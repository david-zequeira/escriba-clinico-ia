import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';

/// Aviso de transparencia: el borrador fue generado con asistencia de IA.
class AiBanner extends StatelessWidget {
  const AiBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.warningSoft,
            t.warningSoft.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_outlined, color: t.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aiBannerTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  context.l10n.aiBannerSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
