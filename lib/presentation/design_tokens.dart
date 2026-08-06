import 'package:flutter/material.dart';

@immutable
class ZentraSpacing extends ThemeExtension<ZentraSpacing> {
  static const standard = ZentraSpacing();

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const ZentraSpacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  @override
  ZentraSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return ZentraSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  ZentraSpacing lerp(covariant ZentraSpacing? other, double t) {
    if (other == null) return this;
    return ZentraSpacing(
      xxs: _lerpDouble(xxs, other.xxs, t),
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
      xxl: _lerpDouble(xxl, other.xxl, t),
    );
  }

  static double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

@immutable
class ZentraRadii extends ThemeExtension<ZentraRadii> {
  static const standard = ZentraRadii();

  final double small;
  final double medium;
  final double large;
  final double extraLarge;
  final double pill;

  const ZentraRadii({
    this.small = 12,
    this.medium = 18,
    this.large = 24,
    this.extraLarge = 32,
    this.pill = 999,
  });

  @override
  ZentraRadii copyWith({
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
    double? pill,
  }) {
    return ZentraRadii(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
      pill: pill ?? this.pill,
    );
  }

  @override
  ZentraRadii lerp(covariant ZentraRadii? other, double t) {
    if (other == null) return this;
    return ZentraRadii(
      small: _lerpDouble(small, other.small, t),
      medium: _lerpDouble(medium, other.medium, t),
      large: _lerpDouble(large, other.large, t),
      extraLarge: _lerpDouble(extraLarge, other.extraLarge, t),
      pill: _lerpDouble(pill, other.pill, t),
    );
  }

  static double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

@immutable
class ZentraPalette extends ThemeExtension<ZentraPalette> {
  static const light = ZentraPalette(
    backgroundTop: Color(0xFFF0F7F3),
    surfaceCard: Color(0xFFFFFFFF),
    progressTrack: Color(0xFFEDF3EF),
    inkSecondary: Color(0xFF5C6865),
    inkTertiary: Color(0xFF77827E),
    inkMuted: Color(0xFF9A9890),
    inkDisabled: Color(0xFFB4B1A6),
    brandDeep: Color(0xFF10362C),
    tealTint: Color(0xFFDCEDE6),
    tealSoft: Color(0xFFA8DCC6),
    checkBorder: Color(0xFFDAD7CC),
    brandTeal: Color(0xFF00796B),
    warmPeach: Color(0xFFE95656),
    calmMint: Color(0xFFD8F3ED),
    ink: Color(0xFF1B2523),
    water: Color(0xFF1976D2),
    movement: Color(0xFFE64A19),
    sleep: Color(0xFF7251B5),
    focus: Color(0xFF257A48),
    various: Color(0xFF546E7A),
    functionalSurface: Color(0xFFFFFEFB),
    specialSurface: Color(0xFFFFF0EC),
    // The same teal as `brandTeal` and the save button, not a tint of it. The
    // band used to be a pale #DCEDE6 that read as almost-white and left the top
    // of the creation screens without a voice. Solid, it says the brand once and
    // stops — which is why everything sitting on it inverts to light: see
    // ZentraModeBand for the ratios that force that.
    salviaFormHeader: Color(0xFF00796B),
  );

  static const dark = ZentraPalette(
    backgroundTop: Color(0xFF000000),
    surfaceCard: Color(0xFF101514),
    progressTrack: Color(0xFF15201E),
    inkSecondary: Color(0xFF8C9793),
    inkTertiary: Color(0xFF6E7A76),
    inkMuted: Color(0xFF8C9793),
    inkDisabled: Color(0xFF5A6662),
    brandDeep: Color(0xFF0E2B25),
    tealTint: Color(0xFF0E2B25),
    tealSoft: Color(0xFF5EECD8),
    checkBorder: Color(0xFF2A3330),
    brandTeal: Color(0xFF5EECD8),
    warmPeach: Color(0xFFFF6B6B),
    calmMint: Color(0xFF063A32),
    ink: Color(0xFFFFFFFF),
    water: Color(0xFF29B6F6),
    movement: Color(0xFFFF7043),
    sleep: Color(0xFFC77DFF),
    focus: Color(0xFF66E09A),
    various: Color(0xFF90A4AE),
    functionalSurface: Color(0xFF000000),
    specialSurface: Color(0xFF1A0B0D),
    salviaFormHeader: Color(0xFF112E28),
  );

  final Color brandTeal;
  final Color backgroundTop;
  final Color surfaceCard;
  final Color progressTrack;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color inkMuted;
  final Color inkDisabled;
  final Color brandDeep;
  final Color tealTint;
  final Color tealSoft;
  final Color checkBorder;
  final Color warmPeach;
  final Color calmMint;
  final Color ink;
  final Color water;
  final Color movement;
  final Color sleep;
  final Color focus;
  final Color various;
  final Color functionalSurface;
  final Color specialSurface;
  final Color salviaFormHeader;

