# ML Stats OCR - Mobile Legends Statistics Tracker

## 📱 Descripción
ML Stats OCR es una aplicación Flutter que utiliza OCR (Reconocimiento Óptico de Caracteres) para extraer automáticamente las estadísticas de Mobile Legends desde capturas de pantalla, permitiendo a los jugadores hacer un seguimiento de su historial de rendimiento.

## 🏗️ Arquitectura
El proyecto utiliza **Clean Architecture** con el patrón **BLoC** para la gestión de estados:

- **Capa de Presentación**: UI con Flutter y BLoC para la gestión de estados
- **Capa de Dominio**: Entidades, casos de uso y contratos de repositorios
- **Capa de Datos**: Implementaciones de repositorios y fuentes de datos

## 📋 Requisitos Previos

### Software Necesario
- Flutter SDK: 3.0.0 o superior
- Dart SDK: 3.0.0 o superior
- Android Studio / VS Code con extensiones de Flutter
- Xcode (solo para desarrollo iOS en macOS)

### Configuración del Entorno

#### 1. Instalar Flutter
```bash
# Verificar si Flutter está instalado
flutter --version

# Si no está instalado, seguir las instrucciones en:
# https://flutter.dev/docs/get-started/install
```

#### 2. Verificar la instalación
```bash
flutter doctor
```
Asegúrate de que todos los checkmarks estén en verde ✓

## 🚀 Configuración del Proyecto

### 1. Clonar o crear el proyecto
```bash
# Crear un nuevo proyecto Flutter (si no existe)
flutter create insight
cd insight

# O clonar desde tu repositorio
git clone <tu-repositorio>
cd insight
```

### 2. Reemplazar los archivos
Copia todos los archivos proporcionados en sus respectivas ubicaciones según la estructura del proyecto.

### 3. Estructura de Carpetas
```
insight/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   ├── injection/
│   │   │   └── injection_container.dart
│   │   └── utils/
│   │       └── stats_parser.dart
│   └── stats/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── local_storage_datasource.dart
│       │   │   └── ocr_datasource.dart
│       │   ├── models/
│       │   │   ├── ocr_result_model.dart
│       │   │   └── stats_collection_model.dart
│       │   └── repositories/
│       │       ├── ocr_repository_impl.dart
│       │       └── stats_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── game_mode.dart
│       │   │   ├── image_source_type.dart
│       │   │   ├── ocr_result.dart
│       │   │   ├── player_stats.dart
│       │   │   ├── stats_collection.dart
│       │   │   ├── stats_upload_type.dart
│       │   │   ├── text_block.dart
│       │   │   └── text_line.dart
│       │   ├── repositories/
│       │   │   ├── ocr_repository.dart
│       │   │   └── stats_repository.dart
│       │   └── usecases/
│       │       ├── copy_text_to_clipboard.dart
│       │       ├── get_all_stats_collections.dart
│       │       ├── get_latest_stats_collection.dart
│       │       ├── pick_image_and_recognize_text.dart
│       │       ├── save_stats_collection.dart
│       │       └── usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── ml_stats_bloc.dart
│           │   ├── ml_stats_event.dart
│           │   ├── ml_stats_state.dart
│           │   ├── ocr_bloc.dart
│           │   ├── ocr_event.dart
│           │   └── ocr_state.dart
│           └── pages/
│               ├── home_screen.dart
│               ├── stats_detail_screen.dart
│               ├── stats_history_screen.dart
│               ├── stats_upload_screen.dart
│               └── widgets/
│                   ├── image_upload_card.dart
│                   ├── quick_stats_overview.dart
│                   ├── stats_summary_card.dart
│                   └── stats_verification_widget.dart
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── ios/
│   └── Runner/
│       └── Info.plist
└── pubspec.yaml
```

### 4. Instalar Dependencias
```bash
# Limpiar cualquier caché previo
flutter clean

# Obtener las dependencias
flutter pub get
```

### 5. Configuración Específica de Plataforma

#### Android
1. Abrir `android/app/build.gradle`
2. Asegurarse de que `minSdkVersion` sea al menos 21:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

#### iOS (solo en macOS)
```bash
cd ios
pod install
cd ..
```

## 📱 Ejecutar la Aplicación

### En un Emulador/Simulador
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# O especificar un dispositivo
flutter run -d <device_id>
```

### En un Dispositivo Físico

#### Android
1. Habilitar "Opciones de desarrollador" en tu dispositivo
2. Activar "Depuración USB"
3. Conectar el dispositivo por USB
4. Ejecutar: `flutter run`

#### iOS
1. Conectar el iPhone a tu Mac
2. Confiar en el ordenador desde el dispositivo
3. Ejecutar: `flutter run`

### Compilar APK (Android)
```bash
# APK de debug
flutter build apk --debug

# APK de release
flutter build apk --release

# El APK se encontrará en: build/app/outputs/flutter-apk/
```

### Compilar para iOS
```bash
# Solo en macOS
flutter build ios --release
```

## 🧪 Modo de Desarrollo

### Hot Reload
Mientras la app está ejecutándose, puedes usar:
- `r` - Hot reload (cambios rápidos)
- `R` - Hot restart (reinicio completo)
- `q` - Salir

### Logs y Debugging
```bash
# Ver logs en tiempo real
flutter logs

# Ejecutar con más información de debug
flutter run --verbose
```

## 🎮 Uso de la Aplicación

1. **Pantalla Principal**:
    - Selecciona cómo cargar las estadísticas (Total o Por Modos)
    - Accede al historial de estadísticas guardadas

2. **Cargar Estadísticas**:
    - Toma una foto o selecciona desde galería
    - La app extraerá automáticamente los datos
    - Verifica y guarda las estadísticas

3. **Historial**:
    - Visualiza todas las estadísticas guardadas
    - Accede a los detalles de cada colección

## 🔧 Solución de Problemas Comunes

### Error: "No devices available"
```bash
# Verificar que ADB detecta el dispositivo (Android)
adb devices

# Reiniciar el servidor ADB si es necesario
adb kill-server
adb start-server
```

### Error de Dependencias
```bash
# Limpiar y reinstalar
flutter clean
flutter pub cache clean
flutter pub get
```

### Error de ML Kit
Asegúrate de que tu dispositivo tenga Google Play Services actualizado (Android) o iOS 10.0+ (iPhone).

### Error de Permisos
- Android: Ve a Configuración > Apps > ML Stats OCR > Permisos
- iOS: Ve a Configuración > ML Stats OCR > Permitir acceso a Cámara/Fotos

## 📝 Notas Adicionales

- La aplicación guarda los datos localmente usando SharedPreferences
- El OCR funciona mejor con capturas de pantalla de alta calidad
- Asegúrate de que las estadísticas sean visibles y legibles en la imagen

## 🤝 Soporte

Si encuentras algún problema durante la configuración, verifica:
1. Que todos los archivos estén en su ubicación correcta
2. Que las dependencias estén instaladas correctamente
3. Que los permisos estén configurados en el dispositivo

---

**¡Listo para ejecutar!** 🚀

Ejecuta `flutter run` y disfruta de tu aplicación ML Stats OCR.
