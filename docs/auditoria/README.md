# Auditoría técnica de Insight — Índice

> **Fecha:** 2026-09-11
> **Rama auditada:** `refactor/cleanup-and-parser-fixes` (HEAD `b9eef13`)
> **Alcance:** todo `lib/`, `test/`, configuración de plataforma (`android/`, `ios/`), `pubspec.yaml`, `analysis_options.yaml`
> **Método:** 5 agentes de exploración en paralelo guiados por skills (`clean-architecture`, `architect-review`, `handoff-document`) + verificación empírica ejecutando `flutter analyze` y `flutter test`.

---

## 1. Cómo leer esta auditoría

Este paquete está pensado como **documento de traspaso (handoff)**: cuando quieras implementar cambios, abre el informe del tema correspondiente y usa su sección **"Próximos pasos"**. El plan agregado y priorizado está en `06-plan-de-accion.md`.

| Documento | Tema | Contenido |
| --- | --- | --- |
| `01-arquitectura-y-capas.md` | Clean Architecture | Regla de dependencia, ciclos entre features, fugas de framework, DI |
| `02-parser-y-dominio.md` | Motor OCR / parser | Corrección de extracción, patrones, validación, entidad, tests |
| `03-presentacion-y-estado.md` | BLoC y UI | Eventos/estados, lints, ciclo de vida, renderizado, duplicación |
| `04-datos-persistencia-rendimiento.md` | Datos | shared_preferences, integridad, O(n²), serialización, import/export, OCR |
| `05-calidad-tests-tooling-plataforma.md` | Calidad | Tests, deps, CI, lints, Android/iOS, deuda visible |
| `06-plan-de-accion.md` | Plan | Backlog priorizado (P0–P3) con criterios de aceptación |

Escala de severidad usada en todos los informes: **Crítica** (pérdida de datos / crash / rompe arquitectura) · **Alta** (bug funcional o deuda estructural relevante) · **Media** (deuda de mantenibilidad) · **Baja** (estilo / limpieza).

---

## 2. Resumen ejecutivo

La app está **funcional y con la suite en verde**, pero la auditoría encuentra **dos riesgos que pueden destruir datos del usuario**, **un crash garantizado en iOS**, y un conjunto de deudas arquitectónicas y de mantenibilidad concentradas sobre todo en la capa de persistencia y en la ubicación de la lógica de negocio.

**Lo más grave (P0):**

1. **La corrupción del JSON borra todo el historial en silencio** (`lib/features/upload/data/datasources/local_storage_datasource.dart:88,93`), y un fallo de lectura se degrada a lista vacía antes de reescribir (`:31-35`).
2. **Guardado batch/import es O(n²)** y **no atómico**: reescribe todo el blob por cada elemento (`history_repository_impl.dart:189-207`); riesgo de pérdida concurrente.
3. **iOS crashea al abrir cámara/galería**: faltan `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` en `ios/Runner/Info.plist`.

**Lo más relevante de arquitectura:**

4. `core` **depende de** `features` (splash, dialog_service, base_usecase, copy_to_clipboard), invirtiendo la regla de dependencia.
5. **Ciclo `upload` ⇄ `history`** por compartir `StatsCollection`.
6. **Fugas de framework en `domain`** (`Widget`/`IconData`/`Color`/`dart:ui` en entidades).
7. `parser` no es una feature con capas: la lógica de negocio vive en `utils/`.
8. **7 archivos `*_injection.dart` vacíos** y **9 use cases de settings huérfanos**.

**Lo más relevante de corrección (parser):** win-rate puede capturar la "Participación en Equipo"; la **coma decimal rompe** porcentajes/KDA; `maxDamageDealt` puede capturar el "Daño tomado"; la detección de modo es código muerto.

**Lo más relevante de proceso:** no hay **CI**, no hay **cobertura**, el lint es poco estricto y hay **dependencias sin usar** (`font_awesome_flutter`, `permission_handler`, `mocktail`).

**Positivo:** la suite pasa **191/191**; `domain` no importa `data`/`presentation`; los repositorios tienen contrato abstracto en `domain` e impl en `data`; el manejo de errores con `Either/Failure` es consistente.

