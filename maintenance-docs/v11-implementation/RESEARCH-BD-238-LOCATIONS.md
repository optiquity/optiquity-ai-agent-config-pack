# RESEARCH-BD-238-LOCATIONS — Pack-side edit-location census (BD-238)

**Role:** pack-docs-researcher (RO). **Task class:** LOCATION / blast-radius census — factual inventory only. Where the pack-side large-BD-pipeline standard would be authored + every surface that already fragment-documents the pipeline. NOT rule-content design.

---

## (a) Runtime regime

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `7caff915a397050b9d53816c22086a56a627c5bc` (matches expected `7caff91`) |
| branch | `v11-dev` |
| `git status --short` | clean (no uncommitted changes) |
| graph used | `graphify-out/graph.json` (fresh at HEAD `7caff91`) for DISCOVERY; grep/Read for VERIFICATION |
| writes performed | EXACTLY ONE: this census doc. No source edits, no state-changing git. |

**State-drift note (important for the architect):** the BD-238 File/Symbol block measured `grep -rln adversarial …` → NO matches at HEAD `62805a8`. At the CURRENT HEAD `7caff91` that grep is NO LONGER zero — see (e) Ambiguity #1. The drift does not change the edit-location SET, only the baseline the architect's measure-then-bound must re-take.

---

## (b) The confined PACK-SIDE edit-location set

Grouped by surface type. Every file is at PACK-ROOT level; NONE under `project-template/` (proven in (d)).

### B1. Pack-root trinity `## Pack memory` (the SSOT for the standard)

Per BD-238 "Where it lives": trinity `## Pack memory` is the SSOT; the existing rules below already encode PIECES of the pipeline and would be referenced/extended by the consolidated standard. Line ranges measured at HEAD `7caff91`.

