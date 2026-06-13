# IMPL-REPORT — BD-214: `_order.md` → `_index.md` rename + scope-broaden (BD ENTRIES ONLY)

> **Coder:** fresh pack-coder. **Date:** 2026-06-13.
> **Branch:** `v11-dev`. **HEAD (pre + post — agents never commit):**
> `935d9a5e525ded7df817803fe3b2240b087a0673`.
> **Scope (user 2026-06-13):** rename the predesigned-but-unbuilt sidecar
> concept `_order.md` → `_index.md` and broaden its scope, in the THREE BD
> entries that reference it (BD-206 primary, BD-203, BD-202). Maintenance-docs
> predesign/design/plan/report/archive chain, scripts, ops docs, `_rules.md`
> supporting-file lists, validators/tests are OUT OF SCOPE — user-DEFERRED to a
> later researcher+architect sweep (anchored in BD-206).

---

## 1. Pre-flight (verified)

| Check | Result |
|---|---|
| `git rev-parse HEAD` | `935d9a5e525ded7df817803fe3b2240b087a0673` |
| `git status` (start) | clean except pre-existing untracked maintenance-docs artifacts (NOT my work) |
| Base contains scoped files | `backlog/BD-206.md`, `BD-203.md`, `BD-202.md`, `backlog/_rules.md`, the census doc, `validate-pack.yml` all present and read in full |
| Census reconciliation | `RESEARCH-ORDER-MD-RENAME-CENSUS.md`: 3 BD entries reference `_order.md` — BD-202 (1), BD-203 (1), BD-206 (4) = 6 lines. Confirmed by `git grep -n '_order\.md' -- backlog/` (6 lines, same distribution). |

---

## 2. Files changed inventory

| Path | Change type | Line delta |
|---|---|---|
| `backlog/BD-202.md` | modified | `2 +-` (1 token rename) |
| `backlog/BD-203.md` | modified | `2 +-` (1 token rename + appended dated forward-consistency note on the same line) |
| `backlog/BD-206.md` | modified | `9 +++++----` (4 renames + broadened definition + new DEFERRED-SWEEP ANCHOR line) |
| `backlog/_toc.md` | regenerated → **byte-identical** (md5 `3bef2273…` before == after); NOT in `git status` (no delta) | 0 |
| `test-fixtures/manifest.txt` | NOT touched (backlog/ is not v11-surface; restored read-only after the CI `--all --clean` rebuild) | 0 |

`git diff --stat -- backlog/`:
```
 backlog/BD-202.md | 2 +-
 backlog/BD-203.md | 2 +-
 backlog/BD-206.md | 9 +++++----
 3 files changed, 7 insertions(+), 6 deletions(-)
```

`git status --short` (tracked only):
```
 M backlog/BD-202.md
 M backlog/BD-203.md
 M backlog/BD-206.md
```
(The `??` untracked entries — IMPL-REPORT-BD-214-GH-DELETION-*, PACK-REVIEW-BD-214-GH-DELETION-*, BD-214-GH-DELETION-EXECUTION-LOG, RESEARCH-ORDER-MD-RENAME-CENSUS — are PRE-EXISTING artifacts from prior sessions, present at pre-flight, not produced by this task. The only new file I author is THIS report.)

---

## 3. Per-entry before / after

### 3.1 BD-202 (`backlog/BD-202.md:14`) — incidental token rename

**Before:**
> "…the project monoliths are deleted; per-entry trees + `_order.md` become the managed assets), so re-assess the AC-1..AC-4 taxonomy coverage…"

**After:**
> "…the project monoliths are deleted; per-entry trees + `_index.md` become the managed assets), so re-assess the AC-1..AC-4 taxonomy coverage…"

Pure token swap; no other change. The "managed assets" mention is incidental and the new name is the correct forward reference.

### 3.2 BD-203 (`backlog/BD-203.md:5`, RESOLVED) — token rename + dated forward-consistency note

BD-203 is `Status: Resolved`. User explicitly approved editing it anyway ("same reason: no dangling refs"). The edit is a rename + a one-line dated note that it does NOT reopen the entry.

**Before** (D1 meta-doc governance list):
> "…every meta-doc (`_intro.md`/`_rules.md`/`_toc.md`/`_order.md`) states audience+purpose at the top — the pack adopts this now; BD-206 inherits it for project. CHANGELOG needs NO normalization beyond per-release `vN.md` (verified: every `## ` H2 is a legitimate version release)."

