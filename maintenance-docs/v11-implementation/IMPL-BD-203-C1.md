# IMPL-BD-203-C1 — Phase A (per-entry engine + validator redesign + test reworks)

**Agent:** pack-coder · **Date:** 2026-06-04 · **Branch:** v11-dev
**Worktree HEAD (start + end — agents never commit):** `a630a312d7c7b93437b99c9d9f87cf52e1afe949`
**Scope:** BD-203 commit C-1 / Phase A — tasks A1–A16, exactly as specified in `PLAN-BD-203.md` §2 "Phase A".
**Keyword:** `pack-only` (no `project-template/` / `supporting-docs/` touched).

---

## 0. EDIT SUMMARY (lead)

All 16 Phase-A tasks implemented as targeted in-place edits. Engine widenings + per-release
changelog grouping + the inverted Check 32′ + repointed Checks 3/40/48 + PM-only path removal +
the two pack-side runtime-dep repoints (recommendation.sh + the pack-surface-only detect.sh branch)
+ the 5 named test reworks + 2 lockstep encoding-surface test fixtures (recommendation-test,
pack-help-test) for A14a/A14b. Manifest regenerated (non-empty diff — Pack Chat stages it).

**CRITICAL INVARIANT VERIFIED:** at the C-1 end-state the monolith STILL EXISTS and NO tree exists;
`python3 scripts/validate-pack.py` is GREEN (Check 32′ vacuously satisfied — tree absent ⇒ SKIP;
Checks 33/34 SKIP; monolith present is fine). Check 43 + Check 47 GREEN; the
`_SANCTIONED_PACK_SIDE_SHIPPED` set is unchanged (`detect.sh`, `pack-help.sh`).

---

## 1. PER-TASK SUMMARY (A1–A16)

| Task | File(s) | Change |
|---|---|---|
| **A1** | `scripts/lib/per-entry/decompose.sh` | pack-backlog anchor → `^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— ` + `id_extract` captures `BD-\d+[a-z]*`; parallel TD- widening on project-backlog anchor (additive). Admits `BD-167b`, `BD-169b`, `BD-195 (Code Red 3)`. |
| **A2** | `scripts/lib/per-entry/decompose.sh` | pack-changelog re-anchored on `^## (v\d+)\b` (entry unit = one `vN.md` per major release); body = the entire H2 block (nested `### vN.M` / `### New` preserved verbatim). |
| **A3** | `_lib.sh`, `toc-regenerate.sh`, `validate-pack.py` STREAMS | pack-changelog entry regex → `^v[0-9]+\.md$` (lib bash form) / `^v\d+\.md$` (py form) in LOCKSTEP. |
| **A4** | `_lib.sh`, `toc-regenerate.sh`, `validate-pack.py` STREAMS (+ `_collect_defined_ids` via STREAMS) | pack-backlog entry regex → `^BD-\d+[a-z]*\.md$` in LOCKSTEP — sized to exactly the 2 suffix entries. |
| **A5** | `validate-pack.py` `CROSS_REF_RE` | token widened to `BD-\d+[a-z]*` / `TD-\d+[a-z]*` — ADMIT the suffix (per V3 EE-5; NOT strip a stray `b`). |
| **A6** | `scripts/lib/per-entry/toc-regenerate.sh` | backlog TOC title regex → `^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*` (suffix + parenthetical get real title). |
| **A7** | `scripts/lib/per-entry/toc-regenerate.sh` | `order_groups` canonical list → RATIFIED `Open → Unblocked → Deferred → Resolved → Deprecated → Cancelled`. |
| **A8** | `mirror-generate.sh`, `_lib.sh`, `decompose.sh` | wrong-model "regenerated mirror" purpose statements corrected to no-mirror-for-pack at COMMENT level; `mirror-generate.sh` NOT deleted; typed deferral comment `# TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206`. |
| **A9** | `scripts/validate-pack.py` | Check 32 → inverted Check 32′ (tree present ⇒ assert monolith ABSENT + `_rules.md`/`_toc.md` present + filenames conform; never regenerate). SKIP on tree-absent. |
| **A10** | `scripts/validate-pack.py` Check 3 | repointed from `pack-ops/BACKLOG.md` to scan `/backlog/*.md` entry bodies; SKIP-on-absent preserved. |
| **A11** | `scripts/validate-pack.py` Check 40 | corrected wrong-model exclusion docstring + `excluded_basenames` comment to no-mirror wording; exclusion mechanism retained (inert post-deletion). |
| **A12** | `scripts/validate-pack.py` Check 48 | `_REMOVED_DOC_SCAN_FILES` (two monoliths) → `_REMOVED_DOC_SCAN_DIRS` (`changelog`, `backlog`); scan walks each tree dir's `*.md`; SKIP-on-absent preserved. |
| **A13** | `scripts/validate-pack.py` | removed `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` from `_PM_ONLY_PERMITTED_PATHS` (tree covered by `backlog/`+`changelog/` prefixes). |
| **A14a** | `scripts/lib/recommendation.sh` | `_rec_compute_pack_signals` repointed to count `/backlog/*.md` entry files (incl. suffix form) + sum tree size + count Open/Unblocked; tree-absent ⇒ zero signals. |
| **A14b** | `scripts/lib/detect.sh` | PACK-surface branch of `detect_pack_surface` repointed to detect a `/backlog/` tree with `BD-NNN[suffix].md` entries (pack-surface-only conditional); CLIENT branches (docs/project + root) UNTOUCHED; install-map↔constant equality unaffected (Check 47 GREEN). |
| **A15** | 5 test files | reworked per T1–T5 (details §3). |
| **A16** | `test-fixtures/manifest.txt` | regenerated via `bash test-fixtures/build.sh --all --clean`; diff NON-EMPTY (3 hash lines) — Pack Chat stages it. |

