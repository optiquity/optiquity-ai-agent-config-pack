# RESEARCH — BD-243: strip historical/audit + bloat from operating docs (pack + project)

Researcher: pack-docs-researcher (fresh, RO). Runtime HEAD `a847f12` (BD-243 committed). Inventory-only — no fix/rule design.

**Headline numbers (measured @ a847f12).** ~145 operating docs in scope (33 pack + 112 project). Historical/audit-trail text is **concentrated pack-side** (pack-root trinity + pack-ops + bl/cl meta). The **project-side (shipped) surface is near-clean of historical/audit text** (the existing pack-self-ref boundary rule already keeps it out) — so project-side BD-243 work is **almost entirely the bloat/terseness axis**, not the history axis. This is the single most important scoping fact for the architect.

---

## OPEN QUESTIONS FOR USER (rule on each before architect bounds the fix-set)

**Q1 — PACK-MEMORY-RATIONALE.md (user-anchored IN): how deep does the strip go?**
Provisional call: IN, but strip is SURGICAL. The file's PURPOSE is "Why + rejected-alternatives" — that conceptual Why is its operational payload (an agent reads it to resolve an ambiguous Rules-Applied row). But each `## <slug>` block opens with dated incident provenance: `**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery. Both BD-195 design failures (C6 …; C7 … 1213 hits in 114 files) …` (12 dated notes, 58 BD/TD refs). The DATED INCIDENT NARRATION is strippable audit-trail; the CONCEPTUAL principle behind it must survive (rewrite "User-locked 2026-05-30 during BD-195…" → the timeless principle). Ambiguity: how aggressively to convert incident-grounded Why into principle-only Why without losing the persuasive force that makes an agent comply. **Recommend: strip dates/BD-incident specifics, keep the conceptual Why + How-to-apply.**