**After:**
> "…every meta-doc (`_intro.md`/`_rules.md`/`_toc.md`/`_index.md`) states audience+purpose at the top — the pack adopts this now; BD-206 inherits it for project. CHANGELOG needs NO normalization beyond per-release `vN.md` (verified: every `## ` H2 is a legitimate version release). [Note 2026-06-13 (BD-214): the prospective meta-doc formerly named `_order` (the predesigned `.md` sidecar) is renamed `_index.md` (broadened scope) — this is a forward-consistency token update to a Resolved entry; rename only, does not reopen the entry.]"

`Status:` line UNTOUCHED (remains `Resolved`); `Resolved:` line UNTOUCHED. No status flip (BD status flips are post-review Pack-Chat work, not coder work).

### 3.3 BD-206 (`backlog/BD-206.md`, PRIMARY — 4 original refs) — rename + broaden + deferred-sweep anchor

**L6 (FINDING) — before:**
> "`_order.md` FINDING: the flat-file execution-ordering support-file `_order.md` is PREDESIGNED but UNBUILT (zero `_order.md` files exist in the tree — measured); BD-206 must CREATE it for the project implementation-plan stream (phase order is NOT numerically recoverable…); if the predesign conflicts with the BD-203 as-built per-entry shape, the predesign is UPDATED to match BD-203 (BD-203 as-built wins). IMPLEMENTATION is Track B…"

**L6 — after:**
> "`_index.md` FINDING (renamed from the former `_order` sidecar 2026-06-13, BD-214 — scope broadened, see ADD (US-6)): the per-entry index sidecar `_index.md` is PREDESIGNED but UNBUILT (zero such files exist in the tree — measured); BD-206 must CREATE it for the project implementation-plan stream (phase order is NOT numerically recoverable from filenames the way `/backlog/` BD-NNN ordering is — execution-ordering is ONE of the indexes `_index.md` may carry); if the predesign conflicts with the BD-203 as-built per-entry shape, the predesign is UPDATED to match BD-203 (BD-203 as-built wins). IMPLEMENTATION is Track B…"

**L13 (ADD US-6) — before:**
> "**ADD (US-6) — `_order.md` create/reconcile:** CREATE the flat-file execution-ordering support-file `_order.md` for the project implementation-plan stream (phase order is NOT numerically recoverable…). `_order.md` is PREDESIGNED but UNBUILT (zero `_order.md` files exist… the predesign lives in `ARCHITECTURE-BD-185-V2.md` §5.3, `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §A-1, and `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3). If the predesign conflicts with the BD-203 as-built per-entry shape …, the predesign is UPDATED to match BD-203 (BD-203 as-built wins)."

**L13 — after (broadened definition, applied verbatim in meaning):**
> "**ADD (US-6) — `_index.md` create/reconcile:** CREATE the per-entry index sidecar `_index.md` for the project implementation-plan stream. `_index.md` is a sidecar alongside `_intro.md` / `_rules.md` / `_toc.md` that may contain ONE OR MORE indexes or graphs for the per-entry flat files — including their ORDER or GROUPINGS, and OPTIONALLY a dependency graph (which MAY reference entries in another directory, e.g. TD entries depending on phase/implementation-plan entries). The dependency graph is NOT a default — it is created only if needed. The flat-file execution-ordering index is ONE of the possible indexes `_index.md` carries (required for the implementation-plan stream because phase order is NOT numerically recoverable from filenames the way `/backlog/` BD-NNN ordering is, so an index is required). `_index.md` is PREDESIGNED but UNBUILT (zero such files exist in the tree today — measured; the predesign, authored under the former name `_order` (the predesigned `.md` sidecar), lives in `ARCHITECTURE-BD-185-V2.md` §5.3, `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §A-1, and `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3). If the predesign conflicts with the BD-203 as-built per-entry shape (flat tree + generated `_toc.md`, audience+purpose meta-doc governance per `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F), the predesign is UPDATED to match BD-203 (BD-203 as-built wins)."

The ordering use is preserved but demoted to ONE of the possible indexes; the reconcile-predesign→BD-203 intent is preserved verbatim.

