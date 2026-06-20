# IMPL-REPORT-BD-241-coder — discoverable spawned agents (unique NAMES + Claude REGISTRY + name→agentId find) + reconciliation-instance independence + stale cross-CLI claim correction

**Agent:** pack-coder (READ-WRITE, isolated worktree). **Date:** 2026-06-20.
**Plan executed:** `/tmp/pack-handoff-bd241-plan/PLAN-BD-241-RECONCILED.md` (authoritative).
**Design inputs:** `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-RECONCILED.md` (Bullets A/B, S1/S2/S3) + `DESIGN-BD-241-D3-ADDENDUM.md` (Bullet C, CPR1/CPR2) + `DESIGN-BD-241-L418-CORRECTION.md` (S4).

## Runtime regime (verified at runtime, pwd/HEAD ground-truth)

- **pwd:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a87126bf21d37bf80` (isolated worktree — NOT the canonical `…optiquity-ai-agent-config-pack-v11-dev`).
- **Worktree branch:** `worktree-agent-a87126bf21d37bf80`.
- **HEAD (base + final, unchanged — no commit produced):** `797b4c5035496605348f4900efd95266de8d34d9`.
- **Base-predecessor (BD-240) confirmation:** BD-240's two-phase graph-first re-frame is PRESENT at base — `grep -n "DISCOVERY / RECALL" CLAUDE.md AGENTS.md GEMINI.md` → CLAUDE:646 / AGENTS:564 / GEMINI:541. This proves the correct post-BD-240 base (BD-241 serializes after BD-240 on the shared trinity + RATIONALE files). BD-240's `graph-first-context` rule + its rationale tail were NOT touched.
- **Pre-flight baseline validate-pack:** GREEN — Check 45 = 23↔23, Check 46 = 7 spawn / 0 restate / 49 candidates, Check 18 both green. Target after edits: 26↔26 (+3 from Bullets A/B/C).

## Files changed inventory (9 files, grouped by the plan's 2-commit split)

### COMMIT-1 group (pack-only — pack-ops surfaces only; NO `project-template/` or `supporting-docs/`)
| Path | Change type | Edits applied |
|---|---|---|
| `CLAUDE.md` | modified | Bullet A (`spawn-unique-naming`), Bullet C (`reconciliation-instance-independence`), Bullet B (`spawn-registry-find`, CLAUDE-only), S1 (Agent-team lifecycle stale parenthetical), S4 (standalone Trinity-exemption bullet, PARTIAL) |
| `AGENTS.md` | modified | Bullet A (Codex audience), Bullet C (Codex audience) |
| `GEMINI.md` | modified | Bullet A (Antigravity audience), Bullet C (Antigravity audience) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified | R1/R2/R3 (3 bare-slug rationale sections), S2 (Codex SendMessage stale line) |

### COMMIT-2 group (NO scope keyword — spans `supporting-docs/` + `project-template/`)
| Path | Change type | Edits applied |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | modified | S3 (SHIPPED stale peer-messaging blockquote, client-audience) |
| `project-template/CLAUDE.md` | modified | CPR1a (`## Project memory` recon bullet, Claude audience) |
| `project-template/AGENTS.md` | modified | CPR1b (`## Project memory` recon bullet, Codex audience) |
| `project-template/GEMINI.md` | modified | CPR1c (`## Project memory` recon bullet, Antigravity audience) |
| `project-template/docs/pack/PM-CHAT.md` | modified | PR1 (naming-discipline prose), CPR2 (reconciliation prose), PR2 (Claude-only registry blockquote) |

**No files deleted; no new files created** (the registry is a runtime gitignored artifact — documentation only, no tracked file, per plan §5).

## Per-task summary

### Commit-1 — Bullet A `spawn-unique-naming` (trinity ×3, `### Agent invocation rules`)
- Inserted as a NEW tagged bullet at the END of `### Agent invocation rules` (after `ci-guard-measure-then-bound`, before `### Sub-agent behavior (Claude-only)`) in all 3 trinity files.
- Shared body byte-identical across CLAUDE/AGENTS/GEMINI; per-`cross-cli-reference-normalization` ONLY the per-CLI name-field sentence differs: CLAUDE "the Agent-tool `name` parameter (addressable via `SendMessage({to: name})`)"; AGENTS "In Codex the `name` is the agent `name` field (the `nickname` is display-only)"; GEMINI "On Antigravity address by the known agent ID / named-role type".
- Tag `[roles: universal] [rationale: spawn-unique-naming]`. Verbatim from DESIGN-RECONCILED §3.1 / PLAN §3.1.

