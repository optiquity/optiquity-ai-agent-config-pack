# IMPLEMENTATION-REPORT-BD-180.md

Coder report for **BD-180** — Extend `cmd_update` mapping symmetry
coverage to remaining surfaces (observations A–G).

- Branch: `v11-dev`
- HEAD (pre-commit): `47f7cbfd2411454378d745f95358b36ce5b2ea94`
- Coder agent: pack-coder (sequential, in-place against parent worktree)
- Date: 2026-05-20
- Scope: 4 source files modified, 1 new test file, 1 manifest regen.
- Architect spawn? NO — mechanical extension of the BD-175 F2a Check 39
  pattern + ARCHITECTURE-BD-176.md §5.3 design sketch realization.

## §1 Summary

Closed all 7 observations (A–G) surfaced for BD-180. Pattern: 6 added
`cmd_update` mappings + 1 removed stale mapping + 1 new `S11` explicit
copy block + 1 documented intentional exclusion + 1 extended check
(forward-only → bidirectional) + 1 new check + 1 self-documenting
inventory comment block + tests for both checks.

**HEAD state after edits:** All checks PASS; new
`scripts/validate-pack.py` Check 41 PASSes cleanly at HEAD with 38
inventory entries × 35 cmd_update entries cross-referenced; Check 39
reverse-direction extension PASSes with 35 entries resolving to extant
sources (zero stale mappings).

**Files changed (5):** 1 source script edit (init-project.sh), 1
validator extension + new check (validate-pack.py), 1 test extension
(test-validate-pack-check-39.sh), 1 new test (test-validate-pack-check-41.sh),
1 manifest regen (test-fixtures/manifest.txt — RC9 triggered + drift
expected).

## §2 Per-observation A–G decision table

