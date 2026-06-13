# IMPL-REPORT — BD-214 GH-issue-deletion one-off script, FIX-1 (4 approved review fixes)

- **Coder:** fresh pack-coder (fix-coder for the BD-214 deletion-script review).
- **Date:** 2026-06-13. **Branch:** `v11-dev`. **HEAD (worktree, read-only):** `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`.
- **Target edited (NOT committed; lives in /tmp ONLY per BD-214 §7 D-I):** `/tmp/bd214-gh-issue-deletion.sh`.
- **Findings fixed:** `PACK-REVIEW-BD-214-GH-DELETION-SCRIPT.md` — BLOCKER-1, SHOULD-1, SHOULD-2, NIT-1 (NIT-2/NIT-3 resolved as a side-effect of BLOCKER-1 per the reviewer's note).
- **Spec sources read in full:** `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` §7 (delete-loop mechanics), `RESEARCH-BD-212-GH-ISSUE-DELETION.md` §5 (rate-limit rules) + §6 (classifier).
- **`--execute` was NEVER run.** Only the default read-only dry-run was executed for validation. The real deletion remains HELD for an explicit user GO.

---

## Outcome summary

| Finding | Severity | Status | Mechanism |
|---|---|---|---|
| BLOCKER-1 — subshell `die` does not halt the script | BLOCKER | FIXED | redirect-form `while … done < <(printf …)` so the loop body runs in the parent shell; a loop `die` halts the whole script before `delete_labels`/`verify_after`. Empirically proven. |
| SHOULD-1 — flat 60s wait, no retry-after / backoff | SHOULD | FIXED | new `ratelimit_wait_secs` (honors `retry-after`, then `x-ratelimit-remaining:0`+`x-ratelimit-reset`, else exponential backoff 60→…→900s cap, max 5 tries) + per-issue retry of the SAME issue. |
| SHOULD-2 — label loop swallows all failures | SHOULD | FIXED | label loop now classifies (FORBIDDEN-class → terminal `die`; not-found → idempotent skip; rate-limit → backoff retry; other → fail loud at end), mirroring the issue loop, also via the redirect form. |
| NIT-1 — `verify_after` search false-positive on index lag | NIT | FIXED | search count relabeled ADVISORY ("may lag the index; non-zero is NOT a failure"); the REST 410-Gone spot-check is marked AUTHORITATIVE with an explicit PASS/CHECK verdict. |
| NIT-2 / NIT-3 — lost in-subshell counters / `local` outside a function | NIT | FIXED (side-effect) | the redirect form runs the body in the parent shell, so the counters survive and `local` is now inside the `delete_issues`/`delete_labels` function bodies legitimately. |

**Files changed inventory:** `/tmp/bd214-gh-issue-deletion.sh` — modified (NOT committed; one-off /tmp tool). No repo-tracked file was touched by the fixes. (This IMPL-REPORT is the only repo-tracked artifact written.)

---

## Fix 1 — BLOCKER-1: loop `die` now halts the WHOLE script

### Before (the bug)

The delete loop ran inside a `printf '%s\n' "$list" | while … done` pipe. The pipe body
executes in a **subshell**, so `die` (`exit 1`) terminated only the subshell; `main` fell
through to `delete_labels` (deleting all 49 labels) and `verify_after`, exiting 0 — defeating
the spec's terminal-stop contract (RESEARCH §6 / ARCHITECTURE §7 step 4 "FORBIDDEN-class →
terminal stop").

```
  printf '%s\n' "$list" | while IFS="$(printf '\t')" read -r num node pid; do
    ...
        FORBIDDEN|INSUFFICIENT_SCOPES)
          die "TERMINAL: deleteIssue returned ${errtype} on #${num}. ... STOP."
        RATE_LIMITED)
          ... sleep 60 ; die "rate limited; re-run ..."
    ...
  done
  note "  issue delete loop complete ..."
}
```

### After (the fix)

Driven by a **process-substitution redirect** — the body runs in the parent shell, so a loop
`die` halts the entire script before `delete_labels`/`verify_after` can run. Counters
(`deleted`/`skipped`/`failed`) now survive; a non-terminal failure tally also halts before
label deletion.

```
  while IFS="$(printf '\t')" read -r num node pid; do
    ...
        FORBIDDEN|INSUFFICIENT_SCOPES)
          die "TERMINAL: deleteIssue returned ${errtype} on #${num}. Admin preflight or scope is wrong. STOP (no labels deleted)." ;;
    ...
  done < <(printf '%s\n' "$list")
  note "  issue delete loop complete: ${deleted} deleted, ${skipped} skipped (NOT_FOUND), ${failed} non-terminal failures."
  if [ "$failed" -gt 0 ]; then
    die "${failed} issue(s) failed with a non-terminal error; STOP before label deletion (re-run to resume; investigate the raw errors above)."
  fi
}
```

Process substitution is bash-only; acceptable here — the shebang is `#!/usr/bin/env bash`
and the reviewer's fix-recipe (a) explicitly sanctions it.

### Halt repro (empirical proof)

**Minimal before/after of the subshell semantics** (`/tmp/repro-before.sh` vs `/tmp/repro-after.sh`):

```
# BEFORE (pipe-while):
processed a
ERROR: terminal on b
AFTER LOOP (should NOT print if die halted)      <-- PRINTED (bug)
MAIN CONTINUED (should NOT print if die halted)  <-- PRINTED (bug)
script-exit-rc=0                                  <-- exits 0 (bug)

# AFTER (redirect form):
processed a
ERROR: terminal on b
script-exit-rc=1                                  <-- halts; nothing after loop prints
```

**Realistic harness mirroring the FIXED `delete_issues` loop + a following
`delete_labels`/`verify_after`/`MAIN END`**, with `gh` stubbed to return a `FORBIDDEN`
errors[].type on issue #102 (file-based call counter so the command-substitution subshell
does not reset it):

