import 'dart:typed_data';

import 'recording_bytes_io.dart'
    if (dart.library.html) 'recording_bytes_web.dart';

/// Lee los bytes de una grabación a partir de lo que devuelve `record.stop()`.
///
/// - En **nativo** es una ruta de fichero → se lee del disco.
/// - En **web** es una URL blob (`blob:…`) → se descarga vía XHR.
///
/// La implementación concreta se elige por import condicional según la plataforma.
Future<Uint8List?> fetchRecordingBytes(String pathOrUrl) =>
    fetchRecordingBytesImpl(pathOrUrl);
