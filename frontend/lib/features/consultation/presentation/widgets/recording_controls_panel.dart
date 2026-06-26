import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/core/patient_identity_labels.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Panel de control de la grabación: identidad del paciente, botón de grabar,
/// waveform y mensajes de estado.
class RecordingControlsPanel extends StatelessWidget {
  const RecordingControlsPanel({
    super.key,
    required this.type,
    required this.patientIdController,
    required this.patientIdFocus,
    required this.recording,
    required this.finalizing,
    required this.serverProcessing,
    required this.onToggleRecording,
  });

  final ConsultationType type;
  final TextEditingController patientIdController;
  final FocusNode patientIdFocus;
  final bool recording;
  final bool finalizing;
  final bool serverProcessing;
  final VoidCallback? onToggleRecording;

  bool get _busy => finalizing || serverProcessing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final acc = context.tokens.accentFor(type.apiValue);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoPill(
            icon: type.icon,
            label: type.shortLabel,
            color: acc.accent,
            background: acc.soft,
          ),
          const SizedBox(height: 20),
          Text(type.recordingHint, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          TextField(
            controller: patientIdController,
            focusNode: patientIdFocus,
            enabled: !recording && !finalizing && !serverProcessing,
            decoration: const InputDecoration(
              labelText: PatientIdentityLabels.fieldLabel,
              hintText: PatientIdentityLabels.hint,
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                PulseRecordButton(
                  recording: recording,
                  busy: _busy,
                  enabled: !serverProcessing,
                  onPressed: onToggleRecording,
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: VionixMotion.medium,
                  curve: VionixMotion.standard,
                  child: recording
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecordingWaveform(active: recording),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (recording || finalizing)
                  FilledButton.icon(
                    onPressed: onToggleRecording,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.tokens.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(finalizing ? l.finishing : l.stopRecording),
                  ),
                if (!recording && !_busy)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      serverProcessing ? l.sendingToServer : l.pressToRecord,
                      key: ValueKey(serverProcessing ? 'upload' : 'idle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  )
                else if (recording)
                  Text(
                    l.recordingInProgress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.tokens.error,
                        ),
                  ),
              ],
            ),
          ),
          if (isDesktopPlatform) ...[
            const SizedBox(height: 20),
            Text(
              l.spaceShortcutHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
