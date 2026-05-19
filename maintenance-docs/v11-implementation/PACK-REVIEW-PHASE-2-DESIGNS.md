# PACK REVIEW — BD-175 Phase 2 architect designs (independent reviewer)

**Reviewer:** pack-reviewer (Phase 3, fresh — not the author of A / B / C / B-fix)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 3 (DESIGN REVIEW — verification of A, B, C, B-fix outputs)
**Date:** 2026-05-18
**Branch:** v11-dev
**HEAD at review time:** `8014186`
**Inputs read:**
- `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md`
- `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md`
- `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` (Architect A)
- `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (Architect B)
- `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` (Architect C)
- `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` (Architect B fix-pass)
- Pack-repo files spot-checked: `CLAUDE.md`, `PACK-AGENTS.md`, `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/docs/pack/PM-CHAT.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, `project-template/skills/audit-methodology/SKILL.md`, `scripts/validate-pack.py`, `scripts/lib/detect.sh`, `scripts/lib/tracker-config.sh`, `scripts/lib/per-entry/_lib.sh`, `scripts/pack-help.sh`, `scripts/tests/test-per-entry.sh`, `.claude/agents/pack-coder.md`, `.claude/skills/pack-startup/SKILL.md`

**Out-of-scope inputs (not read per prompt):** 19c-stream artifacts, PATH-C-CURATION.md, prior PACK-REVIEW reports (none exist for BD-175).

---

## §0 — Executive summary

The four Phase 2 architect designs are largely sound and internally consistent on the major axes:

- **G7 boundary definition is unimpeachable + unambiguous** — B's two-axis (Audience × Function) matrix with 6 categories (C1-C6) survives the curation §5 articulation and the worked challenges in B's §1.3. The PROJECT × OPERATIONS (C5) category is the right answer to the V1-style regression pathway.
- **SC8 discoverability is well-designed** — B's `pack-ops/BOUNDARY-DEFINITION.md` plus the dense cross-reference network across PACK-CHAT.md / PACK-AGENTS.md / pack trinity / pack-* agents / README / project-side PM-CHAT.md hits the discoverability invariant.
- **Re-litigation framework is concrete and traceable** — A's per-finding decisions (REVERT / REPLACE / RELOCATE / JUSTIFY / DUAL-INSTALL / SPLIT) anchor in B's operational test (B's §1.2), and the SUBSUMED-BY cascade reduces 36 findings (13 §C + 17 §D + 8 ambiguous + 11 ambiguous-pending) to 8 actionable tasks (T1-T8).
- **Prevention mechanisms are layered correctly** — C's three-surface architecture (codification + process gates + CI enforcement) covers TYPE-1/3/4 mechanically and explicitly acknowledges TYPE-5 as not-mechanically-detectable with a compensating reviewer-gate.
- **B-fix-pass correctly honors Override 5** — BACKLOG.md / CHANGELOG.md classification flips from STAYS-exempt to MOVES (M9/M10); B's two "external constraint" claims are properly rejected with concrete evidence.

The findings below identify cross-architect reconciliation gaps and one BLOCKER where Architect A's V10 framing contradicts the actual pack-memory rule. The BLOCKER is recoverable (V10 collapses to NO-ACTION-needed once the rule is read correctly), but A's misreading must be surfaced so the planner doesn't sequence a phantom hunk-audit task.

**Findings count:** 1 BLOCKER + 4 MUST + 6 SHOULD + 4 NIT = 15 total.

---

## §1 — Findings by severity

Each finding tagged with severity, actor (who fixes), and reference to the specific architect doc location.

### BLOCKER findings (must be resolved before Phase 4 planner spawns)

#### B1 — Architect A's V10 framing contradicts pack-memory: project-template trinity IS PM-only

**Where:** `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V10 (lines 293-311) + §6.3 V10 line ("VERIFY task — per-hunk audit of `8ba0164`") + OQ-6 (lines 721).

**A claims:** "`PM-only` in pack memory means files Pack Chat may edit directly. Per memory, project-template trinity is NOT PM-only. Yet `8ba0164` edited `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`. Misrepresentation of scope; project-template trinity edits should have gone through fix-coder per pack memory rule."

**Reality (verified at HEAD):**
- `CLAUDE.md:337-338` (pack memory § "What Pack Chat CAN edit directly"): explicitly lists `PM-only files (BACKLOG.md / CHANGELOG.md / README version table / PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root / `project-template/` trinity)` as Pack-Chat-direct edits. project-template trinity is **explicitly named** as Pack-Chat-editable.
- `PACK-AGENTS.md:148` (PM-only file list): "`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root **and** `project-template/`)" — same.

A's V10 framing is empirically wrong: project-template trinity IS PM-only and `8ba0164` (BD-167b PM-only-edits) was correctly scoped. V10 collapses from a VERIFY-then-decide task to NO-ACTION.

