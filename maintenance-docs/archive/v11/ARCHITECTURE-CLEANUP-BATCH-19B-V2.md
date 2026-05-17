# ARCHITECTURE-CLEANUP-BATCH-19B-V2 — Revised strategy after research + fresh second-architect pass

**Author:** pack-architect (second pass — fresh architect, no inherited context from first pass)
**Date:** 2026-05-16
**Branch:** v11-dev (HEAD `cd8246c` — Batch 19 complete)
**Ship target:** v11.0 (unlaunched; per OQ-7/OQ-8)
**Scope:** pack-self only (per OQ-3 — no project-template trinity edits in this batch)
**Status:** Final strategy doc; planner-ready when D-1 through D-9 (see §H) are accepted.

This pass was explicitly empowered to challenge both the first architect's design decisions and the researcher's findings. Disagreements are surfaced in §A; where I agree with the first architect, that is also stated explicitly so silent absorption is not mistaken for endorsement.

---

## 1. Summary

This strategy doc triages 40 cleanup inputs (PC-1..PC-13, PC-uncertain-a..b, V11-1..V11-19, SC-1..SC-3, L1..L9, L8.1) against the current pack-repo trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), `PACK-CHAT.md`, `PACK-AGENTS.md`, `EXECUTION-PLAN-V11.0.md` §B, and the Claude-side memory cache (currently 29 entries enumerated in `~/.claude/projects/<slug>/memory/MEMORY.md`).

