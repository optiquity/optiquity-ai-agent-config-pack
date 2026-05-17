# ARCHITECTURE-CLEANUP-BATCH-19B — Strategy for the v11.0 rules / memories / ops-docs cleanup pass

**Author:** pack-architect (first pass — Batch 19b cleanup)
**Date:** 2026-05-16
**Branch:** v11-dev (HEAD `cd8246c` — Batch 19 complete, including 19h status flips)
**Status:** First-pass architect output; awaits Pack Chat / user review and
the research-need decision documented in §6 and §9 below.

---

## 1. Summary

This strategy doc triages 40 input items collected during Batches 16–19 of
v11.0 development against the current memory index (29 entries), the pack-repo
trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), `PACK-CHAT.md`,
`PACK-AGENTS.md`, the per-batch `EXECUTION-PLAN-V11.0.md` audit/review-fix
protocol, and the project-template trinity. It also designs the substantive
architecture for the three user strategic concerns (cross-CLI parity, pack
version-update propagation, greenfield install propagation).

The dominant finding is that the Claude-Code-only memory index has grown to
29 entries that act as the de-facto pack workflow rulebook, while Codex and
Gemini sessions have no equivalent surface and the trinity files only carry a
subset of those rules. v11.0 cannot ship in good conscience with this
asymmetry — a Codex or Gemini Pack Chat would not see most of the rules the
Claude Pack Chat treats as authoritative, including high-stakes items like
"Pack Chat does NO fixes" and "Deferral IS scope creep."

The user's stated lean — **single point of truth in trinity files, with
memory as a Claude-only cache that mirrors trinity-file content** — is the
correct design and is achievable inside v11.0. The cleanup batch should
promote the load-bearing memory entries into trinity `## Pack memory`
sub-sections, leave the memory index in place as a one-line-per-entry
Claude-only cache pointing back to trinity anchors, and add a "single source
of truth = trinity" rule so future learnings land trinity-first.

**Counts (40 items total):**

| Category | Count |
|---|---|
| KEEP AS-IS | 8 |
| STRENGTHEN WORDING | 5 |
| CONSOLIDATE | 3 |
| REDIRECT | 4 |
| PROMOTE (Claude-memory → trinity) | 11 |
| DISCARD | 1 |
| NEW HOME NEEDED | 7 |
| NEEDS NEW BD | 1 |

**Research verdict:** **RESEARCH NEEDED — architect will re-run after
researcher.** Three of the items (cross-CLI memory parity for Codex,
cross-CLI memory parity for Gemini, and sub-agent / SendMessage capability
parity for both) require authoritative external verification before the
trinity-first promotion can be designed with confidence. See §6 and §9.

---

## 2. Triage table

Item IDs use the source-section codes:
- `PC-N` = main pack-chat undocumented-rules list (item N)
- `V11-N` = v11-dev undocumented-rules list (item N)
- `SC-N` = user strategic concern N
- `L-N` = current-session learning N
- `L8.1` = sub-learning under L8

Categories: KEEP / STRENGTHEN / CONSOLIDATE / REDIRECT / PROMOTE / DISCARD /
NEW-HOME / NEW-BD.

