import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/vionix_tokens.dart';

/// Onda de audio animada para mostrar mientras se graba. Decorativa (no refleja
/// amplitud real). Theme-aware y respeta "reducir movimiento".
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({
    super.key,
    this.active = true,
    this.barCount = 28,
    this.height = 44,
    this.color,
  });

  final bool active;
  final int barCount;
  final double height;
  final Color? color;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(RecordingWaveform old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.tokens.error;
    final animate = widget.active && !context.reduceMotion;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.barCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _bar(i, color, animate),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(int i, Color color, bool animate) {
    final t = _c.value;
    // Onda viajera: cada barra desfasada para simular movimiento.
    final phase = (i / widget.barCount) * math.pi * 2;
    final wave = animate ? (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase)) : 0.25;
    final h = (widget.height * (0.2 + 0.8 * wave)).clamp(4.0, widget.height);
    // Atenuación hacia los extremos para un look más orgánico.
    final edge = math.sin((i / (widget.barCount - 1)) * math.pi);
    final opacity = 0.45 + 0.55 * edge;

    return Container(
      width: 3,
      height: h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity.clamp(0.3, 1.0)),
        borderRadius: BorderRadius.circular(VionixRadii.pill),
      ),
    );
  }
}