### A14b boundary note (`detect.sh` sanctioned-shipped)
The repoint is a pack-surface-only conditional inserted BEFORE the (now docs/project + root) client
loop; the DENY-LIST-CONTENT markers remain structurally intact wrapping the client candidate list.
The `_SANCTIONED_PACK_SIDE_SHIPPED` constant + the install map are NOT touched. Check 47 verified:
`install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entries): ['scripts/lib/detect.sh', 'scripts/pack-help.sh']`.

---

## 2. VERIFICATION (verbatim results)

### 2.1 The 5 reworked test files
```
test-per-entry                              rc=0  PASS: 58  FAIL: 0
test-validate-pack-checks-32-33-34          rc=0  PASS: 70  FAIL: 0
test-validate-pack-check-removed-doc-advisory rc=0  PASS: 3  FAIL: 0
test-validate-pack-checks-36-37-38          rc=0  PASS: 8   FAIL: 0
test-validate-pack-check-40                 rc=0  PASS: 8   FAIL: 0
```

### 2.2 Full `python3 scripts/validate-pack.py` at the C-1 state (monolith present, no tree)
```
validate-pack rc=0
PASSED — all checks clean
── Check 3: TD-TBD sentinels in /backlog/ per-entry tree ──   (SKIP: no /backlog/ tree found)
── Check 32′: no pack monolith exists (BD-203) ──            (SKIP: backlog/ + changelog/ not present)
── Check 43: ... ──  OK (158 files walked; zero pack-internal bare cross-references)
── Check 47: sanctioned pack-side-shipped freeze (BD-195) ── OK (install-map subset == constant: detect.sh, pack-help.sh)
── Check 48: ... ──  OK (0 removed-doc citations WARNed across 0 per-entry tree dir(s))
```
C-1 invariant confirmed: `pack-ops/BACKLOG.md` present: YES; `pack-ops/CHANGELOG.md` present: YES;
`ls -d backlog changelog` → both `No such file or directory`.

