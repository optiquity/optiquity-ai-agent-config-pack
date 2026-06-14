# IMPL-REPORT — BD-197 C6a (P3 PROJECT-side RW/RO two-class model — DATA half)

**Agent:** pack-coder. **Regime:** in-place (no `/tmp` handoff dir named; report
written to the parent-tree path the caller specified). **Repo:**
optiquity-ai-agent-config-pack-v11-dev. **Branch:** `v11-dev`.
**HEAD at start AND at report time (no commit — agents never commit):**
`8e62a2ecf88fb017273379a1781957b4b6d14d82`. **Date:** 2026-06-14.

**Commit scope:** `project-only` (the C0 Check-36 manifest carve-out is
load-bearing here — first real exercise). Edits touch ONLY the CLIENT surface
(`project-template/`) + the regenerated, scope-neutral `test-fixtures/manifest.txt`.

---

## Read attestation (read IN FULL before editing — no skim/derivation)

I read each of the following in full before any edit:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
  §4.3 (RW/RO classification + triple reinforcement, PROJECT — lines 254–261) and
  §13.2 (Guard-B project — lines 541–544, for consistency with what C6b will assert).
  (The doc is 1186 lines; I paged §0–§5 / §13 / §14 in full and targeted §4.3/§13.2
  by content per the "line numbers drift" note in the doc header.)
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` §B "C6a"
  (lines 122–127 — the task list) + §B "C6b" (129–133) + §B "C7a" (135–144) to fix
  the boundary (I did NOT do C6b/C7a work).
- `maintenance-docs/v11-implementation/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`
  — the authoritative PROJECT classification (§1.2: 16 agents = 2 RW [`coder`,
  `repo-ops`] + 14 RO; §1.2 the three-way reconciliation; the "Gemini agent files
  have NO `tools:` field" + "`repo-ops` = Write-capable (script)" facts).
- `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` (lines 397–504)
  + `project-template/agent-run.sh` (`READONLY_AGENTS` lines 38–53 + the stale
  comment at lines 91–95).
- `CLAUDE.md` `## Pack memory` in full — incl. `bd-pack-only-operational-rule`,
  `pack-project-separation-of-concerns`, `regenerate-manifest-v11-surface`,
  `cross-cli-reference-normalization`, `edit-in-place`, plus the project trinity
  `## Project memory` "Project SSOT-first" rule + the pack-self deny-list.
- The four curated memory files in full:
  `feedback_bd_pack_only_operational_rule.md`,
  `feedback_pack_project_separation_of_concerns.md`,
  `feedback_manifest_regen_on_v11_surface.md`,
  `feedback_verify_full_ci_suite.md`.

---

## Empirical-Evidence Block — base-state verification (pre-flight)

- **Command:** `git rev-parse HEAD && git status && git branch --show-current`
- **Output:** HEAD `8e62a2ecf88fb017273379a1781957b4b6d14d82`; "nothing to commit,
  working tree clean"; branch `v11-dev`.
