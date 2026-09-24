# Design: Cleanup & Parser Fixes

## Technical Approach

Five independently-committable phases, each verified by `flutter test` / `flutter analyze`. Parser fixes are pure regex-list extensions (the existing `_CompiledPatterns` first-match strategy is kept — no restructuring). Removals were each verified zero-import at design time via repo-wide grep (evidence per file below). Boot smoke test replaces the stale counter test using fixed-duration pumps — `pumpAndSettle` is forbidden because `_particleController..repeat()` (splash_screen.dart:70-71) never settles.

## Architecture Decisions

| Decision | Options | Choice | Rationale |
|---|---|---|---|
| Spanish label-first totalGames | append at list end vs. insert after number-first | **Insert at index 1** of `_CompiledPatterns.totalGames` (after line 24) | First-match strategy: P1 must keep priority for number-first `1500 Partidas Totales`. Anywhere after P1 works; index 1 mirrors the English pair (P5 number-first → P6 `Played` label-first). Appending works only by coincidence (catch-all P7 `(\d+)(?=.*Tasa)` would grab the same value) |
| MVP separator | `\s*` → `[^\S\n]*` | **`(\d+)[^\S\n]*MVP`** (line 35) | `[^\S\n]` = whitespace minus newline: blocks `1929\nMVP`, keeps `5 MVP`. Zero-`\s`-qualifier change, minimal diff |
| base_usecase move | split UseCase/ImageSourceParams vs. move whole file | **Move whole file** to `lib/core/usecases/` | `recognize_image_text.dart:7` uses `ImageSourceParams` — splitting forces a second import for marginal purity. Residual core→ocr/domain entity import (`ImageSourceType`, ocr_image_source.dart:1) is domain→domain, accepted; flagged for future enum relocation |
| nav test fix | await+expect vs. blocTest | **blocTest with `verify:`** | File's dominant idiom (11 blocTests); `verify: (b) => expect(b.getBadge(2), equals('3'))` gates `_badges` map — a true regression trip, unlike the vacuous `Future.delayed` escape |
| `totalDestinations: 3` | drop arg (bloc default is 3) vs. explicit | **Explicit `NavigationBloc(totalDestinations: 3)`** | Self-documenting correction of the stale 7; bloc default (navigation_bloc.dart:12) already 3 |

## Data Flow

