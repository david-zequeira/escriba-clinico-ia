import 'package:flutter/material.dart';

import 'motion.dart';

/// Transición de página suave (fade + slide ligero), con tokens de motion.
/// Respeta la preferencia de "reducir movimiento" del sistema.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: VionixMotion.slow,
          reverseTransitionDuration: VionixMotion.medium,
          transitionsBuilder: (context, animation, __, child) {
            if (context.reduceMotion) return child;
            final curved =
                CurvedAnimation(parent: animation, curve: VionixMotion.decelerate);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
