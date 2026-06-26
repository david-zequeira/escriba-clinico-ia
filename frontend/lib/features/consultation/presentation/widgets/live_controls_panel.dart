import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/consultation/state_management/live_transcription_controller.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Panel de control de la sesión en vivo: tipo de documento, estado de la
/// sesión, waveform con amplitud real y botones iniciar/pausar/reanudar/finalizar.
class LiveControlsPanel extends StatelessWidget {
  const LiveControlsPanel({
    super.key,
    required this.type,
    required this.status,
    required this.amplitude,
    required this.errorMessage,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final ConsultationType type;
  final LiveStatus status;
  final double amplitude;
  final String? errorMessage;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  bool get _listening => status == LiveStatus.listening;
  bool get _paused => status == LiveStatus.paused;
  bool get _active => _listening || _paused;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final acc = context.tokens.accentFor(type.apiValue);

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InfoPill(
                icon: type.icon,
                label: type.shortLabel(l),
                color: acc.accent,
                background: acc.soft,
              ),
              const Spacer(),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.liveRecordingHint, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 56,
              child: _listening
                  ? RecordingWaveform(level: amplitude, color: context.tokens.primary)
                  : Text(
                      _paused ? l.livePaused : l.liveMicIdle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (!_active)
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.fiber_manual_record_rounded),
              label: Text(l.liveStart),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _listening
                      ? OutlinedButton.icon(
                          onPressed: onPause,
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(l.livePause),
                        )
                      : FilledButton.icon(
                          onPressed: onResume,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l.liveResume),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStop,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.tokens.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l.liveFinish),
                  ),
                ),
              ],
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.tokens.errorSoft,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: context.tokens.error.withValues(alpha: 0.25)),
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

/// Chip de estado de la sesión en vivo, con color e icono coherentes.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LiveStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final (label, color, icon) = switch (status) {
      LiveStatus.idle => (l.liveStatusIdle, t.textTertiary, Icons.circle_outlined),
      LiveStatus.connecting =>
        (l.liveStatusConnecting, t.info, Icons.sync_rounded),
      LiveStatus.listening =>
        (l.liveStatusListening, t.error, Icons.fiber_manual_record_rounded),
      LiveStatus.paused => (l.liveStatusPaused, t.warning, Icons.pause_rounded),
      LiveStatus.stopped =>
        (l.liveStatusStopped, t.success, Icons.check_circle_rounded),
      LiveStatus.error => (l.liveStatusError, t.error, Icons.error_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VionixRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
