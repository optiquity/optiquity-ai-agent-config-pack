# PLAN-BD-239 — implementation plan for the PROJECT-SIDE large-PHASE development pipeline standard (size-tiered)

**Role:** pack-planner (RO). I sequence the approved reconciled design — I do NOT redesign. **BD:** BD-239 (LARGE — runs the full pipeline; this plan goes through an ADVERSARIAL planner review next). **Input:** `DESIGN-BD-239-RECONCILED.md` (the design to sequence), `BD-239.md` (the spec), `ADVERSARIAL-REVIEW-BD-239.md` (context). **Output:** this plan only (sole Write, under `/tmp`). **Next stage:** adversarial planner review → user planner-to-coder gate → pack-coder.

This plan carries the FULL coder-ready sequencing so a coder implements with ZERO open design questions. Every NEW state-claim (beyond the design's verified claims) is backed by an Empirical-Evidence Block (§12), re-measured by me at the CURRENT HEAD. One design claim is CORRECTED on evidence: the manifest is NOT a NOOP (§9, EB-P1/EB-P2) — BD-239's entire edit-set is fixture inputs.

---

## 0. Runtime regime (RO; verified by me)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `d720873b6010a4059a2ebb919070ef85b7d2d5c6` |
| branch | `v11-dev` |
| `git status --short` | clean (the work I plan is design-stage; RO placement = this main checkout) |
| graph | DISCOVERY queried (`graphify query … --graph /Users/.../graphify-out/graph.json --backend claude-cli --budget 1500`); returned maintenance-doc review nodes only (operating-doc rule bodies are not node-indexed at rule granularity) → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/anchor reads). |
| writes | EXACTLY ONE: this plan at `/tmp/pack-handoff-bd239-plan/PLAN-BD-239.md`. No source edits. Read-only git only. No memory store read/written (MEMORY PROHIBITION 2026-06-23 honored). |

**HEAD drift note:** the reconciled design measured at HEAD `3d1cf34`; I re-measured every load-bearing anchor at the CURRENT HEAD `d720873`. All design anchors hold (trinity section still `## Project memory`; cap still 700; L390 allowlist record present; PM-CHAT anchor regions + memory passages unchanged; groupings grep-zero; Option A = 688 code points). ONE design conclusion is CORRECTED: the manifest claim (§9).

---

## 1. Goal + BD scope addressed

**Goal:** codify the project-side large-PHASE development pipeline as ONE official, size-tiered standard — the full chain (optional internal/external researcher(s) → architect → adversarial architect review → reconciliation → user design review → planner → adversarial planner review → reconciliation → user planner-to-coder gate → parallel worktree coder waves → OPTIONAL post-implementation audit), keyed on PHASES, in project vocabulary only, shipped to clients. The two adversarial reviews + reconciliation are the MINIMUM for a LARGE phase and OPTIONAL at developer election for a SMALL phase.

**BD-239 acceptance criteria → where this plan addresses each:**

| BD-239 acceptance clause | Addressed by |
|---|---|
| ONE official, size-tiered standard (full chain incl. optional researcher first step + large/small-PHASE criterion + adversarial-as-min-for-large/optional-for-small + reconciliation + parallel-worktree coder waves) | C1 (METHODOLOGY body, §4.1) — the full 9-stage chain + the two-part 5-signal criterion |
| lives in project-side SSOT surfaces (METHODOLOGY.md / PM-CHAT.md / project trinity) and ships to clients | C1 (METHODOLOGY) + C2 (trinity ×3 + PM-CHAT anchor) — §4.1–§4.3; all are fixture inputs (§9) so they ship |
| uses ONLY project vocabulary (phases, phase tasks, TD backlog, groupings, project agents); NO pack work-item references leak | PREFLIGHT-VOCAB (§6) — the purity grep gate; groupings OMITTED (§5.2) |
| consistent with the pack-side companion standard's pipeline shape | C1 — the design's 9-stage chain mirrors BD-238's shape with the 5 justified roster divergences (design §5) |
| `validate-pack` green | PREFLIGHT (§6) — validate-pack default + DEEP, validate-docs self-test, full battery |
| architect-designed (not PM-chat-authored) | satisfied upstream: architect → adversarial → reconciliation done; this plan + the coder implement mechanically |

**No BD item is partially addressed.** Wrinkle C = option (b) (BD-239 lands FIRST under `## Project memory`; queue NOT reordered) is encoded as a sequencing choice + a hard hand-off note to BD-245 (§5.3) — NOT a deferral. The zero-CLI-memory constraint is encoded as PREFLIGHT-7 (§6).

---

## 2. Affected files — the COMPLETE list (enumerate-encoding-surfaces)

Every surface BD-239 touches, every surface that ENCODES its expected state (gates/allowlist), and every cross-reference surface. Sourced from design §6/§9 + my re-measurement.

### 2.1 Files EDITED (the edit-set)

| # | File | Edit | Mandatory? | Commit |
|---|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | NEW Part-5 subsection: the 9-stage chain + the 5-signal size criterion (the SSOT body) | MANDATORY | C1 |
| 2 | `project-template/CLAUDE.md` | insert the §4.2 trinity pointer bullet under `## Project memory` (byte-identical ×3) | MANDATORY | C1 |
| 3 | `project-template/AGENTS.md` | SAME byte-identical bullet | MANDATORY | C1 |
| 4 | `project-template/GEMINI.md` | SAME byte-identical bullet | MANDATORY | C1 |
| 5 | `project-template/docs/pack/PM-CHAT.md` | consolidating anchor (execution-half region ~L513) + one-line roster/behavioral pointer (~L47–300) | MANDATORY | C1 |
| 6 | `project-template/skills/architecture-review/SKILL.md` | one-line "loaded by the standard's adversarial architect stage" pointer | ELECTIVE (recommended; planner may drop) | C1 |
| 7 | `project-template/skills/planning/SKILL.md` | one-line "loaded by the standard's adversarial planner stage" pointer | ELECTIVE (recommended; planner may drop) | C1 |
| 8 | `maintenance-docs/v11-implementation/` | MOVE the BD-239 pipeline docs (`/tmp/pack-handoff-bd239-arch/*` + `/tmp/pack-handoff-bd239-plan/*`) into the implementation-record area (report-preservation) | MANDATORY | C2 (paired pack-only) |

### 2.2 Surfaces that ENCODE BD-239's expected state but are NOT edited (the gates / allowlist)

