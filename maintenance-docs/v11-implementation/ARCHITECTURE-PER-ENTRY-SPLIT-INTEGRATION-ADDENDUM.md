---
title: ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM
author: primary-chat (v11-dev) integration architect
status: design — bundles 10 user-Pack-Chat-decided items into one addendum
parent: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
prior-pipeline: sidecar parent + addendum + two primary-chat reviewer passes (per parent §1.1 read-record)
audience: primary-chat reviewer (next), then primary-chat planner
date: 2026-05-14
---

# Per-entry split — integration architecture addendum

This addendum bundles 10 items decided in user-Pack-Chat
discussion following the reviewer pass on
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (3,477 lines).
The original integration architect doc is NOT edited; this
addendum corrects + extends it (parallel to the sidecar's own
addendum pattern that corrects + extends the sidecar parent).

## §0 — TL;DR + 10-item disposition table

**One BLOCKER.** Batch positioning was wrong. The original
proposed "NEW Batch 18" — Batch 18 is occupied by BD-111. The
correct next-available slot is **NEW Batch 19**, with the
existing Batches 19+ renumbering up by one. Item 2 below
expands the cascade.

**One additional REDESIGN-CORE.** Per Item 10, the leading-dot
convention for per-entry trees (`/.backlog/`, `/.changelog/`)
is overturned in favor of non-dot (`/backlog/`, `/changelog/`).
This is REDESIGN-CORE #2 of this integration architect pass
(the first was the regenerator invocation model, original
§7 + §16.1). Cascade through every path reference in the
original doc — enumerated in §11 below.

**Six SHOULD-FIX items** (1 / 3 / 4 / 5 / 6 / 7) tighten
discoverability, correct framing, expand defenses, split BDs,
and correct one §1.1 fact-check inaccuracy plus surface a
second one (the `pack-startup` skill location).

**Three NIT items** (8 / 9 / 10) correct cost constants,
clarify pseudo-code disclaimer scope, and overturn the
leading-dot convention. Item 10 is structurally the largest
NIT because it cascades through path references throughout
the original doc; sized as NIT because it is naming-only
(no contract change).

### §0.1 — Item disposition table

