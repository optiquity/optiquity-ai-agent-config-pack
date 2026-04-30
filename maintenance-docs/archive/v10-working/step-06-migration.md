# Step 06 — Migration Design (v9.3 → v10.0)

*Report type: Phase-1 / Step 6 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-architect (read-only session).*
*Date: 2026-04-21.*
*Scope: Resolve CD-5, CD-13, and OQ-3; specify the migration script logic, MIGRATION-v9-to-v10.md outline, rollback plan, and the incremental-testability contract. Consumes Step 4 and Step 5 approved deliverables.*

---

## 0. What this report delivers

| Artifact | Status | Section |
|---|---|---|
| CD-5 (migration preserves x- files) — preservation mechanism precisely specified | Confirmed | §1 |
| CD-13 (v9.3 baseline only) — baseline version documented | Confirmed | §2 |
| OQ-3 (prompt template migration for customized projects) | Resolved | §3 |
| PLATFORM-SKILLS.md project-owned sections preservation rule | Specified | §4 |
| Trinity routing-table `### Custom agents` preservation rule | Specified | §5 |
| Rollback plan | Specified | §6 |
| Incremental testability contract | Specified | §7 |
| Migration script logic (stage-by-stage) | Specified | §8 |
| MIGRATION-v9-to-v10.md outline (automatable + manual) | Drafted | §9 |
| V9 Lessons 1 and 4 applied | §10 |
| Design Requirements discharged | §11 |
| Handoffs to Steps 7, 8, 10 and to Phase 3 | §12 |
| Summary | §13 |

---

## 1. CD-5 — Migration preservation mechanism

### 1.1 Decision

Migration preserves `x-` prefixed files by an **in-place skip** mechanism,
not by temp-move-and-restore, and not by a manifest. The migration script
replaces pack-owned files by **removing only the pack-roster set** and
then copying the new pack template — it never does a wholesale
`rm -rf <dir>/` on any directory that can contain `x-` files.

This is the inverse of the v8→v9 pattern, which used
`rm -rf .claude/agents/ && cp -r ...`. That pattern destroys custom
files. v10 cannot use it.

### 1.2 Directories scanned and treated

The seven detection directories from Step 5 §10.2 are the complete scope:

1. `.claude/agents/*.md`
2. `.codex/agents/*.toml`
3. `.gemini/agents/*.md`
4. `.claude/skills/*/` (directory-level)
5. `.codex/skills/*/` (directory-level)
6. `.gemini/skills/*/` (directory-level)
7. `docs/pack/prompts/*.md`

The migration script operates on each with the same three-bucket rule:

| File/directory classification | Migration action |
|---|---|
| **Pack file** (filename stem / dir name is in the v10 pack roster) | Replace with v10 pack version |
| **`x-` prefixed file** (project customization) | **Preserve in place.** Do not touch, do not copy over, do not rename |
| **Anything else** (non-pack, non-`x-`) | **Flag and preserve in place.** Do not remove. Surface in the post-migration report so the developer decides (Procedure 5.4 — adopt, remove, or defer) |

The v10 pack roster comes from two sources, both authoritative:
- **Agents:** `project-template/docs/pack/PM-CHAT.md` § "Pack agent
  roster" (Step 5 §7.2). Migration script reads it from the pack, not
  from the project's (pre-migration) copy.
- **Prompts:** Step 4 §2.3 file list (`coder.md`, `reviewer.md`,
  `tester.md`, `planner.md`, `docs-researcher.md`, `architect.md`,
  `grpc-schema.md`, `repo-ops.md`, `auditor.md`, `pm-chat.md`).
- **Skills:** the pack's own `project-template/skills/` directory names
  (enumerated at migration time from `ls "$PACK/project-template/skills/"`).

### 1.3 Per-directory replacement recipe

For each of directories 1–3 (agents) and 4–6 (skills), the migration
script performs a **selective replace** rather than `rm -rf`:

```text
# Conceptual pseudocode — concrete shell in §8
for tool in claude codex gemini:
    for pack_agent in $(ls "$PACK/project-template/.${tool}/agents/"):
        # Remove the project's copy of this specific pack agent (if present)
        rm -f ".${tool}/agents/$pack_agent"
        # Copy the v10 version
        cp "$PACK/project-template/.${tool}/agents/$pack_agent" ".${tool}/agents/$pack_agent"
    # x- files untouched: the script never names them and never rm -rf's the dir.

    for pack_skill in $(ls "$PACK/project-template/skills/"):
        rm -rf ".${tool}/skills/$pack_skill"
        cp -r "$PACK/project-template/skills/$pack_skill" ".${tool}/skills/$pack_skill"
    # x- skill dirs untouched: never named, never rm -rf'd.
```

For directory 7 (`docs/pack/prompts/`):

```text
# This directory does not exist in v9.3. Created fresh by the migration.
mkdir -p docs/pack/prompts
# Copy all 10 canonical pack prompt files from $PACK
cp "$PACK/project-template/docs/pack/prompts/"*.md docs/pack/prompts/
# x- prompts cannot exist in v9.3 (the directory did not exist).
# In any v10.x+ migration that re-runs this step, the directory will
# exist and may contain x- files: the same selective-replace rule
# applies.
```

### 1.4 Why in-place skip, not temp-move-and-restore

Three failure modes are avoided:

- **Interrupted migration.** A temp-move-and-restore pattern leaves the
  custom files in a temp directory if the script fails between move
  and restore. In-place skip can never strand custom files — they
  never leave their destination.
- **Partial restore bugs.** A move-then-restore contract has two write
  sides. If the restore path is buggy, custom files land in the wrong
  place. Selective-replace has one write side (replace pack files);
  custom files are untouched by construction.
- **Audit trail.** `git status` after the script runs shows precisely
  which pack files changed and which custom files are unchanged.
  Move-then-restore muddles this because every custom file appears as
  a delete-plus-recreate in the working tree at intermediate steps.

### 1.5 What happens to files that are neither pack nor x- prefixed

These are **improperly-added files** from Step 5 §10.3 row 4 — files
that exist on disk in a scanned directory but are neither in the pack
roster nor prefixed `x-`. The migration script:

1. Does **not** remove them.
2. Does **not** attempt to register or rename them.
3. Records them in the migration report (§8.7) under "Files present but
   unclassified — the PM chat will surface these at first post-migration
   `pm-startup` per Procedure 5.4."
4. Continues.

The migration script does not invoke Procedure 5.4 itself. Procedure 5.4
runs inside the PM chat after the migration commits. That is the only
place a developer is asked to adopt / remove / defer — migration is not
the right moment for that decision because the PM chat is not yet running
against the v10 configuration.

### 1.6 Failure modes explicitly surfaced by the migration

| Condition | Migration behavior |
|---|---|
| An `x-` file exists but is malformed (e.g., invalid frontmatter) | Preserve as-is. Note in the migration report. The PM chat's first post-migration scan (Step 5 §10) will surface it as Unregistered — Procedure 5.3 handles it |
| A pack-named file has been hand-edited by the developer | Replaced by the v10 version. Migration report calls out every pack-named file replaced; developer can inspect the `git diff` before committing. See §6 for rollback |
| A pack skill directory contains an `x-` file inside an otherwise pack-named skill (e.g., `.claude/skills/planning/x-extra.md`) | Not expected by CD-1 (custom skills are whole directories, not files inside pack skills), but if it occurs: the pack skill directory is `rm -rf`'d, so the stray `x-` file is lost. Migration report flags any such case detected in the pre-flight scan (§8.2) so the developer can move it to a proper `x-<name>/SKILL.md` before the migration proceeds. Migration stops until resolved |
| `.codex/config.toml` contains `[agents.<name>]` per-agent entries (hand-written speculatively by the developer based on V10-PREDESIGN) | Step 5 §8 confirmed these do not exist in documented Codex. If present, migration leaves them — they are no-ops. Migration report notes them |
| `docs/pack/PROMPT-TEMPLATES.md` has been customized (OQ-3) | Backup and split per §3 |

---

## 2. CD-13 — Migration baseline is v9.3, exactly

### 2.1 Decision

The sole supported migration baseline is **v9.3** (git tag `v9.3`,
released April 2026, the fourth minor in v9). No earlier v9 minor
(v9.0, v9.1, v9.2) is a supported baseline.

### 2.2 Rationale

V10-PREDESIGN Part 6 documents that "all existing projects are on the
latest v9.x release." The only floating tag is `v9`, which per CLAUDE.md
versioning rules always points at the latest v9 minor — currently v9.3.
CHANGELOG.md confirms v9.3 is the latest minor; no v9.4 exists.
README.md's version table lists v9.0 → v9.1 → v9.2 → v9.3 as shipped.

