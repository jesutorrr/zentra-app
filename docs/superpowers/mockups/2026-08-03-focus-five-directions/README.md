# Focus: cinco direcciones visuales

Estado: exploracion visual. Ninguna direccion esta aprobada ni autoriza cambios en produccion.

Este paquete compara cinco sistemas visuales coherentes a traves de nueve estados reales del flujo Pomodoro. Cada tablero contiene cinco propuestas A-E para la misma pantalla. En total hay 45 propuestas.

## Direcciones

| Clave | Nombre | Idea central | Riesgo a vigilar |
|---|---|---|---|
| A | Salvia Editorial | Hueso calido, tinta, espacio, filetes finos y acentos pequenos. | Puede sentirse demasiado sobria si no se anima con tacto. |
| B | Bosque Inmersivo | Verde profundo para foco y crema/salvia clara para descanso. | El setup no debe convertirse en una gran tarjeta oscura. |
| C | Aurora Ludica | Coral, durazno, lavanda y teal controlados sobre fondos calidos. | Puede perder serenidad si todos los acentos compiten. |
| D | AMOLED Luminoso | Negro real, aro ultrafino menta y digitos tabulares. | El brillo debe ser puntual para evitar estetica gamer. |
| E | Ritual Solar | Pergamino, teal y ambar/coral con geometria orbital. | Los motivos solares deben seguir siendo funcionales. |

## Inventario cubierto

| # | Estado | Problema actual que resuelve el concepto | Contrato propuesto | Movimiento clave |
|---|---|---|---|---|
| 01 | Preparar rapido | Cabecera y contenedores duplican contexto. | Hero editorial, selector compacto, dial protagonista y un CTA. | El aro se dibuja al entrar y el CTA responde al snap. |
| 02 | Preparar ciclo | La informacion puede convertirse en tablero de tarjetas. | Un solo diagrama circular con cuatro enfoques y descansos. | Los cuatro nodos aparecen en secuencia. |
| 03 | Ajustar duracion | El selector debe explicar 5-60 sin otra barra. | Dial de 300 grados, marcas 5/15/30/45/60 y presets. | Snap cada cinco minutos con microescala y haptico. |
| 04 | Enfoque activo | Titulo, sesion, barra y aro repiten la misma historia. | Aro unico, `ENFOQUE · 1 DE 4`, tiempo, siguiente estado y controles. | El setup colapsa hacia el circulo y entra la paleta profunda. |
| 05 | Enfoque pausado | El overlay gris comunica bloqueo, no una pausa elegida. | Mismo espacio preservado, aro abierto y CTA Continuar. | El punto se detiene y el aro abre una respiracion. |
| 06 | Descanso corto | El flujo real no tenia exploracion visual equivalente. | Inversion a crema, `DESCANSO · 1 DE 4` y siguiente enfoque. | Transicion cromatica verde profundo a crema, sin corte brusco. |
| 07 | Enfoque completado | El cierre funcional puede sentirse generico. | Cierre del aro, 25 min, narrativa breve y celebracion contenida. | El aro se cierra, un bloom corto y un haptico satisfactorio. |
| 08 | Historial | El estado vacio actual no muestra la experiencia con datos. | Numero semanal, ritmo de siete dias y lista reciente, sin dashboard. | Barras o puntos crecen una sola vez al abrir. |
| 09 | Terminar antes | El alert centrado rompe la inmersion y enfatiza Terminar. | Hoja inferior, consecuencia exacta y accion segura dominante. | La hoja nace de los controles y conserva el timer al fondo. |

## Archivos

- `01-preparar-rapido-five-directions.png`
- `02-preparar-ciclo-five-directions.png`
- `03-ajustar-duracion-five-directions.png`
- `04-enfoque-activo-five-directions.png`
- `05-enfoque-pausado-five-directions.png`
- `06-descanso-corto-five-directions.png`
- `07-enfoque-completado-five-directions.png`
- `08-historial-five-directions.png`
- `09-terminar-antes-five-directions.png`

## Recomendacion inicial

La base mas fuerte es B, Bosque Inmersivo, combinada con la disciplina tipografica y espacial de A. E es la mejor alternativa si se quiere una personalidad mas calida y distintiva. C funciona mejor como fuente de microacentos que como sistema completo. D conviene conservarlo como opcion de modo oscuro, no como identidad unica de Focus.

La transicion firma deberia ser una sola secuencia continua: el dial del setup crece hasta convertirse en el aro activo, el fondo entra a verde profundo, la pausa abre una pequena brecha en el aro, el descanso invierte la paleta a crema y el cierre completa el circulo. La interfaz se mueve porque cambia el estado, no para decorar.

## Notas de fidelidad

- Los tableros son exploracion raster generada con ImageGen integrado y referencias de capturas reales del proyecto.
- La composicion, jerarquia, paleta y movimiento propuesto son direccionales. La tipografia raster no fija la fuente final.
- La decision elegida debe convertirse despues en especificacion medible y validarse en la app real con Screen Reviewer.
- Fuentes funcionales consultadas: `lib/presentation/pomodoro_screen.dart`, `lib/presentation/pomodoro_history_screen.dart`, `lib/application/pomodoro_provider.dart`, `integration_test/screen_reviewer_test.dart` y `docs/zentra-security-and-minimal-revamp-plan.md`.
