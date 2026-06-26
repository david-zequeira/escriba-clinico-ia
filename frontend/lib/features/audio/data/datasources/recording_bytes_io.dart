import 'dart:io';
import 'dart:typed_data';

/// Nativo (escritorio/móvil): `record.stop()` devuelve una ruta de fichero.
Future<Uint8List?> fetchRecordingBytesImpl(String path) async {
  final file = File(path);
  if (await file.exists() && await file.length() > 0) {
    return file.readAsBytes();
  }
  return null;
}
