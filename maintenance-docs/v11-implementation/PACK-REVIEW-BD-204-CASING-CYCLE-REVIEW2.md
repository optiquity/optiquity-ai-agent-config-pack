# PACK-REVIEW — BD-204 casing+cycle batch, reviewer pass 2 (combined batch + fix-pass-1)

- **Branch:** `v11-dev`; **HEAD:** `1c18b28c4d149d3e80565beafccc84f8d25b32f2` (unchanged across review)
- **Date:** 2026-06-11
- **Reviewer:** fresh pack-reviewer (pass 2 of the bounded review/fix cycle)
- **Scope:** the ENTIRE uncommitted diff vs HEAD — 12 modified files, all under
  `scripts/` (+578/−47). Runtime artifacts (`tracker.toml`, `.pack-tracker/`)
  and `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` excluded per prompt. Prior
  `PACK-REVIEW-BD-204-CASING-CYCLE.md` NOT read (no-prior-reviews rule).
- **Verdict (bottom line first):** **APPROVE-WITH-FIXES** — functionally
  commit-ready; every success criterion verified empirically; one SHOULD
  (comment-accuracy in new code, exposing an adjacent PRE-EXISTING latent
  defect that needs a tracked anchor) + three NITs. No BLOCKER, no MUST.

---

## 1. What I verified (all foreground, this session)

### 1.1 Casing normalization at the boundary + teeth (criterion 1) — CLEAN

- `_gh_normalize_issue` (`scripts/lib/tracker-provider-gh.sh:245-258`) now
  lowercases `stateReason` (`state_reason_in.lower() if isinstance(...) else
  None` — null-safe), at the single provider boundary. Repo-wide grep
  confirms NO other reader of raw `stateReason` outside the provider, and the
  only canonical-JSON consumer of `.state_reason` is `_tmr_decode_status`
  (`scripts/lib/tracker-migrate-reverse.sh:260-290`); `tracker-edit.sh` /
  `tracker-promote.sh` touchpoints are write-side interface tokens.
- **Pre-fix → Resolved, post-fix → correct statuses, reproduced myself:**
  I copied `scripts/` to `/tmp/bd204-rev2-probe/`, reverted ONLY the
  normalizer line to the pre-fix `opt(data, "stateReason")` passthrough, and
  ran the three affected suites in the copy (zero repo-file edits):
  - provider: `FAIL 1.2b normalize: live stateReason NOT_PLANNED → canonical not_planned` (161/1)
  - reverse: `FAIL 1.1c live CLOSED+NOT_PLANNED → normalize → Cancelled` + Deprecated leg (148/2)
  - roundtrip: `FAIL 2.2e BD-004 read-back normalizes to state_reason=not_planned` +
    `FAIL 2.2e BD-004 decodes to Cancelled` (77/2)
  The lossy class (closed Deprecated/Cancelled → Resolved) is caught at unit,
  chain, AND e2e-CI layers. Teeth confirmed.
- Decode arms pinned: reverse 1.1c covers all three closed arms
  (NOT_PLANNED→Cancelled, NOT_PLANNED+`status:deprecated`→Deprecated,
  COMPLETED→Resolved) through the production normalizer.

### 1.2 Cycle pre-pass (criterion 2) — CLEAN

- `tmf_blockers_cycle_precheck` (`scripts/lib/tracker-migrate-forward.sh:675-802`)
  is wired at `tracker_migrate_forward_run` immediately after parse and BEFORE
  the `--dry-run` return (lines 1435-1443). DFS logic reviewed line-by-line:
  iterative GRAY/BLACK coloring is correct (self-loops, 2-cycles, longer
  cycles, multiple cycles all reported; nonexistent-blocker edges are sinks;
  fail-closed rc on unparseable JSON via `tracker_error_emit "schema-reshape"`).