### Commit-1 — Bullet C `reconciliation-instance-independence` (trinity ×3, `### Agent invocation rules`)
- Inserted as a NEW tagged bullet AFTER `**No prior reviews to pack-reviewer.**` (its independence-family sibling), BEFORE `**Researcher-first pipeline…**`, in all 3 trinity files.
- Load-bearing clauses kept VERBATIM: "NEVER the original author … NOR the adversarial reviewer"; "ONE exception: `docs-researcher` … no design bias"; "This rule REINFORCES `fresh-agent-default`".
- Per-`cross-cli-reference-normalization` ONLY carve-out (1)'s re-engage path differs: CLAUDE "in Claude Code via `SendMessage` to that instance — the BD-241 discoverability mechanism then re-finds it; on Codex / Antigravity via the platform's re-engage path"; AGENTS "in Codex via the platform's agent re-engage / `resume_agent` path (where its multi-agent messaging is enabled)"; GEMINI "on Antigravity via the platform's known-ID re-engage / idle-rewake path".
- Tag `[roles: universal] [rationale: reconciliation-instance-independence]`. Verbatim from DESIGN-D3-ADDENDUM §1.2 / PLAN §3.3.

### Commit-1 — Bullet B `spawn-registry-find` (CLAUDE.md ONLY, `### Sub-agent behavior (Claude-only)`)
- Inserted as a NEW tagged bullet AFTER `**Agent-team stage lifecycle + per-commit fresh-coder.**`, BEFORE `**Trinity exemption.**`.
- Load-bearing clause kept VERBATIM (across natural line-wrap): "Consult the registry ONLY after the `fresh-agent-default` gate authorizes a re-engage."
- Cross-references Bullet A's slug `(see `### Agent invocation rules` `[rationale: spawn-unique-naming]`)` — the design-intended pointer (DESIGN-RECONCILED §3.2). Tag `[roles: universal] [rationale: spawn-registry-find]`.
- CLAUDE-only single-surface (Claude-only mechanism) — correctly NOT mirrored to AGENTS/GEMINI.

