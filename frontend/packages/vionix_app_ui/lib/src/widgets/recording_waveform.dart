import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/vionix_tokens.dart';

/// Onda de audio para mostrar mientras se graba. Theme-aware y respeta
/// "reducir movimiento".
///
/// Dos modos:
/// - **Decorativo** (`level == null`): onda viajera animada (no refleja la señal).
/// - **Amplitud real** (`level` en `0..1`): cada nuevo valor entra por la derecha
///   y desplaza el histórico, dibujando la energía real del micrófono.
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({
    super.key,
    this.active = true,
    this.barCount = 28,
    this.height = 44,
    this.color,
    this.level,
  });

  final bool active;
  final int barCount;
  final double height;
  final Color? color;

  /// Amplitud actual normalizada (`0..1`). Si es null, modo decorativo.
  final double? level;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// Histórico de amplitudes (modo real): la última entra por la derecha.
  late List<double> _levels = List<double>.filled(widget.barCount, 0.0);

  bool get _realMode => widget.level != null;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active && !_realMode) _c.repeat();
    if (_realMode) _pushLevel(widget.level!);
  }

  void _pushLevel(double level) {
    final next = List<double>.from(_levels)
      ..removeAt(0)
      ..add(level.clamp(0.0, 1.0));
    _levels = next;
  }

  @override
  void didUpdateWidget(RecordingWaveform old) {
    super.didUpdateWidget(old);
    // El controlador decorativo solo corre cuando NO hay amplitud real.
    if (widget.active && !_realMode && !_c.isAnimating) {
      _c.repeat();
    } else if ((!widget.active || _realMode) && _c.isAnimating) {
      _c.stop();
    }
    if (_realMode && widget.level != old.level) {
      _pushLevel(widget.level!);
    }
    if (widget.barCount != old.barCount) {
      _levels = List<double>.filled(widget.barCount, 0.0);
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

    if (_realMode) {
      return SizedBox(height: widget.height, child: _bars(color, _realBar));
    }

    final animate = widget.active && !context.reduceMotion;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _bars(color, (i) => _decorativeBar(i, color, animate)),
      ),
    );
  }

  Widget _bars(Color color, Widget Function(int i) barBuilder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.barCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: barBuilder(i),
          ),
      ],
    );
  }

  Widget _realBar(int i) {
    final color = widget.color ?? context.tokens.error;
    final level = _levels[i];
    final h = (widget.height * (0.12 + 0.88 * level)).clamp(4.0, widget.height);
    // Más opacas las barras recientes (derecha) para dar sensación de avance.
    final recency = i / (widget.barCount - 1);
    final opacity = (0.35 + 0.65 * recency).clamp(0.3, 1.0);
    return _barShape(h, color.withValues(alpha: opacity));
  }

  Widget _decorativeBar(int i, Color color, bool animate) {
    final t = _c.value;
    // Onda viajera: cada barra desfasada para simular movimiento.
    final phase = (i / widget.barCount) * math.pi * 2;
    final wave = animate ? (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase)) : 0.25;
    final h = (widget.height * (0.2 + 0.8 * wave)).clamp(4.0, widget.height);
    // Atenuación hacia los extremos para un look más orgánico.
    final edge = math.sin((i / (widget.barCount - 1)) * math.pi);
    final opacity = 0.45 + 0.55 * edge;
    return _barShape(h, color.withValues(alpha: opacity.clamp(0.3, 1.0)));
  }

  Widget _barShape(double h, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      width: 3,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VionixRadii.pill),
      ),
    );
  }
}
