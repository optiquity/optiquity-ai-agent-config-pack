# PACK-REVIEW-BD-203-C1 — review of commit C-1 (Phase A): per-entry engine + validator redesign + test reworks

**Agent:** pack-reviewer · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD:** `a630a31`
**Mode:** REVIEW-ONLY (no source edits, no git verb). Review-1 of the bounded cycle.
**Scope reviewed:** the C-1 working-tree diff for the enumerated file set vs `PLAN-BD-203.md` §2 Phase A (A1–A16) + §3 + §7 and the design pair `ARCHITECTURE-BD-203-V3.md` + `ARCHITECTURE-BD-203-V3-AMENDMENT.md` (amendment supersedes V3 on conflict).

---

## VERDICT

**Findings by severity: 1 BLOCKER, 0 MUST, 2 SHOULD, 2 NIT.**

The 16 Phase-A engine/validator/test tasks (A1–A16) are implemented correctly, sized to the projected end-state, and the C-1 CI invariant holds (validate-pack GREEN, all 7 tests pass). The two coder FLAGS are both assessed correct. **The single BLOCKER is a working-tree-hygiene defect, NOT a coder-implementation defect:** `pack-ops/BACKLOG.md` carries an unrelated PM-only change (a BD-206 scope expansion + a new BD-208 entry) that is OUTSIDE the C-1 file set and must NOT be swept into the `pack-only` C-1 commit. All C-1 in-scope edits are clean.

---

## C-1 INVARIANT — VERIFIED GREEN (re-run this pass at `a630a31`)

`python3 scripts/validate-pack.py` → **rc=0, PASSED — all checks clean.** Confirmed directly:

- **Check 3** `── Check 3: TD-TBD sentinels in /backlog/ per-entry tree ──` → `OK: No /backlog/ tree found (nothing to check)` (A10 repoint + SKIP-on-absent).
- **Check 32′** `── Check 32′: no pack monolith exists (BD-203) ──` → both streams `not present (skipping; pre-conversion ...)` (A9 inverted, vacuously satisfied tree-absent).
- **Check 33 / 34** → SKIP (trees absent).
- **Check 43** → `OK ... 158 ... file(s) walked; zero pack-internal bare cross-references`.
- **Check 47** → `OK: install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entr(ies)): ['scripts/lib/detect.sh', 'scripts/pack-help.sh']` — constant + install map UNCHANGED, A14b adjacency contained.
- **Check 48** → `OK ... 0 removed-doc citation(s) WARNed across 0 per-entry tree dir(s)` (A12 repoint to `_REMOVED_DOC_SCAN_DIRS`).

**The 7 tests** (5 named + 2 lockstep) all pass, re-run this pass:
```
test-per-entry                                rc=0  58/58
test-validate-pack-checks-32-33-34            rc=0  70/70
test-validate-pack-check-removed-doc-advisory rc=0  All passed
test-validate-pack-checks-36-37-38            rc=0  All passed
test-validate-pack-check-40                   rc=0  All passed
recommendation-test                           rc=0  All passed
pack-help-test                                rc=0  All passed
```

**Engine smoke (independent, off-tree, this pass):** decompose of a synthetic backlog with `BD-100` / `BD-167b` / `BD-195 (Code Red 3)` produced `BD-100.md` / `BD-167b.md` / `BD-195.md` (parenthetical preserved byte-faithfully in the body header `**BD-195 (Code Red 3) — …**`, NOT in the filename — V3 §2.2 contract honored). Changelog decompose of `## v11` (nested `### v11.0`) + `## v7` (H2-only) produced `v11.md` (nested `v11.0` subsection preserved) + `v7.md`. TOC regenerated: `BD-167b` got its real title (A6) and grouped under the A7 status order.

---

## COMPLETENESS — A1–A16 each verified against plan + WHY

