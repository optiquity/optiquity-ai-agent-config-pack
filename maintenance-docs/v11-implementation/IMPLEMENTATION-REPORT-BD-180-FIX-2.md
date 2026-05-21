# IMPLEMENTATION-REPORT-BD-180-FIX-2.md

BD-180 FIX-2 implementation report for the BD-175 EMERGENCY BATCH —
bundled fix-coder cycle closing PACK-REVIEW-BD-180-FIX-1.md §4.1 SHOULD
(Option A) and §4.2 NIT (heredoc-style consistency). §4.3 NIT
(defensive duplication observation) SKIPPED per Pack Chat triage in
accordance with the reviewer's own no-action recommendation.

- **HEAD (pre-fix):** `093c503bc82b53444717793147c424b981c21beb`
  ("fix: v11 — BD-180 SHOULD-1/2 _parse_client_installed_files
  hardening" — the FIX-1 commit under review)
- **HEAD (post-fix, working tree):** `093c503bc82b53444717793147c424b981c21beb`
  (unchanged — agents never commit; Pack Chat will stage + commit)
- **Fix-coder agent:** `pack-coder` (in-place, no worktree isolation)
- **Date:** 2026-05-20
- **Diff stat (working tree vs HEAD):** 2 files changed, +61 / -13:
  - `scripts/validate-pack.py` (+9 / -8)
  - `scripts/tests/test-validate-pack-check-41.sh` (+52 / -5)
- **Files NOT touched (correctly):** zero `project-template/` edits,
  zero `supporting-docs/` edits, zero `pack-ops/` prose edits, zero
  trinity edits, zero `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md`
  edits, zero `.claude/skills/review/SKILL.md` edits, zero edits to any
  `validate-pack.py` symbol other than the case-(i) `fail()` block in
  `check_client_installed_files`.

---

## §1 Problem restatement (from PACK-REVIEW-BD-180-FIX-1.md)

### §1.1 §4.1 SHOULD — case-(i) error-message wording loop

`scripts/validate-pack.py:check_client_installed_files` case-(i)
`fail()` block (the body-capture-regex-non-match diagnostic) included a
remediation example that created a wording loop:

> "(c) no body between adjacent marker lines (empty inventory must
> contain at least one comment line — e.g., `# (no entries)` — between
> the markers)"

If a maintainer follows the literal advice and inserts `# (no entries)`
between the markers, the resulting input has `regex_matched=True`,
`body_has_content=True`, `entries=[]` — and falls into case (ii)
("block body could not be parsed into inventory entries"). The
maintainer is caught in a loop: case (i)'s advice produces case (ii)'s
error.

**Triage decision (Pack Chat + user-approved):** Option A — drop the
`e.g., # (no entries)` parenthetical and replace with neutral guidance
pointing at the architect doc design intent. The empty-inventory edge
case is genuinely "no Check 41 work to do" → remove the block entirely
per `ARCHITECTURE-BD-176.md` §5.3.

### §1.2 §4.2 NIT — Group 1 vs Group 2 heredoc asymmetry

`scripts/tests/test-validate-pack-check-41.sh` Group 1 (lines ~66-111
pre-fix) used unquoted heredoc `python3 <<EOF` with `$REPO_ROOT` /
`$VALIDATE` shell interpolation. Group 2 (lines ~128-576 pre-fix) used
quoted heredoc `python3 <<'EOF'` with env-var injection. The asymmetry
worked today (Group 1 body had no backticks), but created a footgun: a
future Group 1 assertion containing backticks would trigger bash
command substitution, failing in a way that mimics a real bug.

**Triage decision:** Convert Group 1 to the Group 2 pattern for
consistency.

### §1.3 §4.3 NIT — defensive duplication SKIPPED

Per Pack Chat triage and the reviewer's own no-action recommendation,
no edit to `_parse_client_installed_files` lines 4877-4879. The latent
inconsistency only surfaces if a future maintainer removes the
caller's upfront guard; no defect at HEAD. Not touched.

---

## §2 Implementation

### §2.1 §4.1 Option A — case-(i) `fail()` wording change

**File:symbol:** `scripts/validate-pack.py:check_client_installed_files`
case-(i) `fail()` block (the `if not regex_matched:` branch).

**BEFORE (the FIX-1 wording with the loop):**

