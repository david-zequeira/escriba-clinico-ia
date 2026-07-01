import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:escriba_clinico/core/app_log.dart';
import 'package:escriba_clinico/core/config.dart';

/// Fuente de datos de la transcripción en vivo. Emite *frames* crudos
/// (`Map<String, dynamic>`) tal y como llegan del backend; el mapeo a entidades
/// de dominio es responsabilidad del repositorio (igual que el datasource HTTP).
///
/// Contrato de frames servidor→cliente (ver `docs/07-contrato-streaming.md`):
/// ```json
/// { "type": "partial", "speaker": "medico|paciente|desconocido", "text": "…", "start_ms": 1200 }
/// { "type": "final",   "speaker": "…", "text": "…", "start_ms": 1200, "end_ms": 2600 }
/// { "type": "error",   "message": "…" }
/// { "type": "closed" }
/// ```
abstract class TranscriptionStreamSource {
  /// Abre el canal para [consultationId] y emite los frames crudos.
  Stream<Map<String, dynamic>> frames(String consultationId);

  /// Envía un chunk de audio PCM por el canal (para el STT en streaming real).
  Future<void> sendAudio(List<int> bytes);

  /// Pausa la emisión (control de sesión).
  Future<void> pause();

  /// Reanuda la emisión.
  Future<void> resume();

  /// Cierra el canal y libera recursos.
  Future<void> close();
}

/// Implementación real sobre `web_socket_channel`. No se ejercita hasta que el
/// backend exponga `ws://…/consultations/{id}/stream`; queda lista para que el
/// cambio sea de una sola línea en el provider (front-first con contrato).
class WebSocketTranscriptionSource implements TranscriptionStreamSource {
  WebSocketTranscriptionSource({this.token});

  /// Access token OIDC. El WS no admite cabeceras desde el navegador, así que el
  /// token viaja como query param (`?token=`), como espera el backend. Null en dev.
  final String? token;

  WebSocketChannel? _channel;

  /// Deriva la URL WS de la base HTTP del backend (`http→ws`, `https→wss`).
  Uri _streamUri(String consultationId) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      pathSegments: [...base.pathSegments, 'consultations', consultationId, 'stream'],
      queryParameters:
          (token != null && token!.isNotEmpty) ? {'token': token} : null,
    );
  }

  /// Expone la construcción de la URL para los tests (incluye `?token=`).
  @visibleForTesting
  Uri streamUriForTest(String consultationId) => _streamUri(consultationId);

  @override
  Stream<Map<String, dynamic>> frames(String consultationId) {
    final uri = _streamUri(consultationId);
    devLog('F2.ws', 'conectando a $uri');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    return channel.stream.map((raw) {
      final decoded = jsonDecode(raw as String);
      final frame = Map<String, dynamic>.from(decoded as Map);
      devLog('F2.ws', '← frame ${frame['type']} '
          '${frame['speaker'] ?? ''} "${frame['text'] ?? ''}"');
      return frame;
    });
  }

  @override
  Future<void> sendAudio(List<int> bytes) async {
    // Frame BINARIO: el backend lo entrega tal cual al STT en streaming.
    _channel?.sink.add(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  }

  @override
  Future<void> pause() async => _send({'type': 'pause'});

  @override
  Future<void> resume() async => _send({'type': 'resume'});

  void _send(Map<String, dynamic> control) {
    devLog('F2.ws', '→ control ${control['type']}');
    _channel?.sink.add(jsonEncode(control));
  }

  @override
  Future<void> close() async {
    devLog('F2.ws', 'cerrando canal');
    await _channel?.sink.close();
    _channel = null;
  }
}

/// Fuente *fake* para desarrollo y demo sin backend: reproduce una conversación
/// clínica simulada como una secuencia de parciales que crecen y se consolidan.
/// Respeta pausar/reanudar y nunca inventa datos en release porque solo se usa
/// como mock explícito de desarrollo (ver provider).
class FakeTranscriptionStreamSource implements TranscriptionStreamSource {
  FakeTranscriptionStreamSource({this.step = const Duration(milliseconds: 700)});

  /// Cadencia entre frames; configurable para acelerar los tests.
  final Duration step;

  bool _paused = false;
  bool _closed = false;

  /// Guion: cada turno se emite primero como parciales (prefijos crecientes) y
  /// luego como final. Conversación de ingreso verosímil en español.
  static const List<({String speaker, String text})> _script = [
    (speaker: 'medico', text: 'Buenos días, cuénteme qué le trae hoy a urgencias.'),
    (speaker: 'paciente', text: 'Llevo dos días con dolor en el pecho y me falta el aire al caminar.'),
    (speaker: 'medico', text: '¿El dolor aparece con el esfuerzo o también en reposo?'),
    (speaker: 'paciente', text: 'Sobre todo al subir escaleras, pero esta mañana también estando sentado.'),
    (speaker: 'medico', text: '¿Tiene antecedentes de hipertensión o alguna alergia conocida?'),
    (speaker: 'paciente', text: 'Soy hipertenso desde hace años y soy alérgico a la penicilina.'),
  ];

  @override
  Stream<Map<String, dynamic>> frames(String consultationId) async* {
    var elapsedMs = 0;
    for (final turn in _script) {
      if (_closed) return;
      final words = turn.text.split(' ');
      final startMs = elapsedMs;

      // Parciales: el texto va creciendo palabra a palabra.
      final buffer = StringBuffer();
      for (var i = 0; i < words.length; i++) {
        if (await _haltOrClosed()) return;
        buffer.write(i == 0 ? words[i] : ' ${words[i]}');
        yield {
          'type': 'partial',
          'speaker': turn.speaker,
          'text': buffer.toString(),
          'start_ms': startMs,
        };
      }

      if (await _haltOrClosed()) return;
      elapsedMs += words.length * 350 + 600;
      yield {
        'type': 'final',
        'speaker': turn.speaker,
        'text': turn.text,
        'start_ms': startMs,
        'end_ms': elapsedMs,
      };
    }
    if (!_closed) yield {'type': 'closed'};
  }

  /// Espera un [step], respetando la pausa. Devuelve `true` si hay que cortar.
  Future<bool> _haltOrClosed() async {
    await Future<void>.delayed(step);
    while (_paused && !_closed) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return _closed;
  }

  @override
  Future<void> sendAudio(List<int> bytes) async {
    // El mock no usa el audio: emite un guion fijo. Lo descarta.
  }

  @override
  Future<void> pause() async => _paused = true;

  @override
  Future<void> resume() async => _paused = false;

  @override
  Future<void> close() async => _closed = true;
}
