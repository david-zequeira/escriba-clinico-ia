import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';

import 'package:escriba_clinico/features/audio/data/datasources/recording_bytes.dart';
import 'package:escriba_clinico/features/audio/domain/entities/recorded_audio.dart';

/// Fuente de datos de captura de audio multiplataforma (plugin `record`).
/// Detalle de infraestructura: stream/PCM en escritorio, fichero en móvil.
class AudioRecorderDataSource {
  AudioRecorderDataSource();

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _streamSub;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  bool _streaming = false;
  DateTime? _startedAt;

  static const int _sampleRate = 16000;
  static const int _numChannels = 1;

  /// Suelo de dBFS que mapeamos a 0 en el waveform. Por debajo es "silencio".
  static const double _amplitudeFloorDb = -50.0;

  RecordConfig get _fileConfig {
    if (!_isDesktop) return const RecordConfig();
    return const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: _sampleRate,
      numChannels: _numChannels,
    );
  }

  RecordConfig get _streamConfig => const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
      );

  String get preferredExtension {
    if (!_isDesktop) return 'm4a';
    return 'wav';
  }

  /// macOS: el modo archivo de `record_darwin` finaliza el fichero en un callback
  /// nativo asíncrono. Stream + WAV en memoria evita ficheros temporales frágiles.
  /// `!kIsWeb` primero: en web `Platform` lanza `Unsupported operation`.
  bool get _useStreamOnDesktop => !kIsWeb && Platform.isMacOS;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start(String tempPath) async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Sin permiso de micrófono. Actívalo en Ajustes del sistema.');
    }

    if (_useStreamOnDesktop) {
      _pcmBuffer.clear();
      final stream = await _recorder.startStream(_streamConfig);
      _streaming = true;
      _streamSub = stream.listen(_pcmBuffer.add);
    } else {
      await _recorder.start(_fileConfig, path: tempPath);
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!await _recorder.isRecording()) {
      await _resetRecorder();
      throw StateError(
        'No se pudo iniciar la grabación. Comprueba el micrófono en Ajustes del sistema.',
      );
    }
    _startedAt = DateTime.now();
  }

  /// Pausa la captura sin cerrar la sesión (el micrófono sigue reservado).
  Future<void> pause() => _recorder.pause();

  /// Reanuda la captura tras una pausa.
  Future<void> resume() => _recorder.resume();

  /// Amplitud del micrófono normalizada a `0..1`. El plugin reporta dBFS
  /// (≤ 0, con valores muy negativos en silencio): lo mapeamos desde el suelo
  /// [_amplitudeFloorDb] hasta 0 dB. Cancela limpio al cerrar la suscripción.
  Stream<double> amplitudeStream({
    Duration interval = const Duration(milliseconds: 120),
  }) {
    return _recorder.onAmplitudeChanged(interval).map((a) {
      final db = a.current;
      if (db.isNaN || db.isInfinite) return 0.0;
      final normalized = (db - _amplitudeFloorDb) / (0 - _amplitudeFloorDb);
      return normalized.clamp(0.0, 1.0);
    });
  }

  /// Detiene la grabación y devuelve los bytes del audio.
  Future<RecordedAudio> stopRecording({required String tempPath}) async {
    if (_startedAt != null &&
        DateTime.now().difference(_startedAt!) < const Duration(milliseconds: 800)) {
      throw StateError('Graba al menos un segundo antes de detener.');
    }

    if (kIsWeb) {
      return _stopWebRecording();
    }
    if (_streaming) {
      return _stopStreamRecording();
    }
    return _stopFileRecording(tempPath);
  }

  /// Web: `record` graba a un blob; `stop()` devuelve una URL `blob:…` que
  /// descargamos para obtener los bytes (no hay sistema de ficheros).
  Future<RecordedAudio> _stopWebRecording() async {
    String? url;
    try {
      url = await _recorder.stop().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Seguimos: intentamos recuperar el blob de todos modos.
    }

    final bytes = url != null ? await fetchRecordingBytes(url) : null;
    await _resetRecorder();
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'La grabación está vacía. Comprueba el permiso de micrófono del navegador.',
      );
    }
    return RecordedAudio(bytes: bytes, filename: 'consulta.webm');
  }

  Future<RecordedAudio> _stopStreamRecording() async {
    try {
      await _streamSub?.cancel();
      _streamSub = null;
      await _recorder.stop().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Seguimos con el buffer PCM acumulado.
    } finally {
      _streaming = false;
      _startedAt = null;
    }

    final pcm = _pcmBuffer.toBytes();
    if (pcm.isEmpty) {
      await _resetRecorder();
      throw StateError(
        'La grabación está vacía. Comprueba que el micrófono esté activo en Ajustes del sistema.',
      );
    }

    final wavBytes = _buildWavBytes(pcm);
    await _resetRecorder();
    return RecordedAudio(bytes: wavBytes, filename: 'consulta.wav');
  }

  Future<RecordedAudio> _stopFileRecording(String tempPath) async {
    String? path;

    try {
      path = await _recorder.stop().timeout(const Duration(seconds: 15));
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          final bytes = await file.readAsBytes();
          await _resetRecorder();
          return RecordedAudio(
            bytes: bytes,
            filename: 'consulta.${_extensionFromPath(path)}',
          );
        }
      }
    } catch (_) {
      // El plugin puede tardar en volcar el fichero; esperamos abajo.
    }

    final resolved = await _waitForAudioFile([tempPath, if (path != null && path.isNotEmpty) path]);
    if (resolved != null) {
      final bytes = await File(resolved).readAsBytes();
      await _resetRecorder();
      return RecordedAudio(
        bytes: bytes,
        filename: 'consulta.${_extensionFromPath(resolved)}',
      );
    }

    try {
      await _recorder.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}

    await _resetRecorder();
    throw StateError('No se pudo guardar la grabación. Prueba de nuevo.');
  }

  String _extensionFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return preferredExtension;
    return path.substring(dot + 1);
  }

  /// Espera a que aparezca un fichero con contenido (AVCapture escribe en async).
  Future<String?> _waitForAudioFile(List<String> paths) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      for (final p in paths) {
        final file = File(p);
        if (await file.exists() && await file.length() > 0) return p;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }

  Uint8List _buildWavBytes(Uint8List pcm) {
    final header = _wavHeader(pcm.length);
    final wav = Uint8List(header.length + pcm.length);
    wav.setRange(0, header.length, header);
    wav.setRange(header.length, wav.length, pcm);
    return wav;
  }

  Uint8List _wavHeader(int dataSize) {
    const byteRate = _sampleRate * _numChannels * 2;
    const blockAlign = _numChannels * 2;
    final fileSize = 36 + dataSize;

    final header = BytesBuilder();
    void writeString(String s) => header.add(s.codeUnits);
    void writeInt32(int v) {
      header.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    }

    void writeInt16(int v) => header.add([v & 0xff, (v >> 8) & 0xff]);

    writeString('RIFF');
    writeInt32(fileSize);
    writeString('WAVE');
    writeString('fmt ');
    writeInt32(16);
    writeInt16(1);
    writeInt16(_numChannels);
    writeInt32(_sampleRate);
    writeInt32(byteRate);
    writeInt16(blockAlign);
    writeInt16(16);
    writeString('data');
    writeInt32(dataSize);

    return Uint8List.fromList(header.toBytes());
  }

  Future<void> _resetRecorder() async {
    _startedAt = null;
    _streaming = false;
    try {
      await _streamSub?.cancel();
    } catch (_) {}
    _streamSub = null;
    _pcmBuffer.clear();
    try {
      await _recorder.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {}
    _recorder = AudioRecorder();
  }

  Future<void> dispose() async {
    await _resetRecorder();
  }
}
