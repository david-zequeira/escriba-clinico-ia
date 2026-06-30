#!/usr/bin/env bash
# Instala record_linux 1.3.1 en el pub cache sin usar `dart pub` (útil si pub get da 403).
set -euo pipefail

PKG=record_linux
VER=1.3.1
CACHE_ROOT="${PUB_CACHE:-$HOME/.pub-cache}"
DEST="$CACHE_ROOT/hosted/pub.dev/${PKG}-${VER}"

if [[ -d "$DEST" ]]; then
  echo "OK: ya existe $DEST"
  exit 0
fi

echo "Descargando ${PKG}-${VER} desde pub.dev..."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "https://pub.dev/api/archives/${PKG}-${VER}.tar.gz" -o "$TMP/pkg.tar.gz"
mkdir -p "$CACHE_ROOT/hosted/pub.dev"
tar -xzf "$TMP/pkg.tar.gz" -C "$CACHE_ROOT/hosted/pub.dev"
echo "OK: instalado en $DEST"
