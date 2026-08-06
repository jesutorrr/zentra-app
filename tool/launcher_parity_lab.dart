// Design Lab: «Nuevo hábito» y «Nuevo enfoque», uno al lado del otro.
//
// Los dos labs que ya existen (`progress_pulse_lab`, `calendar_time_live_lab`)
// montan widgets render-only con un fixture. Este no puede: el lanzador de
// Enfoque y el formulario de hábito son pantallas productivas que cuelgan del
// grafo de Riverpod. Así que este lab monta las pantallas REALES sobre un
// contenedor de vista previa, porque la pregunta que tiene que contestar es de
// parangón —¿se ven hermanas?— y esa pregunta no se contesta mirando una pieza
// aislada.
//
// Abrirlo:
//
//   flutter run -t tool/launcher_parity_lab.dart -d <simulador>
//
// `--dart-define=PARITY_DARK=true` para AMOLED, y `PARITY_ONLY=habit|focus`
// para revisar una sola pantalla a tamaño completo cuando la ventana es
// angosta.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/theme.dart';

const _useDarkTheme = bool.fromEnvironment('PARITY_DARK');
const _only = String.fromEnvironment('PARITY_ONLY', defaultValue: 'both');

const String _previewOwner = 'design-lab-parity';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await _previewContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LauncherParityLab(),
    ),
  );
}

class LauncherParityLab extends StatelessWidget {
  const LauncherParityLab({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zentra · Paridad de lanzadores',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _useDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const _ParityStage(),
    );
  }
}

class _ParityStage extends StatelessWidget {
  const _ParityStage();

  @override
  Widget build(BuildContext context) {
    const habit = HabitFormScreen();
    const focus = PomodoroScreen();
    switch (_only) {
      case 'habit':
        return habit;
      case 'focus':
        return focus;
    }
    // Un teléfono no tiene ancho para dos pantallas de verdad, así que en
    // vertical se apilan en pestañas: comparar dos cosas aplastadas a 196dp
    // enseñaría un defecto que no existe. En horizontal caben lado a lado, que
    // es como mejor se ve si la separación superior coincide.
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return const Row(
        children: [
          Expanded(child: _Labelled(label: 'Nuevo hábito', child: habit)),
          VerticalDivider(width: 1),
          Expanded(child: _Labelled(label: 'Nuevo enfoque', child: focus)),
        ],
      );
    }
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            child: SafeArea(
              bottom: false,
              child: TabBar(
                tabs: [
                  Tab(text: 'Nuevo hábito'),
                  Tab(text: 'Nuevo enfoque'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [habit, focus],
            ),
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labelled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// El mismo grafo que usa `OwnerBoundWidgetHarness` en las pruebas, reducido a
/// lo que estas dos pantallas necesitan: hábitos, perfil, tareas y un motor de
/// Pomodoro en memoria. Sin notas, sin notificaciones reales.
Future<ProviderContainer> _previewContainer() async {
  final preferences = await SharedPreferences.getInstance();
  final habits = LocalStorageRepository.forOwner(
    preferences,
    ownerId: _previewOwner,
  );
  final profiles = SharedPreferencesProfileRepository(
    preferences,
    ownerId: _previewOwner,
  );
  final completedTasks = SharedPreferencesCompletedTaskRepository(
    preferences,
    ownerId: _previewOwner,
  );
  // El lab no lee notas, pero el grafo pide una base: en memoria y se va con el
  // proceso, así que una corrida nunca hereda el estado de la anterior.
  ZentraDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      activeOwnerIdProvider.overrideWithValue(_previewOwner),
      habitRepositoryFactoryProvider.overrideWithValue((_) => habits),
      completedTaskRepositoryFactoryProvider
          .overrideWithValue((_) => completedTasks),
      profileRepositoryFactoryProvider.overrideWithValue((_) => profiles),
      habitReminderServiceProvider.overrideWithValue(
        const _SilentHabitReminderService(),
      ),
      pomodoroEngineFactoryProvider.overrideWithValue(
        ({required String ownerId, required VoidCallback onChanged}) {
          return PomodoroEngine(initialUserId: ownerId, onChanged: onChanged);
        },
      ),
    ],
  );
  container.listen(
    habitControllerProvider(_previewOwner),
    (_, __) {},
    fireImmediately: true,
  );
  container.listen(
    profileControllerProvider(_previewOwner),
    (_, __) {},
    fireImmediately: true,
  );
  await Future.wait([
    container.read(habitControllerProvider(_previewOwner).future),
    container.read(profileControllerProvider(_previewOwner).future),
  ]);
  return container;
}

class _SilentHabitReminderService implements HabitReminderService {
  const _SilentHabitReminderService();

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
