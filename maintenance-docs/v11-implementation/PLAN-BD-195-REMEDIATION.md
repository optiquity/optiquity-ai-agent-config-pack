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
  inline fix recipes (and guard design for C1/C2/C3d/C6), Check-36 keyword +
  validity, manifest-regen decision, verification commands, executor, gate.
  C3c (full pack-self strip), C3d (sanctioned-exception freeze + Check 47), and
  PM-step-DD (PM-only trinity rule) realize the BD-195 dual-use-shipped-lib
  design (`ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` §8) inline.
- **§5** COVERAGE-GAP RESOLUTION (K3.7) + open risks.
- **§6** Empirical-Evidence Blocks.
- **§7** Rules-Applied Verification Block.

**Self-contained convention:** this plan RESTATES every fix recipe and guard
design inline. Each commit spec in §4 carries (c) the verbatim per-finding fix
recipes for the findings it fixes, and — for C1/C2/C3d/C6 — the full guard
design (measure → categorize → fix-recipe → allowlist → verify). C3c restates
the full pack-self strip set inline (the architect §C/§8 strip recipe); C3d
restates the §8.2 six lock-step encoding surfaces inline. The §2 ledger's
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

## 2 — Finding ledger (all 67 + 4 new leaks)

Every confirmed finding maps to exactly one commit OR is non-actionable.
Sum of actionable (63) + non-actionable (4) = **67**. Four NEW leaks (not
among the 67) are also scheduled: the `.mcp.json.example:9` leak (→ C3a),
plus three surfaced by C2's broadened guard during review (reviewer-confirmed
GENUINE) — NL-1 (`INSTALL-PROCEDURES.md:655` dead `V10-DESIGN.md` cite → C4)
and NL-2/NL-3 (`scripts/lib/detect.sh:351`/`:360` `AUDIT-BD-035.md` + `BD-035`
pack-internal citation in client-shipped script comments → new C3c). The 3
new leaks are folded into PG-2 per user direction (2026-06-02). A fourth,
NL-4 (`project-template/README.md` pack-repo-internal layout / skill-distribution
prose → C3a), was surfaced during C3a review and folded into C3a per user
direction (2026-06-02).

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
| NL-1 (new leak) `supporting-docs/INSTALL-PROCEDURES.md:655` | C4 | C2 §2.2 guard surfaced; dead `V10-DESIGN.md` cite → C4 recipe (drop or re-point to a client-resolvable form) |
| NL-2 (new leak) `scripts/lib/detect.sh:351` | **C3c** | C2 guard fires (CONFIRMED at HEAD `bb9e807`, EEB-K); `AUDIT-BD-035.md` doc cite + `BD-035` token on a client-shipped script → C3c **FULL pack-self strip** of `detect.sh` + `pack-help.sh` (all `BD-NNN` + pack-doc cites; KEEP fenced functional `pack-ops/` routing) |
| NL-3 (new leak) `scripts/lib/detect.sh:360` | **C3c** | same as NL-2 — both `detect.sh` `AUDIT-BD-035.md` fires cleared by the C3c full strip (architect §C/§8.0, user-approved 2026-06-02) |
| NL-4 (new leak) `project-template/README.md` | **C3a** | C3a review surfaced; pack-repo-internal two-dir layout / `cp -r` / `init-project.sh`-distribution / skill-distribution prose on a Check-43-walked client surface → C3a recipe (NL-4 rework per the user-directive principle) |

**Per-commit finding counts (actionable):** C1 = 11 · C3 = 18 (+1 new leak,
`.mcp.json.example`) · C3c = 0 of the 67 (+2 new leaks NL-2/NL-3 + the full
same-class strip set in `detect.sh`/`pack-help.sh`, architect §C.3 — not among
the 67) · C3d = 0 of the 67 (guard design: frozen constant + walk-gate +
Check 47 + tests) · C4 = 7 (+1 new leak NL-1) · C5 = 7 · C6 = 2 (guard-covered,
no content edit) · C7 = 3 · C8 = 7 · C9 = 8 = **63 actionable** (of the 67).
Non-actionable = 4 (K1.11–K1.14). **63 + 4 = 67.** Separately, **4 new leaks**
(not among the 67) are scheduled: `.mcp.json.example` (C3a), NL-1 (C4),
NL-2/NL-3 (C3c). C3c ALSO strips the broader same-class pack-self provenance the
guard does not yet catch (architect §C.3, user-approved); C3d adds the
sanctioned-exception freeze + Check 47; PM-step-DD adds the trinity rule
(PM-only). No commit fires on any of the 67 for C3c/C3d (guard/strip work).

---

## 3 — Dependency DAG + safe push order

### 3.1 — The DAG

```
C1 (JC-1 grammar strip + error-guard)        independent — lands FIRST
        (C1b DROPPED per NUD-1)

C2 (JC-2 guard broadening)  ──┬─► C3a/C3b (client-surface STRIP fixes)
                              ├─► C3c (FULL pack-self strip of detect.sh +
                              │        pack-help.sh — NL-2/NL-3 + same-class
                              │        set; pack-only)
                              │         └─► C3d (sanctioned-exception freeze +
                              │              Check 47 guard; pack-only)
                              │               └─► PM-step-DD (trinity rule; PM-only)
                              └─► C4 (supporting-docs currency, incl. NL-1)

C5 (pack-internal dangling-doc + QUICKSTART)  independent
C6 (JC-5 soft-advisory guard)                 independent
C7 (PM-only BACKLOG de-citation)              independent (PM-only)
C8 (PM-only README layout/counts)             independent (PM-only)
C9 (NUD-2/5/8 cleanup)                        depends on C2 (its fixes are
                                              project-surface; C2's broadened
                                              guard verifies them clean)
```

> **State of execution (re-measured at HEAD `bb9e807`, 2026-06-02).** C1
> (`8555953`), C2 (`1d3c55a`), C3a (`551a1f4`), C3b (`bb9e807`) have ALREADY
> LANDED (PG-1 pushed; PG-2's guard + project-template/xcode surface fixes
> committed). The C2 broadened guard is LIVE and currently fires exactly
> **3 RED-by-design** at HEAD: NL-1 (`INSTALL-PROCEDURES.md:655`),
> NL-2 (`detect.sh:351`), NL-3 (`detect.sh:360`) — EEB-K. The REMAINING PG-2
> work is: **C3c** (full strip — clears NL-2/NL-3 + the broader same-class
> set), **C3d** (freeze + Check 47), **PM-step-DD** (trinity rule), **C4**
> (clears NL-1), **C9** (project-surface cleanup). C3d depends on C3c (the
> frozen-constant + walk-gate are designed against the post-strip clean files;
> the re-contamination regression injects a `BD-` into the stripped file).
> PM-step-DD follows C3d (it codifies the rule C3d enforces).

**Hard ordering edges (load-bearing):**
1. **C1 first.** It changes shipped library grammar + tests and is the
   BD-185-restart hard prerequisite. No other commit depends on it, but it is
   the agreed lead.
2. **C2 before C3a/C3b/C3c, C4, C9 (all LANDED for C1/C2/C3a/C3b).** The
   broadened Check 43/37 guard (C2, landed `1d3c55a`) exists so the
   client-surface STRIP fixes (C3/C4/C9 + the new leaks NL-1/NL-2/NL-3 surfaced
   by the broadened guard) are verified clean against the broadened walk.
   Measure-then-bound: C2's KEEP set (the durable proto resolve-within-tree
   rule — §2.2 / EEB-H) is sized against the projected post-C3/C3c/C4/C9 tree.
   **C3d after C3c, PM-step-DD after C3d:** C3d freezes the sanctioned exception
   around the POST-STRIP-clean files and its re-contamination regression injects
   a `BD-` into the stripped `detect.sh` (so C3c must land first); PM-step-DD's
   trinity rule codifies the dependency-direction principle that Check 47
   enforces (so it follows C3d). C3d touches only `scripts/validate-pack.py` +
   its test (NOT the two shipped scripts) — no overlap with C3c's files.
