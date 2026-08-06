# Zentra Salvia: seguimiento de pantallas

Actualizado: 5 de agosto de 2026

Este documento es el tablero operativo del revamp Salvia. La estrategia general
de seguridad, accesibilidad y minimalismo vive en
[`zentra-security-and-minimal-revamp-plan.md`](zentra-security-and-minimal-revamp-plan.md).
Aquí se registra qué pantalla está activa, qué falta y qué evidencia necesita
antes de considerarse terminada.

## Estados

- `Aprobada`: implementada, con validación técnica incremental y aprobación
  estética de Uri.
- `Activa`: contrato visual aprobado y plan listo para implementarse.
- `Pendiente`: todavía conserva su diseño anterior o no ha recibido revisión
  Salvia.
- `Bloqueada`: necesita una decisión o una dependencia antes de avanzar.

Un PASS técnico no implica aprobación estética. Cada fila cambia a `Aprobada`
sólo después de revisar capturas reales y, para flujos sensibles del sistema,
probar en dispositivo físico.

## Inventario vivo

La unidad de seguimiento es una superficie con una decisión visual propia, no
cada diálogo ni cada estado de carga.

| # | Superficie | Estado | Evidencia o siguiente paso |
|---:|---|---|---|
| 1 | Splash | Aprobada | Salvia light y AMOLED; conserva el logo oficial. |
| 2 | Acceso | Activa | Nube estacionada: sólo espacio local y restauración; pendiente Release física y aprobación de Uri. |
| 3 | Onboarding: Tu primer hábito | Activa | Gates automáticos y Release instalada; pendiente recorrido y aprobación de Uri. |
| 4 | Hoy | Aprobada | Resumen, navegación, progreso y acciones principales. |
| 5 | Mis hábitos | Aprobada | Activos, pausados, búsqueda, filtros y CTA. |
| 6 | Crear/editar hábito | Activa | Consenso 2/2 y Release instalada; pendiente recorrido y aprobación de Uri. |
| 7 | Notas: biblioteca | Activa | Vista previa legible, progreso, búsqueda con fragmento y filtro por etiqueta; pendiente Release física y aprobación de Uri. |
| 8 | Notas: superficie única | Activa | Lectura y escritura en el mismo lugar, sin modo editar; pendiente Release física y aprobación de Uri. |
| 9 | Recordatorio de nota | Pendiente | Revisar privacidad, fecha, hora y permisos. |
| 10 | Preparar enfoque | Activa | Portal, dial, presets y transición implementados; pendiente smoke nativo físico y aprobación final de Uri. |
| 11 | Enfoque activo | Activa | Inmersión, pausa, descanso, salida segura y cierre implementados; pendiente smoke nativo físico y aprobación final de Uri. |
| 12 | Historial de enfoque | Pendiente | Revisar jerarquía y estados vacíos. |
| 13 | Progreso y logros | Activa | Pulso Vivo 3.0 aprobado por Uri en Design Lab; pendiente adaptador productivo, goldens y Screen Reviewer. |
| 14 | Historial de actividad | Pendiente | Revisar actividad, archivo y filtros. |
| 15 | Calendario | Activa | Tiempo Vivo 1.0 aprobado como dirección y montado en Design Lab; pendiente aprobación de los renders Flutter, adaptador productivo y Screen Reviewer. |
| 16 | Perfil | Pendiente | Reducir cards sin esconder identidad ni cuenta. |
| 17 | Ajustes | Activa | Cuenta y sincronización sustituidas por estado local-only; pendiente Release física y aprobación de Uri. |
| 18 | Acerca de | Pendiente | Compactar información legal y de versión. |
| 19 | Soporte | Pendiente | Confirmar si sigue como pantalla independiente. |

Estado del corte: 3 superficies aprobadas, 10 activas y 6 pendientes. Las
superficies activas cuentan como pendientes hasta cerrar todos sus gates.

## Corte activo: Focus Portal + Silencio

Preparar enfoque y Enfoque activo comparten un solo contrato de interacción.
El círculo es selector, umbral de entrada, timer, pausa, transición a descanso
y sello de cierre. La sesión de trabajo invierte la superficie a verde
profundo; el descanso vuelve a crema sin cambiar la geometría.

- Storyboard aprobado:
  `docs/superpowers/prototypes/2026-08-04-focus-beyond-skins/portal-silence-motion-storyboard.png`.
- Prototipo aprobado:
  `docs/superpowers/prototypes/2026-08-04-focus-beyond-skins/portal-silence-prototype.html`.
- Alcance de este corte: launcher, dial con snap cada 5 minutos, transición,
  sesión, pausa, descanso, salida segura y cierre.
- Fuera de este corte: Historial de enfoque conserva estado `Pendiente` y no se
  rediseña por arrastre.
- Gate de cierre: pruebas enfocadas, análisis, scope `focus` del Screen
  Reviewer en teléfono y tablet, prueba Release física de background,
  notificación, Live Activity y Dynamic Island, y aprobación estética de Uri.

Evidencia del 4 de agosto de 2026, actualizada el 5 de agosto:

