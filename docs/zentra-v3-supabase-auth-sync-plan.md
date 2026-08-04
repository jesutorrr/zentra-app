# Zentra V3: autenticación y sincronización multiplataforma con Supabase

> Actualización del 27 de julio de 2026: este documento conserva decisiones y
> contexto histórico. El estado vigente de seguridad, eliminación de cuenta y
> revamp visual está en
> `docs/zentra-security-and-minimal-revamp-plan.md`.
>
> **Actualización del 3 de agosto de 2026:** la integración está estacionada.
> La build actual no inicializa Supabase ni expone autenticación o sincronización.
> El código, schema y metadata local se conservan para una reactivación futura.
> El contrato vigente está en `docs/zentra-cloud-parking-plan.md`.

**Versión:** 1.0

**Fecha:** 26 de julio de 2026

**Estado:** Estacionado. Este plan no autoriza trabajo remoto hasta completar el
producto local y reabrir explícitamente los gates de reactivación.

**Decisión:** Supabase Cloud + Auth + Postgres + RLS + Realtime

**Plataformas objetivo:** web, iOS y Android

**Relación con V2:** trabajo de arquitectura separado del rebranding visual

**Spike resuelto:** `ZR-SYS-12`, sincronización multiplataforma con backend neutral

## 1. Resultado de producto

Una persona puede iniciar sesión en Zentra desde web, iPhone o Android y encontrar el
mismo espacio personal.

El contrato visible es:

1. Un cambio local aparece inmediatamente en el dispositivo donde se hizo.
2. Con internet, el cambio llega a Supabase y después a los demás dispositivos.
3. Sin internet, Zentra sigue funcionando y conserva el cambio como pendiente.
4. Al recuperar conexión, Zentra envía pendientes y descarga cambios remotos.
5. Al abrir una app que estuvo cerrada, Zentra recupera todo lo ocurrido desde la última
   sincronización.
6. Un reintento nunca duplica completados, XP, notas, sesiones o recordatorios.
7. Un conflicto nunca destruye silenciosamente el texto de una nota.
8. Ningún usuario puede leer o modificar información de otra cuenta.

Ejemplo:

> Uri cambia en web el nombre de un hábito a "Caminar 30 minutos". Después abre
> Zentra en su celular. El celular muestra primero su copia local y, al completar la
> sincronización incremental, reemplaza el nombre anterior por "Caminar 30 minutos".

## 2. Decisiones cerradas

1. Supabase será la fuente canónica compartida.
2. Drift será la fuente de lectura y escritura inmediata de cada dispositivo.
3. La UI no consultará Supabase directamente.
4. Un `SyncCoordinator` será responsable de push, pull, reintentos y conflictos.
5. Los cambios offline se conservarán en una outbox local.
6. Realtime será un acelerador, no una garantía de entrega.
7. La sincronización correcta debe funcionar aunque Realtime esté desconectado.
8. Google será el proveedor principal de acceso.
9. Sign in with Apple se incluirá en iOS para cumplir el contrato de App Store.
10. La experiencia local sin cuenta seguirá disponible.
11. Una cuenta local podrá vincularse después sin perder historial.
12. El sistema de contraseña local fue retirado. Los hashes legados se eliminan
    del almacenamiento al cargar y nunca se suben a Supabase.
13. PowerSync no se agregará en V3. Se construirá un sincronizador acotado al dominio
    de Zentra para evitar un cuarto proveedor.
14. No habrá edición colaborativa simultánea de una misma nota en V3.
15. No habrá handoff de un Pomodoro activo entre dispositivos en V3.
16. Los datos en Supabase estarán cifrados en tránsito y en reposo por la plataforma,
    pero no tendrán cifrado end-to-end en V3.

## 3. Límites con el trabajo de FrontEnd

Mientras FrontEnd termina V2, la línea de nube sólo puede trabajar en archivos nuevos o
en infraestructura aislada.

### Superficie segura durante el rebranding

- `docs/zentra-v3-supabase-auth-sync-plan.md`
- `supabase/config.toml`
- `supabase/migrations/**`
- `supabase/seed.sql`
- `supabase/tests/**`
- `lib/domain/sync/**`
- `lib/infrastructure/sync/**`
- `test/unit/sync/**`
- `test/integration/sync/**`
- Fixtures de migración nuevos

### Superficie reservada para FrontEnd hasta el handoff

- `lib/presentation/**`
- `lib/presentation/theme.dart`
- `lib/presentation/design_tokens.dart`
- `lib/main.dart`
- `pubspec.yaml`
- Assets, sonidos, animaciones y recursos de marca
- Pantallas de acceso, perfil, configuración y onboarding

### Archivos compartidos que requieren una ventana coordinada

- `lib/application/auth_provider.dart`
- `lib/application/habit_provider.dart`
- `lib/application/note_provider.dart`
- `lib/application/pomodoro_provider.dart`
- `lib/application/user_provider.dart`
- `lib/infrastructure/local_storage_repository.dart`
- `lib/infrastructure/drift_note_repository.dart`
- Tablas Drift y código generado

No se modifica un archivo compartido hasta que FrontEnd entregue un punto de integración
estable. La integración se hace sobre ese snapshot, no sobre una versión recordada del
código.

## 4. Arquitectura objetivo

```text
Pantallas y widgets
        |
        v
Providers y casos de uso
        |
        v
Repositorios de dominio
        |
        v
Drift local <--------> SyncCoordinator <--------> Supabase Postgres
   |                         ^                           |
   |                         |                           |
   +---- sync_outbox --------+--------- Realtime -------+
```

### Responsabilidades

**Pantallas y providers**

- Presentan estado.
- Ejecutan casos de uso.
- Nunca contienen SQL, RLS, reintentos o resolución de conflictos.

**Repositorios**

- Leen y escriben Drift.
- Generan mutaciones explícitas para la outbox.
- Mantienen el comportamiento local aunque no exista sesión de nube.

**Drift**

- Sirve datos a la UI.
- Mantiene datos por dueño.
- Conserva mutaciones pendientes.
- Guarda el cursor de sincronización.
- Conserva conflictos hasta resolverlos.

**SyncCoordinator**

