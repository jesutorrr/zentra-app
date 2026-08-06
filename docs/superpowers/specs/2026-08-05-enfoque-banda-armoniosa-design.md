# Enfoque: la banda se presenta y la fila de abajo se ordena

**Fecha:** 5 de agosto de 2026
**Pantalla:** Preparar enfoque (`lib/presentation/pomodoro_screen.dart`, `_FocusLauncher`)
**Estado:** implementado y aprobado por el usuario para producción

## El encargo

El usuario pidió cuatro cosas sobre el lanzador de Enfoque: mover o reemplazar el
titular «Una sola cosa», poner el nombre de la pantalla en la banda que ya lleva
«Rápido / Ciclo», acomodar mejor el historial y la configuración de duración, y
fusionar el chip «Otro» con los ajustes de Pomodoro donde se eligen los tiempos de
descanso, «así podemos deshacernos de un botón extra». La restricción que ya regía
se mantiene: todo en una pantalla, sin scroll, a cualquier tamaño.

## El diagnóstico, con números

Antes de tocar nada, tres medidas.

**Había dos puertas a la misma conversación, en esquinas opuestas.** Un ⚙ en la
banda abría los descansos del ciclo; un chip «Otro» al final de la fila de
duraciones abría un dial de minutos. Los dos hablan de tiempos. Y en Ciclo la
pantalla mostraba «4 enfoques · descansos de 5 y 15 min»: una leyenda que decía
exactamente lo que el usuario querría tocar, y que no se podía tocar.

**La fila de duraciones era cinco cosas y sólo cabían cuatro.** Cuatro números y
un «Otro» que no es un número, repartiéndose el ancho. Medido: los chips salían
entre 45.3 y 56.0 dp según el ancho de pantalla, y el dígito del chip
seleccionado se aplastaba a 0.0 dp — el «25» quedaba debajo del palomeado.

**Y el hallazgo que nadie había visto: el lanzador YA desbordaba en modo Ciclo.**
`maxScrollExtent` de 10.8 dp en 360×640 y 46.0 dp en 320×568, confirmado tocando
«Ciclo» como lo haría el usuario. La prueba oficial de «cabe en una pantalla sin
scroll» nunca lo vio porque sólo medía el modo por defecto, Rápido. El modo alto
—el que crece con la línea de los descansos— era justo el que no se medía.

## Las tres decisiones del usuario

1. **«Enfoque» fijo en la banda, y se va «Una sola cosa».** El titular poético no
   se movió a otro lado: se eliminó. Decía menos sobre dónde estás que el nombre
   del lugar, y costaba una línea que Ciclo no tenía para dar.
2. **La hoja de tiempos se adapta al modo.** Sólo el dial en Rápido; dial más los
   dos sliders de descanso en Ciclo.
3. **El historial es un ⟲ solo, a la derecha de la banda.** La banda se lee
   `‹ Enfoque … ⟲`, espejo del `‹ Nuevo hábito … ⋯` del formulario.

## El diseño

**La banda se presenta.** `_FocusTopBar` pasó de `‹ … ⚙ ⟲` a `‹ Enfoque … ⟲`. El
título vive dentro de la fila de 48 dp que ya existía, así que nombrar la pantalla
no le costó altura a nada. El ⚙ desapareció: bajó a la fila que habla de tiempos.

**El resumen ES el control.** `_FocusTimesRow` es un `TextButton` de 48 dp de alto
que en Ciclo dice «4 enfoques · descansos de X y Y min» y en Rápido «Otra
duración», con `⚙`→`Icons.tune_rounded` a la izquierda y un `›` a la derecha. La
misma fila, un propósito, y lo que ofrece depende de lo que haya que ajustar.

**Los cuatro números recuperan su ancho.** Sin «Otro» en la fila, cada chip pasó
de ~16% a 25% del ancho: medidos, 56.0 dp con 28.0 dp de dígitos en los cinco
tamaños, sin colapsar al seleccionarse.

**`_PortalIntro` se fue entero.** Con él se fue la columna izquierda del layout de
tablet: el marco pasó de `maxWidth: 1040` a `560` y el portal se centra solo, en
teléfono y en tablet, en lugar de quedar pegado a un costado con un hueco enfrente.

