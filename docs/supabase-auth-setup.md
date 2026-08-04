# Configuración de Supabase Auth en Zentra

> **ESTACIONADO desde el 3 de agosto de 2026.** La build vigente es local-only.
> No ejecutes estos pasos, migraciones o despliegues remotos durante esta fase.
> Este archivo se conserva como runbook para la reactivación futura.

La app mantiene Supabase apagado por default. URL, clave y flags OAuth no lo
encienden solos. La reactivación futura requiere además el switch raíz explícito
`ZENTRA_CLOUD_ENABLED=true` y completar los gates de
[`zentra-cloud-parking-plan.md`](zentra-cloud-parking-plan.md).

## Variables de compilación

La configuración del cliente entra por `--dart-define`. Nunca uses la service
role key en Flutter.

```bash
./flutter/bin/flutter run \
  --dart-define=ZENTRA_CLOUD_ENABLED=true \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_VALUE \
  --dart-define=SUPABASE_GOOGLE_AUTH_ENABLED=true \
  --dart-define=SUPABASE_APPLE_AUTH_ENABLED=true
```

Apple sólo se muestra en iOS. Google se muestra en las plataformas donde su flag
esté activo. El redirect móvil por default es:

```text
com.jesutorr.appzentra://login-callback
```

Otro ambiente puede reemplazarlo con:

```text
--dart-define=SUPABASE_REDIRECT_URL=otro.esquema://login-callback
```

Una configuración parcial o una URL HTTP remota se rechaza antes de inicializar
el SDK. `http://127.0.0.1` y `http://localhost` sólo se aceptan para desarrollo
local.

## Supabase local

```bash
supabase start
supabase db reset
supabase db lint --local --level warning
supabase test db
supabase db diff --local --schema public,zentra_private
supabase status -o env
```

Usa `API_URL` como `SUPABASE_URL` y `PUBLISHABLE_KEY` como
`SUPABASE_PUBLISHABLE_KEY`. No copies el resto de las claves al código, assets ni
documentación.

Para probar Flutter web contra el `site_url` local:

```bash
./flutter/bin/flutter run -d chrome --web-port 3000 \
  --dart-define=ZENTRA_CLOUD_ENABLED=true \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=VALOR_LOCAL \
  --dart-define=SUPABASE_GOOGLE_AUTH_ENABLED=true
```

El OAuth local de Google requiere un cliente real de Google Cloud:

1. Registra `http://127.0.0.1:54321/auth/v1/callback` como redirect autorizado.
2. Habilita `[auth.external.google]` en `supabase/config.toml`.
3. Proporciona el client ID y
   `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET` sólo en el entorno local.
4. Reinicia Supabase.

## Proyecto dev remoto

En Supabase Auth:

1. Configura Google y Apple con credenciales exclusivas de dev.
2. Agrega `com.jesutorr.appzentra://login-callback` a Additional Redirect URLs.
3. Configura el Site URL web real.
4. Mantén separados dev y production.

En Google Cloud, el redirect del proveedor apunta a:

```text
https://PROJECT_REF.supabase.co/auth/v1/callback
```

Apple OAuth usa el mismo callback de Supabase y requiere su Services ID, Team ID,
Key ID y secreto firmado. El secreto de Apple tiene rotación operativa y nunca
entra al repositorio.

## Persistencia y ownership

- La sesión y el verificador PKCE se guardan con almacenamiento seguro de
  plataforma.
- `auth.uid()` se usa como owner local de la identidad remota.
- Una cuenta remota sin sesión válida no puede abrir su cache local.
- Cerrar sesión remota conserva el shadow local, pero lo deja bloqueado.
- Autenticar desde la pantalla inicial abre un shadow cloud vacío o existente.
- Vincular desde Ajustes primero muestra conteos, después autentica y sólo
  activa el shadow de `auth.uid()` cuando la copia transaccional pasa conteos y
  checksum.
- La vinculación conserva el espacio local original y usa IDs cloud
  deterministas para que ambos espacios puedan coexistir en la misma base
  Drift sin colisionar sus llaves globales.
- Perfil, hábitos, horarios, completados diarios, notas, recordatorios de notas,
  repasos, tareas terminadas, sesiones de enfoque completadas y tema portable
  ya usan el transporte remoto.
- Realtime despierta un pull incremental y la UI vuelve a cargar el estado
  materializado en Drift. No sustituye al cursor durable.
- El ID de notificación nunca se sube: cada dispositivo conserva o reconstruye
  el suyo. Permisos, sonidos, duraciones del timer y Pomodoro en curso también
  permanecen locales.
- Eliminar una cuenta remota invoca la Edge Function autenticada
  `delete-account`. La función obtiene el usuario desde su JWT, nunca acepta un
  `user_id` proporcionado por el cliente y usa la service role sólo dentro del
  entorno administrado de Supabase.
- Las tablas sincronizadas referencian `auth.users` con `on delete cascade`.
  Borrar la identidad elimina sus filas remotas antes de limpiar la copia local.

## Eliminación remota de cuenta, inactiva

El código apartado incluye `supabase/functions/delete-account/index.ts`, pero
la build vigente no lo invoca. No despliegues la función mientras la nube esté
estacionada. Cuando se autorice la reactivación, hazlo por ambiente:

```bash
supabase functions deploy delete-account \
  --project-ref PROJECT_REF
```

Después del despliegue:

1. Inicia sesión con una cuenta de prueba.
2. Crea al menos un hábito o nota y confirma que sincronice.
3. Usa `Configuración > Eliminar cuenta`.
4. Confirma en Supabase Auth que el usuario ya no existe.
5. Confirma con una consulta administrativa que no quedan filas para ese UUID.
6. Verifica que volver con Google crea una identidad nueva y un espacio vacío.

No despliegues con `--no-verify-jwt`. `verify_jwt = true` forma parte del
contrato de seguridad.

## Fuentes oficiales

- [Inicialización de Supabase Flutter](https://supabase.com/docs/reference/dart/initializing)
- [OAuth desde Flutter](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
- [Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Apple Auth](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
