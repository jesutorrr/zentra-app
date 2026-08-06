# Zentra Screen Reviewer

El Screen Reviewer recorre el flujo principal de Zentra con widgets de
producción sobre simuladores reales. En cada parada:

- realiza acciones por texto, tooltip o tipo de widget, no por coordenadas;
- falla ante excepciones de layout o render;
- verifica que la pantalla esperada haya abierto;
- toma una captura PNG;
- genera un reporte Markdown por dispositivo.

## Cobertura inicial

1. Splash
2. Acceso local-first y restauración
3. Onboarding de una pantalla: primer hábito y recordatorios listos
4. Onboarding: ajuste de recordatorios
5. Today: aviso descartable después de negar notificaciones
6. Today con datos
7. Crear y editar hábito recurrente o actividad única
8. Mis hábitos con estado activo, búsqueda y archivados
9. Notas: biblioteca, búsqueda, nota en lectura, nota en escritura y
    recordatorio
10. Enfoque rápido, dial de duración, ciclo Pomodoro, sesión activa,
    pausa e historial
11. Progreso, colección de logros, actividad durable y archivo de tareas
12. Calendario
13. Perfil
14. Configuración
15. Acerca de

## Ejecutar en todos los simuladores iOS encendidos

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart
```

Si el checkout no contiene el SDK fijado, el runner usa `FLUTTER_ROOT` o el
`flutter` disponible en `PATH`. También se puede fijar explícitamente:

```bash
SCREEN_REVIEW_FLUTTER=/ruta/al/flutter \
  dart run tool/run_screen_reviewer.dart
```

## Ejecutar en un solo simulador

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --device AD73667E-15C3-48D3-B1C7-B7B45C808754
```

## Revisar solo una pantalla modificada

Durante un revamp incremental se puede limitar el recorrido a la pantalla
afectada. El scope conserva datos deterministas, interacciones reales,
capturas light/AMOLED y detección de excepciones, sin recorrer pantallas que no
cambiaron:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope habits \
  --device AD73667E-15C3-48D3-B1C7-B7B45C808754
```

Para revisar Splash, Acceso local, el aviso de nube estacionada en Ajustes y
la salida recuperable de un workspace, incluidas sus variantes AMOLED:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope entry
```

Este scope genera 9 capturas por dispositivo y afirma que Google, Apple y la
sincronización Supabase no aparecen como acciones activas.

Para revisar el onboarding Salvia de una sola pantalla, el sheet de
recordatorios y el aviso posterior al permiso negado:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope onboarding
```

Este scope genera 6 capturas por dispositivo: primer hábito, ajustes y aviso
de permiso negado, cada uno en light y AMOLED. Teléfono y tablet conservan una
sola columna centrada y acotada.

Para revisar únicamente Crear/editar hábito:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope habit-form
```

Este scope genera 8 capturas por dispositivo: recurrente y actividad única en
light/AMOLED, días personalizados, recordatorio, teclado y menú de edición. Desde
el 5 de agosto de 2026 el formulario lleva un solo acento —el teal del botón de
guardar— en lugar de uno por categoría, así que estas capturas sirven para
confirmar que ni la banda del encabezado ni los selectores cambian de color al
probar categorías.

Ese mismo día la banda pasó al teal sólido `#00796B` en light y su contenido se
invirtió a blanco, y «Se repite / Una sola vez» dejó de ser código propio de esta
pantalla: es `ZentraModeSelector`, el mismo widget que pinta «Rápido / Ciclo» en
Enfoque. Dos cosas que sólo se ven en la captura y no en una prueba de ratio: que
la banda **toque el borde superior** —el inset del notch se toma dentro del color,
y aplicado por fuera dejaba una franja crema que hacía leer la banda como un
rectángulo flotando— y que la banda de esta pantalla y la de Enfoque se vean
hermanas. El cotejo lado a lado tiene su propia herramienta, más abajo.

Para revisar la biblioteca de Notas y la superficie única de nota:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope notes
```

Este scope genera 10 capturas por dispositivo: biblioteca, filtro por
etiqueta, búsqueda con fragmento resaltado, nota en lectura, nota en
escritura con la barra de formato, detalles, checklist terminada y la
repetición light/AMOLED de biblioteca, lectura y escritura. La nota sembrada
trae encabezado, negritas, casillas y cita, así que la captura muestra el
formato renderizado y no sólo un párrafo. En una ventana angosta los detalles
salen como hoja inferior; en una ancha salen como columna lateral y la captura
la muestra plegada.

Para revisar únicamente el contrato `Portal + Silencio` de Enfoque:

```bash
./flutter/bin/dart run tool/run_screen_reviewer.dart \
  --scope focus
