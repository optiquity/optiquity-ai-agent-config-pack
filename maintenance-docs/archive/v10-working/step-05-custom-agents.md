# Step 05 — Custom Agent and Skill Support Design

*Report type: Phase-1 / Step 5 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-architect (read-only session).*
*Date: 2026-04-21.*
*Scope: Resolve CD-1, CD-2, CD-3, CD-4, CD-6, CD-7, CD-9 and OQ-1, OQ-2, OQ-7, OQ-8;*
*specify the detection workflow; produce a Procedure 5 outline for METHODOLOGY.md.*
*Consumes: Step 2 CLI verification findings; Step 4 approved prompt-directory spec.*

---

## 0. What this report delivers

| Artifact | Status | Section |
|---|---|---|
| CD-1 (x- prefix) confirmation | Confirmed — uniform `x-<name>` at filename level across all three CLIs, including Codex `name =` field | §1 |
| CD-2 (identical structure) confirmation | Confirmed — per tool, identical to that tool's pack-file format | §2 |
| CD-3 (PM chat as only creation mechanism) + OQ-7 (escape hatch) resolution | Confirmed — PM chat is the primary creator; detect-and-offer-to-register is the sole documented escape hatch | §3 |
| CD-4 (three creation paths) + concrete PM chat workflow | Confirmed; workflow specified per tool with approval gates | §4 |
| CD-6, CD-7 (custom skills + PLATFORM-SKILLS.md `## Custom skills`) | Confirmed; header and column spec provided | §5 |
| CD-9 (custom prompts in `docs/pack/prompts/`) | Confirmed; compatible with Step 4 §4 format | §6 |
| OQ-1 (authoritative pack roster) resolution | Hardcoded roster section in `docs/pack/PM-CHAT.md`, enforced by validate-pack.py against `.claude/agents/` filenames | §7 |
| OQ-2 (Codex `config.toml`) resolution | No config.toml edit required (per Step 2 C-1); only the per-agent `.toml` file is written | §8 |
| OQ-8 (x- prefix future collision) resolution | Pack reserves the `x-` filename namespace; validate-pack.py enforces | §9 |
| Detection workflow (pm-startup and phase-gate) | Specified | §10 |
| Procedure 5 outline for METHODOLOGY.md | Drafted | §11 |
| PLATFORM-SKILLS.md `## Custom skills` section spec | Drafted (header, columns, example) | §12 |
| PM-CHAT.md additions | Specified | §13 |
| Trinity routing table additions | Specified | §14 |
| validate-pack.py updates | Specified | §15 |
| V9 Lessons 2, 3, 5 applied | §16 |
| Design requirements addressed | §17 |
| Handoffs to Steps 6, 7, 8, 10 | §18 |
| Summary | §19 |

---

## 1. CD-1 — x- prefix confirmed (uniform across tools)

### 1.1 Decision

The `x-` prefix rule is **confirmed uniformly at the filename level** for all
three CLI tools and for custom skill directory names. The Codex `name =`
field inside a custom agent's `.toml` file also uses `x-<name>` (hyphen,
not underscore).

| Surface | Custom file pattern | Field value |
|---|---|---|
| Claude Code agent | `.claude/agents/x-<name>.md` | YAML frontmatter `name: x-<name>` |
| Codex agent | `.codex/agents/x-<name>.toml` | TOML `name = "x-<name>"` |
| Gemini agent | `.gemini/agents/x-<name>.md` | YAML frontmatter `name: x-<name>` |
| Custom skill (each tool) | `{.claude,.codex,.gemini}/skills/x-<name>/SKILL.md` | YAML frontmatter `name: x-<name>` |
| Custom prompt | `docs/pack/prompts/x-<name>.md` | YAML frontmatter `agent: x-<name>` |

`<name>` is lowercase ASCII letters, digits, and hyphens only, matching the
regex `^[a-z][a-z0-9-]*$`. This matches:

- Claude Code subagent naming (lowercase-with-hyphens, per Step 2 Fact 2).
- Claude Code skill `name` frontmatter rule: ≤64 chars, lowercase letters,
  digits, hyphens (Step 2 Fact 2 §5).
- Gemini subagent `name` rule: lowercase letters, digits, hyphens, underscores
  (Step 2 Fact 3 §2). Hyphen chosen for parity.
- Codex empirical smoke-test result resolving Step 2 C-2: hyphenated `name =`
  value is accepted at runtime.

### 1.2 Why uniform

Step 2's C-2 originally offered three options (asymmetric per-tool, symmetric
underscore, symmetric hyphen). The smoke test resolved C-2 in favor of
hyphen. Keeping the identifier identical across Claude / Codex / Gemini
agent files removes an entire class of cross-tool lookup bugs and matches
the existing pack convention (all pack agents use the same stem across the
three tools — see `.claude/agents/auditor-architecture.md`,
`.codex/agents/auditor-architecture.toml`,
`.gemini/agents/auditor-architecture.md`).

### 1.3 Rejected alternatives

- **Different identifier forms per tool** (`x-foo.md` in Claude/Gemini but
  `name = "x_foo"` inside Codex TOML, as fallback Options A/B in Step 2 C-2
  proposed). Rejected — introduces a mapping layer the PM chat must maintain
  and blocks the trinity rule's "symmetry is the default" principle. The
  smoke test made the fallback unnecessary.
- **No prefix, differentiate by registry** (track custom files in a separate
  file, no filename marker). Rejected — visibility on disk is a requirement
  for developers who inspect the directories directly, and preservation
  during migration (CD-5) is far simpler when the filename itself carries
  the classification.

### 1.4 Tool-specific deviation: none

No CLI rejects `x-<name>` at any surface. Step 2 findings are consistent
across all three tools. No documented deviation is required.

---

## 2. CD-2 — Custom files follow identical structure to pack files

### 2.1 Decision

"Identical structure" means **identical to each tool's pack-file format in
that tool**, not literally identical across tools. Each tool has its own
required structure; the PM chat's creation workflow (§4) produces the
tool-native form for each.

| Tool | Structure custom files must match |
|---|---|
| Claude Code | YAML frontmatter with `name`, `description`, `tools`; markdown body as system prompt. Same as every pack agent in `.claude/agents/` (e.g., `planner.md`) |
| Codex | TOML with `name`, `description`, `model`, `approval_policy`, `sandbox_mode`, `developer_instructions` (triple-quoted string). Same as every pack agent in `.codex/agents/` (e.g., `planner.toml`) |
| Gemini | YAML frontmatter with `name`, `description`, `model`, `temperature`, `max_turns`; markdown body as system prompt. Same as every pack agent in `.gemini/agents/` (e.g., `planner.md`) |
| Skill (any tool) | Directory containing exactly one `SKILL.md` with YAML frontmatter (`name`, `description`, `allowed-tools`). Same as pack skills |
| Prompt file | YAML frontmatter (`agent`, `variants`) + `## Variant: <slug>` H2 headings per Step 4 §4 |

### 2.2 What identical means operationally

The PM chat's custom-agent-creation workflow produces files that would pass
`validate-pack.py`'s existing per-tool structural checks if they were
included in the pack roster. The only thing that keeps them out of the
roster is the `x-` filename prefix — see §7 and §9.

### 2.3 Rejected alternative

- **A single "pack canonical" agent spec that the PM chat translates into
  three tool forms at consume time.** Rejected — each tool loads the file
  natively from disk; a canonical-on-top layer adds a translation step the
  tools themselves never run. The PM chat already performs the translation
  once at creation (§4); that is the right place for the translation to
  live. See V9 Lesson 2 — do not extrapolate across tools.

---

## 3. CD-3 + OQ-7 — PM chat primary; detect-and-offer is the escape hatch

### 3.1 Decision

**CD-3 confirmed with one revision:** the PM chat is the only *supported*
creation mechanism. A developer is not prevented by any enforcement
mechanism from writing files manually, but manual additions are
*unsupported* and are visible only after the PM chat's detection scan
classifies them and offers to complete registration.

