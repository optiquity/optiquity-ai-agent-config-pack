# RESEARCH-BD-239 — PROJECT-SIDE Large-PHASE-Pipeline Standard: Edit-Location Census

**Researcher:** pack-docs-researcher (RO) · **BD:** BD-239 · **Scope:** LOCATION / blast-radius census (factual inventory — WHERE, not WHAT)

---

## (a) Runtime regime

| Field | Value | Evidence |
|---|---|---|
| Class | RO (read-only) | Sole Write = this census doc under `/tmp` |
| cwd | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` | `pwd` |
| HEAD | `7caff915a397050b9d53816c22086a56a627c5bc` | `git rev-parse HEAD` → matches expected `7caff91` |
| Working tree | CLEAN (no uncommitted changes) | `git status --short` → empty |
| Graph | EXISTS, queried for discovery | `graphify query … --graph …/graphify-out/graph.json --backend claude-cli --budget 1500` returned 26 nodes |

All state-claims below quote actual command output captured at HEAD `7caff91`, 2026-06-23.

---

## CRITICAL SCOPE FINDING (read first — affects the whole edit set)

The BD names `project-template/docs/pack/METHODOLOGY.md` as the primary SSOT surface. **That file does NOT physically exist under `project-template/`.** The authoritative, editable METHODOLOGY.md SOURCE lives at **`supporting-docs/METHODOLOGY.md`** and is COPIED to the client's `docs/pack/METHODOLOGY.md` by `init-project.sh` at install time.

Evidence:
```
$ ls project-template/docs/pack/METHODOLOGY.md
ls: .../project-template/docs/pack/METHODOLOGY.md: No such file or directory

$ ls -la supporting-docs/METHODOLOGY.md
-rw-r--r-- 1 david staff 95015 Jun 20 16:20 .../supporting-docs/METHODOLOGY.md   # 95 KB, present

# init-project.sh install map (the COPY mechanism):
1283: "supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic"
685:  cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
```

`supporting-docs/` is classified **PROJECT-SIDE deliverable** (not pack-ops self-operation), so editing `supporting-docs/METHODOLOGY.md` is in-scope for this PROJECT-SIDE BD:
```
$ grep -n "_PROJECT_SIDE_PATH_PREFIXES" scripts/validate-pack.py
3982: _PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")
```

**Implication for the architect:** the prompt said "census everything under `project-template/`," but the BD's named primary surface (METHODOLOGY.md) is sourced from `supporting-docs/`. The true PROJECT-SIDE edit-location set spans BOTH `project-template/` AND the project-side files in `supporting-docs/` (METHODOLOGY.md + INSTALL-PROCEDURES.md). Both are project-side deliverables; both are DISJOINT from pack-ops. The same `supporting-docs/INSTALL-PROCEDURES.md → docs/pack/INSTALL-PROCEDURES.md` copy pattern holds (`init-project.sh:1284`).

---

## (b) Confined PROJECT-SIDE edit-location set

Grouped by surface type. Each entry: file/group + which section + why in scope.

### Group 1 — Project methodology SSOT (the named primary surface; SOURCE is in supporting-docs)

| File (SOURCE) | Installs to | Section(s) the standard extends | Why in scope |
|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | `docs/pack/METHODOLOGY.md` | **Part 4 — Phase Structure** (L367; incl. `### Multi-part phases` L415, phase-task vocabulary); **Part 5 — Standard Workflows** (L446): Workflow 1 (L452 new project), Workflow 2 (L475 coder→reviewer cycle), Workflow 3 (L510 + external API research), **Workflow 4 — Fix cycle** (L523, the only place an architect trigger currently appears), Workflow 5 (L693 audit), Workflow 6 (L732 new feature); **Part 3 — Agent Roster** (L265, incl. `### Rejected-alternative documentation rule (architect agent)` L338); **Prompt Authoring Principles** (L762) | The named project methodology SSOT. Currently documents the BASE workflow (a simpler coder→reviewer cycle with a SITUATIONAL architect trigger in Workflow 4) but NO consolidated adversarial-review + reconciliation + parallel-worktree large-phase pipeline. This is where the new size-tiered standard's full chain would be authored. |

### Group 2 — PM-Chat orchestration doc (SOURCE lives in project-template)

