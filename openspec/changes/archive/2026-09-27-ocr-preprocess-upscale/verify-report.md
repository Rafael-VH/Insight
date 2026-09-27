# Verify Report: ocr-preprocess-upscale

**Change**: `ocr-preprocess-upscale` (2x bicubic upscale before ML Kit OCR)
**Date**: 2026-09-27
**Mode**: Strict TDD (runner `flutter test`, `strict_tdd: true`)
**Verdict**: **PASS WITH WARNINGS** — behavior is fully conformant; the warnings are process-traceability and one spec-level memory gap, not defects in the shipped code.

---

## 1. Completeness

| Task (tasks.md) | Commit | Status | Acceptance criterion verified against code |
|---|---|---|---|
| T1 `1.1` pubspec `image` | `693649d` | ✅ | `pubspec.yaml` declares `image`, lock resolves 4.10.1; no OCR analyze issue |
| T2 `1.2` config.yaml baseline | `693649d` | ✅ | `187 tests / 4 failures` → `191 tests / 0 failures` (diff confirmed) |
| T3 `1.3` fixtures | `6d058e8` | ✅ | `git ls-files test/fixtures/ocr` = 2 files; SHA256 **byte-identical** to `docs/muestra/*`; tests read only `test/fixtures/` |
| T4 `2.1` threshold predicate | `6c822a8` | ✅ | `shouldUpscaleForOcr` at `ocr_datasource.dart:23-26`; 12 table cases green |
| T5 `2.2` preprocess core | `4fdd907` | ✅ | `preprocessImageForOcr` at `:31-50`; `Interpolation.cubic` literal at `:47` |
| T6 `3.1` datasource wiring | `36c0fe0` | ✅ | `_prepareInputImage` `:126-145`; temp PNG `:138`; `finally` cleanup `:102-115`; `imagePath` original `:96` |
| T7 `4.1` barrel + analyze + test | `450c094`, `9d078b6` | ⚠️ | Both suites registered (`all_tests.dart:32-37,56-57`); 213 > 191 ✅. AC text said "analyze 0 issues" — actual 11 pre-existing `info` lints (see W3) |

**Tasks complete: 7/7** (T7 substantively complete, AC wording imprecise).
**New tests delivered: 22** (17 in `ocr_image_preprocess_test.dart` + 5 in `ocr_datasource_test.dart`) — measured by `flutter test test/features/ocr` = `+22: All tests passed!`. Arithmetic: 191 + 22 = 213. ✅

---

## 2. Build & Test Execution

```
$ flutter test --reporter expanded
01:21 +213: All tests passed!          EXIT=0
```

```
$ flutter analyze
flutter : 11 issues found. (ran in 125.1s)
```
All 11 are `info` level, and **none** are in `ocr_datasource.dart`, `ocr_image_preprocess_test.dart`, or `ocr_datasource_test.dart`. Locations: `splash_screen.dart` (3), `history_list_card.dart` (3), `mlbb_parser.dart` (1), `create_custom_theme_bottom_sheet.dart` (3), `upload_screen.dart` (2). **0 new issues** — matches the apply claim.

**Coverage** (`flutter test --coverage`, changed file only):

| File | Lines hit | Line % | Uncovered lines | Rating |
|---|---|---|---|---|
| `lib/features/ocr/data/datasources/ocr_datasource.dart` | 31/39 | 79.5% | 64, 67, 71, 77, 79, 147, 150, 152 | ⚠️ |

All 8 uncovered lines are **pre-existing, untouched** code (`pickImage` 64-79, `copyTextToClipboard` 147-152). **Every one of the 36 lines this change added is covered** — effective changed-code coverage is 100%. The 79.5% is a pre-existing gap in `pickImage`/`copyTextToClipboard`, not a regression.

**Format**: `dart format --set-exit-if-changed` flags `ocr_datasource.dart` for exactly 2 lines (71, 152). Both are **pre-existing** >80-char lines present at `8d1f8e6` (verified). The new code this change added is format-clean; the 3 new >80 lines are comments, which `dart format` does not wrap. `apply-progress` Learned #9 is accurate and the decision to revert unrelated reformatting was correct.

---

## 3. Spec Compliance Matrix

