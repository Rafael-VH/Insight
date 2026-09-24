# 05 — Calidad, tests, tooling y plataforma

**Contexto.** Suite actual: **191 tests en verde** (`flutter test`). `analysis_options.yaml` hereda `flutter_lints` e ignora dos reglas. No hay CI. La app es 100% offline (sin red).

---

## 1. Tests

**Inventario real** (confirmado por conteo de `test(`/`testWidgets(`/`blocTest` = 191 en 8 archivos):

| Archivo | N.º tests | Código real que cubre |
| --- | --- | --- |
| `test/core/utils/stats_parser_test.dart` | 39 | `lib/features/parser/utils/mlbb_parser.dart` |
| `test/core/utils/stats_validator_test.dart` | 26 | `lib/features/parser/utils/mlbb_validator.dart` |
| `test/features/stats/domain/entities/entities_test.dart` | 32 | `parser/domain/entities`, `upload/domain/entities` |
| `test/features/stats/data/models/stats_collection_model_test.dart` | 11 | `upload/data/model/game_session_model.dart` |
| `test/features/stats/presentation/controllers/stats_upload_controller_test.dart` | 36 | `upload/presentation/controllers/upload_controller.dart` |
| `test/features/settings/domain/entities/settings_entities_test.dart` | 30 | `settings/domain/entities` |
| `test/features/navigation/bloc/navigation_bloc_test.dart` | 16 | `navigation/presentation/bloc` |
| `test/widget_test.dart` | 1 | app completa (smoke) |

`test/all_tests.dart` importa 7 suites (líneas 12–29) y **no** incluye `test/widget_test.dart`, que solo corre por descubrimiento de `flutter test`.

### Hallazgos

- 🟠 **Alta — Sin tests de repositorios/datasources, BLoC por feature, widget y golden.** No existen tests para `history_bloc`, `ocr_bloc`, `upload_bloc`, `settings_bloc`, `theme_bloc`, ni para `HistoryRepositoryImpl`/`LocalStorageDataSource`. La capa más propensa a fallos (persistencia, import/export, OCR) no tiene red de seguridad. `bloc_test` solo se usa en `navigation_bloc_test.dart`.
  → Añadir `blocTest` por feature; tests de repos/datasource con `SharedPreferences.setMockInitialValues`; golden tests para los 4 widgets de gráficos.
- 🟡 **Media — Nomenclatura de test desactualizada.** `test/features/stats/**` y `test/core/utils/**` no reflejan `lib/features/` (`parser`, `upload`, `ocr`, `history`...). Los imports apuntan a archivos que existen, pero la estructura confunde.
  → Mover a espejo de `lib/` y actualizar `all_tests.dart`.
- 🟡 **Media — Smoke test frágil por temporizadores.** `test/widget_test.dart:20-22`: bucle 50 × `pump(100ms)` (hasta 5 s) dependiente de las duraciones del splash.
  → Inyectar duraciones o usar `pumpAndSettle`; separar en test por pantalla.
- 🔵 **Baja — Aserciones débiles.** `stats_upload_controller_test.dart:245` (`expect(controller.hasInvalidStats(), isA<bool>())`) y `stats_validator_test.dart:234` (asertiva dentro de `if`, puede no ejecutar).
  → Fijar textos OCR deterministas y aserciones de valor.

---

## 2. Lints

- 🟡 **Media — `use_build_context_synchronously` ignorado globalmente** (`analysis_options.yaml:12`). El código ya usa `context.mounted` en varios puntos (`dialog_service.dart:94,125,146,226`; `history_screen.dart:287`), señal de riesgo real.
  → Quitar el `ignore`, corregir con `if (!mounted) return;` y dejarlo activo.
- 🔵 **Baja — `avoid_types_as_parameter_names` ignorado** (`analysis_options.yaml:13`). Normalmente innecesario; eliminar y renombrar parámetros.
- 🟡 **Media — Config poco estricta.** El bloque `linter.rules` está efectivamente vacío (`analysis_options.yaml:32-34`).
  → Añadir reglas:
  ```yaml
  linter:
    rules:
      - prefer_single_quotes
      - require_trailing_commas
      - directives_ordering
      - always_declare_return_types
      - unawaited_futures
      - avoid_dynamic_calls
      - prefer_const_constructors
      - use_super_parameters
  ```
- 🔵 **Baja — 11 infos pendientes** (`avoid_print` en `mlbb_parser.dart:624`; `Color.value` en `create_custom_theme_bottom_sheet.dart:69,141`; `unnecessary_underscores` en `splash_screen.dart:175` y `upload_screen.dart:107,111`; `curly_braces` en `history_list_card.dart:44-50`). Mayoría auto-corregible con `dart fix --apply`.

---

## 3. Dependencias (`pubspec.yaml`)

- 🟡 **Media — `font_awesome_flutter: ^11.0.0` NO se usa.** Grep en `lib/` de `font_awesome_flutter|FontAwesome|FaIcon|FontAwesomeIcons` → 0 coincidencias. → Eliminar.
- 🟡 **Media — `permission_handler: ^12.0.1` NO se usa.** Grep de `permission_handler|Permission.` en `lib/` → 0 coincidencias (verificado en esta auditoría). → Eliminar salvo que se planee pedir permisos explícitos.
- 🔵 **Baja — `mocktail: ^1.0.4` declarado y no usado** en `test/` (solo se usa `SharedPreferences.setMockInitialValues`, que es de `shared_preferences`). → Conservar si se añadirán mocks (recomendado) o eliminar.
- 🔵 **Baja — `intl` solo para formato, sin i18n real.** No existen `flutter_localizations`, `localizationsDelegates`, `.arb` ni `AppLocalizations`; `AppSettings.language` existe (`app_settings.dart:30,39,85`, default `'es'`) pero **no se consume**.
  → Implementar `l10n` cableando `language`, o documentar que `intl` es solo formato y retirar el campo.
