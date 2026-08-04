# Zentra: seguridad y revamp minimalista

Estado de referencia: 3 de agosto de 2026

Este documento es el punto de retoma para el hardening de seguridad y el
revamp visual Salvia de Zentra. El hardening ya está implementado localmente.
El revamp dejó de ser una exploración: Acceso, onboarding, Hoy, Mis hábitos y
Crear/editar hábito ya usan el nuevo lenguaje. Onboarding y Crear/editar hábito
están pendientes de aprobación en Release físico; Enfoque y el resto del
producto continúan por fases. El seguimiento operativo vive en
[`zentra-salvia-screen-tracker.md`](zentra-salvia-screen-tracker.md).

## 1. Decisión de producto

Zentra seguirá siendo local-first:

- Todo el producto principal funciona sin cuenta.
- Google y Supabase están estacionados en la build vigente.
- La integración permanece aislada para volver sólo cuando la app local esté
  cerrada y pase nuevamente sus gates de seguridad, datos y dispositivo.
- Una identidad previamente vinculada se abre localmente con el mismo owner ID,
  sin borrar ni copiar su progreso.
- Un espacio local no simula seguridad con una contraseña guardada por la app.
  Su barrera es la seguridad del dispositivo.
- Los datos que salen del dispositivo deben hacerlo por una acción explícita,
  con sincronización autenticada o en un respaldo cifrado.

La dirección visual será calma, precisa y con emoción contenida. Minimalismo no
significa dejar la app vacía ni convertirla en una copia genérica. Se quitará
todo lo que repite una idea, no lo que orienta, da confianza o hace accesible la
experiencia.

## 2. Hardening implementado localmente

### Identidad local

- Se retiró el flujo de correo y contraseña local.
- `LocalUser` ya no guarda, exporta ni valida `passwordHash`.
- Al abrir una instalación anterior, los hashes SHA-256 obsoletos se ignoran y
  se reescriben fuera de `all_users` y `local_user`.
- El espacio y sus datos se conservan. El usuario vuelve a entrar con la acción
  local normal.
- Las cuentas de nube continúan bloqueadas si no existe una sesión remota
  válida.

Motivo: un hash SHA-256 local sin salt ni KDF no protege una contraseña de
ataques offline. Además, esa contraseña no era una barrera real contra alguien
con acceso al almacenamiento de la app.

### Respaldos

- Los respaldos nuevos usan AES-256-GCM.
- La clave se deriva con PBKDF2-HMAC-SHA256, salt aleatorio y 210,000
  iteraciones.
- La contraseña mínima es de 12 caracteres.
- La contraseña no se guarda y Zentra no puede recuperarla.
- El cifrado autentica el contenido. Una contraseña incorrecta o un archivo
  alterado se rechazan con el mismo mensaje.
- El tamaño máximo aceptado es 20 MB.
- Los respaldos antiguos en JSON sin cifrar siguen importándose para evitar
  pérdida de datos. No vuelven a exportarse sin cifrar.
- El contrato de respaldo subió a versión 4 y ya no contiene hashes locales.

### Nube estacionada

- `ZENTRA_CLOUD_ENABLED` está apagado por default y se evalúa antes de leer la
  configuración de Supabase.
- La app no inicializa Supabase, no restaura OAuth, no abre Realtime y no llama
  RPC ni Edge Functions en el modo vigente.
- Las cuentas que estuvieron vinculadas conservan su owner ID y se convierten
  en espacios locales. La marca del proveedor anterior queda sólo como metadata
  local de reactivación.
- La sesión segura remota se elimina del dispositivo. Los datos del espacio no.
- Los vínculos y operaciones pendientes permanecen congelados para auditoría y
  una futura reactivación, pero las escrituras actuales no crean outbox.
- `Eliminar espacio de este dispositivo` borra sólo el espacio local. La
  eliminación remota queda fuera del producto hasta reactivar la nube.

### Logs

- Correos, UUID, Bearer tokens, JWT y query strings se redactan antes de entrar
  al buffer.
- Los errores y stack traces completos sólo se agregan en debug.
- El panel para exportar logs sólo aparece en debug.
- Los logs de hábitos, sesiones y Live Activities dejaron de imprimir nombres
  o identificadores creados por el usuario.

### Notificaciones y pantalla bloqueada

