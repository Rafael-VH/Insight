# Exploration: OCR Preprocessing — 2x Bicubic Upscale

Change: `ocr-preprocess-upscale` · Date: 2026-09-27 · Phase: explore · Status: ready for proposal

## Problem Statement

`google_mlkit_text_recognition` drops or mangles numbers on real MLBB season-stat share images.
Measured root cause (`docs/ocr-alternativas-investigacion.md`, smoke test 2026-09-27 on
`docs/muestra/*.jpg`): the game-generated share image is **1023x632 px** (verified this session
with `System.Drawing` — both samples, `Format24bppRgb`, 72 DPI) and characters average **~15 px tall**
(60 of 88 words < 16 px), **below ML Kit's documented 16 px minimum / 24 px ideal per character**.

A reference on-device engine read every digit correctly after a **2x bicubic upscale** (char avg
30 px, 0 words < 16 px) on the same files. Grayscale+contrast was tested and **HURTS** (adds noise)
— rejected. Spanish accents (Daño, Máx., Héroe, Participación) read fine at 2x.

## Current State

### End-to-end flow (all paths verified by reading the code)

```
UploadScreen._onImageUploadPressed(source, mode)          upload_screen.dart:76-79
  ├─> _controller.startProcessing(mode)                   upload_controller.dart:91-102
  └─> context.read<OcrBloc>().add(ProcessImageEvent(source))

OcrBloc.on<ProcessImageEvent> _onProcessImage             ocr_bloc.dart:19-28
  ├─> emit(OcrLoading())
  └─> pickImageAndRecognizeText(ImageSourceParams(source))          ← RecognizeImageText

RecognizeImageText.call(params)                           recognize_image_text.dart:13-23
  ├─> repository.pickImage(params.source)   → Either<Failure,String>
  ├─> if imagePath.isEmpty → Left(ImagePickerFailure('No image selected'))
  └─> repository.recognizeText(imagePath)                 ← THE SEAM'S CALLER

OcrRepositoryImpl                                       ocr_repository_impl.dart:14-35
  └─> dataSource.pickImage(source) / dataSource.recognizeText(imagePath)

OcrDataSourceImpl                                       ocr_datasource.dart
  :24-40  pickImage  → imagePicker.pickImage(source, imageQuality: 100) → returns pickedFile.path
  :43-59  recognizeText(imagePath)
    :45     final inputImage = InputImage.fromFile(File(imagePath));   ★★★ INSERTION SEAM ★★★
    :46     await textRecognizer.processImage(inputImage);
    :48-50  if recognizedText.text.isEmpty → throw TextRecognitionFailure('No text found in image')
    :52     return OcrResultModel.fromRecognizedText(recognizedText, imagePath)

OcrResult (OcrSuccess) → UploadStateHandlerMixin.handleOcrState / _handleOcrSuccess
                                                 upload_state_handler_mixin.dart:54-58
  └─> uses ONLY state.result.recognizedText + state.result.imagePath
     └─> StatsUploadController.handleOcrSuccessWithDiagnostics(text, imagePath)
                                                    upload_controller.dart:104-160
        ├─> StatsParser.parseStatsWithDiagnostics(text, mode)      ← PURE REGEX ON String
        └─> _uploadedImages[mode] = imagePath            upload_controller.dart:129
             └─> UploadModeCard(imagePath: ...)          upload_screen.dart:165  (thumbnail display)
```

### Key answers

**Q1 — Path or bytes?**
The datasource receives a **filesystem path (`String`)**, never bytes. `InputImage` is built with
`InputImage.fromFile(File(imagePath))` (`ocr_datasource.dart:45`), which is `InputImageType.file`:
- Android → `InputImage.fromFilePath(context, Uri.fromFile(...))` — native decode, native EXIF
  (`InputImageConverter.java`, `file` branch).
- iOS → `[UIImage imageWithContentsOfFile:]` + `visionImage.orientation = image.imageOrientation`
  — native EXIF (`MLKVisionImage+FlutterPlugin.m:22-27`).

