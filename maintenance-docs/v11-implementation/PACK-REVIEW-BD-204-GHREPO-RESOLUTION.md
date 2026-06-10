# PACK-REVIEW — BD-204 GH_REPO owner-repo resolution fix (reviewer pass 1)

- **Date:** 2026-06-10
- **Branch:** `v11-dev`, HEAD `1068c74a90b96fe78c48f73b818ed777c4deb873` (unchanged; uncommitted working-tree diff reviewed)
- **Reviewer:** fresh pack-reviewer instance
- **Scope reviewed:** entire `git diff` vs HEAD — `scripts/lib/tracker-provider-gh.sh` (+69/−6), `scripts/tests/tracker-provider-test.sh` (+168/−6); untracked `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md` read as edit inventory. No prior `PACK-REVIEW-*.md` read. No live GitHub calls of any kind — all verification mock/local.

## Verdict

**APPROVE-WITH-FIXES**

The lib fix and its test coverage are correct, complete within the stated
scope, and independently verified green across the full CI battery (57/57
local steps rc=0), including a /tmp mutation check proving the new coverage
fails loudly on regression. Two items need disposition before/with commit:
the POQ fold-in recommendation (F-1, SHOULD) and the coder's self-disclosed
`git stash` process violation (F-2, MUST-surface — no code change). Two NITs.

---

## 1. Findings

### F-1 (SHOULD) — Fold POQ-BD204-GHREPO-1 into this change now

**Anchor:** `scripts/lib/tracker-migrate-reverse.sh:399-412`
(`_tmr_fetch_first_class_blocked_by`).

The function is GH_REPO-preferred but uses the value VERBATIM:

```bash
if [[ -n "${GH_REPO:-}" && "$GH_REPO" == */* ]]; then
    owner_repo="$GH_REPO"
...
owner=$(printf '%s' "$owner_repo" | cut -d/ -f1)
repo=$(printf  '%s' "$owner_repo" | cut -d/ -f2)
```

With the canonical host-prefixed shape `GH_REPO=github.example.com/owner/repo`
this yields `owner=github.example.com`, `repo=owner` — same bug class the
diff under review fixes, different file.

**When does a host-prefixed GH_REPO reach this code path live?** Concretely:
`tracker_gh_repo_setup` (`scripts/lib/tracker-config.sh:252-283`) exports
`backend.repo` verbatim and its F4 validation EXPLICITLY documents and
accepts the host-prefixed form — line 278: `(expected forms: 'owner/repo' or
'github.example.com/owner/repo'; ...)`. Every reverse-migration run sets
`_TRACKER_PROVIDER_CONFIG_PATH` and the first `_gh_run`/`_gh_owner_repo`
call exports GH_REPO from `tracker.toml`. So ANY client on GHE (or anyone
who writes `github.com/owner/repo` in `backend.repo`, which F4 permits)
hits this on every issue during reverse migration. Failure mode is the bad
kind: the function is deliberately best-effort, so the wrong owner/name
split → GraphQL NOT_FOUND → swallowed → `[]` — **silent Blockers-data loss
during a migration**, worse than the loud failure the provider-side fix
produces.

**Deferral assessment per pack memory (`deferral-is-scope-creep`):**
- SIZE: fails — the fix is ~3-4 lines (the same `case */*/*` strip after
  the GH_REPO read) plus one mock test leg in
  `scripts/tests/tracker-migrate-reverse-test.sh`.
- BLOCKED: fails — depends on nothing unlanded.
- LOGICAL FIT: argues FOR inclusion, not deferral — same bug class, same
  commit narrative ("BD-204 GH_REPO resolution"), same review cycle.