| Task | Verdict | Evidence |
|---|---|---|
| **A1** anchor widen (BD- + parametric TD-) | PASS | `decompose.sh` pack-backlog `^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— `; `id_extract` captures the `BD-\d+[a-z]*` group; identical shape on the project `TD-` anchor (additive). Matches V3 §2.2 exactly. Smoke-confirmed admits all 3 EE-2 forms. |
| **A2** changelog per-release grouping | PASS | `decompose.sh` pack-changelog `^## (v\d+)\b`; body = whole H2 block; nested `### vN.M`/`### New` ride inside. Matches V3 §2.3. Smoke-confirmed v1–v7 + nested preserved. |
| **A3** changelog regex `^v\d+\.md$` lockstep | PASS | `_lib.sh` `^v[0-9]+\.md$`, `toc-regenerate.sh` `^v\d+\.md$`, `validate-pack.py` STREAMS `^v\d+\.md$` — all three in lockstep. |
| **A4** backlog regex `^BD-\d+[a-z]*\.md$` lockstep | PASS | `_lib.sh` `^BD-[0-9]+[a-z]*\.md$`, `toc-regenerate.sh` `^BD-\d+[a-z]*\.md$`, STREAMS `^BD-\d+[a-z]*\.md$`; `_collect_defined_ids` consumes STREAMS regex. Sized to the 2 measured suffix entries. |
| **A5** Check 34 `CROSS_REF_RE` ADMIT suffix | PASS | `validate-pack.py` token → `BD-\d+[a-z]*` / `TD-\d+[a-z]*`. Per V3 EE-5 this ADMITS the suffix (NOT strip a stray `b`). Verified this pass: `BD-167b` → `['BD-167b']`. |
| **A6** TOC title regex admit suffix+parenthetical | PASS | `toc-regenerate.sh` `^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*`. Smoke: `BD-167b` got real title, not filename fallback. |
| **A7** status order Open→Unblocked→Deferred→Resolved→Deprecated→Cancelled | PASS | `order_groups` canonical list exactly matches amendment §E2 ratified order; `Unblocked` admitted. |
| **A8** mirror-generate demote (COMMENT-level; file NOT deleted) | PASS | Corrected purpose statements in `mirror-generate.sh:1-…` header, `_lib.sh` header + `mirror)` attr comments, `decompose.sh` round-trip comments. File present (verified — modified, not deleted). Typed deferral `# TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206` (valid typed form). |
| **A9** Check 32 → inverted 32′ | PASS | Old mirror-regenerate body (≈170 lines) replaced with: tree-present ⇒ assert monolith ABSENT + `_rules.md` + `_toc.md` present + filename conformance; never regenerates. SKIP-on-absent. Matches V3 §4 + plan A9. |
| **A10** Check 3 repoint to `/backlog/` tree | PASS | Scans `/backlog/*.md` entry bodies for `**TD-TBD —`; skips `_`-prefixed; SKIP-on-absent preserved. |
| **A11** Check 40 wrong-model comment correct | PASS | Docstring + `excluded_basenames` comment corrected to no-mirror wording; exclusion mechanism retained (inert post-deletion). No behavior change — correct per A11. |
| **A12** Check 48 repoint to trees | PASS | `_REMOVED_DOC_SCAN_FILES` → `_REMOVED_DOC_SCAN_DIRS = ("changelog","backlog")`; walks each dir's `*.md`; SKIP-on-absent; summary line counts `dirs_scanned`. |
| **A13** remove 2 monolith paths from `_PM_ONLY_PERMITTED_PATHS` | PASS | Both removed; `_PM_ONLY_PERMITTED_PREFIXES` `backlog/`+`changelog/` cover the tree (unchanged). |
| **A14a** recommendation.sh repoint | PASS | `_rec_compute_pack_signals` counts `/backlog/*.md` (suffix-aware), sums byte size, counts Open/Unblocked; tree-absent ⇒ zero. `_rec_backlog_growth_30d` now receives the dir as a `git log -- <pathspec>` — valid (dir pathspec counts tree-touching commits). |
| **A14b** detect.sh pack-surface repoint | PASS | Pack-surface conditional inserted BEFORE the client loop; DENY-LIST markers now wrap only the client candidate list (`docs/project/BACKLOG.md`, root); client branch untouched; `_SANCTIONED_PACK_SIDE_SHIPPED` + install map unchanged (Check 47 GREEN). |
| **A15** 5 named tests reworked lockstep | PASS | See "Encoding-surface lockstep" below. |
| **A16** manifest regenerated, non-empty diff | PASS | See "Manifest" below. |

