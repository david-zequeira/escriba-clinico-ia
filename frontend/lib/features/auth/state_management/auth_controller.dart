import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_session.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.initializing = false,
    this.isAuthenticated = false,
    this.doctorId,
    this.doctorName,
    this.accessToken,
  });

  /// True mientras se intenta restaurar la sesión guardada al arrancar.
  final bool initializing;
  final bool isAuthenticated;
  final String? doctorId;
  final String? doctorName;

  /// Access token OIDC para el interceptor HTTP y el WebSocket. Null en dev.
  final String? accessToken;

  factory AuthState.fromSession(AuthSession session) => AuthState(
        isAuthenticated: true,
        doctorId: session.doctor.id,
        doctorName: session.doctor.name,
        accessToken: session.accessToken,
      );
}

/// Orquesta la sesión apoyándose en [AuthRepository] (puerto del dominio).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState(initializing: true)) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    try {
      final session = await _repo.restoreSession();
      state =
          session != null ? AuthState.fromSession(session) : const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

  /// Login real vía OIDC (redirección al IdP).
  Future<void> loginWithSso() async {
    final session = await _repo.loginWithSso();
    state = AuthState.fromSession(session);
  }

  /// Login de desarrollo (sin IdP).
  Future<void> loginDev({required String user, required String password}) async {
    final session = await _repo.loginDev(user: user, password: password);
    state = AuthState.fromSession(session);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
