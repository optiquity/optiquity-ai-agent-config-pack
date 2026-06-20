# IMPLEMENTATION PLAN — BD-226: Sub-agent worktree-isolation overhaul (coder-ready)

**Agent:** pack-planner (FRESH, empty context, READ-ONLY). **Repo:** optiquity-ai-agent-config-pack, branch `v11-dev`. **HEAD at planning:** `a84094a` (`a84094aa7fa2bda0213f66fb1588fdd162d92247`, verified `git rev-parse HEAD`). **Regime at planning:** IN-PLACE (`pwd` = `git rev-parse --show-toplevel` = `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`). **Deliverable:** this ONE plan doc. No repo edits, read-only git verbs only.

> **SSOT for this plan:** `/tmp/handoff-bd226-final/DESIGN-BD-226-FINAL.md` (the FINAL, census-verified-complete design) + `backlog/BD-226.md` (settled rules 1-10). This plan ENCODES that design into a coder-ready execution sequence. It does NOT re-design, re-litigate, or re-open any decision (A1, B1, C1-extended, D1, E2, F), finding (F-1..F-13, F-A..F-G), or constraint (1-3). All surface IDs (S1, S3, S-RO, S-RT, S-AR, G1-G4, etc.), commit IDs (C1-C6), and gate definitions are the design's; this plan turns them into per-commit task lists, a lock-step table, verification steps, and the dedicated parallelization section.
>
> **No blocking gaps found.** The design is self-contained and the planner re-measured every copy set + S-RT + agent-run.sh + baselines against HEAD `a84094a` (see §8 Empirical-Evidence Blocks). All measurements SUPPORT the design.

---

## 0. HOW TO READ THIS PLAN (coder orientation)

