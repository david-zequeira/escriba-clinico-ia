---
name: flutter-stack
description: >-
  Stack y tendencias Flutter/Dart (2026) para el frontend de Escriba Clínico IA. Úsala al
  tocar la app Flutter: elegir paquetes, montar gestión de estado, navegación, networking,
  serialización, internacionalización o tests. Cubre Riverpod moderno (Notifier/AsyncNotifier
  con codegen), go_router, dio, freezed/json_serializable, estructura feature-first,
  Impeller/rendimiento y comandos de calidad. Complementa flutter-ui-ux (diseño) y
  reusable-ai-architecture (arquitectura multi-caso).
---

# Flutter Stack & Tendencias (2026)

Guía de decisiones técnicas para el frontend. El proyecto ya usa Flutter 3.x, Riverpod, Dio,
`record`, `go_router`. Esta skill fija **qué versión moderna de cada cosa usar** y por qué,
para no arrastrar patrones obsoletos.

> Regla de oro del repo: estado con Riverpod, UI separada de la lógica (controladores),
> red solo a través de `ApiClient`, en almacenamiento seguro solo tokens (nunca datos
> clínicos). Ver `../../CLAUDE.md` §6.

---

## 1. Versiones base (objetivo)

| Pieza | Versión objetivo | Nota |
|-------|------------------|------|
| Flutter | 3.27+ (canal stable) | Impeller es el motor de render por defecto en iOS/Android |
| Dart | 3.6+ | Records, patterns, `sealed`/`final` classes, switch exhaustivo |
| SDK constraint | `>=3.4.0 <4.0.0` | Ya en `pubspec.yaml`; subir a `>=3.6.0` al adoptar patterns |

**Tendencia clave 2026**: los *macros* de Dart fueron **descartados** por el equipo de Dart.
La generación de código sigue haciéndose con `build_runner` + `freezed` + `json_serializable`
+ `riverpod_generator`. No esperes macros; adopta codegen con `build_runner`.

---

## 2. Gestión de estado — Riverpod moderno

El repo usa hoy `StateNotifier` + `StateNotifierProvider` (`consultation_controller.dart`).
**Eso es el patrón legacy de Riverpod.** Para código nuevo usa la API moderna:

- `Notifier` / `AsyncNotifier` en lugar de `StateNotifier`.
- Providers generados con `@riverpod` (paquete `riverpod_generator`), no declarados a mano.
- `AsyncValue<T>` para todo lo que venga de I/O (red, STT, LLM): da `loading/data/error`
  gratis y obliga a manejar los tres estados en la UI.

```dart
// dependencias sugeridas (pubspec.yaml)
// flutter_riverpod: ^2.6.1
// riverpod_annotation: ^2.6.1
// dev: riverpod_generator: ^2.6.x, build_runner: ^2.4.x, custom_lint, riverpod_lint

@riverpod
class ConsultationController extends _$ConsultationController {
  @override
  ConsultationState build() => const ConsultationState();

  Future<void> submitAudio(List<int> audioBytes) async {
    state = state.copyWith(stage: ConsultationStage.processing);
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() => api.uploadConsultation(audioBytes))
        .then(/* map a ConsultationState.review | error */);
  }
}
```

Reglas:
- **Nada de estado global mutable suelto** (regla del repo). Todo via providers.
- Activa `riverpod_lint` + `custom_lint`: detecta providers mal usados en CI.
- Cuando migres `StateNotifier` existente, hazlo por feature, no en bloque.

> Migración a **Riverpod 3.x**: posible pero opcional. Si se adopta, unifica en `Notifier`/
> `AsyncNotifier` (Riverpod 3 elimina `StateNotifierProvider` del núcleo). Decide en equipo.

---

## 3. Navegación — go_router

Ya está en `pubspec.yaml`. Úsalo con rutas tipadas y un `redirect` central para auth (OIDC):

```dart
final router = GoRouter(
  redirect: (ctx, state) => ref.read(authProvider).isAuthed ? null : '/login',
  routes: [ /* /login, /consultations, /consultations/:id/review ... */ ],
);
```

- Define las rutas como constantes; evita strings mágicos repartidos.
- El guard de auth vive en `redirect`, no en cada pantalla.
- Para escritorio/web, go_router maneja deep-links y URL del navegador correctamente.

---

## 4. Networking — Dio

`ApiClient` (en `core/`) es el único punto de red. Añade ahí, no en las pantallas:

