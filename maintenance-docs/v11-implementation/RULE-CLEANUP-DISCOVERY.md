# RULE-CLEANUP-DISCOVERY.md

**Date:** 2026-05-11
**Author:** pack-architect (read-only discovery; Step 1 of multi-step rule cleanup)
**Driving rule (per user, 2026-05-11):**

> Never write or suggest writing BDs for fixes. Audit/review findings
> are fixed in the current session. Pack Chat reports findings, gives
> the user fix options, asks permission to fix, ships the fixes. BDs
> are reserved for new scope / new feature work / new architecture, not
> for closing audit findings. Only the user can initiate
> BD-for-fix conversations.

**Discovery scope:** memory files; pack-root governance files; everything
in `maintenance-docs/v11-implementation/` minus the frozen
`AUDIT-*.md` / `IMPLEMENTATION-REPORT-*.md` / `PACK-REVIEW-*.md` set;
`supporting-docs/`; `project-template/docs/pack/`;
`project-template/skills/`; per-CLI pack agent + skill trees.

This report is a **discovery** — Pack Chat will drive the actual edits
in subsequent steps with explicit user approval per hit.

---

## 1. Headline tally

| Category | Count |
|---|---|
| **REMOVE** (instruction prescribing BD-for-fix that should be deleted or replaced with the new affirmative rule) | 12 |
| **REWRITE** (passage that mentions BD-for-fix as one of several options or implies it as a valid pattern; reframe to remove the BD-for-fix path while keeping surrounding correct content) | 6 |
| **KEEP-HISTORICAL** (prose describing past behavior or events; rewriting would be revisionism) | 35+ (all `fix-follow` mentions inside Resolved BACKLOG entries; all `fix-follow` mentions inside frozen IMPLEMENTATION-REPORT-* and PACK-REVIEW-* files; the Description text of BDs already Resolved). Not enumerated individually below — they are categorically frozen per user direction. |
| **EDGE CASE** (surface to Pack Chat with reasoning; user decides per hit) | 7 |

**Total in-scope edit targets (REMOVE + REWRITE + EDGE CASE): 25.**

