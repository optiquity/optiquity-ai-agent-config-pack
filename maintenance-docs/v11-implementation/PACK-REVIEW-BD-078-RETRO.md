# PACK-REVIEW-BD-078-RETRO — Retroactive per-BD review of BD-078

**Reviewer:** pack-reviewer (retroactive per-BD pass for Batch 21c)
**BD reviewed:** BD-078 — `validate-pack.py` Check (`check_tracker_config`)
**Original ship commit:** `91a9fc5` (2026-05-09; combined Batch 11 commit
covering BD-112 + BD-078 + BD-079)
**Review date:** 2026-05-15
**Review scope (BD-078 portion only):**
- `scripts/validate-pack.py` — new `check_tracker_config()` Check 29
  (lines ~2148–2283 in current HEAD), helpers `_validate_tracker_toml()`
  and constants `_TRACKER_BACKENDS / _TRACKER_MODES / _TRACKER_PREFER /
  _TRACKER_SCHEMA_VERSION`, `import json`, docstring entry, `main()`
  wire-in.
- `scripts/tests/tracker-config-schema-test.sh` (NEW) — 9-scenario
  fixture suite, 17 assertions.
- BD-078 portion of
  `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`
  (note: the active path at ship time was
  `maintenance-docs/v11-implementation/`; archived to v11/ subsequently).

**Out of scope (BD-079 / BD-112 portions of `91a9fc5`):**
- `scripts/lib/customization-preserve.sh` (BD-112)
- `scripts/tests/test-customization-preserve.sh` (BD-112)
- `scripts/tests/recommendation-state-schema-test.sh` (BD-079)
- Check 30 / `check_recommendation_state_schema()` /
  `_REC_STATE_SCHEMA*` constants (BD-079)
- The BD-079 entry in the joint implementation report

