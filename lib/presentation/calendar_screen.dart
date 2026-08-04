import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../application/note_controller.dart';
import '../application/note_state.dart';
import '../application/profile_controller.dart';
import '../application/session_controller.dart';
import '../domain/models.dart';
import '../domain/note_models.dart';
import '../domain/progress_engine.dart';
import '../domain/user_profile.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'note_surface.dart';
import 'pomodoro_history_screen.dart';
import 'theme.dart';
import 'utils/page_transitions.dart';
import 'widgets/responsive_layout.dart';

/// Operational monthly agenda with durable progress context.
class CalendarScreen extends riverpod.ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  riverpod.ConsumerState<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState extends riverpod.ConsumerState<CalendarScreen> {
  late final DateTime _baseMonth;
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late final PageController _monthPageController;
  late final int _initialPage;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final now = _dateOnly(DateTime.now());
    _baseMonth = DateTime(now.year, now.month);
    _focusedMonth = _baseMonth;
    _selectedDate = now;
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
    final ownerId = ref.watch(activeOwnerIdProvider);
    final habitState = ownerId == null
        ? null
        : ref.watch(habitControllerProvider(ownerId)).valueOrNull;
    final noteState = ownerId == null
        ? null
        : ref.watch(noteControllerProvider(ownerId)).valueOrNull;
    final profile = ownerId == null
        ? null
        : ref.watch(profileControllerProvider(ownerId)).valueOrNull?.profile;
    final selectedHabits = _habitsForCalendarDate(
      habitState,
      _selectedDate,
    );
    final selectedNotes = _notesForDate(noteState, _selectedDate);
    final selectedFocus = _focusSessions(profile, _selectedDate);
    final selectedAccent = _accentForDay(
      context,
      habits: selectedHabits,
      notes: selectedNotes,
      focusSessions: selectedFocus,
    );

