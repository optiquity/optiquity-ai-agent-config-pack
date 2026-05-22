# AUDIT — Pre-19C boundary-leak scan

**Date:** 2026-05-21
**Branch:** v11-dev
**HEAD at scan time:** 9da98a44d9b7c2236f8dacd8632bca6e9b662963
**Author:** Audit agent (read-only static scan)
**Scope:** Production client-install surface (project-template/ + the
five files in `supporting-docs/` + `pack-ops/` + `scripts/` copied to
clients by `scripts/init-project.sh`) PLUS the Batch 19c WIP planning
docs in `maintenance-docs/v11-implementation/`.

---

## §0 — Methodology + scan vocabulary

### 0.1 Reference vocabulary scanned

The scan flagged every occurrence of:

- **File / path refs:** `pack-ops/`, `PACK-CHAT`, `PACK-AGENTS`,
  `maintenance-docs`, `PACK-MEMORY`, pack-root bare `BACKLOG.md`,
  pack-root bare `CHANGELOG.md`, `ARCHITECTURE-*` (pack-internal
  design docs), `BOUNDARY-DEFINITION`, `MERGE-STRATEGY`, `DRY-RUN-
  MIGRATION`, `CONCEPTUAL-REVIEW`, `HELP-FRAGMENT-PACK`,
  `AUDIT-USER-CURATION`, `OPTIONAL-FEATURES` (bare; project-side has
  its own copy), `supporting-docs/<X>.md` (where `<X>` is NOT
  installed by init-project.sh)
- **Pack agent names:** `pack-architect`, `pack-coder`, `pack-reviewer`,
  `pack-planner`, `pack-docs-researcher`
- **Pack skill / role names:** `pack-startup`, `Pack Chat` (capitalized
  orchestrator role), `Pack Manager`, `pack-root trinity`, `pack
  memory`, `Tier 1.5`, `PM-only`, `pack-only`, `project-only`
- **BD / TD numbering:** Any specific `BD-NNN` / `TD-NNN` numeric ref
  (pack BD-NNN vs project BD-NNN/TD-NNN namespaces differ)

### 0.2 Classification scheme

- **CONFIRMED LEAK** — pack-internal reference present in a project-
  side surface that should not be there; will not resolve at client
  install or pollutes project design.
- **AMBIGUOUS** — could be legitimate or a leak; needs human judgment.
- **LEGITIMATE PACK-AS-PRODUCT REF** — reference to the pack as a
  shipped product or to a cross-boundary product feature (e.g.,
  PACK-FEEDBACK loop, "this file was installed by the pack") that is
  appropriate at client install.

### 0.3 Client-install enumeration from `scripts/init-project.sh`

Files copied to client installs OUTSIDE `project-template/` (derived
from grep of all `cp` operations in `scripts/init-project.sh`):

| Pack source | Client destination | init-project.sh line |
|---|---|---|
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | `docs/pack/HELP-FRAGMENT-TRACKER.md` | 823-825 |
| `supporting-docs/METHODOLOGY.md` | `docs/pack/METHODOLOGY.md` | 565-572 (also S6 generic table 1188) |
| `supporting-docs/INSTALL-PROCEDURES.md` | `docs/pack/INSTALL-PROCEDURES.md` | 576-583 (also S6 generic table 1189) |
| `scripts/pack-help.sh` | `scripts/pack-help.sh` | 890-892 |
| `scripts/lib/detect.sh` | `scripts/lib/detect.sh` | 894-895 |

Note 1: `project-template/` content is mass-copied by stages S1-S11.
All 99 markdown files under `project-template/` are in scope of §1.

Note 2: `supporting-docs/CLI-PM-SETUP.md`, `supporting-docs/SETUP-
NEW.md`, `supporting-docs/SETUP_TEMPLATE.md`, `supporting-docs/
AGENT_KICKOFF_TEMPLATE.md`, `supporting-docs/MIGRATION-v10-to-v11.md`
are NOT copied — they are pre-install reference content. References
to these from project-template files would not resolve at client
install (CONFIRMED LEAK class).

Note 3: `pack-ops/HELP-FRAGMENT-TRACKER.md` is byte-identical to
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per CI Check 24
contract. The pack-ops/ source is technically a mirror; the canonical
text is the project-template/ copy.

---

## §1 — `project-template/` findings

**Scan coverage:** all 99 markdown files under `project-template/`
plus the trinity at the project-template root, agent files under
`.claude/`, `.codex/`, `.gemini/`, and configs. Scan executed via
recursive `grep -rnE` against the full vocabulary in §0.1.

### 1.1 Trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)

**§1.1.a — Pack-as-deny-list references (lines 385-392 CLAUDE.md,
362-369 AGENTS.md, 381-388 GEMINI.md)**

Quoted (CLAUDE.md, parallel in AGENTS/GEMINI):

> ... Files at the pack repo (PACK-AGENTS.md, PACK-CHAT.md, pack-\*
> agent prompts, pack-repo `maintenance-docs/`, pack-repo `pack-ops/`
> — any file under `pack-ops/`, including BOUNDARY-DEFINITION.md,
> BACKLOG.md, CHANGELOG.md, etc.) are NOT part of the project SSOT
> and must not be referenced from project files — the pack repo is
> not present at this client install. See the `boundary-investigation`
> skill for the SSOT-investigation methodology.

**Classification: LEGITIMATE (deny-list framing).** The references are
EXPLICITLY presented as the pack-only deny-list with "must not be
referenced" framing. The pack file names appear in the trinity AS
the names a client agent must NOT introduce. The framing is
intentional and survives BD-175 review.

**§1.1.b — `boundary-investigation` skill cross-reference (CLAUDE.md
line 196 + 391, AGENTS.md 180 + 368, GEMINI.md 192 + 387)**

Trinity points clients at `boundary-investigation` skill. The skill
itself is in `project-template/skills/boundary-investigation/SKILL.md`
and is mass-copied to clients by S4.

**Classification: LEGITIMATE.** The skill ships to clients; the
cross-reference resolves at client install.

**§1.1.c — BD-142 numeric ref (CLAUDE.md 195, AGENTS.md 179,
GEMINI.md 191)**

