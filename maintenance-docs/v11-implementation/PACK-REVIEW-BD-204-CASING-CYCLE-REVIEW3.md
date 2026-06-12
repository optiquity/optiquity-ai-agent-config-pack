# PACK-REVIEW — BD-204 casing+cycle batch, reviewer pass 3 (FINAL)

- **Branch:** `v11-dev`; **HEAD (unchanged all session):**
  `1c18b28c4d149d3e80565beafccc84f8d25b32f2`
- **Date:** 2026-06-11
- **Reviewer:** fresh pack-reviewer (pass 3 of the bounded review/fix
  cycle — final pass; no fix-coder pass 3 permitted)
- **Scope reviewed:** the ENTIRE uncommitted BD-204 batch — full
  `git diff` vs HEAD (12 modified files, all under `scripts/`),
  excluding the out-of-scope untracked artifacts (root `tracker.toml`,
  `.pack-tracker/`, concurrent agents' ARCHITECTURE / PLAN / AMENDMENT
  / RESEARCH deliverables).
- **Prior reviews:** NOT read (`PACK-REVIEW-BD-204-CASING-CYCLE.md`,
  `-REVIEW2.md` present in the tree but untouched per prompt). The
  three IMPL reports (base, FIX1, FIX2) were read as permitted.

## VERDICT: APPROVE

The batch is commit-ready. Zero BLOCKER / MUST / SHOULD / NIT findings.
Every success criterion was verified empirically in this session (all
commands foreground); details below, including what was checked where
clean.

---

## 1. Casing teeth — revert-probe (criterion 1)

Probe method: copied `scripts/` to `/tmp/bd204-rev3-probe/` (real tree
untouched), reverted ONLY the normalizer line in the copy
(`"state_reason": state_reason_in.lower() if isinstance(...) else None`
→ pre-fix `opt(data, "stateReason")` passthrough), ran the three
pinning suites against the copy:

| Layer | Suite (probe copy) | Result on revert |
|---|---|---|
| Provider boundary | `tracker-provider-test.sh` | **161/1 FAIL** — `1.2b normalize: live stateReason NOT_PLANNED → canonical not_planned` |
| Decoder unit (production normalizer in chain) | `tracker-migrate-reverse-test.sh` | **148/2 FAIL** — both `1.1c` NOT_PLANNED legs (Cancelled, Deprecated) |
| Roundtrip e2e | `tracker-migrate-roundtrip-test.sh` | **77/2 FAIL** — `2.2e ... state_reason=not_planned` + `2.2e BD-004 decodes to Cancelled` |

Five assertions flip to FAIL without the one-line fix — the decode arms
are genuinely pinned at all three layers. Two probe observations, both
CORRECT behavior: `2.2e ... state=closed` still passes on revert
(`state` was already lowercased pre-fix — only `stateReason` was the
defect, matching the IMPL-REPORT root-cause); and `2.2e BD-004
reconstructed to tree with Status: Cancelled` still passes on revert
because the reconstruction reads the authoritative `pack-entry-body-gz64`
blob bytes, not the decoder — that leg pins blob survival, and the
explicit decode assertion is the casing tooth. Probe deleted after use.

Also verified in the real diff: the fix is at the single read-back
normalization site (`_gh_normalize_issue`), non-string `stateReason` →
`None` (null-safe), write side untouched (`provider_close` already
emits lowercase interface tokens). The `_tmr_decode_status` change is
comment-only (casing-contract cross-reference); decoder logic unchanged
— verified by reading the full decoder: lowercase vocabulary
`completed` / `not_planned|duplicate` + `status:deprecated` label
discriminator, exactly as the new tests assert.

## 2. Cycle pre-pass + four link arms (criterion 2)

**Pre-provider, full path, real tree.** Beyond the batch's Group 8
(mock-witnessed empty gh log), I ran the forward dry-run on the REAL
repo tree with a BLOCKING gh shim on PATH (any gh invocation would
print `BLOCKED:` and exit 97 — none fired):

```
forward: parsed 213 BACKLOG entries, 0 phase(s)
ERROR: validation
MESSAGE: forward: Blockers data contains dependency cycle(s) — refusing before any provider call. Cyclic Blockers data is a data error regardless of tracker backend; fix the Blockers: lines of the entries named below and re-run.
  cycle path: BD-094 -> BD-095 -> BD-094 ('->' = blocked-by)
→ Run: pack tracker doctor
```