```
  [1/3] #101 -> DELETED
ERROR: TERMINAL: deleteIssue returned FORBIDDEN on #102. STOP (no labels deleted).
script-exit-rc=1
```

`delete_labels`, `verify_after`, and `MAIN END` did NOT run — proving a FORBIDDEN inside the
restructured loop now stops the whole script BEFORE label deletion. This is the exact contract
BLOCKER-1 required.

---

## Fix 2 — SHOULD-1: honor retry-after / x-ratelimit-reset + exponential backoff

### Before

```
        RATE_LIMITED)
          note "  ... RATE_LIMITED; backing off 60s then aborting this run ..."
          sleep 60
          die "rate limited; re-run the script to resume ..."
        *)
          ... # comment: "Surface secondary-limit retry-after if present" — but never read
```

Flat 60s; ignored `retry-after` / `x-ratelimit-reset`; no exponential backoff (RESEARCH §5.5
+ ARCHITECTURE §7 step 4 mandate honoring those headers and exponential backoff on repeated
secondary-limit hits).

### After

New constants + two helpers, and an inner per-issue retry loop:

- Constants: `BACKOFF_BASE_SEC=60` (RESEARCH §5.5 "wait for at least one minute"),
  `BACKOFF_MAX_SEC=900` (per-wait cap), `BACKOFF_MAX_TRIES=5` (then terminal abort; re-run
  resumes via NOT_FOUND idempotency).
- `ratelimit_wait_secs(headers, fallback)` — priority order per §5.5: (1) `retry-after`
  seconds; (2) `x-ratelimit-remaining:0` + `x-ratelimit-reset` (UTC epoch) → `reset - now`;
  (3) the caller's exponential-backoff fallback. Clamped to `[1, BACKOFF_MAX_SEC]`.
- `is_rate_limited(body)` — detects a secondary/primary-limit signal
  (`RATE_LIMITED` type or a rate-limit / "secondary rate" / "abuse detection" message;
  RESEARCH §5.5 "response status will be 200 or 403" + message).

The issue loop now retries the SAME issue after waiting (honoring headers, fetched read-only
via `gh api -i rate_limit`), doubling the fallback each attempt, capped, up to
`BACKOFF_MAX_TRIES`; exhausting the budget is a terminal `die` (which, post-BLOCKER-1, halts
the script — no labels deleted). This matches RESEARCH §5.5's "wait at least one minute …
exponentially increasing … honor retry-after / x-ratelimit-reset" exactly.

