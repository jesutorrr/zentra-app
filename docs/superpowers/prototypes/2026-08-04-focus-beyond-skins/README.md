# Focus beyond skins

Estado: exploracion UX/UI local. No es contrato aprobado ni implementacion Flutter.

Este corte reinicia el ejercicio anterior desde modelos de interaccion. La regla fue que cada propuesta debia conservar una silueta reconocible en monocromo, sin depender de paleta, tipografia ornamental o efectos.

## Entregables

- `concept-lab.html`: laboratorio interactivo con cinco modelos estructurales en monocromo.
- `concept-silhouettes.svg` y `concept-silhouettes.png`: comparacion determinista de las cinco siluetas.
- `portal-silence-prototype.html`: prototipo navegable de la direccion elegida.
- `portal-silence-motion-storyboard.png`: secuencia de alta fidelidad con seis keyframes.
- `concept-lab-preview.png`: captura estatica del laboratorio.
- `portal-silence-preview.png`: captura estatica del prototipo en preparacion.

## Cinco posturas

| Modelo | Objeto principal | Gesto diferenciador | Prueba de silueta |
|---|---|---|---|
| El Portal | Un circulo continuo | Se expande hasta convertirse en el espacio de enfoque. | Disco grande parcial que cambia de escala. |
| Silencio | Ausencia deliberada de UI | Un toque convoca o retira controles. | Tiempo aislado sobre campo vacio. |
| El Recorrido | Camino de cuatro estaciones | La sesion activa avanza fisicamente por el ciclo. | Eje con cuatro nodos y uno expandido. |
| Tiempo tipografico | Numeros y espacio | La pausa separa y desplaza los digitos. | Tipografia gigante sin aro. |
| Intervalo vivo | Forma organica abstracta | La forma se tensa y descansa. | Cuerpo asimetrico que cambia de volumen. |

## Direccion elegida: Portal + Silencio

El circulo no es decoracion ni una card. Es el mismo objeto funcional durante todo el flujo:

1. En preparacion contiene duracion, dial y `Entrar`.
2. Al iniciar se expande mas alla de los bordes del telefono.
3. En enfoque se convierte en el campo verde profundo y deja un trazo circular minimo.
4. En pausa el trazo abre una brecha y el punto queda suspendido.
5. En descanso la crema vuelve a entrar por esa brecha.
6. Al completar, el trazo se cierra y reduce a un sello.

La metafora de navegacion desaparece. El usuario no cambia de pagina, cruza un umbral.

## Uso del prototipo

Abrir `portal-silence-prototype.html` en un navegador. Se puede:

- tocar `Entrar` para iniciar el enfoque.
- pausar y continuar desde el CTA central.
- abrir la salida segura desde atras o terminar.
- recorrer Preparar, Enfoque, Pausa, Descanso y Cierre desde el panel lateral.
- usar las flechas izquierda y derecha del teclado.

El documento respeta `prefers-reduced-motion`.

## Validacion de este corte

- Los cinco conceptos cambian composicion, objeto y gesto. `SILHOUETTE PASS` conceptual.
- El HTML y JavaScript se parsearon localmente sin errores de sintaxis.
- Quick Look produjo capturas de ambos documentos y fueron inspeccionadas visualmente.
- No se ejecuto el Screen Reviewer de Flutter porque no existe cambio de produccion.
- `TECHNICAL PASS`, `CONTRACT PASS`, `DEVICE PASS` y `URI APPROVED` permanecen abiertos.

## ImageGen

Modo: herramienta integrada.

El storyboard final uso el preview del prototipo como referencia estructural. El prompt pidio seis keyframes de una sola experiencia: preparar, expansion del portal, enfoque, pausa con brecha, descanso con inversion a crema y cierre en forma de sello. Se prohibieron variantes de estilo, cards de timer, serif ornamental, glassmorphism, dashboards, barras duplicadas y titulos redundantes.
