# Conceptos Salvia para iPhone

Fecha: 3 de agosto de 2026

Estado: exploración visual. Estos mockups no son contrato aprobado ni evidencia de
implementación.

## Objetivo

Explorar cómo puede sentirse Zentra más minimalista y premium sin abandonar el
lenguaje Salvia existente. Las cuatro propuestas usan como referencias capturas
reales de Hoy, Notas, Enfoque y Crear hábito.

## Pantallas

1. `01-note-reading.png`: superficie única de lectura, contenido renderizado y
   acciones de recordatorio y enfoque en segundo plano visual.
2. `02-note-editing-keyboard.png`: la misma nota en edición con barra contextual
   anclada sobre el teclado.
3. `03-focus-prepare.png`: preparación de enfoque con una sola acción primaria y
   una geometría que puede transformarse en el timer.
4. `04-focus-active-amoled.png`: sesión activa AMOLED con timer inmersivo, contexto
   mínimo y sin labels repetidos.

## Decisiones que sí vale la pena conservar

- Una sola superficie para leer y editar.
- Barra de formato contextual, no permanente.
- Timer con peso tipográfico ligero y números tabulares.
- Acción primaria claramente separada de las secundarias.
- Color ambiental concentrado en el estado activo, no distribuido por toda la UI.
- Continuidad visual entre preparar y ejecutar una sesión.

## Ajustes antes de convertirlos en contrato

- El CTA de preparar enfoque debe ser sólido, sin degradado.
- El brillo del timer AMOLED debe reducirse para evitar una estética de neón.
- Los metadatos de nota deben colapsarse bajo `Detalles` según el contrato final.
- Iconos, tamaños y copy deben sustituirse por los assets y tokens reales de Zentra.
