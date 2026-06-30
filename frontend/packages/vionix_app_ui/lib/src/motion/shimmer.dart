import 'package:flutter/material.dart';

import '../theme/vionix_tokens.dart';
import 'motion.dart';

/// Bloque "skeleton" con barrido de brillo, para estados de carga.
/// Úsalo para imitar la forma del contenido mientras llega (mejor que un spinner).
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = VionixRadii.sm,
  });

  /// Caja con forma redondeada que se anima sola.
  const Shimmer.box({
    super.key,
    required this.width,
    required this.height,
    this.radius = VionixRadii.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: VionixMotion.slower)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = t.surfaceMuted;
    final highlight = Color.alphaBlend(
      t.textTertiary.withValues(alpha: 0.12),
      base,
    );

    if (context.reduceMotion) {
      return _box(base, null);
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = (_c.value * 2) - 1; // -1 → 1
        return _box(
          base,
          LinearGradient(
            begin: Alignment(dx - 0.3, 0),
            end: Alignment(dx + 0.3, 0),
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
          ),
        );
      },
    );
  }

  Widget _box(Color color, Gradient? gradient) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
}
