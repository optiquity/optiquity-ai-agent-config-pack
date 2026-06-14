# IMPL-REPORT — BD-197 C7a (PROJECT in-session spawn + merge-back + git-permission hardening + launcher; the DATA half)

**Role:** pack-coder. **Commit:** C7a (`project-only`). **Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**Base HEAD (pre-edit = post-edit; agents never commit):** `a255718a6849fd78ddde66c5d0e685e5e0bc80f8`.
**Regime:** IN-PLACE (no `/tmp` handoff dir named in the prompt; edits left in the working tree; a read-only `git diff` patch also emitted to `/tmp/c7a-changes.patch` for auditability).
**Date:** 2026-06-14.
**Realized consumer of:** `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §18.1 (PROJECT in-session spawn — the 5 elements), §4.1/§4.2 (merge-back + IMPL-report-back), §5.1/§5.2/§5.3 (git-permission verb set + where it lands), §6 (conflict protocol), §7 (launcher feasibility / NEW-FORK-1), §12.2 (merge-back codified) + `PLAN-BD-197-WORKTREE-ISOLATION.md` §B C7a / §G / §I C7a / §J5.

---

## 0. Read attestation (NAMED docs read IN FULL before editing — no skim, no derivation)

- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — read §18.1 (PROJECT in-session spawn, 5 elements, client-native), §18.2 (unified backstop layer map: layer iii launcher `--disallowedTools` is C7a; layer ii `permissions.deny` recipe is C8a, NOT here), §18.4 (commit-scope for C7a), §4.1/§4.2 (merge-back flow + all-agents report-back), §5.1 (DENIED set), §5.2 (ALLOWED set + read-only-only principle line), §5.3 (where it lands — project trinity + 48 agent files + `agent-run.sh --disallowedTools` + the shipped-settings reconciliation: do NOT add a `worktree` key to shipped settings.json), §6 (conflict protocol), §7 (launcher feasibility — HEAD-basing PROVEN settings-independent FACT-1; cwd-scoping the open question; no `worktree` key in shipped settings), §17 (Check-36 carve-out, C0 landed), §12.2 (merge-back codified WHERE). Read §1–§16 for context (mode model FACT-1..5; merge-back 1+2+4; RW/RO).
- `PLAN-BD-197-WORKTREE-ISOLATION.md` — read §A (sequence), §B C7a (task list) + C7b/C8a/C8b boundary, §C/§D (full CI battery enumeration), §E, §F, §G (manifest regen flags — C7a stages a non-empty manifest, carved via C0), §H (enumerate-encoding-surfaces), §I C7a (rules-in-force row), §J (J3 Guard-C fold, J4 new-file gate, J5 probe outcomes), §K (out-of-scope).
- `RESEARCH-BD-197-INSESSION-BACKSTOP.md` — read F1–F5; F4 = the exact `--disallowedTools 'Bash(git <verb>:*)'` launcher flag (alias `--disallowed-tools`; deny rules not bypassed by `bypassPermissions`; one scoped rule per verb).
- Surfaces edited (all read before edit): `project-template/docs/pack/PM-CHAT.md` (`## Permission profiles`), `project-template/agent-run.sh` (full), `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (project trinity "No destructive operations"), the 48 `project-template/.{claude,codex,gemini}/agents/*` files, `project-template/skills/implementation/SKILL.md`.
- `CLAUDE.md ## Pack memory` (bd-pack-only-operational-rule, pack-project-separation, trinity rule, cross-cli-reference-normalization, regenerate-manifest-v11-surface, verify-full-ci-suite, edit-in-place) + curated memory files (feedback_bd_pack_only_operational_rule.md, feedback_pack_project_separation_of_concerns.md, feedback_cross_cli_reference_normalization.md, feedback_manifest_regen_on_v11_surface.md, feedback_verify_full_ci_suite.md), `/backlog/_rules.md`, `/changelog/_rules.md`.

---

## 1. Pre-flight check output (verbatim)

```
$ git rev-parse HEAD
a255718a6849fd78ddde66c5d0e685e5e0bc80f8
$ git rev-parse --abbrev-ref HEAD
v11-dev
$ git status   (start) → "nothing to commit, working tree clean"
```
Base contains all docs the caller named (RECONCILED design, PLAN, RESEARCH-INSESSION-BACKSTOP, the project surfaces). C0–C6b landed (Check-36 carve-out `_is_scope_neutral_generated` present; verified by direct module import, §6). Baseline `validate-pack.py` → exit 0, "PASSED — all checks clean". Regime IN-PLACE (no `/tmp` handoff dir in prompt).

