# Capturas de App Store para Zentra 1.0.20

Respaldo obtenido el 23 de julio de 2026 desde la ficha pública de Zentra en el
CDN oficial de Apple:

https://apps.apple.com/us/app/zentra-app/id6757626299

## iPhone 6.5 pulgadas

Ruta: `iphone-6.5/`

Las seis imágenes son PNG RGB de `1242x2688` píxeles, sin canal alfa. Es una
medida aceptada por App Store Connect para la familia iPhone 6.5 pulgadas.

Orden público observado:

1. `01-progress.png`
2. `02-settings.png`
3. `03-today.png`
4. `04-pomodoro.png`
5. `05-profile.png`
6. `06-celebration.png`

Se pueden volver a cargar si App Store Connect no hereda las capturas al crear
la versión o localización. Antes de usarlas, confirmar que cada interfaz siga
representando fielmente el build que se enviará.

## iPad

Ruta: `ipad-13/`

`01-today.jpg` se generó el 23 de julio de 2026 desde Zentra `1.0.20 (24)` en
un simulador iPad Pro de 13 pulgadas. Muestra la pantalla Hoy con un perfil y
cuatro hábitos completamente ficticios. La imagen es JPEG RGB de `2064x2752`
píxeles, sin canal alfa, y cumple la medida vertical aceptada para iPad de
13 pulgadas.

El IPA declara compatibilidad con iPhone y iPad, por lo que esta captura debe
cargarse si la versión nueva no hereda una captura válida de iPad en Media
Manager.

Referencias:

- https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