    return Scaffold(
      appBar: AppBar(
        title: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: const Text('Calendario'),
        ),
        actions: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: TextButton(
              onPressed: _goToToday,
              child: const Text('Hoy'),
            ),
          ),
          SizedBox(width: context.spacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _CalendarAmbientLayer(
          accent: selectedAccent,
          seed: _selectedDate.day + (_selectedDate.month * 31),
          child: ResponsiveLayoutBuilder(
            builder: (context, layout) {
              final usesTwoPane = layout.width >= 760;
              final calendar = _buildCalendarPanel(
                context,
                habitState: habitState,
                noteState: noteState,
                profile: profile,
              );
              final detail = _DayDetailPanel(
                key: const ValueKey('calendar-day-panel'),
                selectedDate: _selectedDate,
                habits: selectedHabits,
                notes: selectedNotes,
                durableHabitCompletions:
                    _habitCompletions(profile, _selectedDate),
                focusSessions: selectedFocus,
                habitState: habitState,
                accent: selectedAccent,
                onToggleHabit: ownerId == null
                    ? null
                    : (habitId, date) => ref
                        .read(habitControllerProvider(ownerId).notifier)
                        .toggleHabit(habitId, date),
                onOpenNote: _openNote,
                onOpenFocusHistory: () {
                  Navigator.of(context).push(
                    PageTransitions.slideFromRight(
                      const PomodoroHistoryScreen(),
                    ),
                  );
                },
              );

              return SingleChildScrollView(
                key: const ValueKey('calendar-scroll'),
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalPagePadding,
                  layout.isShort
                      ? context.spacing.xs
                      : layout.verticalPagePadding,
                  layout.horizontalPagePadding,
                  context.spacing.xxl,
                ),
                child: ResponsiveContentFrame(
                  maxWidth: 1180,
                  child: usesTwoPane
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: calendar),
                            SizedBox(width: context.spacing.xl),
                            Expanded(flex: 6, child: detail),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calendar,
                            SizedBox(height: context.spacing.md),
                            detail,
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarPanel(
    BuildContext context, {
    required HabitState? habitState,
    required NoteState? noteState,
    required UserProfile? profile,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;

    return _ChromaticSurface(
      key: const ValueKey('calendar-month-panel'),
      accent: palette.water,
      secondaryAccent: palette.sleep,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Mes anterior',
                  color: palette.sleep,
                  onPressed: _goToPreviousMonth,
                ),
                Expanded(
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 2,
                    child: Text(
                      _monthYearLabel(_focusedMonth),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Mes siguiente',
                  color: palette.water,
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            SizedBox(height: context.spacing.xs),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.4,
              child: Row(
                children: [
                  for (final day in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                    Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.xxs),
            SizedBox(
              height: largeText ? 396 : 270,
              child: PageView.builder(
                controller: _monthPageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onMonthPageChanged,
                itemBuilder: (context, page) {
                  final month = DateTime(
                    _baseMonth.year,
                    _baseMonth.month + page - _initialPage,
                  );
                  return _buildMonthPage(
                    context,
                    month: month,
                    habitState: habitState,
                    noteState: noteState,
                    profile: profile,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPage(
    BuildContext context, {
    required DateTime month,
    required HabitState? habitState,
    required NoteState? noteState,
    required UserProfile? profile,
  }) {
    final firstDay = DateTime(month.year, month.month);
    final leadingEmptyDays = firstDay.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = _dateOnly(DateTime.now());
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (var row = 0; row < 6; row++)
            TableRow(
              children: [
                for (var column = 0; column < 7; column++)
                  Builder(
                    builder: (context) {
                      final day = row * 7 + column - leadingEmptyDays + 1;
                      if (day < 1 || day > daysInMonth) {
                        return SizedBox(height: largeText ? 65 : 44);
                      }

                      final date = DateTime(month.year, month.month, day);
                      final planned =
                          _habitsForCalendarDate(habitState, date).length;
                      final notes = _notesForDate(noteState, date).length;
                      final completions = _habitCompletions(profile, date);
                      final focusSessions = _focusSessions(profile, date);
                      return _CalendarDayCell(
                        date: date,
                        height: largeText ? 65 : 44,
                        isToday: _isSameDate(date, today),
                        isSelected: _isSameDate(date, _selectedDate),
                        plannedHabits: planned,
                        notes: notes,
                        habitCompletions: completions,
                        focusSessions: focusSessions,
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _focusedMonth = DateTime(month.year, month.month);
                          });
                        },
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _onMonthPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _focusedMonth = DateTime(
        _baseMonth.year,
        _baseMonth.month + page - _initialPage,
      );
      final lastDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        0,
      ).day;
      _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        math.min(_selectedDate.day, lastDay),
      );
    });
  }

  void _goToPreviousMonth() {
    _monthPageController.animateToPage(
      _currentPage - 1,
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 320),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNextMonth() {
    _monthPageController.animateToPage(
      _currentPage + 1,
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 320),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToToday() {
    final today = _dateOnly(DateTime.now());
    setState(() {
      _selectedDate = today;
      _focusedMonth = _baseMonth;
    });
    _monthPageController.animateToPage(
      _initialPage,
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 360),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  List<_CalendarNoteEntry> _notesForDate(
    NoteState? state,
    DateTime date,
  ) {
    if (state == null) return const [];
    final entries = <_CalendarNoteEntry>[];
    for (final reminder in state.reminders) {
      if (reminder.status != NoteReminderStatus.scheduled) continue;
      final scheduled = reminder.scheduledAtUtc.toLocal();
      if (!_isSameDate(scheduled, date)) continue;
      final note = state.getNote(reminder.noteId);
      if (note == null || note.isArchived) continue;
      entries.add(_CalendarNoteEntry(note: note, reminder: reminder));
    }
    entries.sort(
      (left, right) =>
          left.reminder.scheduledAtUtc.compareTo(right.reminder.scheduledAtUtc),
    );
    return entries;
  }

  List<Habit> _habitsForCalendarDate(
    HabitState? state,
    DateTime date,
  ) {
    if (state == null) return const [];
    final target = _dateOnly(date);
    return state
        .getHabitsForDate(target)
        .where((habit) => !_dateOnly(habit.createdAt).isAfter(target))
        .toList(growable: false);
  }

  Color _accentForDay(
    BuildContext context, {
    required List<Habit> habits,
    required List<_CalendarNoteEntry> notes,
    required int focusSessions,
  }) {
    if (notes.isNotEmpty) return context.zentraPalette.sleep;
    if (focusSessions > 0) return context.zentraPalette.warmPeach;
    if (habits.isNotEmpty) {
      return AppTheme.getCategoryColor(
        habits.first.category,
        Theme.of(context).colorScheme,
      );
    }
    return context.zentraPalette.water;
  }

  Future<void> _openNote(Note note) async {
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        NoteSurface(noteId: note.id),
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static int _habitCompletions(UserProfile? profile, DateTime date) =>
      profile?.dailyHabitCompletions[ProgressEngine.dayKey(date)] ?? 0;

  static int _focusSessions(UserProfile? profile, DateTime date) =>
      profile?.dailyFocusSessions[ProgressEngine.dayKey(date)] ?? 0;

  static String _monthYearLabel(DateTime date) =>
      _capitalize('${_spanishMonths[date.month - 1]} ${date.year}');
}

class _CalendarAmbientLayer extends StatelessWidget {
  final Color accent;
  final int seed;
  final Widget child;

  const _CalendarAmbientLayer({
    required this.accent,
    required this.seed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.zentraPalette;
    const alignments = [
      (Alignment(-1, -0.9), Alignment(0.9, 1)),
      (Alignment(-0.8, 1), Alignment(1, -0.7)),
      (Alignment(0.8, -1), Alignment(-1, 0.8)),
    ];
    final alignment = alignments[seed % alignments.length];

    return AnimatedContainer(
      key: const ValueKey('calendar-ambient-layer'),
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 900),
      ),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment.$1,
          end: alignment.$2,
          colors: [
            accent.withValues(alpha: dark ? 0.09 : 0.045),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0),
            palette.sleep.withValues(alpha: dark ? 0.065 : 0.025),
          ],
          stops: const [0, 0.52, 1],
        ),
      ),
      child: child,
    );
  }
}

class _ChromaticSurface extends StatelessWidget {
  final Color accent;
  final Color? secondaryAccent;
  final Widget child;

  const _ChromaticSurface({
    required this.accent,
    required this.child,
    this.secondaryAccent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.zentraPalette;
    final radius = context.radii.large;
    final secondary = secondaryAccent ?? accent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: dark ? 0.72 : 0.32),
            secondary.withValues(alpha: dark ? 0.46 : 0.2),
            Theme.of(context).colorScheme.outlineVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: dark
            ? AppTheme.oledGlow(accent, intensity: 0.18)
            : const <BoxShadow>[],
      ),
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              palette.functionalSurface.withValues(alpha: dark ? 0.96 : 0.98),
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: child,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final double height;
  final bool isToday;
  final bool isSelected;
  final int plannedHabits;
  final int notes;
  final int habitCompletions;
  final int focusSessions;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.height,
    required this.isToday,
    required this.isSelected,
    required this.plannedHabits,
    required this.notes,
    required this.habitCompletions,
    required this.focusSessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final markers = <({Color color, bool outlined})>[
      if (habitCompletions > 0) (color: palette.brandTeal, outlined: false),
      if (focusSessions > 0) (color: palette.warmPeach, outlined: false),
      if (notes > 0) (color: palette.sleep, outlined: false),
      if (plannedHabits > habitCompletions)
        (color: scheme.outline, outlined: true),
    ];
    final details = <String>[
      if (plannedHabits > 0) '$plannedHabits hábitos planeados',
      if (habitCompletions > 0) '$habitCompletions avances',
      if (focusSessions > 0) '$focusSessions sesiones de enfoque',
      if (notes > 0) '$notes notas',
    ];
    final duration = context.motionPolicy.duration(
      const Duration(milliseconds: 260),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        _formatSpanishDate(date),
        if (isToday) 'hoy',
        if (details.isEmpty) 'sin actividad',
        ...details,
      ].join(', '),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedScale(
          duration: duration,
          curve: Curves.easeOutBack,
          scale: isSelected ? 1 : 0.94,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [palette.brandTeal, palette.water],
                    )
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: isToday && !isSelected
                  ? Border.all(color: palette.water, width: 1.5)
                  : null,
              boxShadow: isSelected && dark
                  ? AppTheme.oledGlow(palette.brandTeal, intensity: 0.3)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey(
                  'calendar-day-${ProgressEngine.dayKey(date)}',
                ),
                onTap: onTap,
                child: SizedBox(
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? const Color(0xFFFFFFFF)
                                  : scheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var index = 0;
                                index < math.min(markers.length, 4);
                                index++) ...[
                              if (index > 0) const SizedBox(width: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: markers[index].outlined
                                      ? Colors.transparent
                                      : markers[index].color,
                                  border: Border.all(
                                    color: markers[index].outlined
                                        ? isSelected
                                            ? Colors.white
                                            : markers[index].color
                                        : isSelected
                                            ? Colors.white70
                                            : Colors.transparent,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDetailPanel extends StatelessWidget {
  final DateTime selectedDate;
  final List<Habit> habits;
  final List<_CalendarNoteEntry> notes;
  final int durableHabitCompletions;
  final int focusSessions;
  final HabitState? habitState;
  final Color accent;
  final Future<void> Function(String habitId, DateTime date)? onToggleHabit;
  final ValueChanged<Note> onOpenNote;
  final VoidCallback onOpenFocusHistory;

  const _DayDetailPanel({
    required this.selectedDate,
    required this.habits,
    required this.notes,
    required this.durableHabitCompletions,
    required this.focusSessions,
    required this.habitState,
    required this.accent,
    required this.onToggleHabit,
    required this.onOpenNote,
    required this.onOpenFocusHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _ChromaticSurface(
      accent: accent,
      secondaryAccent: context.zentraPalette.warmPeach,
      child: AnimatedSwitcher(
        duration: context.motionPolicy.duration(
          const Duration(milliseconds: 280),
        ),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _DayDetailContent(
          key: ValueKey(ProgressEngine.dayKey(selectedDate)),
          selectedDate: selectedDate,
          habits: habits,
          notes: notes,
          durableHabitCompletions: durableHabitCompletions,
          focusSessions: focusSessions,
          habitState: habitState,
          onToggleHabit: onToggleHabit,
          onOpenNote: onOpenNote,
          onOpenFocusHistory: onOpenFocusHistory,
        ),
      ),
    );
  }
}

class _DayDetailContent extends StatelessWidget {
  final DateTime selectedDate;
  final List<Habit> habits;
  final List<_CalendarNoteEntry> notes;
  final int durableHabitCompletions;
  final int focusSessions;
  final HabitState? habitState;
  final Future<void> Function(String habitId, DateTime date)? onToggleHabit;
  final ValueChanged<Note> onOpenNote;
  final VoidCallback onOpenFocusHistory;

  const _DayDetailContent({
    required this.selectedDate,
    required this.habits,
    required this.notes,
    required this.durableHabitCompletions,
    required this.focusSessions,
    required this.habitState,
    required this.onToggleHabit,
    required this.onOpenNote,
    required this.onOpenFocusHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedHabits = [...habits]..sort((left, right) {
        final leftMinutes = _reminderMinutes(left);
        final rightMinutes = _reminderMinutes(right);
        final timeComparison = leftMinutes.compareTo(rightMinutes);
        if (timeComparison != 0) return timeComparison;
        return left.title.toLowerCase().compareTo(right.title.toLowerCase());
      });
    final liveCompletions = habits
        .where(
          (habit) =>
              habitState?.isHabitCompleted(habit.id, selectedDate) ?? false,
        )
        .length;
    final preservedCompletions =
        math.max(0, durableHabitCompletions - liveCompletions);
    final hasAnyContent = habits.isNotEmpty ||
        notes.isNotEmpty ||
        durableHabitCompletions > 0 ||
        focusSessions > 0;

    return Padding(
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(
            date: selectedDate,
            habitCompletions: durableHabitCompletions,
            focusSessions: focusSessions,
            notes: notes.length,
          ),
          SizedBox(height: context.spacing.lg),
          if (!hasAnyContent)
            const _CalendarEmptyDay()
          else ...[
            if (preservedCompletions > 0) ...[
              _PreservedActivityCard(count: preservedCompletions),
              SizedBox(height: context.spacing.md),
            ],
            if (focusSessions > 0) ...[
              _FocusDayCard(
                sessions: focusSessions,
                onTap: onOpenFocusHistory,
              ),
              SizedBox(height: context.spacing.md),
            ],
            if (notes.isNotEmpty) ...[
              const _SectionLabel(label: 'Notas'),
              SizedBox(height: context.spacing.xs),
              for (final entry in notes) ...[
                _DayNoteTile(
                  entry: entry,
                  onTap: () => onOpenNote(entry.note),
                ),
                SizedBox(height: context.spacing.xs),
              ],
              SizedBox(height: context.spacing.md),
            ],
            if (sortedHabits.isNotEmpty) ...[
              const _SectionLabel(label: 'Hábitos'),
              SizedBox(height: context.spacing.xs),
              for (final habit in sortedHabits) ...[
                _DayHabitTile(
                  habit: habit,
                  isCompleted:
                      habitState?.isHabitCompleted(habit.id, selectedDate) ??
                          false,
                  onToggle: onToggleHabit == null
                      ? null
                      : () => onToggleHabit!(habit.id, selectedDate),
                ),
                SizedBox(height: context.spacing.xs),
              ],
            ],
          ],
        ],
      ),
    );
  }

  static int _reminderMinutes(Habit habit) {
    if (!habit.hasReminder ||
        habit.reminderHour == null ||
        habit.reminderMinute == null) {
      return 24 * 60;
    }
    return habit.reminderHour! * 60 + habit.reminderMinute!;
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final int habitCompletions;
  final int focusSessions;
  final int notes;

  const _DayHeader({
    required this.date,
    required this.habitCompletions,
    required this.focusSessions,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;

    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_spanishWeekdays[date.weekday - 1]} ${date.day}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              Text(
                '${_spanishMonths[date.month - 1]} · ${date.year}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (habitCompletions > 0 || focusSessions > 0 || notes > 0)
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xs,
            children: [
              if (habitCompletions > 0)
                _ActivityCount(
                  icon: Icons.check_circle_outline_rounded,
                  count: habitCompletions,
                  semanticsLabel:
                      '$habitCompletions ${habitCompletions == 1 ? 'avance' : 'avances'}',
                  color: palette.brandTeal,
                ),
              if (focusSessions > 0)
                _ActivityCount(
                  icon: Icons.timer_outlined,
                  count: focusSessions,
                  semanticsLabel:
                      '$focusSessions ${focusSessions == 1 ? 'enfoque' : 'enfoques'}',
                  color: palette.warmPeach,
                ),
              if (notes > 0)
                _ActivityCount(
                  icon: Icons.note_alt_outlined,
                  count: notes,
                  semanticsLabel: '$notes ${notes == 1 ? 'nota' : 'notas'}',
                  color: palette.sleep,
                ),
            ],
          ),
      ],
    );
  }
}

class _ActivityCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final String semanticsLabel;
  final Color color;

  const _ActivityCount({
    required this.icon,
    required this.count,
    required this.semanticsLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: context.spacing.xxs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CalendarEmptyDay extends StatelessWidget {
  const _CalendarEmptyDay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sin actividad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            'No hay nada guardado para este día.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PreservedActivityCard extends StatelessWidget {
  final int count;

  const _PreservedActivityCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final color = context.zentraPalette.brandTeal;
    return Container(
      key: const ValueKey('calendar-preserved-activity'),
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.09 : 0.06,
        ),
        borderRadius: BorderRadius.circular(context.radii.medium),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: color),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'avance guardado' : 'avances guardados'} '
              'de ${count == 1 ? 'un hábito eliminado' : 'hábitos eliminados'}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusDayCard extends StatelessWidget {
  final int sessions;
  final VoidCallback onTap;

  const _FocusDayCard({
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.zentraPalette.warmPeach;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          '$sessions ${sessions == 1 ? 'sesión de enfoque' : 'sesiones de enfoque'}. Abrir historial.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: dark ? 0.18 : 0.1),
                color.withValues(alpha: dark ? 0.045 : 0.025),
              ],
            ),
            borderRadius: BorderRadius.circular(context.radii.medium),
            border: Border.all(color: color.withValues(alpha: 0.36)),
            boxShadow:
                dark ? AppTheme.oledGlow(color, intensity: 0.1) : const [],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.radii.medium),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.6,
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: color),
                    SizedBox(width: context.spacing.sm),
                    Expanded(
                      child: Text(
                        'Enfoque',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarNoteEntry {
  final Note note;
  final NoteReminder reminder;

  const _CalendarNoteEntry({
    required this.note,
    required this.reminder,
  });
}

class _DayNoteTile extends StatelessWidget {
  final _CalendarNoteEntry entry;
  final VoidCallback onTap;

  const _DayNoteTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.zentraPalette.sleep;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheduled = entry.reminder.scheduledAtUtc.toLocal();
    final time = TimeOfDay.fromDateTime(scheduled).format(context);

    return Semantics(
      button: true,
      label: '${entry.note.title}, $time',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: dark ? 0.18 : 0.09),
                color.withValues(alpha: dark ? 0.035 : 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(context.radii.medium),
            border: Border.all(color: color.withValues(alpha: 0.32)),
            boxShadow:
                dark ? AppTheme.oledGlow(color, intensity: 0.09) : const [],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.radii.medium),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: Row(
                children: [
                  Icon(Icons.note_alt_outlined, color: color),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          time,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHabitTile extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback? onToggle;

  const _DayHabitTile({
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.getCategoryColor(habit.category, scheme);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final time = habit.hasReminder &&
            habit.reminderHour != null &&
            habit.reminderMinute != null
        ? TimeOfDay(
            hour: habit.reminderHour!,
            minute: habit.reminderMinute!,
          ).format(context)
        : null;

    return Semantics(
      button: true,
      checked: isCompleted,
      label: [
        habit.title,
        habit.category.label,
        if (time != null) time,
        isCompleted ? 'completado' : 'pendiente',
      ].join(', '),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(
                  alpha: dark
                      ? isCompleted
                          ? 0.2
                          : 0.1
                      : isCompleted
                          ? 0.12
                          : 0.055,
                ),
                color.withValues(alpha: dark ? 0.025 : 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(context.radii.medium),
            border: Border.all(
              color: color.withValues(alpha: isCompleted ? 0.5 : 0.25),
            ),
            boxShadow: dark && isCompleted
                ? AppTheme.oledGlow(color, intensity: 0.1)
                : const [],
          ),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(context.radii.medium),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: context.spacing.sm,
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 2,
                child: Row(
                  children: [
                    Tooltip(
                      message: habit.category.label,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: dark ? 0.2 : 0.12),
                          borderRadius:
                              BorderRadius.circular(context.radii.small),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(habit.category),
                          color: color,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurface,
                                ),
                          ),
                          if (time != null)
                            Text(
                              time,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.spacing.xs),
                    AnimatedSwitcher(
                      duration: context.motionPolicy.duration(
                        const Duration(milliseconds: 220),
                      ),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                          child: child,
                        );
                      },
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        key: ValueKey(isCompleted),
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _spanishMonths = [
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

const _spanishWeekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _formatSpanishDate(DateTime date) =>
    '${date.day} de ${_spanishMonths[date.month - 1]} ${date.year}';

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
