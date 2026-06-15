<!-- pack-only planning artifact — TARGETED RE-PLAN of BD-219 commit C2. SUPERSEDES §C2 of PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md. Folds in ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md (the settled static-matrix resolution). Feeds the C2 coder. Not a client deliverable. -->
# PLAN — BD-219 C2 (REVISED): static-matrix `tests` job + wired-set re-point

**Planner:** pack-planner (fresh; targeted C2 re-plan after the wired-set-source addendum)
**Date:** 2026-06-15 · **Repo HEAD at planning:** `38e0ae4f6fc9ee5f872546e1622f990794b384dc` (branch `v11-dev`; contains BD-219 C1 `3afccec` + C3 `38e0ae4`; **C2 NOT yet committed**)
**Supersedes:** `PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §C2 (the stale dynamic-`plan`-job plan). §1 (shared contracts), §C1, §C3, §C4 of that plan remain authoritative; only §C2 is replaced.
**Blueprint:** `ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md` (the settled resolution — read in full; this plan SEQUENCES it, does NOT redesign it).

> This is an EXECUTION re-plan of ONE commit (C2). It turns the architect's
> settled static-matrix resolution into an exact, ordered, per-file recipe a
> coder can follow without ambiguity. It does NOT relitigate any settled
> design element (4 shards, weights, allowlist, `--only-check`, Checks 58/59,
> the aggregator). Every repo-state fact carries an Empirical-Evidence Block
> (bottom). I re-measured all load-bearing claims at HEAD `38e0ae4` 2026-06-15.

---

## READ ATTESTATION (each read IN FULL or at the exact cited region; no skim/crop/derive)

| Doc / artifact | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" (all rules) | YES (full, session context) |
| `backlog/BD-219.md` (lines 1–22, incl. the 2026-06-14/15 notes) | YES (full) |
| `ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md` (the resolution — blueprint) | YES (lines 1–302, full) |
| `ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` §2.4 (matrix run-loop 120–173) / §2.5 (fixture cohesion) / §5 / §6 | YES (cited regions) |
| `PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §C2 (the stale plan, 427–508) + §1 (shared contracts, 79–151) | YES (full) |
| COMMITTED `scripts/lib/ci-shard-plan.py` (`parse_wired_tests` @109, modes, header consumers @18–25, `FIXTURE_COHESION_GROUP` @94) | YES (lines 1–403, full) |
| COMMITTED Check 42 (`scripts/validate-pack.py` `wired_pattern` @6775) + Check 58/59/60 (6819–6977) | YES (full) |
| COMMITTED `.github/workflows/validate-pack.yml` (jobs @84; `tests` job @106; 71 `run: bash` lines; fixture region 314–356) | YES (full tests job) |
| COMMITTED `scripts/tests/test-ci-shard-plan.sh` (Group 1 empty-shard @73; Group 6 parse-equivalence @233–254) | YES (full) |
| COMMITTED `scripts/tests/test-validate-pack-check-42.sh` (synthetic `run_check` @198, `run: bash` synthesis @239; Group 3 `--only-check 42` @409) | YES (full) |
| `…/memory/feedback_verify_full_ci_suite.md` | YES (full) |
| `…/memory/feedback_manifest_regen_on_v11_surface.md` | YES (full) |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` | YES (full) |
| `…/memory/feedback_architect_planner_empirical_evidence.md` | YES (full) |

All load-bearing state-claims INDEPENDENTLY re-measured at HEAD `38e0ae4` on 2026-06-15 (Empirical-Evidence Blocks §EE-1…§EE-9). I reproduced the addendum's numbers (71 wired / 72 disk / 1 STRIP / 71 KEEP; 4 non-empty shards; union 71; Check 42 message strings; weights-TSV gap of exactly the 2 named tests).

---

## 0. C2 COMMIT OVERVIEW (the deliverable at a glance)

| Field | Value |
|---|---|
| **Commit** | C2 (3rd in the BD-219 sequence; **C2 lands AFTER C3** — dependency-justified §3) |
| **Scope keyword** | `pack-only` (exactly one; no other keyword token anywhere in the subject — §5) |
| **Surface** | pack-side only: `.github/workflows/` + `scripts/` (+ `test-fixtures/manifest.txt`) |
| **NEW files** | NONE — all six edited paths already exist (§EE-9). Isolated-coder merge-back is the **modified-files-patch** case (no new-file additions in the patch). |
| **Files edited** | (1) `.github/workflows/validate-pack.yml` (2) `scripts/lib/ci-shard-plan.py` (3) `scripts/validate-pack.py` (4) `scripts/tests/test-ci-shard-plan.sh` (5) `scripts/tests/test-validate-pack-check-42.sh` (6) `test-fixtures/manifest.txt` |
| **Manifest regen** | **YES** — C2 now edits `scripts/` (v11-surface), so the stale §C2 "NO regen (yml-only)" note is SUPERSEDED. Run `bash test-fixtures/build.sh --all --clean`; stage iff diff non-empty (§4 step 6). |
| **Verification** | FULL battery (general + deep validate-pack + EVERY wired test in the new `include` union = 71 + Check 58/59/60) + the ordered wired-set-non-empty PREFLIGHT gate w/ empty-set tripwire (§6) |
| **Review cycle** | own bounded cycle: fresh coder → reviewer → Pack-Chat triage → fix-coder (if needed) → final reviewer (max 2 fix pairs + 1 final pass). Plus the end-of-BD reviewer pass over the whole BD-219 batch. |
| **Effectiveness** | UNCHANGED — every wired KEEP test (71) runs exactly once per CI run, sharded; coverage correct-by-construction (§3 proofs, §7 invariants). |

**Subject (template):**
`feat: v11 — BD-219 C2: static-matrix tests job + re-point wired-set source to matrix include array (pack-only)`
The subject MUST NOT contain the literal tokens `project-only` or `pack-chat-only` anywhere (Check 36 substring-scans the whole subject; a denying token wins — §5).

**What changed vs the stale §C2 plan (the deltas this re-plan carries):**
1. The `tests` job is now a **STATIC `strategy.matrix.include[].scripts` array** frozen into the yml (generated once by `ci-shard-plan.py --emit-matrix` at maintenance time), NOT a dynamic `fromJSON(needs.plan.outputs.matrix)`.
2. The dynamic **`plan` job is REMOVED** (it was the circularity — it parsed the very `run: bash` lines C2 deletes). `tests-result.needs` becomes `[tests]` (was `[plan, tests]`).
3. C2 file scope **expands from yml-only to SIX files**: the two parsers re-point their wired-set anchor + their two encoding-surface tests + the manifest.
4. Manifest-regen flips **NO → YES** (C2 now edits `scripts/`).
5. The branch-protection coordination step stays DROPPED (established fact: branch protection not enabled — stale-plan §0; unchanged here).

---

## 1. SHARED CONTRACTS (inherited from the stale plan §1 — apply to C2's coder + reviewer)

C2 inherits these unchanged from `PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §1. Restated here so the C2 coder need not cross-read; the one delta is the manifest row (§1.1) which now applies YES.

