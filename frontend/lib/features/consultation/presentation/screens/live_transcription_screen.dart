import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/live_controls_panel.dart';
import 'package:escriba_clinico/features/consultation/presentation/widgets/transcript_panel.dart';
import 'package:escriba_clinico/features/consultation/state_management/live_transcription_controller.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Captura en vivo (F2): muestra la transcripción en streaming conforme avanza
/// la consulta y un waveform con la amplitud real del micrófono. El audio se
/// procesa al vuelo y no se persiste (minimización del audio, ver CLAUDE.md §7).
class LiveTranscriptionScreen extends ConsumerStatefulWidget {
  const LiveTranscriptionScreen({super.key, required this.consultationType});

  final ConsultationType consultationType;

  @override
  ConsumerState<LiveTranscriptionScreen> createState() =>
      _LiveTranscriptionScreenState();
}

class _LiveTranscriptionScreenState
    extends ConsumerState<LiveTranscriptionScreen> {
  /// Sesión local. Cuando exista el backend WS se sustituirá por el id real
  /// devuelto al crear la consulta (cambio aislado, front-first con contrato).
  late final String _consultationId =
      'live-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    // Asegura liberar micrófono/canal si se sale con la sesión activa.
    final notifier = ref.read(liveTranscriptionProvider.notifier);
    if (ref.read(liveTranscriptionProvider).isActive) {
      notifier.stop();
    }
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

  Future<void> _start() async {
    if (!await _confirmConsentIfNeeded()) return;
    if (!mounted) return;
    try {
      final dir = await getTemporaryDirectory();
      final tempPath =
          '${dir.path}/live-${DateTime.now().millisecondsSinceEpoch}.wav';
      await ref
          .read(liveTranscriptionProvider.notifier)
          .start(_consultationId, tempPath: tempPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final type = widget.consultationType;
    final wide = isWideLayout(context);
    final notifier = ref.read(liveTranscriptionProvider.notifier);

    final status = ref.watch(liveTranscriptionProvider.select((s) => s.status));
    final amplitude =
        ref.watch(liveTranscriptionProvider.select((s) => s.amplitude));
    final error =
        ref.watch(liveTranscriptionProvider.select((s) => s.errorMessage));
    final transcript =
        ref.watch(liveTranscriptionProvider.select((s) => s.transcript));

    final controls = LiveControlsPanel(
      type: type,
      status: status,
      amplitude: amplitude,
      errorMessage: error,
      onStart: _start,
      onPause: notifier.pause,
      onResume: notifier.resume,
      onStop: notifier.stop,
    );

    final transcriptPanel = TranscriptPanel(
      transcript: transcript,
      title: l.liveTranscriptTitle,
    );

    return AppPage(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: type.title(l),
      body: SingleChildScrollView(
        child: FadeSlideIn(
          child: wide
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
        ),
      ),
    );
  }
}
