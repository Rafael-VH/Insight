# Design: OCR Preprocessing — 2x Bicubic Upscale

Change: `ocr-preprocess-upscale` · Phase: design · Date: 2026-09-27

## Technical Approach

One pure, host-testable core at the single seam, `ocr_datasource.dart:45`. It converts image **bytes**
into upscaled PNG **bytes**, or a `null` sentinel meaning "hand over the original". The datasource
owns all I/O and degradation.

    read original bytes ──throws─┐
      └─ preprocessImageForOcr  [pure, no I/O]
           decodeImage == null ───────────┐
           bakeOrientation()     (REQ-3)  │
           shouldUpscale false   (REQ-1) ─┤→ null ─┐
           copyResize ×2 cubic    (REQ-2)  │        │
      null → InputImage.fromFile(original) ┘        │
      else → write temp PNG → fromFile(temp) ───────┘
             └─ await processImage() → finally: delete temp (best effort)
         └─ OcrResult(imagePath: originalPath)  (REQ-6)

## Architecture Decisions

### D1 — Core shape: one pure function, one pure predicate

| Option | Tradeoff | Decision |
|---|---|---|
| One pure fn + one predicate | ~20 lines, fully host-testable | **Chosen** |
| Class + result object | More surface, no extra coverage | Rejected |
| Inline in `recognizeText` | Untestable, binds Flutter | Rejected |

`preprocessImageForOcr` returns `Uint8List?`; the test reads dimensions back out of the PNG, so no
dimension field is carried. `null` is one sentinel for both "decode failed" and "pass-through" — both
hand the caller the original, so the distinction drives no behaviour.

### D2 — REQ-3 EXIF: synthesize a rotated JPEG in-memory (neither (a) nor (b))

| Option | Tradeoff | Decision |
|---|---|---|
| (a) Commit a rotated fixture | New binary asset, still only structural | Rejected |
| (b) Accept the gap in writing | Leaves a real path untested forever | Rejected |
| Synthesize at test time | ~6 test lines, no fixture, real `bakeOrientation` | **Chosen** |

`JpegEncoder` writes `image.exif` and `JpegDecoder` reads it back (`jpeg_encoder.dart:61`,
`jpeg_data.dart:337`); `IfdDirectory.orientation` is a public setter on tag `0x0112`. The test sets
`orientation = 6` and re-encodes: 1023x632 → bake → 632x1023 → **1264x2046**. The transposed output
proves the bake ran.

### D3 — REQ-5 null branch: no wrapper, no fake decoder

| Option | Tradeoff | Decision |
|---|---|---|
| (a) Injectable-decoder wrapper | Production seam existing only for tests | Rejected |
| (b) Undecodable bytes | Zero production surface; hits the real null path | **Chosen** |

`decodeImage` is `decoder?.decode(...)` and `findDecoderForData` sniffs magic bytes
(`formats.dart:264`, `:191`), so a non-image `Uint8List` returns `null` for real. The **throw** branch
shares that funnel, covered by the one `try/catch` returning the original path — inside REQ-7.

### D4 — Temp file: unique name, delete in `finally`

| Option | Tradeoff | Decision |
|---|---|---|
| Fixed name (proposal) | Overlapping OCRs clobber each other | Rejected |
| `ocr_upscale_<microsecondsSinceEpoch>.png` | One line, no dep, collision-free | **Chosen** |
| Delete right after `fromFile` | Unsafe — native read happens during the await | Rejected |

`InputImage.fromFile` only stores a path; Android resolves it inside `processImage`
(`TextRecognizer.java:81`). Cleanup sits in `finally` — after the native read, on success *and*
failure — in its own nested `try/catch` so a delete error is never re-labelled `TextRecognitionFailure`.
Built by interpolation: `package:path` is undeclared and trips `depend_on_referenced_packages`.

### D5 — REQ-2's grep guard pins the core into `ocr_datasource.dart`

