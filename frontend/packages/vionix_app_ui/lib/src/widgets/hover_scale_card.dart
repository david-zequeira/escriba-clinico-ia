import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/vionix_tokens.dart';

/// Tarjeta interactiva: al hacer hover eleva borde + sombra y, en escritorio,
/// sube ligeramente (sin recortes). Theme-aware y con tokens de motion.
class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.accentColor,
    this.accentSoft,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? accentColor;
  final Color? accentSoft;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = widget.accentColor ?? t.primary;
    final accentSoft = widget.accentSoft ?? t.primarySoft;
    final lift = _hovered && !context.reduceMotion;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: VionixMotion.medium,
        curve: VionixMotion.spring,
        transform: Matrix4.translationValues(0, lift ? -3 : 0, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.backgroundElevated,
          borderRadius: BorderRadius.circular(VionixRadii.lg),
          border: Border.all(
            color: _hovered ? accent.withValues(alpha: 0.5) : t.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? accent.withValues(alpha: 0.16) : t.shadow,
              blurRadius: _hovered ? 22 : 12,
              offset: Offset(0, _hovered ? 10 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(VionixRadii.lg),
            splashColor: accentSoft,
            highlightColor: accentSoft.withValues(alpha: 0.45),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