> project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()`

**Classification: AMBIGUOUS.** BD-142 is the pack-development BD that
established the skill-mass-copy convention. The reference contextualizes
WHY the convention exists, but a client team has no way to look up
"BD-142" — it lives only in `pack-ops/BACKLOG.md` (not at client). The
parallel `scripts/init-project.sh` reference IS a script that lives at
client install. The BD-NNN is informational provenance; argument for
LEGITIMATE is "harmless provenance"; argument for CONFIRMED LEAK is "no
client-side way to follow the reference, so it adds noise." Human call.

**§1.1.d — "Pack/PM Chat" capitalized refs (CLAUDE.md 222, AGENTS.md
206, GEMINI.md 218)**

> (read-only mirror; edit via Pack/PM Chat).

**Classification: AMBIGUOUS.** "PM Chat" (capitalized) is the project-
side orchestrator role. "Pack Chat" is the pack-side orchestrator
role. The slash form "Pack/PM Chat" implies "either Pack Chat (when
editing the pack itself) or PM Chat (when editing a project)." The PM
Chat resolution at client install is unambiguous; the Pack Chat
reference is meaningless at a client install (the client team is not
the pack-repo team). Either the trinity should say "PM Chat" alone
(client view) or clarify "Pack Chat" applies only when reading this
file at the pack-repo source.

### 1.2 `project-template/docs/pack/PM-CHAT.md`

**§1.2.a — Mid-text Pack Chat references**

| Line | Quoted text | Classification |
|---|---|---|
| 225-227 | "batches to the Pack Chat only at workflow-complete boundaries (never mid-phase) ... the Pack Chat decides what to do with them." | LEGITIMATE (PACK-FEEDBACK loop product feature) |
| 401-402 | "docs/pack/MERGE-STRATEGY.md (or pack-ops/MERGE-STRATEGY.md in the pack repo)." | AMBIGUOUS — names `docs/pack/MERGE-STRATEGY.md` as the client-side path but `docs/pack/MERGE-STRATEGY.md` is NOT copied by init-project.sh (see §1.5). Cross-ref to pack-ops form is qualified ("in the pack repo") but the client-side path that would resolve does not exist. |
| 349 | "PM-only files (BACKLOG.md, CHANGELOG.md, STATUS.md, PACK-FEEDBACK.md, root .md files) in the Files-in-scope list" | AMBIGUOUS — uses pack-internal "PM-only" terminology. At a client install the phrase reads as "files only the PM chat may edit" which IS the project-side meaning of PM-only — but the term itself is identical to the pack-internal scope keyword. |
| 410 | "ARCHITECTURE-V3.3-DELTA.md §3.1:" | **CONFIRMED LEAK** — `ARCHITECTURE-V3.3-DELTA.md` lives at `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`; pack-internal; not at client install. |

### 1.3 `project-template/docs/pack/PACK-FEEDBACK.md`

**Pack Chat references (lines 13, 42, 58, 87, 98, 104, 106, 112, 122,
143, 150, 151, 152, 172, 294, 312, 336, 357, 377, 394, 419, 446, 448):**

**Classification (ALL): LEGITIMATE.** `PACK-FEEDBACK.md` is the
deliberately-designed cross-boundary product feature — the upstream
feedback channel from a client project's PM chat to the pack-repo
Pack Chat. The HTML comment header at the top explicitly frames the
file as "the upstream feedback channel from the PM chat running this
project to the Pack Chat maintaining the pack." These references are
load-bearing and intentional.

### 1.4 `project-template/docs/pack/OPTIONAL-FEATURES.md`

**Line 174:** "See `MERGE-STRATEGY.md` in the pack repo for the per-
file class matrix and sidecar conventions."

**Classification: AMBIGUOUS.** Reference is qualified ("in the pack
repo") which signals the file is pack-internal — but no client-side
alternative is named, leaving a client reader with a dead-end cite.
At minimum the wording should add "(not installed at this project)"
to avoid creating an expectation of local resolution. Borderline-leak.

### 1.5 `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`

**Line 49:** "See the tracker example template (`tracker.toml.pack-
example` in the pack repo, or `tracker.toml.example` at a client
project root) and `OPTIONAL-FEATURES.md` for full setup."

**Classification: LEGITIMATE.** The reference contrasts pack-only
`tracker.toml.pack-example` (at pack repo) with client-installed
`tracker.toml.example`. The qualification "in the pack repo" plus the
contrasting "at a client project root" makes the cite resolvable on
both sides.

### 1.6 `project-template/docs/pack/HELP-FRAGMENT.md`

Reads as a project-side help fragment. Lines 5, 26, 31 reference
client-side `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-
FEATURES.md`, `docs/pack/PLATFORM-SKILLS.md`, `HELP-FRAGMENT-
TRACKER.md`. All resolve at client install.

**Classification: LEGITIMATE.**

### 1.7 `project-template/skills/boundary-investigation/SKILL.md`

This SKILL.md is the heaviest-referencing single project-template
file. It is mass-copied by S4 to `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` — so it WILL appear at client install.

| Line | Quoted text | Classification |
|---|---|---|
| 17-20 | "It does NOT apply to changes scoped entirely to pack-only files: pack-repo root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at repo root), `pack-ops/` (any file there), `maintenance-docs/`, `scripts/`, `test-fixtures/`, or the pack-repo `.claude/` / `.codex/` / `.gemini/` dotted dirs at the pack repo root." | LEGITIMATE (deny-list / scope-limit framing) |
| 25-27 | "The pack repo maintains its own operating rules (Pack Chat, pack-architect / pack-coder / etc. agent roster, `pack-ops/` operational docs, `maintenance-docs/` design records)." | AMBIGUOUS — at client install, "Pack Chat / pack-architect / pack-coder" are not actors a client team interacts with; the explanation is FOR a client agent ("understand why this skill applies"). Argument for LEGITIMATE: documenting WHY the project-vs-pack distinction matters requires naming pack-side artifacts. Argument for CONFIRMED LEAK: client agents now carry detailed knowledge of pack-internal mechanism vocabulary they cannot act on. |
| 32-35 | "The audit BD-175 (P-missed-7) documented the regression mechanism..." | AMBIGUOUS — pack BD-NNN ref. BD-175 lives in `pack-ops/BACKLOG.md` (not at client). P-missed-7 is pack-memory terminology. Provenance-only or noise. |
| 86-87 | "Surface to Pack Chat (or the PM chat at a client install) for re-design." | LEGITIMATE — explicitly addresses both audiences in parallel. |
| 99-114 | Full deny-list enumeration with `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, all `pack-ops/*` files, `maintenance-docs/`, `scripts/`, `test-fixtures/` | LEGITIMATE (this IS the deny-list, by design) |
| 115-118 | "Agent names: `pack-architect`, `pack-coder`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` (the five pack-\* agents..." | LEGITIMATE (named-as-forbidden) |
| 119-122 | "Role names: `Pack Chat` (capitalized as the pack-repo orchestrator role; lower-case 'pack chat' describing the feedback flow in `PACK-FEEDBACK.md` / `PM-CHAT.md` / `METHODOLOGY.md` / `SETUP-EXISTING.md` is LEGITIMATE per audit §D-4)" | AMBIGUOUS — explanatory cross-ref to BD-175 / Batch-19b audit `§D-4` (lives in `maintenance-docs/`); the disposition statement is correct, but the audit cite is pack-internal. |
| 124 | "STAYS at pack root per AUDIT-USER-CURATION.md Override 1" | **CONFIRMED LEAK** — `AUDIT-USER-CURATION.md` lives at `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`; pack-internal; not at client install. |
| 138-141 | "(a) the proposed edit, (b) the pack-only target, (c) the project-side SSOT to use instead, (d) a request for re-prompting from the orchestrator with the corrected reference." | LEGITIMATE (instructional, generic) |
| 150-154 | "(`CLAUDE.md` at pack root / `pack-ops/PACK-AGENTS.md` / `maintenance-docs/`)" then "(`docs/pack/PM-CHAT.md` / `docs/pack/PLATFORM-SKILLS.md` / project trinity)" | LEGITIMATE (deliberate pack-vs-project side-by-side contrast) |
| 161-186 | Worked example block with `PACK-AGENTS.md` deny-list match + "STOP and redirect to the project-side SSOT" | LEGITIMATE (worked anti-pattern; the deny-list match is the point) |

