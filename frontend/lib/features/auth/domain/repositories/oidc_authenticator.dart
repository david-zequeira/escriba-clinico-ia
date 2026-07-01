import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';

/// Puerto de la interacción OIDC con el IdP (Authorization Code + PKCE).
///
/// Aísla la librería concreta (openid_client / flutter_appauth / oidc): el
/// repositorio y la UI no la conocen. Los tests usan un doble; la implementación
/// real abre el navegador del sistema y recoge la redirección.
abstract class OidcAuthenticator {
  /// Lanza el flujo de login (redirección al IdP) y devuelve los tokens.
  Future<AuthTokens> signIn();

  /// Renueva el access token con el refresh token. Devuelve null si no se pudo.
  Future<AuthTokens?> refresh(String refreshToken);

  /// Cierra la sesión en el IdP (best-effort).
  Future<void> signOut(String? idToken);
}
