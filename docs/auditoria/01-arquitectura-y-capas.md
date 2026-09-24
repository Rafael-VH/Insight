# 01 — Arquitectura y capas (Clean Architecture feature-first)

**Contexto.** `GEMINI.md` declara Clean Architecture feature-first con capas `domain`/`data`/`presentation`. Se auditó el cumplimiento real leyendo los 127 archivos de `lib/`, los 8 archivos de `core/injection/` y `main.dart`.

**Intención de diseño observada.** Cada feature debería ser independiente: `presentation → domain ← data`, con entidades, repositorio abstracto en `domain`, implementación y datasources en `data`, y composición vía GetIt.

---

## Mapa de features

| Feature | domain | data | presentation | Cumple | Observación |
| --- | --- | --- | --- | --- | --- |
| `ocr` | ✅ 4 entities, repo, 1 usecase | ✅ datasource + model + repo impl | ✅ bloc | Sí | `domain` usa `dart:ui` |
| `history` | ⚠️ entidad re-export, repo, 6 usecases | ✅ repo impl (carpeta `models/` vacía) | ✅ bloc + screens | Parcial | Entidad es un re-export de `upload` |
| `settings` | ⚠️ 2 entities (con Flutter), 2 repos, 9 usecases | ✅ 2 datasources + 2 repos impl | ✅ 2 blocs + screens | Parcial | **9 usecases huérfanos**; entities con Flutter |
| `upload` | ⚠️ 2 entities, 1 usecase (sin repo propio) | ⚠️ 2 datasources + 1 model (sin repo) | ✅ bloc + controller | No | Depende del repo de `history`; doble patrón de estado |
| `insights` | ❌ | ❌ | ✅ solo presentation | No | Feature solo-UI |
| `navigation` | ⚠️ 1 entity (con Flutter) | ❌ | ✅ bloc + screens | No | `domain` con fuga de framework |
| `parser` | ✅ 2 entities (con serialización) | ❌ | ⚠️ solo `utils/` | No | Lógica de negocio fuera de capas |

---

## Hallazgos

### 🔴 Crítica

#### H-01 · `core` depende de `features` (inversión de la regla de dependencia)
- **Ubicación:** `lib/core/presentation/splash/splash_screen.dart:3,5,6`; `lib/core/services/dialog_service.dart:3`; `lib/core/usecases/base_usecase.dart:3`; `lib/core/usecases/copy_to_clipboard.dart:4`
- **Evidencia:**
  - `splash_screen.dart:3` importa `features/navigation/presentation/screens/main_screen.dart`; `:5-6` importan `features/settings/presentation/bloc/theme/theme_bloc.dart` y `theme_state.dart`.
  - `dialog_service.dart:3` importa `features/insights/presentation/widgets/session_confirm_dialog.dart`.
  - `base_usecase.dart:3` importa `features/ocr/domain/entities/ocr_image_source.dart` (define `ImageSourceParams` ligado a OCR).
  - `copy_to_clipboard.dart:4` importa `features/ocr/domain/repositories/ocr_repository.dart`.
- **Impacto:** `core` deja de ser transversal; se crea un ciclo lógico core⇄features y se rompe la regla en ambos sentidos. `core` no es testeable ni reutilizable sin las features.
- **Recomendación:** mover `SplashScreen` a `lib/features/splash/presentation/` (o `lib/app/`); mover `CopyToClipboard` e `ImageSourceParams` a `features/ocr/`; en `dialog_service.dart`, invertir la dependencia (callbacks/parámetros) o mover los diálogos genéricos a `core` sin referenciar `insights`.

#### H-02 · Dependencia circular `upload` ⇄ `history`
- **Ubicación:** `lib/features/upload/domain/usecases/save_game_session.dart:3` ↔ `lib/features/history/domain/usecases/{save_collections_batch,import_stats_from_json,get_latest_stats_collection,get_all_stats_collections,export_stats_to_json}.dart:4`
- **Evidencia:** `upload` importa `history/domain/repositories/history_repository.dart`; `history/*` importa `upload/domain/entities/game_session.dart`; y `history/domain/repositories/history_repository.dart:3` usa esa misma entidad.
- **Impacto:** acoplamiento bidireccional; ninguna feature puede evolucionar aislada.
- **Recomendación:** designar dueño único de `StatsCollection` (moverlo a `lib/core/` o a `history`) y que `upload` lo consuma. Eliminar el usecase `SaveGameSession` de `upload` (ya envuelve `HistoryRepository`) o dar a `history` un contrato sin dependencia de `upload`.

