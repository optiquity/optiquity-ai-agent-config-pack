# test-fixtures/v11-trinity-marker-prepped/

**SYNTHETIC** golden fixture for BD-136 round-trip migration testing
(spec entry M-8). Hand-authored, domain-neutral trinity files that
capture a verified-clean marker-prepped state after the BD-136 Shape A +
Shape B marker cycle. The content is a generic macOS content-catalog
sample app — it carries NO real-application name and NO domain-specific
vocabulary, so the fixture is safe to ship in a public repository.

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
(Xcode) and one multi-value-collapse (Swift coding rules → two canonical
sources). Trinity-symmetric except for the AGENTS.md `## Agent
behavior` Shape B override (FP2-7 Option B).

Each file also carries one project-owned marker inside the file
**preamble** relocation history: a preamble marker has no enclosing
H2/H3 host, so it is neither Shape A nor Shape B — the shipped merger
rejects it (fail-loud). The intro was therefore placed at a valid
in-section position — a `### Repository overview` H3 at the head of the
`## Project addenda` seed (the seed-slot exception permits project H3
dumps). The rendered project content is preserved verbatim; only its
marker geometry is valid. Each file carries one Shape A seed pair that
hosts the relocated `### Repository overview` intro.

## Origin — synthetic (recipe)

This fixture is NOT captured from any real project and is NOT
`build.sh`-generated. It is hand-authored to exercise the BD-136
marker-preservation logic with domain-neutral content. To regenerate or
extend it, follow this recipe:

1. **Preserve the marker geometry EXACTLY** (the table above): same
   per-file pair count, same Shape A / Shape B split, the 2
   `renamed-from` annotations per file (one single-value naming
   `## iOS 26 / Xcode 26.3 platform features`, one multi-value-collapse
   naming `## Architecture rules — platform-specific` and
   `## Language-specific coding rules`), and the `## Project addenda`
   Shape A seed hosting a `### Repository overview` H3.
2. **Keep the content domain-neutral.** The sample app is a generic
   macOS content-catalog prototype (types: `Provider`, `Collection`,
   `FeedService`, `Item`, `Entry`, `Event`, `Operation`, `Metric`,
   `Workflow`, `WorkflowSchedule`). Use no real application name and no
   domain-specific (finance/medical/etc.) vocabulary.
3. **Only DOMAIN PROSE varies** between regenerations; the marker
   geometry and section structure are load-bearing and must round-trip
   byte-identical through the marker-aware merger.

The consuming test asserts fixed strings against the synthetic content
(e.g. the repository-overview phrase `content catalog prototype`); if
you change those strings, update the assertions in lock-step in
`scripts/tests/fixture-dependent/test-customization-preserve-bd136.sh`.

## Intended use

Round-trip migration test (BD-136 spec entry M-8): given a drift-free
"new pack canonical" stand-in synthesized from OURS as THEIRS, and this
fixture as OURS, the marker-aware merger MUST produce the same fixture
content byte-identical (zero manual reconciliation needed). The test
asserts:

- All `renamed-from` annotations correctly suppress their canonical
  counterparts in merge output (no duplicate H2s).
- All Shape A body extensions preserved byte-identical.
- All Shape B sections preserved byte-identical.
- `## Project addenda` seed-slot exception honored (project H3 dump
  permitted inside the seed Shape A wrap).
- No `[CONDITIONAL]` prefix appears anywhere in the output.

## Why this is a static hand-authored fixture, not a build.sh-generated one

Existing fixtures (`v10-minimal`, `v10-realistic-ot`, `v11-flat-file`,
`v11-tracker-on`, `existing-project-mid-dev`) are deterministically
rebuilt from scratch by `build.sh`. This fixture is different — it
encodes a specific, hand-verified marker geometry (Shape A + Shape B +
`renamed-from` overrides + the Project-addenda seed-slot exception) that
is not derivable from pack inputs alone. It is committed verbatim and is
NOT tracked in `test-fixtures/manifest.txt`.

## Cross-references

- `/backlog/BD-136.md` — Trinity marker-section preservation pattern
  (Shape A + Shape B) + PM-chat authoring procedure
- `supporting-docs/INSTALL-PROCEDURES.md` — `[CONDITIONAL]` H2
  retirement + Shape B transition for kept conditional sections