**Q2 — supporting-docs/*.md: EXEMPT (reference) or IN (operating)?**
Provisional call: EXEMPT (reference/setup guides), EXCEPT possibly METHODOLOGY.md. All 9 carry ZERO historical/audit refs (measured). CLI-PM-SETUP / INSTALL-PROCEDURES / SETUP-* / DEPENDENCIES / MIGRATION = setup/reference (clearly EXEMPT, like README). AGENT_KICKOFF_TEMPLATE / SETUP_TEMPLATE = fill-in templates that EMIT a project doc (deliverable-construction, not operating instruction → EXEMPT). METHODOLOGY.md = describes the dev methodology to humans/PM ("Applies to: All projects…") — borderline: descriptive guide (EXEMPT) vs system-wide instruction (IN). **Recommend EXEMPT for all 9** (none issue live operating instructions to chat sessions/agents; they describe setup/process). Confirm.

**Q3 — `.codex/agents/*.toml` (16 files): in BD-243's "operating DOCUMENTS" scope, or excluded as "not .md / config"?**
Provisional call: IN. They are agent DEFINITIONS (same operating-instruction content as the `.claude/agents/*.md` + `.agents-plugin/*.md` families), just TOML-serialized. BD-243's exemption is for SCRIPTS (runtime-ignored comments), not for TOML agent-instruction bodies. Excluding them would leave 1/3 of the project agent-def surface un-swept and break tri-family parity. They carry ZERO BD/historical refs today (measured) → bloat-axis only. **Recommend IN.** (Note: TOML is not prose-markdown; the terseness pass applies to the instruction string bodies, not TOML syntax.)

**Q4 — Trinity `## Sub-agent behavior (Claude-only)` mega-rules: bloat-strip vs meaning-loss risk.**
The pack-root memory rules are extreme bloat (the single `graph-first-context` bullet = **5,274 chars**; 52 top-level memory rules in a 768-line CLAUDE.md). Aggressive terseness here is the BIGGEST win AND the BIGGEST meaning-loss risk (these rules encode load-bearing worktree/graph contracts). Ambiguity: how aggressive on rules whose every clause is a contract. **Recommend: architect sets a per-rule terseness bar; reviewer runs no-behavior-change verification rule-by-rule** (flagging here so the architect plans the safest-possible structural conversion, e.g. prose→table, not clause deletion).

**Q5 — `until BD-NNN` / `deferred — BD-NNN` / `coordinate BD-217`: confirm these are KEEP (live forward-pointers), not strip.**
Provisional call: KEEP. See Task C's historical-provenance-vs-live-cross-reference split. A `BD-NNN` that points to LIVE future/deferred/blocked work is operational (it tells the agent where the live anchor is); a `BD-NNN` that narrates a COMPLETED past action is audit-trail (strip). **Recommend the architect's grep-zero gate target HISTORICAL-PROVENANCE shape only, with a measured allowlist of live forward-pointers** (measure-then-bound). Confirm the keep/strip line.

---

## TASK A — OPERATING-vs-REFERENCE TAXONOMY (for user approval)

### Criterion (refined from user anchor)
> A doc is **OPERATING (IN)** iff it ISSUES system-wide operating instructions that a chat session or agent EXECUTES at task time — rules, agent/skill definitions, prompts, contracts agents act on. A doc is **REFERENCE/OUTPUT/HELPER (EXEMPT)** iff it DESCRIBES, sets up, records, or self-governs — read by humans for orientation or emitted as a deliverable, not executed as live instruction.

Tie-breaker tests (apply in order):
1. **Execution test** — does an agent/chat READ this AND CHANGE ITS BEHAVIOR per its content during a task? → IN.
2. **Audience test** — is the primary audience a human reader (orientation/setup/history) rather than an executing agent? → EXEMPT.
3. **Deliverable test** — is the doc a template that EMITS a project artifact, or a record of past work? → EXEMPT (it constructs/records, doesn't instruct).
4. **History-home test** — is the doc itself a history store (changelog/backlog ENTRY, maintenance-doc, IMPL report)? → EXEMPT (history is its job).

User anchors satisfied: PACK-MEMORY-RATIONALE.md → IN (agents execute its Why to resolve rules). README.md / project README / QUICKSTART → EXEMPT (orientation, self-governance).

### IN / EXEMPT classification

| Surface | Class | One-line reason |
|---|---|---|
| Pack root trinity CLAUDE/AGENTS/GEMINI.md | **IN** | Live operating rules every pack chat+agent executes. |
| pack-ops/PACK-CHAT.md, PACK-AGENTS.md | **IN** | Chat operating rules + agent routing executed at task time. |
| pack-ops/MERGE-STRATEGY.md, OPTIONAL-FEATURES.md, BOUNDARY-DEFINITION.md, CONCEPTUAL-REVIEW-METHODOLOGY.md, DRY-RUN-MIGRATION.md | **IN** | Operating procedures/contracts agents follow. |
| pack-ops/PACK-MEMORY-RATIONALE.md | **IN** (anchor) | Agents execute its Why to resolve ambiguous rules. |
| pack-ops/HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md | **IN** | Help text emitted by `pack help` at runtime — operating output of a live command. |
| backlog/_rules.md, changelog/_rules.md (+ _intro.md ×2) | **IN** | Per-stream WRITE CONTRACT agents follow when editing entries. |
| backlog/_toc.md, changelog/_toc.md | **EXEMPT** | Generated index (not authored; not instruction). |
| backlog/BD-*.md, changelog/v*.md (entries) | **EXEMPT** | History store (the canonical home for provenance). |
| .claude/skills/*/SKILL.md (11 pack) | **IN** | Skill bodies agents load + execute. |
| .claude/agents/pack-*.md (5 pack) | **IN** | Agent definitions executed on spawn. |
| project-template trinity CLAUDE/AGENTS/GEMINI.md | **IN** | Shipped operating rules client agents execute. |
| project-template/docs/pack/*.md (6: HELP-FRAGMENT*, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT) | **IN** | Shipped operating instructions to PM chat + agents. |
| project-template/docs/pack/prompts/*.md (10) | **IN** | Spawn-prompt bodies executed verbatim. |
| project-template/skills/*/SKILL.md (37) | **IN** | Shipped skill bodies agents execute. |
| project-template/.claude/agents/*.md (16) | **IN** | Shipped Claude agent definitions. |
| project-template/.agents-plugin/optiquity-agents/agents/*.md (16) | **IN** | Shipped Antigravity agent definitions (tri-family). |
| project-template/.agents-plugin/.../RUNTIME-SUBAGENT-PATTERN.md | **IN** | Issues runtime subagent-invocation operating instructions. |
| project-template/.codex/agents/*.toml (16) | **IN** (Q3) | Codex agent definitions (TOML-serialized operating instructions). |
| project-template/docs/project/{backlog,changelog,implementation-plan}/_rules.md,_intro.md,_format.md (7) | **IN** | Shipped per-stream write contracts. |
| supporting-docs/*.md (9) | **EXEMPT** (Q2) | Setup/reference/methodology guides + emit-templates; describe/set-up, don't instruct. |
| README.md, QUICKSTART.md, LICENSE.md, project-template/README.md | **EXEMPT** (anchor) | Orientation/output/self-governance, not operating instruction. |
| maintenance-docs/**, PACK-REVIEW-*, IMPL reports | **EXEMPT** | History/record store (provenance is their purpose). |
| scripts/**, *.toml config (non-agent), .py | **EXEMPT** | Scripts (BD-243 explicit script exemption). |


---

## TASK B — DEFINITIVE operating-doc blast radius (grep-zero verified set)

Verified against the live tree @ `a847f12`. **Total IN = ~145** (33 pack + 112 project). Candidate ~150-doc set CONFIRMED (with corrections noted).

### Pack-side IN set (33)
- Root trinity (3): `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
- `pack-ops/` (10): `PACK-CHAT.md`, `PACK-AGENTS.md`, `MERGE-STRATEGY.md`, `PACK-MEMORY-RATIONALE.md`, `BOUNDARY-DEFINITION.md`, `OPTIONAL-FEATURES.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`
- bl/cl meta (4): `backlog/_rules.md`, `backlog/_intro.md`, `changelog/_rules.md`, `changelog/_intro.md`  (`_toc.md` ×2 EXCLUDED — generated)
- `.claude/skills/*/SKILL.md` (11): architecture-review, boundary-investigation, commit-discipline, dependency-intake, documentation, implementation-report, pack-help, pack-startup, planning, review, verification-harness
- `.claude/agents/pack-*.md` (5): pack-architect, pack-coder, pack-docs-researcher, pack-planner, pack-reviewer

### Project-side IN set (112, shipped)
- Trinity (3): `project-template/{CLAUDE,AGENTS,GEMINI}.md`
- `docs/pack/*.md` (6): HELP-FRAGMENT-TRACKER, HELP-FRAGMENT, OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT
- `docs/pack/prompts/*.md` (10): architect, auditor, coder, docs-researcher, grpc-schema, planner, pm-chat, repo-ops, reviewer, tester
- `skills/*/SKILL.md` (37) — full list verified (api-design … ui-test-strategy)
- `.claude/agents/*.md` (16): architect, auditor, auditor-architecture, auditor-code, auditor-docs, auditor-ops, auditor-security, auditor-tests, auditor-ui, coder, docs-researcher, grpc-schema, planner, repo-ops, reviewer, tester
- `.agents-plugin/optiquity-agents/agents/*.md` (16) — same 16 roles (Antigravity family)
- `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (1) — **ADDED (candidate set missed it)**
- `.codex/agents/*.toml` (16) — **CORRECTION: Codex family is `.toml`, NOT `.md`** (Q3); same 16 roles
- `docs/project/*/_*.md` (7): backlog/{_intro,_rules}, changelog/{_format,_intro,_rules}, implementation-plan/{_intro,_rules}

### Corrections to the BD-243 candidate
1. **Codex agents are 16 `.toml`, not `.md`** — the candidate's "agent defs x3 CLI families" silently assumed `.md`. Tri-family = `.claude/*.md` (16) + `.agents-plugin/*.md` (16) + `.codex/*.toml` (16) = 48 + RUNTIME-SUBAGENT-PATTERN.md = 49 agent-def surfaces.
2. **RUNTIME-SUBAGENT-PATTERN.md** added (operating, missed by candidate).
3. **supporting-docs reclassified EXEMPT** (Q2) — candidate said "operating subset"; measured: zero historical text + reference/setup nature → none operating. (User confirm.)
4. Project skills = **37** (candidate said 36).
5. **Tri-family parity lock**: the 16 agent roles exist in 3 serialized families — any per-role edit must touch all 3 (Claude .md / Antigravity .md / Codex .toml) in lock-step (rule-6 encoding surfaces).

### Encoding surfaces that ASSERT operating-doc content (rule 6 — must coordinate)
NO existing validator scans operating-doc BODY for historical text (the grep-zero history gate is NET-NEW — architect builds it). STRUCTURAL asserters that an aggressive pass can trip:
- `scripts/validate-pack.py` **Check 16/18/19** — trinity H2 `## Project addenda` presence + H2 parity + no-body-scaffolding (project + pack-root, per-location). A structural strip that drops/renames an H2 on one trinity file breaks parity.
- **Check 45** — pack-memory rule↔rationale slug BIJECTION (CLAUDE.md corpus `[rationale: slug]` set == PACK-MEMORY-RATIONALE.md `## slug` set). Stripping a memory rule MUST drop its rationale section (and vice-versa) in the same commit.
- **Check 11** — pack agent trinity-rule symmetry (informational).
- **Check 1 / Check ~16-skill-inventory** — SKILL.md frontmatter required fields + skill inventory↔disk set-equality (don't strip frontmatter).
- **Trinity rule** (CLAUDE/AGENTS/GEMINI parity, both locations) — every memory-rule / H2 edit serializes across the 3 trinity files.
- `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` — PRIOR concision design (Check 45 cites its §5.2); architect should read it (precedent + existing concision contract).


---

## TASK C — HISTORICAL/AUDIT-TRAIL PATTERN SET (the grep-zero target)

### Pattern catalog (the complete strip-target set)
| # | Pattern | Regex sketch | Default verdict |
|---|---|---|---|
| P1 | BD/TD provenance tag on a rule/section | `\(BD-\d+[^)]*\)`, `BD-\d+ \|`, inline `(BD-NNN)` anchor | STRIP tag (keep rule) |
| P2 | "BD-NNN did X" past-action narration | `BD-\d+ (deleted\|added\|renamed\|introduced\|removed\|created\|retired\|broadened)` | STRIP |
| P3 | "per BD-NNN" / "per the … BD" justification | `per BD-\d+` | STRIP |
| P4 | Dated note `(YYYY-MM-DD …)` / `User-locked YYYY-MM-DD` | `20\d{2}-\d{2}-\d{2}` | STRIP |
| P5 | `pre-YYYY-MM-DD pattern` / "the pre-DATE pattern" | `pre-20\d{2}-\d{2}-\d{2}` | STRIP |
| P6 | "carried from …" / "carry-over" provenance | `carried from\|carry-over` | STRIP |
| P7 | changelog-style narration of past events ("X was added because…", "this fixed the … incident") | prose | STRIP (move force to principle) |
| P8 | incident/commit-SHA references in a rule | `commit `+SHA, `incident`, `19g-pack` | STRIP |
| **L1** | **`until BD-NNN` / `as of BD-NNN`** (transitional clause) | `until BD-\d+`, `as of BD-\d+` | **KEEP if live** (forward-pointer) |
| **L2** | **`deferred — BD-NNN` / `blocked on BD-NNN` / `coordinate BD-NNN` / `= BD-NNN`** | live cross-ref | **KEEP** (points to live anchor) |
| **L3** | **`maintenance-docs/.../ARCHITECTURE-BD-NNN.md` path ref** | doc path | **KEEP** (live doc cross-reference) |

### THE CRITICAL DISTINCTION (flag for architect): historical-provenance (STRIP) vs live-cross-reference (KEEP)
A `BD-NNN` token is **NOT uniformly strippable.** Split by what it points at:
- **Historical-provenance (STRIP)** — narrates a COMPLETED past action: "BD-203 deleted pack-ops/BACKLOG.md", "BD-101 added three gates", "BD-135 renamed the colliding …", "User-locked 2026-05-30 during BD-195 Step-7 recovery". The rule stands without it; the history lives in changelog/backlog.
- **Live-cross-reference (KEEP)** — points at LIVE future/deferred/blocked/doc-path work the agent must act on: "mirror … until BD-206 retires", "tracker mode is deferred — BD-214", "Codex/Antigravity = BD-217", "per `ARCHITECTURE-BD-182.md` canonical table". Removing these loses operational meaning (violates the no-meaning-loss bar).
- **Architect implication (measure-then-bound):** the grep-zero gate must target P1–P8 shapes and carry a MEASURED allowlist of L1–L3 live forward-pointers — not a blanket `BD-\d+` → zero (which would strip live anchors and break the no-meaning-loss AC).

### Per-doc historical/audit content (IN set; volume + notable file:line evidence)
Measured @ `a847f12`. Pack-side carries essentially ALL of it; project-side is near-clean.

**Pack-side (history-heavy):**
| Doc | BD/TD refs | dated | Notable evidence (file:line) | Character |
|---|---|---|---|---|
| `pack-ops/PACK-MEMORY-RATIONALE.md` | 58 | 12 | L208 `original incident BD-169 19g-pack, 2026-05-16`; L214/244/275/308/332 `User-locked 2026-05-30 during BD-195 Step-7 recovery`; L498 `BD-135 renamed the colliding tracker.toml.example`; L538 `the 2026-05-17 incident where commit 667d2dd shipped`; L545 `2026-05-19 incident where BD-175 Phase 5 Commit 8 4120d19`; L605 `the pre-BD-208 convention` | HEAVIEST. Dated incident narration in every `## slug` **Why:** block (P4/P8). Surgical strip per Q1. |
| `pack-ops/MERGE-STRATEGY.md` | 23 | 0 | L419 `BD-101 added three verification gates` (P2) | Provenance narration mixed into procedure. |
| `CLAUDE.md` (root) | 20 | 2 | L34/L589 `BD-203 deleted pack-ops/BACKLOG.md + CHANGELOG.md` (P2); L214 `pre-2026-05-15 batches only` (P5); L221 `was the pre-2026-05-16 pattern and produced too much friction` (P5/P7); section anchors `(BD-119)`,`(BD-225)`,`(BD-226)` (P1). LIVE keeps: L595 `until BD-206`, L598/610/766 `deferred — BD-214`, L420/429/450/464/477 `BD-217` (L1/L2). | Mixed: strip P1/P2/P5, KEEP L1/L2. |
| `AGENTS.md` / `GEMINI.md` (root) | 11 / 11 | 2 / 2 | Mirror of CLAUDE.md (trinity) — same P2 `BD-203 deleted` (AGENTS L36, GEMINI L32), same P5 `pre-2026-05-16` (AGENTS L223, GEMINI L190). | Trinity-locked with CLAUDE.md. |
| `pack-ops/OPTIONAL-FEATURES.md` | 13 | 0 | per-feature BD provenance tags (P1) | Mixed. |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | 12 | 0 | BD provenance tags (P1) | Mixed. |
| `backlog/_rules.md` | 12 | 0 | BD refs in contract prose (mix of P1 + example tokens) | Verify each (some `BD-NNN` are format examples → KEEP). |
| `pack-ops/PACK-CHAT.md` | 8 | 1 | provenance + 1 dated note | Mixed. |
| `pack-ops/PACK-AGENTS.md` | 4 | 0 | provenance tags (P1) | Light. |
| `pack-ops/DRY-RUN-MIGRATION.md` | 4 | 0 | provenance (P1) | Light. |
| `changelog/_rules.md`, `backlog/_intro.md`, `HELP-FRAGMENT-*` | 1–3 each | 0 | scattered (P1 / example tokens) | Light; verify example-vs-provenance. |
| `pack-ops/BOUNDARY-DEFINITION.md` | 0 | 0 | — | CLEAN of history (bloat-axis only). |
| pack skills (11), pack agents (5) | per-file census pending architect | low | (not individually enumerated — low BD density observed) | Mostly bloat-axis. |

**Project-side (history near-clean — major scoping finding):**
- project trinity (3): **BD/TD=0, dated=0** — clean.
- `docs/pack/*.md` (6): only `PM-CHAT.md` L764 `TD-031 is unblocked … promote to phase-7.4` = a worked-EXAMPLE token (KEEP, illustrative); `PACK-FEEDBACK.md` L156 `Status: Ready (2026-06-15)` = format EXAMPLE (KEEP).
- prompts (10): BD/TD=0. skills (37): BD/TD=0. `.claude/agents` (16): 0. `.agents-plugin` (16): 0. `.codex/agents` (16 toml): 0.
- `docs/project/*/_*.md` (7): only `backlog/_rules.md` L14 `^TD-\d+\.md$` = grammar spec (KEEP); `_intro.md` `TD-NNN` = placeholder tokens (KEEP).
- **Conclusion: project-side historical/audit strip ≈ EMPTY.** The shipped surface is kept clean by the existing pack-self-ref boundary rule. BD-243's project-side work is the BLOAT axis (Task D) almost exclusively.


---

## TASK D — BLOAT INVENTORY (for the architect's terseness/structure bar)

Bloat is the DOMINANT axis (esp. project-side, where history ≈ empty). Four bloat types observed:

### B-type 1 — mega-bullet run-on rules (worst offender, pack-root memory)
- pack `CLAUDE.md`: **52 top-level memory rules** in 768 lines. The single `graph-first-context` bullet = **5,274 chars** (one bullet); `Sub-agent isolation`, `Record every spawn`, `Pack Chat does MINOR edits only` are comparably massive. Each packs multiple clauses + parentheticals + cross-CLI notes into one unstructured paragraph.
- Same shape mirrored in root `AGENTS.md` (643 lines) / `GEMINI.md` (632 lines).
- **Architect lever:** convert clause-dense rule prose → structured form (sub-bullets / tables) WITHOUT deleting any contract clause (Q4 meaning-loss risk). Highest token-per-read payoff in the repo.

### B-type 2 — prose that should be a table
- pack `CLAUDE.md` "commit-subject scope-keyword" already IS a table (good) but many adjacent rules narrate enumerable cases in prose (e.g. the denied-git-verb set in `agents-never-commit` is a comma-run of ~30 verbs in prose → list/table candidate).
- project trinity + agent defs: repeated "Rules in force" / permission-profile prose across 49 agent-def files — high cross-file repetition (structure + dedupe candidate, but watch the `x-` client contract + tri-family parity).

### B-type 3 — verbosity / hedging / restatement
- `pack-ops/PACK-MEMORY-RATIONALE.md` (764 lines): each `## slug` restates the imperative then re-argues it at length — much is persuasive padding beyond the operational Why. (Also the Q1 history-strip target.)
- `pack-ops/MERGE-STRATEGY.md` (505 lines), `OPTIONAL-FEATURES.md` (576 lines): long explanatory prose around short operative steps.
- Trinity sub-agent rules: heavy parenthetical hedging ("(Codex/Antigravity async spawning is implicit/platform-native, not a named parameter)") repeated across several rules.