- **Real-topology probe (isolated, zero live calls):** copied the REAL
  `/backlog/` tree (213 entries; `backlog/BD-094.md:5 Blockers: BD-088,
  BD-095, BD-085` + `backlog/BD-095.md:5 Blockers: BD-085, BD-088, BD-094`
  cycle still live) into `/tmp/bd204-rev2-cyreal/` with a logging-only fake
  gh. Both the real run AND `--dry-run` produced:
  `ERROR: validation` / `cycle path: BD-094 -> BD-095 -> BD-094 ('->' =
  blocked-by)` / `→ Run: pack tracker doctor`, rc=1, **gh log 0 bytes,
  `.pack-tracker/` absent** — fail-loud, full path named, zero provider
  calls, zero disk mutation. Matches the live evidence in
  `/tmp/bd204-c8-rerun.log` (130 blocked-by edges; bare swallowed
  `step-7 link blocked-by: BD-095 -> BD-094` line) being made actionable.
- **Acyclic happy path (130-edge class):** removed the BD-094 token from the
  /tmp copy's BD-095 `Blockers:` line; dry-run then parsed 213 entries,
  passed the pre-pass, rc=0, gh log still 0 bytes. Untouched.
- Per-edge stderr surfacing: all THREE `tracker_links_create_blocked_by`
  arms (forward lib lines 1713, 1751, 1835) now capture stderr to `link_err`
  and fold the first `MESSAGE:` line into the partial-failure entry. No
  early `return 1` exists between the `mktemp` (line 1673) and both cleanup
  sites (2060, 2066) — no temp-file leak path (awk scan over the range
  returned empty).
- BFS path naming (`scripts/lib/tracker-cycle-check.sh:288-323`): predecessor
  map reconstruction is correct (src is checked before the visited-set insert,
  so every reconstruction chain terminates at tgt; hop-1 and deeper cases
  verified by tests 5.4 in `test-tracker-cycle-check.sh` + 5.5 in
  `test-tracker-links.sh`).
- Forward-test Group 8 reproduces the live topology (BD-701⇄BD-702 + shared
  BD-703) and asserts rc=1, typed error, full path, **byte-empty gh log**
  (`[[ ! -s "$GH_LOG_CY" ]]`), no id-map, `--dry-run` parity, and absence of
  the legacy swallowed step-7 shape. Group 8 ran green in my battery.

### 1.3 Fix-pass enablers (criterion 3) — CLEAN

- **State-serving mock `issue list`:** consumers enumerated independently —
  exactly two `provider_list` call sites in libs (forward stabilization poll
  line 2297; reverse roster discovery `tracker-migrate-reverse.sh:1335`).
  `tracker_provider_gh_list` lowercases `state` per item and never surfaces
  `stateReason`, so the mock's uppercase storage is normalized on the read
  path. The reverse roster unions list ids with the id-map and dedups
  (`unique`), so the previously-canned-`[]` behavior is subsumed, not
  changed. Prior assertions 6.2/6.4 (`re-run has NO step-7 link failure`)
  remain meaningful and green. No prior assertion weakened.
- **`TMF_STABILIZE_SLEEP_SECS=0` seam:** test-only (set in the test file
  only; lib default untouched at `tracker-migrate-forward.sh:116`),
  documented in the lib's pre-existing seam comment (lines 109-117). See
  NIT-1 on the comment's "must be set BEFORE source" wording.
- **New legs genuinely pin the e2e chain:** my independent normalizer-revert
  probe (§1.1) fails leg 2.2e on both the normalize assertion AND the decoded
  `Cancelled` assertion. Leg 1.2 separately pins that the stored mock shape
  is the uppercase read-back enum (`CLOSED`/`NOT_PLANNED`), so a
  lowercase-mock regression that would mask the normalizer is itself pinned.
  The close-vocabulary tooth (mock exits 1 on a non-CLI reason token) is
  load-bearing via the leg-1.1 rc=0 assert.
- Fixture entry BD-004 conforms to the entry contract (`Status: Cancelled`
  is an admitted lifecycle state per `/backlog/_rules.md` § Lifecycle;
  `Blockers: None` keeps the pre-pass inert).

### 1.4 check-40 T3 rebuild (criterion 4) — CLEAN

- `_build_basename_index` reads module globals `REPO_ROOT` +
  `_CHECK_40_EXCLUDE_PARTS` at call time (`scripts/validate-pack.py:5254-5285`),
  so the test's `mod.REPO_ROOT` swap (with `try/finally` restore + rmtree) is
  sound. `_CHECK_40_EXCLUDE_PARTS` (lines 5245-5251) contains both fixture
  roots the synthetic tree plants copies under.
