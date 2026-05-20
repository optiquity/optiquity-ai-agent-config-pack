# PACK-REVIEW-BD-175-F2A.md

Reviewer: pack-reviewer (background spawn, file-disjoint with T1 per-commit)
Branch: `v11-dev`
HEAD at review time: `b5221ee2b4ff2f652a9f883c2dfe051b811123bb`
Commit reviewed: `bee710c6a4e3d08268d299a0f0415fdbd8353630`
Date: 2026-05-19

## §1 Verdict

**APPROVE WITH NITS.** Check 39 is implemented correctly, exercises the
documented PASS / FAIL / exemption paths via a clean 5-group test fixture,
PASSes at HEAD with 6/6 `project-template/docs/pack/*.md` files mapped (0
exemptions), and leaves persona contracts green
(greenfield 191/0, mid-dev 25/0, migration 37/0). Scope is disciplined (7
files, no trinity, no `init-project.sh` install-logic edits), the 4
out-of-scope asymmetries are correctly flagged in IMPL-REPORT §6 and
forwarded to BD-180 rather than silently fixed, and the manifest is
correctly unchanged per RC9 inclusive trigger. Findings are NIT-grade —
two minor numeric discrepancies between IMPL-REPORT and the actual diff,
plus one SHOULD-grade observation that Check 39 only verifies one
direction of symmetry (file-on-disk → mapping-exists) and misses a stale
`cmd_update` entry for the retired `PROMPT-TEMPLATES.md`. None of these
are ship-stoppers; the stale-entry observation is naturally absorbed by
BD-180 if Pack Chat wants to extend Check 39's scope.

## §2 Independent findings (per review-scope item)

### Scope 1 — Check 39 implementation correctness

**Pass.** `_parse_cmd_update_entries()` (validate-pack.py:4199-4234) uses
a regex `r"local\s+entries=\(\s*\n(.+?)\n\s*\)\s*\n"` against the
init-project.sh file text with `re.DOTALL`. The regex is narrow and
intentional — anchored on `local entries=(`, non-greedy across newlines,
requires the closing `)` on its own line. This matches the canonical bash
array shape at scripts/init-project.sh:1108-1133.

Per-line parsing:
- Strips whitespace.
- Skips blank lines and lines starting with `#` (correct comment skip).
- Extracts the quote-delimited content via index slicing
  (`line[1:line.index('"', 1)]`), then takes the first colon-separated
  field via `split(":", 1)[0]`.

`check_cmd_update_symmetry()` (validate-pack.py:4237-4309) iterates
`project-template/docs/pack/*.md` in sorted order, computes the expected
`pack_rel` form (`project-template/docs/pack/{name}`), checks against
the entries set, falls back to the `_CHECK_39_EXEMPTIONS` allowlist, and
emits a FAIL with an actionable, well-formed recommendation when neither
matches. Failure message includes:
- the missing `pack_rel`,
- the file/line anchor for the S6 glob loop (`init-project.sh:544` —
  verified accurate),
- the exact entry-array form to add (with the canonical `:generic` class),
- the exemption-allowlist escape hatch with a rationale-comment
  requirement.

Defensive failure paths: (a) `init-project.sh` absent → lenient SKIP;
(b) `project-template/docs/pack/` absent → lenient SKIP;
(c) entries-array unparseable / empty → defensive FAIL with the
parse-failure message. The defensive-FAIL contract is correct and prevents
silent PASS-by-vacuity.

### Scope 2 — `_CHECK_39_EXEMPTIONS` allowlist

**Pass.** The allowlist is a `dict[str, str]` mapping basename → rationale
string (validate-pack.py:4192-4196), default empty. The header docstring
(validate-pack.py:4188-4191) explicitly codifies "Surface over
silently-exempt: when in doubt, leave OUT of the allowlist and let
Check 39 FAIL — Pack Chat triage can decide per-file. Each entry MUST
include a one-line rationale comment." This is the correct default
posture per the prompt's design instruction. The mechanism is exercised
by Group 2 T3 (synthetic) and is functionally equivalent to the
existing Check 38 exemption mechanism (different but parallel
implementation — Check 38 uses a 1-line file, Check 39 uses an in-source
dict; both styles exist in the codebase).

