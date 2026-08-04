import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/notification_intent.dart';

void main() {
  group('ZentraNotificationIntent', () {
    test('round-trips a versioned note reminder', () {
      final encoded = ZentraNotificationIntent.openNote('note-42').encode();
      final decoded = ZentraNotificationIntent.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.version, ZentraNotificationIntent.currentVersion);
      expect(decoded.type, ZentraNotificationType.noteReminder);
      expect(decoded.entityId, 'note-42');
      expect(decoded.action, 'open');
    });

    test('keeps legacy payloads readable', () {
      expect(
        ZentraNotificationIntent.tryDecode('pomodoro')!.type,
        ZentraNotificationType.pomodoro,
      );
      expect(
        ZentraNotificationIntent.tryDecode('habit:habit-1')!.entityId,
        'habit-1',
      );
    });

    test('rejects unknown versions and missing entity ids', () {
      expect(
        ZentraNotificationIntent.tryDecode(
          '{"v":99,"type":"noteReminder","entityId":"a","action":"open"}',
        ),
        isNull,
      );
      expect(
        ZentraNotificationIntent.tryDecode(
          '{"v":1,"type":"noteReminder","action":"open"}',
        ),
        isNull,
      );
    });
  });
}