---

## SCOPE COMPLIANCE — 1 BLOCKER (working-tree hygiene)

### BLOCKER-1 — `pack-ops/BACKLOG.md` carries an unrelated PM-only change in the working tree; it must NOT enter the C-1 commit

`git status --short` shows ` M pack-ops/BACKLOG.md` (25 insertions, 2 deletions). The diff is two PM-only edits with **zero relation to Phase A**:
1. A BD-206 `Scope:` / `Acceptance criteria:` expansion (dual-use `_SANCTIONED_PACK_SIDE_SHIPPED` client-half + skill-master completion).
2. A brand-new **BD-208** entry ("Pack Chat editing-scope rule …").

**Why this is a finding, not noise:**
- C-1's file set (per the plan §5 commit table + the review prompt) is exactly the engine/validator/test/manifest list. `pack-ops/BACKLOG.md` is **not** in it.
- This change is a separate-session artifact (the BD-208 entry references "the BD-203 actor-assignment tensions"; an untracked `ARCHITECTURE-BD-208.md` is present). The C-1 coder did **not** author it — the IMPL-REPORT §8 files-changed inventory omits `pack-ops/BACKLOG.md`, and §7 DoD asserts "no PM-only file" was edited. Independently confirmed: the coder's enumerated edits are all in `scripts/` + `test-fixtures/manifest.txt`.
- `pack-ops/BACKLOG.md` is PM-only and is **not** a `pack-only`-denied prefix, so **CI Check 36 would NOT catch it** — a blanket `git add -A` at commit time would silently fold this PM-only BD-208/BD-206 content into the `pack-only` C-1 commit, corrupting the audit trail (a per-entry-engine commit that also opens a governance BD).

**Fix (Pack-Chat-side, at stage time — NOT a coder edit):** stage the C-1 commit by **explicit pathspec** (the enumerated file list only), never `git add -A`. The `pack-ops/BACKLOG.md` change + the untracked `*-BD-208.md` / `*-BD-200-*.md` maintenance-docs belong to their own sessions/commits and must be left out of C-1. Per `no-prestaging-until-commit-approval`, commit named paths directly.

> Note: this is the only scope issue. Every file the coder actually edited is in-scope pack-product. NO `/backlog/` or `/changelog/` tree was created; NO file was deleted; `mirror-generate.sh` is present (modified, comment-only per A8); no trinity / README / PACK-AGENTS / PACK-CHAT content was touched by the C-1 edits.

---

## VALIDATOR SIZING (measure-then-bound) — PASS

- **A4 / A5 / STREAMS** widenings admit EXACTLY the suffix run `[a-z]*` (the 2 measured entries `BD-167b`/`BD-169b`), not broader. Verified `BD-167b`→`['BD-167b']`, `v11`→`[]` (no false widening of the version token).
- **A5 is ADMIT, not strip** — matches V3 EE-5; the research's "mis-tokenize to BD-167 + stray b" recipe was correctly NOT implemented.
- **A9 Check 32′** sized to the projected no-monolith end-state: passes vacuously tree-absent (today), and the lockstep test proves it passes tree-present+no-monolith and fails monolith-present.
- **A12 / A13** sized exactly to the deletion (scan dirs = the 2 trees; PM-only path removal = the 2 files; prefix list already covers the tree).
No allowlist widened to swallow unclassified hits.

---

## ENCODING-SURFACE LOCKSTEP (A15 + the 2 extended tests) — PASS

