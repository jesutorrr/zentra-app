import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../core/constants.dart';
import '../domain/models.dart';
import '../infrastructure/notification_service.dart';
import 'design_tokens.dart';

abstract class OnboardingNotificationGateway {
  Future<bool> requestPermission();

  Future<bool> isPermissionGranted();

  Future<void> setHabitRemindersEnabled(bool enabled);

  Future<DailyReminderSettings> getDailyReminderSettings();

  Future<void> setDailyReminderSettings(
    DailyReminderSettings settings, {
    DailyReminderSnapshot? snapshot,
  });
}

class _SystemOnboardingNotificationGateway
    implements OnboardingNotificationGateway {
  final NotificationService _service = NotificationService();

  @override
  Future<bool> requestPermission() {
    return _service.requestNotificationPermission();
  }

  @override
  Future<bool> isPermissionGranted() {
    return _service.isSystemNotificationPermissionGranted();
  }

  @override
  Future<void> setHabitRemindersEnabled(bool enabled) {
    return _service.setHabitRemindersEnabled(enabled);
  }

  @override
  Future<DailyReminderSettings> getDailyReminderSettings() {
    return _service.getDailyReminderSettings();
  }

  @override
  Future<void> setDailyReminderSettings(
    DailyReminderSettings settings, {
    DailyReminderSnapshot? snapshot,
  }) {
    return _service.setDailyReminderSettings(
      settings,
      snapshot: snapshot,
    );
  }
}

enum _ReminderPermissionState {
  idle,
  requesting,
  granted,
  denied,
  error,
}

