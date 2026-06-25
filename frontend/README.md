# Frontend — Escriba Clínico IA (Flutter)

App **multiplataforma** (Windows, macOS, Linux, iOS, Android) pensada sobre todo para
**uso en consultorio con portátil o PC**: layout amplio, atajos de teclado y campos
cómodos para revisar y editar el borrador.

## Requisitos

- Flutter 3.x
- Backend en marcha (ver `backend/README.md`)

## Primera vez (habilitar escritorio)

Si el proyecto no tiene carpetas `macos/`, `windows/` o `linux/`:

```bash
cd frontend
flutter create . --platforms=macos,windows,linux
flutter pub get
```

## Arranque

**macOS (recomendado en desarrollo):**

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000
```

**Windows / Linux:**

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000
flutter run -d linux   --dart-define=API_BASE_URL=http://localhost:8000
```

**Móvil / emulador:**

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

En dispositivo físico usa la IP de tu máquina en lugar de `localhost`.

## Flujo en la app

1. Elegir tipo de documento (ingreso, indicaciones, evolución).
2. Grabar audio con el micrófono del portátil (consentimiento en entrevistas).
3. Esperar procesamiento (STT + LLM en el backend).
4. Revisar y editar el borrador sección a sección.

Atajo en escritorio: **Espacio** para iniciar/detener grabación (si el foco no está en un campo de texto).

## Problemas frecuentes

### `Authentication error (403)` / `authorization failed` en `flutter pub get`

Dart está enviando un **token inválido** a pub.dev (curl a pub.dev funciona, pero `pub` no).

**Paso 1 — quitar token roto:**

```bash
dart pub token list
dart pub token remove https://pub.dev    # si lista algún token
unset PUB_TOKEN                          # por si quedó en el entorno
flutter pub get
```

**Paso 2 — si el 403 continúa**, instala solo el paquete que falta con curl y usa modo offline:

```bash
cd frontend
bash tool/install_record_linux.sh
flutter pub get --offline
```

El proyecto usa `record` 5.2 + `dependency_overrides` de `record_linux` 1.3.1 (evita el error de compilación sin pedir `record_macos` de la v6).

**Paso 3 — compilar:**

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000
```

> Ya estás en `frontend/` si el prompt termina en `frontend %`. No hace falta `cd frontend` otra vez.

### Error `RecordLinux` / `startStream` al compilar

Ejecuta `bash tool/install_record_linux.sh` y luego `flutter pub get --offline` (ver arriba).

## Estructura

- `lib/core/` — config HTTP, layout escritorio, detección de plataforma
- `lib/models/` — tipos de consulta y borrador clínico (`ClinicalDraft`)
- `lib/features/audio/` — captura de audio (`record`; WAV en PC, M4A en móvil)
- `lib/features/consultation/` — grabación, revisión y estado (Riverpod)

## Importante

- Pide consentimiento del paciente antes de grabar entrevistas de ingreso.
- El audio temporal local se borra tras subirlo al backend.
- La revisión médica es obligatoria; el envío al HIS está deshabilitado en el MVP.
