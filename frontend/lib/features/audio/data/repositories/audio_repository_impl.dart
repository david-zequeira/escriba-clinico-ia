import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/audio/data/datasources/audio_recorder_datasource.dart';
import 'package:escriba_clinico/features/audio/domain/entities/recorded_audio.dart';
import 'package:escriba_clinico/features/audio/domain/repositories/audio_repository.dart';

/// Implementación del repositorio de audio sobre el datasource de captura.
class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(this._source);

  final AudioRecorderDataSource _source;

  @override
  String get preferredExtension => _source.preferredExtension;

  @override
  Future<bool> hasPermission() => _source.hasPermission();

  @override
  Future<void> start(String tempPath) => _source.start(tempPath);

  @override
  Future<RecordedAudio> stop({required String tempPath}) =>
      _source.stopRecording(tempPath: tempPath);

  @override
  Future<void> dispose() => _source.dispose();
}

/// El grabador mantiene estado (buffer/mic) entre start y stop, por eso es un
/// singleton. La pantalla de grabación llama a `dispose()` al salir para liberar
/// el micrófono (el datasource recrea su grabador interno en el siguiente start).
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepositoryImpl(AudioRecorderDataSource());
});