```

Este scope genera 12 capturas por dispositivo: portal, dial, ciclo, campo de
nombre vacío, sesión nombrada, sesión activa, pausa, salida segura, descanso,
portal AMOLED, sesión AMOLED y sello de cierre. El campo de nombre tiene dos
capturas porque su altura al recibir el foco ya desbordó el portal una vez, y
mirar sólo el campo lleno no lo habría mostrado. La parada del portal afirma
además que el selector Rápido/Ciclo va antes del titular y que
`maxScrollExtent == 0`: «Otro» y «Nombrar esta sesión» llegaron a quedar bajo el
pliegue, y una captura de un lanzador incompleto se ve perfectamente sana. La
captura del cierre usa el
mismo widget de producción con una actividad determinista; el flujo de tiempo,
persistencia y background sigue perteneciendo a sus pruebas de motor y al smoke
físico.

Los scopes disponibles viven en `tool/run_screen_reviewer.dart`. La matriz
completa se reserva para cerrar un bloque de pantallas o preparar un release.

## Cotejar «Nuevo hábito» contra «Nuevo enfoque»

El Reviewer recorre una pantalla a la vez, y hay preguntas que eso no contesta:
si dos pantallas se ven hermanas no se sabe mirando una. `launcher_parity_lab`
monta las dos **pantallas reales** —no maquetas— lado a lado sobre un contenedor
de vista previa:

```bash
flutter run -t tool/launcher_parity_lab.dart \
  -d AD73667E-15C3-48D3-B1C7-B7B45C808754
```

`--dart-define=PARITY_DARK=true` para AMOLED y
`--dart-define=PARITY_ONLY=habit|focus` para una sola pantalla a tamaño completo,
que es lo que hay que usar en un teléfono: dos pantallas de verdad aplastadas a
196 dp de ancho enseñan defectos que no existen. Por debajo de 720 dp el lab se
apila en pestañas por esa misma razón.

Lo que el lab ve y una prueba no: que la banda llegue al borde, y que el chip de
duración seleccionado en Enfoque muestre su número. Ese segundo defecto —el
palomeado encimado sobre el «25»— salió en una captura, se confundió con un
frame a medias y sólo la medición lo desmintió: la etiqueta valía 0.0 dp de
ancho. Lo estructural sí está en prueba: `test/widget/launcher_parity_test.dart`
compara las dos pantallas entre sí, no contra literales de color.

Los artefactos quedan bajo `build/screen-review/<timestamp>/`. Cada corrida
incluye `report.md` y una carpeta de capturas por dispositivo.

## Qué valida y qué no

Un `PASS` técnico exige que el recorrido termine, que no existan excepciones de
Flutter y que se generen las 42 capturas esperadas por dispositivo en el scope
completo, o el conteo exacto definido para un scope incremental. Las
capturas permiten que Uri y Codex revisen jerarquía, espaciado, contraste y
feeling. Por eso `PASS` no significa por sí solo que el diseño visual esté
aprobado.

El driver falla si dos capturas intentan usar el mismo nombre en una corrida.
Esto evita un falso PASS causado por sobrescrituras silenciosas.

El runner también falla el dispositivo cuando el build para el simulador falla.
`flutter drive` no se detiene ante un error de compilación: se adjunta a la app
que ya estaba instalada y el recorrido pasa contra código viejo. El 4 de agosto
de 2026 eso produjo un `PASS 10/10` del scope `focus` sobre un binario anterior
al cambio que se quería revisar, con un DerivedData corrupto como causa. Además
de leer los errores de Xcode, el runner compara el nombre de cada captura con el
slug del dispositivo, porque ese nombre viaja por `--dart-define` y delata un
binario de otra corrida. Si aparece cualquiera de las dos señales, se reporta
FAIL y las capturas no valen como evidencia.

No se usan comparaciones pixel a pixel por default porque cambian entre
versiones de iOS, fuentes y motores de render. Si una pantalla se estabiliza,
se puede promover después a golden test con una tolerancia explícita.