**Bounding boxes are DEAD DATA.** `OcrResultModel.fromRecognizedText` (`ocr_result_model.dart:14-35`)
does populate `TextBlock`/`TextLine` with `Rect boundingBox`, and `OcrResult.textBlocks` exposes them —
but a repo-wide grep for `boundingBox|textBlocks|TextBlock|TextLine` returns matches **only** in the
entity definitions, the model construction, and `OcrResult`. No consumer. `StatsParser` is 100% regex
over `String text`; `mlbb_validator.dart` takes `PlayerPerformance`. **2x coordinates cannot break the
parser.** (These entities are candidates for the dead-code cleanup, but that is out of scope here.)

**Q2 — Where must the upscale go?**
Exactly one place: **`ocr_datasource.dart:45`**, between `recognizeText(imagePath)` entry and
`textRecognizer.processImage(inputImage)`. That is the last moment the code still holds a path and has
not yet built an `InputImage`. Upstream (`OcrBloc`, `RecognizeImageText`, `OcrRepositoryImpl`) carry a
`String` and know nothing about pixels — putting image work there would drag pixel concerns into the
domain layer and break the Dependency Rule (`openspec/config.yaml:30`). The file already imports
`dart:io` (line 1) and `google_mlkit_text_recognition` (line 4), so `InputImage` construction stays local.

**Existing image utilities / deps: NONE.** `pubspec.yaml` has no `image`, no `flutter_image_compress`,
no `extended_image`, no `exif`. There is no image-manipulation code anywhere in `lib/`. However
`dart:ui` is already in use in the OCR feature (`import 'dart:ui'` in `text_block.dart:1` and
`text_line.dart`), so a `dart:ui`-only implementation requires **zero pubspec changes**.

## Approaches

### 1. `dart:ui` decode → bicubic upscale → PNG temp file → `InputImage.fromFile` ★ RECOMMENDED

```
bytes  = await File(imagePath).readAsBytes()
codec  = await ui.instantiateImageCodec(bytes)
frame  = await codec.getNextFrame()
rec    = ui.PictureRecorder()
canvas = Canvas(rec, Rect.fromLTWH(0, 0, 2*w, 2*h))
canvas.drawImageRect(frame.image, srcRect, dstRect, Paint()..filterQuality = ui.FilterQuality.high)
up     = await rec.endRecording().toImage(2*w, 2*h)
png    = (await up.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List()
tmp    = File('${(await getTemporaryDirectory()).path}/ocr_up_$ts.png')..writeAsBytes(png)
InputImage.fromFile(tmp)   // unchanged call shape
```

- **Pros:** zero new dependencies (`path_provider` is already a dep for `getTemporaryDirectory()`);
  `InputImage.fromFile(...)` keeps its exact current shape (one variable swap); ML Kit still decodes
  natively so **format detection and EXIF keep working on the pass-through branch**; channel payload
  drops from ~10.3 MB (raw RGBA) to ~0.3 MB (PNG on disk).
- **Cons:** transient memory ~25 MB; PNG encode adds ~100-250 ms on device; needs a temp file lifecycle.
- **Effort:** Low.

### 2. `dart:ui` → `rawRgba` → `InputImage.fromBitmap`

- **Pros:** no file I/O at all; supported on both platforms (verified in `InputImageConverter.java`
  `bitmap` branch and `bitmapToVisionImage` on iOS).
- **Cons:** **10.3 MB method-channel payload** plus a **2.58 M-iteration Java unpacking loop**
  (`InputImageConverter.java` hand-builds an `IntBuffer` from raw RGBA). Also **loses EXIF entirely** —
  `fromBitmap` takes `rotation` defaulting to 0, and the datasource has no EXIF parser.
- **Effort:** Low. **Rejected on cost, not complexity.**

### 3. `image` pub package (`decodeImage` + `copyResize(interpolation: bicubic)`)

