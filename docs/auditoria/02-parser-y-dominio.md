# 02 — Parser, validación y dominio

**Contexto.** El valor central de la app es convertir el texto OCR en un `PlayerPerformance`. `StatsParser` (`lib/features/parser/utils/mlbb_parser.dart`, 669 líneas) y `StatsValidator` (`lib/features/parser/utils/mlbb_validator.dart`, 265 líneas) son el motor. Entidad: `lib/features/parser/domain/entities/player_performance.dart`.

**Precisión de datos:** la entidad tiene **26 campos** (incluido `mode`) en `player_performance.dart:4-35`. `StatsParser.getFieldsForVerification` devuelve **22** (`mlbb_parser.dart:629-650`). El validador cuenta **22** `totalFields` (`mlbb_validator.dart:21`). El README dice "28". → **inconsistencia de conteo a alinear.**

---

## Hallazgos

### 🟠 Alta

#### F1 · Win-rate: captura cruzada con "Participación en Equipo" y dependencia del orden
- **Ubicación:** `mlbb_parser.dart:514-559` (rango en `:542`, `.first` en `:554`); patrones en `:16-20`
- **Evidencia:** se recolectan **todos** los `%` del texto y se toma el primero en rango 40–80 (`:542`). La "Participación en Equipo" (p. ej. 78.5%) también cae en ese rango; si su línea aparece antes en el OCR, se devuelve como win-rate.
- **Impacto:** métrica central incorrecta, sin detección de error.
- **Recomendación:** desambiguar por etiqueta primero (`(?:Tasa\s*de\s*Victorias?|Win\s*Rate|Victorias?)\s*[:]?\s*(\d{1,3}(?:[.,]\d+)?)\s*%`) y usar el rango solo como *fallback*.

#### F2 · Separador decimal con coma rompe porcentajes y KDA
- **Ubicación:** `mlbb_parser.dart:523,574` (`replaceAll(',', '')`); patrones `:16-20`, `:43-61`
- **Evidencia:** los patrones usan `\.` como separador decimal. Con "59,29 %" el patrón `(\d{1,2})\s*%` (`:19`) captura "29" → `29.0`; con "KDA 4,53", `\d+\.?\d*` captura "4" → `4.0`; con "78,5%" captura "5" → `5.0`.
- **Impacto:** truncado silencioso en capturas con coma decimal (locales es-*).
- **Recomendación:** aceptar `[.,]` en los patrones y normalizar según número de dígitos (1–2 → decimal; 3 → miles).

#### F15 · Cobertura de tests insuficiente para los riesgos anteriores
- **Ubicación:** `test/core/utils/stats_parser_test.dart` (39 tests), `stats_validator_test.dart` (26)
- **Evidencia (falsos positivos):** los tests de detección de modo `stats_parser_test.dart:36-55` pasan el mismo modo que esperan; como `parseStats` **sobrescribe** el modo (`:272-275`), no ejercen la detección.
- **Escenarios no cubiertos:** coma decimal; win-rate vs participación en el mismo rango; fallback fuera de 40–80; cross-capture de daño; valores límite (40/80, 1000/999999); ruido OCR (labels partidas por salto de línea, `|`, sin tildes); texto vacío; colisión de modos; mapeo de `getFieldsForVerification` campo↔valor.
- **Recomendación:** añadir los tests de la sección "Ejemplos" al final.

### 🟡 Media

#### F3 · `maxDamageDealt` puede capturar el "Daño tomado"
- **Ubicación:** `mlbb_parser.dart:229-230` (patrón de respaldo `Da[ñn]o[^0-9]{0,20}(\d{4,6})`), orden de extracción `:454` (dealt) antes de `:462` (taken)
- **Evidencia:** el patrón genérico admite hasta 20 caracteres no-dígito, por lo que "Daño tomado Máx./min 15555" encaja. Si la línea de "Causado" falla, `maxDamageDealt` recibe el valor de **tomado**.
- **Recomendación:** anclar el patrón a `Causado|Dealt`; extraer ambos del mismo bloque y cross-validar.

#### F4 · `_detectGameMode` es efectivo inerte
- **Ubicación:** `mlbb_parser.dart:272-275,301` (sobrescritura con `copyWith(mode:)`), `_detectGameMode` en `:599-618`
- **Evidencia:** en producción el modo viene de la UI (`upload_controller.dart:107,122`); la detección solo loguea y su resultado se descarta. `:605` usa "clásica" con tilde (OCR "clasica" no coincide).
- **Recomendación:** decidir la fuente de verdad; si se mantiene, testear `parseFromText` y aceptar variantes sin tilde; si no, eliminar.

#### F5 · Patrón `%` captura dígitos finales de cualquier porcentaje
- **Ubicación:** `mlbb_parser.dart:19` (`(\d{1,2})\s*%`) usado en `:519-531`
- **Evidencia:** en "59.29 %" también coincide con "29 %"; en "100%" con "00" → `0.0`. Contamina `allPercentages`.
- **Recomendación:** exigir frontera previa: `(?<![\d.])(\d{1,3}(?:[.,]\d+)?)\s*%`.

#### F6 · Estado estático mutable compartido
- **Ubicación:** `mlbb_parser.dart:266-267` (`static final _extractionLog`, `_rawMatches`)
- **Evidencia:** `parseFromText`/`parseStats` (`:269-313`) nunca limpian el log; solo `parseStatsWithDiagnostics:279-280` y `upload_controller.dart:120` lo hacen. No reentrante ni seguro ante parseos concurrentes.
- **Recomendación:** devolver el log en `ParseResult` (ya existe) y eliminar el estado estático, o convertir el parser en instancia.

