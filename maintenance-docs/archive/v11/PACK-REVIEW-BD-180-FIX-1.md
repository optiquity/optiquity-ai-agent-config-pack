# PACK-REVIEW-BD-180-FIX-1.md

Per-commit review report for the BD-180 FIX-1 fix-coder commit closing
PACK-REVIEW-BD-180 SHOULD-1 (docstring/impl contract drift on marker
uniqueness) + SHOULD-2 (silent regex non-match collapse). Part of the
BD-175 emergency batch elevated-care protocol — per-BD review/fix runs
inline before the next BD's coder spawns.

- **Commit under review:** `093c503bc82b53444717793147c424b981c21beb`
  ("fix: v11 — BD-180 SHOULD-1/2 _parse_client_installed_files hardening")
- **Compared against:** `04f150e54fe954c4482c648ed6df5e5ac857b73b`
  (pre-fix HEAD; the BD-180 per-commit review commit)
- **Reviewer agent:** `pack-reviewer` (sequential, in-place against
  parent worktree)
- **Date:** 2026-05-20
- **Diff stat:** 3 files changed, +941 / -46 (per `git show --stat`):
  - `scripts/validate-pack.py` (+189 / -16)
  - `scripts/tests/test-validate-pack-check-41.sh` (+318 / -30)
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-1.md` (+480 / -0; new)
- **Files NOT touched (correctly):** zero `project-template/` edits,
  zero `supporting-docs/` edits, zero `pack-ops/` prose edits, zero
  trinity edits. Pack-internal CI tooling + docs only.

---

## §1 Verdict

**APPROVE-WITH-FIXES.**

The fix substantively closes both SHOULD findings:

- **SHOULD-1 closure:** the parser now enforces exactly-once on both
  `_CLIENT_INSTALLED_FILES_START` and `_END` markers via integer-count
  short-circuit; the docstring at `_parse_client_installed_files`
  explicitly documents the exactly-once contract; the caller emits
  distinct missing-marker (`count == 0`) vs duplicate-marker
  (`count > 1`) diagnostics with the actual found-count surfaced; the
  Check 41 header docstring (`scripts/validate-pack.py` line 208) already
  promised "exactly once" so no header docstring edit was needed — the
  implementation now matches the long-documented contract.

- **SHOULD-2 closure:** three-way disambiguation is correctly
  implemented per the IMPL-REPORT §2.2 decision tree. Path (i) regex
  non-match, path (ii) regex-matched + body-has-content + zero-entries,
  and path (iii) regex-matched + whitespace-only body are mutually
  exclusive and exhaustive at the caller. Path (iii) preserves the
  legacy `"no parseable entries"` diagnostic verbatim so any prior
  documentation referencing that string still parses.

- **Internal API evolution:** `_parse_client_installed_files` signature
  3-tuple → 5-tuple is correctly absorbed by the sole caller
  `check_client_installed_files`; no other call-site in pack or tests
  was missed (verified by grep — only the parser, the caller, and the
  test harness Group 1 reference the symbol).

- **Test coverage:** the test harness extends from 7 to 13 cases (T1-T13).
  T5/T6/T7 are strengthened with new diagnostic-string assertions;
  T7b/T8/T9/T10/T11/T12/T13 are new. Each FAIL case asserts a specific
  diagnostic substring (not just non-zero failure count). T7b/T11/T12/T13
  also assert NEGATIVE — the legacy "no parseable entries" string does
  NOT trip on the new disambiguation paths.

- **CI green:** validate-pack.py exit 0 at HEAD with Check 41 reporting
  `38 entries / 0 drift`; all 4 test groups pass; adjacent test suites
  (Check 39, Check 40, Checks 36-37-38) all green; manifest rebuild
  produces empty diff (correct — neither edited file is on the
  client-install path).

Verdict not REJECT because the fix correctly closes both reviewer
findings. Verdict not pure APPROVE because there is one SHOULD-level
finding (§4.1) — an internal inconsistency in error-message wording
where case (i)'s remediation advice (`add a "# (no entries)"
comment line`) would, if followed, deterministically trip case (ii)
("block body could not be parsed into inventory entries"). This is a
diagnostic-quality defect introduced by the FIX-1 wording choices,
not a behavioral regression.

---

## §2 Severity breakdown

| Severity | Count |
|---|---|
| BLOCKER | 0 |
| MUST | 0 |
| SHOULD | 1 |
| NIT | 2 |

---

## §3 Original PACK-REVIEW-BD-180 finding closure table

| Finding | Severity (orig) | Coder action | Reviewer verdict |
|---|---|---|---|
| **SHOULD-1** (docstring/impl drift on marker uniqueness) | SHOULD | Implementation tightened to enforce exactly-once via integer counts; parser returns `(start_count, end_count)`; caller emits distinct missing-vs-duplicate diagnostics with found-count; parser docstring rewritten to document the exactly-once contract. Header docstring at `scripts/validate-pack.py` `(a) START + END markers each appear exactly once` confirmed already correct (no edit). | **Closed cleanly.** Trace at `_parse_client_installed_files` lines 4883-4888: `start_count = text.count(...)`; short-circuit `if start_count != 1 or end_count != 1`. Caller at lines 4952-4985 emits the missing-vs-duplicate-vs-composite diagnostics correctly. Tests T5/T6 (missing) + T8/T9 (duplicate) + T10 (both duplicated) cover all four marker-count violation shapes. |
| **SHOULD-2** (silent regex non-match collapse) | SHOULD | Three-way disambiguation implemented via new flags `regex_matched` + `body_has_content`. Case (i) body-capture failure surfaces explicit regex-pattern + 4 likely-cause guidance. Case (ii) entry-shape failure surfaces explicit entry-format + 4 likely-cause guidance. Case (iii) preserves legacy `"no parseable entries"` message verbatim. | **Closed cleanly** (with one minor wording issue in case (i) — see §4.1). Trace at `check_client_installed_files` lines 5012-5060: three-way `if not entries: if not regex_matched ... elif body_has_content ... else (legacy)`. Tests T7 (legacy), T7b/T12/T13 (case i), T11 (case ii) cover all three paths plus the non-trip assertions. |
| **NIT-1** (commit subject length) | NIT | Coder accepted reviewer's no-action recommendation per IMPL-REPORT §1 header. The new commit subject is `fix: v11 — BD-180 SHOULD-1/2 _parse_client_installed_files hardening` — **68 characters**, under the 70-char guideline. NIT effectively resolved by writing a shorter subject for the fix commit. | **Closed cleanly** (incidental). Verified via `printf '%s' '...' | wc -m` → 68. |

All three original findings closed cleanly.

---

## §4 New findings (introduced by FIX-1 or surfaced during review)

### §4.1 SHOULD-1: Case (i) error message recommends a remediation that deterministically triggers case (ii)

- **Severity:** SHOULD
- **File:symbol:** `scripts/validate-pack.py:check_client_installed_files`
  (case-(i) `fail()` block — the body-capture-regex-non-match diagnostic)
- **Problem:** The case (i) error message at the
  `if not regex_matched:` branch advises the maintainer to fix a truly-empty
  body by adding `"# (no entries)"`:

  > "(c) no body between adjacent marker lines (empty inventory must
  > contain at least one comment line — e.g., `# (no entries)` —
  > between the markers)"

  However, if the maintainer follows this advice literally, the
  resulting input — `_CLIENT_INSTALLED_FILES_START\n# (no entries)\n_CLIENT_INSTALLED_FILES_END`
  — has `regex_matched=True` (the `.+?` captures the comment line),
  `body_has_content=True` (the comment is a non-whitespace-only line),
  and `entries=[]` (no `->` separator). This lands in path (ii),
  producing the entry-shape error: `"block body could not be parsed
  into inventory entries — the body has content lines but no line
  matches the expected entry shape."` The maintainer is now caught
  in a wording loop: case (i)'s advice produced case (ii)'s error.

  Verified empirically by running `check_client_installed_files` against
  a synthetic init-project.sh containing exactly the recommended pattern:

  ```
  FAIL: scripts/init-project.sh has `_CLIENT_INSTALLED_FILES_START`/
  `_END` markers and the block body was captured by the regex, but
  the block body could not be parsed into inventory entries — the
  body has content lines but no line matches the expected entry shape.
  ```

  The defect is purely in error-message wording — the parser behavior
  is correct (an empty inventory genuinely has no consumers today; if
  a future maintainer DOES need to ship an empty inventory, the
  `_CHECK_41_EXEMPTIONS`/"check exits 0 with 0 entries" path is the
  right one). But the user-facing remediation advice is internally
  inconsistent.

