# Phase 3 — v10.0 Implementation Plan (v2)

**Status:** DRAFT v2 — supersedes `phase-3-implementation-plan.md` (v1).
**Primary input:** `maintenance-docs/V10-DESIGN.md` (APPROVED, 4,091 lines).
This is the sole authoritative design document; V10-DESIGN-2.md has been
merged into it and is now a historical working artifact (V10-DESIGN
Part 0).
**Secondary inputs:** `CLAUDE.md` (pack-repo rules), `PACK-AGENTS.md`,
`README.md` (repository layout), `BACKLOG.md` (BD-044, BD-045, BD-046),
`scripts/validate-pack.py`.
**Consumer:** Phase 4 pack chat (implementer). This plan + V10-DESIGN.md
are the only references required to execute v10.0. **v1 is not required
reading.**

---

## 0. What changed from v1

Reader skip this section if v1 was never read. Retained for traceability.

1. **Capability-addition mechanism integrated** (V10-DESIGN AD-14..AD-18;
   §5.14; §5.7 Procedure 6; §7.2 `detect_installed_capabilities`;
   §7.13; §8.2.8; §10.17; §12.5). Three new commits land in Phase 3
   after the BD-044 init-project commits.
2. **Rule-15 back-reference decision is MANDATORY at Gate A** (developer
   correction B1). Either rule 15 is extended in `audit-methodology/
   SKILL.md`, or the "no extension" decision is recorded with a concrete
   reason. Gate A blocks if no decision is recorded. No more
   "conditional" commit.
3. **Fixture-based testing strategy is concrete and executable** (B2,
   B8). Two named fixtures: a **minimal v10 pack install** fixture for
   V-X-PRESERVE / V-ADDCAP / Procedure 5 tests, and a **synthetic v9.3
   project** fixture for V-M1-* migration and rollback rehearsals.
   Neither uses the pack repo itself.
4. **BD-045 renumbering sweep is rigorous** (B3). Exact old rule
   numbers that must return zero matches; exact new rule numbers with
   expected counts; full file scope (`project-template/`,
   `supporting-docs/`, `maintenance-docs/`); range-reference patterns
   (`rules 11–14`) and specific-reference patterns (`per rule 14`)
   covered.
5. **Sentinel-file cleanup flow** in migration pre-flight (B4). S0
   detects stale sentinels from a prior run; developer chooses
   "resume" or "start fresh." Start-fresh deletes
   `.pack-migration-backup/`. Documented in MIGRATION guide.
6. **`detect.sh` unit tests added to Phase 4** (B5). Every detection
   function has at least one input/expected-output case.
7. **`merge-trinity.py` pre-check** added (B6). Before Stage S5 (and
   in migration pre-flight), the helper verifies the `**Active skills:**`
   line exists and matches the expected pattern. Mismatch stops and
   asks the developer. No silent splice.
8. **Gate F runs ALL six sweeps** from V10-DESIGN §8.6** (B7). Each
   sweep has an explicit expected result (zero matches for stale
   patterns, expected counts for valid patterns). Targeted sweeps
   remain at intermediate gates; Gate F is the mandatory full-set pass.
9. **Git worktree replaces simple branch checkout** (C). All v10
   implementation work happens in a worktree at `../v10-dev/` pinned to
   the `v10-dev` branch. Worktree is merged back to `main` at ship.

---

## 1. Goal and BD items addressed

Implement v10.0 of the AI Agent Config Pack on branch `v10-dev` via a
git worktree, commit by commit, with approval gates, inline verification
at every stage, and a clean `Validate Pack` CI state after every
commit. Ship v10.0 to `main` with tags `v10.0` and floating `v10`.

BD items in scope (all three currently **Unblocked** in BACKLOG.md as
of 2026-04-22):

- **BD-045** — Champion the capabilities design pattern alongside LSP
  in architecture guidance. First in implementation order: least
  structural risk; purely additive content.
- **BD-046** — v10 scope umbrella. Covers **four** bullets per
  V10-DESIGN AD-18 (BACKLOG update, row 83):
  (a) custom agent and skill support (Part 5);
  (b) prompt template reorganization (Part 4);
  (c) migration v9.3 → v10.0 (Part 6);
  (d) **capability addition for existing v10 projects** (Part 5 §5.14;
  AD-14..AD-18). (d) is new in the merged design and did not exist
  in v1 of this plan.
- **BD-044** — Project setup paths: `init-project.sh`, QUICKSTART
  router, existing-project onboarding. Depends on the final v10 file
  structure produced by BD-046.

