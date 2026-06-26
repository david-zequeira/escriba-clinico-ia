import 'package:flutter/material.dart';

/// Tokens semánticos de color/elevación de Vionix.
///
/// Viven como [ThemeExtension] para que cambien automáticamente (y se animen)
/// al alternar entre tema claro y oscuro. Accede a ellos con `context.tokens`.
@immutable
class VionixTokens extends ThemeExtension<VionixTokens> {
  const VionixTokens({
    required this.brightness,
    required this.background,
    required this.backgroundElevated,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderSubtle,
    required this.primary,
    required this.primarySoft,
    required this.primaryDark,
    required this.info,
    required this.infoSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.admission,
    required this.admissionSoft,
    required this.treatment,
    required this.treatmentSoft,
    required this.evolution,
    required this.evolutionSoft,
    required this.shadow,
    required this.scrimGradient,
  });

  final Brightness brightness;

  // Superficies
  final Color background;
  final Color backgroundElevated;
  final Color surfaceMuted;

  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Bordes
  final Color border;
  final Color borderSubtle;

  // Marca
  final Color primary;
  final Color primarySoft;
  final Color primaryDark;

  // Estados
  final Color info;
  final Color infoSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;

  // Acentos por tipo de documento
  final Color admission;
  final Color admissionSoft;
  final Color treatment;
  final Color treatmentSoft;
  final Color evolution;
  final Color evolutionSoft;

  // Elevación / fondos
  final Color shadow;

  /// Gradiente sutil de fondo de pantalla (3 paradas).
  final List<Color> scrimGradient;

  bool get isDark => brightness == Brightness.dark;

  /// Acento + su variante suave según un identificador de tipo de documento.
  ({Color accent, Color soft}) accentFor(String typeKey) => switch (typeKey) {
        'treatment_orders' => (accent: treatment, soft: treatmentSoft),
        'evolution' => (accent: evolution, soft: evolutionSoft),
        _ => (accent: admission, soft: admissionSoft),
      };

  static const VionixTokens light = VionixTokens(
    brightness: Brightness.light,
    background: Color(0xFFF4F7FB),
    backgroundElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF8FAFC),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    borderSubtle: Color(0xFFF1F5F9),
    primary: Color(0xFF0D9488),
    primarySoft: Color(0xFFCCFBF1),
    primaryDark: Color(0xFF0F766E),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0xFFEFF6FF),
    success: Color(0xFF10B981),
    successSoft: Color(0xFFECFDF5),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFFFBEB),
    error: Color(0xFFEF4444),
    errorSoft: Color(0xFFFEF2F2),
    admission: Color(0xFF3B82F6),
    admissionSoft: Color(0xFFEFF6FF),
    treatment: Color(0xFF8B5CF6),
    treatmentSoft: Color(0xFFF5F3FF),
    evolution: Color(0xFF10B981),
    evolutionSoft: Color(0xFFECFDF5),
    shadow: Color(0x140F172A),
    scrimGradient: [Color(0xFFF8FAFC), Color(0xFFF4F7FB), Color(0xFFEFF6FF)],
  );

  static const VionixTokens dark = VionixTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0B1120),
    backgroundElevated: Color(0xFF131A2A),
    surfaceMuted: Color(0xFF1B2335),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    border: Color(0xFF243049),
    borderSubtle: Color(0xFF1B2335),
    primary: Color(0xFF2DD4BF),
    primarySoft: Color(0xFF134E4A),
    primaryDark: Color(0xFF14B8A6),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0xFF172554),
    success: Color(0xFF34D399),
    successSoft: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF422006),
    error: Color(0xFFF87171),
    errorSoft: Color(0xFF450A0A),
    admission: Color(0xFF60A5FA),
    admissionSoft: Color(0xFF172554),
    treatment: Color(0xFFA78BFA),
    treatmentSoft: Color(0xFF2E1065),
    evolution: Color(0xFF34D399),
    evolutionSoft: Color(0xFF064E3B),
    shadow: Color(0x66000000),
    scrimGradient: [Color(0xFF0B1120), Color(0xFF0B1120), Color(0xFF111A2E)],
  );

  @override
  VionixTokens copyWith({
    Brightness? brightness,
    Color? background,
    Color? backgroundElevated,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderSubtle,
    Color? primary,
    Color? primarySoft,
    Color? primaryDark,
    Color? info,
    Color? infoSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? admission,
    Color? admissionSoft,
    Color? treatment,
    Color? treatmentSoft,
    Color? evolution,
    Color? evolutionSoft,
    Color? shadow,
    List<Color>? scrimGradient,
  }) {
    return VionixTokens(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryDark: primaryDark ?? this.primaryDark,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      admission: admission ?? this.admission,
      admissionSoft: admissionSoft ?? this.admissionSoft,
      treatment: treatment ?? this.treatment,
      treatmentSoft: treatmentSoft ?? this.treatmentSoft,
      evolution: evolution ?? this.evolution,
      evolutionSoft: evolutionSoft ?? this.evolutionSoft,
      shadow: shadow ?? this.shadow,
      scrimGradient: scrimGradient ?? this.scrimGradient,
    );
  }

  @override
  VionixTokens lerp(ThemeExtension<VionixTokens>? other, double t) {
    if (other is! VionixTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return VionixTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      backgroundElevated: c(backgroundElevated, other.backgroundElevated),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      primary: c(primary, other.primary),
      primarySoft: c(primarySoft, other.primarySoft),
      primaryDark: c(primaryDark, other.primaryDark),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      error: c(error, other.error),
      errorSoft: c(errorSoft, other.errorSoft),
      admission: c(admission, other.admission),
      admissionSoft: c(admissionSoft, other.admissionSoft),
      treatment: c(treatment, other.treatment),
      treatmentSoft: c(treatmentSoft, other.treatmentSoft),
      evolution: c(evolution, other.evolution),
      evolutionSoft: c(evolutionSoft, other.evolutionSoft),
      shadow: c(shadow, other.shadow),
      scrimGradient: [
        for (var i = 0; i < scrimGradient.length; i++)
          c(scrimGradient[i], other.scrimGradient[i]),
      ],
    );
  }
}

/// Escala de espaciado (4pt) — constante entre temas.
abstract final class VionixSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radios de esquina — constantes entre temas.
abstract final class VionixRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Acceso ergonómico a los tokens y al esquema de color desde el contexto.
extension VionixThemeX on BuildContext {
  VionixTokens get tokens =>
      Theme.of(this).extension<VionixTokens>() ?? VionixTokens.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