**Net §1.7 disposition:** The SKILL.md heavily references pack-internal
vocabulary, but the references are STRUCTURALLY the skill's purpose
(deny-list documentation). The one clear leak is `AUDIT-USER-
CURATION.md` (line 124). The "Pack Chat (or PM chat at a client
install)" treatment in line 86-87 is the gold-standard pattern that
should be applied to the other ambiguous mentions if the user
wants tighter cleanup.

### 1.8 Other project-template/skills/ files

| File | Line | Quoted text | Classification |
|---|---|---|---|
| `python-data-architecture/SKILL.md` | 27-28 | "split in v11.0 by BD-141 (the `python_data_marker_detected()` load predicate) and BD-143 (the trinity SKILL.md split into..." | AMBIGUOUS (BD-NNN provenance; same call as §1.1.c) |
| `python-observability-patterns/SKILL.md` | 20 | "(see `docs/pack/PLATFORM-SKILLS.md` Intersection table; BD-162)." | AMBIGUOUS (BD provenance) |
| `python-server-architecture/SKILL.md` | 16-17 | "split in v11.0 by BD-141 ... BD-143 ..." | AMBIGUOUS (BD provenance) |
| `swift-best-practices/SKILL.md` | 92 | "*(AsyncStream payload design — relocated to `swift-concurrency-patterns` as part of the BD-158 split.)*" | AMBIGUOUS (BD provenance) |
| `audit-methodology/SKILL.md` | 77 | "The monolithic `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`, and `CHANGELOG.md` files are regenerated mirrors" | LEGITIMATE (refers to client-side project files) |

### 1.9 `.claude/agents/` + `.codex/agents/` + `.gemini/agents/`

These are project-side agent definitions (architect/coder/reviewer/
etc.), mass-copied by S2. References to "PM-only file edits" appear in
`coder` (Claude line 80, Gemini line 79, Codex toml 48) and `repo-ops`
(Claude line 69, Gemini line 66, Codex toml 39).

