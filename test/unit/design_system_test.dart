import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/presentation/design_tokens.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/widgets/responsive_layout.dart';

void main() {
  test('window classes use the shared Material 3 breakpoints', () {
    expect(
      ZentraBreakpoints.windowClassFor(599),
      ZentraWindowClass.compact,
    );
    expect(
      ZentraBreakpoints.windowClassFor(600),
      ZentraWindowClass.medium,
    );
    expect(
      ZentraBreakpoints.windowClassFor(840),
      ZentraWindowClass.expanded,
    );
    expect(
      ZentraBreakpoints.windowClassFor(1200),
      ZentraWindowClass.large,
    );
    expect(
      ZentraBreakpoints.windowClassFor(1600),
      ZentraWindowClass.extraLarge,
    );
  });

  test('themes expose the shared spacing scale', () {
    expect(
      AppTheme.lightTheme.extension<ZentraSpacing>(),
      ZentraSpacing.standard,
    );
    expect(
      AppTheme.darkTheme.extension<ZentraSpacing>(),
      ZentraSpacing.standard,
    );
  });

  test('themes expose Calma precisa radii and semantic palettes', () {
    expect(
      AppTheme.lightTheme.extension<ZentraRadii>(),
      ZentraRadii.standard,
    );
    expect(
      AppTheme.darkTheme.extension<ZentraRadii>(),
      ZentraRadii.standard,
    );
    expect(
      AppTheme.lightTheme.extension<ZentraPalette>(),
      ZentraPalette.light,
    );
    expect(
      AppTheme.darkTheme.extension<ZentraPalette>(),
      ZentraPalette.dark,
    );
  });

  test('Zentra keeps warm light surfaces and a true AMOLED dark canvas', () {
    expect(
      AppTheme.lightTheme.colorScheme.surface,
      const Color(0xFFF8F6F0),
    );
    expect(
      AppTheme.darkTheme.colorScheme.surface,
      Colors.black,
    );
    expect(
      AppTheme.darkTheme.extension<ZentraPalette>()?.functionalSurface,
      Colors.black,
    );
    expect(
      AppTheme.darkTheme.extension<ZentraPalette>()?.salviaFormHeader,
      const Color(0xFF112E28),
    );
  });

  test('dark identity keeps the original cyan coral and amber energy', () {
    final scheme = AppTheme.darkTheme.colorScheme;

    expect(scheme.primary, const Color(0xFF5EECD8));
    expect(scheme.secondary, const Color(0xFFFF6B6B));
    expect(scheme.tertiary, const Color(0xFFFFD93D));
    expect(
      _contrastRatio(scheme.primary, scheme.surface),
      greaterThanOrEqualTo(7),
    );
  });

  test('light primary colors meet normal-text contrast', () {
    final scheme = AppTheme.lightTheme.colorScheme;

    expect(
      _contrastRatio(scheme.primary, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.onPrimary, scheme.primary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('light category header tints preserve readable text contrast', () {
    final foreground = AppTheme.lightTheme.colorScheme.onSurface;

    for (final category in Category.values) {
      final tint = AppTheme.getCategoryTint(category, Brightness.light);
      expect(
        _contrastRatio(foreground, tint),
        greaterThanOrEqualTo(4.5),
        reason: '${category.name} must keep normal text readable',
      );
    }
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
