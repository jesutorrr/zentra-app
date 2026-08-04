import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/presentation/settings_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('settings exposes only the parked cloud information',
      (tester) async {
    final container = await _localContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final paused = find.byKey(const ValueKey('settings-cloud-paused'));
    await tester.scrollUntilVisible(
      paused,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(paused, findsOneWidget);
    expect(find.text('Cuenta y sincronización en la nube'), findsOneWidget);
    expect(
      find.text(
        'Volverán cuando Zentra local esté completa. '
        'Tu espacio permanece en este dispositivo.',
      ),
      findsOneWidget,
    );
    final tile = tester.widget<ListTile>(
      find.descendant(of: paused, matching: find.byType(ListTile)),
    );
    expect(tile.onTap, isNull);
    expect(find.byKey(const ValueKey('settings-cloud-link')), findsNothing);
    expect(find.byKey(const ValueKey('settings-cloud-sync')), findsNothing);
    expect(find.textContaining('Vincular con'), findsNothing);
    expect(find.text('Sincronización Supabase'), findsNothing);
    expect(find.byTooltip('Sincronizar ahora'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local space actions explain their device-only effects',
      (tester) async {
    final container = await _localContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final leave = find.text('Salir de este espacio');
    await tester.scrollUntilVisible(
      leave,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(leave, findsOneWidget);
    expect(
      find.text('Tu espacio seguirá guardado en este dispositivo'),
      findsOneWidget,
    );
    expect(
      find.text('Eliminar espacio de este dispositivo'),
      findsOneWidget,
    );
    expect(
      find.text('Elimina sólo la copia local guardada en este dispositivo'),
      findsOneWidget,
    );
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.text('Eliminar cuenta'), findsNothing);

    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de este espacio?'), findsOneWidget);
    expect(
      find.text(
        'Tu espacio seguirá guardado en este dispositivo. '
        'Podrás volver a abrirlo cuando quieras.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar espacio de este dispositivo'));
    await tester.pumpAndSettle();
    expect(
      find.text('¿Eliminar este espacio del dispositivo?'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Se eliminarán permanentemente los hábitos, notas y progreso '
        'guardados en este dispositivo. No se eliminará ninguna cuenta ni '
        'dato remoto.',
      ),
      findsOneWidget,
    );
    expect(find.text('Eliminar espacio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local deletion survives a Pomodoro shutdown failure',
      (tester) async {
    final container = await _localContainer(
      pomodoroEngineFactory: ({
        required ownerId,
        required onChanged,
      }) {
        return _FailingShutdownPomodoroEngine(
          ownerId: ownerId,
          onChanged: onChanged,
        );
      },
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final delete = find.text('Eliminar espacio de este dispositivo');
    await tester.scrollUntilVisible(
      delete,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar espacio'));
    await tester.pumpAndSettle();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers, isEmpty);
  });

  testWidgets('local logout survives a stuck Pomodoro shutdown',
      (tester) async {
    final container = await _localContainer(
      pomodoroEngineFactory: ({
        required ownerId,
        required onChanged,
      }) =>
          _HangingShutdownPomodoroEngine(
        ownerId: ownerId,
        onChanged: onChanged,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    final leave = find.text('Salir de este espacio');
    await tester.scrollUntilVisible(
      leave,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(leave);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers, hasLength(1));
  });
}

Future<ProviderContainer> _localContainer({
  PomodoroEngineFactory? pomodoroEngineFactory,
}) async {
  final container = ProviderContainer(
    overrides: [
      accountNotificationCleanupProvider.overrideWithValue(() async {}),
      if (pomodoroEngineFactory != null)
        pomodoroEngineFactoryProvider.overrideWithValue(
          pomodoroEngineFactory,
        ),
    ],
  );
  await container.read(sessionControllerProvider.future);
  expect(
    await container.read(sessionControllerProvider.notifier).continueLocally(),
    isTrue,
  );
  return container;
}

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SettingsScreen(),
    ),
  );
}

class _FailingShutdownPomodoroEngine extends PomodoroEngine {
  _FailingShutdownPomodoroEngine({
    required String ownerId,
    required super.onChanged,
  }) : super(initialUserId: ownerId);

  @override
  Future<void> shutdown() async {
    throw StateError('simulated Live Activity failure');
  }
}

class _HangingShutdownPomodoroEngine extends PomodoroEngine {
  _HangingShutdownPomodoroEngine({
    required String ownerId,
    required super.onChanged,
  }) : super(initialUserId: ownerId);

  @override
  Future<void> shutdown() => Completer<void>().future;
}
