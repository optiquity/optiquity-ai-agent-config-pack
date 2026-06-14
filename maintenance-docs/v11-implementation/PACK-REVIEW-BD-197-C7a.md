# PACK-REVIEW — BD-197 C7a (PROJECT in-session spawn + merge-back + git-permission hardening + launcher; the DATA half)

**Reviewer:** fresh pack-reviewer. **Commit:** C7a (`project-only`). **Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**HEAD at review:** `a255718a6849fd78ddde66c5d0e685e5e0bc80f8`. **Date:** 2026-06-14. **Regime:** IN-PLACE (cwd = main `v11-dev` worktree, not a `worktree-agent-*` path).
**Method:** INDEPENDENT re-verification — every claim re-run; the IMPL-REPORT was NOT trusted. 55-file scope (54 `project-template/` + `test-fixtures/manifest.txt`).

---

## VERDICT: APPROVE

C7a lands all five §18.1 in-session-spawn elements client-native, drops the 42-occurrence broken carve-out to ZERO with verb-precise hardening, keeps trinity parity byte-identical, regenerates the manifest, ships the probe-gated `--worktree` launcher, introduces ZERO pack-self refs, and is scope-clean (`project-only`, no C7b/C8, no shipped-settings worktree key) with the full CI battery green on independent re-run. The single deviation (D-1) is a correct boundary call, not a defect.

---

## Read attestation

Read IN FULL before applying the checklist: `review` / `architecture-review` / `commit-discipline` skills; design `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §4.1/§4.2 (merge-back + RW/RO), §5.1/§5.2/§5.3 (denylist + read-only-only principle + where it lands + backstop verb-precision G-4), §6 (conflict), §7 (launcher feasibility/NEW-FORK-1), §12.2 (mechanism homes — note it names `skills/implementation-report/SKILL.md`), §18.1 (the 5 elements) + §18.2/§18.4 (backstop layers + C7a commit-scope); `PLAN-BD-197-WORKTREE-ISOLATION.md` §B C7a (incl. lines 136–144) + C7b/C8a/C8b boundary; `IMPL-REPORT-BD-197-C7a.md`; `CLAUDE.md ## Pack memory` (incl. P-missed-7 / boundary-investigation, bd-pack-only-operational-rule, pack-project-separation, trinity, cross-cli-reference-normalization, regenerate-manifest, verify-full-ci-suite); `/backlog/_rules.md` + `/changelog/_rules.md` (not in C7a scope — no entry edits expected, none found).

---

## Explicit verdicts on the four headline items

### (a) In-session-spawn gap-closure — VERDICT: GENUINELY CLOSED (PASS)

`project-template/docs/pack/PM-CHAT.md` gains a new `### In-session agent spawning` subsection (lines 449–530), placed between `### Permission classes` and `### Profile assignment` (the natural RW/RO home). All five §18.1 elements present + the no-platform-safety-net note:

| §18.1 element | Location | Evidence |
|---|---|---|
| 1. Two spawn paths (in-session PRIMARY + `agent-run.sh` SECONDARY) | 454–466 | "In-session via the Agent/Task tool (PRIMARY)" + "Via the `agent-run.sh` launcher (SECONDARY)" |
| 2. `isolation:"worktree"` for RW only, keyed to RW/RO SSOT | 468–478 | "Isolation is for read-write agents only … RW ⇒ isolate; RO ⇒ in-place. Read the permission-class table above" |
| 3. Background spawning, client-native | 489–493 | "The exact way to background a spawn is CLI-specific; use whatever your CLI offers" — NO `run_in_background` pack-self citation |
| 4. `/tmp`-patch merge-back | 495–518 | names handoff dir + report + patch path; agent `git diff > <handoff>/changes.patch`; PM chat `git apply --check`/apply + commit; "agents never stage, apply, or commit" |
| 5. Conflict + degradation at project homes | 520–530 | `git apply --3way` → STOP → re-spawn fresh coder; degradation cases point at `docs/pack/OPTIONAL-FEATURES.md` |
| No-platform-safety-net note (FACT-4) | 480–487 | "There is **no platform safety net** … two guarantees are **load-bearing, not advisory**" |