### 2.3 A16 manifest
```
$ bash test-fixtures/build.sh --all --clean   → build rc=0
$ git status --short test-fixtures/manifest.txt
 M test-fixtures/manifest.txt                  (NON-EMPTY — stage in the C-1 commit)
$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---  (3 insertions, 3 deletions)
```
The changed hash lines are the v11 fixtures (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`)
which embed copies of the edited `scripts/` files. Per `manifest-regen-on-v11-surface`: the diff is
NON-EMPTY → Pack Chat stages `test-fixtures/manifest.txt` alongside the C-1 scope edits.

### 2.4 Lockstep encoding-surface tests (A14a / A14b) + syntax + engine smoke
```
recommendation-test                rc=0  Passed: 53  Failed: 0   (A14a encoding surface reworked)
pack-help-test                     rc=0  All tests passed.        (A14b encoding surface reworked)
recommendation-state-schema-test   rc=0  PASS: 19  FAIL: 0
test-init-project                  rc=0
bash -n on all 6 edited .sh files  → OK
python3 ast.parse validate-pack.py → OK
```
Engine end-to-end smoke (synthetic, off-tree): decompose of a backlog with `BD-100` / `BD-167b` /
`BD-195 (Code Red 3)` produced `BD-100.md` / `BD-167b.md` / `BD-195.md` (parenthetical preserved in
the body header line, NOT the filename); decompose of a changelog with `## v11` (nested `### v11.0`
+ `### New`) + `## v7` (H2-only) produced `v11.md` (nested subsections preserved) + `v7.md`; TOCs
grouped by status (A7 order) and by major version descending. detect_pack_surface on a `/backlog/`
tree with `BD-167b.md` → `pack-surface: pack`.

---

## 3. TEST REWORK DETAIL (A15 / T1–T5)

- **T1 `test-per-entry.sh`** (PASS 58): removed pack-stream mirror-filename asserts 1.1/1.2 (named the
  deleted monoliths); widened 1.6 to `^BD-[0-9]+[a-z]*\.md$`; reworked Group 10 (pack-changelog) from
  the per-point-release `v11.0.md`/`v11.1.md` round-trip to per-RELEASE `v11.md`/`v7.md` decompose +
  nested-subsection preservation + a negative assert (no `v11.0.md`). Kept the synthetic-fixture
  engine groups (3–9) that still exercise mirror-generate (retained for project streams).
- **T2 `test-validate-pack-checks-32-33-34.sh`** (PASS 70): rewrote Group A to the inverted Check 32′
  (green = tree present + NO monolith; A2/F4 red = monolith present; A3 = missing `_rules.md`; A4 =
  missing `_toc.md`; A5 = non-conforming filename; A6 = suffix entry conforms). Added a suffix entry
  `BD-167b.md` to the green fixture + the wrapper STREAMS default regex (`^BD-\d+[a-z]*\.md$`). Added
  Group-C cases C6 (suffix ref `BD-167b` resolves) + C7 (dangling suffix ref `BD-999z` FAILs).
  Reworked `build_green_pack_changelog` + Group F to per-release `vN.md` shape (no mirror; inverted
  32′). Changelog fixture's nested header carries NO `vN.M` token (would be a dangling cross-ref).
- **T3 `test-validate-pack-check-removed-doc-advisory.sh`** (PASS 3): re-targeted the symbol name
  `_REMOVED_DOC_SCAN_FILES` → `_REMOVED_DOC_SCAN_DIRS`; Group-1 UNIT fixture now a `/changelog/v11.md`
  per-entry file (monkeypatch `_REMOVED_DOC_SCAN_DIRS=('changelog',)`); Group-2 E2E relaxed from
  "monolith WARN required" to "Check 48 ran non-fatally; exit 0" (at C-1 trees absent ⇒ 0 hits).
- **T4 `test-validate-pack-checks-36-37-38.sh`** (PASS 8): converted T6d/T6e from `True` to `False`
  (positive negative-control of A13: `pack-ops/BACKLOG.md` / `CHANGELOG.md` are NO LONGER PM-only
  permitted FILES; the trees are covered by the prefixes — T8a/T8b still `True`).
- **T5 `test-validate-pack-check-40.sh`** (PASS 8): updated the T7 mirror-exclusion comment/label to
  no-mirror wording; behavior unchanged (exclusion retained per A11).

### Lockstep beyond the 5 named (per `enumerate-encoding-surfaces`)
- `recommendation-test.sh` test 1.1 — A14a encoding surface: rebuilt the fixture as a `/backlog/`
  per-entry tree (3 active incl. suffix `BD-167b.md`; `_rules.md` excluded from the count).
- `pack-help-test.sh` test 1.1 — A14b encoding surface: rebuilt the pack fixture as a `/backlog/`
  tree with `BD-167b.md` so the repointed pack-surface branch is exercised.

---

## 4. PLAN DEVIATIONS

**Zero design deviations.** Two scope notes (within-task, not redesigns):

