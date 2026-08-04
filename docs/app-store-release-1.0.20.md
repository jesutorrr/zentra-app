# Zentra 1.0.20 (24): release y ASO

Estado local al 23 de julio de 2026. Este documento prepara la entrega, pero no
confirma que el binario ya se haya subido o enviado a revisión.

## Estado externo observado

- La App Store pública todavía ofrece `1.0.19 (21)`.
- Transporter entregó correctamente `1.0.20 (23)` el 23 de julio de 2026 y
  Apple lo dejó disponible para pruebas internas.
- El build `23` no incluye el acceso visible a la política de privacidad que se
  agregó después de esa entrega. No seleccionarlo para App Review.
- El build corregido es `1.0.20 (24)`. Transporter aceptó el IPA y muestra
  `Uploading App - Analyzing package`. Todavía falta confirmar `Delivered` y
  que App Store Connect termine de procesarlo sin errores.
- No es necesario borrar el build `23`. Apple permite varios builds para una
  misma versión y permite cambiar el seleccionado hasta enviar la versión a
  revisión.

Referencias oficiales:

- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit

## Artefacto listo

- IPA: `build/ios/ipa/Zentra.ipa`
- Versión: `1.0.20`
- Build: `24`
- Bundle ID: `com.jesutorr.appzentra`
- iOS mínimo: `13.0`
- SDK de compilación: `iphoneos26.1`, Xcode `26.1.1`
- Tamaño exacto del IPA: `25,255,397 bytes`, aproximadamente `25.3 MB`
- SHA-256:
  `71cdaa7675e7d8de987dbc7e106b01995450aa5dde517bc718691128fc7e5c48`
- Firma: Cloud Managed Apple Distribution, equipo `WT47F32FNS`
- Perfil: `iOS Team Store Provisioning Profile: com.jesutorr.appzentra`
- Validación local: `flutter analyze` sin hallazgos y `68/68` tests
- Accesibilidad automatizada: 13 pantallas, tres tamaños y `39/39`
  combinaciones probadas con escalado de texto `3.2x`
- Primera instalación: registro local, onboarding completo y llegada a Hoy
  verificados mediante una prueba de flujo real
- Política de privacidad: enlace visible en `Configuración > Sobre la app`,
  probado contra la URL pública
  `https://jesutorrr.github.io/zentra-app/privacy-policy.html`
- Integridad: el ZIP interno del IPA fue probado sin errores y el log de
  empaquetado no contiene errores ni advertencias

El paquete final no contiene RevenueCat, PurchasesHybridCommon, Google Fonts,
Siri Shortcuts, ActivityKit, Live Activities, un widget ni otra extensión.
Inter se incluye localmente y no requiere descargar fuentes en tiempo de
ejecución. Siri, Live Activities y el widget quedan diferidos hasta implementar
y probar la extensión nativa completa.

## Metadata propuesta para español de México

Los valores respetan los límites actuales de App Store Connect.

- Nombre, 26 caracteres: `Zentra: Hábitos y Pomodoro`
- Subtítulo, 27 caracteres: `Rutinas, enfoque y progreso`
- Categoría primaria: `Productividad`
- Categoría secundaria sugerida: `Salud y forma física`
- Precio: gratis
- Support URL:
  `https://jesutorrr.github.io/zentra-app/support.html`
- Marketing URL opcional:
  `https://jesutorrr.github.io/zentra-app/`
- Privacy Policy URL:
  `https://jesutorrr.github.io/zentra-app/privacy-policy.html`
- Palabras clave, 93 bytes:
  `productividad,metas,racha,recordatorios,calendario,organizador,concentracion,bienestar,diario`
- Texto promocional, 167 caracteres:
  `Crea rutinas sostenibles con hábitos flexibles, recordatorios, calendario y sesiones de enfoque. Sin anuncios ni suscripciones: tus datos permanecen en tu dispositivo.`

Apple limita el nombre y subtítulo a 30 caracteres, el texto promocional a 170,
la descripción a 4000 y las palabras clave a 100 bytes:

- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information

## Descripción propuesta

Convierte tus metas en acciones pequeñas y sostenibles con Zentra.

Organiza hábitos, tareas únicas y sesiones de enfoque desde una experiencia
clara, privada y sin distracciones.

