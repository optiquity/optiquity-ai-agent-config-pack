# IMPLEMENTATION-REPORT-BD-180-FIX-1.md

Fix-coder implementation report for BD-180 PACK-REVIEW SHOULD-1 +
SHOULD-2 (bundled fix scope; same symbol). Part of the BD-175 emergency
batch; landed in the per-BD review/fix cycle per pack-memory
"Per-BD review/fix runs INLINE, before next BD's coder spawns."

- **BD:** BD-180 (cmd_update mapping symmetry across remaining surfaces)
- **Fix scope:** SHOULD-1 (exactly-once marker enforcement) +
  SHOULD-2 (regex-shape-mismatch vs empty-inventory disambiguation)
- **Bundled rationale:** both findings live in the same symbol
  (`scripts/validate-pack.py:_parse_client_installed_files` and its
  caller `check_client_installed_files`); a single coordinated edit
  produces consistent error-message wording and parser-output
  contract.
- **HEAD pre-fix:** `04f150e54fe954c4482c648ed6df5e5ac857b73b`
- **HEAD post-fix:** `04f150e54fe954c4482c648ed6df5e5ac857b73b`
  (agents never commit — staging + commit is Pack Chat's step)
- **Branch:** `v11-dev`
- **NIT-1 disposition:** accepted as-is per reviewer's no-action
  recommendation (commit subject 72 chars; substance trumps strict
  length per §4.3 of the review). Not addressed in this FIX-1
  cycle.

---

## §1 Problem restatement (from PACK-REVIEW-BD-180.md §4.1 + §4.2)

### §1.1 SHOULD-1 — Docstring/implementation contract drift

**File:symbol:** `scripts/validate-pack.py:_parse_client_installed_files`
(parser) and the Check 41 header docstring entry.

The Check 41 header docstring at `scripts/validate-pack.py` promises:
`"(a) START + END markers each appear exactly once"`. The parser at
`_parse_client_installed_files` enforced only `text.count(start_marker)
>= 1` and `text.count(end_marker) >= 1` ("at least once"). A future
maintainer accidentally introducing a duplicate `_CLIENT_INSTALLED_FILES_START`
or `_END` marker (e.g., by copy-pasting the inventory block during a
refactor) would have been silently accepted: the non-greedy regex
would match the first START + first END pair and the validator would
PASS despite the contract violation.

**Choice:** impl-tightens-to-match-docstring (defensive over permissive)
per the calling prompt's explicit direction. Surface-over-silently-fail
matches the design philosophy stated in the file header for the
`_CHECK_*_EXEMPTIONS` allowlists ("surface-over-silently-exempt").

### §1.2 SHOULD-2 — Silent regex non-match collapse

**File:symbol:** `scripts/validate-pack.py:_parse_client_installed_files`.

When the regex body-extraction path triggers a non-match (e.g.,
out-of-order markers, single-line markers, unusual whitespace), the
parser collapsed into empty-entries silently. The subsequent failure
message ("no parseable entries") was misleading because the actual
cause was regex shape mismatch, not empty inventory.

**Decision tree per prompt:**
- markers exist + body has content + regex extraction returns zero
  entries → regex-shape-mismatch error
- markers exist + body is truly empty → preserved legacy "no parseable
  entries" message

---

## §2 Implementation

### §2.1 SHOULD-1 — Exactly-once marker enforcement

**Symbol:** `_parse_client_installed_files`

**Change.** The function signature evolved from
`tuple[list[str], bool, bool]` returning `(entries, start_seen, end_seen)`
to `tuple[list[str], int, int, bool, bool]` returning
`(entries, start_count, end_count, regex_matched, body_has_content)`.

The integer counts let the caller emit specific
`"expected exactly one ..., found N"` diagnostics rather than the
previous binary "seen / not seen" signal. The boolean `regex_matched`
and `body_has_content` flags drive the SHOULD-2 three-way
disambiguation (see §2.2).

**Caller (`check_client_installed_files`) change.** The marker-check
short-circuit now enforces `start_count != 1 or end_count != 1` and
emits distinct diagnostics:

- `start_count == 0`: `"missing _CLIENT_INSTALLED_FILES_START marker
  in scripts/init-project.sh (found 0; expected exactly 1)"`
- `start_count > 1`: `"duplicate _CLIENT_INSTALLED_FILES_START marker
  in scripts/init-project.sh (found N; expected exactly 1)"`
- Symmetric pair for END marker.
- Multiple violations join with `"; "` to surface all errors in one
  pass (avoids the "fix one, re-run, find another" iteration pain).

The composite message frames the contract: `"self-documenting list
marker contract violated: ... The block must be delimited by exactly
one _CLIENT_INSTALLED_FILES_START marker and exactly one
_CLIENT_INSTALLED_FILES_END marker per ARCHITECTURE-BD-176.md §5.3 /
BD-180 observation G. Remove any duplicate markers or add the missing
marker(s)."`

**Docstring update.** The `_parse_client_installed_files` docstring now
explicitly documents the exactly-once contract:

> Exactly-once contract: both markers MUST appear exactly once each.
> The header docstring for Check 41 promises (a) START + END markers
> each appear exactly once; this function enforces that contract by
> returning the raw counts so the caller can emit specific
> "expected exactly one ..., found N" failure messages and the
> validator FAILs rather than silently swallowing duplicate markers
> (the failure mode the exactly-once contract is meant to catch).

The Check 41 inline-comment header (lines ~4798-4823) already
documented the (a)/(b)/(c)/(d) contract correctly — no edit needed
there; the implementation now matches the long-documented contract.

### §2.2 SHOULD-2 — Regex-shape-mismatch vs empty-inventory disambiguation

**Symbol:** `_parse_client_installed_files` + `check_client_installed_files`

**Three-case disambiguation per parser-output triple `(regex_matched,
body_has_content, entries)`:**

| Case | `regex_matched` | `body_has_content` | `entries` | Diagnostic |
|---|---|---|---|---|
| (i) Body-capture regex-shape-mismatch | False | False | `[]` | New: "block body could not be captured — the regex pattern `START\\s*\\n(.+?)\\n[^\\n]*END` did not match" + likely-cause guidance (END-before-START / same-line / no-body / unusual-whitespace) |
| (ii) Entry-shape regex-shape-mismatch | True | True | `[]` | New: "block body could not be parsed into inventory entries — the body has content lines but no line matches the expected entry shape" + likely-cause guidance (missing `->`, missing `#`, malformed whitespace, non-inventory content) |
| (iii) Genuinely empty inventory | True | False | `[]` | Legacy: "block contains no parseable entries" (preserved pre-BD-180 message) |

**Decision-tree rationale.** Case (i) covers structural marker
ill-formedness — the block doesn't look like a START-body-END
sandwich at all. Case (ii) covers a structurally-valid block whose
content doesn't match the entry-line shape (the most likely future
foot-gun for a maintainer manually editing the inventory). Case (iii)
covers the legitimate "empty inventory" case from the consumer's view
(body is whitespace-only); preserves the pre-BD-180 diagnostic shape
so existing tests and documentation references remain valid.

