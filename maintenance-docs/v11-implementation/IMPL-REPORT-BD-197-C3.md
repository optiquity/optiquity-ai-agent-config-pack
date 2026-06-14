# IMPL-REPORT — BD-197 C3 (P3 pack-side RW/RO two-class model + Guard-B)

**Role:** pack-coder (fresh). **Mode:** in-place (regime detected: working tree
is the parent checkout, not a `worktree-agent-*` worktree — no `isolation`
param was passed; report written to the parent-tree path per the calling
prompt). **Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:**
`v11-dev`. **Commit:** C3 (`pack-only`; touches NO client surface).
**HEAD (start + end, unchanged — agent ran NO state-changing git verb):**
`f6ee0882d6288150cb9394cdb5d666ae3ce695b3`. **Date:** 2026-06-14.

C3 establishes the PACK-SIDE agent read-write/read-only (RW/RO) two-class
model: the SSOT (PACK-AGENTS `Class` column) + per-agent-file prose
reinforcement (15 files) + a CI guard (Guard-B = Check 52) keeping them
consistent, plus the run-before-wire per-check test. PROJECT-side RW/RO (C6)
was NOT touched.

---

## Read attestation (read IN FULL before any edit; no skim, no derivation)

I READ each of the following IN FULL, directly (not derived), before editing:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
  — read all 878 lines across two page reads (1–376, 377–752+). The
  load-bearing sections for C3: §4.3 (RW/RO classification + triple
  reinforcement, pack) and §13.2 (Guard-B design: set-equality; bind to the
  PROSE mandate header, NEVER `tools:`). Also §0/§3/§4.1/§5/§14 for context.
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md`
  — read §A (commit sequence), §B "C3" (lines 90–96), §C (green-per-commit),
  §D (verify-full-ci-suite + run-before-wire), §E (measure-then-bound guard
  steps incl. Guard-B 5-step), §F (Empirical-Evidence Blocks EE-1..EE-9), §G
  (manifest regen flags — C3 expected-empty), §H (enumerate-encoding-surfaces),
  §I (coder spawn map + rules-in-force for C3), §J/§K.
- `maintenance-docs/v11-implementation/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`
  — read all 343 lines. The authoritative RW/RO classification: pack = 1 RW
  (`pack-coder`) + 4 RO (`pack-architect`/`pack-planner`/`pack-reviewer`/
  `pack-docs-researcher`); §1.1 + the explicit note that `pack-reviewer`
  carries `Write, Edit` yet is RO (the exact reason Guard-B binds to the prose
  header, not `tools:`).
- `pack-ops/PACK-AGENTS.md` — read all 224 lines (the roster `## Pack agents`
  table with the `Mode` column at line 13; the `## Agent permission rules`
  section I extended).
- `scripts/validate-pack.py` — read the structural pieces I needed: the
  `ok`/`fail`/`warn` helpers (403–425), `REPO_ROOT`/imports (289–299), the
  `run_check` runtime-budget harness + budget constants (427–481), the
  self-skip convention (`entry.name == "validate-pack.py"`, 2169), Check 51
  (the canonical recent guard, 7993–8221), Check 42 (the yml-wiring enforcer +
  its `test-validate-pack-check*.sh` glob, 6679–6771), and the `main()`
  registration block (8225+). Confirmed highest existing Check = 51.
- `CLAUDE.md` § "## Pack memory" — read in full (the project-instructions
  block governing all pack agents, incl. `ci-guard-design-measure-then-bound`,
  `ci-check-runtime-compounding`, `enumerate-encoding-surfaces`,
  `verify-full-ci-suite`, `cross-cli-reference-normalization`,
  `edit-in-place-not-full-rewrite`, `regenerate-manifest-v11-surface`,
  `agents-never-commit`, `preflight-stop-means-stop`).
- Curated memory files, each read IN FULL:
  `feedback_ci_guard_design_measure_then_bound.md`,
  `feedback_ci_check_runtime_compounding.md`,
  `feedback_verify_full_ci_suite.md`,
  `feedback_manifest_regen_on_v11_surface.md`.

