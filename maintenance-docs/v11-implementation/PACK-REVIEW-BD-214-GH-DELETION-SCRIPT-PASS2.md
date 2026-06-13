# PACK-REVIEW — BD-214 GH-issue-deletion one-off script, PASS-2 (final, post-FIX-1)

- **Reviewer:** fresh pack-reviewer (final pass), read-only.
- **Date:** 2026-06-13. **Branch:** `v11-dev`. **HEAD (read-only):** `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`.
- **Target reviewed (NOT committed; lives in /tmp ONLY per BD-214 §7 D-I):** `/tmp/bd214-gh-issue-deletion.sh`.
- **Fixes verified:** BLOCKER-1, SHOULD-1, SHOULD-2, NIT-1 (+ NIT-2/NIT-3 side-effects), per `IMPL-REPORT-BD-214-GH-DELETION-SCRIPT-FIX1.md`.
- **Spec sources read in full:** `RESEARCH-BD-212-GH-ISSUE-DELETION.md` §5 (rate-limit rules) + §6 (classifier); `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` §7 (delete-loop mechanics).
- **`--execute` was NEVER run.** Only the default read-only dry-run + stubbed-`gh` /tmp harnesses (no real mutations). The real deletion remains HELD for an explicit user GO.

---

## VERDICT: SAFE-TO-EXECUTE (under its gated confirmation)

All four fixes are correctly implemented and empirically proven. No proven-safe property from pass-1 regressed. The adversarial re-hunt for over-deletion / repo-deletion / default-label deletion / accidental `--execute` / target-redirect found NONE. Zero BLOCKER / MUST / SHOULD findings. One NIT (advisory, non-blocking) recorded below.

The dry-run is non-mutating (repo counts before == after, quoted), the candidate set matches the §7 decision-of-record exactly (213 issues + 49 labels + 0 stray), and the destructive path stays gated behind both `--execute` AND a typed confirmation phrase.

---

## Fix verification (all four)

### BLOCKER-1 — fail-loud terminal stop now halts the WHOLE script — FIXED, PROVEN

The delete loop was restructured from `printf | while … done` (subshell — `die`/`exit 1` killed only the subshell, `main` fell through to `delete_labels`/`verify_after`) to the **process-substitution redirect form** `while … done < <(printf …)` (script L356–411), so the body runs in the **parent shell**. A loop `die` now `exit 1`s the whole process.

Empirical repro — a harness mirroring the FIXED `delete_issues` loop (redirect form, real classifier branches) with a stubbed `gh` returning a `FORBIDDEN` `errors[].type` on issue #102, followed by stub `delete_labels`/`verify_after`/`MAIN END`:

```
  [1/2] #101 -> DELETED
ERROR: TERMINAL: deleteIssue returned FORBIDDEN on #102. STOP (no labels deleted).
=== script-exit-rc=1 ===
```

`delete_labels`, `verify_after`, and `MAIN END` did NOT print → the FORBIDDEN halted the whole script BEFORE label deletion. This is the exact BLOCKER-1 contract (RESEARCH §6 "FORBIDDEN-class → terminal fail-loud"; ARCHITECTURE §7 step 4 "FORBIDDEN-class → terminal stop").

Parent-shell counter survival (NIT-2) — harness, all NOT_FOUND, counters read AFTER the loop:

```
after-loop counters: deleted=0 skipped=3 failed=0
```

Counters survive the loop (proving parent-shell execution). `local` now lives legitimately inside the `delete_issues`/`delete_labels` function bodies (NIT-3), confirmed by `bash -n` SYNTAX OK under the real default `bash 3.2.57` and by the clean real dry-run.

Exhausted-rate-limit terminal abort — harness, stub `gh` perpetually RATE_LIMITED, `BACKOFF_MAX_TRIES=5`:

```
  attempt 1/5 ... 5/5 waiting 0s
ERROR: rate limited on #101 after 5 backoff attempts; re-run to resume.
=== rl-exit-rc=1 ===
```

