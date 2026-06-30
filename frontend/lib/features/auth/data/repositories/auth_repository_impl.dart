import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';

/// Implementación MVP: acepta cualquier credencial (OIDC real en fase posterior).
/// Cuando llegue OIDC, se reemplaza esta clase por una que hable con el IdP,
/// sin cambiar el controller ni la UI.
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Doctor> login({required String user, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = user.trim().isEmpty ? 'medico-dev' : user.trim();
    return Doctor(id: id, name: id);
  }

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});
