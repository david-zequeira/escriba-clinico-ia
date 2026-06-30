import 'package:flutter/material.dart';

import 'motion.dart';

/// Envuelve cualquier widget para darle feedback táctil "premium":
/// se hunde ligeramente al pulsar y vuelve con un rebote suave al soltar.
/// Ideal para tarjetas, botones personalizados y elementos de lista.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final MouseCursor cursor;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = _pressed && !context.reduceMotion ? widget.pressedScale : 1.0;

    return MouseRegion(
      cursor: enabled ? widget.cursor : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: scale,
          duration: _pressed ? VionixMotion.fast : VionixMotion.medium,
          curve: _pressed ? VionixMotion.standard : VionixMotion.spring,
          child: widget.child,
        ),
      ),
    );
  }
}
