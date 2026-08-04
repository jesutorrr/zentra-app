# Plan maestro de producto y experiencia de Zentra

## Calma precisa con alma Zentra y Notas activas

**Versión:** 2.2, ejecución pantalla por pantalla  
**Fecha:** 26 de julio de 2026  
**Estado:** Gate L implementado y validado, pendiente de aprobación de Uri  
**Producto:** Zentra para iPhone, iPad y, posteriormente, Android y web  

### Registro de ejecución

El rebranding se está implementando pantalla por pantalla. En cada gate se
audita primero la experiencia actual, se rescatan sus fortalezas y sólo después
se cambia producción.

- **Gate F, Nuevo hábito:** completado. Se conservaron categoría, frecuencia,
  recordatorios, opciones avanzadas y vista previa. `flutter analyze` quedó
  limpio, la suite llegó a 355 pruebas y el Screen Reviewer pasó 25 de 25
  capturas en dos iPhone y dos iPad.
- **Gate G, Mis hábitos:** completado. Se conservaron búsqueda, filtros,
  categorías, frecuencia, racha, recordatorios, gestos secundarios,
  archivar, restaurar y list-detail. Se corrigió el overflow en landscape
  corto, la mejor racha ahora sólo considera hábitos activos y los hábitos de
  una vez muestran su fecha localizada. La suite llegó a 361 pruebas y el
  Screen Reviewer pasó 27 de 27 capturas en dos iPhone y dos iPad, incluyendo
  lista, búsqueda y archivados.
- **Gate H, Notas activas:** implementación y validación completas, pendiente
  de aprobación de producto por Uri. Se agregó persistencia local Drift,
  aislamiento por usuario, biblioteca, búsqueda, fijadas, archivadas, editor
  con guardado automático, recordatorio privado, repaso, enfoque opcional,
  integración con Hoy y Calendario, navegación desde notificación, backup v3
  y eliminación de datos. `flutter analyze` quedó limpio, 385 pruebas pasaron
  y el Screen Reviewer produjo 31 de 31 capturas en dos iPhone y dos iPad,
  124 capturas en total.
- **Gate I, Enfoque y Pomodoro:** implementación y validación completas,
  pendiente de aprobación de producto por Uri. Se conservaron la animación de
  burbujas, la configuración flexible y la relación opcional con Notas. Se
  agregaron Rápido/Ciclo, dial de 5 a 60 minutos, acción primaria fija en
  ventanas compactas, recuperación precisa por reloj real, historial con
  minutos reales e idempotencia de cierre y repaso. `flutter analyze` quedó
  limpio y 402 pruebas pasaron. El Screen Reviewer produjo 34 de 34 capturas
  en dos iPhone y dos iPad, 136 capturas en total. El ajuste final de la acción
  fija se verificó además a 320 dp con texto al 320%.
- **Gate J, Gamificación y Progreso:** implementación y validación completas,
  pendiente de aprobación de producto por Uri. Se consolidó un registro
  persistente e idempotente de actividad, XP, niveles y rachas, se amplió el
  catálogo a 51 logros verificables y se rediseñaron Progreso, Perfil y la
  colección de logros sin inventar recompensas. `flutter analyze` quedó limpio,
  411 pruebas pasaron y el Screen Reviewer produjo 35 de 35 capturas en dos
  iPhone y dos iPad, 140 capturas en total.
- **Gate K, Calendario e Historial:** implementación y validación completas,
  pendiente de aprobación de producto por Uri. Calendario ahora funciona como
  agenda operativa y usa el registro durable para conservar el progreso incluso
  cuando el detalle original ya no existe. Historial se convirtió en una línea
  de actividad durable y separa explícitamente el archivo borrable de tareas.
  En iPad Pro ambas pantallas usan list-detail simultáneo, mientras teléfonos y
  iPad mini conservan una composición apilada. `flutter analyze` quedó limpio,
  418 pruebas pasaron y el Screen Reviewer produjo 37 de 37 capturas en dos
  iPhone y dos iPad, 148 capturas en total.
- **Gate L, identidad Zentra y acompañamiento diario:** implementación y
  validación completas, pendiente de aprobación de producto por Uri. Se
  recuperaron el negro AMOLED y el color neón del Zentra original sin volver la
  aplicación monocromática, se redujeron texto y tarjetas redundantes, Enfoque
  volvió a tener pulso, ondas y partículas, y Calendario recibió una nueva
  composición compacta y list-detail. El onboarding y Ajustes ahora controlan
  por separado los recordatorios de mañana y noche, con mensajes que reflejan
  el estado real del día. Se eliminaron productos, precios y controles
  ficticios de soporte. `flutter analyze` quedó limpio, 492 pruebas pasaron y
  el Screen Reviewer produjo 46 de 46 capturas en dos iPhone y dos iPad, 184
  capturas en total. La revisión humana de las capturas aprobó jerarquía,
  contraste, densidad, color y feeling AMOLED. La evidencia está en el
  [reporte de Gate L](../build/screen-review/20260726-215937/report.md).

