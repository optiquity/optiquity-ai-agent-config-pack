# Step 04 — Prompt Template Reorganization Design

*Report type: Phase-1 / Step 4 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-architect (read-only session).*
*Date: 2026-04-21.*
*Scope: Resolve CD-8, OQ-4, OQ-9, OQ-11 with concrete, justified decisions,*
*sized for direct inclusion as a section of V10-DESIGN.md.*

---

## 0. What this report delivers

| Artifact | Status | Section |
|---|---|---|
| Token budget analysis (V10-PREDESIGN Part 9) | Delivered | §1 |
| CD-8 confirmation or revision | Confirmed (revised file list) | §2 |
| OQ-9 resolved (directory name and non-prompt content) | `docs/pack/prompts/` | §3 |
| OQ-11 resolved (per-agent prompt file format) | YAML frontmatter + `## Variant: <slug>` headings | §4 |
| OQ-4 resolved (pm-startup behavior after reorg) | Opaque directory, no read at startup | §5 |
| V9 Lesson 1 applied (operation-placement rationale) | §6.1 |
| V9 Lesson 4 applied (stale prescriptive guidance inventory) | §6.2 |
| Design Requirements addressed | §7 |
| Handoffs for Step 5 / Step 6 | §8 |

---

## 1. Token budget analysis (V10-PREDESIGN Part 9)

### 1.1 Method

- File: `supporting-docs/PROMPT-TEMPLATES.md` (741 lines, 4,986 words).
- Token proxy: `wc -w` × 1.3 ≈ 6,482 tokens for the full file.
- Segmentation: measured each `## Template N` block plus the shared
  "Prompt Authoring Principles" header. Line ranges and `wc -w` per
  segment are recorded below. Proxy consistent across all segments; the
  ratios between segments are more informative than the absolute values.

### 1.2 Per-segment measurements

| Segment | Lines | Words | Proxy tokens | Destination in new model |
|---|---:|---:|---:|---|
| Header / How-to-use / Prompt Authoring Principles | 1–77 | 646 | 840 | Moves to `METHODOLOGY.md` as canonical source (already present there); a short pointer remains in `prompts/README.md` |
| T1 — PM Chat Kickoff | 79–129 | 310 | 403 | `pm-chat.md` `## Variant: kickoff` |
| T2 — Coder (Standard) | 131–209 | 589 | 766 | `coder.md` `## Variant: standard` |
| T3 — Reviewer | 211–291 | 654 | 850 | `reviewer.md` `## Variant: standard` |
| T4 — Fix Cycle (coder) | 293–375 | 591 | 768 | `coder.md` `## Variant: fix-cycle` |
| T4b — Mid-Phase Architect | 377–422 | 325 | 423 | `architect.md` `## Variant: mid-phase` |
| T5 — Tester | 424–451 | 168 | 218 | `tester.md` `## Variant: standard` |
| T6 — Docs-Researcher | 453–486 | 144 | 187 | `docs-researcher.md` `## Variant: standard` |
| T7 — Planner | 488–511 | 137 | 178 | `planner.md` `## Variant: standard` |
| T8 — BACKLOG / STATUS update | 515–570 | 341 | 443 | `pm-chat.md` `## Variant: backlog-status-update` |
| T9 — Auditor | 572–632 | 421 | 547 | `auditor.md` `## Variant: standard` |
| T10–12 — Superseded (auditor subagent note) | 634–653 | 110 | 143 | `auditor.md` trailing note |
| T13 — Generate SETUP.md | 655–678 | 107 | 139 | `pm-chat.md` `## Variant: generate-setup` |
| T14 — Generate AGENT_KICKOFF.md | 680–738 | 422 | 549 | `pm-chat.md` `## Variant: generate-agent-kickoff` |
| Footer | 740–741 | 20 | 26 | Drop |
| **Total monolith** | **741** | **4,985** | **~6,482** | — |

### 1.3 Per-agent file sizes under the proposed layout

Grouping by the CD-8 file-per-agent scheme (with T4b moved from coder to
architect as described in §2.1):

| File | Templates | Words | Proxy tokens |
|---|---|---:|---:|
| `coder.md` | T2 + T4 | 1,180 | 1,534 |
| `reviewer.md` | T3 | 654 | 850 |
| `tester.md` | T5 | 168 | 218 |
| `planner.md` | T7 | 137 | 178 |
| `docs-researcher.md` | T6 | 144 | 187 |
| `architect.md` | T4b (+ placeholder — see §2.2) | 325 | 423 |
| `grpc-schema.md` | placeholder (no v9 content) | ~50 | ~65 |
| `repo-ops.md` | placeholder (no v9 content) | ~50 | ~65 |
| `auditor.md` | T9 + T10–12 note | 531 | 690 |
| `pm-chat.md` | T1 + T8 + T13 + T14 | 1,180 | 1,534 |
| Frontmatter overhead (per file, ~10 lines / ~20 words) | — | +~200 | +~260 |
| **Total content** | — | **4,419** | **5,744** |

