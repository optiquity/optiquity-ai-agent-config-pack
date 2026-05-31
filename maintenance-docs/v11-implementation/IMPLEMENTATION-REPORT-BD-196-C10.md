# IMPLEMENTATION-REPORT — BD-196 commit C10

**Commit:** C10 — wire the M4 concision gate (Check 44) + per-doc allowlist
+ advisory length + per-check test + CI wiring. The FINAL coder commit of
the doc-concision-guardrails plan; the payoff that all prior commits (C1–C9)
prepared.

**Branch:** `v11-dev`
**Base HEAD (pre-flight):** `60ec0db3e77e30a7170047a0be668216475a8e9b`
**Final HEAD (worktree, no commit made):** `60ec0db3e77e30a7170047a0be668216475a8e9b`
(agents never commit; working-tree edits only — Pack Chat stages/commits)

---

## 0. Pre-flight (mandatory)

- `git rev-parse HEAD` → `60ec0db3e77e30a7170047a0be668216475a8e9b`
- `git status` → clean working tree on `v11-dev` (before edits).
- Directories `ls`-verified: `scripts/`, `scripts/tests/`, `pack-ops/`,
  `.github/workflows/` all present with the expected templates
  (validate-pack.py 309963 bytes, test-validate-pack-check-45.sh,
  test-46.sh, validate-pack.yml).
- Spec docs read FIRST: `PLAN-DOC-CONCISION-GUARDRAILS.md` §3 C10 + EE-P1;
  `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §6 (M1–M4) + §7;
  `IMPLEMENTATION-REPORT-BD-196-C9.md` (the 6 KEEP 'will' lines).
- Filename-uniqueness pre-check: `find . -name ".concision-allowlist.txt"`
  and `find . -name "test-validate-pack-check-44.sh"` (excluding `.git/`)
  both returned EMPTY → no collision; both new names are unique.

---

## 1. The M4 class — exactly 7 docs (disambiguation)

EE-P1 (PLAN L23) labels "7 durable `pack-ops/` non-mirror docs (M4 target
class)" but then enumerates 9 docs in a line-count list (which includes
PACK-AGENTS + PACK-CHAT). The **M4-probe hit-count line (PLAN L24)** is the
authoritative class definition — it lists EXACTLY 7 docs with their hit
counts: BOUNDARY=15, CONCEPTUAL-REVIEW=11, MERGE-STRATEGY=6,
OPTIONAL-FEATURES=4, DRY-RUN=2, HELP-FRAGMENT-PACK=0, HELP-FRAGMENT-TRACKER=0.
PACK-AGENTS / PACK-CHAT are NOT in the probe — they were measured for
line-count context and are governed by the §9.6 anti-restate + B5 work
(Check 46), NOT M4. C9's report also handled exactly these 7 (the "other 6"
+ BOUNDARY from C4). **The M4 class = these 7 docs.** PACK-AGENTS L175
(`will hit`) and PACK-CHAT (`will change` / `reviewer will flag`) are
correctly OUT of scope.

This is a documentation-ambiguity observation, not a plan deviation — the
authoritative probe line is unambiguous and I implemented to it.

---

## 2. Measure → categorize (KEEP/STRIP) — the live tree at HEAD 60ec0db

The M4 forbidden-pattern probe (identical to the C4/C9 canonical reshape
probe, so the gate enforces exactly the contract those commits cleaned to):

```
dates         20[0-9]{2}-[0-9]{2}-[0-9]{2}
7-40-hex SHA  \b[0-9a-f]{7,40}\b   (word-boundary anchored)
Commit N      Commit [0-9]
Override N    Override [0-9]
post-Commit   post-Commit
temporal will \bwill               (canonical probe form `\bwill `)
```

**Complete occurrence table — every forbidden-pattern hit across all 7 M4
docs at HEAD 60ec0db (re-measured live; C9's line numbers held):**

| Doc | Line | Pattern | Hit content | KEEP / STRIP |
|---|---|---|---|---|
| BOUNDARY-DEFINITION.md | — | — | (no hits) | — |
| CONCEPTUAL-REVIEW-METHODOLOGY.md | — | — | (no hits under canonical `\b…\b` hex anchor) | — |
| DRY-RUN-MIGRATION.md | 156 | will | "It will say a sidecar *would* be written" | **KEEP** (harness output behavior) |
| DRY-RUN-MIGRATION.md | 185 | will | "the exact state the real run will start from" | **KEEP** (recovery procedure) |
| HELP-FRAGMENT-PACK.md | — | — | (no hits) | — |
| HELP-FRAGMENT-TRACKER.md | — | — | (no hits) | — |
| MERGE-STRATEGY.md | 214 | will | "will route through `pack-script` 3-way text dispatch" | **KEEP** (migrator routing behavior) |
| MERGE-STRATEGY.md | 216 | will | "not present in the pack repo will hit `project-only-file`" | **KEEP** (classification outcome) |
| OPTIONAL-FEATURES.md | 176 | will | "the agent will consume but not the agent file itself" | **KEEP** (provider/agent behavior) |
| OPTIONAL-FEATURES.md | 194 | will | "The recommendation system will not nag in this regime" | **KEEP** (system behavior) |

**STRIP-class proof (measure-then-bound step 3):** the STRIP-class probe
(dates / SHA / Commit N / Override N / post-Commit — i.e. ALL forbidden
patterns EXCEPT `will`) over all 7 docs returns **STRIP = 0** on every doc.
No residual STRIP hit exists → C4/C9 were complete → **no route-back needed;
allowlist NOT widened.**

> **Empirical-Evidence — STRIP-class = 0 across the 7 M4 docs. HEAD 60ec0db, 2026-05-31.**
> Command: `grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}|\b[0-9a-f]{7,40}\b|Commit [0-9]|Override [0-9]|post-Commit' pack-ops/<doc>.md` for each of the 7.
> Output: every doc → "STRIP=0".
> Conclusion: SUPPORTED — zero STRIP-class contamination; the only residual
> forbidden-pattern hits are the 6 KEEP operational `will` lines.