- 🔵 **Baja — `dartz` se usa pero sin mantenimiento activo** (≈26 archivos). Mantener a corto plazo; evaluar `fpdart` o un `Result` propio a largo plazo.
- ✅ Confirmadas en uso (no eliminar): `fl_chart`, `awesome_snackbar_content`, `file_picker`, `share_plus`, `path_provider`, `equatable`, `flutter_bloc`, `get_it`, `shared_preferences`, `image_picker`, `google_mlkit_text_recognition`.

> No se pudo verificar de forma estática el dato "73 paquetes con updates" (requiere `flutter pub outdated`).

---

## 4. Tooling / CI

- 🟠 **Alta — No existe CI/CD.** No hay `.github/` ni pipeline; los únicos YAML son `analysis_options.yaml`, `pubspec.yaml`, `devtools_options.yaml`. La suite de 191 solo corre en local.
  → Crear `.github/workflows/ci.yml`:
  ```yaml
  name: CI
  on: [push, pull_request]
  jobs:
    analyze-and-test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: subosito/flutter-action@v2
          with: { channel: stable, cache: true }
        - run: flutter pub get
        - run: flutter analyze --no-fatal-infos --fatal-warnings
        - run: flutter test --coverage
        - uses: romeovs/lcov-reporter-action@v0.4.0
          with: { lcov-file: coverage/lcov.info }
  ```
- 🟡 **Media — Sin cobertura ni umbral.** `.gitignore:34` ignora `/coverage/` (correcto) pero no se genera ni se exige.
  → `flutter test --coverage` + umbral (p. ej. 70% de líneas).
- 🟡 **Media — Sin pre-commit ni flavors.** No hay hooks personalizados; un único `applicationId` sin `productFlavors`.
  → hook `pre-commit` (`dart format --set-exit-if-changed` + `flutter analyze`) o `lefthook`; definir flavors/`--dart-define`.

---

## 5. Configuración de plataforma

- 🔴 **Alta — iOS sin descripciones de uso de cámara/galería (crash).** `ios/Runner/Info.plist` **no contiene** `NSCameraUsageDescription` ni `NSPhotoLibraryUsageDescription` (verificado leyendo el plist completo). `image_picker` los requiere → la app crashea al abrir cámara/galería en iOS.
  → Añadir:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Se usa la cámara para escanear capturas de estadísticas de MLBB.</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Se accede a la galería para seleccionar capturas de estadísticas.</string>
  ```
- 🟡 **Media — Permisos Android declarados que probablemente no se usan.** `android/app/src/main/AndroidManifest.xml:5-6`: `READ_EXTERNAL_STORAGE` y `WRITE_EXTERNAL_STORAGE` sin `maxSdkVersion`; no hay `READ_MEDIA_IMAGES` (API 33+). La persistencia usa `shared_preferences`/`path_provider` (directorios de app, sin permiso). `INTERNET` (`:7`) tampoco se usa (no hay red en `lib/`).
  → Quitar `WRITE_EXTERNAL_STORAGE`, revisar `READ_EXTERNAL_STORAGE` y evaluar quitar `INTERNET`.
- 🟡 **Media — `minSdk` no fijado, inconsistente con el README.** `android/app/build.gradle.kts:26` usa `flutter.minSdkVersion`; el README afirma "minSdk 21" e "iOS 10.0+" (`README.md:166-167`).
  → Fijar el valor explícito y alinear el README.
- 🟡 **Media — Release firmado con claves de debug; sin `Podfile` iOS.** `build.gradle.kts:38-42` (`signingConfig = signingConfigs.getByName("debug")` con TODO); `ios/` no tiene `Podfile`.
  → Configurar keystore de release (`key.properties`, ignorado) y generar/commitear el `Podfile`.

---

## 6. Deuda técnica visible

- 🟡 **Media — 7 archivos de inyección vacíos** (`lib/core/injection/*_injection.dart`, 0 bytes). Ver `01-...`.
- 🔵 **Baja — Documentación vacía:** `docs/en/` y `docs/es/` (vacías) y `docs/funcionalidades-recomendadas.md` (0 bytes). Poblar o eliminar.
- 🔵 **Baja — README referencia `LICENSE` inexistente** (`README.md:180`) y "28 campos" vs 22/26 reales (`README.md:42`). No existe `LICENSE` en la raíz (verificado).
- 🔵 **Baja — `.metadata` sin `android`/`ios`** (`.metadata:14-20`). Regenerar con `flutter create --platforms=android,ios .`.
- ✅ `analysis.txt` **ya no existe** (eliminado en esta rama de docs).

---

## Advertencias

- Crear CI antes de refactors grandes: hoy nada impide romper la suite en un commit.
- Los permisos iOS son un **crash en producción**, no un warning: priorizar.

## Próximos pasos

1. **P0:** permisos iOS.
2. **P1:** CI mínimo (analyze + test) y cobertura.
3. **P1:** tests de BLoC/repos de `history`/`ocr`/`upload`.
4. **P2:** eliminar deps sin usar; reactivar/hardening de lints; renombrar `test/features/stats`.
5. **P2:** `minSdk` explícito, signing de release, `Podfile`, limpieza de `docs/` vacíos y `LICENSE`.