- Serializa una sola sincronización por usuario.
- Descarga cambios remotos.
- Reconcilia cambios con mutaciones pendientes.
- Envía la outbox con idempotencia.
- Reintenta con backoff.
- Actualiza estado observable de sincronización.
- Dispara la reprogramación local de recordatorios.

**Supabase**

- Autentica cuentas.
- Persiste la historia compartida.
- Aplica RLS y restricciones.
- Asigna versiones y revisiones de servidor.
- Rechaza ownership inválido.
- Emite señales Realtime.

## 5. Estado actual que condiciona la migración

El código actual tiene dos familias de persistencia:

1. Hábitos, logs, perfil y Pomodoro usan `SharedPreferences`.
2. Notas, tags, recordatorios y repasos ya usan Drift.

También existe un modelo local de espacios que:

- Guarda usuarios en `SharedPreferences`.
- Usa UUID local como dueño.
- Puede continuar sin credenciales.
- Puede tener múltiples cuentas por dispositivo.
- Ignora y elimina hashes de contraseña creados por versiones anteriores.

La migración V3 no convierte datos legados de identidad en cuentas remotas. El
usuario local se trata como un espacio sin vincular y el dueño remoto nace de
`auth.uid()`.

## 6. Identidad y ownership

### Identificadores

- `auth.users.id` será el identificador de cuenta remota.
- El UUID original se conserva en el espacio local fuente.
- El shadow cloud usa un UUIDv5 determinista por `auth.uid()`, tipo de entidad e
  ID fuente. Esto permite que ambos espacios coexistan en Drift, cuyas llaves
  primarias de entidad son globales, y produce el mismo ID en cada reintento.
- `user_id` remoto siempre será `auth.uid()`.
- El antiguo UUID local se conserva en una tabla de mapeo local.
- Ningún RPC confiará en un `user_id` recibido desde el cliente.

### Estados de identidad

| Estado | Cuenta remota | Datos locales | Sincronización |
|---|---|---|---|
| Local sin vincular | No | Sí | No |
| Vinculación en proceso | Sí | Sí | Pausada hasta verificar migración |
| Cuenta vinculada | Sí | Sí | Sí |
| Sesión cerrada | No activa | Cache aislado | No |
| Cuenta eliminada | No | Eliminados | No |

### Flujo de vinculación

1. Crear snapshot local versionado.
2. Calcular conteos y checksum por dominio.
3. Iniciar Google o Apple.
4. Obtener `auth.uid()`.
5. Consultar si esa cuenta ya tiene datos remotos.
6. Si está vacía, importar el snapshot local.
7. Si ya tiene datos, ofrecer usar nube o combinar el espacio local.
8. Copiar al shadow de `auth.uid()` con IDs cloud deterministas y relaciones
   remapeadas.
9. Subir la importación con un `migration_id` idempotente.
10. Descargar la representación remota.
11. Comparar conteos y checksums.
12. Marcar el dueño local como vinculado.
13. Conservar las llaves legacy durante al menos una release estable.

Si cualquier paso falla, Zentra vuelve al espacio local intacto.

## 7. Modelo remoto

Todas las tablas sincronizables deben tener:

- `id uuid`
- `user_id uuid`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz` nullable
- `version bigint`
- `server_revision bigint`
- `schema_version integer`

`updated_at` describe cuándo cambió la entidad. `server_revision` es un cursor monotónico
asignado por servidor y evita depender de relojes de dispositivos.

### Cursor incremental sin huecos

El cursor será monotónico por usuario, no global para todo Zentra.

1. `user_sync_heads` guarda la última revisión asignada a cada `user_id`.
2. Cada RPC de mutación bloquea la fila del usuario con `SELECT FOR UPDATE`.
3. La RPC incrementa el head por cada cambio sincronizable.
4. La entidad recibe ese `server_revision`.
5. `sync_changes` registra `entity_type`, `entity_id`, operación y revisión.
6. Todo se confirma dentro de la misma transacción.
7. `pull_changes(after_revision, limit)` devuelve cambios del usuario ordenados por
   revisión.
8. El cliente avanza su cursor sólo después de aplicar la página completa en Drift.

El lock es por usuario. Dos personas pueden sincronizar en paralelo, pero las mutaciones
de una misma cuenta quedan ordenadas incluso si provienen de dispositivos distintos.
Una revisión abortada no se publica y una revisión confirmada no puede aparecer después
de otra posterior del mismo usuario.

Las escrituras de cliente no acceden directamente a las tablas sincronizadas. Pasan por
la RPC para que ninguna actualización omita versión, revisión, idempotencia o change log.

### Tablas V3

| Tabla | Propósito | Restricción principal |
|---|---|---|
| `user_sync_heads` | Cursor monotónico por cuenta | Un head por `user_id` |
| `sync_changes` | Índice durable para pull incremental | Unique `user_id`, `server_revision` |
| `profiles` | Nombre, avatar y talismán | Un perfil por `user_id` |
| `habits` | Definición del hábito o tarea | UUID estable por usuario |
| `habit_schedules` | Días, fecha y recordatorio lógico | Un schedule activo por hábito |
| `habit_day_states` | Estado completado por fecha local | Unique `user_id`, `habit_id`, `local_date` |
| `completed_tasks` | Historial de tareas de una vez | UUID estable e idempotente |
| `notes` | Contenido y metadatos de nota | UUID estable y `version` |
| `note_reminders` | Intención lógica de recordatorio | Un recordatorio activo por nota |
| `note_reviews` | Eventos de repaso | UUID estable |
| `focus_sessions` | Pomodoros terminados | UUID estable |
| `user_preferences` | Preferencias portables | Un registro por usuario |
| `devices` | Dispositivos vinculados y estado básico | UUID por instalación |
| `processed_mutations` | Idempotencia de comandos | Unique `user_id`, `mutation_id` |

### Campos de dominio que no pueden quedar implícitos

- `habit_day_states` contiene `habit_id`, `local_date`, `completed` y `completed_at`.
- `completed` es estado explícito. Nunca se interpreta como toggle.
- `local_date` representa el día elegido por el usuario en su calendario, no la fecha
  UTC inferida al sincronizar.
- `notes.tags` será `text[]` en V3, con valores normalizados, únicos y ordenados.
- Los tags no tendrán filas remotas independientes en V3. Drift puede conservar su
  estructura local y el repositorio traduce entre ambas representaciones.
- `note_reminders` guarda la intención portable. El ID entregado por iOS o Android vive
  sólo en `local_notification_bindings`.

### Relaciones de ownership

Los hijos deben validar al mismo tiempo el ID del padre y el `user_id`. Por ejemplo, un
log no puede apuntar a un hábito de otro usuario aunque conozca su UUID.

Las foreign keys compuestas y RLS funcionan como dos defensas distintas:

1. RLS decide qué filas puede tocar la sesión.
2. La foreign key impide relaciones cruzadas incluso ante un error de aplicación.

## 8. Datos sincronizados y datos locales

| Dominio | Se sincroniza | Regla |
|---|---|---|
| Perfil | Sí | Nombre, avatar y talismán |
| Hábitos | Sí | Definición, schedule y archivo |
| Completados | Sí | Estado idempotente por hábito y fecha |
| Tareas terminadas | Sí | Evento único por UUID |
| Notas | Sí | Contenido, tags, pin y archivo |
| Recordatorios | Parcial | Intención sí, ID del sistema no |
| Repasos de notas | Sí | Evento único por UUID |
| Pomodoros terminados | Sí | Sesión terminada por UUID |
| Pomodoro activo | No en V3 | Permanece en el dispositivo |
| XP, nivel y rachas | Derivados | Se recalculan desde eventos |
| Permiso de notificaciones | No | Propiedad del sistema operativo |
| ID de notificación | No | Cada dispositivo genera el suyo |
| Quick Actions | No | Configuración local |
| Tokens de sesión | No | Almacenamiento seguro del SDK |
| Archivos de backup | No | Son recuperación manual |
| Tema | Parcial | Preferencia portable con override local |

## 9. Modelo local Drift

Antes de habilitar nube, hábitos, logs, perfil y sesiones terminadas deben salir de listas
JSON completas en `SharedPreferences`.

### Tablas locales adicionales

| Tabla | Propósito |
|---|---|
| `sync_outbox` | Mutaciones pendientes |
| `sync_state` | Cursor y última sincronización por usuario |
| `sync_conflicts` | Conflictos que requieren conservación |
| `local_owner_links` | Mapeo entre dueño local y `auth.uid()` |
| `local_notification_bindings` | ID lógico a ID de notificación por dispositivo |
| `local_migration_state` | Estado, checksums y versión de migración |

### Migración de SharedPreferences

1. Leer datos legacy sin modificarlos.
2. Convertir a modelos intermedios validados.
3. Escribir todas las entidades dentro de una transacción Drift.
4. Comparar conteos, IDs y checksums.
5. Ejecutar las mismas consultas de calendario y progreso.
6. Marcar la migración completa.
7. Mantener fallback de lectura legacy.
8. No eliminar llaves anteriores hasta pasar una release estable.

La migración debe poder ejecutarse dos veces sin duplicar datos.

## 10. Mutaciones y outbox

Cada acción sincronizable produce una mutación:

```text
mutation_id
user_id local
device_id
entity_type
entity_id
operation
payload
base_version
created_at
attempt_count
next_attempt_at
status
```

`created_at` del cliente sirve para diagnóstico, no para ordenar la verdad remota.

### Operaciones explícitas

- `habit_create`
- `habit_patch`
- `habit_archive`
- `habit_restore`
- `habit_delete`
- `habit_completion_set`
- `note_upsert`
- `note_archive`
- `note_restore`
- `note_delete`
- `note_reminder_set`
- `note_review_add`
- `focus_session_complete`
- `profile_patch`
- `preferences_patch`

No se sincronizan operaciones ambiguas como `toggle`. La intención viaja como estado:

```text
habit_completion_set
completed = true
```

Repetir esa mutación mantiene `true` y no entrega XP dos veces.

## 11. Ciclo de sincronización

### Escritura local

1. El caso de uso inicia una transacción Drift.
2. Actualiza la entidad local.
3. Inserta la mutación en `sync_outbox`.
4. Cierra la transacción.
5. La UI refleja el cambio inmediatamente.
6. El coordinador intenta sincronizar si hay sesión válida.

Entidad y outbox deben escribirse en la misma transacción.

### Sync completo

1. Adquirir lock por usuario.
2. Confirmar sesión y dueño.
3. Leer `last_server_revision`.
4. Descargar cambios posteriores al cursor.
5. Reconciliar cambios remotos con la outbox.
6. Aplicar cambios seguros a Drift.
7. Rebasar o marcar conflictos.
8. Enviar mutaciones pendientes en orden.
9. Recibir ack, nueva `version` y nueva `server_revision`.
10. Marcar mutaciones procesadas.
11. Ejecutar un segundo pull hasta quedar estable.
12. Guardar cursor y hora de éxito.
13. Reprogramar recordatorios afectados.
14. Liberar lock.

### Disparadores

- Inicio de aplicación.
- Reanudación desde background.
- Inicio de sesión.
- Vinculación de cuenta.
- Recuperación de una petición fallida.
- Señal Realtime.
- Acción manual "Sincronizar ahora".
- Temporizador mientras la app está activa.

La detección de conectividad puede acelerar un intento, pero una petición real determina
si hay red útil.

## 12. Realtime

Supabase Realtime no sustituye el pull incremental.

En V3:

1. La base emite una señal de cambio.
2. El cliente no toma esa señal como historia durable.
3. El cliente agenda `syncNow()` con debounce.
4. El pull por `server_revision` recupera el estado verdadero.
5. Después de suscribirse, el cliente agenda pulls de seguridad a los 2, 5 y
   15 segundos, y luego cada 60 segundos mientras el canal permanezca activo.

La beta puede usar Postgres Changes por su menor configuración. Si crecen las conexiones,
se migra a Broadcast privado, recomendado por Supabase para escala y seguridad. El cambio
no altera providers, repositorios o Drift porque Realtime sólo despierta al coordinador.
Los pulls de seguridad cubren la carrera observada durante un arranque frío de Realtime:
una suscripción WebSocket puede anunciarse antes de que el slot lógico esté listo. El
cursor durable evita duplicados y conserva la corrección aunque esa primera señal se
pierda.

## 13. Resolución de conflictos

| Caso | Decisión |
|---|---|
| Entidades diferentes | Conservar ambas |
| Hábito y schedule cambian en paralelo | Conservar ambos, viven en registros separados |
| Dos cambios del mismo campo | Gana la versión aceptada más reciente por servidor |
| Mismo completado repetido | Upsert idempotente |
| Completar y descompletar offline | Resolver por versión y conservar diagnóstico |
| Update contra entidad eliminada | Delete gana |
| Restore explícito | Crea una versión nueva |
| Nota editada en paralelo | Preservar copia de conflicto |
| Sesión Pomodoro repetida | Ignorar UUID ya procesado |
| XP y racha | Recalcular, no fusionar contadores |

### Notas

Una nota usa optimistic concurrency:

1. El cliente envía `base_version`.
2. Si coincide, Supabase acepta y aumenta `version`.
3. Si no coincide, Supabase devuelve conflicto.
4. Zentra conserva la versión remota.
5. Zentra crea una copia local titulada como conflicto.
6. El usuario decide qué texto conservar.

No se implementa merge automático de texto en V3.

### Eliminaciones

Las entidades sincronizables usan `deleted_at`.

- Un dispositivo que estuvo offline recibe el tombstone.
- El tombstone elimina la entidad de la vista local.
- Una mutación vieja no puede revivirla.
- Una restauración es una operación explícita.
- La purga física ocurre después de una ventana de retención definida.

## 14. Seguridad

### RLS

Cada tabla expuesta debe:

- Tener RLS habilitado.
- Permitir lectura sólo cuando `auth.uid()` coincide con `user_id`.
- Revocar `INSERT`, `UPDATE` y `DELETE` directos para clientes.
- Recibir escrituras sólo mediante la RPC de mutaciones.
- Tomar ownership desde `auth.uid()`, nunca desde el payload.
- Probar acceso negativo con dos cuentas distintas.

La RPC privilegiada usa `security definer`, `search_path` vacío y nombres de esquema
explícitos. Esas funciones validan identidad, versión, ownership e idempotencia antes
de tocar datos.

### Claves

- La app usa Project URL y publishable key.
- La publishable key puede estar en el cliente porque RLS protege los datos.
- La service role key nunca entra en Flutter, web, assets o repositorio.
- Operaciones privilegiadas viven en servidor.
- Los logs nunca incluyen cuerpos de notas, tokens ni payloads completos.

### RPC de mutaciones

El servidor toma el usuario desde la sesión autenticada. La RPC:

1. Busca `mutation_id`.
2. Si ya fue procesada, devuelve el ack anterior.
3. Valida `base_version`.
4. Bloquea el `user_sync_heads` de la cuenta.
5. Ejecuta la operación en transacción.
6. Incrementa `version` y asigna `server_revision`.
7. Registra el cambio en `sync_changes`.
8. Registra el resultado idempotente.

## 15. Autenticación por plataforma

### Web

- Google OAuth mediante redirect o popup.
- Dominio de producción verificado.
- Redirect local permitido sólo en desarrollo.
- Sesión restaurada por Supabase Flutter.

### Android

- Google provider.
- Package name definitivo.
- SHA-1 y SHA-256 de desarrollo y release.
- Deep link o callback configurado.

### iOS

- Google provider.
- Sign in with Apple.
- Bundle ID definitivo.
- URL schemes y callbacks.
- Revisión de Keychain y restauración de sesión.

### Cuenta local

"Continuar localmente" permanece disponible. Vincular con Google o Apple es una mejora,
no una condición para usar las funciones principales.

## 16. Logout, eliminación y privacidad

### Logout

- Termina la sesión remota.
- Detiene Realtime.
- Vacía mutaciones no enviadas sólo después de resolverlas con el usuario.
- Aísla o purga el cache remoto según la política de dispositivo compartido.
- Nunca muestra datos de la cuenta anterior al cambiar de usuario.

### Eliminación de cuenta

La app debe:

1. Exigir una sesión remota vigente.
2. Explicar qué se elimina.
3. Eliminar datos remotos.
4. Eliminar identidad.
5. Eliminar cache, outbox y recordatorios locales.
6. Revocar Sign in with Apple cuando aplique.
7. Volver a estado sin cuenta.

La Edge Function `delete-account` implementa los puntos 3 y 4 usando el usuario
obtenido del JWT. Su despliegue remoto y la validación end-to-end siguen siendo
gates de release. La reautenticación reciente y la revocación especial de Apple
siguen pendientes antes de habilitar Apple en producción.

También debe existir una ruta web para solicitar eliminación desde fuera de la
app.

### Privacidad

Antes de una beta externa:

- Publicar la versión actualizada de `docs/privacy-policy.html`.
- Declarar Supabase como procesador.
- Documentar categorías de datos sincronizados.
- Actualizar App Store Privacy Nutrition Labels.
- Actualizar Google Play Data Safety.
- Explicar que Notas dejan de ser exclusivamente locales al activar sync.
- Explicar que V3 no ofrece cifrado end-to-end.
- Mantener login local para quien no quiera nube.

El archivo local ya refleja la integración. La URL pública debe actualizarse
junto con la release que realmente envíe datos.

## 17. Estados de experiencia

La UI futura necesita un modelo estable, aunque FrontEnd decida su forma visual:

- `localOnly`
- `syncing`
- `synced`
- `offlineWithPending`
- `authRequired`
- `migrationRequired`
- `conflict`
- `errorRecoverable`
- `errorBlocking`

Datos mínimos visibles:

- Última sincronización exitosa.
- Cantidad de cambios pendientes.
- Botón de reintento.
- Estado sin conexión.
- Conflictos pendientes.

Una falla de red no debe bloquear Hoy, Hábitos, Notas o Pomodoro.

## 18. Gates de construcción

### Gate 0. Contrato y decisión

**Estado:** completo con este documento.

Entregables:

- Proveedor decidido.
- Arquitectura local-first.
- Scope de datos.
- Reglas de conflicto.
- Frontera con FrontEnd.

### Gate 1. Supabase local y esquema remoto

**Estado:** completo y validado localmente el 26 de julio de 2026.

**Se ejecutó sin tocar FrontEnd.**

Entregables:

- `supabase init`.
- Migraciones SQL versionadas.
- `user_sync_heads`, `sync_changes` y tablas de dominio.
- Constraints de identidad, ownership, versión y revisión.
- RLS.
- Seed de dos usuarios y datos aislados.
- pgTAP para ownership, idempotencia y conflictos.
- RPC de mutaciones.
- Pull incremental por revisión.

Gate:

- Usuario A nunca puede leer o mutar datos de B.
- Repetir `mutation_id` no duplica nada.
- `habit_day_states` no admite duplicados.
- Delete no se revive mediante una mutación vieja.
- Dos dispositivos de una misma cuenta reciben revisiones en orden y sin saltarse
  cambios confirmados.

Evidencia local:

- `supabase db reset` reconstruye esquema y seed.
- `supabase db lint --local --level warning` no reporta errores.
- `supabase test db` pasa 45 pruebas pgTAP.
- `supabase db diff --local --schema public,zentra_private` no encuentra drift.

### Gate 2. Motor de sync puro

**Estado:** completo y validado localmente el 26 de julio de 2026.

**Se ejecutó en paths nuevos, sin tocar providers, UI, `pubspec.yaml` ni archivos
reservados por FrontEnd.**

Entregables:

- Tipos inmutables para entidad, mutación, cambio remoto, ACK y conflicto.
- Contrato RPC compatible con `apply_sync_mutation` y `pull_sync_changes`.
- Reducer determinista de pull, rebase, ACK y segundo pull.
- Planner de push con una mutación lista por identidad lógica.
- Política de retry con backoff exponencial, jitter estable y `retry-after`.
- Máquina interna de estados y estado estable para experiencia.
- Fixture web más móvil con reloj fijo.
- Tests unitarios sin Flutter UI.

Gate:

- Pull, rebase, push y segundo pull son deterministas.
- La misma fixture produce siempre el mismo resultado.
- Reintentos no cambian el resultado.

Casos cerrados:

- Un cambio web y uno móvil sobre campos distintos convergen sin perder datos.
- Un ACK no adelanta el cursor durable antes del segundo pull.
- IDs provisionales de schedule y día se sustituyen por el ID canónico.
- Un completado remoto idéntico elimina la mutación redundante.
- Delete contra delete es idempotente.
- Update contra delete queda bloqueado como conflicto.
- Restore explícito crea una nueva intención rebasada.
- Mutaciones bloqueadas por falla no regresan solas a pendientes.
- Ediciones paralelas de una nota preservan la copia local y la remota.
- Resolver un conflicto exige una sincronización nueva.

Evidencia local:

- `flutter analyze` no reporta issues en el proyecto completo.
- `flutter test test/unit/sync` pasa 33 pruebas enfocadas.
- `flutter test test/unit` pasa 128 pruebas después de sumar Gate 2.

Límite conservador:

- Los tipos contemplan el contrato planeado de V3.
- El RPC actual de Gate 1 sólo ejecuta perfil, hábitos, horarios y estados diarios.
- Notas, Pomodoro terminado y preferencias permanecen inactivos hasta sus migraciones.
- Todavía no existe transporte Supabase, persistencia Drift de outbox ni wiring de UI.

### Gate 3. Consolidación local en Drift

**Estado:** completo y validado localmente el 27 de julio de 2026.

Entregables:

- Hábitos, logs, perfil y Pomodoro terminado en Drift.
- Migración idempotente desde SharedPreferences.
- Outbox, estado y conflicts.
- Repositorios locales actualizados.
- Backup compatible.

Gate:

- Conteos y checksums coinciden.
- Calendario y progreso no cambian resultados.
- Una falla vuelve al almacenamiento legacy.

#### Estado Gate 3A, base aislada

Completado el 26 de julio de 2026 sin tocar providers ni UI:

- `ZentraDatabase` subió de schema 1 a 2 con una migración aditiva que conserva Notas.
- Se agregaron 13 tablas para core, outbox, estado, conflictos, ownership local,
  notificaciones locales y evidencia de migración.
- Los 11 índices nuevos se crean tanto en instalaciones limpias como al migrar desde
  schema 1.
- `DriftCoreRepository` persiste perfil, hábitos, horarios, días completados, historial
  de tareas, sesiones de enfoque terminadas y progreso de enfoque por dueño.
- `DriftSyncRepository` persiste cursor, outbox, conflictos, timestamps, vínculo local
  y estado de migración por dueño.
- `LegacyCoreMigrator` lee primero todo el snapshot legacy, conserva las llaves, escribe
  core en una transacción y verifica conteos y checksum.
- Una marca completa vuelve la migración idempotente.
- La ausencia de datos legacy no borra datos Drift.
- Datos legacy válidos pero obsoletos no pueden sobrescribir un dueño Drift no vacío.
- El payload core de respaldo conserva los nombres legacy de `pomodoroStats` y añade el
  estado canónico para el siguiente restore.

Evidencia local de Gate 3A:

- 25 pruebas enfocadas pasan para repositorios, aislamiento de dueños, rollback,
  migración legacy y upgrade real de schema 1 a 2.
- Calendario y `ProgressEngine` producen el mismo resultado antes y después de migrar.
- El análisis dirigido de los archivos de Gate 3A no reporta issues.
- La suite unitaria completa pasa 161 pruebas.
- El análisis global no reporta issues en el snapshot actual del proyecto.

Límite histórico de Gate 3A:

- Los providers actuales todavía leen y escriben `SharedPreferences`.
- El cambio de entidad más outbox todavía no está cableado como una sola transacción.
- Export, restore, borrado de cuenta y Notas todavía no usan el snapshot core nuevo.
- El arranque todavía no ejecuta el migrador ni selecciona fallback.
- Estos puntos requieren el snapshot coordinado de FrontEnd antes de declarar Gate 3
  completo.

#### Estado Gate 3B, integración con runtime y FrontEnd

Completado el 27 de julio de 2026:

- `LocalPersistenceRuntime` ejecuta la migración verificada de todos los dueños
  existentes antes de montar la app.
- Cada dueño migrado usa Drift como fuente canónica. Una falla conserva el fallback
  legacy sólo para ese dueño, sin degradar a los demás.
- Hábitos, logs, perfil, tareas completadas, sesiones de enfoque terminadas y progreso
  de enfoque ya entran a los controladores mediante repositorios ligados al dueño.
- El Pomodoro conserva en `SharedPreferences` únicamente configuración y sesión en
  curso. Su historial y progreso durable viven en Drift.
- Export, restore y eliminación de espacio local operan sobre el mismo snapshot core
  que usa el runtime. Restore revierte core, cuenta y Notas si alguna etapa falla.
- El arranque, cambio de cuenta y creación de dueños nuevos usan factories por dueño y
  rechazan repositorios ligados a otra identidad.
- El Screen Reviewer usa el runtime y los repositorios de producción, no dobles de
  `SharedPreferences`.

Evidencia local de Gate 3B:

- `flutter analyze --no-pub` no reporta issues.
- 35 pruebas enfocadas pasan para runtime, backup, restore, eliminación, sesión y
  Pomodoro.
- La suite completa actual pasa 575 pruebas.
- El Screen Reviewer pasa 184 de 184 capturas en iPhone 16e, iPhone 17 Pro Max,
  iPad mini y iPad Pro 11-inch.
- La inspección visual no encontró clipping, overflow ni una ruta bloqueada en esos
  cuatro tamaños.

Límite al cerrar Gate 3, antes de iniciar Gate 4:

- Las escrituras locales todavía no crean una mutación de outbox en la misma
  transacción. Ese cableado se activa con el transporte de Gate 6.
- En ese corte aún no se inicializaba `supabase_flutter` ni existía una sesión OAuth
  remota. El estado actualizado continúa en Gate 4.

### Gate 4. Supabase Auth

**Estado:** cliente integrado localmente el 27 de julio de 2026. La validación
OAuth real permanece pendiente de un proyecto dev y credenciales de proveedor.

Entregables:

- `supabase_flutter`.
- Inicialización por ambiente.
- Google web, Android e iOS.
- Apple iOS.
- Adaptador de identidad.
- Sesión restaurable.
- Logout y cambio de cuenta.

Gate:

- Una identidad tiene el mismo `auth.uid()` en las tres plataformas.
- No existe contraseña local que enviar.
- Cancelar OAuth deja el espacio local intacto.

#### Estado de la integración del cliente

- `supabase_flutter` se inicializa por `--dart-define` sólo cuando existen URL y
  publishable key válidas.
- Google y Apple requieren flags explícitos por ambiente. Una compilación sin
  providers mantiene las acciones remotas inactivas.
- Google usa OAuth en web, Android e iOS. Apple usa OAuth en iOS.
- Android e iOS registran
  `com.jesutorr.appzentra://login-callback`.