- **Pros:** most explicit; pure-Dart so the resize itself is host-testable against a byte fixture.
- **Cons:** new dependency; pure-Dart resize of 2.58 M px needs an isolate; pure-Dart JPEG decode is
  slower than the platform Skia path. Its only real advantage is host-testability of the resize —
  and the part that genuinely needs a test (the threshold) is pure Dart with no image at all.
- **Effort:** Medium. **Not recommended**; `dart:ui` already covers the requirement.

### 4. ML Kit built-in behavior — VERIFIED: NONE EXISTS

Read the plugin source, not the docs. `TextRecognizer.java:81,94` goes
`InputImageConverter.getInputImageFromData(...)` → `textRecognizer.process(inputImage)` with **zero**
resize/scale. Nothing in `google_mlkit_commons` references image dimensions either (`model_manager.dart`
is about remote model download only). Conclusion: **there is no `MaxImageDimension` to design around,
and no built-in upscale.** 2046x1264 is unremarkable to ML Kit.

### ⚠ API trap discovered by reading the plugin source (would cost a day)

The brief sketched `toByteData(format: png)` + `InputImage.fromBytes`. **That does not work.**
`InputImage.fromBytes` takes **raw pixel buffers**, never an encoded image:
- Android (`InputImageConverter.java`, `bytes` branch) accepts only `ImageFormat.NV21` or `YV12`;
  anything else returns `result.error("ImageFormat is not supported.")` — a hard error, not a
  silent failure.
- iOS (`bytesToVisionImage`) builds a `CVPixelBuffer` from the raw bytes with a FourCC — encoded PNG
  bytes yield garbage or a crash.
- And `InputImage.fromBitmap(bitmap: pngBytes, ...)` **silently corrupts**: the Android raw-RGBA
  branch is taken whenever `metadata` is present, so PNG bytes are reinterpreted as pixels. The
  `BitmapFactory.decodeByteArray` JPEG/PNG fallback is unreachable through `fromBitmap`.

### Rejected shortcut

`image_picker`'s `maxWidth`/`maxHeight` only **downscale** (never upscale) and act at pick time, not
OCR time. Useless for this requirement.

### Lazier variant considered and rejected

`ui.instantiateImageCodec(bytes, targetWidth: 2*w, targetHeight: 2*h)` scales in one call — no Canvas,
no `PictureRecorder`. Rejected: the resampling filter becomes the codec's internal default, so the spec
can no longer state "bicubic" — the single thing the smoke test actually establishes. ~8 extra lines
buy a stated, testable guarantee.

## Recommendation

**Approach 1**, inserted at `ocr_datasource.dart:45`, gated by a pure-Dart threshold function, with a
mandatory fallback to the original file.

`FilterQuality` is verified against the local Flutter 3.47.2 SDK
(`bin/cache/pkg/sky_engine/lib/ui/painting.dart`, `enum FilterQuality`):
- `FilterQuality.high` → *"a standard **Bicubic** algorithm which uses a 3rd order..."* — exactly the
  algorithm the smoke test proved works.
- `FilterQuality.none` → **Nearest Neighbor** — blocky, and a silent quality regression.

⚠ A bare `canvas.drawImage(...)` silently uses `none`. The filter MUST be set explicitly.

### Threshold rule

What governs OCR is character height in px; at the datasource we only have dimensions. The proxy is
the **shorter side** (verified against the stated cases):

| Input | Short side | Decision |
|---|---|---|
| `1023x632` game share image (production) | 632 | **2x** → 2046x1264, chars ≈30 px ✔ matches proven smoke test |
| `1080x2400` manual screenshot | 1080 | **pass-through** ✔ requirement satisfied |
| `632x1023` rotated share image | 632 | **2x** (short side, not width) |

**Proposed rule: upscale x2 when `min(width, height) < 800`.**

Derivation: the corpus gives 632 px short side ⇒ ~15 px chars ⇒ ratio 0.0237. ML Kit's floor is
16 px/char ⇒ pass-through is safe at short side ≥ 16/0.0237 ≈ **675 px**. Picking **800** puts the
boundary at ≈19 px chars — 19% above ML Kit's floor, giving margin for the two share-image variants
and JPEG artifacts, while still classifying both real-world cases correctly.