**Classification: AMBIGUOUS.** "PM-only" terminology is identical
between pack-internal scope keyword AND the project-side meaning ("only
the PM chat may edit"). The lists enumerate `BACKLOG.md, CHANGELOG.md,
STATUS.md, PACK-FEEDBACK.md, or any .md file at the project root" —
all of which are CLIENT-SIDE files. The phrase "PM-only" reads
naturally at client install as "PM-chat-only" and resolves correctly.
Borderline-legitimate.

### 1.10 `.claude/skills/pm-startup/SKILL.md`, `.codex/skills/pm-
startup/SKILL.md`, `.gemini/commands/pm-startup.toml`, plus the
canonical `project-template/skills/pm-startup/SKILL.md`

All four reference `ARCHITECTURE-V3.md §28.1.5` (lines 255-260 for
.gemini, 258-260 for .claude, parallel for .codex). The Claude+Codex
skills are mass-copied by S4 to client `.claude/skills/` and
`.codex/skills/`; the gemini command goes to `.gemini/commands/`
per S11 (lines 867-882 of init).

**Classification: CONFIRMED LEAK.** `ARCHITECTURE-V3.md` lives at
`maintenance-docs/v11-research/ARCHITECTURE-V3.md`; pack-internal; not
at client install. A client `/pm-startup` invocation would carry a
stale cross-reference no client agent could resolve.

Same files also reference `supporting-docs/METHODOLOGY.md into
docs/pack/` (line 171 .gemini, 174 .claude, 174 .codex). This is the
SOURCE path used by `init-project.sh` to COPY into client `docs/pack/
METHODOLOGY.md`. The reference is contextualized as "the install copy
step that creates it" — a pre-install reference.

**Classification (METHODOLOGY.md source path): AMBIGUOUS.** The
reference resolves only at pack-repo source, not at client install,
but the surrounding text frames it as "the install step that creates
[the client copy]" — so it reads as documentation, not as a live
cross-ref. Borderline-legitimate.

### 1.11 `project-template/docs/pack/PLATFORM-SKILLS.md`

| Line | Quoted | Classification |
|---|---|---|
| 195, 429 | "boundary-investigation" rows | LEGITIMATE (project-side skill) |
| 222 | "see BD-141)" | AMBIGUOUS (BD provenance) |
| 223 | "see BD-156)" | AMBIGUOUS (BD provenance) |
| 224 | "see BD-162)" | AMBIGUOUS (BD provenance) |
| 225 | "see BD-157)" | AMBIGUOUS (BD provenance) |
| 240, 496 | `pm-startup` skill entries | LEGITIMATE (project-side) |
| 249 | "Those skills live in the pack repo's own `.claude/skills/`," | LEGITIMATE (the surrounding text contrasts pack-side skills with project-side; pack-as-product ref) |
| 582 | "enforcement migration is tracked under BD-155." | AMBIGUOUS (BD provenance) |
| 599-601 | "v11.0 additions: ... (BD-156 ... BD-157 ... BD-158)" | AMBIGUOUS (BD provenance) |

### 1.12 `project-template/docs/pack/prompts/coder.md`

| Line | Quoted | Classification |
|---|---|---|
| 70 | "**Boundary discipline (Project SSOT-first / P-missed-7):**" | AMBIGUOUS — P-missed-7 is pack-memory ID. Provenance only. |
| 83-89 | "the AI Agent Config Pack repo's `PACK-AGENTS.md`, `PACK-CHAT.md`, anything under the pack repo's `pack-ops/` or `maintenance-docs/`, a pack-\* agent name, the `Pack Chat` capitalized orchestrator role), STOP and report" | LEGITIMATE (deny-list framing, parallel to trinity §1.1.a) |
| 195-202 | Same deny-list re-stated for fix-cycle variant | LEGITIMATE (deny-list framing) |

### 1.13 `project-template/docs/pack/prompts/reviewer.md`

| Line | Quoted | Classification |
|---|---|---|
| 102-107 | "pack-repo file like `PACK-AGENTS.md`, `PACK-CHAT.md`, anything under `pack-ops/`, anything under the pack-repo `maintenance-docs/`, a pack-\* agent name, or the `Pack Chat` capitalized orchestrator role)" | LEGITIMATE (deny-list framing) |

### 1.14 `project-template/docs/pack/prompts/pm-chat.md`

| Line | Quoted | Classification |
|---|---|---|
| 94-96 | "I will point you at `supporting-docs/SETUP-NEW.md` § Manual fallback (sub-sections 5.A–5.D)" | **CONFIRMED LEAK** — `supporting-docs/SETUP-NEW.md` is NOT copied by init-project.sh; client has no file at that path. |
| 182-189 | "*PM chat fills this in using SETUP_TEMPLATE.md from the pack.*" + "**Required reading:** `supporting-docs/SETUP_TEMPLATE.md` from the AI Agent Config Pack" | **CONFIRMED LEAK** — `supporting-docs/SETUP_TEMPLATE.md` is NOT copied; client cannot read it. Note "from the AI Agent Config Pack" qualification surfaces the issue but does not resolve it: a client PM chat invoking this variant has nowhere to read the template. |
| 227-234 | "*PM chat fills this in using AGENT_KICKOFF_TEMPLATE.md from the pack.*" + "**Required reading:** `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`" | **CONFIRMED LEAK** — `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` NOT copied. |

### 1.15 `project-template/.mcp.json.example`

Line 9: "See supporting-docs/CLI-PM-SETUP.md for setup instructions."

**Classification: CONFIRMED LEAK** — `supporting-docs/CLI-PM-SETUP.md`
is NOT copied to clients. Pre-install reference only valid when
reading the pack repo directly.

### 1.16 `project-template/README.md`

Line 13: "cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/
your-project/docs/pack/METHODOLOGY.md"

**Classification: LEGITIMATE.** This README is the pack-repo README
copied to clients as `project-template/README.md` — its purpose
includes documenting installation, and the example command shows
what init-project.sh does internally.

Lines 38, 44: References to `supporting-docs/`.

**Classification: AMBIGUOUS** — same as above; pre-install reference
in installation documentation.

### 1.17 `project-template/.codex/config.toml`

Line 20: "and `.gemini/.env` AGENT_CAPABILITIES per the BD-059
trinity rule for..."

**Classification: AMBIGUOUS** (BD provenance, comment in config).

### 1.18 `project-template/.gitignore`

Line 7: "─── Tracker-mode local state (BD-061) ─────"

**Classification: AMBIGUOUS** (BD provenance in comment).

### 1.19 `project-template/docs/project/backlog/_rules.md`, `_intro.md`,
`implementation-plan/_rules.md`, `_intro.md`, `changelog/_rules.md`,
`_intro.md`, `_format.md`

These per-entry-tree skeleton files ship to clients and contain
EXTENSIVE references to pack-internal `ARCHITECTURE-PER-ENTRY-SPLIT.md`,
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`, `ARCHITECTURE-PER-ENTRY-
SPLIT-INTEGRATION-ADDENDUM.md`, `ARCHITECTURE-PER-ENTRY-SPLIT-
INTEGRATION-ADDENDUM-2.md`, `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-
V3.3-DELTA.md`. All of these live in `maintenance-docs/v11-research/`
and `maintenance-docs/v11-implementation/`; none ship to clients.

Specific lines (24 total occurrences across 7 files):

| File | Lines |
|---|---|
| `docs/project/backlog/_rules.md` | 5, 16, 21, 23, 25, 33, 36, 45 |
| `docs/project/backlog/_intro.md` | 32, 37, 51 |
| `docs/project/implementation-plan/_rules.md` | 5, 18, 23, 28, 29, 33, 45 |
| `docs/project/implementation-plan/_intro.md` | 42, 59 |
| `docs/project/changelog/_rules.md` | 5, 19, 30, 45, 48 |
| `docs/project/changelog/_intro.md` | 53 |
| `docs/project/changelog/_format.md` | 5, 7, 50, 56 |

**Classification (ALL 24): CONFIRMED LEAK.** Every reference cites a
pack-internal `maintenance-docs/` ARCHITECTURE doc. Client teams using
the per-entry tree cannot follow any of these cross-references. The
client-side equivalent (what the rule IS, with no cross-ref to the
authoring rationale) should replace these inline.

### 1.20 `project-template/tracker.toml.project-example`

Line 48: '"BD" is reserved for the pack repo; do not use it here.'

**Classification: LEGITIMATE** (correctly identifies the BD-NNN
namespace as pack-only and instructs project teams to use TD-NNN).

### 1.21 `project-template/.github/ISSUE_TEMPLATE/work-item.yml` and
`inbound.yml`

| File | Line | Quoted | Classification |
|---|---|---|---|
| work-item.yml | 2, 18 | "Pack development BDs are filed against the pack repo, not here." / "Pack-development items (BD-NNN) belong in the pack repo, not in this project." | LEGITIMATE (correctly delineates namespace) |
| inbound.yml | 2, 14, 20 | "Pack-feedback subcategories file upstream against the pack repo per V1 §7.5." | AMBIGUOUS — "V1" cite is ambiguous (V1 of what? Project V1, or pack-internal AUDIT-INBOUND-V1?). Pack-as-product ref is legitimate; the section cite is unsourced from a client view. |

### 1.22 §1 — surface summary

- **CONFIRMED LEAK total in `project-template/`:** approximately **34**
  occurrences across **11 files** (notable: 24 `ARCHITECTURE-*`
  references in 7 per-entry-tree skeleton files; 4 `supporting-docs/*`
  references in `prompts/pm-chat.md` + `.mcp.json.example`; 1
  `AUDIT-USER-CURATION.md` ref in `boundary-investigation/SKILL.md`;
  1 `ARCHITECTURE-V3.3-DELTA.md` ref in `PM-CHAT.md` line 410;
  4 `ARCHITECTURE-V3.md` refs across pm-startup variants).
- **AMBIGUOUS:** approximately **30** occurrences (BD-NNN provenance
  refs, "PM-only" terminology usage, "Pack/PM Chat" slash form, mid-
  text "in the pack repo" references that lack a client-side resolved
  cite).
- **LEGITIMATE PACK-AS-PRODUCT REF:** approximately **50** occurrences
  (PACK-FEEDBACK.md cross-boundary product feature, deny-list framing
  in trinity / boundary-investigation SKILL.md / coder.md / reviewer.md,
  README install-doc cites, side-by-side pack-vs-project contrasts).

---

## §2 — `supporting-docs/` + `pack-ops/` + `scripts/` (client-
installed) findings

