import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../application/habit_controller.dart';
import '../application/session_controller.dart';
import '../domain/models.dart';
import '../infrastructure/app_logger.dart';
import '../infrastructure/notification_service.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/feedback_utils.dart';

const Map<Category, List<String>> _categorySuggestions = {
  Category.agua: [
    'Beber 2 litros de agua',
    'Tomar un vaso de agua al despertar',
    'Llevar mi botella de agua',
    'Beber agua antes de cada comida',
  ],
  Category.movimiento: [
    'Caminar 20 minutos',
    'Estirarme por la mañana',
    'Hacer 10 sentadillas',
    'Bailar una canción',
  ],
  Category.sueno: [
    'Dormir 8 horas',
    'Leer antes de dormir',
    'Dejar las pantallas una hora antes',
    'Preparar mi descanso',
  ],
  Category.foco: [
    'Trabajar 25 min sin distracciones',
    'Planear mis 3 prioridades',
    'Leer 20 páginas',
    'Practicar un idioma 10 min',
  ],
  Category.varios: [
    'Ordenar mi escritorio',
    'Llamar a un ser querido',
    'Practicar gratitud',
    'Aprender algo nuevo',
  ],
};

const _spanishWeekdays = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _spanishMonths = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _formatSpanishDate(DateTime date) {
  final weekday = _spanishWeekdays[date.weekday - 1];
  final month = _spanishMonths[date.month - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)} '
      '${date.day} de $month';
}

abstract class HabitFormNotificationGateway {
  Future<bool> requestPermission();

  Future<bool> isPermissionGranted();

  Future<void> setHabitRemindersEnabled(bool enabled);
}

class _SystemHabitFormNotificationGateway
    implements HabitFormNotificationGateway {
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
}

enum _FrequencyPreset { all, weekdays, weekends, custom }

enum _HabitMode { recurring, oneTime }

class HabitFormScreen extends ConsumerStatefulWidget {
  final String? habitId;
  final HabitFormNotificationGateway? notificationGateway;
  final DateTime Function()? now;

  const HabitFormScreen({
    super.key,
    this.habitId,
    this.notificationGateway,
    this.now,
  });

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  late final HabitFormNotificationGateway _notificationGateway;

  Category _selectedCategory = Category.varios;
  _FrequencyPreset _frequencyPreset = _FrequencyPreset.all;
  Set<int> _selectedDays = const {1, 2, 3, 4, 5, 6, 7};
  bool _showDaysError = false;
  bool _hasReminder = false;
  bool _isRequestingPermission = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  _HabitMode _mode = _HabitMode.recurring;
  late DateTime _scheduledDate;
  bool _isSaving = false;
  bool _isDeleting = false;
  String _currentHint = '';

  bool get _isEditing => widget.habitId != null;
  bool get _isOneTime => _mode == _HabitMode.oneTime;
  String get _entityLabel => _isOneTime ? 'actividad' : 'hábito';

  String get _screenTitle {
    if (_isEditing) return 'Editar $_entityLabel';
    return _isOneTime ? 'Nueva actividad' : 'Nuevo hábito';
  }