| File (SOURCE = install) | Section(s) | Why in scope |
|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | `## Role` (L30), `## Pack agent roster` (L47), `## Behavioral rules` (L172, incl. fix-cycle + architect-trigger rules ~L255), `## TD resolution orchestration` (L702 — promotes TD→phase/phase-task), `## Custom agent and skill workflow` (L822), `## Additional project documents` (L1077) | The PM-chat orchestration the standard would extend (who spawns architect/planner/coder/reviewer, the fix-cycle rules, the architect/planner triggers). Installs verbatim: `init-project.sh:1237 "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"`. NOTE: PM-CHAT.md references METHODOLOGY.md ~30 times (e.g. L39 "Follow the full methodology defined in METHODOLOGY.md", L255 "Follow Workflow 4 in METHODOLOGY.md, including the architect…") — so a new pipeline section must be cross-referenced consistently here. |

### Group 3 — Project trinity Project-memory sections (3 distinct files at project-template root)

| File | Section | Existing rules that encode workflow pieces | Why in scope |
|---|---|---|---|
| `project-template/CLAUDE.md` | `## Project memory` (L360) | `Reconciliation-instance independence` (L418 — already encodes the fresh-instance reconciliation rule for every project agent role except docs-researcher); `PM chat does not architect` (L390); `Project SSOT-first` (L397) | Project-memory carries the universal collaboration rules. The standard's reconciliation-round + adversarial-review rules align with the EXISTING `Reconciliation-instance independence` rule here — the architect determines whether to extend it or add a new pipeline rule. Also present: `## Phase routing — default agent assignments` (L429, the phase→agent table). |
| `project-template/AGENTS.md` | `## Project memory` (parity copy) | Same set (trinity parity required) | Trinity rule: any Project-memory edit to CLAUDE.md must be mirrored here in the same set of edits. |
| `project-template/GEMINI.md` | `## Project memory` (parity copy) | Same set (trinity parity; GEMINI may add `## Agent roster` / `## Antigravity CLI operating notes` only) | Trinity rule (third leg). |

Distinct-file evidence (NOT the pack-root trinity):
```
$ stat -f "%i %N" project-template/CLAUDE.md CLAUDE.md
171166774 project-template/CLAUDE.md     # project trinity
171780050 CLAUDE.md                       # pack-root trinity — DIFFERENT inode
```

### Group 4 — Project agent definitions ×3 CLI families (16 per family = 48 files)

Counts (verified):
```
$ ls project-template/.claude/agents/*.md | wc -l      → 16
$ ls project-template/.codex/agents/*.toml | wc -l     → 16
$ ls project-template/.agents-plugin/optiquity-agents/agents/*.md | wc -l → 16
```

Per-family roster (identical names across the three families):
`architect`, `planner`, `coder`, `reviewer`, `docs-researcher`, `tester`, `grpc-schema`, `repo-ops`, `auditor`, `auditor-architecture`, `auditor-code`, `auditor-docs`, `auditor-ops`, `auditor-security`, `auditor-tests`, `auditor-ui`.

| Family | Path glob | Format | Pipeline-stage agents in scope |
|---|---|---|---|
| Claude | `project-template/.claude/agents/*.md` | Markdown | `architect.md`, `planner.md`, `coder.md`, `reviewer.md`, `docs-researcher.md` (the optional internal/external researcher), `tester.md`, `grpc-schema.md`, `repo-ops.md`, the auditor set (8 files) |
| Codex | `project-template/.codex/agents/*.toml` | TOML | same 16, `.toml` |
| Antigravity plugin | `project-template/.agents-plugin/optiquity-agents/agents/*.md` | Markdown | same 16, `.md` |

Why in scope: these agents reference workflow stages (the implementation skill already documents worktree-isolation — see `implementation/SKILL.md` L44/L58 "isolated worktree" + "read-ONLY agent … running in a live worktree writes ONLY its report and emits NO patch"). If the standard adds adversarial-review / reconciliation / parallel-worktree-wave behavior, the architect determines which agent files need a stage reference. The three families must move in lock-step (parity Checks below).

### Group 5 — Project skills documenting workflow stages

Verified-present workflow-stage skills (37 skills total; the workflow-relevant subset):
```
$ for s in planning implementation review audit-methodology …; do test -f project-template/skills/$s/SKILL.md && echo EXISTS; done
EXISTS: project-template/skills/planning/SKILL.md
EXISTS: project-template/skills/implementation/SKILL.md
EXISTS: project-template/skills/review/SKILL.md
EXISTS: project-template/skills/audit-methodology/SKILL.md
EXISTS: project-template/skills/documentation/SKILL.md
EXISTS: project-template/skills/architecture-review/SKILL.md
EXISTS: project-template/skills/pm-startup/SKILL.md
EXISTS: project-template/skills/repo-ops/SKILL.md
EXISTS: project-template/skills/dependency-intake/SKILL.md
EXISTS: project-template/skills/testing/SKILL.md
EXISTS: project-template/skills/boundary-investigation/SKILL.md
```

