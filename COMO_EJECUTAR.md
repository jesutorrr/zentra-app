# 🚀 Cómo Ejecutar la App - Guía Paso a Paso

## ✅ Estado Actual
- ✅ Proyecto creado y configurado correctamente
- ✅ VS Code detectado en tu sistema
- ⚠️ Flutter SDK no encontrado en PATH de terminal

## 📱 Opción 1: Ejecutar desde VS Code (RECOMENDADO)

### Paso 1: Instalar la extensión de Flutter en VS Code
1. Abre VS Code (ya abierto en tu proyecto)
2. Ve a Extensions (⇧⌘X o Cmd+Shift+X)
3. Busca **"Flutter"** 
4. Instala la extensión oficial de **Dart-Code.flutter**
5. Esto también instalará la extensión de **Dart** automáticamente

### Paso 2: Seleccionar un dispositivo
1. En la barra de estado inferior de VS Code, verás **"No Device"**
2. Haz clic en **"No Device"**
3. Selecciona un dispositivo:
   - **Chrome (web)** - Más rápido para probar
   - **iOS Simulator** - Si tienes Xcode instalado
   - **Android Emulator** - Si tienes Android Studio

### Paso 3: Ejecutar la app
Opción A - Atajo de teclado:
- Presiona **F5** o **Fn + F5**

Opción B - Menú:
- Ve a **Run > Start Debugging**

Opción C - Botón:
- Haz clic en el botón ▶️ de **"Run and Debug"** en el panel izquierdo

### Paso 4: Ver la app funcionando
- La app se compilará (puede tomar 1-2 minutos la primera vez)
- Se abrirá en el dispositivo seleccionado
- ¡Listo para probar! 🎉

---

## 📱 Opción 2: Instalar Flutter SDK (Si quieres usar terminal)

### Para macOS:

```bash
# 1. Descarga Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# 2. Añade Flutter al PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# 3. Verifica la instalación
flutter doctor

# 4. Acepta licencias de Android (si usas Android)
flutter doctor --android-licenses

# 5. Vuelve al proyecto y ejecuta
cd /Users/jesutorr/Documents/001CodigosCursos/03ConFlutter
flutter pub get
flutter run
```

---

## 🔧 Solución de Problemas

### Error: "No devices found"
**Para Web (Chrome):**
```bash
flutter channel stable
flutter upgrade
flutter config --enable-web
```

**Para iOS Simulator:**
```bash
# Abre el simulador
open -a Simulator

# Luego ejecuta
flutter run
```

**Para Android:**
- Abre Android Studio
- Ve a Tools > Device Manager
- Crea o inicia un emulador
- Luego ejecuta `flutter run`

### Error: "Flutter SDK not found"
1. Instala Flutter siguiendo: https://docs.flutter.dev/get-started/install/macos
2. O usa VS Code con la extensión de Flutter (Opción 1)

---

## 🎯 Una vez ejecutando, prueba lo siguiente:

### Test Básico:
1. ✅ Verás pantalla vacía: "¡Comienza tu viaje!"
2. ✅ Toca "Crear Primer Hábito"
3. ✅ Crea un hábito: "Beber agua" - Categoría: Agua - Frecuencia: Todos los días
4. ✅ Toca el hábito para marcarlo como completado
5. ✅ La barra de progreso debe mostrar 100%

### Test de Frecuencia:
1. Crea un hábito solo para "Entre semana"
2. Si hoy es fin de semana, NO debería aparecer
3. Si hoy es lunes-viernes, SÍ debe aparecer

### Test de Persistencia:
1. Crea varios hábitos
2. Cierra la app completamente
3. Vuelve a abrirla
4. Los hábitos deben seguir ahí

---

## 💡 Consejo Rápido

**La forma MÁS RÁPIDA de probar:**
1. En VS Code, presiona **Cmd+Shift+P**
2. Escribe: **"Flutter: Launch Emulator"**
3. Selecciona **"Chrome"**
4. Presiona **F5** para ejecutar

**Tiempo estimado: 2-3 minutos** ⚡

---

## 📞 ¿Necesitas ayuda?

Si tienes algún error específico, avísame y te ayudo a resolverlo.

La app está 100% lista para ejecutarse. Solo necesitas configurar el entorno de desarrollo.