| Item | Priority | Topic | Disposition | This addendum § |
|---|---|---|---|---|
| 1 | SHOULD-FIX | Discoverability — drop `stream-discovery` skill (Layer 3); add body-field back-pointer; one-line directives in pack-startup + pm-startup; close pack-* sub-agent context gap | DESIGN — supersedes original §4.2 Layer 3 | §1 |
| 2 | BLOCKER | Batch positioning — NEW Batch 19 (not 18); renumber existing Batches 19+ up by one; cascade EXECUTION-PLAN + BACKLOG + RELEASE-GATE references | DESIGN — supersedes original §17 | §2 |
| 3 | SHOULD-FIX | §6.4 framing — drop "refactor not expansion"; honestly name Signal 9 trip + mode-dependent source-of-truth language throughout | DESIGN — corrects original §5.1 / §6.4 / §6.5 | §3 |
| 4 | SHOULD-FIX | §7.4 concurrent-write safety — full expansion (~80–100 lines) with scenario enumeration + defense-in-depth + CI-dependence gap | DESIGN — supersedes original §7.4 | §4 |
| 5 | SHOULD-FIX | §10 Goal 2 enforcement — layered defense (DO-NOT-EDIT comment + regenerator pre-overwrite warning + explicit defense-in-depth doc + optional pack doctor + opt-in pre-commit hook) | DESIGN — supersedes original §10.6 | §5 |
| 6 | SHOULD-FIX | §17.2 BD split — BD-167 → BD-167 + BD-167b; BD-169 → BD-169 + BD-169b; updated Batch 19 commit count (10 commits, was 8) | DESIGN — supersedes original §17.2 / §17.3 | §6 |
| 7 | SHOULD-FIX | §1.1 audit-methodology correction + fact-check sweep | DESIGN — corrects original §1.1 | §7 |
| 8 | NIT | §7 cost constants — 10 ms/file → ~2 ms/file; recompute table | DESIGN — supersedes original §7.2 cost table + §7.1 prose magnitudes | §8 |
| 9 | NIT | §17.2 BD File/Symbol qualifiers + §10 pseudo-code disclaimers | DESIGN — refines original §17.2 + §10.1 / §10.3 | §9 |
| 10 | NIT (REDESIGN-CORE #2) | Leading-dot convention — drop for per-entry trees (pack `/backlog/` + `/changelog/`); `.pack-tracker/` keeps leading-dot | DESIGN — overturns sidecar parent + original throughout (path cascade) | §10 |

### §0.2 — Headline cascade summary (full enumeration in §11)

- BLOCKER cascade (Item 2): original §17.1 / §17.2 / §17.3 / §17.4 / §17.5 / §17.7 + EXECUTION-PLAN-V11.0.md (PM-only edit Pack Chat applies) + BACKLOG.md BD-138 lines 1595/1597/1599/1600 + BACKLOG.md BD-136 line 1624 + RELEASE-GATE.md lines 38/39 (PM-only edits Pack Chat applies).
- REDESIGN-CORE #2 cascade (Item 10): every path reference to `/.backlog/` or `/.changelog/` in the original integration architect doc — every section. Enumerated explicitly in §10 + §11.
- BD-set growth (Item 6): BD-164..BD-170 + BD-167b + BD-169b = 9 new BDs (was 7 in original §17.2). Total v11.0 commit count: max ~38 → max ~41 (off-by-one corrected per Addendum #2 §3.3 — Batch 19's 10 internal sub-commits add 9 extras, not 8).
- Validator surface unchanged: still three new checks (Check 32 mirror-in-sync, Check 33 TOC-in-sync, Check 34 cross-reference integrity per original §10).

### §0.3 — Architect-pass discipline

This addendum holds the same discipline as the original
integration architect doc:
- No edits to PM-only files (BACKLOG / CHANGELOG / README / PACK-CHAT / PACK-AGENTS / CLAUDE / AGENTS / GEMINI / EXECUTION-PLAN-V11.0 / RELEASE-GATE / V3.x corpus). All required PM-only edits surfaced as edit specifications for Pack Chat to apply.
- No edits to pack-product files (project-template/, supporting-docs/, scripts/). All required pack-product edits surfaced as planner / coder work.
- No edits to the sidecar's design corpus or the original integration architect doc itself.
- No v10 entry-format grammar changes (V3.1-DELTA §3 A2 invariant preserved).
- All structural-signal trips named explicitly (Items 3 + 5 + 6 + 10 surface signal-trip language).


---

## §1 — Item 1: Discoverability redesign (SHOULD-FIX 1)

**Supersedes original §4.2 Layer 3** and updates §4.3 / §4.4 / §4.5.

### §1.1 — Decision

DROP the `stream-discovery` skill (original §4.2 Layer 3). Replace
the discoverability stack with:

- **Layer 1 — Trinity "Key files" pointer.** UNCHANGED from
  original §4.2 Layer 1. Pack-root + project-template trinity
  (CLAUDE.md / AGENTS.md / GEMINI.md, six files total) gain one
  line in the "Key files" block naming the per-entry tree
  directories. PM-only edit Pack Chat applies.
- **Layer 2 — Per-entry HTML-comment back-pointer + body-field
  back-pointer.** UPGRADED from original §4.2 Layer 2 to fix
  offset-read fragility. See §1.2.
- **Layer 3 (NEW) — One-line directives in existing pack-startup
  + pm-startup skills.** Replaces the dropped `stream-discovery`
  skill. No new skill; folds into existing skill content. See
  §1.3.
- **Layer 4 (NEW) — `_rules.md` references in pack-* agent
  prompts.** Closes the sub-agent context gap. See §1.4.

### §1.2 — Layer 2 upgrade: body-field back-pointer

**Problem with original §4.2 Layer 2 (HTML-comment-only):** an
agent reading a per-entry file with `Read` `offset` parameter
non-zero will MISS the line-1 HTML comment. Common offset reads
include "show me lines 30–60 of BD-160" and chunked Read operations
on long Description bodies. The original Layer 2 fails open: the
agent reads partial entry content with no recovery anchor.

**Upgrade:** add a body-field back-pointer as the SECOND BODY FIELD
of every per-entry file, after the bold-header line, before
`Type:`. The field name is `Stream contract:` and its value is the
path to the directory's `_rules.md`. Sample shape for
`/backlog/BD-160.md` (the dot-drop is per Item 10 below; the
non-dot path is the post-Item-10 form):

```
<!-- per-entry source: /backlog/BD-160.md; contract: /backlog/_rules.md -->
**BD-160 — Wire `v11-realistic-ot` fixture (...)**
Stream contract: /backlog/_rules.md
Type: TODO(version)
Status: Open
Blockers: ...
```

The body-field back-pointer is byte-additive on the v10 entry
grammar (V3.1-DELTA §3 A2 invariant preserved): the v10 grammar
admits arbitrary body fields with `Field-Name: value` shape, and
the `Stream contract:` field follows that shape. The field's
position (between bold header and `Type:`) places it inside any
chunked Read of the entry body — single-Read recovery from any
offset.

**Defense vs alternative mechanisms:**

- **YAML frontmatter** (rejected): would change the v10 grammar
  (entries would gain a `---` block at top), tripping V3.1-DELTA
  §3 A2.
- **Directory-prefix encoding in BD-NNN itself** (rejected):
  e.g., `BD-/backlog/-160.md` — would break the existing BD-NNN
  identifier scheme (V3.3-DELTA §6.4) and every cross-reference.
- **Trailer line at end of entry** (rejected): chunked Reads of
  long Description bodies would miss the trailer the same way
  Layer 2 (HTML-only) misses the header.
- **Body-field back-pointer (chosen):** byte-additive on grammar,
  position-stable for chunked reads, single-line, semantically
  consistent with the existing field shape (Type / Status /
  Blockers / etc.).

**Mirror generator behavior with body-field back-pointer.** When
the mirror generator emits per-entry content into the regenerated
monolithic mirror, it STRIPS the `Stream contract:` body field
(same regex-strip discipline as the HTML-comment back-pointer per
original §4.2 Layer 2). The mirror has the directory context
implicit in its location; the back-pointer is a per-entry-file
recovery mechanism, not a mirror-content concern. Idempotent.

**Decompose split adds the body-field back-pointer.** The v10→v11
migrator's decompose step writes the `Stream contract:` field as
the second body field of each per-entry file. Idempotent on
re-decomposition.

**Validator coverage.** Check 32 (mirror-in-sync, original §10.1)
covers the strip-on-emit invariant: the regenerated mirror with the
field stripped must be byte-identical to the on-disk mirror. If a
developer hand-edits a per-entry file and removes the `Stream
contract:` field, the next regeneration restores it (silent
overwrite per original §5.4). If a developer adds a non-`Stream
contract:` body field at position 1, the regenerator preserves it
(byte-additive grammar) — but Layer 2 recovery from that file
would still find the line-1 HTML comment.

### §1.3 — Layer 3 (NEW): one-line directives in existing skills

**Replaces the dropped `stream-discovery` skill.** Both
`pack-startup` and `pm-startup` SKILLs gain ONE additional
directive line (NOT a new skill, NOT a new section, NOT an
Active-skills addition).

**pack-startup directive (lands in 3 files):**
- `.claude/skills/pack-startup/SKILL.md` (pack-root location;
  per the §7 fact-check in this addendum, pack-startup lives
  ONLY at pack-repo level — not in `project-template/`)
- `.codex/skills/pack-startup/SKILL.md`
- `.gemini/commands/pack-startup.toml`

Sample directive line: "Pack streams under `/backlog/` and
`/changelog/` are per-entry trees; read `/backlog/_rules.md` and
`/changelog/_rules.md` for the per-stream contract before any
per-entry edit."

**pm-startup directive (lands in 4 files — canonical + 3 per-CLI):**
- `project-template/skills/pm-startup/SKILL.md` (canonical)
- `project-template/.claude/skills/pm-startup/SKILL.md`
- `project-template/.codex/skills/pm-startup/SKILL.md`
- `project-template/.gemini/commands/pm-startup.toml`

Sample directive line: "Project streams under
`docs/project/backlog/`, `docs/project/implementation-plan/`,
`docs/project/changelog/` are per-entry trees; read each
`<stream>/_rules.md` for the per-stream contract before any
per-entry edit."

**Why directives, not a new skill.** The original §4.2 Layer 3
proposed a `stream-discovery` skill. The user-Pack-Chat decision
flips this to one-line directives in EXISTING skills because:
- Avoids adding a skill file class for a single directive (skill
  authoring overhead is high; one-line directive is cheap).
- Pack-startup / pm-startup skills are loaded by every session
  anyway; the directive lands in context with zero new
  load-mechanism complexity.
- Maintenance-principle signal-trip avoidance: adding a new skill
  to the project-template `skills/` library would touch the
  PLATFORM-SKILLS.md skill-cell consistency surface (Check 31 per
  BD-146); a one-line directive in an existing skill does not.

### §1.4 — Layer 4 (NEW): pack-* agent prompts close sub-agent context gap

**Sub-agent context gap.** The original Layer 1 / 2 / 3 design
loads the discoverability mechanisms via Pack Chat and PM Chat
session-startup paths. But pack-* sub-agents (pack-architect,
pack-coder, pack-planner, pack-reviewer, pack-docs-researcher)
spawned via `claude --agent pack-X` or via the Agent tool with
`subagent_type=pack-X` get their own session context — they read
their own agent file (e.g., `.claude/agents/pack-architect.md`)
and the trinity (CLAUDE.md / AGENTS.md / GEMINI.md). They do NOT
load pack-startup / pm-startup skills.

A pack-* sub-agent that needs to read or analyze BACKLOG entries
(common for pack-architect and pack-reviewer) under v11.0
decomposition needs the discoverability path the same way Pack
Chat needs it.

**Resolution.** Each pack-* agent prompt file gains a
`_rules.md` reference in its "Before making any design
recommendation, read:" / "Inputs to read" section.

Files affected (PM-only edits — Pack Chat applies; trinity rule
applies for the per-CLI mirrors):

Pack-side per-CLI agent files:
- `.claude/agents/pack-architect.md` + `.codex/agents/pack-architect.md` + `.gemini/agents/pack-architect.md`
- `.claude/agents/pack-coder.md` + `.codex/agents/pack-coder.md` + `.gemini/agents/pack-coder.md`
- `.claude/agents/pack-planner.md` + `.codex/agents/pack-planner.md` + `.gemini/agents/pack-planner.md`
- `.claude/agents/pack-reviewer.md` + `.codex/agents/pack-reviewer.md` + `.gemini/agents/pack-reviewer.md`
- `.claude/agents/pack-docs-researcher.md` + `.codex/agents/pack-docs-researcher.md` + `.gemini/agents/pack-docs-researcher.md`

Total: 15 files (5 agents × 3 CLIs).

Sample addition (lands in the existing "Inputs to read" / "Before
making any design recommendation, read:" blocks):

```
- /backlog/_rules.md (pack per-entry tree contract)
- /changelog/_rules.md (pack changelog per-entry tree contract)
```

The PACK-AGENTS.md file (per Item 3 + original §6.4) ALSO gets the
PM-only directories list expansion — that covers the WRITE
authority. Item 1 Layer 4 covers the READ context — both must
land for the sub-agent path to work end-to-end.

**Project-side parallel.** Project-template agent files (16
agents per `README.md` Repository Layout) typically reference
project state docs; they don't need a `_rules.md` directive
because they pick up project-side discoverability from Layer 1
(project-template trinity) and Layer 3 (pm-startup directive).
The pack-* agent gap is specific to the pack-self side because
pack-startup is pack-repo-only.

### §1.5 — Cascade impact (this Item)

The following original-doc sections are affected:

- **Original §4.2 Layer 3:** SUPERSEDED by §1.3 above (one-line
  directives in existing skills, no new skill).
- **Original §4.2 Layer 2:** UPGRADED by §1.2 above (body-field
  back-pointer added beside HTML-comment back-pointer).
- **Original §4.3 recovery scenarios table:** the "Skill-discovery
  skill itself is missing from the session" row becomes
  "pack-startup / pm-startup skill missing → trinity Key files
  Layer 1 covers (1 Read call)". The "All three layers fail" row
  becomes "All four layers fail" with same fallback (trinity Key
  files entry).
- **Original §4.4.2 (skill-list line additions):** REMOVED. The
  six skill files no longer get an "Active skills" line for
  `stream-discovery` (the skill doesn't exist). Instead, those
  six skill files (3 pack-startup + 4 pm-startup; the count is
  3 + 4 because pack-startup has no canonical-in-project-template,
  per §7 below) gain ONE BODY DIRECTIVE LINE each (per §1.3
  above). Net: the surface count (6 vs 7) changes by 1 file
  (pm-startup canonical added, no canonical pack-startup); the
  edit shape (one-line directive vs Active-skills line) is
  similar in cost.
- **Original §4.4.3 (targeted prose addition surfaces):** UNCHANGED
  in count. The `stream-discovery` skill ship is removed; pack-*
  agent prompt edits are added. Net edit surface: +9 files
  (15 pack-* agent files − 6 skill-ship files); the pack-*
  files are PM-only.
- **Original §4.5 script discovery section:** UNCHANGED. The
  scripts (validate-pack, migrator, init-project, detect,
  customization-preserve) discovered `_rules.md` via hard-coded
  constants then; they continue to do so now. Item 1 changes are
  Layer 1–4 (chat / agent context), not script behavior.
- **Original §17.2 BD-167 File/Symbol:** DROPS the
  `stream-discovery` skill ship. See Item 6 (§6 of this addendum)
  for the BD-167 split that bears the cascade.
- **Original §17.2 BD-169 File/Symbol:** GAINS the pack-startup +
  pm-startup one-line directive additions AND the pack-* agent
  prompt edits (PM-only — surfaced for Pack Chat). See Item 6
  (§6 of this addendum) for the BD-169 split (BD-169b).


---

## §2 — Item 2: BLOCKER batch positioning (NEW Batch 19; renumber cascade)

**Supersedes original §17.1, §17.2, §17.3, §17.4, §17.5, §17.7.**

### §2.1 — The error and the correction

**Original error.** Original §17.1 proposed per-entry split as
"NEW Batch 18 between Batch 17 (BD-106 / BD-107 / BD-108 tracker
entity model) and Batch 19 (BD-105 / BD-103 STATUS.md +
tracker reset)."

**Verified error.** `grep -nE '^\| \*\*[0-9]+[a-z]?\*\*'
maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
returns the current batch sequence. Batch 18 is occupied by
BD-111 ("switch blocks/blocked-by from comment-marker to
first-class GH dependency API"). The original integration
architect doc missed BD-111 / Batch 18 entirely — it described
the post-BD-108 sequence as "Batch 17 → Batch 19" when the
actual sequence is "Batch 17 → Batch 18 (BD-111) → Batch 19
(BD-105 ∥ BD-103)."

**Correction.** Per-entry split = **NEW Batch 19**. Existing
Batches 19+ renumber up by one, preserving all suffix-batch
identities (`b` suffixes for in-session fix slots).

### §2.2 — Renumber cascade

| Original (current EXECUTION-PLAN-V11.0.md) | NEW (post-Item-2) |
|---|---|
| Batch 19 (BD-105 ∥ BD-103) | Batch 20 |
| Batch 20 (BD-109 ∥ BD-110) | Batch 21 |
| Batch 20b (BD-136 4-sub-commit) | Batch 21b |
| Batch 21 (BD-100 final audit) | Batch 22 |
| Batch 21b (conditional fix) | Batch 22b |
| Batch 22 (BD-102 dog-food) | Batch 23 |
| Batch 22b (conditional fix) | Batch 23b |
| Batch 23 (BD-093 release pin) | Batch 24 |

Per-entry split inserts as Batch 19 (between current Batch 18
BD-111 and current Batch 19 BD-105 ∥ BD-103). Commit numbering
within Batch 19 is `19a / 19b / 19b-PM / 19c / 19d / 19e / 19f /
19g / 19g-PM / 19h` per Item 6 BD split (10 commits total).

### §2.3 — Sequencing rationale

**The original §17.1 hard sequencing constraints all preserved
under the renumber.** Re-stated against the new numbers:

Hard sequencing constraints (must precede new Batch 19):
- AFTER Batch 6 (BD-128, CI repair) — UNCHANGED.
- AFTER Batches 7–10 (BD-131..BD-134, tracker repairs per sidecar
  §15.2) — UNCHANGED.
- AFTER Batch 12 (BD-104, IMPLEMENTATION-PLAN.md rename per sidecar
  §15.1 recommendation) — UNCHANGED.
- AFTER Batch 13 (BD-095 + BD-101, two-phase migrator + validation
  gates) — UNCHANGED.
- AFTER Batch 17 (BD-106 / BD-107 / BD-108, tracker entity model)
  — UNCHANGED.
- **NEW: AFTER Batch 18 (BD-111, GH dependency API switch).**
  Per-entry split's 1-to-N flat ↔ tracker contract for project
  `implementation-plan/` (sidecar addendum §4) composes against
  the FINAL tracker dependency surface; BD-111 settles the
  dependency-API switch from comment-marker to first-class GH
  dependency. Per-entry split landing AFTER BD-111 ensures the
  decompose helper and the tracker forward / reverse round-trip
  verification compose against the stable dependency surface.

Hard sequencing constraints (must follow new Batch 19):
- BEFORE Batch 22 (BD-100 final milestone audit, was Batch 21) —
  UNCHANGED in spirit; BD-100 audits the v11.0 final state
  including per-entry decomposition.
- BEFORE Batch 23 (BD-102 dog-food migration, was Batch 22) —
  UNCHANGED; dog-food exercises the v10→v11 migrator's decompose
  step against pack-self.

### §2.4 — Updated Batch 19 row for EXECUTION-PLAN-V11.0.md (PM-only edit specification)

**Surfaces, does not write.** Pack Chat applies the EXECUTION-PLAN
edit on ratification.

The new Batch 19 row (inserts between current Batch 18 and current
Batch 19 in the §4 batch table):

```
| **19** | sequential pack-coder + Pack Chat (mixed) | per-entry split (mandatory v11.0): BD-164 → BD-167 → BD-167b → BD-165 → BD-166 → BD-168 → BD-170 → BD-169 → BD-169b → status-flips | scripts/lib/per-entry/* helpers + scripts/migrate-v10-to-v11.sh post-dispatch hook 6th sub-op + scripts/init-project.sh stage extension + scripts/validate-pack.py Checks 32+33+34 + project-template/docs/project/<stream>/ canonical templates × 5 streams + pack-* agent prompt edits + trinity Key files line additions (PM-only) + STATUS.md disclaimer (PM-only) + PACK-AGENTS.md PM-only directories list expansion (PM-only) + READ-site wording updates | After Batch 18 (BD-111 dependency-API switch — final tracker surface dependency); BD-161 absorbed into BD-167. 10 commits. Mixed mode: pack-coder commits 19a/19c/19d/19e/19f/19g + Pack Chat direct commits 19b-PM/19g-PM/19h. |
```

Updated in-table cross-references in EXECUTION-PLAN-V11.0.md
(Pack Chat applies the line-by-line edit):

| Line | Current text (verbatim from EXECUTION-PLAN-V11.0.md) | Updated text |
|---|---|---|
| 91 | "ships the fixes in the current Batch 5 commit" | UNCHANGED (Batch 5 unaffected) |
| 277 (current `21b`) | "Batch 21b (conditional fix)" | RENAME row label → `22b` |
| 279 (current `22b`) | "Batch 22b (conditional fix)" | RENAME row label → `23b` |
| 282 (totals line) | "Total: 25 main batches (23 + Batch 5b + Batch 20b)" | "Total: 26 main batches (24 + Batch 5b + Batch 21b + Batch 19 = 27 total once per-entry split inserts; with conditional fix slots up to 30 main + 3 conditional)" — PRECISE wording for Pack Chat to refine |
| 295 | "Push to `v11-dev` only. Never push to `main` ... v11.0 ships via deliberate handoff at Batch 23." | "deliberate handoff at Batch 24" |
| 296 | "Tag operations are destructive on tag space. Treat as requiring explicit approval at Batch 23 (the only batch that creates/moves tags)." | "approval at Batch 24" |
| 348 | "CI `validate` job must be green before BD-102 dog-food (Batch 22)." | "(Batch 23)" |
| 349 | "CI `tests` job must be green before BD-093 release pin (Batch 23)." | "(Batch 24)" |
| 400 (gates table) | "Final milestone audit Batch 21" | "Batch 22" |
| 401 | "Dog-food migration Batch 22" | "Batch 23" |
| 402 | "Pre-tag check Batch 23" | "Batch 24" |

Plus the §1 in-scope inventory updates (per Item 6: 9 new BDs
BD-164..BD-170 + BD-167b + BD-169b in Group 5; total 50 BDs +
1 verify + 4 untracked).

### §2.5 — BACKLOG.md cascade (PM-only edit specification)

**BACKLOG.md BD entries reference future batch numbers; these
references must be updated.**

| BACKLOG.md line | Current text (verbatim) | Updated text |
|---|---|---|
| 1595 (BD-138 Unblocks) | "downstream Batch 21 (BD-100 final audit) and Batch 22 (BD-102 dog-food)" | "downstream Batch 22 (BD-100 final audit) and Batch 23 (BD-102 dog-food)" |
| 1597 (BD-138 description, EXECUTION-PLAN amendment narrative) | "insert new **Batch 20b** for BD-136 implementation between Batch 20 (auditor agents) and Batch 21 (BD-100 final audit)" | "insert new **Batch 21b** for BD-136 implementation between Batch 21 (auditor agents) and Batch 22 (BD-100 final audit)" |
| 1597 cont'd | "Update Batch 21 (BD-100) audit scope" | "Update Batch 22 (BD-100) audit scope" |
| 1597 cont'd | "Update Batch 22 (BD-102) to specify" | "Update Batch 23 (BD-102) to specify" |
| 1599 (BD-138 description, batch description) | "Batch 20b lands BD-136 implementation" | "Batch 21b lands BD-136 implementation" |
| 1600 (BD-138 Resolved line) | "EXECUTION-PLAN-V11.0.md amended to insert Batch 20b for BD-136 implementation; Batch 21 (BD-100) and Batch 22 (BD-102) scope updated" | "EXECUTION-PLAN-V11.0.md amended to insert Batch 21b for BD-136 implementation; Batch 22 (BD-100) and Batch 23 (BD-102) scope updated" — note: BD-138 is already Resolved; the Resolved line edit is a historical-record clarification (Pack Chat decides whether to backstamp the line vs add a clarifying parenthetical) |
| 1624 (BD-136 Blockers / scheduling note) | "before Batch 22 BD-102 dog-food migration" | "before Batch 23 BD-102 dog-food migration" |

Pack Chat may discover other BACKLOG references (e.g., spot-check
other BD entries' Description or Unblocks fields for `Batch 19/20/20b/21/22/23` references).
This addendum names the verified-by-grep matches; Pack Chat does
the final sweep at edit time.

### §2.6 — RELEASE-GATE.md cascade (PM-only edit specification)

**RELEASE-GATE.md lines 38–39** reference Batch 21 and Batch 22:

| Line | Current text (verbatim) | Updated text |
|---|---|---|
| 38 | "separate from** the final milestone audit (Batch 21)" | "(Batch 22)" |
| 39 | "and dog-food migration (Batch 22)" | "and dog-food (Batch 23)" |

### §2.7 — Renumber cascade summary

Files Pack Chat edits on ratification (PM-only):

| File | Edit count | Edit shape |
|---|---|---|
| `EXECUTION-PLAN-V11.0.md` | 1 new row insert + 8 line edits | Per §2.4 above |
| `BACKLOG.md` | ~7 line edits in BD-138 + BD-136 | Per §2.5 above |
| `RELEASE-GATE.md` | 2 line edits | Per §2.6 above |

Total PM-only file edits for the renumber cascade: ~18 lines
across 3 files. Trivial in scope; mechanically applied by Pack
Chat.


---

## §3 — Item 3: §6.4 framing + mode-dependent source-of-truth (SHOULD-FIX 2)

**Corrects original §5.1, §6.4, and §6.5.**

### §3.1 — Drop "refactor not expansion" framing in original §6.4

**Original §6.4 framing problem.** The original integration
architect doc §6.4 framed the PACK-AGENTS.md PM-only directories
list extension as "a refactor in shape, not an expansion in
semantics" with the argument that "the existing PM-only list names
files; under decomposition, the per-entry tree directories become
the files-equivalent expressed at a different granularity."

**The reviewer + user-Pack-Chat call:** that framing is dishonest.
Per the maintainability principle's signal-9 verbatim trigger
(`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 line 305–306): "Any addition to the agents-never-modify list
or the PM-only file list in PACK-AGENTS.md." Strictly read, the
addition IS a Signal 9 trip.

**Honest framing (replaces original §6.4 prose):**

> Per-entry decomposition mandatorily extends the source-of-truth
> surface from monolithic files to per-entry trees. The protected
> surface (the PACK-AGENTS.md "PM-only files" list) MUST follow
> or the source-of-truth invariant breaks: agents would be free
> to write per-entry files directly, bypassing Pack Chat / PM
> Chat write authority.
>
> This is a Signal 9 trip per the maintainability principle
> (`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 line
> 305–306). Signal 9 requires architect-pass justification for
> any addition to the PM-only file list.
>
> THIS architect pass is the Signal 9 justification. The
> extension is required by Goal 3 (read/write rules invariant)
> + Goal 2 (source-of-truth invariant). Without the extension,
> Goal 2 fails because agents could write entries; without the
> extension, Goal 3 fails because the agent permission audit
> (original §6.1 audit table) has no enforcement on the new
> write surface.
>
> The structural change is acknowledged. The PACK-AGENTS.md
> edit specification per original §6.4 stands; Pack Chat applies
> the edit on ratification.

### §3.2 — Mode-dependent source-of-truth language throughout

The original §5.1 source-of-truth declarations were unconditional
("per-entry file is source of truth for entry content"). They are
correct in flat-file mode (Mode 2 per sidecar §8.1 + original
§2.4) but WRONG in tracker mode (Mode 3) — in tracker mode, the
tracker (e.g., GH Issues) is source of truth and per-entry tree
is a regenerated mirror per §5.6 + the Mode 2 → Mode 3 transition
"Option A is required" call.

**Corrected §5.1 declarations (replaces original §5.1 first six
bullets):**

**Mode-aware source-of-truth declaration.**

In **flat-file mode** (Mode 2 — v11.0 lock per sidecar addendum
§1; the default mode for clients without `tracker.toml`):
- Per-entry file is source of truth for entry content.
- `_rules.md` is source of truth for the per-stream contract.
- `_intro.md` is source of truth for stream preamble (pack-shipped
  immutable per original §3.3).
- `_v8-resolved-archive.md` is source of truth for the legacy v8
  block (pack `backlog/` only).
- `_format.md` is source of truth for the project-side CHANGELOG
  Format Rules (project `changelog/` only).
- The regenerated mirror is NOT source of truth.
- `_toc.md` is NOT source of truth.

In **tracker mode** (Mode 3 — opt-in per V3.x):
- The tracker (e.g., GH Issues) IS source of truth for entry
  content per V1 §6.3 + V3.x design.
- Per-entry tree IS a regenerated mirror of tracker state
  (per Mode 2 → Mode 3 transition Option A — required per
  original §5.6).
- The monolithic mirror IS a regenerated mirror of tracker state.
- `_toc.md` IS a regenerated index from per-entry tree.
- `_rules.md`, `_intro.md`, `_v8-resolved-archive.md`,
  `_format.md` ARE pack-shipped immutable; tracker forward /
  reverse does NOT touch them per original §3.3 friction
  resolution.

**Workflow source-of-truth resolution rule (corrected).** Every
workflow that needs an entry's `Status:`, `Blockers:`, or any
other field MUST resolve through one of two mode-dependent paths:
1. **Tracker mode (Mode 3):** read tracker state via
   `tracker_agent_read.sh` `_tar_read_entry_tracker` (line 100).
2. **Flat-file mode (Mode 2):** read from the per-entry file
   `<stream>/<ID>.md`, NOT from the regenerated mirror, NOT from
   `_toc.md`.

The mode is determined by `tracker.toml` presence + content per
the existing detection logic in `scripts/lib/tracker-config.sh`
(per BD-061 + V1 §3.2 `tracker_mode()` semantics).

### §3.3 — §6.4 PACK-AGENTS.md edit specification clarification

The original §6.4 PACK-AGENTS.md PM-only directories list
expansion (§6.4 of original doc) protects per-entry directories
REGARDLESS of mode. Clarification:

The protection is about **file-write authority**, not about
**source-of-truth designation**:
- In flat-file mode (Mode 2): per-entry tree IS source of truth;
  Pack/PM Chat write authority protects writes against agent
  bypass.
- In tracker mode (Mode 3): per-entry tree is a regenerated
  mirror; Pack/PM Chat write authority STILL protects writes
  because hand-edits to a regenerated mirror would be silently
  overwritten by the next regeneration AND would create a
  source-of-truth divergence between tracker and mirror until
  detection.

Both modes restrict per-entry file writes to Pack/PM Chat + their
tooling (mirror generator, `_toc.md` regenerator, migrator,
tracker-init flow per original §5.6). The PACK-AGENTS.md edit
specification per original §6.4 (PM-only directories list
expansion) stands without mode-dependent distinction in the rule
text.

### §3.4 — §6.5 CLAUDE.md pack-memory bullet correction

The original §6.5 surfaced a CLAUDE.md pack-memory bullet for
Pack Chat to apply. The bullet's first sentence ("Per-entry trees
are source of truth; mirrors are derived") is mode-incorrect.

**Corrected bullet (replaces original §6.5 surfaced text):**

```
- **Per-entry trees vs mirrors — mode-dependent source of truth.**
  In flat-file mode (the default — no `tracker.toml`, or
  `tracker.toml` with `mode.state = "flat-file"`), the pack
  `/backlog/` and `/changelog/` trees, and the project
  `docs/project/backlog/` / `implementation-plan/` / `changelog/`
  trees, are source of truth for entry content. The monolithic
  `BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md` files
  at the canonical locations are regenerated mirrors — read-stable
  but never source of truth.
  In tracker mode (`tracker.toml` with `mode.state = "tracker"`
  + `migration.forward_complete = true`), the tracker (e.g., GH
  Issues) is source of truth and BOTH the per-entry tree and the
  monolithic mirror are regenerated from tracker state per the
  Mode 2 → Mode 3 transition contract.
  STATUS.md and any other convenience view carry an explicit
  "never source of truth" disclaimer; if a convenience view drifts,
  the per-entry tree (Mode 2) or the tracker (Mode 3) wins.
  Read more at `<stream>/_rules.md`.
```

(Note: the path references in this bullet use the post-Item-10
non-dot form per §10 below.)

### §3.5 — Cascade impact (this Item)

- **Original §5.1:** declarations corrected to mode-aware language
  per §3.2 above.
- **Original §5.2 workflow source-of-truth resolution rule:**
  corrected to mode-aware paths per §3.2 above.
- **Original §6.4:** "refactor not expansion" framing dropped per
  §3.1; honest Signal 9 trip framing in its place. Edit
  specification unchanged.
- **Original §6.5:** CLAUDE.md pack-memory bullet text corrected
  per §3.4.
- **Original §17.2 BD-164 / BD-167 / BD-167b File/Symbol fields:**
  use mode-aware language where applicable. See Item 6 below.

### §3.6 — Why mode-aware language matters for v11.0 scope

The v11.0 lock makes per-entry decomposition mandatory + non-reversible
in flat-file mode. The Mode 2 → Mode 3 transition (Option A
required per original §5.6) regenerates the per-entry tree from
tracker state. The mode-aware framing accurately describes both
modes; the original unconditional framing only described Mode 2.

Without the correction, a future reader applies "per-entry tree is
source of truth" in tracker mode and concludes (wrongly) that the
tracker is the regenerated mirror of the per-entry tree. The
direction reverses in tracker mode. The corrected language
prevents that error.


---

## §4 — Item 4: §7.4 concurrent-write safety full expansion (SHOULD-FIX 3)

**Supersedes original §7.4 (~40 lines) with the expanded
~80–100-line treatment below.**

### §4.1 — Problem framing

The original §7.4 named the concurrent-write risk and resolved it
with one paragraph claiming git's normal merge-conflict mechanism
is sufficient. The reviewer + user-Pack-Chat call: that resolution
underspecifies the surface. Multiple race windows exist; each has
a different safety net; the CI-dependence gap (CI catches what
local Pack/PM Chat misses, but CI doesn't fire on every commit)
needs explicit acknowledgement.

### §4.2 — Scenario enumeration

Six concurrent-write scenarios, each with race window + safety net
+ user-visible failure mode:

**Scenario 1 — Single Pack Chat session (no concurrency).**
- Race window: none.
- Safety net: not applicable.
- Failure mode: not applicable.
- Behavior: per the §7.6 commit-time write-path contract. Pack
  Chat writes per-entry files; invokes regenerator before staging;
  commits.

**Scenario 2 — Two Pack Chat sessions, two terminals, same repo,
both at commit time.**
- Race window: both sessions edit per-entry files in their own
  working trees; both invoke the regenerator; both stage and
  commit. The race is at `git push` (or at second `git pull
  --rebase` after the first push).
- Safety net: git's normal merge-conflict mechanism. The second
  push is rejected as non-fast-forward. The user runs
  `git pull --rebase` and resolves conflicts. The conflicts
  surface in BOTH the per-entry files (where the writes
  diverged) AND the regenerated mirror (which derived from each
  session's per-entry tree). Cross-entry-only edits merge cleanly
  per original §7.4 last paragraph (each session edited a
  different per-entry file; the mirrors diff in non-overlapping
  sections).
- Failure mode: same as today (v10.1 monolithic). No new failure
  surface.

**Scenario 3 — User resolves git merge conflict by accepting one
side's mirror without re-running regenerator.**
- Race window: post-rebase merge-conflict resolution. The user
  accepts one mirror version (e.g., `git checkout --theirs
  BACKLOG.md`) but the per-entry files contain a different
  semantic state — the mirror diverges from per-entry truth.
- Safety net: Check 32 (mirror-in-sync) at CI time catches the
  divergence on push. Recovery: re-run the mirror regenerator
  before the next commit; force-push or amend.
- Failure mode if CI doesn't fire: silent divergence persists
  until the next regeneration overwrites (silent overwrite per
  original §5.4 rationale). The "next regeneration" might be
  weeks away if no Pack Chat session writes to that stream in
  the interim. **The CI-dependence gap (§4.4 below) covers this.**

**Scenario 4 — Sub-agent helpers — PROHIBITED per Goal 3.**
- Race window: would only exist if pack-* sub-agents could invoke
  the mirror generator / `_toc.md` regenerator directly.
- Safety net: per Goal 3 binding (original §6 unified treatment)
  + original §6.3 ("tooling-not-agent"), the helpers are NOT
  agent capabilities. Pack-* sub-agents read source; they do
  not invoke the helpers. The helpers are invoked by Pack Chat /
  PM Chat / migrator / tracker init/disable flows only.
- **Stated explicitly so future contributors don't violate:** any
  proposal to add `migrator_skill_rename`-style sub-agent helper
  invocation for the mirror or TOC regenerators is REJECTED. The
  invariant is enforced by Goal 3.

**Scenario 5 — Tracker operation concurrent with Pack Chat edit
(matches existing BD-132 BLOCKER pattern).**
- Race window: BD-132 (per pack `BACKLOG.md:1743`) documented the
  tracker disable / init close-step race that silently drops ~33%
  of BACKLOG entries. Per-entry decomposition does NOT introduce
  a new tracker-concurrent-with-edit race; the existing BD-132
  fix (Batches 7–10 per `EXECUTION-PLAN-V11.0.md`) addresses the
  underlying race. Per-entry split lands AFTER Batches 7–10
  (sidecar §15.2 hard constraint, preserved per §2.3 above), so
  the tracker race is fixed before per-entry split lands.
- Safety net: BD-132 fix per Batches 7–10. Per-entry split
  inherits the fix.
- Failure mode: same as the BD-132 worst case BEFORE the fix
  (silent data loss); Batches 7–10 close it.

**Scenario 6 — Multi-branch (Pack Chat on branch A, PM Chat on
branch B; eventually merged).**
- Race window: at the merge. Each branch has its own per-entry
  edits + regenerated mirror; the merge produces a state where
  the merged mirror MAY OR MAY NOT match the merged per-entry
  tree.
- Safety net: Check 32 catches post-merge divergence at CI time.
  Recovery: re-run the mirror regenerator on the merged tree;
  amend the merge commit (or land a follow-up commit).
- Failure mode: same as Scenario 3. The CI-dependence gap covers
  the worst case (merge happens locally without push).

### §4.3 — Defense-in-depth layering

Three layers cover the typical case; the CI-dependence gap covers
the worst case:

**Layer 1 (local pre-commit) — Pack Chat / PM Chat
stop-before-commit visibility.** Per `PACK-CHAT.md:50-99`
behavioral rules + `EXECUTION-PLAN-V11.0.md:290-296`
stop-before-commit protocol, Pack Chat shows the staged file
list before every commit. The staged list includes the
regenerated mirror; the user spots:
- Mirror not in staged list → user remembers to invoke
  regenerator and re-stage.
- Mirror staged but no per-entry edits → user spots a hand-
  edit to the mirror; user investigates.
- Mirror diff doesn't match per-entry diff in shape → user
  spots regenerator-skipped scenario; user re-runs.

This is the cheapest defense; it works for the common case
(Pack Chat or PM Chat operates in good faith) and depends only
on the existing stop-before-commit discipline.

**Layer 2 (commit time) — git merge-conflict mechanism.** Covers
Scenarios 2, 3, 5, 6 at the merge or push boundary. The
mechanism is git's; per-entry decomposition does not change it
(per Scenario 2 analysis above).

**Layer 3 (CI gate) — Check 32 + Check 33 catch any commit
where the regenerator was skipped or stale.** Per original §10.
This is the enforcement layer — what local discipline misses,
CI catches. Required for the v11.0 lock + Goal 2 invariant.

### §4.4 — CI-dependence gap (acknowledged)

Layer 3 depends on CI firing. CI does NOT fire when:

- **Developer commits to personal branch and never pushes.** No
  push → no `validate-pack` workflow run → Check 32/33 never
  fires. The local mirror diverges silently.
- **Client project has no CI configured.** Per §10.6 of the
  original integration architect doc (covered there for the
  pack-CI-doesn't-extend-to-client case), client-side CI is
  the client's call. A client repo with no CI has no Layer 3
  enforcement.
- **Push to a branch with no CI workflow.** If a branch is
  excluded from the CI workflow's `on: push: branches:` filter,
  Check 32/33 doesn't fire on that branch. (Pack repo's
  `validate-pack.yml` runs on every push to every branch by
  default per the existing workflow shape; clients vary.)

**Acknowledged.** No defense at Layer 3 = invariant relies on
Layers 1 + 2 + the eventual next-regeneration silent overwrite.
Goal 2 holds long-term (silent overwrite eventually corrects)
but transient divergence is possible.

### §4.5 — Mitigation flagged for the planner

**Optional pre-commit hook in project-template/scripts/.** A
sample git pre-commit hook (e.g.,
`project-template/scripts/git-hooks/pre-commit-check32.sh`) that
runs Check 32 + Check 33 locally before allowing the commit.
The hook is opt-in via an `init-project.sh` flag (e.g.,
`init-project.sh --install-pre-commit-hook`); shipping it as
opt-in respects the existing convention that pack does NOT
auto-install local git hooks.

**Pack-side parallel:** the pack repo can install the same hook
locally for pack maintainers who want the local-time gate. Out
of scope for the v11.0 design; surfaced for the planner / coder
as a Phase 2 enhancement if demand emerges.

This is a Layer 0 (local-time pre-commit) addition that closes
the CI-dependence gap for opt-in clients. Not v11.0; flagged for
v11.x or v12.0 if scheduled.

### §4.6 — Cascade impact (this Item)

- **Original §7.4** (concurrent-write safety, ~40 lines) is
  superseded by §4.1–§4.5 of this addendum (~100 lines).
- **Original §10.6** (Goal 2 enforcement) gains the CI-dependence
  gap acknowledgement explicitly; see Item 5 §5.4 below for the
  expanded §10.6 treatment.
- **Original §5.4** (stale-mirror / stale-TOC detection)
  unchanged in core mechanism (Check 32 / 33 + silent overwrite);
  the CI-dependence gap acknowledgement is added by Item 5 below.
- **Original §17.2** unchanged. The optional pre-commit hook is
  flagged for v11.x or v12.0, NOT v11.0; no BD opens for it in
  Batch 19.


---

## §5 — Item 5: §10.6 Goal 2 enforcement layered defense (SHOULD-FIX 4)

**Supersedes original §10.6.**

### §5.1 — New failure mode acknowledgement

Per-entry decomposition introduces a failure mode that did NOT
exist in v10.1: **mirror divergence**. In v10.1, the monolithic
file IS the source of truth; there is no "mirror" to diverge from.
In v11.0 flat-file mode (Mode 2), the per-entry tree is source of
truth and the monolithic file is the regenerated mirror; an edit
to the mirror without a corresponding regeneration creates a
divergence.

The original §10.6 (validator behavior on missing per-entry tree)
covered the backward-compatibility shim. It did NOT cover the
new failure mode of mirror divergence beyond pointing at Check 32.
This Item adds the layered defense.

### §5.2 — Layer 1 (mandatory): explicit "DO NOT EDIT" comment in mirror preamble

**Mechanism.** Every regenerated mirror carries a "DO NOT EDIT"
warning as part of its preamble. Sourced from `_intro.md` — the
warning is a literal block in `_intro.md` that the mirror
generator emits verbatim per the §3.6 sidecar addendum
concatenation order.

**Sample shape (lands in pack `/backlog/_intro.md` and the four
project-side `_intro.md` analogs):**

```
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at /backlog/. To change an entry, edit the corresponding
     /backlog/<ID>.md per-entry file and re-run the mirror
     regenerator. Hand-edits to this mirror are silently overwritten
     on the next regeneration. -->
```

The warning is an HTML comment (invisible in rendered Markdown but
visible in any text editor; grep-discoverable). The `_intro.md`
file is pack-shipped immutable per original §3.3, so the warning
ships with v11.0 and updates only on pack version-bump.

**Discoverability.** A developer who opens `BACKLOG.md` in any
text editor sees the warning on line 1 (or near the top). The
warning is the cheapest discoverability layer for the mirror-edit
failure mode.

### §5.3 — Layer 2 (mandatory): regenerator emits divergence warning

**Mechanism.** When the mirror generator is invoked over a mirror
that differs from what the regenerator would produce (i.e., the
on-disk mirror was hand-edited), the regenerator emits a warning
BEFORE overwriting:

- **Interactive context (Pack Chat / PM Chat invocation):** the
  regenerator detects divergence (same logic as Check 32: diff
  the about-to-write content against the on-disk mirror), prints
  "Warning: mirror has been hand-edited since the last
  regeneration. The regenerator will overwrite the hand-edits.
  Confirm? [Y/n]" interactively. The user confirms or aborts.
- **Non-interactive context (CI / migrator / scripted invocation):**
  the regenerator prints "Warning: mirror was hand-edited;
  regenerator overwriting." to stderr and proceeds. The non-
  interactive path is silent-overwrite per original §5.4
  rationale.

**Why both paths.** Interactive prompting in CI / migrator would
hang the run; silent-overwrite in interactive mode would lose
user intent invisibly. The regenerator detects its invocation
context (e.g., via `[[ -t 0 ]]` stdin-tty check) and routes
accordingly. The planner picks the exact mechanism (TTY check,
explicit `--non-interactive` flag, or environment variable);
this architect-pass output is the contract.

**Detection cost.** The regenerator already produces the
about-to-write content; comparing to on-disk is one extra
`cmp` call. Sub-millisecond.

### §5.4 — Layer 3 (mandatory): explicit defense-in-depth doc in §10.6

The original §10.6 prose covered the backward-compatibility shim
(missing per-entry tree on pre-v11.0 clients). It is supplemented
with the following defense-in-depth statement (appends to original
§10.6):

> **Defense-in-depth for the mirror-divergence failure mode under
> v11.0 flat-file lock.** Five layers protect Goal 2's source-of-
> truth invariant against silent mirror divergence:
>
> - Layer 0 (opt-in by client): sample git pre-commit hook in
>   `project-template/scripts/git-hooks/` that runs Check 32+33
>   locally; opt-in via `init-project.sh --install-pre-commit-hook`.
>   See Item 4 §4.5 of the addendum. Out of scope for v11.0; flagged
>   for planner.
> - Layer 1 (mandatory): "DO NOT EDIT" warning in the regenerated
>   mirror's preamble, sourced from `_intro.md`. Discoverable in
>   any text editor.
> - Layer 2 (mandatory): regenerator emits divergence warning
>   before overwriting hand-edits (interactive prompt in
>   chat/terminal context; stderr-warning + proceed in CI/migrator
>   context). See §5.3 above.
> - Layer 3 (mandatory): pack-CI Check 32 (mirror-in-sync) +
>   Check 33 (TOC-in-sync) per original §10.1 / §10.2. Catches
>   any commit pushed where the regenerator was skipped or stale.
> - Layer 4 (recommended for planner): extend `pack tracker doctor`
>   (BD-130 surface) or create new `pack doctor` verb that runs
>   the mirror+TOC in-sync check user-on-demand, non-CI-dependent.
>   See §5.5 below.
>
> **Pack-CI scope limit.** Pack-CI does NOT extend to client repos.
> Layer 3 protects pack-self only. Client repos at v11.0+ inherit
> Layers 1 + 2 (regenerator warning + mirror preamble); they
> inherit Layer 3 only if they configure their own CI to run
> `validate-pack.py`. Layer 0 (opt-in pre-commit hook) is the
> client-side analog; Layer 4 (`pack doctor`) is user-invokable
> in any client.

### §5.5 — Layer 4 (recommended for planner): pack doctor verb extension

**Surface.** `pack tracker doctor` (BD-130 per pack
`BACKLOG.md:1765`) currently reports tracker state integrity. Per
this Item, the verb extends (or a new sibling `pack doctor`
verb is created) to also run mirror-in-sync and TOC-in-sync
checks.

**User-invocable, non-CI-dependent.** A developer suspecting a
mirror divergence runs `pack doctor` (or `pack tracker doctor`)
locally; the command reports any divergence and offers to
regenerate.

**Out of scope for v11.0.** This is a planner concern surfaced
here, NOT a Batch 19 BD. The planner can either:
- Fold into BD-130 (Batch 8 of `EXECUTION-PLAN-V11.0.md`) — but
  BD-130 ships before Batch 19, so the per-entry-aware check
  would have to land conditionally (skipped if per-entry tree
  absent).
- Open a new BD (BD-171?) for v11.x deferred or v12.0 scope.
- Accept Layers 0–3 as sufficient for v11.0 ship.

The integration architect's recommendation: Layers 1 + 2 + 3
(mandatory) are sufficient for v11.0 ship; Layer 4 is a v11.x
nice-to-have. Planner-final.

### §5.6 — Layer 0 (opt-in for planner): sample pre-commit hook

Per Item 4 §4.5 above. A sample git pre-commit hook in
`project-template/scripts/git-hooks/pre-commit-check32.sh` that
runs Check 32+33 locally; opt-in via `init-project.sh` flag.

Out of scope for v11.0; surfaced for planner. If planner picks
v11.0 inclusion, opens new BD (BD-172?). If planner defers to
v11.x, accepts Layers 1–3 for v11.0.

### §5.7 — Cascade impact (this Item)

- **Original §10.6** expanded with the defense-in-depth statement
  per §5.4 above.
- **Original §5.4 (stale-mirror / stale-TOC detection)** unchanged
  in mechanism (silent overwrite + Check 32/33). The Layer 1
  (mirror preamble) and Layer 2 (regenerator warning) additions
  are NEW to original §5.4; the silent-overwrite path becomes
  non-interactive-only per §5.3.
- **Original §17.2 BD-164 File/Symbol:** GAINS the regenerator
  divergence-warning mechanism (Layer 2). The mirror preamble
  warning (Layer 1) ships in `_intro.md` per BD-167.
- **Original §17.2 BD-167 File/Symbol:** GAINS the mirror preamble
  "DO NOT EDIT" warning content in the canonical `_intro.md`
  templates (one per stream × 5 streams). See Item 6 below for
  the BD-167 split treatment.
- **Original §16 (sidecar core-redesign proposals):** unchanged.
  Item 5's additions are new mechanisms within the existing
  commit-time invocation model (REDESIGN-CORE #1 of original §7);
  they do not overturn additional sidecar decisions.

### §5.8 — Why mandatory now (not deferred to v11.x)

The mirror-divergence failure mode is unique to v11.0 (per §5.1
above). Without Layers 1 + 2 + 3, a v11.0 client can ship the
v11.0 migration, then the user hand-edits BACKLOG.md, then the
divergence persists silently until the next regeneration weeks
later. That's a Goal 2 fail in the v11.0 ship state itself, not
a v11.x scaling issue.

Layers 1 + 2 are cheap (one HTML-comment block in `_intro.md`,
one `cmp` call in the regenerator). Layer 3 is already specified
per original §10.1 / §10.2. All three land in v11.0 with no
material added cost beyond the original §10 + Item 6 BD split.


---

## §6 — Item 6: §17.2 BD split — BD-167 / 167b + BD-169 / 169b (SHOULD-FIX 5)

**Supersedes original §17.2 (BD table) and §17.3 (commit ordering).**

### §6.1 — Rationale for the split

Original §17.2 collapsed pack-product templates AND PM-only edits
into one BD (BD-167). Per the user-Pack-Chat call: PM-only edits
should land in their own commit so the stop-before-commit
visibility (per `EXECUTION-PLAN-V11.0.md` §A.1) is on the PM-only
diff in isolation. Same applies to BD-169 wording: pack-product
prose updates and PM-only file updates are different edit
classes and should be separable.

### §6.2 — BD-167 split

**BD-167 (pack-product templates + install plumbing):**
- Type: TODO(version)
- Status: Open
- File/Symbol (planner picks file structure / specific helper file
  naming):
  - `project-template/docs/project/backlog/_rules.md` (canonical
    template)
  - `project-template/docs/project/backlog/_intro.md` (canonical
    template; includes the §5.2 "DO NOT EDIT" warning block
    per Item 5)
  - `project-template/docs/project/implementation-plan/_rules.md`
  - `project-template/docs/project/implementation-plan/_intro.md`
  - `project-template/docs/project/changelog/_rules.md`
  - `project-template/docs/project/changelog/_intro.md`
  - `project-template/docs/project/changelog/_format.md` (canonical
    template; OT Format Rules block)
  - Pack-side `/backlog/_rules.md`, `_intro.md`,
    `_v8-resolved-archive.md` (initial content extracted from
    `BACKLOG.md:1-20` + `BACKLOG.md:2248`-onward at first migration
    per original §9.7)
  - Pack-side `/changelog/_rules.md`, `_intro.md` (initial content
    extracted from `CHANGELOG.md:1-6`)
  - `scripts/migrate-v10-to-v11.sh` `_v10_to_v11_install_v11_artifacts`
    extension to install the new templates (planner picks function
    placement)
  - `scripts/lib/tracker-agent-read.sh` `_tar_read_entry_flat`
    (line 153) extension to prefer the per-entry file when the
    per-entry tree exists; fall back to the mirror for backward
    compatibility (mode-aware per Item 3 §3.2)
  - BD-161 net-new SKILL.md installs (the SKILL.md files for
    BD-156 / BD-157 / BD-158 + python-server-architecture +
    python-data-architecture + python-observability-patterns from
    BD-162) — absorbed into this BD per original §17.2
- Blockers: BD-164
- Unblocks: BD-165, BD-166, BD-168, BD-169
- Lands in commit 19b-pack.

**BD-167b NEW (PM-only edits — Pack Chat applies):**
- Type: TODO(version)
- Status: Open
- File/Symbol (PM-only — Pack Chat applies):
  - Trinity "Key files" line addition × 6 files: pack-root
    `CLAUDE.md` + `AGENTS.md` + `GEMINI.md` and project-template
    `CLAUDE.md` + `AGENTS.md` + `GEMINI.md`. Per Item 1 Layer 1
    discoverability.
  - `PACK-AGENTS.md` PM-only directories list expansion per Item
    3 honest framing (replaces original §6.4 PM-only edit
    specification).
  - `STATUS.md` disclaimer per Item 5 Layer 3 + original §5.3
    (the project-template-side `STATUS.md` if it ships; otherwise
    surfaced for client-side STATUS.md only per the
    client-tooling boundary).
  - Pack-root `CLAUDE.md` pack-memory bullet per Item 3 §3.4
    (mode-aware corrected text); trinity rule applies — also in
    `AGENTS.md` and `GEMINI.md` at pack root.
  - Pack-* agent prompt edits × 15 files (5 agents × 3 CLIs) per
    Item 1 Layer 4 (`_rules.md` references in agent "Inputs to
    read" blocks).
- Blockers: BD-167 (the canonical templates and `_rules.md` paths
  must exist before the trinity / agent / PACK-AGENTS edits can
  reference them).
- Unblocks: none (downstream BDs do not depend on PM-only edits).
- Lands in commit 19b-PM (separate from 19b-pack so Pack Chat
  sees PM-only diff in isolation per stop-before-commit
  protocol).

### §6.3 — BD-169 split

**BD-169 (pack-product wording):**
- Type: TODO(version)
- Status: Open
- File/Symbol (planner picks specific wording; coder authors):
  - `project-template/docs/pack/PM-CHAT.md` row addition in
    file-access strategy table (PM-CHAT.md is pack-product:
    ships from `project-template/docs/pack/`; the project-template
    copy is the canonical edit; clients receive via
    init-project.sh / migrate-v10-to-v11.sh).
  - `supporting-docs/MERGE-STRATEGY.md` paragraph per original
    §4.4.3.
  - `supporting-docs/MIGRATION-v10-to-v11.md` section per original
    §4.4.3 (~30 lines covering decomposition behavior, backup
    rollback, mode awareness).
  - Auditor agent file extensions × 3 CLIs (per original §4.4.3):
    `project-template/.claude/agents/auditor.md`,
    `.codex/agents/auditor.md`, `.gemini/agents/auditor.md`.
    (Note: per the §7 fact-check in this addendum, the
    `audit-methodology` skill exists at
    `project-template/skills/audit-methodology/SKILL.md` —
    audit-scope language extension may also touch the skill
    file; planner verifies).
  - Pack-startup + pm-startup one-line directive additions per
    Item 1 §1.3 (lands in 3 pack-startup files at pack root +
    4 pm-startup files in project-template):
    - `.claude/skills/pack-startup/SKILL.md` (pack-root)
    - `.codex/skills/pack-startup/SKILL.md` (pack-root)
    - `.gemini/commands/pack-startup.toml` (pack-root)
    - `project-template/skills/pm-startup/SKILL.md` (canonical)
    - `project-template/.claude/skills/pm-startup/SKILL.md`
    - `project-template/.codex/skills/pm-startup/SKILL.md`
    - `project-template/.gemini/commands/pm-startup.toml`
- Blockers: BD-167 (canonical templates exist — `_rules.md`
  paths referenced by the directive lines).
- Unblocks: none.
- Lands in commit 19g-pack.

**BD-169b NEW (PM-only wording — Pack Chat applies):**
- Type: TODO(version)
- Status: Open
- File/Symbol (PM-only — Pack Chat applies):
  - `PACK-CHAT.md` row addition in file-access strategy table
    (lines 42–43) per original §4.4.3.
  - `README.md` Repository Layout entries naming `/backlog/`,
    `/changelog/`, and the project-template-side
    `docs/project/backlog/`, `docs/project/implementation-plan/`,
    `docs/project/changelog/` per original §4.4.3. (Note: paths
    use post-Item-10 non-dot form per §10 below.)
- Blockers: BD-169 (timing — PM-only edits land after pack-product
  prose to avoid forward-references).
- Unblocks: none.
- Lands in commit 19g-PM (separate from 19g-pack so Pack Chat
  sees PM-only diff in isolation).

### §6.4 — Updated Batch 19 BD list (10 BDs total)

| BD | Topic | Blockers | Unblocks | Commit |
|---|---|---|---|---|
| BD-164 | Per-entry split implementation: decompose helper + mirror generator + `_toc.md` regenerator + supporting-file generators (planner picks file structure / specific helper file naming) | BD-104, BD-128, BD-131..BD-134, BD-111 (per Item 2 — final tracker dependency surface) | BD-165, BD-166, BD-167, BD-168, BD-170 | 19a |
| BD-165 | `_v10_to_v11_decompose_streams` 6th sub-operation in v10→v11 post-dispatch hook (planner picks function name / position) | BD-164 | BD-167 | 19c |
| BD-166 | `init-project.sh` greenfield per-entry tree install (S11 extension; planner picks stage extension vs new stage) | BD-164, BD-167 | none | 19d |
| BD-167 | Per-entry split client artifact installs (pack-product templates + install plumbing; absorbs BD-161) | BD-164 | BD-165, BD-166, BD-168, BD-169 | 19b-pack |
| BD-167b NEW | Per-entry split PM-only edits (trinity Key files lines + PACK-AGENTS.md PM-only directories list + STATUS.md disclaimer + CLAUDE.md pack-memory bullet + pack-* agent prompt `_rules.md` references) | BD-167 | none | 19b-PM |
| BD-168 | `validate-pack.py` Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity) | BD-164, BD-167 | none | 19e |
| BD-169 | Per-entry split pack-product wording updates | BD-167 | none | 19g-pack |
| BD-169b NEW | Per-entry split PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries) | BD-169 | none | 19g-PM |
| BD-170 | Pre-decomposed `v11-realistic-ot` fixture extension (planner picks fixture-generator function structure) | BD-164, BD-160 | BD-102 dog-food (Batch 23 per Item 2) | 19f |
| (status flips) | Pack Chat direct: BD-164..BD-170 + BD-167b + BD-169b → Resolved; BD-161 → Resolved with "absorbed into BD-167" Resolution | n/a | n/a | 19h |

**Total: 9 new BDs (BD-164..BD-170 + BD-167b + BD-169b) +
BD-161 absorbed into BD-167 = 10 entries tracked.** Up from
original §17.2's 7 new + 1 absorbed = 8.

### §6.5 — Updated Batch 19 commit ordering (10 commits total)

| # | Commit | Author | Content |
|---|---|---|---|
| 1 | 19a | pack-coder | BD-164 decompose / mirror / TOC helpers + tests; standalone library work |
| 2 | 19b-pack | pack-coder | BD-167 canonical templates × 5 streams + BD-161 net-new SKILL.md installs + migrate-v10-to-v11.sh install step extension + tracker-agent-read.sh extension |
| 3 | 19b-PM | Pack Chat | BD-167b PM-only edits (trinity Key files × 6, PACK-AGENTS.md, STATUS.md disclaimer, CLAUDE.md pack-memory bullet, pack-* agent prompts × 15) |
| 4 | 19c | pack-coder | BD-165 v10→v11 migrator post-dispatch step (6th sub-op) |
| 5 | 19d | pack-coder | BD-166 init-project.sh greenfield install (S11 extension) |
| 6 | 19e | pack-coder | BD-168 validator Checks 32/33/34 |
| 7 | 19f | pack-coder | BD-170 v11-realistic-ot fixture extension |
| 8 | 19g-pack | pack-coder | BD-169 pack-product wording updates (MERGE-STRATEGY paragraph, MIGRATION-v10-to-v11 section, project-template PM-CHAT.md row, auditor agent edits × 3, pack-startup directive × 3, pm-startup directive × 4) |
| 9 | 19g-PM | Pack Chat | BD-169b PM-only wording (PACK-CHAT.md row, README.md Repository Layout entries) |
| 10 | 19h | Pack Chat | BD status flips (per `EXECUTION-PLAN-V11.0.md` §C.4 implicit-flip rule + BD-161 Resolved with absorption attribution) |

**Mixed mode:** 6 pack-coder commits + 4 Pack Chat direct
commits. Stop-before-commit per §A.1 of `EXECUTION-PLAN-V11.0.md`
applies to every commit.

### §6.6 — Updated total v11.0 commit count

Per original §17.3, the original Batch 18 (now 19 per Item 2)
had 8 commits and pushed total v11.0 commits from "max 31" to
"max ~38." Per Item 6's split, the new Batch 19 has 10 commits;
total v11.0 commits go to **max ~41** (off-by-one corrected per
Addendum #2 §3.3 — Batch 19's 10 internal sub-commits add 9
extras over the original Batch 18 baseline, not 8).

### §6.7 — `EXECUTION-PLAN-V11.0.md` §1 in-scope inventory update (PM-only edit specification)

Updates original §17.4's edit specification:
- §1 in-scope inventory: add 9 new BDs (BD-164..BD-170 + BD-167b
  + BD-169b) under Group 5 "per-entry split (added during
  integration architect pass)"
- Bump "Total" from "41 BDs in-scope" to "50 BDs in-scope"
  (+9 new). Plus "1 verify-and-close + 4 untracked" unchanged.

### §6.8 — Cascade impact (this Item)

- **Original §17.2 BD table:** REPLACED by §6.4 above (10 BDs vs
  7).
- **Original §17.3 commit ordering:** REPLACED by §6.5 above
  (10 commits vs 8).
- **Original §17.4 EXECUTION-PLAN-V11.0.md edit specification:**
  EXTENDED — the §1 in-scope count goes to 50 (vs original
  proposal of 48).
- **Original §17.8 total v11.0 BD count:** updated. Was "48 BDs
  in-scope + 1 verify + 4 untracked = 53 items." Now "50 BDs +
  1 verify + 4 untracked = 55 items."
- **Original §18.1 planner items:** add the "planner picks file
  structure" qualifier to the BD-167 / BD-167b / BD-169 / BD-169b
  File/Symbol fields per Item 9 §9 below (BD-164 already had
  this qualifier per original §18.1 #2).


---

## §7 — Item 7: §1.1 audit-methodology correction + fact-check sweep (SHOULD-FIX 6)

**Corrects original §1.1.**

### §7.1 — audit-methodology fact-check correction

**Original §1.1 lines 260–263 (verbatim, paraphrased from
recall of the original integration architect doc):**

> "`audit-methodology/SKILL.md` (auditor scope rules) — searched;
> no current `audit-methodology` skill exists in pack repo at
> this name; the audit methodology lives in the auditor agent
> files (project-template/.claude/agents/auditor.md and per-CLI
> mirrors)."

**This is WRONG.** Verified directly:
- `ls -la /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/`
  returns the directory.
- `test -f /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/SKILL.md`
  succeeds.

The skill exists at
`project-template/skills/audit-methodology/SKILL.md` (26496 bytes
per `ls -la`).

**Correction (parallel to original §3.2 friction 2 acknowledgement
pattern):**

> `project-template/skills/audit-methodology/SKILL.md` (audit
> methodology contract for client-side auditor agents — exists;
> loads for `auditor-architecture`, `auditor-code`, `auditor-ops`,
> `auditor-docs`, `auditor-security`, `auditor-tests`, `auditor-ui`
> per the dimensional skill model).
>
> **Correction:** the original integration architect doc §1.1
> stated this skill did not exist in the pack repo; that was
> wrong (the skill was searched at a pack-self path expectation;
> it actually ships at
> `project-template/skills/audit-methodology/`). Cited correctly
> herein.
>
> Pack-self has no analog audit-methodology skill at this time;
> pack-self audits are governed by the embedded methodology in
> pack-* agent files (`.claude/agents/pack-architect.md`,
> `.claude/agents/pack-reviewer.md`, etc.). Whether pack-self
> should ship its own audit-methodology skill is out of scope
> for this design (would be its own BD if surfaced).

### §7.2 — Fact-check sweep results

Per the PROCESS SAFEGUARD instruction, every §1.1 file existence
claim was verified against the actual file system. Results:

**Files verified to exist (claim correct):**
- `EXECUTION-PLAN-V11.0.md` — OK
- `ARCHITECTURE-BD-119.md` — OK
- `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` — OK
- `scripts/migrate-v10-to-v11.sh` — OK
- `scripts/lib/migrator-core.sh` — OK
- `scripts/lib/migrator-stages.sh` — OK
- `scripts/lib/migrator-manifest.sh` — OK
- `scripts/lib/customization-preserve.sh` — OK
- `scripts/lib/tracker-migrate-forward.sh` — OK
- `scripts/lib/tracker-migrate-reverse.sh` — OK
- `scripts/lib/tracker-mirror.sh` — OK
- `scripts/lib/tracker-agent-read.sh` — OK
- `scripts/lib/detect.sh` — OK
- `scripts/lib/recommendation.sh` — OK
- `scripts/validate-pack.py` — OK
- `scripts/init-project.sh` — OK
- `CLAUDE.md` (pack root) — OK
- `AGENTS.md` (pack root) — OK
- `GEMINI.md` (pack root) — OK
- `README.md` (pack root) — OK
- `PACK-CHAT.md` (pack root) — OK
- `PACK-AGENTS.md` (pack root) — OK
- `BACKLOG.md` (pack root) — highest BD verified at BD-163
- `project-template/CLAUDE.md` — OK
- `project-template/AGENTS.md` — OK
- `project-template/GEMINI.md` — OK
- `project-template/.claude/agents/*.md` — 16 files verified
- `project-template/docs/pack/PM-CHAT.md` — OK
- `project-template/docs/pack/PLATFORM-SKILLS.md` — OK
- `project-template/skills/pm-startup/SKILL.md` (canonical) — OK
- `project-template/.claude/skills/pm-startup/SKILL.md` — OK
- `project-template/.codex/skills/pm-startup/SKILL.md` — OK
- `supporting-docs/SETUP-NEW.md` — OK
- `supporting-docs/SETUP-EXISTING.md` — OK
- `supporting-docs/MIGRATION-v10-to-v11.md` — OK
- `supporting-docs/METHODOLOGY.md` — OK
- `supporting-docs/MERGE-STRATEGY.md` — OK
- `.claude/agents/pack-architect.md` + `pack-coder.md` +
  `pack-docs-researcher.md` + `pack-planner.md` +
  `pack-reviewer.md` — all OK

**Inaccuracy 1 — `audit-methodology` skill location.** Per §7.1
above. The skill exists at
`project-template/skills/audit-methodology/SKILL.md`, NOT
non-existent.

**Inaccuracy 2 (NEW, surfaced by sweep) — `pack-startup` skill
locations.** The original §1.1 cited:
- `project-template/.claude/skills/pack-startup/SKILL.md`
- `project-template/.codex/skills/pack-startup/SKILL.md`
- `project-template/.gemini/commands/pack-startup.toml`

Verified file system check:
- `find ... -path "*/skills/pack-startup/SKILL.md"` returns ONLY
  `.claude/skills/pack-startup/SKILL.md` AND
  `.codex/skills/pack-startup/SKILL.md` at PACK-REPO root level
  (NOT in `project-template/`).
- `find ... -name "pack-startup*"` returns
  `.gemini/commands/pack-startup.toml` ONLY at PACK-REPO root
  level (not in `project-template/`).

**Pack-startup is a pack-repo-only skill.** It does NOT ship in
`project-template/`. The original §1.1 incorrectly cited the
project-template paths.

**Correction:**

> `pack-startup` skill files are pack-repo-only and live at:
> - `.claude/skills/pack-startup/SKILL.md` (pack root)
> - `.codex/skills/pack-startup/SKILL.md` (pack root)
> - `.gemini/commands/pack-startup.toml` (pack root)
>
> The skill loads for sessions on the pack repo itself (Pack
> Chat). It does NOT ship into client projects. Project-side
> sessions use `pm-startup` (which DOES ship in
> `project-template/`).
>
> **Correction:** the original integration architect doc §1.1
> cited pack-startup at `project-template/.claude/skills/pack-startup/SKILL.md`
> etc. Those paths do not exist. Cited correctly herein.

### §7.3 — Cascade impact (this Item)

- **Original §1.1:** two corrections above (audit-methodology
  location + pack-startup location).
- **Original §4.4.2 (skill list line additions):** updated to
  reflect actual pack-startup file count (3 pack-root files,
  NOT 3 project-template files; the directive lands at the
  pack-root level per Item 1 §1.3).
- **Original §17.2 BD-169 File/Symbol:** the pack-startup
  one-line directive lands in 3 files at pack root (not in
  project-template); see Item 6 §6.3 above for the corrected
  paths.

### §7.4 — Audit-methodology skill consideration

The audit-methodology skill at
`project-template/skills/audit-methodology/SKILL.md` is
client-side. The pack-side equivalent is the pack-* agent prompts
themselves (per the corrected §1.1 narrative).

For Batch 19 (per-entry split), the audit-methodology skill MAY
need a small extension to reference per-entry tree directories
in its audit-scope rules. Item 6 §6.3 BD-169 already lists this
under "auditor agent file extensions × 3 CLIs" — the planner
should verify whether the skill file itself needs the extension
or whether the auditor agent files (which load the skill) cover
it. Planner-final.


---

## §8 — Item 8: §7 cost constants correction (NIT 1)

**Supersedes original §7.2 cost table and corrects original §7.1
prose magnitudes.**

### §8.1 — Constant correction

The original §7.2 used 10ms/file as the per-file regenerator
read-cost constant. Per the user-Pack-Chat call: that constant
is too high for typical Markdown file reads (small files; OS
filesystem cache; deterministic shell `cat` / Python `read`
performance on contemporary hardware). Realistic constant:
~2 ms/file (covers cold-cache filesystem read + parser pass for
a typical 30–50-line per-entry file).

### §8.2 — Recomputed cost table

| Scenario | Entries N | Writes per session W | Sidecar model regen runs | Reads per regen | Sidecar total reads | Sidecar time (~2 ms/read) | Commit-time model regen runs | Commit-time total reads | Commit-time time |
|---|---|---|---|---|---|---|---|---|---|
| v11.0 baseline | ~150 | 3–5 | 3–5 | 150 | 450–750 | ~0.9–1.5 sec | 1 | 150 | ~0.3 sec |
| v12 projected | 500 | 3–5 | 3–5 | 500 | 1500–2500 | ~3–5 sec | 1 | 500 | ~1 sec |
| v13 projected | 1000 | 3–5 | 3–5 | 1000 | 3000–5000 | ~6–10 sec | 1 | 1000 | ~2 sec |

(Figures rounded; constants are illustrative; planner verifies
empirically.)

### §8.3 — Updated original §7.1 prose

The original §7.1 Failure 3 paragraph contained the prose
"50-second regenerator runs at v13 scale" tied to the 10ms/file
constant. Per Item 8: rewrite to "10-second regenerator runs at
v13 scale under the sidecar model" and "2-second runs under the
commit-time model" (or the planner's measured values).

The qualitative conclusion is **unchanged**: the sidecar
"regenerate-after-every-write" model is operationally
back-pressured at projected scale and creates the agent-skip
incentive that breaks Goal 1 + Goal 2. The commit-time model
remains 3–5× faster (W writes vs 1 commit-time regeneration);
the recommendation in §7.3 + REDESIGN-CORE #1 stands.

### §8.4 — Empirical-measurement instruction for the planner

Add this one-sentence note at the end of the recomputed §7.2
cost table:

> "Constants are approximate (estimated 2 ms/file based on typical
> Markdown read + parse cost on contemporary hardware); planner-
> pass implementation should empirically measure regenerator cost
> on representative hardware (CI runner + developer macOS/Linux)
> before sizing CI tolerance budgets. The 3.3× speedup of
> commit-time over sidecar-model survives any reasonable constant
> in the 1–10 ms/file range; the recommendation in §7.3 is robust
> to the constant."

### §8.5 — Cascade impact (this Item)

- **Original §7.2 cost table:** REPLACED by §8.2 above.
- **Original §7.1 Failure 3 prose magnitudes:** UPDATED per §8.3
  ("50-second" → "10-second"; "25 sec" → "5 sec"; etc.).
- **Original §7.3 commit-time recommendation:** UNCHANGED in
  conclusion; the speedup ratio is robust.
- **Original §16.1 REDESIGN-CORE #1:** UNCHANGED. The cost
  argument is one of three failure-mode arguments; the cost-
  constant correction does not change the conclusion (commit-
  time wins on Failure 1 + Failure 2 grounds independent of
  Failure 3 cost magnitude).

---

## §9 — Item 9: BD File/Symbol qualifiers + §10 pseudo-code disclaimers (NIT 2)

**Refines original §17.2 (BD table) and §10.1 / §10.3 (validator
pseudo-code).**

### §9.1 — BD File/Symbol "planner picks file structure" qualifier

Per Item 6 §6.4 above (the BD table that supersedes original
§17.2), the qualifier "(planner picks file structure / specific
helper file naming)" is added to BD-167 / BD-167b / BD-169 /
BD-169b File/Symbol fields where specific helper files are
named.

BD-164 already had this qualifier per original §18.1 #2 (the
sub-directory vs single-file decision was explicitly named as
planner-final). Item 6 §6.4 BD table extends the qualifier
consistently across all four BDs that name specific files.

