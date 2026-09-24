# Tasks: Cleanup & Parser Fixes

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~350–450 |
| 800-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (5 commits) |
| Delivery strategy | ask-on-risk (ask-always) |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|---|---|---|---|
| 1 | Phases 1–2: parser + test health | PR 1 | TDD first |
| 2 | Phases 3–4: dead code + DI/nav | PR 1 | grep-zero each delete |
| 3 | Phase 5: docs sync | PR 1 | untracked docs |

## Phase 1 — Parser correctness (STRICT TDD: red → green → refactor)

- [ ] T1 (RED) `test/core/utils/stats_parser_test.dart:15-31` — assert `totalGames==1500`, `mvpCount==320`, `winRate≈59.29`; `flutter test test/core/utils/stats_parser_test.dart` → red on totalGames
- [ ] T2 (RED) `stats_parser_test.dart:70-74` — replace `isA<Map>()` with `rawMatches['KDA']==4.5` + `contains('Tasa de Victorias')` → fails
- [ ] T3 (GREEN) `lib/features/parser/utils/mlbb_parser.dart` totalGames — insert `(?:Partidas?\s*(?:Jugadas?|Totales?))\s*[:\s]*(\d+)` at index 1 (caseSensitive:false); T1 green; number-first intact
- [ ] T4 (GREEN) `mlbb_parser.dart:35` — mvp[0] `(\d+)\s*MVP` → `(\d+)[^\S\n]*MVP`; 'texto realista' green (mvpCount 320, not 1929)
- [ ] T5 (REFACTOR/verify) `flutter test test/core/utils/stats_parser_test.dart test/core/utils/stats_validator_test.dart`

## Phase 2 — Test suite health

- [ ] T6 `test/features/navigation/bloc/navigation_bloc_test.dart:138-145` — rewrite as blocTest `verify: (b) => expect(b.getBadge(2), equals('3'))`; nav suite green
- [ ] T7 rewrite `test/widget_test.dart` as boot smoke: `SharedPreferences.setMockInitialValues({})` → `di.init()` → pump `MyApp` → pump 500ms + 4s + flush; expect `MainScreen`, `UploadHomeScreen`, `AppBar` 'Inicio'; full `flutter test` green

## Phase 3 — Dead code removal (grep BEFORE each deletion; `flutter analyze` + `flutter test` AFTER)

- [ ] T8 delete `session_repository.dart` + `session_repository_impl.dart` (grep: self-pair only)
- [ ] T9 delete `upload_source_button.dart` + `upload_image_picker_card.dart` (grep zero)
- [ ] T10 delete `main_bottom_bar.dart`; re-grep `salomon` zero → drop `pubspec.yaml:19` dep + `flutter pub get`
- [ ] T11 delete 7 barrels `{upload,settings,navigation,parser,insights,ocr,history}.dart` + `settings/domain/usecases/usecases.dart` (grep zero each)
- [ ] T12 delete 4 core widgets `{app_info_banner,empty_state_widget,error_state_widget,session_summary_card}.dart` (grep zero)
- [ ] after each delete: `flutter analyze` clean + `flutter test` green

## Phase 4 — DI/nav consistency

- [ ] T13 `injection_container.dart` — remove :3 http import + :83 `http.Client()`; grep `package:http` zero
- [ ] T14 `injection_container.dart:203` — `totalDestinations: 7` → `3` (matches 3 nav items, main_screen.dart:47-81); nav suite green
- [ ] T15 `main_screen.dart:188-222` — delete `_PlaceholderPage` (grep: never instantiated)
- [ ] T16 move `base_usecase.dart` → `lib/core/usecases/`; rewrite 4 imports (ocr_bloc.dart:4, recognize_image_text.dart:5, get_settings.dart:5, copy_to_clipboard.dart:4); grep old path zero; analyze clean

## Phase 5 — Docs sync

- [ ] T17 `skills-lock.json` — remove both supabase entries (:4-15) → `{"version":1,"skills":{}}`; grep `supabase` zero
- [ ] T18 `.opencode/skills/insight-architecture/SKILL.md:41` drop http line; `README.md:152` heroes tree line (SHOULD)
- [ ] T19 `test/all_tests.dart` :9, :22, :41 — remove stale stats_bloc comment/import/call; grep `stats_bloc` zero
- [ ] T20 `GEMINI.md` :6-9 + :17 — remove `.agents/skills` + supabase refs (untracked — commit at user's discretion); final grep `supabase|heroes|todos_page|stats_bloc|http` over docs/lockfile/skills zero