### B-type 4 — cross-file duplication (tri-family + trinity)
- 49 agent-def surfaces (16 Claude .md + 16 Antigravity .md + 16 Codex .toml + RUNTIME) carry near-identical boilerplate per role across families → repetition cost ×3.
- Trinity (×2 locations × 3 files) duplicates rules by design (parity) — NOT dedup-able (trinity rule), but each copy carries the same bloat, so a terseness pass multiplies savings ×3 (and must stay parity-locked).

### Project-side bloat sizing (line totals, @ a847f12)
- trinity: 478 + 454 + 514 = 1,446
- docs/pack (6): 2,738 ; prompts (10): 1,316
- skills (37): 3,635 ; .claude agents (16): 1,818 ; .agents-plugin agents (16): 1,613 ; .codex toml (16): 884
- **Project-side operating-doc total ≈ 13,450 lines** — the bulk of the BD-243 terseness surface (history ≈ 0 here).

### Pack-side bloat sizing (selected, lines)
- root trinity: 768 + 643 + 632 = 2,043 ; PACK-MEMORY-RATIONALE 764 ; OPTIONAL-FEATURES 576 ; PACK-CHAT 515 ; MERGE-STRATEGY 505 ; CONCEPTUAL-REVIEW 298 ; PACK-AGENTS 284.