**Recommendation: fold into this change now** (fix-coder pass of this same
cycle). One design note for the fix-coder: `_gh_owner_repo` is a private
`_gh_`-prefixed helper of `tracker-provider-gh.sh` ("Helpers are private
... not part of the public API", file header line 16); prefer an inline
3-line strip in `tracker-migrate-reverse.sh` over cross-lib reuse of the
private helper, unless the helper is deliberately promoted. Not a BLOCKER
on the present diff: the defect is pre-existing (this diff did not change
its reachability — `_gh_run` already exported GH_REPO before this fix) and
the coder correctly surfaced it as a POQ rather than opportunistically
expanding scope. Final fix-vs-anchor call is Pack Chat/user triage.

### F-2 (MUST — surface to user; no code change) — coder's disclosed `git stash` violation

**Anchor:** IMPL-REPORT §7 + Rules-Applied row 1 (self-declared VIOLATED).

The coder executed `git stash -q` (state-changing git verb, forbidden to
all agents) and remediated with `git stash pop`. Independently verified by
this reviewer at review time: `git stash list` → empty (rc=0);
`git rev-parse HEAD` → `1068c74a...` unchanged; `git status --porcelain` →
exactly ` M scripts/lib/tracker-provider-gh.sh`,
` M scripts/tests/tracker-provider-test.sh`,
`?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md`.
Net git-state delta is zero and the disclosure is complete and prominent.
Nothing to fix in the diff; the MUST is procedural: Pack Chat must surface
the VIOLATED row to the user before commit per the
`agent-output-rules-applied-block` protocol ("every VIOLATED row gets
surfaced to the user BEFORE any downstream work").

### F-3 (NIT) — IMPL-REPORT §4 "verbatim" grep block is annotated, not verbatim

**Anchor:** IMPL-REPORT §4 fenced block vs
`scripts/lib/tracker-provider-gh.sh:584,669,727,747,767`.

The report's fenced `$ grep -n "_gh_owner_repo" ...` output carries trailing
annotations (`# link (was ~524)`, `# unlink (was ~608)`, etc.) that do NOT
exist in the file — the actual call-site lines are bare
`owner_repo=$(_gh_owner_repo) || return 1` (verified by Read). This also
mildly contradicts the same section's "identical line text at all five
sites" claim (which IS true of the file; the annotated block is the
inconsistency). Evidence presented inside a command-output fence should be
verbatim; annotations belong outside the fence. Report-fidelity only — the
code is correct.

### F-4 (NIT) — `_gh_owner_repo` accepts degenerate ≥3-slash / trailing-slash GH_REPO shapes

**Anchor:** `scripts/lib/tracker-provider-gh.sh:172-179`.

`GH_REPO=a/b/c/d` → strip-once → `b/c/d` → passes the `*/*` check →
malformed REST path; `GH_REPO=owner/repo/` → `repo/` → also passes `*/*`.
Both are garbage-in shapes that `tracker_gh_repo_setup`'s F4 validation
(`tracker-config.sh:274-275` — requires ≥1 slash, no `://`, no whitespace)
likewise does not reject, and that gh itself would mishandle. The failure
mode downstream is a loud typed `not-found`/`validation` error from the
REST call — never silent success — so this is hygiene, not a hazard.
Optional tightening: validate exactly-one-slash-with-non-empty-segments
post-strip. If deferred, it needs a tracked anchor per
`deferred-work-tracked-anchor`.

---

## 2. What was checked (clean areas)

### 2.1 Helper correctness — `_gh_owner_repo()` (`tracker-provider-gh.sh:133-190`)

- **Setup-guard ordering:** `tracker_gh_repo_setup` runs (same
  `declare -f` guard as `_gh_run`, line 165-167) BEFORE `GH_REPO` is read
  (line 168) — so a `backend.repo`-sourced export is in place before the
  preference check. Correct.
- **GH_REPO preference + HOST/-strip:** the strip decides by SLASH COUNT
  (shape), never by content: `case */*/*` strips exactly one leading
  segment from a two-slash `HOST/OWNER/REPO`; a one-slash `OWNER/REPO` is
  never inspected, so an OWNER that "looks like a host" (dotted, e.g. a
  hypothetical `some.org/repo`) can NEVER be mis-stripped — the question
  "is this a host?" is simply not asked for the bare shape. (GitHub owner
  logins cannot contain dots, so the two-slash dotted-first-segment case is
  unambiguously a host.) This is the right discriminator for the canonical
  `[HOST/]OWNER/REPO` contract that `tracker_gh_repo_setup` documents and
  exports (verified at `tracker-config.sh:266-278`). Degenerate non-canonical
  shapes: F-4 (NIT).
- **Fail-loud on set-but-invalid:** a set-but-slash-less `GH_REPO` emits a
  typed `validation` error and returns 1 (lines 175-179) — it does NOT
  silently fall back past a caller-supplied value. Correct per contract.
- **Fallback gating:** `gh repo view` is reached ONLY when `GH_REPO` is
  unset/empty (line 183, sole executable instance), via `_gh_run` so
  failures classify into typed errors; an rc=0-but-empty result emits a
  typed `validation` error naming both remedies (lines 184-188). Correct.
- **Portability:** `local`, `case`, `${var#*/}`, `printf '%s'` only —
  bash-3.2/BSD-safe.

### 2.2 Five call sites traced end-to-end

All five sites are `owner_repo=$(_gh_owner_repo) || return 1`:

| Site | Line | Consumers | Bare-slug need met |
|---|---|---|---|
| `tracker_provider_gh_link` (blocks/blocked-by) | 584 | REST `/repos/$owner_repo/issues/{id,other_id}` node-id lookups; GraphQL `addBlockedBy` consumes node IDs only | YES |
| `tracker_provider_gh_unlink` (blocks/blocked-by) | 669 | same pattern, `removeBlockedBy` | YES |
| `tracker_provider_gh_sub_issue_create` (ext-absent) | 727 | REST node-id lookups; `addSubIssue` node IDs | YES |
| `tracker_provider_gh_sub_issue_list` (ext-absent) | 747 | `cut -d/ -f1/-f2` owner/name split → GraphQL `repository(owner:, name:)` | YES — this was the host-prefix-vulnerable consumer; pinned by 1.21c |
| `tracker_provider_gh_sub_issue_unlink` (ext-absent) | 767 | REST node-id lookups; `removeSubIssue` node IDs | YES |

### 2.3 Test coverage adequacy

- **Kill switch genuinely reproduces the live failure:** the fake fails any
  `repo ...` call with the verbatim `fatal: not a git repository` stderr
  and rc=1, AFTER logging — so a regression is both visible in
  `FAKE_GH_LOG` and fatal to the op. **Mutation-verified:** I reverted the
  link site to the old idiom in a /tmp COPY of `scripts/` (repo untouched)
  and re-ran the suite: `Passed: 145, Failed: 7` — all 1.17f/1.17g
  assertions failed loudly. The coverage bites.
- **Legs present:** repo-view-dead + GH_REPO set → success with zero
  `repo view` log entries (1.17f link, 1.20d unlink, 1.21b
  sub_issue_create, 1.21d sub_issue_unlink); host-prefixed GH_REPO →
  stripped (1.17g REST path; 1.21c GraphQL owner/name split, with negative
  `owner=github.com` / `/repos/github.com/` leak asserts). Note 1.17g runs
  with `FAKE_GH_REPO_VIEW_FAIL` still exported from 1.17f — strengthens it.
- **Fallback still covered, nothing deleted:** 1.17a / 1.20a `repo view`
  asserts RETAINED (relabeled "(GH_REPO-unset fallback)"); the diff removes
  no assertions. The pre-existing 1.21 either/or test now exercises the new
  fail-loud-on-empty-fallback path via its typed-error branch — absorbed
  correctly.
- **Ambient-GH_REPO scrub sound:** suite-level `unset GH_REPO` before
  sourcing the libs + `reset_fake_gh` scrubs `GH_REPO` and
  `FAKE_GH_REPO_VIEW_FAIL` per test; no `tracker.toml` is in scope
  (`_TRACKER_PROVIDER_CONFIG_PATH` unset → `tracker_gh_repo_setup` no-ops),
  so the suite cannot pass/fail on the developer's environment in either
  direction (an ambient GH_REPO would otherwise have silently flipped
  1.17a/1.20a off the now-asserted fallback path).
- **Harness mechanics verified:** suite runs under `set -u` only (no
  `set -e`), so the `rc=$?`-after-command-substitution captures are valid;
  1.20c only used `FAKE_GH_STDERR_FILE`/`FAKE_GH_EXIT`, so
  `UNLINK_DISPATCH_DIR` is intact when 1.20d reuses it; 1.21b-d pin
  `_GH_SUB_ISSUE_EXT_CACHED="no"` and unset it after; all new env exports
  are cleaned up before subsequent tests.
- **No cross-suite breakage:** `grep -rn "assert.*repo view"` across
  `scripts/tests/` excluding the provider suite → zero hits. The seven
  other suites that mention `repo view` only STUB it in fake-gh case arms
  (dead-but-harmless branches when GH_REPO is exported); all those suites
  pass (battery §2.5).

### 2.4 Completeness within the libs

`grep -rn "repo view\|nameWithOwner"` across `scripts/` (non-test) and
`project-template/`:
- `scripts/lib/tracker-provider-gh.sh` — comments + the helper's documented
  fallback at line 183 only. No remaining argument-less slug resolution at
  any op site.
- `scripts/lib/tracker-migrate-reverse.sh:402` — the POQ site (F-1); its
  `gh repo view` is inside the GH_REPO-unset guarded fallback and degrades
  to `[]`.
- No other tracker lib (`tracker-edit.sh`, `tracker-migrate-forward.sh`,
  `tracker-links.sh`, `tracker-labels.sh`, etc.), no `scripts/*.sh`, and no
  `project-template/` file carries the pattern.

### 2.5 Verification — full CI battery (independent, local, mock-only)

Every step of `.github/workflows/validate-pack.yml` run locally in workflow
order (log: `/tmp/bd204-review-battery.log`): **57/57 rows rc=0, zero
non-green rows.** Highlights:

| Step | Result |
|---|---|
| `python3 scripts/validate-pack.py` | rc=0 — "PASSED — all checks clean" |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | rc=0 — "PASSED — all checks clean" |
| `tracker-provider-test.sh` | rc=0 — **152/152 PASS** (independent re-run; all 25 new BD-204 assertions enumerated PASS — 1.17f×5, 1.17g×3, 1.20d×4, 1.21b×6, 1.21c×4, 1.21d×3) |
| forward / reverse / roundtrip migrate suites | rc=0 each |
| `test-fixtures/build.sh --all --clean` → restore committed manifest → `--verify` | rc=0; all rows OK (incl. `existing-project-mid-dev OK: a54e081a...`) |
| `test-v11-realistic-ot.sh` (integration) | rc=0 — 33/33 PASS |
| persona contracts / migrator-skills / all per-check validate-pack suites | rc=0 each |
| `env -u PACK_TRACKER_LIVE_GH tracker-bd204-lossless-roundtrip-test.sh` | rc=0 — `SKIP: live-GH oracle ...` (guard at script line 60 short-circuits before any `gh` call) |

### 2.6 Manifest + scope

- **Manifest:** working-tree `git diff test-fixtures/manifest.txt` was empty
  BEFORE my battery (initial `git status --porcelain` showed no manifest
  row), and the battery's `fixture manifest verify` against the COMMITTED
  manifest passed after a fresh `--all --clean` rebuild — independent
  confirmation of the coder's empty-diff claim (the v11-surface trigger
  fired, the rebuild produced no drift: `scripts/lib/` is not in the
  sanctioned shipped set `{scripts/lib/detect.sh, scripts/pack-help.sh}`
  and `scripts/tests/` is never installed).
