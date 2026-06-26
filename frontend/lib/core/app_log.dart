import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger de desarrollo. SOLO emite en modo debug (`kDebugMode`); en release es
/// un no-op, para no volcar nunca datos clínicos en logs (CLAUDE.md §7.8).
///
/// Uso: `devLog('F2.ws', 'conectando a $uri')`. El [tag] agrupa por subsistema
/// y es greppable en la consola de Flutter / DevTools.
void devLog(String tag, String message) {
  if (!kDebugMode) return;
  developer.log(message, name: tag);
}