---

## 2. Per-surface edits (before/after)

### 2.1 `project-template/docs/pack/PM-CHAT.md` — IN-SESSION Agent/Task-tool spawn instruction (§18.1, the 5 elements) — NEW subsection `### In-session agent spawning`

**Before:** `## Permission profiles` documented agent spawning ONLY via the `agent-run.sh` launcher (the per-profile flag blocks); ZERO in-session Agent/Task-tool spawn instruction (measured EE-11: 1 incidental `in-session` hit at line 606, unrelated to spawn). **+83 lines.** Inserted after `### Permission classes (read-write / read-only)`, before `### Profile assignment` (the natural home — the in-session spawn keys off the RW/RO classes declared just above).

**After (the 5 elements, authored CLIENT-NATIVE — "PM chat", client paths, project agent roster):**
1. **Two spawn paths.** (i) PRIMARY = IN-SESSION via the Agent/Task tool from the PM chat; (ii) SECONDARY = `./agent-run.sh <cli> --agent <name>` launcher (the human-driven path the flag blocks describe). The launcher remains the documented secondary path.
2. **`isolation:"worktree"` for RW agents only.** PM chat spawns RW agents (`coder`, `repo-ops`) in-session with `isolation:"worktree"` (the only valid value); RO agents (the 14 report-only profiles) spawned WITHOUT isolation. Keyed off the `## Permission profiles` RW/RO classification (D2 project SSOT) — "RW ⇒ isolate; RO ⇒ in-place."
3. **Background spawning.** "Spawn agents in the background so the PM chat stays interactive" — client-native phrasing; explicitly "The exact way to background a spawn is CLI-specific; use whatever your CLI offers" (NO pack-self `run_in_background` rule citation, per cross-cli-reference-normalization).
4. **The orchestrator `/tmp`-patch merge-back.** PM chat names a per-spawn `/tmp` handoff dir + report path + patch path; the RW agent edits, runs in-scope verification, emits `git diff > <handoff>/changes.patch` (read-only; the `> file` redirect is shell not a git verb) + writes its report, returns; PM chat reads, runs the review/fix cycle, `git apply --check`/`git apply`, commits with developer approval — "the agent performs zero state-changing git verbs." Handoff-write-failure fallback documented (degrade to in-place report path, never hard-error — §1.2 hardening).
5. **Conflict + degradation.** On `git apply --check` failure: try `git apply --3way`; if still conflicting STOP, surface, re-spawn a fresh `coder` against current HEAD; NO hand-merge. Degradation cases point at the project's own `docs/pack/OPTIONAL-FEATURES.md` (NOT a pack-self ref).

**No-platform-safety-net note (FACT-4):** explicit paragraph — "There is no platform safety net … two guarantees are load-bearing, not advisory: every read-write agent MUST be spawned with `isolation:"worktree"`, and the no-state-changing-git rule … is what keeps an isolated agent's work safe to merge back."

**NOT a byte-copy of PACK-CHAT.md** (authored independently for the client audience — pack-project-separation).

### 2.2 `project-template/agent-run.sh` — `--disallowedTools` hardening (§5.3 layer iii, F4) + the probe-gated `--worktree` launcher (§7, NEW-FORK-1)