- **Both directions probed in-memory (no repo edits):** real EXCLUDE →
  `['tracker.toml']` (T3 PASS); neutered EXCLUDE → 3 candidates leak (T3
  FAIL as designed — covers what the old live-index leg pinned); over-broad
  EXCLUDE → `[]` (T3 FAIL as designed — the direction the old leg never
  tested). T1/T2/T4 untouched.
- check-40 suite green ON THE REAL Mode-3 TREE with root `tracker.toml`
  present (`ls tracker.toml` → exists; suite 19 in my battery: FAIL: 0).

### 1.5 Battery, manifest, scope (criteria 5 + rules 6/7/8) — CLEAN

- `python3 scripts/validate-pack.py` → `PASSED — all checks clean`;
  `PACK_VALIDATE_DEEP=1` → `PASSED — all checks clean`.
- Full CI battery: all 54 `run: bash` commands extracted verbatim from
  `.github/workflows/validate-pack.yml` (= the 52 test suites + the 2
  `test-fixtures/build.sh` steps), run sequentially FOREGROUND. **54/54
  rc=0** (results `/tmp/bd204-rev2-battery-results.txt`; logs
  `/tmp/bd204-rev2-suite-N.log`). Batch-affected counts: provider 162/0,
  forward 199/0, reverse 150/0, roundtrip 79/0, links 44/0, cycle-check
  28/0, check-40 8-tests FAIL:0 — matching the FIX1 report's claims.
- Live oracle: `tracker-bd204-lossless-roundtrip-test.sh` is NOT in CI
  (grep of the workflow: no match) and default-SKIPs as its first action
  (verified by running it: `SKIP: live-GH oracle...`, rc=0). **Zero live
  GitHub calls made by this review** (all probes used fake-gh PATH shims).
- Manifest: `bash test-fixtures/build.sh --all --clean` (suite 47) +
  `--verify` (suite 48) both rc=0; `git diff test-fixtures/manifest.txt`
  empty and `git status --porcelain test-fixtures/` empty afterward —
  **byte-stable confirmed** (the `scripts/lib`/`scripts/tests` paths are not
  client-shipped).
- pack-only: `git diff --name-only` = exactly the 12 expected `scripts/`
  files (4 libs, 7 test suites, 1 test fixture). Untracked additions:
  2 IMPL reports + 1 prior review + the architect doc (workflow artifacts,
  Pattern B) + `tracker.toml` (Pack-Chat-owned runtime). Nothing under
  `project-template/` or `supporting-docs/`. Check-36 `pack-only` claim
  would hold.
- Checklist sweeps with no findings: trinity (no trinity files touched —
  N/A); README layout (no tracked files added/moved/removed — N/A);
  validate-pack alignment (no new files/dirs — N/A); migration safety (no
  client-shipped files touched, per byte-stable manifest — N/A); typed
  deferral-comment format (no plain TODO/FIXME in the diff); no stale
  references to the changed error-message shapes (`cycle of length`
  assertions: none outside the lib; `step-7 link blocked-by` consumers: only
  the intentional test assertions).

---

## 2. Findings

### SHOULD-1 — pre-pass edge-vocabulary comment asserts a parity that is FALSE for single-digit `phase-N.M`; exposes a PRE-EXISTING latent routing defect needing a tracked anchor

