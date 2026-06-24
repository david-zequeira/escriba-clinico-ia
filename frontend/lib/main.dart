import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/consultation/review_screen.dart';

void main() => runApp(const ProviderScope(child: EscribaApp()));

class EscribaApp extends StatelessWidget {
  const EscribaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escriba Clínico IA',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const ReviewScreen(),
    );
  }
}