- **pack-only (BD-204 HARD constraint):** `git diff --name-only` → exactly
  `scripts/lib/tracker-provider-gh.sh` + `scripts/tests/tracker-provider-test.sh`;
  untracked additions = the coder's IMPL-REPORT + this report (both
  `maintenance-docs/`). Zero `project-template/` or `supporting-docs/`
  paths; CI Check 36 `pack-only` deny-list satisfied. The proposed commit
  subject carries `pack-only` legitimately.
- **Other checklist surfaces:** no new files/dirs needing
  `validate-pack.py` coverage (both reports are workflow artifacts, exempt
  during the active batch per the maintenance-mechanical rule); no README
  layout change; no migration-guide/QUICKSTART impact (lib not
  client-shipped); trinity untouched; `backlog/BD-204.md` correctly remains
  `Status: Open` (BD-204 is the umbrella phase, not resolved by this fix).

### 2.7 IMPL-REPORT cross-check

Edit inventory, helper-contract description, five-site grep line numbers,
test enumeration, battery results, manifest claim, and the stash disclosure
all match the working tree and my independent runs, with one fidelity NIT
(F-3). Read-in-full attestation present with line counts; PREFLIGHT line
recorded; Rules-Applied block present with the honest VIOLATED row (F-2).

---

## 3. Read-in-full attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | full | 580 (lines 1-580; final content line 579) |
| `backlog/BD-129.md` | full | 10 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | full | 43 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | full | 15 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ triggered by the memory file) | section | lines 206-233 |

