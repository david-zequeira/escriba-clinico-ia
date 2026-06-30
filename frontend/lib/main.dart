import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/locale_controller.dart';
import 'package:escriba_clinico/core/theme_mode_controller.dart';
import 'package:escriba_clinico/features/auth/presentation/screens/login_screen.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';
import 'package:escriba_clinico/features/home/presentation/screens/home_screen.dart';
import 'package:escriba_clinico/l10n/app_localizations.dart';

void main() => runApp(const ProviderScope(child: VionixApp()));

class VionixApp extends ConsumerWidget {
  const VionixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Vionix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // i18n: español por defecto (fallback) + inglés. `locale` null sigue el
      // idioma del sistema; si el usuario elige uno, manda y se persiste.
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('es'), Locale('en')],
      home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
