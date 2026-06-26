import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/entities/doctor.dart';
import 'package:escriba_clinico/features/auth/domain/repositories/auth_repository.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements AuthRepository {
  @override
  Future<Doctor> login({required String user, required String password}) async =>
      const Doctor(id: 'doc-1', name: 'Dra. Demo');

  @override
  Future<void> logout() async {}
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(_FakeAuth())],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial: sin autenticar', () {
    expect(container.read(authProvider).isAuthenticated, isFalse);
  });

  test('login autentica y guarda los datos del médico', () async {
    await container.read(authProvider.notifier).login(user: 'x', password: 'y');

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.doctorId, 'doc-1');
    expect(state.doctorName, 'Dra. Demo');
  });

  test('logout limpia la sesión', () async {
    final notifier = container.read(authProvider.notifier);
    await notifier.login(user: 'x', password: 'y');

    await notifier.logout();

    expect(container.read(authProvider).isAuthenticated, isFalse);
  });
}
