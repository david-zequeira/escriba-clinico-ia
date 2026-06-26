import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test('devuelve un Doctor con el id del usuario introducido', () async {
      final repo = AuthRepositoryImpl();

      final doctor = await repo.login(user: 'dra.smith', password: 'x');

      expect(doctor.id, 'dra.smith');
      expect(doctor.name, 'dra.smith');
    });

    test('usa un id por defecto si el usuario viene vacío', () async {
      final repo = AuthRepositoryImpl();

      final doctor = await repo.login(user: '   ', password: 'x');

      expect(doctor.id, 'medico-dev');
    });
  });
}