Exhausted backoff fires a terminal `die` (rc=1) BEFORE `delete_labels` — same parent-shell halt guarantee (script L381–383).

### SHOULD-1 — rate-limit: retry-after → x-ratelimit-reset → exponential backoff — FIXED, PROVEN

The flat 60s wait was replaced by `ratelimit_wait_secs(hdrs, fallback)` (script L79–100) honoring the RESEARCH §5.5 priority order. Unit tests against the verbatim function:

```
1. retry-after:42 (+ remaining:0/reset far)  -> 42    (retry-after wins)
2. remaining:0 + reset=now+120, no retry     -> 120   (reset - now)
3. no headers, fallback 300                   -> 300   (exp-backoff fallback)
4. fallback 2000 (> cap)                       -> 900   (BACKOFF_MAX_SEC cap)
5. retry-after:17 only                         -> 17
6. remaining:5 (nonzero) + reset far          -> 60    (ignores reset, uses fallback)
```

`is_rate_limited` classifier (script L105–107):

```
{"errors":[{"type":"RATE_LIMITED"}]}        -> [1]
secondary rate limit / abuse detection      -> [1]
{"errors":[{"type":"NOT_FOUND"}]}           -> [NONE]
forbidden                                   -> [NONE]
```

The issue loop (L362–393) retries the SAME issue, fetching fresh headers read-only via `gh api -i rate_limit`, doubling the fallback per attempt (`backoff = backoff * 2`, capped at `BACKOFF_MAX_SEC`), up to `BACKOFF_MAX_TRIES`. Constants `BACKOFF_BASE_SEC=60` (§5.5 "at least one minute") / `BACKOFF_MAX_SEC=900` / `BACKOFF_MAX_TRIES=5` (L52–54). This is real behavior change driven by live headers, not a comment. Matches RESEARCH §5.5 and ARCHITECTURE §7 step 4 exactly.

### SHOULD-2 — label loop classifies errors like the issue loop — FIXED, PROVEN

The label loop (L435–473) is now the redirect form (parent-shell body, so `die` halts) with the SAME error classification as the issue loop. Harness driving the verbatim classifier body across all branches:

```
MODE=forbidden  -> ERROR: TERMINAL: label delete permission error ...; rc=1   (verify_after NOT reached)
MODE=notfound   -> "label already gone (idempotent)" x2; loop complete; rc=0  (idempotent skip)
MODE=other      -> "label FAILED (non-terminal)" x2; ERROR: 2 failed; rc=1    (fail-loud at end)
MODE=ok         -> "label DELETED" x2; loop complete; rc=0
```

FORBIDDEN-class (`*forbidden* / *403* / *must have admin* / *permission* / *insufficient*`, L462) → terminal `die`; not-found (`*not found* / *404*`) → idempotent skip; rate-limit → shared backoff (L445–456); any other error → counted + fail-loud `die` at end (L474–476). No longer swallows all failures. Matches the issue-loop classifier per RESEARCH §6.

### NIT-1 — 410-Gone spot-check is authoritative; search count is advisory — FIXED

`verify_after` (L481–515): the `search/issues` count is now labeled `[ADVISORY, may lag the search index]` with the explicit note "A non-zero count here is NOT a failure" (L489–491). The per-issue REST 410-Gone spot-check is labeled `[AUTHORITATIVE]` and emits an explicit verdict — `PASS` on a 410, else `CHECK — … investigate (a 200/301 means the issue was NOT deleted)` (L503–509). The hard verdict rests on the 410 check per RESEARCH §4. Correct.

---

## Re-validated read-only dry-run (verbatim)

`bash -n /tmp/bd214-gh-issue-deletion.sh` → SYNTAX OK (under real default `GNU bash 3.2.57`; process substitution is bash-only and works on 3.2 — confirmed).

### Baseline (BEFORE running the fixed script)

```
issues total       : 213
issues bd-entry    : 213
labels total       : 58
labels pack-managed: 49
```

