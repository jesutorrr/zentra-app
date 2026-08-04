import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:zentra/infrastructure/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> platformCalls;

  setUpAll(() => tz.setLocalLocation(tz.UTC));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platformCalls = [];
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      notificationsChannel,
      (call) async {
        platformCalls.add(call);
        if (call.method == 'canScheduleExactNotifications') return false;
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  test('daily and per-habit notification preferences are independent',
      () async {
    final service = NotificationService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);

    await service.setHabitRemindersEnabled(true);

    expect(await service.areNotificationsEnabled(), isFalse);
    expect(await service.areHabitRemindersEnabled(), isTrue);
  });

  test('generic daily reminders require explicit opt-in', () async {
    final service = NotificationService();

    expect(await service.areNotificationsEnabled(), isFalse);
    expect(await service.areHabitRemindersEnabled(), isTrue);
  });

  test('legacy global opt-in enables both daily reminders', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'morning_reminder_time': 8,
      'evening_reminder_time': 21,
    });
    final service = NotificationService();

    final settings = await service.getDailyReminderSettings();

    expect(settings.morningEnabled, isTrue);
    expect(settings.morningHour, 8);
    expect(settings.eveningEnabled, isTrue);
    expect(settings.eveningHour, 21);
  });

  test('explicit morning and night choices stay independent', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'morning_reminder_enabled': true,
      'morning_reminder_time': 7,
      'morning_reminder_minute': 30,
      'evening_reminder_enabled': false,
      'evening_reminder_time': 20,
      'evening_reminder_minute': 15,
    });
    final service = NotificationService();

    final settings = await service.getDailyReminderSettings();

    expect(settings.morningEnabled, isTrue);
    expect(settings.morningHour, 7);
    expect(settings.morningMinute, 30);
    expect(settings.eveningEnabled, isFalse);
    expect(settings.eveningHour, 20);
    expect(settings.eveningMinute, 15);
  });

  test('global off keeps stored daily choices inactive', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': false,
      'morning_reminder_enabled': true,
      'evening_reminder_enabled': true,
    });
    final settings = await NotificationService().getDailyReminderSettings();

    expect(settings.morningEnabled, isFalse);
    expect(settings.eveningEnabled, isFalse);
  });

  test('reconfiguration cancels stable IDs and schedules selected period',
      () async {
    await NotificationService().setDailyReminderSettings(
      const DailyReminderSettings(
        morningEnabled: true,
        morningHour: 8,
        morningMinute: 30,
        eveningEnabled: false,
        eveningHour: 20,
        eveningMinute: 0,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final schedules =
        platformCalls.where((call) => call.method == 'zonedSchedule').toList();
    final cancelledIds = platformCalls
        .where((call) => call.method == 'cancel')
        .map(
          (call) => (call.arguments as Map<Object?, Object?>)['id'] as int,
        )
        .toList();

    expect(cancelledIds, containsAll(<int>[1000, 1001, 1002, 1003]));
    expect(schedules, hasLength(1));
    expect(
      (schedules.single.arguments as Map<Object?, Object?>)['id'],
      1000,
    );
    expect(prefs.getBool('morning_reminder_enabled'), isTrue);
    expect(prefs.getBool('evening_reminder_enabled'), isFalse);
    expect(prefs.getBool('notifications_enabled'), isTrue);
  });

  test('morning copy keeps user-authored habit names off the lock screen', () {
    final content = NotificationService().morningReminderContent(
      DailyReminderSnapshot(
        capturedAt: DateTime(2026, 7, 26, 8, 50),
        totalHabits: 3,
        completedHabits: 0,
        firstPendingHabit: 'Tomar agua',
      ),
    );

    expect(content.title, 'Hoy tienes 3 hábitos');
    expect(content.body, 'Abre Zentra y elige con cuál empezar.');
    expect(content.body, isNot(contains('Tomar agua')));
  });

  test('night copy congratulates only verified completed progress', () {
    final service = NotificationService();
    final completed = service.eveningReminderContent(
      DailyReminderSnapshot(
        capturedAt: DateTime(2026, 7, 26, 18, 50),
        totalHabits: 2,
        completedHabits: 2,
      ),
    );
    final pending = service.eveningReminderContent(
      DailyReminderSnapshot(
        capturedAt: DateTime(2026, 7, 26, 18, 50),
        totalHabits: 2,
        completedHabits: 1,
        firstPendingHabit: 'Preparar mañana',
      ),
    );
    final unknown = service.eveningReminderContent();

    expect(completed.title, 'Día completado');
    expect(completed.body, 'Terminaste tus 2 hábitos de hoy.');
    expect(pending.title, 'Queda 1 hábito');
    expect(
      pending.body,
      'Abre Zentra y decide qué vas a completar hoy.',
    );
    expect(pending.body, isNot(contains('Preparar mañana')));
    expect(unknown.title, 'Cierra el día');
    expect(unknown.title, isNot(contains('completado')));
  });
}
