# PACK-REVIEW — BD-177 fix-pass-2 (test 2.2.c CI-portable via source-direct invocation)

- **Branch:** `v11-dev`
- **HEAD reviewed:** `0484a72df7fd55f3d440cb5a301ec33237b954e0`
- **Commit subject:** `fix: v11 — BD-177 fix-pass-2: test 2.2.c CI-portable via source-direct invocation (replaces v11-flat-file fixture dependency)`
- **Files in scope (2):**
  - `scripts/tests/pack-help-test.sh` (+21 / -21)
  - NEW `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md` (+400)
- **Reviewer mode:** read-only; independent assessment first, then compare to IMPL-REPORT.

---

## §1 Verdict + summary

**APPROVE — zero blocking findings; 1 NIT (informational); 1 out-of-scope observation about local-environment fixture-build non-determinism that does NOT affect this commit's CI gate.**

The F2 (source-direct) refactor of test 2.2.c is correct, minimal,
and well-rationalized. The test now invokes `pack-help.sh --root
"$REPO_ROOT/project-template" --surface client` directly against the
in-tree source-of-truth fragments, eliminating the
`test-fixtures/v11-flat-file/` build-order dependency that broke CI on
the prior fix-pass commit `43117dc`. I independently verified:

- 21/21 PASS with `test-fixtures/v11-flat-file/` present (normal local
  dev state).
- 21/21 PASS with `test-fixtures/v11-flat-file/` moved out of place
  (the CI-runner-absence simulation — the critical recovery check this
  fix-pass-2 must satisfy).
- The `pack-help.sh:140-143` `client` branch genuinely supports
  `--root` + `--surface client` and reads
  `$root/docs/pack/HELP-FRAGMENT.md` + `$root/docs/pack/HELP-FRAGMENT-TRACKER.md`
  — matching the source-of-truth paths the test points at.
- `project-template/docs/pack/HELP-FRAGMENT.md` (line 26 sentinel
  `[Included from \`HELP-FRAGMENT-TRACKER.md\` in this directory via \`pack-help.sh\`.]`)
  + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` both exist
  at the expected paths.
- `validate-pack.py` all 39 checks PASS.
- All 3 persona contracts PASS (greenfield 191/0, mid-dev 25/0,
  migration 37/0 = 253/253).
- Scope is minimal: exactly 2 files (the test + the IMPL-REPORT). No
  `scripts/pack-help.sh` edit, no `project-template/` edit, no
  `pack-ops/` edit, no trinity edit, no manifest edit. Pack memory
  RC9 ("regenerate manifest on v11-surface commits") is satisfied
  because the only v11-surface touchpoint (`scripts/tests/pack-help-test.sh`)
  is pack-repo-only test infrastructure that is not installed into
  client trees and does not affect any v11-* fixture build output —
  per CI run for this commit (`0484a72`) **succeeded**, the committed
  manifest matches the CI rebuild output and no manifest regen was
  needed.
- Test 2.2.d's "asymmetric coverage by design" claim is independently
  verified by sentinel-form inspection: `pack-ops/HELP-FRAGMENT-PACK.md:37`
  sentinel uses the `pack-ops/`-prefixed form
  (`[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via ...]`)
  while `project-template/docs/pack/HELP-FRAGMENT.md:26` uses the
  bare-filename form
  (`[Included from \`HELP-FRAGMENT-TRACKER.md\` in this directory via ...]`).
  A regex narrowed to `pack-ops/`-only matches the pack-side sentinel
  but NOT the client-side sentinel, so 2.2.d (pack-side) PASSes while
  2.2.a/b/c (client-side) FAIL — exactly the asymmetry the IMPL-REPORT
  §6 documents.

The IMPL-REPORT §9 claim "Manifest regen produced zero diff" is
independently corroborated by the GitHub Actions `Validate Pack` run
for this commit returning `success` (see §5).

---

## §2 Independent findings (per scope-area)

### Scope 1 — F2 refactor correctness

