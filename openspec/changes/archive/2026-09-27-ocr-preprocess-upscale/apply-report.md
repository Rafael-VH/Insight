# Apply Report: OCR Preprocess — 2x Bicubic Upscale

Change: `ocr-preprocess-upscale` · Phase: apply report (regenerated per verify C1) · Date: 2026-09-27

## Task Status

| Task | Title | Status | Commit | Tests |
|------|-------|--------|--------|-------|
| T1 | Dependency `image ^4.10.1` + config.yaml baseline | ✅ | `693649d` | — |
| T2 | Real share fixtures → `test/fixtures/ocr/` | ✅ | `6d058e8` | — |
| T3 | `shouldUpscaleForOcr` threshold predicate | ✅ | `6c822a8` | 12 |
| T4 | `preprocessImageForOcr` bicubic core | ✅ | `4fdd907` | 13 |
| T5 | Core coverage suite (EXIF, null, pass-through) | ✅ | `450c094` | 17 |
| T6 | Datasource wiring (temp PNG → ML Kit, fallback, cleanup) | ✅ | `36c0fe0` | 5 |
| T7 | Format + final analysis | ✅ | `9d078b6` | — |

Final: `flutter test` 213/213 green (191 baseline + 22 new). `flutter analyze` 11 issues — all pre-existing info lints, 0 new.

## TDD Cycle Evidence

Strict TDD mode (runner: `flutter test`). RED→GREEN per unit; wiring verified at task level (path_provider channel is outside REQ-7's ceiling).

| Task | RED (what failed first) | GREEN (proof) |
|------|-------------------------|---------------|
| T3 | `shouldUpscaleForOcr` method-not-found | 12 boundary-table tests pass |
| T4 | `preprocessImageForOcr` method-not-found | Fixtures → 2046x1264 PNG dims read back |
| T5 | Core suite RED cycles | 17 green: EXIF orientation=6 transposes 1264x2046; garbage bytes → null; 1600x1000 → null |
| T6 | 2 RED failures: mock recognizer still received the ORIGINAL path | 5 wiring tests green: capture shows 2046x1264 temp PNG path, `finally` removes it, `OcrResult.imagePath` == original |
| T1/T2/T7 | — (mechanical dep/fixture/format work) | `flutter pub get` resolves; fixtures byte-identical; analyze/test green |

## Reviewed Findings (verify phase → archive-ready)

| Finding | Resolution |
|---------|-----------|
| C1 — missing TDD evidence table / apply-report | Closed by this report + regenerated apply-progress |
| W3 — tasks.md AC "analyze 0 issues" (actual: 11 pre-existing info) | tasks.md reworded: "analyze 0 NEW issues" |
| W4 — `(800,600)` labeled no-upscale in plan docs (min=600 → upscale) | tasks.md + design.md corrected to `(800,1200)` as the false boundary case |
| W5 — apply-progress numbering vs tasks.md, unchecked boxes | tasks.md checkboxes checked; numbering 1.1/2.1/3.1/4.1 == T1/T4/T6/T7 aligned |
| W6 — REQ-5 throw branch via missing-file proxy | Accepted in design D3 (same `catch (_)` funnel) |

## Accepted Risks (user decision 2026-09-27)

- **W1**: `bakeOrientation` runs before the predicate — ~98 MB transient on a 12 MP pass-through photo. Accepted: real corpus peaks ~10 MB; the reorder is a one-line knob if on-device QA shows memory pressure.
- **W2**: no output-dimension ceiling (REQ-1 as written) — a 760x12000 input would blow up to ~146 MB. Accepted: elongated inputs are not real for this app; adding a cap requires a spec amendment (deferred).

## Pending (human step, not automatable)

- On-device QA: run a real stats share photo (1023x632) through the app and confirm digits are read correctly. This validates the motivating bug; coverage stops at the InputImage handoff (REQ-7 ceiling).