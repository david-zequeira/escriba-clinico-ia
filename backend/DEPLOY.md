# Despliegue en Fly.io (UE — París)

API pública con Swagger en `https://<app>.fly.dev/docs` (HTTPS gratis).

## Requisitos

1. Cuenta en [fly.io](https://fly.io) (tarjeta para verificación; tier gratis con límites).
2. CLI: `brew install flyctl` (macOS) o [instalador oficial](https://fly.io/docs/hands-on/install-flyctl/).
3. Claves Gladia y Mistral (no van en git; solo como secrets).

## Pasos (primera vez)

```bash
cd backend
fly auth login

# Si el nombre 'escriba-clinico-api' está ocupado, edita app en fly.toml
fly apps create escriba-clinico-api

# Volumen persistente (SQLite + audio temporal) en París
fly volumes create vionix_data --region cdg --size 1 --app escriba-clinico-api

# Secretos (sustituye por tus claves reales)
fly secrets set \
  STT_API_KEY="tu_clave_gladia" \
  LLM_API_KEY="tu_clave_mistral" \
  --app escriba-clinico-api

fly deploy
```

Al terminar:

- **Swagger:** https://escriba-clinico-api.fly.dev/docs
- **Alias:** https://escriba-clinico-api.fly.dev/swagger/index.html → redirige a `/docs`
- **Health:** https://escriba-clinico-api.fly.dev/health

## Actualizar tras cambios en el código

```bash
cd backend
fly deploy
```

## Desplegar API + app web juntas (piloto)

La API sirve la web Flutter en `/app` si existe `backend/webroot/`. El script
compila la web, la copia y despliega todo como una sola app:

```bash
# Desde la raíz del repo (usa flutter o fvm automáticamente)
scripts/deploy-fly.sh
```

Al terminar, la app queda en `https://escriba-clinico-api.fly.dev/app/`
(misma URL para API y web: sin CORS y el WebSocket va al mismo host).

> ⚠️ Con `AUTH_DEV_BYPASS=true` la API queda abierta: no compartas la URL fuera
> del piloto, pon límites de gasto en Gladia/Mistral y usa solo datos simulados
> (role-play), nunca pacientes reales.

## Dominio propio (opcional)

Si tienes `api.tudominio.com`:

```bash
fly certs add api.tudominio.com
```

Añade en tu DNS un CNAME `api` → `escriba-clinico-api.fly.dev`.

## Variables de entorno

| Variable | Dónde | Notas |
|----------|--------|--------|
| `STT_API_KEY`, `LLM_API_KEY` | `fly secrets set` | Obligatorias con Gladia/Mistral |
| Resto | `fly.toml` `[env]` | Editables en el archivo |
| `AUTH_DEV_BYPASS` | `fly.toml` | `false` antes de datos reales |
| `DOCS_ENABLED` | `fly.toml` | `false` para ocultar Swagger en prod |

## Cumplimiento

- Región **cdg** (París, UE).
- No subas audio con datos reales de pacientes hasta tener auth y DPA.
- Regenera claves si se filtraron en chat o commits.

## Solución de problemas

| Error | Acción |
|-------|--------|
| `volume not found` | `fly volumes create vionix_data --region cdg --size 1` |
| App lenta al primer request | Normal: `auto_stop_machines` apaga la VM sin tráfico |
| `failed to grab app config` | `fly auth login` de nuevo |
| Nombre de app ocupado | Cambia `app = '...'` en `fly.toml` |