#### F8 · Complejidad y mantenibilidad
- **Ubicación:** `mlbb_parser.dart:14-263` (`_CompiledPatterns`), `:315-512` (`_parseFromTextWithLogging`, ~197 líneas)
- **Evidencia:** 21 llamadas casi idénticas a `_extractWithPatterns` (`:326-476`) para construir un objeto de 26 argumentos (`:480-507`). Los nombres de campo (con acentos) se repiten en 3 sitios: `getFieldsForVerification:629-650`, `mlbb_validator.dart:119-133` y `session_detail_screen.dart:198-200`.
- **Recomendación:** tabla de especificación por campo (`FieldSpec`) + bucle único; extraer grupos (`_extractCore/_extractPerformance/_extractMax`); centralizar las claves de campo en una constante compartida con el validador y la UI.

#### F9 · `completionPercentage` engañoso; rama `< 50%` inalcanzable
- **Ubicación:** `mlbb_validator.dart:21,135-149,228-230`
- **Evidencia:** `totalFields = 3+6+13 = 22`. Los 13 logros y también `mvp` (`:65`), `deathsPerGame` (`:103`) y `towerDamagePerGame` (`:111`) suman **siempre** a `validFields`; solo 6 campos pueden fallar → mínimo 16/22 = **72.7%**. La recomendación "muy pocos datos (<50%)" nunca se ejecuta.
- **Recomendación:** distinguir "extraído" de "válido" al contar, o basar la recomendación en `missingFields+warningFields`; ajustar/eliminar el umbral `<50`.

#### F12 · Tres campos duplicados y no leídos
- **Ubicación:** `player_performance.dart:33-35`; asignados en `mlbb_parser.dart:504-506`
- **Evidencia:** `oroMaxMin = maxGold`, `danoTomadoMaxMin = maxDamageTaken`, `danoCausadoMaxMin = maxDamageDealt` (mismos valores). Grep en `lib`: nunca se leen (solo definición/copyWith/JSON); solo los usan los tests.
- **Recomendación:** eliminar los 3 campos y actualizar `copyWith`/`toJson`/`fromJson` y los tests que los referencian (`entities_test.dart:37-39`, `stats_collection_model_test.dart:31-33`, `stats_validator_test.dart:56-58`).

### 🔵 Baja

- **F7 · `print` en producción:** `mlbb_parser.dart:624` (`print('[StatsParser] ...')`), sin guarda `kDebugMode`. → `debugPrint`/logger.
- **F10 · MVP mal clasificado:** `mlbb_validator.dart:44-69` cuenta `totalFields += 3` incluyendo MVP, pero el comentario dice "No es crítico" (`:65`) y nunca entra en `missingFields`. → mover a opcionales o documentar.
- **F11 · Etiquetas de warning con explicación embebida:** `mlbb_validator.dart:64,102,110` (`'MVP (puede ser legítimamente 0)'`), y luego se comparan por igualdad. → separar `field` (clave) de `reason` (mensaje).
- **F13 · Falta `==`/`hashCode`/`toString`:** `player_performance.dart` es un value object sin igualdad de valor; `entities_test.dart:265` compara por identidad de referencia. → implementar igualdad o usar `equatable`.
- **F14 · Inmutabilidad correcta:** campos `final` + constructor `const`; `fromJson` (`:169-198`) usa `_toInt/_toDouble` robustos. Observación: el fallback silencioso de `mode` a `GameMode.total` puede enmascarar datos corruptos.

---

## Cumple correctamente

- Diseño multi-patrón por campo (tolerante a variaciones de OCR) con `_CompiledPatterns` compilados una vez.
- Inmutabilidad y helpers de parseo robustos en `PlayerPerformance.fromJson`.
- El validador distingue críticos vs opcionales con mensajes informativos (`getDetailedErrorMessage`, `getRecommendations`).

---

## Advertencias

- **Cualquier cambio al parser debe ir con test primero** (modo strict-TDD del proyecto): los riesgos F1/F2/F3 son silenciosos y no fallan la suite actual.
- Cambiar los patrones de `%` puede alterar el dedup (`:525`) y la selección de win-rate; revisar ambos juntos.
- F12 toca tests; hazlo en un commit separado del resto.

## Próximos pasos

1. **F2** (coma decimal) y **F1** (win-rate por etiqueta) con tests nuevos — mayor impacto en corrección.
2. **F3/F5** (fronteras de patrón) y **F4** (decidir modo).
3. **F12** (campos muertos) + **F13** (`==`/`hashCode`).
4. **F8/F6** refactor de mantenibilidad (tabla de campos, sin estado estático).
5. **F9/F10/F11** ajustes del validador y conteo de campos (alinear README: 22/26, no 28).

### Ejemplos de tests a añadir

```dart
test('no confunde participación (en rango) con win rate si va antes', () {
  const text = 'Participación en Equipo 78.5%\n59.29 % Tasa de Victorias';
  final r = StatsParser.parseStats(text, GameMode.total)!;
  expect(r.winRate, closeTo(59.29, 0.01));
});

test('lee decimales con coma', () {
  const text = 'KDA 4,53 Tasa de Victorias 59,29 %';
  final r = StatsParser.parseStats(text, GameMode.total)!;
  expect(r.kda, closeTo(4.53, 0.01));
  expect(r.winRate, closeTo(59.29, 0.01));
});

test('no captura "Daño tomado" como "Daño causado"', () {
  const text = 'Daño Tomado Máx./min 15555';
  final r = StatsParser.parseStats(text, GameMode.total)!;
  expect(r.maxDamageDealt, isNot(15555));
});
```
