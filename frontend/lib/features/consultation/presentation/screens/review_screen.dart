import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/review_ai_banner.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/review_planilla_field.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/review_planilla_header.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/transcript_panel.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/models/document_templates.dart';

/// Revisión y edición del borrador clínico, con evidencia: cada campo puede
/// resaltar el fragmento de la conversación que lo originó.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
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
    final filledCount = note.orderedSections
        .where((e) => e.value.content.trim().isNotEmpty)
        .length;

    final highlighted = _selectedKey == null
        ? const <int>{}
        : (state.evidenceBySection[_selectedKey] ?? const []).toSet();

    final planilla = _planillaChildren(
      context: context,
      note: note,
      template: template,
      documentTitle: state.documentTitle ?? note.documentType.title,
      patientId: state.patientId,
      filledCount: filledCount,
      evidenceBySection: state.evidenceBySection,
    );

    final transcript = TranscriptPanel(
      transcript: state.transcript,
      highlighted: highlighted,
    );

    final wide = isWideLayout(context);

    return AppPage(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: state.documentTitle ?? 'Revisión',
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: planilla),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 360,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [transcript],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...planilla,
                    const SizedBox(height: 16),
                    transcript,
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _planillaChildren({
    required BuildContext context,
    required ClinicalDraft note,
    required List<DocumentSectionDef> template,
    required String documentTitle,
    required String? patientId,
    required int filledCount,
    required Map<String, List<int>> evidenceBySection,
  }) {
    return [
      PlanillaHeader(
        documentTitle: documentTitle,
        patientId: patientId,
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
        final hasEvidence = (evidenceBySection[def.key] ?? const []).isNotEmpty;
        return FadeSlideIn(
          delay: VionixMotion.stagger * (index + 1),
          child: PlanillaField(
            index: index + 1,
            definition: def,
            section: section,
            hasEvidence: hasEvidence,
            isSelected: _selectedKey == def.key,
            onShowEvidence: hasEvidence
                ? () => setState(() {
                      _selectedKey = _selectedKey == def.key ? null : def.key;
                    })
                : null,
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
    ];
  }
}