  String get _submitLabel {
    if (_isSaving) return 'Guardando...';
    if (_isEditing) return 'Guardar cambios';
    return _isOneTime ? 'Crear actividad' : 'Crear hábito';
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void initState() {
    super.initState();
    _notificationGateway =
        widget.notificationGateway ?? _SystemHabitFormNotificationGateway();
    _scheduledDate = _dateOnly(_now());
    _loadHabitData();
    _refreshHint();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _loadHabitData() {
    if (!_isEditing) return;
    final ownerId = ref.read(activeOwnerIdProvider);
    if (ownerId == null) return;
    final habit = ref
        .read(habitControllerProvider(ownerId))
        .valueOrNull
        ?.getHabitById(widget.habitId!);
    if (habit == null) return;

    _titleController.text = habit.title;
    _selectedCategory = habit.category;
    _selectedDays = habit.frequency.daysOfWeek.toSet();
    _frequencyPreset = _presetForDays(_selectedDays);
    _mode = habit.isOneTime ? _HabitMode.oneTime : _HabitMode.recurring;
    _hasReminder = habit.hasReminder;
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      _reminderTime = TimeOfDay(
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
    if (habit.scheduledDate != null) {
      _scheduledDate = _dateOnly(habit.scheduledDate!);
    }
  }

  _FrequencyPreset _presetForDays(Set<int> days) {
    if (days.length == DateTime.daysPerWeek) return _FrequencyPreset.all;
    if (days.length == 5 && days.containsAll(const {1, 2, 3, 4, 5})) {
      return _FrequencyPreset.weekdays;
    }
    if (days.length == 2 && days.containsAll(const {6, 7})) {
      return _FrequencyPreset.weekends;
    }
    return _FrequencyPreset.custom;
  }

  void _refreshHint() {
    final suggestions = _categorySuggestions[_selectedCategory] ?? const [];
    _currentHint = suggestions.isEmpty
        ? ''
        : suggestions[_random.nextInt(suggestions.length)];
  }

  void _selectCategory(Category category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _refreshHint();
    });
    triggerHaptic(HapticType.selection);
  }

  void _applySuggestion() {
    if (_currentHint.isEmpty) return;
    setState(() {
      _titleController
        ..text = _currentHint
        ..selection = TextSelection.collapsed(offset: _currentHint.length);
    });
    triggerHaptic(HapticType.light);
  }

  void _selectFrequency(_FrequencyPreset preset) {
    setState(() {
      _frequencyPreset = preset;
      _showDaysError = false;
      switch (preset) {
        case _FrequencyPreset.all:
          _selectedDays = const {1, 2, 3, 4, 5, 6, 7};
        case _FrequencyPreset.weekdays:
          _selectedDays = const {1, 2, 3, 4, 5};
        case _FrequencyPreset.weekends:
          _selectedDays = const {6, 7};
        case _FrequencyPreset.custom:
          break;
      }
    });
    triggerHaptic(HapticType.selection);
  }

  void _toggleDay(int day) {
    setState(() {
      final updated = Set<int>.of(_selectedDays);
      updated.contains(day) ? updated.remove(day) : updated.add(day);
      _selectedDays = updated;
      _frequencyPreset = _FrequencyPreset.custom;
      _showDaysError = false;
    });
    triggerHaptic(HapticType.selection);
  }

  void _selectMode(_HabitMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      if (mode == _HabitMode.oneTime) {
        final today = _dateOnly(_now());
        if (_scheduledDate.isBefore(today)) _scheduledDate = today;
      }
    });
    triggerHaptic(HapticType.selection);
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    if (_isRequestingPermission) return;
    if (!enabled) {
      setState(() => _hasReminder = false);
      triggerHaptic(HapticType.selection);
      return;
    }