**Architect sizing takeaway:** history-strip is a pack-side surgical job (~6 heavy files); bloat/terseness is a both-surface job dominated by project-side line volume (~13.5k lines) + the pack-root mega-bullets. The new governance rule's anti-bloat clause has the larger ongoing blast radius than its no-history clause.

---

## EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, date 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EE-1 — Operating-doc enumeration.**
Cmds: `ls CLAUDE.md AGENTS.md GEMINI.md`; `ls pack-ops/*.md`; `ls backlog/_*.md changelog/_*.md`; `ls .claude/skills/*/SKILL.md`; `ls .claude/agents/*.md`; `find project-template -path '*/skills/*/SKILL.md'`; `ls project-template/{.claude,.agents-plugin/.../agents,.codex}/agents/*`; `find project-template/docs/project -name '_*.md'`; `ls supporting-docs/*.md`.
Output (verbatim counts): pack-ops=10 .md; pack skills=11; pack agents=5; bl/cl meta=4 (+2 _toc generated); project skills=37; project .claude/agents=16 .md; .agents-plugin agents=16 .md (+RUNTIME-SUBAGENT-PATTERN.md); **.codex/agents=16 .toml (NO .md)**; docs/project meta=7; supporting-docs=9.
Interpretation: candidate ~150 confirmed; Codex family is TOML; RUNTIME doc added; skills=37 not 36.
Conclusion: **SUPPORTED** — definitive set = ~145 IN (33 pack + 112 project).

