# Notas con Markdown vivo y biblioteca legible

Spec de diseño aprobado. Cubre los proyectos A (Markdown vivo) y B (Biblioteca).
El proyecto C (pulido de iPad y accesibilidad) tiene su propio spec posterior.

- Fecha: 2026-08-03
- Estado: aprobado para escribir plan de implementación
- Alcance: `lib/domain`, `lib/presentation` de Notas. Sin cambios de esquema y
  sin trabajo de Apple Pencil.

## 1. Problema

La sección de Notas pide al usuario escribir Markdown y nunca lo renderiza.
`NoteFormatToolbar` inserta `##`, `**`, `-`, `- [ ]` y `---` en el texto, pero
`NoteDetailSurface` pinta el cuerpo con `SelectableText` plano y
`NoteLibraryCard` muestra las dos primeras líneas crudas. El usuario paga el
costo cognitivo de la sintaxis sin recibir ningún beneficio visual.

Hallazgos concretos de la auditoría de UX:

1. Sin render de formato en lectura ni en tarjetas.
2. Las casillas `- [ ]` no se pueden marcar.
3. `NoteFormatCommand.heading` inserta `## ` en la posición del cursor, sin ir
   al inicio de línea y sin togglear, produciendo Markdown inválido.
4. La barra de formato ocupa espacio permanente y en iPhone queda tapada por el
   teclado.
5. Leer y editar son dos rutas distintas, con salto de pantalla en iPad.
6. En iPhone no existe modo lectura: tocar la tarjeta abre el editor.
7. La vista previa de la tarjeta muestra marcadores crudos.
8. Las etiquetas son texto separado por comas, sin chips ni autocompletado, y
   la tarjeta solo muestra la primera.
9. No hay filtro por etiqueta, pese a estar pedido en el plan maestro 5.4.
10. `NoteSaveStatus` es `liveRegion` y cambia cada 700 ms, saturando VoiceOver.

Los puntos 1 a 9 entran en este spec. El punto 10 pertenece al proyecto C.

## 2. Decisiones de producto

- El contenido sigue siendo Markdown en texto plano. `body: String` es la única
  fuente de verdad.
- El editor es de bloque enfocado: solo el bloque donde está el cursor muestra
  la sintaxis cruda, atenuada. Los demás se ven renderizados.
- No se adopta un editor de bloques con formato propio tipo JSON o Delta. El
  plan maestro lo excluye en 5.14 y rompería Drift, el outbox de sync y los
  backups.
- No se agregan dependencias nuevas.
- Apple Pencil queda completamente fuera de este spec y se mueve a la fase
  best effort, junto con la integración de Supabase. Scribble seguirá
  funcionando por defecto porque `TextField` lo trae activado en iPad con iOS
  14 o superior, pero no es un entregable, no se verifica en hardware y no se
  comunica al usuario en esta fase.

## 3. Contrato de no pérdida de texto

Es la restricción que gobierna todo el diseño. En una app de notas, perder una
palabra destruye la confianza de forma permanente.

- `body` no cambia de formato. `formatVersion` se queda en 1.
- El parser vive en `lib/domain/markdown_document.dart`, es Dart puro y no
  importa Flutter.
- Ciclo completo idempotente, verificado por tests:
  `parse(serialize(parse(x))) == parse(x)` y `serialize(parse(x)) == x` para
  todo el corpus de prueba.
- Todo lo que el parser no reconozca se conserva en un bloque crudo que guarda
  su línea intacta y la devuelve tal cual al serializar. Tablas, imágenes, HTML
  o cualquier extensión futura no se estilizan, pero jamás se corrompen.
- Guardado forzado al cambiar de bloque, además del debounce de 700 ms ya
  existente.
- Historial de undo a nivel documento sobre el Markdown serializado, con tope
  de 50 estados, en lugar del undo interno del campo de texto.