That guard greps *this* file for `Interpolation.cubic`. A separate file fails it; duplicating the call
to satisfy grep would lie to the reviewer. The core is therefore top-level functions in the same file,
above the classes. Cost: the test transitively pulls ML Kit — harmless under `flutter test`, no channel
touched at import. Benefit: **zero new production files**.

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/features/ocr/data/datasources/ocr_datasource.dart` | Modify | Pure core (3 symbols) + rewire `recognizeText` |
| `pubspec.yaml` | Modify | Add `image: ^4.10.1` |
| `test/features/ocr/data/datasources/ocr_image_preprocess_test.dart` | Create | Pure Dart, no mocks |
| `test/fixtures/ocr/{temporadaActual,todasLasTemporadas}.jpg` | Create | Corpus copies — Risk 1 |
| `test/all_tests.dart` | Modify | Register the suite (REQ-7) |
| `openspec/config.yaml:7` | Modify | Replace stale `187 / 4 failures` with the measured count |

## Interfaces / Contracts

```dart
const int kOcrMinSideForUpscale = 800;

/// REQ-1. Pure. `min(width, height) < 800`; non-positive sides never upscale.
bool shouldUpscaleForOcr(int width, int height) =>
    width > 0 && height > 0 &&
    (width < kOcrMinSideForUpscale || height < kOcrMinSideForUpscale);

/// REQ-2/3/5. Pure, no I/O. Upscaled PNG bytes, or `null` = "use the original file".
Uint8List? preprocessImageForOcr(Uint8List bytes) {
  final decoded = decodeImage(bytes);                       // nullable (REQ-5)
  if (decoded == null) return null;
  final upright = bakeOrientation(decoded);                 // REQ-3
  if (!shouldUpscaleForOcr(upright.width, upright.height)) return null;
  return encodePng(copyResize(upright,
      width: upright.width * 2, height: upright.height * 2,
      interpolation: Interpolation.cubic));                // REQ-2
}
```

`recognizeText` keeps its existing exception translation; only the `inputImage` source and the
`finally` block are new. `OcrResultModel.fromRecognizedText(recognizedText, imagePath)` already
receives the original path, so REQ-6 needs no edit.

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit | Threshold table (REQ-1) | (1023,632)✓ (1080,2400)✗ **(800,1200)✗** (799,600)✓ (632,1023)✓ (0,0)✗ (-1,500)✗ (500,-1)✗ — note `(800,600)` is NOT false: min side 600 < 800 → upscale (corrected per verify W4) |
| Unit | Full preprocess (REQ-1/7) | Both fixtures → non-null → `decodeImage` = 2046x1264 |
| Unit | EXIF bake (REQ-3) | In-memory `orientation = 6` → 1264x2046 (transposed) |
| Unit | Null branch (REQ-5) | Garbage `Uint8List` → `null` |
| Unit | Pass-through sentinel | Fixture grown in-memory to 1600x1000 → `null` |
| Unit | Fallback keeps original (REQ-6) | Assert the `null` funnel returns the caller's original `imagePath` |
| E2E | Recognition accuracy | **On-device only** — no CI test (REQ-7) |

Zero mocks, zero devices. `copyResize` forces `nearest` for *paletted* sources internally; picker
output is never paletted, so REQ-2's named argument stands.

## Migration / Rollout

No migration, no state, no API change. Rollback = revert the pubspec line, the `:45` branch, the test
file, and the two fixtures.

## Open Questions

- [x] **Risk 1 (RESOLVED)** — `docs/muestra/` is untracked and `docs/` is the published GitHub Pages site.
  Design pins `test/fixtures/ocr/`, deviating from the spec's literal path. Confirm, or point the test
  at `docs/` and accept a machine-local, non-hermetic suite. **Decisión: `test/fixtures/ocr/` confirmado
  (user, 2026-09-27) — fixtures are the hermetic committed copy, SHA256-identical to `docs/muestra/`.**