## 1. Resumen ejecutivo

Este plan propone evolucionar toda la experiencia de Zentra sobre la dirección
visual **Calma precisa**, conservando y fortaleciendo los elementos que ya hacen
que la aplicación tenga una identidad propia:

- Calidez personal.
- Categorías con color e iconografía propia.
- Progreso diario visible.
- Rachas, XP, niveles y logros.
- Celebraciones táctiles y visuales.
- Pomodoro integrado con la rutina.
- Lenguaje directo, respetuoso y sin vergüenza.
- Funcionamiento local, sin anuncios ni suscripciones.

La evolución no busca convertir Zentra en otra aplicación minimalista genérica.
Busca darle una gramática visual coherente, mayor claridad, más personalidad y
una sensación premium en todas las pantallas.

El plan incorpora además un nuevo módulo estratégico:

> **Notas activas:** Zentra no sólo guarda lo que una persona quiere recordar.
> Le ayuda a volver a ello en el momento correcto y convertirlo en una acción.

Con este módulo, los dominios del producto quedan conectados:

- **Hábitos:** lo que quiero repetir.
- **Notas:** lo que quiero conservar y comprender.
- **Recordatorios:** cuándo quiero volver.
- **Pomodoro:** cuándo decido actuar.
- **Progreso:** cuánto he avanzado.

## 2. Norte del producto

La experiencia completa debe cumplir esta promesa:

> En tres segundos entiendo mi día, con un toque avanzo y cada progreso se
> siente personal, cálido y merecido.

Una pantalla premium no es la que tiene más efectos. Es la que:

- Explica por sí sola qué puede hacer el usuario.
- Mantiene una jerarquía visual inequívoca.
- Responde con precisión a cada interacción.
- Usa color, movimiento y sonido sólo cuando aportan significado.
- Se siente diseñada como parte de un sistema, no como una colección de
  pantallas independientes.

## 3. Principios no negociables

Durante toda la evolución se debe proteger:

1. `Hoy` como centro emocional y funcional.
2. Los colores e iconos propios de cada categoría.
3. La separación clara entre pendientes y completados.
4. El ritual táctil al completar un hábito.
5. Las rachas, XP, niveles, progreso, logros y celebraciones.
6. El tono directo, sin castigos, vergüenza ni ánimo automático.
7. La sencillez, el funcionamiento local y la ausencia de suscripciones.
8. La personalidad del usuario mediante un avatar o talismán Zentra.
9. La capacidad de completar la acción principal con el menor número de pasos.
10. La accesibilidad y responsividad como parte del diseño, no como corrección
    posterior.

Calma precisa aporta jerarquía, aire y coherencia. Zentra aporta personalidad,
color, movimiento y juego.

### 3.1 Contrato de identidad recuperada

- En oscuro, la superficie base es negro AMOLED real. El teal neón, coral,
  ámbar y los colores de categoría viven en acciones, estados y progreso.
- Zentra no se convierte en una aplicación monocromática teal. Agua,
  Movimiento, Sueño, Enfoque y Varios conservan color reconocible.
- Una pantalla muestra primero la acción y el estado. Explicaciones, métricas y
  labels secundarios sólo aparecen si cambian una decisión.
- El fondo puede moverse lentamente y con opacidad mínima. Nunca compite con
  el contenido y respeta Reducir movimiento.
- Enfoque usa pulso, ondas y partículas como firma visual durante una sesión,
  sin comprometer precisión ni accesibilidad.
- La voz normal describe hechos: `Completaste 1 de 3. Quedan 2.` La
  felicitación se reserva para progreso verificado.
- Mañana presenta el trabajo real del día. Noche reconoce un día completo o
  dice directamente qué sigue pendiente.

## 4. Sistema visual de Calma precisa

### 4.1 Paleta

La paleta base conservará:

- Blanco cálido, ligeramente menos clínico que el blanco puro.
- Tinta casi negra para el contenido principal.
- Teal para acción, progreso y confianza.
- Durazno para recompensa y calidez.
- Mint para estados tranquilos.
- Colores de categoría refinados para convivir con el sistema.

El color tendrá tres funciones:

1. Identificar categorías.
2. Comunicar estados.
3. Celebrar progreso.

No se convertirá toda la aplicación en teal. Agua, Movimiento, Sueño, Enfoque
y Varios deben mantener una identidad visual reconocible.

### 4.2 Tipografía

Se definirá una jerarquía completa para:

- Títulos de pantalla.
- Encabezados de sección.
- Números de progreso.
- Cuerpo de texto.
- Etiquetas.
- Ayuda y estados secundarios.