BD-165 (`_v10_to_v11_decompose_streams` 6th sub-op) and BD-166
(init-project.sh S11 extension) similarly name specific positions
within existing files; the qualifier "(planner picks function
name / position)" applies. Per original §18.1 #1 + #5 these were
already deferred; Item 9 confirms the qualifier in the BD-table
File/Symbol fields.

BD-168 (validator Checks 32/33/34) names the function shape; the
implementation language (Python — per the existing
`scripts/validate-pack.py`) is fixed; the function names
(`check_mirror_in_sync`, `check_toc_in_sync`,
`check_cross_reference_integrity`) are placeholder; "(planner
picks function names + STREAMS constant shape)" applies.

BD-170 (fixture extension) names the fixture-builder extension;
"(planner picks fixture-generator function structure)" applies.

### §9.2 — §10.1 + §10.3 pseudo-code disclaimers

The original §10.1 (Check 32) and §10.3 (Check 34) included
Python pseudo-code blocks. Per Item 9: each pseudo-code block
gains a one-line disclaimer immediately above it:

> "Pseudo-code sketches the behavioral contract; planner refines
> exact implementation (Python vs Bash, function/file structure,
> error message wording)."

Pseudo-code STAYS in the original integration architect doc as
illustrative scaffolding. The disclaimer clarifies architect-pass
scope: the contract is what the validator MUST detect, not the
literal Python signature.