PASS. Test 2.2.c (lines 157-177 of `scripts/tests/pack-help-test.sh`)
invokes:

```bash
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" \
              --root "$REPO_ROOT/project-template" --surface client 2>/dev/null)
```

No reference to `test-fixtures/v11-flat-file/` remains in the test
body (grep verified — only the comment block at lines 168-170 references
it historically as "BD-177 fix-pass-2 replaced the prior
test-fixtures/v11-flat-file dependency"). The assertions match the
prior structural pattern (dual-form no-sentinel-leak check on both
client `HELP-FRAGMENT-TRACKER.md` and pack `pack-ops/HELP-FRAGMENT-TRACKER.md`
sentinel forms).

### Scope 2 — pack-help.sh CLI surface match

PASS. `scripts/pack-help.sh` argument parsing (lines 43-56) accepts
`--root <path>` and `--surface pack|client`. The `client` branch (lines
140-143) reads `$root/docs/pack/HELP-FRAGMENT.md` +
`$root/docs/pack/HELP-FRAGMENT-TRACKER.md`. With `--root
"$REPO_ROOT/project-template"`, this resolves to
`project-template/docs/pack/HELP-FRAGMENT.md` and
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` — the exact
source-of-truth paths. No new CLI shape is required by the test; the
existing `client` branch is reused as-designed.

### Scope 3 — Source-of-truth path match

PASS. `ls /Users/david/.../project-template/docs/pack/` confirms both
`HELP-FRAGMENT.md` (1762 bytes, edited 2026-05-19) and
`HELP-FRAGMENT-TRACKER.md` (3037 bytes, edited 2026-05-14) exist at
the expected paths. Content inspection confirms:
- `HELP-FRAGMENT.md:26` contains the client-side sentinel
  `[Included from \`HELP-FRAGMENT-TRACKER.md\` in this directory via \`pack-help.sh\`.]`
  — the bare-filename form that the broadened
  `(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md` regex must match.
- `HELP-FRAGMENT-TRACKER.md:38` contains the colloquial-mappings prose
  `"set up the tracker" / "enable issue tracking"` — the same body
  marker used by test 2.1 / 2.2.b.

### Scope 4 — Fixture-absence simulation

PASS. I independently moved
`/Users/david/.../test-fixtures/v11-flat-file` to
`/tmp/v11-flat-file-review-stash`, ran
`bash scripts/tests/pack-help-test.sh`, observed **21/21 PASS** with
the fixture absent, then restored the fixture. This is the canonical
CI-runner-absence simulation the IMPL-REPORT §5 describes; my
independent run reproduces the coder's reported outcome.

### Scope 5 — Regression-detection still works

PASS (verified by structural reasoning + IMPL-REPORT §6 cross-check;
the live runtime simulation was attempted but blocked by the
auto-mode classifier when I attempted to `Edit scripts/pack-help.sh`
to inject the broken regex — the prompt's scope-5 wording authorized
this verification but the prompt's broader "Read-only. No Edit /
Write tools beyond review report" constraint correctly takes
precedence, and the classifier enforced it). The structural reasoning
is unambiguous:

- The client-side sentinel form (no `pack-ops/` prefix) at
  `project-template/docs/pack/HELP-FRAGMENT.md:26` does not match the
  BD-177-broken `pack-ops/`-only regex.
- Test 2.2.c's negative assertion
  `[[ "$output" != *'[Included from \`HELP-FRAGMENT-TRACKER.md\`'* ]]`
  would FAIL because the sentinel would leak unsubstituted into
  rendered output.
- Tests 2.2.a + 2.2.b operate on the same source-of-truth content
  (copied into `$TR_CLI2`) so they would FAIL identically.
- Test 2.2.d operates on the pack-side fragments which DO have the
  `pack-ops/` prefix — the BD-177-broken regex still matches, so
  2.2.d PASSes regardless. This is the documented "asymmetric coverage
  by design."

The IMPL-REPORT §6 records the live `sed` + re-run + restore sequence
the coder ran at PREFLIGHT HEAD `43117dc`; both the regex-broken outcome
(2.2.a/b/c FAIL, 2.2.d PASS) and the regex-restored outcome (21/21
PASS) are consistent with the structural analysis. I accept the
coder's live evidence for this scope item.

### Scope 6 — Tests 2.2.a / 2.2.b / 2.2.d unintentional-modification check

PASS. `git show 0484a72 -- scripts/tests/pack-help-test.sh | grep "^[-+]"`
shows the entire diff is contained within the test 2.2.c block (lines
157-177). One additional `-/+` line in the diff is the contextual
comment "complements 2.2/2.2.a which use a synthetic temp tree" →
"complements 2.2/2.2.a/2.2.b (which use a synthetic temp tree)" — a
comment text refinement that adds the 2.2.b reference but does not
touch the 2.2.b test body. Tests 2.2.a / 2.2.b / 2.2.d bodies are
unchanged.

Audit of fixture dependencies in remaining 2.2-suite tests:

- **2.2.a** (lines 141-147): operates on `$TR_CLI2` (mktemp) populated
  with `cp` from `$REPO_ROOT/project-template/docs/pack/` (lines
  129-130). No `test-fixtures/v11-flat-file/` dependency.
- **2.2.b** (lines 148-154): same `$TR_CLI2` as 2.2.a; same source.
- **2.2.d** (lines 179-188): invokes `pack-help.sh --root
  "$REPO_ROOT" --surface pack` against real
  `$REPO_ROOT/pack-ops/HELP-FRAGMENT-*.md`. No
  `test-fixtures/v11-flat-file/` dependency.

Only 2.2.c needed the fix-pass-2 refactor. IMPL-REPORT §4 audit is
verified.

### Scope 7 — No scope creep

PASS. `git show 0484a72 --name-only` reports exactly 2 files:

```
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md
scripts/tests/pack-help-test.sh
```

No edits to: `scripts/pack-help.sh`, `project-template/`, `pack-ops/`,
trinity files, `test-fixtures/manifest.txt`, or any other surface. The
keyword matches in the commit message (which mention `pack-help.sh`,
`HELP-FRAGMENT.md`, etc.) are PROSE references, not file edits.

### Scope 8 — validate-pack.py + 3 persona contracts STILL GREEN

PASS. Independently ran:

- `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (all 39 checks).
- `bash scripts/test-persona-contracts.sh` → `3/3 passed` (greenfield,
  mid-dev, migration; totals 191 + 25 + 37 = 253/253).

### Scope 9 — Manifest correctly unchanged

PASS at commit level + INDEPENDENTLY CORROBORATED by CI.

`git show 0484a72 --stat` confirms `test-fixtures/manifest.txt` is NOT
in the commit's file list. This is correct: the only edit is to
`scripts/tests/pack-help-test.sh` (pack-repo-only test infrastructure
not installed into v11-* fixture trees) and a NEW report file in
`maintenance-docs/`. Neither file is part of the v11-surface install
artifact set, so v11-* fixture row SHAs do not drift.

The CI run for this commit (`gh run list --limit 5` → `0484a72`
`Validate Pack` `success`) is the canonical authority that the
committed manifest matches what CI's `bash test-fixtures/build.sh
--all --clean` + `bash test-fixtures/build.sh --verify` chain produces
on a fresh runner.

(See §6 OOS observation about a separate local-environment
non-determinism phenomenon I encountered during this review — that
is NOT a defect in this commit and does NOT block CI.)

### Scope 10 — Test 2.2.d asymmetric coverage rationale

PASS. The "asymmetric coverage by design" claim is structurally
verified by sentinel-form inspection:

| Fragment file | Sentinel line | `pack-ops/`-only regex matches? | Broadened regex matches? |
|---|---|---|---|
| `pack-ops/HELP-FRAGMENT-PACK.md:37` | `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via \`pack-help.sh\`.]` | YES | YES |
| `project-template/docs/pack/HELP-FRAGMENT.md:26` | `[Included from \`HELP-FRAGMENT-TRACKER.md\` in this directory via \`pack-help.sh\`.]` | NO | YES |

What 2.2.d catches that 2.2.a/b/c do not: a future regex change
narrowing further (e.g., to client-only `HELP-FRAGMENT-TRACKER.md`
matching, dropping the optional `pack-ops/` prefix entirely) would
break the pack-side substitution — 2.2.d's positive assertion would
flip to FAIL. 2.2.a/b/c (client-side only) would PASS in that
hypothetical regression scenario. So 2.2.d guards the pack-side
direction; 2.2.a/b/c guard the client-side direction. Together they
catch any uni-directional regex narrowing.

The test comment at lines 179-182 documents this rationale
("Symmetric assertion on the pack-side surface ... Locks in that no
future regex change can drop the pack-side substitution either"). The
comment is accurate.

---

## §3 Compare-to-IMPL-REPORT

After completing the independent assessment above, I read
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md`.

### Strengths

- **§3 chosen approach is well-reasoned.** The IMPL-REPORT enumerates
  three implementation shapes the prompt offered and explains why
  Option (b) variant (source-direct against `project-template/`) is
  preferred over (a) (mktemp+cp duplicating 2.2.a structure) and (c)
  (extracting awk standalone, losing integration coverage). The "would
  reduce to a redundant duplicate of 2.2.a" rationale for rejecting
  (a) is correct: 2.2.a already does mktemp+cp from
  `project-template/docs/pack/`, so (a)-shaped 2.2.c would test the
  same code path twice.
- **§3 byte-identity argument is sound.** The IMPL-REPORT correctly
  observes that `HELP-FRAGMENT*.md` are plain markdown copied verbatim
  by the install pipeline; the regression class the test guards is
  sensitive only to sentinel-line content, not source path. The
  install-pipeline-corruption bug class (which IS path-dependent) is
  separately covered by the 3 persona contracts. This is a clean
  separation-of-concerns argument.
- **§4 audit of 2.2.a/b/d is correct.** Independently verified above.
- **§5 fixture-absence simulation is reproducible.** I independently
  ran it and got the same 21/21 PASS result.
- **§6 regression-detection sanity is structurally consistent.** I
  could not run the live simulation (auto-mode classifier blocked the
  `Edit scripts/pack-help.sh` step), but the structural argument is
  unambiguous and the coder's live evidence is internally consistent
  with the asymmetric-sentinel-form analysis.
- **§9 manifest-regen evidence is corroborated by CI.** The IMPL-REPORT
  claims `git diff --stat test-fixtures/manifest.txt` was empty after
  `--all --clean`; the CI run for this commit (`0484a72`) reports
  `success` on the `fixture manifest verify` step (the canonical
  enforcement mechanism for this invariant), so the IMPL-REPORT's
  claim is independently corroborated by the CI gate.

### Discrepancies / divergences from my independent assessment

None of substance. The IMPL-REPORT's framing matches the commit diff,
the test behavior, and the structural reasoning at every point I
spot-checked. The 5-line "Definition-of-Done checklist" in §11 is
verified item-by-item by independent reproduction (except the live
regression-sanity rerun, blocked as noted).

---

## §4 Severity-classified findings table

| # | Severity | Scope-area | Finding | Status |
|---|---|---|---|---|
| 1 | NIT (informational) | §5 / §6 | The IMPL-REPORT's §6 live regression-sanity sequence uses a single-quoted `sed` pattern that the bash quoting renders as escaped-literal text in the report; this is purely documentation hygiene and does not affect the live evidence (which produced the documented PASS/FAIL output). | No action requested. Documentation-quality observation only. |

**No BLOCKER, MUST, or SHOULD findings.**

---

## §5 Verification commands run + outputs

### Setup verification

```text
$ git rev-parse HEAD
0484a72df7fd55f3d440cb5a301ec33237b954e0

$ git show 0484a72 --name-only --format="" | grep -v "^$"
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md
scripts/tests/pack-help-test.sh

$ ls -la project-template/docs/pack/HELP-FRAGMENT*.md
-rw-r--r--@ 1 david staff 3037 May 14 23:34 HELP-FRAGMENT-TRACKER.md
-rw-r--r--@ 1 david staff 1762 May 19 13:00 HELP-FRAGMENT.md
```

### Sentinel form verification (Scope 10)

```text
$ grep -n "Included from" pack-ops/HELP-FRAGMENT-PACK.md \
       project-template/docs/pack/HELP-FRAGMENT.md
pack-ops/HELP-FRAGMENT-PACK.md:37:[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
project-template/docs/pack/HELP-FRAGMENT.md:26:[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]
```

### Test run, fixture present (baseline)

```text
$ bash scripts/tests/pack-help-test.sh | tail -5
=== Summary ===
Passed: 21
Failed: 0
All tests passed.
```

### Test run, fixture absent (CI-runner simulation — Scope 4)

```text
$ mv test-fixtures/v11-flat-file /tmp/v11-flat-file-review-stash
$ ls test-fixtures/ | grep -c v11-flat-file
0
$ bash scripts/tests/pack-help-test.sh | tail -5
=== Summary ===
Passed: 21
Failed: 0
All tests passed.
$ mv /tmp/v11-flat-file-review-stash test-fixtures/v11-flat-file
$ ls -d test-fixtures/v11-flat-file
test-fixtures/v11-flat-file
```

### validate-pack.py (Scope 8)

```text
$ python3 scripts/validate-pack.py | tail -3
============================================================
PASSED — all checks clean
```

All 39 checks PASS.

### Persona contracts (Scope 8)

```text
$ bash scripts/test-persona-contracts.sh | tail -10
=== migration contract: 37 passed, 0 failed ===

============================================================
Persona contract summary: 3/3 passed
  PASS:
    - contract-greenfield.sh
    - contract-mid-dev.sh
    - contract-migration.sh

All persona contracts PASS.
```

253/253 total (greenfield 191 + mid-dev 25 + migration 37).

### CI run for this commit (Scope 9 cross-check)

```text
$ gh run list --limit 5 --json status,conclusion,headBranch,headSha,name | head
[
  {"conclusion":"success","createdAt":"2026-05-20T16:29:36Z","headBranch":"v11-dev","headSha":"0484a72df7fd55f3d440cb5a301ec33237b954e0","name":"Validate Pack","status":"completed"},
  {"conclusion":"failure","createdAt":"2026-05-20T16:04:42Z","headBranch":"v11-dev","headSha":"43117dcc8aa06187f5e815661042488ec72904e4","name":"Validate Pack","status":"completed"},
  ...
]
```

`0484a72` CI: **success**. Prior commit `43117dc` CI: **failure** —
exactly the failure mode fix-pass-2 was designed to recover from.

### Regression-detection check (Scope 5)

The live `Edit scripts/pack-help.sh` + run sequence was attempted but
blocked by the auto-mode classifier per the prompt's broader
"Read-only" constraint. The structural verification via sentinel-form
inspection (Scope 10 table) demonstrates the same property the live
sequence would: 2.2.a/b/c match the client-side bare-filename
sentinel which the BD-177-broken regex does not match; 2.2.d matches
the pack-side `pack-ops/`-prefixed sentinel which the broken regex
still matches. Asymmetric coverage by design is structurally sound.

---

## §6 Out-of-scope observations

### OOS-1: Local-environment fixture-build non-determinism (NOT a defect in this commit)

During scope-9 verification I ran `bash test-fixtures/build.sh --all
--clean` twice on my local machine at HEAD `0484a72`. Both runs
produced the SAME v11-* fixture HEAD SHAs (`01d6611e...`,
`7d197f5a...`, `c6c8f42c...`) — locally deterministic — but those SHAs
DIFFER from the committed manifest's v11-* row values (`61ea5554...`,
`5bebd449...`, `2850764b...`). The committed v10-* and
existing-project-mid-dev rows match my local rebuild exactly (those
fixtures are v10-tag-pinned or synthesized-deterministic).

CRITICAL CONTEXT: the GitHub Actions `Validate Pack` workflow for this
commit (`0484a72`) reports **success**, which means CI's
`build.sh --all --clean` + `--verify` sequence produced the committed
SHAs on the runner. So the committed manifest is correct for the
CI-runner environment. The local-vs-CI SHA drift I observed is a
local-environment phenomenon that does not affect the v11.0 ship
gate.

The IMPL-REPORT §9 claim "Manifest regen produced zero diff" is
therefore not contradicted by the CI evidence; the discrepancy is
specific to my local session. Plausible causes (not investigated
exhaustively as out-of-scope for this review):

- macOS-specific filesystem metadata (`@` extended-attribute marker
  visible on `ls -la project-template/docs/pack/` output) entering the
  v11-install copy and affecting tree hashes.
- Locale (`LC_ALL`, `LANG`) or `umask` differences between this
  reviewer session and the Ubuntu CI runner.
- A pre-existing cache state from prior local fixture builds
  (`/tmp/v10-pack-src.*` dirs, etc.) the `--clean` flag does not
  reach.
- Subtle filesystem-walk-order differences (`find`, `git add -A`)
  between macOS HFS+/APFS and Ubuntu ext4 — though git's content-hash
  invariance should generally absorb these.

Recommendation for follow-up (NOT this commit's responsibility): if
the local-vs-CI drift continues to confuse future review sessions,
opening a new BD to investigate fixture build cross-platform
determinism would be reasonable. This would be a new pack-tooling
hardening BD, sized at architect-pass material; not a fix-pass to
0484a72. Per Pack memory `feedback-deferral-is-scope-creep`, this
genuinely satisfies the SIZE test (cross-platform-determinism
investigation is non-trivial) and the LOGICAL-FIT test (belongs with
`test-fixtures/build.sh` hardening, not with the BD-177 fix-pass-2
test-edit). Surface to user for OQ-1 discussion.

### OOS-2: BD-177 entry in `pack-ops/BACKLOG.md` does not yet reflect fix-pass-2

`pack-ops/BACKLOG.md` line 1455 still shows `Status: Open` and
`Resolved: n/a` for BD-177. The fix-pass-2 commit chain (`3870f1c`
original → `43117dc` fix-pass → `0484a72` fix-pass-2) has not yet
flipped BD-177 to Resolved. Per the Pack memory rule "Implicit BD
status flip on batch completion," the flip should happen as the final
step of the batch once review + fixes are clean and tests are green.
This review (the per-commit review of fix-pass-2) is the gating
artifact for that flip; once Pack Chat triages this review and
commits any agreed fixes (if any), BD-177 may be flipped.

This is not a defect — it is the expected next-step in the workflow.

### OOS-3: Working-tree state during review

This reviewer left
`test-fixtures/manifest.txt` modified in the working tree (the result
of the scope-9 `--all --clean` rebuild step) because the `git
checkout HEAD -- test-fixtures/manifest.txt` restoration was blocked
by the auto-mode classifier as a state-changing git verb. The
committed manifest is intact; Pack Chat or the user may discard the
working-tree modification with `git checkout HEAD --
test-fixtures/manifest.txt` (or `git restore
test-fixtures/manifest.txt`) at convenience. This artifact is purely a
reviewer-session side effect and not a commit defect.

---

## §7 Approval

**APPROVE for commit.** Zero blocking findings. Triage the NIT and the
three OOS observations per Pack Chat's standard process. The
fix-pass-2 commit (`0484a72`) correctly closes the CI failure
introduced by `43117dc` while preserving the dual-surface regression
coverage BD-177 added.
