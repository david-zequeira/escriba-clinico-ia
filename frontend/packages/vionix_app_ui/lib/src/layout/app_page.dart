import 'package:flutter/material.dart';

import '../theme/vionix_tokens.dart';
import 'platform_info.dart';

/// Ancho máximo del contenido en pantallas grandes (laptop/PC).
const double kDesktopMaxWidth = 1120.0;

/// Scaffold con fondo degradado sutil (del tema) y contenido centrado.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.leading,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String? title;
  final Widget? leading;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wide = isWideLayout(context);

    return Scaffold(
      extendBodyBehindAppBar: title != null,
      appBar: title == null && actions == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              leading: leading,
              actions: actions,
            ),
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: t.scrimGradient,
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: wide ? kDesktopMaxWidth : double.infinity),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: wide ? 20 : 16,
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de acciones al pie de pantallas de revisión.
class DesktopActionBar extends StatelessWidget {
  const DesktopActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: wide
          ? Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  if (children[i] is FilledButton || children[i] is ElevatedButton)
                    children[i]
                  else
                    Expanded(child: children[i]),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            ),
    );
  }
}

/// Badge informativo compacto. Si no se pasan colores, usa el acento "info" del tema.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = color ?? t.info;
    final bg = background ?? t.infoSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VionixRadii.pill),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
