import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/pomodoro_provider.dart';
import '../application/session_controller.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'pomodoro_history_screen.dart';
import 'utils/feedback_utils.dart';
import 'widgets/ambient_background.dart';
import 'widgets/responsive_layout.dart';

/// The focused work surface for Zentra's Calma precisa design language.
///
/// A focus session can stay anonymous, carry a lightweight title, or arrive
/// linked to a note. The timer never requires either piece of context.
class PomodoroScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String? linkedNoteId;

  const PomodoroScreen({
    this.initialTitle,
    this.linkedNoteId,
    super.key,
  });

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  final GlobalKey<_FocusLauncherState> _launcherKey =
      GlobalKey<_FocusLauncherState>();
  bool _completionIsVisible = false;

  void _showCompletionIfNeeded(
    PomodoroViewState provider,
    PomodoroController controller,
  ) {
    final completed = provider.justCompletedActivity;
    if (completed == null || !mounted || _completionIsVisible) return;

    _completionIsVisible = true;
    controller.clearJustCompletedActivity();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _FocusCompletionDialog(
          title: completed.name,
          focuses: completed.cyclesCompleted,
          minutes: completed.totalMinutes,
        ),
      );
      _completionIsVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    if (ownerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pomodoroProvider = pomodoroControllerProvider(ownerId);
    final controller = ref.read(pomodoroProvider.notifier);
    ref.listen<PomodoroViewState>(
      pomodoroProvider,
      (_, next) => _showCompletionIfNeeded(next, controller),
    );
    final provider = ref.watch(pomodoroProvider);

    return Scaffold(
      bottomNavigationBar:
          context.zentraWindowClass == ZentraWindowClass.compact &&
                  provider.canShowLauncher
              ? _CompactFocusStartBar(
                  provider: provider,
                  onStart: () => _launcherKey.currentState?._start(),
                )
              : const SizedBox.shrink(),
      body: ZentraAmbientBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            builder: (context, layout) {
              final content = provider.canShowLauncher
                  ? _FocusLauncher(
                      key: _launcherKey,
                      provider: provider,
                      controller: controller,
                      initialTitle: widget.initialTitle,
                      linkedNoteId: widget.linkedNoteId,
                      expanded: layout.isExpanded,
                    )
                  : _FocusSession(
                      provider: provider,
                      controller: controller,
                      expanded: layout.isExpanded,
                    );

              return CustomScrollView(
                key: const ValueKey('focus_screen_scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPagePadding,
                      layout.verticalPagePadding,
                      layout.horizontalPagePadding,
                      context.spacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ResponsiveContentFrame(
                        maxWidth: 1120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FocusHeader(
                              showConfiguration: provider.canShowLauncher,
                              provider: provider,
                              controller: controller,
                            ),
                            SizedBox(height: context.spacing.lg),
                            content,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FocusHeader extends StatelessWidget {
  final bool showConfiguration;
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _FocusHeader({
    required this.showConfiguration,
    required this.provider,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[
          IconButton.outlined(
            tooltip: provider.canShowLauncher
                ? 'Volver'
                : 'Volver; el temporizador continuará',
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          SizedBox(width: context.spacing.sm),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enfoque',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        SizedBox(width: context.spacing.sm),
        _HeaderAction(
          icon: Icons.history_rounded,
          label: 'Historial',
          onPressed: () {
            triggerHaptic(HapticType.light);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PomodoroHistoryScreen(),
              ),
            );
          },
        ),
        if (showConfiguration) ...[
          SizedBox(width: context.spacing.xs),
          _HeaderAction(
            icon: Icons.tune_rounded,
            label: 'Configurar tiempos',
            onPressed: () => _showFocusSettings(
              context,
              provider,
              controller,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _FocusLauncher extends StatefulWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final String? initialTitle;
  final String? linkedNoteId;
  final bool expanded;

  const _FocusLauncher({
    required this.provider,
    required this.controller,
    required this.initialTitle,
    required this.linkedNoteId,
    required this.expanded,
    super.key,
  });

  @override
  State<_FocusLauncher> createState() => _FocusLauncherState();
}

class _FocusLauncherState extends State<_FocusLauncher> {
  static const _presets = [15, 25, 45];

  late final TextEditingController _titleController;
  late bool _contextExpanded;
  String? _linkedNoteId;
  String? _linkedNoteTitle;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.initialTitle?.trim();
    _titleController = TextEditingController(
      text: widget.linkedNoteId == null ? initialTitle : null,
    );
    _linkedNoteId = widget.linkedNoteId;
    _linkedNoteTitle =
        widget.linkedNoteId == null || initialTitle?.isEmpty == true
            ? null
            : initialTitle;
    _contextExpanded =
        (initialTitle?.isNotEmpty ?? false) || widget.linkedNoteId != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    FocusManager.instance.primaryFocus?.unfocus();
    triggerHaptic(HapticType.medium);

    final title = _titleController.text.trim();
    if (widget.provider.isCycleMode) {
      await widget.controller.startCycleActivity(
        title,
        noteId: _linkedNoteId,
      );
    } else {
      await widget.controller.startQuickSession(
        name: title,
        noteId: _linkedNoteId,
      );
    }

    if (mounted) setState(() => _isStarting = false);
  }

  Future<void> _openDurationDial() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _DurationDialSheet(
        initialMinutes: widget.provider.workDuration,
      ),
    );
    if (result != null) {
      await widget.controller.setWorkDuration(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInlineStart =
        context.zentraWindowClass != ZentraWindowClass.compact;
    final intro = _LauncherIntro(
      provider: widget.provider,
      controller: widget.controller,
    );
    final configurator = _FocusConfigurator(
      provider: widget.provider,
      controller: widget.controller,
      titleController: _titleController,
      contextExpanded: _contextExpanded,
      linkedNoteId: _linkedNoteId,
      linkedNoteTitle: _linkedNoteTitle,
      isStarting: _isStarting,
      presets: _presets,
      onToggleContext: () {
        setState(() => _contextExpanded = !_contextExpanded);
      },
      onRemoveLink: () {
        setState(() {
          _linkedNoteId = null;
          _linkedNoteTitle = null;
        });
      },
      onOpenDial: _openDurationDial,
      onStart: _start,
      showStartButton: showInlineStart,
    );

    if (widget.expanded) {
      return Row(
        key: const ValueKey('pomodoro_launcher'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: intro),
          SizedBox(width: context.spacing.xl),
          Expanded(flex: 6, child: configurator),
        ],
      );
    }

    return Column(
      key: const ValueKey('pomodoro_launcher'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        intro,
        SizedBox(height: context.spacing.lg),
        configurator,
      ],
    );
  }
}

class _LauncherIntro extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _LauncherIntro({
    required this.provider,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige tu ritmo',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: context.spacing.lg),
        _ModeSelector(provider: provider, controller: controller),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _ModeSelector({
    required this.provider,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 340 || textScale >= 1.45;
        final quick = _ModeOption(
          key: const ValueKey('pomodoro_mode_quick'),
          title: 'Rápido',
          description: 'Una sesión',
          icon: Icons.center_focus_strong_rounded,
          selected: provider.isQuickMode,
          onTap: () => controller.selectMode(PomodoroMode.quick),
        );
        final cycle = _ModeOption(
          key: const ValueKey('pomodoro_mode_cycle'),
          title: 'Ciclo',
          description: '4 enfoques',
          icon: Icons.sync_rounded,
          selected: provider.isCycleMode,
          onTap: () => controller.selectMode(PomodoroMode.cycle),
        );

        if (stack) {
          return Column(
            children: [
              quick,
              SizedBox(height: context.spacing.sm),
              cycle,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: quick),
            SizedBox(width: context.spacing.sm),
            Expanded(child: cycle),
          ],
        );
      },
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = context.zentraPalette.focus;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $description',
      child: Material(
        color: selected
            ? focus.withValues(alpha: 0.12)
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.medium),
          side: BorderSide(
            color: selected ? focus : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radii.medium),
          onTap: () {
            triggerHaptic(HapticType.selection);
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? focus : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(context.radii.small),
                  ),
                  child: Icon(
                    icon,
                    color:
                        selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
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

class _FocusConfigurator extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final TextEditingController titleController;
  final bool contextExpanded;
  final String? linkedNoteId;
  final String? linkedNoteTitle;
  final bool isStarting;
  final List<int> presets;
  final VoidCallback onToggleContext;
  final VoidCallback onRemoveLink;
  final VoidCallback onOpenDial;
  final VoidCallback onStart;
  final bool showStartButton;

  const _FocusConfigurator({
    required this.provider,
    required this.controller,
    required this.titleController,
    required this.contextExpanded,
    required this.linkedNoteId,
    required this.linkedNoteTitle,
    required this.isStarting,
    required this.presets,
    required this.onToggleContext,
    required this.onRemoveLink,
    required this.onOpenDial,
    required this.onStart,
    required this.showStartButton,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focusMinutes = provider.workDuration;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 2;
    final startLabel = provider.isCycleMode
        ? (largeText ? 'Iniciar ciclo' : 'Iniciar ciclo de 4 sesiones')
        : (largeText
            ? 'Iniciar enfoque'
            : 'Iniciar $focusMinutes min de enfoque');
    final startButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.md,
      ),
    );

    return Container(
      padding: EdgeInsets.all(
        compact ? context.spacing.md : context.spacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.zentraPalette.functionalSurface,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InlineDurationDial(
            minutes: focusMinutes,
            onChanged: controller.setWorkDuration,
            onOpenFineTune: onOpenDial,
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  key: ValueKey('pomodoro_duration_$preset'),
                  label: Text('$preset min'),
                  selected: focusMinutes == preset,
                  onSelected: (_) => controller.setWorkDuration(preset),
                ),
              ActionChip(
                key: const ValueKey('pomodoro_custom_duration_button'),
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  presets.contains(focusMinutes) ? 'Otro' : '$focusMinutes min',
                ),
                onPressed: onOpenDial,
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          _OptionalContext(
            expanded: contextExpanded,
            titleController: titleController,
            linkedNoteId: linkedNoteId,
            linkedNoteTitle: linkedNoteTitle,
            onToggle: onToggleContext,
            onRemoveLink: onRemoveLink,
          ),
          SizedBox(height: context.spacing.md),
          if (provider.isCycleMode)
            _CycleSummary(provider: provider)
          else
            const SizedBox.shrink(),
          if (showStartButton) ...[
            SizedBox(height: context.spacing.md),
            if (largeText)
              FilledButton(
                key: const ValueKey('pomodoro_start_button'),
                onPressed: isStarting ? null : onStart,
                style: startButtonStyle,
                child: isStarting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(startLabel, textAlign: TextAlign.center),
              )
            else
              FilledButton.icon(
                key: const ValueKey('pomodoro_start_button'),
                onPressed: isStarting ? null : onStart,
                icon: isStarting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(startLabel, textAlign: TextAlign.center),
                style: startButtonStyle,
              ),
          ],
        ],
      ),
    );
  }
}

class _CompactFocusStartBar extends StatelessWidget {
  final PomodoroViewState provider;
  final VoidCallback onStart;

  const _CompactFocusStartBar({
    required this.provider,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final label = provider.isCycleMode
        ? (largeText ? 'Iniciar ciclo' : 'Iniciar ciclo de 4 sesiones')
        : (largeText
            ? 'Iniciar enfoque'
            : 'Iniciar ${provider.workDuration} min de enfoque');

    return Material(
      color: scheme.surface,
      elevation: 10,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(
          context.spacing.md,
          context.spacing.sm,
          context.spacing.md,
          context.spacing.sm,
        ),
        child: FilledButton.icon(
          key: const ValueKey('pomodoro_start_button'),
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(label, textAlign: TextAlign.center),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.md,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineDurationDial extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  final VoidCallback onOpenFineTune;

  const _InlineDurationDial({
    required this.minutes,
    required this.onChanged,
    required this.onOpenFineTune,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = context.zentraPalette.focus;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 300 || textScale >= 1.4;
        final dial = Semantics(
          key: const ValueKey('pomodoro_inline_duration_dial'),
          slider: true,
          label: 'Tiempo de enfoque',
          value: '$minutes minutos',
          increasedValue: '${math.min(60, minutes + 1)} minutos',
          decreasedValue: '${math.max(5, minutes - 1)} minutos',
          onIncrease: minutes < 60 ? () => onChanged(minutes + 1) : null,
          onDecrease: minutes > 5 ? () => onChanged(minutes - 1) : null,
          button: true,
          onTap: onOpenFineTune,
          child: InkWell(
            borderRadius: BorderRadius.circular(context.radii.pill),
            onTap: onOpenFineTune,
            child: CustomPaint(
              painter: _DialPainter(
                progress: minutes / 60,
                color: focus,
                background: scheme.surfaceContainerHighest,
              ),
              child: SizedBox.square(
                dimension: stack ? 174 : 184,
                child: Center(
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.35,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$minutes',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                              ),
                        ),
                        Text(
                          'minutos',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
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
        return Center(
          child: Tooltip(
            message: 'Toca para ajustar entre 5 y 60 minutos',
            child: dial,
          ),
        );
      },
    );
  }
}

class _OptionalContext extends StatelessWidget {
  final bool expanded;
  final TextEditingController titleController;
  final String? linkedNoteId;
  final String? linkedNoteTitle;
  final VoidCallback onToggle;
  final VoidCallback onRemoveLink;

  const _OptionalContext({
    required this.expanded,
    required this.titleController,
    required this.linkedNoteId,
    required this.linkedNoteTitle,
    required this.onToggle,
    required this.onRemoveLink,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = context.motionPolicy;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.medium),
      ),
      child: Column(
        children: [
          InkWell(
            key: const ValueKey('pomodoro_optional_context'),
            borderRadius: BorderRadius.circular(context.radii.medium),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: Row(
                children: [
                  Icon(
                    linkedNoteId == null
                        ? Icons.add_circle_outline_rounded
                        : Icons.description_outlined,
                    color: context.zentraPalette.focus,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          linkedNoteId == null
                              ? 'Nombre o nota'
                              : 'Nota vinculada',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          linkedNoteId == null
                              ? 'Opcional'
                              : (linkedNoteTitle ?? 'Nota de Zentra'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: motion.duration(const Duration(milliseconds: 220)),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing.md,
                      0,
                      context.spacing.md,
                      context.spacing.md,
                    ),
                    child: Column(
                      children: [
                        if (linkedNoteId != null)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Esta sesión marcará la nota como repasada al completarse.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              TextButton(
                                onPressed: onRemoveLink,
                                child: const Text('Desvincular'),
                              ),
                            ],
                          ),
                        TextField(
                          key: const ValueKey('pomodoro_activity_field'),
                          controller: titleController,
                          textInputAction: TextInputAction.done,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la sesión',
                            hintText: 'Ej. Repasar Álgebra lineal',
                            helperText: 'Si lo dejas vacío: Sesión de enfoque',
                            prefixIcon: Icon(Icons.edit_outlined),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CycleSummary extends StatelessWidget {
  final PomodoroViewState provider;

  const _CycleSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: context.zentraPalette.warmPeach.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.route_rounded,
            color: context.zentraPalette.warmPeach,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(
              '4 × ${provider.workDuration} min · descansos de '
              '${provider.shortBreakDuration}/${provider.longBreakDuration} min',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationDialSheet extends StatefulWidget {
  final int initialMinutes;

  const _DurationDialSheet({required this.initialMinutes});

  @override
  State<_DurationDialSheet> createState() => _DurationDialSheetState();
}

class _DurationDialSheetState extends State<_DurationDialSheet> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes.clamp(5, 60);
  }

  void _updateFromPosition(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    const start = math.pi * 2 / 3;
    const sweep = math.pi * 5 / 3;
    var relative = math.atan2(vector.dy, vector.dx) - start;
    while (relative < 0) {
      relative += math.pi * 2;
    }
    while (relative >= math.pi * 2) {
      relative -= math.pi * 2;
    }

    // The 60-degree gap sits below the dial. A gesture inside that gap snaps
    // to the nearest endpoint instead of jumping abruptly between 5 and 60.
    if (relative > sweep) {
      relative = relative - sweep < (math.pi * 2 - relative) ? sweep : 0;
    }
    final clamped = ((relative / sweep) * 60).round().clamp(5, 60).toInt();
    if (clamped == _minutes) return;
    setState(() => _minutes = clamped);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = context.zentraPalette.focus;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        context.spacing.xs,
        context.spacing.lg,
        MediaQuery.viewPaddingOf(context).bottom + context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ajusta tu tiempo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            'Gira el dial. De 5 a 60 minutos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          Center(
            child: Semantics(
              key: const ValueKey('pomodoro_duration_dial'),
              slider: true,
              label: 'Tiempo de enfoque',
              hint:
                  'Desliza sobre el arco abierto para elegir de 5 a 60 minutos',
              value: '$_minutes minutos',
              increasedValue: '${math.min(60, _minutes + 1)} minutos',
              decreasedValue: '${math.max(5, _minutes - 1)} minutos',
              onIncrease:
                  _minutes < 60 ? () => setState(() => _minutes++) : null,
              onDecrease:
                  _minutes > 5 ? () => setState(() => _minutes--) : null,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(
                    260.0,
                    MediaQuery.sizeOf(context).width - 64,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _updateFromPosition(
                      details.localPosition,
                      Size.square(size),
                    ),
                    onPanUpdate: (details) => _updateFromPosition(
                      details.localPosition,
                      Size.square(size),
                    ),
                    onTapUp: (details) => _updateFromPosition(
                      details.localPosition,
                      Size.square(size),
                    ),
                    child: CustomPaint(
                      key: const ValueKey('pomodoro_duration_arc'),
                      painter: _DialPainter(
                        progress: _minutes / 60,
                        color: focus,
                        background: scheme.surfaceContainerHighest,
                        showTicks: true,
                      ),
                      child: SizedBox.square(
                        dimension: size,
                        child: Center(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.35,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_minutes',
                                  key:
                                      const ValueKey('pomodoro_duration_value'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  'minutos',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: context.spacing.lg),
          FilledButton(
            key: const ValueKey('pomodoro_duration_apply'),
            onPressed: () => Navigator.of(context).pop(_minutes),
            child: Text('Usar $_minutes minutos'),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color background;
  final bool showTicks;

  const _DialPainter({
    required this.progress,
    required this.color,
    required this.background,
    this.showTicks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = showTicks ? 7.0 : 6.0;
    final radius = math.min(size.width, size.height) / 2 - 18;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 2 / 3;
    const sweep = math.pi * 5 / 3;

    final track = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, track);
    canvas.drawArc(
      rect,
      start,
      sweep * progress.clamp(0, 1),
      false,
      active,
    );

    if (showTicks) {
      final tickPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      for (final minute in const [5, 15, 30, 45, 60]) {
        final angle = start + sweep * (minute / 60);
        final inner = Offset(
          center.dx + math.cos(angle) * (radius - 18),
          center.dy + math.sin(angle) * (radius - 18),
        );
        final outer = Offset(
          center.dx + math.cos(angle) * (radius - 9),
          center.dy + math.sin(angle) * (radius - 9),
        );
        canvas.drawLine(inner, outer, tickPaint);
      }
    }

    final thumbAngle = start + sweep * progress.clamp(0, 1);
    final thumb = Offset(
      center.dx + math.cos(thumbAngle) * radius,
      center.dy + math.sin(thumbAngle) * radius,
    );
    canvas.drawCircle(
      thumb,
      showTicks ? 15 : 11,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      thumb,
      showTicks ? 11 : 8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.background != background ||
        oldDelegate.showTicks != showTicks;
  }
}

class _FocusSession extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final bool expanded;

  const _FocusSession({
    required this.provider,
    required this.controller,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final timer = _TimerScene(provider: provider);
    final details = _SessionDetails(
      provider: provider,
      controller: controller,
    );

    if (expanded) {
      return Row(
        key: const ValueKey('focus_session_active'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 7, child: timer),
          SizedBox(width: context.spacing.xl),
          Expanded(flex: 5, child: details),
        ],
      );
    }

    return Column(
      key: const ValueKey('focus_session_active'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        timer,
        SizedBox(height: context.spacing.md),
        details,
      ],
    );
  }
}

class _TimerScene extends StatelessWidget {
  final PomodoroViewState provider;

  const _TimerScene({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isBreak = provider.isBreak;
    final accent =
        isBreak ? context.zentraPalette.warmPeach : context.zentraPalette.focus;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: context.motionPolicy.duration(
            const Duration(milliseconds: 260),
          ),
          child: Text(
            provider.state == PomodoroState.paused
                ? 'PAUSA'
                : isBreak
                    ? 'DESCANSO'
                    : 'ENFOQUE',
            key:
                ValueKey('${provider.state.name}-${provider.sessionType.name}'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                ),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        _FocusOrbit(provider: provider, color: accent),
      ],
    );
  }
}

class _FocusOrbit extends StatelessWidget {
  final PomodoroViewState provider;
  final Color color;

  const _FocusOrbit({
    required this.provider,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final max = MediaQuery.sizeOf(context).width < 360 ? 204.0 : 292.0;
        final size = math.min(max, constraints.maxWidth);
        return SizedBox.square(
          dimension: size,
          child: _FocusCore(
            provider: provider,
            color: color,
          ),
        );
      },
    );
  }
}

class _FocusBubbles extends StatefulWidget {
  final Color color;
  final bool isBreak;
  final bool running;

  const _FocusBubbles({
    required this.color,
    required this.isBreak,
    required this.running,
  });

  @override
  State<_FocusBubbles> createState() => _FocusBubblesState();
}

class _FocusBubblesState extends State<_FocusBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _FocusBubbles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBreak != widget.isBreak) {
      _controller.duration = Duration(
        milliseconds: widget.isBreak ? 4800 : 2600,
      );
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.running && context.motionPolicy.allowsDecorativeMotion;
    if (_shouldAnimate == shouldAnimate) return;
    _shouldAnimate = shouldAnimate;
    if (shouldAnimate) {
      _controller.duration = Duration(
        milliseconds: widget.isBreak ? 4800 : 2600,
      );
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.35;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = math.sin(_controller.value * math.pi * 2);
        return CustomPaint(
          key: const ValueKey('pomodoro_focus_aura'),
          painter: _FocusAuraPainter(
            progress: _controller.value,
            accent: widget.color,
            particleColors: [
              palette.water,
              palette.movement,
              palette.sleep,
              palette.focus,
            ],
            isBreak: widget.isBreak,
            running: _shouldAnimate,
          ),
          child: Stack(
            children: [
              _bubble(
                alignment: const Alignment(-0.72, -0.55),
                size: 58,
                color: palette.water,
                offset: Offset(0, wave * 7),
              ),
              _bubble(
                alignment: const Alignment(0.78, -0.32),
                size: 42,
                color: palette.movement,
                offset: Offset(wave * 6, 0),
              ),
              _bubble(
                alignment: const Alignment(-0.68, 0.62),
                size: 45,
                color: palette.sleep,
                offset: Offset(-wave * 5, wave * 5),
              ),
              _bubble(
                alignment: const Alignment(0.68, 0.68),
                size: 66,
                color: widget.color,
                offset: Offset(0, -wave * 6),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble({
    required Alignment alignment,
    required double size,
    required Color color,
    required Offset offset,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.24),
                color.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.44)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusAuraPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final List<Color> particleColors;
  final bool isBreak;
  final bool running;

  const _FocusAuraPainter({
    required this.progress,
    required this.accent,
    required this.particleColors,
    required this.isBreak,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final glowRect = Rect.fromCircle(
      center: center,
      radius: shortest * 0.48,
    );
    canvas.drawCircle(
      center,
      shortest * 0.47,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: running ? 0.18 : 0.10),
            accent.withValues(alpha: 0),
          ],
          stops: const [0.28, 1],
        ).createShader(glowRect),
    );

    if (!running) return;

    if (isBreak) {
      _paintParticles(canvas, center, shortest);
    } else {
      _paintFocusWaves(canvas, center, shortest);
    }
  }

  void _paintFocusWaves(Canvas canvas, Offset center, double shortest) {
    for (var index = 0; index < 3; index++) {
      final phase = (progress + index / 3) % 1;
      final radius = shortest * (0.30 + phase * 0.19);
      final opacity = (1 - phase) * 0.34;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  void _paintParticles(Canvas canvas, Offset center, double shortest) {
    for (var index = 0; index < 10; index++) {
      final seed = index / 10;
      final angle = (seed + progress * (0.18 + index % 3 * 0.03)) * math.pi * 2;
      final breath = math.sin((progress + seed) * math.pi * 2);
      final radius = shortest * (0.34 + index % 3 * 0.035) + breath * 7;
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final color = particleColors[index % particleColors.length];
      final dotRadius = 2.4 + index % 3;
      canvas.drawCircle(
        position,
        dotRadius,
        Paint()..color = color.withValues(alpha: 0.38 + index % 2 * 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusAuraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.isBreak != isBreak ||
        oldDelegate.running != running ||
        oldDelegate.particleColors != particleColors;
  }
}

class _FocusCore extends StatefulWidget {
  final PomodoroViewState provider;
  final Color color;

  const _FocusCore({
    required this.provider,
    required this.color,
  });

  @override
  State<_FocusCore> createState() => _FocusCoreState();
}

class _FocusCoreState extends State<_FocusCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _FocusCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = widget.provider.state == PomodoroState.running &&
        context.motionPolicy.allowsDecorativeMotion;
    final duration = Duration(
      milliseconds: widget.provider.isBreak ? 6200 : 5600,
    );
    if (_shouldAnimate == shouldAnimate && _controller.duration == duration) {
      return;
    }
    _shouldAnimate = shouldAnimate;
    _controller.duration = duration;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sine = math.sin(_controller.value * math.pi * 2);
        final scale = _shouldAnimate ? 1.0025 + sine * 0.0125 : 1.0;
        final glow = _shouldAnimate ? 0.10 + (sine + 1) * 0.035 : 0.08;
        return DecoratedBox(
          key: const ValueKey('pomodoro_breathing_core'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: 48,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('pomodoro_timer_progress'),
              tween: Tween<double>(
                begin: 0,
                end: widget.provider.progress.clamp(0, 1),
              ),
              duration: context.motionPolicy.duration(
                const Duration(milliseconds: 900),
              ),
              curve: Curves.linear,
              builder: (context, progress, _) {
                return CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: widget.color,
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.zentraPalette.functionalSurface
                  .withValues(alpha: dark ? 0.92 : 0.88),
            ),
            child: Center(
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.35,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.provider.formattedTime,
                      key: const ValueKey('pomodoro_time'),
                      semanticsLabel:
                          '${widget.provider.remainingSeconds ~/ 60} minutos y '
                          '${widget.provider.remainingSeconds % 60} segundos',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontSize: MediaQuery.sizeOf(context).width < 360
                                    ? 56
                                    : 76,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -3,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: dark ? widget.color : null,
                              ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      widget.provider.isBreak ? 'descanso' : 'enfoque',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetails extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _SessionDetails({
    required this.provider,
    required this.controller,
  });

  Future<void> _confirmEnd(BuildContext context) async {
    final isCycleCancellation =
        provider.isCycleMode && provider.hasActiveActivity && !provider.isBreak;
    final title = provider.isBreak
        ? '¿Saltar descanso?'
        : isCycleCancellation
            ? '¿Cancelar ciclo?'
            : '¿Terminar enfoque?';
    final message = provider.isBreak
        ? 'Pasarás al siguiente enfoque.'
        : isCycleCancellation
            ? 'El ciclo actual se cancelará y no sumará esta etapa.'
            : 'La sesión no sumará minutos ni afectará tu progreso.';
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton.tonal(
            key: const ValueKey('pomodoro_cancel_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              provider.isBreak
                  ? 'Saltar'
                  : isCycleCancellation
                      ? 'Cancelar ciclo'
                      : 'Terminar',
            ),
          ),
        ],
      ),
    );
    if (shouldEnd == true) {
      if (isCycleCancellation) {
        await controller.cancelActivity();
      } else {
        await controller.skip();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isRunning = provider.state == PomodoroState.running;
    final endTooltip = provider.isBreak
        ? 'Saltar descanso'
        : provider.isCycleMode && provider.hasActiveActivity
            ? 'Cancelar ciclo'
            : 'Terminar enfoque';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          provider.sessionLabel,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        if (provider.isCycleMode)
          _CycleProgress(provider: provider)
        else
          _QuickProgress(provider: provider),
        SizedBox(height: context.spacing.lg),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Reiniciar etapa',
              child: IconButton.outlined(
                key: const ValueKey('pomodoro_reset'),
                tooltip: 'Reiniciar etapa',
                onPressed: controller.reset,
                icon: const Icon(Icons.replay_rounded),
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('pomodoro_pause_resume'),
                onPressed: isRunning ? controller.pause : controller.start,
                icon: Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  isRunning
                      ? 'Pausar'
                      : provider.state == PomodoroState.paused
                          ? 'Continuar'
                          : provider.isBreak
                              ? 'Iniciar descanso'
                              : 'Iniciar enfoque',
                ),
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Semantics(
              button: true,
              label: endTooltip,
              child: IconButton.outlined(
                key: const ValueKey('pomodoro_cancel_activity'),
                tooltip: endTooltip,
                onPressed: () => _confirmEnd(context),
                icon: Icon(
                  provider.isBreak
                      ? Icons.skip_next_rounded
                      : Icons.stop_rounded,
                ),
              ),
            ),
          ],
        ),
        if (provider.linkedNoteId != null) ...[
          SizedBox(height: context.spacing.md),
          Container(
            padding: EdgeInsets.all(context.spacing.md),
            decoration: BoxDecoration(
              color: context.zentraPalette.calmMint.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(context.radii.medium),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nota vinculada',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Se marcará como repasada al completar el enfoque.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CycleProgress extends StatelessWidget {
  final PomodoroViewState provider;

  const _CycleProgress({required this.provider});

  @override
  Widget build(BuildContext context) {
    final completed = provider.activityCyclesCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var index = 0; index < 4; index++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: context.motionPolicy.duration(
                    const Duration(milliseconds: 220),
                  ),
                  height: 8,
                  decoration: BoxDecoration(
                    color: index < completed
                        ? context.zentraPalette.focus
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (index < 3) SizedBox(width: context.spacing.xs),
            ],
          ],
        ),
        SizedBox(height: context.spacing.sm),
        Text(
          '$completed de 4 enfoques completados',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          provider.isBreak
              ? 'Después: ${provider.activityCyclesCompleted >= 4 ? 'ciclo completo' : 'enfoque ${completed + 1}'}'
              : 'Después: ${completed >= 3 ? 'descanso largo' : 'descanso corto'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _QuickProgress extends StatelessWidget {
  final PomodoroViewState provider;

  const _QuickProgress({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.center_focus_strong_rounded,
          color: context.zentraPalette.focus,
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Text(
            '${provider.activeStageDuration} min',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _FocusCompletionDialog extends StatelessWidget {
  final String title;
  final int focuses;
  final int minutes;

  const _FocusCompletionDialog({
    required this.title,
    required this.focuses,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cycle = focuses > 1;

    return AlertDialog(
      key: const ValueKey('focus_completion_dialog'),
      icon: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.zentraPalette.calmMint,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 36,
          color: context.zentraPalette.focus,
        ),
      ),
      title: Text(
        cycle ? 'Ciclo completado' : 'Enfoque completado',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            cycle
                ? '$focuses enfoques · $minutes minutos'
                : '$minutes minutos presentes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          key: const ValueKey('focus_completion_close'),
          onPressed: Navigator.of(context).pop,
          child: const Text('Listo'),
        ),
      ],
    );
  }
}

Future<void> _showFocusSettings(
  BuildContext context,
  PomodoroViewState provider,
  PomodoroController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FocusSettingsSheet(
      provider: provider,
      controller: controller,
    ),
  );
}

class _FocusSettingsSheet extends StatefulWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _FocusSettingsSheet({
    required this.provider,
    required this.controller,
  });

  @override
  State<_FocusSettingsSheet> createState() => _FocusSettingsSheetState();
}

class _FocusSettingsSheetState extends State<_FocusSettingsSheet> {
  late int _focus;
  late int _shortBreak;
  late int _longBreak;

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    _focus = provider.workDuration;
    _shortBreak = provider.shortBreakDuration;
    _longBreak = provider.longBreakDuration;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        context.spacing.xs,
        context.spacing.lg,
        MediaQuery.viewPaddingOf(context).bottom + context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tiempos del ciclo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            'Los cambios se aplican a la siguiente etapa, nunca a una que ya está en curso.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          _DurationSetting(
            label: 'Enfoque',
            value: _focus,
            min: 5,
            max: 60,
            color: context.zentraPalette.focus,
            onChanged: (value) {
              setState(() => _focus = value);
              controller.setWorkDuration(value);
            },
          ),
          _DurationSetting(
            label: 'Descanso corto',
            value: _shortBreak,
            min: 1,
            max: 15,
            color: context.zentraPalette.water,
            onChanged: (value) {
              setState(() => _shortBreak = value);
              controller.setShortBreakDuration(value);
            },
          ),
          _DurationSetting(
            label: 'Descanso largo',
            value: _longBreak,
            min: 5,
            max: 30,
            color: context.zentraPalette.sleep,
            onChanged: (value) {
              setState(() => _longBreak = value);
              controller.setLongBreakDuration(value);
            },
          ),
        ],
      ),
    );
  }
}

class _DurationSetting extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DurationSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '$value min',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: color,
            label: '$value min',
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}
