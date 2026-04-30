# V10 Procedure 5-C — Author Draft (BD-059, C7 deliverable)

**Status:** Architect draft (read-only authoring output).
**Author:** pack-architect session, 2026-04-30.
**Scope:** Body of Procedure 5-C and sub-procedure 5-C.1 ready for direct
inclusion in `supporting-docs/INSTALL-PROCEDURES.md` at Commit C7. Companion
recommendation on sidecar-naming harmonization (OQ-P4) and the migrate-script
edit that recommendation requires.
**Read-only outside this file:** the draft does not modify METHODOLOGY.md,
the migrate script, or any other pack file. The implementer applies the doc
landing and the migrate-script change in C7.

---

## Part 0 — Preamble

### 0.1 Where Procedure 5-C lives

Procedure 5-C lands in `supporting-docs/INSTALL-PROCEDURES.md` per Plan
OQ-3 alongside the relocated procedures: Procedure 5 (and 5.1–5.6),
Procedure 5-S, Procedure 7, and the (folded) Procedure 5-R. Procedure 5-C
is born in INSTALL-PROCEDURES.md — it has no METHODOLOGY.md predecessor.
METHODOLOGY.md retains a one-line pointer stub for 5-C identical in shape
to the stubs C7 leaves for the other relocated procedures.

The procedure body below is written verbatim for direct paste. Heading
levels assume the procedure sits inside INSTALL-PROCEDURES.md as a
top-level `### Procedure 5-C — …` H3, mirroring Procedure 5-R / 5-S in
the current METHODOLOGY.md (lines 1243 / 1267). Sub-procedure 5-C.1 sits
under it as `#### Procedure 5-C.1 — …` H4, mirroring Procedure 5.1 / 5.2
nesting under Procedure 5.

### 0.2 Procedure 5-C versus Procedure 5-R (folded sub-procedure)

Per user direction 2026-04-30, Procedure 5-R is folded into Procedure 5-C
as **Procedure 5-C.1 — Prompt-templates reconciliation**. Procedure 5-C
is the umbrella reconciliation procedure for every `.v9-customized`
sidecar the migration produces; Procedure 5-C.1 covers the legacy
`docs/pack/PROMPT-TEMPLATES.md` retirement case from S6, which differs
from the rest only in (a) the file is removed by design rather than
overwritten, and (b) its sidecar lands under `docs/pack/prompts/`
rather than alongside the original path. After C7, METHODOLOGY.md no
longer hosts Procedure 5-R; INSTALL-PROCEDURES.md hosts 5-C.1. The
`pm-startup` SKILL Step 0 sentinel sweep (per OQ-P2) routes the
PROMPT-TEMPLATES case to 5-C.1 and the rest to 5-C proper.

### 0.3 Sidecar-naming recommendation (OQ-P4)

**Recommendation: unify on `.v9-customized` for every file class,
including PROMPT-TEMPLATES.md.** S6 is changed from
`mv "$proj_file" docs/pack/prompts/_v9-backup.md` to
`mv "$proj_file" "$proj_file.v9-customized"`, producing
`docs/pack/PROMPT-TEMPLATES.md.v9-customized` rather than
`docs/pack/prompts/_v9-backup.md`.

**Rationale (in order of weight):**

1. **One convention, one mental model.** A developer scanning the
   working tree post-migration sees a single sidecar suffix
   (`*.v9-customized`) regardless of file class. The completion check
   (Part 3) reduces to a single shell glob. The pack-startup sentinel
   sweep (OQ-P2) reduces to a single glob.
2. **Procedure 5-C and 5-C.1 share a clearing step.** With unified
   naming, the "delete the sidecar when done" instruction is identical
   in both bodies; the developer does not have to remember two
   different filenames.
3. **The `_v9-backup.md` name was a v10.0 convention with one user
   (the OT migration that destroyed customization).** v10.0 has not
   reached production; renaming now costs nothing. After BD-059 ships,
   the `_v9-backup.md` name appears nowhere outside historical
   commits, archived plan documents, and CHANGELOG.md.
4. **Locality is preserved.** The unified convention places the
   sidecar alongside the migrated file (architect Part 3.6 specified
   `docs/pack/prompts/_v9-backup.md` because v10 retires the path
   `docs/pack/PROMPT-TEMPLATES.md` and there is no migrated file at
   that path to sit beside). Under the recommendation, the sidecar
   sits at `docs/pack/PROMPT-TEMPLATES.md.v9-customized` — beside the
   path the file used to occupy. The file is gone; the sidecar
   documents what was there. Discoverability is at least as good as
   under the legacy name (probably better — `git status` shows it
   adjacent to `docs/pack/` reorganization rather than buried in
   `docs/pack/prompts/`).
