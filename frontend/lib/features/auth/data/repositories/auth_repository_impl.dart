import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/auth/data/datasources/token_store.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_session.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';
import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/oidc_authenticator.dart';

/// Autenticación real vía OIDC + almacenamiento seguro de tokens.
///
/// La interacción con el IdP se delega en [OidcAuthenticator] (puerto): esta
/// clase no conoce la librería concreta y se puede probar con dobles.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._oidc, this._store);

  final OidcAuthenticator _oidc;
  final TokenStore _store;

  @override
  Future<AuthSession> loginWithSso() async {
    final tokens = await _oidc.signIn();
    await _store.save(tokens);
    return AuthSession(doctor: _doctorFrom(tokens), tokens: tokens);
  }

  @override
  Future<AuthSession> loginDev({
    required String user,
    required String password,
  }) async {
    // Sin IdP: sesión simulada. El backend en dev acepta la petición sin token
    // (AUTH_DEV_BYPASS). No se guardan tokens porque no los hay.
    final id = user.trim().isEmpty ? 'medico-dev' : user.trim();
    return AuthSession(doctor: Doctor(id: id, name: id));
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final tokens = await _store.read();
    if (tokens == null) return null;

    if (tokens.isExpired) {
      if (!tokens.canRefresh) {
        await _store.clear();
        return null;
      }
      final refreshed = await _oidc.refresh(tokens.refreshToken!);
      if (refreshed == null) {
        await _store.clear();
        return null;
      }
      await _store.save(refreshed);
      return AuthSession(doctor: _doctorFrom(refreshed), tokens: refreshed);
    }

    return AuthSession(doctor: _doctorFrom(tokens), tokens: tokens);
  }

  @override
  Future<void> logout() async {
    final tokens = await _store.read();
    await _oidc.signOut(tokens?.idToken);
    await _store.clear();
  }

  /// Construye el médico a partir de los claims del `id_token` (sin verificar la
  /// firma: eso lo hace el backend). `sub` es el id estable; el nombre cae al
  /// primer claim disponible.
  Doctor _doctorFrom(AuthTokens tokens, {String fallbackId = 'medico'}) {
    final claims =
        tokens.idToken != null ? _decodeJwtPayload(tokens.idToken!) : const {};
    final id = (claims['sub'] ?? fallbackId).toString();
    final name = (claims['name'] ??
            claims['preferred_username'] ??
            claims['email'] ??
            id)
        .toString();
    return Doctor(id: id, name: name);
  }
}

/// Decodifica el payload de un JWT (sin verificar). Devuelve {} si no es válido.
Map<String, dynamic> _decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return const {};
  try {
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = json.decode(decoded);
    return map is Map<String, dynamic> ? map : const {};
  } catch (_) {
    return const {};
  }
}

/// Autenticador OIDC por defecto: sin librería cableada todavía.
///
/// La implementación real (Authorization Code + PKCE con openid_client u otra)
/// se inyecta sustituyendo [oidcAuthenticatorProvider]. Ver docs/oidc-frontend.md.
class DisabledOidcAuthenticator implements OidcAuthenticator {
  const DisabledOidcAuthenticator();

  @override
  Future<AuthTokens> signIn() async {
    throw StateError(
      'Login SSO no cableado: falta la implementación de OidcAuthenticator '
      '(ver docs/oidc-frontend.md). Usa el login de desarrollo mientras tanto.',
    );
  }

  @override
  Future<AuthTokens?> refresh(String refreshToken) async => null;

  @override
  Future<void> signOut(String? idToken) async {}
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// Sustituir por la implementación real de OIDC al integrar la librería.
final oidcAuthenticatorProvider = Provider<OidcAuthenticator>(
  (ref) => const DisabledOidcAuthenticator(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(oidcAuthenticatorProvider),
    ref.watch(tokenStoreProvider),
  );
});