The total content is slightly smaller than the monolith because the
shared "Prompt Authoring Principles" section is hoisted out. `prompts/`
as a whole is ~5.7K tokens when concatenated.

### 1.4 Savings per "generate one agent prompt" operation

The PM chat consults the template file when generating a prompt for one
agent. The comparison is "tokens charged to the PM chat to look up one
agent's template":

| PM chat surface | v9 access pattern | v10 access pattern | Per-generation savings |
|---|---|---|---|
| Claude Code CLI (mcp-local-rag on the monolith) | RAG query retrieves ~1–2 chunks (~1,500 tokens) | Direct read of one per-agent file (850–1,534 tokens) | ~10–40% per operation + drop the RAG ingest entirely |
| Claude Code CLI (no RAG, direct read of monolith) | Full 6,482 tokens | 850–1,534 tokens | 76–87% |
| Claude Desktop + filesystem MCP | Full 6,482 tokens | 850–1,534 tokens | 76–87% |
| Claude Desktop + Project knowledge (no MCP) | RAG retrieval over whole 30 MB upload | RAG retrieval over a directory of small chunks; precision improves, per-query retrieval likely shrinks | net qualitative improvement; not quantified |
| Codex CLI | Full 6,482 tokens per read | 850–1,534 tokens per read | 76–87% |
| Gemini CLI | Full 6,482 tokens per read | 850–1,534 tokens per read | 76–87% |

A typical phase cycles through coder → reviewer → (possibly) fix cycle
→ reviewer, which is 3–4 prompt generations. For a non-RAG PM chat
surface that is ~6,482 × 3 ≈ 19.5K tokens for monolith reads, vs.
~3.7K tokens for the equivalent per-agent reads. Savings ≥ ~80% per
phase on all four direct-read surfaces.

### 1.5 Decision-rule evaluation

Per V10-DESIGN-PROCESS-PLAN Step 4:

> "≥ 30% savings on per-session reads: reorg justified on efficiency
> grounds alone. 10–30%: justified only if it also enables something
> structural. <10%: justified only on structural grounds."

- **Non-RAG surfaces (Codex CLI, Gemini CLI, Claude Code CLI without RAG,
  Claude Desktop + filesystem MCP):** 76–87% per-generation savings.
  **≥ 30% threshold met on every non-RAG surface. Reorg justified on
  efficiency grounds alone.**
- **Claude Code CLI with mcp-local-rag:** the raw token savings vs. a
  well-tuned RAG query are modest, but the reorg eliminates the need to
  RAG-ingest a templates file at all — pm-startup drops one RAG check
  (§5) and one doc becomes maintenance-free from a RAG standpoint. This
  is a structural simplification even where the token savings alone
  would not justify it.
- **Claude Desktop + Project knowledge:** harder to quantify without
  measurement, but splitting one 765-line knowledge blob into ~10 small
  files aligns chunk boundaries with agent scope, which is a known RAG
  precision gain. Net-positive even if not numerically decisive.
- **Structural enablers independent of the token math:**
  - CD-9 custom agent prompts must live somewhere addressable per agent.
    There is no sensible way to land `x-<name>` content inside a single
    monolith without reintroducing the monolith's problems for custom
    content.
  - Per-agent maintenance: the v9.3 STATUS.md phase-title-linking rule
    addition (OQ-3 example) touched exactly one block (T8). Under the
    reorg, that edit touches exactly one file (`pm-chat.md`), not the
    whole monolith. This localizes future diffs.

**Conclusion.** The reorg is justified **both** on efficiency grounds
(≥ 30% met on every non-RAG surface) **and** on structural grounds
(CD-9, per-agent localization, simplified RAG story). CD-8 is
confirmed.

---

## 2. CD-8 — Confirmed with revised file list

CD-8 as written in V10-PREDESIGN Part 2 is confirmed, with two
corrections and one addition to the proposed file list.

### 2.1 Corrections to the V10-PREDESIGN file list

The V10-PREDESIGN proposal assigns Template 4b (Mid-Phase Architect
Prompt) to `coder.md` alongside Templates 2 and 4. T4b is an **architect
agent** prompt, not a coder prompt. Reassign it to `architect.md`.

| V10-PREDESIGN CD-8 assignment | Corrected assignment | Reason |
|---|---|---|
| `coder.md` — "standard prompt, fix cycle, mid-phase architect" | `coder.md` — standard + fix-cycle | T4b targets the architect agent, read-only doc-proposal output |
| (no `architect.md` was proposed) | `architect.md` — mid-phase | The PM chat already generates an architect pass at project kickoff (via AGENT_KICKOFF.md) and at mid-phase (T4b); both are architect prompts |

### 2.2 Addition: placeholder files for agents with no v9 monolith entry

The v9 agent roster is 10 non-auditor agents + auditor parent + 7
auditor subagents = 18. The monolith covers only a subset. To preserve
"one file per agent" as a stable rule (Step 5's custom-agent creation
workflow depends on it — CD-9 puts `x-<name>.md` in the same directory),
`architect.md`, `grpc-schema.md`, and `repo-ops.md` receive empty
placeholder files in v10.0. Each placeholder is a valid file per the
format in §4, with zero variants listed in frontmatter and a short
body explaining that no standardized template exists yet and the PM
chat composes the prompt ad-hoc following Prompt Authoring Principles.