Sequencing (V10-DESIGN Part 12 §12.1): **BD-045 → BD-046 core → BD-044
→ BD-046 capability addition.** The capability-addition commits sit at
the end of Phase 3 because they depend on BD-044 having landed
`scripts/lib/detect.sh` and the README Repository Layout baseline, and
on BD-046 having landed METHODOLOGY.md Procedure 5 (Procedure 6 is
Procedure 5's sibling).

---

## 2. Key principles applied throughout this plan

1. **Incremental testability.** `python3 scripts/validate-pack.py`
   passes after every single commit. Each commit leaves the pack in a
   working state.
2. **Trinity rule (CLAUDE.md / AGENTS.md / GEMINI.md).** Every trinity
   edit is an atomic commit touching all three files. The pack-repo
   trinity files (top-level) and the project-template trinity files
   (inside `project-template/`) each have their own trinity commits —
   v10 touches only `project-template/` trinity files.
3. **Reserved `x-` prefix invariant.** The pack ships zero `x-` files.
   Enforced by `validate-pack.py` Check 8 from commit C-046-11 onward;
   manually enforced before then by Gate-local greps.
4. **Validator lands with or immediately after target content — never
   before.** A new `validate-pack.py` check lands in the commit that
   targets existing content, so CI never sees a check referencing files
   that do not yet exist.
5. **Blast-radius wider than change set.** After every batch of
   commits, the relevant V10-DESIGN §8.6 sweeps run. Gate F mandates
   all six sweeps against their expected results.
6. **No commit or push without explicit user approval** (CLAUDE.md).
   Every gate (A, B, C, D, E, E2, F, Ship) is a stop.
7. **Historical records are annotated, not mutated** (V9 Lessons 4,
   5). V9-DESIGN.md and V9-AUDIT-REPORT.md receive supersession
   annotations (C-046-09); V10-PREDESIGN.md receives a supersession
   banner (S-02); MIGRATION-v8-to-v9.md receives an optional single-
   line pointer to MIGRATION-v9-to-v10.md (C-046-10 — implementer
   may skip if the pointer adds no value). Body content is preserved
   in all cases.
8. **Single source of truth for conditional-file mapping.** The
   §7.6 conditional-removal table (init-project) is inverted at run
   time by `scripts/add-capability.sh` (Part 5 §5.14.7). Neither
   script hardcodes a second copy.
9. **Mandatory decision points are named gate blockers.** The
   audit-methodology rule 15 decision (B1) is a Gate A entry criterion
   — not a trailing TODO.
10. **All scripts are read-only by default in their pre-confirm phase.**
    `init-project.sh` S0, `migrate-v9-to-v10.sh` S0, and
    `add-capability.sh` A0–A3 never write until developer confirms.

---

## 3. Affected files — complete inventory

Sourced from V10-DESIGN Part 8 §8.2 rows 1–84 (capability-addition rows
78–84 incorporated). Every row appears in at least one commit in §5.
"Combine with X" markers from Part 8 are honored.

### 3.1 Pack-repository files (v10.0 edits)

| Category | Files | Part 8 rows | Commit(s) |
|---|---|---|---|
| Trinity (pack template) | `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | 1–3 (BD-045), 26–28 (docs/pack row), 39–41 (custom-agents sub-section) | C-045-01 (BD-045), C-046-03 (BD-046) |
| Skills with renumbered rules | `skills/apple-architecture-core/SKILL.md`, `skills/python-best-practices/SKILL.md`, `skills/architecture-review/SKILL.md` | 4, 5, 6 | C-045-02 |
| Auditor-architecture trio | `.claude/agents/auditor-architecture.md`, `.codex/agents/auditor-architecture.toml`, `.gemini/agents/auditor-architecture.md` | 7, 8, 9 | C-045-03 |
| audit-methodology rule 15 | `skills/audit-methodology/SKILL.md` | §13.4 / §8.2.1 back-reference (B1 mandatory) | C-045-04 |
| Prompts directory + 10 per-agent files + PROMPT-AUTHORING.md | `docs/pack/prompts/*.md` × 10 + `PROMPT-AUTHORING.md` | 11–22 | C-046-01 |
| Stale-reference sweep (pack template) | `docs/pack/PM-CHAT.md`, `skills/pm-startup/SKILL.md`, `project-template/README.md`, trinity files | 24, 25, 26–28, 29 | C-046-03, C-046-04, C-046-06, C-046-07 |
| PROMPT-TEMPLATES.md deletion | `supporting-docs/PROMPT-TEMPLATES.md` | 23 | C-044-07 (moved to Phase 3; see §5) |
| Supporting-docs sweep | `supporting-docs/METHODOLOGY.md`, `CLI-PM-SETUP.md`, `SETUP_TEMPLATE.md`, `DEPENDENCIES.md`, `MIGRATION-v8-to-v9.md` | 30, 32, 33, 34, 35 | C-046-08 (METHODOLOGY), C-046-10 (others) |
| Maintenance-docs annotation | `V9-DESIGN.md`, `V9-AUDIT-REPORT.md` (if present) | 36, 37 | C-046-09 |
| Custom agent sections | `docs/pack/PM-CHAT.md` (combines row 24+38+81), trinity `### Custom agents` (combines 26–28+39–41), `docs/pack/PLATFORM-SKILLS.md` `## Custom agents`+`## Custom skills` | 38, 39–41, 42, 81 | C-046-03 (trinity), C-046-04 (PM-CHAT inc. trigger rule), C-046-05 (PLATFORM-SKILLS) |
| METHODOLOGY.md Procedure 5/5-R/6 + PROMPT-TEMPLATES sweep | `supporting-docs/METHODOLOGY.md` | 30+43+48+80 (combined) | C-046-08 adds Procedure 5+5-R+sweep; C-046-ADD-02 adds Procedure 6 |
| Migration tooling | `scripts/migrate-v9-to-v10.sh`, `scripts/merge-platform-skills.py`, `scripts/merge-trinity.py`, `supporting-docs/MIGRATION-v9-to-v10.md` | 44–47 | C-046-13 (merge-platform-skills), C-046-14 (merge-trinity), C-046-15 (migrate-v9-to-v10.sh), C-046-16 (guide) |
| Init tooling | `scripts/init-project.sh`, `scripts/lib/` dir, `scripts/lib/detect.sh`, `supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP-EXISTING.md`, `QUICKSTART.md`, top-level `README.md` layout | 49–55 | C-044-01 (detect.sh dir/file), C-044-02..06 |
| **Capability-addition tooling (new in v2)** | `scripts/add-capability.sh`; `scripts/lib/detect.sh` extension (`detect_installed_capabilities()`); METHODOLOGY.md Procedure 6; PM-CHAT.md trigger rule; top-level README layout entry | 78, 79, 80, 81, 82 | C-046-ADD-01 (script + detect.sh extension); C-046-ADD-02 (Procedure 6 + PM-CHAT trigger line); C-046-ADD-03 (README layout line) |
| validate-pack.py | Checks 6, 7, 8, 9; Check 1/5 parity re-verify | 56–60 | C-046-02 (Check 6), C-046-11 (Checks 7+8), C-044-08 (Check 9) |
| CI workflow | `.github/workflows/validate-pack.yml` (re-verify only) | 61 | no-commit-expected, confirmed at Gate E |
| BACKLOG.md capability-addition bullet | `BACKLOG.md` — BD-046 4th bullet per AD-18 | 83 | combined into S-03 (ship commit that resolves BD items) |
| Version bookkeeping | `maintenance-docs/V10-DESIGN.md` (already APPROVED), `V10-PREDESIGN.md` banner, `BACKLOG.md`, top-level `README.md` version table, `CHANGELOG.md` | 62–66 | S-01 (CHANGELOG), S-02 (README row + V10-PREDESIGN banner), S-03 (BACKLOG resolutions + BD-046 scope extension) |

### 3.2 Runtime-produced files (NOT pack-repo commits)

V10-DESIGN Part 8 §8.3 rows 67–77 plus row 84 are produced by
`init-project.sh`, `migrate-v9-to-v10.sh`, `add-capability.sh`, or the
PM chat in downstream projects. They are **not** edited in this plan;
they are validated by Part 10 tests V-INIT-VERIFY-*, V-X-PRESERVE-*,
V-PM5-*, V-ADDCAP-*.

| # | Project path | Actor | Tested by |
|---|---|---|---|
| 67 | `docs/pack/prompts/` + 10 files + PROMPT-AUTHORING.md | `init-project.sh` / `migrate-v9-to-v10.sh` S4 | V-INIT-VERIFY-05, V-INC-05 |
| 68 | `docs/pack/prompts/_v9-backup.md` (conditional) | migrate S6; PM chat deletes | V-M1-CUSTOM-02/03 |
| 69 | `docs/pack/PROMPT-TEMPLATES.md` (v9.3) deletion | migrate S6 | V-M1-01 |
| 70 | `x-*` agent files (×3 tools) | PM chat Procedure 5.1 | V-PM5-01 |
| 71 | `x-*/SKILL.md` (×3 tools) | PM chat Procedure 5.2 | V-PM5-02 |
| 72 | `docs/pack/prompts/x-*.md` | PM chat Procedure 5.1 | V-PM5-01 |
| 73 | PLATFORM-SKILLS.md custom rows | PM chat 5.1/5.2 | V-PM5-01/02 |
| 74 | Trinity `### Custom agents` rows | PM chat 5.1 (TRIO) | V-PM5-01 |
| 75 | `docs/pack/PACK-FEEDBACK.md` entries | PM chat kickoff on skill gap | V-INIT-EXIST-05 |
| 76 | `.gitignore` merges | `init-project.sh` S8; migrate S0; add-capability A6 | V-INIT-VERIFY-07, V-ADDCAP-01 |
| 77 | `.pack-migration-backup/v9.3-to-v10.0/*` | migrate | V-INC-01..09 |
| **84** | `.pack-add-capability-prompt.md` | `add-capability.sh` A7 (create); developer (optional delete) | V-ADDCAP-01, V-ADDCAP-14 |

### 3.3 Cross-reference file sweep (mandatory at Gate F)

Every file named by the six grep targets in V10-DESIGN §8.6 is in scope
even if not listed in §3.1. The six-sweep expectation set is in §6 and
§8 below.

---

## 4. Git worktree setup and phase map

### 4.1 Worktree creation (replaces v1 §4.1 simple checkout)

Rationale: a worktree lets the developer keep `main` checked out in one
working directory (for emergency hot-fix, pack-chat sessions, or
reference reads) while v10 work lives in a separate directory
(`../v10-dev/`). The worktree is attached to the same repo — tags,
branches, and history are shared. Merge back to main happens from
either working directory.

```bash
# Starting point: cwd = main checkout of dhs-ai-agent-config-pack
cd /Users/david/Developer/dhs-ai-agent-config-pack
git fetch origin
git checkout main
git pull --ff-only

# Create the v10-dev branch if it does not already exist
git branch --list v10-dev | grep -q v10-dev || git branch v10-dev

# Create the worktree at a sibling path
git worktree add ../v10-dev v10-dev

# Publish the branch (first push only)
cd ../v10-dev
git push -u origin v10-dev

# From this point on, all v10 commits run from ../v10-dev.
# Return to main working dir for anything else:
#   cd /Users/david/Developer/dhs-ai-agent-config-pack
```

Operational rules:
- All Phase 1–5 commits land on `v10-dev` from the worktree.
- Pack chat / pack-planner / pack-reviewer sessions read from whichever
  working directory is appropriate; read-only agents must not
  accidentally commit from the main working directory.
- `CLAUDE.md` in both worktrees is identical by virtue of both being
  pinned to the same git history; no trinity-rule issue.
- At ship time (Phase 5), `git merge --no-ff v10-dev -m "..."` runs
  from the `main` working directory after its `git pull`.
- After ship, the worktree can be removed: `git worktree remove
  ../v10-dev` (only after the branch is merged and tagged).

### 4.2 Phase map (top level)

| Phase | Scope | Commits | Approval gate at end |
|---|---|---|---|
| **0** | Worktree setup | 0 | (pre-work; user approves worktree creation) |
| **1** | BD-045 capabilities pattern (9 pack locations + rule 15 decision) | 4 | **Gate A** |
| **2a** | BD-046 prompt reorg (new directory, 10 files, PROMPT-AUTHORING.md, Check 6) | 2 | **Gate B** |
| **2b** | BD-046 custom-agent mechanism + stale-reference sweep + Checks 7/8 | 9 | **Gate C** |
| **2c** | BD-046 migration (detect.sh, merge helpers, migrate script, guide) | 5 | **Gate D** |
| **3** | BD-044 init-project.sh + SETUP guides + QUICKSTART router + README layout + Check 9 + PROMPT-TEMPLATES.md deletion | 7 | **Gate E** |
| **3-AC** | BD-046 capability-addition (add-capability.sh, detect.sh extension, Procedure 6, README line) | 3 | **Gate E2** |
| **4** | Full verification pass (Part 10 CP tests; all six sweeps; deferred smoke tests) | 0 (verification only; `fix:` commits only if needed) | **Gate F** |
| **5** | Ship — CHANGELOG, README version row, BACKLOG resolution, merge, tag | 3 + merge + tags | **Ship approval** |
| **6** | Post-ship — OT project migration, deferred follow-through | per-project | — |

Each phase's commits are defined in §5. Approval-gate entry criteria
are in §10.

---

## 5. Fixture-based testing strategy

Tests for custom agents, custom skills, `x-` file preservation,
capability addition, and migration **do not use the pack repo as
working directory**. Two named fixtures are created under an ephemeral
temp parent (`$TMPDIR/v10-fixtures/`) and are regenerable by scripts
that the implementer writes during Phase 4.

### 5.1 Fixture A — Minimal v10 pack install (for V-X-PRESERVE-*, V-ADDCAP-*, V-PM5-*)

**Purpose.** Simulate a downstream project already initialized by
`init-project.sh` — a fresh v10 install. Used to exercise custom agent
workflows, capability-addition runs, and PM-chat detection scans.

**Creation script** (`maintenance-docs/v10-working/fixtures/make-fixture-a.sh`,
authored in Phase 4 when fixtures are first needed):

```bash
#!/usr/bin/env bash
# make-fixture-a.sh — creates a minimal v10 pack-install fixture.
# Usage: make-fixture-a.sh <dest-dir> [--with-x-files]
set -euo pipefail
DEST="${1:?fixture destination required}"
WITH_X=${2:-}

PACK="/Users/david/Developer/dhs-ai-agent-config-pack"    # main worktree

mkdir -p "$DEST"
cd "$DEST"
git init -q
echo "# Fixture A" > README.md
git add README.md
git -c user.email=f@f -c user.name=f commit -qm "fixture init"

# Mimic a completed init-project.sh run:
#  - all 16 pack agents in each of three tool dirs (Claude .md, Codex .toml, Gemini .md)
#  - all 30 pack skills in each of three skill dirs (SKILL.md only)
#  - PLATFORM-SKILLS.md, PM-CHAT.md, METHODOLOGY.md, PACK-FEEDBACK.md, prompts/ (10 + AUTHORING)
#  - trinity (CLAUDE.md / AGENTS.md / GEMINI.md) from the pack template
#  - Active skills line populated with a Swift/macOS profile
#  - scripts/ with v10 pack scripts; agent-run.sh executable

mkdir -p .claude/agents .codex/agents .gemini/agents
mkdir -p .claude/skills .codex/skills .gemini/skills
mkdir -p docs/pack/prompts scripts

cp "$PACK"/project-template/.claude/agents/*.md       .claude/agents/
cp "$PACK"/project-template/.codex/agents/*.toml      .codex/agents/
cp "$PACK"/project-template/.gemini/agents/*.md       .gemini/agents/
for s in "$PACK"/project-template/skills/*/; do
  name=$(basename "$s")
  for tool in claude codex gemini; do
    mkdir -p .$tool/skills/$name
    cp "$s/SKILL.md" .$tool/skills/$name/SKILL.md
  done
done
cp "$PACK"/project-template/CLAUDE.md .
cp "$PACK"/project-template/AGENTS.md .
cp "$PACK"/project-template/GEMINI.md .
cp -r "$PACK"/project-template/docs/pack/*       docs/pack/
cp "$PACK"/project-template/agent-run.sh         .
cp "$PACK"/project-template/scripts/*            scripts/ 2>/dev/null || true
chmod +x agent-run.sh scripts/*.sh 2>/dev/null || true

# Seed an Active skills line consistent with macOS + Swift profile.
# (Real init-project.sh writes this during placeholder fill; here we just stub
#  a known value the tests can assert against.)
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  awk 'BEGIN{done=0} /^\*\*Active skills:\*\*/ && !done {
         print "**Active skills:** swift-best-practices, apple-architecture-core, macos-architecture";
         done=1; next } { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Optional: seed custom x- files for preservation testing.
if [[ "$WITH_X" == "--with-x-files" ]]; then
  cat > .claude/agents/x-deployer.md <<'X'
---
name: x-deployer
description: Release packaging (fixture seed)
tools: Bash, Read, Write
---
# x-deployer
fixture seed
X
  cat > .codex/agents/x-deployer.toml <<'X'
name = "x-deployer"
description = "Release packaging (fixture seed)"
model = "gpt-5-codex"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
developer_instructions = """
fixture seed
"""
X
  cat > .gemini/agents/x-deployer.md <<'X'
---
name: x-deployer
description: Release packaging (fixture seed)
model: gemini-2.5-pro
temperature: 0.2
max_turns: 20
---
# x-deployer
fixture seed
X
  mkdir -p .claude/skills/x-brokerage-api .codex/skills/x-brokerage-api .gemini/skills/x-brokerage-api
  cat > /tmp/x-skill.md <<'X'
---
name: x-brokerage-api
description: Broker adapter patterns (fixture seed)
allowed-tools: Read, Grep
---
# x-brokerage-api
fixture seed
X
  cp /tmp/x-skill.md .claude/skills/x-brokerage-api/SKILL.md
  cp /tmp/x-skill.md .codex/skills/x-brokerage-api/SKILL.md
  cp /tmp/x-skill.md .gemini/skills/x-brokerage-api/SKILL.md
  cat > docs/pack/prompts/x-deployer.md <<'X'
---
agent: x-deployer
variants:
  - standard
---
# x-deployer prompts
## Variant: standard
fixture seed
X
fi

git add -A
git -c user.email=f@f -c user.name=f commit -qm "fixture seed"
echo "Fixture A created at $DEST"
```

**Files counted on creation (asserted by tests):**
- 16 Claude agent files, 16 Codex TOML, 16 Gemini agent files.
- 30 skill directories in each of `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/`.
- `docs/pack/prompts/` with 10 per-agent files + `PROMPT-AUTHORING.md`.
- Trinity files with populated Active-skills line.
- `docs/pack/PLATFORM-SKILLS.md`, `PM-CHAT.md`, `METHODOLOGY.md`,
  `PACK-FEEDBACK.md`.
- `scripts/` with v10 project-level scripts (bootstrap, validate, test,
  format, etc.) and `agent-run.sh` executable. Note: pack-repo scripts
  (`init-project.sh`, `migrate-v9-to-v10.sh`, `add-capability.sh`) are
  invoked against the fixture by absolute `$PACK` path, never copied in.

**Used by tests:**
- V-X-PRESERVE-01/02/03 (preservation + stray `x-` in pack skill dir
  stop condition).
- V-ADDCAP-01/02/03/03b/04..16 (capability addition — with and without seeded `x-`
  files per V-ADDCAP-09/12).
- V-PM5-01..10 (custom agent/skill workflows + detection scan).
- V-CI-05/06 (reserved `x-` prefix, pack repo — fixture deliberately
  adds `x-*` in **project** directories; this does not affect pack-repo
  Check 8 which runs against the pack repo itself, not the fixture).

### 5.2 Fixture B — Synthetic v9.3 project (for V-M1-*, V-M1-ROLLBACK, V-M1-CUSTOM-*)

**Purpose.** Simulate a v9.3 project that will be migrated to v10.0.

**Creation script** (`maintenance-docs/v10-working/fixtures/make-fixture-b.sh`):

```bash
#!/usr/bin/env bash
# make-fixture-b.sh — creates a synthetic v9.3 project fixture.
# Usage: make-fixture-b.sh <dest-dir> [swift|python|monorepo|grpc] [--with-x-files] [--with-custom-prompt-templates]
set -euo pipefail
DEST="${1:?dest required}"
PROFILE="${2:-swift}"
WITH_X=${3:-}
WITH_CUSTOM=${4:-}

PACK="/Users/david/Developer/dhs-ai-agent-config-pack"

mkdir -p "$DEST"
cd "$DEST"
git init -q
echo "# Fixture B — v9.3 ($PROFILE)" > README.md
git add README.md
git -c user.email=f@f -c user.name=f commit -qm "fixture init"

# Precondition: v9.3 tag must exist in $PACK. If absent:
#   git -C "$PACK" fetch --tags
# Check out v9.3 pack contents into temp to source files from
TMP=$(mktemp -d)
git -C "$PACK" worktree add "$TMP" v9.3
trap 'git -C "$PACK" worktree remove -f "$TMP"' EXIT

# v9.3 structure: 16 agents × 3 tools, 30 skills × 3 tools, PROMPT-TEMPLATES.md,
# trinity files (with Active skills line), scripts/, agent-run.sh, docs/pack/
mkdir -p .claude/agents .codex/agents .gemini/agents
mkdir -p .claude/skills .codex/skills .gemini/skills
mkdir -p docs/pack scripts

cp "$TMP"/project-template/.claude/agents/*.md   .claude/agents/
cp "$TMP"/project-template/.codex/agents/*.toml  .codex/agents/
cp "$TMP"/project-template/.gemini/agents/*.md   .gemini/agents/
for s in "$TMP"/project-template/skills/*/; do
  name=$(basename "$s")
  for tool in claude codex gemini; do
    mkdir -p .$tool/skills/$name
    cp "$s/SKILL.md" .$tool/skills/$name/SKILL.md
  done
done
cp "$TMP"/project-template/CLAUDE.md .
cp "$TMP"/project-template/AGENTS.md .
cp "$TMP"/project-template/GEMINI.md .
# v9.3: docs/pack/ contains METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md, PLATFORM-SKILLS.md, PACK-FEEDBACK.md
cp "$TMP"/project-template/docs/pack/*.md        docs/pack/
cp "$TMP"/project-template/scripts/*             scripts/
cp "$TMP"/project-template/agent-run.sh          .
chmod +x agent-run.sh scripts/*.sh

# Profile-specific conditional files
case "$PROFILE" in
  swift)
    # leave as-is; no Python/proto files
    rm -f scripts/bootstrap-python.sh scripts/format-python.sh scripts/validate-python.sh scripts/test-python.sh 2>/dev/null || true
    rm -f pyproject.toml pyrightconfig.json 2>/dev/null || true
    rm -rf server/ proto/ 2>/dev/null || true
    ;;
  python)
    rm -f scripts/bootstrap-swift.sh scripts/format-swift.sh scripts/validate-swift.sh scripts/test-swift.sh 2>/dev/null || true
    cp "$TMP"/project-template/pyproject.toml     . 2>/dev/null || true
    cp "$TMP"/project-template/pyrightconfig.json . 2>/dev/null || true
    cp -r "$TMP"/project-template/server/         . 2>/dev/null || true
    ;;
  monorepo)
    cp "$TMP"/project-template/pyproject.toml     . 2>/dev/null || true
    cp "$TMP"/project-template/pyrightconfig.json . 2>/dev/null || true
    cp -r "$TMP"/project-template/server/         . 2>/dev/null || true
    ;;
  grpc)
    cp -r "$TMP"/project-template/proto/          . 2>/dev/null || true
    ;;
esac

# Populate Active skills line — a v9.3 invariant
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  awk 'BEGIN{done=0} /^\*\*Active skills:\*\*/ && !done {
         print "**Active skills:** swift-best-practices, apple-architecture-core, macos-architecture";
         done=1; next } { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Optional: seed x- custom files (exercises V-X-PRESERVE-*, V-M1-02/04/11/14)
if [[ "$WITH_X" == "--with-x-files" || "$WITH_CUSTOM" == "--with-x-files" ]]; then
  cat > .claude/agents/x-deployer.md <<'X'
---
name: x-deployer
description: Release packaging (fixture seed)
tools: Bash, Read, Write
---
# x-deployer
fixture seed
X
  cat > .codex/agents/x-deployer.toml <<'X'
name = "x-deployer"
description = "Release packaging (fixture seed)"
model = "gpt-5-codex"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
developer_instructions = """
fixture seed
"""
X
  cat > .gemini/agents/x-deployer.md <<'X'
---
name: x-deployer
description: Release packaging (fixture seed)
model: gemini-2.5-pro
temperature: 0.2
max_turns: 20
---
# x-deployer
fixture seed
X
  mkdir -p .claude/skills/x-brokerage-api .codex/skills/x-brokerage-api .gemini/skills/x-brokerage-api
  cat > /tmp/x-skill.md <<'X'
---
name: x-brokerage-api
description: Broker adapter patterns (fixture seed)
allowed-tools: Read, Grep
---
# x-brokerage-api
fixture seed
X
  cp /tmp/x-skill.md .claude/skills/x-brokerage-api/SKILL.md
  cp /tmp/x-skill.md .codex/skills/x-brokerage-api/SKILL.md
  cp /tmp/x-skill.md .gemini/skills/x-brokerage-api/SKILL.md
  # Note: v9.3 has no docs/pack/prompts/ directory, so no x- prompt file
  # is seeded here. The migration creates docs/pack/prompts/ at S4;
  # x- prompt preservation is tested in Fixture A (v10 install) instead.
fi

# Optional: corrupt PROMPT-TEMPLATES.md with a one-sentence custom addition
if [[ "$WITH_CUSTOM" == "--with-custom-prompt-templates" || "$WITH_X" == "--with-custom-prompt-templates" ]]; then
  echo "" >> docs/pack/PROMPT-TEMPLATES.md
  echo "<!-- Project-specific note: custom convention for Template 4 fix-cycle -->" >> docs/pack/PROMPT-TEMPLATES.md
fi

git add -A
git -c user.email=f@f -c user.name=f commit -qm "fixture v9.3 $PROFILE seed"
echo "Fixture B ($PROFILE) created at $DEST"
```

**Used by tests:**
- V-M1-01..15 (migration matrix across profiles + tools + custom states).
- V-M1-ROLLBACK (Part 6 §6.7 rollback rehearsal).
- V-M1-CUSTOM-01/02/03 (PROMPT-TEMPLATES.md divergence handling +
  Procedure 5-R).
- V-X-PRESERVE-01 (`x-` files preserved across migration).

### 5.3 Where the fixture scripts live

Under `maintenance-docs/v10-working/fixtures/` during Phase 4 (working
artifacts, not pack product). After Phase 6 post-ship review they are
either archived (moved under `maintenance-docs/v10-working/` still) or
promoted to `scripts/` as regression-test infrastructure. Phase 3 does
not commit these scripts to the pack repo; they exist only on the
developer's filesystem during verification. Recorded here so the next
implementer knows they are a Phase 4 build artifact.

---

## 6. Ordered commit plan

Every commit lists:
(a) commit message,
(b) V10-DESIGN Part 8 rows covered,
(c) V10-DESIGN source sections the implementer reads,
(d) files touched,
(e) dependencies on prior commits,
(f) per-commit verification,
(g) approval gate membership.

Commit format (CLAUDE.md pack-repo rules):
- `feat: v10 — BD-NNN short description` for behavioral additions.
- `docs: v10 — BD-NNN short description` for doc-only commits.
- `fix: <brief>` for corrections.

### 6.1 Phase 1 — BD-045 capabilities pattern

#### C-045-01 — Trinity capabilities section (TRIO)

- **Message:** `feat: v10 — BD-045 capabilities pattern in trinity files`
- **Part 8 rows:** 1, 2, 3.
- **Source sections:** V10-DESIGN Part 3 §3.1 (principles), §3.2
  (section text + anti-pattern bullet verbatim), §3.9 (LSP-vs-
  capabilities exact wording), §3.10 (BD-045 × BD-046 integration).
- **Files:**
  - `project-template/CLAUDE.md`
  - `project-template/AGENTS.md`
  - `project-template/GEMINI.md`
- **Action in each file:** insert `## Capabilities pattern` H2 between
  `## Liskov Substitution Principle` and `## Dependency intake policy`;
  append anti-pattern bullet to universal anti-patterns list. Copy
  text verbatim from Part 3 §3.2. Byte-identical across the three.
- **Dependencies:** none (first commit).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — all existing checks pass.
  - `diff project-template/CLAUDE.md project-template/AGENTS.md |
    grep "Capabilities"` returns nothing (new section byte-identical).
  - `grep -c "^## Capabilities pattern$" project-template/{CLAUDE,AGENTS,GEMINI}.md`
    returns 3 total matches.
  - V-BD045-01, V-BD045-02, V-BD045-03 pass.
- **Gate:** member of Gate A.

#### C-045-02 — Skills capabilities sections with renumbering

- **Message:** `feat: v10 — BD-045 capabilities rules in apple / python / architecture-review skills`
- **Part 8 rows:** 4, 5, 6.
- **Source sections:** Part 3 §3.3 (apple-architecture-core — new
  rules 11–14; renumber old 11–23 → 15–27), §3.4 (python-best-
  practices — new rules 14–17; renumber old 14–32 → 18–36), §3.6
  (architecture-review — new rules 14–17; renumber old 14–15 → 18–19).
- **Files:**
  - `project-template/skills/apple-architecture-core/SKILL.md`
  - `project-template/skills/python-best-practices/SKILL.md`
  - `project-template/skills/architecture-review/SKILL.md`
- **Dependencies:** C-045-01 (trinity capabilities section exists so
  the skills' references to the pattern point at a real source).
- **Verification after commit:**
  - `validate-pack.py` Check 1 (SKILL.md frontmatter) passes on all
    three (V-CI-08).
  - **Rigorous renumbering sweep (B3).** See §8 sweep S6 for
    expected-count matrix. At minimum:
    ```bash
    # apple-architecture-core — new section is rules 11–14; old 11–23 now 15–27
    grep -nE "^1[1-4]\\. " project-template/skills/apple-architecture-core/SKILL.md   # expect new rules 11–14 (the capabilities section)
    grep -nE "^(1[5-9]|2[0-7])\\. " project-template/skills/apple-architecture-core/SKILL.md  # expect renumbered 15–27
    # No rule-number-20-29 collisions should remain that refer to old content
    # Cross-file rule references — exact old numbers must now be zero:
    grep -rnE "apple-architecture-core.*rule (11|12|13|14)\\b" \
        project-template/ supporting-docs/ maintenance-docs/
    # Expected: zero matches (these old numbers now refer to the Capabilities section,
    # but external references were written against old rule content)
    ```
  - Full sweep S6 from §8 runs with detailed expected results.
  - Every stale match is fixed in this same commit before advancing.
  - V-BD045-07 passes.
- **Gate:** member of Gate A.

#### C-045-03 — Auditor-architecture trio (BD-045 scope bullet)

- **Message:** `feat: v10 — BD-045 capabilities scope in auditor-architecture (trio)`
- **Part 8 rows:** 7, 8, 9.
- **Source sections:** Part 3 §3.7 (exact Claude/Gemini markdown; exact
  Codex plain-bullet form inside `developer_instructions = """..."""`).
- **Files:**
  - `project-template/.claude/agents/auditor-architecture.md`
  - `project-template/.codex/agents/auditor-architecture.toml`
  - `project-template/.gemini/agents/auditor-architecture.md`
- **Action:** insert new `Capabilities pattern adherence` bullet
  immediately after existing `LSP compliance` bullet in Scope list.
  Copy Claude/Gemini markdown byte-identical; Codex plain-bullet per
  §3.7 formatting rule.
- **Dependencies:** C-045-02 (skills now express the pattern so the
  bullet's authority reference is populated).
- **Verification after commit:**
  - `validate-pack.py` Check 2 (TOML parse) passes on updated
    auditor-architecture.toml (V-CI-09).
  - Check 5 (agent-count parity) unchanged (V-CI-10).
  - Trinity-style diff: `diff
    project-template/.claude/agents/auditor-architecture.md
    project-template/.gemini/agents/auditor-architecture.md |
    grep -i capabilit` returns zero (markdown byte-identical for the
    new bullet; file-header differences elsewhere acceptable).
  - V-BD045-05 passes.
- **Gate:** member of Gate A.

#### C-045-04 — Audit-methodology rule 15 back-reference (MANDATORY decision; B1)

- **Trigger for this commit.** V10-DESIGN Part 3 §3.10 and §13.4 defer
  the question "does rule 15 in `audit-methodology/SKILL.md` need a
  capabilities extension?" to Phase 3. This plan **requires** the
  decision be recorded at Gate A. Two possible outcomes; one is
  mandatory.
- **Decision procedure (run before commit):**
  1. Read `project-template/skills/audit-methodology/SKILL.md` rule 15
     verbatim. Record the exact text in the Phase 3 decision log at
     `maintenance-docs/v10-working/phase-3-rule-15-decision.md` (a
     working-docs file; not committed to pack product).
  2. Evaluate against two criteria:
     (i) Does rule 15 reference `auditor-architecture` scope authority
     (an "LSP compliance" or equivalent phrase that establishes what
     that auditor covers)? If yes → **extend**.
     (ii) Does rule 15 read as a general architectural rule not tied
     to the auditor scope list? If yes → **no extension**, but record
     the reasoning.
  3. Commit either the extension or the decision record. Gate A will
     not pass without either outcome.
- **Outcome A — Extension (default expected):**
  - **Message:** `feat: v10 — BD-045 audit-methodology rule 15 capabilities extension`
  - **Files:** `project-template/skills/audit-methodology/SKILL.md`.
  - **Content:** extend rule 15's scope enumeration to include
    "capabilities pattern adherence" alongside "LSP compliance" using
    language parallel to Part 3 §3.7 auditor-architecture bullet.
    LSP remains required; capabilities remains recommended.
- **Outcome B — No extension:**
  - **Message:** `docs: v10 — BD-045 audit-methodology rule 15 decision (no extension)`
  - **Files:** none committed to `project-template/`. A one-file
    annotation committed to `maintenance-docs/v10-working/phase-3-
    rule-15-decision.md` with:
    - Verbatim quote of current rule 15.
    - Specific reasoning for why the v10 auditor scope bullet does
      not need rule 15 changed.
    - A note that if BD-032 (auditor observability refinement) or a
      future BD revisits the auditor scope, this decision should be
      revisited.
  - Even in Outcome B, **a commit happens** — the decision record
    itself is the deliverable. Gate A blocks if no commit landed.
- **Dependencies:** C-045-03 (auditor-architecture bullet is the
  authority-chain endpoint that the decision evaluates).
- **Verification after commit:**
  - If Outcome A: `validate-pack.py` Check 1 on modified SKILL.md.
  - Decision record file exists at the named path with the three
    required fields (quote, reasoning, revisit note).
  - V-BD045-04 and V-BD045-07 still pass.
- **Gate:** member of Gate A — **entry criterion. Gate A cannot pass
  without a decision recorded via C-045-04 Outcome A or Outcome B.**

#### Gate A — End of BD-045

**Entry criteria (all mandatory):**
1. Commits C-045-01..C-045-04 complete on v10-dev.
2. `validate-pack.py` green.
3. Renumbering sweep S6 (§8) returns expected-counts matrix with zero
   stale old-rule-number references.
4. Rule 15 decision record file exists (either C-045-04 Outcome A
   commit modified the SKILL.md, or Outcome B commit recorded the
   decision).
5. V-BD045-01..07 all pass.
6. Trinity diff on capabilities section returns byte-identical.

**Manual checks the developer runs before approving:**
1. `diff project-template/CLAUDE.md project-template/AGENTS.md` — only
   file-header differences outside Capabilities section.
2. Read the rule 15 decision record.
3. Confirm no trinity-rule violation.

**Approve to proceed to Phase 2a or request changes.**

---

### 6.2 Phase 2a — BD-046 prompt reorganization

#### C-046-01 — Create prompts directory and 10 per-agent files + PROMPT-AUTHORING.md

- **Message:** `feat: v10 — BD-046 per-agent prompt files under docs/pack/prompts/`
- **Part 8 rows:** 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22.
- **Source sections:**
  - Part 4 §4.1 (per-template destination map with line ranges).
  - Part 4 §4.2 (file list; placeholder rule for architect.md,
    grpc-schema.md, repo-ops.md).
  - Part 4 §4.3 (PROMPT-AUTHORING.md content spec).
  - Part 4 §4.5 (per-agent file format: YAML frontmatter + H1 +
    optional preamble + `## Variant: <slug>` H2 per variant).
  - Part 4 §4.6 (agent report file convention — REPORT FILE field,
    read-only vs write-capable framing, chunking instruction).
  - **Existing content source:** `supporting-docs/PROMPT-TEMPLATES.md`
    at its current HEAD on v10-dev (equal to v9.3 for this file). If
    v10-dev has unexpectedly modified the file, reset via
    `git show v9.3:supporting-docs/PROMPT-TEMPLATES.md`.
- **Files created (12):**
  - `project-template/docs/pack/prompts/coder.md` (`agent: coder`; variants `standard`, `fix-cycle` from T2+T4)
  - `project-template/docs/pack/prompts/reviewer.md` (`agent: reviewer`; variants `standard` from T3)
  - `project-template/docs/pack/prompts/tester.md` (variants `standard` from T5)
  - `project-template/docs/pack/prompts/planner.md` (variants `standard` from T7)
  - `project-template/docs/pack/prompts/docs-researcher.md` (variants `standard` from T6)
  - `project-template/docs/pack/prompts/architect.md` (variants `mid-phase` from T4b — REASSIGNED from coder per Part 4 §4.2)
  - `project-template/docs/pack/prompts/grpc-schema.md` (placeholder; zero variants)
  - `project-template/docs/pack/prompts/repo-ops.md` (placeholder; zero variants)
  - `project-template/docs/pack/prompts/auditor.md` (variants `standard` from T9; trailing T10–12 supersession note)
  - `project-template/docs/pack/prompts/pm-chat.md` (`agent: pm-chat` reserved; variants `kickoff`, `backlog-status-update`, `generate-setup`, `generate-agent-kickoff` from T1/T8/T13/T14)
  - `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` (Part 4 §4.3 content: How to use, per-agent exceptions table, self-check rule, pointer to METHODOLOGY.md Prompt Authoring Principles)
- **Dependencies:** Phase 1 complete.
- **Verification after commit:**
  - Not yet validated by Check 6 (lands next commit). Manual format
    check: every file starts with `---\n`, has `agent:` + `variants:`
    keys, every slug has a matching `^## Variant: <slug>$` H2.
  - **Token-count sanity (V-PROMPT-01):** `wc -w` summed across the 10
    new files × 1.3 within ±5% of v9.3 monolith's ~6,482 proxy
    tokens, accounting for hoisted Prompt Authoring Principles.
  - **Content-accounting (V-PROMPT-02):** every v9.3 Template 1–14
    present in its mapped file under mapped variant slug; T10–T12
    supersession note present as trailing block in `auditor.md`.
  - **v9.x additions preserved (V-PROMPT-03):** T1 BD-038 active-skills
    instruction in `pm-chat.md ## Variant: kickoff`; T8 STATUS.md
    phase-title rule in `pm-chat.md ## Variant: backlog-status-update`;
    BD-043 Gemini refs preserved throughout.
  - `validate-pack.py` existing checks all green (no agent files
    touched; Check 5 parity unchanged).
  - PROMPT-TEMPLATES.md remains in place (not deleted yet).
- **Gate:** member of Gate B.

#### C-046-02 — validate-pack.py Check 6 (prompts-directory format)

- **Message:** `feat: v10 — BD-046 validate-pack.py Check 6 prompts-directory format`
- **Part 8 rows:** 56.
- **Source sections:** Part 4 §4.5 (format rules); V10-DESIGN §5.11
  bullet 1.
- **Files:** `scripts/validate-pack.py`.
- **Check 6 asserts** for each `project-template/docs/pack/prompts/*.md`
  (excluding `PROMPT-AUTHORING.md`):
  1. File begins with `---\n` YAML frontmatter closed by `---\n`.
  2. Required frontmatter keys: `agent`, `variants`.
  3. Unknown top-level frontmatter keys rejected (except reserved
     `description`, `deprecated-by`, `notes`).
  4. Stem of file matches `agent:` value (except `pm-chat.md` with
     reserved `agent: pm-chat`).
  5. For each slug listed under `variants:`, exactly one `^## Variant:
     <slug>$` H2 exists; no orphan variant H2 not listed in `variants`.
  6. `PROMPT-AUTHORING.md` exists.
- **Dependencies:** C-046-01.
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — Check 6 passes on all 10
    files + PROMPT-AUTHORING.md (V-CI-01).
  - **Local negative test (do NOT commit):** change `agent: reviewer`
    in `coder.md`, expect Check 6 failure naming the file (V-CI-02);
    revert. Change `variants: [foo]` with no matching H2, expect
    failure; revert. Remove `---` opener, expect failure; revert.
- **Gate:** member of Gate B.

#### Gate B — End of Phase 2a

**Entry criteria:**
1. C-046-01..C-046-02 complete.
2. Check 6 passes on all pack prompts.
3. Token-count and template-accounting sanity confirmed.

**Approval check:** developer spot-reads three variant bodies against
v9.3 source lines to confirm no content drift.

**Approve to proceed to Phase 2b.**

---

### 6.3 Phase 2b — BD-046 custom-agent support + stale-reference sweep

PROMPT-TEMPLATES.md is **not** deleted in Phase 2b. Deletion moves to
Phase 3 (C-044-07) after QUICKSTART.md is rewritten.

#### C-046-03 — Trinity: Document-locations row + `### Custom agents` sub-section (TRIO)

- **Message:** `feat: v10 — BD-046 trinity docs/pack row and custom agents sub-section`
- **Part 8 rows:** 26+27+28 (Document-locations row update) +
  39+40+41 (`### Custom agents` sub-section at end of Phase routing).
- **Source sections:** Part 4 §4.8 (stale-reference inventory for
  docs/pack/ row); Part 5 §5.6 (trinity routing-table additions —
  exact sub-section markdown).
- **Files:**
  - `project-template/CLAUDE.md`
  - `project-template/AGENTS.md`
  - `project-template/GEMINI.md`
- **Two edits per file, single commit:**
  1. Replace `docs/pack/PROMPT-TEMPLATES.md` literal with
     `docs/pack/prompts/` directory reference in Document-locations
     table's `docs/pack/` row.
  2. Append `### Custom agents` sub-section at end of Phase routing
     table (content from Part 5 §5.6 verbatim).
- **Dependencies:**
  - Phase 1 (BD-045 capabilities section must be preserved; no edit
    to that region).
  - C-046-01 (`prompts/` directory exists — Document-locations row
    references a real path).
- **Verification after commit:**
  - `validate-pack.py` passes.
  - Trinity diff of new regions byte-identical across three files.
  - `grep -n "PROMPT-TEMPLATES" project-template/{CLAUDE,AGENTS,GEMINI}.md`
    returns zero matches in the Document-locations row.
  - Capabilities section (from Phase 1) still byte-identical across
    three files.
- **Gate:** member of Gate C.

#### C-046-04 — PM-CHAT.md pack roster + custom-agent workflow + capability-addition trigger (combined row 24+38+81)

- **Message:** `feat: v10 — BD-046 PM-CHAT.md pack roster, custom-agent workflow, capability-addition trigger`
- **Part 8 rows:** 24 + 38 + 81 (combined per §8.2.8 "Combine with
  rows 24 and 38" directive).
- **Source sections:**
  - Part 5 §5.3 (pack roster — hardcoded list of 16 v10 pack agent
    stems; placement after `## Role`, before `## Before starting a
    new project`).
  - Part 5 §5.10 (custom-agent workflow section; file-access table
    additions; behavioral rules additions).
  - Part 4 §4.7 (drop PROMPT-TEMPLATES.md from mcp-local-rag
    recommendation).
  - Part 4 §4.6 (agent report file behavioral rule under `##
    Behavioral rules`).
  - **Capability-addition trigger rule** (row 81): add one bullet
    under `## Behavioral rules`: *"If the developer asks to add a
    pack-supported dimension (platform, language, protocol, role),
    direct them to run `scripts/add-capability.sh` from the pack
    first; then run METHODOLOGY.md Procedure 6."* Source: Part 5
    §5.14.1 and §5.14.6.
- **Files:** `project-template/docs/pack/PM-CHAT.md`.
- **Dependencies:** C-046-01 (prompts dir); C-046-03 (trinity
  Document-locations row consistent).
- **Verification after commit:**
  - `validate-pack.py` passes (Check 7 not yet added).
  - `grep -n "PROMPT-TEMPLATES" project-template/docs/pack/PM-CHAT.md`
    returns zero matches.
  - `grep -n "^## Pack agent roster$" project-template/docs/pack/PM-CHAT.md`
    returns exactly one match.
  - Pack roster list contains exactly 16 agent stems matching
    `ls project-template/.claude/agents/*.md` (preview of Check 7).
  - Trigger rule present verbatim.
- **Gate:** member of Gate C.

#### C-046-05 — PLATFORM-SKILLS.md `## Custom agents` + `## Custom skills` sections

- **Message:** `feat: v10 — BD-046 PLATFORM-SKILLS.md custom sections`
- **Part 8 rows:** 42.
- **Source sections:** Part 5 §5.2 (exact markdown for both sections
  + placeholder rows).
- **Files:** `project-template/docs/pack/PLATFORM-SKILLS.md`.
- **Action:** append `## Custom agents` and `## Custom skills` H2
  sections immediately after `## Full skill inventory`, in that
  order. Include placeholder rows per §5.2. The two H2 headings
  serve as positional markers for migration splice (Part 6 §6.6).
- **Dependencies:** C-046-04.
- **Verification after commit:**
  - `validate-pack.py` passes.
  - `grep -cE "^## Custom (agents|skills)$" project-template/docs/pack/PLATFORM-SKILLS.md`
    returns 2.
- **Gate:** member of Gate C.

#### C-046-06 — pm-startup skill drops PROMPT-TEMPLATES.md RAG entry

- **Message:** `feat: v10 — BD-046 pm-startup skill drops PROMPT-TEMPLATES.md RAG entry`
- **Part 8 rows:** 25.
- **Source sections:** Part 4 §4.7 (pm-startup behavior after reorg —
  no prompt-file read; METHODOLOGY.md retained).
- **Files:** `project-template/skills/pm-startup/SKILL.md`.
- **Dependencies:** C-046-01 (prompts dir exists).
- **Verification after commit:**
  - `validate-pack.py` Check 1 passes.
  - `grep -n "PROMPT-TEMPLATES" project-template/skills/pm-startup/SKILL.md`
    returns zero.
  - `grep -n "METHODOLOGY" project-template/skills/pm-startup/SKILL.md`
    still present (retained per §4.7).
- **Gate:** member of Gate C.

#### C-046-07 — project-template/README.md PROMPT-TEMPLATES sweep

- **Message:** `docs: v10 — BD-046 project-template/README.md PROMPT-TEMPLATES sweep` (or skip)
- **Part 8 rows:** 29.
- **Action:**
  1. `grep -n "PROMPT-TEMPLATES" project-template/README.md`.
  2. If matches: replace each with `docs/pack/prompts/` path.
  3. If zero matches: document "no matches — no commit needed" in
     `maintenance-docs/v10-working/phase-3-sweep-log.md` and skip.
- **Dependencies:** none beyond C-046-01.
- **Verification:** post-commit grep returns zero.
- **Gate:** member of Gate C.

#### C-046-08 — METHODOLOGY.md Procedure 5 + Procedure 5-R + PROMPT-TEMPLATES sweep (combined row 30+43+48)

- **Message:** `feat: v10 — BD-046 METHODOLOGY.md Procedure 5 and 5-R`
- **Part 8 rows:** 30 + 43 + 48.
- **Source sections:**
  - Part 5 §5.7 (Procedure 5 outline — sub-procedures 5.1 custom-
    agent creation; 5.2 custom-skill creation; 5.3 unregistered-file
    completion; 5.4 improperly-added adoption; 5.5 detection-scan as
    phase-gate step; 5.6 reference tables).
  - Part 6 §6.5 (Procedure 5-R reconciliation triggered by
    `_v9-backup.md`).
  - Part 4 §4.8 (PROMPT-TEMPLATES.md location references replaced by
    `docs/pack/prompts/<agent>.md`; **"Prompt Authoring Principles"
    section unchanged** — it is already the canonical source).
- **Files:** `supporting-docs/METHODOLOGY.md`.
- **Action:** append Procedure 5 (with 5.1–5.6 sub-procedures) and
  Procedure 5-R to Part 7 of METHODOLOGY.md, immediately after
  Procedure 4. In the same commit, replace any PROMPT-TEMPLATES.md
  location reference with the corresponding
  `docs/pack/prompts/<agent>.md` path or the `docs/pack/prompts/`
  directory. Do **not** touch "Prompt Authoring Principles."
- **Dependencies:** C-046-05 (PLATFORM-SKILLS.md Custom sections);
  C-046-04 (PM-CHAT.md custom-agent workflow).
- **Verification after commit:**
  - `grep -n "PROMPT-TEMPLATES" supporting-docs/METHODOLOGY.md` returns
    zero.
  - `grep -nE "^###? Procedure 5($|[\\. ]|-R)" supporting-docs/METHODOLOGY.md`
    confirms both Procedure 5 (with sub-procedures) and Procedure 5-R
    present.
  - Diff of `## Prompt Authoring Principles` section vs. previous
    HEAD shows no change.
- **Gate:** member of Gate C.

#### C-046-09 — Historical maintenance-docs annotations

- **Message:** `docs: v10 — BD-046 annotate V9 design records with supersession notes`
- **Part 8 rows:** 36, 37.
- **Source sections:** Part 4 §4.8 annotate-only rule; Part 5 §5.13
  (annotate Decision 7 pointer to V10-DESIGN Part 5); V9 Lessons 4, 5.
- **Files:**
  - `maintenance-docs/V9-DESIGN.md` — inline supersession annotations
    beside PROMPT-TEMPLATES.md references; Decision 7 pointer to
    V10-DESIGN Part 5.
  - `maintenance-docs/V9-AUDIT-REPORT.md` (if present) — same
    treatment.
- **Rule:** annotate only; do NOT mutate historical body content
  (V9 Lesson 5).
- **Dependencies:** none beyond C-046-01.
- **Verification:**
  - `validate-pack.py` passes.
  - Diff confirms annotations added; original lines preserved.
- **Gate:** member of Gate C.

#### C-046-10 — supporting-docs sweep (CLI-PM-SETUP, SETUP_TEMPLATE PROMPT-TEMPLATES refs, DEPENDENCIES, MIGRATION-v8-to-v9)

- **Message:** `docs: v10 — BD-046 supporting-docs PROMPT-TEMPLATES sweep`
- **Part 8 rows:** 32, 33 (PROMPT-TEMPLATES refs only; cp-r/QUICKSTART
  Step-N parts deferred to Phase 3 C-044-05 area), 34, 35.
- **Source sections:** Part 4 §4.8; Part 7 §7.13 integration.
- **Scope note.** This commit covers **PROMPT-TEMPLATES references
  only**. The SETUP_TEMPLATE.md `cp -r` replacement and
  QUICKSTART-Step-N number references are Phase-3 work (land with
  C-044-03/04/05 when SETUP-NEW.md and SETUP-EXISTING.md exist as
  replacement targets).
- **Files:**
  - `supporting-docs/CLI-PM-SETUP.md` — replace with
    `docs/pack/prompts/<agent>.md` equivalents.
  - `supporting-docs/SETUP_TEMPLATE.md` — PROMPT-TEMPLATES refs only
    (defer `cp -r` rewrite).
  - `supporting-docs/DEPENDENCIES.md` — sweep only if enumerated.
  - `supporting-docs/MIGRATION-v8-to-v9.md` — historical; optional
    single-line pointer to MIGRATION-v9-to-v10.md (land it after
    C-046-16 creates that guide; acceptable to skip here and do it
    as part of S-02 or a small standalone commit).
- **Dependencies:** C-046-01.
- **Verification:** `grep -rn "PROMPT-TEMPLATES" supporting-docs/`
  returns only `PROMPT-TEMPLATES.md` itself (not yet deleted) +
  `MIGRATION-v8-to-v9.md` historical text. (§8 sweep S1 runs first
  pass here.)
- **Gate:** member of Gate C.

#### C-046-11 — validate-pack.py Checks 7 and 8

- **Message:** `feat: v10 — BD-046 validate-pack.py Checks 7 pack-agent-roster and 8 reserved x- prefix`
- **Part 8 rows:** 57, 58.
- **Source sections:** Part 5 §5.3 (Check 7); Part 5 §5.5 (Check 8);
  Part 5 §5.11.
- **Files:** `scripts/validate-pack.py`.
- **Check 7 asserts:** parse `project-template/docs/pack/PM-CHAT.md`
  `## Pack agent roster` bulleted list; compare to
  `set of basenames(.claude/agents/*.md, .stem)`; fail on any mismatch.
- **Check 8 asserts:** for each of the seven pack scan locations
  (Claude agents, Codex agents, Gemini agents, Claude skills, Codex
  skills, Gemini skills, docs/pack/prompts), zero filenames or
  top-level dir entries begin with `x-`.
- **Dependencies:** C-046-04 (roster exists); C-046-01 (prompts dir
  exists); C-046-05 (PLATFORM-SKILLS.md structure stabilized —
  helpful context though not a hard dep).
- **Verification after commit:**
  - `validate-pack.py` — Checks 7 and 8 pass (V-CI-03, V-CI-05).
  - Local negative (do NOT commit):
    - Temp-add `project-template/docs/pack/prompts/x-test.md` →
      Check 8 fails (V-CI-06). Revert.
    - Add bogus stem to roster → Check 7 fails (V-CI-04). Revert.
- **Gate:** member of Gate C.

#### Gate C — End of Phase 2b

**Entry criteria:**
1. C-046-03..C-046-11 complete.
2. `validate-pack.py` green with Checks 6, 7, 8 active.
3. Sweep S1 (§8) returns only expected residuals:
   `supporting-docs/PROMPT-TEMPLATES.md` (file itself),
   `supporting-docs/MIGRATION-v8-to-v9.md` historical,
   `maintenance-docs/V9-DESIGN.md` / `V9-AUDIT-REPORT.md` annotated,
   `QUICKSTART.md` (deferred to Phase 3 C-044-05).
4. Trinity integrity check: capabilities section + Document-locations
   row + `### Custom agents` sub-section byte-identical across three.
5. METHODOLOGY.md Procedure 5 + Procedure 5-R both present;
   Prompt Authoring Principles section unchanged.

**Approve to proceed to Phase 2c.**

---

### 6.4 Phase 2c — BD-046 migration tooling

The migration script needs `scripts/lib/detect.sh`. `detect.sh` is a
BD-044 artifact but is **built here**, in Phase 2c, so migration
tooling can source it directly and init-project (Phase 3) picks up the
same library unchanged. This ordering avoids a stub-and-rewrite cycle.

#### C-044-01 — scripts/lib/detect.sh shared detection library

- **Message:** `feat: v10 — BD-044 scripts/lib/detect.sh shared detection library`
- **Part 8 rows:** 50, 51.
- **Source sections:** Part 7 §7.2 (function list, each read-only,
  each prints `key: value` structured output).
- **Functions (initial set; V10-DESIGN §7.2 verbatim):**
  - `detect_clean_working_tree` → `working-tree: clean|dirty`
  - `detect_git_repo` → `git-repo: yes|no`
  - `detect_pack_path` → `pack-path: valid|missing|not-a-repo`
  - `detect_pack_version` → `pack-version: v<N.M>`
  - `detect_ai_config` → `ai-config-markers: <comma list>`
  - `detect_x_files` → `x-files: <paths>`
  - `detect_improperly_added_files` → `improperly-added: <paths>`
  - NOTE: `detect_installed_capabilities` is NOT added in this commit
    — it is added in Phase 3-AC C-046-ADD-01 alongside
    `add-capability.sh` (Part 5 §5.14.2 consumer is A2, which does
    not yet exist here).
- **Files:**
  - `scripts/lib/` (new directory).
  - `scripts/lib/detect.sh` (new).
- **Dependencies:** Phase 2b complete (seven scan locations from §5.5
  are fully defined at this point).
- **Verification after commit:**
  - `bash -n scripts/lib/detect.sh` parses cleanly.
  - Smoke test: `source scripts/lib/detect.sh && detect_pack_path &&
    detect_ai_config` prints valid structured lines.
  - `validate-pack.py` passes.
- **Gate:** member of Gate D.

#### C-046-13 — scripts/merge-platform-skills.py

- **Message:** `feat: v10 — BD-046 merge-platform-skills.py helper`
- **Part 8 rows:** 46.
- **Source sections:** Part 6 §6.6 (PLATFORM-SKILLS.md positional
  splice rule — project-owned region begins at first `## Custom
  agents` or `## Custom skills`, EOF).
- **Files:** `scripts/merge-platform-skills.py`.
- **Dependencies:** C-046-05 (PLATFORM-SKILLS.md custom sections
  stabilized in pack template).
- **Verification:**
  - `python3 -m py_compile scripts/merge-platform-skills.py`.
  - Smoke test against a mock v9.3 PLATFORM-SKILLS.md fixture + v10
    template.
- **Gate:** member of Gate D.

#### C-046-14 — scripts/merge-trinity.py (with B6 pre-check)

- **Message:** `feat: v10 — BD-046 merge-trinity.py helper with Active-skills pre-check`
- **Part 8 rows:** 47.
- **Source sections:** Part 6 §6.6 (two splices per trinity file —
  `### Custom agents` sub-section + `**Active skills:**` line).
- **B6 — Active-skills-line pre-check (new in v2).** Before either
  splice runs, the helper must:
  1. Read each of the three trinity files.
  2. For each file, locate the line matching the regex
     `^\*\*Active skills:\*\*\s`.
  3. If the pattern is absent, or appears more than once, **stop**
     with a diagnostic that names the file and the expected pattern.
     Exit non-zero. Do NOT splice.
  4. If the pattern matches once, proceed.
- **Files:** `scripts/merge-trinity.py`.
- **Dependencies:** C-046-03 (trinity `### Custom agents` sub-section
  introduced in pack template).
- **Verification:**
  - `python3 -m py_compile scripts/merge-trinity.py`.
  - Smoke test with valid trinity → both splices succeed; all three
    files updated atomically.
  - Smoke test with trinity missing the Active-skills line → script
    stops with diagnostic; no edits written.
  - Smoke test with trinity having two Active-skills lines → script
    stops with diagnostic.
- **Gate:** member of Gate D.

#### C-046-15 — scripts/migrate-v9-to-v10.sh (with B4 sentinel cleanup)

- **Message:** `feat: v10 — BD-046 migrate-v9-to-v10.sh migration script with sentinel cleanup`
- **Part 8 rows:** 45.
- **Source sections:** Part 6 §6.1 (preservation); §6.3 (S0 pre-flight);
  §6.4 (OQ-3 PROMPT-TEMPLATES diff); §6.6 (splice rules via helpers);
  §6.7 (rollback); §6.8 (eight stages S0–S7 with sentinels); §6.11
  (sources `scripts/lib/detect.sh`).
- **B4 — Sentinel cleanup in S0 (new in v2).** Extend §6.3 S0:
  - After backup-dir creation check, scan
    `.pack-migration-backup/v9.3-to-v10.0/` for any pre-existing
    `stage-S<N>.done` sentinels.
  - If sentinels found: prompt *"Prior migration run detected —
    sentinels: <list>. Resume [r] / Start fresh [f] / Abort [a]?"*
    Default is **Abort**.
  - Resume: leave backup dir and sentinels in place; continue from
    first stage without a sentinel.
  - Start fresh: `rm -rf .pack-migration-backup/`; recreate backup
    dir; begin at S0.
  - Abort: exit 0 without changes.
  - Document the "clean re-run requires deleting
    `.pack-migration-backup/`" behavior in
    `supporting-docs/MIGRATION-v9-to-v10.md` (C-046-16).
- **Files:** `scripts/migrate-v9-to-v10.sh`.
- **Dependencies:** C-044-01 (detect.sh); C-046-13, C-046-14 (merge
  helpers).
- **Verification:**
  - `bash -n` parses cleanly.
  - `chmod +x` applied.
  - Dry-run on Fixture B (Swift profile) → stages S0–S7 all write
    sentinels; `report.md` produced.
  - Sentinel-cleanup test: seed one `stage-S3.done` sentinel in
    fixture, re-run script; script prompts; `r` resumes from S4;
    `f` deletes backup and restarts from S0; `a` exits 0 unchanged.
  - Active-skills pre-check test: corrupt fixture trinity by deleting
    Active-skills line; S5 stops with diagnostic (B6 via
    merge-trinity.py).
  - V-INC-01..09 all pass on fixture.
- **Gate:** member of Gate D.

#### C-046-16 — supporting-docs/MIGRATION-v9-to-v10.md guide

- **Message:** `docs: v10 — BD-046 MIGRATION-v9-to-v10.md migration guide`
- **Part 8 rows:** 44.
- **Source sections:** Part 6 §6.9 (15-section outline); §6.7 rollback
  verbatim; §6.9 paste-ready automatable prompt.
- **Files:** `supporting-docs/MIGRATION-v9-to-v10.md`.
- **v2 addition (B4):** §14 Troubleshooting now includes a subsection
  *"Clean re-run of migration — deleting `.pack-migration-backup/`
  first"* that names the sentinel-cleanup prompt and when to choose
  each answer.
- **Dependencies:** C-046-15.
- **Verification:**
  - Every script command copy-pasted from the guide matches the
    script's interface.
  - Rollback block verbatim from §6.7.
  - Automatable prompt verbatim from §6.9.
  - `validate-pack.py` passes.
- **Gate:** member of Gate D.

#### Gate D — End of Phase 2c

**Entry criteria:**
1. C-044-01, C-046-13..16 complete.
2. `validate-pack.py` passes.
3. V-M1-01 passes against Fixture B (Swift profile).
4. V-M1-ROLLBACK passes against Fixture B.
5. V-X-PRESERVE-01 passes on Fixture B seeded with `x-` files.
6. merge-trinity.py B6 pre-check confirmed via corrupt-trinity
   negative test.
7. Sentinel-cleanup flow confirmed via seeded-sentinel negative test.

**Approve to proceed to Phase 3.**

---

### 6.5 Phase 3 — BD-044 init-project.sh + router + SETUP guides + README layout + Check 9 + PROMPT-TEMPLATES.md deletion

#### C-044-02 — scripts/init-project.sh

- **Message:** `feat: v10 — BD-044 init-project.sh with detection and preview-and-confirm`
- **Part 8 rows:** 49.
- **Source sections:** Part 7 §7.3 (five project classes), §7.4 (AI
  config stop condition — exit 20), §7.5 (preview-and-confirm flow —
  default No), §7.6 (11 stages S0–S10; skip-list at S7; conditional
  removal at S9), §7.7 (per-stage assertions + blast-radius sweep;
  exit codes 10/11/12/20/21–30/31/40/99), §7.8 (skill-gap detection +
  end-of-run prompt), §6.11 (sources `scripts/lib/detect.sh`).
- **Files:** `scripts/init-project.sh`.
- **Dependencies:** C-044-01 (detect.sh); Phase 2a–2b complete
  (docs/pack/prompts/ + trinity template finalized).
- **Verification:**
  - `bash -n` parses cleanly; `chmod +x` applied.
  - Run V-INIT-NEW-01 against fresh-git-init fixture.
  - Run V-INIT-EXIST-07 against fixture with `.claude/` → exit 20, no
    files written.
  - Blast-radius sweep on installed project: `grep -rn
    PROMPT-TEMPLATES` zero.
- **Gate:** member of Gate E.

#### C-044-03 — supporting-docs/SETUP-NEW.md

- **Message:** `docs: v10 — BD-044 SETUP-NEW.md new-project guide`
- **Part 8 rows:** 52.
- **Source sections:** Part 7 §7.10 (section list, ~300–400 lines).
- **Files:** `supporting-docs/SETUP-NEW.md`.
- **Action:** lift from current `QUICKSTART.md` §§1–12; replace manual
  `cp -r` with `init-project.sh` invocation; update any
  PROMPT-TEMPLATES refs to `docs/pack/prompts/pm-chat.md` variants.
- **Dependencies:** C-044-02 (init-project.sh); C-046-01 (prompts
  variants exist).
- **Verification:**
  - Every script command in the guide matches the actual
    init-project.sh interface.
  - Every prompt-variant reference exists in pack (cross-check
    against `docs/pack/prompts/*.md` frontmatter).
- **Gate:** member of Gate E.

#### C-044-04 — supporting-docs/SETUP-EXISTING.md

- **Message:** `docs: v10 — BD-044 SETUP-EXISTING.md existing-project guide`
- **Part 8 rows:** 53.
- **Source sections:** Part 7 §7.11 (section list, ~200–250 lines;
  preview walk-through; existing-docs pointer; skill-gap follow-up).
- **Files:** `supporting-docs/SETUP-EXISTING.md`.
- **Dependencies:** C-044-02, C-044-03.
- **Verification:** run V-INIT-EXIST-01 by following the guide
  verbatim against a fixture.
- **Gate:** member of Gate E.

#### C-044-05 — QUICKSTART.md rewrite (three-path router) + SETUP_TEMPLATE cp-r fix

- **Message:** `feat: v10 — BD-044 QUICKSTART.md three-path router and SETUP_TEMPLATE rewrite`
- **Part 8 rows:** 54 (QUICKSTART.md) + 33 (SETUP_TEMPLATE.md cp-r
  rewrite — rest of row 33 scope).
- **Source sections:** Part 7 §7.9 (QUICKSTART.md full content
  verbatim — ~30 lines); §7.12 (migration-guide naming convention).
- **Files:**
  - `QUICKSTART.md` (top-level; full rewrite).
  - `supporting-docs/SETUP_TEMPLATE.md` (replace `cp -r
    project-template/…` block with `bash "$PACK/scripts/init-project.sh"`;
    rewrite `QUICKSTART.md Step N` references to corresponding
    SETUP-NEW.md section names).
- **Dependencies:** C-044-03 + C-044-04 (SETUP-NEW / SETUP-EXISTING
  exist for links); C-046-16 (MIGRATION-v9-to-v10.md exists).
- **Verification:**
  - `grep -n "PROMPT-TEMPLATES" QUICKSTART.md` zero.
  - Sweeps S2 (`QUICKSTART.md Step N`) and S3 (`cp -r
    project-template`) run; expected zero matches in operational docs.
  - Every link resolves.
  - Line count ≤ 40.
- **Gate:** member of Gate E.

#### C-044-06 — top-level README.md Repository Layout baseline

- **Message:** `docs: v10 — BD-044 README.md repository layout for v10`
- **Part 8 rows:** 55 (layout only; version-table row is ship-time
  commit S-02).
- **Source sections:** Part 7 §7.12 (migration-guide naming convention
  authoritative note); Part 8 §8.2 (new files).
- **Files:** `README.md` (top-level).
- **Action — Repository Layout updates:**
  - Add `scripts/lib/` and `scripts/lib/detect.sh`.
  - Add `scripts/init-project.sh`, `scripts/migrate-v9-to-v10.sh`,
    `scripts/merge-platform-skills.py`, `scripts/merge-trinity.py`.
  - Add `supporting-docs/SETUP-NEW.md`, `SETUP-EXISTING.md`,
    `MIGRATION-v9-to-v10.md`.
  - Add `project-template/docs/pack/prompts/` + `PROMPT-AUTHORING.md`
    entries.
  - Remove `supporting-docs/PROMPT-TEMPLATES.md` entry (deleted next
    commit).
  - Append note under `supporting-docs/`: *"Migration guides follow
    the naming convention `MIGRATION-vN-to-vM.md`. They always live
    in `supporting-docs/` and ship with the major version that
    introduces the destination pack version."*
  - **Do NOT yet add `scripts/add-capability.sh`** — that entry lands
    in C-046-ADD-03 (Phase 3-AC), which shares this README region.
- **Dependencies:** C-044-02..05.
- **Verification:**
  - `validate-pack.py` Check 4 still passes (version table unchanged).
  - Every file named in layout actually exists.
- **Gate:** member of Gate E.

#### C-044-07 — Delete supporting-docs/PROMPT-TEMPLATES.md

- **Message:** `feat: v10 — BD-046 delete supporting-docs/PROMPT-TEMPLATES.md`
- **Part 8 rows:** 23.
- **Pre-deletion mandatory sweep (S1 full-scope):**
  ```bash
  grep -rn "PROMPT-TEMPLATES" \
      project-template/ supporting-docs/ \
      maintenance-docs/ \
      QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md \
      CLAUDE.md AGENTS.md GEMINI.md
  ```
  **Expected matches** (any other = regression, fix in same commit):
  - `supporting-docs/PROMPT-TEMPLATES.md` — the file itself (about to
    be deleted; excluded by `-v`).
  - `supporting-docs/MIGRATION-v8-to-v9.md` — historical, acceptable.
  - `maintenance-docs/V9-DESIGN.md`, `V9-AUDIT-REPORT.md` — annotated
    in C-046-09.
  - `maintenance-docs/V10-DESIGN.md` — design doc, acceptable.
  - Nothing else.
- **Action:** `git rm supporting-docs/PROMPT-TEMPLATES.md`.
- **Dependencies:** C-044-05 (QUICKSTART no longer references it);
  C-044-06 (README layout no longer lists it).
- **Verification:** `ls supporting-docs/PROMPT-TEMPLATES.md` exits
  non-zero; `validate-pack.py` passes.
- **Gate:** member of Gate E.

#### C-044-08 — validate-pack.py Check 9 (BD-044 structure)

- **Message:** `feat: v10 — BD-044 validate-pack.py Check 9 init-project structure`
- **Part 8 rows:** 59.
- **Source sections:** Part 7 §7.13; Part 5 §5.11.
- **Check 9 asserts:**
  1. `scripts/init-project.sh` exists and is executable.
  2. `scripts/lib/detect.sh` exists and sourceable; grep confirms
     required function names from Part 7 §7.2.
  3. `QUICKSTART.md` (top-level), `supporting-docs/SETUP-NEW.md`,
     `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md` all exist.
  4. `README.md` Repository Layout mentions `scripts/lib/` and the
     migration-guide naming convention note.
- **Files:** `scripts/validate-pack.py`.
- **Dependencies:** C-044-02..07.
- **Verification:**
  - `validate-pack.py` Check 9 passes (V-CI-07).
  - Local negative (do NOT commit): rename each of the four required
    files in turn → Check 9 names the missing file; restore.
- **Gate:** member of Gate E.

#### CI-workflow confirmation (no commit expected)

- **Part 8 row:** 61.
- **Action:** inspect `.github/workflows/validate-pack.yml` — confirm
  it invokes `python3 scripts/validate-pack.py` and thus picks up
  Checks 6/7/8/9 with no workflow change. If (unexpected) the
  workflow splits invocations, commit a small update:
  `docs: v10 — BD-044 validate-pack workflow reaffirm`.
- **Gate:** member of Gate E.

#### Gate E — End of Phase 3 BD-044 core

**Entry criteria:**
1. C-044-02..08 complete.
2. All nine `validate-pack.py` checks active and passing.
3. PROMPT-TEMPLATES.md deleted.
4. Repository Layout reflects v10 file structure.
5. Sweeps S1 (post-C-044-07), S2 (post-C-044-05), S3 (post-C-044-05)
   clean with expected results.
6. Part 10 CP tests V-INIT-NEW-01..05, V-INIT-EXIST-01..07 pass.
7. V-INIT-VERIFY-01..10 and V-INIT-FAIL-01..04 pass.

**Approve to proceed to Phase 3-AC (capability addition).**

---

### 6.6 Phase 3-AC — BD-046 capability-addition mechanism (NEW in v2)

Three commits, appended to Phase 3 per V10-DESIGN §12.5. All
dependencies on earlier commits are satisfied by the end of Phase 3:
`detect.sh` exists (C-044-01), `migrate-v9-to-v10.sh` shares it
(C-046-15), METHODOLOGY.md Procedure 5 is in place (C-046-08), PM-
CHAT.md has the trigger-rule bullet (C-046-04 — already added per
combined row 24+38+81), and the README layout baseline exists
(C-044-06).

#### C-046-ADD-01 — scripts/add-capability.sh + detect.sh extension

- **Message:** `feat: v10 — BD-046 add-capability.sh + detect.sh extension`
- **Part 8 rows:** 78 (new script), 79 (detect.sh extension).
- **Source sections:**
  - Part 5 §5.14.1 (trigger + `$PACK` resolution).
  - Part 5 §5.14.2 (stages A0–A7 with post-stage assertions;
    A0 pack-version warning; A1 degenerate-case; A2 already-active
    exit).
  - Part 5 §5.14.3 (end-of-run PM chat prompt written to stdout AND
    `.pack-add-capability-prompt.md`; file gitignored by A6).
  - Part 5 §5.14.4 (artifact table).
  - Part 5 §5.14.5 (approval gates A4, G6-drafts, G6-commit — A4 is
    script-owned).
  - Part 5 §5.14.6 (zero-token dormancy).
  - Part 5 §5.14.7 (integration — inverts §7.6 conditional-file
    table; sources `scripts/lib/detect.sh`).
  - Part 7 §7.2 (extended with `detect_installed_capabilities()`;
    reads Active skills line from trinity; reports dimension values).
  - AD-15 (placement: pack repo `scripts/`, sibling to init and
    migrate).
  - AD-17 (atomic-token grammar — `platform:ios`, `language:python`,
    `protocol:grpc`, `role:python-server`, etc.; multiple `--add`
    flags; PLATFORM-SKILLS.md dimension resolution).
- **Files:**
  - `scripts/add-capability.sh` (new; ~8 stages A0–A7).
  - `scripts/lib/detect.sh` (extension — add
    `detect_installed_capabilities()` function; reads Active skills
    line from trinity; prints `capabilities: <dim>:<val>,…` list).
- **Script interface (AD-17):**
  ```bash
  bash "$PACK/scripts/add-capability.sh" --project . \
      --add language:python \
      --add protocol:grpc
  ```
  - Flags: `--project <path>` (required), `--add <dim>:<val>` (one or
    more), `--pack <path>` (optional override for `$PACK`).
  - Exit codes: 0 success / developer declined / already-active /
    degenerate no-op; non-zero on pre-flight failure, unrecognized
    dimension/value, missing `$PACK`, dirty working tree.
- **Dependencies:**
  - C-044-01 (`scripts/lib/detect.sh` base).
  - C-046-15 (`migrate-v9-to-v10.sh` shares detect.sh — proves the
    shared-library pattern works).
  - C-046-08 (Procedure 5 exists — Procedure 6 will follow in next
    commit but the script's end-of-run prompt names Procedure 6).
  - The §7.6 conditional-file table must be stable (satisfied by
    C-044-02 init-project.sh landing the table).
- **Verification:**
  - `bash -n scripts/add-capability.sh` parses.
  - `chmod +x` applied.
  - Source detect.sh; call `detect_installed_capabilities` on
    Fixture A — expect structured output listing the fixture's
    active dimensions (`capabilities: platform:macos, language:swift`
    or similar).
  - Run script on Fixture A with `--add language:python
    --add protocol:grpc`:
    - A0 passes (clean tree; pack valid).
    - A1 resolves both; skill-delta non-empty.
    - A2 computes union; reports deltas.
    - A3 prints preview; no writes.
    - A4 prompts `[y/N]`; `n` exits 0 no changes (V-ADDCAP-06).
    - `y` → A5 copies conditional files (pyproject.toml,
      pyrightconfig.json, server/, Python scripts, proto/, proto
      scripts); A6 merges `.gitignore`; A7 writes prompt to stdout
      AND `.pack-add-capability-prompt.md`.
  - V-ADDCAP-01/02/03/03b/04/05/06/07/08 run.
  - V-ADDCAP-13 (already-active exit) on Fixture A where Python is
    already active.
  - V-ADDCAP-14 (multi-dimension atomic).
  - V-ADDCAP-07 (dirty tree) — seed untracked file, expect A0 stop.
  - V-ADDCAP-08 (missing `$PACK`) — unset env, expect A0 stop.
  - `validate-pack.py` passes (no new check; existing Check 9
    already covers scripts/ directory).
- **Gate:** member of Gate E2.

#### C-046-ADD-02 — METHODOLOGY.md Procedure 6 (capability-addition companion to add-capability.sh)

- **Message:** `feat: v10 — BD-046 METHODOLOGY.md Procedure 6 for capability addition`
- **Part 8 rows:** 80 (combines with 43+48 already landed in
  C-046-08).
- **Source sections:**
  - Part 5 §5.7 Procedure 6 outline (steps 6.1–6.6 with gates
    G6-drafts and G6-commit).
  - Part 5 §5.14 (mechanism detail — trigger, script interaction,
    artifacts created or modified, zero-token dormancy).
  - AD-16 (placement: Part 7 of METHODOLOGY.md, immediately after
    Procedure 5-R).
- **Files:** `supporting-docs/METHODOLOGY.md`.
- **Action:** append Procedure 6 to Part 7, after Procedure 5-R.
  Content per §5.7 Procedure 6.1–6.6:
  - 6.1 — read `.pack-add-capability-prompt.md` (or pasted prompt).
  - 6.2 — read newly-activated SKILL.md files; extract content for
    placeholder fills.
  - 6.3 — draft trinity updates (Active skills line + placeholder
    fills); present TRIO for approval (G6-drafts).
  - 6.4 — (informational) PLATFORM-SKILLS.md dimension row check.
  - 6.5 — run Procedure 5.5 detection scan; verify no `x-` touches;
    verify PLATFORM-SKILLS.md project-owned regions unchanged.
  - 6.6 — `git add`, commit (G6-commit).
- **v1-to-v2 note:** PM-CHAT.md trigger rule (row 81) was already
  landed in C-046-04 per the combined rows 24+38+81 directive in §8.2.8.
  No duplicate PM-CHAT.md edit here. Procedure 6 lands in a separate
  commit from Procedures 5/5-R (C-046-08) because add-capability.sh
  must exist first — V10-DESIGN §12.5 explicitly permits this split
  and names the dependency as the reason for separate placement.
- **Dependencies:** C-046-ADD-01 (script exists; Procedure 6
  references it); C-046-08 (Procedure 5 exists; 6 is its sibling).
- **Verification:**
  - `validate-pack.py` passes.
  - `grep -nE "^###? Procedure 6($|[\\. ])" supporting-docs/METHODOLOGY.md`
    confirms present.
  - `grep -n "^### Procedure 5\\." supporting-docs/METHODOLOGY.md`
    still present (Procedure 5 untouched).
  - Cross-check: Procedure 6 step 6.5 references Procedure 5.5;
    Procedure 5.5 exists in METHODOLOGY.md from C-046-08.
  - V-ADDCAP-09..12 exercise PM-chat Procedure 6 behavior against
    Fixture A.
- **Gate:** member of Gate E2.

#### C-046-ADD-03 — README.md layout entry for add-capability.sh

- **Message:** `docs: v10 — BD-046 README.md layout entry for add-capability.sh`
- **Part 8 rows:** 82.
- **Source sections:** AD-15 (sibling placement in `scripts/`); Part
  5 §5.14.
- **Files:** `README.md` (top-level).
- **Action:** add one line to the Repository Layout section under
  `scripts/`, beneath `scripts/migrate-v9-to-v10.sh`:
  `└── add-capability.sh            Add a pack-supported capability to an existing project`
- **Dependencies:** C-044-06 (README layout baseline from BD-044);
  C-046-ADD-01 (script exists).
- **Verification:**
  - `validate-pack.py` passes.
  - `grep -n "add-capability.sh" README.md` returns at least one
    match in Repository Layout section.
  - Layout still matches actual repo (file exists).
- **Gate:** member of Gate E2.

#### Gate E2 — End of Phase 3-AC

**Entry criteria:**
1. C-046-ADD-01..03 complete.
2. `validate-pack.py` green.
3. `scripts/add-capability.sh` passes parse and smoke tests.
4. V-ADDCAP-01/02/03/03b/04..16 all pass on Fixture A (some exercise PM-chat
   behavior — acceptable to verify via PM chat transcripts in
   Phase 4).
5. V-ADDCAP-15 trigger-rule firing confirmed manually against a PM
   chat session (developer says "add Python"; PM chat redirects to
   `add-capability.sh` per PM-CHAT.md trigger bullet).
6. README layout contains `add-capability.sh` line.
7. Procedure 6 present in METHODOLOGY.md; Procedure 5 and 5-R still
   present.

**Approve to proceed to Phase 4.**

---

### 6.7 Phase 4 — Full verification pass

No new feature commits. Only `fix:` commits if Gate E2 verification
surfaced regressions. Phase 4 formalizes the global pre-ship audit.

#### Activities

1. **All six stale-reference sweeps (B7 mandatory at Gate F).**
   Detailed in §8 below. Each must return expected results.
2. **Trinity integrity audit** (V10-DESIGN §8.5). For each of six
   section rows, diff the three trinity files. No divergence except
   Codex auditor-architecture formatting.
3. **detect.sh unit tests (B5).** Build a small test harness at
   `maintenance-docs/v10-working/fixtures/test-detect.sh` that runs
   each function against known inputs:
   - `detect_clean_working_tree`: test with clean fixture (expect
     `working-tree: clean`) and with fixture where `touch x` is run
     (expect `working-tree: dirty`).
   - `detect_git_repo`: test inside fixture (yes), inside
     `$TMPDIR/empty` (no).
   - `detect_pack_path`: valid `$PACK`, missing `$PACK`, non-git
     `$PACK`.
   - `detect_pack_version`: on v9.3 worktree (expect v9.3), on
     v10-dev worktree (expect v10.0-dev or similar).
   - `detect_ai_config`: on Fixture A (expect list containing
     `.claude,.codex,.gemini,CLAUDE.md,AGENTS.md,GEMINI.md`); on
     Fixture B (same); on fresh git init (expect empty list).
   - `detect_x_files`: Fixture A without `--with-x-files` (expect
     empty); Fixture A with seeds (expect 4+ paths).
   - `detect_improperly_added_files`: seed
     `.claude/agents/weirdagent.md` (non-`x-`, non-roster) — expect
     reported; remove, expect empty.
   - `detect_installed_capabilities` (Phase 3-AC): on Fixture A with
     macOS/Swift Active-skills line — expect `capabilities:
     platform:macos, language:swift` (or equivalent resolved against
     PLATFORM-SKILLS.md).
   - Every function's expected output is recorded in `test-detect.sh`
     comments for future regression reference.
4. **Part 10 CP test battery (full pass):**
   - V-CI-01..10 (CI tests).
   - V-M1-01..15 (migration matrix — CP cells only).
   - V-M1-ROLLBACK.
   - V-M1-CUSTOM-01..03.
   - V-INIT-NEW-01..05, V-INIT-EXIST-01..07.
   - V-INIT-VERIFY-01..10, V-INIT-FAIL-01..04.
   - V-PM5-01..10 (PM chat workflow).
   - V-PROMPT-01..05.
   - V-X-PRESERVE-01..03.
   - V-BD045-01..07.
   - V-BLAST-01..06.
   - V-INC-01..09.
   - V-ADDCAP-01/02/03/03b/04..16.
5. **Deferred-item smoke tests** (V10-DESIGN Part 13):
   - §13.1 Codex skill loading with `x-` prefix — smoke test against
     Fixture A with seeded `x-brokerage-api` skill; launch Codex CLI;
     confirm skill loads. If not, add tool-specific footnote to
     Part 5 §5.1 row 4 and update Procedure 5.2 (`docs:` commit on
     v10-dev).
   - §13.3 Claude Code `.claude/agents/*.md` live reload — smoke
     test: add dummy `x-test.md`, confirm Claude detects without
     restart. If restart required, update Part 5 §5.8 user-facing
     message (`docs:` commit on v10-dev).
6. **BACKLOG.md review.** Confirm BD-044/045/046 remain Unblocked
   (become Resolved at Phase 5 ship commit S-03).
7. **Optional: OT project migration dry-run.** If schedule permits,
   run MIGRATION-v9-to-v10.md against a copy of the OT project; no
   commit; confirm incremental assertions pass. Mandatory in Phase 6
   regardless.

#### Gate F — End of Phase 4 (MANDATORY full sweep per B7)

**Entry criteria (all mandatory; no shortcuts):**
1. All Part 10 CP tests green.
2. **All six §8.6 sweeps** (S1–S6, detailed in §8) produce expected
   results. This is the B7 hard requirement: intermediate gates run
   targeted sweeps; **Gate F runs the full six and every sweep's
   expected-result line must match**.
3. Trinity integrity audit clean across all six section rows.
4. `detect.sh` unit-test harness passes all eight function tests.
5. Deferred-item smoke tests resolved (either passing on v10-dev or
   with landed `docs:` fixes).
6. No open `fix:` work.

**Approval check:** developer signs off that the pack is ship-ready.

---

### 6.8 Phase 5 — Ship v10.0

Three ship commits in strict order, then merge, then tags.

#### S-01 — CHANGELOG.md v10.0 entry

- **Message:** `docs: v10 — CHANGELOG.md v10.0 entry`
- **Part 8 rows:** 66.
- **Action:** add v10.0 section summarizing:
  - BD-045 capabilities pattern in trinity + 3 skills + auditor
    trio + (if extended) rule 15.
  - BD-046 (a) custom agent/skill support; (b) prompt reorg (new
    directory `docs/pack/prompts/`, 10 per-agent files +
    PROMPT-AUTHORING.md); (c) migration v9.3 → v10.0 with migrate-
    v9-to-v10.sh + merge helpers + MIGRATION-v9-to-v10.md; (d)
    capability addition via add-capability.sh + Procedure 6.
  - BD-044 init-project.sh + QUICKSTART router + SETUP-NEW +
    SETUP-EXISTING + migration-guide naming convention.
  - validate-pack.py Checks 6/7/8/9 added.
  - Deleted: supporting-docs/PROMPT-TEMPLATES.md.
- **Files:** `CHANGELOG.md`.
- **Verification:** `validate-pack.py` passes.

#### S-02 — README.md v10.0 version-table row + V10-PREDESIGN banner

- **Message:** `docs: v10 — README v10.0 version table; V10-PREDESIGN supersession`
- **Part 8 rows:** 63 (V10-PREDESIGN banner), 65 (version table row).
  (Row 62 V10-DESIGN.md already APPROVED — no edit needed.)
- **Action:**
  - Add `| v10.0 | <ship date> | BD-045 capabilities pattern; BD-046
    custom agent/skill support + prompt reorg + migration + capability
    addition; BD-044 init-project.sh + QUICKSTART router |` row.
  - Add supersession banner to `maintenance-docs/V10-PREDESIGN.md`
    pointing at `V10-DESIGN.md`; body retained.
- **Files:** `README.md`, `maintenance-docs/V10-PREDESIGN.md`.
- **Verification:** `validate-pack.py` Check 4 tolerates dev-branch
  (v10.0 tag not yet created).

#### S-03 — BACKLOG.md resolve BD-044/045/046 + BD-046 4th bullet (AD-18)

- **Message:** `docs: v10 — BACKLOG BD-044 / BD-045 / BD-046 Resolved at v10.0`
- **Part 8 rows:** 64, 83.
- **Action:**
  - Set Status: Resolved on BD-044, BD-045, BD-046 with ship date and
    pointer to `v10.0` tag.
  - Add row-83 bullet to BD-046 description: *"(d) adding
    pack-supported capabilities to existing projects (mechanism:
    `scripts/add-capability.sh` + METHODOLOGY.md Procedure 6)."*
    Per AD-18, no new BD-NNN is opened.
- **Files:** `BACKLOG.md`.
- **Verification:** `validate-pack.py` Check 3 (no TD-TBD) passes.

#### Merge to main + tags

```bash
# Pre-flight (from main worktree)
cd /Users/david/Developer/dhs-ai-agent-config-pack
git fetch origin
git checkout main
git pull --ff-only

# Confirm v10-dev is ready (run from v10-dev worktree)
cd ../v10-dev
python3 scripts/validate-pack.py          # must pass
git log --oneline -30                     # sanity

# Merge from main worktree
cd /Users/david/Developer/dhs-ai-agent-config-pack
git merge --no-ff v10-dev -m "Merge v10-dev into main — v10.0"

# Tags
git tag -a v10.0 -m "v10.0"
# Floating major tag — delete old, recreate, push per CLAUDE.md
git tag -d v10 2>/dev/null || true
git push origin :refs/tags/v10 2>/dev/null || true
git tag v10 v10.0

# Push
git push origin main
git push origin v10.0
git push origin v10

# Retire the worktree (optional; post-merge)
git worktree remove ../v10-dev
# Or keep it for v10.x patch work
```

#### Ship approval gate

Developer explicitly says "ship v10.0." Only then do merge + tag +
push run.

---

### 6.9 Phase 6 — Post-ship

1. **OT project migration.** Run `supporting-docs/MIGRATION-v9-to-v10.md`
   against OT project (v9.3 baseline) using pack at `v10.0` tag.
   Verify every V-INC-* assertion green. Any regression opens a BD
   for v10.1.
2. **Deferred-item follow-through:**

   | V10-DESIGN § | Item | Resolution target | Status at ship |
   |---|---|---|---|
   | §13.1 | Codex skill loading with `x-` prefix | Gate F smoke test | Resolved on v10-dev or `docs:` fix commit |
   | §13.2 | Gemini CLI Hooks verification | Future v10.x if needed | Not v10.0 scope |
   | §13.3 | Claude Code `.claude/agents/*.md` live reload | Gate F smoke test | Resolved on v10-dev or `docs:` fix commit |
   | §13.4 | audit-methodology rule 15 back-reference | Gate A (C-045-04) | Resolved via Outcome A or B |
   | §13.6 | pack-version banner formalization | Future v10.x minor | Not v10.0 scope |
3. **v10.x planning.** Open BD numbers for any Phase 4 or OT
   migration regressions.

---

## 7. Mandatory decision points

### 7.1 Rule 15 decision at Gate A (B1)

See §6.1 C-045-04. Entry criterion for Gate A. No advance without
either:
- A commit extending rule 15 (Outcome A, default expected), or
- A commit adding `maintenance-docs/v10-working/phase-3-rule-15-
  decision.md` with verbatim quote, reasoning, and revisit note
  (Outcome B).

A "TBD" or deferred status is not acceptable at Gate A. This is the
B1 hard rule.

### 7.2 Sentinel cleanup decision at migration S0 (B4)

See §6.4 C-046-15. S0 prompts the developer when prior sentinels
exist: `r` resume / `f` start fresh / `a` abort (default).
`MIGRATION-v9-to-v10.md` §14 documents the prompt. "Start fresh"
deletes `.pack-migration-backup/` in full.

### 7.3 Active-skills pattern check at S5 (B6)

See §6.4 C-046-14. `merge-trinity.py` verifies the `**Active skills:**`
line matches the expected regex before splicing. Mismatch stops with
diagnostic; developer must fix or choose to skip splice before S5
re-runs.

---

## 8. Stale-reference sweep schedule

All six sweeps from V10-DESIGN §8.6. Targeted sweeps run at
intermediate gates; **Gate F runs all six** per B7. Each sweep's
expected result is listed; any deviation is a commit-blocker at the
gate listed.

### 8.1 Sweep schedule table

| # | Sweep | Target gate (run locations) | Expected result |
|---|---|---|---|
| S1 | `grep -rn "PROMPT-TEMPLATES" project-template/ supporting-docs/ maintenance-docs/ QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md CLAUDE.md AGENTS.md GEMINI.md` | C-046-10 (Gate C); C-044-05 (Gate E); C-044-07 (Gate E); **Gate F mandatory full pass** | After C-046-10: matches in PROMPT-TEMPLATES.md itself, MIGRATION-v8-to-v9.md historical, V9-DESIGN/V9-AUDIT-REPORT annotated, QUICKSTART.md (to be rewritten). After C-044-05: QUICKSTART.md zero. After C-044-07: **only** MIGRATION-v8-to-v9.md (historical) + V9-DESIGN.md / V9-AUDIT-REPORT.md (annotated) + V10-DESIGN.md (design record). Gate F: identical set — no new matches introduced. |
| S2 | `grep -rnE "QUICKSTART\\.md\\s+Step\\s+[0-9]+" project-template/ supporting-docs/ maintenance-docs/` | C-044-05 (Gate E); **Gate F mandatory** | After C-044-05: zero in `supporting-docs/` and `project-template/`. `maintenance-docs/` historical refs acceptable — annotate if unclear. Gate F: same expectation. |
| S3 | `grep -rnE "cp\\s+-r\\s+.*project-template" supporting-docs/ maintenance-docs/` | C-046-10 (first pass — operational docs); C-044-05 (SETUP_TEMPLATE rewrite); **Gate F mandatory** | After C-044-05: zero in `supporting-docs/`. `maintenance-docs/` historical acceptable. Gate F: same. |
| S4 | `grep -rnE "\\[agents\\.(x_\|x-)" project-template/ supporting-docs/ maintenance-docs/` | C-046-04 (Gate C); **Gate F mandatory** | Zero matches — no per-agent `[agents.x_*]` or `[agents.x-*]` entries exist or are documented per V10-DESIGN §5.4. Gate F: same. |
| S5 | `ls project-template/.claude/agents/ project-template/.codex/agents/ project-template/.gemini/agents/ project-template/skills/ project-template/.claude/skills/ project-template/.codex/skills/ project-template/.gemini/skills/ project-template/docs/pack/prompts/ 2>/dev/null \| grep "^x-"` | Every BD-046 commit (S5-local); post C-046-11 automated by Check 8; **Gate F mandatory** | Zero `x-` entries. Asserted by Check 8. Gate F: confirms Check 8 still zero. |
| S6 | **B3 — rigorous renumbering sweep.** See §8.2 below. | C-045-02 (Gate A); **Gate F mandatory** | See §8.2 expected-counts matrix. |

### 8.2 Sweep S6 — Rigorous renumbering expected counts (B3)

Three skills are renumbered in C-045-02:
- `apple-architecture-core/SKILL.md`: new rules 11–14 inserted; old
  rules 11–23 shift to 15–27.
- `python-best-practices/SKILL.md`: new rules 14–17 inserted; old
  rules 14–32 shift to 18–36.
- `architecture-review/SKILL.md`: new rules 14–17 inserted; old
  rules 14–15 shift to 18–19.

The sweep covers three dimensions:

**Dimension 1 — In-file rule counts (each skill):**

| File | Regex | Expected count post-C-045-02 |
|---|---|---|
| `apple-architecture-core/SKILL.md` | `^1[1-4]\\. ` (lines starting with 11.–14.) | 4 (the new Capabilities section rules) |
| `apple-architecture-core/SKILL.md` | `^(1[5-9]\|2[0-7])\\. ` | 13 (renumbered old 11–23 content) |
| `apple-architecture-core/SKILL.md` | `^(10\|11\|12\|13\|14)\\. ` with body text matching old rule content | Each old rule's text present at new number (4 fresh + 13 shifted) |
| `python-best-practices/SKILL.md` | `^1[4-7]\\. ` | 4 (new Capabilities section) |
| `python-best-practices/SKILL.md` | `^(1[8-9]\|2[0-9]\|3[0-6])\\. ` | 19 (old rules 14–32 renumbered) |
| `architecture-review/SKILL.md` | `^1[4-7]\\. ` | 4 (new Capabilities section) |
| `architecture-review/SKILL.md` | `^(18\|19)\\. ` | 2 (old rules 14–15 renumbered) |

**Dimension 2 — Cross-file specific references to old rule numbers
(must return zero after C-045-02):**

```bash
# Apple: old rules 11–23 shift to new 15–27. Any cross-file reference
# to old rule numbers 11–23 in apple-architecture-core context must be
# updated to the new number (+4). Regex covers the FULL old range.
grep -rnE "apple-architecture-core.*(rule|rules)\\s+(1[1-9]|2[0-3])\\b" \
    project-template/ supporting-docs/ maintenance-docs/
# Expected: zero matches pointing at old content. If matches exist,
# evaluate whether the referent is the pre-v10 content (now at +4) or
# the new Capabilities section rules (11–14). Update accordingly.

# Python: old rules 14–32 shift to new 18–36. Full old range covered.
grep -rnE "python-best-practices.*(rule|rules)\\s+(1[4-9]|2[0-9]|3[0-2])\\b" \
    project-template/ supporting-docs/ maintenance-docs/
# Expected: zero.

# Architecture-review: old 14–15 referenced
grep -rnE "architecture-review.*(rule|rules)\\s+(1[4-5])\\b" \
    project-template/ supporting-docs/ maintenance-docs/
# Expected: zero.
```

**Dimension 3 — Range references (`rules N–M`) and colloquial refs
(`per rule N`, `following rule N`):**

```bash
# Range references across all three skills' scope
grep -rnE "rules?\\s+[0-9]+\\s*[–-]\\s*[0-9]+" \
    project-template/skills/apple-architecture-core/ \
    project-template/skills/python-best-practices/ \
    project-template/skills/architecture-review/ \
    project-template/ supporting-docs/ maintenance-docs/
# Every match must be evaluated against the renumber table. If a
# range like "rules 11–14" referred to pre-v10 apple content, it now
# points at the Capabilities section — the reference must be updated
# to "rules 15–18" or otherwise corrected.

# Specific "per rule N" / "following rule N" / "see rule N" refs
grep -rnE "(per|following|see|under)\\s+rule\\s+[0-9]+" \
    project-template/ supporting-docs/ maintenance-docs/
# Each match examined manually against which skill it references.
```

**Decision rule.** If any Dimension-2 or Dimension-3 match is found
that refers to **old content at its old number**, the fix is made in
the same commit (C-045-02) before Gate A is approved. Gate A does
not pass until every match is cleared.

**Full scope enforcement.** The sweep scope is
`project-template/ supporting-docs/ maintenance-docs/` — **not just
`project-template/`**. Historical maintenance-docs references (e.g.,
V9-DESIGN.md quoting old rule numbers) are acceptable **only** if
they are historical records of v9 state; they must not be modified
but may be annotated if they cause reader confusion.

### 8.3 Additional per-commit local sweeps

Each commit's "Verification" block already names targeted greps. The
six sweeps above are the cross-commit guarantees.

---

## 9. validate-pack.py sequencing

Each new check lands in or immediately after the commit that produces
its target content. No check references files that do not yet exist.

| Check | Added in commit | Target content available after | Rationale |
|---|---|---|---|
| 6 — prompts-dir format | C-046-02 | C-046-01 (10 prompt files + PROMPT-AUTHORING.md) | Content in C-046-01, validator in C-046-02 (next commit) so CI passes at C-046-01 and hardens at C-046-02 |
| 7 — pack-agent-roster | C-046-11 | C-046-04 (PM-CHAT.md `## Pack agent roster`) | After roster section stabilized |
| 8 — reserved `x-` prefix | C-046-11 | always (pack ships zero `x-`) | Lands with Check 7 — both guard custom-agent mechanism |
| 9 — BD-044 structure | C-044-08 | C-044-02..07 | Last — every assertion target has shipped |
| 1 re-verify | C-045-02 (manual in-commit run) | Renumbered skills | No code change; confirm Check 1 still passes |
| 5 re-verify | C-045-03 (manual in-commit run) | Updated auditor-architecture trio | No code change; confirm parity |

Between commits, CI runs the older check set; every intermediate CI
run is green. Check 9 does **not** require add-capability.sh to
exist — it asserts BD-044 deliverables only. `add-capability.sh`
self-validates via stage post-assertions (V10-DESIGN §5.14.2) — no
new validate-pack.py check needed (§8.2.8 "No new check required").

---

## 10. Approval gates — summary

| Gate | After phase | Blocker criteria before developer approves |
|---|---|---|
| Pre-work | Worktree setup | `../v10-dev/` worktree created and pinned to `v10-dev` branch; push complete |
| **A** | Phase 1 (BD-045) | BD-045 trinity + skills + auditor trio edits done; **rule 15 decision recorded (B1 mandatory)**; renumbering sweep S6 rigorous expected counts match; `validate-pack.py` green; V-BD045-01..07 pass |
| **B** | Phase 2a (prompt reorg) | 10 prompt files + PROMPT-AUTHORING.md present; Check 6 active+green; token count ±5%; template accounting complete |
| **C** | Phase 2b (custom-agent + sweeps) | All trinity BD-046 edits combined; PM-CHAT pack roster + trigger rule; METHODOLOGY Procedure 5 + 5-R + sweep; Checks 7+8 green; Sweep S1 residuals only QUICKSTART (deferred) + historical + monolith itself |
| **D** | Phase 2c (migration) | detect.sh + merge helpers + migrate-v9-to-v10.sh + guide land; V-M1-01 + V-M1-ROLLBACK + V-X-PRESERVE-01 pass on Fixture B; merge-trinity.py B6 pre-check negative test passes; sentinel-cleanup flow B4 negative test passes |
| **E** | Phase 3 (BD-044) | init-project.sh + SETUP guides + QUICKSTART router + README layout baseline + Check 9; PROMPT-TEMPLATES.md deleted; V-INIT-NEW/EXIST CP tests pass; sweeps S1/S2/S3 clean |
| **E2** | Phase 3-AC (capability addition) | add-capability.sh + detect.sh extension + Procedure 6 + README line present; V-ADDCAP-01/02/03/03b/04..16 pass on Fixture A; V-ADDCAP-15 trigger-rule manual check passes |
| **F** | Phase 4 (verification) | **All six sweeps S1–S6 mandatory (B7)** returning expected results; trinity integrity audit clean; detect.sh unit tests (B5) pass all eight functions; full Part 10 CP test battery green; deferred-item smoke tests resolved |
| **Ship** | Phase 5 (ship) | CHANGELOG + version table + V10-PREDESIGN banner + BACKLOG resolution (including BD-046 4th bullet per AD-18); validate-pack.py green; developer explicit approval |

Each gate is a hard **stop**. No commit in the next phase begins
until the developer explicitly approves.

---

## 11. New-file content-source map

For every new file the implementer creates, the authoritative
V10-DESIGN source + any additional input file needed.

| New file | Part 8 row | V10-DESIGN source | Additional input |
|---|---|---|---|
| `project-template/docs/pack/prompts/coder.md` | 12 | Part 4 §4.1 (T2+T4 ranges) + §4.5 + §4.6 | `supporting-docs/PROMPT-TEMPLATES.md` lines 131–209 (T2) + 293–375 (T4) |
| `project-template/docs/pack/prompts/reviewer.md` | 13 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 211–291 (T3) |
| `project-template/docs/pack/prompts/tester.md` | 14 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 424–451 (T5) |
| `project-template/docs/pack/prompts/planner.md` | 15 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 488–511 (T7) |
| `project-template/docs/pack/prompts/docs-researcher.md` | 16 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 453–486 (T6) |
| `project-template/docs/pack/prompts/architect.md` | 17 | Part 4 §4.2 + §4.5 | PROMPT-TEMPLATES.md lines 377–422 (T4b reassigned) |
| `project-template/docs/pack/prompts/grpc-schema.md` | 18 | §4.2 zero-variant placeholder + §4.5 | none |
| `project-template/docs/pack/prompts/repo-ops.md` | 19 | §4.2 zero-variant placeholder + §4.5 | none |
| `project-template/docs/pack/prompts/auditor.md` | 20 | §4.5 + §4.6; T10–12 supersession note | PROMPT-TEMPLATES.md lines 572–632 (T9) + 634–653 (T10–12 note) |
| `project-template/docs/pack/prompts/pm-chat.md` | 21 | §4.5 + §4.6; four variants | PROMPT-TEMPLATES.md 79–129 (T1) + 515–570 (T8) + 655–678 (T13) + 680–738 (T14) |
| `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` | 22 | Part 4 §4.3 | PROMPT-TEMPLATES.md lines 7–17 (How to use) + 48–58 (exceptions) + 61–76 (self-check) |
| `scripts/lib/detect.sh` | 51 | Part 7 §7.2 (function list); §5.14.2 extension in Phase 3-AC | none |
| `scripts/init-project.sh` | 49 | Part 7 §§7.3, 7.4, 7.5, 7.6, 7.7, 7.8 | sources `detect.sh` |
| `scripts/migrate-v9-to-v10.sh` | 45 | Part 6 §§6.1, 6.3, 6.4, 6.6, 6.7, 6.8, 6.11; B4 sentinel cleanup | sources `detect.sh`; invokes merge helpers |
| `scripts/add-capability.sh` | 78 | Part 5 §5.14.1..5.14.7; AD-15, AD-17 | sources `detect.sh` |
| `scripts/merge-platform-skills.py` | 46 | Part 6 §6.6 PLATFORM-SKILLS rule | none |
| `scripts/merge-trinity.py` | 47 | Part 6 §6.6 trinity splice; B6 pre-check | none |
| `supporting-docs/MIGRATION-v9-to-v10.md` | 44 | Part 6 §6.9 outline + §6.7 rollback + §6.9 auto-prompt; B4 sentinel section in §14 | none |
| `supporting-docs/SETUP-NEW.md` | 52 | Part 7 §7.10 | current `QUICKSTART.md` §§1–12 as lift source |
| `supporting-docs/SETUP-EXISTING.md` | 53 | Part 7 §7.11 | none |
| `QUICKSTART.md` (rewrite) | 54 | Part 7 §7.9 verbatim | none |
| `CHANGELOG.md` v10.0 entry | 66 | summary of Phase 1–3-AC outputs | none |

New validator-check implementations (`scripts/validate-pack.py`):
- Check 6 — Part 4 §4.5.
- Check 7 — Part 5 §5.3.
- Check 8 — Part 5 §5.5.
- Check 9 — Part 7 §7.13.

---

## 12. Cross-BD coordination checkpoints

From V10-DESIGN Part 12 §12.2 and Part 8 §8.4 "Combine with…" rows.
Each coordination point maps to a single commit or an explicit ordered
set.

| Coordination point | V10-DESIGN rule | Plan realization |
|---|---|---|
| Trinity files — Capabilities pattern + Document-locations row + `### Custom agents` | BD-045 first, BD-046 layered; trinity rule never half-present | C-045-01 (BD-045 section) + C-046-03 (BD-046 Document-locations + Custom agents sub-section, TRIO) |
| METHODOLOGY.md — Procedure 5 + Procedure 5-R + PROMPT-TEMPLATES sweep | Combined rows 30+43+48 in one commit | C-046-08 |
| METHODOLOGY.md — Procedure 6 addition | Procedure 6 joins Procedures 5 and 5-R; row 80 | C-046-ADD-02 (separate from C-046-08 because the script exists only after C-046-ADD-01; Procedure 6 references the script's end-of-run prompt) |
| QUICKSTART.md rewrite + PROMPT-TEMPLATES drop | rows 31+54 | C-044-05 |
| PM-CHAT.md — PROMPT-TEMPLATES sweep + pack roster + custom-agent workflow + capability-addition trigger | rows 24+38+81 combined | C-046-04 |
| README.md — Repository Layout baseline | row 55 (BD-044); row 82 (add-capability.sh line) split; row 65 (version-table row) at ship | C-044-06 (baseline) + C-046-ADD-03 (add-capability line) + S-02 (version row) |
| validate-pack.py — Checks 6/7/8 (BD-046) + Check 9 (BD-044) | 6 in BD-046 2a batch; 7+8 in BD-046 2b; 9 in BD-044 | C-046-02, C-046-11, C-044-08 |
| BACKLOG.md — BD-046 4th bullet (AD-18) | combined with BD resolutions at ship | S-03 |

Trinity-rule integrity audit (V10-DESIGN §8.5) runs across all six
section rows at Gate F; any asymmetry caught before ship.

---

## 13. Risks, unknowns, and mitigations

| # | Risk | Trigger | Mitigation |
|---|---|---|---|
| R1 | Trinity-rule violation during BD-046 layering | One trinity file edited, others forgotten | C-046-03 is a single TRIO commit; Gate F §8.5 audit; Check 7 roster cross-reads one trinity and compares |
| R2 | Stale PROMPT-TEMPLATES references outside inventory | Sweep S1 finds unexpected match | S1 runs at C-046-10, C-044-05, C-044-07, and Gate F; any unexpected match blocks advancement and is fixed in the same phase |
| R3 | validate-pack.py check added before target content exists | Wrong commit sequencing | §9 sequencing table; each check lands in/after its target commit |
| R4 | BD-045 renumbering leaves stale cross-references | Sweep S6 finds matches | §8.2 rigorous expected-counts matrix; three dimensions (in-file, cross-file specific, range+colloquial); full scope `project-template/ supporting-docs/ maintenance-docs/`; all fixed in C-045-02 before Gate A |
| R5 | Migration script order bug — detect.sh not yet present | migrate-v9-to-v10.sh committed before detect.sh | Plan places C-044-01 (detect.sh) before C-046-13/14/15 within Phase 2c |
| R6 | Historical docs mutated in sweep | Overzealous sweep replacing annotated content | Annotate-only rule for maintenance-docs; C-046-09 + C-046-10 explicitly annotate, not rewrite |
| R7 | OT project divergent PROMPT-TEMPLATES.md → Procedure 5-R misses | PM chat behavior not exercised | V-M1-CUSTOM-03 in Phase 4; fix is either METHODOLOGY.md wording or `fix:` commit |
| R8 | Codex TOML parse failure after auditor-architecture edit | Malformed triple-quoted string | Check 2 catches (V-CI-09); Part 3 §3.7 formatting example is the source of truth |
| R9 | init-project.sh copies prompts/ before PROMPT-AUTHORING.md rename stable | Wrong ordering | Phase 3 runs after Phase 2a complete; C-044-02 sources files stabilized in C-046-01 |
| R10 | README.md version row added before v10.0 tag → Check 4 warns | CI Check 4 dev-branch tolerance | validate-pack.py §138–184 tolerates "dev" branch; S-02 ships row while still on v10-dev, tag follows |
| R11 | Rule 15 decision skipped | C-045-04 Outcome B happens without decision record | B1 mandatory at Gate A; Gate A entry criterion requires decision file at `maintenance-docs/v10-working/phase-3-rule-15-decision.md`; no bypass |
| R12 | CI workflow file not re-reviewed after new checks | Passive assumption | Gate E explicit confirmation step in §6.5 |
| R13 | OT migration reveals regression | Fixture differs from real project | Rollback per Part 6 §6.7; regression → BD-NNN for v10.1 |
| R14 | Migration re-run with stale sentinels corrupts state | Developer re-runs after interrupted migration without cleanup | B4 sentinel-cleanup prompt at S0; MIGRATION-v9-to-v10.md §14 documents |
| R15 | merge-trinity.py silently splices on malformed Active skills line | No pre-check | B6 Active-skills pre-check added in C-046-14; corrupt-trinity negative test at Gate D |
| R16 | add-capability.sh misreads PLATFORM-SKILLS.md dimension tables | Row-label format change | AD-17 atomic-token grammar insulates from row-label variation; V-ADDCAP-05 "unrecognized dimension" test catches parse failures |
| R17 | Capability addition on a project with hand-edited Active skills line | Non-standard content in the line | detect_installed_capabilities() (C-046-ADD-01) must tolerate (and ignore) unrecognized skill names in the Active skills list; it reports only the recognized dimension:value pairs |
| R18 | Worktree confusion — commits land on main instead of v10-dev | Developer runs from wrong working directory | Every §6 commit section names the worktree (`cd ../v10-dev`); Gate-local `git branch --show-current` check recommended before commit |
| R19 | Phase 3-AC commits land before BD-044 gate passed | Interleaved work | Explicit sequencing: Gate E must pass before C-046-ADD-01 begins; E is a hard gate |
| R20 | Test fixtures exercise wrong pack version | `$PACK` points at main, not v10-dev worktree | Fixture scripts in §5 explicitly set `PACK` to the v10-dev worktree path during Phase 4 verification; pack-checked-out-to-`v10.0`-tag for Phase 6 OT migration |

---

## 14. Open unknowns (developer approval required before next phase)

1. **Exact content of `supporting-docs/PROMPT-TEMPLATES.md` at v9.3
   tag.** Implementer uses the current HEAD on v10-dev (should equal
   v9.3 content for this file since v10-dev has made no
   PROMPT-TEMPLATES.md edits before Phase 2a). Ground truth: `git
   show v9.3:supporting-docs/PROMPT-TEMPLATES.md`.
2. **Roster order for Check 7.** Part 5 §5.3 shows a canonical
   format; alphabetical. Implementer follows §5.3 exactly.
3. **Codex TOML format for auditor-architecture capabilities
   bullet.** Part 3 §3.7 — plain-bullet inside
   `developer_instructions = """…"""`. Implementer confirms
   triple-quoted string accepts insertion without re-parsing adjacent
   strings (Check 2 validates).
4. **Rule 15 decision (§7.1 above).** Must be recorded before Gate A.
5. **OT project location and current state.** Phase 6 assumes OT is
   on v9.3; implementer confirms before Phase 4 ends.
6. **Fixture script lifecycle.** §5.3 keeps fixture scripts in
   `maintenance-docs/v10-working/fixtures/` during Phase 4. Post-
   v10.0 disposition (promote to `scripts/` as regression
   infrastructure, or archive) is a Phase 6 decision.

Each unknown is either resolved inline in the triggering commit or
becomes a `fix:` commit on v10-dev before the next gate.

---

## 15. Summary — ready-to-execute commit list

Total new commits on v10-dev: **~31** (plus conditional C-045-04
Outcome A or B, plus any `fix:` commits in Phase 4, plus 3 ship
commits).

| # | ID | Phase | Gate | Message |
|---|---|---|---|---|
| 1 | C-045-01 | 1 | A | feat: v10 — BD-045 capabilities pattern in trinity files |
| 2 | C-045-02 | 1 | A | feat: v10 — BD-045 capabilities rules in apple / python / architecture-review skills |
| 3 | C-045-03 | 1 | A | feat: v10 — BD-045 capabilities scope in auditor-architecture (trio) |
| 4 | C-045-04 | 1 | A | (Outcome A) feat: v10 — BD-045 audit-methodology rule 15 capabilities extension **or** (Outcome B) docs: v10 — BD-045 audit-methodology rule 15 decision (no extension) |
| 5 | C-046-01 | 2a | B | feat: v10 — BD-046 per-agent prompt files under docs/pack/prompts/ |
| 6 | C-046-02 | 2a | B | feat: v10 — BD-046 validate-pack.py Check 6 prompts-directory format |
| 7 | C-046-03 | 2b | C | feat: v10 — BD-046 trinity docs/pack row and custom agents sub-section |
| 8 | C-046-04 | 2b | C | feat: v10 — BD-046 PM-CHAT.md pack roster, custom-agent workflow, capability-addition trigger |
| 9 | C-046-05 | 2b | C | feat: v10 — BD-046 PLATFORM-SKILLS.md custom sections |
| 10 | C-046-06 | 2b | C | feat: v10 — BD-046 pm-startup skill drops PROMPT-TEMPLATES.md RAG entry |
| 11 | C-046-07 | 2b | C | docs: v10 — BD-046 project-template/README.md PROMPT-TEMPLATES sweep (skip if no matches) |
| 12 | C-046-08 | 2b | C | feat: v10 — BD-046 METHODOLOGY.md Procedure 5 and 5-R |
| 13 | C-046-09 | 2b | C | docs: v10 — BD-046 annotate V9 design records with supersession notes |
| 14 | C-046-10 | 2b | C | docs: v10 — BD-046 supporting-docs PROMPT-TEMPLATES sweep |
| 15 | C-046-11 | 2b | C | feat: v10 — BD-046 validate-pack.py Checks 7 pack roster and 8 reserved x- prefix |
| 16 | C-044-01 | 2c | D | feat: v10 — BD-044 scripts/lib/detect.sh shared detection library |
| 17 | C-046-13 | 2c | D | feat: v10 — BD-046 merge-platform-skills.py helper |
| 18 | C-046-14 | 2c | D | feat: v10 — BD-046 merge-trinity.py helper with Active-skills pre-check |
| 19 | C-046-15 | 2c | D | feat: v10 — BD-046 migrate-v9-to-v10.sh migration script with sentinel cleanup |
| 20 | C-046-16 | 2c | D | docs: v10 — BD-046 MIGRATION-v9-to-v10.md migration guide |
| 21 | C-044-02 | 3 | E | feat: v10 — BD-044 init-project.sh with detection and preview-and-confirm |
| 22 | C-044-03 | 3 | E | docs: v10 — BD-044 SETUP-NEW.md new-project guide |
| 23 | C-044-04 | 3 | E | docs: v10 — BD-044 SETUP-EXISTING.md existing-project guide |
| 24 | C-044-05 | 3 | E | feat: v10 — BD-044 QUICKSTART.md three-path router and SETUP_TEMPLATE rewrite |
| 25 | C-044-06 | 3 | E | docs: v10 — BD-044 README.md repository layout for v10 |
| 26 | C-044-07 | 3 | E | feat: v10 — BD-046 delete supporting-docs/PROMPT-TEMPLATES.md |
| 27 | C-044-08 | 3 | E | feat: v10 — BD-044 validate-pack.py Check 9 init-project structure |
| 28 | C-046-ADD-01 | 3-AC | E2 | feat: v10 — BD-046 add-capability.sh + detect.sh extension |
| 29 | C-046-ADD-02 | 3-AC | E2 | feat: v10 — BD-046 METHODOLOGY.md Procedure 6 for capability addition |
| 30 | C-046-ADD-03 | 3-AC | E2 | docs: v10 — BD-046 README.md layout entry for add-capability.sh |
| — | (`fix:` commits from any gate) | 3/4 | F | fix: <description> |
| 31 | S-01 | 5 | Ship | docs: v10 — CHANGELOG.md v10.0 entry |
| 32 | S-02 | 5 | Ship | docs: v10 — README v10.0 version table; V10-PREDESIGN supersession |
| 33 | S-03 | 5 | Ship | docs: v10 — BACKLOG BD-044 / BD-045 / BD-046 Resolved at v10.0 (includes AD-18 4th bullet) |

After S-03: from `main` worktree merge `v10-dev --no-ff`, tag
`v10.0`, move `v10` floating tag, push all. Remove `../v10-dev/`
worktree if desired.

---

## 16. Scope completeness check

Before Phase 1 begins, the implementer confirms every V10-DESIGN
Part 8 §8.2 row is covered by this plan.

| Part 8 section | Row range | Plan coverage |
|---|---|---|
| §8.2.1 BD-045 capabilities | 1–10 | C-045-01 (1–3), C-045-02 (4–6), C-045-03 (7–9); row 10 is a design artifact (template), applied in future language-skill additions |
| §8.2.2 Prompt reorg new + remove | 11–23 | C-046-01 (11–22), C-044-07 (23 — deletion) |
| §8.2.2 Stale-reference sweep | 24–37 | C-046-04 (24+38+81), C-046-06 (25), C-046-03 (26–28), C-046-07 (29), C-046-08 (30+43+48), C-044-05 (31+54+33 cp-r), C-046-10 (32, 34, 35), C-046-09 (36, 37) |
| §8.2.3 Custom agent/skill support | 38–43 | C-046-04 (38), C-046-03 (39–41), C-046-05 (42), C-046-08 (43) |
| §8.2.4 Migration | 44–48 | C-046-16 (44), C-046-15 (45), C-046-13 (46), C-046-14 (47), C-046-08 (48) |
| §8.2.5 BD-044 | 49–55 | C-044-02 (49), C-044-01 (50, 51), C-044-03 (52), C-044-04 (53), C-044-05 (54), C-044-06 (55) |
| §8.2.6 validate-pack.py + CI | 56–61 | C-046-02 (56), C-046-11 (57, 58), C-044-08 (59), C-045-02/03 (60 re-verify), Gate-E review (61) |
| §8.2.7 Version bookkeeping | 62–66 | V10-DESIGN already APPROVED (62); S-02 (63, 65); S-03 (64); S-01 (66) |
| §8.2.8 Capability addition | 78–84 | C-046-ADD-01 (78, 79), C-046-ADD-02 (80), C-046-04 (81 — combined earlier), C-046-ADD-03 (82), S-03 (83 — AD-18 BACKLOG extension); row 84 runtime artifact (`.pack-add-capability-prompt.md`) — validated by V-ADDCAP-01 |
| §8.3 Runtime-produced | 67–77 | Not pack-repo commits; validated by Part 10 tests |

**Every row from 1 to 84 has a home.** Gate-E2 is the last gate
before the verification pass that checks this table.

---

## 17. BD-item coverage confirmation

| BD | Scope elements | Plan section |
|---|---|---|
| **BD-045** | Trinity capabilities section (3 files) | C-045-01 |
|  | apple-architecture-core rules 11–14 | C-045-02 |
|  | python-best-practices rules 14–17 | C-045-02 |
|  | architecture-review rules 14–17 | C-045-02 |
|  | auditor-architecture scope bullet (3 files) | C-045-03 |
|  | audit-methodology rule 15 decision (B1) | C-045-04 |
|  | Language placeholder template (§3.5) | Design artifact — applied at future skill addition; not a v10 commit |
| **BD-046** | Prompt reorg (10 files + PROMPT-AUTHORING.md) | C-046-01 |
|  | PROMPT-TEMPLATES.md deletion + sweep | C-046-04..10, C-044-07 |
|  | Custom agent mechanism (trinity, PM-CHAT, PLATFORM-SKILLS) | C-046-03, C-046-04, C-046-05 |
|  | METHODOLOGY.md Procedure 5 + 5-R | C-046-08 |
|  | Migration tooling (detect.sh, merge helpers, migrate script, guide) | C-044-01 + C-046-13/14/15/16 |
|  | validate-pack.py Checks 6/7/8 | C-046-02, C-046-11 |
|  | **(d) Capability addition** (AD-14..AD-18) | C-046-ADD-01/02/03; PM-CHAT trigger in C-046-04 |
| **BD-044** | init-project.sh + detect.sh dependency | C-044-01, C-044-02 |
|  | SETUP-NEW.md / SETUP-EXISTING.md | C-044-03, C-044-04 |
|  | QUICKSTART.md three-path router | C-044-05 |
|  | README.md Repository Layout baseline | C-044-06 |
|  | validate-pack.py Check 9 | C-044-08 |

**Every BD-item scope element appears in at least one plan commit.**

---

*End of Phase 3 Implementation Plan v2.*

*Supersedes `phase-3-implementation-plan.md` (v1). This plan + V10-
DESIGN.md are the sole references needed to execute v10.0.*