| Surface | Why it matters | BD-239 action |
|---|---|---|
| `project-template/scripts/validate-docs.sh` | the shipped client gate (HISTORY/DEFERRED/BLOAT/DANGLING axes); finds the trinity section by the literal `## Project memory`; caps bullets at 700 code points | NOT edited (renaming its `## Project memory` literal is BD-245's job, §5.3). The coder RUNS it (PREFLIGHT). |
| `project-template/scripts/.docs-gate-allowlist.txt` (L390 `target: docs/pack/METHODOLOGY.md`) | DANGLING-axis allowlist; the EXISTING record covers the qualified METHODOLOGY cite | NOT edited (the existing record suffices; EB-P5). The coder confirms the cite is byte-identical to it. |
| `scripts/validate-pack.py` Check 18 | trinity H2-structure parity at project-template (auto-satisfied — no new H2) | NOT edited; the coder runs validate-pack. |
| `scripts/lib/manifest-inputs.sh` (`manifest_path_is_input`) | the SINGLE source of truth for the fixture-input predicate; ALL BD-239 edit paths match it (EB-P1) | NOT edited; informs the manifest expectation (§9). |
| `test-fixtures/manifest.txt` | per-fixture SHA manifest; BD-239 edits ARE fixture inputs → SHAs change → push-time regen (NOT a NOOP — corrects the design, §9) | NOT edited by the coder; the orchestrator runs `manifest-sync.sh` at push (§9). |

### 2.3 Surfaces explicitly NOT touched (design §6.5)

- The 16 agent defs ×3 families (0 mandatory; pipeline-stage refs not added to agent defs).
- 35 of 37 skills (only the 2 adversarial-stage skills get the elective pointer).
- `project-template/docs/project/*/_rules.md` (phase/TD vocabulary contracts — referenced, not changed).
- `project-template/docs/project/` groupings — does not exist (EB-P3); NOT created.
- The CLI-memory-endorsement passages: `PM-CHAT.md` L889-891 ("Per-project Claude memory cache (Claude-only)") + L981-984 ("### Cross-session memory" → `~/.gemini/GEMINI.md`); `GEMINI.md` cross-session; `CLI-PM-SETUP.md`. NOT touched — BD-245 strips them (PREFLIGHT-7, §6).
- Any pack-side operating surface (`pack-ops/`, pack-root trinity, PACK-CHAT.md, PACK-AGENTS.md). ZERO pack surfaces.

---

## 3. Commit sequence + rule-10 parallel/dependency map

### 3.1 The commits

| Commit | Scope | Files | Scope keyword |
|---|---|---|---|
| **C1** | the standard itself (SSOT body + pointers) | METHODOLOGY + trinity ×3 + PM-CHAT anchor/pointer + (elective) 2 skill pointers | `project-only` (§7) |
| **C2** | audit-set preservation | `/tmp/pack-handoff-bd239-arch/*` + `/tmp/pack-handoff-bd239-plan/*` → `maintenance-docs/v11-implementation/` | `pack-only` (maintenance record) |

### 3.2 Rule-10 verdict — SERIAL, ONE coder commit (C1), then C2

**RECOMMENDED: C1 is ONE serial coder commit (METHODOLOGY + trinity ×3 + PM-CHAT + the 2 elective skill pointers combined); C2 is the paired audit-set preservation commit AFTER C1 lands.** The design (§10.2) reached this verdict; I confirm it and re-state the binding reasons:

1. **Cross-reference atomicity (the binding reason).** The trinity bullet + the PM-CHAT anchor POINT AT the METHODOLOGY section; the METHODOLOGY section is the SSOT the pointers resolve to. Splitting them across commits leaves an intermediate commit carrying a half-applied cross-reference (pointers without target, or target without pointers) that the validate-docs DANGLING axis would flag on the qualified PM-CHAT cite. ONE commit means the committed state never carries a dangling cross-reference (clean per-commit audit).
2. **The trinity ×3 is one byte-identical unit** (the trinity rule). That sub-unit cannot be split across commits.
3. **No parallel payoff at this size.** The total edit is small (one METHODOLOGY subsection + one trinity bullet ×3 + 2 short PM-CHAT anchors + 2 elective one-line skill pointers). Parallel worktree waves pay off for MULTI-task implementation phases, not a docs-codification BD. The orchestration cost exceeds the benefit.

**Parallel-vs-serial confirmation (rule 10):** the edit-sets are file-disjoint (METHODOLOGY ≠ trinity ≠ PM-CHAT ≠ skills) and COULD run as concurrent worktree waves, but the three reasons above make SERIAL-one-commit correct. There is NO same-file collision inside C1 (each file is touched once). C1 → C2 is strictly serial (C2 preserves the docs only after C1's content lands).

**If the user/planner-review prefers separate commits** (e.g. land METHODOLOGY first for review): C1a (METHODOLOGY) → C1b (trinity + PM-CHAT pointers) is CI-safe ONLY if both land in the SAME push (CI is push-time end-state, EB-P6); the intermediate C1a-only or C1b-only commit would carry a transient dangling cite. The RECOMMENDED single C1 avoids the transient entirely. The plan defaults to single-C1.

### 3.3 Worktree lifecycle (Claude-only)

- The C1 coder is the FIRST (and only) RW coder for C1 → CREATES the isolated worktree (Agent-tool `isolation:"worktree"`, base `worktree.baseRef:"head"`). Any fix-coder in C1's review/fix cycle REUSES that worktree (never a new one). Teardown ONLY after C1 is CONFIRMED landed (exit 0); a failed/aborted commit KEEPS the worktree.
- C2's doc-move coder is a FRESH coder (per-commit fresh-coder). Pack Chat applies the live-worktree ASK gate if C1's worktree is still live when C2 spawns.
- The entire C1 review/fix cycle runs INSIDE the C1 worktree; the patch is produced only AFTER the reviewer confirms CLEAN (Pack Chat SendMessage-s the most-recent RW agent for `git diff > <handoff>/changes.patch`); the orchestrator applies + commits (user approval). Agents never commit.

### 3.4 Concurrency vs other BDs

- **vs BD-238 (pack-side):** edit-sets DISJOINT (project-side vs pack-side; distinct trinity inodes). No collision; any landing order. Scheduling observation, not a BD-239 dependency.
- **vs BD-245 (project-side, SAME files):** BD-239 lands FIRST (user wrinkle-C = (b)); BD-245 later renames `## Project memory` → `## Project rules` + strips the CLI-memory passages, re-sweeping BD-239's three additive surfaces per the §5.3 hand-off note. A SEQUENCING coordination, not a conflict (BD-239's additions are byte-clean at its landing).

---

## 4. File-by-file edits with exact anchors (text anchors, not line numbers)

The coder authors prose from these REQUIRED elements. The SHAPE is fixed by the design; exact prose-wording within the constraints is the coder's mechanical call.

### 4.1 C1 file 1 — `supporting-docs/METHODOLOGY.md` (the SSOT body; MANDATORY)

**Anchor (placement):** a NEW sub-section in **Part 5 — Standard Workflows**, positioned AFTER Workflow 4 (the fix cycle) and BEFORE Workflow 5 (the audit). Text anchors: insert after the end of the `### Planner trigger rule` / Workflow 4 fix-cycle block, before the `### Audit` / Workflow 5 heading. (The Planner-trigger threshold "more than ~5 tasks, or … non-linear" is the P5 source — confirm it is present and unchanged; EB-P7.) Suggested title: `### Workflow 4.5 — Large-phase development pipeline (size-tiered)` OR `### The large-phase pipeline standard` (the exact title is the coder's mechanical call; the position + content are fixed).

**REQUIRED content (project vocabulary only — phases / phase-tasks / TD backlog / project agents; NO BD/backlog-item/pack-* tokens; NO memory-feature endorsement):**

1. **The full 9-stage chain** (design §4.1), in order:
   1. Optional researcher set FIRST (INTERNAL `docs-researcher` = codebase/docs inventory + blast-radius census; EXTERNAL `docs-researcher` = CLI/tool/framework/API docs verified against authoritative sources). Per-need at ANY phase size. `docs-researcher` is the only role reuse-OK for reconciliation (factual inventory).
   2. `architect` → phase design INCLUDING the REQUIRED parallel/dependency map (which phase tasks run in parallel isolated worktrees vs serial) + the rejected-alternative documentation (the existing Part-3 architect rule). The architect REFINES the large/small classification.
   3. Adversarial architect review (fresh, clean-context `architect`; loads the `architecture-review` skill — divergence D1) → PM-chat triage → [reconciliation architect — FRESH, only if NEEDS-REWORK]; loop until READY. Governed by the existing `Reconciliation-instance independence` trinity rule.
   4. User design review (the design gate).
   5. `planner` → implementation-ready plan (the IMPLEMENTATION-PLAN.md Phase-N task block, or a multi-part phase split) INCLUDING its OWN parallel/dependency map.
   6. Adversarial planner review (fresh `planner`; loads the `planning` skill — D1) → triage → [reconciliation planner — FRESH, only if NEEDS-REWORK].
   7. User planner-to-coder gate.
   8. Parallel worktree `coder` waves off the parallel/dependency map: disjoint-file phase tasks run as concurrent coders, each in its own isolated worktree; same-file ⇒ serialize. Each commit's bounded review/fix cycle (the existing Workflow 4 fix cycle — Trigger A/B architect + Trigger P-A/P-C planner mid-cycle escalations + the cycle-termination invariant) runs IN its worktree; the patch is produced only after review-clean; patches apply to the canonical tree SEQUENTIALLY (atomic per patch) with the conflict protocol (STOP + re-spawn fresh, never hand-merge). Superseded design/plan docs DELETED as the pipeline iterates; the audit set preserved into the implementation-record area.
   9. OPTIONAL post-implementation audit (large PHASE, user-elective) — the `auditor` parent + its 7 read-only cluster subagents (Workflow 5 / Part 6), after a large multi-task phase lands (divergence D2).
   - State the two adversarial passes (3 + 6) are the MINIMUM for a large PHASE; ADDITIONAL architect/planner rounds on larger gaps.
2. **The two-part size criterion** (design §4.2):
   - Five PHASE-size signals (each a yes/no test): **P1 launch/release-gate**, **P2 cross-surface** (edit-set spans ≥2 of: app/source modules · gRPC/proto schema · public API/contract · build/CI/deploy config · test infrastructure · architecture docs), **P3 blast-radius** (changes a contract/schema/interface ≥3 surfaces depend on — the load-bearing test; a required docs-researcher census is a tie-break HINT only, not co-equal — n1 fold-in), **P4 structural** (NEW architectural pattern/boundary, schema migration, new external integration, or new module/subsystem — not a localized in-module change), **P5 task-count/non-linear deps** (more than ~5 tasks OR non-linear intra-phase deps — reusing the EXISTING planner-trigger threshold, D3).
   - The CONSEQUENCE rule: a phase is **LARGE** (the two adversarial reviews + reconciliation are the MINIMUM) iff **P1 fires alone, OR ≥2 of the five signals fire**; otherwise **SMALL** (base flow: optional researcher → architect → planner per the existing trigger → parallel coder waves + the bounded review/fix cycle; the two adversarial passes + reconciliation OPTIONAL at developer election). **Tie-break: when in doubt, treat as LARGE.**
   - **Why P1 stands alone:** a release blocker is the one axis where a missed adversarial pass ships into the release irrecoverably; every other signal alone is recoverable at base-flow rigor.
3. **WHO classifies** (design §4.4, n2 fold-in): the PM chat applies the size criterion at the PHASE GATE (the same place the existing planner-trigger check runs, Procedure 1) using the five mechanical signals; the architect REFINES the classification if spawned (may escalate SMALL→LARGE; tie-break-to-LARGE governs ambiguity).
4. **Complementarity statement** (D4): the up-front size tier and the existing mid-cycle situational triggers (architect A/B, planner P-A/P-C, tester) COEXIST — the standard adds the up-front tier; it does NOT replace the mid-cycle triggers.
5. **Cross-references (NOT restatements):** to the execution half in `docs/pack/PM-CHAT.md` (the "Merge-back / worktree" region) for stage 8; the existing Trigger A/B + P-A/P-C + tester triggers (D4); the `architecture-review` + `planning` skills (D1); Workflow 5 / Part 6 audit (stage 9, D2); the governing trinity reconciliation rule (stages 3, 6).
6. **The escalation detail** ("additional architect/planner rounds on larger gaps").

**HARD content constraints on the METHODOLOGY subsection:**
- ZERO history/dates/SHAs/provenance (the validate-docs HISTORY axis). ZERO deferred-feature/version phrasing (the DEFERRED axis — note "groupings" is grep-zero-OMITTED, §5.2; do NOT name it). This is an operating doc — state only what currently operates.
- **M2 coupling-minimization (the trinity-rule reference):** when the subsection points the reader at the governing trinity rule, REFERENCE IT BY CONCEPT ("the governing trinity rule") rather than the literal section name "`## Project memory`" wherever practical — to keep BD-245's rename re-sweep minimal (§5.3). If a literal section-name reference is unavoidable, it is in BD-245's hand-off census.

### 4.2 C1 files 2-4 — the trinity pointer bullet ×3 (MANDATORY; CURRENT `## Project memory` name)

**Anchor (placement):** insert the new bullet as the LAST bullet under `## Project memory`, AFTER the `**Reconciliation-instance independence.**` bullet and BEFORE the next H2 `## Phase routing — default agent assignments`. (Verified insertion point in all three files; EB-P4.) Byte-identical in `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`.

**The bullet text (design §7.2 Option A — RECOMMENDED; 688 code points ≤ 700):**

```
- **Large-phase pipeline standard (size-tiered).** Large phases run the
  full development pipeline (optional researcher(s) → architect →
  adversarial architect review → reconciliation → design review → planner
  → adversarial planner review → reconciliation → planner-to-coder gate →
  parallel worktree coder waves) as the default; the two adversarial
  reviews + reconciliation are the MINIMUM for a large phase and OPTIONAL
  at developer election for a small phase. A phase is LARGE if it is
  release-gating, or if ≥2 of {cross-surface, blast-radius, structural,
  >5-tasks/non-linear} hold; else small. When in doubt, large. The full
  chain, the size criterion, and the stages live in METHODOLOGY.
```

**TWO HARD CODER CAUTIONS (carry into PREFLIGHT-2):**
1. **THIN MARGIN (12 chars).** Measured: 688 code points, 12 chars of headroom (EB-P8). ANY wording addition risks crossing 700. If the final wording adds ANY detail, switch to **Option B** (split into two ≤700 bullets: (1) the pipeline pointer, (2) the size-tiering test). Option A is preferred (terser) but has almost no headroom.
2. **CODE-POINT, not BYTE, measure (the `wc -c` trap).** The same text is **708 BYTES** in UTF-8 — the 9 `→` arrows + 1 `≥` are multi-byte (EB-P8). The gate measures CODE POINTS (`len()` on a utf-8-DECODED `str`), NOT bytes. A `wc -c` measure would FALSELY report 708 > 700 and reject a passing bullet. The coder MUST replicate the gate's collapse (`" ".join(x.strip() for x in cur)` then `len()`), NEVER `wc -c`. OPTIONAL: the coder MAY substitute ASCII `->` for `→` and `>=` for `≥`, making byte-count == code-point-count and eliminating the trap (a wording call that does not change meaning).

**Structural facts (no rationale tag; no new H2):**
- The bullet carries NO `[rationale: ...]` tag — the project `## Project memory` bullets carry no rationale tags (EB-P3); there is NO project-side rationale-bijection file. So NO rationale section + NO manifest record (unlike the pack's Check-45 bijection). This is a structural simplification vs BD-238.
- The bullet adds NO new `##` H2 (it is a bullet inside the existing rules-section H2), so Check 18 trinity H2-parity is auto-satisfied ×3 (EB-P9).
- CLI-agnostic phrasing ("parallel worktree coder waves") keeps it byte-parity-safe ×3 — no Claude-only worktree mechanics restated (the mechanics live single-source in PM-CHAT, not the trinity).

### 4.3 C1 file 5 — `project-template/docs/pack/PM-CHAT.md` (the consolidating anchor + pointer; MANDATORY)

Two edits, BOTH inside BD-239's two edit regions; NEITHER touches the memory-feature passages at L889-891 / L981-984 (PREFLIGHT-7):

1. **Consolidating ANCHOR** — at the top of the worktree/merge-back section. **Anchor text:** insert immediately before/at the `**Merge-back — the patch comes only after review-clean.**` paragraph (the start of the execution-half region; verified marker, EB-P10). Frame it as "the EXECUTION half of the large-phase pipeline standard," with a one-line pointer to the METHODOLOGY section. A REFERENCE, not a restatement — NO verbatim METHODOLOGY body.
2. **One-line roster/behavioral pointer** — in the agent-roster / behavioral-rules region. **Anchor text:** insert under the `## Behavioral rules` H2 region (verified marker, EB-P10), naming the standard and its METHODOLOGY home, so the orchestrator routing the stages finds the standard.

**M2 coupling-minimization:** the anchor's METHODOLOGY pointer SHOULD use the qualified path `docs/pack/METHODOLOGY.md` (already DANGLING-allowlisted at L390, EB-P5) and reference the trinity rule by CONCEPT, not the literal "`## Project memory`" name — minimizing BD-245's PM-CHAT re-sweep. The qualified `docs/pack/METHODOLOGY.md` cite is gate-safe via the EXISTING allowlist record (no new record needed); confirm byte-identical to the allowlisted form.

### 4.4 C1 files 6-7 — the two elective skill pointers (ELECTIVE; recommended minimal)

- `project-template/skills/architecture-review/SKILL.md` — a one-line pointer noting the skill is loaded by the standard's adversarial-architect stage (stage 3).
- `project-template/skills/planning/SKILL.md` — a one-line pointer noting the skill is loaded by the standard's adversarial-planner stage (stage 6).

Skills are single-file `SKILL.md` (NOT ×3 — EB-P11). 2 edits total. The coder/planner-review MAY drop these to minimize footprint; validate-docs stays green either way. **Do NOT** add the rule body to any skill or agent def (they would become restatement surfaces). **Do NOT** touch the 8 auditor defs, the tester/grpc-schema/repo-ops defs, or the other 31 skills.

### 4.5 C2 — audit-set preservation (MANDATORY; paired pack-only commit AFTER C1)

MOVE the BD-239 pipeline docs from `/tmp/pack-handoff-bd239-arch/*` (research + first design + adversarial review + reconciled design) and `/tmp/pack-handoff-bd239-plan/*` (this plan + the adversarial planner review + any reconciliation) into `maintenance-docs/v11-implementation/`. This is the report-preservation discipline (superseded design docs are NOT preserved if the design directive says delete-on-supersede; the AUDIT SET — the docs the pipeline produced — is preserved). The coder/orchestrator confirms the destination filenames are unique in `maintenance-docs/v11-implementation/` (filename-uniqueness heuristic). This is a pack-side maintenance record; NO client/CI gate applies. The IMPL-REPORT for C1 is also preserved here.

---

## 5. Locked decisions carried (do NOT relitigate)

### 5.1 Wrinkle C = option (b) — BD-239 lands FIRST under `## Project memory`; queue NOT reordered

USER DECISION (2026-06-23). The trinity bullet lands under the CURRENT `## Project memory` heading. The bloat gate finds the section by the literal `## Project memory` (EB-P3), so the gate stays consistent at BD-239's landing. The design's earlier "recommend BD-245 first" framing is SUPERSEDED; this plan encodes BD-239-first. NOT an open user decision.

### 5.2 groupings — OMIT entirely (grep-zero + BD-189 ownership)

The shipped standard uses ONLY phases / phase-tasks / TD vocabulary. groupings is grep-zero under `project-template/` (EB-P3), BD-189 owns the concept (sequenced after BD-206; BD-239 is ahead of it), and phases are the complete size unit — so OMIT. The DEFERRED axis does NOT block a bare "groupings" mention (the regex matches deferral PHRASING only, NOT the concept name — EB-P12); the OMIT rests on grep-zero + BD-189-ownership, NOT a gate fear. The coder must NOT name groupings; if it ever were named WITH deferral phrasing it WOULD trip DEFERRED — BD-239 sidesteps this by omitting the concept.

### 5.3 Zero CLI-memory endorsement — BD-239 is a SEPARATE concern from BD-245

BD-239's edits are ADDITIVE pipeline content ONLY. They add/endorse/reference NO per-CLI project/session memory feature and do NOT modify the existing CLI-memory-endorsement passages (BD-245's job). Encoded as PREFLIGHT-7 (§6). The fresh-instance reconciliation the pipeline cites is the EXISTING `Reconciliation-instance independence` trinity rule (about WHO reconciles, not session memory) — not a memory-feature endorsement.

### 5.4 The BD-239 → BD-245 HARD HAND-OFF NOTE (verbatim — encode into the C1 IMPL-REPORT + the BD-239 entry hand-off)

The coder records this note in the C1 IMPL-REPORT (and Pack Chat carries it to the BD-245 entry / queue) so BD-245's rename/strip census re-sweeps every BD-239 addition:

> **HAND-OFF — BD-239 → BD-245 (BD-239 lands FIRST under `## Project memory`).** BD-245's `enumerate-encoding-surfaces` rename/strip census MUST re-measure the section AFTER BD-239 lands and sweep ALL THREE BD-239-added surfaces that reference the `## Project memory` section name:
> 1. **Trinity ×3** — the NEW BD-239 pipeline bullet under `## Project memory` in `project-template/{CLAUDE,AGENTS,GEMINI}.md`. It rides the heading rename to `## Project rules` (byte-identical ×3 after the rename).
> 2. **`supporting-docs/METHODOLOGY.md`** — the NEW BD-239 Part-5 pipeline subsection. If BD-239's subsection introduces any literal "§ Project memory" / "`## Project memory`" reference (e.g. pointing the reader at the trinity rule), BD-245 renames it in lock-step. (BD-239 SHOULD prefer the bare section concept without the literal name to minimize this coupling — §4.1.)
> 3. **`project-template/docs/pack/PM-CHAT.md`** — the NEW BD-239 anchor + pointer. Same rule: any "§ Project memory" literal BD-239 introduces is in BD-245's census.
>
> BD-245 ALSO updates the shipped `validate-docs.sh` bloat-axis literal `"## Project memory"` → `"## Project rules"` in lock-step — BD-239 does NOT touch `validate-docs.sh`. The BD-239 bullet, sized ≤700 chars under the CURRENT gate, stays ≤700 under the renamed gate (the cap value is unchanged; only the section-finding literal changes).

This is a SEQUENCING coordination + cross-BD hand-off — NOT a deferral. All BD-239 work lands at BD-239's landing; BD-245 RE-PROCESSES BD-239's additions later. (no-deferral / deferral-is-scope-creep: nothing is punted.)

---

## 6. Verification — the PREFLIGHT the coder runs (every gate)

The coder runs ALL of these and emits the one-line PREFLIGHT attestation (`PREFLIGHT: N/N in-scope edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`) ONLY after every one PASSES. If any fails, the coder reports what went wrong INSTEAD of a partial IMPL-REPORT.

| PREFLIGHT | What to verify | How (exact command / method) | Pass condition |
|---|---|---|---|
| **PREFLIGHT-1 — trinity ×3 byte-identity** | the new bullet is byte-identical in CLAUDE/AGENTS/GEMINI | extract the new bullet from each of the three files; normalized diff (the sole body-parity protection — there is NO CI body-parity check, §8) | 0 differences across the three |
| **PREFLIGHT-2 — bloat ≤700 CODE POINTS** | the new trinity bullet's collapsed length ≤ 700 | replicate the gate collapse: read the bullet's lines, `text = " ".join(x.strip() for x in cur)`, `len(text)`. NEVER `wc -c` (the 9 arrows + 1 ≥ are multi-byte → 708 bytes; gate measures 688 code points) | `len(text) ≤ 700`. Option A = 688 (12 margin). If any detail pushed it over, switch to Option B (two ≤700 bullets) |
| **PREFLIGHT-3 — validate-docs operating-doc axes** | HISTORY/DEFERRED/DANGLING/BLOAT clean on the edited docs | `bash project-template/scripts/validate-docs.sh` (scan mode, the installed/source tree); confirm the METHODOLOGY subsection + the trinity bullet carry zero dates/SHAs/deferral/version tokens AND zero groupings mention | exit 0 |
| **PREFLIGHT-4 — cite resolution (DANGLING axis; M1-corrected)** | the METHODOLOGY pointers resolve | confirm the trinity bare-word "METHODOLOGY" is DANGLING-EXEMPT (no `/` — the regex requires a `/`-qualified backtick path, EB-P12); confirm the PM-CHAT qualified `docs/pack/METHODOLOGY.md` cite is byte-identical to the EXISTING L390 allowlist record; run validate-docs to 0 DANGLING fails. **Do NOT test Check 64/70** (Check 64 = MCP/config `.example`-only; Check 70 = `validate-docs.sh`-structure, out of scope — both would trivially pass and give false coverage) | 0 DANGLING fails; cite byte-matches L390 |
| **PREFLIGHT-5 — validate-pack + full battery** | the full CI surface green | `python3 scripts/validate-pack.py` (default) AND `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`; `bash project-template/scripts/validate-docs.sh --self-test`; the relevant project-side checks (Check 18 H2-parity auto-satisfied; Checks 5/27/31/39/1 if any agent/skill/doc touched); the FULL wired CI battery (`verify-full-ci-suite` — not just validate-pack) | all exit 0 |
| **PREFLIGHT-6 — no out-of-scope edits** | scope discipline | `git diff --name-only` shows ONLY the edit-set files (§2.1 rows 1-7); confirm NO edit to `validate-docs.sh`, NO new groupings concept, NO pack-side surface, NO new CI check | only in-scope paths in the diff |
| **PREFLIGHT-7 — zero memory-feature endorsement + memory passages untouched** | the §5.3 HARD CONSTRAINT | grep BD-239's diff for memory-feature tokens (`memory` / `session memory` / `memory cache` / `~/.claude` / `~/.gemini`) → 0 hits in BD-239's NEW text; AND `git diff` shows NO hunk touching `PM-CHAT.md` L889-891 + L981-984 (and `GEMINI.md` cross-session, `CLI-PM-SETUP.md`) — they are byte-UNCHANGED | 0 memory tokens in new text; memory passages byte-unchanged |
| **PREFLIGHT-VOCAB — project-vocabulary purity (§4 rule)** | NO pack-concept leak in shipped text | grep the SHIPPED text (the new METHODOLOGY subsection + the trinity bullet + the PM-CHAT anchors + the skill pointers) for `\bBD-?[0-9]` / `backlog-item` / `pack-[a-z]` / `pack memory` / `pack-ops` / `PACK-CHAT` / `PACK-AGENTS` / `\[rationale` → MUST be zero | 0 pack-concept tokens in shipped text |

**PREFLIGHT-VOCAB note:** the only place BD-238/BD-245 may be NAMED is the C1 IMPL-REPORT and the BD-239 hand-off note (planning context, NOT shipped text). The shipped deliverable text carries phases/phase-tasks/TD/project-agents ONLY.

---

## 7. Commit-scope keyword

**C1 = `project-only`.** C1's edit-set is entirely `project-template/` + project-side `supporting-docs/` (rows 1-7, §2.1). The `project-only` keyword (CI Check 36) denies pack-only paths (everything outside `project-template/` + `supporting-docs/`). C1 touches NO pack-side path → `project-only` is correct and Check 36 passes. (Confirmed against the Check-36 table: `project-only` permitted paths = `project-template/` + `supporting-docs/`; C1's `supporting-docs/METHODOLOGY.md` + `project-template/**` all qualify.)

**C2 = `pack-only`.** C2 moves the audit docs into `maintenance-docs/v11-implementation/` (a pack-side maintenance record). `pack-only` denies `project-template/` + `supporting-docs/`; C2 touches neither → `pack-only` is correct.

**Keyword-token trap caution:** the scope keyword is a Check-36 CLAIM wherever it appears in the subject (incl. prose). The C1 subject must carry `project-only` and NO denying token; the C2 subject must carry `pack-only` and NO denying token. Use the commit-message form `feat: v11 — BD-239 <desc> (project-only)` for C1 and a `docs: v11 — BD-239 <desc> (pack-only)` form for C2 (per the approved commit-message shapes).

---

## 8. Parity / CI-guard call — NO new project-side guard (DROP, not defer)

Carried from the design (§8), confirmed by the adversary. NO new project-side CI body-parity check for BD-239:
- The new bullet is SHORT (688 chars, a pointer — far easier to keep ×3-identical than the pack's ~1289-char rule).
- A ×3 body drift is the ONLY new risk; it is RECOVERABLE (caught at the next trinity edit/review) and is the SAME residual every existing project trinity rule already carries — BD-239 adds no new KIND of exposure.
- A correct body-parity check is a LARGER, SEPARATE effort (normalize around GEMINI-intrinsic H2s, re-baseline every existing rule for ×3 identity, reconcile with the existing parity gates) — a distinct CI-guard contract from BD-239's codification.
- The existing gates (HISTORY/DEFERRED/BLOAT/DANGLING + Check 18 H2-parity) + the PREFLIGHT-1 ×3-byte-identity attestation are the sole-and-sufficient protection.

**DROP, not defer:** the guard is unnecessary work whose correct form is a net complexity loss; it does not exist and is not scheduled. (no-deferral compliance: nothing pushed to a later BD.)

---

## 9. Manifest expectation — BD-239 DOES change fixture inputs (CORRECTS the design's NOOP claim)

**STATE-CORRECTION (load-bearing).** The reconciled design (§9 row 8 + EB-13) and the adversarial review (m3 + EB-A7) concluded "the manifest is a NOOP for BD-239's entire edit-set" based on `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt` → 0. **That test is against the WRONG artifact.** `test-fixtures/manifest.txt` stores `<fixture-name> <sha>` pairs (10 lines: the built scenario trees + a header), NEVER source paths (EB-P1). Grepping it for a source basename ALWAYS returns 0 — for EVERY pack source file, fixture-input or not. The fixture-input decision is made by the predicate `manifest_path_is_input` in `scripts/lib/manifest-inputs.sh` (the SINGLE SoT, EB-P1).

**The predicate, run against BD-239's actual edit paths (EB-P2):**

| BD-239 edit path | `manifest_path_is_input` | Why |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | **INPUT** | named explicitly in `MANIFEST_INPUT_GLOBS` (line 59) — copied to client `docs/pack/` by init-project |
| `project-template/CLAUDE.md` | **INPUT** | matches `project-template/*` (recursive subtree) |
| `project-template/AGENTS.md` | **INPUT** | matches `project-template/*` |
| `project-template/GEMINI.md` | **INPUT** | matches `project-template/*` |
| `project-template/docs/pack/PM-CHAT.md` | **INPUT** | matches `project-template/*` |
| `project-template/skills/architecture-review/SKILL.md` | **INPUT** | matches `project-template/*` |
| `project-template/skills/planning/SKILL.md` | **INPUT** | matches `project-template/*` |

**ALL SEVEN C1 edit paths are fixture inputs.** When BD-239's C1 lands, the deterministic fixture SHAs in `test-fixtures/manifest.txt` WILL change (the edited files are copied into the built fixtures). So at PUSH TIME the orchestrator's `scripts/manifest-sync.sh` regeneration is expected to report **MANIFEST-CHANGED (exit 10) — a REAL SHA change, NOT a NOOP** (this is the OPPOSITE of BD-238 if BD-238's edits were pack-ops/maintenance-only; BD-239 touches the shipped fixture corpus directly).

**Orchestrator action (push-time, NOT per-commit, NOT the coder):** per `regenerate-manifest-v11-surface` — the coder does NOT regenerate the manifest; the manifest is regenerated ONLY at push, ONLY when a fixture input changed, by `scripts/manifest-sync.sh`. Expect `manifest-sync.sh` to exit 10 (MANIFEST-CHANGED) and the orchestrator to commit the regenerated `test-fixtures/manifest.txt` with user approval before `git push`. CI `build.sh --verify` + validate-pack Check 62 enforce manifest correctness at the push end-state.

**Clear statement for the orchestrator:** BD-239 is a fixture-input-changing BD. Plan for a real manifest SHA delta at push (exit 10), NOT a NOOP. The coder leaves `test-fixtures/manifest.txt` untouched; the push-time tool handles it.

---

## 10. Risks + open unknowns

| # | Risk | Likelihood | Mitigation (in this plan) |
|---|---|---|---|
| R1 | **700-char bloat overflow** — a wording tweak pushes the trinity bullet over 700 code points (12-char margin) | MEDIUM | PREFLIGHT-2 mandates the gate-exact code-point measure; Option B (split) is the named fallback; the optional ASCII-arrow substitution removes the byte/code-point ambiguity. |
| R2 | **`wc -c` byte-measure false-failure** — the coder measures bytes (708) and wrongly concludes overflow, or wrongly "fixes" a passing bullet | MEDIUM | PREFLIGHT-2 explicitly forbids `wc -c` and prescribes the `len()` collapse; EB-P8 documents 688 cp / 708 bytes. |
| R3 | **Stale cross-reference (DANGLING)** — a half-applied state (pointer without target) trips the DANGLING axis | LOW | Rule-10 SERIAL single-commit C1 (cross-reference atomicity, §3.2) — pointers + target in ONE commit; PREFLIGHT-4. |
| R4 | **Trinity body drift ×3** — the bullet differs across the three files (no CI body-parity net) | LOW | PREFLIGHT-1 ×3-byte-identity attestation (the sole protection, §8). |
| R5 | **CLI-memory contamination** — the coder accidentally edits/endorses a memory passage | LOW | PREFLIGHT-7 grep-zero + byte-unchanged attestation; §5.3 names the exact line ranges to leave alone. |
| R6 | **Pack-concept leak in shipped text** — a BD/pack-* token reaches the deliverable | LOW | PREFLIGHT-VOCAB purity grep; §4.1 mandates project-vocabulary-only. |
| R7 | **Manifest mishandled** — the coder regenerates the manifest per-commit, OR the orchestrator expects a NOOP and skips the regen | MEDIUM | §9 corrects the design's NOOP claim; the coder leaves the manifest untouched; the orchestrator expects exit 10 at push. |
| R8 | **BD-245 census miss** — BD-245 later renames `## Project memory` but misses a BD-239-added literal reference in METHODOLOGY/PM-CHAT | LOW | §5.4 hard hand-off note enumerates all 3 surfaces; §4.1/§4.3 minimize literal-name references (reference by concept). |
| R9 | **Check 36 scope-keyword mismatch** — C1 carries a denying token or a stray keyword in prose | LOW | §7 specifies `project-only` for C1, `pack-only` for C2, and the keyword-token-trap caution. |

**No purpose-defeating unknowns.** Every state-verifiable question was answered by read-only measurement (§12). The ONE remaining USER-decision the design surfaced (groupings OMIT) is already locked (§5.2). There is NO `MAINTAINER CHECK NEEDED` item — all scope questions are state-verifiable and resolved.

**One MINOR open authoring choice (coder's mechanical call, not a design gap):** the exact METHODOLOGY subsection title (`### Workflow 4.5 …` vs `### The large-phase pipeline standard`) and whether to take Option A vs Option B for the trinity bullet (drive by PREFLIGHT-2's measurement). Neither blocks the coder.

---

## 11. Coder execution order (the step sequence)

1. Create the C1 isolated worktree (orchestrator: Agent-tool `isolation:"worktree"`, base `head`).
2. **C1 edit 1:** author the METHODOLOGY Part-5 subsection (§4.1) in `supporting-docs/METHODOLOGY.md`.
3. **C1 edits 2-4:** insert the byte-identical trinity bullet (§4.2, Option A or B per PREFLIGHT-2) in CLAUDE/AGENTS/GEMINI.
4. **C1 edit 5:** add the PM-CHAT consolidating anchor + roster pointer (§4.3).
5. **C1 edits 6-7 (elective):** add the 2 skill pointers (§4.4) — or drop per planner-review.
6. Run the FULL PREFLIGHT (§6: PREFLIGHT-1 … 7 + PREFLIGHT-VOCAB). All PASS.
7. Emit the PREFLIGHT one-liner; Write the C1 IMPL-REPORT (incl. the §5.4 hand-off note + the §9 manifest expectation + the Rules-Applied + Empirical-Evidence blocks).
8. Bounded review/fix cycle in the C1 worktree (≤2 review/fix pairs + 1 final reviewer). Patch produced only after review-clean. Orchestrator applies + commits C1 (`project-only`, user approval).
9. After C1 lands (exit 0): fresh coder for **C2** — move the audit docs into `maintenance-docs/v11-implementation/` (§4.5). Commit C2 (`pack-only`, user approval). Live-worktree ASK gate applies if C1's worktree is still live.
10. At push (orchestrator): `bash scripts/manifest-sync.sh` → expect exit 10 (MANIFEST-CHANGED) → commit the regenerated `test-fixtures/manifest.txt` (user approval) → `git push` → watch `Validate Pack` CI.

---

## 12. Empirical-Evidence Blocks (every NEW state-claim — re-measured by me)

All measured at HEAD `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, branch `v11-dev`, 2026-06-23, in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EB-P1 — `manifest.txt` stores fixture-name→SHA pairs (not source paths); the predicate is `manifest_path_is_input` (CORRECTS the design's NOOP basis).**
- Command: `head -10 test-fixtures/manifest.txt` ; `wc -l test-fixtures/manifest.txt` ; `grep -c supporting-docs test-fixtures/manifest.txt` ; `sed -n '54,69p' scripts/lib/manifest-inputs.sh`
- Output (verbatim): manifest header `# Format: <fixture-name>  <sha>` + 6 data rows (`v10-minimal`, `v10-realistic-ot`, `v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`, `existing-project-mid-dev`); `10 test-fixtures/manifest.txt`; `supporting-docs` count = `0`; `MANIFEST_INPUT_GLOBS=("project-template/*" "scripts/*" "test-fixtures/build.sh" "supporting-docs/METHODOLOGY.md" "supporting-docs/INSTALL-PROCEDURES.md")`.
- Interpretation: `manifest.txt` indexes built FIXTURE SHAs, never source paths; grepping it for a source basename returns 0 for EVERY source file. The fixture-input set is defined by `manifest_path_is_input` in `manifest-inputs.sh`, which globs `project-template/*` (recursive) + names `supporting-docs/METHODOLOGY.md` explicitly.
- Conclusion: SUPPORTED — the design/adversary "manifest NOOP" conclusion rests on a grep against the wrong artifact; the real test is the predicate.

**EB-P2 — ALL seven BD-239 edit paths are fixture inputs.**
- Command: `source scripts/lib/manifest-inputs.sh; for p in supporting-docs/METHODOLOGY.md project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md project-template/docs/pack/PM-CHAT.md project-template/skills/architecture-review/SKILL.md project-template/skills/planning/SKILL.md; do manifest_path_is_input "$p" && echo "INPUT -> $p" || echo "not -> $p"; done`
- Output (verbatim): `INPUT -> supporting-docs/METHODOLOGY.md`; `INPUT -> project-template/CLAUDE.md`; `INPUT -> project-template/AGENTS.md`; `INPUT -> project-template/GEMINI.md`; `INPUT -> project-template/docs/pack/PM-CHAT.md`; `INPUT -> project-template/skills/architecture-review/SKILL.md`; `INPUT -> project-template/skills/planning/SKILL.md`
- Interpretation: every C1 edit path is a fixture input; editing them changes the built fixtures' content and thus their deterministic SHAs.
- Conclusion: SUPPORTED — BD-239 DOES change fixture inputs; the push-time `manifest-sync.sh` is expected to report MANIFEST-CHANGED (exit 10), NOT a NOOP (§9).

**EB-P3 — trinity section name (`## Project memory`), zero rationale tags, groupings grep-zero, bloat cap 700 + section literal.**
- Command: `grep -n "^## Project memory\|^## Project rules" project-template/{CLAUDE,AGENTS,GEMINI}.md` ; `grep -c "\[rationale:" project-template/CLAUDE.md` ; `grep -rln "groupings" project-template/ | wc -l` ; `grep -n "BLOAT_BULLET_CHAR_CAP" project-template/scripts/validate-docs.sh` ; `grep -n 'l.strip() == "## Project memory"' project-template/scripts/validate-docs.sh`
- Output (verbatim): `CLAUDE.md:360:## Project memory`, `AGENTS.md:339:## Project memory`, `GEMINI.md:357:## Project memory`; `[rationale:` count = `0`; groupings under project-template/ = `0`; `213:BLOAT_BULLET_CHAR_CAP = 700`; `259:        if l.strip() == "## Project memory":`
- Interpretation: section is `## Project memory` (current name — BD-239 lands first); no rationale tags (no bijection surface); groupings absent; the bloat axis caps each `## Project memory` bullet at 700 and finds the section by the literal heading.
- Conclusion: SUPPORTED — the design's placement/structure/cap claims hold at the current HEAD.

**EB-P4 — the trinity insertion anchor (after the Reconciliation bullet, before `## Phase routing`).**
- Command: `awk '/^## Project memory/{f=1} f&&/^## /&&!/^## Project memory/{exit} f{print NR": "$0}' project-template/CLAUDE.md | tail -3` ; `for f in CLAUDE AGENTS GEMINI; do awk '/^## Project memory/{f=1; next} f&&/^## /{print FILENAME" next H2: "$0; exit}' project-template/$f.md; done`
- Output (verbatim): last section content = the `**Reconciliation-instance independence.**` bullet (CLAUDE.md L418-427); next H2 in all three = `## Phase routing — default agent assignments`.
- Interpretation: the new bullet inserts as the LAST bullet under `## Project memory`, after the Reconciliation bullet, before `## Phase routing`, in all three trinity files.
- Conclusion: SUPPORTED — the §4.2 insertion anchor is precise and consistent ×3.

**EB-P5 — the existing `target: docs/pack/METHODOLOGY.md` allowlist record (L390) covers the qualified cite; PM-CHAT already cites it.**
- Command: `grep -n "METHODOLOGY" project-template/scripts/.docs-gate-allowlist.txt` ; `grep -n "docs/pack/METHODOLOGY.md" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `390:target: docs/pack/METHODOLOGY.md` (with `reason: pack-shipped reference doc installed into docs/pack/ at project init …`); PM-CHAT cites `docs/pack/METHODOLOGY.md` at L138, L150, L167, L894.
- Interpretation: the qualified METHODOLOGY cite is already DANGLING-allowlisted (L390); BD-239's anchor cite of the same path rides the existing record — no new record needed.
- Conclusion: SUPPORTED — PREFLIGHT-4 targets the DANGLING axis + the existing L390 record (not Check 64/70).

**EB-P6 — CI is push-time; validate-docs has scan + self-test modes; DEEP env var exists.**
- Command: `sed -n '50,58p' project-template/scripts/validate-docs.sh` ; `grep -n "PACK_VALIDATE_DEEP" scripts/validate-pack.py | head -2`
- Output (verbatim): `--self-test) MODE="selftest" ;; "") MODE="scan" ;; *) MODE="file"; ARG_FILE="$1" ;;`; `9470:#       PACK_VALIDATE_DEEP=1, BEFORE any tree read …`, `9612:    runs the heavy whole-tree verification ONLY under PACK_VALIDATE_DEEP=1`
- Interpretation: validate-docs runs default scan (no arg), `--self-test`, or single-file; validate-pack has a DEEP whole-tree mode under `PACK_VALIDATE_DEEP=1`. The PREFLIGHT-5 battery (default + DEEP + self-test) is wired.
- Conclusion: SUPPORTED — PREFLIGHT-3/5 invoke the right modes.

