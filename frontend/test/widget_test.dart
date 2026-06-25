import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:escriba_clinico/main.dart';

void main() {
  testWidgets('muestra login de Vionix', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VionixApp()));
    await tester.pumpAndSettle();

    expect(find.text('Vionix'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