The real backlog still carries the cycle (`backlog/BD-094.md` →
`Blockers: BD-088, BD-095, BD-085`; `backlog/BD-095.md` → `Blockers:
BD-085, BD-088, BD-094`); the real-tree fail-loud-at-parse is BY DESIGN
and now actionable (both IDs + closed loop named). Zero mutations: no
`.pack-tracker/` writes occur before the refusal (`tmf_mapping_load` is
read-only; the precheck's only write is its own `/tmp` mktemp, removed).

**Placement verified in source:** the precheck call sits at the
forward-run between parse and the `--dry-run` return
(`tracker-migrate-forward.sh`, `tracker_migrate_forward_run`,
immediately after the `forward: parsed ...` echo) — before
`partial_failures` mktemp and every provider step. Nothing upstream of
it touches a provider (config resolve + mapping load are file ops).

**DFS correctness:** hand-traced the iterative GRAY/BLACK DFS in
`tmf_blockers_cycle_precheck` over the Group-8 topology
(BD-701⇄BD-702 + shared sink BD-703): exactly one cycle reported,
`BD-701 -> BD-702 -> BD-701`; self-loops covered; `parent`-style
path-index reconstruction cannot KeyError (cycle slice is taken from
the live `stack_path`). Edge vocabulary regex excludes bare `phase-N`
(parent links) per design; `phase-N.M` tokens are sinks (only BD/TD
entries contribute outgoing edges) so the regex's deliberate superset
of step-7's actual routing cannot produce a false refusal — confirmed
against my own glob measurement (§5). Fail-closed: unparseable entries
JSON → rc=1 via typed `schema-reshape`. Unbounded full pass — catches
cycles longer than `cycle_check_k`, complementing the K-hop BFS.

**BFS cycle-path naming (`tracker-cycle-check.sh`):** hand-traced the
predecessor-map reconstruction for both test topologies — 2-cycle
(`phase-3.2 -> TD-031 -> phase-3.2`) and 3-cycle
(`TD-029 -> TD-031 -> TD-040 -> TD-029`) — the asserted strings are
exactly what the code produces; every non-tgt path node received a
`parent[]` entry at first visit, so reconstruction cannot KeyError.
rc semantics unchanged (0/1/2); message retains the prior
`cycle of length %d` + `pack tracker doctor` content (prior assertions
in `test-tracker-cycle-check.sh` 5.3 and `test-tracker-links.sh` 5.5
unweakened, now extended with path assertions — all green).

**All four link arms (three blocked-by + step-6 parent):** each arm now
redirects stderr to the shared `link_err` mktemp (truncated per
redirect — no stale reads), extracts the first `MESSAGE:` line
(`sed -n 's/^MESSAGE: //p' | head -n 1` — single-line guaranteed), and
appends it `:+`-guarded to the SAME partial-failure line.
**Accounting unaltered:** one `partial_failures` line per failure (the
reason rides the same line, so the `wc -l` count `n_pf` is unchanged),
success-counter increments untouched. **No leak:** `link_err` is
created at the top of the link section and removed at both function
exits; I enumerated every `return` between creation and cleanup — none
exist; the earlier create-failure returns (which predate `link_err`)
already `rm -f "$partial_failures"` themselves. The step-7b herestring
loop's stdin is unaffected by the stderr redirect. The pre-existing
absence assertion (forward-test 6.4 `step-7 link blocked-by` and the
6.2 `step-6 sub_issue_create: BD-501 -> phase-3.2` substring) survives
the suffix-append by construction — confirmed green in the battery.

## 3. Roundtrip e2e chain + enablers (criterion 3)

- **Fixture `BD-004` (Status: Cancelled):** exercises the production
  step-8 close loop (`Cancelled → not_planned` mapping verified in the
  close-loop case arm) → provider CLI form (`"not planned"`, validated
  by the mock against the real vocabulary — a regressed token exits 1
  and fails rc=0) → live read-back storage (`CLOSED`/`NOT_PLANNED`) →
  production normalize → decode → `Cancelled`. `Blockers: None` keeps
  it inert for the cycle pre-pass.
- **Mock realism:** `issue close` stores the GraphQL-enum read-back
  shape; `issue create`/`reopen` store `OPEN` — the mock can no longer
  mask a normalization regression (proven by the revert-probe: the e2e
  legs DID fail against the reverted normalizer).
- **State-serving `issue list` arm:** required because the closed
  fixture entry activates the BD-132 stabilization poll
  (`provider_list label/state=closed`); a canned `[]` would poll to the
  attempt ceiling (floor check `cur_count >= closes_attempted`) and
  fail the run. Filter logic verified: `--state` compares against the
  stored uppercase casing via `ascii_upcase`; `--label` matches the
  label objects; value-taking flags consumed correctly. Battery shows
  `1.2 close-stabilization ran and completed` green.
- **`TMF_STABILIZE_SLEEP_SECS=0` seam:** verified against source — the
  lib's line 116 is a `:-` default-assignment at source time and the
  only reads are `sleep "$TMF_STABILIZE_SLEEP_SECS"` inside the poll
  (call-time reads at lines 2345/2367) — the corrected comment
  ("placement is convention, not a hard requirement") is TRUE.
- **No prior assertion weakened:** all count updates (3→4 entries,
  5→6 issues/mapping, 4→5 in Group 6) are the mechanical consequence
  of the added fixture entry; every pre-existing assertion string
  retained; absence assertions retained; idempotency Group 3 still
  byte-compares create signatures across runs (6 issues).

## 4. check-40 T3 (criterion 4)

The rebuilt T3 monkeypatches `mod.REPO_ROOT` (read at call time by
`_build_basename_index` — verified at `validate-pack.py`
`_build_basename_index`, which uses module-global `REPO_ROOT.rglob`)
onto an isolated synthetic tree with same-basename `tracker.toml`
copies under BOTH excluded roots (`test-fixtures/`,
`scripts/tests/fixtures/`) plus a root-level copy, restoring
`REPO_ROOT` in a `finally` and removing the tmpdir. The equality
assertion `t3_cands == ["tracker.toml"]` covers BOTH failure
directions: a broken EXCLUDE yields 3 candidates (fail); an over-broad
EXCLUDE yields 0 (fail). This is strictly stronger than the replaced
live-tree absence assertion, and decoupled from the live tree's tracker
mode (the old leg was false-failing on Mode-3 trees with a legitimate
root `tracker.toml`). Suite 19 green (8/8) on the REAL Mode-3 tree with
root `tracker.toml` present; live Check 40 also green inside
`validate-pack.py` (PASSED, both normal and DEEP).

## 5. Fix-2 comment truth + typed deferral (criterion 5)

**Glob matrix — measured myself** (bash case statement, exact arms and
order from the link loop):

```
phase-3.2   -> parent arm        phase-10.12 -> phase-task glob MATCH
phase-10.2  -> parent arm        phase-12.34 -> phase-task glob MATCH
phase-2.10  -> parent arm        phase-3 / phase-30 -> parent arm
phase-3foo.4 / phase-3.2.5 -> parent arm
```

The docstring's claim — `phase-[0-9][0-9]*.[0-9][0-9]*` matches only
when BOTH N and M have ≥2 digits; `phase-3.2` and `phase-10.2` fall to
the `phase-[0-9]*` parent arm — is exactly TRUE (my `phase-2.10` probe
confirms the BOTH-positions form). The "harmless for this pre-pass"
reasoning is sound (sinks cannot close cycles; superset matching cannot
false-refuse). The "latent at v11.0" claim is consistent with both arms
silent-skipping absent id-map targets (verified: both arms guard on
`[[ -n "$..._gh_id" ]]`).

**Typed-deferral conformance:** `# KNOWN GAP(functional): TD-TBD — ...`
matches the canonical format at `project-template/CLAUDE.md`
§ "Deferral comments and BACKLOG hygiene" (severity `functional` is in
the vocabulary; `TD-TBD` is mandatory there — "never a real TD number").
The anchor BD is queued but unopened (highest entry is
`backlog/BD-213.md`; no glob-defect entry exists — verified by ls +
grep). The live typed marker IS a valid tracked anchor per
`deferred-work-tracked-anchor`; the Pack-Chat action (open the BD,
optionally substitute the id) is carried in IMPL-REPORT-FIX2 §4.

**Other fix-2 claims:** seam comment TRUE (§3); refusal message now
provider-neutral while the asserted prefix `Blockers data contains
dependency cycle` is retained verbatim (grep: the only `scripts/`
consumers are the emitter and the forward test — both consistent; no
test pins the removed GitHub/addBlockedBy sentence; the docstring's
remaining GitHub mention is incident narrative, acceptable).
**Non-comment delta limited to NIT-2 + message wording:** inspecting
the full folded diff, the only behavior-bearing fix-2 change is the
step-6 parent arm's stderr surfacing (byte-pattern-identical to the
three blocked-by arms); NIT-3 changed only the emitted MESSAGE text
(no control flow), and SHOULD-1/NIT-1 are comments. Consistent with
the FIX2 report's per-finding before/after quotes.