- **Line numbers are drift anchors only.** Every task keys edits on the QUOTED text + the named symbol/section heading, never the line number. Re-grep the quoted text in the live worktree before editing.
- **Six substance commits (C1-C6) + two bookkeeping commits (BK-1, BK-2).** C1-C4 are `pack-only`; C5-C6 are `project-only`. Each is single-scope for CI Check 36 (commit-subject scope keyword).
- **The bounded review/fix cycle is UNCHANGED** — it runs per commit (coder → reviewer → triage → ≤2 fix pairs + 1 final review → commit). BD-226 changes only WHERE the cycle runs (the commit's worktree), never the cycle itself. See §6.
- **The plan is SERIALLY EXECUTABLE.** §4 (the dedicated parallelization section) gives the dependency edges (the ONLY mandatory ordering) and an OPTIONAL wave schedule. A valid serial order is `C1 → C5 → C2 → C3 → C6 → C4`. Parallelism is never a precondition.
- **×3 CLI duplication is lock-step.** Every duplicated surface (pack-coder ×3, 12 RO defs, skills ×3 each, project coder ×3, project repo-ops ×3) + S-RT is assigned to ONE coder task per surface in §2; the §2.5 lock-step table is the master checklist. The 3 copies DIFFER by CLI format (`.md` Markdown vs `.toml` TOML prose) — match content-INTENT, never byte-copy.

---

## 1. GOAL + BD ITEMS ADDRESSED

**Goal.** Codify the worktree-isolation model developed live during BD-221 as the standing default: read-WRITE agents (coders/fix-coders) run in per-commit isolated worktrees; read-ONLY agents (reviewers/architects/planners/auditors/researchers) run in the tree the work lives in; the whole review/fix cycle runs in the commit's worktree; the patch is produced ONLY after review-clean. The model is stated generally (rules 1-10) and re-applied to APPLICATION A (pack-ops) + APPLICATION B (project ops docs), audience-correctly, Claude-only on both surfaces.

**BD item in scope:** **BD-226** (sole in-scope BD). Acceptance criteria (from `backlog/BD-226.md`): the generalized model (rules 1-10) stated once + re-applied to both surfaces audience-correctly; fix-coders forbidden a new worktree (must reuse the commit's worktree); RO agents routed to the work's tree (not "in-place"); patch produced only after review-clean via SendMessage; orphaned worktrees explicitly removed after their commit; Claude-only, Codex/Antigravity serial (BD-217); `validate-pack` green; NO client-install/boundary regression. This plan addresses every criterion (mapping in §7).

**Out of scope (reference only — pre-authorized BD deferrals):** BD-235 (project shared-discipline skill investigation — its entry rides as bookkeeping BK-1, the WORK is out of scope), BD-217 (Codex/Antigravity worktree parity — they run serially until then), BD-218 (background-session isolation). No BD-226 task touches their substance.

---

## 2. PER-COMMIT TASK BREAKDOWN (C1-C6)

> Each task cites its §2 surface ID from the FINAL design. The design's §2 carries the full per-surface delta prose; this plan names the file set, the ordered tasks, the commit subject + keyword, and the lock-step copies. The coder reads the design's §2 entry for the exact reword for each surface.

### COMMIT C1 — pack trinity keystone + class SSOT (`pack-only`)

**Commit subject:** `feat: v11 — BD-226 pack trinity + class SSOT: flip sub-agent isolation default to class-keyed model (pack-only)`
**Scope keyword:** `pack-only` (Check 36 denies `project-template/` + `supporting-docs/`). The subject names NO project path.
**Depends on:** nothing (keystone — establishes the flipped default + class SSOT all later commits restate).

**File set (exact):**
- `CLAUDE.md` (S1 keystone + S9 manifest-consistency check; NOTE: G1/G4 graph hunks are C4, NOT C1)
- `AGENTS.md`, `GEMINI.md` (S2 — EXPLICIT NO-OP; verified: `grep -c "Sub-agent behavior" AGENTS.md GEMINI.md` = 0/0. Do NOT add a section.)
- `pack-ops/PACK-AGENTS.md` (S4 "Two agent classes" — NOTE: G3 graph note is C4, NOT C1)
- `pack-ops/PACK-MEMORY-RATIONALE.md` (S8 `## agents-never-commit` retarget)
- `pack-ops/PACK-CHAT.md` § propagation procedure + `pack-ops/.spawn-rule-manifest.txt` (S9 — slug-unchanged verify/regenerate ONLY; NOTE: S3 spawn+merge-back is C2, G2 inject is C4)

**Ordered tasks:**
1. **T-C1-S1 (CLAUDE.md keystone, CLAUDE-only).** REPLACE the opening bullet of § "Sub-agent behavior (Claude-only)" — quoted anchor: "**Sub-agents run in-place by default; isolation is opt-in.** … When isolation is active, read-write agents emit a patch to the named `/tmp` handoff dir and the orchestrator applies it…" — with the class-keyed model per design §2 S1: RW agents isolated by class (first coder of a commit CREATES the worktree; fix-coders REUSE it, never a new worktree); RO agents run in the tree the work lives in (main when committed; the live worktree when uncommitted — NOT "always in-place"); patch produced ONLY after review-clean via SendMessage-ing the most-recent RW agent (rule 4); orchestrator applies at commit time. ADD rule-7 lifecycle + Constraint 1 (remove a worktree ONLY after its commit lands exit 0; failed commit KEEPS it; never auto-removal). ADD the rule-9 live-worktree ASK gate + a pointer to the rule-10 parallelization-map requirement (Pack Chat consumes the map to schedule parallel worktree waves vs serial commits). KEEP VERBATIM: the runtime-verify-regime (pwd/HEAD) line, `agents-never-commit`, `bgIsolation`→BD-218, the Claude-only "### Trinity exemption" bullet. Minimally extend the "Agent-team stage lifecycle" bullet to name the rule-4 post-review-clean patch step as a sanctioned SendMessage use (rule 6). The keystone bullet carries NO `[rationale:]` tag → outside the Check-45 bijection (no slug churn).
2. **T-C1-S4 (PACK-AGENTS Two-classes).** In `pack-ops/PACK-AGENTS.md` § "Two agent classes" + class roster, flip the opt-in framing to class-default per design §2 S4: "RW agents run in an isolated worktree (class-default); the patch is produced only after review-clean (the orchestrator SendMessage-s the most-recent RW agent); only the orchestrator applies it." Quoted anchor to reword: "When isolation is opted-in, an RW agent emits its `git diff` patch … and the orchestrator applies it". Flip "RW agents MUST be spawned with worktree isolation" from opt-in to class-default. ADD to the RO bullet: RO agents run in the tree the work lives in (not "always in-place").
3. **T-C1-S8 (RATIONALE `## agents-never-commit` retarget).** In `pack-ops/PACK-MEMORY-RATIONALE.md` § `## agents-never-commit`, edit the patch-timing sentence per design §2 S8 — quoted anchor: "The agent's output is its report file plus working-tree edits (or, in the isolated regime, a `git diff` patch emitted to the named `/tmp` handoff dir); Pack Chat reads the report, verifies / applies the patch, then commits." → the patch is the POST-review-clean artifact (rule 4), produced when the orchestrator re-engages the most-recent RW agent after review-clean; the report is the on-return deliverable. LEAVE the `## pack-chat-minor-edits-only` routing rationale UNTOUCHED. Union-grep the WHOLE RATIONALE for OLD-model timing (the §5.1 expanded phrase set, incl. the `bounded-review-fix-cycle` section) and reconcile each hit to rule 4/7 — reword body only; NO slug change. Confirm the `agents-never-commit` SLUG unchanged (manifest L24; Check 45 body-agnostic).
4. **T-C1-S9 (propagation + manifest).** The keystone (S1) edits a corpus bullet with NO `[rationale:]` tag → no slug churn → trinity-parity needs NO AGENTS/GEMINI edit. S8 edits `agents-never-commit` body (manifest-tracked, body-agnostic). Regenerate/verify `pack-ops/.spawn-rule-manifest.txt` consistency; assert NO slug add/remove → no structural manifest change.
5. **T-C1-S2 (NO-OP record).** Confirm AGENTS.md/GEMINI.md "Sub-agent behavior" stays absent. Record in the IMPL-REPORT that the absence is intentional (Claude-only exemption) — do NOT "restore parity."

**C1 verification:** see §3 (C1 row) — trinity body-parity hand-verify; Check 18/45 green; manifest consistency; per-commit union grep over C1's own files; full CI battery.

---

### COMMIT C2 — pack orchestrator contract + agent defs + S-RT (`pack-only`)

**Commit subject:** `feat: v11 — BD-226 pack orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (pack-only)`
**Scope keyword:** `pack-only`. **CRITICAL (keyword-token-trap):** the subject names NO `project-template/` path. S-RT is `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (pack-side), so C2 touches no project path and `pack-only` holds.
**Depends on:** C1 (PACK-CHAT + defs + S-RT cite the flipped class SSOT). File-disjoint from C3.

**File set (exact — 16 files of substance):**
- `pack-ops/PACK-CHAT.md` (S3 — spawn + merge-back, incl. Constraint-3 pack report rule; NOTE: G2 graph inject is C4)
- pack-coder def ×3 (S7): `.claude/agents/pack-coder.md`, `.agents-plugin/pack-agents/agents/pack-coder.md`, `.codex/agents/pack-coder.toml`
- 4 RO pack defs ×3 = 12 (S-RO):
  - `.claude/agents/{pack-architect,pack-planner,pack-reviewer,pack-docs-researcher}.md`
  - `.agents-plugin/pack-agents/agents/{pack-architect,pack-planner,pack-reviewer,pack-docs-researcher}.md`
  - `.codex/agents/{pack-architect,pack-planner,pack-reviewer,pack-docs-researcher}.toml`
- `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (S-RT — NEW surface, F-B)
- DO NOT TOUCH: `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (S-RT(proj) — EXPLICIT NO-OP, verified clean; editing it would inject a project path into a pack-only commit AND there is nothing to fix).

**Ordered tasks (all file-disjoint → any order within the commit's one worktree):**
1. **T-C2-S3 (PACK-CHAT spawn + merge-back).** Heaviest pack prose edit. In `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back", per design §2 S3: (a) reword "Worktree isolation is an opt-in accelerator…; the default is in-place." → "RW agents run in an isolated worktree by class; RO agents run in the tree the work lives in." (b) reword "RW agent (`pack-coder`) → spawn ISOLATED when enabled." → "RW agent → spawn ISOLATED (always, by class); the first coder of a commit CREATES the worktree, fix-coders REUSE it (never a new worktree)." (c) reword "RO agents → spawn IN-PLACE (no isolation). … Omit the `isolation` parameter." → RO agents → spawn in the tree the work lives in (main when committed; the live worktree when uncommitted — cd in + verify pwd/HEAD, rule 8); RO agents emit NO patch. (d) REWRITE "Merge-back": DELETE the up-front "emits the patch … and returns. The worktree may auto-remove on return — irrelevant" framing; the whole cycle runs IN the worktree; the patch is produced ONLY after review-clean by SendMessage-ing the most-recent RW agent; THEN Pack Chat `git apply`s + commits. ADD rule-7 + Constraint-1 teardown. (e) ADD the rule-9 ASK gate to the spawn-decision logic. (f) ADD the rule-10 note (Pack Chat consumes the parallelization map). (g) **Constraint-3 pack merge-back rule:** after the commit lands, the orchestrator MOVES every agent report from its `/tmp` handoff dir into the tree and commits it in a PAIRED commit; destination DERIVED at runtime from the README version table → `maintenance-docs/v<major>-implementation/` (state the DERIVATION, not the literal `maintenance-docs/v11-implementation/`). (h) KEEP the "Conflict protocol" as apply-time hygiene, reframed to the post-review-clean step + cross-referenced to §4 serialized-same-file ordering.
2. **T-C2-S7 (pack-coder def ×3).** Lock-step the 3 copies (`.claude`/`.agents-plugin`/`.codex`; the `.toml` carries the same RW-emit content in TOML prose). Per design §2 S7: reword the RW-emit step ("in the isolated regime, also emit a `git diff` patch … In the in-place regime, leave the edits…") → rule 4: the coder does its edits + verification + Writes its IMPL report + returns; it does NOT emit the patch up front; the patch is produced ONLY when the orchestrator SendMessage-s it back after review-clean (`git diff > <handoff>/changes.patch` at THAT point). KEEP: never-stage/commit/apply; the `/tmp` handoff path. **REPORT-LOCATION:** IMPL report goes to the named `/tmp` handoff dir ALWAYS (remove any "in-place regime → parent-tree report path" conditional). **F-13 why-not:** one line — do not pin `isolation` in frontmatter (single-value param breaks fix-coder reuse).
3. **T-C2-S-RO (4 RO pack defs ×3 = 12 files).** Lock-step all 12. Per design §2 S-RO: REPLACE the binary "isolated/in-place regime" RO-emit framing (e.g. pack-reviewer.md: "**RO-emit:** in the isolated regime that report path is under the named `/tmp` handoff dir …; in the in-place regime it is the named parent-tree path.") with rule-1 placement: "You run in the tree the work lives in: the main checkout when the work is on HEAD/committed; the commit's live worktree when the work is still uncommitted there — cd into that worktree and VERIFY pwd/HEAD at runtime (rule 8). You emit NO patch (RO). ALL your reports go to the named `/tmp` handoff dir the orchestrator supplies." KEEP the `commit-discipline §2` cross-reference. **REPORT-LOCATION:** report ALWAYS → named /tmp handoff dir. Flip all 12 (incl. the `.toml` Codex copies in TOML prose) in lock-step.
4. **T-C2-S-RT (`RUNTIME-SUBAGENT-PATTERN.md`).** REWORD the RW-class bullet — quoted anchor: "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then **emit a patch + report**." → the rule-4 model: pack-coder may write/edit source files within the caller-scoped file set inside its isolated worktree, then write its report and return; the patch is produced ONLY after an RO reviewer confirms the work clean (the orchestrator re-engages the most-recent RW agent via SendMessage), NOT on return. KEEP the RO-class bullet ("Their single permitted file write is the one caller-specified report") + the verb-ban paragraph VERBATIM (correct + universal). One coder task; `pack-only`.

**C2 verification:** see §3 (C2 row) — lock-step (pack-coder ×3 + RO ×12 + S-RT all moved, no drift, content-intent matched across `.md`/`.toml`); S-RT L88 reworded + project twin UNTOUCHED; C2 diff is `pack-only` (no `project-template/` path); per-commit union grep = 0 over C2's files; full CI battery.

---

### COMMIT C3 — pack skills + feature doc + conceptual-review (`pack-only`)

**Commit subject:** `feat: v11 — BD-226 pack skills + feature doc + conceptual-review: regime/handoff decouple + isolated-parallel narrative (pack-only)`
**Scope keyword:** `pack-only`.
**Depends on:** C1 (skills/feature-doc must match the flipped default). File-disjoint from C2 and C4.

**File set (exact):**
- `pack-ops/OPTIONAL-FEATURES.md` (S6)
- commit-discipline SKILL ×3 (S15): `.claude/skills/commit-discipline/SKILL.md`, `.codex/skills/commit-discipline/SKILL.md`, `.agents/skills/commit-discipline/SKILL.md`
- implementation-report SKILL ×3 (S16): `.claude/skills/implementation-report/SKILL.md`, `.codex/skills/implementation-report/SKILL.md`, `.agents/skills/implementation-report/SKILL.md`
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (S18)

**Ordered tasks (file-disjoint → any order within C3's worktree):**
1. **T-C3-S6 (OPTIONAL-FEATURES).** Per design §2 S6 (B1 targeted + F-3 + F-13): reword the "What it is" RW narrative (the up-front-patch ordering) → in-worktree-cycle + patch-after-review-clean (rule 3/4); reword "RO agents … need NO isolation — they emit a report and write nothing" → "RO agents run in the tree the work lives in"; reword "the in-place (non-isolated) regime is the default floor" → in-place is the DEGRADED fallback, not the default. **F-3 (the two caveats, NOT verbatim):** KEEP the auto-removal MECHANISM sentence; REWORD the consequence ("the patch survives auto-removal … BEFORE return") → "the worktree is HELD through the whole review/fix cycle and explicitly removed only AFTER the commit lands (rule 7 + Constraint 1); the patch is produced post-review-clean (rule 4), never pre-return." REWORD "Best-effort isolation" regime-detect to key on the agent's runtime pwd/HEAD ground-truth (rule 8), not a patch-handoff signal. **F-13 why-not:** ADD on the RW class-default narrative — an RW subagent must NOT pin `isolation:"worktree"` in frontmatter (single-value param ⇒ a pin forces a NEW worktree per spawn ⇒ a fresh fix-coder cannot cd-REUSE the first coder's worktree ⇒ breaks rules 1/3/7). **KEEP VERBATIM (B1):** the `baseRef` block, the `permissions.deny` recipe, the Trinity-exempt note, the BD-217/BD-218 refs (pack-side, allowed).
2. **T-C3-S15 (commit-discipline SKILL ×3).** Lock-step. Per design §2 S15 (F-9 decouple regime↔patch-emit): §1 "Detect your regime" — KEEP the pwd/HEAD self-detect MECHANIC (rule-8 ground-truth); REFRAME so the class determines the default (RW ⇒ isolated worktree; RO ⇒ the work's tree) and in-place is the DEGRADED fallback the agent self-detects (not "the default; no isolation param"). §2 "Write-target rule" — DECOUPLE "which tree you write in" from "do I emit a patch = am I RW"; add the THIRD state the binary cannot express: an RO agent in a live worktree writes ONLY its report to /tmp and emits NO patch; the patch is the RW-only POST-review-clean step (rule 4). REPORT-LOCATION: report → named /tmp handoff dir. Remove the up-front "patch + report" framing (it is in the §5.1 phrase set). Lock-step the 3 copies.
3. **T-C3-S16 (implementation-report SKILL ×3).** Lock-step. Per design §2 S16 (F-10): Intro — DELETE the "survives auto-removal" rationale (quoted: "so it survives the worktree's auto-removal on agent return"); the worktree is HELD through the cycle + removed after the commit lands (rule 7); the report is the on-return deliverable; the patch is the post-review-clean artifact (rule 4). §1 + §4 — rework "so the report is self-contained even after the worktree auto-removes" the same way; reword the "on agent return" framing (§5.1 phrase). KEEP the regime + `worktree-agent-*` HEAD-reporting mechanic. Lock-step the 3 copies.
4. **T-C3-S18 (CONCEPTUAL-REVIEW L194).** In `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`, flip the bullet — quoted anchor: "Spawn sub-agents in background; sub-agents run in-place by default, with opt-in worktree isolation (BD-197)" → the class-keyed default ("RW agents isolated by class; RO agents in the work's tree") + update the citation BD-197 → BD-226.

**C3 verification:** see §3 (C3 row) — lock-step (commit-discipline ×3 + implementation-report ×3 moved, no drift across `.claude`/`.codex`/`.agents`); per-commit union grep = 0 over C3's files; full CI battery.

---

### COMMIT C4 — graph-path injection under worktree isolation, CLAUDE-only (`pack-only`)

**Commit subject:** `feat: v11 — BD-226 graph-path injection under worktree isolation, CLAUDE-only (pack-only)`
**Scope keyword:** `pack-only`.
**Depends on:** C1 (shares `CLAUDE.md` [S1/G1/G4] + `PACK-AGENTS.md` [S4/G3]) AND C2 (shares `pack-ops/PACK-CHAT.md` [S3/G2]) — serialize after BOTH (same-file-serialize, §4.2). E2 accepts this; C4 is STANDALONE (not folded into C1/C2).

**File set (exact):**
- `CLAUDE.md` (G1 § "Graph-first context (BD-225)" + G4 § "Agent invocation rules" spawn-syntax — both CLAUDE-only)
- `pack-ops/PACK-CHAT.md` (G2 — ADD graph-inject note near the "Name the handoff dir" anchor)
- `pack-ops/PACK-AGENTS.md` (G3 — ADD graph-inject note near `## How to invoke pack agents` / the `claude --agent` block)
- DO NOT TOUCH (F-1 CLAUDE-only): `AGENTS.md`, `GEMINI.md` (graph-first stays as-is), and `pack-ops/PACK-MEMORY-RATIONALE.md` § `## graph-first-context` (stays as-is).

**Ordered tasks:**
1. **T-C4-G1 (CLAUDE graph-first, CLAUDE-only).** Per design §2 G1 (Constraint 2 + F-8 + F-1): REPLACE the `$(git rev-parse --show-toplevel)/graphify-out/graph.json` self-derivation with the orchestrator-derives-at-runtime-and-injects contract — the orchestrator evaluates the derivation formula in its canonical checkout and INJECTS the resulting literal into the spawn prompt; the agent uses THAT injected path verbatim, NEVER recomputing from its own worktree toplevel (which under isolation resolves to the empty worktree root where gitignored `graphify-out/` is absent). The surface carries the DERIVATION FORMULA + the injection contract, NO machine-specific literal. **F-8 graceful degradation:** the orchestrator injects the literal ONLY when its canonical `graphify-out/graph.json` exists; when absent it injects NO path (or a "no graph" token) and the agent uses grep/Read; the agent runs the G1 existence check against the INJECTED path (never its own toplevel); G2 fallback (query errors/empties ⇒ fall back, never block) unchanged. Keep budgets (2000/1500/1000) + `--backend claude-cli`. **F-1 note:** ADD an explicit Trinity-exempt sentence (worktree path-injection is Claude-only; AGENTS.md/GEMINI.md graph-first stays as-is, correct for their in-place execution; their worktree story is a future pack version).
2. **T-C4-G4 (CLAUDE agent-invocation, CLAUDE-only).** In `CLAUDE.md` § "Agent invocation rules" spawn-syntax, ADD the same injection note (agent uses `--graph <injected>`, never its own toplevel). **Within-task ordering (§4.5):** the two CLAUDE.md hunks (G1, G4) SERIALIZE within this one coder task (same file).
3. **T-C4-G2 (PACK-CHAT inject ADD).** In `pack-ops/PACK-CHAT.md`, ADD a graph-inject note near the "Name the handoff dir" anchor: every spawn prompt injects the orchestrator-derived absolute graph literal (Constraint 2), only when graph.json exists (F-8). PACK-CHAT.md carries zero existing graph text → this is an ADD (do not search for text to replace).
4. **T-C4-G3 (PACK-AGENTS note ADD).** In `pack-ops/PACK-AGENTS.md`, ADD a graph-inject note near `## How to invoke pack agents` / the `claude --agent` block: document the injection requirement. PACK-AGENTS.md carries zero existing graph text → ADD.
5. **T-C4 IMPL-REPORT divergence record.** Record in the C4 IMPL-REPORT that the RATIONALE `## graph-first-context` section + AGENTS.md/GEMINI.md graph-first keep the self-derivation wording BY USER DECISION (F-1 Option A), not an oversight — so a future maintainer understands the intentional divergence.

**C4 verification:** see §3 (C4 row) — Constraint-2 no-hardcoded-path gate = 0; F-8 degradation wording present; F-1 Trinity-exempt note present in G1; CLAUDE-only (grep-confirm zero C4 hits in AGENTS.md/GEMINI.md; RATIONALE `## graph-first-context` UNTOUCHED); G2/G3 are ADDs; full CI battery.

---

### COMMIT C5 — project orchestrator contract + agent defs (`project-only`)

**Commit subject:** `feat: v11 — BD-226 project orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (project-only)`
**Scope keyword:** `project-only` (Check 36 denies everything outside `project-template/` + `supporting-docs/`). The subject names NO pack path.
**Depends on:** nothing on the pack side (project surface partition is fully file-disjoint from all pack commits — no `project-template/` file references a pack-ops file; the deny-list enforces it). Project keystone.

**File set (exact):**
- `project-template/docs/pack/PM-CHAT.md` (S10 — incl. Constraint-3 project report rule + the F-13 why-not HOME)
- project coder def ×3 (S13): `project-template/.claude/agents/coder.md`, `project-template/.agents-plugin/optiquity-agents/agents/coder.md`, `project-template/.codex/agents/coder.toml`
- project repo-ops def ×3 (S13b): `project-template/.claude/agents/repo-ops.md`, `project-template/.agents-plugin/optiquity-agents/agents/repo-ops.md`, `project-template/.codex/agents/repo-ops.toml`

**Audience normalization (P-missed-7, EVERY task in C5/C6):** "the PM chat" (never "Pack Chat"); "your `coder`/`reviewer`/`architect`/`repo-ops`" (never `pack-*`); "a future pack version" / "tracked separately" (never `BD-217`/`BD-218`/any `BD-NNN`); NO Graphify/graph note at all. Express rule-4 re-engagement as: "re-engage the most-recent read-write agent (in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder against the worktree to produce the patch)" — never import the pack's Agent-Teams framing as a universal project guarantee.

**Ordered tasks:**
1. **T-C5-S10 (PM-CHAT, heaviest project edit).** Per design §2 S10: (a) reword § "Isolation is for read-write agents only" — quoted anchor "RW ⇒ isolate; RO ⇒ in-place." → "RW agents (`coder`, `repo-ops`) run in an isolated worktree by class; the first coder of a commit creates it and fix-coders REUSE it (never a new worktree). RO agents run in the tree the work lives in — your main tree when committed, the live worktree when uncommitted (cd in + verify pwd/HEAD)." (b) **F-13 why-not (the SINGLE HOME for both RW agents per F-6):** do NOT pin `isolation:"worktree"` in any RW agent's def frontmatter (single-value param ⇒ pin forces a new worktree per spawn ⇒ fix-coder cannot reuse). (c) REWRITE "Merge-back": DELETE the up-front "via a patch the agent writes before it returns" framing; the whole cycle runs in the worktree; the patch is produced ONLY after the reviewer confirms clean, by re-engaging the most-recent RW agent (project phrasing); THEN the PM chat applies + commits. ADD rule-7 + Constraint-1. ADD the rule-9 ASK gate (project phrasing). ADD the rule-10 note (the PM chat consumes the parallelization map). (d) **Constraint-3 project merge-back rule:** after the commit lands, the PM chat MOVES every agent report from its `/tmp` handoff dir into the tree and commits it (paired commit); destination DERIVED at runtime — a dedicated `docs/impl-reports/**` subtree (NEW — keeps reports OUT of the `docs/` content the pack installs), organized by current phase (e.g. `docs/impl-reports/<current-phase>/` derived from the project's implementation-plan stream). State the DERIVATION, not a baked path. NO pack-self ref. (e) KEEP the conflict protocol, reframed to the post-review-clean step + cross-reference §4 serialized-same-file ordering.
2. **T-C5-S13 (project coder def ×3).** Lock-step. Per design §2 S13: reword "Merge-back: emit a patch, never commit." (coder.toml L29 carries the OLD framing) → rule 4 (project phrasing): edits + verification + report + return; the patch is produced ONLY after review-clean when the PM chat re-engages you. REPORT-LOCATION: report ALWAYS → the named /tmp handoff dir (remove the in-place conditional). "spawn isolation is load-bearing" keeps (no-safety-net) but flip opt-in → class-default. **F-13 why-not:** one line pointer to PM-CHAT.md (project audience). Lock-step the 3 copies (`.md` vs `.toml`).
3. **T-C5-S13b (project repo-ops def ×3).** Lock-step. Per design §2 S13b (F-6 coder-twin): repo-ops has NO "Merge-back" section today (verified: it is NOT in the OLD-model union). ADD the SAME class-default merge-back paragraph coder.md gets, symmetric: repo-ops (an RW agent) runs in an isolated worktree by class; it does its scripted writes + verification, Writes its report to the named /tmp handoff dir, returns; the patch is produced only after review-clean when the PM chat re-engages it; never stage/commit/apply. KEEP the `git worktree`-in-the-verb-ban line VERBATIM (universal verb-ban; the HARNESS creates the worktree). **F-13 why-not:** one line pointer to PM-CHAT.md. Note: if repo-ops legitimately produces only gitignored generated artifacts, the EMPTY patch is the expected handoff (correct, not a barrier). Lock-step the 3 copies.

**C5 verification:** see §3 (C5 row) — lock-step (project coder ×3 + repo-ops ×3 moved); project leak gates = 0 (BD-NNN, graphify); audience-leak grep scoped to the S10 EDIT region (F-F — PM-CHAT.md L342/L344 "Pack Chat" refs are pre-existing, out of scope); full CI battery.

---

### COMMIT C6 — project feature doc + skill + prompts + agent-run launcher (`project-only`)

**Commit subject:** `feat: v11 — BD-226 project feature doc + skill + prompts + agent-run launcher (project-only)`
**Scope keyword:** `project-only`. The subject naming `agent-run.sh` is project-side — safe. Names NO pack path.
**Depends on:** C5 (project docs/skill/prompts/launcher reference PM-CHAT's contract).

**File set (exact):**
- `project-template/docs/pack/OPTIONAL-FEATURES.md` (S12)
- `project-template/skills/implementation/SKILL.md` (S17 — single source → 3 client skill dirs at install)
- `project-template/docs/pack/prompts/coder.md` + `project-template/docs/pack/prompts/reviewer.md` (S14; `prompts/repo-ops.md` — verify only)
- `project-template/agent-run.sh` (S-AR — 4 locations)
- `supporting-docs/METHODOLOGY.md` (S11 — one-line xref IF its fix-cycle prose implies a placement; likely NO EDIT)

**Ordered tasks (audience normalization per C5 header applies to all):**
1. **T-C6-S12 (project OPTIONAL-FEATURES).** Per design §2 S12 (B1 + F-3 + F-13, project audience): reword the "What it is" RW narrative + "Read-only agents … need NO isolation" → in-worktree-cycle + RO-to-work's-tree; reword "in-place (non-isolated) regime is the default floor" → degraded fallback; **F-3 caveats (project copy):** auto-removal MECHANISM fact stays; the patch-timing consequence + "patch handoff ⇒ isolated" regime-detect reword to rule 4/7/Constraint 1 + pwd/HEAD ground-truth; **F-13 why-not** (project audience, no `pack-*`). KEEP VERBATIM: baseRef/permissions.deny blocks; the "Trinity-exempt note (Claude-only)" + "a future pack version" framing (NO BD-NNN — already correct).
2. **T-C6-S17 (project implementation SKILL).** Per design §2 S17 (F-9 + F-10, project audience): § "Reporting the change set (regime-aware)" — quoted anchors "Isolated (opt-in worktree)" + "is the persisted artifact, so the change set survives even after" → rule 4: the patch is the POST-review-clean artifact (not on-return); DELETE the "survives … cleaned up"/`persisted artifact` rationale (F-10); DECOUPLE regime↔patch-emit (F-9): an RO agent in a worktree writes only its report, emits no patch; REPORT-LOCATION: report → named /tmp handoff dir. Project phrasing; NO `pack-*`/BD-NNN/Graphify.
3. **T-C6-S14 (project prompts).** `reviewer.md` "read-only review pass": ADD that the reviewer reads the work IN the live worktree when the work is uncommitted there (cd in + verify pwd/HEAD; rule 3/8). `coder.md` prompt template: verify + align any placement/handoff language to rule 4. `prompts/repo-ops.md`: verify; align only if it asserts a placement; record the verify outcome in the IMPL-REPORT.
4. **T-C6-S-AR (agent-run.sh, 4 locations — measure-then-bound classification).** Per design §2 S-AR table — apply the per-location KEEP/STRIP exactly:
   - **L173-176 (`--worktree` help) — KEEP.** The `--worktree` FLAG is a launcher-LEVEL opt-in (a human-launcher choice for the separate-terminal path, distinct from the agent-PLACEMENT model). Leave the "SECONDARY/opt-in" framing intact.
   - **L275-278 (`run_in_worktree()` comment) — STRIP→reword.** Quoted anchor: "the PM-chat merge-back applies the patch the agent leaves". REWORD to rule 4: "Either way the agent never stages or commits. The PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch — same merge-back model as the in-session spawn path; only the LAUNCH mechanism (separate terminal vs in-session Agent tool) differs, with no special-casing (see docs/pack/PM-CHAT.md 'Merge-back')." Keep the existing PM-CHAT.md + OPTIONAL-FEATURES.md xrefs.
   - **L306-307 (echo'd reminder) — STRIP→reword.** Quoted anchor: "bring its work back via the PM-chat patch merge-back." REWORD the echo to the post-review-clean model (consistent with the L275-278 reword).
   - **L606-608 (branch comment) — KEEP.** Annotates the LAUNCHER branch that fires only when the human passes `--worktree` (launcher-level opt-in, same class as L173-176). Leave as-is.
5. **T-C6-S11 (METHODOLOGY).** Per design §2 S11 (A1): keep the worktree/merge-back SUBSTANCE in PM-CHAT.md (S10). `supporting-docs/METHODOLOGY.md` gets AT MOST a one-line cross-reference if its fix-cycle prose implies a placement. The "the developer may re-run the owning subagent in isolation to verify the fix" prose is already consistent → LIKELY NO EDIT. Do NOT duplicate the substance (single-SSOT; drift risk). Record the no-edit-or-one-line decision in the IMPL-REPORT.

**C6 verification:** see §3 (C6 row) — S-AR 4-location classification verified (L275-278 + L306-307 STRIPPED; L173-176 + L606-608 KEPT); project leak gates = 0; P-missed-7 audience-correctness; `docs/impl-reports/` derivation (not baked); full CI battery.

---

### BOOKKEEPING COMMITS (ride WITH the batch — SEPARATE from C1-C6 substance)

These are NOT BD-226 substance; they keep C1-C6 single-purpose + Check-36-clean. Both are Pack-Chat-direct (per `pack-chat-minor-edits-only`), NOT coder work — listed here for the orchestrator's sequencing, not for a coder.

- **BK-1 (`pack-only`, Pack-Chat-direct new-entry author).** `backlog/BD-235.md` (the out-of-scope project-skill investigation entry, currently untracked at HEAD a84094a) + the regenerated `backlog/_toc.md` (currently `M` at HEAD) ride in a SEPARATE bookkeeping commit — NOT inside any BD-226 substance commit. Verified state: `git status --short backlog/` → ` M backlog/_toc.md` + `?? backlog/BD-235.md`. Both OUT of BD-226 scope; the WORK BD-235 describes is out of scope (reference only).
- **BK-2 (`pack-only`, paired report commit per Constraint 3).** The agent reports for THIS BD-226 batch (architect/planner/coder/reviewer outputs) moved by the orchestrator from `/tmp` into `maintenance-docs/v11-implementation/` (derived from README v11) — the audit record, not BD-226 substance. Lands at batch end after all per-commit cycles.

---

## 2.5 LOCK-STEP ENUMERATION TABLE (every duplicated copy → ONE coder task)

> Re-measured at HEAD `a84094a` (`git ls-files` — see §8 EB-2/EB-3). The 3 copies of each surface DIFFER by CLI format (`.md` Markdown vs `.toml` TOML prose); match content-INTENT, never byte-copy (cross-cli-reference-normalization). Each row's copies are flipped IN ONE coder task so they never drift.

| Surface | Commit | Task | Copy 1 (`.claude`) | Copy 2 (`.agents-plugin`) | Copy 3 (`.codex`) | ×N |
|---|---|---|---|---|---|---|
| **S7** pack-coder def | C2 | T-C2-S7 | `.claude/agents/pack-coder.md` | `.agents-plugin/pack-agents/agents/pack-coder.md` | `.codex/agents/pack-coder.toml` | 3 |
| **S-RO** pack-architect | C2 | T-C2-S-RO | `.claude/agents/pack-architect.md` | `.agents-plugin/pack-agents/agents/pack-architect.md` | `.codex/agents/pack-architect.toml` | 3 |
| **S-RO** pack-planner | C2 | T-C2-S-RO | `.claude/agents/pack-planner.md` | `.agents-plugin/pack-agents/agents/pack-planner.md` | `.codex/agents/pack-planner.toml` | 3 |
| **S-RO** pack-reviewer | C2 | T-C2-S-RO | `.claude/agents/pack-reviewer.md` | `.agents-plugin/pack-agents/agents/pack-reviewer.md` | `.codex/agents/pack-reviewer.toml` | 3 |
| **S-RO** pack-docs-researcher | C2 | T-C2-S-RO | `.claude/agents/pack-docs-researcher.md` | `.agents-plugin/pack-agents/agents/pack-docs-researcher.md` | `.codex/agents/pack-docs-researcher.toml` | 3 |
| **S-RT** RUNTIME-SUBAGENT-PATTERN | C2 | T-C2-S-RT | — (single file) | `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` | — | 1 |
| **S15** commit-discipline SKILL | C3 | T-C3-S15 | `.claude/skills/commit-discipline/SKILL.md` | `.agents/skills/commit-discipline/SKILL.md` | `.codex/skills/commit-discipline/SKILL.md` | 3 |
| **S16** implementation-report SKILL | C3 | T-C3-S16 | `.claude/skills/implementation-report/SKILL.md` | `.agents/skills/implementation-report/SKILL.md` | `.codex/skills/implementation-report/SKILL.md` | 3 |
| **S13** project coder def | C5 | T-C5-S13 | `project-template/.claude/agents/coder.md` | `project-template/.agents-plugin/optiquity-agents/agents/coder.md` | `project-template/.codex/agents/coder.toml` | 3 |
| **S13b** project repo-ops def | C5 | T-C5-S13b | `project-template/.claude/agents/repo-ops.md` | `project-template/.agents-plugin/optiquity-agents/agents/repo-ops.md` | `project-template/.codex/agents/repo-ops.toml` | 3 |

**Lock-step totals:** pack-coder ×3 (S7) + 4 RO defs ×3 = 12 (S-RO) + S-RT ×1 = **16 pack-def files in C2**; commit-discipline ×3 + implementation-report ×3 = **6 pack-skill files in C3**; project coder ×3 + project repo-ops ×3 = **6 project-def files in C5**. Skill triad note: S15/S16 live under `.claude`/`.agents`/`.codex` (NOT `.agents-plugin`); the pack DEF triad lives under `.claude`/`.agents-plugin`/`.codex`. These are different third members — the coder must use the correct triad per surface (verified §8 EB-2).

**Lock-step NON-targets (record, do not edit):**
- S-RT(proj) `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` — verified CLEAN (no OLD-model hit); NO-OP. Editing it injects a project path into pack-only C2.
- S2 `AGENTS.md` / `GEMINI.md` "Sub-agent behavior" — verified ABSENT (0/0); NO-OP. Do not "restore parity."
- AGENTS.md / GEMINI.md graph-first + RATIONALE `## graph-first-context` — F-1 CLAUDE-only; NOT touched by C4.
- project-template trinity `CLAUDE/AGENTS/GEMINI.md` — D1: NO EDIT.
- `scripts/tests/fixtures/customization-preserve/**` pack-coder/RO copies — TEST FIXTURES (regenerated snapshots), not canonical defs; NOT edited (verified §8 EB-2 — they appear in `git ls-files` but are fixture snapshots under `scripts/tests/fixtures/`, excluded by the gate filter).

---

## 3. PER-COMMIT VERIFICATION (FULL CI battery + scoped gates)

> **Every commit (C1-C6)** runs the FULL CI battery, NOT validate-pack alone (verify-full-ci-suite): `scripts/validate-pack.py` (ALL checks incl. Check 43, Check 18, Check 45, Check 36, Check 62) + the DEEP checks + the sharded test suites + `build.sh --verify`. The coder emits the PREFLIGHT line (`PREFLIGHT: N/N in-scope edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`) ONLY after all in-scope edits + verification PASS.

**Per-commit union OLD-model grep (F-E — scoped to THAT commit's OWN file set):**
- The union grep (the §5.1 phrase set) runs over ONLY the files THAT commit edits. Expected OLD-model model-phrase residual in those files = **0** (the commit flipped them). Do NOT run a whole-side grep mid-batch (unsatisfiable — sibling commits still carry OLD text). Coder asserts in PREFLIGHT; reviewer re-asserts.

| C# | Commit-specific verification (in addition to the full CI battery + per-commit union grep = 0) |
|---|---|
| **C1** | (a) Trinity body-parity HAND-VERIFY (§6) — Check 18/45 do NOT catch body divergence within `## Pack memory`; the reviewer hand-verifies the keystone edit did not break trinity body parity and confirms the CLAUDE-only divergence is INTENTIONAL (documented), not an accidental break. (b) Check 18 (`check_trinity_h2_parity`) + Check 45 (`check_pack_memory_rationale_bijection`) GREEN. (c) `.spawn-rule-manifest.txt` consistency; NO slug add/remove. (d) `agents-never-commit` slug unchanged (manifest L24). |
| **C2** | (a) Lock-step verification — pack-coder ×3 + RO defs ×12 + S-RT all moved; `diff`-the-intent across copies (format differs `.md`/`.toml`; content-intent matches). (b) S-RT L88 reworded; project twin `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` UNTOUCHED. (c) C2 `git diff --name-only` is `pack-only` (no `project-template/` path) → Check 36 clean. |
| **C3** | Lock-step — commit-discipline ×3 + implementation-report ×3 moved (no drift across `.claude`/`.codex`/`.agents`). KEEP the `worktree-agent-*` pwd/HEAD self-detect mechanic (rule-8). |
| **C4** | (a) **Constraint-2 no-hardcoded-path gate (§5.3):** `grep -rnE "/Users/\|/home/\|/private/" <C4 diff>` filtered to graph/toplevel context = **0** machine-specific literal paths (the diff carries the DERIVATION FORMULA + injection narrative, never a baked literal). (b) F-8 degradation wording present (inject only when graph.json exists; existence-check on the INJECTED path; G2 fallback unchanged). (c) F-1 Trinity-exempt note present in G1. (d) **CLAUDE-only:** grep-confirm ZERO C4 hits in AGENTS.md/GEMINI.md; RATIONALE `## graph-first-context` UNTOUCHED. (e) G2/G3 are ADDs (no existing graph text replaced). |
| **C5** | (a) Lock-step — project coder ×3 + repo-ops ×3 moved. (b) **Project leak gates (§5.2):** `grep -rEn "BD-[0-9]"` over the C5 surfaces = **0**; `grep -rEn "graphify\|graph\.json\|--graph"` over `project-template supporting-docs` = **0**. (c) **Audience-leak grep (F-F)** scoped to the S10 EDIT region (NOT the whole file — PM-CHAT.md L342/L344 "Pack Chat" refs are pre-existing, out of scope): no `pack-*`/`Pack Chat`/`pack-ops/` in the S10 restatement. (d) S-RT(proj) twin stays CLEAN. |
| **C6** | (a) **S-AR 4-location classification:** L275-278 + L306-307 STRIPPED to post-review-clean; L173-176 + L606-608 launcher-flag KEPT (the reviewer confirms these two are the launcher-flag references and the patch-timing two were reworded). (b) Project leak gates (§5.2) = 0. (c) P-missed-7 audience-correctness over all C6 surfaces. (d) `docs/impl-reports/` rule states a DERIVATION (not a baked phase path); `docs/impl-reports/` is ABSENT today (NEW subtree the rule introduces by derivation). |

**Batch-end verification (after ALL per-commit cycles):**
- One END-OF-BATCH reviewer pass over the full BD-226 batch.
- The **whole-side union grep (§5.1 form A) run ONCE per side** (F-E): `git ls-files -z | xargs -0 grep -IlE "<union phrases>" | grep -vE '^maintenance-docs/' | grep -vE '^backlog/' | grep -vE '^test-fixtures/'` then assert every REMAINING hit is on the §5.1 KEEP allowlist — expected model-phrase remainder = **0** (only the reworded auto-removal MECHANISM sentence + the agent-run.sh launcher-flag lines L173-176/L606-608 may persist as intentional allowlist remainders; the `worktree-agent-*` self-detect mechanic + the `git worktree` verb-ban are MOOT — they never coincide with a union phrase). Run once after C1-C4 (pack) and once after C5-C6 (project).
- Constraint-3 reports moved into the tree + committed (BK-2).

---

## 5. CROSS-DOC CONSISTENCY + PROPAGATION/CI

- **Slugs UNCHANGED.** `agents-never-commit` (S8 body-only edit), `graph-first-context` (untouched by C4 per F-1), `bounded-review-fix-cycle` (verify body has no OLD timing; reword body if present — NO slug change). No new slug minted. The keystone bullet (S1) carries no `[rationale:]` tag → outside the bijection.
- **Check 18 + Check 45 stay GREEN** — both are body-agnostic (Check 18 = H2 names/order; Check 45 = slug set-equality). A body edit to `## agents-never-commit` + the CLAUDE-only keystone keep both green AS LONG AS slugs + H2 names/order are unchanged. C1 adds the manual body-parity hand-verify (§6) because the automated checks do NOT catch body divergence within `## Pack memory`.
- **`.spawn-rule-manifest.txt`** — regenerate/verify in C1; no slug add/remove → no structural manifest change. `graph-first-context` is NOT manifest-tracked → C4 triggers no manifest update.
- **Check 36 (commit-scope keyword)** — each commit's `git diff --name-only` matches its `pack-only`/`project-only` keyword; the §3 partition guarantees this; verify per commit. C2's S-RT file is pack-side → C2 stays `pack-only`.
- **Manifest (`test-fixtures/manifest.txt`)** — NO structural change. Skill edits (S15/S16/S17) touch BODY only (not frontmatter/count) → skill-count/frontmatter checks unaffected. Fixture install-snapshots are REGENERATED push-time by `manifest-sync.sh` + Check 62 — not per-commit; no test hand-asserts OLD-default text (so the flip needs no test edit).
- **No NEW validator** (measure-then-bound). The leak-classes (pack-ref/BD-NNN/graphify in project) are already bounded by the `project-template/CLAUDE.md` deny-list + its CI check; the per-commit reviewer grep-gates (§3 / §5.2) are the completeness check. Adding a BD-226-specific guard widens surface with no new coverage.
- **No test/validator asserts the OLD-default text** → no test edit required for the flip (verified — no fixture is hand-asserted).

---

## 4. PARALLELIZATION GROUPINGS + DEPENDENCIES (rule 10 — its OWN dedicated section)

> This is a SELF-CONTAINED section, deliberately separate from §1/§2 (rule 10 + the USER DIRECTIVE: the parallelization map lives in its own section and does NOT bias the rest of the plan). It DESCRIBES the schedule the orchestrator MAY execute; it does NOT fold commits to dodge serialization (E2 keeps C4 standalone).

### 4.0 THE MAIN PLAN IS SERIALLY EXECUTABLE (read this first)

**The dependency EDGES (§4.1) are the ONLY mandatory ordering. The parallel WAVES (§4.3) are an OPTIONAL accelerator — never a precondition for completing any task.** Every commit C1-C6 is an independent unit of work whose only hard requirement is that its dependency commits have landed first. If parallelism is unavailable — a CLI without worktree isolation (Codex/Antigravity, tracked for a future pack version per BD-217, OUT of scope here) or simply operator choice — the SAME plan runs SERIALLY by following the dependency order. No task changes; no step is skipped; the bounded review/fix cycle (§6) is identical whether a commit runs in a parallel wave or alone in series.

**Concrete valid serial order (§4.6):** `C1 → C5 → C2 → C3 → C6 → C4`, then the bookkeeping commits BK-1, BK-2 at the batch boundary. (Any serial order respecting the edges {C1<C2, C1<C3, C1<C4, C2<C4, C5<C6} is valid; this is one such order.)

### 4.1 Dependency graph (commits from §2)

```
C1 (pack keystone) ──┬──> C2 (pack orchestrator + defs + S-RT) ──┐
                     │                                            ├──> C4 (graph inject, CLAUDE-only)
                     ├──> C3 (pack skills + OF + concept) ────────┘ (C4 needs C1 AND C2)
                     │
C5 (project keystone) ──> C6 (project OF + skill + prompts + launcher)
```

- **C1** — no dependency (keystone; establishes the flipped default + class SSOT all others restate).
- **C2** — depends on **C1** (PACK-CHAT + defs + S-RT cite the flipped class SSOT). File-disjoint from C3. (S-RT's addition does NOT change C2's dependency or wave membership — one more pack-only file in C2's set.)
- **C3** — depends on **C1** (skills/feature-doc must match the flipped default). File-disjoint from C2 and C4.
- **C4** — depends on **C1** (shares `CLAUDE.md` [S1/G1/G4] + `PACK-AGENTS.md` [S4/G3]) AND **C2** (shares `pack-ops/PACK-CHAT.md` [S3/G2]). Standalone (E2). Serialize after BOTH.
- **C5** — NO dependency on any pack commit (project surface partition is fully file-disjoint — no `project-template/` file references a pack-ops file; the deny-list enforces it).
- **C6** — depends on **C5** (project docs/skill/prompts/launcher reference PM-CHAT's contract).

### 4.2 Binding constraint (the rule-10 invariant): SAME FILE ⇒ SERIALIZE

**Two commits that touch the SAME FILE MUST serialize (or merge) — never concurrent worktrees** (avoids patch-apply collision). Shared-file set under E2 (re-measured §8 EB-1):
- `CLAUDE.md`: C1 (keystone S1) + C4 (graph G1/G4) → C4 after C1.
- `pack-ops/PACK-AGENTS.md`: C1 (S4) + C4 (G3) → C4 after C1.
- `pack-ops/PACK-CHAT.md`: C2 (S3) + C4 (G2) → C4 after C2.

So **C4 serializes after C1 AND C2**. S-RT (`RUNTIME-SUBAGENT-PATTERN.md`) is touched ONLY by C2 → introduces no new shared-file edge. All other commit pairs are file-disjoint: C2∥C3, C1∥C5, C3∥C6, C3∥{C2→C4}; the project chain C5→C6 is fully file-disjoint from every pack commit.

### 4.3 Wave schedule (OPTIONAL accelerator — the binding-when-parallel schedule)

- **Wave 0 (concurrent, two worktrees):** { **C1** (pack keystone) ∥ **C5** (project keystone) }. File-disjoint across the pack/project partition.
- **Wave 1 (after their keystones land):** { **C3** (pack skills+OF+conceptual-review) ∥ **C6** (project docs+skill+prompts+launcher, after C5) } run concurrently with the **C2 → C4** serial chain.
  - **C2** (after C1; touches PACK-CHAT.md + pack-coder ×3 + RO defs ×12 + S-RT) → **C4** (after C1 AND C2; touches CLAUDE.md + PACK-AGENTS.md + PACK-CHAT.md graph hunks).
  - **C3** is freely parallel to the C2→C4 chain (file-disjoint: skills + OPTIONAL-FEATURES + CONCEPTUAL-REVIEW).
- **Max concurrency: 3 worktrees** (the C2→C4 chain; C3; the C5→C6 project chain). S-RT does not change this — it rides inside C2's existing worktree.

### 4.4 Per-wave worktree mechanics (F-11 + Constraint 1; rules 1/3/7/8/9)

For EACH concurrent commit in a wave:
1. **Own worktree.** Each concurrent commit = its OWN isolated worktree (rule 1). The FIRST coder of the commit CREATES it; fix-coders REUSE it (never a new worktree).
2. **baseRef:head, shared base.** Every concurrently-created worktree bases at local HEAD (`worktree.baseRef:"head"`, rule 8); concurrent worktrees in a wave all branch from the SAME pre-wave HEAD. A later wave's worktrees are created ONLY AFTER the prior wave's commits land (Wave 1's worktrees base on Wave 0's landed keystone — the orchestrator does NOT create a Wave-1 worktree before Wave-0's keystone lands; the C2→C4, C5→C6 edges encode this).
3. **RO reviewer/fix-coder RULE-FIXED.** The commit's own reviewer/fix-coder is RULE-FIXED to that commit's worktree (rule 3/8/9a) — cd in + verify pwd/HEAD; NO rule-9 ASK. Any NON-cycle agent spawned during a live wave (an architect, a cross-cutting fix, a new task) triggers the **rule-9 ASK gate** (the orchestrator ASKS the human BOTH placement AND disposition — reuse vs abandon; never self-decides).
4. **Teardown gate (Constraint 1).** Remove a commit's worktree ONLY after that commit is CONFIRMED landed (commit exit 0). A FAILED/aborted commit ⇒ KEEP the worktree as the recovery fallback; never tear down on a failed/attempted commit; never rely on auto-removal.
5. **Conflict protocol at the post-review-clean step.** The apply-time conflict protocol (PACK-CHAT.md / PM-CHAT.md) applies at the POST-review-clean patch step (rule 4), not an up-front-patch step. For serialized same-file commits (C4 after C1/C2; C6 after C5) conflict risk is eliminated by ORDERING, not 3-way merge. Concurrent commits in a wave are file-disjoint by construction → no in-wave conflict.

### 4.5 Within-commit task ordering (where meaningful)
- **C2:** T(S3) PACK-CHAT.md; T(S7) pack-coder ×3; T(S-RO) RO defs ×12; T(S-RT) `RUNTIME-SUBAGENT-PATTERN.md` — all file-disjoint → independent within the commit (any order; same worktree).
- **C4:** the two CLAUDE.md hunks (G1, G4) SERIALIZE within one coder task (same file); G2 (PACK-CHAT.md) + G3 (PACK-AGENTS.md) are file-disjoint and may follow in the same worktree.
- **C5:** S10 (PM-CHAT.md) edits one file (serialize within one task); S13 ×3 and S13b ×3 are file-disjoint from PM-CHAT.md and each other (same worktree).
- **C6:** S12, S17, S14, S-AR, S11 are all distinct files → independent within C6's worktree.

### 4.6 Serial fallback order (parallelism unavailable)
A valid serial order respecting the edges {C1<C2, C1<C3, C1<C4, C2<C4, C5<C6}: **C1 → C5 → C2 → C3 → C6 → C4**. (C4 last is sufficient — it depends on C1 AND C2, both earlier. C6 after C5. C3 after C1. C5 has no pack dependency.) BK-1, BK-2 land at the batch boundary in either regime.

### 4.7 Rule-10 ENCODING for FUTURE efforts (this is also content the plan ships)
The codified text (S1/S3 pack; S10 project) MUST state that for ANY multi-commit effort the architect + planner produce this parallel-vs-dependent map in its OWN section, and the orchestrator schedules parallel worktree waves vs serial commits from it (same-file ⇒ serialize; baseRef:head; teardown gated on commit-landed; rule-9 ASK for non-cycle spawns).
- **PACK (S1 / S3):** "Pack Chat consumes the map to schedule parallel worktree waves vs serial commits."
- **PROJECT (S10):** "the PM chat consumes the map to schedule parallel worktree waves vs serial commits." (Project audience; NO `pack-*`/BD-NNN.)

---

## 6. BOUNDED REVIEW/FIX CYCLE PER COMMIT (UNCHANGED — only WHERE it runs)

The cycle is the standing pack process; BD-226 does NOT change it (rule 5). Per commit C1-C6:

1. **Spawn the coder** (fresh instance, per-commit fresh-coder) IN the commit's worktree (when parallel) or against the canonical tree's HEAD (serial fallback). Coder does edits + verification + Writes IMPL-REPORT to the named `/tmp` handoff dir + emits PREFLIGHT. Coder does NOT emit a patch up front (rule 4).
2. **Spawn the reviewer** (fresh, RO) — RULE-FIXED to the commit's worktree (rule 3/8/9a; cd in + verify pwd/HEAD); reads the work IN the worktree, writes its report to `/tmp`.
3. **Pack Chat triages** every finding (BLOCKER/MUST/SHOULD/NIT) fix-or-defer (default FIX-ALL); presents the triage to the user; user may override per finding before fix-coder spawns.
4. **Fix-coder** (fresh, REUSES the commit's worktree — NEVER a new worktree) applies the triaged fixes. Then a post-fix reviewer ALWAYS runs.
5. **Bounded:** ≤2 review/fix pairs + 1 final reviewer pass per commit. If still dirty after the final pass, STOP the cycle and spawn `pack-architect` to diagnose — no fix-coder pass 3.
6. **Patch only after review-clean (rule 4).** Once a reviewer confirms CLEAN, the orchestrator re-engages the most-recent RW agent (SendMessage on the pack side) to produce `git diff > <handoff>/changes.patch`; the orchestrator `git apply`s + commits with user approval.
7. **Teardown after commit lands (rule 7 + Constraint 1).** Remove the worktree ONLY after the commit lands exit 0; a failed commit KEEPS it.

This cycle is IDENTICAL in the serial fallback (the worktree is the canonical-HEAD-based per-commit worktree either way; only the wave concurrency differs).

---

## 7. SEQUENCING SUMMARY + RISK NOTES

### 7.1 Sequencing summary (serial-first, parallel-optional)
1. **C1** (pack keystone) — establishes the flipped default + class SSOT.
2. **C5** (project keystone) — file-disjoint from C1; may run concurrently (Wave 0).
3. **C2** (pack orchestrator + defs + S-RT) — after C1.
4. **C3** (pack skills + OF + conceptual-review) — after C1; concurrent with C2→C4.
5. **C6** (project OF + skill + prompts + launcher) — after C5.
6. **C4** (graph inject, CLAUDE-only) — after C1 AND C2 (last in the serial order).
7. **BK-1** (BD-235 entry + `_toc.md`) + **BK-2** (Constraint-3 reports → `maintenance-docs/v11-implementation/`) — batch boundary.
8. **Batch-end reviewer pass** + the whole-side union grep ×2 (once pack, once project).

### 7.2 Acceptance-criteria coverage (BD-226 § Acceptance criteria → where addressed)
- Model stated once + re-applied to both surfaces audience-correctly → S1/S3/S4 (pack) + S10/S12/S13/S13b/S14/S17 (project); P-missed-7 normalization in C5/C6 headers.
- Fix-coders forbidden a new worktree → S1, S3, OPTIONAL-FEATURES F-13 why-not, PM-CHAT S10; §6 step 4.
- RO agents routed to the work's tree → S1, S4, S-RO ×12, S15.
- Patch only after review-clean via SendMessage → S1, S3, S7, S-RT, S8; §6 step 6.
- Orphaned worktrees removed after their commit → S1, S3 (Constraint 1), S10; §4.4 step 4.
- Claude-only, Codex/Antigravity serial → C4 F-1 CLAUDE-only; §4.0 (serial fallback for non-worktree CLIs, BD-217 out of scope).
- `validate-pack` green + NO client-install/boundary regression → §3 full CI battery per commit; §5.2 leak gates; pack/project separation (C1-C4 vs C5-C6).
- Rule-10 parallelization map in its own section → §4; encoded for future efforts via S1/S3/S10 (§4.7).

### 7.3 Risk notes
- **R1 — Lock-step drift across `.md`/`.toml` (highest risk).** S7 ×3, S-RO ×12, S15/S16 ×3, S13/S13b ×3 each edit one CLI-format triad. RISK: a coder flips the `.md`/`.agents-plugin` copy but leaves the `.codex/.toml` stale (or byte-copies instead of normalizing). MITIGATION: §2.5 master table; one coder task per surface; per-commit lock-step verification (`diff`-the-intent across copies, content-intent matched not byte-identical); the per-commit union grep = 0 over the commit's files would catch a missed copy.
- **R2 — Whole-tree gate omission (the F-A class).** RISK: a hand-listed directory array silently omits `.agents-plugin/` (the original defect that blinded the gate to 11 hits). MITIGATION: §3 batch-end whole-side grep uses the `git ls-files`-anchored whole-tree-minus-exclusions form (names NO directory to include → cannot omit one); empty-residual proof (§8 EB-3) is the completeness guarantee.
- **R3 — Scope-keyword token trap (Check 36).** RISK: C2's subject accidentally naming a project path (S-RT is `.agents-plugin/` = pack-side, safe — but a careless subject could still mis-claim); a denying scope-token anywhere in a subject (incl. prose) is a Check-36 claim. MITIGATION: §2 fixed subjects carry no cross-side path; verify each commit's `git diff --name-only` against its keyword before finalizing.
- **R4 — Trinity body-divergence silent miss (C1).** RISK: Check 18/45 are body-agnostic and do NOT catch divergence within `## Pack memory`; the CLAUDE-only keystone is an INTENTIONAL divergence that must not be "restored to parity." MITIGATION: §3 C1 manual body-parity hand-verify; document the intentional divergence in the C1 + C4 IMPL-REPORTs.
- **R5 — Project leak (pack-self / BD-NNN / graphify into project content).** RISK: a coder imports a `pack-*` name, a `BD-NNN`, or graph content into a C5/C6 restatement. MITIGATION: P-missed-7 audience-normalization headers in C5/C6; §5.2 leak gates = 0 (verified baseline 0); F-F audience-leak grep scoped to the S10 edit region.
- **R6 — Constraint-2/3 baked literal.** RISK: a coder writes a machine-specific graph path (C4) or a baked `maintenance-docs/v11-implementation/` / phase path (C2/C5). MITIGATION: §5.3 no-hardcoded-path gate (C4); §3 C5/C6 derivation checks (the surface states the DERIVATION formula, not the literal).
- **R7 — C4 ordering (depends on BOTH C1 and C2).** RISK: C4 run before C2 lands → PACK-CHAT.md graph hunk (G2) collides with S3. MITIGATION: §4.2 same-file-serialize; the serial fallback puts C4 last; the wave schedule gates C4 on both keystone-and-C2 landing.
- **R8 — S-RT/twin asymmetry "fix."** RISK: a coder "restores symmetry" by editing the verified-clean project twin (injecting a project path into pack-only C2). MITIGATION: §2.5 NON-targets list; C2 verification confirms the twin UNTOUCHED + C2 diff is pack-only.

### 7.4 Blocking gaps
**None.** The design is census-verified-complete and self-contained; the planner re-measured every copy set, S-RT, agent-run.sh, the baselines, and the BK state at HEAD a84094a (§8) and every measurement SUPPORTS the design. No GAP or contradiction blocks planning.

---

## 8. EMPIRICAL-EVIDENCE BLOCKS (planner re-measured THIS pass)

All measured at **HEAD `a84094aa7fa2bda0213f66fb1588fdd162d92247`**, **2026-06-19**, IN-PLACE in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (`pwd` = `git rev-parse --show-toplevel`; branch `v11-dev` — all verified by `git rev-parse HEAD` + `git branch --show-current` + `git rev-parse --show-toplevel`).

**EB-1 — the ×3 copy sets + shared-file edges (the partition + dependency facts).**
- Command: `git ls-files | grep -E 'agents/pack-coder\.(md|toml)$'`; `git ls-files | grep -E 'agents/pack-(architect|planner|reviewer|docs-researcher)\.(md|toml)$'`; `git ls-files | grep -E 'project-template/.*agents/(coder|repo-ops)\.(md|toml)$'`.
- Output: pack-coder canonical copies = `.claude/agents/pack-coder.md`, `.agents-plugin/pack-agents/agents/pack-coder.md`, `.codex/agents/pack-coder.toml` (3); 4 RO defs × 3 surfaces = 12 canonical files (`.claude/agents/*.md`, `.agents-plugin/pack-agents/agents/*.md`, `.codex/agents/*.toml`); project coder ×3 (`.claude/agents/coder.md`, `.agents-plugin/optiquity-agents/agents/coder.md`, `.codex/agents/coder.toml`); project repo-ops ×3 (same triad with `repo-ops`). (Additional `scripts/tests/fixtures/customization-preserve/**` copies appeared — these are test-fixture snapshots, NOT canonical defs, excluded from edit scope.)
- Interpretation: the design's S7 ×3 / S-RO ×12 / S13 ×3 / S13b ×3 lock-step is confirmed; the fixture copies are correctly NON-targets.
- Conclusion: **SUPPORTED** (×3/×12 lock-step confirmed; fixtures excluded).

**EB-2 — skill triads + S-RT twins.**
- Command: `git ls-files | grep -E 'commit-discipline/SKILL\.md$'`; `… implementation-report/SKILL\.md$`; `git ls-files | grep -i RUNTIME-SUBAGENT-PATTERN`.
- Output: commit-discipline SKILL ×3 = `.claude/skills/`, `.codex/skills/`, `.agents/skills/`; implementation-report SKILL ×3 = same triad. S-RT twins = `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (pack) + `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (project). The pack twin L86-88 carries "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then emit a patch + report." The project twin grep for OLD-model phrases (`isolated regime|in-place regime|emit[a-z]*[^.]*patch|patch \+ report|opt-in|merge-back|survives.*auto-removal`) → EMPTY (CLEAN).
- Interpretation: skill triad third member is `.agents` (NOT `.agents-plugin`) — different from the pack DEF triad's third member (`.agents-plugin`); the coder must use the correct triad per surface. S-RT pack twin is a real OLD-model surface (F-B); the project twin is a verified NO-OP.
- Conclusion: **SUPPORTED** (skill triads = `.claude`/`.codex`/`.agents`; S-RT pack carries OLD model, project twin clean).

**EB-3 — pack baselines + whole-tree union file set + empty residual (the gate facts).**
- Command: `git ls-files -z | xargs -0 grep -IlE "isolated regime|in-place regime|emit[a-z]*[^.]*patch" | grep -vE '^maintenance-docs/|^backlog/|^test-fixtures/|^scripts/tests/fixtures/|^changelog/'`; plus per-phrase occurrence counts over tracked files.
- Output: the union (minus exclusions) file set is exactly: the 5 `.agents-plugin/pack-agents/agents/*` defs + `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md`; the 5 `.claude/agents/pack-*` defs; the 5 `.codex/agents/pack-*` defs; `.claude`/`.codex`/`.agents` commit-discipline + implementation-report (6 skill files); `CLAUDE.md`; `pack-ops/{OPTIONAL-FEATURES,PACK-AGENTS,PACK-CHAT,PACK-MEMORY-RATIONALE}.md`; project coder ×3; `project-template/agent-run.sh`; `project-template/docs/pack/{OPTIONAL-FEATURES,PM-CHAT}.md`; `project-template/skills/implementation/SKILL.md`; and `scripts/lib/tracker-edit.sh` + `scripts/pack-tracker.sh`. The ONLY files OUTSIDE the two side-arrays are the two `scripts/` tracker false-positives ("patch JSON", unrelated to agent patches → KEEP). The design's canonical pack-array baselines (isolated=31 / in-place=22 / emit=21) match this file set's composition (the `.agents-plugin` 5 defs + S-RT contribute the deltas over the old `.agents-plugin`-excluded count). Note: my raw whole-tree `-o` occurrence counts are higher than the design's per-phrase line counts because they span doc-history the design EXCLUDES and count occurrences not lines — but the model-bearing FILE SET is identical to the design's.
- Interpretation: F-A confirmed — the whole-tree-minus-exclusions form names no directory and cannot omit `.agents-plugin`; the empty residual (only tracker false-positives outside the arrays) is the directory-completeness guarantee.
- Conclusion: **SUPPORTED** (whole-tree gate form; empty-residual proven; the two tracker false-positives are the only un-arrayed hits).

**EB-4 — agent-run.sh FOUR locations (S-AR 2-KEEP/2-STRIP).**
- Command: `sed -n '170,180p'`, `sed -n '273,280p'`, `sed -n '304,309p'`, `sed -n '604,610p' project-template/agent-run.sh`.
- Output (verbatim): L173-176 `--worktree` help "(claude only) Run the agent in an isolated git worktree … SECONDARY/opt-in — probe cwd-scoping once before relying on it"; L275-278 run_in_worktree comment "the PM-chat merge-back applies the patch the agent leaves; see docs/pack/PM-CHAT.md … and docs/pack/OPTIONAL-FEATURES.md"; L306-307 echo "The agent never commits; bring its work back via the PM-chat patch merge-back."; L606-608 branch comment "SECONDARY isolated-worktree path (opt-in). See run_in_worktree for the cwd-scoping caveat + manual fallback."
- Interpretation: L173-176 + L606-608 annotate the launcher's `--worktree` flag (launcher-level opt-in → KEEP); L275-278 + L306-307 are the OLD up-front-patch timing (STRIP → post-review-clean reword). Matches the design's F-C classification exactly.
- Conclusion: **SUPPORTED** (4 locations; 2 KEEP / 2 STRIP).

**EB-5 — project leak baselines + S18 + S2 no-op + BK state + impl-reports absence.**
- Command: `grep -rEn "BD-[0-9]"` over the C5/C6 project surfaces; `grep -rEn "graphify|graph.json|--graph" project-template supporting-docs`; `sed -n '190,198p' pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`; `grep -c "Sub-agent behavior" AGENTS.md GEMINI.md`; `git status --short backlog/`; `git ls-files | grep docs/impl-reports`; `grep -n "agents-never-commit" pack-ops/.spawn-rule-manifest.txt`; `grep -n "Pack Chat" project-template/docs/pack/PM-CHAT.md`.
- Output: project BD-[0-9] = 0; project graphify = 0. S18 line present: "Spawn sub-agents in background; sub-agents run in-place by default, with opt-in worktree isolation (BD-197)". AGENTS/GEMINI "Sub-agent behavior" = 0/0. `git status --short backlog/` → ` M backlog/_toc.md` + `?? backlog/BD-235.md`. `docs/impl-reports` → ABSENT. `agents-never-commit` slug @ manifest L24. PM-CHAT.md "Pack Chat" refs at L342 + L344 (pre-existing, OUTSIDE the S10 L470-532 region).
- Interpretation: project leak gates correctly sized to 0; S18 flip target confirmed (BD-197→BD-226); S2 no-op confirmed; BK-1 state confirmed (`_toc.md` modified + BD-235 untracked, both out of scope); `docs/impl-reports/` is a NEW subtree the S10 rule introduces by derivation; manifest slug stable; F-F pre-existing "Pack Chat" refs confirmed out of the S10 region.
- Conclusion: **SUPPORTED** (all project/CI/BK facts confirmed).

---

## R. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran read-only git verbs only: `git rev-parse HEAD` → `a84094aa7fa2bda0213f66fb1588fdd162d92247`, `git branch --show-current` → `v11-dev`, `git rev-parse --show-toplevel`, `git ls-files`, `git status --short backlog/`; plus `grep`/`sed -n`(read)/`wc`/`mkdir /tmp/...`/Read. No add/commit/apply/worktree/branch/reset/restore/checkout/mv/rm/stash. Sole write = this plan at `/tmp/handoff-bd226-plan2/PLAN-BD-226-FINAL.md` (caller-specified, under `/tmp`, outside the repo). No repo state changed. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op attempted; the untracked `backlog/BD-235.md` + modified `backlog/_toc.md` were NOT touched (recorded as BK-1 out-of-scope, only `git status` read). | COMPLIANT |
| **deferral-is-scope-creep** | Planned ALL in-scope BD-226 work (C1-C6, every lock-step copy + S-RT + S-AR 4 locations + all gates) into this batch; deferred nothing unblocked. BD-235/BD-217/BD-218 are the BD's pre-authorized out-of-scope items (reference only). | COMPLIANT |
| **no-deferral-without-user-direction** | Invented no deferrals; the only out-of-scope items are the BD's own pre-authorized deferrals. | COMPLIANT |
| **graph-first-context** | Exact-string completeness work → used grep/Read (the rule's own fall-through for exact-string + SSOT + freshly-changed-file cases); the design notes the graph token-collides on prose for this work; no relationship/orientation question needed a graph query. | COMPLIANT |
| **preflight-stop-means-stop** | No parent stop received; the full plan completed and was written to the named path. | COMPLIANT |
| **rules-applied-verification-block** | This table; every row carries a measurement/quote + terminal conclusion (no empty cells, no AMBIGUOUS). | COMPLIANT |
| **empirical-evidence-blocks** | §8 EB-1..5: each state-claim (×3/×12 copy sets; skill triads + S-RT twins; whole-tree union file set + baselines + empty residual; agent-run.sh 4 locations + 2/2 classification; project leak=0 + S18 + S2 no-op + BK state + impl-reports absence) has command + verbatim output + HEAD a84094a + 2026-06-19 + interpretation + SUPPORTED. The ×3 copy sets + S-RT were re-measured by me, not taken from the design. | COMPLIANT |
| **enumerate-encoding-surfaces** | §2.5 master table enumerates every duplicated copy (pack-coder ×3, 4 RO ×12, commit-discipline ×3, implementation-report ×3, project coder ×3, project repo-ops ×3) + S-RT; each surface → ONE coder task (§2). §5 confirms no test/validator encodes the OLD default (no hand-asserted fixture; install snapshots regenerated). | COMPLIANT |
| **ci-guard-measure-then-bound** | §3 batch-end gate uses the whole-tree-minus-exclusions form (cannot omit a directory — empty-residual EB-3); the KEEP allowlist is sized exactly to the census KEEP classes (history-excluded, fixtures-excluded, 2 script false-positives, the moot self-detect/verb-ban, the reworded mechanism sentence, the 2 agent-run.sh launcher-flag lines); expected post-flip model-phrase remainder = 0; measured the tree FIRST (EB-3), classified every occurrence (§2.5 NON-targets + §2 S-AR table), verified the projected post-fix gate runs clean (empty residual). | COMPLIANT |
| **pack-project-separation-of-concerns** | C1-C4 (`pack-only`) and C5-C6 (`project-only`) never mix; each single-scope (Check 36, §2/§5). S-RT is pack-only (C2); its project twin is a verified-clean NO-OP, not edited (§2.5 NON-targets). F-1 graph fix is pack-only/CLAUDE-only (C4). | COMPLIANT |
| **bd-pack-only-operational-rule** | §5.2 project BD-[0-9]=0 gate (baseline 0, EB-5); zero BD-NNN in any project restatement; project deferral phrased "a future pack version". | COMPLIANT |
| **cross-cli-reference-normalization** | §2.5 + §2 require the ×3 def/skill edits to respect each CLI format (`.md` vs `.toml`), content-intent matched not byte-copied; C5/C6 project restatements audience-correct (P-missed-7 headers). | COMPLIANT |
| **worktree-isolation-mergeback-ops** | §4/§6 reflect rules 1-10 + Constraint-1 teardown gate (§4.4 step 4) + report-location-always-/tmp + Constraint-3 merge-back (S3/S10); the bounded review/fix cycle (§6) is UNCHANGED (only WHERE it runs). | COMPLIANT |
| **rename-plans-measure-then-bound** | The flip-completeness gate is a coder-PREFLIGHT + reviewer KEEP-allowlist assertion over the whole-tree `git ls-files` union grep (§3 / §5.1-form), NOT a hand-enumerated anchor list; the whole-tree form cannot omit a directory (empty-residual EB-3). | COMPLIANT |
| **verify-full-ci-suite** | §3 every commit runs the FULL CI battery (validate-pack all checks + DEEP + sharded suites + `build.sh --verify`), not validate-pack alone. | COMPLIANT |
| **commit-subject-keyword-token-trap** | §2 each commit's fixed subject carries one scope keyword matching its diff; C2's subject names no `project-template/` path (S-RT is `.agents-plugin/…` = pack-side); C6's subject names no pack path; §5/§7.3 R3 require verifying `git diff --name-only` against the keyword before finalizing. | COMPLIANT |

---

*End of coder-ready IMPLEMENTATION PLAN for BD-226. Encodes `/tmp/handoff-bd226-final/DESIGN-BD-226-FINAL.md` (FINAL design) + `backlog/BD-226.md` (rules 1-10). Six substance commits C1-C6 (C1-C4 pack-only; C5-C6 project-only) + bookkeeping BK-1/BK-2; serially executable (`C1 → C5 → C2 → C3 → C6 → C4`) with an optional 3-worktree wave schedule. All copy sets + S-RT + agent-run.sh + baselines + BK state re-measured at HEAD a84094a; no blocking gap.*
