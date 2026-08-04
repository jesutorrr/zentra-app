import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/completed_task_repository.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/presentation/habits_list_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _MemoryHabitRepository implements HabitRepository {
  _MemoryHabitRepository({
    required List<Habit> habits,
    List<HabitLog> logs = const [],
  })  : _habits = List<Habit>.from(habits),
        _logs = List<HabitLog>.from(logs);

  List<Habit> _habits;
  List<HabitLog> _logs;

  @override
  void setCurrentUser(String? userId) {}

  @override
  Future<List<Habit>> getHabits() async => List<Habit>.from(_habits);

  @override
  Future<void> saveHabit(Habit habit) async {
    _habits = [..._habits, habit];
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    _habits = [
      for (final current in _habits)
        if (current.id == habit.id) habit else current,
    ];
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits = _habits.where((habit) => habit.id != habitId).toList();
    _logs = _logs.where((log) => log.habitId != habitId).toList();
  }

  @override
  Future<List<HabitLog>> getAllLogs() async => List<HabitLog>.from(_logs);

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    return _logs.where((log) => log.matches(log.habitId, date)).toList();
  }

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final existing = _logs.indexWhere((log) => log.matches(habitId, date));
    if (existing >= 0) {
      _logs.removeAt(existing);
    } else {
      _logs.add(
        HabitLog(
          habitId: habitId,
          date: HabitLog.normalizeDate(date),
        ),
      );
    }
  }
}

class _BlockingHabitRepository extends _MemoryHabitRepository {
  _BlockingHabitRepository()
      : super(
          habits: const [],
        );

  final Completer<List<Habit>> loading = Completer<List<Habit>>();

  @override
  Future<List<Habit>> getHabits() => loading.future;
}

class _RetryHabitRepository extends _MemoryHabitRepository {
  _RetryHabitRepository({required super.habits});

  var attempts = 0;

  @override
  Future<List<Habit>> getHabits() {
    attempts += 1;
    if (attempts == 1) {
      throw StateError('temporary failure');
    }
    return super.getHabits();
  }
}

class _FakeReminderService implements HabitReminderService {
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

class _MemoryCompletedTaskRepository implements CompletedTaskRepository {
  @override
  final String ownerId;
  List<CompletedTask> tasks = [];

  _MemoryCompletedTaskRepository(this.ownerId);

  @override
  Future<List<CompletedTask>> loadCompletedTasks() async => [...tasks];

  @override
  Future<void> replaceCompletedTasks(List<CompletedTask> tasks) async {
    this.tasks = [...tasks];
  }
}

class _TestHabitWorkspace {
  static const ownerId = 'habits-list-owner';

  final ProviderContainer container;

