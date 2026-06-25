import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_layout.dart';
import '../../core/patient_identity_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../models/clinical_note.dart';
import '../../models/document_templates.dart';
import 'consultation_controller.dart';

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
              _PlanillaHeader(
                documentTitle: state.documentTitle ?? note.documentType.title,
                patientId: state.patientId,
                filledCount: filledCount,
                totalCount: template.length,
              ),
              const SizedBox(height: 16),
              _AiBanner(),
              const SizedBox(height: 24),
              ...template.asMap().entries.map((entry) {
                final index = entry.key;
                final def = entry.value;
                final section = note.sections[def.key] ?? ClinicalSection();
                return _PlanillaField(
                  index: index + 1,
                  definition: def,
                  section: section,
                  onChanged: (value) => ref
                      .read(consultationProvider.notifier)
                      .updateSectionContent(def.key, value),
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

class _PlanillaHeader extends StatelessWidget {
  const _PlanillaHeader({
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '$filledCount de $totalCount campos completados por la IA. '
            'Completa los vacíos y revisa el resto antes de confirmar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warningSoft,
            AppColors.warningSoft.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_outlined, color: AppColors.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borrador con asistencia de IA',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Los campos marcados como «Revisar» requieren confirmación explícita.',
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

class _PlanillaField extends StatefulWidget {
  const _PlanillaField({
    required this.index,
    required this.definition,
    required this.section,
    required this.onChanged,
  });

  final int index;
  final DocumentSectionDef definition;
  final ClinicalSection section;
  final ValueChanged<String> onChanged;

  @override
  State<_PlanillaField> createState() => _PlanillaFieldState();
}

class _PlanillaFieldState extends State<_PlanillaField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.section.content);
  }

  @override
  void didUpdateWidget(_PlanillaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.content != widget.section.content &&
        _controller.text != widget.section.content) {
      _controller.text = widget.section.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isFilled => widget.section.content.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final status = _fieldStatus();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status.borderColor,
            width: status.highlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: status.numberBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: status.numberColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.definition.label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.definition.hint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: TextFormField(
                controller: _controller,
                minLines: 3,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: _isFilled ? null : 'Pendiente — completa manualmente…',
                  filled: true,
                  fillColor: status.fieldBackground,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _FieldStatus _fieldStatus() {
    if (widget.section.needsConfirmation && _isFilled) {
      return _FieldStatus.review;
    }
    if (_isFilled) {
      return _FieldStatus.filledByAi;
    }
    return _FieldStatus.empty;
  }
}

enum _FieldStatusKind { filledByAi, empty, review }

class _FieldStatus {
  const _FieldStatus({
    required this.kind,
    required this.label,
    required this.borderColor,
    required this.numberBackground,
    required this.numberColor,
    required this.fieldBackground,
    required this.chipBackground,
    required this.chipColor,
    this.highlighted = false,
  });

  final _FieldStatusKind kind;
  final String label;
  final Color borderColor;
  final Color numberBackground;
  final Color numberColor;
  final Color fieldBackground;
  final Color chipBackground;
  final Color chipColor;
  final bool highlighted;

  static const filledByAi = _FieldStatus(
    kind: _FieldStatusKind.filledByAi,
    label: 'IA',
    borderColor: AppColors.primary,
    numberBackground: AppColors.primarySoft,
    numberColor: AppColors.primary,
    fieldBackground: Color(0xFFF4FAFA),
    chipBackground: AppColors.primarySoft,
    chipColor: AppColors.primary,
    highlighted: true,
  );

  static const empty = _FieldStatus(
    kind: _FieldStatusKind.empty,
    label: 'Vacío',
    borderColor: AppColors.border,
    numberBackground: AppColors.surfaceMuted,
    numberColor: AppColors.textTertiary,
    fieldBackground: AppColors.surfaceMuted,
    chipBackground: AppColors.surfaceMuted,
    chipColor: AppColors.textTertiary,
  );

  static const review = _FieldStatus(
    kind: _FieldStatusKind.review,
    label: 'Revisar',
    borderColor: AppColors.warning,
    numberBackground: AppColors.warningSoft,
    numberColor: AppColors.warning,
    fieldBackground: AppColors.warningSoft,
    chipBackground: AppColors.warningSoft,
    chipColor: AppColors.warning,
    highlighted: true,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _FieldStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.chipColor,
        ),
      ),
    );
  }
}
