# 04 — Datos, persistencia y rendimiento

**Contexto.** El historial se guarda en `shared_preferences` como un único string JSON. El datasource (`lib/features/upload/data/datasources/local_storage_datasource.dart`) implementa un patrón read-modify-write sobre ese blob. El repositorio (`lib/features/history/data/repositories/history_repository_impl.dart`) orquesta CRUD, export/import. El OCR usa `google_mlkit_text_recognition` (`lib/features/ocr/data/datasources/ocr_datasource.dart`).

> **Alcance:** hallazgos basados en la lectura de 14 archivos concretos, no en ejecución de la app.

---

## Hallazgos

### 🔴 Crítica

#### D-01 · La corrupción del JSON borra **todo** el historial en silencio
- **Ubicación:** `local_storage_datasource.dart:88` y `:93` (dentro de `getAllStatsCollections`)
- **Evidencia:**
  ```dart
  try {
    decoded = json.decode(jsonString);
  } catch (e) {
    await sharedPreferences.remove(_collectionsKey);   // :88
    return [];
  }
  if (decoded is! List) {
    await sharedPreferences.remove(_collectionsKey);   // :93
    return [];
  }
  ```
- **Impacto:** un byte corrupto, un JSON truncado o un valor no-lista elimina **toda** la colección del usuario de forma permanente, sin aviso ni respaldo. Como `saveStatsCollection` llama antes a `getAllStatsCollections()` (`:31`), la siguiente escritura consolida la pérdida.
- **Recomendación:** no borrar en el camino de lectura. Conservar el valor crudo en una clave de cuarentena (`stats_collections_corrupt`) y devolver `Failure` en lugar de `[]`; respaldar la clave antes de sobrescribir.

#### D-02 · Se carga y decodifica **todo** el historial en cada operación
- **Ubicación:** `local_storage_datasource.dart:31,124,139,192,232`
- **Evidencia:** `getAllStatsCollections()` (decode completo + sort) es llamado por `saveStatsCollection`, `getLatestStatsCollection`, `deleteStatsCollection`, `updateStatsCollectionName` y `getStatsCollectionByDate`. `getLatestStatsCollection` (`:124`) decodifica todo para devolver `collections.first`.
- **Impacto:** coste O(n) de decode+sort también al abrir "última colección", renombrar o borrar.
- **Recomendación:** índice por `createdAt`/`id` o BD con índice; `getLatest`/`getByDate` no deben materializar toda la lista.

#### D-03 · Guardado batch / import **O(n²)**
- **Ubicación:** `history_repository_impl.dart:189-207` (`saveCollectionsBatch`), apoyado en `local_storage_datasource.dart:29-63`
- **Evidencia:** el bucle llama a `saveStatsCollection` por cada elemento, y cada llamada **re-lee y re-escribe toda la lista**.
- **Impacto:** importar N colecciones ejecuta N ciclos de decode+encode+write ⇒ O(n²) en tiempo y E/S, multiplicando las ventanas de escritura no atómica.
- **Recomendación:** leer una vez, aplicar todas las inserciones en memoria y escribir **una sola** vez (o usar transacción de BD).

### 🟠 Alta

#### D-04 · Escrituras read-modify-write no atómicas + fallo de lectura degradado a `[]`
- **Ubicación:** `local_storage_datasource.dart:29-63`, `:138-168`, `:191-220`; en particular `:31-35`
- **Evidencia:**
  ```dart
  try { collections = await getAllStatsCollections(); }
  catch (e) { collections = []; }   // :31-35
  ```
- **Impacto:** dos operaciones concurrentes pueden intercalarse (last-write-wins); y un error de lectura transitorio se convierte en una escritura que **borra** el historial previo.
- **Recomendación:** serializar el acceso con cola/mutex de escritura y **no** degradar errores de lectura a lista vacía (abortar la escritura).

