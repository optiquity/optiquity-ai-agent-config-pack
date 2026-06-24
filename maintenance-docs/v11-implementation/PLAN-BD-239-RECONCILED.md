# PLAN-BD-239-RECONCILED — implementation plan for the PROJECT-SIDE large-PHASE development pipeline standard (size-tiered)

**Role:** pack-planner (RO), FRESH + INDEPENDENT reconciler. I did NOT author `PLAN-BD-239.md` and I am NOT its adversarial reviewer. **BD:** BD-239 (LARGE — runs the full pipeline). **Inputs reconciled:** `PLAN-BD-239.md` (the plan revised here), `ADVERSARIAL-REVIEW-PLAN-BD-239.md` (NEEDS-REWORK: 0 blocking / 1 MAJOR + 3 MINOR + 2 NIT), `DESIGN-BD-239-RECONCILED.md` (the approved design), `BD-239.md` (the spec). **Output:** this reconciled plan only (sole Write, under `/tmp`). **Next stage:** user planner-to-coder gate → pack-coder.

This plan carries the FULL coder-ready sequencing (not a diff) so a coder implements with ZERO open design questions. The adversary's single MAJOR (the wrong/conflated METHODOLOGY insertion anchor in §4.1) is FIXED with re-verified text anchors; the 3 MINOR + 2 NIT are folded in. Every state-claim I touch is re-measured at the CURRENT HEAD (§12). The carry-forwards the adversary CONFIRMED accurate are kept UNCHANGED per the reconciliation directive.

---

## 0. Runtime regime (RO; verified by me)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `d720873b6010a4059a2ebb919070ef85b7d2d5c6` |
| branch | `v11-dev` |
| `git status --short` | clean (the work I plan is design-stage / committed; RO placement = this main checkout) |
| graph | DISCOVERY queried (`graphify query … --graph /Users/.../graphify-out/graph.json --backend claude-cli --budget 1500`); operating-doc rule bodies are not node-indexed at rule granularity → grep/Read/python3 for VERIFICATION (G2 fallback, sanctioned for exact-bytes/anchor/predicate reads). |
| writes | EXACTLY ONE: this plan at `/tmp/pack-handoff-bd239-plan/PLAN-BD-239-RECONCILED.md`. No source edits. Read-only git only. No memory store read/written (MEMORY PROHIBITION 2026-06-23 honored). |

**HEAD parity note:** the plan under reconciliation measured at HEAD `d720873`; I am at the SAME HEAD `d720873` — no drift. Every load-bearing anchor was re-verified at this exact HEAD, including the CORRECTED METHODOLOGY anchor (EB-R1).

---

## 1. Goal + BD scope addressed

**Goal:** codify the project-side large-PHASE development pipeline as ONE official, size-tiered standard — the full chain (optional internal/external researcher(s) → architect → adversarial architect review → reconciliation → user design review → planner → adversarial planner review → reconciliation → user planner-to-coder gate → parallel worktree coder waves → OPTIONAL post-implementation audit), keyed on PHASES, in project vocabulary only, shipped to clients. The two adversarial reviews + reconciliation are the MINIMUM for a LARGE phase and OPTIONAL at developer election for a SMALL phase.

**BD-239 acceptance criteria → where this plan addresses each:**

| BD-239 acceptance clause | Addressed by |
|---|---|
| ONE official, size-tiered standard (full chain incl. optional researcher first step + large/small-PHASE criterion + adversarial-as-min-for-large/optional-for-small + reconciliation + parallel-worktree coder waves) | C1 (METHODOLOGY body, §4.1) — the full 9-stage chain + the two-part 5-signal criterion |
| lives in project-side SSOT surfaces (METHODOLOGY.md / PM-CHAT.md / project trinity) and ships to clients | C1 (METHODOLOGY) + C1 (trinity ×3 + PM-CHAT anchor) — §4.1–§4.3; all are fixture inputs (§9) so they ship |
| uses ONLY project vocabulary (phases, phase tasks, TD backlog, groupings, project agents); NO pack work-item references leak | PREFLIGHT-VOCAB (§6) — the purity grep gate; groupings OMITTED (§5.2) |
| consistent with the pack-side companion standard's pipeline shape | C1 — the design's 9-stage chain mirrors BD-238's shape with the 5 justified roster divergences (design §5) |
| `validate-pack` green | PREFLIGHT (§6) — validate-pack default + DEEP, validate-docs self-test, full battery |
| architect-designed (not PM-chat-authored) | satisfied upstream: architect → adversarial → reconciliation done; this plan + the coder implement mechanically |

**No BD item is partially addressed.** Wrinkle C = option (b) (BD-239 lands FIRST under `## Project memory`; queue NOT reordered) is encoded as a sequencing choice + a hard hand-off note to BD-245 (§5.4) — NOT a deferral. The zero-CLI-memory constraint is encoded as PREFLIGHT-7 (§6, tightened per MINOR-3).

---

## 2. Affected files — the COMPLETE list (enumerate-encoding-surfaces)

Every surface BD-239 touches, every surface that ENCODES its expected state (gates/allowlist), and every cross-reference surface. Sourced from design §6/§9 + my re-measurement.

### 2.1 C1 edit-set — the files EDITED in commit C1 (the only files PREFLIGHT-6 bounds)

> **NIT-1 fold-in:** this table is ONLY the C1 edit-set (the 7 paths the PREFLIGHT-6 "only in-scope paths" diff-check bounds). The C2 doc-move is a SEPARATE commit with its OWN mini-table (§2.1b) — it is NOT in the C1 diff.

| # | File | Edit | Mandatory? | Commit |
|---|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | NEW Part-5 subsection: the 9-stage chain + the 5-signal size criterion (the SSOT body) | MANDATORY | C1 |
| 2 | `project-template/CLAUDE.md` | insert the §4.2 trinity pointer bullet under `## Project memory` (byte-identical ×3) | MANDATORY | C1 |
| 3 | `project-template/AGENTS.md` | SAME byte-identical bullet | MANDATORY | C1 |
| 4 | `project-template/GEMINI.md` | SAME byte-identical bullet | MANDATORY | C1 |
| 5 | `project-template/docs/pack/PM-CHAT.md` | consolidating anchor (execution-half region ~L513) + one-line roster/behavioral pointer (~L47–172) | MANDATORY | C1 |
| 6 | `project-template/skills/architecture-review/SKILL.md` | one-line "loaded by the standard's adversarial architect stage" pointer | ELECTIVE (recommended; planner/coder may drop) | C1 |
| 7 | `project-template/skills/planning/SKILL.md` | one-line "loaded by the standard's adversarial planner stage" pointer | ELECTIVE (recommended; planner/coder may drop) | C1 |

### 2.1b C2 edit-set — the audit-set preservation (SEPARATE commit, NOT in the C1 diff)

| # | File | Edit | Mandatory? | Commit |
|---|---|---|---|---|
| 8 | `maintenance-docs/v11-implementation/` | MOVE the BD-239 pipeline docs (`/tmp/pack-handoff-bd239-arch/*` + `/tmp/pack-handoff-bd239-plan/*`) into the implementation-record area (report-preservation) | MANDATORY | **C2 (separate, paired pack-only) — NOT in the C1 diff that PREFLIGHT-6 bounds** |

### 2.2 Surfaces that ENCODE BD-239's expected state but are NOT edited (the gates / allowlist)

