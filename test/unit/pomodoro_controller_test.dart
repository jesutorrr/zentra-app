import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:zentra/application/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() {
    tz.setLocalLocation(tz.UTC);
    FlutterForegroundTask.skipServiceResponseCheck = true;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      foregroundChannel,
      (call) async => call.method == 'isRunningService' ? false : null,
    );
    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async => null,
    );
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps configuration isolated by owner and publishes engine changes',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ownerA = pomodoroControllerProvider('owner-a');
    final ownerB = pomodoroControllerProvider('owner-b');
    final controllerA = container.read(ownerA.notifier);
    final controllerB = container.read(ownerB.notifier);

    await controllerA.initialize();
    await controllerB.initialize();
    await controllerA.setWorkDuration(35);

    expect(container.read(ownerA).workDuration, 35);
    expect(container.read(ownerB).workDuration, 25);
  });

  test('timer actions are exposed through the Riverpod controller', () async {
    final container = ProviderContainer(
      overrides: [
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required String ownerId,
            required void Function() onChanged,
          }) {
            return PomodoroEngine(
              initialUserId: ownerId,
              onChanged: onChanged,
              completionTransitionDelay: Duration.zero,
            );
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = pomodoroControllerProvider('owner-a');
    final controller = container.read(provider.notifier);
    await controller.initialize();
    await controller.startQuickSession(name: 'Leer');

    final running = container.read(provider);
    expect(running.state, PomodoroState.running);
    expect(running.quickSessionName, 'Leer');

    await controller.skip();
    final stopped = container.read(provider);
    expect(stopped.state, PomodoroState.idle);
    expect(stopped.canShowLauncher, isTrue);
  });
}