## 6. Battery / manifest / scope (criterion 6 + constraints)

- `python3 scripts/validate-pack.py` → rc=0 `PASSED — all checks
  clean`; `PACK_VALIDATE_DEEP=1` → rc=0 PASSED. (FOREGROUND)
- **Full unattended battery:** all 54 `run: bash` commands extracted
  verbatim from `.github/workflows/validate-pack.yml`, run sequentially
  FOREGROUND in three chunks → **54/54 rc=0**
  (`/tmp/bd204-rev3-results.txt`, per-suite logs
  `/tmp/bd204-rev3-suite-N.log`). Includes real-tree check-40
  (suite 19), fixture build+verify (47/48), `test-v11-realistic-ot.sh`
  (49).
- Batch-affected suite counts (Passed/Failed): provider **162/0**,
  forward **199/0** (incl. new Group 8, 9 asserts), reverse **150/0**
  (incl. 1.1c ×3), roundtrip **79/0** (incl. 1.2 + 2.2e), links
  **44/0**, cycle-check **28/0**, check-40 **8/0**.
- **Live oracle:** `tracker-bd204-lossless-roundtrip-test.sh` →
  `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`,
  rc=0. Zero live GitHub calls made by this review.
- **Manifest byte-stable:** suite 47 (`build.sh --all --clean`) rc=0;
  `git diff --stat test-fixtures/manifest.txt` immediately after →
  EMPTY; suite 48 (`--verify`) rc=0 against the committed manifest.
  The batch's `scripts/lib` + `scripts/tests` edits are not
  client-shipped — nothing to stage.