**El dial fino sigue existiendo.** `_DurationDialSheet` ya no se alcanza desde la
fila de duraciones, pero sí desde «Ajustar», que el portal ofrece cuando el texto
va a 200% y la barra accesible se lleva el «Entrar». Es la única puerta que le
queda a quien más la necesita, así que tiene prueba propia.

## El defecto del dial que el usuario encontró

Con el rediseño en el simulador, el usuario reportó: «el 5 inicia donde debería
ser cero, luego el 15 y así no están donde debería estar». Tenía razón, y eran dos
causas.

**El piso de progreso.** El pintor arrancaba en `0.045` para que 5 minutos no se
viera vacío. Ese piso dejaba el pulgar 13.5° adelante de la marca del 5.

**El arco medía de 5 a 60.** Con ese rango las marcas `5, 15, 30, 45, 60` caían en
0 / 18.2 / 45.5 / 72.7 / 100% del recorrido: el 30 descentrado, y el 5 pegado al
origen — de ahí que se leyera como un cero cuyo indicador ya había avanzado.
Además eran cinco números separados por 10, 15, 15 y 15 minutos: sobre un arco
parejo, saltos desparejos.

**La corrección.** El arco mide **de 0 a 60**, aunque sólo se pueda elegir de 5 a
60. Contra ese rango las marcas `15, 30, 45, 60` caen en cuartos exactos, el 30
queda justo arriba (3π/2), y 5 minutos pinta 8.3% por su propia cuenta: el piso
artificial ya no hace falta.

**Y la causa de fondo:** la fórmula vivía copiada en tres lugares —el pintor del
arco, el gesto del portal y la hoja de «otra duración»— y las tres tenían que
estar de acuerdo para que el pulgar cayera sobre su marca. No lo estaban. Ahora
`lib/presentation/widgets/focus_dial_geometry.dart` es la única fuente, así que el
desacuerdo deja de ser posible.

## Cómo se verifica

**El desborde de Ciclo no puede volver a esconderse.** La prueba de no-scroll
mide ahora **los dos modos** en los cinco tamaños, cambiando de modo tocando
«Ciclo» —no llamando al controlador—, que es la única forma de medir lo que el
usuario ve. Probada por mutación: subir la fila de tiempos a 96 dp falla con
`320x568 Rápido: 36.0`; subirla sólo en Ciclo a 108 dp falla con
`360x640 Ciclo: 8.8` después de que Rápido pasó en los cinco tamaños. Las dos
ramas miden por su cuenta.

**El dial se interroga en el lienzo real.** `test/widget/focus_dial_painter_test.dart`
usa un `_RecordingCanvas implements Canvas` que captura `drawArc` y `drawCircle`,
así que pregunta dónde quedó el pulgar en vez de confiar en la aritmética de la
prueba. Probada por mutación: reinsertar el piso `0.045` falla con
`Expected: within <0.000001> of <0.4363...> Actual: <0.2356...>`; devolver el `5` a
las marcas falla con `Expected: within <0.001> of <0.25> Actual: <0.0833...>`.

**La geometría se prueba contra dos caminos independientes.** En
`test/unit/focus_dial_geometry_test.dart` el ángulo que da la geometría se compara
contra el que sale de la proporción cruda `minutos/60`. La primera versión de esa
prueba era `expect(angleFor(m), angleFor(m))` —tautológica, no probaba nada— y se
reescribió.

**Números finales:** `maxScrollExtent == 0` en Rápido **y** Ciclo en 430×932,
393×852, 375×667, 360×640 y 320×568. Holgura: 132 / 101.5 / 49.4 / 41.6 / 22.0 dp.
El 320×568 en Ciclo pasó de −46 dp a +22 dp. `flutter analyze` limpio; 1046
pruebas en verde.

## Lo que no cambia

- La estructura `SliverLayoutBuilder` + `ConstrainedBox`: mide el layout real en
  vez del intrínseco, que es lo que evitaba el desborde del `AnimatedSize`.
- La banda llega al borde físico superior, con el inset consumido dentro del color.
- Los 48 dp mínimos de toque en todo.
- La privacidad de las notificaciones: los tres métodos de Pomodoro siguen sin
  usar el nombre de la actividad, y la Live Activity conserva su etiqueta
  genérica. Nada de este rediseño toca esa ruta.