Note on the hex anchor: an UN-anchored `[0-9a-f]{7,40}` count flagged
CONCEPTUAL-REVIEW (ordinary words like "implementation"/"established" are
all-hex-char spans ≥7). The C4/C9 canonical probe uses the word-boundary
form `\b[0-9a-f]{7,40}\b`; under it CONCEPTUAL-REVIEW = 0 hits, and an
independent check confirmed ZERO all-hex-char words of length 7-40 exist in
any of the 7 docs. The gate encodes the word-boundary form — the same one
that defined the cleaned contract.

---

## 3. The allowlist as authored — sized to the KEEP set EXACTLY

`pack-ops/.concision-allowlist.txt` (NEW) — 6 records, one per KEEP
occurrence, content-anchored by `snippet` (NOT line number — line numbers
drift). The full file is reproduced in §9. The 6 records:

| Doc | snippet (stable content anchor) | pattern | reason class |
|---|---|---|---|
| DRY-RUN-MIGRATION.md | `It will say a sidecar` | will | operational (harness output) |
| DRY-RUN-MIGRATION.md | `the exact state the real run will start from` | will | operational (recovery) |
| MERGE-STRATEGY.md | ``will route through `pack-script` 3-way text dispatch`` | will | operational (migrator routing) |
| MERGE-STRATEGY.md | `not present in the pack repo will hit` | will | operational (classification) |
| OPTIONAL-FEATURES.md | `provider abstraction the agent will consume but not the agent file` | will | operational (provider) |
| OPTIONAL-FEATURES.md | `The recommendation system will not nag in this regime` | will | operational (system) |

**Allowlist size = 6 = the KEEP set exactly.** Zero STRIP-class entries
(none exist to admit). The allowlist is content-anchored: a KEEP line that
MOVES is still matched (snippet substring); a line whose content CHANGES
stops matching (so a snippet can never silently cover a different/new
contamination). This is the measure-then-bound discipline: the allowlist
admits the measured legitimate set and nothing broader.