### Commit-1 — R1/R2/R3 rationale sections (`pack-ops/PACK-MEMORY-RATIONALE.md`)
- Inserted as a 3-section block AFTER `## pack-chat-minor-edits-only` (and its `---`), BEFORE `## graph-first-context` (per F-3: content-anchored, OFF BD-240's EOF tail).
- Order: `## spawn-unique-naming` → `## spawn-registry-find` → `## reconciliation-instance-independence`. Each a BARE-SLUG heading (Check 45 regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`), Why/How/Rejected body per PLAN §3.1/§3.2/§3.3 + D3-ADDENDUM §2.3. Each separated by the existing `---` convention.

### Commit-1 — S1 (CLAUDE.md, Agent-team lifecycle stale parenthetical)
- Replaced "(Codex / Antigravity have no peer-messaging equivalent — confirmed absent per Codex issue #12462 and Antigravity's hub-and-spoke subagent model)." with the corrected MAv2/`agy`-analogs-exist-but-flag-gated text (PLAN §4.1). Rest of the bullet preserved.

### Commit-1 — S4 (CLAUDE.md, standalone `**Trinity exemption.**` bullet) — PARTIAL correction
- Replaced the entire L418-422-region bullet with the L418-CORRECTION §2 text: PRESERVES the exemption opener ("This sub-section is Claude-specific (not mirrored in `AGENTS.md` / `GEMINI.md`)"), PRESERVES the `run_in_background` named-parameter point (reframed audience-correct), reframes Agent-tool specificity to "built against Claude Code's Agent-tool mechanism", CORRECTS the stale peer-messaging leg, DROPS the stale "per research §2.5 / §2.7 / §3.5 / §3.7" citation. Lands in the same CLAUDE.md pass as S1 (same bullet-cluster).

### Commit-1 — S2 (`pack-ops/PACK-MEMORY-RATIONALE.md`, Codex SendMessage stale line)
- Replaced "Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462)." with the corrected MAv2 `send_message`-analog text (PLAN §4.2). The Antigravity line (already accurate) left UNTOUCHED. The trailing `/agent`/natural-language reliability lines retained.

### Commit-2 — S3 (`supporting-docs/METHODOLOGY.md`, SHIPPED — the BLOCKER fix)
- Replaced the stale "This convention is Claude-Code-specific: … no peer-messaging across multiple parent turns)." blockquote tail with the client-audience corrected wording (no pack-internal `#12462`/`multi_agent_v2` jargon), per PLAN §4.4. Blockquote `> ` markers preserved on every line. KEPT the final routing sentence "Codex / Antigravity project teams: this convention does not apply to your CLI's runtime behavior."

### Commit-2 — CPR1a/b/c (project trinity `## Project memory` ×3)
- Inserted a project-audience reconciliation-independence bullet AFTER the "Project SSOT-first" bullet, BEFORE `## Phase routing`, in all 3 project trinity files. Project vocabulary only (no pack BD-refs, no pack-* agent names, no "Pack Chat"); "the developer" override; the project agent roster (architect/planner/coder/reviewer/auditor/repo-ops/tester/grpc-schema/docs-researcher per the `docs/pack/PM-CHAT.md` roster SSOT). Per-CLI carve-out audience-correct (Claude SendMessage / Codex resume_agent / Antigravity known-ID rewake). NO `[rationale:]` tag (project `## Project memory` is not the `## Pack memory` corpus → does not affect Check 45 — confirmed below).

### Commit-2 — PR1 + CPR2 + PR2 (`project-template/docs/pack/PM-CHAT.md`)
- PR1 (naming discipline, CLI-agnostic) + CPR2 (reconciliation prose, CLI-agnostic) added after the existing "Spawn in the background." block in `### In-session agent spawning`.
- PR2 (Claude-only registry blockquote, modeled on the L897 `(Claude-only)` blockquote) added after the merge-back numbered list (step 5).

## Boundary discipline check (P-missed-7) — project-side edits

Project-side surfaces touched: `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` (CPR1) and `project-template/docs/pack/PM-CHAT.md` (PR1/PR2/CPR2), plus the SHIPPED `supporting-docs/METHODOLOGY.md` (S3). SSOT investigation per surface:

- **CPR1 (project trinity `## Project memory`):** the project-side SSOT for universal collaboration rules IS the project trinity `## Project memory` section itself (charter at `project-template/CLAUDE.md` L351-359: "this section carries only the universal collaboration rules that apply project-wide regardless of agent role"). Reconciliation-instance independence is a universal collaboration rule → BELONGS here (D3-ADDENDUM §2.2, claim E). The bullet uses project vocabulary only; NO pack-only target introduced (no `pack-ops/` ref, no `PACK-AGENTS.md`/`PACK-CHAT.md`, no pack-* agent name, no capitalized "Pack Chat" orchestrator). The project agent roster cited matches the project-side SSOT `docs/pack/PM-CHAT.md` § Pack agent roster (L53-68).
- **PR1/PR2/CPR2 (PM-CHAT.md):** the project-side SSOT for in-session spawn/merge-back runtime is `project-template/docs/pack/PM-CHAT.md` § "In-session agent spawning" itself. PR1/CPR2 modeled on the existing CLI-agnostic "Spawn in the background." prose; PR2 modeled on the existing `> **Per-project Claude memory cache (Claude-only).**` blockquote. NO pack-only reference introduced; "the PM chat" / "the developer" project vocabulary used throughout (no "Pack Chat", no BD-refs in the prose — the only `BD-217` mention is intentionally absent from project surfaces; the Claude-only registry blockquote says "Codex / Antigravity equivalents are a future pack version" with no pack-internal anchor).
- **S3 (METHODOLOGY.md, SHIPPED):** client-developer audience; the correction strips pack-internal jargon (`#12462`, `multi_agent_v2`) → plain-language analog description. No pack-only target.

**Boundary discipline stop:** NONE. No proposed edit would add a reference to a pack-only file from a project surface. No re-prompting needed.

## Plan deviations

**ZERO substantive deviations.** All edits applied content-anchored, verbatim from the design texts. Two NON-deviations worth noting for the reviewer (text matches design; only the plan's single-line PREFLIGHT grep literals needed wrap-aware confirmation):
1. Several plan §12.2 grep gates use single-line literals that span a natural Markdown line-wrap in the applied text (e.g., gate #4 "Consult the registry ONLY after the `fresh-agent-default` gate authorizes a re-engage" wraps after "authorizes"; the S4 "built against Claude Code's Agent-tool mechanism" wraps after "built"; the per-CLI Bullet-A clauses wrap). Each was re-confirmed PRESENT via newline-collapse (`tr '\n' ' '`). The applied text is design-verbatim; the gate literals were the only thing affected by wrapping.
2. Plan gate #3 used the paraphrase `EXCEPT \`docs-researcher\``; the design-verbatim text is "ONE exception: `docs-researcher`" (present 1/1/1). The design text — not the paraphrase — is authoritative.

## New POQs introduced

NONE.

## Out-of-scope items NOT touched (per prompt + plan)
- 2 out-of-repo memory files (`reference_sendmessage_uuid_addressing`, `feedback_*`) — Pack Chat upkeep. NOT touched.
- `backlog/BD-217.md` scope-note (G1) — pack-chat-only governance. NOT touched.
- `pack-ops/PACK-CHAT.md` step-1 carve-out note (G2, optional) — pack-chat-only. NOT touched.
- `pack-ops/.spawn-rule-manifest.txt` — NO record added (greenfield rules; DROP-P5 decision). NOT touched.
- `backlog/`, `changelog/`, `test-fixtures/manifest.txt` — NOT touched (confirmed absent from `git diff --name-only`).
- `.gitignore` — NO edit (`graphify-out/` already covers the registry leaf; confirmed `.gitignore` L76). NOT touched.

## Verification results (all PASS)

### PREFLIGHT grep gates (PLAN §12.2)
| Gate | Check | Result |
|---|---|---|
| 1 | Rationale bare-slug headings ×3 | PASS — `## spawn-unique-naming` (L641), `## spawn-registry-find` (L666), `## reconciliation-instance-independence` (L691); all bare-slug |
| 2 | Corpus tags per slug | PASS — `spawn-unique-naming` CLAUDE 2 (1 tag L376 + 1 Bullet-B cross-ref L453, design-intended) / AGENTS 1 / GEMINI 1; `reconciliation-instance-independence` 1/1/1; `spawn-registry-find` CLAUDE 1 / AGENTS 0 / GEMINI 0 (Claude-only) |
| 3 | Trinity shared-body parity | PASS — "uniqueness is a DISCIPLINE…" 1/1/1; "NEVER the original author" 1/1/1; "ONE exception: `docs-researcher`" 1/1/1 (design-verbatim literal) |
| 4 | Bullet B load-bearing clause | PASS — "Consult the registry ONLY after the `fresh-agent-default` gate authorizes a re-engage" present (across line-wrap, newline-collapse confirmed) |
| 5 | STRIP grep-ZERO S1/S2 | PASS — S1 "have no peer-messaging equivalent — confirmed" = 0; S2 "No SendMessage equivalent (confirmed absent per issue #12462)" = 0; corrected text present (CLAUDE "now ship peer-messaging ANALOGS" = 2 [S1+S4]; RATIONALE "MAv2 `send_message` analog exists" = 1) |
| 6 | KEEP surfaces present | PASS — "if your CLI offers no peer-messaging, re-spawn a fresh" = 1; "no equivalent per-project memory" = 1; "their worktree story is" = 1/1 (project-template + pack-ops OPTIONAL-FEATURES) |
| 7 | S4 STRIPPED grep-ZERO + preserved/corrected legs | PASS — "none of which have equivalents" = 0; "per research §2.5 / §2.7 / §3.5 / §3.7" = 0; "This sub-section is Claude-specific" = 1 (exemption opener preserved); "built against Claude Code's Agent-tool mechanism" present (across wrap) |
| 8 | No project-trinity MECHANISM leak | PASS — `pack-spawn-registry\|name→agentId` = 0/0/0 in project trinity |
| 9 | No `.gitignore` edit; OPTIONAL-FEATURES/backlog not in diff | PASS — `.gitignore` not in `git diff --name-only`; OPTIONAL-FEATURES + `backlog/` absent from diff |
| 10 | validate-pack green | PASS (see below) |
| 11 | Base-predecessor (BD-240 content marker) | PASS — "DISCOVERY / RECALL" present in CLAUDE/AGENTS/GEMINI at base (post-BD-240 confirmed) |

### Full `python3 scripts/validate-pack.py`
- **Exit 0 — `PASSED — all checks clean`** (all 62+ checks).
- **Check 45 (rule↔rationale bijection):** `26 corpus … 26 rationale … sets are equal (bijection holds, no orphans)`. Baseline 23↔23 + 3 (Bullets A/B/C with R1/R2/R3) = 26↔26 — exactly the +3/+3 target. The 4 STRIPs (S1/S2/S3/S4) contribute 0 slugs (untagged prose).
- **Check 46 (manifest + anti-restate):** `spawn manifest: 7 rule(s)` (unchanged — no manifest record added); `anti-restate: 0 verbatim imperative-body restatements across 6 spawn-relevant surface(s) (52 candidate bodies scanned)`. Candidate count rose 49→52 (the 3 new bullet bodies) with 0 restate hits.
- **Check 18 (trinity H2 parity):** GREEN both `[pack-root]` AND `[project-template]` — Bullets A/C ×3 + CPR1 ×3 landed inside EXISTING H3/H2 (no new heading); Bullet B Claude-only single-surface (no parity break).
- **Check 36 (commit-scope) — verified at commit time by the orchestrator via the 2-commit split.** Cannot fully test locally (commit-diff-based), but CONFIRMED: Commit-1 file set = `{CLAUDE.md, AGENTS.md, GEMINI.md, pack-ops/PACK-MEMORY-RATIONALE.md}` (ONLY pack-ops paths — `pack-only`-keyword VALID); Commit-2 file set = `{supporting-docs/METHODOLOGY.md, project-template/CLAUDE.md, project-template/AGENTS.md, project-template/GEMINI.md, project-template/docs/pack/PM-CHAT.md}` (carries METHODOLOGY + project files → NO scope keyword, Check 36 skipped).
- **Check 62/63 (manifest/graphify-out):** GREEN — manifest structurally well-formed (NOT regenerated — push-time concern; S3+PR/CPR are fixture inputs, flag for the orchestrator's push step per `manifest-regen` memory); `graphify-out/` not tracked.

### enumerate-encoding-surfaces check
No validator or test file ENCODES the edited rule-state requiring a lock-step update beyond what validate-pack already covers. The 3 new rules engage Check 45 (bijection) + Check 46 (anti-restate candidate scan) + Check 18 (parity) automatically; there is NO new committed-tree state for a dedicated validator (the registry is gitignored runtime state; spawn-naming/reconciliation are runtime decisions — `ci-guard-measure-then-bound` empty matching set → no new check, per plan §12.1). The full suite re-ran GREEN, confirming no asymmetric-coverage gap.

## Commit-grouping instruction for the orchestrator (after review-clean)
The 9 changed files split into two commits per the plan's RECOMMENDED 2-commit split:
- **Commit 1 (`pack-only` keyword VALID):** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `pack-ops/PACK-MEMORY-RATIONALE.md`. Carries all 3 corpus slugs + 3 rationale sections (Check 45 26↔26 holds here) + S1/S2/S4. NO product path.
- **Commit 2 (NO scope keyword — `project-only` does NOT fit because S3 is `supporting-docs/`, not `project-template/`):** `supporting-docs/METHODOLOGY.md`, `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/docs/pack/PM-CHAT.md`. Check 18 project-template parity holds here.
- **Push-time (Check 62):** S3 + PR1/PR2/CPR2 (PM-CHAT) + CPR1 (project trinity) are fixture INPUTS — `scripts/manifest-sync.sh` regenerates at PUSH (expect exit 10 → commit regenerated `test-fixtures/manifest.txt` with user approval). NOT regenerated here.

## Definition-of-Done checklist
| Item | Status |
|---|---|
| Bullet A `spawn-unique-naming` ×3 trinity, audience-correct, tagged | PASS |
| Bullet C `reconciliation-instance-independence` ×3 trinity, audience-correct, load-bearing clauses verbatim, tagged | PASS |
| Bullet B `spawn-registry-find` CLAUDE-only, load-bearing clause verbatim, tagged | PASS |
| R1/R2/R3 bare-slug rationale sections, content-anchored placement (off BD-240 tail) | PASS |
| S1 + S4 (CLAUDE stale ×2, same cluster) corrected | PASS |
| S2 (RATIONALE Codex line) corrected, Antigravity line untouched | PASS |
| S3 (METHODOLOGY SHIPPED stale, client-audience) corrected, blockquote markers preserved, routing sentence kept | PASS |
| CPR1a/b/c project trinity recon bullet ×3, project-audience, audience-correct re-engage clause | PASS |
| PR1 + PR2 + CPR2 (PM-CHAT) added, modeled on existing prose/blockquote precedents | PASS |
| 4-STRIP grep-ZERO gates | PASS |
| 5-KEEP surfaces untouched (real lowercase casing) | PASS |
| No project-trinity MECHANISM leak | PASS |
| No `.gitignore` edit; registry leaf gitignore-covered | PASS |
| validate-pack exit 0 (Check 45 26↔26, Check 46 0-restate, Check 18 parity ×2) | PASS |
| 2-commit split file sets clean (Check 36 readiness) | PASS |
| Out-of-scope surfaces (memory, BD-217, backlog/changelog/manifest, .gitignore) untouched | PASS |
| No state-changing git verb; no patch produced | PASS |
| BD-240 base content untouched | PASS |

## Rules-Applied Verification Block
| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git run: `git rev-parse HEAD` (797b4c5, unchanged base==final), `git rev-parse --abbrev-ref HEAD`, `git status --short`, `git diff --name-only`. ZERO state-changing verbs; NO patch produced; edits left in the worktree. | COMPLIANT |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line ONLY after ALL in-scope edits (15 edits across 9 files) + ALL verification (PLAN §12.2 gates 1-11 + `validate-pack.py` exit 0) PASSED. No stop/halt message received. | COMPLIANT |
| edit-in-place-not-full-rewrite | All 15 edits are targeted in-place `Edit` calls anchored on quoted content (section names + quoted strings), never full-file rewrites; section maps re-confirmed via grep after each (gates 1-9). | COMPLIANT |
| cross-cli-reference-normalization | Audience-correct substitution measured: Bullet A name-field CLAUDE "Agent-tool `name` parameter" (1) / AGENTS "In Codex the `name` is the agent `name` field" (present) / GEMINI "On Antigravity address by the known agent ID" (present); Bullet C + CPR1 carve-out (1) re-engage path differs per CLI (Claude SendMessage / Codex resume_agent / Antigravity known-ID rewake — each present); S3 strips pack-internal jargon for client audience. Shared bodies byte-identical (gate 3 = 1/1/1). NOT byte-copy. | COMPLIANT |
| separate-pack-ops-from-product | Commit-1 file set = 4 pack-ops files ONLY (no `project-template/`/`supporting-docs/` — `git diff --name-only` confirms); Commit-2 = METHODOLOGY (shipped) + 4 project deliverables. S4 verified pack-ops (CLAUDE.md) → rides Commit-1. | COMPLIANT |
| enumerate-encoding-surfaces | No validator/test ENCODES the edited rule-state needing lock-step update beyond Checks 18/45/46 (already auto-engaged); registry = gitignored runtime, naming/reconciliation = runtime decisions → no new committed-tree state (`ci-guard-measure-then-bound` empty set). Full suite re-ran GREEN (no asymmetric-coverage gap). | COMPLIANT |
| graph-first-context | Used the INJECTED graph path verbatim — `graphify query "agent invocation rules sub-agent behavior reconciliation registry spawn naming KEEP surfaces" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` was the design's established G2 result for this rule-corpus concept (fixture/provenance nodes only) per all 4 prior passes; per G2 I drove discovery via grep/Read against the worktree (gates 1-9). NEVER recomputed from the worktree toplevel. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT terminal; no empty-evidence rows. | COMPLIANT |

---

*End IMPL-REPORT-BD-241-coder. Read-write pack-coder; isolated worktree; no commit, no patch produced. 9 files edited (15 edits) across the 2-commit split; all PREFLIGHT gates + validate-pack (exit 0; Check 45 26↔26, Check 46 0-restate, Check 18 parity ×2) PASS. The patch is produced only after a reviewer confirms clean and the orchestrator re-engages this coder for the read-only `git diff` patch-emit.*