- **pack-only:** `git diff --name-only` = exactly the 12 expected
  `scripts/` files (4 lib, 1 fixture, 7 tests). Nothing under
  `project-template/` or `supporting-docs/`. Untracked set = the named
  out-of-scope artifacts + the IMPL/PACK-REVIEW reports + concurrent
  agents' `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT{,-AMENDMENT}.md` /
  `PLAN-BD-204-MODE3-OPS-CONTRACT.md` (the AMENDMENT file appeared
  mid-session from a concurrent thread; not touched, not assessed)
  + this report. Post-battery `git status` modified-set unchanged;
  HEAD unchanged.

## 7. Findings

**None.** No BLOCKER, MUST, SHOULD, or NIT. Items examined and
explicitly cleared as non-findings:

- `_tmf_cyc_line` read-loop variable not `local` — matches the file's
  established convention (e.g. `_rc_pack_id` in the close-retry sweep);
  `_tmf_`-namespaced; not a defect.
- `partial_failures` cleanup on the pre-link early-return paths — those
  paths `rm -f` it themselves (verified at the compose-failure return);
  `link_err` does not exist there. No temp-file leak introduced.
- Group 8 calls `tracker_migrate_forward_run` with 3 args — 4th
  (`mirror_only`) defaults to 0 per the signature; fine.
- The unopened glob-defect BD — Pack-Chat bookkeeping at commit time
  (carried in FIX2 §4); the typed `KNOWN GAP(functional): TD-TBD`
  marker is the valid live anchor meanwhile.

**Note for Pack Chat (not a finding):** when staging, remember the
glob-defect BD open (FIX2 §4) and the BD-094/BD-095 Blockers data
correction (a live Pack-Chat operation deliberately excluded from this
batch per the base IMPL-REPORT scope note).

## 8. READ-IN-FULL attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | FULL via Read tool | 579 |
| `/tmp/bd204-c8-rerun.log` | FULL via Read tool | 15 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | FULL via Read tool | 43 |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | FULL via Read tool | 15 |