| Skill | Path | Stage documented | Why in scope |
|---|---|---|---|
| `planning` | `project-template/skills/planning/SKILL.md` | Planning stage (L32 references reviewer-preemption) | Planner stage of the pipeline |
| `implementation` | `project-template/skills/implementation/SKILL.md` | Implementation + worktree isolation (L44 "isolated worktree"; L58–60 RO-agent-in-live-worktree contract) | Already encodes the worktree-isolation model the coder waves use — the most pipeline-relevant skill |
| `review` | `project-template/skills/review/SKILL.md` | Review + carry-forward discipline (L34–38 SIZE/BLOCKED/FIX-NOW tests) | Reviewer stage + bounded review/fix cycle |
| `audit-methodology` | `project-template/skills/audit-methodology/SKILL.md` | Audit cadence (L14/L20 retrospective/periodic; auditor cluster defs) | Audit stage (Workflow 5) |
| `architecture-review` | `project-template/skills/architecture-review/SKILL.md` | Architecture review | Adversarial-architect-review stage analog |
| `pm-startup` | `project-template/skills/pm-startup/SKILL.md` | PM-chat startup/orchestration | PM-chat orchestration entry point |

Architect determines which skills need a stage reference; `implementation`, `review`, `planning`, `audit-methodology` are the highest-probability touch set.

### Group 6 — Vocabulary-defining docs (project terms only — no pack work-item leakage)

The standard MUST use PROJECT vocabulary (phases / phase tasks / TD backlog / groupings). Where that vocabulary is defined:

| Surface | Defines | Evidence |
|---|---|---|
| `project-template/docs/project/implementation-plan/_rules.md` | PHASE + phase-task vocabulary, filename `^phase-\d+\.md$`, "tasks live inline in the phase file", phase-state vocabulary | L14–16, L20–24, L28 |
| `project-template/docs/project/backlog/_rules.md` | TD-NNN (tech-debt) vocabulary, `^TD-\d+\.md$`, `✅ RESOLVED (Phase NN)` | L14–15, L22, L28 |
| `supporting-docs/METHODOLOGY.md` | Part 4 Phase Structure (phase epic `phase-N` / sibling-or-cross-phase task `phase-N.M`), `### Multi-part phases` | L386, L415 |
| `project-template/docs/pack/PM-CHAT.md` | `## TD resolution orchestration` — TD→phase / TD→phase-task promotion paths (the TD/phase/phase-task relationship) | L702–719 |

These are NOT primary edit targets but the architect references them to keep the standard's vocabulary project-correct. Note `groupings` is named in BD-239 vocabulary but a literal `grep -rln "groupings" project-template/docs/project/` returned NO hits — groupings vocabulary appears NOT yet defined in the project stream docs (it is a pack-side / v11.1 concept per the active project state). The architect should confirm whether "groupings" belongs in the shipped v11.0 standard or is forward-looking.

---

## (c) Gating validate-pack checks (per enumerate-encoding-surfaces)

Checks that GATE the project surfaces in the edit set:

| Check | What it gates | Evidence (validate-pack.py) |
|---|---|---|
| **Check 5 — Agent file count consistency** | Claude↔Codex 2-way + plugin-roster count parity (all 3 families ship the same named 16-agent roster) | L688–700 |
| **Check 18 — Trinity H2 structure parity** | CLAUDE/AGENTS/GEMINI H2 names + order WITHIN a trinity location; runs at BOTH `project-template` (default) AND `pack-root` (param) → confirms the two trinities are distinct surfaces checked separately | L1585–1623 |
| **Check 16 — Trinity `## Project addenda` H2** | Project-template trinity carries the addenda marker | L1926–1970 |
| **Check 19 — Trinity templates free of body scaffolding** | Project-template trinity hygiene | L1498–1542 |
| **Check 27 — Agent canonical-phrase compliance + skills-to-load conformance** | Every project-template agent definition carries canonical phrasing; skill-cell conformance (BD-146 extension) | L1753–1818 |
| **Check 11 — Pack agent trinity-rule symmetry (informational)** | Roster agent trinity-rule symmetry | L1081–1097 |
| **Check 17 — Tool-config AGENT_CAPABILITIES parity** | AGENT_CAPABILITIES expressed identically across tool configs | L1175–1192 |
| **Check 31 — Skill-cell consistency vs PLATFORM-SKILLS.md** | Skill cells match PLATFORM-SKILLS.md | L2977–3005 |
| **Check 39 — `project-template/docs/pack/*.md` forward-check** | Every docs/pack md file has a `cmd_update` install mapping (so PM-CHAT.md edits stay install-mapped) | L4980–4995 |
| **Check 64 — shipped-doc cite gate** | Cites must resolve to `project-template/<basename>` or be dropped (gates cross-refs into the methodology/PM-CHAT) | L7147 |
| **Check 70 — shipped client doc-gate structural parity** | Shipped client doc-gate structural parity (BD-243) | L9011–9066 |
| **Check 1 — SKILL.md frontmatter** | Every skill's frontmatter (gates Group-5 skill edits) | L530–533 |

`supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` are inside the project-side fence allowlist (`scripts/validate-pack.py` L4468–4469), confirming they are sanctioned project-side deliverable sources.

---

## (d) Disjointness verdict vs the PACK side

**VERDICT: DISJOINT.** Zero shared files between the BD-239 (project-side) edit set and the BD-238 (pack-side) edit set.

The separate BD-238 researcher censuses the PACK-SIDE companion: pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, `pack-ops/*`, `.claude/agents/pack-*`, `.claude/skills/*`. My PROJECT-SIDE set lives entirely under `project-template/` + the project-side files in `supporting-docs/`. Verified disjoint on every axis:

| Axis | Pack side (BD-238) | Project side (BD-239, this census) | Shared? |
|---|---|---|---|
| Trinity | `/CLAUDE.md` (inode 171780050) | `/project-template/CLAUDE.md` (inode 171166774) | NO — distinct inodes |
| Methodology SSOT | trinity `## Pack memory` + `pack-ops/PACK-CHAT.md` | `supporting-docs/METHODOLOGY.md` + `project-template/docs/pack/PM-CHAT.md` | NO |
| Agents | `.claude/agents/pack-*` (pack-root, 5 pack agents) | `project-template/.claude/agents/*` + `.codex/agents/*` + `.agents-plugin/.../*` (48 files) | NO |
| Skills | `.claude/skills/*` (pack-root) | `project-template/skills/*` (37) | NO |
| Ops docs | `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md` | (none — project has no pack-ops; uses PM-CHAT.md) | NO |

Supporting evidence:
```
# project-template/ is a separate subtree from pack-root operating files:
$ grep -n "_PROJECT_SIDE_PATH_PREFIXES" scripts/validate-pack.py
3982: _PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")
# (pack-ops/ is NOT in this prefix set → it is pack-side, not in my edit set)

$ ls -d pack-ops      → pack-ops (PRESENT, pack-side, NOT in my set)
```

Per the `separate-pack-ops-from-pack-product` rule: pack-ops self-operation files (CLAUDE.md/AGENTS.md/GEMINI.md at pack root, PACK-CHAT.md, PACK-AGENTS.md, the `/backlog/` + `/changelog/` trees) are NEVER mixed into project-template product files — and the converse. No file in my project-side set is a pack-ops self-operation file at the pack root. **No file could be touched by BOTH sides.**

One caution flag (not an overlap, but a coordination point): both BDs edit the SAME-NAMED concept ("the large-phase/large-BD pipeline standard") in PARALLEL FILES. BD-238 lands it in pack-root trinity `## Pack memory`; BD-239 lands it in project-side METHODOLOGY/PM-CHAT/project-trinity. The architect must ensure the project-side standard re-expresses the pack-side shape in PROJECT vocabulary (phases, not BDs) without importing pack work-item concepts — but there is no FILE collision.

---

## (e) Ambiguities for the architect

1. **METHODOLOGY.md source location (HIGH).** The BD names `project-template/docs/pack/METHODOLOGY.md`, but that file does NOT exist there — the editable source is `supporting-docs/METHODOLOGY.md` (installed to `docs/pack/METHODOLOGY.md` by `init-project.sh`). The architect must author the standard in `supporting-docs/METHODOLOGY.md`, NOT in a non-existent `project-template/docs/pack/METHODOLOGY.md`. INSTALL-PROCEDURES.md has the identical source/install split (`supporting-docs/INSTALL-PROCEDURES.md → docs/pack/INSTALL-PROCEDURES.md`).