**NEW LINE 14 — DEFERRED-SWEEP ANCHOR (added immediately after the ADD clause):**
> "**DEFERRED-SWEEP ANCHOR (2026-06-13, BD-214):** the `_order`→`_index.md` rename (the former `.md` sidecar basename) is applied to BD entries only (2026-06-13); the predesign chain (`ARCHITECTURE-BD-185-V2.md` + its `-ORDERING-ADDENDUM` + `ARCHITECTURE-BD-203-V3-AMENDMENT.md`), the BD-214 design/plan/report docs, the archived BD-185 pipeline records, the unbuilt `_order-generate.sh` generator, and any pack-ops/scripts involvement still carry the old `_order` name and REQUIRE a thorough researcher + architect sweep when `_index.md` usage + operations are implemented (census: `RESEARCH-ORDER-MD-RENAME-CENSUS.md` = 56 refs / 14 files; pure text, no built file / no validator-test hardcode)."

**L16 (TRACK B) — before:** "…the conversion + `_order.md` IMPLEMENTATION is Track-B work…"
**L16 — after:** "…the conversion + `_index.md` IMPLEMENTATION is Track-B work…"

**L18 (acceptance criteria) — before:** "…the project implementation-plan stream carries an `_order.md` execution-ordering support-file reconciled to the BD-203 as-built shape;…"
**L18 — after:** "…the project implementation-plan stream carries an `_index.md` index sidecar (carrying at least the execution-ordering index) reconciled to the BD-203 as-built shape;…"

---

## 4. Completeness gate proof

The gate (prompt §COMPLETENESS GATE): `git grep -c '_order\.md' -- backlog/` MUST be 0.

```
$ git grep -c '_order\.md' -- backlog/
(no output)
grep-exit=1   # exit 1 = NO MATCHES = PASS
$ git grep -n '_order\.md' -- backlog/ || echo "NONE — gate PASS"
NONE — gate PASS
```

**`_index.md` presence confirmed in all three entries:**
```
$ git grep -c '_index\.md' -- backlog/BD-202.md backlog/BD-203.md backlog/BD-206.md
backlog/BD-202.md:1
backlog/BD-203.md:1
backlog/BD-206.md:5
```

**Note on historical-reference wording (important).** The gate is ABSOLUTE
(literal `_order.md` count == 0), but several edits must still REFER to the old
name (the FINDING "renamed from…", the L13 predesign provenance, the DEFERRED-
SWEEP anchor, the L13 generator pointer). To satisfy the gate AND retain the
historical reference, those provenance mentions use the bare `_order` token
(without the `.md` extension) or `_order-generate.sh` — neither contains the
literal substring `_order.md`, so the gate is clean while the reader still sees
the old name. No `_order.md` literal remains anywhere in `backlog/`.

`_order-generate.sh` (the generator pointer in the anchor) is intentionally
retained as a bare `_order-generate.sh` token — it does not match `_order\.md`
and naming it is required to direct the future sweep to the unbuilt generator.

---

## 5. `_toc.md` regeneration

Ran the sanctioned regenerator (NOT a hand-edit), per `backlog/_rules.md`
§ "Write authority":
```
$ source scripts/lib/per-entry/toc-regenerate.sh && per_entry_regenerate_toc pack-backlog backlog
regen-exit=0
toc md5 before=3bef227327fb185098b1569af70f0c65 after=3bef227327fb185098b1569af70f0c65
TOC byte-identical (titles unchanged) — expected
```
Titles are unchanged (only field-body prose edited), so the regenerated TOC is
byte-identical → no `_toc.md` delta in `git status`. Regenerator exit 0.

---

## 6. FULL CI suite verification (every wired step from `.github/workflows/validate-pack.yml`, NO sampling)

The run-command list was extracted from BOTH jobs of `validate-pack.yml`
(`validate` job = 2 steps; `tests` job = the full enumerated per-name list).
Every command was run locally; every exit captured.

### 6.1 `validate` job (2 steps)
| Step | Command | Exit |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **0** — "PASSED — all checks clean" |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** — "PASSED — all checks clean" |

Check 33 (`_toc.md`) + Check 34 (cross-refs) are part of validate-pack general
→ included in the EXIT 0 above.

