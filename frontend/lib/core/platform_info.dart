import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Columnas del grid según ancho útil del contenido.
int contentColumns(double width) {
  if (width >= 900) return 3;
  if (width >= 560) return 2;
  return 1;
}

bool isWideLayout(BuildContext context) => contentColumns(contentWidth(context)) > 1;

double contentWidth(BuildContext context) {
  final screen = MediaQuery.sizeOf(context).width;
  const max = 1120.0;
  const hPad = 40.0;
  return (screen > max ? max : screen) - (hPad * 2);
}
