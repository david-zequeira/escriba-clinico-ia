#!/usr/bin/env bash
# Despliega API + app web (Flutter) como una sola app en Fly.io.
#
# 1. Compila la web apuntando a la propia API (mismo origen, sin CORS).
# 2. Copia la build a backend/webroot (la API la sirve en /app).
# 3. fly deploy desde backend/.
#
# Uso:
#   scripts/deploy-fly.sh                      # usa la URL por defecto de fly.toml
#   API_BASE_URL=https://otra.fly.dev scripts/deploy-fly.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_URL="${API_BASE_URL:-https://escriba-clinico-api.fly.dev}"

# Resuelve Flutter (PATH o fvm), igual que el hook pre-push.
if command -v flutter >/dev/null 2>&1; then
  FLUTTER=flutter
elif command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"
else
  echo "ERROR: no se encontró flutter ni fvm en el PATH" >&2
  exit 1
fi

echo "==> Compilando web (API_BASE_URL=$API_URL)"
cd "$ROOT/frontend"
$FLUTTER build web --release --base-href /app/ --dart-define=API_BASE_URL="$API_URL"

echo "==> Copiando build a backend/webroot"
rm -rf "$ROOT/backend/webroot"
mkdir -p "$ROOT/backend/webroot"
cp -R "$ROOT/frontend/build/web/." "$ROOT/backend/webroot/"

echo "==> Desplegando en Fly.io"
cd "$ROOT/backend"
fly deploy

echo "==> Listo: ${API_URL}/app/"
