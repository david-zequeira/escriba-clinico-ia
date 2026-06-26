import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';

/// Puerto del dominio para autenticación. Hoy simulado; mañana OIDC real
/// (Keycloak/IdP del hospital) sin tocar la presentación.
abstract class AuthRepository {
  Future<Doctor> login({required String user, required String password});
  Future<void> logout();
}
