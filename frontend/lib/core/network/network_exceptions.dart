import 'package:dio/dio.dart';

/// Traduce errores de red de Dio a mensajes accionables para el médico.
/// Vive en core para reutilizarse en todos los datasources.
Exception friendlyApiError(String action, String baseUrl, DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return Exception(
      'No se pudo conectar con el backend ($baseUrl) al $action.\n'
      '¿Está arrancado? cd backend && source .venv/bin/activate && python -m app',
    );
  }
  final detail = e.response?.data?.toString() ?? e.message;
  return Exception('Error al $action: $detail');
}
