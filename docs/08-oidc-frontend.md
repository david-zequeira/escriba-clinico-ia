# 08 · Login OIDC en el frontend (Slice 2)

Autenticación OIDC del cliente Flutter contra el IdP del hospital (Keycloak u
equivalente, residencia UE). El backend ya valida el JWT (ver `backend/app/core/oidc.py`);
este slice conecta la app.

## Qué está hecho y probado (`flutter test`)

- **Config** (`core/config.dart`): `oidcIssuer`, `oidcClientId`, `oidcRedirectUri`,
  `oidcScopes`, `oidcConfigured` — por `--dart-define`.
- **Tokens** (`features/auth/…`): `AuthTokens`, `TokenStore` (puerto) + `SecureTokenStore`
  (flutter_secure_storage). **Solo tokens**, nunca datos clínicos (§6).
- **Sesión**: `AuthRepositoryImpl` (login SSO / login dev / restore con refresh / logout),
  `AuthController` (expone `accessToken`, restaura la sesión al arrancar).
- **Red**: interceptor de `dio` que adjunta `Authorization: Bearer`; **401 → logout**.
- **WebSocket**: el token viaja como `?token=` (el backend lo exige así).
- **UI**: botón «Entrar con SSO» en el login cuando `oidcConfigured`; acceso de
  desarrollo si no hay IdP.

Todo esto se prueba con dobles (sin red ni navegador).

## Lo que falta: la implementación concreta de `OidcAuthenticator`

La interacción real con el IdP (Authorization Code + PKCE, abrir navegador y recoger
la redirección) está aislada tras el puerto `OidcAuthenticator`. Por defecto se inyecta
`DisabledOidcAuthenticator` (lanza un error claro). Para activarlo:

1. **Elegir librería** según plataformas objetivo:
   - **Escritorio/móvil** (recomendado para el piloto): `openid_client` + `url_launcher`
     (flujo loopback, sin config nativa pesada).
   - **Web**: requiere flujo de redirección de página (p. ej. paquete `oidc`).

2. **Implementar el puerto** (ejemplo con `openid_client`, escritorio/móvil):

   ```dart
   // features/auth/data/datasources/openid_authenticator.dart
   import 'package:openid_client/openid_client_io.dart';
   import 'package:url_launcher/url_launcher.dart';
   // ... implementa OidcAuthenticator:
   //   final issuer = await Issuer.discover(Uri.parse(AppConfig.oidcIssuer));
   //   final client = Client(issuer, AppConfig.oidcClientId);
   //   final authenticator = Authenticator(client, scopes: AppConfig.oidcScopes,
   //       port: 4000, urlLancher: (u) => launchUrl(Uri.parse(u)));
   //   final cred = await authenticator.authorize();
   //   final t = await cred.getTokenResponse();
   //   return AuthTokens(accessToken: t.accessToken!, refreshToken: t.refreshToken,
   //       idToken: t.idToken.toCompactSerialization(), expiresAt: t.expiresAt);
   ```

3. **Cablearlo**: sustituir `oidcAuthenticatorProvider` para devolver la impl real.

4. **Config por plataforma**:
   - **Redirect URI** registrado en el cliente `vionix-app` del realm (ya incluye
     `http://localhost:*` y `vionix://auth`).
   - **macOS**: añadir en los entitlements `com.apple.security.network.client` y
     `com.apple.security.network.server` (loopback del flujo).
   - **iOS/Android**: esquema propio (`vionix://auth`) en Info.plist / manifest.

## Ejecutar con IdP real

```bash
# Levanta Keycloak (ver backend/docker-compose.yml)
docker compose up -d keycloak

flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=OIDC_ISSUER=http://localhost:8080/realms/vionix \
  --dart-define=OIDC_CLIENT_ID=vionix-app \
  --dart-define=OIDC_REDIRECT_URI=http://localhost:4000
```

## Verificación manual (no cubierta por tests)

1. Pulsar «Entrar con SSO» → se abre el navegador en Keycloak.
2. Entrar con `medico / medico` → vuelve a la app autenticado.
3. Las peticiones REST llevan `Authorization: Bearer` y el WS conecta con `?token=`.
4. Reiniciar la app → restaura la sesión desde el token guardado.
5. Backend con `AUTH_DEV_BYPASS=false` → sin token, 401.
