import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/models.dart';

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

/// App theme configuration using Material 3
/// Nueva paleta: Teal/Mint moderno con acentos cálidos
class AppTheme {
  // Colores de acento (usados en toda la app)
  static const Color accentOrange = Color(0xFFFF7043); // Deep Orange 400
  static const Color accentAmber = Color(0xFFFFB300);  // Amber 600
  static const Color successGreen = Color(0xFF66BB6A); // Green 400

  // ============ DARK THEME (OLED) - Negro Puro Minimalista ============
  // Colores vibrantes que resaltan en negro puro
  static const Color _primaryDark = Color(0xFF5EECD8);  // Cyan vibrante
  static const Color _secondaryDark = Color(0xFFFF6B6B); // Coral neón
  
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary - Cyan vibrante que resalta en negro
      primary: _primaryDark,
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF004D44),
      onPrimaryContainer: _primaryDark,
      // Secondary - Coral neón
      secondary: _secondaryDark,
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF5C1A1A),
      onSecondaryContainer: Color(0xFFFFB3B3),
      // Tertiary - Amber brillante
      tertiary: Color(0xFFFFD93D),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFF5C4A00),
      onTertiaryContainer: Color(0xFFFFE57F),
      // Error - Rojo neón
      error: Color(0xFFFF5252),
      onError: Color(0xFF000000),
      errorContainer: Color(0xFF5C0000),
      onErrorContainer: Color(0xFFFFB3B3),
      // Surface - NEGRO PURO OLED
      surface: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFF0D0D0D),
      onSurfaceVariant: Color(0xFF888888),
      // Outline - Muy sutil
      outline: Color(0xFF333333),
      outlineVariant: Color(0xFF1A1A1A),
      // Inverse
      inverseSurface: Color(0xFFFFFFFF),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF00897B),
      // Shadow
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: _primaryDark,
    );

    return _buildOledTheme(colorScheme);
  }

  // ============ LIGHT THEME - Blanco Puro Minimalista ============
  // Mismo diseño que Dark pero con colores invertidos (blanco puro)
  static const Color _primaryLight = Color(0xFF00897B);  // Teal oscuro para contraste en blanco
  static const Color _secondaryLight = Color(0xFFFF5252); // Coral
  
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary - Teal que resalta en blanco
      primary: _primaryLight,
      onPrimary: Color(0xFFFFFFFF), // Blanco sobre teal
      primaryContainer: Color(0xFFE0F2F1),
      onPrimaryContainer: _primaryLight,
      // Secondary - Coral
      secondary: _secondaryLight,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFEBEE),
      onSecondaryContainer: Color(0xFFD32F2F),
      // Tertiary - Amber
      tertiary: Color(0xFFFFB300),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFFFFF8E1),
      onTertiaryContainer: Color(0xFFFF8F00),
      // Error - Rojo
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      // Surface - BLANCO PURO
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      surfaceContainerHighest: Color(0xFFF5F5F5),
      onSurfaceVariant: Color(0xFF666666),
      // Outline - Sutil gris claro
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFF0F0F0),
      // Inverse
      inverseSurface: Color(0xFF121212),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF5EECD8),
      // Shadow
      shadow: Color(0x1A000000),
      scrim: Color(0x1A000000),
      surfaceTint: _primaryLight,
    );

    // Reutilizar el builder con el colorScheme de blanco
    return _buildOledTheme(colorScheme);
  }

  // ============ BUILD OLED THEME ============
  static ThemeData _buildOledTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.robotoTextTheme(baseTextTheme).copyWith(
      // Display - Números grandes con peso ligero para OLED
      displayLarge: GoogleFonts.roboto(
        fontSize: 64,
        fontWeight: FontWeight.w200, // Thin - se ve increíble en OLED
        letterSpacing: -2.0,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      // Headlines - Bold para contraste
      headlineLarge: GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      // Titles
      titleLarge: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      // Body
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      // Labels
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // Scaffold - Negro puro
      scaffoldBackgroundColor: colorScheme.surface,
      
      // AppBar - Transparente, se funde con el fondo
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards - Fondo puro (negro OLED o blanco OLED White) con borde iluminado sutil
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: isDark ? Colors.black : Colors.white, // Negro o blanco puro según tema
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2), // Borde iluminado
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips - Minimalistas
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.opacity20,
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // Input - Bordes sutiles
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.opacity50),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // FAB - Con glow sutil
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button - Flat con color
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button - Borde sutil
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Slider - Delgado y elegante
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.opacity20,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // Dialog - Fondo puro según tema
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1,
          ),
        ),
        elevation: 0,
      ),

      // Bottom Sheet - Fondo puro según tema
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1,
          ),
        ),
        elevation: 0,
      ),

      // Divider - Muy sutil
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 4,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: GoogleFonts.roboto(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Switch
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

      // Checkbox
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


  // ============ CATEGORY COLORS ============
  // Colores más vibrantes para categorías
  static Color getCategoryColor(Category category, ColorScheme colorScheme) {
    switch (category) {
      case Category.agua:
        return const Color(0xFF29B6F6); // Light Blue 400
      case Category.movimiento:
        return const Color(0xFFFF7043); // Deep Orange 400
      case Category.sueno:
        return const Color(0xFFAB47BC); // Purple 400
      case Category.foco:
        return const Color(0xFF66BB6A); // Green 400
      case Category.varios:
        return const Color(0xFF78909C); // Blue Grey 400
    }
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

  // ============ GRADIENT HELPERS ============
  
  /// Standard card gradient for highlighted cards
  /// Used in profile headers, stats cards, summary cards
  static LinearGradient cardGradient(ColorScheme colorScheme, bool isDark) {
    return LinearGradient(
      colors: isDark
          ? [colorScheme.primary.opacity30, colorScheme.secondary.opacity20]
          : [colorScheme.primaryContainer, colorScheme.secondaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Border for gradient cards in dark mode
  static Border? cardGradientBorder(ColorScheme colorScheme, bool isDark) {
    return isDark 
        ? Border.all(color: colorScheme.primary.opacity30)
        : null;
  }

  /// Soft shadow for light mode cards
  static List<BoxShadow>? cardShadow(ColorScheme colorScheme, bool isDark) {
    return isDark 
        ? null 
        : [
            BoxShadow(
              color: colorScheme.primary.opacity10,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ];
  }

  // ============ OLED SPECIFIC HELPERS ============
  
  /// Glow effect for interactive elements in OLED mode
  /// Creates a subtle colored glow that looks amazing on black backgrounds
  static List<BoxShadow> oledGlow(Color color, {double intensity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ];
  }

  /// Gradient for OLED cards - very subtle, almost invisible
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

  /// Check if current theme is dark mode (surface is pure black)
  /// Ahora siempre true para dark theme ya que es OLED por defecto
  static bool isOledTheme(ColorScheme colorScheme) {
    return colorScheme.surface == const Color(0xFF000000);
  }

  /// Check if current theme is light mode (surface is pure white)
  /// Ahora siempre true para light theme ya que es OLED White por defecto
  static bool isOledWhiteTheme(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.light && 
           colorScheme.surface == const Color(0xFFFFFFFF);
  }

  /// Check if either theme is active (siempre true ahora)
  static bool isAnyOledTheme(ColorScheme colorScheme) {
    return isOledTheme(colorScheme) || isOledWhiteTheme(colorScheme);
  }

  /// Get container/card background color
  /// Returns pure black for dark, pure white for light
  static Color getContainerColor(ColorScheme colorScheme, bool isDark) {
    return isDark ? Colors.black : Colors.white;
  }

  /// Get container decoration
  /// Dark: black bg + illuminated border
  /// Light: white bg + subtle border
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
        color: borderColor ?? colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        width: 1,
      ),
    );
  }
}
