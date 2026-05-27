# PLAN-BD-194.md — Check 24 byte-identity gate replacement (single-commit implementation plan)

Status: PLANNER DELIVERABLE — single-commit implementation plan pending user review.
HEAD SHA at planner pass: `8570243` (`85702434bd8771fc964c89565491bb75e2ceec01`).
Author: pack-planner; produced 2026-05-27 per BD-194 pipeline.
Read-only against working tree at planner pass; no source modified.

Mechanical companion to `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md`
(architect deliverable, user-approved Candidate 6).

---

## §1 Scope

BD-194 — Check 24 byte-identity gate replacement (post-BD-193 architectural baseline fix).

This plan is the mechanical bridge between the architect's user-locked
Candidate 6 design (delete Check 24 + modify Check 23 to fail-loud +
correct Check 22 per-surface tracker fragment + update 6 audit-trail
allowlist comments) and the pack-coder implementation pass.

Anchors:
- Architect deliverable: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179 lines)
- BD entry: `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open; Position Batch 19d-prep-3)
- HEAD SHA: `8570243` (`85702434bd8771fc964c89565491bb75e2ceec01`)
- Pipeline position: fires AFTER BD-193 Resolved + BEFORE BD-185 H.2

---

## §2 User-locked inputs (recap; do not re-litigate)

### §2.1 Candidate 6 — approved design (architect §4 + §5)

1. **Delete Check 24 entirely.**
   - Remove `def check_help_fragment_tracker_byte_identity()` (current
     `scripts/validate-pack.py:2154-2175`).
   - Remove its callsite (current `scripts/validate-pack.py:6067`).
   - Replace the check-list comment entry at L62-64 with a retirement
     note (architect §5.4 step 3).

2. **Modify Check 23 (`check_help_fragment_completeness`) to fail-loud.**
   - Current behavior (L1968-1976): silently `if tracker_fragment.is_file():`
     concatenates only when present.
   - New behavior (architect §5.1): pack-side tracker fragment
     `pack-ops/HELP-FRAGMENT-TRACKER.md` is REQUIRED — if missing,
     `fail()` and return early.

3. **Fix Check 22 (`check_help_fragment_freshness`) — per-surface
   tracker fragment selection (no cross-surface concatenation).**
   - Current bug (L1903, L1913-1914): single `tracker_fragment` constant
     `pack-ops/HELP-FRAGMENT-TRACKER.md` is concatenated to BOTH surfaces'
     fragments before verb comparison. Post-BD-193 this is wrong for
     the project-template surface.
   - Fix (architect §5.1): add per-surface `tracker_fragment` path to
     the `surfaces` dict; each surface uses its own tracker fragment
     (pack-root → `pack-ops/HELP-FRAGMENT-TRACKER.md`; project-template
     → `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`).
   - Fail-loud if the per-surface tracker fragment is missing.

4. **Update 6 allowlist / audit-trail comments** (architect §5.2 + §8.5):
   - `scripts/validate-pack.py` L62-64 (check-list comment for Check 24).
   - `scripts/validate-pack.py` L4762-4770 (`_BARE_REFERENCE_EXEMPTIONS`
     for `HELP-FRAGMENT.md`).
   - `scripts/validate-pack.py` L5126 (`_CHECK_43_ALLOWLIST` for
     `HELP-FRAGMENT-TRACKER.md`).
   - Three additional internal-prose touches found by planner audit
     (see §3.4 below — Check 37 anchor-phrase comment at L4051, and two
     places inside the Check 24 function itself which disappear with the
     function deletion).

5. **README version-table prose update (PM-only).**
   - L60 row prose ("validate-pack.py expanded to 41 invoked checks").
   - L107 Repository Layout note for `HELP-FRAGMENT-TRACKER.md`
     ("byte-identical to pack root, DELTA L1").
   - L195 Repository Layout note for `validate-pack.py` ("41 invoked
     checks").
   - L272 Repository Layout note (HELP-FRAGMENT-TRACKER pack-root entry
     "mirrored to project-template/docs/pack/").

### §2.2 POQ-1 — Check 22 fix INCLUDED in BD-194 scope (architect §7.1)

User decision: include the per-surface Check 22 correction in BD-194.
Rationale: `feedback_deferral_is_scope_creep` LOGICAL-FIT (same file,
same subject, same architectural correction class).

### §2.3 POQ-2 — README edit lands in SAME commit as coder commit (architect §7.2)

User decision: single-commit shape. Pack Chat owns the `README.md` edit
(PM-only). Coder owns `scripts/validate-pack.py`. Both land in one
commit per POQ-2.

### §2.4 POQ-3 — Allowlist comment-text precision deferred to coder-pass review (architect §7.3)

User decision: not blocking; coder may use the architect's draft text
or refine; reviewer audits in the standard post-coder review pass.


---

## §3 Pre-implementation investigation (verify against HEAD `8570243`)

### §3.1 Architect line-number references — verified

| Architect-doc citation | Status at HEAD `8570243` | Notes |
|---|---|---|
| Check 24 function `scripts/validate-pack.py:2154-2175` | VERIFIED | Function spans exactly 2154-2175; matches architect §2.4 verbatim. |
| Check 24 callsite L6067 | VERIFIED | `check_help_fragment_tracker_byte_identity()` at exactly L6067. |
| Check 24 check-list comment L62-64 | VERIFIED | Lines 62-64 carry the "24. HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1)" prose. |
| Check 22 function L1871-1958 | VERIFIED | Function definition at L1871; `tracker_fragment` constant at L1903; concatenation at L1913-1914. |
| Check 23 function L1961-2006 | VERIFIED | `tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"` at L1970; concatenation at L1975-1976. |
| L4762-4770 `_BARE_REFERENCE_EXEMPTIONS` comment block | VERIFIED | `HELP-FRAGMENT.md` entry at L4770 with literal text "Byte-identical mirror exception (Check 24); ...". |
| L5126 `_CHECK_43_ALLOWLIST` entry | VERIFIED | `HELP-FRAGMENT-TRACKER.md` entry text "...byte-identical mirror per Check 24". |
| L5217 `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` | VERIFIED | Tuple = `("pack-ops/HELP-FRAGMENT-TRACKER.md",)`. NO edit needed — value is correct under separation rule. |
| L4051 Check 37 anchor-phrase comment | PARTIAL — see §3.4 | Comment mentions "HELP-FRAGMENT-TRACKER.md:49" inside the `_DENY_LIST_ANCHOR_PHRASES` context. Survives content divergence today; architect §5.2 flags as "future reviewer awareness only, no immediate edit needed". |