```
      if [ "$errtype" = "RATE_LIMITED" ] || [ -n "$rl" ]; then
        attempt=$((attempt + 1))
        if [ "$attempt" -gt "$BACKOFF_MAX_TRIES" ]; then
          die "rate limited on #${num} after ${BACKOFF_MAX_TRIES} backoff attempts; re-run to resume ..."
        fi
        http_hdrs="$(gh api -i rate_limit 2>&1 | sed -n '1,40p')"
        wait_s="$(ratelimit_wait_secs "${http_hdrs}
${resp}" "$backoff")"
        note "  ... RATE_LIMITED (attempt ${attempt}/${BACKOFF_MAX_TRIES}); waiting ${wait_s}s (retry-after/reset honored, else exp backoff) then retrying same issue."
        sleep "$wait_s"
        backoff=$(( backoff * 2 )); [ "$backoff" -le "$BACKOFF_MAX_SEC" ] || backoff="$BACKOFF_MAX_SEC"
        continue
      fi
```

This is real classification/backoff (not cosmetic): it changes the wait duration based on
live headers and grows it across attempts.

---

## Fix 3 — SHOULD-2: label-delete loop now classifies errors (fail-loud on FORBIDDEN)

### Before

```
  printf '%s\n' "$names" | while IFS= read -r ln; do
    if gh label delete "$ln" --repo "${TARGET_NWO}" --yes >/dev/null 2>&1; then
      note "  label DELETED: ${ln}"
    else
      note "  label delete FAILED or already gone: ${ln} (continuing)"   # swallows ALL failures
    fi
  done
```

A permission failure was treated identically to an idempotent already-gone — a FORBIDDEN on
labels would be silently logged and the loop would continue.

### After

Redirect form (parent-shell body, so a `die` halts the script) + the SAME classification as
the issue loop:

- captures stderr (`out="$(gh label delete … 2>&1)"`),
- rate-limit → backoff retry (shared `ratelimit_wait_secs` / `is_rate_limited`),
- `*not found* / *404*` → idempotent skip,
- `*forbidden* / *403* / *must have admin* / *permission* / *insufficient*` → terminal `die`
  ("Admin/scope regressed mid-run. STOP."),
- any other error → counted and a fail-loud `die` at end of loop.

```
        *forbidden*|*"403"*|*"must have admin"*|*permission*|*"insufficient"*)
          die "TERMINAL: label delete returned a permission error on '${ln}': ${out}. Admin/scope regressed mid-run. STOP." ;;
```

A FORBIDDEN on a label now fails loud rather than silently continuing.

---

## Fix 4 — NIT-1: 410 spot-check is the authoritative observable; search count is advisory

### Before

```
  remaining="$(gh api -X GET search/issues -f q="repo:${TARGET_NWO} is:issue label:${BD_ENTRY_LABEL}" ...)"
  note "  issues still carrying '${BD_ENTRY_LABEL}': ${remaining} (expect 0)"
  ...
  note "  spot-check #${sample_num} via REST -> ${status} (expect HTTP/2 410 or '410 Gone')"
```

The search count could false-positive on GitHub's search-index lag (seconds-to-minutes),
reading a transient non-zero as failure.

### After

The search count is explicitly labeled `[ADVISORY, may lag the search index]` with a note
that a non-zero count is NOT a failure; the REST 410-Gone spot-check is labeled
`[AUTHORITATIVE]` and now emits an explicit verdict (`PASS` on a 410, else `CHECK — …
investigate`). The hard verdict rests on the 410 check (RESEARCH §4), per the reviewer's
recommendation.

```
  note "  [ADVISORY, may lag the search index] issues still indexed with '${BD_ENTRY_LABEL}': ${remaining}"
  note "  (A non-zero count here is NOT a failure ... The authoritative observable is the REST 410-Gone spot-check below.)"
  ...
    if printf '%s' "$status" | grep -q '410'; then
      verdict="PASS (issue is hard-deleted; 410 Gone is the authoritative post-delete observable)"
    else
      verdict="CHECK — expected '410 Gone'; investigate (a 200/301 means the issue was NOT deleted)"
    fi
    note "  [AUTHORITATIVE] spot-check #${sample_num} via REST -> ${status}"
    note "    verdict: ${verdict}"
```