**EB-P7 — the Planner-trigger threshold (P5 source) is present in METHODOLOGY.**
- Command: `grep -n "more than ~5 tasks\|Planner trigger" supporting-docs/METHODOLOGY.md | head`
- Output (verbatim): the `### Planner trigger rule` block with condition #1 "The phase has more than ~5 tasks, or task dependencies within the phase are non-linear" (the design EB-A3a confirmed it at L317; present at the current HEAD).
- Interpretation: P5 ("more than ~5 tasks OR non-linear intra-phase deps") faithfully reuses the existing planner-trigger condition #1 — not invented.
- Conclusion: SUPPORTED — the METHODOLOGY anchor (insert after Workflow 4, before Workflow 5) is adjacent to this existing trigger; P5 grounding holds.

**EB-P8 — Option A = 688 code points (12 margin) / 708 bytes / 9 arrows + 1 ≥ (the bloat + byte-trap measure).**
- Command: Python replication of the gate collapse `" ".join(x.strip() for x in lines)` + `len()` + `.encode("utf-8")` on the verbatim §4.2 Option A bullet.
- Output (verbatim): `collapsed code-point len: 688`; `<=700? True | margin: 12`; `UTF-8 byte len: 708`; `arrows: 9 | >= signs: 1`
- Interpretation: Option A fits under the gate's code-point measure (688 ≤ 700, 12 margin) but is 708 bytes — a `wc -c` measure would falsely flag it. The 9 `→` + 1 `≥` are the multi-byte source.
- Conclusion: SUPPORTED — PREFLIGHT-2's code-point-not-byte mandate + the thin-margin/Option-B fallback are necessary and correct.