A single baseline is simpler to test (one migration path), simpler to
document (one MIGRATION-v9-to-v10.md), and simpler to support (no
per-source-version branching logic).

### 2.3 What "v9.3 baseline" means concretely for the migration script

The migration script assumes the project's current state matches the
v9.3 pack:

- Agent directories contain 16 pack agents (from v9.3's BD-043 Gemini
  native-subagent rework): coder, reviewer, tester, planner,
  docs-researcher, grpc-schema, architect, repo-ops, auditor, and the
  seven auditor subagents (auditor-architecture, auditor-code,
  auditor-docs, auditor-ops, auditor-security, auditor-tests,
  auditor-ui). All three tools have all 16.
- Skill directories contain 30 pack skills (v9.0 baseline count,
  unchanged through v9.3).
- `docs/pack/` contains METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md,
  PLATFORM-SKILLS.md, PACK-FEEDBACK.md (v9.2's BD-042 relocation).
- `.codex/config.toml` has the v9 registry (16 agents, `max_depth = 2`).
- Scripts match the v9 post-patch state (v9-dev fixes for skills
  distribution and Gemini/Codex agent-run.sh — see `802787f` and
  `5d3f15b`).
- Trinity files contain the v9.1 "Active skills" line (BD-038) in the
  Skill loading section.
- PM-CHAT.md contains the v9.1 "Before starting a new project" section
  (BD-041) and the `a795abb` STATUS.md phase-title linking rule.
- PROMPT-TEMPLATES.md Template 8 contains the `a795abb` STATUS.md
  phase-title linking rule (OQ-3 concrete example).

### 2.4 How the script verifies the baseline

Pre-flight check (§8.2) confirms the following invariants before any
write:

1. `docs/pack/PROMPT-TEMPLATES.md` exists (if missing, the project is
   on an older pre-v9.2 layout and not supported).
2. `.claude/agents/` contains at least the 16 v9.3 pack agent stems.
3. `.gemini/agents/` exists and contains `.md` files (not absent, as in
   v9.0–v9.2).
4. `PLATFORM-SKILLS.md` path is `docs/pack/PLATFORM-SKILLS.md` (v9.2+),
   not project root (v9.0–v9.1).

If any invariant fails, the script prints a diagnostic and refuses to
proceed. It names the expected v9.3 state and the path to the older
migration guide if one ever exists in the future (none today — older
projects must migrate manually first, which is outside v10 scope per
CD-13).

### 2.5 Non-goal — multi-version baseline

The script does **not** attempt to normalize a v9.0, v9.1, or v9.2
project to a v9.3-equivalent state first. If that is ever needed, a
separate v9.x-to-v9.3 guide can be written later, but v10 assumes the
project is already at v9.3.

---

## 3. OQ-3 — Prompt template migration for customized projects

### 3.1 Decision

The migration handles `docs/pack/PROMPT-TEMPLATES.md` in two linked
passes:

1. **Diff against v9.3 baseline.** The migration script diffs the
   project's `docs/pack/PROMPT-TEMPLATES.md` against the pack's own
   v9.3-tagged `supporting-docs/PROMPT-TEMPLATES.md` (retrieved from
   the pack repo — the script asks the developer for the pack repo
   path, same as v8→v9).
2. **If identical to v9.3 baseline:** split mechanically using the
   Step 4 §1.2 destination map — each `## Template N` block goes to its
   designated per-agent file at the designated `## Variant: <slug>`
   heading. No developer involvement beyond approval. Delete
   `docs/pack/PROMPT-TEMPLATES.md` from the project (with backup per
   §6).
3. **If diverged from v9.3 baseline:** proceed with the same mechanical
   split, then **additionally** save the full original as
   `docs/pack/prompts/_v9-backup.md` (a reserved filename in the
   prompts directory). Write a migration report entry naming the
   divergence, and route the post-migration PM chat to Procedure 5-R
   (reconciliation; §3.5) at first startup.

This is the "backup-and-reconcile fallback" that V10-PREDESIGN OQ-3
named as the default fallback.

### 3.2 How the diff is computed

- Source of truth for v9.3 baseline:
  `$PACK/supporting-docs/PROMPT-TEMPLATES.md` **at git tag v9.3**. The
  script verifies the tag: it runs `git -C "$PACK" rev-parse v9.3` and
  `git -C "$PACK" show v9.3:supporting-docs/PROMPT-TEMPLATES.md` rather
  than trusting the checked-out state of the pack (which may be a v10
  branch). If the pack repo lacks a v9.3 tag, the script stops.
- Comparison: byte-exact after whitespace-normalization (trailing
  spaces stripped, CRLF → LF). No semantic diffing. Either identical or
  not.

### 3.3 Carrying forward v9.x incremental additions

The v9.3 baseline already includes every v9.x incremental addition to
PROMPT-TEMPLATES.md. The Step 4 §1.2 destination map was built from the
v9.3 version of the file. Therefore:

- The **Template 8 STATUS.md phase-title linking rule** (commit
  `a795abb`) — present in v9.3's Template 8 — is carried forward into
  `docs/pack/prompts/pm-chat.md` `## Variant: backlog-status-update`
  because that variant's body is the verbatim v9.3 Template 8 text,
  unchanged from the monolith split.
- The **v9.1 BD-038 Active-skills instruction in Template 1** is
  carried forward into `docs/pack/prompts/pm-chat.md`
  `## Variant: kickoff` by the same mechanism.
- Any future v9.x addition (none exists today — v9.3 is the last
  minor) would be present in the v9.3 baseline by the CD-13 invariant
  and therefore in the split output.

The exhaustive list of v9.x incremental additions to PROMPT-TEMPLATES.md
since v9.0, derived from `git log v9.0..v9.3 -- supporting-docs/PROMPT-TEMPLATES.md`:

| Commit | Version | Change | Where it lands in v10 |
|---|---|---|---|
| `f8758f9` | v9.1 | BD-038 Template 1 active-skills-list instruction | `pm-chat.md` `## Variant: kickoff` |
| `a795abb` | v9.3 | Template 8 STATUS.md phase-title linking rule | `pm-chat.md` `## Variant: backlog-status-update` |
| `8364b20` | v9.3 | BD-043 Gemini agent architecture reference update | Distributed throughout — wherever Gemini was referenced, the references are preserved in the split |

All three are already in the v9.3 state. No special handling is needed
when the diff reports "identical." Custom divergences beyond these
v9.x additions are what trigger the backup-and-reconcile path.

### 3.4 What the split produces

For both the identical-to-baseline and diverged cases, the split writes
all 10 v10 pack prompt files from Step 4 §2.3 into
`docs/pack/prompts/`:

| File | Content source |
|---|---|
| `coder.md` | v10 pack `coder.md` from `$PACK/project-template/docs/pack/prompts/coder.md` (not derived from the project's v9.3 PROMPT-TEMPLATES.md) |
| `reviewer.md` | same — v10 pack file |
| ... | same for all 10 |

Implementation note: the migration does **not** actually re-derive the
split from the project's monolith. It writes the v10 pack's per-agent
files directly. The v10 pack's per-agent files were produced once, by
the pack maintainer, as the canonical split of v9.3 baseline content
per Step 4 §1.2, and validated by pack CI (Step 4 §4.5). Every project
gets the identical v10 pack content. This is the same pattern as other
pack-owned files (METHODOLOGY.md, PM-CHAT.md) — v10 ships fresh copies,
and the diff tells the developer whether their v9.3 monolith had
customizations worth reconciling.

### 3.5 Procedure 5-R — reconciliation (new sub-procedure in METHODOLOGY.md)

When the migration has left a `docs/pack/prompts/_v9-backup.md` file
in place, the PM chat at first post-migration `pm-startup` detects it
and invokes Procedure 5-R:

1. PM chat reads `_v9-backup.md` and the v10 pack prompt files.
2. PM chat computes a conceptual diff: the v9.3 baseline content (which
   matches what is now in the v10 per-agent files modulo reformatting)
   vs. `_v9-backup.md`. The only meaningful diff is the project's
   customization.
3. PM chat surfaces the customization to the developer with proposed
   placement — "your project added the following instruction to
   Template 4; in v10 this would live in `coder.md` `## Variant:
   fix-cycle` between these lines. Approve the insertion?"
4. Developer approves, modifies, or rejects.
5. PM chat writes the changes to the relevant per-agent file(s).
6. PM chat offers to remove `_v9-backup.md`. Developer approves;
   `_v9-backup.md` is deleted and the commit message records the
   reconciliation.

Procedure 5-R is added to METHODOLOGY.md Part 7 alongside Procedure 5.
It is triggered solely by the presence of `_v9-backup.md` — once that
file is gone, Procedure 5-R does not run.

### 3.6 Why not auto-merge

Auto-merging a project's PROMPT-TEMPLATES.md customizations into the
new per-agent files would require:
- Parsing the project's monolith (possibly edited into a non-standard
  form) against the v9.3 baseline.
- Mapping each changed section to a per-agent file.
- Inserting the diff at the right heading level.
- Ensuring the result still passes Step 4 §4.5 validation.

All four steps are failure modes — a bad parse, a wrong destination, a
malformed insertion, or a validation failure leaves the project in an
unusable state mid-migration. The backup-and-reconcile path delegates
the judgment to the developer (via the PM chat) at a time when the PM
chat is fully running against v10 and can present the decision
interactively. This matches V10-PREDESIGN Part 8 Lesson 1 (justify
where each operation lives): auto-merge in a shell script is the wrong
lifecycle stage for this decision.

### 3.7 Corner case — PROMPT-TEMPLATES.md already deleted

If `docs/pack/PROMPT-TEMPLATES.md` is missing at migration time, the
pre-flight check in §2.4 invariant 1 fails. The script refuses to
proceed. This could indicate a partially-migrated project or a
project that pre-dates v9.2 BD-042 — either way, the developer needs
to resolve the state manually before migration, outside v10 scope.

---

## 4. PLATFORM-SKILLS.md — preservation of project-owned sections

### 4.1 Decision

PLATFORM-SKILLS.md is structurally split into a **pack-owned region**
(above `## Custom agents`) and a **project-owned region** (`##
Custom agents` + `## Custom skills` sections). The v10 pack template
ships with both regions. The migration merges by replacing pack content
and preserving project content.

### 4.2 The marker rule

The project-owned region begins at the first occurrence of one of these
H2 headings, whichever comes first:

- `## Custom agents`
- `## Custom skills`

Everything from that line to EOF is project-owned. Everything above is
pack-owned.

This is a positional rule, not a comment-marker rule. It is chosen over
the alternative `<!-- PACK-MANAGED ABOVE / PROJECT-MANAGED BELOW -->`
comment because:
- The section headings are themselves the functional markers (Step 5
  §12.1/§12.2 — they carry content the PM chat reads).
- A comment marker is a second source of truth that can drift from the
  headings.
- Every file in the v10 pack template has both sections in the same
  order (Step 5 §12), so the v10 pack template itself is self-marking.

### 4.3 Merge recipe

```text
# Conceptual pseudocode
project_file = read("docs/pack/PLATFORM-SKILLS.md")
pack_file = read("$PACK/project-template/docs/pack/PLATFORM-SKILLS.md")

# Find the first ## Custom agents or ## Custom skills line in each
project_split_line = find_first_custom_heading(project_file)
pack_split_line    = find_first_custom_heading(pack_file)

if project_split_line is None:
    # v9.3 project — no custom sections exist yet. Use the pack's
    # template sections as-is (which include the "No custom agents
    # defined for this project." placeholder).
    output = pack_file
else:
    pack_region    = pack_file[:pack_split_line]
    project_region = project_file[project_split_line:]
    output = pack_region + project_region

backup(project_file)  # per §6
write("docs/pack/PLATFORM-SKILLS.md", output)
```

### 4.4 v9.3 baseline — no custom sections exist

On a v9.3 project, PLATFORM-SKILLS.md has no `## Custom agents` or
`## Custom skills` section (those were added in v10). The merge
consequently uses the v10 pack template unchanged. This is the common
case at the v9.3 → v10.0 transition.

The custom sections become populated only after the project runs
Procedure 5 (Step 5 §11) post-migration. From v10.1 onward (a future
pack upgrade), the merge recipe's `else` branch runs with real custom
content and preserves it.

### 4.5 Edge cases

| Case | Handling |
|---|---|
| Project has `## Custom agents` but no `## Custom skills` | `## Custom agents` is the first marker; project-owned region begins there, includes everything below. Pack's `## Custom skills` header does not overwrite |
| Project has `## Custom skills` but no `## Custom agents` | Symmetric — `## Custom skills` is the first marker |
| Project has content between `## Full skill inventory` and `## Custom agents` that the developer added (not a pack section) | Preserved (falls inside the project-owned region from the marker onward). Migration report flags it so the developer can decide whether to move it above or below in a follow-up commit |
| Project has `## Custom agents` positioned above `## Full skill inventory` (out of pack-expected order) | Detected in the pre-flight check. Migration stops with a diagnostic — the developer must move the custom section below `## Full skill inventory` first |

### 4.6 Rejected alternatives

- **Hard overwrite.** Rejected — destroys custom content.
- **Three-way merge against v9.3 baseline.** Rejected — v9.3 has no
  custom sections; the concept does not apply. Every downstream v10.x
  merge can use the positional rule uniformly.
- **Comment-marker block.** Rejected per §4.2 — redundant with the
  heading-based structure.

---

## 5. Trinity routing-table `### Custom agents` preservation

### 5.1 Decision

The `### Custom agents` sub-section at the end of the Phase routing
table in each of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` is project-owned
after v10. The migration preserves it by the same positional marker
rule as §4.

### 5.2 The marker rule (trinity files)

For each trinity file, the project-owned region is everything from the
first occurrence of `### Custom agents` to the end of the Phase routing
table (which is terminated by the next H2, `## Agent behavior`, per the
v10 template in Step 5 §14).

Concretely:

```text
... pack content ...
## Phase routing — default agent assignments
... pack phase table ...
### Custom agents        <-- first line of project-owned region
... project rows ...
## Agent behavior        <-- next H2; end of project-owned region
... pack content resumes ...
```

### 5.3 Merge recipe

For each of CLAUDE.md / AGENTS.md / GEMINI.md:

```text
project_file = read("CLAUDE.md")
pack_file    = read("$PACK/project-template/CLAUDE.md")

# Locate the ### Custom agents line in each and the next ## line after it
project_custom_start, project_custom_end = find_custom_block(project_file)
pack_custom_start,    pack_custom_end    = find_custom_block(pack_file)

if project_custom_start is None:
    # v9.3 — no sub-section exists. Use pack template.
    output = pack_file
else:
    # Splice: pack above + project custom block + pack below
    output = (
        pack_file[:pack_custom_start]
        + project_file[project_custom_start:project_custom_end]
        + pack_file[pack_custom_end:]
    )

backup(project_file)
write(project_file.path, output)
```

### 5.4 v9.3 baseline — no sub-section exists

On a v9.3 project, trinity files have no `### Custom agents`
sub-section. The merge uses the v10 pack template unchanged (which
itself contains a stub `### Custom agents` sub-section with the
parenthetical placeholder row from Step 5 §14). This is the common
case at v9.3 → v10.0.

### 5.5 Interaction with BD-045 content

BD-045 (capabilities pattern) adds content to the LSP section and
anti-patterns list — Step 3 §4 specifies those exact locations. Neither
of those locations is inside the Phase routing table. The §5 preservation
rule does not interact with BD-045 content: BD-045 content lands in the
pack-owned region (above the custom agents sub-section) and therefore is
part of the v10 pack template copy.

If a future v10.x pack reverses or changes BD-045 wording, the merge
rule continues to work — that wording is pack-owned, replaced on
upgrade, not touched by the preservation logic.

### 5.6 Trinity-rule compliance during migration

The migration applies the same splice logic to all three trinity files
in one atomic step. Either all three are updated or none is (wrapped in
a transactional staging directory — §8.5). This preserves the trinity
rule from Step 5 §16.2: any change to one trinity file must appear in
the other two in the same commit.

### 5.7 Edge case — Active skills line

The v9.1 BD-038 "Active skills" line in the Skill loading section
(CLAUDE.md / AGENTS.md / GEMINI.md) is a project-owned value inside a
pack-owned section. The pack template ships it as the literal
placeholder text `[PM chat writes this line during project kickoff...]`.

This is already a solved case in v9.x — the PM chat overwrites the
placeholder at kickoff time. During migration:

| State of Active skills line | Migration action |
|---|---|
| Still the literal pack placeholder text (never filled in) | Replaced by the v10 pack placeholder (identical text); no functional change |
| Filled in with real skills (e.g., `swift-best-practices, apple-architecture-core, macos-architecture`) | **Preserved** via a second positional splice inside the `## Skill loading` section — exact mechanism in §5.8 |

### 5.8 Active-skills splice

The Active skills line is always a single line starting with the literal
prefix `**Active skills:**`. The migration:

1. Reads the project's Active skills line from the old file.
2. After applying the top-level merge (§5.3), finds the Active skills
   line in the merged output (which came from the pack template, i.e.,
   the placeholder).
3. If the project's Active skills line contains real content (not the
   placeholder), replace the merged output's placeholder line with the
   project's line.