| REQ | Scenario | Test | Result |
|---|---|---|---|
| REQ-1 | 1023x632 corpus upscales → 2046x1264 | `ocr_image_preprocess_test.dart:41-51` + `:53-63` (both fixtures) | ✅ COMPLIANT |
| REQ-1 | Threshold exclusive at 800 | `:19-20` — `(800,1200)✗` and `(1200,800)✗` | ✅ COMPLIANT |
| REQ-1 | 799 → upscale | `:21-22` — `(799,1200)✓` and `(1200,799)✓` | ✅ COMPLIANT |
| REQ-1 | 632x1023 (shorter side, not width) | `:17` | ✅ COMPLIANT |
| REQ-1 | 1080x2400 pass-through | `:18` | ✅ COMPLIANT |
| REQ-1 | Degenerate / non-positive never upscale | `:23-25` — `(0,0)✗ (-1,500)✗ (500,-1)✗` | ✅ COMPLIANT |
| REQ-1 | Decision is pure, no decode, no Flutter engine | `:30-37` calls `shouldUpscaleForOcr` directly, no mocks, no bindings | ✅ COMPLIANT |
| REQ-2 | Grep guard: literal `Interpolation.cubic` named arg | grep of `ocr_datasource.dart` → `line 47: interpolation: Interpolation.cubic,` | ✅ COMPLIANT |
| REQ-3 | Rotated input stays upright (baked before resize) | `:65-87` — in-memory `orientation=6` JPEG → 1264x2046 transposed | ✅ COMPLIANT |
| REQ-4 | Temp PNG in `getTemporaryDirectory()`, `fromFile` not `fromBytes` | `ocr_datasource_test.dart:82-107` — asserts temp path, real on-disk 2046x1264 PNG; `fromBytes` appears only in a comment (`ocr_datasource.dart:124`) | ✅ COMPLIANT (exceeds design — see C8) |
| REQ-5 | Decoder yields no image → original file | `ocr_datasource_test.dart:127-136` (real garbage bytes) + `:89-95` | ✅ COMPLIANT |
| REQ-5 | Decoder **throws** → original file | `:139-146` exercises the **same** `catch (_)` funnel via a missing-file read failure, not a throwing decoder | ⚠️ PARTIAL — same funnel, different trigger; explicitly accepted in design D3 |
| REQ-5 | No new exception type surfaces | `:134-135` — recognizer receives original, `recognizeText` returns normally | ✅ COMPLIANT |
| REQ-6 | Upscale branch reports original path | `ocr_datasource_test.dart:103` — `result.imagePath == original.path` while ML Kit got the temp path | ✅ COMPLIANT |
| REQ-6 | Fallback branch reports original path | `ocr_datasource_test.dart:135` | ✅ COMPLIANT |
| REQ-7 | Suite registered in `test/all_tests.dart` | `all_tests.dart:32-37` (imports) + `:56-57` (`main()` calls), both suites | ✅ COMPLIANT |
| REQ-7 | Passing count exceeds 191 | 213 measured | ✅ COMPLIANT |
| REQ-7 | Ceiling: no faked accuracy test | No test asserts recognition text/accuracy; suite stops at the `InputImage` handoff | ✅ COMPLIANT |

**Compliance summary: 18/19 scenarios fully compliant, 1 PARTIAL (accepted by design D3).**

### Threshold boundary table — independently re-derived
`shouldUpscaleForOcr(w,h) = w>0 && h>0 && (w<800 || h<800)`. Because the clause is a **disjunction**, it is exactly equivalent to `min(w,h) < 800` for positive inputs, and the `w>0 && h>0` guard makes non-positive a pass-through. All 7 spec rows verified against the 12 live cases. ✅

---

## 4. Adversarial Review of `ocr_datasource.dart` (full read)

