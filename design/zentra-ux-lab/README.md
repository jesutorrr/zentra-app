# Zentra UX Lab

Portafolio local para comparar cinco direcciones de experiencia y diseño en
dieciocho estados reales de Zentra. Todas pertenecen a Calma precisa 3.2,
pero proponen modelos de uso distintos. El laboratorio sigue separado del
código Flutter de producción.

## Abrir

Desde la raíz del proyecto:

```bash
python3 -m http.server 8844
```

Después visita:

```text
http://127.0.0.1:8844/design/zentra-ux-lab/
```

## Qué contiene

- Guía diaria: prioriza una siguiente acción clara.
- Agenda viva: organiza hábitos, notas y enfoque alrededor del calendario.
- Progreso vivo: convierte la constancia en niveles y colecciones amables.
- Compañera Zentra: ofrece sugerencias locales, explicables y descartables.
- Estudio modular: aprovecha iPad y la futura web como espacio de trabajo.

Cada dirección se puede recorrer en iPhone e iPad por Inicio, Acceso,
Bienvenida, Hoy, Nuevo hábito, Hábitos, Notas, Editor de nota, Recordatorio,
Pomodoro, Enfoque en curso, Progreso, superficies del sistema, Calendario,
Historial, Perfil, Ajustes y Ayuda.

El laboratorio es deliberadamente interactivo. En Pomodoro se pueden cambiar
los modos, elegir presets y abrir el dial de 5 a 60 minutos. En Acceso se
pueden recorrer la entrada local, el usuario existente y la restauración. En
Bienvenida existe un flujo consolidado de cuatro pasos:

1. Promesa de producto y confianza local-first.
2. Talismán e intención inicial.
3. Primer hábito editable u omitible y vista previa de recompensa.
4. Recordatorio opcional, pre-permiso y resumen antes de entrar a Hoy.

La propia pantalla de Bienvenida permite cambiar entre primera apertura y la
ruta `Tu espacio volvió contigo` para revisar un respaldo ya restaurado. En el
último paso se pueden simular los estados `notDetermined`, `requesting`,
`granted`, `denied` y `error` sin abrir un diálogo real del sistema.
El estado `requesting` cambia de forma reproducible a `error` después de tres
segundos si no se selecciona otra respuesta. Ese timeout pertenece únicamente
al laboratorio: en producción debe prevalecer el resultado real del sistema.

Paso, ruta y permiso se reflejan en la URL. Atrás y Adelante del navegador
restauran esos estados sin reiniciar el laboratorio. Los grupos de talismán,
intención, decisión de hábito, recordatorio y permiso implementan el patrón de
radio con flechas, Home y End, además de `tabindex` móvil.

Las cinco direcciones comparten esta máquina de estados para que la comparación
no mantenga cinco implementaciones divergentes. Cada dirección cambia promesa,
lenguaje, acento visual y composición conceptual. Esta consolidación es una
decisión deliberada del laboratorio, no una limitación de la futura app.

Calma precisa 3.2 prueba:

- Acceso local-first con uso completo en el dispositivo, restauración segura y
  usuarios locales existentes. Google se comunica como capacidad futura, no
  como una acción disponible antes de que exista la integración.
- Calendario visible desde el encabezado y navegación dedicada en iPad.
- Gamificación responsable con niveles, colección, retos opcionales y color
  por categoría.
- Burbujas de categoría en el temporizador, con estado estático para Reduced
  Motion.
- Notas activas con recordatorio, vínculo a hábitos y sesión de enfoque.
- Navegación móvil con Hoy, Hábitos, Notas, Enfoque y Progreso.
- Cinco formas distintas de agregar un hábito directamente desde Hoy.
- Cinco configuradores de Enfoque donde el título y cualquier vínculo son
  opcionales, con dial de 5 a 60 minutos.
- Cinco formularios completos de hábito con las categorías reales Agua,
  Movimiento, Sueño, Foco y Varios, frecuencia, días y recordatorio.
- Composición específica para iPad, sin estirar una columna de teléfono.
- Live Activity, Dynamic Island y widgets con privacidad por defecto.
- Preferencias explícitas para Reduced Motion, audio y haptics.

Estas propuestas no son recolors. Comparten tipografía, sobriedad, tokens de
categoría y principios de accesibilidad, pero cambian la arquitectura de Hoy,
la forma de orientar al usuario y el uso del espacio.

Los scores son hipótesis de diseño, no resultados de investigación con
usuarios. Su propósito es hacer explícitos los criterios y tradeoffs antes de
convertir una propuesta en código de producción.