3. C5, C6 are independent of all of the above and of each other.
4. C7, C8 are PM-only and independent (no validator dependency for content;
   C8 must still pass any README-asserting check post-edit).

### 3.2 — Red-CI window (CI-must-pass-on-every-push) — RESOLUTION

Landing C2 (the broadened guard) as a standalone green commit BEFORE the
client-surface STRIP fixes leaves CI RED in the interval: the broadened guard
FIRES on the still-unfixed client-surface STRIP set. At the ORIGINAL planning
HEAD that set was larger; **re-measured at HEAD `bb9e807` (2026-06-02) the live
fire-set is exactly 3** (EEB-K): NL-1 `INSTALL-PROCEDURES.md:655` (dead
`V10-DESIGN.md`), NL-2 `detect.sh:351` + NL-3 `detect.sh:360` (both
`AUDIT-BD-035.md`). C3a (`551a1f4`) + C3b (`bb9e807`) already cleared the
project-template/xcode portion of the original set. The pack rule "CI must pass
on every push" forbids pushing C2 alone — but C1/C2/C3a/C3b are already
committed (not yet a clean push: the 3 fires above remain), so PG-2 is closed
out by landing C3c (clears NL-2/NL-3) + C3d + PM-step-DD + C4 (clears NL-1) + C9
before the PG-2 push.

> **Post-C3c-strip fire-set (verified-by-projection, EEB-K).** C3c strips both
> `detect.sh` `AUDIT-BD-035.md` fires (lines 351/360) → the fire-set drops from
> **3 → 1** (only NL-1 `INSTALL-PROCEDURES.md:655` remains). C3d adds Check 47
> and re-walks the now-clean files (no new fire — the gate is membership-only).
> C4 then clears NL-1 → fire-set **0** (green). So `validate-pack.py` stays RED
> across C3c/C3d and goes green only at C4 — which is why C3c/C3d/C4 are in the
> SAME PG-2 push (no intermediate push is green; the GROUP push is the green
> boundary).

**The fix:** couple the guard with the client-surface fixes at the push
boundary and keep the rest sequential.

- **Collapse C2 + C3a/C3b/C3c/C3d + C4 + C9 (+ PM-step-DD) into one ATOMIC
  push boundary.** Concretely: C2, C3a, C3b, C3c, C3d, and C4 are authored as
  separate *commits* (each a self-contained review/fix unit; PM-step-DD is a
  PM-only direct commit) but are **pushed together in one push** so no
  intermediate push leaves the broadened guard firing on an unfixed STRIP
  target. C3c (full `detect.sh` + `pack-help.sh` strip — clears NL-2/NL-3) and
  the C4 NL-1 fix (`INSTALL-PROCEDURES.md:655`) are the remaining live fires
  (EEB-K) the guard surfaces, so they belong in this push group. C3d (freeze +
  Check 47) must land AFTER C3c (its re-contamination regression injects a
  `BD-` into the stripped `detect.sh`); PM-step-DD follows C3d. C9's
  project-surface fixes are likewise included (caught by the C2 guard — K2.2
  bootstrap is on a `.sh` already walked, B.5–B.10 + PACK-FEEDBACK are walked
  client surfaces).

  > Rationale for separate commits inside one push: each commit keeps its own
  > bounded review/fix cycle + IMPL-REPORT (auditability), while the push
  > boundary preserves green CI. This honors both `bounded-review-fix-cycle`
  > and the CI-green rule.

**Push groups (the safe order):**

| Push group | Commits | Why grouped |
|---|---|---|
| PG-1 | C1 | independent; green on its own (tracker libs not walked by Check 43 for the broadened ext-set until C2) |
| PG-2 | C2 → C3a → C3b → **C3c → C3d → PM-step-DD** → C4 → C9 | guard + every client-surface STRIP it fires on land in ONE push; the green boundary is the GROUP push after C4 clears the last fire (NL-1). C1/C2/C3a/C3b already committed (EEB-K: 3 live fires remain); C3c clears NL-2/NL-3 (3→1), C3d freezes the sanctioned exception + adds Check 47, PM-step-DD codifies the trinity rule (PM-only), C4 clears NL-1 (1→0). Pinned order: C3c BEFORE C3d (regression injects into the stripped file) BEFORE PM-step-DD; C4/C9 any order after |
| PG-3 | C5 | independent; green on its own |
| PG-4 | C6 | independent; soft-advisory is non-fatal (exit 0) by design |
| PG-5 | C7 | PM-only; independent |
| PG-6 | C8 | PM-only; independent |