**Methodology constraints honored:** No `PACK-REVIEW-*.md` files
consulted. Reference set drawn from BD-078's `BACKLOG.md` entry,
`ARCHITECTURE.md` §3.1 + §A.2 (V1 — the canonical spec doc the BACKLOG
entry cites), `EXECUTION-PLAN-V11.0.md` Batch 11 row, the
joint implementation report (BD-078 section only), and
`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (6 dimensions +
touch-point classification).

---

## 1. Scope declaration

### Concept being reviewed
"Pack-side schema validation for `tracker.toml` example files at CI
time" — the pre-flight gate that catches schema drift in the example
files which `init-project.sh` ships to clients.

### Binding invariant
Every committed `tracker.toml.*-example` file in the pack MUST conform
to the live `scripts/lib/tracker-config.sh` reader's expectations and
to the schema documented in `ARCHITECTURE.md` §3.1.

### In-scope acceptance criteria (from `BACKLOG.md` BD-078 entry, lines 311-322)
1. **A:** Validates `tracker.toml` schema if present.
2. **B:** Warns if mode tracker but mirror files have stale
   `Last regenerated` timestamps relative to
   `tracker.toml.migration.last_forward_run` (per V1 §A.2).
3. **C:** Check number is "pedagogical — verify next-free integer at
   land-time per §6.C."

### Touch-point matrix vs adjacent concepts

| Concept | File touched by BD-078 | Class | Notes |
|---|---|---|---|
| Tracker config reader | `scripts/lib/tracker-config.sh` | SHARED-RO | Validator must stay in sync with reader's accepted schema; reader is BD-061's owner |
| Example files (pack & client) | `tracker.toml.pack-example` + `project-template/tracker.toml.project-example` | SHARED-RO | Owned by BD-061/BD-135; Check 29 is read-only verifier |
| CI workflow | `.github/workflows/validate-pack.yml` | SHARED-RW | New test scripts must be wired into CI for the gate to fire |
| `validate-pack.py` numbered-check ledger | `scripts/validate-pack.py` `main()` | OWNED | New check slot |

---

## 2. Methodology notes

### Artifacts surveyed
- `git show 91a9fc5 -- scripts/validate-pack.py` (full BD-078 diff).
- `git show 91a9fc5 -- scripts/tests/tracker-config-schema-test.sh`
  (full file, 269 lines).
- `BACKLOG.md` BD-078 entry (lines 311-322, including the "warns if
  mode tracker but mirror files have stale `Last regenerated`
  timestamps" criterion).
- `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1 (lines 473-524)
  and §A.2 (lines 2153-2182) — original spec for BD-078.
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
  Batch 11 row (line 295).
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`
  (BD-078 section, lines 46-135).
- Live tree: `tracker.toml.pack-example`,
  `project-template/tracker.toml.project-example`,
  `scripts/lib/tracker-config.sh`,
  `.github/workflows/validate-pack.yml`,
  `test-fixtures/v11-{tracker-on,flat-file}/tracker.toml.example`.
- Current `scripts/validate-pack.py` HEAD state (Check 29 unchanged
  since ship per `git diff 91a9fc5..HEAD -- scripts/validate-pack.py`).

### Tools used to ground findings
- `git show 91a9fc5 -- <path>` for original ship state.
- `git diff 91a9fc5..HEAD -- scripts/validate-pack.py` to confirm no
  Check 29 evolution since ship.
- `grep -rn` for cross-references to test script names and BD-078
  symbols across the repo.
- Live invocation: `python3 -c "..."` to import `validate-pack.py` and
  call `check_tracker_config()` against the live tree (passes 0 of 0
  failures; observation grounds the OK-path).

### Live verification
`python3 scripts/validate-pack.py` Check 29 output:
```
── Check 29: Tracker-config schema (BD-078) ──
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')
```
0 failures on live tree. The shipped portion of the check is
operating as designed. The findings below concern the spec gap, the
CI wiring gap, and the smaller correctness/false-negative surfaces.

---

## 3. Findings

### F1 — MUST — Acceptance criterion B (mirror staleness warning) was never implemented

- **Severity:** MUST
- **Dimension:** (a) Completeness
- **Touch-point class:** OWNED
- **Evidence:**
  - `BACKLOG.md` line 318-320 (BD-078 entry, `Description:`):
    > "warns if mode tracker but mirror files have stale
    > `Last regenerated` timestamps relative to
    > `tracker.toml.migration.last_forward_run` (per V1 §A.2)."
  - `maintenance-docs/v11-research/ARCHITECTURE.md` §A.2 lines
    2179-2182 (the V1 spec the BACKLOG entry cites verbatim):
    > "`scripts/validate-pack.py`: add Check 19
    > (`check_tracker_config`) that validates `tracker.toml`
    > schema if present and warns if mode tracker but mirror
    > files have stale `Last regenerated` timestamps relative
    > to `tracker.toml.migration.last_forward_run`."
  - Shipped `check_tracker_config()` (validate-pack.py:2266-2283):
    only invokes `_validate_tracker_toml` for both example files. No
    branch checks `mode.state == "tracker"`, no read of any mirror
    file's `Last regenerated:` header, no comparison against
    `migration.last_forward_run`.
  - `IMPLEMENTATION-REPORT-BD-078-BD-079.md` "Plan deviations"
    section (line 281): "None." — implementation report does not
    declare the half it dropped.
  - `IMPLEMENTATION-REPORT-BD-078-BD-079.md` "Deferred items" (line
    327): "None." — also does not declare the gap.
- **Description:** The shipped Check 29 implements only the first half
  of the BACKLOG/spec acceptance criteria (schema validation of the
  example files). The second half — the staleness warning — was
  silently dropped. The implementation report does not flag the
  deviation, the BACKLOG `Resolved:` line lists only the schema half,
  and the BD was flipped Resolved without the missing leg ever being
  discussed. The originally-spec'd value of Check 29 is "schema OK
  AND mirror not stale"; what shipped is "schema OK only," which is
  weaker than the spec contract.
- **Suggested fix:** Either (a) extend `check_tracker_config()` to
  add the staleness leg the spec calls out — when
  `tracker.toml.pack-example` (or live `tracker.toml`, depending on
  the design choice) declares `mode.state = "tracker"`, read the
  configured mirror files (`location_backlog` / `location_status` /
  `location_changelog`), parse the `Last regenerated:` header
  comment, compare against `migration.last_forward_run`, warn if
  any mirror is older — OR (b) carry the staleness leg forward as an
  explicit deferred item in BACKLOG (open a follow-up BD-NNN, cite
  V1 §A.2, and amend BD-078's `Resolved:` line to state which leg
  was implemented vs deferred). Path (b) is the lighter-weight close;
  the user / Pack Chat decides since BDs-for-fix require user
  initiation per pack memory.
- **Cross-concept impact:** Affects the broader "tracker integration
  pre-flight gates" concept (touches `scripts/lib/tracker-mirror.sh`
  semantics for the `Last regenerated:` header format if implemented).
  No re-architect needed.
- **Rule violated:** Pack rule "Fix all review findings, including
  nits" + `MEMORY.md` `feedback_review_fix_one_cycle.md` (per-BD
  acceptance criteria are the contract, not a menu). Also CONCEPTUAL-
  REVIEW-METHODOLOGY.md design principle 1 "Single source of truth"
  — the BACKLOG entry is the contract; shipped behavior diverges
  from contract without a deferral note.

### F2 — MUST — New test script not wired into CI; gate only fires on local invocation

- **Severity:** MUST
- **Dimension:** (c) Touch points + cross-concept impact
- **Touch-point class:** SHARED-RW
- **Evidence:**
  - `scripts/tests/tracker-config-schema-test.sh` exists in tree
    (BD-078 ship; 269 lines, executable, 17/17 PASS on local run).
  - `.github/workflows/validate-pack.yml` lines 110-213 enumerate
    every test script CI invokes. `grep -n "scripts/tests/"
    .github/workflows/validate-pack.yml` returns 19 invocations
    (lines 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146,
    149, 152, 155, 158, 161, 164, 167, 207, 210, 213). The string
    `tracker-config-schema-test` does not appear anywhere in
    `.github/workflows/`.
  - `grep -rn "tracker-config-schema-test"
    /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
    returns only the file's own header and its `Usage:` line. No
    aggregate runner / `Makefile` / orchestrator picks it up either.
  - The `--name "tracker-config tests (BD-061)"` step at line 117-119
    invokes `tracker-config-test.sh` (the BD-061 reader test),
    which is NOT the new BD-078 schema test (different file).