### 🟠 Alta

#### H-03 · Fugas de framework en `domain`
- **Ubicación:** `navigation/domain/entities/navigation_item.dart:1`; `settings/domain/entities/app_theme.dart:1`; `settings/domain/entities/app_settings.dart:1`; `ocr/domain/entities/text_block.dart:1`; `ocr/domain/entities/text_line.dart:1`
- **Evidencia:** los tres primeros importan `package:flutter/material.dart`. `navigation_item.dart:14` declara `final Widget page;` y usa `IconData`/`Color`; `app_settings.dart:3-6,10,12` define el enum `AppThemeMode` con `Icons` y expone `ThemeMode get flutterThemeMode`; `text_block.dart`/`text_line.dart` importan `dart:ui` por `Rect`.
- **Impacto:** `domain` atado al framework (no testeable en Dart puro). `NavigationItem` es un modelo de UI disfrazado de entidad.
- **Recomendación:** mover `NavigationItem` a `navigation/presentation/models/`; sustituir `Icons` por identificadores y llevar `flutterThemeMode` a un mapper de presentation; reemplazar `Rect` por un tipo propio en OCR.

#### H-04 · 7 archivos de inyección vacíos + contenedor monolítico
- **Ubicación:** `lib/core/injection/{parser,settings,upload,ocr,navigation,insights,history}_injection.dart` (0 bytes) y `injection_container.dart` (≈206 líneas)
- **Impacto:** archivos muertos que sugieren modularidad inexistente; el contenedor mezcla todas las features.
- **Recomendación:** implementar `initXxxInjection(sl)` por feature y dejar el contenedor como compositor, **o** eliminar los 7 archivos vacíos si se mantiene el contenedor único.

#### H-05 · 9 use cases de `settings` huérfanos
- **Ubicación:** `lib/core/injection/injection_container.dart:115-123`; definiciones en `lib/features/settings/domain/usecases/*`
- **Evidencia:** `GetSettings, SaveSettings, ResetSettings, UpdateThemeMode, UpdateSelectedTheme, UpdateNotifications, UpdateHapticFeedback, UpdateAutoSave, UpdateAwesomeSnackbar` solo aparecen en su definición y en el registro DI. `SettingsBloc` y `ThemeBloc` usan **directamente** `SettingsRepository`/`AppThemeRepository`.
- **Impacto:** capa `domain` de settings en gran parte ficticia; 9 registros DI sin uso.
- **Recomendación:** o el `SettingsBloc` pasa a invocar los usecases (arquitectura correcta) o se eliminan los 9 usecases y sus registros.

#### H-06 · `parser` sin capas: lógica de negocio en `utils/`
- **Ubicación:** `lib/features/parser/utils/mlbb_parser.dart` (`class StatsParser`, 669 líneas) y `lib/features/parser/utils/mlbb_validator.dart`
- **Evidencia:** no hay `data/` ni `domain/usecases` ni `domain/repositories`. `StatsParser` usa métodos estáticos y **estado mutable estático** (`_extractionLog:266`, `_rawMatches:267`). `presentation` los invoca directo (`upload_controller.dart:2-3,120-126`; `insights/presentation/widgets/session_stats_card.dart:2,14`).
- **Impacto:** regla de negocio fuera de `domain`/`data`; estado global no reentrante ni testeable en aislamiento.
- **Recomendación:** exponer el parseo vía `ParserRepository` abstracto en `domain` con impl/datasource en `data`; eliminar el estado estático y devolver el log en el resultado.

### 🟡 Media

