import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/core/config.dart';
import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/core/temp_audio_path.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/presentation/screens/review_screen.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/live_controls_panel.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/transcript_panel.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/features/consultation/state_management/live_transcription_controller.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Captura de la consulta (flujo unificado).
///
/// Una sola pantalla para todo el viaje: identidad del paciente + consentimiento
/// → captura con **transcripción en vivo** (streaming) y waveform real →
/// **Finalizar** genera el borrador y abre la revisión médica. Sustituye a las
/// antiguas pantallas separadas de grabación y de transcripción en vivo.
class ConsultationCaptureScreen extends ConsumerStatefulWidget {
  const ConsultationCaptureScreen({super.key, required this.consultationType});

  final ConsultationType consultationType;

  @override
  ConsumerState<ConsultationCaptureScreen> createState() =>
      _ConsultationCaptureScreenState();
}

class _ConsultationCaptureScreenState
    extends ConsumerState<ConsultationCaptureScreen> {
  final _patientIdController = TextEditingController();
  final _patientIdFocus = FocusNode();
  bool? _backendOk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consultationProvider.notifier).selectType(widget.consultationType);
      _checkBackend();
    });
  }

  @override
  void dispose() {
    // Libera micrófono/canal si se sale con la sesión activa.
    if (ref.read(liveTranscriptionProvider).isActive) {
      ref.read(liveTranscriptionProvider.notifier).stop();
    }
    _patientIdController.dispose();
    _patientIdFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final ok = await ref.read(consultationRepositoryProvider).isBackendReachable();
    if (mounted) setState(() => _backendOk = ok);
  }

  Future<bool> _confirmConsentIfNeeded() async {
    if (widget.consultationType != ConsultationType.admissionInterview) {
      return true;
    }
    final l = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.tokens.warningSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.privacy_tip_outlined, color: context.tokens.warning),
        ),
        title: Text(l.consentTitle),
        content: Text(l.consentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
        ],
      ),
    );
    return accepted ?? false;
  }

  /// Inicia la sesión: valida paciente y consentimiento, crea la consulta real
  /// en el backend y arranca el streaming en vivo con ese id.
  Future<void> _start() async {
    final l = context.l10n;
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.patientIdRequired)));
      _patientIdFocus.requestFocus();
      return;
    }
    if (!await _confirmConsentIfNeeded()) return;
    if (!mounted) return;

    final id = await ref.read(consultationProvider.notifier).beginSession(patientId);
    if (id == null) return; // el error se muestra vía ref.listen
    if (!mounted) return;

    try {
      final tempPath = await tempAudioPath(prefix: 'live');
      _patientIdFocus.unfocus();
      await ref.read(liveTranscriptionProvider.notifier).start(id, tempPath: tempPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Finaliza: detiene la captura conservando el audio y lo manda al pipeline
  /// para generar el borrador. La navegación a revisión la dispara `ref.listen`.
  Future<void> _finish() async {
    final l = context.l10n;
    final audio = await ref.read(liveTranscriptionProvider.notifier).finishCapture();
    if (!mounted) return;
    if (audio == null || audio.bytes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.emptyRecording)));
      return;
    }
    await ref.read(consultationProvider.notifier).finalizeWithAudio(
          audio.bytes,
          filename: audio.filename,
        );
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

    final l = context.l10n;
    final type = widget.consultationType;
    final wide = isWideLayout(context);
    final liveNotifier = ref.read(liveTranscriptionProvider.notifier);

    final status = ref.watch(liveTranscriptionProvider.select((s) => s.status));
    final amplitude =
        ref.watch(liveTranscriptionProvider.select((s) => s.amplitude));
    final liveError =
        ref.watch(liveTranscriptionProvider.select((s) => s.errorMessage));
    final transcript =
        ref.watch(liveTranscriptionProvider.select((s) => s.transcript));
    // Tras Finalizar, el borrador se genera en el backend: bloquea controles.
    final generatingDraft = ref.watch(
        consultationProvider.select((s) => s.stage == ConsultationStage.processing));

    final active = status == LiveStatus.listening || status == LiveStatus.paused;

    final controls = LiveControlsPanel(
      type: type,
      status: status,
      amplitude: amplitude,
      errorMessage: liveError,
      generatingDraft: generatingDraft,
      patientIdController: _patientIdController,
      patientIdFocus: _patientIdFocus,
      patientIdEnabled: !active && !generatingDraft,
      onStart: generatingDraft ? null : _start,
      onPause: liveNotifier.pause,
      onResume: liveNotifier.resume,
      onStop: _finish,
    );

    final transcriptPanel = TranscriptPanel(
      transcript: transcript,
      title: l.liveTranscriptTitle,
    );

    return AppPage(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: generatingDraft ? null : () => Navigator.of(context).pop(),
      ),
      title: type.title(l),
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
                    color: context.tokens.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: context.tokens.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${l.backendUnavailable(AppConfig.apiBaseUrl)}\n'
                    '${l.backendStartHint}',
                    style: TextStyle(color: context.tokens.error, fontSize: 13),
                  ),
                )
              else if (_backendOk == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.connectedTo(AppConfig.apiBaseUrl),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.success,
                        ),
                  ),
                ),
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: controls),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: transcriptPanel),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        controls,
                        const SizedBox(height: 20),
                        transcriptPanel,
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
