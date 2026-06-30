import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';

/// Evento de la transcripción en vivo (streaming). Entidad de dominio: la
/// presentación reacciona a estos eventos sin conocer el transporte (WebSocket)
/// ni el formato JSON del backend.
///
/// Modelo de utterance único: en cada momento hay como mucho un segmento
/// [TranscriptPartial] "en curso"; cuando el interlocutor termina llega un
/// [TranscriptFinal] que lo consolida y reinicia el parcial.
sealed class TranscriptionEvent {
  const TranscriptionEvent();
}

/// Resultado parcial (interino): el texto del segmento actual aún puede cambiar.
class TranscriptPartial extends TranscriptionEvent {
  const TranscriptPartial(this.segment);

  final TranscriptSegment segment;
}

/// Segmento consolidado: ya no cambiará.
class TranscriptFinal extends TranscriptionEvent {
  const TranscriptFinal(this.segment);

  final TranscriptSegment segment;
}

/// Error reportado por el canal de transcripción.
class TranscriptStreamError extends TranscriptionEvent {
  const TranscriptStreamError(this.message);

  final String message;
}

/// El backend cerró el canal de forma ordenada (fin de la consulta).
class TranscriptStreamClosed extends TranscriptionEvent {
  const TranscriptStreamClosed();
}
