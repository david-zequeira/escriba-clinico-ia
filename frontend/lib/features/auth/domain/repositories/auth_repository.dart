import 'package:escriba_clinico/features/auth/domain/entities/auth_session.dart';

/// Puerto del dominio para autenticación.
///
/// Dos vías: **SSO OIDC** (real, contra el IdP del hospital) y **login dev**
/// (simulado, para trabajar sin IdP contra `AUTH_DEV_BYPASS` del backend). La
/// presentación no sabe cuál se usa.
abstract class AuthRepository {
  /// Login real vía OIDC (redirección al IdP). Guarda los tokens.
  Future<AuthSession> loginWithSso();

  /// Login simulado de desarrollo (sin IdP). No emite tokens reales.
  Future<AuthSession> loginDev({required String user, required String password});

  /// Restaura la sesión desde los tokens guardados (o null si no hay/expiró).
  Future<AuthSession?> restoreSession();

  /// Cierra la sesión: limpia tokens locales y notifica al IdP (best-effort).
  Future<void> logout();
}