    setState(() => _isRequestingPermission = true);
    try {
      var granted = await _notificationGateway.isPermissionGranted();
      if (!granted) granted = await _notificationGateway.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sin permiso no podemos enviar este recordatorio. '
                '${_isOneTime ? 'La actividad' : 'El hábito'} sí puede '
                'guardarse.',
              ),
            ),
          );
        }
        return;
      }
      await _notificationGateway.setHabitRemindersEnabled(true);
      if (!mounted) return;
      setState(() => _hasReminder = true);
      triggerHaptic(HapticType.light);
    } catch (error, stack) {
      AppLogger().error(
        'HabitForm',
        'Error requesting notification permission',
        error,
        stack,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos activar el recordatorio. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final theme = Theme.of(context);
    final categoryColor =
        AppTheme.getCategoryColor(_selectedCategory, theme.colorScheme);
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: categoryColor),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() => _reminderTime = time);
    triggerHaptic(HapticType.selection);
  }

  Future<void> _pickScheduledDate() async {
    final theme = Theme.of(context);
    final categoryColor =
        AppTheme.getCategoryColor(_selectedCategory, theme.colorScheme);
    final now = _dateOnly(_now());
    final initialDate = _scheduledDate.isBefore(now) ? now : _scheduledDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: categoryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    setState(() => _scheduledDate = _dateOnly(date));
    triggerHaptic(HapticType.selection);
  }

  void _selectRelativeDate(int dayOffset) {
    final date = _dateOnly(_now()).add(Duration(days: dayOffset));
    if (_sameDate(date, _scheduledDate)) return;
    setState(() => _scheduledDate = date);
    triggerHaptic(HapticType.selection);
  }

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<void> _saveHabit() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _titleFocusNode.requestFocus();
      return;
    }
    if (!_isOneTime && _selectedDays.isEmpty) {
      setState(() {
        _frequencyPreset = _FrequencyPreset.custom;
        _showDaysError = true;
      });
      return;
    }
    if (_isOneTime && _hasReminder) {
      final reminderDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );
      if (!reminderDateTime.isAfter(_now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Elige una fecha y hora futuras para este recordatorio.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final ownerId = ref.read(activeOwnerIdProvider);
      if (ownerId == null) {
        throw StateError('No active owner is available.');
      }
      final provider = habitControllerProvider(ownerId);
      final controller = ref.read(provider.notifier);
      final previous = _isEditing
          ? ref.read(provider).valueOrNull?.getHabitById(widget.habitId!)
          : null;
      final sortedDays = _selectedDays.toList()..sort();
      final habit = Habit(
        id: previous?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        frequency: _isOneTime
            ? Frequency.daily()
            : Frequency(isWeekly: true, daysOfWeek: sortedDays),
        createdAt: previous?.createdAt ?? _now(),
        isArchived: previous?.isArchived ?? false,
        isOneTime: _isOneTime,
        scheduledDate: _isOneTime ? _scheduledDate : null,
        hasReminder: _hasReminder,
        reminderHour: _hasReminder ? _reminderTime.hour : null,
        reminderMinute: _hasReminder ? _reminderTime.minute : null,
      );

      if (_isEditing) {
        await controller.updateHabit(habit);
      } else {
        await controller.createHabit(habit);
      }

      final warning = controller.consumeReminderWarning();
      if (warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning)),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error, stack) {
      AppLogger().error('HabitForm', 'Error saving habit', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'No pudimos guardar los cambios.'
                  : 'No pudimos crear '
                      '${_isOneTime ? 'la actividad' : 'el hábito'}.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteHabit() async {
    if (!_isEditing || _isDeleting) return;
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar $_entityLabel',
      message: '¿Eliminar ${_isOneTime ? 'esta actividad' : 'este hábito'} y '
          'su historial? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_forever_rounded,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final ownerId = ref.read(activeOwnerIdProvider);
      if (ownerId == null) {
        throw StateError('No active owner is available.');
      }
      await ref
          .read(habitControllerProvider(ownerId).notifier)
          .deleteHabit(widget.habitId!);
      if (mounted) Navigator.of(context).pop();
    } catch (error, stack) {
      AppLogger().error('HabitForm', 'Error deleting habit', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No pudimos eliminar '
              '${_isOneTime ? 'la actividad' : 'el hábito'}. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String get _frequencySummary {
    if (_isOneTime) return 'Una sola vez';
    if (_selectedDays.length == DateTime.daysPerWeek) return 'Todos los días';
    if (_selectedDays.length == 5 &&
        _selectedDays.containsAll(const {1, 2, 3, 4, 5})) {
      return 'L a V';
    }
    if (_selectedDays.length == 2 && _selectedDays.containsAll(const {6, 7})) {
      return 'S y D';
    }
    if (_selectedDays.isEmpty) return 'Elige días';
    return '${_selectedDays.length} días';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(16);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      key: const ValueKey('habit-form-screen'),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HabitFormHeader(
              title: _screenTitle,
              mode: _mode,
              selectedCategory: _selectedCategory,
              isEditing: _isEditing,
              isDeleting: _isDeleting,
              onBack: () => Navigator.of(context).maybePop(),
              onModeSelected: _selectMode,
              onDelete: _deleteHabit,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth < 360 || textScale > 22;
                    return SingleChildScrollView(
                      key: const ValueKey('habit-form-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        compact ? context.spacing.md : context.spacing.lg,
                        compact ? context.spacing.md : 20,
                        compact ? context.spacing.md : context.spacing.lg,
                        keyboardOpen ? context.spacing.lg : context.spacing.xl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          key: const ValueKey('habit-form-content'),
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _IdentitySection(
                                titleController: _titleController,
                                titleFocusNode: _titleFocusNode,
                                currentHint: _currentHint,
                                selectedCategory: _selectedCategory,
                                validationMessage: _isOneTime
                                    ? 'Escribe el nombre de la actividad'
                                    : 'Escribe el nombre del hábito',
                                onTitleChanged: (_) => setState(() {}),
                                onUseSuggestion: _applySuggestion,
                                onCategorySelected: _selectCategory,
                              ),
                              SizedBox(height: compact ? 18 : 20),
                              AnimatedSwitcher(
                                duration: context.motionPolicy.duration(
                                  const Duration(milliseconds: 240),
                                ),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _ScheduleSection(
                                  key: ValueKey(
                                    'habit-schedule-${_mode.name}',
                                  ),
                                  preset: _frequencyPreset,
                                  selectedDays: _selectedDays,
                                  showDaysError: _showDaysError,
                                  isOneTime: _isOneTime,
                                  scheduledDate: _scheduledDate,
                                  today: _dateOnly(_now()),
                                  summary: _frequencySummary,
                                  onPresetSelected: _selectFrequency,
                                  onDayToggled: _toggleDay,
                                  onTodaySelected: () => _selectRelativeDate(0),
                                  onTomorrowSelected: () =>
                                      _selectRelativeDate(1),
                                  onDateTap: _pickScheduledDate,
                                ),
                              ),
                              SizedBox(height: compact ? 16 : 18),
                              _ReminderRow(
                                enabled: _hasReminder,
                                requestingPermission: _isRequestingPermission,
                                reminderTime: _reminderTime,
                                onEnabledChanged: _setReminderEnabled,
                                onTimeTap: _pickReminderTime,
                              ),
                              if (keyboardOpen) ...[
                                SizedBox(height: context.spacing.lg),
                                _SubmitButton(
                                  label: _submitLabel,
                                  isEditing: _isEditing,
                                  isSaving: _isSaving,
                                  onPressed: _saveHabit,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : _SubmitBar(
              label: _submitLabel,
              isEditing: _isEditing,
              isSaving: _isSaving,
              onPressed: _saveHabit,
            ),
    );
  }
}

class _HabitFormHeader extends StatelessWidget {
  final String title;
  final _HabitMode mode;
  final Category selectedCategory;
  final bool isEditing;
  final bool isDeleting;
  final VoidCallback onBack;
  final ValueChanged<_HabitMode> onModeSelected;
  final VoidCallback onDelete;

  const _HabitFormHeader({
    required this.title,
    required this.mode,
    required this.selectedCategory,
    required this.isEditing,
    required this.isDeleting,
    required this.onBack,
    required this.onModeSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 360 ? 12.0 : 20.0;
    final backgroundColor = isDark
        ? context.zentraPalette.salviaFormHeader
        : AppTheme.getCategoryTint(selectedCategory, Brightness.light);

    return AnimatedContainer(
      key: const ValueKey('habit-form-header'),
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 240),
      ),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          18,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('habit-back'),
                        tooltip: 'Atrás',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      if (isEditing)
                        PopupMenuButton<String>(
                          key: const ValueKey('habit-more-menu'),
                          tooltip: 'Más opciones',
                          enabled: !isDeleting,
                          onSelected: (value) {
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              key: const ValueKey('habit-delete'),
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: isDeleting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.more_horiz_rounded),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _HabitModeSelector(
                  selected: mode,
                  onSelected: onModeSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitModeSelector extends StatelessWidget {
  final _HabitMode selected;
  final ValueChanged<_HabitMode> onSelected;

  const _HabitModeSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      key: const ValueKey('habit-mode-selector'),
      color: isDark
          ? Colors.black.withValues(alpha: 0.42)
          : Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(context.radii.medium),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _HabitModeOption(
                key: const ValueKey('habit-mode-recurring'),
                label: 'Se repite',
                selected: selected == _HabitMode.recurring,
                onTap: () => onSelected(_HabitMode.recurring),
              ),
            ),
            Expanded(
              child: _HabitModeOption(
                key: const ValueKey('habit-mode-one-time'),
                label: 'Una sola vez',
                selected: selected == _HabitMode.oneTime,
                onTap: () => onSelected(_HabitMode.oneTime),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HabitModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.medium - 4),
          child: AnimatedContainer(
            duration: context.motionPolicy.duration(
              const Duration(milliseconds: 240),
            ),
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
            decoration: BoxDecoration(
              color: selected
                  ? isDark
                      ? context.zentraPalette.tealSoft
                      : context.zentraPalette.surfaceCard
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(context.radii.medium - 4),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected && isDark
                    ? Colors.black
                    : selected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final String currentHint;
  final Category selectedCategory;
  final String validationMessage;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onUseSuggestion;
  final ValueChanged<Category> onCategorySelected;

  const _IdentitySection({
    required this.titleController,
    required this.titleFocusNode,
    required this.currentHint,
    required this.selectedCategory,
    required this.validationMessage,
    required this.onTitleChanged,
    required this.onUseSuggestion,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('QUÉ QUIERES HACER'),
        const SizedBox(height: 8),
        TextFormField(
          key: const ValueKey('habit-title-field'),
          controller: titleController,
          focusNode: titleFocusNode,
          textInputAction: TextInputAction.done,
          onChanged: onTitleChanged,
          decoration: InputDecoration(
            hintText:
                currentHint.isEmpty ? 'Ej. Caminar 20 minutos' : currentHint,
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? context.zentraPalette.surfaceCard
                : Colors.white,
            suffixIcon: IconButton(
              tooltip: 'Usar sugerencia',
              onPressed: onUseSuggestion,
              icon: Icon(Icons.auto_awesome_rounded, color: color),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radii.medium),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radii.medium),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return validationMessage;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const _SectionLabel('CATEGORÍA'),
        const SizedBox(height: 8),
        _CategorySelector(
          selected: selectedCategory,
          onSelected: onCategorySelected,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.zentraPalette.brandTeal,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final Category selected;
  final ValueChanged<Category> onSelected;

  const _CategorySelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 6.0 : 10.0;
        final available = constraints.maxWidth - gap * 4;
        final itemWidth = available / 5;
        final row = Row(
          key: const ValueKey('habit-category-grid'),
          children: [
            for (var index = 0; index < Category.values.length; index++) ...[
              if (index > 0) SizedBox(width: gap),
              Expanded(
                child: _CategoryOption(
                  key: ValueKey(
                    'habit-category-${Category.values[index].name}',
                  ),
                  category: Category.values[index],
                  selected: Category.values[index] == selected,
                  onTap: () => onSelected(Category.values[index]),
                ),
              ),
            ],
          ],
        );
        if (itemWidth >= 44) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('habit-category-grid'),
            children: [
              for (var index = 0; index < Category.values.length; index++) ...[
                if (index > 0) SizedBox(width: gap),
                SizedBox.square(
                  dimension: 52,
                  child: _CategoryOption(
                    key: ValueKey(
                      'habit-category-${Category.values[index].name}',
                    ),
                    category: Category.values[index],
                    selected: Category.values[index] == selected,
                    onTap: () => onSelected(Category.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.getSalviaCategoryColor(
      category,
      theme.brightness,
    );
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Categoría ${category.label}',
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.radii.medium),
            child: AnimatedContainer(
              duration: context.motionPolicy.duration(
                const Duration(milliseconds: 180),
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: isDark ? 0.18 : 0.12)
                    : isDark
                        ? context.zentraPalette.surfaceCard
                        : Colors.white,
                borderRadius: BorderRadius.circular(context.radii.medium),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(
                AppTheme.getCategoryIcon(category),
                color: color,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final _FrequencyPreset preset;
  final Set<int> selectedDays;
  final bool showDaysError;
  final bool isOneTime;
  final DateTime scheduledDate;
  final DateTime today;
  final String summary;
  final ValueChanged<_FrequencyPreset> onPresetSelected;
  final ValueChanged<int> onDayToggled;
  final VoidCallback onTodaySelected;
  final VoidCallback onTomorrowSelected;
  final VoidCallback onDateTap;

  const _ScheduleSection({
    required this.preset,
    required this.selectedDays,
    required this.showDaysError,
    required this.isOneTime,
    required this.scheduledDate,
    required this.today,
    required this.summary,
    required this.onPresetSelected,
    required this.onDayToggled,
    required this.onTodaySelected,
    required this.onTomorrowSelected,
    required this.onDateTap,
    super.key,
  });

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDatePreset = _sameDate(scheduledDate, today)
        ? 0
        : _sameDate(scheduledDate, tomorrow)
            ? 1
            : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionLabel(isOneTime ? 'QUÉ DÍA' : 'CUÁNDO'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _WeekdayRow(
          selectedDays: isOneTime ? {scheduledDate.weekday} : selectedDays,
          isOneTime: isOneTime,
          onDayToggled: onDayToggled,
        ),
        const SizedBox(height: 10),
        if (isOneTime) ...[
          _CompactSelector<int>(
            key: const ValueKey('habit-date-presets'),
            selected: selectedDatePreset,
            options: const [
              (value: 0, label: 'Hoy', keyName: 'habit-date-today'),
              (value: 1, label: 'Mañana', keyName: 'habit-date-tomorrow'),
              (value: 2, label: 'Elegir', keyName: 'habit-date-pick'),
            ],
            onSelected: (value) {
              switch (value) {
                case 0:
                  onTodaySelected();
                case 1:
                  onTomorrowSelected();
                case 2:
                  onDateTap();
              }
            },
          ),
          const SizedBox(height: 10),
          _InlineAction(
            key: const ValueKey('habit-scheduled-date'),
            icon: Icons.calendar_month_outlined,
            label: _formatSpanishDate(scheduledDate),
            onTap: onDateTap,
          ),
        ] else ...[
          _CompactSelector<_FrequencyPreset>(
            key: const ValueKey('habit-frequency-presets'),
            selected: preset,
            options: const [
              (
                value: _FrequencyPreset.all,
                label: 'Todos',
                keyName: 'habit-frequency-all',
              ),
              (
                value: _FrequencyPreset.weekdays,
                label: 'L-V',
                keyName: 'habit-frequency-weekdays',
              ),
              (
                value: _FrequencyPreset.weekends,
                label: 'S-D',
                keyName: 'habit-frequency-weekends',
              ),
              (
                value: _FrequencyPreset.custom,
                label: 'Otro',
                keyName: 'habit-frequency-custom',
              ),
            ],
            onSelected: onPresetSelected,
          ),
          if (showDaysError) ...[
            const SizedBox(height: 6),
            Text(
              'Selecciona al menos un día',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  final Set<int> selectedDays;
  final bool isOneTime;
  final ValueChanged<int> onDayToggled;

  const _WeekdayRow({
    required this.selectedDays,
    required this.isOneTime,
    required this.onDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final cell = (constraints.maxWidth - gap * 6) / 7;
        Widget day(Weekday weekday) => _DayOption(
              key: ValueKey('habit-day-${weekday.value}'),
              weekday: weekday,
              selected: selectedDays.contains(weekday.value),
              informative: isOneTime,
              onTap: isOneTime ? null : () => onDayToggled(weekday.value),
            );
        if (cell >= 42) {
          return Row(
            key: const ValueKey('habit-custom-days'),
            children: [
              for (var index = 0; index < Weekday.values.length; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: day(Weekday.values[index]),
                  ),
                ),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          key: const ValueKey('habit-custom-days'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < Weekday.values.length; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox.square(
                  dimension: 44,
                  child: day(Weekday.values[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayOption extends StatelessWidget {
  final Weekday weekday;
  final bool selected;
  final bool informative;
  final VoidCallback? onTap;

  const _DayOption({
    required this.weekday,
    required this.selected,
    required this.informative,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.brightness == Brightness.dark
        ? context.zentraPalette.tealSoft
        : theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;
    final background = selected && !informative
        ? primary
        : theme.brightness == Brightness.dark
            ? context.zentraPalette.surfaceCard
            : Colors.white;
    final foreground = selected && !informative
        ? theme.brightness == Brightness.dark
            ? Colors.black
            : theme.colorScheme.onPrimary
        : selected
            ? primary
            : muted.withValues(alpha: informative ? 0.45 : 1);
    return Semantics(
      button: !informative,
      selected: selected,
      label: weekday.label,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: BorderSide(
            color: selected && informative
                ? primary
                : selected && !informative
                    ? primary
                    : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              weekday.shortLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSelector<T> extends StatelessWidget {
  final T selected;
  final List<({T value, String label, String keyName})> options;
  final ValueChanged<T> onSelected;

  const _CompactSelector({
    required this.selected,
    required this.options,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? context.zentraPalette.surfaceCard
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(context.radii.medium),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: Semantics(
                  key: ValueKey(option.keyName),
                  button: true,
                  selected: selected == option.value,
                  label: option.label,
                  child: InkWell(
                    onTap: () => onSelected(option.value),
                    borderRadius: BorderRadius.circular(
                      context.radii.medium - 4,
                    ),
                    child: AnimatedContainer(
                      duration: context.motionPolicy.duration(
                        const Duration(milliseconds: 180),
                      ),
                      constraints: const BoxConstraints(minHeight: 46),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected == option.value
                            ? isDark
                                ? context.zentraPalette.tealSoft
                                : theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          context.radii.medium - 4,
                        ),
                      ),
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected == option.value
                              ? isDark
                                  ? Colors.black
                                  : theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: selected == option.value
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.brightness == Brightness.dark
          ? context.zentraPalette.surfaceCard
          : Colors.white,
      borderRadius: BorderRadius.circular(context.radii.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
          child: Row(
            children: [
              Icon(icon, color: context.zentraPalette.brandTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final bool enabled;
  final bool requestingPermission;
  final TimeOfDay reminderTime;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTimeTap;

  const _ReminderRow({
    required this.enabled,
    required this.requestingPermission,
    required this.reminderTime,
    required this.onEnabledChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.brightness == Brightness.dark
          ? context.zentraPalette.surfaceCard
          : Colors.white,
      borderRadius: BorderRadius.circular(context.radii.medium),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: EdgeInsets.only(
          left: context.spacing.md,
          right: context.spacing.sm,
        ),
        child: Row(
          children: [
            requestingPermission
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.notifications_none_rounded,
                    color: context.zentraPalette.brandTeal,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                requestingPermission ? 'Revisando permiso...' : 'Recordarme',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (enabled)
              TextButton(
                key: const ValueKey('habit-reminder-time'),
                onPressed: onTimeTap,
                child: Text(reminderTime.format(context)),
              ),
            Switch.adaptive(
              key: const ValueKey('habit-reminder-toggle'),
              value: enabled,
              onChanged: requestingPermission ? null : onEnabledChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final String label;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.label,
    required this.isEditing,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(
          context.spacing.lg,
          context.spacing.sm,
          context.spacing.lg,
          context.spacing.sm,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _SubmitButton(
              label: label,
              isEditing: isEditing,
              isSaving: isSaving,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.isEditing,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark ? Colors.black : theme.colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton.icon(
        key: const ValueKey('habit-submit'),
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? context.zentraPalette.tealSoft
              : theme.colorScheme.primary,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radii.medium),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Icon(isEditing ? Icons.save_outlined : Icons.add_rounded),
        label: Text(label),
      ),
    );
  }
}