- `flutter analyze`: PASS global sin issues.
- `flutter test`: 965 PASS y 5 SKIP; los skips corresponden a integraciones que
  no contaban con su entorno externo y no se presentan como cobertura verde.
- Pruebas enfocadas de motor, controlador, notificación, Live Activity,
  historial y responsive: 51 PASS.
- Scope `focus` en iPhone 16e: 10/10, reporte en
  `build/screen-review/focus-portal-silence-20260804/iphone-compact/report.md`.
- Scope `focus` en iPhone 17 Pro Max: 10/10, reporte en
  `build/screen-review/focus-portal-silence-20260804/iphone/report.md`.
- Scope `focus` en iPad mini (A17 Pro): 10/10, reporte en
  `build/screen-review/focus-portal-silence-20260804/ipad-mini/report.md`.
- Scope `focus` en iPad Pro 13-inch (M5): 10/10, reporte en
  `build/screen-review/focus-portal-silence-20260804/ipad/report.md`.
- Revisión visual de Codex: PASS de jerarquía, espaciado, contraste y
  continuidad en las 40 capturas. No sustituye aprobación de Uri.
- Release `2.0.0+25` compilada, firmada e instalada en iPhone 15 Pro Max físico
  el 4 de agosto de 2026. El launch directo quedó bloqueado por el estado
  `Locked` del dispositivo, así que no se presenta como smoke nativo completo.
- Release `2.0.0+25` reinstalada y lanzada en «jesutorr's iPhone» (iOS 26.6) el 5
  de agosto de 2026, ya con la sesión nombrable. Esta vez el launch sí ocurrió.
  Instalación confirmada con `devicectl`. Instalar y abrir no es el smoke nativo:
  el recorrido de background, force quit, notificación, Live Activity y Dynamic
  Island sigue pendiente y sólo lo puede dar Uri sobre el dispositivo.

Auditoría cruzada del 4 de agosto de 2026, cuatro defectos corregidos sobre este
corte:

- La Live Activity había empezado a publicar el nombre escrito por el usuario en
  la pantalla bloqueada y en Dynamic Island, con una prueba que fijaba ese
  comportamiento como esperado. Se restauró la etiqueta genérica en las
  superficies del sistema, `sessionLabel` conserva el nombre real sólo dentro de
  la app y la prueba quedó invertida. Detalle en el plan de seguridad.
- El launcher de Enfoque se anclaba al borde superior en tablet y dejaba la
  mitad inferior de la ventana vacía. El portal ahora reclama el centro y el
  contenido más alto que la ventana sigue haciendo scroll desde arriba.
- Una nota de estado partía en dos la lista numerada del Gate S2 en el plan de
  seguridad.
- El Screen Reviewer podía reportar `PASS` sobre un build fallido: `flutter
  drive` se adjuntaba a la app ya instalada y capturaba código viejo. Ahora el
  runner falla ante errores de Xcode y ante capturas cuyo nombre no corresponde
  al dispositivo. Cualquier evidencia visual anterior a este cambio hay que
  leerla sabiendo que un PASS no garantizaba que el binario fuera reciente.

Reverificación del 4 de agosto, posterior a esas correcciones y previa a las del
día 5: `flutter analyze` sin issues, `flutter test` 959 PASS y 5 SKIP —cinco
menos que hoy, porque las pruebas de nombrar sesión aún no existían—, y scope
`focus` en iPad Pro 13-inch (M5) 10/10
con build limpio en `build/screen-review/20260804-141144/report.md`. El centrado
del portal en tablet quedó confirmado en captura y protegido por una aserción de
geometría en `test/widget/adaptive_navigation_test.dart`.

Nombrar la sesión de Enfoque, corregido el 5 de agosto de 2026. El rediseño no
rompió el guardado —el nombre siempre llegó al historial— pero sí dejó la opción
prácticamente inservible, por tres causas distintas:

- El botón decía «Añadir contexto», que no dice qué hace, y el campo había
  perdido su etiqueta, su texto de ayuda y la `ValueKey` de la que depende el
  Screen Reviewer. Ahora el botón dice «Nombrar esta sesión» y el campo declara
  que lo escrito se guarda en el historial y que es opcional.
- El campo cambiaba de forma y de altura al recibir el foco, porque declaraba un
  borde inferior propio mientras el tema global le daba un contorno redondeado al
  enfocarse. Ese salto de 16 px desbordaba el portal: `SliverFillRemaining`
  reserva espacio según la altura *intrínseca* del hijo, y un `AnimatedSize`
  informa la altura hacia la que anima, no la que pinta. Se eliminó el borde
  propio y el sliver se sustituyó por una altura mínima calculada del viewport,
  que mide el layout real: centra mientras el contenido cabe y crece a scroll
  cuando no.
- En teléfono el campo se revelaba por debajo del pliegue, así que pulsar el
  botón no parecía hacer nada. Revelarlo ahora también le da el foco, con lo que
  entra en pantalla y levanta el teclado.