### The fixed script's own dry-run (default path, no flags)

```
mode  : DRY-RUN (read-only, DEFAULT)
PREFLIGHT
  auth: account DShaneNYC present, 'repo' scope present.
  repo: DShaneNYC/optiquity-ai-agent-config-pack viewerCanAdminister=true.
SNAPSHOT (issues) -> /tmp/bd214-gh-issue-deletion-manifest-20260613T183959Z.json
  captured 213 issues into manifest.
SNAPSHOT (labels)
  captured 58 labels into manifest.
SAFETY GATE
  total issues in repo : 213
  candidate issues     : 213 (bd-entry label OR pack-id marker)
  STRAY (non-candidate): 0
  total labels in repo : 58
  pack-managed labels  : 49
  GitHub default labels: 9 (will NOT be touched)
  Safety gate PASSED: zero stray issues.
PREVIEW — what WOULD be deleted
ISSUES TO DELETE: 213
LABELS TO DELETE: 49
DRY-RUN COMPLETE. Nothing was mutated.
=== dry-run-exit-rc=0 ===
```

Candidate set = **213 marker-bearing issues + 49 pack-managed labels + 0 stray** — exactly the §7 / EE-4 decision-of-record. The 49 LABELS TO DELETE are all pack-managed (`bd-entry`, `status:*`, `type:*`, `scope:*`, `template:*`, etc.); the 9 GitHub defaults are not listed.

### Repo PROVEN unchanged (AFTER the dry-run)

```
issues total       : 213   (was 213)
issues bd-entry    : 213   (was 213)
labels total       : 58    (was 58)
labels pack-managed: 49    (was 49)
```

Issue/label counts before == after. Nothing was mutated. `--execute` was NEVER passed.

---

## Adversarial safety re-hunt (no path to over-deletion / repo-delete / default-label / accidental execute)

| Attack surface | Finding | Evidence |
|---|---|---|
| Repo deletion | NONE. Only mutating `gh` verbs are `deleteIssue` (by node ID) and `gh label delete`. The only `repo delete` token is the L26 prose safety comment. | `grep -nE 'repo delete\|gh repo (delete\|del)\|deleteRepository'` → only L26 comment |
| Over-deletion (non-candidate issue) | NONE. `delete_issues` input is built ONLY from `is_candidate` manifest rows (L337–344); `safety_gate` hard-stops (rc=2 → `die`) if ANY stray exists, BEFORE any mutation. | Stray-injection test: `python safety-gate rc on stray = 2` → die → no mutation |
| Default-label deletion | NONE. `delete_labels` input is ONLY `is_pack_managed` rows (`desc == "v11 pack-managed label"`, L421–428). The 9 GitHub defaults never enter the list (dry-run: "9 (will NOT be touched)"). | L421–428 + dry-run preview (49 names, all pack-managed) |
| Accidental `--execute` | NONE. `EXECUTE=0` unconditionally at L60; flipped only by the literal `--execute` flag (L125). NO env var, positional, or config path sets it. The destructive path requires `EXECUTE==1` AND a typed `CONFIRM_PHRASE` match (L534, L553–554). | `grep` for env hooks → none; double-gate at L534 + L554 |
| Target redirect | NONE. `TARGET_OWNER/REPO/NWO/EXPECTED_ACCOUNT` are `readonly` (L38–41); no flag/env/positional reaches them. Preflight `die`s on account ≠ DShaneNYC, missing `repo` scope, `nwo` ≠ target, or `viewerCanAdminister ≠ true` (L142–157). | L38–41 readonly; L142–157 preflight guards |
| Gate fails open on crash | NONE. `safety_gate` aborts on ANY non-zero gate rc, not just rc=2 (`[ "$rc" -eq 0 ] || die`, L308–309). A python crash (rc=1) still aborts. | Crash sim: outer rc=1 → aborts |
| Ordering (mutate before gate) | NONE. `main` orders `preflight → snapshot_issues → snapshot_labels → safety_gate → preview` (L523–527); the destructive `delete_issues → delete_labels → verify_after` runs only after the typed-confirmation gate (L556–558). | L523–558 |

