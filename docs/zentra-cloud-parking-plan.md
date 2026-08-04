# Zentra: contrato de nube estacionada

Estado: activo desde el 3 de agosto de 2026

## Decisión

Zentra funciona temporalmente sólo en el dispositivo. Supabase, OAuth,
sincronización, Realtime y eliminación remota quedan fuera del runtime y de la
interfaz hasta que la experiencia local esté completa.

Esto es un estacionamiento reversible, no una eliminación de la integración.
Se conservan el código, las migraciones, los vínculos locales y la outbox para
poder auditarlos antes de una futura reactivación. No se modifica el proyecto
remoto.

## Invariantes de datos

1. Ningún hábito, nota, registro, sesión, perfil o progreso se borra al
   estacionar la nube.
2. Una identidad antes vinculada conserva exactamente el mismo `ownerId`.
3. La identidad deja de estar activa como cloud y guarda localmente el proveedor
   anterior y la fecha de estacionamiento.
4. La sesión segura de Supabase se elimina sin una llamada de red.
5. Los vínculos y mutaciones pendientes ya existentes se congelan. Las nuevas
   escrituras locales no generan outbox.
6. `Salir de este espacio` afecta sólo la sesión del dispositivo.
7. `Eliminar espacio de este dispositivo` afecta sólo la copia local. No borra
   una identidad o datos que todavía existan en Supabase.

## Kill switch

`ZENTRA_CLOUD_ENABLED` es el switch raíz y su valor por default es `false`.
Mientras esté apagado:

- `bootstrapSupabase` termina antes de leer o validar variables `SUPABASE_*`;
- no existe gateway de autenticación ni transporte de sync;
- no se restaura una identidad remota;
- no se escucha Realtime;
- `LocalPersistenceRuntime` no habilita owners vinculados;
- Acceso y Ajustes no muestran acciones de nube.

La build de producción de esta fase no debe incluir
`--dart-define=ZENTRA_CLOUD_ENABLED=true`.

## Experiencia visible

- Acceso: `Usar en este dispositivo` y `Restaurar un respaldo`.
- Ajustes: tarjeta informativa `Cuenta y sincronización en la nube` con el
  mensaje de que volverán cuando Zentra local esté completa.
- Sesión: `Salir de este espacio`.
- Eliminación: `Eliminar espacio de este dispositivo`.
- Error de preparación: `Reintentar` y `Volver al acceso` siempre disponibles.

## Reactivación futura

La nube sólo puede volver en una fase separada y explícitamente aprobada. Antes:

1. Terminar y aprobar las superficies locales pendientes.
2. Definir la política para cuentas y filas remotas creadas antes del
   estacionamiento.
3. Auditar que reactivar un owner estacionado no duplique ni sobrescriba datos.
4. Validar RLS, RPC, outbox, pull, Realtime y conflictos con Supabase local.
5. Desplegar y probar `delete-account` en dev antes de exponer eliminación.
6. Revalidar OAuth, redirects, Google y Apple por ambiente.
7. Actualizar privacidad, soporte y App Store Privacy antes del release.
8. Ejecutar suite completa, Screen Reviewer, matriz física y prueba destructiva
   con una cuenta exclusiva de QA.

## Gate de cierre local-only

- TECHNICAL PASS: análisis, pruebas enfocadas y suite completa.
- CONTRACT PASS: ausencia de OAuth/sync, conservación del owner y salida del
  estado de error.
- VISUAL PASS: Acceso, Ajustes y error de sesión en light y AMOLED.
- DEVICE PASS: Release sin defines de Supabase en el iPhone físico indicado.
- URI APPROVED: Uri confirma el recorrido. Hasta entonces el tracker permanece
  `Activa`.
