# DESIGN — BD-226 (FINAL, PLANNER-READY): Sub-agent worktree-isolation overhaul

**Agent:** pack-architect (FRESH final-amendment author, READ-ONLY). **Repo:** optiquity-ai-agent-config-pack, branch `v11-dev`. **HEAD:** `a84094a` (= `a84094aa7fa2bda0213f66fb1588fdd162d92247`, verified `git rev-parse HEAD`). **Regime:** IN-PLACE in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (pwd + `git rev-parse --show-toplevel` identical; `git branch --show-current` = `v11-dev`). **Deliverable:** this ONE FINAL design doc. **No repo edits, no commit, read-only git verbs only.**

> **This doc SUPERSEDES `/tmp/handoff-bd226-reconcile/DESIGN-BD-226-RECONCILED.md`.** It is the reconciled design + the verified-complete whole-tree census corrections + the adversarial-plan review's settled corrections (F-A..F-G + the expanded phrase union). **Rules 1-10 in `backlog/BD-226.md`, the six user decisions (A1, B1, C1-extended, D1, E2, F), the report-location decision, and Constraints 1-3 are SETTLED — this doc CODIFIES them, it does not re-litigate them.** The planner reads ONLY this doc + `backlog/BD-226.md`; the doc is therefore self-contained (no "see the census for X").
>
> **The whole-tree census found NO new missed surfaces beyond F-A/F-B/F-C and NO severe design flaw** (census §1, §7). This is a FOCUSED AMENDMENT folding settled completeness corrections, NOT a redesign.

---

## AMENDMENT LEDGER (what changed vs the reconciled design)