#### D-05 · Sin versionado de esquema en el almacenamiento local
- **Ubicación:** `game_session_model.dart` (`toJson`/`fromJson`) y `local_storage_datasource.dart:60,162,215`
- **Evidencia:** el JSON persistido es una lista plana sin campo `version`/`schemaVersion`. El único versionado (`'version': '1.0'`) existe solo en el export de archivo (`history_repository_impl.dart:122`).
- **Impacto:** imposible migrar el formato almacenado; cualquier cambio de estructura + D-01 descartaría datos existentes.
- **Recomendación:** envolver en `{ "schemaVersion": 2, "collections": [...] }` y aplicar migraciones en lectura.

#### D-06 · Sin paginación ni búsqueda en la capa de datos
- **Ubicación:** `local_storage_datasource.dart:80-118`; `history/domain/usecases/get_all_stats_collections.dart`
- **Evidencia:** `getAllStatsCollections()` devuelve la lista completa; el usecase no acepta `limit`/`offset` ni filtros.
- **Recomendación:** exponer `(limit, offset)` y filtros respaldados por BD con índices.

#### D-07 · Errores silenciados (items descartados sin traza)
- **Ubicación:** `local_storage_datasource.dart:100-110`; `history_repository_impl.dart:176-180`; `theme_datasource.dart` (`getThemeById` catch → `null`)
- **Evidencia:**
  ```dart
  try { collections.add(StatsCollectionModel.fromJson(item)); }
  catch (e) { continue; }        // local_storage :109
  ...
  catch (_) { continue; }        // history_repository :179
  ```
- **Impacto:** registros corruptos/inválidos se descartan sin log ni aviso; pérdida invisible.
- **Recomendación:** contar y registrar omisiones; exponer un conteo de "elementos omitidos".

#### D-08 · `replaceExisting` borra todo el historial antes de insertar, sin transacción
- **Ubicación:** `history_repository_impl.dart:193-197`
- **Evidencia:** `if (replaceExisting) { await localDataSource.clearAllStats(); }` y después inserta elemento a elemento (O(n²), D-03).
- **Impacto:** si el bucle falla a mitad, el usuario queda con datos parciales y los originales ya borrados; sin rollback.
- **Recomendación:** buffer temporal + swap atómico, o transacción de BD.

#### D-09 · `TextRecognizer` sin cierre en el datasource
- **Ubicación:** `ocr_datasource.dart:19,41-43`
- **Evidencia:** `TextRecognizer` se recibe por constructor y se usa en `recognizeText`, pero la clase no expone `close()`/`dispose()`.
- **Impacto:** si el contenedor no lo cierra, se filtran recursos nativos de ML Kit. (El cierre real depende del provider DI, fuera del alcance leído.)
- **Recomendación:** exponer `dispose()` que llame a `textRecognizer.close()` y orquestarlo desde el proveedor.

### 🟡 Media

- **D-10 · `remove()` `false` tratado como error:** `local_storage_datasource.dart:179-183` (`throw FileSystemFailure` si `remove` devuelve false) → falsos `Failure` en flujos de "limpiar". Tratar el borrado como idempotente.
- **D-11 · `DateTime.parse` sin `tryParse`:** `game_session_model.dart:52` → `TypeError`/`FormatException` con datos externos/antiguos; el registro se descarta silenciosamente. Usar `tryParse` + fallback + log.
- **D-12 · Mapeo modelo↔modelo duplicado 3×:** existe `StatsCollectionModel.fromEntity(...)` pero `local_storage_datasource.dart:49-58,148-158,203-213` reconstruye el modelo a mano. Usar `fromEntity(c).toJson()`.
- **D-13 · `catch (e)` genérico:** `history_repository_impl.dart` (varios), `ocr_repository_impl.dart`, `settings_datasource.dart`, `theme_datasource.dart` → errores de programación (`TypeError`, `RangeError`) disfrazados de `FileSystemFailure`. Clasificar los inesperados.
- **D-14 · Import tolerante en exceso:** `history_repository_impl.dart:174-183` (solo falla si **ni una** colección es válida; sin informe de omitidos). Devolver `(imported, skipped, errors)`.
- **D-15 · `totalCollections` no validado:** `history_repository_impl.dart:124` (escritura) vs `:154-183` (lectura) → un archivo truncado pasa la validación básica. Comparar conteos.
- **D-16 · Sin límite de tamaño de import:** `json_export_datasource.dart:24-31` (`readAsString` completo antes de `jsonDecode`) → riesgo de OOM. Fijar tamaño máximo.
- **D-17 · Dedupe solo por timestamp:** `history_repository_impl.dart:199-203` y `local_storage_datasource.dart:37-45` usan `createdAt.millisecondsSinceEpoch` → colisiones en el mismo milisegundo. Introducir `id` (UUID).
- **D-18 · `imageQuality: 100` sin reescalado:** `ocr_datasource.dart:30` → fotos a resolución completa a ML Kit; memoria/lentitud. Fijar `maxWidth`/`maxHeight` y calidad ~85.
- **D-19 · Permisos no gestionados; cancelación = `''`:** `ocr_datasource.dart:26-35` colapsa permiso denegado/cancelación/error en un `ImagePickerFailure` genérico; la cancelación devuelve `''` que aguas arriba puede tratarse como ruta válida.