- Sesión y PKCE se guardan con almacenamiento seguro de plataforma, no con el
  `SharedPreferences` default del SDK.
- `auth.uid()` se convierte en el owner canónico del shadow local.
- Una cuenta cloud almacenada no abre su cache si Supabase no presenta una
  sesión vigente.
- Logout remoto bloquea el shadow sin borrar el espacio local previo.
- Autenticar desde la entrada principal abre el shadow cloud sin asumir un
  espacio fuente. Vincular desde Ajustes ejecuta el preview y checksum de Gate
  5 antes de activar el nuevo owner.

Evidencia local:

- La app arrancó en iPhone 16e contra el Supabase local configurado.
- El build iOS para simulador y el APK debug Android terminaron correctamente.
- El esquema local reconstruye, pasa lint y pgTAP, y no presenta schema drift.
- El análisis global no reporta issues y la suite completa pasa 575 pruebas.
- La matriz final de FrontEnd suma 184 de 184 capturas. Los iPhone se repitieron
  de forma aislada después de una caída de `CoreSimulatorService`.
- Pruebas dirigidas cubren configuración, almacenamiento seguro, owner por
  `auth.uid()`, restauración, logout y la acción OAuth de UI.

Pendiente externo para cerrar Gate 4:

- Configurar Google y Apple en un proyecto dev.
- Registrar callbacks, client IDs, fingerprints y el dominio web definitivo.
- Probar que la misma cuenta entrega el mismo `auth.uid()` en web, Android e iOS.
- Probar cancelación y retorno real de cada proveedor.