/// Calm, local-first onboarding for a newly-created Zentra space.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final Future<void> Function()? onBack;
  final String userId;
  final OnboardingNotificationGateway? notificationGateway;

  const OnboardingScreen({
    required this.onComplete,
    this.onBack,
    this.userId = 'local-preview',
    this.notificationGateway,
    super.key,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 2;
  // Content rule, not a device breakpoint: both icon-label segments need this
  // much usable panel width to remain comfortable side by side.
  static const _habitChoiceComfortableHorizontalWidth = 300.0;
  final TextEditingController _habitTitleController =
      TextEditingController(text: 'Leer diez páginas');
  final ScrollController _scrollController = ScrollController();
  Category _selectedCategory = Category.foco;
  bool _createFirstHabit = true;
  bool _wantsHabitReminder = false;
  TimeOfDay _habitReminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _morningReminderEnabled = true;
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _eveningReminderEnabled = true;
  TimeOfDay _eveningReminderTime = const TimeOfDay(hour: 19, minute: 0);
  _ReminderPermissionState _permissionState = _ReminderPermissionState.idle;
  bool _isCompleting = false;
  bool _didHydrateExistingHabit = false;
  String? _errorMessage;

  late final OnboardingNotificationGateway _notificationGateway =
      widget.notificationGateway ?? _SystemOnboardingNotificationGateway();

  @override
  void initState() {
    super.initState();
    _habitTitleController.addListener(_handleHabitTitleChanged);
    _loadNotificationPreferences();
  }

  void _hydrateExistingHabit(HabitState habitState) {
    if (_didHydrateExistingHabit) return;
    _didHydrateExistingHabit = true;
    final existingHabit = habitState.getHabitById(_habitId);
    if (existingHabit == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _habitTitleController
        ..removeListener(_handleHabitTitleChanged)
        ..text = existingHabit.title
        ..addListener(_handleHabitTitleChanged);
      setState(() {
        _selectedCategory = existingHabit.category;
        _createFirstHabit = true;
        _wantsHabitReminder = existingHabit.hasReminder;
        if (existingHabit.reminderHour != null &&
            existingHabit.reminderMinute != null) {
          _habitReminderTime = TimeOfDay(
            hour: existingHabit.reminderHour!,
            minute: existingHabit.reminderMinute!,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _habitTitleController
      ..removeListener(_handleHabitTitleChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleHabitTitleChanged() {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final results = await Future.wait<Object>([
        _notificationGateway.isPermissionGranted(),
        _notificationGateway.getDailyReminderSettings(),
      ]);
      if (!mounted) return;
      final granted = results[0] as bool;
      final dailySettings = results[1] as DailyReminderSettings;
      setState(() {
        _permissionState = granted
            ? _ReminderPermissionState.granted
            : _ReminderPermissionState.idle;
        _morningReminderEnabled = granted ? dailySettings.morningEnabled : true;
        _morningReminderTime = TimeOfDay(
          hour: dailySettings.morningHour,
          minute: dailySettings.morningMinute,
        );
        _eveningReminderEnabled = granted ? dailySettings.eveningEnabled : true;
        _eveningReminderTime = TimeOfDay(
          hour: dailySettings.eveningHour,
          minute: dailySettings.eveningMinute,
        );
      });
    } catch (_) {
      // Permission is requested only after the user chooses the reminder CTA.
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    _completeOnboarding();
  }

  Future<void> _previousStep() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    if (widget.onBack != null) {
      await widget.onBack!();
      return;
    }
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<bool> _ensureNotificationPermission() async {
    if (_permissionState == _ReminderPermissionState.requesting) return false;

    if (_permissionState == _ReminderPermissionState.granted) return true;

    setState(
      () => _permissionState = _ReminderPermissionState.requesting,
    );
    try {
      final granted = await _notificationGateway.requestPermission();
      final systemGranted =
          granted && await _notificationGateway.isPermissionGranted();
      if (!mounted) return false;
      setState(() {
        _permissionState = systemGranted
            ? _ReminderPermissionState.granted
            : _ReminderPermissionState.denied;
      });
      return systemGranted;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _permissionState = _ReminderPermissionState.error);
      return false;
    }
  }

  void _toggleMorningReminder() {
    setState(() {
      _morningReminderEnabled = !_morningReminderEnabled;
      _errorMessage = null;
    });
  }

  void _toggleEveningReminder() {
    setState(() {
      _eveningReminderEnabled = !_eveningReminderEnabled;
      _errorMessage = null;
    });
  }

  Future<void> _pickMorningReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _morningReminderTime,
      helpText: 'Hora del recordatorio de mañana',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (selected == null || !mounted) return;
    setState(() => _morningReminderTime = selected);
  }

  Future<void> _pickEveningReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _eveningReminderTime,
      helpText: 'Hora del recordatorio de noche',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (selected == null || !mounted) return;
    setState(() => _eveningReminderTime = selected);
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    if (_createFirstHabit && _habitTitleController.text.trim().isEmpty) {
      setState(
        () => _errorMessage = 'Escribe un nombre para tu primer hábito.',
      );
      return;
    }

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    try {
      final wantsDailyReminders =
          _morningReminderEnabled || _eveningReminderEnabled;
      if (wantsDailyReminders &&
          _permissionState != _ReminderPermissionState.granted) {
        await _ensureNotificationPermission();
      }

      final habitState =
          ref.read(habitControllerProvider(widget.userId)).valueOrNull;
      if (habitState == null) {
        throw StateError('El perfil del usuario todavía no está listo.');
      }
      final habitController =
          ref.read(habitControllerProvider(widget.userId).notifier);

      if (_createFirstHabit) {
        final existingHabit = habitState.getHabitById(_habitId);
        final reminderIsActive = _wantsHabitReminder &&
            (_permissionState == _ReminderPermissionState.granted ||
                existingHabit?.hasReminder == true);
        final habit = Habit(
          id: _habitId,
          title: _habitTitleController.text.trim(),
          category: _selectedCategory,
          frequency: existingHabit?.frequency ?? Frequency.daily(),
          createdAt: existingHabit?.createdAt ?? DateTime.now(),
          isArchived: existingHabit?.isArchived ?? false,
          isOneTime: existingHabit?.isOneTime ?? false,
          scheduledDate: existingHabit?.scheduledDate,
          hasReminder: reminderIsActive,
          reminderHour: reminderIsActive ? _habitReminderTime.hour : null,
          reminderMinute: reminderIsActive ? _habitReminderTime.minute : null,
        );
        if (existingHabit == null) {
          await habitController.createHabit(habit);
        } else {
          await habitController.updateHabit(habit);
        }
      }

      final now = DateTime.now();
      final updatedHabits =
          ref.read(habitControllerProvider(widget.userId)).valueOrNull ??
              habitState;
      final todayHabits = updatedHabits.getTodayHabits(now);
      final pendingHabits = todayHabits
          .where(
            (habit) => !updatedHabits.isHabitCompleted(habit.id, now),
          )
          .toList();
      await _notificationGateway.setDailyReminderSettings(
        DailyReminderSettings(
          morningEnabled: _morningReminderEnabled &&
              _permissionState == _ReminderPermissionState.granted,
          morningHour: _morningReminderTime.hour,
          morningMinute: _morningReminderTime.minute,
          eveningEnabled: _eveningReminderEnabled &&
              _permissionState == _ReminderPermissionState.granted,
          eveningHour: _eveningReminderTime.hour,
          eveningMinute: _eveningReminderTime.minute,
        ),
        snapshot: DailyReminderSnapshot(
          capturedAt: now,
          totalHabits: todayHabits.length,
          completedHabits: updatedHabits.getCompletionCount(now),
          firstPendingHabit:
              pendingHabits.isEmpty ? null : pendingHabits.first.title,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        kNotificationPermissionNoticePendingKey,
        wantsDailyReminders &&
            _permissionState != _ReminderPermissionState.granted,
      );

      await prefs.setBool(
        'onboarding_completed_${widget.userId}',
        true,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onComplete();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
        _errorMessage =
            'No pudimos guardar este paso. Tus datos siguen seguros. Intenta de nuevo.';
      });
    }
  }

  bool get _canContinue {
    if (_isCompleting ||
        _permissionState == _ReminderPermissionState.requesting) {
      return false;
    }
    if (_createFirstHabit && _habitTitleController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  String get _habitId => 'onboarding-first-habit-${widget.userId}';

  @override
  Widget build(BuildContext context) {
    final habitState =
        ref.watch(habitControllerProvider(widget.userId)).valueOrNull;
    if (habitState != null) {
      _hydrateExistingHabit(habitState);
    }
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600
                ? context.spacing.md
                : context.spacing.lg;
            final flowPadding = constraints.maxWidth < 390
                ? context.spacing.md
                : context.spacing.lg;
            final shellWidth = (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, 680.0)
                .toDouble();
            final flowContentWidth =
                (shellWidth - flowPadding * 2).clamp(0.0, double.infinity);
            final habitChoiceDirection =
                flowContentWidth < _habitChoiceComfortableHorizontalWidth ||
                        mediaQuery.textScaler.scale(14) > 18
                    ? Axis.vertical
                    : Axis.horizontal;

            return SingleChildScrollView(
              key: const ValueKey('onboarding-scroll-view'),
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                context.spacing.md,
                horizontalPadding,
                context.spacing.md + keyboardInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SizedBox(
                    width: shellWidth,
                    child: Container(
                      key: const ValueKey('onboarding-shell'),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(context.radii.extraLarge),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildFlow(
                        context,
                        contentPadding: flowPadding,
                        minHeight:
                            (constraints.maxHeight - context.spacing.md * 2)
                                .clamp(0, double.infinity),
                        habitChoiceDirection: habitChoiceDirection,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlow(
    BuildContext context, {
    required double contentPadding,
    required double minHeight,
    required Axis habitChoiceDirection,
  }) {
    final theme = Theme.of(context);
    final compactHeight = MediaQuery.sizeOf(context).height < 880;
    final spacerBaseline = compactHeight ? 722.0 : 690.0;
    final spacerMax = compactHeight
        ? context.spacing.xxl + context.spacing.lg + context.spacing.md
        : context.spacing.xxl +
            context.spacing.xl +
            context.spacing.lg +
            context.spacing.md;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        key: const ValueKey('onboarding-content-panel'),
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgress(context),
            KeyedSubtree(
              key: const ValueKey('onboarding-step-first-habit'),
              child: _buildCurrentStep(
                context,
                habitChoiceDirection: habitChoiceDirection,
              ),
            ),
            SizedBox(
              height: (minHeight - spacerBaseline).clamp(
                context.spacing.lg,
                spacerMax,
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: context.spacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  _errorMessage!,
                  key: const ValueKey('onboarding-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: context.spacing.lg),
            _buildNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Paso $_totalSteps de $_totalSteps',
              child: LinearProgressIndicator(
                key: const ValueKey('onboarding-progress'),
                value: 1,
                minHeight: context.spacing.xs,
                borderRadius: BorderRadius.circular(context.radii.pill),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            ),
          ),
          SizedBox(width: context.spacing.md),
          Text(
            '$_totalSteps / $_totalSteps',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context, {
    required Axis habitChoiceDirection,
  }) {
    return _buildHabitStep(
      context,
      habitChoiceDirection: habitChoiceDirection,
    );
  }

  Widget _buildHabitStep(
    BuildContext context, {
    required Axis habitChoiceDirection,
  }) {
    final theme = Theme.of(context);
    final editor = _buildHabitEditor(
      context,
      habitChoiceDirection: habitChoiceDirection,
    );
    final reminders = _buildReadyReminders(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 720 &&
            MediaQuery.textScalerOf(context).scale(16) <= 22;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Tu primer hábito',
                key: const ValueKey('onboarding-habit-title'),
                style: theme.textTheme.headlineLarge,
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              'Te proponemos uno pequeño. Edítalo o continúa sin crearlo.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.lg),
            if (useColumns)
              Row(
                key: const ValueKey('onboarding-habit-two-column'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: editor),
                  SizedBox(width: context.spacing.lg),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  SizedBox(width: context.spacing.lg),
                  Expanded(flex: 4, child: reminders),
                ],
              )
            else ...[
              KeyedSubtree(
                key: const ValueKey('onboarding-habit-single-column'),
                child: editor,
              ),
              SizedBox(height: context.spacing.lg),
              reminders,
            ],
          ],
        );
      },
    );
  }

  Widget _buildHabitEditor(
    BuildContext context, {
    required Axis habitChoiceDirection,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: ValueKey(
            'onboarding-habit-choice-'
            '${habitChoiceDirection == Axis.vertical ? 'vertical' : 'horizontal'}',
          ),
          child: SegmentedButton<bool>(
            key: const ValueKey('onboarding-habit-choice'),
            direction: habitChoiceDirection,
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(
                Size(0, kMinInteractiveDimension),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.transparent;
                }
                return theme.brightness == Brightness.dark
                    ? context.zentraPalette.tealSoft
                    : theme.colorScheme.primary;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.selected)) {
                  return theme.colorScheme.onSurfaceVariant;
                }
                return theme.brightness == Brightness.dark
                    ? Colors.black
                    : theme.colorScheme.onPrimary;
              }),
              side: WidgetStatePropertyAll(
                BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            segments: const [
              ButtonSegment(value: true, label: Text('Crear hábito')),
              ButtonSegment(value: false, label: Text('Saltar')),
            ],
            selected: {_createFirstHabit},
            onSelectionChanged: (selection) {
              setState(() {
                _createFirstHabit = selection.first;
                _errorMessage = null;
              });
            },
          ),
        ),
        if (_createFirstHabit) ...[
          SizedBox(height: context.spacing.md),
          TextField(
            key: const ValueKey('onboarding-habit-name'),
            controller: _habitTitleController,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Leer diez páginas',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            key: const ValueKey('onboarding-category-pills'),
            spacing: context.spacing.xxs,
            runSpacing: context.spacing.xs,
            children: Category.values
                .map(
                  (category) => _CategoryChoiceChip(
                    key: ValueKey('habit-category-${category.name}'),
                    category: category,
                    selected: _selectedCategory == category,
                    onSelected: () =>
                        setState(() => _selectedCategory = category),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReadyReminders(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('onboarding-reminders-ready'),
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xs,
            children: [
              Text(
                'RECORDATORIOS LISTOS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              TextButton(
                key: const ValueKey('onboarding-reminders-adjust'),
                onPressed: _showReminderAdjustments,
                child: const Text('Ajustar'),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              final morning = _ReminderReadyTile(
                key: const ValueKey('onboarding-morning-reminder'),
                icon: Icons.wb_twilight_outlined,
                title: 'Mañana',
                time: _morningReminderTime.format(context),
                selected: _morningReminderEnabled,
                onTap: _toggleMorningReminder,
              );
              final evening = _ReminderReadyTile(
                key: const ValueKey('onboarding-evening-reminder'),
                icon: Icons.nights_stay_outlined,
                title: 'Noche',
                time: _eveningReminderTime.format(context),
                selected: _eveningReminderEnabled,
                onTap: _toggleEveningReminder,
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    morning,
                    SizedBox(height: context.spacing.sm),
                    evening,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: morning),
                  SizedBox(width: context.spacing.sm),
                  Expanded(child: evening),
                ],
              );
            },
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            'Los activamos por ti. Puedes silenciarlos cuando quieras desde Ajustes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderAdjustments() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> updateTime({required bool morning}) async {
            if (morning) {
              await _pickMorningReminderTime();
            } else {
              await _pickEveningReminderTime();
            }
            if (sheetContext.mounted) setSheetState(() {});
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.lg,
                0,
                context.spacing.lg,
                context.spacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ajustar recordatorios',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: context.spacing.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mañana'),
                    subtitle: Text(_morningReminderTime.format(context)),
                    value: _morningReminderEnabled,
                    onChanged: (_) {
                      _toggleMorningReminder();
                      setSheetState(() {});
                    },
                    secondary: IconButton(
                      key: const ValueKey('onboarding-morning-time'),
                      onPressed: () => updateTime(morning: true),
                      icon: const Icon(Icons.schedule_outlined),
                      tooltip: 'Cambiar hora de mañana',
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Noche'),
                    subtitle: Text(_eveningReminderTime.format(context)),
                    value: _eveningReminderEnabled,
                    onChanged: (_) {
                      _toggleEveningReminder();
                      setSheetState(() {});
                    },
                    secondary: IconButton(
                      key: const ValueKey('onboarding-evening-time'),
                      onPressed: () => updateTime(morning: false),
                      icon: const Icon(Icons.schedule_outlined),
                      tooltip: 'Cambiar hora de noche',
                    ),
                  ),
                  SizedBox(height: context.spacing.md),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final shouldStack = MediaQuery.textScalerOf(context).scale(16) > 22 ||
        MediaQuery.sizeOf(context).width < 360;
    final primary = FilledButton(
      key: const ValueKey('onboarding-primary-action'),
      onPressed: _canContinue ? _nextStep : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.lg,
          vertical: context.spacing.md,
        ),
      ),
      child: _isCompleting
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Comenzar en Zentra'),
    );

    final back = TextButton(
      key: const ValueKey('onboarding-back-action'),
      onPressed: _isCompleting ? null : _previousStep,
      child: const Text('Atrás'),
    );

    if (shouldStack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          SizedBox(height: context.spacing.xs),
          back,
        ],
      );
    }

    return Row(
      children: [
        back,
        SizedBox(width: context.spacing.md),
        Expanded(child: primary),
      ],
    );
  }
}

class _CategoryChoiceChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChoiceChip({
    required this.category,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (category) {
      Category.agua => context.zentraPalette.water,
      Category.movimiento => context.zentraPalette.movement,
      Category.sueno => context.zentraPalette.sleep,
      Category.foco => context.zentraPalette.focus,
      Category.varios => context.zentraPalette.various,
    };
    return ChoiceChip(
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      label: Text(category.label),
      labelStyle: Theme.of(context).textTheme.labelLarge,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ReminderReadyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  const _ReminderReadyTile({
    required this.icon,
    required this.title,
    required this.time,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.65)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.medium),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle_outline_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.sm),
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