- **Suggested fix:** Two equally valid options; coder picks. Option A
  is the minimal-diff path; Option B is the more correct path:

  **Option A — remove the misleading example from case (i).** Drop the
  `"e.g., `# (no entries)` — between the markers"` parenthetical from
  the case (i) error message and replace with neutral wording like:
  `"empty inventory should not need this block at all — if no files
  install to clients, remove the entire block per ARCHITECTURE-BD-176.md
  §5.3"`. This avoids the wording loop without expanding parser semantics.

  **Option B — treat `"# (no entries)"` specially in the parser.** Add a
  parser branch that recognizes a `"# (no entries)"`-style placeholder
  comment as a legitimate empty-inventory marker and produces
  `entries=[], body_has_content=False` (so the caller falls into case
  (iii) and produces the preserved legacy diagnostic). This honors the
  case (i) advice but requires extending parser semantics and adding a
  T14 test case for the placeholder pattern.

  Either path requires one wording change in
  `check_client_installed_files` case (i) `fail()` call; Option B
  additionally requires a one-line check in `_parse_client_installed_files`
  before the entry-loop.

- **Rationale:** A self-debugging integrity gate's error messages are
  themselves a contract with the maintainer. When the remediation
  advice in one branch deterministically lands the maintainer in
  another branch's failure mode, the gate's value as a self-debugging
  surface degrades. The pack memory pattern `"surface-over-silently-
  fail"` cited in the FIX-1 IMPL-REPORT §1.1 (and the file-header
  comment for `_CHECK_*_EXEMPTIONS`) applies symmetrically to error-
  message guidance: surface remediation that actually fixes the
  problem, not remediation that re-triggers the gate. Per the review
  skill `correctness` priority and the IMPL-REPORT §2.2 "specific +
  actionable" wording goal.

