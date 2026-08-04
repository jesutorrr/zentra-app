import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/profile_screen.dart';
import 'package:zentra/presentation/profile_setup_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _FakeHabitReminderService implements HabitReminderService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelHabitReminder(String habitId) async {}

  @override
  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    bool isOneTime = false,
    DateTime? scheduledDate,
  }) async {
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }
}

class _ProfileHarness {
  static const ownerId = 'profile-owner';

  final riverpod.ProviderContainer container;

  _ProfileHarness(SharedPreferences preferences)
      : container = riverpod.ProviderContainer(
          overrides: [
            activeOwnerIdProvider.overrideWithValue(ownerId),
            habitRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return LocalStorageRepository.forOwner(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return SharedPreferencesCompletedTaskRepository(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return SharedPreferencesProfileRepository(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            habitReminderServiceProvider.overrideWithValue(
              _FakeHabitReminderService(),
            ),
            pomodoroEngineFactoryProvider.overrideWithValue(
              ({
                required ownerId,
                required onChanged,
              }) {
                return PomodoroEngine(
                  initialUserId: ownerId,
                  onChanged: onChanged,
                );
              },
            ),
          ],
        );

  Future<void> initialize() async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      profileControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(ownerId).future),
      container.read(profileControllerProvider(ownerId).future),
    ]);
    await container
        .read(profileControllerProvider(ownerId).notifier)
        .createProfile(name: 'Uri', avatarEmoji: '🦉');
    container.read(pomodoroControllerProvider(ownerId));
    await container
        .read(pomodoroControllerProvider(ownerId).notifier)
        .initialize();
  }

  void dispose() => container.dispose();
}

void main() {
  Future<_ProfileHarness> createHarness() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final harness = _ProfileHarness(preferences);
    addTearDown(harness.dispose);
    await harness.initialize();
    return harness;
  }

  Widget buildApp({
    required _ProfileHarness harness,
    required double textScale,
    Widget home = const ProfileScreen(),
  }) {
    return riverpod.UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
              accessibleNavigation: true,
            ),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }

  Future<void> configureDevice(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('profile keeps identity direct and collection detail on demand', (
    tester,
  ) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await tester.pumpWidget(buildApp(harness: harness, textScale: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Uri'), findsOneWidget);
    expect(find.textContaining('días con Zentra'), findsOneWidget);
    expect(find.textContaining('días en tu viaje'), findsNothing);
    expect(find.text('Tu colección'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(
      find.textContaining('convertir tu perfil en una pared'),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('zentra_ambient_background')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile setup requires a name and updates the existing profile',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    final initialProfile = harness.container
        .read(profileControllerProvider(_ProfileHarness.ownerId))
        .valueOrNull!
        .profile!;
    var completed = false;

    await tester.pumpWidget(
      buildApp(
        harness: harness,
        textScale: 1,
        home: ProfileSetupScreen(
          ownerId: _ProfileHarness.ownerId,
          initialProfile: initialProfile,
          onComplete: () async => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('profile-setup-name'));
    await tester.enterText(field, '   ');
    await tester.tap(find.byKey(const ValueKey('profile-setup-continue')));
    await tester.pump();
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(completed, isFalse);

    await tester.enterText(field, 'Uri Actualizado');
    await tester.tap(find.byKey(const ValueKey('profile-setup-continue')));
    await tester.pumpAndSettle();

    final updated = harness.container
        .read(profileControllerProvider(_ProfileHarness.ownerId))
        .valueOrNull!
        .profile!;
    expect(updated.id, initialProfile.id);
    expect(updated.name, 'Uri Actualizado');
    expect(completed, isTrue);
  });

  testWidgets('seeded profile remains readable at 320dp and 3.2x text', (
    tester,
  ) async {
    await configureDevice(tester, logicalSize: const Size(320, 568));
    final harness = await createHarness();
    await tester.pumpWidget(buildApp(harness: harness, textScale: 3.2));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Uri'), findsOneWidget);
    expect(find.textContaining('días con Zentra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
