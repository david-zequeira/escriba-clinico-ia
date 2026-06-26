import 'dart:typed_data';

/// Audio capturado listo para subir al backend. Entidad de dominio.
class RecordedAudio {
  const RecordedAudio({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
