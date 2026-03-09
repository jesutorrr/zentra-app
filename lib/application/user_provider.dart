import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/user_profile.dart';

/// Provider for user profile and achievements
class UserProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = true;
  final Set<String> _newlyUnlockedAchievements = {};
  bool _allAchievementsUnlocked = false;
  String? _currentUserId;

  /// Get the storage key for user profile (user-specific if logged in)
  String get _profileKey => _currentUserId != null 
      ? 'user_profile_$_currentUserId' 
      : 'user_profile';

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasProfile => _profile != null;
  Set<String> get newlyUnlockedAchievements => _newlyUnlockedAchievements;
  bool get allAchievementsJustUnlocked => _allAchievementsUnlocked;

  /// Check if all achievements are unlocked
  bool get hasAllAchievements {
    if (_profile == null) return false;
    return _profile!.unlockedAchievements.length >= Achievements.all.length;
  }

  /// Get progress percentage for achievements
  double get achievementProgress {
    if (_profile == null) return 0;
    return _profile!.unlockedAchievements.length / Achievements.all.length;
  }

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    if (_profile == null) return [];
    return Achievements.all
        .where((a) => _profile!.unlockedAchievements.contains(a.id))
        .toList();
  }

  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    if (_profile == null) return Achievements.all;
    return Achievements.all
        .where((a) => !_profile!.unlockedAchievements.contains(a.id))
        .toList();
  }

  /// Clear newly unlocked achievements (after showing them)
  void clearNewlyUnlocked() {
    _newlyUnlockedAchievements.clear();
    _allAchievementsUnlocked = false;
    notifyListeners();
  }

  /// Load profile from storage
  Future<void> loadProfile({String? userId}) async {
    _isLoading = true;
    _currentUserId = userId;
    _profile = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileJson));
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create new profile
  Future<void> createProfile({
    required String name,
    String? avatarEmoji,
  }) async {
    final profile = UserProfile(
      id: const Uuid().v4(),
      name: name,
      avatarEmoji: avatarEmoji ?? '😊',
      createdAt: DateTime.now(),
    );

    _profile = profile;
    await _saveProfile();
    notifyListeners();
  }

  /// Update profile
  Future<void> updateProfile({
    String? name,
    String? avatarEmoji,
  }) async {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      name: name,
      avatarEmoji: avatarEmoji,
    );

    await _saveProfile();
    notifyListeners();
  }

  // Contadores por categoría (se actualizan externamente)
  int _categoryAguaCount = 0;
  int _categoryMovimientoCount = 0;
  int _categorySuenoCount = 0;
  int _categoryFocoCount = 0;
  int _pomodorosCount = 0;

  /// Record habit completion and check achievements
  Future<void> recordHabitCompletion({
    required int totalCompleted,
    required int longestStreak,
    required int daysActive,
    int categoryAguaCount = 0,
    int categoryMovimientoCount = 0,
    int categorySuenoCount = 0,
    int categoryFocoCount = 0,
    int pomodorosCount = 0,
  }) async {
    if (_profile == null) return;

    // Actualizar contadores de categorías
    _categoryAguaCount = categoryAguaCount;
    _categoryMovimientoCount = categoryMovimientoCount;
    _categorySuenoCount = categorySuenoCount;
    _categoryFocoCount = categoryFocoCount;
    _pomodorosCount = pomodorosCount;

    final newLevel = UserProfile.calculateLevel(totalCompleted);
    final previousAchievementsCount = _profile!.unlockedAchievements.length;

    _profile = _profile!.copyWith(
      totalHabitsCompleted: totalCompleted,
      longestStreak: longestStreak > _profile!.longestStreak 
          ? longestStreak 
          : _profile!.longestStreak,
      totalDaysActive: daysActive,
      currentLevel: newLevel,
    );

    // Check for new achievements
    await _checkAndUnlockAchievements();

    // Check if ALL achievements just got unlocked
    if (_profile!.unlockedAchievements.length == Achievements.all.length &&
        previousAchievementsCount < Achievements.all.length) {
      _allAchievementsUnlocked = true;
    }

    await _saveProfile();
    notifyListeners();
  }

  /// Check and unlock achievements
  Future<void> _checkAndUnlockAchievements() async {
    if (_profile == null) return;

    final unlockedIds = List<String>.from(_profile!.unlockedAchievements);
    
    for (final achievement in Achievements.all) {
      if (unlockedIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;
      
      switch (achievement.type) {
        case AchievementType.habitsCompleted:
          shouldUnlock = _profile!.totalHabitsCompleted >= achievement.requirement;
          break;
        case AchievementType.streakDays:
          shouldUnlock = _profile!.longestStreak >= achievement.requirement;
          break;
        case AchievementType.daysActive:
          shouldUnlock = _profile!.totalDaysActive >= achievement.requirement;
          break;
        // Categorías específicas
        case AchievementType.categoryAgua:
          shouldUnlock = _categoryAguaCount >= achievement.requirement;
          break;
        case AchievementType.categoryMovimiento:
          shouldUnlock = _categoryMovimientoCount >= achievement.requirement;
          break;
        case AchievementType.categorySueno:
          shouldUnlock = _categorySuenoCount >= achievement.requirement;
          break;
        case AchievementType.categoryFoco:
          shouldUnlock = _categoryFocoCount >= achievement.requirement;
          break;
        // Pomodoro
        case AchievementType.pomodorosCompleted:
          shouldUnlock = _pomodorosCount >= achievement.requirement;
          break;
        // Otros tipos (implementar después si es necesario)
        case AchievementType.habitsCreated:
        case AchievementType.perfectWeek:
        case AchievementType.perfectMonth:
        case AchievementType.earlyBird:
        case AchievementType.nightOwl:
        case AchievementType.weekendWarrior:
        case AchievementType.consistency:
          // These will be checked elsewhere or in future updates
          break;
      }

      if (shouldUnlock) {
        unlockedIds.add(achievement.id);
        _newlyUnlockedAchievements.add(achievement.id);
      }
    }

    _profile = _profile!.copyWith(unlockedAchievements: unlockedIds);
  }

  /// Delete profile
  Future<void> deleteProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    _profile = null;
    notifyListeners();
  }

  /// Save profile to storage
  Future<void> _saveProfile() async {
    if (_profile == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profile!.toJson()));
  }
}
