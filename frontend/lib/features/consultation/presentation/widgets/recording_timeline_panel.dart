import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Panel de progreso del procesamiento: grabación → transcripción → borrador.
class RecordingTimelinePanel extends StatelessWidget {
  const RecordingTimelinePanel({
    super.key,
    required this.type,
    required this.recording,
    required this.finalizing,
    required this.serverProcessing,
    this.errorMessage,
  });

  final ConsultationType type;
  final bool recording;
  final bool finalizing;
  final bool serverProcessing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final recordingDone =
        !recording && (finalizing || serverProcessing || errorMessage != null);
    final steps = [
      _StepData(l.stepRecording, Icons.mic_none_rounded, recording, recordingDone),
      _StepData(
        l.stepTranscription,
        Icons.graphic_eq_rounded,
        serverProcessing && !finalizing,
        false,
      ),
      _StepData(l.stepClinicalDraft, Icons.article_outlined, false, false),
    ];

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.progress, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) {
            final step = e.value;
            final isLast = e.key == steps.length - 1;
            return _TimelineStep(step: step, showConnector: !isLast);
          }),
          if (finalizing || serverProcessing) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 6),
            ),
            const SizedBox(height: 10),
            Text(
              finalizing ? l.savingAudioLocally : l.processingOnServer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.tokens.errorSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: context.tokens.error.withValues(alpha: 0.25)),
              ),
              child: Text(errorMessage!,
                  style: TextStyle(color: context.tokens.error)),
            ),
          ],
          const SizedBox(height: 16),
          Text(type.subtitle(l), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData(this.label, this.icon, this.active, this.done);
  final String label;
  final IconData icon;
  final bool active;
  final bool done;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.showConnector});

  final _StepData step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = step.active
        ? t.primary
        : step.done
            ? t.success
            : t.textTertiary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: step.active || step.done
                      ? color.withValues(alpha: 0.12)
                      : t.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(step.icon, size: 18, color: color),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: step.done
                        ? t.success.withValues(alpha: 0.4)
                        : t.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: step.active || step.done
                            ? t.textPrimary
                            : t.textTertiary,
                      ),
                    ),
                  ),
                  if (step.active)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (step.done)
                    Icon(Icons.check_circle_rounded, size: 18, color: t.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
