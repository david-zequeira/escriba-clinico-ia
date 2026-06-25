import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Autenticación MVP: acepta cualquier credencial (OIDC real en fase posterior).
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  Future<void> login({required String user, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = user.trim().isEmpty ? 'medico-dev' : user.trim();
    state = AuthState(isAuthenticated: true, doctorId: id, doctorName: id);
  }

  void logout() => state = const AuthState();
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
