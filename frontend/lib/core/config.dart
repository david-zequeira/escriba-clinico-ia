/// Configuración de la app. En producción, inyectar por entorno.
class AppConfig {
  /// URL del backend (alojado en la UE).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