  const ZentraPalette({
    required this.backgroundTop,
    required this.surfaceCard,
    required this.progressTrack,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkMuted,
    required this.inkDisabled,
    required this.brandDeep,
    required this.tealTint,
    required this.tealSoft,
    required this.checkBorder,
    required this.brandTeal,
    required this.warmPeach,
    required this.calmMint,
    required this.ink,
    required this.water,
    required this.movement,
    required this.sleep,
    required this.focus,
    required this.various,
    required this.functionalSurface,
    required this.specialSurface,
    required this.salviaFormHeader,
  });

  @override
  ZentraPalette copyWith({
    Color? backgroundTop,
    Color? surfaceCard,
    Color? progressTrack,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? inkMuted,
    Color? inkDisabled,
    Color? brandDeep,
    Color? tealTint,
    Color? tealSoft,
    Color? checkBorder,
    Color? brandTeal,
    Color? warmPeach,
    Color? calmMint,
    Color? ink,
    Color? water,
    Color? movement,
    Color? sleep,
    Color? focus,
    Color? various,
    Color? functionalSurface,
    Color? specialSurface,
    Color? salviaFormHeader,
  }) {
    return ZentraPalette(
      backgroundTop: backgroundTop ?? this.backgroundTop,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      progressTrack: progressTrack ?? this.progressTrack,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      inkMuted: inkMuted ?? this.inkMuted,
      inkDisabled: inkDisabled ?? this.inkDisabled,
      brandDeep: brandDeep ?? this.brandDeep,
      tealTint: tealTint ?? this.tealTint,
      tealSoft: tealSoft ?? this.tealSoft,
      checkBorder: checkBorder ?? this.checkBorder,
      brandTeal: brandTeal ?? this.brandTeal,
      warmPeach: warmPeach ?? this.warmPeach,
      calmMint: calmMint ?? this.calmMint,
      ink: ink ?? this.ink,
      water: water ?? this.water,
      movement: movement ?? this.movement,
      sleep: sleep ?? this.sleep,
      focus: focus ?? this.focus,
      various: various ?? this.various,
      functionalSurface: functionalSurface ?? this.functionalSurface,
      specialSurface: specialSurface ?? this.specialSurface,
      salviaFormHeader: salviaFormHeader ?? this.salviaFormHeader,
    );
  }

  @override
  ZentraPalette lerp(covariant ZentraPalette? other, double t) {
    if (other == null) return this;
    return ZentraPalette(
      backgroundTop:
          Color.lerp(backgroundTop, other.backgroundTop, t) ?? backgroundTop,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t) ?? surfaceCard,
      progressTrack:
          Color.lerp(progressTrack, other.progressTrack, t) ?? progressTrack,
      inkSecondary:
          Color.lerp(inkSecondary, other.inkSecondary, t) ?? inkSecondary,
      inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t) ?? inkTertiary,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t) ?? inkMuted,
      inkDisabled: Color.lerp(inkDisabled, other.inkDisabled, t) ?? inkDisabled,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t) ?? brandDeep,
      tealTint: Color.lerp(tealTint, other.tealTint, t) ?? tealTint,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t) ?? tealSoft,
      checkBorder: Color.lerp(checkBorder, other.checkBorder, t) ?? checkBorder,
      brandTeal: Color.lerp(brandTeal, other.brandTeal, t) ?? brandTeal,
      warmPeach: Color.lerp(warmPeach, other.warmPeach, t) ?? warmPeach,
      calmMint: Color.lerp(calmMint, other.calmMint, t) ?? calmMint,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      water: Color.lerp(water, other.water, t) ?? water,
      movement: Color.lerp(movement, other.movement, t) ?? movement,
      sleep: Color.lerp(sleep, other.sleep, t) ?? sleep,
      focus: Color.lerp(focus, other.focus, t) ?? focus,
      various: Color.lerp(various, other.various, t) ?? various,
      functionalSurface:
          Color.lerp(functionalSurface, other.functionalSurface, t) ??
              functionalSurface,
      specialSurface:
          Color.lerp(specialSurface, other.specialSurface, t) ?? specialSurface,
      salviaFormHeader:
          Color.lerp(salviaFormHeader, other.salviaFormHeader, t) ??
              salviaFormHeader,
    );
  }
}

extension ZentraThemeContext on BuildContext {
  ZentraSpacing get spacing =>
      Theme.of(this).extension<ZentraSpacing>() ?? ZentraSpacing.standard;

  ZentraRadii get radii =>
      Theme.of(this).extension<ZentraRadii>() ?? ZentraRadii.standard;

  ZentraPalette get zentraPalette {
    final fallback = Theme.of(this).brightness == Brightness.dark
        ? ZentraPalette.dark
        : ZentraPalette.light;
    return Theme.of(this).extension<ZentraPalette>() ?? fallback;
  }
}
