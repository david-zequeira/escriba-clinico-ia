import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';

/// Almacén de tokens OIDC. Puerto: en tests se sustituye por uno en memoria.
///
/// Cumplimiento §6: SOLO se guardan tokens (nunca datos clínicos ni PHI).
abstract class TokenStore {
  Future<void> save(AuthTokens tokens);
  Future<AuthTokens?> read();
  Future<void> clear();
}

/// Implementación con almacenamiento seguro del sistema (Keychain/Keystore).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'oidc_access_token';
  static const _kRefresh = 'oidc_refresh_token';
  static const _kId = 'oidc_id_token';
  static const _kExpiresAt = 'oidc_expires_at';

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    await _storage.write(key: _kId, value: tokens.idToken);
    await _storage.write(
      key: _kExpiresAt,
      value: tokens.expiresAt?.toIso8601String(),
    );
  }

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    if (access == null || access.isEmpty) return null;
    final expiresRaw = await _storage.read(key: _kExpiresAt);
    return AuthTokens(
      accessToken: access,
      refreshToken: await _storage.read(key: _kRefresh),
      idToken: await _storage.read(key: _kId),
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kId);
    await _storage.delete(key: _kExpiresAt);
  }
}