Section reads (named by the prompt): `scripts/lib/tracker-provider-gh.sh`
helper + all five call sites (lines 1-200, 560-790);
`scripts/lib/tracker-config.sh` `tracker_gh_repo_setup` (lines 220-283);
`scripts/lib/tracker-migrate-reverse.sh` `_tmr_fetch_first_class_blocked_by`
(lines 380-429); `scripts/tests/tracker-provider-test.sh` full diff + fake-gh
harness (lines 1-30, 95-170, 520-660) + both file diffs in full.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session: `status --porcelain`, `diff`/`diff --stat`/`diff --name-only`, `rev-parse HEAD`, `log --oneline -1`, `stash list` (read-only), plus the CI workflow's documented `git checkout HEAD -- test-fixtures/manifest.txt` restore step (workflow comment: "Read-only `git checkout -- <path>` form; no branch state is mutated"; the committed manifest was byte-identical to the working-tree manifest before AND after — initial `git status --porcelain` had no manifest row, final has no manifest row). No add/commit/push/tag/stash. End-state `git status --porcelain` = the coder's 2 modified files + 2 untracked reports; HEAD `1068c74a...` unchanged. | COMPLIANT |
| per-action-approval-sub-agents | Destructive ops limited to self-created /tmp artifacts: `rm -rf /tmp/bd204-mutation` (my own scratch copy), `/tmp/bd204-review-battery.{sh,log}` (my own). No repo-file deletion/overwrite; no `git rm`; no operation requiring approval arose. | COMPLIANT |
| preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1068c74a90b96fe78c48f73b818ed777c4deb873; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION.md`. Verification was complete (57/57 battery rows rc=0) before the line. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted measurements; format per `pack-ops/PACK-MEMORY-RATIONALE.md:227-233` (read this session, conditional MUST-READ honored). No empty-evidence or AMBIGUOUS rows. | COMPLIANT |
| agents-read-rule-docs-in-full | §3 attestation: 4 named files read IN FULL with line counts (580/10/43/15) + the triggered rationale section (lines 206-233) + the prompt-named lib/test section reads. No named doc's content was derived instead of read. | COMPLIANT |
| verify-full-ci-suite | Full battery run locally in workflow order (`/tmp/bd204-review-battery.log`): `grep -c "rc=0"` → 57; `grep -v "rc=0"` → only `BATTERY-DONE`. Counts: validate-pack PASS (both modes), provider **152/152** (25 new assertions individually PASS), forward/reverse/roundtrip green, `test-v11-realistic-ot.sh` 33/33, fixture build + committed-manifest `--verify` OK, persona contracts PASS. Live oracle: `SKIP: live-GH oracle ...` rc=0 under `env -u PACK_TRACKER_LIVE_GH`. Zero live GitHub calls made. | COMPLIANT |
| regenerate-manifest-v11-surface | Coder's empty-diff claim verified two ways: (1) pre-battery `git status --porcelain` showed NO `test-fixtures/manifest.txt` row (diff empty at review start); (2) post-`--all --clean` rebuild + committed-manifest restore, `build.sh --verify` rc=0 ("all rows OK"), and final `git diff --stat test-fixtures/manifest.txt` → empty. No staging needed. | COMPLIANT |
| pack-only | `git diff --name-only` → `scripts/lib/tracker-provider-gh.sh`, `scripts/tests/tracker-provider-test.sh` (exactly the two expected files). `git status --porcelain` untracked: `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md` + this report only. Zero `project-template/` / `supporting-docs/` paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Findings limited to real defects/dispositions in this change (F-1 POQ assessment was explicitly requested as item 5; F-2 is the coder's own VIOLATED row; F-3/F-4 anchor to the diff/report). Single deliverable: this report at the prompted path. No code edits, no extra files beyond /tmp scratch (removed). | COMPLIANT |
