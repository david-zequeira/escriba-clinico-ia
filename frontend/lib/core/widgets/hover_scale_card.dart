import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tarjeta interactiva: hover solo cambia borde y sombra (sin escala, evita recortes al zoom).
class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.accentColor = AppColors.primary,
    this.accentSoft = AppColors.primarySoft,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;
  final Color accentSoft;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.accentColor.withValues(alpha: 0.5) : AppColors.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.1)
                  : AppColors.shadow,
              blurRadius: _hovered ? 16 : 12,
              offset: Offset(0, _hovered ? 6 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.accentSoft,
            highlightColor: widget.accentSoft.withValues(alpha: 0.45),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
