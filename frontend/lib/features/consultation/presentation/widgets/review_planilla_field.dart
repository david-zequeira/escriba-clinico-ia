import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/models/document_templates.dart';

/// Campo editable de una sección de la planilla, con estado (IA / Vacío / Revisar).
class PlanillaField extends StatefulWidget {
  const PlanillaField({
    super.key,
    required this.index,
    required this.definition,
    required this.section,
    required this.onChanged,
    this.hasEvidence = false,
    this.evidenceCount = 0,
    this.isSelected = false,
    this.onShowEvidence,
  });

  final int index;
  final DocumentSectionDef definition;
  final ClinicalSection section;
  final ValueChanged<String> onChanged;

  /// Hay evidencia (segmentos de la conversación) que respalda este campo.
  final bool hasEvidence;

  /// Número de fragmentos de la conversación que respaldan este campo.
  final int evidenceCount;

  /// El campo está seleccionado: su evidencia se resalta en la conversación.
  final bool isSelected;

  /// Solicita resaltar la evidencia de este campo en el panel de conversación.
  final VoidCallback? onShowEvidence;

  @override
  State<PlanillaField> createState() => _PlanillaFieldState();
}

class _PlanillaFieldState extends State<PlanillaField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.section.content);
  }

  @override
  void didUpdateWidget(PlanillaField oldWidget) {
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
    final t = context.tokens;
    final status = _fieldStatus(t);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: t.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected ? t.primary : status.borderColor,
            width: widget.isSelected ? 2 : (status.highlighted ? 1.5 : 1),
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
                                color: t.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.definition.hint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: t.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: status),
                  if (widget.hasEvidence) ...[
                    const SizedBox(width: 2),
                    _EvidenceButton(
                      selected: widget.isSelected,
                      count: widget.evidenceCount,
                      onTap: widget.onShowEvidence,
                    ),
                  ],
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

  _FieldStatus _fieldStatus(VionixTokens t) {
    if (widget.section.needsConfirmation && _isFilled) {
      return _FieldStatus.review(t);
    }
    if (_isFilled) {
      return _FieldStatus.filledByAi(t);
    }
    return _FieldStatus.empty(t);
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

  /// Campo rellenado por la IA (acento primario).
  static _FieldStatus filledByAi(VionixTokens t) => _FieldStatus(
        kind: _FieldStatusKind.filledByAi,
        label: 'IA',
        borderColor: t.primary,
        numberBackground: t.primarySoft,
        numberColor: t.primary,
        fieldBackground: Color.alphaBlend(
            t.primary.withValues(alpha: 0.06), t.backgroundElevated),
        chipBackground: t.primarySoft,
        chipColor: t.primary,
        highlighted: true,
      );

  /// Campo vacío, pendiente de completar.
  static _FieldStatus empty(VionixTokens t) => _FieldStatus(
        kind: _FieldStatusKind.empty,
        label: 'Vacío',
        borderColor: t.border,
        numberBackground: t.surfaceMuted,
        numberColor: t.textTertiary,
        fieldBackground: t.surfaceMuted,
        chipBackground: t.surfaceMuted,
        chipColor: t.textTertiary,
      );

  /// Campo que requiere confirmación explícita del médico (acento de aviso).
  static _FieldStatus review(VionixTokens t) => _FieldStatus(
        kind: _FieldStatusKind.review,
        label: 'Revisar',
        borderColor: t.warning,
        numberBackground: t.warningSoft,
        numberColor: t.warning,
        fieldBackground: t.warningSoft,
        chipBackground: t.warningSoft,
        chipColor: t.warning,
        highlighted: true,
      );
}

/// Botón compacto "ver evidencia": resalta en la conversación el origen del campo.
class _EvidenceButton extends StatelessWidget {
  const _EvidenceButton({required this.selected, this.count = 0, this.onTap});

  final bool selected;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.primary : t.textTertiary;
    return Tooltip(
      message: count > 1 ? 'Ver de dónde salió ($count fragmentos)' : 'Ver de dónde salió',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VionixRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore_rounded, size: 18, color: color),
              if (count > 1) ...[
                const SizedBox(width: 3),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