Rationale: leaving some agents without a file creates an asymmetry that
Step 5 (custom agent creation workflow) and the migration script both
have to special-case. Each placeholder costs ~150 tokens on disk —
negligible against the savings — and removes a branch in every consumer.

### 2.3 Final file list for `docs/pack/prompts/`

10 files total for v10.0. Every file follows the §4 format.

| File | Agent | Variants (frontmatter) | Source templates in v9 monolith |
|---|---|---|---|
| `coder.md` | coder | `standard`, `fix-cycle` | T2, T4 |
| `reviewer.md` | reviewer | `standard` | T3 |
| `tester.md` | tester | `standard` | T5 |
| `planner.md` | planner | `standard` | T7 |
| `docs-researcher.md` | docs-researcher | `standard` | T6 |
| `architect.md` | architect | `mid-phase` | T4b (standalone architect prompts are generated by PM chat ad-hoc from AGENT_KICKOFF — no separate template) |
| `grpc-schema.md` | grpc-schema | (none — placeholder) | — |
| `repo-ops.md` | repo-ops | (none — placeholder) | — |
| `auditor.md` | auditor | `standard` | T9 (+ T10–12 superseded note as trailing prose) |
| `pm-chat.md` | pm-chat | `kickoff`, `backlog-status-update`, `generate-setup`, `generate-agent-kickoff` | T1, T8, T13, T14 |

Auditor subagents (auditor-architecture, auditor-code, ...) do not each
get their own prompt file; the parent auditor prompt (T9) delegates to
them by name, and per-subagent skill lists live in PLATFORM-SKILLS.md.

Custom prompt files land in the same directory under CD-9:
`docs/pack/prompts/x-<name>.md`. Same format as pack prompt files.

### 2.4 Hoisting of "Prompt Authoring Principles"