**EB-P9 — the proposed bullet adds NO new H2 (Check 18 auto-satisfied); Check 18 is the trinity H2-parity gate.**
- Command: (the §4.2 Option A bullet is a `-` bullet, zero `##` lines) ; `grep -n "Check 18.*Trinity H2\|def .*check.*18\|Trinity H2 structure parity" scripts/validate-pack.py | head`
- Output (verbatim): Option A contains 0 `^##` lines; `1585:    """Check 18 — trinity templates have matching H2 structure at a given location.`; `1623: print(f"\n── Check 18 [{label}]: Trinity H2 structure parity (BD-059, BD-181) ──")`
- Interpretation: the new bullet introduces no `##` heading, so the project-template trinity H2 set/order is unchanged → Check 18 is auto-satisfied ×3.
- Conclusion: SUPPORTED — no H2-parity work needed.

**EB-P10 — PM-CHAT anchor regions + the memory passages (the two edit regions + the leave-alone passages).**
- Command: `grep -n "Merge-back\|Preserve the reports\|Ask before reusing\|parallel worktree waves\|On conflict\|^## Behavioral rules\|^## Pack agent roster\|Per-project Claude memory\|Cross-session memory" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `47:## Pack agent roster`; `172:## Behavioral rules`; `513:**Merge-back — the patch comes only after review-clean.**`; `564:**Preserve the reports.**`; `576:**Ask before reusing a live worktree for off-cycle work.**`; `590:to schedule parallel worktree waves versus serial commits`; `594:**On conflict, do not hand-merge.**`; `889:> **Per-project Claude memory cache (Claude-only).**`; `981:### Cross-session memory`
- Interpretation: the execution-half anchor goes at/near the `Merge-back` paragraph (~L513); the roster pointer goes under `## Behavioral rules` (~L172) / `## Pack agent roster` (~L47). The CLI-memory passages BD-239 must NOT touch are at L889 + L981 — OUTSIDE both anchor regions.
- Conclusion: SUPPORTED — §4.3 anchors are precise; PREFLIGHT-7's leave-alone targets are the L889/L981 ranges.

