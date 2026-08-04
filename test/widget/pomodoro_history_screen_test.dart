import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/presentation/pomodoro_history_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> seededContainer() async {
    const ownerId = 'history-owner';
    final now = DateTime.now();
    final activities = [
      PomodoroActivity(
        id: 'quick-5',
        name: '',
        startTime: DateTime(now.year, now.month, now.day, 9),
        endTime: DateTime(now.year, now.month, now.day, 9, 5),
        cyclesCompleted: 1,
        totalMinutes: 5,
        isCompleted: true,
      ),
      PomodoroActivity(
        id: 'cycle-15',
        name: 'Repasar Álgebra',
        startTime: DateTime(now.year, now.month, now.day - 1, 18),
        cyclesCompleted: 3,
        totalMinutes: 15,
        isCompleted: true,
        noteId: 'note-1',
      ),
    ];
    SharedPreferences.setMockInitialValues({
      'pomodoro_activities_$ownerId': jsonEncode(
        activities.map((activity) => activity.toJson()).toList(),
      ),
    });
    final container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
      ],
    );
    await container
        .read(pomodoroControllerProvider(ownerId).notifier)
        .initialize();
    return container;
  }

  Future<void> pumpHistory(
    WidgetTester tester, {
    required ProviderContainer container,
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: const PomodoroHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses actual focus minutes and tolerates a missing end time',
      (tester) async {
    final container = await seededContainer();
    await pumpHistory(
      tester,
      container: container,
      size: const Size(390, 844),
    );

    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('5 min'), findsNWidgets(2));
    expect(find.text('15 min'), findsNWidgets(2));
    expect(find.text('Sesión de enfoque'), findsOneWidget);
    expect(find.text('Repasar Álgebra'), findsOneWidget);
    expect(find.text('3 enfoques'), findsOneWidget);
    expect(find.bySemanticsLabel('Nota vinculada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in <({String name, Size size, double scale})>[
    (
      name: 'compact phone at 320 percent text',
      size: const Size(320, 568),
      scale: 3.2,
    ),
    (
      name: 'standard phone',
      size: const Size(390, 844),
      scale: 1,
    ),
    (
      name: 'iPad expanded layout',
      size: const Size(1024, 1366),
      scale: 1,
    ),
  ]) {
    testWidgets('populated history adapts on ${scenario.name}', (tester) async {
      final container = await seededContainer();
      await pumpHistory(
        tester,
        container: container,
        size: scenario.size,
        textScale: scenario.scale,
      );

      expect(
        find.byKey(const ValueKey('focus_history_scroll')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
