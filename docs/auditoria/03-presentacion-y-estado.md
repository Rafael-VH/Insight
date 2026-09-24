# 03 — Presentación y gestión de estado (BLoC)

**Contexto.** 8 BLoCs/states/events (`navigation`, `history`, `upload`, `ocr`, `settings`, `theme`), un `StatsUploadController` (`ChangeNotifier`), pantallas/widgets en `lib/features/**/presentation/**` y `lib/core/presentation/splash/`. Composición de providers en `main.dart` y `main_screen.dart`.

---

## Hallazgos

### 🟠 Alta

#### P-01 · Filtro/orden/paginación en el widget con `setState` (estado duplicado)
- **Ubicación:** `lib/features/history/presentation/screens/history_screen.dart:42-57` (estado local) y `:60-166` (`_filterAndSortCollections`, `_onSearchChanged`, `_onToggleSort`, `_loadMoreCollections`, `_updateCollections`)
- **Evidencia:** `HistoryScreen` mantiene `_allCollections`, `_displayedCollections`, `_currentPage`, `_searchQuery`, `_sortBy`, `_isAscending` y los muta con `setState`, mientras `HistoryBloc` ya expone `HistoryCollectionsLoaded(collections)`. `_reloadWithFilters` relee el estado del BLoC con `context.read`.
- **Impacto:** dos fuentes de verdad desincronizables; la lógica de negocio (búsqueda/orden/paginación) queda intestable e invisible al BLoC.
- **Recomendación:** mover filtro/orden/paginación a `HistoryBloc` (`SearchChanged`, `SortChanged`, `LoadMore`) y exponer la lista ya procesada + `hasMore`/`isLoadingMore`.

### 🟡 Media

#### P-02 · `BuildContext` tras `await` (lint desactivado globalmente)
- **Ubicación:** `history_screen.dart:177-186` (`_renameCollection`), `:189-196` (`_deleteCollection`); `main_screen.dart:98-103` (`_handleTabChange`)
- **Evidencia:**
  ```dart
  final newName = await HistoryRenameDialog.show(...);   // :178
  if (newName != null && ... ) {
    context.read<HistoryBloc>().add(...);                 // :183  ← sin guard mounted
  }
  ```
  `analysis_options.yaml:12` desactiva `use_build_context_synchronously`, por eso no aparece en `flutter analyze`.
- **Impacto:** uso de `context`/`Navigator`/`ScaffoldMessenger` tras un gap asíncrono sin `mounted`; riesgo de excepción si la pantalla se desmonta.
- **Recomendación:** `if (!mounted) return;` antes de cada uso y reactivar el lint.

#### P-03 · Tres mecanismos de estado en `upload` (ChangeNotifier + setState + 2 BLoCs)
- **Ubicación:** `upload_screen.dart` (`StatsUploadController` + `ListenableBuilder` en `:107,109`, `BlocListener<OcrBloc>`/`BlocListener<UploadBloc>`), `upload_state_handler_mixin.dart` (`set isSaving(bool) => setState(...)`)
- **Impacto:** flujo difícil de seguir y testear; controller y BLoC se sincronizan manualmente.
- **Recomendación:** unificar en un único BLoC/Cubit o documentar la frontera (UI-local vs asíncrono) y reducir a una fuente.

#### P-04 · Estados/eventos muertos
- **Ubicación / Evidencia (verificado por grep):**
  - `navigation/presentation/bloc/navigation_event.dart:33` `NavigateToDestination` → no registrado en el BLoC ni despachado.
  - `navigation/presentation/bloc/navigation_state.dart:49` `NavigationTransitioning` → nunca emitido.
  - `ocr/presentation/bloc/ocr_event.dart:20,29` `CopyTextEvent`/`ResetStateEvent` y `ocr_state.dart:33` `TextCopied` → registrados/producidos pero ningún widget los usa.
  - `history/presentation/bloc/history_event.dart:15,17` `LoadLatestStatsCollectionEvent`/`GetStatsCollectionByDateEvent` → manejados pero nunca despachados.
- **Impacto:** API muerta que da falsa sensación de funcionalidad.
- **Recomendación:** eliminar o completar la funcionalidad y cubrirla con tests.