| ID | One-line summary | Category | Current anchor | Recommended action / new home |
|---|---|---|---|---|
| PC-1 | "No tech debt" rule overrides EXECUTION-PLAN §B "No new BDs for audit findings" | STRENGTHEN | `feedback_deferral_is_scope_creep` + `feedback_no_deferral_without_user_direction` (Claude memory) + EXECUTION-PLAN §B | EXECUTION-PLAN §B language is now obsolete on the "no new BDs" leg — Batches 14b / 22b / 23 contemplated no-BD audit fixes, but per `feedback_deferral_is_scope_creep` unblocked new scope from an audit IS opened as a BD inserted immediately after the audit. Reconcile §B wording to match the memory; tag as "user rule revision 2026-05-16." Also PROMOTE both memories into trinity (see PC-1 anchor in §3). |
| PC-2 | "Stop after reviewer for fix discussion" — no auto-commit even on clean verdict | NEW-HOME | None — implicit in the per-BD review/fix cycle | Add a one-line bullet to PACK-CHAT.md `## Behavioral rules`: "After every pack-reviewer run, Pack Chat STOPS, presents triage to user, and waits — even on clean verdicts. No auto-commit." This is distinct from the implicit-status-flip rule (which fires AFTER fixes land + tests green) and from `feedback_commit_approval_next_steps` (which governs commit-approval wording, not whether a commit fires). |
| PC-3 | "Audit IS the review" — audit fix passes don't need a separate reviewer | KEEP | Implicit in EXECUTION-PLAN §B steps 1–4 (audit produces findings; in-session fix; status flip — no second review interposed) | EXECUTION-PLAN §B already encodes this by structure (steps 1–4 do not insert a second reviewer pass between audit findings and the in-session fix). Add a single clarifying sentence in §B step 3: "An audit pass IS the review; no separate pack-reviewer is run on the audit-fix commit." |
| PC-4 | Agent-team / SendMessage stage-lifecycle policy | KEEP | `feedback_agent_teams_stage_lifecycle` (Claude memory) | Already covered. PROMOTE to trinity per §3 (Claude-Code-specific: the rule references the AGENT_TEAMS=1 mode + the Agent tool's SendMessage verb; mark with the same "Trinity exemption" pattern used today for the worktree-isolation rule, IF research confirms Codex/Gemini lack equivalents — see §6). |
| PC-5 | Hard stop point for sidecar work — pause after Batch 16; remind user of stopping point | DISCARD | Session-only directive that has already been honored | Session-scoped directive that was applied at the time. The general pattern ("user retains hard-stop authority") is already captured by L6 / `feedback_no_destructive_without_approval` / `feedback_commit_approval_next_steps`. No standing rule needed. |
| PC-6 | Sidecar / primary chat file-ownership boundary | NEW-HOME | None | Add a new PACK-CHAT.md `## Behavioral rules` bullet: "Chat-ownership of files. When two pack-chats run concurrently against the same repo (e.g., sidecar / primary), the user assigns file-ownership boundaries; no two chats touch the same file. When ownership is unclear, ask the user — never guess." Cross-link to PC-7 (same rule, narrower scope). |
| PC-7 | "Don't read or commit files you didn't request or write; ask, don't guess" | CONSOLIDATE | None | Subsumed by PC-6. Single bullet covers both. |
| PC-8 | "Carry-forward notes need a tracked home — hope is not acceptable" | KEEP | `feedback_deferred_work_tracking` (Claude memory) | Already covered word-for-word. PROMOTE to trinity per §3. |
| PC-9 | "Use next available BD numbers; don't skip" — sidecar BD reservations are not authoritative | KEEP | CLAUDE.md / AGENTS.md / GEMINI.md "BD-NNN numbering" rule ("read BACKLOG.md, find the highest existing BD-NNN, increment by 1") | Trinity already covers it. STRENGTHEN by adding one sentence: "Reservation lists from other chats / planning docs are not authoritative — always read the live BACKLOG before assigning." |
| PC-10 | Pack-architect needs explicit approval before spawning | NEW-HOME | None | Add to PACK-CHAT.md `## Behavioral rules`: "No pack-architect spawn without explicit user approval. Pack-planner / pack-coder / pack-reviewer / pack-docs-researcher follow the established Pack Chat triage; pack-architect is an explicit user-approved spawn even when scope clearly calls for it." Rationale: an architect pass commits Pack Chat to a multi-stage pipeline (architect → planner → coder → reviewer) and reorders future BD work; not Pack-Chat's call to make. |
| PC-11 | docs-researcher → architect → planner → coder pipeline for substantive content | KEEP | `feedback_researcher_architect_planner_pipeline` (Claude memory) | Already covered. PROMOTE to trinity per §3. |
| PC-12 | Fix-pass approach varies by content type (tiny/mechanical vs non-trivial) | CONSOLIDATE | `feedback_pack_chat_does_no_fixes` (Claude memory) | The "no Pack-Chat fixes" rule INTENTIONALLY has no size threshold per its own wording ("no threshold exception"). PC-12 contradicts the standing rule and should be DISCARDED in favor of the memory's explicit no-threshold posture. The cleanup batch must NOT codify a tiny-fix carve-out. |
| PC-13 | Pre-commit verification — show diff stat / file list before approval | KEEP | PACK-CHAT.md `## Behavioral rules` ("No commit without explicit approval ... Always run `git add -A && git status` and show the result before any commit") + EXECUTION-PLAN §A.1 | Already covered. No action — verify the wording is byte-equivalent across PACK-CHAT.md and EXECUTION-PLAN. |
| PC-uncertain-a | "Per-action approval applies to Claude AND spawned sub-agents" — possible extension beyond the original rule | STRENGTHEN | `feedback_no_destructive_without_approval` (Claude memory, current wording explicitly says "applies to Claude AND spawned sub-agents") | Memory wording already covers it. The agent-side anchor lives in PACK-AGENTS.md `## Agent permission rules` ("Git state changes are forbidden for ALL agents"). STRENGTHEN by adding a one-line cross-reference in the trinity Pack-memory section explicitly naming the sub-agent extension, so the user concern (was this an extension or the original?) is resolved in trinity. |
| PC-uncertain-b | "Default sub-agent spawns to background" — already in memory; reinforced this session | KEEP | `feedback_spawn_agents_in_background` (Claude memory) | Already covered. PROMOTE to trinity per §3 (likely Claude-Code-specific: the run_in_background parameter is a Claude Code Agent-tool feature; mark with Trinity exemption pending research). |
| V11-1 | "Fix has to be real, not a band-aid to make it green" | NEW-HOME | None | Add to PACK-CHAT.md `## Behavioral rules`: "Real fixes only — no green-the-test band-aids. A fix that suppresses a failure without addressing the underlying defect is a defect itself; reviewer will flag it." Distinct from `feedback_fix_all_review_findings` (scope) — this is depth. |
| V11-2 | Anti-sycophancy / direct-opinion rule | NEW-HOME | None | Add to PACK-CHAT.md `## Behavioral rules`: "Direct opinion, not validation. Base analysis on evidence and logic; state what you actually think; do not echo the user's framing to be agreeable. The user has flagged sycophancy as a recurring failure mode." Applies to Pack Chat surface — agent prompts already have "no solutions in prompts" which is a related but distinct rule. |
| V11-3 | "Don't read/commit files you didn't request or write" | CONSOLIDATE | None | Same as PC-7. Single bullet under PC-6. |
| V11-4 | "Lean to doing work in v11.0 — not delay to v11.1 or v12" | KEEP | `feedback_no_deferral_without_user_direction` (Claude memory) | Already covered. PROMOTE to trinity per §3. |
| V11-5 | "Push only to v11-dev, never to main during v11-dev phase" | NEW-HOME | EXECUTION-PLAN §A.4 ("Push to `v11-dev` only. Never push to `main` from this chat. v11.0 ships via deliberate handoff at Batch 24.") | Covered in EXECUTION-PLAN §A. STRENGTHEN by adding a one-line bullet in PACK-CHAT.md `## Behavioral rules` so the rule is visible without reading the execution plan: "Push to `v11-dev` only during v11-dev development phase; never push to `main`." Branch-policy memory is short-lived (resolves when v11.0 ships) but load-bearing right now. |
| V11-6 | "Fresh coder agent per commit / per batch (incl. repeat passes)" | NEW-HOME | None — implicit in `feedback_agent_teams_stage_lifecycle` ("After commit, close them and use new sub-agents") | The stage-lifecycle memory already implies this at end-of-stage. STRENGTHEN by extending the memory wording: "Fresh pack-coder per commit AND per repeat pass on the same BD — never re-use a coder instance across commits, even within a stage. Per-BD review/fix cycle = fresh coder for the implementation, fresh coder for the fix." Differs from the stage-lifecycle wording which is end-of-stage rather than per-commit. |
| V11-7 | Scope-extension decision test — symmetric pair / same-feature-surface → SendMessage extend, not new BD | NEW-HOME | None | Add to PACK-CHAT.md `## Behavioral rules`: "Scope-extension test for in-flight work. When the in-flight work surfaces a symmetric pair or same-feature-surface item, extend in-session via SendMessage rather than open a new BD. New BDs are reserved for new scope, new feature, new architecture — not the second half of a feature already in progress." Cross-link to existing CLAUDE.md "Workflow > One review/fix cycle per batch" bullet which already says "BDs are reserved for new scope / new feature / new architecture." |
| V11-8 | Single-BD batch close vs multi-BD batch close (combined commit vs separate commits) | NEEDS NEW BD | None | This is a tactical commit-shape pattern with no current home. Recommended: open BD-173 — "Codify single-BD vs multi-BD batch-close commit-shape convention in EXECUTION-PLAN-V11.0.md §A / §C" — small (≤30 lines of doc + cross-link from PACK-CHAT.md). Lands in v11.0 per `feedback_no_deferral_without_user_direction`. Insertion point: immediately after Batch 19b cleanup. Marked NEW-BD rather than NEW-HOME because it is more than a one-line rule — it is a worked pattern with two distinct shapes. |
| V11-9 | `PACK-REVIEW-BD-NNN-RETRO.md` naming convention | NEW-HOME | CLAUDE.md `## Pack memory > Repo conventions > Skill and agent maintenance > Workflow artifacts` list mentions `PACK-REVIEW-*.md` but not the `-RETRO` suffix | STRENGTHEN the existing CLAUDE.md/AGENTS.md/GEMINI.md workflow-artifacts list by adding `PACK-REVIEW-*-RETRO.md` and `IMPLEMENTATION-REPORT-*-RETRO-FIX.md` to the enumerated patterns. Also add `CLEANUP-INPUTS-*.md` (this file). Same Pattern B archive-on-version-ship treatment. |
| V11-10 | Retro fix commit-message format `fix: v11 — BD-NNN retroactive per-BD review-fix (Batch 21c)` | NEW-HOME | CLAUDE.md / AGENTS.md / GEMINI.md "Commit message format" section enumerates only base forms (feat:, fix:, docs:) | Trinity Commit-message-format section is the right home. STRENGTHEN by adding an enumerated list of approved suffixes for the `fix:` form: `(Batch N)`, `(Batch Nx)`, `retroactive per-BD review-fix (Batch N)`, `broad batch review/fix`. Keeps the rules-as-data structure rather than leaving Pack Chat to invent commit-message shapes. |
| V11-11 | "Trial run before scaling" pattern | KEEP | None | Tactical pattern that has been used twice but is a Pack-Chat heuristic rather than a load-bearing rule. KEEP unwritten — the situations where it applies are too context-specific to codify cleanly without producing a rule that is more confusing than helpful. Pack Chat can continue to use it when appropriate; if it becomes load-bearing across multiple batches, revisit. |
| V11-12 | Retro review prompts must source File/Symbol from BACKLOG entry + git --stat, not prose recall | REDIRECT | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "File/Symbol scope from authoritative sources, not prose recall" (already exists) | Already exists in CONCEPTUAL-REVIEW-METHODOLOGY.md per the grep. Verify the wording covers the retro-specific case. If not, STRENGTHEN that existing section. No new home needed. |
| V11-13 | CI-touching work prompts must include "concrete change → red verification" | REDIRECT | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "CI-step interrogation heuristic" (already exists) | Already exists. Verify wording covers the must-include-in-prompt aspect; STRENGTHEN if needed. |
| V11-14 | Convention/naming docs need a finding-mode checklist | REDIRECT | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Convention/naming docs review checklist" (already exists) | Already exists. No action unless wording is weak — verify and STRENGTHEN if needed. |
| V11-15 | Reviewer prompt template factual error: cites `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); canonical doc is `EXECUTION-PLAN-V11.0.md` | NEW-HOME | None — template error per V11-15 | This is a defect in the reviewer prompt template Pack Chat carries, not a rule. The fix is mechanical (find and replace in the template wherever Pack Chat keeps it). If the template lives in `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` or similar, fix it there. Cleanup batch should sweep for any stale `IMPLEMENTATION-PLAN-V11.0.md` references across pack-ops docs. |
| V11-16 | Default-to-recommended option in AskUserQuestion | KEEP | Claude Code tool docs (default behavior) | Tool-doc default; not a user rule per V11-16's own uncertainty. No action. |
| V11-17 | "approved" without option name = approve recommended/Option A | KEEP | None — session inference | Session inference per V11-17's own caveat. Not a load-bearing rule. No action. |
| V11-18 | AskUserQuestion only when there's a real branch point | NEW-HOME | None | Soft preference per V11-18's own uncertainty. RECOMMEND: do not codify yet — the boundary is fuzzy and the user has not stated this as a rule explicitly. Pack Chat continues current judgment; if it becomes load-bearing, revisit. |
| V11-19 | No // TODO / carry-forward comments in code without a tracking BD or live-doc anchor | REDIRECT | `feedback_deferred_work_tracking` (Claude memory) + `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene" (already covers code-side TODO/KNOWN GAP/VERIFY with TD-TBD format) | The client-side trinity (`project-template/CLAUDE.md` lines 296-326) already covers code-comment TODOs with the typed `TODO(scope)` / `KNOWN GAP(severity)` / `VERIFY(source)` format and TD-TBD requirement. For PACK-REPO code (not client code): no equivalent in pack-repo trinity. RECOMMEND: add a one-line bullet to pack-repo CLAUDE.md / AGENTS.md / GEMINI.md `## Pack memory > Repo conventions`: "Code-comment deferrals in pack-repo source follow the same typed format as project-template/CLAUDE.md § 'Deferral comments' — never plain English `// TODO` or `// fix later`." Trinity propagation. |
| SC-1 | Cross-CLI parity for rules (Claude memory ↔ Codex equivalent ↔ Gemini equivalent) | (See §3) | (See §3) | (See §3) — substantive design pending research verification. |
| SC-2 | Pack version update propagation (rule change → existing client repos) | (See §4) | (See §4) | (See §4) — design landed under user's "single point of truth in trinity" lean. |
| SC-3 | Greenfield install propagation (rule change → new client repos via init-project.sh) | (See §5) | (See §5) | (See §5) — design landed under same lean. |
| L1 | Pack Chat is not a coder agent | KEEP | `feedback_pack_chat_does_no_fixes` (Claude memory) | Already covered. PROMOTE to trinity per §3. |
| L2 | Deferral IS scope creep | KEEP | `feedback_deferral_is_scope_creep` (Claude memory) | Already covered. PROMOTE to trinity per §3. Note this is the rule that obsoletes EXECUTION-PLAN §B's "No new BDs for audit findings" — PC-1 reconciliation. |
| L3 | Per-BD review/fix runs INLINE before next BD's coder | STRENGTHEN | `feedback_review_fix_one_cycle` (Claude memory — updated 2026-05-15) | Memory wording per L3 may not yet make the inline-before-commit aspect unambiguous. STRENGTHEN the memory file to explicitly say "per-BD = INLINE before the next BD's coder spawns; never retroactive at end of batch except for pre-2026-05-15 batches caught up via Batch 21c-style retro recovery." Then PROMOTE to trinity per §3. |
| L4 | Architect-first pattern for rules / operating docs | NEW-HOME | None | Add to PACK-CHAT.md `## Behavioral rules`: "Architect-first for rules / operating docs. When the work touches rules (memory, PACK-CHAT.md, PACK-AGENTS.md, trinity Pack memory sections), spawn pack-architect FIRST to design a strategy doc; pack-coder applies mechanically after user approves the strategy. No Pack-Chat-direct rule edits beyond mechanical typo fixes." Pairs with PC-10 (architect-spawn requires user approval). |
| L5 | Pack Chat presents triage to user before fix-coder spawns | KEEP | `feedback_pack_chat_does_no_fixes` (Claude memory) + `feedback_fix_all_review_findings` (Claude memory) | Together these two memories already cover the triage-gate pattern. STRENGTHEN ONE of them (recommend `feedback_pack_chat_does_no_fixes`) by extending the wording: "Pack Chat triages findings (MUST/SHOULD/NIT) with FIX vs SKIP per finding (rationale for SKIPs), presents triage to user, fix-coder runs in background after user approval, user approves the resulting commit (not per-finding)." Then PROMOTE to trinity per §3. |
| L6 | User retains hard-stop authority | KEEP | `feedback_no_destructive_without_approval` + `feedback_commit_approval_next_steps` (Claude memories) | Already covered by union of those two. PROMOTE the consolidated principle to trinity as part of the §3 promotion sweep. |
| L7 | Working files / inputs files convention (`CLEANUP-INPUTS-*` + `PACK-REVIEW-*-RETRO.md` + `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`) | STRENGTHEN | CLAUDE.md `## Pack memory > Repo conventions > Skill and agent maintenance` enumerates workflow artifacts but not these new patterns | Same as V11-9. STRENGTHEN the trinity workflow-artifact list to add the three new patterns (`CLEANUP-INPUTS-*.md`, `PACK-REVIEW-*-RETRO.md`, `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`). Same Pattern B archive-on-version-ship treatment. |
| L8 | Sub-agent SendMessage-stop defiance + PREFLIGHT pattern | PROMOTE | `feedback_pack_coder_preflight_pattern` (Claude memory) | Already in memory. Decide cross-CLI propagation pending research (§6 R-3). If Codex/Gemini lack sub-agent spawning, PROMOTE to trinity with Trinity exemption (Claude-Code-specific). If they have it, design parallel surface in Codex/Gemini trinity equivalents. Either way, also add a PACK-AGENTS.md `## Agent permission rules` cross-reference so the agent-side authority is visible from the agent contract. |
| L8.1 | Architect-doc divergence: STATUS.md disclaimer literal (`PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.8 vs `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.3) | KEEP | Documented in `IMPLEMENTATION-REPORT-BD-169.md` §6.1 | This is a documentation coordination cleanup item (one wording is now canonical — whichever was followed at BD-169 — and the other architect text needs an addendum cross-reference). Per the task constraints ("Do NOT propose architect-doc edits to the per-entry-split corpus — those are PM-owned"), the cleanup batch surfaces this as a PM action item rather than fixing it in code. Pack Chat (not pack-coder) reconciles. |
| L9 | Architect-doc-vs-reality reconciliation pattern (BD-119 §9.2 addendum + BD-160 docstring + IMPL-REPORT cross-reference) | PROMOTE | Worked example in `ARCHITECTURE-BD-119.md` §9.2 addendum (lines 652-666) + `scripts/lib/migrator-core.sh` docstring (lines 505-518) + `IMPLEMENTATION-REPORT-BD-160-170.md` line 38 | Pattern is load-bearing for v11.x onward (every future shipped surface that pre-existed in architect docs needs the same chain). PROMOTE to a new trinity `## Pack memory > Repo conventions` bullet: "Architect-doc-vs-reality reconciliation. When a BD realizes a design anticipated in an architect doc, ship the chain: (a) in-code docstring naming the realized consumer; (b) architect-doc addendum cross-referencing the realized consumer; (c) IMPL-REPORT cross-reference linking both. Worked example: BD-119 §9.2 addendum → migrator-core.sh:505-518 → IMPLEMENTATION-REPORT-BD-160-170.md:38." Also add to memory index. |

---

## 3. Cross-CLI parity strategy

### 3.1 Current state

The Claude-Code memory at `~/.claude/projects/<project-slug>/memory/*.md`
contains 29 entries that act as the de-facto pack workflow rulebook. Codex
and Gemini sessions see none of them. The trinity files (`CLAUDE.md` /
`AGENTS.md` / `GEMINI.md` at the pack repo root) carry only a subset under
the `## Pack memory` H2 — currently approximately 14 of the 29 memory entries
have trinity coverage (workflow / agent-invocation / sub-agent-isolation /
repo-conventions / project-goals sub-sections). The other ~15 entries are
Claude-Code-only.

Examples of LOAD-BEARING memory entries with NO trinity coverage today:
- `feedback_pack_chat_does_no_fixes` (no Pack-Chat-direct fixes)
- `feedback_deferral_is_scope_creep` (Deferral IS scope creep)
- `feedback_no_deferral_without_user_direction` (No v11.1+ deferral while
  v11.0 unlaunched)
- `feedback_fix_all_review_findings` (Triage all reviewer findings;
  default fix-all; nits become tech debt)
- `feedback_deferred_work_tracking` (Deferrals need tracked home; archived
  reports not acceptable)
- `feedback_pack_coder_preflight_pattern` (STOP-MEANS-STOP + PREFLIGHT)
- `feedback_commit_approval_next_steps` (Commit-approval prompts include
  next-steps plan)
- `feedback_researcher_architect_planner_pipeline` (Researcher → architect
  → planner pipeline)
- `feedback_test_infra_self_provisioned`
- `feedback_filename_uniqueness`
- `feedback_no_solutions_in_agent_prompts` (PARTIALLY covered — trinity
  has "No solutions in agent prompts" in Agent-invocation-rules)
- `feedback_chunk_long_outputs`
- `feedback_no_prior_reviews_to_reviewer`
- `feedback_review_fix_one_cycle`

A Codex or Gemini Pack-Chat session today would not see any of the load-
bearing rules above. This is a material asymmetry that v11.0 must close.

### 3.2 User's stated lean (verbatim from CLEANUP-INPUTS § Common theme)

"Single point of truth in trinity files, with memory as a Claude-only cache
that mirrors trinity-file content. The architect should design the seam to
honor this leaning unless there is a strong reason against it."

I find no strong reason against. Trinity-first is the right design. Memories
become a Claude-Code convenience layer; the trinity is authoritative.

### 3.3 Three-tier model (recommended)

**Tier 1 — Trinity (authoritative, cross-CLI).** All load-bearing pack rules
live in trinity `## Pack memory` sub-sections (Workflow / Agent invocation
rules / Sub-agent behavior / Repo conventions / Project goals + any new
sub-sections needed). Trinity is the single source of truth. Any rule change
edits trinity FIRST.

**Tier 2 — Tool-native memory caches (convenience, mirror).** Each CLI's
native memory surface (Claude Code's `~/.claude/projects/.../memory/*.md`;
Codex equivalent if any; Gemini equivalent if any) carries a one-line-per-rule
index that POINTS to the trinity anchor for the authoritative text. Memory
entry shape:

```
- [Short title](trinity-anchor-or-anchor-id) — one-line summary
```

When the trinity rule changes, the memory line updates the summary but
points to the same trinity anchor. Memory NEVER carries text that contradicts
trinity, and NEVER carries rules that are not in trinity.

**Tier 3 — Tool-specific exemptions (rare, explicit).** Rules that are
PROVABLY tool-specific (e.g., Claude Code's Agent-tool worktree isolation,
or the Codex sandbox-mode flags) live in only the relevant trinity file and
carry an explicit "Trinity exemption" annotation per the existing pattern
used today for `### Sub-agent isolation (Claude-only)`. Tier 3 is the
exception; symmetry is the default.

### 3.4 Open dependency on research (§6 R-1 + R-2 + R-3)

Whether Codex and Gemini have memory equivalents AT ALL determines whether
Tier 2 has a multi-CLI shape or stays Claude-Code-only:

- **If Codex has app-level memory:** add a Codex-native cache mirroring the
  Claude cache; same one-line-per-rule shape. Where it lives depends on the
  Codex CLI's storage convention (research item R-1).
- **If Codex does NOT have app-level memory:** Codex sessions rely 100% on
  the trinity `AGENTS.md` file in the pack repo, which Codex loads
  automatically at session start (confirmed — see line 4 of current
  `AGENTS.md`). No Tier 2 needed for Codex.
- **If Gemini has app-level memory:** same as Codex.
- **If Gemini does NOT have app-level memory:** Gemini sessions rely 100% on
  trinity `GEMINI.md`. No Tier 2 needed for Gemini.

The trinity-first promotion (Tier 1) works regardless of Codex/Gemini memory
capability. The research blocks only the Tier 2 design choice for the
non-Claude CLIs.

### 3.5 Promotion sweep (the actual work for pack-coder)

The cleanup batch promotes ~11 currently-Claude-only memory entries into
trinity `## Pack memory`. Mapping:

| Memory entry | Recommended trinity sub-section | Rationale |
|---|---|---|
| `feedback_pack_chat_does_no_fixes` | NEW sub-section `### Pack Chat scope` (sibling of Workflow) | Defines what Pack Chat does and does NOT do (orchestrator, not editor) |
| `feedback_deferral_is_scope_creep` | EXTEND `### Workflow` | Sits next to "One review/fix cycle per batch" / "Implicit BD status flip" |
| `feedback_no_deferral_without_user_direction` | EXTEND `### Workflow` | Same as above; v11-active-version-specific clause |
| `feedback_fix_all_review_findings` | EXTEND `### Workflow` | Triage + fix-all default |
| `feedback_deferred_work_tracking` | EXTEND `### Workflow` | Deferral chain-of-custody |
| `feedback_pack_coder_preflight_pattern` | EXTEND `### Agent invocation rules` | PREFLIGHT + STOP-MEANS-STOP for pack-coder prompts |
| `feedback_commit_approval_next_steps` | NEW sub-section `### Pack Chat scope` | Commit-approval prompt wording |
| `feedback_researcher_architect_planner_pipeline` | EXTEND `### Agent invocation rules` | Pipeline ordering rule |
| `feedback_test_infra_self_provisioned` | KEEP under `### Repo conventions` (already there) | Already in trinity — verify |
| `feedback_no_solutions_in_agent_prompts` | KEEP under `### Agent invocation rules` (already there) | Already in trinity — verify wording strength |
| `feedback_chunk_long_outputs` | KEEP under `### Agent invocation rules` (already there) | Already in trinity — verify |
| `feedback_no_prior_reviews_to_reviewer` | KEEP under `### Agent invocation rules` (already there) | Already in trinity — verify |
| `feedback_review_fix_one_cycle` | KEEP under `### Workflow` (already there) | STRENGTHEN per L3 to make inline-before-commit unambiguous |
| `feedback_filename_uniqueness` | EXTEND `### Repo conventions` | Project-wide pattern |
| L4 (architect-first for rules) | NEW under `### Pack Chat scope` | Pairs with PC-10 |
| L9 (architect-doc-vs-reality reconciliation) | EXTEND `### Repo conventions` | Pattern with worked example |

Existing trinity sub-sections that need restructuring to absorb the new
content:

- `### Workflow` becomes the cycle/lifecycle section (review/fix, status
  flips, deferral discipline, fix-now vs defer-tracking).
- `### Agent invocation rules` becomes the agent-prompt-construction section
  (PREFLIGHT, no-solutions, chunked-Edit, no-prior-reviews, researcher
  pipeline).
- `### Sub-agent isolation (Claude-only)` stays as-is (Trinity exemption).
- NEW `### Pack Chat scope` consolidates Pack-Chat-specific behavioral rules
  (no Pack-Chat fixes, commit-approval prompt wording, architect-first for
  rules, presents-triage-to-user pattern).
- `### Repo conventions` absorbs filename-uniqueness, architect-doc-vs-
  reality reconciliation, workflow-artifact patterns (extend list to add
  `PACK-REVIEW-*-RETRO.md`, `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`,
  `CLEANUP-INPUTS-*.md`).
- `### Project goals (v11)` stays as-is.

### 3.6 Memory index simplification

After promotion, the Claude-Code memory index at
`~/.claude/projects/<project-slug>/memory/MEMORY.md` becomes:

```
This index points to the trinity rules at <pack-repo>/CLAUDE.md `## Pack memory`.
Trinity is authoritative; this file is a Claude-Code convenience cache.

- [Trinity rule](#trinity-rule-claude--agents--gemini) — modify all three together
- [Pack Chat does NO fixes](#pack-chat-does-no-fixes) — orchestrator, not editor
- [Deferral IS scope creep](#deferral-is-scope-creep) — fix-now is scope containment
- ... (one line per trinity rule with a trinity-anchor link)
```

Memory files that survive as STANDALONE entries (not mirrored into trinity)
are the Claude-Code-specific operational ones that pack-coder cannot fix
because they're about chat behavior, not pack rules:
- `feedback_spawn_agents_in_background` — Claude Code Agent-tool default
- `feedback_agent_teams_stage_lifecycle` — AGENT_TEAMS=1 mode operation
- `feedback_no_prefix_chars` — copy-paste-text formatting
- `feedback_worktree_isolation_broken_from_v11_clone` — Claude Code Agent
  tool worktree behavior
- `feedback_pack_coder_preflight_pattern` — IF research shows Codex/Gemini
  have no sub-agent equivalent (Trinity exemption pattern)

If research shows Codex/Gemini have sub-agent spawning, then the last entry
above promotes to trinity instead.


---

## 4. Version-update propagation strategy

### 4.1 Current state

When a project gets a pack version bump (`init-project.sh --update`), the
existing `customization-preserve` library (BD-088) and the merge-strategy
contract handle pack-source trinity-file updates without overwriting client
edits. Verified via `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (greps
for `## Project memory` and `## Project addenda` H2 markers in trinity
files) and via the BD-088 invariants exercised in
`scripts/persona-contracts/contract-customization.sh`.

Memories do NOT propagate today — they are personal and per-machine
(`~/.claude/projects/<project-slug>/memory/*.md`).

### 4.2 Trinity-first design (under the user's lean)

With trinity as the single source of truth (per §3), rule propagation across
pack version updates uses the EXISTING customization-preserve mechanism. No
new propagation surface is needed.

Concretely:
- A pack v11.0 → v11.1 update that changes a rule edits the rule text in
  pack-repo trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` and the parallel
  `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`).
- The next pack-update at a client repo pulls the new pack-trinity content
  via `init-project.sh --update` → `customization-preserve` merge contract.
- Client edits in `## Project addenda` (and any client-protected blocks) are
  preserved; pack-controlled blocks above `## Project addenda` are updated
  to the new pack-trinity content.
- The merger contract (per BD-088 + BD-136 marker-aware merge) handles
  Shape A + Shape B cases per the existing forward-migration flow.

### 4.3 Memory propagation: none required

Under the trinity-first design, memory is a Claude-Code-only convenience
cache that points to trinity anchors. When trinity content changes:
- The trinity update propagates to the client repo via the existing
  mechanism (§4.2 above).
- The Claude-Code memory cache at the client developer's local
  `~/.claude/projects/...` is regenerated by Claude Code from trinity at the
  next session start (Claude Code reads `CLAUDE.md` at session start; the
  memory index is a convenience pointer that does NOT need to round-trip
  through pack version updates).

This means memory files don't need a "ship from pack" mechanism. They're
developer-local convenience caches. The trinity is the wire format.

### 4.4 What this DOES NOT do

The trinity-first model does not propagate Claude-Code-only operational
rules (e.g., `feedback_no_prefix_chars` — copy-paste-text formatting rule
that is about chat tooling, not pack content) into Codex / Gemini contexts.
Those rules stay in the Claude-Code memory cache and never propagate. This
is correct — they don't belong in trinity because they're not pack rules,
they're chat-tool conventions.

### 4.5 What changes for v11.0 → v11.1 specifically

If the cleanup batch lands as designed (sections 3 promotion sweep + the
NEW-HOME additions to PACK-CHAT.md), the v11.0 → v11.1 update cycle gives
existing client repos:
- Updated trinity content (via customization-preserve).
- Updated PACK-CHAT.md (if PACK-CHAT.md is pack-shipped to clients — see §5
  note on this).

If PACK-CHAT.md is NOT pack-shipped to client repos (it lives only at the
pack-repo root), then client repos do not need PACK-CHAT.md updates at all.
This needs verification — see Open Question OQ-2 in §8.

---

## 5. Greenfield install propagation strategy

### 5.1 Current state

`init-project.sh` (default flow, not `--update`) installs at stages S0..S11.
Stage S11 installs v11 client-side artifacts including:
- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (trinity)
- HELP fragments, tracker config example, issue templates, per-CLI skills,
  per-CLI agents.

No memory files install. No `PACK-CHAT.md` install. No `PACK-AGENTS.md`
install. Client repos get only the project-template content.

The client-side trinity (`project-template/CLAUDE.md` line 320 `## Project
memory`) already exists and carries 3 client-side rules (Trinity rule, No
destructive operations without approval, PM chat does not architect). This
section is the client equivalent of pack-repo trinity `## Pack memory`.

### 5.2 Trinity-first design (under the user's lean)

For greenfield installs, the existing project-template trinity install
covers the client-side rule surface completely. No new files install.

For the pack-repo rules (the 29 memory entries from §3), those govern
PACK DEVELOPMENT — Pack Chat working on the pack repo itself. They DO NOT
govern client projects. Client repos use the project-template trinity for
their own PM Chat / agent rules. The pack-repo memory entries do not need
to install to client repos at all.

This means greenfield install requires NO new propagation surface. The
existing `init-project.sh` S11 stage already covers the client-side trinity,
which is the only rules surface clients need.

### 5.3 Asymmetry check

The user's lean (single source of truth in trinity files) applies separately
to two surfaces:
- **Pack-repo trinity** (`<repo-root>/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)
  — governs pack-development sessions. Memory is a Claude-Code convenience
  cache. Audience: David (the pack maintainer).
- **Project-template trinity** (`project-template/CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md` — installed at client repos) — governs client-project PM-Chat /
  agent sessions. No memory cache equivalent (client developers have their
  own per-project memory at their own discretion). Audience: client
  developers using the pack.

These two trinities are SEPARATE files with DIFFERENT content. The pack
repo's `CLAUDE.md` is NOT a template; it is the pack-development rulebook
(line 4 of current pack-repo CLAUDE.md: "This file is read by Claude Code
CLI agents working on the pack repo itself. It is NOT a template and is
NOT copied to coding projects.").

The cleanup batch's promotion sweep (§3.5) edits PACK-REPO trinity, not
project-template trinity. Project-template trinity is touched only if a
rule applies symmetrically to client projects (e.g., L9 architect-doc-vs-
reality reconciliation applies broadly enough that the client trinity
should also carry it). See per-item triage (§2) for client-side
propagation flags.

### 5.4 PACK-CHAT.md and PACK-AGENTS.md ship?

These two files live at the pack-repo root and govern Pack-Chat / pack-
agent operations. The naming convention "PM-CHAT.md" + "AGENTS-PROJECT.md"
(or similar) is the client-side equivalent. Greenfield installs ship the
client-side equivalents, not the pack-side files. Verified — see
`project-template/docs/pack/PM-CHAT.md` and similar (per README Repository
Layout).

This means PACK-CHAT.md and PACK-AGENTS.md additions from the cleanup batch
(per §2 NEW-HOME items) do NOT propagate to client repos. They're pack-ops
files that stay in the pack repo. This is correct under the separation-of-
pack-ops-from-pack-product rule (`feedback_ops_product_separation`).

If a rule added to PACK-CHAT.md ALSO needs a client-side counterpart, the
cleanup batch must add the parallel rule to project-template/docs/pack/PM-
CHAT.md (or wherever the client-side PM-Chat rule surface lives). See per-
item triage for which items need both.

### 5.5 The TWO trinity systems

To make this concrete: there are TWO trinity systems in the pack repo:

| Trinity | Location | Audience | Governs |
|---|---|---|---|
| Pack-repo trinity | `<repo-root>/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | David / pack-development sessions | Pack-development rules, Pack-Chat behavior, pack-agent permissions |
| Project-template trinity | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | Client developers using the pack | Client-project rules (universal layer discipline, capabilities pattern, deferral comments, etc.) |

Both trinities have `## Project memory` (project-template) or `## Pack
memory` (pack-repo) sub-sections. They are SEPARATE files with SEPARATE
content. The trinity RULE (modify all three together) applies WITHIN each
trinity, not BETWEEN them.

The cleanup batch primarily edits the pack-repo trinity. It edits the
project-template trinity only where a pack-development rule has a clear
client-side parallel (e.g., L9 reconciliation pattern; V11-19 code-comment
deferral typing — already present in project-template).

---

## 6. Research-need analysis

The triage above produces three research items requiring external
verification before the second architect pass. All three are CLI-capability
questions answerable by reading authoritative tool documentation.

### R-1 — Codex CLI memory and sub-agent capabilities

**Question:** Does Codex CLI support:
(a) Persistent file-based memory equivalent to Claude Code's
    `~/.claude/projects/<project-slug>/memory/*.md` (an app-level local
    convenience cache that auto-loads at session start)?
(b) Sub-agent spawning (a parent session that delegates work to a typed
    sub-agent and receives its output)?
(c) Inter-agent messaging equivalent to Claude Code's SendMessage tool?

**Verdict:** (R) — Research needed.

**Research target for pack-docs-researcher:**
- Codex CLI official documentation (whichever URL or repo serves as the
  authoritative reference for Codex CLI's persistence, session, and agent
  features).
- `.codex/agents/` and `.codex/skills/` conventions in the current pack to
  understand what the pack already assumes Codex supports.
- The `AGENTS.md` file load convention (confirmed: Codex auto-loads
  `AGENTS.md` at session start per current pack docs — this is the trinity
  fallback for "no memory" scenarios).

**Why it matters for the cleanup batch:** R-1 (a) determines whether Tier 2
of the §3.3 model has a Codex shape or stays Claude-only. R-1 (b) + (c)
determine whether `feedback_pack_coder_preflight_pattern` (L8) needs a
Codex equivalent or stays Claude-only with a Trinity exemption.

### R-2 — Gemini CLI memory and sub-agent capabilities

**Question:** Same as R-1 (a)-(c) for Gemini CLI.

**Verdict:** (R) — Research needed.

**Research target for pack-docs-researcher:**
- Gemini CLI official documentation.
- `.gemini/agents/` and `.gemini/skills/` conventions in the current pack
  (Gemini uses `@agent-name` invocation per PACK-AGENTS.md line 74 —
  understand what that mechanism supports for sub-agent spawning).
- The `GEMINI.md` file load convention.

**Why it matters:** Same as R-1.

### R-3 — Sub-agent / SendMessage / stop-signal cross-CLI parity (folded with R-1 + R-2)

**Question:** If R-1 and R-2 confirm sub-agent spawning is supported in
Codex / Gemini, are there equivalents to Claude Code's SendMessage tool
(parent-to-spawned-agent message) and to the system security-warning
mechanism that detected L8's defiance? If equivalents exist, do they
honor stop directives the same way?

**Verdict:** (R) — Research needed; folded into R-1 + R-2 scope.

**Research target:** Same as R-1 + R-2; specifically: the inter-agent
messaging API and any agent-defiance / security-warning mechanism in
each CLI.

**Why it matters:** Determines whether the STOP-MEANS-STOP preamble +
PREFLIGHT confirmation pattern (L8) is structurally Claude-Code-specific
(Trinity exemption) or has Codex/Gemini equivalents that need parallel
prompt patterns.

### N-1 through N-37 — All other items

Every other triage item (PC-1..PC-13, V11-1..V11-19, L1..L9 excluding L8,
SC-2, SC-3) is resolvable without external research. The categorization
in §2 stands; the trinity-first design in §3 is viable for these items
under either outcome of R-1/R-2/R-3.

### Overall research verdict

**RESEARCH NEEDED — architect will re-run after researcher.** The Tier 2
shape for non-Claude CLIs (§3.3) and the cross-CLI propagation of L8
(STOP-MEANS-STOP + PREFLIGHT) cannot be designed responsibly without the
R-1 / R-2 / R-3 answers. The trinity-first Tier 1 design is sound under
any outcome, but the second-architect-pass needs the research-grounded
data to finalize the Tier 2 + Trinity-exemption decisions.

---

## 7. Pre-planner deliverables checklist

These artifacts must be in place BEFORE pack-planner can sequence the
cleanup work. Numbering is for the planner's reference.

**D-1 (from this doc, available now):** Triage table per item with KEEP /
STRENGTHEN / CONSOLIDATE / REDIRECT / PROMOTE / DISCARD / NEW-HOME / NEW-BD
category and target home. See §2.

**D-2 (from this doc, available now):** Trinity promotion sweep mapping
(which memory entries → which trinity sub-section). See §3.5.

**D-3 (from this doc, available now):** Trinity sub-section restructure
plan (NEW `### Pack Chat scope` sub-section; extend `### Workflow`,
`### Agent invocation rules`, `### Repo conventions` per §3.5).

**D-4 (PENDING research):** Cross-CLI propagation decisions for:
- Memory tier 2 shape (Codex-native cache yes/no; Gemini-native cache yes/no).
- L8 STOP-MEANS-STOP + PREFLIGHT trinity propagation (full mirror vs
  Trinity exemption Claude-only).
- L8 PACK-AGENTS.md authority-section addition (independent of cross-CLI
  memory question — applies regardless).

**D-5 (PENDING this doc's user review):** Disposition of EXECUTION-PLAN
§B "No new BDs for audit findings" reconciliation. The current §B language
is obsoleted by `feedback_deferral_is_scope_creep`. Cleanup batch must
reconcile — either edit §B to match the new memory rule, or add an
addendum at §B saying "Superseded by `feedback_deferral_is_scope_creep`
2026-05-16; new scope from audits opens BDs inserted immediately after
the audit." Pack Chat decision required.

**D-6 (PENDING this doc's user review):** Disposition of L8.1 STATUS.md
disclaimer divergence. Per the task constraints, this architect pass does
not propose architect-doc edits to the per-entry-split corpus. Pack Chat
picks which wording is canonical and updates the other architect text in
a separate PM-owned action.

**D-7 (PENDING this doc's user review):** Decision on opening BD-173 for
V11-8 (single-BD vs multi-BD batch-close convention). Recommended OPEN
per the triage; user confirms.

**D-8 (PENDING):** Decision on whether project-template trinity (client-
side) also gets the L9 architect-doc-vs-reality reconciliation pattern.
The triage flags it as plausibly client-applicable; user decides.

**D-9 (PENDING):** Decision on PACK-CHAT.md `## Behavioral rules` ordering
/ grouping. The cleanup batch adds 6+ new bullets to this section (PC-2,
PC-6, PC-10, L4, V11-1, V11-2, V11-5 if not deferred). Planner picks
ordering; architect recommends clustering by theme (chat-scope rules
together; commit-discipline rules together; agent-spawning rules together).

The planner can produce a PLAN-CLEANUP-BATCH-19B.md as soon as D-1, D-2,
D-3 are accepted and D-4..D-9 are resolved. D-4 is the only one blocked on
research; the others are user-decision items.

---

## 8. Open questions for Pack Chat / user

These are items the architect cannot resolve without user input. Pack Chat
should address before pack-planner spawns.

**OQ-1 — EXECUTION-PLAN §B reconciliation** (also D-5 in §7). The current
EXECUTION-PLAN §B "Audit / review-fix protocol" still says "No new BDs are
opened for audit findings" (lines 333-355 of EXECUTION-PLAN-V11.0.md).
This language is obsoleted by `feedback_deferral_is_scope_creep`. Cleanup
batch must reconcile. **User decides:** (a) edit §B to match the new
memory rule (replace "no new BDs" with "new scope from audits opens BDs
inserted immediately after the audit"); or (b) add an addendum sentence
to §B preserving the historical context.

**OQ-2 — Does PACK-CHAT.md ship to client repos?** §4.5 + §5.4 turn on
this question. The pack-repo PACK-CHAT.md is at `<repo-root>/PACK-CHAT.md`.
There is also `project-template/docs/pack/PM-CHAT.md` (client-side
equivalent). Verify: are these byte-distinct files with separate content,
or is one a transformed copy of the other? If byte-distinct, the cleanup
batch edits only the pack-side file and the client-side is unaffected. If
transformed-copy, the cleanup batch must edit both. **User confirms.**

**OQ-3 — Does project-template trinity also get L4 / PC-2 / PC-6 / PC-10?**
These NEW-HOME items live in pack-repo PACK-CHAT.md per §2 triage. Several
of them might apply to project-template / PM-Chat sessions too (e.g.,
"architect-first for rules" applies to project PM-Chat too; "no
architect-spawn without approval" applies similarly). **User decides** per
item whether the project-template trinity gets the parallel rule.

**OQ-4 — Is PACK-AGENTS.md the right home for the L8 PREFLIGHT authority
addition?** L8 triage recommends "add a PACK-AGENTS.md `## Agent permission
rules` cross-reference so the agent-side authority is visible from the
agent contract." Alternative: keep it as a memory-rule + trinity bullet
only and don't extend PACK-AGENTS.md. **User decides.**

**OQ-5 — How does the user want fresh-architect-vs-same-architect handled
for the SECOND architect pass?** Per `feedback_researcher_architect_planner_
pipeline`, this is a per-case discussion at the second-pass decision
point. This first architect pass does not pre-commit. Surface for the
user to address WHEN the researcher pass completes and the second
architect pass spawns. **User decides at that point.**

**OQ-6 — Does the cleanup batch produce a CLEANUP-INPUTS-* archive when
done?** The `CLEANUP-INPUTS-SESSION-RULES.md` file is the input bundle.
Per its own header ("After the architect produces its strategy doc and
pack-coder applies the cleanup, this file should be archived (its content
folded into the resulting memory/ops-doc edits)."), the file gets folded
into the cleanup outputs and archived. Confirm this happens at the end of
the batch and archive target is `maintenance-docs/archive/v11/` per
Pattern B. **User confirms.**

**OQ-7 — How are existing client repos that have been spinning up under
v11.0 (any?) handled?** If any client repo has installed pack v11.0
already (BD-102 dog-food in Batch 23, or any external user), the §4
update propagation mechanism will refresh their trinity content at next
`init-project.sh --update`. **No action needed**, but user should be aware
the cleanup ships in v11.1 (per the pack version-bump convention) or as
v11.0 still-unlaunched-so-trinity-edit-and-republish (depending on the
ship target — see OQ-8).

**OQ-8 — Cleanup batch ship target: v11.0 (pre-launch) or v11.1?** Per
`feedback_no_deferral_without_user_direction`, the default is v11.0
because v11.0 is unlaunched. The cleanup batch IS a v11.0-scoped item
(it codifies rules surfaced during v11.0 development). Confirm ship
target — recommended v11.0 per the standing rule. **User confirms.**

---

## 9. Recommendation — research needed (Y/N)

**RECOMMENDATION: RESEARCH NEEDED.**

The trinity-first design (§3 Tier 1) is sound under any outcome of R-1 /
R-2 / R-3. The Tier 2 (tool-native memory caches) shape and the L8 cross-
CLI propagation cannot be finalized without authoritative Codex / Gemini
capability data.

**Recommended next step:** spawn `pack-docs-researcher` with a prompt that
scopes the three research questions (R-1 + R-2 + R-3 in §6). The
researcher's output should answer:

1. Does Codex CLI have persistent file-based memory equivalent to Claude
   Code's `~/.claude/projects/.../memory/*.md`? If yes, where does it
   live and what is its file format? Does it auto-load at session start?
2. Does Codex CLI support sub-agent spawning + inter-agent messaging? If
   yes, what are the tool names and call shape? Is there a stop-signal
   mechanism?
3. Same two questions for Gemini CLI.

After the researcher pass lands, pack-architect runs AGAIN (per
`feedback_researcher_architect_planner_pipeline`) and produces an updated
strategy doc that:
- Finalizes the Tier 2 design for Codex and Gemini memory caches (or
  confirms trinity-only for those CLIs).
- Decides the cross-CLI propagation shape for L8 (full mirror with
  parallel-tool-equivalent text vs Trinity exemption Claude-only).
- Updates the §7 D-4 row from PENDING to RESOLVED.

The same-architect-vs-fresh-architect decision for the second pass is a
per-case user-discussion item per the established memory rule. This first
pass does not pre-commit either way.

Only after the second architect pass completes can pack-planner spawn to
sequence the actual cleanup work into pack-coder commits.

---

## 10. Appendix — items intentionally OUT OF SCOPE

Per the task constraints, this strategy doc does NOT propose:

- New substantive features (no new validate-pack checks, no new test
  runners, no new agent definitions).
- Architect-doc edits to the per-entry-split corpus (those are PM-owned;
  L8.1 surfaces as a Pack-Chat action item — see OQ in §8).
- BACKLOG.md format changes, CHANGELOG.md format changes, per-entry tree
  contract changes (stable per Batch 19 work).
- Tracker-mode design changes (BD-079 / Phase B scope).
- New BDs beyond the one recommended in §2 V11-8 row (BD-173 — single-BD
  vs multi-BD batch-close convention). All other items resolve as in-batch
  cleanup work without new BD-NNN entries, per
  `feedback_deferral_is_scope_creep` insertion-immediately-after rule.

---

End of first-pass strategy doc. Awaits Pack Chat / user review of §8
open questions; then spawn `pack-docs-researcher` per §9 to unblock the
second architect pass.
