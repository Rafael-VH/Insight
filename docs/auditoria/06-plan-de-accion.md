# 06 — Plan de acción priorizado

> **Uso:** este es el backlog de implementación derivado de la auditoría. Cada bloque tiene criterios de aceptación verificables. Abre el informe del tema para el detalle y la evidencia (`archivo:línea`).
>
> **Regla del proyecto:** strict-TDD — test primero. Ver `05-... §1`.

Leyenda de severidad: 🔴 Crítica · 🟠 Alta · 🟡 Media · 🔵 Baja.

---

## P0 — Riesgos que destruyen datos o crashean (hacer primero)

| ID | Tema | Acción | Criterio de aceptación |
| --- | --- | --- | --- |
| D-01 | Datos | No borrar en el camino de lectura de `getAllStatsCollections`; cuarentena + `Failure` | Test: JSON corrupto **no** elimina datos; se preserva original en clave de cuarentena |
| D-04 | Datos | No degradar fallo de lectura a `[]`; abortar escritura | Test: lectura fallida ⇒ `Left(Failure)` y el blob previo intacto |
| D-03 | Datos | `saveCollectionsBatch` escribe **una** vez (no O(n²)) | Test: importar N elementos hace 1 write; tiempo lineal |
| D-09 | Datos | `TextRecognizer.dispose()` / cerrar desde el provider | El recognizer se cierra al desmontar; sin leaks nativos |
| — | Plataforma | Añadir `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` a `ios/Runner/Info.plist` | La app no crashea al abrir cámara/galería en iOS |

---

## P1 — Corrección funcional y deuda estructural

| ID | Tema | Acción | Criterio de aceptación |
| --- | --- | --- | --- |
| F2 | Parser | Aceptar separador decimal `[.,]` y normalizar | Tests: `59,29%`→59.29; `4,53`→4.53; `78,5%`→78.5 |
| F1 | Parser | Win-rate por etiqueta con fallback de rango | Test: participación (78.5%) antes que win-rate ⇒ win-rate = 59.29 |
| F3 | Parser | Anclar patrón de daño a `Causado|Dealt`; cross-validar | Test: solo "Daño tomado" ⇒ `maxDamageDealt` ≠ 15555 |
| F5 | Parser | Frontera `(?<![\d.])` en patrón `%` | Tests de límites siguen pasando; sin candidatos espurios |
| F4 | Parser | Decidir fuente de verdad del modo; tests reales | Test ejercita `parseFromText` o se elimina `_detectGameMode` |
| F12 | Parser | Eliminar 3 campos duplicados no leídos | `PlayerPerformance` sin `oroMaxMin`/`danoTomadoMaxMin`/`danoCausadoMaxMin`; tests actualizados |
| F13 | Parser | `==`/`hashCode`/`toString` en `PlayerPerformance` | Test de igualdad de valor (no de referencia) |
| H-01 | Arquitectura | Sacar splash/copy_to_clipboard de `core`; invertir `dialog_service` | `core/` no importa `features/` (grep = 0) |
| H-02/H-07 | Arquitectura | Dueño único de `StatsCollection`; eliminar re-export | Sin ciclo `upload`⇄`history`; sin archivo duplicado |
| H-03 | Arquitectura | Quitar Flutter de `domain` (`navigation_item`, `app_settings`, OCR `Rect`) | `domain/**` sin imports de `package:flutter` ni `dart:ui` |
| H-06 | Arquitectura | `parser` con `domain/repositories` + `data` | `presentation` no importa `utils/` directamente |
| P-01 | Presentación | Mover filtro/orden/paginación a `HistoryBloc` | `blocTest` cubren search/sort/paginación; la pantalla no usa `setState` para la lista |
| P-02 | Presentación | Guards `mounted` + reactivar lint | `use_build_context_synchronously` activo y sin infos |
| D-02 | Datos | `getLatest`/`getByDate` sin materializar toda la lista | Complejidad sublineal con índice/BD |
| D-05 | Datos | Versionar esquema local + migraciones | Payload con `schemaVersion`; migración probada |
| — | Calidad | CI `analyze` + `test` + cobertura | Workflow verde en push/PR |