#### P-05 · Caché del `ThemeBloc` declarada pero nunca asignada (código muerto)
- **Ubicación:** `lib/features/settings/presentation/bloc/theme/theme_bloc.dart:23-24,28,36,38`
- **Evidencia:** `_cachedTheme`/`_cachedAvailableThemes` se leen en `:28,36,38` pero **no existe ninguna asignación** (grep: solo esas 5 líneas) → la rama `:29-42` es inalcanzable.
- **Recomendación:** implementar la caché (asignar tras cargar) o eliminar campos y rama.

#### P-06 · Estados transitorios + `Future.delayed` "mágicos" para recargar
- **Ubicación:** `history_bloc.dart:96-107` (`_onDelete`), `:131-146` (`_onUpdateName`), `:198-208` (`_onImport`)
- **Evidencia:** se emite estado de éxito y luego `await Future.delayed(300/200 ms)` + `add(LoadAllStatsCollectionsEvent())`; en `_onImport` el `Future.delayed(...add(...))` ni se `await`ea.
- **Impacto:** secuencias dependientes de timing; posibilidad de `add` tras cierre del bloc.
- **Recomendación:** encadenar en el mismo `fold` (`await save; emit(success); add(reload)`) sin delays.

#### P-07 · Pirámide de `fold` en `ThemeBloc`
- **Ubicación:** `lib/features/settings/presentation/bloc/theme/theme_bloc.dart:27-85`
- **Evidencia:** hasta 5 niveles de `fold` anidados con `async`, mezclando `await` y callbacks.
- **Recomendación:** aplanar con `await` secuencial y returns tempranos.

#### P-08 · Doble carga inicial del historial
- **Ubicación:** `main.dart:90` (`..add(LoadAllStatsCollectionsEvent())`) **y** `history_screen.dart:33,76-78` (`initState` → `_loadCollections()` → mismo evento)
- **Impacto:** dos cargas idénticas al arrancar (I/O y notificaciones innecesarias).
- **Recomendación:** dejar solo una de las dos.

#### P-09 · `IndexedStack` mantiene vivas todas las páginas
- **Ubicación:** `main_screen.dart:139-142`
- **Evidencia:** `IndexedStack` construye y mantiene montados `UploadHomeScreen`, `HistoryScreen` y `SettingsScreen`. Por tanto `SettingsScreen.initState` dispara `LoadSettings()` (`settings_screen.dart:20-23`) y `HistoryScreen.initState` carga el historial aunque el usuario no visite esas tabs.
- **Impacto:** más memoria y trabajo en el arranque.
- **Recomendación:** aceptar y documentar el coste, o construir de forma perezosa / cargar en el BLoC raíz.

#### P-10 · `history_screen.dart` grande y acoplado; lista no perezosa
- **Ubicación:** `history_screen.dart` (~560 líneas, ~20 métodos), `:410-472` (`SliverChildListDelegate([...])` + `...asMap().entries.map(...)`)
- **Evidencia:** se construye la `List<Widget>` completa antes de delegar; la paginación (`_pageSize = 10`) mitiga pero no hay reciclado.
- **Recomendación:** extraer lógica al BLoC (P-01), helpers de formato/métricas a utilidades y usar `SliverList.builder`/`SliverChildBuilderDelegate`.

#### P-11 · Colores hardcodeados y duplicados
- **Ubicación (ejemplos):** `0xFF059669` en `history_list_card.dart:46`, `upload_screen.dart`, `history_screen.dart`, `upload_home_screen.dart:280`, `main_screen.dart:47,54,73`, `theme_selector_widget.dart:53`; `0xFFD97706`/`0xFFDC2626` en `history_list_card.dart:48,50`.
- **Impacto:** cambios de marca costosos; rompe temas personalizados (el color no respeta el `ColorScheme` activo).
- **Recomendación:** centralizar en `ThemeConfig`/extensiones de `ColorScheme`.

#### P-12 · Secuenciación por `Future.delayed(100ms)` entre Settings y Theme
- **Ubicación:** `settings_theme_mode_selector.dart:16-24` (tras `SettingsBloc.add(UpdateThemeMode)`, espera 100 ms y hace `context.read<ThemeBloc>().add(ChangeThemeMode)`); también `settings_reset_dialog.dart:28` y `upload_state_handler_mixin.dart:76,228`
- **Impacto:** frágil ante latencias; puede leer settings desactualizados.
- **Recomendación:** reaccionar al estado (`BlocListener` sobre `SettingsLoaded`) en lugar de esperar por tiempo.