- **Description:** The fixture suite the implementation report lists
  as the test deliverable for BD-078 lives only on disk. CI never
  invokes it. Local-run-only test scripts have a known failure mode
  in this pack: `CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Race-condition
  detection heuristic" cites this exact pattern as a v11 procedural
  race ("CI workflow + new test scripts: test scripts exist on disk
  but workflow doesn't invoke them (Batch 17 BD-108 F1) — CI green
  doesn't mean tests ran"). BD-108's F1 retroactive review-fix
  added the missing CI step for `test-tracker-cycle-check.sh`
  precisely because this pattern was empirically catching pack
  defects. The BD-078 ship reproduced the same pattern.
- **Suggested fix:** Add a step to `.github/workflows/validate-pack.yml`
  in the per-suite block (after line 119's `tracker-config-test.sh`
  invocation, or grouped with the other tracker checks):
  ```yaml
  - name: tracker-config-schema tests (BD-078, validate-pack Check 29)
    if: always()
    run: bash scripts/tests/tracker-config-schema-test.sh
  ```
  (The same fix should be considered for
  `scripts/tests/recommendation-state-schema-test.sh` per BD-079,
  but that's out of this BD's scope — flag for the BD-079 retro
  review.)
- **Cross-concept impact:** Affects the "CI gate completeness"
  concept (BD-117 RELEASE-GATE.md owns the gate inventory; BD-118
  owns the CI workflow extensions). The fix is mechanical YAML
  addition — coordinate with the CI workflow owner so it ships in a
  single commit.
- **Rule violated:** Pack memory `feedback_review_fix_one_cycle.md`
  empirical race pattern named in CONCEPTUAL-REVIEW-METHODOLOGY.md
  § "Race-condition detection heuristic." Also pack design principle
  6 (Idempotency for orchestration verbs) inverted — the CI gate is
  not a gate at all if the test script isn't invoked; "PASSED — all
  checks clean" is misleading because Check 29's regression coverage
  was never exercised by CI.

### F3 — SHOULD — `schema_version = true` (or `= false`) silently passes

- **Severity:** SHOULD
- **Dimension:** (b) Edge cases (bounded)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/validate-pack.py` line 2200: `schema_version =
    _require("schema_version", int)`.
  - `_require` (line 2193): `if not isinstance(cur, expected_type)`.
  - In Python `isinstance(True, int) == True` (bool is a subclass of
    int). So `schema_version = true` in TOML loads as Python `True`,
    `isinstance(True, int)` is True, `_require` returns `True`.
  - Line 2201: `if schema_version is not None and schema_version !=
    _TRACKER_SCHEMA_VERSION`. `True != 1` is False (because `bool(True)
    == int(1)`). So the equality check ALSO passes.
  - Net result: `schema_version = true` produces no failure.
  - This problem is solved correctly by Check 30 / `_REC_STATE_SCHEMA`
    in lines 2308-2314 (the bool-rejecting branch the implementation
    report flagged for `user_re_enable_count`); BD-078 didn't apply
    the same defense.
