import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/habit_provider.dart';
import '../domain/models.dart';

/// Pantalla de calendario mensual
/// Parte superior: calendario
/// Parte inferior: detalle del día seleccionado
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Mes base para el PageView (normalmente el mes actual)
  late DateTime _baseMonth;

  // Mes actualmente enfocado en el calendario (ej. diciembre 2025)
  late DateTime _focusedMonth;

  // Día actualmente seleccionado dentro del mes enfocado
  late DateTime _selectedDate;

  // Controlador para el PageView de meses
  late PageController _monthPageController;

  // Página inicial del PageView (un índice alto para permitir navegar hacia atrás/adelante)
  late int _initialPage;

  // Página actual del PageView
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _focusedMonth = _baseMonth;
    _selectedDate = DateTime(now.year, now.month, now.day);

    _initialPage = 10000;
    _currentPage = _initialPage;
    _monthPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        centerTitle: false,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          return Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Sección superior: calendario mensual
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de mes y año
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            tooltip: 'Mes anterior',
                            onPressed: _goToPreviousMonth,
                          ),
                          Text(
                            _monthYearLabel(_focusedMonth),
                            style: theme.textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            tooltip: 'Mes siguiente',
                            onPressed: _goToNextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Encabezado de días de la semana (L - D)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(child: Center(child: Text('L'))),
                          Expanded(child: Center(child: Text('M'))),
                          Expanded(child: Center(child: Text('X'))),
                          Expanded(child: Center(child: Text('J'))),
                          Expanded(child: Center(child: Text('V'))),
                          Expanded(child: Center(child: Text('S'))),
                          Expanded(child: Center(child: Text('D'))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Grid de días con PageView para navegar entre meses
                      Expanded(
                        child: PageView.builder(
                          controller: _monthPageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                              final offset = page - _initialPage;
                              _focusedMonth = DateTime(_baseMonth.year, _baseMonth.month + offset);

                              // Ajustar el día seleccionado si no existe en el nuevo mes
                              final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
                              var day = _selectedDate.day;
                              if (day > lastDayOfMonth) {
                                day = lastDayOfMonth;
                              }
                              _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                            });
                          },
                          itemBuilder: (context, page) {
                            final offset = page - _initialPage;
                            final month = DateTime(_baseMonth.year, _baseMonth.month + offset);
                            return _buildMonthPage(
                              month: month,
                              theme: theme,
                              colorScheme: colorScheme,
                              isDark: isDark,
                              habitProvider: habitProvider,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sección inferior: detalle del día seleccionado
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final habitsForDate = habitProvider.getHabitsForDate(_selectedDate);
                      final withReminder = habitsForDate
                          .where((h) => h.hasReminder && h.reminderHour != null && h.reminderMinute != null)
                          .toList()
                        ..sort((a, b) {
                          final aMinutes = (a.reminderHour! * 60) + a.reminderMinute!;
                          final bMinutes = (b.reminderHour! * 60) + b.reminderMinute!;
                          return aMinutes.compareTo(bMinutes);
                        });

                      final withoutReminder = habitsForDate
                          .where((h) => !h.hasReminder || h.reminderHour == null || h.reminderMinute == null)
                          .toList()
                        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dayLabel(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (habitsForDate.isEmpty) ...[
                            Text(
                              'No hay hábitos programados para este día',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: ListView(
                                children: [
                                  if (withReminder.isNotEmpty) ...[
                                    Text(
                                      'Con recordatorio',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...withReminder.map(
                                      (habit) => _DayHabitTile(
                                        habit: habit,
                                        isDark: isDark,
                                        colorScheme: colorScheme,
                                        isCompleted: habitProvider.isHabitCompleted(habit.id, _selectedDate),
                                        selectedDate: _selectedDate,
                                        timeLabel: _formatTime(context, habit.reminderHour!, habit.reminderMinute!),
                                        onToggle: () => habitProvider.toggleHabit(habit.id, _selectedDate),
                                      ),
                                    ),
                                  ],

                                  if (withoutReminder.isNotEmpty) ...[
                                    if (withReminder.isNotEmpty) const SizedBox(height: 16),
                                    Text(
                                      'Sin recordatorio',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...withoutReminder.map(
                                      (habit) => _DayHabitTile(
                                        habit: habit,
                                        isDark: isDark,
                                        colorScheme: colorScheme,
                                        isCompleted: habitProvider.isHabitCompleted(habit.id, _selectedDate),
                                        selectedDate: _selectedDate,
                                        onToggle: () => habitProvider.toggleHabit(habit.id, _selectedDate),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la cuadrícula de un mes específico
  Widget _buildMonthPage({
    required DateTime month,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required HabitProvider habitProvider,
  }) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // weekday en Dart: lunes=1 ... domingo=7
    final int leadingEmptyDays = firstDayOfMonth.weekday - 1; // para empezar en lunes
    final int daysInMonth = lastDayOfMonth.day;
    final int totalCells = leadingEmptyDays + daysInMonth;
    final int rows = (totalCells / 7).ceil();

    final today = _dateOnly(DateTime.now());

    int dayCounter = 1;
    final List<TableRow> rowsWidgets = [];

    for (int row = 0; row < rows; row++) {
      final List<Widget> cells = [];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;

        if (cellIndex < leadingEmptyDays || cellIndex >= leadingEmptyDays + daysInMonth) {
          // Celdas vacías (antes o después de los días reales)
          cells.add(const SizedBox.shrink());
        } else {
          final day = dayCounter++;
          final cellDate = DateTime(month.year, month.month, day);
          final habitsForDate = habitProvider.getHabitsForDate(cellDate);
          final bool hasHabits = habitsForDate.isNotEmpty;
          final bool hasReminders = habitsForDate.any((h) => h.hasReminder);
          final isSelected = _isSameDate(cellDate, _selectedDate);
          final isToday = _isSameDate(cellDate, today);

          Color bgColor = Colors.transparent;
          Color textColor = colorScheme.onSurface;
          Border? border;

          if (isSelected) {
            bgColor = colorScheme.primary;
            textColor = colorScheme.onPrimary;
          } else if (isToday) {
            border = Border.all(color: colorScheme.primary, width: 1.5);
          }

          cells.add(
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = cellDate;
                  _focusedMonth = DateTime(month.year, month.month);
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: border,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (hasHabits) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: hasReminders
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
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
      rowsWidgets.add(TableRow(children: cells));
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rowsWidgets,
    );
  }

  void _goToPreviousMonth() {
    _monthPageController.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNextMonth() {
    _monthPageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthYearLabel(DateTime date) {
    // Formato simple: "Mes Año" (luego podemos internacionalizar si hace falta)
    const monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final monthName = monthNames[date.month - 1];
    return '$monthName ${date.year}';
  }

  String _dayLabel(DateTime date) {
    // Formato simple: "29 de Diciembre 2025" (podemos mejorar luego con intl)
    const monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final monthName = monthNames[date.month - 1];
    return '${date.day} de $monthName ${date.year}';
  }

  String _formatTime(BuildContext context, int hour, int minute) {
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return timeOfDay.format(context);
  }
}

class _DayHabitTile extends StatelessWidget {
  final Habit habit;
  final bool isDark;
  final ColorScheme colorScheme;
  final String? timeLabel;
  final bool isCompleted;
  final DateTime selectedDate;
  final VoidCallback? onToggle;

  const _DayHabitTile({
    required this.habit,
    required this.isDark,
    required this.colorScheme,
    required this.isCompleted,
    required this.selectedDate,
    this.timeLabel,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('${habit.id}_${selectedDate.toIso8601String()}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // Swipe derecha (startToEnd): completar solo si NO está completado
        // Swipe izquierda (endToStart): descompletar solo si YA está completado
        if (direction == DismissDirection.startToEnd && !isCompleted) {
          onToggle?.call();
        } else if (direction == DismissDirection.endToStart && isCompleted) {
          onToggle?.call();
        }
        return false; // Don't actually dismiss
      },
      // Swipe derecha: Completar (verde)
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              Icons.check_rounded,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Completar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // Swipe izquierda: Desmarcar (naranja)
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Desmarcar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.undo_rounded,
              color: Colors.orange,
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.08))
              : (isDark ? Colors.black : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withValues(alpha: isDark ? 0.4 : 0.3)
                : colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Check icon for completed habits
            if (isCompleted) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
            ],
            if (timeLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCompleted ? Colors.green : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                habit.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isCompleted
                      ? colorScheme.onSurface.withValues(alpha: 0.6)
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
