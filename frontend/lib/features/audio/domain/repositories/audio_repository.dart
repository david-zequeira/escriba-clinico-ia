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

  /// Detiene y devuelve el audio capturado.
  Future<RecordedAudio> stop({required String tempPath});

  /// Libera el micrófono y los recursos nativos.
  Future<void> dispose();
}