**Scan coverage:** the five files enumerated in §0.3.

### 2.1 `pack-ops/HELP-FRAGMENT-TRACKER.md`

Scanned with full vocabulary; zero matches against `Pack Chat`,
`pack-architect`, `pack-coder`, `pack-reviewer`, `pack-planner`,
`pack-docs-researcher`, `PACK-CHAT`, `PACK-AGENTS`, `maintenance-docs`,
`PACK-MEMORY`, `pack memory`, `pack-root trinity`, `Tier 1.5`,
`PM-only`, `pack-only`, `project-only`.

**Surface findings: NONE.**

### 2.2 `supporting-docs/METHODOLOGY.md` (5 matches)

| Line | Quoted | Classification |
|---|---|---|
| 119 | "PACK-FEEDBACK.md ... Upstream feedback log to Pack Chat" | LEGITIMATE (PACK-FEEDBACK product feature) |
| 1420 | "The Pack Chat (the upstream maintainer of the pack)" | LEGITIMATE (Part 10 Pack Feedback Loop spec) |
| 1438 | "the Pack Chat seeds open questions in PACK-FEEDBACK.md `## Pack Chat Open Questions`" | LEGITIMATE (Part 10) |
| 1444 | "Review all Pack Chat Open Questions in PACK-FEEDBACK.md." | LEGITIMATE (Part 10) |
| 1446 | "generate the delivery prompt and present it to the user for forwarding to Pack Chat." | LEGITIMATE (Part 10) |

**Surface §2.2 findings:** ZERO leaks; 5 legitimate Pack-Chat
references all bound to the Pack Feedback Loop product feature (Part
10). The file's design intent is to document an upstream-feedback
contract; the Pack Chat references are load-bearing.

### 2.3 `supporting-docs/INSTALL-PROCEDURES.md` (2 matches)

| Line | Quoted | Classification |
|---|---|---|
| 301 | "STOP and surface it to Pack Chat before proceeding." | LEGITIMATE (escalation pattern, parallels Part 10) |
| 609 | "STOP and surface to Pack Chat." | LEGITIMATE (escalation pattern) |

**Surface §2.3 findings:** ZERO leaks; 2 escalation references mirror
the cross-boundary product feature established by Part 10 of
METHODOLOGY.md.

### 2.4 `scripts/pack-help.sh`

Pack-internal vocabulary appears in 13 lines (38, 39, 86, 87, 92,
106, 112-113, 119-120, 133, 136, 153, 169) — ALL referencing
`pack-ops/HELP-FRAGMENT-PACK.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md`,
or "pack-ops/" generically. The script is a fragment-loader that runs
in BOTH the pack-repo context (where `pack-ops/` exists) AND the
client-install context (where it does not).

Inspection shows the script branches on `$root` and tests for both
the pack-repo path (`$root/pack-ops/HELP-FRAGMENT-PACK.md`) AND the
client-side path (`$root/docs/pack/HELP-FRAGMENT-TRACKER.md`). The
pack-ops/ references appear in:

- Comment headers documenting the dual-source design (lines 38-39,
  86-87, 92, 106): **LEGITIMATE** (documentation of dual-context
  behavior).
- Code that checks for `$root/pack-ops/HELP-FRAGMENT-PACK.md` at line
  112-113 / 119-120 / 133 / 136 / 153: **LEGITIMATE** (runtime
  fallback; the path test fails silently at client install where the
  pack-ops/ tree does not exist).
- Error-message text at line 169: "pack-help: expected pack-ops/
  HELP-FRAGMENT-PACK.md (pack repo) or...": **AMBIGUOUS** — a client-
  install error message naming "pack-ops/HELP-FRAGMENT-PACK.md (pack
  repo)" tells a client user about an internal pack-repo file. The
  qualification "(pack repo)" is correct but the surface to a
  client-team end-user is suboptimal. Borderline-legitimate.

**Surface §2.4 findings:** ZERO confirmed leaks. 1 borderline-AMBIGUOUS
error message that names pack-internal paths to client end-users.

### 2.5 `scripts/lib/detect.sh` (2 matches)

| Line | Quoted | Classification |
|---|---|---|
| 335 | "# (maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md):" | **CONFIRMED LEAK** — comment in client-installed script names a pack-internal `maintenance-docs/` file. |
| 678 | "# maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md:" | **CONFIRMED LEAK** — same pattern. |

Both are comments documenting the canonical authority for the
detection rules. A client agent or user inspecting `scripts/lib/
detect.sh` to understand its behavior follows the comment, finds no
file, and is left with an unresolved authority pointer. The
information-hiding tax: a client team has no way to read the source
of truth for the predicate.

