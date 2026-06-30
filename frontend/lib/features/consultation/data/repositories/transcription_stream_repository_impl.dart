import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/consultation/data/datasources/transcription_stream_source.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/transcription_stream_repository.dart';

/// Traduce los *frames* crudos de la fuente a [TranscriptionEvent] de dominio.
/// Es la ÚNICA capa que conoce el formato JSON del streaming.
class TranscriptionStreamRepositoryImpl implements TranscriptionStreamRepository {
  TranscriptionStreamRepositoryImpl(this._source);

  final TranscriptionStreamSource _source;

  @override
  Stream<TranscriptionEvent> connect(String consultationId) {
    return _source.frames(consultationId).map(_mapFrame);
  }

  TranscriptionEvent _mapFrame(Map<String, dynamic> f) {
    switch (f['type'] as String?) {
      case 'partial':
        return TranscriptPartial(_segment(f, isPartial: true));
      case 'final':
        return TranscriptFinal(_segment(f, isPartial: false));
      case 'error':
        return TranscriptStreamError(
          f['message'] as String? ?? 'Error de transcripción',
        );
      case 'closed':
        return const TranscriptStreamClosed();
      default:
        return TranscriptStreamError('Frame de transcripción desconocido: ${f['type']}');
    }
  }

  TranscriptSegment _segment(Map<String, dynamic> f, {required bool isPartial}) {
    return TranscriptSegment(
      speaker: Speaker.fromApi(f['speaker'] as String?),
      text: f['text'] as String? ?? '',
      startMs: f['start_ms'] as int?,
      endMs: f['end_ms'] as int?,
      isPartial: isPartial,
    );
  }

  @override
  Future<void> sendAudio(List<int> bytes) => _source.sendAudio(bytes);

  @override
  Future<void> pause() => _source.pause();

  @override
  Future<void> resume() => _source.resume();

  @override
  Future<void> close() => _source.close();
}

/// Fuente de la transcripción en vivo.
///
/// Conectada al backend real vía WebSocket (`ws://…/consultations/{id}/stream`).
/// Para volver a la demo sin backend, sustituir por `FakeTranscriptionStreamSource()`.
///
/// Nota: hoy el backend responde con un proveedor *mock* (guion fijo) y no
/// transcribe el audio real; eso llegará con el proveedor STT en streaming real
/// (Gladia Real-Time). Aun así, esta ruta ya ejercita la tubería completa.
final transcriptionStreamSourceProvider = Provider<TranscriptionStreamSource>(
  (ref) => WebSocketTranscriptionSource(),
);

final transcriptionStreamRepositoryProvider =
    Provider<TranscriptionStreamRepository>((ref) {
  return TranscriptionStreamRepositoryImpl(
    ref.watch(transcriptionStreamSourceProvider),
  );
});