La guía operativa está en
[`supabase-auth-setup.md`](supabase-auth-setup.md).

### Gate 5. Vinculación y migración a nube

**Estado:** completo para la vinculación local al shadow cloud y validado
localmente el 27 de julio de 2026.

Entregables:

- Snapshot local.
- Preview de migración.
- Import idempotente.
- Remapeo de owner.
- Comparación de checksums.
- Merge de cuenta remota existente.

Gate:

- Vincular no pierde datos.
- Repetir vinculación no duplica.
- Interrumpir el proceso conserva local.

Implementación cerrada:

- Ajustes muestra un preview por dominio antes de abrir Google o Apple.
- La sesión conserva el owner local pendiente durante OAuth y no expone el
  shadow remoto antes de terminar la preparación.
- La copia corre en una transacción Drift, remapea IDs y relaciones con UUIDv5,
  compara conteos y checksum y registra estados `running`, `completed` o
  `failed`.
- El espacio fuente queda intacto. Un reintento con el mismo checksum es un
  no-op y no agrega mutaciones duplicadas.
- Si la preparación falla, Supabase cierra la sesión recién creada y la sesión
  local anterior permanece activa.
- Una cuenta remota con datos conserva su contenido y recibe el merge de los IDs
  deterministas que provienen del espacio local.

