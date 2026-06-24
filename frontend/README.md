# Frontend — Escriba Clínico IA (Flutter)

Un solo código para iOS, Android, Windows, macOS, Linux y web.

## Arranque
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Estructura
- `lib/core/` — config y cliente HTTP (Dio)
- `lib/models/` — modelo de la nota clínica (espejo del backend)
- `lib/features/audio/` — captura de audio (paquete `record`)
- `lib/features/consultation/` — controlador (Riverpod) y pantalla de revisión

## Importante
- Pide y registra el consentimiento del paciente ANTES de grabar.
- El audio temporal local se borra tras subirlo al backend.
- La pantalla de revisión es obligatoria: el médico valida antes de guardar.