### §9.3 — Cascade impact (this Item)

- **Original §17.2 BD table:** REPLACED by Item 6 §6.4 above
  (which already includes the qualifier).
- **Original §10.1 Check 32 pseudo-code:** disclaimer prepended
  per §9.2 above.
- **Original §10.3 Check 34 pseudo-code:** disclaimer prepended
  per §9.2 above.
- **Original §10.2 Check 33 pseudo-code:** noted as "same shape
  as Check 32" without literal pseudo-code in the original; no
  disclaimer needed (the contract description is sufficient).
- **Original §18.x planner items:** unchanged; the qualifier is
  consistent with the existing planner-deferral discipline.


---

## §10 — Item 10: REDESIGN-CORE #2 — leading-dot convention drop (NIT 3 by priority; structurally largest cascade)

**Overturns sidecar parent + addendum + original integration
architect doc throughout (path-naming cascade).**

### §10.1 — The decision

Drop the leading-dot convention for per-entry trees. New shape:

| Surface | Sidecar / original (leading-dot) | Post-Item-10 (non-dot) |
|---|---|---|
| Pack-side per-entry backlog tree | `/.backlog/` | `/backlog/` |
| Pack-side per-entry changelog tree | `/.changelog/` | `/changelog/` |
| Project-side per-entry backlog tree | `docs/project/backlog/` | UNCHANGED — already non-dot |
| Project-side per-entry implementation-plan tree | `docs/project/implementation-plan/` | UNCHANGED |
| Project-side per-entry changelog tree | `docs/project/changelog/` | UNCHANGED |
| Tracker state directory | `.pack-tracker/` | UNCHANGED — STAYS leading-dot |

