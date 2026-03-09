import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Local user account for authentication
class LocalUser {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String? avatarEmoji;
  final DateTime createdAt;
  final DateTime lastLogin;

  const LocalUser({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt, required this.lastLogin, this.avatarEmoji,
  });

  LocalUser copyWith({
    String? username,
    String? email,
    String? passwordHash,
    String? avatarEmoji,
    DateTime? lastLogin,
  }) {
    return LocalUser(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'passwordHash': passwordHash,
    'avatarEmoji': avatarEmoji,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin.toIso8601String(),
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
    avatarEmoji: json['avatarEmoji'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLogin: DateTime.parse(json['lastLogin'] as String),
  );

  /// Hash password for secure storage
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against stored hash
  bool verifyPassword(String password) {
    return passwordHash == hashPassword(password);
  }
}

/// Complete backup data structure
class BackupData {
  final LocalUser user;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> logs;
  final List<Map<String, dynamic>> pomodoroActivities;
  final List<Map<String, dynamic>> completedTasks;
  final Map<String, dynamic> pomodoroStats;
  final DateTime exportedAt;
  final String appVersion;

  const BackupData({
    required this.user,
    required this.profile,
    required this.habits,
    required this.logs,
    required this.exportedAt, required this.appVersion, this.pomodoroActivities = const [],
    this.completedTasks = const [],
    this.pomodoroStats = const {},
  });

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'profile': profile,
    'habits': habits,
    'logs': logs,
    'pomodoroActivities': pomodoroActivities,
    'completedTasks': completedTasks,
    'pomodoroStats': pomodoroStats,
    'exportedAt': exportedAt.toIso8601String(),
    'appVersion': appVersion,
    'backupVersion': 2, // Updated for new fields
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    user: LocalUser.fromJson(json['user'] as Map<String, dynamic>),
    profile: json['profile'] as Map<String, dynamic>? ?? {},
    habits: (json['habits'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList(),
    logs: (json['logs'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList(),
    pomodoroActivities: (json['pomodoroActivities'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ?? [],
    completedTasks: (json['completedTasks'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ?? [],
    pomodoroStats: json['pomodoroStats'] as Map<String, dynamic>? ?? {},
    exportedAt: DateTime.parse(json['exportedAt'] as String),
    appVersion: json['appVersion'] as String? ?? '1.0.0',
  );

  /// Encode to base64 string for easy sharing
  String encode() {
    final jsonString = jsonEncode(toJson());
    return base64Encode(utf8.encode(jsonString));
  }

  /// Decode from base64 string
  static BackupData decode(String encoded) {
    final jsonString = utf8.decode(base64Decode(encoded));
    return BackupData.fromJson(jsonDecode(jsonString));
  }
}