```
text ──→ _extractWithPatterns(text, patterns, …) ── first pattern list match wins ──→ PlayerPerformance
         totalGames[0]=number-first → [1]=NEW Spanish label-first → [2..7] fallbacks
         mvp[0]=(\d+)[^\S\n]*MVP → mvp[1]=MVP\s*[:\s]*(\d+)   (badge line → 320)

MyApp → ThemeBloc.LoadTheme → ThemeLoaded → MaterialApp(home: SplashScreen)
     → 3.8s sequence (200+900+100+1200+900+500ms) → pushReplacement → MainScreen
```

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/features/parser/utils/mlbb_parser.dart` | Modify | totalGames: insert `(?:Partidas?\s*(?:Jugadas?\|Totales?))\s*[:\s]*(\d+)` at index 1 (caseSensitive:false → covers lowercase/singular, `1,500` via existing comma-strip :573). mvp[0]: `(\d+)\s*MVP` → `(\d+)[^\S\n]*MVP` |
| `test/core/utils/stats_parser_test.dart` | Modify | :15-31 add `totalGames==1500` (RED now: current parser yields 0 for label-first `Partidas Totales 1500`), `mvpCount==320`, `winRate≈59.29`. :70-74 replace `isA<Map>` with `rawMatches['KDA']==4.5` + `contains('Tasa de Victorias')` |
| `test/widget_test.dart` | Rewrite | Boot smoke test (below), no counter assertions |
| `test/features/navigation/bloc/navigation_bloc_test.dart` | Modify | :138-145 → blocTest (below) |
| `lib/features/upload/domain/repositories/session_repository.dart` + `data/repositories/session_repository_impl.dart` | Delete | Zero external imports (only impl→domain self-pair) |
| `lib/features/upload/presentation/widgets/{upload_source_button,upload_image_picker_card}.dart` | Delete | Zero imports |
| `lib/features/navigation/presentation/screens/widgets/main_bottom_bar.dart` | Delete | Zero imports; sole `salomon_bottom_bar` consumer |
| 7 barrels `lib/features/{upload,settings,navigation,parser,insights,ocr,history}/*.dart` | Delete | Zero imports (all code uses direct paths) |
| 4 core widgets `lib/core/widgets/{session_summary_card,error_state_widget,empty_state_widget,app_info_banner}.dart` | Delete | Zero imports |
| `lib/features/settings/domain/usecases/usecases.dart` | Delete | Empty barrel, zero imports |
| `pubspec.yaml` | Modify | Drop `salomon_bottom_bar: ^3.3.2` (line 19) + `flutter pub get`. `http` is NOT in pubspec (transitive) — nothing to remove |
| `lib/core/injection/injection_container.dart` | Modify | Remove :3 import + :83 `http.Client()`; :203 `totalDestinations: 3` |
| `lib/features/navigation/presentation/screens/main_screen.dart` | Modify | Delete `_PlaceholderPage` (:188-222, zero instantiations) |
| `lib/features/upload/domain/usecases/base_usecase.dart` | Move | → `lib/core/usecases/base_usecase.dart`; rewrite 4 imports (ocr_bloc.dart:4, recognize_image_text.dart:5, get_settings.dart:5, copy_to_clipboard.dart:4) |
| `skills-lock.json` | Modify | Remove both supabase entries (:4-15) → `{"version":1,"skills":{}}` |
| `.opencode/skills/insight-architecture/SKILL.md` | Modify | Remove :41 `HTTP Client: http package` |
| `GEMINI.md` | Modify | Remove :6-9 (`.agents/skills` priority + supabase exclusion) and :17 `Backend: Supabase`. **Untracked — commit at user's discretion** |
| `test/all_tests.dart` | Modify | Remove :9, :22, :41 stats_bloc references (suite doesn't exist — verified) |
| `README.md` | Modify (SHOULD) | :152 `heroes/` tree line — outside spec's file list but inside acceptance grep "documentation" |

## Interfaces / Contracts

```dart
// mlbb_parser.dart — exact edits
RegExp(r'(?:Partidas?\s*(?:Jugadas?|Totales?))\s*[:\s]*(\d+)', caseSensitive: false), // totalGames[1]
RegExp(r'(\d+)[^\S\n]*MVP', caseSensitive: false),                                   // mvp[0]

// widget_test.dart — boot smoke
SharedPreferences.setMockInitialValues({});
await di.init();
await tester.pumpWidget(const MyApp());
await tester.pump(const Duration(milliseconds: 500)); // ThemeBloc → ThemeLoaded
await tester.pump(const Duration(seconds: 4));        // splash 3.8s sequence
await tester.pump();                                  // pushReplacement frame
expect(find.byType(MainScreen), findsOneWidget);
expect(find.byType(UploadHomeScreen), findsOneWidget);
expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);

// navigation_bloc_test.dart — replacement for :138-145
blocTest('getBadge retorna el badge correcto después de actualizar',
  build: () => NavigationBloc(totalDestinations: 4),
  act: (b) => b.add(const UpdateNavigationBadge(index: 2, badge: '3')),
  expect: () => [isA<NavigationBadgeUpdated>()],
  verify: (b) => expect(b.getBadge(2), equals('3')));
```

Smoke test feasibility verified: LocalStorageDataSource is 100% SharedPreferences-backed; HistoryBloc preload returns `[]` on empty mock; OcrBloc/UploadBloc construct without platform calls (TextRecognizer is lazily constructed, no native call at boot).

## Testing Strategy

| Layer | What | How |
|---|---|---|
| Unit | totalGames Spanish label-first (800, Totales, lowercase, 1,500); mvp badge-vs-adjacent-line | `flutter test test/core/utils/stats_parser_test.dart` — :112-116 red→green; strengthened :15-31 red→green |
| Widget | Boot: splash → MainScreen | `flutter test test/widget_test.dart` (fixed pumps) |
| BLoC | getBadge gates | blocTest `verify:` |
| Whole | After each phase | `flutter test` + `flutter analyze`; grep evidence: zero `session_repository`, barrels, deleted widgets, `salomon`, `package:http`, no `_PlaceholderPage` |

## Migration / Rollout

None — no data migration. Per-commit `git revert` rollback; each phase independently reversible.

## Open Questions

- [x] `.atl/skill-registry.md:49-50` still lists supabase — untracked SDD artifact; refresh on next skill-registry run, excluded from acceptance grep
- [x] base_usecase keeps `core → ocr/domain` entity import — accepted; future: relocate `ImageSourceType` to core
- [x] README.md:152 included in docs-sync (1 line) to satisfy acceptance grep