Evidencia local:

- La prueba de migración cubre preview, copia de perfil, hábito y nota,
  preservación del source, orden de outbox, link a `auth.uid()` e idempotencia.
- Las pruebas de sesión cubren el owner fuente durante OAuth y el rollback
  visible cuando falla el checksum.
- La prueba widget cubre el texto de seguridad, los conteos y la confirmación
  antes de lanzar OAuth.
- Una integración contra Supabase local crea una identidad real, vincula el
  espacio y descarga perfil y hábito en una segunda base Drift.

### Gate 6. Sync de un dispositivo

**Estado:** completo para perfil, hábitos, horarios y completados diarios,
validado contra Supabase local el 27 de julio de 2026.

Entregables:

- Escritura local con outbox.
- Push y pull.
- Backoff.
- Estado observable.
- Resync completo de recuperación.

Gate:

- Crear, editar, archivar, restaurar y eliminar funciona online y offline.
- Cerrar la app con pendientes no los pierde.

Implementación cerrada:

- Las escrituras cloud crean entidad y mutación en la misma transacción Drift.
- El dispositivo, cursor, outbox, conflictos, reintentos y timestamps de éxito
  sobreviven al relanzamiento.
- `SyncCoordinator` ejecuta primer pull, reconciliación, push ordenado y segundo
  pull. Sólo permite una corrida activa por owner.