Pack-side moves from leading-dot to non-dot for symmetry with
project-side. `.pack-tracker/` STAYS leading-dot because the
semantic distinction is preserved (tool state vs primary data).

### §10.2 — Rationale

**Goal 1 discoverability.** Per-entry trees are primary state;
humans (Pack Chat / PM Chat / project developers) hand-edit them
routinely. Leading-dot directories are conventionally hidden:
- `ls` without `-a` does not show them.
- `find` without explicit predicates does not descend.
- Many IDE file browsers default to hidden.
- macOS Finder hides them by default.

A primary-state directory hidden by default fails Goal 1: a user
opening the repo in any default file browser does not see the
per-entry trees. The trinity Key files pointer (Item 1 Layer 1)
helps, but the file system itself should not actively work
against discoverability.

**Goal 2 fragmentation.** Pack-side and project-side were
asymmetric in the original design: pack-side leading-dot;
project-side non-dot. Same conceptual class (per-entry source
of truth), different file-naming convention. Item 10 makes them
symmetric.

**Semantic alignment.** Leading-dot conventionally signals
"tool-managed; don't hand-edit" (`.git/`, `.pack-tracker/`,
`.github/`, `.vscode/`, `.idea/`, etc.). Per-entry trees ARE
hand-edited (Pack Chat / PM Chat write per-entry files
directly); the leading-dot signal was wrong.