**EB-P11 — the two elective skills are single-file SKILL.md (not ×3) and exist.**
- Command: `ls project-template/skills/architecture-review/SKILL.md project-template/skills/planning/SKILL.md`
- Output (verbatim): both paths present (no error).
- Interpretation: each skill is one `SKILL.md` file; the elective pointer is 2 edits total (not 6).
- Conclusion: SUPPORTED — §4.4 footprint (2 edits) is correct.

**EB-P12 — the DANGLING regex requires a `/`-qualified backtick path (bare "METHODOLOGY" exempt); the DEFERRED regex lacks "groupings".**
- Command: `sed -n '222,224p' project-template/scripts/validate-docs.sh` ; `sed -n '202,207p' project-template/scripts/validate-docs.sh`
- Output (verbatim): `DANGLING_BACKTICK = re.compile(r"`([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:" + _DANGLING_EXT + r"))`")`; `DEFERRED_PATTERN = re.compile(r"\bdeferred\b|future (release|version)|\bnot yet (created|implemented|built|shipped)\b|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b", re.IGNORECASE)`
- Interpretation: DANGLING matches only a backtick-wrapped token containing a `/` and a known extension — the bare-word "METHODOLOGY" (no `/`) is exempt; only a qualified `docs/pack/METHODOLOGY.md` cite matches. DEFERRED matches deferral PHRASING only — "groupings" is not in the alternation.
- Conclusion: SUPPORTED — PREFLIGHT-4 (trinity bare-word exempt; PM-CHAT qualified cite rides L390) + §5.2 (groupings OMIT on grep-zero/BD-189 grounds, not a DEFERRED fear) are correct.

