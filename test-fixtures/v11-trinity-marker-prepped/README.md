# test-fixtures/v11-trinity-marker-prepped/

OT-derived golden fixture for BD-136 round-trip migration testing
(spec entry M-8). Captures the verified-clean state of the
OptiquityTrader trinity files after the three-pass marker-prep cycle
documented in `maintenance-docs/v11-implementation/PACK-REVIEW-OT-TRINITY-PREP.md`.

## What this is

Three trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) prepped
per the BD-136 Shape A + Shape B specification with `renamed-from`
override annotations. Each file has marker pairs in both shapes:

| File         | Pairs | Shape A | Shape B |
|--------------|-------|---------|---------|
| CLAUDE.md    | 14    | 10      | 4       |
| AGENTS.md    | 13    | 8       | 5       |
| GEMINI.md    | 14    | 10      | 4       |

Total 6 `renamed-from` annotations (2 per file): one single-value
(Xcode), one multi-value-collapse (Swift coding rules → two canonical
sources). Trinity-symmetric except for the AGENTS.md `## Agent
behavior` Shape B override (FP2-7 Option B).

The original OT snapshot carried one additional project-owned marker in
the file **preamble** (a repository-overview intro above the first `## `
heading). A preamble marker has no enclosing H2/H3 host, so it is neither
Shape A nor Shape B — the shipped merger rejects it (fail-loud). Under
BD-136 C9b that intro was relocated to a valid in-section placement — a
`### Repository overview` H3 at the head of the `## Project addenda`
seed (the seed-slot exception permits project H3 dumps). The rendered
project content is preserved verbatim; only its marker geometry became
valid. That relocation is why each file carries one fewer pair than the
raw `fd6a0d6` capture (CLAUDE/GEMINI 15→14, AGENTS 14→13).

## Provenance

| Field | Value |
|---|---|
| Source repo | `/Users/david/Developer/OptiquityTrader/` |
| Source commit | `fd6a0d6` (`chore: v11 prep — wrap trinity customizations in BD-136 markers`) |
| Snapshot date | 2026-05-10 |
| Pack-side baseline | v10.1 canonical at `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/` |
| Verification | `maintenance-docs/v11-implementation/PACK-REVIEW-OT-TRINITY-PREP.md` (initial review + FP1 + FP2 + FP3 verifications, all PASS) |
| BD-136 spec at capture time | Twice-amended (Shape A + Shape B + `renamed-from` + Project-addenda seed-slot exception); commit `a2a2446` |

## Intended use

Round-trip migration test (BD-136 spec entry M-8): given the v10.1
canonical trinity as BASE, the v11 canonical trinity as THEIRS, and
this fixture as OURS, the marker-aware merger MUST produce the same
fixture content byte-identical (zero manual reconciliation needed).
The test asserts:

- All `renamed-from` annotations correctly suppress their canonical
  counterparts in merge output (no duplicate H2s).
- All Shape A body extensions preserved byte-identical.
- All Shape B sections preserved byte-identical.
- `## Project addenda` seed-slot exception honored (project H3 dump
  permitted inside the seed Shape A wrap).
- No `[CONDITIONAL]` prefix appears anywhere in the output.

## Why this is a static snapshot, not a build.sh-generated fixture

Existing fixtures (`v10-minimal`, `v10-realistic-ot`, `v11-flat-file`,
`v11-tracker-on`, `existing-project-mid-dev`) are deterministically
rebuilt from scratch by `build.sh`. This fixture is different — it
captures real-world prep work done in an external repo (OT) and is
not derivable from pack inputs alone. The fixture is intentionally
frozen at the source commit listed above; future OT trinity changes
do not affect this fixture.

If BD-136 implementation later prefers a synthesized variant for
deterministic regeneration, that should be added as a SIBLING fixture
(e.g., `v11-trinity-marker-prepped-synthesized`), not by overwriting
this real-world snapshot.

## Cross-references

- `BACKLOG.md` BD-136 — Trinity marker-section preservation pattern
  (Shape A + Shape B) + PM-chat authoring procedure
- `maintenance-docs/v11-implementation/PACK-REVIEW-OT-TRINITY-PREP.md`
  — full review history (initial + FP1 + FP2 + FP3 verifications)
- `supporting-docs/INSTALL-PROCEDURES.md` — `[CONDITIONAL]` H2
  retirement + Shape B transition for kept conditional sections