Every validator/engine change moves with its test:
- Check 32′ ↔ `checks-32-33-34` Group A (inverted: green=tree+no-monolith, red=monolith-present / missing `_rules.md` / missing `_toc.md` / non-conforming filename).
- Check 34 / STREAMS ↔ same file: suffix entry `BD-167b.md` fixture + cross-ref cases (C6 suffix-ref resolves, C7 dangling suffix-ref fails).
- Check 48 ↔ `removed-doc-advisory` (re-targeted `_REMOVED_DOC_SCAN_DIRS`, monkeypatched to a `/changelog/v11.md` fixture).
- PM-only ↔ `checks-36-37-38` T6d/T6e flipped `True`→`False` (the 2 monoliths are no longer PM-only-permitted FILES; T8a/T8b tree prefixes stay `True`).
- Check 40 ↔ `check-40` T7 comment relabel (no-mirror wording).
- Engine mirror-demote / per-release changelog ↔ `test-per-entry` (mirror-filename asserts 1.1/1.2 removed; Group 10 reworked to per-release `vN.md`).

No asymmetric coverage observed.

---

## THE TWO CODER FLAGS — both assessed CORRECT

### FLAG (a) — A15 lockstep EXTENDED to `recommendation-test.sh` + `pack-help-test.sh` — CORRECT, in-scope, NOT scope creep

A14a changed `_rec_compute_pack_signals` (recommendation.sh) and A14b changed `detect_pack_surface` (detect.sh). Their encoding tests are `recommendation-test.sh` 1.1 and `pack-help-test.sh` 1.1. Per `enumerate-encoding-surfaces` ("a validator/engine change without its lockstep test = a finding"), updating those two fixtures was **mandatory**, not optional. The coder reports `recommendation-test` 1.1 regressed before the fixture fix — confirming the lockstep was required. Both tests pass this pass. This is the rule operating as designed, not scope expansion.

### FLAG (b) — nested `vN.M` cross-refs in `vN.md` deferred to C-2 — REAL C-2 concern, correctly DEFERRED, REQUIRED CARRY-FORWARD

Under per-release granularity (A2) a `vN.md` body contains nested `### vN.M` headers. Check 34's `CROSS_REF_RE` tokenizes `v\d+\.\d+`, but only `vN` is a defined entry ID — so a literal `v11.0` inside `v11.md` would tokenize as a **dangling** cross-ref once the real changelog tree exists at C-2. Independently confirmed this pass: `### v11.0 — point` → `CROSS_REF_RE` yields `['v11.0']`, and the smoke `v11.md` contains a live `v11.0` token. At C-1 Check 34 SKIPs (trees absent), so this is correctly NOT a C-1 defect and the coder correctly did NOT alter the `vN.M` token (out of A5 scope). It is a genuine C-2/Phase-E concern that the coder surfaced rather than silently dropped (good).

**CARRY-FORWARD TO C-2 (required):** when C-2 builds the real `/changelog/` tree, Check 34 will activate. The C-2 coder/oracle MUST resolve whether the real CHANGELOG's nested `vN.M` mentions trip Check 34, and if so whether the changelog stream needs a Check-34 cross-ref-scope exclusion or an allowlist (measure-then-bound). The coder's own test fixture already documents the mitigation pattern (the synthetic changelog fixture deliberately carries NO `vN.M` token) — but that does not cover the real CHANGELOG content. Do not let this fall through at C-2.

---

## MANIFEST (A16) — PASS