- **Description:** The `_require()` helper does not defend against
  Python's bool-is-int quirk for the `int`-typed key. A malformed
  `tracker.toml` example with `schema_version = true` slips through
  Check 29 because (a) `isinstance(True, int)` is True and (b) `True
  == 1` evaluates True for the equality check. The same quirk is
  present for any future int-typed schema key added through `_require`.
  The fixture suite does not cover this edge (Test 2 only varies the
  numeric value to `99`; no bool-as-int case).
- **Suggested fix:** Add a `bool` rejection branch in the
  `_require` int path (mirroring Check 30's pattern at line
  2308-2314):
  ```python
  if isinstance(cur, bool) and expected_type is int:
      fail(f"{rel} — key {key_path}: expected int, got bool")
      failed = True
      return None
  ```
  Add a 10th fixture scenario to
  `scripts/tests/tracker-config-schema-test.sh` covering
  `schema_version = true` → expect non-zero exit + message "expected
  int, got bool".
- **Cross-concept impact:** None outside BD-078's owned helper.
- **Rule violated:** Design principle 7 (Additive grammar
  extensions) inverted — the validator must reject malformed
  grammar, not silently accept Python's permissive isinstance
  behavior. Internal-consistency principle: BD-079's
  `user_re_enable_count` defense and BD-078's `schema_version`
  defense should use the same defensive idiom.

### F4 — SHOULD — Validator scope drift vs spec-declared schema (V1 §3.1)

- **Severity:** SHOULD
- **Dimension:** (e) Design best practice adherence (single source of
  truth)
- **Touch-point class:** SHARED-RO
- **Evidence:**
  - `ARCHITECTURE.md` §3.1 lines 488-524 declares the canonical
    `tracker.toml` schema. Beyond what Check 29 verifies, §3.1 also
    declares: `backend.repo` (str, required for GH-backed installs),
    `backend.host` (str, optional — for GHE), `backend.instance` (str,
    optional — for Jira), `mode.opted_in_at` (str ISO 8601, set on
    opt-in), `mode.opted_in_by` (str email, set on opt-in),
    `migration.last_forward_run` (str ISO 8601 or null),
    `migration.last_reverse_run` (str ISO 8601 or null).
  - Check 29 verifies none of `backend.repo` / `backend.host` /
    `backend.instance` / `mode.opted_in_*` / `migration.last_*_run`.
  - Live `tracker.toml.pack-example` line 21 ships with `repo =
    "DShaneNYC/optiquity-ai-agent-config-pack"`; live
    `project-template/tracker.toml.project-example` line 25 ships with
    `repo = "your-org/your-project"`. Both are expected by
    `tracker_repo_slug()` (`scripts/lib/tracker-config.sh` line 217)
    and `tracker_gh_repo_setup()` (line 252-262), which silently
    no-op when missing — exactly the failure mode the validator was
    supposed to catch by gating example-file shape.
