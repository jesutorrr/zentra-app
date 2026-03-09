import 'dart:convert';
import 'dart:io' if (dart.library.html) 'io_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../domain/auth_models.dart';
import '../domain/user_profile.dart';
// Web-specific import for file download
import 'web_download_stub.dart' if (dart.library.html) 'web_download.dart' as web_download;

/// Authentication state
enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Provider for local authentication
/// Supports multiple accounts per device
class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  LocalUser? _currentUser;
  List<LocalUser> _allUsers = [];
  String? _error;
  bool _isSessionActive = false;
  bool _needsDataReload = false; // Flag to force data reload after import

  AuthState get state => _state;
  LocalUser? get currentUser => _currentUser;
  List<LocalUser> get allUsers => _allUsers;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated && _isSessionActive;
  bool get hasAccount => _allUsers.isNotEmpty;
  bool get hasMultipleAccounts => _allUsers.length > 1;
  bool get needsDataReload => _needsDataReload;
  
  void clearNeedsDataReload() {
    _needsDataReload = false;
  }

  /// Initialize and load all accounts
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load all users
      final usersJson = prefs.getString('all_users');
      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        _allUsers = usersList
            .map((e) => LocalUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      // Migration: if old single-user format exists, migrate it
      final oldUserJson = prefs.getString('local_user');
      if (oldUserJson != null && _allUsers.isEmpty) {
        final oldUser = LocalUser.fromJson(jsonDecode(oldUserJson));
        _allUsers.add(oldUser);
        await _saveAllUsers();
        // Keep old key for backward compatibility
      }

      // Check for active session (auto-login)
      final activeUserId = prefs.getString('active_session_user_id');
      LocalUser? userToLogin;
      
      if (activeUserId != null) {
        // Try to find the user with active session
        userToLogin = _allUsers.where((u) => u.id == activeUserId).firstOrNull;
      }
      
      // If no active session but users exist, auto-login to most recent user
      // This handles cases where session was lost but user data exists
      if (userToLogin == null && _allUsers.isNotEmpty) {
        // Sort by lastLogin (most recent first)
        _allUsers.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
        userToLogin = _allUsers.first;
      }
      
      if (userToLogin != null) {
        _currentUser = userToLogin;
        _isSessionActive = true;
        _state = AuthState.authenticated;
        
        // Update last login and save session
        final updatedUser = userToLogin.copyWith(lastLogin: DateTime.now());
        final index = _allUsers.indexWhere((u) => u.id == userToLogin!.id);
        if (index != -1) {
          _allUsers[index] = updatedUser;
          _currentUser = updatedUser;
          await _saveAllUsers();
        }
        await prefs.setString('local_user', jsonEncode(updatedUser.toJson()));
        // Ensure session is persisted
        await prefs.setString('active_session_user_id', updatedUser.id);
        
        notifyListeners();
        return;
      }

      _state = AuthState.unauthenticated;
    } catch (e) {
      _error = 'Error initializing: $e';
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// Save all users to storage
  Future<void> _saveAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(_allUsers.map((u) => u.toJson()).toList());
    await prefs.setString('all_users', usersJson);
  }

  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? avatarEmoji,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      // Validate
      if (username.trim().isEmpty) {
        throw Exception('El nombre de usuario es requerido');
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        throw Exception('Ingresa un correo válido');
      }
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      final normalizedEmail = email.trim().toLowerCase();
      
      // Check if email is already registered (case-insensitive)
      if (_allUsers.any((u) => u.email.toLowerCase() == normalizedEmail)) {
        throw Exception('Ya existe una cuenta con este correo');
      }

      // Create user
      final user = LocalUser(
        id: const Uuid().v4(),
        username: username.trim(),
        email: normalizedEmail,
        passwordHash: LocalUser.hashPassword(password),
        avatarEmoji: avatarEmoji ?? '😊',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Add to users list and save
      _allUsers.add(user);
      await _saveAllUsers();

      // Save as current user (for backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user', jsonEncode(user.toJson()));

      // Create initial profile for this user
      final profile = UserProfile(
        id: user.id,
        name: username.trim(),
        avatarEmoji: avatarEmoji ?? '😊',
        createdAt: DateTime.now(),
      );
      await prefs.setString('user_profile_${user.id}', jsonEncode(profile.toJson()));
      await prefs.setString('user_profile', jsonEncode(profile.toJson()));

      _currentUser = user;
      _isSessionActive = true;
      _state = AuthState.authenticated;
      
      // Save active session for auto-login
      await prefs.setString('active_session_user_id', user.id);
      
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      if (_allUsers.isEmpty) {
        throw Exception('No hay cuentas registradas');
      }

      final normalizedEmail = email.trim().toLowerCase();
      
      // Find user by email
      final userIndex = _allUsers.indexWhere((u) => u.email == normalizedEmail);
      if (userIndex == -1) {
        throw Exception('No existe una cuenta con este correo');
      }
      
      final user = _allUsers[userIndex];

      // Verify password
      if (!user.verifyPassword(password)) {
        throw Exception('Contraseña incorrecta');
      }

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      _allUsers[userIndex] = updatedUser;
      await _saveAllUsers();
      
      // Set as current user
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user', jsonEncode(updatedUser.toJson()));
      
      // Load user-specific profile
      final profileJson = prefs.getString('user_profile_${updatedUser.id}');
      if (profileJson != null) {
        await prefs.setString('user_profile', profileJson);
      }

      _isSessionActive = true;
      _state = AuthState.authenticated;
      
      // Save active session for auto-login
      await prefs.setString('active_session_user_id', updatedUser.id);
      
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logout (end session but keep account)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session_user_id');
    
    _isSessionActive = false;
    _currentUser = null;
    _error = null; // Clear any previous error
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Update user profile
  Future<void> updateProfile({
    String? username,
    String? avatarEmoji,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      username: username,
      avatarEmoji: avatarEmoji,
    );

    // Update in users list
    final index = _allUsers.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _allUsers[index] = _currentUser!;
      await _saveAllUsers();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user', jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    try {
      if (!_currentUser!.verifyPassword(currentPassword)) {
        throw Exception('Contraseña actual incorrecta');
      }

      if (newPassword.length < 6) {
        throw Exception('La nueva contraseña debe tener al menos 6 caracteres');
      }

      _currentUser = _currentUser!.copyWith(
        passwordHash: LocalUser.hashPassword(newPassword),
      );

      // Update in users list
      final index = _allUsers.indexWhere((u) => u.id == _currentUser!.id);
      if (index != -1) {
        _allUsers[index] = _currentUser!;
        await _saveAllUsers();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Export all data as backup file
  Future<String?> exportBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUser?.id;

      // Gather all data (user-specific keys if logged in)
      final userJson = prefs.getString('local_user');
      final profileJson = userId != null 
          ? prefs.getString('user_profile_$userId') 
          : prefs.getString('user_profile');
      final habitsJson = userId != null 
          ? prefs.getString('habits_$userId') 
          : prefs.getString('habits');
      final logsJson = userId != null 
          ? prefs.getString('habit_logs_$userId') 
          : prefs.getString('habit_logs');
      
      // Gather Pomodoro data (user-specific keys if logged in)
      final pomodoroActivitiesJson = userId != null 
          ? prefs.getString('pomodoro_activities_$userId') 
          : prefs.getString('pomodoro_activities');
      final completedTasksJson = userId != null 
          ? prefs.getString('completed_tasks_$userId') 
          : prefs.getString('completed_tasks');
      final pomodoroTotal = userId != null 
          ? (prefs.getInt('pomodoro_total_$userId') ?? 0) 
          : (prefs.getInt('pomodoro_total') ?? 0);
      final pomodoroToday = userId != null 
          ? (prefs.getInt('pomodoro_today_$userId') ?? 0) 
          : (prefs.getInt('pomodoro_today') ?? 0);
      final pomodoroFirstDate = userId != null 
          ? prefs.getString('pomodoro_first_date_$userId') 
          : prefs.getString('pomodoro_first_date');
      final pomodoroLastDate = userId != null 
          ? prefs.getString('pomodoro_last_date_$userId') 
          : prefs.getString('pomodoro_last_date');

      if (userJson == null) {
        throw Exception('No hay datos para exportar');
      }

      String appVersion;
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (_) {
        appVersion = '1.0.0';
      }

      final backup = BackupData(
        user: LocalUser.fromJson(jsonDecode(userJson)),
        profile: profileJson != null ? jsonDecode(profileJson) : {},
        habits: habitsJson != null
            ? (jsonDecode(habitsJson) as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [],
        logs: logsJson != null
            ? (jsonDecode(logsJson) as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [],
        pomodoroActivities: pomodoroActivitiesJson != null
            ? (jsonDecode(pomodoroActivitiesJson) as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [],
        completedTasks: completedTasksJson != null
            ? (jsonDecode(completedTasksJson) as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [],
        pomodoroStats: {
          'total': pomodoroTotal,
          'today': pomodoroToday,
          'firstDate': pomodoroFirstDate,
          'lastDate': pomodoroLastDate,
        },
        exportedAt: DateTime.now(),
        appVersion: appVersion,
      );

      final backupJson = jsonEncode(backup.toJson());
      
      if (kIsWeb) {
        // For web, trigger download and return special marker
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
        final filename = 'zentra_backup_$timestamp.json';
        web_download.downloadFile(backupJson, filename);
        return 'WEB_DOWNLOAD:$filename';
      } else {
        // For mobile, save to Downloads folder
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
        final fileName = 'zentra_backup_$timestamp.json';
        
        // Try to save to Downloads folder (Android) or app documents (iOS)
        Directory? saveDir;
        if (Platform.isAndroid) {
          try {
            // Prefer a safe Downloads directory provided by the OS
            saveDir = await getDownloadsDirectory();
          } catch (_) {
            // Ignore and fallback below
          }
          // Fallback to app documents directory if Downloads is not available
          saveDir ??= await getApplicationDocumentsDirectory();
        } else {
          saveDir = await getApplicationDocumentsDirectory();
        }
        
        if (saveDir == null) {
          throw Exception('No se pudo acceder al almacenamiento');
        }
        
        final file = File('${saveDir.path}/$fileName');
        await file.writeAsString(backupJson);

        return file.path;
      }
    } catch (e) {
      _error = 'Error al exportar: $e';
      notifyListeners();
      return null;
    }
  }

  /// Import backup from file
  /// If [preserveCurrentUser] is true, the current user credentials are kept
  /// (useful when importing from profile). If false, user from backup is used.
  /// Returns: true = success, false = error, null = cancelled by user
  Future<bool?> importBackup({String? jsonData, bool preserveCurrentUser = false}) async {
    try {
      String? backupJson = jsonData;

      if (backupJson == null) {
        // Pick file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );

        if (result == null || result.files.isEmpty) {
          return null; // User cancelled file picker
        }

        final file = result.files.first;
        if (file.bytes != null) {
          backupJson = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          backupJson = await File(file.path!).readAsString();
        }
      }

      if (backupJson == null) {
        throw Exception('No se pudo leer el archivo');
      }

      final backupData = BackupData.fromJson(jsonDecode(backupJson));
      final prefs = await SharedPreferences.getInstance();

      // Determine target user ID for storage
      String? targetUserId;
      
      // Restore user data - preserve current user if importing from profile
      if (preserveCurrentUser && _currentUser != null) {
        // Keep current user credentials AND profile, only import activity data
        targetUserId = _currentUser!.id;
      } else {
        // Use user from backup (importing from login screen)
        targetUserId = backupData.user.id;
        await prefs.setString('local_user', jsonEncode(backupData.user.toJson()));
        await prefs.setString('user_profile_$targetUserId', jsonEncode(backupData.profile));
        _currentUser = backupData.user;
        
        // Add user to all_users if not exists
        if (!_allUsers.any((u) => u.id == targetUserId)) {
          _allUsers.add(backupData.user);
          await _saveAllUsers();
        }
      }
      
      // Always import habits and logs to user-specific keys
      await prefs.setString('habits_$targetUserId', jsonEncode(backupData.habits));
      await prefs.setString('habit_logs_$targetUserId', jsonEncode(backupData.logs));
      
      // Restore Pomodoro activities and tasks to user-specific keys
      if (backupData.pomodoroActivities.isNotEmpty) {
        await prefs.setString('pomodoro_activities_$targetUserId', jsonEncode(backupData.pomodoroActivities));
      }
      if (backupData.completedTasks.isNotEmpty) {
        await prefs.setString('completed_tasks_$targetUserId', jsonEncode(backupData.completedTasks));
      }
      
      // Restore Pomodoro stats to user-specific keys
      if (backupData.pomodoroStats.isNotEmpty) {
        final stats = backupData.pomodoroStats;
        if (stats['total'] != null) {
          await prefs.setInt('pomodoro_total_$targetUserId', stats['total'] as int);
        }
        if (stats['today'] != null) {
          await prefs.setInt('pomodoro_today_$targetUserId', stats['today'] as int);
        }
        if (stats['firstDate'] != null) {
          await prefs.setString('pomodoro_first_date_$targetUserId', stats['firstDate'] as String);
        }
        if (stats['lastDate'] != null) {
          await prefs.setString('pomodoro_last_date_$targetUserId', stats['lastDate'] as String);
        }
      }

      // Update session state
      if (!preserveCurrentUser) {
        _currentUser = backupData.user;
      }
      _isSessionActive = true;
      _state = AuthState.authenticated;
      
      // Persist active session for auto-login on next app start
      if (!preserveCurrentUser && targetUserId != null) {
        await prefs.setString('active_session_user_id', targetUserId);
      }
      _needsDataReload = true; // Force data reload in AuthWrapper
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error al importar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete current account and its data
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userId = _currentUser!.id;
    
    // Remove from users list
    _allUsers.removeWhere((u) => u.id == userId);
    await _saveAllUsers();
    
    // Remove user-specific data
    await prefs.remove('user_profile_$userId');
    await prefs.remove('habits_$userId');
    await prefs.remove('habit_logs_$userId');
    await prefs.remove('pomodoro_activities_$userId');
    await prefs.remove('completed_tasks_$userId');
    await prefs.remove('pomodoro_total_$userId');
    await prefs.remove('pomodoro_today_$userId');
    await prefs.remove('pomodoro_total_minutes_$userId');
    await prefs.remove('pomodoro_today_minutes_$userId');
    await prefs.remove('pomodoro_first_date_$userId');
    await prefs.remove('pomodoro_last_date_$userId');
    
    // Clear current session data
    await prefs.remove('local_user');
    await prefs.remove('user_profile');
    await prefs.remove('habits');
    await prefs.remove('habit_logs');
    await prefs.remove('completed_tasks');
    await prefs.remove('pomodoro_activities');
    await prefs.remove('pomodoro_total');
    await prefs.remove('pomodoro_today');
    await prefs.remove('pomodoro_total_minutes');
    await prefs.remove('pomodoro_today_minutes');
    await prefs.remove('pomodoro_first_date');
    await prefs.remove('pomodoro_last_date');
    await prefs.remove('active_session_user_id');

    _currentUser = null;
    _isSessionActive = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
