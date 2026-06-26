import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/patient_identity_labels.dart';

/// Cabecera de la planilla de revisión: título, paciente y progreso de campos.
class PlanillaHeader extends StatelessWidget {
  const PlanillaHeader({
    super.key,
    required this.documentTitle,
    required this.patientId,
    required this.filledCount,
    required this.totalCount,
  });

  final String documentTitle;
  final String? patientId;
  final int filledCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (patientId != null && patientId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${PatientIdentityLabels.fieldLabel}: $patientId',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '$filledCount de $totalCount campos completados por la IA. '
            'Completa los vacíos y revisa el resto antes de confirmar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: t.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