El scope `focus` pasó de 10 a 12 capturas: el campo vacío y el campo con nombre
tienen captura propia. `flutter analyze` sin issues, `flutter test` 965 PASS y 5
SKIP, y `focus` 12/12 tanto en iPhone 16e como en iPad mini (A17 Pro)
(`build/screen-review/named-session-v4` y `named-session-ipadmini`). El nombre
escrito sigue sin salir a Live Activity, Dynamic Island ni notificaciones, y esa
última superficie quedó cerrada por construcción: los tres métodos de
notificación de enfoque recibían el nombre y no lo usaban, así que dejaron de
recibirlo. Una prueba nueva lee el título y el cuerpo del `zonedSchedule` real.

Estado del gate: implementación local, pruebas, análisis, matriz visual y build
Release en PASS. Siguen pendientes la aprobación estética de Uri y el recorrido
físico de background, force quit, notificación, Live Activity y Dynamic Island.
Ningún PASS técnico cambia estas dos superficies a `Aprobada` sin esas dos
evidencias.

## Cuatro defectos reportados sobre la Release física, 5 de agosto de 2026

El usuario instaló la Release en su iPhone 15 Pro Max y reportó cuatro fallos con
capturas. Los cuatro están corregidos.

**1. El lanzador de Enfoque exigía scroll y escondía dos opciones.** «Otro» y
«Nombrar esta sesión» quedaban 135 dp bajo el pliegue y nada en pantalla sugería
que hubiera más. La medición —una prueba desechable que imprimía `getRect` y
`maxScrollExtent` por tamaño— reveló dos causas que no se deducen leyendo el
código: el titular no ocupaba dos líneas sino **cinco** (195 dp a 393 dp de
ancho), y el dial se dimensionaba sólo por ancho, así que un teléfono de 375×667
recibía 335 dp de dial, la mitad de su altura. Seis cambios coordinados dejaron
`maxScrollExtent == 0` en 430×932, 393×852, 375×667, 360×640 y 320×568:

- El selector Rápido/Ciclo subió al tope, antes del titular, igual que «Se repite
  / Una sola vez» abre el formulario de hábito. Es lo que pidió el usuario y
  además ordena la pantalla por ritmo antes que por retórica.
- El titular pasó a una línea, «Una sola cosa», y perdió el subtítulo.
- El dial se acota también contra la altura (`height * 0.42`, mínimo 240 dp). En
  393 dp y más el tope por ancho sigue ganando, así que ahí mide exactamente lo
  que siempre midió: 353 dp en 393, 372 dp en 430.
- Los cuatro presets y «Otro» pasaron de `Wrap` a `Row` con `Expanded`. Un `Wrap`
  que no cabe manda «Otro» a una segunda fila y cuesta 56 dp fijos; peor, deja la
  opción de elegir cualquier otra duración sola en una fila que nadie mira.
- En pantallas angostas los chips pierden ancho decorativo, nunca altura:
  `VisualDensity.compact` los dejaba en 40 dp, bajo el mínimo táctil de 48. Se
  descartó y se documentó por qué.
- Los espaciados del sliver responden a `layout.isShort`.

Dos mutaciones confirman que la prueba tiene dientes: restaurar el titular viejo
falla con 46 dp de scroll en 393×852, y volver el dial a sólo-ancho falla con 14
dp en 360×640.

**2. Contraste perdido en «Enfoque completado».** Corregido y verificado con
prueba de ratio.

**3. Un acento único en el formulario de hábito.** El acento cambiaba por
categoría: elegir «Agua» repintaba el formulario de azul y «Movimiento» de
naranja, así que el color se movía mientras el usuario todavía estaba decidiendo.
Ahora `_CategoryOption` usa `palette.brandTeal` —el mismo teal del botón de
guardar— para anillo y relleno, y el icono dejó de comunicar categoría para
comunicar selección. Los `showTimePicker`/`showDatePicker` perdieron su
`colorScheme` override, que hacía llegar el mismo diálogo azul o naranja según
una decisión anterior sin relación. La banda del encabezado quedó fija, y el
token `salviaFormHeader` claro pasó de un melocotón que ya nadie pintaba a la
familia teal (`0xFFDCEDE6`; más tarde ese mismo día, al teal sólido `0xFF00796B`
—ver la sección de paridad de lanzadores más abajo). El alcance fue deliberado:
por decisión del usuario,
sólo el formulario. Las tarjetas, la lista y Hoy conservan color por categoría, y
sus once llamadas a `getCategoryColor`/`getSalviaCategoryColor`/`getCategoryTint`
quedaron intactas. Los días de la semana ya caben completos, domingo incluido.

**4. La Live Activity ahora tiene un héroe.** La línea más prominente del widget
era `attributes.activityName`, truncada a «Sesión de enf…», y ese nombre es
genérico por política de privacidad: gastaba el lugar de honor en no decir nada.
Se eliminó de la pantalla bloqueada y de la región `.bottom` del Dynamic Island,
y el contador ocupó su lugar a 46 pt redondeados sobre una etiqueta de etapa
pequeña, la barra de progreso y «Al terminar». El icono de etapa medía **1.69:1**
sobre el fondo crema, muy por debajo del 3.0:1 que necesita un glifo: pasó a deep
green (4.80:1). El Dynamic Island conserva el mint a propósito, porque se dibuja
sobre negro, donde el mint lee 11.24:1 y el deep green casi desaparece. El widget
no puede importar `ZentraPalette`, así que un `private enum ZentraActivityPalette`
espeja los pocos colores con sus ratios medidos en el comentario. `pausedProgress`
ganó una guarda contra división por cero. El campo `activityName` sigue en
`ZentraActivityAttributes` y en el puente Dart/Swift: el widget ya no lo lee, pero
quitarlo de punta a punta rompería el contrato del puente sin ganar nada.

