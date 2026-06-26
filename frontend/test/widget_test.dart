import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:escriba_clinico/main.dart';

void main() {
  testWidgets('arranca en el login de Vionix', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VionixApp()));
    await tester.pumpAndSettle();

    // Independiente del idioma (el login se traduce es/en).
    expect(find.text('Vionix'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget); // botón de iniciar sesión
  });
}