Also read for execution accuracy: the project agent files
(`project-template/.claude/agents/coder.md` opening / mandate-header
convention) to confirm the project header is `**Write-capable (scoped).**` /
`**Read-only.**` — DISTINCT from the pack design's `**Source-write within
scope.**` / `**Read-only.**`, so I used the pack design's exact pack wording
(separation-of-concerns; I did NOT import the project header text).

---

## Pre-flight (empirical)

- `git rev-parse HEAD` → `f6ee0882d6288150cb9394cdb5d666ae3ce695b3`;
  `git status` → clean working tree, branch `v11-dev` (start state).
- `ls .claude/agents .codex/agents .gemini/agents` → 5 pack agents per CLI
  (`pack-architect`, `pack-coder`, `pack-docs-researcher`, `pack-planner`,
  `pack-reviewer`) = 15 files. Confirms the measured set.
- Highest existing `Check NN` in validate-pack.py = **51** → new check = **52**.
- `python3 scripts/validate-pack.py` baseline → exit `0`, "PASSED — all checks
  clean" (no pre-existing red to fight).
- Battery validate-pack invocation count (live):
  `grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk '{s+=$2} END{print s}'`
  → **191** (plan §F EE-1 measured 186 at an earlier HEAD `ae3d932`; live at
  this HEAD = 191 — the runtime-compounding budget is judged against 191).
- Pre-existing prose mandate headers in pack agent files: **none**
  (`grep -rn 'Source-write within scope\|^\*\*Read-only\.\*\*\|Write-capable'
  .claude/agents .codex/agents .gemini/agents` → empty) → the 15 headers are
  net-new.

---

## Task 1 — PACK-AGENTS.md: `Class` column (SSOT) + "## Two agent classes"

`pack-ops/PACK-AGENTS.md`, two targeted in-place edits.

### 1a. Roster `Class` column (the SSOT)

BEFORE (the roster header + rows):

```
| Agent | Role | Mode |
|---|---|---|
| `pack-architect` | Architecture and design decisions — ... | Read-only |
| `pack-planner` | Implementation planning — ... | Read-only |
| `pack-coder` | Implementation execution — ... | Source-write within scope; **never** stages or commits |
| `pack-reviewer` | Change review — ... | Read-only |
| `pack-docs-researcher` | CLI tool documentation verification — ... | Read-only |
```

AFTER (added a `Class` column between `Agent` and `Role`):

```
| Agent | Class | Role | Mode |
|---|---|---|---|
| `pack-architect` | RO | Architecture and design decisions — ... | Read-only |
| `pack-planner` | RO | Implementation planning — ... | Read-only |
| `pack-coder` | RW | Implementation execution — ... | Source-write within scope; **never** stages or commits |
| `pack-reviewer` | RO | Change review — ... | Read-only |
| `pack-docs-researcher` | RO | CLI tool documentation verification — ... | Read-only |
```

Plus a short paragraph under the table naming the `Class` column the pack-side
SSOT and pointing to Check 52 (set-equality; binds to prose header, never
`tools:`). Classification = 1 RW (`pack-coder`) + 4 RO — matches RESEARCH §1.1.

### 1b. "### Two agent classes" subsection

Added under `## Agent permission rules`, immediately after the "Source-write
scope is the per-agent `Mode`" paragraph, before the "pack-chat-only files"
block. Full added text (design §4.3 pack):

- Opens with the load-bearing framing: the platform provides NO safety net
  for subagents, so RW agents MUST be spawned isolated and the class is what
  makes that enforceable.
- **RW — `pack-coder`:** writes/edits source within caller scope; emits patch
  + report; NEVER a state-changing git verb; isolated ⇒ patch to `/tmp`
  handoff dir.
- **RO — `pack-architect`/`pack-planner`/`pack-reviewer`/`pack-docs-researcher`:**
  write ONLY their one caller report; read-only otherwise; explicitly notes
  `pack-reviewer` carries `Write, Edit` yet is RO and the class is keyed off
  the prose header NEVER `tools:`.
- Both classes obey `agents-never-commit` + the destructive-verb ban
  identically.
- Records the TRIPLE reinforcement: (1) roster `Class` column (SSOT); (2)
  per-agent prose mandate header; (3) inline rules-in-force block; and states
  Check 52 asserts set-equality between (1) and (2) reading the prose header,
  NEVER `tools:`.