### §4.2 NIT-1: Asymmetric heredoc-quoting style between Group 1 and Group 2

- **Severity:** NIT
- **File:symbol:** `scripts/tests/test-validate-pack-check-41.sh`
  Group 1 (lines 66-111, `python3 <<EOF`) vs Group 2 (lines 128-576,
  `python3 <<'EOF'` with env-var injection)
- **Problem:** Group 1 uses an unquoted heredoc with `$REPO_ROOT`/`$VALIDATE`
  interpolation; Group 2 uses a quoted heredoc with the same paths
  injected via environment variables. The IMPL-REPORT §4.4 rationale
  explains the Group 2 switch (backtick-containing assertion strings
  would trigger bash command substitution under unquoted heredoc), but
  the Group 1 body has no backticks in assertion strings today —
  hence the asymmetry. The asymmetry works functionally but creates a
  footgun for future maintainers: if someone adds a backtick-containing
  assertion to Group 1 (e.g., to assert the parser's docstring contains
  a `regex_matched` flag), the test will break in a way that mimics
  a real bug (failed `command not found` substitution).
- **Suggested fix:** Convert Group 1 to the same quoted-heredoc +
  env-var-injection pattern as Group 2 for consistency. The diff is
  ~5 lines (change `<<EOF` to `<<'EOF'`, prefix with
  `REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE"`, change `'$REPO_ROOT/scripts'`
  to `os.environ['REPO_ROOT'] + '/scripts'`, similar for `VALIDATE`).
  No behavior change; reduces the footgun surface.
