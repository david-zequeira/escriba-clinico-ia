import 'package:flutter/widgets.dart';

import 'package:escriba_clinico/l10n/app_localizations.dart';

/// Acceso ergonómico a las traducciones: `context.l10n.signIn`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
