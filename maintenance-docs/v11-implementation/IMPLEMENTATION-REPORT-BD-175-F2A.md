# IMPLEMENTATION-REPORT-BD-175-F2A.md

Coder report for **BD-175 F2a** — `scripts/validate-pack.py` **Check 39**
(`cmd_update` mapping/glob symmetry gate).

- Branch: `v11-dev`
- HEAD: `88a0aea1f086266460f6966500ffff175297176e`
- Coder agent: pack-coder (background spawn, file-disjoint with F1 reviewer)
- Date: 2026-05-19

## §1 Summary

Implemented **Check 39** in `scripts/validate-pack.py` to programmatically
gate `cmd_update` mapping/glob symmetry in `scripts/init-project.sh`. The
check parses the `cmd_update` `entries=()` array via regex and verifies
that every file under the S6 fresh-install glob target
`project-template/docs/pack/*.md` has a corresponding explicit
`cmd_update` mapping entry. Files intentionally absent from `cmd_update`
can be added to a `_CHECK_39_EXEMPTIONS` allowlist with rationale
(default: empty — surface-over-silently-exempt).

The check FAILs with an actionable recommendation when a docs/pack/*.md
file lacks both a `cmd_update` mapping AND an exemption — the BD-175
Commit 10 failure mode the F4 bundle reviewer prevention-design feed-in
#2 called out (asymmetric coverage between fresh-install S6 glob and
`pack update` explicit mappings).

**HEAD state:** Check 39 PASSes cleanly with 6/6 files in
`project-template/docs/pack/*.md` having explicit mappings (HELP-FRAGMENT,
HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS,
PM-CHAT). 0 exemptions needed.

## §2 Files changed

| File | Type | Lines added | Notes |
|---|---|---|---|
| `scripts/validate-pack.py` | modified | ~145 (header docstring §39 entry + Check 39 implementation block + main() registration) | Includes `_CHECK_39_EXEMPTIONS` allowlist (empty), `_parse_cmd_update_entries()` regex parser, `check_cmd_update_symmetry()` check function. |
| `scripts/tests/test-validate-pack-check-39.sh` | new | 282 | 5 test groups: module-import, parser-against-real-init, synthetic-PASS/FAIL/exempt fragments, static-fixture sanity, end-to-end validate-pack run. |
| `scripts/tests/fixtures/cmd-update-symmetry/README.md` | new | 41 | Fixture-set documentation. |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-pass.sh` | new | 18 | PASS-path fragment (3 entries, all matching docs/pack files). |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-missing.sh` | new | 14 | FAIL-path fragment (omits BAZ.md). |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-malformed.sh` | new | 20 | Parser-degradation fragment (comment-only entries body). |

No edits outside this in-scope set. Trinity files UNCHANGED. Architect
doc edits UNCHANGED. `test-fixtures/manifest.txt` unchanged after
`--all --clean` rebuild (expected: my edits are to `scripts/validate-pack.py`,
a pack-internal CI tool that does not affect what `init-project.sh`
installs, so v11-* fixture SHAs do not drift).

## §3 Check 39 implementation walkthrough

### Function design

Check 39 has two collaborating functions:

1. **`_parse_cmd_update_entries() -> set[str]`** — parses
   `scripts/init-project.sh` and extracts the set of `pack_relpath`
   strings (first colon-separated field) from the `cmd_update`
   `entries=()` array. Uses regex `r"local\s+entries=\(\s*\n(.+?)\n\s*\)\s*\n"`
   against the file text — does NOT source the shell file (no
   side effects, no shell-version sensitivity). Skips lines that
   are blank or start with `#` (comments). Returns empty set on
   parse failure (drives a defensive Check 39 FAIL rather than
   silent PASS-by-vacuity).

2. **`check_cmd_update_symmetry() -> None`** — walks
   `project-template/docs/pack/*.md` and verifies each file is
   either (a) covered by the parsed `cmd_update` entries set, or
   (b) on the `_CHECK_39_EXEMPTIONS` allowlist. FAILs with an
   actionable recommendation naming the missing pack_relpath and
   the exact entries-array form to add.

### Allowlist (exemption) design

`_CHECK_39_EXEMPTIONS: dict[str, str]` — maps bare filename (basename
under `docs/pack/`) to a one-line rationale comment that documents
why the file is intentionally absent from `cmd_update`. Default at
HEAD: empty dict. This is intentional per the "Surface over
silently-exempt" principle from the prompt — better to surface a
file and have Pack Chat decide than to silently exempt without
review.

The exemption mechanism is the prompt's "PASS-with-exemption" path:
if a file in `docs/pack/` is genuinely pre-install-only (e.g., a
hypothetical `MIGRATION-INSTRUCTIONS.md` that's a pre-install reference,
not a client install target), it can be added to `_CHECK_39_EXEMPTIONS`
with a rationale comment per entry. The check then emits an "exempt
per `_CHECK_39_EXEMPTIONS`" OK notice instead of a FAIL.

### Parsing approach

Regex-based parsing of the shell array literal, NOT sourcing the
shell file. Rationale:

- **No side effects** — sourcing `init-project.sh` would execute
  `set -euo pipefail`, define readonly variables, and source other
  libraries (`detect.sh`, `three-way.sh`). The validator must remain
  side-effect-free.
- **No bash-version sensitivity** — pure Python regex works
  identically on macOS bash 3.2 and Linux bash 5.x.
- **Close to Check 26 pattern** — Check 26 also uses regex against
  shell-file contents (`re.search(rf'\breadonly\s+{re.escape(sym)}=', ...)`)
  rather than sourcing. Check 39 follows the same convention.

The regex `r"local\s+entries=\(\s*\n(.+?)\n\s*\)\s*\n"` is
intentionally narrow:

- Anchored on `local entries=(` — the exact form used inside
  `cmd_update` at `scripts/init-project.sh:1108`.
- Non-greedy across newlines (`re.DOTALL`) — captures the array body.
- Requires a closing `)` on its own line — matches the canonical
  bash array shape and prevents accidental matching of nested
  parens in entry content.

If a future refactor changes the array shape (e.g., uses `readonly
entries=(...)` or moves the array out of a function), the regex
will fail to match, `_parse_cmd_update_entries()` returns empty,
and `check_cmd_update_symmetry()` FAILs defensively with the
parse-failure message. This drives a coder fix before the symmetry
check silently degrades.

### Why narrow scope (docs/pack/*.md only)

The prompt suggested a broader symmetry check covering S4 / S6 / S11
glob targets. After reading the actual install paths in
`init-project.sh`, the highest-value asymmetry surface is
`docs/pack/*.md` — the empirically-demonstrated BD-175 Commit 10
failure mode (OPTIONAL-FEATURES.md). Other potential asymmetries
(see §6 below) involve subtler S4/S11 install paths where the
symmetry contract is less clean (e.g., `project-template/skills/*/SKILL.md`
is the canonical pool distributed to all 3 CLIs by S4, NOT directly
copied by cmd_update; `_cmd_update_iter_dir` walks
`project-template/scripts` and `.{tool}/agents` directories at
update time, so those are implicitly covered).

A narrow Check 39 that catches the documented failure mode is
better than a broad Check 39 that produces false positives on
intentional-asymmetry install paths. The narrow check can be
extended later if new asymmetry classes emerge.

## §4 Test fixture design

`scripts/tests/test-validate-pack-check-39.sh` has 5 test groups
(parallel to Check 36/37/38 fixture-script structure):

### Group 0 — Module-import + symbol-registration

Confirms `validate-pack.py` imports cleanly and exposes the new symbols
(`check_cmd_update_symmetry`, `_parse_cmd_update_entries`,
`_CHECK_39_EXEMPTIONS`).

### Group 1 — Parser against real init-project.sh

Invokes `_parse_cmd_update_entries()` against the live
`scripts/init-project.sh` and asserts (a) the parsed entry set contains
the 9 known anchor entries (6 docs/pack files + 3 trinity), (b) the
total entry count is in the expected range 15-50, (c) no comment lines
get parsed as entries.

### Group 2 — Synthetic init-project.sh fragments

Builds 5 tmpdir-scoped scenarios that swap `mod.REPO_ROOT` to a
synthetic root with a stub `scripts/init-project.sh` (entries array
shape only) and `project-template/docs/pack/` directory:

- **T1 PASS** — every synthetic `.md` file has a matching entry → 0
  failures, "no asymmetric coverage" message present.
- **T2 FAIL (missing mapping)** — BAZ.md on disk but not in entries
  → 1 failure, FAIL message names BAZ.md AND references cmd_update.
- **T3 PASS-with-exemption** — MIGRATION-INSTRUCTIONS.md on disk,
  not in entries, BUT on the `_CHECK_39_EXEMPTIONS` allowlist → 0
  failures, exemption notice emitted.
- **T4 empty docs/pack/** — no `.md` files on disk → 0 failures (vacuous
  PASS, but exercised to lock in behavior).
- **T5 comment-only entries body** — parser returns empty set → ≥1
  failure (either parse-failure or per-file FAIL; both defensive).

### Group 3 — Static fixture file sanity

Validates the 3 static `.sh` fixtures under
`scripts/tests/fixtures/cmd-update-symmetry/` are present and parseable.
Asserts `init-fragment-pass.sh` yields ≥3 entries and
`init-fragment-fail-missing.sh` yields strictly fewer entries than
the PASS fragment (regression guard on fixture content).

### Group 4 — End-to-end validate-pack.py exit-status

Invokes the full `python3 scripts/validate-pack.py` and asserts (a)
exit 0, (b) Check 39 header line emitted, (c) Check 39 summary line
("Check 39 — N file(s) checked") emitted. Ensures Check 39 is
actually registered in `main()` and reachable end-to-end.

### Static fixture files (4 in `scripts/tests/fixtures/cmd-update-symmetry/`)

| Fixture | Purpose |
|---|---|
| `README.md` | Documents the fixture set + why static fixtures (vs. tmpdir only). |
| `init-fragment-pass.sh` | PASS-path synthetic with 3 entries matching 3 docs/pack files. |
| `init-fragment-fail-missing.sh` | FAIL-path synthetic omitting BAZ.md. |
| `init-fragment-fail-malformed.sh` | Parser-degradation synthetic (comment-only entries body). |

These mirror the `scripts/tests/fixtures/boundary-checks/` pattern
from Check 37 fixture set: committed reference shapes serve as
documentation anchors and regression scaffolding independent of
tmpdir lifecycle.

## §5 Persona-contract results

All three persona contracts run cleanly:

```
$ bash scripts/persona-contracts/contract-greenfield.sh
...
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh
...
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh
...
=== migration contract: 37 passed, 0 failed ===
```

No regressions. Expected given Check 39 is pure read-only validation
(no install-behavior changes).

## §6 Out-of-scope observations (Pack Chat triage feed-in)

During implementation I noticed several **asymmetries between fresh-install
and `cmd_update` that Check 39 does NOT currently surface** (because they
fall outside the narrow `docs/pack/*.md` scope). These are documented here
per the prompt §"Out of scope" instruction — they are NOT fixed in this
commit; Pack Chat may triage as separate fix work.

### Asymmetry A — `.gemini/commands/pm-startup.toml` not in `cmd_update`

- **File:** `project-template/.gemini/commands/pm-startup.toml`
- **Fresh-install coverage:** NOT explicitly copied by any stage. The
  S11 explicit copy block at `scripts/init-project.sh:867-870` only
  copies `pack-help.toml`. Stage S4 distributes `project-template/skills/
  pm-startup/SKILL.md` to `.claude/skills/pm-startup/SKILL.md` and
  `.codex/skills/pm-startup/SKILL.md`, but the Gemini variant is a
  separate `.toml` command file — NOT copied at fresh install AND NOT
  in `cmd_update` entries.
- **Update coverage:** NOT in `cmd_update` entries array
  (lines 1108-1133).
- **Net effect:** `pm-startup.toml` exists in `project-template/` but
  is NEVER installed to clients via either fresh-install or update. This
  is a deeper drift than what Check 39 catches.
- **Suggested triage:** A separate fix-coder pass to (a) add the
  S11 explicit copy block for `.gemini/commands/pm-startup.toml`
  parallel to the pack-help copy, AND (b) add the entry
  `"project-template/.gemini/commands/pm-startup.toml:.gemini/commands/pm-startup.toml:generic"`
  to `cmd_update` entries.

### Asymmetry B — `.claude/skills/pm-startup/SKILL.md` and `.codex/skills/pm-startup/SKILL.md` not in `cmd_update`

- **Files:** `project-template/.claude/skills/pm-startup/SKILL.md`,
  `project-template/.codex/skills/pm-startup/SKILL.md`
- **Fresh-install coverage:** Distributed by S4 from
  `project-template/skills/pm-startup/SKILL.md` (the canonical pool).
- **Update coverage:** NOT in `cmd_update` entries. Compare with
  `.claude/skills/pack-help/SKILL.md` and `.codex/skills/pack-help/
  SKILL.md` which ARE in cmd_update at lines 1130-1131.
- **Net effect:** Updates to the pm-startup skill content don't
  propagate to existing clients via `pack update`. Fresh-install gets
  the updated content because S4 re-distributes from the canonical
  pool.
- **Suggested triage:** Add cmd_update entries for both per-CLI
  pm-startup skill paths. OR: refactor `cmd_update` to also iterate
  the canonical skills pool (parity with S4's distribution loop)
  via a new `_cmd_update_iter_dir` call against
  `project-template/skills`. The latter is a bigger refactor.

### Asymmetry C — `project-template/.claude/settings.local.example.json` not in `cmd_update`

- **File:** `project-template/.claude/settings.local.example.json`
- **Fresh-install coverage:** NOT explicitly copied by S3 (only
  `.claude/settings.json` is in S3's loop). Likely intentional —
  `settings.local.*` patterns are typically user-managed.
- **Update coverage:** NOT in `cmd_update` entries.
- **Net effect:** Consistent — neither path installs this file.
  Probably correct.
- **Suggested triage:** No fix needed unless Pack Chat determines this
  IS intended to install to clients. If so, add to both S3 explicit
  loop AND cmd_update entries.

### Asymmetry D — Per-entry skeleton (`project-template/docs/project/{backlog,implementation-plan,changelog}/_*.md`) not in `cmd_update`

- **Files:** `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md`,
  `_intro.md`, `_format.md` (changelog only).
- **Fresh-install coverage:** Installed by S11 step 6 (lines 891-947)
  via explicit `"$copy_fn"` calls.
- **Update coverage:** NOT in `cmd_update` entries.
- **Net effect:** Updates to per-entry skeleton templates (e.g., a
  new section in `_rules.md`) don't propagate to existing clients
  running `pack update`. Fresh-install gets them.
- **Suggested triage:** Add cmd_update entries for the 8 per-entry
  skeleton files (2 each for backlog + implementation-plan + 3 for
  changelog). Use class `generic` or a new class `per-entry-template`
  per BD-088 customization-preserve semantics.

### Recommendation for Check 39 future extensions

Once Pack Chat resolves the asymmetries above, Check 39 can be
**extended in a follow-up BD** to walk additional fresh-install glob
targets:
- `project-template/skills/*/SKILL.md` (canonical pool — covered via
  3 per-CLI mirrors or via direct cmd_update entries).
- `project-template/.gemini/commands/*.toml` (Gemini command surface).
- `project-template/docs/project/<stream>/_*.md` (per-entry skeleton
  templates).

The current narrow scope (`docs/pack/*.md`) is the highest-value gate
and a clean PASS at HEAD. Broader gates require resolving the
asymmetries first (otherwise broader Check 39 FAILs at HEAD).

## §7 Verification command output

```
$ git rev-parse HEAD
88a0aea1f086266460f6966500ffff175297176e

$ grep -n "check_39\|Check 39\|cmd_update.*symmetry\|_CHECK_39" \
    scripts/validate-pack.py | head -8
179:  39. cmd_update mapping/glob symmetry (BD-175 F2a per F4 bundle
194:      `_CHECK_39_EXEMPTIONS` for files intentionally absent from
4179:# ── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a) ────────────────
4190:# leave OUT of the allowlist and let Check 39 FAIL — Pack Chat triage can
4192:_CHECK_39_EXEMPTIONS: dict[str, str] = {
4199:def _parse_cmd_update_entries() -> set[str]:
4237:def check_cmd_update_symmetry() -> None:
4254:    print("\n── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──")

$ python3 scripts/validate-pack.py 2>&1 | tail -5
── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean

$ bash scripts/tests/test-validate-pack-check-39.sh 2>&1 | tail -5
=== Summary ===
  PASS: 5
  FAIL: 0

All tests passed.

$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>&1 | tail -5
=== Summary ===
  PASS: 6
  FAIL: 0

All tests passed.

$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -1
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -1
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -1
=== migration contract: 37 passed, 0 failed ===

$ bash test-fixtures/build.sh --all --clean 2>&1 | tail -3
  built: .../test-fixtures/existing-project-mid-dev
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
manifest written: .../test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
(no output — manifest unchanged)

$ git status --short
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F1.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F4-BUNDLE.md
?? scripts/tests/fixtures/cmd-update-symmetry/
?? scripts/tests/test-validate-pack-check-39.sh
```

The two `PACK-REVIEW-BD-175-*.md` files in `?? `untracked are from
the concurrent F1 per-commit reviewer + the F4 bundle review —
file-disjoint with this coder session per the prompt's
background-spawn note.

## §8 PREFLIGHT line

```
PREFLIGHT: 6/6 in-scope file edits complete; verification PASS; HEAD 88a0aea1f086266460f6966500ffff175297176e; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F2A.md
```

## Definition-of-Done checklist

- [x] `scripts/validate-pack.py` has Check 39 implementation (PASS)
- [x] `python3 scripts/validate-pack.py` exit 0 — Check 39 PASSes at HEAD (PASS, 0 mapping additions needed)
- [x] Test fixture script (`test-validate-pack-check-39.sh`) PASSes (PASS, 5/5)
- [x] Test fixtures exist and exercise PASS / FAIL / PASS-with-exemption paths (PASS — Group 2 T1/T2/T3 cover all three; Group 3 covers static fixtures)
- [x] `bash test-fixtures/build.sh --all --clean` executes; manifest diff empty as expected (validate-pack.py edits do not affect fixture install outputs)
- [x] All 3 persona contracts STILL PASS (greenfield 191/0, mid-dev 25/0, migration 37/0)
- [x] No edits outside the named in-scope files
- [x] No state-changing git verbs run (only `git rev-parse HEAD`, `git status`, `git diff`)
- [x] PREFLIGHT line emitted before IMPL-REPORT write
- [x] Trinity files UNCHANGED
- [x] Architect doc edits UNCHANGED
- [x] `cmd_update` install logic in `init-project.sh` UNCHANGED (Check 39 is the GATE; mapping gaps surfaced in §6 are NOT fixed here)

## Files-changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-validate-pack-check-39.sh` | new |
| `scripts/tests/fixtures/cmd-update-symmetry/README.md` | new |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-pass.sh` | new |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-missing.sh` | new |
| `scripts/tests/fixtures/cmd-update-symmetry/init-fragment-fail-malformed.sh` | new |

## Plan deviations

**Zero.** The prompt left the exact implementation shape ("Python regex,
sh source-parsing, AST, whatever fits") to the coder's judgment. The
chosen approach (regex against the shell array literal, narrow scope
of `docs/pack/*.md`) is described in §3 and §6 as a deliberate design
choice. Out-of-scope asymmetries are documented in §6 per the prompt's
"Out of scope" instruction.

## New POQs introduced

None. The §6 asymmetry observations are operational drift findings,
not architectural questions. Pack Chat triage routes them to follow-up
fix-coder work or a new BD if scope warrants.