- **Rationale:** Pack-coder maintenance is mechanical by default
  (trinity Pack memory § "Skill and agent maintenance is mechanical
  by default"). When two adjacent groups of the same test harness use
  different patterns for the same purpose, future mechanical
  maintenance has to context-switch. NIT, not SHOULD, because the
  current Group 1 body genuinely has no backticks and the test
  passes today; surfacing for proactive footgun reduction.

### §4.3 NIT-2: `_parse_client_installed_files` re-checks `init_sh.is_file()` that the caller already guarded

- **Severity:** NIT
- **File:symbol:** `scripts/validate-pack.py:_parse_client_installed_files`
  lines 4877-4879 (`if not init_sh.is_file(): return ([], 0, 0, False, False)`)
- **Problem:** `check_client_installed_files` at line 4938-4941 already
  guards `if not init_sh.is_file(): ok("...skipping..."); return`. The
  parser then re-checks the same condition and returns the absence
  default. This is defensive coding (the parser can be called from
  the test harness Group 1 independently of the caller's guard), so
  the duplication is functionally correct. But the parser's `(0, 0,
  False, False)` absence return would now confusingly land in the
  caller's SHOULD-1 "missing markers" branch if the caller ever
  forgot the upfront guard — producing the wrong diagnostic for a
  missing-file scenario. Since the test harness Group 1 always calls
  the parser against the real `scripts/init-project.sh` (which exists),
  this latent inconsistency is unreached today.
- **Suggested fix:** No action. The current shape is correct (parser is
  defensive against missing file; caller guards explicitly). Surfacing
  only because the absence-default tuple `(0, 0, False, False)` is
  shape-identical to the SHOULD-1 short-circuit and a future caller
  refactor could land in the wrong branch. If a future maintainer
  removes the caller's upfront guard (e.g., to centralize the
  absence-handling in the parser), they should be aware of this.
  Not a defect at HEAD.
- **Rationale:** Forward-looking observation about API shape, not a
  defect. NIT per review skill — surfaced as transparency, not action.

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

Exit code: 0. All 41 distinct check stages clean. Check 41 behavior at
HEAD is functionally identical to pre-FIX-1 (`38 entries / 0 drift`)
— the new exactly-once enforcement and three-way disambiguation are
backwards-compatible for the real production file shape, which is what
we want.

### §5.2 `bash scripts/tests/test-validate-pack-check-41.sh`

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

All 4 test groups (with 13 synthetic sub-cases in Group 2) PASS.
Specific diagnostic-string assertions for SHOULD-1 (T5/T6/T8/T9/T10)
and SHOULD-2 (T7/T7b/T11/T12/T13) all exercised.

### §5.3 Adjacent test suites green

- `bash scripts/tests/test-validate-pack-check-39.sh`: PASS 6 / FAIL 0
- `bash scripts/tests/test-validate-pack-check-40.sh`: PASS 8 / FAIL 0
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh`: PASS 6 / FAIL 0

No regression in adjacent boundary/cross-reference/install-coverage
gates. The validate-pack.py edits are scoped strictly to the Check 41
symbols (`_parse_client_installed_files` + `check_client_installed_files`);
adjacent checks share no code with the edited region.

### §5.4 RC9 manifest verification

```
$ bash test-fixtures/build.sh --all --clean
... [6 fixtures rebuilt cleanly] ...
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff test-fixtures/manifest.txt
(empty)
```

Manifest diff is empty as the IMPL-REPORT §6 predicted. The rebuild
trigger fired correctly (`scripts/` touched per RC9 directory-wide
trigger) but neither `scripts/validate-pack.py` nor
`scripts/tests/test-validate-pack-check-41.sh` is on the
`scripts/init-project.sh` stage S1-S11 client-install path, so no
fixture SHA drifted. Per the trinity Pack memory `"Regenerate
test-fixtures/manifest.txt on every v11-surface commit"` trailing-
clause: trigger fired correctly (false positive ~30-90s rebuild cost,
no incorrect manifest change), no staging needed.

### §5.5 Edge-case probe for case-(i) advice loop

To verify §4.1 SHOULD-1, I ran an independent Python harness simulating
a maintainer following the case (i) `"# (no entries)"` advice. Result:
the input lands in case (ii) ("block body could not be parsed into
inventory entries"), confirming the internal inconsistency. Probe
script result captured in the §4.1 finding above.

### §5.6 Boundary discipline (P-missed-7)

```
$ git diff --name-only 04f150e..093c503
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-1.md
scripts/tests/test-validate-pack-check-41.sh
scripts/validate-pack.py
```

Zero `project-template/` edits; zero `supporting-docs/` edits; zero
`pack-ops/` prose edits; zero trinity edits. All changes are
pack-internal: `scripts/` (pack-only by construction; CI tooling and
test harness, neither copied to clients), `maintenance-docs/`
(pack-only by construction). Per the `boundary-investigation` skill
Step 5: project-template/ deny-list not engaged because no project-
side file was modified. No SSOT investigation required.

### §5.7 Caller adaptation correctness — 5-tuple unpack

The only caller `check_client_installed_files` (line 4943) unpacks
all 5 returned elements as:

```python
entries, start_count, end_count, regex_matched, body_has_content = (
    _parse_client_installed_files()
)
```

Each element is used:
- `start_count` + `end_count` → SHOULD-1 marker-uniqueness short-circuit
  (lines 4952-4985)
- `regex_matched` + `body_has_content` → SHOULD-2 three-way
  disambiguation (lines 5012-5060)
- `entries` → SHOULD-2 disambiguation guard (`if not entries:`) AND
  the (c) source-file-existence and (d) cmd_update-cross-check loops
  (lines 5062-5111)

No unused element, no element used in wrong path. Test harness Group 1
also unpacks all 5 elements and asserts against `start_count`,
`end_count`, `regex_matched`, `body_has_content`, and `entries`
independently.

### §5.8 Backward-compat — legacy "no parseable entries" string

`grep -rn "no parseable entries\|block contains no parseable entries"`
across the pack repo:

- `scripts/validate-pack.py:5055` — the preserved case-(iii) message
- 5 test-harness lines asserting positive (T7) or negative (T11/T12/T13)
  on the legacy string
- 4 IMPL-REPORT references documenting the preservation

No CI workflow, no documentation, no other surface pattern-matches the
legacy string outside the test harness itself. Backward-compat
preserved for the consumer surface; case (iii) emits the legacy
message verbatim per T7's positive assertion.

### §5.9 Commit subject length

```
$ printf '%s' 'fix: v11 — BD-180 SHOULD-1/2 _parse_client_installed_files hardening' | wc -m
      68
```

Under the 70-character soft guideline (CLAUDE.md commit-format
section). Improvement over the 72-character predecessor that surfaced
the original NIT-1.

---

## §6 Carry-forward observations

**Carry-forward discipline applied per `.claude/skills/review/SKILL.md`
§ "Carry-forward discipline" (FIX-5 in BD-179 fix-cycle, commit
`ff23a00`). I am the 3rd reviewer bound by this discipline.**

**Zero carry-forwards surfaced.** All three findings in §4 are surfaced
as in-scope (SHOULD or NIT) for Pack Chat default-fix-all triage. None
are deferred to a future BD, batch, or end-of-batch reviewer.

### §6.1 Findings considered for carry-forward and rejected

1. **§4.1 case-(i) wording loop** — considered as "could be deferred to
   a documentation polish cycle." **FAILS all three high-bar tests:**
   - SIZE: ~5-15 line wording change in one function; not architect-pass
     material.
   - BLOCKED: no dependency on any not-yet-landed artifact; the parser
     and caller exist at HEAD.
   - LOGICAL-FIT: the defect is in the SAME symbol the FIX-1 commit
     edited (`check_client_installed_files` case-(i) `fail()`); there
     is no future sibling BD this naturally belongs with — the
     deferral would just be "later." Surfaced as SHOULD per
     default-fix-all.

2. **§4.2 Group-1-vs-Group-2 heredoc asymmetry** — considered as "could
   be deferred to a test-harness consistency pass." **FAILS all three
   tests:**
   - SIZE: ~5-line mechanical change to one heredoc.
   - BLOCKED: no dependency.
   - LOGICAL-FIT: same file the FIX-1 commit edited; same harness as
     Group 2's defensive heredoc change. Surfaced as NIT per
     default-fix-all (NIT default is also FIX per the discipline).

3. **§4.3 absence-default tuple shape latent inconsistency** —
   considered as "forward-looking observation about a future caller
   refactor risk." **FAILS LOGICAL-FIT and is forward-looking
   conjecture** (the discipline explicitly forbids "X is likely to
   grow" / "this could drift" framings unless it represents a current
   defect with concrete evidence). The current shape is correct;
   surfacing only as transparency, NOT as a deferred finding.
   Classified as NIT with "no action" recommendation, NOT carry-forward.

### §6.2 Considered but not surfaced as findings

The following observations were considered during review and judged
to be NOT defects at HEAD — neither in-scope findings nor
carry-forwards:

1. **Parser docstring's "Each entry line must be of the form `[stage:...]`"
   is more strict than what the parser actually validates** (the parser
   only requires the left-of-`->` token, not the stage tag). This is
   intentional documentation of the canonical form (not a regex contract)
   — the parser is permissive on the right side by design (e.g., to
   tolerate `[stage:S6,cmd_update]` and `[stage:S11]` variants without
   needing a re-validation regex). Not a defect; the parser docstring is
   a usage guide, not a contract assertion. NOT surfaced.

2. **`_CHECK_41_EXEMPTIONS` is empty at HEAD with no worked example.**
   Same as IMPL-REPORT §7 observation 2; coder considered and rejected.
   Reviewer concurs: FAILS SIZE for in-scope finding (one-line change),
   not a defect at HEAD. NOT surfaced.

3. **Adjacent parsers in `validate-pack.py` for marker-uniqueness drift.**
   Same as IMPL-REPORT §7 observation 3; coder spot-checked and found
   no analogous defect surface. Reviewer concurs: spot-checked
   `_parse_cmd_update_entries` (Check 39), `_parse_skill_frontmatter`,
   `_parse_codex_toml` — none use marker-based body extraction with
   the same risk profile. "Broader pattern" framing is forbidden by
   the discipline. NOT surfaced.

### §6.3 Forbidden carry-forward shapes self-checked

- "broader pattern without expanding scope"? No — §4.1, §4.2, §4.3
  each cite specific file:symbol and concrete evidence; no "this is a
  broader pattern" framing.
- "worth ~N minutes before batch closes"? No.
- forward-looking conjecture ("X is likely to grow", "this could
  drift")? §4.3 acknowledges a latent inconsistency but explicitly
  classifies "no action" rather than deferring — present-tense
  observation about current shape, not "could drift" prediction.
- design ratification ("this is a feature, not a bug")? No.
- "pack memory recommends fix-now but I'm deferring"? No — all three
  findings are surfaced fix-now.

Zero carry-forwards survive the high bar. The three findings in §4 are
all in-scope for Pack Chat's default-fix-all triage; the rejected
candidates in §6.1 are documented as rejected, not deferred.

---

## §7 What the implementation got right

Acknowledgments per review skill principle "A review that only lists
problems is incomplete":

- **Mechanical contract closure.** SHOULD-1 closed by enforcing the
  long-documented `(a) exactly-once` contract at the implementation
  level; the implementation now matches the header docstring. SHOULD-2
  closed by replacing the silent collapse with a discriminated-union-
  style 5-tuple return that lets the caller emit the right diagnostic
  for each cause. Mechanical fidelity to the reviewer's recommended fix
  shape.

- **Single coordinated edit.** Both findings live in the same symbol
  pair (parser + sole caller); a single commit with a coordinated
  signature evolution + caller adaptation is the simpler-correct
  approach vs two separate commits that would each touch the same
  symbols. Bundling rationale documented in IMPL-REPORT §1 header.

- **Multi-violation message folding.** The marker-uniqueness diagnostic
  joins multiple violations with `"; "` so a maintainer who duplicates
  both START and END (T10 case) sees both errors in one pass instead
  of the "fix one, re-run, find another" iteration pain. Good error-
  message ergonomics.

- **Specific + actionable error messages.** Each new diagnostic names
  the marker (`_CLIENT_INSTALLED_FILES_START` / `_END`), the found
  count, the expected count, and the canonical reference
  (`ARCHITECTURE-BD-176.md §5.3 / BD-180 observation G`). Case (i)
  + (ii) enumerate four likely causes each. Specificity matches the
  pack memory pattern `"surface-over-silently-fail"`.

- **Heredoc quoting defensive change.** Group 2's switch to
  `<<'EOF'` + env-var injection eliminates the backtick-command-
  substitution footgun for future maintainers adding assertion strings
  with backticks. The defensive change is documented inline at lines
  123-127. (Asymmetry with Group 1 is the §4.2 NIT.)

- **Test coverage symmetry with finding shape.** Six new test cases
  (T7b, T8, T9, T10, T11, T12, T13) cover all SHOULD-1 + SHOULD-2
  failure shapes plus the negative-assertion guards (legacy string
  must NOT trip on new paths). Three strengthened test cases (T5, T6,
  T7) gain new diagnostic-string assertions. Test coverage matches
  finding coverage one-to-one.

- **Boundary discipline.** Zero project-side edits; the fix is pure
  pack-internal CI tooling improvement. No pack-only-into-project-side
  regression risk.

- **Carry-forward discipline in the IMPL-REPORT.** Coder's §7
  explicitly rejected three plausible-but-borderline deferral
  candidates with SIZE / BLOCKED / LOGICAL-FIT reasoning. Reviewer
  concurred with all three rejections.

- **Backward-compat preservation.** Case (iii) preserves the legacy
  `"no parseable entries"` message verbatim — a defensive choice in
  case any external surface (CI grep, documentation reference, monitor
  script) pattern-matched the string. Verified by grep that no
  external surface does today, but the preservation is forward-looking
  insurance.

- **Manifest hygiene.** RC9 trigger fired correctly per the trinity
  Pack memory inclusive-trigger rule; rebuild produced empty diff
  (correct, since neither edited file is on the client-install path);
  no staging required.

- **Subject length improvement.** The fix commit subject is 68
  characters (under the 70-char guideline), an improvement over the
  72-character predecessor that originally surfaced NIT-1. The NIT-1
  acceptance ("no action") in the IMPL-REPORT was honored without
  introducing a new length regression.

---

## §8 Summary

BD-180 FIX-1 commit `093c503` is **APPROVE-WITH-FIXES.**

- Both SHOULD-1 and SHOULD-2 findings from PACK-REVIEW-BD-180.md
  closed cleanly.
- Internal API evolution (3-tuple → 5-tuple) correctly absorbed by
  the sole caller; no missed call-sites.
- 13 test cases pass, including new SHOULD-1 (T5/T6/T8/T9/T10) and
  SHOULD-2 (T7/T7b/T11/T12/T13) coverage with specific diagnostic
  assertions.
- All adjacent test suites green (Check 39 / 40 / 36-37-38).
- Manifest clean (empty diff after `--all --clean` rebuild).
- Boundary discipline satisfied (zero project-side edits).
- Commit subject 68 chars (under guideline).
- Carry-forward discipline applied; zero deferrals; rejected
  candidates documented in §6.1.

One new SHOULD finding (§4.1: case-(i) error message recommends
`"# (no entries)"` which deterministically trips case (ii)). Two NITs
(§4.2: Group-1-vs-Group-2 heredoc asymmetry; §4.3: latent absence-
default tuple shape inconsistency). All three are in-scope for Pack
Chat's default-fix-all triage; none are carry-forwards.

Pack Chat to triage the SHOULD and two NITs per default-fix-all and
proceed (per BD-175 elevated-care: the per-commit reviewer is the
last gate before the next commit's coder spawns).