**Hardening — `CLAUDE_READONLY_FLAGS` (before → after).** Before: `--disallowedTools "Bash(git commit:*)" "Bash(git push:*)"` (2 verbs). After: the full §5.1 set as one scoped `Bash(git <verb>:*)` rule per verb — `commit, push, add, mv, rm, stash, reset, restore, checkout, apply, worktree, clean, rebase, merge`. **VERB-PRECISE:** denies `Bash(git apply:*)`, NEVER `Bash(git diff:*)` (the agent's patch-emit must stay allowed). The block comment now states the verb-precision + the patch-emit rationale; the `--help` text updated to enumerate the denied set + "git diff stays allowed for patch emit." Shipped-settings reconciliation honored: NO `worktree` key added to `project-template/.claude/settings.json` (it still allows `Bash(git add *)` for the human/PM — verified §6); the agent ban is enforced by the agent Hard rule + these launcher flags, not settings.

**Launcher — `--worktree` (UC-SECONDARY, NEW-FORK-1 = gate-then-probe-then-degrade).** Added: (a) `--worktree [path]` argument parsing (optional path; claude-only — validated with a `die` if used on codex/gemini, since `claude --agent` in a worktree cwd is the launch path); (b) a `run_in_worktree()` helper that creates the worktree with `git worktree add --detach <path> HEAD` (HEAD-basing — PROVEN settings-independent, FACT-1) then runs `claude --agent <name>` with cwd inside it; (c) wired into the claude launch branch; (d) `--help` entry. **The cwd-scoping caveat + manual fallback are documented inline** in the `run_in_worktree` comment (I cannot run the `claude --agent` cwd-scoping probe — see §5 J6 surfacing): a 2-step in-environment probe recipe + the manual `git worktree add … && (cd … && claude --agent …)` fallback if the probe shows a git leak. The agent still never commits either way (the PM-chat patch merge-back applies its work). `bash -n` clean; `--help` renders the new flag.

### 2.3 Project trinity "No destructive operations" rule (CLAUDE.md / AGENTS.md / GEMINI.md) — verb-enumeration gap closed to §5.1; TRINITY RULE parallel ×3 in this commit

**Before:** "Before any `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`, or `git checkout -- <path>` … `git checkout --` is destructive …" **After (×3, byte-identical bodies — md5 `b532e6694107571e704da21837567bd6` across all three):** enumerates the working-tree-/ref-mutating verbs — `git reset` (any mode), `git restore`, `git checkout` (path or branch), `git clean`, `git stash`, `git merge`, `git rebase`, `git worktree` — PLUS the positive principle line ("read-only git verbs are allowed; any git verb that changes working-tree, index, ref, or config state is destructive … including but not limited to the ones enumerated here") PLUS a clarifier that agents go further (NO state-changing git verb at all; see the agent's definition file). **GEMINI approval-mode line preserved** (GEMINI.md line 471, untouched — verified §6). Client-native; no pack-self refs.

### 2.4 The 48 agent files' Hard rules + Codex permission-profile blocks — §5.1 verb gap closed + the `git checkout -- <path>` carve-out DROPPED

**Carve-out drop (the C6a-surfaced item).** The broken carve-out "except `git checkout -- <path>` to inspect file contents at a different ref" appeared in 42 of 48 files (16 claude + 10 codex + 16 gemini). It is SEMANTICALLY WRONG — `git checkout -- <path>` is destructive (discards working-tree changes), not a read-only inspect verb. **All 42 occurrences removed**; the correct read-only inspect verb (`git show <ref>:<path>`) substituted ("To inspect a file at a different ref, use the read-only `git show <ref>:<path>`, never a path checkout"). Per-CLI, prose-coherent (claude wrapped-line .md; gemini wrapped-line .md with 3 sub-variants; codex single-line .toml with backtick/no-backtick/Forbidden sub-variants). **`grep -rn 'checkout -- <path>'` over the 48 files = ZERO.** No orphan `(except)` fragments (verified §6).

**Verb gap closed (§5.1).** Every one of the 48 files' Hard rule now enumerates the full denied set including `restore, clean, apply, worktree` (the 6 terse codex auditor files that lacked the carve-out had the short verb list extended; `repo-ops.toml` had `git restore` added). Verified: `restore`/`clean`/`apply`/`worktree` present in ALL 48; zero adjacent-duplicate verbs (a transient `git stash` duplication introduced by the codex bulk-replace was caught + fixed in-pass, §3 + §6).

### 2.5 Project coder agent files ×3 — RW-emit step + no-platform-safety-net note (§12.2 project, FACT-4)

`project-template/.{claude,codex,gemini}/agents/coder.{md,toml}` each gained, in `## Permission profile`: (a) **"Merge-back: emit a patch, never commit"** — the regime-aware RW-emit step (isolated ⇒ `git diff > <handoff>/changes.patch` + report to `/tmp`; in-place ⇒ leave edits + emit `git diff` for auditability; handoff-write-failure fallback; "zero state-changing git verbs"); (b) **"No platform safety net — spawn isolation is load-bearing"** — RW agents NOT spawned isolated edit the main tree directly; the PM chat spawns with `isolation:"worktree"` AND the agent runs no state-changing git verb; both required, not optional. Client-native; per-CLI format (wrapped .md vs single-line .toml).

### 2.6 `project-template/skills/implementation/SKILL.md` — regime-aware report step (§12.2 project; §11.2 operational-mention redesign)

Added a new section "## Reporting the change set (regime-aware)" after step 15. In-place ⇒ change set is the working-tree diff against base HEAD; isolated ⇒ the `git diff > <handoff>/changes.patch` patch is the persisted artifact (survives worktree cleanup). Agent runs read-only git only (`git diff`, never `git apply`); applying + committing belong to the PM chat. Handoff-write-failure fallback documented. **+29 lines.** (Boundary note: see §8 — the project has NO `implementation-report` skill; the project-side report-step SSOT is this `implementation` skill, so the regime step landed here, not at the non-existent `project-template/skills/implementation-report/SKILL.md` the prompt/plan named.)

### 2.7 `test-fixtures/manifest.txt` — regenerated (forced co-variant; carved scope-neutral via C0)

Editing `project-template/` drifts 3 v11 fixture SHAs → manifest changed (3 +/3 -). Regenerated via `bash test-fixtures/build.sh --all --clean` (exit 0), KEPT (left MODIFIED — no `git add`, no `git checkout`), `build.sh --verify` exit 0. Carved scope-neutral by C0, so the `project-only` keyword holds (§4).

---

## 3. Plan deviations

- **D-1 (report-step skill target — boundary/SSOT correction).** The prompt + PLAN §B C7a named `project-template/skills/implementation-report/SKILL.md (+ mirrors)` for the regime-aware report step. **That skill does not exist on the project side** — only the PACK side has an `implementation-report` skill. The project-side SSOT for the coder report-emit step is `project-template/skills/implementation/SKILL.md` (steps 14–15) + the coder agent files. I landed the regime-aware report step in `project-template/skills/implementation/SKILL.md` (§2.6) + the coder agent files (§2.5) — the project-side homes that actually carry the report step — rather than create a new mis-named skill. This realizes the design's §12.2 intent ("the agent's emit patch + report step") at the correct project SSOT. Documented as a Boundary discipline finding (§8). NOT a scope change — same content, correct home.

- **D-2 (carve-out drop scope).** The prompt item 4 phrased the carve-out drop as the "project `coder.toml` `git checkout -- <path>` carve-out." Measurement showed the carve-out is in 42 of 48 agent files (not just coder.toml), and the verification criterion (`grep -rn 'checkout -- <path>'` over the project agent files = ZERO) requires dropping ALL of them. PLAN §B C7a line 141 ("48 agent files' Hard rules … close any verb gap") and §D manual-check (e) confirm the all-files scope. Dropped from all 42. Not a deviation from intent — the prompt's verification gate mandates the full sweep.

No other deviations. The mode model, merge-back (1+2+4), conflict protocol, no-platform-safety-net framing, and the `--disallowedTools`/launcher contracts were applied exactly as the design specifies.

---

## 4. ZERO pack-self refs + trinity parity + carve-out-gone + Check-36 carve-out (verification)

**ZERO pack-self refs in ADDED content (the `+` lines of my diff):**
```
git diff project-template/ | grep '^+' | grep -E 'BD-[0-9]+'                       → 0
git diff project-template/ | grep '^+' | grep -E 'maintenance-docs'               → 0
git diff project-template/ | grep '^+' | grep -E 'Pack Chat|Pack-Chat'            → 0
git diff project-template/ | grep '^+' | grep -E 'pack-ops'                       → 0
git diff project-template/ | grep '^+' | grep -E 'pack-(coder|architect|planner|reviewer|chat)' → 0
```
(Whole-file greps surface 3 `maintenance-docs` / 3 `pack-ops` / 2 `Pack Chat` hits — ALL pre-existing, untouched: the `maintenance-docs`/`pack-ops` hits are inside the canonical DENY-LIST-CONTENT block of the trinity "Project SSOT-first" rule — that IS the boundary deny-list, correct content, not my edit; the `Pack Chat` hits are in PM-CHAT.md's pre-existing Recommendation/feedback section, lines 342/344, not my in-session-spawn subsection.)

**Trinity parity (project "No destructive operations" rule):** byte-identical bodies across CLAUDE/AGENTS/GEMINI — md5 `b532e6694107571e704da21837567bd6` ×3. GEMINI approval-mode line preserved (`grep -c 'Approval mode:.*Gemini default mode'` = 1).

**Carve-out gone + prose-coherent:** `grep -rn 'checkout -- <path>'` over the 48 project agent files = 0; `grep -rn '(except)' / '(except '` = 0; `grep -rn 'checkout.*except|except.*checkout'` = 0; per-CLI read-back of representative files (codex terse auditor, gemini short auditor, claude long reviewer, codex Forbidden repo-ops) all read coherently with the full verb set + `git show <ref>:<path>` substitution.

**Check-36 (carve-out) over the actual commit file set** (55 paths = 54 project-template + manifest), evaluated against the live patched `validate-pack.py` predicate:
```
project_only OFFENDERS: []         (manifest scope-neutral? True)
=> Check-36 project_only PASS (no offenders)
```
The `project-only` keyword is clean; the manifest is exempt via C0's `_is_scope_neutral_generated`.

**Manifest regen:** non-empty diff (3 fixture SHAs drifted), KEPT (left MODIFIED, no `git add`/`git checkout`), `build.sh --verify` exit 0.

---

## 5. Launcher cwd-scoping probe — J6 user-visible outcome (NOT a C7a blocker)

**NEW-FORK-1 = gate-then-probe-then-degrade.** The `--worktree` launcher's HEAD-basing is PROVEN settings-independent (FACT-1: `git worktree add --detach <path> HEAD` bases at parent HEAD deterministically — no `baseRef` dependence). The remaining open question is **cwd-scoping**: does `claude --agent` launched with cwd inside a worktree keep ALL its git operations scoped to that worktree (vs leaking to the parent repo — the #55708 / Gemini #22658 leak class)?

**I CANNOT run this probe** — it requires launching `claude --agent`, which a coder cannot do. Per the gate-then-probe-then-degrade decision, I:
- SHIPPED the `--worktree` flag (the mechanism is implemented + `bash -n` clean + `--help`-documented + correctly claude-gated), AND
- DOCUMENTED the cwd-scoping caveat + a 2-step in-environment probe recipe + the manual-worktree fallback inline in the `run_in_worktree` comment, so a developer probes ONCE before relying on parallel isolated launches and degrades to the manual procedure if the probe fails.

**J6 SURFACED for the user/Pack Chat:** the cwd-scoping probe must be run in a live `claude --agent` environment (not by this coder) before the `--worktree` launcher is relied upon for parallel isolated runs. **It does NOT block C7a** — UC-1 (in-session Agent-tool spawn, §2.1) is the PRIMARY path and is unaffected by the launcher's cwd-scoping status. The C8a OPTIONAL-FEATURES doc (NOT this commit) will also reflect the probe-gated launcher vs the manual fallback.

---

## 6. FULL CI SUITE results (every wired script; exit statuses quoted; no sampling)

**`validate` job (2):**
- `python3 scripts/validate-pack.py` → **EXIT 0** — "PASSED — all checks clean"
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **EXIT 0** — "PASSED — all checks clean"

**`tests` job (every script, exit 0 unless noted):**
- `scripts/test-detect.sh` → **EXIT 0** (100 passed, 0 failed)
- `scripts/tests/template-translations-test.sh` (trinity/skill/agent parity ×3 CLIs) → **EXIT 0** (44 passed, 0 failed)
- `scripts/tests/template-version-test.sh` → **EXIT 0** (36 passed, 0 failed)
- `scripts/tests/test-issue-forms.sh` → **EXIT 0** (77 passed, 0 failed)
- `scripts/tests/test-v11-realistic-ot.sh` (banner pins) → **EXIT 0** (33/33 PASSED)
- `scripts/test-persona-contracts.sh` → **EXIT 0** ("All persona contracts PASS.")
- `scripts/test-migrator-skills.sh` → **EXIT 0** (19 passed, 0 failed)
- `scripts/tests/test-init-project.sh` → **EXIT 0** ("All tests passed.")
- `scripts/tests/test-customization-preserve.sh` → **EXIT 0** ("All tests passed.")
- `scripts/tests/pack-help-test.sh` → **EXIT 0** ("All tests passed.")
- `test-fixtures/build.sh --all --clean` → **EXIT 0**; then `test-fixtures/build.sh --verify` → **EXIT 0** (all fixtures OK)
- **Batch 1 (31 scripts, all EXIT 0):** tracker-provider-test, tracker-config-test, tracker-init-test, tracker-agent-read-test, tracker-migrate-forward-test, tracker-migrate-reverse-test, tracker-migrate-roundtrip-test, test-tracker-phase-task, test-tracker-links, test-tracker-cycle-check, tracker-errors-test, tracker-config-schema-test, recommendation-state-schema-test, test-per-entry, test-validate-pack-checks-32-33-34, test-validate-pack-checks-36-37-38, test-validate-pack-check-{39,40,41,18,16,19,42,43,44,45,46}, test-validate-pack-check-removed-doc-advisory, test-validate-pack-check-49-field-faithfulness, test-validate-pack-check-50-codec-single-source, test-validate-pack-check-51-flip-block. **Tally: pass=31 fail=0.**
- **Batch 2 (14 scripts, all EXIT 0):** tracker-deferral-gate-test, tracker-bd129-gh-repo-test, tracker-bd130-doctor-wired-test, tracker-bd132-race-test, tracker-bd133-header-preservation-test, tracker-bd134-close-retry-test, recommendation-test, test-migrate-v10-to-v11, test-migrate-v10-to-v11-dry-run, test-migrate-v10-to-v11-gates, test-migrate-v10-to-v11-decompose, test-migrator-core, test-migrator-manifest, test-migrator-capability-translation. **Tally: pass=14 fail=0.**

**No script in the wired battery failed.** `bash -n project-template/agent-run.sh` → SYNTAX OK.

**In-pass fix (caught + corrected before report):** the codex bulk carve-out replacement initially introduced a duplicated `git stash` token in 9 codex files (existing `git reset, git stash` + my fragment starting `git restore, git stash`). Detected by an adjacency-duplicate scan; fixed (`git reset, git stash, git restore, git checkout`); zero duplicates remain across all 48 files. The 6 terse codex auditors + repo-ops were also found missing `restore/clean/apply/worktree` and fixed in-pass.

---

## 7. Files changed inventory (55 files; all MODIFIED; nothing staged; HEAD unchanged)

- `project-template/docs/pack/PM-CHAT.md` — modified (+83; in-session spawn subsection)
- `project-template/agent-run.sh` — modified (+127/-… ; `--disallowedTools` hardening + `--worktree` launcher + help)
- `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` — modified (trinity "No destructive operations" verb-enum ×3)
- `project-template/skills/implementation/SKILL.md` — modified (+29; regime-aware report step)
- `project-template/.claude/agents/*.md` (16) — modified (carve-out drop + §5.1 verbs; coder.md also RW-emit + no-safety-net)
- `project-template/.codex/agents/*.toml` (16) — modified (carve-out drop + §5.1 verbs; coder.toml also RW-emit + no-safety-net)
- `project-template/.gemini/agents/*.md` (16) — modified (carve-out drop + §5.1 verbs; coder.md also RW-emit + no-safety-net)
- `test-fixtures/manifest.txt` — modified (regenerated; scope-neutral via C0)

Diff stat: **55 files changed, 486 insertions(+), 147 deletions(-).** Read-only `git diff` patch emitted to `/tmp/c7a-changes.patch` (1310 lines) for auditability. No new files. No deletions. **`git diff --cached` = empty (nothing staged). HEAD = `a255718a6849fd78ddde66c5d0e685e5e0bc80f8` (unchanged — agents never commit).**

---

## 8. Boundary discipline check (P-missed-7 — required for project-side edits)

Every edit is on the CLIENT surface (`project-template/`). For each, the project-side SSOT investigated:

- **PM-CHAT.md in-session spawn** — project-side SSOT = `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` (the project agent-spawn + RW/RO SSOT, D2). Authored client-native ("PM chat", `./agent-run.sh`, `docs/pack/OPTIONAL-FEATURES.md`). NO reach for `pack-ops/PACK-CHAT.md`, Pack Chat, or pack-* names.
- **Project trinity "No destructive operations"** — project-side SSOT = the project trinity `## Project memory` (universal collaboration rules). Edited in place ×3, client-native.
- **48 agent files + coder RW-emit** — project-side SSOT = each agent's own definition file (PM-CHAT.md names them authoritative). Client-native; `git show <ref>:<path>` is generic git, not pack-self.
- **Regime-aware report step (the one boundary correction).** The prompt/PLAN named `project-template/skills/implementation-report/SKILL.md` — **no such project-side skill exists** (only PACK has `implementation-report`). Investigated the project-side SSOT for the coder report-emit step: it is `project-template/skills/implementation/SKILL.md` (steps 14–15) + the coder agent files. Landed the regime step THERE (the correct project SSOT), NOT at the non-existent mis-named path and NOT by importing the pack `implementation-report` skill (which would be a client-install regression). **No SSOT exists at `skills/implementation-report/` for the project — implemented at the real project report-step SSOT (`skills/implementation/` + coder agent files) per the design's §12.2 intent.** Surfaced as plan deviation D-1.
- **`agent-run.sh` `--disallowedTools` + `--worktree`** — project-side SSOT = the shipped `project-template/agent-run.sh` (the project launcher) + `project-template/.claude/settings.json` (verified: allows `Bash(git add *)`, NO `worktree` key — left untouched per the design's shipped-settings reconciliation).

**No boundary-discipline STOP** — no edit added a reference to a pack-only file, a pack-* agent name, the `Pack Chat` orchestrator role, `pack-ops/`, or `maintenance-docs/`. (The pre-existing pack-only refs in the trinity DENY-LIST-CONTENT block are the boundary deny-list itself — correct content, untouched by this commit.)

---

## 9. Definition-of-Done checklist

| # | DoD item (from prompt) | PASS/FAIL | Evidence |
|---|---|---|---|
| 1 | PM-CHAT.md gains the in-session Agent/Task-tool spawn instruction (5 elements, client-native) | PASS | §2.1; new `### In-session agent spawning` subsection, +83 lines, 5 elements present |
| 2 | `isolation:"worktree"` for RW only; RO in-place; keyed to project RW/RO SSOT | PASS | §2.1 element 2; "RW ⇒ isolate; RO ⇒ in-place" keyed to `## Permission profiles` |
| 3 | Background spawning, client-native (no pack-self rule citation) | PASS | §2.1 element 3; "CLI-specific … whatever your CLI offers" |
| 4 | `/tmp`-patch merge-back (orchestrator names dirs; agent emits `git diff`; PM chat applies; agents never commit) | PASS | §2.1 element 4 |
| 5 | Conflict/degradation at the project's own homes | PASS | §2.1 element 5; points at `docs/pack/OPTIONAL-FEATURES.md`, no pack-self ref |
| 6 | No-platform-safety-net note (RW spawned isolated; verb-ban load-bearing) | PASS | §2.1 + §2.5; explicit paragraphs |
| 7 | `agent-run.sh --disallowedTools` extended to §5.1, verb-precise (deny apply, not diff) | PASS | §2.2; `git apply` denied, `git diff` NOT denied; `bash -n` OK |
| 8 | Shipped-settings reconciliation: NO `worktree` key in shipped settings.json | PASS | §2.2 + §6; `grep worktree settings.json` = 0; `git add` allow intact |
| 9 | Project trinity "No destructive operations" verb-enum closed to §5.1, parallel ×3, GEMINI line preserved | PASS | §2.3 + §4; md5 ×3 identical; approval-mode line count = 1 |
| 10 | 48 agent files' verb gap closed (restore/clean/apply/worktree in all) | PASS | §2.4 + §6; present in all 48; no dup verbs |
| 11 | `git checkout -- <path>` carve-out DROPPED across project agent files = ZERO; prose-coherent | PASS | §2.4 + §4; `grep -rn 'checkout -- <path>'` = 0; no orphan `(except)`; read-back coherent |
| 12 | coder.* RW-emit step (patch + report to handoff dir) ×3 | PASS | §2.5 |
| 13 | impl-report skill regime-aware report step | PASS | §2.6 (landed at the real project report-step SSOT — D-1) |
| 14 | `--worktree` launcher implemented (HEAD-basing) + cwd-scoping caveat + manual fallback | PASS | §2.2 + §5; `run_in_worktree`; `bash -n` OK; help renders |
| 15 | Launcher cwd-scoping probe surfaced as a J6 user-visible outcome (not a blocker) | PASS | §5 |
| 16 | Manifest regenerated (non-empty), KEPT, no `git checkout`/`git add`, `build.sh --verify` green | PASS | §2.7 + §6 |
| 17 | Check-36 carve-out: `project-only` commit of {edits + manifest} has no offenders | PASS | §4; offenders `[]` |
| 18 | ZERO pack-self refs in every project-template edit | PASS | §4; all added-line greps = 0 |
| 19 | FULL CI suite green (no sampling) | PASS | §6; validate ×2 + every tests-job script EXIT 0 |
| 20 | C7a scope only (NOT C7b/C8a/C8b; no pack-side edits; no `permissions.deny` recipe) | PASS | §10; no `scripts/` edit, no OPTIONAL-FEATURES edit, no `permissions.deny` |

---

## 10. Scope adherence (NOT C7b / C8a / C8b; no pack-side; no `permissions.deny` recipe)

- **C7b (verb-parity guard extension)** — NOT done (it is a `scripts/validate-pack.py` GUARD half, pack-only).
- **C8a (project OPTIONAL-FEATURES + the `permissions.deny` recipe)** — NOT done. The documented-optional `permissions.deny` recipe (§18.2 layer ii) is C8a, NOT here; I added only layer iii (`agent-run.sh --disallowedTools`) and layer i (prose deny-list across trinity + agent files). No edit to `project-template/docs/pack/OPTIONAL-FEATURES.md`.
- **C8b (Guard-A′)** — NOT done.
- **No pack-side surfaces touched** — diff is exclusively `project-template/` + `test-fixtures/manifest.txt` (the C0 scope-neutral carve-out). No `pack-ops/`, no `.claude/`/`.codex/`/`.gemini/` (pack-root), no `scripts/`.
- **No `worktree` key added to shipped settings.json.**

---

## 11. Proposed commit message

```
feat: v11 — BD-197 C7a project in-session spawn + merge-back + git-permission hardening + launcher (DATA, project-only)
```

---

## 12. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | bd-pack-only-operational-rule | `git diff project-template/ \| grep '^+' \| grep -E 'BD-[0-9]+\|maintenance-docs\|Pack Chat\|pack-ops\|pack-(coder\|architect\|planner\|reviewer\|chat)'` → ALL 0 added-line hits (§4). Pre-existing whole-file hits are the trinity DENY-LIST-CONTENT block + PM-CHAT recommendation section (untouched). | COMPLIANT |
| 2 | pack-project-separation-of-concerns | PM-CHAT.md in-session subsection authored CLIENT-NATIVE ("PM chat", `./agent-run.sh`, `docs/pack/OPTIONAL-FEATURES.md`), NOT a byte-copy of PACK-CHAT.md (§2.1). coder RW-emit + skill regime step + trinity rule all client-native. No pack artifact used as a fallback. | COMPLIANT |
| 3 | trinity rule | Project "No destructive operations" rule edited in CLAUDE.md + AGENTS.md + GEMINI.md in THIS commit; bodies byte-identical (md5 `b532e6694107571e704da21837567bd6` ×3, §4); GEMINI approval-mode line preserved (`grep -c` = 1). | COMPLIANT |
| 4 | cross-cli-reference-normalization | Carve-out drop authored per-CLI (claude/gemini wrapped .md; codex single-line .toml backtick/no-backtick/Forbidden sub-variants), NOT byte-copied; coder RW-emit + no-safety-net authored per-CLI format; PM-CHAT background-spawn phrasing client-native ("CLI offers"), no pack `run_in_background` citation. Read-back coherent (§6). | COMPLIANT |
| 5 | regenerate-manifest-v11-surface | `bash test-fixtures/build.sh --all --clean` EXIT 0; manifest changed (3+/3-, non-empty); KEPT (left MODIFIED, no `git add`/`git checkout`); `build.sh --verify` EXIT 0 (§2.7 + §6). | COMPLIANT |
| 6 | verify-full-ci-suite | validate-pack ×2 EXIT 0 + EVERY tests-job script EXIT 0 (template-translations 44/44, test-v11-realistic-ot 33/33, fixture build+verify, + batch1 31/0 + batch2 14/0 + 6 standalone) — exit statuses quoted §6; no sampling. | COMPLIANT |
| 7 | edit-in-place-not-full-rewrite | All edits targeted (Edit tool for unique strings; Python exact-string replace for the 42-occurrence-identical carve-out drop, each asserting occurrence-count). No wholesale rewrite of PM-CHAT.md / agent-run.sh / trinity / agent / skill files. Sections re-read after edit (§2). | COMPLIANT |
| 8 | empirical-evidence-blocks | Every state-claim backed by command + verbatim output (baseline 42 carve-out / 0 after; trinity md5 ×3; Check-36 offenders `[]`; CI exit codes; manifest sha before/after) at HEAD `a255718…`, date 2026-06-14 (§1/§4/§6). | COMPLIANT |
| 9 | preflight-stop-means-stop | PREFLIGHT line emitted in chat immediately before this Write, only after ALL edits + the FULL battery PASSED. No parent stop/halt received during the pass. | COMPLIANT |
| 10 | agents-never-commit | Ran NO state-changing git verb: only `git rev-parse`/`git status`/`git diff`/`git log`/`git diff --name-only`/`git diff --cached` (reads). Manifest restored-via-build (cp/build), never `git checkout`. `git diff --cached` = empty; HEAD unchanged `a255718a6849fd78ddde66c5d0e685e5e0bc80f8` (§6/§7). | COMPLIANT |
| 11 | scope-deliverables-to-the-ask | C7a DATA half only: PM-CHAT in-session, agent-run.sh hardening + launcher, trinity verb-rule ×3, 48-agent verb-close + carve-out drop, coder RW-emit, skill regime step, manifest. NOT C7b/C8a/C8b; no `permissions.deny` recipe; no pack-side edit; no `worktree` key in shipped settings. Launcher cwd-scoping surfaced as J6 (§5/§10). | COMPLIANT |
| 12 | rules-applied-verification-block | This table; every row carries quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

*End of IMPL-REPORT-BD-197-C7a.md — IN-PLACE regime; 55 files modified, nothing staged, HEAD `a255718a6849fd78ddde66c5d0e685e5e0bc80f8` unchanged; full CI battery green; read-only patch at `/tmp/c7a-changes.patch`.*
