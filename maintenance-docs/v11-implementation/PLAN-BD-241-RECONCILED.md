# PLAN-BD-241-RECONCILED — Coder-ready implementation plan: discoverable spawned agents (unique NAMES + Claude REGISTRY + name→agentId find) + reconciliation-instance independence + stale cross-CLI claim correction

**Agent:** pack-planner (READ-ONLY, FRESH/INDEPENDENT — RECONCILIATION pass; neither the
original planner nor the adversarial planner) · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`).
**Supersedes:** `/tmp/pack-handoff-bd241-plan/PLAN-BD-241.md` (the original plan).
**Reconciliation inputs (read in full):**
1. `/tmp/pack-handoff-bd241-plan/PLAN-BD-241.md` — the original plan.
2. `/tmp/pack-handoff-bd241-plan/ADVERSARIAL-PLAN-REVIEW-BD-241.md` — the adversarial review
   (0 BLOCKER / 2 MAJOR / 4 MINOR; verdict NEEDS-REWORK; rebase-on-BD-240 ROBUST).
3. The settled design — THREE docs: `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-RECONCILED.md`
   + `DESIGN-BD-241-D3-ADDENDUM.md` (Bullet C) + `DESIGN-BD-241-L418-CORRECTION.md` (S4 = the
   4th STRIP, CLAUDE.md L418-422, joins Commit 1).

**This plan does NO redesign.** It (a) applies all adversarial findings (triaged FIX-all),
(b) independently re-challenges the whole plan with fresh eyes, and (c) keeps the verified-clean
architecture intact. Every surface carries a CONTENT-ANCHOR (a grep-able literal at the REAL
tree casing), not a bare line number — line numbers drift (`measure-then-bound` /
`rename-plans-measure-then-bound`).

> **Method note (graph-first, G2 fallback).** I queried the injected graph
> (`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json`,
> `--backend claude-cli --budget 1500`) FIRST for the invocation-rule / sub-agent-behavior /
> peer-messaging / reconciliation / KEEP-surface concepts; it returned only fixture +
> provenance nodes (the rule-corpus concept is not a graph node — the same G2 result all four
> prior passes hit). Per G2 I re-measured EVERY load-bearing surface — especially the F-1
> KEEP-surface live casing and the F-6 S4 grep patterns — with grep/Read against HEAD
> `af73ffb`. Proof in §13. This is a rule-corpus + prose-correction BD; grep/Read is the
> correct primary tool.

---

## 0. Reconciliation summary — what this pass changed vs the original plan

| Finding | Severity | Disposition | Where applied in THIS plan |
|---|---|---|---|
| **F-6** (S4 self-contradiction: §2.6/§12.2-gate-#7/§14-risk-#1 say "leave untouched/OPEN ITEM" while §2.1/§4.3 say "strip") | MAJOR | **APPLIED** — the whole plan now treats S4 as an INCLUDED strip in Commit 1; every "leave untouched / open-item" remnant removed; gate #7 flipped to grep-ZERO | §2.1 (S4 row), §2.6 (rewritten = RESOLVED), §4.3 (S4 spec), §12.2 gate #7, §14 risk #1 |
| **F-1** (§12.2 gate #6 KEEP-surface grep literals use ALL-CAPS emphasis casing — false-FAIL on the real lowercase tree) | MAJOR | **APPLIED + STRENGTHENED** — corrected to the measured live casing; AND fixed a deeper miscount/line-wrap defect the adversarial fix would itself have false-failed on (see §0.1 NEW gap) | §12.2 gate #6, §2.5, §13 claim #10 |
| **F-2** (§2.5 + §13-claim-#10 KEEP quotes mis-cased, compounding F-1) | MINOR | **APPLIED** — quotes normalized to measured lowercase + flagged "gist where not a literal gate" | §2.5, §13 claim #10 |
| **F-3** (R1/R2/R3 have no specified insertion point → avoidable EOF adjacency to BD-240's edited tail section) | MINOR | **APPLIED** — content-anchored insertion directive added (after `## pack-chat-minor-edits-only`, before `## graph-first-context`) | §2.1 (R1/R2/R3 rows), §3 (placement directive) |
| **F-4** (§12.2 gate #6 final `git diff` parenthetical asks the coder to assert never-touched files) | MINOR | **APPLIED** — parenthetical tightened to PM-CHAT ADD-only + the two never-touched files | §12.2 gate #6 final clause |
| **F-5** (no PREFLIGHT base-predecessor assertion that BD-240 actually LANDED) | MINOR | **APPLIED + CORRECTED** — added a CONTENT-marker base assertion (not the adversarial's `git log \| grep BD-240`, which FALSE-PASSES at af73ffb — see §0.1) | §12.2 gate #11, §14 risk #3 |

### 0.1 NEW gaps I found independently (both prior planners AND the adversarial missed them)

- **NEW-1 (folds into F-1, MAJOR-adjacent) — the adversarial's own recommended F-1 fix is
  STILL WRONG for two of the three KEEP literals.** Re-measured at af73ffb:
  - `worktree story is tracked` appears **TWICE** in `project-template/docs/pack/OPTIONAL-FEATURES.md`
    (L99 AND L283), not once — so the adversarial's recommended `grep -c "worktree story is
    tracked" … → 1/1` would read 2 and FALSE-FAIL.
  - `worktree story is tracked` appears **0 times** in `pack-ops/OPTIONAL-FEATURES.md` — the
    string is LINE-WRAPPED there (`…their worktree story is` / `tracked under BD-217…`), so even
    the lowercase literal returns 0 in that file. The adversarial's `→ 1/1` is impossible.
  The robust both-files literal is **`their worktree story is`** → `1/1` (present once per file,
  survives the line-wrap, and excludes the L99 duplicate). This plan uses that literal. Evidence
  in §13 claim #10a/#10b.
- **NEW-2 (folds into F-5) — the adversarial's `git log -5 \| grep -i BD-240` base-predecessor
  assertion FALSE-PASSES at the current HEAD.** Measured: `git log --oneline -8 \| grep -i
  BD-240` already returns the af73ffb commit (`open BD-240 …`) — the *opening* commit — even
  though BD-240's rule re-frame has NOT landed (`backlog/BD-240.md` Status: Open). A log-grep on
  the BD number cannot distinguish "BD-240 opened" from "BD-240 work landed." The correct
  predecessor assertion is a CONTENT marker for BD-240's actual landed change (the re-framed
  `graph-first-context` rule text), not a commit-message grep. §12.2 gate #11 uses a content
  marker.
- **NEW-3 (folds into F-6 preserved-leg gate) — the adversarial's F-6 preserved-leg gate
  `grep -c "run_in_background" CLAUDE.md → ≥1` is non-specific.** Measured: `run_in_background`
  appears 3× in CLAUDE.md, so that gate stays ≥1 even if S4's mention were deleted (false-PASS).
  The precise S4-scoped preserved-leg presence gate is `This sub-section is Claude-specific` → 1
  (unique to S4's opener). §12.2 gate #7 uses that.

**What I KEPT INTACT (adversarial-confirmed, not re-opened):** the 2-commit split; rebase-on-BD-240
ROBUSTness (disjoint regions, content-anchored); Check 45 26↔26 bijection; the 3-rule (A/B/C) +
4-STRIP (S1/S2/S3/S4) + project (PR1/PR2/CPR1×3/CPR2) + out-of-repo memory (M1-M4) +
BD-217-note surface set; Check 36 commit framing; Check 46 anti-restate clearance.

### 0.2 Push-back register (evidence-backed)
I push back on NOTHING in the adversarial review — all six findings re-measured as valid (F-1
and F-5 needed STRENGTHENING per §0.1, not rejection). The fix recipes are corrected where the
adversarial's own recipe would have re-introduced a false-fail/false-pass (NEW-1, NEW-2, NEW-3).

---

## 1. Goal + BD scope addressed

**Goal.** Make a still-alive previously-spawned agent reliably re-findable WITHOUT transcript
archaeology, codify when a reconciliation pass must use a fresh instance, and correct the stale
"peer-messaging confirmed-absent" cross-CLI claim wherever it lives (one copy SHIPS to clients)
— by adding 3 new corpus rules (A/B/C), correcting 4 stale clauses (S1/S2/S3/S4), wiring the
Claude-only spawn registry (documentation only), and propagating to the project side.

**BD-241 acceptance criteria → plan coverage (every AC item addressed):**

| BD-241 AC clause | Addressed by |
|---|---|
| orchestrator re-finds a still-alive spawn by NAME (registry-backed) | Bullet B `spawn-registry-find` (§3.2) + registry doc (§5) |
| documented fallback precedence name → agentId → other (NO message-id — no primitive) | Bullet B precedence clause (§3.2); message-id tier DROPPED per the design |
| all spawns uniquely named going forward | Bullet A `spawn-unique-naming` ×3 (§3.1) |
| durable registry consulted (no archaeology) | §5 registry doc (gitignored JSONL) |
| Claude-only mechanism documented pack + project; unique-naming wherever agents spawn | Bullet A ×3 (cross-CLI) + Bullet B (Claude-only) pack; PR1/PR2 project (§7) |
| Codex/Antigravity applicability determined (likely BD-217) | BD-217 scope-note (§6); the 4 STRIPs correct the stale "confirmed-absent" premise |
| reconciled with `reference_sendmessage_uuid_addressing` (refined) + `feedback_fresh_agent_default_no_sendmessage` (unchanged) | §8 memory edits; fresh-agent-default left UNCHANGED |
| validate-pack green (bijection / anti-restate / parity / manifest) | §10 + §12 (Checks 18/45/46/62/36) |

**Plus (D3 addendum) Bullet C `reconciliation-instance-independence`** — a reconciliation pass
uses a FRESH instance (never the author, never the adversarial reviewer), all roles EXCEPT
`docs-researcher`, carve-outs = user-override / architect-challenge. Codified on BD-241 surfaces
(trinity ×3 + rationale + project trinity ×3 + PM-CHAT). The BD-238/239 pipeline-structure facet
is a cross-reference HANDOFF (§9), not authored here.

**Plus (L418-CORRECTION) S4** — CLAUDE.md L418-422 standalone `**Trinity exemption.**` bullet is
the 4th STRIP (PARTIAL correction: fix the stale peer-messaging leg; preserve the
Agent-tool/`run_in_background` leg + the exemption opener). Joins Commit 1.

**Out of scope (settled — do NOT do):** any `.spawn-rule-manifest.txt` record (greenfield
rules; Check 45 bijection gives teeth); any new validator/CI check (no scannable committed-tree
state — `ci-guard-measure-then-bound` empty matching set); the cross-CLI registry MECHANISM
(v11.1, BD-217 handoff); editing the 5 KEEP census surfaces.

---

## 2. Complete affected-surface inventory (content-anchored, real casing)

All anchors below are grep-confirmed at HEAD `af73ffb` (commands + verbatim hits in §13).
Line numbers are CONTEXT ONLY — the coder finds each edit by its content-anchor literal.

### 2.1 Pack-side tree files
| ID | File | Anchor (grep literal) | Edit kind |
|---|---|---|---|
| A1 | `CLAUDE.md` | H3 `### Agent invocation rules` (ctx L242) | ADD Bullet A |
| A2 | `AGENTS.md` | H3 `### Agent invocation rules` (ctx L244) | ADD Bullet A (audience-correct) |
| A3 | `GEMINI.md` | H3 `### Agent invocation rules` (ctx L211) | ADD Bullet A (audience-correct) |
| B1 | `CLAUDE.md` | H3 `### Sub-agent behavior (Claude-only)` (ctx L348); insert AFTER bullet `**Agent-team stage lifecycle + per-commit fresh-coder.**` (ctx L402) and BEFORE bullet `**Trinity exemption.**` (ctx L418) | ADD Bullet B (CLAUDE.md ONLY) |
| C1 | `CLAUDE.md` | H3 `### Agent invocation rules`; insert AFTER bullet `**No prior reviews to pack-reviewer.**` (ctx L269) | ADD Bullet C |
| C2 | `AGENTS.md` | same H3; AFTER `**No prior reviews to pack-reviewer.**` (ctx L259) | ADD Bullet C (audience-correct) |
| C3 | `GEMINI.md` | same H3; AFTER `**No prior reviews to pack-reviewer.**` (ctx L233) | ADD Bullet C (audience-correct) |
| R1 | `pack-ops/PACK-MEMORY-RATIONALE.md` | NEW bare-slug heading `## spawn-unique-naming`; insert AFTER `## pack-chat-minor-edits-only` (ctx L600) and BEFORE `## graph-first-context` (ctx L638) — NOT at EOF (keeps R1/R2/R3 off BD-240's edited tail section; F-3) | ADD rationale section |
| R2 | `pack-ops/PACK-MEMORY-RATIONALE.md` | NEW bare-slug heading `## spawn-registry-find`; same insertion block as R1 (after `## pack-chat-minor-edits-only`, before `## graph-first-context`) | ADD rationale section |
| R3 | `pack-ops/PACK-MEMORY-RATIONALE.md` | NEW bare-slug heading `## reconciliation-instance-independence`; same insertion block as R1/R2 | ADD rationale section |
| S1 | `CLAUDE.md` | clause `(Codex / Antigravity have no peer-messaging equivalent — confirmed absent per Codex issue #12462 and Antigravity's hub-and-spoke subagent model)` inside the `**Agent-team stage lifecycle...**` bullet's `Trinity exemption:` tail (ctx L415-417) | STRIP/REPLACE |
| S2 | `pack-ops/PACK-MEMORY-RATIONALE.md` | line `- Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462).` (ctx L193) | STRIP/REPLACE (Codex line only) |
| S3 | `supporting-docs/METHODOLOGY.md` | from `This convention is Claude-Code-specific:` through `...peer-messaging across multiple parent turns).` (ctx L94-100) — SHIPPED | STRIP/REPLACE (client-audience) |
| **S4** | `CLAUDE.md` | standalone bullet `- **Trinity exemption.** This sub-section is Claude-specific (not mirrored in \`AGENTS.md\` / \`GEMINI.md\`)` … `none of which have equivalents … per research §2.5 / §2.7 / §3.5 / §3.7.` (ctx L418-422), at the END of `### Sub-agent behavior (Claude-only)` | STRIP/REPLACE (PARTIAL — §4.3 text; fix peer-messaging leg, PRESERVE Agent-tool/`run_in_background` leg + exemption opener) |

### 2.2 Project-side tree files (product deliverables)
| ID | File | Anchor (grep literal) | Edit kind |
|---|---|---|---|
| PR1 | `project-template/docs/pack/PM-CHAT.md` | H3 `### In-session agent spawning` (ctx L454); model on the existing `**Spawn in the background.**` CLI-agnostic prose (ctx L506) | ADD naming-discipline prose (CLI-agnostic) |
| PR2 | `project-template/docs/pack/PM-CHAT.md` | near the merge-back re-engage `re-spawn a fresh \`coder\`` (ctx L539/L591); model on the existing `> **Per-project Claude memory cache (Claude-only).**` blockquote (ctx L897) | ADD Claude-only registry+precedence blockquote |
| CPR1a | `project-template/CLAUDE.md` | H2 `## Project memory` (ctx L349) | ADD Bullet C (project-audience) |
| CPR1b | `project-template/AGENTS.md` | H2 `## Project memory` (ctx L326) | ADD Bullet C (project-audience, audience-correct) |
| CPR1c | `project-template/GEMINI.md` | H2 `## Project memory` (ctx L346) | ADD Bullet C (project-audience, audience-correct) |
| CPR2 | `project-template/docs/pack/PM-CHAT.md` | spawn section `### In-session agent spawning` (ctx L454) / near merge-back (ctx L533-541) | ADD reconciliation-independence prose (CLI-agnostic) |

### 2.3 Out-of-repo memory files (Pack-Chat upkeep — NOT tree files; flag for Pack Chat)
| ID | File | Edit |
|---|---|---|
| M1 | `…/memory/reference_sendmessage_uuid_addressing.md` | REFINE: registry-backed; precedence name→agentId; NO message-id; cite the two in-repo slugs |
| M2 | `…/memory/MEMORY.md` (index) | UPDATE the SendMessage-UUID pointer to mention the registry; ADD a `reconciliation-instance-independence` pointer line |
| M3 | `…/memory/feedback_fresh_agent_default_no_sendmessage.md` | REFINE: cross-ref C (reconciliation-pass case codified; carve-outs; docs-researcher exempt) |
| M4 (optional) | `…/memory/feedback_adversarial_planner_review_major_plans.md` | OPTIONAL one-line cross-ref: the two-sense "reconcile" (lightweight Pack-Chat merge vs substantive fresh-instance) — §8.4 |

### 2.4 Governance (pack-chat-only — flag for Pack Chat to apply; NOT a coder edit)
| ID | File | Edit |
|---|---|---|
| G1 | `backlog/BD-217.md` | one-line scope-NOTE (BD-217 also owns the cross-CLI discovery analog; corrected premise) — §6 |
| G2 (recommended) | `pack-ops/PACK-CHAT.md` | step-1 Claude-only ×3-exempt carve-out note — §3.2.1 |

### 2.5 KEEP — measured-correct, NO EDIT (real casing; these are NOT stale peer-messaging claims)
Quotes here are the MEASURED LIVE strings (lowercase), not emphasis prose — they double as the
§12.2 gate #6 literals. Where a quote is a gist (not the exact gate literal) it is marked.
- `project-template/docs/pack/PM-CHAT.md` `if your CLI offers no peer-messaging, re-spawn a fresh \`coder\`` (ctx L539) — **conditional guard** (degradation logic, not a capability claim). Gate literal `if your CLI offers no peer-messaging, re-spawn a fresh` → 1.
- `project-template/docs/pack/PM-CHAT.md` `no equivalent per-project memory` (ctx L907, lowercase `memory`) — **different capability** (per-project memory). Gate literal `no equivalent per-project memory` → 1.
- `project-template/docs/pack/OPTIONAL-FEATURES.md` `their worktree story is` (ctx L283, lowercase `worktree`; the gist `worktree story is tracked separately` also appears at L99 — so the gate uses the precise `their worktree story is` literal) — **worktree, not peer-messaging**.
- `pack-ops/OPTIONAL-FEATURES.md` `their worktree story is` (ctx L284, lowercase `worktree`; LINE-WRAPPED as `their worktree story is` / `tracked under BD-217`) — **worktree**. Gate literal `their worktree story is` (NOT `worktree story is tracked`, which is 0 here due to the wrap).
- `backlog/BD-241.md` provenance lines — **pack-chat-only entry provenance**, not a rule surface (not in the coder's edit set, not in `git diff`).

### 2.6 S4 — RESOLVED (was an OPEN ITEM in the original plan; now an INCLUDED strip in Commit 1)
The original plan §2.6 framed CLAUDE.md L418-422 as an OPEN ITEM the coder must "leave
UNTOUCHED … surface in the IMPL-REPORT." **That is RESOLVED.** Per
`DESIGN-BD-241-L418-CORRECTION.md` the user DECIDED (2026-06-20) to INCLUDE L418-422 as the 4th
STRIP, **S4**, in Commit 1. The settled STRIP set is therefore {S1, S2, S3, **S4**}.
- **S4 is a PARTIAL correction** (the user's nuance): the L418-422 bullet bundles three legs —
  (1) the Agent-tool specificity, (2) the `run_in_background` named parameter, (3) the
  Agent-Teams/SendMessage peer-messaging "none of which have equivalents" assertion. Leg (3) is
  now STALE (Codex MAv2 + Antigravity `agy` ship analogs). Legs (1)+(2) + the exemption opener
  remain TRUE and are PRESERVED. The coder applies the §4.3 replacement text.
- **S4 joins Commit 1** (CLAUDE.md is pack-ops; `pack-only`-clean) alongside S1 — both are
  stale-claim corrections in the SAME `### Sub-agent behavior (Claude-only)` bullet-cluster, so
  they land atomically (no transient inconsistency where one note says "confirmed absent" and
  the adjacent says "analogs exist").
- **S4 has ZERO Check-45 impact** (untagged prose — no `[rationale:]` / `[roles:]` tag;
  measured §13 claim #11). The bijection delta stays +3 (Bullets A/B/C only).
- **The coder STRIPS S4** (does NOT leave it untouched; does NOT merely surface it). The §12.2
  gate #7 is a grep-ZERO completeness gate proving the stale phrasing is GONE.


---

## 3. The 3 new corpus rules — exact drop-in text + rationale sections

Each rule = (a) a tagged bullet in the corpus + (b) a bare-slug `## <slug>` rationale section
in `PACK-MEMORY-RATIONALE.md`, landed in the SAME commit (Check 45 bijection). The
`[rationale: <slug>]` tag is what engages Check 45 — NOT the role tag. All three use
`[roles: universal]` (verified an in-use vocab form, §13). Rationale headings are BARE SLUG
(regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`, verified) — lowercase kebab, nothing after the slug.

**Rationale-section placement (F-3 — content-anchored, NOT EOF).** Insert R1, R2, R3 as a block
IMMEDIATELY AFTER the existing `## pack-chat-minor-edits-only` section (RATIONALE.md, anchor
`## pack-chat-minor-edits-only`, ctx L600) and BEFORE `## graph-first-context` (ctx L638, the
LAST section / EOF region BD-240 re-frames). Do NOT append at EOF — that would abut BD-240's
edited tail section and create an avoidable rebase adjacency. This block also sits clear of S2's
region (`## preflight-stop-means-stop`, ctx L138). Order within the block: R1 (`spawn-unique-naming`),
R2 (`spawn-registry-find`), R3 (`reconciliation-instance-independence`).

### 3.1 Bullet A — `spawn-unique-naming` (trinity ×3, `### Agent invocation rules`)

**Surfaces A1/A2/A3.** Insert as a NEW bullet in `### Agent invocation rules` in all three
trinity files. CLAUDE.md form (verbatim from RECONCILED §3.1 — keep load-bearing clauses):

```
- **Uniquely + descriptively name every spawn.** Every spawned agent carries a
  unique, descriptive `name` of the shape `<role>-<bd>-<facet>[-<seq>]` (lowercase
  kebab, `^[a-z0-9][a-z0-9-]{2,47}$`): `<role>` the agent role token
  (`coder`/`fixcoder`/`reviewer`/`architect`/`planner`/`docsresearcher` — the
  `subagent_type` minus the `pack-` prefix); `<bd>` the work anchor (`bdNNN` or
  `batchNN`); `<facet>` a short scope tag (`cdocs`/`worktree`/`external`); append
  `-2`/`-3`… to keep a repeated `<role>-<bd>-<facet>` triple unique within a live
  cycle (uniqueness is a DISCIPLINE — no platform guarantees it). In Claude Code the
  `name` is the Agent-tool `name` parameter (addressable via `SendMessage({to:
  name})`); on Codex / Antigravity use the platform's agent-name field. A
  unique name is the key the discovery mechanism records and re-finds by. `[roles:
  universal] [rationale: spawn-unique-naming]`
```

**Audience-correct substitution (`cross-cli-reference-normalization` — NOT a byte-copy).** The
regex, the `<role>-<bd>-<facet>[-<seq>]` triple shape, and the discipline-not-guarantee clause
are IDENTICAL across all three; ONLY the per-CLI name-field sentence differs:
- **AGENTS.md (Codex audience):** replace the "In Claude Code the `name` is…" sentence with
  *"In Codex the `name` is the agent `name` field (the `nickname` is display-only)."*
- **GEMINI.md (Antigravity audience):** replace it with *"On Antigravity address by the known
  agent ID / named-role type."*

**Rationale R1 — new `## spawn-unique-naming`.** Body shape Why/How/Rejected:
- **Why:** re-finding a still-alive spawn (the BD-206 docs-researcher case) required digging the
  `agentId` out of session JSONL; a unique descriptive name is the stable key the registry
  records + re-finds by. Cross-CLI because all platforms spawn named agents.
- **How:** the `<role>-<bd>-<facet>[-<seq>]` shape + the `-seq` uniquifier within a live cycle.
- **Rejected:** free-form / non-descriptive names; UUID-suffixed names (defeats human re-find).

### 3.2 Bullet B — `spawn-registry-find` (Claude-only, `### Sub-agent behavior (Claude-only)`)

**Surface B1 (CLAUDE.md ONLY).** Insert as a NEW bullet in `### Sub-agent behavior
(Claude-only)`, AFTER the `**Agent-team stage lifecycle + per-commit fresh-coder.**` bullet and
BEFORE the `**Trinity exemption.**` bullet (the S4 bullet — which is also edited; insert Bullet B
above it). Verbatim from RECONCILED §3.2:

```
- **Record every spawn in the durable registry; re-find by name→agentId
  (Claude-only mechanism).** The orchestrator records each Agent-tool spawn — its
  unique `name` (see `### Agent invocation rules` `[rationale: spawn-unique-naming]`),
  `agentId` (from the spawn tool_result), `purpose`, `status` — into the gitignored
  per-clone ledger `graphify-out/.pack-spawn-registry.jsonl` (NEVER committed —
  `agents-never-commit`; modeled on `graphify-out/.pack-refresh-status`) and CONSULTS
  it to re-find a still-alive spawn with NO transcript archaeology (the registry is
  re-read from disk, so it survives a parent context compaction). Lookup precedence:
  **by NAME → by agentId** (both work as `SendMessage.to`, measured; there is NO
  message-id addressing primitive — do not invent one; terminal fallback is a fresh
  re-spawn). Consult the registry ONLY after the `fresh-agent-default` gate authorizes
  a re-engage — this fixes HOW-to-find, not WHEN-to-reengage. The find/registry
  MECHANISM is Claude-only here; Codex MAv2 (`list_agents`/`resume_agent`) and
  Antigravity `agy` analogs exist but need their own verification + mapping (BD-217).
  `[roles: universal] [rationale: spawn-registry-find]`
```

**LOAD-BEARING — keep VERBATIM (do NOT trim):** *"Consult the registry ONLY after the
`fresh-agent-default` gate authorizes a re-engage."* Without it the registry reads as a new
authority to reuse agents, defeating `fresh-agent-default`.

**Rationale R2 — new `## spawn-registry-find`.** Why/How/Rejected:
- **Why:** a durable on-disk registry survives parent context compaction → no archaeology.
- **How:** gitignored JSONL `{name, agentId, purpose, status}`; precedence name→agentId; consult
  ONLY after the `fresh-agent-default` gate.
- **Rejected:** a committed manifest (`agents-never-commit` forbids a mid-task commit); the
  Agent-Teams `members` list (teams-only, not durable); a message-id tier (no such primitive).
  Claude-only — Codex/Antigravity = BD-217.

#### 3.2.1 G2 (recommended, pack-chat-only) — PACK-CHAT.md step-1 carve-out note
Bullet B is the FIRST formally-tagged Claude-only corpus rule. The propagation step-1 row
(`pack-ops/PACK-CHAT.md`, anchor `Corpus imperative line ×3 trinity`) says "×3 trinity" with no
"unless Claude-only" clause. RECOMMEND Pack Chat add a one-line note to that step-1 row: *"(a
Claude-only sub-section rule is single-surface — no ×3 mirror; see the existing `### Sub-agent
behavior (Claude-only)` precedent.)"* This is pack-chat-only (PACK-CHAT.md); Pack Chat applies
directly. Bullet A and Bullet C are unaffected (both ARE ×3). [Optional — surface at the gate.]

### 3.3 Bullet C — `reconciliation-instance-independence` (trinity ×3, `### Agent invocation rules`)

**Surfaces C1/C2/C3.** Insert as a NEW bullet in `### Agent invocation rules` in all three
trinity files, AFTER the `**No prior reviews to pack-reviewer.**` bullet (its nearest
independence-family sibling). CLAUDE.md form (verbatim from D3-ADDENDUM §1.2):

```
- **Reconciliation-instance independence.** A reconciliation pass (the round that
  resolves an adversarial review's findings before the work advances) uses a FRESH,
  independent instance — NEVER the original author (contaminated + design-biased toward
  its own design) NOR the adversarial reviewer (biased toward its own findings). This
  applies to EVERY agent role — architect, planner, coder, reviewer, auditor, repo-ops,
  tester, grpc-schema, and any other — with ONE exception: `docs-researcher`, which MAY
  be re-engaged/reused (its work is factual inventory, accumulated context helps, and it
  carries no design bias). Two carve-outs override the fresh-instance default: (1) **user
  override** — the user EXPLICITLY asks to re-engage an existing agent (in Claude Code
  via `SendMessage` to that instance — the BD-241 discoverability mechanism then
  re-finds it; on Codex / Antigravity via the platform's re-engage path); and (2)
  **architect challenge** — a good, evidence- and logic-based reason argued per case (not
  a blanket exemption). This rule REINFORCES `fresh-agent-default` (it is that
  independence principle applied to the reconciliation step) and SUBORDINATES the
  Agent-team "SendMessage for follow-ups" convenience: a reconciliation pass is a fresh
  spawn unless a carve-out fires. `[roles: universal]
  [rationale: reconciliation-instance-independence]`
```

**Audience-correct substitution (`cross-cli-reference-normalization`).** ONLY carve-out (1)'s
per-CLI re-engage reference differs; the rule body, role roster, the docs-researcher exemption,
the architect-challenge carve-out, and the fresh-agent-default reinforcement are IDENTICAL ×3:
- **AGENTS.md (Codex):** carve-out (1) clause → *"in Codex via the platform's agent re-engage /
  `resume_agent` path (where its multi-agent messaging is enabled)"*.
- **GEMINI.md (Antigravity):** carve-out (1) clause → *"on Antigravity via the platform's
  known-ID re-engage / idle-rewake path"*.

**LOAD-BEARING — keep VERBATIM (D3 §1.2):** (1) *"NEVER the original author ... NOR the
adversarial reviewer"*; (2) *"EXCEPT `docs-researcher` ... no design bias"*; (3) *"This rule
REINFORCES `fresh-agent-default`"*. Dropping any re-opens the contamination/compatibility the
rule closes.

**Rationale R3 — new `## reconciliation-instance-independence`.** Why/How/Rejected:
- **Why:** the original author is contaminated/design-biased; the adversarial reviewer is biased
  toward its own findings; a fresh instance reading both as inputs is the only unbiased party —
  same independence rationale as `fresh-agent-default` / "No prior reviews to pack-reviewer" /
  per-commit fresh-coder, applied to the reconciliation step.
- **How:** spawn a NEW instance of the relevant discipline, handed the design + the adversarial
  review as SUBJECTS to reconcile; `docs-researcher` exempt (factual inventory); carve-out (1)
  user override (Claude `SendMessage` via the BD-241 registry; Codex/Antigravity per-platform);
  carve-out (2) architect-challenge per case.
- **Rejected:** (i) reuse the author "for its context" — that context IS the contamination;
  (ii) reuse the adversarial reviewer "for its findings knowledge" — that knowledge IS the bias;
  (iii) a blanket standing "any agent reusable if the user once said so" — carve-out is
  per-instance/explicit; (iv) exempting MORE roles than `docs-researcher` — only factual-
  inventory work qualifies.

### 3.4 Bijection arithmetic (Check 45)
Baseline (measured, §13): **23 corpus ↔ 23 rationale**. This plan adds **+3 corpus slugs**
(`spawn-unique-naming`, `spawn-registry-find`, `reconciliation-instance-independence`) and **+3
rationale sections** (R1/R2/R3) → target **26 ↔ 26**. The 4 STRIPs (S1/S2/S3/S4) are untagged
prose → **+0 slugs** (S4 explicitly: untagged, measured §13 claim #11 → no Check-45 impact). The
corpus scan reads CLAUDE.md's `## Pack memory` section (Bullet B's Claude-only slug IS picked up
— the scan does not stop at the H3); the rationale scan reads PACK-MEMORY-RATIONALE.md. Coder
confirms the LIVE count post-edit (do NOT hard-code 26 — if BD-238/BD-240 land first, the
baseline shifts; the DELTA is +3/+3).

---

## 4. The 4 stale-claim STRIPs — exact replacements (audience-correct, NOT byte-copy)

Per `cross-cli-reference-normalization`, each STRIP gets AUDIENCE-CORRECT wording. The 5 KEEP
surfaces (§2.5) stay untouched. Coder confirms exact sentence boundaries by re-reading the local
context BEFORE editing (line numbers drift).

### 4.1 S1 — `CLAUDE.md` (pack-maintainer audience; inside the Agent-team lifecycle bullet)
**Anchor:** the `Trinity exemption:` tail of the `**Agent-team stage lifecycle + per-commit
fresh-coder.**` bullet — the exact clause `(Codex / Antigravity have no peer-messaging
equivalent — confirmed absent per Codex issue #12462 and Antigravity's hub-and-spoke subagent
model).` **REPLACE that parenthetical with:**
```
(Codex MAv2 `send_message` (flag-gated `multi_agent_v2`; issue #12462
CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing + idle
auto-rewake) now ship peer-messaging ANALOGS — but they are flag-gated /
not-yet-GA-documented (Codex) and partly-unverified (Antigravity), so this
MECHANISM stays Claude-only here; the cross-CLI mapping is BD-217.)
```
Keep the rest of the bullet (the fresh-per-pass clauses + "Agent Teams + SendMessage are
Claude-Code-specific") intact.

### 4.2 S2 — `pack-ops/PACK-MEMORY-RATIONALE.md` (pack rationale doc; STOP-MEANS-STOP, Codex line only)
**Anchor:** the single line `- Codex CLI: No SendMessage equivalent (confirmed absent per issue
#12462).` **REPLACE that line (and keep the following lines) with:**
```
Codex CLI: a MAv2 `send_message` analog exists (issue #12462 CLOSED-COMPLETED
2026-05-02; flag-gated `multi_agent_v2`, not-yet-GA-documented), so the parent stop
mechanism MAY use it where enabled; otherwise `/agent` or natural-language.
Cross-CLI coordination = BD-217.
```
**LEAVE the Antigravity line UNTOUCHED** (the `- Antigravity: parent-control stop is native…`
bullet that follows is already accurate — verified).

### 4.3 S4 — `CLAUDE.md` (pack-maintainer audience; standalone Trinity-exemption bullet, L418-422) — PARTIAL correction
**Anchor:** the standalone bullet `- **Trinity exemption.** This sub-section is Claude-specific
(not mirrored in \`AGENTS.md\` / \`GEMINI.md\`) … none of which have equivalents in Codex CLI or
Antigravity CLI per research §2.5 / §2.7 / §3.5 / §3.7.` at the END of `### Sub-agent behavior
(Claude-only)`. **REPLACE the ENTIRE bullet with (verbatim from L418-CORRECTION §2):**
```
- **Trinity exemption.** This sub-section is Claude-specific (not
  mirrored in `AGENTS.md` / `GEMINI.md`) because its rules are built
  against Claude Code's Agent-tool mechanism — the Agent tool's spawn
  schema, the `run_in_background` parameter (Codex/Antigravity async
  spawning is implicit/platform-native, not a named parameter), and the
  Agent Teams / SendMessage peer-messaging primitives. Codex MAv2
  `send_message` (flag-gated `multi_agent_v2`; issue #12462
  CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing +
  idle auto-rewake) now ship peer-messaging ANALOGS, but they are
  flag-gated / not-yet-GA-documented (Codex) and partly-unverified
  (Antigravity) — so this mechanism stays Claude-only here; the
  cross-CLI mapping is BD-217.
```
**This is a PARTIAL correction (the user's nuance):** it PRESERVES the exemption opener (`This
sub-section is Claude-specific (not mirrored in \`AGENTS.md\` / \`GEMINI.md\`)`), PRESERVES the
`run_in_background` named-parameter point (reframed to the audience-correct truth), reframes the
Agent-tool-specificity from "no equivalents anywhere" to "built against Claude Code's Agent-tool
mechanism," CORRECTS the stale peer-messaging leg, and DROPS the stale `per research §2.5 / §2.7
/ §3.5 / §3.7` citation (superseded v11-archive research). **S4 lands in the SAME CLAUDE.md edit
pass as S1** (both in the `### Sub-agent behavior (Claude-only)` cluster) so the two adjacent
"Trinity exemption" notes are corrected together.

### 4.4 S3 — `supporting-docs/METHODOLOGY.md` (SHIPPED → client docs/pack/; client-developer audience)
**Anchor:** the blockquote tail running from `This convention is Claude-Code-specific:` through
`...peer-messaging across multiple parent turns).` (the Codex `/agent` + Antigravity hub-and-spoke
sentences). **REPLACE those sentences with client-audience wording — NO pack-internal `#12462` /
`multi_agent_v2` jargon:**
```
This convention is Claude-Code-specific. Codex CLI and Antigravity CLI now ship
their own inter-agent-messaging analogs (Codex's multi-agent messaging; Antigravity's
inter-agent ID-addressing with idle auto-rewake), but these are newer, opt-in /
partly-preview capabilities — so this Agent-Teams stage-lifecycle convention is
documented for Claude Code only; on Codex / Antigravity, follow your CLI's own
subagent guidance.
```
**KEEP the existing final routing sentence** `Codex / Antigravity project teams: this convention
does not apply to your CLI's runtime behavior.` — it is a correct audience-routing line, not a
stale capability claim. (Coder: re-read the blockquote (`> **Claude-only operating convention…**`
through the routing sentence) and confirm boundaries before editing — the blockquote markers
`> ` must be preserved on every replacement line.)

**S3 is the BLOCKER fix.** Leaving it uncorrected ships the exact falsehood the BD exists to fix
to every new client (`scripts/init-project.sh` L685 copies it to `docs/pack/METHODOLOGY.md`;
mirrored in 5 `test-fixtures/**/docs/pack/METHODOLOGY.md` — push-time manifest concern, §10).

---

## 5. The registry mechanism (documentation only — no tracked artifact)

The registry is DOCUMENTED by Bullet B (§3.2); there is NO code/file to create in this commit.
- **Path:** `graphify-out/.pack-spawn-registry.jsonl` (per-clone, gitignored). Modeled on the
  existing `graphify-out/.pack-refresh-status` precedent.
- **Gitignore — already covered, NO `.gitignore` EDIT.** Verified `.gitignore` line
  `graphify-out/` ignores the whole dir; the leaf `.pack-spawn-registry.jsonl` is covered with
  ZERO `.gitignore` change (§13). Confirm at impl; do NOT add a `.gitignore` line.
- **No tracked artifact created.** The orchestrator records/consults it at RUNTIME; it is NEVER
  committed (`agents-never-commit`). No empty placeholder file, no schema file, no validator (no
  scannable committed state → `ci-guard-measure-then-bound` empty matching set → NO new Check).
- **Schema (informational, lives in the rule + rationale, not a checked file):** one JSON object
  per line, `{name, agentId, purpose, status}`. No schema check.

---

## 6. BD-217 scope-note (G1 — pack-chat-only governance; FLAG for Pack Chat, NOT a coder edit)

`backlog/BD-217.md` is pack-chat-only governance. The settled design recommends Option (a): a
one-line scope-NOTE (over opening a new v11.1 BD) — BD-241 L19 already names BD-217 the
cross-CLI-applicability anchor. **Pack Chat applies directly** (`pack-chat-minor-edits-only` — a
NEW forward-pointing note on a not-yet-landed BD). Recommended note:
```
Note (2026-06-20, BD-241 handoff): BD-217 ALSO owns the cross-CLI analog of BD-241's
spawn-discovery mechanism (unique-naming is shipped cross-CLI in v11.0; the
registry + find + resume MECHANISM defers here). Carry the corrected cross-CLI
capability premise — Codex MAv2 + Antigravity `agy` peer-messaging analogs EXIST but
are flag-gated / partly-unverified (NOT 'confirmed absent') — into the per-platform
research. See the BD-241 §6 handoff spec.
```
This is NOT a coder edit. The coder must NOT touch `backlog/BD-217.md`.


---

## 7. Project-side surfaces (product deliverables)

### 7.1 PR1 — `project-template/docs/pack/PM-CHAT.md` naming-discipline prose (Bullet A, project audience)
**Anchor:** H3 `### In-session agent spawning`; add a CLI-agnostic prose line modeled on the
existing `**Spawn in the background.**` line (anchor `Spawn in the background`). Project-AUDIENCE
(no pack BD-refs; project agent roster + the `<role>-<workitem>-<facet>` shape in CLI-agnostic
terms). Suggested form:
```
**Name every spawn uniquely + descriptively.** Give each spawned agent a unique,
descriptive name of the shape `<role>-<workitem>-<facet>` (lowercase kebab) so the
orchestrator can re-find a still-alive agent by name. (On Claude Code this is the
Agent-tool `name`; on Codex / Antigravity use the platform's agent-name field.)
```

### 7.2 PR2 — `project-template/docs/pack/PM-CHAT.md` registry+precedence blockquote (Bullet B, Claude-only, project audience)
**Anchor:** near the merge-back re-engage (`re-spawn a fresh \`coder\``); add a `(Claude-only)`
blockquote modeled on the existing `> **Per-project Claude memory cache (Claude-only).**`
blockquote (anchor `Per-project Claude memory cache (Claude-only)`). Suggested form:
```
> **Spawn registry + name→id re-find (Claude-only).** On Claude Code, the
> orchestrator records each spawn (name, id, purpose, status) in a gitignored
> per-clone ledger and re-finds a still-alive agent by name → id — only AFTER the
> fresh-agent-default decision authorizes a re-engage (this is HOW to re-find, not
> WHEN to reuse). Codex / Antigravity equivalents are a future pack version.
```

### 7.3 CPR1a/b/c — project trinity `## Project memory` ×3 (Bullet C, project audience)
**Anchors:** `## Project memory` in `project-template/CLAUDE.md` (ctx L349) /
`project-template/AGENTS.md` (ctx L326) / `project-template/GEMINI.md` (ctx L346). ADD a
project-audience reconciliation-independence bullet (D3 §2.2 C-PR1). Project vocabulary only (no
pack BD-refs); the project agent roster (architect/planner/coder/reviewer/auditor[+specialized]/
repo-ops/tester/grpc-schema/docs-researcher). Suggested CLAUDE.md form:
```
- **Reconciliation-instance independence.** A reconciliation pass (resolving an
  adversarial review before the work advances) uses a FRESH instance — never the
  original author nor the adversarial reviewer. Applies to every project agent role
  (architect, planner, coder, reviewer, auditor, repo-ops, tester, grpc-schema, and
  the rest) EXCEPT `docs-researcher` (factual inventory — reuse OK). Carve-outs: the
  developer explicitly asks to re-engage an existing agent (on Claude Code via
  `SendMessage`; on Codex / Antigravity via the platform re-engage path), or a
  per-case architect-challenge reason.
```
Audience-correct ×3 (ONLY carve-out (1)'s per-CLI re-engage clause differs — same pattern as
§3.3). **Trinity rule:** all three project-trinity edits land in the SAME commit (Check 18
project-template parity). This is a UNIVERSAL collaboration rule — the section's exact charter
("rules that apply project-wide regardless of agent role", verified D3 §7 claim E) — so it
BELONGS here (contrast the Claude-only registry MECHANISM, which correctly stays OUT of the
project trinity).

### 7.4 CPR2 — `project-template/docs/pack/PM-CHAT.md` reconciliation prose (Bullet C, project audience)
**Anchor:** spawn section `### In-session agent spawning` / near the merge-back re-engage
(`re-spawn a fresh \`coder\``). ADD a CLI-agnostic prose line (D3 §2.2 C-PR2). Suggested form:
```
**Reconciliation passes use a fresh instance.** A reconciliation pass (resolving an
adversarial review before the work advances) is a FRESH spawn — never the original
author or the adversarial reviewer — for every agent except `docs-researcher`.
Re-engage an existing agent only on the developer's explicit ask or a per-case
architect-challenge reason.
```

### 7.5 Project NO-EDIT surfaces (do NOT touch)
- `supporting-docs/METHODOLOGY.md` for Bullet C — NO edit. METHODOLOGY's reconciliation-PIPELINE
  narrative is BD-239's home; adding it now pre-empts BD-239 (D3 §2.2). (Note S3 in §4.4 DOES
  edit METHODOLOGY, but only the STALE peer-messaging clause — a different facet.)
- `project-template/docs/pack/METHODOLOGY.md` — DOES NOT EXIST as a project-template source
  (verified `find … METHODOLOGY.md` → only `supporting-docs/` + 5 fixtures). No edit.
- The project trinity `## Project memory` for the BD-241 MECHANISM (Bullet B) — NO edit (the
  registry mechanism is Claude-only runtime detail, wrong audience for a universal-rules section).

---

## 8. Out-of-repo memory edits (Pack-Chat upkeep — FLAG for Pack Chat; trinity wins)

These are NOT tree files (they live under `~/.claude/projects/<slug>/memory/`). The coder does
NOT edit them. Flag for Pack Chat (`pack-chat-minor-edits-only` — Pack Chat's own operating state).

### 8.1 M1 — `reference_sendmessage_uuid_addressing.md` (REFINE → registry + precedence)
Add: the registry is the durable re-find surface; precedence is name → agentId; both work as
`SendMessage.to`; there is NO message-id primitive (do not invent); cite the two in-repo slugs
`spawn-unique-naming` + `spawn-registry-find` (trinity wins). Keep the existing "prefer naming at
spawn / UUIDs work" content.

### 8.2 M2 — `MEMORY.md` (index) — UPDATE + ADD pointers
- UPDATE the SendMessage-UUID pointer line to mention the registry.
- ADD a one-line pointer (under "Design discipline" or "Workflow / coordination"):
  *"Reconciliation-instance independence — fresh instance for the reconciliation pass; never the
  author/reviewer; docs-researcher exempt; user-override + architect-challenge carve-outs."*

### 8.3 M3 — `feedback_fresh_agent_default_no_sendmessage.md` (REFINE → cross-ref C)
Add a cross-ref line: the reconciliation-pass case is codified as trinity `[rationale:
reconciliation-instance-independence]` (fresh instance for the reconciliation round; carve-outs =
user override / architect challenge; `docs-researcher` exempt). trinity wins. (The rule itself is
UNCHANGED — this is only a cross-reference pointer.)

### 8.4 M4 (OPTIONAL) — `feedback_adversarial_planner_review_major_plans.md` (two-sense clarification)
The memory says "Pack Chat RECONCILES the two passes." That is the LIGHTWEIGHT-merge sense (Pack
Chat reading two text outputs and surfacing a merged view — orchestration/triage, NOT a spawned
agent pass — C does not govern it). The SUBSTANTIVE sense (an agent re-authoring the design/plan,
as THIS reconciled plan itself was) IS C-governed → fresh instance. This is a CLARIFICATION, NOT
a contradiction — both memories survive (D3 §4.1). OPTIONAL one-line cross-ref to C distinguishing
the two senses. **No tree-rule conflict exists.** Surface to the user.

---

## 9. BD-238 / BD-239 handoff (cross-reference only — NOT authored here)

C has two facets. BD-241 (this plan) codifies the **agent-REUSE rule** (trinity + project trinity
+ PM-CHAT). BD-238 (pack-side) / BD-239 (project-side) own the **pipeline-STRUCTURE** (the
size-tiered pipeline in which the reconciliation round is a STEP). The handoff (D3 §3):
- **BD-238** (pack pipeline standard): its step-3 ("reconciliation architect") / step-6
  ("reconciliation planner") CROSS-REFERENCE C's slug (do NOT restate — anti-restate/Check 46b;
  safe pointer form "the reconciliation round uses a fresh instance — see trinity `## Pack
  memory` `[rationale: reconciliation-instance-independence]`"); name `docs-researcher` exempt at
  the researcher step; inherit C's two carve-outs by reference.
- **BD-239** (project pipeline standard / METHODOLOGY): the SAME cross-reference, project
  audience; METHODOLOGY.md is BD-239's home for the pipeline-narrative prose; project vocabulary
  only (no pack BD-refs — BD-239 ships to clients).
- **Sequencing:** recommended BD-241 (C) → BD-238 → BD-239 so cross-refs resolve. If BD-238/239
  run BEFORE C, they reference the PLANNED slug + carry a `RE-VERIFY at impl` marker that C landed.
- **Separation-of-concerns line:** the RULE facet (WHO) = BD-241 trinity slug; the PIPELINE facet
  (WHERE in the flow) = BD-238/239 cross-reference. The pipeline docs reference the rule; they do
  NOT re-author it (one SSOT, trinity-wins, no drift).

---

## 10. Commit framing (CROSS-SURFACE — Check 36) + plan

**This is a CROSS-SURFACE change** (`separate-pack-ops-from-product`): it spans (a) pack-ops
trinity + RATIONALE (rule mechanism + pack-side stale corrections incl. S4), (b) a SHIPPED
product file `supporting-docs/METHODOLOGY.md` (S3), and (c) project-template product
(`project-template/{CLAUDE,AGENTS,GEMINI}.md` + `docs/pack/PM-CHAT.md`). Therefore the commit
**MUST NOT carry the `pack-only` keyword** for any commit touching product paths — CI Check 36
denies `supporting-docs/` AND `project-template/` under `pack-only`. The `keyword-token trap`: a
`pack-only` token ANYWHERE in the subject (even prose) is a Check-36 claim — keep it out of the
subject entirely for the product commit.

**RECOMMENDED — the 2-commit SPLIT (adversarial-confirmed PASS; isolates the fixture-input/push-manifest concern):**

- **Commit 1 (`pack-only` clean):** A1/A2/A3 (Bullet A ×3), B1 (Bullet B), C1/C2/C3 (Bullet C ×3),
  R1/R2/R3 (rationale ×3), **S1 + S4** (CLAUDE stale ×2 in the `### Sub-agent behavior
  (Claude-only)` cluster), S2 (RATIONALE stale). Files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
  `pack-ops/PACK-MEMORY-RATIONALE.md`. NO `project-template/` / `supporting-docs/` →
  `pack-only` keyword VALID. **Check 45 (26↔26) + Check 18 pack-root parity must hold in THIS
  commit** (all 3 corpus slugs + 3 rationale + the trinity ×3 all here). S4 is CLAUDE.md (pack-ops)
  → preserves the `pack-only` claim (verified §13 claim #11).
- **Commit 2 (NO scope keyword — `project-only` does NOT fit because S3 is `supporting-docs/`,
  not `project-template/`):** S3 (METHODOLOGY), PR1/PR2 (PM-CHAT), CPR1a/b/c (project trinity ×3),
  CPR2 (PM-CHAT). Files: `supporting-docs/METHODOLOGY.md`, `project-template/{CLAUDE,AGENTS,GEMINI}.md`,
  `project-template/docs/pack/PM-CHAT.md`. Mixed product surface → NO keyword (Check 36 skipped).
  **Check 18 project-template parity must hold in THIS commit** (the project trinity ×3 all here).
- **Each commit independently `validate-pack`-green** (the bounded-cycle invariant): Commit 1
  leaves Check 45 at 26↔26 and Check 18 pack-root green; Commit 2 adds only prose + the
  project-trinity bullet (no new corpus slug) → Check 45 unchanged, Check 18 project-template
  green. **NOTE:** the project trinity bullet (CPR1) is NOT a `## Pack memory` corpus rule (it
  lives in `## Project memory`), so it does NOT affect Check 45 bijection — confirm at impl.

**Alternative — Option A (ONE neutral-framed commit, no scope keyword, Check 36 skipped):** all
surfaces in one commit, subject e.g. `feat: v11 — BD-241 cross-surface: spawn-discovery +
reconciliation-instance rules + stale cross-CLI correction`. Simplest; both pass Check 36. The
SPLIT is RECOMMENDED for audit cleanliness. User chooses at the gate.

**Fixture-input / push-manifest (Check 62):** S3 (`supporting-docs/METHODOLOGY.md`), PR1/PR2/CPR2
(`project-template/docs/pack/PM-CHAT.md`), and CPR1 (project trinity) are fixture INPUTS (mirrored
in `test-fixtures/**`). `scripts/manifest-sync.sh` reconciles the manifest at PUSH, NOT per-commit
(`manifest-regen` memory). The coder does NOT regen `test-fixtures/manifest.txt`; flag for the
orchestrator's push step (expect `manifest-sync.sh` exit 10 → commit the regenerated manifest with
user approval, then push, then watch `Validate Pack` CI / Check 62). S1/S2/S4 (Commit 1) are NOT
fixture inputs (CLAUDE.md + RATIONALE.md are pack-ops) → no manifest concern from Commit 1.

---

## 11. rule-10 — parallelization / dependency map

### 11.1 CROSS-BD serialization (the load-bearing finding — adversarial-confirmed)
**BD-238 + BD-240 + BD-241 ALL edit the same shared files** — trinity `## Pack memory`
(CLAUDE/AGENTS/GEMINI) AND `pack-ops/PACK-MEMORY-RATIONALE.md` (BD-238 adds a pipeline corpus rule
+ rationale; BD-240 re-frames `graph-first-context` ×3 + rationale; BD-241 adds Bullets A/B/C +
R1/R2/R3 + S1/S2/S4). Plus BD-239 edits the project trinity `## Project memory` that BD-241's CPR1
also edits.

| Shared file | BD-238 | BD-240 | BD-241 | BD-239 | Schedule |
|---|---|---|---|---|---|
| `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory` | YES | YES | YES (A/B/C, S1, S4) | no | **SERIALIZE** |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | YES | YES | YES (R1/R2/R3, S2) | no | **SERIALIZE** |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` | no | no | YES (CPR1) | YES | **SERIALIZE (BD-241 vs BD-239)** |

**Consequence (rule 10):** BD-238 / BD-240 / BD-241 CANNOT run as concurrent worktree waves —
concurrent edits to those shared files would conflict and fire the STOP + re-spawn-fresh protocol.
The orchestrator schedules them as **SERIAL commits**. Each coder **BASES ON THE PRIOR-LANDED
HEAD** (not origin/main, not a stale base) and **NEVER hand-merges** — if a base is stale, STOP
and re-spawn the coder on the fresh HEAD. **Rebase-on-BD-240 is ROBUST** (adversarial-confirmed):
BD-240 edits the file TAIL (`graph-first-context` rule + its rationale at RATIONALE.md EOF
region); BD-241 edits the file MIDDLE (`### Agent invocation rules` + `### Sub-agent behavior`)
and an interior RATIONALE block (R1/R2/R3 after `## pack-chat-minor-edits-only`, before
`## graph-first-context`; S2 inside `## preflight-stop-means-stop`). The regions are DISJOINT and
every anchor is a CONTENT literal, so BD-240's line-shift does not move BD-241's anchors. The F-3
fix (R1/R2/R3 NOT at EOF) removes the only residual adjacency. User-stated order: BD-240 runs next;
BD-241 "after/with BD-240" → natural serial order **BD-240 → BD-241**, with BD-238 slotted by the
user. C's BD-238/239 cross-refs (§9) prefer **BD-241 → BD-238 → BD-239** so the slug exists when
referenced.

### 11.2 INTRA-BD-241 map
BD-241's own surfaces overlap on files (A1+C1+B1+S1+S4 all in CLAUDE.md; R1+R2+R3+S2 all in
PACK-MEMORY-RATIONALE.md; A1/A2/A3+C1/C2/C3 across the trinity ×3; PR1+PR2+CPR2 all in PM-CHAT.md)
→ **BD-241's own coders SERIALIZE within the BD** (no intra-BD parallel wave on shared files).
- If **Option A (one neutral commit)** is taken: a single serial coder/commit.
- If **the SPLIT** is taken: Commit 1's files (CLAUDE/AGENTS/GEMINI/RATIONALE) are DISJOINT from
  Commit 2's files (METHODOLOGY + project-template trinity + PM-CHAT). The two commits COULD run
  as a 2-wide wave, but bijection/parity gates live per-commit, so **recommend serial: Commit 1 →
  Commit 2** (the split is about scope-keyword cleanliness, not parallelism — the commits are small).


---

## 12. Verification plan — CI gates + coder PREFLIGHT grep gates

### 12.1 CI / validate-pack gates (run `python3 scripts/validate-pack.py` after edits)
| Check | What it verifies for BD-241 | Pass condition |
|---|---|---|
| **Check 45** (rule↔rationale bijection) | +3 corpus slugs (A/B/C) ↔ +3 rationale sections (R1/R2/R3), SAME commit, bare-slug headings; S1/S2/S3/S4 contribute 0 | **26↔26** (or +3 over the live baseline if BD-238/240 landed first); 0 orphans either direction |
| **Check 46** (manifest + anti-restate) | NO new `.spawn-rule-manifest.txt` record (still 7 spawn records); the 3 new bullet bodies appear in NONE of the 6 anti-restate surfaces | 7 records unchanged; **0 verbatim restatements** (candidate count rises ~49→~52; 0 hits) |
| **Check 18** (trinity H2 parity) | new bullets land inside EXISTING H3s (`### Agent invocation rules`, `### Sub-agent behavior (Claude-only)`, project `## Project memory`) — NO new heading | parity green pack-root AND project-template; Bullet A/C ×3, Bullet B CLAUDE-only (no parity break — single-surface in a Claude-only H3); CPR1 ×3 |
| **Check 36** (commit-scope honesty) | the product commit touches `supporting-docs/` + `project-template/` → MUST NOT claim `pack-only` | SPLIT: Commit 1 `pack-only` valid (S1/S2/S4 add no product path), Commit 2 no keyword. Option A: no keyword (skipped) |
| **Check 62** (push-time manifest) | S3 + PR/CPR fixture inputs reconciled at PUSH via `manifest-sync.sh` | NOT per-commit; orchestrator runs it pre-push (expect exit 10 → commit regenerated manifest) |

**measure-then-bound — NO new CHECK designed.** The registry is gitignored runtime state and
spawn names / reconciliation-instance choices are runtime decisions — there is NO committed-tree
state for a validator to scan (an empty matching set, forbidden by `ci-guard-measure-then-bound`).
Enforcement is the corpus rules (discipline) + Pack Chat's rules-in-force block at spawn time,
reusing Checks 18/45/46. CI runtime-compounding cost (×~155) UNCHANGED.

### 12.2 Coder PREFLIGHT grep gates (run ALL before the IMPL-REPORT; PREFLIGHT line gates the report)
Run from the repo root (or the isolated worktree root — verify pwd/HEAD at runtime). ALL grep
literals below are at the REAL tree casing (measured at af73ffb, §13) — a correct edit makes
every gate pass.

1. **Rationale bare-slug headings present (×3):**
   `grep -nE "^## (spawn-unique-naming|spawn-registry-find|reconciliation-instance-independence)$" pack-ops/PACK-MEMORY-RATIONALE.md`
   → exactly 3 lines, each a BARE slug (nothing after the slug — matches Check 45 regex).
2. **Corpus tags present (count per slug across trinity):**
   `for s in spawn-unique-naming spawn-registry-find reconciliation-instance-independence; do echo "$s:"; grep -c "rationale: $s" CLAUDE.md AGENTS.md GEMINI.md; done`
   → `spawn-unique-naming` = 1/1/1 (×3 trinity); `reconciliation-instance-independence` = 1/1/1
   (×3 trinity); `spawn-registry-find` = 1/0/0 (CLAUDE.md ONLY — Claude-only).
3. **Trinity ×3 SHARED-BODY parity for each ×3 bullet** (Bullet A + Bullet C): confirm the
   load-bearing clauses are byte-identical across CLAUDE/AGENTS/GEMINI and ONLY the per-CLI
   reference clause differs. E.g.
   `grep -c "uniqueness is a DISCIPLINE — no platform guarantees it" CLAUDE.md AGENTS.md GEMINI.md`
   → 1/1/1; `grep -c "NEVER the original author" CLAUDE.md AGENTS.md GEMINI.md` → 1/1/1;
   `grep -c "EXCEPT \`docs-researcher\`" CLAUDE.md AGENTS.md GEMINI.md` → 1/1/1.
4. **Load-bearing clause kept verbatim (Bullet B):**
   `grep -c "Consult the registry ONLY after the \`fresh-agent-default\` gate authorizes a re-engage" CLAUDE.md`
   → 1.
5. **Stale-claim grep-ZERO on the pack-side STRIP surfaces S1/S2 (removed phrasings gone):**
   - `grep -c "have no peer-messaging equivalent — confirmed" CLAUDE.md` → 0 (S1)
   - `grep -c "No SendMessage equivalent (confirmed absent per issue #12462)" pack-ops/PACK-MEMORY-RATIONALE.md` → 0 (S2)
   - Positive presence of the corrected text:
     `grep -c "now ship peer-messaging ANALOGS\|MAv2 \`send_message\` analog exists" CLAUDE.md pack-ops/PACK-MEMORY-RATIONALE.md` → ≥1 each.
6. **KEEP surfaces UNTOUCHED (grep-still-present — no accidental strip; REAL lowercase casing):**
   - `grep -c "if your CLI offers no peer-messaging, re-spawn a fresh" project-template/docs/pack/PM-CHAT.md` → 1
   - `grep -c "no equivalent per-project memory" project-template/docs/pack/PM-CHAT.md` → 1
     (lowercase `memory` — the ALL-CAPS `MEMORY` literal returns 0; see §13 claim #10a)
   - `grep -c "their worktree story is" project-template/docs/pack/OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md` → 1/1
     (use `their worktree story is`, NOT `worktree story is tracked`: the latter is 2 in the
     project-template file (a duplicate at L99) and 0 in the pack-ops file (line-wrapped) — both
     false-fail. `their worktree story is` is the precise both-files literal; see §13 claim #10b)
   - (F-4 tightening) Confirm `git diff project-template/docs/pack/PM-CHAT.md` shows only ADD hunks
     for PR1/PR2/CPR2 (the KEEP lines unchanged); the two OPTIONAL-FEATURES files
     (`project-template/docs/pack/OPTIONAL-FEATURES.md`, `pack-ops/OPTIONAL-FEATURES.md`) and
     `backlog/BD-241.md` must NOT appear in `git diff --name-only` at all (not in BD-241's edit set).
7. **S4 STRIPPED — grep-ZERO completeness gate (F-6: was "leave untouched → 1"; now ZERO):**
   - `grep -c "none of which have equivalents" CLAUDE.md` → 0 (S4 stale assertion removed;
     measured: this phrase appears ONLY in S4 at baseline, §13 claim #11a)
   - `grep -c "per research §2.5 / §2.7 / §3.5 / §3.7" CLAUDE.md` → 0 (S4 stale superseded-research
     citation dropped)
   - **Preserved-leg presence (S4 is a PARTIAL correction):**
     `grep -c "This sub-section is Claude-specific" CLAUDE.md` → 1 (the exemption opener survives;
     this literal is UNIQUE to S4 — measured §13 claim #11b. NOTE: do NOT use
     `grep -c "run_in_background" CLAUDE.md` as the preserved-leg gate — it is 3 in CLAUDE.md and
     stays ≥1 even if S4's mention were dropped, a false-PASS)
   - **Corrected leg present in S4:** `grep -c "built against Claude Code's Agent-tool mechanism" CLAUDE.md` → 1
8. **No project-trinity MECHANISM leak:** the project trinity `## Project memory` carries Bullet C
   (CPR1) only — NOT Bullet B's registry mechanism:
   `grep -c "pack-spawn-registry\|name→agentId" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` → 0/0/0.
9. **No `.gitignore` edit:** `git diff --name-only` does NOT list `.gitignore`.
10. **validate-pack green:** `python3 scripts/validate-pack.py` → `PASSED — all checks clean`;
    Check 45 = 26↔26 (or +3 over live baseline); Check 46 = 7 records / 0 restate; Check 18 green
    pack-root + project-template.
11. **Base-predecessor assertion (F-5, CORRECTED — content marker, NOT a commit-message grep):**
    IF the orchestrator schedules BD-241 AFTER BD-240, confirm the base HEAD is the POST-BD-240
    tree by a CONTENT marker for BD-240's landed change — NOT `git log | grep BD-240` (which
    false-PASSES at af73ffb, where the BD-240 *opening* commit is already in the log but the
    re-frame has NOT landed; see §13 claim #12). The exact marker is whatever string BD-240's plan
    introduces into the re-framed `## graph-first-context` rule/rationale; the coder confirms that
    marker is PRESENT at base (e.g. `grep -c "<BD-240 re-frame marker>" CLAUDE.md pack-ops/PACK-MEMORY-RATIONALE.md` ≥ 1).
    If absent AND the orchestrator intended BD-240-first, STOP — the base is stale/wrong-order;
    re-spawn on the correct HEAD. (If BD-241 is scheduled BEFORE BD-240, this gate is N/A — the
    BD-241 anchors are disjoint from BD-240's region and resolve cleanly either way; rebase
    ROBUST.) This is the `RE-VERIFY at impl` marker the D3 handoff §3.2 prescribes, applied to
    BD-241's own base.

**PREFLIGHT line (emit ONLY after all gates + validate-pack PASS):**
`PREFLIGHT: N/N in-scope edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`.
If ANY gate fails, report what went wrong INSTEAD of a partial IMPL-REPORT. STOP-means-stop: any
parent stop/halt/revert message halts ALL work immediately.

---

## 13. Empirical-Evidence Block (every state-claim — command + verbatim output + HEAD + conclusion)

All commands run in MAIN checkout, branch `v11-dev`, HEAD `af73ffb`, 2026-06-20.

| # | State-claim | Command | Output (verbatim/measured) | Conclusion |
|---|---|---|---|---|
| 1 | HEAD / branch as stated | `git rev-parse HEAD && git branch --show-current` | `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` / `v11-dev` | SUPPORTED |
| 2 | validate-pack baseline GREEN; Check 45 = 23↔23; Check 46 = 7 spawn / 0 restate / 49 candidates | `python3 scripts/validate-pack.py` | "Check 45 — 23 corpus … 23 rationale … sets are equal (bijection holds…)"; "Check 46 … spawn manifest: 7 rule(s) … anti-restate: 0 … (49 candidate bodies … >= 60 chars)"; "PASSED — all checks clean"; Check 18 [project-template]+[pack-root] both printed | SUPPORTED (targets +3 → 26↔26) |
| 3 | `### Agent invocation rules` ×3 + `### Sub-agent behavior` CLAUDE-only | `grep -n "### Agent invocation rules" CLAUDE.md AGENTS.md GEMINI.md`; `grep -c "### Sub-agent behavior" CLAUDE.md AGENTS.md GEMINI.md` | CLAUDE:242 / GEMINI:211 / AGENTS:244; Sub-agent behavior 1/0/0 | SUPPORTED |
| 4 | `**No prior reviews to pack-reviewer.**` ×3 (Bullet C anchor) | `grep -n "No prior reviews to pack-reviewer" CLAUDE.md AGENTS.md GEMINI.md` | CLAUDE:269; GEMINI:233; AGENTS:259 | SUPPORTED |
| 5 | Bullet B insertion neighbors (Agent-team lifecycle → Trinity exemption) | `grep -n "Agent-team stage lifecycle\|^- \*\*Trinity exemption" CLAUDE.md` | :402 `**Agent-team stage lifecycle + per-commit fresh-coder.**`; :418 `- **Trinity exemption.**` | SUPPORTED |
| 6 | S1 stale clause present | `grep -cn "have no peer-messaging equivalent — confirmed" CLAUDE.md` | 1 | SUPPORTED |
| 7 | S2 stale Codex line present | `grep -cn "No SendMessage equivalent (confirmed absent per issue #12462)" pack-ops/PACK-MEMORY-RATIONALE.md` | 1 | SUPPORTED |
| 8 | S3 stale clauses present in METHODOLOGY | `grep -cn "no peer-messaging analog" supporting-docs/METHODOLOGY.md`; `grep -cn "hub-and-spoke" supporting-docs/METHODOLOGY.md` | 1; 1 | SUPPORTED |
| 9 | METHODOLOGY SHIPS + mirrored in 5 fixtures (Check 62) | `grep -n METHODOLOGY scripts/init-project.sh` | L685 `cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"` | SUPPORTED |
| **10a** | **F-1/NEW-1: PM-CHAT KEEP literal casing — lowercase `memory`, ALL-CAPS returns 0** | `grep -c "no equivalent per-project memory" PM-CHAT`; `grep -c "no equivalent per-project MEMORY" PM-CHAT` | lowercase = `1` (L907 `…have no equivalent per-project memory`); ALL-CAPS = `0` | SUPPORTED — gate uses lowercase `memory` |
| **10b** | **F-1/NEW-1: worktree KEEP literal — `worktree story is tracked` MIScounts; `their worktree story is` is the robust 1/1** | `grep -c "worktree story is tracked" project-template/docs/pack/OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md`; `grep -c "their worktree story is" <same two>` | `worktree story is tracked` = **2 / 0** (project-template: dup at L99+L283; pack-ops: line-wrapped → 0); `their worktree story is` = **1 / 1** | SUPPORTED — gate uses `their worktree story is` (adversarial's `→1/1` on `worktree story is tracked` would FALSE-FAIL) |
| 10c | F-1: third KEEP literal (conditional guard) correct as-is | `grep -c "if your CLI offers no peer-messaging, re-spawn a fresh" project-template/docs/pack/PM-CHAT.md` | 1 | SUPPORTED — leave as written |
| **11a** | **F-6: S4 stale phrase `none of which have equivalents` present, and ONLY in S4** | `grep -n "none of which have equivalents" CLAUDE.md` | `:421   SendMessage features — none of which have equivalents in Codex CLI` (single hit, inside L418-422) | SUPPORTED — grep-ZERO post-strip proves complete removal, no copy elsewhere |
| **11b** | **F-6/NEW-3: preserved-leg gate — `This sub-section is Claude-specific` is UNIQUE to S4 (1); `run_in_background` is 3 (non-specific)** | `grep -c "This sub-section is Claude-specific" CLAUDE.md`; `grep -c "run_in_background" CLAUDE.md` | `1`; `3` | SUPPORTED — use the `This sub-section is Claude-specific` literal as the preserved-leg gate |
| 11c | S4 is untagged prose → 0 Check-45 impact | `sed -n '418,422p' CLAUDE.md \| grep -c "rationale:\|roles:"` | 0 | SUPPORTED — bijection delta stays +3 |
| **12** | **F-5/NEW-2: `git log \| grep BD-240` FALSE-PASSES (the OPEN commit is already in the log); BD-240 work NOT landed** | `git log --oneline -8 \| grep -i BD-240`; `grep "^Status:" backlog/BD-240.md` | log hit: `af73ffb docs: v11 — open BD-240 (graph-first rule re-frame) + BD-241 …`; `Status: Open` | SUPPORTED — base assertion must be a CONTENT marker for BD-240's landed re-frame, not a log-grep |
| 13 | F-3: rationale insertion anchors | `grep -n "^## pack-chat-minor-edits-only\|^## graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md`; `wc -l` | :600 `## pack-chat-minor-edits-only`; :638 `## graph-first-context`; EOF 684 | SUPPORTED — insert R1/R2/R3 between L600 and L638 (off BD-240's tail) |
| 14 | rationale headings are BARE-SLUG; Check 45 regex | `grep -nE "^## [a-z0-9][a-z0-9-]*$" pack-ops/PACK-MEMORY-RATIONALE.md \| tail` | e.g. `## pack-chat-minor-edits-only`, `## graph-first-context` | SUPPORTED |
| 15 | `graphify-out/` gitignored → registry leaf covered, NO `.gitignore` edit | (RECONCILED §7 G-3, re-cited) `.gitignore` ignores `graphify-out/` | covered | SUPPORTED |
| 16 | project trinity `## Project memory` ×3 (CPR1 home) | `grep -n "## Project memory" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` | CLAUDE:349; AGENTS:326; GEMINI:346 | SUPPORTED |
| 17 | PM-CHAT.md spawn-section anchors (PR1/PR2/CPR2) | `grep -n "### In-session agent spawning\|Spawn in the background\|Per-project Claude memory cache" project-template/docs/pack/PM-CHAT.md`; `grep -c "re-spawn a fresh" PM-CHAT` | :454; :506; :897; re-spawn-a-fresh = 2 | SUPPORTED |
| 18 | `[roles: universal]` is a valid in-use tag | (D3 §7 claim F, re-cited) `grep -ohE "\[roles:[^]]*\]" CLAUDE.md \| sort -u` | includes `[roles: universal]` | SUPPORTED |

---

## 14. Open risks / unknowns (for Pack Chat + user at the planner→coder gate)

1. **S4 (RESOLVED — no longer an open item).** Per `DESIGN-BD-241-L418-CORRECTION.md` the user
   INCLUDED CLAUDE.md L418-422 as the 4th STRIP (S4) in Commit 1; the coder STRIPS it (PARTIAL
   correction — fix the peer-messaging leg, preserve the Agent-tool/`run_in_background` leg + the
   exemption opener). The §12.2 gate #7 is a grep-ZERO completeness gate proving removal. The old
   "half-corrected CLAUDE.md" risk is CLOSED by stripping S4 together with S1 in the same edit pass.
2. **Commit framing (§10).** SPLIT (Commit 1 `pack-only` / Commit 2 no-keyword) vs Option A (one
   neutral commit). RECOMMEND the SPLIT (isolates the fixture-input/push-manifest concern; keeps
   the rule-mechanism commit `pack-only`-clean). Both pass Check 36. User chooses.
3. **rule-10 serialization + base assertion (§11, §12.2 gate #11).** BD-238/240/241 MUST serialize
   on trinity + RATIONALE. If BD-240 is scheduled first, the coder confirms a CONTENT marker for
   BD-240's landed re-frame at base (NOT a `git log | grep BD-240`, which false-passes at af73ffb).
   RISK: a stale-base coder silently bases on a tree missing BD-240 — mitigated by the content-marker
   gate. Rebase-on-BD-240 is otherwise ROBUST (disjoint regions, content anchors, R1/R2/R3 off EOF).
4. **Bijection timing (Check 45).** Under the SPLIT, the 3 corpus slugs AND 3 rationale sections
   MUST be in Commit 1 (CLAUDE/AGENTS/GEMINI + RATIONALE) — they ARE (S3/PR/CPR in Commit 2 add no
   corpus slug; CPR1 is `## Project memory`, not `## Pack memory`; S4 is untagged prose). RISK if
   mis-split: a corpus slug in Commit 1 with its rationale in Commit 2 would FAIL Check 45 at
   Commit 1. Mitigated: keep all R1/R2/R3 with A/B/C in Commit 1.
5. **Anti-restate (Check 46b) if the OPTIONAL PACK-CHAT.md pointer is added (§3.2.1).** The
   recommendation is SKIP. If added, the coder MUST measure the 120-char leading-window
   non-overlap. Default: do NOT add it.
6. **Governance items (G1 BD-217 note, G2 PACK-CHAT carve-out, M1-M4 memory) are NOT coder edits**
   — Pack Chat applies them. RISK: a coder editing `backlog/BD-217.md` or the memory files =
   boundary violation. The coder touches ONLY the tree files in §2.1 + §2.2.

---

## 15. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | §13 — 18 numbered state-claims (incl. 10a/10b/11a/11b/12 sub-claims), each with command + verbatim output + HEAD `af73ffb`/2026-06-20 + conclusion. The load-bearing reconciliation claims are measured: F-1 (10a/10b — lowercase casing + the `worktree story is tracked` miscount/line-wrap), F-6 (11a/11b — S4 stale phrase uniqueness + preserved-leg gate specificity), F-5 (12 — the log-grep false-pass). | COMPLIANT |
| adversarial-planner-review (independent challenge) | I did not rubber-stamp the adversarial fixes: re-measured every finding, and STRENGTHENED F-1 (NEW-1: `their worktree story is` is the only robust 1/1 literal — the adversarial's `worktree story is tracked → 1/1` would false-fail 2/0) and F-5 (NEW-2: content marker, not `git log | grep BD-240` which false-passes), and tightened the F-6 preserved-leg gate (NEW-3: `This sub-section is Claude-specific`, not `run_in_background`). Pushed back on nothing (all 6 findings valid). | COMPLIANT |
| rename-plans-measure-then-bound / measure-then-bound | Every surface in §2 carries a grep-able CONTENT-ANCHOR at the REAL tree casing; §12.2 gates are grep-ZERO on STRIP surfaces (S1/S2 #5, S4 #7) + grep-PRESENT on KEEP (#6, real lowercase literals) + per-slug tag counts (#2). Line numbers are explicitly "context only". R1/R2/R3 placement is content-anchored (F-3), not EOF. | COMPLIANT |
| separate-pack-ops-from-product | §10 keeps the SPLIT: Commit 1 = pack-ops (trinity + RATIONALE + S1/S2/S4); Commit 2 = product (shipped METHODOLOGY S3 + project-template trinity + PM-CHAT). S4 verified pack-ops (CLAUDE.md) → rides Commit 1's `pack-only` claim (§13 claim #11c untagged; §11.1). | COMPLIANT |
| graph-first-context | Ran `graphify query "agent invocation rules sub-agent behavior peer messaging reconciliation registry KEEP surfaces worktree" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST → returned only fixture/provenance nodes (concept not a graph node) → G2 fallback to grep/Read for every load-bearing surface (§13). | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Read-only git only (`git rev-parse HEAD`, `git branch --show-current`, `git log --oneline -8`). ZERO state-changing verbs. Sole filesystem write = this reconciled plan doc at `/tmp/pack-handoff-bd241-plan/PLAN-BD-241-RECONCILED.md` (chunked heredoc appends). No destructive op. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT terminal; includes the graph-query-ran row. No empty-evidence rows. | COMPLIANT |
| graph-query-ran (evidence row) | `graphify query "…" --graph <injected absolute path> --backend claude-cli --budget 1500` executed FIRST (injected path, not self-derived); result = fixture/provenance nodes only → G2 fallback. | COMPLIANT |

---

*End PLAN-BD-241-RECONCILED. Read-only pack-planner RECONCILIATION plan; no patch produced; sole
write is this doc at `/tmp/pack-handoff-bd241-plan/PLAN-BD-241-RECONCILED.md` (SUPERSEDES the
original). No redesign — applies all 6 adversarial findings (F-1/F-6 MAJOR; F-2/F-3/F-4/F-5
MINOR), STRENGTHENS the F-1/F-5/F-6 gate recipes (NEW-1/NEW-2/NEW-3), and keeps the
adversarial-confirmed architecture intact (2-commit split; rebase-on-BD-240 ROBUST; Check 45
26↔26; the 3-rule + 4-STRIP + project + memory + BD-217-note surface set). S4 is single-voiced as
an INCLUDED strip in Commit 1; KEEP-surface grep gates use the real lowercase casing; all PREFLIGHT
gates are internally correct. Plan-ready → user planner-to-coder gate.*