**EE-2 — Pack-side historical density.**
Cmd: per-file `grep -coE 'BD-[0-9]+|TD-[0-9]+'` and `grep -coE '20[0-9]{2}-[0-9]{2}-[0-9]{2}'` over trinity + pack-ops + bl/cl meta.
Output (verbatim): PACK-MEMORY-RATIONALE BD/TD=58 dated=12; MERGE-STRATEGY=23/0; CLAUDE.md=20/2; AGENTS=11/2; GEMINI=11/2; OPTIONAL-FEATURES=13/0; CONCEPTUAL-REVIEW=12/0; backlog/_rules=12/0; PACK-CHAT=8/1; PACK-AGENTS=4/0; DRY-RUN=4/0; HELP-FRAGMENT-PACK=3/0; BOUNDARY-DEFINITION=0/0.
Interpretation: history concentrated in ~6 pack files; RATIONALE heaviest.
Conclusion: **SUPPORTED**.

**EE-3 — Project-side historical density ≈ 0.**
Cmd: `grep -rhoE 'BD-[0-9]+|TD-[0-9]+'` aggregated over prompts/skills/.claude-agents/.agents-plugin/.codex/docs-project-meta; trinity per-file.
Output (verbatim): prompts=0; skills=0; .claude/agents=0; .agents-plugin=0; .codex/agents=0; docs/project meta=1 (`^TD-\d+\.md$` grammar); trinity=0/0 each; docs/pack PM-CHAT=1 (`TD-031` example), PACK-FEEDBACK dated=1 (`(2026-06-15)` format example).
Interpretation: the few hits are template tokens/examples, not provenance.
Conclusion: **SUPPORTED** — project-side history-strip ≈ empty; bloat-axis only.

