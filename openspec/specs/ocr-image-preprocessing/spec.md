# OCR Image Preprocessing Specification

## Purpose

Normalize image resolution before ML Kit OCR so characters clear the engine's 16px floor.
Preprocessing is an accuracy optimization only: it MUST never become a new hard-failure mode.

## Requirements

### REQ-1: The upscale decision is a pure function of the shorter side

The system MUST upscale by exactly 2x when `min(width, height) < 800`, and MUST pass the image
through untouched otherwise. The decision MUST come from a pure function with no image decode and no
Flutter-engine dependency.

| Input (w x h) | min side | Decision |
|---|---|---|
| 1023x632 (production corpus) | 632 | 2x → 2046x1264 |
| 1080x2400 (screenshot) | 1080 | pass-through |
| 800 x m | 800 | pass-through (boundary) |
| 799 x m | 799 | 2x |
| 632x1023 (rotated share) | 632 | 2x — shorter side, not width |
| 0 or negative | <= 0 | pass-through |
| any other aspect ratio | — | governed by the shorter side only |

#### Scenario: Production corpus upscales

- GIVEN `test/fixtures/ocr/temporadaActual.jpg` at 1023x632
- WHEN the decision is evaluated
- THEN upscale by 2 producing 2046x1264
- AND `test/fixtures/ocr/todasLasTemporadas.jpg` behaves identically

#### Scenario: The threshold is exclusive at 800

- GIVEN an image whose min side is exactly 800
- WHEN the decision is evaluated
- THEN the image is passed through unmodified

#### Scenario: Degenerate dimensions never upscale

- GIVEN a zero or negative dimension
- WHEN the decision is evaluated
- THEN the image is passed through and no resize is attempted

### REQ-2: Resampling MUST be explicitly bicubic

The system MUST pass `interpolation: Interpolation.cubic` as a named argument to the resize call.
A resize relying on the default filter is a rejection of this spec.

#### Scenario: Review-time grep guard

- GIVEN the modified `ocr_datasource.dart`
- WHEN a reviewer greps it for `Interpolation.cubic`
- THEN a named-argument call MUST be present
- AND absence means the default-filter trap was not avoided — REJECT

### REQ-3: EXIF orientation is baked before resizing

The system MUST bake EXIF orientation before resizing, so a rotated input is never upscaled sideways.

#### Scenario: Rotated input stays upright

- GIVEN a rotated JPEG under the threshold
- WHEN preprocessing runs
- THEN the upscaled output is visually upright

### REQ-4: Handoff to the recognizer is a temporary PNG file

The upscale branch MUST write a PNG into `getTemporaryDirectory()` and hand that path to the
file-based `InputImage` constructor. It MUST NOT use the byte-buffer constructor (raw NV21/YV12
pixel buffers only).

### REQ-5: Preprocessing failure degrades to the original file

If decoding throws OR yields no image, the system MUST hand the ORIGINAL file to the recognizer,
complete OCR normally, and MUST NOT surface a new exception type.

#### Scenario: Decoder throws

- GIVEN a decoder that throws
- WHEN `recognizeText` runs
- THEN the original file is recognized and no new exception surfaces

#### Scenario: Decoder yields no image

- GIVEN a decoder that returns null instead of throwing
- WHEN `recognizeText` runs
- THEN the original file is recognized and no new exception surfaces

### REQ-6: The result always reports the original path

`OcrResult.imagePath` MUST equal the original input path on BOTH branches, because it feeds the
thumbnail UI.

#### Scenario: Upscale branch reports the original

- GIVEN preprocessing succeeded
- THEN `imagePath` is the original path, not the temp path

#### Scenario: Fallback branch reports the original

- GIVEN preprocessing failed
- THEN `imagePath` is the original path

### REQ-7: Accepted verification ceiling

Device-side recognition correctness is verified ON-DEVICE ONLY. No CI test may simulate or fake it.
The unit-testable surfaces are exactly: the full preprocess function against the REAL
`test/fixtures/ocr/*.jpg` fixtures producing a 2046x1264 PNG; the threshold function returning true
for (1023,632), false for (1080,2400), false for exactly (800,m), and true for (799,m); and the
fallback returning the original path.

#### Scenario: The new suite is reachable

- GIVEN `test/all_tests.dart` is a hand-maintained barrel that lists each suite explicitly
- WHEN the new test file is added
- THEN it MUST also be registered in that barrel
- AND the passing-test count MUST exceed the 191 green baseline