- **Anchor:** `scripts/lib/tracker-migrate-forward.sh:694-703` (new comment:
  "Edge vocabulary: only tokens the step-7 link arms route to blocked-by
  edges participate — `BD-NNN`, `TD-NNN`, `phase-N.M`") vs the PRE-EXISTING
  step-7 glob at line 1702: `phase-[0-9][0-9]*.[0-9][0-9]*`.
- **Empirical:** in bash glob semantics `[0-9][0-9]*` is digit + digit +
  any-string (NOT "one or more digits" — that is regex thinking). Verified:
  `phase-3.2` does NOT match the phase-task arm and falls to the
  `phase-[0-9]*` PARENT arm (line 1728); `phase-12.34` matches. So the
  step-7 arms route single-digit-N `phase-N.M` blockers (the realistic
  shape) to the sub-issue-parent path, not blocked-by — the BD-108 F9
  "tightening" regressed the pre-F9 `phase-[0-9]*.[0-9]*` which DID match
  `phase-3.2`. The existing forward-test Group 6 assertion 6.2 cannot detect
  this: both the phase-task arm and the parent arm silent-skip when the
  target is absent from the id-map (parent arm line 1731 `if [[ -n
  "$parent_gh_id" ]]` with no else), and phase-tasks are never in the
  id-map at v11.0 (BD-108 §10.2), so the mis-routing is currently LATENT
  (zero behavioral difference today). It becomes live the day phase-task
  creation lands.
- **Impact on THIS batch: none functional.** In the pre-pass digraph,
  `phase-N.M` tokens are pure sinks (only entry pack_ids — BD/TD — have
  outgoing edges), so they can never close a cycle; the regex being a
  superset of actual routing cannot cause a false refusal. The defect in
  this change is documentary only.
- **Asked fix (this batch):** soften/correct the new comment at lines
  694-703 (and the matching `edge_re` comment at 730-732) — e.g., "tokens
  the step-7 link arms are DESIGNED to route to blocked-by edges (BD-108
  F3); NOTE the current `phase-[0-9][0-9]*.[0-9][0-9]*` glob only matches
  N≥10 — see BD-NNN" — one comment edit, no logic change.
- **Asked anchor (Pack Chat):** open a BD for the pre-existing F9 glob
  defect (`phase-[0-9][0-9]*.[0-9][0-9]*` → a form matching single-digit N/M,
  e.g. case-arm regex test, + a Group-6 assertion that can actually
  distinguish the arms). Per `deferred-work-tracked-anchor` this cannot live
  only in this report.

### NIT-1 — seam comment overstates the before-source constraint

- **Anchor:** `scripts/tests/tracker-migrate-roundtrip-test.sh:46-52` —
  "must be set BEFORE the libs are sourced (the lib captures the value at
  source time via ${TMF_STABILIZE_SLEEP_SECS:-2})". The lib's
  default-assignment runs at source time, but the variable stays mutable;
  setting it AFTER sourcing would override equally (the poll reads the var
  at call time, `tracker-migrate-forward.sh:2320/2342`). The chosen
  placement is correct and conservative; only the stated *reason* is
  imprecise and could mislead a future maintainer.

### NIT-2 — step-6 parent arm still swallows stderr (pre-existing, same class as the fixed arms)

- **Anchor:** `scripts/lib/tracker-migrate-forward.sh:1732-1738` —
  `provider_sub_issue_create ... >/dev/null 2>&1` with a bare
  `step-6 sub_issue_create: %s -> %s` partial-failure line, cause-less,
  exactly the unactionable shape this batch fixed for the three blocked-by
  arms. Pre-existing; not a regression; the incident class (swallowed cycle
  refusal) cannot occur here (no cycle check on parent links). Fold into the
  SHOULD-1 BD or fix as a fourth arm in the fix pass.

### NIT-3 — pre-pass refusal message hardcodes GitHub in a provider-agnostic layer

- **Anchor:** `scripts/lib/tracker-migrate-forward.sh:790` — "GitHub cannot
  represent a blocked-by cycle (its own addBlockedBy validation rejects
  it)". `tracker-migrate-forward.sh` dispatches via `provider_*`; with a
  non-gh backend the parenthetical would be inaccurate (the refusal itself
  is correct for any tracker — cyclic Blockers is a data error regardless).
  Cosmetic; current backends are github + stub.

### Notes for Pack Chat (not coder findings)

- **Staging hazard:** root `tracker.toml` is untracked and NOT gitignored
  (`git status` shows `?? tracker.toml`). The standing `git add -A` commit
  idiom would stage it alongside the batch. Exclude it (and the concurrent
  architect doc, if it is not meant to ride this commit) explicitly.
- **Pass-1 bookkeeping:** the FIX1 report records pass-1 MUST-1/NIT-1 as
  Pack-Chat-owned bookkeeping left untouched by the fix-coder; `backlog/
  BD-204.md` is `Status: Open` (correct until batch completion). Confirm
  those items are executed at/with the commit.

---