1. **A15 lockstep extended to 2 unnamed tests.** A15 names 5 test files, but A14a/A14b changed
   `_rec_compute_pack_signals` (recommendation.sh) and `detect_pack_surface` (detect.sh), whose
   encoding tests are `recommendation-test.sh` 1.1 and `pack-help-test.sh` 1.1. Per
   `enumerate-encoding-surfaces` ("a validator change and its TEST move together"), I updated those
   two fixtures in lockstep. Not a redesign — the standing rule mandates it; without it both tests
   would have regressed (recommendation-test failed 1.1 before the fixture fix; confirmed).
2. **A11 kept the Check 40 exclusion mechanism** (corrected the wrong-model COMMENT only), matching
   A11's "the exclusion + comment become moot post-deletion; correct the wrong-model prose." The
   files still exist at C-1; the exclusion is harmless during conversion and inert once they are
   deleted at C-4. No behavior change.

---

## 5. NEW POQs

None. No architecture gap encountered; the V3 + amendment design pair fully specified every edit.

---

## 6. OUT-OF-SCOPE ITEMS NOTICED (surfaced, NOT fixed)

- **Changelog nested `vN.M` cross-refs (forward-looking, C-2/E concern).** Under per-release
  granularity the changelog entry files WILL contain nested `### vN.M` headers and `vN.M` mentions.
  Check 34's `CROSS_REF_RE` tokenizes `vN.M`, but per-release granularity defines only `vN` as an
  entry ID — so a literal `v11.0` mention inside `v11.md` would tokenize as a DANGLING cross-ref at
  C-2 (when the real tree is built). I did NOT alter Check 34's `vN.M` token (out of A5 scope; A5
  widens the `BD-`/`TD-` token only). FLAG for C-2/Phase-E: the oracle / reviewer should confirm
  whether the real pack CHANGELOG's nested `vN.M` mentions trip Check 34, and if so whether they
  belong on a Check-34 allowlist or the changelog cross-ref scope needs adjustment. Surfaced per the
  BD-195 prompt-GOALS "out-of-scope issues surfaced not silently fixed."

---

## 7. DEFINITION-OF-DONE CHECKLIST

| Item | Status |
|---|---|
| A1 decompose anchor widened (BD- + parametric TD-) | PASS |
| A2 pack-changelog per-release grouping | PASS |
| A3 changelog regex `^v\d+\.md$` lockstep (lib+toc+vp) | PASS |
| A4 backlog regex `^BD-\d+[a-z]*\.md$` lockstep (lib+toc+vp+`_collect_defined_ids`) | PASS |
| A5 Check 34 `CROSS_REF_RE` admits suffix (ADMIT not strip) | PASS |
| A6 TOC title regex admits suffix + parenthetical | PASS |
| A7 status order `Open→Unblocked→Deferred→Resolved→Deprecated→Cancelled` | PASS |
| A8 mirror-generate retired-for-pack at COMMENT level; file NOT deleted; typed deferral comment | PASS |
| A9 Check 32 → inverted Check 32′ | PASS |
| A10 Check 3 repointed to `/backlog/` tree | PASS |
| A11 Check 40 wrong-model comment corrected | PASS |
| A12 Check 48 repointed to `/backlog/`+`/changelog/` trees | PASS |
| A13 two monolith paths removed from `_PM_ONLY_PERMITTED_PATHS` | PASS |
| A14a recommendation.sh pack-signals → `/backlog/*.md` | PASS |
| A14b detect.sh pack-surface branch repointed; client branch + Check 47 unaffected | PASS |
| A15 5 named test files reworked (lockstep) | PASS |
| A16 manifest regenerated; diff non-empty reported | PASS |
| `python3 scripts/validate-pack.py` GREEN at C-1 state | PASS |
| Check 43 + Check 47 GREEN | PASS |
| No tree/asset created; no monolith content edited; no PM-only file; no deletion; no `project-template/`/`supporting-docs/` touched | PASS |
| No git state-changing verb run | PASS |

---

## 8. FILES-CHANGED INVENTORY

All `modified` (no new/deleted files):

