import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';

/// Panel de la conversación. Resalta los segmentos que respaldan el campo
/// seleccionado (evidence grounding / trazabilidad Clase I).
class TranscriptPanel extends StatelessWidget {
  const TranscriptPanel({
    super.key,
    required this.transcript,
    this.highlighted = const {},
  });

  final Transcript transcript;
  final Set<int> highlighted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 18, color: t.textSecondary),
              const SizedBox(width: 8),
              Text('Conversación', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            highlighted.isEmpty
                ? 'Toca «ver evidencia» en un campo para resaltar de dónde salió.'
                : 'Resaltado: el origen del campo seleccionado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (transcript.isEmpty)
            Text('Sin transcripción disponible.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            for (var i = 0; i < transcript.segments.length; i++)
              _SegmentTile(
                segment: transcript.segments[i],
                highlighted: highlighted.contains(i),
              ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({required this.segment, required this.highlighted});

  final TranscriptSegment segment;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDoctor = segment.speaker == Speaker.medico;
    final speakerColor = switch (segment.speaker) {
      Speaker.medico => t.primary,
      Speaker.paciente => t.info,
      Speaker.desconocido => t.textTertiary,
    };

    return AnimatedContainer(
      duration: VionixMotion.medium,
      curve: VionixMotion.standard,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? speakerColor.withValues(alpha: 0.10) : t.surfaceMuted,
        borderRadius: BorderRadius.circular(VionixRadii.md),
        border: Border.all(
          color: highlighted ? speakerColor.withValues(alpha: 0.6) : t.borderSubtle,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDoctor ? Icons.medical_services_outlined : Icons.person_outline,
                size: 14,
                color: speakerColor,
              ),
              const SizedBox(width: 6),
              Text(
                segment.speaker.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: speakerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(segment.text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
