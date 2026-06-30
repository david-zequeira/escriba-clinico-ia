import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
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
  final Map<String, GlobalKey> _fieldKeys = {};

  GlobalKey _fieldKey(String key) => _fieldKeys.putIfAbsent(key, GlobalKey.new);

  /// Muestra la evidencia de un campo. En pantallas anchas resalta en el panel
  /// lateral (toggle); en estrechas abre un bottom sheet con los fragmentos.
  void _showEvidence(String key, String label) {
    if (isWideLayout(context)) {
      setState(() => _selectedKey = _selectedKey == key ? null : key);
      return;
    }
    setState(() => _selectedKey = key);
    final state = ref.read(consultationProvider);
    final indices = state.evidenceBySection[key] ?? const <int>[];
    final segments = state.transcript.segments;
    final cited = [
      for (final i in indices)
        if (i >= 0 && i < segments.length) segments[i],
    ];
    if (cited.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.tokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VionixRadii.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: TranscriptPanel(
            transcript: Transcript(segments: cited),
            highlighted: {for (var i = 0; i < cited.length; i++) i},
            title: context.l10n.evidenceTitle(label),
          ),
        ),
      ),
    );
  }

  /// Toca un fragmento de la conversación → selecciona el campo que respalda
  /// y desplaza la planilla hasta él (evidence grounding bidireccional).
  void _onSegmentTap(int index) {
    final evidence = ref.read(consultationProvider).evidenceBySection;
    String? key;
    for (final entry in evidence.entries) {
      if (entry.value.contains(index)) {
        key = entry.key;
        break;
      }
    }
    if (key == null) return;
    setState(() => _selectedKey = key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _fieldKeys[key]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: VionixMotion.medium,
          curve: VionixMotion.standard,
        );
      }
    });
  }

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
        title: context.l10n.review,
        body: Center(child: Text(context.l10n.noDraftYet)),
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
      documentTitle: state.documentTitle ?? note.documentType.title(context.l10n),
      patientId: state.patientId,
      filledCount: filledCount,
      evidenceBySection: state.evidenceBySection,
    );

    final transcript = TranscriptPanel(
      transcript: state.transcript,
      highlighted: highlighted,
      onSegmentTap: _onSegmentTap,
    );

    final wide = isWideLayout(context);

    return AppPage(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: state.documentTitle ?? context.l10n.review,
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
        return KeyedSubtree(
          key: _fieldKey(def.key),
          child: FadeSlideIn(
            delay: VionixMotion.stagger * (index + 1),
            child: PlanillaField(
              index: index + 1,
              definition: def,
              section: section,
              hasEvidence: hasEvidence,
              evidenceCount: (evidenceBySection[def.key] ?? const []).length,
              isSelected: _selectedKey == def.key,
              onShowEvidence: hasEvidence
                  ? () => _showEvidence(def.key, def.label(context.l10n))
                  : null,
              onChanged: (value) => ref
                  .read(consultationProvider.notifier)
                  .updateSectionContent(def.key, value),
            ),
          ),
        );
      }),
      DesktopActionBar(
        children: [
          FilledButton.icon(
            onPressed: () {
              ref.read(consultationProvider.notifier).markReviewedLocally();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.draftMarkedReviewed)),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.l10n.confirmReview),
          ),
          Tooltip(
            message: context.l10n.sendToHisTooltip,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(context.l10n.sendToHis),
            ),
          ),
        ],
      ),
    ];
  }
}