- **Description:** Check 29 validates a strict subset of the
  spec-declared schema. The omitted keys include `backend.repo`,
  which the live runtime reads from `tracker_repo_slug()` to set
  `GH_REPO` and is the difference between every-`gh`-call-works vs
  every-`gh`-call-fails-with-a-misleading-error (BD-129 / D-1's
  whole motivating problem). If the example files ship without
  `backend.repo`, fresh installs propagate the breakage exactly as
  the implementation report's stated motivation says it should
  catch ("If the examples fall out of sync with the live
  scripts/lib/tracker-config.sh reader expectations, every fresh
  install propagates the breakage" — `check_tracker_config()`
  docstring at validate-pack.py line 2274-2276).
- **Suggested fix:** Add `_require("backend.repo", str)` with empty-
  string rejection (parallel to the existing `migration.mapping_file`
  treatment at line 2252-2253). Optionally add presence of
  `backend.host` / `backend.instance` only when validated with conditional
  logic on `backend.name`. This is incremental: pick the highest-
  payoff missing key first (`backend.repo`), test it, ship it; the
  rest are decorative for v11.0 single-backend ("github") scope.
  Add a fixture scenario for missing/empty `backend.repo`.
- **Cross-concept impact:** SHARED-RO with BD-129 (gh repo setup
  surface). No re-architect needed; the validator is the right
  place to gate this.
- **Rule violated:** Design principle 1 (Single source of truth) —
  the spec at V1 §3.1 declares one schema; the validator enforces a
  strict subset; the runtime depends on a key the validator doesn't
  gate. Validator-Check empirical risk surface "schema completeness
  vs the spec it validates" cited in this review's prompt.

### F5 — SHOULD — Validator stale doc reference (`ARCHITECTURE.md §3.1` ambiguity)

- **Severity:** SHOULD
- **Dimension:** (d) Pack rule adherence
- **Touch-point class:** OWNED (docstring text inside Check 29)
- **Evidence:**
  - `scripts/validate-pack.py` line 88 (top-of-file docstring): "and
    carry the required keys/types per ARCHITECTURE.md §3.1".
  - `scripts/validate-pack.py` line 2271
    (`check_tracker_config()` docstring): "and carry the required
    keys/types per ARCHITECTURE.md §3.1."
  - The pack repo has no committed `ARCHITECTURE.md` at the root or
    in `project-template/`. The cited spec lives at
    `maintenance-docs/v11-research/ARCHITECTURE.md` (the V1 doc).
    The pack also has `ARCHITECTURE-V2.md`, `ARCHITECTURE-V3.md`,
    `ARCHITECTURE-V3.{1,2,3}-DELTA.md` siblings in the same dir.
  - A pack contributor opening `validate-pack.py` and looking up
    "ARCHITECTURE.md §3.1" from the docstring will not find the
    file; the reference is unqualified.
- **Description:** Both docstring sites refer to the spec by bare
  filename only. In a repo with V1 / V2 / V3 / V3.x deltas all
  named `ARCHITECTURE-*.md` plus the bare `ARCHITECTURE.md` (V1),
  bare references are ambiguous, especially since the cited §3.1
  schema also appears in V3.md and may evolve. Pack convention per
  `MEMORY.md` `feedback_filename_uniqueness.md` is to disambiguate
  references in prose.