CONSTRUYE TUS RUTINAS

- Crea hábitos diarios, semanales o con días personalizados.
- Programa tareas para una fecha específica.
- Agrega recordatorios locales para mantener el ritmo.
- Consulta tu día y marca cada avance en segundos.

ENFÓCATE CON POMODORO

- Inicia sesiones de concentración y descanso.
- Organiza actividades de cuatro ciclos.
- Consulta minutos, sesiones e historial de enfoque.

MIDE TU PROGRESO

- Revisa calendario, rachas, historial y estadísticas.
- Identifica tendencias por hábito y categoría.
- Celebra avances sin convertir la productividad en presión.

PRIVACIDAD PRIMERO

- Tus perfiles, hábitos y progreso se guardan localmente.
- No usamos anuncios ni analítica de seguimiento.
- No necesitas crear una cuenta en un servidor.
- Exporta e importa respaldos manualmente cuando lo necesites.

Zentra está diseñada para ayudarte a avanzar con constancia, una acción a la
vez.

## Novedades de la versión

- Mejoramos la experiencia con tamaños de texto grandes y corregimos desbordes
  en las pantallas principales.
- Renovamos la imagen de inicio de la app.
- Mejoramos navegación, formularios, estados vacíos y Pomodoro.
- Reducimos dependencias innecesarias y reforzamos la privacidad local.
- Incluimos mejoras generales de estabilidad.

## Notas propuestas para App Review

```text
Zentra works entirely on device. The sign-up and sign-in interface creates and
reads local profiles only; it does not create a remote account.

On a clean installation:
1. Choose Create Account if the registration form is not already visible.
2. Name: App Review
3. Email: appreview@zentra.local
4. Password: Zentra23
5. Confirm the same password and continue through onboarding.

The reviewer may also use any valid-looking email and any password with at
least six characters. No email verification or external service is required.

Notifications are optional and are used only for local habit reminders and
Pomodoro alerts. Backup import/export is manual. The app contains no ads,
subscriptions, in-app purchases, analytics, or remote account service.

The privacy policy is available in Settings > Sobre la app > Política de
privacidad and at:
https://jesutorrr.github.io/zentra-app/privacy-policy.html
```

Agregar en App Store Connect el nombre, teléfono y correo reales de contacto.
Apple pide instrucciones y acceso de prueba suficientes para evitar retrasos:

- https://developer.apple.com/app-store/review/

## Historia sugerida para capturas

La ficha pública actual contiene seis capturas verticales de iPhone. Se
inspeccionaron visualmente y siguen representando funciones presentes en
`1.0.20`: Hoy, Pomodoro, progreso, perfil, configuración y celebración. Se
pueden conservar para no bloquear esta entrega.

No son todavía un set ASO fuerte: carecen de titulares que expliquen beneficios
y una captura muestra el nombre `Uriel`. Para una mejora posterior, preparar de
cinco a seis capturas limpias, sin datos personales reales:

1. `Tu día, en orden`: pantalla Hoy con hábitos claros.
2. `Rutinas que se adaptan a ti`: creación de hábito y frecuencia.
3. `Enfócate con Pomodoro`: temporizador en una actividad.
4. `Mira tu constancia`: progreso, rachas y estadísticas.
5. `Planea y revisa`: calendario e historial.
6. `Privacidad local`: ajustes y respaldo manual.

La primera captura debe explicar el beneficio principal, no solo mostrar la
interfaz. Preparar los tamaños vigentes para iPhone y iPad que solicite App
Store Connect. No reutilizar una captura estirada entre familias de dispositivo.

El IPA declara `UIDeviceFamily = [1, 2]`, por lo que corre en iPhone y iPad.
Se preparó `docs/app-store-assets/1.0.20/ipad-13/01-today.jpg` desde Zentra
`1.0.20 (24)` en un simulador iPad Pro de 13 pulgadas. Es JPEG RGB vertical de
`2064x2752`, sin canal alfa y usa únicamente datos ficticios. Antes de enviar,
abrir `View All Sizes in Media Manager`: conservar una captura heredada válida
o cargar esta imagen en la familia iPad de 13 pulgadas.

- https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

## Accesibilidad

