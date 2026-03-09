import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../domain/models.dart';
import '../application/habit_provider.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/app_logger.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/feedback_utils.dart';

/// Sugerencias de hábitos por categoría
const Map<Category, List<String>> _categorySuggestions = {
  Category.agua: [
    'Beber 2 litros de agua',
    'Tomar un vaso de agua al despertar',
    'Llevar botella de agua al trabajo',
    'Beber agua antes de cada comida',
    'Tomar té o infusión sin azúcar',
    'Tomar agua con limón en ayunas',
    'Evitar bebidas azucaradas',
    'Hidratarse después de ejercicio',
  ],
  Category.movimiento: [
    'Caminar 10,000 pasos',
    'Hacer 20 minutos de ejercicio',
    'Estiramientos por la mañana',
    'Subir escaleras en vez de elevador',
    'Hacer 10 sentadillas',
    'Salir a correr 15 minutos',
    'Hacer yoga 10 minutos',
    'Hacer 1 minuto de plancha',
    'Bailar una canción',
    'Pasear al perro',
    'Hacer 10 flexiones',
    'Nadar 20 minutos',
    'Andar en bicicleta',
  ],
  Category.sueno: [
    'Dormir 8 horas',
    'Acostarme antes de las 11pm',
    'No usar pantallas 1h antes de dormir',
    'Leer 15 minutos antes de dormir',
    'Meditar 5 minutos antes de dormir',
    'Despertar sin snooze',
    'Preparar la ropa del día siguiente',
    'Mantener horario fijo de dormir',
    'No cenar pesado',
    'Usar modo nocturno en dispositivos',
    'Ventilar la habitación antes de dormir',
  ],
  Category.foco: [
    'Trabajar 25 min sin distracciones',
    'Revisar emails solo 2 veces al día',
    'Planear las 3 tareas del día',
    'Apagar notificaciones al trabajar',
    'Leer 20 páginas de un libro',
    'Practicar un idioma 10 min',
    'Escribir en un diario',
    'Hacer una sola tarea a la vez',
    'Organizar el espacio de trabajo',
    'Definir 1 prioridad del día',
    'Desactivar redes sociales al trabajar',
    'Hacer brain dump (vaciar la mente)',
  ],
  Category.varios: [
    'Ordenar mi escritorio',
    'Llamar a un ser querido',
    'Practicar gratitud',
    'Tomar vitaminas',
    'Revisar mis finanzas',
    'Cocinar en casa',
    'No gastar en cosas innecesarias',
    'Hacer la cama al levantarse',
    'Sacar la basura',
    'Regar las plantas',
    'Practicar un hobby 15 min',
    'Aprender algo nuevo',
    'Hacer una buena acción',
    'Desconectarse de redes 1 hora',
    'Salir a tomar aire fresco',
    'Escuchar un podcast educativo',
    'Revisar el calendario del día',
  ],
};

/// Obtiene una sugerencia aleatoria para una categoría
String _getRandomSuggestion(Category category) {
  final suggestions = _categorySuggestions[category] ?? [];
  if (suggestions.isEmpty) return '';
  final random = Random();
  return suggestions[random.nextInt(suggestions.length)];
}

/// Screen for creating or editing a habit
class HabitFormScreen extends StatefulWidget {
  final String? habitId;

  const HabitFormScreen({super.key, this.habitId});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _uuid = const Uuid();
  final _daysShakeKey = GlobalKey<ShakeWidgetState>();

  Category _selectedCategory = Category.varios;
  bool _isWeekly = true; // true = Semanal (recurrente), false = Única (one-time)
  bool _isOneTime = false;
  Set<int> _selectedDays = {1, 2, 3, 4, 5};
  bool _isSaving = false; // Prevent double save
  String _currentHint = '';
  
