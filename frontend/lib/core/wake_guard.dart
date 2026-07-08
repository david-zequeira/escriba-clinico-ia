import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:escriba_clinico/core/app_log.dart';

/// Evita que la pantalla (y con ella el equipo) se duerma mientras hay una
/// captura en curso: si el portátil se suspende, la grabación se corta. En web
/// usa la Screen Wake Lock API; en escritorio/móvil, la API nativa equivalente.
///
/// Puerto para poder inyectar un no-op en tests (el plugin no existe sin
/// plataforma) y para degradar sin romper si el sistema no lo soporta.
abstract class WakeGuard {
  /// Mantiene el equipo despierto. No debe lanzar: si no está disponible,
  /// simplemente no surte efecto (la captura sigue funcionando).
  Future<void> enable();

  /// Libera el bloqueo y deja que el equipo vuelva a su gestión de energía.
  Future<void> disable();
}

/// No hace nada. Default seguro en tests y en plataformas sin soporte.
class NoopWakeGuard implements WakeGuard {
  const NoopWakeGuard();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

/// Implementación real sobre `wakelock_plus`. Nunca propaga errores: un fallo al
/// (des)activar el wake lock no debe tumbar la grabación.
class WakelockWakeGuard implements WakeGuard {
  const WakelockWakeGuard();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
      devLog('wake', 'wake lock activado');
    } catch (e) {
      devLog('wake', 'no se pudo activar el wake lock: $e');
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
      devLog('wake', 'wake lock liberado');
    } catch (e) {
      devLog('wake', 'no se pudo liberar el wake lock: $e');
    }
  }
}

final wakeGuardProvider = Provider<WakeGuard>((ref) => const WakelockWakeGuard());