- Recordatorios de hábitos y resúmenes diarios usan texto genérico.
- Las notificaciones de enfoque no incluyen el nombre de la actividad.
- El servicio foreground de Android usa visibilidad privada.
- Los recordatorios de notas comienzan en modo oculto por defecto. El usuario
  todavía puede elegir mostrar título o contenido.
- Dynamic Island y Live Activity conservan el temporizador con una etiqueta
  genérica de sesión.

### Backend

- Las tablas públicas mantienen RLS por `auth.uid()`.
- Escrituras sincronizadas pasan por RPC versionadas.
- `anon` no puede usar las RPC privadas.
- No hay service role key, secreto OAuth ni clave privada en Flutter, assets o
  documentos.
- El bootstrap rechaza claves `sb_secret_` y JWT con rol `service_role` antes
  de inicializar Supabase.
- Android desactiva el backup de la app y no permite migrar la sesión segura
  mediante backup.

## 3. Gates de la etapa local-only

Antes de aprobar esta etapa:

1. Verificar que una cuenta antes vinculada abre hábitos, notas, progreso y
   sesiones con el mismo owner ID.
2. Confirmar que Acceso no muestra Google ni Apple.
3. Confirmar que Ajustes no permite vincular, cerrar o eliminar una cuenta
   remota.
4. Probar `Salir de este espacio` y volver a abrirlo localmente.
5. Probar `Eliminar espacio de este dispositivo` sólo con un respaldo de prueba.
6. Forzar un error de preparación y confirmar que `Volver al acceso` funciona.
7. Ejecutar el scope incremental del Screen Reviewer y una Release física.
8. Publicar la política actualizada antes de distribuir esta build.

No ejecutar migraciones, despliegues de Edge Functions ni pruebas destructivas
contra el proyecto remoto durante esta etapa.

Para producción:

- Separar los proyectos y credenciales de dev y producción.
- Publicar Google OAuth fuera de modo prueba cuando corresponda.
- Verificar la ficha App Privacy de App Store Connect contra la política real.
- Responder de nuevo el cuestionario de export compliance. El respaldo ahora
  usa AES desde una librería incluida en la app. No agregar
  `ITSAppUsesNonExemptEncryption = false` sin clasificar primero este uso en App
  Store Connect.
- Agregar una ruta web para solicitar eliminación fuera de la app.
- Evaluar Universal Links cuando exista un dominio y archivo AASA controlados.
- Probar restauración cifrada y eliminación en un iPhone físico en release.

## 4. Riesgo residual aceptado

- La base local no usa SQLCipher. En iOS depende del sandbox y Data Protection.
  Antes de sumar cifrado de base, se debe medir compatibilidad con Drift,
  migración y recuperación. No se agregará una capa criptográfica improvisada.
- Una Live Activity necesariamente muestra estado en superficies del sistema.
  Se mantiene contenido genérico. Un futuro ajuste puede permitir desactivarla
  por completo.
- Un respaldo legado sin cifrar sigue siendo legible. La compatibilidad es
  temporal y debe revisarse después de una release estable.
- Dependencias con versiones nuevas disponibles no implican una vulnerabilidad.
  Los upgrades mayores se harán por lotes con pruebas, no como barrido.

## 5. Norte visual Salvia

Nombre interno: Salvia. Descripción útil, no nombre de una moda: minimalismo
plano, suave y silencioso. La interfaz usa tipografía, espacio, color de acento
y estado para construir jerarquía. La elevación, los bordes y el copy sólo
aparecen cuando agregan significado.

Salvia no debe copiar la apariencia completa de iOS ni de Material 3. Apple y
Material se usan como guardrails de comportamiento, accesibilidad y estados;
la identidad visual sigue siendo Zentra. Esta separación evita que un cambio
de tendencia del sistema obligue a rediseñar el producto entero.

Reglas no negociables:

1. Una acción primaria clara por contexto.
2. Una superficie por agrupación real. Nada de card dentro de card.
3. El estado no depende sólo del color: icono, texto, forma o selección lo
   confirman.
4. El vacío se usa para respirar, no para esconder información necesaria.
5. Dark no es light invertido. AMOLED usa negro real y superficies apenas
   elevadas por contraste tonal.
6. Tablet recompone el contenido. No estira un teléfono.
7. La personalidad vive en ritmo, copy breve, iconografía y movimiento
   contenido, no en decoración constante.

## 6. Estado real del revamp

### Implementado y validado

