import 'dart:convert';

import 'package:escriba_clinico/features/auth/data/datasources/token_store.dart';
import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/oidc_authenticator.dart';
import 'package:flutter_test/flutter_test.dart';

/// id_token JWT falso (sin firma real): el repositorio solo decodifica el payload.
String _fakeIdToken(Map<String, dynamic> claims) {
  final payload =
      base64Url.encode(utf8.encode(json.encode(claims))).replaceAll('=', '');
  return 'header.$payload.signature';
}

class _FakeOidc implements OidcAuthenticator {
  _FakeOidc({this.tokens, this.refreshed});

  final AuthTokens? tokens;
  final AuthTokens? refreshed;
  int signOutCalls = 0;

  @override
  Future<AuthTokens> signIn() async =>
      tokens ?? (throw StateError('sin tokens de prueba'));

  @override
  Future<AuthTokens?> refresh(String refreshToken) async => refreshed;

  @override
  Future<void> signOut(String? idToken) async => signOutCalls++;
}

class _FakeStore implements TokenStore {
  _FakeStore([this._saved]);
  AuthTokens? _saved;
  int clears = 0;

  @override
  Future<void> save(AuthTokens tokens) async => _saved = tokens;
  @override
  Future<AuthTokens?> read() async => _saved;
  @override
  Future<void> clear() async {
    _saved = null;
    clears++;
  }
}

void main() {
  group('AuthRepositoryImpl', () {
    test('loginWithSso guarda los tokens y deriva el médico del id_token', () async {
      final tokens = AuthTokens(
        accessToken: 'access-abc',
        idToken: _fakeIdToken({'sub': 'dr-house', 'name': 'Dr. House'}),
      );
      final store = _FakeStore();
      final repo = AuthRepositoryImpl(_FakeOidc(tokens: tokens), store);

      final session = await repo.loginWithSso();

      expect(session.doctor.id, 'dr-house');
      expect(session.doctor.name, 'Dr. House');
      expect(session.accessToken, 'access-abc');
      expect((await store.read())?.accessToken, 'access-abc');
    });

    test('loginDev crea una sesión simulada sin tokens', () async {
      final repo = AuthRepositoryImpl(_FakeOidc(), _FakeStore());
      final session = await repo.loginDev(user: 'dra.smith', password: 'x');
      expect(session.doctor.id, 'dra.smith');
      expect(session.accessToken, isNull);
    });

    test('restoreSession devuelve la sesión si el token es válido', () async {
      final tokens = AuthTokens(
        accessToken: 'a',
        idToken: _fakeIdToken({'sub': 'dr-1', 'preferred_username': 'ghouse'}),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final repo = AuthRepositoryImpl(_FakeOidc(), _FakeStore(tokens));

      final session = await repo.restoreSession();

      expect(session, isNotNull);
      expect(session!.doctor.name, 'ghouse');
    });

    test('restoreSession refresca si el token expiró y hay refresh token', () async {
      final expired = AuthTokens(
        accessToken: 'viejo',
        refreshToken: 'r',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final refreshed = AuthTokens(
        accessToken: 'nuevo',
        idToken: _fakeIdToken({'sub': 'dr-1'}),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final store = _FakeStore(expired);
      final repo = AuthRepositoryImpl(_FakeOidc(refreshed: refreshed), store);

      final session = await repo.restoreSession();

      expect(session?.accessToken, 'nuevo');
      expect((await store.read())?.accessToken, 'nuevo');
    });

    test('restoreSession limpia y devuelve null si expiró y no hay refresh', () async {
      final expired = AuthTokens(
        accessToken: 'viejo',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final store = _FakeStore(expired);
      final repo = AuthRepositoryImpl(_FakeOidc(), store);

      final session = await repo.restoreSession();

      expect(session, isNull);
      expect(store.clears, 1);
    });

    test('restoreSession devuelve null si no hay tokens guardados', () async {
      final repo = AuthRepositoryImpl(_FakeOidc(), _FakeStore());
      expect(await repo.restoreSession(), isNull);
    });

    test('logout notifica al IdP y limpia el almacén', () async {
      final oidc = _FakeOidc();
      final store = _FakeStore(const AuthTokens(accessToken: 'a'));
      final repo = AuthRepositoryImpl(oidc, store);

      await repo.logout();

      expect(oidc.signOutCalls, 1);
      expect(store.clears, 1);
      expect(await store.read(), isNull);
    });
  });
}