Verificación: `flutter analyze` sin issues sobre todo el código versionado,
`flutter test` 986 PASS y 5 SKIP, y el target `ZentraWidgetExtension` compila con
`** BUILD SUCCEEDED **` en Release para `iphoneos`. Las dos pruebas que fallan en
la corrida completa pertenecen a prototipos sin versionar de otra sesión
(`progress_pulse`, `calendar_time_live`) y no tocan nada de este trabajo.

Release `2.0.0 (25)` con las cuatro correcciones instalada y lanzada en
«jesutorr's iPhone» (iOS 26.6) el 5 de agosto de 2026. El `.appex` del widget
corre como proceso propio en el dispositivo, así que la Live Activity rediseñada
está desplegada, no sólo compilada. Sigue pendiente el smoke nativo que sólo
puede dar Uri: background, force quit, notificación, Live Activity y Dynamic
Island vistos en la pantalla real.

Nota de toolchain, porque costó tres builds fallidos: dos compilaciones
simultáneas del mismo proyecto corrompen el `build.db` de Xcode y el error
miente. Aparece como `disk I/O error` de SQLite, o como un `.d`, un
`OutputFileMap.json` o un `const_extract_protocols.json` que no se puede abrir, y
con el volumen al 96% invita a diagnosticar disco lleno. No lo era: el log del
sistema no reportaba ni un solo error de E/S, y el culpable era un `flutter drive`
del Screen Reviewer corriendo en paralelo desde otra sesión sobre este mismo
repo. En cuanto terminó, el build pasó en 49.8 s sin cambiar nada. Antes de
borrar DerivedData conviene correr `pgrep -fl "flutter_tools|xcodebuild"`.

## «Nuevo hábito» y «Nuevo enfoque» abren con el mismo objeto, 5 de agosto de 2026

El usuario pidió que las dos pantallas de creación se vieran hermanas, tomando
«Se repite / Una sola vez» como referencia para «Rápido / Ciclo», y que la banda
del encabezado pasara del `#DCEDE6` clarito al teal fuerte de los botones —**sólo
en light**. Lo que salió no fue un parecido sino una pieza compartida.

**Por qué compartida y no copiada.** Los dos selectores ya se habían parecido una
vez y se habían separado en cuatro ejes a la vez: radio 999 contra 18, color del
riel, `MainAxisSize.min` contra `Expanded`, y relleno `brandDeep` contra pastilla
clara. Ninguna prueba lo vio porque cada pantalla se probaba sola y por separado
las dos estaban bien; lo que estaba roto era la relación. `ZentraModeBand` y
`ZentraModeSelector` viven ahora en `lib/presentation/widgets/mode_band.dart`, y
`_HabitModeSelector`, `_HabitModeOption`, `_ModeSelector` y `_ModePill`
desaparecieron. Un widget compartido no puede divergir.

**El teal fuerte forzó dos decisiones que no se ven venir.** Medido sobre la banda
`#00796B`: `ink` da 2.96:1 y `inkSecondary` 1.09:1, ambos por debajo de 4.5; el
blanco da 5.32:1. Así que el contenido de la banda **se invierte a claro** en vez
de heredar la tinta de la página. Y el riel **se oscurece** en vez de aclararse:
blanco al 55% compone `#8CC3BC` sobre el teal y deja su propia etiqueta en
1.97:1, mientras negro al 14% da `#00685C` y 6.70:1. El token oscuro
(`#112E28`) no se tocó, y una prueba afirma que no se arrastre al teal claro.

**La banda es el techo de la pantalla, no un rectángulo dentro de ella.** Con el
inset del notch aplicado por fuera quedaba una franja crema encima del teal y la
banda se leía despegada del borde. El `SafeArea` vive dentro del color: la banda
arranca en 0 y el contenido baja. Una prueba lo fija con `padding.top = 47`, y
mutar la estructura a la anterior falla con `Actual: <47.0>` en las dos pantallas.

**Regresión propia, encontrada y cerrada.** Al subir el selector dentro de la
banda, ésta creció una fila entera y en 320×568 costó 16 dp más de los que el
lanzador tiene: rompió el `maxScrollExtent == 0` de la corrección 1. Los 16 dp
salieron del aire de la banda misma cuando `layout.isShort`, no del portal, que es
la parte a la que el usuario tiene que llegar.

**Y un defecto que la captura delató.** El chip de duración seleccionado mostraba
el número encimado por el palomeado. Parecía medio frame; medido con una sonda
desechable, no lo era: el chip recibía 54.8 dp donde necesitaba 68, y la etiqueta
del «25» salía a **0.0 dp de ancho** en 393 y 375. Dos causas. El palomeado
ensancha el chip elegido y con cinco chips repartiéndose la fila no hay ancho
donde ensancharse: `showCheckmark` pasó a `false` en todos los anchos —el relleno
y la semántica ya dicen cuál está elegido, que era el razonamiento que ya existía
por debajo de 360 dp. Y el relleno de etiqueta angosto dejó de depender del ancho
del dispositivo: el aprieto es de la fila, no del teléfono, y atarlo a 360 dp
hacía que los chips cambiaran de forma en un umbral invisible. Los dígitos ahora
miden entre 14 y 28 dp en 430, 393, 375, 360 y 320.