  _TestHabitWorkspace(
    HabitRepository repository, {
    required HabitReminderService reminderService,
  }) : container = ProviderContainer(
          overrides: [
            activeOwnerIdProvider.overrideWithValue(ownerId),
            habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
              expect(requestedOwner, ownerId);
              return repository;
            }),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return _MemoryCompletedTaskRepository(ownerId);
              },
            ),
            habitReminderServiceProvider.overrideWithValue(reminderService),
          ],
        );

  Future<void> initialize() async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await container.read(habitControllerProvider(ownerId).future);
  }

  Habit? getHabitById(String habitId) {
    return container
        .read(habitControllerProvider(ownerId))
        .valueOrNull
        ?.getHabitById(habitId);
  }

  bool isHabitCompletedToday(String habitId) {
    return container
            .read(habitControllerProvider(ownerId))
            .valueOrNull
            ?.isHabitCompleted(habitId, DateTime.now()) ??
        false;
  }

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<Habit> seededHabits(DateTime now) {
    final otherWeekday =
        now.weekday == DateTime.monday ? DateTime.tuesday : DateTime.monday;
    return [
      Habit(
        id: 'focus-habit',
        title: 'Leer Álgebra',
        category: Category.foco,
        frequency: Frequency.daily(),
        createdAt: now,
        hasReminder: true,
        reminderHour: 8,
        reminderMinute: 30,
      ),
      Habit(
        id: 'sleep-habit',
        title: 'Dormir temprano',
        category: Category.sueno,
        frequency: Frequency.daily(),
        createdAt: now,
      ),
      Habit(
        id: 'off-habit',
        title: 'Caminar con calma',
        category: Category.movimiento,
        frequency: Frequency(
          isWeekly: true,
          daysOfWeek: [otherWeekday],
        ),
        createdAt: now,
      ),
      Habit(
        id: 'archived-habit',
        title: 'Tomar agua',
        category: Category.agua,
        frequency: Frequency.daily(),
        createdAt: now,
        isArchived: true,
      ),
    ];
  }

  List<HabitLog> seededLogs(DateTime now) {
    return [
      HabitLog(
        habitId: 'sleep-habit',
        date: HabitLog.normalizeDate(now),
      ),
    ];
  }

  Future<_TestHabitWorkspace> seededProvider() async {
    final now = DateTime.now();
    final repository = _MemoryHabitRepository(
      habits: seededHabits(now),
      logs: seededLogs(now),
    );
    final provider = _TestHabitWorkspace(
      repository,
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    return provider;
  }

  Future<_TestHabitWorkspace> categoryMatrixProvider() async {
    final now = DateTime.now();
    final repository = _MemoryHabitRepository(
      habits: [
        for (final category in Category.values)
          Habit(
            id: 'category-${category.name}',
            title: 'Hábito ${category.label}',
            category: category,
            frequency: Frequency.daily(),
            createdAt: now,
          ),
      ],
    );
    final provider = _TestHabitWorkspace(
      repository,
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    return provider;
  }

  double contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter =
        firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
    final darker =
        firstLuminance < secondLuminance ? firstLuminance : secondLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  Widget app(
    _TestHabitWorkspace provider, {
    double textScale = 1,
    bool disableAnimations = true,
    ThemeMode themeMode = ThemeMode.light,
    Widget screen = const ClassicHabitsListScreen(),
  }) {
    return UncontrolledProviderScope(
      container: provider.container,
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
              disableAnimations: disableAnimations,
              accessibleNavigation: true,
            ),
            child: child!,
          );
        },
        home: screen,
      ),
    );
  }

  Future<void> setSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<_TestHabitWorkspace> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool disableAnimations = true,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await setSize(tester, size);
    final provider = await seededProvider();
    await tester.pumpWidget(
      app(
        provider,
        textScale: textScale,
        disableAnimations: disableAnimations,
        themeMode: themeMode,
      ),
    );
    await tester.pump();
    return provider;
  }

  Future<_TestHabitWorkspace> pumpSalviaScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool disableAnimations = true,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await setSize(tester, size);
    final provider = await seededProvider();
    await tester.pumpWidget(
      app(
        provider,
        textScale: textScale,
        disableAnimations: disableAnimations,
        themeMode: themeMode,
        screen: const HabitsListScreen(),
      ),
    );
    await tester.pump();
    return provider;
  }

  Future<void> openActions(
    WidgetTester tester,
    String habitId,
  ) async {
    final actions = find.byKey(ValueKey('habit-actions-$habitId'));
    await tester.ensureVisible(actions);
    await tester.pump();
    await tester.tap(actions);
    await tester.pumpAndSettle();
  }

  Finder salviaScrollable() {
    return find
        .descendant(
          of: find.byKey(
            const ValueKey('habits-single-column-layout'),
          ),
          matching: find.byType(Scrollable),
        )
        .first;
  }

  testWidgets('Salvia composes active and paused habits in one calm library',
      (tester) async {
    await pumpSalviaScreen(tester);

    expect(find.text('MIS HÁBITOS'), findsOneWidget);
    expect(find.text('Tus hábitos'), findsOneWidget);
    expect(find.text('3 activos · 1 en pausa'), findsOneWidget);
    expect(find.byKey(const ValueKey('habits-category-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('habits-category-movimiento')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(
      find.byIcon(Icons.local_fire_department_rounded),
      findsWidgets,
    );

    final paused = find.byKey(
      const ValueKey('habit-row-archived-habit'),
    );
    await tester.scrollUntilVisible(
      paused,
      240,
      scrollable: salviaScrollable(),
    );
    expect(find.text('EN PAUSA'), findsOneWidget);
    expect(paused, findsOneWidget);
    expect(
      find.byKey(const ValueKey('habit-restore-archived-habit')),
      findsOneWidget,
    );

    final add = find.byKey(const ValueKey('habits-add'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, 54);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia search stays hidden until requested and keeps accents',
      (tester) async {
    await pumpSalviaScreen(tester);

    expect(find.byKey(const ValueKey('habits-search')), findsNothing);
    final toggle = find.byKey(const ValueKey('habits-search-toggle'));
    expect(tester.getSize(toggle), const Size(48, 48));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('habits-search'));
    expect(search, findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.enterText(search, 'sueno');
    await tester.pump();

    expect(find.byKey(const ValueKey('habit-row-sleep-habit')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia category filters include paused habits', (tester) async {
    await pumpSalviaScreen(tester);

    await tester.tap(
      find.byKey(const ValueKey('habits-category-agua')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('habit-row-archived-habit')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);
    expect(find.text('EN PAUSA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia pause and one-tap reactivation use the stable archive',
      (tester) async {
    final provider = await pumpSalviaScreen(tester);
    await openActions(tester, 'sleep-habit');
    await tester.tap(
      find.byKey(const ValueKey('habit-action-archive-sleep-habit')),
    );
    await tester.pumpAndSettle();

    expect(provider.getHabitById('sleep-habit')?.isArchived, isTrue);
    expect(find.text('2 activos · 2 en pausa'), findsOneWidget);

    final restore = find.byKey(
      const ValueKey('habit-restore-sleep-habit'),
    );
    await tester.scrollUntilVisible(
      restore,
      220,
      scrollable: salviaScrollable(),
    );
    expect(tester.getSize(restore), const Size(48, 48));
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(provider.getHabitById('sleep-habit')?.isArchived, isFalse);
    expect(find.text('3 activos · 1 en pausa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia AMOLED uses pure black and keeps the classic fallback',
      (tester) async {
    await pumpSalviaScreen(
      tester,
      themeMode: ThemeMode.dark,
    );

    final background = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey('habits-salvia-background'),
            ),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = background.decoration as BoxDecoration;
    expect(decoration.color, Colors.black);
    expect(decoration.gradient, isNull);
    expect(find.text('Tus hábitos'), findsOneWidget);
    final addButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('habits-add')),
    );
    expect(
      addButton.style?.elevation?.resolve(const <WidgetState>{}),
      0,
    );
    expect(
      addButton.style?.shadowColor?.resolve(const <WidgetState>{}),
      Colors.transparent,
    );
    expect(tester.takeException(), isNull);

    final provider = await seededProvider();
    await tester.pumpWidget(
      app(
        provider,
        screen: const ClassicHabitsListScreen(),
      ),
    );
    await tester.pump();
    expect(find.byType(ClassicHabitsListScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('habits-compact-metrics')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia remains scrollable at 320dp and 320 percent text',
      (tester) async {
    await pumpSalviaScreen(
      tester,
      size: const Size(320, 568),
      textScale: 3.2,
    );

    final scroll = find.byKey(
      const ValueKey('habits-single-column-layout'),
    );
    expect(scroll, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('habits-add')),
      420,
      scrollable: salviaScrollable(),
    );
    expect(find.byKey(const ValueKey('habits-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search matches title and category without accents',
      (tester) async {
    await pumpScreen(tester);
    final search = find.byKey(const ValueKey('habits-search'));

    await tester.enterText(search, 'algebra');
    await tester.pump();
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-row-sleep-habit')), findsNothing);

    await tester.enterText(search, 'sueno');
    await tester.pump();
    expect(find.byKey(const ValueKey('habit-row-sleep-habit')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active and archived filters expose only their own habits',
      (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('habit-row-archived-habit')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('habits-filter-archived')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('habit-row-archived-habit')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact density exposes metrics and the first habit early',
      (tester) async {
    await pumpScreen(tester);

    final add = find.byKey(const ValueKey('habits-add'));
    final metrics = find.byKey(
      const ValueKey('habits-compact-metrics'),
    );
    final firstHabit = find.byKey(
      const ValueKey('habit-row-focus-habit'),
    );

    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(add).width, greaterThanOrEqualTo(48));
    expect(metrics, findsOneWidget);
    expect(
      find.descendant(of: metrics, matching: find.text('Activos')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metrics, matching: find.text('Hoy')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metrics, matching: find.text('Mejor racha')),
      findsOneWidget,
    );
    expect(firstHabit, findsOneWidget);
    expect(tester.getTopLeft(firstHabit).dy, lessThan(560));
    expect(tester.takeException(), isNull);
  });

  testWidgets('completion is accessible, 48dp and can be undone',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final provider = await pumpScreen(tester);
    final completion = find.byKey(
      const ValueKey('habit-complete-focus-habit'),
    );
    await tester.ensureVisible(completion);
    await tester.pump();

    expect(tester.getSize(completion).height, greaterThanOrEqualTo(48));
    final before = tester.getSemantics(completion).getSemanticsData();
    expect(before.hasAction(SemanticsAction.tap), isTrue);
    expect(before.flagsCollection.isToggled, Tristate.isFalse);

    tester.semantics.tap(
      find.semantics.byLabel(
        'Marcar Leer Álgebra como completado',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(provider.isHabitCompletedToday('focus-habit'), isTrue);
    final after = tester.getSemantics(completion).getSemanticsData();
    expect(after.flagsCollection.isToggled, Tristate.isTrue);

    tester.semantics.tap(
      find.semantics.byLabel(
        'Marcar Leer Álgebra como pendiente',
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.isHabitCompletedToday('focus-habit'), isFalse);
    expect(
      tester
          .getSemantics(completion)
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('compact menu is accessible, 48dp and archives into Archived',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final provider = await pumpScreen(tester);
    final actions = find.byKey(
      const ValueKey('habit-actions-focus-habit'),
    );
    await tester.ensureVisible(actions);
    await tester.pump();

    expect(tester.getSize(actions).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(actions).width, greaterThanOrEqualTo(48));
    final menuSemantics = find.semantics.byLabel(
      'Más acciones para Leer Álgebra',
    );
    expect(menuSemantics, findsOneWidget);
    tester.semantics.tap(menuSemantics);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('habit-action-archive-focus-habit')),
    );
    await tester.pumpAndSettle();

    expect(provider.getHabitById('focus-habit')?.isArchived, isTrue);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('habits-filter-archived')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('archived habit can be restored from its card', (tester) async {
    final provider = await pumpScreen(tester);
    await tester.tap(
      find.byKey(const ValueKey('habits-filter-archived')),
    );
    await tester.pump();

    final restore = find.byKey(
      const ValueKey('habit-restore-archived-habit'),
    );
    await tester.ensureVisible(restore);
    await tester.pump();
    expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
    await tester.tap(restore);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(provider.getHabitById('archived-habit')?.isArchived, isFalse);
    expect(find.byKey(const ValueKey('habits-empty-results')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact delete can be cancelled and then confirmed',
      (tester) async {
    final provider = await pumpScreen(tester);

    await openActions(tester, 'focus-habit');
    await tester.tap(
      find.byKey(const ValueKey('habit-action-delete-focus-habit')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eliminar hábito'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(provider.getHabitById('focus-habit'), isNotNull);

    await openActions(tester, 'focus-habit');
    await tester.tap(
      find.byKey(const ValueKey('habit-action-delete-focus-habit')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Eliminar hábito'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(provider.getHabitById('focus-habit'), isNull);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create button and compact card wire into the habit form',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('habits-add')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo hábito'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('habit-back')));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('habit-row-focus-habit'));
    await tester.ensureVisible(row);
    await tester.pump();
    expect(
      find.semantics.byLabel(
        RegExp(r'^Editar Leer Álgebra'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Leer Álgebra'));
    await tester.pumpAndSettle();

    expect(find.text('Editar hábito'), findsOneWidget);
    expect(find.text('Leer Álgebra'), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-preview')), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('editing from the list persists and refreshes the card',
      (tester) async {
    final provider = await pumpScreen(tester);
    final row = find.byKey(const ValueKey('habit-row-focus-habit'));
    await tester.ensureVisible(row);
    await tester.tap(find.text('Leer Álgebra'));
    await tester.pumpAndSettle();

    final title = find.byKey(const ValueKey('habit-title-field'));
    expect(title, findsOneWidget);
    await tester.enterText(title, 'Repasar Álgebra lineal');
    final submit = find.byKey(const ValueKey('habit-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byType(ClassicHabitsListScreen), findsOneWidget);
    expect(
      provider.getHabitById('focus-habit')?.title,
      'Repasar Álgebra lineal',
    );
    expect(find.text('Repasar Álgebra lineal'), findsOneWidget);
    expect(find.text('Leer Álgebra'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-results state clears the search', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const ValueKey('habits-search')),
      'algo que no existe',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('habits-empty-results')), findsOneWidget);
    expect(find.text('Limpiar búsqueda'), findsOneWidget);
    final clear = find.text('Limpiar búsqueda');
    await tester.ensureVisible(clear);
    await tester.pump();
    await tester.tap(clear);
    await tester.pump();

    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-use empty state keeps a direct creation action',
      (tester) async {
    await setSize(tester, const Size(390, 844));
    final provider = _TestHabitWorkspace(
      _MemoryHabitRepository(habits: const []),
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    await tester.pumpWidget(app(provider));
    await tester.pump();

    expect(find.text('Tu espacio está listo'), findsOneWidget);
    final add = find.byKey(const ValueKey('habits-empty-add'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated 320x568 at 3.2x text remains usable and scrollable',
      (tester) async {
    await pumpScreen(
      tester,
      size: const Size(320, 568),
      textScale: 3.2,
    );

    final singleColumn = find.byKey(
      const ValueKey('habits-single-column-layout'),
    );
    expect(singleColumn, findsOneWidget);
    expect(find.byKey(const ValueKey('habits-add')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final scrollable = find.descendant(
      of: singleColumn,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('habit-row-off-habit')),
      420,
      scrollable: scrollable,
    );
    expect(find.byKey(const ValueKey('habit-row-off-habit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short landscape stays in the scrollable single-column layout',
      (tester) async {
    await pumpScreen(
      tester,
      size: const Size(932, 430),
    );

    expect(
      find.byKey(const ValueKey('habits-single-column-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habits-expanded-layout')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('best streak metric only considers active habits',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await setSize(tester, const Size(390, 844));
    final now = DateTime.now();
    final provider = _TestHabitWorkspace(
      _MemoryHabitRepository(
        habits: [
          Habit(
            id: 'active',
            title: 'Hábito activo',
            category: Category.foco,
            frequency: Frequency.daily(),
            createdAt: now,
          ),
          Habit(
            id: 'archived',
            title: 'Hábito archivado',
            category: Category.agua,
            frequency: Frequency.daily(),
            createdAt: now,
            isArchived: true,
          ),
        ],
        logs: [
          HabitLog(habitId: 'active', date: HabitLog.normalizeDate(now)),
          for (var offset = 0; offset < 5; offset++)
            HabitLog(
              habitId: 'archived',
              date: HabitLog.normalizeDate(
                now.subtract(Duration(days: offset)),
              ),
            ),
        ],
      ),
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    await tester.pumpWidget(app(provider));
    await tester.pump();
    final metrics = find.byKey(const ValueKey('habits-compact-metrics'));

    expect(
      find.descendant(of: metrics, matching: find.text('Mejor racha')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metrics, matching: find.text('5')),
      findsNothing,
    );
    expect(
      find.semantics.byLabel(RegExp(r'\b1 Mejor racha\b')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('populated dark mode keeps completion contrast and layout',
      (tester) async {
    await pumpScreen(
      tester,
      themeMode: ThemeMode.dark,
    );
    final completion = find.byKey(
      const ValueKey('habit-complete-focus-habit'),
    );
    await tester.ensureVisible(completion);
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: completion,
        matching: find.byWidgetPredicate(
          (widget) => widget is FilledButton,
        ),
      ),
    );
    final background = button.style?.backgroundColor?.resolve(
      const <WidgetState>{},
    );
    final foreground = button.style?.foregroundColor?.resolve(
      const <WidgetState>{},
    );
    expect(background, isNotNull);
    expect(foreground, isNotNull);
    expect(
      contrastRatio(background!, foreground!),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.takeException(), isNull);
  });

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'category metadata meets 4.5 contrast in ${themeMode.name}',
      (tester) async {
        await setSize(tester, const Size(390, 844));
        final provider = await categoryMatrixProvider();
        await tester.pumpWidget(
          app(
            provider,
            themeMode: themeMode,
          ),
        );
        await tester.pump();

        for (final category in Category.values) {
          await tester.enterText(
            find.byKey(const ValueKey('habits-search')),
            category.label,
          );
          await tester.pump();

          final metadata = find.byKey(
            ValueKey('habit-category-label-category-${category.name}'),
          );
          expect(metadata, findsOneWidget);
          await tester.ensureVisible(metadata);
          await tester.pump();

          final container = tester.widget<Container>(
            find.descendant(
              of: metadata,
              matching: find.byType(Container),
            ),
          );
          final decoration = container.decoration! as BoxDecoration;
          final background = decoration.color!;
          final text = tester.widget<Text>(
            find.descendant(
              of: metadata,
              matching: find.byType(Text),
            ),
          );
          final icon = tester.widget<Icon>(
            find.descendant(
              of: metadata,
              matching: find.byType(Icon),
            ),
          );

          expect(
            contrastRatio(text.style!.color!, background),
            greaterThanOrEqualTo(4.5),
            reason:
                '${category.label} text in ${themeMode.name} must be legible',
          );
          expect(
            contrastRatio(icon.color!, background),
            greaterThanOrEqualTo(4.5),
            reason:
                '${category.label} icon in ${themeMode.name} must be legible',
          );
          expect(decoration.border, isNotNull);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('compact loading is scrollable and static with reduced motion',
      (tester) async {
    await setSize(tester, const Size(320, 568));
    final repository = _BlockingHabitRepository();
    final provider = _TestHabitWorkspace(
      repository,
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    unawaited(provider.initialize());

    await tester.pumpWidget(
      app(
        provider,
        textScale: 2,
      ),
    );
    await tester.pump();

    final loading = find.byKey(const ValueKey('habits-loading-scroll'));
    expect(loading, findsOneWidget);
    expect(
      find.byKey(const ValueKey('habits-loading-static')),
      findsOneWidget,
    );
    await tester.drag(loading, const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);

    repository.loading.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('initial error retries into the populated list', (tester) async {
    await setSize(tester, const Size(390, 844));
    final repository = _RetryHabitRepository(
      habits: seededHabits(DateTime.now()),
    );
    final provider = _TestHabitWorkspace(
      repository,
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    await tester.pumpWidget(app(provider));
    await tester.pump();

    expect(find.text('No pudimos cargar tus hábitos'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(repository.attempts, 2);
    expect(find.byKey(const ValueKey('habit-row-focus-habit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1024 width uses list-detail with real selected content',
      (tester) async {
    await pumpScreen(
      tester,
      size: const Size(1024, 1366),
    );

    expect(
      find.byKey(const ValueKey('habits-expanded-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habits-wide-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habits-compact-metrics')),
      findsNothing,
    );
    final add = find.byKey(const ValueKey('habits-add'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
    expect(
      find.byKey(const ValueKey('habits-list-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habits-detail-panel')),
      findsOneWidget,
    );
    final listPanel = find.byKey(const ValueKey('habits-list-panel'));
    final detailPanel = find.byKey(const ValueKey('habits-detail-panel'));
    expect(
      find.descendant(
        of: listPanel,
        matching: find.text('Leer Álgebra'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detailPanel,
        matching: find.text('Leer Álgebra'),
      ),
      findsOneWidget,
    );

    final edit = find.byKey(const ValueKey('habit-detail-edit'));
    final archive = find.byKey(
      const ValueKey('habit-detail-archive'),
    );
    final delete = find.byKey(
      const ValueKey('habit-detail-delete'),
    );
    for (final action in [edit, archive, delete]) {
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }

    await tester.tap(
      find.descendant(
        of: listPanel,
        matching: find.text('Dormir temprano'),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: detailPanel,
        matching: find.text('Dormir temprano'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('list-detail keeps a valid selection after archiving',
      (tester) async {
    final provider = await pumpScreen(
      tester,
      size: const Size(1024, 1366),
    );
    final detailPanel = find.byKey(const ValueKey('habits-detail-panel'));

    expect(
      find.descendant(
        of: detailPanel,
        matching: find.text('Leer Álgebra'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: detailPanel,
        matching: find.byKey(const ValueKey('habit-detail-archive')),
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.getHabitById('focus-habit')?.isArchived, isTrue);
    expect(
      find.descendant(
        of: detailPanel,
        matching: find.text('Dormir temprano'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habit-row-focus-habit')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('one-time habit exposes its date in card and detail',
      (tester) async {
    await setSize(tester, const Size(1024, 1366));
    final provider = _TestHabitWorkspace(
      _MemoryHabitRepository(
        habits: [
          Habit(
            id: 'one-time',
            title: 'Presentar examen',
            category: Category.foco,
            frequency: Frequency.daily(),
            createdAt: DateTime(2026, 7, 20),
            isOneTime: true,
            scheduledDate: DateTime(2026, 8, 10),
          ),
        ],
      ),
      reminderService: _FakeReminderService(),
    );
    addTearDown(provider.dispose);
    await provider.initialize();
    await tester.pumpWidget(app(provider));
    await tester.pump();

    expect(find.textContaining('Una vez'), findsNWidgets(2));
    expect(find.textContaining('10'), findsWidgets);
    expect(find.text('Cuando lo necesites'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double delete tap opens only one confirmation dialog',
      (tester) async {
    await pumpScreen(
      tester,
      size: const Size(1024, 1366),
    );
    final detailPanel = find.byKey(const ValueKey('habits-detail-panel'));
    final delete = find.descendant(
      of: detailPanel,
      matching: find.byKey(const ValueKey('habit-detail-delete')),
    );

    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.tap(delete, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Eliminar hábito'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
