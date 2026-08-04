const Object _localUserUnset = Object();

/// Local owner of one Zentra workspace.
///
/// A previously linked cloud identity can be parked without changing [id].
/// Keeping the owner id stable preserves every owner-scoped Drift record while
/// the cloud integration is disabled.
class LocalUser {
  final String id;
  final String username;
  final String? email;
  final String? avatarEmoji;
  final String? remoteIdentityProvider;
  final String? parkedRemoteIdentityProvider;
  final DateTime? cloudParkedAt;
  final DateTime createdAt;
  final DateTime lastLogin;

  const LocalUser({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.lastLogin,
    this.email,
    this.avatarEmoji,
    this.remoteIdentityProvider,
    this.parkedRemoteIdentityProvider,
    this.cloudParkedAt,
  });

  bool get isCloudLinked => remoteIdentityProvider?.trim().isNotEmpty == true;
  bool get hasParkedCloudIdentity =>
      parkedRemoteIdentityProvider?.trim().isNotEmpty == true;

  LocalUser copyWith({
    String? username,
    String? email,
    String? avatarEmoji,
    Object? remoteIdentityProvider = _localUserUnset,
    Object? parkedRemoteIdentityProvider = _localUserUnset,
    Object? cloudParkedAt = _localUserUnset,
    DateTime? lastLogin,
  }) {
    return LocalUser(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      remoteIdentityProvider: identical(
        remoteIdentityProvider,
        _localUserUnset,
      )
          ? this.remoteIdentityProvider
          : remoteIdentityProvider as String?,
      parkedRemoteIdentityProvider: identical(
        parkedRemoteIdentityProvider,
        _localUserUnset,
      )
          ? this.parkedRemoteIdentityProvider
          : parkedRemoteIdentityProvider as String?,
      cloudParkedAt: identical(cloudParkedAt, _localUserUnset)
          ? this.cloudParkedAt
          : cloudParkedAt as DateTime?,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatarEmoji': avatarEmoji,
        'remoteIdentityProvider': remoteIdentityProvider,
        'parkedRemoteIdentityProvider': parkedRemoteIdentityProvider,
        'cloudParkedAt': cloudParkedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String?,
        avatarEmoji: json['avatarEmoji'] as String?,
        remoteIdentityProvider: json['remoteIdentityProvider'] as String?,
        parkedRemoteIdentityProvider:
            json['parkedRemoteIdentityProvider'] as String?,
        cloudParkedAt: json['cloudParkedAt'] == null
            ? null
            : DateTime.parse(json['cloudParkedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastLogin: DateTime.parse(json['lastLogin'] as String),
      );
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
  final Map<String, dynamic> noteSnapshot;
  final DateTime exportedAt;
  final String appVersion;

  const BackupData({
    required this.user,
    required this.profile,
    required this.habits,
    required this.logs,
    required this.exportedAt,
    required this.appVersion,
    this.pomodoroActivities = const [],
    this.completedTasks = const [],
    this.pomodoroStats = const {},
    this.noteSnapshot = const {},
  });

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'profile': profile,
        'habits': habits,
        'logs': logs,
        'pomodoroActivities': pomodoroActivities,
        'completedTasks': completedTasks,
        'pomodoroStats': pomodoroStats,
        'noteSnapshot': noteSnapshot,
        'exportedAt': exportedAt.toIso8601String(),
        'appVersion': appVersion,
        'backupVersion': 4,
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
                .toList() ??
            [],
        completedTasks: (json['completedTasks'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        pomodoroStats: json['pomodoroStats'] as Map<String, dynamic>? ?? {},
        noteSnapshot: json['noteSnapshot'] as Map<String, dynamic>? ?? const {},
        exportedAt: DateTime.parse(json['exportedAt'] as String),
        appVersion: json['appVersion'] as String? ?? '1.0.0',
      );
}