La aplicación mantendrá una fuente principal altamente legible. Se evaluará un
acento tipográfico limitado para momentos editoriales o de recompensa, sin
afectar accesibilidad ni rendimiento.

### 4.3 Formas y superficies

Sólo existirán tres niveles de superficie:

1. Superficie base.
2. Tarjeta funcional.
3. Tarjeta especial o recompensa.

Se centralizarán:

- Escala de espaciado.
- Radios.
- Bordes.
- Elevaciones.
- Sombras.
- Tamaños de iconos.
- Alturas de controles.
- Estados de interacción.

Una opción de ajustes no debe competir visualmente con un nivel, un hábito o
un resumen semanal.

### 4.4 Movimiento y feedback

Las interacciones se clasificarán por intensidad:

- **Nivel 1:** navegación, selección y feedback discreto.
- **Nivel 2:** completar un hábito o iniciar una sesión.
- **Nivel 3:** día perfecto, nuevo nivel o logro desbloqueado.

Las animaciones deben:

- Mantener 60 fps en dispositivos compatibles.
- Respetar la preferencia de reducir movimiento.
- No bloquear la acción siguiente.
- Tener haptics coherentes con su importancia.
- Evitar celebraciones repetitivas que pierdan significado.

## 5. Identidad personal y talismanes Zentra

El avatar actual hace que Zentra se sienta personal, pero depende de emojis del
sistema. Para conservar la calidez sin depender de ellos se propone una
colección original de **talismanes Zentra**.

Características:

- Formas inspiradas en naturaleza, constelaciones y objetos cotidianos.
- Estética retro-futurista cálida.
- Ilustraciones vectoriales propias.
- Color personalizable.
- Apariencia consistente en iOS, Android y web.
- Variantes desbloqueables mediante logros.

La migración debe conservar el avatar anterior hasta que el usuario elija un
talismán. Ningún perfil existente debe perder identidad o datos.

## 6. Arquitectura de navegación adaptable

La navegación se determinará por el espacio disponible, nunca por el nombre
del dispositivo.

### 6.1 iPhone y ventanas compactas

- Encabezado personal.
- Herramientas esenciales visibles.
- Acciones contextuales cerca del contenido.
- Navegación secundaria sin depender de menús ocultos.
- Acceso claro a Hábitos, Notas, Enfoque, Progreso y Calendario.

### 6.2 iPad y ventanas amplias

- Navegación persistente y compacta.
- List-detail en Notas, Hábitos, Calendario e Historial.
- Paneles de apoyo cuando aporten información o acciones reales.
- Sin columnas de teléfono flotando en un lienzo vacío.

### 6.3 Split View y Slide Over

Una ventana de 320 dp en un iPad debe recibir la experiencia compacta. La
orientación y el modelo del dispositivo no deben determinar el layout.

## 7. Roadmap de pantallas y dominios

### Fase 0. Baseline y contrato de experiencia

Antes de modificar producción:

1. Conservar capturas del estado actual.
2. Documentar comportamientos que no deben perderse.
3. Definir métricas de interacción y accesibilidad.
4. Confirmar el inventario completo de pantallas.
5. Acordar la definición de terminado.

**Gate de aprobación:** ADN actual y principios no negociables aceptados.

### Fase 1. Constitución visual

Entregables:

- Paleta semántica.
- Tipografía.
- Espaciado.
- Radios, bordes y elevaciones.
- Iconografía.
- Botones, campos, chips, tarjetas y estados.
- Movimiento y haptics.
- Light y dark mode.
- Componentes de recompensa.

El sistema debe vivir en tokens y componentes compartidos. No se deben
distribuir decisiones de estilo como valores aislados en cada pantalla.

**Gate de aprobación:** catálogo de componentes aprobado en UX Lab.

### Fase 2. Talismanes e identidad

Entregables:

- Dirección artística.
- Colección inicial de talismanes.
- Selector de identidad.
- Estado bloqueado y desbloqueado.
- Migración desde avatares existentes.
- Integración con perfil, encabezado y celebraciones.

**Gate de aprobación:** un talismán debe verse consistente en registro, Hoy,
Perfil, logros y tema oscuro.

### Fase 3. Shell y navegación

Entregables:

- Navegación compacta.
- Navegación para iPad.
- Estado seleccionado compartido.
- Enrutamiento desde notificaciones.
- Acción global de creación.
- Navegación por teclado y foco para futuras plataformas.

La acción global de creación ofrecerá como mínimo:

- Nuevo hábito.
- Nueva nota.

No se ocultarán funciones primarias detrás de menús de tres puntos.

**Gate de aprobación:** todas las áreas principales deben encontrarse en un
máximo de una interacción desde Hoy.

### Fase 4. Loop diario de hábitos

#### 4.1 Hoy

