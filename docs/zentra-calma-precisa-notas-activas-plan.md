# Plan maestro de producto, experiencia y sistema de Zentra

## Calma precisa con juego, Notas activas y presencia útil

**Versión:** 3.2  
**Fecha:** 25 de julio de 2026  
**Estado:** UX Lab aprobado; fundación visual e Inicio implementados y validados  
**Snapshot de auditoría inicial:** working tree local `1.0.20+24`  
**Estado ejecutable actual:** working tree local `2.0.0+25`  
**Corte de rebranding:** `2.0.0+25`  
**Plataforma premium inicial:** iOS  
**Plataformas previstas:** iPhone, iPad, Android y web  
**Versión anterior:** [Plan maestro 2.0 archivado](zentra-calma-precisa-notas-activas-plan-v2.md)  

> **Nota de frescura:** el repositorio contiene cambios locales amplios y archivos
> sin commit. Las referencias de código documentan el estado ejecutable observado
> el 25 de julio de 2026. Deben volver a verificarse antes de implementar cada fase.

## 1. Resumen ejecutivo

Zentra evolucionará sobre la dirección **Calma precisa**, conservando los
elementos que ya la hacen reconocible:

- Calidez personal.
- Categorías con color e iconografía propia.
- Progreso diario visible.
- Rachas, XP, niveles y logros.
- Celebraciones con significado.
- Pomodoro conectado con la rutina.
- Lenguaje optimista que no castiga.
- Funcionamiento local como opción completa, sin anuncios ni suscripciones.
- Cuenta opcional para continuidad entre plataformas.

El objetivo no es convertir Zentra en otra aplicación minimalista genérica. El
objetivo es retirar ruido, ordenar la experiencia y hacer que su personalidad se
sienta intencional en cada superficie.

El plan mantiene **Notas activas** como dominio principal:

> Zentra no sólo guarda lo que una persona quiere recordar. Le ayuda a volver a
> ello en el momento correcto y convertirlo en una acción.

También incorpora una nueva dimensión del producto:

> La sensación premium no termina al cerrar Zentra. El sistema puede mostrar la
> siguiente acción, el estado de un enfoque o un recordatorio sin exigir otra
> apertura de la aplicación.

La inversión se ordenará en cuatro capas:

1. **Calma y accesibilidad:** movimiento reducido, feedback sensorial coherente,
   audio que convive con el sistema y rendimiento validado.
2. **Identidad y usabilidad:** sistema visual, talismanes, navegación adaptable y
   pantallas rediseñadas.
3. **Fuente de verdad:** persistencia transaccional, comandos idempotentes,
   recordatorios y migraciones seguras.
4. **Presencia útil:** Live Activities, widgets, acciones de notificación y App
   Intents con privacidad y degradación explícita.

## 2. Norte del producto

La experiencia completa debe cumplir esta promesa:

> En tres segundos entiendo mi día, con un toque avanzo y cada progreso se
> siente personal, cálido y merecido.

Los dominios del producto forman un solo ciclo:

- **Hábitos:** lo que quiero repetir.
- **Notas:** lo que quiero conservar y comprender.
- **Recordatorios:** cuándo quiero volver.
- **Pomodoro:** cuándo decido actuar.
- **Progreso:** cuánto he avanzado.
- **Sistema:** cómo Zentra me acompaña sin interrumpir.

Una experiencia premium:

- Explica por sí sola qué puede hacer el usuario.
- Mantiene una jerarquía visual inequívoca.
- Responde con precisión a cada interacción.
- Usa color, movimiento, sonido y haptics sólo cuando aportan significado.
- Reduce aperturas innecesarias.
- Mantiene una fuente de verdad para cada dato.
- Protege información sensible fuera de la aplicación.
- Degrada con honestidad cuando una capacidad no está disponible.
- Se siente parte de un sistema, no una colección de pantallas.

### 2.1 Decisiones de experiencia incorporadas

Esta versión agrega decisiones tomadas durante la revisión del UX Lab:

1. **Calma precisa es un universo, no una skin.** Las cinco propuestas comparan
   modelos de producto, no recolors:
   - Guía diaria: prioriza una siguiente acción.
   - Agenda viva: ordena la experiencia alrededor del tiempo y el calendario.
   - Progreso vivo: hace visible el juego, los niveles y la colección.
   - Compañera Zentra: ofrece sugerencias locales, explicables y descartables.
   - Estudio modular: aprovecha iPad y la futura web como espacio de trabajo.
2. **Lenguaje cotidiano.** No se usará `ritual` en etiquetas o mensajes para el
   usuario. Se prefieren hábito, actividad, ritmo, constancia, sesión y progreso.
3. **Acceso local-first.** Google será el camino principal futuro para identidad
   multiplataforma, pero usar Zentra sin cuenta seguirá siendo una experiencia
   completa. Restaurar un respaldo aparece antes del onboarding.
4. **Calendario descubrible.** En móvil vive en el encabezado y también se abre
   desde fechas y recordatorios. En tamaños amplios forma parte de la navegación
   persistente.
5. **Gamificación con color.** El perfil concentra nivel, XP, retos opcionales,
   colección y logros. Las categorías conservan color en Hoy, Hábitos,
   Calendario, Progreso y Perfil.
6. **Burbujas como firma de Enfoque.** La animación se conserva y evoluciona.
   Las burbujas representan categorías, permanecen detrás del temporizador y se
   vuelven estáticas con Reduced Motion.
7. **Guía diaria es la base de producto aprobada.** Mantiene una siguiente acción
   clara y el sistema completo disponible. Hereda el juego y la colección de
   Progreso vivo, el calendario visible de Agenda viva, la explicación local y
   descartable de Compañera Zentra, y la composición amplia de Estudio modular.
   Esas aportaciones se integran como capacidades, no como cinco interfaces
   simultáneas.

Estas decisiones son parte del contrato de producto. No son decoración
postergable.

### 2.2 Estado del UX Lab

El laboratorio de diseño ya cumple su función de decisión previa a producción:

- Compara cinco modelos de Calma precisa con diferencias reales de arquitectura.
- Recorre dieciocho estados de producto en iPhone e iPad.
- Mantiene Inicio, Acceso, Bienvenida, Hoy, hábitos, Notas, Enfoque, Progreso,
  Calendario, Perfil, Ajustes y superficies del sistema dentro del mismo lenguaje.
- Permite crear un hábito desde Hoy.
- Conserva en Nuevo hábito las categorías Agua, Movimiento, Sueño, Foco y Varios,
  frecuencia, selección de días, recordatorio y vista previa.
- Permite iniciar Enfoque sin nota, hábito o título.
- Conserva el dial de 5 a 60 minutos, modo rápido, ciclo y burbujas de categoría.
- Presenta cuenta como opción futura sin degradar el modo 100% local ni restaurar
  respaldo.
- Hace visibles calendario, gamificación, privacidad y Reduced Motion.

El UX Lab es evidencia de intención, no evidencia de calidad de producción.
Cada pantalla se vuelve a construir con widgets reales, datos reales y el Screen
Reviewer antes de considerarse terminada.

## 3. Evaluación del feedback del equipo

El feedback de integración premium contiene una dirección valiosa y un
diagnóstico local mayormente correcto. No se incorpora de forma literal. Cada
propuesta se clasifica por evidencia, impacto y riesgo.

### 3.1 Decisiones aceptadas

| Propuesta | Decisión del plan | Motivo |
|---|---|---|
| Reduced Motion central | Aceptada como P0 | Es accesibilidad básica y hoy no existe una política común |
| Reducir haptics duplicados | Aceptada como P0 | El patrón actual puede apilar varios impactos por una acción |
| Core Haptics | Aceptado con fallback | Permite una firma sensorial corta y propia en hardware compatible |
| Conservar `audioplayers` | Aceptada | La necesidad actual es un asset breve, no un motor de reproducción complejo |
| Audio iOS `ambient` | Aceptada | Convive con audio de otras apps y respeta Silent Mode |
| Inicialización de sonido en cold start | Aceptada | El setting debe funcionar sin visitar Ajustes |
| ProMotion | Validación, no implementación | `CADisableMinimumFrameDurationOnPhone` ya está configurado |
| Live Activity de Pomodoro | Aceptada | Es la integración de sistema con mayor valor y mejor ajuste al producto |
| Drift como persistencia Flutter objetivo | Aceptada | Notas, historial, migraciones y consultas ya superan el modelo JSON |
| Widget informativo antes del interactivo | Aceptada | Reduce riesgo y prueba el valor antes de permitir mutaciones |
| App Intents como dirección moderna | Aceptada | Reutiliza acciones en Siri, Shortcuts, widgets y Spotlight |
| Acciones de notificación por fases | Aceptada | Navegar es menos riesgoso que mutar datos con la app cerrada |
| Privacidad de Lock Screen | Aceptada | Hábitos, notas y nombres de enfoque pueden ser sensibles |
| Android con fallback explícito | Aceptada | La ausencia de paridad no debe ocultarse |
| Rive sólo como spike | Aceptada | Una dependencia visual debe demostrar una mejora medible |
| HealthKit sólo para mindfulness real | Aceptada como candidato tardío | Productividad genérica no equivale a una sesión mindful |
| Sync como decisión separada | Aceptada | CloudKit, backup y backend neutral resuelven problemas distintos |

### 3.2 Propuestas aceptadas con una corrección

#### Drift y extensiones nativas

Drift resuelve transacciones, migraciones, consultas tipadas y concurrencia entre
isolates Dart. No convierte automáticamente una base Dart en una API disponible
para una extensión Swift.