---

## Re-validated read-only dry-run (verbatim)

`bash -n /tmp/bd214-gh-issue-deletion.sh` → `SYNTAX OK`.

### Baseline (BEFORE running the fixed script)

```
$ gh api -X GET search/issues -f q="repo:DShaneNYC/optiquity-ai-agent-config-pack is:issue" --jq '.total_count'        -> 213
$ gh api -X GET search/issues -f q="repo:DShaneNYC/optiquity-ai-agent-config-pack is:issue label:bd-entry" --jq '...'  -> 213
$ gh label list ... --json name,description | python3 ...   -> total labels: 58 ; pack-managed: 49
```

### The fixed script's own dry-run (default path, no flags) — safety-gate + counts

```
mode  : DRY-RUN (read-only, DEFAULT)
PREFLIGHT
  auth: account DShaneNYC present, 'repo' scope present.
  repo: DShaneNYC/optiquity-ai-agent-config-pack viewerCanAdminister=true.
SNAPSHOT (issues) -> /tmp/bd214-gh-issue-deletion-manifest-20260613T183413Z.json
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

Candidate set = **213 marker-bearing issues + 49 pack-managed labels + 0 stray**, exactly
matching the EE-4 / §7 decision-of-record (unchanged from the pre-fix review).

### Repo PROVEN unchanged (AFTER the dry-run)

```
$ gh api ... is:issue --jq '.total_count'              -> 213   (was 213)
$ gh api ... label:bd-entry --jq '.total_count'        -> 213   (was 213)
$ gh label list ... -> total labels: 58 ; pack-managed: 49      (was 58 / 49)
```

Issue/label counts before == after. Nothing was mutated. `--execute` was NEVER passed.

---

## Proven safety properties — re-confirmed intact post-fix

The four fixes touched only `delete_issues`, `delete_labels`, `verify_after`, and added
constants/helpers; none touched the safety gates / marker-scoping / confirm-phrase / snapshot
logic (out of scope, left as-is). Re-confirmed by grep against the edited script:

- **Marker-scoping intact** — `is_candidate = (bd_label in labels) or (pack_id is not None)`
  (snapshot) + `is_pack_managed = (desc == pack_desc)` (labels) unchanged; the delete loops
  still consume only the manifest's `is_candidate` / `is_pack_managed` rows.
- **`--execute` double-gate intact** — `EXECUTE=0` default (unconditional, post-env), only
  `--execute` flips it, then an interactive typed `CONFIRM_PHRASE` match
  (`[ "$typed" = "$CONFIRM_PHRASE" ] || die "confirmation phrase mismatch; aborted. Nothing deleted."`).
- **Snapshot-first intact** — `main` orders `preflight → snapshot_issues → snapshot_labels →
  safety_gate → preview`, and the gated path runs `delete_issues → delete_labels →
  verify_after` only after the typed confirmation.
- **No-repo-delete intact** — the only `repo delete` token in the file is the line-26 safety
  COMMENT ("Never repo delete"); zero executable repo-level destructive verbs.
- **No-default-label-delete intact** — `delete_labels` enumerates only `is_pack_managed`
  names; the 9 GitHub defaults are never listed (dry-run reported "9 (will NOT be touched)").
- **Sanctioned target only** — `TARGET_OWNER`/`TARGET_REPO`/`TARGET_NWO`/`EXPECTED_ACCOUNT`
  remain `readonly`; no flag/env/positional can redirect to another repo.

---

## Plan deviations

None. The fixes implement exactly the four approved review findings (BLOCKER-1, SHOULD-1,
SHOULD-2, NIT-1), using BLOCKER-1's reviewer-sanctioned fix-recipe (a) (redirect form), and
the NIT-2/NIT-3 cosmetic issues resolved as the reviewer predicted. No out-of-scope edit was
made; the safety gates / marker-scoping / confirm-phrase / snapshot logic were left untouched.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| BLOCKER-1 fixed — loop `die` halts whole script before label deletion | PASS (FORBIDDEN-in-loop harness → rc=1, no `delete_labels`/`verify_after`/`MAIN END`) |
| SHOULD-1 fixed — retry-after / x-ratelimit-reset honored + exponential backoff | PASS (`ratelimit_wait_secs` + per-issue retry loop; constants 60→×2→900 cap, 5 tries) |
| SHOULD-2 fixed — label loop classifies; FORBIDDEN-class fails loud | PASS (terminal `die` on permission errors; idempotent skip on not-found; backoff on rate-limit) |
| NIT-1 fixed — 410 spot-check authoritative; search count advisory | PASS (relabeled + explicit PASS/CHECK verdict) |
| NIT-2 / NIT-3 resolved (counter survival / `local` scope) | PASS (side-effect of redirect form) |
| `bash -n` syntax check | PASS (SYNTAX OK; macOS bash 3.2-compatible except process substitution, which is bash-only and sanctioned) |
| Read-only dry-run re-validated (213 + 49, 0 stray) | PASS (verbatim above) |
| Repo proven unchanged (before == after) | PASS (213/213 issues, 58/49 labels) |
| `--execute` NOT run | PASS (default no-flag path only) |
| Proven safety properties intact | PASS (grep re-confirmed all six) |
| Script stays at /tmp, NOT committed | PASS (no git state change; only IMPL-REPORT written to repo) |

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit (git read-only) | Only git verbs run: `git rev-parse HEAD` → `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`, `git status`. No `git add`/`commit`/`push`/`tag`/`rm`/`mv`/`checkout` anywhere. The script edits are to `/tmp/bd214-gh-issue-deletion.sh` (untracked, outside the repo); the only repo-tracked write is this IMPL-REPORT. | COMPLIANT |
| No destructive op (`--execute` NEVER run; real run held-for-user) | Every invocation of the script was the default no-flag dry-run (`=== dry-run-exit-rc=0 ===`). The FORBIDDEN halt repro used a STUBBED `gh` in a throwaway `/tmp` harness — no real `gh` mutation. Repo unchanged: `is:issue 213→213`, `label:bd-entry 213→213`, labels `58/49→58/49`. The real `--execute` deletion remains HELD for an explicit user GO. | COMPLIANT |
| Real fixes — no band-aids | BLOCKER-1: redirect form proven to halt the whole script on a simulated FORBIDDEN (`script-exit-rc=1`, no post-loop output) vs the before pipe-while (`rc=0`, all post-loop output printed). SHOULD-1: `ratelimit_wait_secs` reads `retry-after` / `x-ratelimit-remaining:0`+`x-ratelimit-reset`, exponential fallback 60→×2 capped 900, 5-try budget — a behavior change, not a comment. SHOULD-2: label loop now has the issue-loop classifier (FORBIDDEN→die). | COMPLIANT |
| Preserve proven safety | grep-confirmed intact: `readonly` target constants (L38–41), `EXECUTE=0` + `--execute` + typed `CONFIRM_PHRASE` gate (L60/125/554), `main` snapshot-first order (preflight→snapshot×2→safety_gate→preview, then delete×2→verify), `is_candidate`/`is_pack_managed` predicates, zero executable repo-delete verbs (only L26 prose comment). Dry-run reported "GitHub default labels: 9 (will NOT be touched)". | COMPLIANT |
| Validate read-only (213+49, 0 stray, repo unchanged; quoted) | Dry-run output quoted verbatim: candidate issues 213, STRAY 0, pack-managed labels 49, defaults 9, exit 0, "Nothing was mutated." Baseline and after counts quoted: 213/213/58/49 both times. | COMPLIANT |
| Rules-Applied Verification Block | This block (per-rule name + quoted evidence + conclusion; no empty evidence). | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 4 fixes applied; dry-run re-validated (213+49, 0 stray, repo unchanged); loop-die halt proven; --execute NOT run; about to Write IMPL-REPORT to <path>` after all fixes + dry-run + halt repro PASSed, before this Write. No parent stop message received. | COMPLIANT |
