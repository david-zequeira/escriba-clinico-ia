import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'vionix_tokens.dart';
import 'vionix_typography.dart';

/// Temas de Vionix. Ambos comparten el mismo lenguaje visual (tokens + motion)
/// y solo cambian la paleta. Úsalos con `MaterialApp(theme:, darkTheme:, themeMode:)`.
abstract final class AppTheme {
  static ThemeData light() => _build(VionixTokens.light);
  static ThemeData dark() => _build(VionixTokens.dark);

  static ThemeData _build(VionixTokens t) {
    final isDark = t.isDark;
    final textTheme = buildVionixTextTheme(t);

    final base = ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: t.background,
      extensions: <ThemeExtension<dynamic>>[t],
      colorScheme: ColorScheme.fromSeed(
        seedColor: t.primary,
        brightness: t.brightness,
        primary: t.primary,
        onPrimary: isDark ? const Color(0xFF04221F) : Colors.white,
        surface: t.backgroundElevated,
        onSurface: t.textPrimary,
        outline: t.border,
        error: t.error,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: t.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VionixRadii.xl),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceMuted,
        hoverColor: t.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VionixRadii.md),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VionixRadii.md),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VionixRadii.md),
          borderSide: BorderSide(color: t.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: t.textSecondary),
        hintStyle: TextStyle(color: t.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VionixRadii.md)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VionixRadii.md)),
          side: BorderSide(color: t.border),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: t.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VionixRadii.md)),
        backgroundColor: isDark ? t.surfaceMuted : t.textPrimary,
        contentTextStyle: TextStyle(
          color: isDark ? t.textPrimary : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VionixRadii.xl)),
        backgroundColor: t.backgroundElevated,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: t.textSecondary),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1),
    );
  }
}