| File | Section / rule | Line range | Why in scope |
|---|---|---|---|
| `CLAUDE.md` | `## Pack memory` (umbrella) | L140 (heading) | Container of the SSOT; the new consolidated standard lands here. |
| `CLAUDE.md` | `### Workflow` | L150 | Holds `bounded review/fix cycle`-adjacent workflow rules the standard chains into. |
| `CLAUDE.md` | `### Agent invocation rules` | L240 | Holds `Researcher-first pipeline`, `Planner output → user review → coder spawn`, `Reconciliation-instance independence`, `Pack-coder PREFLIGHT` — the pipeline-stage rules. |
| `CLAUDE.md` | rule **Reconciliation-instance independence** `[rationale: reconciliation-instance-independence]` | L270–287 | Already encodes the reconciliation-round stage (fresh-instance rule). |
| `CLAUDE.md` | rule **Researcher-first pipeline for substantive content** | L288–296 | Already encodes the base chain `docs-researcher → architect → planner → coder` (the standard's spine). |
| `CLAUDE.md` | rule **Planner output → user review → coder spawn** | L296–306 | Already encodes the planner-to-coder user gate (standard step 7). |
| `CLAUDE.md` | `### Sub-agent behavior (Claude-only)` → **Parallelization map (rule 10)** | section L381; rule 10 at L416–419 | Already encodes the parallel-vs-dependent map the coder waves key off (standard step 8). CLAUDE-ONLY / Trinity-exempt — see note below. |
| `CLAUDE.md` | rule **Pack-architect spawn protocol** | L556–569 | Already encodes architect-first + the multi-stage pipeline framing. |
| `CLAUDE.md` | rule **Pack Chat NO coder review; bounded reviewer/fix cycle** `[rationale: bounded-review-fix-cycle]` | L580–587 | Already encodes the per-commit bounded review/fix cycle the coder waves run inside. |
| `AGENTS.md` | `## Pack memory` | L142 | Trinity parity copy (Checks 16/18/19 enforce). |
| `AGENTS.md` | `### Workflow` | L152 | parity |
| `AGENTS.md` | **Reconciliation-instance independence** | L260–276 | parity copy of the reconciliation rule |
| `AGENTS.md` | **Researcher-first pipeline** | L277–285 | parity copy |
| `AGENTS.md` | **Planner output → user review → coder spawn** | L285–~295 | parity copy |
| `AGENTS.md` | **Pack-architect spawn protocol** | L450–~470 | parity copy |
| `AGENTS.md` | **bounded reviewer/fix cycle** | ends L481 | parity copy |
| `GEMINI.md` | `## Pack memory` | L108 | parity |
| `GEMINI.md` | `### Workflow` | L118 | parity |
| `GEMINI.md` | **Reconciliation-instance independence** | L233–248 | parity copy |
| `GEMINI.md` | **Researcher-first pipeline** | L249–257 | parity copy |
| `GEMINI.md` | **Planner output → user review → coder spawn** | L257–~267 | parity copy |
| `GEMINI.md` | **Pack-architect spawn protocol** | L425–~445 | parity copy |
| `GEMINI.md` | **bounded reviewer/fix cycle** | ends L456 | parity copy |

**Trinity-exemption (load-bearing for the architect):** the `### Sub-agent behavior (Claude-only)` section — INCLUDING **Parallelization map (rule 10)** — exists ONLY in `CLAUDE.md`. Verified grep-zero in AGENTS.md / GEMINI.md:
```
$ grep -rn "Sub-agent behavior (Claude-only)\|Parallelization map (rule 10)" CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:381:### Sub-agent behavior (Claude-only)
CLAUDE.md:416:  - **Parallelization map (rule 10).** For any multi-commit effort the
```
So the "parallel worktree coder waves" portion of the standard is a CLAUDE-only surface (worktrees are Claude-only in this pack version); it must NOT be parity-ported to AGENTS/GEMINI. The other pipeline rules (researcher-first, reconciliation, planner-to-coder, bounded cycle, architect-spawn) DO carry trinity parity ×3.

### B2. `pack-ops/` operating docs (lifecycle + propagation reference surfaces)

| File | Section | Line range | Why in scope |
|---|---|---|---|
| `pack-ops/PACK-CHAT.md` | `## In-session sub-agent spawn + merge-back (worktree isolation)` | L228–393 | The orchestrator lifecycle the standard consolidates: `### How Pack Chat spawns` (L244), `### Merge-back` (L308), **Parallelization map (rule 10)** prose (L343), `### Conflict protocol` (L361). The standard's step 8 (parallel coder waves + sequential patch apply + conflict protocol) is documented HERE. |
| `pack-ops/PACK-CHAT.md` | `## Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current` → `### Rule-change propagation procedure` | L465–540 | The AUTHORITATIVE propagation-surface enumeration (the 6-row table). If the standard adds/changes a `[rationale:]` slug, this procedure governs the surfaces to touch. This is the propagation map (see B5). |
| `pack-ops/PACK-AGENTS.md` | `## Pack agents` (roster + Class column) | L8–25 | The agent roster the pipeline stages route to; Class column is pack-side SSOT for RW/RO. |
| `pack-ops/PACK-AGENTS.md` | `### Skills loaded by pack agents` | L27–42 | Maps which skill loads in which agent — relevant if the standard touches a spawn-relevant skill. |
| `pack-ops/PACK-AGENTS.md` | `### How to invoke pack agents` / `## When agents are used vs. pack chat direct` | L46–134 | Documents how stages are spawned (sub-agent vs separate session) — orchestration the standard references. |
| `pack-ops/PACK-AGENTS.md` | `## Agent permission rules` / `### Two agent classes` | L135–176 | RO/RW class model the coder-wave isolation depends on. |
| `pack-ops/PACK-AGENTS.md` | one-line spawn-rule reference rows (anti-restate target) | per `.spawn-rule-manifest.txt` references column | If a new spawn-rule slug is added, its collapsed one-line reference may land here (Check 46 anti-restate surface). |

**NOTE — pack-ops files OUT of scope (false-positive eliminated):** `pack-ops/DRY-RUN-MIGRATION.md` (L104) and `pack-ops/MERGE-STRATEGY.md` (12 hits) match the word "reconciliation" but ALL refer to the migrator's file-merge state `customization-detected-needs-reconciliation` — NOT the agent-pipeline reconciliation rounds. Evidence:
```
pack-ops/MERGE-STRATEGY.md:16:file as needing manual reconciliation. The same matrix applies symmetrically
pack-ops/MERGE-STRATEGY.md:30:- **What to do on `customization-detected-needs-reconciliation`** — the
pack-ops/DRY-RUN-MIGRATION.md:104:  AND the stdout tail shows `customization-detected-needs-reconciliation`
```
These two docs are NOT in the BD-238 blast radius.

### B3. Pack agent definitions (`.claude/agents/pack-*.md` + 2 mirrors each)

**Finding: NO pack agent definition documents the pipeline stages.** A targeted grep for pipeline vocab (`adversarial`, `reconciliation`, `researcher-first`, `planner-to-coder`, `large-BD`, `architect →`, `parallel wave`) returned NO file-level matches. The only incidental hits:
```
.claude/agents/pack-coder.md:35:  `git apply` — the orchestrator (Pack Chat) runs the review/fix cycle,
.claude/agents/pack-coder.md:127: ... parallel change to the other two ...   (= trinity-parity edit, not pipeline waves)
```
Neither documents the standard. The architect MAY elect to add a one-line pointer to the new standard in the relevant agent defs (architect, planner, coder), but at HEAD `7caff91` they are NOT existing fragment-documenters. The full pack-root agent file-set (each in 3 mirrors — parity-checked elsewhere):
```
.claude/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md
.codex/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md
.agents-plugin/pack-agents/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md
```
(If the architect edits a `.claude` agent def, the same edit propagates to the `.codex` + `.agents-plugin` mirror — parity-enforced; treat the 3 as one logical surface.)

### B4. Pack skills (`.claude/skills/*/SKILL.md` — 11 skills, 3 mirrors each)

**Finding: NO skill documents the pipeline STAGES as a chain or the size-tiering.** A grep for pipeline-stage vocab across all 11 skills returned NO file-level matches for `adversarial / reconciliation / researcher-first / planner-to-coder / large-BD / architect → / worktree wave`. The hits found are generic methodology references, NOT the standard:
- `planning/SKILL.md:18` — generic "identify steps that can be parallelized" (step-level, not coder-wave scheduling).
- `commit-discipline/SKILL.md:186` + `implementation-report/SKILL.md:11,16` — descriptive "Pack Chat reads the report, runs the review/fix cycle in the worktree" (the bounded cycle, mentioned in passing).
- `architecture-review`, `review`, `boundary-investigation` — generic architect/planner/reviewer methodology, no pipeline chain.

The 4 spawn-relevant skills bound by Check 46 anti-restate (`commit-discipline`, `review`, `planning`, `implementation-report`) are the ONLY skills that could become anti-restate targets if a new spawn-rule body were copied in — but they do not currently restate the standard. The architect MAY add a one-line pointer to the new standard in `planning` and/or `review`, but this is an architect call, not a pre-existing fragment. Full pack-root skill file-set (each ×3 mirrors `.claude` / `.codex` / `.agents`):
```
.claude/skills/{architecture-review,boundary-investigation,commit-discipline,dependency-intake,
  documentation,implementation-report,pack-help,pack-startup,planning,review,verification-harness}/SKILL.md
```

### B5. Rationale + manifest propagation surfaces

If the consolidated standard introduces a NEW `[rationale: <slug>]` (e.g. a `large-bd-pipeline-standard` slug — naming is the architect's call), the propagation procedure (PACK-CHAT.md L475 table) mandates these surfaces in lock-step:

| File | What | Gating check |
|---|---|---|
| `pack-ops/PACK-MEMORY-RATIONALE.md` | add `## <new-slug>` section (Why + How) | Check 45 bijection (slug-set equality vs CLAUDE.md corpus) |
| `pack-ops/.spawn-rule-manifest.txt` | add `slug: / canonical: / corpus: / references:` row | Check 46 reference-resolution |
| `pack-ops/PACK-AGENTS.md` and/or `pack-ops/PACK-CHAT.md` | one-line collapsed reference (if any) | Check 46 anti-restate + reference-resolution |
| out-of-repo thin memory-cache pointer | Pack-Chat upkeep | no validator (trinity-wins) |

Existing pipeline-relevant slugs ALREADY present (the standard extends/references, does NOT re-create):
```
$ grep "^slug:" pack-ops/.spawn-rule-manifest.txt
agents-never-commit / role-write-scope / preflight-stop-means-stop /
presents-triage-before-fix-coder / triage-all-fix-all / bounded-review-fix-cycle / pack-chat-minor-edits-only
$ grep "^## " pack-ops/PACK-MEMORY-RATIONALE.md | grep -iE "reconcil|bounded|review-fix"
## bounded-review-fix-cycle
## architect-doc-reality-reconciliation
## reconciliation-instance-independence
```
Note: `researcher-first-pipeline`, `pack-architect-spawn-protocol`, `planner-to-coder` (Planner output → …) are NOT currently in `.spawn-rule-manifest.txt` as slugs (they have no `[rationale:]` tag on their corpus lines) — so adding a consolidated standard slug is a NEW manifest+rationale row, while those three existing rules remain untagged. The architect decides whether to fold them under one new slug or leave them as-is and add a single umbrella standard.

### B6. Out-of-repo adversarial memories (reconcile-targets — NOT a repo edit surface)

Per BD-238 acceptance criteria, the two situational adversarial memories are reconciled to POINT AT the new in-repo standard (trinity-wins). They are NOT in the repo, so editing them is Pack-Chat memory upkeep, not a coder edit:
```
/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/
  feedback_adversarial_architect_review_on_major_gap.md   (4163 bytes, exists)
  feedback_adversarial_planner_review_major_plans.md      (2476 bytes, exists)
```
Flag for the architect: these are reconcile-targets in the standard's blast radius but are OUTSIDE the repo edit set (no validator gates them; trinity-wins on any conflict).

---

## (c) Gating validate-pack checks (per enumerate-encoding-surfaces)

Every check that GATES the surfaces above, so the architect's edit set is symmetric (doc + validator + cross-ref):

| Check | What it enforces | Surfaces it gates | Scope note |
|---|---|---|---|
| **Check 16 / 18 / 19** | Trinity parity (H2 structure / `## Project addenda` / no body scaffolding) | trinity files | **TEMPLATE-ONLY** per the code — these run on `project-template/` trinity, NOT the pack-root trinity `## Pack memory`. They DO NOT gate the pack-root SSOT. (See Ambiguity #2.) |
| **Check 45** | pack-memory rule↔rationale **bijection** (set-equality) | `CLAUDE.md` `## Pack memory` `[rationale:]` slugs ⇔ `pack-ops/PACK-MEMORY-RATIONALE.md` `## <slug>` headings | CLAUDE.md is the REPRESENTATIVE corpus; AGENTS/GEMINI parity is "separately enforced". Any new standard slug MUST appear in both. |
| **Check 46** | reference-resolution + **anti-restate** over `.spawn-rule-manifest.txt` (and `.boundary-pointer-manifest.txt`) | `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, and the 4 spawn-relevant skills (`commit-discipline`, `review`, `planning`, `implementation-report`) | (a) every named surface exists + carries its pointer; (b) no canonical `## Pack memory` imperative BODY (≥60 chars) reappears verbatim in a reference surface/skill. A new standard's body must NOT be copy-pasted into a reference surface. |
| **Check 36** | commit-scope honesty (`pack-only` keyword ⇒ diff must be pack-only) | the commit subject | BD-238 is PACK-ONLY (no `project-template/` touch per (d)) ⇒ the commit may carry `pack-only`; CI verifies. |
| **Check 52** | agent Class set-equality (RW/RO) | `PACK-AGENTS.md` Class column ⇔ agent-file prose mandate headers | Gates B3 if any agent def's mandate header is edited. |
| **Check 62 + `build.sh --verify`** | `test-fixtures/manifest.txt` correctness | fixture manifest | Push-time only; NOT a per-commit propagation step (PACK-CHAT.md table row 6). Relevant only if an agent/skill fixture input changed. |

The propagation ORDER (PACK-CHAT.md L505): corpus (trinity ×3) → rationale → references + spawn-rule manifest IN THE SAME COMMIT (so bijection + anti-restate never see a half-applied state) → cache as upkeep.

---

## (d) Disjointness verdict vs the project side (BD-239)

**VERDICT: DISJOINT.** The BD-238 pack-side edit set and the BD-239 project-side set are strictly different file-sets. NO file is shared. Evidence (per separate-pack-ops-from-pack-product):

**(1) Trinity is path-disjoint** — pack-root trinity vs project-template trinity are different paths:
```
$ git ls-files | grep -E "^(CLAUDE|AGENTS|GEMINI)\.md$|^project-template/(CLAUDE|AGENTS|GEMINI)\.md$"
AGENTS.md
CLAUDE.md
GEMINI.md
project-template/AGENTS.md      <- BD-239 surface, NOT mine
project-template/CLAUDE.md      <- BD-239 surface, NOT mine
project-template/GEMINI.md      <- BD-239 surface, NOT mine
```

**(2) `pack-ops/` has NO project-template counterpart** (it is pack-only by construction):
```
$ git ls-files | grep "project-template/.*pack-ops"
NONE: pack-ops/ does not exist under project-template/
```

**(3) `pack-*` agents are pack-only; the project roster is UNPREFIXED** (the BD-239 surface):
```
$ git ls-files | grep "project-template/.*pack-architect|...pack-coder|..."
NONE: pack-* agents do not exist under project-template/

$ git ls-files | grep -E "project-template/.*/(agents)/"   (the BD-239 side, for contrast)
project-template/.agents-plugin/optiquity-agents/agents/architect.md
project-template/.claude/agents/architect.md
project-template/.claude/agents/coder.md  ... (unprefixed: architect/coder/planner/reviewer/auditor*/tester/...)
```
My pack-side agents are `.claude/agents/pack-architect.md` etc. (prefixed, pack-root). The project-side agents are `project-template/.claude/agents/architect.md` etc. (unprefixed, under project-template). Different file-set.

**(4) Skills are path-disjoint** — my pack skills live at `.claude/skills/*` (pack-root); the project skills the BD-239 census owns live under `project-template/skills/` (the source the pack-root copies FROM, per PACK-AGENTS.md L29-30). Different trees.

**Shared-file flag:** NONE. No file in the BD-238 set could be touched by the BD-239 census. This matches `separate-pack-ops-from-pack-product` (pack ops files are NEVER mixed with `project-template/` product). The two standards (pack-self-operation vs project-lifecycle) live on cleanly separated surfaces.

---

## (e) Ambiguity for the architect to resolve

1. **State-drift since BD authoring (re-measure the baseline).** BD-238's File/Symbol claims `grep -rln adversarial …` = NO matches (HEAD `62805a8`). At HEAD `7caff91` "adversarial" now appears in the trinity ×3 + `PACK-MEMORY-RATIONALE.md` — ALL as part of the EXISTING `Reconciliation-instance independence` rule (the word entered via that rule, not a new standard):
   ```
   CLAUDE.md:271 / AGENTS.md:261 / GEMINI.md:234  — "...resolving an adversarial review's findings..."
   pack-ops/PACK-MEMORY-RATIONALE.md:661-679       — reconciliation-instance-independence rationale
   ```
   The architect's measure-then-bound MUST re-take the baseline at the live HEAD; the "no in-repo mention of adversarial" premise is now PARTIALLY satisfied by the reconciliation rule. The edit-location SET is unchanged.

2. **Pack-root trinity `## Pack memory` parity is gated by Check 45 (bijection) + Check 46 (anti-restate), NOT by Checks 16/18/19.** Checks 16/18/19 are template-only (project-template trinity) per the code. The architect should confirm what actually enforces ×3 byte-parity of the pack-ROOT `## Pack memory` rules (Check 45's note says "trinity parity of AGENTS.md/GEMINI.md is separately enforced by Checks 16/18/19" — but those are template-only; there may be a separate pack-root parity check, or the parity is discipline-enforced). Architect to verify which check (if any) byte-compares pack-root AGENTS/GEMINI `## Pack memory` against CLAUDE.md, so the edit set is symmetric.

3. **Single umbrella slug vs extend-existing.** Three pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) currently carry NO `[rationale:]` tag (not in `.spawn-rule-manifest.txt`). The architect decides whether the consolidated standard is (a) ONE new umbrella slug that references them, or (b) re-tagging each. This affects how many bijection/manifest rows change. Census-only flag — NOT a recommendation.

4. **Claude-only worktree-wave portion.** Step 8 (parallel worktree coder waves) lives in the CLAUDE-only `### Sub-agent behavior (Claude-only)` + PACK-CHAT.md merge-back. The architect must decide how the size-tiered standard expresses the parallel-wave step WITHOUT forcing a parity port to AGENTS/GEMINI (which would violate the documented Trinity-exemption). Census-only flag.

---

## (f) Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Only Write performed = `/tmp/pack-handoff-bd238-research/RESEARCH-BD-238-LOCATIONS.md`. All git invocations read-only (`git rev-parse HEAD` → `7caff915…`, `git status --short` → clean, `git ls-files | grep …`). No `add/commit/push/checkout/etc.` issued. | COMPLIANT |
| 2 | **scope-deliverables-to-the-ask** | Output censuses LOCATIONS (file + section + line-range + why), the gating checks, and the disjointness verdict ONLY. No rule wording authored; no size-tiering criterion designed (Ambiguity #3/#4 explicitly defer those to the architect). | COMPLIANT |
| 3 | **researcher-maps-blast-radius-before-architect** | Enumerated EVERY pack-side surface: trinity ×3 (with rule-level line ranges B1), `pack-ops/PACK-CHAT.md` + `PACK-AGENTS.md` (B2), 5 agents ×3 mirrors (B3, grep-zero proven), 11 skills ×3 mirrors (B4, grep-zero proven), rationale+manifest (B5), out-of-repo memories (B6), 6 gating checks (c). False-positives eliminated (DRY-RUN/MERGE-STRATEGY reconciliation = migrator state, quoted). | COMPLIANT |
| 4 | **enumerate-encoding-surfaces** | Included the doc surfaces AND every validator that gates them: Checks 16/18/19, 45, 46, 36, 52, 62+build.sh (section c), with each check mapped to the surface it gates. Asymmetry avoided (bijection slug ⇒ both RATIONALE.md + manifest + corpus). | COMPLIANT |
| 5 | **separate-pack-ops-from-pack-product** | Disjointness proven empirically (d): `git ls-files` shows pack-root trinity / `pack-ops/` / `pack-*` agents / `.claude/skills` are path-disjoint from `project-template/` equivalents; "NONE: pack-ops/ does not exist under project-template/"; "NONE: pack-* agents do not exist under project-template/". Shared-file flag = NONE. | COMPLIANT |
| 6 | **graph-first-context** | DISCOVERY via `graphify query` FIRST (3 queries against the injected `--graph /Users/.../graphify-out/graph.json --backend claude-cli --budget 1500`); it surfaced project-side + maintenance-doc audit nodes, confirming operating-doc rules are not node-indexed → fell to grep/Read for VERIFICATION of exact line ranges. G2 fallback used (graph returned no operating-doc rule nodes). Evidence quoted (graph traversal output + grep output) for every state-claim. | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — each rule 1–7 with quoted evidence + terminal conclusion (no AMBIGUOUS, no empty evidence). | COMPLIANT |
