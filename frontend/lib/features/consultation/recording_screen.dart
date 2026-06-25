import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_layout.dart';
import '../../core/config.dart';
import '../../core/patient_identity_labels.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/platform_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/glass_surface.dart';
import '../../core/widgets/pulse_record_button.dart';
import '../../models/consultation_type.dart';
import '../audio/audio_recorder.dart';
import '../consultation/consultation_controller.dart';
import 'review_screen.dart';

/// Captura de audio y envío al backend.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key, required this.consultationType});

  final ConsultationType consultationType;

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final _recorder = ConsultationRecorder();
  final _patientIdController = TextEditingController();
  final _patientIdFocus = FocusNode();
  bool _recording = false;
  /// Deteniendo grabación local (plugin nativo); distinto del procesamiento en servidor.
  bool _finalizing = false;
  bool? _backendOk;
  String? _tempPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consultationProvider.notifier).selectType(widget.consultationType);
      _checkBackend();
    });
  }

  Future<void> _checkBackend() async {
    final ok = await ref.read(apiClientProvider).checkHealth();
    if (mounted) setState(() => _backendOk = ok);
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientIdFocus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _confirmConsentIfNeeded() async {
    if (widget.consultationType != ConsultationType.admissionInterview) {
      return true;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.privacy_tip_outlined, color: AppColors.warning),
        ),
        title: const Text('Consentimiento del paciente'),
        content: const Text(
          'Confirma que el paciente ha sido informado y consiente la grabación '
          'de la consulta para generar un borrador clínico con asistencia de IA.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _toggleRecording() async {
    final state = ref.read(consultationProvider);
    if (_finalizing || state.stage == ConsultationStage.processing) return;

    if (_recording) {
      setState(() {
        _finalizing = true;
        _recording = false;
      });

      try {
        final tempPath = _tempPath;
        if (tempPath == null) {
          throw StateError('Ruta de audio no disponible.');
        }

        final audio = await _recorder.stopRecording(tempPath: tempPath);
        if (audio.bytes.isEmpty) {
          throw StateError('La grabación está vacía. Comprueba el micrófono.');
        }

        if (!mounted) return;
        setState(() => _finalizing = false);

        // No await la navegación: ref.listen abre ReviewScreen al completar.
        unawaited(
          ref.read(consultationProvider.notifier).submitAudio(
                audio.bytes,
                _patientIdController.text.trim(),
                filename: audio.filename,
              ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Bad state: ', '')),
            duration: const Duration(seconds: 8),
          ),
        );
      } finally {
        if (mounted) setState(() => _finalizing = false);
      }
      return;
    }

    if (!await _confirmConsentIfNeeded()) return;
    if (!mounted) return;

    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(PatientIdentityLabels.requiredMessage)),
      );
      _patientIdFocus.requestFocus();
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final ext = _recorder.preferredExtension;
      _tempPath = '${dir.path}/consulta-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _recorder.start(_tempPath!);
      setState(() => _recording = true);
      _patientIdFocus.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ConsultationState>(consultationProvider, (prev, next) {
      if (next.stage == ConsultationStage.review &&
          prev?.stage != ConsultationStage.review) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(AppPageRoute(page: const ReviewScreen()));
        });
      }
      if (next.stage == ConsultationStage.error &&
          prev?.stage != ConsultationStage.error &&
          next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              duration: const Duration(seconds: 10),
            ),
          );
        });
      }
    });

    final state = ref.watch(consultationProvider);
    final type = widget.consultationType;
    final wide = isWideLayout(context);
    final serverProcessing = state.stage == ConsultationStage.processing;
    final error = state.stage == ConsultationStage.error ? state.errorMessage : null;
    final showProgress = _finalizing || serverProcessing;

    return Shortcuts(
      shortcuts: isDesktopPlatform
          ? {const SingleActivator(LogicalKeyboardKey.space): const _ToggleRecordIntent()}
          : const {},
      child: Actions(
        actions: {
          _ToggleRecordIntent: CallbackAction<_ToggleRecordIntent>(
            onInvoke: (_) {
              if (!_finalizing && !serverProcessing) _toggleRecording();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: isDesktopPlatform,
          child: AppPage(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: serverProcessing ? null : () => Navigator.of(context).pop(),
            ),
            title: type.title,
            body: SingleChildScrollView(
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_backendOk == false)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Backend no disponible en ${AppConfig.apiBaseUrl}\n'
                          'Arranca: cd backend && source .venv/bin/activate && python -m app',
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      )
                    else if (_backendOk == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Conectado a ${AppConfig.apiBaseUrl}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                      ),
                    wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _ControlsPanel(
                              type: type,
                              patientIdController: _patientIdController,
                              patientIdFocus: _patientIdFocus,
                              recording: _recording,
                              finalizing: _finalizing,
                              serverProcessing: serverProcessing,
                              onToggleRecording: showProgress ? null : _toggleRecording,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: _TimelinePanel(
                              type: type,
                              recording: _recording,
                              finalizing: _finalizing,
                              serverProcessing: serverProcessing,
                              errorMessage: error,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ControlsPanel(
                            type: type,
                            patientIdController: _patientIdController,
                            patientIdFocus: _patientIdFocus,
                            recording: _recording,
                            finalizing: _finalizing,
                            serverProcessing: serverProcessing,
                            onToggleRecording: showProgress ? null : _toggleRecording,
                          ),
                          const SizedBox(height: 20),
                          _TimelinePanel(
                            type: type,
                            recording: _recording,
                            finalizing: _finalizing,
                            serverProcessing: serverProcessing,
                            errorMessage: error,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRecordIntent extends Intent {
  const _ToggleRecordIntent();
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
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
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoPill(
            icon: type.icon,
            label: type.shortLabel,
            color: type.accentColor,
            background: type.accentSoft,
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
                if (recording || finalizing)
                  FilledButton.icon(
                    onPressed: onToggleRecording,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(finalizing ? 'Finalizando…' : 'Detener grabación'),
                  ),
                if (!recording && !_busy)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      serverProcessing ? 'Enviando al servidor…' : 'Pulsa para grabar',
                      key: ValueKey(serverProcessing ? 'upload' : 'idle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                else if (recording)
                  Text(
                    'Grabando… pulsa detener o usa Espacio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                  ),
              ],
            ),
          ),
          if (isDesktopPlatform) ...[
            const SizedBox(height: 20),
            Text(
              'Atajo: Espacio (si el foco no está en un campo)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
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
    final recordingDone = !recording && (finalizing || serverProcessing || errorMessage != null);
    final steps = [
      _StepData('Grabación', Icons.mic_none_rounded, recording, recordingDone),
      _StepData(
        'Transcripción',
        Icons.graphic_eq_rounded,
        serverProcessing && !finalizing,
        false,
      ),
      _StepData('Borrador clínico', Icons.article_outlined, false, false),
    ];

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progreso', style: Theme.of(context).textTheme.titleMedium),
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
              finalizing
                  ? 'Guardando audio localmente…'
                  : 'Procesando en el servidor (STT + borrador)…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Text(errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          ],
          const SizedBox(height: 16),
          Text(type.subtitle, style: Theme.of(context).textTheme.bodySmall),
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
    final color = step.active
        ? AppColors.primary
        : step.done
            ? AppColors.success
            : AppColors.textTertiary;

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
                  color: step.active || step.done ? color.withValues(alpha: 0.12) : AppColors.surfaceMuted,
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
                    color: step.done ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
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
                        color: step.active || step.done ? AppColors.textPrimary : AppColors.textTertiary,
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
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