- **Date/HEAD:** 2026-06-14 / `8e62a2e`.
- **Interpretation:** correct base (the caller's HEAD; clean tree); the authority
  docs + the 48 agent files + PM-CHAT.md + agent-run.sh + the C0 carve-out are all
  present (verified by Read/grep below).
- **Conclusion:** SUPPORTED — proceeded.

---

## Per-task summary

### Task 1 — PM-CHAT.md `## Permission profiles` two-class framing (the project RW/RO SSOT)

**File:** `project-template/docs/pack/PM-CHAT.md` — `+38` lines, `-0`. Targeted
in-place insert of a new `### Permission classes (read-write / read-only)`
subsection BETWEEN the existing intro paragraph and the `### Profile assignment`
table (no rewrite of any existing content).

**What it establishes (design §4.3 PROJECT, client-native):** the three existing
profiles collapse into TWO permission classes; this `## Permission profiles`
section is named the authoritative project-side declaration of each agent's class:

- **RW** = `coder` (Write-capable scoped) + `repo-ops` (Write-capable script) —
  write within scope, emit patch + report, NEVER stage/commit (PM chat does that
  with developer approval); PM chat keeps concurrent RW agents on non-overlapping
  scopes (the safe-parallelism rationale, client-native).
- **RO** = the 14 remaining agents (named) — single report write only; the note
  that several RO agents carry `Write`/`Edit` ONLY for the report so the tool set
  does NOT classify the agent (mirrors the design's "bind to the PROSE header,
  never `tools:`" rule); the class is carried by the prose mandate header + this
  table + (Claude) the `agent-run.sh READONLY_AGENTS` dispatch.
- A shared hard-rule sentence: no agent runs a state-changing git verb (read-only
  verbs allowed); and the closing invariant that the three declarations (header,
  table, array) MUST always agree — exactly the set-equality C6b's Guard-B asserts.

**Client-native:** orchestrator is "PM chat" (lowercase, matching the existing
file convention); ZERO pack-self concepts. NOT a byte-copy of the pack
PACK-AGENTS `## Two agent classes` treatment (different audience, different
orchestrator name, different anchor).

### Task 2 — agent-run.sh stale-comment fix

**File:** `project-template/agent-run.sh` — `+8/-3` (lines 91–100). The
`READONLY_AGENTS` array (14 entries, lines 38–53) was already correct and was NOT
changed. Only the stale comment was fixed.

- **Before (FALSE since BD-127 kept Write):** "Safe here because Edit/Write tools
  are excluded at the agent-definition level."
- **After (truthful):** read-only is enforced by the launch-time `--disallowedTools`/
  flag profile + the read-only mandate header in each agent's definition file —
  NOT by removing Write/Edit at the agent-definition level; RO agents keep
  Write/Edit so they can produce their single report file, and the prompt
  constrains those tools to the report path.

**Verification:** `bash -n project-template/agent-run.sh` → SYNTAX OK (bash
3.2.57, macOS default — no GNU-only constructs). Stale token
`"excluded at the agent-definition level"` → grep confirms GONE. I did NOT add
the C7a `--disallowedTools` hardening verbs (that is C7a, out of scope).

### Task 3 — per-agent prose mandate headers (16 agents × 3 CLIs = 48 files)

**Files touched:** NONE. **Evidence-based decision (documented under "Plan
deviations").** All 48 headers ALREADY carry the EXACT design §4.3-specified
labels and were introduced in commit `43b5fe1` (v10.1, 2026-05-08), predating
BD-197 by over a month. C6a's deliverable for the headers is the third
reinforcement leg being PRESENT, CORRECT, and CONSISTENT (2 RW + 14 RO) — which
it already is. I verified, did not re-author (per `edit-in-place` +
`scope-deliverables-to-the-ask`).

**Header survey (the third reinforcement leg), per CLI:**

| CLI dir | RO headers | RW headers | NONE | TOTAL | RW set |
|---|---|---|---|---|---|
| `project-template/.claude/agents/*.md` | 14 | 2 | 0 | 16 | `coder`, `repo-ops` |
| `project-template/.codex/agents/*.toml` | 14 | 2 | 0 | 16 | `coder`, `repo-ops` |
| `project-template/.gemini/agents/*.md` | 14 | 2 | 0 | 16 | `coder`, `repo-ops` |

Exact labels present (design §4.3 wording — verbatim match):
- RW scoped: `**Write-capable (scoped).**` (`coder`, all 3 CLIs)
- RW script: `**Write-capable (script).**` (`repo-ops`, all 3 CLIs)
- RO: `**Read-only.**` (the 14, all 3 CLIs)

**Before/after samples (UNCHANGED by C6a — shown to document the reinforcement leg):**
- `.claude/agents/coder.md:24` (RW): `**Write-capable (scoped).** You may write or
  edit source files within the explicit scope the calling prompt defines under
  "Files in scope." …`
- `.codex/agents/repo-ops.toml:19` (RW script): `**Write-capable (script).** You may
  run scripts in the project's \`scripts/\` directory and edit generated artifacts …`
- `.gemini/agents/architect.md:24` (RO; NO `tools:` field): `**Read-only.** You may
  inspect any file in the repository. The single permitted file write or edit …`

---

## RW/RO-consistency proof (2 RW + 14 RO across all three reinforcement legs)

This is the load-bearing C6a guarantee — exactly what C6b's Guard-B(project) will
later assert (design §13.2: set-equality {PM-CHAT RO rows} ↔ {`READONLY_AGENTS`}
↔ {per-file RO PROSE headers}). All three legs are not only equal in COUNT but
SET-IDENTICAL in agent NAMES.

**Empirical-Evidence Block (triple-reinforcement set-equality):**
- **Command (leg 1 — PM-CHAT Profile-assignment table, table-scoped):**
  `awk '/^### Profile assignment/{f=1;next} f&&/^###|^## /{f=0} f&&/^\| \`/{print}'`
  → 14 rows `Read-only` + `coder` Write-capable (scoped) + `repo-ops`
  Write-capable (script) = **RO=14, RW=2, TOTAL=16**.
- **Command (leg 2 — `READONLY_AGENTS`):**
  `awk '/^READONLY_AGENTS=\(/{...}'` → **14 entries**: architect, reviewer,
  planner, tester, docs-researcher, grpc-schema, auditor, auditor-architecture,
  auditor-code, auditor-docs, auditor-security, auditor-tests, auditor-ui,
  auditor-ops.
- **Command (leg 3 — 48 per-file headers):** grep classify per file across all 3
  CLIs → each CLI dir = RO=14, RW=2, NONE=0; RW set = `{coder, repo-ops}` on
  every CLI.
- **Set-equality check:** `diff` of sorted RO-name lists →
  `leg1 == leg2` IDENTICAL; `leg1 == leg3 (.claude)` IDENTICAL. The 14 RO names
  match exactly across all three legs.
- **Gemini no-`tools:` check:** `grep -rln '^tools:' project-template/.gemini/agents/`
  → none (0/16) — Gemini agents carry no `tools:` field; classification is
  prose-header-only there (consistent with design §13.2 "Gemini files have no
  `tools:` … prose+array only").
- **Date/HEAD:** 2026-06-14 / working tree at `8e62a2e` + my edits.
- **Interpretation:** the project two-class declaration is consistent on all three
  legs by both count and name; C6b's Guard-B will pass on arrival (measure-then-bound).
- **Conclusion:** SUPPORTED.

---

## ZERO-pack-self-refs proof (bd-pack-only-operational-rule)

**Empirical-Evidence Block:**
- **Command:** `git diff -- project-template/ | grep '^+' | grep -vE '^\+\+\+'`
  then grep for each token across the added lines.
- **Output (each token → result):**
  `BD-[0-9]` none · `maintenance-docs` none · `pack-ops` none · `PACK-AGENTS`
  none · `PACK-CHAT` none · `Pack Chat` none · `pack-coder` none ·
  `pack-architect` none · `pack-reviewer` none · `pack-planner` none ·
  `pack-docs-researcher` none · `Two agent classes` none · `pack-self` none ·
  `pack-only` none · `pack-chat-only` none.
- **Date/HEAD:** 2026-06-14 / `8e62a2e` + edits.
- **Interpretation:** my project-template additions introduce ZERO pack-self
  concepts; all references are client-native (PM chat, client paths, agent
  names without the `pack-` prefix).
- **Conclusion:** SUPPORTED — clean.

---

## Manifest regeneration (regenerate-manifest-v11-surface; the carve-out's first real exercise)

**Empirical-Evidence Block (regen + non-empty + verify):**
- **Command:** `bash test-fixtures/build.sh --all --clean` → EXIT 0 ("manifest
  written: …/test-fixtures/manifest.txt"). Then `bash test-fixtures/build.sh
  --verify` → EXIT 0 (all six fixtures "OK"). Re-ran both a second time
  (determinism check) → EXIT 0 / EXIT 0, identical SHAs.
- **Output (`git diff -- test-fixtures/manifest.txt`):** 3 insertions / 3
  deletions — the three v11 fixture SHAs changed:
  - `v11-realistic-ot 685169e… → 06b4de4…`
  - `v11-flat-file 1d39609… → f3748c0…`
  - `v11-tracker-on d143022… → 87dfdea…`
  - (`v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev` UNCHANGED —
    correct: only v11 fixtures project the `project-template/` content.)
- **Date/HEAD:** 2026-06-14 / `8e62a2e` + edits.
- **Interpretation:** my `project-template/` edits project into the v11 fixtures
  → fixture HEAD SHAs drift → manifest diff is NON-EMPTY (EXPECTED). This is the
  C0 Check-36 carve-out's FIRST real exercise: a `project-only` commit that
  legitimately carries the regenerated manifest.
- **Conclusion:** SUPPORTED. **The new manifest is KEPT (left MODIFIED/unstaged)**
  — the orchestrator stages it WITH the commit; I ran NO `git add` and NO
  `git checkout` (denied verbs). I did NOT restore the old manifest.

---

## Check-36 carve-out confirmation (the carve-out exercise)

**Empirical-Evidence Block (simulated `project-only` offender logic on the C6a set):**
- **Command:** loaded `scripts/validate-pack.py` as a module and ran the exact
  Check-36 `project-only` offender comprehension over my three touched paths:
  `[p for p in paths if not _is_project_side_path(p) and not _is_scope_neutral_generated(p)]`.
- **Output:**
  - `project-template/docs/pack/PM-CHAT.md` → project_side=True, scope_neutral=False → NOT offender
  - `project-template/agent-run.sh` → project_side=True, scope_neutral=False → NOT offender
  - `test-fixtures/manifest.txt` → project_side=False, scope_neutral=**True** → NOT offender (carve-out)
  - **`project-only` offenders: [] → PASS (zero offenders)**
- **Source of the carve-out:** `scripts/validate-pack.py:4136` —
  `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})`
  (authored in C0); the Check-36 `project-only` branch (lines 4349–4362) excludes
  scope-neutral paths from the offender set.
- **Date/HEAD:** 2026-06-14 / `8e62a2e` + edits.
- **Interpretation:** a `project-only` commit of {PM-CHAT.md + agent-run.sh +
  regenerated manifest} produces ZERO Check-36 offenders → PASSES. The two
  project-template files are project-side (legitimate for `project-only`); the
  manifest is exempt via the carve-out. Without C0's carve-out the staged manifest
  would have denied `project-only` (B-1) — confirming the carve-out is load-bearing.
- **Conclusion:** SUPPORTED.

---

## FULL CI suite results (verify-full-ci-suite — EVERY wired script; no sampling)

Every script wired in `.github/workflows/validate-pack.yml` was run locally with
the NEW manifest + my edits in the working tree. Exit statuses quoted.

**`validate` job (both invocations):**

| Step | Command | EXIT |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **0** — "PASSED — all checks clean" |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** — "PASSED — all checks clean" |

(Notable: Check 52 [pack RW/RO Guard-B, C3], Check 53 [Guard-A, C5], Check 56
[Guard-C, C5] all PASS with my project-side changes — no pack-side guard regressed.)

**`tests` job — every enumerated step (EXIT all 0 unless noted):**

| Step | EXIT | Step | EXIT |
|---|---|---|---|
| detect.sh | 0 | check-46 | 0 |
| tracker-provider | 0 | check-48 removed-doc-advisory | 0 |
| tracker-config | 0 | check-49 field-faithfulness | 0 |
| tracker-init | 0 | check-50 codec-single-source | 0 |
| tracker-agent-read | 0 | check-51 flip-block | 0 |
| tracker-migrate-forward | 0 | check-52 (pack RW/RO Guard-B) | 0 |
| tracker-migrate-reverse | 0 | check-53 (Guard-A) | 0 |
| tracker-migrate-roundtrip | 0 | check-56 (Guard-C) | 0 |
| tracker-phase-task | 0 | tracker-deferral-gate | 0 |
| tracker-links | 0 | tracker-bd129-gh-repo | 0 |
| tracker-cycle-check | 0 | tracker-bd130-doctor-wired | 0 |
| tracker-errors | 0 | tracker-bd132-race | 0 |
| tracker-config-schema | 0 | tracker-bd133-header-preservation | 0 |
| recommendation-state-schema | 0 | tracker-bd134-close-retry | 0 |
| per-entry | 0 | recommendation | 0 |
| check-32-33-34 | 0 | pack-help | 0 |
| check-36-37-38 | 0 | customization-preserve | 0 |
| check-39 | 0 | init-project | 0 |
| check-40 | 0 | migrate-v10-to-v11 | 0 |
| check-41 | 0 | migrate-dry-run | 0 |
| check-18 | 0 | migrate-gates | 0 |
| check-16 | 0 | migrate-decompose | 0 |
| check-19 | 0 | migrator-core | 0 |
| check-42 | 0 | migrator-manifest | 0 |
| check-43 | 0 | migrator-capability-translation | 0 |
| check-44 | 0 | build test fixtures (`--all --clean`) | 0 |
| check-45 | 0 | fixture manifest verify (`--verify`) | 0 |

| Step (post-fixture) | EXIT |
|---|---|
| v11-realistic-ot integration | 0 |
| migrator-skills | 0 |
| persona-contracts | 0 |
| template-translations | 0 |
| template-version | 0 |
| issue-forms | 0 |

**Not-yet-existing (correctly absent; NOT wired in the yml; out-of-scope future
commits):** `test-validate-pack-check-54.sh` (C8b deliverable) and
`test-validate-pack-check-55.sh` (C6b deliverable) → EXIT 127 (file not found).
These are NOT part of the current CI suite and their absence is correct for C6a.

**The CI `restore committed manifest before verify` step** uses
`git checkout HEAD -- test-fixtures/manifest.txt` (a CI-runner-side read-only
restore so `--verify` compares against the pinned manifest). I did NOT run it
(`git checkout` is a denied verb for agents); instead I regenerated the manifest
and verified the rebuilt fixtures match it (EXIT 0), which is the local-dev
equivalent. On the CI runner the committed manifest will be the NEW one the
orchestrator commits, so the restore→verify pair is tautology-free and green.

---

## Files changed inventory

| Path | Change type | Lines | Surface | Staged? |
|---|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | modified | +38/-0 | CLIENT (project-side) | NO (orchestrator stages) |
| `project-template/agent-run.sh` | modified | +8/-3 | CLIENT (project-side) | NO |
| `test-fixtures/manifest.txt` | modified (regenerated) | +3/-3 | scope-NEUTRAL (carve-out) | NO (orchestrator stages WITH commit) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C6a.md` | new (this report) | n/a | pack-only (report artifact) | NO |

No new source files created (no full-file-content dump needed). The 48 agent
files are UNCHANGED (verification-only — see Plan deviations).

---

## Boundary discipline check (P-missed-7)

C6a edits the CLIENT surface (`project-template/`), so the project-side SSOT
pre-flight applies:

- **Concept "agent RW/RO classification" — project-side SSOT investigated:**
  `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` (the project
  RO/RW SSOT) + `project-template/agent-run.sh READONLY_AGENTS` (the runtime
  projection) + the per-agent prose mandate headers. I used these project-side
  SSOTs and did NOT reach for any pack-only mechanism. The two-class framing was
  authored INTO the project SSOT (PM-CHAT.md), client-native ("PM chat"
  orchestrator), with no pack-only target referenced.
- **No reference to a pack-only file/role added:** confirmed by the ZERO-pack-self
  grep above (no `pack-ops/`, `PACK-AGENTS.md`, `Pack Chat`, `BD-NNN`,
  `maintenance-docs/`, `pack-*` agent names introduced into project content).
- **No "Boundary discipline stop" triggered** — no edit attempted to add a
  pack-only reference to a client surface.
- **Frame-rotation:** this commit is project-side ONLY; the project-side answer
  (cite PM-CHAT.md / agent-run.sh / the headers as the SSOTs) is the correct
  frame. The pack-side equivalent (PACK-AGENTS `## Two agent classes`) was
  deliberately NOT mirrored byte-for-byte (separation-of-concerns).

---

## Plan deviations

**One deviation, evidence-based, within the plan's intent:**

1. **The 48 per-agent mandate headers were VERIFIED, not re-authored.** The plan
   §B C6a line 125 lists "per-agent prose mandate header reinforcement
   (`**Write-capable (scoped).**` / `**Read-only.**`)" as a deliverable. Evidence
   (`git blame`): all 48 headers were introduced in `43b5fe1` (v10.1, 2026-05-08)
   and ALREADY carry the EXACT design §4.3 labels with the correct 2 RW + 14 RO
   classification (set-identical to legs 1 and 2). The reinforcement deliverable
   (the third leg PRESENT + CORRECT + CONSISTENT) is therefore already satisfied.
   Re-editing 48 files to add content the plan/design does not specify for the
   project headers (e.g., a new SSOT cross-reference) would be
   `scope-deliverables-to-the-ask` + `edit-in-place` violation and would risk
   introducing inconsistency. I verified consistency (the C6b Guard-B
   precondition) instead of editing. **No header file was changed.** This is the
   expected outcome when a reinforcement leg pre-exists correct — the design's
   "triple reinforcement" requires the leg to AGREE, and it does.

**No architecture changes. No new POQs introduced.**

---

## Scope discipline (scope-deliverables-to-the-ask)

C6a = PROJECT RW/RO DATA half ONLY. I did NOT:
- add the in-session spawn instruction to PM-CHAT.md (that is C7a),
- add the Guard-B(project) validator / Check 55 (that is C6b),
- add `agent-run.sh --disallowedTools` hardening verbs (that is C7a — I left the
  existing `Bash(git commit:*)`/`Bash(git push:*)` flags untouched),
- drop the Codex `git checkout -- <path>` carve-out (that is C4/C7a),
- touch any pack-side surface.

**Surfaced for the orchestrator (noticed, not fixed — out of C6a scope):**
- `project-template/.codex/agents/coder.toml:47` still carries the stale
  `git checkout (except \`git checkout -- <path>\`)` carve-out. Per PLAN §B C7a
  line 137 + the C4 M-2 prose-coherence nuance, that excision is a C7a (project)
  deliverable. NOT touched here.

---

## Definition-of-Done checklist

| Item | PASS/FAIL | Evidence |
|---|---|---|
| PM-CHAT `## Permission profiles` carries the two-class (RW/RO) framing, client-native | PASS | `### Permission classes (read-write / read-only)` subsection added; "PM chat" orchestrator; no pack-self |
| `agent-run.sh READONLY_AGENTS` = exactly the 14 RO agents | PASS | leg-2 awk count = 14; set-identical to PM-CHAT RO rows |
| `agent-run.sh` stale comment FIXED (truthful enforcement model) | PASS | old token gone; new comment states flag-profile + RO header enforcement; `bash -n` OK |
| 48 per-agent headers carry correct labels (2 RW + 14 RO) | PASS | survey: each CLI 14 RO + 2 RW, NONE=0; RW = {coder, repo-ops} |
| RW/RO consistent (2 RW + 14 RO) across SSOT / array / headers (set-identical) | PASS | leg1==leg2==leg3 (diff IDENTICAL); names match |
| ZERO pack-self refs in project-template edits | PASS | comprehensive token sweep — all none |
| Manifest regenerated; diff NON-EMPTY; KEPT unstaged | PASS | 3 v11 SHAs changed; `--verify` EXIT 0; no `git add`/`git checkout` |
| Check-36 `project-only` would PASS for the C6a set | PASS | simulated offender logic → [] (zero offenders); carve-out exempts manifest |
| FULL CI battery PASS (no sampling) | PASS | validate ×2 EXIT 0; every tests-job script EXIT 0 |
| client-native authoring; not a byte-copy of pack treatment | PASS | "PM chat"; client paths; no PACK-AGENTS structure imported |
| audience-correct per-CLI headers (Gemini no `tools:`) | PASS | Gemini 0/16 `tools:`; headers unchanged & already audience-correct |
| no C6b/C7a work; no pack-side surface touched | PASS | only PM-CHAT.md + agent-run.sh + manifest changed |
| agents-never-commit (no state-changing git verb) | PASS | only `git status`/`diff`/`rev-parse`/`blame`/`log` + edits + build.sh + read-only `git show`-free run |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **bd-pack-only-operational-rule** [coder] | Token sweep over `git diff -- project-template/` added lines: `BD-[0-9]` none, `maintenance-docs` none, `pack-ops` none, `PACK-AGENTS` none, `PACK-CHAT` none, `Pack Chat` none, `pack-coder/architect/reviewer/planner/docs-researcher` none, `Two agent classes` none, `pack-self` none. | COMPLIANT |
| **pack-project-separation-of-concerns** [universal] | PM-CHAT two-class subsection authored client-native: orchestrator = "PM chat" (lowercase, file's own convention), references the project SSOTs (`## Permission profiles` table, `agent-run.sh READONLY_AGENTS`, per-file headers) only; NOT the pack `## Two agent classes` section or `pack-ops/PACK-AGENTS.md`. Separate artifact, not a byte-copy. | COMPLIANT |
| **cross-cli-reference-normalization** [coder] | Headers are audience-correct per-CLI and unchanged (`.md` vs `.toml`; Gemini `grep -rln '^tools:'` = 0/16 → prose-only). No byte-copy across formats was introduced; the only edits (PM-CHAT.md, agent-run.sh) are single-file, not cross-trinity. | COMPLIANT |
| **regenerate-manifest-v11-surface** [coder] | `bash test-fixtures/build.sh --all --clean` EXIT 0 → manifest written; `git diff` non-empty (3 v11 SHAs); `--verify` EXIT 0. Manifest left MODIFIED/unstaged (no `git add`); no `git checkout` / restore of the old manifest. | COMPLIANT |
| **verify-full-ci-suite** [universal] | Ran EVERY wired script: `validate` job ×2 (general + `PACK_VALIDATE_DEEP=1`) both EXIT 0; ALL `tests`-job scripts EXIT 0 (per-table above), incl. fixture build + `--verify` + v11-realistic-ot + persona-contracts + issue-forms. No sampling. (check-54/55 absent = future commits, correctly not wired.) | COMPLIANT |
| **edit-in-place-not-full-rewrite** [universal] | PM-CHAT.md = targeted insert of one subsection (no existing content rewritten); agent-run.sh = one comment block replaced; both re-Read after editing and confirmed correct. 48 agent files NOT rewritten (verified, unchanged). | COMPLIANT |
| **empirical-evidence-blocks** [coder] | Every state-claim above carries an Empirical-Evidence Block: command + verbatim output + Date/HEAD (`8e62a2e`, 2026-06-14) + interpretation + SUPPORTED conclusion (base-state, triple-reinforcement, zero-pack-self, manifest, Check-36). | COMPLIANT |
| **preflight-stop-means-stop** [universal] | Emitted the single PREFLIGHT line `PREFLIGHT: C6a PROJECT RW/RO … FULL CI battery PASS; HEAD 8e62a2e…; about to Write IMPL-REPORT …` ONLY after all edits + the full battery PASSED. No parent stop/halt message received. | COMPLIANT |
| **agents-never-commit** [universal] | Ran only read-only git verbs (`git status`, `git diff`, `git rev-parse`, `git branch --show-current`, `git blame`, `git log`) + the edits + `build.sh`. NO `git add`/`commit`/`checkout`/`apply`/any state-changing verb. Final `git status` shows 3 files MODIFIED, none staged. | COMPLIANT |
| **scope-deliverables-to-the-ask** [universal] | Only PM-CHAT.md (DATA) + agent-run.sh (comment fix) + manifest (regen) changed. NOT done: C7a in-session spawn instruction, C6b Guard-B/Check-55, C7a `--disallowedTools` hardening, Codex checkout carve-out drop, any pack-side edit. Out-of-scope `coder.toml:47` carve-out surfaced (not fixed). | COMPLIANT |
| **rules-applied-verification-block** [universal] | This block. | COMPLIANT |