5. **The `_v9-backup.md` filename does not encode the disposition.**
   `.v9-customized` does. A developer encountering an unknown sidecar
   can deduce its meaning from the suffix; `_v9-backup.md` requires
   reading documentation to learn what it represents.

**Cost:** one line change in `scripts/migrate-v9-to-v10.sh` S6 (line
911), one cross-reference sweep across `MIGRATION-v9-to-v10.md` and
the `pm-startup` SKILL for the legacy filename. The migrate script
already records the disposition via `record_disposition` with a
sidecar argument (line 912) — the value of the sidecar argument
changes from `docs/pack/prompts/_v9-backup.md` to
`docs/pack/PROMPT-TEMPLATES.md.v9-customized`. No structural change to
the report or to dispositions.tsv schema.

### 0.4 Migrate-script edit the implementer must execute alongside this doc

To honour the recommendation in 0.3, the C7 commit also edits
`scripts/migrate-v9-to-v10.sh` S6 stage:

- **Line 910:** message text changes from
  `customization: divergence detected — preserving as docs/pack/prompts/_v9-backup.md`
  to
  `customization: divergence detected — preserving as docs/pack/PROMPT-TEMPLATES.md.v9-customized`.
- **Line 911:** `mv "$proj_file" docs/pack/prompts/_v9-backup.md`
  becomes `mv "$proj_file" "$proj_file.v9-customized"`.
- **Line 912:** `record_disposition` sidecar argument changes from
  `docs/pack/prompts/_v9-backup.md` to
  `docs/pack/PROMPT-TEMPLATES.md.v9-customized`; trailing notes string
  updates "Procedure 5-R" to "Procedure 5-C.1".
- **End-of-run summary (lines 1035, 1059):** any reference to
  `_v9-backup.md` becomes the unified name; "Procedure 5-R" becomes
  "Procedure 5-C.1".

The end-of-run summary already routes the unified case to 5-C; the
remaining edits are copy-edits to remove residual `_v9-backup.md`
mentions.

If the implementer (Pack Chat) declines to unify, the alternative is
documented at the end of Part 4 — the procedure body must then carry
the legacy filename in 5-C.1's preamble and the completion check (Part
3) must accept either suffix. Architect prefers unification.

---

## Part 1 — Procedure 5-C body (verbatim for INSTALL-PROCEDURES.md)

The text below uses H3 for the procedure heading and H4 for sub-headings,
matching the existing Procedure 5-R / 5-S level in METHODOLOGY.md.

