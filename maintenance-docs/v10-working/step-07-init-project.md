# Step 07 — BD-044 Project Initialization and QUICKSTART Router Design

*Report type: Phase-1 / Step 7 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-architect (read-only session).*
*Date: 2026-04-21.*
*Scope: Resolve OQ-5 and OQ-12; produce a complete design for*
*`init-project.sh`, the QUICKSTART.md three-path router, SETUP-NEW.md,*
*SETUP-EXISTING.md, and the migration-guide naming convention.*
*Inline verification is required at every stage of the flow.*

---

## 0. What this report delivers

| Artifact | Status | Section |
|---|---|---|
| OQ-5 (init-project.sh vs migration script relationship) | Two scripts + shared library at `scripts/lib/detect.sh` | §1 |
| OQ-12 (detection heuristics) | Five-class classification with explicit rules | §2 |
| Preview-and-confirm report format | Concrete example + confirmation contract | §3 |
| New-project path | Stage-by-stage spec | §4 |
| Existing-project path | Stage-by-stage spec, `.gitignore` merge, skip list, transition message, end-of-run PM chat prompt | §5 |
| Inline verification at every stage | Stage-scoped + blast-radius sweep + failure modes | §6 |
| Skill gap tracking | Detection + PM chat prompt instruction | §7 |
| QUICKSTART.md three-path router | Complete rewritten content | §8 |
| SETUP-NEW.md outline | Section list + content pointers | §9 |
| SETUP-EXISTING.md outline | Section list + content pointers | §10 |
| Migration guide naming convention | Rule + authoritative home | §11 |
| V9 Lesson 1 + Lesson 2 applied | Placement table + CLI-fact citations | §12 |
| Design Requirements discharged | Per-requirement crosswalk | §13 |
| Handoffs | Step 8 touch-point + Step 10 verification plan | §14 |

---

## 1. OQ-5 — Two scripts with a shared detection library

### 1.1 Decision

- **Two scripts**, not one with mode flags:
  - `scripts/init-project.sh` — creates a project installation (new or existing)
  - `scripts/migrate-v9-to-v10.sh` — upgrades a v9.3 pack install to v10.0
    (Step 6 §8.1)
- **One shared library** sourced by both: `scripts/lib/detect.sh`.
- Both scripts live in the pack repo's top-level `scripts/` directory (not
  in `project-template/scripts/`; they are pack tooling, never copied into
  projects).

### 1.2 Rationale — why two scripts, not one with mode flags

| Factor | Two scripts | One script with `--init` / `--migrate` mode |
|---|---|---|
| Divergent write logic | init does selective-add + skip; migrate does replace-pack-files + preserve-x-files. Completely different flows | Long conditional branches inside every stage — hard to read, hard to verify |
| Divergent pre-flight invariants | init: no existing AI config; migrate: v9.3 baseline present | Flag gates would skip most checks anyway — the scripts share little beyond detection |
| Failure blast radius | A bug in migration cannot affect a fresh init, and vice versa | A bug in one mode's code path can surface while in the other mode's execution |
| Discoverability | Each script's name describes its purpose | One script, two modes — developer must read `--help` to know it exists |
| Shared code | Sourced library — one source of truth, two consumers | Same — no different |
| Step 6 handoff §12.1 | Explicitly lists pre-flight invariants 1-6 as shared candidates and baseline-invariant check (§2.4) as migration-only | Same conclusion |

Two scripts, one shared library is the elegant split: each consumer reads
cleanly on its own, the shared machinery is not duplicated, and the boundary
between "detect what's on disk" and "decide what to do about it" is
enforced by the module layout.

### 1.3 What the shared library contains

`scripts/lib/detect.sh` provides shell functions. It is sourced, not executed.
Functions are small, named by what they detect, and print structured output
(one fact per line, `key: value` format) that the calling script parses.

```bash
# scripts/lib/detect.sh
# Sourced detection helpers used by init-project.sh and migrate-v9-to-v10.sh.
# Every function is read-only w.r.t. the target project.

detect_clean_working_tree()       # prints: working-tree: clean|dirty
detect_git_repo()                 # prints: git-repo: yes|no
detect_pack_path()                # validates $PACK; prints: pack-path: valid|missing|not-a-repo
detect_pack_version()             # prints: pack-version: v<N.M>  (resolves to latest if $PACK is on main)
detect_ai_config()                # prints: ai-config-markers: <comma-separated list> (empty if none)
detect_x_files()                  # prints: x-files: <path> per line (scans 7 directories per Step 5 §10.2)
detect_improperly_added_files()   # prints: improperly-added: <path> per line
```