  // Reminder settings
  bool _hasReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  
  // Calendar scheduling for one-time tasks
  bool _addToCalendar = false;
  DateTime _scheduledDate = DateTime.now();

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    _loadHabitData();
    _updateHint();
  }

  void _loadHabitData() {
    if (_isEditing) {
      final provider = context.read<HabitProvider>();
      final habit = provider.getHabitById(widget.habitId!);

      if (habit != null) {
        _titleController.text = habit.title;
        _selectedCategory = habit.category;
        _isOneTime = habit.isOneTime;
        _isWeekly = !habit.isOneTime && habit.frequency.isWeekly;
        _selectedDays = habit.frequency.daysOfWeek.toSet();
        _hasReminder = habit.hasReminder;
        if (habit.reminderHour != null && habit.reminderMinute != null) {
          _reminderTime = TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!);
        }
        // Load scheduled date for one-time tasks
        if (habit.scheduledDate != null) {
          _addToCalendar = true;
          _scheduledDate = habit.scheduledDate!;
        }
      }
    }
  }

  void _updateHint() {
    setState(() {
      _currentHint = _getRandomSuggestion(_selectedCategory);
    });
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
      _currentHint = _getRandomSuggestion(category);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _setAllDays() {
    setState(() {
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
    });
  }

  void _setWeekdays() {
    setState(() {
      _selectedDays = {1, 2, 3, 4, 5};
    });
  }

  void _setWeekends() {
    setState(() {
      _selectedDays = {6, 7};
    });
  }

  void _clearDays() {
    setState(() {
      _selectedDays = {};
    });
  }

  Future<void> _saveHabit() async {
    final logger = AppLogger();
    logger.info('HabitForm', '_saveHabit called, _isSaving=$_isSaving, _isEditing=$_isEditing');
    
    // Prevent double save
    if (_isSaving) {
      logger.warning('HabitForm', '_saveHabit blocked - already saving');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      logger.warning('HabitForm', 'Form validation failed');
      return;
    }

    // Validate frequency selection (only for recurring tasks)
    if (!_isOneTime && _isWeekly && _selectedDays.isEmpty) {
      logger.warning('HabitForm', 'No days selected for weekly habit');
      _daysShakeKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día de la semana'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    logger.info('HabitForm', 'Starting save process...');
    
    try {
      final provider = context.read<HabitProvider>();
      logger.info('HabitForm', 'Got HabitProvider');

      // For one-time tasks, use daily frequency (appears every day until done)
      final sortedDays = _selectedDays.toList()..sort();
      final frequency = _isOneTime
          ? Frequency.daily()
          : Frequency(
              isWeekly: true,
              daysOfWeek: sortedDays,
            );

      final habitId = _isEditing ? widget.habitId! : _uuid.v4();
      logger.info('HabitForm', 'Creating habit object with id=$habitId, title=${_titleController.text.trim()}');
      
      final habit = Habit(
        id: habitId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        frequency: frequency,
        createdAt: _isEditing
            ? provider.getHabitById(widget.habitId!)!.createdAt
            : DateTime.now(),
        isOneTime: _isOneTime,
        scheduledDate: (_isOneTime && _addToCalendar) ? _scheduledDate : null,
        hasReminder: _hasReminder,
        reminderHour: _hasReminder ? _reminderTime.hour : null,
        reminderMinute: _hasReminder ? _reminderTime.minute : null,
      );

      if (_isEditing) {
        logger.info('HabitForm', 'Calling updateHabit...');
        await provider.updateHabit(habit);
        logger.info('HabitForm', 'updateHabit completed');
      } else {
        logger.info('HabitForm', 'Calling createHabit...');
        await provider.createHabit(habit);
        logger.info('HabitForm', 'createHabit completed');
      }

      // Schedule or cancel reminder notification (wrapped in try-catch to not block saving)
      try {
        logger.info('HabitForm', 'Setting up notifications, hasReminder=$_hasReminder, isOneTime=$_isOneTime');
        final notificationService = NotificationService();
        await notificationService.initialize();
        if (_hasReminder) {
          logger.info('HabitForm', 'Scheduling habit reminder...');
          // Para tareas únicas, programar todos los días hasta que se complete
          final days = _isOneTime ? [1, 2, 3, 4, 5, 6, 7] : (sortedDays.isNotEmpty ? sortedDays : [1, 2, 3, 4, 5, 6, 7]);
          await notificationService.scheduleHabitReminder(
            habitId: habit.id,
            habitTitle: habit.title,
            hour: _reminderTime.hour,
            minute: _reminderTime.minute,
            daysOfWeek: days,
          );
          logger.info('HabitForm', 'Reminder scheduled');
        } else if (_isEditing) {
          logger.info('HabitForm', 'Canceling existing reminder (editing)...');
          await notificationService.cancelHabitReminder(habit.id);
          logger.info('HabitForm', 'Reminder canceled');
        }
      } catch (e, stack) {
        logger.error('HabitForm', 'Error scheduling notification', e, stack);
      }

      logger.info('HabitForm', 'Save complete, mounted=$mounted, calling Navigator.pop()');
      if (mounted) {
        Navigator.of(context).pop();
        logger.info('HabitForm', 'Navigator.pop() called');
      }
    } catch (e, stack) {
      logger.error('HabitForm', 'Error saving habit', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el hábito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      logger.info('HabitForm', 'Finally block, mounted=$mounted');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Color dinámico basado en la categoría seleccionada
    final categoryColor =
        AppTheme.getCategoryColor(_selectedCategory, colorScheme);

    return Theme(
      // Override theme with category color
      data: theme.copyWith(
        colorScheme: colorScheme.copyWith(
          primary: categoryColor,
          primaryContainer: categoryColor.withValues(alpha: isDark ? 0.3 : 0.2),
          onPrimaryContainer:
              isDark ? categoryColor : categoryColor.withValues(alpha: 0.9),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: categoryColor,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Hábito' : 'Nuevo Hábito'),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final habitProvider = context.read<HabitProvider>();
                  final navigator = Navigator.of(context);
                  
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: 'Eliminar hábito',
                    message: '¿Estás seguro de que quieres eliminar este hábito? Esta acción no se puede deshacer.',
                    confirmText: 'Eliminar',
                    cancelText: 'Cancelar',
                    icon: Icons.delete_forever_rounded,
                    isDangerous: true,
                  );

                  if (confirmed == true) {
                    await habitProvider.deleteHabit(widget.habitId!);
                    navigator.pop();
                  }
                },
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card with title input - Hero animation para el icono
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Hero animation del icono de categoría
                              Hero(
                                tag: _isEditing 
                                    ? 'habit_icon_${widget.habitId}'
                                    : 'new_habit_icon',
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: categoryColor.opacity15,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    AppTheme.getCategoryIcon(_selectedCategory),
                                    color: categoryColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Qué hábito quieres crear?',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Define un objetivo claro y alcanzable',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: _currentHint.isNotEmpty
                                  ? _currentHint
                                  : 'Ej: Beber 8 vasos de agua',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant
                                    .opacity60,
                              ),
                              filled: true,
                              fillColor: AppTheme.getContainerColor(colorScheme, isDark),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: categoryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              suffixIcon: _titleController.text.isEmpty &&
                                      _currentHint.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 22,
                                        color: categoryColor,
                                      ),
                                      tooltip: 'Usar sugerencia',
                                      onPressed: () {
                                        triggerHaptic(HapticType.success);
                                        setState(() {
                                          _titleController.text = _currentHint;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyLarge,
                            onChanged: (value) {
                              setState(() {});
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El título no puede estar vacío';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Section
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 20,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Categoría',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Category chips - responsive grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final buttonWidth = (constraints.maxWidth - 10) / 2;
                              return Column(
                                children: [
                                  // Row 1: Agua, Movimiento
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: buttonWidth,
                                        child: _CategoryChip(
                                          category: Category.agua,
                                          isSelected: _selectedCategory == Category.agua,
                                          catColor: AppTheme.getCategoryColor(Category.agua, colorScheme),
                                          isDark: isDark,
                                          colorScheme: colorScheme,
                                          onTap: () => _selectCategory(Category.agua),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: buttonWidth,
                                        child: _CategoryChip(
                                          category: Category.movimiento,
                                          isSelected: _selectedCategory == Category.movimiento,
                                          catColor: AppTheme.getCategoryColor(Category.movimiento, colorScheme),
                                          isDark: isDark,
                                          colorScheme: colorScheme,
                                          onTap: () => _selectCategory(Category.movimiento),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Row 2: Sueño, Foco
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: buttonWidth,
                                        child: _CategoryChip(
                                          category: Category.sueno,
                                          isSelected: _selectedCategory == Category.sueno,
                                          catColor: AppTheme.getCategoryColor(Category.sueno, colorScheme),
                                          isDark: isDark,
                                          colorScheme: colorScheme,
                                          onTap: () => _selectCategory(Category.sueno),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: buttonWidth,
                                        child: _CategoryChip(
                                          category: Category.foco,
                                          isSelected: _selectedCategory == Category.foco,
                                          catColor: AppTheme.getCategoryColor(Category.foco, colorScheme),
                                          isDark: isDark,
                                          colorScheme: colorScheme,
                                          onTap: () => _selectCategory(Category.foco),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Row 3: Varios (full width)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _CategoryChip(
                                      category: Category.varios,
                                      isSelected: _selectedCategory == Category.varios,
                                      catColor: AppTheme.getCategoryColor(Category.varios, colorScheme),
                                      isDark: isDark,
                                      colorScheme: colorScheme,
                                      onTap: () => _selectCategory(Category.varios),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Frequency Section
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Frecuencia',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Frequency Type Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: AppTheme.getContainerDecoration(
                              colorScheme, 
                              isDark, 
                              borderRadius: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _FrequencyTypeButton(
                                    label: 'Semanal',
                                    isSelected: !_isOneTime,
                                    accentColor: categoryColor,
                                    onTap: () {
                                      setState(() {
                                        _isOneTime = false;
                                        _isWeekly = true;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _FrequencyTypeButton(
                                    label: 'Única',
                                    isSelected: _isOneTime,
                                    accentColor: categoryColor,
                                    onTap: () {
                                      setState(() {
                                        _isOneTime = true;
                                        _isWeekly = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!_isOneTime) ...[
                            const SizedBox(height: 20),

                            // Quick Actions Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickActionButton(
                                  icon: Icons.date_range_rounded,
                                  label: 'Todos',
                                  isActive: _selectedDays.length == 7,
                                  accentColor: categoryColor,
                                  isDark: isDark,
                                  onTap: _setAllDays,
                                ),
                                _QuickActionButton(
                                  icon: Icons.work_rounded,
                                  label: 'L-V',
                                  isActive: _selectedDays.length == 5 &&
                                      _selectedDays
                                          .containsAll({1, 2, 3, 4, 5}),
                                  accentColor: categoryColor,
                                  isDark: isDark,
                                  onTap: _setWeekdays,
                                ),
                                _QuickActionButton(
                                  icon: Icons.weekend_rounded,
                                  label: 'S-D',
                                  isActive: _selectedDays.length == 2 &&
                                      _selectedDays.containsAll({6, 7}),
                                  accentColor: categoryColor,
                                  isDark: isDark,
                                  onTap: _setWeekends,
                                ),
                                _QuickActionButton(
                                  icon: Icons.clear_rounded,
                                  label: 'Limpiar',
                                  isActive: false,
                                  accentColor: colorScheme.error,
                                  isDark: isDark,
                                  isSmall: false,
                                  onTap: _clearDays,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Day Selection - Beautiful circular buttons with shake animation
                            ShakeWidget(
                              key: _daysShakeKey,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: Weekday.values.map((weekday) {
                                  final isSelected =
                                      _selectedDays.contains(weekday.value);
                                  return Flexible(
                                    child: _DayButton(
                                      label: weekday.shortLabel,
                                      isSelected: isSelected,
                                      accentColor: categoryColor,
                                      isDark: isDark,
                                      onTap: () => _toggleDay(weekday.value),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            if (_selectedDays.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.opacity10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getDaysDescription(),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: categoryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else ...[
                            // One-time task description
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: categoryColor.opacity10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: categoryColor.opacity30,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.task_alt_rounded,
                                    size: 22,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Esta tarea desaparecerá al completarse',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Add to calendar switch
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 20,
                                  color: categoryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Agregar al calendario',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _addToCalendar,
                                  onChanged: (value) {
                                    setState(() {
                                      _addToCalendar = value;
                                      if (value) {
                                        _scheduledDate = DateTime.now();
                                      }
                                    });
                                    triggerHaptic(HapticType.light);
                                  },
                                  activeTrackColor: categoryColor.withValues(alpha: 0.5),
                                  activeThumbColor: categoryColor,
                                ),
                              ],
                            ),
                            
                            // Date picker (only if addToCalendar is true)
                            if (_addToCalendar) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _scheduledDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: theme.copyWith(
                                          colorScheme: colorScheme.copyWith(
                                            primary: categoryColor,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(() => _scheduledDate = date);
                                    triggerHaptic(HapticType.light);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: categoryColor.opacity10,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: categoryColor.opacity30,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: categoryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Fecha programada',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(_scheduledDate),
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                color: categoryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: categoryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Esta tarea solo aparecerá en el calendario en esta fecha',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reminder Section
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_rounded,
                                size: 20,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Recordatorio',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: _hasReminder,
                                onChanged: (value) async {
                                  if (value) {
                                    final notificationService = NotificationService();
                                    final hasPerm = await notificationService.areNotificationsEnabled();
                                    
                                    if (!hasPerm) {
                                      final granted = await notificationService.requestNotificationPermission();
                                      if (!granted) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Habilita las notificaciones para usar recordatorios'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      await notificationService.setNotificationsEnabled(true);
                                    }
                                    triggerHaptic(HapticType.light);
                                  }
                                  setState(() => _hasReminder = value);
                                },
                                activeTrackColor: categoryColor.withValues(alpha: 0.5),
                                activeThumbColor: categoryColor,
                              ),
                            ],
                          ),
                          if (_hasReminder) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _reminderTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: theme.copyWith(
                                        colorScheme: colorScheme.copyWith(
                                          primary: categoryColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setState(() => _reminderTime = time);
                                  triggerHaptic(HapticType.light);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: categoryColor.opacity10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: categoryColor.opacity30,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 22,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hora del recordatorio',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _reminderTime.format(context),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: categoryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: categoryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Recibirás una notificación a esta hora los días que tengas programado este hábito.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              triggerHaptic(HapticType.medium);
                              _saveHabit();
                            },
                      icon: _isSaving 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                      label: Text(
                        _isSaving 
                            ? 'Guardando...' 
                            : (_isEditing ? 'Guardar cambios' : 'Crear hábito'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ); // Close Theme widget
  }

  String _getDaysDescription() {
    if (_selectedDays.length == 7) return 'Todos los días';
    if (_selectedDays.length == 5 &&
        _selectedDays.containsAll({1, 2, 3, 4, 5})) {
      return 'Lunes a Viernes';
    }
    if (_selectedDays.length == 2 && _selectedDays.containsAll({6, 7})) {
      return 'Fines de semana';
    }
    return '${_selectedDays.length} día${_selectedDays.length == 1 ? '' : 's'} seleccionado${_selectedDays.length == 1 ? '' : 's'}';
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final monthName = monthNames[date.month - 1];
    return '${date.day} de $monthName ${date.year}';
  }
}

/// Section card widget for consistent styling
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Category chip widget - FASE 9: Mejorado con scale y glow
class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Color catColor;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.catColor,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Siempre usar estilo OLED (fondo puro + borde del color de categoría)
    return GestureDetector(
      onTap: () {
        // Haptic feedback tipo reloj mecánico para selección de categoría
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      catColor.withValues(alpha: isDark ? 0.35 : 0.2),
                      catColor.withValues(alpha: isDark ? 0.25 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : (isDark ? Colors.black : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? catColor
                  : catColor.withValues(alpha: isDark ? 0.3 : 0.25),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppTheme.getCategoryIcon(category),
                  size: 18,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  category.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : catColor)
                        : (isDark ? Colors.white70 : colorScheme.onSurface),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

/// Frequency type button widget with smooth animations
class _FrequencyTypeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FrequencyTypeButton({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FrequencyTypeButton> createState() => _FrequencyTypeButtonState();
}

class _FrequencyTypeButtonState extends State<_FrequencyTypeButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: isDark ? 0.35 : 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                color: widget.isSelected
                    ? (isDark ? Colors.white : widget.accentColor)
                    : (isDark ? Colors.white70 : colorScheme.onSurfaceVariant),
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick action button widget with tap feedback
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final bool isDark;
  final bool isSmall;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.isDark,
    required this.onTap, this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    // Siempre usar estilo OLED (fondo puro + borde de acento)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Haptic feedback para quick actions
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? Colors.black : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? accentColor
                  : accentColor.withValues(alpha: isDark ? 0.3 : 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? accentColor
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? accentColor
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Day button widget (circular) with tap feedback
class _DayButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Siempre usar estilo OLED (fondo puro + borde de acento)
    return GestureDetector(
      onTap: () {
        // Haptic feedback tipo reloj mecánico para selección
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : (isDark ? Colors.black : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : accentColor.withValues(alpha: isDark ? 0.3 : 0.25),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