This is a second splice, independent of the `### Custom agents` splice.
Both run per trinity file.

### 5.9 Rejected alternatives

- **Three-way merge tool (git merge-file, diff3).** Rejected — those
  tools operate on line-level diffs and do not understand section
  semantics. The positional rule is more robust against unrelated
  whitespace changes.
- **Marker comments.** Rejected for the same reason as §4.6 — the
  section heading is the functional marker.
- **Full hand-merge per Step 5 of v8-to-v9 guide.** Rejected — that was
  the right pattern for v9 because trinity files had heavy
  project-specific customizations (platform rules, placeholders). In v10,
  the only project-owned regions in trinity files are narrowly scoped
  (custom agents sub-section + active skills line). A precise positional
  splice handles them without the error-prone hand-merge.

---

## 6. Rollback plan

### 6.1 Design requirement

V10-PREDESIGN Part 7 — "every destructive operation creates a backup;
the migration guide includes a 'how to revert to v9.3' section
specifying what to copy back and what to remove."

### 6.2 Backup directory

Every destructive operation writes a backup to
`.pack-migration-backup/v9.3-to-v10.0/`. This directory is created at
the start of the migration and named with the from-version and
to-version pair.

Directory structure:

```text
.pack-migration-backup/v9.3-to-v10.0/
    manifest.txt               # one line per backed-up path; source and
                               # backup path
    docs/pack/PROMPT-TEMPLATES.md  # whole-file backup
    docs/pack/PM-CHAT.md            # pack-owned pre-migration copy
    docs/pack/PLATFORM-SKILLS.md    # pre-merge full copy
    CLAUDE.md                       # pre-merge full copy
    AGENTS.md
    GEMINI.md
    .claude/agents/                 # full snapshot of pre-migration dir
        coder.md
        ...
    .codex/agents/
    .gemini/agents/
    .claude/skills/
    .codex/skills/
    .gemini/skills/
    .codex/config.toml
    .claude/settings.json
    scripts/                        # pre-migration scripts
    agent-run.sh
```