---

## 4. Advisory-length derivation per doc (measure-then-bound, NOT round)

Each doc's advisory ceiling = `ceil(measured_lines * 1.15)` — the doc's
actual post-C4/C9 cleaned line count plus a uniform 15% growth headroom.
These are per-doc, non-round, content-derived numbers (NOT a single round
cap). Advisory only: exceeding it emits an OK-notice, never a failure
(ARCHITECTURE §6 "SC1 limits": enforcing limit = 0-outside-allowlist;
length is per-doc advisory).

| Doc | measured lines (HEAD 60ec0db) | advisory ceiling = ceil(measured × 1.15) | over ceiling at HEAD? |
|---|---|---|---|
| BOUNDARY-DEFINITION.md | 135 | 156 | no |
| CONCEPTUAL-REVIEW-METHODOLOGY.md | 298 | 343 | no |
| DRY-RUN-MIGRATION.md | 199 | 229 | no |
| HELP-FRAGMENT-PACK.md | 42 | 49 | no |
| HELP-FRAGMENT-TRACKER.md | 49 | 57 | no |
| MERGE-STRATEGY.md | 484 | 557 | no |
| OPTIONAL-FEATURES.md | 235 | 271 | no |

All 7 docs are at-or-under their derived ceilings → no advisory notice
fires at HEAD. The derivation is shown in code via a comment block in
`_CHECK_44_DURABLE_DOCS` and reproduced here.

---

## 5. The four ENCODING surfaces — lock-step evidence

The M4 gate's expected state is encoded across FOUR surfaces; all four
landed in this commit (asymmetry would fail Check 42 AND create an audit
gap per the enumerate-ENCODING-surfaces rule):

| # | Surface | Change type | Evidence |
|---|---|---|---|
| (a) | `check_durable_doc_concision` function in `scripts/validate-pack.py` | NEW (+ `_check_44_load_allowlist` helper + `_CHECK_44_FORBIDDEN_PATTERNS` + `_CHECK_44_DURABLE_DOCS` module consts) + `main()` callsite after the Check 46 callsite | function imports + runs; callsite emits "── Check 44: M4 durable-doc concision gate (BD-196) ──" |
| (b) | `pack-ops/.concision-allowlist.txt` it reads | NEW | 6 KEEP records; read via `_parse_manifest_records` (shared w/ Check 46) |
| (c) | `scripts/tests/test-validate-pack-check-44.sh` | NEW (chmod +x) | 3 test groups, T1–T5; passes 3/3 |
| (d) | CI wiring line in `.github/workflows/validate-pack.yml` | NEW step (placed before the Check 45 step, grouping BD-196 checks 44/45/46) | Check 42 = 13/13 (13 disk tests, 13 workflow invocations) |

**Edit-in-place proof (validate-pack.py):** the new function + consts were
inserted between the Check 46 `ok()` tail and the `# ── Main` banner; the
callsite was inserted between `check_boundary_and_spawn_pointer_manifests()`
and the `print("\n" + "=" * 60)` summary. No existing check function or
callsite was modified. Confirmed by: full validate-pack still runs ALL prior
checks (1–43, 45, 46) and exits 0; neighbor tests 45/46/42/32-33-34 all green
(see §7). The module docstring "Checks:" inventory was NOT extended — this
FOLLOWS the C3/C6 precedent (Check 45 + Check 46 were added without docstring-
inventory entries; the inventory is not kept in lock-step with new check IDs).
Matching that precedent avoids introducing a divergent convention; noted here
for reviewer awareness.

---

## 6. test-44 assertions

`scripts/tests/test-validate-pack-check-44.sh` mirrors the test-45/46
structure (Group 0 import, Group 1 synthetic-tree end-to-end, Group 2 HEAD
exit-status). The Group 1 cases cover the three required assertions plus two
defensive cases:

- **T1 — clean tree PASSES:** a synthetic durable doc with no forbidden
  pattern → 0 failures + the "0 = clean" OK message.
- **T2 — injected STRIP hit OUTSIDE allowlist FAILS (the teeth):** a date
  (`2026-05-30`) injected into the doc with NO allowlist → ≥1 failure +
  "OUTSIDE the allowlist" + the offending line named.
- **T3 — allowlisted occurrence PASSES:** an operational `will` line covered
  by a snippet allowlist record → 0 failures + "1 allowlisted" count.
- **T4 — over-ceiling ADVISORY is SOFT:** a doc exceeding a tight per-doc
  ceiling but with NO forbidden pattern → emits "ADVISORY:" notice and does
  NOT fail (proves length is advisory, not a hard rule).
- **T5 — KEEP-only allowlist is NOT a blanket:** a SHA (`deadbeef1234`)
  injected on a doc whose only allowlist record is a `will` snippet → still
  FAILS (proves the allowlist covers exactly its snippet-matched lines, not
  the whole doc — measure-then-bound teeth).

The test monkeypatches `_CHECK_44_DURABLE_DOCS` to a single synthetic doc
inside a tmp `REPO_ROOT`, saves/restores module state on every exit path,
and cleans up its tmpdir (no real pack-ops doc is mutated).

---

## 7. Verification results

**Full validate-pack:**
```
$ python3 scripts/validate-pack.py
...
── Check 44: M4 durable-doc concision gate (BD-196) ──
  OK: Check 44 — 7 durable doc(s) scanned; 0 forbidden pattern(s) outside the allowlist (0 = clean); 6 allowlisted operational occurrence(s) admitted (KEEP set).
============================================================
PASSED — all checks clean
EXIT: 0
```

**test-44:** `PASS: 3 / FAIL: 0` — "All tests passed." (Group 0 import +
symbols; Group 1 T1–T5; Group 2 HEAD exit-status clean).

**Check 42 (CI-wiring guard) = 13/13:**
```
  OK: Check 42 — 13 per-check test file(s) on disk; 13 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.
```
(disk count `ls scripts/tests/test-validate-pack-check*.sh | wc -l` = 13;
workflow invocation count = 13.)

**Neighbor per-check tests:**
- `test-validate-pack-check-42.sh` → PASS 4 / FAIL 0
- `test-validate-pack-check-45.sh` → PASS 3 / FAIL 0
- `test-validate-pack-check-46.sh` → PASS 3 / FAIL 0
- `test-validate-pack-checks-32-33-34.sh` → PASS 65 / FAIL 0 (shares the
  set-compare/manifest-parse pattern family)

**Live-tree M4=0-outside-allowlist grep-proof (the C10 PREFLIGHT obligation,
v1 EE-5 coder obligation):** an INDEPENDENT Python re-scan (not the
validator) over the 7 M4 docs applying the canonical forbidden-pattern set
and the authored allowlist:
```
FORBIDDEN-PATTERN HITS OUTSIDE ALLOWLIST = 0
ALLOWLISTED (KEEP) OCCURRENCES = 6
```
This matches Check 44's own output (0 outside / 6 KEEP), proving the gate
runs clean against the actual live tree.

**Manifest regen (v11-surface trigger: `scripts/` + `pack-ops/` touched):**
`bash test-fixtures/build.sh --all --clean` → exit 0; `git diff
test-fixtures/manifest.txt` → **EMPTY** (no fixture row changes — the
allowlist + tests + validator are not installed by init-project.sh, as EE-P1
anticipated). Nothing to stage for the manifest.

---

## 8. Coverage-bound disclosure (no silent caps)

Per "No silent caps" — explicit logging of what the gate does and does NOT
cover, so nothing reads as "covered everything":

- **Doc-set scope:** the gate covers EXACTLY the 7 M4-class durable docs
  (§1). It does NOT scan PACK-AGENTS / PACK-CHAT (those carry their own
  `will` occurrences governed by Check 46 / §9.6, not M4), nor the
  regenerated mirrors BACKLOG.md / CHANGELOG.md, nor any other pack-ops doc.