### Scope 3 — Test fixture coverage

**Pass with NIT.** The test script
`scripts/tests/test-validate-pack-check-39.sh` is 359 lines (NIT: the
IMPL-REPORT §2 and commit message both say "282 lines" — actual is 359;
minor count drift, no functional impact). The script has 5 test groups
exercising all required paths:

- **Group 0** — module-import + symbol-registration sanity (catches
  rename / move regressions on `check_cmd_update_symmetry`,
  `_parse_cmd_update_entries`, `_CHECK_39_EXEMPTIONS`).
- **Group 1** — `_parse_cmd_update_entries()` against the LIVE
  `scripts/init-project.sh`. Asserts a required-subset of 9 known
  entries are parsed (6 docs/pack + 3 trinity), entry count is in a
  15-50 sanity range, no comment-lines parsed as entries.
- **Group 2** — 5 synthetic in-tmpdir scenarios that swap
  `mod.REPO_ROOT` and exercise: T1 PASS (all entries present), T2 FAIL
  (missing mapping; verifies BAZ.md named + cmd_update referenced in
  failure), T3 PASS-with-exemption (rationale string emitted), T4
  empty docs/pack (vacuous PASS), T5 comment-only entries body
  (defensive FAIL). Coverage of the 4 prompt-required paths
  (PASS / FAIL-missing / FAIL-malformed / PASS-with-exemption) is
  complete.
- **Group 3** — static fixture sanity. Asserts the 4 fixture files
  exist and are parseable; checks that the PASS fragment yields ≥3
  entries and the FAIL fragment yields strictly fewer than the PASS
  fragment.
- **Group 4** — end-to-end exit-status of `validate-pack.py`. Asserts
  exit-0 AND Check 39 header line emitted AND Check 39 summary line
  emitted.

Static fixtures (4 files in
`scripts/tests/fixtures/cmd-update-symmetry/`):
- `README.md` (46 lines) — documents the fixture-set purpose, mirrors
  the `scripts/tests/fixtures/boundary-checks/` README pattern.
- `init-fragment-pass.sh` (17 lines) — 3 mapping entries, all
  matching docs/pack files.
- `init-fragment-fail-missing.sh` (15 lines) — 2 entries (omits
  BAZ.md vs PASS fragment).
- `init-fragment-fail-malformed.sh` (19 lines) — comment-only entries
  body (parser-degradation case).

All 4 fixtures have inline docstring headers explaining purpose and
expected behavior. The README explicitly explains why static fixtures
exist in addition to tmpdir generation (documentation anchor + regression
scaffolding + out-of-band diagnosis).

### Scope 4 — Check 39 PASSes at HEAD

**Pass (independently verified).** Ran `python3 scripts/validate-pack.py`
from HEAD `b5221ee`; entire script exits 0; Check 39 emits:

```
── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.
```