**EE-4 — Provenance-vs-live split exists.**
Cmd: `grep -nE 'BD-[0-9]+'` on CLAUDE.md; `grep -rnE 'until BD|deferred — BD|BD-217'`.
Output (verbatim): historical `BD-203 deleted …` (L34/L589), `BD-101 added three verification gates` (MERGE-STRATEGY L419); live `until BD-206` (L595), `deferred — BD-214` (L598/610/766), `= BD-217` (L420/429/450/464/477).
Interpretation: both shapes coexist in the same files.
Conclusion: **SUPPORTED** — grep-zero must be shape-targeted + allowlisted (measure-then-bound).

**EE-5 — Bloat sizing.**
Cmd: `wc -l` per doc/category; `sed -n '692,766p' CLAUDE.md | wc -c`; `awk` memory-rule count.
Output (verbatim): graph-first bullet=5,274 chars; pack CLAUDE.md=52 memory rules/768 lines; project operating-doc total ≈13,450 lines; PACK-MEMORY-RATIONALE=764 lines.
Interpretation: bloat dominant + structurally convertible.
Conclusion: **SUPPORTED**.

**EE-6 — Encoding surfaces.**
Cmd: `grep -niE 'trinity|pack.memory|rationale|Check 45|Check 16|Check 18|Check 19'` over scripts/validate-pack.py; `find` for ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md.
Output (verbatim): Check 16/18/19 (trinity H2/parity/scaffolding), Check 45 (rule↔rationale bijection, cites ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2), Check 11 (pack agent symmetry), Check 1 (SKILL frontmatter); concision doc exists at `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`. No body-history validator exists.
Interpretation: structural asserters constrain the pass; net-new grep-zero history gate required.
Conclusion: **SUPPORTED**.