---

## P2 — Mantenibilidad y limpieza

| ID | Tema | Acción |
| --- | --- | --- |
| H-04 | Arquitectura | Implementar/eliminar los 7 `*_injection.dart` vacíos |
| H-05 | Arquitectura | Usar o eliminar los 9 usecases de settings |
| H-10 | Arquitectura | Eliminar `history/data/models/` y unificar convención |
| H-11 | Arquitectura | Mover `toJson/fromJson` de entidades a modelos `data` |
| H-12 | Arquitectura | No resolver `sl` en widgets |
| F6 | Parser | Eliminar estado estático mutable (`_extractionLog`/`_rawMatches`) |
| F8 | Parser | `FieldSpec` + bucle único; claves centralizadas |
| F9/F10/F11 | Parser | Corregir completitud/umbral, MVP y etiquetas |
| P-04 | Presentación | Eliminar eventos/estados muertos (Navigation/OCR/History) |
| P-05 | Presentación | Implementar o eliminar caché del `ThemeBloc` |
| P-06/P-07 | Presentación | Quitar `Future.delayed` de orquestación; aplanar `ThemeBloc` |
| P-08 | Presentación | Eliminar doble carga inicial del historial |
| P-09 | Presentación | Decidir estrategia `IndexedStack` (perezoso vs documentar) |
| P-03 | Presentación | Unificar estado de `upload` en un solo BLoC |
| P-10 | Presentación | `SliverList.builder` y extraer helpers/widgets de `history_screen` |
| P-11 | Presentación | Centralizar colores en `ThemeConfig`/`ColorScheme` |
| P-12 | Presentación | Reemplazar `Future.delayed(100ms)` por reacción a estado |
| D-07/D-13/D-14/D-15 | Datos | Registrar omisiones, clasificar errores, informe de import, validar conteos |
| D-16/D-17 | Datos | Límite de tamaño de import; `id` UUID para dedupe |
| D-18/D-19 | Datos | Reescalar imagen OCR; permisos y cancelación tipada |
| — | Tests | `blocTest` por feature, tests de repos/datasource, golden de gráficos; renombrar `test/features/stats` |
| — | Deps | Eliminar `font_awesome_flutter` y `permission_handler`; decidir `mocktail`/`intl` |
| — | Plataforma | Quitar permisos Android innecesarios; fijar `minSdk`; signing release; `Podfile` |

---

## P3 — Pulido

| ID | Acción |
| --- | --- |
| P-13 | Migrar states/events a `sealed class` |
| P-14 | Excluir `timestamp` de `props` en `NavigationChanged` |
| P-15/P-16 | Eliminar ramas inalcanzables en `MyApp`; `_accentColor` fuera de `build` |
| P-17/P-18 | Consolidar `BlocListener`; `removeListener` en `dispose` |
| P-19/P-20/P-21 | Corregir/eliminar `_SettingsHeroCard`; i18n o documentar; extraer scaffolds de bottom sheets |
| F7 | `print` → `debugPrint`/logger |
| — | `dart fix --apply` para los 11 infos de estilo |
| — | Poblar/eliminar `docs/en`, `docs/es`, `funcionalidades-recomendadas.md` |
| — | Añadir `LICENSE` (MIT) o corregir README; alinear "28 campos" → 22/26 |
| — | Regenerar `.metadata` con `android`/`ios` |

---

## Orden sugerido de ejecución

```text
P0  D-01 → D-04 → D-03 → D-09 → permisos iOS
P1  F2 → F1 → F3 → F5 → F4/F12/F13
P1  H-01 → H-02/H-07 → H-03 → H-06
P1  P-01/P-02 → D-02/D-05 → CI
P2  (resto, agrupado por tema/feature)
P3  pulido y limpieza
```

## Definición de "hecho" por bloque

1. Tests añadidos (rojo → verde) que cubren el comportamiento nuevo.
2. `flutter analyze` sin infos nuevos.
3. `flutter test` en verde.
4. Informe del tema actualizado si cambia el estado del hallazgo.
5. Resultado registrado en Engram.