Cap/output bound: at the threshold, output short side is 1600; the realistic case is 2046x1264.
Peak decoded RGBA = 2046·1264·4 ≈ **10.3 MB**, plus source decode ≈2.6 MB and recorder surface
≈10.3 MB ⇒ ~25 MB transient.

### Two mandatory design constraints

1. **Graceful degradation.** Any throw/OOM in the upscale path MUST fall back to
   `InputImage.fromFile(File(imagePath))` with the original file and complete the OCR normally. The
   upscale is an accuracy optimization and MUST NOT become a new hard-failure mode. This also yields a
   free A/B signal: log which branch ran.
2. **Keep the ORIGINAL path in the result.** `OcrResultModel.fromRecognizedText(recognizedText, imagePath)`
   (`ocr_datasource.dart:52`) MUST keep receiving the original `imagePath`, not the temp path, because
   `StatsUploadController._uploadedImages[mode] = imagePath` (`upload_controller.dart:129`) feeds
   `UploadModeCard` (`upload_screen.dart:165`) for thumbnail display. Handing it a temp path would make
   the UI depend on a file the OS can delete. Easy to get wrong — a one-argument decision.

## Affected Areas

| Path | Impact |
|---|---|
| `lib/features/ocr/data/datasources/ocr_datasource.dart` | **Modified** — seam at :45; the upscale + threshold call. Only file needing production change. |
| `test/features/ocr/data/datasources/ocr_upscale_threshold_test.dart` (new) | **New** — pure-Dart threshold unit tests |
| `test/all_tests.dart` | **Modified** — import the new suite (:11-29) |
| `openspec/config.yaml` | **Modified** — stale test-count/failure line (see Tests) |
| `lib/core/injection/injection_container.dart` | Unchanged — `TextRecognizer(script: TextRecognitionScript.latin)` at :86 is already the right model for es/pt/en |
| `pubspec.yaml` | **Unchanged** — zero new dependencies |
| `lib/features/ocr/presentation/bloc/*`, `recognize_image_text.dart`, `ocr_repository*.dart`, `mlbb_parser.dart`, `upload_controller.dart` | **Unchanged** — all consume `String` only |
| `lib/features/ocr/domain/entities/{text_block,text_line}.dart`, `ocr_result.dart` | **Unchanged** (dead `boundingBox` data noted for a future cleanup) |

## Tests

**Existing OCR test surface: ZERO.** `test/` holds 8 files (`all_tests.dart`, `widget_test.dart`,
`stats_parser_test`, `stats_validator_test`, `navigation_bloc_test`, `settings_entities_test`,
`stats_collection_model_test`, `entities_test`, `stats_upload_controller_test`). There is no
`ocr_datasource_test.dart`, no `InputImage` reference anywhere in `test/`, no `TextRecognizer` fake,
no ML Kit mock. `openspec/config.yaml:14-19` sets `integration: false`, `e2e: false` — nothing can
exercise the real engine in CI. `recognizeText` is untestable today and stays untestable. Do not try.

Per testman's **Extract-Before-Mock** rule, extract the decision into a pure Dart function with no
image and no Flutter engine:

```dart
int? upscaleFactorFor(int width, int height)   // null = pass-through
bool shouldUpscale(int width, int height)
```

Scenarios to pin (Given/When/Then, RFC 2119):
1. `1023x632` → factor 2 (production corpus)
2. `1080x2400` → pass-through (explicitly required)
3. `800x600` → 2
4. `800x800` → pass-through (boundary pinned on ONE side, not fuzzy)
5. `632x1023` → 2 (short side, not width)
6. zero/negative dimension → pass-through (defensive; never upscale garbage)
7. `1023 * 2 == 2046` and `632 * 2 == 1264` (cap is honored)