- La outbox usa orden persistente con resolución de segundos. Esto garantiza
  que `profile`, `habit` y `habit_schedule` no se reordenen por UUID al recargar
  SQLite.
- Ajustes presenta sincronizando, al día, offline con pendientes, auth expirada,
  conflicto y error, además de sincronización manual.
- El flujo real contra Postgres cubre crear, editar, archivar, restaurar,
  completar, desmarcar y eliminar. Otro Drift independiente descarga las
  revisiones por RPC.
- Las pruebas sin red conservan la outbox y la vacían al recuperar conexión.

Evidencia final del snapshot:

- `flutter analyze --no-pub` termina sin issues.
- La suite general pasa 585 pruebas. Las 2 integraciones condicionadas por
  variables se omiten en esa corrida y pasan por separado contra Supabase local.
- `supabase db reset`, lint, 45 pruebas pgTAP y schema diff terminan verdes y
  sin drift.
- Los builds iOS Simulator y APK debug terminan correctamente.
- Screen Reviewer pasa 184 de 184 capturas en dos iPhone y dos iPad. El reporte
  está en `build/screen-review/20260727-104704/report.md`.

Ese límite correspondía al cierre de Gate 6. Gate 7 amplió el contrato sobre la
misma outbox y el mismo cursor durable, sin crear una segunda ruta de datos.

### Gate 7. Multidispositivo y Realtime

**Estado:** completo y validado contra Supabase local el 27 de julio de 2026.

Vertical multidispositivo cerrado:

- `notes`, `note_reminders` y `note_reviews` usan RLS de lectura por
  `auth.uid()` y escrituras exclusivamente por RPC.
- Cada escritura local guarda entidad y outbox en una sola transacción. Un test
  fuerza el rechazo del outbox y confirma rollback de la nota.
- Contenido, tags, pin, archivo, tombstones, recordatorios y repasos hacen
  push/pull incremental con versión y revisión de servidor.
- El ID de notificación permanece local por dispositivo. Al descargar un
  recordatorio se conserva el binding previo o se deriva un ID local estable.
- Dos bases Drift independientes descargan la misma nota. Una edición paralela
  crea `blockedByConflict` y conserva el cuerpo local y el remoto.
- La vinculación local a `auth.uid()` ya encola y sube las notas copiadas al
  shadow cloud.
- Tareas terminadas usan upsert y tombstone. Las sesiones de enfoque terminadas
  son eventos idempotentes y XP, minutos y rachas se derivan localmente.
- El tema es la única preferencia portable en V3. Permisos, sonidos, duración
  del timer, IDs de notificación y Pomodoro activo permanecen por dispositivo.
- `sync_changes` emite una señal Postgres Changes filtrada por `auth.uid()`.
  El cliente confirma el JWT, reintenta el arranque en frío con backoff y
  ejecuta el pull incremental con debounce. Pulls de seguridad a los 2, 5 y
  15 segundos, y después cada 60 segundos, cubren una primera señal perdida sin
  convertir Realtime en fuente de verdad.
- Después de materializar el pull, Riverpod refresca hábitos, notas, perfil,
  historial, enfoque y tema sin reiniciar el timer activo.
- `supabase db reset`, 119 pruebas pgTAP, lint y schema diff pasan sin drift.
- Cinco escenarios Flutter contra Supabase local validan hábitos, ciclo de vida
  de notas, conflictos paralelos, historial, enfoque, tema, Realtime y
  vinculación local a `auth.uid()`.
- `flutter analyze --no-pub` termina sin issues y la suite completa pasa 594
  pruebas, con cinco escenarios externos omitidos en esa corrida y aprobados
  por separado contra Supabase local.
- Los builds Web, APK debug e iOS Simulator terminan correctamente.
- El Screen Reviewer pasa 184 de 184 capturas en iPhone 16e, iPhone 17 Pro Max,
  iPad mini e iPad Pro. La inspección visual de Hoy, Notas, Pomodoro,
  onboarding y Ajustes confirma que no hay clipping, overflow ni rutas
  bloqueadas. El reporte está en
  `build/screen-review/20260727-120448/report.md`.
- Después de migrar el proyecto a Flutter 3.44.8, un smoke adicional con SDK
  externo pasa 46 de 46 capturas en iPhone 17 Pro Max. Incluye la pantalla de
  hábito ajustada al contrato de ink de Material. El reporte está en
  `build/screen-review/20260727-external-sdk-smoke/report.md`.
- La captura de onboarding etiquetada `keyboard` confirma el estado enfocado,
  pero el simulador no presentó el teclado virtual. La cobertura visual del
  teclado físico en pantalla queda como una limitación explícita de esta
  corrida, no como una aprobación implícita.

Entregables:

- Web más iOS.
- Web más Android.
- Señales Realtime.
- Conflictos de notas.
- Tombstones.
- Reprogramación local de recordatorios.

Gate:

- Un cambio web aparece al abrir móvil.
- Un móvil offline sube al reconectar.
- Dos dispositivos no duplican XP.
- Un conflicto de nota conserva ambos textos.

### Gate 8. Cumplimiento y beta

Entregables:

- Eliminación de cuenta.
- Política de privacidad.
- Data Safety.
- App Store disclosures.
- Observabilidad sin PII.
- Recovery runbook.
- Beta interna.

Gate:

- Matriz completa web, iPhone, iPad y Android.
- Ningún error de ownership.
- Restore desde nube probado en instalación limpia.

## 19. Workflow local

Supabase CLI `2.109.1` está disponible en el entorno actual.

Comandos que usarán los gates de backend:

```bash
supabase start
supabase db reset
supabase db lint
supabase test db
```

Checks Flutter después de integrar código:

```bash
./flutter/bin/flutter analyze
./flutter/bin/flutter test
./flutter/bin/dart run tool/run_screen_reviewer.dart
```

No se ejecuta `supabase db push` contra un proyecto remoto hasta tener:

- Proyecto dev explícitamente aprobado.
- Migraciones locales verdes.
- RLS probado.
- Backup o rollback documentado.
- Variables de ambiente revisadas.