**OQ-7 resolved** by Option (a) from V10-DESIGN-PROCESS-PLAN Step 5 Work
Item 3: PM chat as primary + detect-and-offer-to-register as the de facto
escape hatch. No separate "manual path" is documented in METHODOLOGY.md
because the detection flow IS the manual path — the developer drops a file,
the PM chat finds it on next startup or phase gate, and guides the
registration.

### 3.2 Rationale

A parallel "documented manual path" was considered and rejected on V9
Lesson 1 grounds: two paths to the same outcome doubles the maintenance
surface and, historically, produces inconsistent behavior when one path is
revised and the other is not. A single path (PM-chat-driven, with
detection-and-registration for files that appeared outside the chat) keeps
the lifecycle story uniform.

The "Codex-only workflow, offline, or knowledgeable developer" case in OQ-7
is handled the same way: the developer creates what they want, and the PM
chat's first run after that event classifies and registers. No behavior is
denied; it just becomes registered before it becomes usable.

### 3.3 What "unsupported" means concretely

- **Not denied:** file-system writes are not blocked. Claude Code, Codex,
  and Gemini will load whatever is on disk that matches their native format.
- **Not visible to PM chat prompts:** manually-added files are not in the
  routing table, not in PLATFORM-SKILLS.md, not in the custom-agent roster
  the PM chat uses when generating prompts. The agent file exists; the
  workflow cannot route to it until registration is complete.
- **Flagged at every detection scan:** the PM chat surfaces the file at the
  next pm-startup or phase-gate check (§10) and offers to register.

### 3.4 Why "invisible until registered" is the correct default

Step 2 C-3 established that Codex emits no file-creation hook. Claude Code
has live agent/skill change detection (Step 2 Fact 2) but the PM chat
itself does not subscribe to it — detection is a PM-chat-level concern, not
a CLI-tool-level concern. A cross-tool-consistent behavior must operate at
the PM chat layer, which runs scans at well-defined times (§10). Between
scans, a manually-added file is invisible to the PM chat's routing
decisions. This is a property of the architecture, not a bug.

### 3.5 Rejected alternatives

- **Enforce PM-chat-only creation via a hook that blocks edits outside the
  chat.** Rejected — no cross-tool-consistent way to do this (Step 2 C-3);
  Claude Code has PreToolUse/PostToolUse but Codex does not fire file-edit
  hooks and Gemini CLI's hook model was not fully verified in Step 2. A
  hook-based enforcement would build three different enforcement layers
  with different guarantees — V9 Lesson 2 pattern.
- **Two documented paths (chat-driven and manual-procedure).** Rejected —
  see 3.2. Lesson 1 pattern.

---

## 4. CD-4 — Three creation paths + PM chat workflow

### 4.1 Decision — CD-4 confirmed

The three creation paths in V10-PREDESIGN CD-4 are confirmed unchanged:

1. **Describe-driven.** Developer describes the agent (purpose, tools
   needed, read-only or write, prompt variants). PM chat asks clarifying
   questions, drafts all artifacts.
2. **One-tool-format seed.** Developer provides the Claude or Codex or
   Gemini agent file. PM chat translates to the other two tool formats and
   drafts the prompt template.
3. **Existing-file adoption.** Developer provides a file not in pack
   conventions. PM chat reviews, rewrites to pack conventions, then
   produces the other two forms plus prompt.

### 4.2 Concrete files the PM chat creates per custom-agent request

For every custom agent, the PM chat produces **all** of the following
artifacts. The developer sees drafts of all of them before anything is
committed.

| Artifact | Path | Source of truth for format |
|---|---|---|
| Claude agent file | `.claude/agents/x-<name>.md` | Format matches pack Claude agent files (§2.1 row 1). YAML `name: x-<name>`, `description:`, `tools: …`, markdown body |
| Codex agent file | `.codex/agents/x-<name>.toml` | Format matches pack Codex agent files (§2.1 row 2). TOML `name = "x-<name>"`, `description =`, `model =`, `approval_policy =`, `sandbox_mode =`, `developer_instructions = """…"""` |
| Gemini agent file | `.gemini/agents/x-<name>.md` | Format matches pack Gemini agent files (§2.1 row 3). YAML `name: x-<name>`, `description:`, `model:`, `temperature:`, `max_turns:`, markdown body |
| Custom prompt file | `docs/pack/prompts/x-<name>.md` | Step 4 §4 format. Frontmatter `agent: x-<name>` and `variants: [<slug>, …]`; one `## Variant: <slug>` per variant |
| PLATFORM-SKILLS.md rows | `docs/pack/PLATFORM-SKILLS.md` `## Custom agents` section (added in §5 / §12) and, if loading custom skills, `## Custom skills` section | §12 |
| Routing-table rows | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — Phase routing table rows (§14) | Existing Phase routing table format |

**What the PM chat does NOT create:**

- **No `.codex/config.toml` edit.** Per Step 2 C-1 (Fact 1), Codex
  auto-discovers `.codex/agents/*.toml` files. No per-agent `[agents.<name>]`
  entry exists in documented Codex. This is a direct reversal of the
  V10-PREDESIGN Part 4 touch-point row and Part 5 workflow step — those
  entries are *removed* by Step 8 (touch-point consolidation).
- **No manifest file.** Per Step 4 §5.3 — pm-startup does not read a
  prompt-directory manifest.

### 4.3 Creation order and approval gates

The order preserves Incremental Testability (each gate leaves the project
in a valid or trivially-revertable state). Every gate is an explicit
"approved / change / stop" decision by the developer.

**Approval gate flow:**