### §3.2 README prose — verified

| README citation | Status at HEAD `8570243` |
|---|---|
| L60 version-table v11.0 row: "validate-pack.py expanded to 41 invoked checks (39 numbered Check 1–11 and 16–43; ..." | VERIFIED. The "41 invoked checks" count IS the post-BD-194 EDIT target. The prose enumerates "Check 1–11 and 16–43" and lists `Checks 12–15 retired per v9 sunset`. Post-BD-194: enumeration becomes "Check 1–11, 16–23, 25–43"; retirement clause gains "; Check 24 retired per BD-194". |
| L107 Repository Layout note for client-installed `HELP-FRAGMENT-TRACKER.md`: "Shared tracker section (v11; byte-identical to pack root, DELTA L1)" | VERIFIED. Post-BD-194 the "byte-identical to pack root, DELTA L1" phrase is FACTUALLY INCORRECT under the separation contract. EDIT REQUIRED. |
| L195 Repository Layout note for `validate-pack.py`: "CI structural validation (41 invoked checks — ... Checks 12–15 retired per v9 sunset; pack-internal)" | VERIFIED. Same edit as L60 — adjust count + retirement clause. |
| L272 Repository Layout note for pack-side `HELP-FRAGMENT-TRACKER.md`: "Shared tracker section (v11; canonical; mirrored to project-template/docs/pack/)" | VERIFIED. The phrase "mirrored to project-template/docs/pack/" is now INCORRECT under separation. EDIT REQUIRED. |

### §3.3 Existing tests for Check 22 / Check 23 / Check 24 — verified

Per architect §2.5: no per-check test files exist for Check 22, 23, or
24. Confirmed by planner `ls scripts/tests/`:

- `test-validate-pack-check-16.sh`
- `test-validate-pack-check-18.sh`
- `test-validate-pack-check-19.sh`
- `test-validate-pack-check-39.sh`
- `test-validate-pack-check-40.sh`
- `test-validate-pack-check-41.sh`
- `test-validate-pack-check-42.sh`
- `test-validate-pack-check-43.sh`
- `test-validate-pack-checks-32-33-34.sh`
- `test-validate-pack-checks-36-37-38.sh`

No `test-validate-pack-check-22.sh` / `-23.sh` / `-24.sh` exist. Per
architect §5.3 NO new per-check test file lands in BD-194. The CI
self-test (`python3 scripts/validate-pack.py`) IS the regression gate.

Per architect §5.3 + `feedback_deferral_is_scope_creep` LOGICAL-FIT
bar: adding per-check tests for Checks 22/23 is OUT OF SCOPE (test-
infra surface; gap predates BD-194). If a future divergence work needs
per-check tests, that's its own BD.

CI workflow check: `.github/workflows/validate-pack.yml` has NO step
named for Check 24 (confirmed by `grep -n "check_help_fragment_tracker_byte_identity\|test-validate-pack-check-24" .github/workflows/validate-pack.yml` returning empty). Check 42 (`check_ci_workflow_wires_per_check_tests`) discovers per-check test files from disk; absence of `test-validate-pack-check-24.sh` is correctly the post-BD-194 state.

### §3.4 Planner-discovered references — beyond the architect-doc scope

Pre-commit grep audit found four reference classes the architect doc
either did not enumerate or noted only as "future-aware". Each is
classified Required / Optional / Out-of-scope for this commit.

#### §3.4.1 Pack-root trinity references (PLANNER-LEVEL POQ — see §8 POQ-1)

`grep -n "CI Check 24\|byte-identity" CLAUDE.md AGENTS.md GEMINI.md` at
the pack root surfaces three references in the
`## Pack memory → Repo conventions → Filename uniqueness heuristic`
section:

- `CLAUDE.md:505` — "Structurally required collisions are exempt
  (trinity files, per-skill `SKILL.md`, byte-identical mirrors per
  CI Check 24, ecosystem-fixed names like `.gitignore` / ..."
- `AGENTS.md:466` — same text (trinity parity).
- `GEMINI.md:436` — same text (trinity parity).

Status post-BD-194: the citation "byte-identical mirrors per CI Check 24"
becomes STALE (Check 24 retired). However — these files are PM-only per
`pack-ops/PACK-AGENTS.md:149` ("CLAUDE.md / AGENTS.md / GEMINI.md (root
and `project-template/`)"). The user-prompt-scope for BD-194 lists
in-scope edits as `scripts/validate-pack.py`, `README.md`,
`scripts/tests/` files, and `test-fixtures/manifest.txt` — pack-root
trinity is NOT in scope.

This raises POQ-1 (see §8): Should the pack-root trinity references be
updated in the same commit (extending scope to add three PM-only trinity
edits) or deferred to a follow-on commit?

#### §3.4.2 Architect comment in Check 22 `surfaces` dict (REQUIRED but minimal)

The current Check 22 dict (`scripts/validate-pack.py:1884-1902`)
contains no comment explaining why a single shared `tracker_fragment`
is used. Post-BD-194 the dict gains a per-surface `tracker_fragment`
key. The added entries should carry a one-line BD-194 reconciliation
comment naming the architect doc — per CLAUDE.md "Architect-doc-vs-
reality reconciliation" rule:

> When a BD realizes a design anticipated in an architect doc, ship
> the reconciliation chain: (a) in-code docstring naming the realized
> consumer (file + symbol; never line numbers — line numbers drift),
> (b) architect-doc addendum cross-referencing the realized consumer,
> (c) IMPL-REPORT cross-reference linking both.

The architect doc per §5.1 supplies an inline implementation sketch
including a comment ("Per BD-194: each surface authors its own
HELP-FRAGMENT-TRACKER.md. Per-surface fragment lookup per the surface
dictionary; no cross-surface concatenation."). Coder includes this in
the working tree. REQUIRED.

#### §3.4.3 Check 22 + Check 23 docstring updates (REQUIRED but minimal)

The Check 22 and Check 23 docstrings (architect §5.1) refer
specifically to `BD-082` (the original BD that created the check).
Post-BD-194 the per-surface-fragment behavior change for Check 22 and
the fail-loud behavior change for Check 23 should be reflected in
their docstrings with a one-line BD-194 attribution. REQUIRED for
audit-trail consistency per CLAUDE.md "Architect-doc-vs-reality
reconciliation".

Suggested format (coder may refine per architect §7.3 / POQ-3
non-blocking nature):

Check 22 docstring trailing addendum:
> Per BD-194: per-surface tracker fragment lookup (no cross-surface
> concatenation). Each surface's verbs are compared against the
> surface's own HELP-FRAGMENT-TRACKER.md.

Check 23 docstring trailing addendum:
> Per BD-194: pack-side tracker fragment is REQUIRED — fail-loud if
> missing (no silent fallback).

#### §3.4.4 Check 24 function deletion — no rename required

When the function `check_help_fragment_tracker_byte_identity` is
deleted (architect §5.1), all internal references within the function
disappear by definition. No additional in-function audit needed.

#### §3.4.5 Maintenance-docs/archive/v11 historical references — NO EDIT

`grep -rn "Check 24" maintenance-docs/archive/v11/` returns multiple
hits across archived ARCHITECTURE-*, PLAN-*, PACK-REVIEW-*, and
IMPLEMENTATION-REPORT-* docs. These are HISTORICAL ARTIFACTS captured
in Pattern B archive sweeps per CLAUDE.md "Skill and agent maintenance
is mechanical by default" rule. They are NOT EDITED post-event — they
record what each batch shipped at the time. NO EDIT to archive/.

### §3.5 Manifest regen — TRIGGER FIRES per CLAUDE.md RC9

Trigger evaluation per CLAUDE.md "Regenerate test-fixtures/manifest.txt
on every v11-surface commit":

- Files modified in this commit include `scripts/validate-pack.py` →
  `scripts/` directory → v11-surface trigger fires.
- README.md is NOT in the v11-surface list (per the CLAUDE.md rule:
  `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`)
  but README.md is at PACK ROOT — also not in the trigger list. The
  trigger fires regardless via the `scripts/validate-pack.py` change.

Coder runs `bash test-fixtures/build.sh --all --clean` before staging.
Then checks `git diff test-fixtures/manifest.txt`. If non-empty,
stages `test-fixtures/manifest.txt` in the same commit per RC9.

Note on expected outcome: `scripts/validate-pack.py` is mass-copied by
`scripts/init-project.sh` stages S1-S11 (per CLAUDE.md). v11-* fixture
row SHAs drift naturally with this change. Manifest update is expected;
v10-* row SHAs should NOT drift (tag-pinned).


---

## §4 Commit shape

### §4.1 Single-commit file list

Per POQ-2 (user-locked): one commit, mixed-scope (touches both
PM-only and pack-coder files).

| # | File | Owner | Edits |
|---|---|---|---|
| 1 | `scripts/validate-pack.py` | pack-coder | Modify Check 22 (per-surface tracker fragment + docstring addendum); modify Check 23 (fail-loud + docstring addendum); delete Check 24 function + callsite; update check-list comment L62-64; update L4762-4770 `_BARE_REFERENCE_EXEMPTIONS` rationale text; update L5126 `_CHECK_43_ALLOWLIST` rationale text. Total ~6 edit-sites. |
| 2 | `README.md` | Pack Chat (PM-only) | L60 v11.0 row prose ("41 invoked checks" → "40 invoked checks" + new Check 24 retirement clause); L107 client-installed `HELP-FRAGMENT-TRACKER.md` note ("byte-identical to pack root" → per-surface); L195 `validate-pack.py` note ("41 invoked checks" → "40"); L272 pack-side `HELP-FRAGMENT-TRACKER.md` note ("mirrored to project-template/docs/pack/" → per-surface). |
| 3 | `test-fixtures/manifest.txt` | pack-coder (regen) | Regenerated by `bash test-fixtures/build.sh --all --clean` after edit #1 lands in the working tree; v11-* fixture row SHAs drift. Per CLAUDE.md RC9. |

### §4.2 Edit sequencing within the commit

There are NO inter-edit dependencies within `scripts/validate-pack.py`
that require strict ordering — each edit is independent.

Recommended order for coder ergonomics:

1. **Check 24 retirement** (atomic removal). Delete function L2154-2175;
   delete callsite L6067; replace check-list comment L62-64. After this
   step, `python3 scripts/validate-pack.py` runs with 40 invoked checks.
2. **Check 23 fail-loud modification.** Replace L1975-1976 silent
   fallback with fail-loud branch; add BD-194 docstring addendum.
3. **Check 22 per-surface fragment fix.** Add `tracker_fragment` key to
   each surface in the `surfaces` dict (L1884-1902); replace L1903 +
   L1913-1914 single-source concatenation with per-surface concatenation
   + missing-fragment fail-loud; add BD-194 docstring addendum.
4. **Allowlist rationale comment updates.**
   a. `_BARE_REFERENCE_EXEMPTIONS` L4762-4770 — update the multi-line
      comment block at L4762-4769 AND the rationale string at L4770.
   b. `_CHECK_43_ALLOWLIST` L5126 — update the rationale string at L5126.
5. **PREFLIGHT.** Run `python3 scripts/validate-pack.py` — must PASS at
   40 invoked checks. See §5 verification gates.
6. **Manifest regeneration.** Run `bash test-fixtures/build.sh
   --all --clean` against the working tree; stage
   `test-fixtures/manifest.txt` if diff is non-empty.
7. **README PM-only edits.** Pack Chat applies the 4 README edits per
   §4.1 row 2 + §3.2.

Pack Chat stages all three files (pack-coder edits #1 + #3, plus
README edit #2) and creates a single commit with the message per §4.3.

### §4.3 Commit subject + body draft

Subject (mixed-scope; no scope keyword per CLAUDE.md "Commit-subject
scope-keyword convention" — touches both pack-coder PM-only-distinct
surfaces and PM-only `README.md`):

```
fix: v11 — BD-194 Check 24 byte-identity gate retired; Check 22 + Check 23 per-surface fragment fix
```

The `fix:` form is correct per CLAUDE.md "Approved suffixes for the
`fix:` form" — this is a per-BD inline fix in the current batch
(Batch 19d-prep-3).

No scope keyword (`pack-only` / `project-only` / `PM-only`) attaches
— this commit touches `scripts/` (pack-coder) AND `README.md`
(PM-only). Per CLAUDE.md "Batch-scope claims are enforced by CI, not
honor system": when a batch spans both, use neutral framing.

Body draft (for the actual commit message; coder + Pack Chat refine
at commit time):

```
Per maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md
(user-approved Candidate 6, 2026-05-27):

- Retire Check 24 (check_help_fragment_tracker_byte_identity)
  cross-surface byte-identity gate. Per pack memory
  feedback_pack_project_separation_of_concerns (user-locked
  2026-05-26), pack-ops/HELP-FRAGMENT-TRACKER.md and
  project-template/docs/pack/HELP-FRAGMENT-TRACKER.md are SEPARATE
  artifacts with SEPARATE audiences; the byte-identity invariant
  contradicts this rule and would fail on first intentional
  divergence.

- Modify Check 23 (check_help_fragment_completeness) to fail-loud
  if pack-side pack-ops/HELP-FRAGMENT-TRACKER.md is missing
  (was: silent fallback). Pack-side existence is asserted by
  Check 23; project-side existence is asserted by Check 41
  (_CLIENT_INSTALLED_FILES self-doc list integrity).

- Fix Check 22 (check_help_fragment_freshness) latent bug surfaced
  by §2.6.1 of the architect doc: each surface now uses its OWN
  tracker fragment instead of the single pack-side fragment
  concatenated to both surfaces. project-template surface verbs
  resolve from project-template-side HELP-FRAGMENT-TRACKER.md.

- Update 2 audit-trail allowlist rationale comments removing
  "byte-identical mirror per Check 24" language: scripts/validate-
  pack.py _BARE_REFERENCE_EXEMPTIONS entry for HELP-FRAGMENT.md
  (L4762-4770) and _CHECK_43_ALLOWLIST entry for HELP-FRAGMENT-
  TRACKER.md (L5126).

- README version-table prose: validate-pack invoked-check count
  41 → 40; Check 24 added to the retirement clause beside Checks
  12-15.

- README Repository Layout notes: HELP-FRAGMENT-TRACKER pack-root
  + client-installed entries no longer claim cross-surface
  byte-identity.

- Manifest regenerated per CLAUDE.md RC9 (v11-surface touched).

Closes: BD-194 (Position Batch 19d-prep-3; unblocks BD-185 H.2).
```

### §4.4 What this commit does NOT touch (deferral integrity)

Per the user-prompt-scope and `feedback_deferral_is_scope_creep`:

- Pack-root trinity references to "CI Check 24" (CLAUDE.md L505,
  AGENTS.md L466, GEMINI.md L436). See POQ-1 in §8.
- Pack-ops trinity (no `Check 24` hits found per planner audit).
- `.github/workflows/validate-pack.yml` (no `Check 24` step name).
- `pack-ops/HELP-FRAGMENT-TRACKER.md` content (unchanged).
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` content
  (unchanged).
- `pack-ops/BACKLOG.md` (BD-194 already open at HEAD; status flip to
  Resolved is the end-of-batch action per `feedback_implicit_status_flip`,
  not this commit).
- `scripts/tests/` directory (no per-check test file added per
  architect §5.3).
- `maintenance-docs/archive/v11/` (historical artifacts; never edited
  per CLAUDE.md Pattern B).


---

## §5 Pre-commit verification gates

All gates run AFTER edits #1 + #3 land in the working tree but BEFORE
Pack Chat stages anything. The README edit (#2) is mechanical and
verified by reviewer pass post-commit.

### §5.1 Gate G1 — `python3 scripts/validate-pack.py` PASS at 40 invoked checks

Command: `python3 scripts/validate-pack.py`

Expected outcome:
- Output enumerates 40 invoked checks (was 41 pre-BD-194).
- `Check 24:` line MUST NOT appear in the output.
- Check 22 and Check 23 PASS at HEAD post-edit (both files exist
  pack-side and project-side; fail-loud branches not taken).
- All other checks PASS (no regression).

Failure semantics: any FAIL on Check 22, 23, or 41 means an edit
introduced a regression; coder MUST diagnose and fix before continuing.

### §5.2 Gate G2 — Check 24 identifier purge

Per architect §5.4, the function name and check-list comment text
must be absent from `scripts/validate-pack.py` post-edit (except in
the architect-doc cross-reference if one is added, which would be a
comment-only allusion not a code dependency).

Audit commands:
```
grep -n "check_help_fragment_tracker_byte_identity" scripts/validate-pack.py
grep -n "Check 24" scripts/validate-pack.py
grep -n "byte-identity" scripts/validate-pack.py
```

Expected outcomes:
- `check_help_fragment_tracker_byte_identity`: ZERO matches.
- `Check 24`: ZERO matches as a check function name or print
  statement. The check-list comment at L62-64 may carry a single
  retirement note line referencing "Check 24" — that is INTENTIONAL
  audit-trail prose and is acceptable.
- `byte-identity`: MAY appear in unrelated checks (Check 32 mirror-
  in-sync uses the phrase at L3252; Check 33 TOC-in-sync at L3383;
  Check 22 has a "no-op if the on-disk mirror is byte-identical" prose
  comment at L3103 unrelated to Check 24). The audit verifies
  Check 24-specific phrasing is gone (L2155, L2159, L2162, L2172,
  L2175 retired with the function).

### §5.3 Gate G3 — Allowlist rationale text purge

Per architect §5.2 the 2 allowlist comments must no longer reference
"byte-identical mirror per Check 24" or "Byte-identical mirror
exception (Check 24)".

Audit commands:
```
grep -n "Check 24\|byte-identical mirror" scripts/validate-pack.py
```

Expected outcome: the only `Check 24` reference allowed is the
optional retirement-note line at L62-64 (architect §5.4 step 3).
The phrases "byte-identical mirror per Check 24" (L5126 was) and
"Byte-identical mirror exception (Check 24)" (L4770 was) MUST be
absent post-edit.

### §5.4 Gate G4 — Test-fixtures manifest regeneration per CLAUDE.md RC9

Per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every
v11-surface commit":

Procedure:
1. `bash test-fixtures/build.sh --all --clean` (from pack root).
2. `git diff test-fixtures/manifest.txt` — if non-empty, stage
   alongside the scope edits in the same commit.

Expected outcome: v11-* fixture row SHAs in `test-fixtures/manifest.txt`
will drift (likely 3 rows: `v11-flat-file`, `v11-realistic-ot`,
`v11-tracker-on`, `v11-trinity-marker-prepped`) since `scripts/`
is mass-copied at install. v10-* SHAs MUST NOT drift (tag-pinned per
`test-fixtures/README.md` § Determinism).

Failure mode: if v10-* SHAs drift, coder reports the drift instead of
proceeding — that indicates an unintended cross-fixture leak that
needs investigation, not a clean v11-surface manifest regen.

### §5.5 Gate G5 — PREFLIGHT line per pack-coder spawn protocol

Per pack memory `feedback_pack_coder_preflight_pattern` + CLAUDE.md
"Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern":

After ALL coder edits + verification G1-G4 PASS, the coder emits ONE
plain-text PREFLIGHT line per the trinity contract:

```
PREFLIGHT: N/N in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>
```

Then Writes `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md`.

If G1-G4 fail in any way, the coder reports the failure (with file:line
+ matched basename + suggested remediation) INSTEAD OF writing the
IMPL-REPORT. Pack Chat reviews and decides whether to fix in this
commit or escalate.

### §5.6 Gate G6 — Local divergence smoke test (architect §5.5 step 2; NON-COMMITTED)

Optional sanity check the coder MAY run before PREFLIGHT to confirm
the architectural correction works end-to-end:

1. Add a temporary line to `pack-ops/HELP-FRAGMENT-TRACKER.md` (e.g., a
   single `<!-- BD-194 smoke -->` comment) so the file diverges from
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`.
2. Run `python3 scripts/validate-pack.py` — MUST PASS (this is the
   architectural correction; pre-BD-194 Check 24 would have FAILed here).
3. Revert the temporary line: `git checkout -- pack-ops/HELP-FRAGMENT-TRACKER.md`.

Per CLAUDE.md "No destructive operations without explicit approval":
the coder asks Pack Chat before running `git checkout --` on a file
that did not originally have coder-written changes; pure revert of a
non-staged smoke-test addition is operator-judgment but planner flags
it for caution.


---

## §6 Post-commit verification

### §6.1 CI workflow expectations

The `Validate Pack` GitHub Actions workflow runs on every push.
Expected behaviors post-commit:

- **Step `validate` (`python3 scripts/validate-pack.py`)** — PASS at
  40 invoked checks. The job output enumerates "Check 1–11, 16–23,
  25–43" (38 numbered post-BD-194) plus 2 unnumbered informational
  checks (`issue-template-forms`, `template-archive-v11`) = 40 total.
- **Step `fixture manifest verify` (BD-115; RELEASE-GATE item 5)** —
  PASS. The `test-fixtures/manifest.txt` was regenerated in this
  commit per RC9; the CI comparison step verifies the manifest
  matches a fresh rebuild.
- **Per-check tests** — no `test-validate-pack-check-24.sh` to wire
  (architect §5.3); Check 42 (`check_ci_workflow_wires_per_check_tests`)
  PASSes because it discovers per-check test files from disk and
  absence is correctly absent.

### §6.2 pack-reviewer scope (post-coder; per-BD review pass)

Per CLAUDE.md "Per-BD review/fix runs INLINE, before next BD's coder
spawns" + `feedback_review_fix_one_cycle`:

After coder writes IMPL-REPORT-BD-194, Pack Chat spawns `pack-reviewer`
(in background per `feedback_spawn_agents_in_background`) with the
following review scope:

**REQUIRED review surfaces:**
- `scripts/validate-pack.py` Check 22 + Check 23 modifications +
  Check 24 deletion + comment updates.
- `README.md` 4 prose edits.
- `test-fixtures/manifest.txt` regeneration (sanity-check: v10-* rows
  unchanged; v11-* rows reflect the `scripts/` mass-copy effect).
- BD-194 architectural-correction rationale matches architect doc §4
  (Candidate 6) — i.e., the commit is faithful to the user-locked
  design.

**REQUIRED review checks per pack-reviewer skill contract:**
- SIZE / BLOCKED / LOGICAL-FIT bar on any "carry-forward" framing
  (per `feedback_review_carry_forward_discipline`).
- Default-fix-all triage per `feedback_fix_all_review_findings`;
  nits become tracked tech debt per `feedback_deferred_work_tracking`.
- Boundary discipline (P-missed-7) — verify no pack-side rule leaked
  into project-side surfaces, no project-side authority eroded.

**Out of scope for the reviewer pass:**
- Pack-root trinity references at CLAUDE.md L505 / AGENTS.md L466 /
  GEMINI.md L436 — see POQ-1 in §8. If POQ-1 resolves to "defer to
  follow-on commit", the reviewer notes those references as KNOWN
  CARRY-FORWARD for the follow-on PM-only commit; if POQ-1 resolves
  to "include in this commit", scope expands to include the three
  trinity edits as PM-only co-edits in the same commit.

### §6.3 Implicit BD-194 status flip on batch completion

Per `feedback_implicit_status_flip` + CLAUDE.md "Implicit BD status flip
on batch completion":

After reviewer pass + any fix-coder pass complete and CI is green,
Pack Chat flips BD-194 from `Open` to `Resolved` in
`pack-ops/BACKLOG.md`:3076-3124 as the final action of the batch
(end-of-batch PM-only commit, separate from the BD-194 coder commit).

The `Resolved:` line on L3124 (currently `n/a`) gets the resolution
date + a one-paragraph summary referencing the commit SHA + the
architect-doc anchor.

This status-flip commit may be combined with the BD-185 H.2 spawn-
prep edits in the next session, or land as a standalone PM-only
commit — Pack Chat decides per ergonomics.

---

## §7 Coder-pass scope (what the coder edits vs Pack Chat PM-only edits)

### §7.1 pack-coder agent scope (in-scope file edits)

- `scripts/validate-pack.py` — full edit authority for §4.2 steps 1-4
  per architect §5.1 + §5.4.
- `test-fixtures/manifest.txt` — regen via `bash test-fixtures/build.sh
  --all --clean` per §5.4 G4.

The coder MAY also surface (in the IMPL-REPORT, NOT edit) any
incidental stale references discovered during the edit (e.g., if the
coder finds a comment elsewhere in `scripts/validate-pack.py` that
became stale post-Check-24-retirement, surface it for Pack Chat triage
instead of editing it). The coder MUST stay within the file scope per
the spawn prompt.

### §7.2 Pack Chat PM-only edits (same commit per POQ-2)

- `README.md` — 4 prose edits per §4.1 row 2 + §3.2.

Pack Chat applies these edits directly using Write / Edit tools per
CLAUDE.md "What Pack Chat CAN edit directly" → PM-only files list
(README.md version table is explicitly in the list at
`pack-ops/PACK-AGENTS.md:146`).

### §7.3 STOP-MEANS-STOP preamble (coder prompt)

Per CLAUDE.md "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern", the
coder spawn prompt MUST include:

> If you receive a parent-session message containing the words
> stop / halt / revert / do not continue, you MUST immediately stop
> ALL work, including any in-progress Write. Partial files are
> acceptable; do not append to make consistent. Stop authority is
> absolute and unconditional.

### §7.4 Output of the coder pass

- Working-tree edits: `scripts/validate-pack.py` +
  `test-fixtures/manifest.txt`.
- PREFLIGHT line (plain text, written before IMPL-REPORT write) per
  §5.5.
- IMPL-REPORT file: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md`.

The IMPL-REPORT MUST cross-reference both `ARCHITECTURE-BD-194.md`
(the design) and this `PLAN-BD-194.md` (the mechanical bridge) per
CLAUDE.md "Architect-doc-vs-reality reconciliation".

### §7.5 Out-of-scope for the coder pass

- README.md (Pack Chat owns).
- Pack-root trinity (PM-only; POQ-1).
- `pack-ops/BACKLOG.md` BD-194 status flip (Pack Chat owns at end of
  batch per `feedback_implicit_status_flip`).
- `.github/workflows/validate-pack.yml` (no Check 24 step name; nothing
  to remove).
- `pack-ops/HELP-FRAGMENT-TRACKER.md` content (unchanged).
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` content
  (unchanged).
- `scripts/tests/test-validate-pack-check-24.sh` (does not exist; per
  architect §5.3 NO new per-check test file lands).


---

## §8 POQs requiring user resolution

### §8.1 POQ-1 — Pack-root trinity references to "CI Check 24" (NEW; planner-discovered)

**Question.** Per §3.4.1, three pack-root trinity files (CLAUDE.md
L505, AGENTS.md L466, GEMINI.md L436) cite "byte-identical mirrors
per CI Check 24" as an example of the structurally-required-collision
exemption class in the
`## Pack memory → Repo conventions → Filename uniqueness heuristic`
section. Post-BD-194 this citation is FACTUALLY STALE (Check 24
retired).

Options:

- **Option A — Include in this commit.** Extend scope to add three
  PM-only trinity edits in the same commit as the coder pass. The
  three files are PM-only (per `pack-ops/PACK-AGENTS.md:149`) so Pack
  Chat applies them directly, same authority as the README edit.
  Maintains commit atomicity — all post-BD-194 reality reconciliation
  lands together. Adds 3 small trinity edits + the existing 4 README
  edits = 7 total PM-only edits in this commit. The trinity rule
  requires parallel edits across all three files anyway (per CLAUDE.md
  "Trinity rule"), so this is structurally a single conceptual edit
  applied 3x.
- **Option B — Defer to a follow-on PM-only commit.** Strict adherence
  to the user-prompt-scope ("Out-of-scope: any file NOT listed
  above"). Trinity references update in a separate commit, possibly
  bundled with the BD-194 status flip + BD-185 H.2 spawn-prep.
  Avoids scope-expansion mid-BD; trinity has its own audit cadence.
  Risk: the staleness window between BD-194 coder commit and follow-on
  trinity commit is brief but real — anyone reading the trinity in
  that window sees a citation to a check that no longer exists.

**Suggested replacement text** (architect-doc-style; coder/Pack Chat
refines at edit time):

> Current (CLAUDE.md L505, AGENTS.md L466, GEMINI.md L436):
> "...trinity files, per-skill `SKILL.md`, byte-identical mirrors per
> CI Check 24, ecosystem-fixed names like `.gitignore` /
> `pyproject.toml` / `Package.swift`..."
>
> Post-BD-194 (one suggested form):
> "...trinity files, per-skill `SKILL.md`, ecosystem-fixed names like
> `.gitignore` / `pyproject.toml` / `Package.swift`..."
>
> (Drops the byte-identical-mirrors clause entirely; HELP-FRAGMENT-
> TRACKER is no longer such a mirror under the BD-193/BD-194
> separation contract; no other byte-identical mirror exists in the
> pack at HEAD that would need the exemption-class anchor.)

Recommendation: **OPTION A** (include in this commit) — the trinity
rule means all three files are edited together anyway, and the
post-BD-194 reality reconciliation feels cleaner if all stale
"Check 24" prose lands in one commit.

**Risk if Option A chosen:** scope expansion mid-BD. Mitigation: the
edits are mechanical (single-clause removal x 3) with no architectural
content; reviewer pass scope expands to include trinity diff for parity
verification.

**Risk if Option B chosen:** brief staleness window; trinity audit
cadence is dictated by trinity-affecting BDs (CLAUDE.md trinity rule)
and not by self-referential check renumberings. Mitigation:
follow-on commit immediately after this BD's reviewer pass closes.

**User decision needed before coder spawn.**

### §8.2 POQ-2 — Whether to drop the byte-identical-mirrors example entirely or refer to a different example

**Question.** Per §8.1 POQ-1 Option A suggested replacement text, the
trinity citation to "byte-identical mirrors per CI Check 24" could
either be:

- **Sub-option a — Drop entirely.** No replacement example needed; the
  trinity-files / SKILL.md / ecosystem-fixed-names examples already
  carry the rule's intent.
- **Sub-option b — Replace with a different exemption-class example.**
  No other byte-identical-mirror class exists in the pack at HEAD
  that fits the example shape (the per-entry mirror SHAs at Check 32
  / Check 33 are mirror-in-sync gates, NOT byte-identical-mirror
  collisions in the filename-uniqueness sense). Sub-option (b) would
  require inventing a fictitious example or referring to none.

Recommendation: **SUB-OPTION A** (drop the clause). The remaining
3 example classes (trinity, SKILL.md, ecosystem-fixed-names) already
convey the rule's intent without the now-fictitious byte-identical
example.

POQ-2 is bundled with POQ-1 — if POQ-1 resolves to Option B (defer
trinity edits), POQ-2 deferred with it.

### §8.3 POQ-3 — Allowlist comment text precision (architect §7.3; non-blocking)

Architect §7.3 already noted that the exact replacement text for the
2 allowlist rationale comments (L4762-4770 + L5126) is non-blocking
and may be refined at the coder pass.

Planner agreement: this is correctly non-blocking. The architect's
draft text is fit-for-purpose; reviewer will flag any drift from the
underlying invariant. No additional user decision needed at planner
gate.


---

## §9 Risk callouts

### §9.1 RISK-1 — Check 22 modification touches the surfaces dict (medium)

The Check 22 fix per architect §5.1 adds a per-surface `tracker_fragment`
key to the `surfaces` dict at L1884-1902. This dict is read by the
`for surface, cfg in surfaces.items()` loop at L1906. Any typo or
missing key results in a `KeyError` at runtime.

Mitigation: Gate G1 (`python3 scripts/validate-pack.py`) executes the
full Check 22 path against both surfaces; any missing/misspelled key
fails at CI-runtime with a clear error.

### §9.2 RISK-2 — Check 23 fail-loud branch interacts with Check 41 self-doc integrity (low)

If a future content edit removes `pack-ops/HELP-FRAGMENT-TRACKER.md`
without also removing `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`
from `_CLIENT_INSTALLED_FILES`, Check 23 will FAIL (pack-side missing)
and Check 41 will independently flag the project-side entry as still
installed. This is the DESIRED behavior under separation — each surface
asserts its own integrity.

Mitigation: documented in architect §6.1 (divergence-mode matrix); no
code change needed beyond the fail-loud branch.

### §9.3 RISK-3 — Manifest drift across CI runs (low)

Per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface
commit": this commit touches `scripts/` and MUST regenerate the manifest.
Risk: if the coder forgets to run `bash test-fixtures/build.sh --all
--clean` after the validate-pack edit, the manifest stays stale and CI
fails on the `fixture manifest verify` step (BD-115, RELEASE-GATE
item 5).

Mitigation: Gate G4 (§5.4) is a hard pre-commit step in this plan.
Coder PREFLIGHT (§5.5) explicitly attests to G4 completion.

### §9.4 RISK-4 — Pack-root trinity staleness window (low; POQ-1-dependent)

If POQ-1 resolves to Option B (defer trinity edits), the pack-root
trinity (CLAUDE.md L505, AGENTS.md L466, GEMINI.md L436) carries a
factually stale "byte-identical mirrors per CI Check 24" citation
between BD-194's coder commit and the follow-on trinity commit.

Window: small (one Pack Chat batch step typically lasts under an
hour). Audience: pack-developers reading trinity files. Impact:
confusion / doc-trust erosion. Mitigation: surface in IMPL-REPORT as
KNOWN CARRY-FORWARD; follow-on commit lands as a discrete PM-only
step before the next BD spawns.

If POQ-1 resolves to Option A (include in this commit), risk is
ZERO.

### §9.5 RISK-5 — Reviewer pass may flag the Check 22 per-surface fix as scope creep (low)

`feedback_review_carry_forward_discipline` and `feedback_deferral_is_scope_creep`
together carry a HIGH BAR on adding NEW work mid-BD. The architect doc
§4.3 + POQ-1 (user-locked) already established Check 22 fix as
LOGICAL-FIT in-scope. Reviewer pass should affirm this, but a
defensive note in the IMPL-REPORT cross-referencing architect §4.3 +
the BD-194 entry §Description guards against a reviewer mis-classifying
the Check 22 fix as scope creep.

Mitigation: coder includes the architect §4.3 cross-reference in the
IMPL-REPORT preface.

### §9.6 RISK-6 — README "41 invoked checks" count drift across CI versions (very low)

The README L60 and L195 prose enumerate the invoked-check COUNT
explicitly ("41 invoked checks" → "40 invoked checks" post-BD-194).
Any future check addition / retirement requires hand-update of this
prose. No CI gate currently auto-verifies the count claim against
actual validate-pack execution.

Pre-existing risk; not introduced by BD-194. Surface for future
investigation but not actionable in this commit.

### §9.7 RISK-7 — Downstream check dependencies on Check 24 (zero)

Architect §2.6.1 enumerated downstream dependencies on the
byte-identity assumption. Confirmed by planner audit:

| Downstream surface | Behavioral dependency? | Comment dependency? | Edit needed in this commit? |
|---|---|---|---|
| Check 22 (`check_help_fragment_freshness`) | YES — latent bug | NO | YES (architect §5.1) |
| Check 23 (`check_help_fragment_completeness`) | YES — fail-loud upgrade | NO | YES (architect §5.1) |
| `pack-help.sh` runtime rendering | NO | NO | NO |
| `scripts/init-project.sh` S11 (post-BD-193) | NO | NO | NO |
| Check 43 `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` | NO | NO (path-keyed exemption is still correct) | NO |
| Check 40 `_BARE_REFERENCE_EXEMPTIONS` `HELP-FRAGMENT.md` | NO | YES (L4762-4770 rationale text) | YES |
| Check 43 `_CHECK_43_ALLOWLIST` `HELP-FRAGMENT-TRACKER.md` | NO | YES (L5126 rationale text) | YES |
| Check 37 anchor-phrase comment L4051 | NO | LOW — survives content divergence today | NO (architect §5.2 future-aware only) |
| `.github/workflows/validate-pack.yml` | NO | NO | NO |

Verdict: ZERO behavioral surprises beyond the architect-identified
scope. Comment edits limited to the 2 allowlist locations explicitly
named.


---

## §10 Cross-references

### §10.1 Architect doc

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179 lines)
  - §1 Scope & Background (problem statement; pack memory anchors; HEAD evidence)
  - §2 Investigation findings (file content; natural divergence patterns; `check_issue_template_forms` pattern survey; current Check 24 implementation; existing tests; downstream dependencies; Phase 4 candidates re-evaluation)
  - §3 Candidate evaluation (Candidates 1-6; goal-criteria matrix)
  - §4 Recommended design (Candidate 6 rationale; comparison to alternatives; in-scope-vs-follow-on for Check 22 latent bug)
  - §5 Implementation shape (§5.1 function signature changes; §5.2 allowlist comment updates; §5.3 per-check test file; §5.4 step-by-step replacement logic; §5.5 test plan)
  - §6 Future evolution (divergence scenarios + CI signal mapping; scalability; long-term anticipation)
  - §7 POQs (POQ-1 Check 22 scope; POQ-2 README timing; POQ-3 comment-text precision)
  - §8 Cross-references

### §10.2 BD-194 entry

- `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open; Position Batch 19d-prep-3;
  Blockers: BD-193 Resolved; Unblocks: BD-185 H.2; Pipeline: architect →
  user review → planner → user review → coder → reviewer)

### §10.3 Pack memory anchors (authoritative; not adjustable in this commit)

- `feedback_pack_project_separation_of_concerns` — user-locked 2026-05-26;
  authoritative for the BD-194 architectural correction.
- `feedback_deferral_is_scope_creep` — applies to the Check 22 in-scope
  inclusion (LOGICAL FIT) and to POQ-1 deferral discussion.
- `feedback_review_carry_forward_discipline` — high bar for reviewer
  pass on any "defer to follow-on" framing post-coder.
- `feedback_pack_coder_preflight_pattern` — PREFLIGHT line + STOP-MEANS-STOP
  preamble required in coder spawn (§5.5 + §7.3).
- `feedback_spawn_agents_in_background` — coder + reviewer spawns use
  `run_in_background: true` per default rule.
- `feedback_implicit_status_flip` — BD-194 status flip to Resolved is
  end-of-batch action; not part of this commit.
- `feedback_pack_chat_does_no_fixes` — Pack Chat may edit
  PM-only files directly (README.md per §7.2) but coder owns
  `scripts/validate-pack.py` per §7.1.
- `feedback_manifest_regen_on_v11_surface` — RC9 trigger fires on
  `scripts/` edits; manifest regenerated in same commit (§5.4 G4).
- `feedback_planner_user_review_before_coder` — this planner deliverable
  goes to user for thorough review before coder spawns.

### §10.4 Related architect docs (read-only context for coder)

- `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
  §1.4 — Check 43 allowlist contract (cross-reference for §5.2 L5126 edit).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3 —
  Check 41 `_CLIENT_INSTALLED_FILES` self-doc list integrity (the
  project-side existence guarantee Candidate 6 relies on; Check 41
  PASSes at HEAD with the project-side `HELP-FRAGMENT-TRACKER.md`
  entry present).

### §10.5 Pipeline next steps (post-planner-pass)

1. **User review of this PLAN-BD-194.md.** Resolve POQ-1 + POQ-2.
   POQ-3 explicitly non-blocking per architect; user may comment but
   coder pass proceeds regardless.
2. **Spawn pack-coder.** Background spawn (`run_in_background: true`)
   with this PLAN as the mechanical reference + ARCHITECTURE-BD-194 as
   the design reference. STOP-MEANS-STOP preamble + PREFLIGHT pattern
   per §5.5 + §7.3.
3. **Coder verification gates G1-G4** per §5.
4. **PREFLIGHT line + IMPL-REPORT write** per §5.5.
5. **Pack Chat edits README.md** (PM-only per §7.2) + applies pack-root
   trinity edits if POQ-1 resolved to Option A.
6. **Stage + commit** (Pack Chat owns; user approval per
   `feedback_no_destructive_without_approval`). Commit subject per §4.3.
7. **Spawn pack-reviewer** (background per `feedback_spawn_agents_in_background`)
   with review scope per §6.2.
8. **Pack Chat triages reviewer findings** per `feedback_fix_all_review_findings`;
   any fix-coder pass follows the same pattern.
9. **End-of-batch BD-194 status flip** per §6.3.
10. **BD-185 H.2 spawns** on the post-BD-194 baseline per the BD-194
    entry "Unblocks" field.


---

*End of planner deliverable.*