Herramientas nuevas: `tool/launcher_parity_lab.dart` monta las dos pantallas
reales lado a lado sobre un contenedor de vista previa (`PARITY_DARK`,
`PARITY_ONLY=habit|focus`) —los otros labs montan widgets render-only con un
fixture, pero aquí la pregunta es de parangón y no se contesta mirando una pieza
aislada— y `test/widget/launcher_parity_test.dart` compara las dos pantallas
entre sí en vez de contra literales de color, así que sobrevive a un cambio de
paleta en lugar de exigir una edición. Tres mutaciones más confirmaron dientes,
con los mismos números medidos antes de escribir código: banda de vuelta a
`#DCEDE6` → 3 fallos; riel de vuelta a blanco al 55% → 1.9758; título sin
`color: onBand` → 2.9556.

## Corte activo: nube estacionada

La build vigente es local-only. Este corte afecta únicamente Acceso, Ajustes,
la recuperación de un fallo al cargar sesión y la infraestructura de arranque,
identidad y persistencia relacionada con nube.

- Supabase queda apagado por default mediante `ZENTRA_CLOUD_ENABLED=false`.
- URL, publishable key y flags OAuth no tienen efecto mientras el switch raíz
  permanezca apagado.
- Una identidad previamente vinculada conserva el mismo `ownerId`, hábitos,
  notas, registros, sesiones y progreso. Sólo se retira su proveedor activo y
  se registra localmente que la identidad quedó estacionada.
- La sesión segura de Supabase se elimina del dispositivo sin contactar la red.
- El vínculo y la outbox existentes permanecen congelados en Drift para una
  futura reactivación. Las nuevas escrituras locales no generan outbox.
- `Salir de este espacio` termina sólo la sesión local.
- `Eliminar espacio de este dispositivo` elimina sólo la copia local. No llama
  a Supabase ni promete borrar una identidad o datos remotos.
- El error `Tu espacio necesita otro intento` conserva `Reintentar` y agrega
  `Volver al acceso`, para que ninguna preparación fallida encierre al usuario.
- Contrato y criterios de reactivación:
  [`zentra-cloud-parking-plan.md`](zentra-cloud-parking-plan.md).

Estado del gate: pruebas enfocadas en PASS. Análisis completo, suite completa,
Screen Reviewer incremental, Release física y `URI APPROVED` todavía pendientes.

## Corte reabierto: Onboarding

El onboarding aprobado ahora es una sola superficie `2 / 2`. Se retiró por
completo `Hazlo tuyo`, talismán, intención y la confirmación posterior a
restaurar. Restaurar entra directo a Hoy. El único paso permite crear o saltar
el primer hábito, elegir una categoría mediante píldoras ajustadas con punto de
acento y revisar los recordatorios listos. El permiso del sistema se solicita
sólo al tocar `Comenzar en Zentra`; si se niega, Hoy muestra un aviso
descartable.

- Mockup aprobado: `design/approved/onboarding-first-habit-approved-2026-08-03.png`.
- Evidencia de matriz: `build/screen-review/onboarding-final-20260803/`.
- Corrección compacta final: `build/screen-review/onboarding-final-compact-v2-20260803/`.
- Estado: TECHNICAL, CONTRACT, VISUAL y simuladores en PASS. Falta probar la
  Release física y obtener `URI APPROVED`.
- Release `2.0.0 (25)` instalada y lanzada el 3 de agosto de 2026 en
  `jesutorr’s iPhone`, bundle `com.jesutorr.appzentra`; falta el recorrido
  manual de Uri.

## Corte activo: Crear/editar hábito

### Objetivo

Convertir el formulario actual, largo y organizado como pasos, en una sola
composición Salvia que permita crear o editar un hábito recurrente o una
actividad única sin scroll en un iPhone moderno con escala de texto normal.

`Sin scroll` no es una restricción absoluta. Con teclado abierto, 320 dp de
ancho, texto grande, orientación horizontal o un error de validación, el
contenido debe poder desplazarse para que ninguna acción quede inaccesible.

### Contrato visual

1. El encabezado contiene atrás, título y un segmento de dos estados:
   `Se repite` y `Una sola vez`.
2. El formulario conserva una sola acción primaria persistente.
3. El cuerpo evita cards numeradas, preview, copy de ayuda repetido y la
   sección `Opciones avanzadas`.
4. `Qué quieres hacer` usa un campo con label persistente y sugerencia
   accesible mediante el icono de destellos.
5. Las cinco categorías viven en una fila de controles del mismo ancho y alto.
   La selección se comunica con borde, superficie y semántica, no sólo color.
6. Los siete días usan `Expanded` y `AspectRatio(1)` para ocupar exactamente el
   ancho disponible sin números mágicos.
