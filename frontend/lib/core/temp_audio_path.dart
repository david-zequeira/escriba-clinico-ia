import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Devuelve una ruta temporal para la grabación según la plataforma.
///
/// En **web** no hay sistema de ficheros (path_provider lanza
/// MissingPluginException en `getTemporaryDirectory`): el plugin `record` graba
/// a un blob e ignora la ruta, así que devolvemos cadena vacía.
Future<String> tempAudioPath({String prefix = 'consulta', String ext = 'wav'}) async {
  if (kIsWeb) return '';
  final dir = await getTemporaryDirectory();
  return '${dir.path}/$prefix-${DateTime.now().millisecondsSinceEpoch}.$ext';
}