- Splash Salvia conserva el logo oficial de Zentra.
- Acceso local-first prioriza `Usar en este dispositivo` y mantiene
  restauración. Google y Apple no aparecen mientras la nube está estacionada.
- Onboarding se redujo a una sola superficie `2 / 2`: `Tu primer hábito`.
- Se retiraron talismán, intención y la confirmación posterior a restaurar.
  Restaurar entra directamente a Hoy.
- Las categorías son píldoras ajustadas al contenido y usan un punto de acento
  al inicio.
- Los recordatorios de mañana y noche se informan como listos. El permiso del
  sistema sólo se solicita al tocar `Comenzar en Zentra`.
- Negar notificaciones ya no detiene el onboarding. Hoy muestra una sola tarjeta
  descartable con acceso a Ajustes.
- Hoy Salvia compacta fecha, saludo, nivel y progreso, conserva la navegación
  visible y mantiene acciones de enfoque y hábito.
- Mis hábitos Salvia usa una biblioteca calmada con activos, pausados, búsqueda,
  filtros y CTA persistente.
- Onboarding usa una columna centrada y acotada en iPhone, iPad mini e iPad
  Pro. Crear/editar hábito usa el mismo principio y elimina la preview lateral.

### Evidencia de este corte

- 616 pruebas Flutter pasaron y 5 integraciones remotas se omitieron por no
  tener variables de Supabase en la corrida local.
- `flutter analyze` terminó sin issues.
- El scope `onboarding` produjo 6 capturas por dispositivo y `habit-form`
  produjo 8 en iPhone 16e, iPhone 17 Pro Max, iPad mini e iPad Pro.
- El PASS técnico no sustituye la aprobación estética de Uri.

## 7. Sistema visual que debe consolidarse

### Tokens, no colores sueltos

Cada color nuevo debe tener un rol semántico y variantes light, AMOLED y de
contraste aumentado:

- `canvas`: fondo principal.
- `surface`: agrupaciones interactivas.
- `surfaceSelected`: selección persistente.
- `primary` y `onPrimary`: acción principal y su contenido.
- `muted` y `onMuted`: información secundaria legible.
- `hairline`: separación de 0.5 a 1 punto.
- `danger` y `onDanger`: sólo errores y acciones destructivas.
- acentos de categoría: agua, movimiento, sueño, enfoque y varios.

