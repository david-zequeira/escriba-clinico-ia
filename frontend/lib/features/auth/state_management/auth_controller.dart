import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({this.isAuthenticated = false, this.doctorId, this.doctorName});

  final bool isAuthenticated;
  final String? doctorId;
  final String? doctorName;

  AuthState copyWith({bool? isAuthenticated, String? doctorId, String? doctorName}) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
      );
}

/// Orquesta la sesión apoyándose en [AuthRepository] (puerto del dominio).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> login({required String user, required String password}) async {
    final doctor = await _repo.login(user: user, password: password);
    state = AuthState(
      isAuthenticated: true,
      doctorId: doctor.id,
      doctorName: doctor.name,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