- **Suggested fix:** Replace both occurrences with full path
  qualification: `maintenance-docs/v11-research/ARCHITECTURE.md
  §3.1` (the V1 doc that is the canonical schema source the BACKLOG
  entry cites verbatim — BD-078's BACKLOG entry says "(V1 §A.2)").
  Alternatively, cite the V3 superseding section if the schema
  has been updated there. Verify which doc is the active spec at
  the time of the fix.
- **Cross-concept impact:** None.
- **Rule violated:** `MEMORY.md` `feedback_filename_uniqueness.md`
  ("prefer unique filenames so prose references are unambiguous";
  exemptions for trinity / SKILL.md / byte-identical mirrors /
  ecosystem-fixed names — none apply here).

### F6 — NIT — Test fixtures `test-fixtures/v11-{tracker-on,flat-file}/tracker.toml.example` not validated

- **Severity:** NIT
- **Dimension:** (c) Touch points + cross-concept impact
- **Touch-point class:** SHARED-RO
- **Evidence:**
  - `find tracker.toml.*example` returns four files:
    - `tracker.toml.pack-example` (root)
    - `project-template/tracker.toml.project-example`
    - `test-fixtures/v11-flat-file/tracker.toml.example`
    - `test-fixtures/v11-tracker-on/tracker.toml.example`
  - `check_tracker_config()` lines 2279-2280 hardcode only the first
    two paths.
  - The test-fixture variants are committed pre-built fixtures used
    by `test-fixtures/build.sh` (BD-115/116/117) and the migration
    test harness (BD-085/095/101). They claim to be example
    `tracker.toml` files (filename pattern matches exactly).
- **Description:** The validator has a strict "validate the example
  files we ship" goal but stops at two of four committed example
  files. The two test-fixture examples are not exercised by Check 29.
  If those fixtures drift from the live schema, the migration tests
  silently use stale shapes.
- **Suggested fix:** Either (a) extend Check 29 to also validate the
  two test-fixture files (with caveats — the test fixtures may
  intentionally model historical/pinned shapes for migration regression
  coverage, in which case adding them to Check 29 is incorrect), OR
  (b) add a docstring note + visible exclusion at the top of
  `check_tracker_config()` documenting which `tracker.toml.*example`
  files are intentionally excluded and why. Path (b) is lighter and
  may be the right call given migration-fixture immutability concerns.
  This is a NIT only because it's downstream of the BD-078 ship-time
  scope (fixtures for BD-115+ existed but were tangential).
- **Cross-concept impact:** SHARED-RO with BD-115/116/117 (fixture
  ownership). Coordinate before any extension.
- **Rule violated:** None directly; design principle 1 (single source
  of truth — what defines an "example file" the validator gates?) is
  ambiguous, not violated.

### F7 — NIT — Unused local variable `VALIDATOR` in test script

- **Severity:** NIT
- **Dimension:** (e) Design best practice adherence (dead code)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/tests/tracker-config-schema-test.sh` line 28:
    `VALIDATOR="$REPO_ROOT/scripts/validate-pack.py"`.
  - `grep -n "VALIDATOR" scripts/tests/tracker-config-schema-test.sh`
    returns only line 28 (the assignment). The variable is never
    read.
- **Description:** Dead local variable left over from an earlier
  design where the test invoked the validator as a subprocess. The
  current `run_check29_at()` uses `importlib` to load
  `validate-pack.py` as a module instead — the path is constructed
  inline at line 48. The `VALIDATOR` assignment is unused.
- **Suggested fix:** Delete line 28
  (`VALIDATOR="$REPO_ROOT/scripts/validate-pack.py"`).
- **Cross-concept impact:** None.
- **Rule violated:** Pack design hygiene (dead code).

### F8 — NIT — `_ = (fwd, rev)` lint-silencer is a code smell

- **Severity:** NIT
- **Dimension:** (e) Design best practice adherence (clarity)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/validate-pack.py` lines 2249-2258:
    ```python
    fwd = _require("migration.forward_complete", bool)
    rev = _require("migration.reverse_available", bool)
    mapping = _require("migration.mapping_file", str)
    ...
    # Silence unused-binding lint; the _require side effects ...
    _ = (fwd, rev)
    ```
  - The author explicitly comments why `fwd` and `rev` are bound
    but unused: `_require()`'s side effect (registering a `fail()`
    on missing key / wrong type) is the load-bearing call.
- **Description:** Functional behavior is correct; the comment is
  accurate. But the construct trains future readers to expect this
  pattern, and the alternative is cleaner: just call `_require`
  without binding — the side effect fires regardless.
- **Suggested fix:** Replace the three lines with bare calls:
  ```python
  _require("migration.forward_complete", bool)
  _require("migration.reverse_available", bool)
  mapping = _require("migration.mapping_file", str)
  ```
  Drop the comment + `_ = (fwd, rev)` line. (The `mapping` binding
  is genuinely used at line 2252 for the empty-string check, so it
  stays.)