**`body_has_content` semantics.** True iff regex matched AND body
contains at least one non-empty, non-whitespace-only line:
`any(line.strip() for line in body.splitlines())`. Implemented as a
parser-output flag so the caller decision-tree stays a flat
if-cascade.

**Error-message wording.** Per the prompt's "specific + actionable"
direction:

- Case (i): names the regex pattern verbatim, enumerates four likely
  causes with concrete examples, and points at the canonical
  marker-shape reference (`ARCHITECTURE-BD-176.md §5.3`).
- Case (ii): names the entry-line format verbatim, enumerates four
  likely causes, and points at the same canonical reference.
- Case (iii): preserved verbatim from pre-BD-180 to avoid breaking
  any external documentation that quoted the legacy message.

---

## §3 Files modified

| File | Lines | Purpose |
|---|---|---|
| `scripts/validate-pack.py` | +173 / -16 | `_parse_client_installed_files` signature evolved to 5-tuple; docstring rewritten to document the exactly-once contract and the three-case disambiguation; `check_client_installed_files` caller updated with new marker-check (SHOULD-1) and three-way empty-entries disambiguation (SHOULD-2) |
| `scripts/tests/test-validate-pack-check-41.sh` | +288 / -30 | Group 1 tuple-unpack updated to 5-tuple with new flag assertions; Group 2 `run_check` helper extended with optional `raw_init_sh` override (for marker-uniqueness and regex-shape-mismatch fixtures); 6 new test cases added (T7b, T8, T9, T10, T11, T12, T13) covering SHOULD-1 and SHOULD-2; existing T5/T6/T7 strengthened with new diagnostic-string assertions; heredoc switched to quoted form (`<<'EOF'`) to allow backtick-containing diagnostic strings in assertion failures; REPO_ROOT/VALIDATE injected via env vars |

`git diff --stat` summary:

```
 scripts/tests/test-validate-pack-check-41.sh | 318 +++++++++++++++++++++++++--
 scripts/validate-pack.py                     | 189 +++++++++++++---
 2 files changed, 461 insertions(+), 46 deletions(-)
```