La prueba automatizada ya cubre las 13 pantallas navegables con texto al
`3.2x` en iPhone compacto `320x568`, iPhone `390x844` e iPad `1024x1366`.
Antes de publicar la etiqueta `Larger Text`, completar manualmente en un iPhone
y un iPad estas tareas con el tamaño máximo:

- primer inicio, perfil local y onboarding;
- crear, editar, completar y eliminar un hábito;
- crear una tarea única;
- iniciar, pausar y terminar Pomodoro;
- revisar calendario, historial, progreso y ajustes;
- exportar e importar un respaldo.

Apple exige que todas las tareas comunes puedan completarse antes de declarar
la etiqueta. Todavía no declarar VoiceOver, Voice Control, contraste o Reduced
Motion sin una auditoría independiente:

- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria

## Privacidad y cumplimiento

- Mantener `Data Not Collected` solo mientras no se agreguen analítica,
  publicidad, sincronización, compras ni otros servicios que reciban datos.
- La descarga de Google Fonts y RevenueCat se eliminaron del binario de esta
  versión.
- El IPA contiene 14 privacy manifests de Apple y dependencias. Todos declaran
  `NSPrivacyTracking = false` y una lista vacía de datos recolectados.
- Siri Shortcuts y Live Activities se quitaron de las capacidades declaradas
  para esta versión porque todavía no existe una extensión funcional embebida.
- El perfil y el correo se guardan localmente. La política debe explicarlo con
  claridad, aunque Apple no lo considera recopilación por el desarrollador.
- Confirmar que Support URL muestre información de contacto real y que Privacy
  Policy URL abra directamente la política.
- Usar como Privacy Policy URL:
  `https://jesutorrr.github.io/zentra-app/privacy-policy.html`
- Usar como Support URL:
  `https://jesutorrr.github.io/zentra-app/support.html`
- GitHub Pages está configurado con el origen `main:/docs`, estado `built` y
  HTTPS forzado.
- `docs/index.html` y `docs/support.html` ya están preparados y validados
  localmente. Deben publicarse en GitHub Pages y responder con HTTP 200 antes de
  enviar la versión a App Review. La página de soporte incluye contacto real,
  preguntas frecuentes, respaldo, eliminación de datos y un enlace a la
  política de privacidad.
- Estado público comprobado el 23 de julio de 2026: la portada y la política
  responden HTTP 200; `support.html` todavía responde HTTP 404.
- Confirmar las preguntas vigentes de clasificación por edad.
- Confirmar el estado de comerciante para la Unión Europea y las regiones
  seleccionadas.
- Resolver el cuestionario de export compliance en App Store Connect. El código
  usa SHA-256 para proteger la contraseña local, pero no se agregó
  `ITSAppUsesNonExemptEncryption` porque la respuesta debe coincidir con la
  determinación mostrada por Apple y con cualquier respuesta aceptada en
  versiones anteriores.

Referencias oficiales:

- https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations

## Pasos de entrega

1. Abrir Transporter con `unbobosaurio@gmail.com`.
2. Arrastrar `build/ios/ipa/Zentra.ipa`.
3. Confirmar que Transporter muestre `1.0.20 (24)`, no el build `23`.
4. Pulsar `Deliver` y guardar el resultado completo de validación.
5. Esperar a que el build `24` termine de procesarse.
6. En App Store Connect, abrir Zentra y crear la versión iOS `1.0.20` si aún no
   existe.
7. Seleccionar exclusivamente el build `24`. No seleccionar el `23`.
8. Publicar `docs/index.html`, `docs/support.html` y la política actualizada en
   GitHub Pages. Confirmar que las tres URLs públicas respondan correctamente.
9. Agregar la localización `Español (México)` y pegar la metadata de este
   documento.
10. Conservar o cargar las capturas correctas para iPhone y confirmar en Media
   Manager la captura de iPad de 13 pulgadas. Si falta, cargar
   `docs/app-store-assets/1.0.20/ipad-13/01-today.jpg`.
11. Completar App Privacy, age rating, export compliance, disponibilidad y datos
   de App Review.
12. Elegir lanzamiento manual para revisar la ficha después de la aprobación.
13. Pulsar `Add for Review` y después `Submit for Review`.
14. Cuando Apple apruebe, revisar la ficha pública y lanzar manualmente la
    versión.

No reutilizar el IPA si su SHA-256 no coincide con el indicado arriba.