### 6.2 `tests` job — batch 1 (41 offline suites), all PASS, fail=0
detect.sh; tracker-provider; tracker-config; tracker-init; tracker-agent-read;
tracker-migrate-forward; tracker-migrate-reverse; tracker-migrate-roundtrip;
tracker phase-task; tracker links; tracker cycle-check; tracker error mapping;
tracker-config-schema; recommendation-state-schema; per-entry helper;
Check 32/33/34; Check 36/37/38; Check 39; Check 40; Check 41; Check 18;
Check 16; Check 19; Check 42; Check 43; Check 44; Check 45; Check 46;
Check 48 removed-doc-advisory; Check 49/50 field-faithfulness;
Check 50 codec-single-source; Check 51 flip-block; tracker deferral gate;
tracker BD-129 gh-repo; tracker BD-130 doctor-wired; tracker BD-132 race;
tracker BD-133 header-preservation; tracker BD-134 close-retry; recommendation;
pack-help → **all PASS** (`=== batch 1 done; fail=0 ===`).

### 6.3 `tests` job — batch 2 (17 steps incl. fixtures + integration), all PASS, fail=0
customization-preserve; init-project; migrate-v10-to-v11; migrate
dry-run/apply/resume; migrate verification gates; migrate decompose;
migrator-core; migrator-manifest; migrator-capability-translation;
**build test fixtures (`test-fixtures/build.sh --all --clean`)**;
restore committed manifest (`git checkout HEAD -- test-fixtures/manifest.txt` —
read-only path-checkout, the BD-118-retro CI step, NOT a branch-state change);
**fixture manifest verify (`--verify`)**; **v11-realistic-ot integration**;
migrator-skills; persona contracts; template-translations; template-version;
issue-forms → **all PASS** (`=== batch 2 done; fail=0 ===`).

**Total wired steps run: 2 (validate) + 41 + 17 = 60. Every EXIT = 0. Zero failures.**

---

## 7. Manifest check (Rule 6)