- **Enforcement split:** the forbidden-pattern count (0-outside-allowlist)
  is HARD-FAIL teeth. The per-doc length ceiling is ADVISORY (OK-notice,
  never fails) — by design (ARCHITECTURE §6). A doc can grow past its
  ceiling without failing CI; the advisory is a smell signal only.
- **Allowlist coverage:** sized to the 6 KEEP operational `will` lines
  exactly. STRIP-class patterns have ZERO allowlist entries — any future
  date/SHA/Commit-N/Override-N/post-Commit appearance in any of the 7 docs
  FAILS by definition (no widening escape hatch).

---

## 9. Full file contents (NEW files — for re-apply without re-derivation)

### 9.1 `pack-ops/.concision-allowlist.txt`

```
# .concision-allowlist.txt — M4 concision-gate allowlist (BD-196 C10)
#
# The M4 concision gate (Check 44, scripts/validate-pack.py
# check_durable_doc_concision) scans the 7 durable pack-ops/ non-mirror
# rule docs for FORBIDDEN PATTERNS that belong in agent reports, NOT in
# forward-only durable rule docs (per ARCHITECTURE-DOC-CONCISION-
# GUARDRAILS.md §6 M4 + the C2 surface-separation rule):
#
#   - dates           20[0-9]{2}-[0-9]{2}-[0-9]{2}
#   - 7-40-hex SHAs    \b[0-9a-f]{7,40}\b
#   - Commit N         Commit [0-9]
#   - Override N       Override [0-9]
#   - post-Commit      post-Commit
#   - temporal 'will'  \bwill (the C4/C9 canonical probe form `\bwill `)
#
# THE TEETH: forbidden-pattern count = 0 OUTSIDE this allowlist. A hit on
# any line NOT listed here FAILS the gate. This allowlist is sized to the
# KEEP set EXACTLY (measure-then-bound, ARCHITECTURE §6 SC1 + CLAUDE.md
# "CI guard design — measure-then-bound"): every entry is a MEASURED,
# legitimate operational-behavioral occurrence — NOT a contamination hit
# widened in to make the gate pass.
#
# KEEP basis (the only legitimate residue): operational-behavioral 'will'
# — a 'will' that describes what a shipped pack mechanism DOES (migrator
# routing, recommendation-system behavior, dry-run harness output), NOT a
# temporal/roadmap 'will' (which is STRIP-class and was cleaned in C4/C9).
# STRIP-class patterns (dates / SHAs / Commit N / Override N / post-Commit)
# have ZERO legitimate KEEP residue across all 7 docs — none are
# allowlisted; any future appearance is contamination by definition.
#
# Re-measured at HEAD 60ec0db (BD-196 C10) against the post-C4/C9 tree:
# 6 KEEP entries; STRIP-class = 0 outside the allowlist. See
# maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C10.md
# for the full measure→categorize table.
#
# FORMAT: one allowlisted occurrence per record, blank-line separated.
#   doc:      pack-ops/<file>.md         (path relative to repo root)
#   pattern:  the forbidden-pattern class this occurrence matches (will)
#   snippet:  a stable substring of the allowlisted line (anchors the
#             entry to its content, so a line that MOVES is still matched
#             by content and an entry whose content CHANGES stops matching
#             — line numbers are NOT used as the key because they drift)
#   reason:   why this occurrence is legitimate (operational, not temporal)
#
# The check matches an occurrence to an allowlist record when the doc
# matches AND the record's `snippet` is a substring of the offending line.
# Line numbers are intentionally absent from the key (they drift); the
# snippet is the stable anchor.

doc: pack-ops/DRY-RUN-MIGRATION.md
pattern: will
snippet: It will say a sidecar
reason: operational — describes the dry-run harness's output behavior (what it reports), not a roadmap promise.

doc: pack-ops/DRY-RUN-MIGRATION.md
pattern: will
snippet: the exact state the real run will start from
reason: operational — describes the recovery-procedure starting state, not a roadmap promise.

doc: pack-ops/MERGE-STRATEGY.md
pattern: will
snippet: will route through `pack-script` 3-way text dispatch
reason: operational — describes how the migrator routes a project-added script, not a roadmap promise.

doc: pack-ops/MERGE-STRATEGY.md
pattern: will
snippet: not present in the pack repo will hit
reason: operational — describes the three-way classification outcome, not a roadmap promise.

doc: pack-ops/OPTIONAL-FEATURES.md
pattern: will
snippet: provider abstraction the agent will consume but not the agent file
reason: operational — describes what the shipped provider abstraction is consumed by, not a roadmap promise.

doc: pack-ops/OPTIONAL-FEATURES.md
pattern: will
snippet: The recommendation system will not nag in this regime
reason: operational — documents recommendation-system behavior in the low-BD-volume regime, not a roadmap promise.
```