The research report confirms what the first architect suspected: trinity files are the only universal cross-CLI rule surface. Codex memories are opt-in + regionally restricted + opaque-format; Gemini has no separate per-project memory cache (memory IS the GEMINI.md hierarchy). Sub-agent peer messaging is confirmed-absent in Codex (issue #12462) and Gemini (hub-and-spoke architecture); the SECURITY WARNING transcript classifier is Claude-Code-only.

**My design choice — trinity-first, single-tier-of-truth.** The first architect proposed a three-tier model (Tier 1 trinity authoritative, Tier 2 tool-native memory caches mirroring trinity, Tier 3 tool-specific exemptions). Given the research shows Tier 2 is structurally infeasible for Codex (opaque) and Gemini (no cache), I am collapsing the model to **two tiers**: Tier 1 = trinity (single source of truth, cross-CLI), Tier 1.5 = Claude-Code memory index (pure pointer file — one line per trinity-anchored rule, NO body text, NO contradictions possible by construction). This is simpler than the first architect's design and structurally enforces "trinity is the only place rules live."

**Critical decisions / call-outs:**

- **OQ-1 (EXECUTION-PLAN §B) — Rewrite §B substantively** per user's nuanced rule: fix-now default; new BDs only when (a) huge scope, (b) blocker, or (c) better-fit-with-an-existing-BD-which-is-edit-not-open; **all new-BD-opens require Pack-Chat-discussion-and-user-approval**. Specific BEFORE/AFTER text in §B (item PC-1).
- **OQ-4 (PACK-AGENTS.md L8 cross-ref) — DO add cross-ref**, per §C decision. Specific text in §E.
- **L8 cross-CLI propagation — Hybrid trinity bullet**: PREFLIGHT (platform-neutral) lives in shared trinity; STOP-MEANS-STOP enforcement carries Claude-Code-specific note within the same bullet. PACK-AGENTS.md cross-ref points to both. Per §C decision.
- **OQ-6 (Cleanup batch archive timing) — Archive at end of Batch 19b** as explicit final commit, per user's (a) confirmation. Specific planner step in §H.
- **Challenge of V11-8 NEW BD recommendation** — I reclassify V11-8 from NEW-BD to NEW-HOME (one short PACK-CHAT.md bullet); per OQ-1, even if it stays NEW-BD, opening BD-173 now requires user-discussion-and-approval (it does not auto-open). §G covers the ripple.
- **Challenge of first architect's Tier 2 design** — collapse to Tier 1.5 pointer-only Claude cache; §D covers the rationale and design.
- **Challenge of first architect's NEW `### Pack Chat scope` sub-section creation** — I keep the new sub-section but with a stricter content rule (rules about WHO does work, not WHAT work). §I covers the restructure.

**Counts (40 items total) — my classifications:**

| Category | Count | Delta vs first architect |
|---|---|---|
| KEEP AS-IS | 8 | same |
| STRENGTHEN WORDING | 6 | +1 (PC-uncertain-a stays STRENGTHEN; I added V11-15 specific edit) |
| CONSOLIDATE | 3 | same |
| REDIRECT | 4 | same |
| PROMOTE (Claude-memory → trinity) | 11 | same as first architect's count |
| DISCARD | 2 | +1 (PC-12 reclassified to DISCARD per its own no-threshold logic; first architect had it as CONSOLIDATE but called it DISCARD in prose) |
| NEW HOME NEEDED | 6 | -1 (V11-8 reclassified from NEW-BD to NEW-HOME) |
| NEEDS NEW BD | 0 | -1 (V11-8 reclassified; no new BDs opened in this cleanup batch) |

Sum = 40.

---

## §A — Disagreements with the first architect

I challenge the following first-architect decisions. Where the disagreement is substantive, I state the rationale and the new conclusion in this section, and the per-item triage in §B carries the resulting text.

### A.1 — Tier 2 (tool-native memory caches) is wrong design under research findings — CHALLENGE

**First architect's design (§3.3):** Three-tier model. Tier 2 = each CLI's native memory surface carries a one-line-per-rule index pointing to trinity anchors.

**Why I challenge this:** The research shows Codex memories are (a) opt-in, (b) not available in EEA/UK/CH, (c) opaque generated state per official guidance ("don't rely on editing them by hand"), and (d) have no documented MEMORY.md-style index file. Gemini has no separate per-project memory cache at all. Designing a Tier 2 for those CLIs would require either (i) shipping a non-canonical convention that contradicts the upstream tool's docs, or (ii) treating "trinity is the cache" as the Codex/Gemini story — but then there is no Tier 2 for them, which means the three-tier model is really a one-and-a-half-tier model in practice.

**My conclusion:** Collapse to two tiers. Tier 1 = trinity (authoritative, cross-CLI, user-edited). Tier 1.5 = Claude-Code memory cache (pure pointer file — title + one-line summary + trinity anchor link; NO body text; NO standalone rules). Codex and Gemini have no Tier 1.5 — trinity is the only surface they see. This is structurally simpler and matches what the platforms actually support.

**Implication:** The Claude memory index becomes mechanically derivable from trinity; if it ever drifts, trinity wins. This eliminates the "memory and trinity can disagree" failure mode by construction.

### A.2 — V11-8 should not be NEW-BD; promote to NEW-HOME — CHALLENGE

**First architect's recommendation (§2 V11-8 row):** Open BD-173 (single-BD vs multi-BD batch-close commit-shape convention) inserted immediately after Batch 19b cleanup.

**Why I challenge this:** Per OQ-1 (user's 2026-05-16 nuance), opening a new BD now requires Pack-Chat-discussion-and-user-approval — it is no longer the architect's binding recommendation. And per the first architect's own size argument ("≤30 lines of doc + cross-link"), V11-8 is mechanical-edit-sized, not architect-pass-sized. The first architect's justification ("worked pattern with two distinct shapes" makes it NEW-BD not NEW-HOME) doesn't hold: PACK-CHAT.md can carry a 6-line bullet describing both shapes inline. That is exactly the role of `## Behavioral rules`.

**My conclusion:** Reclassify V11-8 as NEW-HOME — add a bullet to PACK-CHAT.md `## Behavioral rules` covering both batch-close shapes. No new BD opened. Specific text in §B (V11-8 row).

**Note:** If user prefers BD-173 over inline coverage, this becomes a user-discussion-and-approval item per OQ-1. My architect recommendation is NEW-HOME because it is the smaller scope under `feedback_deferral_is_scope_creep`.

### A.3 — PC-12 should be DISCARD, not CONSOLIDATE — CHALLENGE (label correction)

**First architect's classification (§2 PC-12 row):** CONSOLIDATE.

**Why I challenge this:** The first architect's own prose for PC-12 says "PC-12 contradicts the standing rule and should be DISCARDED in favor of the memory's explicit no-threshold posture. The cleanup batch must NOT codify a tiny-fix carve-out." That IS a DISCARD verdict, not a CONSOLIDATE verdict (consolidate implies the content is preserved under a different anchor; discard means the content is rejected). Label mismatch.

**My conclusion:** PC-12 is DISCARD. The pack-coder's instruction file (PLAN-CLEANUP-BATCH-19B) carries no PC-12 edit at all; the existing `feedback_pack_chat_does_no_fixes` memory's "no threshold exception" wording is the standing rule and the cleanup batch reaffirms it rather than weakening it.

### A.4 — V11-15 needs specific find-replace text, not a "sweep" — CHALLENGE (specificity)

**First architect's recommendation (§2 V11-15 row):** "Sweep for any stale `IMPLEMENTATION-PLAN-V11.0.md` references across pack-ops docs."

**Why I challenge this:** "Sweep" is not specific text. The pack-coder needs explicit grep targets and replacement strings. I produce them in §B (V11-15 row) — `grep -RIn 'IMPLEMENTATION-PLAN-V11.0.md' .` is the find verb, replacement is `EXECUTION-PLAN-V11.0.md`, scope is `supporting-docs/`, `maintenance-docs/`, and any pack-ops template-string carriers Pack Chat uses.

### A.5 — L9 (architect-doc-vs-reality reconciliation) needs trimmed wording, not extension — CHALLENGE

**First architect's recommendation (§2 L9 row, also §3.5 mapping):** PROMOTE to a new trinity `### Repo conventions` bullet with worked example "BD-119 §9.2 addendum → migrator-core.sh:505-518 → IMPLEMENTATION-REPORT-BD-160-170.md:38."

**Why I challenge this:** Per the user's `feedback_filename_uniqueness` memory and the recurring concern about trinity bloat (Gemini's GEMINI.md has a "Keep this file concise — it is loaded into every prompt" header), bullet text with file:line citations grows the trinity faster than principle-only bullets. Also, file:line citations are exactly what the user's memory warns drifts ("Line numbers drift with every edit; symbol names are stable" — from `project-template/CLAUDE.md` § Deferral comments line 326).

**My conclusion:** Promote the PATTERN to trinity; KEEP the worked example in `ARCHITECTURE-BD-119.md` §9.2 addendum (already there, it is the worked example). The trinity bullet names the pattern in 3 lines; the worked example anchor is named-by-doc not file-line. Specific text in §B (L9 row).

### A.6 — First architect missed that L4 + PC-10 + L5 are the SAME rule under three skins — PARTIAL CHALLENGE

**First architect's design:** L4 (architect-first for rules), PC-10 (architect-spawn needs user approval), L5 (Pack Chat presents triage to user before fix-coder spawns) each get their own bullet — L4 and PC-10 under new `### Pack Chat scope`, L5 by extending `feedback_pack_chat_does_no_fixes`.

**Why I partially challenge this:** L4 and PC-10 ARE the same rule restated. L4 says "spawn architect first for rules work"; PC-10 says "don't auto-spawn architect — wait for user approval." Both say the same thing from different angles: an architect spawn for rules-work is a user-discussion-and-approval event, NOT a Pack-Chat-direct decision. Treating them as two bullets duplicates the rule.

**My conclusion:** Merge L4 and PC-10 into one trinity bullet titled "Pack-architect spawn protocol" — covers both the rules-work-needs-architect AND the user-approval requirement in 3 lines. L5 stays separate (it is about per-BD review/fix triage flow, not architect spawning) and goes into the `### Workflow` extension as one bullet, NOT into a new sub-section. This drops the first architect's new `### Pack Chat scope` sub-section from 4 entries to 2 (commit-approval next-steps + the merged architect-spawn rule). I keep the new sub-section because it has stable content (Pack Chat orchestrator scope) but with fewer entries.

### A.7 — First architect under-specified PC-uncertain-a (cross-ref wording) — CHALLENGE (specificity)

**First architect's recommendation (§2 PC-uncertain-a row):** "STRENGTHEN by adding a one-line cross-reference in the trinity Pack-memory section explicitly naming the sub-agent extension."

**Why I challenge this:** "Add a one-line cross-reference" without specific text leaves it to the pack-coder to invent. I produce the specific text in §B (PC-uncertain-a row).

### A.8 — First architect's Project-template trinity ripple (D-8) is out of scope per OQ-3 — CHALLENGE (drop)

**First architect's D-8 (§7):** Decision on whether project-template trinity (client-side) also gets the L9 architect-doc-vs-reality reconciliation pattern.

**Why I challenge this:** Per OQ-3 (user confirmed 2026-05-16): "This work should be for the config pack self maintenance for now. At some point we need to have a discussion on what should be transferred to the project side and how it should be integrated." Project-template trinity is explicitly out of scope for this batch. The first architect surfaced D-8 as a pending question, but per OQ-3 the answer is "not in this batch" — period.

**My conclusion:** Drop D-8 entirely. Project-template trinity edits are a separate future effort, not a Batch 19b deliverable. Surface this as an explicit out-of-scope item in §M with a forward-pointing note.

### A.9 — First architect's V11-19 client-side trinity propagation also out of scope per OQ-3 — CHALLENGE (drop)

**First architect's recommendation (§2 V11-19 row):** "RECOMMEND: add a one-line bullet to pack-repo CLAUDE.md / AGENTS.md / GEMINI.md `## Pack memory > Repo conventions`: 'Code-comment deferrals in pack-repo source follow the same typed format as project-template/CLAUDE.md § Deferral comments — never plain English `// TODO` or `// fix later`.' Trinity propagation."

**Why I partially challenge this:** The first architect's text is FINE for the pack-repo trinity bullet (that part is pack-self, in scope). What I disagree with is the framing as "Trinity propagation" — that wording implies project-template trinity is involved. Per OQ-3 it isn't. The pack-repo trinity adds a one-line bullet that POINTS to the project-template's existing convention as the canonical typed format — but does NOT edit project-template trinity in this batch.

**My conclusion:** Keep the pack-repo trinity edit. Drop the "Trinity propagation" wording. Specific text in §B (V11-19 row).

### A.10 — Where I AGREE with first architect (explicit endorsements)

The following first-architect decisions I reach the same conclusion on:

- **Trinity-first design** (§3.2 user's lean) is correct and structurally supportable.
- **PC-1 (EXECUTION-PLAN §B reconciliation)** needs §B language rewritten — though I produce specific text below per OQ-1 nuance.
- **PC-5 (sidecar hard-stop session directive)** is DISCARD (already honored, no standing rule needed).
- **PC-3 (audit IS the review)** is KEEP with one-sentence §B clarification.
- **PC-4 (Agent Teams stage-lifecycle)** is KEEP and PROMOTE to trinity with Trinity exemption (Claude-Code-specific by construction per research).
- **V11-4 (lean to v11.0)** is KEEP and PROMOTE — `feedback_no_deferral_without_user_direction` is the authoritative entry.
- **V11-5 (push to v11-dev only)** is NEW-HOME in PACK-CHAT.md — short-lived but load-bearing right now.
- **L1, L2, L3, L6, L7, L8 dispositions** — all reasonable. L3 needs the wording strengthening the first architect proposed.
- **CLEANUP-INPUTS-* and PACK-REVIEW-*-RETRO.md and IMPLEMENTATION-REPORT-*-RETRO-FIX.md** all belong in the trinity workflow-artifacts list (L7 / V11-9).
- **OQ-6 archive-at-batch-end** is correct (per user's (a) confirmation).


---

## §B — Per-item triage with BEFORE/AFTER text

This is the complete table. Where the first architect's text is sound I keep it (and say so); where text was directional I produce specific text; where I disagree with the category I re-classify with rationale.

Item IDs match the source-section codes from `CLEANUP-INPUTS-SESSION-RULES.md`. Categories: KEEP / STRENGTHEN / CONSOLIDATE / REDIRECT / PROMOTE / DISCARD / NEW-HOME / NEW-BD.

### PC-1 — EXECUTION-PLAN §B "no new BDs" reconciliation (STRENGTHEN; obsolete-text rewrite)

**Current §B text** (EXECUTION-PLAN-V11.0.md lines 331-355, verbatim, abbreviated for context here):
> Every audit/review pass that produces findings is fixed *in the current session*. No fix-follow BDs are opened. ... **BDs are reserved for new scope, new features, and new architecture — never for closing audit findings. Only the user can initiate a BD-for-fix conversation; Pack Chat must not propose one.**

**Replacement §B text (FULL section, replace lines 331-355):**

```
### B. Audit / review-fix protocol (user rule, 2026-05-11; revised 2026-05-16 per OQ-1)

1. Every audit/review pass that produces findings is FIX-NOW by default
   in the current session. Pack Chat does not propose deferral (per
   `feedback-deferral-is-scope-creep` in `## Pack memory`).

2. Pack Chat reports findings to the user (severity-grouped: MUST /
   SHOULD / NIT), presents a fix-vs-skip triage per finding (with
   rationale for SKIPs), and waits for triage approval. Per
   `feedback-pack-chat-does-no-fixes`, Pack Chat does NOT apply the
   fixes itself — a fix-coder agent does, running in the background
   after user approves the triage.

3. With user approval, fix-coder lands the fixes in the same batch's
   commit, or in a small follow-up commit Pack Chat proposes and the
   user approves.

4. After review fixes land and validator/CI is clean, status flips
   per the implicit-flip rule (§C.4).

5. **New-BD-opens require user-discussion-and-approval.** When a
   review/audit finding might warrant a new BD, Pack Chat surfaces the
   finding AND its candidacy for a new BD to the user — but does NOT
   open the BD. New BDs are opened only when (a) the work is too large
   for in-place fix (architect-pass material), (b) blocked by a
   not-yet-landed dependency, or (c) belongs cleanly with an existing
   BD (in which case the existing BD is EDITED, not a new one opened).
   In all three cases, user discussion and approval is required before
   any BD is opened or edited. Pack Chat must not pre-frame "should we
   open a BD?" as a default choice — the default remains fix-now.

6. If a new BD IS opened with user approval per (5), it is inserted
   IMMEDIATELY AFTER the current BD or batch (unblocked) or at the
   unblock point (blocked) — never parked at the end of v11.0, never
   "next batch" with no anchor.

**Historical context:** the prior §B text (pre-2026-05-16) said "No
new BDs are opened for audit findings" as a flat rule. Per the
`feedback-deferral-is-scope-creep` memory revision, the rule narrowed:
unblocked-new-scope from audits DOES open a BD inserted-immediately-
after. Per the OQ-1 nuance (2026-05-16), the new-BD-open additionally
requires user-discussion-and-approval. Together: fix-now default; new
BDs are an exception requiring (size or block or fit) AND user
approval.
```

**Rationale for replacement (not addendum):** the user's 2026-05-16 nuance is substantive enough that an addendum would leave Pack Chat reading two conflicting paragraphs in §B. Replacement is cleaner.

### PC-2 — Reviewer stop-for-fix-discussion (NEW-HOME)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules`.

**Specific BEFORE/AFTER:**

INSERT after the existing "Verify staged files before committing" bullet (line 64 of PACK-CHAT.md):

```
- **Stop after every reviewer pass for triage discussion.** After every
  pack-reviewer run, Pack Chat STOPS, surfaces the findings (severity-
  grouped) to the user, and waits for triage approval — even if the
  reviewer verdict is fully clean. No auto-commit on clean verdicts.
  This is distinct from the implicit-BD-status-flip rule (which fires
  AFTER all per-BD fixes land + tests are green) and from the
  commit-approval rule (which governs the wording of the approval
  ask). The stop point is BEFORE Pack Chat triages — the triage
  itself is surfaced to the user as the first action after the stop.
```

### PC-3 — Audit IS the review (KEEP + §B clarification)

**Action:** Add one clarifying sentence inside the rewritten §B (PC-1) step 4.

**Specific text (already folded into the PC-1 §B replacement above, but isolating the addition here):**

Append to step 4 of the replacement §B: `An audit pass IS the review for that batch; no separate pack-reviewer is run on the audit-fix commit.`

This goes inside the same §B rewrite as PC-1.

### PC-4 — Agent-team / SendMessage stage-lifecycle (KEEP; PROMOTE with Trinity exemption)

**Action:** PROMOTE `feedback_agent_teams_stage_lifecycle` into trinity `### Sub-agent isolation (Claude-only)` sub-section (this sub-section is renamed in §I to `### Sub-agent behavior (Claude-only)` to absorb both isolation AND stage-lifecycle rules).

**Specific text to ADD as a bullet inside the renamed `### Sub-agent behavior (Claude-only)` sub-section:**

```
- **Agent-team stage lifecycle.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled, sub-agents spawned
  for a stage (architect → planner → coder → reviewer) stay alive
  within the stage; Pack Chat uses SendMessage for follow-ups against
  the same instance. After the stage's commit lands, close ALL stage
  sub-agents and respawn fresh for the next stage. Trinity exemption:
  this rule references Agent Teams + SendMessage, which are
  Claude-Code-specific (Codex / Gemini have no peer-messaging
  equivalent — confirmed absent per Codex issue #12462 and Gemini
  hub-and-spoke docs).
```

This is Claude-only by construction — the trinity exemption note IS the parity statement for Codex/Gemini.

### PC-5 — Hard stop point for sidecar work (DISCARD)

**Action:** No standing rule needed. The session-scoped directive was applied at the time. The general "user retains hard-stop authority" principle is already covered by `feedback_no_destructive_without_approval` and `feedback_commit_approval_next_steps`. Both are already in memory and (post-cleanup) in trinity.

**No edit required.**

### PC-6 — Sidecar / primary chat file-ownership boundary (NEW-HOME, consolidates PC-7 + V11-3)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules`.

**Specific BEFORE/AFTER:**

INSERT after the PC-2 bullet (above) in PACK-CHAT.md `## Behavioral rules`:

```
- **Chat-ownership boundaries on concurrent sessions.** When two
  pack-chats run concurrently against the same repo (e.g., sidecar +
  primary; multiple devs; multiple worktrees on the same clone), the
  user assigns file-ownership boundaries; no two chats touch the same
  file. Do not read, edit, or commit files you did not request, write,
  or that were assigned to your scope. When ownership is unclear, ask
  the user — do not guess. This rule subsumes the "don't touch
  v11-research/" and "don't read/commit files you didn't write"
  directives from prior sessions.
```

### PC-7 — Don't touch v11-research files (CONSOLIDATE with PC-6)

**Action:** No separate bullet. Already covered by PC-6's "Do not read, edit, or commit files you did not request, write, or that were assigned to your scope" clause.

### PC-8 — Carry-forward notes need tracked home (KEEP; PROMOTE)

**Action:** PROMOTE `feedback_deferred_work_tracking` to trinity `### Workflow` sub-section.

**Specific text to ADD as a bullet inside `### Workflow` (after the existing "Implicit BD status flip" bullet):**

```
- **Deferred work needs a tracked anchor.** When work is genuinely
  deferred (user-authorized; survives the `feedback-deferral-is-scope-
  creep` size/blocked/fit test), it MUST land on a live forward-pointing
  surface AND be scheduled to a specific anchor: an open BD entry, a
  live `// TODO(scope): TD-TBD` comment in code per `project-template/
  CLAUDE.md` § "Deferral comments and BACKLOG hygiene", or a new BD
  inserted at the appropriate plan position. Archived reports are NOT
  acceptable anchors — work that lives only in an archived doc is lost.
```

### PC-9 — Use next available BD numbers (KEEP + one-sentence STRENGTHEN)

**Action:** STRENGTHEN the existing trinity "BD-NNN numbering" rule.

**Specific BEFORE/AFTER (all three trinity files — CLAUDE.md line 61-63, AGENTS.md line 55-57, GEMINI.md line 45-46):**

BEFORE (CLAUDE.md verbatim):
```
**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
```

AFTER:
```
**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
- Reservation lists from other chats, planning docs, or sidecar
  sessions are NOT authoritative — always read the live BACKLOG before
  assigning. Reserved-but-unwritten numbers are guesses, not commitments.
```

Parallel edits to AGENTS.md (lines 55-57) and GEMINI.md (lines 45-46) per trinity rule. The Gemini version may need a tighter phrasing to honor the "Keep this file concise" header — proposed Gemini text:

```
**BD numbering:** Always read BACKLOG.md to find the highest existing BD
number, then increment by 1. Never assign a BD number from memory or
from another chat's reservation list — reservations are not authoritative.
```

### PC-10 — Pack-architect needs explicit approval before spawning (NEW-HOME, merged with L4)

**Action:** Per §A.6 challenge, merge with L4 into ONE trinity bullet titled "Pack-architect spawn protocol" in the NEW `### Pack Chat scope` sub-section.

**Specific text to ADD as a bullet inside NEW `### Pack Chat scope` sub-section:**

```
- **Pack-architect spawn protocol.** When work touches rules,
  operating docs, memory files, PACK-CHAT.md, PACK-AGENTS.md, or any
  trinity Pack-memory section, spawn `pack-architect` FIRST to design
  a strategy doc; coder applies mechanically after user approves the
  strategy. Pack-architect spawn is NOT a Pack-Chat-direct decision —
  even when scope clearly calls for it, the architect-spawn requires
  explicit user approval. Rationale: an architect pass commits Pack
  Chat to a multi-stage pipeline (architect → planner → coder →
  reviewer) and reorders future BD work; that ordering decision
  belongs to the user. Pack-planner / pack-coder / pack-reviewer /
  pack-docs-researcher follow standard Pack Chat triage (no
  per-spawn user approval).
```

### PC-11 — Researcher → architect → planner → coder pipeline (KEEP; PROMOTE)

**Action:** PROMOTE `feedback_researcher_architect_planner_pipeline` to trinity `### Agent invocation rules` sub-section.

**Specific text to ADD as a bullet inside `### Agent invocation rules` (after the existing "No prior reviews to pack-reviewer" bullet):**

```
- **Researcher-first pipeline for substantive content.** When agent
  work depends on domain knowledge verified against authoritative
  external sources (CLI docs, tool semantics, framework behavior),
  the pipeline is `pack-docs-researcher` → `pack-architect` →
  `pack-planner` → `pack-coder`. Architect runs AFTER researcher,
  not before, not skipped. The same-architect-vs-fresh-architect
  decision for the second architect pass is per-case user
  discussion at the second-pass decision point.
```

### PC-12 — Fix-pass approach varies by content type (DISCARD)

**Action:** Per §A.3 challenge, label is DISCARD (first architect prose said the same, label was mis-set to CONSOLIDATE). The `feedback_pack_chat_does_no_fixes` "no threshold exception" wording stands as the standing rule.

**No edit required.** The cleanup batch must NOT codify a tiny-fix carve-out.

### PC-13 — Pre-commit verification (KEEP; verify byte-equivalence)

**Action:** Already covered by PACK-CHAT.md `## Behavioral rules` "No commit without explicit approval" bullet + EXECUTION-PLAN §A.1. Verify byte-equivalence — they should not drift. If a Pack Chat reads only one, the other must say the same thing.

**Verification step for pack-coder (no source edit unless verification fails):**

```
diff <(grep -A2 "No commit without explicit approval" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md) \
     <(sed -n '325p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md)
```

If the texts diverge in meaning, fix to match. No edit otherwise.

### PC-uncertain-a — Per-action approval applies to sub-agents (STRENGTHEN)

**Action:** Add a specific cross-reference bullet in trinity `## Pack memory` `### Workflow` sub-section.

**Specific text to ADD as a bullet inside `### Workflow` (after the existing "Agents never commit" bullet):**

```
- **Per-action approval extends to sub-agents.** The "no state-changing
  operations without explicit per-action approval" rule applies to
  Claude Code Pack Chat AND every sub-agent it spawns. State-changing
  git verbs are forbidden to all agents per `PACK-AGENTS.md` § "Agent
  permission rules"; destructive file operations (`rm -rf`, `git rm`,
  overwriting trusted files) require Pack Chat to ask the user even
  when the overall task is approved. Sub-agents inherit this rule by
  construction (they write only their report + scoped working-tree
  files; they cannot commit). See `feedback-no-destructive-without-
  approval` for the memory-cache pointer.
```

### PC-uncertain-b — Default sub-agent spawns to background (KEEP; PROMOTE with Trinity exemption)

**Action:** PROMOTE `feedback_spawn_agents_in_background` to trinity renamed `### Sub-agent behavior (Claude-only)` sub-section per §I.

**Specific text to ADD as a bullet inside the renamed `### Sub-agent behavior (Claude-only)` sub-section:**

```
- **Default sub-agent spawns to background.** Every Agent-tool
  invocation from Pack Chat uses `run_in_background: true` so the chat
  stays interactive while the sub runs. User has auto-mode on; the
  background sub will not block the chat. Trinity exemption: this rule
  references the Claude Code Agent tool's `run_in_background` parameter;
  Codex parallel-spawn behavior is implicit (parallel-by-default, capped
  by `agents.max_threads`); Gemini parallel-spawn is implicit via `@`
  invocation. No cross-CLI parity edit needed — each platform's
  parallel-or-async behavior is platform-native.
```


### V11-1 — Real fixes, no band-aids (NEW-HOME)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules`.

**Specific text (INSERT after the PC-6 bullet):**

```
- **Real fixes only — no green-the-test band-aids.** A fix that
  suppresses a failure without addressing the underlying defect is
  itself a defect; the reviewer will flag it. Examples of forbidden
  band-aids: assertion deletion, commenting out a failing test,
  catching+ignoring an exception that masks a contract violation,
  changing a test expectation to match buggy output, adding a sleep
  to mask a race condition. If the fix would require this kind of
  patch, surface the underlying defect to the user and either fix
  the real cause or open a discussion with the user about scope.
  Distinct from `feedback-fix-all-review-findings` (scope of fixes)
  and `feedback-pack-chat-does-no-fixes` (who applies fixes): this
  rule is the depth requirement on whatever fix the coder applies.
```

### V11-2 — Anti-sycophancy / direct opinion (NEW-HOME)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules`.

**Specific text (INSERT after V11-1 bullet):**

```
- **Direct opinion, not validation.** Base analysis on evidence and
  logic; state what you actually think. Do NOT echo the user's framing
  to be agreeable; do NOT pre-anchor to the user's lean before
  evaluating evidence; do NOT pad responses with affirming language
  ("Great question," "You're absolutely right," etc.). When you
  disagree with the user, say so explicitly with the reasoning. The
  user has flagged sycophancy as a recurring failure mode (verbatim
  2026-05-16: "Don't just be complementary. Base your analysis on
  evidence and logic. Tell me what you think."). This rule applies to
  Pack Chat surface (chat replies); agent prompts already enforce a
  related but distinct "no solutions / no biased framing" rule under
  `### Agent invocation rules`.
```

### V11-3 — Don't read/commit files you didn't write (CONSOLIDATE with PC-6)

**Action:** No separate bullet. Already covered by PC-6.

### V11-4 — Lean to v11.0 (KEEP; PROMOTE)

**Action:** PROMOTE `feedback_no_deferral_without_user_direction` to trinity `### Workflow` sub-section.

**Specific text to ADD as a bullet inside `### Workflow` (after the PC-8 bullet above):**

```
- **No deferral to v11.1+ without explicit user direction.** While
  v11.0 is unlaunched, ALL work surfaced during v11.0 development MUST
  land in v11.0 unless the user explicitly authorizes deferral. Pack
  Chat must NEVER propose "defer to v11.1" as a default option in
  user-facing framings. Architect / reviewer / coder defer-
  recommendations are SCOPING signals (often driven by prompt
  boundaries Pack Chat imposed), not AUTHORITY signals — re-scope to
  land in v11.0 and surface the blast-radius to the user. Only the user
  authorizes v11.1+ deferral; this default inverts only on explicit
  user direction ("this is v11.1 work" / "defer this" / "don't block
  v11.0 on this").
```

### V11-5 — Push to v11-dev only (NEW-HOME)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules` mirroring EXECUTION-PLAN §A.4.

**Specific text (INSERT after V11-2 bullet):**

```
- **Push to v11-dev only during the v11-dev phase.** Never push to
  `main` from this chat. v11.0 ships via deliberate handoff at Batch
  24 (the release-pin batch). This rule is short-lived (it resolves
  when v11.0 ships and v11.0 merges to `main`) but load-bearing right
  now. EXECUTION-PLAN-V11.0.md §A.4 carries the same rule for
  agent / planner contexts; PACK-CHAT.md carries it here so Pack Chat
  sees it at every session.
```

### V11-6 — Fresh coder per commit / per batch (STRENGTHEN; consolidate with stage-lifecycle)

**Action:** STRENGTHEN the `feedback_agent_teams_stage_lifecycle` memory wording AND the trinity bullet derived from it (PC-4 above). The promotion text in PC-4 already covers "After the stage's commit lands, close ALL stage sub-agents and respawn fresh for the next stage." I add one explicit extension to that bullet to cover the per-BD-within-a-stage case.

**Specific text — REVISED PC-4 trinity bullet (replaces the version in PC-4 above):**

```
- **Agent-team stage lifecycle + per-commit fresh-coder.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled, sub-agents spawned
  for a stage (architect → planner → coder → reviewer) stay alive
  within the stage; Pack Chat uses SendMessage for follow-ups against
  the same instance. After the stage's commit lands, close ALL stage
  sub-agents and respawn fresh for the next stage. Additionally: each
  pack-coder commit gets a FRESH coder instance — never reuse a coder
  across commits, even within a stage. Per-BD review/fix cycle = fresh
  coder for the implementation, fresh coder for the fix. Trinity
  exemption: Agent Teams + SendMessage are Claude-Code-specific
  (Codex / Gemini have no peer-messaging equivalent — confirmed absent
  per Codex issue #12462 and Gemini hub-and-spoke docs).
```

The memory file `feedback_agent_teams_stage_lifecycle` becomes a Tier-1.5 pointer per §F disposition.

### V11-7 — Scope-extension decision test (NEW-HOME)

**Action:** Add a bullet to PACK-CHAT.md `## Behavioral rules` AND cross-link to existing trinity "One review/fix cycle per batch" bullet.

**Specific text (INSERT after V11-5 bullet):**

```
- **Scope-extension test for in-flight work.** When the in-flight work
  surfaces a SYMMETRIC PAIR or SAME-FEATURE-SURFACE item (the second
  half of the same feature; a sibling action that mirrors the original;
  e.g., link/unlink, create/delete, parser/emitter), extend the current
  BD's scope via SendMessage rather than open a new BD. New BDs are
  reserved for NEW scope, NEW feature, NEW architecture (per trinity
  `## Pack memory` `### Workflow` "One review/fix cycle per batch"
  bullet) — not the second half of a feature already in progress.
  Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open also requires
  user-discussion-and-approval; the scope-extension test exists to
  prevent unnecessary BD-opens in the first place.
```

### V11-8 — Single-BD vs multi-BD batch close (NEW-HOME, not NEW-BD per §A.2 challenge)

**Action:** Per §A.2 challenge, add a bullet to PACK-CHAT.md `## Behavioral rules` covering both shapes inline. No BD-173 opened.

**Specific text (INSERT after V11-7 bullet):**

```
- **Batch close commit shapes.** Single-BD batches: combine the fix
  commit and the status flip into ONE final commit
  (`fix: vN — BD-NNN ... + status flip`). Multi-BD batches: ship the
  fix commit and the status-flip commit as TWO separate commits
  (fix first, then a docs commit flipping all batch BDs at once,
  e.g., `docs: vN — flip BD-NNN/MMM/PPP to Resolved`). Rationale:
  single-BD batches have no cross-BD status state to maintain; multi-
  BD batches benefit from a clean status-flip commit that names every
  flipped BD for audit history. Worked precedents: Batch 17 multi-BD
  split; Batch 18 single-BD combined.
```

If the user prefers BD-173 over inline coverage, this becomes a user-discussion-and-approval item per OQ-1 (and per `feedback-deferral-is-scope-creep` size justification: this is a 6-line bullet, not architect-pass material).

### V11-9 — PACK-REVIEW-BD-NNN-RETRO.md naming convention (STRENGTHEN; trinity workflow-artifact list extension)

**Action:** STRENGTHEN the existing trinity `### Repo conventions` `### Skill and agent maintenance is mechanical by default` bullet (which enumerates workflow-artifact patterns).

**Specific BEFORE/AFTER (CLAUDE.md line 191-200 — verbatim):**

BEFORE:
```
      Workflow artifacts
      (architect/planner/coder/reviewer/auditor outputs:
      `ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`,
      `PACK-REVIEW-*.md`, `AUDIT-*.md`, `RESEARCH-*.md`,
      `*-DISCOVERY.md`) are exempted from the "no new top-level doc"
      structural signal during their batch's active development; they
      sweep to `maintenance-docs/archive/vN/` at version ship as the
      final pre-tag step (Pattern B). Threshold conditions and worked
      examples in `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
      §3.
```

AFTER:
```
      Workflow artifacts
      (architect/planner/coder/reviewer/auditor outputs:
      `ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`,
      `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`,
      `PACK-REVIEW-*.md`, `PACK-REVIEW-*-RETRO.md`,
      `AUDIT-*.md`, `RESEARCH-*.md`, `*-DISCOVERY.md`,
      `CLEANUP-INPUTS-*.md`) are exempted from the "no new top-level
      doc" structural signal during their batch's active development;
      they sweep to `maintenance-docs/archive/vN/` at version ship as
      the final pre-tag step (Pattern B). Threshold conditions and
      worked examples in `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
      §3.
```

Parallel edit to AGENTS.md and GEMINI.md per trinity rule (Gemini's tighter wording is acceptable — same patterns added).

### V11-10 — Retro fix commit-message format (STRENGTHEN; trinity commit-format enumeration)

**Action:** STRENGTHEN the existing trinity "Commit message format" section to enumerate approved `fix:` suffixes.

**Specific BEFORE/AFTER (CLAUDE.md lines 47-53 — verbatim):**

BEFORE:
```
**Commit message format:**
```
feat: vN — BD-NNN short description
fix: brief description of what was corrected
docs: brief description of documentation change
```
Where N is the current major version (read from README.md version table).
```

AFTER:
```
**Commit message format:**
```
feat: vN — BD-NNN short description
fix: brief description of what was corrected
docs: brief description of documentation change
```
Where N is the current major version (read from README.md version table).

**Approved suffixes for the `fix:` form:**
- `fix: vN — BD-NNN brief description` (per-BD inline fix in current batch)
- `fix: vN — BD-NNN ... (Batch N)` (fix attached to a specific batch)
- `fix: vN — BD-NNN ... (Batch Nx)` (fix attached to a sub-batch — e.g., 19b cleanup)
- `fix: vN — BD-NNN retroactive per-BD review-fix (Batch N)` (retro recovery
  of a per-BD cycle missed in a prior multi-BD batch)
- `fix: vN — broad batch review/fix (Batch N)` (end-of-batch cross-BD
  fix that does not bind to a single BD)

Other `fix:` shapes require Pack-Chat-discussion-and-user-approval before
they land — invented commit-message shapes break audit history.
```

Parallel edit to AGENTS.md (lines 41-47) and GEMINI.md (line 38).

### V11-11 — Trial run before scaling (KEEP unwritten)

**Action:** No edit. Tactical pattern, too context-specific to codify cleanly. Pack Chat continues current judgment.

### V11-12 — Retro review prompts source File/Symbol from authoritative sources (REDIRECT)

**Action:** Already exists in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "File/Symbol scope from authoritative sources, not prose recall". 

**Verification step for pack-coder:** Read the existing section, verify wording covers the retro-specific case (sourcing File/Symbol from BACKLOG entry + `git --stat <sha>` rather than prose recall — applies to retro-review prompts specifically, which run against historical commits). If the wording is generic-only and doesn't name the retro case, ADD one paragraph to that section:

```
**Retro-review prompts (per-BD review of historical commits).** When
generating a per-BD review prompt for a commit that has already landed
(retroactive per-BD review-fix per `feedback-review-fix-one-cycle`),
source the File/Symbol scope from (a) the BACKLOG entry's File/Symbol
field for the BD, and (b) `git diff --stat <SHA>` for the commit that
landed the BD. Do NOT source File/Symbol from prose recall of what the
BD touched — prose recall has empirically been wrong (see Batch 21c
BD-112 trial-run incident where prose recall named the wrong file).
```

If the existing wording covers this, no edit. Pack-coder reports which.

### V11-13 — CI-touching work prompts (REDIRECT)

**Action:** Already exists in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "CI-step interrogation heuristic".

**Verification step for pack-coder:** Read the existing section, verify wording covers the must-include-in-prompt aspect. If missing, ADD one sentence at the end of that section:

```
**Must-include-in-prompt rule.** When the BD touches CI workflows
(`.github/workflows/*.yml` or any other CI configuration), the
agent prompt that generates the implementation OR the review MUST
explicitly require the agent to identify, for every new or modified
CI step, a concrete change that would turn it red AND confirm the
wiring would surface that change. Prompts that omit this requirement
have empirically missed CI gaps (BD-118 retro).
```

If the existing wording covers this, no edit.

### V11-14 — Convention/naming docs need finding-mode checklist (REDIRECT)

**Action:** Already exists in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Convention/naming docs review checklist".

**Verification step for pack-coder:** Read the existing section, verify wording is concrete (names the checklist items) and not just a section header. If it is only a header / placeholder, file as STRENGTHEN — but in this batch's scope, only flag for the user; do NOT extend it without an architect pass per L4. The verification check is read-and-report only.

### V11-15 — Reviewer prompt template factual error (NEW-HOME; specific find-replace per §A.4)

**Action:** Per §A.4 challenge, specific find-replace text instead of "sweep."

**Specific text — pack-coder steps:**

```bash
# Step 1: Find all references to the wrong filename across pack-ops docs
grep -RIln 'IMPLEMENTATION-PLAN-V11.0.md' \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/ \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/ \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md \
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md \
  2>/dev/null
```

For each file the grep returns:
- Read the context around each match (3 lines before and after).
- If the reference clearly should be `EXECUTION-PLAN-V11.0.md`, replace.
- If the reference is historical (e.g., in an archived doc explaining why the rename happened), leave it as-is and report.

Pack-coder reports the list of files changed and the list left as-historical.

Note: if Pack Chat carries reviewer prompt templates inline in PACK-CHAT.md or in a `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` (or similar), those template strings are the priority targets.

### V11-16 — Default-to-recommended in AskUserQuestion (KEEP; no edit)

**Action:** Tool-doc default per V11-16's own uncertainty. No edit.

### V11-17 — "approved" without option name (KEEP; no edit)

**Action:** Session inference per V11-17's own caveat. Not load-bearing. No edit.

### V11-18 — AskUserQuestion only for real branch points (KEEP; no edit)

**Action:** Soft preference; boundary is fuzzy; user has not stated this as a rule explicitly. Pack Chat continues current judgment. If it becomes load-bearing across batches, revisit.

### V11-19 — No code-comment carry-forward without anchor (REDIRECT + ADD pack-repo trinity bullet)

**Action:** Per §A.9 challenge, add ONE bullet to pack-repo trinity `### Repo conventions` — NOT to project-template trinity (out of scope per OQ-3).

**Specific text to ADD as a bullet inside `### Repo conventions` (after the existing "Skill and agent maintenance is mechanical by default" bullet):**

```
- **Pack-repo code-comment deferrals.** Code comments in pack-repo
  source (`scripts/`, `proto/`, any non-template source) that defer
  work MUST use the typed format defined in `project-template/CLAUDE.md`
  § "Deferral comments and BACKLOG hygiene" — never plain English
  `// TODO`, `// fix later`, or `// FIXME` markers. Typed format:
  `// TODO(scope): TD-TBD — title`, `// KNOWN GAP(severity): TD-TBD —
  title`, `// VERIFY(source): TD-TBD — title` (substitute `#` for `//`
  in Python). Cross-reference: the project-template section is canonical
  for the typed format; the pack-repo follows the same convention so
  pack-coder behavior is consistent across pack-repo and client-repo
  contexts.
```

This is pack-repo trinity only — project-template trinity already carries the typed format (lines 296-326). No project-template edit per OQ-3.


### SC-1 — Cross-CLI parity for rules (see §C and §D)

**Action:** Substantive design landed in §C (L8 propagation) and §D (Tier 2 memory shape). Triage-level disposition: trinity-first single-tier-of-truth (per §A.1 challenge to first architect's three-tier model).

### SC-2 — Pack version update propagation (see §J)

**Action:** No new propagation mechanism needed. Existing `customization-preserve` library handles trinity updates; memory is Claude-Code-only convenience cache that does not propagate. Specific design in §J.

### SC-3 — Greenfield install propagation (see §K)

**Action:** No new files install. Existing `init-project.sh` S11 stage covers client-side trinity. Pack-repo trinity / memory entries do NOT install to client repos (per OQ-3). Specific design in §K.

### L1 — Pack Chat is not a coder agent (KEEP; PROMOTE)

**Action:** PROMOTE `feedback_pack_chat_does_no_fixes` to trinity NEW `### Pack Chat scope` sub-section.

**Specific text to ADD as a bullet inside NEW `### Pack Chat scope` sub-section:**

```
- **Pack Chat does NO fixes.** Pack Chat's role in any review/fix
  cycle is exactly: spawn pack-reviewer (in background) → read review
  report → triage findings (fix-or-skip per finding, with rationale
  for skips) → present triage to user → spawn fix-coder (in background)
  with the triage decisions → read the fix-coder IMPL-REPORT → stage +
  commit with user approval. Pack Chat does NOT use Edit / Write tools
  to apply review findings. NO threshold exception — there is no "small
  enough to skip the coder" carve-out. A one-line typo fix from a review
  finding goes to fix-coder. Rationale: auditability (fix-coder IMPL-
  REPORT carries the rationale doc), pattern consistency, background
  execution, Pack Chat context preservation.

- **What Pack Chat CAN edit directly** (this is NOT a contradiction
  of the rule above — these are not fixes):
  - Memory files (`~/.claude/projects/<slug>/memory/*.md`) — Pack
    Chat's own operating state, not pack work.
  - PM-only files (BACKLOG.md / CHANGELOG.md / README version table /
    PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root /
    `project-template/` trinity) — see `PACK-AGENTS.md` § "Agent
    permission rules" for the PM-only list. PM-only IS Pack-Chat-direct
    by construction.
  - Pack Chat may NOT edit project-template / supporting-docs /
    maintenance-docs / scripts / fixtures / agent definitions —
    those go to pack-coder.
```

### L2 — Deferral IS scope creep (KEEP; PROMOTE)

**Action:** PROMOTE `feedback_deferral_is_scope_creep` to trinity `### Workflow` sub-section.

**Specific text to ADD as a bullet inside `### Workflow` (after V11-4 bullet):**

```
- **Deferral IS scope creep.** Deferring unblocked work to a later BD
  or batch is tech debt and scope creep. Punted items lose context,
  multiply, require archaeology in future sessions. Defending deferral
  rigorously requires (a) SIZE (architect-pass material; real file/
  contract surface argument, not "felt big"), (b) BLOCKED (real
  dependency on not-yet-landed artifact, not "feels related"), or
  (c) LOGICAL FIT (cleanly belongs with another sibling BD/commit;
  concrete same-file/same-contract fit, not "thematic"). When a new
  BD is created that is LARGE and UNBLOCKED, insert it IMMEDIATELY
  AFTER the current BD or batch — do not park at end of v11.0, do not
  park in a "next batch" with no anchor. When BLOCKED, insert at the
  exact unblock point. Per OQ-1 (rewritten EXECUTION-PLAN §B), any
  new-BD-open additionally requires user-discussion-and-approval.
```

### L3 — Per-BD review/fix INLINE before next BD's coder (STRENGTHEN; existing memory wording extension)

**Action:** STRENGTHEN `feedback_review_fix_one_cycle` memory text to make INLINE-BEFORE-COMMIT unambiguous. Then PROMOTE.

**Specific BEFORE/AFTER for memory file (`feedback_review_fix_one_cycle.md` line 8 — verbatim):**

BEFORE:
```
**Multi-BD batches: review/fix runs at TWO scopes — per-BD (each impl) AND end-of-batch (the bundle).** Sequence: coder finishes BD impl → per-BD pack-reviewer runs once on that BD's diff → fix commit closes all actionable findings → commit + CI green → NEXT BD's coder spawns against the just-fixed code. After all per-BD cycles complete and CI is green: end-of-batch pack-reviewer runs once on the full batch → fix commit closes batch findings → CI green → implicit BD status flip per [[feedback_implicit_status_flip]].
```

AFTER:
```
**Multi-BD batches: review/fix runs at TWO scopes — per-BD (each impl) AND end-of-batch (the bundle).** Sequence: coder finishes BD impl → per-BD pack-reviewer runs once on that BD's diff → fix commit closes all actionable findings → commit + CI green → NEXT BD's coder spawns against the just-fixed code. **The per-BD review/fix runs INLINE, before the next BD's coder spawns — never retroactively at end of batch.** (Exception: pre-2026-05-15 batches that shipped before this rule was current may need a Batch-21c-style retroactive per-BD review-fix recovery pass; that exception does NOT apply to any batch starting 2026-05-15 or later.) After all per-BD cycles complete and CI is green: end-of-batch pack-reviewer runs once on the full batch → fix commit closes batch findings → CI green → implicit BD status flip per [[feedback_implicit_status_flip]].
```

THEN PROMOTE the strengthened version to trinity `### Workflow` sub-section.

**Specific text to ADD as a bullet inside `### Workflow` (after L2 bullet above):**

```
- **Per-BD review/fix runs INLINE, before next BD's coder spawns.**
  Multi-BD batches: each BD's review/fix runs inline (coder → reviewer
  → triage → fix-coder → commit → NEXT BD's coder). End-of-batch
  reviewer runs once on the full batch after all per-BD cycles
  complete. Single-BD batches: only one cycle needed. Never delay
  per-BD reviews to end-of-batch retroactive recovery (Batch-21c-
  style); that is an exception for pre-2026-05-15 batches only.
```

### L4 — Architect-first for rules (NEW-HOME; merged with PC-10 per §A.6)

**Action:** Per §A.6 challenge, merged into the PC-10 trinity bullet titled "Pack-architect spawn protocol". See PC-10 above for the specific text.

### L5 — Pack Chat presents triage to user before fix-coder spawns (KEEP + PROMOTE as one bullet)

**Action:** Per §A.6, L5 is distinct from L4/PC-10 (it is about review-fix flow, not architect spawning). Promote as ONE bullet in `### Workflow`. NOT a sub-section creator.

**Specific text to ADD as a bullet inside `### Workflow` (after L3 bullet above):**

```
- **Pack Chat presents triage to user before fix-coder spawns.** After
  every reviewer pass, Pack Chat reads the report, triages each
  finding (FIX vs SKIP, with rationale for SKIPs — default FIX-ALL per
  `feedback-fix-all-review-findings`), and surfaces the triage to the
  user. User can override per finding before fix-coder spawns. User
  approves the resulting fix commit (not per-finding approval — that
  was the pre-2026-05-16 pattern and produced too much friction). The
  triage gate is between reviewer and fix-coder; the commit gate is
  between fix-coder IMPL-REPORT and the `git commit`.
```

### L6 — User retains hard-stop authority (KEEP; consolidated principle is in trinity)

**Action:** The principle is already covered by `feedback_no_destructive_without_approval` (in memory; promoted via PC-uncertain-a's trinity bullet) and `feedback_commit_approval_next_steps` (in memory; promoted via the new `### Pack Chat scope` sub-section — see L6 specific text below). No additional bullet needed.

**Specific text to ADD as a bullet inside NEW `### Pack Chat scope` sub-section (already mentioned as the commit-approval-next-steps promotion target):**

```
- **Commit-approval requests include next-steps plan.** Every
  "Approve commit?" prompt to the user MUST include a numbered or
  bulleted list at the bottom of the approval message naming the
  concrete actions Pack Chat plans to take between this commit and
  the next anticipated commit. Each step names a concrete action
  (agent spawn + which agent; direct PM-only edit + which file; test
  run; etc.) — not a vague phase name. If nothing is planned beyond
  this commit, explicitly state "nothing planned." No exceptions for
  "obvious" next steps. Rationale: Pack Chat carries multi-step
  sequences in its head but the user only sees the immediate ask;
  surfacing the plan lets the user redirect BEFORE work happens,
  not after. Hard-stop authority (`feedback-no-destructive-without-
  approval`) attaches to the plan — the user can stop or redirect
  any planned step.
```

### L7 — Working files / inputs files convention (STRENGTHEN; covered by V11-9 trinity workflow-artifact extension)

**Action:** Same edit as V11-9. The trinity workflow-artifact list extension covers `CLEANUP-INPUTS-*.md`, `PACK-REVIEW-*-RETRO.md`, `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`. Pattern B archive-on-version-ship applies.

No separate edit beyond V11-9.

### L8 — Sub-agent SendMessage-stop defiance + PREFLIGHT (PROMOTE; hybrid cross-CLI per §C)

**Action:** Promote `feedback_pack_coder_preflight_pattern` to trinity with the hybrid shape designed in §C below. Also add PACK-AGENTS.md cross-reference per §E.

Specific trinity text is in §C; specific PACK-AGENTS.md text is in §E.

### L8.1 — Architect-doc divergence: STATUS.md disclaimer literal (KEEP as PM action item)

**Action:** Per task constraints ("Do NOT propose architect-doc edits to the per-entry-split corpus — those are PM-owned"), this cleanup batch surfaces the divergence as a Pack-Chat action item — NOT a pack-coder fix. Surface in §H planner deliverables as a "Pack-Chat-to-discuss" item.

**Action item text for Pack Chat:**

```
Pack Chat: pick which STATUS.md disclaimer literal is canonical between
PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 and ARCHITECTURE-PER-ENTRY-SPLIT-
INTEGRATION.md §5.3. The wording followed at BD-169 is the de-facto
canonical (per IMPLEMENTATION-REPORT-BD-169.md §6.1). Update the
OTHER architect-doc text to point to the canonical wording with a
short addendum cross-reference. This is documentation coordination,
not a code defect.
```

### L9 — Architect-doc-vs-reality reconciliation pattern (PROMOTE; trimmed per §A.5)

**Action:** Per §A.5 challenge, promote the PATTERN to trinity; KEEP the worked example in `ARCHITECTURE-BD-119.md` §9.2 addendum (already there). Trinity bullet names the pattern in 3 lines; the worked example anchor is named-by-doc not file-line.

**Specific text to ADD as a bullet inside trinity `### Repo conventions` (after V11-19 bullet above):**

```
- **Architect-doc-vs-reality reconciliation.** When a BD realizes a
  design anticipated in an architect doc, ship the reconciliation
  chain: (a) in-code docstring naming the realized consumer (file +
  symbol; never line numbers — line numbers drift), (b) architect-doc
  addendum cross-referencing the realized consumer, (c) IMPL-REPORT
  cross-reference linking both. Worked example: BD-119 §9.2 addendum
  in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  names BD-160 as the first realized consumer; the consumer carries
  the matching docstring; the BD-160 IMPL-REPORT links both. This
  pattern is load-bearing for any future shipped surface that pre-
  existed in an architect doc.
```

Also add a Tier-1.5 memory pointer per §F.


---

## §C — L8 cross-CLI propagation decision + text

### C.1 — Decision

I choose the **hybrid** shape: PREFLIGHT lives in the shared trinity bullet (platform-neutral per research §5.6 — it is just text emission); the STOP-MEANS-STOP enforcement carries an explicit Claude-Code-specific note WITHIN the same trinity bullet (the SendMessage delivery mechanism + SECURITY WARNING classifier are Claude-Code-only per research §5.4 + §5.5).

This is one trinity bullet, not two. The cross-CLI scope is internal to the bullet body — Pack Chat reads ONE bullet and understands both what is universal (PREFLIGHT) and what is platform-conditional (STOP-MEANS-STOP enforcement).

### C.2 — Why this shape (rationale; rejected alternatives)

**Considered and rejected:**

- **Pure Trinity exemption (Claude-only sub-section like the existing isolation rule).** Rejected because PREFLIGHT IS platform-neutral — emitting a one-line text PREFLIGHT line is a content requirement, not a tool-call requirement. Codex / Gemini sub-agents can be told to emit the same line. Putting BOTH halves in a Claude-only sub-section would deprive Codex / Gemini sub-agent prompts of PREFLIGHT discipline without justification.
- **Platform-neutral PREFLIGHT-only trinity bullet (no STOP-MEANS-STOP).** Rejected because STOP-MEANS-STOP is half the rule's value — it is the rule that prevented the BD-169 IMPL-REPORT defiance incident. Dropping it for cross-CLI purity would weaken the rule when used in the Claude context (the context where the incident occurred and is most likely to recur). Codex / Gemini will get a weaker version with no STOP-MEANS-STOP — but that is honest reporting of platform capability, not a rule weakening.
- **Two separate trinity bullets (PREFLIGHT bullet + Claude-only STOP-MEANS-STOP bullet).** Rejected because the rule is logically ONE rule with two halves. Splitting it into two bullets means a future reader could promote the PREFLIGHT bullet to e.g. project-template trinity without realizing it is half a rule. One bullet with an internal scope note is more cohesive.

**Chosen shape: one trinity bullet, hybrid scope.** PREFLIGHT is required for every coder spawn in any CLI; STOP-MEANS-STOP preamble is required for every Claude pack-coder spawn; the corresponding Codex / Gemini behavior depends on platform-native UI affordances (`/agent`, `Esc`, `Ctrl+C`) per research §3.6 / §3.7 / §2.6.

### C.3 — Specific trinity bullet text

ADD as a bullet inside `### Agent invocation rules` (after PC-11 bullet above):

```
- **Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern.** Every pack-coder
  agent prompt MUST include both halves of this pattern:

  - **PREFLIGHT (platform-neutral, REQUIRED for all CLIs).** After
    completing all in-scope file edits + verification, BEFORE writing
    the IMPL-REPORT, the coder emits ONE plain-text line:
    `PREFLIGHT: N/N in-scope file edits complete; verification PASS;
    HEAD <SHA>; about to Write IMPL-REPORT to <path>`. Then it writes
    the IMPL-REPORT. Pack Chat treats this line as the trust signal
    that the report-write is starting from a complete-and-green state.
    If the coder cannot complete the preflight (some edit failed,
    some test failed), it reports what went wrong instead and does
    NOT write a partial IMPL-REPORT.

  - **STOP-MEANS-STOP preamble (CLAUDE-CODE-SPECIFIC ENFORCEMENT,
    REQUIRED for all CLIs as content).** The coder prompt opens with
    an explicit instruction: "If you receive a parent-session message
    containing the words stop / halt / revert / do not continue, you
    MUST immediately stop ALL work, including any in-progress Write.
    Partial files are acceptable; do not append to make consistent.
    Stop authority is absolute and unconditional." This text is
    platform-neutral; the in-band ENFORCEMENT mechanism is platform-
    conditional:
    - Claude Code: SendMessage tool (Agent Teams,
      `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`); SECURITY WARNING
      classifier flags subagent defiance at handoff. This is the
      enforced path the BD-169 incident exposed (see worked example
      in `feedback-pack-coder-preflight-pattern` memory pointer).
    - Codex CLI: No SendMessage equivalent (confirmed absent per
      issue #12462). Parent stop mechanism is `/agent` command or
      natural-language ("ask Codex to stop the subagent"). Reliability
      caveats per research §2.6.
    - Gemini CLI: No SendMessage equivalent (hub-and-spoke per docs).
      Parent stop mechanism is natural-language or `Ctrl+C` (terminates
      whole session per issue #3385). Reliability caveats per
      research §3.6.

  Worked-example anchor:
  `feedback-pack-coder-preflight-pattern` memory pointer; original
  incident BD-169 19g-pack, 2026-05-16.
```

### C.4 — Implication for non-Claude CLIs

Codex / Gemini pack-coder prompts (in `.codex/agents/` / `.gemini/agents/` per the pack's existing CLI-specific agent definitions) get the PREFLIGHT requirement immediately; they get the STOP-MEANS-STOP preamble as CONTENT (the text is in the prompt) but cannot benefit from the SECURITY WARNING enforcement layer Claude has. That is an honest reflection of platform capability. A pack user running Codex or Gemini Pack Chat must rely on UI-affordance stop (`/agent`, `Ctrl+C`) and accept the reliability caveats.

This does NOT require new pack files. It is one trinity bullet, applied uniformly across all CLI agent definitions when those definitions are next updated. Pack-coder is exempt from "new substantive features" because the PREFLIGHT+STOP-MEANS-STOP text is content in agent prompts, not new tooling.

---

## §D — Tier 2 Codex / Gemini memory shape decision + design

### D.1 — Decision

I choose **trinity-only for Codex and Gemini**. The pack does NOT ship a Codex memory file, does NOT ship a Gemini memory file, and does NOT carry a Codex/Gemini equivalent of the Claude `~/.claude/projects/<slug>/memory/MEMORY.md` index. Trinity (`AGENTS.md` for Codex, `GEMINI.md` for Gemini) IS the only rule surface those CLIs see for pack rules.

This collapses the first architect's three-tier model to two effective tiers:

- **Tier 1 — Trinity (authoritative, cross-CLI):** `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at the pack repo root. Single source of truth. Cross-CLI by construction.
- **Tier 1.5 — Claude-Code memory cache (pure pointer file, Claude-only):** `~/.claude/projects/<slug>/memory/MEMORY.md` carries one-line-per-rule pointers to trinity anchors. NO body text. NO standalone rules. Memory files (the `feedback_*.md` files alongside MEMORY.md) similarly reduce to header + one-line pointer to the trinity anchor.

There is no Tier 2 for Codex or Gemini.

### D.2 — Why this design (rationale)

**Structural reasons (research-driven):**

- Codex memories are opt-in + regionally restricted + opaque per official guidance ("treat these files as generated state ... don't rely on editing them by hand as your primary control surface"). Shipping a pack-managed Codex memory file would (a) require Codex users to opt-in to a feature off by default, (b) be unavailable in EEA/UK/CH, (c) contradict OpenAI's own guidance that this surface is not user-editable. None of these are reasonable engineering tradeoffs for a pack maintainer.
- Gemini has no separate per-project memory cache surface. Memory IS the GEMINI.md hierarchy. Shipping a "Gemini memory" would require shipping it AS GEMINI.md content — which is just trinity. So there is nothing to design.

**Design reasons (independent of research):**

- A pointer-only Tier 1.5 file makes "trinity and memory disagree" impossible by construction. The memory file carries no body text that could drift from trinity.
- Maintenance is simpler: when trinity changes, the memory pointer line's summary updates; the trinity anchor URL stays the same. No round-trip; no "remember to update both."
- Pack-coder / pack-architect / pack-planner agents READ trinity directly (via CLAUDE.md / AGENTS.md / GEMINI.md at session start) — they do not need to read memory files. The memory cache exists purely for Pack Chat's own in-chat recall convenience.

### D.3 — Tier 1.5 (Claude memory) shape specification

Each memory file at `~/.claude/projects/<slug>/memory/<feedback>.md` reduces to this template:

```
---
name: <human-readable-title>
description: <one-line summary, ≤120 chars>
metadata:
  node_type: memory
  type: feedback | reference
  trinity_anchor: <path/to/file.md>#<anchor-id>
  originSessionId: <preserve from original>
---

# <Human-readable title>

This memory entry is a Tier-1.5 pointer cache. The authoritative rule
lives in trinity:

→ `<absolute-path>/CLAUDE.md` `## Pack memory` > `### <sub-section>` >
  bullet "<bullet-title-or-first-N-words>"

If this pointer disagrees with trinity, TRINITY WINS. Update this
pointer file in the same commit as any trinity rule change.
```

The MEMORY.md index file similarly reduces to:

```
**Tier 1.5 (Claude-Code memory cache).** This index points to trinity
rules at `<absolute-path>/CLAUDE.md` `## Pack memory`. Trinity is the
single source of truth; this file is a Claude-Code convenience cache.
If this index disagrees with trinity, TRINITY WINS.

- [<title>](<trinity-anchor>) — <one-line summary>
- [<title>](<trinity-anchor>) — <one-line summary>
...
```

One line per ACTIVE Claude-only rule (i.e., entries NOT promoted to trinity stay as standalone memory entries; entries promoted to trinity become pointer entries — see §F per-memory-file disposition).

### D.4 — Standalone Claude-Code-only memory entries

Some memory entries are Claude-Code-specific by content and do NOT promote to trinity. They retain their original body content (NOT pointer-only) because they describe Claude-Code-specific operational behavior. These are the platform-specific entries. See §F for the full table; the Claude-only standalone entries are:

- `feedback_no_prefix_chars` (Claude Code copy-paste-text formatting)
- `feedback_worktree_isolation_broken_from_v11_clone` (Claude Code Agent tool isolation behavior) — note this duplicates the trinity `### Sub-agent isolation (Claude-only)` content; per §F the memory becomes pointer-only since the trinity already carries the authoritative text. Keep the memory file as a Tier-1.5 pointer.
- `feedback_spawn_agents_in_background` — Claude Code Agent-tool `run_in_background` parameter; per §F the memory becomes pointer-only since PC-uncertain-b promotes it to trinity.
- `feedback_agent_teams_stage_lifecycle` — Claude Code Agent Teams + SendMessage; per §F the memory becomes pointer-only since PC-4/V11-6 promotes it to trinity.

The only TRUE standalone Claude-only entry (not promoted, not pointer-only) is `feedback_no_prefix_chars` — it has no trinity equivalent because it is a chat-tooling convention (copy-paste-text formatting), not a pack rule.

### D.5 — What pack-coder ships for Tier 1.5

Pack-coder edits memory files at `~/.claude/projects/<slug>/memory/` directly. This is a per-machine local cache; the pack itself does NOT ship memory file content (no template files for memory). Pack Chat may edit memory files directly per `feedback_pack_chat_does_no_fixes` scope clause ("Edit memory files — this IS Pack Chat's operating state, not pack work") — so in this Batch 19b, Pack Chat performs the memory cache edits, NOT pack-coder. Per the agent / Pack-Chat scope boundary, memory edits are PM-direct work.

Pack-coder DOES write to trinity (CLAUDE.md / AGENTS.md / GEMINI.md at pack root) and PACK-CHAT.md and PACK-AGENTS.md and EXECUTION-PLAN-V11.0.md per the §H planner deliverables. Memory file edits happen separately in the same batch by Pack Chat. This is consistent with the existing "Pack Chat may edit memory files directly" carve-out and avoids the agent-touching-Claude-private-state question.

---

## §E — OQ-4 PACK-AGENTS.md L8 cross-ref decision + text

### E.1 — Decision

I choose **DO add a cross-reference to PACK-AGENTS.md `## Agent permission rules`**, but with specific scoped text — not a duplicate of the trinity bullet.

### E.2 — Rationale

PACK-AGENTS.md is the contract document agents read for permission boundaries. The PREFLIGHT + STOP-MEANS-STOP rule is BOTH a prompt-construction rule (covered by trinity `### Agent invocation rules` per §C) AND an agent-behavior rule (the agent's enforcement obligation). Without a PACK-AGENTS.md cross-reference, an agent reading only PACK-AGENTS.md would not see the rule.

The trinity bullet (§C) is the authoritative text; PACK-AGENTS.md gets a SHORT cross-reference (3 lines) that points to trinity for the full text.

### E.3 — Specific text

ADD as a bullet inside PACK-AGENTS.md `## Agent permission rules` (after the existing "PM-only files and directories" + per-entry-decomposition section; specifically, INSERT before the existing "Skill and agent maintenance" bullet — which is the last bullet of that section per line 189):

```
**Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation.** Every pack-coder
(or coder-style fix-coder) agent has two non-negotiable behavioral
obligations:

- **PREFLIGHT line BEFORE IMPL-REPORT.** After all in-scope edits +
  verification, emit a single plain-text line of the form `PREFLIGHT:
  N/N in-scope file edits complete; verification PASS; HEAD <SHA>;
  about to Write IMPL-REPORT to <path>` before any IMPL-REPORT write.
  This is the orchestrator's trust signal that the report-write
  starts from complete-and-green state.

- **STOP-MEANS-STOP on parent stop directives.** Any parent-session
  message containing stop / halt / revert / do not continue MUST
  trigger immediate halt of all work including in-progress Writes.
  Partial files are acceptable; do not append to "make consistent."
  Defying a parent stop directive is the worst possible failure
  mode (see worked example: BD-169 19g-pack incident, 2026-05-16).

Authoritative full text for both halves of the pattern (including
cross-CLI scope notes for Codex / Gemini): trinity `## Pack memory`
`### Agent invocation rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP
pattern" bullet.
```

This is one short PACK-AGENTS.md addition, pointing to the trinity bullet for the full text. Agents reading PACK-AGENTS.md see the obligation summary; agents reading trinity see the full text. No duplication; clear ownership of authority (trinity).

---


## §F — Per-memory-file disposition table

All 29 memory files currently listed in `~/.claude/projects/<slug>/memory/MEMORY.md` are enumerated below with disposition. Files are listed in MEMORY.md order. Disposition codes:

- **POINTER (Tier 1.5)** — memory file is reduced to pointer-only per the §D.3 template; authoritative text lives in named trinity bullet.
- **STANDALONE (Tier 1.5)** — memory file retains full body content (Claude-Code-specific by content; no trinity equivalent because the rule is about chat tooling, not pack rules).
- **DELETE** — memory file is removed (no use cases remain; rule is obsolete or fully subsumed).
- **EDIT-IN-PLACE** — memory file's body is edited (no POINTER reduction; the file remains a Tier-1.5 standalone but with strengthened wording per §B).

| # | Memory file | Disposition | Trinity anchor (if POINTER) or rationale (if STANDALONE / DELETE) |
|---|---|---|---|
| 1 | `feedback_clarg_trinity` | POINTER | Trinity rule itself is in trinity `**Trinity rule**` section (not in `## Pack memory` — it is in the top-level rules block). Pointer to that section. |
| 2 | `feedback_no_destructive_without_approval` | POINTER | Promoted via PC-uncertain-a trinity bullet (`### Workflow` > "Per-action approval extends to sub-agents"). |
| 3 | `feedback_spawn_agents_in_background` | POINTER | Promoted via PC-uncertain-b trinity bullet (renamed `### Sub-agent behavior (Claude-only)` > "Default sub-agent spawns to background"). Note: still Claude-only by content; trinity exemption stated in the bullet. |
| 4 | `feedback_agent_teams_stage_lifecycle` | POINTER | Promoted via PC-4/V11-6 trinity bullet (renamed `### Sub-agent behavior (Claude-only)` > "Agent-team stage lifecycle + per-commit fresh-coder"). |
| 5 | `feedback_no_prefix_chars` | STANDALONE | Claude Code chat-tooling convention (copy-paste-text formatting on left margin). No trinity equivalent — this is NOT a pack rule, it is a chat-text-formatting preference. Retains full body content. |
| 6 | `feedback_ops_product_separation` | POINTER | Already in trinity `### Repo conventions` > "Separate pack ops from pack product". |
| 7 | `feedback_agent_prompt_rules` | POINTER | Already in trinity `### Agent invocation rules` > "Agent prompt requirements". |
| 8 | `reference_pack_backlog_structure` | POINTER | Already in trinity `### Repo conventions` > "BACKLOG.md has no Resolved section". |
| 9 | `feedback_chunk_long_outputs` | POINTER | Already in trinity `### Agent invocation rules` > "Agent prompt requirements" (the "chunk Write calls for outputs over ~300 lines" clause). |
| 10 | `reference_pack_agent_invocation` | POINTER | Already in trinity `### Agent invocation rules` > "Pack agent invocation". |
| 11 | `feedback_pack_chat_does_not_architect` | POINTER | Already in trinity `### Workflow` > "Pack Chat does not architect". |
| 12 | `feedback_no_solutions_in_agent_prompts` | POINTER | Already in trinity `### Agent invocation rules` > "No solutions in agent prompts". |
| 13 | `feedback_no_prior_reviews_to_reviewer` | POINTER | Already in trinity `### Agent invocation rules` > "No prior reviews to pack-reviewer". |
| 14 | `feedback_review_fix_one_cycle` | EDIT-IN-PLACE then POINTER | First, EDIT-IN-PLACE per L3 §B (add the explicit INLINE-BEFORE-COMMIT clarification). Then POINTER: promoted via L3 trinity bullet (`### Workflow` > "Per-BD review/fix runs INLINE, before next BD's coder spawns"). The edit-in-place captures the strengthened wording before pointer reduction so the strengthened wording is preserved in trinity. |
| 15 | `feedback_fix_all_review_findings` | POINTER | New trinity bullet promoted under `### Workflow` (not yet listed in §B because the first architect did not give it a row of its own; my disposition: ADD trinity bullet — see §F.1 below for the new bullet text). |
| 16 | `feedback_deferred_work_tracking` | POINTER | Promoted via PC-8 trinity bullet (`### Workflow` > "Deferred work needs a tracked anchor"). |
| 17 | `feedback_no_deferral_without_user_direction` | POINTER | Promoted via V11-4 trinity bullet (`### Workflow` > "No deferral to v11.1+ without explicit user direction"). |
| 18 | `feedback_deferral_is_scope_creep` | POINTER | Promoted via L2 trinity bullet (`### Workflow` > "Deferral IS scope creep"). |
| 19 | `feedback_pack_chat_does_no_fixes` | POINTER | Promoted via L1 trinity bullet (NEW `### Pack Chat scope` > "Pack Chat does NO fixes"). |
| 20 | `feedback_implicit_status_flip` | POINTER | Already in trinity `### Workflow` > "Implicit BD status flip on batch completion". |
| 21 | `project_v11_high_level_goals` | POINTER | Already in trinity `### Project goals (v11)`. |
| 22 | `feedback_test_infra_self_provisioned` | POINTER | Already in trinity `### Repo conventions` > "Test infra is self-provisioned". |
| 23 | `feedback_agents_never_commit` | POINTER | Already in trinity `### Workflow` > "Agents never commit". |
| 24 | `feedback_worktree_isolation_broken_from_v11_clone` | POINTER | Already in trinity `### Sub-agent isolation (Claude-only)` (which I am renaming to `### Sub-agent behavior (Claude-only)` per §I). |
| 25 | `feedback_filename_uniqueness` | POINTER | New trinity bullet promoted under `### Repo conventions` — see §F.2 below for the new bullet text. |
| 26 | `feedback_pack_coder_preflight_pattern` | POINTER | Promoted via L8 trinity bullet (`### Agent invocation rules` > "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern") per §C. |
| 27 | `feedback_commit_approval_next_steps` | POINTER | Promoted via L6 trinity bullet (NEW `### Pack Chat scope` > "Commit-approval requests include next-steps plan"). |
| 28 | `feedback_researcher_architect_planner_pipeline` | POINTER | Promoted via PC-11 trinity bullet (`### Agent invocation rules` > "Researcher-first pipeline for substantive content"). |
| 29 | `feedback_planner_user_review_before_coder` | POINTER | NEW trinity bullet promoted under `### Workflow` — see §F.3 below for the new bullet text. (First architect omitted this entry from §3.5 mapping; my disposition catches it.) |

**Count check:** 29 entries enumerated. Disposition counts: 26 POINTER, 1 STANDALONE (`feedback_no_prefix_chars`), 1 EDIT-IN-PLACE-then-POINTER (`feedback_review_fix_one_cycle`), 0 DELETE.

### F.1 — `feedback_fix_all_review_findings` new trinity bullet text

The first architect listed this entry in §3.1 as a LOAD-BEARING memory without trinity coverage but did not produce a specific §3.5 mapping row OR a §2 triage row for it. My disposition catches it and produces the bullet.

ADD as a bullet inside trinity `### Workflow` (after the L5 bullet above):

```
- **Triage all reviewer findings; default fix-all; nits become tech
  debt.** Pack Chat surfaces every reviewer finding (BLOCKER / MUST /
  SHOULD / NIT) to the user as a fix-or-defer triage per finding. The
  default for all severities is FIX. NITs that are deferred (with
  user-discussion-and-approval per OQ-1 EXECUTION-PLAN §B) become
  tracked tech debt per `feedback-deferred-work-tracking` — never
  "noted in the report and dropped." Default fix-all preserves the
  small-fix-now contract that prevents tech debt accumulation
  (per `feedback-deferral-is-scope-creep`).
```

### F.2 — `feedback_filename_uniqueness` new trinity bullet text

ADD as a bullet inside trinity `### Repo conventions` (after the V11-19 bullet):

```
- **Filename uniqueness heuristic.** When introducing new files in the
  pack repo, prefer names that don't collide with any other file
  anywhere in the repo, so prose references are unambiguous even when
  the path is omitted. Quick check: `find . -name "<proposed-name>"
  -not -path "./.git/*"`. Structurally required collisions are exempt
  (trinity files, per-skill `SKILL.md`, byte-identical mirrors per
  CI Check 24, ecosystem-fixed names like `.gitignore` / `pyproject.toml`
  / `Package.swift`); for these exempted collisions, prose references
  must include path context ("pack-root `CLAUDE.md`" vs "project-template
  `CLAUDE.md`"). Worked example: BD-135 renamed the colliding
  `tracker.toml.example` pair.
```

### F.3 — `feedback_planner_user_review_before_coder` new trinity bullet text

ADD as a bullet inside trinity `### Agent invocation rules` (after PC-11 bullet, before the L8 PREFLIGHT bullet):

```
- **Planner output → user review → coder spawn.** Pack-planner output
  is NEVER auto-approved into a pack-coder spawn. Pack Chat surfaces
  the plan to the user for thorough review (the user may comment, add
  constraints, request structural changes) and waits for explicit
  approval before spawning pack-coder. The planner-to-coder gate is the
  user's last cheap window to redirect work before implementation
  consumes hours of agent time and chat context.
```


---

## §G — OQ-1 ripple-effect sweep

Per user's OQ-1 nuance, the rule "new-BD-opens require Pack-Chat-discussion-and-user-approval" has ripple effects across multiple items. I walk the triage and identify every affected item with updated language.

### G.1 — Items affected by the OQ-1 rule

| Item | OQ-1 ripple | My handling |
|---|---|---|
| PC-1 | Direct subject — §B rewrite is THE place OQ-1 is codified. | §B (PC-1 row) carries the full §B replacement text including step 5 ("New-BD-opens require user-discussion-and-approval"). |
| V11-7 | Scope-extension test exists to prevent unnecessary new-BD opens; cross-link explicitly to OQ-1. | §B (V11-7 row) text adds "Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open also requires user-discussion-and-approval; the scope-extension test exists to prevent unnecessary BD-opens in the first place." |
| V11-8 | First architect recommended NEW-BD-173; under OQ-1 that recommendation is no longer architect-binding — it becomes user-discussion-and-approval. Per my §A.2 challenge I reclassify V11-8 as NEW-HOME (inline bullet in PACK-CHAT.md), which avoids the new-BD-open entirely. | §B (V11-8 row) reclassifies and produces inline bullet; if user prefers BD-173, the §A.2 note flags it as a user-discussion item. |
| L2 | `feedback_deferral_is_scope_creep` says "insert immediately after the current BD/batch" for new BDs; OQ-1 layers on "with user approval". | §B (L2 row) trinity bullet cross-references OQ-1: "Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open additionally requires user-discussion-and-approval." |
| L5 | Triage gate — Pack Chat presents triage to user before fix-coder spawns. OQ-1 reinforces: if triage includes "skip with rationale for new BD," that skip-and-new-BD-recommendation now requires user-discussion-and-approval. | §B (L5 row) trinity bullet does NOT need OQ-1 cross-link (the rule is about per-finding fix-vs-skip, not about opening BDs for skipped findings — that downstream decision is governed by L2 + EXECUTION-PLAN §B step 5 which I rewrote per PC-1). Note: if a SKIP rationale is "this belongs in a new BD," the user-discussion-and-approval applies via the PC-1 §B mechanism. |
| F.1 (`feedback_fix_all_review_findings`) | "NITs deferred become tech debt" — OQ-1 requires user-discussion-and-approval for the defer-becomes-new-BD case. | §F.1 trinity bullet text cross-references: "NITs that are deferred (with user-discussion-and-approval per OQ-1 EXECUTION-PLAN §B)". |
| Any future architect-spawn or planner recommendation | Architect / planner cannot RECOMMEND opening a BD as a binding decision anymore — it is always a user-discussion item. | The PC-10/L4 merged trinity bullet ("Pack-architect spawn protocol") implicitly covers this — the architect produces a strategy doc, the user approves; any new-BD opens that emerge from the strategy go through PC-1 §B step 5. No additional bullet needed. |

### G.2 — Items NOT affected by OQ-1 (explicit no-action)

For completeness, items that DO involve BDs but are NOT new-BD-opens:

- Implicit BD status flip on batch completion (trinity rule, already in `### Workflow`). Status flip is BD edit, not BD open. Not affected.
- BD-NNN numbering (PC-9 STRENGTHEN). The "always read live BACKLOG" rule applies once the user has approved a new BD; the read-live-BACKLOG step happens AFTER OQ-1 approval. Not affected by OQ-1 directly.
- Architect-doc-vs-reality reconciliation (L9). About in-code docstrings + architect-doc addenda; no BD-open involved. Not affected.

### G.3 — Pack-Chat-side discussion shape (advisory, not a rule)

OQ-1 says new-BD-opens require user-discussion-and-approval. The discussion shape is NOT a trinity rule (it is Pack Chat operating-style, not pack rule), but for the planner's reference: when a finding might warrant a new BD, Pack Chat surfaces:

1. The finding text.
2. Why it might warrant a new BD (cite the (a) size, (b) blocked, (c) better-fit-with-existing-BD framing from §B step 5).
3. Pack Chat's recommendation: fix-now / extend-current-BD / edit-existing-BD / NEW-BD (with the (a)/(b)/(c) justification).
4. Explicit ask for user direction.

User responds with the choice. Pack Chat acts accordingly. No discussion-shape bullet is needed in trinity — this is Pack Chat workflow shape.

---

## §H — Planner-ready deliverables checklist

These artifacts must be in place BEFORE pack-planner can sequence Batch 19b. The planner ingests THIS strategy doc as its primary architect input and produces `PLAN-CLEANUP-BATCH-19B.md` (separate file from the first architect's strategy doc; the first architect's doc remains in place for comparison).

Items are numbered for planner cross-reference. STATUS is RESOLVED (architect produced specific text) or PENDING-USER (needs Pack-Chat-discussion-and-user-approval before planner can sequence the affected commit).

| ID | Deliverable | Status | Source |
|---|---|---|---|
| D-1 | Per-item triage with BEFORE/AFTER text for all 40 items | RESOLVED | §B |
| D-2 | Trinity promotion sweep mapping (memory → trinity sub-section) | RESOLVED | §F per-memory-file disposition table |
| D-3 | Trinity sub-section restructure plan (NEW `### Pack Chat scope`; rename `### Sub-agent isolation` → `### Sub-agent behavior`; extend Workflow / Agent invocation rules / Repo conventions) | RESOLVED | §I |
| D-4 | Cross-CLI propagation for L8 (PREFLIGHT + STOP-MEANS-STOP) | RESOLVED | §C |
| D-5 | Tier 2 (Codex / Gemini) memory shape decision | RESOLVED | §D — trinity-only; no Codex / Gemini memory files |
| D-6 | OQ-4 PACK-AGENTS.md L8 cross-reference text | RESOLVED | §E |
| D-7 | OQ-1 EXECUTION-PLAN §B reconciliation text | RESOLVED | §B (PC-1 row) — full §B replacement |
| D-8 | OQ-6 archive `CLEANUP-INPUTS-SESSION-RULES.md` to `maintenance-docs/archive/v11/` as the FINAL commit of Batch 19b | RESOLVED | §H specific planner step below |
| D-9 | L8.1 STATUS.md disclaimer divergence — Pack-Chat-to-discuss action item | PENDING-USER | §B (L8.1 row); Pack Chat picks canonical wording; not a pack-coder fix |
| D-10 | V11-8 BD-173 disposition — my recommendation is NEW-HOME (inline bullet); if user prefers BD-173, this becomes user-discussion-and-approval per OQ-1 | PENDING-USER | §A.2 challenge + §B (V11-8 row) |
| D-11 | PACK-CHAT.md `## Behavioral rules` ordering of new bullets (PC-2, PC-6, V11-1, V11-2, V11-5, V11-7, V11-8) | RESOLVED | §H ordering recommendation below |
| D-12 | Memory file edits (Pack Chat scope, not pack-coder) — 29 files per §F | RESOLVED | §F per-memory-file disposition table |

### H.1 — Recommended planner commit sequence for Batch 19b

The planner is free to override; this is my architect-side recommendation. Commit-shape per V11-8 trinity bullet (multi-commit batch → fix commits + final status flip commit; this batch has no BD status flips so the last commit is the archive commit).

```
Commit 19b-1: docs: v11 — Batch 19b cleanup — trinity ## Pack memory restructure + promotions

  Scope: trinity CLAUDE.md + AGENTS.md + GEMINI.md edits per §B + §I.
  Files: CLAUDE.md, AGENTS.md, GEMINI.md (pack-repo root only;
  per OQ-3, NO project-template trinity edits).
  Verification: validate-pack CI; manual diff vs first-architect-doc
  to confirm all promotions landed.

Commit 19b-2: docs: v11 — Batch 19b cleanup — PACK-CHAT.md ## Behavioral rules
              extensions (PC-2/6/V11-1/2/5/7/8 inline + L8.1 action-item note)

  Scope: PACK-CHAT.md additions per §B.
  Files: PACK-CHAT.md.
  Verification: read-only review by Pack Chat.

Commit 19b-3: docs: v11 — Batch 19b cleanup — PACK-AGENTS.md PREFLIGHT obligation
              addition (OQ-4)

  Scope: PACK-AGENTS.md addition per §E.
  Files: PACK-AGENTS.md.
  Verification: read-only review.

Commit 19b-4: docs: v11 — Batch 19b cleanup — EXECUTION-PLAN-V11.0.md §B rewrite (OQ-1)

  Scope: EXECUTION-PLAN-V11.0.md §B replacement per §B (PC-1 row).
  Files: EXECUTION-PLAN-V11.0.md.
  Verification: read-only review.

Commit 19b-5: docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY
              extensions + V11-15 reviewer-prompt-template find-replace

  Scope: supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md extensions
  (only if existing sections are missing wording — pack-coder verifies
  first per §B V11-12/13/14 rows); V11-15 find-replace per §B.
  Files: supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md, plus any
  files V11-15 grep returns.
  Verification: validate-pack CI; manual diff.

Commit 19b-6 (Pack Chat direct, not pack-coder): docs: v11 — Batch 19b cleanup —
              Claude memory cache pointer reduction (§F)

  Scope: ~/.claude/projects/<slug>/memory/*.md edits per §F.
  Files: 29 memory files + MEMORY.md index.
  Verification: Pack Chat reads MEMORY.md after edit; every pointer
  resolves to a trinity anchor; no body-text content carries rules.
  This commit is Pack-Chat-direct per the `feedback_pack_chat_does_no_fixes`
  scope clause ("Edit memory files — this IS Pack Chat's operating state").

Commit 19b-7 (FINAL — per OQ-6): docs: v11 — Batch 19b cleanup — archive
              CLEANUP-INPUTS-SESSION-RULES.md + first-architect strategy doc

  Scope: per OQ-6 (a), archive CLEANUP-INPUTS-SESSION-RULES.md to
  maintenance-docs/archive/v11/ as the FINAL commit of Batch 19b.
  Also archive ARCHITECTURE-CLEANUP-BATCH-19B.md (first architect's
  doc) and RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md (researcher's doc)
  and ARCHITECTURE-CLEANUP-BATCH-19B-V2.md (this doc) per the same
  workflow-artifacts archive convention (V11-9 / L7 / Pattern B).
  Files: git mv 4 docs to maintenance-docs/archive/v11/.
  Verification: read-only review; archive directory listing
  confirms all 4 files present.
```

The commit shape per V11-8 trinity bullet: this is a multi-BD batch in spirit (multiple distinct rules-cleanup outcomes); but since there are no BD-NNN status flips in this cleanup batch, the final commit is the archive commit (not a status-flip commit). The single-vs-multi distinction in V11-8 covers BD-status-flip behavior; this batch is a special case where the convention does not apply because there are no in-flight BDs to flip.

Per OQ-1, this batch opens NO new BDs. If the user opts for BD-173 (V11-8) per D-10 PENDING-USER, that becomes a separate sequenced commit (and the user-discussion-and-approval per OQ-1 happens BEFORE the planner can sequence it).

### H.2 — Recommended PACK-CHAT.md `## Behavioral rules` ordering for new bullets

Per first architect's D-9, the planner needs ordering for the 6+ new bullets. My architect-side recommendation is theme-clustered:

```
Existing bullets (unchanged):
  - Plan before executing
  - No commit without explicit approval
  - Verify staged files before committing
  - Tag management
  - No solution-biasing
  - Separation of pack operations and pack product
  - Delegate to pack agents when appropriate
  - Check CI after every push
  - No commit-staging beyond mechanical-edit threshold

NEW bullets inserted in the following order, grouped by theme:

  [Group: review/triage cycle]
  - Stop after every reviewer pass for triage discussion          [PC-2]

  [Group: chat-ownership / file boundaries]
  - Chat-ownership boundaries on concurrent sessions               [PC-6 + PC-7 + V11-3]

  [Group: fix discipline]
  - Real fixes only — no green-the-test band-aids                 [V11-1]
  - Direct opinion, not validation                                 [V11-2]

  [Group: branch / commit policy]
  - Push to v11-dev only during the v11-dev phase                 [V11-5]
  - Batch close commit shapes                                      [V11-8 inline per §A.2]

  [Group: scope-extension test]
  - Scope-extension test for in-flight work                       [V11-7]
```

7 new bullets total in PACK-CHAT.md (after V11-8 reclassification per §A.2). Clustering keeps related rules adjacent.

### H.3 — Archive-at-batch-end explicit planner step (per OQ-6 + Pass-criterion 7)

The final commit of Batch 19b (Commit 19b-7 above) archives:

1. `maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md` → `maintenance-docs/archive/v11/CLEANUP-INPUTS-SESSION-RULES.md`
2. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md` → `maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B.md`
3. `maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md` → `maintenance-docs/archive/v11/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md`
4. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` (THIS doc) → `maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md`

Plus: `PLAN-CLEANUP-BATCH-19B.md` (when produced by the planner) and any `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B.md` (when produced by pack-coder) also archive in the same commit.

Per OQ-6 (a): archive happens immediately after committing the substantive edits, NOT at v11.0 ship. Pattern B normally archives at version ship; cleanup batch is the exception because the inputs file's content has fully landed in trinity / PACK-CHAT.md / PACK-AGENTS.md / EXECUTION-PLAN, leaving the inputs file with no live forward-pointing value.

**Exception clause:** if any sub-step of Batch 19b cleanup is deferred (e.g., V11-15 grep surfaces more references than expected and needs a follow-up), the archive commit waits until that follow-up lands. The user's OQ-6 wording explicitly says "if the doc is needed later, don't archive it until after we are done using it."


---

## §I — Updated trinity sub-section restructure plan

This section is the carry-over from first architect §3.5 + my §A.6 challenge (merging L4 with PC-10) + §A.1 (collapse to two-tier) + §C (renaming the isolation sub-section to absorb sub-agent behavior more broadly).

### I.1 — Resulting trinity `## Pack memory` structure (POST-Batch 19b)

```
## Pack memory (project-local learnings)

[existing 4-line preamble]

### Workflow
  - Agents never commit                                          [unchanged]
  - Pack Chat does not architect                                 [unchanged]
  - One review/fix cycle per batch                               [unchanged]
  - Implicit BD status flip on batch completion                  [unchanged]
  - Per-action approval extends to sub-agents                    [PC-uncertain-a — NEW]
  - Deferred work needs a tracked anchor                         [PC-8 — NEW]
  - No deferral to v11.1+ without explicit user direction        [V11-4 — NEW]
  - Deferral IS scope creep                                      [L2 — NEW]
  - Per-BD review/fix runs INLINE                                [L3 — NEW]
  - Pack Chat presents triage to user before fix-coder spawns    [L5 — NEW]
  - Triage all reviewer findings; default fix-all                [F.1 — NEW]
  - Planner output → user review → coder spawn                   [F.3 — NEW]

### Agent invocation rules
  - Pack agent invocation                                        [unchanged]
  - Agent prompt requirements                                    [unchanged]
  - No solutions in agent prompts                                [unchanged]
  - No prior reviews to pack-reviewer                            [unchanged]
  - Researcher-first pipeline for substantive content            [PC-11 — NEW]
  - Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern               [L8 — NEW]

### Sub-agent behavior (Claude-only)                             [RENAMED from "Sub-agent isolation (Claude-only)"]
  - Spawn all sub-agents with no worktree isolation              [unchanged]
  - Default sub-agent spawns to background                       [PC-uncertain-b — NEW]
  - Agent-team stage lifecycle + per-commit fresh-coder          [PC-4 + V11-6 — NEW]
  - Trinity exemption (for the whole sub-section)                [unchanged note]

### Pack Chat scope                                              [NEW sub-section]
  - Pack Chat does NO fixes                                      [L1 — NEW]
  - Commit-approval requests include next-steps plan             [L6 — NEW]
  - Pack-architect spawn protocol                                [PC-10 + L4 merged — NEW]

### Repo conventions
  - Per-entry trees vs mirrors                                   [unchanged]
  - BACKLOG.md has no Resolved section                           [unchanged]
  - Separate pack ops from pack product                          [unchanged]
  - Test infra is self-provisioned                               [unchanged]
  - Skill and agent maintenance is mechanical by default         [unchanged — but workflow-artifact list extended per V11-9 / L7]
  - Pack-repo code-comment deferrals                             [V11-19 — NEW]
  - Filename uniqueness heuristic                                [F.2 — NEW]
  - Architect-doc-vs-reality reconciliation                      [L9 — NEW]

### Project goals (v11)
  - Pack tracker opt-in works with little to no user intervention [unchanged]
  - OT-style v10→v11 migration is automated                       [unchanged]
```

### I.2 — Comparison vs first architect

| Sub-section | First architect | My design | Delta |
|---|---|---|---|
| `### Workflow` | 4 existing + 6 promoted | 4 existing + 9 promoted | +3 (F.1 fix-all-findings; F.3 planner-output-user-review; explicit per-BD INLINE wording per L3) |
| `### Agent invocation rules` | 4 existing + 2 promoted (PREFLIGHT + researcher-pipeline) | 4 existing + 2 promoted | same |
| `### Sub-agent isolation (Claude-only)` | renamed implicitly? | RENAMED to `### Sub-agent behavior (Claude-only)`; 1 existing + 2 promoted | renamed for breadth (now covers isolation + background + agent-teams) |
| `### Pack Chat scope` (NEW) | NEW with 4 items | NEW with 3 items | -1 (PC-10/L4 merged per §A.6) |
| `### Repo conventions` | 5 existing + 3 promoted | 5 existing + 3 promoted | same items, different rationale per §A.5 (L9 trimmed) |
| `### Project goals (v11)` | unchanged | unchanged | same |

Total bullets in trinity `## Pack memory` post-Batch-19b: approx 35 bullets (was ~14 pre-batch). This is a substantive trinity growth and is intentional — the user's "single source of truth in trinity" lean accepts the file-size cost in exchange for the cross-CLI parity benefit.

### I.3 — Trinity file size estimate

Current pack-repo CLAUDE.md is 208 lines. Post-Batch-19b estimated:

- ~35 bullets × avg 6 lines per bullet (including bullet body) = ~210 lines of new `## Pack memory` content
- Existing sections (Quick reference / Repo structure / Rules for agents / commit-format / versioning / etc.) ~ 100 lines
- Total estimated: ~310 lines

Within Claude Code's 200-line auto-load cap? Per research §1.2, the cap is on MEMORY.md (200 lines or 25KB whichever first); CLAUDE.md has "no hard cap (200 lines guidance)." So 310 lines exceeds the SOFT guidance but does not break a hard limit. Codex `project_doc_max_bytes` default is 32 KiB; 310 lines × ~80 chars = ~24 KiB, within cap. Gemini has no documented cap.

**Consideration for planner:** if the post-batch trinity exceeds the 200-line soft guidance and the user wants tighter trinity, an alternative is to split `## Pack memory` content across `@`-imported sub-files (`.claude/rules/*.md` with YAML frontmatter scoping per Claude Code memory docs). This is OUT OF SCOPE for Batch 19b — it would be a separate architecture pass — but flag for the user as a future consideration.

### I.4 — Trinity rule consistency (CLAUDE.md / AGENTS.md / GEMINI.md)

Per the trinity rule, all three files get the same `## Pack memory` content. CLAUDE.md is the master copy in this batch; AGENTS.md gets identical Pack memory content; GEMINI.md gets identical Pack memory content WITH the "Keep this file concise" header acknowledged — but Gemini does not get a tighter version of `## Pack memory` (because that would break symmetry). The Gemini-specific operational notes at the bottom of GEMINI.md (`/chat save`, `save_memory`, etc.) stay as-is.

The only trinity exemption in `## Pack memory` is the `### Sub-agent behavior (Claude-only)` sub-section — this is preserved in CLAUDE.md only (AGENTS.md and GEMINI.md DROP this sub-section per the existing trinity-exemption pattern). The sub-section's "Trinity exemption" note explains why.

---

## §J — Version-update propagation strategy

This section is the carry-over from first architect §4 + §A.1 challenge (no Tier 2 for non-Claude CLIs).

### J.1 — Trinity-first propagation (under §A.1 collapsed-tier model)

When a project gets a pack version bump (`init-project.sh --update`), trinity files in the pack-shipped product (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) update via the existing `customization-preserve` library (BD-088 + BD-136 marker-aware merge contract).

But — per OQ-3 — the Batch 19b cleanup does NOT edit project-template trinity. The cleanup edits the PACK-REPO trinity only. So pack version-update propagation for THIS batch's content does not apply: client repos will NOT see the new pack-repo trinity content. That is correct under OQ-3 (pack-self only).

If a FUTURE batch wants to propagate ANY of the new pack-repo trinity rules to project-template trinity, that batch:

1. Reads this V2 strategy doc to understand which rules are pack-development-only vs. broadly-applicable.
2. Decides which subset of trinity edits cross-applies (e.g., `feedback_no_destructive_without_approval` cross-applies; `feedback_pack_chat_does_no_fixes` does NOT — clients have their own PM Chat, not Pack Chat).
3. Edits project-template trinity per the trinity rule (parallel edits across 3 files).
4. Pack version bumps (e.g., to v11.1); existing client repos pick up the new project-template trinity content via `init-project.sh --update` + `customization-preserve` merge.

Per OQ-3, this future batch is OUT OF SCOPE for Batch 19b.

### J.2 — Memory propagation: not applicable

Under §A.1 + §D, Codex and Gemini have no separate memory cache; Claude's memory cache is a Tier-1.5 pointer file that is regenerated per-machine by Pack Chat (or by hand) — it does NOT round-trip through pack version updates.

When trinity content changes via pack version-update, the Claude memory cache at a developer's local `~/.claude/projects/<slug>/memory/` becomes stale (pointer files name the old trinity anchor; bullet titles may have changed). The fix: Pack Chat at the developer's machine re-reads trinity, re-generates pointer files. Alternatively: at version-bump time, Pack Chat's `/pack-startup` could check trinity-bullet-anchor consistency against the local memory pointer files and surface drift.

This is a Pack Chat operational nicety, NOT a pack rule. Out of scope for Batch 19b. Flag for future consideration.

### J.3 — No new propagation surface in Batch 19b

To be explicit: Batch 19b ships zero new propagation infrastructure. The existing `customization-preserve` + trinity-file merge contract handles all trinity-update propagation (when project-template trinity is edited — not in this batch). Memory cache is per-developer, not pack-shipped.

---


## §K — Greenfield install propagation strategy

This section is the carry-over from first architect §5 + OQ-3 explicit scope confirmation.

### K.1 — Pack-self vs. client-side trinity systems

There are TWO trinity systems in the pack repo:

| Trinity | Location | Audience | Governs |
|---|---|---|---|
| Pack-repo trinity | `<repo-root>/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | David / pack-development sessions | Pack-development rules; Pack Chat behavior; pack-agent permissions |
| Project-template trinity | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | Client developers using the pack | Client-project rules (universal layer discipline, capabilities pattern, deferral comments, etc.) |

Per OQ-3, this Batch 19b touches ONLY the pack-repo trinity. The project-template trinity is unchanged.

### K.2 — Greenfield install (pack v11 → new client repo)

When a new project gets the pack installed for the first time via `init-project.sh`, stage S11 installs:

- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (project-template trinity, NOT pack-repo trinity) → client `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
- HELP fragments, tracker config example, issue templates, per-CLI skills, per-CLI agents.

The pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` are NOT shipped to clients. The pack-repo `## Pack memory` content (the substance of Batch 19b's edits) is for PACK DEVELOPMENT only.

Per OQ-3, greenfield install propagation is unchanged by Batch 19b. No new files install. No `init-project.sh` edits.

### K.3 — Client-side §Project memory unchanged

The project-template trinity (line 343 of current `project-template/CLAUDE.md`) carries `## Project memory` with 3 client-side rules:
- Trinity rule
- No destructive operations without explicit approval
- PM chat does not architect

Per OQ-3, this section is NOT extended in Batch 19b. The pack-repo trinity rules from Batch 19b stay in the pack-repo `## Pack memory`. The pack-repo and client-side rule surfaces are SEPARATE by design.

### K.4 — Future consideration (out of scope per OQ-3)

The user explicitly flagged a future discussion ("At some point we need to have a discussion on what should be transferred to the project side and how it should be integrated"). A future batch (post-v11.0 or in v11.1) can decide which pack-side rules cross-apply to clients. Some plausible candidates for that future discussion:

- `feedback_no_destructive_without_approval` — likely already covered by client-side "No destructive operations without explicit approval"
- `feedback_deferral_is_scope_creep` — plausibly client-applicable; but client PM Chat dynamics differ from Pack Chat
- `feedback_pack_chat_does_no_fixes` — NOT client-applicable (client PM Chat does fix work in some contexts; check `project-template` PM-CHAT.md)
- L9 architect-doc-vs-reality reconciliation — plausibly client-applicable
- V11-19 typed code-comment deferrals — already client-canonical (it is in `project-template/CLAUDE.md` lines 296-326)

This is NOT a Batch 19b deliverable. Surface as a future BD candidate; the user decides.

### K.5 — PACK-CHAT.md and PACK-AGENTS.md do NOT ship per OQ-2

Per OQ-2 (user confirmation 2026-05-16): "The pack items that ship to the client projects should be in `project-template/` or `supporting-docs/` so PACK-CHAT.md should never be shipped to a client." PACK-CHAT.md and PACK-AGENTS.md are pack-ops files at the pack repo root. They do NOT install to client repos. There is a distinct client-side equivalent at `project-template/docs/pack/PM-CHAT.md` which is separate content (governs client PM Chat behavior, not pack development).

The Batch 19b PACK-CHAT.md additions (PC-2, PC-6, V11-1, V11-2, V11-5, V11-7, V11-8) stay in pack-repo PACK-CHAT.md. They do NOT propagate to client repos. Client PM-CHAT.md is unchanged in this batch.

---

## §L — Open questions remaining for user / Pack Chat

Per the task constraints ("Anything you don't answer becomes a discussion item"), I list every question I cannot resolve without further user input. The goal is to keep this section near-empty.

### L.1 — V11-8 disposition: NEW-HOME inline (my recommendation) vs NEW-BD-173 (first architect's recommendation)

Per §A.2 challenge: I reclassify V11-8 as NEW-HOME (6-line inline bullet in PACK-CHAT.md). The first architect recommended NEW-BD-173. Per OQ-1, opening BD-173 requires user-discussion-and-approval.

**User decision needed BEFORE the planner sequences Commit 19b-2** (the PACK-CHAT.md commit). If user accepts NEW-HOME, the inline bullet from §B (V11-8 row) lands in Commit 19b-2. If user prefers BD-173, the planner sequences a separate BD-173 commit (and PACK-CHAT.md gets only a cross-reference, not the inline bullet).

### L.2 — L8.1 STATUS.md disclaimer canonical wording

Per §B (L8.1 row): the canonical wording between PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 and ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.3 is a Pack-Chat decision (PM-owned per task constraints).

**User decision needed for Pack Chat**, not pack-coder. Architecture-doc edit to the per-entry-split corpus is excluded from this strategy's scope.

### L.3 — Trinity-file size soft-guidance overflow

Per §I.3: estimated post-batch trinity grows to ~310 lines, exceeding Claude Code's 200-line soft guidance. Three options surface for user:

1. Accept the overflow (CLAUDE.md has no hard cap; 310 lines is workable).
2. Future architecture pass to split `## Pack memory` across `@`-imported sub-files (substantial architecture work; out of scope for Batch 19b).
3. Tighten bullet wording across the board (reduces line count without splitting; some loss of detail).

**User decision NOT needed before Batch 19b ships** — option 1 is the default. Flag for awareness; the user may want option 2 as a future BD.

### L.4 — Memory file regen vs. hand-edit for Tier-1.5 pointer reduction

Per §D.3 + §D.5: the Tier-1.5 reduction reduces 26 memory files from full-text to pointer-only. Two execution options:

1. Pack Chat hand-edits each file with the §D.3 template per §F disposition (manual, error-prone for 26 files).
2. Pack Chat scripts the reduction (small shell script that reads each existing memory file's frontmatter, applies the §D.3 template body, preserves `originSessionId`).

**User decision: option (1) or (2).** My recommendation: option (2) — script the reduction. The script is small (~50 lines) and one-shot. But: the script is itself a piece of code, and per `feedback_pack_chat_does_no_fixes` Pack Chat shouldn't write code. So the script would go to pack-coder. That's added complexity for a one-shot task. Option (1) might be cleaner.

Pack Chat surfaces both options to user; user decides.

### L.5 — V11-12 / V11-13 / V11-14 verification outcome

Per §B (V11-12/13/14 rows): pack-coder verifies whether the existing `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` sections cover the wording needed. If they do, no edit. If they don't, pack-coder extends with the specific text I provided.

**User decision NOT needed pre-execution** — pack-coder's verification report names the outcome; if extensions are made, Pack Chat surfaces the actual edit in the commit-approval gate.

### L.6 — Order of OQ-1 EXECUTION-PLAN §B rewrite vs. existing batches that ALREADY shipped under the old §B

Per §B (PC-1 row): the rewritten §B says "fix-now default; new BDs require user-discussion-and-approval." Existing batches (Batches 1-19) shipped under the OLD §B ("No new BDs are opened for audit findings"). Those batches' outcomes are unchanged — but the rewritten §B's "user-discussion-and-approval" clause is new and applies forward.

**Clarification needed: does the rewrite apply retroactively to in-flight items, or only to items surfaced AFTER the §B rewrite commit lands?** My recommendation: forward-only. Items already triaged under old §B (e.g., any findings from Batch 19h status-flip review) stay under old §B. New findings from Batch 19b cleanup onward apply new §B.

Surface to user for confirmation.

---

## §M — Items intentionally OUT OF SCOPE

Per task constraints, this strategy doc does NOT propose:

- **New substantive features** (no new validate-pack checks, no new test runners, no new agent definitions).
- **Project-template trinity edits** (per OQ-3 — pack-self only; project-side propagation is a future separate batch).
- **Architect-doc edits to the per-entry-split corpus** (PM-owned; L8.1 surfaces as a Pack-Chat action item per §L.2).
- **BACKLOG.md format changes, CHANGELOG.md format changes, per-entry tree contract changes** (stable per Batch 19 work).
- **Tracker-mode design changes** (BD-079 / Phase B scope; out of v11.0 entirely).
- **New BDs** (per OQ-1 + §A.2 challenge — V11-8 reclassified to NEW-HOME; no new BDs opened in Batch 19b unless user accepts BD-173 per §L.1 PENDING-USER).
- **Project-template `## Project memory` extensions** (per §A.8 challenge — out of scope per OQ-3).
- **Splitting `## Pack memory` into `@`-imported sub-files** (per §L.3 — future architecture pass; not a Batch 19b deliverable).
- **Memory-file-format change beyond pointer reduction** (per §D.3 — pointer-only template is the spec; no schema changes to frontmatter beyond `trinity_anchor` field addition).
- **Pack memory propagation to client developer machines via init-project.sh** (per §J.2 — memory cache is per-machine; out of scope).
- **Codex / Gemini memory file design** (per §D — trinity-only for those CLIs; no Codex / Gemini memory file shipped or created).
- **PACK-AGENTS.md restructure beyond the OQ-4 PREFLIGHT cross-ref** (per §E — one bullet addition; no broader restructure).
- **EXECUTION-PLAN-V11.0.md edits beyond §B** (per §B PC-1 row — only §B is rewritten; §A, §C, §D, §E, §F stay as-is).
- **Validation-pack check addition for Tier-1.5 pointer-file integrity** (the §F edits leave the memory cache consistent at edit time; ongoing consistency is a Pack Chat operational nicety, not a pack rule). Could be a future BD.
- **Cross-CLI Codex / Gemini AGENTS.md / GEMINI.md content edits beyond pack-repo trinity Pack-memory section** (the agent-definition files at `.codex/agents/*.toml` and `.gemini/agents/*.md` get the PREFLIGHT obligation text indirectly via trinity reference; no agent-definition-file edits are required in Batch 19b — they will pick up the new rule the next time those files are updated for other reasons).

---

## Document end

This is the final V2 strategy doc. The planner ingests this doc as its primary architect input. Pack Chat surfaces the §L PENDING-USER items to the user BEFORE planner spawns. Once §L is clear, planner can produce `PLAN-CLEANUP-BATCH-19B.md` and sequence work.

**Disagreement summary (for fast reading):**
- §A.1: Collapse first architect's three-tier model to two tiers (Tier 1 trinity + Tier 1.5 Claude pointer cache).
- §A.2: V11-8 NEW-HOME (inline bullet), not NEW-BD-173.
- §A.3: PC-12 label correction (DISCARD, not CONSOLIDATE).
- §A.4: V11-15 specific find-replace text, not "sweep."
- §A.5: L9 worked-example anchor by doc name, not file:line citations.
- §A.6: Merge L4 + PC-10 into one bullet ("Pack-architect spawn protocol").
- §A.7: PC-uncertain-a specific cross-ref text produced.
- §A.8: Drop D-8 (project-template L9 ripple) — out of scope per OQ-3.
- §A.9: Drop "Trinity propagation" framing on V11-19 — pack-repo trinity only per OQ-3.

**Endorsements (for fast reading):** Trinity-first design, PC-1 §B rewrite, PC-3 audit-IS-the-review, PC-4/V11-6 stage-lifecycle promotion, V11-4 / L1 / L2 / L3 / L6 / L7 / L8 dispositions, OQ-6 archive-at-batch-end.

End of ARCHITECTURE-CLEANUP-BATCH-19B-V2.md.
