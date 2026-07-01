import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_session.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';
import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.restoreResult});
  final AuthSession? restoreResult;

  @override
  Future<AuthSession> loginWithSso() async => const AuthSession(
        doctor: Doctor(id: 'sso-1', name: 'Dra. SSO'),
        tokens: AuthTokens(accessToken: 'tok-123'),
      );

  @override
  Future<AuthSession> loginDev({
    required String user,
    required String password,
  }) async =>
      const AuthSession(doctor: Doctor(id: 'doc-1', name: 'Dra. Demo'));

  @override
  Future<AuthSession?> restoreSession() async => restoreResult;

  @override
  Future<void> logout() async {}
}

/// Espera a que termine la restauración asíncrona del constructor.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  ProviderContainer containerWith(AuthRepository repo) {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sin sesión guardada: termina no autenticado', () async {
    final container = containerWith(_FakeAuth());
    // Fuerza la creación del provider (dispara _restore).
    container.read(authProvider);
    await _settle();

    final state = container.read(authProvider);
    expect(state.initializing, isFalse);
    expect(state.isAuthenticated, isFalse);
  });

  test('restaura la sesión guardada al arrancar', () async {
    final container = containerWith(
      _FakeAuth(
        restoreResult: const AuthSession(
          doctor: Doctor(id: 'doc-9', name: 'Dr. Restaurado'),
          tokens: AuthTokens(accessToken: 'guardado'),
        ),
      ),
    );
    container.read(authProvider);
    await _settle();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.doctorId, 'doc-9');
    expect(state.accessToken, 'guardado');
  });

  test('loginDev autentica sin token', () async {
    final container = containerWith(_FakeAuth());
    await _settle();

    await container.read(authProvider.notifier).loginDev(user: 'x', password: 'y');

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.doctorId, 'doc-1');
    expect(state.accessToken, isNull);
  });

  test('loginWithSso autentica y guarda el token', () async {
    final container = containerWith(_FakeAuth());
    await _settle();

    await container.read(authProvider.notifier).loginWithSso();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.doctorId, 'sso-1');
    expect(state.accessToken, 'tok-123');
  });

  test('logout limpia la sesión', () async {
    final container = containerWith(_FakeAuth());
    await _settle();
    final notifier = container.read(authProvider.notifier);
    await notifier.loginDev(user: 'x', password: 'y');

    await notifier.logout();

    expect(container.read(authProvider).isAuthenticated, isFalse);
  });
}