Each of these is a candidate from Step 6 §12.1 ("Clean-working-tree check,
Pack repo path verification, x- file audit, Improperly-added file audit").
The x-file and improperly-added audits are shared because both scripts may
want to surface them (init-project.sh for the existing-project path, to
refuse to proceed; migration to preserve).

### 1.4 What stays in init-project.sh (not in the shared library)

- `detect_language_markers()` — Swift (`Package.swift`, `*.xcodeproj`,
  `*.xcworkspace`), Python (`pyproject.toml`), Proto (`proto/`), Kotlin
  (`build.gradle.kts`, `settings.gradle.kts`), TypeScript (`package.json`,
  `tsconfig.json`). Migration-only does not need these — the migration
  already runs inside a pack-configured project with those markers known.
- `detect_source_files()` — count of source-extension files at depth ≤ 2.
  Same reasoning.
- `classify_project_state()` — applies the OQ-12 rules in §2.3. Migration
  does not classify; it expects a v9.3 baseline.
- `compute_skip_list()` — determines which pack files to skip copying based
  on what already exists.
- `compute_gitignore_merge()` — computes appended `.gitignore` entries
  with dedup.
- `generate_pm_chat_prompt()` — formats the end-of-run kickoff prompt with
  detected-gaps instructions.

### 1.5 What stays in migrate-v9-to-v10.sh (not in the shared library)

Per Step 6 §8.1 and §12.1:

- Baseline-invariant checks (`docs/pack/PROMPT-TEMPLATES.md` exists,
  ≥16 pack agents, etc.) — migration-only; init-project has no baseline.
- PROMPT-TEMPLATES.md diff against v9.3 tag.
- x- file preservation logic (the seven-directory in-place skip per
  Step 6 §1.3).
- Python merge helpers (`merge-platform-skills.py`, `merge-trinity.py`).
- Migration stage sentinels (`stage-SN.done`).

### 1.6 Directory layout in the pack repo

```
scripts/
├── init-project.sh              (NEW — BD-044)
├── migrate-v9-to-v10.sh         (NEW — Step 6)
├── merge-platform-skills.py     (NEW — Step 6)
├── merge-trinity.py             (NEW — Step 6)
├── validate-pack.py             (EXISTING — pack CI)
└── lib/
    └── detect.sh                (NEW — shared detection library)
```

`README.md` "Repository Layout" section adds the `scripts/lib/` entry.

### 1.7 Rejected alternatives

- **One script, two mode flags.** Rejected per §1.2.
- **Shared Python module instead of shell library.** Rejected — init-project.sh
  and migrate-v9-to-v10.sh are shell scripts per pack convention (bootstrap.sh,
  validate.sh, format.sh are all shell). Introducing Python for detection
  alone would make either script depend on a Python interpreter for
  pre-flight, which is contrary to the zero-dependency stance. The two
  Python helpers (merge-*.py) are justified only because their work
  (structured markdown splicing) is hard in shell; detection is not.
- **Two scripts, no shared library (duplicate functions).** Rejected —
  divergence is V9 Lesson 4 ("skills distribution changed twice") waiting
  to happen. One source of truth for detection.

---

## 2. OQ-12 — Detection heuristics

### 2.1 Decision summary

A target directory is classified into exactly one of five states. The
classification drives which path the script follows (or whether it refuses
to proceed). Classification is deterministic: same directory contents
always yield the same class.

| State | Meaning | Path taken |
|---|---|---|
| `new-empty` | Git repo, no source, no README (or only `.gitignore`/`LICENSE`), no AI config | New-project path (§4) |
| `new-bare` | Git repo, only `README.md` + optionally `.gitignore` / `LICENSE`, no source, no AI config | New-project path (§4) |
| `existing-bare` | Git repo with docs (`README.md`, `docs/`) but **no** source and no language markers and no AI config | Existing-project path (§5), with a note that source was not detected |
| `existing-source` | Git repo with source files or language markers, no AI config | Existing-project path (§5) |
| `already-configured` | Any AI config marker present | **STOP** — §2.6 stop procedure |

### 2.2 "Source files present" — concrete rules

Two categories of evidence; either one makes the project "existing":

**Strong evidence — language markers (depth ≤ 2)**

| Language | Markers |
|---|---|
| Swift | `Package.swift` (anywhere at depth ≤ 2), `*.xcodeproj`, `*.xcworkspace` |
| Python | `pyproject.toml` |
| Kotlin | `build.gradle.kts`, `settings.gradle.kts`, `build.gradle` |
| TypeScript/Node | `package.json`, `tsconfig.json` |
| Proto | `proto/` directory with at least one `.proto` file |

Any one of the above at the root or at a direct subdirectory (depth ≤ 2)
qualifies as "source present."

**Weak evidence — source-extension files (depth ≤ 2, threshold ≥ 3)**

| Language | Extensions | Threshold |
|---|---|---|
| Swift | `*.swift` | ≥ 3 files |
| Python | `*.py` | ≥ 3 files |
| Kotlin | `*.kt`, `*.kts` | ≥ 3 files |
| TypeScript | `*.ts`, `*.tsx` | ≥ 3 files |

The threshold is 3 to avoid classifying a single example file as
"existing source." A project with exactly one `hello.py` and no
`pyproject.toml` reads as `new-bare` and goes through the new-project
path — which is the safe choice. The developer can always add the
`pyproject.toml` first and re-run init-project.sh if they want the
existing-project path.

**Recursion depth cap: 2.** Only the project root and one subdirectory
level are scanned. Rationale: deep recursion is slow on real projects
(node_modules, build artifacts, DerivedData) and adds no signal. If a
project has source only inside a nested monorepo subdirectory, the
language marker at the subdirectory root still matches at depth 2.

### 2.3 README-only / near-empty classification

| Directory contents | Class |
|---|---|
| Empty directory (no git) | Script refuses — asks the developer to `git init` first |
| `.git/` only | `new-empty` |
| `.git/` + `.gitignore` | `new-empty` |
| `.git/` + `LICENSE` | `new-empty` |
| `.git/` + `README.md` (+ optional `.gitignore`/`LICENSE`) | `new-bare` — proceed as new |
| `.git/` + `README.md` + `docs/` directory containing markdown only | `existing-bare` — proceed as existing; PM chat gets a pointer to the existing docs |
| `.git/` + any source or language marker | `existing-source` |

Rationale: a repo with only a README is functionally fresh — forcing the
existing-project path on it would just prompt the developer to skip
copying a README that the pack doesn't ship anyway. A repo with a `docs/`
tree but no source is a documentation project or a project in pre-code
planning — the PM chat should read those docs for context, so the
existing-project path is correct.

### 2.4 Monorepo detection

A project qualifies as a **monorepo** if `detect_language_markers` returns
two or more distinct language markers (e.g., Swift + Python + Proto).

Handling:
- Classification is still `existing-source` (single state).
- The preview report names every detected language under "Language markers
  found," each with its marker files.
- Skill coverage check runs per language; any language without pack
  skill coverage is reported in the "Pack skill coverage" section.
- The copied template retains all conditional files (`pyproject.toml` +
  `proto/` etc.) — §4.6 removes only files whose language was not
  detected; a monorepo keeps everything for every detected language.
- `bootstrap.sh` already handles multi-language repos (it runs each
  detected language's bootstrap). No additional logic needed.

### 2.5 Platform-marker precedence

When a repo has source for multiple languages, there is no precedence
— all detected languages are reported and all conditional files for
those languages are kept. The pack is additive by design.

The only place precedence would matter is if two markers conflicted in
meaning (e.g., both `Package.swift` and `pyproject.toml`). They don't
conflict; both are kept. This is already the convention of the v9.x
monorepo template.

### 2.6 AI config stop condition

If `detect_ai_config` returns any of the following at the target root,
the script **stops**:

| Marker | Meaning |
|---|---|
| `.claude/` | Claude Code config directory |
| `.codex/` | Codex config directory |
| `.gemini/` | Gemini CLI config directory |
| `CLAUDE.md` | Claude context file |
| `AGENTS.md` | Codex context file |
| `GEMINI.md` | Gemini context file |

Stop procedure:

1. Print a report naming exactly which markers were found.
2. Ask the developer to choose:
   - **(a)** The project already uses this pack — run
     `scripts/migrate-v9-to-v10.sh` instead (follow
     `supporting-docs/MIGRATION-v9-to-v10.md`).
   - **(b)** The project uses some other AI config — remove or archive
     those files before running init-project.sh.
3. Exit with status 20 (AI config present — refusing to proceed).

init-project.sh does not attempt to merge pre-existing AI config. That
is the migration script's job for pack-version upgrades; for any other
tooling, the developer makes the decision before running init. This
matches BD-044's scope statement: "Full merging of existing AI config
or PM docs is explicitly out of scope — the PM chat handles that after
the pack is installed and working."

### 2.7 Detection output — structured report

See §3 for the full preview-and-confirm report. Detection results feed
directly into that report; no intermediate format.

---

## 3. Preview-and-confirm flow

### 3.1 Contract

1. Detection is **read-only**. The only file init-project.sh writes before
   confirmation is the detection report on stdout.
2. Detection completes and prints the full report.
3. The script prompts `Proceed? [y/N]`. Default is **No**. Any answer
   other than `y` / `Y` / `yes` exits with status 0 and writes nothing.
4. Every operation in the report will be executed. If a stage's actual
   operation does not match what the report promised, the inline
   verification (§6) catches it.
5. Between stages, verification runs automatically. On verification
   failure the script stops with a distinct non-zero exit status (§6.3).

### 3.2 Report format (example — existing Swift-only project)

```
init-project.sh detection report
=================================
Target project:  /Users/dev/MyApp
Pack:            /Users/dev/dhs-ai-agent-config-pack  (tag: v10.0)

Classification:  existing-source

Git repo:        yes
Working tree:    clean

Language markers found (depth ≤ 2):
  Swift:    Package.swift, MyApp.xcodeproj
  Python:   (none)
  Kotlin:   (none)
  TypeScript: (none)
  Proto:    (none)

Source files present (depth ≤ 2):
  *.swift: 47

Existing AI config:  none detected  (proceeding)

Pack skill coverage:
  Swift:   FULL        (apple-architecture-core, swift-best-practices, ...)
  (no gaps to report)

Existing docs at depth ≤ 1:
  README.md           (will be kept — skipped from copy)
  docs/ARCHITECTURE.md (will be kept — PM chat kickoff prompt will
                        instruct the PM chat to read it for context)

Planned operations
------------------
  [ADD — new files and directories]
    .claude/agents/              (16 agent files)
    .codex/agents/               (16 agent files)
    .codex/config.toml
    .codex/settings.toml         (if shipped by pack)
    .claude/settings.json
    .gemini/agents/              (16 agent files)
    .claude/skills/              (30 skills × SKILL.md)
    .codex/skills/               (30 skills × SKILL.md)
    .gemini/skills/              (30 skills × SKILL.md)
    CLAUDE.md                    (template — developer fills placeholders)
    AGENTS.md                    (template — developer fills placeholders)
    GEMINI.md                    (template — developer fills placeholders)
    docs/pack/METHODOLOGY.md
    docs/pack/PM-CHAT.md
    docs/pack/PLATFORM-SKILLS.md
    docs/pack/PACK-FEEDBACK.md
    docs/pack/prompts/           (10 per-agent prompt files)
    scripts/bootstrap.sh, bootstrap-swift.sh, bootstrap-python.sh
    scripts/validate.sh, validate-swift.sh, validate-python.sh, validate-proto.sh
    scripts/format.sh, format-swift.sh, format-python.sh
    scripts/test.sh, test-swift.sh, test-python.sh
    scripts/proto-gen.sh
    scripts/agent-post-edit-check.sh
    agent-run.sh                 (agent launcher — chmod +x applied)
    .mcp.json.example

  [MERGE — appended and deduplicated]
    .gitignore                   (pack entries appended; 4 new lines, 0 duplicates)

  [CONDITIONAL REMOVE — files shipped by pack that don't apply here]
    pyproject.toml              (no Python detected — not copied)
    pyrightconfig.json          (no Python detected — not copied)
    server/                     (no Python server — not copied)

  [SKIP — existing files preserved as-is]
    README.md                   (exists — untouched)
    LICENSE                     (exists — untouched)
    Package.swift               (language marker — untouched)
    MyApp.xcodeproj             (language marker — untouched)
    docs/ARCHITECTURE.md        (existing doc — untouched)
    .gitignore                  (merged, not overwritten — see MERGE above)

  [END-OF-RUN OUTPUT]
    A PM chat kickoff prompt will be printed to stdout. It instructs the
    PM chat to:
      - Read docs/ARCHITECTURE.md (and any other existing docs the
        developer names) for context before context-file kickoff.
      - Log any pack skill gaps detected above to
        docs/pack/PACK-FEEDBACK.md.
      - Proceed through normal PM chat kickoff (Template 1 —
        docs/pack/prompts/pm-chat.md variant: kickoff).

Developer transition notice
---------------------------
After this run, your project will use the pack's file names and
locations as the standard going forward:
  - Agent config: .claude/, .codex/, .gemini/
  - Context: CLAUDE.md, AGENTS.md, GEMINI.md at the project root
  - Methodology & templates: docs/pack/
  - Scripts: scripts/
  - Agent launcher: agent-run.sh at the project root

Your existing README.md, LICENSE, Package.swift, MyApp.xcodeproj, and
docs/ARCHITECTURE.md are unchanged and will continue to be authoritative.

Proceed? [y/N]
```

For a `new-empty` or `new-bare` project, the [SKIP] list is empty or
contains only `README.md`/`.gitignore`, and the transition notice is
replaced with a one-line "This is a fresh project; no existing files
preserved." Otherwise the format is identical.

### 3.3 Confirmation contract

- Only `y`, `Y`, or `yes` (case-insensitive) proceeds.
- Any other answer (including blank, `n`, `N`, `no`, `q`, Ctrl-D/EOF)
  exits with status 0 and no files changed. stdout: `Aborted. No files
  were changed.`
- SIGINT (Ctrl-C) at the prompt is treated the same as `n`.
- If stdin is not a terminal (piped input), the script reads one line
  and applies the same rule. Scripts that wrap init-project.sh can
  pipe `yes` to auto-confirm (useful for CI dry runs), but the default
  is always confirm-required.

---

## 4. New-project path (`new-empty` and `new-bare`)

Applies to classes `new-empty` and `new-bare`. The project has no source,
no AI config, and at most a `README.md` / `.gitignore` / `LICENSE`.

### 4.1 Stages

| Stage | Operation |
|---|---|
| **S0** | Detection and preview (§3) — read-only |
| **S1** | Create directory skeleton (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `docs/pack/`, `docs/project/`, `docs/reference/`, `scripts/`) |
| **S2** | Copy pack agent files from `$PACK/project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/` |
| **S3** | Copy `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` from `$PACK/project-template/` |
| **S4** | Distribute skills — for each `$PACK/project-template/skills/<name>/`, copy `SKILL.md` into `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, `.gemini/skills/<name>/SKILL.md` |
| **S5** | Copy `scripts/` content from `$PACK/project-template/scripts/` and `agent-run.sh` from `$PACK/project-template/agent-run.sh`. Apply `chmod +x` to `agent-run.sh` and every `scripts/*.sh` |
| **S6** | Copy `docs/pack/` content: `METHODOLOGY.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md`, `prompts/` (entire directory per Step 4 §2.3 file list) |
| **S7** | Copy `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` from `$PACK/project-template/` to project root |
| **S8** | `.gitignore` — if exists: merge (append pack lines, dedupe). If not: copy `$PACK/project-template/.gitignore` |
| **S9** | Conditional removal — per detected language, remove pack files that don't apply: Swift-only removes `pyproject.toml`, `pyrightconfig.json`, `server/`; Python-only removes `proto/` unless proto detected; etc. For `new-empty` / `new-bare` this stage is effectively a no-op because nothing was detected — §4.6 handles it. |
| **S10** | Generate and print end-of-run PM chat kickoff prompt (§7.2) |

Each stage has its own verification (§6).

### 4.2 Source of truth for file lists

The set of files copied at each stage is **derived from the pack repo
contents at the pinned version**, not hardcoded in init-project.sh.
The script enumerates `$PACK/project-template/` directories and copies
what it finds.

Rationale: this avoids drift between the script and the pack template.
If v10.1 adds a new agent, init-project.sh v10.1 picks it up automatically
with no code change. The verification step at §6 asserts that the copied
count matches the pack's count — i.e., no stale hardcoded list ever goes
unnoticed.

### 4.3 Pack version pinning

The developer points `$PACK` at a specific pack checkout. The script
reads `$PACK`'s current HEAD and tag, and includes the resolved pack
version in the detection report. If `$PACK` is on a branch (not a tag),
the report labels it `(unreleased — branch <name>)` and the confirmation
prompt warns the developer explicitly before proceeding. This is
consistent with the v8-to-v9 migration convention (developer chooses
`$PACK` checkout).

### 4.4 For `new-bare` specifically: README.md handling

A `new-bare` project has an existing `README.md`. The pack ships no
top-level `README.md` in `project-template/`, so there is no file
conflict. The detection report lists it under [SKIP], but the operation
is a no-op because nothing is copied over it.

### 4.5 Conditional files — what the pack ships unconditionally vs. what it removes based on detection

The unified v9 template ships all conditional files (Python, Proto, etc.)
and documents in QUICKSTART.md Step 2 that the developer removes what
doesn't apply.

v10 inverts this: init-project.sh runs the removal for them, based on
detected language markers.

| Pack file | Kept when | Removed when |
|---|---|---|
| `pyproject.toml`, `pyrightconfig.json` | Python detected | Python not detected |
| `server/` (Python server scaffold) | Python detected | Python not detected |
| `proto/` | Proto detected (proto directory at marker scan) or user flag `--with-proto` (future) | Proto not detected |
| `scripts/bootstrap-python.sh`, `format-python.sh`, `validate-python.sh`, `test-python.sh` | Python detected | Python not detected |
| `scripts/bootstrap-swift.sh`, `format-swift.sh`, `validate-swift.sh`, `test-swift.sh` | Swift detected | Swift not detected |
| `scripts/validate-proto.sh`, `proto-gen.sh` | Proto detected | Proto not detected |

For `new-empty` / `new-bare`, nothing is detected. Default behavior:
copy **everything**, because the developer will add source next and
the pack's unified template is the baseline they're working from. The
developer can remove unused conditional files by hand (the current
QUICKSTART Step 2 remains the fallback), or re-run init-project.sh
**after** adding source files to trigger the language-aware removal.

This preserves backward compatibility with the v9 mental model for
fresh projects while adding language-aware pruning for existing
projects that already have source.

### 4.6 Rejected alternatives

- **Prompt the developer interactively to choose languages at init.**
  Rejected — init-project.sh is a one-shot confirm-and-go script. Adding
  interactive multi-choice prompts contradicts the preview-and-confirm
  contract (§3.1) and adds nothing that the language detection doesn't
  already cover for projects with source. For new projects, copying the
  full unified template is cheap and aligns with the v9.x default.
- **Make the developer specify `--languages swift,python` on the
  command line.** Rejected — creates a second source of truth (flag
  vs. detection) and is rarely used. Detection is authoritative.
- **Drop conditional removal entirely — always copy everything.**
  Rejected — for existing projects, copying `pyproject.toml` into a
  Swift-only repo would be confusing. For new projects, keep the
  v9 behavior (copy all) because nothing is detectable yet.


---

## 5. Existing-project path (`existing-bare` and `existing-source`)

Applies to classes `existing-bare` and `existing-source`. The project has
docs or source, no AI config.

### 5.1 Stages

Identical stage list to §4.1 (S0-S10), with three behavioral differences:

- **S7 (context files).** If any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
  exist at the project root, the AI config stop condition (§2.6) already
  triggered and the script never reached S7. So at S7, trinity files do
  not exist — they are written fresh from the pack template. No skip
  logic is needed in this stage.

- **S8 (.gitignore).** Append + dedupe. Specified precisely in §5.2.

- **S9 (conditional removal).** Applies detected-language-based pruning.
  This is where existing-project diverges from new-project: the detection
  knows which languages are actually used, so the pack's unified template
  is trimmed accordingly.

- **S10 (end-of-run prompt).** The prompt includes a pointer to existing
  docs (§7.2) and the skill-gap instruction (§7.1).

### 5.2 `.gitignore` merge

**Intent.** The existing project may already have a `.gitignore` tuned
for its language. The pack ships a `.gitignore` with agent-config-specific
entries (`.claude/settings.local.json`, `.mcp.json`, generated Protobuf
output, etc.). Both must be present after init.

**Algorithm.**

1. Read the project's existing `.gitignore` (if absent, copy the pack's
   `.gitignore` verbatim — done).
2. Read `$PACK/project-template/.gitignore`.
3. For each line in the pack `.gitignore`:
   - If the literal line (after trim of trailing whitespace) is not
     already present in the project's `.gitignore`, append it.
   - Blank lines and comment-only lines are deduped too (don't append
     a second `# Agent config` comment header if one already exists with
     the same text).
4. Preserve the project's existing line ordering. Pack additions go at
   the bottom under a header comment:
   ```
   # --- AI Agent Config Pack additions (v10.0) ---
   ```
5. Write the merged file. Emit a stage-verification line counting how
   many pack lines were new vs. already present.

**Rejected alternative — sort + unique the whole file.** Rejected because
ordering in `.gitignore` sometimes matters (ignore patterns, `!` negation
lines). Preserving the project's order and appending pack additions is
safer.

**Rejected alternative — overwrite the project's `.gitignore`.**
Rejected per BD-044: "selective copy (add-don't-overwrite)."

### 5.3 Skip list

Files that init-project.sh **never overwrites**, regardless of detection:

| File pattern | Rationale |
|---|---|
| `README.md` | Project's own documentation |
| `LICENSE`, `LICENSE.*` | Project's license |
| `Package.swift`, `*.xcodeproj`, `*.xcworkspace` | Swift project manifests / Xcode workspace |
| `pyproject.toml`, `poetry.lock`, `uv.lock`, `requirements*.txt` | Python project manifests |
| `build.gradle*`, `settings.gradle*` | Kotlin project manifests |
| `package.json`, `tsconfig.json`, `package-lock.json`, `yarn.lock` | Node/TypeScript manifests |
| `.git/`, `.git*` files (except `.gitignore` which is merged) | Git internals |
| Any file inside `docs/` that already exists **at the filename level** | Preserve project docs |
| Any file inside `scripts/` that already exists with the same filename | Preserve project scripts |

**Handling an existing `scripts/` directory.** If the project has its own
`scripts/` (e.g., `scripts/build.sh`), init-project.sh copies the pack's
scripts into `scripts/` **without overwriting** any file that already
exists. If a pack script name collides with an existing project script
(e.g., project has its own `bootstrap.sh`), the pack script is skipped
and the detection report lists the collision under [SKIP — existing
project scripts] with a recommendation to rename and re-run.

**Handling an existing `docs/` directory.** Pack content lands only in
`docs/pack/` (new subdirectory — no project has this pre-init). The
project's existing `docs/` content is untouched.

**Handling an existing `agent-run.sh`.** The pack ships `agent-run.sh`
at the project root; a project without AI config is extremely unlikely
to have this filename already. If it does, it gets skipped and reported.

### 5.4 Developer transition message

Shown inside the detection report (see §3.2) under the "Developer
transition notice" heading. Also emitted after stage S10 as a final
summary line so the developer sees it at both confirmation time and
completion time.

Verbatim text:

```
After this run, your project will use the pack's file names and
locations as the standard going forward:
  - Agent config:  .claude/, .codex/, .gemini/
  - Context:       CLAUDE.md, AGENTS.md, GEMINI.md at the project root
  - Methodology:   docs/pack/ (METHODOLOGY, PM-CHAT, PLATFORM-SKILLS,
                   PACK-FEEDBACK, prompts/)
  - Scripts:       scripts/
  - Launcher:      agent-run.sh at the project root

Your existing README, LICENSE, language manifest, and project docs
are unchanged and will continue to be authoritative.
```

Rationale: BD-044 requires the script to state this explicitly so the
developer knows the pack's structure is now canonical and shouldn't
be renamed to match their previous structure. This is the "pack file
names and locations are the standard going forward" message.

### 5.5 End-of-run PM chat kickoff prompt

See §7.2 for the full prompt. Generated by `generate_pm_chat_prompt()`
(§1.4) and printed to stdout at stage S10. The developer copies it
and pastes into their PM chat on first run.

### 5.6 Rejected alternatives

- **Interactive per-file overwrite prompts.** Rejected — preview-and-
  confirm at the top handles the decision once. Re-prompting per file
  fragments attention and breaks the "confirm once, go" flow.
- **Three-way merge for `.gitignore`.** Rejected — append + dedupe is
  simpler, covers all realistic cases, and the developer can sort the
  result manually if they want.
- **PM chat prompt as a file on disk (`FIRST-RUN-PROMPT.md`) instead
  of stdout.** Considered — the current v9 approach for SETUP.md and
  AGENT_KICKOFF.md writes to disk. For init-project.sh, stdout is
  preferred because (a) the prompt is intended for one-time paste, not
  permanent storage, (b) writing it to the repo would commit a
  transient artifact, (c) the PM chat's own record of its kickoff is
  committed into `PM-CHAT.md` and `docs/project/STATUS.md` after
  kickoff runs, which is the right permanent record. A tee option
  (`init-project.sh --prompt-to FILE`) may be added later if needed.

---

## 6. Inline verification at every stage

### 6.1 Principle

Each stage of init-project.sh verifies its own work before the next
stage begins. Verification scope is **wider than the immediate change
set** (V10-PREDESIGN Part 7): after writing files, the script also
greps for references to those files elsewhere in the project to catch
stale or missing cross-references that a naive "did the cp succeed"
check would miss.

### 6.2 Per-stage verification

| Stage | What the stage did | Verification (must all pass) |
|---|---|---|
| **S0 — Detection** | Read-only; printed report; got confirmation | - Confirmation was explicit `y` / `Y` / `yes`. - `$PACK` exists and `$PACK/project-template/` exists. - Target is a git repo (`.git/` present). - If non-`already-configured`: `detect_ai_config` still returns empty (race-check). |
| **S1 — Directory skeleton** | Created expected directories | All expected directories exist (`-d` checks). No unexpected directories at project root that the script didn't intend to create. |
| **S2 — Agent files** | Copied pack agent files for three tools | `ls .claude/agents/*.md \| wc -l` equals `ls $PACK/project-template/.claude/agents/*.md \| wc -l`. Same check for `.codex/agents/*.toml` and `.gemini/agents/*.md`. **Trinity parity check:** set of filename stems is identical across `.claude/agents/`, `.codex/agents/`, and `.gemini/agents/` (the only extension difference is `.md` vs `.toml`). |
| **S3 — Configs** | Copied `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` | Each file exists and is non-empty. `.codex/config.toml` contains `[profile` header (sanity check on not-a-stub). |
| **S4 — Skills** | Distributed skills to three tool directories | For every `$PACK/project-template/skills/<name>/`, confirm `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, and `.gemini/skills/<name>/SKILL.md` all exist. **Byte-identical check:** `diff -r` pack skill body vs. copied body for Claude (the tool with full directory copy per current v9 model). |
| **S5 — Scripts** | Copied scripts and agent-run.sh | Every script in `$PACK/project-template/scripts/` that should be present (after §4.6 conditional removal) is present in `scripts/`. Every such script has `-x` (executable) permission. `agent-run.sh` exists at project root with `-x`. |
| **S6 — docs/pack/** | Copied METHODOLOGY, PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK, prompts/ | All five artifacts present. `docs/pack/prompts/` contains exactly the file list from Step 4 §2.3 (10 files). Each prompt file passes the Step 4 §4.5 format check (frontmatter + `## Variant:` headings). **PLATFORM-SKILLS.md contains `## Custom skills` and `## Custom agents` section headers** per Step 5 §5.2, §12.1, §12.2 (not populated; headers and placeholder lines only). |
| **S7 — Context files** | Copied CLAUDE.md, AGENTS.md, GEMINI.md | All three exist. Each contains at least one `[PLACEHOLDER]` marker (proves it's the template, not a pre-filled variant). **Trinity rule sanity:** same set of top-level section headings appears in all three (e.g., `## Core priorities`, `## Capability policy`, `## Phase routing`). |
| **S8 — .gitignore** | Merged pack entries | Every line in `$PACK/project-template/.gitignore` is present (verbatim match) in the project's `.gitignore`. Dup count reported matches the number of lines already present before merge. |
| **S9 — Conditional removal** | Removed pack files that don't apply | For each language **not** detected, no pack-origin file for that language exists in the project (e.g., no `pyproject.toml` if Python not detected, etc.). For each language **detected**, all its pack files are still present. |
| **S10 — End-of-run prompt** | Generated and printed PM chat kickoff prompt | The printed prompt contains: project absolute path; pack version string; pointer line to existing docs (only on existing-project path) referencing real existing filenames; skill-gap instruction (only if gaps detected) naming the exact gap languages; `docs/pack/prompts/pm-chat.md` variant reference. |

### 6.3 Blast-radius-wider-than-change-set sweep

After S6 (pack content installed) and again after S10 (end-of-run), the
script runs a grep sweep across all copied pack files for references
that the pack shouldn't contain and shouldn't have missed:

| Sweep check | What it catches |
|---|---|
| **No `PROMPT-TEMPLATES.md` references.** `grep -r PROMPT-TEMPLATES .claude .codex .gemini docs/pack CLAUDE.md AGENTS.md GEMINI.md agent-run.sh scripts/` must return zero matches. | A stale v9 pack reference carried into v10. |
| **No `[PROJECT_NAME]` placeholders in files the script should have filled.** For files the init script does NOT fill (CLAUDE.md, AGENTS.md, GEMINI.md), placeholders are expected. For PM-CHAT.md and PACK-FEEDBACK.md, placeholders are also expected (PM chat fills at kickoff). If a file the pack ships with no placeholders suddenly has one, the pack is broken. The sweep records current placeholder counts in the verification output for reference; does not fail. | Diagnostic baseline — not a hard failure, but surfaces pack template bugs. |
| **Every referenced skill exists.** Grep PLATFORM-SKILLS.md for skill names (pattern: `apple-architecture-core`, `swift-best-practices`, etc.) and verify each is present in `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`. | A stale reference in PLATFORM-SKILLS.md to a skill that wasn't copied. |
| **Every referenced prompt file exists.** Grep PM-CHAT.md and CLAUDE.md / AGENTS.md / GEMINI.md for `docs/pack/prompts/<name>.md` references; each must exist. | A stale reference to a prompt file missed during pack copy. |
| **Every referenced script exists.** Grep CLAUDE.md / AGENTS.md / GEMINI.md "Scripts" table for script names; each must exist in `scripts/` (accounting for §4.6 removal). | Script referenced in context file but not shipped after conditional removal. |
| **Trinity parity on routing tables.** The Phase routing table in CLAUDE.md, AGENTS.md, GEMINI.md contains the same set of agents. Confirmed by extracting the Agent column of each and diffing. | Trinity asymmetry introduced at pack-copy time (V9 Lesson 3). |

The blast-radius sweep is not stage-scoped; it runs once at end of S6
(first chance to run across the installed pack content) and once at
end of S10 (catches conditional-removal gaps). A failure stops the
script with a diagnostic listing the exact filename and stale reference.

### 6.4 Failure modes and exit codes

| Exit code | Meaning |
|---|---|
| 0 | Success, or developer declined at prompt |
| 10 | `$PACK` not set, missing, or not a pack repo |
| 11 | Target is not a git repo |
| 12 | Working tree not clean (existing-source path only; script asks for clean before overwriting `.gitignore`) |
| 20 | Stop — existing AI config detected (§2.6) |
| 21-30 | Stage N (S1-S10) verification failed — code = 20 + N |
| 31 | Blast-radius sweep failure |
| 40 | Conditional-removal failure (§4.6) |
| 99 | Internal error (bash `set -euo pipefail` trap) |

On any non-zero exit after S1 has begun, the script prints:

```
init-project.sh FAILED at stage S<N>: <short diagnostic>
The project is in a partial state. Options:
  - Inspect the partial files: git status
  - Roll back: git reset --hard && git clean -fd
    (WARNING: this removes everything not in the last commit)
  - File a bug: include the exit code, stage, and the last 20
    lines of output.
```

The script does **not** attempt automatic rollback. Rationale: rollback
requires knowing which files existed before init (only `git status`
accurately knows), and `git reset --hard` is the documented procedure
the developer chooses explicitly. Automatic rollback would mask
verification failures and make debugging harder.

### 6.5 Why verification runs inline rather than at the end

V10-PREDESIGN Part 7: "Each stage actively checks that the work it
just did is correct before proceeding." Rationale:

- **Earliest possible failure.** A broken S2 (agent files missing)
  should stop before S3 copies configs that reference those agents.
- **Diagnostic specificity.** "S2 failed: `.codex/agents/` has 14 files,
  pack has 16" is more actionable than "End-of-run sweep found 2
  missing references in PM-CHAT.md."
- **Blast-radius catch.** Stage-local verification catches what the
  stage directly did; blast-radius sweeps catch what the stage
  affected elsewhere. Both are needed.
- Mirrors Step 6 §7 migration's seven-stage post-assertion pattern
  (reference pattern per V10-PREDESIGN Part 7).

---

## 7. Skill gap tracking

### 7.1 Detection

After `detect_language_markers` runs, init-project.sh compares the
detected languages against the pack's skill coverage table. The
coverage table lives in `scripts/lib/detect.sh` as a constant:

```bash
# scripts/lib/detect.sh
PACK_SKILL_COVERAGE="\
swift:apple-architecture-core,swift-best-practices
python:python-architecture-core,python-best-practices
proto:grpc-patterns
"
```

(Table illustrative; actual list derived from `project-template/skills/`
at implementation time.)

`detect_skill_gaps()` returns the set of detected languages for which
no skill is listed in the coverage table. Example output:

```
skill-gaps: kotlin,typescript
```

The detection report (§3.2) includes a `Pack skill coverage` section
per-language. Languages with no coverage are marked `NO COVERAGE` and
listed in the gap set.

### 7.2 End-of-run PM chat kickoff prompt

Format (conditional blocks only appear when relevant):

```
You are the PM chat for [PROJECT_NAME at /Users/dev/MyApp].

The AI Agent Config Pack v10.0 has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
Template 1 (docs/pack/prompts/pm-chat.md, variant: kickoff).

{IF existing-project path AND existing docs detected}
This is an existing project with prior documentation. Before
proceeding with the usual context-file placeholder fill-in, read
the following existing documents for context, and confirm with the
developer which other existing docs they want you to read:

  - docs/ARCHITECTURE.md
  - README.md

If the developer points you at additional files (inline design notes,
ADRs, wiki exports, etc.), read those too before generating
architecture content.
{END IF}

{IF skill gaps detected}
init-project.sh detected language/platform markers for which this
pack version has no skill coverage:

  - kotlin
  - typescript

When you complete kickoff, append an entry to
docs/pack/PACK-FEEDBACK.md under the "Language/platform coverage
gaps" section, including:
  - The language or platform name
  - The project stage (from Template 1 kickoff output)
  - A short note on the kinds of guidance the project would benefit from
{END IF}

Run /pm-startup (or your CLI's equivalent), then apply Template 1 with
the developer.
```

### 7.3 Why skill-gap logging happens in the PM chat, not in init-project.sh

- **Context.** The PM chat has project-stage, architecture-brief, and
  developer intent available after kickoff. A log entry written by a
  shell script has none of that context — it would be a shallow note.
- **PACK-FEEDBACK.md is the PM chat's file.** Per `project-template/CLAUDE.md`
  Document locations table, PACK-FEEDBACK.md is "appended by PM chat during
  project." Shell scripts do not write to PACK-FEEDBACK.md.
- **Placement rationale (V9 Lesson 1).** Skill-gap logging is a
  one-time-per-project task that requires project knowledge; PM chat
  is the right owner. init-project.sh detects and instructs; PM chat
  records.

---

## 8. QUICKSTART.md as a three-path router

### 8.1 Decision

QUICKSTART.md becomes a short routing document. No procedural content.
One short paragraph per path, each pointing to the authoritative guide
in `supporting-docs/`. Any existing procedural content moves into
SETUP-NEW.md (§9) or SETUP-EXISTING.md (§10).

### 8.2 Full content of the new QUICKSTART.md

```markdown
# AI Agent Config Pack — Quick Start

This pack configures Claude Code, Codex CLI, Gemini CLI, and Xcode
to follow your project's architecture rules, coding standards, and
conventions automatically — without repeated prompting.

## Which path are you on?

### New project — you are creating a new repo (no code yet, or only a README)

Follow **[`supporting-docs/SETUP-NEW.md`](supporting-docs/SETUP-NEW.md)**.
You will run `scripts/init-project.sh` from the pack; it copies the agent
files, skills, scripts, and context-file templates into your new project
and prints a PM chat kickoff prompt at the end.

### Existing project — you have an existing project with no AI tooling

Follow **[`supporting-docs/SETUP-EXISTING.md`](supporting-docs/SETUP-EXISTING.md)**.
You will run the same `scripts/init-project.sh`; it detects your existing
source files and docs, previews what it will do, and adds the pack
without overwriting your existing files. The script stops automatically
if any prior AI agent config is detected.

### Pack version upgrade — you already use the pack and want the next major version

Follow the version-specific migration guide in `supporting-docs/`.
For v9 → v10, that is **[`supporting-docs/MIGRATION-v9-to-v10.md`](supporting-docs/MIGRATION-v9-to-v10.md)**.

Version-specific migration guides are always named `MIGRATION-vN-to-vM.md`
and always land in `supporting-docs/`. If you are on an older major
version, first apply the intermediate guide(s) in sequence.

---

See `README.md` for the full version history and repository layout.
```

That is the entire new QUICKSTART.md — approximately 30 lines. Anything
procedural (Xcode scheme config, Xcode companion install, swift-format
install, PM chat options, phase routing cheat sheet, "what NOT to put
in git") moves to SETUP-NEW.md and/or SETUP-EXISTING.md.

### 8.3 Cross-reference updates

Any file in the pack that currently references a specific QUICKSTART.md
step by number (e.g., "see QUICKSTART.md Step 10") must be updated to
point at the new authoritative doc. Step 8 (touch-point consolidation)
inherits this sweep — §14.1 §14.3 list the known referrers.

### 8.4 Rejected alternatives

- **Keep QUICKSTART.md as the new-project procedure + add sections for
  existing and upgrade.** Rejected — BD-044 is explicit: "no procedural
  content in QUICKSTART.md." Keeping procedure here reintroduces the
  single-file readability problem this split is meant to solve.
- **Router plus the new-project procedure (combine §8.2 + §9 in one
  file).** Rejected — the existing-project and upgrade paths are
  substantial enough (SETUP-EXISTING.md ~100 lines, MIGRATION-v9-to-v10.md
  per Step 6 §9.1 is substantial) that the new-project procedure would
  dominate QUICKSTART.md. The router is cleanest as its own ~30-line doc.

---

## 9. SETUP-NEW.md outline

### 9.1 Role

SETUP-NEW.md is the full procedural guide for a developer who has
just created a new git repo and wants to install the pack. It is the
authoritative destination for anything QUICKSTART.md v9 currently
contains about new-project setup, with content updated to use
`init-project.sh` instead of manual `cp -r` + skill distribution.

### 9.2 Section list

| § | Heading | Content source / notes |
|---|---|---|
| Title | `# [PROJECT_NAME] — Setting up a New Project with the AI Agent Config Pack` | New heading; identifies the doc's role |
| Prerequisites | `## Prerequisites` | macOS version, Xcode version, git, GitHub CLI optional, pack repo cloned locally. Lifted from current QUICKSTART top matter and SETUP_TEMPLATE.md §Prerequisites |
| 1 | `## Step 1 — Create the GitHub repo` | `gh repo create` or manual. Lifted from SETUP_TEMPLATE §1 |
| 2 | `## Step 2 — (Apple projects) Create the Xcode project` | Lifted from SETUP_TEMPLATE §2 |
| 3 | `## Step 3 — Run init-project.sh` | **NEW.** `PACK=...`, `cd project`, `bash "$PACK/scripts/init-project.sh"`, review preview, type `y`. Replaces current QUICKSTART Step 1 (`cp -r`) + Step 2 (remove conditional files) + Step 4 (chmod + skill distribution) — all three are now automated. |
| 4 | `## Step 4 — Fill in context file placeholders` | Lifted from current QUICKSTART Step 3. Trimmed to just the placeholder list; the PM chat fills most of them at kickoff. |
| 5 | `## Step 5 — (Apple projects) Fill in Xcode scheme variables` | Lifted from current QUICKSTART Step 5 |
| 6 | `## Step 6 — (Apple projects) Install swift-format` | Lifted from current QUICKSTART Step 6 |
| 7 | `## Step 7 — (gRPC projects) Set up proto code generation` | Lifted from current QUICKSTART Step 7 |
| 8 | `## Step 8 — (Apple projects) Install Xcode companion files (once per Mac)` | Lifted from current QUICKSTART Step 8 |
| 9 | `## Step 9 — Initial commit` | Lifted from current QUICKSTART Step 9 |
| 10 | `## Step 10 — Set up the PM chat` | Lifted from current QUICKSTART Step 10 (Option A — Desktop; Option B — Claude Code CLI; Option C — Gemini CLI). Update any `PROMPT-TEMPLATES.md` references to `docs/pack/prompts/pm-chat.md` per Step 4 §6.2. |
| 11 | `## Step 11 — Generate SETUP.md and AGENT_KICKOFF.md` | Lifted from current QUICKSTART Step 11. Template references update to `docs/pack/prompts/pm-chat.md` variants `generate-setup` and `generate-agent-kickoff`. |
| 12 | `## Step 12 — Run the architecture kickoff` | Lifted from current QUICKSTART Step 12 |
| Reference | `## Common agent invocations`, `## Phase routing cheat sheet`, `## What NOT to put in Git`, `## Reference documents (not copied into project repos)` | Lifted verbatim from current QUICKSTART §§ of the same names |
| Migration note | `## Upgrading to a future major version` | One-paragraph pointer: version upgrades follow `MIGRATION-vN-to-vM.md`; always lives in `supporting-docs/` (§11 authoritative). |

### 9.3 Size and shape

Approximately 300-400 lines when lifted from current QUICKSTART.md
(which is ~493 lines) minus the ~90 lines of Step 1/2/4 that
init-project.sh replaces.

### 9.4 SETUP_TEMPLATE.md coordination

SETUP_TEMPLATE.md is the template the PM chat uses at Step 11 to
generate the project-specific SETUP.md. Current content at §4 (copy
agent config files) must change to point at `init-project.sh` instead
of manual `cp -r`, and the QUICKSTART step-number references in §11
("Follow QUICKSTART.md Step 10, Option B") must be rewritten to
reference SETUP-NEW.md by section name (not step number).

This is in §14.1 touch points (edit SETUP_TEMPLATE.md).

---

## 10. SETUP-EXISTING.md outline

### 10.1 Role

SETUP-EXISTING.md is the procedural guide for a developer adding the
pack to a project that already has source code, docs, or both, but no
prior AI agent config. It describes the preview-and-confirm flow
explicitly, calls out the developer transition message, and documents
the end-of-run PM chat onboarding step.

### 10.2 Section list

| § | Heading | Content source / notes |
|---|---|---|
| Title | `# [PROJECT_NAME] — Adding the AI Agent Config Pack to an Existing Project` | |
| Scope | `## What this path is for` | Explicit scope statement: "You have a project under development with source files and/or existing docs, no prior AI agent config, and you want to add the pack without losing your existing work." Includes stop condition: "If you already have `.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`, this is not the right path — use the migration guide (§11) or remove the existing AI config first." |
| Prerequisites | `## Prerequisites` | macOS, Xcode, git, pack repo cloned locally. **Additionally: clean working tree and a branch for the pack-init commit.** |
| 1 | `## Step 1 — Create the pack-init branch` | `git checkout -b pack-init` |
| 2 | `## Step 2 — Run init-project.sh and review the preview` | `PACK=...`, `bash "$PACK/scripts/init-project.sh"`, preview appears, **walk through the detection report section by section**: Classification, Language markers, Source files, Existing AI config (must be `none detected`), Pack skill coverage, Existing docs, Planned operations (ADD/MERGE/CONDITIONAL REMOVE/SKIP), End-of-run output, Developer transition notice. Confirm with `y`. |
| 3 | `## Step 3 — Review the stage verification output` | As each stage completes, init-project.sh prints a verification summary. The developer scans for anything unexpected. Pointers to the exit-code meanings in §6.4. |
| 4 | `## Step 4 — Fill in context file placeholders` | Same as SETUP-NEW §4. The existing project's language and platform flow into the `[PLATFORM_DEFAULTS]` the developer fills in. |
| 5 | `## Step 5 — (Apple projects) Fill in Xcode scheme variables` | Same as SETUP-NEW §5 |
| 6 | `## Step 6 — (Apple projects) Install Xcode companion files (once per Mac)` | Same as SETUP-NEW §8 |
| 7 | `## Step 7 — Commit the pack-init changes` | `git add -A`, review staged files, commit. Recommended commit message: `chore: add AI agent config pack v10.0`. Push the pack-init branch for merge. |
| 8 | `## Step 8 — Start the PM chat and paste the kickoff prompt` | The end-of-run PM chat prompt was printed to stdout by init-project.sh. Copy it into your chosen PM chat surface (Desktop app, Claude Code CLI, Codex CLI, or Gemini CLI; cross-references SETUP-NEW §10 for the three-option PM chat setup). |
| 9 | `## Step 9 — PM chat onboarding — existing docs pointer` | **Key new procedure.** The PM chat reads whatever existing docs the developer points it at before filling context files. Procedure: before the PM chat moves from Template 1 kickoff to `[PLATFORM_ARCHITECTURE]` fill-in, the developer says "Read docs/ARCHITECTURE.md, docs/DESIGN-NOTES.md, and the `// ARCHITECTURE:` inline comments in sources/, then summarize what you learned." The PM chat acknowledges and either proceeds or asks clarifying questions about the existing material. |
| 10 | `## Step 10 — PM chat kickoff and architecture assessment` | The PM chat proceeds with Template 1. It produces an initial architecture assessment that reflects (a) the pack's architecture rules and (b) what it read from existing docs. The developer and PM chat reconcile — if the existing architecture is compatible, proceed; if incompatible, the PM chat flags the conflict and the developer decides. |
| 11 | `## Step 11 — Skill gap follow-up` | If init-project.sh reported skill gaps, confirm the PM chat has logged them to `docs/pack/PACK-FEEDBACK.md`. |
| 12 | `## Step 12 — Continue as normal` | From here the project follows the standard pack workflow. Future sessions run `/pm-startup` (Claude Code CLI) or its equivalent. |
| Reference | `## What NOT to put in Git`, `## Reference documents` | Same as SETUP-NEW |
| Migration note | `## Upgrading to a future major version` | Same pointer as SETUP-NEW §Migration note |

### 10.3 Size and shape

Approximately 200-250 lines — shorter than SETUP-NEW because it lifts
less procedural content from the current QUICKSTART.md and leans on
the preview-and-confirm flow for most of the copy/merge work.

### 10.4 Key differences from SETUP-NEW

- Clean-working-tree and branch-creation prerequisite.
- Explicit walkthrough of the preview report (Step 2).
- Existing-docs pointer procedure (Step 9) — new content.
- Architecture assessment step (Step 10) — recognizes that the PM chat
  must reconcile pack rules with pre-existing architecture.
- Skill-gap follow-up (Step 11) — recognizes that existing projects
  are more likely to hit coverage gaps than greenfield projects.

---

## 11. Migration guide naming convention

### 11.1 Rule

- **Name:** `MIGRATION-vN-to-vM.md`, where `N` is the prior major
  version and `M` is the new major version. For v9 → v10, the file
  is `MIGRATION-v9-to-v10.md` (Step 6 §9.1, §9.5 already uses this
  name).
- **Location:** `supporting-docs/` — always. Migration guides are
  pack product documents, not maintenance records.
- **Creation:** Every major version ships with exactly one migration
  guide that covers the previous major. Patch versions do not ship
  migration guides; they ship release notes inside `CHANGELOG.md`.
- **Intermediate upgrades:** A project on vN-2 applies `MIGRATION-v{N-2}-to-v{N-1}.md`
  from the earlier pack checkout first, then `MIGRATION-v{N-1}-to-v{N}.md`
  from the current checkout. The pack does not ship direct N-2 → N
  migration guides.

### 11.2 Authoritative home for the convention

The convention is stated in three places for discoverability, with
exactly one of them being authoritative and the other two pointing
to it:

- **Authoritative.** `README.md` "Repository Layout" section gets a
  note under `supporting-docs/`:
  > Migration guides follow the naming convention `MIGRATION-vN-to-vM.md`.
  > They always live in `supporting-docs/` and ship with the major
  > version that introduces the destination pack version.
- **Reference.** QUICKSTART.md third router paragraph (§8.2) already
  states the naming rule: "Version-specific migration guides are
  always named `MIGRATION-vN-to-vM.md` and always land in `supporting-docs/`."
- **Reference.** SETUP-NEW.md and SETUP-EXISTING.md each end with a
  one-line note: "For future pack version upgrades, see
  `supporting-docs/MIGRATION-vN-to-vM.md` (convention documented in
  `README.md`)."

### 11.3 Why README.md is authoritative

README.md already hosts the repository layout — the structural
invariants of the pack repo. The migration-guide naming rule is a
structural invariant. Putting it in any of the setup docs would make
it feel path-specific; putting it in the README makes it a pack-wide
convention everyone discovers at the repository root.

### 11.4 Automatable migration option

Per V10-PREDESIGN CD-12: "A `MIGRATION-v9-to-v10.md` guide is required
with an automatable migration option using the same paste-ready prompt
pattern as MIGRATION-v8-to-v9.md."

The automatable option is supplied by `scripts/migrate-v9-to-v10.sh`
(Step 6 §8.1). The MIGRATION guide (Step 6 §9) walks through using
it. Future migrations follow the same pattern: one guide, one script,
same paste-ready prompt pattern.

---

## 12. V9 lessons applied

### 12.1 Lesson 1 — operation-placement rationale

Each operation involved in project initialization is explicitly placed
at one lifecycle stage with rationale. This prevents the v9.0 skills-
distribution class of defect (operation moved between bootstrap and
QUICKSTART, then reversed).

| Operation | Placement | Why this stage |
|---|---|---|
| Copy pack template files | `init-project.sh` — stages S1-S7 | Once per project. Pack artifacts are project-level, not per-machine |
| Distribute skills to three tool directories | `init-project.sh` — stage S4 | Once per project. Committed to git so teammates inherit via clone. Consistent with v9.3 decision (skills distributed at project creation, not per machine) |
| Apply `chmod +x` to scripts | `init-project.sh` — stage S5 | Once per project at creation time. `bootstrap.sh` documents that agents re-applying chmod is per-machine, but that is for clones of already-initialized projects, not for init |
| Detect AI config stop condition | `init-project.sh` — stage S0 | Only meaningful at init time — after init, AI config is always present |
| Detect source files / language markers | `init-project.sh` — stage S0 | Determines which conditional files to keep. Only run once, at init |
| Merge `.gitignore` | `init-project.sh` — stage S8 | Once per project at creation time |
| Language-specific dependency resolution (SPM, uv) | `bootstrap.sh` — per machine | Per-machine concern (installed CLI tools differ by developer) — consistent with v9 decision |
| Verify `buf` installed | `bootstrap.sh` — per machine | Per-machine concern |
| Fill `[PLACEHOLDER]` values in context files | PM chat — once per project | Requires project knowledge from kickoff conversation; cannot be done by a script |
| Read existing docs for project context | PM chat — once per project | Requires reasoning over the existing content |
| Log skill gaps to PACK-FEEDBACK.md | PM chat — once per project, after kickoff | PACK-FEEDBACK.md is PM chat-owned (per trinity file Document locations table); script-written entries would lack project context (§7.3) |
| Generate project-specific SETUP.md and AGENT_KICKOFF.md | PM chat — once per project, post-kickoff | Needs the kickoff conversation output |
| Run detection scan for custom agents / improperly-added files | PM chat — at pm-startup and phase gate (Step 5 §10.7) | Ongoing concern after init; script detects once, PM chat watches for drift |

Every operation has exactly one home. Nothing is split across two
stages. This is Lesson 1 discharged.

### 12.2 Lesson 2 — CLI-behavior assumptions grounded in Step 2 facts

init-project.sh does NOT rely on any tool-emitted hook or any
implicit CLI behavior at run time. It is a copy-and-confirm script
that exits before any CLI reads the newly-installed files.

The only CLI-adjacent assumption is the post-completion behavior — at
the first PM chat session after init, the three CLIs must pick up the
newly-installed agent and skill files. Grounded in Step 2:

| Claim | Step 2 source |
|---|---|
| Claude Code picks up `.claude/agents/*.md` and `.claude/skills/<name>/SKILL.md` at session start | Fact 2 §1 (live change detection within watched directories) and §2 (top-level new directory requires restart — not an issue here because init creates the top-level dirs before the first session) |
| Gemini CLI picks up `.gemini/agents/*.md` with YAML frontmatter and `.gemini/skills/<name>/SKILL.md` at session start | Fact 3 §1 (file format) and §5 (skills discovered at session start) |
| Codex picks up `.codex/agents/*.toml` at session start via auto-discovery; no `config.toml` per-agent registration required | Fact 1 §1 and Contradiction C-1 |
| Filename rules permit lowercase hyphenated names (e.g., `docs-researcher.md`) across all three tools | Fact 2 §5, Fact 3 §2, Fact 1 §3 (unverified for Codex; Step 5 §1 resolved via smoke test) |
| No script-level file-edit hook is assumed (no Codex `post_edit_command`) | Fact 6 / Contradiction C-3 |

All claims cited; no extrapolation.

Lesson 2 additionally applies to the CLI-documentation-verification
gates in SETUP-NEW and SETUP-EXISTING — those docs re-use the current
QUICKSTART prose for PM chat setup (Claude Code session commands,
Codex CLI `--agent` flag, Gemini CLI `@agent-name` syntax). Any of
those prose references must match Step 2 facts; Step 8 (touch-point
consolidation) includes this sweep.

---

## 13. Design Requirements addressed

Per V10-PREDESIGN Part 7.

### 13.1 Automated and manual workflows

- Automated: `init-project.sh` handles detection, preview, copy,
  merge, verification, and prompt generation in one run.
- Manual: the developer walks through the preview, confirms, fills
  context file `[PLACEHOLDER]`s after the script completes, and
  pastes the end-of-run prompt into the PM chat. Manual steps are
  each documented in SETUP-NEW and SETUP-EXISTING.
- Clear actor boundary: init-project.sh writes files; the developer
  confirms and fills placeholders; the PM chat handles everything
  after init (kickoff, architecture, skill gap logging).
- No ambiguity about which actor owns which file — Lesson 1 §12.1
  table is the contract.

### 13.2 Document access patterns

- QUICKSTART.md: **setup-time, one-time read**, and after v10 it is
  a router — the developer reads it once to pick a path, then never
  again. Sized for direct read on any surface (~30 lines).
- SETUP-NEW.md / SETUP-EXISTING.md: **setup-time, one-time read**,
  per path. Sized for direct read (~250-400 lines each).
- MIGRATION-vN-to-vM.md: **setup-time**, one-time read at upgrade.
  Sized for direct read (Step 6 §9).
- The router split matches the access pattern — the developer on the
  new-project path never reads SETUP-EXISTING.md; they read one of
  three short docs and act. This is the V9 Part 7 requirement
  discharged at the file-organization level.

### 13.3 PM Chat tool flexibility

The end-of-run kickoff prompt emitted by init-project.sh is a
plain-text string that works on all four PM chat surfaces:

| Surface | How the prompt is consumed |
|---|---|
| Claude Desktop app | Paste into a new chat in the Claude Project after the GitHub connector sync |
| Claude Code CLI | Paste after `/pm-startup` |
| Codex CLI | Paste as the first user message after `codex` starts |
| Gemini CLI | Paste as the first user message after `gemini` loads GEMINI.md |

The prompt body refers to `docs/pack/prompts/pm-chat.md` variant
`kickoff`; the PM chat looks up the variant per Step 4 §4.4 on
whichever surface it is running. No surface-specific prompt content
is required.

### 13.4 Inline verification at every stage with blast-radius-wider-than-change-set scope

Discharged by §6.

- Stage-local verification: §6.2 table, one row per stage.
- Blast-radius sweep: §6.3 table, grep across files beyond the
  immediate change set.
- Failure modes: §6.4 exit codes and diagnostic format.
- Rationale for inline vs. end-of-run: §6.5.

### 13.5 Seamless BD integration

- **With BD-045 (capabilities pattern).** BD-045 adds content to
  trinity files. init-project.sh copies those trinity files verbatim
  from the pack template. No init-specific content depends on BD-045.
- **With BD-046 / Step 4 (prompt reorg).** init-project.sh copies
  `docs/pack/prompts/` from the pack template as a unit. Verification
  at §6.2 S6 asserts the exact file list from Step 4 §2.3.
- **With BD-046 / Step 5 (custom agents).** init-project.sh never
  creates x-prefixed files (Step 5 §18.2). The project's initial
  state has the `## Custom agents` and `## Custom skills` sections
  in PLATFORM-SKILLS.md with their "No custom X defined for this
  project." placeholder rows per Step 5 §12. The detection scan for
  improperly-added files runs at first pm-startup, not in
  init-project.sh (Step 5 §18.2).
- **With Step 6 (migration).** init-project.sh refuses to run on
  a project with existing AI config; that case is the migration
  script's job. Shared detection library (§1.3) ensures the two
  scripts agree on what "AI config present" means.

### 13.6 Maintenance considerations

- **Single script home.** Both scripts in `scripts/` at the pack root,
  shared library in `scripts/lib/detect.sh`. One directory to audit
  for detection changes.
- **No hardcoded file lists.** init-project.sh enumerates the pack
  template at run time (§4.2). Adding a new pack agent doesn't require
  a script change.
- **Skill coverage table.** Lives in `scripts/lib/detect.sh` as a
  constant. Updated when a new language skill is added to the pack.
  Step 8 (touch-point) includes a verification task: when
  `project-template/skills/` adds a language-specific skill,
  `scripts/lib/detect.sh` coverage constant must be updated in the
  same commit.

### 13.7 Resource considerations

init-project.sh runs a handful of `find` / `ls` calls (detection),
a handful of `cp` / `mkdir` calls (copy), and a small number of grep
sweeps (verification). Runtime target: < 5 seconds on a typical
project. Token cost: zero — no LLM is invoked.

The preview report is ~60-80 lines; easily read on terminal. The
end-of-run PM chat prompt is ~30 lines; fits in a single paste.

### 13.8 Best use of RAG

Not applicable to init-project.sh itself. Affects SETUP-NEW and
SETUP-EXISTING only insofar as they describe the three PM chat
options, each of which has its own RAG vs. direct-read profile
(covered in Step 2 Fact 4 and Step 4 §7.3).

### 13.9 Rollback plan

init-project.sh does not have a rollback plan in the same sense as
the migration script (Step 6 §6). init-project is additive — it
adds files but does not overwrite existing content (skip list +
.gitignore merge + AI config stop condition). The developer is on
a branch (SETUP-EXISTING §Step 1); rollback is `git reset --hard`
+ `git checkout main` + `git branch -D pack-init`. Documented in
§6.4 failure-mode diagnostics.

### 13.10 Incremental testability

Each stage of init-project.sh leaves the project in a state where
the stage's output can be inspected, even though the project is
not yet complete. If S4 (skills) succeeds but S5 (scripts) fails,
the `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` are all
present and correct; the developer can decide whether to abandon
and retry or investigate the S5 failure. The per-stage sentinels
mirror Step 6 §7's migration design.

---

## 14. Handoffs

### 14.1 To Step 8 (touch-point consolidation)

New files introduced by this step:

- `scripts/init-project.sh` (new — pack repo top-level `scripts/`)
- `scripts/lib/detect.sh` (new — shared detection library)
- `supporting-docs/SETUP-NEW.md` (new)
- `supporting-docs/SETUP-EXISTING.md` (new)

Files modified by this step:

- `QUICKSTART.md` — rewritten as three-path router (§8.2)
- `README.md` — Repository Layout updated for new `scripts/lib/`
  directory, new `SETUP-NEW.md` and `SETUP-EXISTING.md` entries;
  migration-guide naming convention note added under
  `supporting-docs/` (§11.2)
- `supporting-docs/SETUP_TEMPLATE.md` — §4 (copy agent config files)
  rewritten to use `init-project.sh`; QUICKSTART-step-number
  references in §11 rewritten to reference SETUP-NEW.md by name

Stale references that must be swept:

- Any file referencing `QUICKSTART.md Step N` (where N is the current
  v9 step number) — update to reference SETUP-NEW.md by section name
  or SETUP-EXISTING.md by section name. Known candidates (grep sweep
  at Step 8):
  - `supporting-docs/SETUP_TEMPLATE.md` (explicit reference)
  - `supporting-docs/CLI-PM-SETUP.md` (likely)
  - Any `maintenance-docs/` doc that mentions the setup procedure
- Any file referencing `cp -r` as the setup command — update to
  `bash "$PACK/scripts/init-project.sh"`. Known candidates:
  - `supporting-docs/SETUP_TEMPLATE.md`
  - Possibly older `maintenance-docs/guides/` content (annotate per
    V9 Lesson 4 — historical records are annotated, not rewritten)

CI additions (`scripts/validate-pack.py`):

- Confirm `scripts/init-project.sh` exists, is executable, and sources
  `scripts/lib/detect.sh` (shell-script `source` line grep).
- Confirm `scripts/lib/detect.sh` exists and defines the functions
  listed in §1.3.
- Confirm QUICKSTART.md, SETUP-NEW.md, SETUP-EXISTING.md all exist.
- Confirm README.md Repository Layout section mentions `scripts/lib/`
  and the migration-guide naming convention.

### 14.2 To Step 9 (migration testing matrix)

Testing dimensions added by this step:

- **Project type for init-project.sh:** new-empty, new-bare,
  existing-bare (docs only), existing-source Swift-only, existing-source
  Python-only, existing-source Swift+Python monorepo, existing-source
  Kotlin (gap case).
- **Stop condition:** existing project with partial AI config
  (`.claude/` present, others absent) — verify the stop procedure
  (§2.6) runs and exits 20.
- **Preview-and-confirm:** confirm with `y`, with `n`, with EOF, with
  piped input.
- **Inline verification failure injection:** artificially remove a
  pack skill from `$PACK/project-template/skills/` between stages to
  verify S4 catches the missing skill.

### 14.3 To Step 10 (verification plan)

Verification items originating in this step:

1. **New-project dry run** (`new-empty`, `new-bare`) on a freshly
   `git init`-ed directory — script completes, all pack files
   present, end-of-run prompt printed.
2. **Existing-project dry run** (`existing-source`) on a real Swift
   project — preview lists existing files under SKIP; confirm;
   `.gitignore` merged correctly; existing files untouched; prompt
   includes existing-docs pointer.
3. **AI config stop condition** — existing project with `.claude/`
   pre-populated; verify exit 20.
4. **Skill gap reporting** — existing Kotlin project; verify
   Kotlin listed in "Pack skill coverage: NO COVERAGE" and the
   end-of-run prompt instructs PACK-FEEDBACK logging.
5. **Per-stage verification injection** — deliberately delete a pack
   agent between S1 and S2 (hard to do cleanly; may require mocking);
   verify exit 22.
6. **Blast-radius sweep** — doctor a pack template to reference a
   skill that doesn't exist; verify the sweep catches it; exit 31.
7. **.gitignore merge** — project with an existing `.gitignore`
   containing three pack-identical lines; verify those lines are
   not duplicated.
8. **Skip-list coverage** — project with a pre-existing
   `scripts/bootstrap.sh` (different content from pack's); verify
   the pack script is skipped and the collision is reported.
9. **QUICKSTART router readability** — render QUICKSTART.md to
   HTML / preview in GitHub; confirm the three links resolve and
   the content fits in one screen.
10. **SETUP-NEW / SETUP-EXISTING** — lint for broken cross-references
    (every internal link and external reference resolves).
11. **Migration-guide naming convention** — README Repository Layout
    section contains the convention note; QUICKSTART third paragraph
    restates it; SETUP-NEW and SETUP-EXISTING both point back to README.

### 14.4 To Phase 3 (implementation planning)

Phase 3 consumes this step's:

- §1 script architecture (two scripts + shared library)
- §2 detection heuristics (five-class classification)
- §3 preview report format
- §4 new-project stages
- §5 existing-project stages + `.gitignore` merge + skip list + transition
- §6 per-stage verification contracts
- §8 QUICKSTART.md full content
- §9, §10 SETUP-NEW/SETUP-EXISTING outlines
- §11 migration naming convention

as input to produce per-file edit sequences and the commit plan for
BD-044.

---

## 15. Summary

- **OQ-5 resolved.** Two scripts, one shared detection library. Init
  and migration are separate binaries with separate scopes;
  `scripts/lib/detect.sh` is the shared code (§1).
- **OQ-12 resolved.** Five project classes (`new-empty`, `new-bare`,
  `existing-bare`, `existing-source`, `already-configured`) determined
  by language markers (depth ≤ 2), source-extension files (threshold
  ≥ 3, depth ≤ 2), AI config markers, README handling, and monorepo
  handling — all rules specified (§2).
- **Preview-and-confirm flow.** Read-only detection, structured report
  with five named sections (classification, language markers, source,
  AI config, skill coverage, existing docs, planned operations,
  developer transition notice), explicit `y/N` confirmation default
  No (§3).
- **New-project path.** 10 stages, enumerated source of truth from the
  pack template at run time, conditional removal based on detected
  languages (§4).
- **Existing-project path.** Same 10 stages, with explicit skip list,
  `.gitignore` append-and-dedupe merge, developer transition notice,
  end-of-run PM chat prompt containing existing-docs pointer and
  skill-gap instructions (§5).
- **Inline verification at every stage.** Per-stage local checks
  (§6.2), blast-radius sweep wider than the change set (§6.3),
  explicit exit codes and failure diagnostics (§6.4). Mirrors Step 6
  migration's reference pattern.
- **Skill gap tracking.** init-project.sh detects; the PM chat logs
  to `docs/pack/PACK-FEEDBACK.md` per the end-of-run prompt (§7).
- **QUICKSTART.md three-path router.** ~30-line routing doc; all
  procedural content moves to SETUP-NEW.md or SETUP-EXISTING.md (§8).
- **SETUP-NEW.md / SETUP-EXISTING.md.** Section lists defined;
  content sources mapped to current QUICKSTART and SETUP_TEMPLATE
  sections plus new content for preview walk-through and existing-docs
  pointer (§9, §10).
- **Migration guide naming convention.** `MIGRATION-vN-to-vM.md` in
  `supporting-docs/`; authoritative in README Repository Layout,
  referenced from QUICKSTART and both setup docs (§11).
- **V9 Lesson 1.** Every operation has one placement, justified (§12.1).
- **V9 Lesson 2.** All CLI-adjacent assumptions cite Step 2 facts; no
  hook or post-edit-command assumptions (§12.2).
- **Design Requirements.** All nine items from V10-PREDESIGN Part 7
  addressed; explicit crosswalk in §13.
- **Handoffs.** New files, modified files, and CI additions listed
  for Step 8; test combinations for Step 9; verification items for
  Step 10; consumption for Phase 3 (§14).
- **No new open questions opened.** All resolutions concrete and ready
  for Phase 3 implementation planning.

---

*End of step-07-init-project.md.*