```python
fail(
    "scripts/init-project.sh has exactly one "
    "`_CLIENT_INSTALLED_FILES_START` and exactly one "
    "`_CLIENT_INSTALLED_FILES_END` marker, but the block "
    "body could not be captured — the regex pattern "
    "`START\\s*\\n(.+?)\\n[^\\n]*END` did not match. Likely "
    "causes: (a) END marker appears textually before the "
    "START marker, (b) START and END markers on the same "
    "line, (c) no body between adjacent marker lines "
    "(empty inventory must contain at least one comment "
    "line — e.g., `# (no entries)` — between the markers), "
    "(d) unusual whitespace around the markers (e.g., "
    "missing trailing newline after START, or missing "
    "leading newline before END). Restore the canonical "
    "marker shape per ARCHITECTURE-BD-176.md §5.3 / BD-180 "
    "observation G: each marker on its own comment line, "
    "START preceding END, with body content between them."
)
```

**AFTER (the FIX-2 wording without the loop):**

```python
fail(
    "scripts/init-project.sh has exactly one "
    "`_CLIENT_INSTALLED_FILES_START` and exactly one "
    "`_CLIENT_INSTALLED_FILES_END` marker, but the block "
    "body could not be captured — the regex pattern "
    "`START\\s*\\n(.+?)\\n[^\\n]*END` did not match. Likely "
    "causes: (a) END marker appears textually before the "
    "START marker, (b) START and END markers on the same "
    "line, (c) no body between adjacent marker lines "
    "(empty inventory should not need this block at all — "
    "if no files install to clients, remove the entire "
    "block per ARCHITECTURE-BD-176.md §5.3), (d) unusual "
    "whitespace around the markers (e.g., missing trailing "
    "newline after START, or missing leading newline before "
    "END). Restore the canonical marker shape per "
    "ARCHITECTURE-BD-176.md §5.3 / BD-180 observation G: "
    "each marker on its own comment line, START preceding "
    "END, with body content between them."
)
```

**Delta:** Only the `(c)` clause's parenthetical body is replaced. The
diagnostic's structural shape (preamble, regex pattern, four `Likely
causes:` enumeration, canonical-restore guidance) is preserved.

**What changed:**
- REMOVED: "empty inventory must contain at least one comment line —
  e.g., `# (no entries)` — between the markers"
- ADDED: "empty inventory should not need this block at all — if no
  files install to clients, remove the entire block per
  ARCHITECTURE-BD-176.md §5.3"

The new (c) clause:
1. Removes the misleading `# (no entries)` advice that would trip case
   (ii).
2. Points at the architect doc (§5.3 — already referenced once in this
   message, so the maintainer has the anchor already loaded).
3. Acknowledges that "empty inventory" = "no Check 41 work to do"
   (the whole block is removable when no files install to clients —
   genuinely the case the wording loop tripped on).

**Why this is safe for case (i) only:** Case (i) fires when the regex
itself did not match — i.e., either the body is truly empty (zero
characters between markers, since `.+?` requires at least one) OR the
markers are in unusual positions. The (c) clause specifically addresses
the empty-body scenario. The new advice "remove the entire block" is
the correct one because: if a maintainer wanted to keep the block but
ship it empty, the right path is the (c) suggestion or the
`_CHECK_41_EXEMPTIONS` allowlist; removing the markers entirely is the
simpler fix when there's genuinely nothing to inventory.

### §2.2 §4.2 — Group 1 heredoc style consistency

**File:** `scripts/tests/test-validate-pack-check-41.sh` Group 1
(`_parse_client_installed_files` unit tests).

**BEFORE (unquoted heredoc + shell interpolation):**

```bash
printf "\n=== Group 1: _parse_client_installed_files unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
```

**AFTER (quoted heredoc + env-var injection, matching Group 2 pattern):**

```bash
printf "\n=== Group 1: _parse_client_installed_files unit tests ===\n"

# Use a quoted heredoc (`<<'EOF'`) so bash performs ZERO substitution on
# the Python body — matches the Group 2 pattern for consistency and
# defends against a future Group 1 assertion containing backticks
# triggering bash command substitution. Inject REPO_ROOT and VALIDATE
# paths via environment variables that Python reads with os.environ.
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
```

**Delta:** The five mechanical changes from the §4.2 suggested fix
were applied verbatim:
1. `python3 <<EOF` → `REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'`
2. Added `import os` (joined into the existing `import sys` line as
   `import os, sys` to keep import block compact — matches Group 2
   line 129).
3. Added two binding lines: `REPO_ROOT_PY = os.environ['REPO_ROOT']`
   and `VALIDATE_PY = os.environ['VALIDATE']`.