The dominant pattern is `EXECUTION-PLAN-V11.0.md` and `BACKLOG.md` —
both encode the broken §5.B rule explicitly. The trinity files
(`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) and the Claude memory files
encode a softer adjacent rule ("one review/fix cycle per batch") that
is *consistent* with the new rule and may only need an explicit
clarifier addition rather than removal.

---

## 2. Per-file findings

### 2.1 Memory files (Claude auto-memory)

**Path:** `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/`

(Note: a v11-dev-specific memory dir does not exist; the v11-dev chat
reads from the non-v11 path above. Per system prompt the index is
`MEMORY.md` plus per-feedback files.)

#### `MEMORY.md` (index)

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 12 | `[One review/fix cycle per BD batch](feedback_review_fix_one_cycle.md) — run reviewer once per batch, fix once, move on; never propose a second pass; final audit is user-initiated` | **EDGE CASE** | The summary line itself does not say "open a BD for fix"; it says "fix once, move on." Substance aligns with the new rule. The linked file (below) is where the BD-for-fix language is implied. Decide whether the index entry needs a wording tweak (e.g. "fix once *in-session*") once the linked file is rewritten. |
| 13 | `[Implicit BD status flip on batch completion](feedback_implicit_status_flip.md) — when a batch's fix-follow + tests are green, flip its BDs to Resolved as the final step; no separate approval needed` | **REWRITE** | The phrase `a batch's fix-follow` presumes the existence of a separate fix-follow commit/BD. Under the new rule, fixes land *inside* the original session/commit (or a follow-up commit by Pack Chat — but not a new BD). Reword to drop "fix-follow" terminology, e.g. "when a batch's review fixes are green and tests pass, flip its BDs to Resolved." |

#### `feedback_review_fix_one_cycle.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 2 | `name: One review/fix cycle per BD batch` | **EDGE CASE** | Title is rule-name; substance OK if the body is rewritten. May survive intact. |
| 3 | `description: Pack workflow — run reviewer agent once per batch of related BDs, fix once, then move on; never propose a second cumulative review on the same batch` | **EDGE CASE** | "fix once" is correct under new rule; needs no edit unless Pack Chat wants to add "in-session" for clarity. |
| 11 | `One fix-follow commit closes all actionable findings (all severities — BLOCKER / WARNING / NIT — are addressed unless the reviewer explicitly says no action needed).` | **REWRITE** | "Fix-follow commit" is fine as-is (a commit that holds the fixes), but the broader file uses "fix-follow" in a way that implies the BD-for-fix pattern elsewhere in the pack. Suggest: "One fix commit, in the current session, closes all actionable findings…". Do NOT introduce "fix-follow BD" language as a substitute. |
| 19 | `After landing a fix-follow for a batch, the next action is the next BD batch — not another reviewer pass.` | **REWRITE** | Same — replace "fix-follow" with "in-session fix commit" or simply "the fixes." |
| 21 | `Exception (grandfathered): if a reviewer pass *was* run … all actionable findings from it MUST still be fixed in fast-follow per the NO TECH DEBT rule.` | **EDGE CASE** | "Fast-follow" here means "promptly" — different word from "fix-follow BD." Decide whether to leave or rephrase to "fixed in-session." |

#### `feedback_implicit_status_flip.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 3 | `description: When a Pack batch's fix-follow is committed and tests green, the BD entries in that batch flip to Resolved as the final step of completing the batch — no separate approval required` | **REMOVE / REWRITE** | "Pack batch's fix-follow" presupposes the BD-for-fix model. Drop "fix-follow" and rephrase: "When a Pack batch's review fixes are committed and tests green…" |
| 7-11 | `When a Pack batch is complete (implementation commits + reviewer pass + fix-follow committed + tests green + validate-pack rc=0), the BD entries implementing that batch flip to Status: Resolved as the implicit final step…` | **REMOVE / REWRITE** | Same — drop the `+ fix-follow committed` clause; the batch-completion criteria become "implementation commits + reviewer pass + review-fix commits (in-session) + tests green + validate-pack rc=0". |
| 21-22 | `Or fold into the fix-follow commit if it's small.` | **REWRITE** | Replace "fix-follow commit" with "review-fix commit" (or whatever the new term is once Pack Chat agrees). |
| 27 | `Do this *only* after the batch is fully complete (fix-follow committed, CI green).` | **REWRITE** | Same — strip "fix-follow committed." |
| 34 | `feedback_review_fix_one_cycle.md — one review/fix cycle per batch` | **KEEP** (cross-ref; updates only after the linked file is rewritten) | |

> **Cross-cutting:** The two memory files above are the *source of
> truth* for Pack Chat's review-loop behavior. They should be edited
> together so the index entry, both linked files, and the substantive
> rules all use the same vocabulary. A single new affirmative rule (see
> §3) likely replaces both.

---

### 2.2 Pack-root governance files

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 112-114 | `**One review/fix cycle per batch.** Run pack-reviewer once per batch, fix once, move on. Do not propose a second review pass; the final audit is user-initiated.` | **EDGE CASE** | Substance ("fix once, move on") aligns with the new rule. Does NOT mention BD-for-fix. The question is whether to make the new rule *explicit* here (i.e. add a sentence like "Fixes land in the current session — never as a new BD."). Trinity edit if changed. |
| 115-117 | `**Implicit BD status flip on batch completion.** When a batch's review + fixes are clean and tests are green, flip its BDs to Resolved as the final step of the batch — no separate user approval needed.` | **KEEP** | Phrasing is correct ("review + fixes" — no BD-for-fix language). Trinity-mirrored to AGENTS.md / GEMINI.md. |

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 106-108 | (identical bullet to CLAUDE.md 112-114) | **EDGE CASE** | Trinity copy. Same disposition as CLAUDE.md. |
| (parallel) | (Implicit BD status flip bullet) | **KEEP** | |

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 87-89 | (identical bullet to CLAUDE.md 112-114) | **EDGE CASE** | Trinity copy. Same disposition. |
| (parallel) | (Implicit BD status flip bullet) | **KEEP** | |

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md`

Zero hits. Clean.

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md`

Zero hits relevant to BD-for-fix. (`open BD items` at line 102 means
"Open-status BD items in the backlog" — KEEP.)

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 112 | `│       ├── coder.md                        variants: standard, fix-cycle` | **KEEP** | "fix-cycle" here names a project-template coder prompt variant (`coder.md` Variant: fix-cycle). Different concept from "fix-follow BD." Project-side, not pack-side. |

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CHANGELOG.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 376 | `…report pack version and open BD items.` | **KEEP** | Same idiom as PACK-AGENTS — "Open-status BD items," not BD-for-fix. |
| 410 | `PM chat kickoff, coder, reviewer, fix cycle, tester, …` | **KEEP** | Project-template prompt variant terminology. |

#### `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md`

The user's scope rule is explicit: "BACKLOG.md historical resolved
entries — they may mention 'fix-follow BD' in their Resolved: lines as
historical record; LEAVE FROZEN. Only flag forward-looking content in
BACKLOG (currently-Open BDs that contain BD-for-fix instructions, or
sections that aren't BD entries)."

I checked every Open BD identified by `awk` (Status: Open). **No Open
BD currently encodes a BD-for-fix instruction in its Description.** The
Open BDs that mention "fix-follow" semantics in their bodies are:
none. (BD-128, BD-139, BD-126, BD-127 — all the BDs with the relevant
prose — are Resolved and therefore frozen.)

Header / non-BD-entry sections of BACKLOG.md were spot-checked (lines
1–25 instructions; v11 Active block header) — no BD-for-fix prose.

**Disposition for BACKLOG.md: zero in-scope hits.** All `fix-follow`
references in this file are in Resolved BACKLOG entries → KEEP-HISTORICAL.

---

### 2.3 `maintenance-docs/v11-implementation/` (in-scope subset)

> **Excluded from this section per the user's scope:** all
> `AUDIT-BD-*.md`, `AUDIT-BATCH-*.md`, `IMPLEMENTATION-REPORT-*.md`,
> and `PACK-REVIEW-*.md` files. Many of those contain the offending
> language (e.g. AUDIT-BD-104.md, AUDIT-BATCH-13.md, the
> IMPLEMENTATION-REPORT-*-FIX-FOLLOW.md set). They are frozen.

#### `EXECUTION-PLAN-V11.0.md` — **the primary cleanup target**

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 91 | `**BD-059** — v10 customization-preservation. Almost certainly closed by BD-088. Pack Chat verifies BD-088 closed it; flips status; adds Resolved note pointing to BD-088 commits. **If verification surfaces residual gaps, opens fix-follow BD.**` | **REMOVE** | Direct violation: instructs Pack Chat to "open a fix-follow BD" if verification surfaces gaps. Replace with the affirmative rule (see §3 D-1). |
| 205 | (Inside a quoted Open-BD-128 fragment, *but BD-128 is already Resolved as of 2026-05-09*. The plan still embeds the pre-resolution Description text:) `… May spawn fix-follow BDs if any failure surfaces a deeper issue. **NOTE on sequencing:** …` | **REWRITE** | This text was a `Description` field copied from the BD-128 entry into the EXECUTION-PLAN. BD-128 is Resolved (BACKLOG line 1551) — its Description is frozen. But the EXECUTION-PLAN copy is *not* a Resolved BACKLOG entry; it is forward-looking plan prose. Replace "May spawn fix-follow BDs if any failure surfaces a deeper issue" with the new rule (e.g. "If any failure surfaces a deeper issue, Pack Chat reports it and asks the user how to proceed; new BDs are opened only if the user directs."). |
| 246 | `\| **14** \| parallel pack-architect (audit-only) \| BD-032 ∥ BD-033 ∥ BD-034 ∥ BD-035 \| audit reports under maintenance-docs/v11-implementation/AUDIT-BD-032..035.md (no code) \| Audit batch; **standing rule §5.B applies — fix-follow BD opened for every finding incl. NITs** \|` | **REMOVE** | Direct violation. Strip the "standing rule §5.B applies — fix-follow BD opened…" phrasing. Replace per §3 D-2. |
| 247 | `\| **14b** \| (conditional) sequential pack-coder \| **fix-follow BDs from Batch 14 findings** \| TBD by audit output \| Spawned only if audits surface defects; **one commit per fix-follow BD** \|` | **REMOVE** | Whole row premised on "fix-follow BDs from Batch 14 findings." Under the new rule, defects from a Batch 14 audit are fixed in-session (in Batch 14 itself or in a Pack Chat-approved follow-up commit), not as new BDs. Decide whether Batch 14b survives at all (it might collapse into Batch 14, or remain as "fix commit if needed — no BD"). |
| 255 | `\| **21** \| sequential pack-architect + pack-reviewer (audit-only) \| BD-100 final milestone audit … \| … \| Audit batch; **standing rule §5.B applies — fix-follow BDs opened for every finding incl. NITs**; final blocker check before BD-102 \|` | **REMOVE** | Same as line 246. Strip §5.B reference; replace with the affirmative new rule. |
| 256 | `\| **21b** \| (conditional) sequential pack-coder \| **fix-follow BDs from Batch 21 findings** \| TBD by audit output \| Spawned only if audit surfaces defects \|` | **REMOVE** | Same as line 247. |
| 257 | `\| **22** \| sequential pack-coder + manual \| BD-102 dog-food migration … \| … \| Produces dog-food report …; **defects → fix-follow BDs incl. NITs (§5.B)** \|` | **REMOVE** | Same — strip "defects → fix-follow BDs incl. NITs (§5.B)". Replace with the new rule. |
| 258 | `\| **22b** \| (conditional) sequential pack-coder \| **fix-follow BDs from Batch 22 defects** \| TBD by dog-food findings \| Spawned only if dog-food surfaces defects \|` | **REMOVE** | Same as 247 / 256. |
| 261 | `**Total: 25 main batches (23 + Batch 5b for BD-135 + Batch 20b for BD-136 implementation) + up to 3 conditional fix-follow batches = max 28 commits, plus Batch 20b internally ships 4 commits, putting practical max at ~31 commits.** Could be more if any audit / dog-food fix-follow needs more than one commit.` | **REWRITE** | Total math depends on whether Batches 14b/21b/22b survive at all. If they do, rename them to "(conditional fix commit)" and update the "fix-follow batches" / "fix-follow needs more than one commit" wording. |
| 277-283 | The entire **§5.B Audit / fix-follow protocol (user rule, 2026-05-09)** subsection: 5 numbered points instructing fix-follow BDs for every audit pass, including NITs, with new BDs spawned for out-of-scope defects. | **REMOVE (entire subsection)** | This is the canonical encoding of the broken rule. The whole subsection should be replaced by the new affirmative rule (see §3 D-3). |
| 282 | `4. After fix-follow lands and validator/CI is clean, status flips per the implicit-flip rule (§C.4).` | **REMOVE** (part of subsection above) | |
| 283 | `5. If fix-follow surfaces defects beyond the original audit scope, those become NEW BDs — not folded into the fix-follow batch.` | **REMOVE** (part of subsection above) | This sub-rule is *the inverted version of the new rule*. Today: "in-scope = fix-follow BD; out-of-scope = NEW BD." Under the new rule: "in-scope = in-session fix; out-of-scope = report to user, BD only at user direction." |
| 290 | `4. **Implicit BD status flip on batch completion.** When a batch's review + fixes are clean and tests are green, flip its BDs to Resolved as the final step of the batch — no separate user approval needed (memory rule). Note this is distinct from §A.1: the BACKLOG status flip happens inside the same commit as the BD's implementation, not as a separate commit.` | **KEEP** | Phrasing is correct ("review + fixes" — no BD-for-fix language). Mirrors trinity bullet. |
| 308 | `1. **validate-pack.py PASSES after every batch.** Pack Chat verifies before committing. Regression on any check (1–28) is a defect — **fix-forward in the same batch or split a fix-follow.**` | **REWRITE** | "Split a fix-follow" implies splitting off a separate fix-follow BD/batch. Replace with: "fix-forward in the same batch, or in a follow-up commit Pack Chat approves with the user." |
| 361 | `\| Final milestone audit \| Batch 21 \| audit report finds zero BLOCKER + acceptable SHOULD-FIX/NIT scope \| **Fix-follow batch (Batch 21b) per §5.B** \|` | **REMOVE** | Replace "Fix-follow batch (Batch 21b) per §5.B" with "Pack Chat presents findings, options, and asks the user how to proceed (new rule)." |
| 362 | `\| Dog-food migration \| Batch 22 \| clean migrator output against v10-tag pack clone; customization preserved \| **Fix-follow batch (Batch 22b) per §5.B** \|` | **REMOVE** | Same as line 361. |

> **Cross-cutting observation #1.** Lines 246/247, 255/256, 257/258 all
> follow the same "audit batch row + 'b' fix-follow conditional row"
> pattern. The same structural change applies to all three pairs: kill
> the §5.B reference in the audit row, and either fold the 'b' row
> back into the parent or rewrite it as "(conditional in-session fix
> commit) — no new BD." Decide once, apply three times.

> **Cross-cutting observation #2.** §5.B (lines 277-283) is the
> *single* place the broken rule is written down as a numbered
> protocol. Everywhere else in EXECUTION-PLAN-V11.0 references back to
> §5.B by section number. Removing §5.B and replacing it with the new
> affirmative rule (kept in the same numbered slot, e.g. §B retitled
> "Audit / review-fix protocol") will let all the other line-247-style
> "per §5.B" references update by reference rather than per-instance
> rewriting (though the *labels* "§5.B" should still be replaced with
> the new section name for prose clarity).

#### `PLAN-BD-119.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 913 | `- [ ] One pack-reviewer pass after C-7 (per the one-review/fix-cycle-per-batch rule). Review prompt cites ARCHITECTURE-BD-119.md and this PLAN, never any prior review.` | **KEEP** | The rule name "one-review/fix-cycle-per-batch" is the same rule kept in CLAUDE/AGENTS/GEMINI. The wording is congruent with the new rule. |
| 914 | `- [ ] If reviewer finds issues: one fix-follow batch, then move on.` | **REWRITE** | "Fix-follow batch" here means a batch of fix commits — implies the BD-for-fix pattern. Replace with: "If reviewer finds issues: fix in-session, then move on." |
| 110 / 455 / 603 / 671 / 762 / 843 | `…a new BD…` (multiple sites) | **KEEP** | All these "new BD" references describe the architecture-amendment pattern: amending the BD-119 framework's public surface requires a new BD that *amends* BD-119 (i.e. new architecture work, not fix-follow). Aligned with new rule ("BDs are reserved for new scope / new feature / new architecture"). |

#### `ARCHITECTURE-BD-119.md`

Zero hits matching the search patterns.

#### `SEMANTIC-AUDIT-REPORT.md`

This file is **not** in the explicit exclusion set ("AUDIT-*.md") but
is *in spirit* a frozen audit report (dated 2026-05-07; pre-release
audit gate for BD-093). Surface it to Pack Chat as **EDGE CASE**:

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 211 | `…ships 6.** Drift introduced before fix-follow.` | **EDGE CASE** | Historical narrative ("the drift happened before the fix-follow ran"). If Pack Chat treats this file as frozen-historical, KEEP. |
| 223 | `…pre-fix-follow remnant the Resolved-line text never updated.` | **EDGE CASE** | Same — historical narrative. |
| 391 | `…clearing the four cheap ones in the same fix-follow as B-1:` | **EDGE CASE** | This is *forward-looking* recommendation prose — "the auditor recommends clearing X in the same fix-follow as B-1." Under the new rule, the recommendation should be "in the same in-session fix as B-1." If the file is frozen, leave; if Pack Chat decides this audit report is editable, REWRITE. |
| 402 | `… whether to bundle into the BD-093 release-pin commit or ship as **W-prefixed follow-up BDs** is a maintainer judgment call.` | **EDGE CASE** | Same — forward-looking recommendation. Under the new rule the "W-prefixed follow-up BDs" wording should be dropped. |
| 414-435 | `## 6. Followup BD list (proposed; for Pack Chat to assign numbers)` — entire section listing 10 proposed follow-up BD entries from the audit. | **EDGE CASE** | This entire section literally proposes opening a BD for every audit finding. Under the new rule, it would not be authored this way today. If Pack Chat treats this audit as a frozen historical artifact, KEEP. If editable, the section needs rewriting from "10 follow-up BDs" to "10 in-session fixes for the user to approve." |
| 434 | `…the BLOCKER plus the four cheap warnings is one focused fix-follow + Pack Chat approval to move BD-093 forward.` | **EDGE CASE** | Same disposition. |

> **Recommendation to Pack Chat:** treat SEMANTIC-AUDIT-REPORT.md as
> frozen historical (consistent with the AUDIT-*.md exclusion intent).
> But surface explicitly because it does not match the literal glob.

#### Other files in `maintenance-docs/v11-implementation/`

- `RESEARCH-NON-APPLE-UI-SKILLS.md` — concurrent agent owns this file.
  Hits at lines 21-22 are descriptive ("(after BD-034 fix-follow)") —
  factual references to a past fix-follow. KEEP-HISTORICAL. **Flag:
  may be affected by concurrent BD-104b agent (`pack-docs-researcher`)
  — Pack Chat to verify final state.**
- `ARCHITECTURE-BD-119.md` — zero hits. KEEP.
- All `AUDIT-*.md`, `IMPLEMENTATION-REPORT-*.md`,
  `PACK-REVIEW-*.md` — excluded per user direction. Many contain the
  offending language; all are frozen.

---

### 2.4 `supporting-docs/`

#### `DRY-RUN-MIGRATION.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 190 | `…that is a migrator defect — file a BD with both reports attached.` | **EDGE CASE** | This is a *user-facing bug-report instruction* directed at downstream pack adopters: when an end user sees a migrator defect, they should file a BD against the pack as bug intake. Different from the pack-internal "open a fix-follow BD for our own audit findings" pattern. Under the new rule, end users *can* still file BDs against the pack; only Pack Chat is forbidden from auto-opening BDs for its own findings. **Recommend: KEEP.** Surface to Pack Chat for confirmation. |

#### `MIGRATION-v10-to-v11.md`

| Line | Snippet | Category | Rationale |
|---|---|---|---|
| 336 | `If the migrator reports customization-detected-needs-reconciliation on a file you didn't customize, that's a defect — please file a BD against the customize-preserve library with the .pack-migrate-v10-to-v11/dispositions.tsv row attached.` | **EDGE CASE** | Same as DRY-RUN-MIGRATION.md line 190 — user-facing bug-report instruction. **Recommend: KEEP.** |

All other `supporting-docs/` files: zero hits.

#### Other `supporting-docs/` files (audited, zero hits)

- `AGENT_KICKOFF_TEMPLATE.md`
- `CLI-PM-SETUP.md`
- `DEPENDENCIES.md`
- `INSTALL-PROCEDURES.md` (only references `coder.md ## Variant: fix-cycle` — project-side prompt variant, unrelated)
- `MERGE-STRATEGY.md`
- `METHODOLOGY.md` (multiple `fix-cycle` references — all about the project-side coder Variant: fix-cycle prompt, unrelated to BD-for-fix)
- `MIGRATION-v8-to-v9.md`
- `SETUP_TEMPLATE.md`
- `SETUP-EXISTING.md` (only references `coder.md ## Variant: fix-cycle`)
- `SETUP-NEW.md`

---

### 2.5 `project-template/docs/pack/`

All files audited; **zero hits** matching the broken rule. Files
audited (in scope):

- `HELP-FRAGMENT.md`
- `HELP-FRAGMENT-TRACKER.md`
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`
- `PACK-FEEDBACK.md` (multiple `fix-cycle` references — project-side prompt variant)
- `prompts/coder.md`, `prompts/reviewer.md`, `prompts/architect.md`,
  `prompts/auditor.md`, `prompts/tester.md`, `prompts/planner.md`,
  `prompts/docs-researcher.md`, `prompts/grpc-schema.md`,
  `prompts/repo-ops.md`, `prompts/pm-chat.md` (all `fix-cycle`
  references are project-side prompt variants)

> **Confirmation:** the broken rule was *never* exported to the
> client-side product surface. It lives only in pack-ops files
> (memory, EXECUTION-PLAN, BACKLOG entries, audit reports). This is
> consistent with the "separate pack ops from pack product" rule and
> is a positive finding for the cleanup scope.

---

### 2.6 `project-template/skills/`

All `SKILL.md` files audited (canonical skills):

- `pm-startup/SKILL.md` — zero hits
- `implementation/SKILL.md` — zero hits
- `commit-discipline` — not present in `project-template/skills/`
  (lives only in per-CLI trees `.claude/skills/`,`.codex/skills/`,
  `.gemini/skills/` — see §2.7)
- `implementation-report` — not present in `project-template/skills/`
  (same as commit-discipline)
- All other skills — not searched individually; spot-checked top-level
  with broad grep, zero hits.

---

### 2.7 Per-CLI pack agent + skill trees

**Paths searched:**
- `/.claude/skills/`, `/.codex/skills/`, `/.gemini/skills/`
- `/.claude/agents/`, `/.codex/agents/`, `/.gemini/agents/`

| File set | Hits | Disposition |
|---|---|---|
| `.{claude,codex,gemini}/skills/{pack-startup,documentation,commit-discipline,dependency-intake,planning,pack-help,verification-harness,review,implementation-report,architecture-review}/SKILL.md` | Only `verification-harness/SKILL.md:211` matches "new BD that needs to verify multi-step behavior" — describes new-feature-BD case, NOT BD-for-fix. **KEEP.** | KEEP |
| `.{claude,codex,gemini}/agents/pack-architect.{md,toml}` line 27/18/29 | "BACKLOG.md (open BD items and their constraints)" — same idiom as PACK-AGENTS.md. **KEEP.** | KEEP |
| All other pack-agent files | Zero hits. | KEEP |

> **Confirmation:** the per-CLI skill and agent files are clean of
> BD-for-fix prescriptions. Only Pack-Chat-facing operational docs
> need editing.

---

## 3. Affirmative-rule draft suggestions (DRAFT — Pack Chat + user finalize)

Several REMOVE/REWRITE hits leave a hole in the prose where an
affirmative replacement is needed. Below are draft replacements,
labeled DRAFT and grouped by site type. Pack Chat + user finalize.

### D-1 — Replacement for `EXECUTION-PLAN-V11.0.md:91` (BD-059 verify-then-close)

> **Original:**
> > If verification surfaces residual gaps, opens fix-follow BD.
>
> **DRAFT replacement:**
> > If verification surfaces residual gaps, Pack Chat reports the gaps to
> > the user, presents fix options, and (with user approval) ships the
> > fixes in the current Batch 5 commit. New BDs are not opened for
> > findings — only at user direction.

### D-2 — Replacement for `EXECUTION-PLAN-V11.0.md:246/255/257` (audit-batch table-row "Notes")

> **Original (boilerplate across three rows):**
> > Audit batch; **standing rule §5.B applies — fix-follow BD opened for every finding incl. NITs**
>
> **DRAFT replacement:**
> > Audit batch. Per the in-session fix rule (§B revised), Pack Chat
> > reports all findings to the user, presents fix options per finding
> > (including NITs), asks permission, and ships the fixes in the same
> > batch (or in a Pack-Chat-approved follow-up commit). No new BDs are
> > opened for audit findings.

### D-3 — Replacement for `EXECUTION-PLAN-V11.0.md:277-283` (entire §5.B subsection)

> **Original section title and 5 points:**
> > ### B. Audit / fix-follow protocol (user rule, 2026-05-09)
> > 1. Every audit pass that produces findings spawns a fix-follow batch.
> > 2. **Even NITs get fixed.** Fix-follow scope includes every BLOCKER, SHOULD-FIX, and NIT surfaced.
> > 3. Fix-follow runs as pack-coder (or direct edits if scope ≤ a few lines per file).
> > 4. After fix-follow lands and validator/CI is clean, status flips per the implicit-flip rule (§C.4).
> > 5. If fix-follow surfaces defects beyond the original audit scope, those become NEW BDs — not folded into the fix-follow batch.
>
> **DRAFT replacement:**
>
> > ### B. Audit / review-fix protocol (user rule, 2026-05-11)
> >
> > 1. Every audit/review pass that produces findings is fixed *in
> >    the current session*. No fix-follow BDs are opened.
> > 2. Pack Chat reports the findings to the user (severity-grouped),
> >    presents fix options per finding (including NITs), and asks
> >    permission to fix.
> > 3. With user approval, Pack Chat ships the fixes in the same
> >    batch's commit, or in a small follow-up commit Pack Chat
> >    proposes and the user approves.
> > 4. After review fixes land and validator/CI is clean, status flips
> >    per the implicit-flip rule (§C.4).
> > 5. If review surfaces defects beyond the audit scope, Pack Chat
> >    surfaces them to the user. New BDs for out-of-scope defects are
> >    opened only when the user explicitly directs.
> >
> > **BDs are reserved for new scope, new features, and new
> > architecture — never for closing audit findings. Only the user can
> > initiate a BD-for-fix conversation.**

### D-4 — Replacement for `feedback_implicit_status_flip.md` (memory)

> **Original (description + body excerpt):**
> > description: When a Pack batch's fix-follow is committed and tests green, the BD entries in that batch flip to Resolved as the final step of completing the batch — no separate approval required
>
> **DRAFT replacement:**
> > description: When a Pack batch's review fixes are committed and tests green, the BD entries in that batch flip to Resolved as the final step of completing the batch — no separate approval required.
>
> Throughout the body, replace `fix-follow committed` → `review fixes committed`, `the fix-follow commit` → `the review-fix commit`, `landing a fix-follow` → `landing the review fixes`.

### D-5 — Replacement for `feedback_review_fix_one_cycle.md` (memory)

> **Add a new bullet at the end of the "How to apply" section:**
>
> > - **Fixes land in the current session.** Findings — at every
> >   severity, including NITs — are fixed inside the session that ran
> >   the review (or in a Pack-Chat-approved follow-up commit). Never
> >   open a new BD for an audit/review finding. BDs are reserved for
> >   new scope / new feature / new architecture work, and only the
> >   user can initiate a BD-for-fix conversation.

### D-6 — Replacement for `EXECUTION-PLAN-V11.0.md:308` (validator regression note)

> **Original:**
> > Regression on any check (1–28) is a defect — fix-forward in the same batch or split a fix-follow.
>
> **DRAFT replacement:**
> > Regression on any check (1–28) is a defect — fix-forward in the same batch, or in a small Pack-Chat-approved follow-up commit. No fix-follow BD is opened.

### D-7 — Replacement for `PLAN-BD-119.md:914`

> **Original:**
> > - [ ] If reviewer finds issues: one fix-follow batch, then move on.
>
> **DRAFT replacement:**
> > - [ ] If reviewer finds issues: fix in-session (in BD-119's commits or a Pack-Chat-approved follow-up commit), then move on.

### D-8 — Optional addendum to trinity bullet (CLAUDE.md / AGENTS.md / GEMINI.md, line ~112-114)

> **Optional clarifier sentence to append to the existing
> "One review/fix cycle per batch" bullet:**
>
> > Fixes land in the current session — never as a new BD. BDs are
> > reserved for new scope / new feature / new architecture; only the
> > user can initiate a BD-for-fix.
>
> Trinity edit if applied.

---

## 4. Cross-cutting observations

1. **Two rule strata exist today and only one is broken.** The
   "one review/fix cycle per batch" rule (memory + trinity) is
   *consistent* with the new rule — it says "fix once, move on" without
   mandating BD-for-fix. The "§5.B fix-follow" rule (EXECUTION-PLAN +
   memory's `fix-follow` vocabulary) is the broken one. Cleanup can
   leave the first rule largely intact (with a small clarifying
   addition) and surgically remove the second.

2. **The broken rule is concentrated in 4 files.** Every
   forward-looking REMOVE/REWRITE hit lives in:
   - `EXECUTION-PLAN-V11.0.md` (8 hits in 5 distinct sites + 1 whole subsection)
   - `feedback_implicit_status_flip.md` (5 hits, same theme)
   - `feedback_review_fix_one_cycle.md` (3-4 hits)
   - `MEMORY.md` (1 entry-line)
   - `PLAN-BD-119.md` (1 hit)

   Plus 6 EDGE CASE hits in `SEMANTIC-AUDIT-REPORT.md` (frozen-or-not
   decision required).

3. **Same 3 EXECUTION-PLAN row patterns repeat 3x.** Lines 246/247,
   255/256, 257/258 all use the same audit-batch-row plus 14b/21b/22b
   fix-follow-conditional row pattern. Single design decision applies
   to all three pairs:
   - (a) Drop the §5.B reference from the audit row.
   - (b) Decide what to do with the conditional 'b' rows: collapse
         into the parent row, or rewrite as "(conditional in-session
         fix commit)" with explicit "no new BD" qualifier.

4. **The product surface (project-template/) is clean.** Zero hits in
   `project-template/docs/pack/` or `project-template/skills/`.
   Confirms the "separate pack ops from pack product" rule held: the
   broken rule never escaped pack-ops territory.

5. **End-user "file a BD against the pack" instructions are different
   from the broken rule.** Two hits in `supporting-docs/` (DRY-RUN /
   MIGRATION) tell downstream users to file BDs against the pack as
   *bug intake* when migrators misbehave. Recommend KEEP — these are
   end-user channels for new defect reports, not pack-internal
   audit-finding workflow.

6. **`fix-cycle` ≠ `fix-follow`.** Many `fix-cycle` references in
   `supporting-docs/`, `project-template/docs/pack/`,
   `project-template/docs/pack/prompts/coder.md`, `README.md`,
   `CHANGELOG.md`, `BACKLOG.md`, and `METHODOLOGY.md` refer to a
   project-side coder *prompt variant* called "Variant: fix-cycle."
   Different concept from the pack-internal "fix-follow BD" pattern.
   All KEEP.

7. **All BACKLOG.md `fix-follow` hits are in Resolved entries.** Per
   user direction these are frozen historical record.

8. **All `AUDIT-*.md`, `IMPLEMENTATION-REPORT-*.md`,
   `PACK-REVIEW-*.md` hits are excluded from this report per user
   direction.** Many of these files contain heavy use of the broken
   pattern; they are categorically frozen.

9. **`SEMANTIC-AUDIT-REPORT.md` is the one ambiguous file.** Not in
   the literal `AUDIT-*.md` exclusion glob, but in spirit a frozen
   audit artifact. Recommend Pack Chat make a one-time call: freeze
   it, or rewrite §6 ("Followup BD list").

10. **Concurrent agent flag.** `RESEARCH-NON-APPLE-UI-SKILLS.md` has
    KEEP-only hits (line 21-22, factual references to a past
    BD-034 fix-follow). The `pack-docs-researcher` is currently the
    sole writer to that file. No conflict on the discovery snapshot;
    Pack Chat to verify final-state content if any rewrite is decided.
    No `pack-coder` (BD-104b skill split) overlap with any REMOVE /
    REWRITE / EDGE CASE hit identified above.

---

## 5. Files audited with zero hits

Files explicitly searched, in scope per the discovery spec, that
returned zero hits matching the broken-rule patterns:

**Pack-root governance:**
- `PACK-CHAT.md`
- `PACK-AGENTS.md` (only "open BD items" idiom — KEEP)

**`maintenance-docs/v11-implementation/`:**
- `ARCHITECTURE-BD-119.md`

**`supporting-docs/`:**
- `AGENT_KICKOFF_TEMPLATE.md`
- `CLI-PM-SETUP.md`
- `DEPENDENCIES.md`
- `INSTALL-PROCEDURES.md` (only project-side `fix-cycle` prompt-variant references — KEEP)
- `MERGE-STRATEGY.md`
- `METHODOLOGY.md` (only project-side `fix-cycle` prompt-variant references — KEEP)
- `MIGRATION-v8-to-v9.md`
- `SETUP_TEMPLATE.md`
- `SETUP-EXISTING.md` (only project-side `fix-cycle` prompt-variant references — KEEP)
- `SETUP-NEW.md`

**`project-template/docs/pack/`:**
- `HELP-FRAGMENT.md`
- `HELP-FRAGMENT-TRACKER.md`
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`
- `PACK-FEEDBACK.md` (only project-side `fix-cycle` prompt-variant references — KEEP)
- All `prompts/*.md` (only project-side `fix-cycle` prompt-variant references — KEEP)

**`project-template/skills/`:**
- `pm-startup/SKILL.md`
- `implementation/SKILL.md`
- All other canonical skills (broad grep — zero hits)

**Per-CLI pack skills (`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`):**
- All `SKILL.md` files (only one factual "new BD that needs to verify…"
  reference in `verification-harness/SKILL.md:211` — KEEP, it describes
  a new-feature BD, not BD-for-fix)

**Per-CLI pack agents (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`):**
- All agent files (only "BACKLOG.md (open BD items and their
  constraints)" idiom in pack-architect — KEEP, this is "Open-status
  BD items in BACKLOG", not BD-for-fix)

---

## 6. Recommended cleanup sequence (suggestion to Pack Chat)

This is a discovery report; sequencing is Pack Chat's call. One
suggested order, if helpful:

1. **Edit §5.B in EXECUTION-PLAN-V11.0.md first.** That subsection is
   the single canonical authority. Replace it with the affirmative
   rule (D-3 draft). All `per §5.B` references downstream point
   somewhere meaningful again (or get cleaned in the next step).

2. **Sweep EXECUTION-PLAN-V11.0.md** lines 91, 205, 246/247, 255/256,
   257/258, 261, 308, 361, 362 (apply D-1, D-2, D-6 drafts; decide
   14b/21b/22b row fate).

3. **Edit memory files** (`MEMORY.md`, `feedback_implicit_status_flip.md`,
   `feedback_review_fix_one_cycle.md`) to align vocabulary.

4. **Trinity addendum** (CLAUDE.md / AGENTS.md / GEMINI.md, optional
   D-8 clarifier) — single trinity edit, three files.

5. **PLAN-BD-119.md:914** — single line edit (D-7).

6. **Decide SEMANTIC-AUDIT-REPORT.md disposition** — frozen or
   rewrite §6.

7. **Confirm supporting-docs end-user "file a BD" instructions
   stay** — explicit Pack Chat / user sign-off that these are
   bug-intake channels, not the broken rule.

After step 1 lands, every subsequent step is small and easy to
review. If the user wants the cleanup committed in one batch, all
seven steps can be staged together with stop-before-commit per the
existing §A.1 rule.

---

**End of discovery report.**