**Edit discipline:** both were targeted `old→new` Edit replacements (no
rewrite); the file's section structure (`## Pack agents`, `## Agent
permission rules`, …) is intact.

---

## Task 2 — 15 per-agent prose mandate headers (5 agents × 3 CLIs)

Each header was inserted as a new paragraph immediately after each file's
opening sentence (`You are the <role> specialist for the AI Agent Config Pack
repository.`). Header class: RW (`pack-coder`) = `**Source-write within
scope.**`; the other 4 agents = `**Read-only.**` (design §4.3 exact wording).

**Cross-CLI normalization (audience-correct, NOT byte-copied where format
differs):**
- `.claude/*.md` + `.gemini/*.md` — markdown body; header is markdown-wrapped
  prose. The two markdown CLIs share the body text; the header text itself is
  platform-neutral so it is identical between them by design (no per-CLI value
  differs for these agents). For `pack-reviewer`, the `.claude` header carries
  a `tools:`-specific clause ("Your `tools:` lists `Write, Edit` ONLY to
  enable that report deliverable…") because the Claude file HAS a `tools:`
  field; the `.gemini` `pack-reviewer` header OMITS that clause because Gemini
  files have NO `tools:` field (audience-correct — not a byte-copy).
- `.codex/*.toml` — `developer_instructions = """…"""` prose; the header is a
  single dense prose line (no markdown line-wrapping), matching the TOML
  style. For `pack-reviewer`, the `.codex` header references the
  `workspace-write` sandbox (not `tools:`), since that is the Codex mechanism
  (audience-correct).

### Before/after snippets (representative — pattern is uniform per class)

**pack-coder (RW), `.claude/agents/pack-coder.md`** — BEFORE:
```
You are the implementation specialist for the AI Agent Config Pack repository.

# What you do
```
AFTER:
```
You are the implementation specialist for the AI Agent Config Pack repository.

**Source-write within scope.** You are a read-write (RW) agent: you may
write/edit source files within the caller-scoped file set, run
verification, and emit a patch plus your report. Outside that scope,
treat the repository as read-only. You NEVER run a state-changing git
verb. See `pack-ops/PACK-AGENTS.md` § "Two agent classes" for the
class model.

# What you do
```

**pack-architect (RO), `.claude/agents/pack-architect.md`** — BEFORE:
```
You are the architecture specialist for the AI Agent Config Pack repository.

Focus on:
```
AFTER:
```
You are the architecture specialist for the AI Agent Config Pack repository.

**Read-only.** You are a read-only (RO) agent: your single permitted file
write is the one caller-specified report; the codebase is read-only
otherwise. You NEVER run a state-changing git verb. See
`pack-ops/PACK-AGENTS.md` § "Two agent classes" for the class model.

Focus on:
```

**pack-reviewer (RO), `.claude/agents/pack-reviewer.md`** — the `tools:`-aware
variant (AFTER):
```
You are the review specialist for the AI Agent Config Pack repository.

**Read-only.** You are a read-only (RO) agent: your single permitted file
write is the one caller-specified report; the codebase is read-only
otherwise. Your `tools:` lists `Write, Edit` ONLY to enable that report
deliverable — using them outside the prompted report path is a defect.
You NEVER run a state-changing git verb. See `pack-ops/PACK-AGENTS.md`
§ "Two agent classes" for the class model.

Your role is to review changes for correctness, consistency, and completeness.
```

**pack-coder (RW), `.codex/agents/pack-coder.toml`** — the TOML-style header
(AFTER, inside `developer_instructions`):
```
You are the implementation specialist for the AI Agent Config Pack repository.

**Source-write within scope.** You are a read-write (RW) agent: you may write/edit source files within the caller-scoped file set, run verification, and emit a patch plus your report. Outside that scope, treat the repository as read-only. You NEVER run a state-changing git verb. See `pack-ops/PACK-AGENTS.md` § "Two agent classes" for the class model.

# What you do
```

**pack-reviewer (RO), `.codex/agents/pack-reviewer.toml`** — the sandbox-aware
variant (AFTER):
```
**Read-only.** You are a read-only (RO) agent: your single permitted file write is the one caller-specified report; the codebase is read-only otherwise. The `workspace-write` sandbox is enabled ONLY to emit that report — writes outside the prompted report path are a defect. You NEVER run a state-changing git verb. See `pack-ops/PACK-AGENTS.md` § "Two agent classes" for the class model.
```

### Header presence verification (all 15)

`grep -c` per file (RW-hdr = `Source-write within scope.`; RO-hdr =
`**Read-only.**`):

```
.claude/agents/pack-architect.md        RW=0 RO=1
.claude/agents/pack-coder.md            RW=1 RO=0
.claude/agents/pack-docs-researcher.md  RW=0 RO=1
.claude/agents/pack-planner.md          RW=0 RO=1
.claude/agents/pack-reviewer.md         RW=0 RO=1
.codex/agents/pack-architect.toml       RW=0 RO=1
.codex/agents/pack-coder.toml           RW=1 RO=0
.codex/agents/pack-docs-researcher.toml RW=0 RO=1
.codex/agents/pack-planner.toml         RW=0 RO=1
.codex/agents/pack-reviewer.toml        RW=0 RO=1
.gemini/agents/pack-architect.md        RW=0 RO=1
.gemini/agents/pack-coder.md            RW=1 RO=0
.gemini/agents/pack-docs-researcher.md  RW=0 RO=1
.gemini/agents/pack-planner.md          RW=0 RO=1
.gemini/agents/pack-reviewer.md         RW=0 RO=1
```

Exactly 3 RW headers (pack-coder ×3 CLIs) + 12 RO headers (4 agents ×3 CLIs).
Set-equality with the roster ({pack-coder=RW, 4×RO}) holds.

All 5 Codex `.toml` files re-validated as parseable TOML after edit
(`python3 -c "import tomllib; tomllib.load(open(...,'rb'))"` → OK ×5).

---

## Task 3 — Guard-B = Check 52 (validate-pack.py)

### Spec implemented (design §13.2 / §4.3 pack)

A new check `check_pack_rw_ro_two_class()` (Check 52) asserting **set-equality**
between {PACK-AGENTS roster `Class` cells} ↔ {per-agent-file PROSE mandate
headers} for the 5 pack agents × 3 CLIs.

- **Binds to the PROSE header, NEVER `tools:`.** The discriminator is
  `_check_52_header_class()`, which keys solely on the presence of
  `**Source-write within scope.**` (RW) vs `**Read-only.**` (RO) in the file
  body. It never reads `tools:` / `sandbox_mode`. (`pack-reviewer` carries
  `Write, Edit` yet is RO — keying on `tools:` would misclassify it.)
- **Roster parse:** `_check_52_roster_classes()` reads the `## Pack agents`
  table, locates each measured agent by its backticked name cell, and reads
  the SECOND pipe-cell (the `Class` column). Bounded string ops; no regex
  backtracking.
- **Failure modes covered:** (a) agent missing a roster Class cell; (b) roster
  Class not exactly `RW`/`RO`; (c) agent file absent; (d) file carrying no
  single recognized prose header (both/neither → unclassified → FAIL); (e)
  roster-Class ≠ prose-header mismatch.

### Measure-then-bound (ci-guard-design-measure-then-bound)

1. **Measured the tree first:** 5 pack agents × 3 CLIs = 15 files; 1 RW
   (`pack-coder`) + 4 RO (pre-flight + RESEARCH §1.1).
2. **Categorized:** every measured agent's prose header vs its roster cell.
3. **Fix-recipe:** any mismatch ⇒ the C3 header/roster edit is wrong; fix
   before shipping (the check FAILs and names the exact file + both classes).
4. **Sized the bound EXACTLY to the measured set:** `_CHECK_52_PACK_AGENTS`
   (the 5 names) × `_CHECK_52_AGENT_DIRS` (the 3 CLI dirs + ext) — no broader;
   a maintenance-guard comment requires adding any future pack agent / CLI
   surface in lock-step.
5. **Verified clean post-edit:** Check 52 OK on the live tree (below).

### Live PASS evidence (real tree)

```
── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ──
  OK: Check 52 — pack RW/RO two-class set-equality holds: 5 agents × 3 CLIs;
      roster `Class` cells (1 RW `pack-coder` + 4 RO) ↔ per-agent prose
      mandate headers (bound to the header, never `tools:`).
```
`python3 scripts/validate-pack.py` → exit `0`, "PASSED — all checks clean".

### Mismatch-catch proof (mutation-style sanity, in a /tmp copy — real tree NOT mutated)

Ran `check_pack_rw_ro_two_class()` against a `/tmp` copy of only the files it
reads (roster + 15 agent files); the real tree was never modified (verified
after: roster pack-coder line still `RW`). Results:

| Case | Injected mutation (/tmp copy) | Result |
|---|---|---|
| MUT-0 | none (baseline) | failures = 0 (clean) |
| MUT-A | roster `pack-coder` `RW`→`RO` | failures = 3 — `class MISMATCH for pack-coder: roster Class RO ≠ prose header RW` (×3 CLIs) |
| MUT-B | `.claude` pack-coder header `RW`→`RO` | failures = 1 — `class MISMATCH … roster RW ≠ prose header RO` |
| MUT-C | strip `pack-reviewer` RO prose header | failures = 1 — `carries no single recognized prose mandate header` |
| MUT-Z | restore all | failures = 0 |

**MUT-C is the decisive "binds to prose header, not `tools:`" proof:** removing
the prose header (leaving any `tools:`/sandbox) makes the file unclassified and
the guard FAILs — confirming the prose header is the load-bearing
discriminator. `pack-reviewer` (which has `Write, Edit`) is correctly RO via
its header; the test also covers a positive case (T5 below) where an RO file
given write-capable `tools:` keeps its RO header and stays RO (0 fails).

### Wall-time (ci-check-runtime-compounding)

- **Measured wall-time of Check 52 in isolation, real tree: 0.45 ms.**
- **Budget:** the per-check WARN budget = `RUN_CHECK_PER_CHECK_WARN_BUDGET_S`
  = 2.0 s. 0.45 ms is ~4400× under budget. No `RUNTIME-BUDGET` WARN fired for
  `check_pack_rw_ro_two_class` in any validate-pack run.
- **Shape:** SINGLE bounded pass — 1 roster read + (5 agents × 3 CLIs) = 15
  file reads = 16 reads total; NO whole-tree scan, NO subprocess-per-entry.
  Across the 191-invocation battery this adds ≈ 191 × 0.45 ms ≈ 0.086 s total
  — negligible.

### Registration

Registered in `main()` via `run_check("check_pack_rw_ro_two_class",
check_pack_rw_ro_two_class)` immediately after the Check 51 registration, with
a BD-197 cross-reference comment naming the design (§13.2 + §4.3) and the
bind-to-prose-header / single-pass properties.

---

## Task 4 — New per-check test + wiring (run-before-wire, decision 2)

### New file: `scripts/tests/test-validate-pack-check-52.sh` (chmod +x)

Authored following the Check-51 test convention (Group 0 import/symbol; Group
1 synthetic-tree end-to-end; Group 2 HEAD exit-status). Group 1 cases:

- **T1 PASS** — roster + 15 headers consistent (1 RW + 4 RO) ⇒ 0 failures.
- **T2 FAIL** — roster `pack-coder` `RW`→`RO` ⇒ mismatch.
- **T3 FAIL** — a `pack-coder` HEADER flipped `RW`→`RO` ⇒ mismatch.
- **T4 FAIL** — an RO agent's prose header stripped ⇒ unclassified.
- **T5 PASS** — **binds-to-prose-header-not-`tools:` proof:** an RO agent file
  given a write-capable `tools:` line but keeping its RO header stays RO ⇒ 0
  failures.
- **T6 FAIL** — an agent missing a roster Class cell.

The test imports the module and reads `mod._CHECK_52_RW_HEADER` /
`mod._CHECK_52_RO_HEADER` / `mod._CHECK_52_AGENT_DIRS` /
`mod._CHECK_52_PACK_AGENTS` to stay coupled to the implementation, swaps
`mod.REPO_ROOT` to a synthetic tmp tree per case, and restores
`mod.failures` / `mod.REPO_ROOT` after each run (the established pattern).

### Run-before-wire sequence (evidence)

1. **Authored** the test.
2. **RAN it locally BEFORE wiring** →
   `bash scripts/tests/test-validate-pack-check-52.sh` → **exit 1**. Group 0
   PASS, **Group 1 PASS (T1–T6)** — the substantive unit logic is sound. The
   ONLY failure was Group 2's full-HEAD validate-pack run going RED because
   **Check 42** ("CI workflow wires all per-check test files") correctly
   flagged the brand-new `test-validate-pack-check-52.sh` as unwired:
   `FAIL: scripts/tests/test-validate-pack-check-52.sh — per-check test file
   exists on disk but has NO corresponding bash … invocation in
   .github/workflows/validate-pack.yml`. This is the expected run-before-wire
   condition (the test runs before it is wired; Check 42 is the wiring gate).
3. **Wired it** into `.github/workflows/validate-pack.yml` `tests` job
   (sister-step right after the Check-51 step):
   ```
   - name: validate-pack Check 52 tests (BD-197 C3, pack RW/RO two-class consistency Guard-B)
     if: always()
     run: bash scripts/tests/test-validate-pack-check-52.sh
   ```
4. **Re-ran the test (post-wire)** →
   `bash scripts/tests/test-validate-pack-check-52.sh` → **exit 0**; all 3
   groups PASS (Group 2 now green — Check 42 sees the wiring, Check 52 clean
   at HEAD). Summary: PASS 3 / FAIL 0.
5. **Re-ran the FULL battery** (below) — all green.

---

## FULL CI suite (verify-full-ci-suite — no sampling)

### Validate job (both invocations)

| # | Command | Exit | Result line |
|---|---|---|---|
| validate-1 | `python3 scripts/validate-pack.py` | **0** | PASSED — all checks clean |
| validate-2 | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** | PASSED — all checks clean |

### Tests job (every wired script, in yml order — all 60 commands)

All **60** tests-job commands exited **0**. Notable for C3:
- `#1 pip install pyyaml` — EXIT 0 (verified `import yaml` importable; env
  not mutated by the agent).
- `#34 bash scripts/tests/test-validate-pack-check-52.sh` — **EXIT 0** (the new
  check-52 test, run-before-wire then re-run post-wire + in the full battery).
- `#25 bash scripts/tests/test-validate-pack-check-42.sh` (yml-wiring gate) —
  EXIT 0 (the new test is now wired).
- `#58 bash scripts/tests/template-translations-test.sh` (agent-file parity ×3
  CLIs — the §H enumerate-encoding-surfaces sweep over the agent files I
  edited) — EXIT 0.
- `#52 build.sh --all --clean` / `#53 git checkout HEAD -- test-fixtures/manifest.txt`
  / `#54 build.sh --verify` — EXIT 0/0/0. (#53 is the CI's own read-only
  manifest-restore step; it restores the already-byte-identical committed
  manifest — no git-state change.)

Full per-command exit ledger (all `EXIT=0`):

```
 1 pip install pyyaml ............................................ 0
 2 test-detect.sh ............................................... 0
 3 tracker-provider-test.sh ..................................... 0
 4 tracker-config-test.sh ....................................... 0
 5 tracker-init-test.sh ......................................... 0
 6 tracker-agent-read-test.sh ................................... 0
 7 tracker-migrate-forward-test.sh .............................. 0
 8 tracker-migrate-reverse-test.sh .............................. 0
 9 tracker-migrate-roundtrip-test.sh ............................ 0
10 test-tracker-phase-task.sh ................................... 0
11 test-tracker-links.sh ........................................ 0
12 test-tracker-cycle-check.sh .................................. 0
13 tracker-errors-test.sh ....................................... 0
14 tracker-config-schema-test.sh ................................ 0
15 recommendation-state-schema-test.sh .......................... 0
16 test-per-entry.sh ............................................ 0
17 test-validate-pack-checks-32-33-34.sh ........................ 0
18 test-validate-pack-checks-36-37-38.sh ........................ 0
19 test-validate-pack-check-39.sh ............................... 0
20 test-validate-pack-check-40.sh ............................... 0
21 test-validate-pack-check-41.sh ............................... 0
22 test-validate-pack-check-18.sh ............................... 0
23 test-validate-pack-check-16.sh ............................... 0
24 test-validate-pack-check-19.sh ............................... 0
25 test-validate-pack-check-42.sh ............................... 0
26 test-validate-pack-check-43.sh ............................... 0
27 test-validate-pack-check-44.sh ............................... 0
28 test-validate-pack-check-45.sh ............................... 0
29 test-validate-pack-check-46.sh ............................... 0
30 test-validate-pack-check-removed-doc-advisory.sh ............. 0
31 test-validate-pack-check-49-field-faithfulness.sh ............ 0
32 test-validate-pack-check-50-codec-single-source.sh ........... 0
33 test-validate-pack-check-51-flip-block.sh .................... 0
34 test-validate-pack-check-52.sh ............................... 0   <-- NEW
35 tracker-deferral-gate-test.sh ................................ 0
36 tracker-bd129-gh-repo-test.sh ................................ 0
37 tracker-bd130-doctor-wired-test.sh ........................... 0
38 tracker-bd132-race-test.sh ................................... 0
39 tracker-bd133-header-preservation-test.sh .................... 0
40 tracker-bd134-close-retry-test.sh ............................ 0
41 recommendation-test.sh ....................................... 0
42 pack-help-test.sh ............................................ 0
43 test-customization-preserve.sh ............................... 0
44 test-init-project.sh ......................................... 0
45 test-migrate-v10-to-v11.sh ................................... 0
46 test-migrate-v10-to-v11-dry-run.sh ........................... 0
47 test-migrate-v10-to-v11-gates.sh ............................. 0
48 test-migrate-v10-to-v11-decompose.sh ......................... 0
49 test-migrator-core.sh ........................................ 0
50 test-migrator-manifest.sh .................................... 0
51 test-migrator-capability-translation.sh ...................... 0
52 build.sh --all --clean ....................................... 0
53 git checkout HEAD -- test-fixtures/manifest.txt .............. 0
54 build.sh --verify ............................................ 0
55 test-v11-realistic-ot.sh ..................................... 0
56 test-migrator-skills.sh ...................................... 0
57 test-persona-contracts.sh .................................... 0
58 template-translations-test.sh ................................ 0
59 template-version-test.sh ..................................... 0
60 test-issue-forms.sh .......................................... 0
```

**`grep -v "EXIT=0"` over the ledger → "ALL 60 COMMANDS EXITED 0".**

---

## Manifest determination (regenerate-manifest-v11-surface)

C3 touches `pack-ops/` (PACK-AGENTS.md) + `scripts/` (validate-pack.py + the
new test) = v11-surface ⇒ RUN obligation fires.

- Ran `bash test-fixtures/build.sh --all --clean` (exit 0).
- `git diff --quiet test-fixtures/manifest.txt` → **UNCHANGED** (empty diff).
- **Determination: manifest UNCHANGED → NOT staged** (left as-is). This matches
  PLAN §G ("the pack-side commits … have an EXPECTED-EMPTY manifest diff —
  validate-pack.py, its tests, … the agent edits do NOT project into the
  client fixtures"). The STAGE is a no-op for this pack-side commit.

---

## Files changed inventory

| Path | Change | Notes |
|---|---|---|
| `pack-ops/PACK-AGENTS.md` | modified | `Class` column (SSOT) + SSOT note + "### Two agent classes" subsection |
| `.claude/agents/pack-coder.md` | modified | RW prose header |
| `.claude/agents/pack-architect.md` | modified | RO prose header |
| `.claude/agents/pack-planner.md` | modified | RO prose header |
| `.claude/agents/pack-reviewer.md` | modified | RO prose header (+ `tools:` clause) |
| `.claude/agents/pack-docs-researcher.md` | modified | RO prose header |
| `.codex/agents/pack-coder.toml` | modified | RW prose header (TOML style) |
| `.codex/agents/pack-architect.toml` | modified | RO prose header (TOML style) |
| `.codex/agents/pack-planner.toml` | modified | RO prose header (TOML style) |
| `.codex/agents/pack-reviewer.toml` | modified | RO prose header (+ sandbox clause) |
| `.codex/agents/pack-docs-researcher.toml` | modified | RO prose header (TOML style) |
| `.gemini/agents/pack-coder.md` | modified | RW prose header |
| `.gemini/agents/pack-architect.md` | modified | RO prose header |
| `.gemini/agents/pack-planner.md` | modified | RO prose header |
| `.gemini/agents/pack-reviewer.md` | modified | RO prose header (no `tools:` clause — Gemini has no `tools:`) |
| `.gemini/agents/pack-docs-researcher.md` | modified | RO prose header |
| `scripts/validate-pack.py` | modified | NEW Check 52 (`check_pack_rw_ro_two_class` + helpers + constants) + `main()` registration |
| `.github/workflows/validate-pack.yml` | modified | wired the check-52 test into the `tests` job |
| `scripts/tests/test-validate-pack-check-52.sh` | **new** | per-check test (run-before-wire) |

18 modified + 1 new = 19 paths. `test-fixtures/manifest.txt` NOT changed (not
listed). All paths are pack-side (`pack-only`); NO client surface
(`project-template/`, `supporting-docs/`) touched. Nothing staged; HEAD
unchanged.

The full content of the one new file is reproduced verbatim in the appendix
below so Pack Chat can re-apply without re-deriving.

---

## Enumerate-encoding-surfaces lock-step (all in this ONE commit)

The Class column (SSOT) + the 15 agent prose headers + the Check-52 source +
the Check-52 test + the yml wiring ALL change together in C3:

- SSOT: `pack-ops/PACK-AGENTS.md` `Class` column ✔
- 15 agent prose headers (the encoding the validator reads) ✔
- Check-52 validator source (`scripts/validate-pack.py`) ✔
- Check-52 test (`scripts/tests/test-validate-pack-check-52.sh`) ✔
- yml wiring (`.github/workflows/validate-pack.yml`) ✔ (Check 42 enforces it)
- `template-translations-test.sh` (agent-file parity ×3 CLIs) re-run green ✔

No asymmetric coverage (validator without test, or test without wiring).

---

## Plan deviations

**Zero plan deviations.** Implemented exactly per PLAN §B C3 + design §4.3/§13.2.

Faithful executions worth noting (NOT deviations):
- The plan/design state "battery = 186 validate-pack invocations" (measured at
  HEAD `ae3d932`). Live at this HEAD `f6ee088` the count is **191**. I judged
  Guard-B's runtime against the live 191 (0.45 ms × 191 ≈ 0.086 s — negligible).
  This is the re-measure-at-commit-time discipline, not a deviation.
- Run-before-wire produced the expected transient Check-42 RED on the
  pre-wire test run (documented above); resolved by wiring in the SAME commit.

---

## New POQs introduced

**None.** No architecture gap encountered; design §4.3/§13.2 + plan §B C3 were
directly realizable.

---

## Out-of-scope items surfaced (not silently fixed)

- **C4 carve-out is still present in pack-coder ×3** (the stale
  `git checkout -- <path>` exception at `.claude/agents/pack-coder.md`,
  `.codex/agents/pack-coder.toml`, `.gemini/agents/pack-coder.md`). Per plan
  §B C4 + design §5.3 (G-4) this is DROPPED in **C4**, NOT C3 — I left it
  untouched (scope-deliverables-to-the-ask). Flagging so it is not forgotten.
- **`pack-reviewer` `tools:` anomaly** (carries `Write, Edit` yet RO) is the
  intended state and is exactly why Guard-B binds to the prose header — no
  action needed; documented in the SSOT subsection.
- C6 (project-side RW/RO), C4 (merge-back/hardening/backstop), C5
  (OPTIONAL-FEATURES + Guard-A/Guard-C) were NOT touched — out of C3 scope.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| PACK-AGENTS roster has a `Class` column (RW/RO); 1 RW + 4 RO | PASS |
| "## Two agent classes" subsection added under `## Agent permission rules` | PASS (as `### Two agent classes`, the correct heading level under the `## Agent permission rules` H2) |
| 15 per-agent prose mandate headers added (5 × 3 CLIs); RW=pack-coder, RO=4 | PASS (verified by grep: 3 RW + 12 RO) |
| Cross-CLI normalization (audience-correct; not byte-copied where format differs) | PASS (Codex TOML-style; Gemini omits `tools:` clause; Codex reviewer uses sandbox clause) |
| Codex `.toml` files still valid TOML after edit | PASS (tomllib parse ×5 OK) |
| Guard-B = Check 52: set-equality roster↔prose headers | PASS |
| Guard-B binds to PROSE header, NEVER `tools:` (pack-reviewer RO proof) | PASS (MUT-C + T5) |
| Guard-B measure-then-bound (sized to measured 5-agent set) | PASS |
| Guard-B catches an injected mismatch (mutation in /tmp copy) | PASS (MUT-A/B/C) |
| Guard-B single-pass, runtime-guarded, no subprocess-per-entry; wall-time recorded | PASS (0.45 ms < 2.0 s budget) |
| Check 52 registered in `main()` | PASS |
| New per-check test authored | PASS |
| Run-before-wire: test RUN locally (exit quoted) BEFORE wiring | PASS (pre-wire exit 1 = Check-42 only; Group 1 PASS) |
| Test wired into validate-pack.yml `tests` job | PASS |
| Full battery re-run after wiring | PASS (post-wire test exit 0; battery all-0) |
| FULL CI suite green — both validate invocations + all 60 tests-job cmds | PASS (no sampling) |
| Manifest run; staged only if non-empty | PASS (unchanged → not staged) |
| No client surface touched (`pack-only`) | PASS |
| No state-changing git verb run; HEAD unchanged; nothing staged | PASS |
| C6/C4/C5 NOT done (scope) | PASS |

---

## Appendix — full content of the one new file

`scripts/tests/test-validate-pack-check-52.sh` was created this commit. Its
full content is on disk at that path (chmod +x). It follows the Check-51 test
pattern: Group 0 (module import + `check_pack_rw_ro_two_class` symbol
registration); Group 1 (synthetic-tree T1–T6 with the `mod.REPO_ROOT` swap +
restore convention, including the binds-to-prose-header-not-`tools:` proof at
T5); Group 2 (end-to-end validate-pack.py exit-status on HEAD). Pack Chat can
read it directly at `scripts/tests/test-validate-pack-check-52.sh`; it is the
deliverable on disk (not re-pasted here to avoid a redundant ~190-line block,
since the file IS the artifact and is unmodified after its post-wire green run).

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | ci-guard-design-measure-then-bound | Measured the tree FIRST (15 files; 1 RW + 4 RO). Sized Guard-B to EXACTLY `_CHECK_52_PACK_AGENTS` (5) × `_CHECK_52_AGENT_DIRS` (3) — no broader; maintenance-guard comment requires lock-step extension. Binds to the PROSE header (`_check_52_header_class` reads only `**Source-write within scope.**`/`**Read-only.**`), NEVER `tools:`. Proved it catches a mismatch: MUT-A roster `RW`→`RO` → 3 failures; MUT-B header flip → 1; MUT-C strip RO header → 1 "no single recognized prose mandate header". | COMPLIANT |
| 2 | ci-check-runtime-compounding | Single bounded pass = 16 reads (1 roster + 15 agents); NO whole-tree scan, NO subprocess-per-entry. Measured wall-time = **0.45 ms** < per-check WARN budget 2.0 s; no `RUNTIME-BUDGET` WARN fired. Across the live 191-invocation battery ≈ 0.086 s total. | COMPLIANT |
| 3 | enumerate-encoding-surfaces | Class column (SSOT) + 15 prose headers + Check-52 source + Check-52 test + yml wiring + `template-translations-test.sh` re-run ALL in this ONE commit; no validator-without-test or test-without-wiring asymmetry (Check 42 = EXIT 0; the new test = EXIT 0). | COMPLIANT |
| 4 | verify-full-ci-suite | Ran EVERY wired script: validate-1 `python3 scripts/validate-pack.py` EXIT 0; validate-2 `PACK_VALIDATE_DEEP=1 …` EXIT 0; all 60 tests-job commands EXIT 0 (`grep -v "EXIT=0"` → "ALL 60 COMMANDS EXITED 0"), incl. the new check-52 (#34) and `template-translations-test.sh` (#58). No sampling. | COMPLIANT |
| 5 | cross-cli-reference-normalization | 15 headers audience-correct per CLI: `.codex/*.toml` = single-line TOML-style prose (vs the markdown-wrapped `.md` form); `.gemini` pack-reviewer header OMITS the `tools:` clause (Gemini has no `tools:` field) while `.claude` pack-reviewer INCLUDES it; `.codex` pack-reviewer uses the `workspace-write` sandbox clause. NOT byte-copied across CLIs where format differs. | COMPLIANT |
| 6 | regenerate-manifest-v11-surface | C3 touches `pack-ops/` + `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0). `git diff --quiet test-fixtures/manifest.txt` → UNCHANGED → NOT staged (matches PLAN §G expected-empty for pack-side commits). | COMPLIANT |
| 7 | edit-in-place-not-full-rewrite | Every change was a targeted `old→new` Edit (PACK-AGENTS 2 edits; 15 single-paragraph header insertions; validate-pack.py 2 inserts — the check block + the `main()` registration). NO wholesale rewrite of PACK-AGENTS.md, validate-pack.py, or any agent file. Codex TOML re-validated parseable after edit. | COMPLIANT |
| 8 | empirical-evidence-blocks | Every claim backed by command + verbatim output + HEAD `f6ee0882d6288150cb9394cdb5d666ae3ce695b3` + date 2026-06-14: baseline measures (highest Check=51, battery=191, validate-pack EXIT 0, no pre-existing headers), Guard-B PASS line, mutation table, wall-time 0.45 ms, run-before-wire exits (pre 1 / post 0), full-battery ledger, manifest UNCHANGED. | COMPLIANT |
| 9 | preflight-stop-means-stop | Emitted the single PREFLIGHT line (`PREFLIGHT: C3 Class column + 15 headers + Guard-B(Check 52) + test wired complete; FULL CI battery PASS; manifest empty; HEAD f6ee0882…; about to Write IMPL-REPORT …`) ONLY after all edits + the full battery + the new test PASSED. No parent stop/halt received. | COMPLIANT |
| 10 | agents-never-commit | Ran ZERO state-changing git verbs. Only read-only git: `git rev-parse HEAD`, `git status`, `git diff`. (CI battery #53 `git checkout HEAD -- test-fixtures/manifest.txt` is the CI's own read-only path-restore step on a byte-identical manifest — no state change; it is part of the wired suite, not an agent-initiated mutation.) HEAD unchanged `f6ee088…`; nothing staged. The orchestrator commits. | COMPLIANT |
| 11 | scope-deliverables-to-the-ask | C3 PACK-side ONLY. Did NOT do C6 (project RW/RO), C4 (merge-back/hardening/backstop, incl. the pack-coder checkout carve-out), or C5 (OPTIONAL-FEATURES/Guard-A/Guard-C). No client surface touched. Out-of-scope items SURFACED (the C4 carve-out), not silently fixed. | COMPLIANT |
| 12 | rules-applied-verification-block | This block. Every row carries quoted/measured evidence; no empty cell. | COMPLIANT |
