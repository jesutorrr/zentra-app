import 'dart:ui' show SemanticsAction, Tristate;

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/core/constants.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/calendar_screen.dart';
import 'package:zentra/presentation/celebration_dialog.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/today_screen.dart';
import 'package:zentra/presentation/widgets/celebration_particles.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <MethodCall>[];

  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  setUp(() {
    platformCalls.clear();
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> configureDevice(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<_TodayHarness> createHarness({
    bool seeded = true,
    bool completeSecondHabit = true,
    String pendingTitle = 'Revisar metas del día',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final habits = LocalStorageRepository.forOwner(
      prefs,
      ownerId: _TodayHarness.ownerId,
    );
    final profile = SharedPreferencesProfileRepository(
      prefs,
      ownerId: _TodayHarness.ownerId,
    );
    final completedTasks = SharedPreferencesCompletedTaskRepository(
      prefs,
      ownerId: _TodayHarness.ownerId,
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    final notes = DriftNoteRepository.forOwner(
      database,
      ownerId: _TodayHarness.ownerId,
    );

    await profile.saveProfile(
      UserProfile(
        id: 'profile-uri',
        name: 'Uri',
        avatarEmoji: '🦉',
        talismanId: 'brujula-serena',
        createdAt: DateTime.now(),
      ),
    );
    if (seeded) {
      await habits.saveHabit(
        Habit(
          id: 'pending-habit',
          title: pendingTitle,
          category: Category.foco,
          frequency: Frequency.daily(),
          createdAt: DateTime.now(),
        ),
      );
      await habits.saveHabit(
        Habit(
          id: 'completed-habit',
          title: 'Preparar descanso',
          category: Category.sueno,
          frequency: Frequency.daily(),
          createdAt: DateTime.now(),
        ),
      );
      if (completeSecondHabit) {
        await habits.toggleLog('completed-habit', DateTime.now());
      }
    }

    final harness = _TodayHarness(
      habits: habits,
      profile: profile,
      completedTasks: completedTasks,
      notes: notes,
      database: database,
    );
    addTearDown(harness.dispose);
    await harness.initialize();
    return harness;
  }

  Widget buildApp(
    _TodayHarness harness, {
    double textScale = 1,
    Widget home = const TodayScreen(),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
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

  Future<void> pumpToday(
    WidgetTester tester,
    _TodayHarness harness, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(buildApp(harness, textScale: textScale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder target,
  ) async {
    await Scrollable.ensureVisible(
      target.evaluate().single,
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();
    final verticalScroll = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollable = tester.state<ScrollableState>(verticalScroll);
    final viewportCenter = tester.getRect(verticalScroll).center.dy;
    final targetCenter = tester.getCenter(target).dy;
    final desiredOffset =
        (scrollable.position.pixels + targetCenter - viewportCenter).clamp(
      scrollable.position.minScrollExtent,
      scrollable.position.maxScrollExtent,
    );
    scrollable.position.jumpTo(desiredOffset);
    await tester.pump();
  }

  testWidgets('Today exposes progress, gamification and mixed habit states',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);

    expect(find.byKey(const ValueKey('today-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today-progress-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today-gamification-summary')),
      findsOneWidget,
    );
    expect(find.text('lvl 1'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('today-progress-summary')),
          )
          .value,
      '1 de 2 hábitos completados',
    );
    expect(
      find.byKey(const ValueKey('today-pending-pending-habit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today-completed-completed-habit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habit-completion-pending-habit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habit-category-pending-habit')),
      findsOneWidget,
    );

    final completion = find.byKey(
      const ValueKey('habit-completion-pending-habit'),
    );
    expect(tester.getSize(completion).shortestSide, greaterThanOrEqualTo(48));
    platformCalls.clear();
    await tester.tap(completion);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(
      find.byKey(const ValueKey('today-pending-pending-habit')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('today-completed-pending-habit')),
      findsOneWidget,
    );
    expect(find.byType(DayCompletedDialog), findsOneWidget);
    final completionHaptics = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(completionHaptics, hasLength(1));
    expect(
      completionHaptics.single.arguments,
      'HapticFeedbackType.mediumImpact',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied notification permission becomes one dismissible notice',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationPermissionNoticePendingKey, true);
    final harness = await createHarness();
    await pumpToday(tester, harness);

    expect(
      find.byKey(const ValueKey('today-notification-permission-notice')),
      findsOneWidget,
    );
    expect(find.text('Los avisos están apagados'), findsOneWidget);
    expect(find.text('Abrir Ajustes'), findsOneWidget);
    expect(find.text('Más tarde'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('today-notification-permission-later')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('today-notification-permission-notice')),
      findsNothing,
    );
    expect(prefs.getBool(kNotificationPermissionNoticePendingKey), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpToday(tester, harness);
    expect(
      find.byKey(const ValueKey('today-notification-permission-notice')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia gives progress the freed width and keeps 50/50 actions',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);

    final level = tester.getRect(
      find.byKey(const ValueKey('today-level-chip')),
    );
    final profile = tester.getRect(
      find.byKey(const ValueKey('today-profile-action')),
    );
    final progress = tester.getRect(
      find.byKey(const ValueKey('today-progress-track')),
    );
    final focus = tester.getSize(
      find.byKey(const ValueKey('today-focus-launcher')),
    );
    final habit = tester.getSize(
      find.byKey(const ValueKey('today-add-habit')),
    );

    expect(level.right, lessThanOrEqualTo(profile.left));
    expect(progress.width, greaterThan(250));
    expect(focus.width, closeTo(habit.width, 0.5));
    expect(focus.height, 54);
    expect(habit.height, 54);
    expect(find.text('Nivel 1 · Semilla'), findsNothing);
    expect(find.text('lvl 1'), findsOneWidget);
    expect(find.text('HÁBITOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia AMOLED uses black canvas and designed card surfaces',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, themeMode: ThemeMode.dark),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    final background = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('today-salvia-background')),
    );
    final backgroundDecoration = background.decoration as BoxDecoration;
    final card = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('salvia-habit-card-pending-habit')),
    );
    final cardDecoration = card.decoration as BoxDecoration;

    expect(backgroundDecoration.color, Colors.black);
    expect(backgroundDecoration.gradient, isNull);
    expect(cardDecoration.color, const Color(0xFF101514));
    expect(cardDecoration.boxShadow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Classic Today remains executable as the visual fallback',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, home: const ClassicTodayScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Nivel 1 · Semilla'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today-salvia-background')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today keeps add, calendar and focus paths directly reachable',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);

    await tester.tap(find.byKey(const ValueKey('today-add-habit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HabitFormScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('habit-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('today-calendar-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CalendarScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final focus = find.byKey(const ValueKey('today-focus-launcher'));
    await reveal(tester, focus);
    await tester.tap(focus);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PomodoroScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today derives its visible level from live habit logs',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);

    expect(find.text('lvl 1'), findsOneWidget);
    for (var daysAgo = 1; daysAgo <= 9; daysAgo++) {
      await harness.toggleHabit(
        'pending-habit',
        DateTime.now().subtract(Duration(days: daysAgo)),
      );
    }
    await tester.pump();

    expect(find.text('lvl 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today exposes one clean, invokable semantics action per target',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness(completeSecondHabit: false);
    await pumpToday(tester, harness);
    final semantics = tester.ensureSemantics();

    final completion = find.byKey(
      const ValueKey('habit-completion-pending-habit'),
    );
    final completionNode = tester.getSemantics(completion);
    final completionData = completionNode.getSemanticsData();
    expect(
      completionNode.label,
      'Marcar Revisar metas del día como completado',
    );
    expect(completionData.flagsCollection.isToggled, Tristate.isFalse);
    expect(completionData.hasAction(SemanticsAction.tap), isTrue);

    platformCalls.clear();
    tester.semantics.tap(
      find.semantics.byLabel('Marcar Revisar metas del día como completado'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(harness.isHabitCompletedToday('pending-habit'), isTrue);
    final toggledNode = tester.getSemantics(
      find.byKey(const ValueKey('habit-completion-pending-habit')),
    );
    expect(
      toggledNode.getSemanticsData().flagsCollection.isToggled,
      Tristate.isTrue,
    );
    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      hasLength(1),
    );

    final targets = <({String key, String label})>[
      (key: 'today-add-habit', label: 'Nuevo hábito'),
      (key: 'today-calendar-action', label: 'Calendario'),
      (key: 'today-focus-action', label: 'Enfoque'),
      (key: 'today-profile-action', label: 'Abrir perfil'),
    ];
    for (final target in targets) {
      final finder = find.byKey(ValueKey(target.key));
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).shortestSide, greaterThanOrEqualTo(48));
      final node = tester.getSemantics(finder);
      expect(node.label, contains(target.label));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
    }

    final progressNode = tester.getSemantics(
      find.byKey(const ValueKey('today-progress-summary')),
    );
    expect(progressNode.label, 'Progreso de hoy');
    expect(progressNode.value, '1 de 2 hábitos completados');
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('today-gamification-summary')),
          )
          .label,
      contains('Nivel 1, Semilla'),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('unmarking a completed habit emits no haptic feedback',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);
    final completion = find.byKey(
      const ValueKey('habit-completion-completed-habit'),
    );
    await reveal(tester, completion);

    platformCalls.clear();
    await tester.tap(completion);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(harness.isHabitCompletedToday('completed-habit'), isFalse);
    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('habit long press emits one haptic before opening its menu',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    await pumpToday(tester, harness);
    final habit = find.byKey(
      const ValueKey('today-pending-pending-habit'),
    );
    await reveal(tester, habit);

    platformCalls.clear();
    await tester.longPress(habit);
    await tester.pump(const Duration(milliseconds: 400));

    final haptics = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today uses a real two-pane canvas at expanded width',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(1024, 900));
    final harness = await createHarness();
    await pumpToday(tester, harness);

    expect(
      find.byKey(const ValueKey('today-expanded-layout')),
      findsOneWidget,
    );
    final habits = tester.getRect(
      find.byKey(const ValueKey('today-habits-panel')),
    );
    final progress = tester.getRect(
      find.byKey(const ValueKey('today-progress-summary')),
    );
    expect(habits.right, lessThanOrEqualTo(progress.left));
    expect(
      find.byKey(const ValueKey('today-single-column-layout')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('critical Today copy does not truncate at 320dp and 3.2x text',
      (tester) async {
    const longTitle =
        'Preparar con calma todos los materiales para el examen de mañana';
    await configureDevice(tester, logicalSize: const Size(320, 640));
    final harness = await createHarness(pendingTitle: longTitle);
    await pumpToday(tester, harness, textScale: 3.2);

    final criticalCopy = <Finder>[
      find.byKey(const ValueKey('habit-title-pending-habit')),
      find.text('Hábitos'),
      find.byKey(
        const ValueKey('today-destination-label-Mes'),
      ),
    ];
    for (final finder in criticalCopy) {
      expect(finder, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'Critical copy must remain fully readable at 3.2x text.',
      );
    }
    expect(find.text(longTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  final responsiveCases = <({Size size, double textScale})>[
    (size: const Size(320, 640), textScale: 3.2),
    (size: const Size(360, 640), textScale: 2),
    (size: const Size(744, 1133), textScale: 2),
    (size: const Size(1024, 900), textScale: 2),
    (size: const Size(744, 1133), textScale: 3.2),
  ];

  for (final responsiveCase in responsiveCases) {
    testWidgets(
      'seeded Today is stable at ${responsiveCase.size.width}dp and '
      '${responsiveCase.textScale}x text',
      (tester) async {
        await configureDevice(tester, logicalSize: responsiveCase.size);
        final harness = await createHarness();
        await pumpToday(
          tester,
          harness,
          textScale: responsiveCase.textScale,
        );

        expect(find.byKey(const ValueKey('today-screen')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('today-progress-summary')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('today-pending-pending-habit')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('today-completed-completed-habit')),
          findsOneWidget,
        );
        expect(find.byType(BouncingNumber), findsNothing);

        final add = find.byKey(const ValueKey('today-add-habit'));
        await reveal(tester, add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(find.byType(HabitFormScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('habit-back')));
        await tester.pumpAndSettle();

        final calendar = find.byKey(
          const ValueKey('today-calendar-action'),
        );
        await reveal(tester, calendar);
        await tester.tap(calendar);
        await tester.pumpAndSettle();
        expect(find.byType(CalendarScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        final focus = find.byKey(const ValueKey('today-focus-launcher'));
        await reveal(tester, focus);
        await tester.tap(focus);
        await tester.pumpAndSettle();
        expect(find.byType(PomodoroScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty Today is warm and has one real creation path',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(744, 1133));
    final harness = await createHarness(seeded: false);
    await pumpToday(tester, harness);

    expect(find.byKey(const ValueKey('today-empty-state')), findsOneWidget);
    expect(find.text('Crea tu primer hábito'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today-empty-create-habit')),
      findsNothing,
    );
    expect(find.text('Hábito'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-add-habit')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('habit and completion log survive owner repository reconstruction',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final firstRepository = LocalStorageRepository.forOwner(
      prefs,
      ownerId: _TodayHarness.ownerId,
    );
    final habit = Habit(
      id: 'persistent-habit',
      title: 'Leer diez minutos',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime.now(),
    );

    await firstRepository.saveHabit(habit);
    await firstRepository.toggleLog(habit.id, DateTime.now());

    final reconstructed = LocalStorageRepository.forOwner(
      prefs,
      ownerId: _TodayHarness.ownerId,
    );

    expect(
      (await reconstructed.getHabits()).single.title,
      habit.title,
    );
    expect(
      (await reconstructed.getAllLogs())
          .where((log) => log.habitId == habit.id),
      hasLength(1),
    );
  });
}

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

class _TodayHarness {
  static const ownerId = 'uri';

  final LocalStorageRepository habits;
  final SharedPreferencesProfileRepository profile;
  final SharedPreferencesCompletedTaskRepository completedTasks;
  final DriftNoteRepository notes;
  final ZentraDatabase database;
  late final ProviderContainer container;

  _TodayHarness({
    required this.habits,
    required this.profile,
    required this.completedTasks,
    required this.notes,
    required this.database,
  }) {
    container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
        habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return habits;
        }),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          (requestedOwner) {
            expect(requestedOwner, ownerId);
            return completedTasks;
          },
        ),
        profileRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return profile;
        }),
        noteRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return notes;
        }),
        habitReminderServiceProvider.overrideWithValue(
          _FakeHabitReminderService(),
        ),
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required String ownerId,
            required VoidCallback onChanged,
          }) {
            expect(ownerId, _TodayHarness.ownerId);
            return PomodoroEngine(
              initialUserId: ownerId,
              onChanged: onChanged,
            );
          },
        ),
      ],
    );
  }

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
    container.listen(
      noteControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(ownerId).future),
      container.read(profileControllerProvider(ownerId).future),
      container.read(noteControllerProvider(ownerId).future),
    ]);
  }

  Future<void> toggleHabit(String habitId, DateTime date) {
    return container
        .read(habitControllerProvider(ownerId).notifier)
        .toggleHabit(habitId, date);
  }

  bool isHabitCompletedToday(String habitId) {
    return container
            .read(habitControllerProvider(ownerId))
            .valueOrNull
            ?.isHabitCompleted(habitId, DateTime.now()) ??
        false;
  }

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}
