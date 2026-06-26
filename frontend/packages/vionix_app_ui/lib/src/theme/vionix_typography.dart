import 'package:flutter/material.dart';

import 'vionix_tokens.dart';

/// Construye la jerarquía tipográfica usando los colores del tema activo.
TextTheme buildVionixTextTheme(VionixTokens t) {
  return TextTheme(
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.15,
      color: t.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: t.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: t.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: t.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: t.textSecondary),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: t.textSecondary),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: t.textTertiary),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: t.textSecondary,
    ),
  );
}
