import 'dart:convert';

/// Stable, versioned contract between scheduled notifications and navigation.
///
/// Legacy string payloads are decoded for backwards compatibility, but every
/// new notification must use [encode].
enum ZentraNotificationType {
  pomodoro,
  habitReminder,
  noteReminder,
}

class ZentraNotificationIntent {
  static const int currentVersion = 1;

  final int version;
  final ZentraNotificationType type;
  final String? entityId;
  final String action;

  const ZentraNotificationIntent({
    required this.type,
    required this.action,
    this.entityId,
    this.version = currentVersion,
  });

  factory ZentraNotificationIntent.openPomodoro() {
    return const ZentraNotificationIntent(
      type: ZentraNotificationType.pomodoro,
      action: 'open',
    );
  }

  factory ZentraNotificationIntent.openHabit(String habitId) {
    return ZentraNotificationIntent(
      type: ZentraNotificationType.habitReminder,
      entityId: habitId,
      action: 'open',
    );
  }

  factory ZentraNotificationIntent.openNote(String noteId) {
    return ZentraNotificationIntent(
      type: ZentraNotificationType.noteReminder,
      entityId: noteId,
      action: 'open',
    );
  }

  String encode() {
    return jsonEncode({
      'v': version,
      'type': switch (type) {
        ZentraNotificationType.pomodoro => 'pomodoro',
        ZentraNotificationType.habitReminder => 'habitReminder',
        ZentraNotificationType.noteReminder => 'noteReminder',
      },
      if (entityId != null) 'entityId': entityId,
      'action': action,
    });
  }

  static ZentraNotificationIntent? tryDecode(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    // Build 24 and earlier used ad-hoc strings. Keep opening notifications
    // already pending on users' devices while all new schedules use JSON.
    if (payload == 'pomodoro') {
      return ZentraNotificationIntent.openPomodoro();
    }
    if (payload.startsWith('habit:')) {
      final id = payload.substring('habit:'.length);
      return id.isEmpty ? null : ZentraNotificationIntent.openHabit(id);
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['v'];
      final type = decoded['type'];
      final action = decoded['action'];
      final entityId = decoded['entityId'];
      if (version is! int ||
          version > currentVersion ||
          action is! String ||
          (entityId != null && entityId is! String)) {
        return null;
      }

      final parsedType = switch (type) {
        'pomodoro' => ZentraNotificationType.pomodoro,
        'habitReminder' => ZentraNotificationType.habitReminder,
        'noteReminder' => ZentraNotificationType.noteReminder,
        _ => null,
      };
      if (parsedType == null) return null;
      if (parsedType != ZentraNotificationType.pomodoro &&
          (entityId == null || (entityId as String).isEmpty)) {
        return null;
      }

      return ZentraNotificationIntent(
        version: version,
        type: parsedType,
        entityId: entityId as String?,
        action: action,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