| Path | Type | Tasks |
|---|---|---|
| `scripts/lib/per-entry/decompose.sh` | modified | A1, A2, A8 |
| `scripts/lib/per-entry/_lib.sh` | modified | A3, A4, A8 |
| `scripts/lib/per-entry/toc-regenerate.sh` | modified | A3, A4, A6, A7 |
| `scripts/lib/per-entry/mirror-generate.sh` | modified | A8 |
| `scripts/validate-pack.py` | modified | A3, A4, A5, A9, A10, A11, A12, A13 |
| `scripts/lib/recommendation.sh` | modified | A14a |
| `scripts/lib/detect.sh` | modified | A14b |
| `scripts/tests/test-per-entry.sh` | modified | A15-T1 |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | modified | A15-T2 |
| `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` | modified | A15-T3 |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | modified | A15-T4 |
| `scripts/tests/test-validate-pack-check-40.sh` | modified | A15-T5 |
| `scripts/tests/recommendation-test.sh` | modified | A14a lockstep (encoding surface) |
| `scripts/tests/pack-help-test.sh` | modified | A14b lockstep (encoding surface) |
| `test-fixtures/manifest.txt` | modified | A16 (regenerated) |

No new files were created (all per-entry asset/tree creation is C-2, out of scope).

---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED) | Conclusion |
|---|---|---|
| **read-in-full + no-derivation** | Every named doc Read DIRECTLY via the Read tool — see READ-IN-FULL row below (per-file line-count / first+last proof). No named doc derived. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line `PREFLIGHT: 16/16 in-scope edits complete; verification PASS; HEAD a630a31; about to Write IMPL-REPORT ...` ONLY after all 16 edits + all verification (5 named tests + validate-pack Check 43/47 + lockstep tests + manifest) PASS. No stop/halt message received. | COMPLIANT |
| **agents-never-commit** | Ran only read-only git verbs (`git rev-parse HEAD`, `git status`, `git diff`). HEAD unchanged at `a630a312...` start and end. No `git add`/`commit`/`push`/`tag`/`rm`. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Measured first: baseline validate-pack GREEN (`/tmp/vp-baseline.out`); the 3 special header forms (`BD-167b`,`BD-169b`,`BD-195 (Code Red 3)`) enumerated; trees absent confirmed. Widenings sized EXACTLY to the measured suffix set (`[a-z]*` admits `167b`/`169b`, not broader); Check 32′ verified vacuously-true at the projected tree-absent C-1 state AND PASSING at the synthetic tree-present state (test A1/F1). No allowlist widened to swallow unclassified hits. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All changes via targeted `Edit` calls with exact anchors (no full-file `Write` on any source). Re-verified affected regions via the test suite + engine smoke after editing; no section drops (each Edit reported success — exact-match required). | COMPLIANT |
| **enumerate-encoding-surfaces** | Each validator change moved with its TEST in lockstep: Check 32′↔checks-32-33-34 Group A; Check 34/STREAMS↔checks-32-33-34 fixtures+C6/C7; Check 48↔removed-doc-advisory; PM-only↔checks-36-37-38 T6d/e; Check 40↔check-40 T7; A14a↔recommendation-test 1.1; A14b↔pack-help-test 1.1. No asymmetric coverage. | COMPLIANT |
| **pack-repo-code-comment-deferrals** | A8 mirror-generate deferral uses the typed form `# TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206` (not plain `# TODO`/`# FIXME`). `grep` of the edited header confirms the typed shape. | COMPLIANT |
| **regenerate-manifest-on-v11-surface** | Diff touches `scripts/` (v11-surface). Ran `bash test-fixtures/build.sh --all --clean` (rc=0); `git status --short test-fixtures/manifest.txt` → ` M ...` (NON-EMPTY). Reported for Pack Chat to stage in the C-1 commit (agents never stage). | COMPLIANT |
| **dependency-direction-placement** | `detect.sh` is in the frozen `_SANCTIONED_PACK_SIDE_SHIPPED` set. A14b repoint is pack-surface-conditional only; the constant + install map were NOT changed. Check 47 GREEN: `install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entries): ['scripts/lib/detect.sh', 'scripts/pack-help.sh']`. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented exactly A1–A16 + the rule-mandated lockstep test fixtures. Report leads with the edit summary. NO tree/asset created (C-2), NO monolith content edited (C-2/C-4), NO PM-only file (C-3), NO deletion. One out-of-scope issue (changelog nested `vN.M` cross-refs) SURFACED, not fixed. | COMPLIANT |
| **rules-applied-verification-block** | This block; every row QUOTED evidence (none empty); READ-IN-FULL row below with per-file direct-read proof. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)

