# IMPL-REPORT — BD-214 C3 review fixes (FIX1)

**Agent:** fresh pack-coder (fix-coder). **Date:** 2026-06-13.
**Branch:** `v11-dev`. **Pre-flight HEAD:** `c994d82cdab77c3ebddabe1c4db6b56d50454201`.
**Final HEAD (worktree, uncommitted — coder never commits):** `c994d82cdab77c3ebddabe1c4db6b56d50454201`.
**Scope:** exactly the five approved C3 review fixes (B-1, M-1, S-1, Item-2, N-1).
Out-of-scope items NOT touched: the 93-doc deletion (C4), backlog entry re-scopes
(C5a/C5b), C3's other pre-existing edits, `backlog/BD-214.md`.

`PREFLIGHT: 5/5 fixes complete; project-template BD-214 count=0; FULL CI wired-test job verified locally; HEAD c994d82cdab77c3ebddabe1c4db6b56d50454201; about to Write IMPL-REPORT`

---

## Summary table

| Fix | Severity | Status | Verification |
|---|---|---|---|
| B-1 | BLOCKER | DONE | `git grep -c 'BD-214' -- project-template/` → exit 1 (0 matches) |
| M-1 | MUST | DONE | `test-migrator-core.sh` EXIT=0 (assertion strengthened to `!=`) |
| S-1 | SHOULD | DONE | `test-init-project.sh` EXIT=0 (banner substring preserved) |
| Item-2 | (review item) | DONE | comment-only; `py_compile` OK; `check-51` EXIT=0 |
| N-1 | NIT | DONE | `check-40.sh` EXIT=0 (disambiguation anchor preserved) |

Full CI wired-test battery (both jobs): **62 run-steps, 0 failures.** See "CI verification" below.

---

## Fix B-1 (BLOCKER) — remove `BD-214` token from client-shipped `project-template/` content

**Goal:** strip every internal pack BD citation from client-shipped prose while KEEPING the
deferral meaning. Reword "(BD-214)" / "— BD-214" / ", BD-214" → "to a future release" or drop
the trailing token, never delete the deferral sentence.

**21 occurrences across 13 files — all reworded:**

| File | Lines (pre) | Before token | After |
|---|---|---|---|
| `project-template/.claude/skills/pm-startup/SKILL.md` | 86, 212, 219 | `deferred — BD-214.` / `DEFERRED — BD-214)` / `DEFERRED (BD-214):` | `deferred to a future release.` / `DEFERRED to a future release)` / `DEFERRED to a future release:` |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 86, 212, 219 | (same 3) | (same 3) |
| `project-template/.gemini/commands/pm-startup.toml` | 83, 209, 216 | (same 3) | (same 3) |
| `project-template/skills/pm-startup/SKILL.md` | 86, 212, 219 | (same 3) | (same 3) |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 4, 38 | `release version** (BD-214).` / `DEFERRED (BD-214) — each` | `release version**.` / `DEFERRED — each` |
| `project-template/docs/pack/HELP-FRAGMENT.md` | 25 | `deferred (BD-214); the verbs` | `deferred; the verbs` |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | 112 | `(no release version), BD-214.` | `(no release version).` |
| `project-template/docs/pack/PM-CHAT.md` | 508, 587 | `DEFERRED (BD-214):` / `deferred — BD-214).` | `DEFERRED to a future release:` / `deferred to a future release).` |
| `project-template/docs/pack/prompts/auditor.md` | 51 | `deferred — BD-214.)` | `deferred to a future release.)` |
| `project-template/docs/pack/prompts/coder.md` | 69 | `is deferred — BD-214.)` | `is deferred to a future release.)` |
| `project-template/docs/project/backlog/_intro.md` | 44 | `(no release version, BD-214);` | `(no release version);` |
| `project-template/docs/project/changelog/_intro.md` | 48 | `(no release version, BD-214);` | `(no release version);` |
| `project-template/docs/project/implementation-plan/_intro.md` | 53 | `(no release version, BD-214);` | `(no release version);` |

In every case the deferral semantics (tracker deferred indefinitely / no release version /
flat-file is the sole supported mode / code retained dormant) are PRESERVED — only the
internal `BD-214` citation is removed. No deferral sentence was deleted.

**Completeness proof:**
```
$ git grep -c 'BD-214' -- project-template/
$ echo $?
1            # exit 1 = zero matches across all project-template/ files
```

