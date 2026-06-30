import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma seleccionado, **persistido** entre sesiones (igual que el tema).
///
/// `null` = seguir el idioma del sistema (con español como fallback).
final localeProvider =
    StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null) {
    _load();
  }

  static const _key = 'locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> _persist(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }

  /// Fija el idioma (o `null` para seguir el del sistema) y lo persiste.
  void set(Locale? locale) {
    state = locale;
    _persist(locale);
  }
}