Se conservará:

- Avatar o talismán.
- Saludo.
- Progreso circular.
- Pendientes y completados.
- Categorías.
- Rachas.
- Creación rápida.

Se mejorará:

- Jerarquía del encabezado.
- Densidad de navegación.
- Lectura de la meta diaria.
- Diferencia entre pendiente, completado y omitido.
- Accesibilidad del control de completado.
- Intensidad progresiva de celebraciones.
- Uso de espacio en iPad.
- Inclusión contextual de `Para repasar` cuando existan notas pendientes.

#### 4.2 Nuevo hábito

Orden propuesto:

1. Nombre e intención.
2. Categoría.
3. Frecuencia sencilla.
4. Recordatorio opcional.
5. Opciones avanzadas colapsadas.
6. Vista previa.
7. Guardar.

Crear un hábito básico debe requerir menos de 20 segundos.

#### 4.3 Mis hábitos

- Búsqueda y filtros ligeros.
- Racha y frecuencia visibles.
- Separación entre activos y archivados.
- Edición rápida.
- Gestos secundarios conservados.
- List-detail en pantallas amplias.

**Gate de aprobación:** crear, completar, editar, archivar y eliminar funciona
en todos los tamaños cubiertos por la matriz de pruebas.

### Fase 5. Notas activas

#### 5.1 Promesa

> Captura una idea y decide cuándo volver a ella.

Notas no será un bloc genérico. Cada nota puede convertirse en una intención
accionable mediante recordatorios, repaso y enfoque.

#### 5.2 Recorrido principal

Ejemplo:

1. Crear `Examen de biología`.
2. Escribir o pegar apuntes.
3. Programar `Mañana a las 7:00 p. m.`.
4. Recibir un recordatorio.
5. Abrir directamente la nota.
6. Iniciar un enfoque de 25 minutos.
7. Marcar como repasada.
8. Programar el siguiente repaso.

Flujo:

```text
Capturar nota
      |
Programar recordatorio
      |
Notificación del sistema
      |
Abrir exactamente esa nota
      |
Leer, editar o iniciar enfoque
      |
Registrar repaso y progreso
```

#### 5.3 Alcance del MVP

Cada nota tendrá:

- Título.
- Contenido de texto con formato ligero.
- Fecha de creación y edición.
- Etiquetas opcionales.
- Estado fijado o archivado.
- Color o acento discreto.
- Un recordatorio activo opcional.
- Acción `Iniciar enfoque`.
- Historial básico de repasos.

Formato ligero:

- Encabezados.
- Negritas.
- Listas.
- Listas de verificación.
- Separadores.

#### 5.4 Organización

La biblioteca incluirá:

- Para repasar.
- Fijadas.
- Recientes.
- Archivadas.
- Búsqueda.
- Filtros por etiqueta y recordatorio.

En iPad se utilizará list-detail.

#### 5.5 Integración

- `Hoy` mostrará `Para repasar` sólo cuando exista contenido relevante.
- Calendario mostrará recordatorios de notas diferenciados de hábitos.
- Pomodoro podrá iniciar una sesión asociada a una nota.
- Perfil y Progreso podrán mostrar repasos reales.
- La acción global permitirá crear una nota.

#### 5.6 Modelo de dominio

Modelo aproximado:

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

NoteReminder
- id
- noteId
- scheduledAtUtc
- timezoneId
- status
- notificationId
- snoozeCount

NoteReview
- id
- noteId
- reviewedAt
- focusActivityId
- durationMinutes
```

Se deben guardar:

- El instante programado en UTC.
- La zona horaria usada al crearlo.
- La intención local de calendario.
- El estado real de programación.

#### 5.7 Persistencia

Las notas no se almacenarán como listas JSON crecientes en
`SharedPreferences`. Se introducirá un repositorio respaldado por SQLite o una
capa local equivalente que soporte:

- Migraciones.
- Búsqueda indexada.
- Consultas por recordatorio.
- Archivo.
- Contenido largo.
- Relaciones entre nota, recordatorio y repaso.

Contratos propuestos:

```text
NoteRepository
NoteReminderRepository
NoteReviewRepository
```

La implementación concreta de la base se decidirá después de comparar
mantenimiento, migraciones, búsqueda, tamaño y soporte multiplataforma.

#### 5.8 Payloads y navegación

Los payloads de notificaciones evolucionarán hacia un formato tipado y
versionado:

```json
{
  "v": 1,
  "type": "noteReminder",
  "entityId": "note-uuid",
  "action": "open"
}
```

El router debe funcionar con la aplicación:

- Cerrada.
- En segundo plano.
- Activa.
- En login.
- En otra ruta.

Si la nota fue eliminada, se cancelará el recordatorio obsoleto y se mostrará
un estado seguro.

#### 5.9 Recordatorios

Opciones del MVP:

- Más tarde hoy.
- Mañana.
- Este fin de semana.
- Fecha y hora.
- Sin recordatorio.

Acciones desde la notificación:

- Abrir nota.
- Iniciar enfoque.
- Recordar más tarde.
- Marcar repasada.

Los permisos se solicitarán en contexto, después de crear el primer
recordatorio, nunca automáticamente al abrir la aplicación.

#### 5.10 Presupuesto de notificaciones

Se mantendrá un presupuesto central compartido:

```text
Slots del sistema
|- Recordatorios diarios
|- Hábitos
|- Pomodoro
`- Notas próximas
```