---

## Findings by severity

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT-A (advisory, non-blocking):** `delete_issues`'s non-terminal `*)` branch (L403–407) logs the raw `gh` `resp` and continues, then `die`s at end-of-loop if `failed > 0` (L413–415) — this is correct fail-loud behavior and is intended. No change required; recorded only so the operator knows a non-terminal-but-failing issue tally also halts the run BEFORE label deletion (consistent with BLOCKER-1's contract). The candidate count != expected (213) case is a WARNING surfaced for re-confirmation, not a hard stop, by design (L293–298) — correct, since entries can legitimately drift; the stray check (not the count) is the airtight gate.

---

## Proven safety properties — re-confirmed intact post-fix

- **Marker-scoping airtight** — `is_candidate = (bd_label in labels) or (pack_id is not None)` (snapshot) + `is_pack_managed = (desc == pack_desc)` (labels); delete loops consume only those rows; stray → hard-stop before mutation; 0 stray live.
- **`--execute` double-gated** — flag (L125) + typed phrase (L554); env var ignored (no env path exists).
- **Snapshot-first ordering** — gate + preview run before any mutation; mutation only after typed confirmation.
- **No repo-delete verb** — only `deleteIssue` + `gh label delete` mutate; L26 is prose.
- **No default-label deletion** — only `is_pack_managed` names; 9 defaults untouched.
- **Sanctioned-target-only `readonly` constants** — L38–41; preflight guards account/scope/nwo/admin.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. Agents never commit (git read-only) | Only git verbs run: `git rev-parse HEAD` → `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`, `git status --short`. No `git add`/`commit`/`push`/`tag`/`rm`/`mv`/`checkout`. The pre-existing ` M backlog/*.md` working-tree changes were present at session start and NOT touched by me. The only file I wrote is this report. | COMPLIANT |
| 2. No destructive op (`--execute` NEVER run; dry-run only; repo-unchanged quoted) | Every script invocation was the default no-flag dry-run (`=== dry-run-exit-rc=0 ===`). Halt repros used STUBBED `gh` in throwaway `/tmp` harnesses (since deleted) — no real mutation. Repo proven unchanged: issues `213→213`, bd-entry `213→213`, labels `58→58`, pack-managed `49→49`. The real `--execute` was NEVER passed. | COMPLIANT |
| 3. Independent verification (command + quoted output per claim) | BLOCKER-1: stubbed-FORBIDDEN harness → `script-exit-rc=1`, no post-loop output (quoted). SHOULD-1: 6 `ratelimit_wait_secs` cases + classifier table (quoted). SHOULD-2: 4-mode label-loop harness (quoted). Dry-run + before/after counts (quoted). Counter-survival + exhausted-RL + stray-abort + gate-crash all run and quoted. | COMPLIANT |
| 4. Adversarial safety (re-hunt over-deletion / repo-delete / default-label / accidental execute) | 7-row attack-surface table above; every row NONE with grep/test evidence. Stray injection → rc=2 die; gate crash → rc=1 die; no env path to EXECUTE/TARGET; readonly target constants; only `deleteIssue`+`label delete` mutate. | COMPLIANT |
| 5. Severity-tagged findings (with line refs) | BLOCKER/MUST/SHOULD = none; one NIT-A (advisory, L403–415 / L293–298), no change required. All fix verifications carry script line refs (L356–411, L79–100, L435–473, L481–515, L38–41, etc.). | COMPLIANT |
| 6. Rules-Applied Verification Block | This block; per-rule name + quoted evidence + conclusion; no empty evidence. | COMPLIANT |
| 7. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; BLOCKER-1 halt re-verified; dry-run re-validated; --execute NOT run; about to Write <path>` after all repros + dry-run PASSed, before this Write. No parent stop message received. | COMPLIANT |
