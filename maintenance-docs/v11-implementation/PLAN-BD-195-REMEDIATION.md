# PLAN-BD-195-REMEDIATION

**Status:** Executable commit-by-commit plan (fresh pack-planner). Plan-only;
no edits to source, no git state changes.
**Branch:** `v11-dev`. **HEAD at planning:** `c440bdf`
(`c440bdf742a52f6fc0d66b75f6f07a88771f374e`).
**Trusted basis (the ONLY inputs):**
- `BD-195-CLEAN-FOUNDATION.md` (kinds K1–K7, principles, rulings JC-1..JC-7).
- `AUDIT-BD-195-VERIFIED-FINDINGS.md` (67 confirmed findings at `file:line`).

Every load-bearing claim below was re-read at `file:line` in the live repo at
HEAD `c440bdf` (Empirical-Evidence Blocks in §6). This plan is a self-contained,
ordered, coder-ready commit sequence: every per-finding fix recipe and every
guard design lives INLINE in the per-commit specs of §4, with the 9 user
rulings of 2026-06-01 applied. A coder can execute any commit Cn from this
document alone — no other doc is required.

> Note on HEAD drift: the upstream design measured at HEAD `3178fa4`; planning
> re-measured at `c440bdf`. All load-bearing findings reproduce at the same
> `file:line` (EEB-A..EEB-H). The four commits since `3178fa4` are pack-ops
> doc commits that did not move any finding locus.

---

## 0 — How to read this plan

- **§1** USER RULINGS applied (the 9 NUD dispositions as binding facts).
- **§2** FINDING LEDGER — all 67 findings → exactly one commit OR
  non-actionable; plus the new `.mcp.json.example` leak. Sums to 67.
- **§3** DEPENDENCY DAG + the red-CI window resolution (the safe push order).
- **§4** PER-COMMIT SPEC — for each commit: files, finding IDs, the full
  inline fix recipes (and guard design for C1/C2/C6), Check-36 keyword +
  validity, manifest-regen decision, verification commands, executor, gate.
- **§5** COVERAGE-GAP RESOLUTION (K3.7) + open risks.
- **§6** Empirical-Evidence Blocks.
- **§7** Rules-Applied Verification Block.

**Self-contained convention:** this plan RESTATES every fix recipe and guard
design inline. Each commit spec in §4 carries (c) the verbatim per-finding fix
recipes for the findings it fixes, and — for C1/C2/C6 — the full guard design
(measure → categorize → fix-recipe → allowlist → verify). The §2 ledger's
disposition column names the in-plan recipe location for each finding. A coder
reads the recipe in §4 and executes it without opening any other document.

---

## 1 — User rulings applied (binding facts, 2026-06-01)

| NUD | Finding(s) | Ruling applied in this plan |
|---|---|---|
| NUD-1 | K1.11–K1.14 | RECLASSIFY NOT-A-DEFECT. **C1b is DROPPED — it does not fire.** The 4 findings are non-actionable; the JC-1 strip locus (§2.1) leaves the shared link layer intact and these 4 stay green as-is. |
| NUD-2 | K2.2 (`bootstrap.sh`) | Option A — STRIP the pack-only skills-distribution explainer comment entirely; no replacement destination invented. C9. |
| NUD-3 | K3.3/K3.4/K3.5 (BD-195 BACKLOG entry) | Option A — RE-CITE the live trusted basis (`PLAN-BD-195-REMEDIATION.md` + `BD-195-CLEAN-FOUNDATION.md` + `AUDIT-BD-195-VERIFIED-FINDINGS.md`), replacing the deleted-doc segmentation narrative. **PM-only; Pack-Chat-direct edit at execution time** (exact wording is a PM editorial call). C7. |
| NUD-4 | K3.8/K3.9/K3.10, B.15, B.16 (README layout) | Option A — STRIP the removed-doc rows; CORRECT the two mis-sited rows to `pack-ops/`; **NO annotations.** C8. |
| NUD-5 | K5.7 (`PACK-FEEDBACK.md`) | Option A — swap ONLY version-LABEL fields to the current version; LEAVE illustrative prose ("after the v9 split…") intact. C9. |
| NUD-6 | K5.11 (`METHODOLOGY.md`) | Option A — fix the stale pack-version token + date (values pulled from the README version table SSOT at fix time); KEEP internal doc-version 2.1 (no content-revision bump). **NUD-6 ruled → no C4b split needed; K5.11 lands inside C4.** |
| NUD-7 | K5.15 (README check count) | Option A — recompute counts only (against the real Check NN set in `validate-pack.py`); NO version-cell narrative. C8. |
| NUD-8 | B.5–B.10 (per-entry `scripts/lib/` path) | Option B — DROP the concrete pack-internal path; describe the mechanism abstractly; apply ONE consistent phrasing across all 6 files. C9. |
| NUD-9 | B.17 (README skill count) | Option B — reconcile against `PLATFORM-SKILLS.md` (the count SSOT) and set the README to match it, WITHIN the same commit (C8). Not deferred. |

**Also in force (not a NUD):** the new leak
`project-template/.mcp.json.example:9` → dead `supporting-docs/CLI-PM-SETUP.md`
is a real fix folded into **C3** (CLI-PM-SETUP.md is NOT client-installed —
confirmed EEB-G).

**Consequences for the commit set (vs. the original 10-commit draft):**
- C1b — DROPPED (NUD-1).
- C4b — NOT created (NUD-6 ruled Option A; K5.11 lands in C4).
- C7/C8/C9 — fire with the chosen options above.
- All NUD gates are now CLOSED (rulings in hand); no commit waits on a
  further user disposition. C7/C8 remain PM-only Pack-Chat-direct edits; C9
  is a fresh-coder commit.

---

## 2 — Finding ledger (all 67 + the new leak)

Every confirmed finding maps to exactly one commit OR is non-actionable.
Sum of actionable (63) + non-actionable (4) = **67**. The new
`.mcp.json.example` leak (not among the 67) lands in C3.

| Finding | Commit | Disposition / recipe pointer |
|---|---|---|
| K1.1 | C1 | C1 §2.1 grammar regex (bash ERE arm strip) |
| K1.2 | C1 | C1 §2.1 (Python `DEP_ENTRY` arm strip) |
| K1.3 | C1 | C1 recipe (dep-grammar docstring) |
| K1.4 | C1 | C1 recipe (capture-group doc) |
| K1.5 | C1 | C1 §2.1 dispatch-guard |
| K1.6 | C1 | C1 recipe (emit-comment) |
| K1.7 | C1 | C1 recipe (fixture bullet) |
| K1.8 | C1 | C1 recipe (flip test → not_contains) |
| K1.9 | C1 | C1 recipe (replace sample + error-guard test) |
| K1.10 | C1 | C1 recipe (flip to rejection assertion) |
| K7.1 | C1 | C1 §2.1 (parity `DEP` regex) |
| K1.11 | — | **NON-ACTIONABLE (NUD-1 reclassify NOT-A-DEFECT).** Shared link layer; stays green. |
| K1.12 | — | **NON-ACTIONABLE (NUD-1).** |
| K1.13 | — | **NON-ACTIONABLE (NUD-1).** |
| K1.14 | — | **NON-ACTIONABLE (NUD-1).** |
| K2.1 | C3 | C3a recipe + C2 §2.2 guard (→ `docs/pack/METHODOLOGY.md`, ×3 copies) |
| K2.2 | C9 | C9 recipe + NUD-2 Option A (STRIP explainer) |
| K3.1 | C5 | C5 recipe (drop dangling V3.2-DELTA; keep V3.3-DELTA) |
| K3.2 | C5 | C5 recipe (drop V3.2-DELTA basename + §clause) |
| K3.3 | C7 | C7 recipe + NUD-3 Option A (re-cite live basis) — PM-only |
| K3.4 | C7 | C7 recipe + NUD-3 — PM-only |
| K3.5 | C7 | C7 recipe + NUD-3 — PM-only |
| K3.6 | C4 | C4 recipe (→ MIGRATION-v10-to-v11.md + sunset framing) |
| K3.7 | **C5** | C5 recipe (replace dead QUICKSTART hyperlink). **Coverage-gap resolution — see §5.1.** |
| K3.8 | C8 | C8 recipe + NUD-4 (STRIP row) — PM-only |
| K3.9 | C8 | C8 recipe + NUD-4 (STRIP row) — PM-only |
| K3.10 | C8 | C8 recipe + NUD-4 (STRIP V10-PREDESIGN token only) — PM-only |
| K3.11 | C5 | C5 recipe (remove live present-tense directive block) |
| K3.12 | C6 | C6 recipe (JC-5: NO content edit; soft-advisory guard C6 §2.3) |
| K3.13 | C6 | C6 recipe (JC-5-class: NO content edit; covered by C6 §2.3 guard) |
| K4.1 | C3 | C3a recipe + C2 §2.2 guard (drop V10-DESIGN.md) |
| K4.2 | C3 | C3a recipe + C2 §2.2 guard (drop research-doc + SHA) |
| K4.3 | C3 | C3a recipe (→ `docs/pack/METHODOLOGY.md`, Gemini) |
| K4.4 | C3 | C3a recipe (drop dead primary; keep fenced pack-ops fallback) |
| K4.5 | C3 | C3a recipe + C2 §2.2 guard (qualify "pack maintainers only" / retain anchor-exempt) |
| K5.1 | C3 | C3a recipe (de-version v10→v11 title) |
| K5.2 | C3 | C3a recipe (version-neutral) |
| K5.3 | C3 | C3a recipe + JC-6 (version-neutral RAG label, Gemini) |
| K5.4 | C3 | C3a recipe + JC-6 (version-neutral RAG label, ×3 copies) |
| K5.5 | C3 | C3a recipe (headline v10→v11 migrator) |
| K5.6 | C3 | C3a recipe (kickoff seed v10→v11) |
| K5.7 | C9 | C9 recipe + NUD-5 Option A (label-only swap; keep prose) |
| K5.8 | C3 | C3b recipe (live parity claim → current version) |
| K5.9 | C4 | C4 recipe (identity header → v11.0) |
| K5.10 | C4 | C4 recipe (identity header → v11.0) |
| K5.11 | C4 | C4 recipe + NUD-6 Option A (version token + date; keep doc-version 2.1) |
| K5.12 | C4 | C4 recipe (→ v11) |
| K5.13 | C4 | C4 recipe (→ v11, deliverable cleanliness) |
| K5.14 | C4 | C4 recipe (→ v11) |
| K5.15 | C8 | C8 recipe + NUD-7 Option A (recompute counts only) — PM-only |
| B.1 | C3 | C3a recipe + JC-3 (redirect `cp -r` → init-project.sh/QUICKSTART) |
| B.2 | C3 | C3a recipe + JC-4 (rewrite SSOT-table paths to client-resolvable) |
| B.3 | C3 | C3a recipe (`.v9-customized` → `.v10-customized`) |
| B.4 | C3 | C3a recipe (`bash scripts/pack-tracker.sh` → `pack tracker`) |
| B.5 | C9 | C9 recipe + NUD-8 Option B (drop path; abstract phrasing) |
| B.6 | C9 | C9 recipe + NUD-8 |
| B.7 | C9 | C9 recipe + NUD-8 |
| B.8 | C9 | C9 recipe + NUD-8 |
| B.9 | C9 | C9 recipe + NUD-8 |
| B.10 | C9 | C9 recipe + NUD-8 |
| B.11 | C3 | C3b recipe (remove dangling `config_file` lines / blocks) — xcode (C3b) |
| B.12 | C5 | C5 recipe (re-point or drop ARCHITECTURE-V1.md) |
| B.13 | C5 | C5 recipe (re-point or drop ARCHITECTURE-V1.md ×2) |
| B.14 | C5 | C5 recipe (correct abbreviated IMPL-REPORT basename) |
| B.15 | C8 | C8 recipe + NUD-4 (correct row → pack-ops/) — PM-only |
| B.16 | C8 | C8 recipe + NUD-4 (correct row → pack-ops/) — PM-only |
| B.17 | C8 | C8 recipe + NUD-9 Option B (reconcile vs PLATFORM-SKILLS.md) — PM-only |
| (new leak) `.mcp.json.example:9` | C3 | C2 §2.2 guard + C3a recipe (STRIP / re-point CLI-PM-SETUP cite) |

