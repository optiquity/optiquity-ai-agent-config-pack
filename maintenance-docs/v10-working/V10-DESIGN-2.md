# V10-DESIGN-2.md — Addendum: Capability Addition for Existing Projects

## Part 0 — Status

- **Document status:** DRAFT (addendum to V10-DESIGN.md; not yet approved).
- **Relationship to V10-DESIGN.md:** Additive. No AD in V10-DESIGN.md Part 2
  is revised. New decisions are numbered AD-A1..AD-A5 to avoid collision
  with the approved AD-1..AD-13 set.
- **Scope:** Within the existing BD-046 envelope. No new BD-NNN is proposed.
- **Target version:** v10.0 (same ship target as V10-DESIGN.md per AD-12).
- **Authoritative v10 reference:** V10-DESIGN.md remains the base design.
  This document extends it; where they overlap, V10-DESIGN.md wins and a
  cross-reference here names the section reused verbatim.

### How to read this document

If you have read V10-DESIGN.md, skim Part 1 for the problem, then read
Part 2 (decisions), Part 3 (workflow), and Part 4 (blast radius). Parts 5
and 6 are alternatives-rejected and implementation-plan impact.

If you have NOT read V10-DESIGN.md, read its Part 1 (why v10 exists),
Part 7 (init-project.sh), and Part 6 (migration) first — this addendum
reuses the `scripts/lib/detect.sh` shared library (V10-DESIGN §7.2), the
script-plus-PM-chat-procedure pattern (§6.5, §7.8), and the conditional
file table (§7.6 S9).

---

## Part 1 — Problem

### The capability-addition gap

A project is installed with the pack via `init-project.sh` for one set of
PLATFORM-SKILLS.md dimensions — say, macOS + Swift. All 30 pack skills
were distributed to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
at init time (V10-DESIGN §7.6 stage S4). But the project was pruned for
its actual profile:

- The **Active skills** line in the trinity files names only Swift/macOS
  skills (CLAUDE.md line 218, AGENTS.md line 140, GEMINI.md line 172).
- The trinity **[PLACEHOLDER]** sections (`PLATFORM_DEFAULTS`,
  `PLATFORM_ARCHITECTURE`, `LANGUAGE_RULES`, `GRPC_RULES`,
  `PLATFORM_SECURITY`, `PLATFORM_TESTING`, `PLATFORM_ANTIPATTERNS`) were
  filled with content derived from the macOS + Swift skills only.
- Conditional project files for other dimensions (`pyproject.toml`,
  `pyrightconfig.json`, `server/`, `bootstrap-python.sh`,
  `validate-python.sh`, `proto/`, `proto-gen.sh`, etc.) were removed at
  init stage S9 per V10-DESIGN §7.6.

Later, the developer needs to add a capability the pack already supports
— Python, iOS alongside macOS, gRPC, a new Component Role. None of this
is custom: the skills exist on disk, the scripts and stubs exist in the
pack, and the placeholder templates exist in the trinity files.

### What currently goes wrong

Under V10-DESIGN.md as written today, the developer has three options, all
bad:

1. Manually edit the Active skills line, manually grep each SKILL.md for
   content to paste into placeholders, manually `cp` conditional files
   from the pack, and hope nothing is missed. No procedure exists.
2. Run `init-project.sh` again — but §7.4 says it STOPS on any existing
   AI config (exit 20).
3. Delete the project's AI config, re-run `init-project.sh`, and lose
   every customization and `x-` file. Unacceptable.

### What this applies to

All four PLATFORM-SKILLS.md dimensions equally:

| Dimension | Example addition |
|---|---|
| Platform Targets | Adding iOS to a macOS-only project |
| Languages | Adding Python to a Swift-only project |
| Component Roles | Adding a Python server to an Apple client monorepo |
| Communication Protocols | Adding gRPC to a REST-only project |

The mechanism must be dimension-uniform: one flag set, one workflow.

### Constraints the mechanism must satisfy

1. **Automated.** Not a list of manual steps.
2. **Zero-token dormancy.** No cost during normal project work; the
   mechanism only consumes tokens when invoked.
3. **Small blast radius on V10-DESIGN.md.** Reuse existing decisions;
   minimize new files and new procedures.
4. **Four PM chat surfaces.** Must work on Claude Code CLI, Claude
   Desktop, Codex CLI, and Gemini CLI.
5. **Four-dimension parity.** Same mechanism for Platform Targets,
   Languages, Component Roles, and Communication Protocols.
6. **Within BD-046 scope.** No new BD-NNN. This is in-scope for v10.0.
7. **x-file and customization preservation.** Must never modify
   `x-` files or project-owned regions of PLATFORM-SKILLS.md / trinity
   files.

---

## Part 2 — Approved Decisions (proposed)

### AD-A1 — Two-part mechanism: shell helper + PM chat procedure

The capability-addition mechanism is split across two lifecycle stages,
mirroring the init-project.sh-plus-kickoff pattern (V10-DESIGN Part 7
§7.8) and the migrate-v9-to-v10.sh-plus-Procedure-5-R pattern
(V10-DESIGN Part 6 §6.5).

