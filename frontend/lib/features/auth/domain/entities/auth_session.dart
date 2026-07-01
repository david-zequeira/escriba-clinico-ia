import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';
import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';

/// Sesión autenticada: el médico y sus tokens. En dev (bypass del backend) los
/// tokens pueden ir vacíos: el backend acepta la petición sin `Authorization`.
class AuthSession {
  const AuthSession({required this.doctor, this.tokens});

  final Doctor doctor;
  final AuthTokens? tokens;

  String? get accessToken => tokens?.accessToken;
}