- Modo "Editar como texto" que abre la nota entera en un campo plano. Es la
  válvula de escape para pegar documentos largos y el plan B si aparece un bug
  de bloques en producción.

## 4. Modelo de contenido

### 4.1 Bloques en alcance

| Bloque | Sintaxis | Notas |
| --- | --- | --- |
| `heading` | `#`, `##`, `###` | Niveles 1 a 3 |
| `paragraph` | texto | Bloque por defecto |
| `bulletItem` | `- `, `* ` | Se normaliza a `- ` al serializar |
| `numberedItem` | `1. ` | Renumeración automática al renderizar |
| `checkItem` | `- [ ] `, `- [x] ` | Casilla real tocable |
| `quote` | `> ` | |
| `divider` | `---` | |
| `codeFence` | tres acentos graves | Contenido literal, sin parseo inline |
| `raw` | cualquier otra cosa | Preserva la línea sin tocarla |

Fuera de alcance: tablas, imágenes, notas al pie y HTML embebido. Se preservan
como `raw`.

La indentación se soporta con tope de tres niveles y se guarda como `indent` en
el bloque. Sin esto, pegar un `.md` con listas anidadas produce un resultado
visualmente roto, y ese es un caso real.

### 4.2 Formato inline

Un tokenizador propio, con posiciones de origen, para negritas, cursivas,
código inline, tachado y enlaces. Se construye a mano por dos razones que
ninguna librería de Markdown resuelve:

1. El bloque activo y el bloque renderizado deben usar el mismo motor de
   estilos, o el texto brinca al entrar y salir de un bloque.
2. Atenuar los marcadores en su lugar exige conocer su posición exacta en el
   texto fuente, dato que los AST de Markdown no exponen.

El tokenizador produce `List<InlineSpan>` a partir de una sola función, con un
parámetro que decide si los marcadores se muestran atenuados (bloque activo) o
se ocultan (bloque renderizado).

## 5. Arquitectura del editor

- Un único `TextEditingController` y un único `FocusNode` vivos, reasignados al
  bloque activo. No un controller por bloque: con notas largas eso significa
  cientos de objetos y fugas de memoria.
- Los bloques inactivos son widgets de render puro dentro de un
  `ListView.builder`, así que una nota de mil líneas no reconstruye lo que no
  está a la vista.
- Reparseo incremental: al editar solo se reparsea el bloque tocado, salvo
  cuando la edición cambia su tipo o lo parte.

### 5.1 Comportamiento del teclado

- `Enter` parte el bloque en la posición del cursor y hereda el prefijo si el
  bloque es lista, numerada o casilla.
- `Enter` sobre un ítem de lista vacío convierte el bloque en párrafo y sale de
  la lista.
- `Backspace` al inicio de un bloque lo une con el anterior, preservando el
  contenido de ambos.
- `Tab` y `Shift+Tab` ajustan la indentación entre 0 y 3.

### 5.2 Limitación conocida y su mitigación

No habrá selección continua entre bloques mientras se edita. Se compensa con:

- Modo lectura envuelto en `SelectionArea`, con selección y copiado de corrido.
- Acción "Seleccionar todo" que copia el Markdown crudo completo.

## 6. Superficie única de lectura y escritura

Una sola `NoteSurface` con dos estados, sin cambio de ruta entre ellos.
`NoteEditorScreen` deja de existir como ruta separada; el plan de
implementación debe inventariar y actualizar a todos sus llamadores, incluidos
quick actions, notificaciones y deep links.

- iPhone: la tarjeta abre la nota en modo lectura. Tocar el cuerpo entra a
  escritura con el cursor en el bloque tocado. La barra superior cambia a un
  botón "Listo" que regresa a lectura sin salir de la nota.
- iPad: el panel derecho es la misma superficie. Se elimina el botón de lápiz.
- Nota nueva: entra directo en escritura con el cursor en el título.

