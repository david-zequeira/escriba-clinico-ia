import 'package:record/record.dart';

/// Captura de audio multiplataforma. Pide consentimiento del paciente ANTES de grabar.
class ConsultationRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Inicia la grabación a un archivo temporal local (se borra tras subir).
  Future<void> start(String tempPath) async {
    if (await _recorder.hasPermission()) {
      await _recorder.start(const RecordConfig(), path: tempPath);
    }
  }

  /// Detiene y devuelve la ruta del archivo grabado.
  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}
