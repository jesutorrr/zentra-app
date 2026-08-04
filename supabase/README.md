# Zentra Supabase local

Este directorio contiene el backend reproducible de Zentra V3.

El workspace puede vincularse temporalmente a un proyecto remoto mediante la
CLI. Ninguna credencial OAuth, service role key o dato real debe entrar a estos
archivos.

## Comandos

```bash
supabase start
supabase db reset
supabase db lint --local --level warning
supabase test db
supabase db diff --local --schema public,zentra_private
supabase stop
```

## Estructura

- `config.toml` configura el stack local con project ID `zentra`.
- `migrations/` es la única fuente de verdad del esquema.
- `seed.sql` crea dos espacios ficticios sin contraseña.
- `tests/` valida el esquema, RLS, idempotencia, conflictos y pull incremental.
- `functions/delete-account/` elimina la identidad autenticada desde un entorno
  de servidor. No acepta IDs enviados por Flutter.

## Contrato de seguridad

- `auth.uid()` define el dueño de cada operación.
- El cliente nunca envía ni puede cambiar `user_id`.
- Las tablas públicas permiten lectura autenticada únicamente de filas propias.
- `INSERT`, `UPDATE` y `DELETE` directos están revocados para clientes.
- Toda escritura sincronizada pasa por la RPC versionada de su dominio.
- Todo pull incremental pasa por `pull_sync_changes`.
- Las funciones `security definer` usan `search_path` vacío.
- `anon` no puede ejecutar las RPC.
- La service role nunca debe entrar a Flutter, web, assets, documentos o
  repositorio. La función de eliminación la recibe únicamente del entorno de
  Supabase.

## Cobertura local actual

Las migraciones cubren perfil, hábitos, horarios, estados diarios, historial,
notas, recordatorios, repasos, sesiones de enfoque terminadas y tema portable.
`sync_changes` publica señales Realtime, pero el cliente siempre recupera la
verdad mediante `pull_sync_changes`.

Permisos del sistema, IDs de notificación, sonidos, duración y estado de un
Pomodoro activo permanecen en cada dispositivo.

Antes de cualquier comando `--linked`, confirma con `supabase projects list` que
el punto indica el proyecto de desarrollo correcto. `db push` y
`functions deploy` cambian estado remoto y los ejecuta Uri de forma explícita.