| # | Check | Result | Evidence |
|---|---|---|---|
| A1 | Does `finally` cleanup run on the **success** path, not just exceptions? | ✅ YES | `finally` at `:102-115` is attached to the `try` wrapping `processImage`, so it fires on normal return. Proven at runtime: `ocr_datasource_test.dart:105` asserts the temp file is **gone** after a successful OCR whose mock read the file's real bytes at `:98-101`. Both success (`:105`) and failure (`:122`) are asserted. |
| A2 | Is `_prepareInputImage` outside the `try`? | ✅ CORRECT | `:85` destructures before `try` at `:86`. Safe because the helper's own `catch (_)` at `:142` can never throw, so `upscaledTemp` is always bound before `finally` needs it. |
| A3 | Any `path_provider` call on the pass-through branch? | ✅ NO | `:131-133` returns `(InputImage.fromFile(original), null)` **before** `getTemporaryDirectory()` at `:135`. No MethodChannel hop when no upscale is needed. |
| A4 | Double `bakeOrientation`? | ✅ NOT FUNCTIONALLY | Our `:37` bakes and **clears** `orientation` (`bake_orientation.dart:22`). `copy_resize.dart:33-35` then sees no orientation and skips rotation. Correctness safe. See S3 for the residual copy cost. |
| A5 | Temp path leaked into `OcrResult`? | ✅ NO | `:96` passes `imagePath` (the original parameter), never `upscaledTemp`. Asserted at `:103` and `:135`. |
| A6 | `filterQuality` / interpolation correctness | ✅ CORRECT | `Interpolation.cubic` named explicitly at `:47`. Resistor caveat S4. |
| A7 | Can a delete error be re-labelled `TextRecognitionFailure`? | ✅ NO | Delete is wrapped in its own nested `try/catch` at `:109-113`. A throw there is swallowed as best-effort, so it can never replace the in-flight exception from the outer `catch` at `:97`. |
| A8 | Temp-name collision between overlapping OCRs? | ✅ NO | `ocr_upscale_${DateTime.now().microsecondsSinceEpoch}.png` at `:138`; read+decode+resize elapse between calls. Asserted by regex `ocr_upscale_\d+\.png$` at `:95-96`. |
| A9 | Temp written durably before the native read? | ✅ YES | `writeAsBytes(upscaled, flush: true)` at `:140`. |
| A10 | Memory ceiling on low-end devices | ⚠️ **W1/W2** | See findings. The corpus case peaks ~25 MB transient (safe). The pass-through case pays ~2× the decoded size for a decision it then discards. |

---

## 5. Design Coherence

| Decision | Followed? | Notes |
|---|---|---|
| D1 — one pure fn + one pure predicate, no result object | ✅ Yes | `Uint8List?` return, no dimension field; test reads dims back out of the PNG |
| D2 — EXIF synthesized in-memory, no new fixture | ✅ Yes | `:69-73`; **self-proving** guard at `:76` asserts orientation 6 survives re-encode, so a broken EXIF would fail the test rather than silently pass |
| D3 — no wrapper, no fake decoder, no injectable seam | ✅ Yes | `preprocessImageForOcr(Uint8List bytes)` takes only bytes (`:31`); no decoder parameter exists anywhere in the file. Garbage bytes hit the real `findDecoderForData` magic-byte sniff. |
| D4 — unique temp name, cleanup in `finally`, nested try/catch | ✅ Yes | `:138`, `:102-115`, `:109-113` |
| D5 — pure core as top-level functions in `ocr_datasource.dart`; zero new production files | ✅ Yes | Core at `:15-50`, above `abstract class` at `:52`. `git log --name-status` shows `ocr_datasource.dart` as the **only** modified file under `lib/`. |
| Design contract signature | ✅ Yes + minor addition | Matches exactly, plus `kOcrUpscaleFactor = 2` (`:18`) extracted to replace magic `2`. Pure refactor improvement. |
| No grayscale / contrast anywhere | ✅ Yes | grep for `grayscale|contrast|adjustColor` across the datasource and both test files: **0 hits** |
| Single seam | ⚠️ Stale line ref | Design cites `ocr_datasource.dart:45`; the preprocessing seam is now `_prepareInputImage` at `:126` (`:45` is inside the pure core). Same single entry point, stale citation — see S5. |
| Test plan (6 unit groups, zero mocks) | ✅ Exceeded | 22 tests. Datasource suite uses a mocktail `TextRecognizer` + one mocked `path_provider` channel — a deviation *beyond* the design, in the right direction (see C8). |

---