| Document | Direct Read? | Proof |
|---|---|---|
| `PLAN-BD-203.md` (§2 Phase A + §7 + §3 + all) | YES | 702 lines; read pp.1–542 + offset 543 lim 160 → L702 "**End of PLAN-BD-203.md**". |
| `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines; L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design ..." → L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 244 lines; L1 "# ARCHITECTURE-BD-203-V3-AMENDMENT ..." → L244 "**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**". |
| `CLAUDE.md` `## Pack memory` | YES | Provided in full via system context; the Pack-memory section + repo-conventions read directly (dependency-direction-placement, enumerate-encoding-surfaces, regenerate-manifest, pack-repo-code-comment-deferrals quoted in edits). |
| `scripts/lib/per-entry/decompose.sh` | YES | 288 lines read in full (L1→L287 PYEOF) before editing the anchors L110-153 + comments. |
| `scripts/lib/per-entry/_lib.sh` | YES | 439 lines read in full (L1 header → L439 `pe_id_from_filename`); stream tuples L64-122 edited. |
| `scripts/lib/per-entry/toc-regenerate.sh` | YES | 295 lines read in full (L1 → L294); entry-regex L83-90, title L123, changelog title/group L136-149, order L198-221, sort L226-247 edited. |
| `scripts/lib/per-entry/mirror-generate.sh` (header) | YES | header L1-70 read directly (purpose statement); A8 comment edited. |
| `scripts/validate-pack.py` (affected checks) | YES | Read STREAMS L290-369, Check 3 L455-477, Check 32 L3107-3380, CROSS_REF_RE+Check 34 L3490-3650, PM-only L3818-3872, Check 40 L5113-5182 + L5058-5071, Check 48 L7140-7206 directly. |
| `scripts/lib/recommendation.sh` | YES | L100-176 + L178-267 read directly; `_rec_compute_pack_signals` edited. |
| `scripts/lib/detect.sh` | YES | 879 lines read in full (L1 header → L878 detect_target_pack_version); `detect_pack_surface` L40-62 + DENY-LIST markers edited. |
| `scripts/tests/test-per-entry.sh` | YES | 610 lines read in full; Groups 1/10 edited. |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | YES | 755 lines read in full; wrapper STREAMS + Group A/C/F + fixtures edited. |
| `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` | YES | 181 lines read in full; Groups 0/1/2 edited. |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | YES | read L104-163 directly (T6 block) + grepped T6d/e; edited. |
| `scripts/tests/test-validate-pack-check-40.sh` | YES | 768 lines read in full; Group 5 T7 edited. |
| `scripts/tests/recommendation-test.sh` | YES | L33-61 read directly (test 1.1); edited. |
| `scripts/tests/pack-help-test.sh` | YES | L30-81 read directly (Group 1); test 1.1 edited. |
| `feedback_agents_read_rule_docs_in_full.md` | YES | 97 lines; L1 frontmatter → L97 "...reinforced in every spawn prompt." |
| `feedback_agent_output_rules_applied_block.md` | YES | 15 lines (incl. system-reminder); L1 frontmatter → L15 Related links. |
| `feedback_manifest_regen_on_v11_surface.md` | YES | 16 lines; L1 frontmatter → L15 "Related: test-infra self-provisioning." |
| `feedback_ci_guard_design_measure_then_bound.md` | YES | 15 lines; L1 frontmatter → L15 Related links. |
| `feedback_edit_in_place_not_full_rewrite.md` | YES | 15 lines (incl. system-reminder); L1 frontmatter → L14 Related links. |
| `feedback_scope_deliverables_to_the_ask.md` | YES | 35 lines; L1 frontmatter → L35 "...standing preference for terse, exactly-scoped work." |

**No named document was derived rather than read.** Every named document was Read directly via the
Read tool; all load-bearing measurements (baseline GREEN, 3 special header forms, trees-absent,
manifest non-empty diff, Check 47 unchanged set, the engine end-to-end smoke) were independently
captured this pass at HEAD `a630a31` via Bash/Read.

**End of IMPL-BD-203-C1.md**
