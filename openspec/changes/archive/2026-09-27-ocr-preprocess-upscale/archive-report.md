# Archive Report: OCR Preprocess — 2x Bicubic Upscale

Change: `ocr-preprocess-upscale` · Phase: archive · Date: 2026-09-27 · artifact_store: both
Archive path (pending move at commit time): `openspec/changes/archive/2026-09-27-ocr-preprocess-upscale/`

## What Changed

A 2x bicubic upscale is inserted before ML Kit OCR so share screenshots (1023x632, ~15px characters)
clear the engine's 16px floor and digits are no longer dropped. Preprocessing is an accuracy
optimization only — every failure path degrades to the original file. The whole feature is one pure,
host-testable core (`shouldUpscaleForOcr` / `preprocessImageForOcr`) plus a private `_prepareInputImage`
seam inside `lib/features/ocr/data/datasources/ocr_datasource.dart`. Zero new production files;
`image: ^4.10.1` is the only added dependency.

## Spec Sync Delta

New capability `ocr-image-preprocessing` — `openspec/specs/` had no OCR domain, so the delta was a
FULL spec, synced by copy (precedent `2026-09-07-cleanup-and-parser-fixes`: 5/5 domains byte-identical
between the change folder and `openspec/specs/`).

| Domain | Action | Details |
|--------|--------|---------|
| `ocr-image-preprocessing` | Created | 7 requirements (REQ-1..REQ-7), 12 Given/When/Then scenarios, 0 modified, 0 removed |

Two deviations from a byte-identical copy, both accuracy corrections, recorded here because the
precedent is a verbatim copy:

1. **Fixture path corrected** — `docs/muestra/*.jpg` → `test/fixtures/ocr/*.jpg` (REQ-1 scenario, REQ-7).
   `docs/muestra/` is UNTRACKED and `docs/` is the published GitHub Pages site, so the literal spec
   path would have put a non-hermetic, machine-local path into the source of truth. Design Risk 1 was
   resolved in favor of `test/fixtures/ocr/` (user-confirmed 2026-09-27); the committed fixtures are
   SHA256-identical to the originals. The archived delta keeps the original wording — the audit trail
   is untouched.
2. **Change-scoped scaffolding dropped** — the `Capability / Change / Phase / Date` metadata line and
   the `## Out of Scope (handoff to sdd-tasks)` section (the stale `config.yaml` count it flagged was
   fixed by task 1.2). Main specs carry requirements only, per the precedent layout.

Unchanged on purpose: REQ-1's "MUST exceed the 191 green baseline" keeps its historical baseline, and
W2's missing output-dimension ceiling is NOT amended here — see accepted risks.

## Final State

| | |
|---|---|
| Commits | `693649d..9d078b6` — 7 work-unit commits, all on `main`, HEAD verified at `9d078b6` |
| Tests | **213/213 green**, exit 0 (191 baseline + 22 new) — `flutter test` verified at HEAD, tree clean for tracked files |
| Analyze | 11 pre-existing `info` lints, 0 new, 0 in any changed file |
| Coverage | 79.5% of `ocr_datasource.dart`; **100% of the 36 added lines**; all 8 uncovered lines are pre-existing untouched code |
| Verify | **PASS WITH WARNINGS** — 18/19 scenarios fully compliant, 1 PARTIAL (accepted in design D3) |
| Tasks | 7/7 complete, all checkboxes `[x]` |
| Artifacts | proposal, exploration, specs, design, tasks, apply-report, verify-report, archive-report |

### Verify findings disposition

| Finding | Disposition |
|---------|-------------|
| C1 — missing TDD Cycle Evidence / no apply-report | **Resolved** — `apply-report.md` + regenerated `apply-progress` (#794, rev 2) |
| W3 — T7 AC "analyze 0 issues" unsatisfiable | **Resolved** — tasks.md reworded "analyze 0 NEW issues" |
| W4 — `(800,600)` labeled no-upscale (min=600 → upscale) | **Resolved** — design.md:121 and tasks.md:45 corrected to `(800,1200)` as the false case |
| W5 — task numbering drift, unchecked boxes | **Resolved** — checkboxes checked; numbering 1.1/2.1/3.1/4.1 aligned to T1/T4/T6/T7 |
| W6 — REQ-5 throw branch covered by a missing-file proxy | Accepted in design D3 (same `catch (_)` funnel) |
| S1–S6 | Not addressed — suggestions, no behavior impact |

## Accepted Risks (user decision 2026-09-27)

- **W1 — `bakeOrientation` runs before the predicate.** `bake_orientation.dart:13` starts with an
  unconditional `Image.from` deep copy, so a 12 MP pass-through photo transiently allocates ~98 MB to
  be discarded. Accepted: the real corpus peaks ~25 MB. **The fix needs no spec change** — `min(w,h)`
  is invariant under EXIF 90° rotations, and REQ-3 only requires baking *before resizing*, so the
  predicate can move above the bake. One-line reorder; trigger it if on-device QA shows memory pressure.
- **W2 — no ceiling on upscale output dimensions.** REQ-1 as written mandates 2x whenever the shorter
  side is under 800, so a 760x12000 long screenshot would yield ~146 MB. Accepted: elongated inputs
  are not real for this app. **A cap would VIOLATE REQ-1 — this needs a spec amendment, not a code
  change.** Deferred.

## Pending Human Step (not automatable)

**On-device QA** — run a real stats share photo (1023x632) through the app on a physical device and
confirm the digits are read correctly. Per REQ-7 the suite deliberately stops at the `InputImage`
handoff: it proves what bytes ML Kit receives and that the original path is preserved, NOT that a
Double cell photo now yields correct digits. No CI test may fake this.

## Traceability (Engram, project `insight`)

| Artifact | Observation |
|----------|-------------|
| proposal | #789 |
| spec | #790 |
| design | #791 |
| tasks | #792 |
| apply-progress (TDD evidence) | #794 |
| session summary | #795 |
| verify-report | #796 |
| archive-report | this document (topic `sdd/ocr-preprocess-upscale/archive-report`) |

## Note for the Orchestrator

- `openspec/config.yaml` was left untouched on purpose: the `191 tests / 0 failures` line is the
  BASELINE, referenced by REQ-7, and task 1.2 already fixed it from a stale `187 / 4 failures`.
  The 191 → 213 transition is recorded here instead.
- The change folder move to `openspec/changes/archive/2026-09-27-ocr-preprocess-upscale/` was NOT
  performed — no commit, push, or file move was made in this phase, per the archive instructions. The
  move belongs in the same commit as the spec sync.
- Untracked `docs/muestra/` and `docs/ocr-alternativas-investigacion.md` were not touched or staged.