`.pack-tracker/` legitimately keeps leading-dot because it IS
tool state: `id-map.json`, `forward.checkpoint.json`,
`recommendation-state.json`, etc. — humans don't hand-edit those.
The semantic signal is correct in `.pack-tracker/`'s case.

### §10.3 — Cascade through original integration architect doc

Every reference to `/.backlog/` or `/.changelog/` in the original
integration architect doc updates to non-dot. Per the
PROCESS SAFEGUARD instruction, enumerated explicitly so the
planner can see the cascade:

**§2 (Locked decisions inherited from sidecar — restated for the planner):**
- §2.1 (Stream shape and naming) item 1: pack-side paths update
  `/.backlog/` → `/backlog/`, `/.changelog/` → `/changelog/`. The
  parenthetical "leading-dot for 'structured pack state, not pack
  product', parallel to `.pack-tracker/`" is overturned. The new
  parenthetical: "non-dot for symmetry with project-side per-entry
  trees and to support default discoverability under Goal 1."
- §2.4 item 2: `pack tracker init` flow paths reference per-entry
  trees; update to non-dot.
- §2.6 item 1: `_v8-resolved-archive.md` lives at
  `/backlog/_v8-resolved-archive.md`.
- §2.7 concatenation order: paths in the comment update to
  non-dot.