Authored CLIENT-NATIVE — "PM chat", `./agent-run.sh`, `docs/pack/OPTIONAL-FEATURES.md`. NOT a byte-copy of PACK-CHAT.md. The under-scope §18.E EB-A flagged (PM-CHAT documented spawning ONLY via the launcher) is closed.

### (b) D-1 boundary correction — VERDICT: CORRECT CALL (PASS)

The plan §B C7a line 138 and design §12.2 both named `project-template/skills/implementation-report/SKILL.md (+ mirrors)` for the regime-aware report step. Re-verified independently:

- `ls -d project-template/skills/implementation-report` → **No such file or directory** (does NOT exist).
- `ls -d project-template/skills/implementation` → **exists**.
- `implementation-report` exists ONLY on the PACK side: `./.claude/skills/implementation-report`, `./.codex/...`, `./.gemini/...` (and is referenced by pack-only `validate-pack.py` Check-46 surface list at line 6937 as a pack skill).
- Project skills are a SINGLE canonical tree (`project-template/skills/<name>/`); they are NOT per-CLI quads — `project-template/.claude/skills/` carries only `pack-help` + `pm-startup`. So editing the one `implementation/SKILL.md` is the complete edit — no mirror obligation.

The coder landed the regime-aware report step at `project-template/skills/implementation/SKILL.md` (new `## Reporting the change set (regime-aware)` section, lines 34–60, both regimes, client-native, `git diff`/`git apply` contract correct) + the three coder agent files (RW-emit step). Importing the pack `implementation-report` skill name into the project would have been a client-install regression (the pack repo is not present at a client install) — exactly the P-missed-7 failure mode. **The deviation is the right call; the design/plan named a non-existent project surface, and the coder correctly routed to the real project SSOT.** No content was lost; §12.2 intent is realized at the correct home.

### (c) Carve-out 42→0 + verb hardening — VERDICT: PASS