---

## §4 Test coverage additions

All new and updated tests live in `scripts/tests/test-validate-pack-check-41.sh`
Group 2 (synthetic init-project.sh PASS/FAIL).

### §4.1 SHOULD-1 coverage

| Test | Fixture shape | Expected behavior | Asserted diagnostic strings |
|---|---|---|---|
| T1 (preserved, regression) | 1 START + 1 END + 2 entries, all sources extant | PASS (0 failures) | "consistent with copy-site state" |
| T5 (strengthened) | 0 START + 1 END | FAIL | "missing `_CLIENT_INSTALLED_FILES_START` marker"; "found 0"; "expected exactly 1" |
| T6 (strengthened) | 1 START + 0 END | FAIL | "missing `_CLIENT_INSTALLED_FILES_END` marker"; "found 0"; "expected exactly 1" |
| T8 (new) | 2 START + 1 END (duplicate START) | FAIL | "duplicate `_CLIENT_INSTALLED_FILES_START` marker"; "found 2"; "expected exactly 1" |
| T9 (new) | 1 START + 2 END (duplicate END) | FAIL | "duplicate `_CLIENT_INSTALLED_FILES_END` marker"; "found 2"; "expected exactly 1" |
| T10 (new) | 2 START + 2 END (both duplicated) | FAIL | Both duplicate-START and duplicate-END diagnostics in same message |

### §4.2 SHOULD-2 coverage

| Test | Fixture shape | Expected behavior | Asserted diagnostic strings |
|---|---|---|---|
| T7 (rewritten) | 1 START + 1 END + whitespace-only body (single line of 3 spaces) | FAIL with LEGACY message | "no parseable entries" (preserved); NOT "block body could not be captured"; NOT "could not be parsed into inventory entries" |
| T7b (new) | 1 START + 1 END + truly-empty body (blank line between adjacent marker lines) | FAIL with NEW body-capture message | "block body could not be captured"; "no body between adjacent marker lines" |
| T11 (new) | 1 START + 1 END + garbage between (non-comment shell content + comment-without-`->`) | FAIL with NEW entry-shape message | "block body could not be parsed into inventory entries"; NOT "block contains no parseable entries" |
| T12 (new) | START and END on the same line | FAIL with NEW body-capture message | "block body could not be captured"; "START and END markers on the same line"; NOT "block contains no parseable entries" |
| T13 (new) | END marker textually before START marker | FAIL with NEW body-capture message | "block body could not be captured"; "END marker appears textually before the START marker"; NOT "block contains no parseable entries" |

### §4.3 Group 2 helper extension

`run_check` gained a new keyword argument `raw_init_sh: str = None`.
When non-None, this overrides the canonical scaffold entirely and
writes the provided text verbatim to `scripts/init-project.sh`. The
canonical scaffold (used by T1-T4) generates a 1-START + 1-END
inventory by construction, which would make it impossible to test
marker-uniqueness violations and regex-shape-mismatch failure modes
where the marker structure itself is under test. The new override is
the minimal-surface evolution needed to exercise T7b/T8-T13.

### §4.4 Heredoc rationale

The Group 2 Python body switched from unquoted `<<EOF` to quoted
`<<'EOF'` with `REPO_ROOT` and `VALIDATE` paths injected via
environment variables (`REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE"
python3 <<'EOF'`). This was forced by the new assertion strings
containing backticks (e.g., `if "missing
\`_CLIENT_INSTALLED_FILES_START\` marker" not in captured:`) — under
the unquoted heredoc, bash interprets backticks as command
substitution. The quoted heredoc disables all bash substitution on
the body, eliminating that footgun for future maintainers.

### §4.5 Group 1 update

Group 1 (real `scripts/init-project.sh` parser tests) tuple-unpack
updated from 3-tuple to 5-tuple. New assertions verify
`start_count == 1`, `end_count == 1`, `regex_matched is True`, and
`body_has_content is True` against the real production file. The
existing canonical-path spot-check and `>= 20 entries` sanity check
are preserved.

---

## §5 Verification

### §5.1 `bash scripts/tests/test-validate-pack-check-41.sh`