- **Cross-concept impact:** None.
- **Rule violated:** None directly; pack design principle "smallest
  correct surface area" — bare calls express intent more directly
  than a captured-and-discarded binding plus a 4-line comment
  explaining the pattern.

### F9 — NIT — Implementation report stored under archive/v11/, but BACKLOG `Resolved:` line points to `v11-implementation/`

- **Severity:** NIT
- **Dimension:** (c) Touch points + cross-concept impact
- **Touch-point class:** SHARED-RO
- **Evidence:**
  - `BACKLOG.md` line 322 (BD-078 `Resolved:`):
    "see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-BD-079.md`."
  - `find … -name "IMPLEMENTATION-REPORT-BD-078*"`:
    only hit is `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`.
  - `maintenance-docs/v11-implementation/` does not contain the
    file (it was archived after the doc-sweep at some Batch
    boundary; the BACKLOG `Resolved:` line was not updated when the
    sweep happened).
- **Description:** A reader following the BACKLOG resolution link
  will hit a 404 in their head until they realize archived docs
  live elsewhere. Cross-reference rot from a doc sweep that didn't
  back-update the BACKLOG entries that point at swept files.
- **Suggested fix:** Update BD-078 (and any sibling BDs whose
  `Resolved:` lines point to swept-but-archived implementation
  reports) to use the current path:
  `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`.
  This is a Pack-Chat-only edit (BACKLOG.md is PM-chat-owned per
  CLAUDE.md), so the reviewer surfaces the finding; Pack Chat
  applies the fix.
- **Cross-concept impact:** Affects every other BD whose
  implementation report has been archived under
  `maintenance-docs/archive/v11/` since ship — likely a sweep-wide
  fix beyond just BD-078.
- **Rule violated:** Pack ops/product separation maintained; this is
  ops-doc rot. Pack memory `feedback_filename_uniqueness.md`
  applies indirectly (the reference in BACKLOG should be
  unambiguous and locatable).

---

## 4. Coverage notes

In scope but not deeply reviewed:
- The TOML parse-error path (Test 9) of the fixture script. Visually
  confirmed the failure scenario; trusted the existing test pass
  rather than mutate to multi-line-string / surrogate-byte bombs.
- `_validate_tracker_toml`'s `ok()` summary message format. Cosmetic;
  no finding.