**Per-commit finding counts (actionable):** C1 = 11 · C3 = 18 (+1 new leak) ·
C4 = 7 · C5 = 7 · C6 = 2 (guard-covered, no content edit) · C7 = 3 · C8 = 7 ·
C9 = 8 = **63 actionable**. Non-actionable = 4 (K1.11–K1.14). **63 + 4 = 67.**

---

## 3 — Dependency DAG + safe push order

### 3.1 — The DAG

```
C1 (JC-1 grammar strip + error-guard)        independent — lands FIRST
        (C1b DROPPED per NUD-1)

C2 (JC-2 guard broadening)  ──┐
                              ├─► C3 (client-surface STRIP fixes)
                              └─► C4 (supporting-docs currency)

C5 (pack-internal dangling-doc + QUICKSTART)  independent
C6 (JC-5 soft-advisory guard)                 independent
C7 (PM-only BACKLOG de-citation)              independent (PM-only)
C8 (PM-only README layout/counts)             independent (PM-only)
C9 (NUD-2/5/8 cleanup)                        depends on C2 (its fixes are
                                              project-surface; C2's broadened
                                              guard verifies them clean)
```

**Hard ordering edges (load-bearing):**
1. **C1 first.** It changes shipped library grammar + tests and is the
   BD-185-restart hard prerequisite. No other commit depends on it, but it is
   the agreed lead.
2. **C2 before C3, C4, C9.** The broadened Check 43/37 guard (C2) must exist
   so the client-surface STRIP fixes (C3/C4/C9) can be verified clean
   against the broadened walk. Measure-then-bound: C2's allowlist (the two
   proto self-imports — §2.2 / EEB-H) is sized against the projected
   post-C3/C4/C9 tree.
3. C5, C6 are independent of all of the above and of each other.
4. C7, C8 are PM-only and independent (no validator dependency for content;
   C8 must still pass any README-asserting check post-edit).

### 3.2 — Red-CI window (CI-must-pass-on-every-push) — RESOLUTION

Landing C2 (the broadened guard) as a standalone green commit BEFORE C3/C4/C9
leaves CI RED in the interval: the broadened guard FIRES on the still-unfixed
client-surface STRIP set (K4.2, the `.mcp.json.example:9` leak, the pm-startup
`supporting-docs/` family, etc.). The pack rule "CI must pass on every push"
forbids pushing C2 alone.

**The fix:** couple the guard with the client-surface fixes at the push
boundary and keep the rest sequential.

- **Collapse C2 + C3 (+ the supporting-docs slice that C2's guard
  fires on) into one ATOMIC push boundary.** Concretely: C2, C3a, C3b, and C4
  are authored as separate *commits* (each a self-contained review/fix unit)
  but are **pushed together in one push** so no intermediate push leaves the
  broadened guard firing on an unfixed STRIP target. C9's project-surface
  fixes are likewise included in that push group (C9 fixes are caught by the
  C2 guard too — K2.2 bootstrap is on a `.sh` already walked, but B.5–B.10
  and PACK-FEEDBACK are walked client surfaces).

  > Rationale for separate commits inside one push: each commit keeps its own
  > bounded review/fix cycle + IMPL-REPORT (auditability), while the push
  > boundary preserves green CI. This honors both `bounded-review-fix-cycle`
  > and the CI-green rule.

**Push groups (the safe order):**

| Push group | Commits | Why grouped |
|---|---|---|
| PG-1 | C1 | independent; green on its own (tracker libs not walked by Check 43 for the broadened ext-set until C2) |
| PG-2 | C2 → C3a → C3b → C4 → C9 | guard + every client-surface STRIP it fires on land in ONE push; no intermediate push is red |
| PG-3 | C5 | independent; green on its own |
| PG-4 | C6 | independent; soft-advisory is non-fatal (exit 0) by design |
| PG-5 | C7 | PM-only; independent |
| PG-6 | C8 | PM-only; independent |

> Push grouping is a Pack-Chat / user decision at execution time
> (`agents-never-commit`); this plan supplies the SAFE order, not a push
> instruction. Within PG-2 the commit order is C2 first (guard exists), then
> the surface fixes in any order; the GROUP is pushed only after the last
> surface fix in the group lands and `validate-pack.py` is green.

---

## 4 — Per-commit specification

Legend for each commit: **(a)** files · **(b)** finding IDs · **(c)** recipe
pointer · **(d)** Check-36 keyword + validity · **(e)** manifest-regen
decision · **(f)** verification commands · **(g)** executor + gate.

> **Manifest rule (binding, `regenerate-manifest-v11-surface`):** any commit
> touching `project-template/` | `scripts/` | `pack-ops/` | `supporting-docs/`
> MUST run `bash test-fixtures/build.sh --all --clean` and stage
> `test-fixtures/manifest.txt` in the SAME commit **IFF the manifest diff is
> non-empty.** The manifest captures per-fixture init-project.sh output SHAs.
> EEB-F establishes: only `scripts/lib/detect.sh` is staged into fixtures from
> `scripts/lib/`; the tracker libs and `validate-pack.py` are NOT staged, and
> `README.md` / `pack-ops/BACKLOG.md` do not feed fixtures. So the *expected*
> diff for scripts-only / pack-ops-only / README-only commits is EMPTY — but
> the coder MUST still RUN the build and stage only if the diff is in fact
> non-empty (run-then-check; never skip the run on a prediction).

### C1 — JC-1 phase-task `BD-` strip + error-guard

- **(a) Files:** `scripts/lib/tracker-phase-task.sh`,
  `scripts/lib/tracker-promote.sh`,
  `scripts/tests/test-tracker-phase-task.sh`,
  `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md`,
  + NEW error-guard test (add cases to `test-tracker-phase-task.sh` per the
  (c) §2.1 Step-3 error-guard recipe, or a new
  `scripts/tests/test-tracker-phase-task-bd-guard.sh` — coder
  picks; if a new file, mind `filename-uniqueness-heuristic` and wire it into
  the CI runner so Check 42 stays green).
- **(b) Findings:** K1.1, K1.2, K1.3, K1.4, K1.5, K1.6, K1.7, K1.8, K1.9,
  K1.10, K7.1 (11).