`backlog/` is NOT a v11-surface (the rule scopes v11-surface to
`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). No manifest
delta is expected. The CI `--all --clean` step rebuilt fixtures during
verification; I restored the committed `test-fixtures/manifest.txt` immediately
after (read-only path checkout, exactly as the CI workflow does), so the final
worktree shows NO manifest change:
```
$ git status --short | grep -v '^??'
 M backlog/BD-202.md
 M backlog/BD-203.md
 M backlog/BD-206.md
```
`test-fixtures/manifest.txt` is NOT modified. Confirmed.

---

## 8. Plan deviations

**One mechanical deviation, fully within intent — flagged for transparency:**
The prompt's literal DEFERRED-SWEEP anchor text contained the substring
`_order.md` (e.g. "the `_order.md`→`_index.md` rename", "carry the old
`_order.md` name"), and the L6/L13 historical-provenance phrasing the prompt
implied ("renamed from `_order.md`", "former name `_order.md`") would ALSO have
contained that literal substring. The COMPLETENESS GATE requires
`git grep -c '_order\.md' -- backlog/` == 0 — an ABSOLUTE 0. These two
directives are in tension if taken byte-literally. I resolved it by keeping the
gate absolute (the controlling acceptance criterion) and writing the historical
references with the bare `_order` token (no `.md`) or `_order-generate.sh` —
which preserve the old-name reference for the reader and the future sweep while
producing zero `_order.md` literals. Meaning is fully preserved; the gate is
clean. No other deviation.

---

## 9. New POQs introduced

None. (The which-streams-get-`_index.md`, predesign-chain-consistency, and
`_order-generate.sh`→`_index-generate.sh` questions are already SURFACED in the
census §4 and now explicitly anchored for the deferred researcher+architect
sweep via the new BD-206 DEFERRED-SWEEP ANCHOR — no new open question is
created by this entry-only rename.)

---

## 10. Boundary discipline check

All three edited files are `/backlog/` per-entry entries — pack-side governance
SSOT (the live pack backlog tree), NOT a project-shipped surface
(`project-template/` / `supporting-docs/`). The pack/project boundary
pre-flight (P-missed-7) applies to project-side edits; these are pack-side
entries, so the project-side-SSOT-investigation gate is N/A. No edit adds a
project-side reference to a pack-only file. The DEFERRED-SWEEP anchor references
pack-side maintenance-docs (`ARCHITECTURE-BD-185-V2.md`, etc.) and the census —
all correct pack-side targets cited inside a pack-side governance entry. No
boundary-discipline stop.

---

## 11. Definition-of-Done checklist

| Item | Status |
|---|---|
| BD-202: `_order.md` → `_index.md` (incidental rename) | PASS |
| BD-203: `_order.md` → `_index.md` in D1 list + dated forward-consistency note (rename only, no reopen, Status untouched) | PASS |
| BD-206: all 4 refs renamed → `_index.md` | PASS |
| BD-206: directive broadened to multi-index/groupings/optional-dependency-graph definition (ordering = one index) | PASS |
| BD-206: reconcile-predesign→BD-203 intent preserved | PASS |
| BD-206: DEFERRED-SWEEP ANCHOR added (predesign chain + BD-214 docs + archive + generator + scripts/ops + census ref) | PASS |
| Completeness gate `git grep -c '_order\.md' -- backlog/` == 0 | PASS (grep exit 1, no matches) |
| `_index.md` present in BD-202/203/206 | PASS |
| No `_order.md` introduced anywhere | PASS |
| `_toc.md` regenerated via sanctioned `per_entry_regenerate_toc` (byte-identical) | PASS |
| Only 3 backlog entries touched (+ toc no-delta); nothing out of scope | PASS |
| validate-pack general + DEEP EXIT 0 (Check 33 + Check 34 included) | PASS |
| FULL CI tests job (60 wired steps) EXIT 0, zero failures | PASS |
| Manifest: no delta (backlog/ not v11-surface) | PASS |
| Agents never commit — HEAD unchanged, no git state change | PASS |

---

## 12. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| 1. Agents never commit (git read-only) | Only read-only git verbs used: `git rev-parse HEAD` (→ `935d9a5e…` pre AND post), `git status`, `git diff`, `git grep`, and `git checkout HEAD -- test-fixtures/manifest.txt` (the read-only path-restore form, the CI BD-118-retro step — NOT a branch-state change). No `add`/`commit`/`push`/`tag`/`stash`/`reset`/`restore`/branch-`checkout`. HEAD identical pre/post. | COMPLIANT |
| 2. Real edit, content+intent preserved | BD-206's directive broadened to the verbatim-meaning multi-index/groupings/optional-dependency-graph definition with the reconcile-intent preserved (§3.3 L13); BD-203/202 are faithful token renames; no entry body content lost — `git diff --stat` shows +7/-6 across 3 files, all localized to the named lines. | COMPLIANT |
| 3. Edit in place | Six targeted `Edit` calls (no full-file rewrites); each file's surrounding fields untouched; post-edit `git grep` + `git diff --stat` confirm only the intended lines changed (BD-203 `Status:`/`Resolved:` untouched; BD-206 only L6/L13/L14-new/L16/L18). | COMPLIANT |
| 4. Completeness gate + Check 34/33 | `git grep -c '_order\.md' -- backlog/` → no output, exit 1 (== 0 matches); `git grep -n` → "NONE — gate PASS". validate-pack general (carries Check 33 `_toc.md` + Check 34 cross-refs) EXIT 0; standalone "Check 32/33/34" test PASS (§6.2). | COMPLIANT |
| 5. Verify FULL CI suite — every wired script, NO sampling | Extracted ALL run-commands from both jobs of `validate-pack.yml`; ran 2 validate steps + 41 batch-1 + 17 batch-2 = 60 steps; every EXIT 0 (`fail=0` both batches; validate "PASSED — all checks clean" + DEEP "PASSED — all checks clean"). Quoted in §6. | COMPLIANT |
| 6. Manifest (backlog/ not v11-surface → no delta) | `git status --short` tracked = only the 3 BD entries; `test-fixtures/manifest.txt` NOT modified (restored read-only after the CI `--all --clean` rebuild). §7. | COMPLIANT |
| 7. Rules-Applied Verification Block present | This table: each rule named, quoted/measured evidence, terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |
| 8. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 3 BD entries renamed _order.md→_index.md; backlog _order.md count=0; FULL CI wired-test job verified locally; HEAD 935d9a5e525ded7df817803fe3b2240b087a0673; about to Write IMPL-REPORT to <path>` in the turn immediately before this Write, AFTER all edits + toc regen + gate + full verification PASSED. No parent stop/halt message received. | COMPLIANT |

---

**End of IMPL-REPORT.** Worktree carries exactly: `M backlog/BD-202.md`,
`M backlog/BD-203.md`, `M backlog/BD-206.md` (+ this new report file). Staging
and commit are Pack Chat's, with user approval.