| Obs | Investigation finding | Decision | Implementation surface | Rationale |
|---|---|---|---|---|
| **A** | `project-template/.gemini/commands/pm-startup.toml` exists at the pack-template path but NO stage (S4/S6/S11) and NO cmd_update entry installs it. Parallel feature: `.claude/skills/pm-startup/SKILL.md` + `.codex/skills/pm-startup/SKILL.md` ARE distributed at fresh-install by S4's canonical-pool loop (project-template/skills/pm-startup/SKILL.md → all 3 CLIs). The Gemini surface is a `.toml` command file, NOT a skill, so the S4 loop doesn't cover it. The `pack-help` analogue has an explicit S11 block (lines 855-871) that copies `.gemini/commands/pack-help.toml`. | **FIX** | (1) Added explicit S11 copy block parallel to pack-help.toml at `init-project.sh:stage_s11_v11_artifacts()`; (2) Added cmd_update mapping `"project-template/.gemini/commands/pm-startup.toml:.gemini/commands/pm-startup.toml:generic"`. | Functionally correct: the `/pm-startup` command works on Claude/Codex via skill files; without this fix, Gemini clients have no `/pm-startup` command. Verified via fixture rebuild: `test-fixtures/v11-flat-file/.gemini/commands/pm-startup.toml` now exists. |
| **B** | `.claude/skills/pm-startup/SKILL.md` + `.codex/skills/pm-startup/SKILL.md` exist at project-template path; S4 distributes both at fresh-install (from canonical pool). cmd_update mapping ABSENT. Compare with `pack-help` skills at lines 1130-1131 (the BD-077 precedent). Net effect: pm-startup skill updates would NOT propagate via `pack update`. | **FIX** | Added 2 cmd_update mappings for `.claude/skills/pm-startup/SKILL.md` and `.codex/skills/pm-startup/SKILL.md` (parallel to pack-help). | Same class as pack-help, which has explicit mappings. Refactoring `_cmd_update_iter_dir` to walk the canonical skills pool was rejected as bigger scope than this BD warrants; explicit mappings preserve clarity. |
| **C** | `project-template/.claude/settings.local.example.json` exists. S3 only copies `.claude/settings.json` (not `*.local.*`). cmd_update has NO entry. NEITHER fresh-install NOR update installs the file. The `settings.local.*` convention is Claude Code's per-developer customization pattern; clients author their own (not pack-seeded). | **EXEMPT — by intentional non-install** | NO cmd_update mapping added (would propagate to clients incorrectly). Documented in the new `_CLIENT_INSTALLED_FILES` "Intentionally NOT installed" comment block at `init-project.sh:cmd_update()` epilogue (per observation G structure) with rationale. No exemption allowlist entry needed: the file does not appear on either side of cmd_update symmetry. | Discoverability via the inventory block: an actor asking "why does `settings.local.example.json` exist if it never installs?" finds the documented rationale at the canonical inventory location. |
| **D** | Per-entry skeleton templates exist: `project-template/docs/project/{backlog,implementation-plan,changelog}/_{rules,intro,format}.md` (7 files total — backlog: 2, implementation-plan: 2, changelog: 3). S11 step 6 (`init-project.sh:stage_s11_v11_artifacts()` lines 891-947) installs each at fresh-init via explicit `"$copy_fn"` calls (BD-166/BD-167 contract). cmd_update has ZERO entries. Net effect: template updates (e.g., `_rules.md` schema additions) would NOT propagate to existing clients via `pack update`. BD-167 scaffolding contract is load-bearing per pack memory. | **FIX** | Added 7 cmd_update mappings for the per-entry skeleton files (one per `_*.md` template). | Per pack memory "per-entry templates are load-bearing for BD-167 scaffolding — pack update should propagate template fixes." Class `generic`; same BD-088 customization-preserve treatment as other docs/pack/* files. |
| **E** | `project-template/docs/pack/PROMPT-TEMPLATES.md` mapped at `init-project.sh:1122` (pre-BD-180 HEAD). File DOES NOT EXIST at HEAD (retired in v10.0 — PM-CHAT.md:149-150 documents the retirement). Stale mapping accumulated through multiple release cycles unflagged because Check 39 only verified forward direction. | **FIX (both: remove mapping + add reverse-direction check)** | (1) Removed the stale entry from cmd_update at `init-project.sh:cmd_update()`; (2) Extended Check 39 with reverse-direction verification at `validate-pack.py:check_cmd_update_symmetry()` — every cmd_update entry's `pack_relpath` MUST resolve to an extant file at HEAD; (3) Added `_CHECK_39_REVERSE_EXEMPTIONS` allowlist (default: empty) for intentionally-extern paths. | Check 39 extension chosen over new Check 41-for-reverse per simplest-correct-design (the reverse direction IS cmd_update symmetry, just the other vector — naturally belongs in Check 39). Minimizes check-count proliferation. Check 41 reserved for observation G self-documenting list (semantically distinct: discoverability vs. symmetry). |
| **F** | `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` exist at pack root. S6 installs both at fresh-init via separate copy blocks (`init-project.sh:stage_s6_docs_pack()` lines 565-583). cmd_update has ZERO entries. Net effect: same gap class as B/D — files reach fresh-init clients but not update clients. BD-175 Commit 8 CI failure (METHODOLOGY.md manifest drift) confirms these ARE fixture-affecting AND ARE distributed at install time. | **FIX** | Added 2 cmd_update mappings: `"supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic"` + `"supporting-docs/INSTALL-PROCEDURES.md:docs/pack/INSTALL-PROCEDURES.md:generic"`. Note: `pack_relpath` field for these uses the `$PACK/supporting-docs/...` form per the existing comment "pack_relpath — path under $PACK (or $PACK/project-template/)"; the cmd_update loop at `init-project.sh:cmd_update()` resolves `theirs="$PACK/$pack_rel"` correctly. | Same install-stage code path as METHODOLOGY.md's CI-failure precedent — confirms the mapping shape is correct. |
| **G** | BD-176 architect §5.3 sketched a self-documenting "files copied to clients" list inside `scripts/init-project.sh` or `scripts/validate-pack.py`, with a corresponding `validate-pack.py` check that asserts the list matches actual copy-site state. Per §5.3, the location is coder's choice. Per BD-176 §5.3 the original sketch said "Check 40" but Check 40 was claimed by BD-179. | **FIX** (implement per §5.3 with refinements) | (1) Added `_CLIENT_INSTALLED_FILES_START`/`_END` self-documenting comment block to `init-project.sh` immediately after `cmd_update()` body close — single discoverability anchor for all install paths (cmd_update + S3/S4/S6/S11); (2) Added Check 41 at `validate-pack.py:check_client_installed_files()` that parses the block and asserts (a) markers exist exactly once each, (b) block has ≥1 parseable entry, (c) every entry's `pack_relpath` exists at HEAD, (d) every cmd_update `pack_relpath` is named in the block (drift-prevention). | Location choice: `init-project.sh` (NOT validate-pack.py) is the simplest-correct location per §5.3 — the inventory lives where the install logic lives, so an actor adding a new copy-site writes both in the same file. Check 41 enforces the discoverability contract from validate-pack.py side. Check 40 already taken; Check 41 is the next available. See §4 for the design refinements vs. the §5.3 sketch. |

## §3 Implementation details

### §3.1 cmd_update additions (init-project.sh:cmd_update())

12 new entries added inline, grouped by observation source with inline
rationale comments per the existing style:

- 2 entries for **B** (pm-startup per-CLI skills): `.claude/skills/pm-startup/SKILL.md`, `.codex/skills/pm-startup/SKILL.md`
- 1 entry for **A** (pm-startup.toml gemini surface)
- 7 entries for **D** (per-entry templates: backlog _rules/_intro; implementation-plan _rules/_intro; changelog _rules/_intro/_format)
- 2 entries for **F** (supporting-docs/METHODOLOGY.md, supporting-docs/INSTALL-PROCEDURES.md)

### §3.2 cmd_update removals

1 entry removed for **E**: the stale `project-template/docs/pack/PROMPT-TEMPLATES.md` mapping (file retired in v10.0). Replaced by an inline comment block explaining the removal + the BD-180 reverse-direction check that would have caught the drift sooner.

### §3.3 Install-loop additions (S11 / init-project.sh:stage_s11_v11_artifacts())

1 new S11 explicit-copy block for **A**: parallel to the pack-help.toml block (lines 855-871), added immediately after — copies `project-template/.gemini/commands/pm-startup.toml` to `$TARGET/.gemini/commands/pm-startup.toml` using `$copy_fn` (so the existing-classifier-copy contract is respected for existing-* clients).

### §3.4 Check 39 extension (validate-pack.py:check_cmd_update_symmetry())

Forward direction preserved as-is (BD-175 F2a contract; `docs/pack/*.md` scope; `_CHECK_39_EXEMPTIONS` allowlist).

New reverse direction:
- Iterates the parsed `cmd_update` entries set from `_parse_cmd_update_entries()` (no duplicate parsing — reuses the BD-175 F2a parser).
- For each entry, checks `(REPO_ROOT / pack_rel).is_file()`. If not, FAILs with an actionable message (remove the entry OR allowlist via `_CHECK_39_REVERSE_EXEMPTIONS`).
- `_CHECK_39_REVERSE_EXEMPTIONS: dict[str, str]` — default empty; intentional extern-resolved paths only.

Combined PASS message reports both directions: forward-checked counts AND reverse-checked counts.

### §3.5 Check 41 design (validate-pack.py:check_client_installed_files())

New `_CHECK_41_EXEMPTIONS: dict[str, str]` allowlist (default: empty).

New `_parse_client_installed_files() -> tuple[list[str], bool, bool]` parser:
- Returns `(entries, start_seen, end_seen)`.
- Locates `_CLIENT_INSTALLED_FILES_START` and `_CLIENT_INSTALLED_FILES_END` markers (each MUST appear at least once).
- Extracts the body between markers via regex.
- Per line: strips leading `#`, requires `->` separator, takes the LHS-of-`->` as `pack_relpath`.
- Comment-only lines without `->` are skipped (allows free-form documentation inside the block).

New `check_client_installed_files()`:
- Verifies markers + non-empty block.
- (c) Iterates entries: each `pack_relpath` must `.is_file()` at HEAD. Allowlist via `_CHECK_41_EXEMPTIONS`.
- (d) Iterates `cmd_update` entries: each MUST appear in the inventory set. Drift-prevention assertion.

Registered in `main()` AFTER Check 40 (independent surfaces; ordering preference: install-coverage → cross-reference → inventory-drift).

## §4 Self-documenting list design (observation G refinements vs. ARCHITECTURE-BD-176.md §5.3)

Per pack memory **architect-doc-vs-reality-reconciliation**: BD-180
implementation realizes the ARCHITECTURE-BD-176.md §5.3 design sketch.
This section documents what changed vs. the sketch + the reconciliation
chain.

### §4.1 Sketch (ARCHITECTURE-BD-176.md §5.3)

The sketch proposed:
- A comment block above stage S6 + stage S11 listing the explicit copy-sites (file paths from `$PACK/` to `$TARGET/`).
- A corresponding `validate-pack.py` Check (proposed: Check 40) that asserts each listed file exists, is grep-matched against the corresponding `init-project.sh` line, and the surrounding directory is in the RC9 trigger glob.

### §4.2 Refinements applied in BD-180 implementation

| Sketch | Implementation | Rationale |
|---|---|---|
| "Comment block above stages S6 + S11" | Single comment block immediately AFTER `cmd_update()` body close, before `blast_radius_sweep()` definition. | Single discoverability anchor (better DRY than 2 blocks). The block is "about install paths in general" rather than per-stage, so co-location with the cmd_update array (the largest single install path) is the natural reading order. |
| "Check 40" | Check 41 (Check 40 was claimed by BD-179 between BD-176 architect doc and BD-180 implementation). | Check number availability. The sketch's "e.g., Check 40" wording explicitly allowed substitution. |
| "Assert each file exists ... grep-matched against init-project.sh line ... directory in RC9 trigger glob" | Asserts (a) markers exist, (b) ≥1 entry, (c) every entry's pack_relpath exists at HEAD, (d) every cmd_update path is listed in the inventory. Does NOT grep-match against init-project.sh source lines; does NOT cross-check against RC9 trigger glob. | Simpler-correct: (a)-(d) catch the BD-176 D4 failure mode (stale or missing inventory entry) without the complexity of grep-matching install-loop source. The RC9 trigger glob is already enforced by the CI manifest-rebuild gate (BD-176 Phase 1); duplicating it in Check 41 is redundant. The (d) cross-check is the load-bearing drift-prevention assertion. |
| (sketch implicit) | Added "Intentionally NOT installed" sub-section inside the inventory header comment, with observation C's `settings.local.example.json` as the seed entry. | Discoverability extension: an actor asking "why does this exist if it never installs?" finds the answer at the canonical inventory location. Future intentional non-install files (if any) extend this list. |

### §4.3 Reconciliation chain (per pack memory architect-doc-vs-reality-reconciliation)

- **(a) In-code reference** in `scripts/init-project.sh` self-documenting comment block: "BD-180 observation G per ARCHITECTURE-BD-176.md §5.3" + "validate-pack.py Check 41 ... asserts the inventory matches".
- **(b) Architect-doc addendum** NOT added in this BD: ARCHITECTURE-BD-176.md §5.3 is read-only per the prompt; the addendum cross-referencing BD-180's realization should be added by a follow-up Pack-Chat-direct edit OR rolled into Pack Chat's BD-180 close. Surfacing here as a NOTE rather than executing the edit (architect-doc edit is out of scope per the prompt).
- **(c) IMPL-REPORT cross-reference** is this section (§4).

The architect-doc addendum follow-up is NOT a deferral — it is a
Pack-Chat-direct edit (per pack memory "What Pack Chat CAN edit
directly" → ARCHITECTURE docs are NOT in that list, but the trigger is
"architect-doc-vs-reality-reconciliation" which calls for a small
addendum; if Pack Chat determines this needs an architect spawn, that
is Pack Chat's discretion). For BD-180's success criteria, the
in-code reference (a) + this IMPL-REPORT (c) are sufficient.

## §5 Files modified

| Path | Change type | Lines added (approx) | Purpose |
|---|---|---|---|
| `scripts/init-project.sh` | modified | +88 (cmd_update entries +21; S11 pm-startup.toml block +7; self-doc inventory comment +60; inline rationale comments +others) | Observations A (S11 + cmd_update), B (cmd_update), D (cmd_update), E (remove stale entry; add inline comment), F (cmd_update), G (self-doc inventory). |
| `scripts/validate-pack.py` | modified | +234 (Check 39 reverse-direction extension; new Check 41 + parser + allowlist; header docstring updates) | Observation E (Check 39 reverse-direction); observation G (new Check 41). |
| `scripts/tests/test-validate-pack-check-39.sh` | modified | +120 (new Group 2b with T6/T7/T8/T9 reverse-direction tests; updated T4 to satisfy reverse direction; updated Group 4 patterns for new header text) | Coverage for Check 39 reverse-direction extension. |
| `scripts/tests/test-validate-pack-check-41.sh` | new | 297 | New test for Check 41 (4 groups: module-import, real-init parse, synthetic PASS/FAIL T1-T7, end-to-end). |
| `test-fixtures/manifest.txt` | modified | 3 SHA updates (v11-realistic-ot, v11-flat-file, v11-tracker-on) | RC9 regen — `init-project.sh` edits + new pm-startup.toml install drove v11-* fixture content drift (expected per RC9 contract). |

No edits outside the in-scope set. Trinity files UNCHANGED. Architect
doc edits UNCHANGED (ARCHITECTURE-BD-176.md §5.3 read-only per prompt).
BACKLOG/CHANGELOG/README UNCHANGED (Pack Chat scope).

## §6 Test coverage

### §6.1 Existing tests still PASS

| Test | Before | After |
|---|---|---|
| `bash scripts/tests/test-validate-pack-check-39.sh` | 5 PASS / 0 FAIL | 6 PASS / 0 FAIL (added Group 2b reverse-direction) |
| `bash scripts/tests/test-validate-pack-check-40.sh` | 8 PASS / 0 FAIL | 8 PASS / 0 FAIL (no change) |
| `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` | 6 PASS / 0 FAIL | 6 PASS / 0 FAIL (no change) |
| `bash scripts/tests/test-init-project.sh` | 67 PASS / 0 FAIL | 67 PASS / 0 FAIL (no change) |
| `bash scripts/tests/test-customization-preserve.sh` | 233 PASS / 0 FAIL | 233 PASS / 0 FAIL (no change) |
| `bash scripts/tests/test-v11-realistic-ot.sh` | 33 PASS / 0 FAIL | 33 PASS / 0 FAIL (no change) |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43 PASS / 0 FAIL | 43 PASS / 0 FAIL (no change) |
| `bash scripts/persona-contracts/contract-greenfield.sh` | 191 PASS / 0 FAIL | 191 PASS / 0 FAIL (no change) |
| `bash scripts/persona-contracts/contract-mid-dev.sh` | 25 PASS / 0 FAIL | 25 PASS / 0 FAIL (no change) |
| `bash scripts/persona-contracts/contract-migration.sh` | 37 PASS / 0 FAIL | 37 PASS / 0 FAIL (no change) |

### §6.2 New tests added

- `scripts/tests/test-validate-pack-check-39.sh` Group 2b — 4 new
  reverse-direction synthetic tests (T6 reverse-PASS, T7 reverse-FAIL
  with stale entry, T8 reverse-PASS-with-exemption, T9 combined
  forward+reverse failures).
- `scripts/tests/test-validate-pack-check-41.sh` — new test (4 groups,
  ~10 sub-tests; same harness pattern as Check 39 test). Covers
  module-import, real-init parse, synthetic PASS/FAIL T1-T7 (PASS;
  stale-inventory-entry; inventory-drift; PASS-with-exemption;
  missing START marker; missing END marker; empty block),
  end-to-end exit-status.

## §7 Verification

### §7.1 Validate-pack.py at HEAD

```
$ python3 scripts/validate-pack.py 2>&1 | tail -8
── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

============================================================
PASSED — all checks clean
```

Exit code: 0.

### §7.2 Check 39 test (extended)

```
$ bash scripts/tests/test-validate-pack-check-39.sh 2>&1 | tail -5
=== Summary ===
  PASS: 6
  FAIL: 0

All tests passed.
```

### §7.3 Check 41 test (new)

```
$ bash scripts/tests/test-validate-pack-check-41.sh 2>&1 | tail -5
=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

### §7.4 Other related tests

```
$ bash scripts/tests/test-validate-pack-check-40.sh 2>&1 | tail -3
  PASS: 8
  FAIL: 0
All tests passed.

$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>&1 | tail -3
  PASS: 6
  FAIL: 0
All tests passed.

$ bash scripts/tests/test-init-project.sh 2>&1 | tail -3
Passed: 67
Failed: 0
All tests passed.

$ bash scripts/tests/test-customization-preserve.sh 2>&1 | tail -3
Passed: 233
Failed: 0
All tests passed.

$ bash scripts/tests/test-v11-realistic-ot.sh 2>&1 | tail -3
PASS: 33
FAIL: 0
All v11-realistic-ot integration tests PASSED (33/33).

$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -3
Passed: 43
Failed: 0
All tests passed.

$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -1
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -1
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -1
=== migration contract: 37 passed, 0 failed ===
```

All green.

### §7.5 Functional verification (observation A install now works)

```
$ find test-fixtures/v11-flat-file -name "pm-startup*" 2>/dev/null
test-fixtures/v11-flat-file/.gemini/commands/pm-startup.toml
test-fixtures/v11-flat-file/.gemini/skills/pm-startup
test-fixtures/v11-flat-file/.claude/skills/pm-startup
test-fixtures/v11-flat-file/.codex/skills/pm-startup
```

The newly-added S11 explicit-copy block successfully installs
`.gemini/commands/pm-startup.toml` to fresh-install clients (was
ABSENT before this BD).

## §8 RC9 manifest status

- **Trigger fired:** YES — `scripts/init-project.sh` and
  `scripts/validate-pack.py` are both under `scripts/`. Also
  `scripts/tests/test-validate-pack-check-41.sh` is new (test file;
  not a copied-to-clients file, but `scripts/` directory trigger fires
  inclusively per RC9 design).
- **Rebuild result:** `bash test-fixtures/build.sh --all --clean`
  produced **non-empty diff** (3 SHAs changed):
  - `v11-realistic-ot`: `47e5ea26...` → `add3450a...`
  - `v11-flat-file`: `e0e4e081...` → `991dfa30...`
  - `v11-tracker-on`: `84f66214...` → `9cf47786...`
  - `v10-*` and `existing-project-mid-dev` rows UNCHANGED (v10 fixtures
    tag-pinned; the mid-dev fixture is a pre-install synthesized
    Swift+Python+gRPC tree).
- **Stage manifest?** YES — Pack Chat MUST `git add test-fixtures/manifest.txt`
  alongside the scope edits in the same commit (per RC9 contract).
  Drift is **expected and correct** — the new pm-startup.toml install
  + the new cmd_update mappings change what gets copied at install
  time, so v11-* fixture content shifts. The v11-* rows in `test-
  fixtures/manifest.txt` are the canonical authority confirming the
  rebuild succeeded with the new install logic.
- **DOES NOT stage manifest:** the coder agent does NOT run `git add`
  per pack memory `feedback_agents_never_commit`. Pack Chat owns the
  staging step.

## §9 P-missed-7 boundary discipline

**Project-template/ edits in this BD:** ZERO. All edits are pack-side
(scripts/, test-fixtures/manifest.txt).

**Substance audit:** verified each cmd_update addition references a
file that already exists under `project-template/` (the install
mechanism gains awareness of these files; no new project-side files
were created). The pm-startup.toml file already existed at `project-
template/.gemini/commands/pm-startup.toml`; this BD's S11 addition
copies it to clients. No project-template substance changes.

**No project-side SSOT investigation needed:** P-missed-7's failure
mode is "project-side acquires pack-only reference / pack-internal
mechanism." This BD adds pack-internal install machinery + a
pack-internal validate check. The new self-documenting inventory and
the new Check 41 are validate-pack tooling (pack-side); they do not
appear in any project-shipped file.

**Boundary safe by construction:** no project-side surface touched;
no pack-only reference threatens to enter a project-shipped surface
via this BD.

## §10 Carry-forward discipline

**SIZE / BLOCKED / LOGICAL-FIT high bar applied:** ZERO deferrals.

All 7 observations (A–G) were closed in this BD. No scope-adjacent
discoveries surfaced during implementation that required separate-BD
treatment. Specifically, I checked for the following candidate
deferrals and rejected each per the high bar:

- **Architect-doc-vs-reality addendum to ARCHITECTURE-BD-176.md §5.3.**
  Could be folded into BD-180 as a 1-line "Realized in BD-180 — see
  IMPLEMENTATION-REPORT-BD-180.md §4." Decision: surfaced as a Pack-
  Chat-direct edit recommendation in §4.3 (not a coder edit; the
  architect doc is read-only per the prompt). This is NOT a deferral
  — it's an out-of-scope architect doc edit that Pack Chat can decide
  to handle inline or as part of BD-180 close.

- **Extend `_cmd_update_iter_dir` to also walk the canonical
  `project-template/skills/` pool.** Would obviate the per-CLI
  pm-startup + pack-help mappings via a single canonical-pool
  iteration. Decision: FAILS the SIZE high bar (architect-pass material:
  the refactor crosses `_cmd_update_iter_dir`'s contract surface +
  the BD-088 customization-preserve dispatch; would require its own
  ARCHITECTURE doc). Also FAILS BLOCKED (no current blocker). PASSES
  LOGICAL-FIT vaguely (same code area), but the LOGICAL-FIT criterion
  per the review skill requires "concrete same-file / same-contract /
  same-symbol fit, not thematic resemblance." Refactoring
  `_cmd_update_iter_dir` would extend its symbol to a new shape
  (iterating a structurally-different source location), not a
  same-symbol fit. Surfacing only as a NOTE here — not a new BD,
  not deferred work. If Pack Chat triages this as warranted, it
  belongs in a future BD with architect-pass treatment.

- **Add ISSUE_TEMPLATE/*.yml glob-walking to `_cmd_update_iter_dir`
  parallel to scripts/agents.** Would replace the 3 explicit
  ISSUE_TEMPLATE entries with a glob loop. Decision: same SIZE/LOGICAL-FIT
  analysis as above. Not warranted in BD-180.

Zero deferrals after high-bar applied. Per the OQ-1 rewritten
EXECUTION-PLAN §B + W8 contract, no new-BD-opens triggered by this
BD's implementation.

## §11 Architect-doc-vs-reality reconciliation

BD-180 observation G implementation realizes the
ARCHITECTURE-BD-176.md §5.3 design sketch. Per pack memory
`architect-doc-vs-reality-reconciliation` (load-bearing for any
future-shipped surface that pre-existed in an architect doc):

- **(a) In-code reference:** `scripts/init-project.sh` self-documenting
  comment block (lines added in BD-180 implementation) carries the
  text "BD-180 observation G per ARCHITECTURE-BD-176.md §5.3" and
  cross-references `validate-pack.py` Check 41 by name. Searchable
  symbol: `_CLIENT_INSTALLED_FILES_START` / `_CLIENT_INSTALLED_FILES_END`.

- **(b) Architect-doc addendum:** ARCHITECTURE-BD-176.md §5.3 is
  read-only per the BD-180 coder prompt; addendum NOT added in this
  BD. Recommended Pack-Chat-direct follow-up (out of BD-180 coder
  scope per the prompt's "Files you must NOT modify without surfacing
  first: any architect doc"): add a 1-3 line addendum after §5.4 to
  cross-reference BD-180 IMPL-REPORT §4 (this section) as the
  realized-consumer record.

- **(c) IMPL-REPORT cross-reference:** §4 of this IMPL-REPORT
  documents the realization + the design refinements (Check 40 →
  Check 41 substitution; single-anchor block vs. dual-stage blocks).

This is the FIRST realized consumer of ARCHITECTURE-BD-176.md §5.3;
the pattern applied here matches BD-119 §9.2 → BD-160 (the canonical
worked-example anchor per pack memory).

## §12 Plan deviations

ZERO from the BD-180 prompt's success criteria. All 7 observations
resolved; reverse-direction check implemented as Check 39 extension
(per simplest-correct-design guidance in the prompt); self-documenting
list implemented per §5.3 with documented refinements (§4.2);
manifest regen completed and noted for Pack Chat staging.

Implementation choices made within the prompt's stated coder-judgment
latitude:

- **Check 39 extension vs. new Check 41 for reverse-direction:** chose
  Check 39 extension (rationale §3.4: reverse direction IS cmd_update
  symmetry — naturally belongs in the same check).
- **Check 41 used for self-documenting list:** Check 40 already taken
  (BD-179); the sketch's "e.g., Check 40" wording allowed substitution.
- **Self-doc inventory location: `init-project.sh` not `validate-pack.py`:**
  the inventory lives where the install logic lives (rationale §4.2);
  enforces co-located maintenance.
- **Self-doc inventory format: simple `<pack_rel>  ->  <project_rel>  [stage:...]`:**
  parseable by regex without sourcing the shell file (consistent with
  Check 39 parsing approach).

## §13 New POQs introduced

None. All BD-180 scope items closed. No architectural questions
surfaced during implementation; the BD-176 §5.3 sketch was applied
with documented refinements (§4.2) that fall within "simplest-correct-
design" coder latitude (per the sketch's "informational only ... the
design lands in BD-180" closing line).

## §14 Definition-of-Done checklist

- [x] All 7 observations (A–G) resolved (with mappings OR documented exemptions)
- [x] `scripts/init-project.sh` cmd_update mapping is complete + accurate at HEAD (35 entries; 0 stale; 35/35 reverse-resolve)
- [x] Stale PROMPT-TEMPLATES.md mapping REMOVED (observation E)
- [x] Reverse-direction check implemented (chose Check 39 extension over new Check 41 per simplest-correct-design — Check 41 reserved for observation G)
- [x] Self-documenting "files copied to clients" list per observation G + ARCHITECTURE-BD-176.md §5.3 (38 entries; PASS via Check 41)
- [x] All checks pass: `python3 scripts/validate-pack.py` exits 0
- [x] All Check 39 tests pass (6/6); all Check 41 tests pass (4/4)
- [x] All adjacent tests still PASS: Check 40 (8/8), Checks 36/37/38 (6/6), init-project (67/67), customization-preserve (233/233), v11-realistic-ot (33/33), migrate-v10-to-v11 (43/43), persona contracts (greenfield 191/0, mid-dev 25/0, migration 37/0)
- [x] Manifest regen + non-empty diff (3 v11-* SHAs drift; staging deferred to Pack Chat per agents-never-commit rule)
- [x] IMPL-REPORT documents per-observation decision (fix vs exemption + rationale) — see §2 table
- [x] P-missed-7 boundary check: zero project-template/ edits; no project-side SSOT investigation required (§9)
- [x] Carry-forward discipline applied: ZERO deferrals after high-bar (§10)
- [x] Architect-doc-vs-reality reconciliation: in-code reference (a) + IMPL-REPORT cross-reference (c) present; architect-doc addendum (b) surfaced for Pack-Chat-direct follow-up (§11)
- [x] No state-changing git verbs run (only `git rev-parse`, `git status`, `git diff`)
- [x] Trinity files UNCHANGED
- [x] Architect doc UNCHANGED (ARCHITECTURE-BD-176.md §5.3 read-only per prompt)
- [x] BACKLOG / CHANGELOG / README UNCHANGED (Pack Chat scope)
- [x] PREFLIGHT line emitted before IMPL-REPORT write (separate from this report)

## §15 Files-changed inventory

| Path | Change type |
|---|---|
| `scripts/init-project.sh` | modified |
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-validate-pack-check-39.sh` | modified |
| `scripts/tests/test-validate-pack-check-41.sh` | new |
| `test-fixtures/manifest.txt` | modified (RC9 regen output) |

Untracked file in working tree NOT touched by this BD:
`maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md`
(pre-existing untracked file from a prior session; out of BD-180 scope;
should NOT be staged with BD-180's commit).

## §16 PREFLIGHT line

Emitted in the final assistant message after this IMPL-REPORT write.