> Push grouping is a Pack-Chat / user decision at execution time
> (`agents-never-commit`); this plan supplies the SAFE order, not a push
> instruction. Within PG-2: C2 first (already landed), then the surface fixes.
> The remaining PINNED sub-order is **C3c → C3d → PM-step-DD** (C3d's
> re-contamination regression injects a `BD-` into the C3c-stripped file, and
> PM-step-DD codifies the rule C3d enforces); C4 and C9 may land in any order
> relative to the C3c/C3d/PM-step-DD chain. The GROUP is pushed only after the
> LAST surface fix lands and `validate-pack.py` is green (fire-set 0 — i.e.
> after C4 clears NL-1; EEB-K).

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
  | (iii) | proto self-imports — `example/v1/example_service.proto:7` `import "common/v1/common.proto";` + `common/v1/common.proto:5` self-ref (`grep -rn` over `project-template/proto/` — full output EEB-H) | NOT matched by any current matcher tier — `.proto` is absent from the bare-ref `_CHECK_40_FILE_EXTS` set, so the bare-ref / hyperlink regexes never produce a `.proto` basename (zero `.proto` fires); recognized as VALID via the durable resolve-within-tree rule | **KEEP** (legitimate project-side content — gRPC/protobuf is a supported language with dedicated skill(s); a proto import resolving WITHIN the shipped `project-template/proto/` tree is recognized as VALID by a durable resolve-within-tree rule, NOT a basename allowlist) |
  | (i)+(iv) | `README.md:9` — bare-prose `V10-DESIGN.md` | bypasses (no backticks) | **STRIP** (K4.1 / JC-3) |
  | (i) | `OPTIONAL-FEATURES.md:174` — bare `MERGE-STRATEGY.md` "in the pack repo" | anchor-EXEMPT | KEEP-or-qualify (K4.5) |
  | (i) | `PM-CHAT.md:530` — `docs/pack/MERGE-STRATEGY.md` primary | passes (resolves syntactically) but dead at client | **STRIP** (K4.4) |
  | supporting-docs prefix | pm-startup family `supporting-docs/METHODOLOGY.md` ×4 copies | passes (METHODOLOGY in installed-set) but `supporting-docs/` dir absent at client | **STRIP** (K2.1/K4.3) |
  | (supporting-docs prefix) | `project-template/README.md:13/38/44` — `supporting-docs/...` refs (`:13` = the `cp ... supporting-docs/METHODOLOGY.md ... docs/pack/METHODOLOGY.md` line; `:38`/`:44` = the "Directory boundary rule" prose describing the pack's two-dir layout) | walked by Check 43 (`_iter_client_installed_files()` does `(a) all regular files under project-template/ recursive` — validate-pack.py:4116-4140) | **NOT a standalone KEEP — STRIP-or-rework folded into the C3a JC-3 README rework** (this README is the v10-titled client README whose `cp -r` (B.1), `V10-DESIGN.md` cite (K4.1), and v10 title (K5.1) are all reworked in C3a; lines 13/38/44 are resolved by that rework, not by a permanent allowlist entry) |

  **Step 2 — Categorize.** STRIP = K4.2 (research-doc + SHA), the NEW
  `.mcp.json.example:9` CLI-PM-SETUP leak, K4.1 bare-prose V10-DESIGN.md, K4.4
  dead primary MERGE-STRATEGY path, the pm-startup
  `supporting-docs/METHODOLOGY.md` family (K2.1/K4.3). KEEP (the proto-validity
  set, re-measured) = the proto self-imports
  (`example/v1/example_service.proto` → `common/v1/common.proto`, and
  `common/v1/common.proto`'s self-ref) — they resolve within the shipped
  `proto/` tree. These are recognized as VALID by the durable
  resolve-within-tree rule (Step-4), NOT a basename allowlist. The
  `project-template/README.md:13/38/44` `supporting-docs/` refs are NOT a KEEP:
  they are STRIP-or-rework lines folded into the C3a JC-3 README rework (the
  same v10 client README B.1/K4.1/K5.1 touch), so the KEEP set stays sized to
  the in-tree proto imports alone. Separately, the
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

  **Step 4 — Size the KEEP set EXACTLY (durable proto-validity rule).** The
  KEEP set re-measured at HEAD (`grep -rn` over `project-template/proto/` +
  the `supporting-docs/` walk in EEB-H) is the **proto self-imports**.
  Recognized as VALID via a **durable resolve-within-tree rule**, NOT two
  hardcoded basenames:
    - **Rule (the proto-validity KEEP):** any proto `import` whose target
      resolves to an existing file WITHIN the shipped `project-template/proto/`
      tree is VALID (never flagged). This is implemented as a
      resolve-within-tree predicate (`_check_43_proto_resolves_in_tree` in
      `scripts/validate-pack.py` — a `.proto` basename that resolves to a file
      under `project-template/proto/`), NOT as a basename allowlist. The rule
      survives the proto tree growing or gRPC/protobuf skills adding example
      protos, so it does not go stale the way the two prior hardcoded entries
      (`common.proto`, `example_service.proto`) would have. (The
      `google/protobuf/*` / `google/rpc/*` imports are external well-known
      protos that do NOT resolve in-tree → NOT admitted by the rule; out of
      scope for this guard.)
    - **Defensive + bounded (`ci-guard-measure-then-bound`):** the rule is
      DEFENSIVE — the current matcher does NOT fire on proto imports at all
      (`.proto` is absent from `_CHECK_40_FILE_EXTS`; zero `.proto` fires), so
      the rule has no effect on the present fire-set. It exists so any FUTURE
      matchable proto reference is correctly recognized as valid. It is BOUNDED
      to resolve-within-tree imports ONLY: it admits NO external/non-resolving
      proto path, NO pack-doc basename, and NO other STRIP-class hit.
    The KEEP set gets NO other new entries. Specifically:
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
  carrying a pack-only basename FAILs; the durable proto-validity rule tested
  in BOTH directions (an in-tree proto basename is VALID; a non-resolving /
  external proto basename — and a pack-doc basename — is NOT admitted);
  a commit-SHA provenance FAILs; a `supporting-docs/<installed-basename>` cite
  on a client surface FAILs (prefix rule); a fenced supporting-docs source
  file does NOT trip the prefix rule (disjointness). Confirm no regression on
  the 6 anchored KEEP hits.
- **(d) Keyword:** `pack-only`. Valid: only `scripts/` paths (EEB-E).
- **(e) Manifest:** RUN build. Expected EMPTY (`validate-pack.py` not staged
  into fixtures — EEB-F). Stage only if non-empty.
- **(f) Verify:** `bash scripts/tests/test-validate-pack-check-43.sh` with the
  new cases (a `.example` carrying a pack-only basename FAILs; the durable
  proto-validity rule passes BOTH directions — in-tree proto basename VALID,
  external/pack-doc basename NOT admitted; a commit-SHA provenance FAILs; a
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
  the proto KEEP is recognized by the durable resolve-within-tree rule
  (bounded to in-tree proto imports ONLY — never an external/non-resolving
  proto path, a pack-doc basename, or any other STRIP/unclassified hit), not a
  basename allowlist. Bounded review/fix.

### C3 — Client-surface leak + currency fixes (split C3a project-template / C3b xcode)

C3 is SPLIT because `xcode-companion-templates/` is neither `project-template/`
nor `supporting-docs/` (EEB-E), so a single `project-only` keyword cannot cover
it. Two commits:

**C3a — project-template/ client surfaces (no keyword)**

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
  the NEW `.mcp.json.example:9` CLI-PM-SETUP leak + NL-4
  (`project-template/README.md` pack-repo-internal layout / skill-distribution
  prose; surfaced during C3a review, folded into C3a per user direction
  2026-06-02).
  > Correction binding: K5.8 (`xcode-companion-templates/README.md`) and
  > B.11 (`xcode-companion-templates/Codex/config.toml`) move to **C3b**.
  > C3a findings = K2.1, K4.1–K4.5, K5.1–K5.6, B.1, B.2, B.3, B.4 + new leak
  > + NL-4.
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
  - **NL-4** (`project-template/README.md`, surfaced during C3a review, folded
    in per user direction 2026-06-02): the README describes PACK-REPO INTERNALS
    on a Check-43-walked client surface — the two-directory pack layout
    (`project-template/` + `supporting-docs/`), the `cp -r` whole-template
    mechanic, `init-project.sh`-driven distribution, the "Directory boundary
    rule" and "Skill distribution" sections, and pack-only doc names. A client
    repo has none of these directories and never runs that distribution, so
    this is contamination by the directory-based rule. **Fix (the user-directive
    rework principle, binding 2026-06-02):** find the pack/project boundary in
    the README; REMOVE the pack-related content; then make the remaining
    project/client-relevant content factually correct for the INSTALLED client
    layout — paths as files actually land per `_CLIENT_INSTALLED_FILES` (trinity
    at the project root; `docs/pack/<X>`; skills at
    `.{claude,codex,gemini}/skills/<name>/SKILL.md`), NOT the pre-install
    pack-repo source paths; and if a section cannot be made factually correct
    for the client layout, REMOVE it. Applied: the "Directory boundary rule",
    "Conditional files", and "Skill distribution" sections were removed (not
    correctable for an already-installed client); the intro + contents table
    were reworked to the client install layout.
  - **NEW leak** (`.mcp.json.example:9`): cites `supporting-docs/CLI-PM-SETUP.md`,
    a dead client path (CLI-PM-SETUP.md is NOT client-installed — only
    METHODOLOGY.md + INSTALL-PROCEDURES.md are; EEB-G). Fix: drop the
    `supporting-docs/CLI-PM-SETUP.md` cite or re-point to a client-resolvable
    setup note.

  Project-side SSOT honored (`P-missed-7`): K4.4 keeps the fenced
  `pack-ops/MERGE-STRATEGY.md` fallback (no project-side SSOT exists); B.2
  rewrites SSOT-table paths to client-resolvable forms; K2.1/K4.3 →
  `docs/pack/METHODOLOGY.md` (the client-installed location, EEB-G).
- **(d) Keyword:** **none (no keyword).** This commit stages
  `test-fixtures/manifest.txt` (`regenerate-manifest-v11-surface`, non-empty
  diff — CONFIRMED non-empty for C3a); `project-only` denies any path outside
  `project-template/`+`supporting-docs/`, so the manifest forces no-keyword
  (mixed-scope per the Check-36 convention). `project-only` would be valid ONLY
  if the manifest diff is empty (no `test-fixtures/` path in the commit).
  Every C3a content path is under `project-template/` (EEB-D), but the staged
  manifest path is not, which is why the commit cannot claim `project-only`.
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

**C3c — Full pack-self strip of `scripts/lib/detect.sh` + `scripts/pack-help.sh` (NL-2/NL-3 + clean end-state, `pack-only`)**

REWRITTEN 2026-06-02 (user decision, superseding the original 2-line NL-2/NL-3
reword). The architect dual-use investigation
(`ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` §8) + the user's binding rulings
EXPAND C3c from "reword 2 `AUDIT-BD-035` comments" to a FULL pack-self strip of
BOTH client-shipped scripts. Binding facts:

- **Location stays pack-side.** `scripts/lib/detect.sh` + `scripts/pack-help.sh`
  STAY in `scripts/` (NOT promoted to `project-template/scripts/`). Reason
  (dependency-direction principle, §8.0): `init-project.sh` / `add-capability.sh`
  / the migrator are PACK OPERATIONS that `source` `detect.sh` at runtime; a
  project-side deliverable must NEVER be a runtime dependency of a pack
  operation. The architect RETRACTED its §A "promote" recommendation. So C3c is
  a CONTENT strip only — no `git mv`, no install-mechanism change, no caller
  re-point.
- **Full strip (not just the 2 CI-firing lines).** Per `bd-pack-only-operational-
  rule` (categorical: no pack-self refs anywhere in client-shipped content) the
  WHOLE pack-self provenance layer is stripped, even the parts CI does not yet
  catch. The current guard fires on only the doc-BASENAME `AUDIT-BD-035.md`
  (NL-2/NL-3); the ~32 remaining bare `BD-NNN` provenance comments + the
  `PLATFORM-SKILLS.md` / `V10-DESIGN` / `ARCHITECTURE-SKILL-DIMENSIONS.md` cites
  pass CI today but are the SAME-class leak (EEB-J). They are stripped here for
  the clean end-state, not because CI forces them.
- **KEEP the functional fenced surface-routing.** The `pack-ops/BACKLOG.md`
  candidate-scan paths in `detect_pack_surface` (`detect.sh:22-37`/`:45-47`,
  fenced) and the `pack-ops/HELP-FRAGMENT-*.md` fragment-resolution paths in
  `pack-help.sh` (fenced) are LOAD-BEARING — the code must reference them to run.
  They pass the op-vs-explanatory test (`bd-pack-only-operational-rule`):
  functional treatment = legitimate, fence-covered. They are NOT stripped.

- **(a) Files:** `scripts/lib/detect.sh`, `scripts/pack-help.sh` (both).
- **(b) Findings:** NL-2 (`detect.sh:351`), NL-3 (`detect.sh:360`) — the 2 new
  leaks the guard fires on — PLUS the full same-class strip set (architect §C.3,
  user-approved): ~32 further bare `BD-NNN` provenance comments + the
  `AUDIT-*`/`PLATFORM-SKILLS.md`/`V10-DESIGN`/`ARCHITECTURE-SKILL-DIMENSIONS.md`
  doc cites in `detect.sh`, and the 6 `BD-NNN` + `V3 §`/`DELTA` provenance prose
  in `pack-help.sh`. (Not among the 67; surfaced + scoped per `bd195-prompt-
  goals-section` Q1/Q2 and approved by the user 2026-06-02.)
- **(c) Recipe — full pack-self strip (inline, verbatim):**
  - **`detect.sh` STRIP set (EEB-J):** remove EVERY `BD-NNN` token from `#`
    comments (34 occurrences / 10 distinct BDs: BD-035 ×5, BD-075, BD-114,
    BD-119, BD-141 ×9, BD-144, BD-156 ×8, BD-157 ×4, BD-162 ×2, BD-175 ×2) and
    EVERY pack-doc cite (`AUDIT-BD-035.md`, `PLATFORM-SKILLS.md`,
    `V10-DESIGN §5.14.2`, `ARCHITECTURE-SKILL-DIMENSIONS.md §3.5`). For each
    stripped comment, PRESERVE the client-neutral heuristic rationale (the
    what-it-does / what-it-fixes intent) without naming any pack artifact —
    e.g. `# (BD-035 audit finding F5 fix — see AUDIT-BD-035.md §3.)` →
    a plain statement of the heuristic the line implements. NL-2 (`:351`) and
    NL-3 (`:360`) are the two such lines the guard fires on; they are stripped
    by this same recipe along with the rest.
  - **`pack-help.sh` STRIP set:** remove the 6 `BD-NNN` tokens (BD-075, BD-077,
    BD-175 ×2, BD-177 ×2) and the `V3 §28.2.x` / `DELTA L1` provenance prose
    from `#` comments; preserve the client-neutral description of what each
    block does.
  - **KEEP (do NOT strip):** the fenced functional `pack-ops/BACKLOG.md`
    surface-routing paths in `detect.sh` (`:22-37`/`:45-47`) and the fenced
    `pack-ops/HELP-FRAGMENT-PACK.md` / `pack-ops/HELP-FRAGMENT-TRACKER.md`
    resolution paths in `pack-help.sh` — these are inside
    `<!-- DENY-LIST-CONTENT-START/END -->` fences and are required for the code
    to locate its inputs at runtime. The strip touches ONLY unfenced provenance
    prose.
  - **No new doc invented** (NUD-2-style discipline): the BD/design provenance
    already lives in the pack-side records (`maintenance-docs/v11-implementation/`,
    `pack-ops/BACKLOG.md`); the strip simply stops duplicating those citations
    into a client-shipped surface. Pack design history stays pack-side.
  > Pack-self-ref boundary (`bd-pack-only-operational-rule`): both files ship to
  > clients (init-project.sh stages `scripts/lib/detect.sh` +
  > `scripts/pack-help.sh` — EEB-F/EEB-J); `BD-NNN` tokens + pack-doc cites are
  > pack-internal and dead at a client. The reword keeps the heuristic's design
  > rationale (the what-it-does intent) without naming pack-internal artifacts.
- **(d) Keyword:** `pack-only`. Valid: the only touched paths are
  `scripts/lib/detect.sh` + `scripts/pack-help.sh` — under `scripts/`, NOT under
  `project-template/` or `supporting-docs/` (Check 36 pack-only deny-set, EEB-E).
  `pack-only` tolerates `scripts/` + `test-fixtures/` (the manifest, if staged).
- **(e) Manifest:** `scripts/` IS a named v11 surface AND `detect.sh` +
  `pack-help.sh` ARE staged into fixtures (init-project.sh `cp -f` of both —
  EEB-F/EEB-J), so the regen rule fires AND the diff is LIKELY non-empty (the
  reworded comments change the staged files' bytes). RUN
  `bash test-fixtures/build.sh --all --clean`; stage `test-fixtures/manifest.txt`
  in this commit IFF the diff is non-empty (run-then-check; do not skip on a
  prediction).
- **(f) Verify:** `python3 scripts/validate-pack.py` (the two `detect.sh`
  `AUDIT-BD-035.md` fires — NL-2/NL-3 — must be GONE; Check 43 clean on both
  files). `grep -nE 'BD-[0-9]+|AUDIT-|PLATFORM-SKILLS|V10-DESIGN|ARCHITECTURE-'
  scripts/lib/detect.sh scripts/pack-help.sh` → only the fenced functional
  `pack-ops/` routing lines remain (no `BD-NNN` token, no pack-doc cite outside
  the fence). `bash scripts/test-detect.sh` && `bash scripts/tests/pack-help-test.sh`
  (behavior unchanged — comment-only edits, zero executable-code change; protects
  Goal 2 / `/pack-help`). The migrator/init tests
  (`bash scripts/tests/test-init-project.sh`,
  `bash scripts/tests/test-migrate-v10-to-v11.sh`) stay green (pack-side sourcing
  of `detect.sh` is unchanged — no `git mv`).
- **(g) Executor + gate:** fresh `pack-coder`. `bd-pack-only-operational-rule`:
  surgical strip removing pack-self refs while preserving heuristic rationale;
  no executable code touched (comments only). `enumerate-encoding-surfaces`: the
  strip touches ONLY the two source files' comments — the Check-43 test fixtures
  that assert detect.sh leak-classes (`scripts/tests/fixtures/project-side-refs/
  project-side-fail-detect-sh-comment.sh`) use a SYNTHETIC stub, not the real
  file's bytes, so they need no edit; the real-file cleanliness is asserted by
  the full `validate-pack.py` run in (f). `pack-repo-code-comment-deferrals`: no
  deferral introduced. Bounded review/fix.

**C3d — Sanctioned-exception freeze + Check 47 anti-pattern guard (`pack-only`)**

NEW PG-2 commit added 2026-06-02 (architect §8.1/§8.2 (a)+(b), user-approved).
Post-C3c the two files are CLEAN but pack-side-LOCATED and client-SHIPPED — a
deliberate, bounded exception. Today there is NO frozen sanction: branch (b) of
`_iter_client_installed_files` (`validate-pack.py:4116-4148`) admits ANY
non-`project-template/` map entry to the Check-43 walk with zero membership gate
(EEB-K) — the exception is implicit and UNBOUNDED. C3d (a) freezes the exception
to EXACTLY the two files and (b) blocks the lazy "ship a new file from
`scripts/`" path. The §8.2 SIX lock-step encoding surfaces land here (surfaces
1–4 + 6; surface 5 — the trinity `## Pack memory` rule — is the PM-only step
that immediately follows, see "PM-step-DD" below).

- **(a) Files:** `scripts/validate-pack.py`,
  `scripts/tests/test-validate-pack-check-43.sh` (+ a Check-47 test — folded into
  the same file or a new `scripts/tests/test-validate-pack-check-47.sh` per
  `filename-uniqueness-heuristic`; if new, wire it into the CI runner so Check 42
  stays green).
- **(b) Findings:** none of the 67 (guard design); realizes architect §8.1/§8.2.
- **(c) Recipe — the §8.2 surfaces 1–4 + 6 (inline, verbatim):**
  - **Surface 1 — frozen constant.** Add `_SANCTIONED_PACK_SIDE_SHIPPED` to
    `scripts/validate-pack.py`, a FROZEN 2-tuple holding EXACTLY
    `("scripts/lib/detect.sh", "scripts/pack-help.sh")`, with the inline
    contract comment from architect §8.1 (each entry is a pack-operation runtime
    dependency AND must ship; ADDING an entry requires architect+user
    authorization citing `ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` §8 and
    Check 47). The constant sanctions LOCATION (pack-side + ships), NOT content.
  - **Surface 2 — walk-gate.** Change branch (b) of
    `_iter_client_installed_files` so the non-`project-template/` entries are
    admitted to the walk ONLY IF they are members of
    `_SANCTIONED_PACK_SIDE_SHIPPED`; an UNsanctioned non-template entry is a HARD
    error (not a silent add). CRITICAL: this is a MEMBERSHIP GATE, NOT a content
    skip — the sanctioned files STAY fully walked and fully cleanliness-enforced
    by Check 43/37; the gate authorizes their PRESENCE in the walk-set, never
    relaxes their content. (Re-adding a `BD-` token to `detect.sh` post-strip
    MUST still FAIL Check 43 — verified by the regression in surface 4.)
  - **Surface 3 — Check 47 (`check_sanctioned_pack_side_shipped()`).** New check,
    `# ── Check 47: ...`. Next-free integer VERIFIED = 47 (EEB-A re-measured:
    highest existing Check = 46; 44/45/46 are the BD-196 checks). Two assertions:
    (1) FREEZE / set-equality — the set of non-`project-template/`,
    non-`supporting-docs/` entries parsed from `_CLIENT_INSTALLED_FILES`
    (init-project.sh map) MUST EQUAL `_SANCTIONED_PACK_SIDE_SHIPPED` exactly
    (neither superset nor subset) — so adding a pack-side shipped file to the map
    WITHOUT editing the frozen constant FAILS CI; (2) the failure message names
    the dependency-direction MEMBERSHIP TEST (a file qualifies ONLY IF (1) a pack
    operation depends on it at runtime AND (2) a client surface requires it
    shipped; default for new shipped files stays `project-template/scripts/`) and
    cites this doc §8.3. `ci-guard-measure-then-bound`: the sanction is sized to
    EXACTLY the 2-member set; the gate admits no unclassified entry; Check 47
    fails on any superset/subset.
  - **Surface 4 — tests.** Extend `test-validate-pack-check-43.sh` (+ Check-47
    cases) with the regression set: (i) a CLEAN sanctioned file PASSES Check 43;
    (ii) a sanctioned file with an INJECTED `BD-` (or pack-doc cite) still FAILS
    Check 43 (proves the gate is membership-only, not a content silencer — the
    load-bearing re-contamination regression); (iii) a non-template map entry NOT
    in the frozen constant FAILS Check 47 (lazy-add blocked); (iv) a constant
    entry NOT in the map FAILS Check 47 (set-equality, both directions). The T3
    inventory + T8 detect.sh synthetic cases already in the test
    (`test-validate-pack-check-43.sh:183-192/447-459`) are the integration
    anchors.
  - **Surface 6 — manifest.** Covered by (e).
- **(d) Keyword:** `pack-only`. Valid: only `scripts/` paths (validate-pack.py +
  the test) — none under `project-template/` or `supporting-docs/` (EEB-E).
- **(e) Manifest:** RUN `bash test-fixtures/build.sh --all --clean`. Expected
  diff EMPTY (`validate-pack.py` + the test are NOT staged into fixtures — EEB-F;
  C3d does not touch any fixture-feeding file). Stage `manifest.txt` only if
  non-empty.
- **(f) Verify:** `bash scripts/tests/test-validate-pack-check-43.sh` (with the
  new regression cases: clean sanctioned PASSES; injected-`BD-` sanctioned FAILS;
  unsanctioned non-template map entry FAILS Check 47; constant-entry-not-in-map
  FAILS Check 47) && `python3 scripts/validate-pack.py` (full run; Check 47 OK;
  Check 43 still clean on the C3c-stripped files; the only remaining fire is
  NL-1 `INSTALL-PROCEDURES.md:655` until C4 lands — see the push-group note).
- **(g) Executor + gate:** fresh `pack-coder`. `enumerate-encoding-surfaces`:
  surfaces 1–4 (frozen constant + walk-gate + Check 47 + tests) land together in
  THIS single commit; surface 6 (manifest) per (e); surface 5 (trinity rule) is
  the immediately-following PM-only step (PM-step-DD) — flagged so the encoding
  set is complete across the C3d commit + the PM step. `ci-guard-measure-then-
  bound` (architect §8.1/§8.2). Bounded review/fix.

**PM-step-DD — Trinity `## Pack memory` dependency-direction rule (PM-only, Pack-Chat-direct)**

The §8.2 surface-5 rule is PM-ONLY — Pack Chat writes it directly into the
pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`
`### Repo conventions`), NOT a coder (trinity files are PM-only per
`PACK-AGENTS.md` § "PM-only files and directories"; `skill-agent-maintenance-
mechanical` routes a rule change to PM, not convenience). This is a SEPARATE
step from C3d (different executor + different keyword), sequenced immediately
after C3d in PG-2.

- **The rule (architect §8.2/§8.3 wording):** "Client deliverables default to
  `project-template/scripts/`. A pack-side file may be client-shipped ONLY IF it
  is a pack-operation runtime dependency AND must ship to clients, AND ONLY via
  `_SANCTIONED_PACK_SIDE_SHIPPED` in `validate-pack.py` with architect + user
  sign-off (Check 47 freezes the set; the dependency-direction principle is the
  membership test)." `[roles: coder architect] [rationale: dual-use-shipped-lib-
  dependency-direction]` (slug is a PM editorial call at write time).
- **(d) Keyword:** `PM-only`. Valid: only the pack-root trinity files (PM-only
  by construction). Note: `PM-only` PERMITS `project-template/` trinity but this
  rule lands on the PACK-ROOT trinity (it is a pack-developer repo convention,
  not a project rule) — still within the PM-only file set.
- **(e) Manifest:** the pack-root trinity (CLAUDE/AGENTS/GEMINI) is the
  `regenerate-manifest-v11-surface` base-case EXEMPT (they are not under the four
  named surfaces and do not feed fixtures). No build run required for the trinity
  edit itself. BUT see the propagation note below — IF a `[rationale: slug]` is
  attached, the bijection/manifest surfaces in the PACK-CHAT.md procedure apply.
- **Propagation (binding — PACK-CHAT.md § "Rule-change propagation procedure"):**
  a spawn-relevant `## Pack memory` rule carrying `[rationale: slug]` triggers
  the ordered multi-surface PM-only propagation, all in the SAME commit so
  Check 45 (rule↔rationale bijection) + the anti-restate scan never see a
  half-applied state: (1) corpus imperative line ×3 trinity (with `[roles:]` +
  `[rationale: slug]`); (2) `pack-ops/PACK-MEMORY-RATIONALE.md` `## <slug>` entry
  (Check 45 bijection); (4) any one-line reference in `PACK-AGENTS.md` /
  `PACK-CHAT.md`; (5) `pack-ops/.spawn-rule-manifest.txt` slug→canonical+refs
  (Check 46); (6) `test-fixtures/manifest.txt` regen only if a v11-surface path
  changed (trinity is base-case exempt → expected no manifest change). The thin
  out-of-repo memory-cache pointer (3) is Pack-Chat upkeep. Order: corpus →
  rationale → references + manifest in one commit → cache as upkeep.
- **(g) Executor + gate:** **Pack-Chat-direct PM-only edit** (NOT a coder — per
  CLAUDE.md "What Pack Chat CAN edit directly": PM-only files). No bounded
  review/fix cycle (PM-only direct edits are not coder work); user approves the
  commit. The pack-architect-spawn-protocol does NOT require a fresh architect
  pass here — the rule wording is already designed in
  `ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` §8.2/§8.3; Pack Chat applies it
  mechanically.

### C4 — supporting-docs currency (incl. K5.11 per NUD-6)

- **(a) Files:** `supporting-docs/SETUP-EXISTING.md`,
  `supporting-docs/SETUP-NEW.md`, `supporting-docs/DEPENDENCIES.md`,
  `supporting-docs/SETUP_TEMPLATE.md`,
  `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`,
  `supporting-docs/METHODOLOGY.md`,
  `supporting-docs/INSTALL-PROCEDURES.md` (NL-1, added 2026-06-02).
- **(b) Findings:** K5.9, K5.10, K5.11, K5.12, K5.13, K5.14, K3.6 (7) +
  NL-1 (new leak, `INSTALL-PROCEDURES.md:655`).
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
  - **NL-1** (`INSTALL-PROCEDURES.md:655`, new leak surfaced by C2's broadened
    guard, reviewer-confirmed GENUINE): the line cites a dead `V10-DESIGN.md`
    reference (`V10-DESIGN.md` is pack-only at `maintenance-docs/archive/`,
    never client-installed; Check 43 reports it as a broken/dead bare ref at a
    client surface). Fix: drop OR re-point the dead `V10-DESIGN.md` reference
    to a client-resolvable form — the C4 coder picks the exact target from
    resolving docs, consistent with the other C4 recipes (e.g., point at the
    client-installed `docs/pack/METHODOLOGY.md` or drop the cite if the
    surrounding prose still reads correctly without it).
- **(d) Keyword:** **none (no keyword).** This commit stages
  `test-fixtures/manifest.txt` (`regenerate-manifest-v11-surface`) when the
  diff is non-empty — EXPECTED non-empty (C4 edits client-installed,
  fixture-feeding content; confirm at execution per (e)); `project-only`
  denies any path outside `project-template/`+`supporting-docs/`, so the
  staged manifest forces no-keyword (mixed-scope per the Check-36 convention).
  `project-only` would be valid ONLY if the manifest diff is empty (no
  `test-fixtures/` path in the commit). All C4 content paths are under
  `supporting-docs/` (project-side per EEB-E), but the staged manifest path is
  not, which is why the commit cannot claim `project-only`.
- **(e) Manifest:** RUN build. Expected EMPTY (`supporting-docs/` is copied
  individually at install but its content does not change the fixture git
  SHAs the manifest pins — only `METHODOLOGY.md` ships, to `docs/pack/`;
  whether its edit moves a fixture SHA is determined by the run). RUN, stage
  IFF non-empty.
- **(f) Verify:** `python3 scripts/validate-pack.py` (C2 broadened guard
  present; must PASS). Confirm K3.6 routes to the resolving
  `MIGRATION-v10-to-v11.md` (EXISTS — EEB-B). Confirm NL-1: the
  `INSTALL-PROCEDURES.md:655` `V10-DESIGN.md` Check-43 fire is GONE (the dead
  cite dropped or re-pointed to a client-resolvable target).
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
- **(d) Keyword:** **none (no keyword).** This commit stages
  `test-fixtures/manifest.txt` (`regenerate-manifest-v11-surface`) when the
  diff is non-empty — EXPECTED non-empty (C9 edits client-installed,
  fixture-feeding content; confirm at execution per (e)); `project-only`
  denies any path outside `project-template/`+`supporting-docs/`, so the
  staged manifest forces no-keyword (mixed-scope per the Check-36 convention).
  `project-only` would be valid ONLY if the manifest diff is empty (no
  `test-fixtures/` path in the commit). Every C9 content path is under
  `project-template/` (EEB-D), but the staged manifest path is not, which is
  why the commit cannot claim `project-only`.
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
| R-8 | **C3c strips a functional fenced routing line by mistake.** The full strip touches comments throughout `detect.sh`/`pack-help.sh`; over-stripping a fenced `pack-ops/BACKLOG.md` / `HELP-FRAGMENT-*` routing path would break `detect_pack_surface` / `/pack-help` (Goal 2 regression). | C3c recipe pins the KEEP set to the fenced `<!-- DENY-LIST-CONTENT-START/END -->` blocks (EEB-J line refs); (f) runs `bash scripts/test-detect.sh` + `pack-help-test.sh` (behavior unchanged) + asserts only fenced functional `pack-ops/` lines remain via grep. Comments-only edit — zero executable-code change. |
| R-9 | **C3d walk-gate implemented as a content SKIP (silences the guard) instead of a membership GATE.** A skip would let future re-contamination of the sanctioned files pass CI — defeating the freeze. | C3d surface-2 recipe + surface-4 regression (ii): the gate authorizes PRESENCE in the walk-set ONLY; the files stay fully cleanliness-enforced; the test injects a `BD-` into the stripped `detect.sh` and asserts Check 43 STILL FAILS. `ci-guard-measure-then-bound`: sanction sized to exactly the 2-tuple; Check 47 fails on any superset/subset. |
| R-10 | **PM-step-DD lands a half-applied trinity rule (Check 45 bijection FAIL).** A `## Pack memory` rule with `[rationale: slug]` but no matching `PACK-MEMORY-RATIONALE.md` entry / spawn-manifest entry fails Check 45/46. | PM-step-DD (e) + propagation note: corpus ×3 + rationale entry + spawn-manifest + references land in the SAME PM-only commit (PACK-CHAT.md § rule-change-propagation order); the trinity is manifest base-case exempt so no fixture regen needed. |

### 5.3 — No deferrals

All 63 actionable findings + all 4 new leaks (`.mcp.json.example` → C3a,
NL-1 → C4, NL-2/NL-3 → C3c) land in v11.0 commits in this plan
(`deferral-is-scope-creep` / `no-deferral-without-user-direction`). The new
leaks surfaced by C2's broadened guard (reviewer-confirmed GENUINE) are
scheduled into PG-2 per user direction (2026-06-02), not deferred. The EXPANDED
C3c scope (the full same-class pack-self strip of `detect.sh` + `pack-help.sh`
beyond the 2 CI-firing lines — architect §C.3) lands in v11.0 (C3c), NOT
deferred — per `no-deferral-without-user-direction` the user authorized the full
strip 2026-06-02. The sanctioned-exception freeze + Check 47 (C3d) and the
trinity rule (PM-step-DD) also land in v11.0, in the same PG-2 push. The 4 NUD-1
findings are NOT deferred — reclassified NOT-A-DEFECT by user ruling
(non-actionable, not postponed). No finding is pushed to v11.1+.

---

## 6 — Empirical-Evidence Blocks

EEB-A..EEB-H measured at HEAD `c440bdf742a52f6fc0d66b75f6f07a88771f374e`,
branch `v11-dev`, 2026-06-01. **EEB-J + EEB-K** (the BD-195 dual-use-shipped-lib
re-sequencing) re-measured at HEAD `bb9e807722d282ea4272c90f012d8ba63552d4e04`,
2026-06-02 — after C1 (`8555953`) / C2 (`1d3c55a`) / C3a (`551a1f4`) / C3b
(`bb9e807`) landed. EEB-A's `Check 1 … Check 46` ceiling is RE-CONFIRMED at
`bb9e807` (EEB-K: highest existing Check = 46 → next-free = 47); EEB-F's
fixture-input facts hold at `bb9e807` (init-project.sh stages both shipped
scripts, EEB-J).

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
- Interpretation: every C3a and C9 CONTENT path is under `project-template/`.
  This alone would admit `project-only`, but because C3a/C9 each stage the
  regenerated `test-fixtures/manifest.txt` (`regenerate-manifest-v11-surface`),
  the commit also touches a path outside `project-template/`+`supporting-docs/`
  — so the final keyword is **none (no keyword)**, not `project-only` (see the
  C3a/C9 (d) lines).
- Conclusion: SUPPORTED.

**EEB-E — Check 36 scope-keyword path model.**
- Command: `sed -n '3821,3824p' scripts/validate-pack.py`.
- Output (verbatim):
  `# Pack-only path prefixes for scope honesty (Check 36 pack-only check):`
  `# a `pack-only` commit MUST NOT touch any path under these prefixes.`
  `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`.
- Interpretation: `pack-only` DENIES `project-template/` + `supporting-docs/`;
  `project-only` is the inverse (denies everything outside those two).
  Therefore: C1/C2/C6 `pack-only` valid (scripts/ only — `pack-only` tolerates
  `test-fixtures/`); C3a/C9 content is under `project-template/` and C4 content
  is under `supporting-docs/` (project-side), but each stages the regenerated
  `test-fixtures/manifest.txt`, a path outside both project-side prefixes — so
  C3a/C4/C9 carry **no keyword** (`project-only` would FAIL Check 36 on the
  staged manifest path; mixed-scope per the Check-36 convention); C3b
  `xcode-companion-templates/` is NEITHER prefix → no keyword (project-only
  would FAIL Check 36); C5 mixed scripts/+maintenance-docs/+pack-root → no
  keyword.
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

**EEB-H — JC-2 proto-validity KEEP set (durable resolve-within-tree rule).**
- Command: `ls project-template/proto/example/v1/example_service.proto
  project-template/proto/common/v1/common.proto`.
- Output (verbatim): both files EXIST.
- Interpretation: the C2 proto KEEP (C2 §2.2 Step-4) is recognized by a
  DURABLE resolve-within-tree rule (`_check_43_proto_resolves_in_tree`): any
  proto reference whose basename resolves to an existing file WITHIN
  `project-template/proto/` is VALID. This REPLACES the two prior hardcoded
  allowlist basenames so the rule survives the proto tree growing or skills
  adding example protos. It is DEFENSIVE (the current matcher does not fire on
  proto imports — `.proto` is absent from `_CHECK_40_FILE_EXTS`, so zero
  `.proto` fires) and BOUNDED to in-tree imports only (never admits an
  external/non-resolving proto path or a pack-doc basename).
  `project-template/README.md:13/38/44` `supporting-docs/` refs are NOT
  carved out by the proto rule — they are resolved by the C3a README rework
  (see C2 §2.2 Step-2 measure table + Step-4). `ci-guard-measure-then-bound`.
- Conclusion: SUPPORTED.

**EEB-J — Full pack-self strip inventory (detect.sh + pack-help.sh) at HEAD `bb9e807`.**
- Commands:
  `grep -oE "BD-[0-9]+" scripts/lib/detect.sh | sort | uniq -c`;
  `grep -nE "AUDIT-|PLATFORM-SKILLS|V10-DESIGN|ARCHITECTURE-" scripts/lib/detect.sh`;
  `grep -oE "BD-[0-9]+" scripts/pack-help.sh | sort | uniq -c`;
  `grep -nE "DENY-LIST-CONTENT" scripts/lib/detect.sh scripts/pack-help.sh`;
  `grep -n "detect.sh\|pack-help" scripts/init-project.sh`.
- Output (verbatim, key):
  `detect.sh` BD tokens = `5 BD-035 · 1 BD-075 · 1 BD-114 · 1 BD-119 · 9 BD-141
  · 1 BD-144 · 8 BD-156 · 4 BD-157 · 2 BD-162 · 2 BD-175` → **34 total /
  10 distinct**; pack-doc cites in `detect.sh` comments = `:253 V10-DESIGN
  §5.14.2`, `:307 ARCHITECTURE-SKILL-DIMENSIONS.md §3.5`, `:351/:360
  AUDIT-BD-035.md §3`, plus `PLATFORM-SKILLS.md` at `:252/:328/:365/:487/:594/
  :723`. `detect.sh` fences = `22 / 37 / 45 / 47` (two blocks — the functional
  `pack-ops/BACKLOG.md` surface-routing, lines `46` etc. are INSIDE; the BD/doc
  provenance comments at `:252/:253/:307/:351/:360/:449/:487/:554/:594/:723` are
  OUTSIDE any fence). `pack-help.sh` BD tokens = `1 BD-075 · 1 BD-077 ·
  2 BD-175 · 2 BD-177` → **6 total**; pack-doc/provenance prose = `V3 §28.2.x`,
  `DELTA L1` (`:2/:4/:6/:13/:33/:38/:40`), `BD-175 reorg` at `:40/:111`; the
  `pack-ops/HELP-FRAGMENT-*.md` resolution paths are inside fences
  (`:28-42/:88-96/:110-130/:136-145/:161-163/:179-181`). init-project.sh stages
  BOTH files (`cp -f .../scripts/pack-help.sh` + `cp -f .../scripts/lib/detect.sh`).
- HEAD/date: `bb9e807` / 2026-06-02.
- Interpretation: the STRIP set is 34 BD tokens + 4 distinct pack-doc-cite
  families in `detect.sh` (all in `#` comments, OUTSIDE the fences) and 6 BD
  tokens + the V3/DELTA provenance prose in `pack-help.sh`; the functional
  `pack-ops/` routing in BOTH files is fenced → KEEP. Both ship to clients →
  the categorical `bd-pack-only-operational-rule` applies. C3c strips the
  unfenced provenance, preserves the fenced functional routing.
- Conclusion: SUPPORTED.

**EEB-K — Sanction currently absent/unbounded; live Check-43 fire-set = 3.**
- Commands:
  `sed -n '4116,4148p' scripts/validate-pack.py` (`_iter_client_installed_files`);
  `grep -n "_SANCTIONED\|EXPECTED_NON_TEMPLATE" scripts/validate-pack.py`;
  `grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | tail -1`;
  `python3 scripts/validate-pack.py` (full run).
- Output (verbatim, key): branch (b) of the walk loops
  `for entry in entries:` with the ONLY filter
  `if entry.startswith("project-template/"): continue` — NO frozen membership
  gate; `grep` for `_SANCTIONED`/`EXPECTED_NON_TEMPLATE` → no match (constant
  does not exist). Highest existing Check NN = **46** (44/45/46 = the BD-196
  checks: M4 concision / rule↔rationale bijection / boundary-spawn manifests).
  `validate-pack.py` exits **1** with exactly **3 FAILs**:
  `FAIL: supporting-docs/INSTALL-PROCEDURES.md:655 — bare cross-reference
  V10-DESIGN.md — broken ref` (NL-1);
  `FAIL: scripts/lib/detect.sh:351 — bare-prose reference to pack-only doc
  AUDIT-BD-035.md` (NL-2);
  `FAIL: scripts/lib/detect.sh:360 — … AUDIT-BD-035.md` (NL-3). The guard does
  NOT fire on any bare `BD-NNN` token (confirmed: only the `AUDIT-BD-035.md`
  doc-BASENAME fires on `detect.sh`); `pack-help.sh` has ZERO fires.
- HEAD/date: `bb9e807` / 2026-06-02.
- Interpretation: (1) the sanctioned-exception is implicit + UNBOUNDED today →
  C3d adds the frozen constant + walk-gate + Check 47 (next-free = **47**,
  verified). (2) The live fire-set is 3, NOT the 13 measured at the original
  planning HEAD (C3a `551a1f4` + C3b `bb9e807` already cleared the
  project-template/xcode portion). (3) C3c strips both `detect.sh` fires
  (351/360) → fire-set 3→1 (NL-1 only); C3d re-walks the clean files with no
  new fire (membership-only gate); C4 clears NL-1 → 0. (4) The full strip goes
  BEYOND CI: the ~32 bare `BD-NNN` + `PLATFORM-SKILLS.md`/`V10-DESIGN`/
  `ARCHITECTURE-SKILL-DIMENSIONS.md` cites pass CI but are stripped for the
  clean end-state (categorical rule).
- Conclusion: SUPPORTED.

---

## 7 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit [universal] | No `git add/commit/push/tag` issued. Tool use: Read (3 input docs), read-only Bash (`git rev-parse`/`git status`/`grep`/`ls`/`find`/`sed`/`head`/`python3 -c` arithmetic), and one Write via heredoc to the single output doc `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md`. `git status --short` at start = clean. | COMPLIANT |
| empirical-evidence-blocks [planner] | §6 EEB-A..EEB-K each carry command + verbatim output (counts/paths/lines, e.g. `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`, `Check 1 … Check 46`, `36` skill dirs, `893:cp -f "$PACK/scripts/lib/detect.sh"`) + HEAD (`c440bdf` for A–H; `bb9e807` for J/K) + interpretation + SUPPORTED. NEW state-claims this pass: detect.sh = **34 BD / 10 distinct** + 4 pack-doc-cite families, pack-help.sh = **6 BD** + V3/DELTA prose, fenced functional routing KEEP (EEB-J); highest Check = **46** → next-free **47**, sanction absent/unbounded, **live fire-set = 3** (NL-1/NL-2/NL-3), post-C3c-strip fire-set **3→1**, C4 → **0** (EEB-K). | COMPLIANT |
| deferral-is-scope-creep [universal] | §2 ledger maps all 63 actionable findings + 4 new leaks to a commit; the EXPANDED C3c full-strip set (architect §C.3, beyond the 2 CI-firing lines), the C3d freeze + Check 47, and PM-step-DD all land in v11.0 (PG-2) — §5.3 records zero deferrals; the 4 NUD-1 findings are reclassified NOT-A-DEFECT (user ruling), not postponed. | COMPLIANT |
| no-deferral-without-user-direction [universal] | §5.3: all actionable work lands in v11.0 commits (C1/C3–C9); nothing pushed to v11.1+; the new `.mcp.json.example` leak lands in C3a (v11.0). | COMPLIANT |
| boundary-investigation-precedes-pack-defaults / P-missed-7 [universal] | Project-side SSOTs named for the project-surface commits: C3a K2.1/K4.3 → client-installed `docs/pack/METHODOLOGY.md` (EEB-G), B.2 → client-resolvable skill/docs paths, K4.4 → existing fenced `pack-ops/MERGE-STRATEGY.md` (no project-side SSOT exists, §1 K4.4); C9 NUD-8 abstract phrasing must not import a pack-only mechanism name (the `docs/project/<stream>/_rules.md` contract is the project SSOT). | COMPLIANT |
| regenerate-manifest-v11-surface [coder, plan sequences it] | Per-commit (e) manifest decisions: C1/C2/C5/C6 RUN build, expected EMPTY (EEB-F), stage IFF non-empty; C3a/C9 RUN build, expected NON-EMPTY, stage; **C3c** RUN build, LIKELY non-empty (both shipped scripts feed fixtures — EEB-J), stage IFF non-empty; **C3d** RUN build, expected EMPTY (validate-pack.py + test not staged — EEB-F), stage IFF non-empty; **PM-step-DD** trinity is base-case EXEMPT (no fixture feed) but a `[rationale: slug]` triggers the PACK-CHAT.md propagation surfaces (bijection/spawn-manifest) in the SAME commit; C4 RUN build, stage IFF non-empty; C7 (pack-ops/) RUN build, expected EMPTY (EEB-F), stage IFF non-empty; C8 (README pack-root) + C3b (xcode) do NOT trigger the rule. Run-then-check is binding; never skip on prediction (R-4). | COMPLIANT |
| enumerate-encoding-surfaces [reviewer/coder, plan sequences it] | C1 pairs the grammar edit with its docstrings/tests/fixture + error-guard in ONE commit; C6 lands the soft-advisory guard + its test together; **C3d realizes the architect §8.2 SIX lock-step surfaces** across the C3d commit + PM-step-DD: surfaces 1–4 (frozen `_SANCTIONED_PACK_SIDE_SHIPPED` constant + walk-gate + Check 47 + the Check-43/47 tests incl. the injected-`BD-` re-contamination regression) land together in C3d; surface 6 (manifest) per (e); surface 5 (trinity `## Pack memory` rule) is PM-step-DD (PM-only). R-6 flags wiring any new test file into the CI runner so Check 42 stays green. | COMPLIANT |
| rules-applied-verification-block [universal] | This table. | COMPLIANT |
| preflight-stop-means-stop [universal] | PREFLIGHT line emitted before the C3c/C3d/PM-step re-sequencing edits, after self-checks (next-free Check = 47 verified EEB-K; post-C3c-strip fire-set 3→1 verified EEB-K; PM-only trinity step flagged; PLAN coherent + self-contained). No parent stop/halt issued. | COMPLIANT |