- `grep -rn 'checkout -- <path>' project-template/` → **0** (baseline at HEAD: 16 `.claude` + 10 `.codex` + 16 `.gemini` = **42**). All 42 dropped.
- No orphan fragments: `(except` → 0; `except.*checkout|checkout.*except` → 0.
- Replacement `git show <ref>:<path>` present in all **48/48** agent files; prose-coherent per-CLI (the 6 "checkout … inspect" hits are the intended substitution prose, not residue).
- `git checkout` stays DENIED: 42 space-form files name it as forbidden; the 6 terse codex auditors name it slash-form (`…/checkout/clean/apply/worktree`); trinity names it twice each.
- §5.1 verb-gap closed — `restore`/`clean`/`apply`/`worktree` present in all **48/48** (space-form in 42, slash-form in the 6 codex auditors; 0 missing across all 48 in either form). The 6 codex auditors were correctly extended (`reset/stash/checkout` → `reset/restore/stash/checkout/clean/apply/worktree`).
- No adjacent-duplicate verbs (python scan over 48 files = **0** — the coder's in-pass `git stash` dedup held).
- All 16 codex `.toml` files parse cleanly (`tomllib`).
- `agent-run.sh` `CLAUDE_READONLY_FLAGS` (lines 105–113) is VERB-PRECISE: 14 scoped `Bash(git <verb>:*)` rules (`commit,push,add,mv,rm,stash,reset,restore,checkout,apply,worktree,clean,rebase,merge`) — denies `apply`, **`Bash(git diff` count = 0** (diff never denied). Comment (91–104) + `--help` (160–175) document the verb-precision + patch-emit rationale. `bash -n` OK.
- Shipped `project-template/.claude/settings.json`: NO `worktree` key; `Bash(git add *)` allow preserved (line 16).

### (d) J6 launcher — VERDICT: PASS (correctly probe-pending, non-blocking)

`--worktree` launcher implemented: `run_in_worktree()` (lines 264–294) creates `git worktree add --detach <path> HEAD` (HEAD-basing, settings-independent per FACT-1), runs `claude --agent` with cwd inside it; claude-only gate (`die` on non-claude, lines 491–492); cwd-scoping caveat + 2-step probe recipe + manual `git worktree add … && (cd … && claude --agent …)` fallback documented inline (gate-then-probe-then-degrade, lines 246–263); `--help` renders the flag; client-native references (`docs/pack/PM-CHAT.md`, `docs/pack/OPTIONAL-FEATURES.md`), no pack-self refs; `bash -n` OK. The cwd-scoping probe is correctly surfaced as a user-visible outcome (IMPL §5), NOT a C7a blocker — UC-1 (the in-session Agent-tool path) is the PRIMARY path and is independent of the launcher's cwd-scoping status. (Note: the launcher itself runs `git worktree add` — this is the human-driven launcher invoked by the developer, not an agent running a git verb; consistent with §7/J6 UC-SECONDARY. The agents-never-commit ban targets the agent, which here only runs `claude --agent`.)

---

## Independent re-verification of the prompt checklist

| # | Check | Result |
|---|---|---|
| 1 | In-session spawn (5 elements + no-safety-net, client-native) | PASS — PM-CHAT.md 449–530 (table above) |
| 2 | D-1 boundary correction | PASS — implementation-report absent project-side / present pack-side; landed at `skills/implementation/` + coder files; correct P-missed-7 call |
| 3 | git-permission hardening (full §5.1, verb-precise, no shipped worktree key) | PASS — 14 deny rules, `apply` denied / `diff` allowed, settings.json no worktree key |
| 4 | Trinity parity ("No destructive operations" ×3, GEMINI approval line) | PASS — rule body byte-identical md5 `d9774bdba7902235895d9b993f2ca2f8` (1043 chars) ×3; GEMINI approval-mode line count = 1 (line 480) |
| 5 | Carve-out drop 42→0; replacement coherent; checkout still denied; no dup verbs | PASS — see (c) |
| 6 | ZERO pack-self refs in added lines | PASS — `BD-`/`maintenance-docs`/`Pack Chat`/`pack-ops`/`pack-(coder|architect|planner|reviewer|chat|docs-researcher)` all 0 on `git diff project-template/ \| grep '^+'` (excluding `+++` headers) |
| 7 | Manifest regenerated, kept, build.sh --verify green; Check-36 no offenders | PASS — manifest matches fresh `build.sh --all --clean` (3+/3-), MODIFIED/kept, `--verify` exit 0; live Check-36 predicate over 55 files → offenders `[]`, manifest `_is_scope_neutral_generated`=True |
| 8 | Full CI green (independent) | PASS — see CI table below |
| 9 | J6 launcher (probe-gated, documented, non-blocking) | PASS — see (d) |
| 10 | Scope: only project-template + manifest + IMPL-REPORT; no pack-side; no C7b/C8; no worktree key | PASS — `git status --short` clean to scope; no `scripts/`, no OPTIONAL-FEATURES, no `permissions.deny` recipe (count 0), no pack-root `.claude/.codex/.gemini` |

### CI battery (re-run at HEAD `a255718…`, 2026-06-14)

| Script | Exit | Result |
|---|---|---|
| `validate-pack.py` | 0 | PASSED — all checks clean |
| `PACK_VALIDATE_DEEP=1 validate-pack.py` | 0 | PASSED — all checks clean |
| `template-translations-test.sh` (trinity/skill/agent parity ×3 CLIs) | 0 | 44 passed, 0 failed |
| `test-v11-realistic-ot.sh` (banner pins) | 0 | 33/33 PASSED |
| `template-version-test.sh` | 0 | 36 passed, 0 failed |
| `test-init-project.sh` | 0 | All tests passed |
| `test-customization-preserve.sh` | 0 | All tests passed |
| `test-persona-contracts.sh` | 0 | All persona contracts PASS |
| `test-fixtures/build.sh --verify` | 0 | all fixtures OK |
| `agent-run.sh --help` | — | renders `--worktree`; `bash -n` OK |

No non-reproduction. Every claim in the IMPL-REPORT that I re-ran reproduced.

---

## Findings

**No BLOCKER, MUST, or SHOULD findings.**

### NIT-1 (advisory, NOT introduced by C7a — pre-existing, out of scope)

`project-template/docs/pack/PM-CHAT.md` lines 342/344 carry pre-existing "the Pack Chat" references in the PACK-FEEDBACK-flow prose. Re-verified these are NOT touched by the C7a diff (`git diff … | grep '^[+-].*Pack Chat'` = empty) and are pre-existing project-shipped content describing the upstream-feedback-to-pack channel. C7a's new in-session subsection has zero "Pack Chat" hits. No action required for C7a; flagged only for completeness — if a future pass audits client-shipped pack-self references, these two lines are candidates, but they are unrelated to this commit and the IMPL-REPORT correctly identified them as pre-existing.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured, HEAD `a255718…`, 2026-06-14) | Conclusion |
|---|---|---|---|
| 1 | bd-pack-only-operational-rule | `git diff project-template/ \| grep '^+' \| grep -v '^+++' \| grep -E '<pattern>'` → BD- 0, maintenance-docs 0, Pack Chat 0, pack-ops 0, pack-* agent names 0. No pack-self concept in any added line. | COMPLIANT |
| 2 | pack-project-separation-of-concerns | PM-CHAT in-session subsection client-native ("PM chat", `./agent-run.sh`, `docs/pack/OPTIONAL-FEATURES.md`), NOT a byte-copy of PACK-CHAT.md. D-1: `implementation-report` absent project-side / present only pack-side → coder used the real project SSOT `skills/implementation/`, did NOT import the pack skill (would be a client-install regression). | COMPLIANT |
| 3 | trinity rule | "No destructive operations" rule body byte-identical across CLAUDE/AGENTS/GEMINI (`diff` IDENTICAL ×2; md5 `d9774bdba7902235895d9b993f2ca2f8`, 1043 chars). GEMINI approval-mode line preserved (`grep -c` = 1, line 480). `git checkout` named destructive in all three. | COMPLIANT |
| 4 | cross-cli-reference-normalization | Carve-out drop authored per-CLI (42 space-form `.md`/`.toml` + 6 slash-form codex auditors); replacement `git show <ref>:<path>` coherent in all 48; coder RW-emit + no-safety-net authored per-CLI format (wrapped .md vs single-line .toml); background-spawn phrasing client-native ("whatever your CLI offers"), no `run_in_background` citation. | COMPLIANT |
| 5 | regenerate-manifest-v11-surface | Working-tree manifest == fresh `bash test-fixtures/build.sh --all --clean` (exit 0); MODIFIED/kept (3+/3-, non-empty); `build.sh --verify` exit 0 (3 fixtures OK). | COMPLIANT |
| 6 | verify-full-ci-suite | validate-pack ×2 + template-translations 44/0 + test-v11-realistic-ot 33/33 + template-version 36/0 + init-project + customization-preserve + persona-contracts + fixture verify — all EXIT 0 (CI table). Banner-pin integration + trinity/skill/agent parity ×3 CLIs included, not sampled away. | COMPLIANT |
| 7 | empirical-evidence-blocks | Every verdict backed by re-run command + verbatim output + HEAD `a255718…` + date 2026-06-14 (carve-out 42→0; md5 ×3; Check-36 offenders `[]`; CI exits; manifest fresh-regen match). | COMPLIANT |
| 8 | scope-deliverables-to-the-ask | C7a = project DATA half only. Verdicts on (a) in-session gap, (b) D-1, (c) carve-out+hardening, (d) J6 delivered. D-1 deviation assessed (justified). No invented nits; the one NIT is explicitly pre-existing/out-of-scope. Scope re-verified: no C7b/C8, no pack-side, no `permissions.deny` recipe, no shipped worktree key. | COMPLIANT |
| 9 | agents-never-commit | Ran ONLY read-only git (`status`, `diff`, `rev-parse`, `log`, `grep`, `show`-class) + read-only tests + `bash test-fixtures/build.sh` (cp/build, not a git verb; output byte-identical to coder's, no state introduced). NO state-changing git verb. Single file write = this report. | COMPLIANT |
| 10 | rules-applied-verification-block | This table; every row carries quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

*End of PACK-REVIEW-BD-197-C7a.md — VERDICT APPROVE; HEAD `a255718a6849fd78ddde66c5d0e685e5e0bc80f8`; full CI battery green on independent re-run; carve-out 42→0; ZERO pack-self refs; trinity byte-identical ×3; `project-only` Check-36 clean; D-1 a correct boundary call; J6 launcher correctly probe-pending.*