| Correction | Severity | Where folded in this FINAL doc | Net effect |
|---|---|---|---|
| **F-A** — gate scope | BLOCKER | §5.1 (replaced the hand-listed pack array with the whole-tree-minus-exclusions form + empty-residual proof; restated baselines isolated=31/in-place=22/emit=21; side-array convenience form now INCLUDES `.agents-plugin`) | gate structurally cannot omit a directory |
| **F-B** — omitted surface | MUST | §1.2 (new surface S-RT), §2 (S-RT delta), §3 commit **C2** (gains S-RT, still single-scope pack-only), §4 (no wave-structure change — S-RT rides C2 in the C2→C4 chain). Project twin recorded as explicit NO-OP. | one pack-self model-encoder now flipped; project twin not "fixed" by mistake |
| **F-C** — agent-run.sh under-scoped | MUST | §2 S-AR widened to all FOUR locations with an explicit per-location KEEP/STRIP classification | the launcher's stale OLD framing fully classified |
| **F-D** — tighten allowlist | SHOULD | §5.1 (expected post-flip union remainder for the listed phrases = 0; allowlist reserved ONLY for an explicitly-reworded residual mechanism sentence) | stricter gate; would have surfaced F-A |
| **F-E** — per-commit grep scope | SHOULD | §5.5 (per-commit union grep = THAT commit's own file set; whole-side union grep = once at BATCH END) | the gate is satisfiable per-commit AND complete at batch end |
| **F-F** — C5 audience-leak grep | NIT | §5.6 (audience-leak grep scoped to the S10 EDIT region; PM-CHAT.md pre-existing "Pack Chat" refs ~L342/344 are out of scope) | no false-positive on pre-existing state |
| **F-G** — G2/G3 are ADDs | NIT | §2 G2/G3 phrased as "ADD near <anchor>" | coder does not hunt for non-existent text |
| **Expanded phrase union** (census §5.3) | verification tightening | §5.1 (the gate's phrase set gains the discovered variants; the EDIT list does NOT grow — every variant is within an already-enumerated surface or the F-B add) | the gate can VERIFY the variants, not just flip them |

**Everything else is UNCHANGED from the reconciled design** and carried forward verbatim in substance: the ×3 lock-step enumeration (pack-coder ×3; 4 RO pack defs ×3 = 12; project coder ×3; project repo-ops ×3; skills ×3); F-1 (CLAUDE-only graph fix + Trinity-exempt note); the E2 commit partition (C1-C4 pack-only, C5-C6 project-only; C4 serial after C1+C2); report-location-always-/tmp; Constraints 1/2/3 (teardown gate; no-hardcoded graph path; report preservation to derived `maintenance-docs/<ver>/` + `docs/impl-reports/<phase>/`); the bounded review/fix cycle; D1 (no project-template trinity edit).

---

## 0. LEDGER (decisions + findings → where encoded)

| Input | Disposition | Encoded in |
|---|---|---|
| **A1** worktree substance in PM-CHAT.md; METHODOLOGY ≤1-line xref | honor | §1 S10 (substance), S11 (METHODOLOGY xref-only / likely no-op) |
| **B1** (as amended by F-3) targeted OPTIONAL-FEATURES edits; baseRef/permissions.deny verbatim; the 2 caveats NOT verbatim | honor + F-3 amendment | §2 S6 / S12 |
| **C1-extended** do NOT pin `isolation` in ANY RW frontmatter; document the WHY-NOT (single-value param ⇒ pin forces new worktree per spawn ⇒ breaks fix-coder reuse rules 1/3/7) | honor; F-13 deletes the inverted "MAY pin" framing | §2 S6/S12 + S7 (pack-coder) + S13 (project coder) + S13b (repo-ops) |
| **D1** NO project-template trinity edit | honor | §1 (trinity row = explicit no-op) |
| **E2** graph addendum = STANDALONE commit C4; accept serialization | honor | §3 commit table; §4 wave schedule |
| **F** MERGE-STRATEGY no touch; PACK-MEMORY-RATIONALE REQUIRED (retargeted per F-5) | honor | §2 S8 (retargeted to `## agents-never-commit`) |
| **F-1** USER OPTION A — graph fix in **CLAUDE.md ONLY** + Trinity-exempt note; AGENTS/GEMINI graph-first stays as-is | USER OVERRIDE of the all-trinity rec | §2 G-surfaces; §6 trinity note |
| **F-2** 4 RO pack defs ×CLIs; replace binary RO-emit framing with rule-1 placement | FIX | §2 S-RO (×3 CLIs = 12 files) |
| **REPORT-LOCATION** every agent report → named /tmp handoff dir ALWAYS (no regime conditional) | settled | §2 S-RO, S7, S10/S13, S17; Constraint 3 |
| **F-3** the 2 OPTIONAL-FEATURES caveats reworded (mechanism kept; patch-timing → rule 4/7/Constraint 1) | FIX, amends B1 | §2 S6/S12 |
| **F-4** add project `agent-run.sh` rework (widened by F-C to 4 locations) | FIX (project-only) | §2 S-AR |
| **F-5** retarget RATIONALE edit to `## agents-never-commit`; leave the routing rationale; union-grep the whole RATIONALE | FIX | §2 S8 |
| **F-6** repo-ops = coder's twin (verb-ban ≠ isolation barrier; harness creates the worktree); same isolation/no-pin treatment | FIX | §2 S13b |
| **F-7** §4 = E2 binding schedule; C4 standalone | FIX | §4 |
| **F-8** graceful degradation (CLAUDE-only per F-1): inject path only when graph.json exists; G1 check on injected path; G2 fallback unchanged | FIX | §2 G-surfaces; Constraint 2 |
| **F-9** decouple regime(=which tree) from patch-emit(=RW-only) in skills | FIX | §2 S15 (pack ×3) + S17 (project) |
| **F-10** delete "survives auto-removal" rationale; rework the reason | FIX | §2 S16 (pack ×3) + S17 |
| **F-11** per-wave worktree mechanics in §4 | FIX | §4 |
| **F-12** CONCEPTUAL-REVIEW L194 = REQUIRED edit (was "candidate/skip") | FIX | §2 S18 |
| **F-13** DELETE the "MAY pin" framing; replace with C1 why-not note | FIX | §2 S6/S12, S7, S13/S13b |
| **F-A** gate scope = whole-tree-minus-exclusions; corrected baselines | BLOCKER (census) | §5.1 |
| **F-B** add `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (S-RT) | MUST (census) | §1.2 S-RT; §2 S-RT; §3 C2 |
| **F-C** widen agent-run.sh S-AR to 4 locations + classify each | MUST (census) | §2 S-AR |
| **F-D** tighten allowlist (post-flip remainder = 0) | SHOULD | §5.1 |
| **F-E** per-commit grep = own file set; whole-side grep at batch end | SHOULD | §5.5 |
| **F-F** C5 audience-leak grep scoped to the EDIT region | NIT | §5.6 |
| **F-G** G2/G3 graph-inject = "ADD near <anchor>" | NIT | §2 G2/G3 |
| **Constraint 1** rule-7 teardown gated on commit-confirmed-landed; failed commit KEEPS worktree | settled | §2 S1/S3/S10; §4 |
| **Constraint 2** no hardcoded path; orchestrator derives at runtime + injects literal; agent uses verbatim | settled | §2 G-surfaces; §5 gate |
| **Constraint 3** orchestrator moves all /tmp reports into the tree + commits them; pack→`maintenance-docs/<active-ver>/`; project→`docs/impl-reports/<phase>/` | settled | §2 S3 + S10; §5 |
| **OUT OF SCOPE** BD-235 (project shared-discipline skill), BD-217 (Codex/Antigravity worktree), BD-218 (background-session isolation) | reference only | §1 note; §7 |

---

## 1. FINAL SURFACE INVENTORY (side-tagged; lock-step duplicates marked)

The generalized model (rules 1-10) is stated ONCE (canonical short form in §1.1) and re-applied to APPLICATION A (pack) + APPLICATION B (project). Per P-missed-7, every B-surface RESTATES for the project audience ("the PM chat", "your `coder`/`reviewer`"), never a byte-copy and never a pack-self ref (`pack-*`, `pack-ops/`, `BD-NNN`, Graphify).

### 1.1 The canonical model (rules 1-10, settled — the codification target)

1. **Default by class.** RW agents (coders/fix-coders) → isolated worktree. The FIRST coder of a commit CREATES it; every later RW agent in that commit's cycle (fix-coders) REUSES it — NEVER a new worktree for a fix-coder. RO agents (reviewers/architects/planners/auditors/researchers) → the tree the work lives in (main when committed; the live worktree when the work is still uncommitted there). RO is NOT "always in-place".
2. **Governing bias.** NEVER apply/patch/commit known-buggy or not-yet-reviewed work to the canonical tree.
3. **Per-commit worktree holds the WHOLE cycle.** The entire review/fix cycle for a commit runs inside that one worktree; nothing reaches canonical mid-cycle.
4. **Patch only after review-clean.** No up-front patch. The patch is produced ONLY after an RO reviewer confirms CLEAN, by re-engaging (SendMessage on the pack side) the most-recent RW agent. The orchestrator then applies + commits (user approval).
5. **Bounded cycle unchanged.** ≤2 review/fix pairs + 1 final review; architect escalation if still dirty. Only WHERE the cycle runs changed.
6. **Spawning.** Each spawn is fresh/clean-context UNLESS SendMessage re-engages an existing agent (the rule-4 patch step is the deliberate exception).
7. **Lifecycle (refined by Constraint 1).** Fresh worktree per commit's first coder; remove a worktree ONLY after its commit is CONFIRMED landed (exit 0) — AFTER, not right-after-use; a FAILED/aborted commit ⇒ KEEP the worktree as the recovery fallback; NEVER tear down on a failed/attempted commit; NEVER rely on auto-removal.
8. **Mechanics.** Worktrees ALWAYS base at local HEAD (`worktree.baseRef:"head"`). An agent operating in a pre-existing worktree `cd`s in + VERIFIES pwd/HEAD at runtime. Agents NEVER commit/stage/apply.
9. **Live-worktree gate — ASK, don't self-judge.** Standard-cycle reviewer/fix-coder = RULE-FIXED to the commit's worktree (no ask). Any OTHER agent spawned while a live uncommitted worktree exists ⇒ ASK the human BOTH placement AND disposition (reuse vs abandon).
10. **Parallelization + dependency map.** Architect/planner deliverable in its OWN section (§4 here; and a rule to ENCODE for future efforts).

**APPLICATION A graph addendum (PACK-ONLY, CLAUDE-only per F-1).** The orchestrator derives the real graph path at runtime in its canonical checkout and injects the literal into every spawn prompt; agents query `graphify <verb> … --graph <injected literal>`, NEVER their own `$(git rev-parse --show-toplevel)` (which under worktree isolation resolves to the empty worktree root where gitignored `graphify-out/` is not materialized).

### 1.2 Surface table (every surface to edit)

**Legend.** Side = PACK / PROJECT. ×N = lock-step copies. "NEW vs reconciled" = surface the reconciled design did NOT enumerate (added by this final amendment).

#### APPLICATION A — PACK (commits C1-C4; `pack-only`)

| ID | Surface (file + symbol) | ×N | NEW? | Disposition source |
|---|---|---|---|---|
| S1 | `CLAUDE.md` § "Sub-agent behavior (Claude-only)" (keystone bullet "Sub-agents run in-place by default…") | 1 (CLAUDE-only) | — | rules 1-4,7,8,9 + Constraint 1 |
| S2 | `AGENTS.md` / `GEMINI.md` § Pack memory | — | — | explicit NO-OP (section verified absent; Claude-only exemption) |
| S3 | `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back" (L232-322) | 1 | — | rules 1-4,7,9 + Constraint 1 + Constraint 3 (pack merge-back) |
| S4 | `pack-ops/PACK-AGENTS.md` § "Two agent classes" + class roster (L139-155) | 1 | — | rules 1,4 (class SSOT) |
| S5 | `feedback_worktree_isolation_mergeback_ops` (out-of-repo memory) | — | — | already NEW model; Pack-Chat upkeep only — NOT a coder edit, NOT a commit |
| S6 | `pack-ops/OPTIONAL-FEATURES.md` § "Isolated parallel agents" (L111-265) | 1 | — | B1 targeted + F-3 caveats + F-13 why-not |
| S7 | pack-coder def: `.claude/agents/pack-coder.md` + `.agents-plugin/pack-agents/agents/pack-coder.md` + `.codex/agents/pack-coder.toml` (RW-emit step) | **3** | — | rule 4 + REPORT-LOCATION + F-13 why-not |
| S-RO | 4 RO pack defs (pack-architect/planner/reviewer/docs-researcher) × `.claude/agents/*.md` + `.agents-plugin/pack-agents/agents/*.md` + `.codex/agents/*.toml` = **12 files** | **12** | — | F-2 rule-1 RO placement + REPORT-LOCATION |
| **S-RT** | `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` L88 ("emit a patch + report") | 1 (pack-only; project twin CLEAN) | **YES (F-B)** | rule-4 reword of the RW class "emit a patch + report" |
| S8 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## agents-never-commit` (L31-37) | 1 | — | F-5 rule 4; LEAVE the routing rationale |
| S9 | `pack-ops/PACK-CHAT.md` § propagation procedure + `pack-ops/.spawn-rule-manifest.txt` | 1 | — | mechanism: slug-unchanged verify |
| S15 | `commit-discipline` SKILL × `.claude`/`.codex`/`.agents` (§1 regime detect + §2 write-target) | **3** | — | F-9 decouple regime↔patch-emit |
| S16 | `implementation-report` SKILL × `.claude`/`.codex`/`.agents` (§ intro + §1 + §4) | **3** | — | F-10 delete "survives auto-removal"; rework reason |
| S18 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` L194 | 1 | — | F-12 flip default + BD-197→BD-226 cite |
| G1 | `CLAUDE.md` § "Graph-first context (BD-225)" (L596-624; derivation L597,L610) | 1 (CLAUDE-only, F-1) | — | Constraint 2 + F-8 + F-1 exempt note |
| G2 | `pack-ops/PACK-CHAT.md` spawn-prompt construction (graph-path inject — ADD near the "Name the handoff dir" anchor ~L262) | 1 | — | Constraint 2 inject (F-G: ADD) |
| G3 | `pack-ops/PACK-AGENTS.md` spawn-syntax surface (graph note — ADD near `## How to invoke pack agents` / `claude --agent` block ~L46/L68) | 1 | — | Constraint 2 (F-G: ADD) |
| G4 | `CLAUDE.md` § "Agent invocation rules" spawn-syntax (graph inject note) | 1 (CLAUDE-only) | — | Constraint 2 |

#### APPLICATION B — PROJECT (commits C5-C6; `project-only`)

| ID | Surface (file + symbol) | ×N | NEW? | Disposition source |
|---|---|---|---|---|
| S10 | `project-template/docs/pack/PM-CHAT.md` § "Isolation is for RW only" + "Merge-back" (L470-532) | 1 | — | rules 1-4,7,9 + Constraint 1 + Constraint 3 (project merge-back) |
| S11 | `supporting-docs/METHODOLOGY.md` (install-source → client `docs/pack/METHODOLOGY.md`) | 1 | — | A1: ≤1-line xref; L720 likely no-op (already consistent) |
| S12 | `project-template/docs/pack/OPTIONAL-FEATURES.md` § "Isolated parallel agents" | 1 | — | B1 targeted + F-3 caveats + F-13 why-not (project audience) |
| S13 | project coder def: `project-template/.claude/agents/coder.md` + `…/.agents-plugin/optiquity-agents/agents/coder.md` + `…/.codex/agents/coder.toml` (Merge-back step) | **3** | — | rule 4 + F-13 why-not (project audience) |
| S13b | project repo-ops def: `…/.claude/agents/repo-ops.md` + `…/.agents-plugin/optiquity-agents/agents/repo-ops.md` + `…/.codex/agents/repo-ops.toml` | **3** | — | F-6 coder-twin treatment (ADD merge-back para) |
| S14 | `project-template/docs/pack/prompts/coder.md` + `reviewer.md` | up to 2 | — | targeted: reviewer reads work IN live worktree (rule 3/8); verify coder |
| S17 | `project-template/skills/implementation/SKILL.md` (single source → 3 client skill dirs at install) | 1 | — | F-9 + F-10 (project audience) |
| S-AR | `project-template/agent-run.sh` — **4 locations** (L173-176 `--worktree` help; L275-278 `run_in_worktree()` comment; L306-307 echo; L606-608 branch comment) | 1 | **widened (F-C)** | F-4 rule-4 reword + per-location KEEP/STRIP |
| S-RT(proj) | `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` | — | — | **explicit NO-OP** (twin verified CLEAN — F-B) |
| — | project-template trinity `CLAUDE/AGENTS/GEMINI.md` | — | — | **D1: NO EDIT** (explicit no-op) |

**Net: 19 PACK files of substance** (S1; S3; S4; S6; S7 ×3; S-RO ×12; **S-RT ×1**; S8; S18; G1; G2; G3; G4 — S2 no-op, S5 out-of-repo, S9 mechanism). **Plus project surfaces** (S10; S11; S12; S13 ×3; S13b ×3; S14 ≤2; S17; S-AR — S-RT(proj) no-op, trinity no-op). The reconciled design listed 18 pack files of substance; the FINAL adds S-RT (`RUNTIME-SUBAGENT-PATTERN.md`), bringing it to 19.

---

## 2. FINAL PER-SURFACE DELTAS

> All line numbers are measurement anchors at HEAD `a84094a` and WILL drift; the coder keys edits on the quoted text + named symbol, not the line number.

### APPLICATION A — PACK (Claude-only on the keystone; pack audience: "Pack Chat", `pack-coder`, `pack-reviewer`)

**S1 — `CLAUDE.md` § "Sub-agent behavior (Claude-only)" — the keystone (CLAUDE.md ONLY).**
Current opening bullet (verbatim, L339+): "**Sub-agents run in-place by default; isolation is opt-in.** … When isolation is active, read-write agents emit a patch to the named `/tmp` handoff dir and the orchestrator applies it…"
- REPLACE the bullet title + body with the class-keyed model: RW agents run in an isolated worktree by class (first coder of a commit creates it; fix-coders REUSE it, never a new worktree); RO agents run in the tree the work lives in (main when committed; the live worktree when uncommitted there — NOT "always in-place"). The patch is produced ONLY after review-clean by SendMessage-ing the most-recent RW agent; the orchestrator applies the reviewed-clean patch at commit time (rule 4).
- ADD rule-7 lifecycle WITH Constraint 1: remove a worktree ONLY after its commit is confirmed landed (exit 0); a failed commit KEEPS the worktree; never rely on auto-removal.
- ADD the rule-9 live-worktree ASK gate + a pointer to the rule-10 parallelization-map requirement (the architect/planner produce the map in its own section; Pack Chat consumes it to schedule parallel worktree waves vs serial commits).
- KEEP verbatim: the runtime-verify-regime (pwd/HEAD) line, `agents-never-commit`, `bgIsolation`→BD-218, the Claude-only "### Trinity exemption" bullet. Extend the "Agent-team stage lifecycle" bullet minimally to name the rule-4 post-review-clean patch step as a sanctioned SendMessage use (rule 6).
- The keystone bullet carries NO `[rationale:]` tag → it is OUTSIDE the Check-45 bijection; no slug churn.

**S2 — `AGENTS.md` / `GEMINI.md` § Pack memory — EXPLICIT NO-OP.** The "Sub-agent behavior" section is verified ABSENT from both (`grep -c "Sub-agent behavior" AGENTS.md GEMINI.md` = 0/0). Do NOT add it (would assert false cross-CLI parity). Recorded so the coder does not "restore parity".

**S3 — `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back" (L232-322).** The orchestrator contract — heaviest pack prose edit.
- L240-241 "Worktree isolation is an opt-in accelerator…; the default is in-place." → "RW agents run in an isolated worktree by class; RO agents run in the tree the work lives in."
- L248-254 "RW agent (`pack-coder`) → spawn ISOLATED when enabled." → "RW agent → spawn ISOLATED (always, by class); the first coder of a commit CREATES the worktree, fix-coders REUSE it (never a new worktree)."
- L255-257 "RO agents → spawn IN-PLACE (no isolation). … Omit the `isolation` parameter." → "RO agents → spawn in the tree the work lives in: main when the work is committed; the live worktree when the work is still uncommitted (cd in + verify pwd/HEAD, rule 8). RO agents emit NO patch."
- REWRITE "Merge-back" (L276-296): DELETE the up-front "emits the patch … and returns. The worktree may auto-remove on return — irrelevant" framing (L278-282). The whole review/fix cycle runs IN the worktree; the patch is produced ONLY after review-clean by SendMessage-ing the most-recent RW agent; THEN Pack Chat `git apply`s + commits. Add rule-7 + Constraint 1 teardown (remove the worktree only after the commit lands exit 0; failed commit keeps it).
- ADD the rule-9 ASK gate to the spawn-decision logic. ADD the rule-10 note (Pack Chat consumes the parallelization map to schedule parallel worktree waves vs serial commits).
- **Constraint 3 (pack merge-back rule):** after the commit lands, the orchestrator MOVES every agent report from its `/tmp` handoff dir into the tree and commits it, so nothing is lost to /tmp cleanup or worktree teardown. Destination is DERIVED at runtime, not baked: `maintenance-docs/<active-version-work-area>/` where the active-version dir is derived from the README version table (today `maintenance-docs/v11-implementation/`; the rule states the derivation, not the literal). The reports ride in a PAIRED commit immediately after the work's commit (keeps the work commit single-purpose + Check-36-clean; the report commit is `pack-only`, mixed-BD-report content allowed).
- The "Conflict protocol" (L297-322) STAYS as apply-time hygiene, reframed to apply at the post-review-clean patch step and cross-referenced to §4's serialized-same-file ordering (serialized same-file commits avoid conflicts by ordering, not 3-way merge).

**S4 — `pack-ops/PACK-AGENTS.md` § "Two agent classes" (L139-155).** Class SSOT.
- "When isolation is opted-in, an RW agent emits its `git diff` patch … and the orchestrator applies it" → "RW agents run in an isolated worktree (class-default); the patch is produced only after review-clean (the orchestrator SendMessage-s the most-recent RW agent); only the orchestrator applies it." Flip "RW agents MUST be spawned with worktree isolation" from opt-in framing to class-default. Add to the RO bullet: RO agents run in the tree the work lives in (not "always in-place").

**S5 — `feedback_worktree_isolation_mergeback_ops` (out-of-repo memory).** Already the NEW model (cites BD-226 SSOT). NOT a ship-target, NOT a coder edit, NOT a commit. Pack-Chat upkeep only if final rule wording shifts. No propagation gate (not in corpus/manifest/RATIONALE).

**S6 — `pack-ops/OPTIONAL-FEATURES.md` § "Isolated parallel agents" (L111-265). B1 targeted + F-3 + F-13.**
- "What it is" (L119-128): the RW narrative "The agent edits in the worktree, emits a `git diff` patch to a named handoff directory, and returns; Pack Chat reads the patch, runs the review/fix cycle, applies it" encodes the OLD up-front-patch ordering → reword to the in-worktree-cycle + patch-after-review-clean (rule 3/4). "Read-only agents … need NO isolation — they emit a report and write nothing" → "RO agents run in the tree the work lives in" (rule 1).
- "default floor" (L133-134): "the in-place (non-isolated) regime is the default floor" → in-place is the DEGRADED fallback, not the default; the class-keyed model is the default.
- **F-3 (amends B1) — the two caveats are NOT verbatim.** L237-242 "Auto-removal can delete unmerged branches": KEEP the MECHANISM sentence ("When an isolated subagent exits cleanly, Claude Code auto-removes its worktree and branch. A branch with unmerged commits can be silently deleted"); REWORD the consequence "which is why the pack's merge-back model captures the agent's work as a patch … BEFORE return (the patch survives auto-removal)" → "which is why the worktree is HELD through the whole review/fix cycle and explicitly removed only AFTER the commit lands (rule 7 + Constraint 1), and the patch is produced post-review-clean (rule 4), never pre-return." L243-246 "Best-effort isolation": reword "the orchestrator detects the ACTUAL regime from what the agent reports (a patch handoff ⇒ isolated; in-place edits ⇒ in-place)" → key regime detection on the agent's runtime pwd/HEAD ground-truth (rule 8), not on a patch-handoff signal.
- **F-13 (C1 why-not).** ADD on the RW class-default narrative: an RW subagent must NOT pin `isolation: worktree` in its frontmatter — the `isolation` parameter has only the value `"worktree"` (no `"off"`; OPTIONAL-FEATURES L142-144 "`"worktree"` is the ONLY valid value … `head` and `none` are SETTINGS values … NOT parameter values"), so a frontmatter pin forces a NEW worktree on EVERY spawn, and a fresh fix-coder could then not cd-REUSE the first coder's worktree (breaking rules 1/3/7). Per-spawn opt-in is retained.
- KEEP VERBATIM (B1): the `baseRef` block (L150-172) and the `permissions.deny` recipe (L185-232). KEEP the Trinity-exempt note (L256-259) and BD-217/BD-218 refs (pack-side, allowed).

**S7 — pack-coder def ×3 (`.claude/agents/pack-coder.md` + `.agents-plugin/pack-agents/agents/pack-coder.md` + `.codex/agents/pack-coder.toml`).** Lock-step (the 3 copies DIFFER by CLI format — enumerate-encoding-surfaces; the `.toml` carries the same RW-emit content in TOML prose).
- The RW-emit step ("in the isolated regime, also emit a `git diff` patch … In the in-place regime, leave the edits…") → rule 4: the coder does its edits + verification + Writes its IMPL report + returns; it does NOT emit the patch up front; the patch is produced ONLY when the orchestrator SendMessage-s it back after review-clean (`git diff > <handoff>/changes.patch` at THAT point). KEEP: never-stage/commit/apply; the `/tmp` handoff path.
- **REPORT-LOCATION:** the IMPL report goes to the named `/tmp` handoff dir ALWAYS (remove any "in-place regime → parent-tree report path" conditional; the orchestrator names the dir, it never searches).
- **F-13 why-not:** one line — do not pin `isolation` in frontmatter (single-value param breaks fix-coder reuse).

**S-RO — 4 RO pack defs ×3 CLIs = 12 files (pack-architect/planner/reviewer/docs-researcher).** Lock-step. (F-2)
- Current RO-emit framing (verbatim, e.g. pack-reviewer.md L48-52): "**RO-emit:** in the isolated regime that report path is under the named `/tmp` handoff dir …; in the in-place regime it is the named parent-tree path." This binary "isolated/in-place regime" is OLD-model for an RO agent.
- REPLACE with rule-1 placement: "You run in the tree the work lives in: the main checkout when the work is on HEAD/committed; the commit's live worktree when the work is still uncommitted there — in which case you cd into that worktree and VERIFY pwd/HEAD at runtime (rule 8). You emit NO patch (RO). ALL your reports go to the named `/tmp` handoff dir the orchestrator supplies." KEEP the `commit-discipline §2` cross-reference (S15 flips that target).
- **REPORT-LOCATION:** report ALWAYS → named /tmp handoff dir (no regime conditional). The `.toml` Codex copies carry the same content in TOML prose — flip all 12 in lock-step.

**S-RT — `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` L88 (NEW; F-B; pack-only).** A pack-self model-encoder documenting the pack-developer roster's RW subagent execution pattern.
- Current text (verbatim, L86-88): "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then **emit a patch + report**." The "emit a patch + report" on return is the OLD up-front-patch model that rule 4 flips.
- REWORD L88 to the rule-4 model: pack-coder may write/edit source files within the caller-scoped file set inside its isolated worktree, then write its report and return; the patch is produced ONLY after an RO reviewer confirms the work clean (the orchestrator re-engages the most-recent RW agent via SendMessage), NOT on return. KEEP the RO-class bullet (L84-86, "Their single permitted file write is the one caller-specified report") unchanged — it is already correct under the new model. KEEP the verbatim "preserve that permission-profile prose" + verb-ban paragraph (L90+) — they are correct and universal.
- This surface lives with the `.agents-plugin/pack-agents/` def bundle → commit **C2**, one coder task, `pack-only`.
- **Project twin (`project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`) = EXPLICIT NO-OP.** Verified CLEAN (no OLD-model hit — `grep -nE "isolated regime|in-place regime|emit[a-z]*[^.]*patch|patch \+ report|opt-in|merge-back|survives.*auto-removal"` returns empty). Record this so a coder does not "fix" it; editing it would be an out-of-scope project-side change in a pack-only commit.

**S8 — `pack-ops/PACK-MEMORY-RATIONALE.md` `## agents-never-commit` (L31-37). RETARGETED per F-5.**
- Edit L34-37: "The agent's output is its report file plus working-tree edits (or, in the isolated regime, a `git diff` patch emitted to the named `/tmp` handoff dir); Pack Chat reads the report, verifies / applies the patch, then commits." → the patch is the POST-review-clean artifact (rule 4), produced when the orchestrator re-engages the most-recent RW agent after review-clean; the report is the on-return deliverable.
- LEAVE the `## pack-chat-minor-edits-only` routing rationale (~L597+) UNTOUCHED (it is the correct routing rationale, NOT the rule-3 contradiction the original design once claimed).
- **Union-grep the WHOLE RATIONALE** for OLD-model timing (the expanded phrase set, §5.1) and reconcile each hit to rule 4/7 (the `bounded-review-fix-cycle` section must be checked too — reword body only if it carries OLD timing; NO slug change).
- Confirm the `agents-never-commit` SLUG name unchanged (manifest + Check 45 are body-agnostic; `agents-never-commit` @ manifest L24).

**S9 — propagation (`PACK-CHAT.md` § propagation + `.spawn-rule-manifest.txt`).** Mechanism, not a model-encoder. The keystone (S1) edits a corpus bullet with NO `[rationale:]` tag → no slug churn → trinity-parity step requires NO AGENTS/GEMINI edit. S8 edits `agents-never-commit` body (manifest-tracked, but body-agnostic). RECOMMEND: keep all slugs; regenerate/verify `.spawn-rule-manifest.txt` consistency in C1.

**S15 — `commit-discipline` SKILL ×3. F-9 decouple regime↔patch-emit.**
- §1 "Detect your regime" (L33-38): the binary is "ISOLATED (`worktree-agent-*` pwd) vs IN-PLACE (the default; no isolation param)". KEEP the pwd/HEAD self-detect MECHANIC (it is rule-8 ground-truth and correct). REFRAME: the class determines the default (RW ⇒ isolated worktree; RO ⇒ the work's tree); in-place is the DEGRADED fallback the agent self-detects, not "the default; no isolation param was passed."
- §2 "Write-target rule" (L57-93): DECOUPLE "regime = which tree you write in" from "do I emit a patch = am I RW". Add the THIRD state the binary model cannot express: an RO agent in a live worktree writes ONLY its report to /tmp and emits NO patch; the patch is the RW-only, POST-review-clean step (rule 4). REPORT-LOCATION: the report goes to the named /tmp handoff dir. Note: this skill carries the `patch + report` variant (2 hits/copy) — the reword must remove the up-front "patch + report" framing (it is in the gate's expanded phrase set, §5.1).
- Lock-step the 3 copies.

**S16 — `implementation-report` SKILL ×3. F-10 rework the reason, not just the timing.**
- Intro L14-17 ("in the isolated regime the change set is captured as the `git diff` patch persisted to the `/tmp` handoff dir (so it survives the worktree's auto-removal on agent return)"): DELETE the "survives auto-removal" rationale. The worktree is HELD through the cycle and removed only after the commit lands (rule 7); the report is the deliverable on return; the patch is the post-review-clean artifact (rule 4).
- §1 (L24-30) + §4 (L53-57) "so the report is self-contained even after the worktree auto-removes": rework the same way (the patch is post-review-clean, the report is the return deliverable). Reword the `on agent return` framing (gate phrase, §5.1). KEEP the regime + `worktree-agent-*` HEAD-reporting mechanic.
- Lock-step the 3 copies.

**S18 — `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` L194. F-12 REQUIRED (not skip).**
- "Spawn sub-agents in background; sub-agents run in-place by default, with opt-in worktree isolation (BD-197)" → flip to the class-keyed default ("RW agents isolated by class; RO agents in the work's tree") + update the citation BD-197 → BD-226.

### APPLICATION A addendum — GRAPH ACCESS (PACK-ONLY; CLAUDE-only per F-1)

> F-1 = USER OPTION A: the graph-path-injection fix lands in **CLAUDE.md ONLY**, plus an explicit Trinity-exempt note. AGENTS.md/GEMINI.md graph-first path-resolution stays AS-IS (correct for their in-place execution; their worktree story is a future pack version). Do NOT expand to all-trinity. C4 does NOT touch AGENTS.md/GEMINI.md or the RATIONALE `## graph-first-context` section.

**G1 — `CLAUDE.md` § "Graph-first context (BD-225)" (derivation L597, L610).** Constraint 2 + F-8 + F-1 note.
- Constraint 2: REPLACE the `$(git rev-parse --show-toplevel)/graphify-out/graph.json` self-derivation with: the orchestrator evaluates the derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` AT RUNTIME in its canonical checkout and INJECTS the resulting literal into the spawn prompt; the agent uses THAT injected path verbatim, NEVER recomputing from its own worktree toplevel (which under isolation resolves to the empty worktree root where gitignored `graphify-out/` is absent). NO machine-specific literal is written on the surface — the surface carries the DERIVATION FORMULA + the injection contract.
- F-8 graceful degradation: the orchestrator injects the literal ONLY when its canonical `graphify-out/graph.json` exists; when absent (fresh clone / graphify not installed / feature off) it injects NO path (or a "no graph" token) and the agent uses grep/Read. The agent runs the G1 existence check against the INJECTED path (never its own toplevel); G2 fallback (query errors/empties ⇒ fall back, never block) unchanged. Keep budgets (2000/1500/1000) + `--backend claude-cli`.
- F-1 note: add an explicit Trinity-exempt sentence — "Worktree path-injection is Claude-only (only Claude runs worktrees); the AGENTS.md/GEMINI.md graph-first path-resolution intentionally stays as-is, correct for their in-place execution; their worktree story is a future pack version." This documents the intentional divergence so a future maintainer does not "restore parity".

**G2 — `pack-ops/PACK-CHAT.md` spawn-prompt construction. F-G: ADD (no existing graph text).** ADD a graph-inject note near the "Name the handoff dir" anchor (~L262): every spawn prompt injects the orchestrator-derived absolute graph literal (Constraint 2), only when graph.json exists (F-8). PACK-CHAT.md carries zero existing graph text, so this is an ADD — the coder does not search for text to replace.

**G3 — `pack-ops/PACK-AGENTS.md` spawn-syntax surface. F-G: ADD (no existing graph text).** ADD a graph-inject note near `## How to invoke pack agents` / the `claude --agent` block (~L46/L68): document the injection requirement (agent uses `--graph <injected>`, never its own toplevel). PACK-AGENTS.md carries zero existing graph text → ADD, not edit.

**G4 — `CLAUDE.md` § "Agent invocation rules" spawn-syntax.** Same injection note (CLAUDE-only).

**Gx — RATIONALE `## graph-first-context` / manifest.** NOT touched by C4 (F-1: CLAUDE-only; the RATIONALE section + AGENTS/GEMINI stay as-is). `graph-first-context` is NOT in the manifest → no manifest update. (Intentional consequence: the RATIONALE `## graph-first-context` keeps the self-derivation wording; acceptable under F-1 because the live-worktree bug is Claude-only and the CLAUDE.md corpus bullet is the operative instruction for Claude agents. Record this in the C4 IMPL-REPORT so a future maintainer understands the divergence is by user decision, not an oversight.)

### APPLICATION B — PROJECT (Claude-only here; restated for the PROJECT audience, NEVER byte-copied)

**Audience normalization for EVERY B-surface (P-missed-7):** "the PM chat" (never "Pack Chat"); "your `coder`/`reviewer`/`architect`/`repo-ops`" (never `pack-*`); "a future pack version" / "tracked separately" (never `BD-217`/`BD-218`/any `BD-NNN`); NO Graphify/graph note at all. The existing project text already does this — preserve it (project-side BD-NNN=0, graphify=0).

**Project-side rule-4 re-engagement (Claude-specific, audience-correct).** Express rule 4's "SendMessage-ing the most-recent RW agent" as: "re-engage the most-recent read-write agent (in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder against the worktree to produce the patch)." Never import the pack's Agent-Teams framing as a universal project guarantee.

**S10 — `project-template/docs/pack/PM-CHAT.md` § "Isolation is for RW only" + "Merge-back" (L470-532).** Heaviest project edit.
- L470-480 "Isolation is for read-write agents only … RO agents … spawned **without** isolation … RW ⇒ isolate; RO ⇒ in-place." → "RW agents (`coder`, `repo-ops`) run in an isolated worktree by class; the first coder of a commit creates it and fix-coders REUSE it (never a new worktree). RO agents run in the tree the work lives in — your main tree when the work is committed, the live worktree when the work is still uncommitted (cd in + verify pwd/HEAD)."
- **F-13 why-not (both RW agents named here):** do NOT pin `isolation:"worktree"` in any RW agent's def frontmatter — the parameter has only the value `"worktree"`, so a pin forces a new worktree on every spawn and a fresh fix-coder could not reuse the first coder's worktree. (This is the chosen single HOME for the both-RW-agents why-not per F-6; S13/S13b carry only a one-line pointer.)
- REWRITE "Merge-back" (L497-520): DELETE the up-front "via a patch the agent writes before it returns" framing. The whole review/fix cycle runs in the worktree; the patch is produced ONLY after the reviewer confirms clean, by re-engaging the most-recent RW agent (project phrasing above); THEN the PM chat applies + commits. Add rule-7 + Constraint 1 (remove the worktree only after the commit lands; a failed commit KEEPS it). Add the rule-9 ASK gate (project phrasing). Add the rule-10 note (the PM chat consumes the parallelization map to schedule parallel worktree waves vs serial commits).
- **Constraint 3 (project merge-back rule):** after the commit lands, the PM chat MOVES every agent report from its `/tmp` handoff dir into the tree and commits it (paired commit right after the work's commit), so nothing is lost to /tmp cleanup or worktree teardown. Destination DERIVED at runtime, not baked: a dedicated `docs/impl-reports/**` subtree (NEW — keeps reports OUT of the `docs/` content the pack installs), then organized by the current phase/grouping (e.g. `docs/impl-reports/<current-phase>/`). State the derivation rule for "the current target dir" (read the active phase from the project's implementation-plan stream), NOT a baked path. NO pack-self ref; project audience only.
- The conflict protocol (L522-532) STAYS, reframed to the post-review-clean step; cross-reference §4's serialized-same-file ordering.

**S11 — `supporting-docs/METHODOLOGY.md` (install-source → client `docs/pack/METHODOLOGY.md`). A1.**
- Keep the worktree/merge-back SUBSTANCE in PM-CHAT.md (S10). METHODOLOGY gets AT MOST a one-line cross-reference if its fix-cycle prose implies a placement. L720 ("the developer may re-run the owning subagent in isolation to verify the fix") is already consistent with the new model → LIKELY NO EDIT. Do NOT duplicate the substance into METHODOLOGY (single-SSOT; drift risk). Record the no-edit-or-one-line decision in the IMPL-REPORT.

**S12 — `project-template/docs/pack/OPTIONAL-FEATURES.md` § "Isolated parallel agents". B1 + F-3 + F-13 (project audience).**
- "What it is" RW narrative + "Read-only agents … need NO isolation" → in-worktree-cycle + RO-to-work's-tree (project phrasing).
- "in-place (non-isolated) regime is the default floor" → in-place is the degraded fallback.
- **F-3 caveats (project copy, ~L250-251):** the auto-removal MECHANISM fact stays; the patch-timing consequence + the "patch handoff ⇒ isolated" regime-detect reword to rule 4/7/Constraint 1 + pwd/HEAD ground-truth.
- **F-13 why-not** (project audience, no `pack-*`).
- KEEP VERBATIM: baseRef/permissions.deny blocks; the "Trinity-exempt note (Claude-only)" + "a future pack version" framing (NO BD-NNN — already correct).

**S13 — project coder def ×3 (`.claude/agents/coder.md` + `.agents-plugin/optiquity-agents/agents/coder.md` + `.codex/agents/coder.toml`).** Lock-step (the 3 copies differ by CLI format; `.toml` L29 carries the OLD Merge-back framing).
- "Merge-back: emit a patch, never commit." (L38-50 / coder.toml L29): "When the calling prompt names a `/tmp` handoff directory (the isolated regime), your sequence is: … emit the change set … (`git diff > <handoff>/changes.patch`) → write your report → return. The PM chat reads the report, runs the review/fix cycle, and applies the patch itself. … When no handoff directory is named (the in-place regime), leave the edits…" → rule 4 (project phrasing): edits + verification + report + return; the patch is produced ONLY after review-clean when the PM chat re-engages you. REPORT-LOCATION: report ALWAYS → the named /tmp handoff dir (remove the in-place conditional). "spawn isolation is load-bearing" (L52-59) keeps (no-safety-net) but flip opt-in → class-default.
- **F-13 why-not** (one line pointer to PM-CHAT.md, project audience).

**S13b — project repo-ops def ×3 (`.claude/agents/repo-ops.md` + `.agents-plugin/optiquity-agents/agents/repo-ops.md` + `.codex/agents/repo-ops.toml`). F-6 coder-twin.**
- *F-6 premise (settled):* repo-ops's "MAY NOT run `git worktree`" (L56-61) is the UNIVERSAL verb-ban (coder.md carries the identical line via Hard rules) — it is NOT an isolation barrier. The HARNESS creates the worktree; the agent never runs `git worktree`. So repo-ops isolates exactly like coder.
- repo-ops has NO "Merge-back" section today. ADD the SAME class-default merge-back paragraph coder.md gets, symmetric with coder: repo-ops (an RW agent) runs in an isolated worktree by class; it does its scripted writes + verification, Writes its report to the named /tmp handoff dir, returns; the patch is produced only after review-clean when the PM chat re-engages it; never stage/commit/apply. Keep the `git worktree`-in-the-verb-ban line VERBATIM (it is correct and universal).
- **F-13 why-not** (one line pointer to PM-CHAT.md).
- *Confirm at impl (settled note):* there is NO other repo-ops-specific reason it needs the canonical tree — if repo-ops legitimately produces only gitignored generated artifacts for a given task, the EMPTY patch is the expected handoff (correct, not a barrier); the work still ran in the isolated worktree.

**S14 — `project-template/docs/pack/prompts/coder.md` + `reviewer.md`.** Targeted.
- `reviewer.md` "read-only review pass": add that the reviewer reads the work IN the live worktree when the work is uncommitted there (cd in + verify pwd/HEAD; rule 3/8). `coder.md` prompt template: verify + align any placement/handoff language to rule 4. (`docs/pack/prompts/repo-ops.md` — verify; align only if it asserts a placement; record in the IMPL-REPORT.)

**S17 — `project-template/skills/implementation/SKILL.md` (single source → 3 client skill dirs at install). F-9 + F-10 (project audience).**
- § "Reporting the change set (regime-aware)" (L34-61): "Isolated (opt-in worktree) … emits the change set as a patch … The patch — not the worktree — is the persisted artifact, so the change set survives even after the isolated worktree is cleaned up. The PM chat applies the patch" → rule 4: the patch is the POST-review-clean artifact (not the on-return artifact). DELETE the "survives … cleaned up" / `persisted artifact` rationale (F-10): the worktree is held through the cycle and removed after the commit lands. DECOUPLE regime↔patch-emit (F-9): an RO agent in a worktree writes only its report, emits no patch. REPORT-LOCATION: report → the named /tmp handoff dir. Project phrasing; NO `pack-*`/BD-NNN/Graphify.

**S-AR — `project-template/agent-run.sh` — FOUR locations (F-C widens the reconciled single-location S-AR). F-4 + measure-then-bound classification.**

The launcher encodes the OLD opt-in/SECONDARY/up-front-patch model at four places. Each is CLASSIFIED explicitly (consistent with the user's F-4 call):

| Location | Current text (verbatim) | KEEP / STRIP | Action |
|---|---|---|---|
| **L173-176** (`--worktree` help) | "(claude only) Run the agent in an isolated git worktree based at the current HEAD. … **SECONDARY/opt-in — probe cwd-scoping once before relying on it** (see the run_in_worktree comment in this file)." | **KEEP** (the `--worktree` FLAG is a launcher-LEVEL opt-in — a human-launcher choice for the separate-terminal launch path, distinct from the agent-PLACEMENT model). Leave the "opt-in" framing of the flag intact; it is correct that the flag is opt-in at the launcher level. | KEEP-as-is (flag-is-opt-in is true). |
| **L275-278** (`run_in_worktree()` comment) | "Either way the agent still never stages or commits — you bring its work back (**the PM-chat merge-back applies the patch the agent leaves**; see docs/pack/PM-CHAT.md … and docs/pack/OPTIONAL-FEATURES.md)." | **STRIP** (the "patch the agent leaves" = the OLD up-front-patch timing). | REWORD to rule 4: "Either way the agent never stages or commits. The PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch — same merge-back model as the in-session spawn path; only the LAUNCH mechanism (separate terminal vs in-session Agent tool) differs, with no special-casing (see docs/pack/PM-CHAT.md 'Merge-back')." Keep the existing PM-CHAT.md + OPTIONAL-FEATURES.md xrefs. |
| **L306-307** (echo'd reminder) | "The agent never commits; bring its work back via the **PM-chat patch merge-back**." | **STRIP** (the "patch merge-back" echo implies the up-front-patch timing). | REWORD the echo to the post-review-clean model: the agent never commits; the PM chat runs the review/fix cycle in the worktree and applies the reviewed-clean patch (consistent with the L275-278 reword). |
| **L606-608** (branch comment) | "**SECONDARY isolated-worktree path (opt-in)**. See run_in_worktree for the cwd-scoping caveat + manual fallback." | **KEEP** (this comment annotates the LAUNCHER branch that fires only when the human passes `--worktree` — the launcher-level opt-in, same class as L173-176). | KEEP-as-is (the launcher branch IS the opt-in launch path). |

- Net: the two **launcher-level** opt-in references (L173-176, L606-608) are KEEP — the `--worktree` flag is genuinely a human-launcher choice, distinct from the placement model. The two **patch-timing** references (L275-278, L306-307) are STRIP — reworded to the post-review-clean model. project-only (C6). The gate's expanded phrase set (§5.1) carries `patch the agent leaves` + `the patch the agent` + `SECONDARY`/`opt-in` so the reviewer can VERIFY the STRIP set was reworded and the KEEP set is intentionally retained (allowlist entry; see §5.1).

**S-RT(proj) — `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` — EXPLICIT NO-OP (F-B).** The project twin of S-RT is verified CLEAN (no OLD-model hit). Recorded so the coder does NOT edit it; touching it would inject a project-side change into a pack-only commit (and there is nothing to fix).

**project-template TRINITY — D1: NO EDIT.** The project trinity carries universal collaboration rules (trinity rule, no-destructive-without-approval, PM-does-not-architect, Project-SSOT-first); none change. The trinity's only worktree mention is `git worktree` in the no-destructive-without-approval verb list — a DIFFERENT rule, not a placement model. Adding a worktree-placement section would duplicate PM-CHAT.md (drift) and force a Claude-only rule into a trinity with no Claude-only-exemption precedent. Recorded as explicit no-op.

### LEAK-RISK GUARDS (P-missed-7 / pack-project-separation) — carried forward

- **SendMessage / Agent-Teams** Claude-specificity: project restatements use "re-engage the most-recent RW agent (in Claude Code, via the Agent-team peer-message path; else re-spawn a fresh coder)" — never the pack's Agent-Teams framing as a universal project mechanism.
- **BD-NNN**: ZERO in any project restatement ("a future pack version" / "tracked separately"). Reviewer grep-gate enforces zero (§5).
- **Graph addendum**: PACK-ONLY; ZERO graph content on any B-surface. Reviewer grep-gate enforces zero (§5).
- **S-RT pack/project asymmetry:** the pack `RUNTIME-SUBAGENT-PATTERN.md` is flipped (S-RT, C2); the project twin is a verified-clean NO-OP. Do not "restore symmetry" by editing the project twin — there is no OLD-model text to flip and it would break the pack-only scope of C2.
- **Standing CI guard:** `project-template/CLAUDE.md` § "Project SSOT-first" `<!-- DENY-LIST-CONTENT -->` block (PACK-AGENTS.md, PACK-CHAT.md, pack-* prompts, `maintenance-docs/`, `pack-ops/`) is already CI-checked. NO new validator (measure-then-bound — the leak-class is already bounded; the per-commit reviewer grep-gates are the completeness check).

---

## 3. FINAL COMMIT PARTITION (E2; every commit single-scope for Check 36)

Each commit is `pack-only` OR `project-only` — never mixed (the surfaces are cleanly side-partitioned). E2 keeps the graph addendum as a STANDALONE commit C4 and ACCEPTS its serialization. The BD-235 entry (already opened, untracked at HEAD) + the Constraint-3 report-preservation docs are committed WITH the batch (see notes).

| C# | Subject sketch | Side / keyword | Surfaces | Depends on |
|---|---|---|---|---|
| **C1** | `feat: v11 — BD-226 pack trinity + class SSOT: flip sub-agent isolation default to class-keyed model (pack-only)` | PACK | S1 (CLAUDE.md keystone), S2 (no-op), S4 (PACK-AGENTS Two-classes), S8 (RATIONALE `## agents-never-commit` retarget), S9 (propagation + manifest verify) | — (keystone) |
| **C2** | `feat: v11 — BD-226 pack orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (pack-only)` | PACK | S3 (PACK-CHAT spawn+merge-back incl. Constraint-3 pack report rule), S7 (pack-coder ×3), S-RO (4 RO defs ×3 = 12), **S-RT (`RUNTIME-SUBAGENT-PATTERN.md`)** | C1 |
| **C3** | `feat: v11 — BD-226 pack skills + feature doc + conceptual-review: regime/handoff decouple + isolated-parallel narrative (pack-only)` | PACK | S6 (OPTIONAL-FEATURES), S15 (commit-discipline ×3), S16 (implementation-report ×3), S18 (CONCEPTUAL-REVIEW L194) | C1 |
| **C4** | `feat: v11 — BD-226 graph-path injection under worktree isolation, CLAUDE-only (pack-only)` | PACK | G1 (CLAUDE graph-first), G2 (PACK-CHAT inject ADD), G3 (PACK-AGENTS note ADD), G4 (CLAUDE agent-invocation) | C1 (shares CLAUDE.md + PACK-AGENTS.md) AND C2 (shares PACK-CHAT.md) — serialize after BOTH |
| **C5** | `feat: v11 — BD-226 project orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (project-only)` | PROJECT | S10 (PM-CHAT incl. Constraint-3 project report rule + F-13 why-not home), S13 (project coder ×3), S13b (project repo-ops ×3) | — (project keystone; file-disjoint from all pack commits) |
| **C6** | `feat: v11 — BD-226 project feature doc + skill + prompts + agent-run launcher (project-only)` | PROJECT | S12 (OPTIONAL-FEATURES), S17 (implementation skill), S14 (prompts), S-AR (agent-run.sh, 4 locations), S11 (METHODOLOGY one-line xref if any) | C5 |

**C2 gains S-RT (`.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md`) and STAYS single-scope `pack-only`.** S-RT is a pack-only file in `.agents-plugin/pack-agents/` — it sits naturally with the C2 def bundle (it documents the same pack-developer roster). Its project twin is a NO-OP, so C2 touches no `project-template/` path; the `pack-only` keyword + Check 36 hold. One coder task: rule-4 reword of L88.

**Not commits:** S2 (AGENTS/GEMINI no-op), S5 (out-of-repo memory upkeep), S-RT(proj) (verified-clean project twin no-op).

**E2 serialization (settled):** C4 is standalone (NOT folded into C1/C2). It shares CLAUDE.md + PACK-AGENTS.md with C1 and PACK-CHAT.md with C2 → it MUST serialize after both (same-file-serialize rule, §4). E2 accepts this.

**Scope-keyword discipline (commit_subject_keyword_token_trap):** C1-C4 carry `pack-only` and DENY `project-template/`+`supporting-docs/`. C5-C6 carry `project-only` and DENY pack-only paths. S11 (`supporting-docs/METHODOLOGY.md`) is project install-source → goes in C6 (`project-only`), NEVER a pack-only commit. The C2 subject must NOT name any `project-template/` path (S-RT is `.agents-plugin/pack-agents/…`, which is pack-side — safe). The C6 subject naming `agent-run.sh` is project-side — safe. Verify each commit's `git diff --name-only` against its keyword before finalizing.

**Constraint-3 report-preservation docs + BD-235 entry (bookkeeping commits, ride WITH the batch — SEPARATE from C1-C6 substance):**
- **BK-1 (`pack-only`, Pack-Chat-direct new-entry author):** `backlog/BD-235.md` (the out-of-scope project-skill investigation entry, currently untracked at HEAD) + the regenerated `backlog/_toc.md` ride in a SEPARATE bookkeeping commit — NOT inside any BD-226 substance commit (keeps C1-C6 single-purpose + Check-36-clean). `backlog/_toc.md` is currently modified + `backlog/BD-235.md` untracked at HEAD `a84094a` — both OUT of BD-226 scope.
- **BK-2 (`pack-only`, paired report commit per Constraint 3):** the agent reports for THIS BD-226 batch (architect/planner/coder/reviewer outputs) moved by the orchestrator from `/tmp` into `maintenance-docs/v11-implementation/` (derived from README v11) — the audit record, not BD-226 substance.

---

## 4. PARALLELIZATION + DEPENDENCY MAP (rule 10 — its OWN dedicated section)

> Per rule 10 this section lives on its own and does NOT bias §2/§3 — it DESCRIBES the schedule the orchestrator executes (E2; it does NOT propose folding commits to dodge serialization). Restated for both audiences at the end.
>
> **THE MAIN PLAN IS SERIALLY EXECUTABLE.** The dependency edges below are the ONLY mandatory ordering; the parallel waves are an OPTIONAL accelerator. If parallelism is unavailable — a CLI without worktree isolation (Codex/Antigravity, tracked for a future pack version per BD-217, out of scope here) or operator choice — the SAME plan runs serially by following the dependency order (a valid serial order is given in §4.6). Parallelism is NEVER a precondition for completing any task. (Rule 10 + the user's directive.)

### 4.1 Dependency graph (commits from §3)

```
C1 (pack keystone) ──┬──> C2 (pack orchestrator + defs + S-RT) ──┐
                     │                                            ├──> C4 (graph inject, CLAUDE-only)
                     ├──> C3 (pack skills + OF + concept) ────────┘ (C4 needs C1 AND C2)
                     │
C5 (project keystone) ──> C6 (project OF + skill + prompts + launcher)
```

- **C1** — no dependency (keystone; establishes the flipped default + class SSOT all others restate).
- **C2** — depends on **C1** (PACK-CHAT + defs + S-RT cite the flipped class SSOT). File-disjoint from C3. (S-RT's addition does NOT change C2's dependency or wave membership — it is one more pack-only file in C2's set.)
- **C3** — depends on **C1** (skills/feature-doc must match the flipped default). File-disjoint from C2 and C4.
- **C4** — depends on **C1** (shares `CLAUDE.md` [S1/G1/G4] + `PACK-AGENTS.md` [S4/G3]) AND **C2** (shares `pack-ops/PACK-CHAT.md` [S3/G2]). Standalone (E2). Serialize after BOTH.
- **C5** — NO dependency on any pack commit (project surface partition is fully file-disjoint — no project-template file references a pack-ops file; the deny-list enforces it).
- **C6** — depends on **C5** (project docs/skill/prompts/launcher reference PM-CHAT's contract).

### 4.2 Binding constraint (the rule-10 invariant): same file ⇒ serialize

**Two commits that touch the SAME FILE MUST serialize (or merge) — never concurrent worktrees**, to avoid patch-apply collision. Shared-file set under E2:
- `CLAUDE.md`: C1 (keystone S1) + C4 (graph G1/G4) → C4 after C1.
- `pack-ops/PACK-AGENTS.md`: C1 (S4) + C4 (G3) → C4 after C1.
- `pack-ops/PACK-CHAT.md`: C2 (S3) + C4 (G2) → C4 after C2.
So C4 serializes after C1 AND C2 (E2 accepts exactly this). S-RT (`RUNTIME-SUBAGENT-PATTERN.md`) is touched ONLY by C2 → introduces no new shared-file edge.

All other commit pairs are file-disjoint: C2∥C3 (PACK-CHAT+defs+S-RT vs skills+OF+concept); C1∥C5 (pack vs project partition); C3∥C6; C3∥{C2→C4}. The project chain (C5→C6) is fully file-disjoint from every pack commit.

### 4.3 Wave schedule (E2 — the binding, executable schedule)

- **Wave 0 (concurrent, two worktrees):** { **C1** (pack keystone) ∥ **C5** (project keystone) }. File-disjoint across the pack/project partition.
- **Wave 1 (after their keystones land):** { **C3** (pack skills+OF+conceptual-review) ∥ **C6** (project docs+skill+prompts+launcher, after C5) } run concurrently with the **C2 → C4** serial chain.
  - **C2** (after C1; touches PACK-CHAT.md + pack-coder ×3 + RO defs ×12 + S-RT) → **C4** (after C1 AND C2; touches CLAUDE.md + PACK-AGENTS.md + PACK-CHAT.md graph hunks).
  - **C3** is freely parallel to the C2→C4 chain (file-disjoint: skills + OPTIONAL-FEATURES + CONCEPTUAL-REVIEW).
- **Max concurrency: 3 worktrees** (the C2→C4 chain; C3; the C5→C6 project chain — C5 in Wave 0). S-RT does not change this — it is inside C2's existing worktree.

### 4.4 Per-wave worktree mechanics (F-11 + Constraint 1)

For EACH concurrent commit in a wave:
1. **Own worktree.** Each concurrent commit = its OWN isolated worktree (rule 1). The first coder of the commit creates it; fix-coders REUSE it.
2. **baseRef:head, shared base.** Every concurrently-created worktree bases at local HEAD (`worktree.baseRef:"head"`, rule 8); concurrent worktrees in a wave all branch from the SAME pre-wave HEAD. A later wave's worktrees are created only AFTER the prior wave's commits land (so Wave 1's worktrees base on Wave 0's landed keystone — the orchestrator does NOT create a Wave-1 worktree before Wave-0's keystone lands; the C2→C4, C5→C6 edges encode this).
3. **RO reviewer/fix-coder rule-fixed.** The commit's own reviewer/fix-coder is RULE-FIXED to that commit's worktree (rule 3/8/9a) — cd in + verify pwd/HEAD; NO rule-9 ASK. Any NON-cycle agent spawned during a live wave (an architect, a cross-cutting fix, a new task) triggers the rule-9 ASK gate (placement + disposition).
4. **Teardown gate (Constraint 1).** Remove a commit's worktree ONLY after that commit is CONFIRMED landed (commit exit 0). A FAILED/aborted commit ⇒ KEEP the worktree as the recovery fallback; never tear down on a failed/attempted commit; never rely on auto-removal.
5. **Conflict protocol at the post-review-clean step.** The apply-time conflict protocol (PACK-CHAT.md / PM-CHAT.md) applies at the POST-review-clean patch step (rule 4), not at an up-front-patch step. For serialized same-file commits (C4 after C1/C2; C6 after C5) the conflict risk is eliminated by ORDERING, not 3-way merge. Concurrent commits in a wave are file-disjoint by construction, so no in-wave conflict arises.

### 4.5 Within-commit task ordering (where meaningful)
- **C2:** T(S3) edits PACK-CHAT.md; T(S7) pack-coder ×3; T(S-RO) RO defs ×12; T(S-RT) `RUNTIME-SUBAGENT-PATTERN.md` — all file-disjoint from each other → independent within the commit (any order; same worktree).
- **C4:** the two CLAUDE.md hunks (G1, G4) SERIALIZE within one coder task; G2 (PACK-CHAT.md) + G3 (PACK-AGENTS.md) are file-disjoint and may follow in the same worktree.
- **C5:** S10 (PM-CHAT.md) edits one file (serialize within one task); S13 ×3 and S13b ×3 are file-disjoint from PM-CHAT.md and from each other (same commit/worktree).

### 4.6 Serial fallback order (parallelism unavailable)
A valid serial order respecting the edges {C1<C2, C1<C3, C1<C4, C2<C4, C5<C6}: **C1 → C5 → C2 → C3 → C6 → C4**. (C4 last is sufficient — it depends on C1 AND C2, both earlier. C6 after C5. C3 after C1. C5 has no pack dependency.) The bookkeeping commits (BK-1, BK-2) may land at the batch boundary in either regime.

### 4.7 Rule-10 ENCODING for FUTURE efforts (restated both audiences)
The codified text MUST state that for ANY multi-commit effort the architect + planner produce this parallel-vs-dependent map in its OWN section, and the orchestrator schedules parallel worktree waves vs serial commits from it (same-file ⇒ serialize; baseRef:head; teardown gated on commit-landed; rule-9 ASK for non-cycle spawns).
- **PACK (S1 / S3):** "Pack Chat consumes the map to schedule parallel worktree waves vs serial commits."
- **PROJECT (S10):** "the PM chat consumes the map to schedule parallel worktree waves vs serial commits." (Project audience; NO `pack-*`/BD-NNN.)

---

## 5. COMPLETENESS GATES (measure-then-bound; baselines at HEAD a84094a)

### 5.1 The ONE union OLD-model grep (the flip-completeness gate) — F-A whole-tree-minus-exclusions form

**F-A correction (BLOCKER): the gate scope is NOT a hand-listed directory array — it is a whole-tree census with exclusions.** A hand-listed array silently omitted `.agents-plugin/` and blinded the gate to 11 OLD-model hits in 5 def copies + the S-RT surface. The churn-proof form names NO directory to include and therefore CANNOT omit one:

**(A) Whole-tree-minus-exclusions (the gate — RECOMMENDED, RUN THIS):**
```
git ls-files -z | xargs -0 grep -IlE "<union phrases>" \
  | grep -vE '^maintenance-docs/'   # implementation history/archive (KEEP — describes OLD model AS history)
  | grep -vE '^backlog/'            # BD entries = history/forward-look (KEEP — BD-197 Resolved, BD-217/218 deferred)
  | grep -vE '^test-fixtures/'      # regenerated install snapshots (KEEP — never hand-asserted)
  # then assert every remaining hit is on the KEEP allowlist (§5.1 allowlist below)
```
This form cannot omit a directory because it never names one.

**(B) Side-array convenience form (if a per-side split is wanted, the pack array MUST include `.agents-plugin`):**
- **PACK array (corrected — `.agents-plugin` ADDED):** `CLAUDE.md AGENTS.md GEMINI.md pack-ops .claude/agents .claude/skills .codex .agents .agents-plugin`
- **PROJECT array (unchanged, already complete):** `project-template supporting-docs`

**Empty-residual proof (the directory-completeness guarantee — re-measured this pass; EB-FINAL-3).** The union of ALL OLD-model phrases over `git ls-files` minus the three exclusions yields exactly 36 live files. Of those, the set OUTSIDE the two corrected side-arrays is exactly the two `scripts/` tracker false-positives (`scripts/lib/tracker-edit.sh`, `scripts/pack-tracker.sh` — "patch JSON", unrelated to agent patches → KEEP). EVERY model-bearing STRIP surface — including `project-template/skills/implementation/SKILL.md`, `pack-ops/PACK-MEMORY-RATIONALE.md`, the 5 `.agents-plugin` def copies, AND `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (catchable ONLY because `.agents-plugin` is now in scope / the whole-tree form is used) — falls inside one side-array. That empty-residual (zero un-arrayed model surface; only tracker false-positives remain outside) is the guarantee no directory is omitted. This whole-tree form is what ends the recurring "missed surface" churn.

**Expanded union phrase set (census §5.3 — the EDIT list does NOT grow; only the gate's detection does).** Every variant below is within an already-enumerated edit surface (or the F-B add S-RT), so it gets flipped regardless; adding the phrase lets the gate VERIFY it.
- **Original (keep):** `in-place by default`, `isolation is opt-in`, `isolated regime`, `in-place regime`, `opt-in worktree`, `emit[a-z]*[^.]*patch`, `patch the agent leaves`, `default floor`, `RW ⇒ isolate`, `default is in-place`, `survives.*auto-removal`.
- **ADD (discovered):** `patch \+ report` (commit-discipline ×3 + PACK-CHAT + S-RT/RUNTIME-SUBAGENT), `opt-in accelerator` (PACK-CHAT), `spawn ISOLATED` / `spawn IN-PLACE` / `when enabled` (PACK-CHAT spawn-decision), `may auto-remove` / `worktree may auto` (PACK-CHAT), `on agent return` (implementation-report ×3), `the patch the agent` (agent-run.sh), `persisted artifact` (project skills/implementation), `before it returns` / `writes before` (PM-CHAT), plus `SECONDARY` / `opt-in` for the agent-run.sh F-C judgment (these last two are partly KEEP per S-AR — see allowlist below).

**Gate semantics:** the gate is **"every REMAINING hit is on the KEEP allowlist"**, and per F-D the EXPECTED post-flip remainder for the listed model-phrases is **0** (not "some allowlist remainders"). Coder PREFLIGHT asserts it; reviewer re-asserts (rename-plans-measure-then-bound; no hand-enumerated anchor list).

**KEEP allowlist (F-D — tightened; sized exactly to the census §4 KEEP classes; expected remainder for the model-phrases = 0):**
1. **History/archive** — `maintenance-docs/**`, `backlog/BD-*.md` (BD-197 Resolved; BD-217/218 deferred forward-look), `changelog/**` — describe the OLD model AS history; EXCLUDED by the gate's `-vE` filters, never a flip target.
2. **Regenerated fixtures** — `test-fixtures/**` (install snapshots, regenerated push-time by `manifest-sync.sh` + Check 62) — EXCLUDED by the `-vE` filter; never hand-edited.
3. **Script false-positives** — `scripts/lib/tracker-edit.sh` + `scripts/pack-tracker.sh` ("patch JSON required" / "empty patch" — tracker verb, NOT an agent patch) + `scripts/compare-agent-trinity.py` docstring ("before returning") — unrelated to the worktree model; these are the ONLY live union hits outside the two side-arrays.
4. **Mechanism facts / verb-ban (NOT a patch-timing claim) — the ONLY in-edit-surface allowlist entries:**
   - The `worktree-agent-*` pwd/HEAD **self-detect mechanic** (commit-discipline §1, implementation-report §1) — keys on rule-8 ground-truth; uses standalone `ISOLATED`/`IN-PLACE` tokens, NOT `isolated regime`/`in-place regime` → **MOOT for the union grep (never coincides with a union phrase)**; the gate emits 0 on it. KEEP the mechanic.
   - The destructive-verb-ban `git worktree` occurrences (every agent def + pack/project trinity verb list) — the UNIVERSAL verb-ban; agents never RUN `git worktree`; the harness creates worktrees → **MOOT for the union grep (never coincides with a union phrase)**. KEEP verbatim.
   - The reworded **auto-removal MECHANISM sentence** in OPTIONAL-FEATURES (pack + project) AFTER F-3 — the FACT stays; the OLD consequence ("the patch survives auto-removal … BEFORE return") is STRIP → the single `survives.*auto-removal` hit is reworded AWAY (post-flip 0). RESERVE this allowlist slot ONLY for an explicitly-reworded residual mechanism sentence that no longer carries the OLD patch-timing claim.
   - The **agent-run.sh launcher-level `--worktree` opt-in** (L173-176 help, L606-608 branch comment) — KEEP per S-AR (the flag is a human-launcher choice, not the placement model). The gate's `SECONDARY`/`opt-in` phrases WILL match these two lines; they are the intentional allowlist remainder for agent-run.sh. The reviewer confirms these two are the launcher-flag references (KEEP), and that L275-278 + L306-307 (patch-timing) were STRIPPED.

**F-D conclusion:** apart from (a) the reworded mechanism sentence and (b) the agent-run.sh launcher-flag lines, the post-flip union remainder for the model-phrases is **0**. Items "self-detect mechanic" and "`git worktree` verb-ban" are MOOT (they never produce a union-phrase hit), so they are NOT allowlist remainders the gate must admit — a tighter, measure-then-bound gate. Any non-allowlisted residual = a missed copy (STRIP) and FAILS the gate.

**Baselines (re-measured this pass, HEAD a84094a — EB-FINAL-3):**
- PACK union (with `.agents-plugin` in scope): `isolated regime`=**31**, `in-place regime`=**22**, `emit[a-z]*[^.]*patch`=**21** (the `.agents-plugin` 5 def copies contribute isolated=6 / in-place=5 / emit=5 — exactly the deltas from the reconciled design's `.agents-plugin`-excluded 25/17/16). Also `in-place by default`=2, `isolation is opt-in`=1, `opt-in worktree`=1, `default floor`=1, `default is in-place`=1, `survives.*auto-removal`=1, `patch the agent leaves`=0, `RW ⇒ isolate`=0.
- PROJECT union: `isolated regime`=3, `in-place regime`=3, `opt-in worktree`=1, `patch the agent leaves`=1, `default floor`=1, `RW ⇒ isolate`=1, `survives.*auto-removal`=1, `emit[a-z]*[^.]*patch`=6.
The large `isolated/in-place regime` counts are dominated by S-RO (12) + skills ×3 + coder ×3 + the 5 `.agents-plugin` copies — exactly the surfaces §2 flips. Post-flip, the model-phrase remainder = 0; only the allowlist mechanism-sentence + agent-run.sh launcher-flag lines may persist.

### 5.2 Project-side leak gates (sized to empty contamination set)
- `grep -rn "BD-[0-9]"` over the edited project surfaces (S10, S12, S13 ×3, S13b ×3, S14, S17, S-AR) → **must be 0**. Baseline measured = 0. Gate correctly sized to empty.
- `grep -rn "graphify\|graph.json\|--graph"` over `project-template supporting-docs` → **must be 0**. Baseline measured = 0. The graph addendum adds ZERO project content.
- S-RT(proj) twin: confirm it stays CLEAN (no edit; verified-clean NO-OP).

### 5.3 Constraint-2 no-hardcoded-path gate (C4)
`grep -rnE "/Users/|/home/|/private/" <C4 diff>` filtered to graph/toplevel context → **must be 0** machine-specific literal paths. Baseline in the C4 surfaces today = 0. The C4 diff carries the DERIVATION FORMULA `$(git rev-parse --show-toplevel)/graphify-out/graph.json` + the orchestrator-injection narrative, never a baked literal.

### 5.4 Constraint-3 destination-derivation gate
Pack: the report-preservation rule (S3) MUST state the deterministic derivation of the active-version dir (from the README version table → `maintenance-docs/v<major>-implementation/`), NOT a baked `maintenance-docs/v11-implementation/` literal. Project: the rule (S10) MUST state the derivation of the current-phase dir under `docs/impl-reports/`, NOT a baked phase path. Reviewer reads each rule for a derivation formula (analogous to Constraint 2), not a literal. `docs/impl-reports/` is ABSENT today → a NEW project subtree the rule introduces by derivation.

### 5.5 Per-commit vs batch-end grep scope (F-E)
The union grep has TWO distinct applications — do not conflate them:
- **PER-COMMIT grep = THAT commit's own file set.** When a commit's coder runs PREFLIGHT and its reviewer re-asserts, the union grep is scoped to ONLY the files THAT commit edits — expected OLD-model residual in those files = 0 (the commit flipped them). A whole-side grep mid-batch is unsatisfiable: after C1 lands, C2/C3 files still carry OLD text, so "every remaining hit on the allowlist over the whole side" is FALSE per-commit. Scope the per-commit grep to the commit's own file set.
- **WHOLE-SIDE grep = ONCE at BATCH END.** The whole-tree-minus-exclusions union grep (§5.1 form A) runs once after ALL pack commits (C1-C4) land for the pack side, and once after ALL project commits (C5-C6) land for the project side — asserting every remaining hit is on the KEEP allowlist (post-flip model-phrase remainder = 0).

### 5.6 Audience-leak grep scope (F-F)
The C5 reviewer's audience-leak grep (no `pack-*` / `Pack Chat` / `pack-ops/` in project restatements) MUST be scoped to the S10 EDIT region, NOT the whole file. `project-template/docs/pack/PM-CHAT.md` carries 2 pre-existing "Pack Chat" refs (~L342/L344) OUTSIDE the S10 edit region (L470-532) — they are pre-existing state, out of BD-226 scope; a whole-file grep would false-positive on them. (BD-[0-9]=0 and graphify=0 are whole-file gates and stay so — they have no pre-existing hits.)

---

## 6. PROPAGATION + CI NOTES

- **Slugs UNCHANGED.** `agents-never-commit` (S8 body edit), `graph-first-context` (untouched by C4 per F-1), `bounded-review-fix-cycle` (verify body has no OLD timing; reword if present — no slug change). No new slug minted. The keystone bullet (S1) carries no `[rationale:]` tag → outside the bijection.
- **Check 18 (`check_trinity_h2_parity`) + Check 45 (`check_pack_memory_rationale_bijection`) stay GREEN** — Check 18 verifies H2 names/order only; Check 45 verifies SLUG set-equality only (both body-agnostic). A body edit to `## agents-never-commit` and the CLAUDE-only keystone keeps both green AS LONG AS slugs + H2 names/order are unchanged.
- **C1 reviewer HAND-VERIFY (the silent-miss guard).** Because Check 18/45 do NOT catch body divergence within `## Pack memory`, the C1 reviewer MUST hand-verify trinity body parity is NOT broken by the keystone edit. Per F-1, graph-first stays CLAUDE-only by the trinity rule's own "provably tool-specific" exemption — the reviewer confirms this is the INTENTIONAL divergence (CLAUDE.md graph-first bullet diverges from AGENTS/GEMINI BY USER DECISION, documented in the G1 Trinity-exempt note), NOT an accidental parity break. State this explicitly in the C1 + C4 IMPL-REPORTs.
- **`.spawn-rule-manifest.txt`:** regenerate/verify consistency in C1; no slug add/remove → no structural manifest change. `graph-first-context` is NOT manifest-tracked → C4 triggers no manifest update.
- **Check 36 (commit-scope keyword):** each commit's diff matches its `pack-only`/`project-only` keyword — the §3 partition guarantees this; verify per commit. C2's S-RT file (`.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md`) is pack-side → C2 stays `pack-only` clean.
- **No NEW validator** (measure-then-bound). The leak-classes (pack-ref/BD-NNN/graphify in project) are already bounded by the `project-template/CLAUDE.md` deny-list + its CI check; the per-commit reviewer grep-gates (§5) are the completeness check. Adding a BD-226-specific guard would widen surface with no new coverage.
- **No test/validator asserts the OLD-default text** → no test edit required for the flip; the install-snapshot fixtures are REGENERATED, not hand-asserted (push-time `manifest-sync.sh` + Check 62 handle any fixture-input drift — push-time only, not per-commit).
- **Manifest regen** only if a slug changes (it does not). Skill edits (S15/S16/S17) touch BODY only, not frontmatter/count → skill-count/frontmatter checks unaffected.

---

## 7. VERIFICATION STRATEGY

- **Per-commit (every C1-C6):** `scripts/validate-pack.py` Check 43 + the FULL CI battery (validate-pack all checks + DEEP + sharded suites + `build.sh --verify`, NOT validate-pack alone); the union OLD-model grep (§5.1) scoped to **THAT commit's own file set** (F-E; expected model-phrase residual = 0); coder PREFLIGHT line before the IMPL-REPORT.
- **C1:** trinity body-parity hand-verify (§6); manifest consistency; Check 18/45 green.
- **C2:** lock-step verification — pack-coder ×3 + RO defs ×12 + S-RT all moved (no drift across `.claude`/`.agents-plugin`/`.codex`). `diff`-the-intent across copies (format differs; content-intent must match). Confirm S-RT L88 reworded and the project twin UNTOUCHED. Confirm C2 diff is `pack-only` (no `project-template/` path).
- **C3:** lock-step — commit-discipline ×3 + implementation-report ×3 moved (no drift across `.claude`/`.codex`/`.agents`).
- **C4:** Constraint-2 no-hardcoded-path gate (§5.3) = 0; F-8 degradation wording present (inject only when graph.json exists; existence-check on injected path); F-1 Trinity-exempt note present in G1; CLAUDE-only (AGENTS/GEMINI graph-first UNTOUCHED — grep-confirm zero C4 hits in AGENTS.md/GEMINI.md; the RATIONALE `## graph-first-context` section UNTOUCHED). G2/G3 are ADDs (no existing graph text to replace).
- **C5:** lock-step — project coder ×3 + repo-ops ×3 moved; project-side leak gates (§5.2) = 0 (BD-NNN, graphify); audience-leak grep scoped to the S10 EDIT region (F-F); S-AR is C6, not here.
- **C6:** S-AR 4-location classification verified (L275-278 + L306-307 STRIPPED to post-review-clean; L173-176 + L606-608 launcher-flag KEPT); project-side leak gates = 0; P-missed-7 audience-correctness; `docs/impl-reports/` derivation (not baked).
- **Batch end:** one end-of-batch reviewer pass over the full BD-226 batch after all per-commit cycles; the **whole-side union grep (§5.1 form A) run ONCE per side** (F-E) — all remaining hits on the KEEP allowlist (model-phrase remainder = 0); Constraint-3 reports moved into the tree + committed (BK-2).

---

## 8. EMPIRICAL-EVIDENCE BLOCKS (re-measured THIS pass for everything the amendment CHANGED)

All measured at **HEAD `a84094aa7fa2bda0213f66fb1588fdd162d92247`**, **2026-06-19**, IN-PLACE in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (pwd + `git rev-parse --show-toplevel` identical; branch `v11-dev`). Unchanged facts cite the census/reconciled-design EBs by reference; everything the amendment CHANGES is re-confirmed below.

**EB-FINAL-1 — S-RT (`RUNTIME-SUBAGENT-PATTERN.md`) carries the OLD model at L88; the project twin is CLEAN. [F-B]**
- Command: `git ls-files | grep -i RUNTIME-SUBAGENT-PATTERN`; `sed -n '80,95p' .agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md`; `grep -nE "isolated regime|in-place regime|emit[a-z]*[^.]*patch|patch \+ report|opt-in|merge-back|survives.*auto-removal" project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`.
- Output: two twins exist (`.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` + `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`). Pack L86-88: "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then **emit a patch + report**." Project twin grep → EMPTY (CLEAN). The pack RO-class bullet (L84-86) + the verb-ban paragraph (L90+) are already correct under the new model.
- Interpretation: S-RT is a real, pack-only omitted edit surface (L88 = OLD up-front-patch model); the project twin needs NO edit (explicit NO-OP).
- Conclusion: **SUPPORTED** (F-B real, pack-only; project twin no-op).

**EB-FINAL-2 — agent-run.sh has FOUR OLD-framing locations; two are launcher-level opt-in (KEEP), two are patch-timing (STRIP). [F-C]**
- Command: `sed -n '170,180p'`, `sed -n '273,280p'`, `sed -n '304,309p'`, `sed -n '604,610p' project-template/agent-run.sh`.
- Output (verbatim):
  - L173-176 (`--worktree` help): "(claude only) Run the agent in an isolated git worktree based at the current HEAD. … **SECONDARY/opt-in — probe cwd-scoping once before relying on it** (see the run_in_worktree comment in this file)."
  - L275-278 (run_in_worktree comment): "Either way the agent still never stages or commits — you bring its work back (**the PM-chat merge-back applies the patch the agent leaves**; see docs/pack/PM-CHAT.md … and docs/pack/OPTIONAL-FEATURES.md)."
  - L306-307 (echo): "The agent never commits; bring its work back via the **PM-chat patch merge-back**."
  - L606-608 (branch comment): "**SECONDARY isolated-worktree path (opt-in)**. See run_in_worktree for the cwd-scoping caveat + manual fallback."
- Interpretation: L173-176 + L606-608 annotate the LAUNCHER's `--worktree` flag (a human-launcher choice; KEEP — launcher-level opt-in, distinct from the placement model). L275-278 + L306-307 are the OLD up-front-patch timing (STRIP → post-review-clean reword). This matches the user's F-4 call (the flag-is-opt-in stays; the patch-timing flips).
- Conclusion: **SUPPORTED** (F-C real; classification: 2 KEEP / 2 STRIP).

**EB-FINAL-3 — corrected pack baselines (with `.agents-plugin`) + empty-residual proof. [F-A, F-D]**
- Command: pack array `(CLAUDE.md AGENTS.md GEMINI.md pack-ops .claude/agents .claude/skills .codex .agents .agents-plugin)` → `grep -rIn -- "isolated regime"` / `"in-place regime"` / `grep -rInE "emit[a-z]*[^.]*patch"` (excluding tracker/compare-agent-trinity false-pos); then `git ls-files -z | xargs -0 grep -IlE "<union+expanded>" | grep -vE '^maintenance-docs/|^backlog/|^test-fixtures/'` and inspect the residual outside the two side-arrays.
- Output: `isolated regime`=**31**, `in-place regime`=**22**, `emit[a-z]*[^.]*patch`=**21**. `.agents` and `.agents-plugin` are DIFFERENT dirs (`.agents` = skills only; `.agents-plugin/pack-agents/agents/` = the 5 pack `.md` def copies). Whole-tree union (minus the 3 exclusions) = 36 live files. The full list is exactly: the 5 `.agents-plugin` def copies + `.agents-plugin/.../RUNTIME-SUBAGENT-PATTERN.md`; the 5 `.claude/agents` defs; the 5 `.codex/agents` defs; `.claude`/`.codex`/`.agents` commit-discipline + implementation-report (6 skill files); `CLAUDE.md`; `pack-ops/{CONCEPTUAL-REVIEW-METHODOLOGY,OPTIONAL-FEATURES,PACK-AGENTS,PACK-CHAT,PACK-MEMORY-RATIONALE}.md`; project coder ×3; `project-template/agent-run.sh`; `project-template/docs/pack/{OPTIONAL-FEATURES,PM-CHAT}.md`; `project-template/skills/implementation/SKILL.md`; and `scripts/lib/tracker-edit.sh` + `scripts/pack-tracker.sh`. The residual OUTSIDE both corrected side-arrays = ONLY the two `scripts/` tracker false-positives (KEEP).
- Interpretation: F-A confirmed — `.agents-plugin` carries 6 isolated / 5 in-place / 5 emit hits the old hand-listed array could not see; the corrected baselines are 31/22/21. The empty-residual (no model surface outside the two arrays; only tracker false-pos) is the directory-completeness guarantee. F-D: the only in-edit-surface allowlist remainders are the reworded mechanism sentence + the agent-run.sh launcher-flag lines; the model-phrases drop to 0.
- Conclusion: **SUPPORTED** (F-A baselines 31/22/21; empty-residual proven; F-D allowlist tightened to 0 model-phrase remainder).

**EB-FINAL-4 (carried, re-confirmed) — `.agents-plugin` def copies + `.codex` `.toml` copies carry the OLD framing (lock-step ×3 holds).**
- Command (this pass): `ls .agents-plugin/pack-agents/agents/`; the §5.1 whole-tree census listing.
- Output: `.agents-plugin/pack-agents/agents/` = {pack-architect.md, pack-coder.md, pack-docs-researcher.md, pack-planner.md, pack-reviewer.md} — all 5 appear in the union census; `.codex/agents/pack-*.toml` (5) also appear. Pack defs = 5 agents × 3 CLI surfaces = 15 canonical homes (S7 pack-coder ×3; S-RO 4 RO ×3 = 12).
- Interpretation: the ×3 (not ×2) lock-step from the reconciled design holds; `.agents-plugin` is now also covered by the gate.
- Conclusion: **SUPPORTED** (carried from reconciled EB-3 / census EB-3; re-confirmed this pass).

**EB-FINAL-5 (cited, unchanged) — facts NOT changed by this amendment.** The following carry UNCHANGED from the reconciled design's §8 (re-verified there at the same HEAD a84094a) and the census §8; this amendment does not alter them and does not re-measure them: D1 project-trinity verb-ban-only (reconciled EB-1); keystone CLAUDE-only (reconciled EB-2); repo-ops no merge-back / verb-ban ≠ barrier (reconciled EB-4); gitignored `graphify-out/` + project graph-leak=0 (reconciled EB-5); `isolation` single-value (reconciled EB-6); keystone no rationale-tag / graph-first full-trinity-tagged (reconciled EB-7); Constraint-3 pack dir derivation + Constraint-2 baseline=0 (reconciled EB-8); project defs ×3 + project leak baselines=0 (reconciled EB-9); Check 45/18 body-agnostic + graph-first not manifest-tracked (reconciled EB-10); no test/validator asserts OLD text (reconciled EB-11 / census EB-7); skills carry OLD model (reconciled EB-12); `docs/impl-reports/` ABSENT = NEW subtree (plan EB-P13).

---

## R. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran read-only git verbs only this pass: `git rev-parse HEAD` → `a84094aa7fa2bda0213f66fb1588fdd162d92247`, `git branch --show-current` → `v11-dev`, `git rev-parse --show-toplevel`, `git ls-files`; plus `grep`/`sed -n`(read)/`ls`/`wc`/Read. No add/commit/apply/worktree/branch/reset/restore/checkout/mv/rm/stash. Sole write = this design at `/tmp/handoff-bd226-final/DESIGN-BD-226-FINAL.md` (caller-specified, under `/tmp`, outside the repo). No repo state changed. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op attempted; the untracked `backlog/BD-235.md` + modified `backlog/_toc.md` were NOT touched (carried as BK-1 out-of-scope from the inputs, not acted on). | COMPLIANT |
| **deferral-is-scope-creep** | Folded ALL corrections now (F-A..F-G + expanded union + S-RT + S-AR 4-location) into the FINAL design; deferred nothing in-scope. BD-235/BD-217/BD-218 are pre-authorized out of scope (reference only). | COMPLIANT |
| **no-deferral-without-user-direction** | Invented no deferrals; the only out-of-scope items (BD-235/BD-217/BD-218) are the BD's own pre-authorized deferrals. | COMPLIANT |
| **graph-first-context** | This is exact-string completeness work — used grep/Read (the rule's own fall-through for exact-string + SSOT + freshly-changed-file cases). The census already noted the graph token-collides on prose for this work; no relationship/orientation question arose that needed a graph query. | COMPLIANT |
| **preflight-stop-means-stop** | No parent stop received; full amendment completed and written to the named path. | COMPLIANT |
| **rules-applied-verification-block** | This table; every row carries a measurement/quote + terminal conclusion (no empty cells, no AMBIGUOUS). | COMPLIANT |
| **empirical-evidence-blocks** | §8 EB-FINAL-1..5: each CHANGED state-claim (S-RT content + project twin clean; agent-run.sh 4 locations + 2/2 classification; corrected baselines 31/22/21; empty-residual; ×3 lock-step) has command + verbatim output + HEAD a84094a + 2026-06-19 + interpretation + SUPPORTED. Unchanged facts cite the reconciled/census EBs (EB-FINAL-5). | COMPLIANT |
| **ci-guard-measure-then-bound** | The gate fix IS the central correction: §5.1 adopts the whole-tree-minus-exclusions scope (cannot omit a directory — proven empty-residual EB-FINAL-3); sizes the KEEP allowlist exactly to the census §4 KEEP classes (history-excluded, fixtures-excluded, script false-pos, the moot self-detect/verb-ban, the reworded mechanism sentence, the agent-run.sh launcher-flag); states the expected post-flip model-phrase remainder = 0 (F-D); never widens to admit unclassified hits. Measured the tree FIRST (EB-FINAL-3), classified every occurrence KEEP/STRIP (§2 S-AR table, §5.1 allowlist), designed fix-recipes (§2), verified the post-fix gate runs clean (empty residual). | COMPLIANT |
| **enumerate-encoding-surfaces** | §1.2 enumerates every surface + every duplicate copy: pack-coder ×3, 4 RO pack defs ×12, skills ×3 each, project coder ×3, project repo-ops ×3, PLUS the newly-added S-RT (`RUNTIME-SUBAGENT-PATTERN.md`); each copy assigned to ONE commit/task (§3, §4.5) for lock-step. Confirmed no test/validator encodes the OLD default (EB-FINAL-5). | COMPLIANT |
| **pack-project-separation-of-concerns** | Pack commits C1-C4 and project commits C5-C6 never mix; each single-scope (Check 36, §3). S-RT is pack-only (C2); its project twin is a verified-clean NO-OP, NOT edited (would break C2's pack-only scope). F-1 graph fix stays pack-only/CLAUDE-only. | COMPLIANT |
| **bd-pack-only-operational-rule** | Zero BD-NNN in any project restatement (§5.2 grep-gate; baseline 0); project deferral = "a future pack version". | COMPLIANT |
| **cross-cli-reference-normalization** | The ×3 def/skill edits respect each CLI format (`.md` vs `.toml`), content-intent matched not byte-copied (§2 S7/S-RO/S13/S13b/S15/S16); project restatements audience-correct (P-missed-7 normalization block §2). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | This is an AMENDMENT: preserved the reconciled design's §0 ledger / §1 inventory / §2 deltas / §3 commits / §4 parallelization / §5 gates / §6 propagation / §7 verification / §8 EBs verbatim in substance; changed ONLY what the corrections require (added S-RT row + delta; widened S-AR to 4 locations + classification; replaced §5.1 gate scope with the whole-tree form + corrected baselines + tightened allowlist + expanded union; added §5.5/§5.6 scoping; F-G ADD phrasing on G2/G3). Not a from-scratch re-derivation. | COMPLIANT |
| **worktree-isolation-mergeback-ops** | Preserved rules 1-10 (§1.1) + Constraint-1 teardown (§2 S1/S3/S10 + §4.4) + report-location-always-/tmp + Constraint-3 merge-back (§2 S3/S10 + §5.4); the bounded review/fix cycle is UNCHANGED (only WHERE it runs). | COMPLIANT |
| **rename-plans-measure-then-bound** | The completeness gate is the whole-tree `git ls-files` union grep + KEEP-allowlist (coder PREFLIGHT + reviewer, §5.1/§5.5), NOT a hand-enumerated anchor list; the whole-tree-minus-exclusions form cannot omit a directory (empty-residual proof EB-FINAL-3). | COMPLIANT |
| **architect-doc-reality-reconciliation** | Realized consumers named by file+symbol, not line numbers for identity: S-RT = `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` "Read-write within scope (RW)" bullet; S-AR = `project-template/agent-run.sh` `run_in_worktree()` + the `--worktree` help/branch annotations; line numbers carried only as drift-anchors. | COMPLIANT |
| **dependency-direction-placement** | No pack-only content on any project surface: S-RT fix is pack-only (`.agents-plugin/pack-agents/`); the project twin is untouched; F-1 graph fix is CLAUDE-only/pack; `docs/impl-reports/` is a project deliverable, not a pack runtime dependency. | COMPLIANT |
| **filename-uniqueness-heuristic** | Output `DESIGN-BD-226-FINAL.md` is unique in the repo (the BD-226 doc family uses DESIGN-/DESIGN-…-RECONCILED-/PLAN-/CENSUS-/ADVERSARIAL-PLAN-REVIEW- prefixes; -FINAL is new and distinct); it is under `/tmp`, not in the tree. | COMPLIANT |

---

*End of FINAL planner-ready design for BD-226. It is the reconciled design + the verified-complete whole-tree census corrections (F-A whole-tree gate scope + empty-residual proof + corrected baselines 31/22/21; F-B `RUNTIME-SUBAGENT-PATTERN.md` as S-RT in C2; F-C agent-run.sh widened to 4 locations with a 2-KEEP/2-STRIP classification; F-D tightened allowlist to 0 model-phrase remainder; F-E per-commit-vs-batch-end scoping; F-F edit-region-scoped audience grep; F-G G2/G3-as-ADD; the expanded phrase union). Everything else carries unchanged from the reconciled design. No severe design flaw found. The planner re-reconciles PLAN-BD-226.md from THIS doc + backlog/BD-226.md.*
