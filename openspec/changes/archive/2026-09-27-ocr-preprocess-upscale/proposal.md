# Proposal: OCR Preprocessing — 2x Bicubic Upscale

## Intent

MLBB share images are **1023x632** with ~15px characters — under ML Kit's 16px floor. 60/88 words fall below it, so digits get dropped and stats are wrong. A 2x bicubic upscale made a reference engine read every digit.

## Scope

**In:** preprocess in `recognizeText` before `InputImage` is built; `image: ^4.10.1` engine (decode → orient → resize → encode); 2x when `min(w,h) < 800`; fall back to the original.

**Out:** engine switch; ML Kit changes (verified: no built-in resize); grayscale/contrast (tested — hurts); parser changes; Settings toggle.

## Capabilities

**New — `ocr-image-preprocessing`:** normalize resolution before OCR — threshold, 2x bicubic upscale, EXIF orientation, temp-file handoff, graceful degradation.

**Modified:** None.

## Key Decisions

| Decision | Choice | Why |
|---|---|---|
| Engine | `image ^4.10.1` (MIT, pure Dart) | Authorized dep; kills hand-rolled Canvas + EXIF parser |
| EXIF | `bakeOrientation` | **Closes** the explore risk outright |
| Threshold | `min(w,h) < 800` | 19% margin. 1023x632→2046x1264; 1080x2400 pass-through |
| Handoff | temp PNG + `path_provider` | `fromBytes` takes raw NV21/YV12 only |
| Failure | fall back to original | Never hard-fail on an accuracy tweak |
| Result path | keep **original** `imagePath` | Feeds the `UploadModeCard` thumbnail |

## Approach

One seam: `ocr_datasource.dart:45`. `decodeImage` → `bakeOrientation` → `copyResize(cubic)` → `encodePng` → `getTemporaryDirectory()` → `InputImage.fromFile`. Verified: `decodeImage` is nullable, `bakeOrientation` is a **top-level fn**, `copyResize` defaults to `nearest`.

## Affected Areas

| Path | Impact |
|---|---|
| `ocr_datasource.dart` | Modified — seam :45 |
| `pubspec.yaml` | Modified — add `image` |
| `test/.../ocr_upscale_preprocess_test.dart` | New — pure Dart, `docs/muestra/` fixtures |
| `test/all_tests.dart` | Modified — barrel, else it never runs |
| `openspec/config.yaml` | Modified — stale test count (real: 191 green) |
| Rest of OCR chain | Unchanged — `String` only |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| ~25MB transient on 2x decode | Med (low-end) | Try/catch fallback; hard bound 2046x1264 |
| Temp files accumulate | Low | `getTemporaryDirectory()`, fixed name per run |
| PNG re-encode degrades JPG source | Low | PNG is lossless; resample is the only lossy step |

## Rollback Plan

Revert the pubspec entry, the `:45` branch, and the test file + barrel import. No migration, no state, no API change.

## Dependencies

- `image: ^4.10.1` — new; MIT; pure Dart; SDK `^3.0.0` fits; pulls `archive ^4.0.9`
- `path_provider ^2.1.5` — already present

## Success Criteria

- [ ] 1023x632 → 2046x1264; 1080x2400 untouched
- [ ] Failed preprocessing still completes OCR on the original
- [ ] `OcrResult.imagePath` is original on both branches
- [ ] `flutter analyze` clean; `flutter test` above the 191 baseline
- [ ] Resize is on-device only — specs MUST NOT invent a fake CI test
