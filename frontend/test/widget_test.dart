import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:escriba_clinico/features/auth/data/datasources/token_store.dart';
import 'package:escriba_clinico/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:escriba_clinico/features/auth/domain/entities/auth_tokens.dart';
import 'package:escriba_clinico/main.dart';

/// Almacén vacío: evita el plugin de secure storage en tests y simula "sin
/// sesión guardada" para que la app arranque en el login.
class _EmptyTokenStore implements TokenStore {
  @override
  Future<void> save(AuthTokens tokens) async {}
  @override
  Future<AuthTokens?> read() async => null;
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('arranca en el login de Vionix', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(_EmptyTokenStore())],
        child: const VionixApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Independiente del idioma (el login se traduce es/en).
    expect(find.text('Vionix'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget); // botón de iniciar sesión
  });
}