| Gate | What the PM chat presents | What the developer approves |
|---|---|---|
| **G-design** | Clarifying-question answers; draft description of the agent's purpose, scope, read-only/write mode, variants, and any custom skill dependencies | The agent's shape is what was intended |
| **G-files** | Drafts of all three agent files (Claude `.md`, Codex `.toml`, Gemini `.md`) + the prompt file + optional SKILL.md set, side-by-side for review | The files are correctly shaped and the content is right |
| **G-registration** | Proposed additions: PLATFORM-SKILLS.md `## Custom agents` row (and `## Custom skills` rows if applicable); Phase routing table rows in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`; entries for the roster-scan (§10) | Registration surfaces are correct |
| **G-commit** | `git add` list + proposed commit message (`feat: vN — add custom agent x-<name>`); staged files inspection | Commit proceeds (per CLAUDE.md pack rule: no commit without explicit approval) |

A developer who aborts at any gate leaves the project in the state before
that gate — no half-committed files. The pre-G-commit state is in the
working tree (visible via `git status`) but not committed; a `git restore`
reverts cleanly.

### 4.4 Per-path workflow specifics

All three paths converge on the same four approval gates. The path only
affects what happens at G-design and G-files.

**Path 1 — Describe-driven:**
- G-design: PM chat asks the clarifying questions itemized in §11
  Procedure 5.1. No file drafts yet.
- G-files: PM chat generates all three agent files from scratch plus the
  prompt file.

**Path 2 — One-tool-format seed:**
- G-design: PM chat reads the seed file, extracts purpose/tools/variants,
  drafts the clarifying-question answers from the seed, asks follow-ups
  only where the seed is silent (e.g., if the seed is a Claude `.md`, the
  PM chat asks about Codex `sandbox_mode` and Gemini `temperature` /
  `max_turns`).
- G-files: PM chat emits the seed file (possibly lightly normalized to pack
  conventions) plus the other two tool forms, plus the prompt file.

**Path 3 — Existing-file adoption:**
- G-design: PM chat reads the existing file, reviews it against pack
  conventions, lists deviations (e.g., missing `allowed-tools`, wrong
  filename pattern, no variants marked). Asks the developer to confirm
  rewrites.
- G-files: PM chat emits the rewritten file in its correct tool directory
  plus the other two tool forms and the prompt file.

### 4.5 How the workflow works on all four PM chat surfaces

| Surface | File writes | Notes |
|---|---|---|
| Claude Code CLI | Native `Write` tool | Live detection picks up new files in `.claude/agents/` and `.claude/skills/` within the same session (Step 2 Fact 2) |
| Codex CLI | Native `ApplyPatch`/`Write` (as the Codex PM chat) | No file-edit hook fires (Step 2 C-3), but Codex auto-discovers `.codex/agents/*.toml` at next session start (Step 2 Fact 1) |
| Gemini CLI | Native file tools | New subagents in `.gemini/agents/` are available in the session (Step 2 Fact 3); `/skills reload` is available for skills |
| Claude Desktop app (Projects) | Via **filesystem MCP** recommended (Step 2 Fact 4, reaffirmed in Step 4 §7.4); fallback is the developer copy-pasting the PM chat's file output into the files | Project knowledge snapshot re-upload is the developer's responsibility after the commit |

This is **PM Chat tool flexibility** (V10-PREDESIGN Part 7 Design
Requirement) discharged explicitly. No part of the workflow requires a
specific CLI; the fallback path on the one surface without native disk
access (Desktop without filesystem MCP) is manual paste, which is already
the pattern for that surface's other file writes (METHODOLOGY.md Part 1,
"Desktop Commander note").

### 4.6 Custom skills: when the PM chat creates them

A custom skill is created only when the custom agent requires
project-specific knowledge that is not covered by any existing pack skill.
Most custom agents load one or more *existing* pack skills plus their own
prompt content; they do not need a new skill.

If a new skill is warranted, the PM chat creates three `SKILL.md` files —
one under each tool's skill directory — with identical `name`,
`description`, and `allowed-tools` frontmatter and identical body. This
matches the pack's current skill-distribution model (one skill →
`.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`,
`.gemini/skills/<name>/SKILL.md`, per the pre-v10 pack structure).

---

## 5. CD-6 and CD-7 — Custom skills and PLATFORM-SKILLS.md Custom section

### 5.1 CD-6 — Custom skills load the same way as pack skills

Confirmed. A custom skill with `SKILL.md` in `.claude/skills/x-<name>/`,
`.codex/skills/x-<name>/`, and `.gemini/skills/x-<name>/` is loaded by an
agent prompt via the same prompt-instruction mechanism as every pack skill
(PLATFORM-SKILLS.md Step 3 text block: `Load the following skills for this
task: …`). No separate loading mechanism exists for custom skills; they
are just more entries on the load list.

Step 2 findings confirm feasibility per tool:

- **Claude Code.** Live change detection picks up new skill directories
  within an already-watched top-level directory. `.claude/skills/` already
  exists (pack ships it), so `.claude/skills/x-<name>/SKILL.md` is picked
  up without restart (Step 2 Fact 2 §1, §2).
- **Gemini CLI.** Progressive disclosure loads metadata at session start;
  `/skills reload` refreshes during a session (Step 2 Fact 3 §5). The `x-`
  prefix satisfies the name-slug rule.
- **Codex CLI.** Codex skills are documented at
  https://developers.openai.com/codex/skills (Step 2 "Unverified / follow-up
  items" 3). A targeted verification before BD-046 merge is required (§18.3
  hand-off) but the expectation is consistent with the other two tools; no
  design decision in this step depends on a contradictory answer.

### 5.2 CD-7 — PLATFORM-SKILLS.md gets `## Custom skills` (and `## Custom agents`) sections

Confirmed with one addition. **Two** sections are added, not one, because
the custom-file population can include agents without a custom skill.
Section header and column structure are specified in §12.

### 5.3 Rejected alternatives

- **Separate file for custom skills** (e.g., `docs/pack/CUSTOM-SKILLS.md`).
  Rejected — PLATFORM-SKILLS.md is already the PM chat's skill-selection
  reference and is read at prompt generation time. A second file
  doubles the read surface and the maintenance surface.
- **Load custom skills by auto-scanning `x-` directories at prompt time.**
  Rejected — automatic inclusion would defeat the "not visible until
  registered" property from §3.3. An agent prompt's skill list is an
  explicit, reviewed set; custom skills must earn their place in the
  PLATFORM-SKILLS.md table before the PM chat loads them.

---

## 6. CD-9 — Custom prompts in the prompts/ directory

### 6.1 Decision

CD-9 confirmed. Custom prompt files live at
`project-template/docs/pack/prompts/x-<name>.md` (in the pack) and
`docs/pack/prompts/x-<name>.md` (in a project) under the Step 4 §4 format.

### 6.2 Compatibility with Step 4 format

Step 4 §4.5 already specifies that `x-<name>.md` files in the prompts
directory follow the same frontmatter-plus-variants format as pack prompt
files, and that validate-pack.py's format check applies to them uniformly.
No change to Step 4 is required.

**Worked example** (the PM chat renders this when creating a custom agent
named `deployer`):

```markdown
---
agent: x-deployer
variants:
  - standard
  - dry-run
---

# x-deployer — prompt templates

Custom agent for packaging a release build and pushing to staging.

## Variant: standard

*Generated by PM chat when the developer requests a deploy to staging.*

You are the deployment specialist for this repository. Load the skills
specified by the PM chat for this task. …

## Variant: dry-run

…
```

The frontmatter `agent: x-deployer` matches the filename stem
(`x-deployer.md`), satisfying Step 4 §4.5 rule 2. validate-pack.py's
prompts-directory check applies without modification.

### 6.3 Step 4 §8.1 hand-off discharged

Step 4 explicitly handed to Step 5 the classification rule for files in
`docs/pack/prompts/`. The detection workflow in §10 discharges this.

---


## 7. OQ-1 — Authoritative pack roster mechanism

### 7.1 Decision

**Hardcoded pack-agent roster section in `docs/pack/PM-CHAT.md`**, enforced
against the actual `project-template/.claude/agents/` directory by
validate-pack.py. The roster is the list of agent filename stems the PM chat
treats as "this is a known pack agent; do not classify as custom."

One fact, one file. No new file is introduced. PLATFORM-SKILLS.md is *not*
used as the roster source — see 7.4.

### 7.2 Section shape (in PM-CHAT.md, added to the pack template and shipped to every project)

Added near the top of PM-CHAT.md, after "Role" and before "Before starting
a new project":

```markdown
## Pack agent roster

The following are the canonical v10 pack agents. Any agent file whose stem
is NOT in this list and does NOT begin with `x-` is an improperly-added
agent (see "Detection of improperly added files" below).

- architect
- auditor
- auditor-architecture
- auditor-code
- auditor-docs
- auditor-ops
- auditor-security
- auditor-tests
- auditor-ui
- coder
- docs-researcher
- grpc-schema
- planner
- repo-ops
- reviewer
- tester
```

The list is sorted lexicographically. When a future pack version adds or
removes a pack agent, PM-CHAT.md is updated in the same commit.

### 7.3 Drift and maintenance characteristics

| Property | Value |
|---|---|
| Where the roster lives | `project-template/docs/pack/PM-CHAT.md` § "Pack agent roster" |
| Who reads it | PM chat, at startup and at phase-gate scans (§10) |
| Who updates it | Pack chat, when a pack agent is added or removed |
| Drift risk — roster out of sync with `.claude/agents/` | Caught by validate-pack.py (new check, §15) in pack CI |
| Drift risk — pack upgrade leaves a stale roster in a project | Mitigated by Step 6 migration: `docs/pack/PM-CHAT.md` is part of the pack-owned `docs/pack/` files replaced on upgrade. The new pack's PM-CHAT.md has the new roster |
| Drift risk — a developer hand-edits PM-CHAT.md's roster | Detection scan misclassifies. Mitigation: PM-CHAT.md ships with the comment "edits to this section are managed by the pack chat; do not modify" |
| Trinity rule | Not applicable — PM-CHAT.md is a single-tool-agnostic file, not in the CLAUDE/AGENTS/GEMINI trinity |

### 7.4 Rejected alternatives

- **Derive roster from PLATFORM-SKILLS.md agent rows.** Rejected — the
  "Agents and their skill assignments" section in PLATFORM-SKILLS.md is
  human prose with irregular spacing (see the file's current state,
  lines 148–214). Parsing it reliably requires more structure than a clean
  list. A robust parser would be a new dependency; a brittle parser would
  be a drift source. A hardcoded list has no parse layer.
- **New registry file** (e.g., `docs/pack/AGENT-ROSTER.md`). Rejected —
  adds a third place to keep the agent list (directories → PM-CHAT.md →
  new file). Elegance preference: fewer files, fewer conventions.
- **Derive from the filesystem at runtime** (`ls .claude/agents/`
  subtracting `x-*`). Rejected — the runtime filesystem state is precisely
  what the roster is used to classify; using it as the roster is circular.
  It also fails on Claude Desktop + Project Knowledge, which has no
  `ls` equivalent (Step 4 §5.4).

### 7.5 Why this resolves OQ-1

OQ-1 asked three questions: what is the roster, is the routing table
sufficient, what if it drifts. Answers:

- The roster is the `## Pack agent roster` bulleted list in PM-CHAT.md.
- The Phase routing tables in CLAUDE.md / AGENTS.md / GEMINI.md are *not*
  the roster. They receive custom agent entries (§14); mixing them with
  the roster would force the PM chat to distinguish pack rows from custom
  rows inside the same table — a new parse problem.
- Drift is caught by a new validate-pack.py check (§15.2) that compares
  the PM-CHAT.md roster to the actual agent directories.

---

## 8. OQ-2 — Codex config.toml registration (resolved per Step 2 C-1)

### 8.1 Decision

No per-agent `[agents.<name>]` registration entry in `.codex/config.toml`
exists in documented Codex. The PM chat creates **only** the
`.codex/agents/x-<name>.toml` file when provisioning a Codex custom agent.
Codex auto-discovers the file by its `name` field (Step 2 Fact 1).

The V10-PREDESIGN Part 4 row "`project-template/.codex/config.toml` —
Custom agent registration documentation" is **removed**.
The V10-PREDESIGN Part 5 PM-chat-workflow sub-step "PM chat adds
`[agents.x_name]` entry" is **removed**.
Step 8 (touch-point consolidation) inherits these removals.

### 8.2 What remains in `config.toml`

The global `[agents]` table (Step 2 Fact 1 §2) — `agents.max_threads`,
`agents.max_depth`, `agents.job_max_runtime_seconds` — is a separate
concern, unaffected by v10. The pack's current `.codex/config.toml` does
not set these. If a project chooses to tune them, that is a project
configuration choice independent of any custom agent.

### 8.3 Consistency scan is dropped

V10-PREDESIGN OQ-2 anticipated a "consistency scan" — detect when
`.toml` file exists but `config.toml` entry is missing, or vice versa. Per
Step 2 C-1, this scan is chasing a non-existent requirement. It is dropped
from the detection workflow (§10).

### 8.4 What the detection scan does check for Codex

The detection scan (§10) classifies `.codex/agents/*.toml` files by the
same roster-vs-prefix rules as the other two tools:

- Filename stem in PM-CHAT.md pack roster → pack agent (OK).
- Filename begins with `x-` → custom agent (then: registered or
  unregistered, depending on the other artifacts).
- Neither → improperly added.

No cross-check against `config.toml` is performed.

---

## 9. OQ-8 — x- prefix future collision policy

### 9.1 Decision

The `x-` filename namespace is **reserved for project customizations**. The
pack itself will not ship any agent, skill, or prompt file whose name
begins with `x-` in any of its template directories. This reservation is
enforced by validate-pack.py (§15.3) so a future pack version cannot
accidentally introduce an `x-` pack file.

### 9.2 Corollary for the hypothetical collision in OQ-8

OQ-8 named two cases. Both are handled:

- **Project creates `x-deployer.md`; future pack adds `deployer.md`.** No
  filename collision (`x-deployer` ≠ `deployer`). Both coexist; the PM
  chat's roster scan treats `x-deployer` as custom and `deployer` as pack.
- **Project creates `x-auditor-perf.md`; future pack adds `auditor-perf.md`.**
  No filename collision. Conceptual overlap ("two auditor-perf things")
  is handled at design time by the PM chat: when a future pack version
  adds an agent whose domain matches an existing `x-` customization, the
  migration workflow surfaces both in the "custom files in this project"
  review so the developer can decide whether to retire the custom or keep
  both. That is a migration-script concern (Step 6) not a design-time
  collision.

### 9.3 Why reservation (vs. collision handling only)

A collision-only policy (no reservation) would require the detection scan
to special-case a file named `x-foo.md` that IS a pack file and another
`x-foo.md` that is NOT. Reserving the prefix removes that branch entirely.
One rule, one direction: `x-` means custom, always.

### 9.4 CI rule added in §15.3

validate-pack.py gains a rule: any file in a pack template directory
(`project-template/.claude/agents/`, `project-template/.codex/agents/`,
`project-template/.gemini/agents/`, every `project-template/.*/skills/*/`,
and `project-template/docs/pack/prompts/`) whose filename or directory
name begins with `x-` fails validation.

---

## 10. Detection workflow

### 10.1 When the scan runs

| Trigger | Scope | Why |
|---|---|---|
| PM chat startup (`/pm-startup` or tool-native equivalent) | Full scan (all directories in 10.2) | Session start — the PM chat's context must reflect the actual on-disk state. Lesson 5 — maintenance-docs included: PM chat also sanity-checks prompts dir |
| Phase-gate check (METHODOLOGY.md Procedure 1 new step; see §11 / Procedure 5.4) | Full scan | Prevents a manual addition made between sessions from silently affecting the next phase's prompts |
| Custom-agent creation workflow (§4, G-design) | Same-name pre-check only | Before drafting files, PM chat verifies no file for the proposed name already exists (prevents accidental overwrite) |

Step 2 C-3 confirmed no Codex file-edit hook fires; Step 2 Fact 2 confirmed
Claude Code has live detection for skills/agents (session-local only, not
a PM-chat-level signal). A PM-chat-level scan is the only
cross-tool-consistent mechanism, run at the times above.

### 10.2 Directories scanned

1. `.claude/agents/*.md`
2. `.codex/agents/*.toml`
3. `.gemini/agents/*.md`
4. `.claude/skills/*/SKILL.md`
5. `.codex/skills/*/SKILL.md`
6. `.gemini/skills/*/SKILL.md`
7. `docs/pack/prompts/*.md`

No other directories are part of the detection scope.

### 10.3 Classification rules

For each file found in the seven scan locations:

| Observed | Classification | PM chat action |
|---|---|---|
| Filename stem is in PM-CHAT.md pack-agent roster (agents) / pack-skill roster (skills) / Step 4 §2.3 pack-prompt roster (prompts) | **Pack** | OK — no action |
| Filename stem / directory name begins with `x-` AND all registration artifacts present (see 10.4) | **Registered custom** | OK — no action |
| Filename stem / directory name begins with `x-` AND some registration artifact missing | **Unregistered custom** | Flag to developer; offer to complete registration via Procedure 5 |
| Filename stem / directory name does NOT begin with `x-` AND NOT in pack roster (and NOT the prompts-dir exemption list — see 10.5) | **Improperly added** | Flag; explain invisibility (§3.3); offer to rename-to-`x-` and register via Procedure 5 |

### 10.4 What "registration artifacts present" means for a registered custom agent

For an `x-<name>` custom agent to be classified as Registered, **all** of:

1. `.claude/agents/x-<name>.md` exists with valid YAML frontmatter
   (`name: x-<name>`).
2. `.codex/agents/x-<name>.toml` exists with valid TOML (`name = "x-<name>"`).
3. `.gemini/agents/x-<name>.md` exists with valid YAML frontmatter
   (`name: x-<name>`).
4. `docs/pack/prompts/x-<name>.md` exists and passes Step 4 §4.5 validation.
5. PLATFORM-SKILLS.md `## Custom agents` section contains a row for
   `x-<name>` (§12.1).
6. CLAUDE.md / AGENTS.md / GEMINI.md Phase routing tables each contain a
   row for `x-<name>` in the `## Custom agents` sub-section (§14).

For an `x-<name>` custom skill to be classified as Registered, **all** of:

1. `.claude/skills/x-<name>/SKILL.md` exists with valid frontmatter.
2. `.codex/skills/x-<name>/SKILL.md` exists with valid frontmatter.
3. `.gemini/skills/x-<name>/SKILL.md` exists with valid frontmatter.
4. PLATFORM-SKILLS.md `## Custom skills` section contains a row for
   `x-<name>` (§12.2).

If any of the above is missing, the file set is Unregistered and the PM
chat surfaces the gap.

### 10.5 Prompt-directory exemption list

Per Step 4 §8.1 hand-off, the prompt-directory scan exempts one
non-agent file from agent-roster comparison:

- `docs/pack/prompts/pm-chat.md` — PM chat operational templates file.
  Frontmatter `agent: pm-chat` is a reserved non-agent identifier (Step 4
  §4.2 table). The detection scan lets it pass.

All other non-`x-` files in the prompts directory must match Step 4 §2.3
(`coder.md`, `reviewer.md`, …). Anything else is Improperly added.

### 10.6 What the PM chat says when flagging

Concrete phrasing for each class, so METHODOLOGY.md Procedure 5 can quote
it verbatim:

- **Unregistered custom:** "I found `x-<name>` files at
  `<paths>` but the registration is incomplete: missing `<specifics>`. Do
  you want me to complete registration? (This will produce drafts of the
  missing artifacts for your review before committing.)"
- **Improperly added:** "I found `<path>` which is not a pack agent and
  does not begin with `x-`. This file is currently invisible to the PM
  chat's prompt generation and routing. Do you want me to adopt it as a
  custom agent? That would rename it to `x-<name>` and produce the missing
  companion files and registration entries."

### 10.7 pm-startup and phase-gate integration

- **pm-startup** (skills/pm-startup/SKILL.md gains a new Step): scan the
  seven directories, apply classification rules from 10.3, include the
  summary line in the pm-startup ready report: either
  `Agent/skill/prompt scan: OK` or
  `Agent/skill/prompt scan: N unregistered, M improperly added — see
  details above`. The per-file details are printed before the ready line.
- **Phase-gate** (METHODOLOGY.md Procedure 1 gains step 5a, or uses the
  existing step 5 Orphan audit as a sibling): run the same scan. If any
  non-OK classifications are found, pause prompt generation until the
  developer decides to register, adopt, or defer. "Defer" is allowed — the
  PM chat flags and continues, and the file remains invisible.

---


## 11. Procedure 5 outline for METHODOLOGY.md

To be added as a new procedure in METHODOLOGY.md Part 7 ("BACKLOG and TODO
Management"), immediately after Procedure 4. Section header
**"Procedure 5 — Custom agent and skill workflow."** Full text is
implementation content (Phase 4); this step produces the outline.

### Procedure 5.1 — Creating a custom agent

Triggered when the developer asks the PM chat to add a custom agent.

1. **Pre-check** (G-design): verify no `.claude/agents/x-<name>.md`,
   `.codex/agents/x-<name>.toml`, `.gemini/agents/x-<name>.md`, or
   `docs/pack/prompts/x-<name>.md` already exists for the proposed name. If
   any exist, stop and route to Procedure 5.3 (completing a partial
   registration) instead.
2. **Clarifying questions.** Purpose of the agent; primary phase in the
   methodology this agent serves; read-only or write-enabled; whether it
   needs Bash / Web / MCP tools; how many prompt variants; does it load
   any existing pack skills, or does it require a new custom skill; what
   agent the PM chat would have routed to absent this custom (context for
   the routing-table row).
3. **Drafts** (G-files). PM chat drafts all four files (Claude, Codex,
   Gemini, prompt) and presents side-by-side. Developer reviews and
   approves, or asks for changes — iterate until approved.
4. **Registration drafts** (G-registration). PM chat drafts the
   PLATFORM-SKILLS.md `## Custom agents` row, the
   CLAUDE.md / AGENTS.md / GEMINI.md Phase routing table rows (trinity
   rule applies — three identical rows in three files), and (if a custom
   skill is involved) the `## Custom skills` row plus the three SKILL.md
   files. Developer approves.
5. **Commit** (G-commit). PM chat presents `git add` list and commit
   message; per CLAUDE.md pack rule the developer explicitly approves
   before the commit runs. One commit, all artifacts.

### Procedure 5.2 — Creating a custom skill (standalone)

Triggered when the developer asks the PM chat to add a custom skill
*without* a custom agent (an existing pack agent or `x-` custom agent
will load it).

1. Pre-check: no `x-<name>` skill directory exists in any of the three
   tool skills directories.
2. Clarifying questions. Purpose; which agents will load it; what
   `allowed-tools` it needs.
3. Drafts (G-files). Three SKILL.md files with identical frontmatter and
   body content, one under each tool's skill directory. Developer
   approves.
4. Registration drafts (G-registration). `## Custom skills` row in
   PLATFORM-SKILLS.md naming which agents load the skill. Developer
   approves.
5. Commit (G-commit). Same rule as 5.1 step 5.

### Procedure 5.3 — Completing a partial registration (Unregistered)

Triggered when the detection scan (§10) reports an Unregistered custom
agent or skill.

1. PM chat lists the files present and the artifacts missing (per §10.4).
2. Developer approves reconstruction of the missing artifacts. PM chat
   drafts the missing tool forms (e.g., developer wrote a Claude agent
   manually; Codex and Gemini forms are generated), the prompt file (if
   missing), and the PLATFORM-SKILLS.md / routing-table entries.
3. PM chat presents the full registration set for approval at
   G-registration.
4. Commit at G-commit.

### Procedure 5.4 — Adopting an improperly-added file

Triggered when the detection scan reports an Improperly added file
(non-`x-`, not in pack roster).

1. PM chat confirms invisibility consequence (per §3.3 / §10.6 phrasing).
2. Developer chooses: **Adopt as custom** (rename to `x-<name>`, proceed
   to Procedure 5.3), **Remove** (delete; PM chat produces the `git rm`
   commands for approval per CLAUDE.md destructive-op rule),
   **Defer** (leave as-is; file stays invisible, scan continues to flag
   at every subsequent trigger).

### Procedure 5.5 — Detection scan as a phase-gate step

The phase-gate check in Procedure 1 gains a sub-step (numbered 5a to sit
beside the existing "5. Run orphan audit"):

> **5a. Run custom-file detection scan (Procedure 5 §10).** If any
> unregistered or improperly-added files are found, pause and route to
> the appropriate sub-procedure (5.3 or 5.4). Developer may Defer; do not
> block the phase on unregistered custom files if the developer
> explicitly chooses Defer, but do not include those files in the
> upcoming prompt generation either.

### Procedure 5.6 — Reference tables

The procedure ends with two reference tables copied from §10.4 of this
design — "Registration artifacts for a custom agent" and "Registration
artifacts for a custom skill" — so a developer reading Procedure 5
directly can answer "is my custom agent properly registered?" without
cross-referencing another document.

---

## 12. PLATFORM-SKILLS.md — `## Custom agents` and `## Custom skills` sections

### 12.1 Exact header, column structure, and example for `## Custom agents`

Added to `project-template/docs/pack/PLATFORM-SKILLS.md`, immediately
after the current `## Full skill inventory` section (so pack-roster
content stays together above the custom content).

```markdown
## Custom agents

Project-specific agents created via Procedure 5 (METHODOLOGY.md Part 7).
All entries in this section begin with `x-`. The PM chat treats these as
equivalent to pack agents for skill loading and routing, with the single
difference that they are project-owned and preserved across pack upgrades.

| Agent | Purpose | Phase routed to | Tier 1 skills | Tier 2 skills | Read/write mode |
|---|---|---|---|---|---|
| `x-deployer` | Release packaging and staging deploy | Repo operations | repo-ops | deployment-apple, deployment-python | write |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5. If a project has no custom agents, the section body is
`*No custom agents defined for this project.*` below the header.*
```

**Column semantics:**

| Column | Meaning | Value constraint |
|---|---|---|
| Agent | Agent stem (backticked) | Must begin with `x-`; regex `^x-[a-z][a-z0-9-]*$` |
| Purpose | One sentence | Free text |
| Phase routed to | Entry that will appear in the Phase column of the trinity Phase routing table | Existing phase name or new row label |
| Tier 1 skills | Comma-separated list of pack role skills the agent loads | Values from the PLATFORM-SKILLS.md Tier 1 inventory |
| Tier 2 skills | Comma-separated list of pack platform skills and/or `x-` custom skills | Values from PLATFORM-SKILLS.md Tier 2 inventory and/or `## Custom skills` section |
| Read/write mode | `read` or `write` | Must match the tool-native sandbox/tools configuration in the agent files |

### 12.2 Exact header, column structure, and example for `## Custom skills`

Added immediately after `## Custom agents`:

```markdown
## Custom skills

Project-specific skills created via Procedure 5 (METHODOLOGY.md Part 7).
All entries in this section begin with `x-`. Loaded by agents via the same
instruction block as pack skills — see "Step 3 — Generate the prompt" above.

| Skill | Description | Loaded by |
|---|---|---|
| `x-brokerage-api` | OT broker-adapter patterns, capability masks, idempotency | reviewer, auditor-code, x-deployer |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5. If a project has no custom skills, the section body is
`*No custom skills defined for this project.*` below the header.*
```

**Column semantics:**

| Column | Meaning | Value constraint |
|---|---|---|
| Skill | Skill stem (backticked) | Must begin with `x-`; regex `^x-[a-z][a-z0-9-]*$` |
| Description | One sentence | Free text |
| Loaded by | Comma-separated agent list — pack agents by stem, custom agents by `x-<name>` | Values must match either PM-CHAT.md pack roster or existing `## Custom agents` rows |

### 12.3 Why both sections live in PLATFORM-SKILLS.md (not split)

PLATFORM-SKILLS.md is already the single document the PM chat reads at
prompt-generation time to resolve "what skills does this agent need"
(Step 1 inputs table referenced §12 of PM-CHAT.md current file-access
strategy). Putting custom agents there keeps the PM chat's read pattern
uniform: one file to answer "is this agent pack-or-custom, and what
skills does it load."

### 12.4 Rejected alternative: separate `## Custom agents` in a different file

A `docs/pack/CUSTOM.md` was considered and rejected for the same reasons
as §5.3 — second read surface, second maintenance surface. Elegance
preference.

---

## 13. PM-CHAT.md additions

Edits to `project-template/docs/pack/PM-CHAT.md` for v10.0:

### 13.1 New `## Pack agent roster` section

Added as specified in §7.2. Position: after `## Role`, before
`## Before starting a new project`.

### 13.2 New `## Custom agent and skill workflow` section

Added after `## Behavioral rules` (lines 107–146 in the current file) and
before `## Tool-specific: Claude Code CLI`. Content summary (full text is
implementation in Phase 4):

- One-paragraph overview stating that custom agents and skills follow
  Procedure 5 in METHODOLOGY.md and are created through this PM chat, not
  manually.
- Pointer to Procedure 5 for the full workflow.
- The detection-and-classification rules from §10 summarized as a short
  behavioral rule the PM chat follows: "At pm-startup and at every phase
  gate, scan the seven detection directories. Flag unregistered `x-` files
  and improperly-added non-`x-` files. Offer Procedure 5.3 or 5.4 as
  appropriate. Developer may Defer; Defer leaves the file invisible and
  the scan continues to flag it."
- One sentence reiterating that no pack agent file or skill directory may
  begin with `x-` (validate-pack.py enforces).

### 13.3 File-access-strategy table additions

The existing File-access-strategy table gains:

| `docs/pack/prompts/<agent>.md` | Direct read (on demand, at generation time) | Step 4 §5.5 already specifies this |
| `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`, `docs/pack/prompts/` | Directory listing (on detection-scan) | §10.2 |

PROMPT-TEMPLATES.md row is removed (Step 4 §6.2).

### 13.4 Behavioral rules additions

Three new bullets under `## Behavioral rules`:

- **Custom files via Procedure 5 only.** When the developer asks for a
  custom agent or skill, follow Procedure 5 in METHODOLOGY.md. Never
  write agent or skill files outside the Procedure 5 approval gates.
- **Detection scan at every startup and every phase gate.** Run the scan
  specified in METHODOLOGY.md Procedure 5 §10 (detection workflow) at
  pm-startup and at Procedure 1 step 5a. Flag or surface findings before
  generating any prompt.
- **Pack roster is in `## Pack agent roster` above.** Use that list as the
  authoritative pack-agent set. Do not infer the roster from any other
  file.

### 13.5 Trinity rule not applicable

PM-CHAT.md is not in the CLAUDE.md / AGENTS.md / GEMINI.md trinity. Edits
to PM-CHAT.md do not require parallel edits in any of those three.

---

## 14. Trinity routing-table additions

The Phase routing table in each of `project-template/CLAUDE.md`,
`project-template/AGENTS.md`, `project-template/GEMINI.md` gains a
sub-section at the end:

```markdown
### Custom agents

Project-specific agents created via Procedure 5. See
`docs/pack/PLATFORM-SKILLS.md` § "Custom agents" for the canonical list
and full skill assignments. All custom agent names begin with `x-`.

| Phase | Agent | Key reason |
|---|---|---|
| (Developer / PM chat adds rows per project during Procedure 5) |  |  |
```

When Procedure 5 creates a custom agent, the PM chat adds the row to all
three trinity files in the same commit. V9 Lesson 3 (trinity-rule
validated per tool, in identical wording across CLAUDE.md / AGENTS.md /
GEMINI.md) applies; the per-tool asymmetries (Claude Task tool syntax,
Gemini `@agent` invocation) are already handled below the Phase routing
table in each file's existing content and are not touched by the custom
agent rows.

### 14.1 Why rows go in the existing Phase routing table (subsection), not a separate table

The PM chat already reads the Phase routing table when generating prompts
for any phase-bound agent (see CLAUDE.md §"Phase routing" / `./agent-run.sh
<cli> --agent <name>` pattern). Adding custom rows to the same table keeps
the read pattern uniform. A sub-section `### Custom agents` at the end of
the table keeps pack rows visually separated from custom rows without
requiring a second table for the PM chat to parse.

### 14.2 Rejected alternative

- **New `### Custom agents` table in each trinity file with a different
  shape.** Rejected — the Phase/Agent/Key-reason columns are the same
  three the pack agents use; a separate table would duplicate the column
  definitions with no added value.

---

## 15. validate-pack.py updates

### 15.1 Prompts-directory check (from Step 4 §4.5)

Already specified in Step 4 §4.5. This step does not modify that
specification.

### 15.2 PM-CHAT.md pack-agent-roster consistency

New check: read `project-template/docs/pack/PM-CHAT.md` `## Pack agent
roster` section, parse the bullet list. Compare the parsed set against
the set of `.md` filename stems in `project-template/.claude/agents/`.
Fail if they differ. (Check 5 in validate-pack.py already enforces
Claude / Codex / Gemini agent-directory parity, so comparing to Claude
alone is sufficient.)

### 15.3 Reserved `x-` prefix rule for the pack

New check: for each of
- `project-template/.claude/agents/*.md`
- `project-template/.codex/agents/*.toml`
- `project-template/.gemini/agents/*.md`
- `project-template/.claude/skills/*/`
- `project-template/.codex/skills/*/`
- `project-template/.gemini/skills/*/`
- `project-template/docs/pack/prompts/*.md`

fail validation if any filename or directory name begins with `x-`. The
pack must not ship `x-` files; that namespace is reserved for project
customizations. (This also catches the `## Pack agent roster` in
PM-CHAT.md if it ever lists an `x-` entry.)

### 15.4 Enforcement boundary

These CI checks apply to the **pack repo only**. They do NOT run on
downstream projects. A project that has `x-` files in these directories
is correct, not failing. Only the pack is disallowed from shipping `x-`
files.

---


## 16. V9 lessons applied

### 16.1 Lesson 2 — per-tool CLI behavior not extrapolated

Each of the three CLIs is specified on its own terms using Step 2 verified
facts:

- **Claude Code.** x- prefix works per Step 2 Fact 2 §5. Live change
  detection works within already-watched directories per Fact 2 §1. Skill
  loading behavior per Fact 2 §4 (progressive disclosure — metadata at
  startup, body on invoke). These facts are cited in §1.3, §5.1, and
  §10.1 where they drive a decision.
- **Codex.** No per-agent `config.toml` entry required (C-1 / Fact 1). No
  file-edit hook (C-3 / Fact 6). Hyphenated `name =` accepted (C-2
  resolved by smoke test, per opening context). These facts drive §1,
  §4.2, §8, and §10.1.
- **Gemini.** YAML frontmatter mandatory on agent files (Fact 3 §1).
  Hyphenated name-slug accepted (Fact 3 §2). `/skills reload` available
  (Fact 3 §5). These facts drive §1, §2.1 row 3, and §5.1.

The detection workflow (§10) is specified at the PM-chat layer, not at
any per-tool hook layer, precisely because the three tools have
asymmetric hook guarantees (Claude Code has file-edit hooks, Codex does
not, Gemini hooks not verified in Step 2). Building detection on a
uniform layer above the tools honors Lesson 2.

### 16.2 Lesson 3 — trinity rule validated per tool for custom agent files

The custom-agent workflow (§4.2) produces three tool-native files from the
same design intent, with identical `name`, `description`, and
prompt-body content modulo frontmatter differences and TOML quoting.
Trinity rule applies to the three agent files in the same sense it
applies to pack agents (symmetric; any divergence requires justification).

The trinity rule also applies to the Phase routing-table `### Custom
agents` sub-section added to CLAUDE.md / AGENTS.md / GEMINI.md in §14 —
the same row appears in all three files in the same commit.

The trinity rule does **not** apply to PM-CHAT.md, PLATFORM-SKILLS.md, or
Procedure 5 in METHODOLOGY.md — those are single-file documents read by
the PM chat regardless of the CLI it runs on. Asymmetry is justified for
those files by their tool-agnostic role; symmetry is not meaningful
because there is only one file of each.

### 16.3 Lesson 5 — maintenance-docs references not overlooked

This design expressly includes the following maintenance-docs / operational
touch points that a naive workflow specification would miss:

- **`docs/pack/PM-CHAT.md`** is a pack-owned file (post BD-042) and is
  replaced on upgrade (Step 6 responsibility). The pack-agent-roster
  section must ship with every pack version.
- **`validate-pack.py`** (in pack CI) gains checks in §15 that did not
  exist in v9.x. The pack's own CI must be updated in the same PR that
  introduces the `x-` prefix rule, not as a follow-up.
- **`maintenance-docs/V9-DESIGN.md`** Decision 7 (the current "permitted
  project-level customization" language) becomes partially superseded by
  v10. Per Lesson 4 / Step 4 §6.2 treatment — annotate the V9 reference,
  do not rewrite it.
- **Step 4 §6.2 stale-reference inventory** is the model to follow for
  any v10 document that prescribes "read PLATFORM-SKILLS.md" or "edit
  CLAUDE.md routing table" — the v10 content must audit every such
  reference. Step 8 (touch-point consolidation) is where this audit
  lands; this step does not pre-empt it.

---

## 17. Design requirements addressed

Per V10-PREDESIGN Part 7. Each requirement is discharged by explicit
sections of this step.

### 17.1 Automated and manual workflows

The PM-chat-driven creation (§4, Procedure 5.1 / 5.2) is the automated
path. The manual escape hatch (§3, Procedure 5.3 / 5.4) is the path when
files are created outside the chat. Each path has a clear owner: PM chat
for both, with developer approval gates at G-design / G-files /
G-registration / G-commit. No other actor has creation authority.

### 17.2 Maintenance considerations

Single sources of truth:

- **Pack agent roster** — PM-CHAT.md `## Pack agent roster` (§7.2). One
  file, enforced by CI (§15.2).
- **Custom agents registry** — PLATFORM-SKILLS.md `## Custom agents`
  (§12.1). One file per project.
- **Custom skills registry** — PLATFORM-SKILLS.md `## Custom skills`
  (§12.2). One file per project.
- **Prompt files** — `docs/pack/prompts/` (Step 4 §2.3). One file per
  agent.
- **Pack reservation of `x-` prefix** — validate-pack.py (§15.3). One
  enforcement point.

Custom files are preserved across pack upgrades because they are named
distinctly (§1, CD-1) and because the migration script handles them
explicitly (CD-5, Step 6 hand-off §18.1).

### 17.3 PM Chat tool flexibility

The creation workflow works on all four PM chat surfaces, specified per
surface in §4.5. The detection workflow (§10) is tool-agnostic — a
directory scan and a roster comparison, both of which are expressible in
each tool's file-access idiom (CLI native `ls` / file reads; Desktop with
filesystem MCP; Desktop with Project knowledge via the developer's manual
file upload after changes).

### 17.4 Seamless BD integration

- **With BD-044 (init-project.sh).** A fresh project gets the pack
  PM-CHAT.md with its roster and empty `## Custom agents` / `## Custom
  skills` sections. init-project.sh does not create any `x-` files. See
  Step 7 hand-off §18.2.
- **With BD-045 (capabilities pattern).** BD-045 edits trinity files in
  the LSP section and anti-patterns list (Step 3 deliverable); v10-BD-046
  edits trinity files in the Phase routing table (§14). Different
  sections; no collision. Same commit-ordering concern (Step 11 review)
  applies.
- **With Step 4 (prompt reorg).** Step 4 §4 format is the contract for
  `x-<name>.md` custom prompt files (§6). Step 4 §2.3 file list is the
  pack-prompt roster used in §10.3 classification. Step 4 §8.1 hand-off
  is discharged here.

### 17.5 Resource considerations

Detection scan cost:

- Directory `ls` on seven directories. On a typical project, the agent
  directories hold ~16 files each, skill directories hold ~30 entries
  each, prompts holds ~10 files. Total ~170 directory entries —
  negligible vs. any file read.
- Classification is pure string matching against the roster in
  PM-CHAT.md (parsed once at pm-startup, cached in chat context).
- No file body reads at scan time except for validation of the
  "Registered" status artifacts, which is done on-demand only when a
  flag is raised.

Documents read frequently (PLATFORM-SKILLS.md, PM-CHAT.md) gain
small sections (§12, §13). File sizes stay well within the
direct-read comfort thresholds in Step 2 Fact 5.

---

## 18. Handoffs

### 18.1 To Step 6 (migration design)

Step 6 inherits from this step:

- The `x-` filename convention (§1) is the migration script's marker for
  "preserve across upgrade." CD-5 is implemented as "preserve every file
  or directory whose top-level name in the seven scan directories (§10.2)
  begins with `x-`."
- The pack roster (§7) is the migration script's source of truth for
  "what is a pack file." Pack files are replaced on upgrade; `x-` files
  are preserved.
- PM-CHAT.md `## Pack agent roster` section is pack-owned and IS replaced
  on upgrade. If a pack upgrade adds or removes a pack agent, the
  roster that ships with the new pack version reflects the new list.
- PLATFORM-SKILLS.md `## Custom agents` and `## Custom skills` sections
  are **project-owned**, not pack-owned (they contain the project's
  customizations). Step 6 must specify a merge rule: pack-owned content
  above the two custom sections replaces on upgrade; the two custom
  sections preserve on upgrade. A clear marker (either a comment like
  `<!-- PACK-MANAGED ABOVE / PROJECT-MANAGED BELOW -->` or a rule that
  the sections always appear after `## Full skill inventory` and are
  copied over verbatim) is Step 6's to choose.
- Trinity routing-table `### Custom agents` sub-section is also
  project-owned. Same merge-rule concern applies to trinity files —
  Step 6 specifies.

### 18.2 To Step 7 (BD-044 init-project.sh)

Step 7 inherits from this step:

- `init-project.sh` never creates `x-` files. It copies the pack's
  template directories verbatim, which by §15.3 contain no `x-` files.
- The project's initial state has empty `## Custom agents` and
  `## Custom skills` sections in PLATFORM-SKILLS.md (section headers and
  the "No custom X defined for this project." placeholder line per §12).
- The end-of-run PM chat prompt that init-project.sh emits (per BD-044
  existing-project path) may trigger a first detection scan on the
  project's first pm-startup. On a fresh init the scan will find only
  pack files — OK. On an existing-project import it may find files the
  developer had in `.claude/` or `.codex/` — the scan's Improperly-added
  branch (§10.3 row 4, §10.6) surfaces those for adoption or removal.
- init-project.sh itself does not need the detection scan logic
  embedded — the PM chat runs the scan at first pm-startup after the
  script completes.

### 18.3 To Step 8 (touch-point consolidation)

Step 8 inherits from this step:

- V10-PREDESIGN Part 4 row for `.codex/config.toml` custom agent
  registration is **removed** (§8.1). The corresponding Part 5 workflow
  step is removed.
- V10-PREDESIGN Part 4 rows for `.claude/agents/x-<n>.md`,
  `.codex/agents/x-<n>.toml`, `.gemini/agents/x-<n>.md`,
  `.claude/skills/x-<n>/SKILL.md`, `.codex/skills/x-<n>/SKILL.md`,
  `.gemini/skills/x-<n>/SKILL.md`, `docs/pack/prompts/x-<n>.md`,
  PLATFORM-SKILLS.md `## Custom agents`/`## Custom skills`,
  CLAUDE.md/AGENTS.md/GEMINI.md routing-table additions are **kept** per
  this step's §4.2 and §14.
- New touch points added by this step for Step 8 to inventory:
  - `project-template/docs/pack/PM-CHAT.md` — new sections (§7.2, §13).
  - `project-template/docs/pack/PLATFORM-SKILLS.md` — new sections (§12).
  - `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — routing-
    table sub-section (§14).
  - `supporting-docs/METHODOLOGY.md` — new Procedure 5 (§11).
  - `scripts/validate-pack.py` — new checks (§15).
- Follow-up verification tasks for pack-docs-researcher (hand-off to
  Step 10 verification plan): Codex skill loading with `x-` prefix
  (Step 2 "Unverified / follow-up items" §3); Claude Code `.claude/agents/*.md`
  live reload behavior (Step 2 follow-up §4); Gemini CLI hook model if
  v10 design depends on it (Step 2 follow-up §2).

### 18.4 To Step 10 (verification plan)

Verification items originating in this step:

1. **Creation workflow** — three scripted scenarios (Path 1, Path 2,
   Path 3 from §4.1/§4.4) run on all four PM chat surfaces (§4.5). Each
   produces the six artifacts (§4.2) and the registration rows (§12,
   §14). No `config.toml` edit appears.
2. **Detection workflow** — simulated scenarios for each classification
   class (§10.3): Registered custom; Unregistered custom missing one
   artifact (missing Claude file, missing Gemini file, missing prompt,
   missing PLATFORM-SKILLS row); Improperly added (no `x-` prefix);
   `pm-chat.md` exempt file.
3. **Detection at phase gate** — a file is added between sessions; the
   next phase-gate check surfaces it before prompt generation.
4. **Pack roster consistency** — validate-pack.py §15.2 check catches a
   forged desynchronization (remove an agent file from `.claude/agents/`,
   CI fails).
5. **Reserved `x-` prefix** — validate-pack.py §15.3 check catches an
   `x-` file or directory introduced anywhere in the pack template tree.
6. **Migration preservation** — see Step 6 hand-off §18.1; verification
   is Step 6's to scope.

---

## 19. Summary

- **CD-1 confirmed.** `x-<name>` filename prefix used uniformly across
  Claude, Codex, and Gemini agent files and skill directories, and across
  the `docs/pack/prompts/` directory. Codex `name =` field also uses
  hyphenated `x-<name>` (C-2 resolved by smoke test).
- **CD-2 confirmed** with the operational meaning "identical to that
  tool's pack-file format." The PM chat produces the tool-native form for
  each of the three CLIs.
- **CD-3 confirmed + OQ-7 resolved.** PM chat is the primary creator.
  Detect-and-offer-to-register at pm-startup and phase-gate is the sole
  documented escape hatch. No parallel "manual procedure" is published.
- **CD-4 confirmed.** Three creation paths converge on four approval
  gates (G-design, G-files, G-registration, G-commit). The PM chat
  produces six or nine artifacts per custom-agent request (three agent
  files, prompt file, PLATFORM-SKILLS.md row, trinity routing-table
  rows; plus three SKILL.md files if a custom skill is involved). No
  `.codex/config.toml` edit is created.
- **CD-6 and CD-7 confirmed.** Custom skills load via the same PM-chat
  prompt-instruction mechanism as pack skills; PLATFORM-SKILLS.md gains
  `## Custom agents` and `## Custom skills` sections with the column
  specs in §12.
- **CD-9 confirmed.** `docs/pack/prompts/x-<name>.md` uses the Step 4 §4
  format unchanged.
- **OQ-1 resolved.** Hardcoded `## Pack agent roster` section in
  PM-CHAT.md; validate-pack.py enforces consistency with the actual
  `.claude/agents/` directory.
- **OQ-2 resolved.** Per Step 2 C-1, no `config.toml` edit is required
  or created. The touch-point rows and workflow steps in V10-PREDESIGN
  Parts 4 and 5 that assumed otherwise are removed at Step 8.
- **OQ-8 resolved.** The `x-` prefix namespace is reserved for project
  customizations; validate-pack.py §15.3 prevents the pack itself from
  ever shipping an `x-` file. Hypothetical collisions are handled by
  distinct filenames (§9.2); conceptual overlap is surfaced at migration
  time (Step 6 concern).
- **Detection workflow specified precisely.** Seven directories (§10.2);
  four classification classes (§10.3); exempt file `pm-chat.md` (§10.5);
  phrasing for surfacing each class (§10.6); pm-startup and phase-gate
  integration (§10.7). Runs at the PM-chat level, tool-agnostic, so the
  per-tool hook asymmetry (Step 2 C-3 and Fact 2) does not propagate
  into design.
- **Procedure 5 outlined** for METHODOLOGY.md (§11), with five
  sub-procedures covering creation, skill-only creation, partial
  registration, adoption of improperly-added files, and the phase-gate
  integration step.
- **V9 Lessons 2, 3, 5 applied** (§16).
- **All eight Design Requirements relevant to this step addressed**
  (§17).
- **Handoffs discharged** to Steps 6, 7, 8, and 10 (§18). No unresolved
  OQ left in scope; follow-up verifications (Codex skill x- prefix,
  Claude agent live reload, Gemini hooks) are named for Step 10.

---

*End of step-05-custom-agents.md.*
