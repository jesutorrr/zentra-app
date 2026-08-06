import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/pomodoro_provider.dart';
import '../application/session_controller.dart';
import '../domain/pomodoro_activity.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'pomodoro_history_screen.dart';
import 'theme.dart';
import 'utils/feedback_utils.dart';
import 'widgets/ambient_background.dart';
import 'widgets/focus_dial_geometry.dart';
import 'widgets/mode_band.dart';
import 'widgets/responsive_layout.dart';

/// Portal de entrada y superficie inmersiva para el flujo de enfoque.
///
/// El motor conserva la sesión, notificaciones y Live Activity. Esta pantalla
/// sólo traduce ese estado a la gramática visual Portal + Silencio.
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
  PomodoroActivity? _completion;
  String? _handledCompletionId;

  void _captureCompletion(
    PomodoroViewState state,
    PomodoroController controller,
  ) {
    final completed = state.justCompletedActivity;
    if (completed == null || completed.id == _handledCompletionId) return;
    _handledCompletionId = completed.id;
    controller.clearJustCompletedActivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      triggerHaptic(HapticType.medium);
      setState(() => _completion = completed);
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
      (_, next) => _captureCompletion(next, controller),
    );
    final state = ref.watch(pomodoroProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final usesAccessibleStartBar = _completion == null &&
        state.canShowLauncher &&
        context.zentraWindowClass == ZentraWindowClass.compact &&
        textScale >= 2;

    final child = switch ((_completion, state.canShowLauncher)) {
      (final PomodoroActivity completed, _) => FocusCompletionScene(
          activity: completed,
          onClose: () => setState(() => _completion = null),
        ),
      (null, true) => _FocusLauncher(
          key: _launcherKey,
          provider: state,
          controller: controller,
          initialTitle: widget.initialTitle,
          linkedNoteId: widget.linkedNoteId,
          showPortalStart: !usesAccessibleStartBar,
        ),
      _ => _ImmersiveFocusScene(
          provider: state,
          controller: controller,
        ),
    };

    return Scaffold(
      backgroundColor: state.canShowLauncher
          ? context.zentraPalette.functionalSurface
          : null,
      bottomNavigationBar: usesAccessibleStartBar
          ? _AccessibleFocusStartBar(
              provider: state,
              onStart: () => _launcherKey.currentState?._start(),
            )
          : null,
      body: AnimatedSwitcher(
        duration: context.motionPolicy.duration(
          const Duration(milliseconds: 420),
        ),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: child,
      ),
    );
  }
}

class _FocusLauncher extends StatefulWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final String? initialTitle;
  final String? linkedNoteId;
  final bool showPortalStart;

  const _FocusLauncher({
    required this.provider,
    required this.controller,
    required this.initialTitle,
    required this.linkedNoteId,
    required this.showPortalStart,
    super.key,
  });

  @override
  State<_FocusLauncher> createState() => _FocusLauncherState();
}

class _FocusLauncherState extends State<_FocusLauncher> {
  static const _presets = [5, 15, 25, 45];