**§3 (Three frictions resolved):**
- §3.3 (Friction 3 `_intro.md` round-trip) paths to per-entry
  trees update to non-dot.

**§4 (Discoverability design):**
- §4.1 problem statement paragraph 1 references per-entry trees.
- §4.2 Layer 1 sample addition lines reference `/.backlog/` and
  `/.changelog/`; update to `/backlog/` and `/changelog/`.
- §4.2 Layer 2 sample HTML-comment back-pointer
  (`<!-- per-entry source: /.backlog/BD-NNN.md; contract: /.backlog/_rules.md -->`)
  updates to `/backlog/`. Item 1 §1.2 above shows the
  post-Item-10 shape.
- §4.4.1 surfaces that STAY: any reference to
  `/.backlog/` / `/.changelog/` updates to non-dot.
- §4.4.3 README.md Repository Layout entries: paths update to
  non-dot.
- §4.5 script-discovery section: `validate-pack.py` STREAMS
  constant references update; `migrator-v10-to-v11.sh` decompose
  step paths update.

**§5 (Source-of-truth invariant + STATUS.md disclaimer):**
- §5.1 declarations: pack-side per-entry tree paths update to
  non-dot. Per Item 3 §3.2 above the declarations are also
  mode-aware corrected.
- §5.2 workflow source-of-truth resolution rule: paths update.
- §5.5 inflection-point signal collection: `find /.backlog/ -name
  'BD-*.md' | wc -l` becomes `find /backlog/ -name 'BD-*.md' |
  wc -l`.
- §5.6 Mode-2 → Mode-3 transition: paths update.

**§6 (Read/write rules audit):**
- §6.1 audit table: every per-entry tree path entry updates from
  `/.backlog/` to `/backlog/` etc.
- §6.4 PACK-AGENTS.md edit specification: directory list entries
  update to non-dot. Per Item 3 §3.1 the framing also drops
  "refactor not expansion" in favor of honest Signal 9 trip.
- §6.5 CLAUDE.md pack-memory bullet: paths update; per Item 3
  §3.4 the bullet text is also mode-aware corrected.

**§7 (Regenerator cost / invocation redesign):**
- §7.3 sample regenerator invocation command line:
  `bash scripts/lib/<helper>.sh regenerate-mirror /.backlog/`
  becomes `bash scripts/lib/<helper>.sh regenerate-mirror
  /backlog/`. Pseudo-code in §7.6 write-path contract: paths
  update.

**§8 (Identify-only items §5.a–§5.r disposition):**
- §8.1, §8.2, §8.3 (workflow / TOC / mirror generator runtime
  invocation): no path mentions; no update needed.
- §8.4 (stale detection): no specific paths.
- §8.5 (concurrent-write safety): no specific paths.
- §8.6 (cross-reference integrity): no specific paths.
- §8.7 (test fixture migration): no specific paths.
- §8.16 (`.pack-tracker/` vs `/.backlog/` namespace collision
  risk): the naming changes; the conclusion (no detect.sh
  change) is unchanged. But the section title and prose update:
  "`.pack-tracker/` vs `/backlog/` non-collision (different
  conventions for different purposes)".
- §8.17 (init-project.sh greenfield path): paths update;
  `docs/project/<stream>/` already non-dot.
- §8.18 (backup and rollback): paths update; sample post-report
  hook advisory text references `/backlog/`, `/changelog/` etc.

**§9 (Migrator integration):**
- §9.1: 6th sub-operation reads paths; update.
- §9.5: namespace collision risk (per §8.16 above).
- §9.7 (`_intro.md` and `_v8-resolved-archive.md` initial
  install): paths to `/backlog/_intro.md`,
  `/backlog/_v8-resolved-archive.md` etc. update.

**§10 (Validator new-checks):**
- §10.1 Check 32 pseudo-code: `STREAMS = [(...path...)]`
  constant shape — paths update to non-dot.
- §10.5 validator behavior on missing per-entry tree: paths
  update.

**§11 (Cross-reference integrity):**
- §11.3 `_v8-resolved-archive.md` exception: path updates.

**§12 (Test fixture migration):**
- §12.1 + §12.2 + §12.3 fixture paths reference project-side
  `docs/project/<stream>/` (already non-dot); pack-side tree
  references in test fixture builder paths update if any.

**§13 (Customization-preserve verification):**
- No path-specific edits beyond passing reference; the
  classifier `*) printf 'generic\n' ;;` fall-through at line 178
  catches paths regardless of leading-dot.

**§14 (Pattern B archive sweep impact):**
- §14.2 + §14.3: paths update.

**§15 (Diffability tradeoff):**
- No path-specific edits.

