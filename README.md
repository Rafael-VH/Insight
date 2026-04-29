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
Tomas una foto o  →   Google ML Kit reconoce →  MLBBValidator clasifica →  La sesión queda
subes una captura     el texto y MLBBParser      cada campo como crítico     guardada con sus
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

---

## ✨ Características

### 🔍 Motor de OCR con validación inteligente

El texto extraído por Google ML Kit pasa por `MLBBParser`, un motor de expresiones regulares con múltiples patrones alternativos por campo para tolerar las variaciones que el OCR puede introducir. A continuación, `MLBBValidator` distingue entre campos **críticos** y campos **opcionales**. El resultado es un informe de completitud con porcentaje y recomendaciones específicas.

### 🎮 Cuatro modos de juego independientes

Cada sesión guardada puede contener estadísticas de hasta cuatro modos distintos: **Total**, **Clasificatoria**, **Clásica** y **Coliseo**. El parser detecta automáticamente el modo a partir de palabras clave en el texto reconocido.

### 🛡️ Enciclopedia de Héroes

Nueva sección que permite consultar la lista completa de héroes de Mobile Legends, con detalles específicos integrados. Los datos se obtienen de forma remota y se almacenan en caché localmente para un acceso rápido y sin conexión.

### 📊 Análisis visual por modo de juego

Gráficos interactivos con cuatro visualizaciones independientes por modo:

- **Gauge de Win Rate** (Verde/Amarillo/Rojo).
- **Barras de Rendimiento** (KDA, participación, etc.).
- **Radar de Logros** (Legendario, Savage, etc.).
- **Torta de Economía** (Oro, Daño a héroes, Daño a torres).

### 📚 Historial con búsqueda y paginación

El historial soporta búsqueda en tiempo real, ordenamiento por fecha o nombre, y carga paginada para mantener la fluidez.

### 💾 Gestión de datos y Configuración

Centraliza operaciones de exportación/importación en formato `.json` y eliminación masiva con confirmación en dos pasos.

### 🎨 Apariencia y Navegación

- **Navigation Drawer**: Menú lateral organizado por secciones (General, Enciclopedia, App) para facilitar el acceso a las 7 destinos actuales.
- **Seis temas de color**: Esmeralda, Violeta, Azul Océano, Carmesí, Ámbar y Rosa, con soporte para modo oscuro.

---

## 🛠 Tecnología

| Librería | Versión | Rol en la app |
| --- | --- | --- |
| **Flutter / Dart** | SDK `>=3.10.3` | Framework principal de UI multiplataforma |
| **google_mlkit_text_recognition** | `^0.15.1` | Motor OCR — procesa imágenes |
| **flutter_bloc** | `^9.1.1` | Gestión de estado reactiva |
| **get_it** | `^9.2.1` | Inyección de dependencias |
| **http** | `^1.2.0` | Cliente para peticiones remotas (Héroes) |
| **shared_preferences** | `^2.5.4` | Almacenamiento local persistente |
| **fl_chart** | `^1.2.0` | Visualización de datos y gráficos |
| **image_picker** | `^1.2.1` | Acceso a cámara y galería |
| **file_picker** | `^10.3.10` | Selección de archivos JSON |
| **share_plus** | `^12.0.1` | Compartir archivos exportados |
| **equatable** | `^2.0.8` | Comparación estructural de objetos |

---

## 🏗 Arquitectura

El proyecto implementa **Clean Architecture** dividida en módulos funcionales (`features`).

### Estructura de carpetas

```text
lib/
├── core/
│   ├── errors/
│   │   └── app_failures.dart           # Fallos específicos de la aplicación
│   ├── injection/
│   │   └── injection_container.dart    # Registro central de GetIt
│   └── presentation/                   # Elementos visuales transversales (Splash)
│
└── features/
    ├── navigation/                     # Gestión de NavigationDrawer y flujo de la app
    ├── parser/                         # MLBBParser y MLBBValidator (Motor de lógica)
    ├── ocr/                            # Integración con Google ML Kit
    ├── upload/                         # Flujo inicial de carga y procesamiento post-OCR
    ├── history/                        # CRUD de sesiones guardadas y persistencia
    ├── heroes/                         # Enciclopedia de héroes (Data, Domain, Presentation)
    ├── settings/                       # Preferencias, temas y gestión de datos
    └── academy/ items/ insights/       # Módulos en desarrollo (Placeholders)
```

### BLoCs Principales

- `NavigationBloc`: Gestiona las 7 rutas del menú lateral y badges.
- `HistoryBloc`: CRUD completo y persistencia del historial.
- `UploadBloc`: Orquestación del flujo de guardado post-OCR.
- `OcrBloc`: Ciclo de vida del procesamiento de imágenes.
- `HeroBloc`: Gestión de datos de héroes (remoto + caché).
- `SettingsBloc` & `ThemeBloc`: Configuración global y apariencia.

---

## 🚀 Instalación

### Requisitos

- Flutter SDK `>=3.10.3`
- Android `minSdk 21`
- iOS `10.0+`

### Pasos

```bash
flutter pub get
flutter run
```

---

## 📄 Licencia

Distribuido bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---

Hecho con ❤️ para la comunidad de Mobile Legends