---

## 13. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Ran only read-only verbs: `git rev-parse HEAD` → `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty, plus `grep`/`sed`/`head`/`ls`/`awk`/`Read`/`python3`/`source` + `graphify query` measurement. NO `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. Sole Write = this plan at `/tmp/pack-handoff-bd239-plan/PLAN-BD-239.md` (Bash heredoc appends). No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **no-solutions-injected** | I SEQUENCED the reconciled design — I did not redesign. The 9-stage chain, the 5-signal criterion, the Option-A bullet text, the placements, the parity-DROP, the wrinkle resolutions are CARRIED from `DESIGN-BD-239-RECONCILED.md` §4-§10. My ONLY substantive addition is the manifest STATE-CORRECTION (§9) — a measured fact (EB-P1/EB-P2), not a design change; the design's NOOP conclusion was based on a grep against the wrong artifact. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §12 carries EB-P1…EB-P12: every NEW state-claim (the manifest predicate + the seven INPUT verdicts; the section name/cap/groupings; the insertion anchor; the L390 record; the modes/DEEP var; the planner-trigger source; the 688/708 measure; no-new-H2; the PM-CHAT anchors + memory passages; single-file skills; the DANGLING/DEFERRED regexes) backed by command + verbatim output + HEAD `d720873` + interpretation + SUPPORTED conclusion. | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only** | The shipped standard (§4.1/§4.2/§4.3/§4.4) uses ONLY project vocabulary — phases, phase-tasks, TD backlog, project agents (architect/planner/coder/reviewer/docs-researcher/tester/auditor), the project's own triggers + execution half. PREFLIGHT-VOCAB (§6) encodes the purity grep gate (`\bBD-?[0-9]`/`backlog-item`/`pack-[a-z]`/`pack memory`/`pack-ops`/`PACK-CHAT`/`PACK-AGENTS`/`\[rationale` → must be zero in shipped text). The only BD-238/BD-245 mentions in this plan are PLANNING CONTEXT, not shipped text. | COMPLIANT |
| 5 | **operating-docs-no-history-no-bloat** | §4.1 mandates the METHODOLOGY subsection carry ZERO history/dates/SHAs/provenance + ZERO deferral/version phrasing; §4.2 keeps the trinity bullet a terse ≤700-code-point pointer (688, EB-P8), the full chain in METHODOLOGY (uncapped). PREFLIGHT-2/3 attest the bloat + HISTORY/DEFERRED axes. The hand-off note + manifest history live in the IMPL-REPORT/this plan (reference docs), NOT in the operating doc. | COMPLIANT |
| 6 | **enumerate-encoding-surfaces** | §2 enumerates EVERY surface: the 7 edited files (§2.1), the 5 state-encoding gates/allowlist NOT edited but that gate the work (validate-docs.sh, .docs-gate-allowlist.txt L390, Check 18, manifest-inputs.sh, manifest.txt — §2.2), and the NOT-touched set (§2.3). §6 enumerates every verification gate (PREFLIGHT-1…7 + VOCAB). Lock-step coverage: the trinity bullet's encoding surfaces (validate-docs bloat/dangling + Check 18) are each named with their PREFLIGHT. | COMPLIANT |
| 7 | **regenerate-manifest-v11-surface** | §9 ASSESSES and STATES the manifest expectation from measurement (EB-P1/EB-P2): ALL seven BD-239 edit paths are fixture inputs per `manifest_path_is_input` → BD-239 DOES change fixture inputs → push-time `manifest-sync.sh` is expected to exit 10 (MANIFEST-CHANGED, a REAL SHA delta, NOT a NOOP). The coder does NOT regenerate the manifest per-commit; the orchestrator regenerates at push, ONLY when an input changed. This CORRECTS the design's "NOOP" claim. | COMPLIANT |
| 8 | **deferral-is-scope-creep / no-deferral** | Nothing deferred. Wrinkle C = (b) is a SEQUENCING choice (BD-239 first, queue NOT reordered) + the §5.4 cross-BD hand-off note (BD-245 re-sweeps BD-239's additions) — a COORDINATION, not a punt; ALL BD-239 work lands at BD-239's landing. The parity guard is DROPPED (§8), not deferred (no follow-up scheduled). groupings is OMITted in-scope (§5.2), not pushed to a later BD by BD-239. The elective skill pointers may be dropped (a footprint choice), not a deferral. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — rules 1-9, each name + quoted evidence + terminal conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

---

*End of PLAN-BD-239. Pack-planner (RO); sequenced the reconciled design (no redesign); one Write (this plan) under /tmp; read-only git only; no memory store used. The plan is coder-ready: exact anchors (§4) + the Option-A bullet text + the two coder cautions (thin margin + code-point-not-byte), the 9-stage METHODOLOGY chain spec, the verbatim BD-245 hand-off note (§5.4), the full PREFLIGHT incl. zero-memory attestation + validate-docs self-test + vocab-purity grep (§6), the SERIAL single-C1-commit + paired-C2 rule-10 map (§3), the project-only/pack-only keywords (§7), and the CORRECTED manifest expectation — BD-239 DOES change fixture inputs → push-time exit-10 regen, NOT a NOOP (§9, EB-P1/EB-P2). Ready for adversarial planner review → user planner-to-coder gate → pack-coder.*
