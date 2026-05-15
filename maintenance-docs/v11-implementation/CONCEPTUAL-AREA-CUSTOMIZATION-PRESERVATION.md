# Conceptual Area: Customization Preservation (v11.0)

**Concept-scope doc** for the conceptual review methodology described in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.

**Trial review status:** scheduled after Batch 21b (BD-136) ships, before Batch 22 (milestone audit). First trial of the conceptual review methodology in this pack.

---

## Concept statement (binding invariant)

**User customizations to pack-installed files survive v10→v11 migration byte-identical for marker-protected content.** The migration must:
- Preserve content inside Shape A trinity markers (CLAUDE/AGENTS/GEMINI marker pairs) byte-identical
- Preserve content inside Shape B markers (per BD-136 spec, e.g., `[CONDITIONAL]` blocks → trinity-marker form) byte-identical or via documented translation
- Surface unmigrated customizations explicitly (no silent loss)
- Round-trip cleanly: customized v10 → migrated v11 → reverse-mapped → byte-identical to v10 source for marker contents

## In-scope BDs

| BD | Batch | Role in concept |
|---|---|---|
| BD-096 | 16 | Synthetic-fixture set covering customization-preserve scenarios; baseline for migration testing |
| BD-101 (partial) | 13 | In-script validation gates for `migrate-v10-to-v11.sh` — relevant where validation guards customization preservation |
| BD-095 (partial) | 13 | `--dry-run`/`--apply`/`--resume` workflow — relevant where these touch customized files |
| BD-128 (partial) | 6 | CI test-suite repair — relevant where existing customization-preserve tests run |
| BD-136 | 21b | Marker-aware merger (THE central impl); validator V-1..V-8; PM-CHAT.md authoring procedure P-1..P-8; trinity marker seed; test fixtures M-1..M-12 |
| BD-102 | 23 | Dog-food migration on pack-repo clone at v10 tag — empirical test of preservation |

## In-scope files

**Source-of-truth and implementation:**
- `scripts/lib/customization-preserve.sh` (BD-096 + BD-136 marker-aware merger)
- `scripts/lib/marker-preserve.sh` (if BD-136 ships as a separate sibling)
- `scripts/migrate-v10-to-v11.sh` (BD-095 + BD-101 + dispatch to merger)
- `scripts/init-project.sh` (BD-136 post-install hint)
- `scripts/validate-pack.py` (BD-136 V-1..V-8 check)

**Tests + fixtures:**
- `scripts/tests/test-customization-preserve.sh` (BD-096; extends with BD-136)
- `scripts/tests/test-customization-preserve-bd136.sh` (BD-136-specific; M-1..M-10)
- `scripts/tests/fixtures/customization-preserve/` (BD-096; 6 sub-fixtures)
- `test-fixtures/v11-trinity-marker-prepped/` (BD-136 M-8 round-trip golden)
- `test-fixtures/` M-11/M-12 fixtures (BD-136)

**Documentation surfaces:**
- `project-template/docs/pack/PM-CHAT.md` (BD-136 authoring procedure section)
- `project-template/docs/pack/INSTALL-PROCEDURES.md` (BD-136 cross-references)
- `project-template/docs/pack/SETUP-NEW.md` (BD-136 cross-references)
- `project-template/docs/pack/SETUP-EXISTING.md` (BD-136 cross-references)
- `supporting-docs/MIGRATION-v10-to-v11.md` (BD-084-extended; documents preservation contract)
- `supporting-docs/MERGE-STRATEGY.md` (if exists; documents merge resolution)
- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (Shape A marker pair seeds; trinity-replicated)

**Canonical templates that drop `[CONDITIONAL]` per BD-136:**
- per-CLI canonical templates in `project-template/` that previously used `[CONDITIONAL]` blocks

## Out-of-scope concepts

Explicit exclusion list to prevent drift:

| Concept | Why out-of-scope |
|---|---|
| Tracker mode lifecycle | Different concept (#1 in conceptual area list); shares almost no files with customization-preserve |
| Label family (`derived-from:`, `promoted-to:`) | Tracker concept; no overlap with customization preservation |
| Promotion paths (Path 1 / Path 2 / direct close) | Tracker concept |
| Per-entry split workflow corpus | Different concept (#7); workflow artifacts, not customization |
| Trinity rule consistency | Adjacent concept (#2); customization-preserve uses trinity markers but trinity-rule consistency is broader |
| CI workflow coverage | Adjacent concept (#8); customization-preserve tests are wired in CI but the broader CI coverage is its own concept |

Cross-references to these concepts are allowed (one-sentence notes) but not pursued.

## Touch-point matrix vs other concepts

| File | This concept | Other concept(s) | Touch class for this review |
|---|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | yes | per-entry split workflow corpus (#7); pack ops vs product separation (#5) | SHARED-RW |
| `scripts/init-project.sh` | yes (BD-136 post-install hint) | tracker mode lifecycle (#1; init also touches this) | SHARED-RW |
| `scripts/validate-pack.py` | yes (V-1..V-8 check) | trinity rule consistency (#2); CI coverage (#8) | SHARED-RW |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` | yes (Shape A marker seeds) | trinity rule consistency (#2; #1 source) | CONTRACT |
| `project-template/docs/pack/PM-CHAT.md` | yes (BD-136 authoring procedure) | tracker mode lifecycle (#1; PM-CHAT documents tracker too); per-entry split workflow corpus (#7) | SHARED-RW |
| `supporting-docs/METHODOLOGY.md` | yes (preservation contract docs) | every other concept (METHODOLOGY is shared) | SHARED-RO |
| `test-fixtures/` | yes (BD-096 + BD-136 fixtures) | OWNED for this concept's fixtures only | OWNED |

`CONTRACT` flag on `project-template/{CLAUDE,AGENTS,GEMINI}.md` because:
- Shape A markers in these files are the inter-concept contract between customization-preserve and trinity rule consistency
- Changing the marker format here breaks both concepts simultaneously
- Any finding requiring marker format change → `ARCH` severity

## Design intent references

- `BACKLOG.md` BD-136 entry — full implementation contract (L-1..L-10 merger logic; V-1..V-8 validator; P-1..P-8 authoring; M-1..M-12 fixtures; override mechanism; renamed-from)
- `BACKLOG.md` BD-138 entry — pre-merger spec (Shape A vs Shape B requirements; round-trip identity)
- `BACKLOG.md` BD-096 entry — synthetic fixture coverage requirements
- `CLAUDE.md` — trinity rule (Shape A markers must mirror across CLAUDE/AGENTS/GEMINI)
- `supporting-docs/MIGRATION-v10-to-v11.md` (BD-084-extended) — user-facing migration contract
- (if it exists) `maintenance-docs/v11-implementation/ARCHITECTURE-BD-136.md` or equivalent design doc — authoritative design for the merger

## Sidecar suffix conventions

The pack uses **two distinct sidecar-suffix conventions** for preserving prior-state files during pack-touching operations. Both are in active use; mixing them up is a real defect class (BD-116 retro F2 was caused by exactly this confusion). Future contributors editing customization-preserve, init-project, or migrator surfaces MUST consult this section.

| Convention | Suffix shape | Source | Used by | When written |
|---|---|---|---|---|
| Init-update sidecar | `<original>.pre-update` | `scripts/lib/customization-preserve.sh` default `sidecar_suffix` parameter (`customization_preserve_init`) | `scripts/init-project.sh --update` workflow | Any time `init-project.sh --update` writes a new pack-canonical version of a file the project has customized |
| Migrator sidecar | `<original>.<source-version>-customized` (e.g., `.v10-customized`) | `scripts/migrate-v10-to-v11.sh:76` `MIGRATOR_OWN_SIDECAR_SUFFIX` constant | `scripts/migrate-v10-to-v11.sh` (and any future `scripts/migrate-vN-to-vM.sh` per BD-119 framework) | Any time a migrator stage writes a new pack-canonical version of a file the project customized in the source-version era |

**Why two conventions:** the version-agnostic `.pre-update` suffix would collide if a migrator ran twice (e.g., v10→v11 then v11→v12 on the same workspace) or if `--update` ran after a migrator. Encoding the source version in the migrator suffix gives every migrator pass a distinct sidecar namespace.

**Cross-references:**
- `scripts/persona-contracts/contract-migration.sh` 3c fallback: must use `config.toml.<vN>-customized*` glob (NOT `config.toml.pre-*`) — verifying migrator sidecar carrying, not init-update sidecar.
- `scripts/persona-contracts/contract-mid-dev.sh` and `contract-greenfield.sh` pre-existing assertions: may reference either suffix depending on which surface they verify; check the contract's persona scoping before reading the glob.
- `scripts/lib/migrator-core.sh` (BD-119 adapter framework): each migrator's adapter exports `MIGRATOR_OWN_SIDECAR_SUFFIX` per-vN. The framework wires the value into the customization-preserve init call.

**Maintenance discipline:** any new sidecar-writing surface MUST pick one convention and document which (in code comment + this section's table). Adding a third convention without architect-pass review violates the maintainability principle (`CLAUDE.md` § Pack memory).

## Critical invariants

| # | Invariant | Test that proves it |
|---|---|---|
| C-1 | Shape A marker content survives v10→v11 byte-identical | M-8 round-trip fixture (BD-136); SHA-256 byte-identity assertion |
| C-2 | Shape B marker content survives or has documented translation path | M-1..M-7, M-9..M-12 fixtures (BD-136) |
| C-3 | Trinity rule preserved post-migration (CLAUDE/AGENTS/GEMINI marker pairs remain mirrored) | validate-pack Check 24 (existing) + V-1..V-8 (BD-136) |
| C-4 | Unmigrated customizations surfaced explicitly (no silent loss) | partial-write contract per V1 §9.6; tests assert error messages |
| C-5 | Round-trip: v10 → v11 → reverse-map → v10 source byte-identical for marker contents | dog-food migration (BD-102) |
| C-6 | Override mechanism + renamed-from honor user intent | BD-136 override mechanism tests |

## Pre-existing test coverage

To avoid the reviewer re-deriving what tests already prove:

| Surface | Test | Coverage |
|---|---|---|
| Synthetic fixtures (BD-096) | `test-customization-preserve.sh` | 6 sub-fixtures: lightly-customized-minimal, heavily-customized, language-heterogeneous, custom-agents-heavy, v10-with-customization, pack-retires-files (file-removal dispositions). 233 assertions across 8 groups. |
| Marker-aware merger (BD-136) | `test-customization-preserve-bd136.sh` | M-1..M-10 covers Shape A, Shape B, override, renamed-from |
| Trinity parity | validate-pack Check 24 + Check 27 | byte-identity across CLAUDE/AGENTS/GEMINI mirrors |
| Migration script | `test-init-project.sh` | end-to-end migration smoke |
| Dog-food migration | (Batch 23 — empirical test) | round-trip on pack-repo clone |

The reviewer uses these as anchors. Findings that re-derive proven invariants without new evidence are out of scope.

## Known boundary conditions / failure modes

- **Customization survives but trinity drifts:** the merger preserves marker content but downstream the user edits one of the three trinity files without mirroring. validate-pack Check 24 catches at next CI run; conceptual review should confirm the catch path is robust.
- **Override + renamed-from interaction:** user has BOTH an override AND a renamed-from marker for the same file region. Behavior must be deterministic; documented in BD-136 spec.
- **Shape B → Shape A translation loss:** if the canonical template retires a `[CONDITIONAL]` block that the user customized (Shape B), the merger should translate to Shape A trinity-marker form preserving content. Edge: `[CONDITIONAL]` block content references a deprecated v10 feature; translation may not be semantically meaningful.
- **Migration on dirty working tree:** user runs migration with uncommitted changes; merger operates on disk state, not git state. Coverage gap?
- **Migration on a v9 or earlier base:** out of v11.0 support scope; should error cleanly with named recovery verb.

## Reviewer prompt scope

When invoking the reviewer for this conceptual area, the prompt MUST:

1. Cite this scope doc explicitly (path + version)
2. Cite the methodology doc (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`)
3. Limit reading to the files listed in the in-scope and touch-point sections (plus design-intent references)
4. Forbid reading PACK-REVIEW-*.md from prior reviews (per the no-prior-reviews pack memory rule)
5. Forbid pursuing out-of-scope concepts beyond one-sentence noting
6. Use the standardized finding format from the methodology doc
7. Output to `maintenance-docs/v11-implementation/CONCEPTUAL-REVIEW-CUSTOMIZATION-PRESERVATION.md` (the report)

## Concept-specific dimension (f) items

Items unique to this concept that don't fit the universal (a)-(e) dimensions:

- **f1: Marker grammar precision.** Shape A and Shape B markers must be unambiguously parseable; no edge case where a user-authored line resembles a marker.
- **f2: Translation fidelity for `[CONDITIONAL]` retirement.** Where v10 used `[CONDITIONAL]` blocks, v11's trinity-marker translation must preserve user intent (not just content).
- **f3: Override mechanism semantics.** What happens when override + renamed-from conflict? When override targets a marker pair that no longer exists in v11 canonical?
- **f4: Forward-compatibility hooks.** Does the merger leave room for future Shape C / Shape D markers without re-architect?

These (f) items are pre-declared and bounded; the reviewer does not invent new (f) items mid-review.

## Trial review hand-off

When this trial review runs (post-Batch 21b, pre-Batch 22):

1. Pack Chat parent invokes the reviewer agent (`pack-auditor` if BD-110 has shipped; else `pack-architect` with explicit conceptual-review prompt template)
2. Reviewer reads this scope doc + methodology doc + listed inputs
3. Reviewer outputs `maintenance-docs/v11-implementation/CONCEPTUAL-REVIEW-CUSTOMIZATION-PRESERVATION.md` per the report shape in the methodology doc
4. Pack Chat parent triages findings (severity-ordered) per the standing fix-all rule
5. ARCH findings (if any) trigger a separate architect pass; non-ARCH findings get fix work in-session
6. Empirical-results write-up: `maintenance-docs/v11-implementation/CONCEPTUAL-REVIEW-TRIAL-RESULTS.md` documents:
   - Findings count by severity + dimension + touch-point class
   - Findings unique to this scope (not catchable by per-BD or per-batch reviews)
   - Reviewer wall-clock + token cost
   - Methodology revisions needed
   - Decision: institutionalize as Batch 21d for v12.0+? (See methodology doc § "Empirical validation requirement")