**Why BLOCKER:** A's TASK-T7 cascade graph (§6.3) carries V10 as a Phase 5 hunk-audit task; the planner will schedule it; the coder will spawn against a no-op directive. Worse, the framing "Pack Chat directly edited files outside its permission scope" propagates as a false precedent into Architect C's M1a memory rule (C §10.1's `Batch-scope claims are enforced by CI, not honor system` cites V10 in §10.2 worked example as a PM-only-claim that "should have failed CI"). C's M1b/M5a Check 36 with `PM-only` keyword would FAIL on the (correct, in-scope) `8ba0164` pattern, creating a false-positive CI gate against legitimate PM-only edits.

**Actor:** Architect A fix-pass (collapse V10 to NO-ACTION); cascade to Architect C fix-pass (drop V10 as M1a/M5a worked example; reframe PM-only keyword definition to match actual `PACK-AGENTS.md:148` PM-only list rather than the audit's narrower reading).

**Fix shape:**
- A: rewrite V10 §2 entry to NO-ACTION with rationale citing `CLAUDE.md:337-338` and `PACK-AGENTS.md:148`; drop V10 from §6.3 cascade; drop OQ-6.
- C: rewrite §10.1 to make PM-only keyword permitted-paths regex include project-template trinity (per actual PACK-AGENTS.md list); rewrite §10.2 worked example to use a real PM-only-claim-vs-non-PM-only-touch violation (e.g., a synthetic test fixture, or audit V2 `aaa61b3` which DID touch outside PM-only by editing `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`).

---

### MUST findings (must be addressed in Phase 5 — block clean implementation if unresolved)

#### M1 — Architect B's `detect_pack_surface` claim is wrong; B-fix correctly catches it but A/C don't ripple

**Where:**
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §3.2 line 293: "pack-help.sh uses a separate auto-detection function (`detect_pack_surface` from `scripts/lib/detect.sh`) which inspects `BACKLOG.md` for entry-shape patterns. That function is unaffected by file moves."
- `scripts/lib/detect.sh:31-51` (verified): `detect_pack_surface` scans `$target/BACKLOG.md` first. After M9 (BACKLOG.md → pack-ops/), the scan returns `ambiguous` for every pack-repo invocation — Check 36 / pack-help.sh dispatch breaks.
- B-fix `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §6.2 + §8.3 correctly surface this as a CRITICAL same-commit update.

**Issue:** B's original M1-M5 commit (before B-fix's M9/M10 fold-in) leaves a window where M5 (`PACK-CHAT.md` move) triggers tracker-config.sh detection update but pack-help.sh detection still scans for root `BACKLOG.md`. If M9/M10 do NOT land in the same commit as M1-M5 (i.e., if the planner schedules per Option B in B-fix §7.2), `detect_pack_surface` is broken between M5-commit and M9-commit landings.

**Why MUST:** This is recoverable as long as the planner applies B-fix's §7.1 Option A (fold M9/M10 into the same commit as M1-M5). B-fix correctly identifies this. The MUST finding is to make sure the planner reads B-fix's Option A as mandatory, not optional — the prose says "RECOMMENDED" and "Reject Option B" but the planner should not have discretion here. If Phase 4 planner picks Option B, CI breaks mid-sequence.

**Actor:** Phase 4 planner — must enforce Option A (combined M1-M5 + M9-M10 single commit).

**Fix shape:** Planner's PLAN-* doc names the single combined commit explicitly with all 7 `git mv` + all script updates + manifest regen in one atomic landing; no per-MOVE commit splitting.

---

#### M2 — Architect C's TYPE-4 deny-list (Check 37, M5b) doesn't include post-B `pack-ops/` paths

**Where:** `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §8.2 (lines 449-462) deny-list table.

**C's deny-list patterns:**
- `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`, `OPTIONAL-FEATURES.md` (bare filename)
- `maintenance-docs/` (path prefix)
- Pack-agent names

**Gap:** After B's M1-M5 + B-fix's M9/M10 land, references to `pack-ops/PACK-AGENTS.md`, `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/PACK-CHAT.md` from project-side files are EQUIVALENT contamination to the current bare-filename refs. C's deny-list doesn't catch them because:
- Bare-filename grep on `PACK-AGENTS.md` matches `pack-ops/PACK-AGENTS.md` (word-boundary heuristic), so this slips through OK.
- But `pack-ops/` as a path-prefix is NOT in the deny-list, so a project-side file referencing `pack-ops/BOUNDARY-DEFINITION.md` (which is pack-only) would NOT be flagged.
- The `maintenance-docs/` path-prefix entry catches that case, but the symmetric `pack-ops/` path-prefix is missing.

**Why MUST:** C explicitly flags the deny-list as B-conditional in §11 + §14, but does not include the obvious `pack-ops/` path-prefix addition. Without it, a future regression where someone references "see `pack-ops/PACK-AGENTS.md` for…" from project-template/ would slip through Check 37.

**Actor:** Architect C fix-pass (or Phase 4 planner addendum if C is closed).

**Fix shape:** Add `pack-ops/` to the deny-list path-prefix entries in §8.2. Mirror this in M4's boundary-investigation skill deny-list (§6 "Pack-only deny-list" section).

---

#### M3 — Architect A's QUICKSTART (F-4) handling is silent; OQ-4 names it but no decision

**Where:**
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` OQ-4 (lines 717): "F-4 QUICKSTART.md audience split. This framework did not design F-4 because QUICKSTART.md does not surface in the §C / §D contamination findings... Phase 3 reviewer verifies that Architect B addresses F-4 and that no §A-related QUICKSTART decision was missed by this framework."
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §4.4 (S1 commit): SPLIT QUICKSTART into pack-side + project-side halves; `project-template/docs/pack/QUICKSTART.md` is NEW.
- `AUDIT-USER-CURATION.md` Override 7: "NO SPLIT. QUICKSTART.md stays at root as-is... B's S1 (QUICKSTART SPLIT) commit is DROPPED. project-template/docs/pack/QUICKSTART.md is NOT created. init-project.sh does NOT gain a new install stage for it."

**Issue:** Override 7 explicitly DROPS B's S1 commit. B's §6.2 SPLIT list still names S1 as a Phase 5 commit. B's §6.4 step 5 still names S1. B's §8 final-state tree still shows `project-template/docs/pack/QUICKSTART.md (NEW — project-side half from S1 split)`. A's OQ-4 punts to "verify Architect B addresses F-4" — Architect B's design DOES address F-4, but with SPLIT (which Override 7 forbids). A's framework doesn't carry the Override 7 cascade.

**Why MUST:** Phase 5 coder reading B's design as-is will create the SPLIT files. Override 7 must be reflected in B's design (or in a documented B fix-pass) before Phase 5 spawn, OR Phase 4 planner must carry a flag "drop S1; no project-side QUICKSTART created; B's §6.2 / §6.4 step 5 / §8 tree are obsolete on this point."

**Actor:** Architect B fix-pass (extend B-fix to drop S1 from §6.2/§6.4/§8 and reconcile the validate-pack.py Check 22 surfaces dict — line 1655 stays at `REPO_ROOT / "QUICKSTART.md"`, NO new `project-template/docs/pack/QUICKSTART.md` entry; B's §6.6 explicitly says line 1655 "unchanged" which is consistent — but the surfaces["project-template"]["docs"] addition mentioned in §4.4 must be dropped).

**Fix shape:**
- B-fix: add §11+ entry explicitly amending B's §4.4 / §6.2 (drop S1) / §6.4 step 5 / §8 (drop `QUICKSTART.md` entry from `project-template/docs/pack/` block) per Override 7.
- Drop the surfaces["project-template"]["docs"] addition from `validate-pack.py` Check 22 (§4.4 explicitly mentioned adding it).

---

#### M4 — Architect B's §3 reference to "C2-at-root exemption list (closed set)" is stale post-B-fix; surfaces in C's design too

**Where:**
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §2.1, §3.3, §2.2, §8 — all reference a "3-entry closed set" (BACKLOG.md, CHANGELOG.md, tracker.toml.pack-example).
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §4 (line 109-117): correctly shrinks to 1 entry (only `tracker.toml.pack-example`).
- `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §7 M4 deny-list and §11 conditional surfaces table both reference the closed-set as an allow-list for Check 36 / Check 38 — citing B's 3-entry version implicitly.

**Issue:** B and C both still reference the 3-entry exemption list. B-fix corrects to 1 entry. C consumes the closed-set (via `pack-ops/.boundary-exempt-root.txt`) and operates on the count. If C's regression-test fixtures assume 3 entries, they'll fail post-B-fix.

**Why MUST:** The post-fix `.boundary-exempt-root.txt` has 1 entry, not 3. C's Check 36 / Check 38 allow-list reads this file; any fixture or test asserting "exempt list has N entries" needs to know N=1, not N=3.

**Actor:** Architect C fix-pass (or Phase 4 planner addendum) — ripple the B-fix exemption-list reduction (3 → 1) through C's M4 / M5a / M5b deny-list references and any test-fixture expectations.

**Fix shape:** C-fix surfaces the post-B-fix exemption list as 1-entry; updates any allow-list-count-based assertions accordingly.

---

### SHOULD findings (improvements that should land but don't block Phase 5)

#### S1 — Architect A's OQ-1 V4 cascade subsumption: under Override 6 (`pack-ops/`), the framework still works but assumption rewording needed

**Where:** `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V4 (line 137-160), §5 (line 580-628), OQ-1 (line 711).

**A's framing:** V4 RELOCATE assumes Architect B chooses a "pack-only directory" target for `CONCEPTUAL-REVIEW-METHODOLOGY.md`. A's PRIMARY recommendation is RELOCATE; the conditional fallback paths (KEEP in supporting-docs, REWRITE for project-side) are designed.

**Reality:**
- B's §4.1 (F-1 resolution) chose `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` as the destination.
- User Override 6 explicitly rejects this: "B's 'maintenance-docs/ houses live methodology' reasoning is rejected. Destination is `pack-ops/`."
- A's V4 framework is destination-agnostic ("pack-only directory designated by Architect B") — under Override 6, the destination becomes `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. A's cascade-subsumption logic (all 11 §5 ambiguous-pending refs become LEGITIMATE post-RELOCATE) STILL HOLDS because the destination is still a pack-only directory.

**Why SHOULD (not MUST):** A's framework is correct in spirit; the cascade subsumption survives Override 6 because the operative property is "pack-only directory", not the specific directory choice. But A's specific phrasing "V4 RELOCATE collapses to V4 JUSTIFY (the location is reclassified-correct) under F-1 path A" no longer maps cleanly because B's F-1 path A was `maintenance-docs/` (rejected by Override 6) and the actual destination is `pack-ops/` (a fourth path neither A nor B framed explicitly).

**Actor:** Architect A fix-pass OR Phase 4 planner doc note.

**Fix shape:** A-fix adds an Override 6 cascade note: "V4 RELOCATE destination per Override 6 is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (NOT `maintenance-docs/` per B's §4.1)." Update §5 to name the actual destination. The cascade logic is unchanged.

---

#### S2 — Architect A's OQ-3 OPTIONAL-FEATURES recommendation needs Override 8 reconciliation

**Where:** `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §3.5 D8.6/D8.7 (lines 440-453), §4 A4-A8 cluster (lines 515-565), OQ-3 (line 715).

**A's framing:** "Recommended path for both D8.6 and D8.7: **DUAL-INSTALL OPTIONAL-FEATURES.md.**" A explicitly recommends DUAL-INSTALL (`init-project.sh` installs to client `docs/pack/`).

**B's framing (§4.5):** Same — B recommends SPLIT (option (b)) with pack-side at `pack-ops/` + new project-side at `project-template/docs/pack/OPTIONAL-FEATURES.md`.

**User Override 8:** "**CONFIRMED SPLIT.**" — confirms B's recommended default and explicitly authorizes Phase 5 coder to implement S2.

**Issue:** A and B both default to DUAL-INSTALL/SPLIT, user confirms. But A's framework also has FALLBACK paths (drop the 5 refs, keep pack-only-only) which Override 8 implicitly excludes. A's framework doesn't carry the Override 8 cascade explicitly. Phase 5 coder reading A's §3.5/§4 needs to know "fallback paths are dropped per Override 8."

**Why SHOULD:** A's design is correct; the issue is just that A's "DEPENDS ON F-5 RESOLUTION" framing should collapse to "Override 8 RESOLVES F-5 as DUAL-INSTALL — A4-A8 are all LEGITIMATE post-S2; D8.6/D8.7 REPLACE per S2." No design rework; documentation update.

**Actor:** Architect A fix-pass (small) OR Phase 4 planner doc note.

**Fix shape:** A-fix adds Override 8 cascade note collapsing the conditional D8.6/D8.7 + A4-A8 framings to the SPLIT-confirmed path. The "alternate paths REVERT all 5" fallback drops.

---

#### S3 — `init-project.sh` install stage for project-side OPTIONAL-FEATURES (S2) needs design specificity

**Where:** B's §4.5 + §6.2 + §6.4 step 6 (conditional S2 commit).

**B's framing:** "If (b): pack-root `OPTIONAL-FEATURES.md` moves to `pack-ops/OPTIONAL-FEATURES.md`. A new file `project-template/docs/pack/OPTIONAL-FEATURES.md` is CREATED with project-side-audience content (subset of pack-side, project-targeted). `init-project.sh` gains a stage to install `project-template/docs/pack/OPTIONAL-FEATURES.md` → `<client>/docs/pack/OPTIONAL-FEATURES.md`."

**Issue:** The "subset of pack-side, project-targeted" content split is not designed anywhere. Phase 5 coder receives: "create a new file with project-targeted content" with no concrete guidance on what content stays pack-side, what crosses to project-side, what gets adapted. This is a content-design task masquerading as a mechanical task. Without specificity, the coder will improvise (which is exactly the P-missed-7 anti-pattern this BD is trying to fix).

**Why SHOULD:** Override 8 says "one for pack. one for projects. There may be something common to both and maybe some individual to both. That is OK." — user is comfortable with the coder making content judgments here. But the coder needs a starting structure to avoid TYPE-2 contamination during the split itself (e.g., reflexively copying "pack tracker integration" content into project-side without considering that project-PM-chats consume different surfaces).

**Actor:** Architect B fix-pass OR a small dedicated Architect-B-content design pass before Phase 5.

**Fix shape:** Extend B's §4.5 with a content-split sketch: which sections of current `OPTIONAL-FEATURES.md` stay pack-only (e.g., pack-tracker plumbing, validate-pack Check 22 references) vs ship as project-side feature catalog (e.g., tracker opt-in instructions for project PM chats). 5-10 line outline is sufficient.

---

#### S4 — C's M2 codification cascade for both trinity surfaces needs to honor Override 9 explicitly

**Where:** `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §4 (M2) + §4.2 (project-side mirror).

**C's framing:** §4 codifies P-missed-7 in pack trinity Pack memory. §4.2 designs a "shorter and inverted" project-side mirror for project-template trinity Project memory.

**User Override 9:** "**CONFIRMED.** 'Different audience means different wording is fine.' Two audience-specific rules, not a mirror in the byte-identical-drift sense."

**Issue:** C's design is substantively correct (different wording per audience), but C doesn't explicitly reference Override 9 as the authority. Phase 3 reviewer reading C alone would not know whether the two-trinity codification is a user-confirmed plan or a unilateral architect decision. Override 9 also says "no cross-trinity drift gate needed for this codification (different wording is intentional, not drift)" — C's design implicitly aligns (no Check 18 H2 parity is mentioned for the new bullet) but doesn't explicitly state that Check 18 will treat the new bullet as non-parity-required.

**Why SHOULD:** Code can be implemented per C as-is. The reviewer-trace gap is documentation, not behavioral.

**Actor:** Architect C fix-pass (small).

**Fix shape:** C-fix adds explicit citation: "Per AUDIT-USER-CURATION.md Override 9, the pack-side and project-side P-missed-7 codifications are intentionally different in wording. No Check 18 H2 parity gate applies to the new bullet."

---

#### S5 — C's M2 codification for project-template trinity Project memory does not check against B's directory architecture for references

**Where:** C §4.2 (project-side mirror text, lines 134-147).

**C's project-side mirror text includes:**
```
Files at the pack repo (PACK-AGENTS.md, PACK-CHAT.md, pack-*
agent prompts, pack-repo maintenance-docs/) are NOT part of the
project SSOT and must not be referenced from project files —
the pack repo is not present at this client install.
```

**Issue:** Post-B-fix, the pack-repo files referenced are at NEW paths (`pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/MERGE-STRATEGY.md`, etc.). C's mirror text uses bare filenames for `PACK-AGENTS.md` / `PACK-CHAT.md` (correct for grep regardless of new path) but does NOT name the `pack-ops/` path-prefix as a deny-target. A future project-side file referencing "see pack-repo's `pack-ops/BOUNDARY-DEFINITION.md` for the rules" would not violate C's verbatim text (no listed deny pattern matches), even though it's a TYPE-4 contamination (path doesn't resolve at client install).

**Why SHOULD:** The same M2-deny-list expansion needed for Check 37 (M2 finding in this report) applies to C's project-trinity codification. Easy mechanical addition.

**Actor:** Architect C fix-pass (small).

**Fix shape:** Add to C §4.2 project-side mirror text: `pack-ops/ (any file there)` to the deny-list — matches the symmetric pack-side P-missed-7 expansion.

---

#### S6 — C's M5a Check 36 PM-only keyword definition needs to align with actual PACK-AGENTS.md PM-only list (cascades from B1)

**Where:** C §8.1 M5a Check 36 table (lines 419-424) + §10.2 M1b table.

**C's framing:** "`PM-only` or `pack-memory-only` → Only Pack-Chat-direct-edit surfaces per PACK-AGENTS.md (root trinity, PACK-CHAT.md, PACK-AGENTS.md, root BACKLOG/CHANGELOG, **project-template trinity edits FAIL this gate** — caught V10)"

**Issue:** Cascades from B1 above. The actual `PACK-AGENTS.md:148` lists project-template trinity AS PM-only (root AND project-template/). C's Check 36 PM-only keyword would WRONGLY fail any commit with `PM-only` keyword that touches project-template trinity — flagging correct PM-only commits as violations.

**Why SHOULD (not MUST):** This is downstream of B1. Once B1 fixes the V10 framing, S6 falls out automatically. But if C's M5a/M5b/M1b are implemented as written before B1 is fixed, the Check 36 regression-test fixtures will encode the wrong rule and need re-work.

**Actor:** Architect C fix-pass (cascade from B1 fix).

**Fix shape:** Update C §8.1 + §10.2 + §12 (test plan) to make `PM-only` keyword permit project-template trinity edits per actual PACK-AGENTS.md PM-only list. Drop the parenthetical "caught V10" — V10 was not a real PM-only violation.

---

### NIT findings (cosmetic / polish)

#### N1 — Output filename mismatch between orchestration plan and prompt

**Where:** ORCHESTRATION-PLAN-BD-175.md §5 Phase 3 names output as `PACK-REVIEW-EMERGENCY-DESIGNS.md`. This reviewer's prompt instructs `PACK-REVIEW-PHASE-2-DESIGNS.md`. The prompt is authoritative; this report writes to the prompt-specified path. Future archaeology might miss this if the orchestration plan isn't updated.

**Actor:** Pack Chat (orchestration-plan housekeeping, not architect-level).

**Fix shape:** Update ORCHESTRATION-PLAN-BD-175.md §5 Phase 3 to name the actual output path used.

---

#### N2 — B-fix-pass §10.4 verification step references checks that don't exist yet

**Where:** B-fix §10.4 step 1: "`bash scripts/validate-pack.py` — all 33 checks pass." But Architect C designs Checks 36, 37, 38 (new checks not yet implemented at HEAD). Either the validate-pack.py at the time of Phase 5 has 33 (current count, pre-C) or 36+ (post-C). The hardcoded "33 checks" will drift.

**Actor:** B fix-pass minor edit OR Phase 4 planner doc note.

**Fix shape:** Replace "all 33 checks pass" with "all currently-enabled checks pass" — count-agnostic.

---

#### N3 — A's §2 V8 references `5035328` as origin commit; verify if relevant for any fix-trace

**Where:** A §2 V8 (line 253): "Confirmed pre-v11 origin: introduced by commit `5035328` (v9-dev, 2026-04-12); persisted into v11 by virtue of being present at HEAD."

A surfaces this for completeness. No fix or action attaches to the origin commit (V8 decision is REVERT — drop the italicized paragraph from project trinity). NIT only — confirm the v9-dev origin trace doesn't affect any of the V8 / TASK-T1 sequencing.

**Actor:** No action needed unless planner has a reason to know the origin commit.

**Fix shape:** None; informational note only.

---

#### N4 — B's §4.2 (F-2 retain `project-template/docs/pack/` NAME) reasoning is sound but could surface a deferred rename option

**Where:** B §4.2 (lines 351-371).

**B's design:** Keep the directory name `project-template/docs/pack/` despite the audit's F-2 concern that the name is misleading. Justified by: high rename cost, mitigation via boundary definition discoverability, semantic accuracy (the content IS pack-AUTHORED for project-USE).

**NIT observation:** B's reasoning is sound for v11.0, but the F-2 anti-pattern signal remains real (a new pack contributor reading `project-template/docs/pack/` may still misread the audience). B does not surface a deferred rename as an option for v12 (when a coordinated migrator step could absorb the rename cost).

**Actor:** No action needed for Phase 5; potentially a future BD anchor.

**Fix shape:** None for BD-175. If desired, Pack Chat can open a v12 anchor BD for "evaluate `docs/pack/` rename to `docs/pack-authored/` or similar" — purely optional, not a BD-175 deliverable.

---

## §2 — Cross-architect reconciliation (prompt concerns 1-7)

### Concern 1: A's 6 OQs against B's / C's / user overrides

| OQ | Topic | Reconciliation status |
|---|---|---|
| OQ-1 | CONCEPTUAL-REVIEW-METHODOLOGY placement (V4 RELOCATE) | Cascade SHOULD finding S1: A's V4 assumes "pack-only directory" generically; user Override 6 specifies `pack-ops/`. A's logic survives; documentation note needed. |
| OQ-2 | MERGE-STRATEGY install decision | A's PRIMARY recommendation (pack-only with audience header amendment); B's design moves to `pack-ops/MERGE-STRATEGY.md` per §4.1. Match. No fix needed. |
| OQ-3 | OPTIONAL-FEATURES split | SHOULD S2: A defers to F-5; user Override 8 RESOLVES to SPLIT. A's framework still valid; documentation note needed. |
| OQ-4 | QUICKSTART | MUST M3: A punts to B; B designs SPLIT (S1); user Override 7 DROPS S1. B needs fix-pass to drop S1 from its design. |
| OQ-5 | T5-A alignment with C's trinity-structure design | A's T5-A is the inline-enumeration removal; C's M2 is the P-missed-7 codification — orthogonal. C's M8 trinity-rule-clarification (line 568-580) is INFORMATIONAL not enforced, so no conflict with A's T5-A. No fix needed. |
| OQ-6 | V10 hunk-audit yield | BLOCKER B1: V10 framing is wrong; project-template trinity IS PM-only per `CLAUDE.md:337-338` + `PACK-AGENTS.md:148`. V10 collapses to NO-ACTION; cascade to C's M1a/M1b/M5a. |

### Concern 2: B + B-fix-pass integration

**B-fix correctly folds M9/M10 into B's M1-M5 commit (Option A).** Verified:
- B-fix §7.1 enumerates the combined commit's scope (7 `git mv` + scripts/lib/tracker-config.sh + scripts/lib/detect.sh + validate-pack.py STREAMS+Check3+Check22+Check24+Check32+Check35 + scripts/lib/per-entry/_lib.sh + scripts/lib/recommendation.sh + scripts/lib/tracker-doctor.sh + scripts/lib/tracker-agent-read.sh + scripts/lib/tracker-migrate-reverse.sh + scripts/tests/test-per-entry.sh + pack-side trinity + pack-* agents + pack-startup skill + README repo-layout + RC9 manifest regen).
- RC9 manifest regen requirement honored explicitly (B's §6.7 + B-fix's §10.3 closing).
- Trinity rule (Check 18) honored implicitly (all three CLI variants edited in lockstep per B's §6.5 + B-fix's §10.3).

**The new detect.sh:31-51 constraint is correctly surfaced as a same-commit update (B-fix §6.2 + §8.3 + §10.3).** B's original §3.2 incorrectly claimed `detect_pack_surface` was unaffected (M1 finding above). B-fix correctly catches this.

### Concern 3: C depends on B's directory architecture (M5a/M5b/M5c implementation surfaces)

| Mechanism | Specifiable given B's design? | Status |
|---|---|---|
| M5a Check 36 PERMITTED-PATHS regex | YES — `project-template/`, `supporting-docs/`, plus post-B-fix `pack-ops/` as pack-only path-prefix | Specifiable; but BLOCKER B1 requires PM-only keyword permitted-paths to include project-template trinity |
| M5b Check 37 project-side deny-list | YES — bare-filename patterns work post-relocation; path-prefixes need `pack-ops/` addition (MUST M2) | Specifiable with M2 fix |
| M5c Check 38 pack-only-file siting | YES — but `supporting-docs/` becomes clean PROJECT × PRODUCT post-B's M6-M8, so Check 38 baseline-flag count drops; threshold needs re-derivation | Specifiable; threshold tuning is planner-pass concern |

### Concern 4: C's M2 codification preserves B's trinity placements

C's M2 codifies P-missed-7 in BOTH pack-root trinity Pack memory AND project-template trinity Project memory (per Override 9). B's directory architecture does NOT touch trinity placements — pack trinity stays at root (C3 TOOL-CONFIG); project-template trinity stays at `project-template/` root (C6 TOOL-CONFIG). Compatible.

Verified: B's §2 row 6 (CLAUDE.md), row 7 (GEMINI.md), row 3 (AGENTS.md) all C3 STAYS at root. B's §1.1 C6 maps project-template trinity to `project-template/` root. C's M2 codification surfaces (pack trinity + project trinity) are both untouched by B. No conflict.

### Concern 5: User curation overrides honored

| Override | Topic | Honored by | Status |
|---|---|---|---|
| 1 | `tracker.toml.pack-example` STAYS | B §2 row 16; B-fix §4 | Honored |
| 2 | Root `.github/` PACK-ONLY | B §1.3 Challenge 5 + §2 row 20 | Honored |
| 3 | Drop F-3 from SHARED catalog | B §4.3 | Honored |
| 4 | Drop F-7 from SHARED catalog | B §4.7 | Honored |
| 5 | BACKLOG.md / CHANGELOG.md MOVE | B-fix §2.4 + §3 + §5 + §9 | Honored |
| 6 | CONCEPTUAL-REVIEW-METHODOLOGY → `pack-ops/` | NOT honored by B (B chose `maintenance-docs/`); A's V4 framework is destination-agnostic | SHOULD S1 — needs Architect B fix-pass to honor Override 6 explicitly, OR documented planner override |
| 7 | QUICKSTART NO SPLIT | NOT honored by B (B designed S1 split) | MUST M3 — needs B fix-pass to drop S1 |
| 8 | OPTIONAL-FEATURES SPLIT confirmed | Honored by B's §4.5 default; A's D8.6/D8.7 cascade aligns | SHOULD S2 — A's documentation needs Override 8 cascade note |
| 9 | C's M2 two-tier codification confirmed | Honored by C's §4 + §4.2 (without explicit Override 9 citation) | SHOULD S4 — C-fix adds citation |

**Net override honor status:** 5 of 9 honored cleanly; 4 of 9 need fix-pass (S1 documentation, M3 B-fix-pass for QUICKSTART, S2 A documentation, S4 C documentation; Override 6 is an architect-level disagreement that needs explicit reconciliation).

**Override 6 (`pack-ops/` vs `maintenance-docs/`) needs special attention.** B's §4.1 rationale for `maintenance-docs/` (CONCEPTUAL-REVIEW-METHODOLOGY is methodology siblings to TOOL-COMPARISON.md, RECOMMENDATIONS.md) is internally consistent. User Override 6 rejects this with a different placement framing (consult user direction itself). The architecture is correct in spirit (RELOCATE to a pack-only dir) regardless of which pack-only dir; the user's explicit choice wins.

### Concern 6: Cross-architect non-overlap

| Architect | Designed in own domain | Encroached on others? |
|---|---|---|
| A (re-litigation) | Per-finding decisions (REVERT/REPLACE/RELOCATE/JUSTIFY/DUAL-INSTALL/SPLIT) for 13 §C + 17 §D + 8 ambiguous + 11 ambiguous-pending findings; cascade subsumption to 8 tasks | No directory design (defers to B with explicit "[B's domain]" markers throughout); no CI/agent-guardrail design (defers to C); no boundary-definition design (treats user §5 as authority). Clean. |
| B (directory + boundary) | G7 boundary definition; SC8 discoverability; G2 directory architecture (`pack-ops/` + SHARED resolutions); path-reference update strategy | Mentions "Architect A re-litigates" for content decisions; mentions "Architect C designs the gate" for CI. Does NOT design re-litigation content or CI gates. Clean. |
| C (prevention) | M1-M8 mechanisms; codification surfaces; CI checks; agent prompts; reviewer protocol amendments; trinity-rule clarification (informational, NOT enforced) | Explicitly NOT-read: A's and B's outputs (per prompt). Conditional dependencies on B surfaced in §11 + §14. Clean. |
| B-fix | Narrow corrective for BACKLOG/CHANGELOG placement | Does NOT relitigate B's boundary work (correctly preserves C2 classification, just flips placement). Does NOT extend to A's or C's domains. Clean. |

**Cross-architect non-overlap verdict: clean.** Each architect stayed in their assigned domain. The one edge case is B's §7 ("Architectural facts that bear on Architect A and Architect C") which surfaces facts without designing — appropriate boundary discipline.

### Concern 7: G/SC coverage

| Goal/SC | Designed by | Status |
|---|---|---|
| G1 (classification) | B's §2 + §3 + §4 (classifies every root file + every directory + SHARED resolutions per category) | Covered |
| G2 (directory re-arch / eliminate shared) | B's §3 + §4 + B-fix §3 | Covered |
| G3 (full v11 audit) | Phase 1 deliverable; A/B/C/B-fix all reference it | Covered (Phase 1, not Phase 2) |
| G4 (re-litigation not blind revert) | A's per-finding framework | Covered |
| G5 (project-side HEAD integrity) | A's REVERT/REPLACE actions per finding | Covered |
| G6 (structural prevention) | C's M1-M8 mechanisms | Covered |
| G7 (boundary definition) | B's §1 (two-axis matrix) | Covered |
| SC1 (classification doc exists) | B's §1 + planned `pack-ops/BOUNDARY-DEFINITION.md` | Covered |
| SC2 (audit report exists) | Phase 1 deliverable | Covered |
| SC3 (violations re-litigated) | A's framework + Phase 5 coder | Covered (design level; Phase 5 implementation) |
| SC4 (project-side HEAD clean) | A's REVERT/REPLACE + Phase 5 verification | Covered (design level) |
| SC5 (prevention deployed) | C's M1-M8 + CI checks | Covered |
| SC6 (19c resumes clean) | Out of Phase 2 scope (Phase 7 of orchestration) | Covered (design defers correctly) |
| SC7 (directory architecture deployed) | B + B-fix | Covered |
| SC8 (boundary def discoverable) | B's §5 (`pack-ops/BOUNDARY-DEFINITION.md` + cross-ref network) | Covered |

**No uncovered G/SC.**

### Concern 8: Meta-check — architect designs don't themselves contain pack-bias contamination

**Verified:** Each architect's design correctly distinguishes pack-side from project-side surfaces.

- **A's framework** correctly identifies project-side SSOTs (PM-CHAT.md §47, PLATFORM-SKILLS.md as project-side surfaces) and proposes REPLACE patterns that cite project-side SSOTs rather than pack-only refs. Boundary discipline applied internally.
- **B's design** correctly maps the six categories (C1-C6) and places every file via the audience-context check (B §1.3 Challenge 1). The PROJECT × OPERATIONS category (C5) is the structural answer to the V1-style contamination — explicitly named and defended.
- **C's design** explicitly defers TYPE-5 detection to a positive-assertion reviewer gate (no false claim of mechanical detectability). The deny-list explicitly distinguishes capitalized `Pack Chat` (orchestrator role — contamination) from lower-case `pack chat` (feedback flow — legitimate) per audit §D-4. The boundary-investigation skill text in §6 worked example references the V1 anti-pattern correctly.
- **B-fix** correctly identifies BACKLOG/CHANGELOG as C2 (PACK × OPERATIONS) and applies the same MOVE pattern as B's M1-M5 — symmetric treatment.

**No pack-bias contamination patterns surface in the architect designs.** The cure does not contain the disease.

---

## §3 — Independence + reviewer-trace verification

This reviewer is a fresh agent (not A, B, C, or B-fix). No prior PACK-REVIEW-*.md docs for BD-175 were read. The review is based on the inputs listed in the front-matter; no inherited framing from earlier review cycles.

This reviewer did NOT design solutions — findings name problems and actors (who should fix), not proposed fix prose. Fix-shape notes are concrete enough to enable an architect-fix-pass or planner-doc-note to execute mechanically.

---

## §4 — Action summary for Pack Chat triage

Pack Chat should triage each finding with the user as fix-or-defer per pack-memory triage rules. Default per pack-memory is FIX. Recommended triage:

| Finding | Severity | Actor | Recommended action |
|---|---|---|---|
| B1 | BLOCKER | Architect A fix-pass + Architect C fix-pass | FIX before Phase 4 planner spawn — V10 collapses to NO-ACTION; C's M1a/M1b/M5a PM-only definitions correct per actual PACK-AGENTS.md:148 |
| M1 | MUST | Phase 4 planner | FIX as planner constraint — enforce Option A (combined M1-M5 + M9-M10 single commit) |
| M2 | MUST | Architect C fix-pass | FIX — add `pack-ops/` to Check 37 deny-list path-prefix entries |
| M3 | MUST | Architect B fix-pass | FIX — extend B-fix to drop S1 per Override 7; reconcile §4.4 / §6.2 / §6.4 step 5 / §8 / validate-pack.py Check 22 surfaces |
| M4 | MUST | Architect C fix-pass | FIX — ripple B-fix's exemption list reduction (3 → 1) through C's M4/M5a/M5b |
| S1 | SHOULD | Architect A fix-pass | FIX (small) — Override 6 cascade note for V4 destination |
| S2 | SHOULD | Architect A fix-pass | FIX (small) — Override 8 cascade note for D8.6/D8.7 + A4-A8 |
| S3 | SHOULD | Architect B fix-pass | FIX — extend B-fix with project-side OPTIONAL-FEATURES content-split sketch |
| S4 | SHOULD | Architect C fix-pass | FIX (small) — Override 9 citation for §4 + §4.2 |
| S5 | SHOULD | Architect C fix-pass | FIX (small) — add `pack-ops/` to §4.2 project-side mirror deny-list |
| S6 | SHOULD | Architect C fix-pass | FIX — cascades from B1; align PM-only keyword definition |
| N1 | NIT | Pack Chat | Optional — update ORCHESTRATION-PLAN-BD-175.md §5 to name actual output path |
| N2 | NIT | Architect B fix-pass | Optional — "all 33 checks" → "all currently-enabled checks" |
| N3 | NIT | (none) | No action |
| N4 | NIT | (none for BD-175) | Optional v12 BD anchor |

**Suggested fix-pass batching for efficiency:**
- **Single Architect A fix-pass** addresses B1 + S1 + S2 (all small documentation updates to A's framework).
- **Single Architect B fix-pass** (extension of existing B-fix) addresses M3 + S3 + N2 (B-fix-pass extension for Override 7 drop + content-split sketch + check-count adjustment).
- **Single Architect C fix-pass** addresses B1 cascade + M2 + M4 + S4 + S5 + S6 (PM-only keyword definition + deny-list expansion + exemption-count + Override 9 citation + project-side mirror deny-list).
- **Pack Chat orchestration housekeeping** addresses N1 (small ORCHESTRATION-PLAN update).
- **N3, N4** are no-action.

After fix-passes land, Phase 3 reviewer (this reviewer, or a fresh one — per pack-memory the same reviewer can re-verify their own findings post-fix) confirms the fixes resolve the findings. Then Phase 4 planner spawn.

---

## §5 — Open questions surfaced for user reconciliation

None. All findings have a clear fix path; no open architect-level questions remain after these findings are addressed.

---

## §6 — Reviewer self-check

Per the prompt's success criteria:

1. **All 6 of A's OQs reconciled.** Yes — §2 Concern 1 table.
2. **B + B-fix integration verified.** Yes — §2 Concern 2.
3. **C's M5a/M5b/M5c specifiability against B.** Yes — §2 Concern 3.
4. **C's M2 + B's trinity placements compatible.** Yes — §2 Concern 4.
5. **9 user overrides verified honored.** Yes — §2 Concern 5; 5 honored cleanly; 4 need fix-pass (surfaced as findings).
6. **Cross-architect non-overlap verified.** Yes — §2 Concern 6.
7. **G/SC coverage verified.** Yes — §2 Concern 7; no uncovered.
8. **Meta-check (no pack-bias in designs themselves).** Yes — §2 Concern 8.
9. **Findings tagged with severity + actor.** Yes — §1 + §4 summary.
10. **Output is markdown only.** Yes.
11. **PREFLIGHT line emitted.** Yes (before this write).

---

## §7 — End of review

Phase 3 reviewer pass complete. 15 findings (1 BLOCKER + 4 MUST + 6 SHOULD + 4 NIT) for triage by Pack Chat with user. Recommended path: 3 small fix-passes (A, B-extension, C) + 1 orchestration-doc update; then Phase 4 planner spawn.

The four Phase 2 architect designs are substantively correct and internally consistent on the major axes (boundary definition, directory architecture, prevention layering, re-litigation framework). The findings here are integration / Override-cascade / deny-list-completeness gaps, not fundamental design defects. None of the findings recommend re-architecting any of the four designs; all are addressable via small fix-passes or planner-doc-notes.