| Stage | Owner | Responsibility |
|---|---|---|
| File plumbing | `scripts/add-capability.sh` (new pack script) | Read `$PACK`; copy conditional project files for the new dimension; update `.gitignore` if needed; emit an end-of-run PM chat prompt |
| Markdown edits | PM chat, new Procedure 6 | Update Active skills line; fill [PLACEHOLDER] sections from the newly-active skills' SKILL.md content; add PLATFORM-SKILLS.md dimension rows if the dimension gains a row; commit |

**Why split.** The file-copy step needs `$PACK` access and cross-tool-
identical semantics that only a shell script delivers (Desktop + MCP
filesystem cannot guarantee file-copy parity with native CLIs — V10-DESIGN
§7.1 uses the same reasoning for placing migration and init as separate
pack-repo scripts with a shared detection library). The markdown step
needs per-project interpretive judgment (which skill content applies to
which placeholder, how to word active-skills deltas) that the PM chat
owns.

**Why not one shell script doing everything.** It would need to splice
markdown the way `merge-trinity.py` and `merge-platform-skills.py` do for
migration — and then it would need a separate PM chat pass anyway to
verify intent. The split puts each owner on its strong ground.

**Why not "PM chat only, no shell."** PM chat on Claude Desktop without
filesystem MCP cannot write files; on Codex CLI without explicit `$PACK`
mount it cannot read the pack; on ChatGPT Web it cannot run scripts.
Shell guarantees the file-copy step works uniformly on all four
surfaces. After the shell step, every PM chat surface can do the
markdown step because the skills are already on disk in the project and
SKILL.md bodies are readable without `$PACK`.

### AD-A2 — `scripts/add-capability.sh` lives in the pack repo, not in projects

Same placement as `init-project.sh` and `migrate-v9-to-v10.sh`
(V10-DESIGN §7.1, §6.10). The three scripts are the pack-operational
triad: they run against a project but do not ship into it.

```
scripts/
├── init-project.sh              (V10-DESIGN §7.1)
├── migrate-v9-to-v10.sh         (V10-DESIGN §6.10)
├── add-capability.sh            (NEW — this addendum)
├── merge-platform-skills.py     (V10-DESIGN §6.10)
├── merge-trinity.py             (V10-DESIGN §6.10)
├── validate-pack.py             (existing)
└── lib/
    └── detect.sh                (V10-DESIGN §7.2 — shared)
```

README.md Repository Layout gains one line for `add-capability.sh`
under `scripts/`. No other layout changes.

### AD-A3 — METHODOLOGY.md Procedure 6: "Adding a pack-supported capability"

Procedure 6 is appended to METHODOLOGY.md Part 7 immediately after
Procedure 5 and Procedure 5-R (V10-DESIGN §5.7, §6.5). Procedure 5
handles custom additions (`x-` files); Procedure 5-R handles v9.3-to-v10
reconciliation; Procedure 6 handles pack-supported-capability additions
to an existing v10 project.

Three procedures, three distinct triggers, one consistent pattern (PM
chat runs a detection step, presents drafts through named approval
gates, commits at the end). No overlap with Procedures 1–5.

### AD-A4 — Dimension-uniform invocation with atomic-token grammar

The developer names the dimension and value:

```bash
bash $PACK/scripts/add-capability.sh --project . \
    --add language:python
bash $PACK/scripts/add-capability.sh --project . \
    --add platform:ios
bash $PACK/scripts/add-capability.sh --project . \
    --add protocol:grpc
bash $PACK/scripts/add-capability.sh --project . \
    --add role:python-server
```

Multiple `--add` flags in one invocation are supported. The script
resolves each against the PLATFORM-SKILLS.md dimension tables and derives
the skill delta and conditional-file delta deterministically.