Matches the coder's claim exactly (6/6, 0 exemptions). Verified `ls
project-template/docs/pack/*.md` returns 6 files (HELP-FRAGMENT,
HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS,
PM-CHAT — same 6 in coder's report). Verified `_parse_cmd_update_entries()`
returns 24 entries against live init-project.sh.

### Scope 5 — Test script PASSes

**Pass (independently verified).** Ran
`bash scripts/tests/test-validate-pack-check-39.sh`; output:
```
=== Summary ===
  PASS: 5
  FAIL: 0
All tests passed.
```
5/5 PASS matches the coder's claim. Also ran the regression test
`bash scripts/tests/test-validate-pack-checks-36-37-38.sh`: 6/6 PASS
(no regression on neighboring checks).

### Scope 6 — Persona contracts still GREEN

**Pass (independently verified).** Ran
`bash scripts/test-persona-contracts.sh`; output ends with:
```
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
Persona contract summary: 3/3 passed
All persona contracts PASS.
```
Counts match the coder's claim (191/0, 25/0, 37/0). Expected because
Check 39 is pure read-only validation; no install behavior is altered.

### Scope 7 — Manifest correctly unchanged

**Pass.** `git show bee710c --stat` shows ONLY 7 files modified/added,
none of which is `test-fixtures/manifest.txt`. The coder's IMPL-REPORT
§2 documents that they ran `bash test-fixtures/build.sh --all --clean`
post-edit and the manifest diff was empty (which is the correct RC9
inclusive-trigger behavior — `validate-pack.py` is a pack-internal CI
tool that doesn't change what `init-project.sh` installs, so v11-*
fixture SHAs do not drift). The coder honored RC9 ("run the rebuild")
and correctly did NOT stage manifest (no diff to stage).

### Scope 8 — Scope discipline

**Pass.** Exactly 7 files in commit:
1. `scripts/validate-pack.py` (modified, +154 lines)
2. `scripts/tests/test-validate-pack-check-39.sh` (new, 359 lines)
3. `scripts/tests/fixtures/cmd-update-symmetry/README.md` (new, 46 lines)
4. `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-pass.sh` (new, 17 lines)
5. `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-missing.sh` (new, 15 lines)
6. `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-malformed.sh` (new, 19 lines)
7. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F2A.md` (new, 432 lines)

No trinity edits, no edits to `scripts/init-project.sh` install logic
(verified via `git show bee710c --stat | grep -E "init-project"` —
empty), no edits to other validate-pack.py checks. The only edits to
`validate-pack.py` are: (a) Check 39 implementation block at L4179-4309,
(b) header docstring entry at L179-195 (the Check 39 numbered description
in the top-of-file comment), (c) one `main()` registration call at L4371
with surrounding comment block at L4368-4370. Surgical, in-scope only.

### Scope 9 — 4 out-of-scope observations correctly flagged + NOT applied

**Pass.** IMPL-REPORT §6 documents all 4 observations:
- **A** — `.gemini/commands/pm-startup.toml` never installed (S4/S6/S11
  none + cmd_update none).
- **B** — `.claude/skills/pm-startup/SKILL.md` and
  `.codex/skills/pm-startup/SKILL.md` in S4 but not cmd_update.
- **C** — `.claude/settings.local.example.json` in neither path
  (probably intentional but needs verification).
- **D** — per-entry skeleton templates in S11 but not cmd_update.

Each entry includes "Suggested triage" language and is explicitly NOT
applied in this commit. Confirmed in `pack-ops/BACKLOG.md` lines
1533-1562 that BD-180 was opened (Status: Open, blocked on BD-175 +
BD-176 + BD-177 + BD-178 + BD-179) with all 4 observations (A/B/C/D)
captured 1:1 in BD-180's Description block. The 4 observations were
NOT silently fixed; the fold-into-BD-180 path is correctly executed.

### Scope 10 — No POQ-3-N regressions / narrow scope documented

**Pass.** IMPL-REPORT §3 "Why narrow scope (docs/pack/*.md only)"
explicitly justifies the narrow scope decision with reference to (a)
the empirical BD-175 Commit 10 failure (OPTIONAL-FEATURES.md), (b)
the S4 canonical-pool-distribution pattern that makes broader scope
produce false positives without first resolving the BD-180 asymmetries,
(c) the future-extension hook in IMPL-REPORT §6 "Recommendation for
Check 39 future extensions". The narrow-scope decision is intentional,
documented, and routed to BD-180 for broader expansion later.

## §3 Compare-to-IMPL-REPORT

After forming the independent assessment above I read
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F2A.md`.
Material agreement on all 10 scope items. Two minor numeric
discrepancies between the IMPL-REPORT and the actual diff:

1. IMPL-REPORT §2 says `scripts/tests/test-validate-pack-check-39.sh`
   is 282 lines; actual is 359 lines (`wc -l` and `git show --stat`).
   The commit-message body also repeats the 282 figure. This is a
   NIT — minor count drift, no functional impact.
2. IMPL-REPORT §2 says `scripts/validate-pack.py` added 145 lines;
   actual is +154 lines (`git show --stat`). Same NIT class.

Both numbers appear to be earlier-in-process counts the coder didn't
refresh before writing the IMPL-REPORT. Neither affects correctness.

IMPL-REPORT §7 Verification command output is faithful (I re-ran every
command listed there and got matching output). The PREFLIGHT line in
§8 is well-formed and the Definition-of-Done checklist in §"Definition-of-Done
checklist" honestly reflects the work.

## §4 Severity-classified findings table

| ID | Severity | Area | Finding | Recommendation |
|---|---|---|---|---|
| F2A-N1 | NIT | IMPL-REPORT consistency | IMPL-REPORT §2 + commit message claim `test-validate-pack-check-39.sh` is 282 lines; actual is 359. | Optional follow-up: update IMPL-REPORT numbers to match `wc -l`. Pure documentation cosmetic. |
| F2A-N2 | NIT | IMPL-REPORT consistency | IMPL-REPORT §2 claims `scripts/validate-pack.py` added ~145 lines; actual is +154 per `git show --stat`. | Same as F2A-N1 — refresh numbers. |
| F2A-S1 | SHOULD | Check 39 scope (one-direction) | Check 39 verifies (file-on-disk → cmd_update mapping exists) but NOT the inverse (cmd_update mapping → file-on-disk exists). The `cmd_update` `entries=()` array at scripts/init-project.sh:1122 maps `project-template/docs/pack/PROMPT-TEMPLATES.md:docs/pack/PROMPT-TEMPLATES.md:generic`, but the file was retired in v10.0 — verified via `ls project-template/docs/pack/PROMPT-TEMPLATES.md` (file not found) and `grep "PROMPT-TEMPLATES" project-template/docs/pack/PM-CHAT.md` (PM-CHAT.md L149-150 confirms retirement). The stale entry causes `pack update` to silently `[[ -f "$theirs" ]] || theirs=""` and proceed without surfacing the dead mapping, which is a different operational drift than Check 39 was designed to catch but lives in the same surface. | Fold into BD-180 scope as a 5th observation, OR extend Check 39's logic to also walk `cmd_update` entries and FAIL any entry whose `pack_rel` resolves to a missing file. BD-180's existing Description already mentions "extending Check 39's scope" as an option (line 1556), so this is a natural fit. Pack Chat may want to add an explicit fifth bullet to BD-180's Description capturing the inverse-direction check. |

No BLOCKER, no MUST. Findings F2A-N1 and F2A-N2 are documentation
cosmetics. Finding F2A-S1 is a SHOULD that BD-180 naturally absorbs.

## §5 Verification commands run + outputs

All commands run from repo root at HEAD `b5221ee`.

```
$ git rev-parse HEAD
b5221ee2b4ff2f652a9f883c2dfe051b811123bb

$ git show bee710c --stat | tail -10
 .../IMPLEMENTATION-REPORT-BD-175-F2A.md            | 432 +++++++++++++++++++++
 .../tests/fixtures/cmd-update-symmetry/README.md   |  46 +++
 .../init-fragment-fail-malformed.sh                |  19 +
 .../init-fragment-fail-missing.sh                  |  15 +
 .../cmd-update-symmetry/init-fragment-pass.sh      |  17 +
 scripts/tests/test-validate-pack-check-39.sh       | 359 +++++++++++++++++
 scripts/validate-pack.py                           | 154 ++++++++
 7 files changed, 1042 insertions(+)

$ python3 scripts/validate-pack.py 2>&1 | tail -5
── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean

$ bash scripts/tests/test-validate-pack-check-39.sh 2>&1 | tail -8
=== Summary ===
  PASS: 5
  FAIL: 0

All tests passed.

$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>&1 | tail -5
=== Summary ===
  PASS: 6
  FAIL: 0
All tests passed.

$ bash scripts/test-persona-contracts.sh 2>&1 | grep -E "^=== (greenfield|mid-dev|migration) contract:"
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===

$ python3 -c "
import sys, importlib.util
spec = importlib.util.spec_from_file_location('vp', 'scripts/validate-pack.py')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
e = mod._parse_cmd_update_entries()
print('entries count:', len(e))
print('PROMPT-TEMPLATES present:', any('PROMPT-TEMPLATES' in x for x in e))
"
entries count: 24
PROMPT-TEMPLATES present: True

$ ls project-template/docs/pack/PROMPT-TEMPLATES.md 2>&1
ls: project-template/docs/pack/PROMPT-TEMPLATES.md: No such file or directory

$ ls project-template/docs/pack/*.md | wc -l
       6
```

All commands match the IMPL-REPORT's verification claims. The
PROMPT-TEMPLATES.md probe is the new diagnostic for finding F2A-S1.

## §6 Out-of-scope observations (worth logging, not actionable for F2a)

### Observation O1 — Inverse-direction (mapping → file) gap

Already classified as F2A-S1 SHOULD above. The `cmd_update` entries
array contains a stale mapping for `project-template/docs/pack/PROMPT-TEMPLATES.md`
that has been retired since v10.0 (confirmed via PM-CHAT.md:149-150 in
docs/pack/). At runtime the cmd_update loop guards via
`[[ -f "$theirs" ]] || theirs=""` and the customization-preserve library
records this as an "absent-on-both-sides" finding (per BD-088 truthful-
report contract), so the operational impact is benign noise rather than
data loss. But it IS a stale entry and Check 39's current scope does not
surface it. Natural fit for BD-180's extension scope.

### Observation O2 — Line-number references in Check 39 messages

The Check 39 FAIL recommendation message refers to
`scripts/init-project.sh ~L1108-L1133` (validate-pack.py:4294) and
`scripts/init-project.sh:544` (validate-pack.py:4291). These are
line-numbered references in error output — line numbers drift naturally
with file edits. The pack-memory rule about line-number-references is
phrased for docstrings/IMPL-REPORTs and architect docs, not user-facing
error messages where line anchors are operationally helpful. Both
references happen to be accurate at HEAD (verified) and the `~` prefix
on L1108-L1133 already signals approximate. Not a finding; logged
because future Check 39 maintainers may want to consider replacing the
exact line numbers with function-name anchors (`cmd_update` /
`stage_s6_docs_pack`) for drift-resistance.

### Observation O3 — Check 39 dedupes by basename, mapping uses full path

In `check_cmd_update_symmetry()` at validate-pack.py:4282, the
exemption-allowlist lookup uses `md.name` (basename only — e.g.,
`PROMPT-TEMPLATES.md`). The implication is two files with the same
basename in different `project-template/docs/pack/` paths would share
an exemption. Today this is a non-issue (the directory is flat — no
subdirectories), and adding nested directories under
`project-template/docs/pack/` would be a larger architectural decision.
Logged for symmetry awareness; no action.

### Observation O4 — Group 1 T2 entries-count sanity range

The Group 1 test asserts entries count in [15, 50]. Current is 24.
The upper bound is generous (room for growth). The lower bound (15)
is approximate to the current 24 and would catch a regression that
removes many entries. Reasonable range; no change recommended.

---

**End of review.** Approve with NITs. The SHOULD-grade finding
(F2A-S1, stale `PROMPT-TEMPLATES.md` mapping not caught by current
Check 39 scope) is a natural fold-in to BD-180's existing "extend
Check 39's scope" hook (BACKLOG line 1556) and does not block this
commit.