7. El modo recurrente muestra presets `Todos`, `L-V`, `S-D` y `Otro`.
8. El modo de una sola vez muestra `Hoy`, `Mañana` y `Elegir`, más una fila con
   la fecha completa.
9. `Recordarme` conserva switch, permiso y hora. Al activarse, la hora aparece
   como control compacto en la misma fila.
10. El CTA usa `Crear hábito` en recurrente, `Crear actividad` en una sola vez
    y `Guardar cambios` al editar cualquiera de los dos.

### Decisiones de comportamiento

- El modelo y repositorio continúan usando `Habit`. `Actividad` es copy de UI
  para el caso `isOneTime`; no se renombra el dominio ni se cambia el esquema.
- Toda actividad nueva de una sola vez guarda `scheduledDate`. `Hoy` es el
  default; `Mañana` y `Elegir` actualizan la misma fuente de verdad.
- Un registro legado `isOneTime` sin `scheduledDate` se muestra inicialmente en
  `Hoy`, pero no se modifica hasta que el usuario guarde.
- En una sola vez, los círculos de días son informativos. Sólo el día de la
  fecha elegida aparece marcado con borde, no relleno, para que no parezca una
  recurrencia. La fecha se cambia desde `Hoy`, `Mañana` o `Elegir`.
- En recurrente, `Otro` habilita selección múltiple directa de días. Elegir o
  quitar un día actualiza el resumen visible.
- El permiso de notificaciones se solicita únicamente al encender el switch.
  Negarlo deja el recordatorio apagado y permite guardar.
- Un recordatorio de actividad única debe quedar en una fecha y hora futuras.
- Editar conserva `id`, `createdAt`, historial, archivo, modo, categoría,
  frecuencia, fecha y recordatorio existentes.
- Eliminar permanece sólo en edición, dentro de un menú secundario en el
  encabezado y con la confirmación destructiva actual.
- El doble tap no puede crear duplicados y un fallo al guardar conserva el
  contenido del formulario.

### Responsive y accesibilidad

- Teléfono normal: composición de una sola pantalla con CTA inferior.
- Teléfono compacto, texto grande o teclado: `SafeArea` y scroll de respaldo;
  el CTA sigue siendo alcanzable y el campo enfocado permanece visible.
- iPad mini y iPad Pro: formulario centrado con ancho máximo aproximado de
  640 a 700 dp. No se estira como teléfono ni se conserva una segunda columna
  vacía sólo para una preview eliminada.
- Objetivos táctiles de al menos 48 dp.
- Labels, valores y estado seleccionado disponibles para VoiceOver/TalkBack.
- El día de una actividad única se anuncia como, por ejemplo,
  `Martes, fecha seleccionada`.
- El cambio de modo usa transición de 220 a 300 ms. Con Reduce Motion se reduce
  a un cambio de estado o fade breve.
- Light y AMOLED usan tokens existentes de tema y categoría. No se agregan
  hexadecimales sueltos al widget.

### Plan de implementación

#### Fase 1. Estado y compatibilidad

1. Sustituir la combinación de `isOneTime`, `advancedExpanded` y
   `addToCalendar` por un único modo de programación visible desde el inicio.
2. Mantener los campos y contratos existentes de `Habit`, controller,
   repositorio y servicio de recordatorios.
3. Hacer que una actividad nueva siempre tenga fecha, sin migración automática
   ni escritura silenciosa de registros anteriores.
4. Centralizar resúmenes de frecuencia, fecha y CTA para que el copy no se
   desincronice del estado.

#### Fase 2. Composición Salvia

1. Rehacer encabezado y control segmentado.
2. Aplanar identidad y categoría en un solo bloque visual.
3. Construir la fila compacta de categorías con cinco controles flexibles.
4. Construir una tira de siete días compartida por ambos modos.
5. Intercambiar presets recurrentes y de fecha con `AnimatedSwitcher` o
   equivalente compatible con Reduce Motion.
6. Integrar fecha, recordatorio y hora como filas compactas.
7. Mantener un único CTA inferior y adaptar el modo edición.

#### Fase 3. Responsive, teclado y tablet

1. Ajustar densidad vertical para que el flujo normal quepa sin scroll en
   iPhone 16e y iPhone 17 Pro Max.
2. Conservar scroll de respaldo para texto grande, teclado y errores.
3. Reemplazar la composición iPad de formulario más preview por un formulario
   centrado y acotado.
4. Verificar safe areas, orientación, contraste aumentado y escalas de texto.

#### Fase 4. Pruebas y evidencia

1. Actualizar las pruebas existentes sin rebajar sus assertions de lógica.
2. Agregar cobertura para cambio de modo, presets, fecha, día informativo,
   reminder/hora, hidratación de edición y copy de CTA.
3. Conservar casos de permiso negado, recordatorio futuro, doble tap, fallo de
   guardado, eliminación, dark y Reduce Motion.
4. Proteger explícitamente el layout normal sin scroll y el fallback accesible
   a 320 dp con 320 por ciento de texto.