2. **"groupings" vocabulary (MEDIUM).** BD-239 lists "groupings" as project vocabulary the standard may use, but `grep -rln "groupings" project-template/docs/project/` returns ZERO hits — groupings are not defined in the project stream contracts at HEAD `7caff91` (active project state notes groupings as a v11.1 concept, BD-186/189). The architect must decide whether the shipped v11.0 standard references groupings at all (risk: forward-reference to an undefined project concept).

3. **Reconciliation rule already exists project-side (MEDIUM).** `project-template/CLAUDE.md` L418 already carries `Reconciliation-instance independence` (fresh instance, never original author nor adversarial reviewer, all roles except docs-researcher). The architect must decide: EXTEND this existing rule vs. ADD a new size-tiered pipeline rule — to avoid duplication/conflict and to keep trinity parity.

4. **Worktree-isolation already documented project-side (LOW).** `implementation/SKILL.md` L44/L58 already encodes the isolated-worktree + RO-agent-no-patch model. The parallel-worktree-coder-waves stage of the standard should cross-reference this rather than re-derive it.

5. **Scope phrasing (LOW).** The prompt scoped "everything under `project-template/`," but the true project-side edit set includes `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` (project-side deliverables, not pack-ops). The architect should treat "project side" = `project-template/` ∪ project-side `supporting-docs/` files, NOT `project-template/` alone.

6. **Three-family lock-step cost (LOW).** Any agent-stage reference added to one family must be added to all three (Claude .md / Codex .toml / Antigravity plugin .md = 48 files), gated by Check 5 + Check 27. The architect should bound which agent files actually need a stage reference (likely just architect/planner/reviewer/docs-researcher/coder, not the 8 auditors) to keep the edit set tight.

---

## (f) Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Ran only read-only verbs: `git rev-parse HEAD`, `git status --short`, `git log --oneline -- <path>`, `ls`, `grep`, `graphify query`, `Read`. NO `git add/commit/push/checkout/etc.` Sole Write = this census at `/tmp/pack-handoff-bd239-research/RESEARCH-BD-239-LOCATIONS.md`. | COMPLIANT |
| 2 | scope-deliverables-to-the-ask | Census reports LOCATIONS + sections + gating checks + disjointness only. Section (a)–(f) carry no rule wording and no size-tiering criterion design — "where" only. The size-tiering / rule text is explicitly deferred to the architect (Ambiguities #2/#3). | COMPLIANT |
| 3 | researcher-maps-blast-radius-before-architect | Enumerated ALL 3 agent families with verified counts (`ls … \| wc -l` → 16/16/16); ALL 37 skills listed; both methodology sources (`supporting-docs/METHODOLOGY.md` + `project-template/docs/pack/PM-CHAT.md`); all 3 project-trinity files; vocabulary-defining stream docs. No surface left a-priori. | COMPLIANT |
| 4 | enumerate-encoding-surfaces | Section (c) enumerates 12 gating validate-pack checks (5/18/16/19/27/11/17/31/39/64/70/1) with line-number evidence — the validators that encode the expected state of trinity parity, agent-family parity, skill frontmatter, and docs/pack install mapping. | COMPLIANT |
| 5 | separate-pack-ops-from-pack-product | Section (d): verified `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` (L3982) excludes `pack-ops/`; distinct trinity inodes (171166774 vs 171780050); no pack-ops file in the project-side set. DISJOINT verdict evidence-backed. | COMPLIANT |
| 6 | pack-side-project-concepts-deliverable-only | Section (b) Group 6 + Ambiguity #2 located project vocabulary (phases/phase-tasks/TD/groupings) in the stream `_rules.md` files + METHODOLOGY Part 4; flagged that the standard must use project terms only and that "groupings" is undefined project-side (no pack work-item import). | COMPLIANT |
| 7 | graph-first-context | DISCOVERY ran `graphify query "project-side development workflow pipeline…" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` (returned 26 nodes incl. PM-CHAT.md, project trinity Pack-memory, the agent roster) using the INJECTED absolute path verbatim; VERIFICATION (exact paths/sections/inodes/check line numbers) via grep/Read. | COMPLIANT |
| 8 | rules-applied-verification-block | This table: each rule 1–8 with quoted evidence + terminal conclusion (no empty cells, no AMBIGUOUS). | COMPLIANT |