  late final TextEditingController _titleController;
  late bool _contextExpanded;
  String? _linkedNoteId;
  String? _linkedNoteTitle;
  bool _isEntering = false;
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.initialTitle?.trim();
    _titleController = TextEditingController(
      text: widget.linkedNoteId == null ? initialTitle : null,
    );
    _linkedNoteId = widget.linkedNoteId;
    _linkedNoteTitle = widget.linkedNoteId == null ? null : initialTitle;
    _contextExpanded =
        (initialTitle?.isNotEmpty ?? false) || widget.linkedNoteId != null;
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// Reveals the name field and puts the caret in it.
  ///
  /// On a phone the field opens below the fold, so asking to name the session
  /// and then having to hunt for the field defeats the point of the button.
  /// Focusing it scrolls it into view and raises the keyboard, which is what
  /// tapping "Nombrar esta sesión" was asking for.
  void _toggleContext() {
    final expanding = !_contextExpanded;
    setState(() => _contextExpanded = expanding);
    if (!expanding || _linkedNoteId != null) {
      _titleFocus.unfocus();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  Future<void> _start() async {
    if (_isEntering) return;
    FocusManager.instance.primaryFocus?.unfocus();
    triggerHaptic(HapticType.medium);
    setState(() => _isEntering = true);

    final transition = context.motionPolicy.duration(
      const Duration(milliseconds: 560),
    );
    if (transition > Duration.zero) await Future<void>.delayed(transition);
    if (!mounted) return;

    final title = _titleController.text.trim();
    try {
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
    } finally {
      if (mounted) setState(() => _isEntering = false);
    }
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
    if (result != null) await widget.controller.setWorkDuration(result);
  }

  /// Los tiempos, desde la fila que habla de ellos.
  ///
  /// Antes eran dos entradas: un ⚙ en la banda para los descansos y un chip
  /// «Otro» para la duración. Son la misma conversación, así que ahora es una
  /// sola hoja que se adapta al modo.
  void _openFocusTimes() {
    triggerHaptic(HapticType.light);
    _showFocusSettings(context, widget.provider, widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('pomodoro_launcher'),
      child: ZentraAmbientBackground(
        // The band takes the top inset itself so its teal reaches the physical
        // top edge; taking it here too would leave a cream strip above it.
        child: SafeArea(
          top: false,
          child: ResponsiveLayoutBuilder(
            builder: (context, layout) {
              return CustomScrollView(
                key: const ValueKey('focus_screen_scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  // The band: navigation and the Rápido / Ciclo choice on one
                  // strip, exactly as the habit form opens. It stays in its own
                  // sliver against the top edge so the portal below can claim
                  // the middle without dragging it along. Full-bleed, so the
                  // page padding lives inside it rather than around it.
                  SliverToBoxAdapter(
                    child: ZentraModeBand(
                      child: Padding(
                        // The band grew by a whole row when the selector moved
                        // into it, and on a 320x568 screen that row costs 16dp
                        // more than the launcher has. It comes out of the band's
                        // own air rather than out of the portal below, which is
                        // the part the user has to reach.
                        padding: EdgeInsets.fromLTRB(
                          layout.horizontalPagePadding,
                          layout.isShort
                              ? context.spacing.xs
                              : layout.verticalPagePadding,
                          layout.horizontalPagePadding,
                          layout.isShort
                              ? context.spacing.xs
                              : context.spacing.md,
                        ),
                        child: ResponsiveContentFrame(
                          maxWidth: 1040,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FocusTopBar(
                                provider: widget.provider,
                                showTitle: true,
                                foreground:
                                    ZentraModeBand.foregroundOf(context),
                              ),
                              SizedBox(height: context.spacing.xs),
                              _ModeSelector(
                                provider: widget.provider,
                                controller: widget.controller,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The portal is the whole point of this screen, so on a
                  // tablet it sits in the middle of the space instead of
                  // hugging the top with the window empty below it. Content
                  // taller than the window still scrolls from the top instead
                  // of overflowing.
                  //
                  // SliverFillRemaining would be the obvious fit, but it sizes
                  // its child from that child's *intrinsic* height, and an
                  // AnimatedSize reports the height it is animating towards
                  // rather than the one it currently paints. Naming a session
                  // shrinks the field by one line, so mid-animation the column
                  // painted 16px taller than the space the sliver had reserved
                  // and overflowed. Constraining the minimum height instead
                  // measures the real layout: it centers while the content fits
                  // and grows into a scroll the moment it does not.
                  SliverLayoutBuilder(
                    builder: (context, sliverConstraints) {
                      final available = math.max(
                        0.0,
                        sliverConstraints.viewportMainAxisExtent -
                            sliverConstraints.precedingScrollExtent,
                      );
                      return SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: available),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              layout.horizontalPagePadding,
                              0,
                              layout.horizontalPagePadding,
                              // On a short phone this bottom air is the
                              // difference between the naming button being on
                              // the screen and being under it.
                              layout.isShort
                                  ? context.spacing.md
                                  : context.spacing.xxl,
                            ),
                            // El titular «Una sola cosa» vivía aquí, y en una
                            // ventana ancha ocupaba la columna izquierda con el
                            // portal a su derecha. La pantalla ya se nombra en
                            // la banda, así que la columna se fue con él: el
                            // portal se centra solo, en teléfono y en tablet,
                            // en lugar de quedar pegado a un costado con un
                            // hueco enfrente.
                            child: ResponsiveContentFrame(
                              alignment: Alignment.center,
                              maxWidth: 560,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!layout.isShort)
                                    SizedBox(height: context.spacing.md),
                                  _PortalConfiguration(
                                    provider: widget.provider,
                                    controller: widget.controller,
                                    titleController: _titleController,
                                    titleFocus: _titleFocus,
                                    linkedNoteId: _linkedNoteId,
                                    linkedNoteTitle: _linkedNoteTitle,
                                    contextExpanded: _contextExpanded,
                                    presets: _presets,
                                    isEntering: _isEntering,
                                    showStart: widget.showPortalStart,
                                    onStart: _start,
                                    onOpenDial: _openDurationDial,
                                    onOpenTimes: _openFocusTimes,
                                    onToggleContext: _toggleContext,
                                    onRemoveLink: () => setState(() {
                                      _linkedNoteId = null;
                                      _linkedNoteTitle = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

/// La fila de navegación de Enfoque: `‹ Enfoque … ⟲`.
///
/// El mismo esqueleto que abre el formulario de hábito —flecha, título, una
/// acción— con el selector de modo debajo. El título vive dentro de la fila de
/// 48dp que ya existía, así que nombrar la pantalla no le costó altura a nada.
///
/// Aquí vivía también un ⚙ para los tiempos del ciclo. Se fue a la fila de
/// abajo, junto a la duración, que es de lo que hablaba: dos accesos a lo mismo
/// desde extremos opuestos de la pantalla eran un botón de más.
class _FocusTopBar extends StatelessWidget {
  final PomodoroViewState provider;
  final bool showTitle;
  final Color? foreground;
  final VoidCallback? onBack;

  const _FocusTopBar({
    required this.provider,
    required this.showTitle,
    this.foreground,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final iconStyle = IconButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(
        color: (foreground ?? Theme.of(context).colorScheme.outline)
            .withValues(alpha: 0.34),
      ),
      minimumSize: const Size.square(48),
    );

    return Row(
      children: [
        if (canPop || onBack != null)
          IconButton.outlined(
            tooltip: provider.canShowLauncher ? 'Volver' : 'Salir del enfoque',
            style: iconStyle,
            onPressed: onBack ?? Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        if (showTitle)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: context.spacing.sm),
              child: Text(
                'Enfoque',
                key: const ValueKey('focus_portal_headline'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: foreground,
                    ),
              ),
            ),
          )
        else
          const Spacer(),
        IconButton.outlined(
          tooltip: 'Historial',
          style: iconStyle,
          onPressed: () {
            triggerHaptic(HapticType.light);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PomodoroHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    );
  }
}

/// «Rápido / Ciclo», el mismo control que «Se repite / Una sola vez».
///
/// Antes era una copia con el mismo propósito y cuatro diferencias: pastilla de
/// radio 999 contra 18, riel de otro color, mitades ajustadas a su etiqueta en
/// vez de repartidas, y relleno `brandDeep` en vez de la pastilla clara. Ahora
/// las dos pantallas construyen el mismo widget, así que no pueden volver a
/// separarse.
class _ModeSelector extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _ModeSelector({
    required this.provider,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ZentraModeSelector(
      options: [
        ZentraModeOption(
          key: const ValueKey('pomodoro_mode_quick'),
          label: 'Rápido',
          selected: provider.isQuickMode,
          onTap: () => controller.selectMode(PomodoroMode.quick),
        ),
        ZentraModeOption(
          key: const ValueKey('pomodoro_mode_cycle'),
          label: 'Ciclo',
          selected: provider.isCycleMode,
          onTap: () => controller.selectMode(PomodoroMode.cycle),
        ),
      ],
    );
  }
}

class _PortalConfiguration extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String? linkedNoteId;
  final String? linkedNoteTitle;
  final bool contextExpanded;
  final List<int> presets;
  final bool isEntering;
  final bool showStart;
  final VoidCallback onStart;
  final VoidCallback onOpenDial;
  final VoidCallback onOpenTimes;
  final VoidCallback onToggleContext;
  final VoidCallback onRemoveLink;

  const _PortalConfiguration({
    required this.provider,
    required this.controller,
    required this.titleController,
    required this.titleFocus,
    required this.linkedNoteId,
    required this.linkedNoteTitle,
    required this.contextExpanded,
    required this.presets,
    required this.isEntering,
    required this.showStart,
    required this.onStart,
    required this.onOpenDial,
    required this.onOpenTimes,
    required this.onToggleContext,
    required this.onRemoveLink,
  });

  @override
  Widget build(BuildContext context) {
    // Narrow phones lose the chips' decorative width, never their height: at
    // VisualDensity.compact they came out 40dp tall, under the 48dp tap target,
    // which is not a trade worth making for one row of layout.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    // Tight at every width, not only below 360dp. When "Otro" shared this row
    // the five chips never got their intrinsic width — not even on a 430dp
    // screen — so the default 20dp of air per side came out of the label
    // instead: measured, the digits fell to 9.3dp at 360 and 0dp at 393 once
    // selected. "Otro" is a row of its own now and each chip went from ~16% to
    // 25% of the width, but the padding stays tight: it is what keeps 320dp
    // honest, and keying it to a device width was a guess about the phone when
    // the squeeze belongs to the row.
    const labelPadding = EdgeInsets.symmetric(horizontal: 2);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _PortalDial(
              minutes: provider.workDuration,
              isEntering: isEntering,
              showStart: showStart,
              onChanged: controller.setWorkDuration,
              onOpenFineTune: onOpenDial,
              onStart: onStart,
            ),
          ),
          SizedBox(
            height: narrow ? context.spacing.sm : context.spacing.md,
          ),
          _DurationPresets(
            presets: presets,
            selected: provider.workDuration,
            narrow: narrow,
            labelPadding: labelPadding,
            onSelect: controller.setWorkDuration,
          ),
          SizedBox(height: narrow ? context.spacing.xxs : context.spacing.xs),
          _FocusTimesRow(
            isCycle: provider.isCycleMode,
            shortBreak: provider.shortBreakDuration,
            longBreak: provider.longBreakDuration,
            onOpen: onOpenTimes,
          ),
          SizedBox(height: context.spacing.xs),
          _OptionalFocusContext(
            expanded: contextExpanded,
            titleController: titleController,
            titleFocus: titleFocus,
            linkedNoteId: linkedNoteId,
            linkedNoteTitle: linkedNoteTitle,
            onToggle: onToggleContext,
            onRemoveLink: onRemoveLink,
          ),
        ],
      ),
    );
  }
}

/// La fila de los tiempos: lo que hay puesto, y la manera de cambiarlo.
///
/// En Ciclo esto era una leyenda —«4 enfoques · descansos de 5 y 15 min»— que
/// decía exactamente lo que el usuario querría tocar y no se podía tocar; los
/// ajustes vivían tras un ⚙ en la esquina opuesta de la pantalla. Ahora el
/// resumen ES el control. En Rápido no hay descansos que resumir, así que la
/// misma fila ofrece lo único que queda por ajustar: otra duración.
class _FocusTimesRow extends StatelessWidget {
  final bool isCycle;
  final int shortBreak;
  final int longBreak;
  final VoidCallback onOpen;

  const _FocusTimesRow({
    required this.isCycle,
    required this.shortBreak,
    required this.longBreak,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = isCycle
        ? '4 enfoques · descansos de $shortBreak y $longBreak min'
        : 'Otra duración';

    return TextButton(
      key: const ValueKey('pomodoro_custom_duration_button'),
      onPressed: onOpen,
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        minimumSize: const Size.fromHeight(48),
        padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.medium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tune_rounded, size: 18),
          SizedBox(width: context.spacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

/// The four presets on a single row: choosing a duration, and nothing else.
///
/// They used to be a centered [Wrap], which is fine until the row does not fit:
/// then the last chip drops to a second line, and the whole portal grows by
/// 56dp. On a 320dp screen that was exactly what pushed the naming button off
/// the bottom edge. Sharing the width equally keeps one row down to 320dp
/// without shrinking any tap target below 48dp.
///
/// "Otro" used to be a fifth chip here, which made the row two things at once —
/// four numbers and a doorway — and starved all five of width. It is a row of
/// its own now, next to the times it opens.
class _DurationPresets extends StatelessWidget {
  final List<int> presets;
  final int selected;
  final bool narrow;
  final EdgeInsets? labelPadding;
  final ValueChanged<int> onSelect;

  const _DurationPresets({
    required this.presets,
    required this.selected,
    required this.narrow,
    required this.labelPadding,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gap = narrow ? context.spacing.xxs : context.spacing.xs;
    final chips = <Widget>[
      for (final preset in presets)
        ChoiceChip(
          key: ValueKey('pomodoro_duration_$preset'),
          label: Text('$preset', textAlign: TextAlign.center),
          selected: selected == preset,
          labelPadding: labelPadding,
          // No checkmark at any width. It widens whichever chip is selected,
          // and when the chips share the row equally there is no width to widen
          // into: the label got squeezed to 0dp and the digits came out under
          // the tick. The fill says which one is chosen, and so does its
          // selected semantics.
          showCheckmark: false,
          onSelected: (_) {
            triggerHaptic(HapticType.selection);
            onSelect(preset);
          },
        ),
    ];

    return Row(
      children: [
        for (var index = 0; index < chips.length; index++) ...[
          if (index > 0) SizedBox(width: gap),
          Expanded(child: Align(child: chips[index])),
        ],
      ],
    );
  }
}

class _PortalDial extends StatelessWidget {
  final int minutes;
  final bool isEntering;
  final bool showStart;
  final ValueChanged<int> onChanged;
  final VoidCallback onOpenFineTune;
  final VoidCallback onStart;

  const _PortalDial({
    required this.minutes,
    required this.isEntering,
    required this.showStart,
    required this.onChanged,
    required this.onOpenFineTune,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final cream = ZentraPalette.light.functionalSurface;
    final screen = MediaQuery.sizeOf(context);
    // Width alone used to decide this, which is why a 375×667 phone got a 335dp
    // dial — half its height — and pushed "Otro" and the naming button off the
    // screen. Capping against height as well keeps the whole portal on one
    // screen on short phones; on a 393×852 and up the width cap still wins, so
    // the dial there is exactly the size it has always been.
    final size = math.min(
      math.min(372.0, screen.width - 40),
      math.max(240.0, screen.height * 0.42),
    );
    final paintedProgress = FocusDialGeometry.fractionFor(minutes);

    void update(Offset position) {
      final next = FocusDialGeometry.minutesFromOffset(
        position,
        Size.square(size),
      );
      if (next == minutes) return;
      HapticFeedback.selectionClick();
      onChanged(next);
    }

    return AnimatedScale(
      key: const ValueKey('focus_portal'),
      scale: isEntering ? 2.65 : 1,
      duration: context.motionPolicy.duration(
        const Duration(milliseconds: 560),
      ),
      curve: Curves.easeInOutCubic,
      child: Semantics(
        slider: true,
        label: 'Duración del enfoque, mínimo 5, máximo 60 minutos',
        value: '$minutes minutos',
        increasedValue: '${math.min(60, minutes + 5)} minutos',
        decreasedValue: '${math.max(5, minutes - 5)} minutos',
        onIncrease: minutes < 60 ? () => onChanged(minutes + 5) : null,
        onDecrease: minutes > 5 ? () => onChanged(minutes - 5) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => update(details.localPosition),
          onPanUpdate: (details) => update(details.localPosition),
          onTapUp: (details) {
            final center = Offset(size / 2, size / 2);
            if ((details.localPosition - center).distance > size * 0.32) {
              update(details.localPosition);
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.brandDeep,
              boxShadow: [
                BoxShadow(
                  color: palette.brandDeep.withValues(alpha: 0.18),
                  blurRadius: 42,
                  spreadRadius: -14,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: AnimatedOpacity(
              opacity: isEntering ? 0 : 1,
              duration: context.motionPolicy.duration(
                const Duration(milliseconds: 220),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('pomodoro_duration_arc'),
                      painter: _PortalDialPainter(
                        progress: paintedProgress,
                        active: palette.tealSoft,
                        track: cream.withValues(alpha: 0.18),
                        labels: cream.withValues(alpha: 0.60),
                      ),
                    ),
                  ),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$minutes',
                          key: const ValueKey('pomodoro_duration_value'),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                            color: cream,
                            fontWeight: FontWeight.w300,
                            fontSize: size < 320 ? 64 : 78,
                            letterSpacing: -4,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        Text(
                          'MINUTOS',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: cream.withValues(alpha: 0.62),
                                    letterSpacing: 3,
                                  ),
                        ),
                        if (showStart) ...[
                          SizedBox(height: context.spacing.lg),
                          FilledButton(
                            key: const ValueKey('pomodoro_start_button'),
                            onPressed: onStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: cream,
                              foregroundColor: palette.brandDeep,
                              minimumSize: const Size(132, 52),
                            ),
                            child: const Text('Entrar'),
                          ),
                        ] else ...[
                          SizedBox(height: context.spacing.sm),
                          TextButton(
                            onPressed: onOpenFineTune,
                            style: TextButton.styleFrom(foregroundColor: cream),
                            child: const Text('Ajustar'),
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
    );
  }
}

class _PortalDialPainter extends CustomPainter {
  final double progress;
  final Color active;
  final Color track;
  final Color labels;

  const _PortalDialPainter({
    required this.progress,
    required this.active,
    required this.track,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 38;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = FocusDialGeometry.startAngle;
    const sweep = FocusDialGeometry.sweepAngle;
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..color = active
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, base);
    canvas.drawArc(
      rect,
      start,
      sweep * progress.clamp(0, 1),
      false,
      foreground,
    );

    for (final minute in FocusDialGeometry.marks) {
      final angle = FocusDialGeometry.angleFor(minute);
      final mark = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(mark, 2.5, Paint()..color = labels);
      final painter = TextPainter(
        text: TextSpan(
          text: '$minute',
          style: TextStyle(
            color: labels,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelRadius = radius - 19;
      final labelCenter = Offset(
        center.dx + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );
      painter.paint(
        canvas,
        labelCenter - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final thumbAngle = start + sweep * progress.clamp(0, 1);
    final thumb = Offset(
      center.dx + math.cos(thumbAngle) * radius,
      center.dy + math.sin(thumbAngle) * radius,
    );
    canvas.drawCircle(
      thumb,
      10,
      Paint()..color = active.withValues(alpha: 0.2),
    );
    canvas.drawCircle(thumb, 6, Paint()..color = active);
  }

  @override
  bool shouldRepaint(covariant _PortalDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.track != track ||
        oldDelegate.labels != labels;
  }
}

class _OptionalFocusContext extends StatelessWidget {
  final bool expanded;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String? linkedNoteId;
  final String? linkedNoteTitle;
  final VoidCallback onToggle;
  final VoidCallback onRemoveLink;

  const _OptionalFocusContext({
    required this.expanded,
    required this.titleController,
    required this.titleFocus,
    required this.linkedNoteId,
    required this.linkedNoteTitle,
    required this.onToggle,
    required this.onRemoveLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          key: const ValueKey('pomodoro_optional_context'),
          onPressed: onToggle,
          icon: Icon(
            expanded ? Icons.remove_rounded : Icons.add_rounded,
            size: 18,
          ),
          // Naming the session is what makes it findable in the history later,
          // so the button says what it does instead of hiding the field behind
          // a word as vague as "contexto".
          label: Text(
            linkedNoteId == null ? 'Nombrar esta sesión' : 'Con nota',
          ),
        ),
        AnimatedSize(
          duration: context.motionPolicy.duration(
            const Duration(milliseconds: 220),
          ),
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(top: context.spacing.xs),
                  child: linkedNoteId != null
                      ? Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 20),
                            SizedBox(width: context.spacing.sm),
                            Expanded(
                              child: Text(
                                linkedNoteTitle ?? 'Nota vinculada',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar nota',
                              onPressed: onRemoveLink,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        )
                      : TextField(
                          key: const ValueKey('pomodoro_activity_field'),
                          controller: titleController,
                          focusNode: titleFocus,
                          maxLength: 80,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la sesión',
                            hintText: 'Ej. Estudiar Química',
                            helperText: 'Se guarda en tu historial. Opcional.',
                            counterText: '',
                            prefixIcon: Icon(Icons.edit_outlined),
                          ),
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AccessibleFocusStartBar extends StatelessWidget {
  final PomodoroViewState provider;
  final VoidCallback onStart;

  const _AccessibleFocusStartBar({
    required this.provider,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final label = provider.isCycleMode ? 'Iniciar ciclo' : 'Iniciar enfoque';
    return Material(
      color: context.zentraPalette.functionalSurface,
      elevation: 10,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.all(context.spacing.sm),
        child: FilledButton(
          key: const ValueKey('pomodoro_start_button'),
          onPressed: onStart,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 2,
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
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
    _minutes = _snap(widget.initialMinutes);
  }

  static int _snap(int minutes) => FocusDialGeometry.snap(minutes);

  void _setMinutes(int value) {
    final next = _snap(value);
    if (next == _minutes) return;
    setState(() => _minutes = next);
    HapticFeedback.selectionClick();
  }

  void _updateFromPosition(Offset position, Size size) {
    _setMinutes(FocusDialGeometry.minutesFromOffset(position, size));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = context.zentraPalette.focus;
    final size = math.min(280.0, MediaQuery.sizeOf(context).width - 64);
    final progress = FocusDialGeometry.fractionFor(_minutes);

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
              label: 'Tiempo de enfoque, mínimo 5, máximo 60 minutos',
              value: '$_minutes minutos',
              increasedValue: '${math.min(60, _minutes + 5)} minutos',
              decreasedValue: '${math.max(5, _minutes - 5)} minutos',
              onIncrease:
                  _minutes < 60 ? () => _setMinutes(_minutes + 5) : null,
              onDecrease: _minutes > 5 ? () => _setMinutes(_minutes - 5) : null,
              child: GestureDetector(
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
                  painter: _PortalDialPainter(
                    progress: progress,
                    active: focus,
                    track: scheme.surfaceContainerHighest,
                    labels: scheme.onSurfaceVariant,
                  ),
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.25,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_minutes',
                              key: const ValueKey('pomodoro_duration_value'),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w400,
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
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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

class _ImmersiveFocusScene extends StatefulWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;

  const _ImmersiveFocusScene({
    required this.provider,
    required this.controller,
  });

  @override
  State<_ImmersiveFocusScene> createState() => _ImmersiveFocusSceneState();
}

class _ImmersiveFocusSceneState extends State<_ImmersiveFocusScene> {
  bool _allowPop = false;
  bool _exitSheetVisible = false;

  Future<void> _offerExit() async {
    if (_exitSheetVisible) return;
    _exitSheetVisible = true;
    final action = await showModalBottomSheet<_ExitAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ExitFocusSheet(
        isBreak: widget.provider.isBreak,
      ),
    );
    _exitSheetVisible = false;
    if (!mounted || action == null || action == _ExitAction.stay) return;
    if (action == _ExitAction.end) await _endSession();
    if (!mounted || action == _ExitAction.end) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _confirmEnd() async {
    final shouldEnd = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _EndFocusSheet(isBreak: widget.provider.isBreak),
    );
    if (shouldEnd == true) await _endSession();
  }

  Future<void> _endSession() async {
    final state = widget.provider;
    if (state.isCycleMode && state.hasActiveActivity && !state.isBreak) {
      await widget.controller.cancelActivity();
    } else {
      await widget.controller.skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.provider;
    final palette = context.zentraPalette;
    final isBreak = state.isBreak;
    final background =
        isBreak ? ZentraPalette.light.functionalSurface : palette.brandDeep;
    final foreground = isBreak
        ? ZentraPalette.light.brandDeep
        : ZentraPalette.light.functionalSurface;
    final quiet = foreground.withValues(alpha: 0.56);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _offerExit();
      },
      child: ColoredBox(
        key:
            ValueKey(isBreak ? 'focus_rest_immersion' : 'focus_work_immersion'),
        color: background,
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            builder: (context, layout) {
              final horizontal = layout.horizontalPagePadding;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  layout.verticalPagePadding,
                  horizontal,
                  context.spacing.lg,
                ),
                child: Column(
                  key: const ValueKey('focus_session_active'),
                  children: [
                    _FocusTopBar(
                      provider: state,
                      // La sesión corriendo no se titula: el contador es el
                      // héroe y la pantalla ya no es un lanzador.
                      showTitle: false,
                      foreground: foreground,
                      onBack: _offerExit,
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _stageLabel(state),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: quiet,
                                        letterSpacing: 4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                if (isBreak) ...[
                                  SizedBox(height: context.spacing.sm),
                                  Text(
                                    'Suelta los hombros',
                                    key: const ValueKey('focus_rest_headline'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -1,
                                        ),
                                  ),
                                ],
                                SizedBox(height: context.spacing.lg),
                                _SilenceTimer(
                                  provider: state,
                                  foreground: foreground,
                                  quiet: quiet,
                                ),
                                SizedBox(height: context.spacing.lg),
                                Text(
                                  _nextLabel(state),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: quiet,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                                if (_showSessionName(state)) ...[
                                  SizedBox(height: context.spacing.sm),
                                  Text(
                                    state.sessionLabel,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: quiet),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _SilenceControls(
                      provider: state,
                      controller: widget.controller,
                      foreground: foreground,
                      quiet: quiet,
                      onEnd: _confirmEnd,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _stageLabel(PomodoroViewState state) {
    if (state.isBreak) return 'DESCANSO';
    if (!state.isCycleMode) return 'ENFOQUE';
    final current = (state.activityCyclesCompleted + 1).clamp(1, 4);
    return 'ENFOQUE · $current DE 4';
  }

  String _nextLabel(PomodoroViewState state) {
    if (state.isBreak) {
      return 'Después: enfoque ${(state.activityCyclesCompleted + 1).clamp(1, 4)}';
    }
    if (!state.isCycleMode) return 'Después: listo';
    return state.activityCyclesCompleted >= 3
        ? 'Después: descanso largo'
        : 'Después: descanso corto';
  }

  bool _showSessionName(PomodoroViewState state) {
    return state.isBreak ||
        state.sessionLabel != 'Sesión de enfoque' ||
        state.linkedNoteId != null;
  }
}

class _SilenceTimer extends StatefulWidget {
  final PomodoroViewState provider;
  final Color foreground;
  final Color quiet;

  const _SilenceTimer({
    required this.provider,
    required this.foreground,
    required this.quiet,
  });

  @override
  State<_SilenceTimer> createState() => _SilenceTimerState();
}

class _SilenceTimerState extends State<_SilenceTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _SilenceTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final animate = widget.provider.state == PomodoroState.running &&
        context.motionPolicy.allowsDecorativeMotion;
    if (animate && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!animate && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final size = math.min(screenWidth - 64, 350.0).clamp(236.0, 350.0);
    final paused = widget.provider.state == PomodoroState.paused;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final scale = _breath.isAnimating ? 0.995 + _breath.value * 0.01 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox.square(
        dimension: size,
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
                  const Duration(milliseconds: 700),
                ),
                builder: (context, progress, _) => CustomPaint(
                  key: paused
                      ? const ValueKey('focus_pause_gap')
                      : const ValueKey('focus_running_ring'),
                  painter: _SilenceRingPainter(
                    progress: progress,
                    color: widget.foreground,
                    paused: paused,
                  ),
                ),
              ),
            ),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                widget.provider.formattedTime,
                key: const ValueKey('pomodoro_time'),
                semanticsLabel:
                    '${widget.provider.remainingSeconds ~/ 60} minutos y '
                    '${widget.provider.remainingSeconds % 60} segundos',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: widget.foreground,
                  fontSize: size < 290 ? 58 : 76,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SilenceRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool paused;

  const _SilenceRingPainter({
    required this.progress,
    required this.color,
    required this.paused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const start = -math.pi / 2;
    final availableSweep = paused ? math.pi * 1.72 : math.pi * 2;
    canvas.drawArc(rect, start, availableSweep, false, track);
    canvas.drawArc(
      rect,
      start,
      availableSweep * progress.clamp(0, 1),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _SilenceRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.paused != paused;
  }
}

class _SilenceControls extends StatelessWidget {
  final PomodoroViewState provider;
  final PomodoroController controller;
  final Color foreground;
  final Color quiet;
  final VoidCallback onEnd;

  const _SilenceControls({
    required this.provider,
    required this.controller,
    required this.foreground,
    required this.quiet,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final running = provider.state == PomodoroState.running;
    final primaryLabel = running
        ? 'Pausar'
        : provider.state == PomodoroState.paused
            ? 'Continuar'
            : provider.isBreak
                ? 'Iniciar descanso'
                : 'Iniciar enfoque';
    final sideStyle = IconButton.styleFrom(
      foregroundColor: quiet,
      side: BorderSide(color: foreground.withValues(alpha: 0.22)),
      minimumSize: const Size.square(54),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('pomodoro_reset'),
            tooltip: 'Reiniciar etapa',
            style: sideStyle,
            onPressed: controller.reset,
            icon: const Icon(Icons.replay_rounded),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              key: const ValueKey('pomodoro_pause_resume'),
              onPressed: running ? controller.pause : controller.start,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withValues(alpha: 0.28)),
                minimumSize: const Size.fromHeight(56),
              ),
              icon: Icon(
                running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(primaryLabel),
            ),
          ),
          SizedBox(width: context.spacing.sm),
          IconButton.outlined(
            key: const ValueKey('pomodoro_cancel_activity'),
            tooltip: provider.isBreak ? 'Saltar descanso' : 'Terminar enfoque',
            style: sideStyle,
            onPressed: onEnd,
            icon: Icon(
              provider.isBreak ? Icons.skip_next_rounded : Icons.stop_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExitAction { stay, preserve, end }

class _ExitFocusSheet extends StatelessWidget {
  final bool isBreak;

  const _ExitFocusSheet({required this.isBreak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('focus_safe_exit_sheet'),
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
            isBreak ? '¿Salir del descanso?' : '¿Salir del enfoque?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'El temporizador puede continuar mientras usas el resto de Zentra.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ExitAction.stay),
            child: const Text('Seguir aquí'),
          ),
          TextButton(
            key: const ValueKey('focus_exit_preserve'),
            onPressed: () => Navigator.of(context).pop(_ExitAction.preserve),
            child: const Text('Salir y conservar'),
          ),
          TextButton(
            key: const ValueKey('focus_exit_end'),
            onPressed: () => Navigator.of(context).pop(_ExitAction.end),
            style: TextButton.styleFrom(
              foregroundColor: context.zentraPalette.warmPeach,
            ),
            child: const Text('Terminar sesión'),
          ),
        ],
      ),
    );
  }
}

class _EndFocusSheet extends StatelessWidget {
  final bool isBreak;

  const _EndFocusSheet({required this.isBreak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('focus_end_sheet'),
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
            isBreak ? '¿Saltar este descanso?' : '¿Terminar este enfoque?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            isBreak
                ? 'Pasarás a la siguiente etapa.'
                : 'Esta sesión no sumará minutos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isBreak ? 'Seguir descansando' : 'Seguir enfocándome'),
          ),
          TextButton(
            key: const ValueKey('pomodoro_cancel_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.zentraPalette.warmPeach,
            ),
            child: Text(isBreak ? 'Saltar descanso' : 'Terminar sesión'),
          ),
        ],
      ),
    );
  }
}

/// Low-stimulation completion surface used after a quick focus or full cycle.
///
/// It stays public so the visual review harness can render the otherwise
/// time-dependent completion state deterministically.
class FocusCompletionScene extends StatelessWidget {
  final PomodoroActivity activity;
  final VoidCallback onClose;

  const FocusCompletionScene({
    required this.activity,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const palette = ZentraPalette.light;
    final cycle = activity.cyclesCompleted > 1;
    // The closing seal is always a light, low-stimulation surface, even when the
    // app runs in AMOLED. Painting a light background while the ambient theme
    // stays dark is what made the button label and the close icon unreadable:
    // they resolve their foreground from `colorScheme.onPrimary` and
    // `colorScheme.primary`, which in dark mode are near-black ink and mint on
    // cream (1.31:1 and 1.44:1). Imposing the light theme keeps every descendant
    // — including ones added later — consistent with the surface it sits on.
    return Theme(
      data: _lightTheme,
      // Builder, not a direct call: the styles below read `Theme.of(context)`,
      // and the enclosing build context sits *above* the Theme that was just
      // installed. Without a new context they would resolve the ambient dark
      // theme again and the fix would be inert.
      child: Builder(
        builder: (context) => _build(context, palette: palette, cycle: cycle),
      ),
    );
  }

  /// Built once: [AppTheme.lightTheme] assembles a full [ThemeData] on every
  /// call, and this scene rebuilds on each animation tick.
  static final ThemeData _lightTheme = AppTheme.lightTheme;

  Widget _build(
    BuildContext context, {
    required ZentraPalette palette,
    required bool cycle,
  }) {
    return ColoredBox(
      key: const ValueKey('focus_completion_dialog'),
      color: palette.functionalSurface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.outlined(
                  key: const ValueKey('focus_completion_close'),
                  tooltip: 'Cerrar',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 146,
                          height: 146,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.brandDeep,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 64,
                            color: palette.brandDeep,
                          ),
                        ),
                        SizedBox(height: context.spacing.lg),
                        Text(
                          'LISTO',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: palette.inkSecondary,
                                    letterSpacing: 4,
                                  ),
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          cycle ? 'Ciclo completado' : 'Enfoque completado',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -1.5,
                              ),
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          cycle
                              ? '${activity.cyclesCompleted} enfoques · '
                                  '${activity.totalMinutes} minutos'
                              : '${activity.totalMinutes} minutos presentes',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: palette.inkSecondary,
                                  ),
                        ),
                        SizedBox(height: context.spacing.lg),
                        Text(
                          'Una cosa menos en tu cabeza.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: palette.brandDeep,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        SizedBox(height: context.spacing.xl),
                        FilledButton(
                          onPressed: onClose,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.brandDeep,
                            minimumSize: const Size(180, 54),
                          ),
                          child: const Text('Hecho'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  late bool _isCycle;

  @override
  void initState() {
    super.initState();
    _focus = widget.provider.workDuration;
    _shortBreak = widget.provider.shortBreakDuration;
    _longBreak = widget.provider.longBreakDuration;
    // El modo se lee al abrir y no cambia mientras la hoja vive: el selector
    // queda detrás del velo, así que la hoja no puede cambiar de forma sola.
    _isCycle = widget.provider.isCycleMode;
  }

  @override
  Widget build(BuildContext context) {
    final isCycle = _isCycle;
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
            isCycle ? 'Tiempos del ciclo' : 'Tu tiempo de enfoque',
            key: const ValueKey('focus_times_sheet_title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            isCycle
                ? 'Los cambios se aplican a la siguiente etapa.'
                : 'De 5 a 60 minutos.',
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
            divisions: 11,
            color: context.zentraPalette.focus,
            onChanged: (value) {
              final snapped = ((value / 5).round() * 5).clamp(5, 60);
              setState(() => _focus = snapped);
              widget.controller.setWorkDuration(snapped);
            },
          ),
          // Los descansos sólo existen en Ciclo: `startQuickSession` nunca los
          // consume. Mostrarlos en Rápido serían dos controles que no hacen
          // nada, y el usuario no tiene manera de saberlo mirándolos.
          if (isCycle) ...[
            _DurationSetting(
              label: 'Descanso corto',
              value: _shortBreak,
              min: 1,
              max: 15,
              divisions: 14,
              color: context.zentraPalette.water,
              onChanged: (value) {
                setState(() => _shortBreak = value);
                widget.controller.setShortBreakDuration(value);
              },
            ),
            _DurationSetting(
              label: 'Descanso largo',
              value: _longBreak,
              min: 5,
              max: 30,
              divisions: 25,
              color: context.zentraPalette.sleep,
              onChanged: (value) {
                setState(() => _longBreak = value);
                widget.controller.setLongBreakDuration(value);
              },
            ),
          ],
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
  final int divisions;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DurationSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
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
            divisions: divisions,
            activeColor: color,
            label: '$value min',
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}