### 9.2 `scripts/tests/test-validate-pack-check-44.sh`

The test file is reproduced verbatim in the worktree at
`scripts/tests/test-validate-pack-check-44.sh` (executable, 11700 bytes).
Its structure mirrors `test-validate-pack-check-45.sh`: a bash harness with
`t_pass`/`t_fail`, a Group 0 Python import-and-symbol probe, a Group 1
heredoc Python block defining `run_check_with_synthetic()` (which monkeypatches
`mod._CHECK_44_DURABLE_DOCS` and `mod.REPO_ROOT` to a tmp tree, runs
`check_durable_doc_concision`, restores state, and cleans up), the five
synthetic cases T1–T5 (§6), and a Group 2 HEAD exit-status block asserting
the gate runs clean. (Full body omitted from this report for length — it is
on disk and re-derivable from the §6 assertion list + the test-45 template;
it was authored, made executable, and verified PASS 3/3.)

---

## 10. Plan deviations

**ZERO plan deviations.** Every C10 file in the plan §3 file list was
created/edited exactly as specified:
- `scripts/validate-pack.py` — added `check_durable_doc_concision` (Check 44)
  + callsite after Check 46 (plan says "after Check 42/45/46"; Check 46 is the
  last of those, so after-46 satisfies it).
- `pack-ops/.concision-allowlist.txt` — NEW, sized to KEEP-only (6).
- `scripts/tests/test-validate-pack-check-44.sh` — NEW.
- `.github/workflows/validate-pack.yml` — wired (Check 42 → 13/13).

The §1 M4-class disambiguation (7 docs via the authoritative probe line) and
the §5 docstring-inventory-not-extended decision (matching C3/C6 precedent)
are implementation observations within the plan's intent, not deviations.

---

## 11. New POQs introduced

**None.** No architecture gap surfaced. The EE-P1 "9 docs listed under a
'7' label" wording ambiguity was resolved against the authoritative probe
line (§1) without needing a design change.

---

## 12. Definition-of-Done checklist

| DoD item | Status | Evidence |
|---|---|---|
| Check 44 runs clean (0-outside-allowlist) against the live tree | PASS | Check 44 OK: "0 forbidden ... (0 = clean); 6 allowlisted"; independent grep-proof = 0 outside / 6 KEEP |
| Full `validate-pack.py` exit 0 | PASS | "PASSED — all checks clean"; EXIT: 0 |
| `test-validate-pack-check-44.sh` passes | PASS | PASS 3 / FAIL 0 |
| Check 42 CI-wiring guard = 13/13 | PASS | "13 per-check test file(s) on disk; 13 workflow invocation(s); zero unwired" |
| Neighbor per-check tests still pass | PASS | 42→4/0, 45→3/0, 46→3/0, 32-33-34→65/0 |
| Allowlist sized to exactly the KEEP set (no wider) | PASS | 6 records = 6 KEEP occurrences; 0 STRIP-class entries |
| Advisory lengths derived + shown | PASS | §4 table — ceil(measured×1.15) per doc, non-round |
| measure-then-bound: STRIP=0, no route-back, no widening | PASS | §2 STRIP-class proof = 0 all 7 docs |
| Four ENCODING surfaces in lock-step | PASS | §5 table — function/allowlist/test/CI all landed |
| Manifest regen reported | PASS | build exit 0; diff EMPTY (§7) |
| No state-changing git verbs | PASS | only `git rev-parse`/`status`/`diff` (read-only) |
| No out-of-scope edits | PASS | git status = exactly the 4 in-scope files |
| Filename uniqueness confirmed | PASS | both new names: `find` returned empty (pre-flight) |

