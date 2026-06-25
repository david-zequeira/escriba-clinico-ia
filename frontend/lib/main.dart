import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() => runApp(const ProviderScope(child: VionixApp()));

class VionixApp extends ConsumerWidget {
  const VionixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vionix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