5. Crear un scope `habit-form` del Screen Reviewer con ocho estados por
   dispositivo:
   - recurrente light;
   - recurrente AMOLED;
   - una sola vez light;
   - una sola vez AMOLED;
   - días personalizados;
   - recordatorio con hora;
   - teclado abierto;
   - edición con acción destructiva disponible.
6. Ejecutarlo en iPhone 16e, iPhone 17 Pro Max, iPad mini e iPad Pro.
7. Correr `flutter analyze`, pruebas enfocadas y suite completa.
8. Presentar capturas a Uri. El PASS técnico no cierra el gate sin su aprobación
   estética.

### Estado de fases del corte activo

| Fase | Estado | Gate necesario para cerrarla |
|---|---|---|
| 1. Estado y compatibilidad | Verificada; pendiente Uri | TECHNICAL y CONTRACT PASS, suite completa y consenso 2/2. |
| 2. Composición Salvia | Verificada; pendiente Uri | VISUAL y CONTRACT PASS contra el mockup aprobado. |
| 3. Responsive, teclado y tablet | Verificada; pendiente Uri | Cuatro simuladores PASS; teclado nativo pendiente en Release físico. |
| 4. Pruebas y evidencia | Verificada; pendiente Uri | Análisis, 620 pruebas, matrices y consenso final en PASS. |

`Completada` se escribe únicamente después del gate de consenso descrito abajo.
Terminar código o recibir dos opiniones favorables no basta por sí solo.

#### Evidencia de Fase 1

- El modo recurrente o una sola vez tiene una única fuente de verdad.
- El selector de modo está siempre visible y `Opciones avanzadas` fue retirado.
- El copy de encabezado, CTA, validación, permisos, errores y eliminación se
  deriva del modo.
- Toda actividad única nueva guarda una fecha local normalizada, sin hora.
- Un registro legado sin fecha no se reescribe al abrirse; recibe fecha sólo al
  guardarse explícitamente.
- La suite completa pasó con 620 pruebas. Cinco integraciones Supabase quedaron
  omitidas de forma explícita porque requieren las variables del entorno de
  test remoto.
- `flutter analyze` terminó sin issues.
- El revisor lógico detectó dos huecos de cobertura: eliminación desde el
  formulario y restauración completa sin flash de Acceso/Onboarding. Ambos se
  agregaron y pasaron; la reauditoría emitió TECHNICAL y CONTRACT PASS.
- El revisor visual comparó los dos mockups contra las matrices light/AMOLED de
  iPhone 16e, iPhone 17 Pro Max, iPad mini e iPad Pro. Emitió VISUAL, CONTRACT y
  DEVICE PASS para simuladores y confirmó el resultado después del delta final.
- `habit-form-matrix-20260803` pasó 8/8 en cada dispositivo.
- `onboarding-final-20260803` pasó 6/6 en cada dispositivo; el iPhone 16e usa
  como evidencia compacta autoritativa `onboarding-final-compact-v2-20260803`.
- El alcance se limitó a Crear/editar hábito y dependencias directas. No se
  revisaron Notas, Hoy, Enfoque ni otras superficies.

Las cuatro fases siguen abiertas únicamente hasta validar la Release ya
instalada en el iPhone físico y recibir `URI APPROVED`. No se marcan
`Completada` ni `Aprobada` antes de ese último gate.

### Gate de consenso por fase

Cada fase usa el mismo ciclo obligatorio:

1. Joy implementa la fase y ejecuta sus comprobaciones locales.
2. Se lanzan dos agentes revisores independientes. Ambos reciben el objetivo,
   el diff, los criterios de aceptación y una lista explícita de superficies
   afectadas, pero preparan primero su veredicto sin ver el del otro.
3. El Revisor A prioriza corrección, regresiones, persistencia, permisos y
   pruebas. El Revisor B prioriza UX Salvia, responsive, accesibilidad,
   movimiento y consistencia con las pantallas aprobadas. Los dos pueden
   reportar hallazgos de cualquier categoría.
4. Después de la revisión independiente, ambos contrastan hallazgos. Deben
   producir acuerdos, desacuerdos y evidencia concreta. No se fuerza consenso.
5. Joy revisa los comentarios contra código, pruebas y capturas reales. Un
   comentario incorrecto se descarta con evidencia; uno válido se corrige.
6. Se vuelven a ejecutar las comprobaciones afectadas. Si cambió materialmente
   la implementación, los revisores reciben el delta final para confirmar que
   sus bloqueos quedaron resueltos.
7. Joy entrega a Uri el veredicto, los hallazgos corregidos, los riesgos
   residuales y la evidencia exacta que debe verificar.
8. Uri prueba o inspecciona el resultado. Sólo cuando Uri confirma que está bien
   se cambia la fase a `Completada` en esta tabla.

Si los dos revisores discrepan, existe un fallo reproducible, falta evidencia o
Uri no aprueba el resultado, la fase permanece abierta. El acuerdo de agentes
es una revisión adicional, no una sustitución del criterio de Uri ni de los
checks automatizados.

La revisión es incremental. Los agentes sólo recorren la pantalla activa, los
componentes compartidos modificados por esa fase y los flujos directamente
dependientes. No se vuelven a revisar Notas, Hoy, Enfoque u otras superficies
estables si el diff no las afecta. La matriz completa se reserva para el cierre
del producto o para un cambio transversal real de tema, navegación,
persistencia o infraestructura.

