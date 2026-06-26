import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/consultation/presentation/widgets/review_ai_banner.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/review_planilla_field.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/review_planilla_header.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/models/document_templates.dart';

/// Revisión y edición del borrador clínico como planilla digital estructurada.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultationProvider);
    final note = state.note;

    if (note == null) {
      return AppPage(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: 'Revisión',
        body: const Center(child: Text('Sin borrador todavía')),
      );
    }

    final template = DocumentTemplates.forType(note.documentType);
    final filledCount = note.orderedSections.where((e) => e.value.content.trim().isNotEmpty).length;

    return AppPage(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: state.documentTitle ?? 'Revisión',
      body: SingleChildScrollView(
        child: FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlanillaHeader(
                documentTitle: state.documentTitle ?? note.documentType.title,
                patientId: state.patientId,
                filledCount: filledCount,
                totalCount: template.length,
              ),
              const SizedBox(height: 16),
              const AiBanner(),
              const SizedBox(height: 24),
              ...template.asMap().entries.map((entry) {
                final index = entry.key;
                final def = entry.value;
                final section = note.sections[def.key] ?? ClinicalSection();
                return FadeSlideIn(
                  delay: VionixMotion.stagger * (index + 1),
                  child: PlanillaField(
                    index: index + 1,
                    definition: def,
                    section: section,
                    onChanged: (value) => ref
                        .read(consultationProvider.notifier)
                        .updateSectionContent(def.key, value),
                  ),
                );
              }),
              DesktopActionBar(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(consultationProvider.notifier).markReviewedLocally();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Borrador marcado como revisado (solo local)'),
                        ),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar revisión'),
                  ),
                  Tooltip(
                    message: 'Disponible cuando se conecte al sistema del hospital',
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar al HIS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