**The resize itself stays untested in CI — an accepted ceiling, not an oversight.** The correctness
evidence is the on-device smoke test. State this in the spec so verify does not invent a fake test for
it. What IS worth pinning: the **fallback path** is exercised (non-image / unreadable path ⇒ OCR still
completes on the original file instead of raising a new exception type).

⚠ `test/all_tests.dart` is a **hand-maintained barrel** (:11-29). A new test file that is not imported
there silently never runs.

⚠ **Correction to project config:** `openspec/config.yaml:7` claims *"187 tests total; 4 pre-existing
failures (stats_parser, navigation_bloc, widget smoke test)"*. Verified this session by running
`flutter test`: **191 tests, "All tests passed!", 0 failures.** The config line is stale. sdd-apply
should treat the safety-net baseline as **GREEN**. Flagged here, not fixed — explore writes no code.

## Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | **EXIF orientation silently dropped on the upscale branch.** Verified: the pass-through branch is safe (iOS sets `imageOrientation`; Android lets ML Kit read EXIF from the file URI). But the upscale branch writes a fresh PNG via `dart:ui`, which carries no EXIF, and `ui.instantiateImageCodec` does not apply EXIF rotation. A rotated camera capture under 800 px short side would be OCR'd unrotated — and would present as "OCR is broken", not as a rotation bug. | Low (the only rotated input is a camera capture, normally 1080x2400 ⇒ pass-through) | Silent wrong output | Spec pins an on-device check with a rotated sample and accepts the documented limitation for the game's unrotated share images. If correctness is required: read EXIF orientation from the JPEG APP1 segment (tag `0x0112`) in ~40 lines of pure Dart, no new dep, unit-testable against `docs/muestra/*.jpg` as a byte fixture. **Decision belongs in spec.** |
| 2 | **Memory spike on the upscale branch** — ~25 MB transient (2.6 MB source + 10.3 MB upscaled surface + 10.3 MB recorder + PNG buffer). Survivable on modern Android, OOM-able on low-end. This is a **new** failure mode the current code does not have. | Medium on low-end | OCR fails / crash | The mandatory try/catch fallback to the original file. Also: `2046x1264` is a hard output bound, not unbounded. |
| 3 | **Silent quality regression if the filter is left at the default.** A bare `canvas.drawImage(...)` uses `FilterQuality.none` (Nearest Neighbor) ⇒ blocky 2x that could be *worse* than the original and would look like "upscale hurt" — the same trap grayscale already fell into. | Medium if unimplemented | Regresses accuracy invisibly | Spec MUST require bicubic (`FilterQuality.high`); code MUST set it explicitly; add a `filterQuality` grep check to review. |
| 4 | **Processing time.** PNG encode of 2046x1264 adds ~100-250 ms on device on top of ML Kit's own work. | Certain | Minor | `OcrLoading` (ocr_bloc.dart:20) and `_isProcessing[mode]` already drive a spinner. No new UI state needed. |
| 5 | Temp-file accumulation in the OS cache dir. | Low | Disk | Write to `getTemporaryDirectory()` (OS-managed) and/or overwrite a fixed filename per run. |

## Open Questions for Spec

1. **EXIF policy** — accept the limitation, or implement the ~40-line APP1 parser? (Risk #1)
2. **Exact threshold constant** — `800` is derived, not measured on a wider corpus. Confirm, or pin
   `800` with the derivation recorded as rationale.
3. **Should the upscale branch be user-visible/toggleable** (a Settings flag), or silently automatic?
   Ponytail says automatic; a toggle is a second code path to test. Recommend automatic for v1.
4. **Logging/telemetry** — the fallback needs a `debugPrint` (or `extractionLog` entry) noting which
   branch ran, so a device smoke test can confirm the upscale actually fired. Confirm the sink.

## Ready for Proposal

**Yes.** The flow is fully mapped, the seam is a single line, the approach is chosen with the API traps
verified against plugin source rather than assumed, and the test surface is a pure function with zero
mocks. The one decision that genuinely belongs to the user is the **EXIF policy** (Open Question 1) —
it changes the scope from ~1 file to ~2. Everything else is ready to pin as requirements.
