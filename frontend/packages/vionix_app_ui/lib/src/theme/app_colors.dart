import 'package:flutter/material.dart';

/// Constantes de color del tema claro.
///
/// COMPATIBILIDAD: se conserva para el código que aún referencia colores fijos.
/// Para soportar tema oscuro, prefiere leer `context.tokens` ([VionixTokens])
/// en vez de estas constantes estáticas.
abstract final class AppColors {
  static const background = Color(0xFFF4F7FB);
  static const backgroundElevated = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);
  static const borderSubtle = Color(0xFFF1F5F9);

  static const primary = Color(0xFF0D9488);
  static const primarySoft = Color(0xFFCCFBF1);
  static const primaryDark = Color(0xFF0F766E);

  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFEFF6FF);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0xFFFEF2F2);

  static const admission = Color(0xFF3B82F6);
  static const admissionSoft = Color(0xFFEFF6FF);
  static const treatment = Color(0xFF8B5CF6);
  static const treatmentSoft = Color(0xFFF5F3FF);
  static const evolution = Color(0xFF10B981);
  static const evolutionSoft = Color(0xFFECFDF5);

  static const shadow = Color(0x140F172A);
}