## 6. Strict TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported in the **required artifact** | ❌ | `apply-progress` (#794) has a `Task status` bullet list but **no `TDD Cycle Evidence` table**, and no `openspec/changes/ocr-preprocess-upscale/apply-report.md` exists. → **C1** |
| Evidence recoverable elsewhere | ⚠️ | Session summary #795 carries prose RED notes: T3/T4 "RED: method not found", T6 "RED: 2 failures proving ML Kit still received the original path". Not the mandated artifact, not a table. |
| All tasks have tests | ✅ | 5/7 tasks touch behavior; all 5 have dedicated, green, passing test files. T1/T2/T7 are config/doc tasks correctly marked `TDD: no` in tasks.md. |
| RED confirmed (tests exist) | ✅ | Both test files exist and are registered in the barrel. |
| GREEN confirmed (tests pass now) | ✅ | 22/22 OCR tests green in this run. |
| Triangulation adequate | ✅ | Threshold: 12 cases vs 7 planned. Boundary tested in **both** orientations. Both fixtures tested. EXIF + garbage + pass-through = 3 distinct `null`-adjacent behaviors with distinct expected values. |
| Safety net for modified files | ⚠️ | `ocr_datasource.dart` was modified by all 5 code commits; no baseline capture is reported per-commit. The 191-green baseline is asserted in spec/tasks but not recorded as a per-task safety-net measurement. → W4 |

**TDD Compliance**: 5/7 checks pass; the 2 failures are evidence-**traceability**, not evidence of a skipped cycle.

### Test layer distribution

| Layer | Tests | Files | Tools |
|---|---|---|---|
| Unit (pure Dart, zero mocks) | 17 | 1 | `flutter test` |
| Integration (wiring: real datasource + mocked platform channel + mocked ML Kit) | 5 | 1 | `flutter test` + mocktail |
| E2E (real ML Kit / on-device) | 0 | 0 | not installed — **by design, REQ-7** |
| **Total** | **22** | **2** | |

No test uses a tool absent from the project's testing capabilities. ✅

### Assertion Quality Audit (Step 5f)

| File | Line | Assertion | Issue | Severity |
|---|---|---|---|---|
| — | — | — | No tautologies, no ghost loops, no type-only-only assertions, no implementation-detail/CSS coupling | — |

**✅ All assertions verify real behavior.** Specific strengths:
- Mock/assertion ratio in `ocr_datasource_test.dart`: 2 mock classes + 1 channel mock vs 22 assertions — healthy (≤3 mocks/file).
- `isNotNull` is always paired with a concrete value assertion (`:46-50`, `:58-62`, `:80-85`) — never standalone.
- `ocr_datasource_test.dart:98-101` reads the **actual bytes on disk inside the recognizer mock** and decodes them to 2046x1264. This proves REQ-4 end-to-end without native ML Kit, and it is the single strongest assertion in the change.
- `:153` `isEmpty` on filtered temp files is an "orphan empty check", but it is non-vacuously constrained: the sibling upscale test proves the same `tempDir` **does** receive a PNG under the other branch. Noted as S6, not a finding.

---

## 7. Findings

### CRITICAL