Los widgets se ejecutan en un proceso separado. Un `AppIntent` de widget puede
ejecutarse dentro de la extensión. Antes de permitir que complete hábitos con la
aplicación cerrada se debe elegir y probar una estrategia:

1. Abrir Zentra y ejecutar el comando en el proceso de la aplicación.
2. Compartir un archivo SQLite dentro del App Group y definir ownership nativo
   explícito.
3. Usar una cola de comandos idempotentes en el App Group y reconciliarla desde
   la aplicación.

**Decisión:** Drift es la fuente canónica Flutter. Las mutaciones nativas quedan
bloqueadas hasta completar un spike de proceso, bloqueo, protección de datos e
idempotencia.

#### Core Haptics como P0

Core Haptics no debe añadirse antes de centralizar los callers actuales. Primero
se elimina la duplicación. Después se prueba un solo patrón firma.

**Decisión:** la gramática háptica completa es P0. La adopción del engine nativo
ocurre dentro de esa fase, con fallback único en hardware no compatible.

#### Widget después de Live Activities

El widget informativo no depende técnicamente de que la Live Activity esté
terminada. Ambos sí comparten WidgetKit, packaging, diseño glanceable y App Group.

**Decisión:** Live Activity mantiene prioridad de producto. La base de la
extensión se diseña para soportar después el widget sin rehacer packaging.

#### Backup antes de sincronización

Un archivo en iCloud no es una base sincronizada. Un backup automático puede ser
útil, pero debe ser versionado, recuperable y verificable.

**Decisión:** primero exportación e importación segura sobre Drift. El backup
automático es una entrega separada. La sincronización continua necesita otra
decisión.

### 3.3 Trabajo que no se incorpora ahora

- Migrar a `just_audio` sin una necesidad de reproducción más compleja.
- Introducir Rive en todas las celebraciones.
- Suponer que Drift resuelve por sí solo escrituras desde Swift.
- Completar hábitos desde un widget reescribiendo JSON en
  `SharedPreferences`.
- Usar `icloud_storage` como si fuera sincronización transaccional.
- Exportar todos los Pomodoros como Mindful Minutes.
- Cambiar automáticamente el ícono por una racha.
- Enviar actualizaciones de Live Activity cada segundo desde Flutter.
- Marcar recordatorios ordinarios como `timeSensitive`.
- Prometer HealthKit, Spotlight o sync como parte del rebranding base.

## 4. Estado técnico verificado

### 4.1 Base actual

- Zentra declara `1.0.20+24` en `pubspec.yaml:4`.
- El SDK local contiene Flutter 3.38.3 y Dart 3.10.1.
- La persistencia canónica de hábitos y logs usa listas JSON completas en
  `SharedPreferences`.
- Pomodoro combina timer Dart, notificación programada y
  `flutter_foreground_task`.
- Existen Quick Actions para nuevo hábito, Pomodoro y progreso.
- Fin de enfoque y descanso ya usan `InterruptionLevel.timeSensitive`.
- El fallback Android exacto o inexacto ya consulta disponibilidad.
- `CADisableMinimumFrameDurationOnPhone` ya está activo.
- Runner ya declara el App Group `group.com.jesutorr.zentra`.
- Runner no declara HealthKit ni iCloud.
- No existe una política central de Reduced Motion.
- El sonido sólo se inicializa actualmente al construir la tarjeta de
  notificaciones en Ajustes.
- El historial Pomodoro conserva 30 días.

### 4.2 Live Activities

Existen:

- `lib/infrastructure/live_activity_service.dart`.
- `ios/Runner/ZentraActivityAttributes.swift`.
- Un target `ZentraWidgetExtension`.

Falta:

- Registrar el channel `com.jesutorr.zentra/live_activity` en iOS.
- Conectar `LiveActivityService` con `PomodoroProvider`.
- Crear `ActivityConfiguration`.
- Crear las vistas SwiftUI de Lock Screen y Dynamic Island.
- Declarar `NSSupportsLiveActivities`.
- Crear los archivos reales dentro de `ios/ZentraWidget/`.
- Dar App Group a la extensión.
- Embebido efectivo de `ZentraWidgetExtension.appex`.
- Tests de lifecycle y packaging.

La fase `Embed Foundation Extensions` no contiene archivos y el target declara
26.1 como deployment target. Ese valor debe tratarse como scaffolding
accidental, no como decisión de compatibilidad.

### 4.3 Widgets

El proyecto conoce un target de widget, pero no contiene su implementación en
disco y no lo embebe en Runner.

**Estado:** Zentra todavía no entrega un widget.

### 4.4 Siri y Shortcuts

Existe `SiriShortcutsService`, pero:

- No se inicializa desde `main.dart`.
- No tiene callers de donación.
- AppDelegate no registra `com.zentra.app/siri`.
- No hay `AppIntent`, `AppEntity` ni `AppShortcutsProvider`.

Las Quick Actions del ícono son una capacidad distinta.

**Estado:** Siri y Shortcuts no funcionan end to end.

### 4.5 Notificaciones

Actualmente existen:

- Inicialización sin pedir permisos en cold start.
- Solicitud de permiso en contexto desde Ajustes.
- Programación zoned.
- Fallback exacto o inexacto en Android.
- Routing principal por payload.
- `timeSensitive` para eventos de Pomodoro.

Falta:

- Categorías de notificación.
- Botones de acción.
- Callback background.
- Payload tipado y versionado.
- Command handler compartido.
- Presupuesto global para hábitos, Pomodoro y Notas.

### 4.6 Feedback sensorial

`triggerHaptic(HapticType.success)` dispara cuatro señales separadas. Otros
widgets también ejecutan haptics propios, por lo que completar una acción puede
apilar feedback.

`SoundService`:

- Usa `audioplayers`.
- Precarga `completion.mp3`.
- No configura todavía una sesión `ambient`.
- No se inicializa desde `main.dart`.
- Depende de que Ajustes haya construido su tarjeta para leer el setting.

## 5. Principios no negociables

Durante toda la evolución se debe proteger:

1. `Hoy` como centro emocional y funcional.
2. Los colores e iconos propios de cada categoría.
3. La separación clara entre pendientes y completados.
4. La respuesta táctil al completar un hábito.
5. Las rachas, XP, niveles, progreso, logros y celebraciones.
6. El tono optimista, sin castigos ni vergüenza.
7. La sencillez, el funcionamiento local y la ausencia de suscripciones.
8. La identidad personal mediante un avatar o talismán Zentra.
9. La acción principal con el menor número razonable de pasos.
10. La accesibilidad y responsividad como diseño, no como corrección posterior.
11. Una fuente canónica por dato.
12. Privacidad por defecto en Lock Screen, widgets y Spotlight.
13. Fallback funcional cuando una capacidad del sistema no existe.
14. Paridad o diferencia explícita entre iOS y Android.
15. Evidencia en dispositivo físico para capacidades de hardware.

Calma precisa aporta jerarquía, aire y coherencia. Zentra aporta personalidad,
color, movimiento, tacto y juego.

## 6. Sistema visual y sensorial

### 6.1 Paleta

La paleta base conservará:

- Blanco cálido.
- Tinta casi negra para contenido principal.
- Teal para acción, progreso y confianza.
- Durazno para recompensa y calidez.
- Mint para estados tranquilos.
- Colores de categoría refinados.

El color tendrá tres funciones:

1. Identificar categorías.
2. Comunicar estados.
3. Celebrar progreso.

No se convertirá toda la aplicación en teal. Agua, Movimiento, Sueño, Enfoque
y Varios conservarán identidad.

### 6.2 Tipografía

Se definirá un `TextTheme` completo para:

- Títulos de pantalla.
- Encabezados de sección.
- Números de progreso.
- Cuerpo.
- Etiquetas.
- Ayuda.
- Estados secundarios.

No se introducirán nuevos `fontSize` aislados después de la constitución visual.

### 6.3 Formas y superficies

Sólo existirán tres niveles:

1. Superficie base.
2. Tarjeta funcional.
3. Tarjeta especial o recompensa.

Se centralizarán:

- Espaciado.
- Radios.
- Bordes.
- Elevaciones.
- Sombras.
- Tamaños de icono.
- Alturas de controles.
- Estados pressed, focused, hovered, disabled y loading.

### 6.4 MotionPolicy

Se creará una política central que combine:

- `MediaQuery.disableAnimationsOf(context)`.
- Preferencia interna opcional.
- Estado de lifecycle y visibilidad.
- Nivel semántico de la animación.

Con Reduced Motion:

- Entradas pasan a cero o fade breve.
- No existen loops de respiración.
- No hay partículas.
- Confetti se sustituye por una confirmación estática.
- Una animación Rive usa frame estático.
- Live Activities evitan decoración animada.
- El estado final sigue siendo visible y comprensible.

Movimiento, sonido y haptics tendrán settings independientes.

### 6.5 Gramática háptica

Intenciones:

- `selection`: picker, tab o toggle.
- `success`: completar hábito o repaso.
- `warning`: acción reversible con atención.
- `error`: error real.

Reglas:

- Una acción produce como máximo una señal semántica.
- No se apilan haptics entre card, provider, diálogo y celebración.
- `selectionClick` se conserva para selección.
- Se crea un único patrón firma de éxito entre 180 y 320 ms.
- Core Haptics usa un engine nativo con reset y auto shutdown.
- Hardware sin Core Haptics recibe un fallback único.
- iPad no recibe un sustituto agresivo.
- El usuario puede desactivar haptics.

### 6.6 Audio premium

Se mantiene `audioplayers`.

Trabajo:

- Leer el setting durante el arranque.
- Configurar iOS como audio `ambient`.
- Configurar Android como sonification sin foco exclusivo.
- Crear y precachear el player sólo cuando aporte valor.
- Respetar Silent Mode.
- Probar con Apple Music, Spotify y podcasts.
- No bajar ni pausar audio ajeno.
- No reproducir si el setting está desactivado.

Se evaluará `audio_session` sólo si más plugins compiten por la sesión global.

### 6.7 Rive

No se agrega como dependencia general.

Spike opcional para el check firma:

- `idle`.
- `completing`.
- `completed`.
- `uncompleting`.

Gate:

- Asset local mantenible por Diseño.
- 60 y 120 fps en hardware real.
- Tamaño y cold start aceptables.
- Frame estático para Reduced Motion.
- Mejor resultado que Flutter nativo.

Si no gana claramente, se conserva una animación Flutter con tokens de
movimiento.

### 6.8 ProMotion

No se agregará otra tarea de configuración.

Se validará:

- Build `profile`.
- iPhone Pro físico.
- Frame pacing en scroll, check, confetti y Pomodoro.
- Jank de shaders.
- Rendimiento con Reduced Motion activado y desactivado.

El objetivo no es anunciar 120 Hz. Es evitar que Zentra rompa el ritmo del
sistema.

## 7. Identidad y navegación adaptable

### 7.1 Talismanes Zentra

El avatar actual da calidez, pero depende de emojis del sistema. Se propone una
colección propia:

- Naturaleza, constelaciones y objetos cotidianos.
- Estética retro-futurista cálida.
- Vectores propios.
- Color personalizable.
- Consistencia iOS, Android y web.
- Variantes desbloqueables.

La migración conservará el avatar anterior hasta que el usuario elija un
talismán.

### 7.2 Regla de layout

La navegación se decide por espacio disponible, nunca por el nombre del
dispositivo.

Clases:

- `compact`: NavigationBar o navegación superior compacta según el flujo.
- `medium`: NavigationRail colapsado.
- `expanded`: NavigationRail extendido.
- `large`: NavigationDrawer persistente cuando aporte valor.

La selección y el routing se comparten. No existen navegadores diferentes por
tamaño.

### 7.3 iPhone y ventanas compactas

- Encabezado personal.
- Herramientas esenciales visibles.
- Acciones contextuales cerca del contenido.
- Navegación inferior con Hoy, Hábitos, Notas, Enfoque y Progreso.
- Calendario visible en el encabezado, no enterrado en un menú.
- Perfil visible mediante avatar, talismán o acceso equivalente.
- Funciones primarias fuera de menús de tres puntos.

### 7.4 iPad y ventanas amplias

- Navegación persistente con Hoy, Hábitos, Notas, Enfoque, Progreso,
  Calendario y Perfil.
- List-detail en Notas, Hábitos, Calendario e Historial.
- Paneles de apoyo sólo cuando contienen información o acciones reales.
- Sin columnas de teléfono flotando en un lienzo vacío.

### 7.5 Slide Over y Split View

Una ventana de 320 dp en un iPad recibe la experiencia compacta. El tamaño del
hardware no implica un layout amplio.

### 7.6 Safe areas e insets

Cada pantalla debe diferenciar:

- `padding` para áreas parcialmente cubiertas.
- `viewPadding` para áreas seguras persistentes.
- `viewInsets` para teclado.
- Home indicator.
- Dynamic Island.
- Ventanas redimensionadas.

## 8. Fuente de verdad, comandos y persistencia

### 8.1 Decisión

Drift será la persistencia objetivo para los datos de producto.

`SharedPreferences` se conserva para preferencias escalares durante la
transición, no para listas crecientes de hábitos, logs, notas o sesiones.

### 8.2 Tablas mínimas

```text
users
habits
habit_schedules
habit_logs
notes
note_reminders
note_reviews
pomodoro_sessions
settings
system_commands
```

`sync_metadata` sólo se agrega después de elegir una estrategia de sync.

Entidades persistentes:

- UUID estable.
- `createdAt`.
- `updatedAt`.
- `deletedAt` cuando aplique.
- Versión de schema.

Restricciones:

```text
habit_logs: unique(userId, habitId, localDate)
system_commands: unique(operationId)
```

### 8.3 Repositorios

Contratos iniciales:

```text
HabitRepository
HabitLogRepository
NoteRepository
NoteReminderRepository
NoteReviewRepository
PomodoroSessionRepository
SettingsRepository
```

Providers y superficies del sistema no escriben SQL directamente.

### 8.4 Command handlers

Acciones reutilizables:

- `CompleteHabitCommand`.
- `UndoHabitCompletionCommand`.
- `StartFocusCommand`.
- `SnoozeReminderCommand`.
- `MarkNoteReviewedCommand`.

Cada comando define:

- `operationId`.
- Actor y origen.
- Entity ID estable.
- Fecha local y zona horaria cuando importan.
- Política de idempotencia.
- Resultado tipado.

Flutter, notificaciones y futuras integraciones invocan el mismo contrato.

### 8.5 Migración desde SharedPreferences

1. Leer datos legacy sin modificarlos.
2. Validar y convertir a un modelo intermedio.
3. Escribir Drift dentro de una transacción.
4. Comparar conteos, IDs y checksums.
5. Ejecutar queries equivalentes de calendario y progreso.
6. Marcar migración completa.
7. Conservar backup exportable.
8. No borrar llaves legacy durante al menos una release estable.

La migración debe ser:

- Repetible.
- Idempotente.
- Recuperable.
- Probada con datos válidos, parciales y dañados.

Si falla, Zentra abre los datos legacy y explica el estado sin perderlos.

### 8.6 App Group y proyecciones

El App Group publica snapshots de lectura:

```text
widget_snapshot_v1
  schemaVersion
  generatedAt
  userId
  completed
  total
  nextHabitId
  nextHabitTitle
  activeFocus
  privacyMode
```

Un snapshot no es fuente canónica.

### 8.7 Spike de mutación entre procesos

Antes de un widget interactivo:

- Identificar el proceso que ejecuta cada `AppIntent`.
- Probar estado locked y unlocked.
- Definir ubicación del archivo compartido.
- Validar Data Protection.
- Probar WAL, locking y escrituras simultáneas.
- Evitar dos implementaciones divergentes de reglas de negocio.
- Definir recuperación de comandos incompletos.
- Probar taps duplicados.

Sin este gate, los widgets sólo leen y abren Zentra.

### 8.8 Backup y sync

Orden:

1. Exportación e importación versionada.
2. Backup recuperable.
3. Contrato de sync y resolución de conflictos.
4. Elección de proveedor.

Rutas futuras:

- Backup de archivo.
- CloudKit privado.
- Backend neutral.

Como Android y web están en el roadmap, la recomendación estratégica para
sync real es un backend neutral. CloudKit sólo se elegiría si Producto decide
una etapa Apple-first deliberada.

Reglas mínimas:

- Logs append-only e idempotentes.
- Cambios usan versión y `updatedAt`.
- Eliminación crea tombstone.
- Una racha se deriva de logs.
- No se revive automáticamente una entidad eliminada.

## 9. Experiencias principales

### 9.1 Hoy y hábitos

#### Hoy

Se conserva:

- Talismán o avatar.
- Saludo.
- Progreso circular.
- Pendientes y completados.
- Categorías.
- Rachas.
- Creación rápida.
- Colores de categoría como identidad funcional.

Se mejora:

- Jerarquía del encabezado.
- Densidad de navegación.
- Lectura de meta diaria.
- Diferencia entre pendiente, completado y omitido.
- Accesibilidad del check.
- Intensidad de celebraciones.
- Composición para iPad.
- `Para repasar` sólo cuando existan notas relevantes.
- Estado de Pomodoro activo sin dominar la pantalla.
- Acceso visible a Calendario y Perfil.
- Una estructura de Hoy seleccionada entre los cinco modelos del UX Lab.

La implementación no mezcla los cinco modelos. El UX Lab sirve para elegir uno
como base y rescatar componentes compatibles de los demás sólo cuando mejoren
una tarea concreta.

#### Nuevo hábito

Orden:

1. Nombre e intención.
2. Categoría.
3. Frecuencia sencilla.
4. Recordatorio opcional.
5. Opciones avanzadas colapsadas.
6. Vista previa.
7. Guardar.

Un hábito básico debe crearse en menos de 20 segundos.

#### Mis hábitos

- Búsqueda.
- Filtros ligeros.
- Racha y frecuencia visibles.
- Activos y archivados.
- Edición rápida.
- Gestos secundarios.
- List-detail en pantallas amplias.

### 9.2 Notas activas

#### Promesa

> Captura una idea y decide cuándo volver a ella.

Notas no es un bloc genérico. Cada nota puede convertirse en intención mediante
recordatorio, repaso y enfoque.

#### Recorrido

1. Crear `Examen de biología`.
2. Escribir o pegar apuntes.
3. Programar `Mañana a las 7:00 p. m.`.
4. Recibir un recordatorio.
5. Abrir exactamente esa nota.
6. Iniciar un enfoque de 25 minutos.
7. Marcarla como repasada.
8. Programar el siguiente repaso.

```text
Capturar nota
      |
Programar recordatorio
      |
Notificación
      |
Abrir la nota
      |
Leer, editar o enfocar
      |
Registrar repaso y progreso
```

#### MVP

Cada nota:

- Título.
- Texto con formato ligero.
- Creación y edición.
- Etiquetas.
- Fijada o archivada.
- Acento discreto.
- Un recordatorio activo.
- Acción `Iniciar enfoque`.
- Historial básico de repasos.

Formato:

- Encabezados.
- Negritas.
- Listas.
- Checklist.
- Separadores.

#### Biblioteca