Custom `x-` files are **not** backed up — they are never touched and
therefore cannot be lost. Backing them up would be defensive but
unnecessary: if the whole migration is rolled back, custom files are
still in place.

### 6.3 Rollback procedure (documented in MIGRATION-v9-to-v10.md)

> **To revert to v9.3 after migration:**
>
> ```bash
> # 1. Uncommit the migration commit if already committed
> git log --oneline -5   # find the migration commit
> git revert <hash>      # or: git reset --hard <parent-hash> before push
>
> # 2. Restore pack-owned files from the backup directory
> BACKUP=".pack-migration-backup/v9.3-to-v10.0"
>
> cp "$BACKUP/docs/pack/PROMPT-TEMPLATES.md" docs/pack/PROMPT-TEMPLATES.md
> cp "$BACKUP/docs/pack/PM-CHAT.md" docs/pack/PM-CHAT.md
> cp "$BACKUP/docs/pack/PLATFORM-SKILLS.md" docs/pack/PLATFORM-SKILLS.md
> cp "$BACKUP/CLAUDE.md" CLAUDE.md
> cp "$BACKUP/AGENTS.md" AGENTS.md
> cp "$BACKUP/GEMINI.md" GEMINI.md
> cp "$BACKUP/.codex/config.toml" .codex/config.toml
> cp "$BACKUP/.claude/settings.json" .claude/settings.json
> rm -rf .claude/agents .codex/agents .gemini/agents
> cp -r "$BACKUP/.claude/agents" .claude/agents
> cp -r "$BACKUP/.codex/agents"  .codex/agents
> cp -r "$BACKUP/.gemini/agents" .gemini/agents
> rm -rf .claude/skills .codex/skills .gemini/skills
> cp -r "$BACKUP/.claude/skills" .claude/skills
> cp -r "$BACKUP/.codex/skills"  .codex/skills
> cp -r "$BACKUP/.gemini/skills" .gemini/skills
> rm -rf scripts
> cp -r "$BACKUP/scripts" scripts
> cp "$BACKUP/agent-run.sh" agent-run.sh
> chmod +x agent-run.sh scripts/*.sh
>
> # 3. Remove the new v10 directory (did not exist in v9.3)
> rm -rf docs/pack/prompts
>
> # 4. Remove the backup directory (optional)
> rm -rf .pack-migration-backup
>
> # 5. Verify
> ls .claude/agents/ | wc -l    # expect 16
> ls docs/pack/              # expect the five v9.3 files, no prompts/
> git status                 # should show a clean tree after revert
> ```
>
> **Custom x- files:** any custom agents, skills, or prompts you created
> after migration remain on disk. The rollback does not touch them. They
> will be invisible under v9.3 (pre-v10 has no x-support), so either
> remove them (`rm -rf .claude/agents/x-*.md ...`) or keep them in place
> for a later re-attempt at migration.

### 6.4 Rollback guarantees

- **No data loss on pack files.** Every pack-owned file replaced during
  migration is backed up. The `manifest.txt` records every backup;
  nothing is skipped.
- **No data loss on custom files.** x- files are never touched, not in
  the forward path and not in the rollback path.
- **No data loss on project content files.** BACKLOG.md, STATUS.md,
  ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CHANGELOG.md are not touched
  by the migration — they are project-owned docs. Migration script
  explicitly does not write them.
- **Deterministic recovery.** The rollback commands above are a fixed
  sequence; there is no "figure out what to do" step.

### 6.5 When to roll back vs. fix forward

MIGRATION-v9-to-v10.md documents the decision:

| Situation | Path |
|---|---|
| Migration script errored mid-run, working tree is inconsistent | Roll back per §6.3 step 2 (tree is not yet committed; revert not needed) |
| Migration committed; validation passes; developer wants to explore v10 | Proceed — no rollback |
| Migration committed; validation fails with a reproducible bug in v10 pack | File an issue; roll back per §6.3; wait for pack patch |
| Migration committed; validation passes; developer dislikes v10 ergonomics | Not a rollback case — v10 is the new steady state. If genuine regressions surface, file a PACK-FEEDBACK.md entry |

### 6.6 Backup directory is ignored by git

The migration script appends `.pack-migration-backup/` to `.gitignore`
before creating the directory. If `.gitignore` already lists it, no
change. This prevents accidentally committing 10–30 MB of backed-up
agent and skill files.

---

## 7. Incremental testability contract

### 7.1 Design requirement

V10-PREDESIGN Part 7 — "each implementation stage must leave the pack
in a working state that can be tested independently before moving to
the next stage."

For migration specifically (as distinct from the pack implementation
sequence BD-045 → BD-046 → BD-044), the requirement is: every stage of
the migration leaves the **project** in a state where (a) tests still
pass, (b) the PM chat can start (even if it flags unresolved items),
(c) `validate-pack`-equivalent project-level checks pass.

### 7.2 The migration stages

The migration is one logical operation but decomposes into seven
stages. Each stage leaves the project in a valid, testable state.

| Stage | Action | Post-stage state | Test |
|---|---|---|---|
| **S0 — pre-flight** | Read-only checks (§8.2). Creates backup directory. | Project unchanged | `git status` shows only `.pack-migration-backup/` as untracked |
| **S1 — replace pack agent files** | Selective-replace per §1.3 for Claude, Codex, Gemini agent directories. x- files untouched | Agents are v10; skills still v9.3; prompts dir still monolith | `./agent-run.sh --help` runs; each agent invocation on a trivial task succeeds |
| **S2 — replace pack skill directories** | Selective-replace per §1.3 for all three tool skill dirs. x- dirs untouched | Agents v10; skills v10; monolith still present | Skills visible to each tool (Claude live detection; Gemini `/skills reload`; Codex picks up at next session) |
| **S3 — replace scripts and config** | `scripts/`, `agent-run.sh`, `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` | Config aligned with v10 | `./scripts/bootstrap.sh` runs; `./scripts/validate.sh` runs |
| **S4 — prompts directory creation** | Create `docs/pack/prompts/` and copy v10 pack's 10 per-agent files | Prompts dir coexists with monolith | Directory exists; validate-pack.py's prompts-dir check (Step 4 §4.5) passes on the new files |
| **S5 — trinity and docs/pack merge** | Positional splices per §4 and §5 for CLAUDE.md / AGENTS.md / GEMINI.md and docs/pack/PM-CHAT.md + docs/pack/PLATFORM-SKILLS.md | Trinity + pack docs updated, custom regions preserved | Trinity rule CI check passes; manual inspection of `git diff` shows only pack-owned region changes |
| **S6 — PROMPT-TEMPLATES.md retire** | Diff vs. v9.3 baseline; if identical, delete the file; if diverged, write `_v9-backup.md` and set the Procedure 5-R flag | Monolith gone or backed up | Migration report shows the split mapping; backup exists per §6 |
| **S7 — post-migration report** | Write `.pack-migration-backup/v9.3-to-v10.0/report.md` summarizing every action | Migration complete; developer can commit | Report lists: files replaced, files backed up, improperly-added files, Procedure 5-R flag status |