**No new pack-self leak introduced (Rule 3):**
```
$ git grep -nE 'BD-[0-9]|pack-ops/|maintenance-docs/' -- project-template/
```
Remaining hits are all PRE-EXISTING deny-list CONTENT (the project trinity § "Project
SSOT-first" deny-list, `prompts/coder.md`/`reviewer.md` boundary-discipline deny-lists, and
the `boundary-investigation` skill's canonical deny-list) — these files legitimately
ENUMERATE pack-only paths (`pack-ops/`, `maintenance-docs/`, pack-* names) as the surfaces a
project must NOT reference. My edits added ZERO new `BD-`/`pack-ops/`/`maintenance-docs/`
tokens — they only removed `BD-214` tokens.

**Out-of-scope confirmation:** `BD-214` references in `supporting-docs/`, `scripts/`,
`pack-ops/HELP-FRAGMENT-TRACKER.md`, and `backlog/BD-214.md` were NOT touched (those surfaces
legitimately carry pack BD citations).

---

## Fix M-1 (MUST) — stale install-surface ground truth in `migrator-core.sh`

**Goal:** `migrator_target_surface_for_version v11` still listed `tracker.toml.example` as a
path a v11 install creates; per C3 the install no longer ships it. Remove it; update the test
that pinned the stale value; keep the assertion real.

**`scripts/lib/migrator-core.sh` — v11 case (`migrator_target_surface_for_version`):**
- Removed the `tracker.toml.example` line from the heredoc list.
- Updated the inline comment: dropped `tracker.toml` from the "adds the v11-specific surfaces"
  list and added an explicit note: *"tracker.toml.example is NOT listed: a v11 install no
  longer creates it (tracker integration is deferred; flat-file is the sole supported mode)."*

Post-fix v11 surface list:
```
CLAUDE.md / AGENTS.md / GEMINI.md / .claude/agents / .codex/agents / .gemini/agents
/ .codex/config.toml / BACKLOG.md / docs/pack/HELP-FRAGMENT.md
/ .github/ISSUE_TEMPLATE/work-item.yml / .claude/skills/pack-help/SKILL.md
/ .codex/skills/pack-help/SKILL.md / .gemini/commands/pack-help.toml
```

**`scripts/test-migrator-core.sh` (test 15, lines ~391/396) — strengthened, not weakened:**
- Line 391 flipped from `&& "$out" == *"tracker.toml.example"*` (assert PRESENT, stale) to
  `&& "$out" != *"tracker.toml.example"*` (assert ABSENT — a REAL positive assertion that the
  deferred flip material is gone). This mirrors the v10 test (line 370) which already asserts
  v10 excludes `tracker.toml.example`.
- Pass message updated to: *"v11 surface inherits v10 + adds HELP-FRAGMENT/ISSUE_TEMPLATE/
  per-CLI pack-help; excludes deferred tracker.toml.example"*.

**Verification:** `bash scripts/test-migrator-core.sh` → **EXIT=0** (the `!=` assertion passes
against the corrected `migrator_target_surface_for_version v11` output — confirming the test
exercises the real data, not a weakened check).

---

## Fix S-1 (SHOULD) — S11 stage banner in `init-project.sh`

**Goal:** the S11 banner still advertised "tracker"; reword to drop the tracker advertisement
(consistent with the install no longer shipping tracker materials).

**`scripts/init-project.sh` line 911:**
- Before: `say "── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──"`
- After:  `say "── S11 — v11 client artifacts (HELP-FRAGMENT, issue forms, pack-help) ──"`

"tracker" removed from the advertised-artifact list. ("issue forms" stays — the dormant
work-item form family is still installed per C3 design §5; only `tracker.toml.example` stopped
installing.)

**Encoding-surface check:** `scripts/tests/test-init-project.sh:150` matches only the
substring `"S11 — v11 client artifacts"`, which is preserved — no test breakage.

**Verification:** `bash scripts/tests/test-init-project.sh` → **EXIT=0**.

---

## Fix Item-2 — Check 51 leg-3 maintenance guard comment (`validate-pack.py`)

**Goal:** add a code comment instructing that any FUTURE CLI-surface addition (a new
skill/command dir hosting `recommendation_should_recommend`) MUST be added to the leg-3
directory tuple, else the bounded guard develops a blind spot. Comment only — no logic change.

**`scripts/validate-pack.py` — above `_CHECK_51_RECOMMEND_SKILL_DIRS`:** added an 11-line
`# MAINTENANCE GUARD:` comment explaining that the tuple is the EXHAUSTIVE set of CLI-surface
skill/command directories leg 3 scans; because the leg is a bounded scan (not a whole-tree
rglob), any future per-CLI skill/command directory that can host
`recommendation_should_recommend` MUST be added here, otherwise a re-armed recommendation
invoker on the new surface passes the guard undetected. The tuple values are UNCHANGED.

**No-logic-change proof:** `python3 -c "import py_compile; py_compile.compile(...)"` → OK;
`bash scripts/tests/test-validate-pack-check-51-flip-block.sh` → **EXIT=0** (legs 1–5 still
pass identically).

---

## Fix N-1 (NIT) — awkward "at a client project root" stub phrasing

**Goal:** fix the awkward phrasing in the deferred-stub text the reviewer flagged.

**Location:** `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` line 54 (the shipped client
stub). The phrase read as if `tracker.toml.example` currently exists at a client root, but a
v11 install no longer creates it.

- Before: `The tracker example template (\`tracker.toml.pack-example\` in the pack repo, or \`tracker.toml.example\` at a client project root) is the dormant config record ...`
- After:  `The tracker example template (\`tracker.toml.pack-example\` in the pack repo; a new install no longer copies a \`tracker.toml.example\` into the project root) is the dormant config record ...`

**Check-40 anchor preserved:** the bare ref `tracker.toml.example` requires the
pack-vs-project disambiguation anchor `"in the pack repo"` within ±2 lines
(`_DENY_LIST_ANCHOR_PHRASES` / `_context_has_anchor` in `validate-pack.py`). That anchor is
on the SAME line and is retained, so Check 40 still classifies the ref LEGITIMATE.

**Scope note:** the `pack-ops/HELP-FRAGMENT-TRACKER.md` copy is a SEPARATE artifact (pack-side,
different verb set, retains its BD-214 ref legitimately, and has no "at a client project root"
line) — out of scope, not touched. The Check-40 test fixture (`test-validate-pack-check-40.sh`
T2) and the two boundary fixtures use their own synthetic copies of the phrasing — not the
shipped stub — so they were not touched and still pass.

**Verification:** `bash scripts/tests/test-validate-pack-check-40.sh` → **EXIT=0**.

---

## Manifest regeneration (Rule 5)

`project-template/` + `scripts/` were touched → ran `bash test-fixtures/build.sh --all --clean`
(exit 0). The manifest diff is NON-EMPTY (expected — project-template prose changed):

```
test-fixtures/manifest.txt | 6 +++---
-v11-realistic-ot  ae3fc6ff...   +v11-realistic-ot  685169ef...
-v11-flat-file     f9705c27...   +v11-flat-file     1d396090...
-v11-tracker-on    944ddee3...   +v11-tracker-on    d1430225...
```

Left regenerated and staged for the commit. `bash test-fixtures/build.sh --verify` → EXIT=0
(rebuilt tree matches the regenerated manifest).

---

## CI verification (Rule 4 — FULL suite, no sampling)

Extracted all `run:` steps from `.github/workflows/validate-pack.yml` (62 total; jobs
`validate` + `tests`). Ran every test/validate command. The two non-test steps skipped are
`pip install pyyaml` (×2, env setup; pyyaml already present locally) and
`git checkout HEAD -- test-fixtures/manifest.txt` (a forbidden git verb for this role AND a
CI-internal manifest-restore no-op, not a test — replaced by direct `--verify`).

**`validate` job:**
| Step | EXIT |
|---|---|
| `python3 scripts/validate-pack.py` | 0 |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | 0 |

**`tests` job — all EXIT=0:**
```
test-detect.sh                                  0
tracker-provider-test.sh                        0
tracker-config-test.sh                          0
tracker-init-test.sh                            0
tracker-agent-read-test.sh                      0
tracker-migrate-forward-test.sh                 0
tracker-migrate-reverse-test.sh                 0
tracker-migrate-roundtrip-test.sh              0
test-tracker-phase-task.sh                       0
test-tracker-links.sh                            0
test-tracker-cycle-check.sh                      0
tracker-errors-test.sh                           0
tracker-config-schema-test.sh                    0
recommendation-state-schema-test.sh             0
test-per-entry.sh                                0
test-validate-pack-checks-32-33-34.sh            0   (Check 34 cross-ref — B-1 BD removal: no dangling-ref regression)
test-validate-pack-checks-36-37-38.sh            0
test-validate-pack-check-39.sh                   0
test-validate-pack-check-40.sh                   0   (N-1 disambiguation)
test-validate-pack-check-41.sh                   0
test-validate-pack-check-18.sh                   0
test-validate-pack-check-16.sh                   0
test-validate-pack-check-19.sh                   0
test-validate-pack-check-42.sh                   0
test-validate-pack-check-43.sh                   0
test-validate-pack-check-44.sh                   0
test-validate-pack-check-45.sh                   0
test-validate-pack-check-46.sh                   0
test-validate-pack-check-removed-doc-advisory.sh 0
test-validate-pack-check-49-field-faithfulness.sh 0
test-validate-pack-check-50-codec-single-source.sh 0
test-validate-pack-check-51-flip-block.sh        0   (Item-2; legs 1-5)
tracker-deferral-gate-test.sh                    0
tracker-bd129-gh-repo-test.sh                    0
tracker-bd130-doctor-wired-test.sh               0
tracker-bd132-race-test.sh                       0
tracker-bd133-header-preservation-test.sh        0
tracker-bd134-close-retry-test.sh                0
recommendation-test.sh                           0
pack-help-test.sh                                0   (fragment-content pin — S-1/N-1/B-1 frag edits)
test-customization-preserve.sh                   0
test-init-project.sh                             0   (S-1)
test-migrate-v10-to-v11.sh                       0
test-migrate-v10-to-v11-dry-run.sh               0
test-migrate-v10-to-v11-gates.sh                 0
test-migrate-v10-to-v11-decompose.sh             0
test-migrator-core.sh                            0   (M-1)
test-migrator-manifest.sh                        0
test-migrator-capability-translation.sh          0
build.sh --verify                                0
test-v11-realistic-ot.sh                         0   (integration)
test-migrator-skills.sh                          0
test-persona-contracts.sh                        0
template-translations-test.sh                    0
template-version-test.sh                          0
test-issue-forms.sh                              0
```

**Result: 0 failures across the full wired battery.** Zero regressions.

Additional sanity: `py_compile validate-pack.py` OK; `bash -n` on `migrator-core.sh`,
`init-project.sh`, `test-migrator-core.sh` all OK.

---

## Files changed inventory (this session)

| Path | Change type | Fix |
|---|---|---|
| `project-template/.claude/skills/pm-startup/SKILL.md` | modified | B-1 |
| `project-template/.codex/skills/pm-startup/SKILL.md` | modified | B-1 |
| `project-template/.gemini/commands/pm-startup.toml` | modified | B-1 |
| `project-template/skills/pm-startup/SKILL.md` | modified | B-1 |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | modified | B-1 + N-1 |
| `project-template/docs/pack/HELP-FRAGMENT.md` | modified | B-1 |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified | B-1 |
| `project-template/docs/pack/PM-CHAT.md` | modified | B-1 |
| `project-template/docs/pack/prompts/auditor.md` | modified | B-1 |
| `project-template/docs/pack/prompts/coder.md` | modified | B-1 |
| `project-template/docs/project/backlog/_intro.md` | modified | B-1 |
| `project-template/docs/project/changelog/_intro.md` | modified | B-1 |
| `project-template/docs/project/implementation-plan/_intro.md` | modified | B-1 |
| `scripts/lib/migrator-core.sh` | modified | M-1 |
| `scripts/test-migrator-core.sh` | modified | M-1 |
| `scripts/init-project.sh` | modified | S-1 |
| `scripts/validate-pack.py` | modified | Item-2 |
| `test-fixtures/manifest.txt` | modified (regenerated) | Rule 5 |

**NOT touched by this session** (pre-existing C3 working-tree changes, left as-is): `backlog/BD-214.md`,
`project-template/{CLAUDE,AGENTS,GEMINI}.md` (no BD-214 token; C3 prose changes), `project-template/docs/pack/prompts/{pm-chat,reviewer,tester}.md`, `scripts/migrate-v10-to-v11.sh`, `scripts/persona-contracts/contract-{greenfield,migration}.sh`, `scripts/tests/{pack-help-test,test-init-project,test-migrate-v10-to-v11,test-validate-pack-check-51-flip-block}.sh`, `supporting-docs/{DEPENDENCIES,METHODOLOGY,MIGRATION-v10-to-v11}.md`.

---

## Plan deviations

None. All five fixes implemented exactly as scoped. No out-of-scope file required.

## New POQs introduced

None.

## Boundary discipline check (P-missed-7)

Project-side edits in this session: the 13 `project-template/` files (B-1) + the
`HELP-FRAGMENT-TRACKER.md` stub (N-1). For each, the concept changed is "tracker-deferral
prose wording." Project-side SSOT investigation: the deferral concept on project-side
surfaces is carried by the shipped prose itself (HELP-FRAGMENT-TRACKER / OPTIONAL-FEATURES /
PM-CHAT / pm-startup / _intro stubs) — there is no project-side SSOT FILE that these reference
for the wording; they ARE the deliverable prose. The fix REMOVES a pack-only artifact (the
`BD-214` internal citation) from these client surfaces and replaces it with surface-correct
client prose ("to a future release" / "no release version"). No pack-only reference
(`pack-ops/`, `maintenance-docs/`, pack-* name, `Pack Chat`, BD-NNN) was ADDED to any
project-side surface — verified by the Rule-3 grep above. This is the correct direction for
P-missed-7: stripping pack-self leakage OUT of client-shipped content, never importing it.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| B-1: `git grep -c 'BD-214' -- project-template/` == 0 | PASS (exit 1, 0 matches) |
| B-1: deferral meaning preserved in every reworded occurrence | PASS |
| B-1: no `BD-214` touched outside `project-template/` | PASS |
| M-1: `tracker.toml.example` removed from v11 surface list | PASS |
| M-1: test assertion corrected + REAL (`!=`, not weakened) | PASS (test EXIT=0) |
| S-1: S11 banner tracker advertisement removed | PASS |
| Item-2: leg-3 maintenance-guard comment added (comment-only) | PASS (py_compile OK, check-51 EXIT=0) |
| N-1: awkward stub phrasing fixed, Check-40 anchor preserved | PASS (check-40 EXIT=0) |
| Rule 5: manifest regenerated + staged | PASS |
| Rule 4: FULL CI wired battery (62 steps) green | PASS (0 failures) |
| No git state change performed | PASS (read-only git only) |

---

## Rules-Applied Verification Block

| # | Rule | Evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Only `git rev-parse HEAD`, `git status`, `git grep`, `git diff` were run. No `git add/commit/push/tag/checkout`. Final HEAD unchanged: `c994d82cdab77c3ebddabe1c4db6b56d50454201`. | COMPLIANT |
| 2 | Real fixes only — no band-aids | B-1 kept the deferral sentence in all 21 occurrences (table above), only removed the BD token. M-1 strengthened the test from `== *"tracker.toml.example"*` to `!= *"tracker.toml.example"*` (a positive ABSENCE assertion, test EXIT=0). No check/assertion weakened. | COMPLIANT |
| 3 | No-pack-self-in-project / P-missed-7 | `git grep -nE 'BD-[0-9]\|pack-ops/\|maintenance-docs/' -- project-template/` returns only PRE-EXISTING deny-list CONTENT (trinity SSOT-first lists + boundary-investigation skill); my edits added zero new pack-self tokens and removed all `BD-214`. | COMPLIANT |
| 4 | Verify FULL CI suite, no sampling | Extracted 62 `run:` steps from validate-pack.yml; ran all test/validate commands incl. integration `test-v11-realistic-ot.sh`, Check 34, Check 40, Check 51 (legs 1-5), test-migrator-core, test-init-project, pack-help-test. All EXIT=0 (tables above). | COMPLIANT |
| 5 | Regenerate manifest on v11-surface commits | `bash test-fixtures/build.sh --all --clean` exit 0; `git diff --stat test-fixtures/manifest.txt` → "1 file changed, 3 insertions(+), 3 deletions(-)"; `--verify` EXIT=0. Left regenerated. | COMPLIANT |
| 6 | Edit in place | All changes applied via targeted `Edit` (exact-string) calls, never full-file rewrites; read each file region before editing. | COMPLIANT |
| 7 | Rules-Applied Verification Block | This block. | COMPLIANT |
| 8 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted before this Write (top of report); all 5 fixes + full verification PASS first; no parent stop message received. | COMPLIANT |