#### H-07 · `game_session.dart` duplicado/re-exportado + drift de nombres
- **Ubicación:** `lib/features/history/domain/entities/game_session.dart:1` (una sola línea: `export ... upload/domain/entities/game_session.dart;`) vs `lib/features/upload/domain/entities/game_session.dart` (clase **`StatsCollection`**) y `upload/data/model/game_session_model.dart:4` (`StatsCollectionModel extends StatsCollection`)
- **Impacto:** no hay dos clases homónimas, pero el nombre de archivo no coincide con la clase y el re-export oculta la dependencia real.
- **Recomendación:** eliminar el re-export; renombrar a `stats_collection.dart` / `stats_collection_model.dart`; decidir dueño único (H-02).

#### H-08 · `GameMode.shortName` duplicado y shadowed
- **Ubicación:** `parser/domain/entities/game_mode.dart:10` vs `parser/presentation/utils/game_mode_extensions.dart:52`
- **Evidencia:** la extensión `GameModeUI.shortName` nunca se invoca (un miembro de extensión no puede ocultar a uno de instancia); además los textos difieren ('Clasificatoria/Clásica/Coliseo' vs 'Ranked/Classic/Brawl').
- **Recomendación:** renombrar el de la extensión (p. ej. `chipLabel`) o eliminar `GameMode.shortName` y centralizar el texto.

#### H-09 · Doble patrón de estado en `upload` (Bloc + ChangeNotifier)
- **Ubicación:** `upload/presentation/bloc/upload_bloc.dart`, `upload/presentation/controllers/upload_controller.dart`
- **Evidencia:** `UploadScreen` usa `_controller` (`upload_screen.dart:31,63`) **y** `BlocListener<UploadBloc, UploadState>` (`:98`). El controller extiende `ChangeNotifier` (`upload_controller.dart:31`) y hace parseo/validación.
- **Recomendación:** unificar en Bloc y mover el parseo a un usecase.

#### H-10 · Carpeta vacía
- **Ubicación:** `lib/features/history/data/models/` (0 archivos; el modelo real está en `upload/data/model/`, singular)
- **Recomendación:** eliminar y unificar convención `models/`.

### 🔵 Baja

- **H-11** · Serialización (`toJson`/`fromJson`) dentro de entidades de `domain` (`parser/domain/entities/player_performance.dart`). Mover a modelo de `data`.
- **H-12** · Service locator invocado desde presentation: `navigation/presentation/screens/main_screen.dart:3` importa `injection_container.dart` y usa `sl<HistoryBloc>()` en `:65,78`. Inyectar vía providers.
- **H-13** · `test/` desfasado respecto a `lib/` (ver `05-...`).
- **H-14** · Uso de `lazySingleton` para usecases sin criterio documentado (`injection_container.dart:115-154`); documentar la convención.

---

## Cumple correctamente

- `domain` **no** importa `data` ni `presentation` (0 coincidencias en el grep).
- Repositorio abstracto en `domain` + impl en `data`: correcto en `history`, `ocr` y `settings`.
- `presentation` consume `domain` (repos/usecases/blocs), sin tocar `data` directamente.
- `HistoryBloc` como `lazySingleton` (instancia única entre tabs) y `UploadBloc` como `factory` está cableado con intención.
- `core/errors/app_failures.dart` es genuinamente transversal.
- No hay dos clases de entidad homónimas.

---

## Advertencias

- El re-export de `history/domain/entities/game_session.dart` hace que muchas herramientas reporten una falsa duplicación; **es intencional en el código actual**.
- Arreglar H-01/H-02 toca imports en varios archivos a la vez; conviene hacerlo por pasos y con la suite verde entre pasos.

## Próximos pasos

1. **H-01**: reubicar splash y `CopyToClipboard`/`ImageSourceParams`; invertir `dialog_service`.
2. **H-02/H-07**: designar dueño de `StatsCollection` y eliminar el re-export.
3. **H-03**: sacar framework del `domain` (prioriza `navigation_item` y `app_settings`).
4. **H-06**: crear `domain/repositories` + `data` para `parser` (coordinar con `02-...`).
5. **H-04/H-05/H-10**: limpiar DI y carpetas vacías (rápido, bajo riesgo).
