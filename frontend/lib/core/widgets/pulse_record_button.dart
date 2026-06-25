import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botón circular de grabación. Área táctil completa (120×120) para evitar clics perdidos.
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
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
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
    final active = widget.recording;
    final color = active ? AppColors.error : AppColors.primary;
    final canTap = widget.enabled && !widget.busy && widget.onPressed != null;

    return SizedBox(
      width: 120,
      height: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canTap ? widget.onPressed : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final t = _pulse.value;
                    return Container(
                      width: 120 + (t * 36),
                      height: 120 + (t * 36),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.18 * (1 - t)),
                      ),
                    );
                  },
                ),
              ),
            Material(
              elevation: active ? 8 : 4,
              shadowColor: color.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              color: canTap ? color : AppColors.border,
              child: SizedBox(
                width: 88,
                height: 88,
                child: widget.busy
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
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
