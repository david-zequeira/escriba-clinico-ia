import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/core/config.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';

/// Adjunta el token OIDC como `Authorization: Bearer` si hay sesión. Puro y sin
/// dependencias de Riverpod para poder probarlo de forma aislada.
void applyAuthHeader(RequestOptions options, String? token) {
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
}

/// Dio configurado y compartido por todos los datasources remotos.
/// Interceptores: auth OIDC (Bearer) y cierre de sesión ante 401.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Se lee el token vigente en cada petición (no se cachea): tras refresh
        // o logout, la siguiente petición usa el valor correcto.
        applyAuthHeader(options, ref.read(authProvider).accessToken);
        handler.next(options);
      },
      onError: (error, handler) {
        // Token inválido/expirado: cerrar sesión para forzar re-login. No se
        // loguea el token ni el cuerpo (sin PHI, §7.8).
        if (error.response?.statusCode == 401) {
          ref.read(authProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
