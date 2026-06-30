import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';

/// Puerto del dominio para la transcripción en vivo de una consulta.
///
/// La capa de presentación depende de ESTA interfaz, nunca del transporte
/// concreto (WebSocket) ni de una fuente *fake*. Así el backend, el mock de
/// desarrollo y los tests son intercambiables (principio front-first / Clase I).
abstract class TranscriptionStreamRepository {
  /// Abre el canal y emite los [TranscriptionEvent] conforme avanza la consulta.
  /// El stream se cierra al llamar [close] o cuando el backend termina.
  Stream<TranscriptionEvent> connect(String consultationId);

  /// Envía un chunk de audio del micrófono por el canal (STT en streaming real).
  Future<void> sendAudio(List<int> bytes);

  /// Pausa la sesión: el backend deja de enviar segmentos hasta [resume].
  Future<void> pause();

  /// Reanuda la sesión tras una pausa.
  Future<void> resume();

  /// Cierra el canal y libera los recursos.
  Future<void> close();
}