Each stage writes a sentinel file
(`.pack-migration-backup/v9.3-to-v10.0/stage-S<N>.done`) on completion.
A resumed migration reads the sentinels and skips completed stages.

### 7.3 After-each-stage assertion

Between stages, the migration script runs this pseudo-check:

```bash
# Assertions that must hold after every stage:
test -d .claude/agents                           # agent dir exists
test -d .gemini/agents                           # v9.3+ invariant
test $(ls .claude/agents/*.md 2>/dev/null | wc -l) -ge 16  # pack agents present
test -f CLAUDE.md && test -f AGENTS.md && test -f GEMINI.md
```

If any assertion fails, the script aborts and prints "Migration failed
at stage S<N>. Working tree is in an intermediate state. To recover,
roll back per MIGRATION-v9-to-v10.md §'Rollback'."

### 7.4 What "working state" means for the PM chat between stages

After each stage the PM chat can in principle be launched and will not
crash. It may flag unresolved items — for example, after S4 but before
S6, `docs/pack/PROMPT-TEMPLATES.md` still exists but the PM chat has
been told the new convention is `docs/pack/prompts/`. This is a
diagnostic, not a crash. The migration is a single operation from the
developer's perspective — intermediate states exist only if the
migration script is interrupted.

### 7.5 Why seven stages, not one atomic write

- **Debuggability.** A migration that stops at S3 is easier to diagnose
  than a migration that stops "somewhere in a 200-line script."
- **Resumability.** Sentinel files let a resumed migration skip stages
  already completed, without redoing destructive work.
- **Review granularity.** The automatable-via-AI-CLI option (§9.2)
  pauses between stages for developer approval of the stage's diff.
  Granular pauses are valuable; a single atomic write gives no
  pause points.

### 7.6 Rejected alternative — transactional staging dir

A design where every write goes first to `.pack-migration-staging/`
and is moved atomically at the end was considered. Rejected because:
- The developer cannot inspect intermediate `git status` during staging
  (the staging dir is not the project files).
- Atomic moves of entire directory trees (across filesystems) are not
  guaranteed atomic.
- The stage-by-stage model gives better observability with simpler
  semantics.

---

## 8. Migration script logic — stage by stage

### 8.1 Script name and location

`scripts/migrate-v9-to-v10.sh`. Lives in the pack repo (not in the
project template — it is not copied into projects). Invoked from within
the project repo with `$PACK` pointing to the pack repo checkout:

```bash
PACK=/path/to/pack
cd ~/Developer/my-project
bash "$PACK/scripts/migrate-v9-to-v10.sh"
```

Matches the v8-to-v9 convention (developer points a `$PACK` variable
at the pack repo). Step 7 (BD-044) determines whether this script and
`init-project.sh` share a detection library; this step does not
preempt that decision, but §1 and §2 pre-flight logic is a candidate
for the shared library per OQ-5.

### 8.2 Pre-flight checks (S0)

In order, stopping at the first failure:

1. **Clean working tree.** `git status --porcelain` must be empty.
   Offer to `git stash` if the developer confirms.
2. **On a migration branch.** Current branch matches
   `migration-v9-to-v10` (create it if not: `git checkout -b
   migration-v9-to-v10`).
3. **Pack repo tag verification.** `$PACK` exists; `git -C "$PACK"
   rev-parse v9.3` succeeds; a v10 tag or v10-dev branch exists for the
   pack content to copy.
4. **Baseline invariants** (§2.4): `docs/pack/PROMPT-TEMPLATES.md`
   exists; `.claude/agents/` has ≥16 pack files; `.gemini/agents/`
   exists; PLATFORM-SKILLS.md is in `docs/pack/`.
5. **x- file audit.** Scan the seven directories per §1.2. Record each
   x- file's path, classification (registered / unregistered / etc.),
   and the `.pack-migration-backup/...` is ignored by `.gitignore`
   (add the line if missing).
6. **Unclassifiable file audit.** Record each non-pack, non-x- file in
   the seven directories. These are deferred to the post-migration PM
   chat run.
7. **Stray x- file inside pack skill directory** (§1.6). Stop and ask
   the developer to move the file to a proper `x-<name>/SKILL.md`.
8. **Create backup directory.** Per §6.2.

On success, create `.pack-migration-backup/v9.3-to-v10.0/stage-S0.done`.

### 8.3 Stage S1 — replace pack agent files

```bash
for tool in claude codex gemini; do
    ext=$(case $tool in claude|gemini) echo md;; codex) echo toml;; esac)
    mkdir -p ".$tool/agents"
    cp -r ".$tool/agents" ".pack-migration-backup/v9.3-to-v10.0/.$tool/agents"
    for pack_agent in $(ls "$PACK/project-template/.$tool/agents/"); do
        rm -f ".$tool/agents/$pack_agent"
        cp "$PACK/project-template/.$tool/agents/$pack_agent" ".$tool/agents/$pack_agent"
    done
done
```

x- files are untouched because they are not named in the inner loop.

Sentinel: `stage-S1.done`.

### 8.4 Stage S2 — replace pack skill directories

```bash
for tool in claude codex gemini; do
    mkdir -p ".$tool/skills"
    cp -r ".$tool/skills" ".pack-migration-backup/v9.3-to-v10.0/.$tool/skills"
    for pack_skill in $(ls "$PACK/project-template/skills/"); do
        rm -rf ".$tool/skills/$pack_skill"
        # Replicate the v9 distribution pattern per tool
        if [ "$tool" = "claude" ]; then
            cp -r "$PACK/project-template/skills/$pack_skill" ".$tool/skills/$pack_skill"
        else
            mkdir -p ".$tool/skills/$pack_skill"
            cp "$PACK/project-template/skills/$pack_skill/SKILL.md" ".$tool/skills/$pack_skill/SKILL.md"
        fi
    done
done
```

x- skill directories untouched (not in the pack skill loop).

Sentinel: `stage-S2.done`.

### 8.5 Stage S3 — replace scripts and config

```bash
# Backup
cp -r scripts ".pack-migration-backup/v9.3-to-v10.0/scripts"
cp agent-run.sh ".pack-migration-backup/v9.3-to-v10.0/agent-run.sh"
cp .codex/config.toml ".pack-migration-backup/v9.3-to-v10.0/.codex/config.toml"
cp .claude/settings.json ".pack-migration-backup/v9.3-to-v10.0/.claude/settings.json"
cp .mcp.json.example ".pack-migration-backup/v9.3-to-v10.0/.mcp.json.example" 2>/dev/null

# Replace
rm -rf scripts
cp -r "$PACK/project-template/scripts" scripts
cp "$PACK/project-template/agent-run.sh" agent-run.sh
cp "$PACK/project-template/.codex/config.toml" .codex/config.toml
cp "$PACK/project-template/.claude/settings.json" .claude/settings.json
cp -n "$PACK/project-template/.mcp.json.example" .mcp.json.example
chmod +x agent-run.sh scripts/*.sh
```

Sentinel: `stage-S3.done`.

### 8.6 Stage S4 — create prompts directory

```bash
mkdir -p docs/pack/prompts
for prompt in $(ls "$PACK/project-template/docs/pack/prompts/"); do
    cp "$PACK/project-template/docs/pack/prompts/$prompt" "docs/pack/prompts/$prompt"
done
```

Sentinel: `stage-S4.done`.

### 8.7 Stage S5 — trinity + docs/pack merge

Per §4 (PLATFORM-SKILLS.md) and §5 (CLAUDE.md, AGENTS.md, GEMINI.md):

