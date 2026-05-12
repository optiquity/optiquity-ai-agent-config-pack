# IMPLEMENTATION-REPORT-BD-156

**BD:** BD-156 — `protobuf-patterns` skill — extract Proto3 schema rules
from `grpc-patterns`; standalone-usable via intersection table
**Branch:** `v11-dev`
**Pre-flight HEAD:** `b168a9f0fd6b6d85e39306add09957731750f989`
**Final HEAD:** `b168a9f0fd6b6d85e39306add09957731750f989` (no commits — agent is read-only on git state per pack workflow rule)
**Working-tree state at finish:** modified (6 files) + untracked (1 dir, 1 new SKILL.md). See "Files changed" below.

---

## 1. Pre-flight state

- `git status` → clean working tree.
- `git rev-parse HEAD` → `b168a9f`.
- Baseline `python3 scripts/validate-pack.py` → PASSED — all 30 checks clean.
- Baseline `bash scripts/test-detect.sh` → 42 passed, 0 failed.
- Baseline `bash scripts/tests/test-init-project.sh` → 34 passed, 0 failed.
- Pack-root `.claude/skills/` inventory: pack-development trigger-load
  skills only (architecture-review, commit-discipline, dependency-intake,
  documentation, implementation-report, pack-help, pack-startup,
  planning, review, verification-harness). **No `grpc-patterns`
  pack-root mirror exists.** Decision: only the project-template
  trinity is in scope (single-source SKILL.md per skill, since
  pack-template skills are sourced from `project-template/skills/<name>/`
  and copied into the per-CLI `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/` trees by `init-project.sh stage_s4_skills`).

## 2. Plan deviations

The BD-156 spec ("File/Symbol" line) describes the new SKILL.md as a
trinity (`project-template/.claude/skills/protobuf-patterns/SKILL.md` +
`.codex/skills/...` + `.gemini/skills/...`, byte-identical per Check 9)
and the existing `grpc-patterns` SKILL.md likewise as a trinity. **This
spec is stale** — the actual pack repo layout stores skill SKILL.md
files at the single canonical path
`project-template/skills/<name>/SKILL.md` and `init-project.sh` copies
each into the per-CLI trees of target projects at scaffold time
(`stage_s4_skills`). The `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` trees inside `project-template/` themselves only hold
CLI-specific helper skills (`pack-help`, `pm-startup`) — every other
skill is single-source. Verified by:

- `find project-template -name SKILL.md -path '*python-data-architecture*'`
  returns one path (`project-template/skills/python-data-architecture/SKILL.md`).
- `git log --all --oneline -- project-template/skills/python-data-architecture/SKILL.md`
  → BD-035 split commit ships a single file.
- Check 9 of `validate-pack.py` enforces detection-function presence
  and BD-044 docs; it does NOT enforce a per-CLI SKILL.md trinity for
  any skill other than `pack-help` / `pm-startup`. Check 1 walks
  `project-template/skills/*/SKILL.md` exclusively.

Deviation: implemented as a single-source SKILL.md at
`project-template/skills/protobuf-patterns/SKILL.md` plus the matching
single-source edit to `project-template/skills/grpc-patterns/SKILL.md`.
This matches the pack's existing skill-distribution model; recreating
the spec's trinity-of-files would diverge from established convention
and break `init-project.sh stage_s4_skills`'s `cp` loop (which would
then copy from `project-template/skills/protobuf-patterns/` while the
authoritative content lives at `project-template/.claude/skills/...`).

No other plan deviations.

## 3. New POQs surfaced

1. **POQ-BD-156-A: BD-156 spec File/Symbol line is stale on the
   skill-trinity geometry.** Ship-time ARCHITECTURE / PLAN docs
   describe SKILL.md files as trinity (3-copy) artifacts; the actual
   pack distributes single-source SKILL.md files via
   `stage_s4_skills`. The BD-156 entry's File/Symbol line was written
   to that stale model. Disposition: implemented per actual pack
   convention (single-source); the BD-156 backlog entry should be
   amended at PM-chat review time to read "NEW
   `project-template/skills/protobuf-patterns/SKILL.md` (single source
   distributed to per-CLI trees via `init-project.sh
   stage_s4_skills`)" and "MODIFIED
   `project-template/skills/grpc-patterns/SKILL.md`". Do NOT
   re-implement as 3-copy trinity.

