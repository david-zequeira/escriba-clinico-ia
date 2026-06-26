import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:escriba_clinico/core/config.dart';
import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/presentation/screens/review_screen.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/recording_controls_panel.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/recording_timeline_panel.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Captura de audio y envío al backend.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key, required this.consultationType});

  final ConsultationType consultationType;

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  late final _audio = ref.read(audioRepositoryProvider);
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
    final ok = await ref.read(consultationRepositoryProvider).isBackendReachable();
    if (mounted) setState(() => _backendOk = ok);
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientIdFocus.dispose();
    _audio.dispose();
    super.dispose();
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

  Future<void> _toggleRecording() async {
    final state = ref.read(consultationProvider);
    final l = context.l10n;
    if (_finalizing || state.stage == ConsultationStage.processing) return;

    if (_recording) {
      setState(() {
        _finalizing = true;
        _recording = false;
      });

      try {
        final tempPath = _tempPath;
        if (tempPath == null) {
          throw StateError(l.audioPathUnavailable);
        }

        final audio = await _audio.stop(tempPath: tempPath);
        if (audio.bytes.isEmpty) {
          throw StateError(l.emptyRecording);
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
        SnackBar(content: Text(l.patientIdRequired)),
      );
      _patientIdFocus.requestFocus();
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final ext = _audio.preferredExtension;
      _tempPath = '${dir.path}/consulta-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _audio.start(_tempPath!);
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

    // select: esta pantalla solo se reconstruye cuando cambian la etapa o el error,
    // no ante cualquier cambio del estado de consulta.
    final stage = ref.watch(consultationProvider.select((s) => s.stage));
    final error = ref.watch(consultationProvider
        .select((s) => s.stage == ConsultationStage.error ? s.errorMessage : null));
    final l = context.l10n;
    final type = widget.consultationType;
    final wide = isWideLayout(context);
    final serverProcessing = stage == ConsultationStage.processing;
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
                          Expanded(
                            flex: 5,
                            child: RecordingControlsPanel(
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
                            child: RecordingTimelinePanel(
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
                          RecordingControlsPanel(
                            type: type,
                            patientIdController: _patientIdController,
                            patientIdFocus: _patientIdFocus,
                            recording: _recording,
                            finalizing: _finalizing,
                            serverProcessing: serverProcessing,
                            onToggleRecording: showProgress ? null : _toggleRecording,
                          ),
                          const SizedBox(height: 20),
                          RecordingTimelinePanel(
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

