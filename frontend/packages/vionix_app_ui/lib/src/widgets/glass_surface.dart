import 'package:flutter/material.dart';

import '../theme/vionix_tokens.dart';

/// Superficie elevada con borde sutil y sombra ligera. Theme-aware.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = VionixRadii.xl,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? t.backgroundElevated,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? t.border),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