**Token grammar (decision; was Open Q 4 in an earlier draft).** Valid
`dimension` tokens: `platform`, `language`, `protocol`, `role`
(corresponding one-to-one with PLATFORM-SKILLS.md §§ Step 1 Dimensions
1–4). Valid `value` tokens are **atomic, lowercase-hyphenated**
normalizations of the row labels in those tables. This rule applies
uniformly to all four dimensions — not just `platform:` — because
Dimensions 1 and 3 both use multi-word row labels (e.g., "iOS + macOS
(universal)", "Python server", "Shared native library"):

- `platform:ios`, `platform:macos` (atomic; unions emerge from running
  the flag twice).
- `language:swift`, `language:python`, `language:c`, `language:cpp`,
  `language:objc`.
- `protocol:grpc`, `protocol:rest`.
- `role:python-server`, `role:embedded-python`,
  `role:shared-native-library`.

Anything unrecognized exits non-zero with a "proposed dimension not in
PLATFORM-SKILLS.md — consider PACK-FEEDBACK.md" diagnostic.

### AD-A5 — BD-046 scope; no new BACKLOG item

BD-046's v10 scope is established across V10-DESIGN.md AD-12 (combined
scope for v10.0) and Parts 4, 5, 6 (prompt reorg, custom agents/skills,
migration). Capability addition shares the same files as all three
established BD-046 sub-areas and fits the same lifecycle. It is folded
into BD-046 in the BACKLOG entry as a fourth bullet ("adding
pack-supported capabilities to existing projects"). No new BD-NNN is
proposed and no existing AD is modified — the scope extension is carried
by the BACKLOG.md edit in §5.3 below and by AD-12's combined-scope
framing.

---

## Part 3 — Mechanism Workflow

### 3.1 Trigger

The developer triggers the workflow from a terminal in the project
directory:

```bash
# Canonical form
PACK="/path/to/dhs-ai-agent-config-pack"
bash "$PACK/scripts/add-capability.sh" --project . \
    --add language:python \
    --add protocol:grpc
```

`$PACK` is the same environment variable used by
`migrate-v9-to-v10.sh` (V10-DESIGN §6.9 paste-ready prompt). No new
convention.

On Claude Desktop, the shell step runs via filesystem MCP or in a
separate terminal; the developer then pastes the end-of-run prompt
(§3.4) into the Desktop session. This mirrors V10-DESIGN §6.9's
treatment for `migrate-v9-to-v10.sh` and preserves the four-surface
parity constraint (Part 1 constraint 4).

The script detects `$PACK` from:

1. `--pack <path>` flag if provided.
2. `$PACK` environment variable.
3. The script's own location (`$(dirname $(dirname "$0"))`) — works when
   invoked by absolute path from the pack repo.

### 3.2 Script behavior (add-capability.sh stages)

The script reuses V10-DESIGN §7.2 `scripts/lib/detect.sh` and the
conditional file table from V10-DESIGN §7.6 stage S9 (inverted —
conditional-add rather than conditional-remove).

| Stage | Action | Post-stage assertion |
|---|---|---|
| **A0** | Pre-flight: working tree clean; target is a git repo; project has AI config (inverse of init-project.sh §7.4 stop); `$PACK` valid; pack-version compatibility check (see note below) | Working-tree clean, pack resolvable |
| **A1** | Resolve `--add` arguments against `$PACK/project-template/docs/pack/PLATFORM-SKILLS.md` dimension tables; compute skill delta and conditional-file delta | Dimension + value recognized; combined (skill-delta ∪ conditional-file-delta) is non-empty — see degenerate-case note below |
| **A2** | Read existing Active skills line from `CLAUDE.md` (trinity-equivalent to `AGENTS.md` / `GEMINI.md` per V10-DESIGN §6.6); compute union with skill delta; report what will be added vs. what is already active | Union computed; no silent overwrites; already-active short-circuit per note below |
| **A3** | Detection report + preview (§7.5 format adapted): planned file adds, planned skill additions, planned placeholder sections the PM chat will need to fill | Report printed; no writes yet |
| **A4** | Confirmation prompt `Proceed? [y/N]`. Default **No**. SIGINT / EOF / non-`y` exits 0 with no changes | Explicit consent required |
| **A5** | Copy conditional files per V10-DESIGN §7.6 conditional-removal table, inverted: if language/proto/platform is being added, copy the corresponding files from `$PACK/project-template/` | Files present; executable bits set (`chmod +x`); assertion matches per-file byte count |
| **A6** | `.gitignore` merge: re-run the full pack `.gitignore` merge using the init-project.sh S8 logic (append-missing under the pack header comment; dedupe). Idempotent — entries already present are skipped | `.gitignore` contains all pack entries; duplicates reported |
| **A7** | Write end-of-run PM chat prompt to stdout AND to `.pack-add-capability-prompt.md` in the project root (the file is gitignored by A6's merge; it is ephemeral and may be deleted after Procedure 6 completes) | Prompt present on both stdout and the ephemeral file |

**A0 pack-version compatibility — warning, not hard stop.** The trinity
files carry a banner comment of the form
`*Copied from: project-template/CLAUDE.md — AI Agent Config Pack vN*`.
This is a human-readable comment, not a formally-defined machine-readable
frontmatter field. A0 reads the banner best-effort. If the banner's
version string does not match `$PACK`'s current version, the script
prints a warning (`WARNING: project installed from pack vN; $PACK is
vM — proceed only if you understand the compatibility impact`) but does
not abort. Formalizing the banner to a fenced frontmatter block with a
`pack-version:` key is deferred to a future minor-version iteration; the
warning preserves operability in the meantime.

**A1 degenerate-case exit.** If the combined (skill-delta ∪
conditional-file-delta) is empty after resolving `--add` arguments — for
example `--add role:shared-native-library` when PLATFORM-SKILLS.md
Dimension 3 declares that row adds no distinct skills or files — A1
exits 0 with the message "nothing to add — this dimension/value is
already covered by existing active skills and files." This is a success
outcome, not an error.

**A2 already-active exit.** If every `--add` argument resolves to a
dimension/value whose skills are already in the Active skills line AND
whose conditional files are already present on disk, A2 exits 0 with
"all requested capabilities already active; no changes needed." The
end-of-run prompt is still written (§3.4) for auditing, but it reports
zero deltas.

No markdown splicing. No `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` writes (skills are already on disk from init). No
trinity edits. No PLATFORM-SKILLS.md edits. The script's scope is
strictly file-system plumbing for the pack-sourced conditional files.

### 3.3 PM chat Procedure 6 behavior

Procedure 6 sits in METHODOLOGY.md Part 7 after Procedure 5-R.

Triggered when:

- The developer pastes the prompt emitted by `add-capability.sh` stage
  A7, or
- The developer asks the PM chat to "add Python" / "add iOS" / etc. and
  the PM chat first instructs them to run `add-capability.sh` before
  resuming.

| Step | Action | Approval gate |
|---|---|---|
| **6.1** | Read `add-capability.sh` report — either pasted into the session or read from `.pack-add-capability-prompt.md` at the project root (written by A7); verify stages A0–A7 completed | — |
| **6.2** | Read the newly-activated SKILL.md files from `.claude/skills/<name>/SKILL.md` (skills are already on disk); extract the content relevant to each trinity placeholder | — |
| **6.3** | Draft updates to the trinity files: update **Active skills** line; fill `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]` placeholders as applicable for the newly-added dimension. Present drafts side-by-side for all three trinity files (TRIO) | **G6-drafts** — developer confirms trinity drafts |
| **6.4** | If the project now qualifies for a PLATFORM-SKILLS.md dimension row that was not previously selected (e.g., project gains iOS row after adding iOS to a macOS-only selection), surface the dimension row for explicit acknowledgement. This is informational — PLATFORM-SKILLS.md rows describe the pack's matrix, not the project's selection, so typically no edit is needed | — |
| **6.5** | Run the Procedure 5.5 detection scan once the drafts are applied — verify no `x-` files were touched; verify PLATFORM-SKILLS.md `## Custom agents` / `## Custom skills` project-owned regions are unchanged | — |
| **6.6** | Present `git add` list and commit message (`feat: project — add <dimension>:<value> capability`); developer approves per CLAUDE.md pack rule (same gate as Procedure 5 G-commit) | **G6-commit** |

The trinity edits are always TRIO (V10-DESIGN Appendix B "Trinity rule",
Part 8 §8.5 trinity-rule integrity audit): the same content is spliced
into CLAUDE.md, AGENTS.md, GEMINI.md in one commit.

### 3.4 End-of-run PM chat prompt (script output)

Stage A7 writes this prompt both to stdout and to
`.pack-add-capability-prompt.md` in the project root. The file is
gitignored (A6's merge adds the pattern if it is not already present)
and is ephemeral — the developer may delete it after Procedure 6
commits.

```
You are the PM chat for [PROJECT_NAME at <absolute path>].

scripts/add-capability.sh has just run and added the following
pack-supported capabilities to this project:

  --add language:python
  --add protocol:grpc

Files copied:
  - pyproject.toml
  - pyrightconfig.json
  - server/
  - scripts/bootstrap-python.sh, format-python.sh, validate-python.sh,
    test-python.sh
  - scripts/proto-gen.sh, validate-proto.sh
  - proto/

.gitignore entries added: 4 new, 2 duplicates.

Active skills currently in CLAUDE.md:
  swift-best-practices, apple-architecture-core, macos-architecture

Active skills after your Procedure 6 run should be:
  swift-best-practices, apple-architecture-core, macos-architecture,
  python-best-practices, python-architecture, grpc-patterns

Please run METHODOLOGY.md Procedure 6 (Adding a pack-supported
capability). Present your trinity-file drafts for approval at G6-drafts
before writing, and the commit message at G6-commit before committing.

Do NOT modify any file starting with x-.
Do NOT modify PLATFORM-SKILLS.md project-owned sections
(`## Custom agents`, `## Custom skills`).
```

### 3.5 Artifacts created or modified

| Artifact | Actor | Created / modified |
|---|---|---|
| `pyproject.toml`, `pyrightconfig.json`, `server/`, Python / proto scripts, `proto/` | `add-capability.sh` | Created (copied from `$PACK`) |
| `.gitignore` | `add-capability.sh` | Modified (full pack-merge append-and-dedupe) |
| `.pack-add-capability-prompt.md` | `add-capability.sh` | Created (ephemeral; gitignored; developer may delete after Procedure 6) |
| `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | PM chat (Procedure 6) | **Active skills** line + placeholder sections updated; TRIO |
| `PLATFORM-SKILLS.md` | PM chat (Procedure 6) | Usually untouched. Modified only if the dimension row did not exist for this project before (rare) |
| `docs/pack/PACK-FEEDBACK.md` | PM chat (Procedure 6) | Untouched by Procedure 6 itself. Appended only if the developer reports that the newly-added capability exposed a gap in the pack |

Files **never** touched: any `x-` agent / skill / prompt file; any SKILL.md
(already on disk); BACKLOG.md; STATUS.md; ARCHITECTURE.md;
IMPLEMENTATION_PLAN.md; CHANGELOG.md.

### 3.6 Approval gates (summary)

- **A4** — Script pre-write confirmation (script stage).
- **G6-drafts** — Trinity drafts reviewed before any markdown write.
- **G6-commit** — `git add` list + commit message before commit.

Aborting at any gate leaves the project in the pre-gate state (pre-A4:
no changes; pre-G6-drafts: files copied but no markdown edits —
rollback = `git checkout -- .` plus remove the added files the script
reports in stage A5; pre-G6-commit: working tree edits revertable with
`git restore`). No half-committed states.

---

## Part 4 — Blast Radius on V10-DESIGN.md

### 4.1 Sections affected

| V10-DESIGN section | Change | Rationale |
|---|---|---|
| Part 2 AD-12 (v10.0 combined scope) | Text note: AD-12's combined-scope list covers capability-addition as a fourth BD-046 sub-area alongside custom agents, prompt reorg, and migration | Confirms scope without changing acceptance; preferred over annotating AD-11 (which is about BD-045) |
| Part 5 §5.7 Procedure 5 outline | No change to Procedure 5. Procedure 6 is a new sibling; Procedure 5's sub-procedures 5.1–5.6 are untouched | — |
| Part 6 §6.5 Procedure 5-R | No change. Procedure 5-R stays one-shot (v9.3 → v10 reconciliation); Procedure 6 is repeatable (every capability addition) | — |
| Part 7 §7.2 `scripts/lib/detect.sh` | Extend with `detect_installed_capabilities()` helper that reads the Active skills line and reports which dimension values are currently active | Shared-library pattern already established |
| Part 7 §7.6 stage S9 conditional-removal table | No change. `add-capability.sh` inverts the same table; single source of truth | — |
| Part 7 §7.13 Integration with other BDs | Append one bullet: "BD-046 add-capability.sh — runs post-init against already-initialized projects; sources `scripts/lib/detect.sh`; inverts the §7.6 S9 conditional-file table; never creates `x-` files." | Keeps the integration inventory complete |
| Part 8 §8.2 Touch Point Inventory | New BD-046 rows (see §4.3 below) | Mechanical append |
| Part 10 §10.x Verification plan | New V-ADDCAP-* suite (see §6.2 below) | Mechanical append |
| Part 12 §12.1 Implementation Sequence | New commits appended to Phase 3 (see §5 below) | Minor sequence growth |
| Appendix B Glossary | New entry: "Procedure 6 — METHODOLOGY.md Part 7 procedure for adding a pack-supported capability (platform, language, protocol, or role) to an existing project; paired with `scripts/add-capability.sh`. See V10-DESIGN-2 §3.3." | Matches existing glossary entries for Procedure 5 and Procedure 5-R |

### 4.2 Sections unchanged

All other V10-DESIGN.md sections: Parts 1, 3, 4, 5 (except §5.7 already
confirmed unchanged), 6 (except §6.5 confirmed unchanged), 7.1, 7.3,
7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11, 7.12 (§7.13 is the only Part 7
addition — see §4.1 row), 9, 11.

No AD is revised. No approved decision is reopened.

### 4.3 New files and file additions (touch-point deltas)

Appended to V10-DESIGN Part 8 §8.2 as new rows in §8.2.4 (migration) or a
new §8.2.8:

| # | File | Change | BD | Actor | Source |
|---|---|---|---|---|---|
| (new) | `scripts/add-capability.sh` | New pack-operational script; stages A0–A7 per §3.2 above | BD-046 | pack chat | V10-DESIGN-2 §3.2 |
| (new) | `scripts/lib/detect.sh` | Add `detect_installed_capabilities()` function | BD-046 | pack chat | V10-DESIGN-2 §4.1 |
| (new) | `supporting-docs/METHODOLOGY.md` | Add Procedure 6 (Adding a pack-supported capability) after Procedure 5-R. **Combine with rows 43 and 48.** | BD-046 | pack chat | V10-DESIGN-2 §3.3 |
| (new) | `project-template/docs/pack/PM-CHAT.md` | Add one-line trigger rule under `## Behavioral rules`: "If the developer asks to add a pack-supported dimension (platform, language, protocol, role), direct them to run `scripts/add-capability.sh` from the pack first; then run METHODOLOGY.md Procedure 6." **Combine with row 38.** | BD-046 | pack chat | V10-DESIGN-2 §3.3 |
| (new) | `supporting-docs/MIGRATION-v9-to-v10.md` | No change — capability addition is post-migration | — | — | — |
| (new) | `README.md` (top-level) | Add `scripts/add-capability.sh` to Repository Layout. **Combine with rows 55 and 65.** | BD-044, BD-046 | pack chat | V10-DESIGN-2 §4.3 |
| (new) | `scripts/validate-pack.py` | No new check required. Existing structural checks are sufficient; add-capability.sh is self-validating via stage post-assertions | — | — | — |

No new file is added to `project-template/` (the template itself is
unaffected — the mechanism runs against a downstream project after
install).

### 4.4 Zero-token-dormancy argument

During normal project work:

- `add-capability.sh` is a file on disk in the pack repo, not read by
  any PM chat or agent until the developer executes it.
- Procedure 6 sits inside METHODOLOGY.md. METHODOLOGY.md is consumed
  on-demand rather than at every session startup on most surfaces
  (Claude Code CLI uses mcp-local-rag per-query retrieval; Claude
  Desktop + filesystem MCP reads on demand; Codex CLI / Gemini CLI read
  on demand). The net cost of adding ~one procedure's worth of content
  to METHODOLOGY.md is paid only when Procedure 6 is actually invoked.
- The one-line trigger rule in PM-CHAT.md Behavioral rules is ~15 tokens
  at pm-startup (PM-CHAT.md is read at startup on most surfaces).
  De minimis.

The mechanism consumes tokens only when the developer invokes it: script
run costs zero tokens (it is shell); Procedure 6 run costs the tokens of
reading Procedure 6 itself plus the delta content it produces. Both are
tied to the developer's explicit action.

---

## Part 5 — Implementation Plan Impact

### 5.1 New commits (proposed insertion points)

Per the current `maintenance-docs/v10-working/phase-3-implementation-plan.md`
Phase structure (Gate A–F), capability addition lands in **Phase 3**
(BD-044 + finalization) alongside init-project.sh, since it shares
`scripts/lib/detect.sh` and the conditional-file table.

Three new commits append to Phase 3 after C-044-08 and before Gate E:

| Commit | Message | Files | Depends on |
|---|---|---|---|
| **C-046-ADD-01** | `feat: v10 — BD-046 add-capability.sh + detect.sh extension` | `scripts/add-capability.sh`, `scripts/lib/detect.sh` (extension) | C-044/046-01 (detect.sh must exist), C-044-02 (init-project.sh's conditional table is the source of truth), C-046-15 (migrate script shares detect.sh) |
| **C-046-ADD-02** | `feat: v10 — BD-046 Procedure 6 for capability addition` | `supporting-docs/METHODOLOGY.md` (Procedure 6 section), `project-template/docs/pack/PM-CHAT.md` (trigger rule line) | C-046-04 (PM-CHAT.md pack roster pass), C-046-08 (METHODOLOGY.md Procedure 5 pass) |
| **C-046-ADD-03** | `docs: v10 — BD-046 README.md layout entry for add-capability.sh` | `README.md` Repository Layout | C-044-06 (README layout baseline) |

**Commit-ID note.** The commit identifiers in the table above
(`C-046-ADD-01..03`) and in the "Depends on" column (`C-044-08`,
`C-044/046-01`, `C-044-02`, `C-046-15`, `C-046-04`, `C-046-08`,
`C-044-06`) are **placeholders referenced from the working Phase 3
implementation plan** (`maintenance-docs/v10-working/phase-3-
implementation-plan.md`). That plan is a working artifact outside the
approved design boundary and its commit IDs may be renumbered when
Phase 3 is frozen. The **dependency relationships** expressed here (not
the literal IDs) are the authority: the add-capability script depends
on whatever commit lands `scripts/lib/detect.sh`; Procedure 6 depends on
whatever commit lands the Procedure 5 pass; and so on.

Total: 3 new commits. No existing commit from phase-3-implementation-plan.md
is modified.

Optional alternative placement: fold C-046-ADD-01 into Phase 2c alongside
migration tooling (C-046-15) since both scripts share detect.sh. If
taken, the extension to `scripts/lib/detect.sh` lands with C-044/046-01
and the script itself lands in Phase 3. Either ordering respects
dependencies; the Phase 3 grouping keeps capability-addition commits
together.

### 5.2 No changes to existing Phase 1–Phase 2c commits

C-045-01 through C-046-16 remain as currently planned. Capability
addition does not modify BD-045 content (trinity capabilities pattern),
does not modify BD-046 prompt reorganization, does not modify BD-046
custom-agent registration surfaces, and does not modify BD-046 migration
tooling.

### 5.3 BACKLOG.md

BD-046 description line updated from three bullets to four:

> v10 addresses **four** problems in one major version. [1–3 unchanged.]
> **Fourth: no supported path exists for adding pack-supported
> capabilities (new language, new platform, new protocol, new role) to a
> project already installed with the pack. Solution summary continues:**
> `scripts/add-capability.sh` for the file plumbing and METHODOLOGY.md
> Procedure 6 for the PM-chat-driven markdown edits.

No new BD-NNN is opened.

### 5.4 CHANGELOG.md

One bullet appended to the v10.0 entry at ship time:

> `scripts/add-capability.sh` and METHODOLOGY.md Procedure 6: add
> pack-supported capabilities (platform, language, protocol, role) to
> existing v10 projects without re-initialization.

---

## Part 6 — Alternatives Rejected and Verification

### 6.1 Alternatives rejected

**A — Extend `init-project.sh` with an `--add` mode.** Rejected.
init-project.sh §7.4 stop condition on existing AI config is a load-
bearing invariant of BD-044. Inverting it for a flag introduces a long
conditional branch with divergent pre-flight semantics — the exact trap
V10-DESIGN §7.1 cites as the reason to split init and migrate into two
scripts. Separate script, shared library is the established pattern.

**B — Make it entirely a PM chat procedure with no shell script.**
Rejected. Claude Desktop without filesystem MCP and ChatGPT Web without
Codex CLI cannot execute file copies from `$PACK` into the project.
Cross-surface parity (V10-DESIGN Part 0 repeatedly emphasized) requires
a shell layer. Even when the PM chat has filesystem access, delegating
the mechanical copy-and-chmod to a script is cheaper in tokens and
easier to verify.

**C — Emit a manifest file the PM chat writes by hand.** Rejected.
Manifest-driven workflows are the second-source-of-truth trap V9 Lesson
1 names explicitly. The conditional-file table lives in V10-DESIGN §7.6
and the script reads it at run time.

**D — Use the migration script for "minor" migrations.** Rejected.
Migration is a one-shot v9.3 → v10.0 operation with baseline invariants;
capability addition is a repeatable v10.x operation. Collapsing them
would require migrate-v9-to-v10.sh to be renamed and restructured,
breaking the V10-DESIGN Part 6 design that assumes one-shot semantics.

**E — New BACKLOG item BD-047 for v10.1.** Rejected per user constraint
("fits into the existing BD-046 scope"). The mechanism touches the same
files BD-046 already touches (trinity placeholders, METHODOLOGY.md,
PM-CHAT.md, `scripts/lib/detect.sh`); batching is cheaper than a
follow-up version.

**F — Populate Active skills line with the full 30-skill union at init
time, eliminating the "dormant skills" problem.** Rejected. V9.1 BD-038
established Active skills as the authoritative "what this project
currently uses" line, consumed by the PM chat at every phase gate. A
30-skill Active line defeats that mechanism's purpose and inflates
every agent prompt. The on-disk skills are dormant by design; activating
them is the lifecycle event this addendum addresses.

### 6.2 Verification plan additions

Appended to V10-DESIGN Part 10 as new V-ADDCAP-* suite:

| Test | Scope |
|---|---|
| **V-ADDCAP-01** | `add-capability.sh --add language:python` on a Swift-only project copies `pyproject.toml`, `server/`, Python scripts; `.gitignore` gains Python entries; `x-` files untouched |
| **V-ADDCAP-02** | `--add platform:ios` on a macOS-only project copies no files (platform add is skill-only) but reports the skill delta and prompts PM chat Procedure 6 — A1's combined-delta rule accepts skill-only additions |
| **V-ADDCAP-03** | `--add protocol:grpc` copies `proto/`, `proto-gen.sh`, `validate-proto.sh`; gRPC skill delta reported |
| **V-ADDCAP-03b** | `--add role:python-server` on an Apple-client monorepo that does not already have Python active: Dimension 3 coverage — asserts the script resolves the role to its skill + file delta (per PLATFORM-SKILLS.md Dimension 3), copies the role-specific conditional files, and reports the skill additions |
| **V-ADDCAP-04** | Running with no `--add` arguments exits non-zero with usage message |
| **V-ADDCAP-05** | Running with an unrecognized dimension value (`--add language:cobol`) exits non-zero with the "not in PLATFORM-SKILLS.md — consider PACK-FEEDBACK.md" diagnostic |
| **V-ADDCAP-06** | Declining the A4 confirmation prompt (`n`, EOF, SIGINT) exits 0 with no file changes |
| **V-ADDCAP-07** | Dirty working tree stops at A0 with the init-project.sh §7.5 diagnostic pattern |
| **V-ADDCAP-08** | Missing or invalid `$PACK` stops at A0 |
| **V-ADDCAP-09** | PM chat Procedure 6 run updates Active skills line without touching `x-` files or `## Custom agents` / `## Custom skills` sections |
| **V-ADDCAP-10** | After PM chat Procedure 6 run: the targeted placeholder sections (`[LANGUAGE_RULES]`, `[PLATFORM_ARCHITECTURE]`, etc. for the newly-added dimension) now contain non-trivial content; no placeholder-literal text (`[LANGUAGE_RULES — fill in from loaded skills]` or equivalent) remains in those sections; at least one full sentence is present per filled placeholder. (Byte-comparison against `.claude/skills/<name>/SKILL.md` is **not** the assertion — the PM chat step is interpretive per §3.3 step 6.2.) |
| **V-ADDCAP-11** | After Procedure 6 commit, trinity-diff shows three files with identical added content (TRIO preserved) |
| **V-ADDCAP-12** | Procedure 6 run against a project with existing `x-` files leaves all `x-` files byte-identical (git status shows no changes to `.claude/agents/x-*.md`, etc.) |
| **V-ADDCAP-13** | **Already-active exit.** Running `--add language:python` on a project where `language:python` is already in the Active skills line and all Python conditional files are already present: A2 exits 0 with "all requested capabilities already active"; no file changes; no trinity edits |
| **V-ADDCAP-14** | **Multi-dimension atomic invocation.** A single invocation with three flags — `--add language:python --add role:python-server --add protocol:grpc` — resolves all three deltas, copies all three file sets, and produces a single end-of-run prompt that names all three in the same "capabilities added" list |
| **V-ADDCAP-15** | **Trigger-rule firing.** The developer says to the PM chat "add Python to this project" without first running the script. The PM chat (observing its PM-CHAT.md behavioral rule) redirects the developer to run `add-capability.sh --add language:python` from the pack before beginning Procedure 6; it does not attempt the file-copy step itself |
| **V-ADDCAP-16** | **G6-drafts abort.** Developer runs the script through Procedure 6 up to G6-drafts, then declines the trinity drafts. Post-abort state: conditional files present on disk (from A5); `.gitignore` updated (from A6); trinity files unchanged; `git restore` on the conditional files is sufficient rollback (no partial trinity edit has been committed) |

**Matrix coverage.** V-ADDCAP-01, 02, 03, 03b cover all four
PLATFORM-SKILLS.md dimensions: language (2), platform (1), protocol
(4), role (3). V-ADDCAP-13–16 cover non-trivial edge cases across the
mechanism (already-active, multi-dimension, trigger-rule, abort). The
earlier draft's "Dimension 3 is covered by V-ADDCAP-03" claim has been
removed — `protocol:grpc` is Dimension 4, not Dimension 3, and the role
case needed its own test.

### 6.3 V9 Lesson 1 — placement justification

Lesson 1 (V10-DESIGN §L1): "Skills distribution design changed twice —
be explicit about where each artifact lives and why."

| Artifact | Placement | Why here, not elsewhere |
|---|---|---|
| `scripts/add-capability.sh` | Pack repo `scripts/` | Sibling to `init-project.sh` and `migrate-v9-to-v10.sh`; runs against a project but does not ship to projects. Placing it in `project-template/scripts/` would make every project carry a script that only the pack repo's contents can satisfy |
| `scripts/lib/detect.sh` extension | Existing shared library | Single source of truth for detection functions. V10-DESIGN §7.2 already established this library for init + migrate; capability-addition joins the set |
| Procedure 6 | METHODOLOGY.md Part 7 | Part 7 already hosts Procedure 1 (phase gate), Procedure 2 (post-session), Procedure 3 (orphan audit), Procedure 4 (resolution), Procedure 5 (custom agents/skills), Procedure 5-R (migration reconciliation). Procedure 6 is the sixth sibling. Placing it in PM-CHAT.md would split procedures across two files |
| Trigger rule | PM-CHAT.md Behavioral rules | One line; consistent with other trigger rules ("Detection scan at every startup"). A separate file would be a second PM-CHAT-like file |
| Prompt emission | add-capability.sh stdout + `.pack-add-capability-prompt.md` (gitignored, ephemeral) | Not committed to the project. Matches init-project.sh §7.8 end-of-run prompt pattern — the prompt is a hand-off, not an artifact. The ephemeral-file copy serves Desktop/MCP flows where stdout scrollback may not be accessible |
| Touch-point delta | V10-DESIGN Part 8 §8.2 (this addendum's §4.3 rows) | Part 8 is the single-source-of-truth touch-point inventory. All changes surface there |
| Glossary entry | V10-DESIGN Appendix B (per §4.1) | Appendix B already defines Procedure 5 and Procedure 5-R; Procedure 6 is added alongside for consistency |

Every artifact has exactly one owner and one location. No artifact
straddles surfaces.

### 6.4 Design invariants preserved

- **Trinity rule.** Trinity edits remain TRIO and commit together
  (V10-DESIGN Appendix B, §8.5).
- **x- preservation.** Procedure 6 explicitly forbids touching `x-`
  files; V-ADDCAP-12 enforces.
- **Project-owned regions.** PLATFORM-SKILLS.md `## Custom agents` /
  `## Custom skills` sections and trinity `### Custom agents` sub-
  sections are untouched by Procedure 6.
- **Single source of truth for conditional files.** V10-DESIGN §7.6
  stage S9 table is read by init-project.sh (remove-when-absent) and by
  add-capability.sh (add-when-newly-present). No second table.
- **Skill-loading uniformity.** `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/` already contain all 30 skills from init time. No
  skill file is written by Procedure 6; no tool-specific divergence is
  introduced.
- **Zero-dependency script policy.** `add-capability.sh` is shell;
  matches V10-DESIGN §7.1 rationale against Python dependencies for
  pre-flight work.

---

## Part 7 — Open Questions for Reviewer

(Open questions resolved in this revision are recorded as decisions in
Part 2 and are not listed here. Specifically: the earlier Open Q 4 on
multi-word dimension values was resolved and is now part of AD-A4.)

1. **Commit placement.** C-046-ADD-01 in Phase 3 (default here) vs.
   folded into Phase 2c alongside migration. Phase 3 keeps the three
   add-capability commits co-located; Phase 2c groups all scripts that
   source `scripts/lib/detect.sh`. Either is acceptable; phase-3
   grouping is the default in this addendum.
2. **Trigger-rule wording.** The one-line PM-CHAT.md addition is
   drafted in §4.3; final wording is pending Procedure 6 section author.
3. **README layout row placement.** Does
   `scripts/add-capability.sh` get its own line, or does the
   README Repository Layout entry for `scripts/` gain a sub-bullet list?
   Consistency with `scripts/init-project.sh` and
   `scripts/migrate-v9-to-v10.sh` suggests matching whatever Commit
   C-044-06 lands on.
4. **Pack-version banner formalization.** A0 currently warns on a
   version-string mismatch read from a human-readable banner. A future
   minor iteration may promote the banner to a fenced frontmatter block
   with a machine-readable `pack-version:` key (trinity rule applies).
   Not required for v10.0.

---

## Part 8 — Summary

A two-part mechanism:

1. `scripts/add-capability.sh` — new pack-operational script, sibling to
   `init-project.sh` and `migrate-v9-to-v10.sh`; copies conditional
   project files for a newly-added PLATFORM-SKILLS.md dimension value;
   emits a PM chat prompt to stdout and to an ephemeral gitignored file.
2. METHODOLOGY.md Procedure 6 — PM chat workflow for updating the
   Active skills line and filling trinity [PLACEHOLDER] sections from
   on-disk skill content, with G6-drafts and G6-commit approval gates.

Three new commits in Phase 3, zero modifications to existing V10-DESIGN
ADs, zero new BACKLOG items, cross-surface parity (including Claude
Desktop per §3.1), four-dimension uniformity with atomic-token grammar
(AD-A4). Blast radius: one new script, one detect.sh function, one
METHODOLOGY.md procedure, one PM-CHAT.md line, one README layout line,
one Part 7 §7.13 integration bullet, one Appendix B glossary entry.

Dormant until the developer invokes it.