**Surface §2.5 findings:** 2 confirmed leaks (comment-only; do not
affect runtime).

### 2.6 §2 — surface summary

- **CONFIRMED LEAK total:** 2 (both in `scripts/lib/detect.sh`
  comments).
- **AMBIGUOUS:** 1 (`scripts/pack-help.sh` line 169 error message).
- **LEGITIMATE PACK-AS-PRODUCT REF:** 7 (5 in METHODOLOGY.md Part 10,
  2 in INSTALL-PROCEDURES.md escalation lines).
- **NONE:** `pack-ops/HELP-FRAGMENT-TRACKER.md` clean.

---

## §3 — Batch 19c WIP planning docs findings

**Scan coverage:** all 4 docs (5,156 lines total).

**Critical framing:** these 4 docs live in `maintenance-docs/v11-
implementation/` — pack-internal location, NOT shipped to clients.
Pack-internal vocabulary INSIDE these docs is INHERENTLY LEGITIMATE
because the docs ARE pack-internal artifacts. What MATTERS is whether
the EDITS THEY PROPOSE TO PROJECT-SIDE FILES would introduce leaks
when applied.

This section therefore focuses on:
1. Proposed text blocks in §C placements that would be inserted into
   project-template files;
2. Architectural decisions in §D that prescribe project-side patterns;
3. Trinity-affecting edits in §C (CLAUDE.md / AGENTS.md / GEMINI.md
   ripples).

### 3.1 `ARCHITECTURE-CLEANUP-BATCH-19C.md` — proposed project-side
edit blocks

For each §C placement, classification of the EXACT proposed text:

#### 3.1.1 — §C.1 (OT-T-1 always-reviewer-after-coder)

- Target file 1: `project-template/docs/pack/PM-CHAT.md` § Behavioral
  rules
- Target file 2: `supporting-docs/METHODOLOGY.md` Part 5 Workflow 2

Proposed text contains no pack-internal vocabulary; references are
project-side ("PM chat," "coder," "reviewer").

**Classification: CLEAN.**

#### 3.1.2 — §C.2 (OT-T-2 architect trigger surface-even-mechanical)

- Target file: `supporting-docs/METHODOLOGY.md` Part 5 Workflow 4

Proposed text contains "PM chat" + "architect pass" — project-side
vocabulary.

**Classification: CLEAN.**

#### 3.1.3 — §C.3 (OT-T-3 BACKLOG-between-phases proactive surfacing)

- Conditional target: `supporting-docs/METHODOLOGY.md` Part 7
  Procedure 1 step 2

Proposed text "PM chat reports newly-unblocked items to the user
proactively at every phase gate." Project-side.

**Classification: CLEAN.**

#### 3.1.4 — §C.4 (OT-T-4 closeout-sequence)

- Target file: `project-template/docs/pack/PM-CHAT.md`

Proposed text uses "PM chat," "reviewer pass," "BACKLOG entry,"
"CHANGELOG entry," "STATUS changes." All project-side.

**Classification: CLEAN.**

#### 3.1.5 — §C.5 (OT-T-5 no-chained-git-add)

- Target: STRENGTHEN existing PM-CHAT.md "Source file edits" bullet

Proposed text uses "PM chat," "BACKLOG.md," "STATUS.md," "git add."
Project-side.

**Classification: CLEAN.**

#### 3.1.6 — §C.6 (OT-T-6 PM-chat-never-edits-source)

- Target file 1: `project-template/docs/pack/PM-CHAT.md`
- Target file 2: Trinity (CLAUDE.md / AGENTS.md / GEMINI.md)

The PM-CHAT.md text uses project-side vocabulary. The trinity
STRENGTHEN adds `git checkout -- <path>` to an existing destructive-
operations list. Both project-side.

**Classification: CLEAN.**

#### 3.1.7 — §C.7 (OT-T-7 re-read per-agent prompt file every time)

- Target file: `project-template/docs/pack/PM-CHAT.md`

Proposed text: "Before generating any agent prompt (coder, reviewer,
architect, planner, tester, auditor, docs-researcher, repo-ops, grpc-
schema, or any custom x-\* agent), re-read the full per-agent prompt
file from `docs/pack/prompts/<agent>.md`."

The agent roster enumerated is the PROJECT-SIDE roster (NOT
`pack-architect / pack-coder / etc.`). The pointer is to client-
side `docs/pack/prompts/<agent>.md`. Project-side.

**Classification: CLEAN.**

#### 3.1.8 — §C.8 (OT-UT-2 pack-repo-is-read-only)

- Target file: `project-template/docs/pack/PM-CHAT.md`

Proposed text:

> "Pack repo is read-only from this project. If a clone of the AI
> Agent Config Pack lives on this machine for reference (e.g., to
> read METHODOLOGY.md, prompts/, supporting-docs/ as upstream source),
> the PM chat MUST NOT modify any file inside that pack clone from
> this project's session. Read for reference only. Pack-side issues
> (rule clarifications, prompt template gaps, documentation errors)
> are recorded in PACK-FEEDBACK.md per METHODOLOGY.md Part 10,
> delivered to Pack Chat at workflow boundaries — never patched into
> the upstream pack from within a project. This rule applies to agent
> sessions spawned from this project as well: scope all agent edits
> to this project's working tree."

References "Pack Chat" in the "delivered to Pack Chat at workflow
boundaries" phrasing — IDENTICAL to existing legitimate Part 10
PACK-FEEDBACK.md cross-boundary product feature.

**Classification: CLEAN** (Pack Chat ref is bound to existing
PACK-FEEDBACK loop; the rule itself is project-side instruction).

#### 3.1.9 — §C.9 (OT-UT-3 mid-pipeline working-tree state)

Project-side vocabulary. **CLEAN.**

#### 3.1.10 — §C.10 (OT-UT-6 architect-output → user-reads)

- Target file 1: `project-template/docs/pack/PM-CHAT.md`
- Target file 2: `supporting-docs/METHODOLOGY.md`

Proposed text uses "PM chat," "architect agent's report," "ARCHITECTURE.md
content." Project-side. The phrase "project-side analog of the pack-
side 'Planner output → user review → coder spawn' rule applied one
step earlier in the pipeline" appears — this WOULD be a pack-internal
ref ("pack-side ... rule") inside a project-side file.