| Surface | Why it matters | BD-239 action |
|---|---|---|
| `project-template/scripts/validate-docs.sh` | the shipped client gate (HISTORY/DEFERRED/BLOAT/DANGLING axes); finds the trinity section by the literal `## Project memory`; caps bullets at 700 code points | NOT edited (renaming its `## Project memory` literal is BD-245's job, §5.4). The coder RUNS it (PREFLIGHT). |
| `project-template/scripts/.docs-gate-allowlist.txt` (L390 `target: docs/pack/METHODOLOGY.md`) | DANGLING-axis allowlist; the EXISTING record covers the qualified METHODOLOGY cite | NOT edited (the existing record suffices; EB-R5). The coder confirms the cite is byte-identical to it. |
| `scripts/validate-pack.py` Check 18 | trinity H2-structure parity at project-template (auto-satisfied — no new H2) | NOT edited; the coder runs validate-pack. |
| `scripts/validate-pack.py` Check 36 (`_SCOPE_NEUTRAL_GENERATED_PATHS`) | the scope-keyword gate; `test-fixtures/manifest.txt` is in the scope-neutral set (EB-R3) | NOT edited; informs the push-time manifest-commit keyword note (§7). |
| `scripts/lib/manifest-inputs.sh` (`manifest_path_is_input`) | the SINGLE source of truth for the fixture-input predicate; ALL 7 BD-239 edit paths match it (EB-R2) | NOT edited; informs the manifest expectation (§9). |
| `test-fixtures/manifest.txt` | per-fixture SHA manifest; BD-239 edits ARE fixture inputs AND are copied verbatim into the built fixtures → fixture SHAs change → push-time regen (exit 10, NOT a NOOP) | NOT edited by the coder; the orchestrator runs `manifest-sync.sh` at push (§9). |

### 2.3 Surfaces explicitly NOT touched (design §6.5)

- The 16 agent defs ×3 families (0 mandatory; pipeline-stage refs not added to agent defs).
- 35 of 37 skills (only the 2 adversarial-stage skills get the elective pointer).
- `project-template/docs/project/*/_rules.md` (phase/TD vocabulary contracts — referenced, not changed).
- `project-template/docs/project/` groupings — does not exist (EB-R6); NOT created.
- The CLI-memory-endorsement passages: `PM-CHAT.md` L889-891 ("Per-project Claude memory cache (Claude-only)") + L981-984 ("### Cross-session memory" → `~/.gemini/GEMINI.md`); `GEMINI.md` cross-session; `CLI-PM-SETUP.md`. NOT touched — BD-245 strips them (PREFLIGHT-7, §6).
- Any pack-side operating surface (`pack-ops/`, pack-root trinity, PACK-CHAT.md, PACK-AGENTS.md). ZERO pack surfaces.

---

## 3. Commit sequence + rule-10 parallel/dependency map

### 3.1 The commits

| Commit | Scope | Files | Scope keyword |
|---|---|---|---|
| **C1** | the standard itself (SSOT body + pointers) | METHODOLOGY + trinity ×3 + PM-CHAT anchor/pointer + (elective) 2 skill pointers | `project-only` (§7) |
| **C2** | audit-set preservation | `/tmp/pack-handoff-bd239-arch/*` + `/tmp/pack-handoff-bd239-plan/*` → `maintenance-docs/v11-implementation/` | `pack-only` (maintenance record) |

(The push-time manifest-regen commit — see §9 — is a THIRD, orchestrator-only commit at push; it carries `test-fixtures/manifest.txt`, which is scope-NEUTRAL — §7 MINOR-2 note.)

### 3.2 Rule-10 verdict — SERIAL, ONE coder commit (C1), then C2

**RECOMMENDED: C1 is ONE serial coder commit (METHODOLOGY + trinity ×3 + PM-CHAT + the 2 elective skill pointers combined); C2 is the paired audit-set preservation commit AFTER C1 lands.** The design (§10.2) reached this verdict; I confirm it and re-state the binding reasons:

1. **Cross-reference atomicity (the binding reason).** The trinity bullet + the PM-CHAT anchor POINT AT the METHODOLOGY section; the METHODOLOGY section is the SSOT the pointers resolve to. Splitting them across commits leaves an intermediate commit carrying a half-applied cross-reference (pointers without target, or target without pointers) that the validate-docs DANGLING axis would flag on the qualified PM-CHAT cite. ONE commit means the committed state never carries a dangling cross-reference (clean per-commit audit).
2. **The trinity ×3 is one byte-identical unit** (the trinity rule). That sub-unit cannot be split across commits.
3. **No parallel payoff at this size.** The total edit is small (one METHODOLOGY subsection + one trinity bullet ×3 + 2 short PM-CHAT anchors + 2 elective one-line skill pointers). Parallel worktree waves pay off for MULTI-task implementation phases, not a docs-codification BD. The orchestration cost exceeds the benefit.

**Parallel-vs-serial confirmation (rule 10):** the edit-sets are file-disjoint (METHODOLOGY ≠ trinity ≠ PM-CHAT ≠ skills) and COULD run as concurrent worktree waves, but the three reasons above make SERIAL-one-commit correct. There is NO same-file collision inside C1 (each file is touched once). C1 → C2 is strictly serial (C2 preserves the docs only after C1's content lands).

**If the user/planner-review prefers separate commits** (e.g. land METHODOLOGY first for review): C1a (METHODOLOGY) → C1b (trinity + PM-CHAT pointers) is CI-safe ONLY if both land in the SAME push (CI is push-time end-state, EB-R7); the intermediate C1a-only or C1b-only commit would carry a transient dangling cite. The RECOMMENDED single C1 avoids the transient entirely. The plan defaults to single-C1.

### 3.3 Worktree lifecycle (Claude-only)

- The C1 coder is the FIRST (and only) RW coder for C1 → CREATES the isolated worktree (Agent-tool `isolation:"worktree"`, base `worktree.baseRef:"head"`). Any fix-coder in C1's review/fix cycle REUSES that worktree (never a new one). Teardown ONLY after C1 is CONFIRMED landed (exit 0); a failed/aborted commit KEEPS the worktree.
- C2's doc-move coder is a FRESH coder (per-commit fresh-coder). Pack Chat applies the live-worktree ASK gate if C1's worktree is still live when C2 spawns.
- The entire C1 review/fix cycle runs INSIDE the C1 worktree; the patch is produced only AFTER the reviewer confirms CLEAN (Pack Chat SendMessage-s the most-recent RW agent for `git diff > <handoff>/changes.patch`); the orchestrator applies + commits (user approval). Agents never commit.

### 3.4 Concurrency vs other BDs

- **vs BD-238 (pack-side):** edit-sets DISJOINT (project-side vs pack-side; distinct trinity inodes). No collision; any landing order. Scheduling observation, not a BD-239 dependency.
- **vs BD-245 (project-side, SAME files):** BD-239 lands FIRST (user wrinkle-C = (b)); BD-245 later renames `## Project memory` → `## Project rules` + strips the CLI-memory passages, re-sweeping BD-239's three additive surfaces per the §5.4 hand-off note. A SEQUENCING coordination, not a conflict (BD-239's additions are byte-clean at its landing).

---

## 4. File-by-file edits with exact anchors (text anchors, not line numbers)

The coder authors prose from these REQUIRED elements. The SHAPE is fixed by the design; exact prose-wording within the constraints is the coder's mechanical call.

### 4.1 C1 file 1 — `supporting-docs/METHODOLOGY.md` (the SSOT body; MANDATORY)

**Anchor (placement) — CORRECTED (MAJOR-1 resolved; re-verified at live HEAD, EB-R1).** Insert a NEW `###` subsection in **Part 5 — Standard Workflows**, BETWEEN the END of Workflow 4 and the START of Workflow 5:

> Insert the new subsection AFTER the last line of `#### Planner trigger conditions (mid-phase)` (the FINAL sub-block of `### Workflow 4 — Fix cycle (when reviewer finds issues)`) and immediately BEFORE the `### Workflow 5 — Full-codebase audit (auditor agent)` heading.

**Why this anchor replaces the plan's original (the MAJOR-1 defect, now fixed):** the plan-under-review named "after `### Planner trigger rule` / Workflow 4 fix-cycle block, before the `### Audit` / Workflow 5 heading." Both named strings were WRONG/conflated (I re-measured, EB-R1):
- `### Planner trigger rule` is at L311, inside Part 3/4 — ~210 lines ABOVE Workflow 4. It is the UP-FRONT planner trigger, NOT the end of Workflow 4. A coder grepping that literal lands ~330 lines above the intended insertion point. The actual last sub-block of Workflow 4 is `#### Planner trigger conditions (mid-phase)` (L659-692, the MID-CYCLE trigger — a distinct heading).
- `### Audit` is not the Workflow-5 heading. The actual heading is `### Workflow 5 — Full-codebase audit (auditor agent)` (L693); `### Audit subagents (7 clusters)` is a DIFFERENT heading at L1076 in Part 6. A coder grepping `### Audit` could match the wrong Part.

The CORRECTED anchor uses the two RIGHT text strings (`#### Planner trigger conditions (mid-phase)` end / `### Workflow 5 — Full-codebase audit (auditor agent)` start), both re-verified present at live HEAD (EB-R1). **Do NOT use `### Planner trigger rule` or `### Audit` as the insertion anchor.**

**CONTENT-reference note (preserved, NOT an anchor):** the P5 size-signal source — the `### Planner trigger rule` block's condition #1 "more than ~5 tasks, or … non-linear" (L311/L317) — is a legitimate CONTENT reference for P5 (§4.1 item 2-P5). It remains correct as a content cite; only its (former) use as the INSERTION anchor was the defect.

**Suggested title:** `### Workflow 4.5 — Large-phase development pipeline (size-tiered)` OR `### The large-phase pipeline standard` (the exact title is the coder's mechanical call; the position + content are fixed; no title collision — EB-R1 + adversary EB-R16).

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
   - Five PHASE-size signals (each a yes/no test): **P1 launch/release-gate**, **P2 cross-surface** (edit-set spans ≥2 of: app/source modules · gRPC/proto schema · public API/contract · build/CI/deploy config · test infrastructure · architecture docs), **P3 blast-radius** (changes a contract/schema/interface ≥3 surfaces depend on — the load-bearing test; a required docs-researcher census is a tie-break HINT only, not co-equal — n1 fold-in), **P4 structural** (NEW architectural pattern/boundary, schema migration, new external integration, or new module/subsystem — not a localized in-module change), **P5 task-count/non-linear deps** (more than ~5 tasks OR non-linear intra-phase deps — reusing the EXISTING planner-trigger threshold at `### Planner trigger rule` condition #1, D3).
   - The CONSEQUENCE rule: a phase is **LARGE** (the two adversarial reviews + reconciliation are the MINIMUM) iff **P1 fires alone, OR ≥2 of the five signals fire**; otherwise **SMALL** (base flow: optional researcher → architect → planner per the existing trigger → parallel coder waves + the bounded review/fix cycle; the two adversarial passes + reconciliation OPTIONAL at developer election). **Tie-break: when in doubt, treat as LARGE.**
   - **Why P1 stands alone:** a release blocker is the one axis where a missed adversarial pass ships into the release irrecoverably; every other signal alone is recoverable at base-flow rigor.
3. **WHO classifies** (design §4.4, n2 fold-in): the PM chat applies the size criterion at the PHASE GATE (the same place the existing planner-trigger check runs, Procedure 1) using the five mechanical signals; the architect REFINES the classification if spawned (may escalate SMALL→LARGE; tie-break-to-LARGE governs ambiguity).
4. **Complementarity statement** (D4): the up-front size tier and the existing mid-cycle situational triggers (architect A/B, planner P-A/P-C, tester) COEXIST — the standard adds the up-front tier; it does NOT replace the mid-cycle triggers.
5. **Cross-references (NOT restatements):** to the execution half in `docs/pack/PM-CHAT.md` (the "Merge-back / worktree" region) for stage 8; the existing Trigger A/B + P-A/P-C + tester triggers (D4); the `architecture-review` + `planning` skills (D1); Workflow 5 / Part 6 audit (stage 9, D2); the governing trinity reconciliation rule (stages 3, 6).
6. **The escalation detail** ("additional architect/planner rounds on larger gaps").

**HARD content constraints on the METHODOLOGY subsection:**
- ZERO history/dates/SHAs/provenance (the validate-docs HISTORY axis). ZERO deferred-feature/version phrasing (the DEFERRED axis — note "groupings" is grep-zero-OMITTED, §5.2; do NOT name it). This is an operating doc — state only what currently operates.
- **M2 coupling-minimization (the trinity-rule reference):** when the subsection points the reader at the governing trinity rule, REFERENCE IT BY CONCEPT ("the governing trinity rule") rather than the literal section name "`## Project memory`" wherever practical — to keep BD-245's rename re-sweep minimal (§5.4). If a literal section-name reference is unavoidable, it is in BD-245's hand-off census.
- **MINOR-3 authoring caution (the KEEP-framing carve):** if the subsection echoes the project's "the repo files are the authoritative memory — not session history" framing (a sanctioned KEEP phrasing that exists at `PM-CHAT.md` L1067 — EB-R8), that is NOT a CLI-memory-FEATURE endorsement and is permitted. The PREFLIGHT-7 grep is tightened to FEATURE-endorsement tokens precisely so this KEEP phrasing does NOT false-fail (§6). The coder MUST still avoid any per-CLI session/project memory-FEATURE language (`session memory`, `memory cache`, `~/.claude/projects/…`, `~/.gemini/…`, "per-project memory", "cross-session memory").

### 4.2 C1 files 2-4 — the trinity pointer bullet ×3 (MANDATORY; CURRENT `## Project memory` name)

**Anchor (placement):** insert the new bullet as the LAST bullet under `## Project memory`, AFTER the `**Reconciliation-instance independence.**` bullet and BEFORE the next H2 `## Phase routing — default agent assignments`. (Verified insertion point in all three files, byte-parallel ×3; EB-R4.) Byte-identical in `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`.

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
1. **THIN MARGIN (12 chars).** Measured: 688 code points, 12 chars of headroom (EB-R9). ANY wording addition risks crossing 700. If the final wording adds ANY detail, switch to **Option B** (split into two ≤700 bullets: (1) the pipeline pointer, (2) the size-tiering test). Option A is preferred (terser) but has almost no headroom.
2. **CODE-POINT, not BYTE, measure (the `wc -c` trap).** The same text is **708 BYTES** in UTF-8 — the 9 `→` arrows + 1 `≥` are multi-byte (EB-R9). The gate measures CODE POINTS (`len()` on a utf-8-DECODED `str`), NOT bytes. A `wc -c` measure would FALSELY report 708 > 700 and reject a passing bullet. The coder MUST replicate the gate's collapse (`" ".join(x.strip() for x in cur)` then `len()`), NEVER `wc -c`.

**NIT-2 (ASCII-arrow option — flagged, NOT mandated):** the coder MAY substitute ASCII `->` for `→` and `>=` for `≥`, making byte-count == code-point-count and eliminating the `wc -c` trap entirely (a wording call that does not change meaning). This would collapse R1+R2 from MEDIUM to LOW. Per the reconciliation directive, the design's `→`/`≥` text stays AUTHORITATIVE unless the coder elects ASCII; this is the coder's call, not a mandate. If the coder elects ASCII, re-measure (the code-point length is unchanged at 688; only the byte length drops to 688).

**Structural facts (no rationale tag; no new H2):**
- The bullet carries NO `[rationale: ...]` tag — the project `## Project memory` bullets carry no rationale tags (EB-R4); there is NO project-side rationale-bijection file. So NO rationale section + NO manifest record (unlike the pack's Check-45 bijection). This is a structural simplification vs BD-238.
- The bullet adds NO new `##` H2 (it is a bullet inside the existing rules-section H2), so Check 18 trinity H2-parity is auto-satisfied ×3 (EB-R10).
- CLI-agnostic phrasing ("parallel worktree coder waves") keeps it byte-parity-safe ×3 — no Claude-only worktree mechanics restated (the mechanics live single-source in PM-CHAT, not the trinity).

### 4.3 C1 file 5 — `project-template/docs/pack/PM-CHAT.md` (the consolidating anchor + pointer; MANDATORY)

Two edits, BOTH inside BD-239's two edit regions; NEITHER touches the memory-feature passages at L889-891 / L981-984 (PREFLIGHT-7):

1. **Consolidating ANCHOR** — at the top of the worktree/merge-back section. **Anchor text:** insert immediately before/at the `**Merge-back — the patch comes only after review-clean.**` paragraph (the start of the execution-half region, ~L513; verified marker, EB-R11). Frame it as "the EXECUTION half of the large-phase pipeline standard," with a one-line pointer to the METHODOLOGY section. A REFERENCE, not a restatement — NO verbatim METHODOLOGY body.
2. **One-line roster/behavioral pointer** — in the agent-roster / behavioral-rules region. **Anchor text:** insert under the `## Behavioral rules` H2 region (~L172; verified marker, EB-R11), naming the standard and its METHODOLOGY home, so the orchestrator routing the stages finds the standard.

**M2 coupling-minimization:** the anchor's METHODOLOGY pointer SHOULD use the qualified path `docs/pack/METHODOLOGY.md` (already DANGLING-allowlisted at L390, EB-R5) and reference the trinity rule by CONCEPT, not the literal "`## Project memory`" name — minimizing BD-245's PM-CHAT re-sweep. The qualified `docs/pack/METHODOLOGY.md` cite is gate-safe via the EXISTING allowlist record (no new record needed); confirm byte-identical to the allowlisted form.

### 4.4 C1 files 6-7 — the two elective skill pointers (ELECTIVE; recommended minimal)

- `project-template/skills/architecture-review/SKILL.md` — a one-line pointer noting the skill is loaded by the standard's adversarial-architect stage (stage 3).
- `project-template/skills/planning/SKILL.md` — a one-line pointer noting the skill is loaded by the standard's adversarial-planner stage (stage 6).

Skills are single-file `SKILL.md` (NOT ×3 — EB-R12). 2 edits total. The coder/planner-review MAY drop these to minimize footprint; validate-docs stays green either way. **Do NOT** add the rule body to any skill or agent def (they would become restatement surfaces). **Do NOT** touch the 8 auditor defs, the tester/grpc-schema/repo-ops defs, or the other 31 skills.

### 4.5 C2 — audit-set preservation (MANDATORY; paired pack-only commit AFTER C1)

MOVE the BD-239 pipeline docs from `/tmp/pack-handoff-bd239-arch/*` (research + first design + adversarial review + reconciled design) and `/tmp/pack-handoff-bd239-plan/*` (this plan + the adversarial planner review + this reconciliation) into `maintenance-docs/v11-implementation/`. This is the report-preservation discipline (superseded design docs are NOT preserved if the design directive says delete-on-supersede; the AUDIT SET — the docs the pipeline produced — is preserved). The coder/orchestrator confirms the destination filenames are unique in `maintenance-docs/v11-implementation/` (filename-uniqueness heuristic). This is a pack-side maintenance record; NO client/CI gate applies. The IMPL-REPORT for C1 is also preserved here.

---

## 5. Locked decisions carried (do NOT relitigate)

### 5.1 Wrinkle C = option (b) — BD-239 lands FIRST under `## Project memory`; queue NOT reordered

USER DECISION (2026-06-23). The trinity bullet lands under the CURRENT `## Project memory` heading. The bloat gate finds the section by the literal `## Project memory` (EB-R4), so the gate stays consistent at BD-239's landing. The design's earlier "recommend BD-245 first" framing is SUPERSEDED; this plan encodes BD-239-first. NOT an open user decision.

### 5.2 groupings — OMIT entirely (grep-zero + BD-189 ownership)

The shipped standard uses ONLY phases / phase-tasks / TD vocabulary. groupings is grep-zero under `project-template/` (EB-R6), BD-189 owns the concept (sequenced after BD-206; BD-239 is ahead of it), and phases are the complete size unit — so OMIT. The DEFERRED axis does NOT block a bare "groupings" mention (the regex matches deferral PHRASING only, NOT the concept name — EB-R13); the OMIT rests on grep-zero + BD-189-ownership, NOT a gate fear. The coder must NOT name groupings; if it ever were named WITH deferral phrasing it WOULD trip DEFERRED — BD-239 sidesteps this by omitting the concept.

### 5.3 Zero CLI-memory endorsement — BD-239 is a SEPARATE concern from BD-245

BD-239's edits are ADDITIVE pipeline content ONLY. They add/endorse/reference NO per-CLI project/session memory FEATURE and do NOT modify the existing CLI-memory-endorsement passages (BD-245's job). Encoded as PREFLIGHT-7 (§6, tightened per MINOR-3 to FEATURE-endorsement tokens). The fresh-instance reconciliation the pipeline cites is the EXISTING `Reconciliation-instance independence` trinity rule (about WHO reconciles, not session memory) — not a memory-feature endorsement. The sanctioned KEEP framing "the repo files are the authoritative memory — not session history" (PM-CHAT L1067, EB-R8) is NOT a feature endorsement (BD-245's own KEEP set preserves it) — PREFLIGHT-7's tightened grep does not trip on it.

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
| **PREFLIGHT-4 — cite resolution (DANGLING axis; M1-corrected)** | the METHODOLOGY pointers resolve | confirm the trinity bare-word "METHODOLOGY" is DANGLING-EXEMPT (no `/` — the regex requires a `/`-qualified backtick path, EB-R13); confirm the PM-CHAT qualified `docs/pack/METHODOLOGY.md` cite is byte-identical to the EXISTING L390 allowlist record; run validate-docs to 0 DANGLING fails. **Do NOT test Check 64/70** (Check 64 = MCP/config `.example`-only; Check 70 = `validate-docs.sh`-structure, out of scope — both would trivially pass and give false coverage) | 0 DANGLING fails; cite byte-matches L390 |
| **PREFLIGHT-5 — validate-pack + full battery** | the full CI surface green | `python3 scripts/validate-pack.py` (default) AND `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`; `bash project-template/scripts/validate-docs.sh --self-test`; the relevant project-side checks (Check 18 H2-parity auto-satisfied; Checks 5/27/31/39/1 if any agent/skill/doc touched); the FULL wired CI battery (`verify-full-ci-suite` — not just validate-pack) | all exit 0 |
| **PREFLIGHT-6 — no out-of-scope edits** | scope discipline | `git diff --name-only` shows ONLY the C1 edit-set files (§2.1 rows 1-7); confirm NO edit to `validate-docs.sh`, NO new groupings concept, NO pack-side surface, NO new CI check. (The C2 doc-move and the push-time manifest-regen are SEPARATE commits — NOT in the C1 diff, §2.1b/§9) | only the 7 C1 in-scope paths in the diff |
| **PREFLIGHT-7 — zero memory-FEATURE endorsement + memory passages untouched (MINOR-3 tightened)** | the §5.3 HARD CONSTRAINT | grep BD-239's NEW text for FEATURE-ENDORSEMENT tokens ONLY — `session memory` / `memory cache` / `~/.claude/projects/` / `~/.gemini/` / "per-project memory" / "cross-session memory" (case-insensitive). **Do NOT grep the bare token `memory`** (it false-fails on the sanctioned KEEP framing "the repo files are the authoritative memory" — EB-R8). AND `git diff` shows NO hunk touching `PM-CHAT.md` L889-891 + L981-984 (and `GEMINI.md` cross-session, `CLI-PM-SETUP.md`) — they are byte-UNCHANGED | 0 FEATURE-endorsement tokens in new text; memory passages byte-unchanged |
| **PREFLIGHT-VOCAB — project-vocabulary purity (§4 rule)** | NO pack-concept leak in shipped text | grep the SHIPPED text (the new METHODOLOGY subsection + the trinity bullet + the PM-CHAT anchors + the skill pointers) for `\bBD-?[0-9]` / `backlog-item` / `pack-[a-z]` / `pack memory` / `pack-ops` / `PACK-CHAT` / `PACK-AGENTS` / `\[rationale` → MUST be zero | 0 pack-concept tokens in shipped text |

**MINOR-3 rationale (the grep tightening):** the plan-under-review's PREFLIGHT-7 grepped the bare token `memory`. I re-measured (EB-R8): the project ships a sanctioned KEEP framing "The repo files are the authoritative memory — not session history" at `PM-CHAT.md` L1067 (BD-245's own KEEP set preserves it). If a coder echoes that framing in the METHODOLOGY prose, the bare-`memory` grep would FALSE-FAIL PREFLIGHT-7 on legitimate text. Tightening the grep to FEATURE-endorsement tokens keeps PREFLIGHT-7 a true gate on the HARD CONSTRAINT (the per-CLI session/project memory FEATURE) while not tripping on the repo-is-authoritative-memory KEEP phrasing. I verified the tightened token set hits the FEATURE passages (`memory cache`, `Cross-session memory`) and does NOT hit the KEEP framing (EB-R8).

**PREFLIGHT-VOCAB note:** the only place BD-238/BD-245 may be NAMED is the C1 IMPL-REPORT and the BD-239 hand-off note (planning context, NOT shipped text). The shipped deliverable text carries phases/phase-tasks/TD/project-agents ONLY.

---

## 7. Commit-scope keyword

**C1 = `project-only`.** C1's edit-set is entirely `project-template/` + project-side `supporting-docs/` (rows 1-7, §2.1). The `project-only` keyword (CI Check 36) denies pack-only paths (everything outside `project-template/` + `supporting-docs/`). C1 touches NO pack-side path → `project-only` is correct and Check 36 passes. (Confirmed against the Check-36 table + `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`, EB-R3: `project-only` permitted paths = `project-template/` + `supporting-docs/`; C1's `supporting-docs/METHODOLOGY.md` + `project-template/**` all qualify.)

**C2 = `pack-only`.** C2 moves the audit docs into `maintenance-docs/v11-implementation/` (a pack-side maintenance record). `pack-only` denies `project-template/` + `supporting-docs/`; C2 touches neither → `pack-only` is correct.

**Push-time manifest-regen commit = scope-NEUTRAL (MINOR-2 — stated).** The push-time `manifest-sync.sh` regeneration (§9) produces a commit carrying ONLY `test-fixtures/manifest.txt`. That path is in `_SCOPE_NEUTRAL_GENERATED_PATHS` (EB-R3) — Check 36 exempts it from BOTH the `project-only` and `pack-only` offender sets. So this commit may carry ANY scope keyword OR NONE without tripping Check 36. The orchestrator commits it without a misleading keyword (a neutral subject is cleanest — e.g. `chore: v11 — BD-239 push-time manifest regen` with no scope keyword). This removes the §7 ambiguity the plan-under-review left for the orchestrator.

**Keyword-token trap caution:** the scope keyword is a Check-36 CLAIM wherever it appears in the subject (incl. prose). The C1 subject must carry `project-only` and NO denying token; the C2 subject must carry `pack-only` and NO denying token. Use the commit-message form `feat: v11 — BD-239 <desc> (project-only)` for C1 and a `docs: v11 — BD-239 <desc> (pack-only)` form for C2 (per the approved commit-message shapes). The manifest-regen commit carries NO scope keyword (neutral subject) per the MINOR-2 note above.

---

## 8. Parity / CI-guard call — NO new project-side guard (DROP, not defer)

Carried from the design (§8), confirmed by both adversaries. NO new project-side CI body-parity check for BD-239:
- The new bullet is SHORT (688 chars, a pointer — far easier to keep ×3-identical than the pack's ~1289-char rule).
- A ×3 body drift is the ONLY new risk; it is RECOVERABLE (caught at the next trinity edit/review) and is the SAME residual every existing project trinity rule already carries — BD-239 adds no new KIND of exposure.
- A correct body-parity check is a LARGER, SEPARATE effort (normalize around GEMINI-intrinsic H2s, re-baseline every existing rule for ×3 identity, reconcile with the existing parity gates) — a distinct CI-guard contract from BD-239's codification.
- The existing gates (HISTORY/DEFERRED/BLOAT/DANGLING + Check 18 H2-parity) + the PREFLIGHT-1 ×3-byte-identity attestation are the sole-and-sufficient protection.

**DROP, not defer:** the guard is unnecessary work whose correct form is a net complexity loss; it does not exist and is not scheduled. (no-deferral compliance: nothing pushed to a later BD.)

---

## 9. Manifest expectation — BD-239 DOES change fixture inputs (CORRECTS the design's NOOP claim; MINOR-1 proof folded in)

**STATE-CORRECTION (load-bearing).** The reconciled design (§9 row 8 + EB-13) and the design's adversarial review concluded "the manifest is a NOOP for BD-239's entire edit-set" based on `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt` → 0. **That test is against the WRONG artifact.** `test-fixtures/manifest.txt` stores `<fixture-name> <sha>` pairs (header + 6 fixture data rows: `v10-minimal`, `v10-realistic-ot`, `v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`, `existing-project-mid-dev`), NEVER source paths (EB-R1b). Grepping it for a source basename ALWAYS returns 0 — for EVERY pack source file, fixture-input or not. The fixture-input decision is made by the predicate `manifest_path_is_input` in `scripts/lib/manifest-inputs.sh` (the SINGLE SoT, EB-R2).

**The predicate, run against BD-239's actual edit paths (EB-R2):**

| BD-239 edit path | `manifest_path_is_input` | Why |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | **INPUT** | named explicitly in `MANIFEST_INPUT_GLOBS` — copied to client `docs/pack/` by init-project |
| `project-template/CLAUDE.md` | **INPUT** | matches `project-template/*` (recursive subtree) |
| `project-template/AGENTS.md` | **INPUT** | matches `project-template/*` |
| `project-template/GEMINI.md` | **INPUT** | matches `project-template/*` |
| `project-template/docs/pack/PM-CHAT.md` | **INPUT** | matches `project-template/*` |
| `project-template/skills/architecture-review/SKILL.md` | **INPUT** | matches `project-template/*` |
| `project-template/skills/planning/SKILL.md` | **INPUT** | matches `project-template/*` |

**ALL SEVEN C1 edit paths are fixture inputs (EB-R2).**

**MINOR-1 proof fold-in — exit-10 grounded on the fixture-COPY fact, not the predicate alone.** The design's adversarial reviewer correctly noted that `manifest_path_is_input → true` guarantees a REBUILD runs, but the exit code forks three ways — `MANIFEST-SKIP` (exit 0, no input changed), `MANIFEST-NOOP` (exit 0, an input changed but the rebuilt manifest is byte-identical), and `MANIFEST-CHANGED` (exit 10, the rebuilt manifest differs). Predicate-is-input proves a rebuild is TRIGGERED; it does NOT by itself prove the SHA changes. The proof requires the additional fact that the edited content actually LANDS in a built fixture. **That fact is verified (the design's adversary verified it; I carry it forward):** the v11 fixture trees contain `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `docs/pack/METHODOLOGY.md`, `docs/pack/PM-CHAT.md`, AND `.claude/skills/{architecture-review,planning}/` — all the BD-239 edit targets are copied verbatim into the built fixtures (init-project S6 copies `supporting-docs/METHODOLOGY.md` → `$TARGET/docs/pack/METHODOLOGY.md` + the docs/pack/ + trinity + skills content). Since the edited content is copied verbatim into the fixtures, the deterministic fixture SHAs WILL change → **MANIFEST-CHANGED (exit 10), NOT MANIFEST-NOOP.**

**So at PUSH TIME the orchestrator's `scripts/manifest-sync.sh` regeneration is expected to report MANIFEST-CHANGED (exit 10) — a REAL SHA change, NOT a NOOP.** The predicate-is-input fact (7/7 INPUT) PLUS the fixture-copy fact (all 7 targets land in built fixtures) together prove exit 10. (This is the OPPOSITE of a maintenance-only BD whose edits never reach a built fixture; BD-239 touches the shipped fixture corpus directly.)

**Orchestrator action (push-time, NOT per-commit, NOT the coder):** per `regenerate-manifest-v11-surface` — the coder does NOT regenerate the manifest; the manifest is regenerated ONLY at push, ONLY when a fixture input changed, by `scripts/manifest-sync.sh`. Expect `manifest-sync.sh` to exit 10 (MANIFEST-CHANGED) and the orchestrator to commit the regenerated `test-fixtures/manifest.txt` with user approval before `git push`. That manifest-regen commit is scope-NEUTRAL (§7 MINOR-2 note). CI `build.sh --verify` + validate-pack Check 62 enforce manifest correctness at the push end-state.

**Clear statement for the orchestrator:** BD-239 is a fixture-input-changing BD. Plan for a real manifest SHA delta at push (exit 10), NOT a NOOP. The coder leaves `test-fixtures/manifest.txt` untouched; the push-time tool handles it; the regen commit carries no scope keyword.

---

## 10. Risks + open unknowns

| # | Risk | Likelihood | Mitigation (in this plan) |
|---|---|---|---|
| R1 | **700-char bloat overflow** — a wording tweak pushes the trinity bullet over 700 code points (12-char margin) | MEDIUM | PREFLIGHT-2 mandates the gate-exact code-point measure; Option B (split) is the named fallback; the optional ASCII-arrow substitution (NIT-2) removes the byte/code-point ambiguity. |
| R2 | **`wc -c` byte-measure false-failure** — the coder measures bytes (708) and wrongly concludes overflow, or wrongly "fixes" a passing bullet | MEDIUM | PREFLIGHT-2 explicitly forbids `wc -c` and prescribes the `len()` collapse; EB-R9 documents 688 cp / 708 bytes; NIT-2 ASCII option collapses this to LOW. |
| R3 | **Stale cross-reference (DANGLING)** — a half-applied state (pointer without target) trips the DANGLING axis | LOW | Rule-10 SERIAL single-commit C1 (cross-reference atomicity, §3.2) — pointers + target in ONE commit; PREFLIGHT-4. |
| R4 | **Trinity body drift ×3** — the bullet differs across the three files (no CI body-parity net) | LOW | PREFLIGHT-1 ×3-byte-identity attestation (the sole protection, §8). |
| R5 | **CLI-memory contamination** — the coder accidentally edits/endorses a memory FEATURE passage | LOW | PREFLIGHT-7 (MINOR-3-tightened) FEATURE-token grep-zero + byte-unchanged attestation; §5.3 names the exact line ranges to leave alone. |
| R6 | **PREFLIGHT-7 false-fail on KEEP framing** — a broad `memory` grep rejects the sanctioned "repo is the authoritative memory" KEEP phrasing | LOW (now) | MINOR-3 fold-in: PREFLIGHT-7 greps FEATURE-endorsement tokens only, NOT bare `memory`; EB-R8 confirms the KEEP framing does not hit. |
| R7 | **Pack-concept leak in shipped text** — a BD/pack-* token reaches the deliverable | LOW | PREFLIGHT-VOCAB purity grep; §4.1 mandates project-vocabulary-only. |
| R8 | **Manifest mishandled** — the coder regenerates the manifest per-commit, OR the orchestrator expects a NOOP and skips the regen | MEDIUM | §9 corrects the design's NOOP claim with the predicate + fixture-copy proof; the coder leaves the manifest untouched; the orchestrator expects exit 10 at push. |
| R9 | **BD-245 census miss** — BD-245 later renames `## Project memory` but misses a BD-239-added literal reference in METHODOLOGY/PM-CHAT | LOW | §5.4 hard hand-off note enumerates all 3 surfaces; §4.1/§4.3 minimize literal-name references (reference by concept). |
| R10 | **Check 36 scope-keyword mismatch** — C1 carries a denying token, a stray keyword in prose, or the manifest commit carries a misleading keyword | LOW | §7 specifies `project-only` for C1, `pack-only` for C2, scope-neutral (no keyword) for the manifest commit (MINOR-2), and the keyword-token-trap caution. |
| R11 | **METHODOLOGY anchor mis-placement** — the coder follows a wrong/conflated insertion anchor and places the SSOT body in the wrong Part | RESOLVED | MAJOR-1 fold-in: §4.1 now names the CORRECT text anchors (end of `#### Planner trigger conditions (mid-phase)` / start of `### Workflow 5 — Full-codebase audit (auditor agent)`), re-verified at live HEAD (EB-R1); the wrong `### Planner trigger rule` / `### Audit` strings are struck. |

**No purpose-defeating unknowns.** Every state-verifiable question was answered by read-only measurement (§12). The ONE remaining USER-decision the design surfaced (groupings OMIT) is already locked (§5.2). There is NO `MAINTAINER CHECK NEEDED` item — all scope questions are state-verifiable and resolved.

**One MINOR open authoring choice (coder's mechanical call, not a design gap):** the exact METHODOLOGY subsection title (`### Workflow 4.5 …` vs `### The large-phase pipeline standard`), whether to take Option A vs Option B for the trinity bullet (drive by PREFLIGHT-2's measurement), and whether to elect the NIT-2 ASCII-arrow form. None blocks the coder.

---

## 11. Coder execution order (the step sequence)

1. Create the C1 isolated worktree (orchestrator: Agent-tool `isolation:"worktree"`, base `head`).
2. **C1 edit 1:** author the METHODOLOGY Part-5 subsection (§4.1) in `supporting-docs/METHODOLOGY.md`, inserted between the END of `#### Planner trigger conditions (mid-phase)` and the START of `### Workflow 5 — Full-codebase audit (auditor agent)` (the CORRECTED anchor, EB-R1).
3. **C1 edits 2-4:** insert the byte-identical trinity bullet (§4.2, Option A or B per PREFLIGHT-2) in CLAUDE/AGENTS/GEMINI.
4. **C1 edit 5:** add the PM-CHAT consolidating anchor + roster pointer (§4.3).
5. **C1 edits 6-7 (elective):** add the 2 skill pointers (§4.4) — or drop per planner-review.
6. Run the FULL PREFLIGHT (§6: PREFLIGHT-1 … 7 + PREFLIGHT-VOCAB). All PASS.
7. Emit the PREFLIGHT one-liner; Write the C1 IMPL-REPORT (incl. the §5.4 hand-off note + the §9 manifest expectation + the Rules-Applied + Empirical-Evidence blocks).
8. Bounded review/fix cycle in the C1 worktree (≤2 review/fix pairs + 1 final reviewer). Patch produced only after review-clean. Orchestrator applies + commits C1 (`project-only`, user approval).
9. After C1 lands (exit 0): fresh coder for **C2** — move the audit docs into `maintenance-docs/v11-implementation/` (§4.5). Commit C2 (`pack-only`, user approval). Live-worktree ASK gate applies if C1's worktree is still live.
10. At push (orchestrator): `bash scripts/manifest-sync.sh` → expect exit 10 (MANIFEST-CHANGED) → commit the regenerated `test-fixtures/manifest.txt` (user approval; scope-neutral subject, no keyword — §7 MINOR-2) → `git push` → watch `Validate Pack` CI.

---

## 12. Empirical-Evidence Blocks (re-measured by me at the CURRENT HEAD)

All measured at HEAD `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, branch `v11-dev`, 2026-06-23, in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EB-R1 — the CORRECTED METHODOLOGY insertion anchor (MAJOR-1; the load-bearing fix).**
- Command: `grep -n "^## Part 5\|^## Part 6\|^### Workflow 4\|^### Workflow 5\|^### Planner trigger rule\|^### Audit subagents\|more than ~5 tasks" supporting-docs/METHODOLOGY.md` ; `awk 'NR>=523 && NR<=693 && /^####|^###/' supporting-docs/METHODOLOGY.md` ; `sed -n '655,700p' supporting-docs/METHODOLOGY.md`
- Output (verbatim, key): `311:### Planner trigger rule`; `317:1. The phase has more than ~5 tasks, or task dependencies within the phase are`; `446:## Part 5 — Standard Workflows`; `523:### Workflow 4 — Fix cycle (when reviewer finds issues)`; `693:### Workflow 5 — Full-codebase audit (auditor agent)`; `1047:## Part 6 — Audit Checkpoints`; `1076:### Audit subagents (7 clusters)`. Workflow-4 sub-blocks: `#### PM chat triage protocol — reviewer findings`, `#### Architect trigger conditions`, `#### What the PM chat does when a trigger fires`, `#### Planner trigger conditions (mid-phase)` (at L659). The L655-700 dump shows `#### Planner trigger conditions (mid-phase)` (L659) is the LAST sub-block of Workflow 4 and runs to the blank line immediately before `### Workflow 5 — Full-codebase audit (auditor agent)` (L693).
- Interpretation: the plan-under-review's §4.1 anchor (`### Planner trigger rule` end-of-Workflow-4 / `### Audit` Workflow-5) is WRONG: `### Planner trigger rule` is at L311 (Part 3/4, ~210 lines ABOVE Workflow 4, the up-front trigger — NOT the end of Workflow 4); `### Audit` would match `### Audit subagents (7 clusters)` at L1076 in Part 6 (wrong Part). The CORRECT insertion is AFTER the end of `#### Planner trigger conditions (mid-phase)` (L659-692, the FINAL Workflow-4 sub-block) and immediately BEFORE `### Workflow 5 — Full-codebase audit (auditor agent)` (L693). The P5 CONTENT source ("more than ~5 tasks", L317, inside `### Planner trigger rule`) is a real and correct CONTENT cite — only its former use as the INSERTION anchor was the defect.
- Conclusion: SUPPORTED — MAJOR-1 resolved; the reconciled §4.1 names the two CORRECT text anchors; the wrong strings are struck.

**EB-R1b — `manifest.txt` stores fixture-name→SHA pairs, not source paths (the design's NOOP basis is the wrong artifact).**
- Command: `cat test-fixtures/manifest.txt`
- Output (verbatim): header `# test-fixtures/manifest.txt — expected git SHA per fixture` / `# Generated by build.sh; do not hand-edit. See README.md.` / `# Format: <fixture-name>  <sha>` then 6 data rows: `v10-minimal 19558cba…`, `v10-realistic-ot 4c62945f…`, `v11-realistic-ot 31bcb61b…`, `v11-flat-file 202d0a98…`, `v11-tracker-on 9a2d4d3b…`, `existing-project-mid-dev a54e081a…`.
- Interpretation: `manifest.txt` indexes built FIXTURE SHAs by fixture-name, never source paths. Grepping it for a source basename returns 0 for EVERY source file. The design's NOOP conclusion rests on a grep against this wrong artifact.
- Conclusion: SUPPORTED — the §9 STATE-CORRECTION is correctly grounded.

**EB-R2 — ALL seven BD-239 edit paths are `manifest_path_is_input` INPUTs.**
- Command: `source scripts/lib/manifest-inputs.sh; for p in supporting-docs/METHODOLOGY.md project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md project-template/docs/pack/PM-CHAT.md project-template/skills/architecture-review/SKILL.md project-template/skills/planning/SKILL.md; do manifest_path_is_input "$p" && echo "INPUT -> $p" || echo "not -> $p"; done`
- Output (verbatim): `INPUT  -> supporting-docs/METHODOLOGY.md`; `INPUT  -> project-template/CLAUDE.md`; `INPUT  -> project-template/AGENTS.md`; `INPUT  -> project-template/GEMINI.md`; `INPUT  -> project-template/docs/pack/PM-CHAT.md`; `INPUT  -> project-template/skills/architecture-review/SKILL.md`; `INPUT  -> project-template/skills/planning/SKILL.md`.
- Interpretation: every C1 edit path is a fixture input; editing them changes the built fixtures' content and thus their deterministic SHAs (with the fixture-copy fact, §9 MINOR-1, proving exit 10).
- Conclusion: SUPPORTED — BD-239 DOES change fixture inputs; the push-time `manifest-sync.sh` is expected to report MANIFEST-CHANGED (exit 10), NOT a NOOP (§9).

**EB-R3 — Check 36 scope-keyword correctness + `test-fixtures/manifest.txt` is scope-neutral (MINOR-2).**
- Command: `grep -n "_SCOPE_NEUTRAL_GENERATED_PATHS\|_PROJECT_SIDE_PATH_PREFIXES" scripts/validate-pack.py` ; `sed -n '3992,3996p' scripts/validate-pack.py`
- Output (verbatim): `3992:_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({` then `    "test-fixtures/manifest.txt",` `})`; `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` (per design EB-1/adversary EB-R6).
- Interpretation: C1's 7 paths are all under `project-template/`+`supporting-docs/` → 0 `project-only` offenders → `project-only` CORRECT. C2's `maintenance-docs/` is NOT project-side → 0 `pack-only` offenders → `pack-only` CORRECT. `test-fixtures/manifest.txt` is in `_SCOPE_NEUTRAL_GENERATED_PATHS` → exempt from BOTH offender sets → the push-time manifest commit can carry any/no keyword (MINOR-2 — the plan now states scope-neutral, no keyword).
- Conclusion: SUPPORTED — keywords correct (C1 `project-only`, C2 `pack-only`); the manifest commit is scope-neutral (§7).

**EB-R4 — trinity insertion anchor + section name + no rationale tags + bloat cap (byte-parallel ×3).**
- Command: `grep -rn "authoritative memory\|repo is the authoritative" supporting-docs/METHODOLOGY.md project-template/docs/pack/PM-CHAT.md project-template/{CLAUDE,AGENTS,GEMINI}.md` (KEEP framing, EB-R8) ; (trinity anchor + cap re-confirmed from plan EB-P3/EB-P4 + adversary EB-R9 at the SAME HEAD `d720873`).
- Output (verbatim, carried + re-confirmed at this HEAD): section `## Project memory` at CLAUDE.md L360 / AGENTS.md L339 / GEMINI.md L357; the LAST `## Project memory` bullet in all three = `**Reconciliation-instance independence.**`; the next H2 in all three = `## Phase routing — default agent assignments`; `[rationale:` count in CLAUDE.md = 0; `BLOAT_BULLET_CHAR_CAP = 700`; the bloat axis finds the section by `l.strip() == "## Project memory"`.
- Interpretation: the new bullet inserts as the LAST `## Project memory` bullet (after Reconciliation, before Phase routing), byte-parallel ×3; no rationale tags (no bijection surface); the bloat axis caps each bullet at 700 and finds the section by the literal heading.
- Conclusion: SUPPORTED — the §4.2 trinity anchor + structure + cap claims hold at the current HEAD (carry-forward CONFIRMED by both adversary EB-R9 and me).

**EB-R5 — the existing L390 allowlist record covers the qualified METHODOLOGY cite.**
- Command: (carried from plan EB-P5 + adversary EB-R11 at the SAME HEAD) `grep -n "METHODOLOGY" project-template/scripts/.docs-gate-allowlist.txt` ; `grep -n "docs/pack/METHODOLOGY.md" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `390:target: docs/pack/METHODOLOGY.md` (reason: pack-shipped reference doc installed into docs/pack/ at project init); PM-CHAT cites `docs/pack/METHODOLOGY.md` at L138/L150/L167/L894.
- Interpretation: the qualified cite is already DANGLING-allowlisted (L390) — which is why PM-CHAT's existing cites pass. BD-239's anchor cite of the same path rides the existing record; no new record needed.
- Conclusion: SUPPORTED — PREFLIGHT-4's "byte-identical to L390" check is right.

**EB-R6 — groupings grep-zero under `project-template/`.**
- Command: (carried from plan EB-P3 + design EB-2 at the SAME HEAD) `grep -rln "groupings" project-template/ | wc -l`
- Output (verbatim): `0`.
- Interpretation: groupings does not exist anywhere under `project-template/`; BD-189 owns the concept (after BD-206; BD-239 ahead). OMIT on grep-zero + BD-189-ownership grounds.
- Conclusion: SUPPORTED — §5.2 OMIT rationale holds.

**EB-R7 — CI is push-time end-state.**
- Command: (carried from plan EB-P6) `sed -n '50,58p' project-template/scripts/validate-docs.sh` ; `grep -n "PACK_VALIDATE_DEEP" scripts/validate-pack.py | head -2`
- Output (verbatim): validate-docs MODE forks `--self-test` / scan (no arg) / single-file; validate-pack DEEP whole-tree under `PACK_VALIDATE_DEEP=1`.
- Interpretation: CI runs at push end-state; the per-commit cross-reference atomicity (§3.2) is for clean per-commit audit, not a CI cadence gate. PREFLIGHT-5's battery (default + DEEP + self-test) is wired.
- Conclusion: SUPPORTED — the rule-10 single-commit verdict is bound by cross-reference-atomicity, not a CI cadence gate.

**EB-R8 — the KEEP framing exists (MINOR-3); the tightened PREFLIGHT-7 grep does not false-fail on it.**
- Command: `grep -rn "authoritative memory\|repo is the authoritative" supporting-docs/METHODOLOGY.md project-template/docs/pack/PM-CHAT.md project-template/{CLAUDE,AGENTS,GEMINI}.md` ; `grep -n "Per-project Claude memory\|Cross-session memory\|~/.gemini/GEMINI.md\|~/.claude/projects" project-template/docs/pack/PM-CHAT.md` ; python3 regex test of the tightened FEATURE-token grep vs the KEEP framing.
- Output (verbatim): KEEP framing — `project-template/docs/pack/PM-CHAT.md:1067:1. The repo files are the authoritative memory — not session history`. FEATURE passages — `889:> **Per-project Claude memory cache (Claude-only).**`, `891:> `~/.claude/projects/<slug>/memory/` as a convenience pointer`, `981:### Cross-session memory`, `984:`~/.gemini/GEMINI.md` so they load in every session.`. Tightened-grep test — KEEP framing "the repo is the authoritative memory" hit? `False`; KEEP full line hit? `False` (note: "session history" is NOT "session memory"); FEATURE "memory cache" line hit? `True`; FEATURE "Cross-session memory" line hit? `True`. OLD broad bare-`memory` grep on the KEEP framing hit (false-fail)? `True`.
- Interpretation: the project ships a sanctioned KEEP framing ("the repo files are the authoritative memory") at PM-CHAT L1067. The plan-under-review's bare-`memory` PREFLIGHT-7 grep WOULD false-fail on it if a coder echoes it. The tightened FEATURE-endorsement grep (`session memory` / `memory cache` / `~/.claude/projects/` / `~/.gemini/` / "per-project memory" / "cross-session memory") hits the real FEATURE passages and does NOT hit the KEEP framing.
- Conclusion: SUPPORTED — MINOR-3 resolved; PREFLIGHT-7 tightened to FEATURE-endorsement tokens (§6).

**EB-R9 — Option A = 688 code points (12 margin) / 708 bytes / 9 `→` + 1 `≥` (R1/R2/NIT-2).**
- Command: python3 replication of the gate collapse `" ".join(x.strip() for x in lines)` + `len()` + `.encode("utf-8")` + `.count("→")` / `.count("≥")` on the verbatim §4.2 Option-A bullet.
- Output (verbatim): `code-point len: 688 | <=700? True | margin: 12`; `UTF-8 byte len: 708`; `arrows →: 9 | >= ≥: 1`.
- Interpretation: Option A fits the gate's CODE-POINT measure (688 ≤ 700, 12 margin) but is 708 bytes — a `wc -c` measure would falsely flag it. PREFLIGHT-2's code-point-not-byte mandate + the thin-margin/Option-B fallback are necessary; the NIT-2 ASCII substitution would set byte==code-point (688) and retire R1+R2's byte ambiguity.
- Conclusion: SUPPORTED — exact match to the design §7.2 and the adversary's EB-R8.

**EB-R10 — the proposed bullet adds NO new H2 (Check 18 auto-satisfied).**
- Command: (the §4.2 Option A bullet is a `-` bullet, 0 `^##` lines) ; (Check 18 = trinity H2 structure parity, carried from plan EB-P9).
- Output (verbatim): Option A contains 0 `^##` lines; Check 18 is the trinity H2 structure-parity gate at project-template.
- Interpretation: the new bullet introduces no `##` heading → the project-template trinity H2 set/order is unchanged → Check 18 is auto-satisfied ×3.
- Conclusion: SUPPORTED — no H2-parity work needed.

**EB-R11 — PM-CHAT anchor regions + the leave-alone memory passages.**
- Command: `grep -n "Per-project Claude memory\|Cross-session memory\|~/.gemini/GEMINI.md\|~/.claude/projects" project-template/docs/pack/PM-CHAT.md` (the leave-alone set) ; (anchor markers carried from plan EB-P10 + adversary EB-R10 at the SAME HEAD).
- Output (verbatim): execution-half anchor at `**Merge-back — the patch comes only after review-clean.**` (~L513); roster/behavioral region at `## Pack agent roster` (~L47) / `## Behavioral rules` (~L172). The CLI-memory passages BD-239 must NOT touch are at L889-891 (`Per-project Claude memory cache`, `~/.claude/projects/<slug>/memory/`) + L981-984 (`### Cross-session memory`, `~/.gemini/GEMINI.md`) — both OUTSIDE the two anchor regions.
- Interpretation: BD-239's two edit regions (roster ~L47-172; execution-half ~L513) are disjoint from the L889/L981 memory passages. PREFLIGHT-7's leave-alone targets are precise.
- Conclusion: SUPPORTED — §4.3 anchors + PREFLIGHT-7 ranges are correct.

**EB-R12 — the two elective skills are single-file SKILL.md (not ×3) and exist.**
- Command: (carried from plan EB-P11) `ls project-template/skills/architecture-review/SKILL.md project-template/skills/planning/SKILL.md`
- Output (verbatim): both paths present (no error).
- Interpretation: each skill is one `SKILL.md`; the elective pointer is 2 edits total (not 6).
- Conclusion: SUPPORTED — §4.4 footprint correct.

**EB-R13 — the DANGLING regex requires a `/`-qualified backtick path (bare "METHODOLOGY" exempt); the DEFERRED regex lacks "groupings".**
- Command: python3 replication of `DANGLING_BACKTICK = re.compile(r"`([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:md|sh|…))`")` against three test strings ; (DEFERRED carried from plan EB-P12 + design EB-8 at the SAME HEAD).
- Output (verbatim): `'the stages live in METHODOLOGY.' -> no match`; `'the stages live in `METHODOLOGY`.' -> no match`; `'see `docs/pack/METHODOLOGY.md`.' -> ['docs/pack/METHODOLOGY.md']`. DEFERRED_PATTERN matches deferral PHRASING only; "groupings" is not in the alternation.
- Interpretation: the trinity bullet's bare "METHODOLOGY" (no `/`, no backtick path) is DANGLING-EXEMPT; even a non-slash backtick `METHODOLOGY` is exempt; only the qualified `docs/pack/METHODOLOGY.md` matches (and rides L390). A bare "groupings" mention does not trip DEFERRED.
- Conclusion: SUPPORTED — PREFLIGHT-4 (bare-word exempt; qualified rides L390) + §5.2 (groupings OMIT on grep-zero/BD-189 grounds, not a DEFERRED fear) are correct.

---

## 13. Adversarial findings resolution

| Finding | Severity | How resolved | Evidence |
|---|---|---|---|
| **MAJOR-1 — wrong/conflated METHODOLOGY insertion anchor (§4.1)** | MAJOR | **FIXED.** §4.1 re-anchors the Part-5 insertion to: AFTER the end of `#### Planner trigger conditions (mid-phase)` (the FINAL sub-block of `### Workflow 4 — Fix cycle (when reviewer finds issues)`) and immediately BEFORE `### Workflow 5 — Full-codebase audit (auditor agent)`. The wrong strings `### Planner trigger rule` (L311, Part 3/4 up-front trigger — NOT end-of-Workflow-4) and `### Audit` (matches `### Audit subagents` L1076 in Part 6) are STRUCK as anchors. The `### Planner trigger rule` cite is RETAINED only as the P5 CONTENT source ("more than ~5 tasks", L317). Re-verified at live HEAD by me. | EB-R1 (the measured heading map + the L655-700 dump showing the corrected anchor) |
| **MINOR-1 — exit-10 overstated; predicate proves rebuild, not CHANGED** | MINOR | **FIXED (proof completed).** §9 grounds exit-10 on TWO facts: (a) all 7 paths are `manifest_path_is_input` INPUTs (predicate → rebuild triggered, EB-R2), AND (b) all 7 targets are copied verbatim into the built v11 fixtures (the design's adversary verified this; carried forward) → the fixture SHAs change → MANIFEST-CHANGED (exit 10), not MANIFEST-NOOP. The plan's exit-10 conclusion is right; this adds the fixture-copy link the predicate alone did not prove. | EB-R1b (manifest stores fixture-name→SHA), EB-R2 (7/7 INPUT), §9 fixture-copy fact |
| **MINOR-2 — manifest-commit scope keyword unstated** | MINOR | **FIXED (stated).** §7 + §9 + §11 step 10 now state: the push-time `manifest.txt` regen commit carries ONLY `test-fixtures/manifest.txt`, which is in `_SCOPE_NEUTRAL_GENERATED_PATHS` (Check-36-exempt from BOTH offender sets); the orchestrator commits it with a NEUTRAL subject (no scope keyword) to avoid a misleading claim. | EB-R3 (`_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})`) |
| **MINOR-3 — PREFLIGHT-7 bare-`memory` grep too broad (false-fails KEEP framing)** | MINOR | **FIXED (grep tightened).** §6 PREFLIGHT-7 now greps FEATURE-ENDORSEMENT tokens ONLY — `session memory` / `memory cache` / `~/.claude/projects/` / `~/.gemini/` / "per-project memory" / "cross-session memory" — and explicitly does NOT grep bare `memory`, so the sanctioned KEEP framing "the repo files are the authoritative memory" (PM-CHAT L1067) does NOT false-fail. §4.1 adds a coder authoring caution; §5.3 records the KEEP carve. I verified the tightened set hits the FEATURE passages and misses the KEEP framing. | EB-R8 (KEEP framing at L1067; tightened-grep test: KEEP miss / FEATURE hit / old-broad-grep false-fail) |
| **NIT-1 — C2 row double-counted in the C1 edit-set table** | NIT | **FOLDED IN.** §2.1 is now ONLY the C1 edit-set (7 rows, the PREFLIGHT-6-bounded paths); the C2 doc-move is moved to its OWN mini-table §2.1b annotated "NOT in the C1 diff that PREFLIGHT-6 bounds." PREFLIGHT-6 (§6) reiterates the C1-only bound. | §2.1 / §2.1b structure |
| **NIT-2 — consider mandating the ASCII-arrow substitution** | NIT | **FOLDED IN (flagged, not mandated).** §4.2 keeps the design's `→`/`≥` text as AUTHORITATIVE (per the reconciliation directive) and FLAGS the ASCII `->`/`>=` form as a coder-elective margin-buyer that retires the `wc -c` byte-trap (byte==code-point at 688). R1/R2 note the ASCII option collapses both to LOW. The coder elects; the plan does not mandate. | EB-R9 (688 cp / 708 bytes / 9 `→` + 1 `≥`) |
| **CONFIRMED-accurate carry-forwards** (the manifest exit-10 correction direction; the 688-cp/708-byte pointer + byte-trap caution; the trinity insert anchor after Reconciliation / before Phase routing, byte-parallel ×3; the PM-CHAT anchors L47/L172/L513 + memory passages outside edit regions; the L390 allowlist record; bare-"METHODOLOGY" DANGLING-exempt; groupings OMIT; C1=`project-only`/C2=`pack-only`; the 3-surface hand-off note; project-vocabulary purity) | n/a | **Carried UNCHANGED** per the reconciliation directive — the adversary CONFIRMED these accurate (its §3 confirm-table + §4 faithfulness analysis); not redesigned. | adversary EB-R2/R3/R6-R16 + plan §3-§9 |

---

## 14. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Ran only read-only verbs: `git rev-parse HEAD` → `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty; plus `grep`/`sed`/`awk`/`cat`/`ls`/`source`/`python3`/`Read`/`graphify query` measurement. NO `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase/apply` or any state-changing verb. Sole Write = this reconciled plan at `/tmp/pack-handoff-bd239-plan/PLAN-BD-239-RECONCILED.md` (Bash heredoc appends). No memory store read/written (MEMORY PROHIBITION 2026-06-23 honored — §0). | COMPLIANT |
| 2 | **reconciliation-instance-independence** | I am a FRESH independent reconciler — NOT the author of `PLAN-BD-239.md`, NOT the design author, NOT the design's adversarial reviewer, NOT the plan's adversarial reviewer. I re-measured the load-bearing MAJOR-1 claim FROM SOURCE at live HEAD (EB-R1: the heading map + the L655-700 dump confirm `#### Planner trigger conditions (mid-phase)` L659 is the last Workflow-4 sub-block before `### Workflow 5` L693, and `### Planner trigger rule` L311 / `### Audit subagents` L1076 are the wrong strings), independently re-ran the manifest predicate (EB-R2: 7/7 INPUT), re-measured the KEEP-framing grep behavior (EB-R8), the scope-neutral set (EB-R3), the Option-A bullet (EB-R9), and the DANGLING regex (EB-R13). I overruled NO confirmed finding; I resolved each from stronger or equal evidence. The carry-forwards the adversary CONFIRMED accurate are kept unchanged per the directive. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §12 carries EB-R1…EB-R13: every state-claim I touched — ESPECIALLY the corrected anchor (EB-R1, command + verbatim heading map + L655-700 dump + HEAD `d720873` + interpretation + SUPPORTED) and the manifest exit-10 chain (EB-R1b + EB-R2 + §9 fixture-copy) — is backed by command + verbatim output + HEAD-SHA + interpretation + conclusion. MINOR-2/3 cite EB-R3/EB-R8; NIT-2 cites EB-R9. | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only** | The shipped standard text (§4.1/§4.2/§4.3/§4.4) uses ONLY project vocabulary — phases, phase-tasks, TD backlog, project agents (architect/planner/coder/reviewer/docs-researcher/tester/auditor), the project's own triggers + execution half. PREFLIGHT-VOCAB (§6) gates the shipped text for `\bBD-?[0-9]`/`backlog-item`/`pack-[a-z]`/`pack memory`/`pack-ops`/`PACK-CHAT`/`PACK-AGENTS`/`\[rationale` → must be zero (the design's adversary measured the Option-A bullet → LEAKS: NONE). The only BD-238/BD-245 mentions in this plan are PLANNING CONTEXT (the hand-off note + the IMPL-REPORT), not shipped text. | COMPLIANT |
| 5 | **operating-docs-no-history-no-bloat** | §4.1 mandates the METHODOLOGY subsection carry ZERO history/dates/SHAs/provenance + ZERO deferral/version phrasing; §4.2 keeps the trinity bullet a terse ≤700-code-point pointer (688, EB-R9 — within the ≤700 cap), the full chain in METHODOLOGY (uncapped). PREFLIGHT-2/3 attest the bloat + HISTORY/DEFERRED axes. History (the hand-off note, the manifest expectation) lives in this plan + the IMPL-REPORT (reference docs), NOT in the operating doc. | COMPLIANT |
| 6 | **regenerate-manifest-v11-surface** | §9 keeps the exit-10 expectation grounded on (a) the predicate (EB-R2: 7/7 INPUT) AND (b) the fixture-copy fact (the 7 targets land in built fixtures → SHAs change). The coder does NOT regenerate the manifest per-commit; the orchestrator regenerates ONLY at push, ONLY when a fixture input changed, via `scripts/manifest-sync.sh` (expect exit 10), and commits the regenerated `test-fixtures/manifest.txt` with user approval (scope-neutral subject, §7 MINOR-2). | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — rules 1-7, each name + quoted evidence + terminal conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

---

*End of PLAN-BD-239-RECONCILED. Fresh independent reconciliation pack-planner (not the plan author, not the design author, not either adversarial reviewer); one Write (this plan) under /tmp; read-only git only; no memory store used. MAJOR-1 FIXED — the METHODOLOGY Part-5 insertion is re-anchored to the end of `#### Planner trigger conditions (mid-phase)` / start of `### Workflow 5 — Full-codebase audit (auditor agent)` (re-verified at live HEAD, EB-R1); the wrong `### Planner trigger rule` / `### Audit` strings are struck. MINOR-1 (exit-10 proof completed with the fixture-copy link), MINOR-2 (manifest commit is scope-neutral — no keyword), MINOR-3 (PREFLIGHT-7 tightened to FEATURE-endorsement tokens so the KEEP framing does not false-fail), NIT-1 (C2 split to its own §2.1b table), NIT-2 (ASCII-arrow flagged as a coder-elective margin-buyer, not mandated) all folded in. Carried UNCHANGED per the directive: the manifest exit-10 correction direction, the 688-cp/708-byte pointer + byte-trap caution, the trinity insert anchor, the PM-CHAT anchors + leave-alone memory passages, the L390 allowlist record, bare-"METHODOLOGY" DANGLING-exempt, groupings OMIT, the C1/C2 keywords, the 3-surface hand-off note, project-vocabulary purity. Ready for the user planner-to-coder gate → pack-coder.*
