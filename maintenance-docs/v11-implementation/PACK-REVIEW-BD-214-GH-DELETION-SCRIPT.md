# PACK-REVIEW — BD-214 GH-issue-deletion one-off script (adversarial safety review)

- **Reviewer:** fresh pack-reviewer (read-only).
- **Date:** 2026-06-13. **Repo HEAD:** `e45a90c` (branch `v11-dev`).
- **Target under review:** `/tmp/bd214-gh-issue-deletion.sh` (NOT committed; one-off per BD-214 design §7 D-I).
- **Spec sources:** `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` §7; `RESEARCH-BD-212-GH-ISSUE-DELETION.md` (read in full).
- **Sanctioned live repo:** `DShaneNYC/optiquity-ai-agent-config-pack` (the ONLY repo the script can touch).

---

## VERDICT: APPROVE-WITH-FIXES — NOT SAFE-TO-EXECUTE as written

The script is **safe against the catastrophic failure modes** the prompt asked me to hunt for:
it can delete NO repo, can target NO other repo, can delete NO GitHub default label, can delete
NO non-pack issue, and has NO accidental `--execute` trigger. The marker-scoping and the
dry-run-default model are sound and were independently re-validated.

However there is **one BLOCKER**: the terminal-stop contract (`FORBIDDEN`/`INSUFFICIENT_SCOPES`
→ HARD STOP, and `RATE_LIMITED` → abort-this-run) is **defeated by a subshell bug** — `die`
inside the `printf | while` pipe exits only the subshell, so a terminal error does NOT stop the
script; it falls through to `delete_labels` + `verify_after`. The intended fail-loud HARD STOP
becomes "skip the rest of the issues, then delete all 49 labels anyway." This must be fixed
before any `--execute` run. It does NOT enable over-deletion, but it breaks the safety contract
the spec mandates (RESEARCH §6 classifier; architecture §7 step 4 "FORBIDDEN-class → terminal stop").

Fix the BLOCKER + the two SHOULDs, re-run the dry-run, and the tool is safe to execute under
the gated confirmation.

---

## Independent dry-run re-validation (read-only; repo PROVEN unchanged)

### Baseline (BEFORE running the script)

```
$ gh api -X GET search/issues -f q="repo:DShaneNYC/optiquity-ai-agent-config-pack is:issue" --jq '.total_count'
213
$ gh api -X GET search/issues -f q="repo:DShaneNYC/optiquity-ai-agent-config-pack is:issue label:bd-entry" --jq '.total_count'
213
$ gh label list --repo DShaneNYC/optiquity-ai-agent-config-pack --limit 300 --json name,description | python3 ...
total labels: 58
pack-managed: 49
```

### The script's own dry-run (default path, no flags) — verbatim safety-gate + counts

```
mode  : DRY-RUN (read-only, DEFAULT)
PREFLIGHT
  auth: account DShaneNYC present, 'repo' scope present.
  repo: DShaneNYC/optiquity-ai-agent-config-pack viewerCanAdminister=true.
SNAPSHOT (issues) -> /tmp/bd214-gh-issue-deletion-manifest-20260613T182405Z.json
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
```

Independent manifest inspection confirms candidate logic is exact:

```
$ python3 -c '... candidates without pack_id, non-candidates ...'
issues: 213   labels: 58   meta: {'target': 'DShaneNYC/optiquity-ai-agent-config-pack'}
candidates w/o pack_id: []      # every candidate carries BOTH bd-entry AND a pack-id marker
non-candidates: []              # zero strays
```

### Repo PROVEN unchanged (AFTER all my probing)

```
$ gh api -X GET search/issues ... is:issue --jq '.total_count'   -> 213   (was 213)
$ ... label:bd-entry --jq '.total_count'                          -> 213   (was 213)
$ gh label list ... total labels: 58  pack-managed: 49            (was 58 / 49)
```

Candidate set **= 213 issues (all marker-bearing) + 49 pack-managed labels + 0 stray**, exactly
matching the EE-4 / §7 decision-of-record. The repo is byte-for-byte unchanged across three full
dry-run executions plus all adversarial probing. `--execute` was NEVER run.

