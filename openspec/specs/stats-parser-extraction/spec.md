# Stats Parser Extraction Specification

## Purpose

`StatsParser` (lib/features/parser/utils/mlbb_parser.dart) must extract total games and MVP count from real MLBB Spanish label-first layouts, and must never capture a number from an adjacent line. This is the only behavioral capability of the change; it is developed test-first (strict TDD: red → green via `flutter test`).

## Requirements

### Requirement: Spanish label-first total games extraction

The system MUST extract the total games value from label-first Spanish layouts of the form `Partidas Jugadas: <n>` and `Partidas Totales: <n>`. The pattern list `_CompiledPatterns.totalGames` (mlbb_parser.dart:23-31) currently only matches number-first layouts (pattern 1, line 24) and label-first without descriptor (pattern 2, line 25), so label-first layouts with a descriptor return 0 via `_extractWithPatterns` (mlbb_parser.dart:594). The fix MUST also cover lowercase and singular variants (`partida jugada`, `Partida Total`). Case-insensitivity exists for all patterns (`caseSensitive: false`).

#### Scenario: Exact format `Partidas Jugadas: 800`

- GIVEN the text `Partidas Jugadas: 800`
- WHEN `StatsParser.parseStats(text, GameMode.total)` is called
- THEN `totalGames` equals 800
- AND the test at stats_parser_test.dart:112-116 (currently red) passes

#### Scenario: `Partidas Totales` variant

- GIVEN the text `Partidas Totales: 800`
- WHEN the text is parsed
- THEN `totalGames` equals 800

#### Scenario: Singular and lowercase variants

- GIVEN the text `partida jugada 800`
- WHEN the text is parsed
- THEN `totalGames` equals 800

#### Scenario: Value with thousands separator

- GIVEN the text `Partidas Jugadas: 1,500`
- WHEN the text is parsed
- THEN `totalGames` equals 1500 (the parser already strips commas, mlbb_parser.dart:573)

### Requirement: MVP count must not capture a previous-line number

The system MUST NOT match a number followed by `MVP` across a line break. Pattern 1 of `_CompiledPatterns.mvp` (mlbb_parser.dart:35) uses `(\d+)\s*MVP`, where `\s*` matches `\n`, so `Asesinato Doble 1929\nMVP Perdedor 165` yields mvpCount 1929. The separator MUST be non-newline whitespace (e.g. `[^\S\n]*`), so `MVP <n>` badge lines remain the only source of the MVP count.

#### Scenario: Real MLBB fixture — badge wins over adjacent line

- GIVEN the full fixture at stats_parser_test.dart:257-281 (contains `Asesinato Doble 1929` on one line and `MVP 320` on its own line)
- WHEN the text is parsed
- THEN `mvpCount` equals 320, never 1929
- AND the assertion at stats_parser_test.dart:288 (currently red) passes

#### Scenario: Adjacent-line number without badge line

- GIVEN the text `Asesinato Doble 1929\nMVP Perdedor 165` with no `MVP <n>` badge line
- WHEN the text is parsed
- THEN `mvpCount` MUST NOT equal 1929
- AND `mvpCount` equals 0 when no badge is present

### Requirement: Weak tests verify what they claim

The parseStats test (stats_parser_test.dart:15-31) MUST assert the extracted values of its fixture — `totalGames` 1500, `mvpCount` 320, `winRate` ≈ 59.29 — not merely non-null and mode. The rawMatches test (stats_parser_test.dart:70-74) MUST assert specific keys (e.g. `rawMatches['KDA']` equals 4.5 and a `Tasa de Victorias` key exists) instead of the always-true `isA<Map<String, dynamic>>()`.

#### Scenario: Strengthened parseStats assertions go red first

- GIVEN the strengthened test asserting `totalGames` 1500 for `Partidas Totales 1500` (label-first)
- WHEN run against the current parser
- THEN the test fails (red)

#### Scenario: Strengthened rawMatches assertions

- GIVEN the text `59.29 % KDA 4.5`
- WHEN `parseStatsWithDiagnostics` extracts it
- THEN `rawMatches['KDA']` equals 4.5
- AND `rawMatches` contains the `Tasa de Victorias` key

## Acceptance Criteria

- `flutter test test/core/utils/stats_parser_test.dart` passes after the parser fix (red before)
- `totalGames` = 800 for `Partidas Jugadas: 800`; `mvpCount` = 320 in the real fixture