The 646-word "Prompt Authoring Principles" section at the top of
PROMPT-TEMPLATES.md is duplicative of content already present in
`supporting-docs/METHODOLOGY.md` § "Prompt Authoring Principles" (the
monolith's own text says "Full details in METHODOLOGY.md — Prompt
Authoring Principles section.").

Under v10 it is removed from `docs/pack/prompts/` entirely. The PM chat
re-reads METHODOLOGY.md § "Prompt Authoring Principles" before generating
any prompt. A short `docs/pack/prompts/README.md` points to that source.

This is consistent with the Design Requirement "single source of truth
where possible" and avoids re-introducing a monolithic top-of-directory
preamble that every consumer has to load alongside the per-agent file.

### 2.5 Rejected alternatives for CD-8

- **Keep the monolith** — rejected. Fails OQ-3 (custom prompts have no
  natural home), fails the maintenance case (every edit touches one
  large file), and fails the token math on every non-RAG surface.
- **One file per variant** (`coder-standard.md`, `coder-fix-cycle.md`)
  — rejected. Trebles the file count without reducing per-generation
  token cost below the per-agent figure. Creates naming proliferation
  for custom agents with multiple variants. `## Variant:` headings
  inside a per-agent file give the same logical separation at a tenth
  the file-count cost.
- **Per-agent-per-variant nested directories** (`prompts/coder/standard.md`,
  `prompts/coder/fix-cycle.md`) — rejected. Same objections as above
  plus one more directory level for the migration script to handle.

---

## 3. OQ-9 — Directory name resolved: `docs/pack/prompts/`

### 3.1 Decision

Use `docs/pack/prompts/` as originally proposed in CD-8. Do not split.
Do not rename.

### 3.2 Rationale

Four names were weighed:

| Candidate | Outcome |
|---|---|
| `docs/pack/prompts/` | Chosen — see below |
| `docs/pack/templates/` | Rejected — "templates" already denotes SETUP_TEMPLATE.md and AGENT_KICKOFF_TEMPLATE.md in `supporting-docs/`; reusing the term for a different concept adds ambiguity |
| `docs/pack/agent-prompts/` | Rejected — the directory contains `pm-chat.md`, whose variants are PM-chat-to-self and PM-chat-to-developer prompts, not agent prompts. A name that asserts "agent only" creates the same OQ-9 objection for `pm-chat.md` that OQ-9 raised against `prompts/` |
| Split: `docs/pack/prompts/` (agent) + `docs/pack/workflows/` (PM chat) | Rejected — two directories for ten files. Adds a migration branch. CD-9 `x-<name>.md` files would have to pick one directory, reintroducing the "where do custom prompts go?" question. Elegance preference: fewer directories, fewer special cases |

The OQ-9 concern was whether "prompts" is honest for PM-chat
operational templates (T1, T8, T13, T14). Resolution: **every file in
the directory contains prompt text — text prepared to be sent to an
LLM or pasted by a developer into an LLM session.** T1 is a prompt the
developer pastes into a new PM chat session. T8 is a prompt the PM chat
uses on itself for a write operation. T13 and T14 are prompts the PM
chat uses on itself to generate project setup artifacts. The distinction
is *which consumer*, not *whether it is a prompt*. The directory name
is accurate.

### 3.3 Migration-churn cost

`prompts/` is the name V10-PREDESIGN uses throughout Part 4, Part 5,
CD-8, and CD-9; picking a different name now would force a churn pass
across those documents and the maintenance-docs record. Keeping the
predesign name minimizes churn.

### 3.4 Path

Final path: `project-template/docs/pack/prompts/`. The `docs/pack/`
directory already houses the other pack-version-controlled
per-project docs (METHODOLOGY.md, PM-CHAT.md, PLATFORM-SKILLS.md,
PACK-FEEDBACK.md) per BD-042's Document-locations scheme that is
already live in v9.x, so the new directory does not introduce a new
top-level location. Monorepo-ready and unchanged by init-project.sh
(BD-044) beyond straight copy.

---

## 4. OQ-11 — Per-agent prompt file format

### 4.1 Decision summary

- **Frontmatter:** YAML, required. Keys: `agent`, `variants`. Others
  reserved.
- **File body structure:** one H1 title, optional short body preamble,
  one H2 `## Variant: <slug>` heading per variant.
- **PM chat variant lookup:** by exact H2 heading match on the pattern
  `## Variant: <slug>`. Variant body is everything from the heading to
  the next H2 or EOF.
- **Machine-parseable:** yes. Standard YAML frontmatter and regex-
  detectable variant headings. Deliberately minimal so that validate-pack.py
  can enforce it and the migration script can produce it without a
  custom parser.
- **Free-form markdown inside a variant:** yes, unchanged from the
  current monolith's per-template content.

### 4.2 Frontmatter schema

Required. Three-dash fences at the top of the file.

```yaml
---
agent: coder
variants:
  - standard
  - fix-cycle
---
```

| Key | Required | Type | Meaning |
|---|---|---|---|
| `agent` | yes | string | Agent identifier, matches the agent's filename convention across the three CLI tools (Claude `.md`, Codex `.toml` `name`-after-normalization, Gemini `.md`). Exactly one of the pack's canonical agent names, or an `x-<name>` custom. For `pm-chat.md`, value is `pm-chat` (a reserved non-agent identifier; PM chat is the consumer, not an agent). |
| `variants` | yes | list of strings | Zero or more variant slugs. Each slug must appear as a `## Variant: <slug>` heading below. Empty list is legal for placeholder files. Slugs are lowercase ASCII with hyphens: `^[a-z][a-z0-9-]*$`. |

Reserved keys that v10 does not use but validate-pack.py must
**permit** so that a later minor can add them without a format break:
`description`, `deprecated-by`, `notes`. Unknown keys at file top are
rejected.

Frontmatter authors must not embed tool-specific content in the
frontmatter itself — prompt content is markdown, not structured data.
YAML is the minimum needed to answer "which agent is this file for and
what variants does it contain?"

### 4.3 Body structure

```markdown
---
agent: coder
variants:
  - standard
  - fix-cycle
---

# coder — prompt templates

Short one-paragraph description of the agent and when the PM chat
generates prompts for it. This is free-form prose, not a variant.

## Variant: standard

*Generated by PM chat for each implementation phase.*

...body of the standard template, unchanged from T2...

## Variant: fix-cycle

*Generated by PM chat after the fix plan has been presented and the user
has given explicit approval. Do not generate this prompt until the plan
is approved.*

...body of the fix-cycle template, unchanged from T4...
```

Rules:

1. **Exactly one H1** at the top of the body. Its text is free but
   conventional: `# <agent> — prompt templates` (or
   `# <agent> — PM chat templates` for `pm-chat.md`).
2. **Optional preamble** between the H1 and the first H2. Free-form
   markdown. Short — one paragraph. This is where the current
   monolith's "*Generated by PM chat for…*" italic annotations live
   when they apply to the whole file rather than a specific variant.
3. **One H2 per variant.** Heading text matches the literal pattern
   `## Variant: <slug>` where `<slug>` is exactly one of the values
   listed in frontmatter `variants:`. Deviation = format violation.
4. **No H1 or H2 inside a variant body.** H3 and below are permitted
   for internal structure.
5. **Variant body** is free-form markdown from its H2 through to the
   next H2 or EOF. The body carries the prompt text the PM chat copies
   and customizes. The opening italic annotation (e.g. *"Generated by
   PM chat for each implementation phase."*) stays with the variant.
6. **No top-of-file preamble** other than the H1 + optional paragraph.
   The "Prompt Authoring Principles" content that currently prefixes
   PROMPT-TEMPLATES.md is removed from this directory and lives only
   in METHODOLOGY.md (see §2.4).

### 4.4 PM chat variant lookup procedure

Given a need to generate a prompt for agent `<a>`, variant `<v>`:

1. Read `docs/pack/prompts/<a>.md`.
2. Parse YAML frontmatter. Confirm `agent == <a>` and `<v> in variants`.
   If frontmatter and `<v>` disagree, stop and report the inconsistency
   (file is corrupt or Step-5 workflow failed).
3. Locate the line matching `^## Variant: <v>\s*$`.
4. Copy the body from the first non-blank line after that heading
   through to the line before the next `^## ` heading, or EOF.
5. Customize with phase-specific fill-ins per the monolith's existing
   `[PLACEHOLDER]` convention, which is preserved unchanged.

No in-file TOC, no front-matter index, no cross-file includes. A single
file is the unit of read; a single variant is the unit of copy.

### 4.5 Validate-pack.py enforcement

The validate-pack.py workflow gains a check that iterates every file in
`project-template/docs/pack/prompts/`:

- Rejects files without valid YAML frontmatter.
- Rejects files whose `agent` frontmatter field does not match the
  filename stem (e.g. `coder.md` must have `agent: coder`).
- Rejects `variants` entries whose slug does not match a literal
  `## Variant: <slug>` H2 heading, and vice versa.
- Accepts zero-variant placeholder files (`variants: []`).
- Allows `x-<name>.md` files to follow the same rule set (CI does not
  otherwise validate x- files per CD-5 preservation model).

### 4.6 Rejected alternatives for OQ-11

- **No frontmatter, headings only.** Rejected — validate-pack.py cannot
  detect file-heading drift (e.g. someone renames the H1 heading, leaves
  the file still usable but no longer machine-indexable). The
  frontmatter is the one canonical source of truth for "what agent and
  what variants are in this file."
- **JSON frontmatter / TOML frontmatter.** Rejected — YAML is the Claude
  and Gemini agent-file convention already (both tools use `---` YAML
  frontmatter in `.claude/agents/*.md` and `.gemini/agents/*.md`);
  matching that convention reduces cognitive load for agents the PM
  chat is already maintaining.
- **Variant indexed by section-anchor link** (e.g. PM chat finds a
  variant by GitHub anchor `[[coder.md#variant-standard]]`). Rejected
  — anchors are computed from heading text per a GitHub-specific rule
  (lowercase, hyphenate spaces, strip em-dashes, etc.). Using the
  explicit `## Variant: <slug>` literal makes the parse trivial and
  tool-independent.
- **Single heading `## Standard` without the `Variant:` prefix.**
  Rejected — collides with free-form markdown inside the variant body
  (an author might legitimately want an H2 subsection named "Standard
  output format"). The `Variant:` prefix is a reserved marker.
- **Machine-readable variant bodies** (e.g. structured JSON inside a
  code fence). Rejected — the variant body is a prompt template, not
  a data record. Keeping it markdown preserves the author's ability
  to iterate on wording without a parser in the loop.

---

## 5. OQ-4 — pm-startup behavior after reorg

### 5.1 Decision

`pm-startup` **does not** read any prompt file at startup. The
directory is opaque to startup. The PM chat reads individual
`docs/pack/prompts/<agent>.md` files on demand at prompt-generation
time.

`pm-startup` drops its existing RAG-freshness check on
`docs/pack/PROMPT-TEMPLATES.md` (Step 4 of the current SKILL.md) —
the file no longer exists. The Step 4 RAG check on METHODOLOGY.md
is retained.

No manifest file. No directory scan at startup.

### 5.2 Impact on `project-template/skills/pm-startup/SKILL.md`

The current Step 4 reads:

```bash
git log -1 --format="%H %cd" --date=short -- docs/pack/METHODOLOGY.md
git log -1 --format="%H %cd" --date=short -- docs/pack/PROMPT-TEMPLATES.md
```

Under v10 this becomes:

```bash
git log -1 --format="%H %cd" --date=short -- docs/pack/METHODOLOGY.md
```

The `docs/pack/PROMPT-TEMPLATES.md` reference is removed. The
surrounding prose about re-ingesting is updated to name only
METHODOLOGY.md.

No new step is added. The startup ready-status summary (Step 6) is not
changed — it does not currently report on PROMPT-TEMPLATES.md and does
not need to report on `prompts/`.

### 5.3 Why not a manifest

A manifest (`prompts/MANIFEST.md` or `prompts/_index.md`) was
considered. Rejected for three reasons:

- **Drift surface.** Every new `x-<name>.md` under CD-9 would have to
  update the manifest. That is a second write target for the PM chat
  creation workflow and a second thing the migration script must
  preserve across upgrades. The authoritative "what agents exist in
  this project" record already lives in CLAUDE.md / AGENTS.md /
  GEMINI.md phase-routing tables and in `.claude/agents/`,
  `.codex/agents/`, `.gemini/agents/` directories. A manifest would
  be a third record of the same fact.
- **No startup need.** pm-startup's job is to refresh PM chat context
  from state files. Prompt files are consulted only at generation
  time. Loading the manifest at startup would charge tokens for data
  the PM chat does not yet need.
- **Detection scans belong to phase-gate, not startup.** The "improper
  additions" detection scan (V10-PREDESIGN Part 5, CD-3) is a
  phase-gate and custom-agent-creation-workflow concern, not a startup
  concern. Step 5 of the design process plan owns that detection
  design.

### 5.4 Why not a directory scan at startup

A `ls docs/pack/prompts/` at startup would cost almost nothing and
would let pm-startup report "prompts available: 10" in its ready
summary. Rejected because:

- pm-startup's output is a fixed, user-facing ready summary. Adding a
  "prompts available" line adds display noise for information the user
  does not consume — the PM chat uses it, not the developer.
- The scan would cross-tool assume shell `ls`. Codex and Gemini CLI
  PM chats can shell out, and Claude Code CLI can, but Claude Desktop
  with Projects knowledge (no filesystem MCP) cannot. Making pm-startup
  tool-dependent when it does not need to be would regress
  "PM Chat tool flexibility."

Opaque is the simplest and most tool-portable.

### 5.5 Impact on `project-template/docs/pack/PM-CHAT.md`

The File access strategy table row for `PROMPT-TEMPLATES.md` is removed
and replaced with one new row:

| File | How to access | Why |
|---|---|---|
| `docs/pack/prompts/<agent>.md` | Direct read (on demand, at generation time) | Small per-agent files; read only the file for the agent currently being prompted |

The "Claude Code CLI / File access" section's sentence "*For large
stable files (METHODOLOGY.md, PROMPT-TEMPLATES.md), use mcp-local-rag
for semantic search.*" has `PROMPT-TEMPLATES.md` removed; mcp-local-rag
is now recommended only for METHODOLOGY.md.

---

## 6. V9 lessons applied

### 6.1 Lesson 1 — operation-placement rationale (prevent "skills distribution changed twice")

Per V10-PREDESIGN Part 8 Lesson 1, each setup operation's placement is
justified rather than assumed.

| Operation | Placement | Rationale |
|---|---|---|
| Pack-repo source of truth for prompt files | `project-template/docs/pack/prompts/` | Co-located with existing `docs/pack/` peers (METHODOLOGY.md, PM-CHAT.md, PLATFORM-SKILLS.md) that are already under the same lifecycle rules. One pattern, not two |
| Distribution into a project | `init-project.sh` (BD-044) performs a straight directory copy as part of the one-time pack-copy step | One-time copy matches the semantics — a prompt file is a pack artifact, not a per-machine resource. Same model as every other `docs/pack/` file in v9.x. Explicitly not placed in `bootstrap.sh` (which runs repeatedly per machine) and explicitly not lazily created on first PM chat run (which would be ad-hoc) |
| Prompt file read at **pm-startup** | None | Opaque to startup (§5). Reads happen at generation time when the specific agent and variant are known |
| Prompt file read at **prompt generation** | PM chat reads one file, on demand | Matches the use: one agent, one variant, one file. Zero context spent on other agents' prompts |
| `pm-startup` RAG ingest | Dropped (was: ingest PROMPT-TEMPLATES.md) | The monolith no longer exists; per-agent files are too small to warrant RAG |
| Detection of improperly added x- files | Phase-gate scan + custom-agent creation workflow (Step 5) | Detection is a Step-5 concern, not a Step-4 concern; this step does not define it and does not pre-empt it |
| Migration of v9.x prompt content into v10 per-agent files | Migration script (Step 6) | A one-time transformation at upgrade. Not a recurring operation; does not live in bootstrap.sh, does not live in init-project.sh |

Each operation lives where its lifecycle matches. No operation is
distributed across two places. This is the inverse of the v9.0 skills-
distribution decision that was later reversed.

### 6.2 Lesson 4 — stale prescriptive guidance inventory

Per V10-PREDESIGN Part 8 Lesson 4, every document that prescribes
"read PROMPT-TEMPLATES.md" or assumes the file exists must be updated
when the monolith is replaced. A grep sweep for `PROMPT-TEMPLATES`
across the pack returned 27 files. Categorized by update obligation:

**Update required in v10.0 (operational documents):**

| File | Update obligation |
|---|---|
| `project-template/docs/pack/PM-CHAT.md` | Remove the PROMPT-TEMPLATES.md row from the File access strategy table; replace with a `docs/pack/prompts/<agent>.md` row (§5.5). Remove `PROMPT-TEMPLATES.md` from the mcp-local-rag recommendation sentence |
| `project-template/skills/pm-startup/SKILL.md` | Drop PROMPT-TEMPLATES.md from the Step 4 RAG-freshness check (§5.2). Remove it from the Step 2 core-state-files list if present |
| `project-template/CLAUDE.md` | Update the Document locations table's `docs/pack/` row to replace the literal `PROMPT-TEMPLATES.md` with a reference to the `prompts/` directory |
| `project-template/AGENTS.md` | Same edit as CLAUDE.md (trinity rule) |
| `project-template/GEMINI.md` | Same edit as CLAUDE.md (trinity rule) |
| `project-template/README.md` | Any file-listing or path reference to PROMPT-TEMPLATES.md |
| `supporting-docs/METHODOLOGY.md` | References to PROMPT-TEMPLATES.md as the location of per-agent templates should point to `docs/pack/prompts/<agent>.md`. "Prompt Authoring Principles" section remains the canonical source; no change to that section's content |
| `supporting-docs/PROMPT-TEMPLATES.md` itself | Deleted at migration (with v9.x backup per Step 6) |
| `QUICKSTART.md` | Router rewrite under BD-044 (Step 7) will touch this file regardless; the PROMPT-TEMPLATES.md reference is replaced as part of that rewrite |
| `supporting-docs/CLI-PM-SETUP.md` | Any reference to PROMPT-TEMPLATES.md as a directly-paste-able resource should point to per-agent files |
| `supporting-docs/SETUP_TEMPLATE.md` | References to PROMPT-TEMPLATES.md in the setup flow are replaced with the prompts/ directory reference |
| `supporting-docs/DEPENDENCIES.md` | Only if it enumerates PROMPT-TEMPLATES.md as a shipped file |
| `supporting-docs/MIGRATION-v8-to-v9.md` | No update needed — v8→v9 is a historical migration path that already shipped. Leave the reference in place |
| `.github/workflows/` / `validate-pack.py` | Replace any filesystem-layout check that expects `supporting-docs/PROMPT-TEMPLATES.md` with one that expects `project-template/docs/pack/prompts/` and its per-agent file roster |

**Annotate but do not mutate (historical records — per Lesson 4,
update verification checklists, not historical content):**

| File | Annotation obligation |
|---|---|
| `maintenance-docs/V9-DESIGN.md` | Decisions and verification checklists that reference PROMPT-TEMPLATES.md as a shipping artifact must receive a v10 supersession note next to each reference, pointing to the v10 prompts/ directory. Do not silently rewrite the v9 content |
| `maintenance-docs/V9-AUDIT-REPORT.md` | Same treatment — annotate, do not mutate |
| `maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md` | No action — pure history |
| `maintenance-docs/guides/ai-agent-config-pack-v8-guide.md` | No action — pure history |
| `maintenance-docs/GEMINI-CLI-ANALYSIS.md` | No action — pure history |
| `CHANGELOG.md` | No action — each entry is a historical record of the state at its ship date |
| `BACKLOG.md` BD-027, BD-028, BD-029, BD-038 resolved entries | No action — resolved entries describe what shipped at the time |
| `PACK-CHAT.md` | If it references PROMPT-TEMPLATES.md in operational guidance, update; if only in historical notes, leave |
| `README.md` repository layout section | Update if it enumerates `supporting-docs/PROMPT-TEMPLATES.md` as a shipping file. The layout section is an operational reference, not history |

**Step 8 (touch point inventory) will incorporate this list; it is not
authoritative here. The purpose of listing it here is to satisfy V9
Lesson 4 by surfacing the update scope at the design stage rather than
discovering it at implementation time.**

---

## 7. Design Requirements addressed

Per V10-PREDESIGN Part 7, V10-DESIGN.md must address specific design
requirements. This step contributes to the following:

### 7.1 Resource considerations

Proved directly by the §1 token analysis. The reorg reduces per-
generation token cost by 76–87% on every non-RAG PM chat surface. On
Claude Code CLI with RAG, the reorg reduces the set of files needing
RAG ingest by one. No surface regresses.

### 7.2 Document access patterns

Three access-time classes, with the reorg's placement for each:

| Class | Example | Where prompts/ lives |
|---|---|---|
| Setup-time (read once during project creation) | QUICKSTART, SETUP-NEW, MIGRATION guide | `docs/pack/prompts/` copies happen here (init-project.sh), but no file is *read* at this class |
| Startup-time (read at every PM chat startup) | BACKLOG, STATUS, PM-CHAT, PLATFORM-SKILLS | `docs/pack/prompts/` **is not** in this class. No prompt file is read at startup |
| Workflow-time (read during active development) | Per-agent prompt generation, CHANGELOG update, ARCHITECTURE section | `docs/pack/prompts/<agent>.md` is strictly workflow-time |

The reorg is an explicit move of prompt-related content from the
startup-time class (monolith read via RAG at startup) to the workflow-
time class (per-agent read at generation). This matches the actual
use — prompts are only needed when a prompt is being generated.

### 7.3 Best use of RAG

- **Claude Code CLI with mcp-local-rag.** The monolith's RAG ingest is
  dropped entirely. METHODOLOGY.md remains the large stable file
  warranting RAG. The overall RAG surface shrinks.
- **Claude Desktop + Project knowledge (no MCP).** Smaller, per-agent
  chunks improve retrieval precision for "generate coder prompt"
  queries — one file aligns with one intent. The split is a net gain
  even without quantification, because RAG chunk boundaries now match
  the semantic unit of retrieval.
- **Claude Desktop + filesystem MCP.** Recommended mode for desktop PM
  chat (per Step 2 Fact 4). Per-agent files are directly readable by
  path. No RAG needed.
- **Codex CLI, Gemini CLI.** No RAG involved. Direct per-agent reads.

### 7.4 PM Chat tool flexibility

The per-agent file model is tool-neutral. Every CLI tool can read a
small markdown file by path; every hosted surface (Claude Desktop +
Project knowledge, Claude Desktop + filesystem MCP) can access them
through its respective mechanism. No decision in this step requires a
tool-specific capability. Step 2 Fact 4 is honored — the design does
not require filesystem MCP, but recommends it for Desktop surfaces
because direct path-read is the cleanest of the available options.

### 7.5 Maintenance considerations

The v9.3 STATUS.md phase-title-linking addition to Template 8 is the
concrete precedent for the localization benefit. Under v9.x, that
change touched PROMPT-TEMPLATES.md — a 741-line file; the diff
reviewer had to scan to find what changed. Under v10, the same change
touches `docs/pack/prompts/pm-chat.md` — a ~150-line file whose sole
scope is PM chat operational templates. Future edits to any single
agent's template carry the same localization property.

Single source of truth is preserved:

- "Prompt Authoring Principles" lives only in METHODOLOGY.md (§2.4).
- Each template's text lives in exactly one per-agent file.
- Custom prompts live under the same rule (CD-9).

---

## 8. Handoffs

### 8.1 To Step 5 (custom agent and skill support)

Step 5 inherits from this step:

- The format spec in §4 is the contract that custom `x-<name>.md`
  files must satisfy. Step 5's PM-chat-driven creation workflow writes
  files that pass §4.5 validation.
- The file list in §2.3 is the canonical "what a fresh pack copy looks
  like." Step 5's detection scan classifies any file in the directory
  that is neither in §2.3 nor `x-` prefixed as improperly added.
- `pm-chat.md` (§2.3) is not itself an agent file; Step 5's roster
  detection must exempt it from agent-roster comparisons.

### 8.2 To Step 6 (migration design)

Step 6 inherits from this step:

- The monolith → per-agent split logic is specified: which template
  goes to which file (§1.2 table's "Destination in new model" column).
  The migration script can be written as a literal map from template
  title / line range → destination file + variant slug.
- Every file in the migration output must pass §4.5 validation. The
  migration script runs validate-pack.py's new prompts-directory check
  as its last step, before committing the migrated project.
- OQ-3 customization concern: if a project's v9.x
  `supporting-docs/PROMPT-TEMPLATES.md` diverges from the pack's v9.3
  baseline, the diff is preserved as `docs/pack/prompts/_v9-backup.md`
  for PM-chat reconciliation. Step 6 specifies the reconciliation
  procedure; the format here does not depend on the outcome.
- The "Prompt Authoring Principles" header (lines 1–77 in the
  monolith) is not copied into any per-agent file; its content is
  already present in METHODOLOGY.md. The migration script simply
  drops it. If a project has customized that section, the backup
  captures it.

### 8.3 To Step 8 (touch point inventory) and Step 10 (verification plan)

- §6.2 is a starting inventory of stale-reference targets. Step 8
  consolidates it into the full touch-point table.
- validate-pack.py additions are named in §4.5 and §6.2; Step 10
  writes the verification plan entry for each.

### 8.4 To Phase 3 (implementation planning)

No dependencies are opened here that Phase 3 must close. Phase 3
consumes the §2.3 file list, §4 format spec, §5 pm-startup edits, and
§6.2 stale-reference inventory as input and produces per-file edit
sequences.

---

## 9. Summary

- **CD-8 confirmed.** The prompt template reorganization ships in v10.0
  under `docs/pack/prompts/` with 10 per-agent files (§2.3), under the
  format in §4. Mid-Phase Architect (T4b) moves from the coder to the
  architect file; three agents get placeholder files to keep the
  one-file-per-agent rule uniform.
- **OQ-9 resolved.** Directory is `docs/pack/prompts/`; no split; PM
  chat operational templates live in `pm-chat.md` in the same
  directory; "Prompt Authoring Principles" hoists out to METHODOLOGY.md.
- **OQ-11 resolved.** YAML frontmatter with `agent` and `variants`;
  body uses `## Variant: <slug>` H2 headings; variant body is free-form
  markdown; validate-pack.py enforces the format.
- **OQ-4 resolved.** pm-startup does not read the prompts directory;
  drops the PROMPT-TEMPLATES.md RAG-freshness check; PM chat reads
  per-agent files only at generation time.
- **Decision-rule evaluation (§1.5).** ≥ 30% per-generation savings on
  every non-RAG PM chat surface. Reorg justified on efficiency alone,
  with structural justification for CD-9 reinforcing it.
- **V9 Lesson 1.** Each operation's placement is explicitly justified
  (§6.1), avoiding the "skills distribution changed twice" class of
  defect.
- **V9 Lesson 4.** The full list of documents referencing
  PROMPT-TEMPLATES.md as a monolith is inventoried and classified into
  must-update and annotate-but-preserve (§6.2).
- **No new open questions opened.** All resolutions are concrete and
  ready for Step 5 and Step 6 to consume.

---

*End of step-04-prompt-reorg.md.*