### Archivos previstos

- `lib/presentation/habit_form_screen.dart`
- `test/widget/habit_form_screen_test.dart`
- `integration_test/screen_reviewer_test.dart`
- `tool/run_screen_reviewer.dart`
- `docs/screen-reviewer.md`
- este tracker y, si cambia una regla global, el plan minimalista principal.

No se prevén cambios de schema, migraciones Supabase ni renombres del dominio.
Si la implementación demuestra que alguno es necesario, se detiene ese cambio
de alcance y se documenta antes de tocar persistencia.

### Criterio de terminado

- Crear y editar funcionan en los dos modos.
- Una actividad única aparece sólo en su fecha y su recordatorio se programa una
  sola vez.
- Frecuencia recurrente y presets producen exactamente los días esperados.
- No hay scroll en el flujo normal de teléfono ni overflow en los fallbacks.
- El teclado no oculta la acción necesaria.
- Light, AMOLED, iPhone e iPad tienen composición intencional.
- Semántica, contraste, Reduce Motion y targets táctiles pasan revisión.
- Análisis, pruebas enfocadas, suite completa y scope visual pasan.
- Dos revisores independientes alcanzan consenso sin bloqueos pendientes y Joy
  verifica su conclusión contra la evidencia.
- Uri aprueba las capturas.

## Corte activo: Notas en Markdown vivo

La nota dejó de tener un modo lectura y un modo edición separados. El cuerpo
siempre se ve renderizado y sólo el bloque bajo el cursor se convierte en
Markdown literal. `NoteEditorScreen` se retiró; la única superficie es
`NoteSurface`.

- Plan: [`superpowers/plans/2026-08-03-notas-markdown-vivo.md`](superpowers/plans/2026-08-03-notas-markdown-vivo.md).
- Scope del Screen Reviewer: `notes`, 10 capturas por dispositivo.
- Evidencia: `build/screen-review/notes-20260804/`, en iPhone 16e,
  iPhone 17 Pro Max, iPad mini (A17 Pro) e iPad Pro 13-inch (M5).
- Los cuatro dispositivos pasaron 10/10 sin excepciones de Flutter.

### Estado de los gates

| Gate | Estado |
|---|---|
| TECHNICAL | PASS: recorrido completo y suite enfocada en verde. |
| CONTRACT | PASS con hallazgos: nada prohibido aparece, pero quedan nueve observaciones abiertas, cinco importantes y cuatro de pulido. |
| VISUAL | Pendiente: las capturas existen y fueron revisadas, falta el sí de Uri. |
| DEVICE | PASS en simuladores; Release física pendiente. |
| URI APPROVED | Pendiente. |

### Hallazgos de la revisión visual del 4 de agosto

Ninguno es bloqueante. Se registran aquí en vez de corregirse en la tarea de
cierre, para que el arreglo entre con su propia revisión.

Importantes:

1. La barra de formato se desborda en todo iPhone. `Deshacer` y `Rehacer`
   quedan siempre fuera de pantalla y el scroll horizontal no tiene ninguna
   señal visible. iPhone 16e muestra 7 de 11 controles, iPhone 17 Pro Max
   muestra 9 de 11 y ambos iPad muestran los 11.
2. El título de la nota y un bloque `#` usan el mismo `headlineSmall`, así que
   `Repasar Álgebra lineal` y `Repaso de la semana` compiten como si fueran
   dos títulos.
3. Al elegir una etiqueta, la tira se desplaza y deja el chip `Todas` casi
   fuera de pantalla, justo la salida explícita que el filtro promete.
4. En la columna lateral de 320 dp la ayuda del campo de etiquetas se recorta
   a `Escribe una y confirma para agre…` en vez de envolverse.
5. Al escribir, el encabezado carga seis controles y en un teléfono compacto
   el estado de guardado se recorta a `Sin …`.

Pulido:

6. El fragmento de búsqueda empieza a media palabra: `…a Transformaciones,`.
7. Las etiquetas del panel de detalles no tienen contorno de chip, mientras
   que los acentos sí, y se leen como texto suelto con una equis.
8. La hoja de detalles no tiene ancho máximo en tablet y se estira en iPad
   mini.
9. La biblioteca pasa a lista y detalle en 800 dp, pero la nota sólo gana
   columna lateral en 840 dp. Un iPad Pro de 11 pulgadas en vertical, con
   834 dp, recibe biblioteca de dos paneles y nota con hoja inferior.

## Protocolo para cada pantalla siguiente

1. Mover una sola superficie a `Activa`.
2. Congelar su contrato visual y sus decisiones de comportamiento.
3. Implementar sin rediseñar superficies ya aprobadas.
4. Aplicar el gate de dos revisores en cada fase.
5. Ejecutar lógica y Screen Reviewer sólo para lo modificado.
6. Mostrar evidencia light, AMOLED, teléfono y tablet.
7. Marcar `Aprobada` sólo después del sí de Uri, o volver a `Activa` con
   hallazgos.
8. Al final del producto, ejecutar la matriz completa antes de release.
