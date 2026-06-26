import 'package:escriba_clinico/features/audio/domain/entities/recorded_audio.dart';

/// Puerto del dominio para la captura de audio. La presentación depende de esta
/// interfaz, no del plugin de grabación concreto (intercambiable / testeable).
abstract class AudioRepository {
  /// Extensión preferida del fichero según la plataforma (wav/m4a).
  String get preferredExtension;

  /// ¿Hay permiso de micrófono concedido?
  Future<bool> hasPermission();

  /// Inicia la grabación (a un fichero temporal en plataformas de archivo).
  Future<void> start(String tempPath);

  /// Pausa la captura sin cerrar la sesión (control de sesión en vivo).
  Future<void> pause();

  /// Reanuda la captura tras una pausa.
  Future<void> resume();

  /// Amplitud del micrófono normalizada a `0..1` (0 = silencio, 1 = máximo).
  /// Alimenta el waveform en vivo con la energía real de la señal.
  Stream<double> amplitudeStream({Duration interval});

  /// Detiene y devuelve el audio capturado.
  Future<RecordedAudio> stop({required String tempPath});

  /// Libera el micrófono y los recursos nativos.
  Future<void> dispose();
}
