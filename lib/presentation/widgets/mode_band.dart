import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_tokens.dart';
import '../motion_policy.dart';
import '../utils/feedback_utils.dart';

/// The band that opens a creation screen, and the two-way selector inside it.
///
/// «Nuevo hábito» and «Nuevo enfoque» ask the same question in the same place —
/// does this repeat, is this a cycle — so they ask it with the same object. This
/// lives in one file on purpose: the two screens looked alike once before and
/// drifted apart on four separate axes (radius, rail colour, how the halves
/// share width, how the active pill is filled), because looking alike was all
/// that held them together. A shared widget cannot drift.
///
/// In light mode the band is solid [ZentraPalette.brandTeal]. That is the
/// loudest surface on either screen, and it forces every choice below:
///
/// | on the band #00796B          | ratio  |
/// |------------------------------|--------|
/// | `ink` #1B2523                | 2.96 ✗ |
/// | `inkSecondary`               | 1.09 ✗ |
/// | white                        | 5.32 ✓ |
///
/// So the band's contents invert to light rather than inheriting the page's
/// ink. The rail has to darken for the same reason: white at 55% composites to
/// #8CC3BC over teal and leaves its own label at 1.97:1, while black at 14%
/// gives #00685C and 6.70:1.
class ZentraModeBand extends StatelessWidget {
  /// Painted behind [child]; also what [ZentraModeSelector] measures against.
  static Color backgroundOf(BuildContext context) =>
      context.zentraPalette.salviaFormHeader;

  /// The colour text and icons must use to sit on [backgroundOf].
  static Color foregroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? context.zentraPalette.ink
          : Colors.white;

  /// The band is the topmost surface and, in light mode, a dark one. Without
  /// this the status bar keeps its dark glyphs and they vanish into the teal.
  static SystemUiOverlayStyle overlayOf(BuildContext context) =>
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      );

  final Widget child;

  const ZentraModeBand({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayOf(context),
      child: AnimatedContainer(
        key: const ValueKey('zentra-mode-band'),
        duration: context.motionPolicy.duration(
          const Duration(milliseconds: 240),
        ),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: backgroundOf(context)),
        // The colour runs to the physical top edge and the SafeArea lives
        // *inside* it, so the notch pushes the content down without leaving a
        // cream strip above the teal. With the inset applied outside, the band
        // read as a floating rectangle instead of the top of the screen.
        child: SafeArea(bottom: false, child: child),
      ),
    );
  }
}

/// One option in a [ZentraModeSelector].
class ZentraModeOption {
  final Key key;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ZentraModeOption({
    required this.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// «Se repite / Una sola vez» and «Rápido / Ciclo»: the same control.
///
/// The halves share the width through [Expanded] instead of sizing to their
/// labels, so the selector does not change shape when the words do — and at
/// large text scales it stacks rather than squeezing.
class ZentraModeSelector extends StatelessWidget {
  final List<ZentraModeOption> options;

  const ZentraModeSelector({required this.options, super.key});

  /// Black over the band rather than white: see the ratios on [ZentraModeBand].
  static Color railColorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.42)
          : Colors.black.withValues(alpha: 0.14);

  @override
  Widget build(BuildContext context) {
    final stack = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final pills = [
      for (final option in options)
        _ZentraModePill(key: option.key, option: option),
    ];
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.8,
      child: Material(
        key: const ValueKey('zentra-mode-selector'),
        color: railColorOf(context),
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: stack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: pills,
                )
              : Row(
                  children: [
                    for (final pill in pills) Expanded(child: pill),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ZentraModePill extends StatelessWidget {
  final ZentraModeOption option;

  const _ZentraModePill({required this.option, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = context.zentraPalette;
    // A light chip on the teal band, 5.32:1 against it, carrying ink at 15.72:1.
    // Dark mode keeps its mint-on-black pairing, which already measured well.
    final selectedFill = isDark ? palette.tealSoft : palette.surfaceCard;
    final radius = BorderRadius.circular(context.radii.medium - 4);
    return Semantics(
      button: true,
      selected: option.selected,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            triggerHaptic(HapticType.selection);
            option.onTap();
          },
          borderRadius: radius,
          child: AnimatedContainer(
            duration: context.motionPolicy.duration(
              const Duration(milliseconds: 240),
            ),
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
            decoration: BoxDecoration(
              color: option.selected ? selectedFill : Colors.transparent,
              borderRadius: radius,
            ),
            child: Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: option.selected
                    ? isDark
                        ? Colors.black
                        : palette.ink
                    // Not onSurfaceVariant: on the darkened rail that measures
                    // far below 4.5:1. The band's own foreground does not.
                    : ZentraModeBand.foregroundOf(context),
                fontWeight:
                    option.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