```bash
# PLATFORM-SKILLS.md
cp docs/pack/PLATFORM-SKILLS.md ".pack-migration-backup/v9.3-to-v10.0/docs/pack/PLATFORM-SKILLS.md"
python3 "$PACK/scripts/merge-platform-skills.py" \
    --pack "$PACK/project-template/docs/pack/PLATFORM-SKILLS.md" \
    --project docs/pack/PLATFORM-SKILLS.md \
    --out    docs/pack/PLATFORM-SKILLS.md

# PM-CHAT.md — pack-owned wholesale; no project-owned region in v10 design
cp docs/pack/PM-CHAT.md ".pack-migration-backup/v9.3-to-v10.0/docs/pack/PM-CHAT.md"
cp "$PACK/project-template/docs/pack/PM-CHAT.md" docs/pack/PM-CHAT.md
# (The project's [PROJECT_NAME] value and any project-specific
# "Additional project documents" rows are re-applied by the PM chat
# at first post-migration pm-startup — Procedure 5-R adjacent flow.
# If the pack later decides to preserve those too, a second positional
# splice can be added here without restructuring the migration.)

# Trinity files
for trinity in CLAUDE.md AGENTS.md GEMINI.md; do
    cp "$trinity" ".pack-migration-backup/v9.3-to-v10.0/$trinity"
    python3 "$PACK/scripts/merge-trinity.py" \
        --pack "$PACK/project-template/$trinity" \
        --project "$trinity" \
        --out "$trinity"
done

# METHODOLOGY.md — pack-owned wholesale
cp docs/pack/METHODOLOGY.md ".pack-migration-backup/v9.3-to-v10.0/docs/pack/METHODOLOGY.md"
cp "$PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
```

The two Python helpers (`merge-platform-skills.py`,
`merge-trinity.py`) implement the positional splice rules from §4.3
and §5.3. They are the only non-shell code in the migration and live
alongside `migrate-v9-to-v10.sh` in the pack's `scripts/` directory.
They are read-only w.r.t. the pack (they read the pack template, they
write only to the project).

Sentinel: `stage-S5.done`.

### 8.8 Stage S6 — PROMPT-TEMPLATES.md retire

```bash
# Backup
cp docs/pack/PROMPT-TEMPLATES.md ".pack-migration-backup/v9.3-to-v10.0/docs/pack/PROMPT-TEMPLATES.md"

# Diff against v9.3 baseline
v93_tmp=$(mktemp)
git -C "$PACK" show v9.3:supporting-docs/PROMPT-TEMPLATES.md > "$v93_tmp"

if diff -q <(tr -d '\r' < docs/pack/PROMPT-TEMPLATES.md | sed 's/[[:space:]]*$//') \
           <(tr -d '\r' < "$v93_tmp" | sed 's/[[:space:]]*$//') > /dev/null; then
    # Identical to baseline — no reconciliation needed
    rm docs/pack/PROMPT-TEMPLATES.md
    echo "customization: none" >> ".pack-migration-backup/v9.3-to-v10.0/report.md"
else
    # Diverged — preserve as _v9-backup.md for PM chat reconciliation
    cp docs/pack/PROMPT-TEMPLATES.md docs/pack/prompts/_v9-backup.md
    rm docs/pack/PROMPT-TEMPLATES.md
    echo "customization: divergence detected; reconciliation flag set" \
        >> ".pack-migration-backup/v9.3-to-v10.0/report.md"
fi
rm -f "$v93_tmp"
```

Sentinel: `stage-S6.done`.

### 8.9 Stage S7 — post-migration report

Write `.pack-migration-backup/v9.3-to-v10.0/report.md` with:

- List of files replaced (from backup manifest).
- x- files preserved (from S0 audit).
- Improperly-added files preserved for PM chat attention (from S0 audit).
- Prompt customization status (`none` or `divergence detected`).
- Rollback command block (copy of §6.3).
- Next-step prompt for the PM chat (a paste-ready prompt matching
  MIGRATION-v8-to-v9 Step C).

Sentinel: `stage-S7.done`.

