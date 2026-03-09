# Discusion con LLM: Librerias para Zentra

## Contexto del Proyecto

**Zentra** es una app de seguimiento de habitos gamificada construida con Flutter (v1.0.20), siguiendo Clean Architecture. Cuenta con 52 archivos Dart distribuidos en 4 capas:

- **Domain**: Modelos puros en Dart (Habit, HabitLog, LocalUser, UserProfile, PomodoroActivity) y contrato `HabitRepository`
- **Infrastructure**: Persistencia con SharedPreferences, notificaciones, Live Activities iOS, Siri Shortcuts, Quick Actions, Logger
- **Application**: 5 Providers con ChangeNotifier (Habits, Auth, Pomodoro, User, Theme)
- **Presentation**: 16 pantallas, 11 widgets reutilizables, tema Material 3

La app incluye sistema de autenticacion local multi-cuenta, timer Pomodoro con Live Activities de iOS, calendario, graficas de progreso, achievements, y soporte para Siri Shortcuts y 3D Touch.

### Librerias actuales (20 dependencias)

| Categoria | Librerias |
|-----------|-----------|
| Estado | provider |
| Persistencia | shared_preferences |
| Utilidades | uuid, intl, crypto |
| UI | google_fonts, confetti |
| Animaciones | flutter_animate, lottie, shimmer, animations |
| Graficas | fl_chart |
| Notificaciones | flutter_local_notifications, timezone, flutter_timezone |
| Archivos | file_picker, share_plus, path_provider |
| Dispositivo | package_info_plus, device_info_plus, url_launcher |
| Audio | audioplayers |
| Background | flutter_foreground_task |

---

## Pregunta 1: Sugerencias de librerias

> **Prompt**: Considerando la arquitectura actual de Zentra y que buscamos que la app se sienta premium, que librerias me recomendarias integrar?

### Respuesta del LLM

Se sugirieron 6 librerias organizadas por impacto:

| # | Libreria | Impacto UX | Complejidad | Proposito |
|---|----------|-----------|-------------|-----------|
| 1 | **Rive** | Muy alto | Media | Animaciones interactivas con State Machines |
| 2 | **Isar** | Alto | Alta | Base de datos NoSQL de alto rendimiento |
| 3 | **flutter_slidable** | Alto | Baja | Swipe actions nativas en tarjetas |
| 4 | **purchases_flutter** (RevenueCat) | Medio | Media | Monetizacion profesional (IAP) |
| 5 | **freezed** + json_serializable | Medio | Media | Modelos inmutables con code generation |
| 6 | **smooth_page_indicator** | Bajo-medio | Muy baja | Indicadores de pagina premium |

---

## Pregunta 2: Deep dive en Rive

> **Prompt**: Quiero saber mas sobre Rive. Que hace exactamente? Cuales son los pros y contras? Como se compara con las alternativas, especialmente con Lottie que ya tenemos?

### Que es Rive

Rive es un motor de animaciones interactivas en tiempo real. A diferencia de Lottie (que reproduce animaciones pre-renderizadas), Rive usa **State Machines** que permiten que las animaciones reaccionen al input del usuario, datos de la app, o condiciones logicas en tiempo real.

Se disena en el editor web de Rive (rive.app, gratuito) y se exporta como un archivo `.riv` ultraligero que corre nativamente en Flutter.

### Ejemplo de uso en Flutter

```dart
RiveAnimation.asset(
  'assets/animations/habit_check.riv',
  stateMachines: ['CheckStateMachine'],
  onInit: (artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard, 'CheckStateMachine'
    );
    artboard.addController(controller!);
    _isChecked = controller.findInput<bool>('isChecked') as SMIBool;
  },
)

// Al completar un habito:
_isChecked.value = true; // La animacion transiciona automaticamente
```

### Pros

| Pro | Detalle |
|-----|---------|
| Interactividad real | Animaciones responden a inputs en tiempo real, no solo play/pause |
| Archivos ultraligeros | Un .riv pesa 5-50 KB vs Lottie JSON de 200 KB+ |
| Rendimiento nativo | Renderiza en GPU, no interpreta JSON frame-by-frame |
| State Machines | Logica de animacion declarativa con estados y transiciones |
| Editor gratuito | Editor web free para uso personal/indie |
| Multi-plataforma | Mismo .riv funciona en Flutter, iOS, Android, Web, React |
| Comunidad activa | Marketplace de assets, soporte directo, documentacion solida |

### Contras