---

## Safety-gate trace (adversarial — every catastrophic path checked)

### 1. Cannot delete a repo / cannot target another repo — PROVEN

- `TARGET_OWNER` / `TARGET_REPO` / `TARGET_NWO` are `readonly` (L38–40). No flag, env var, or
  positional arg can change them — the arg parser (L78–85) accepts only `--execute` / `-h`
  and `die`s on anything else.
- `grep -nE "repo delete|deleteRepository|repo archive"` → **zero matches** in executable code.
  There is no repo-level destructive verb anywhere.
- The delete mutation (L310) targets `issueId: $node` — a node ID harvested ONLY from the
  target-repo snapshot query (L131–139, owner/name pinned to the constants). Node IDs are
  object-scoped; the loop can physically reach no object outside the target repo.

### 2. Cannot delete a non-pack issue — PROVEN

- Candidate predicate (L166): `is_candidate = (bd-entry in labels) OR (pack-id marker present)`.
- Safety gate (L228–264): any issue that is NOT a candidate is a `stray`; `strays` → `sys.exit(2)`
  → `die` → **no mutation**. A fresh inbound-lane or user-filed issue (no bd-entry, no pack-id)
  HARD-STOPS the whole run before the delete loop. Independently confirmed: 0 strays in the live repo.
- The delete loop's input (L292–299) is re-derived from the SAME manifest the gate validated,
  filtered to `is_candidate` — there is no "delete everything" code path; a non-candidate can
  never enter the loop list.

### 3. Cannot delete a GitHub default label — PROVEN

- Label predicate (L201): `is_pack_managed = (description == "v11 pack-managed label")`.
- Delete-labels loop (L347–353) emits ONLY `is_pack_managed` names. The 9 GH defaults
  (description ≠ the sentinel) are never enumerated. Dry-run preview listed exactly the 49
  pack-managed labels; the 9 defaults were reported "will NOT be touched."

### 4. `--execute` is genuinely gated — PROVEN

- Default `EXECUTE=0` (L53) is an UNCONDITIONAL assignment that runs AFTER any inherited
  environment, so `EXECUTE=1 bash …` does NOT bypass — confirmed live: `EXECUTE=1 bash script`
  still printed `mode: DRY-RUN (read-only, DEFAULT)`.
- Only the literal `--execute` flag (L80) flips it. Even then, the destructive path (L418–429)
  requires an INTERACTIVE typed match of `CONFIRM_PHRASE` ("DELETE ALL PACK ISSUES AND LABELS");
  any mismatch → `die` → nothing deleted. There is no non-interactive escape hatch (no
  `--yes`-equivalent for the issue path, no env override).

### 5. Snapshot-first / audit artifact — PRESENT

- The manifest (number/node_id/title/state/labels/pack_id) is written by `snapshot_issues` +
  `snapshot_labels` (L120–211) BEFORE `safety_gate`/`preview`/any delete. `main` (L398–402)
  orders snapshot → gate → preview, and the gated delete runs only after. The script prints the
  "archive a copy OUTSIDE /tmp" recommendation and correctly notes a personal account logs no
  deletion event (matches RESEARCH §4).

### 6. Deletion mechanics vs RESEARCH-BD-212 / architecture §7

| Spec requirement | Script | Status |
|---|---|---|
| `deleteIssue` by NODE ID via GraphQL | L310 mutation `deleteIssue(input:{issueId:$id})`, `$id`=node | OK |
| ≥1s mutation pacing | `sleep "${MIN_WRITE_INTERVAL_SEC}"` (=1), L339 + L362 | OK |
| NOT_FOUND → idempotent skip | L322–324 | OK |
| FORBIDDEN → terminal stop | L325–326 `die` — **defeated by subshell** (see BLOCKER-1) | BROKEN |
| rate-limit → backoff + honor retry-after | L328–331 flat 60s sleep then `die`; **no retry-after / x-ratelimit-reset / exponential backoff** | PARTIAL (see SHOULD-1) |
| post-execute verify (0 pack issues, 410 spot-check, 0 pack labels) | `verify_after` L368–390 | OK (see NIT-1 on search lag) |
| idempotent + resumable on partial | NOT_FOUND skip makes re-run resumable | OK |

