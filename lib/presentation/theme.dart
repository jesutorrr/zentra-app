import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'design_tokens.dart';

// ============================================================================
// COLOR EXTENSIONS - Usa withValues() para evitar pérdida de precisión
// ============================================================================

/// Extension for color opacity helpers using the new withValues API
extension ColorOpacity on Color {
  /// Returns color with specified alpha (0.0 to 1.0)
  Color withAlphaValue(double alpha) {
    return withValues(alpha: alpha);
  }

  /// Common opacity presets for consistency
  Color get opacity10 => withValues(alpha: 0.1);
  Color get opacity15 => withValues(alpha: 0.15);
  Color get opacity20 => withValues(alpha: 0.2);
  Color get opacity30 => withValues(alpha: 0.3);
  Color get opacity40 => withValues(alpha: 0.4);
  Color get opacity50 => withValues(alpha: 0.5);
  Color get opacity60 => withValues(alpha: 0.6);
  Color get opacity70 => withValues(alpha: 0.7);
  Color get opacity80 => withValues(alpha: 0.8);
}

/// Material 3 theme for the Calma precisa design language.
class AppTheme {
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color successGreen = Color(0xFF43A047);

  static const Color _primaryDark = Color(0xFF5EECD8);
  static const Color _secondaryDark = Color(0xFFFF6B6B);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryDark,
      onPrimary: Color(0xFF001F1B),
      primaryContainer: Color(0xFF063A32),
      onPrimaryContainer: Color(0xFFB9FFF4),
      secondary: _secondaryDark,
      onSecondary: Color(0xFF260000),
      secondaryContainer: Color(0xFF4A1014),
      onSecondaryContainer: Color(0xFFFFDADA),
      tertiary: Color(0xFFFFD93D),
      onTertiary: Color(0xFF241A00),
      tertiaryContainer: Color(0xFF493C00),
      onTertiaryContainer: Color(0xFFFFEEA6),
      error: Color(0xFFFF5252),
      onError: Color(0xFF260000),
      errorContainer: Color(0xFF4D0004),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF050807),
      surfaceContainer: Color(0xFF090D0C),
      surfaceContainerHigh: Color(0xFF0F1513),
      surfaceContainerHighest: Color(0xFF151D1A),
      onSurfaceVariant: Color(0xFFB8C4C1),
      outline: Color(0xFF65736F),
      outlineVariant: Color(0xFF202725),
      inverseSurface: Color(0xFFF4F7F6),
      onInverseSurface: Color(0xFF101413),
      inversePrimary: Color(0xFF00796B),
      shadow: Color(0xFF000000),
      scrim: Color(0xB3000000),
      surfaceTint: _primaryDark,
    );

    return _buildTheme(colorScheme, ZentraPalette.dark);
  }

  static const Color _primaryLight = Color(0xFF00796B);
  static const Color _secondaryLight = Color(0xFFD94747);

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryLight,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD8F3ED),
      onPrimaryContainer: Color(0xFF004D43),
      secondary: _secondaryLight,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDADA),
      onSecondaryContainer: Color(0xFF7A181D),
      tertiary: Color(0xFF9A6500),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFE7A5),
      onTertiaryContainer: Color(0xFF5D3B00),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F6F0),
      onSurface: Color(0xFF1B2523),
      surfaceContainerLowest: Color(0xFFFFFEFB),
      surfaceContainerLow: Color(0xFFF4F3ED),
      surfaceContainer: Color(0xFFEFEEE8),
      surfaceContainerHigh: Color(0xFFE9E8E2),
      surfaceContainerHighest: Color(0xFFE3E2DC),
      onSurfaceVariant: Color(0xFF5C6865),
      outline: Color(0xFF7B8985),
      outlineVariant: Color(0xFFCED8D4),
      inverseSurface: Color(0xFF2D3533),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF9DD8CF),
      shadow: Color(0x260D1C19),
      scrim: Color(0x660D1C19),
      surfaceTint: _primaryLight,
    );

    return _buildTheme(colorScheme, ZentraPalette.light);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    ZentraPalette palette,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = baseTextTheme.apply(fontFamily: 'Inter').copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 64,
            fontWeight: FontWeight.w700,
            height: 1.04,
            letterSpacing: -2.0,
            color: colorScheme.onSurface,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.06,
            letterSpacing: -1.5,
            color: colorScheme.onSurface,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.08,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.14,
            letterSpacing: -0.3,
            color: colorScheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.16,
            color: colorScheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: colorScheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.1,
            color: colorScheme.onSurface,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.1,
            color: colorScheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: colorScheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: colorScheme.onSurface,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: colorScheme.onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.1,
            color: colorScheme.onSurface,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.5,
            color: colorScheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.5,
            color: colorScheme.onSurfaceVariant,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        ZentraSpacing.standard,
        ZentraRadii.standard,
        palette,
      ],

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: palette.functionalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.large),
          side: BorderSide(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.22)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.pill),
        ),
        side: BorderSide.none,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.opacity70),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isDark ? 5 : 1,
        focusElevation: isDark ? 7 : 2,
        hoverElevation: isDark ? 7 : 2,
        highlightElevation: isDark ? 3 : 0,
        splashColor: colorScheme.secondary.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            return isDark ? 4 : 1;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant;
            }
            return colorScheme.onPrimary;
          }),
          shadowColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: isDark ? 0.55 : 0.20),
          ),
          overlayColor: WidgetStatePropertyAll(
            colorScheme.secondary.withValues(alpha: 0.16),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ZentraRadii.standard.medium,
              ),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: isDark ? 4 : 1,
          shadowColor:
              colorScheme.primary.withValues(alpha: isDark ? 0.55 : 0.20),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          overlayColor: colorScheme.secondary.withValues(alpha: 0.16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
          ),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.72 : 0.58),
            width: 1.25,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZentraRadii.standard.small),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.opacity20,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.functionalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.large),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        elevation: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.functionalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ZentraRadii.standard.large),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZentraRadii.standard.medium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.opacity30;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static Color getCategoryColor(Category category, ColorScheme colorScheme) {
    final palette = colorScheme.brightness == Brightness.dark
        ? ZentraPalette.dark
        : ZentraPalette.light;
    switch (category) {
      case Category.agua:
        return palette.water;
      case Category.movimiento:
        return palette.movement;
      case Category.sueno:
        return palette.sleep;
      case Category.foco:
        return palette.focus;
      case Category.varios:
        return palette.various;
    }
  }

  static Color getCategoryTint(Category category, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (category) {
      case Category.agua:
        return isDark ? const Color(0xFF0D1F33) : const Color(0xFFE8F0FA);
      case Category.movimiento:
        return isDark ? const Color(0xFF2B1A0E) : const Color(0xFFFBE9E2);
      case Category.sueno:
        return isDark ? const Color(0xFF24192E) : const Color(0xFFEEE8F8);
      case Category.foco:
        return isDark ? const Color(0xFF0E2B1E) : const Color(0xFFE6F2EA);
      case Category.varios:
        return isDark ? const Color(0xFF162126) : const Color(0xFFEBEEF0);
    }
  }

  static Color getSalviaCategoryColor(
    Category category,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    switch (category) {
      case Category.agua:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
      case Category.movimiento:
        return isDark ? const Color(0xFFFF9E6D) : const Color(0xFFE64A19);
      case Category.sueno:
        return isDark ? const Color(0xFFC79DFF) : const Color(0xFF7251B5);
      case Category.foco:
        return isDark ? const Color(0xFF66E09A) : const Color(0xFF257A48);
      case Category.varios:
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A);
    }
  }

  static Color getSalviaNoteColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFE95656);
  }

  // Category icons
  static IconData getCategoryIcon(Category category) {
    switch (category) {
      case Category.agua:
        return Icons.water_drop_rounded;
      case Category.movimiento:
        return Icons.directions_run_rounded;
      case Category.sueno:
        return Icons.bedtime_rounded;
      case Category.foco:
        return Icons.psychology_rounded;
      case Category.varios:
        return Icons.dashboard_rounded;
    }
  }

  static LinearGradient cardGradient(ColorScheme colorScheme, bool isDark) {
    final palette = isDark ? ZentraPalette.dark : ZentraPalette.light;
    return LinearGradient(
      colors: isDark
          ? [
              palette.calmMint,
              palette.specialSurface,
            ]
          : [colorScheme.primaryContainer, palette.specialSurface],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Border? cardGradientBorder(ColorScheme colorScheme, bool isDark) {
    return Border.all(color: colorScheme.outlineVariant);
  }

  static List<BoxShadow>? cardShadow(ColorScheme colorScheme, bool isDark) {
    return isDark
        ? null
        : [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ];
  }

  static List<BoxShadow> oledGlow(Color color, {double intensity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ];
  }

  static LinearGradient oledCardGradient(ColorScheme colorScheme) {
    return LinearGradient(
      colors: [
        colorScheme.primary.opacity10,
        colorScheme.secondary.opacity10,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static bool isOledTheme(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark;
  }

  static bool isOledWhiteTheme(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.light;
  }

  static bool isAnyOledTheme(ColorScheme colorScheme) {
    return isOledTheme(colorScheme) || isOledWhiteTheme(colorScheme);
  }

  static Color getContainerColor(ColorScheme colorScheme, bool isDark) {
    return isDark
        ? ZentraPalette.dark.functionalSurface
        : ZentraPalette.light.functionalSurface;
  }

  static BoxDecoration getContainerDecoration(
    ColorScheme colorScheme,
    bool isDark, {
    double borderRadius = 16,
    Color? borderColor,
  }) {
    final bgColor = getContainerColor(colorScheme, isDark);

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? colorScheme.outlineVariant,
        width: 1,
      ),
    );
  }
}