4. `sys.path.insert(0, '$REPO_ROOT/scripts')` → `sys.path.insert(0,
   REPO_ROOT_PY + '/scripts')`.
5. `spec_from_file_location('vp', '$VALIDATE')` → `spec_from_file_location('vp',
   VALIDATE_PY)`.

Comment block above the heredoc cites Group 2's defensive rationale
verbatim ("Use a quoted heredoc... matches the Group 2 pattern for
consistency and defends against...") so future maintainers see the
"why" before encountering the pattern.

Rest of Group 1 body unchanged — the existing failure-list collection,
parser invocation, sanity assertions, and exit-status handling all
work identically because they reference local Python names, not shell
interpolation.

### §2.3 T14 — placeholder-loop regression guard ADDED

**Decision:** T14 ADDED.

**Rationale:** The §4.1 wording fix removes the `# (no entries)` advice
from the case-(i) message, but the underlying parser/caller behavior
(placeholder → case ii) is unchanged. T14 documents this empirical
behavior and serves as a regression guard:

- **Defends against silent Option B drift.** If a future change tries
  to special-case `# (no entries)` in the parser (Option B from the
  reviewer's §4.1 suggested fix), the author would need to also update
  T14's assertions. The test forces the author to confront the
  behavior change explicitly rather than silently changing the parser
  semantics.
- **Documents the historically-recommended placeholder.** Even after
  the wording fix, code-review trails / git-blame / older
  IMPL-REPORTs may reference the original `# (no entries)` placeholder
  advice. T14 documents what that input actually does at HEAD (lands
  in case ii, NOT case iii) so the historical context is preserved
  empirically.
- **Costs little.** T14 is ~40 lines of test harness code, follows the
  exact T7/T7b/T11/T12/T13 pattern, and exercises a synthetic
  fixture path that's already well-supported by the `run_check`
  helper.

T14 placement: between T13 and the failure check (preserves the
ordered-by-failure-mode test layout: T1-T4 PASS / exemption cases,
T5-T6 missing markers, T7/T7b empty-body cases, T8-T10 duplicate
markers, T11 regex-shape-mismatch entry-shape, T12-T13 regex-shape-
mismatch body-capture-position, T14 regex-matched-but-placeholder).

T14 assertions (positive and negative):
- Positive: fail_count >= 1; `"block body could not be parsed into
  inventory entries"` SUBSTRING present (confirms case ii landing).
- Negative: `"block contains no parseable entries"` NOT present
  (confirms NOT case iii); `"block body could not be captured"` NOT
  present (confirms NOT case i).

The `t_pass` summary message updated to reflect T14 inclusion:
`"...T1-T14 including ... T14 FIX-2 placeholder-loop regression guard"`.

---

## §3 Files modified — diff stat + per-file purpose

| File | Lines (added/removed) | Purpose |
|---|---|---|
| `scripts/validate-pack.py` | +9 / -8 | §4.1 Option A: case-(i) `fail()` block wording change (only the `(c)` clause's parenthetical body). |
| `scripts/tests/test-validate-pack-check-41.sh` | +52 / -5 | §4.2: Group 1 heredoc converted to quoted + env-var-injection pattern (+ comment block). T14 added: placeholder-loop regression guard. |

**Total:** 2 files, +61 / -13.

**Zero edits in:**
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` (the
  architect doc the fix references; reading-only).
- `.claude/skills/review/SKILL.md` (the carry-forward skill the prompt
  pointed at for binding; reading-only).
- Any other `validate-pack.py` symbol (especially
  `_parse_client_installed_files` — Option A is wording-only in the
  caller, no parser change).
- Any `project-template/` or `supporting-docs/` file (zero project-side
  edits).
- Any `pack-ops/` prose file.
- Any trinity (CLAUDE.md / AGENTS.md / GEMINI.md) file.

---

## §4 Test coverage

### §4.1 Existing test coverage (T1-T13) — unchanged in behavior

All thirteen pre-fix Group 2 cases pass with identical behavior:

- T1: PASS path (inventory matches cmd_update; sources exist) — PASS
- T2: FAIL path (stale inventory entry) — PASS
- T3: FAIL path (cmd_update drift) — PASS
- T4: PASS-with-exemption — PASS
- T5: FAIL missing START marker (SHOULD-1) — PASS
- T6: FAIL missing END marker (SHOULD-1) — PASS
- T7: FAIL whitespace-only body (case iii, legacy diagnostic) — PASS
- T7b: FAIL truly-empty body (case i, body-capture regex-non-match)
  — PASS. **Note:** T7b's positive assertion still uses
  `"no body between adjacent marker lines"` from the case-(i)
  diagnostic — the FIX-2 wording change KEPT this phrase intact (only
  the parenthetical body of the `(c)` clause changed). Verified
  empirically by full test-suite green run.
- T8-T10: FAIL duplicate START/END/both (SHOULD-1) — PASS
- T11: FAIL regex-shape-mismatch entry-shape (SHOULD-2 case ii) — PASS
- T12: FAIL markers same line (SHOULD-2 case i) — PASS
- T13: FAIL END-before-START (SHOULD-2 case i) — PASS

### §4.2 T14 — new placeholder-loop regression guard

T14 added as documented in §2.3. Input: `# (no entries)` between
markers. Expected behavior: case (ii) ("block body could not be parsed
into inventory entries"). Positive + negative assertions exercise the
three-way disambiguation guard one more time.

T14 PASSED on first run of the test harness post-fix.

---

## §5 Verification

All verification commands returned green; outputs paraphrased + key
lines pasted.

### §5.1 `bash scripts/tests/test-validate-pack-check-41.sh`

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

All 4 test groups PASS — including the new T14 case in Group 2.
Group 1's converted heredoc pattern works identically to its pre-fix
shell-interpolated form (both produce the same `OK` print + zero
failures from the real `init-project.sh` parse).

### §5.2 `python3 scripts/validate-pack.py` at HEAD

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

### §5.3 Adjacent test suites green (regression check)

- `bash scripts/tests/test-validate-pack-check-39.sh`: PASS 6 / FAIL 0
- `bash scripts/tests/test-validate-pack-check-40.sh`: PASS 8 / FAIL 0
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh`: PASS 6 / FAIL 0

No regression in adjacent boundary / cross-reference / install-coverage
gates. The validate-pack.py edit is scoped strictly to one `fail()`
block within `check_client_installed_files`; adjacent checks share no
code with the edited region.

### §5.4 Empirical §4.1 wording-fix verification

Ran a standalone Python probe (`/tmp/vp-check41-fix2-probe.py`, not
committed) that synthesizes the T7b shape (truly-empty body between
markers) against the modified validate-pack.py and asserts:

- `# (no entries)` NOT present in the diagnostic output.
- `"empty inventory should not need this block at all"` PRESENT.
- `"ARCHITECTURE-BD-176.md §5.3"` PRESENT.
- `"block body could not be captured"` PRESENT (case-(i) diagnostic
  still fires for the empty-body regex-non-match shape).

All four assertions PASSED. The probe was a transient verification
artifact (deleted post-run); the durable regression coverage is
T7b (existing) + T14 (new).

### §5.5 Boundary discipline (P-missed-7)

Files modified per `git diff --name-only`:
- `scripts/tests/test-validate-pack-check-41.sh` (pack-internal CI tooling)
- `scripts/validate-pack.py` (pack-internal CI tooling)

Zero `project-template/` edits; zero `supporting-docs/` edits; zero
`pack-ops/` prose edits; zero trinity edits. Both files are
pack-only by construction (not copied to clients by any
`init-project.sh` stage, not referenced by any client-side file).
Per the `boundary-investigation` skill Step 5: project-template/
deny-list not engaged because no project-side file was modified. No
SSOT investigation required.

### §5.6 Manifest verification (RC9)

```
$ bash test-fixtures/build.sh --all --clean
... [6 fixtures rebuilt cleanly] ...
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff test-fixtures/manifest.txt
(empty)
```

See §6 for the RC9 trigger analysis.

---

## §6 RC9 manifest status

**Trigger:** FIRED (`scripts/` touched — `scripts/validate-pack.py` and
`scripts/tests/test-validate-pack-check-41.sh` both under the
4-directory v11-surface trigger).

**Rebuild outcome:** EMPTY DIFF on `test-fixtures/manifest.txt`.

**Why empty diff:** Both edited files are pack-internal CI tooling.
Neither is on the `scripts/init-project.sh` stage S1-S11 client-install
path:

- `scripts/validate-pack.py` is invoked by GitHub Actions and by
  `pack-startup` for local verification; never copied to clients.
- `scripts/tests/test-validate-pack-check-41.sh` is a pack-internal
  test harness; not in any `init-project.sh` stage.

Per the trinity Pack memory `"Regenerate test-fixtures/manifest.txt on
every v11-surface commit"` trailing clause: the trigger correctly
fires inclusively (false positive ~30-90s rebuild cost), the manifest
diff is the canonical authority, and no manifest staging is needed
because the diff is empty.

**Staging plan:** Pack Chat should stage `scripts/validate-pack.py` +
`scripts/tests/test-validate-pack-check-41.sh` only. No manifest
staging needed.

---

## §7 Carry-forward discipline

Applied per `.claude/skills/review/SKILL.md` § "Carry-forward
discipline" (FIX-5 in BD-179 fix-cycle, commit `ff23a00`).

**Zero carry-forwards surfaced.** All scope-adjacent observations
considered during implementation were judged either (a) already
in-scope for this FIX-2 (and handled), (b) in-scope for the BD-180
FIX-1 reviewer's §4.3 NIT which was SKIPPED per triage, or (c) not
defects at HEAD.

### §7.1 Observations considered and judged NOT carry-forwards

1. **T7b's positive assertion uses `"no body between adjacent marker
   lines"`** — this phrase is preserved by the FIX-2 wording change
   (only the parenthetical body of the `(c)` clause changed). T7b
   continues to PASS without modification. NOT a carry-forward; the
   wording change was deliberately surgical to preserve T7b's
   assertion contract.

2. **§4.3 NIT (defensive duplication observation)** — explicitly
   SKIPPED per Pack Chat triage. The reviewer's own recommendation
   was "no action." No carry-forward needed because the finding is
   surfaced and triaged.

3. **Group 0 (lines 34-58) also uses unquoted shell interpolation
   (`$REPO_ROOT`, `$VALIDATE`)** in its `python3 -c "..."` invocation.
   Considered as a potential scope expansion of §4.2 (Group 1
   heredoc consistency). **Rejected as carry-forward because it FAILS
   LOGICAL FIT:** Group 0 uses `python3 -c "..."` (an arg, not a
   heredoc) and shell-interpolates `$REPO_ROOT`/`$VALIDATE` into a
   double-quoted string. The §4.2 finding specifically cites
   "Group 1 vs Group 2 heredoc patterns" — Group 0 is a different
   invocation shape (the C arg, not a heredoc), the body is small
   (~24 lines), and the same backtick-substitution footgun applies
   to ANY shell-quoted Python invocation. If Group 0's pattern is a
   concern, it should be a separate scope decision (likely an
   in-scope follow-up if a future test needs backticks, not a
   speculative refactor today). Surfaced here as transparency, NOT
   as a carry-forward.

4. **The §4.1 fix changes the user-facing diagnostic in a way that
   could also be reflected in the SHOULD-2 disambiguation header
   comment** (lines 4987-5011, the in-code documentation of cases
   i/ii/iii). Considered as a doc-comment touch-up. **Rejected as
   carry-forward because it FAILS SIZE for non-scope expansion:**
   the header comment lines 4987-5011 document the parser/caller
   behavior, which is UNCHANGED by FIX-2. The only thing that
   changed is the wording inside one `fail()` call. The header
   comment's enumeration of (i)/(ii)/(iii) cases still correctly
   describes what the parser/caller do. No doc-comment edit needed.

### §7.2 Forbidden carry-forward shapes self-checked

- "broader pattern without expanding scope"? No — Group 0 observation
  in §7.1.3 explicitly cites file:symbol and concrete evidence; the
  rejection is "different invocation shape," not "out of theme."
- "worth ~N minutes before batch closes"? No.
- forward-looking conjecture ("X is likely to grow")? No.
- design ratification ("this is a feature, not a bug")? No.
- "pack memory recommends fix-now but I'm deferring"? No.

Zero carry-forwards survive the high bar. The two in-scope findings
(§4.1 + §4.2) are both implemented; T14 is added; §4.3 is SKIPPED per
triage. No deferred work.

---

## §8 Plan deviations

**Zero deviations from the prompt.**

- §4.1 Option A applied with the suggested-fix text largely
  verbatim (refined for prose flow per "Reasonable judgment calls
  expected"). The reference to `ARCHITECTURE-BD-176.md §5.3` is
  preserved; the "remove the entire block" remediation is preserved.
- §4.2 applied with all five mechanical changes from the suggested
  fix.
- T14 added (per "Optional test addition (your judgment)" with
  rationale documented in §2.3).
- Zero edits to files outside the two-file scope (`scripts/validate-pack.py`
  + `scripts/tests/test-validate-pack-check-41.sh`).
- No `git add`, `git commit`, or `git push` operations performed (per
  agent contract).

---

## §9 New POQs introduced

**Zero.** This FIX-2 closes two findings from a prior review and adds
one regression-guard test case. No new architectural questions
surfaced. No new BDs needed.

---

## §10 Definition-of-Done checklist

| Item | Status |
|---|---|
| Case-(i) `fail()` block in `check_client_installed_files` no longer references `# (no entries)` as remediation | PASS (verified by §5.4 probe) |
| New wording points at ARCHITECTURE-BD-176.md §5.3 design intent | PASS (substring `"per ARCHITECTURE-BD-176.md §5.3"` present in the `(c)` clause) |
| Group 1 heredoc converted to quoted + env-var-injection pattern matching Group 2 | PASS (verified by file inspection + green test run) |
| All Check 41 test groups still PASS (T1-T13 unchanged in behavior) | PASS (4/4 groups PASS; T1-T13 unchanged; T14 added) |
| `python3 scripts/validate-pack.py` PASSes at HEAD (38 entries × 35 cmd_update, 0 drift) | PASS (§5.2) |
| Adjacent suites unaffected | PASS (§5.3 — Check 39 / Check 40 / Checks 36-37-38 all green) |
| IMPL-REPORT documents both fixes + carry-forward discipline outcome | PASS (this document; §2.1 / §2.2 / §7) |
| Optional T14 add-or-skip decision documented | PASS (§2.3 — T14 ADDED with rationale) |
| RC9 manifest rebuild empty diff confirmed | PASS (§5.6 / §6) |
| Zero `project-template/` / `supporting-docs/` / `pack-ops/` / trinity edits | PASS (§5.5) |
| Zero edits to non-scope `validate-pack.py` symbols (especially `_parse_client_installed_files`) | PASS (only the case-(i) `fail()` block in `check_client_installed_files` modified) |
| Zero edits to `ARCHITECTURE-BD-176.md` or `.claude/skills/review/SKILL.md` | PASS (read-only context, not modified) |
| No `git add` / `git commit` / `git push` operations | PASS (HEAD unchanged at `093c503`) |
| PREFLIGHT line emitted in final assistant message after IMPL-REPORT Write | PASS (emitted post-Write below) |

All DoD items PASS.

---

## §11 Files-changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (+9 / -8) |
| `scripts/tests/test-validate-pack-check-41.sh` | modified (+52 / -5) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-2.md` | new (this file) |

Three files total. Zero deletions. Zero renames.

---

## §12 Summary

BD-180 FIX-2 implements both bundled findings from
PACK-REVIEW-BD-180-FIX-1.md:

- **§4.1 SHOULD (Option A):** case-(i) `fail()` block wording in
  `check_client_installed_files` no longer recommends `# (no entries)`;
  new wording points at ARCHITECTURE-BD-176.md §5.3 with the "remove
  the entire block" remediation that actually fixes the problem.
- **§4.2 NIT:** Group 1 in `test-validate-pack-check-41.sh` converted
  to the quoted-heredoc + env-var-injection pattern matching Group 2;
  comment block above the heredoc cites Group 2's defensive rationale
  for future maintainers.
- **§4.3 NIT:** SKIPPED per Pack Chat triage (reviewer's own no-action
  recommendation honored).
- **T14:** ADDED — placeholder-loop regression guard documenting that
  `# (no entries)` between markers lands in case (ii), not case (iii).
  Defends against silent Option B drift if a future change tries to
  special-case the placeholder.

All verifications green: 4/4 Check 41 test groups PASS (T1-T14);
validate-pack.py exits 0 with Check 41 reporting clean (38 entries /
0 drift); adjacent test suites (Check 39 / Check 40 / Checks 36-37-38)
all green; manifest rebuild produces empty diff (correct per RC9
trailing-clause for pack-internal-only changes).

Zero project-side edits. Zero plan deviations. Zero new POQs. Zero
carry-forwards. Two minutely-scoped pack-internal CI tooling edits +
one regression-guard test case + this IMPL-REPORT.

Pack Chat to read this report, stage `scripts/validate-pack.py` +
`scripts/tests/test-validate-pack-check-41.sh` (no manifest staging
needed per §6), and commit with user approval per BD-175 elevated-care
protocol.

PREFLIGHT line follows in the assistant's final message per
`feedback_pack_coder_preflight_pattern`.