| # | Item | Evidence | Location |
|---|---|---|---|
| **C1** | **Missing `TDD Cycle Evidence` table.** Strict TDD was active; `apply-progress` (#794) reports task status as prose bullets and there is no `apply-report.md` in `openspec/changes/ocr-preprocess-upscale/`. The mandated RED/GREEN/TRIANGULATE/REFACTOR/Safety-Net table is absent from the artifact downstream phases consume. Mitigation: prose RED evidence exists in session summary #795, and the end state is independently verified green by this phase. This is a **process/traceability defect, not a behavior defect** — but it means RED-before-GREEN is not auditable from the committed history, because tests and implementation land in the *same* work-unit commit (`6c822a8`, `4fdd907`). | `strict-tdd-verify.md` Step 5a: "If NO 'TDD Cycle Evidence' table found: Flag: CRITICAL" | `openspec/changes/ocr-preprocess-upscale/` (no `apply-report.md`); engram #794 |

### WARNING

| # | Item | Evidence | Location |
|---|---|---|---|
| **W1** | **Pass-through branch pays 2× the decoded image size for a decision it discards.** `bakeOrientation` is called at `:37` **before** the `shouldUpscaleForOcr` guard at `:39`, and `bake_orientation.dart:13` starts with `final bakedImage = Image.from(image);` — an unconditional full-frame deep copy that runs even when the answer is "no upscale". A 12 MP camera photo (4032×3024 ≈ 48.8 MB decoded) transiently allocates ~98 MB just to be passed through untouched. On a 2 GB Android device near its heap ceiling this is a real pressure point. **This is spec-legal and fixable without touching the spec**: `min(w,h)` is invariant under the EXIF 90° rotations, so evaluating the predicate on `decoded.width/height` yields an identical decision; REQ-3 only requires baking *before resizing*, which the reordered form still satisfies. | `image-4.9.1/lib/src/transform/bake_orientation.dart:13` (unconditional `Image.from`); REQ-3 wording "bake EXIF orientation before resizing" | `ocr_datasource.dart:37-39` |
| **W2** | **No ceiling on upscale output dimensions (spec gap, not an implementation defect).** `preprocessImageForOcr` computes `width*2 / height*2` with no upper bound, because REQ-1 mandates 2x whenever min side < 800. An elongated input (e.g. 760×12000 long chat screenshot) yields 1520×24000 ≈ 36.5 M px ≈ 146 MB output, plus source and baked copies — peak > 250 MB transient. The real corpus (1023×632 → 2046×1264) peaks ~25 MB and is safe, so this is a latent risk, not an observed one. Adding a cap would **violate REQ-1 as written**; this needs a spec amendment, not a code change. | REQ-1 as written; `ocr_datasource.dart:42-49` | `ocr_datasource.dart:42-49` |
| **W3** | **T7's acceptance criterion is worded wrong and was met in substance only.** AC reads "analyze 0 issues"; the actual result is 11 pre-existing `info` lints (`flutter analyze` exits 1 because of them). Substantively correct — 0 new issues, none in any changed file — but the AC as written is unsatisfiable and would misdirect a future executor. | `tasks.md:55`; analyze output shows 11 `info`, 0 in changed files | `openspec/changes/ocr-preprocess-upscale/tasks.md:55` |
| **W4** | **Plan documents contain a wrong boundary case, never corrected.** `design.md:121` and `tasks.md:43` both assert `(800,600)✗` (no upscale). `min(800,600) = 600 < 800`, so the correct answer is **upscale**. The implementation and tests are RIGHT (`(800,1200)✗`); the planning docs are wrong. `apply-progress` Learned #5 caught it during apply, but neither file was amended, so a future reader of design.md would derive a broken predicate. | `design.md:121`, `tasks.md:43` vs `ocr_image_preprocess_test.dart:19` | `design.md:121`, `tasks.md:43` |
| **W5** | **Task numbering in `apply-progress` does not match `tasks.md`.** Engram labels T2 = fixtures and T5 = "cover tests"; `tasks.md` has T2 = config.yaml and T5 = preprocess core. Commit hashes and file contents all verify, but cross-referencing by task ID is ambiguous. Also, **all 7 tasks in `tasks.md` remain unchecked `- [ ]`** — testman TDD step 6 ("mark task complete `[x]`") was not performed. | engram #794 vs `tasks.md:33-55` | `tasks.md:33-55` |
| **W6** | **REQ-5 "Decoder throws" is covered by proxy, not literally.** The test at `ocr_datasource_test.dart:139-146` triggers the `catch (_)` funnel with a *missing file* (a `readAsBytes` failure), not a decoder that throws mid-decode. The funnel is identical and this is explicitly accepted in design D3 and `apply-progress` Learned #3, so it is PARTIAL rather than UNTESTED — but a reviewer checking REQ-5 literally will find no throwing-decoder test. | spec REQ-5 scenario 1; design D3 | `ocr_datasource_test.dart:139-146` |

### SUGGESTION

| # | Item | Evidence | Location |
|---|---|---|---|
| **S1** | Redundant local: `final File? temp = upscaledTemp;` is a pointless re-alias. `upscaledTemp` comes from a `final` record pattern at `:85`, which Dart already treats as definitely assigned, so the alias at `:107` can be deleted and `upscaledTemp` used directly. | Definite-assignment rules; no compiler complaint either way | `ocr_datasource.dart:107` |
| **S2** | No test asserts that `getTemporaryDirectory()` is **not** invoked on the pass-through branch. The code is correct by inspection (A3), but the MethodChannel-avoidance rationale is unprotected against regression. A `verify()`-style count on the mocked channel would close it. | — | `ocr_datasource_test.dart:126-155` |
| **S3** | `copy_resize.dart:29-31` silently forces `interpolation = Interpolation.nearest` when `src.hasPalette`. REQ-2's named argument is necessary but not sufficient for *paletted* sources. Real picker output (JPEG/PNG) is never paletted, so this is theoretical — already documented in `apply-progress`/design Learned #3. | `image-4.9.1/lib/src/transform/copy_resize.dart:29-31` | `ocr_datasource.dart:43-48` |
| **S4** | The `finally` cleanup's second call `bakeOrientation` inside `copyResize` performs an unconditional `Image.from` deep copy even when the orientation is already cleared. Package-internal and unavoidable from here; worth knowing when sizing W1/W2. | `image-4.9.1/.../bake_orientation.dart:13` | — |
| **S5** | Design and the engram design artifact cite the seam as `ocr_datasource.dart:45`. Post-change, `:45` is inside `copyResize`'s argument list; the actual seam is `_prepareInputImage` at `:126`. Same single entry point, stale citation. | `design.md:7`, engram #791 | `design.md:7` |
| **S6** | `ocr_datasource_test.dart:153` asserts the temp dir has no PNGs without a same-setup non-empty companion. It is non-vacuously constrained by the sibling upscale test (which proves the dir *does* receive a PNG on the other branch), so this is a nit about test-locality, not a phantom assertion. | — | `ocr_datasource_test.dart:148-154` |

---

## 8. Observations That Strengthen Confidence (not findings)

- **C8 — coverage exceeded the design.** `design.md:60` and `tasks.md:60` state REQ-4's temp write has **no** automated coverage. The apply phase delivered it anyway: mocking the `plugins.flutter.io/path_provider` channel (name verified against `path_provider_platform_interface-2.1.2`) plus a mocktail `TextRecognizer` that captures the real `InputImage` and reads the on-disk bytes mid-flight. This proves REQ-4, the `ocr_upscale_\d+\.png` naming, and the `finally` cleanup on **both** success and failure paths — all with no native ML Kit. A design deviation in the strictly better direction.
- Fixtures are SHA256-identical to `docs/muestra/`, so the hermetic `test/fixtures/ocr/` pinning of design Risk 1 is byte-faithful while keeping the suite machine-independent.
- The EXIF test's self-proving guard (`ocr_image_preprocess_test.dart:76`) is the right way to prevent a test that silently passes when the orientation never travels in the bytes.
- `finally` cleanup is proven on the success path (`:105`), which is the case most likely to be forgotten.

---

## 9. Known Ceiling — Explicitly NOT a Finding

Per **REQ-7**, device-side recognition correctness is verified **on-device only**. No CI test simulates or fakes recognition accuracy, and this phase added none. Coverage of this change stops at the `InputImage` handoff: the suite proves *what bytes ML Kit receives* and *that the original path is preserved*, but **not** that a Double cell photo now yields correct digits. That is an **accepted spec ceiling, not a gap in the implementation** — and per the apply plan, manual QA on a physical device with the Double cell share photo is the required closing step.

---

## 10. Verdict

**PASS WITH WARNINGS**

All 7 tasks are present in the 7 commits with their acceptance criteria satisfied in substance. 213/213 tests green (exit 0), 0 new analyzer issues, and **100% coverage of every line this change added**. 18 of 19 spec scenarios are fully compliant; the single PARTIAL (REQ-5 throwing decoder) was explicitly accepted in design D3. The REQ-2 grep guard, both fallback branches, REQ-6 on both branches, the temp naming, and the nested-`try/catch` `finally` are all verified in source **and** at runtime — including the success-path cleanup that is the easiest thing to get wrong. The one CRITICAL (C1) is an artifact-format defect: the mandated `TDD Cycle Evidence` table is missing from `apply-progress`, so RED-before-GREEN is not auditable from history, though the underlying work is independently verified green. The WARNINGs are one spec-level memory gap (W1/W2, correctly routed to a spec amendment rather than a code change), three planning-document defects (W3/W4/W5), and one proxy-covered scenario (W6).
