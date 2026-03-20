# 📊 Insight

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Google ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)
[![Architecture](https://img.shields.io/badge/Clean%20Architecture-BLoC-blueviolet?style=for-the-badge)](https://bloclibrary.dev)

**Convierte tus capturas de pantalla de Mobile Legends en datos reales al instante.**

Insight es una aplicación móvil que usa OCR (Reconocimiento Óptico de Caracteres) para escanear las pantallas de estadísticas de Mobile Legends, extraer automáticamente todos los datos numéricos y construir un historial de rendimiento detallado sin necesidad de escribir nada a mano.

[¿Cómo funciona?](#-cómo-funciona) · [Estadísticas que rastrea](#-estadísticas-que-rastrea) · [Características](#-características) · [Tecnología](#-tecnología) · [Arquitectura](#-arquitectura) · [Instalación](#-instalación)

---

## 🤔 ¿Cómo funciona?

El flujo completo desde la captura hasta el historial tiene cuatro pasos:

```text
  1. CAPTURA              2. EXTRACCIÓN             3. VALIDACIÓN             4. HISTORIAL
──────────────────    ──────────────────────    ──────────────────────    ──────────────────────
Tomas una foto o  →   Google ML Kit reconoce →  StatsValidator clasifica →  La sesión queda
subes una captura     el texto y StatsParser     cada campo como crítico     guardada con sus
de tu pantalla de     lo convierte en un         u opcional y calcula un     gráficos listos
Mobile Legends        objeto PlayerStats          % de completitud           para consultar
```

### Dos modos de carga

Insight ofrece dos formas distintas de escanear tus estadísticas según cómo aparezcan en tu pantalla:

| Modo | Imágenes | Cuándo usarlo |
| --- | --- | --- |
| **Total** | 1 imagen | Cuando tienes una pantalla con el resumen general de todas tus partidas |
| **Por modos de juego** | 3 imágenes | Cuando quieres cargar por separado Clasificatoria, Clásica y Coliseo para comparar tu rendimiento en cada modalidad |

---

## 📋 Estadísticas que rastrea

Insight extrae y almacena **28 campos** por cada modo de juego escaneado, organizados en tres grupos:

### Estadísticas principales

| Campo | Descripción |
| --- | --- |
| Partidas Totales | Número total de partidas jugadas |
| Tasa de Victorias | Porcentaje de victorias (ej. `59.29%`) |
| MVP | Cantidad de veces nombrado jugador más valioso |

### Rendimiento por partida

| Campo | Descripción |
| --- | --- |
| KDA | Ratio Kills / Deaths / Assists |
| Participación en Equipo | Porcentaje de participación en peleas de equipo |
| Oro / Min | Promedio de oro generado por minuto |
| Daño a Héroe / Min | Daño promedio infligido a héroes por minuto |
| Muertes / Partida | Promedio de muertes por partida |
| Daño a Torre / Partida | Daño promedio a estructuras por partida |

### Logros y récords históricos

| Campo | Campo | Campo |
| --- | --- | --- |
| Legendario | Savage | Maniac |
| Asesinato Triple | Asesinato Doble | MVP Perdedor |
| Asesinatos Máx. | Asistencias Máx. | Racha de Victorias Máx. |
| Primera Sangre | Daño Causado Máx./min | Daño Tomado Máx./min |
| Oro Máx./min | — | — |

> Los logros como Legendario o Savage pueden ser legítimamente 0. El validador los trata como **opcionales** y no los marca como errores, a diferencia de campos críticos como el KDA o la Tasa de Victorias.

---

## ✨ Características

### 🔍 Motor de OCR con validación inteligente

El texto extraído por Google ML Kit pasa por `StatsParser`, un motor de expresiones regulares con múltiples patrones alternativos por campo para tolerar las variaciones que el OCR puede introducir (espacios extra, caracteres similares, orden alterado). A continuación, `StatsValidator` distingue entre campos **críticos** —cuya ausencia invalida el registro— y campos **opcionales** —que pueden ser cero sin problema. El resultado es un informe de completitud con porcentaje y recomendaciones específicas si algo falló ("Asegúrate de que el porcentaje de victorias esté completo en la imagen").

### 🎮 Cuatro modos de juego independientes

Cada sesión guardada puede contener estadísticas de hasta cuatro modos distintos: **Total**, **Clasificatoria**, **Clásica** y **Coliseo**. El parser detecta automáticamente el modo a partir de palabras clave en el texto reconocido (`clasificatoria`, `clásica`, `coliseo`, `todos los juegos`).

### 📊 Análisis visual por modo de juego

Cada registro del historial tiene una pantalla de gráficos con cuatro visualizaciones independientes, una por modo escaneado:

- **Gauge de Win Rate** — Medidor semicircular con código de color: verde ≥60 %, amarillo ≥50 %, rojo <50 %.
- **Barras de Rendimiento** — Comparativa normalizada de KDA, participación en equipo, tasa de muertes/partida y porcentaje de MVPs.
- **Radar de Logros** — Gráfico radial de seis ejes (Legendario, Savage, Maniac, Triple Kill, Doble Kill, Primera Sangre) con valores normalizados respecto a referencias realistas.
- **Torta de Economía** — Distribución porcentual entre Oro/min, Daño a Héroe/min y Daño a Torre/partida, con interacción al tocar cada sector.

### 📚 Historial con búsqueda, ordenamiento y paginación

El historial soporta búsqueda en tiempo real por nombre o fecha, ordenamiento ascendente/descendente por fecha o nombre alfabético, y carga paginada de 10 elementos para mantener la fluidez con grandes colecciones. La sesión más reciente tiene una tarjeta destacada al inicio de la lista.

### 💾 Gestión de datos desde Configuración

La sección **Datos** en Configuración centraliza todas las operaciones sobre el historial en tres acciones independientes, cada una con su propio bottom sheet:

- **Exportar estadísticas** — Muestra un resumen previo con el número de colecciones, la fecha del registro más reciente y el tamaño estimado del archivo antes de confirmar. Al exportar genera un `.json` y abre el menú nativo de compartir para guardarlo o enviarlo.
- **Importar estadísticas** — Permite elegir entre dos modos antes de seleccionar el archivo: *Fusionar* (agrega las colecciones del archivo sin tocar las existentes, omitiendo duplicados) o *Reemplazar* (borra el historial actual y carga únicamente el contenido del archivo). Tras una importación exitosa navega automáticamente al Historial.
- **Eliminar todo el historial** — Flujo de dos pasos: el primero muestra el número exacto de colecciones que se perderán y un consejo para exportar antes; el segundo pide confirmación final para prevenir eliminaciones accidentales.

### 🔄 Formato de exportación e importación

El archivo exportado es un `.json` con metadatos de versión y fecha (`ml_stats_YYYYMMDD_HHMMSS.json`). El formato es compatible entre dispositivos y soporta importación con dos estrategias:

- **Fusionar** — Añade las colecciones del archivo sin tocar las existentes, omitiendo duplicados por timestamp.
- **Reemplazar** — Limpia el historial actual antes de importar.

### 🏷️ Gestión del historial

Cada registro se puede renombrar con un nombre personalizado (hasta 50 caracteres) para encontrarlo fácilmente, o eliminarse individualmente con un diálogo de confirmación. Las opciones se acceden con un toque largo sobre la tarjeta.

### 🎨 Apariencia totalmente personalizable

Seis temas de color predefinidos con sus variantes clara y oscura:

| Tema | Color semilla |
| --- | --- |
| Esmeralda *(por defecto)* | `#059669` |
| Violeta | `#7C3AED` |
| Azul Océano | `#2563EB` |
| Carmesí | `#DC2626` |
| Ámbar | `#F59E0B` |
| Rosa | `#EC4899` |

El modo de tema (Claro / Oscuro / Sistema) y el tema de color se persisten entre sesiones.

---

## 🛠 Tecnología

| Librería | Versión | Rol en la app |
| --- | --- | --- |
| **Flutter / Dart** | SDK `>=3.9.2` | Framework principal de UI multiplataforma |
| **google_mlkit_text_recognition** | `^0.15.0` | Motor OCR — procesa imágenes con el script Latin |
| **flutter_bloc** | `^9.1.1` | Gestión de estado reactiva con el patrón BLoC |
| **get_it** | `^9.1.1` | Inyección de dependencias y service locator |
| **dartz** | `^0.10.1` | Tipo `Either<Failure, T>` para manejo funcional de errores |
| **shared_preferences** | `^2.5.3` | Almacenamiento local del historial serializado en JSON |
| **fl_chart** | `^1.2.0` | PieChart, BarChart, RadarChart y gráfico de gauge |
| **image_picker** | `^1.2.1` | Acceso a cámara y galería de fotos |
| **file_picker** | `^10.3.10` | Selección de archivos `.json` para importar |
| **share_plus** | `^12.0.1` | Compartir el archivo exportado con otras apps |
| **path_provider** | `^2.1.5` | Ruta de directorio para guardar archivos exportados |
| **equatable** | `^2.0.7` | Comparación estructural de objetos en BLoC |
| **intl** | `^0.20.2` | Formateo de fechas y números |
| **salomon_bottom_bar** | `^3.3.2` | Barra de navegación inferior animada |
| **awesome_snackbar_content** | `^0.1.8` | Notificaciones flotantes con estilo moderno |
| **permission_handler** | `^12.0.1` | Gestión de permisos de cámara en tiempo de ejecución |

---

## 🏗 Arquitectura

El proyecto implementa **Clean Architecture** en tres capas desacopladas, con el patrón **BLoC** como eje de gestión de estado en la presentación.

### Estructura de carpetas

```text
lib/
├── core/
│   ├── errors/
│   │   └── failures.dart               # ImagePickerFailure · TextRecognitionFailure
│   │                                   # FileSystemFailure · ParseFailure
│   ├── injection/
│   │   └── injection_container.dart    # Registro global de dependencias con GetIt
│   └── utils/
│       ├── stats_parser.dart           # Motor de extracción: regex compiladas por campo
│       └── stats_validator.dart        # Validación, clasificación y % de completitud
│
└── features/
    ├── navigation/                     # NavigationBloc — bottom nav y back stack
    ├── settings/                       # ThemeBloc · SettingsBloc · pantalla de ajustes
    │   └── presentation/
    │       └── screens/
    │           └── widgets/
    │               ├── settings_export_bottom_sheet.dart   # Exportar con resumen previo
    │               ├── settings_import_bottom_sheet.dart   # Importar con modo fusionar/reemplazar
    │               └── settings_delete_all_bottom_sheet.dart # Eliminar con confirmación en dos pasos
    └── stats/
        ├── data/
        │   ├── datasources/            # OcrDataSourceImpl · LocalStorageDataSourceImpl
        │   │                           # JsonExportDataSourceImpl
        │   ├── model/                  # OcrResultModel · StatsCollectionModel (toJson/fromJson)
        │   └── repositories/           # OcrRepositoryImpl · StatsRepositoryImpl
        ├── domain/
        │   ├── entities/               # PlayerStats · StatsCollection · GameMode
        │   │                           # OcrResult · TextBlock · TextLine · …
        │   ├── repositories/           # Contratos abstractos (interfaces)
        │   └── usecases/               # Un caso de uso por operación (SRP estricto)
        └── presentation/
            ├── bloc/                   # OcrBloc · StatsBloc
            ├── controllers/            # StatsUploadController (ChangeNotifier)
            ├── screens/                # home/ · history/ · upload/ · details/ · charts/
            ├── services/               # DialogService — notificaciones centralizadas
            ├── utils/                  # GameModeExtensions (color, icono, nombre)
            └── widgets/                # Widgets reutilizables entre pantallas
```

### Los cinco BLoCs del proyecto

| BLoC | Eventos principales | Responsabilidad |
| --- | --- | --- |
| `NavigationBloc` | `NavigationItemSelected` · `NavigateBack` · `UpdateNavigationBadge` | Índice activo del bottom nav, historial de navegación, badges |
| `SettingsBloc` | `LoadSettings` · `UpdateThemeMode` · `UpdateAutoSave` · `ResetSettings` | Persistencia de todas las preferencias del usuario |
| `ThemeBloc` | `LoadTheme` · `ChangeTheme` · `ChangeThemeMode` | Carga y cambio de tema en tiempo real, temas personalizados |
| `OcrBloc` | `ProcessImageEvent` · `CopyTextEvent` · `ResetStateEvent` | Ciclo de vida del escaneo: imagen → OCR → resultado |
| `StatsBloc` | `SaveStatsCollectionEvent` · `LoadAllStatsCollectionsEvent` · `DeleteStatsCollectionEvent` · `ExportStatsToJsonEvent` · `ImportStatsFromJsonEvent` | CRUD completo del historial más exportación/importación |

### Flujo de datos

```text
[ Widget ]  →  Event  →  [ BLoC ]  →  UseCase  →  [ Repository ]  →  DataSource
                                                          ↑
                                               Either<Failure, T>
                                           (manejo funcional sin excepciones)
[ Widget ]  ←  State  ←  [ BLoC ]  ←──────────────────────┘
```

El manejo de errores usa el tipo `Either<Failure, T>` de **dartz**. Cualquier fallo en cualquier capa sube como `Left(Failure)` sin lanzar excepciones no controladas. El BLoC convierte ese `Left` en un estado de error concreto que la UI renderiza con información útil para el usuario.

### Separación de responsabilidades entre módulos

La gestión de datos está dividida entre dos módulos con roles distintos:

- **`settings/`** — Punto de entrada visual. Los tres bottom sheets de exportar, importar y eliminar viven aquí porque son operaciones de configuración global que el usuario espera encontrar en Ajustes.
- **`stats/`** — Lógica de negocio. `StatsBloc`, los casos de uso y los repositorios permanecen intactos en este módulo. Los bottom sheets de settings los consumen directamente sin duplicar código.

---

## 🚀 Instalación

### Requisitos

- Flutter SDK `>=3.9.2` / Dart `>=3.0.0`
- Android `minSdk 21` (Android 5.0+) con Google Play Services actualizado
- iOS `10.0+`

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/insight.git
cd insight

# 2. Instalar dependencias
flutter pub get

# 3. Solo iOS — instalar pods
cd ios && pod install && cd ..

# 4. Ejecutar
flutter run
```

> **Permisos requeridos:** La app necesita acceso a la **cámara** y a la **galería de fotos** para funcionar. En Android se solicitan en tiempo de ejecución. En iOS deben estar declarados en `Info.plist` (`NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription`).

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si encuentras un bug o tienes una idea de mejora, abre un issue describiendo el problema o envía un pull request con tus cambios.

---

## 📄 Licencia

Distribuido bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---

Hecho con ❤️ para la comunidad de Mobile Legends
