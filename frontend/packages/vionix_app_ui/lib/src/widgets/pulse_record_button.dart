import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/vionix_tokens.dart';

/// Botón circular de grabación con pulso animado. Área táctil completa (120×120).
/// Theme-aware; respeta "reducir movimiento".
class PulseRecordButton extends StatefulWidget {
  const PulseRecordButton({
    super.key,
    required this.recording,
    required this.onPressed,
    this.enabled = true,
    this.busy = false,
  });

  final bool recording;
  final bool enabled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<PulseRecordButton> createState() => _PulseRecordButtonState();
}

class _PulseRecordButtonState extends State<PulseRecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.recording) _pulse.repeat();
  }

  @override
  void didUpdateWidget(PulseRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.recording && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = widget.recording;
    final color = active ? t.error : t.primary;
    final canTap = widget.enabled && !widget.busy && widget.onPressed != null;
    final showPulse = active && !context.reduceMotion;

    return SizedBox(
      width: 120,
      height: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canTap ? widget.onPressed : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showPulse)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final v = _pulse.value;
                    return Container(
                      width: 120 + (v * 36),
                      height: 120 + (v * 36),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.18 * (1 - v)),
                      ),
                    );
                  },
                ),
              ),
            Material(
              elevation: active ? 8 : 4,
              shadowColor: color.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              color: canTap ? color : t.border,
              child: SizedBox(
                width: 88,
                height: 88,
                child: widget.busy
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white),
                      )
                    : Icon(
                        active ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