```markdown
### Procedure 5-C — Customization reconciliation after v9.3 → v10 migration

Triggered by presence of any `*.v9-customized` sidecar file in the
project working tree after `migrate-v9-to-v10.sh` completes.

A `*.v9-customized` sidecar means the migration script detected
project customization the migration could not safely auto-merge with
the v10 pack template. The v10 pack file has been written; the
project's pre-migration content is preserved in the sidecar; the
report lists the file under "Reconciliation required". Procedure 5-C
walks the developer through resolving each sidecar so that the
migration commit lands a working tree the developer has reviewed line
by line.

Procedure 5-C is re-entrant. Partial completion preserves the
unresolved sidecars and the procedure resumes where it left off at
the next `/pm-startup`. The procedure is complete only when every
`*.v9-customized` sidecar is removed from the working tree.

#### Procedure 5-C.0 — Pre-flight (read this first)

1. **Open the migration report.** `cat
   .pack-migration-backup/v9.3-to-v10.0/report.md`. Read the
   "Reconciliation required" section. Each entry names the migrated
   file, the sidecar path, the three-way diff path, and a one-line
   reason for the reconciliation.
2. **Inventory sidecars.** From the project root:
   `find . -name '*.v9-customized' -not -path './.pack-migration-backup/*'`.
   The list must match the "Reconciliation required" section of the
   report one-for-one. A mismatch is a defect — STOP and surface it
   to Pack Chat before proceeding.
3. **Confirm the migration branch.** `git branch --show-current` must
   print `migration-v9-to-v10` (or whatever branch the migration
   created). Procedure 5-C does not run on `main`.
4. **Decide reconciliation strategy per file class.** The flow below
   branches by file class (per the disposition record's `class` column
   in `dispositions.tsv`). Process files in the order they appear in
   the report — the order is class-grouped (text-prose first, then
   structured configs, then agents/skills, then scripts) so the
   developer establishes context once per class.

#### Procedure 5-C.1 — Prompt-templates reconciliation (legacy D4 case)

(Body authored in Part 2 below — folded from the former Procedure 5-R.
Apply this sub-procedure when the sidecar is the file produced by S6
for `docs/pack/PROMPT-TEMPLATES.md`. All other sidecars use 5-C.2
through 5-C.7 below.)

#### Procedure 5-C.2 — Trinity prose (C1 / C2 / C3)

Files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (sidecar: `<file>.v9-customized`).
Pattern: P (intermixed prose under pack-named H2 sections).

The migration produced `<file>.v9-customized` for each trinity file
where v9.3 OURS differed from the v9.3 BASE and the v10 pack also
changed the file. The v10 pack file has been written; the project's
v9.3 prose is preserved in the sidecar.

The trinity rule applies throughout: every reconciliation decision is
made once and applied to all three files (CLAUDE.md / AGENTS.md /
GEMINI.md) with byte-identical content under each H2 the trinity rule
covers. The only allowed asymmetry is tool-intrinsic content (Claude
Task tool syntax, Codex profile names, Gemini agent invocation
syntax) — and only inside H2 sections that are themselves marked as
tool-specific.

1. **Open the three-way diff.** `cat
   .pack-migration-backup/v9.3-to-v10.0/diffs/<file>.three-way.diff`
   (path from the report). The diff shows BASE (v9.3 pack baseline) →
   OURS (project v9.3 customization) → THEIRS (v10 pack template).
2. **Walk each H2 section in the project's v9.3 file.** Open
   `<file>.v9-customized` in the editor alongside the live `<file>`
   (now containing the v10 template). For each H2 in the v9.3 file:
   a. **H2 also exists in v10 template.** Read the v9.3 body, read
      the v10 body. Decide one of:
      - **Keep pack.** v10 supersedes v9.3 for this section
        (e.g., the section is a methodology summary the pack tightened
        and the project has no domain-specific override). No edit
        needed; the v10 template is already in place.
      - **Keep project.** The v9.3 body is project-specific
        (architecture rules tuned to the codebase, security policy,
        anti-patterns the team learned). Replace the v10 body under
        this H2 with the v9.3 body from the sidecar. Apply the same
        replacement to all three trinity files.
      - **Hand-merge.** Both contain content that must survive.
        Compose a merged body — pack scaffolding plus project
        additions — and replace the v10 body with the merged result.
        Apply identically across the three files.
   b. **H2 is project-original (not in v10 template).** Two routes:
      - **Pack-worthy.** The customization should be upstreamed.
        Land the section under `## Project addenda` at the bottom
        of the v10 template (the v10 template ships the H2 marker
        empty — see Plan OQ-4 / architect Part 3.2). File a
        `PACK-FEEDBACK.md` entry per Workflow 10 / Part 10 of
        METHODOLOGY.md proposing the addition to the pack.
      - **Project-only.** Land the section under `## Project addenda`.
        No PACK-FEEDBACK entry.
3. **Walk each H2 section in v10 that is NOT in the v9.3 file.** These
   are pack additions the project must adopt or consciously reject.
   Default action is **adopt** — the v10 template is already in place.
   If the project explicitly does not want the section (e.g., it
   conflicts with project policy), delete the section from all three
   trinity files and record the rejection in `BACKLOG.md` so a future
   migration does not silently re-introduce it.
4. **Run the trinity rule check.** `diff <(grep '^## ' CLAUDE.md) <(grep '^## ' AGENTS.md)`
   and the same for GEMINI.md. Any diff is a trinity-rule violation
   unless the H2 is tool-intrinsic (asymmetry justified). Resolve
   before proceeding.
5. **Delete the sidecars.** `rm CLAUDE.md.v9-customized
   AGENTS.md.v9-customized GEMINI.md.v9-customized`. Procedure 5-C
   does not consider trinity reconciliation complete until all three
   sidecars are gone.

#### Procedure 5-C.3 — PM-CHAT.md (D1)

File: `docs/pack/PM-CHAT.md` (sidecar: `docs/pack/PM-CHAT.md.v9-customized`).
Pattern: T (template) → P (intermixed prose after kickoff fill).

PM-CHAT.md is a template at install time; the kickoff (Procedure 7)
fills `[PROJECT_NAME]` and the "Additional project documents" section.
After kickoff, the file is intermixed prose under pack-named headings.
The migration's classifier detects the post-kickoff state via the
`[PROJECT_NAME]` placeholder absence and the populated additional-docs
section.

1. Open `docs/pack/PM-CHAT.md.v9-customized` and the live
   `docs/pack/PM-CHAT.md` side by side.