---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only git verb run: `git rev-parse HEAD` → `a847f12…` (read-only). No add/commit/push/checkout/etc. Sole write = this research doc via `cat >>`/`cat >` to `/tmp/pack-handoff-bd243-research/RESEARCH-BD-243.md`. No repo-file edits; no patch. | COMPLIANT |
| **empirical-evidence-blocks** | EE-1…EE-6 each carry: command run + verbatim output (counts/file:line) + runtime HEAD `a847f12` + date 2026-06-21 + interpretation + SUPPORTED conclusion. Every state-claim (set size, density, split, bloat, encoding) is backed. | COMPLIANT |
| **researcher-maps-blast-radius-before-architect** | Task B enumerates the COMPLETE IN set (~145) verified against the live tree via `find`/`ls`/`grep`; corrected the candidate (Codex=.toml, +RUNTIME doc, skills=37, supporting-docs reclassified). Encoding surfaces (Checks 16/18/19/45/11/1 + trinity + tri-family) enumerated. | COMPLIANT |
| **external-rules-census-before-design** | Task C enumerates the COMPLETE pattern set P1–P8 (strip) + L1–L3 (keep) BEFORE the architect's strip recipes, with the historical-provenance-vs-live-cross-reference distinction flagged + per-doc volume census. | COMPLIANT |
| **graph-first-context** | Discovery query run FIRST: `graphify query "...operating docs vs reference..." --graph /Users/.../graphify-out/graph.json --backend claude-cli --budget 1500` (29 nodes; surfaced the agent-def families). Graph noted STALE (no BD-243; stale on deletions) → every exact-state claim verified via grep/Read/git. Injected absolute path used verbatim; QUERY only, never built. | COMPLIANT |
| **enumerate-encoding-surfaces** | Enumerated all surfaces that ENCODE doc state: validate-pack Checks 16/18/19 (trinity H2/parity/scaffolding), 45 (rule↔rationale bijection), 11 (agent symmetry), 1 (SKILL frontmatter); trinity parity (×2 locations); tri-family agent-def lock (Claude .md / Antigravity .md / Codex .toml); prior ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md. New-rule surface = 6 trinity files + architect-decided. | COMPLIANT |
| **filename-uniqueness-heuristic** | Output `RESEARCH-BD-243.md` in `/tmp/pack-handoff-bd243-research/` — BD-243-unique; no collision with repo files (BD-243 is new). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |

**END — RESEARCH-BD-243.md**
