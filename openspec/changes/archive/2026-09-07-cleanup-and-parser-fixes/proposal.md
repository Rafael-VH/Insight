# Proposal: Cleanup & Parser Fixes

## Intent

Post heroes/Supabase removal: 2 real parser bugs, 4 failing tests, dead code, DI/nav drift, stale docs. Goal: green `flutter test`, codebase matching reality.

## Scope

### In Scope (5 phases; each = one work-unit commit; single PR)

1. **Parser correctness (TDD)** — `mlbb_parser.dart`: add Spanish label-first totalGames pattern (`Partidas Jugadas: 800`); fix MVP `(\d+)\s*MVP` → `[^\S\n]*` (cross-line capture). Strengthen `stats_parser_test.dart` (assert totalGames=800; rawMatches keys, not `isA<Map>()`).
2. **Test health (TDD)** — `navigation_bloc_test.dart:138-145` async-escape → awaited/blocTest; replace `widget_test.dart` template with MainScreen smoke test (mock prefs + di.init).
3. **Dead code (zero-import verified)** — `session_repository.dart`+impl (dead twin of HistoryRepository), `upload_source_button.dart`, `upload_image_picker_card.dart`, `main_bottom_bar.dart`, 7 feature barrels `{upload,settings,navigation,parser,insights,ocr,history}.dart`, 4 core widgets, `settings/.../usecases.dart`.
4. **Consistency** — drop phantom `http` import + `http.Client()` DI; `NavigationBloc(totalDestinations: 7→3)`; delete `_PlaceholderPage`; move `base_usecase.dart` → `lib/core/usecases/` (4 imports).
5. **Docs sync** — `skills-lock.json` (drop 2 supabase skills), `insight-architecture/SKILL.md:41`, `docs/` + `GEMINI.md` (Supabase creds/todos_page refs), `all_tests.dart` (stats_bloc_test leftovers).

### Out of Scope

- New parser formats (ranked/season layouts); coverage beyond touched suites
- Committing untracked artifacts (.commandcode/, GEMINI.md, docs/ — user's call)

## Capabilities

### New
- `stats-parser-extraction`: total-games/MVP extraction matches real MLBB Spanish label-first layouts; no cross-line number capture.

### Modified
None — no existing specs; rest is internal quality, spec-invisible.

## Approach

P1-2 test-first (red→green via `flutter test`). P3-5 removals verified by `flutter analyze` + `flutter test` after. Est. < 800 lines.

## Affected Areas

| Area | Impact |
|---|---|
| `lib/features/parser/utils/mlbb_parser.dart` | Modified — totalGames + MVP regex |
| `test/core/utils/stats_parser_test.dart` | Modified — stronger assertions |
| `navigation_bloc_test.dart` / `widget_test.dart` | Modified / Removed |
| `session_repository*.dart`, `upload_source_button.dart`, `upload_image_picker_card.dart`, `main_bottom_bar.dart` | Removed (+ salomon_bottom_bar dep) |
| 7 feature barrels; 4 core widgets; `settings/.../usecases.dart` | Removed |
| `injection_container.dart` | Modified — http phantom, 7→3 |
| `main_screen.dart` | Modified — `_PlaceholderPage` deleted |
| `base_usecase.dart` | Moved → `lib/core/usecases/` |
| `skills-lock.json`, SKILL.md, `docs/`, `GEMINI.md`, `all_tests.dart` | Modified — docs sync |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| salomon_bottom_bar referenced elsewhere | Low (grep: self only) | re-grep before dropping |
| totalDestinations 7→3 breaks nav index expectations | Low | flutter test; align expectations |
| widget_test replacement (delete vs smoke) | Med | smoke test preferred (covers boot path) |
| docs/GEMINI untracked, edits invisible in PR | Med | commit at user's discretion |

## Rollback Plan

Per-commit `git revert`; no data migration; every phase independently reversible.

## Dependencies

None.

## Success Criteria

- [ ] `flutter test` green (0 failures)
- [ ] `flutter analyze` clean
- [ ] totalGames=800 for `Partidas Jugadas: 800`; MVP ignores adjacent-line numbers
- [ ] No lingering imports/deps to deleted items (grep)