Sections also read per prompt: `_gh_normalize_issue` (full),
`_tmr_decode_status` (full), `tmf_blockers_cycle_precheck` + all four
link arms + `_tmf_wait_for_close_stabilization` (full), the
`tracker-cycle-check.sh` BFS (full), all new test legs / fixture / mock
arms (full diff + surrounding context), check-40 T3 +
`_build_basename_index`, `backlog/_rules.md` + `changelog/_rules.md`
(pack-reviewer standing inputs), `project-template/CLAUDE.md` deferral
section, and the three IMPL reports.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Only read-only git verbs run: `git rev-parse HEAD`, `git status --porcelain`, `git diff` / `--stat` / `--name-only`, `grep` over tracked files. No add/commit/push/tag/stash/reset/restore/checkout at any point. End-state HEAD `1c18b28c4d...` unchanged; modified-set identical to session start (12 `M scripts/...` entries quoted in §6). Revert-probe ran in `/tmp/bd204-rev3-probe` (a `cp -R` of `scripts/`), never the repo. Output = this report only. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive op on repo content: zero Edit/Write on tracked files; `rm -rf` used ONLY on my own `/tmp` scratch (`/tmp/bd204-rev3-probe`, mktemp shim dir) — self-created scratch, not trusted files. Nothing required surfacing/stopping. | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted verbatim immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1c18b28c4d149d3e80565beafccc84f8d25b32f2; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW3.md`. No parent stop message received. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table: one row per prompt rule (9/9), each with quoted command output/measurement; no empty evidence cells; no AMBIGUOUS conclusions. | COMPLIANT |
| 5. agents-read-rule-docs-in-full | §8 table: all four named files read IN FULL via Read tool with line counts (579 / 15 / 43 / 15). All prompt-named code sections read; glob claim re-measured independently (§5 matrix). | COMPLIANT |
| 6. verify-full-ci-suite | §6: `validate-pack.py` rc=0 + DEEP rc=0 (`PASSED — all checks clean`); 54/54 workflow `run: bash` commands rc=0, ALL FOREGROUND (results file `/tmp/bd204-rev3-results.txt`; every line `rc=0`), incl. real-tree check-40 (suite 19, 8/0) and `test-v11-realistic-ot.sh` (suite 49). Live oracle default-SKIP rc=0 (`SKIP: live-GH oracle ...`). Suite counts: provider 162/0, forward 199/0, reverse 150/0, roundtrip 79/0, links 44/0, cycle-check 28/0. 54/54-class green met. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | Battery suite 47 `bash test-fixtures/build.sh --all --clean` rc=0; immediately after: `git diff --stat test-fixtures/manifest.txt` → empty (quoted in /tmp/bd204-rev3-manifest-diff.txt: zero lines); suite 48 `--verify` rc=0 against the committed manifest. Byte-stable claim VERIFIED — nothing to stage. | COMPLIANT |
| 8. pack-only (BD-204 HARD constraint) | `git diff --name-only` → exactly: `scripts/lib/tracker-cycle-check.sh`, `scripts/lib/tracker-migrate-forward.sh`, `scripts/lib/tracker-migrate-reverse.sh`, `scripts/lib/tracker-provider-gh.sh`, `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md`, `scripts/tests/test-tracker-cycle-check.sh`, `scripts/tests/test-tracker-links.sh`, `scripts/tests/test-validate-pack-check-40.sh`, `scripts/tests/tracker-migrate-forward-test.sh`, `scripts/tests/tracker-migrate-reverse-test.sh`, `scripts/tests/tracker-migrate-roundtrip-test.sh`, `scripts/tests/tracker-provider-test.sh`. Untracked additions = the named artifacts + IMPL/REVIEW reports + concurrent-thread deliverables + this report (§6). Zero live GitHub calls (oracle SKIP; real-tree probe used a BLOCKING gh shim that never fired). | COMPLIANT |
| 9. scope-deliverables-to-the-ask | Findings section contains zero speculative items; every examined-and-cleared item is listed with the dismissal rationale (§7); out-of-scope untracked artifacts not assessed; pre-existing non-batch code (early-return cleanup, BD-108 glob defect) examined only as far as needed to clear batch claims, with the glob defect left on its existing queued-BD anchor rather than re-litigated. | COMPLIANT |