---

## Findings by severity

### BLOCKER-1 — terminal `die` inside the `printf | while` subshell does NOT stop the script (L306–340; also L328–331)

The delete loop is `printf '%s\n' "$list" | while … do … done`. The pipe runs the `while` body
in a **subshell**. `die` (L56) calls `exit 1`, which terminates only the subshell, not the parent.
Empirically proven:

```
$ # minimal repro: die inside `printf … | while read` then code after the loop
processed a
ERROR: terminal on b
AFTER LOOP (should NOT print if die halted script)   <-- printed
MAIN CONTINUED (should NOT print if die halted script) <-- printed
script-exit-rc=0
```

Consequences during a real `--execute` run:

- **FORBIDDEN / INSUFFICIENT_SCOPES (L325–326):** spec + architecture §7 step 4 require a HARD
  STOP ("admin preflight lied / scope wrong"). Instead the loop ends, `delete_issues` returns,
  and `main` proceeds to **`delete_labels` (deletes all 49 labels) and `verify_after`**, exiting 0.
  A genuine permission failure mid-run is silently downgraded and the run "completes."
- **RATE_LIMITED (L328–331):** intended "back off 60s then abort this run (re-run resumes)"
  becomes "back off 60s, abort the issue loop, then delete all labels anyway" — the labels get
  deleted even though the issue deletion was incomplete.

This does NOT cause over-deletion (the loop list is still candidate-only), so it is not a
data-safety catastrophe — but it breaks the fail-loud terminal-stop contract that is the whole
point of the classifier, and it can leave the repo in a half-deleted state with labels gone.

**Fix (any one):** (a) feed the loop without a pipe so `die` halts the script — use a
process-substitution/redirect form `while … read …; do … done < <(printf '%s\n' "$list")` (note:
process substitution is bash-only; acceptable since the shebang is bash), OR a temp-file
`done < "$tmp_list"`; (b) have the subshell signal terminal failure via a non-zero subshell exit
that the parent checks (`… | while …; done; rc=$?; [ "$rc" = 0 ] || die …`) AND make the FORBIDDEN
branch `exit 3` so the pipe's exit status is the `while`'s; then gate `delete_labels` on the issue
loop's success. The redirect form (a) is the cleanest and also fixes the lost-counter cosmetic issue.

### SHOULD-1 — rate-limit handling does not honor `retry-after` / `x-ratelimit-reset` or do exponential backoff (L328–336)

RESEARCH §5.4–§5.5 and architecture §7 step 4 mandate honoring `retry-after` /
`x-ratelimit-reset` headers and exponential backoff on repeated secondary-limit hits. The script
instead does a flat `sleep 60` then aborts (and, per BLOCKER-1, doesn't actually abort cleanly).
The `*)` default branch (L333–336) carries a comment "Surface secondary-limit retry-after if
present" but does NOT read or act on it. The abort-and-resume design is fail-SAFE (it never
hammers), so this is a SHOULD not a BLOCKER — but it diverges from the spec the script claims to
implement. At minimum, capture the response headers (`gh api … --include` or a REST HEAD) and
sleep the advertised `retry-after`; resume via the existing NOT_FOUND idempotency.

### SHOULD-2 — label-delete loop swallows ALL failures, masking a FORBIDDEN on labels (L355–363)