Nunca usar un acento como única señal de selección. El check, radio, borde o
label también debe cambiar. La guía de [color de Apple](https://developer.apple.com/design/human-interface-guidelines/color)
y los [estados de Material 3](https://m3.material.io/foundations/interaction/states/overview)
se toman como referencia de comportamiento, no como skin.

### Tipografía

- Títulos fuertes, copy secundario corto y line-height generoso.
- Números del timer tabulares para evitar que los dígitos bailen.
- Timer entre 76 y 96 puntos según viewport, peso 200 a 300 y tracking negativo
  moderado.
- Las fuentes deben vivir en assets. No se descargan en runtime.
- Los formularios conservan labels persistentes. Un placeholder no reemplaza
  un nombre accesible.

### Forma, espacio y elevación

- Padding horizontal base de 24 a 28 puntos en teléfono.
- Escala de espaciado: 4, 8, 12, 16, 24, 32 y 48.
- Radio grande para grupos principales y píldoras; radio pequeño para controles
  compactos. Evitar un radio distinto por widget.
- Sombras sólo para CTA flotante, sheet o transición de plano. En AMOLED se
  prefiere contraste tonal a glow permanente.
- Separar con espacio o hairline antes de envolver en otra card.

### Acciones y estados

- Un botón ancho para la acción primaria.
- Secundarias como texto o iconos circulares cuando el significado sea claro.
- Estados mínimos: enabled, pressed, selected, focused, loading y disabled.
- Objetivo táctil de 44 puntos en iOS y 48 dp como baseline de Flutter.
- Todo icono sin label visible conserva `Semantics`, tooltip y acción anunciada.

Flutter recomienda objetivos de al menos 48 por 48 y contraste suficiente en su
[guía de UI accesible](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling).
Zentra debe cumplir el mayor objetivo práctico sin romper la composición.

## 8. Movimiento y tacto

La animación Salvia debe explicar estado y continuidad. No existe para mantener
la pantalla ocupada.

Tokens propuestos:

- feedback: 120 a 180 ms.
- transición de componente: 220 a 320 ms.
- cambio inmersivo de estado: 500 a 650 ms con `easeOutCubic`.
- respiración ambiental: lenta, de amplitud mínima y sólo en superficies de
  enfoque.

Reglas:

- Ninguna animación bloquea una acción.
- El progreso del timer avanza continuo, no a brincos de un segundo.
- `Reduce Motion` apaga respiración, escala, parallax, blur animado y partículas.
  Una transición funcional se reemplaza por fade, highlight o cambio de color.
- Háptico ligero al seleccionar duración, medio al pausar o reanudar y marcado
  al completar. Nunca vibrar en cada tick.
- Sonido y háptico complementan el estado, nunca son el único canal.

Apple distingue entre movimiento decorativo que puede detenerse y movimiento
funcional que debe conservar significado con una alternativa menos agresiva en
sus [criterios de Reduced Motion](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria).

## 9. Auditoría minimalista por pantalla

### Acceso, onboarding, Hoy, Mis hábitos y Crear/editar hábito

Estos cuatro bloques ya tienen dirección Salvia. No se rediseñan de nuevo en
cada pase. Sólo reciben correcciones de lógica, accesibilidad, responsive o una
decisión explícita de Uri. Su revisión incremental usa scopes del Screen
Reviewer y la matriz completa se reserva para cerrar el gate.

### Enfoque

Quitar o combinar:

- El segundo label `ENFOQUE` cuando el header ya establece el contexto.
- La card exterior del timer y la card separada de sesión.
- Conteo textual y barras cuando expresan exactamente el mismo avance.
- Labels visibles de Reiniciar y Terminar si los iconos son inequívocos y su
  semántica es completa.

Conservar:

- Tiempo restante, etapa, sesión actual y qué sigue.
- Pausar o reanudar como única acción primaria con texto.
- Atrás siempre visible. Con sesión activa debe ofrecer conservarla o cancelarla.
- Historial como acción secundaria.

Dirección aprobada: Inmersión. Enfoque usa verde profundo; descanso usa crema.
La jerarquía final es `reiniciar circular | pausar ancho | terminar circular`.

### Notas

- Mantener título, cuerpo y estado de guardado.
- Reducir metadata que no cambia una decisión.
- Separar fijar, archivar, recordatorio y borrar por riesgo y frecuencia.
- El editor no debe vivir dentro de varias cards.
- Recordatorios privados por default y copy explícito al mostrar contenido.

### Calendario y progreso

- Un resumen principal por pantalla.
- No duplicar el mismo dato en anillo, porcentaje, copy y badge.
- El calendario necesita leyenda sólo si el color no se entiende por contexto.
- Logros conservan nombre y criterio; el brillo no reemplaza la explicación.
- Empty states cortos con una acción real.

### Perfil y Ajustes

- Headers de sección y divisores en lugar de card por fila.
- Switches actúan directamente y no llevan chevron.
- Exportar, restaurar, cerrar sesión y eliminar cuenta conservan labels
  explícitos y confirmaciones completas.
- Diagnóstico y exportación de logs continúan sólo en debug.
- Seguridad no se minimaliza ocultando consecuencias.

## 10. Rediseño del dial de enfoque

Problema actual: 5 minutos es el mínimo matemático, pero el indicador se ve como
progreso cero. El usuario puede interpretar que el dial está roto.

Solución propuesta:

- Cambiar de anillo de progreso a perilla de selección.
- Arco de 300 grados con abertura inferior.
- 5 en el extremo inicial y 60 en el final.
- Marcas mayores en 5, 15, 30, 45 y 60.
- En 5 minutos se dibuja un segmento mínimo visible, nunca un track vacío.
- El handle sigue el dedo y hace snap cada 5 minutos.
- `HapticFeedback.selectionClick()` en cada snap, no durante el arrastre libre.
- Centro con duración y CTA `Iniciar 5 min`.
- Presets 5, 15, 25 y 45 como alternativa rápida.
- Semántica de slider con valor, mínimo, máximo y acciones Increase/Decrease.
- Flechas y teclado cuando la plataforma los exponga.

## 11. Orden de ejecución actualizado

### Gate S0. Base Salvia, cerrado para este corte

- Splash y Acceso.
- Onboarding de una pantalla y excepción de permisos en Hoy.
- Hoy.
- Mis hábitos.
- Scopes visuales incrementalmente verificados.

### Gate S1. Crear/editar hábito

1. Llevar `Se repite` y `Una sola vez` al primer nivel del formulario.
2. Aplanar identidad, categorías, programación y recordatorio en una sola
   composición.
3. Conservar creación, edición, eliminación, permisos y scheduling actuales.
4. Evitar scroll en el flujo normal y mantener fallback accesible.
5. Cerrar con el scope `habit-form` descrito en el tracker Salvia.

### Gate S2. Enfoque

1. Corregir dial y bug de reinicio desde notificación.
2. Agregar salida segura y cancelación de sesión.
3. Implementar Inmersión para enfoque y descanso.
4. Unificar timer, progreso y tres controles.
5. Verificar background, force quit, notificación, Live Activity y Dynamic
   Island.
6. Cerrar con iPhone físico en release.

### Gate S3. Notas, Calendario y Progreso

1. Auditar una pantalla a la vez.
2. Eliminar duplicación visual sin reducir contexto.
3. Conectar cada logro a un evento real antes de diseñar celebración.
4. Crear scope de Screen Reviewer para cada bloque cambiado.

### Gate S4. Perfil, Ajustes y sistema compartido

1. Consolidar tokens de color, radio, espacio, estados y movimiento.
2. Sustituir variantes locales sólo después de comparar el closest sibling.
3. Aplanar Ajustes sin ocultar acciones de seguridad.
4. Revisar textos y traducciones con tamaños grandes.

### Gate S5. Cierre visual y release

1. Screen Reviewer completo.
2. Matriz de accesibilidad y rendimiento.
3. Prueba release en iPhone físico y iPad.
4. Aprobación estética de Uri.
5. Sólo después, congelar paleta y promover pantallas estables a golden tests.

## 12. Matriz de validación Salvia

Cada pantalla modificada debe cubrir:

- light y AMOLED.
- teléfono compacto y teléfono grande.
- iPad mini y iPad Pro, incluidos cambios de composición.
- texto al 200 por ciento; CTA crítico también a 320 dp y 320 por ciento.
- VoiceOver o TalkBack con orden, labels, valores y acciones.
- Reduce Motion.
- contraste aumentado y escala de grises para estados que usan color.
- enabled, pressed, selected, loading, disabled y error cuando apliquen.
- scroll, teclado, background y retorno.

Para animaciones, perfilar en dispositivo real y revisar frames lentos con la
[vista Performance de Flutter DevTools](https://docs.flutter.dev/tools/devtools/performance).
Presupuesto orientativo: 16.7 ms por frame a 60 Hz y 8.3 ms a 120 Hz.

## 13. Criterio de terminado

El revamp no termina porque compile ni porque una captura se vea limpia:

- Cada fase pasa por dos revisiones independientes, contraste de hallazgos y
  una síntesis verificada contra código, pruebas y capturas.
- Ninguna acción crítica queda fuera del viewport o sin hit target.
- Ninguna pantalla desborda con texto grande.
- El estado se entiende sin depender sólo de color, movimiento o sonido.
- Reduce Motion se respeta.
- La sesión de enfoque sobrevive background, bloqueo, force quit y retorno.
- Dynamic Island, notificación y Flutter muestran la misma sesión.
- Terminar desde notificación no reinicia en cero.
- Atrás y cancelar no dejan servicios ni avisos huérfanos.
- El Screen Reviewer completo pasa en la matriz requerida.
- Uri aprueba el resultado estético en un iPhone físico release.

El acuerdo de revisores no marca una fase como terminada. La fase sólo cambia a
`Completada` en el tracker Salvia cuando Joy verifica la evidencia y Uri confirma
el resultado.

## 14. Fuentes oficiales usadas como guardrails

- [Apple Human Interface Guidelines: Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Apple Human Interface Guidelines: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Apple Human Interface Guidelines: Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Apple: Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
- [Apple Human Interface Guidelines: Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Apple Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Material 3: Interaction states](https://m3.material.io/foundations/interaction/states/overview)
- [Flutter: UI design and accessibility](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)
- [Flutter DevTools: Performance view](https://docs.flutter.dev/tools/devtools/performance)

## 15. Primer paso al retomar

Cerrar el gate conjunto de onboarding y Crear/editar hábito con dos revisiones
independientes, Release en el iPhone físico de Uri y su aprobación explícita.
Después, avanzar a Enfoque sin volver a rediseñar superficies ya aprobadas.
