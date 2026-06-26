import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';

/// Panel de la conversación. Resalta los segmentos que respaldan el campo
/// seleccionado y, al tocar un segmento, pide seleccionar el campo que respalda
/// (evidence grounding bidireccional / trazabilidad Clase I).
class TranscriptPanel extends StatefulWidget {
  const TranscriptPanel({
    super.key,
    required this.transcript,
    this.highlighted = const {},
    this.onSegmentTap,
  });

  final Transcript transcript;
  final Set<int> highlighted;
  final ValueChanged<int>? onSegmentTap;

  @override
  State<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<TranscriptPanel> {
  List<GlobalKey> _keys = const [];

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
  }

  void _rebuildKeys() {
    _keys = List.generate(widget.transcript.segments.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(TranscriptPanel old) {
    super.didUpdateWidget(old);
    if (old.transcript.segments.length != widget.transcript.segments.length) {
      _rebuildKeys();
    }
    if (widget.highlighted.isNotEmpty &&
        !setEquals(old.highlighted, widget.highlighted)) {
      _scrollToFirstHighlighted();
    }
  }

  void _scrollToFirstHighlighted() {
    final first = widget.highlighted.reduce((a, b) => a < b ? a : b);
    if (first < 0 || first >= _keys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[first].currentContext;
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
            widget.highlighted.isEmpty
                ? 'Toca «ver evidencia» en un campo, o un fragmento aquí, para enlazarlos.'
                : 'Resaltado: el origen del campo seleccionado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (widget.transcript.isEmpty)
            Text('Sin transcripción disponible.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            for (var i = 0; i < widget.transcript.segments.length; i++)
              KeyedSubtree(
                key: _keys[i],
                child: _SegmentTile(
                  segment: widget.transcript.segments[i],
                  highlighted: widget.highlighted.contains(i),
                  onTap: widget.onSegmentTap == null
                      ? null
                      : () => widget.onSegmentTap!(i),
                ),
              ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.segment,
    required this.highlighted,
    this.onTap,
  });

  final TranscriptSegment segment;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDoctor = segment.speaker == Speaker.medico;
    final speakerColor = switch (segment.speaker) {
      Speaker.medico => t.primary,
      Speaker.paciente => t.info,
      Speaker.desconocido => t.textTertiary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VionixRadii.md),
          child: AnimatedContainer(
            duration: VionixMotion.medium,
            curve: VionixMotion.standard,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlighted
                  ? speakerColor.withValues(alpha: 0.10)
                  : t.surfaceMuted,
              borderRadius: BorderRadius.circular(VionixRadii.md),
              border: Border.all(
                color: highlighted
                    ? speakerColor.withValues(alpha: 0.6)
                    : t.borderSubtle,
                width: highlighted ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDoctor
                          ? Icons.medical_services_outlined
                          : Icons.person_outline,
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
          ),
        ),
      ),
    );
  }
}