## 20. Ambientes

| Ambiente | Propósito | Datos |
|---|---|---|
| Local | Desarrollo y CI | Ficticios |
| Dev Cloud | OAuth y pruebas reales | No productivos |
| Production | Usuarios reales | Reales |

Cada ambiente tiene:

- Project ID distinto.
- Redirects distintos.
- Google OAuth client separado cuando aplique.
- Apple configuration separada cuando aplique.
- Variables de build explícitas.

No se comparte una base de producción con previews o pruebas automatizadas.

## 21. Pruebas obligatorias

### Base y seguridad

- RLS positivo y negativo.
- Relaciones cruzadas bloqueadas.
- Mutación repetida.
- Versión vieja rechazada.
- Tombstone protegido.
- Purga por usuario.

### Migración

- Usuario sin datos.
- Usuario con todos los dominios.
- Dos cuentas locales.
- Backup v1, v2 y v3.
- JSON parcial.
- Datos corruptos.
- Migración interrumpida.
- Ejecución repetida.

### Sync

- Online normal.
- Inicio offline.
- Pérdida de red a mitad de push.
- Ack perdido después de commit remoto.
- App cerrada con outbox.
- Sesión expirada.
- Dos dispositivos cambian entidades diferentes.
- Dos dispositivos cambian el mismo hábito.
- Dos dispositivos editan la misma nota.
- Delete contra update.
- Realtime desconectado.
- Resync completo.

### Plataforma

- Chrome, Safari y Firefox.
- iPhone e iPad.
- Android phone y tablet.
- Instalación limpia.
- Upgrade desde V2.
- Logout y cambio de cuenta.
- Eliminación de cuenta.

## 22. Observabilidad

Métricas permitidas:

- Duración de sync.
- Cantidad de cambios enviados y recibidos.
- Tamaño de outbox.
- Edad del pendiente más antiguo.
- Reintentos.
- Conflictos por tipo.
- Rechazos de versión.
- Errores de autenticación por código.

Nunca registrar:

- Cuerpo o título de notas.
- Nombre de hábitos.
- Tokens.
- Email completo.
- Payload completo.
- Claves.

## 23. Costos y operación

Durante desarrollo se puede usar Supabase Free.

Antes de producción pública se recomienda Pro porque:

- Un proyecto gratuito puede pausarse por inactividad.
- Producción necesita backups automáticos.
- Producción necesita mejor retención de logs.
- El costo base es predecible.

El plan debe incluir alertas de uso para:

- MAU.
- Database size.
- Egress.
- Realtime messages.
- Storage.

## 24. Riesgos principales

| Riesgo | Mitigación |
|---|---|
| Pérdida al migrar SharedPreferences | Snapshot, transacción, checksums y fallback |
| Sobrescritura de notas | Optimistic concurrency y copia de conflicto |
| Doble XP | Eventos idempotentes y progreso derivado |
| Resurrección tras delete | Tombstones y delete gana |
| Relojes distintos | `server_revision` y hora de servidor |
| Realtime perdido | Pull incremental al iniciar y reanudar |
| Recordatorios duplicados | Binding local por dispositivo |
| Fuga entre usuarios | RLS, foreign keys compuestas y tests con dos cuentas |
| FrontEnd pisado | Paths aislados y ventana de integración |
| Privacidad desactualizada | Gate de cumplimiento antes de beta |
| Dependencia de proveedor | Postgres, repositorios y export completo |

## 25. Definition of Done de Zentra V3 Sync

- Google funciona en web, Android e iOS.
- Apple funciona en iOS.
- Continuar localmente sigue disponible.
- Vincular conserva todo el historial.
- Una instalación nueva recupera datos remotos.
- Web y móvil convergen al mismo estado.
- Offline permite leer y escribir.
- Reintentos son idempotentes.
- Conflictos de nota preservan ambos textos.
- Deletes no se revierten solos.
- XP y rachas no se duplican.
- RLS impide acceso cruzado.
- Eliminación borra cuenta y datos.
- Privacidad y tiendas reflejan la nube.
- Tests locales, base, integración y Screen Reviewer están verdes.

## 26. Primer bloque de trabajo recomendado

Mientras FrontEnd continúa:

- [x] Crear el scaffold local `supabase/`.
- [x] Escribir las migraciones de `user_sync_heads`, `sync_changes`, `profiles`,
  `habits`, `habit_schedules`, `habit_day_states` y `processed_mutations`.
- [x] Escribir RLS y constraints compuestas.
- [x] Crear pgTAP con usuarios A y B.
- [x] Definir los tipos puros de mutación bajo `lib/domain/sync/`.
- [x] Implementar el reducer de conflictos con fixtures, sin tocar providers.
- [x] Crear la base aislada de Gate 3A con schema Drift, repositorios y migración
  idempotente.
- [x] Cablear providers, backup y arranque durante el handoff coordinado de FrontEnd.
- [x] Validar el runtime real con la suite completa y Screen Reviewer.
- [x] Integrar el SDK, almacenamiento seguro, deep links y UI OAuth de Gate 4.
- [x] Implementar preview, copia verificada e idempotencia de Gate 5.
- [x] Integrar outbox y push/pull del núcleo de perfil y hábitos de Gate 6.
- [ ] Verificar Google y Apple con credenciales reales en un proyecto dev.
- [x] Ampliar tablas, RPC y Drift sync a notas, recordatorios y repasos.
- [x] Ampliar tablas, RPC y Drift sync a historial, Pomodoro y preferencias.
- [x] Integrar señales Realtime.
- [x] Validar conflictos de notas en dos dispositivos.

Este bloque prueba las partes más riesgosas sin interferir con el rebranding.

## 27. Referencias

- [Plan maestro V2](zentra-calma-precisa-notas-activas-plan-v2.md)
- [Revisión de integración](zentra-system-integration-rebranding-review.md)
- [Persistencia de hábitos actual](../lib/infrastructure/local_storage_repository.dart)
- [Repositorio Drift de Notas](../lib/infrastructure/drift_note_repository.dart)
- [Modelo de autenticación local](../lib/domain/auth_models.dart)
- [Supabase Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Realtime](https://supabase.com/docs/guides/realtime/subscribing-to-database-changes)
- [Flutter stream](https://supabase.com/docs/reference/dart/stream)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111)
