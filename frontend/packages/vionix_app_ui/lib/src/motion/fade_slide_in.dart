import 'package:flutter/material.dart';

import 'motion.dart';

/// Entrada suave (estilo apps modernas): fade + ligero desplazamiento.
/// Respeta "reducir movimiento": en ese caso aparece sin animar.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = VionixMotion.slower,
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve =
        CurvedAnimation(parent: _controller, curve: VionixMotion.decelerate);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _controller.value = 1; // sin animación: estado final directo
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Aplica [FadeSlideIn] en cascada a una lista de hijos (entrada escalonada).
/// Devuelve una lista lista para usar dentro de Column/Wrap/GridView.
List<Widget> staggeredChildren(
  List<Widget> children, {
  Duration interval = VionixMotion.stagger,
  Duration initialDelay = Duration.zero,
  Offset offset = const Offset(0, 16),
}) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeSlideIn(
        delay: initialDelay + (interval * i),
        offset: offset,
        child: children[i],
      ),
  ];
}