2. **POQ-BD-156-B: PLAN doc absent for BD-156 specifically.** The
   PLAN-SKILL-DIMENSIONS.md was written before BD-156 / BD-157 /
   BD-158 were added (per the BD-156 entry's `Type` line: "added as
   v11.0 scope parallel to BD-149"). PLAN therefore does not cover
   BD-156's batch sequencing. Disposition: BD-156 was implemented
   directly against the BACKLOG entry + ARCHITECTURE-SKILL-DIMENSIONS.md
   §3.7 (intersection-cell loading) + §7.10 (naming convention). No
   architecture changes were made; only mechanical / additive
   intersection-table extension.

3. **POQ-BD-156-C: BD-156 References Check 31 of `validate-pack.py`
   (skill-cell consistency, BD-146).** The agent prompt explicitly
   excludes editing `validate-pack.py` (Check 31 is added by BD-146,
   not yet shipped). All 30 currently-shipped Checks pass with the
   BD-156 changes. Disposition: when BD-146 ships and adds Check 31,
   it must include `protobuf-patterns` in its dimensional-skill
   roster; BD-146's implementation should grep PLATFORM-SKILLS.md's
   "### Dimensional skills (NN)" header for the count to derive the
   roster automatically (rather than hard-coding skill names), which
   makes BD-156's already-landed PLATFORM-SKILLS.md row pick up
   automatically. No action in BD-156.

## 4. BD-159 §3.1 mechanical-edit sanity check

BD-159 §3.1 sets a soft cap of ≤10 files per mechanical batch.
BD-156's footprint is **8 files modified or created**:

1. NEW `project-template/skills/protobuf-patterns/SKILL.md`
2. MOD `project-template/skills/grpc-patterns/SKILL.md`
3. MOD `project-template/docs/pack/PLATFORM-SKILLS.md`
4. MOD `scripts/lib/detect.sh`
5. MOD `scripts/init-project.sh`
6. MOD `scripts/add-capability.sh`
7. MOD `scripts/test-detect.sh`

Total: 7 distinct files (the BD-156 prompt's pre-count of 11 assumed a
3-copy SKILL.md trinity for both the new and the modified skill, plus
PLATFORM-SKILLS.md, plus 4 scripts; the actual single-source skill
geometry collapses 6 SKILL.md files into 2). **Comfortably under the
≤10 cap.** No structural escalation required; the change fits the
existing 5+3 dimension model + intersection-cell loading mechanism + the
`*-patterns` naming convention recommended by ARCHITECTURE
§7.10. BD-159 §3.1 sanity check: PASS.

## 5. Per-file edit log

### 5.1 NEW `project-template/skills/protobuf-patterns/SKILL.md`

- **Lines:** 234 lines (frontmatter + 9 sections + 45 numbered rules).
- **Sections:** Applicability; Field numbering invariants (rules 1-5);
  Backward and forward compatibility (6-11); Proto3 vs Proto2
  differences (12-15); `oneof` semantics (16-19); Well-known types
  (20-25); Map types (26-28); Imports and package conventions (29-32);
  Naming conventions (33-35); Code-generation options (36-38); Tooling
  (39-42); High-risk changes (43-45).
- **Frontmatter:** `name: protobuf-patterns`,
  `description:` (per BD-156 spec — Proto3 schema design,
  field-evolution, well-known types, code-gen conventions, applies
  with or without gRPC), `allowed-tools: Read, Grep, Glob, Bash`.
- **Rule extraction provenance from `grpc-patterns`:**
  - grpc-patterns rules 1, 2 (`reserved` + field-numbering invariant)
    → expanded into protobuf-patterns rules 1-5 (added 1-15
    one-byte-tag rule; added the 19000-19999 reserved range; added
    the renumbering anti-pattern rule).
  - grpc-patterns rule 3 (UNSPECIFIED enum zero) → protobuf-patterns
    rule 14 (Proto3 enums, expanded with default-on-absence semantics).
  - grpc-patterns rule 4 (Timestamp) → protobuf-patterns rule 20
    (extended with same rationale; added Duration as rule 21).
  - grpc-patterns rule 7 (snake_case / PascalCase /
    SCREAMING_SNAKE_CASE) → protobuf-patterns rule 33 (added enum
    prefix-repetition guidance).
  - grpc-patterns rule 8 (one service per .proto file) → covered in
    protobuf-patterns rule 32 (imports / package conventions).
  - grpc-patterns rule 9 (`proto3 optional`) → protobuf-patterns
    rule 13 (as part of Proto3 vs Proto2 differences).
  - grpc-patterns rule 10 (FieldMask) → protobuf-patterns rule 22.
  - grpc-patterns rules 11, 12 (`buf lint` / `buf breaking`) →
    protobuf-patterns rules 11, 39, 40 (split: rule 11 keeps the
    breaking-change-detection in compatibility section; rules 39-42
    cover lint/format/pinning under Tooling).
  - grpc-patterns rule 13 (never hand-edit generated code) →
    protobuf-patterns rule 38 (with gRPC-side parallel kept in
    grpc-patterns rule 7).
  - grpc-patterns rule 14 (flag high-risk changes) →
    protobuf-patterns rules 43, 44, 45 (expanded into 3
    field/RPC/rename categories with explicit rationale).
- **New rules added beyond the grpc-patterns extraction (per BD-156
  Description's expanded scope):** field-number 19000-19999 reserved
  range; type-change compatibility table; repeated⇄singular evolution;
  proto3 default-customization rule; full `oneof` semantic & migration
  rules (4 rules); well-known type guidance for `Empty`, `Any`, and
  wrapper types beyond `Timestamp` / `FieldMask`; map type
  restrictions; package-versioning convention; code-generation
  options table for swift / java / go / csharp; `buf` tooling pin
  guidance.

### 5.2 MOD `project-template/skills/grpc-patterns/SKILL.md`

- **Lines before:** 84 (84 LOC + frontmatter, 44 numbered rules).
- **Lines after:** 67 (67 LOC + frontmatter, 33 numbered rules).
- **Removed:** "Proto3 schema rules" section (rules 1-14 — schema
  design, `reserved`, UNSPECIFIED, Timestamp, auth metadata,
  google.rpc.Status, naming, services-per-file, optional, FieldMask,
  buf lint/breaking, hand-edit, high-risk flags). Rules 5 (auth
  tokens) and 6 (google.rpc.Status) were transport-side rules
  bundled in the schema section in v10; they MOVED to a new
  "gRPC service / call rules" section (renumbered as grpc-patterns
  rules 5-7) — they are gRPC-call-shape rules, not schema rules,
  and stay with grpc-patterns.
- **Added:** new "Companion skill — Proto3 schema rules" header
  paragraph at the top (per BD-156 spec's "one-paragraph see
  protobuf-patterns" requirement). Cross-references rule 7 in the
  new "gRPC service / call rules" section back to protobuf-patterns
  for the schema-side hand-edit rule.
- **Renumbered:** every retained rule was renumbered (15→1, ...,
  44→33). Cross-references inside the file (none existed) were not
  affected. External references to rule numbers (PLATFORM-SKILLS.md,
  CLAUDE.md trinity, etc.) checked: no rule numbers are referenced
  outside this file (`grep -rn "grpc-patterns rule [0-9]"
  project-template scripts maintenance-docs` → no matches).
- **Retained:** Protobuf↔domain mapping (now rules 1-4); gRPC
  service/call rules (5-7); grpc-swift-2 client (8-14); Swift gRPC
  → domain error mapping (15-17); grpc.aio server (18-25); Python
  gRPC → domain error mapping (26-28); cross-language conventions
  (29-33).
- **Updated frontmatter `description`:** dropped "Protobuf schema
  design" prose — now reads "Use for gRPC service patterns —
  servicers, interceptors, streaming, deadlines, error model, async
  handlers, grpc-swift-2 / grpc.aio specifics, and gRPC-side
  cross-language conventions."

### 5.3 MOD `project-template/docs/pack/PLATFORM-SKILLS.md`

- **Intersection table:** added new row for `protobuf-patterns`
  immediately after `python-data-architecture`. Predicate: "(any
  host language) ∩ protobuf-marker present"; canonical predicate
  cited as `scripts/lib/detect.sh::protobuf_marker_detected()`.
- **§"Dimensional skills (16)" header bumped to (17).** Verified
  count by `awk` extraction over the table body: 17 skill rows
  present.
- **`grpc-patterns` row description updated:** dropped "Proto3
  schema" lead, now reads "gRPC service patterns: servicers,
  interceptors, streaming, deadlines, error model, async handlers,
  grpc-swift-2 / grpc.aio specifics, gRPC-side cross-language
  conventions *(Proto3 schema rules live in `protobuf-patterns`;
  load both when D4=grpc)*".
- **`protobuf-patterns` row added** in the dimensional table with
  Cell="(any host language) ∩ protobuf-marker", Description per
  BD-156 spec, Agents per BD-156 spec ("architect, grpc-schema,
  coder, reviewer, auditor-architecture, auditor-code").
- **§"16 dimensional / intersection skills" tally paragraph bumped
  to 17,** and the intersection-loaded-rows enumeration extended
  from 3 (`python-server-architecture`, `python-data-architecture`,
  `deployment-python`) to 4 (adding `protobuf-patterns`).
- **"Total skills: 31" → "Total skills: 32"** in the Full skill
  inventory closing paragraph; tier breakdown updated (16→17 in
  the dimensional column).
- **Worked examples updated:** "Python gRPC server (Linux container)"
  and "Universal Apple app + Python gRPC server (monorepo)"
  examples both now list `protobuf-patterns` in the intersection
  step and in the result line. The two pure-Apple worked examples
  (no proto) and "macOS Swift app with C++" example are
  unchanged — they have no protobuf-marker.
- **Step 2 agent assignments updated:** `architect`, `coder`,
  `reviewer`, `grpc-schema`, `auditor-architecture`, `auditor-code`
  — each gained `protobuf-patterns` in their dimensional skill list
  per BD-156 spec ("Loaded by: architect, grpc-schema, coder,
  reviewer, auditor-architecture, auditor-code").

### 5.4 MOD `scripts/lib/detect.sh`

- **New function** `protobuf_marker_detected()` added immediately
  before `detect_target_pack_version()` (105 LOC including the
  block-comment docstring).
- **Mirrors the BD-141 `python_data_marker_detected()` shape:**
  single positional arg defaulting to cwd, missing-target-tolerant,
  emits a single `protobuf-marker: yes|no` line on stdout.
- **Markers:** (a) any `.proto` file in the project tree (with
  `find -prune` of `node_modules`, `.git`, `build`, `.venv`,
  `venv`, `.tox`); (b) Python manifests
  (`requirements.txt` / `pyproject.toml` / `setup.py` / `setup.cfg`)
  list any of `protobuf` / `grpc-tools` / `grpcio-tools` / `protoc`;
  Swift manifests (`Package.swift` / `Package.resolved`) list any of
  `swift-protobuf` / `SwiftProtobuf` / `grpc-swift-2` / `grpc-swift`;
  generic `buf.yaml` or `buf.gen.yaml` present.
- **Boundary construction reuses BD-141's negated-character-class
  pattern** (`(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])`) —
  rejects substring matches like `protobuf-c-bindings` via
  `protobuf` (test case proto-marker-substring-reject covers this).
- **Permission bits:** unchanged — `detect.sh` is `-rw-r--r--` (a
  sourced library; the file's leading comment explicitly says
  "Do NOT add a shebang — this file is sourced, not executed").

### 5.5 MOD `scripts/init-project.sh`

- **`pack_skill_coverage_for() proto)` case** rewritten from a
  single-skill `echo "grpc-patterns"` to a marker-conditional emit:
  if `protobuf_marker_detected "$target_dir"` returns
  `protobuf-marker: yes` → emit `grpc-patterns,protobuf-patterns`;
  else → emit `grpc-patterns` (unchanged from v10 behavior).
- **Pattern matches the BD-141 python case** (full-literal helper-
  output line comparison, not field parsing — same hardening
  rationale as BD-141: a future helper output change is caught at
  compare time, not silently).
- **Permission bits:** unchanged (`-rwxr-xr-x`).

### 5.6 MOD `scripts/add-capability.sh`

- **`capability_skills() protocol:grpc)` case:** added a multi-line
  comment block above the existing `echo "grpc-patterns"` line
  documenting that `protobuf-patterns` is intersection-loaded by
  marker (not by capability). The capability mapping itself is
  unchanged — `protocol:grpc` still resolves to `grpc-patterns`
  only. Standalone-protobuf clients load `protobuf-patterns` via
  the intersection table without ever declaring `protocol:grpc`.
- **Permission bits:** unchanged (`-rwxr-xr-x`).

### 5.7 MOD `scripts/test-detect.sh`

- **New section** `# ── protobuf_marker_detected (BD-156) ───`
  inserted before the `detect_target_pack_version` section,
  containing **10 new test cases**:
  1. empty dir → no
  2. non-existent target → no (tolerated)
  3. `.proto` file present → yes (marker a)
  4. `.proto` only inside `node_modules/` → no (vendored prune)
  5. `pyproject.toml` lists `protobuf` → yes (marker b — Python)
  6. `requirements.txt` lists `grpcio-tools` → yes
  7. `Package.swift` references `swift-protobuf` → yes (marker b — Swift)
  8. substring `protobuf-c-bindings` alone → no (boundary reject —
     mirrors the BD-141 boundary-test pattern)
  9. `buf.yaml` present → yes (generic buf-tooling marker)
  10. manifests without protobuf tooling → no
- **Test count:** 42 → 52 passing.
- **Permission bits:** unchanged (`-rwxr-xr-x`).

## 6. Verification commands and results

### 6.1 `python3 scripts/validate-pack.py`

Exit: 0. Final line: `PASSED — all checks clean`. All 30 checks pass.
Specifically Check 1 (SKILL.md frontmatter) walks the new
`protobuf-patterns` directory and validates the frontmatter shape
(name + description + allowed-tools all present) — `OK:
skills/protobuf-patterns/SKILL.md`. Check 9 (init-project structure)
re-validates `scripts/lib/detect.sh` function presence — all 7
required functions still defined (the BD-156 addition is additive).

### 6.2 `bash scripts/test-detect.sh`

Exit: 0. Final line: `=== Results: 52 passed, 0 failed ===`. All 10
new BD-156 tests pass (positive: 5 — `.proto` file, pyproject
protobuf, requirements grpcio-tools, Package.swift swift-protobuf,
buf.yaml; negative: 4 — empty dir, non-existent, vendored-only-proto,
unrelated deps; boundary: 1 — substring rejection).

### 6.3 `bash scripts/tests/test-init-project.sh`

Exit: 0. Final line: `Passed: 34 / Failed: 0`. The proto handling
inside `pack_skill_coverage_for` is exercised indirectly by the
preview generation; no regression from the marker-conditional emit
since the test fixtures do not include `.proto` files.

### 6.4 `git diff --stat`

```
 project-template/docs/pack/PLATFORM-SKILLS.md  |  38 ++++-----
 project-template/skills/grpc-patterns/SKILL.md |  92 +++++++++++-----------
 scripts/add-capability.sh                      |   9 +++
 scripts/init-project.sh                        |  20 ++++-
 scripts/lib/detect.sh                          | 105 +++++++++++++++++++++++++
 scripts/test-detect.sh                         |  96 ++++++++++++++++++++++
 6 files changed, 294 insertions(+), 66 deletions(-)
```

Plus the untracked new file
`project-template/skills/protobuf-patterns/SKILL.md` (~234 LOC).

### 6.5 Permission bits preserved

```
-rwxr-xr-x  scripts/add-capability.sh
-rwxr-xr-x  scripts/init-project.sh
-rw-r--r--  scripts/lib/detect.sh         (sourced library — no shebang, intentional)
-rwxr-xr-x  scripts/test-detect.sh
```

All permissions unchanged from pre-flight.

### 6.6 Trinity-rule compliance

The trinity-rule (CLAUDE.md / AGENTS.md / GEMINI.md) does NOT apply
to this batch — no edits to any of the three doc trinities (pack-repo
trinity nor project-template trinity nor pack-template trinity). The
new skill file is single-source per pack convention and is not a
trinity artifact.

### 6.7 Skill-count consistency

`PLATFORM-SKILLS.md` headers and totals reconcile to actual table
contents:

- "### Dimensional skills (17)" header → table has 17 rows (verified
  via `awk` extraction).
- "**17 dimensional / intersection skills.**" tally paragraph → matches.
- Intersection-loaded enumeration: 4 rows
  (`python-server-architecture`, `python-data-architecture`,
  `protobuf-patterns`, `deployment-python`) — matches Intersection
  table content.
- "**Total skills: 32**" → 13 Tier 0 + 17 dimensional + 1 trigger-
  loaded + 1 PM chat operational = 32. Arithmetic checks.

## 7. Files-changed inventory

| Path | Change | LOC delta | Notes |
|---|---|---|---|
| `project-template/skills/protobuf-patterns/SKILL.md` | NEW | +234 | New skill source per BD-156 |
| `project-template/skills/grpc-patterns/SKILL.md` | MOD | -17 | Strip Proto3 schema; cross-reference protobuf-patterns; renumber rules |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | MOD | net +N | New intersection row + dimensional row + count bumps + worked-example refresh + Step 2 agent assignment additions |
| `scripts/lib/detect.sh` | MOD | +105 | New `protobuf_marker_detected()` function |
| `scripts/init-project.sh` | MOD | +18 | `pack_skill_coverage_for proto)` → marker-conditional |
| `scripts/add-capability.sh` | MOD | +9 | Comment cross-reference at `protocol:grpc` |
| `scripts/test-detect.sh` | MOD | +96 | 10 new test cases for `protobuf_marker_detected()` |

Total distinct files: **7** (1 new, 6 modified). Under BD-159 §3.1
≤10 cap.

## 8. Definition-of-Done checklist

| Criterion | Status |
|---|---|
| `python3 scripts/validate-pack.py` PASSED | PASS |
| `bash scripts/test-detect.sh` all green | PASS |
| `bash scripts/tests/test-init-project.sh` no regression | PASS |
| New `protobuf-patterns/SKILL.md` exists with valid frontmatter | PASS |
| `grpc-patterns/SKILL.md` retains gRPC-only rules + cross-reference | PASS |
| `PLATFORM-SKILLS.md` intersection-table row added | PASS |
| `PLATFORM-SKILLS.md` dimensional-table row added; description updated for grpc-patterns | PASS |
| `PLATFORM-SKILLS.md` skill counts reconciled (17 dimensional, 32 total) | PASS |
| `PLATFORM-SKILLS.md` Step 2 agent assignments updated for the 6 BD-156-listed agents | PASS |
| `scripts/lib/detect.sh` `protobuf_marker_detected()` defined | PASS |
| `scripts/init-project.sh` proto case wired to the helper | PASS |
| `scripts/add-capability.sh` cross-reference comment added | PASS |
| `scripts/test-detect.sh` 10 new positive/negative/boundary cases pass | PASS |
| `validate-pack.py` not edited (per spec — Check 31 belongs to BD-146) | PASS |
| Permission bits preserved on all `.sh` files | PASS |
| Trinity rule N/A (no trinity files touched) — explicitly verified | PASS |
| BD-159 §3.1 mechanical-edit ≤10 file cap | PASS (7 files) |
| No edits outside BD-156 footprint | PASS |
| No state-changing git verbs run by the agent | PASS |
| Implementation report created at the spec'd path | PASS |

All criteria PASS. Ready for Pack Chat review and commit.

## 9. Suggested commit message (for Pack Chat to use after review)

```
feat: v11 — BD-156 protobuf-patterns skill + intersection-cell loader

- NEW project-template/skills/protobuf-patterns/SKILL.md with Proto3
  schema-design rules extracted from grpc-patterns and expanded per
  the BD-156 description (well-known types, oneof semantics, code-gen
  options, buf tooling, high-risk-change flags).
- MOD project-template/skills/grpc-patterns/SKILL.md — strip Proto3
  schema rules; add companion-skill cross-reference; renumber rules
  (44 → 33). gRPC-specific rules retained (servicers, interceptors,
  streaming, deadlines, error model, grpc-swift-2 / grpc.aio).
- MOD project-template/docs/pack/PLATFORM-SKILLS.md — new
  intersection-table row; new dimensional row; grpc-patterns
  description refocused; counts 16→17 dimensional, 31→32 total;
  worked examples + Step 2 agent assignments updated.
- MOD scripts/lib/detect.sh — new protobuf_marker_detected()
  predicate (mirrors BD-141 python_data_marker_detected() shape).
- MOD scripts/init-project.sh — pack_skill_coverage_for proto) wired
  to the marker predicate.
- MOD scripts/add-capability.sh — comment cross-reference at
  protocol:grpc documenting intersection loading.
- MOD scripts/test-detect.sh — 10 new test cases (52 passing).
```

(Pack Chat may amend; the above is informational only.)