Migration is complete. The developer reviews `git status` and `git
diff`, runs `./scripts/validate.sh`, and commits manually (no commit
by the script, per CLAUDE.md pack rule "no commit or push without
explicit user approval").

### 8.10 Resumability

If the script is interrupted, re-invoking it reads the sentinel files
and skips completed stages. The script reads
`.pack-migration-backup/v9.3-to-v10.0/manifest.txt` to know which
backups have been written; it does not re-create them.

### 8.11 Script boundary — what it does NOT do

- **Does not commit.** CLAUDE.md pack rule — developer explicitly
  approves commits.
- **Does not run tests.** The developer runs
  `./scripts/validate.sh` after the migration completes.
- **Does not register custom agents.** Procedure 5.3 handles that after
  first post-migration pm-startup.
- **Does not reconcile PROMPT-TEMPLATES.md customizations.** Procedure
  5-R handles that, invoked by PM chat at first startup when
  `_v9-backup.md` is present.
- **Does not modify BACKLOG.md, STATUS.md, ARCHITECTURE.md,
  IMPLEMENTATION_PLAN.md, CHANGELOG.md, PACK-FEEDBACK.md, README.md.**
  These are project-owned state; migration is orthogonal.
- **Does not touch `docs/reference/`.** Project-owned content.
- **Does not touch `xcode-companion-templates/`** on the machine.
  That is a separate per-machine step, carried forward from v8→v9
  practice.

---

## 9. MIGRATION-v9-to-v10.md outline

### 9.1 Overall structure

MIGRATION-v9-to-v10.md follows the structural pattern of
`supporting-docs/MIGRATION-v8-to-v9.md`: self-contained, procedural,
automatable option at the end. Sections in order:

| # | Section | Content |
|---|---|---|
| 1 | Title + automatable-option banner | "Automated migration via AI CLI: see end of guide" |
| 2 | Overview of what changed in v10 | Three BD-item summaries (BD-045 capabilities, BD-046 custom agents + prompt reorg, BD-044 init-project + router); three structural shifts (monolith→per-agent prompts; x-prefix custom files; PLATFORM-SKILLS.md + trinity custom sections) |
| 3 | Before you start | Prerequisites: project is on v9.3; working tree clean; pack v10 available locally; create migration branch |
| 4 | Step 1 — Run the migration script | `bash "$PACK/scripts/migrate-v9-to-v10.sh"` — script behavior description (stage-by-stage, backup, sentinel files, resumable) |
| 5 | Step 2 — Review the migration report | Read `.pack-migration-backup/v9.3-to-v10.0/report.md`; inspect `git status` and `git diff` |
| 6 | Step 3 — Verify | `./scripts/bootstrap.sh`; `./scripts/validate.sh`; agent count invariants; prompts directory validation |
| 7 | Step 4 — First PM chat run | Start PM chat, observe detection scan results; if Procedure 5-R flag is set, reconcile `_v9-backup.md`; otherwise proceed |
| 8 | Step 5 — Custom file registration | Any `x-` files flagged as Unregistered → Procedure 5.3; any non-pack non-x files → Procedure 5.4 |
| 9 | Step 6 — Xcode companion files (Apple projects) | Per-machine update (carried forward from v8→v9 pattern) |
| 10 | Step 7 — Commit | Review `git status`, commit with developer-approved message |
| 11 | What to do after migration | PM chat brief about v10 changes (capabilities pattern, custom agent workflow); restart sessions after commit |
| 12 | Rollback | §6.3 full procedure |
| 13 | Project-type-specific notes | Swift/Python/monorepo specifics (if any — v10 has no per-type migration content beyond the pack template's unified design) |
| 14 | Troubleshooting | Script errors at each stage; baseline-check failures; divergence detected — reconciliation guidance |
| 15 | Automated migration via AI CLI | Paste-ready prompt pattern (Claude Code, Codex, Gemini) |

### 9.2 Automated migration paste-ready prompt (draft pattern)

Matches MIGRATION-v8-to-v9's "Automated migration via Claude Code CLI"
section. Key differences for v10:

- The guide explicitly supports all three CLI tools (not just Claude
  Code) — reflecting Step 5 §4.5 PM chat tool flexibility.
- Stage-by-stage approval is explicit — the prompt instructs the CLI to
  pause after each migration stage for the developer to approve.
- Custom file preservation is called out; the CLI is told not to touch
  `x-` files ever.

Outline of the prompt body:

```text
You are performing a v9.3 → v10.0 migration of this project using the
AI Agent Config Pack. Set:

PACK="/path/to/pack"

Before starting: verify working tree is clean (git status). If it is
not clean, stop.

Instructions:

1. Read $PACK/supporting-docs/MIGRATION-v9-to-v10.md in full before
   doing anything.
2. Create branch: git checkout -b migration-v9-to-v10
3. Run $PACK/scripts/migrate-v9-to-v10.sh and report each stage's
   completion to me. Pause for my review and approval after each stage.
4. When the script completes, present the migration report
   (.pack-migration-backup/v9.3-to-v10.0/report.md) and the git diff
   summary. Do NOT commit.
5. Run ./scripts/bootstrap.sh and ./scripts/validate.sh and report
   results.
6. Present the "What to do after migration" section so I know what to
   do with my first PM chat session (including any reconciliation flag
   set by the script).

Rules:

- Do NOT commit anything without my explicit review and approval.
- Do NOT modify any file starting with `x-` under any circumstance.
- Do NOT modify any file in the pack repo — only this project.
- If the script pauses or errors, report the stage and sentinel file
  state and wait for my direction. Do not attempt to recover by
  reversing individual file edits.
- If the Procedure 5-R reconciliation flag is set (non-trivial
  customizations in PROMPT-TEMPLATES.md), do not attempt the
  reconciliation — PM chat handles that at first pm-startup after
  the migration commits.
```

### 9.3 What the guide does not prescribe

- **Specific validation commands beyond bootstrap + validate.**
  Project-specific tests and builds are the developer's responsibility
  (same as v8→v9).
- **Custom agent creation.** MIGRATION-v9-to-v10.md does not teach
  Procedure 5; it points at METHODOLOGY.md Part 7.
- **BD-045 learning.** The guide names "capabilities pattern added to
  trinity files and architecture skills" as one of the v10 changes but
  does not teach the pattern. Learning belongs in the trinity files
  themselves, where the pattern is defined.

### 9.4 Lesson-4 maintenance note in the guide

Per V9 Lesson 4 (historical prescriptive guidance becomes stale when
decisions are reversed), the guide includes a short maintainer note at
the bottom:

> **Maintainer note.** If a v10.x patch reverses a v10.0 design
> decision that this guide prescribes, update this guide as part of
> that patch. Do not rely on CHANGELOG.md alone; this guide is
> prescriptive and is read by future migrators.

### 9.5 Location and naming

- Guide: `supporting-docs/MIGRATION-v9-to-v10.md`.
- Script: `scripts/migrate-v9-to-v10.sh` (pack repo, not a project
  template file).
- Merge helpers: `scripts/merge-platform-skills.py`,
  `scripts/merge-trinity.py` (pack repo).
- Naming convention per BD-044 §Step 2 (Step 7 will finalize this
  during its resolution of OQ-5).

---

## 10. V9 lessons applied

### 10.1 Lesson 1 — operation-placement rationale

Every migration operation is placed with explicit justification for
its lifecycle stage. Avoids the "skills distribution changed twice"
pattern.

| Operation | Where it lives | Rationale |
|---|---|---|
| x- file preservation | Migration script (§1) | One-time per upgrade; must be atomic with the pack replacement |
| Detection scan for unregistered / improperly-added files | PM chat post-migration (Step 5 §10) | Scan is a recurring pm-startup / phase-gate operation — belongs in the PM chat, not the migration script. The migration only records the state; the PM chat decides |
| PROMPT-TEMPLATES.md → per-agent split | Migration script writes the v10 pack's fresh per-agent files (§3.4). No project-monolith re-split logic in the script | Script writes canonical pack content once; divergence is preserved for PM chat reconciliation (Procedure 5-R) |
| Customization reconciliation (Procedure 5-R) | PM chat post-migration (§3.5) | Reconciliation requires interactive judgment; belongs in a chat context, not a shell script |
| Backup creation | Migration script (§6.2) | Must be atomic with the destructive write it backs up |
| Rollback | Developer-driven, documented in the guide (§6.3) | Developer decides when to roll back; not automated — a rollback that fires automatically on a failed validation would remove the developer's opportunity to inspect and fix forward |
| Trinity / PLATFORM-SKILLS.md merge | Migration script's Python helpers (§5.3, §4.3) | Positional splices are deterministic and belong in the automation |
| METHODOLOGY.md replacement | Migration script, wholesale (§8.7) | METHODOLOGY.md has no project-owned regions in v10; pack-owned wholesale matches the file's lifecycle |
| Xcode companion file update | Developer-driven, per-machine (§9.1 Step 6) | Per-machine files are outside the repo; cannot be touched by a project-repo migration script |
| PM chat first-run detection | Automatic at pm-startup (Step 5 §10) | Belongs at pm-startup because that is when the PM chat's context must reflect the new disk state |

Every row justifies its placement. No operation is split across two
stages.

### 10.2 Lesson 4 — prescriptive guidance must be kept current

The migration guide is prescriptive. §9.4 adds an explicit maintainer
note instructing future pack maintainers to update the guide if a
v10.x patch reverses a v10.0 decision. This mirrors V9's post-release
experience where the verification checklist became stale.

Historical documents affected by this step are annotated, not
rewritten:

- MIGRATION-v8-to-v9.md — remains as-is; historical record of the v9
  migration. A single one-line pointer to MIGRATION-v9-to-v10.md for
  v9→v10 upgrades is acceptable but not required.
- V9-DESIGN.md — not touched. Step 8 (touch-point inventory) handles
  the annotation there per Step 4 §6.2.

### 10.3 Lesson 2 — per-tool CLI behavior not extrapolated

The migration specifies each tool's agent directory and skill directory
on its own terms (claude/codex/gemini each have their own per-file or
per-directory conventions, per Step 5 §2). The x- preservation is
uniform at the filename level (Step 5 §1) but the replacement recipe
per tool respects the per-tool file extension (`.md` vs. `.toml`) and
skill-dir structure (Claude has nested files; Codex/Gemini have only
SKILL.md).

### 10.4 Lesson 3 — trinity rule in the migration

§5.6 explicitly applies the trinity rule: migration updates all three
trinity files atomically within stage S5 via three identical splice
operations. A partial trinity update (two of three) would fail the
pack's own trinity-rule CI check post-migration. The script's
assertion (§7.3) catches this.

### 10.5 Lesson 5 — maintenance-docs included in the migration scope

The migration does not touch `maintenance-docs/` in a project (projects
don't have one — `maintenance-docs/` is pack-only). But §10.2 calls
out the pack-repo maintenance docs that stale-reference V9 — Step 8
touch-point inventory is responsible for the final list (Step 4 §6.2
hand-off).

---

## 11. Design requirements discharged

Per V10-PREDESIGN Part 7.

### 11.1 Automated and manual workflows

- **Automated path:** `migrate-v9-to-v10.sh` + the paste-ready AI CLI
  prompt (§9.2) drives the whole migration with developer approvals
  between stages.
- **Manual path:** MIGRATION-v9-to-v10.md Steps 1–7 (§9.1) walk a
  developer through the same outcome without the script. Falls back to
  the step-by-step shell commands (mostly identical to the script's
  per-stage commands).
- **Every actor has a clear role:** migration script replaces pack
  files and writes backups; developer approves commits and inspects
  diffs; PM chat handles post-migration detection and Procedure 5-R;
  pack-reviewer (pack repo) reviews the script itself during Phase 4
  implementation.

### 11.2 Rollback plan

§6 in full — backup directory, per-file restore sequence, explicit
`git revert` guidance, guarantees about data loss. Documented in the
MIGRATION guide §9.1 row 12.

### 11.3 Incremental testability

§7 — seven stages, each with a post-stage assertion and a sentinel
file. A failed stage does not leave the project in an unrecoverable
state. The rollback procedure (§6.3) works at any point in the
migration because the backup was written at S0 before any destructive
operation.

### 11.4 Seamless BD integration

- **With BD-044 (Step 7).** §8.1 names the shared-detection candidate
  (OQ-5). The pre-flight logic (§8.2) is a candidate to live in a
  shared library sourced by both `init-project.sh` and this migration
  script. Step 7 finalizes OQ-5.
- **With BD-045 (Step 3).** BD-045 content lives in the pack-owned
  region of trinity files — §5.5. The migration carries the v10 pack
  template which includes the BD-045 capabilities section;
  project-owned custom agents are spliced in around it. No conflict.
- **With Step 5 (custom agent mechanism).** §1 preservation uses the
  same `x-` rule as Step 5 §1. The pack roster comes from Step 5 §7.2
  PM-CHAT.md. The seven directories are the same seven from Step 5
  §10.2.
- **With Step 4 (prompt reorg).** §3 splits are mapped per Step 4 §1.2.
  The format is validated by Step 4 §4.5's validate-pack.py check; the
  migration writes pack files that pass that check.

### 11.5 Maintenance considerations

- **Single sources of truth preserved:** pack roster (PM-CHAT.md);
  pack prompt list (Step 4 §2.3); pack-reserved x- namespace (Step 5
  §15.3).
- **No duplicated logic:** the merge helpers (merge-trinity.py,
  merge-platform-skills.py) are the only places the splice logic
  exists. The MIGRATION guide documents the rule but points at the
  scripts for the implementation.
- **Resumability:** sentinel files let a failed migration resume at
  the failing stage without re-running prior successful stages.

### 11.6 PM chat tool flexibility

The migration script is pure shell + Python 3. It runs on any
developer machine. The paste-ready prompt (§9.2) works on Claude Code
CLI, Codex CLI, or Gemini CLI equally. For a developer running PM chat
as a Claude Desktop Project, the migration is still driven by
invoking one of the CLI tools (not Claude Desktop) — consistent with
the v8→v9 approach.

### 11.7 Document access patterns

The migration writes setup-time files (MIGRATION-v9-to-v10.md is
read-once) and leaves workflow-time files (the new per-agent prompts,
trinity docs, PLATFORM-SKILLS.md) in their v10 access patterns.
Migration does not change the access-pattern classifications from
Step 4 §7.2.

### 11.8 Resource considerations

- **Script runtime:** dominated by the per-file copies (~200 files
  across agent + skill dirs). Estimated wall time on a typical dev
  machine: under 10 seconds for the stages, plus the diff computation
  in S6.
- **Backup disk usage:** ~10–30 MB depending on project skill count.
  Transient — backup directory is removed after successful validation.
- **Tokens:** the automated path (AI CLI prompt) consumes ~3K–5K
  tokens to digest the migration guide and run the script; each
  per-stage approval pause consumes another ~500–1K tokens for the
  diff summary. Well within any CLI's single-session budget.

---

## 12. Handoffs

### 12.1 To Step 7 (BD-044 init-project.sh)

Step 7 inherits from this step:

- **Shared detection library.** §8.2 pre-flight checks 1–6 are
  candidates for a shared library (`scripts/lib/detect.sh`) sourced by
  both `migrate-v9-to-v10.sh` and `init-project.sh`. The specific
  shared subset:
  - Clean-working-tree check
  - Pack repo path verification
  - x- file audit
  - Improperly-added file audit
- **Not shared:** baseline-invariant checks (§2.4) are migration-only;
  init-project.sh does not have a baseline to verify.
- **Two-script decision.** §8.1 names this script and implies a
  distinct `init-project.sh`; Step 7 decides whether they share a
  library or whether one script has mode flags. The `x-` preservation
  logic (§1) is migration-only; init-project.sh never creates or
  preserves x- files (Step 5 §18.2).

### 12.2 To Step 8 (touch-point consolidation)

Step 8 inherits from this step:

- **New files:** `supporting-docs/MIGRATION-v9-to-v10.md`,
  `scripts/migrate-v9-to-v10.sh`, `scripts/merge-platform-skills.py`,
  `scripts/merge-trinity.py`.
- **Historical annotations:** MIGRATION-v8-to-v9.md is unchanged but
  may receive a pointer to MIGRATION-v9-to-v10.md.
- **BACKLOG entries:** BD-046 migration clause; BD-044 init-project.sh
  convergence clause.
- **Stale-reference sweep:** the seven directories named in §1.2; any
  doc that prescribes `rm -rf .claude/agents/` from the v8→v9 era is
  stale and must be updated.

### 12.3 To Step 10 (verification plan)

Verification items originating in this step:

1. **Migration dry run.** Execute `migrate-v9-to-v10.sh` against a
   synthetic v9.3 project with known contents; assert each stage's
   sentinel file is written and the post-stage state matches §7.2.
2. **x- preservation test.** Before migration, seed the v9.3 project
   with `.claude/agents/x-deployer.md`, `.codex/agents/x-deployer.toml`,
   `.gemini/agents/x-deployer.md`, `docs/pack/prompts/x-deployer.md`
   (note: prompts dir does not exist in v9.3, so add this one to a
   staging synthetic v10 project instead for the preservation check on
   v10.x → v10.y in the future). Run migration; assert every x- file
   is byte-identical after migration.
3. **Improperly-added preservation test.** Seed a non-pack non-x file
   (e.g., `.claude/agents/notes.md`). Assert the migration preserves
   it and flags it in the report.
4. **PROMPT-TEMPLATES.md identical path.** Seed v9.3 project with
   unmodified PROMPT-TEMPLATES.md. Assert the migration deletes it and
   writes no `_v9-backup.md`.
5. **PROMPT-TEMPLATES.md diverged path.** Seed with a modified
   PROMPT-TEMPLATES.md. Assert `_v9-backup.md` is written and the
   report flags divergence.
6. **Trinity merge splice.** Seed trinity files with a synthetic
   `### Custom agents` sub-section. Assert the migration preserves the
   sub-section and the Active skills line.
7. **PLATFORM-SKILLS.md merge splice.** Seed `## Custom agents` and
   `## Custom skills` sections. Assert preserved.
8. **Rollback rehearsal.** Execute migration; commit; then execute
   §6.3 rollback. Assert project state matches pre-migration hash.
9. **Incremental testability.** Interrupt the migration mid-stage (via
   signal); restart; assert it resumes from the correct sentinel.
10. **Pack CI check.** validate-pack.py in the pack repo confirms the
    migration script and its helpers are present and pass linting.

### 12.4 To Phase 3 (implementation planning)

No dependencies are opened for Phase 3 beyond what this step discharges.
Phase 3 consumes:

- §8 stage definitions as the implementation outline.
- §9.1 guide section list as the documentation outline.
- §12.3 verification items as inputs to the Phase 4 testing plan.

---

## 13. Summary

- **CD-5 confirmed.** Migration preserves x- files by in-place skip —
  the script never names them and never `rm -rf`'s any of the seven
  scan directories. Pack files are removed individually by name from
  the pack roster, then the v10 pack version is copied. Files that are
  neither pack nor x- prefixed are preserved and flagged for PM chat
  attention (Procedure 5.4) post-migration. Preservation mechanism,
  directories, roster source, and failure modes all specified (§1).
- **CD-13 confirmed.** Migration baseline is v9.3 exactly. Older v9
  minors are out of scope. The script verifies invariants at pre-flight
  (§2.4) and refuses to proceed otherwise.
- **OQ-3 resolved.** Migration diffs the project's PROMPT-TEMPLATES.md
  against the v9.3-tagged pack baseline. Identical → mechanical split
  by writing the v10 pack's per-agent files; delete the monolith.
  Diverged → same split, plus preserve the original as
  `docs/pack/prompts/_v9-backup.md`, and set a flag that the PM chat
  picks up at first startup (Procedure 5-R reconciliation). All three
  v9.x incremental additions (BD-038 Template 1 instruction; `a795abb`
  Template 8 phase-title rule; BD-043 Gemini references) are preserved
  because they are part of the v9.3 baseline that the v10 pack per-agent
  files were derived from (Step 4 §1.2).
- **PLATFORM-SKILLS.md preservation** specified as a positional splice
  at the first `## Custom agents` or `## Custom skills` heading (§4).
  On v9.3 (no custom sections yet) the pack template is used verbatim.
- **Trinity preservation** specified as two splices per trinity file:
  the `### Custom agents` sub-section and the Active skills line (§5).
  Trinity rule compliance maintained via atomic updates within stage
  S5.
- **Rollback plan** documented — backup directory
  `.pack-migration-backup/v9.3-to-v10.0/` populated before any
  destructive write, a concrete step-by-step rollback sequence in
  MIGRATION-v9-to-v10.md §6.3, and explicit guarantees about data loss
  (§6.4). `.pack-migration-backup/` auto-ignored by git.
- **Incremental testability** specified — seven migration stages each
  with a post-stage assertion and a sentinel file. Resumable on
  failure (§7, §8.10).
- **Migration script** (`scripts/migrate-v9-to-v10.sh`) with two Python
  merge helpers (`merge-platform-skills.py`, `merge-trinity.py`)
  specified stage-by-stage (§8). Boundaries of the script are explicit
  (§8.11) — it does not commit, does not run tests, does not register
  custom agents, does not reconcile PROMPT-TEMPLATES.md.
- **MIGRATION-v9-to-v10.md** outline drafted (§9) with 15 sections,
  automatable-option paste-ready prompt pattern matching the v8-to-v9
  convention, and an explicit maintainer note per Lesson 4.
- **V9 Lessons 1 and 4 applied** — operation-placement justified for
  every migration operation (§10.1); prescriptive guide maintenance
  rule documented (§10.2). Lessons 2, 3, 5 also addressed (§10.3–.5).
- **All relevant Design Requirements discharged** (§11): automated +
  manual workflows, rollback plan, incremental testability, seamless
  BD integration, maintenance considerations, PM chat tool flexibility,
  document access patterns, resource considerations.
- **Handoffs discharged** (§12) to Step 7 (shared detection library
  candidates), Step 8 (touch-point inventory), Step 10 (verification
  items), and Phase 3 (consuming §8 and §9.1 as implementation input).
- **No new open questions opened.** CD-5, CD-13, and OQ-3 are the only
  items this step is responsible for resolving; all are resolved.

---

*End of step-06-migration.md.*
