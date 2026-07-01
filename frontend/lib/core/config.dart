/// Configuración de la app. En producción, inyectar por entorno.
class AppConfig {
  /// URL del backend (alojado en la UE).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // --- OIDC (IdP del hospital: Keycloak u equivalente, residencia UE) ---
  // Se inyectan por --dart-define. Si `oidcIssuer` está vacío, la app opera en
  // modo dev (login simulado contra AUTH_DEV_BYPASS del backend) y no muestra SSO.

  /// Emisor OIDC, p. ej. `http://localhost:8080/realms/vionix`.
  static const String oidcIssuer = String.fromEnvironment('OIDC_ISSUER');

  /// Client id público de la app (Authorization Code + PKCE).
  static const String oidcClientId = String.fromEnvironment(
    'OIDC_CLIENT_ID',
    defaultValue: 'vionix-app',
  );

  /// Redirect URI registrado en el IdP. En escritorio/móvil, un loopback o
  /// esquema propio (`vionix://auth`); en web, la URL de la app.
  static const String oidcRedirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'http://localhost:4000',
  );

  /// Scopes solicitados. `offline_access` habilita refresh token.
  static const List<String> oidcScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  /// True si hay un IdP configurado (habilita el login SSO real).
  static bool get oidcConfigured => oidcIssuer.isNotEmpty;
}