Se programarán primero los recordatorios más cercanos. Al volver a abrir la
aplicación, editar una nota o cambiar la zona horaria, se recalculará la
ventana.

En Android:

- Se comprobará el permiso de alarmas exactas.
- Si no existe, se degradará a programación inexacta.
- Se informará al usuario.
- No se declarará `USE_EXACT_ALARM` sin validar que Zentra califique bajo la
  política de Google Play.

#### 5.11 Privacidad

- Notas locales por defecto.
- Ningún contenido se envía a servidores.
- Sin analítica del texto.
- Vista previa de notificación configurable.
- Opción para ocultar contenido sensible.
- Backup e importación actualizados.
- Eliminación de cuenta borra notas, índices y recordatorios.
- Adjuntos futuros fuera de preferencias.
- Cifrado y bloqueo biométrico evaluados en una fase posterior.

Ejemplo privado de notificación:

```text
Zentra
Tienes una nota pendiente para repasar.
```

#### 5.12 Gamificación responsable

No se concederá XP sólo por crear notas.

Se premiará:

- Completar una sesión de enfoque asociada.
- Marcar una nota como repasada.
- Mantener una rutina de estudio.
- Completar un plan de repaso.

Colección propuesta:

- Primer repaso.
- Tres sesiones de estudio.
- Una semana preparando un examen.
- Cinco notas repasadas.
- Una nota revisada en tres fechas distintas.

#### 5.13 Evolución posterior

Después de validar el MVP se puede agregar un plan de repaso:

```text
Repasar:
- Mañana
- En 3 días
- En 7 días
```

Sólo se mantiene programado el siguiente recordatorio. Al completar un repaso
se agenda el siguiente.

Esto aproxima a Zentra a repetición espaciada sin convertirla inmediatamente
en una aplicación especializada como Anki.

#### 5.14 Fuera del MVP

- Sincronización en la nube.
- Edición colaborativa.
- OCR.
- Escaneo de documentos.
- PDFs y audio.
- IA para resumir.
- Flashcards automáticas.
- Múltiples recordatorios activos por nota.
- Editor comparable con Notion.

**Gate de aprobación:** una nota puede crearse, encontrarse, recordarse,
abrirse desde el sistema y convertirse en una sesión de enfoque sin perder su
estado.

#### 5.15 Resultado ejecutado en Gate H

La implementación eligió Drift sobre SQLite como fuente canónica de Notas.
`SharedPreferences` sigue almacenando datos legacy de otros dominios, pero no
contiene listas JSON crecientes de notas.

Quedó implementado:

- `Note`, `NoteReminder`, `NoteReview` y snapshots versionados de propietario.
- Tablas relacionadas, migraciones, índices, transacciones y borrado en
  cascada.
- Aislamiento estricto por usuario y búsqueda sin sensibilidad a acentos.
- Biblioteca compacta con Para repasar, Fijadas, Recientes y Archivadas.
- Selector visible sin controles escondidos en iPhone.
- List-detail 40/60 desde 800 dp cuando el contenido y el texto lo permiten.
- Editor cálido con guardado automático y formato ligero.
- Un recordatorio activo por nota, presets, fecha y hora, zona horaria y tres
  niveles de privacidad en pantalla bloqueada.
- IDs estables reservados para notas y payload JSON tipado y versionado.
- Apertura de la nota exacta desde cold, warm y hot state.
- Reprogramación de recordatorios al iniciar sesión y cambiar de zona horaria.
- Tarjeta contextual en Hoy y recordatorios diferenciados en Calendario.
- Inicio opcional de Enfoque desde una nota y registro del repaso al completar.
- Backup e importación v3, remapeo de propietario y eliminación local.
- Quick Action de sistema para crear una nota.

Se difiere deliberadamente:

- Botones interactivos dentro de la notificación.
- Métricas completas de repaso en Progreso y Perfil.
- XP, logros y planes de repetición espaciada.
- Sync, adjuntos, OCR e IA.

Esas piezas pertenecen a sus fases de sistema, gamificación o progreso. No se
forzaron dentro de Gate H para evitar duplicar lógica antes de sus respectivos
contratos.

Evidencia:

