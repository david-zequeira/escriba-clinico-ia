import 'package:flutter/material.dart';

/// Tokens de movimiento de Vionix. Una sola fuente para duraciones y curvas,
/// de modo que toda la app se sienta coherente y "premium".
abstract final class VionixMotion {
  // Duraciones — escala perceptual.
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration slower = Duration(milliseconds: 560);

  /// Escalonado entre elementos de una lista/grid al entrar.
  static const Duration stagger = Duration(milliseconds: 70);

  // Curvas — entrada decelerada, salida acelerada, énfasis con rebote sutil.
  static const Curve standard = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOutQuart;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve spring = Cubic(0.34, 1.4, 0.64, 1.0);
}

/// Utilidades de accesibilidad para el movimiento.
extension MotionAccessibilityX on BuildContext {
  /// El usuario pidió reducir el movimiento (Sistema → Accesibilidad).
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  /// Devuelve [d] o `Duration.zero` si el usuario reduce el movimiento.
  Duration motion(Duration d) => reduceMotion ? Duration.zero : d;
}
