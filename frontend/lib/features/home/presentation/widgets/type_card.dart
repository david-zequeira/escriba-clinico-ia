import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/consultation/presentation/screens/recording_screen.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Tarjeta de selección de un tipo de documento clínico.
class TypeCard extends StatelessWidget {
  const TypeCard({super.key, required this.type});

  final ConsultationType type;

  void _open(BuildContext context) {
    Navigator.of(context)
        .push(AppPageRoute(page: RecordingScreen(consultationType: type)));
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.tokens.accentFor(type.apiValue);
    return HoverScaleCard(
      accentColor: acc.accent,
      accentSoft: acc.soft,
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: acc.soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon, color: acc.accent, size: 22),
            ),
            const SizedBox(height: 12),
            Text(type.shortLabel.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              type.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                type.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.start,
                    style:
                        TextStyle(fontWeight: FontWeight.w600, color: acc.accent),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: acc.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