- `flutter analyze --no-pub`: sin issues.
- Suite completa: 385 pruebas aprobadas.
- Suite dirigida de Notas y recordatorios: 41 pruebas aprobadas.
- Casos responsive dedicados: 320 dp con texto al 200%, iPhone compacto e
  iPad Pro portrait a 834 dp.
- Screen Reviewer: 31 de 31 capturas por dispositivo en iPad Pro 11, iPad
  mini, iPhone 16e y iPhone 17 Pro Max.
- Reporte: `build/screen-review/gate-h-approved/report.md`.

### Fase 6. Enfoque y Pomodoro

La pantalla actual será refinada dentro de Calma precisa:

- Dial de 5 a 60 minutos.
- Enfoque rápido y ciclo completo.
- Secuencia visible de enfoques y descansos.
- Actividad recordada de forma opcional.
- Transición clara entre enfoque y descanso.
- Estado activo accesible desde Hoy.
- Sesión asociable a una nota.
- Historial con significado.
- Recompensas conectadas con XP y logros.

El temporizador debe sentirse como entrar a una habitación más silenciosa
dentro de la misma aplicación.

**Gate de aprobación:** el timer conserva precisión y estado al pasar entre
foreground, background, bloqueo y notificación.

#### 6.1 Resultado ejecutado en Gate I

Se rescató de la experiencia anterior:

- La animación de burbujas como firma visual del temporizador activo.
- La posibilidad de configurar enfoque, descanso corto y descanso largo.
- La continuidad del temporizador mediante foreground task y notificaciones.
- El historial de sesiones y su relación con las métricas de enfoque.

Quedó implementado:

- Selector explícito entre una sesión `Rápido` y un `Ciclo` de cuatro enfoques.
- Nombre de sesión y vínculo con Nota completamente opcionales.
- Dial accesible de 5 a 60 minutos, presets de 15, 25 y 45 minutos y ajuste
  fino.
- Acción de inicio siempre visible en ventanas compactas, incluso a 320 dp con
  texto al 320%. En iPad permanece dentro del panel funcional.
- Congelación de la duración de la etapa activa para que un cambio en Ajustes
  no altere una sesión ya iniciada.
- Persistencia por deadline de reloj real para recuperar una sesión corriendo
  o pausada sin perder ni inventar tiempo.
- Flujo completo de pausar, continuar, reiniciar etapa, terminar y cancelar.
- Ciclo de cuatro enfoques con descansos cortos y descanso largo final.
- Historial que suma minutos realmente registrados y tolera sesiones legacy
  incompletas.
- Registro idempotente de actividad, XP y repaso de Nota con identificador
  estable de sesión.
- Aislamiento de propietario al cambiar de usuario durante una sesión o un
  repaso pendiente.
- Semántica accesible para dial, timer, acciones y vínculo con Nota.
- Escalado de texto hasta 320%, limitando sólo la geometría interna del dial y
  el timer mientras su valor completo permanece disponible a accesibilidad.

Se difiere deliberadamente:

- Live Activities y Dynamic Island.
- Acciones interactivas desde notificaciones.
- Widgets de sistema.
- Integración completa de sesiones y repasos en Progreso, Perfil y logros.

Estas piezas dependen de los gates de sistema y gamificación. El timer actual
mantiene su fallback por foreground task y notificación.

Evidencia:

- `flutter analyze --no-pub`: sin issues.
- Suite completa: 402 pruebas aprobadas.
- Suite dirigida de provider, Drift, layouts adaptables e historial poblado:
  48 pruebas aprobadas.
- Casos críticos: 320 dp con texto al 320%, 390 dp, iPad mini e iPad Pro.
- Screen Reviewer: 34 de 34 capturas por dispositivo en iPad Pro 11, iPad
  mini, iPhone 16e y iPhone 17 Pro Max, 136 capturas en total.
- Reporte: `build/screen-review/20260726-175045/report.md`.
- La revisión humana de esas capturas detectó que el CTA quedaba bajo el
  pliegue en iPhone. La corrección posterior quedó protegida por una prueba de
  visibilidad y hit testing a 320 dp con texto al 320%.

### Fase 7. Gamificación coherente

#### 7.1 XP y niveles

- Explicar de dónde viene cada XP.
- Mostrar cuánto falta para el siguiente nivel.
- Celebrar el cambio de nivel una vez.
- Evitar números decorativos sin significado.
- Conectar hábitos, enfoque y repaso sin permitir explotación.

#### 7.2 Logros

Se auditarán los logros existentes:

- Implementar condiciones faltantes.
- No mostrar como alcanzable un logro que el motor no puede conceder.
- Agrupar por Constancia, Bienestar, Enfoque, Aprendizaje y Exploración.
- Mostrar progreso hacia los siguientes logros.
- Diseñar insignias propias.

#### 7.3 Intensidad