## 3. READ-IN-FULL attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | FULL via Read tool | 579 |
| `/tmp/bd204-c8-rerun.log` | FULL via Read tool | 15 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | FULL via Read tool | 42 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | FULL via Read tool | 14 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ triggered by the memory file) | section read (lines 206-233) | — |
| `/backlog/_rules.md` + `/changelog/_rules.md` (reviewer-role inputs) | FULL via Read tool | 94 + 66 |

Section reads per prompt: `_gh_normalize_issue` (provider-gh 219-262);
`_tmr_decode_status` (reverse 200-290); `tmf_blockers_cycle_precheck`
(forward 675-802) + link arms (1672-1860) + stabilization poll (2235-2350) +
seam params (95-125); BFS (cycle-check 288-323); roundtrip fake-gh + new
legs (full diff + source 1-260, 500-700, 950-1030); check-40 T3 (full diff +
validate-pack 5245-5285). Both IMPL reports read.

## 4. Verdict

**APPROVE-WITH-FIXES.** The batch is functionally commit-ready: all five
success criteria verified empirically (including independent revert-probes
for the casing teeth and T3 directions, and an isolated real-topology probe
for the pre-pass), 54/54 CI commands green including check-40 on the real
Mode-3 tree, manifest byte-stable, pack-only scope intact. SHOULD-1 is a
one-comment alignment in new code plus a Pack-Chat BD-open for the
pre-existing F9 glob defect it exposed; NITs are optional per triage.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs run: `git rev-parse HEAD`, `git status --porcelain`, `git diff` (names/stat/content). Final `git status --porcelain` byte-identical to session start (12 `M` + 5 `??`); HEAD `1c18b28c4d...` unchanged. All probe mutations confined to `/tmp/bd204-rev2-*`. Only file write: this report. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op on any repo or trusted file; `rm -rf` used only on `/tmp/bd204-rev2-probe` and `/tmp/bd204-rev2-cyreal` (dirs I created this session); `tracker.toml` / `.pack-tracker/` read-only-untouched (mtime-bearing `git status` unchanged; cycle probe ran in a /tmp copy). | COMPLIANT |
| preflight-stop-means-stop | Emitted verbatim before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1c18b28c4d149d3e80565beafccc84f8d25b32f2; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW2.md`. No parent stop message received. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored (`PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block, lines 206-233, read before constructing). No empty rows; no AMBIGUOUS. | COMPLIANT |
| agents-read-rule-docs-in-full | §3 table: CLAUDE.md 579 lines, c8-rerun.log 15 lines, verify_full_ci_suite 42 lines, rules_applied_block 14 lines — each read IN FULL via Read tool (outputs in transcript); plus _rules.md pair (94/66). | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → `PASSED — all checks clean`; `PACK_VALIDATE_DEEP=1` → same; 54/54 workflow `run: bash` commands rc=0 FOREGROUND (`grep -cv "rc=0" /tmp/bd204-rev2-battery-results.txt` → `0`), incl. check-40 (suite 19, `FAIL: 0`) on the real tree with root `tracker.toml` present; live oracle not in CI and default-SKIPs (`SKIP: live-GH oracle...`, rc=0). Counts: provider 162/0, forward 199/0, reverse 150/0, roundtrip 79/0, links 44/0, cycle-check 28/0. | COMPLIANT |
| regenerate-manifest-v11-surface | Suite 47 `bash test-fixtures/build.sh --all --clean` rc=0 + suite 48 `--verify` rc=0; then `git diff --stat test-fixtures/manifest.txt | wc -l` → `0` and `git status --porcelain test-fixtures/` → empty. Byte-stable claim VERIFIED. | COMPLIANT |
| pack-only (BD-204 HARD constraint) | `git diff --name-only` → exactly 12 paths, all `scripts/...` (listed §1.5). Untracked: 3 workflow reports + architect doc + `tracker.toml` (runtime). No `project-template/` or `supporting-docs/` paths anywhere in the diff. | COMPLIANT |
| scope-deliverables-to-the-ask | 1 SHOULD + 3 NITs, each with file:line anchor; SHOULD-1 is anchored to NEW comment text in the diff (the pre-existing glob defect is routed to a Pack-Chat BD anchor, not graded against the coder); NIT-2/3 explicitly labeled pre-existing/cosmetic. No drive-by re-architecture proposals. | COMPLIANT |
