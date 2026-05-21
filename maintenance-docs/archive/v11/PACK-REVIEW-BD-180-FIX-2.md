# PACK-REVIEW-BD-180-FIX-2.md

Per-commit review report for the BD-180 FIX-2 fix-coder commit closing
PACK-REVIEW-BD-180-FIX-1.md §4.1 SHOULD (Option A) + §4.2 NIT (heredoc
asymmetry). §4.3 NIT SKIPPED per Pack Chat triage (reviewer's own
no-action recommendation). Part of the BD-175 EMERGENCY BATCH elevated-
care protocol — per-BD review/fix runs inline before the next BD's
coder spawns.

- **Commit under review:** `e45a90ca3a956854dc05b3a0b61267e6ad863837`
  ("fix: v11 — BD-180 FIX-2 case-(i) wording + heredoc-quoting
  consistency")
- **Compared against:** `093c503bc82b53444717793147c424b981c21beb`
  (BD-180 FIX-1; the prior fix under review)
- **Reviewer agent:** `pack-reviewer` (sequential, in-place against
  parent worktree)
- **Date:** 2026-05-20
- **Diff stat:** 3 files changed, +693 / -13 (per `git show --stat`):
  - `scripts/validate-pack.py` (+9 / -8)
  - `scripts/tests/test-validate-pack-check-41.sh` (+52 / -5)
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-2.md` (+632 / -0; new)
- **Files NOT touched (correctly):** zero `project-template/` edits,
  zero `supporting-docs/` edits, zero `pack-ops/` prose edits, zero
  trinity edits. Pack-internal CI tooling + docs only.
- **Reviewer carry-forward discipline:** I am the 4th reviewer bound by
  the discipline encoded at `.claude/skills/review/SKILL.md` § "Carry-
  forward discipline" (FIX-5 in BD-179 fix-cycle, commit `ff23a00`).
  Applied rigorously to my own findings (see §6).

---

## §1 Verdict

**APPROVE-WITH-FIXES.**

Both §4.1 and §4.2 closures land cleanly at the mechanical level:

- **§4.1 closure:** the `# (no entries)` parenthetical advice is fully
  removed from `check_client_installed_files` case-(i) `fail()`. The
  replacement text points at `ARCHITECTURE-BD-176.md §5.3` and offers
  the "remove the entire block" remediation. The wording-loop that
  triggered the SHOULD finding (case-(i) advice → case-(ii) error)
  is genuinely broken.

- **§4.2 closure:** Group 1 of `test-validate-pack-check-41.sh`
  is now byte-shape-consistent with Group 2 — `<<'EOF'` quoted heredoc
  + `REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE"` env-var injection +
  `os.environ['REPO_ROOT']` / `os.environ['VALIDATE']` in-Python
  bindings. The mechanical asymmetry is gone; the comment block above
  the heredoc cites the same defensive rationale as Group 2.

- **T14 regression guard:** the new T14 case is well-formed. Positive
  assertion matches the actual case-(ii) error substring exactly
  (`"block body could not be parsed into inventory entries"`).
  Negative assertions cover both off-path diagnostics (case-(i)'s
  `"block body could not be captured"` AND case-(iii)'s
  `"block contains no parseable entries"`). T14 would correctly
  break if a future Option B change special-cased the placeholder
  without updating the test.

- **All verifications green:** Check 41 test suite 4/4 PASS (T1-T14);
  validate-pack.py exits 0 with Check 41 `38 entries / 35 cmd_update /
  0 drift`; adjacent suites (Check 39 / Check 40 / Checks 36-37-38)
  all green; boundary discipline (P-missed-7) satisfied — zero
  project-side / supporting-docs / pack-ops prose / trinity edits.

Verdict not pure APPROVE because there is one SHOULD-level finding
(§4.1 below) — the FIX-2 wording introduces a **new, milder wording
loop**: the new advice "remove the entire block" would, if literally
followed, deterministically trip the SHOULD-1 marker-uniqueness branch
("missing `_CLIENT_INSTALLED_FILES_START` marker... found 0"). This
is a different failure mode (informative + structurally clean), not
the cyclical case-(i)→case-(ii) loop FIX-2 was meant to break, but
it is still a remediation that doesn't reach `OK`. One additional NIT
about test-harness internal comment drift (§4.2).

Verdict not REJECT because the original SHOULD wording-loop is
genuinely broken and both findings are improvements over FIX-1's
state. The two new findings are also low-risk — error-message wording
in a self-debugging integrity gate (§4.1) and a stale internal comment
in a test harness (§4.2). Pack Chat default-fix-all triage handles both.

---

## §2 Severity breakdown

| Severity | Count |
|---|---|
| BLOCKER | 0 |
| MUST | 0 |
| SHOULD | 1 |
| NIT | 1 |

---

## §3 Per-finding closure table (FIX-1 review → FIX-2 outcome)

| Finding (FIX-1 review) | Severity (FIX-1) | Coder action | Reviewer verdict |
|---|---|---|---|
| **§4.1 SHOULD-1** (case-(i) `# (no entries)` advice triggers case-(ii)) | SHOULD | Option A applied: dropped `# (no entries)` parenthetical from `check_client_installed_files` case-(i) `fail()`; replaced with neutral guidance pointing at `ARCHITECTURE-BD-176.md §5.3` design intent + "remove the entire block" remediation. Verified empirically by §5.4 probe (`# (no entries)` absent from output; new advice substrings present). | **Closed cleanly for the original loop.** The case-(i) → case-(ii) cyclical advice is genuinely removed. **One residual SHOULD** carried forward: the new "remove the entire block" advice itself lands in a different Check 41 failure path (SHOULD-1 marker-uniqueness). See §4.1 below — the residual is milder (structurally informative, not cyclical), so the FIX-2 is a net improvement but not yet a clean fix-to-OK path. |
| **§4.2 NIT-1** (Group 1 vs Group 2 heredoc asymmetry) | NIT | Group 1 converted to `<<'EOF'` + env-var injection matching Group 2; comment block above the heredoc cites Group 2's defensive rationale verbatim. Five mechanical changes (heredoc quoting, env-var prefix, `import os, sys`, `REPO_ROOT_PY`/`VALIDATE_PY` bindings, in-Python path references) all applied. | **Closed cleanly.** Group 1 now matches Group 2 byte-shape; the future-backtick footgun is eliminated. Test still PASSes (Group 1 OK in test output). One residual NIT carried forward: T7b's internal comment at `scripts/tests/test-validate-pack-check-41.sh:365-366` still uses the old "empty inventory requires at least one content line" framing that contradicts the FIX-2 user-facing diagnostic; see §4.2 below. |
| **§4.3 NIT-2** (defensive duplication, no-action) | NIT | SKIPPED per Pack Chat triage in accordance with reviewer's own no-action recommendation. | **Triage honored** — no edit; no defect at HEAD. |

Both fix-targeted findings closed at the mechanical level. Two new
findings (one SHOULD residual from §4.1, one NIT from §4.2) surfaced
in §4 — both are downstream of the FIX-2 edits and would not exist
without the FIX-2 changes.

---

## §4 New findings (introduced by FIX-2 or surfaced during review)

### §4.1 SHOULD-1: New case-(i) advice "remove the entire block" deterministically trips SHOULD-1 marker-uniqueness branch

- **Severity:** SHOULD
- **File:symbol:** `scripts/validate-pack.py:check_client_installed_files`
  case-(i) `fail()` block (lines 5023-5025 — the `(c)` clause's new
  parenthetical body)
- **Problem:** The FIX-2 wording change replaces the case-(i) `(c)`
  clause body with:

  > "empty inventory should not need this block at all — if no files
  > install to clients, remove the entire block per
  > ARCHITECTURE-BD-176.md §5.3"

  If a maintainer follows this advice literally and removes BOTH
  `_CLIENT_INSTALLED_FILES_START` and `_CLIENT_INSTALLED_FILES_END`
  markers from `scripts/init-project.sh`, the result is:
  `start_count = 0` and `end_count = 0` — which lands in the
  SHOULD-1 marker-uniqueness branch at
  `check_client_installed_files` lines 4952-4985 with the diagnostic
  `"missing `_CLIENT_INSTALLED_FILES_START` marker in
  scripts/init-project.sh (found 0; expected exactly 1); missing
  `_CLIENT_INSTALLED_FILES_END` marker..."`.

  This is a NEW wording loop introduced by FIX-2, parallel to the
  one FIX-2 was meant to break: case-(i)'s advice now produces
  SHOULD-1's error instead of case-(ii)'s error. The new loop is
  MILDER than the FIX-1 case-(i)→case-(ii) loop because:

  1. The new failure (SHOULD-1) is structurally informative — it
     names the missing marker and says "found 0; expected exactly
     1" — so a maintainer encountering it learns what's needed
     (add the markers back) rather than chasing a vague entry-shape
     error.
  2. The transition is one-hop (case-(i) → SHOULD-1) rather than
     re-entering the same branch (FIX-1's loop was case-(i) →
     case-(ii), which could itself recommend `# (no entries)` advice
     in some implementations and re-trip).

  But it is still NOT a fix-to-`OK` path. A maintainer following
  the literal new advice ends up with a different Check 41 failure
  rather than a green check. The genuinely-correct path for
  "no files install to clients" today is not surfaced anywhere in
  the new advice — and per `ARCHITECTURE-BD-176.md` §5.3 (the doc
  the advice cites), §5.3 actually describes the inventory block as
  the source authority for inventory; it does NOT describe a
  "remove the block" path. The cited authority does not support the
  remediation it's cited for.

  Verified by trace through `check_client_installed_files`:
  - Line 4938: `init_sh` file check — passes (init-project.sh exists).
  - Line 4943: parser call — returns `([], 0, 0, False, False)` per
    `_parse_client_installed_files` lines 4886-4888 (exactly-once
    short-circuit when `start_count != 1`).
  - Line 4952: `if start_count != 1 or end_count != 1:` — TRUE
    (both are 0), branch entered.
  - Lines 4954-4958: appends "missing _CLIENT_INSTALLED_FILES_START
    marker in scripts/init-project.sh (found 0; expected exactly 1)".
  - Lines 4965-4969: appends "missing _CLIENT_INSTALLED_FILES_END
    marker in scripts/init-project.sh (found 0; expected exactly 1)".
  - Lines 4976-4984: `fail()` emits the joined error.

  Result: removing the block → SHOULD-1 failure, not `OK`.

- **Suggested fix:** Two options; coder picks:

  **Option A (minimal-diff):** Update the `(c)` clause to surface the
  TRUE path for "no files install to clients" — which is the
  `_CHECK_41_EXEMPTIONS` allowlist mechanism (already referenced at
  lines 5072-5078 + 5099 in the source-existence branch, but NOT
  surfaced in case-(i)). Specifically: a maintainer who wants to
  ship an `init-project.sh` with no files-to-clients can keep the
  markers, leave the block empty (with a single content line that
  is shape-`#  PLACEHOLDER  ->  PLACEHOLDER  [stage:none]`), and
  add the placeholder to `_CHECK_41_EXEMPTIONS`. Or — if "no files
  install to clients" really means "Check 41 doesn't apply to my
  setup," the right path is the lenient-mode return at lines
  4939-4941 (currently keyed only on `init-project.sh` being absent
  entirely). Re-cast the `(c)` clause to point at one of these two
  real paths rather than "remove the block" which simply re-trips.

  **Option B (rework the marker contract):** Make
  `_CLIENT_INSTALLED_FILES_START`/`_END` markers OPTIONAL — if
  neither exists, `check_client_installed_files` returns `ok()`
  (the "no client-installed files; nothing to verify" case). This
  changes parser semantics so the new "remove the entire block"
  advice IS a fix-to-`OK` path. Requires updating
  `_parse_client_installed_files` to distinguish "absent markers
  (legitimate empty-inventory case)" from "present markers with
  count != 1 (defect)," updating the caller's branch order, and
  adding a T15 case that asserts the absent-markers case lands in
  `ok()`. More work; aligns the user-facing advice with the gate's
  actual semantics.

- **Rationale:** The case-(i) error message is a contract with the
  maintainer. FIX-2's repair of the original wording loop is correct
  in direction (drop the `# (no entries)` advice), but the
  replacement advice creates a different wording loop. Per the same
  `surface-over-silently-fail` pack memory pattern cited in the
  FIX-1 IMPL-REPORT §1.1 — and per the `correctness` priority in
  `.claude/skills/review/SKILL.md` — remediation advice should
  surface a path that actually fixes the problem, not a path that
  re-triggers the gate (even when the re-trigger is "informative").
  The discipline at the review-skill level is unchanged whether the
  re-trigger lands one branch over or in a cycle.

  **Severity SHOULD (not BLOCKER/MUST):** the residual loop is
  milder than the FIX-1 loop, the new SHOULD-1 failure is
  structurally clear, and the production state at HEAD (`38 entries
  / 0 drift`) is unaffected. A real maintainer encountering case-(i)
  will likely reach for the `ARCHITECTURE-BD-176.md` §5.3 cite (good)
  and notice the cite doesn't actually describe "remove the block"
  (also good — surfaces the inconsistency). But the user-facing
  diagnostic remains inconsistent until reworked.

### §4.2 NIT-1: T7b internal comment uses obsolete "empty inventory requires at least one content line" framing

- **Severity:** NIT
- **File:symbol:** `scripts/tests/test-validate-pack-check-41.sh`
  lines 365-366 (T7b's internal comment block above the
  `raw_truly_empty` fixture)
- **Problem:** The T7b comment reads:

  > Documents that "empty inventory" requires at least one content
  > line between markers for the regex to capture cleanly.

  This was accurate when the FIX-1 case-(i) error message recommended
  `# (no entries)` as a remediation — the comment captured why T7b
  existed (to test the truly-empty case that would have prompted the
  `# (no entries)` advice). After FIX-2 dropped the `# (no entries)`
  advice and replaced it with "remove the entire block at all," the
  comment is stale: the new user-facing diagnostic does NOT recommend
  adding a content line; it recommends removing the block. The
  comment's framing "empty inventory requires at least one content
  line" now contradicts the user-facing diagnostic at lines 5023-5025.
- **Suggested fix:** Replace the T7b comment line at 365-366 with
  framing that matches the FIX-2 wording. E.g.:

  > Documents that a truly-empty body (zero chars between adjacent
  > marker lines) is captured by case (i) ("block body could not be
  > captured"), since the `.+?` capture requires at least one
  > character. Per FIX-2, the user-facing remediation now points at
  > ARCHITECTURE-BD-176.md §5.3 rather than recommending a content-
  > line placeholder.

  Pure comment edit — no behavior change; no assertion change. ~2
  lines.
- **Rationale:** Test-harness internal comments are documentation for
  future maintainers reading the test to understand WHY a case exists
  and what it asserts. When the user-facing diagnostic that motivated
  the test changes, the test's "why" comment should follow. NIT
  (not SHOULD) because the assertions are still correct, the test
  still passes, and the comment is internal-only (no client-facing
  surface). Surfaced for proactive drift reduction.

---

## §5 Verification results

All verification commands returned green; specific outputs below.

### §5.1 `python3 scripts/validate-pack.py` at HEAD

Final Check 41 line:

```
── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked;
  38 resolve to existing files at HEAD, 0 on exemption allowlist.
  35 cmd_update path(s) cross-checked against inventory; 0 drift(s)
  (must be 0). Self-documenting list is consistent with copy-site state.

============================================================
PASSED — all checks clean
```

Exit code: 0. Check 41 behavior at HEAD is functionally identical to
pre-FIX-2 (`38 entries / 0 drift`) — the wording fix is purely in the
diagnostic-message path, not exercised by the well-formed production
file.

### §5.2 `bash scripts/tests/test-validate-pack-check-41.sh`

```
=== Group 0: Module import + Check 41 symbol registration ===
  PASS validate-pack.py imports + Check 41 symbols registered

=== Group 1: _parse_client_installed_files unit tests ===
OK
  PASS _parse_client_installed_files parses real init-project.sh correctly

=== Group 2: Synthetic init-project.sh PASS/FAIL tests ===
OK
  PASS Synthetic PASS/FAIL tests (T1-T14 including T7/T7b SHOULD-2
       disambiguation, T8-T10 SHOULD-1 duplicate-marker, and T14 FIX-2
       placeholder-loop regression guard)

=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0; Check 41 runs and reports clean

=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

All 4 test groups PASS. T14 (the new regression guard) PASSes — its
positive assertion matches the actual case-(ii) error substring and
its two negative assertions correctly exclude case-(i) + case-(iii)
diagnostics. Group 1's converted heredoc pattern works identically to
its pre-FIX-2 shell-interpolated form (`OK` print + zero failures
from the real init-project.sh parse).

### §5.3 Adjacent test suites green (regression check)

- `bash scripts/tests/test-validate-pack-check-39.sh`: PASS 6 / FAIL 0
- `bash scripts/tests/test-validate-pack-check-40.sh`: PASS 8 / FAIL 0
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh`: PASS 6 / FAIL 0

No regression in adjacent boundary / cross-reference / install-coverage
gates. The validate-pack.py edit is scoped strictly to one `fail()`
block within `check_client_installed_files`; adjacent checks share no
code with the edited region.

### §5.4 §4.1 wording-fix verification

The IMPL-REPORT §5.4 documents a transient probe script confirming:
- `# (no entries)` absent from the new diagnostic output.
- `"empty inventory should not need this block at all"` PRESENT.
- `"ARCHITECTURE-BD-176.md §5.3"` PRESENT.
- `"block body could not be captured"` PRESENT (case-(i) diagnostic
  still fires for the empty-body regex-non-match shape).

The four assertions are independently verifiable by static inspection
of `scripts/validate-pack.py` lines 5014-5032 (the new `fail()` block).
Verified by reading the source; no contradiction with the IMPL-REPORT.

### §5.5 RC9 manifest verification

The IMPL-REPORT §5.6 / §6 claim `bash test-fixtures/build.sh
--all --clean` produces empty diff on `test-fixtures/manifest.txt`.

This reviewer did NOT independently re-run the manifest rebuild
(read-only-review constraint; the rebuild is a state-changing
operation requiring permission). The IMPL-REPORT's claim is consistent
with the rule:

- Both edited files (`scripts/validate-pack.py`,
  `scripts/tests/test-validate-pack-check-41.sh`) are pack-internal CI
  tooling; neither is on the `scripts/init-project.sh` stage S1-S11
  client-install path.
- Per the trinity Pack memory RC9 trailing clause: when the
  inclusive-directory trigger fires (here, `scripts/` is touched) but
  the edited files are not actually fixture-affecting, the rebuild is
  a ~30-90s false positive that produces empty diff.

Reviewer accepts the IMPL-REPORT's manifest-empty-diff claim with the
note that independent re-verification by Pack Chat (which can perform
the rebuild) is the canonical authority per RC9.

### §5.6 Boundary discipline (P-missed-7)

Files modified per `git diff --name-only 093c503..e45a90c`:
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-2.md` (new pack-internal doc)
- `scripts/tests/test-validate-pack-check-41.sh` (pack-internal CI tooling)
- `scripts/validate-pack.py` (pack-internal CI tooling)

Zero `project-template/` edits; zero `supporting-docs/` edits; zero
`pack-ops/` prose edits; zero trinity edits. All three files are
pack-only by construction (not copied to clients by any
`init-project.sh` stage, not referenced by any client-side file).
Per the `boundary-investigation` skill Step 5: project-template/
deny-list not engaged because no project-side file was modified. No
SSOT investigation required. BOUNDARY DISCIPLINE SATISFIED.

### §5.7 Backward-compat — dropped wording is not externally referenced

`grep -rn "# (no entries)" scripts/ supporting-docs/ project-template/ test-fixtures/`
returns zero matches in production / fixture surfaces. The phrase
appears only in:
- `project-template/docs/pack/PACK-FEEDBACK.md` lines 176/179/182/etc.
  using the unrelated `*(no entries yet)*` prose form (not the
  `# (no entries)` placeholder advice the FIX-2 removed).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-2.md`
  + `PACK-REVIEW-BD-180-FIX-1.md` — historical references documenting
  the dropped wording.

No CI workflow, no client-facing doc, no test fixture pattern-matches
the dropped `# (no entries)` phrase. Backward-compat preserved.

### §5.8 T14 assertion specificity verification

T14 (lines 590-615 in the test harness) asserts:

| Assertion | What it verifies | Specificity |
|---|---|---|
| `fail_count >= 1` | Placeholder input produces at least one failure | Bounds-only; adequate as a guard |
| `"block body could not be parsed into inventory entries" in captured` | Lands in case-(ii) entry-shape diagnostic | Substring matches the actual `fail()` text at lines 5037-5050 |
| `"block contains no parseable entries" not in captured` | Does NOT trip case-(iii) legacy diagnostic | Substring matches case-(iii) text at line 5055 |
| `"block body could not be captured" not in captured` | Does NOT trip case-(i) regex-non-match diagnostic | Substring matches case-(i) text at line 5017 |

All four assertions are tied to specific substrings of the actual
diagnostic strings in `validate-pack.py`. Future change to case-(ii)
wording would break T14's positive assertion; future Option B parser
change (special-casing the placeholder to land in case-(iii)) would
break T14's negative-(iii) assertion. T14 is a well-formed regression
guard for both the positive landing path and the two negative off-paths.

### §5.9 Commit subject length

```
$ printf '%s' 'fix: v11 — BD-180 FIX-2 case-(i) wording + heredoc-quoting consistency' | wc -m
      70
```

Exactly at the 70-character soft guideline. Acceptable (the rule is
"≤ 70," and 70 = 70 is under-or-equal). Improvement margin available
for future fixes but not a defect here.

### §5.10 Caller adaptation correctness — no off-target edits

`git diff 093c503..e45a90c -- scripts/validate-pack.py` shows exactly
one edited region: lines 5023-5031 (the case-(i) `fail()` block's
`(c)` clause body). No off-target edits to:
- `_parse_client_installed_files` (parser unchanged — Option A scope).
- The case-(ii) `fail()` block (lines 5037-5050 — preserved).
- The case-(iii) `fail()` block (lines 5054-5060 — preserved).
- The SHOULD-1 marker-uniqueness branch (lines 4952-4985 — preserved).
- Any other Check 41 surface.

`git diff 093c503..e45a90c -- scripts/tests/test-validate-pack-check-41.sh`
shows exactly two edited regions: Group 1 heredoc conversion (lines
66-77) + T14 case addition (lines 577-615) + the `t_pass` summary
message update (line 625). No off-target edits to:
- Group 0 (module import test — line 36-58).
- T1-T13 cases (lines 187-575 — preserved).
- The `run_check` helper (lines 157-340 — preserved).

Surgical scope; no scope creep.

---

## §6 Carry-forward observations

**Carry-forward discipline applied per `.claude/skills/review/SKILL.md`
§ "Carry-forward discipline" (FIX-5 in BD-179 fix-cycle, commit
`ff23a00`). I am the 4th reviewer bound by this discipline.**

**Zero carry-forwards surfaced.** Both findings in §4 are surfaced as
in-scope (SHOULD or NIT) for Pack Chat default-fix-all triage. None
are deferred to a future BD, batch, or end-of-batch reviewer.

### §6.1 Findings considered for carry-forward and rejected

1. **§4.1 case-(i) residual wording loop (`"remove the entire block"`
   trips SHOULD-1)** — considered as "could be deferred to a
   post-launch documentation polish cycle." **FAILS all three
   high-bar tests:**
   - SIZE: Option A is a ~5-15 line wording change in one function;
     Option B is a ~30-50 line parser-semantics change. Both fit
     within a single fix-coder cycle. Neither is architect-pass
     material requiring new design surface — the design surface
     (Check 41 + the marker contract) is fully described in
     `ARCHITECTURE-BD-176.md` §5.3 + the parser docstring.
   - BLOCKED: no dependency on any not-yet-landed artifact. The
     case-(i) `fail()` block, the SHOULD-1 marker branch, and
     `_CHECK_41_EXEMPTIONS` all exist at HEAD.
   - LOGICAL-FIT: the defect is in the SAME symbol the FIX-2 commit
     edited (`check_client_installed_files` case-(i) `fail()`).
     There is no future sibling BD this naturally belongs with —
     the deferral would just be "later." Surfaced as SHOULD per
     default-fix-all.

2. **§4.2 T7b internal comment stale framing** — considered as
   "could be deferred to a test-harness comment refresh cycle."
   **FAILS all three tests:**
   - SIZE: pure 2-line comment edit; no test behavior change.
   - BLOCKED: no dependency.
   - LOGICAL-FIT: same file the FIX-2 commit edited (Group 1 +
     T14); same test-harness context as the wording it now
     contradicts. Surfaced as NIT per default-fix-all (NIT default
     is also FIX per the discipline).

### §6.2 Considered but not surfaced as findings

The following observations were considered during review and judged
to be NOT defects at HEAD — neither in-scope findings nor
carry-forwards:

1. **T14's `run_check` invocation passes `extant_paths=
   ["project-template/docs/pack/FOO.md"]` to a synthetic fixture
   that never references `FOO.md`.** This is consistent with T11/
   T12/T13's pattern — the extant path is staged so the synthetic
   `cmd_update` `entries=()` array doesn't trip the cross-check
   gate later in `check_client_installed_files`. Not a defect; the
   path serves the run_check helper's contract. NOT surfaced.

2. **`ARCHITECTURE-BD-176.md` §5.3 cited in the new case-(i)
   `(c)` clause does not actually describe "remove the block"
   as a remediation.** This was considered as a fold-in to §4.1
   but is structurally part of the SAME finding (the new advice
   text is internally inconsistent with the cited authority).
   Folded into §4.1 SHOULD rather than surfaced separately.
   NOT surfaced as a distinct finding.

3. **The 70-char commit subject is at the boundary.** The rule is
   "≤ 70 chars" per CLAUDE.md commit-format section; 70 is the
   boundary, not over. Not a defect. NOT surfaced.

### §6.3 Forbidden carry-forward shapes self-checked

- "broader pattern without expanding scope"? No — §4.1 and §4.2
  each cite specific file:symbol and concrete evidence; neither
  uses "this is a broader pattern" framing.
- "worth ~N minutes before batch closes"? No.
- forward-looking conjecture ("X is likely to grow", "this could
  drift")? §4.1 names a CURRENT behavior (the literal advice
  produces a literal failure today, verifiable by trace at the
  cited line numbers); §4.2 names a CURRENT contradiction (the
  comment at lines 365-366 contradicts the diagnostic at lines
  5023-5025 today). Neither is conjecture.
- design ratification ("this is a feature, not a bug")? No.
- "pack memory recommends fix-now but I'm deferring"? No — both
  findings are surfaced fix-now.

Zero carry-forwards survive the high bar. The two findings in §4
are all in-scope for Pack Chat's default-fix-all triage; the rejected
candidates in §6.1 are documented as rejected, not deferred.

---

## §7 What the implementation got right

Acknowledgments per review skill principle "A review that only lists
problems is incomplete":

- **Original wording loop genuinely broken.** The FIX-1 case-(i)→
  case-(ii) cyclical loop (the original SHOULD finding) is
  conclusively closed. A maintainer who reads the new case-(i)
  diagnostic no longer sees the `# (no entries)` advice that would
  re-trip on case-(ii). The structural problem this fix targeted is
  resolved.

- **Surgical scope.** Only the `(c)` clause's parenthetical body
  changed in the `fail()` call. The diagnostic's overall shape
  (preamble + regex pattern + four-cause enumeration + canonical-
  restore guidance) is preserved. No off-target edits to adjacent
  branches (case-(ii), case-(iii)) or the SHOULD-1 marker branch.
  Evidence: §5.10 diff confines the edit to lines 5023-5031.

- **Group 1/Group 2 heredoc consistency.** All five mechanical
  changes from the §4.2 suggested fix applied verbatim. The comment
  block above the new Group 1 heredoc cites Group 2's defensive
  rationale (`<<'EOF'` quotes the body; env-var injection passes
  paths) so future maintainers see the "why" before encountering
  the pattern. Pattern parity is restored.

- **T14 is a well-formed regression guard.** Positive assertion ties
  to actual case-(ii) substring; two negative assertions exclude
  the off-paths (case-(i), case-(iii)). T14 would correctly break
  if a future change tried to special-case the placeholder. The
  test is documented in §2.3 of the IMPL-REPORT with explicit
  rationale (defends against silent Option B drift; documents
  empirical historical behavior).

- **Boundary discipline.** Zero project-template/ edits; zero
  supporting-docs/ edits; zero pack-ops/ prose edits; zero trinity
  edits. Pure pack-internal CI tooling improvement. Per
  `boundary-investigation` skill Step 5: project-template/ deny-list
  not engaged.

- **Carry-forward discipline in the IMPL-REPORT.** Coder's §7
  explicitly rejected four plausible-but-borderline deferral
  candidates with SIZE / BLOCKED / LOGICAL-FIT reasoning. Reviewer
  concurs with all four rejections.

- **Backward-compat preservation.** Case-(iii) preserves the legacy
  `"no parseable entries"` message verbatim (unchanged). T7b's
  positive assertion `"no body between adjacent marker lines"` is
  preserved (the FIX-2 wording change kept the case-(i) `(c)`
  clause OPENING text intact; only the parenthetical body changed).
  T1-T13 unchanged in behavior; T7b still PASSes against the
  modified diagnostic.

- **Specific + actionable triage decisions.** §1.3 explicitly
  documents the SKIP for §4.3 NIT per Pack Chat triage + reviewer's
  no-action recommendation. No silent drop; the decision is auditable.

- **Manifest hygiene plan.** RC9 trigger acknowledged as fired
  (`scripts/` touched); manifest rebuild predicted to produce empty
  diff (neither edited file is on the client-install path); plan
  surfaces in IMPL-REPORT §6 for Pack Chat's staging decision.

- **PREFLIGHT pattern compliance.** IMPL-REPORT §10 DoD checklist
  includes the PREFLIGHT line emission requirement, consistent
  with the `feedback_pack_coder_preflight_pattern` pack memory.

- **Commit subject at the boundary.** 70 characters (exactly at the
  soft guideline). Not over — acceptable. The fix-coder honored
  the commit-format discipline despite this fix touching two scope
  surfaces (validate-pack.py wording + test-harness consistency).

---

## §8 Summary

BD-180 FIX-2 commit `e45a90c` is **APPROVE-WITH-FIXES.**

- Both §4.1 SHOULD and §4.2 NIT findings from PACK-REVIEW-BD-180-FIX-1
  closed at the mechanical level.
- §4.3 NIT SKIPPED per Pack Chat triage; reviewer's no-action
  recommendation honored.
- T14 regression guard added correctly; positive + negative
  assertions cover all three case branches of the disambiguation.
- All 4 Check 41 test groups PASS (T1-T14); validate-pack.py exits
  0 with `38 entries / 35 cmd_update / 0 drift`.
- All adjacent test suites green (Check 39 / Check 40 / Checks
  36-37-38).
- Manifest rebuild predicted empty (per IMPL-REPORT §5.6 / §6);
  reviewer accepts the claim subject to Pack-Chat re-verification
  (RC9 trailing clause: rebuild is the canonical authority).
- Boundary discipline satisfied (zero project-side / supporting-
  docs / pack-ops prose / trinity edits).
- Commit subject exactly 70 chars (under-or-equal soft guideline).
- Carry-forward discipline applied; zero deferrals; rejected
  candidates documented in §6.1.

One new SHOULD finding (§4.1: new case-(i) "remove the entire block"
advice deterministically trips SHOULD-1 marker-uniqueness branch —
a new wording loop, milder than the FIX-1 case-(i)→case-(ii) loop
but still not a fix-to-`OK` path). One NIT (§4.2: T7b internal
comment at lines 365-366 still uses obsolete "empty inventory
requires at least one content line" framing that contradicts the
new user-facing diagnostic). Both are in-scope for Pack Chat
default-fix-all triage; neither is a carry-forward.

Pack Chat to triage §4.1 + §4.2 per default-fix-all and proceed
(per BD-175 elevated-care: the per-commit reviewer is the last gate
before the next commit's coder spawns).