Las herramientas de la nota (recordatorio, enfoque, etiquetas, acento, fijar)
pasan a un panel de detalles: hoja inferior en iPhone, columna colapsable en
iPad, cerrada por defecto mientras se escribe. Recordatorio y enfoque siguen
accesibles de un toque porque son las dos acciones que dan sentido a Notas
dentro de Zentra.

El título se mantiene como campo separado, no se fusiona con un `# H1`, porque
búsqueda, tarjetas, notificaciones y sync dependen de él. Si el usuario pega un
`.md` cuyo primer bloque es H1 y el título está vacío, aparece un banner en
línea sobre el cuerpo con dos acciones, "Usar como título" y "Descartar". Al
elegir cualquiera de las dos, el banner no vuelve a mostrarse para esa nota.

## 7. Barra de formato y casillas

### 7.1 Barra

- Aparece solo cuando el cuerpo tiene el foco.
- Anclada sobre el teclado usando `MediaQuery.viewInsets`; en iPad flota sobre
  el borde inferior del panel.
- Los botones son interruptores sobre el bloque completo, nunca inserciones en
  la posición del cursor. Esto elimina por construcción el defecto actual del
  `##` a media palabra.
- Encabezado cicla párrafo, H1, H2, H3, párrafo. Viñeta, numerada, casilla y
  cita se alternan entre sí y con párrafo. Negrita y cursiva envuelven o
  desenvuelven la selección. Separador inserta un bloque nuevo debajo.
- La barra indica qué formato tiene el bloque activo.

### 7.2 Casillas

- Widget real con área táctil mínima de 44 puntos, tocable en modo lectura y en
  los bloques inactivos.
- Al marcar: tachado, atenuación y haptic ligero, respetando la preferencia de
  haptics existente en Ajustes.
- Marcar dispara guardado inmediato, no el debounce, porque es una acción con
  intención explícita del usuario.
- Cuando la última casilla pendiente de una nota se marca, aparece una vez un
  mensaje breve en línea bajo el bloque, sin animación ni sonido, que se
  descarta solo. No otorga XP ni logros: el plan maestro 5.12 prohíbe premiar
  la creación de notas y premiar el marcado sería la misma trampa. Si el
  usuario desmarca y vuelve a marcar, el mensaje no se repite en esa sesión.

## 8. Biblioteca

- Vista previa de la tarjeta: primer bloque con contenido real, convertido a
  texto legible sin marcadores.
- Progreso de casillas en la tarjeta cuando existan, como barra fina con
  "3 de 7".
- Búsqueda: se resalta la coincidencia y el fragmento mostrado es el que la
  rodea, no el inicio de la nota.
- Etiquetas: campo de chips con autocompletado sobre las etiquetas existentes
  del usuario, aprovechando el índice `note_tag_owner_value_idx`. La tarjeta
  muestra hasta dos con un contador.
- Filtro por etiqueta desde el selector de secciones, pendiente desde el plan
  maestro 5.4.

## 9. Accesibilidad y movimiento

- Todos los objetivos táctiles nuevos cumplen 44 puntos mínimos.
- El editor respeta Dynamic Type usando el mismo umbral que ya aplica el resto
  de la app, `MediaQuery.textScalerOf(context).scale(16) > 23`: por encima de
  ese punto el panel de detalles de iPad se apila en lugar de dividirse.
- Reduced Motion desactiva la animación de transición entre lectura y
  escritura.
- Semántica: cada bloque expone su rol (encabezado nivel n, elemento de lista,
  casilla marcada o sin marcar) y las casillas anuncian el cambio de estado.

## 10. Pruebas

- Unitarias del parser: ciclo completo sobre un corpus que incluya listas
  anidadas, bloques de código con `#` dentro, casillas mixtas, separadores y
  contenido no reconocido.
- Unitarias del tokenizador inline, incluyendo marcadores sin cerrar y
  anidamiento de negrita con cursiva.
- Unitarias de transformaciones como funciones puras sobre el documento: Enter,
  Backspace, Tab, y cada toggle de la barra.
