// dart:html sigue siendo la vía simple para XHR en web; aislado tras import condicional.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web: `record.stop()` devuelve una URL blob (`blob:…`). La descargamos con
/// XHR (arraybuffer) para obtener los bytes del audio grabado en el navegador.
Future<Uint8List?> fetchRecordingBytesImpl(String url) async {
  if (url.isEmpty) return null;
  final completer = Completer<Uint8List?>();
  final req = html.HttpRequest()
    ..open('GET', url)
    ..responseType = 'arraybuffer';
  req.onLoad.listen((_) {
    final response = req.response;
    if (response is ByteBuffer) {
      completer.complete(response.asUint8List());
    } else {
      completer.complete(null);
    }
  });
  req.onError.listen((_) => completer.complete(null));
  req.send();
  return completer.future;
}
