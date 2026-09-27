# Tasks: OCR Preprocess — 2x Bicubic Upscale

Change: `ocr-preprocess-upscale` · Phase: tasks · Date: 2026-09-27

Status: **COMPLETE** — all 7 tasks implemented locally (commit `693649d`..`9d078b6`), 213/213 green; docs amended per verify findings (C1/W3/W4/W5, 2026-09-27).

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~200 text lines + 2 binary fixtures (~128 KB) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR, 7 work-unit commits |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

Binary fixtures add 0 text lines but ~128 KB of attach weight — reviewers skim, they do not read them.

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 (T1–T3) | Dependable test foundation | PR 1 | No behavior change |
| 2 (T4–T5) | Pure, host-testable core | PR 1 | RED→GREEN per unit |
| 3 (T6–T7) | Datasource wiring + green suite | PR 1 | Verified by test run |

## Phase 1: Foundation

- [x] 1.1 (T1) Add `image: ^4.10.1` under the OCR deps in `pubspec.yaml`; run `flutter pub get`.
  AC: pub get resolves, `flutter analyze` clean. Files: `pubspec.yaml`, `pubspec.lock`. Effort S. Deps: none. TDD: no. → commit `693649d`.
- [x] 1.2 (T2) Fix stale baseline in `openspec/config.yaml:7` → 191 tests, 0 failures.
  AC: line no longer claims `187 / 4 failures`. Files: `openspec/config.yaml`. S. Deps: none. TDD: no. → commit `693649d`.
- [x] 1.3 (T3) Copy `docs/muestra/{temporadaActual,todasLasTemporadas}.jpg` into `test/fixtures/ocr/`.
  AC: both committed byte-identical, `git ls-files test/fixtures/ocr` returns 2, tests never read `docs/`. Files: 2 JPGs. S. Deps: none. TDD: no. → commit `6d058e8`.

## Phase 2: Pure Core (`ocr_datasource.dart`, top-level)

- [x] 2.1 (T4) RED then GREEN `kOcrMinSideForUpscale` + `shouldUpscaleForOcr(int,int)`.
  AC: REQ-1 table green — (1023,632)✓ (1080,2400)✗ **(800,1200)✗** (799,600)✓ (632,1023)✓ (0,0)✗ (-1,500)✗ (note: (800,600) would upscale — min side 600; corrected per verify W4). Files: `ocr_datasource.dart`, new test file. S. Deps T1,T3. **TDD: strict.** → commit `6c822a8`.
- [x] 2.2 (T5) RED then GREEN `preprocessImageForOcr(Uint8List) → Uint8List?`.
  AC: both fixtures → non-null PNG measuring 2046x1264; in-memory `orientation=6` JPEG → 1264x2046 (transposed); garbage bytes → `null`; grown 1600x1000 → `null`. Review guard: `interpolation: Interpolation.cubic` is a literal named argument in the file. M. Deps T4. **TDD: strict.** → commit `4fdd907` (core) + `450c094` (suite).

## Phase 3: Datasource Wiring

- [x] 3.1 (T6) Rewire `recognizeText`: read bytes → preprocess → temp `ocr_upscale_<microsecondsSinceEpoch>.png` via `getTemporaryDirectory()` → `InputImage.fromFile` → `finally` delete in nested `try/catch`; keep `OcrResultModel.fromRecognizedText(..., imagePath)` on the original.
  AC: fallback test injects a mocktail `TextRecognizer`, feeds a garbage file, asserts the captured `InputImage` path == original and no temp file remains; suite still green. M. Deps T5. **TDD: wiring verified at task level, not red-first** (path_provider channel is out of REQ-7's ceiling). → commit `36c0fe0`.

## Phase 4: Verification

- [x] 4.1 (T7) Register the suite in `test/all_tests.dart` (import + `main()` call); run `flutter analyze` + `flutter test`.
  AC: barrel lists `ocr_image_preprocess_test`; analyze 0 NEW issues (11 pre-existing info lints accepted); full suite green and passing count > 191. S. Deps T6. TDD: no. → commit `9d078b6`.

## Notes

- REQ-2 is a **review-time grep guard**, not a test — do not add a source-scanning test (testman REGLA 4).
- REQ-4's temp write has no automated coverage (inside REQ-7's on-device ceiling). Add a path_provider channel mock if that ceiling is ever lifted.
- Deviates from spec fixture path: `test/fixtures/ocr/`, not `docs/muestra/` (untracked + published Pages site). Design Risk 1.
- No CI task: `.github/workflows/docs.yml` never runs `flutter test`.
