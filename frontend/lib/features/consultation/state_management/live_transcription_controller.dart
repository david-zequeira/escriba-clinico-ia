import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:escriba_clinico/features/audio/domain/repositories/audio_repository.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/transcription_stream_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/transcription_stream_repository.dart';

/// Estado del ciclo de captura en vivo (streaming).
enum LiveStatus { idle, connecting, listening, paused, stopped, error }

class LiveTranscriptionState {
  const LiveTranscriptionState({
    this.status = LiveStatus.idle,
    this.transcript = const Transcript(),
    this.amplitude = 0.0,
    this.errorMessage,
  });

  final LiveStatus status;

  /// Transcripción mostrada: segmentos finales + el parcial en curso al final.
  /// Solo se recrea cuando cambian los segmentos, no en cada tick de amplitud,
  /// para que el waveform pueda repintar sin reconstruir la lista.
  final Transcript transcript;

  /// Amplitud del micrófono normalizada (0..1) para el waveform en vivo.
  final double amplitude;

  final String? errorMessage;

  bool get isActive =>
      status == LiveStatus.listening || status == LiveStatus.paused;

  LiveTranscriptionState copyWith({
    LiveStatus? status,
    Transcript? transcript,
    double? amplitude,
    String? errorMessage,
  }) =>
      LiveTranscriptionState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        amplitude: amplitude ?? this.amplitude,
        errorMessage: errorMessage,
      );
}

/// Orquesta la captura en vivo: arranca el micrófono (para amplitud real y, en
/// el futuro, el envío de audio) y consume el stream de transcripción del
/// backend. No conoce ni WebSocket ni el plugin de audio: solo los puertos.
class LiveTranscriptionController extends StateNotifier<LiveTranscriptionState> {
  LiveTranscriptionController(this._audio, this._transcription)
      : super(const LiveTranscriptionState());

  final AudioRepository _audio;
  final TranscriptionStreamRepository _transcription;

  StreamSubscription<TranscriptionEvent>? _eventsSub;
  StreamSubscription<double>? _amplitudeSub;

  final List<TranscriptSegment> _finalized = [];
  TranscriptSegment? _partial;

  Future<void> start(String consultationId, {required String tempPath}) async {
    if (state.isActive) return;
    state = const LiveTranscriptionState(status: LiveStatus.connecting);
    _finalized.clear();
    _partial = null;

    try {
      await _audio.start(tempPath);
      _amplitudeSub = _audio.amplitudeStream().listen(
            (level) => state = state.copyWith(amplitude: level),
            onError: (_) {},
          );
      _eventsSub = _transcription.connect(consultationId).listen(
            _onEvent,
            onError: (e) => _fail(e.toString()),
            onDone: () {
              if (state.status == LiveStatus.listening) {
                state = state.copyWith(status: LiveStatus.stopped, amplitude: 0);
              }
            },
          );
      state = state.copyWith(status: LiveStatus.listening);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> pause() async {
    if (state.status != LiveStatus.listening) return;
    await _audio.pause();
    await _transcription.pause();
    state = state.copyWith(status: LiveStatus.paused, amplitude: 0);
  }

  Future<void> resume() async {
    if (state.status != LiveStatus.paused) return;
    await _transcription.resume();
    await _audio.resume();
    state = state.copyWith(status: LiveStatus.listening);
  }

  Future<void> stop() async {
    if (state.status == LiveStatus.idle) return;
    await _teardown();
    state = state.copyWith(status: LiveStatus.stopped, amplitude: 0);
  }

  void _onEvent(TranscriptionEvent event) {
    switch (event) {
      case TranscriptPartial(:final segment):
        _partial = segment;
        _rebuildTranscript();
      case TranscriptFinal(:final segment):
        _finalized.add(segment);
        _partial = null;
        _rebuildTranscript();
      case TranscriptStreamError(:final message):
        _fail(message);
      case TranscriptStreamClosed():
        unawaited(_teardown());
        state = state.copyWith(status: LiveStatus.stopped, amplitude: 0);
    }
  }

  void _rebuildTranscript() {
    final segments = [
      ..._finalized,
      if (_partial != null) _partial!,
    ];
    state = state.copyWith(transcript: Transcript(segments: segments));
  }

  void _fail(String message) {
    unawaited(_teardown());
    state = state.copyWith(
      status: LiveStatus.error,
      amplitude: 0,
      errorMessage: message,
    );
  }

  Future<void> _teardown() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _eventsSub?.cancel();
    _eventsSub = null;
    await _transcription.close();
    try {
      await _audio.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _eventsSub?.cancel();
    unawaited(_transcription.close());
    super.dispose();
  }
}

final liveTranscriptionProvider =
    StateNotifierProvider<LiveTranscriptionController, LiveTranscriptionState>(
  (ref) => LiveTranscriptionController(
    ref.watch(audioRepositoryProvider),
    ref.watch(transcriptionStreamRepositoryProvider),
  ),
);