- **(c) Recipe — §2.1 JC-1 guard design (measure-then-bound) + per-finding
  recipes (all inline; nothing referenced elsewhere):**

  **§2.1 — JC-1: strip `BD-` from the project phase-task dependency grammar +
  error-guard.**

  **Step 1 — Measure (the `BD-` occurrences in the phase-task dependency
  grammar surfaces).** Verbatim grep at HEAD (full output in EEB-A/EEB-I):

  | Occurrence | Surface | Class |
  |---|---|---|
  | `tracker-phase-task.sh:75` | dep-grammar docstring | STRIP |
  | `tracker-phase-task.sh:113` | capture-group docstring | STRIP |
  | `tracker-phase-task.sh:132` | bash ERE `tracker_phase_task_dependency_re` | STRIP |
  | `tracker-phase-task.sh:208` | Python `DEP_ENTRY` regex | STRIP |
  | `tracker-promote.sh:390` | phase-task emit-comment | STRIP |
  | `tracker-promote.sh:1151` | phase-task dispatch comment | STRIP |
  | `tracker-promote.sh:1155` | phase-task dispatch-guard ERE | STRIP |
  | `test-tracker-phase-task.sh:113,132,149,204-205` | grammar-asserting tests + parity DEP regex | STRIP (flip to rejection) |
  | `fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md:26` | `- BD-108` dep bullet | STRIP |
  | `tracker-links.sh:12,71,132 + validate_id_shapes/_tlk_is_valid_pack_id` | SHARED link-shape vocabulary | **KEEP** (boundary — NUD-1) |
  | `tracker-migrate-forward.sh:990` (`BD-*|TD-*` entry-Blockers arm) | entry-level Blockers grammar | **KEEP** (JC-1 explicitly leaves untouched) |
  | `test-tracker-links.sh:106,169 · test-tracker-cycle-check.sh:168 · fixtures/tracker-links/id-map.json:5-6` | SHARED link/cycle tests + fixtures (the intact LINK layer) | **KEEP** (the fixed strip locus leaves the shared validator intact; NUD-1 only formalizes their reclassification) |

  **Step 2 — Categorize.** STRIP = the phase-task `Dependencies:` bullet
  grammar (`DEP_ENTRY` / `tracker_phase_task_dependency_re`), the Path-2
  phase-task promotion dispatch-guard that emits phase-task edges, their
  docstrings/comments, the grammar-asserting tests, and the fixture
  IMPLEMENTATION-PLAN dep bullet. KEEP = the SHARED link-orchestration
  vocabulary (`tracker_links_validate_id_shapes`) and the entry-level
  Blockers grammar (`tracker-migrate-forward.sh:990`) — JC-1 explicitly
  preserves the pack's own-backlog `BD-` handling, and the entry-Blockers
  path routes `BD-*|TD-*` through that shared validator for legitimate
  `TD↔BD` cross-namespace links (V3.3 §5.1).

  **Strip locus (load-bearing, CONFIRMED — not a choice):** JC-1 says
  "phase-task dependency grammar" AND expressly preserves the pack's
  own-backlog `BD-` handling. Those two clauses TOGETHER fix the strip locus
  mechanically: strip `BD-` ONLY at the phase-task dispatch-guard regex
  (`tracker-promote.sh:1155`) and the
  `DEP_ENTRY`/`tracker_phase_task_dependency_re` grammar — NOT from the SHARED
  `tracker_links_validate_id_shapes` / `_tlk_is_valid_pack_id`. Stripping the
  shared validator would break the entry-Blockers path
  (`tracker-migrate-forward.sh:990` `BD-*|TD-*` arm → `validate_id_shapes`)
  that JC-1 EXPLICITLY leaves untouched, so it is self-evidently forbidden by
  JC-1's own-backlog clause — not a live design alternative. With the strip
  locus thus fixed, the SHARED link validator stays intact and the four
  findings K1.11–K1.14 (which test that shared LINK layer, not the phase-task
  `DEP_ENTRY` grammar) test a LEGITIMATE own-backlog/cross-namespace feature.
  The remaining open question is therefore NOT "where to strip" (settled) but
  "are K1.11–K1.14 contamination at all?" → ruled NUD-1 (reclassified
  NOT-A-DEFECT; see §1).

  **Step 3 — Fix-recipe (per STRIP; these ARE the K1.1–K1.10 / K7.1 recipes):**
    - Grammar regexes (K1.1/K1.2/K7.1): change
      `(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)` → `(phase-\d+(?:\.\d+)?|TD-\d+)`
      in all three encoding copies (bash ERE, Python `DEP_ENTRY`, the test's
      inline parity `DEP`).
    - Dispatch-guard (K1.5): change the :1155 alternation to drop
      `|BD-[0-9]+`; a `BD-` blocker on a promoted TD is then passed through to
      flat-file (warning path) but NOT linked as a phase-task dependency edge.
    - Docstrings/comments (K1.3/K1.4/K1.6, :1151): drop `BD-` from the
      documented grammar; K1.6 comment states phase-task Dependencies emit
      `phase-N(.M)`/`TD-NNN` only.
    - Fixture (K1.7): delete the `- BD-108` bullet from the phase-task
      `Dependencies:` block.
    - Tests (K1.8/K1.9/K1.10): flip `assert_contains "...BD-[0-9]+"` →
      `assert_not_contains`; replace the `- BD-108` parser-input sample with a
      `TD-`/`phase-` sample; flip the "captures BD-108 as dep target"
      assertion to assert the **error-guard** rejects `BD-` (next item).
    - **Error-guard (the NEW JC-1 mandate):** add a typed-error check at the
      phase-task dependency parse boundary in `tracker-phase-task.sh` — after
      the line matches the (now BD-free) `DEP_ENTRY`, if the **dependency
      TARGET token (capture-group-1 of the dep bullet)** is a `BD-[0-9]+`, emit
      a typed `tracker_error_emit "validation"` ("`BD-` is not a valid
      phase-task dependency target; phase-task Dependencies accept
      `phase-N(.M)` and `TD-NNN` only"). **Binding (pinned recipe):** the guard
      MUST test the captured TARGET position ONLY — never grep the raw bullet
      text — so a legitimate free-text annotation that mentions `BD-NNN` (e.g.
      `- TD-031  (see BD-108 for context)`) does NOT false-positive. JC-1
      scopes the rejection to "`BD-` as a project phase-task dependency
      *target*"; the recipe quotes that scoping. This converts silent
      admission into a loud failure. New tests assert: (i) the guard FIRES on
      `- BD-NNN` in target position; (ii) the guard does NOT fire on `BD-NNN`
      appearing only in annotation free-text after a valid `TD-`/`phase-`
      target.

  **Step 4 — Size the allowlist.** This guard is an in-grammar error-guard,
  not an allowlist-style scanner — its "allowlist" is the accepted target
  vocabulary `{phase-N, phase-N.M, TD-NNN}` sized exactly to the KEEP set (the
  pack's own-backlog `BD-` handling lives entirely in the link/Blockers layer,
  untouched).

  **Step 5 — Verify clean post-fix.** After the STRIP recipe: (a) the
  phase-task parser rejects a `BD-` dep bullet with the typed error (new test
  PASSES); (b) `test-tracker-phase-task.sh` group-1 bash-vs-Python parity
  still holds on the BD-free grammar; (c) the entry-Blockers path
  (`test-tracker-links.sh` BD↔ cases) still PASSES — proving the own-backlog
  `BD-` handling is untouched by the fixed strip locus. (See (f) for the
  command set.) With the strip locus fixed (shared validator intact),
  K1.11–K1.14 stay green as-is; NUD-1 is ruled (reclassified NOT-A-DEFECT).
- **(d) Keyword:** `pack-only`. Valid: all touched paths are under `scripts/`
  — none under `project-template/` or `supporting-docs/` (EEB-A). Check 36
  pack-only deny-set = `("project-template/", "supporting-docs/")` (EEB-E).
- **(e) Manifest:** RUN `bash test-fixtures/build.sh --all --clean`. Expected
  diff EMPTY (tracker libs + their tests are not staged into fixtures — only
  `scripts/lib/detect.sh` is; EEB-F). Stage `manifest.txt` only if non-empty.
- **(f) Verify:** `bash scripts/tests/test-tracker-phase-task.sh` (incl. the
  new guard cases: guard FIRES on `- BD-NNN` in target position; does NOT
  fire on `BD-NNN` in annotation free-text after a valid target) &&
  `bash scripts/tests/test-tracker-promote-path2.sh` &&
  `bash scripts/tests/test-tracker-links.sh` &&
  `bash scripts/tests/test-tracker-cycle-check.sh` (these last two PROVE the
  shared link layer is untouched — NUD-1 evidence) &&
  `python3 scripts/validate-pack.py` (full PASS; Check 43 unaffected).
- **(g) Executor + gate:** fresh `pack-coder`. **`enumerate-encoding-surfaces`:**
  the grammar edit (bash ERE + Python `DEP_ENTRY`), its docstrings, the
  parity `DEP` regex in the test, the grammar-asserting tests, and the
  fixture bullet are ALL updated in lock-step in this single commit; the new
  error-guard + its tests land here too. Bounded review/fix cycle.
- **NUD-1 note:** C1b is DROPPED. The K1.11–K1.14 link/cycle tests + id-map
  fixture are NOT edited; they stay green and prove the strip locus is
  correct (verification (f)).

### C2 — JC-2 client-surface leak-guard broadening

- **(a) Files:** `scripts/validate-pack.py`,
  `scripts/tests/test-validate-pack-check-43.sh`.
- **(b) Findings:** none directly (guard design); enables verification of
  C3/C4/C9 STRIP fixes.
- **(c) Recipe — §2.2 JC-2 guard design (measure-then-bound), full and inline:**

  **§2.2 — JC-2: broaden the client-surface leak-guard (Check 43 / Check 37).**
  JC-2 broadens the existing client-surface leak guard along four axes: (i)
  bare pack-doc basenames, (ii) commit-SHA-as-provenance, (iii) scan
  `.example`/`.proto`/`.env.example`, (iv) bare-prose (non-backtick) refs.
  Measure-then-bound governs what actually lands.

  **Step 1 — Measure (every occurrence the broadening would newly match).**
  Verbatim greps at HEAD (full output in EEB-H/EEB-G):

  | Axis | Occurrence | Currently | Class |
  |---|---|---|---|
  | (iii) ext-scan | `.codex/config.toml.example`, `.mcp.json.example`, `.gemini/.env.example`, `proto/example/v1/example_service.proto`, `proto/common/v1/common.proto` | NOT walked (`example`/`proto` not in `_CHECK_40_FILE_EXTS`) | walk-set add |
  | (iii)+(i)+(ii) | `.codex/config.toml.example:13` — `V10-CODEX-MCP-RESEARCH.md (commit 73d480e)` | bypasses (unwalked + bare-prose + SHA) | **STRIP** (K4.2) |
  | (iii)+(i) | `.mcp.json.example:9` — `supporting-docs/CLI-PM-SETUP.md` | bypasses (unwalked); CLI-PM-SETUP NOT client-installed (only METHODOLOGY + INSTALL-PROCEDURES are) | **STRIP — NEW LEAK not in the 67** |
  | (iii) | proto self-imports — `example/v1/example_service.proto:7` `import "common/v1/common.proto";` + `common/v1/common.proto:5` self-ref (`grep -rn` over `project-template/proto/` — full output EEB-H) | would newly match the basename regex if `.proto` is walked | **KEEP** (resolve WITHIN the shipped `proto/` tree → legitimate self-import; the sole genuine JC-2 allowlist) |
  | (i)+(iv) | `README.md:9` — bare-prose `V10-DESIGN.md` | bypasses (no backticks) | **STRIP** (K4.1 / JC-3) |
  | (i) | `OPTIONAL-FEATURES.md:174` — bare `MERGE-STRATEGY.md` "in the pack repo" | anchor-EXEMPT | KEEP-or-qualify (K4.5) |
  | (i) | `PM-CHAT.md:530` — `docs/pack/MERGE-STRATEGY.md` primary | passes (resolves syntactically) but dead at client | **STRIP** (K4.4) |
  | supporting-docs prefix | pm-startup family `supporting-docs/METHODOLOGY.md` ×4 copies | passes (METHODOLOGY in installed-set) but `supporting-docs/` dir absent at client | **STRIP** (K2.1/K4.3) |
  | (supporting-docs prefix) | `project-template/README.md:13/38/44` — `supporting-docs/...` refs (`:13` = the `cp ... supporting-docs/METHODOLOGY.md ... docs/pack/METHODOLOGY.md` line; `:38`/`:44` = the "Directory boundary rule" prose describing the pack's two-dir layout) | walked by Check 43 (`_iter_client_installed_files()` does `(a) all regular files under project-template/ recursive` — validate-pack.py:4116-4140) | **NOT a standalone KEEP — STRIP-or-rework folded into the C3a JC-3 README rework** (this README is the v10-titled client README whose `cp -r` (B.1), `V10-DESIGN.md` cite (K4.1), and v10 title (K5.1) are all reworked in C3a; lines 13/38/44 are resolved by that rework, not by a permanent allowlist entry) |

  **Step 2 — Categorize.** STRIP = K4.2 (research-doc + SHA), the NEW
  `.mcp.json.example:9` CLI-PM-SETUP leak, K4.1 bare-prose V10-DESIGN.md, K4.4
  dead primary MERGE-STRATEGY path, the pm-startup
  `supporting-docs/METHODOLOGY.md` family (K2.1/K4.3). KEEP (the ALLOWLIST set,
  re-measured) = the two proto self-imports ONLY
  (`example/v1/example_service.proto` → `common/v1/common.proto`, and
  `common/v1/common.proto`'s self-ref) — they resolve within the shipped
  `proto/` tree. The `project-template/README.md:13/38/44` `supporting-docs/`
  refs are NOT an allowlist KEEP: they are STRIP-or-rework lines folded into
  the C3a JC-3 README rework (the same v10 client README B.1/K4.1/K5.1 touch),
  so they leave the allowlist sized to the proto pair alone. Separately, the
  correctly-anchored "in the pack repo" pack-as-product pointers (K4.5 + the 6
  anchored hits) stay exempt via the EXISTING anchor mechanism — no allowlist
  growth.

  **Critical refinement (the `supporting-docs/` prefix gap):** the current
  Check 43 CLASS-C test FAILs a `supporting-docs/<X>` cite only when `<X>` is
  NOT in the client-installed set. But the LEAK is the `supporting-docs/`
  DIRECTORY reference itself — at a client there is no `supporting-docs/`
  directory, so even `supporting-docs/METHODOLOGY.md` (content installed at
  `docs/pack/`) is a dead PATH. JC-2 broadening: a qualified `supporting-docs/`
  path on a client surface FAILs regardless of whether the basename is
  installed elsewhere — the remediation is to cite the client-resolvable
  `docs/pack/<X>` path, not the pre-install pack path. Note on
  `project-template/README.md:13/38/44`: these `supporting-docs/` refs are NOT
  carved out by a standalone allowlist exception — they are resolved by the
  C3a JC-3 README rework (which re-frames the pre-install copy step and the
  two-directory boundary prose for the v11 client README). Verify post-rework
  (Step 5) that the broadened guard runs clean on the reworked README rather
  than admitting the un-reworked lines via an allowlist (admitting them would
  treat contamination as legitimate by default).

  **Step 3 — Fix-recipe (per STRIP).** Each STRIP is fixed by its §1 finding
  recipe — and those recipes live inline in the commit specs that fix them:
  K4.2 (drop research-doc+SHA), the new `.mcp.json.example:9` (drop the
  `supporting-docs/CLI-PM-SETUP.md` cite or re-point to a client-resolvable
  setup note), K4.1 (drop V10-DESIGN.md), K4.4 (re-point primary), K2.1/K4.3
  (→ `docs/pack/METHODOLOGY.md`) — all in the C3a recipe set. The GUARD change
  (this commit): (a) add `example|proto` to the walked-extension set for
  Check 43 (and the `.env.example` double-extension); (b) add a bare-prose
  (non-backtick) pack-doc-basename class-test for the
  `_DENY_LIST_FILENAMES`-style basenames (`V10-*.md`, `MERGE-STRATEGY.md`,
  etc. — sourced from the pack-only doc inventory, NOT a hand-list); (c) add a
  commit-SHA-as-provenance class-test (`commit [0-9a-f]{7,40}` in a
  `Source:`/provenance context on a client surface); (d) tighten the
  `supporting-docs/` CLASS-C test to FAIL on the directory prefix regardless
  of installed-basename status.

  **Step 4 — Size the allowlist EXACTLY to KEEP.** The KEEP set re-measured at
  HEAD (`grep -rn` over `project-template/proto/` + the `supporting-docs/`
  walk in EEB-H) is the **two proto self-imports ONLY**. New allowlist entries
  (and ONLY these):
    - proto self-imports: `common/v1/common.proto`,
      `example/v1/example_service.proto` (and the bare `common.proto` /
      `example_service.proto` basenames) — these resolve WITHIN the shipped
      `proto/` tree, so they are legitimate. (The `google/protobuf/*` /
      `google/rpc/*` imports are external well-known protos, not
      pack-doc-basename matches — out of scope for this guard.)
    The allowlist gets NO other new entries. Specifically:
    - `project-template/README.md:13/38/44` are NOT added to the allowlist —
      they are STRIP-or-rework lines resolved by the C3a JC-3 README rework;
      if the rework leaves any `supporting-docs/` ref, it must be re-pointed to
      the client-resolvable `docs/pack/` form, not allowlisted. (An allowlist
      is not sized against lines that are themselves remediation targets.)
    - the 6 correctly-anchored "in the pack repo" pack-as-product pointers
      stay exempt via the EXISTING anchor mechanism (no allowlist growth
      needed).
    - Fence interaction (NIT): the tightened `supporting-docs/` prefix rule
      must NOT double-flag the per-line-fenced supporting-docs SOURCE files
      (`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`
      at validate-pack.py:4236-4237) — those fence entries cover legitimate
      pack-internal references inside the supporting-docs source files
      themselves, NOT a client surface citing the `supporting-docs/` prefix.
      The two are disjoint (the fenced files are not "client surfaces citing
      the prefix"), but the coder MUST assert this disjointness in the Step-5
      verification rather than leaving it implicit.
    The allowlist is NOT widened to admit any STRIP-classified or unclassified
    hit.

  **Step 5 — Verify clean post-fix.** After STRIP recipes + guard change +
  KEEP allowlist: run `python3 scripts/validate-pack.py` — Check 43 + Check 37
  PASS with the broadened walk (the 5 newly-walked files: 2 fixed, 1
  proto-allowlisted ×2, all clean). Two re-measure-driven verification adds:
  (a) confirm the broadened guard runs CLEAN on the C3a-reworked
  `project-template/README.md` (its 13/38/44 `supporting-docs/` refs resolved
  by the rework, NOT admitted via allowlist); (b) confirm the tightened
  `supporting-docs/` prefix rule does NOT double-flag the per-line-fenced
  supporting-docs source files (validate-pack.py:4236-4237) — assert the fence
  set and the client-surface prefix-hit set are disjoint. Add/extend
  `scripts/tests/test-validate-pack-check-43.sh` with: a `.example` file
  carrying a pack-only basename FAILs; a proto self-import PASSES (allowlist);
  a commit-SHA provenance FAILs; a `supporting-docs/<installed-basename>` cite
  on a client surface FAILs (prefix rule); a fenced supporting-docs source
  file does NOT trip the prefix rule (disjointness). Confirm no regression on
  the 6 anchored KEEP hits.
- **(d) Keyword:** `pack-only`. Valid: only `scripts/` paths (EEB-E).
- **(e) Manifest:** RUN build. Expected EMPTY (`validate-pack.py` not staged
  into fixtures — EEB-F). Stage only if non-empty.
- **(f) Verify:** `bash scripts/tests/test-validate-pack-check-43.sh` with the
  new cases (a `.example` carrying a pack-only basename FAILs; a proto
  self-import PASSEs via allowlist; a commit-SHA provenance FAILs; a
  `supporting-docs/<installed-basename>` cite on a client surface FAILs; a
  fenced supporting-docs source file does NOT trip the prefix rule) &&
  `python3 scripts/validate-pack.py`.
  > **Standalone C2 will FAIL `validate-pack.py`** because the broadened
  > guard fires on the still-unfixed C3/C4/C9 STRIP set. This is EXPECTED and
  > is exactly why C2 is push-grouped with C3/C4/C9 (PG-2, §3.2). The
  > per-check test (`test-validate-pack-check-43.sh`) uses synthetic fixtures
  > and PASSES standalone; the full-repo `validate-pack.py` green-state is
  > only asserted at the END of PG-2 (after the last STRIP fix lands).
- **(g) Executor + gate:** fresh `pack-coder`. `ci-guard-measure-then-bound`:
  allowlist sized to the measured KEEP set (proto pair) only — never widened
  to admit a STRIP or unclassified hit. Bounded review/fix.

### C3 — Client-surface leak + currency fixes (split C3a project-template / C3b xcode)

C3 is SPLIT because `xcode-companion-templates/` is neither `project-template/`
nor `supporting-docs/` (EEB-E), so a single `project-only` keyword cannot cover
it. Two commits:

**C3a — project-template/ client surfaces (`project-only`)**

- **(a) Files:** `project-template/README.md`,
  `project-template/.codex/config.toml.example`,
  `project-template/.mcp.json.example`,
  pm-startup triad — `project-template/skills/pm-startup/SKILL.md` +
  `project-template/.claude/skills/pm-startup/SKILL.md` +
  `project-template/.codex/skills/pm-startup/SKILL.md` +
  `project-template/.gemini/commands/pm-startup.toml`,
  `project-template/docs/pack/PM-CHAT.md`,
  `project-template/docs/pack/OPTIONAL-FEATURES.md`,
  `project-template/docs/pack/HELP-FRAGMENT.md`,
  `project-template/docs/pack/prompts/pm-chat.md`,
  `project-template/skills/boundary-investigation/SKILL.md`.
- **(b) Findings:** K2.1, K4.1, K4.2, K4.3, K4.4, K4.5, K5.1, K5.2, K5.3,
  K5.4, K5.5, K5.6, K5.8 (wait — K5.8 is xcode → C3b), B.1, B.2, B.3, B.4 +
  the NEW `.mcp.json.example:9` CLI-PM-SETUP leak.
  > Correction binding: K5.8 (`xcode-companion-templates/README.md`) and
  > B.11 (`xcode-companion-templates/Codex/config.toml`) move to **C3b**.
  > C3a findings = K2.1, K4.1–K4.5, K5.1–K5.6, B.1, B.2, B.3, B.4 + new leak.
- **(c) Recipe — per-finding fix recipes (inline, verbatim):** these are the
  STRIP set caught by the C2 broadened guard.
  - **K2.1** (`skills/pm-startup/SKILL.md:174` + identical `.claude/`/`.codex/`
    copies): the cite `supporting-docs/METHODOLOGY.md` on a client-shipped
    skill names a pack-only dir absent at client. METHODOLOGY ships to
    `docs/pack/METHODOLOGY.md` (init-project.sh `_CLIENT_INSTALLED_FILES` line
    1186). Fix: rewrite to the client-resolvable path `docs/pack/METHODOLOGY.md`.
    Apply identically across all three copies (trinity-of-copies).
  - **K4.1** (`README.md:9`, JC-3): client-shipped README cites `V10-DESIGN.md`
    (pack-only at `maintenance-docs/archive/`). Fix: state METHODOLOGY ships to
    `docs/pack/` without citing the pack-only design record.
  - **K4.2** (`.codex/config.toml.example:13`, JC-2): `.example` client-gated
    file cites `V10-CODEX-MCP-RESEARCH.md` (pack-only) AND `commit 73d480e`
    (SHA-as-provenance). Fix: drop the pack-only research-doc + SHA provenance;
    keep the factual MCP-config prose.
  - **K4.3** (`.gemini/commands/pm-startup.toml:171`): same
    `supporting-docs/METHODOLOGY.md` leak as K2.1, Gemini command surface. Fix:
    re-point to `docs/pack/METHODOLOGY.md`. (Parallels K2.1 across the
    pm-startup family; mind cross-CLI reference normalization.)
  - **K4.4** (`docs/pack/PM-CHAT.md:530`): the UN-gated PRIMARY path
    `docs/pack/MERGE-STRATEGY.md` does not resolve at client (MERGE-STRATEGY
    exists only at `pack-ops/`; PM-CHAT.md:526-534 shows the primary cite at
    :528-530 and a correctly DENY-LIST-fenced
    `(or pack-ops/MERGE-STRATEGY.md in the pack repo)` fallback at :531-534).
    **Pinned recipe (one, not two):** there is NO project-side SSOT doc for the
    forward-migration customization-preservation behavior (the behavior lives
    in the migrator + the pack-ops MERGE-STRATEGY.md), so DROP the dead primary
    `docs/pack/MERGE-STRATEGY.md` cite and KEEP the existing fenced
    `pack-ops/MERGE-STRATEGY.md` fallback as the sole, correctly-anchored
    reference. (The "point at a project-side SSOT" sub-option is foreclosed —
    no such SSOT exists; `P-missed-7`.)
  - **K4.5** (`docs/pack/OPTIONAL-FEATURES.md:174`): bare `MERGE-STRATEGY.md`
    "in the pack repo" (currently anchor-EXEMPT in Check 43, but still a dead
    pointer for a client who has no pack repo). Fix: keep the "in the pack
    repo" framing only if the cite is genuinely a pack-as-product pointer; else
    drop. Recommend: retain with explicit "(pack maintainers only)" qualifier
    so the client reader is not sent to a doc they cannot open.
  - **K5.1** (`README.md:1`, JC-3): title "v10". Fix: de-version v10→v11.
  - **K5.2** (`.codex/config.toml.example:16`): "v10 ships STDIO only". Fix:
    "v11" (or version-neutral "the pack ships STDIO only"); prefer
    version-neutral to avoid recurring currency churn.
  - **K5.3** (`.gemini/commands/pm-startup.toml:125`, JC-6): "manifest in v10".
    Fix: version-neutral the RAG-manifest label across the pm-startup triad
    (Gemini variant).
  - **K5.4** (`skills/pm-startup/SKILL.md:128` + `.claude/`/`.codex/` copies,
    JC-6): same "in v10" RAG-manifest label. Fix: version-neutral across the
    triad; apply identically to all three copies.
  - **K5.5** (`docs/pack/HELP-FRAGMENT.md:14`): verb manifest headlines
    `migrate-v9-to-v10.sh`; current migrator is `migrate-v10-to-v11.sh`. Fix:
    headline the v10→v11 migrator; note v9→v10 sunset.
  - **K5.6** (`docs/pack/prompts/pm-chat.md:35`): kickoff template seeds "Pack
    version: v10". Fix: "v11".
  - **B.1** (`README.md:5-7`, JC-3): bare `cp -r` whole-template install. Fix:
    redirect to `init-project.sh`/QUICKSTART.
  - **B.2** (`skills/boundary-investigation/SKILL.md:67-76`, esp. :76, JC-4):
    SSOT table uses pack-repo-relative `project-template/...` prefixes that
    resolve to nothing at client. JC-4: malformed-path correctness fix (NOT a
    K4 leak). Fix: rewrite the table paths to
    client-resolvable forms (`docs/pack/...`,
    `.claude/skills/<name>/SKILL.md`, etc.) per the client install layout.
  - **B.3** (`docs/pack/PM-CHAT.md:930`): documents `.v9-customized` sidecar;
    the migrator emits `v10-customized`
    (`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`,
    migrate-v10-to-v11.sh:76). Fix: `.v9-customized` → `.v10-customized`.
  - **B.4** (`docs/pack/OPTIONAL-FEATURES.md:132-135, 164`): uses
    `bash scripts/pack-tracker.sh <verb>` (doesn't resolve at client; the
    surface convention elsewhere is the `pack tracker <verb>` shell-verb). Fix:
    switch to `pack tracker <verb>`.
  - **NEW leak** (`.mcp.json.example:9`): cites `supporting-docs/CLI-PM-SETUP.md`,
    a dead client path (CLI-PM-SETUP.md is NOT client-installed — only
    METHODOLOGY.md + INSTALL-PROCEDURES.md are; EEB-G). Fix: drop the
    `supporting-docs/CLI-PM-SETUP.md` cite or re-point to a client-resolvable
    setup note.

  Project-side SSOT honored (`P-missed-7`): K4.4 keeps the fenced
  `pack-ops/MERGE-STRATEGY.md` fallback (no project-side SSOT exists); B.2
  rewrites SSOT-table paths to client-resolvable forms; K2.1/K4.3 →
  `docs/pack/METHODOLOGY.md` (the client-installed location, EEB-G).
- **(d) Keyword:** `project-only`. Valid: every C3a path is under
  `project-template/` (EEB-D). `project-only` denies pack-only paths
  (everything outside `project-template/` + `supporting-docs/`); all C3a
  files satisfy this.
- **(e) Manifest:** RUN build. Expected NON-EMPTY (project-template/ content
  feeds fixture installs). Stage `test-fixtures/manifest.txt` in this commit.
- **(f) Verify:** `python3 scripts/validate-pack.py` (with C2's broadened
  guard present — these were its STRIP targets; must PASS now). Cross-CLI
  reference normalization verified for the pm-startup triad + Gemini command
  (`cross-cli-reference-normalization`, ARCHITECTURE-BD-182 §4.1 canonical
  table — substitute audience-correct values, NOT byte-identical copies).
- **(g) Executor + gate:** fresh `pack-coder`. Trinity-of-copies parity:
  K2.1 + K5.4 apply IDENTICALLY across the three pm-startup SKILL.md copies;
  the Gemini command (K4.3/K5.3) gets the audience-correct normalized form.
  Bounded review/fix.

**C3b — xcode-companion-templates/ (no keyword)**

- **(a) Files:** `xcode-companion-templates/README.md`,
  `xcode-companion-templates/Codex/config.toml`.
- **(b) Findings:** K5.8, B.11 (2).
- **(c) Recipe — per-finding fix recipes (inline, verbatim):**
  - **K5.8** (`xcode-companion-templates/README.md:24`): "mirror the v9
    project-level policy" is a LIVE parity claim (not history). Fix: "v11" (or
    version-neutral "the current project-level policy").
  - **B.11** (`xcode-companion-templates/Codex/config.toml:52,56,60,64,69,73,77`):
    declares 7 sub-agents `config_file = "agents/<name>.toml"`; no `agents/`
    dir exists (confirmed no `agents/` dir, EEB-C; `Codex/` has only AGENTS.md
    + config.toml; README install copies only those two). Fix: remove the 7
    `[agents.*]` blocks' `config_file` lines (or the blocks) so the installed
    config references no undelivered file. (Cross-check whether Codex requires
    inline agent defs vs. external files; mechanical removal of dangling
    `config_file` is the floor.)
- **(d) Keyword:** **none (no keyword).** `xcode-companion-templates/` is
  neither a pack-only nor a project-only path under Check 36's prefix model
  (EEB-E) — it is outside `_PROJECT_SIDE_PATH_PREFIXES`, so `project-only`
  would FAIL Check 36 (it touches a non-project-side path), and `pack-only`
  is semantically wrong (this is shipped companion content). No keyword →
  Check 36 skipped (no claim to verify).
- **(e) Manifest:** RUN build. Expected EMPTY (`xcode-companion-templates/` is
  NOT one of the four named v11 surfaces, and is not staged into fixtures).
  The `regenerate-manifest-v11-surface` rule is triggered ONLY by
  project-template/ | scripts/ | pack-ops/ | supporting-docs/ — C3b touches
  none of these, so the regen rule does not fire at all for C3b. (Run-check
  optional; no stage.)
- **(f) Verify:** `python3 scripts/validate-pack.py` (full PASS).
- **(g) Executor + gate:** fresh `pack-coder`. Bounded review/fix.

### C4 — supporting-docs currency (incl. K5.11 per NUD-6)

- **(a) Files:** `supporting-docs/SETUP-EXISTING.md`,
  `supporting-docs/SETUP-NEW.md`, `supporting-docs/DEPENDENCIES.md`,
  `supporting-docs/SETUP_TEMPLATE.md`,
  `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`,
  `supporting-docs/METHODOLOGY.md`.
- **(b) Findings:** K5.9, K5.10, K5.11, K5.12, K5.13, K5.14, K3.6 (7).
- **(c) Recipe — per-finding fix recipes (inline, verbatim):**
  - **K5.9** (`SETUP-EXISTING.md:3`): doc-identity header "v10.0". Fix: v11.0.
    (NOT the accurate `git checkout v10.0` / backup-path refs — only the
    identity header.)
  - **K5.10** (`SETUP-NEW.md:3-4`): doc-identity header "v10.0". Fix: v11.0.
  - **K5.11** (`METHODOLOGY.md:3-4, 1732`, NUD-6 Option A): version/identity
    block says "Version 2.1 (v10.0, April 2026)". Fix: bump the pack-version
    token to v11.0 + move the date to the v11.0 release — values pulled from
    the README version-table SSOT at fix time; KEEP internal doc-version 2.1
    (no content-revision bump).
  - **K5.12** (`DEPENDENCIES.md:3`): "Pack v10". Fix: v11.
  - **K5.13** (`SETUP_TEMPLATE.md:18, 35`): template self-labels + prescribes
    generated output as "v10". Fix: v11 (deliverable-cleanliness corollary —
    the generated SETUP.md must be clean).
  - **K5.14** (`AGENT_KICKOFF_TEMPLATE.md:21`): generated-output provenance
    "Pack v10". Fix: v11.
  - **K3.6** (`SETUP-EXISTING.md:12, 18`): twice routes the reader to
    `MIGRATION-v9-to-v10.md` (ABSENT at HEAD; sunset in v11 per BD-121) with NO
    historical framing, AND is stale (v9.3→v10 routing on a v11 pack). Fix:
    re-point the two dangling cites (lines 12, 18 — EEB-B) to
    `MIGRATION-v10-to-v11.md` + the `git checkout v10 -- ...` recovery framing
    used correctly by INSTALL-PROCEDURES.md; de-version the stale v9.3→v10
    routing to the v11 baseline.
- **(d) Keyword:** `project-only`. Valid: `supporting-docs/` IS project-side
  per Check 36 (EEB-E: `_PROJECT_SIDE_PATH_PREFIXES` includes
  `supporting-docs/`). `project-only` denies everything outside the two
  project-side prefixes; all C4 paths are under `supporting-docs/`.
- **(e) Manifest:** RUN build. Expected EMPTY (`supporting-docs/` is copied
  individually at install but its content does not change the fixture git
  SHAs the manifest pins — only `METHODOLOGY.md` ships, to `docs/pack/`;
  whether its edit moves a fixture SHA is determined by the run). RUN, stage
  IFF non-empty.
- **(f) Verify:** `python3 scripts/validate-pack.py` (C2 broadened guard
  present; must PASS). Confirm K3.6 routes to the resolving
  `MIGRATION-v10-to-v11.md` (EXISTS — EEB-B).
- **(g) Executor + gate:** fresh `pack-coder`. **NUD-6 ruled → NO C4b split;
  K5.11 (METHODOLOGY.md) lands inside C4.** Bounded review/fix.

### C5 — Pack-internal dangling-doc fixes (+ QUICKSTART, coverage-gap resolution)

- **(a) Files:** `scripts/lib/tracker-migrate-forward.sh`,
  `scripts/lib/tracker-phase-task.sh`, `scripts/lib/tracker-cycle-check.sh`,
  `scripts/lib/tracker-links.sh`, `scripts/validate-pack.py`,
  `maintenance-docs/TOOL-COMPARISON.md`, **`QUICKSTART.md`**.
- **(b) Findings:** K3.1, K3.2, K3.11, B.12, B.13, B.14, **K3.7** (7).
- **(c) Recipe — per-finding fix recipes (inline, verbatim):**
  - **K3.1** (`tracker-migrate-forward.sh:238`): cites
    `ARCHITECTURE-V3.2-DELTA.md` (ABSENT at HEAD). The co-cited
    `ARCHITECTURE-V3.3-DELTA.md` EXISTS and carries the content forward (both
    confirmed ABSENT/EXISTS at EEB-B). Fix: drop the dangling V3.2-DELTA
    basename; keep the V3.3-DELTA cite.
  - **K3.2** (`tracker-phase-task.sh:78-79`): same dangling
    `ARCHITECTURE-V3.2-DELTA.md` basename in the Reference comment; V3.3-DELTA
    resolves. Fix: drop the V3.2-DELTA basename + its `§4.1, §4.2, §4.3`
    clause.
  - **K3.11** (`maintenance-docs/TOOL-COMPARISON.md:5-6, 217-218, 220-221`): a
    self-declared "living/authoritative reference" asserts
    `GEMINI-CLI-ANALYSIS.md`/`ANDROID-ANALYSIS.md` "remain in the repo" (both
    ABSENT) via a LIVE present-tense directive (JC-5's history carve-out does
    NOT cover live directives). Fix: remove the L217-221 "Deprecated analysis
    documents" block + the L5-6 supersession banner (the content was absorbed
    here; the source files are gone). Secondary L6 `V9-DESIGN.md` now at
    `maintenance-docs/archive/` (EXISTS at EEB-B) — re-point.
  - **B.12** (`tracker-cycle-check.sh:93`): cites `ARCHITECTURE-V1.md` (ABSENT;
    not in BD-195 deleted set — pre-existing). V2/V3 exist. Fix: re-point to
    the resolving doc (`ARCHITECTURE-V3.3-DELTA.md` or the current
    ARCHITECTURE-V*.md that carries §9/§27.1) or drop the dangling basename.
  - **B.13** (`tracker-links.sh:96-97`): two `ARCHITECTURE-V1.md` cites
    (ABSENT). Fix: same as B.12 — re-point or drop. (`ARCHITECTURE-V2.md`/
    `V3.md`/`V3.3-DELTA.md` exist, EEB-B; coder picks the resolving target
    carrying the cited §s or drops the dangling basename.)
  - **B.14** (`scripts/validate-pack.py:4241`): cites
    `IMPL-REPORT-BD-173-Batch-19c-H.13.md`; actual file is
    `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` (full prefix; confirmed).
    Sibling line 4220 uses the correct full prefix. Fix: correct the
    abbreviated basename.
  - **K3.7** (`QUICKSTART.md:34`): live hyperlink to
    `supporting-docs/MIGRATION-v9-to-v10.md` (ABSENT; EEB-B confirms ABSENT).
    README:156 already states the v9→v10 guide was sunset. Fix: replace the
    dead hyperlink with the README sunset note + `git checkout v10` recovery
    recipe (NO live link to a deleted file).
- **(d) Keyword:** **none (no keyword)** — mixed scope. C5 touches `scripts/`
  (pack-only territory), `maintenance-docs/` (neither prefix), AND
  `QUICKSTART.md` (pack-root, neither prefix). A `pack-only` keyword is VALID
  by the literal rule (none of these paths are under `project-template/` or
  `supporting-docs/`, EEB-E) — but to keep the commit a single auditable unit
  spanning a doc surface (`maintenance-docs/` + pack-root QUICKSTART) the
  plan uses **no keyword** (Check 36 skipped). *Optional split* (coder/Pack-
  Chat choice, not required): C5-scripts (`scripts/` paths) as `pack-only` +
  C5-docs (`maintenance-docs/TOOL-COMPARISON.md` + `QUICKSTART.md`) as no
  keyword. The default is the single no-keyword commit.
- **(e) Manifest:** RUN build (C5 touches `scripts/`). Expected EMPTY (tracker
  libs + `validate-pack.py` not staged; `maintenance-docs/` + `QUICKSTART.md`
  not staged — EEB-F). Stage IFF non-empty.
- **(f) Verify:** `python3 scripts/validate-pack.py` (full PASS); confirm the
  re-pointed cites resolve (EEB-B target list). If B.12/B.13 re-point to a
  doc, that doc must EXIST (EEB-B).
- **(g) Executor + gate:** fresh `pack-coder`. **`pack-repo-code-comment-
  deferrals`:** if any fix would leave a deferred item, use the typed
  `# TODO(scope): TD-TBD — title` format (these are bash/Python comments) —
  but all C5 items are CLEAR-FIX with no deferral. Bounded review/fix.

### C6 — JC-5 soft-advisory removed-doc guard (guard only; NO content edit)

- **(a) Files:** `scripts/validate-pack.py`, NEW
  `scripts/tests/test-validate-pack-<advisory>.sh` (name per
  `filename-uniqueness-heuristic`; wire into the CI runner so Check 42 stays
  green).
- **(b) Findings:** K3.12, K3.13 — covered by the guard; **NO hand-correction
  of the cited lines** (JC-5: accurate v8/v9 + process history).
- **(c) Recipe — §2.3 JC-5 guard design (measure-then-bound), full and inline:**

  **§2.3 — JC-5: soft-advisory removed-doc guard (cited-path-resolves-to-a-
  removed-doc).**

  **Step 1 — Measure.** The K3.12 CHANGELOG lines (451, 481-482, 562, 564) and
  K3.13 BACKLOG lines (3061, 3690, 4169, 4284, 4300/4302/4304) cite removed
  docs within accurate historical narrative (verified ABSENT:
  GEMINI-CLI-ANALYSIS.md, ANDROID-ANALYSIS.md, V10-PREDESIGN.md,
  ARCHITECTURE-BD-185.md, PLAN-BD-185.md).

  **Step 2 — Categorize.** ALL KEEP-as-history (JC-5: leave accurate v8/v9 +
  process narrative; do NOT hand-correct). There are NO STRIP items — JC-5's
  sole output is a NON-blocking advisory.

  **Step 3 — Fix-recipe.** None (no content edit per JC-5).

  **Step 4 — Size.** The guard is informational/SOFT — it WARNs (never
  hard-fails) when a backtick-cited basename resolves to a removed doc. Its
  "allowlist" is implicit: every hit is a warning, none is a gate failure, so
  accurate-history citations never break CI. It must NOT be wired as a
  `fail()`.

  **Step 5 — Verify.** Run `python3 scripts/validate-pack.py`; confirm the new
  soft-advisory emits WARN lines for the K3.12/K3.13 citations and the overall
  exit code stays 0 (PASS). A test asserts the advisory is non-fatal (exit 0
  with WARNs present).
- **(d) Keyword:** `pack-only`. Valid: only `scripts/` paths (EEB-E).
- **(e) Manifest:** RUN build. Expected EMPTY (`validate-pack.py` + test not
  staged — EEB-F). Stage IFF non-empty.
- **(f) Verify:** `python3 scripts/validate-pack.py` emits WARN lines for the
  K3.12 (CHANGELOG 451/481-482/562/564) and K3.13 (BACKLOG) citations AND
  exits 0 (PASS); the new test asserts the advisory is non-fatal (exit 0 with
  WARNs present). The advisory MUST NOT be wired as a gate failure.
- **(g) Executor + gate:** fresh `pack-coder`. `enumerate-encoding-surfaces`:
  the guard + its test land together. Bounded review/fix.

### C7 — PM-only BACKLOG BD-195-entry de-citation

- **(a) Files:** `pack-ops/BACKLOG.md`.
- **(b) Findings:** K3.3, K3.4, K3.5 (3).
- **(c) Recipe — per-finding fix recipes (inline, verbatim) + NUD-3 Option A:**
  the open BD-195 entry cites three+ DELETED-set docs as authoritative inputs
  to the work IN PROGRESS:
  - **K3.3** (`pack-ops/BACKLOG.md:3135`): the LIVE BD-195 entry (Status: Open)
    cites three DELETED-set docs (`AUDIT-BD-195-REFRESH-POST-BD196.md`,
    `ARCHITECTURE-BD-195-SEGMENTATION.md`, `ARCHITECTURE-BD-195-RESCOPE.md`) as
    authoritative inputs.
  - **K3.4** (`pack-ops/BACKLOG.md:3137`): the same entry's "Segments"
    subsection attributes its S0–S4 structure to the deleted
    `ARCHITECTURE-BD-195-SEGMENTATION.md`.
  - **K3.5** (`pack-ops/BACKLOG.md:3168`): the same entry's Step 9 cites
    deleted `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`.

  **NUD-3 Option A** — RE-CITE the live trusted basis
  (`PLAN-BD-195-REMEDIATION.md` + `BD-195-CLEAN-FOUNDATION.md` +
  `AUDIT-BD-195-VERIFIED-FINDINGS.md`), replacing the deleted-doc segmentation
  narrative at `pack-ops/BACKLOG.md:3135/3137/3168`. Exact wording is a PM
  editorial call at execution time.
- **(d) Keyword:** `PM-only`. Valid: `pack-ops/BACKLOG.md` is PM-only per
  `PACK-AGENTS.md` § "PM-only files and directories" (BACKLOG is the canonical
  PM-only example). `PM-only` permits this edit by construction.
- **(e) Manifest:** `pack-ops/` IS a named v11 surface, so the regen rule
  fires — RUN `bash test-fixtures/build.sh --all --clean`. Expected diff
  **EMPTY** (the manifest pins per-fixture init-project.sh output SHAs;
  `pack-ops/BACKLOG.md` does not feed fixtures — EEB-F). Stage `manifest.txt`
  ONLY if the diff is non-empty (it should not be).
- **(f) Verify:** `python3 scripts/validate-pack.py` (full PASS — no validator
  asserts the BD-195 entry's narrative content; the de-citation must not
  break any BACKLOG-structure check such as Check 32/33/34 per-entry
  validators if `/backlog/` existed — it does NOT at HEAD (the pack-self
  `/backlog/` `/changelog/` per-entry trees do not exist at HEAD `c440bdf`:
  `ls backlog/` → `No such file or directory`; they are created at Batch 23 /
  BD-102 dog-food — so the monolithic mirror `pack-ops/BACKLOG.md` is the
  current edit target).
- **(g) Executor + gate:** **Pack-Chat-direct PM-only edit** (NOT a coder —
  per CLAUDE.md "What Pack Chat CAN edit directly": PM-only files). No bounded
  review/fix cycle (PM-only direct edits are not coder work); user approves
  the commit.

### C8 — PM-only README layout/version-table currency

- **(a) Files:** `README.md`.
- **(b) Findings:** K3.8, K3.9, K3.10, K5.15, B.15, B.16, B.17 (7).
- **(c) Recipe — per-finding fix recipes (inline, verbatim) + the three rulings.**
  Finding loci: K3.8 (`README.md:163`, lists `maintenance-docs/GEMINI-CLI-ANALYSIS.md`
  — ABSENT), K3.9 (`README.md:164`, lists `maintenance-docs/ANDROID-ANALYSIS.md`
  — ABSENT), K3.10 (`README.md:170`, names archive `V10-PREDESIGN.md` — ABSENT;
  sibling `V10-DESIGN-PROCESS-PLAN.md` EXISTS), B.15 (`README.md:152`, sites
  `MERGE-STRATEGY.md` under `supporting-docs/`; actual `pack-ops/`), B.16
  (`README.md:154`, sites `DRY-RUN-MIGRATION.md` under `supporting-docs/`;
  actual `pack-ops/`), K5.15 (`README.md:60, 195`, check-count staleness), B.17
  (`README.md:101`, "34 skills" vs 36 in tree). The rulings:
  - **NUD-4 Option A** (K3.8/K3.9/K3.10, B.15, B.16): STRIP the removed-doc
    rows `GEMINI-CLI-ANALYSIS.md` (README:163), `ANDROID-ANALYSIS.md`
    (README:164), and the `V10-PREDESIGN.md` token (README:170 — keep the
    sibling `V10-DESIGN-PROCESS-PLAN.md`, EXISTS at EEB-B); CORRECT the two
    mis-sited rows `MERGE-STRATEGY.md` (README:152) and `DRY-RUN-MIGRATION.md`
    (README:154) from the `supporting-docs/` heading to `pack-ops/` (actual
    location — both EXIST at `pack-ops/`, EEB-B). NO annotations.
    > Layout-edit caution (RISK R-1, §5.2): README:152/154 sit UNDER the
    > `supporting-docs/` tree-heading (README:143) and README:163/164 under
    > the `maintenance-docs/` heading (EEB-B). Removing 163/164 and moving
    > 152/154 must keep the ASCII tree well-formed (the `├──`/`└──`/`│`
    > connectors) and must relocate 152/154 to under the `pack-ops/` heading
    > if one exists, or note them at the correct site — the coder/PM verifies
    > the tree still parses and any layout-asserting validator stays green.
  - **NUD-7 Option A** (K5.15): recompute the check counts ONLY against the
    real Check NN set in `validate-pack.py` — HEAD defines Check 1–46 with
    12–15 and 24 retired (EEB-A confirms `Check 1..46` present). Update
    README:60 (version-table cell) and README:195 (layout annotation). NO
    version-cell narrative beyond the count correction. (The coder recomputes
    "numbered" and "invoked" totals from the actual check set, not from a
    hand-list.)
  - **NUD-9 Option B** (B.17): reconcile the skill count against
    `project-template/docs/pack/PLATFORM-SKILLS.md` (the count SSOT) and set
    README:101 to MATCH it, WITHIN this commit. Tree has 36 dirs (EEB-A); the
    README says 34. The coder reads PLATFORM-SKILLS.md's authoritative count +
    breakdown and sets README:101 to that value (not a blind 34→36 bump — the
    SSOT governs the number AND the 13+19+1+1-style breakdown).
- **(d) Keyword:** `PM-only`. Valid: `README.md` version table + layout are
  PM-only per CLAUDE.md ("README.md version table (PM chat only)") and
  PACK-AGENTS.md PM-only list. `PM-only` permits this edit.
- **(e) Manifest:** `README.md` is at pack-root — NOT under any of the four
  named v11 surfaces (`project-template/` | `scripts/` | `pack-ops/` |
  `supporting-docs/`), so the `regenerate-manifest-v11-surface` rule does NOT
  fire for a README-only commit. No build run required; no manifest stage.
- **(f) Verify:** `python3 scripts/validate-pack.py` (full PASS — including
  any check that asserts README layout/structure or check-count strings; the
  recomputed counts must satisfy any self-consistency check, e.g. a check
  that cross-references README's stated check ceiling against
  `validate-pack.py`'s actual Check NN set, if present).
- **(g) Executor + gate:** **Pack-Chat-direct PM-only edit.** B.17 requires
  reading PLATFORM-SKILLS.md first (count SSOT). User approves the commit.

### C9 — NUD-2 / NUD-5 / NUD-8 cleanup

- **(a) Files:** `project-template/scripts/bootstrap.sh`,
  `project-template/docs/pack/PACK-FEEDBACK.md`,
  `project-template/docs/project/backlog/_intro.md`,
  `project-template/docs/project/backlog/_rules.md`,
  `project-template/docs/project/changelog/_intro.md`,
  `project-template/docs/project/changelog/_rules.md`,
  `project-template/docs/project/implementation-plan/_intro.md`,
  `project-template/docs/project/implementation-plan/_rules.md`.
- **(b) Findings:** K2.2, K5.7, B.5, B.6, B.7, B.8, B.9, B.10 (8).
- **(c) Recipe — per-finding fix recipes (inline, verbatim) + rulings:**
  - **NUD-2 Option A** (K2.2, `bootstrap.sh:46-49` primary + `:51`): a
    client-gated comment names multiple pack-internal artifacts (`in the pack
    repo`, `supporting-docs/SETUP-NEW.md`, `init-project.sh`, `migration
    guide`); the client never re-runs init-project.sh from this file. STRIP the
    pack-only skills-distribution explainer comment at `bootstrap.sh:46-49`
    (+ the :51 migration-guide line) entirely; do NOT invent a replacement
    destination.
  - **NUD-5 Option A** (K5.7, `PACK-FEEDBACK.md:40,163,297,313,331,337,352,358,359,372,378,389,395,414,420,436,439`):
    pervasive `v9` seed content in a FRESH v11 template — some lines are
    version LABELS, some are illustrative PROSE. Swap ONLY the version-LABEL
    fields among the 17 lines (e.g. L40 `Pack version in use | v9.[N]`) to the
    current version; LEAVE illustrative prose (L359 "After the v9 split,
    auditor-ui covers only …", L297 seed-question narrative, etc.) intact. The
    coder distinguishes LABEL (a current-version claim) vs PROSE (example
    narrative, not a version label) per this framing.
  - **NUD-8 Option B** (B.5–B.10): DROP the concrete `scripts/lib/per-entry/`
    path from all 6 files; describe the mechanism abstractly (e.g. "the
    pack's per-entry mirror generator"); apply ONE consistent phrasing across
    all 6. (`P-missed-7` / `boundary-investigation`: the project-side SSOT for
    these per-entry surfaces is the `docs/project/<stream>/_rules.md` contract
    itself; the abstract phrasing must not import a pack-only mechanism name.)
- **(d) Keyword:** `project-only`. Valid: every C9 path is under
  `project-template/` (EEB-D). `project-only` denies pack-only paths; all C9
  files satisfy this.
- **(e) Manifest:** RUN `bash test-fixtures/build.sh --all --clean`. Expected
  NON-EMPTY (project-template/ content — `bootstrap.sh`, the per-entry
  `_intro`/`_rules`, and PACK-FEEDBACK.md all ship into fixture installs).
  Stage `test-fixtures/manifest.txt` in this commit.
- **(f) Verify:** `python3 scripts/validate-pack.py` (C2 broadened guard
  present; K2.2 bootstrap is a `.sh` walked by the guard — must PASS clean).
- **(g) Executor + gate:** fresh `pack-coder`. NUD-8 phrasing applied
  uniformly across all 6 per-entry files (one phrasing). Bounded review/fix.

---

## 5 — Coverage-gap resolution + open risks

### 5.1 — Coverage-gap RESOLVED: K3.7 (QUICKSTART.md) had no commit in the upstream draft

K3.7 (`QUICKSTART.md:34` dead `supporting-docs/MIGRATION-v9-to-v10.md`
hyperlink) is a CLEAR-FIX: replace the dead hyperlink with the README sunset
note + `git checkout v10` recovery recipe (no live link to a deleted file).
In the upstream commit draft the commit table (C1–C9) never named K3.7 — it
fell through every row. Left unassigned, K3.7 would be a dropped finding (a
plan defect per success criterion 1).

**Resolution (no new scope; the fix is the K3.7 recipe in C5 (c)):** assign
K3.7 to **C5**. Rationale: K3.7 is a pack-root dangling-doc reference,
the same defect-class as C5's pack-internal dangling-doc cluster (K3.1, K3.2,
K3.11, B.12–B.14). `QUICKSTART.md` is pack-root (EEB-B) — it cannot go in C3
(`project-only` denies pack-root) or C4 (`supporting-docs/` only). C5 is
already no-keyword/mixed (it spans `scripts/` + `maintenance-docs/`), so adding
a pack-root doc keeps the keyword decision unchanged. This is a placement
resolution, not a recipe change.

### 5.2 — Open risks

| ID | Risk | Mitigation |
|---|---|---|
| R-1 | **Stale README layout tree (C8).** Stripping README:163/164 rows and relocating 152/154 can break the ASCII tree connectors or leave a row under the wrong heading. | C8 verify-step runs `validate-pack.py`; PM/coder confirms the tree parses and 152/154 land under the correct `pack-ops/` site (EEB-B). NUD-4 is "no annotations," so the edit is pure strip/relocate. |
| R-2 | **Red-CI window (C2 alone).** Pushing C2 standalone fails `validate-pack.py` (broadened guard fires on unfixed STRIP set). | §3.2: C2 is push-grouped with C3a/C3b/C4/C9 (PG-2); the full-repo green state is asserted only at the END of PG-2. The per-check test passes standalone. |
| R-3 | **Trinity-of-copies drift (C3a).** K2.1/K5.4 must apply identically across the 3 pm-startup SKILL.md copies; the Gemini variant (K4.3/K5.3) needs the normalized form, not a byte copy. | `cross-cli-reference-normalization` (ARCHITECTURE-BD-182 §4.1) + trinity parity in the C3a gate. |
| R-4 | **Manifest false-confidence.** The plan predicts EMPTY manifest diffs for scripts/pack-ops/README commits; if a fixture pin unexpectedly moves, a skipped run would miss it. | Binding rule: RUN the build on every commit touching the 4 surfaces and stage IFF non-empty — never skip the run on the prediction. C8 (README-only) correctly does NOT trigger the rule (pack-root). |
| R-5 | **B.12/B.13 re-point target.** Re-pointing `ARCHITECTURE-V1.md` requires a doc that actually carries the cited §s. | Coder picks a resolving target from the EXISTS set (EEB-B: V2/V3/V3.3-DELTA) OR drops the dangling basename (§1 B.12/B.13 permit either). Verify the chosen target exists. |
| R-6 | **New CI test files (C1 guard test, C6 advisory test).** A new `scripts/tests/test-*.sh` must be wired into the CI runner or Check 42 (CI-wires-all-per-check-tests) fails. | C1/C6 gates include wiring the new test into the runner; `enumerate-encoding-surfaces` covers this. Prefer extending existing test files where possible (C1 §2.1 Step-3 error-guard recipe adds cases to `test-tracker-phase-task.sh`). |
| R-7 | **NUD-9 SSOT read (C8/B.17).** A blind 34→36 bump risks re-drift if PLATFORM-SKILLS.md says otherwise. | NUD-9 Option B mandates reconciling against PLATFORM-SKILLS.md and matching it — read the SSOT first; the tree-count (36, EEB-A) is corroboration, not the authority. |

### 5.3 — No deferrals

All 63 actionable findings + the new `.mcp.json.example` leak land in v11.0
commits in this plan (`deferral-is-scope-creep` /
`no-deferral-without-user-direction`). The 4 NUD-1 findings are NOT deferred —
they are reclassified NOT-A-DEFECT by user ruling (non-actionable, not
postponed). No finding is pushed to v11.1+.

---

## 6 — Empirical-Evidence Blocks

All measurements taken at HEAD `c440bdf742a52f6fc0d66b75f6f07a88771f374e`,
branch `v11-dev`, 2026-06-01.

**EEB-A — Check NN set, skill count, sidecar suffix.**
- Commands: `grep -oE 'Check [0-9]+' scripts/validate-pack.py | sort -u`;
  `ls -d project-template/skills/*/ | wc -l`;
  `grep -n 'OWN_SIDECAR_SUFFIX' scripts/migrate-v10-to-v11.sh`.
- Output (verbatim, key): Check set = `Check 1 … Check 46` (contiguous 1–46
  present in the source); skill dirs = `36`;
  `76:MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`.
- Interpretation: README's "top 43 / 34 skills" is stale (Check 44–46 exist;
  36 skill dirs); PM-CHAT.md's `.v9-customized` is wrong (migrator emits
  `v10-customized`). Drives K5.15 (C8), B.17 (C8), B.3 (C3a).
- Conclusion: SUPPORTED.

**EEB-B — Dangling/relocation target existence.**
- Command: `for f in <list>; do [ -e "$f" ] && echo EXISTS || echo ABSENT; done`
  + `find . -name "ARCHITECTURE-V*.md"` + `ls QUICKSTART.md` +
  `sed -n '12p;18p' supporting-docs/SETUP-EXISTING.md` + `sed -n '34p' QUICKSTART.md`.
- Output (verbatim, key):
  `ABSENT maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md`;
  `EXISTS .../ARCHITECTURE-V3.3-DELTA.md`;
  `ABSENT maintenance-docs/GEMINI-CLI-ANALYSIS.md`;
  `ABSENT maintenance-docs/ANDROID-ANALYSIS.md`;
  `ABSENT maintenance-docs/archive/V10-PREDESIGN.md`;
  `EXISTS maintenance-docs/archive/V10-DESIGN-PROCESS-PLAN.md`;
  `EXISTS maintenance-docs/archive/V10-DESIGN.md`;
  `ABSENT supporting-docs/MIGRATION-v9-to-v10.md`;
  `EXISTS supporting-docs/MIGRATION-v10-to-v11.md`;
  `ABSENT supporting-docs/MERGE-STRATEGY.md` / `EXISTS pack-ops/MERGE-STRATEGY.md`;
  `ABSENT supporting-docs/DRY-RUN-MIGRATION.md` / `EXISTS pack-ops/DRY-RUN-MIGRATION.md`;
  `ABSENT maintenance-docs/v11-research/ARCHITECTURE-V1.md` /
  `EXISTS .../ARCHITECTURE-V2.md` + `.../ARCHITECTURE-V3.md` + `.../ARCHITECTURE-V3.3-DELTA.md`;
  `EXISTS maintenance-docs/archive/V9-DESIGN.md`;
  `QUICKSTART.md` (pack-root, EXISTS);
  `SETUP-EXISTING.md:12` and `:18` both cite `MIGRATION-v9-to-v10.md`;
  `QUICKSTART.md:34` = the dead `supporting-docs/MIGRATION-v9-to-v10.md` hyperlink.
- Interpretation: confirms dangling targets for K3.1/K3.2/K3.6/K3.7/K3.8–
  K3.10/K3.11, K4.1, B.12/B.13/B.15/B.16, and the resolving co-cites /
  relocations used by C4/C5/C8. `QUICKSTART.md` is pack-root (drives §5.1).
- Conclusion: SUPPORTED.

**EEB-C — xcode Codex dangling agent files (B.11).**
- Command: `ls xcode-companion-templates/Codex/`.
- Output (verbatim): `AGENTS.md` / `config.toml` (no `agents/` dir).
- Interpretation: the 7 `config_file = "agents/<name>.toml"` declarations
  reference an undelivered dir → B.11 confirmed; C3b removes them.
- Conclusion: SUPPORTED.

**EEB-D — C3a/C9 file homes are under project-template/.**
- Command: `for f in <C3a + C9 list>; do [ -e "$f" ] && echo OK || echo MISSING; done`.
- Output (verbatim): all `OK` for `project-template/README.md`,
  `.codex/config.toml.example`, `.mcp.json.example`, the 3 pm-startup
  SKILL.md copies, `.gemini/commands/pm-startup.toml`, `docs/pack/PM-CHAT.md`,
  `docs/pack/OPTIONAL-FEATURES.md`, `docs/pack/HELP-FRAGMENT.md`,
  `docs/pack/prompts/pm-chat.md`, `skills/boundary-investigation/SKILL.md`;
  and (C9) `scripts/bootstrap.sh`, `docs/pack/PACK-FEEDBACK.md`, the 6
  per-entry `_intro`/`_rules` files — all under `project-template/`.
- Interpretation: `project-only` is valid for C3a and C9 (every path under
  `project-template/`).
- Conclusion: SUPPORTED.

**EEB-E — Check 36 scope-keyword path model.**
- Command: `sed -n '3821,3824p' scripts/validate-pack.py`.
- Output (verbatim):
  `# Pack-only path prefixes for scope honesty (Check 36 pack-only check):`
  `# a `pack-only` commit MUST NOT touch any path under these prefixes.`
  `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`.
- Interpretation: `pack-only` DENIES `project-template/` + `supporting-docs/`;
  `project-only` is the inverse (denies everything outside those two).
  Therefore: C1/C2/C6 `pack-only` valid (scripts/ only); C3a/C9 `project-only`
  valid (project-template/); C4 `project-only` valid (supporting-docs/ IS
  project-side); C3b `xcode-companion-templates/` is NEITHER prefix → no
  keyword (project-only would FAIL Check 36); C5 mixed scripts/+maintenance-
  docs/+pack-root → no keyword.
- Conclusion: SUPPORTED.

**EEB-F — Manifest build inputs (what feeds fixture SHAs).**
- Commands: `head -20 test-fixtures/manifest.txt`;
  `grep -n 'scripts/lib' scripts/init-project.sh`;
  `grep -n 'detect.sh' scripts/init-project.sh`.
- Output (verbatim, key): manifest format = `<fixture-name>  <sha>` (6
  fixtures: v10-minimal, v10-realistic-ot, v11-realistic-ot, v11-flat-file,
  v11-tracker-on, existing-project-mid-dev); init-project.sh stages from
  `scripts/lib/` ONLY `detect.sh`
  (`887:mkdir -p "$TARGET/scripts/lib"` … `893:cp -f "$PACK/scripts/lib/detect.sh"
  "$TARGET/scripts/lib/detect.sh"`); the per-entry helpers run from
  `$PACK/scripts/lib/per-entry` (NOT staged); `validate-pack.py` is not copied
  into fixtures.
- Interpretation: the manifest pins per-fixture init-project.sh OUTPUT SHAs.
  Tracker libs (C1/C5), `validate-pack.py` (C2/C5/C6), `pack-ops/BACKLOG.md`
  (C7), `README.md` (C8), `maintenance-docs/` + `QUICKSTART.md` (C5), and
  `xcode-companion-templates/` (C3b) do NOT feed fixtures → expected EMPTY
  manifest diff. project-template/ content (C3a, C4 METHODOLOGY ship-path, C9)
  CAN move fixture SHAs → expected NON-EMPTY. Binding: RUN the build on every
  4-surface commit; stage IFF non-empty.
- Conclusion: SUPPORTED.

**EEB-G — CLI-PM-SETUP.md NOT client-installed; METHODOLOGY ships to docs/pack/.**
- Commands: `ls supporting-docs/CLI-PM-SETUP.md`;
  `sed -n '9p' project-template/.mcp.json.example`.
- Output (verbatim): `EXISTS supporting-docs/CLI-PM-SETUP.md` (pack-root only);
  `.mcp.json.example:9` = `"_readme": "… See supporting-docs/CLI-PM-SETUP.md
  for setup instructions."`.
- Interpretation: `supporting-docs/CLI-PM-SETUP.md` exists at pack root but is
  NOT in the client-installed set (only METHODOLOGY.md + INSTALL-PROCEDURES.md
  ship — CLI-PM-SETUP.md is absent from `_CLIENT_INSTALLED_FILES` in
  `scripts/init-project.sh`), so the `.mcp.json.example:9` cite is a dead
  client path → the NEW leak folded into C3a. K2.1/K4.3 re-point to
  `docs/pack/METHODOLOGY.md` (the client-installed location).
- Conclusion: SUPPORTED.

**EEB-H — JC-2 allowlist KEEP set (the two proto self-imports).**
- Command: `ls project-template/proto/example/v1/example_service.proto
  project-template/proto/common/v1/common.proto`.
- Output (verbatim): both files EXIST.
- Interpretation: the C2 allowlist (C2 §2.2 Step-4) is sized EXACTLY to these
  two proto self-imports (they resolve within the shipped `proto/` tree) and NO
  other new entry; `project-template/README.md:13/38/44` `supporting-docs/`
  refs are NOT allowlisted — they are resolved by the C3a README rework (see
  C2 §2.2 Step-2 measure table + Step-4). `ci-guard-measure-then-bound`.
- Conclusion: SUPPORTED.

---

## 7 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit [universal] | No `git add/commit/push/tag` issued. Tool use: Read (3 input docs), read-only Bash (`git rev-parse`/`git status`/`grep`/`ls`/`find`/`sed`/`head`/`python3 -c` arithmetic), and one Write via heredoc to the single output doc `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md`. `git status --short` at start = clean. | COMPLIANT |
| empirical-evidence-blocks [planner] | §6 EEB-A..EEB-H each carry command + verbatim output (counts/paths/lines, e.g. `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`, `Check 1 … Check 46`, `36` skill dirs, `OWN_SIDECAR_SUFFIX="v10-customized"`, `893:cp -f "$PACK/scripts/lib/detect.sh"`) + HEAD `c440bdf` + interpretation + SUPPORTED. Every sequencing/keyword/manifest claim points to an EEB. | COMPLIANT |
| deferral-is-scope-creep [universal] | §2 ledger maps all 63 actionable findings + the new leak to a commit; §5.3 records zero deferrals; the 4 NUD-1 findings are reclassified NOT-A-DEFECT (user ruling), not postponed. | COMPLIANT |
| no-deferral-without-user-direction [universal] | §5.3: all actionable work lands in v11.0 commits (C1/C3–C9); nothing pushed to v11.1+; the new `.mcp.json.example` leak lands in C3a (v11.0). | COMPLIANT |
| boundary-investigation-precedes-pack-defaults / P-missed-7 [universal] | Project-side SSOTs named for the project-surface commits: C3a K2.1/K4.3 → client-installed `docs/pack/METHODOLOGY.md` (EEB-G), B.2 → client-resolvable skill/docs paths, K4.4 → existing fenced `pack-ops/MERGE-STRATEGY.md` (no project-side SSOT exists, §1 K4.4); C9 NUD-8 abstract phrasing must not import a pack-only mechanism name (the `docs/project/<stream>/_rules.md` contract is the project SSOT). | COMPLIANT |
| regenerate-manifest-v11-surface [coder, plan sequences it] | Per-commit (e) manifest decisions: C1/C2/C5/C6 RUN build, expected EMPTY (EEB-F), stage IFF non-empty; C3a/C9 RUN build, expected NON-EMPTY, stage; C4 RUN build, stage IFF non-empty; C7 (pack-ops/) RUN build, expected EMPTY (EEB-F), stage IFF non-empty; C8 (README pack-root) + C3b (xcode) do NOT trigger the rule (outside the four surfaces). Run-then-check is binding; never skip on prediction (R-4). | COMPLIANT |
| enumerate-encoding-surfaces [reviewer/coder, plan sequences it] | C1 pairs the grammar edit (bash ERE + Python `DEP_ENTRY` + parity `DEP`) with its docstrings, grammar-asserting tests, fixture bullet, and the NEW error-guard + its tests in ONE commit; C6 lands the soft-advisory guard + its test together; R-6 flags wiring new test files into the CI runner so Check 42 stays green. | COMPLIANT |
| rules-applied-verification-block [universal] | This table. | COMPLIANT |
| preflight-stop-means-stop [universal] | PREFLIGHT line emitted before the Write, after the full ledger self-check (63 actionable + 4 non-actionable = 67; K3.7 gap resolved into C5). No parent stop/halt issued. | COMPLIANT |