All DoD items PASS.

---

## 13. Files changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (added Check 44 function + helper + 2 module consts + `main()` callsite; existing checks untouched) |
| `pack-ops/.concision-allowlist.txt` | new |
| `scripts/tests/test-validate-pack-check-44.sh` | new (executable) |
| `.github/workflows/validate-pack.yml` | modified (added Check 44 test wiring step) |

`test-fixtures/manifest.txt` — regenerated, NO diff (not staged).

Scope: all changes are `pack-only` (no `project-template/` or
`supporting-docs/` touched) — consistent with the C10 plan scope.

---

## 14. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| CI-guard measure-then-bound (LOAD-BEARING) | (1) MEASURED the live tree: §2 occurrence table over all 7 M4 docs. (2) CATEGORIZED: 6 KEEP `will` / 0 STRIP. (3) STRIP-class probe = "STRIP=0" on every doc → no route-back. (4) Allowlist = 6 records = KEEP set exactly. (5) Post-wire gate runs clean: Check 44 "0 forbidden ... outside the allowlist" + independent grep-proof "OUTSIDE ALLOWLIST = 0". | COMPLIANT |
| No silent caps | §8 logs doc-set scope (7 only), enforcement split (hard teeth vs soft advisory), allowlist coverage (6 KEEP, 0 STRIP entries). §4 advisory derivation = `ceil(measured×1.15)` per-doc, NOT round. | COMPLIANT |
| Enumerate ENCODING surfaces | §5 table: all 4 surfaces (function / allowlist / test / CI line) landed in lock-step; Check 42 13/13 proves no asymmetry. | COMPLIANT |
| Filename uniqueness heuristic | Pre-flight `find . -name ".concision-allowlist.txt"` and `find . -name "test-validate-pack-check-44.sh"` (excl. .git) both EMPTY → no collision. | COMPLIANT |
| Edit-in-place, not full rewrite | validate-pack.py: targeted Edit inserting function between Check 46 tail and `# ── Main`; callsite Edit between `check_boundary_and_spawn_pointer_manifests()` and summary. Existing checks 1–43/45/46 still run + exit 0; CI workflow wiring used a single inserted step. | COMPLIANT |
| Regenerate manifest on v11-surface commits | `scripts/` + `pack-ops/` touched → `bash test-fixtures/build.sh --all --clean` exit 0; `git diff test-fixtures/manifest.txt` EMPTY; reported (not staged). | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted with M4=0-outside-allowlist live grep-proof AFTER all edits + verification PASS. No stop signal received. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Pack-repo code-comment deferrals | No deferral markers introduced in validate-pack.py (all C10 work completed; no `# TODO`/`# FIXME`). | N/A: no deferrals introduced |
| Agents never commit | Only read-only git verbs (`git rev-parse`/`status`/`diff`/`diff --stat`) run; no `git add`/`commit`/etc. | COMPLIANT |
| Per-action approval / no destructive ops | No `rm -rf`/`git rm`/trusted-file overwrite; only Write to NEW paths + Edit to in-scope files; `chmod +x` on the new test (non-destructive). | COMPLIANT |
| No deferral (deferral IS scope creep) | All 4 in-scope C10 files completed now; nothing deferred. | COMPLIANT |
| STOP-MEANS-STOP | No stop/halt/revert signal received during the session. | N/A: no stop signal |

End of IMPLEMENTATION-REPORT-BD-196-C10.md.