| Contra | Detalle |
|--------|---------|
| Curva de aprendizaje | Hay que aprender el editor y el concepto de State Machines |
| Requiere disenar animaciones | Menos assets gratuitos que Lottie (LottieFiles tiene miles) |
| Formato propietario | El .riv no es editable fuera de Rive |
| No reemplaza todo | Para one-shots simples (confetti), Lottie sigue siendo mas practico |
| Tamano del runtime | Agrega ~2-3 MB al binario (motor de renderizado) |

### Comparacion: Rive vs Lottie vs Alternativas

| Aspecto | Rive | Lottie | Animaciones manuales (Flutter) |
|---------|------|--------|-------------------------------|
| Interactividad | State Machines con inputs | Solo play/pause/reverse | Total pero codigo manual |
| Peso de archivo | 5-50 KB | 50-500 KB | 0 (es codigo) |
| Rendimiento | GPU nativo | Interpreta JSON | Depende de implementacion |
| Editor visual | Rive.app (gratis) | After Effects + plugin Bodymovin | No hay |
| Assets disponibles | Marketplace creciente | LottieFiles (miles gratis) | N/A |
| Curva de aprendizaje | Media | Baja | Alta |
| Logica condicional | Nativa (blend, listeners) | No tiene | Manual con AnimationController |
| Ideal para | Micro-interacciones, UI animada | Ilustraciones, loadings, iconos | Transiciones simples |

### Veredicto para Zentra

**Rive no reemplaza a Lottie, lo complementa:**

- **Mantener Lottie** para: celebraciones one-shot, loading animations, ilustraciones del onboarding
- **Agregar Rive** para: checkbox interactivo del habit card, timer visual del Pomodoro, avatar animado del perfil, transiciones entre estados (idle/completado/racha)

Este enfoque es el que usan apps premium como **Duolingo** (Rive para su mascota interactiva) y **Headspace** (animaciones reactivas en meditacion).

---

## Conclusion

Rive es la libreria con mayor impacto potencial para elevar Zentra a un nivel premium. Su capacidad de crear micro-interacciones que responden al usuario en tiempo real es lo que diferencia a las apps "bonitas" de las que se sienten verdaderamente vivas. La estrategia optima es usarla junto a Lottie, asignando cada herramienta a lo que mejor hace.

---

## Implementacion

Tras la discusion, se procedió a integrar las 6 librerias en el proyecto:

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | Agregadas las 6 dependencias + dev dependencies para code generation |
| `lib/presentation/widgets/habit_card.dart` | Reemplazo de `Dismissible` por `Slidable` con acciones de editar, archivar y eliminar |
| `lib/presentation/onboarding_screen.dart` | Reemplazo de barras de progreso manuales por `SmoothPageIndicator` con efecto ExpandingDots |
| `lib/presentation/support_screen.dart` | Integración con `PurchaseService` (RevenueCat), tips dinámicos, y botón de restaurar compras |

### Archivos creados

| Archivo | Proposito |
|---------|-----------|
| `lib/presentation/widgets/rive_checkbox.dart` | Widget de checkbox premium con Rive State Machines y fallback animado |
| `lib/presentation/widgets/rive_celebration.dart` | Overlay de celebración Rive para achievements con fallback de partículas |
| `lib/infrastructure/purchase_service.dart` | Servicio singleton de RevenueCat para tip jar con fallback local |
| `lib/infrastructure/isar_schemas.dart` | Schemas Isar para Habit, HabitLog, CompletedTask y PomodoroActivity |
| `lib/infrastructure/isar_repository.dart` | Implementación de `HabitRepository` con Isar (queries indexadas, transacciones) |
| `lib/domain/habit_freezed.dart` | Modelos inmutables con freezed: FrequencyModel, HabitModel, HabitLogModel, etc. |
| `build.yaml` | Configuración de build_runner para freezed y json_serializable |

### Pasos para activar code generation

```bash
# Generar archivos .freezed.dart, .g.dart e isar schemas
dart run build_runner build --delete-conflicting-outputs
```

### Pasos para activar RevenueCat

1. Crear cuenta en [RevenueCat](https://www.revenuecat.com)
2. Configurar productos en App Store Connect / Google Play Console
3. Reemplazar los API keys en `lib/infrastructure/purchase_service.dart`
4. Configurar entitlements y offerings en el dashboard de RevenueCat

---

*Discusion realizada con Claude (Anthropic) - Marzo 2026*
*Proyecto: Zentra - Habit Tracker Gamificado (Flutter)*