`gh label delete … || note "FAILED or already gone … (continuing)"` treats a permission failure
identically to an idempotent already-gone. Unlike the issue loop, there is NO error
classification — a FORBIDDEN on labels would be silently logged and the loop continues. This is
fail-safe (under-deletes), but inconsistent with the issue-loop contract and would hide a real
auth regression. Recommend classifying label-delete failures (at least: distinguish "already
gone / not found" from a permission/other error, and fail-loud on the latter).

### NIT-1 — `verify_after` "expect 0" via `search/issues` can false-positive on index lag (L371–372)

GitHub's search index lags writes by seconds-to-minutes; immediately after deletion the
`label:bd-entry` search may still report a non-zero count even though the issues are gone. The
410-spot-check (L383, REST, not search) is the authoritative post-delete observable per RESEARCH
§4 and is correct. Consider wording the search line as advisory ("may lag the index") and relying
on the 410 check for the hard verdict, or add a short re-poll.

### NIT-2 — lost in-subshell counters (`deleted`/`skipped`/`failed`, L301–308)

These are incremented inside the pipe subshell and never survive to the parent; they are also
never read after the loop, so this is purely cosmetic dead code today. The BLOCKER-1 redirect-form
fix would also let these counters survive if a final tally is desired.

### NIT-3 — `local idx` / `local resp errtype` inside the `while` body (L304, L309)

`local` outside a function body is technically a misuse (the `while` body in a pipe is a subshell,
not a function). It works on bash 3.2 here but is fragile; the redirect-form fix moves these into
the function scope cleanly.

---

## Things explicitly verified SAFE (no action needed)

- Preflight (L91–114): `gh auth status` account == `DShaneNYC` AND `'repo'` scope present
  (both `die` on failure); `viewerCanAdminister == true` AND returned `nameWithOwner` ==
  `TARGET_NWO` (both `die` on mismatch). Independently reproduced: `viewerCanAdminister=true`,
  `nameWithOwner=DShaneNYC/optiquity-ai-agent-config-pack`. Fail-loud and correct.
- `set -u` is on (L32); `set -e` deliberately off with a documented rationale (L33–35) that is
  correct for a classify-per-item loop.
- Snapshot pagination (L129–149) pages at 100 with `hasNextPage`/`endCursor` and correctly breaks;
  213 issues captured matches the live count.
- Marker regex (L164) `<!--\s*pack-id:\s*([^\s]+)\s*-->` correctly extracts the pack-id; every
  candidate carried one in the live data.
- Success detection (L312) keys on `data.deleteIssue` being truthy — correct given the payload
  echoes only `repository` (RESEARCH §1.1: the deleted issue is not echoed).

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit (git read-only) | The only git invocation was `git status --short` / `git rev-parse` (read-only, run from /tmp so it reported "not a git repository" — harmless). No `git add`/`commit`/`push`/`tag`/`rm`/`mv` anywhere in the session. | COMPLIANT |
| No destructive op (`--execute` NEVER run) | Every script invocation was the default (no-flag) dry-run or `--help`/`--force`(rejected)/`EXECUTE=1`(env, ignored). Repo proven unchanged: `is:issue` total `213→213`, `label:bd-entry` `213→213`, labels `58/49 → 58/49` across before, mid, and after. `--execute` token never passed. | COMPLIANT |
| Independent verification (command + quoted output) | Preflight (`gh api graphql viewerCanAdminister` → `true`, nwo match), baseline counts, the script's own dry-run output, manifest inspection, and the repo-unchanged re-check are all quoted verbatim above with the commands that produced them. | COMPLIANT |
| Adversarial safety review (hunt over-delete / repo-delete / default-label / accidental `--execute`) | Traced all four: repo-delete IMPOSSIBLE (`readonly` constants + zero repo-level verbs, grep quoted); other-repo IMPOSSIBLE (node IDs sourced only from target snapshot); non-pack issue IMPOSSIBLE (stray→`sys.exit(2)`→die, 0 strays live); default-label IMPOSSIBLE (description-sentinel predicate, 9 defaults excluded); accidental `--execute` IMPOSSIBLE (env-ignored + typed-phrase gate). Found BLOCKER-1 (subshell `die` defeats terminal-stop) with a quoted minimal repro. | COMPLIANT |
| Severity-tagged findings with line refs | BLOCKER-1 (L306–340/L325–331), SHOULD-1 (L328–336), SHOULD-2 (L355–363), NIT-1 (L371–372), NIT-2 (L301–308), NIT-3 (L304/L309). | COMPLIANT |
| Rules-Applied Verification Block | This block; per-rule quoted evidence + COMPLIANT conclusions. | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; dry-run re-validated read-only; --execute NOT run; about to Write <path>` before this Write. No parent stop received. | COMPLIANT |