- Para repasar.
- Fijadas.
- Recientes.
- Archivadas.
- Búsqueda.
- Filtro por etiqueta.
- Filtro por recordatorio.
- List-detail en iPad.

#### Integración

- Hoy muestra `Para repasar`.
- Calendario distingue notas y hábitos.
- Pomodoro inicia desde una nota.
- Perfil y Progreso muestran repasos reales.
- La acción global crea una nota.

#### Modelo

```text
Note
- id
- userId
- title
- body
- formatVersion
- isPinned
- isArchived
- createdAt
- updatedAt
- deletedAt

NoteReminder
- id
- noteId
- scheduledAtUtc
- timezoneId
- localCalendarIntent
- status
- notificationId
- snoozeCount

NoteReview
- id
- noteId
- reviewedAt
- pomodoroSessionId
- durationMinutes
```

#### Recordatorios

Opciones:

- Más tarde hoy.
- Mañana.
- Este fin de semana.
- Fecha y hora.
- Sin recordatorio.

Acciones iniciales:

- Abrir nota.
- Iniciar enfoque abriendo Zentra.
- Recordar más tarde.

`Marcar repasada` desde background queda detrás del command handler y del gate
de persistencia.

#### Privacidad

- Notas locales por defecto.
- Sin analítica del texto.
- Preview configurable.
- Opción de texto genérico.
- Eliminación cancela recordatorios.
- Exportación e importación actualizadas.
- Cifrado y biometría evaluados después del MVP.

Notificación privada:

```text
Zentra
Tienes una nota pendiente para repasar.
```

#### Gamificación responsable

No se concede XP por crear notas.

Se premia:

- Enfoque asociado.
- Nota repasada.
- Rutina de estudio.
- Plan de repaso completado.

#### Evolución

Repetición espaciada básica:

```text
Repasar:
- Mañana
- En 3 días
- En 7 días
```

Sólo se mantiene programado el siguiente recordatorio.

#### Fuera del MVP

- Colaboración.
- OCR.
- PDFs y audio.
- IA.
- Flashcards automáticas.
- Múltiples recordatorios activos.
- Editor tipo Notion.
- Sync continuo.

### 9.3 Enfoque y Pomodoro

La pantalla tendrá:

- Dial de 5 a 60 minutos.
- Enfoque rápido.
- Ciclo completo.
- Secuencia de enfoques y descansos.
- Actividad opcional.
- Transición clara.
- Sesión asociable a hábito o nota.
- Historial significativo.
- Recompensas verificables.
- Burbujas de categoría como animación firma.

El temporizador debe sentirse como una habitación más silenciosa dentro de la
misma aplicación.

Las burbujas:

- Permanecen detrás del tiempo y nunca compiten con los controles.
- Usan los colores de Organización, Movimiento, Descanso, Estudio y Bienestar.
- Se mueven lentamente durante una sesión activa.
- No aparecen como confetti ni representan una recompensa aleatoria.
- Quedan estáticas o se sustituyen por un halo suave con Reduced Motion.
- Deben sostener 60 fps y 120 fps en hardware compatible sin jank.

#### Estado temporal

La precisión no depende de decrementar una variable:

- Se conserva `timerEndTime`.
- Al resumir se recalcula el tiempo.
- Pausa elimina el end time activo.
- Cancelar termina toda superficie.
- Completar registra una sola sesión.

### 9.4 Live Activity de Pomodoro

Es la principal superficie premium del sistema.

#### Compatibilidad

- ActivityKit se protege por disponibilidad.
- La app principal puede conservar un mínimo anterior.
- La extensión tendrá un deployment target deliberado compatible con
  ActivityKit.
- El valor 26.1 actual debe corregirse antes de archivar.

La decisión sobre seguir soportando iOS 13 se cierra en Fase 0.

#### Estado mínimo

- Session ID.
- Nombre o etiqueta privada.
- Tipo de etapa.
- `timerEndTime`.
- Corriendo o pausado.
- Progreso semántico.

Flutter actualiza al:

- Iniciar.
- Pausar.
- Reanudar.
- Cambiar de etapa.
- Terminar.

No se envían updates por segundo desde Dart. SwiftUI representa el countdown.

#### Superficies

- Lock Screen.
- Dynamic Island compacta.
- Dynamic Island expandida.
- Dynamic Island minimal.
- Dispositivo sin Dynamic Island.

#### Entrega A

- Tocar abre Pomodoro.
- Sin pause o cancel desde la isla.

#### Entrega B

- Pause o resume mediante `LiveActivityIntent`.
- Finalizar con confirmación.

Entrega B sólo avanza después de probar ownership del estado.

#### Lifecycle

- Foreground.
- Background.
- Flutter suspendido.
- App terminada.
- Pausa y resume.
- Cancelación.
- Fin con pantalla bloqueada.
- Cambio de hora.
- Cambio de zona.
- Reinicio.
- Live Activities desactivadas.

#### Privacidad

Setting:

- Mostrar nombre.
- Mostrar `Sesión de enfoque`.

#### Android

Se conserva la notificación foreground actual. No se intenta clonar Dynamic
Island.

### 9.5 Widgets

#### Entrega A, informativa

- Lock Screen circular con progreso.
- Home Screen pequeño con anillo.
- Mediano con siguiente hábito y progreso.
- Tap a Hoy o al hábito.
- Snapshot versionado.
- Timestamp de frescura.
- Privacy mode.

Un snapshot viejo debe mostrarse como desactualizado.

#### Entrega B, interactiva

- Completar.
- Deshacer.
- Abrir detalle.

Sólo después de:

- Drift.
- Command handlers.
- Spike de mutación entre procesos.
- App Intents.
- Pruebas de idempotencia.

#### Android

Se evaluará `home_widget` con Glance o RemoteViews. La UI sigue siendo nativa.

### 9.6 App Intents, Siri y Shortcuts

El scaffold legacy no se completa como arquitectura principal.

Intents:

1. `StartFocusIntent`.
2. `OpenTodayIntent`.
3. `ShowProgressIntent`.
4. `CompleteHabitIntent`.

Primer corte:

- Abrir Zentra en la ruta correcta.
- Iniciar enfoque con confirmación dentro de la app.

Segundo corte:

- Ejecución sin abrir sólo cuando la persistencia compartida sea segura.

`HabitEntity`:

- ID estable.
- Título.
- Categoría.
- Estado de hoy.
- Archivado.
- Privacidad.

Los hábitos eliminados no aparecen en sugerencias.

### 9.7 Acciones de notificación

Recordatorio de hábito:

- Abrir hábito.
- Posponer una hora.
- Marcar como hecho, sólo después del gate de comandos.

Fin de Pomodoro:

- Abrir Zentra.
- Iniciar descanso.

Nota:

- Abrir.
- Posponer.
- Iniciar enfoque.
- Marcar repasada, sólo después del gate de comandos.

No se ofrece eliminar desde una notificación.

### 9.8 Presupuesto de notificaciones