2. **Project name (H1).** The v9.3 file's H1 has the literal project
   name; the v10 file has `[PROJECT_NAME]`. Replace the placeholder
   with the project name from the sidecar. (If Procedure 5-S Task B
   has already run and substituted the placeholder, this step is a
   no-op — confirm and continue.)
3. **Role paragraph.** v9.3 had a "You are the PM for X" sentence
   plus optional project-specific role description. v10 has the
   pack-template role paragraph with `[PROJECT_NAME]` token. Decide:
   keep-pack (replace token only), keep-project (paste sidecar
   paragraph), or hand-merge (template scaffold plus project
   specifics).
4. **Additional project documents section.** This is the most common
   conflict point. v10 ships an empty / illustrative list; v9.3 has
   the project's filled list of project-specific docs. Replace the
   v10 list wholesale with the sidecar's list.
5. **Walk remaining H2 / H3 sections.** Apply the same H2-walk logic
   as trinity (5-C.2 step 2) — keep-pack / keep-project / hand-merge
   per section.
6. **Delete the sidecar.** `rm docs/pack/PM-CHAT.md.v9-customized`.

PM-CHAT.md is not under the trinity rule; no cross-file symmetry
check applies.

#### Procedure 5-C.4 — PLATFORM-SKILLS.md (D2)

File: `docs/pack/PLATFORM-SKILLS.md` (sidecar:
`docs/pack/PLATFORM-SKILLS.md.v9-customized`).
Pattern: X (marker-section) — sidecar appears only when the v9.3
project lacked the v10 marker convention OR the auto-splice produced
warnings.

The migration's `merge-platform-skills.py` helper splices the
project's `## Custom agents` and `## Custom skills` regions
verbatim into the v10 template. v9.3 projects do not have those
sections, so the splice writes the v10 template verbatim — but the
project may have edited rows above the `## Custom *` boundary
(active-skills tuning) that the splice does not preserve. The
sidecar captures those edits.

1. **Confirm the auto-splice preserved Pattern X regions.** `diff <(awk
   '/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md.v9-customized)
   <(awk '/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md)`. The
   diff should be empty (no edits to Custom regions during migration).
   If the diff is non-empty, the auto-splice failed — STOP and
   surface to Pack Chat.
2. **Reconcile non-Pattern-X edits.** Diff the pre-`## Custom agents`
   region of the sidecar against the same region of the live file:
   `diff <(awk '!/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md.v9-customized)
   <(awk '!/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md)`. Any
   diff is a project edit the auto-splice did not preserve. Decide
   keep-pack / keep-project / hand-merge per row.
3. **Adopt v10 marker convention.** If the v9.3 file had no
   `## Custom agents` / `## Custom skills` heading, the v10 file now
   has both empty (or with the project's pre-existing custom rows if
   the project added rows in non-Pattern-X form). Verify the
   project's actual custom agents and skills (from
   `.claude/agents/x-*.md`, `.claude/skills/x-*/`) have rows under
   the new headings. Add rows for any missing entries.
4. **Delete the sidecar.** `rm docs/pack/PLATFORM-SKILLS.md.v9-customized`.

#### Procedure 5-C.5 — Structured configs (K1 / K2 / K3 / K4)

Files: `.claude/settings.json` (K1), `.codex/config.toml` (K2),
`.codex/requirements.toml` (K3 if shipped), `.mcp.json.example` (K4).
Pattern: S (semantic structured merge).

The migration's `merge-json.py` and `merge-toml.py` helpers compute a
key-level three-way merge. A sidecar appears only when the helpers
hit an ambiguous case (project-removed AND pack-added the same item;
type mismatch across BASE / OURS / THEIRS; structural conflict). When
a sidecar appears, the helpers also write a warnings log at
`.pack-migration-backup/v9.3-to-v10.0/diffs/<file>.merge-warnings.log`
listing each unresolved key.

1. **Read the warnings log.** `cat
   .pack-migration-backup/v9.3-to-v10.0/diffs/<file>.merge-warnings.log`.
   Each warning names a key path, the BASE / OURS / THEIRS values,
   and the conflict type.