**Classification: AMBIGUOUS / borderline LEAK.** The motivational text
"project-side analog of the pack-side rule" should be rewritten to
remove the pack-side cross-reference; the project-side rule should
stand on its own merits. Pre-19c-revival recommendation: drop the
pack-side cross-ref from this proposed text, OR scope it to the
architect's rationale-only comment block.

#### 3.1.11 — §C.11 (OT-UT-8 open-questions-surface)

Proposed text is project-side. **CLEAN.**

#### 3.1.12 — §C.12 (OT-UT-10 /tmp reports are ephemeral)

Proposed text contains "paste into Pack Chat for upstream debugging."

**Classification: AMBIGUOUS.** "Pack Chat" appears as a generic
audience cite for "upstream debugging." At a client install, "Pack
Chat" is a meaningless audience to a client team — they would paste
to the pack-repo maintainer via PACK-FEEDBACK.md channels, not "Pack
Chat" directly. The phrase should be rewritten to "for upstream
debugging via PACK-FEEDBACK.md" or "for the pack maintainer."

### 3.2 §D architectural decisions

#### 3.2.1 — D.1 per-project Claude memory cache

Proposed PM-CHAT.md text:

> "Claude Code projects may use per-project memory at
> `~/.claude/projects/<slug>/memory/` as a convenience pointer
> index to project rules — **same Tier 1.5 design as the pack repo
> (per pack memory pattern)**. Pure pointers; no body text; trinity /
> PM-CHAT.md / METHODOLOGY.md remain authoritative."

The bolded phrase contains TWO pack-internal references:
- "Tier 1.5 design" — pack-internal pattern terminology
- "pack memory pattern" — pack-internal section name in pack-root
  CLAUDE.md ("## Pack memory")

**Classification: CONFIRMED LEAK in proposed text.** Both
"Tier 1.5" and "pack memory" are pack-internal vocabulary that does
not exist at a client install. The rule can be expressed without
them: "pure pointer files; no body text; trinity / PM-CHAT.md /
METHODOLOGY.md remain authoritative" — drop the cross-reference to
the pack-repo's mirror pattern.

**Action required before revive:** rewrite the proposed text to
remove "Tier 1.5 design" and "pack memory pattern" references.

#### 3.2.2 — D.2 trinity vs PM-CHAT.md surface

Architect recommendation. Doc-internal; not proposed verbatim text.
**CLEAN** as decision-doc content; check final wording when V2
architect lands actual edits.

#### 3.2.3 — D.3 project-side audit/fix-cycle clarification

Doc-internal; no verbatim project-side text proposed. **CLEAN.**

#### 3.2.4 — D.4 project-side mid-phase planner triggers

Architect recommendation for METHODOLOGY.md Workflow 4. Triggers
P-A / P-B / P-C use project-side vocabulary. **CLEAN.**

#### 3.2.5 — D.5 closeout-gating elevation

Proposed METHODOLOGY.md Part 7 Procedure 4 cross-ref text:

> "Procedure 4 step 3 ... MUST be preceded by the closeout sequence
> defined in PM-CHAT.md `## Behavioral rules`..."

Project-side cross-ref to client-installed PM-CHAT.md. **CLEAN.**

### 3.3 `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md`

This doc compares V1 architect's analysis to Pack Chat's independent
answer, with §5.3 "Pack Chat's honest assessment" naming the
architect's frame as materially better. Pack-internal vocabulary
appears extensively (Pack Chat, pack-architect, Tier 1.5,
PACK-CHAT.md, PACK-AGENTS.md, maintenance-docs/, PM-only). All
references are pack-internal artifacts in a pack-internal doc.

**Surface 3.3 findings: ZERO project-side leaks.** The doc itself
does not propose project-side text directly (it's a methodology
critique of V1's analysis); proposals flow through §3.1's §C
placements above. **CLEAN** as a discussion artifact.

### 3.4 `ARCHITECTURE-CLEANUP-BATCH-19C-DISCARDED.md`

Pack-internal vocabulary appears in lines documenting Batch-19b
strategic-rules research artifacts. References are to pack-internal
docs from a pack-internal doc. No project-side text proposals.

**Surface 3.4 findings: ZERO project-side leaks.** **CLEAN** as a
discussion artifact.

### 3.5 `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`

Pack-internal vocabulary appears in 20+ lines documenting G-item
verifications against existing pack source. Authored by pack-
architect to inform §G research scope; references to PACK-CHAT.md /
PACK-AGENTS.md / maintenance-docs/ / pack-architect / pack-coder are
documentation of authority sources and prior research. The doc does
not propose project-side text directly.

**Surface 3.5 findings: ZERO project-side leaks.** **CLEAN** as a
research artifact.

### 3.6 §3 — surface summary

- **CONFIRMED LEAK in PROPOSED PROJECT-SIDE TEXT:** 1 (D.1's
  "Tier 1.5 design ... pack memory pattern" phrase).
- **AMBIGUOUS in PROPOSED PROJECT-SIDE TEXT:** 2 (C.10 "pack-side
  analog" cross-ref; C.12 "paste into Pack Chat" audience cite).
- **CLEAN PROPOSED EDITS:** all 12 §C placements except above
  3 cases.
- **DISCUSSION ARTIFACTS (no project-side text proposals):**
  principle-check, discarded, research docs all clean — pack-
  internal vocab in pack-internal artifacts is by-construction
  legitimate.

---

## §4 — Final verdict

### 4.1 Production surface (project-template/ + 5 client-installed
files in supporting-docs/ + pack-ops/ + scripts/)

**STATUS: NOT CLEAN — 36 confirmed leaks total across multiple files.**

Confirmed-leak breakdown:
- 24 `ARCHITECTURE-PER-ENTRY-SPLIT*` / `ARCHITECTURE-V3*` references
  in 7 per-entry-tree skeleton files under `project-template/docs/
  project/{backlog,implementation-plan,changelog}/`
- 4 `supporting-docs/SETUP-NEW.md` / `SETUP_TEMPLATE.md` /
  `AGENT_KICKOFF_TEMPLATE.md` / `CLI-PM-SETUP.md` references in
  `project-template/docs/pack/prompts/pm-chat.md` and
  `project-template/.mcp.json.example`
- 4 `ARCHITECTURE-V3.md` references in the 4 pm-startup variant files
  (3 SKILL/skill + 1 gemini command)
- 1 `ARCHITECTURE-V3.3-DELTA.md` reference in
  `project-template/docs/pack/PM-CHAT.md` line 410
- 1 `AUDIT-USER-CURATION.md` reference in
  `project-template/skills/boundary-investigation/SKILL.md` line 124
- 2 `maintenance-docs/v11-implementation/ARCHITECTURE-*` references
  in `scripts/lib/detect.sh` comments (lines 335, 678)

These do not break at runtime (the references are documentation, not
code paths), but at client install they are dead-end cross-references
that confuse a client team and pollute the project-design intent.

### 4.2 Batch 19c WIP plans (4 files in maintenance-docs/v11-
implementation/)