- The `[graph] cycle_check_k` optional section added by BD-108 after
  BD-078 ship. Check 29 correctly does nothing with it (additive
  schema extension, not in BD-078's scope to validate). Confirmed
  live tree passes when the live `tracker.toml.pack-example` carries
  the commented-out `[graph]` block.
- Fixture script's `mktemp -d -t` portability. macOS BSD utils +
  Linux GNU utils both accept the syntax used; bash 3.2 compatibility
  flagged in DOD checklist and verified by inspection.

Out of scope but adjacent:
- BD-079's `check_recommendation_state_schema` and its test script
  (parallel orphan-from-CI risk identified — see F2 cross-reference;
  flag for BD-079's own retro review).
- BD-112's three-way diff fix and its test additions (independent
  scope per the implementation report's "no file overlap" note).

---

## 5. Re-architect summary

**No `ARCH`-severity findings.**

All 9 findings are MUST / SHOULD / NIT and have concrete
in-place fixes that don't require touching cross-concept contracts.
No Re-architect pass needed.

The MUST findings (F1, F2) are spec-vs-shipped gaps and CI-wiring
gaps respectively — both fix-with-existing-mechanisms tasks. The
SHOULD findings (F3, F4, F5) are validator-completeness improvements
within the same Check 29 surface. The NIT findings (F6-F9) are
hygiene.

---

## 6. Methodology friction notes

Issues encountered applying CONCEPTUAL-REVIEW-METHODOLOGY.md to
per-BD review of BD-078:

1. **The 6 dimensions are concept-level by design; per-BD review of
   a validator-Check is closer to "does the shipped code match the
   spec'd contract?" than the cross-cutting concept questions the
   methodology was built for.** Dimension (a) Completeness mapped
   cleanly to "did all spec'd acceptance criteria ship?" (F1).
   Dimension (c) Touch points mapped cleanly to "is the test wired
   into CI? do other example files exist that should be validated?"
   (F2, F6). But the per-BD lens loses the cross-concept signal that
   the methodology mostly exists to surface. Recommend: when applying
   the methodology to per-BD reviews, the reviewer briefly notes
   which of the 6 dimensions are "narrow" for this scope and which
   are "load-bearing" — done implicitly here, but not codified.

2. **`ARCH` severity guidance assumes a multi-concept fix surface.**
   BD-078 is a self-contained validator-Check addition; nothing in
   the finding set rises to ARCH because the contract is self-
   evident (BACKLOG entry + V1 §A.2). The methodology's `ARCH`
   triggers (CONTRACT touch-point change, ≥2-concept procedure
   reordering, finding-spawning-finding) don't fire on per-BD
   reviewer scope by construction. This is correct, not friction —
   noting it for the next reviewer who might wonder if they missed
   something.

3. **The "no prior reviews" rule (per `MEMORY.md`
   `feedback_no_prior_reviews_to_reviewer.md`) interacts oddly with
   the implicit "sibling BD context."** BD-078 + BD-079 + BD-112
   shipped in one commit with one combined implementation report.
   Reviewing BD-078 in isolation requires reading the combined
   report and mentally filtering to the BD-078 section. This worked
   for BD-078 (the report has clean per-BD sections). It might not
   for future combined reports. Recommend: implementation reports
   for multi-BD batches should make per-BD section boundaries grep-
   able (the BD-078-079 report does this well — `## BD-078 — …`
   and `## BD-079 — …` headers; cite as the reference template).

4. **The CI-wiring race pattern (F2) was already empirically
   established in CONCEPTUAL-REVIEW-METHODOLOGY.md** as a pack-
   recurring failure mode (Batch 17 BD-108 F1). A pre-flight
   reviewer checklist item — "if the BD added a new `scripts/tests/*-test.sh`
   file, grep `.github/workflows/validate-pack.yml` for it; if
   absent, surface as MUST" — would catch this pattern at every
   future per-BD review with zero reasoning required. Recommend:
   add this exact check to the conceptual-review methodology as a
   named heuristic.

---

## Summary table

| # | Sev | Dim | Class | One-line |
|---|---|---|---|---|
| F1 | MUST  | (a) | OWNED      | Acceptance criterion B (mirror staleness warning) never implemented |
| F2 | MUST  | (c) | SHARED-RW  | `tracker-config-schema-test.sh` not wired into CI |
| F3 | SHOULD| (b) | OWNED      | `schema_version = true` silently passes (bool-is-int Python quirk) |
| F4 | SHOULD| (e) | SHARED-RO  | Validator subset of V1 §3.1 schema; `backend.repo` (load-bearing for `gh`) not gated |
| F5 | SHOULD| (d) | OWNED      | Bare `ARCHITECTURE.md §3.1` reference is ambiguous in a repo with V1/V2/V3 docs |
| F6 | NIT   | (c) | SHARED-RO  | `test-fixtures/v11-*/tracker.toml.example` not validated; document or include |
| F7 | NIT   | (e) | OWNED      | Unused `VALIDATOR=…` assignment in `tracker-config-schema-test.sh` line 28 |
| F8 | NIT   | (e) | OWNED      | `_ = (fwd, rev)` lint-silencer can be replaced by bare calls |
| F9 | NIT   | (c) | SHARED-RO  | BACKLOG `Resolved:` link points to `v11-implementation/` but report is at `archive/v11/` |

**Counts:** 0 BLOCKER, 2 MUST, 3 SHOULD, 4 NIT, 0 ARCH.

---

## Closing note

The shipped Check 29 is operationally clean — it does what it does
correctly, and the fixture suite proves the schema-validation leg
works against the assertions it was designed for. The findings above
are about (a) the half of the BACKLOG acceptance criteria that was
silently dropped, (b) the CI wiring that means even the half that
shipped is not a real gate, and (c) the smaller correctness /
ergonomic surfaces. None of the findings invalidate the Resolved
status, but F1 and F2 are spec / contract gaps that the original
end-of-batch review cycle missed, which is exactly the gap Batch 21c
exists to surface.