```
=== Group 0: Module import + Check 41 symbol registration ===
  PASS validate-pack.py imports + Check 41 symbols registered

=== Group 1: _parse_client_installed_files unit tests ===
OK
  PASS _parse_client_installed_files parses real init-project.sh correctly

=== Group 2: Synthetic init-project.sh PASS/FAIL tests ===
OK
  PASS Synthetic PASS/FAIL tests (T1-T13 including T7/T7b SHOULD-2 disambiguation and T8-T10 SHOULD-1 duplicate-marker)

=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0; Check 41 runs and reports clean

=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

All 4 test groups (containing 13 synthetic Group 2 sub-cases) PASS.

### §5.2 `python3 scripts/validate-pack.py` at HEAD

Exit code: **0**. Final Check 41 line:

```
── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked;
  38 resolve to existing files at HEAD, 0 on exemption allowlist.
  35 cmd_update path(s) cross-checked against inventory; 0 drift(s)
  (must be 0). Self-documenting list is consistent with copy-site state.
```

Matches the pre-fix Check 41 baseline exactly (38 entries / 0 drift)
— the new exactly-once enforcement and three-way disambiguation are
backwards-compatible for the real production file shape.

Validator final line: `PASSED — all checks clean`.

### §5.3 Specific new test cases (per-fixture pass evidence)

All 6 new test cases (T7b, T8, T9, T10, T11, T12, T13) and 3
strengthened test cases (T5, T6, T7) verified PASS via the Group 2
PASS line above. No assertion in the `failures` list survived the
Python run (`print("OK")` line emitted before `sys.exit(1)` guard).
Specific assertion strings exercised per §4.1 + §4.2 tables above.

### §5.4 Adjacent test suites still green

```
bash scripts/tests/test-validate-pack-check-39.sh: PASS 6 / FAIL 0
bash scripts/tests/test-validate-pack-check-40.sh: PASS 8 / FAIL 0
bash scripts/tests/test-validate-pack-checks-36-37-38.sh: PASS 6 / FAIL 0
```

No regression introduced in Check 36 / 37 / 38 / 39 / 40 test
harnesses by the validate-pack.py edits (which were scoped strictly
to the Check 41 symbol).

### §5.5 Python syntax sanity

```
python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read()); print('AST OK')"
AST OK
```

---

## §6 RC9 manifest status

**Trigger:** fired (commit will touch `scripts/`).

**Rebuild command:** `bash test-fixtures/build.sh --all --clean`

**Result:** rebuild completed; all six fixture rows rebuilt
deterministically (v10-minimal, v10-realistic-ot, v11-realistic-ot,
v11-flat-file, v11-tracker-on, existing-project-mid-dev).

**`git diff test-fixtures/manifest.txt`:** empty.

**Interpretation per RC9 trailing-clause.** `scripts/validate-pack.py`
and `scripts/tests/test-validate-pack-check-41.sh` are both
pack-internal (not on the client-install path per the
`scripts/init-project.sh` stages S1-S11; `validate-pack.py` is a CI
script never copied to clients; the test script is a pack-developer
harness never copied to clients). The trigger fired correctly (per
the "directory-wide trigger defends against future copy-site
additions" rationale in the trinity Pack memory), the rebuild
produced empty diff (correct — no client-installed file changed), and
no staging of `test-fixtures/manifest.txt` is required.

---

## §7 Carry-forward discipline

**Applied per `.claude/skills/review/SKILL.md` § "Carry-forward
discipline" SIZE / BLOCKED / LOGICAL-FIT high-bar.**

**Zero carry-forwards surfaced.**

**Scope-adjacent observations considered during implementation:**

1. **Could the regex itself be hardened to reject duplicate markers
   instead of relying on the marker-count check?** Considered. The
   current `START\s*\n(.+?)\n[^\n]*END` regex is non-greedy, so it
   matches the FIRST START + FIRST END pair regardless of duplicates.
   Tightening the regex (e.g., using `(?!.*START)` look-aheads) would
   make the pattern complex and brittle. The marker-count short-circuit
   is the simpler-correct mechanism and is now in place. NOT a defect
   at HEAD; not surfaced as carry-forward. FAILS SIZE (no
   architect-pass material); FAILS LOGICAL-FIT (the marker-count
   check IS the equivalent enforcement at the symbol level).

2. **Should `_CHECK_41_EXEMPTIONS` allowlist gain a docstring example
   showing how to add an entry?** Considered. The existing in-line
   comment ("Add entries here only when the inventory references a
   path that intentionally does not exist at HEAD") is sufficient
   pointer for first-use. Adding a worked example would be helpful
   pedagogically but FAILS SIZE (one comment line is not architect-pass
   material; could be added as a NIT in a future broad-batch cycle if
   pattern shows up). Not surfaced as in-scope finding either — out
   of scope for the SHOULD-1 + SHOULD-2 bundle.

3. **Adjacent parsers in `validate-pack.py` that might have similar
   docstring/implementation contract drift?** Considered.
   `_parse_cmd_update_entries` (Check 39 parser) has a simpler
   contract (no marker uniqueness — it walks a `local entries=(...)`
   array unconditionally) and does not have the analogous failure
   mode. Spot-checked `_parse_*` symbols (`_parse_skill_frontmatter`,
   `_parse_codex_toml`, etc.) — none use marker-based body extraction
   with the same exactly-once + body-shape risk profile.
   No analogous defect surface; no broader-pattern carry-forward
   warranted (would be a "broader pattern" framing — explicitly
   forbidden by the discipline).

**Forbidden carry-forward shapes self-checked against my own output:**

- Have I framed any deferred work as "broader pattern" without
  expanding scope of an in-scope finding? No — the three observations
  above are explicitly rejected as carry-forward candidates, not
  surfaced as deferred work.
- Have I introduced forward-looking conjecture ("X is likely to
  grow", "this could drift")? No.
- Have I ratified design as "intentional tradeoff" while deferring?
  No.
- Have I claimed "pack memory recommends fix-now" while deferring? No.

The two SHOULD findings in scope are FIXED in this cycle; no work
deferred.

---

## §8 Boundary discipline check (P-missed-7)

**Project-side surface touched:** zero. All changes are pack-internal
(`scripts/validate-pack.py` is a CI tooling script; `scripts/tests/`
is the pack-developer test harness — neither is copied to clients via
`scripts/init-project.sh`).

`git diff --name-only` (scoped to this fix):

```
scripts/tests/test-validate-pack-check-41.sh
scripts/validate-pack.py
```

No `project-template/` edits; no `supporting-docs/` edits; no `pack-ops/`
prose edits; no trinity edits. Per the `boundary-investigation` skill
Step 5, the project-template/ deny-list is not engaged because no
project-side file was modified. No SSOT investigation required.

---

## §9 Definition-of-Done checklist

| Item | Status |
|---|---|
| SHOULD-1: exactly-once marker enforcement implemented | PASS |
| SHOULD-1: docstring updated to match new behavior | PASS |
| SHOULD-1: specific "expected exactly one ..., found N" error wording | PASS |
| SHOULD-2: regex-shape-mismatch vs empty-inventory disambiguation | PASS |
| SHOULD-2: distinct error messages for body-capture vs entry-shape vs whitespace-only | PASS |
| New tests for both findings added | PASS (T7b, T8-T13; T5/T6/T7 strengthened) |
| All existing test groups still PASS (Check 41) | PASS (4/4) |
| `python3 scripts/validate-pack.py` PASSes at HEAD | PASS (exit 0; 38 entries / 0 drift) |
| Adjacent test suites still green (Checks 36-37-38, 39, 40) | PASS |
| Python AST parses cleanly | PASS |
| RC9 manifest rebuild produces empty diff (pack-internal-only) | PASS |
| Carry-forward discipline applied; zero deferrals | PASS |
| Boundary discipline check: zero project-side edits | PASS |
| Files-touched outside scope: none | PASS (only `scripts/validate-pack.py` + `scripts/tests/test-validate-pack-check-41.sh`) |
| No `git add` / `git commit` / `git push` run | PASS |
| IMPL-REPORT written to specified path | PASS |
| PREFLIGHT line emitted as last message | (emitted after IMPL-REPORT Write completes) |

---

## §10 Files changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-validate-pack-check-41.sh` | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-1.md` | new |

No deletions. No new fixture files (synthetic fixtures embedded
in-test via heredocs per the calling prompt's "Synthetic fixtures
preferred (in-test heredocs; don't pollute `scripts/tests/fixtures/`)"
direction).

---

## §11 Plan deviations

**Zero deviations from the calling prompt.** The prompt allowed
"reasonable judgment calls" on error-message wording, regex-shape-
mismatch vs empty-inventory boundary, and test-case structure — all
exercised per §2 + §4.

One mid-implementation refactor: the parser signature evolved twice
(3-tuple → 4-tuple `regex_matched` → 5-tuple
`(regex_matched, body_has_content)`) as the three-way disambiguation
emerged from working through the test cases. The 5-tuple final
shape is documented in the parser docstring and the test harness
unpacks it correctly. No behavioral surprise to the caller; only
the test harness's Group 1 needed the unpack update.

---

## §12 New POQs introduced

None.

---

PREFLIGHT: 2/2 in-scope file edits complete; verification PASS;
HEAD 04f150e54fe954c4482c648ed6df5e5ac857b73b; about to Write
IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-1.md