**STATUS: REVIVABLE WITH 1 REQUIRED FIX (and 2 RECOMMENDED).**

1. **REQUIRED:** Rewrite §D.1 proposed PM-CHAT.md text to remove
   "Tier 1.5 design" and "pack memory pattern" pack-internal
   vocabulary references. The architectural decision (per-project
   Claude memory cache as convention) is sound; only the
   cross-reference wording needs rework.
2. **RECOMMENDED:** Rewrite §C.10 OT-UT-6 proposed text to drop
   the "project-side analog of the pack-side 'Planner output → user
   review → coder spawn' rule" cross-reference. The rule itself
   should stand on its own merits without referencing the pack-side
   analog (a client team has no pack-side analog to reference).
3. **RECOMMENDED:** Rewrite §C.12 OT-UT-10 proposed text to replace
   "paste into Pack Chat for upstream debugging" with "for upstream
   debugging via PACK-FEEDBACK.md" — the client-resolvable channel.

The other 9 §C placements and §D.2-D.5 architectural decisions are
clean as proposed and would not introduce leaks at client install.
The principle-check / discarded / research artifacts contain heavy
pack-internal vocabulary but live in pack-internal locations (and
propose nothing to project-side) — those are clean by construction.

### 4.3 Cross-cutting observations

- The largest single class of leak is the `ARCHITECTURE-*` cross-
  references in `docs/project/{backlog,implementation-plan,changelog}/`
  per-entry skeleton files. These were authored to cite "WHY THE RULE
  EXISTS" at the architect-doc level; the rule itself is captured
  inline, but the rationale cites pack-internal docs the client
  cannot read. Recommended remediation: drop the per-doc rationale
  cite, OR keep the cite but reword as "(see pack repo changelog
  for design history)" — a generic, non-resolvable cite is honest
  about its non-resolvability without naming specific files.
- The `pm-startup` cluster (3 SKILL files + 1 TOML command) all
  share an identical "Reference: ARCHITECTURE-V3.md §28.1.5" tail.
  A single edit removing this tail (or replacing with a project-
  side cite) closes 4 leaks in one mechanical sweep.
- `project-template/docs/pack/prompts/pm-chat.md` (PM chat self-
  prompts) carries 3 of the 4 `supporting-docs/*` confirmed leaks.
  The "generate-setup" and "generate-agent-kickoff" variants require
  pre-install template files that are NOT shipped — the variants
  themselves are pack-only-usable in their current shape. Either
  ship the templates to clients OR remove the variants from the
  client-installed pm-chat.md OR rewrite to use client-side equivalents.
- `project-template/skills/boundary-investigation/SKILL.md` is the
  heaviest single source of pack-internal vocabulary on the client
  surface — by design (it IS the deny-list documentation). The single
  remediation needed is the `AUDIT-USER-CURATION.md` cite at line 124
  (replace with prose: "STAYS at pack root per pack-repo audit
  finding; not installed at client" — drop the doc-name cite).
- `scripts/lib/detect.sh` comments at lines 335 and 678 are
  trivially fixable: replace `maintenance-docs/v11-implementation/
  ARCHITECTURE-SKILL-DIMENSIONS.md` with "(see pack architecture
  docs for derivation history)" or drop the citation entirely.
- BD-NNN provenance references (the AMBIGUOUS bucket) are the
  hardest call: they add useful provenance for pack maintainers
  re-reading these files in the pack repo, but at client install
  they are dead-end references. A blanket "scrub all BD-NNN refs
  from client-installed files" policy is one path; a contextual
  "keep where useful, drop otherwise" is another. Out of scope for
  this audit to decide.

### 4.4 What this audit does NOT decide

- Whether the 30 AMBIGUOUS cases should be fixed or kept (Pack-Chat
  triage decision).
- Whether Batch 19c should revive as-is with the 3 fixes named in
  §4.2, or be re-architected (depends on user preference and
  whether the V2 architect pass folds the boundary-cleanup work in
  the same batch).
- Whether the 24 ARCHITECTURE-* refs in per-entry-tree skeletons
  warrant a dedicated BD or fold into Batch 19c (depends on
  whether 19c scope wants to expand from "OT-PM-input cleanup" to
  "comprehensive boundary-leak cleanup").

### 4.5 BD-175 remediation efficacy

BD-175 documented the regression of project trinity acquiring
`PACK-AGENTS.md` references via review-fix commits and established
the `boundary-investigation` skill + P-missed-7 pack memory entry.
This audit finds that BD-175's PRIMARY symptom (project trinity
referencing PACK-AGENTS.md / PACK-CHAT.md as authority) IS closed —
the trinity references that remain (§1.1.a) are deny-list framings,
not authority pointers.

However, BD-175 remediation did NOT extend to:
- The per-entry-tree skeleton files (§1.19) installed by S11 —
  these were drafted during the v11.0 per-entry-tree work
  (BD-166 area) and acquired ARCHITECTURE-* cross-refs that
  predate the BD-175 discipline.
- The pm-startup cluster (§1.10) — ARCHITECTURE-V3.md §28.1.5
  cites predate BD-175.
- The pm-chat.md self-prompts (§1.14) — supporting-docs/* cites
  predate BD-175.
- The `scripts/lib/detect.sh` comments (§2.5) — predate BD-175.

The fix-shape for these surfaces is the SAME pattern BD-175
established (replace pack-internal cite with project-side cite OR
drop the cite entirely), but the surfaces were never swept. The
33 confirmed leaks identified in production surface here are
candidates for a follow-on cleanup BD or for expanding Batch 19c
scope.

