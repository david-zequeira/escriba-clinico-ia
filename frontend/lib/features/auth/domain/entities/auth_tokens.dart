/// Tokens OIDC emitidos por el IdP. Solo se guardan tokens (nunca datos
/// clínicos) en el almacenamiento seguro (§6).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  /// Momento de expiración del access token (si el IdP lo informó).
  final DateTime? expiresAt;

  /// True si el access token ya expiró (con margen de 30 s para el reloj).
  bool get isExpired {
    final at = expiresAt;
    if (at == null) return false;
    return DateTime.now().isAfter(at.subtract(const Duration(seconds: 30)));
  }

  bool get canRefresh => (refreshToken ?? '').isNotEmpty;
}