- Un hábito: feedback táctil y partículas discretas.
- Todos los hábitos del día: celebración completa.
- Nueva racha significativa: reconocimiento especial.
- Nuevo nivel o logro: pieza coleccionable.
- Repeticiones normales: sin interrumpir.

**Gate de aprobación:** cada recompensa corresponde a una acción verificable y
su intensidad coincide con su importancia.

### Fase 8. Progreso, Perfil, Calendario e Historial

#### 8.1 Progreso

- Conservar la tarjeta semanal volteable.
- Mejorar legibilidad y densidad.
- Mostrar acciones sugeridas.
- Adaptar a dos columnas en iPad.
- Integrar hábitos, enfoque y repasos.

#### 8.2 Perfil

- Talismán.
- Nivel.
- XP.
- Mejor racha.
- Días activos.
- Logros.
- Camino hacia la siguiente recompensa.
- Colección de Aprendizaje.

#### 8.3 Calendario

- Intensidad diaria de progreso.
- Indicadores por categoría.
- Hábitos y notas diferenciados.
- Recordatorios visibles.
- Detalle simultáneo en iPad.

#### 8.4 Historial

- Línea de tiempo.
- Filtros por tipo y categoría.
- Restauración cuando aplique.
- Resúmenes mensuales.
- Hábitos, notas y enfoque en una narrativa coherente.

**Gate de aprobación:** los datos deben ayudar a tomar una decisión, no sólo
llenar tarjetas.

### Fase 9. Acceso, onboarding, ajustes y soporte

#### 9.1 Acceso

- Formulario más corto.
- Backup secundario pero visible.
- Talismán como parte de identidad.
- Mejor balance en iPad.

#### 9.2 Onboarding

El usuario realizará acciones reales:

1. Comprender la promesa.
2. Elegir talismán.
3. Crear una primera intención.
4. Conocer la recompensa.
5. Crear un primer recordatorio si lo desea.
6. Solicitar permisos en contexto.

El permiso de recordatorios diarios configura dos momentos independientes:

- Mañana: muestra cuántos hábitos hay hoy y propone empezar por uno.
- Noche: felicita sólo cuando el día está completo. Si no, informa cuántos
  hábitos quedan.

El recordatorio particular del primer hábito sigue siendo opcional y no se
confunde con estos dos acompañamientos diarios.

#### 9.3 Ajustes y soporte

- Agrupación clara.
- Estado de permisos.
- Estado de exactitud de recordatorios.
- Privacidad de notas.
- Backup.
- Apariencia coherente.
- Sin funciones esenciales escondidas.
- Sin productos, precios o compras simuladas cuando la tienda no está
  configurada.

**Gate de aprobación:** cada permiso explica qué habilita y qué ocurre si se
rechaza.

### Fase 10. Estabilización y release

Antes de generar un build para distribución:

- Auditoría de accesibilidad.
- Matriz responsiva.
- Light y dark mode.
- Pruebas de teclado e insets.
- Pruebas de notificaciones.
- Migración de datos.
- Backup e importación.
- Rendimiento.
- Screen Reviewer completo.
- Revisión visual humana.
- Suite completa de pruebas.
- Analyzer sin problemas.

No se subirá una nueva build hasta que Uri apruebe la experiencia final.

## 8. Método de trabajo pantalla por pantalla

Cada pantalla seguirá este ciclo:

1. Diagnóstico del estado actual.
2. Mockup actualizado en UX Lab.
3. Versión iPhone e iPad.
4. Light y dark mode.
5. Explicación de decisiones.
6. Revisión y aprobación de Uri.
7. Implementación en Flutter.
8. Pruebas de interacción y accesibilidad.
9. Screen Reviewer completo una sola vez al cierre del gate.
10. Comparativa antes y después.

No se pasará a la siguiente pantalla si la anterior no está aprobada.

Las iteraciones intermedias usarán pruebas unitarias, widget tests y revisión
manual dirigida. Sólo se repetirá un dispositivo antes del cierre si una prueba
o una captura puntual revela un riesgo específico. No se ejecutará la matriz
completa después de cada ajuste.

## 9. Matriz de validación

Anchos mínimos:

- 320 dp.
- 360 dp.
- 393 dp.
- 600 dp.
- 744 dp.
- 840 dp.
- 1024 dp.

Texto:

- 100%.
- 200%.
- 320% como estrés en flujos críticos.

Temas:

- Light.
- Dark.

Estados:

- Vacío.
- Con datos.
- Contenido largo.
- Error.
- Permiso denegado.
- Teclado abierto.
- Recordatorio programado.
- Recordatorio limitado.
- Entidad eliminada.

## 10. Definición de terminado

Cada pantalla debe:

- Funcionar desde 320 dp hasta iPad completo.
- Respetar áreas seguras, teclado y home indicator.
- Tener una acción primaria inequívoca.
- Ser operable con lector de pantalla.
- Mantener objetivos táctiles de al menos 44 a 48 dp.
- Funcionar en light y dark mode.
- No presentar overflow.
- Mantener el mismo flujo mental en cada tamaño.
- Pasar analyzer, pruebas y recorrido automatizado.
- Verse intencional y consistente con el sistema.

Cada recordatorio debe:

- Programarse con ID estable.
- Cancelarse al editar o eliminar la entidad.
- Sobrevivir al cierre de la aplicación cuando el sistema lo permita.
- Reprogramarse tras reinicio y cambios relevantes.
- Manejar cambio de zona horaria y DST.
- Abrir la entidad correcta en cold, warm y hot state.
- Degradarse con transparencia si no tiene permiso exacto.

## 11. Cambios arquitectónicos previstos

### 11.1 Sistema de tema

Centralización de tokens, componentes y estados.

### 11.2 Talismanes

Nuevo modelo de identidad con migración compatible desde emoji.

### 11.3 Notas

Nuevo dominio, repositorios y base local con migraciones.

### 11.4 Recordatorios

Planificador central para hábitos, notas, Pomodoro y sistema.

### 11.5 Payloads

Formato tipado y versionado para navegación segura.

### 11.6 Logros

Motor completo con condiciones verificables.

### 11.7 Layout adaptable

Pantallas con composición real para compact, medium y expanded.

## 12. Contrato de diseño aprobado y ejecución

UX Lab definió el contrato visual inicial:

1. Constitución visual definitiva.
2. Catálogo inicial de talismanes.
3. Hoy rediseñado.
4. Nuevo hábito rediseñado.
5. Perfil rediseñado.
6. Biblioteca de Notas.
7. Editor de nota.
8. Configuración de recordatorio.
9. Nota con acción de enfoque.
10. Adaptaciones de iPhone e iPad.

Estas pantallas probaron que Calma precisa puede unir utilidad, calidez,
gamificación y Notas activas. Producción avanza ahora gate por gate, siempre
después de revisar el estado actual y rescatar las fortalezas de cada pantalla.

## 13. Decisiones consolidadas

| Tema | Decisión recomendada |
|---|---|
| Dirección visual | Calma precisa con personalidad Zentra |
| Posición de Notas | Módulo principal |
| Datos de notas | Locales por defecto |
| Editor | Texto con formato ligero |
| Recordatorios MVP | Uno activo por nota |
| Acciones | Abrir, enfocar, posponer o marcar repasada |
| Integración | Hoy, Calendario, Pomodoro, Progreso y Perfil |
| Gamificación | Premiar repaso real, no crear notas |
| Adjuntos, OCR e IA | Fuera del MVP |
| Sincronización | Decisión futura separada |
| Ejecución | UX Lab como contrato antes de cada gate Flutter |
| Release | Sólo después de aprobación y matriz completa |

## 14. Referencias técnicas

Código actual:

- [Servicio de notificaciones](../lib/infrastructure/notification_service.dart)
- [Planificador de recordatorios](../lib/infrastructure/notification_schedule_planner.dart)
- [Navegación desde notificaciones](../lib/main.dart)
- [Persistencia actual de hábitos](../lib/infrastructure/local_storage_repository.dart)
- [Dominio de Notas](../lib/domain/note_models.dart)
- [Repositorio Drift de Notas](../lib/infrastructure/drift_note_repository.dart)
- [Base local Zentra](../lib/infrastructure/database/zentra_database.dart)
- [Biblioteca de Notas](../lib/presentation/notes_screen.dart)
- [Editor de Notas](../lib/presentation/note_editor_screen.dart)

Documentación oficial:

- [Apple: solicitar permiso para notificaciones](https://developer.apple.com/documentation/UserNotifications/asking-permission-to-use-notifications)
- [Apple: programar una notificación local](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app)
- [Apple: notificaciones con acciones](https://developer.apple.com/documentation/UserNotifications/declaring-your-actionable-notification-types)
- [Android: programar alarmas](https://developer.android.com/develop/background-work/services/alarms)
- [Android: permiso de notificaciones](https://developer.android.com/develop/ui/compose/notifications/notification-permission)

## 15. Veredicto

Este plan no busca hacer que Zentra se vea como otra aplicación minimalista.
Busca quitar ruido sin quitar alma.

Notas activas no se agrega como una pantalla aislada. Completa el ciclo central
del producto:

> Capturo algo importante, Zentra me lo devuelve en el momento correcto y me
> ayuda a dedicarle atención real.

La ejecución continúa pantalla por pantalla: revisar lo que existe, rescatar lo
que hace única a Zentra, implementar el contrato aprobado y cerrar cada gate
con pruebas, evidencia visual y aprobación de Uri.