### 🔵 Baja

- **D-20 · `copyWith` pierde subtipo y null-safety:** `upload/domain/entities/game_session.dart` (`copyWith` devuelve `StatsCollection`, usa `??`).
- **D-21 · Retrocompatibilidad ad-hoc:** default de `name` (`game_session_model.dart`), no versionada.
- **D-22 · `Failure` solo con `message`:** `core/errors/app_failures.dart` (sin código ni `StackTrace`) dificulta diagnóstico.
- **D-23 · `InputImage.fromFile` sin validar archivo:** `ocr_datasource.dart:41`.

### Positivo

- Manejo de errores con `Either<Failure, T>` consistente en repositorios (`history_repository_impl.dart`, `ocr_repository_impl.dart`).
- `dartz` **sí se usa** (≈26 archivos de `domain`/`data`); no retirar sin plan.
- La retrocompatibilidad del campo `name` (default `''`) funciona para JSON antiguos.

---

## Recomendación estructural: migrar a base de datos

`shared_preferences` no está pensado para colecciones grandes: cada mutación reescribe el blob completo, sin transacciones ni índices.

| Opción | Pros | Contras |
| --- | --- | --- |
| **sqflite** | Ligero, SQL, índices y transacciones, sin codegen | SQL manual y migraciones propias |
| **drift** | Tipado, migraciones versionadas, consultas reactivas | Codegen y algo más de peso de build |
| **isar** | Muy rápido, objetos nativos, sin SQL | Menor madurez/ecosistema |

Recomendado: **drift** si se prioriza tipado + migraciones; **sqflite** si se busca mínima dependencia. Migrar con un paso único que lea el JSON actual y lo inserte en la tabla (resuelve D-01 a D-08 de raíz).

---

## Advertencias

- **Antes de tocar nada:** escribir tests con `SharedPreferences.setMockInitialValues` que fijen el comportamiento actual de `getAllStatsCollections`/`saveStatsCollection`, especialmente el camino de corrupción (D-01), hoy destructivo.
- Cambiar la clave de persistencia sin migración romperá instalaciones existentes.
- `getLatestStatsCollection` y `getStatsCollectionByDate` son los puntos más calientes si se mantiene `shared_preferences`.

## Próximos pasos

1. **Detener la pérdida de datos (P0):** D-01, D-04, D-09 → no borrar en lectura, no asumir `[]`, serializar escrituras.
2. **Rendimiento (P0/P1):** D-02/D-03 (O(n²)) e idealmente D-05/D-06/D-17 migrando a drift/sqflite con índice por `id`.
3. **Integridad de import/export:** D-14, D-15, D-16, D-08.
4. **OCR:** D-09 (cerrar recognizer), D-18 (reescalar), D-19 (permisos/cancelación tipada).
