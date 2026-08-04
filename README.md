# Zentra

Zentra es una app Flutter local-first para organizar hábitos, notas, sesiones de
enfoque y progreso personal. La experiencia principal funciona sin cuenta remota
ni conexión a internet.

## Estado actual

- Acceso local y restauración desde respaldo.
- Onboarding, hábitos, calendario, notas, Pomodoro, progreso y perfil.
- Temas claro, oscuro y del sistema.
- Navegación adaptable para teléfono y tablet.
- Recordatorios locales, quick actions y manejo del ciclo de vida.
- Exportación, restauración y eliminación de datos por dueño.

La nube está estacionada en la build vigente. Supabase no se inicializa, no se
restaura una sesión remota, no se crea outbox y la interfaz no muestra acceso,
vinculación, cierre o eliminación de cuenta remota. Un espacio que antes estuvo
vinculado conserva el mismo identificador de dueño y todos sus datos de Drift,
pero se abre como espacio local.

La integración de Supabase permanece aislada y compilable para retomarla cuando
el producto local esté cerrado. Reactivarla requiere el flag explícito
`ZENTRA_CLOUD_ENABLED=true`, además de las variables del ambiente y todos los
gates de seguridad descritos en la documentación. Incluir sólo URL y clave ya
no enciende la nube por accidente.

## Arquitectura

```text
lib/
├── domain/          # Entidades y contratos sin UI
├── infrastructure/  # Drift, SharedPreferences y servicios de plataforma
├── application/     # Controladores y estado con Riverpod
└── presentation/    # Pantallas, widgets, tema y layout adaptable
```

Drift es la fuente canónica por dueño para perfil, hábitos, logs, tareas
completadas, sesiones terminadas, tema portable y progreso de enfoque.
SharedPreferences queda limitado a sesión local, cache de tema para el arranque,
configuración específica del dispositivo, Pomodoro en curso y fallback por
dueño durante la migración legacy.

Al arrancar, `LocalPersistenceRuntime` migra cada dueño existente a Drift,
verifica conteos y checksum, y mantiene el almacenamiento anterior únicamente
para el dueño cuya migración haya fallado. Notas ya usan Drift con aislamiento
por dueño.

## Ejecutar localmente

El repositorio incluye su Flutter SDK bajo `flutter/`.

```bash
./flutter/bin/flutter pub get
./flutter/bin/flutter run
```

## Gates de calidad

```bash
./flutter/bin/flutter analyze --no-pub
./flutter/bin/flutter test --no-pub
./flutter/bin/dart run tool/run_screen_reviewer.dart
```

El Screen Reviewer usa widgets y repositorios de producción, recorre el producto
en simuladores iPhone y iPad, toma 41 capturas por dispositivo y deja el reporte
bajo `build/screen-review/<timestamp>/report.md`.

## Supabase estacionado

El trabajo de nube queda apartado bajo `supabase/` y su diseño completo vive en
[`docs/zentra-v3-supabase-auth-sync-plan.md`](docs/zentra-v3-supabase-auth-sync-plan.md).
El contrato actual vive en
[`docs/zentra-cloud-parking-plan.md`](docs/zentra-cloud-parking-plan.md). No se
ejecuta `supabase db push`, no se despliegan funciones y no se habilita OAuth
remoto durante esta fase.

La integración local completa se verifica contra Postgres y Realtime reales con:

```bash
./flutter/bin/flutter test --no-pub \
  test/integration/supabase_sync_integration_test.dart \
  --dart-define=SUPABASE_TEST_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_TEST_PUBLISHABLE_KEY=VALOR_LOCAL
```

## Documentación

- [Screen Reviewer](docs/screen-reviewer.md)
- [Contrato de nube estacionada](docs/zentra-cloud-parking-plan.md)
- [Plan V3 de autenticación y sincronización](docs/zentra-v3-supabase-auth-sync-plan.md)
- [Configuración de Supabase Auth](docs/supabase-auth-setup.md)
- [Plan de experiencia V2](docs/zentra-calma-precisa-notas-activas-plan-v2.md)