- **§1.1 Manifest-regen (`regenerate-manifest-v11-surface`):** C2's diff touches `scripts/` → v11-surface → regen `test-fixtures/manifest.txt` (`bash test-fixtures/build.sh --all --clean`), then `git status --short test-fixtures/manifest.txt`; stage in the SAME commit iff `M`; if clean, note "manifest diff empty — not staged" in the IMPL-REPORT. (This SUPERSEDES the stale §C2 "NO regen" row.)
- **§1.2 Full-CI-suite (`verify-full-ci-suite`):** a green `validate-pack.py` is NOT a green commit. C2's coder PREFLIGHT and the reviewer's independent pass MUST run: (1) `python3 scripts/validate-pack.py` (general); (2) `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep); (3) EVERY test wired in the POST-C2 `include` union (71 scripts) — extract the complete list from the new matrix and run each, quoting each EXIT status (sampling is the BD-203/BD-214 CI-red defect); (4) enumerate-encoding-surfaces sweep for any assertion on changed validator/parser OUTPUT.
- **§1.3 Runtime-cost (`ci-check-runtime-compounding`):** the re-pointed Check 42 + Check 60 stay cheap (one regex/extraction over the yml + dir globs + small-file reads; no subprocess-per-script; route through `run_check` 2.0 s WARN). Removing the `plan` job nets one FEWER runner setup. No new compounding (§EE-blueprint §2.5).
- **§1.4 Commit-subject keyword (`commit-subject-keyword-token-trap`):** §5 below.
- **§1.5 PREFLIGHT (`preflight-stop-means-stop`):** the coder emits the single PREFLIGHT line only after ALL in-scope edits + the §6 gate + the §1.2 battery PASS; if anything fails, report what went wrong INSTEAD of a partial IMPL-REPORT. A parent stop/halt message halts all work immediately.

---

## 2. THE STATIC-MATRIX RESOLUTION (the settled design C2 sequences)

Per the blueprint addendum §RESOLUTION + §2: the post-C2 wired-set source is the **`tests`-job matrix `include` array itself**, parsed from the yml. The `include` is a FROZEN OUTPUT of `ci-shard-plan.py --emit-matrix` (generated ONCE at maintenance time against the PRE-C2 yml that still has the `run: bash` lines), pasted verbatim into the yml. The wired set becomes `union(all include[].scripts)`. Both readers (the shard module + Check 42) re-anchor their parse to the `include[].scripts` token-strings. The `include` IS the partition AND the membership list simultaneously, so coverage is correct-by-construction with NO CI-time `--emit-matrix` call.

The static `include` is "frozen generated output" — the same pattern as the `_toc.md` generated indices — NOT a hand-maintained shard map (invariant 5). `--assert-coverage` (run in the aggregator + mirrored by Check 60) re-proves `union(shards) == disk_KEEP_set` at run time, catching a stale/hand-edited `include`.

---

## 3. DEPENDENCY RATIONALE — why C2 lands AFTER C3 (and is non-parallel with it)

**C3 BEFORE C2 (hard).** C2 consumes `scripts/lib/ci-shard-plan.py` (created in C3) two ways: (a) the maintenance-time `--emit-matrix` that GENERATES the frozen `include` C2 pastes into the yml; (b) the run-time `--assert-coverage` the `tests-result` aggregator runs + Check 60 mirrors. The module exists at HEAD `38e0ae4` (C3 landed — §EE-9), so this dependency is SATISFIED for C2 now. C2 could NOT have landed before C3 (the module would not exist) — confirming the C1 → C3 → C2 order.

**C2 re-anchors C3-committed parsers (forward edit, not a C3 rewrite).** The two parsers (`parse_wired_tests`, Check 42 `wired_pattern`) currently anchor on `run: bash` (committed in C3 at `38e0ae4`). C2 forward-edits them to the `include[].scripts` anchor. This is a forward edit landing IN C2 — the C3 commit (`38e0ae4`) is NOT rewritten or rebased (blueprint §RESOLUTION final sentence).

**Why the re-point MUST be atomic with the yml restructure (single commit).** If C2 deleted the `run: bash` lines but did NOT re-point the parsers (the stale §C2's gap), the wired set would parse EMPTY → empty partition → CI runs ZERO tests (silent effectiveness collapse) AND Check 42 would FAIL naming all 71 KEEP scripts as unwired (blueprint §1.3, §EE-blueprint EE-E/EE-F). Conversely, re-pointing the parsers without the yml restructure would FAIL because there is no `include` array yet. The yml restructure and the two parser re-points are mutually dependent → they MUST be ONE commit. C2 is therefore an indivisible six-file change.

**Every intermediate state remains working / CI-green.** Before C2: HEAD `38e0ae4` is green (Check 42 / 58 / 59 / 60 all pass over the `run: bash` source — §EE-1, §EE-6). After C2: the `tests` job is sharded, wired set parsed from `include`, all guards green over the new source. There is no half-migrated committed state (the change is atomic).

**Isolated-coder note (worktree).** C2's coder runs ISOLATED. C2 adds NO new files (§EE-9) — the merge-back is the **modified-files-patch** case: a patch touching six EXISTING tracked files. No new-file staging step is needed in merge-back. (C2 is also file-disjoint from C1/C4, but its hard ordering dependency on C3 forbids parallelism with C3 — stale plan §4.)

---

## 4. EXACT C2 FILE-BY-FILE CHANGE LIST (functions / sections — NOT line numbers; numbers drift)

All six edits are ONE commit. Edits 2/3 are forward edits into C2 (C3's commit is not rewritten). The maintenance-time generation step (4.0) precedes the yml paste.

### 4.0 PRE-EDIT generation step (maintenance-time, run against the PRE-C2 yml)

BEFORE deleting the `run: bash` lines, the coder runs `python3 scripts/lib/ci-shard-plan.py --emit-matrix` against the CURRENT (pre-C2) yml — which still has the 71 `run: bash` lines (§EE-2) — to GENERATE the static `include` array (4 shards, 71 tests, JSON). This is the partition C2 freezes into the yml (4.1). The generator output is the SOURCE of the `include` block; the coder pastes it verbatim (expanded from compact JSON into yml `include` list syntax). Capture the generator output in the IMPL-REPORT for audit. NOTE: run this step FIRST, before any of the 4.1–4.5 edits, because once the `run: bash` lines are gone the generator (still on the `run: bash` anchor at this instant) would emit empty — the re-point (4.2) happens AFTER the paste.

> Ordering inside C2's working tree (single commit, but ordered edits to avoid a self-inflicted empty emit):
> (i) 4.0 generate `include` from the pre-edit yml → (ii) 4.1 restructure the yml (delete `run: bash`, paste `include`, remove `plan`, add run-loop + aggregator) → (iii) 4.2 re-point `parse_wired_tests` to `include[].scripts` → (iv) 4.3 re-point Check 42/60 docstrings + `wired_pattern` → (v) 4.4/4.5 update the two encoding-surface tests → (vi) 4.6 regen manifest → (vii) §6 PREFLIGHT gate over the whole tree.

### 4.1 `.github/workflows/validate-pack.yml` (the restructure)

- **`validate` job — UNCHANGED.** It runs ALL checks (general + deep, no flag, no selector); not sharded. Do not touch it. Check 58 asserts this stays flag-free.
- **`tests` job → STATIC matrix.** Add `strategy:` with `fail-fast: false` (HARD requirement) and `matrix: { include: [ {shard:1, scripts:"…"}, {shard:2,…}, {shard:3,…}, {shard:4,…} ] }`, the four entries = the 4.0 generator output pasted verbatim (each `scripts:` value the space-separated test list for that shard). DELETE the ~71 individual `- name: … / if: always() / run: bash scripts/…sh` steps (the per-script test runners at the tests-job body — EXCLUDING the fixture build/restore/verify steps, which become the conditional fixture step below). The 71 deleted lines = §EE-2.
- **Replace the per-script steps with TWO steps (blueprint §2.2 shape):**
  - the conditional fixture step: `if: always()` → `if python3 scripts/lib/ci-shard-plan.py --shard ${{ matrix.shard }} --needs-fixtures; then bash test-fixtures/build.sh --all --clean; git checkout HEAD -- test-fixtures/manifest.txt; bash test-fixtures/build.sh --verify; fi` — the BD-118 manifest-restore + BD-163 build/restore/verify ORDER preserved, run ONLY in the fixture-owning shard.
  - the run-loop step: `if: always()` → `rc=0; for t in ${{ matrix.scripts }}; do echo "::group::$t"; bash "$t" || rc=1; echo "::endgroup::"; done; exit $rc` (preserves "every script in a shard runs; shard exits non-zero on any failure").
  - keep the `tests` job's `checkout@v6 (fetch-depth: 0)` + `setup-python@v6 (3.12)` + `pip install pyyaml` steps.
- **REMOVE the `plan` job — DO NOT ADD ONE.** The static `include` replaces it. There must be NO `python3 scripts/lib/ci-shard-plan.py --emit-matrix` invocation in any CI job after C2 (it is maintenance-time only now).
- **`tests-result` job:** `needs: [tests]` (NOT `[plan, tests]` — no `plan` job exists), `if: always()`; checkout + setup-python; step 1 asserts `test "${{ needs.tests.result }}" = "success"`; step 2 `python3 scripts/lib/ci-shard-plan.py --assert-coverage`. (If `tests-result` does not yet exist in the committed yml, add it; if a prior commit added it with `needs: [plan, tests]`, fix the `needs` — verify at coder time which is present.)
- **`on: push` UNCHANGED; NO path/branch filter added** (research §2.2 rule 7).

### 4.2 `scripts/lib/ci-shard-plan.py` (forward edit — re-anchor the parser; demote the generator)

- **`parse_wired_tests(workflow_text)`** — re-anchor: instead of `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` over the whole yml, extract every `scripts/…\.sh` token that appears inside the `matrix.include[].scripts` mapping values. Robust approach: match `scripts:` value lines under the `include:` block and pull `scripts/[^\s"]+\.sh` tokens from them (or scan the `include` region for those tokens). Return the same sorted unique list shape. KEEP the docstring's "SAME wired-set parse Check 42 uses" promise true — the new anchor must be byte-identical to Check 42's new extraction (4.3) so Group 6 holds.
- **Demote `--emit-matrix` to a maintenance-time generator** in the docstrings: update the module header "Realized consumers" block — DROP the `plan` job line (`# - BD-219 C2 … plan job → --emit-matrix`) and the `--emit-matrix` mode's "for the `plan` job's `$GITHUB_OUTPUT`" wording; REPLACE with "maintenance-time `include`-block generator (re-run to refresh the frozen yml matrix; NOT a CI runtime call)". Keep the `--assert-coverage` / `--needs-fixtures` / `--print-partition` consumer lines.
- **UNCHANGED:** `compute_partition`, `cmd_assert_coverage`, `cmd_shard_needs_fixtures`, `cmd_print_partition`, `FIXTURE_COHESION_GROUP` (5 members — §EE-7), weights/allowlist loading, `DEFAULT_SHARDS=4`. The generator logic is unchanged — only its docstring role + the parse anchor change.

### 4.3 `scripts/validate-pack.py` (forward edit — re-anchor Check 42; touch Check 60 docstring)

- **Check 42 `check_ci_workflow_wires_per_check_tests` — re-anchor `wired_pattern`** from `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` to the SAME `include[].scripts` extraction the new `parse_wired_tests` uses (byte-identical, preserving Group 6 equivalence). The invariant `disk_KEEP_set == wired_set` is UNCHANGED; only `wired_set`'s derivation moves. Update the docstring lines that describe `wired_set` as "the `run: bash scripts/…sh` test runners in the yml" → "the `scripts/…sh` tokens in the `tests`-job `matrix.include[].scripts` strings". Update the failure-message remediation text (which today tells the maintainer to add a `run: bash <path>` step) → tell the maintainer to **re-run `ci-shard-plan.py --emit-matrix` and refresh the frozen `include` block** (a `run: bash` step is no longer the wiring mechanism). PRESERVE the PASS-message strings verbatim (`disk_KEEP_set == wired_set`, `CI workflow wiring is complete`, `N test script(s) on disk`, `N allowlisted (intentionally-OUT)`, `N KEEP`, `N wired in workflow`) — encoding-surface tests assert them (§EE-8).
- **Check 60 `check_ci_shard_coverage` — code UNCHANGED** (it shells `ci-shard-plan.py --assert-coverage`, which rides the re-pointed `parse_wired_tests`). Update only its docstring IF it names the `run: bash` source. Its "authoritative run-time assertion lives in the C2 `tests-result` aggregation JOB" reference is now accurate (verify wording).
- **Checks 58 / 59 — UNCHANGED.** Check 58 reads the `validate` job's invocations (C2 does not change them); Check 59 reads `CHECK_REGISTRY` (C1 work, orthogonal).

### 4.4 `scripts/tests/test-ci-shard-plan.sh` (encoding surface — enumerate-encoding-surfaces)

- **Group 6 (parse-equivalence)** hard-codes Check 42's OLD regex `r"run:\s+bash\s+(scripts/[^\s]+\.sh)"` to assert `csp.parse_wired_tests(text) == c42-regex(text)`. Update BOTH the in-test reference regex/extraction AND its comment to the new `include[].scripts` anchor (matching the re-pointed Check 42). The assertion's MEANING (the two parsers agree) is preserved.
- **Group 1 (`--emit-matrix`)** asserts 4 shards, no empty `scripts`, union == wired KEEP. It re-computes the wired KEEP via `csp._load_all(4)` (which calls the re-pointed `parse_wired_tests`). It KEEPS passing once the parser is re-pointed AND it runs against the POST-C2 yml (the one with the `include` array). The coder MUST run Group 1 against the post-restructure yml to prove non-empty (it would FAIL against a half-migrated yml — but C2 is atomic, so the committed yml is fully migrated).
- **Group 2 (`--assert-coverage` green)** rides the re-pointed parser; keeps passing post-C2.
- **Groups 0/3/4/5 — UNAFFECTED** (module-import, in-process broken-partition monkeypatch, `--needs-fixtures`, graceful degradation). Do not edit.

### 4.5 `scripts/tests/test-validate-pack-check-42.sh` (encoding surface — the synthetic-yml rewrite)

- **Group 2 synthetic `run_check()` helper** builds synthetic ymls by emitting `run: bash <path>` step lines (the `for p in wired: … run: bash {p}` loop). Under the re-pointed Check 42 these synthetic ymls would have an EMPTY wired set → every FAIL-path case (T2 unwired tests/ KEEP, T3 unwired scripts-root KEEP, T4 multi-unwired, T6 allowlist staleness) and PASS-path case (T1 all-wired, T5 allowlisted-STRIP-unwired) would mis-fire. The coder MUST rewrite the synthetic-yml construction to emit a `strategy.matrix.include` block whose `scripts:` strings carry the `wired` paths instead of `run: bash` steps. The T1–T8 assertions + the count strings (`3 test script(s) on disk`, `3 wired in workflow`, `1 allowlisted (intentionally-OUT)`, `Allowlist staleness`, `exists on disk but has NO`, the lenient `skipping (lenient)` skips) are PRESERVED — only the yml-fixture SHAPE changes. NOTE: T2's `exists on disk but has NO` message currently embeds the old `run: bash {path}` remediation; if the coder changed that remediation text in 4.3, update T2's asserted substring in lock-step (verify the exact post-4.3 message).
- **Group 1 (real-state PASS) and Group 3 (`--only-check 42` e2e)** read the REAL yml + invoke the real Check 42 → ride the re-point automatically. Group 3 already uses `--only-check 42` (§EE-8); its asserted strings are preserved. No edit unless a string changed in 4.3.
- **Group 0 (symbol registration)** — unaffected.

### 4.6 `test-fixtures/manifest.txt` (regen — §1.1)

C2 edits `scripts/` → v11-surface → run `bash test-fixtures/build.sh --all --clean`, then `git status --short test-fixtures/manifest.txt`. Stage iff `M`. A re-anchor of regex parsers + docstrings does not change fixture SHAs, so the diff is very likely EMPTY — but the coder MUST run+check, never assume. If empty, note "manifest diff empty — not staged" in the IMPL-REPORT. If non-empty, stage it (it rides cleanly under `pack-only` — manifest.txt is pack-side).

---

## 5. SCOPE KEYWORD — `pack-only` (keyword-token-trap discipline)

C2's six edited paths are ALL pack-side (`.github/`, `scripts/`, `test-fixtures/`) → exactly `pack-only`. Check 36 substring-scans the WHOLE commit subject for any scope-keyword token; a denying token wins; only the claimed keyword may appear.

- The subject carries `pack-only` and MUST NOT contain the literal substrings `project-only` or `pack-chat-only` ANYWHERE — including in prose (e.g., do NOT write "this is not a project-only change"; the token `project-only` would trip Check 36).
- Describe the change with non-keyword vocabulary ("workflow restructure", "matrix shard", "wired-set source").
- Check 36 validates subject-vs-diff and can only surface POST-commit → re-run `python3 scripts/validate-pack.py` AFTER the commit exists to confirm Check 36 passes on the `pack-only` claim.
- Commit-message form (current major = v11, §EE confirms README): `feat: v11 — BD-219 C2: <desc> (pack-only)`.

---

## 6. WIRED-SET-NON-EMPTY PREFLIGHT GATE (ordered; the gap's direct proof + empty-set tripwire)

Per blueprint §5: the coder MUST pass these in order, against the POST-restructure tree, BEFORE writing the IMPL-REPORT. Any failure → report what failed INSTEAD of a partial report (preflight-stop-means-stop). This gate PROVES the static matrix yields a NON-EMPTY 71-test wired set equal to `disk_KEEP_set`.

1. **Wired-set non-empty + complete:** `python3 scripts/lib/ci-shard-plan.py --print-partition` → assert the header reads `wired: 71 … KEEP: 71 … shards: 4` (NOT 0), and every shard line shows ≥1 test (no empty shard).
2. **emit-matrix ↔ frozen include identity (no stale paste):** `python3 scripts/lib/ci-shard-plan.py --emit-matrix` against the POST-C2 yml → assert `union == 71 KEEP` and (modulo deterministic ordering) it reproduces the FROZEN `include` the yml carries. If the re-point is correct, the generator reading the `include` reproduces the `include`.
3. **`--assert-coverage` green:** `python3 scripts/lib/ci-shard-plan.py --assert-coverage` exits 0 with `71 wired KEEP test(s) … union == wired_KEEP_set … pairwise-disjoint … cohesion group co-located`.
4. **Check 42 green over the new source:** `python3 scripts/validate-pack.py --only-check 42` → prints `… 72 test script(s) on disk; 1 allowlisted …; 71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set …` (NOT a FAIL naming 71 unwired scripts).
5. **Parse-equivalence holds:** `bash scripts/tests/test-ci-shard-plan.sh` → Group 6 passes (`ci-shard-plan wired-set parse == Check 42 wired-set parse`); Groups 1/2 green.
6. **Negative proof (the gap cannot silently recur):** in a SCRATCH copy of the yml, delete one shard's `scripts:` entry (or remove one test token) → assert (a) `--print-partition` shows < 71, (b) `--assert-coverage` FAILs naming the missing test, (c) `validate-pack --only-check 42` FAILs naming it unwired. Revert (work on a copy; never mutate the committed yml destructively).
7. **Empty-set tripwire (the precise gap):** assert `--emit-matrix` over the POST-C2 yml does NOT emit any shard with an empty `scripts` string AND the union is exactly 71 — the literal condition the stale dynamic design would have produced ZERO of (empty partition → zero tests). This is the one-line tripwire that the wired set did not collapse to empty.
8. **Full battery (§1.2):** general + deep validate-pack + EVERY wired test in the new `include` union (71), quoting each exit; Check 58/59/60 green; Check 36 green post-commit on `pack-only`.

---

## 7. SIX-INVARIANT CONFIRMATION (all hold under this C2 — per blueprint §3)

| # | Invariant | Holds under this C2? | Mechanism in the plan |
|---|---|---|---|
| 1 | Effectiveness unchanged — every wired KEEP test (71) runs exactly once per CI run, sharded, none dropped | **YES** | Frozen `include` enumerates all 71 KEEP (4.0/4.1); run-loop `for t in ${{ matrix.scripts }}` runs each once (4.1); `--assert-coverage` FAILs if any KEEP test is in no/two shards. §6 gate steps 1/3/7 prove 71 non-empty. |
| 2 | Coverage correct-by-construction; `--assert-coverage` meaningful + passing | **YES** | The `include` IS the partition AND `wired_set = union(include[].scripts)` — the SAME object; aggregator + Check 60 re-prove at run time (4.1/4.3). Now catches a stale hand-edited `include`. §6 step 2 (emit↔include identity). |
| 3 | Wiring-drift guarded — Check 42 catches a disk test not in CI; allowlist sizing preserved (measure-then-bound) | **YES** | Check 42 keeps `disk_KEEP_set == wired_set`; only `wired_set`'s anchor moves to `include[].scripts` (4.3). Allowlist UNCHANGED (1 STRIP — §EE-4); no widening. §6 step 4 + step 6 negative proof. |
| 4 | Balance preserved — weights drive LPT; fixture cohesion co-located (BD-163/BD-118 order) | **YES** | `include` GENERATED by `--emit-matrix` (unchanged `compute_partition` + LPT over `ci-shard-weights.tsv`, pins `FIXTURE_COHESION_GROUP` — 4.0/4.2). Fixture-owning shard runs `--needs-fixtures` → build/restore/verify in BD-163 order (4.1). `--assert-coverage` re-asserts co-location. |
| 5 | No hand-maintained shard map; single source of the partition | **YES** | Partition still GENERATED by `ci-shard-plan.py` (4.0); the yml `include` is its FROZEN OUTPUT, refreshed by re-running `--emit-matrix` (the only hand act is pasting generator output — a documented mechanical step, with `--assert-coverage` + Check 42 as the safety net). Candidate A (new file) rejected by the architect (drift surface). |
| 6 | Checks 58/59/60 + `--only-check` registry invariant hold | **YES** | Check 58 untouched (reads `validate` job — C2 leaves it flag-free, 4.1); Check 59 untouched (`CHECK_REGISTRY` is C1 work); Check 60 rides the re-pointed `parse_wired_tests` (4.3); `test-validate-pack-checks-58-59-60.sh` is itself one of the 71 KEEP → appears in the frozen `include`. §6 step 8. |

All six SUPPORTED. No invariant requires a design change beyond the addendum's settled resolution.

---

## 8. REVIEW / FIX CYCLE (bounded — per `bounded-review-fix-cycle`)

C2 gets its OWN bounded cycle: fresh coder → pack-reviewer (background) → Pack-Chat triage (fix-or-skip per finding, default FIX-ALL, surfaced to the user) → fix-coder (fresh, if needed) → final reviewer pass. Bound: max 2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder spawns. If dirty after the final pass, STOP and spawn `pack-architect` to diagnose (no fix-coder pass 3). There is ALSO an end-of-BD reviewer pass over the whole BD-219 batch (C1+C2+C3+C4) after the final commit. Each coder/fix-coder is a FRESH instance (per-commit-fresh-coder). The reviewer prompt references the ARCHITECTURE addendum + this plan ONLY — never a prior PACK-REVIEW report.

The reviewer's independent pass MUST re-run the §6 gate (all 8 steps) + the §1.2 full battery — a green `validate-pack` alone is not a clean verdict (verify-full-ci-suite). High-risk encoding surfaces for the reviewer to re-verify: the two parser anchors are byte-identical (Group 6), and the `test-validate-pack-check-42.sh` synthetic-yml rewrite exercises all FAIL paths under the new anchor (T2/T3/T4/T6).

---

## Auto-regen idea assessment (Task B)

The user proposed: instead of a manual matrix-regen when a test is added, a **git pre-commit hook** detects a new test in the test directory and regenerates the static matrix automatically — so neither Pack Chat nor a coder does anything manual; the static matrix stays the committed SSOT and the test DIRECTORY is the inventory. Assessment + recommendation below. (This is an ASSESS-and-recommend task — I do NOT design it in detail.)

### B.1 Reliability finding — a git pre-commit hook CANNOT be the enforcement (CONFIRMED)

The user's reliability concern is CORRECT and is the load-bearing fact. A git pre-commit hook lives in `.git/hooks/` (per-clone, LOCAL state): it is **not version-controlled** (git never tracks `.git/`), **not auto-installed** on clone (a fresh clone has no hooks), and **bypassable** (`git commit --no-verify` skips it; many GUIs/automations skip hooks entirely). Therefore a hook can NEVER be the anti-drift ENFORCEMENT — a contributor who doesn't install it, or bypasses it, or commits via a path that skips hooks, would silently let the static matrix drift out of sync with the test directory.

**The reliable anti-drift gate is — and must remain — the CI guard: Check 42 (`disk_KEEP_set == wired_set`) + Check 60 (`--assert-coverage`) + the aggregator's run-time `--assert-coverage`.** These run on every push in CI (server-side, unbypassable by a local actor). If a new test is added but the static `include` is not refreshed, Check 42 FAILs naming the unwired test and CI goes RED — exactly the drift the hook would aim to prevent, caught reliably. This is the measure-then-bound CI guard the C2 plan ships; it does NOT depend on any hook.

**How a hook would PAIR with the CI guard (convenience layer, not replacement).** The hook (or any auto-regen mechanism) is purely a **convenience accelerator**: it would refresh the frozen `include` locally so the contributor doesn't push a CI-RED commit and wait for the round-trip. The enforcement is still Check 42 in CI. So the correct framing is: **CI guard = the gate (mandatory, reliable); auto-regen = optional convenience that helps a contributor go green BEFORE pushing.** The C2 static-matrix + Check 42 baseline works WITHOUT any auto-regen — auto-regen is purely additive.

### B.2 Mechanism comparison (feasibility on THIS repo; ship/install; sharp edges; pack-commits-via-Pack-Chat; boundary)

| # | Mechanism | Feasibility on this repo | Install / ship mechanism | Mutate-tree-mid-commit / re-stage sharp edges | Pack-commits-via-Pack-Chat reality | Boundary / dependency-direction |
|---|---|---|---|---|---|---|
| **(i)** | **Shipped + installed pre-commit hook** (regen + re-stage mid-commit) | Feasible but heavy. Needs a tracked hook script + an installer (the pack has no hook-install convention today — would be net-new infra). | Ship the hook under e.g. `scripts/hooks/`; install via a `pack`-verb or a documented `git config core.hooksPath scripts/hooks` step; both are NEW pack-dev tooling. | SHARP. A pre-commit hook that REGENERATES the yml and `git add`s it mid-commit mutates the working tree + index during the commit — fragile (interacts with partial staging, `--no-verify`, re-entrancy), and **collides head-on with `agents-never-commit` / `never-pre-stage-until-commit-approval`**: a hook auto-`git add`ing during a commit is exactly the un-approved staging the pack forbids. | DIRECT CONFLICT. Pack commits go through Pack Chat with explicit user approval; pack AGENTS never stage/commit. An auto-staging hook inverts that model (it stages without the per-action approval gate). For pack-DEV use this is a governance regression. | pack-only pack-dev tooling (the hook governs pack CI). It does NOT ship to clients (BD-219 is pack-only). If it were ever proposed for `project-template/`, P-missed-7 + dependency-direction apply — but that is out of scope here. |
| **(ii)** | **`pack`-style helper / make target the dev runs when CI complains** (`pack regen-shards`-style: re-run `--emit-matrix` + rewrite the `include` block) | Most feasible + lowest-risk. The generator (`ci-shard-plan.py --emit-matrix`) already exists; this is a thin wrapper that writes its output into the yml `include` block. | Add a `pack`-verb (`pack help` registry) or a documented one-liner in the maintenance doc. Small, explicit, opt-in. | MINIMAL. The dev runs it deliberately, reviews the diff, and stages via the normal Pack-Chat-approval path — no mid-commit mutation, no auto-stage. The regen and the commit are SEPARATE deliberate acts. | COMPATIBLE. The dev (or a scoped coder) runs the helper; Pack Chat reviews + commits with user approval — same model as every other pack edit. No inversion. | pack-only pack-dev tooling; lives pack-side (`scripts/`); not a runtime dependency of a pack OPERATION (CI + maintainer only) → dependency-direction satisfied; not client-shipped. |
| **(iii)** | **CI-side auto-regen** (a CI job regenerates the `include` and commits/pushes it back) | Feasible but worst fit. Requires CI write-back (a bot push or PR), credentials, and loop-guards. | A workflow job with write permissions + a token. Net-new CI write surface. | SHARP. CI committing back to the branch (a) needs elevated creds (the user's PAT cannot push arbitrary bot commits cleanly — see the no-delete/archive-only credential note), (b) can loop (push triggers CI triggers push), (c) violates "agents/automation never commit without approval". And the static matrix would no longer be a stable committed SSOT — CI would mutate it. | DIRECT CONFLICT — CI auto-committing bypasses the user-approval commit gate entirely. | pack-only; but the write-back inverts the "static `include` is the committed SSOT" property the C2 design rests on. Rejected on fit. |

**Comparison verdict:** (ii) — a `pack`-verb / helper the dev runs when CI complains — is the clear best fit. It is thin, opt-in, has no mid-commit mutation, and PRESERVES the pack-commits-via-Pack-Chat-with-approval model. (i) and (iii) both collide with `agents-never-commit` + `never-pre-stage-until-commit-approval` (auto-staging / auto-committing without the per-action approval gate) and add net-new install/write infra. The auto-regen the user described as "neither Pack Chat nor a coder does anything manual" is the property that conflicts with the pack's deliberate-approval commit model — full automation is exactly what the governance forbids; (ii) keeps the human/approval in the loop while still removing the tedious manual `include`-block hand-edit.

### B.3 Scoping verdict + recommendation

- **Is this a NEW mechanism needing an ARCHITECT pass?** For mechanism (i) or (iii) — **YES, architect-level.** Shipping/installing a hook or adding CI write-back is net-new pack-dev infra that (a) interacts with the `agents-never-commit` / pre-staging rules, (b) needs an install/ship contract the pack does not have today, and (c) touches the commit-governance model. That is precisely "work that touches rules / operating model" → the `pack-architect`-first protocol applies; the planner should NOT spec it. For mechanism (ii) — a thin maintainer helper that just writes `--emit-matrix` output into the `include` block — it is closer to planner-speccable, BUT it still introduces a new `pack`-verb / convention, so I recommend a LIGHT architect touch (or at least explicit user direction) before specing, not a unilateral planner design.
- **Does it belong IN BD-219 (a new commit C5) or as a SEPARATE follow-up BD?** **A SEPARATE follow-up BD — NOT a C5 in BD-219.** Rationale: (1) the C2 static-matrix + Check 42 baseline works WITHOUT any auto-regen — it is purely ADDITIVE convenience, so deferring it does NOT block BD-219's effectiveness-preserving acceptance criteria; (2) it is a distinct concern (developer-convenience tooling + commit-governance interaction) from BD-219's CI-runtime optimization (LOGICAL-FIT test: it is thematically related but not the same contract); (3) the better mechanisms (i)/(iii) need an architect pass, which would expand BD-219's pipeline. This is a SIZE + LOGICAL-FIT defer that survives the `deferral-is-scope-creep` bar — but per `no-deferral-without-user-direction` (v11.0 is unlaunched), the defer-to-a-new-BD REQUIRES explicit user authorization; I SURFACE it as a recommendation, not a unilateral defer.
- **Recommendation (surfaced for user decision):** ship C2 as planned (static matrix + Check 42 enforcement) WITHOUT auto-regen. Open a SEPARATE BD for the auto-regen convenience, scoped as mechanism (ii) (a maintainer-run `pack regen-shards`-style helper), with an architect pass to confirm the verb contract + that it does not auto-stage/auto-commit. Explicitly REJECT mechanisms (i) and (iii) in that BD's framing (they collide with the pack's never-auto-commit governance). If the user wants it inside BD-219 instead, that is a re-scope the user authorizes — flag the blast radius: a new commit C5 + a new `pack` verb + an architect pass inserted before it.

---

## EMPIRICAL-EVIDENCE BLOCKS

All measurements at HEAD `38e0ae4f6fc9ee5f872546e1622f990794b384dc`, branch `v11-dev`, 2026-06-15.

### §EE-1 — HEAD contains C1 + C3; C2 not yet committed
- **Claim:** the re-plan bases on a tree where C1 (`--only-check`/registry) + C3 (Check 42 set-equality + shard module + Checks 58/59/60) are landed and C2 is not.
- **Command + output:** `git rev-parse HEAD` → `38e0ae4f6fc9ee5f872546e1622f990794b384dc`; `git log --oneline -3` → `38e0ae4 feat: v11 — BD-219 C3: CI test-wiring guard (Check 42 set-equality) + shard-plan module + Checks 58/59/60 (pack-only)` / `3afccec feat: v11 — BD-219 C1: validate-pack --only-check + CHECK_REGISTRY refactor; strip stale Check-54 comments (pack-only)` / `f140c48 docs: v11 — BD-219 research + design + plan; open BD-220 …`.
- **Interpretation:** C1+C3 landed; the next BD-219 commit is C2. The two parsers + Check 42/60 are at their C3-committed state (anchored on `run: bash`).
- **Conclusion: SUPPORTED.**

### §EE-2 — the current `tests` job has 71 `run: bash scripts/…sh` lines (the source C2 deletes)
- **Claim:** C2's restructure removes the 71 per-script lines both parsers currently read.
- **Command + output:** `grep -cE 'run:\s+bash\s+scripts/' .github/workflows/validate-pack.yml` → `71`.
- **Interpretation:** the §6 gate must prove the post-restructure wired set is 71 (not 0) from the `include` array — the exact collapse the stale §C2 risked.
- **Conclusion: SUPPORTED.**

### §EE-3 — current partition: 4 non-empty shards, 71 wired/KEEP, assert-coverage green
- **Claim:** at HEAD the generator emits a valid 4-shard / 71-test partition (the input C2 freezes).
- **Command + output:** `python3 scripts/lib/ci-shard-plan.py --print-partition | head -2` → `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4` / `── shard 1  (load ~119.5s, 22 tests) [FIXTURE-OWNER] ──`. `python3 scripts/lib/ci-shard-plan.py --assert-coverage` → `ci-shard-plan --assert-coverage OK: 71 wired KEEP test(s) across 4 shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.` `--emit-matrix | json` → `shards: 4`, `union: 71`.
- **Interpretation:** the 4.0 generation step produces the 71-test/4-shard `include`; §6 steps 1/2/3 reproduce it post-C2.
- **Conclusion: SUPPORTED.**

### §EE-4 — measure-then-bound: 72 disk / 1 STRIP / 71 KEEP == 71 wired (allowlist unchanged)
- **Claim:** the post-C2 wired set must equal the 71-element KEEP set; allowlist stays at 1; no widening.
- **Command + output:** `ls scripts/test*.sh scripts/tests/*.sh | wc -l` → `72`; `grep -vE '^\s*#|^\s*$' scripts/ci-test-wiring-allowlist.txt` → 1 entry (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh  # live-GH manual-only oracle …`); 72 − 1 = 71 = wired (§EE-2) = KEEP (§EE-3).
- **Interpretation:** the frozen `include` enumerates exactly 71; the allowlist is correctly bounded; C2 does NOT touch it (no contamination tolerance added — measure-then-bound).
- **Conclusion: SUPPORTED.**

### §EE-5 — Check 42 PASS-message strings are preserved by the resolution
- **Claim:** the encoding-surface assertions on Check 42's PASS message survive the re-anchor (only `wired_set`'s derivation moves).
- **Command + output:** `python3 scripts/validate-pack.py --only-check 42 | grep -A1 'Check 42'` → `── Check 42: CI workflow wires every CI-eligible test (BD-184, BD-219) ──` / `OK: Check 42 — 72 test script(s) on disk; 1 allowlisted (intentionally-OUT); 71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set. CI workflow wiring is complete.` These strings are asserted by `test-validate-pack-check-42.sh` Group 1 (`disk_KEEP_set == wired_set`, `CI workflow wiring is complete`) + Group 3.
- **Interpretation:** 4.3 must PRESERVE these strings; only the failure-message remediation text changes (`run: bash` → re-run `--emit-matrix`).
- **Conclusion: SUPPORTED.**

### §EE-6 — Check 60 + the aggregator ride `--assert-coverage` (no code change to Check 60)
- **Claim:** Check 60 is unaffected in code; it shells `--assert-coverage`, which rides the re-pointed `parse_wired_tests`.
- **Command + output:** `scripts/validate-pack.py` Check 60 body (`check_ci_shard_coverage`) runs `subprocess.run([sys.executable, …ci-shard-plan.py, "--assert-coverage"])` (lines 6959–6962). `grep -n 'tests-result' scripts/validate-pack.py` → `6934: lives in the C2 \`tests-result\` aggregation JOB …`, `9830: # authoritative run-time assertion is the C2 tests-result job).`
- **Interpretation:** Check 60 code unchanged; only its docstring is verified (it already names the `tests-result` aggregator correctly).
- **Conclusion: SUPPORTED.**

### §EE-7 — `FIXTURE_COHESION_GROUP` has 5 members (cohesion preserved by unchanged logic)
- **Claim:** the fixture cohesion group is a 5-member set the unchanged `compute_partition` pins into one shard (invariant 4).
- **Command + output:** `scripts/lib/ci-shard-plan.py` lines 94–100 → `FIXTURE_COHESION_GROUP = frozenset({"test-v11-realistic-ot.sh", "test-migrator-skills.sh", "test-persona-contracts.sh", "test-dry-run-migration.sh", "test-add-capability.sh"})`. `--print-partition` shows shard 1 flagged `[FIXTURE-OWNER]`.
- **Interpretation:** C2 does NOT touch this set or the pinning logic; the conditional fixture step (4.1) runs build/restore/verify only in the fixture-owning shard.
- **Conclusion: SUPPORTED.**

### §EE-8 — encoding surfaces: Group 6 hard-codes the old regex; check-42 synthesizes `run: bash`; Group 3 uses `--only-check 42`
- **Claim:** the two encoding-surface tests need the §4.4/§4.5 edits.
- **Command + output:** `test-ci-shard-plan.sh` line 243 → `c42 = set(re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)").findall(text))` (Group 6 hard-codes the OLD anchor); line 73 → `errs.append(f"shard {s.get('shard')} has empty scripts")` (Group 1 empty-shard check). `test-validate-pack-check-42.sh` line 239 → `lines.append(f"        run: bash {p}")` (synthetic-yml emits `run: bash` steps); line 409 → `python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 42` (Group 3 already uses the selector).
- **Interpretation:** Group 6 + the synthetic `run_check` helper MUST be re-anchored to `include[].scripts`; Group 3 + the PASS strings are preserved.
- **Conclusion: SUPPORTED.**

### §EE-9 — C2 adds NO new files (all six edited paths exist) → modified-files-patch merge-back
- **Claim:** the isolated coder's merge-back is the modified-files-patch case (no new-file staging).
- **Command + output:** `ls .github/workflows/validate-pack.yml scripts/lib/ci-shard-plan.py scripts/validate-pack.py scripts/tests/test-ci-shard-plan.sh scripts/tests/test-validate-pack-check-42.sh test-fixtures/manifest.txt` → all six present. Also: `ci-shard-plan.py` header lines 18–25 ("Realized consumers") + line 39 reference the `plan` job + `--emit-matrix` → these docstrings need the §4.2 demotion.
- **Interpretation:** C2 is a six-file MODIFY-only patch; merge-back applies a patch over existing tracked files (no new-file additions). The `plan`-job docstring references confirm the §4.2 demotion is in scope.
- **Conclusion: SUPPORTED.**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §EE-1…§EE-9: every repo/code state-claim (HEAD = C1+C3 / C2 pending; 71 `run: bash` lines; 4 non-empty shards / 71 wired / assert-coverage green; 72 disk / 1 STRIP / 71 KEEP==wired; Check 42 PASS strings; Check 60 rides `--assert-coverage`; 5-member cohesion group; Group 6 old regex + check-42 `run: bash` synthesis + Group 3 `--only-check 42`; six files exist / no new file) carries command + verbatim output + HEAD `38e0ae4` + date 2026-06-15 + interpretation + SUPPORTED. | COMPLIANT |
| **verify-full-ci-suite** | §0 + §1.2 + §6 step 8 + §8 bind C2's coder PREFLIGHT and the reviewer's independent pass to run general + deep validate-pack + EVERY wired test in the POST-C2 `include` union (71), quoting each exit (sampling = the BD-203/BD-214 defect), plus an enumerate-encoding-surfaces sweep covering BOTH encoding-surface tests (Group 6 + the check-42 synthetic-yml rewrite). Not validate-pack alone. | COMPLIANT |
| **regenerate-manifest-v11-surface** | §0 + §1.1 + §4.6: C2 now edits `scripts/` (v11-surface) → manifest-regen flips NO→YES; the plan names `bash test-fixtures/build.sh --all --clean` + `git status --short test-fixtures/manifest.txt` + stage-iff-non-empty, and explicitly SUPERSEDES the stale §C2 "NO regen (yml-only)" note. | COMPLIANT |
| **commit-subject-keyword-token-trap** | §0 + §5: C2 subject carries EXACTLY `pack-only`; MUST NOT contain `project-only` or `pack-chat-only` anywhere (incl. prose); describe with non-keyword vocabulary; re-run validate-pack AFTER the commit (Check 36 is post-commit). All six edited paths are pack-side, justifying the single keyword. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | §EE-4 re-measures at HEAD (72/1/71==71); §2/§7-inv3 keep Check 42's `disk_KEEP_set == wired_set` with the allowlist sized to EXACTLY the 1 STRIP (no widening); the wired set post-C2 = `union(include)` generated FROM the 71 KEEP (correct-by-construction) + run-time `--assert-coverage`. The Task-B assessment explicitly holds that the CI guard (Check 42) is the reliable enforcement and the hook is only convenience. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Task A: planned EXACTLY C2 (the settled static-matrix resolution) — did NOT relitigate shard count/weights/allowlist/`--only-check`/Checks 58/59/aggregator; superseded only §C2. Task B: ASSESSED the auto-regen idea (reliability + 3-mechanism comparison + scoping verdict) and explicitly did NOT design it in detail — flagged (i)/(iii) as needing an architect pass and recommended a SEPARATE BD, surfacing the user-decision rather than absorbing it. | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git branch --show-current`, `git log --oneline`. No add/commit/push/checkout/restore/etc. Single Write = this plan doc at `maintenance-docs/v11-implementation/PLAN-BD-219-C2-REVISED.md`. No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