2. **Resolve each warning.** For each:
   a. **Project-removed AND pack-added the same item.** Decide
      whether the project's removal was intentional (e.g., OT
      removed `[model_providers.ollama]` because the project does
      not run a local Ollama instance). If intentional, leave the
      live file as-is (the merge defaulted to including the item;
      remove it manually). If not intentional, the merge default
      stands — no edit needed.
   b. **Type mismatch.** A key was a string in v9.3, a list in v10.
      Read the v10 schema (in the pack template comment header or
      in `V10-DESIGN.md`); decide the correct value shape. Edit the
      live file.
   c. **Structural conflict.** A whole table (TOML) or object
      (JSON) has divergent shape. Open the sidecar, the live file,
      and the BASE (from `git -C $PACK show v9.3:<path>` per the
      migration's three-way materials). Hand-resolve.
3. **Validate the resulting file.** For JSON:
   `python3 -m json.tool < <file> > /dev/null`. For TOML:
   `python3 -c "import tomllib; tomllib.load(open('<file>','rb'))"`.
4. **Apply trinity rule for tool-config parity (per BD-059 success
   criterion).** If the reconciled file affects an
   `AGENT_CAPABILITIES`-class key (env in `.claude/settings.json`,
   `[agent_capabilities]` table in `.codex/config.toml`,
   `.gemini/.env`), confirm the same value is expressed in all three
   tools' configs. The migration's parity check warns if not; resolve
   before proceeding.
5. **Delete the sidecar.** `rm <file>.v9-customized`.

#### Procedure 5-C.6 — Pack agents (A1–A3) and pack skills (L1–L3)

Files: `.{claude,codex,gemini}/agents/<roster>.{md,toml}` (sidecar:
sibling `<file>.v9-customized`); `.{claude,codex,gemini}/skills/<roster>/SKILL.md`
(sidecar: `SKILL.md.v9-customized` inside the skill dir).
Pattern: P (intermixed pack content with project additions).

Project-edited pack agents and pack skills are uncommon but legitimate
(e.g., a project that hand-tuned `auditor-architecture.md` with a
domain-specific review checklist bullet). The sidecar captures the
project edits; the live file has the v10 pack version.

1. **Diff the sidecar against the live file.** `diff <file>.v9-customized
   <file>`. The diff shows project additions / removals against the
   v10 pack version.
2. **Decide per addition.** For each project addition:
   - **Port forward.** Re-apply the addition on top of the v10 pack
     file (the addition is project-specific and should remain in
     the project's copy of the pack file).
   - **Upstream.** File a `PACK-FEEDBACK.md` entry proposing the
     addition. After upstreaming, the addition lands in a future
     pack version and the project's local edit can be removed at
     the next migration.
   - **Drop.** v10 supersedes the project edit (the pack changed
     for a reason that obsoletes the project's customization).
3. **Trinity-symmetry check for agents and skills.** The same edit
   applied to one tool's variant (e.g., `.claude/agents/coder.md`)
   must be applied to the Codex `.codex/agents/coder.toml` and Gemini
   `.gemini/agents/coder.md` equivalents — UNLESS the change is
   tool-intrinsic (Claude `Task` tool reference, Codex profile name,
   Gemini YAML frontmatter shape). The trinity rule applies to pack
   agent files identically to the trinity prose files.
4. **Skill-dir siblings.** A skill directory may contain files
   beyond `SKILL.md` (project notes, supporting docs). The migration
   preserves siblings in place; only `SKILL.md` is reconciled. If
   the v10 pack ships new sibling files for a skill, they appear
   alongside the project's pre-existing siblings — confirm no name
   collision and adopt the new pack siblings.
5. **Delete the sidecar.** `rm <file>.v9-customized` (or `rm
   <skill-dir>/SKILL.md.v9-customized`).

#### Procedure 5-C.7 — Scripts (S1, S2)

Files: `agent-run.sh` (S1), `scripts/<script>.sh` for pack-roster
scripts (S2). Sidecar: `<file>.v9-customized` alongside.
Pattern: P (pack-shipped scripts with possible project edits).

Project-edited pack scripts are uncommon (most projects accept the
pack scripts unchanged). When sidecars appear:

1. **Diff sidecar against live.** `diff <file>.v9-customized <file>`.
2. **Decide per change.** Same options as 5-C.6 step 2 — port forward,
   upstream, drop.
3. **Project-only `x-*.sh` scripts.** S2/S3 preserve `scripts/x-*.sh`
   in place automatically; they do not produce sidecars. Confirm
   their presence with `ls scripts/x-*.sh` (the report's "Project
   files preserved" section also lists them). No reconciliation
   action is required for `x-*.sh` scripts unless the project chose
   to retire one — in which case `git rm` on developer approval per
   CLAUDE.md destructive-op rule.
4. **Delete the sidecar.** `rm <file>.v9-customized`.

#### Procedure 5-C.8 — Per-agent prompts (P1)

Files: `docs/pack/prompts/<roster>.md` (sidecar: sibling
`<file>.v9-customized`). Pattern: P.

When the project edited a pack-roster prompt file (rare — most prompt
edits go in `docs/pack/prompts/x-*.md` project additions), the
migration preserves the project edit as a sidecar and writes the v10
pack version live.

Apply the trinity-prose flow (5-C.2 H2 walk) to the prompt file. Per-
agent prompt files are not under the trinity rule (one file per agent,
not a tool trinity).

1. Open the sidecar and the live prompt file.
2. Walk each named section (Variant: standard, Variant: fix-cycle,
   etc.). Decide keep-pack / keep-project / hand-merge.
3. Project-original sections (a variant the v10 pack template doesn't
   have) belong in `docs/pack/prompts/x-<agent>-<variant>.md` per the
   `x-*` convention, not appended to the pack-roster file. Move the
   section there if needed.
4. Delete the sidecar.

#### Procedure 5-C.9 — Completion check and commit

After every sidecar has been reconciled and removed:

1. **Inventory check.** From the project root:
   `find . -name '*.v9-customized' -not -path './.pack-migration-backup/*'`.
   Output must be empty.
2. **Legacy-name check (transitional).** `find . -name '_v9-backup.md'
   -not -path './.pack-migration-backup/*'`. Output must be empty
   (relevant only on installs that ran a pre-C7 v10.0 migration).
3. **Report check.** Re-read the "Reconciliation required" section
   of `report.md`. The developer maintains a checklist alongside the
   report (in the editor or as a scratch file at
   `.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md`)
   confirming each entry has been addressed. Each entry must be
   marked done.
4. **Working-tree review.** `git status` and `git diff` on the
   migration branch. Confirm the working tree contains no
   `*.v9-customized` files and matches developer intent.
5. **Commit.** `git add` the resolved files, the deleted sidecars
   (which `git status` shows as deletions), and any new
   `## Project addenda` sections, `x-*.md` prompts, or
   PACK-FEEDBACK.md additions. Commit on the migration branch per
   `MIGRATION-v9-to-v10.md` Steps 5–7. Procedure 5-C does not run
   again on this project.
```

---

## Part 2 — Procedure 5-C.1 body (verbatim for INSTALL-PROCEDURES.md)

The text below is intended to sit immediately after the Procedure 5-C.0
"Pre-flight" sub-procedure in Part 1, **replacing the placeholder** at
"Procedure 5-C.1 — Prompt-templates reconciliation (legacy D4 case)".
The body is restructured from the existing METHODOLOGY.md Procedure 5-R
(lines 1243–1265) to fit the 5-C parent structure and the unified
sidecar naming.

```markdown
#### Procedure 5-C.1 — Prompt-templates reconciliation (legacy D4 case)

Triggered when the migration's S6 stage produced
`docs/pack/PROMPT-TEMPLATES.md.v9-customized` — the v10 retirement of
`docs/pack/PROMPT-TEMPLATES.md` for projects whose v9.3 file diverged
from the v9.3 pack baseline (i.e., the project edited the
PROMPT-TEMPLATES content). This sub-procedure folds the former
Procedure 5-R from METHODOLOGY.md into Procedure 5-C with unified
sidecar naming.

The PROMPT-TEMPLATES.md file is retired by design in v10 — its
content distributes across `docs/pack/prompts/<agent>.md` per-agent
prompt files. The sidecar preserves the project's v9.3 customization
so the developer can redistribute the project-specific edits into the
new per-agent prompt structure.

(Pre-C7 installs may have a sidecar at
`docs/pack/prompts/_v9-backup.md` instead. The procedure below works
identically — substitute the legacy path. The inventory step in
Procedure 5-C.9 explicitly checks for the legacy filename so neither
shape is missed.)

1. **Read the sidecar.** `cat
   docs/pack/PROMPT-TEMPLATES.md.v9-customized`. The file contains the
   project's v9.3 PROMPT-TEMPLATES.md verbatim — pack-baseline
   sections plus project edits intermixed.
2. **Read the v10 per-agent prompt files.** `ls
   docs/pack/prompts/`. The v10 per-agent prompts (`coder.md`,
   `reviewer.md`, `tester.md`, etc., plus the `pm-chat.md` variants)
   contain the v9.3 baseline content reshaped per agent. The
   meaningful diff between the sidecar and the v10 pack content is
   the project-specific customization — the same content that the
   v9.3 pack shipped is already represented in the v10 per-agent
   files modulo reformatting.
3. **PM chat surfaces each project customization with proposed
   placement.** For example: "your project added X to Template 4; in
   v10 this would live in `coder.md ## Variant: fix-cycle` between
   these lines. Approve?" PM chat reads the existing per-agent file
   and proposes the insertion point based on the v10 prompt-section
   convention (METHODOLOGY.md Part 5 § Mandatory section structure).
4. **Developer approves, modifies, or rejects each surfaced item.**
   For project-specific customizations that don't fit into a
   pack-roster prompt section, the developer may opt to land the
   content in a project `x-<agent>.md` variant or in
   `PACK-FEEDBACK.md` for upstream consideration.
5. **PM chat writes approved changes to the relevant per-agent
   file(s).** One write per file; no bulk rewrites. Each write is
   confirmed before the next.
6. **Delete the sidecar.** `rm
   docs/pack/PROMPT-TEMPLATES.md.v9-customized` (or the legacy
   `docs/pack/prompts/_v9-backup.md` for pre-C7 installs).
   Procedure 5-C.1 does not run again. The reconciliation is
   recorded in the migration commit message per Procedure 5-C.9.

Procedure 5-C.1 differs from 5-C.2–5-C.8 in two ways:
- **No file under the original path.** v10 retires
  `docs/pack/PROMPT-TEMPLATES.md`; the sidecar sits beside the
  retired path but no live file pairs with it.
- **Cross-file redistribution.** The reconciliation lands content
  into multiple per-agent prompt files, not back into the original
  file's location. This is the only sub-procedure where reconciled
  content moves to a different path than where the sidecar sits.

Both differences are accommodated by the same sidecar / report /
clear-and-commit mechanism as the other sub-procedures.
```

---

## Part 3 — Completion-check specification

A machine-checkable assertion that Procedure 5-C is complete. The
developer or an automated check (e.g., the `pm-startup` SKILL Step 0
sentinel sweep, OQ-P2) runs all four checks; passing all four
asserts the procedure is complete.

### 3.1 Assertions

**Assertion A — No `.v9-customized` sidecars in working tree.**

```bash
test -z "$(find . -name '*.v9-customized' \
    -not -path './.pack-migration-backup/*' \
    -not -path './.git/*')"
```

Exit zero ⇒ assertion holds. Non-empty output is a list of
unresolved sidecars; reconciliation is incomplete.

**Assertion B — No legacy `_v9-backup.md` under `docs/pack/prompts/`.**

```bash
test ! -f docs/pack/prompts/_v9-backup.md
```

Exit zero ⇒ assertion holds. The legacy filename is removed for
all pre-C7 v10.0 installs and for any post-C7 install (which never
produces this filename). Assertion is permanent — once satisfied,
it stays satisfied.

**Assertion C — Reconciliation rows in `dispositions.tsv` all
addressed.**

The dispositions file lists every file the migration touched with a
disposition. Rows with disposition
`customization-detected-needs-reconciliation` (or `removed-by-design`
with a non-empty sidecar field) require reconciliation. The check:
each such row must have its sidecar absent from disk (per Assertion
A) AND a corresponding entry in the developer's reconciliation
checklist marked done.

The developer's checklist lives at
`.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md` —
a one-line-per-row file the developer maintains during 5-C.2–5-C.8
execution. The format:

```
- [x] CLAUDE.md — kept project's Anti-patterns section, adopted v10 ## Project addenda block
- [x] AGENTS.md — same as CLAUDE.md (trinity)
- [x] GEMINI.md — same as CLAUDE.md (trinity)
- [x] docs/pack/PM-CHAT.md — substituted [PROJECT_NAME], merged Additional documents list
- [x] .claude/settings.json — kept XCODE_SCHEME=OptiquityTrader, adopted v10 permissions schema
...
```

The check verifies that the count of `[x]` lines in the checklist
matches the count of reconciliation-required rows in
dispositions.tsv:

```bash
required=$(awk -F'\t' '$1 ~ /reconciliation/ && $4 != "-"' \
    .pack-migration-backup/v9.3-to-v10.0/dispositions.tsv | wc -l)
checked=$(grep -c '^- \[x\]' \
    .pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md \
    2>/dev/null || echo 0)
test "$required" -eq "$checked"
```

**Assertion D — Working tree on migration branch and commit-ready.**

```bash
test "$(git branch --show-current)" = "migration-v9-to-v10"
test -z "$(git diff --name-only -- '*.v9-customized')"
```

The first command confirms the developer is on the migration branch
(not main). The second confirms no `*.v9-customized` paths appear in
`git diff` (a sanity check redundant with Assertion A but cheap to
run).

### 3.2 One-shot composite check

A single-command composite for the developer or a `pm-startup`
SKILL Step 0 hook:

```bash
scripts/check-procedure-5c-complete.sh
```

The check script runs A + B + C + D and prints PASS / FAIL with the
specific failing assertion. The script itself is out of scope for
this draft (its authoring is BD-059 implementation work, not
documentation work). The assertions above are the specification.

If C7 commits this draft as the procedure body without the check
script, the developer runs the assertions manually per the bash
snippets above. The script can ship in a follow-up commit without
blocking BD-059 resolution.

### 3.3 Re-entrancy guarantee

Procedure 5-C is re-entrant per architect Part 3 design — partial
completion preserves unresolved sidecars on disk; the next
`/pm-startup` re-detects them via Assertion A and re-routes to
Procedure 5-C. The completion criterion (all four assertions pass)
is the same on every re-entry; once it passes, the procedure is
done and the migration commit can land.

---

## Part 4 — Open questions for the implementer

**OQ-5C-1 — `## Project addenda` H2 — empty placeholder vs. comment?**

Procedure 5-C.2 step 2.b directs the developer to land project-only
H2 sections under `## Project addenda` at the bottom of the v10
trinity templates. Plan OQ-4 establishes that this H2 ships in the
v10 templates. **Question:** does the v10 template ship the H2 with
an empty body, with a `<!-- Project addenda go here -->` HTML
comment, or with a one-line instruction (`> Land project-specific
sections under H3 / H4 below this H2`)? Architect prefers the
HTML-comment shape — it is invisible in rendered Markdown, survives
trivial whitespace edits, and lets `validate-pack.py`
`check_trinity_addenda_h2` (Plan OQ-P6) lock both the H2 and the
comment as a single token. Implementer to choose.

**OQ-5C-2 — Reconciliation checklist authoring tool.**

Part 3.1 Assertion C references a developer-maintained checklist at
`.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md`. The
migration script does not currently emit this file; the developer
or PM chat creates it during 5-C execution. **Question:** should the
migration script emit a checklist skeleton (one `- [ ]` line per
reconciliation row in dispositions.tsv) at S7 alongside the
report? Architect prefers yes — emit a skeleton at S7; the
developer ticks `[x]` per resolution. This makes Assertion C
mechanical rather than dependent on developer initiative.
Implementer to decide whether this is C7 scope or a separate
follow-up.

**OQ-5C-3 — `pm-startup` SKILL Step 0 routing for legacy
`_v9-backup.md`.**

Per OQ-P2, `pm-startup` SKILL Step 0 detects sidecars and routes
to Procedure 5-C. **Question:** does Step 0 also detect the legacy
`_v9-backup.md` filename and route to Procedure 5-C.1 specifically,
or does it treat both filenames as a generic "sidecar present"
signal and let the procedure body decide which sub-procedure
applies? Architect prefers the latter (one sentinel, one route);
the procedure body's branch-by-class step (5-C.0 step 4) handles
sub-procedure dispatch. Implementer to confirm.

**OQ-5C-4 — Procedure 5-C.6 trinity-symmetry check tooling.** RESOLVED 2026-04-30.

Original architect lean was eyeball + Pack Chat assistance with a
BD-061-candidate structured-diff helper deferred. User decision
2026-04-30 folded the helper into BD-059 scope ("BD-059 is not done
until everything works — a procedure that requires eyeballed
cross-format diffing is theater"). The helper shipped in commit C7a
as `scripts/compare-agent-trinity.py` with `--all`, `--strict`, and
`--summary-only` modes plus `scripts/test-compare-agent-trinity.sh`
covering 10 unit cases. C7's authored Procedure 5-C.6 step 3 must
reference `scripts/compare-agent-trinity.py <name>` instead of any
eyeball-fallback wording. `validate-pack.py` Check 11 runs the
comparator in lenient `--all` mode informationally on every push.

**OQ-5C-5 — Where does the developer's checklist persist after
commit?**

The reconciliation checklist (Part 3.1 Assertion C) lives under
`.pack-migration-backup/v9.3-to-v10.0/`, which is in the project
gitignore (per S0 stage). The checklist is therefore not committed
with the migration. **Question:** should the migration commit
include the checklist as evidence of reconciliation (e.g., copied
to `docs/migration-evidence/v9.3-to-v10.0/reconcile-checklist.md`),
or is the local `.pack-migration-backup/` copy sufficient and the
backup directory's eventual cleanup (per `MIGRATION-v9-to-v10.md`
§14) takes the checklist with it? Architect prefers committing the
checklist — it provides a permanent record of which sections the
developer kept project / kept pack / hand-merged, valuable for the
next migration. Implementer to decide; minor scope.

---

*End of draft.*