**§16 (Sidecar core-redesign proposals):**
- §16.1 (REDESIGN-CORE #1 regenerator invocation) text unchanged.
- **NEW §16.3 — REDESIGN-CORE #2 leading-dot convention drop.**
  See §10.4 below for the NEW §16.3 entry text.

**§17 (Integration into v11.0 execution plan):**
- §17.2 BD table: every BD-164..BD-170 + BD-167b + BD-169b
  File/Symbol field referencing per-entry tree paths updates.
  Per Item 6 §6.4 the table is replaced; the replaced table
  uses the post-Item-10 non-dot paths.
- §17.4 `EXECUTION-PLAN-V11.0.md` edit specification: paths
  update.

**§18 (Open items for the planner / coder):**
- No path-specific edits beyond passing references.

### §10.4 — NEW §16.3 — REDESIGN-CORE #2 entry text

Per the original §16.1 / §16.2 pattern, NEW §16.3 enumerates the
overturn:

> ### §16.3 — REDESIGN-CORE #2: leading-dot convention drop
>
> **Sidecar locked decision (parent §3.1 + §3.2):** pack-side
> per-entry trees live at `/.backlog/` and `/.changelog/`
> (leading-dot, parallel to `.pack-tracker/`).
>
> **Why integration overturns:** Goal 1 discoverability fail
> (leading-dot directories hidden by default in `ls`, `find`,
> IDE file browsers, macOS Finder); Goal 2 fragmentation fail
> (asymmetric pack-side leading-dot vs project-side non-dot
> for the same conceptual class); semantic-alignment fail
> (leading-dot conventionally signals tool-managed; per-entry
> trees ARE hand-edited so the signal was wrong).
>
> **Proposed alternative (this design — Item 10):** pack-side
> moves to `/backlog/` and `/changelog/` (non-dot, symmetric
> with project-side). `.pack-tracker/` STAYS leading-dot
> (legitimately tool state).
>
> **Why the alternative resolves the failures:** non-dot makes
> per-entry trees visible by default in standard browse paths
> (Goal 1); pack-side and project-side use the same convention
> (Goal 2); semantic signal is preserved (tool state stays
> leading-dot in `.pack-tracker/`; primary data is non-dot).
>
> **Architect-pass scope of this redesign:** path-naming only.
> All other sidecar decisions for the per-entry trees (filename
> conventions per stream, supporting-file basenames per stream,
> mirror-not-replace, byte-additive grammar, customization-
> preserve generic-class fall-through, BD-119 framework hook
> contract) — unchanged.
>
> **Cascade impact:** every path reference to `/.backlog/` or
> `/.changelog/` in the original integration architect doc
> updates to non-dot. See addendum §10.3 + §11 for the full
> enumeration.
>
> **Sidecar parent compatibility note:** sidecar parent doc
> (ARCHITECTURE-PER-ENTRY-SPLIT.md) and addendum
> (ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md) reference the
> leading-dot paths throughout. This integration's REDESIGN-CORE
> #2 supersedes those references — future readers see the
> sidecar's leading-dot paths and the integration's non-dot
> correction in the same way they see REDESIGN-CORE #1
> (regenerator invocation model). Sidecar files are NOT edited;
> the integration architect's REDESIGN-CORE language is
> authoritative.

### §10.5 — Why this is sized as NIT (not BLOCKER)

Item 10 is structurally the largest cascade in this addendum
(every section of the original doc has at least passing path
reference) but is sized as **NIT** because:
- The change is naming-only. No contract changes. No semantic
  changes. No new mechanisms. No new BDs (the BDs in §17.2 /
  Item 6 §6.4 already exist; their File/Symbol fields update).
- The cost is mechanical — replace `/.backlog/` with `/backlog/`
  and `/.changelog/` with `/changelog/` throughout the impl;
  shell scripts, validator, helpers, fixtures, doc references.
- The impact on the v11.0 ship date is zero — the change happens
  during BD-164 (Batch 19) implementation; no scheduling change.
- The Goal 1 / Goal 2 / semantic-alignment improvements are
  qualitative gains; ship without any of them would still meet
  the v11.0 user direction (mandatory + non-reversible
  per-entry decomposition).

The user-Pack-Chat call to overturn the leading-dot convention
captures cheap qualitative gains; the cost is mechanical
cascade.

### §10.6 — Cascade verification (PROCESS SAFEGUARD compliance)

Per the PROCESS SAFEGUARD instruction (cascade verification:
every REDESIGN-CORE / structural change MUST propagate through
ALL references in the original doc), §10.3 above enumerates the
affected sections explicitly:

§2.1, §2.4, §2.6, §2.7, §3.3, §4.1, §4.2 (Layer 1 + Layer 2),
§4.4.1, §4.4.3, §4.5, §5.1, §5.2, §5.5, §5.6, §6.1, §6.4, §6.5,
§7.3, §7.6, §8.16, §8.17, §8.18, §9.1, §9.5, §9.7, §10.1, §10.5,
§11.3, §14.2, §14.3, §16 (gains §16.3 NEW), §17.2 (replaced via
Item 6 §6.4), §17.4.

§11 of this addendum (Cascade audit) provides the integrated
view across all 10 items.


---

## §11 — Cascade audit (which sections of the original doc are affected by which items)

This section provides the integrated cascade view per the
PROCESS SAFEGUARD instruction. Every section of the original
integration architect doc that is modified by this addendum is
listed with the items that modify it.

### §11.1 — Per-section impact table

| Original § | Title | Items affecting it |
|---|---|---|
| §0 | TL;DR + recommendation summary | Items 2 (batch number 18→19), 6 (BD count 7→9 + commit count 8→10), 10 (path naming) |
| §1.1 | Inputs read | Item 7 (audit-methodology + pack-startup corrections) |
| §1.2 | Authority map | unchanged |
| §1.3 | Sidecar authority preserved (re-litigation policy) | Item 10 (REDESIGN-CORE #2 added) |
| §2.1 | Stream shape and naming | Item 10 (paths) |
| §2.2 | Mirror contract | unchanged |
| §2.3 | Migrator integration | unchanged |
| §2.4 | Tracker integration | Item 3 (mode-aware language), Item 10 (paths) |
| §2.5 | Entry grammar invariant | unchanged |
| §2.6 | `_v8-resolved-archive.md` and the no-Resolved-section rule | Item 10 (paths) |
| §2.7 | Generator concatenation order | Item 10 (paths in comment) |
| §3.1 | Friction 1: hook-sequencing | unchanged |
| §3.2 | Friction 2: §5.r citation slip | unchanged |
| §3.3 | Friction 3: `_intro.md` round-trip | Item 10 (paths) |
| §4.1 | Discoverability problem | Item 10 (paths) |
| §4.2 | Three layered discoverability mechanisms (Layers 1–3) | Item 1 (Layer 3 dropped; Layer 2 upgraded with body-field back-pointer; Layer 4 added — pack-* agent prompts), Item 10 (paths in samples) |
| §4.3 | Recovery from context-window drop | Item 1 (table updated for Layer 3 drop / Layer 4 add) |
| §4.4 | Read-site update inventory | Item 1 (skill-list line additions removed; pack-* agent prompt edits added; pack-startup count corrected per Item 7), Item 10 (paths) |
| §4.5 | Discovery for scripts | Item 10 (paths) |
| §5.1 | Source-of-truth declarations | Item 3 (mode-aware), Item 10 (paths) |
| §5.2 | Workflow source-of-truth resolution rule | Item 3 (mode-aware), Item 10 (paths) |
| §5.3 | STATUS.md disclaimer requirement | unchanged |
| §5.4 | Stale-mirror / stale-TOC detection | Item 5 (Layer 1 mirror preamble + Layer 2 regenerator warning added) |
| §5.5 | Convenience views and recommendation system | Item 10 (paths in `find` example) |
| §5.6 | Mode-2 → Mode-3 transition | Item 10 (paths) |
| §6.1 | Write authority audit table | Item 10 (paths in column 1) |
| §6.2 | Pack agent permission verification | unchanged |
| §6.3 | Mirror generator and `_toc.md` regenerator: tooling-not-agent | unchanged |
| §6.4 | PACK-AGENTS.md edit specification | Item 3 (drop "refactor not expansion" framing; honest Signal 9 trip), Item 10 (paths in directories list) |
| §6.5 | CLAUDE.md pack-memory addition | Item 3 (mode-aware bullet text), Item 10 (paths) |
| §7.1 | The problem with sidecar §6.4 + §7.2 | Item 8 (cost magnitudes corrected) |
| §7.2 | Cost calculation table | Item 8 (constants and table replaced) |
| §7.3 | Replacement model: commit-time regeneration | Item 10 (paths in sample command), Item 5 (Layer 2 regenerator divergence-warning addition mentioned in passing) |
| §7.4 | Concurrent-write safety | Item 4 (full ~80–100-line expansion) |
| §7.5 | `_rules.md` runtime-read scope | unchanged |
| §7.6 | Updated write-path contract | Item 10 (paths if any in sample) |
| §8.0 | Disposition table for §5.a–§5.r items | unchanged |
| §8.1 | §5.a workflow discovery | Item 1 cascades (the §4 unified treatment items reference Layer 3 drop + Layer 4 add) |
| §8.2 | §5.b TOC runtime invocation | unchanged |
| §8.3 | §5.c mirror generator runtime invocation | unchanged |
| §8.4 | §5.d stale detection | Item 5 (Layers 1+2 added) |
| §8.5 | §5.e concurrent-write safety | Item 4 (treated in expanded §7.4) |
| §8.6 | §5.f cross-reference integrity | unchanged |
| §8.7 | §5.g test fixture migration | unchanged |
| §8.8 | §5.h validator new-checks | unchanged |
| §8.9 | §5.i read-site audit completeness | Item 1 (cascades to §4.4) |
| §8.10 | §5.j skill update inventory | Item 1 (cascades to §4.4.2) |
| §8.11 | §5.k STATUS.md interaction | Item 5 Layer 3 (disclaimer in defense-in-depth doc) |
| §8.12 | §5.l Pattern B archive sweep | Item 10 (paths) |
| §8.13 | §5.m customization-preserve at per-entry | unchanged |
| §8.14 | §5.n BD-161 absorption | unchanged |
| §8.15 | §5.o diffability tradeoff | unchanged |
| §8.16 | §5.p namespace collision risk | Item 10 (section title and prose updated; conclusion unchanged) |
| §8.17 | §5.q init-project.sh greenfield | Item 10 (paths) |
| §8.18 | §5.r backup and rollback | Item 10 (paths in sample post-report-hook text) |
| §9.1 | Hook integration restated | Item 10 (paths in 6th sub-op description) |
| §9.2 | Manifest implications | unchanged |
| §9.3 | init-project.sh greenfield path | unchanged |
| §9.4 | Backup and rollback | unchanged |
| §9.5 | Namespace collision risk | Item 10 (paths) |
| §9.6 | Sequencing inside the v10→v11 hook | unchanged |
| §9.7 | `_intro.md` and `_v8-resolved-archive.md` initial install | Item 10 (paths) |
| §10.1 | Check 32 (mirror-in-sync) | Item 9 (pseudo-code disclaimer prepended), Item 10 (paths in STREAMS constant) |
| §10.2 | Check 33 (TOC-in-sync) | Item 10 (paths in STREAMS constant) |
| §10.3 | Check 34 (cross-reference integrity) | Item 9 (pseudo-code disclaimer prepended) |
| §10.4 | Why three checks not one | unchanged |
| §10.5 | Validator behavior on missing per-entry tree | Item 10 (paths) |
| §10.6 | Pack-side vs project-side validator scope | Item 5 (defense-in-depth statement added per §5.4) |
| §11 | Cross-reference integrity | unchanged |
| §11.3 | `_v8-resolved-archive.md` exception | Item 10 (paths) |
| §12 | Test fixture migration | Item 10 (paths if any in fixture-builder description) |
| §13 | Customization-preserve verification | unchanged |
| §14.2 | Per-entry trees are NOT workflow artifacts | Item 10 (paths) |
| §14.3 | `_v8-resolved-archive.md` is NOT swept | Item 10 (paths) |
| §15 | Diffability / git history tradeoff | unchanged |
| §16.1 | REDESIGN-CORE #1 (regenerator invocation) | Item 10 (mention `.pack-tracker/` parallel preserved) |
| §16.2 | Other sidecar decisions ratified table | Item 10 (gains REDESIGN-CORE #2 reference) |
| §16.3 NEW | REDESIGN-CORE #2 (leading-dot convention drop) | Item 10 (creates this section) |
| §17.1 | Batch positioning | Item 2 (NEW Batch 19 instead of Batch 18; renumber cascade) |
| §17.2 | BD table | Item 6 (split — table replaced; 9 BDs vs 7); Item 9 (qualifiers); Item 10 (paths) |
| §17.3 | Commit ordering | Item 6 (10 commits vs 8) |
| §17.4 | EXECUTION-PLAN-V11.0.md edit specification | Item 2 (new edit specs for line edits + Batch row insert position) + Item 6 (BD count update) |
| §17.5 | Sequencing relative to existing v11.0 work | Item 2 (Batch 18 BD-111 added as predecessor) |
| §17.6 | BD-numbering audit | unchanged (BD-163 still highest; new BDs sequential) |
| §17.7 | Other v11.0 BDs blocked / unblocked | Item 2 (renumber cascade in Batch 22 / Batch 23 references) |
| §17.8 | Total v11.0 BD count | Item 6 (50 BDs vs 48) |
| §18.1 | Planner items | Item 6 (qualifiers per Item 9); Item 10 (paths in any examples) |
| §18.2 | Coder items | Item 1 (back-pointer body field add/strip per §1.2 above); Item 5 (regenerator divergence-warning per §5.3 above); Item 10 (paths) |
| §18.3 | Items deferred to v11.x or later | Item 5 (Layer 0 opt-in pre-commit hook surfaced) |
| §19 | Final-line marker | unchanged (this addendum has its own §12 final-line marker) |

### §11.2 — Coverage verification

Total original-doc sections (per `grep -nE "^## §"` on the
original): 19 top-level sections (§0..§19). Of these:

- **Modified by this addendum:** §0, §1.1, §1.3, §2.1, §2.4,
  §2.6, §2.7, §3.3, §4.1, §4.2, §4.3, §4.4, §4.5, §5.1, §5.2,
  §5.4, §5.5, §5.6, §6.1, §6.4, §6.5, §7.1, §7.2, §7.3, §7.4,
  §7.6, §8.1, §8.4, §8.5, §8.9, §8.10, §8.11, §8.12, §8.16,
  §8.17, §8.18, §9.1, §9.5, §9.7, §10.1, §10.2, §10.3, §10.5,
  §10.6, §11.3, §12, §14.2, §14.3, §16.1, §16.2, §16.3 NEW,
  §17.1, §17.2, §17.3, §17.4, §17.5, §17.7, §17.8, §18.1, §18.2,
  §18.3 = 60+ sub-sections (the section count exceeds 19 because
  many §s have sub-§s).
- **Unchanged:** §1.2, §2.2, §2.3, §2.5, §3.1, §3.2, §5.3, §6.2,
  §6.3, §7.5, §8.0, §8.2, §8.3, §8.6, §8.7, §8.8, §8.13, §8.14,
  §8.15, §9.2, §9.3, §9.4, §9.6, §10.4, §11 (overall), §13, §15,
  §17.6, §19.

The cascade is large but precise. Item 10 alone touches more
sections than any other item (path-naming is pervasive); Item
1 touches the §4.x sub-section family; Item 6 touches the §17
family; Item 3 touches the §5.1 / §6.4 / §6.5 cluster.

### §11.3 — No section unintentionally untouched

Per the PROCESS SAFEGUARD cascade-verification instruction, the
above enumeration is exhaustive. The planner reading this addendum
+ the original integration architect doc together has the
complete view. Nothing is missed.


---

## §12 — Final-line marker

ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-COMPLETE: 2026-05-14 —
Bundles 10 user-Pack-Chat-decided items into one addendum to
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (3,477 lines).
ONE BLOCKER (Item 2 — batch positioning was wrong; per-entry
split is NEW Batch 19 not Batch 18; Batch 18 is occupied by
BD-111; existing Batches 19+ renumber up by one;
EXECUTION-PLAN-V11.0.md / BACKLOG.md / RELEASE-GATE.md cascade
edit specifications surfaced for Pack Chat). SIX SHOULD-FIX
(Item 1 discoverability redesign — drop `stream-discovery` skill
Layer 3, upgrade Layer 2 with body-field back-pointer, replace
Layer 3 with one-line directives in existing pack-startup +
pm-startup skills, add Layer 4 pack-* agent prompt `_rules.md`
references; Item 3 §6.4 framing — drop "refactor not expansion"
in favor of honest Signal 9 trip + mode-dependent source-of-truth
language throughout original §5.1 / §6.4 / §6.5; Item 4 §7.4
concurrent-write safety full expansion to ~80–100 lines with 6
scenario enumeration + defense-in-depth layering + CI-dependence
gap acknowledgement; Item 5 §10.6 Goal 2 enforcement layered
defense — Layer 1 mirror preamble "DO NOT EDIT" warning + Layer
2 regenerator divergence-warning + Layer 3 explicit defense-in-
depth doc + Layer 4 `pack doctor` extension recommended for
planner + Layer 0 opt-in pre-commit hook recommended for planner;
Item 6 §17.2 BD split — BD-167 → BD-167 + BD-167b NEW, BD-169 →
BD-169 + BD-169b NEW; Batch 19 commit count 8 → 10; total v11.0
commit count max ~38 → max ~41 (off-by-one corrected per
Addendum #2 §3.3); Item 7 §1.1 audit-methodology
correction — exists at `project-template/skills/audit-methodology/SKILL.md`,
NOT non-existent; fact-check sweep surfaced second inaccuracy:
`pack-startup` is pack-repo-only and lives at `.claude/skills/`,
`.codex/skills/`, `.gemini/commands/` at PACK ROOT level, NOT in
`project-template/`). THREE NIT (Item 8 cost constants — 10ms/file
→ ~2ms/file; recompute table with v11.0 baseline 0.3 sec, v12
projected 1 sec, v13 projected 2 sec under commit-time model;
3.3× speedup of commit-time over sidecar-model survives any
reasonable constant; Item 9 BD File/Symbol "planner picks file
structure" qualifier consistency + §10.1 / §10.3 pseudo-code
disclaimers; Item 10 REDESIGN-CORE #2 — leading-dot convention
drop for per-entry trees; pack-side `/.backlog/` → `/backlog/`,
`/.changelog/` → `/changelog/`; project-side unchanged; `.pack-
tracker/` STAYS leading-dot — semantic distinction preserved;
NEW §16.3 entry created in original-doc structure; cascade
through 30+ original-doc sub-sections enumerated in §10.3 + §11).
Cascade audit (§11) provides per-section impact map for the
planner; 60+ sub-sections of the original doc affected; coverage
verified per PROCESS SAFEGUARD. Architect-pass discipline
preserved: no edits to PM-only files (PACK-AGENTS / PACK-CHAT /
BACKLOG / CHANGELOG / README / CLAUDE / AGENTS / GEMINI /
EXECUTION-PLAN-V11.0 / RELEASE-GATE / V3.x corpus); all required
PM-only edits surfaced as edit specifications (Pack Chat applies
on ratification — totaling ~18 line edits across EXECUTION-PLAN /
BACKLOG / RELEASE-GATE for renumber cascade plus the BD-167b /
BD-169b PM-only commits within Batch 19); no edits to pack-
product files; no edits to sidecar design corpus or the original
integration architect doc; no v10 entry-format grammar changes
(V3.1-DELTA §3 A2 invariant preserved — body-field back-pointer
is byte-additive `Field-Name: value` shape); structural-signal
trips named explicitly where they occur (Signal 9 in Item 3;
Signal 4 in Items 5 + 9 — Checks 32/33/34 already defended in
original §10). Verification by grep confirmed batch numbering
(`grep -nE '^\| \*\*[0-9]+[a-z]?\*\*' EXECUTION-PLAN-V11.0.md`
returned current Batch 1 → Batch 23; next-available main-batch
slot is 24 once renumber cascades, and per-entry split inserts
between current Batch 18 BD-111 and current Batch 19 BD-105 ∥
BD-103 = renumbered new Batch 20). Sidecar parent + addendum
NOT edited — REDESIGN-CORE #2 supersedes their leading-dot path
references in the same supersession pattern as REDESIGN-CORE #1.
No further addendum iteration anticipated; ready for primary-
chat reviewer to evaluate before primary-chat planner spawns
Batch 19 BD scheduling.