---

## 3. Verificación empírica (ejecutada en esta auditoría)

Comandos ejecutados sobre el HEAD actual:

```text
flutter analyze --no-pub   → 11 issues (11 info, 0 warning, 0 error), exit 1
flutter test               → 191/191 tests passed
```

Entorno real medido: **Flutter 3.47.2 / Dart 3.13.2** (los artefactos previos de Engram registraban 3.44.9/3.12.2).

> Nota: `flutter test` modificó automáticamente `analysis_options.yaml` (añadió `exclude: build/android/ios/web`) y `pubspec.lock` (7 deps al día). Esos cambios quedaron en el working tree, sin commitear.

---

## 4. Matriz de verificación de claims previos

Las auditorías anteriores (memoria Engram del proyecto) y las afirmaciones del contexto de sesión se re-chequearon contra el código actual. **CIERTO** = confirmado; **FALSO** = corregido.

| # | Claim previo | Veredicto | Evidencia |
| --- | --- | --- | --- |
| 1 | Suite de tests pasa 191/191 | **CIERTO** | `flutter test` → "All tests passed!" |
| 2 | `flutter analyze` reporta 11 infos, 0 errores | **CIERTO** | salida de `flutter analyze` |
| 3 | README menciona "Enciclopedia de Héroes" desfasada | **CIERTO** | `README.md:85` (ya corregido en esta rama de docs) |
| 4 | README dice "7 destinos"; reales son 3 | **CIERTO** | `main_screen.dart:49-80` tiene 3 `NavigationItem` (Inicio, Historial, Configuración) |
| 5 | `GEMINI.md` menciona la Enciclopedia de Héroes | **FALSO** | `GEMINI.md` solo define Clean Architecture + Flutter + ML Kit |
| 6 | `analysis.txt` era un volcado obsoleto | **CIERTO** | referenciaba `lib/core/utils/stats_parser.dart` (inexistente); ya eliminado |
| 7 | Los 7 `lib/core/injection/*_injection.dart` están vacíos | **CIERTO** | los 7 archivos tienen 0 líneas |
| 8 | El módulo `heroes` fue eliminado | **CIERTO** | `lib/features/` contiene 7 dirs, sin `heroes` |
| 9 | Tests conservan nomenclatura vieja `test/features/stats/` | **CIERTO** | inventario de `test/` |
| 10 | La entidad `PlayerPerformance` tiene 28 campos | **FALSO** | tiene **26** (`player_performance.dart:4-35`); el validador cuenta **22** (`mlbb_parser.dart:629-650`); 3 están duplicados/no leídos |
| 11 | Falta `LICENSE` pese a proclamarse MIT | **CIERTO** | no existe `LICENSE` en la raíz; `README.md:180` lo referencia |
| 12 | Existe CI/CD | **FALSO** | no hay `.github/` ni pipeline alguno |

---

## 5. Advertencias (leer antes de implementar)

- **No tocar la lógica de persistencia sin tests primero.** El camino de lectura actual borra datos; cualquier refactor debe ir precedido de tests con `SharedPreferences.setMockInitialValues` que fijen el comportamiento actual y luego el deseado.
- **Los hallazgos de "datos/persistencia" se basan en lectura de 14 archivos concretos**, no en ejecución de la app. El ciclo de vida real del `TextRecognizer` (si algún provider lo cierra) queda fuera del alcance verificado.
- **Las severidades de los agentes se normalizaron**; ante discrepancia entre informes, prevalece la evidencia `archivo:línea` citada.
- Los archivos vacíos `docs/en/`, `docs/es/` y `docs/funcionalidades-recomendadas.md` ya existían antes de esta auditoría; **no forman parte de ella**.

---

## 6. Próximos pasos

1. Revisar `06-plan-de-accion.md` y elegir el bloque P0 (integridad de datos + permisos iOS).
2. Antes de cada cambio, abrir el informe del tema y su sección "Próximos pasos".
3. Añadir CI mínimo (`analyze` + `test`) para que la suite no dependa de ejecución manual (ver `05-...`).
4. Registrar en Engram el resultado de cada bloque implementado.