### 🔵 Baja

- **P-13 · `sealed` no usado:** states/events son `abstract class` planas (p. ej. `history_state.dart:5`, `navigation_state.dart:4`, `ocr_event.dart:5`); migrar a `sealed class` para exhaustividad.
- **P-14 · `timestamp` en `props`:** `navigation_state.dart:34-44` (`NavigationChanged` con `DateTime.now()` en `props`) anula la igualdad de `Equatable` y provoca rebuilds.
- **P-15 · Ramas inalcanzables en `MyApp`:** `main.dart:100-140`; todos los tipos de `ThemeState` están cubiertos, el `return` final es muerto.
- **P-16 · `_accentColor` mutado en `build`:** `splash_screen.dart:197` (efecto secundario en build).
- **P-17 · Listeners duplicados:** `history_screen.dart:398-410` (dos `BlocListener<HistoryBloc>` anidados sin `listenWhen`).
- **P-18 · Scroll listener no removido:** `history_screen.dart:41` (`addListener(_onScroll)` sin `removeListener` en `dispose`).
- **P-19 · `alpha: 8.0` inválido:** `settings_screen.dart:92` en `_SettingsHeroCard` (widget sin uso, `// ignore: unused_element`).
- **P-20 · Textos hardcodeados + pluralización manual:** `history_screen.dart:224-242`, `upload_home_screen.dart:343`; sin i18n.
- **P-21 · Duplicación de UI entre bottom sheets:** `settings_export/import/delete_all_bottom_sheet.dart`, `history_export_import_bottom_sheet.dart` repiten handle/header/padding.

### Los 11 infos de `flutter analyze` (verificados)

| Regla | Ubicación |
| --- | --- |
| `unnecessary_underscores` | `splash_screen.dart:175` (`(_, __, ___)`); `upload_screen.dart:107,111` (`(_, __)`) |
| `curly_braces_in_flow_control_structures` | `history_list_card.dart:44-50` |
| `deprecated_member_use` (`Color.value`) | `create_custom_theme_bottom_sheet.dart:69,141` |
| `avoid_print` | `mlbb_parser.dart:624` |

La mayoría son auto-corregibles con `dart fix --apply`.

---

## Ciclo de vida (verificado OK)

Se liberan correctamente: `_animationController` (`main_screen.dart:36-40`), 4 `AnimationController` del splash (`splash_screen.dart:181-188,369-372`), `_saveTimeoutTimer` y el controller (`upload_screen.dart:63-69`; `upload_controller.dart:243-263`), `_scrollController`/`_searchController` (`history_screen.dart:44-52`), `_tabController` (`charts_screen.dart:35-38`), `_nameController` (`create_custom_theme_bottom_sheet.dart:49-52`). No hay `StreamSubscription`/`StreamController` sin liberar.

**Matiz sobre `HistoryBloc`:** el uso de `BlocProvider.value` (`main_screen.dart:65,78`) es correcto y no duplica registro (apunta al mismo `lazySingleton`). Pero el `BlocProvider<HistoryBloc>(create:)` raíz (`main.dart:88-91`) **sí cierra** al desmontarse un objeto cuyo ciclo de vida pertenece a GetIt; hoy es inofensivo (vive toda la app), pero es un acoplamiento frágil. → unificar la propiedad: `BlocProvider.value` en la raíz o `registerFactory` con dueño único.

---

## Advertencias

- Mover filtro/orden/paginación al BLoC (P-01) es el cambio de mayor impacto y riesgo; hacerlo con `blocTest` que cubran búsqueda, orden y paginación **antes** de tocar la UI.
- Reactivar `use_build_context_synchronously` producirá una lista de puntos a corregir; hazlo en un commit propio.

## Próximos pasos

1. **P-01** + **P-10**: llevar la lógica de la lista al `HistoryBloc` y usar `SliverList.builder`.
2. **P-02**: añadir guards `mounted` y reactivar el lint.
3. **P-04/P-05/P-06/P-07**: eliminar código muerto y delays; aplanar `ThemeBloc`.
4. **P-08/P-09/P-03**: eliminar doble carga; decidir estrategia de `IndexedStack`; unificar estado de `upload`.
5. **Resto**: `dart fix --apply` para los infos de estilo; centralizar colores (P-11) y reutilizar bottom sheets (P-21).