- Unitarias del undo a nivel documento.
- De widget: entrar y salir de bloque, posición del cursor, marcar casilla,
  y verificación de que el autosave escribió el Markdown esperado.
- Integración: `integration_test/screen_reviewer_test.dart` con capturas en
  iPhone e iPad, en claro, oscuro y AMOLED.
- Verificación de compilación al cerrar cada fase, según regla del proyecto:
  `flutter build ios --release --no-codesign`.
- Checkpoint de git antes de cada cambio mayor, según regla del proyecto.

## 11. Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Pérdida de texto | Bloque `raw`, ciclo completo probado, guardado al cambiar de bloque, undo por documento, modo texto plano |
| Rendimiento en notas largas | `ListView.builder`, bloques inactivos baratos, reparseo incremental |
| Salto visual al entrar a un bloque | Un solo motor de estilos inline para bloque activo y renderizado |
| Regresión en llamadores de `NoteEditorScreen` | Inventario explícito de llamadores como primera tarea del plan |

## 12. Definición de terminado

1. Una nota escrita con encabezados, listas, casillas, cita y separador se ve
   formateada en lectura, en la tarjeta y en los bloques inactivos del editor.
2. Las casillas se marcan con un toque en lectura y en bloques inactivos, y el
   cambio queda persistido en el Markdown.
3. Escribir, salir y volver a entrar a la nota no altera ni un carácter del
   contenido, incluido el contenido no reconocido.
4. En iPhone existe modo lectura y en iPad no hay salto de pantalla al editar.
5. La barra de formato solo aparece con el cuerpo enfocado, va sobre el teclado
   y sus botones son idempotentes.
6. La tarjeta muestra una vista previa legible y el progreso de casillas.
7. La búsqueda resalta coincidencias y muestra el fragmento correspondiente.
8. Las etiquetas se editan como chips con autocompletado y se puede filtrar por
   etiqueta.
9. Toda la suite de tests pasa y `flutter build ios --release --no-codesign`
   compila sin errores.

## 13. Fuera de este spec

Proyecto C, con spec propio inmediatamente posterior:

- Atajos de teclado en iPad, hover y orden de foco.
- Arreglo del `liveRegion` de `NoteSaveStatus` en VoiceOver.

Fase best effort, sin fecha, junto con la integración de Supabase que se está
separando en paralelo:

- Verificación de Scribble en un iPad físico y comunicación de la capacidad al
  usuario.
- Entrada a edición al detectar `PointerDeviceKind.stylus` sobre un bloque.
- Convivencia con los dos defectos abiertos de Flutter en el toolbar de
  selección y el teclado al usar Apple Pencil en iPad (flutter#147558 y
  flutter#160662), que no son resolubles desde la app.
- Lienzo de dibujo, que requeriría tabla nueva, migración y cambios en backup,
  sync y borrado de cuenta.

Sin planear:

- Tablas, imágenes y adjuntos.
- Selección continua entre bloques durante la edición.

## 14. Referencias

- Plan maestro, Fase 5 Notas activas, secciones 5.3, 5.4, 5.12 y 5.14:
  `docs/zentra-calma-precisa-notas-activas-plan-v2.md`.
- Alternativas de render de Markdown evaluadas y descartadas por necesitar
  posiciones de origen: https://pub.dev/packages/flutter_markdown_plus

Referencias guardadas para la fase best effort de Apple Pencil:

- `stylusHandwritingEnabled`, soporte de Scribble en Flutter:
  https://api.flutter.dev/flutter/widgets/EditableText/stylusHandwritingEnabled.html
- Defectos abiertos de Apple Pencil en iPad:
  https://github.com/flutter/flutter/issues/147558 y
  https://github.com/flutter/flutter/issues/160662
- Alternativas de lienzo: https://pub.dev/packages/pencil_kit y
  https://github.com/timcreatedit/scribble