```text
Slots del sistema
|- Recordatorios diarios
|- Hábitos
|- Pomodoro
`- Notas próximas
```

Reglas:

- Límite iOS tratado como 64 pendientes.
- Ventana móvil con eventos más cercanos.
- Recalcular al abrir, editar, cambiar timezone o volver a foreground.
- IDs estables.
- Payload tipado y versionado.
- Cancelación al eliminar.
- `timeSensitive` sólo para un evento que ocurre ahora.
- Permiso solicitado en contexto.

Payload:

```json
{
  "v": 1,
  "type": "noteReminder",
  "entityId": "note-uuid",
  "action": "open"
}
```

Routing:

- Cold.
- Warm.
- Hot.
- Login.
- Ruta distinta.
- Entidad eliminada.

Android:

- `POST_NOTIFICATIONS` en contexto.
- Consultar alarmas exactas.
- Fallback inexacto.
- Explicar degradación.
- Sin `USE_EXACT_ALARM` hasta validar política.
- Reschedule después de reinicio.
- Documentar Doze y optimización de batería.

### 9.9 Gamificación coherente

#### XP

- Explicar origen.
- Mostrar siguiente nivel.
- Celebrar una sola vez.
- Evitar números decorativos.
- No permitir explotación con notas vacías.

#### Logros

- Implementar condiciones faltantes.
- Ocultar logros imposibles.
- Agrupar en Constancia, Bienestar, Enfoque, Aprendizaje y Exploración.
- Mostrar progreso.
- Diseñar insignias propias.
- Mostrar una colección que dé una razón real para volver al Perfil.

#### Retos y colección

- Retos semanales opcionales.
- Sin pérdida de XP por descansar.
- Sin loot boxes, monedas comprables ni recompensas aleatorias.
- Desbloqueables visuales elegidos por el usuario.
- Color por categoría como hilo entre acción y recompensa.

#### Intensidad

- Hábito normal: señal táctil y visual discreta.
- Día perfecto: celebración completa.
- Racha significativa: reconocimiento especial.
- Nivel o logro: pieza coleccionable.
- Repeticiones normales: sin interrupción.

### 9.10 Progreso, Perfil, Calendario e Historial

#### Progreso

- Tarjeta semanal volteable.
- Mejor legibilidad.
- Acciones sugeridas.
- Dos columnas en iPad.
- Hábitos, enfoque y repasos.

#### Perfil

- Avatar o talismán.
- Nivel.
- XP.
- Mejor racha.
- Días activos.
- Logros.
- Próxima recompensa.
- Colección de Aprendizaje.
- Retos opcionales.
- Distribución de actividad por categoría.
- Acceso secundario a preferencias y privacidad.

El Perfil es el hogar de identidad, colección y progreso personal. No debe
parecer una lista de Ajustes con un encabezado decorativo.

#### Calendario

- Intensidad diaria.
- Categorías.
- Hábitos y notas diferenciados.
- Recordatorios.
- List-detail en iPad.
- Acceso persistente desde el encabezado en móvil.
- Acceso persistente desde el rail en iPad.
- La fecha de Hoy abre el día correspondiente.

#### Historial

- Línea de tiempo.
- Filtros.
- Restauración cuando aplique.
- Resumen mensual.
- Hábitos, notas y enfoque como narrativa.

### 9.11 Acceso, onboarding, Ajustes y soporte

#### Acceso

- Continuar con Google como identidad futura multiplataforma.
- Usar Zentra sin cuenta como camino completo y de primera clase.
- Restaurar un respaldo antes de crear datos nuevos.
- Correo y contraseña como camino secundario y de migración.
- Enlazar después los datos locales con una cuenta sin perder historial.
- Ninguna función principal requiere cuenta.
- Balance real en iPad con explicación de privacidad y control de datos.

La cuenta resuelve identidad y continuidad. No define dónde vive la fuente
canónica ni sustituye la decisión de sync.

#### Onboarding

1. Comprender la promesa.
2. Elegir talismán.
3. Crear una intención.
4. Conocer la recompensa.
5. Crear un recordatorio opcional.
6. Pedir permisos en contexto.

#### Ajustes

- Permisos.
- Exactitud de recordatorios.
- Privacidad de Lock Screen.
- Reduced Motion interno.
- Haptics.
- Sonido.
- Live Activities.
- HealthKit si alguna vez se habilita.
- Backup.
- Apariencia.

## 10. Capacidades opcionales del ecosistema

### 10.1 HealthKit

No forma parte del núcleo aprobado.

Sólo se evaluará si:

- La actividad se marca explícitamente como meditación, respiración o
  mindfulness.
- El usuario activa la integración.
- La sesión termina normalmente.
- Se solicita únicamente permiso necesario.
- Negar permiso no afecta Pomodoro.
- Existe deduplicación por session ID.
- Privacy Policy y disclosures se actualizan.

Una sesión de estudio o programación nunca se exporta como mindful.

### 10.2 Spotlight

Preferentemente sobre App Entities:

- Hábitos activos.
- Hoy.
- Iniciar enfoque.
- Progreso.
- Notas sólo si el usuario lo autoriza.

No indexar:

- Hábitos archivados.
- Texto privado.
- Logs individuales.

### 10.3 Íconos alternativos

Orden:

1. Ícono principal default, dark y tinted.
2. Validación en Home, Spotlight, Settings y notificaciones.
3. Uno o dos alternates.

Un ícono puede desbloquearse por logro, pero el usuario siempre lo elige.

### 10.4 Sincronización

No se implementa durante el rebranding base.

Spike:

- Apple-first con CloudKit.
- Multiplataforma con backend.
- Backup automático sin sync.

La decisión debe incluir identidad, conflictos, seguridad, costos y soporte.

## 11. Fases de entrega

Las prioridades P0 a P3 indican urgencia. Las fases indican orden y gates.

### Fase 0. Baseline y decisiones

Entregables:

- Capturas actuales.
- Inventario de pantallas.
- ADN que no debe perderse.
- Snapshot técnico.
- Métricas.
- Compatibilidad mínima de iOS.
- Política de privacidad para Lock Screen.
- Estrategia local-first.
- Definition of Done.

**Gate:** Producto y Diseño aceptan el contrato.

**Estado al iniciar 3.2:** cumplido para la dirección visual y el modelo Guía
diaria. Las decisiones de plataforma que aparecen en la sección 17 permanecen
abiertas hasta la fase que las necesite.

### Fase 1. Constitución visual, calma y convivencia

Entregables:

- Paleta y TextTheme.
- Espaciado, radios y componentes.
- Light y dark.
- MotionPolicy.
- Auditoría de haptics.
- Patrón firma Core Haptics con fallback.
- SoundService desde cold start.
- Sesión `ambient`.
- Perfil de ProMotion.
- Spike Rive opcional.

**Resultado:** Zentra deja de interrumpir y obtiene una firma sensorial.

**Gate:** catálogo UX Lab y pruebas físicas aprobados.

**Avance al 25 de julio de 2026:** la constitución visual, los temas light y
dark, las ThemeExtensions, el MotionPolicy mínimo y la pantalla Inicio ya están
implementados. La auditoría háptica, Core Haptics, audio `ambient`, cold start,
perfil de ProMotion y el spike Rive siguen pendientes. Por ello la fase permanece
abierta aunque el gate de Inicio esté cerrado.

### Fase 2. Identidad, shell y responsividad

- Avatar y talismanes.
- Navegación adaptable.
- Calendario persistente.
- Perfil persistente.
- iPhone.
- iPad.
- Slide Over.
- Split View.
- Safe areas.
- Acción global.
- Routing compartido.

**Gate:** todas las áreas principales están a una interacción desde Hoy.

### Fase 3. Fuente de verdad

- Drift.
- Schema.
- Repositorios.
- Command handlers.
- Migración.
- Exportación versionada.
- Presupuesto de notificaciones.
- Payloads tipados.
- App Group snapshot.

**Gate:** equivalencia de datos, fallback y pruebas de migración.

### Fase 4. Experiencia diaria

- Hoy.
- Nuevo hábito.
- Mis hábitos.
- Color por categoría.
- Check firma.
- Estados vacíos.
- Accesibilidad.
- Composición iPad.

**Gate:** crear, completar, deshacer, editar, archivar y eliminar es estable.

### Fase 5. Notas activas

- Biblioteca.
- Editor.
- Búsqueda.
- Etiquetas.
- Recordatorio.
- Repaso.
- Integración con Hoy, Calendario y Pomodoro.
- Privacidad.

**Gate:** una nota se crea, encuentra, recuerda y convierte en enfoque.

### Fase 6. Pomodoro y presencia útil

- Pantalla Calma precisa.
- Dial.
- Burbujas de categoría y fallback Reduced Motion.
- Ciclos.
- Persistencia de sesiones.
- Completar target WidgetKit.
- Live Activity.
- Dynamic Island.
- Fallback Android.
- Packaging y entitlements.

**Gate:** lifecycle completo y timer consistente.

### Fase 7. Acciones del sistema

Entrega A:

- Widget informativo.
- App Intents que abren rutas.
- Acciones de notificación de navegación.

Entrega B:

- Spike de mutación entre procesos.
- Widget interactivo.
- Acciones background.
- CompleteHabitIntent.

**Gate:** idempotencia y privacidad con dispositivo locked y unlocked.

### Fase 8. Gamificación e información

- XP.
- Niveles.
- Logros.
- Retos opcionales.
- Colección.
- Recompensas visuales elegibles.
- Progreso.
- Perfil.
- Calendario.
- Historial.

**Gate:** cada número conduce a una decisión o recompensa real.

### Fase 9. Acceso y superficies secundarias

- Google como identidad multiplataforma.
- Modo 100% local.
- Enlace posterior de datos locales.
- Login por correo como camino secundario.
- Onboarding.
- Ajustes.
- Soporte.
- About.
- Importación.
- Recuperación.

**Gate:** permisos y degradación son comprensibles.

### Fase 10. Ecosistema opcional

- Spike sync.
- HealthKit selectivo.
- Spotlight.
- Íconos alternativos.

Cada capacidad requiere aprobación independiente. No bloquea el rebranding.

### Fase 11. Estabilización y release

- Accessibility audit.
- Screen Reviewer.
- Matriz responsiva.
- Dark.
- Texto aumentado.
- Notificaciones.
- Migración.
- Backup.
- Performance.
- Archive con extensión.
- Dispositivo físico.
- Suite verde.
- Analyzer limpio.

No se genera una build de distribución sin aprobación de Uri.

## 12. Paquetes de trabajo

Las tallas son comparativas.

| ID | Paquete | Prioridad | Talla | Dependencias |
|---|---|---:|---:|---|
| ZR-UX-01 | Constitución visual | P0 | M | Fase 0 |
| ZR-SYS-01 | MotionPolicy | P0 | S | Ninguna |
| ZR-SYS-02 | Auditoría y gramática háptica | P0 | M | ZR-SYS-01 |
| ZR-SYS-03 | Audio cold start y ambient | P0 | S | Ninguna |
| ZR-SYS-04 | Perfil ProMotion | Validación | S | Build profile |
| ZR-UX-02 | Navegación y layouts adaptables | P0 | L | ZR-UX-01 |
| ZR-AUTH-01 | Acceso local-first, Google y restauración | P1 | L | Decisión de identidad |
| ZR-GAME-01 | Perfil, colección y color de categoría | P1 | L | ZR-UX-01 |
| ZR-DATA-01 | Drift y migración | P1 | XL | Schema aprobado |
| ZR-DATA-02 | Command handlers | P1 | M | ZR-DATA-01 |
| ZR-NOTE-01 | Notas activas MVP | P1 | XL | ZR-DATA-01 |
| ZR-FOCUS-01 | Pomodoro Calma precisa | P1 | L | ZR-UX-01 |
| ZR-SYS-05 | Live Activity Pomodoro | P1 | L | ZR-SYS-01, ZR-FOCUS-01 |
| ZR-SYS-06 | Acciones de notificación | P1/P2 | M | ZR-DATA-02 para mutar |
| ZR-SYS-07 | Widget informativo | P2 | M | WidgetKit base |
| ZR-SYS-08 | App Intents y HabitEntity | P2 | L | ZR-DATA-02 |
| ZR-SYS-09 | Spike de mutación nativa | P2 | M | ZR-DATA-01, ZR-SYS-08 |
| ZR-SYS-10 | Widget interactivo | P2 | L | ZR-SYS-09 |
| ZR-SYS-11 | Spike Rive | P2 | S | ZR-SYS-01 |
| ZR-SYS-12 | Spike de sincronización | P3 | M | ZR-DATA-01 |
| ZR-SYS-13 | HealthKit selectivo | P3 | M | Decisión de Producto |
| ZR-SYS-14 | Spotlight e íconos | P3 | M | ZR-SYS-08 |

### Definition of Ready

- Problema y resultado definidos.
- Versión mínima de OS definida.
- Privacidad definida.
- Fallback definido.
- Diseño de estados aprobado.
- Error y recuperación definidos.
- Dispositivo físico disponible cuando aplica.

### Definition of Done

- Implementación local.
- Migraciones probadas.
- Tests proporcionales al riesgo.
- Evidencia física.
- Capabilities y entitlements documentados.
- Privacy Policy actualizada cuando aplica.
- Sin regresión Android.
- Screen Reviewer.

## 13. Método pantalla por pantalla

### Mantra operativo

> **Observar lo que existe. Rescatar lo que funciona. Transformar sólo lo que
> mejora la experiencia.**

El rebranding no parte de la idea de que la aplicación actual está equivocada.
Cada pantalla existente contiene decisiones, flujos y rasgos de personalidad que
pueden seguir siendo valiosos. Antes de diseñar o escribir código se debe separar
con evidencia:

- Lo que funciona y debe conservarse.
- Lo que funciona pero necesita mejor jerarquía o presentación.
- Lo que genera fricción y debe cambiar.
- Lo que falta para cumplir la promesa nueva.

No se elimina una interacción, animación, color, función o detalle propio de
Zentra sólo porque el mockup nuevo sea más minimalista. Si una pieza actual
aporta claridad, juego, calidez o reconocimiento, se rescata y se integra en
Calma precisa.

Cada pantalla:

1. Ejecutar la pantalla actual y recorrer sus flujos como usuario.
2. Capturar su estado actual en iPhone e iPad.
3. Revisar el código que controla comportamiento, layout y estado.
4. Clasificar cada elemento como conservar, mejorar, retirar o agregar.
5. Comparar esa evidencia con la propuesta aprobada del UX Lab.
6. Preparar la propuesta final explicando qué se rescata y por qué.
7. Validar iPhone, iPad, light, dark y texto aumentado en el diseño.
8. Obtener la aprobación de Uri.
9. Implementar sin perder comportamiento rescatable.
10. Ejecutar analyze y tests.
11. Agregar golden tests donde aporten valor.
12. Ejecutar el Screen Reviewer.
13. Presentar la comparativa real antes y después.

No se avanza de pantalla sin aprobar la anterior.

Las fundaciones transversales como MotionPolicy o Drift sí se validan como
paquetes propios antes de que varias pantallas dependan de ellas.

### 13.1 Orden de implementación aprobado

1. Base visual compartida e Inicio.
2. Acceso local-first.
3. Bienvenida y permisos en contexto.
4. Shell adaptable y Hoy.
5. Nuevo hábito y Mis hábitos.
6. Biblioteca y editor de Notas.
7. Recordatorio de nota y navegación desde notificación.
8. Configuración de Enfoque y sesión en curso.
9. Progreso, Calendario e Historial.
10. Perfil gamificado, Ajustes y Ayuda.
11. Live Activity, Dynamic Island, widgets y acciones del sistema cuando sus
    dependencias de datos estén listas.

La base visual puede cambiar tokens compartidos, pero cada pantalla conserva un
gate visual independiente. Un cambio global no equivale a aprobar de golpe toda
la aplicación.

## 14. Matriz de validación

### 14.1 Anchos

- 320 dp.
- 360 dp.
- 393 dp.
- 600 dp.
- 744 dp.
- 840 dp.
- 1024 dp.
- 1280 dp para web futura.
- 1920 dp para web futura.

### 14.2 Texto

- 100%.
- 200%.
- 320% como estrés en flujos críticos.

### 14.3 Temas

- Light.
- Dark.
- Increased Contrast cuando aplique.

### 14.4 Estados

- Vacío.
- Con datos.
- Contenido largo.
- Error.
- Offline.
- Permiso denegado.
- Teclado abierto.
- Recordatorio programado.
- Recordatorio inexacto.
- Entidad eliminada.
- Snapshot viejo.
- Dispositivo locked.
- Reduced Motion.
- Haptics desactivados.
- Sonido desactivado.
- Modo local sin cuenta.
- Respaldo válido, inválido y de versión anterior.
- Cuenta enlazada después de uso local.
- Categorías con contenido largo.

### 14.5 Dispositivos físicos

- iPhone compacto.
- iPhone grande.
- iPhone Pro con 120 Hz.
- iPhone con Dynamic Island.
- iPad sin Core Haptics.
- Android compacto.

### 14.6 Suites

- Unit tests de commands e idempotencia.
- Migration tests.
- Notification planner con fake clock.
- DST y múltiples timezones.
- Routing cold, warm y hot.
- Lifecycle Pomodoro.
- Live Activity lifecycle.
- Reduced Motion.
- Privacy mode.
- Widget snapshot.
- Accessibility.
- Adaptive navigation.

## 15. Definición de terminado

Cada pantalla:

- Funciona desde 320 dp hasta iPad completo.
- Respeta SafeArea, teclado y home indicator.
- Tiene acción primaria inequívoca.
- Es operable con lector de pantalla.
- Usa objetivos táctiles mínimos de 44 a 48 dp.
- Funciona en light y dark.
- No presenta overflow.
- Mantiene el mismo modelo mental.
- Respeta Reduced Motion.
- Conserva el color de categoría cuando comunica identidad o progreso.
- Mantiene Calendario y Perfil descubribles según su size class.
- Pasa analyzer, tests y Screen Reviewer.

Cada recordatorio:

- Usa ID estable.
- Se cancela al editar o eliminar.
- Usa timezone.
- Maneja DST.
- Abre la entidad correcta.
- Tiene fallback.
- Respeta privacidad.
- Comparte presupuesto.

Cada superficie de sistema:

- Reduce una apertura o resume una acción.
- No crea otra fuente de verdad.
- Tiene timestamp de frescura.
- Tiene privacy mode.
- Funciona con la capacidad desactivada.
- Declara fallback Android.
- Tiene prueba física.

## 16. Cambios arquitectónicos previstos

### 16.1 Tema

Tokens, `ColorScheme`, `TextTheme`, ThemeExtensions y componentes.

### 16.2 Layout

Size classes y composiciones adaptive compartidas.

### 16.3 Identidad

Talismanes con migración desde emoji.

### 16.4 Datos

Drift, repositorios, schema y migraciones.

### 16.5 Comandos

Acciones idempotentes reutilizables.

### 16.6 Notas

Dominio Note, NoteReminder y NoteReview.

### 16.7 Pomodoro

PomodoroSession persistente y estado temporal separado.

### 16.8 Notificaciones

Planner, presupuesto, payloads y acciones.

### 16.9 Superficies nativas

WidgetKit, ActivityKit, App Intents y App Group.

### 16.10 Gamificación

Motor de logros con condiciones verificables.

## 17. Decisiones que deben cerrarse

1. ¿Zentra conserva iOS 13 como mínimo?
2. ¿Cuál es el mínimo de la extensión ActivityKit?
3. ¿Los títulos aparecen en Lock Screen por default?
4. ¿Qué acciones pueden ocurrir con el teléfono bloqueado?
5. ¿Diseño mantendrá un asset Rive?
6. ¿El ícono alternativo es estético o recompensa?
7. ¿Qué categorías califican como mindfulness?
8. ¿Sync será Apple-first o multiplataforma?
9. ¿El widget mutará de inmediato o abrirá Zentra en su primera versión?
10. ¿Qué duración de historial se conserva después de Drift?
11. ¿Google será la única identidad social en la primera entrega
    multiplataforma?
12. ¿Qué contrato enlaza datos locales con una cuenta sin duplicar entidades?

### 17.1 Decisiones cerradas

- **Modelo base:** Guía diaria.
- **Aportes integrados:** juego y colección de Progreso vivo, calendario de
  Agenda viva, explicabilidad de Compañera Zentra y composición amplia de
  Estudio modular.
- **Estrategia visual:** una sola interfaz coherente. No se alternan modelos en
  producción.
- **Corte de versión:** `2.0.0+25`, porque cambia la identidad, la navegación y
  la promesa funcional. El número de build continúa después de `1.0.20+24`.

## 18. Primer entregable completado

El primer entregable de diseño quedó implementado en
[`design/zentra-ux-lab`](../design/zentra-ux-lab/):

1. Comparativa de Guía diaria, Agenda viva, Progreso vivo, Compañera Zentra y
   Estudio modular.
2. Acceso local-first con Google, respaldo y correo secundario.
3. Constitución visual.
4. Color por categoría.
5. Motion states y Reduced Motion.
6. Gramática háptica representada.
7. Avatar, talismanes y colección.
8. Hoy.
9. Nuevo hábito.
10. Perfil gamificado.
11. Calendario descubrible.
12. Biblioteca de Notas.
13. Editor.
14. Recordatorio.
15. Nota con enfoque.
16. Pomodoro con burbujas.
17. Live Activity en Lock Screen.
18. Dynamic Island.
19. Widget informativo.
20. Variantes iPhone e iPad.

Las superficies nativas se muestran como mockup primero. No se modifica
producción hasta aprobar su valor, privacidad y fallback.

### 18.1 Primer corte real completado

El primer corte real de `2.0.0+25` quedó implementado:

1. Tokens de Calma precisa.
2. Light y dark coherentes.
3. MotionPolicy mínimo.
4. Inicio rediseñado con un asset de marca transparente separado del ícono de
   App Store.
5. Composición adaptable para iPhone e iPad.
6. Texto a 100%, 200% y estrés a 320%.
7. Analyze, pruebas de widgets y evidencia del Screen Reviewer.

Evidencia:

- `flutter analyze`: sin issues.
- `flutter test`: 279 pruebas aprobadas.
- Screen Reviewer: 19 capturas por dispositivo y recorrido PASS en iPhone 16e,
  iPhone 17 Pro Max, iPad mini e iPad Pro.
- Revisión visual manual de Inicio en los cuatro tamaños.
- Reduced Motion probado con indicador estático.
- El ícono original permanece sin cambios para App Store; Inicio usa
  `assets/images/zentra_logo_mark.png`.

El siguiente gate es **Acceso local-first**. Debe conservar uso 100% local,
restauración de respaldo y correo, y dejar Google como integración futura sin
simular que ya funciona. No se genera una build de distribución hasta aprobar
esta pantalla.

### 18.2 Clasificación aprobable de Acceso

La pantalla actual fue revisada en código y en las capturas del Screen Reviewer
para iPhone e iPad. Esta clasificación precede al rediseño y evita reemplazar
comportamiento valioso por una maqueta visual.

#### Conservar

- `SafeArea`, scroll vertical y composición por espacio disponible.
- Validaciones, estado de carga y protección contra doble envío.
- Restauración de respaldo como ruta completa de entrada.
- Sesión local persistente y recarga de datos después de importar.
- Compatibilidad con los usuarios locales ya creados.
- Soporte interno para más de un usuario, sin convertirlo en la decisión
  principal del primer arranque.
- `AuthWrapper` como propietario de la transición hacia onboarding y Hoy.
- Correo y contraseña como ruta secundaria para datos existentes y migración.

#### Mejorar

- Explicar con honestidad que la identidad actual es local y no una cuenta en
  línea.
- Convertir `Usar Zentra en este dispositivo` en el camino principal y completo.
- Reducir el peso visual del formulario y eliminar el gran vacío superior.
- Dar a iPad una composición intencional. Un iPad Pro de 11 pulgadas en vertical
  tiene 834 dp y hoy queda apenas debajo del breakpoint expandido de 840 dp, por
  lo que recibe una columna angosta rodeada de espacio sin función.
- Reemplazar el saludo con emoji por marca, color de categorías y calidez propia
  de Zentra.
- Enrutar movimiento y hápticos por `MotionPolicy` y la futura gramática
  sensorial, en vez de animaciones y llamadas hápticas directas.
- Presentar una vista previa y confirmación antes de restaurar un respaldo.
- Mantener foco, semántica, teclado, texto aumentado y errores comprensibles en
  todos los caminos.

#### Retirar

- La obligación de proporcionar correo y contraseña para usar datos que sólo
  viven en el dispositivo.
- La apariencia de autenticación en la nube cuando no existe autenticación
  remota.
- El emoji de saludo y el avatar emoji como centro de la pantalla de acceso.
- La copia genérica `comenzar tu viaje`.
- Escalas con rebote, shake y hápticos directos que no respetan la política
  sensorial.
- El patrón de formulario telefónico centrado en una gran superficie de iPad.
- Cualquier botón activo de Google antes de que la integración funcione.

#### Agregar

- Tres rutas inequívocas: continuar en este dispositivo, restaurar respaldo y
  entrar como usuario local existente.
- Explicación breve de propiedad de datos y de que una cuenta puede vincularse
  después sin perder historial.
- Modelo de identidad preparado para vincular Google más adelante conservando
  el UUID local.
- Estados diseñados para instalación nueva, usuario local existente,
  restauración, error de archivo y modo sin conexión.
- Pruebas de interacción de cada ruta, no sólo capturas sin excepciones.
- Composición de iPad que use la segunda zona para explicar privacidad,
  continuidad y respaldo, sin estirar el formulario.

#### Cambio arquitectónico requerido

`LocalUser` exige actualmente correo y `passwordHash`. Para que el modo sin
cuenta sea real, la identidad local debe aceptar credenciales opcionales o
separarse del proveedor de identidad. El UUID local seguirá siendo la identidad
estable de los datos. Google o correo se vincularán después como credenciales,
no reemplazarán al propietario local ni crearán otro historial.

La maqueta vigente de UX Lab también debe corregirse antes de implementarse:
`Continuar con Google` aparece como acción disponible y promete continuidad
multidispositivo. Mientras no exista integración real, se elimina de las
acciones ejecutables. Puede explicarse como capacidad futura sin simular éxito.

### 18.3 Propuesta final de Acceso en UX Lab

El laboratorio quedó actualizado antes de tocar Flutter:

1. `Usar en este dispositivo` es la acción principal y abre Bienvenida.
2. `Restaurar un respaldo` tiene un estado propio con selección, vista previa
   prometida y confirmación antes de reemplazar datos.
3. `Ya tengo un usuario en este dispositivo` abre el formulario local heredado.
4. Google aparece únicamente como capacidad futura no interactiva.
5. La propiedad de los datos se explica sin presentar una cuenta en la nube.
6. iPhone usa una jerarquía compacta sin el vacío superior actual.
7. iPad divide el espacio entre promesa, privacidad y acciones, en vez de
   centrar un formulario de teléfono.
8. Marca, iconografía y color de categorías reemplazan los emojis protagonistas.

Los estados `choices`, `existing` y `backup` se pueden recorrer mediante
interacción o por parámetros del laboratorio. JavaScript pasó validación de
sintaxis y las composiciones de iPhone e iPad se inspeccionaron mediante
capturas headless.

### 18.4 Implementación real de Acceso completada

La propuesta aprobada dejó de ser sólo una maqueta y ya está implementada en
Flutter:

1. Una instalación nueva puede crear una identidad local estable sin correo ni
   contraseña mediante `Usar en este dispositivo`.
2. El UUID local sigue siendo el propietario de hábitos, progreso y ajustes.
3. Si ya existía una identidad local sin credenciales, se reutiliza en vez de
   fragmentar el historial con otro usuario.
4. Los usuarios heredados con correo y contraseña mantienen su ruta de acceso y
   compatibilidad con el hash existente.
5. `LocalUser` ahora distingue identidad de dispositivo y credenciales
   vinculadas mediante campos opcionales y `hasCredentials`.
6. Restaurar un respaldo separa selección, validación, vista previa,
   confirmación y escritura. Elegir un archivo ya no modifica datos por sí
   solo.
7. Google se presenta como integración futura no interactiva y no promete
   sincronización que aún no existe.
8. La pantalla usa la marca transparente real, paleta semántica, Material
   Icons, `SafeArea`, scroll y `MotionPolicy`.
9. A partir de 700 dp y cuando la altura y el texto lo permiten, Acceso usa dos
   paneles. Esto corrige específicamente el iPad Pro de 11 pulgadas en vertical
   a 834 dp sin depender de identificar el dispositivo.
10. Con texto grande la composición vuelve a una sola columna y todas las
    etiquetas pueden crecer verticalmente.

Gate automatizado de implementación:

- `flutter analyze`: sin issues.
- `flutter test`: 284 pruebas aprobadas.
- Pruebas nuevas para identidad local sin credenciales, reutilización del
  propietario, acceso heredado y lectura de ambos formatos JSON.
- Pruebas de widget para caminos local-first y respaldo.
- Prueba específica del layout de Acceso a 834 x 1194 dp.
- Matriz existente aprobada a texto 320%, 320 dp de ancho, tamaños de iPhone,
  Split View e iPad.
- Durante el gate se encontró y corrigió un overflow real de la etiqueta futura
  de Google con texto al 320%.

Gate visual final ejecutado:

- El artefacto iOS de debug faltante se recuperó mediante el workflow oficial
  `flutter precache --ios --force`; después se verificó una build limpia para
  simulador.
- El Screen Reviewer completó el recorrido de 19 capturas en iPhone 16e,
  iPhone 17 Pro Max, iPad mini e iPad Pro, sin excepciones.
- La revisión humana detectó que el logo blanco perdía contraste sobre la
  superficie clara y que el detalle de respaldo heredaba una posición de
  scroll confusa en el iPhone compacto.
- El logo transparente ahora conserva su asset y aparece sobre una base de
  marca con contraste.
- En teléfonos, las rutas secundarias de acceso ocultan la introducción larga y
  comienzan en un panel limpio; al volver a las opciones el scroll regresa al
  inicio. En iPad se conserva la composición simultánea de marca y acciones.
- La repetición dirigida en iPhone 16e confirmó visualmente ambos estados.

Acceso queda **técnicamente aprobable**. El paso a Bienvenida continúa detenido
hasta el visto bueno explícito de Uri.

## 19. Protocolo multiagente pantalla por pantalla

El rebranding se ejecutará como una caravana de agentes con gates humanos. El
objetivo no es producir más cambios al mismo tiempo, sino separar investigación,
decisión, implementación y validación para que cada etapa tenga un dueño claro
y Uri pueda revisar antes de comprometer la siguiente.

### 19.1 Regla de concurrencia

- Joy conserva la coordinación, integra los hallazgos y es la única responsable
  de declarar que un gate está cerrado.
- Los agentes de auditoría y arquitectura trabajan en modo `READ ONLY`. Pueden
  avanzar en paralelo porque no modifican archivos.
- Sólo existe un agente escritor sobre la app o UX Lab en cada momento.
- El agente QA no corrige mientras revisa. Entrega evidencia y devuelve el
  trabajo al escritor si encuentra una regresión.
- Ningún agente inicia la siguiente pantalla sin el visto bueno explícito de
  Uri.
- No se hacen commits, pushes ni mutaciones remotas. Los cambios quedan locales
  y sin stage para revisión.

### 19.2 Equipo por pantalla

#### Agente A. Auditor de producto y código

Responsabilidad:

- Recorrer la pantalla real como usuario.
- Trazar navegación, estado, datos, errores y variantes.
- Citar archivos y líneas relevantes.
- Clasificar cada elemento como `conservar`, `mejorar`, `retirar` o `agregar`.
- Identificar comportamiento valioso que no debe perderse con el rebranding.

Entrega:

- Informe de rescate.
- Mapa de estados.
- Riesgos funcionales y de migración.
- Lista de pruebas que protegen el comportamiento existente.

#### Agente B. Arquitecta UX adaptable

Responsabilidad:

- Contrastar la pantalla real con UX Lab y este plan maestro.
- Proponer la jerarquía final para iPhone compacto, iPhone grande, Split View e
  iPad.
- Incluir texto a 200%, teclado, dark mode, Reduced Motion y estados vacíos,
  cargando y error.
- Definir criterios visuales y de interacción verificables.

Entrega:

- Especificación de la pantalla.
- Rescates visuales y funcionales.
- Contrato responsive.
- Criterios de aceptación para implementación y QA.

Los agentes A y B pueden trabajar en paralelo. Joy elimina contradicciones y
presenta una sola recomendación a Uri.

#### Agente C. Implementadora

Responsabilidad:

- Actualizar primero UX Lab cuando la decisión visual todavía necesite
  comparación.
- Implementar Flutter sólo después del gate de diseño.
- Mantener una única fuente de verdad y evitar rutas duplicadas por tamaño.
- Agregar o actualizar pruebas proporcionales al riesgo.
- Actualizar este plan con lo que realmente quedó construido.

Entrega:

- Diff local enfocado en una pantalla o habilitador.
- `flutter analyze` limpio.
- Pruebas unitarias y de widget verdes.
- Nota de cualquier desviación justificada respecto al mockup.

#### Agente D. QA adversarial

Responsabilidad:

- Intentar romper la pantalla en los tamaños y estados definidos.
- Ejecutar el recorrido real del Screen Reviewer.
- Revisar screenshots manualmente. Un `PASS` automatizado sólo demuestra que el
  flujo terminó sin excepciones, no que la composición sea buena.
- Verificar rutas, semántica, texto aumentado, dark mode, Reduced Motion y
  persistencia.

Entrega:

- Evidencia antes y después.
- Hallazgos con severidad y reproducción.
- Veredicto `APROBABLE` o `DEVOLVER`.

### 19.3 Gates y pausas de revisión

Cada pantalla atraviesa cuatro gates:

1. **Gate A. Rescate.** Joy entrega a Uri la lectura conjunta de los agentes A y
   B. Uri decide si la dirección conserva suficiente identidad y funcionalidad.
2. **Gate B. Diseño.** Si hace falta UX Lab, se muestra la propuesta navegable y
   sus estados. Nada entra a Flutter hasta recibir aprobación.
3. **Gate C. Implementación.** Se entrega el diff, las decisiones realizadas y
   los checks automatizados. La siguiente pantalla todavía no comienza.
4. **Gate D. Pantalla aprobada.** QA entrega screenshots y recorrido. Joy pide a
   Uri permiso explícito para continuar.

Si Uri tarda en revisar, el proceso se detiene en ese gate. Los agentes no
rellenan el tiempo cambiando otra pantalla, porque eso acumularía decisiones no
aprobadas y haría más costoso corregir la dirección.

### 19.4 Orden de ejecución y dependencias

El orden mezcla tráfico de usuario, riesgo y dependencias de datos:

0. Cerrar QA visual de Acceso.
1. Bienvenida y onboarding.
2. Shell adaptable y navegación.
3. Hoy.
4. Nuevo y editar hábito.
5. Lista y detalle de hábitos.
6. Gate de datos: Drift, migración y command handlers idempotentes.
7. Biblioteca de Notas.
8. Editor y detalle de Nota.
9. Recordatorios de Nota y deep links.
10. Configuración de Enfoque.
11. Sesión de Enfoque activa.
12. Progreso.
13. Calendario.
14. Historial.
15. Perfil gamificado.
16. Ajustes y preferencias sensoriales.
17. Ayuda, Acerca de y soporte.
18. Superficies nativas, cada una con gate propio: Live Activity, widget
    informativo, acciones de notificación, App Intents y widget interactivo.
19. Gate integral de release.

Drift se coloca después de Hábitos y antes de Notas. Esto permite aterrizar el
nuevo camino diario sobre los contratos existentes y evita construir Notas,
widgets o acciones de sistema sobre escrituras JSON no transaccionales.

### 19.5 Quality gate común

El agente QA debe ejecutar, según corresponda:

```bash
./flutter/bin/flutter analyze
./flutter/bin/flutter test
./flutter/bin/dart run tool/run_screen_reviewer.dart
```

La matriz visual mínima incluye:

- iPhone compacto.
- iPhone grande.
- iPad mini.
- iPad Pro.
- Anchos críticos de 320, 360, 393, 600, 744, 840 y 1024 dp.
- Texto a 100% y 200%; pruebas de estrés a 320% en componentes críticos.
- Light y dark.
- Reduced Motion activo e inactivo.
- Teclado visible en pantallas con formularios.

Cada gate conserva un reporte y capturas bajo `build/screen-review/`. La
evidencia generada puede recrearse y no se considera fuente canónica; las
decisiones y resultados sí se registran en este plan.

### 19.6 Estado de la caravana

- **Acceso:** implementación y QA completados. Build iOS limpia, analyzer sin
  issues, suite adaptativa verde, recorrido completo 19/19 en cuatro
  simuladores y verificación visual dirigida del iPhone compacto. Gate D
  técnicamente aprobable y pendiente sólo del visto bueno de Uri.
- **Onboarding:** siguiente pantalla. Los agentes A y B no comienzan hasta que
  Acceso tenga evidencia visual aprobable y Uri autorice continuar.

## 20. Referencias

### 20.1 Evidencia local

- [Versión y dependencias](../pubspec.yaml)
- [Persistencia actual](../lib/infrastructure/local_storage_repository.dart)
- [Notificaciones](../lib/infrastructure/notification_service.dart)
- [Planner](../lib/infrastructure/notification_schedule_planner.dart)
- [Feedback sensorial](../lib/presentation/utils/feedback_utils.dart)
- [Tokens de Calma precisa](../lib/presentation/design_tokens.dart)
- [MotionPolicy](../lib/presentation/motion_policy.dart)
- [Tema de Calma precisa](../lib/presentation/theme.dart)
- [Inicio real](../lib/presentation/splash_screen.dart)
- [Pomodoro](../lib/application/pomodoro_provider.dart)
- [Live Activity Dart](../lib/infrastructure/live_activity_service.dart)
- [ActivityAttributes](../ios/Runner/ZentraActivityAttributes.swift)
- [AppDelegate](../ios/Runner/AppDelegate.swift)
- [Siri scaffold](../lib/infrastructure/siri_shortcuts_service.dart)
- [Info.plist](../ios/Runner/Info.plist)
- [Entitlements](../ios/Runner/Runner.entitlements)
- [Screen Reviewer del primer corte](../build/screen-review/20260725-163646/report.md)
- [Gate visual completo de Acceso](../build/screen-review/20260725-184432/report.md)
- [Repetición final de Acceso en iPhone compacto](../build/screen-review/20260725-access-gate-final/report.md)
- [Revisión del equipo](zentra-system-integration-rebranding-review.md)

### 20.2 Apple y Flutter

- [ActivityKit](https://developer.apple.com/documentation/ActivityKit)
- [Widget interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [Core Haptics](https://developer.apple.com/documentation/corehaptics/chhapticengine)
- [AVAudioSession ambient](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/ambient)
- [Actionable notifications](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)
- [HealthKit mindful session](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/mindfulsession)
- [Alternate icons](https://developer.apple.com/documentation/xcode/configuring-your-app-to-use-alternate-app-icons)
- [Flutter disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)

### 20.3 Datos, notificaciones y Android

- [Drift](https://pub.dev/packages/drift)
- [Drift migrations](https://drift.simonbinder.eu/migrations/)
- [Drift isolates](https://drift.simonbinder.eu/isolates/)
- [iOS notification limit](https://pub.dev/documentation/flutter_local_notifications/latest/)
- [Android exact alarms](https://developer.android.com/develop/background-work/services/alarms)
- [Android notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)

## 21. Veredicto

Calma precisa ya no es sólo una dirección visual. Se convierte en una
arquitectura de producto:

- El movimiento respeta al usuario.
- El tacto comunica una sola intención.
- El sonido convive con el sistema.
- Los datos tienen una fuente de verdad.
- El usuario puede empezar localmente y decidir después si quiere una cuenta.
- Pomodoro vive fuera de la app cuando aporta valor.
- Las burbujas conservan una firma visual sin ignorar Reduced Motion.
- Notas regresan en el momento correcto.
- Widgets e intents reducen navegación sin duplicar lógica.
- La privacidad se diseña antes de mostrar contenido en Lock Screen.
- Calendario es visible y Perfil concentra la parte divertida del progreso.

El plan mantiene la ambición del feedback, pero no confunde scaffolding con
funcionalidad terminada ni una librería con una arquitectura completa.

La secuencia correcta es:

> Primero calma, lenguaje y acceso honesto. Después fuente de verdad. Luego
> experiencias principales. Finalmente presencia útil y ecosistema.

Así Zentra puede sentirse premium, cálida y propia sin volverse frágil.