- **Interceptor de auth**: inyecta `Authorization: Bearer <JWT OIDC>`.
- **Interceptor de reintentos** con backoff para fallos de red transitorios (no para 4xx).
- **Timeouts** explícitos (connect/receive). El pipeline backend puede tardar minutos: ajusta
  `receiveTimeout` para `/consultations` o usa polling/jobs (ver reusable-ai-architecture).
- **Logging sin PHI**: nunca loguear cuerpos con datos clínicos. Filtra en el interceptor.

```dart
// dio: ^5.7.0 (ya); considerar dio_smart_retry para reintentos declarativos
final dio = Dio(BaseOptions(
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(minutes: 3),
))..interceptors.addAll([authInterceptor, retryInterceptor, redactedLogInterceptor]);
```

---

## 5. Modelos y serialización — freezed + json_serializable

Hoy `clinical_note.dart` es manual y mutable. Para modelos nuevos (y al refactorizar):

- `freezed` para modelos inmutables con `copyWith`, igualdad y uniones selladas.
- `json_serializable` para `fromJson`/`toJson` (sin escribir mapeos a mano, sin typos).
- `AsyncValue` + uniones `sealed` para estados de pantalla.

```dart
// freezed: ^2.5.x, json_annotation; dev: build_runner, freezed_annotation, json_serializable
@freezed
class ClinicalSection with _$ClinicalSection {
  const factory ClinicalSection({
    @Default('') String content,
    @Default(false) bool needsConfirmation,
  }) = _ClinicalSection;
  factory ClinicalSection.fromJson(Map<String, dynamic> j) => _$ClinicalSectionFromJson(j);
}
```

> Mantén los nombres de campo JSON alineados con el backend Pydantic (`needs_confirmation`).
> Usa `@JsonKey(name: 'needs_confirmation')` o `field_rename`. El contrato FE↔BE es uno solo.

---

## 6. Internacionalización

`intl` ya está. El idioma por defecto es **español**. Usa `flutter_localizations` + ARB
(`gen_l10n`) para textos de UI; nunca hardcodees strings de usuario dispersos. Esto facilita
añadir idiomas (el backend ya pasa `language` en las interfaces STT/LLM).

---

## 7. Audio multiplataforma

`record` (`^5.1.2`) ya cubre móvil/escritorio/web. Recuerda:
- Pedir consentimiento del paciente **antes** de grabar (requisito de cumplimiento).
- Grabar a archivo temporal local y **borrarlo tras subir** (minimización RGPD).
- Para streaming futuro: `web_socket_channel` (ya en deps) + `transcribe_stream()` del backend.

---

## 8. Testing y calidad

| Nivel | Herramienta | Qué probar |
|-------|-------------|-----------|
| Unit | `flutter_test` | Controladores/Notifiers, mapeo de modelos |
| Provider | `ProviderContainer` + overrides | Lógica de estado con `ApiClient` mockeado |
| Widget | `flutter_test` + `pumpWidget` | Pantalla de revisión: render, edición, validación |
| Golden | `golden_toolkit` / golden nativo | Consistencia visual multiplataforma del design system |
| Mock | `mocktail` | Sin codegen para mocks (preferido sobre `mockito`) |

Comandos canónicos (de `../../CLAUDE.md` §5):

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # si usas codegen
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Activa lints estrictos: parte de `flutter_lints` (ya) y añade `custom_lint` + `riverpod_lint`.

---

## 9. Rendimiento

- **Impeller** es el render por defecto; evita patrones que fuerzan shader jank antiguos.
- `const` en widgets siempre que puedas; separa widgets para acotar rebuilds.
- Usa `select` de Riverpod para escuchar solo el trozo de estado que importa.
- Listas largas: `ListView.builder`/`SliverList`, nunca construir todo de golpe.
- Imágenes/iconos: `flutter_svg` para vectores nítidos en todas las densidades.

---

## 10. Checklist al tocar el frontend

- [ ] ¿Estado nuevo en `Notifier`/`AsyncNotifier` (no `StateNotifier` legacy)?
- [ ] ¿Toda la red pasa por `ApiClient`? ¿Sin PHI en logs?
- [ ] ¿Modelos nuevos con `freezed`/`json_serializable` y campos alineados al backend?
- [ ] ¿Textos de usuario vía i18n (ARB), no hardcodeados?
- [ ] ¿UI separada de la lógica? ¿Widgets pequeños y `const`?
- [ ] ¿Solo tokens en `flutter_secure_storage`, nunca datos clínicos?
- [ ] ¿`flutter analyze` y `flutter test` en verde?
- [ ] ¿Se ve y funciona bien en móvil, tablet, escritorio y web? (ver flutter-ui-ux)