`git diff test-fixtures/manifest.txt` is exactly the 3 v11 fixture hash lines (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`), which embed copies of the edited `scripts/` files — the expected consequence of the Phase-A `scripts/` edits, nothing spurious. A fresh `bash test-fixtures/build.sh --all --clean` this pass reproduced the identical 3-line diff (build rc=0), confirming the coder's manifest is current and deterministic. Per `regenerate-manifest-on-v11-surface` it must be staged in the C-1 commit (it is in the C-1 file set).

---

## SHOULD / NIT (non-blocking)

### SHOULD-1 — `_v8-resolved-archive.md` residue left in `known_supporting_for` / `_lib.sh` support / `v8_archive_basenames` (carry-forward to C-2)
The amendment §G reverses V3 §3.2: the 19 BD-001..019 become real entries and **no `_v8-resolved-archive.md` is emitted**, so §G directs dropping `_v8-resolved-archive.md` from the pack-backlog `support` attribute + `known_supporting_for` and removing the dead `v8_archive_basenames` SKIP in Check 34. **These removals are NOT in PLAN-BD-203 Phase A (A1–A16)** — the plan only schedules the `_rules.md` basename drop at B2. So this is a **plan gap, not a coder defect**: the coder implemented A1–A16 as written, and the residue is functionally inert at C-1 (no tree) and harmless at C-2 (an allowlist entry for a never-emitted file = a no-op; the v8 SKIP simply never fires). **Action:** Pack Chat/architect should confirm the `_v8-resolved-archive.md` residue + `v8_archive_basenames` deadness are explicitly addressed in C-2/Phase-B (drop them in lockstep with `_lib.sh` support + `_rules.md`) so no dead allowlist/SKIP lingers. File refs: `scripts/lib/per-entry/_lib.sh` `pack-backlog … support`; `scripts/validate-pack.py` `known_supporting_for["pack-backlog"]`, `v8_archive_basenames`.

### SHOULD-2 — untracked separate-session maintenance-docs present in the working tree
`git status` lists many untracked `IMPL-BD-200-*.md` / `PACK-REVIEW-BD-200-*.md` / `ARCHITECTURE-BD-208.md` files plus `PLAN-BD-203.md` and this review's siblings. None are C-1 artifacts. Same hygiene risk as BLOCKER-1: ensure they are not swept into the C-1 commit (explicit-pathspec staging covers this). Listed for Pack Chat awareness, not a coder issue.

### NIT-1 — `entry_sort_key` (pack-backlog) not widened for the suffix form (cosmetic, C-2)
`toc-regenerate.sh` `entry_sort_key` uses `^[A-Z]+-(\d+)$`, which does NOT match `BD-167b` → returns 0 → suffix entries sort to the TOP of their status group in the real tree (ahead of `BD-001`) rather than adjacent to `BD-167`. The plan A6/A7 did not task the sort key (only title regex + group order), so the coder correctly implemented exactly what was specified. Purely cosmetic TOC ordering; surfaced for the C-2 oracle to decide whether `BD-167b` adjacency to `BD-167` matters. File: `scripts/lib/per-entry/toc-regenerate.sh` `entry_sort_key`.

### NIT-2 — A8 deferral scope token `v11.0` vs plan's `version` placeholder
A8's typed deferral comment reads `# TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206`; the plan literal was `# TODO(version): TD-TBD …`. `v11.0` is a valid concrete scope (arguably better than the `version` placeholder) and satisfies the typed format in `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene". No action; noted for completeness.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED / measured) | Conclusion |
|---|---|---|
| **read-in-full + no-derivation** | Every named doc Read DIRECTLY this pass — see READ-IN-FULL row below (per-file proof). PLAN §2/§3/§7 read across both pages (L1–542 + 543–702); design pair read in full; IMPL-REPORT read in full; every changed file's diff read via `git diff`; CLAUDE.md `## Pack memory` provided in full via system context + read directly; the 5 curated memory files read. No named doc derived. | COMPLIANT |
| **no-prior-reviews-to-reviewer** | No `PACK-REVIEW-*.md` was read or referenced; findings derive solely from PLAN-BD-203 + the V3/AMENDMENT design pair + the live diff + independent measurement. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Held each validator change to the measured end-state: `BD-167b`→`['BD-167b']`, `v11`→`[]` (no false version widening); `^BD-\d+[a-z]*\.md$` admits only the 2 suffix files; Check 32′ verified vacuously-true tree-absent + (via test) pass tree-present/no-monolith, fail monolith-present. No allowlist widened to swallow unclassified hits. | COMPLIANT |
| **enumerate-encoding-surfaces** | Verified each engine/validator change has its lockstep test (table above); ran all 7 tests rc=0; the 2 extended tests (recommendation/pack-help) confirmed required by A14a/A14b. No asymmetric coverage. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly C-1; led with the VERDICT; classified every finding with file/path + concrete fix; no edge-case sprawl. The one out-of-scope working-tree change surfaced as BLOCKER-1, not silently ignored. | COMPLIANT |
| **agents-never-commit** | Ran only read-only verbs (`git status`, `git diff`, `git rev-parse`) + off-tree `/tmp` smoke + read-only validate-pack/test runs. HEAD `a630a31` unchanged; no `git add`/`commit`/`push`/`tag`/`rm`. Sole write = this report at the prompted path. | COMPLIANT |
| **rules-applied-verification-block** | This block; every row carries QUOTED/measured evidence (none empty); READ-IN-FULL row below with per-file direct-read proof. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `PLAN-BD-203.md` | YES | 702 lines; read L1–542 + offset 543 lim 160 → L702 "**End of PLAN-BD-203.md**". |
| `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines; L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design …" → L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 244 lines; L1 "# ARCHITECTURE-BD-203-V3-AMENDMENT …" → L244 "**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**". |
| `IMPL-BD-203-C1.md` | YES | 283 lines; L1 "# IMPL-BD-203-C1 — Phase A …" → L283 "**End of IMPL-BD-203-C1.md**". |
| `scripts/lib/per-entry/decompose.sh` (diff) | YES | full `git diff` read (A1/A2/A8 hunks). |
| `scripts/lib/per-entry/_lib.sh` (diff) | YES | full `git diff` (A3/A4/A8 hunks). |
| `scripts/lib/per-entry/toc-regenerate.sh` (diff) | YES | full `git diff` (A3/A4/A6/A7 hunks). |
| `scripts/lib/per-entry/mirror-generate.sh` (diff) | YES | full `git diff` (A8 header). |
| `scripts/validate-pack.py` (diff) | YES | full `git diff` (STREAMS/Check 3/32′/34/40/48/PM-only). |
| `scripts/lib/recommendation.sh` (diff + L220-235) | YES | full `git diff` + Read offset 220 lim 45 (`_rec_backlog_growth_30d`). |
| `scripts/lib/detect.sh` (diff) | YES | full `git diff` (A14b pack-surface conditional + DENY-LIST markers). |
| `scripts/tests/*` (5 named + 2 lockstep, diff) | YES | `git diff` spot-read of checks-32-33-34 + checks-36-37-38; all 7 executed rc=0. |
| `test-fixtures/manifest.txt` (diff) | YES | `git diff` + fresh rebuild reproduced identical 3-line diff. |
| `pack-ops/BACKLOG.md` (diff) | YES | full `git diff` (the out-of-scope BD-206/BD-208 change → BLOCKER-1). |
| `CLAUDE.md` `## Pack memory` | YES | provided in full via system context; conventions read directly. |
| `feedback_review_fix_cycle.md` | YES | bounded-cycle rule applied (review-1 of the cycle). |
| `feedback_ci_guard_design_measure_then_bound.md` | YES | measure-then-bound applied to A4/A5/A9/A12/A13. |
| `feedback_scope_deliverables_to_the_ask.md` | YES | verdict-first, exactly-C-1, no sprawl. |
| `feedback_agent_output_rules_applied_block.md` | YES | this block authored per the rule (QUOTED evidence, no empty cells). |
| `feedback_agents_read_rule_docs_in_full.md` | YES | curated set read directly; no derivation. |

**No named document was derived rather than read.** All load-bearing measurements (validate-pack GREEN rc=0; 7 tests rc=0; the CROSS_REF_RE tokenization of `BD-167b`/`v11.0`/`v11`; the decompose/changelog/TOC smoke; the manifest reproduce; the `pack-ops/BACKLOG.md` out-of-scope diff) were independently captured this pass at HEAD `a630a31` via Bash/Read.

**End of PACK-REVIEW-BD-203-C1.md**
