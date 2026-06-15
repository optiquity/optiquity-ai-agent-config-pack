<!-- pack-only architecture artifact — ADDENDUM to ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md. Resolves ONE BD-219 C2 design gap (wired-set source after the matrix restructure). Feeds the C2 re-plan → C2 coder. Not a client deliverable. -->
# ARCHITECTURE ADDENDUM — BD-219 C2 wired-set source after the matrix restructure

**Architect:** pack-architect (fresh; targeted gap-resolution pass)
**Date:** 2026-06-15 · **Repo HEAD at design:** `38e0ae4f6fc9ee5f872546e1622f990794b384dc` (branch `v11-dev`; contains BD-219 C1 `3afccec` + C3 `38e0ae4`; C2 NOT yet committed)
**Scope:** resolve EXACTLY the wired-set-source transition gap in C2. The shard architecture (matrix `tests` job + `plan` job + `tests-result` aggregator + `ci-shard-plan.py` + generalized Check 42 + Checks 58/59/60 + `--only-check`) is SETTLED and partially shipped — NOT relitigated here.
**This is an ADDENDUM.** It does NOT rewrite `ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md`. It adds the missing wired-set-source decision that §2.4 (the matrix run-loop) silently omitted, and forward-edits two C3-committed files inside C2 (no rewrite of C1/C3 commits).

---

## READ ATTESTATION (each read IN FULL or at the exact cited region; no skim/crop/derive)

| Doc / artifact | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" (CI-guard, runtime-compounding, empirical-evidence, scope, agents-never-commit, dependency-direction) | YES (full, session context) |
| `backlog/BD-219.md` (lines 1–22, incl. the 2026-06-14/15 notes) | YES (full) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` §2.3/§2.4/§5/§6.1/§6.2/§6.3 | YES (lines 1–475, full; §2.4 matrix run-loop at 147–154) |
| `…/PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §C2 + §C3 | YES (lines 1–875, full; C2 run-loop at 448–454; C2 "Files edited" = yml-only at 436–467) |
| COMMITTED `scripts/lib/ci-shard-plan.py` (esp. `parse_wired_tests`, modes) | YES (lines 1–403, full; `parse_wired_tests` regex at 121) |
| COMMITTED generalized Check 42 + Checks 58/59/60 in `scripts/validate-pack.py` | YES (6701–6977; `wired_pattern` at 6775) |
| `scripts/ci-shard-weights.tsv` | YES (full; 69 non-comment rows) |
| `scripts/ci-test-wiring-allowlist.txt` | YES (full; 1 STRIP entry) |
| `.github/workflows/validate-pack.yml` (jobs + `tests` job + fixture region) | YES (84–365; 71 `run: bash scripts/…sh` lines) |
| COMMITTED `scripts/tests/test-ci-shard-plan.sh` (Groups 0–6) | YES (full; Group 6 parse-equivalence at 230–253) |
| COMMITTED `scripts/tests/test-validate-pack-check-42.sh` | YES (asserts `disk_KEEP_set == wired_set` PASS message) |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` | YES (full) |
| `…/memory/feedback_architect_planner_empirical_evidence.md` | YES (full) |

All load-bearing state-claims were INDEPENDENTLY measured at HEAD `38e0ae4` on 2026-06-15 (Empirical-Evidence Blocks §EE-A…§EE-H). I did not take the gap on the caller's word — I reproduced it (§EE-C/§EE-D).

---

## RESOLUTION (one paragraph)

**Chosen wired-set source post-C2: the `tests`-job matrix `include` array itself, parsed from the yml.** Keep the wired set anchored in `.github/workflows/validate-pack.yml` (single yml SSOT, no new sidecar file), but move the anchor from the disappearing per-step `run: bash scripts/…sh` lines to the **static `matrix.include[].scripts` token strings** that C2 introduces. C2 makes the `tests`-job matrix STATIC and SELF-DESCRIBING: instead of the `plan` job calling `--emit-matrix` (which would parse the very lines C2 deletes — the circularity), C2 commits the partition INTO the yml as a literal `strategy.matrix.include` array (one entry per shard, each carrying its space-separated `scripts:` string), generated ONCE at author/maintenance time by `ci-shard-plan.py --emit-matrix` run against the PRE-C2 yml (which still has the `run: bash` lines), then frozen into the yml. The wired set becomes `union(all matrix.include[].scripts)`. Both readers change their parse anchor accordingly: `ci-shard-plan.py.parse_wired_tests()` parses the `scripts:` token-strings out of the committed `include` array (and `--emit-matrix` is RETIRED as a CI runtime call — it remains a maintenance-time generator), and Check 42's `wired_pattern` parses the same `include[].scripts` strings. **Resulting C2 file scope expands from yml-only to THREE files: (1) `.github/workflows/validate-pack.yml` (static `include` matrix + plan-job removal + run-loop), (2) `scripts/lib/ci-shard-plan.py` (re-point `parse_wired_tests` to the `include` array; demote `--emit-matrix` to a generator), (3) `scripts/validate-pack.py` (re-point Check 42 `wired_pattern` + Check 60 to the new source) — plus their two encoding-surface tests `test-ci-shard-plan.sh` Group 6 and `test-validate-pack-check-42.sh`, and `test-fixtures/manifest.txt`.** These (2)/(3) edits are forward edits landing IN C2; the C1/C3 commits are NOT rewritten.

---

## 1. GAP CONFIRMATION (reproduced independently — §EE evidence)

### 1.1 Both readers parse the SAME disappearing yml lines (the shared anchor)

`scripts/lib/ci-shard-plan.py` `parse_wired_tests()` (line 121) and Check 42 `wired_pattern` (`scripts/validate-pack.py` line 6775) use the **byte-identical** regex over the yml:

```
re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")
```

This identity is not incidental — it is a DESIGN INVARIANT, asserted at run time by the committed `scripts/tests/test-ci-shard-plan.sh` Group 6 (lines 230–253): it reads `.github/workflows/validate-pack.yml`, computes `csp.parse_wired_tests(text)` and the Check-42 regex set, and FAILs unless they are equal ("single source of truth"). So the wired set has, today, exactly ONE source: the per-step `run: bash scripts/…sh` lines in the `tests` job. (§EE-A, §EE-B)

### 1.2 C2 deletes exactly that source

The C2 design (`ARCHITECTURE …` §2.4 lines 147–154; `PLAN …` §C2 lines 448–454) replaces the ~71 individual `run: bash scripts/…sh` steps with ONE matrix run step:

```yaml
- name: run shard ${{ matrix.shard }}
  run: |
    for t in ${{ matrix.scripts }}; do bash "$t" || rc=1; done
    exit $rc
```

After this restructure there are NO `run: bash scripts/…sh` step lines in the `tests` job — the scripts live inside `${{ matrix.scripts }}`. (§EE-D shows the current count = 71; the loop removes all 71.) The plan's C2 "Files edited" lists the yml ONLY (PLAN lines 436–467); it does NOT touch the two parsers. That omission is the gap.

### 1.3 The circularity, reproduced

The original §2.4 design has the `plan` job compute the matrix at CI time via `python3 scripts/lib/ci-shard-plan.py --emit-matrix`. But `--emit-matrix` calls `parse_wired_tests()`, which parses the `run: bash` lines that the matrix `tests` job REPLACED. So the matrix's own script list is derived by parsing the lines the matrix deleted. Reproduced at HEAD: against the CURRENT (pre-C2) yml, `--emit-matrix` emits 4 non-empty shards over 71 wired tests and `--assert-coverage` passes (§EE-C); after the §2.4 restructure those 71 lines are gone, so the SAME `--emit-matrix` would parse an EMPTY set → empty partition → **CI runs ZERO tests** (effectiveness collapse, silent), and Check 42's set-equality `disk_KEEP_set == wired_set` would find `wired_set` empty → it FAILS naming all 72 disk scripts as "unwired" (a loud failure, but the effectiveness collapse it points at is real). Three committed encoding surfaces break: Check 42, Check 60 (mirrors `--assert-coverage`), and `test-ci-shard-plan.sh` Groups 1/2/6. (§EE-E, §EE-F)

**CONCLUSION: GAP CONFIRMED.** The settled architecture has a self-referential wired-set source: the matrix is computed from the lines the matrix removes.

---

## 2. THE RESOLUTION — static, self-describing matrix `include` as the wired-set source

### 2.1 Why STATIC `include` (the design challenge — preliminary-triage-architect-challenge)

I considered three candidate sources and rejected two:

| Candidate source | Verdict | Why |
|---|---|---|
| **(A) Keep the dynamic `plan` job; have `--emit-matrix` read a NEW dedicated wired-list file** | REJECT | Introduces a new hand-maintained file = a NEW drift surface, and re-creates "a list someone must keep in sync" — the exact thing `ci-shard-plan.py` was built to abolish. Violates invariant 5. |
| **(B) `scripts/ci-shard-weights.tsv` as the wired set** | REJECT | The TSV is NOT a complete wired enumeration: 2 wired tests (`test-ci-shard-plan.sh`, `test-validate-pack-checks-58-59-60.sh`) are absent from it by design (they get `DEFAULT_WEIGHT_S`) — §EE-G. It is graceful-degradation balance DATA, never the membership SSOT. Using it would silently drop those 2 tests. Violates invariants 1+2. |
| **(C) The committed static `matrix.include[].scripts` array in the yml** | **CHOOSE** | Keeps the wired set in the yml (single SSOT, no new file). The `include` array IS the partition AND the membership list simultaneously — the partition and the wired set become the SAME object, so coverage is correct-by-construction (invariant 2) with NO run-time `--emit-matrix`. The partition is still GENERATED by `ci-shard-plan.py` (invariant 5) — at maintenance time, not CI time. |

**The key move:** the partition is computed by `ci-shard-plan.py` exactly as today (LPT bin-pack over the weighted KEEP set), but the OUTPUT is FROZEN into the yml as a static `strategy.matrix.include` rather than re-derived every CI run. A static matrix is GA and account-type-agnostic (it is plain workflow syntax — strictly simpler than the dynamic `fromJSON` the original §2.4 proposed; the availability matrix in the main doc §2.1 is a SUPERSET of what this needs). This eliminates the `plan` job entirely (one fewer job, fewer runner-setups — a small bonus consistent with the runtime goal).

### 2.2 What C2 commits into the yml (shape)

```yaml
jobs:
  validate:        # UNCHANGED — runs ALL checks; not sharded.
    ...

  tests:           # MATRIX — STATIC include (generated by ci-shard-plan.py at maintenance time, frozen here)
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false                 # HARD REQUIREMENT (unchanged from §2.4)
      matrix:
        include:
          - shard: 1
            scripts: "scripts/tests/tracker-migrate-reverse-test.sh scripts/tests/test-migrate-v10-to-v11.sh scripts/test-persona-contracts.sh ..."
          - shard: 2
            scripts: "scripts/tests/test-migrate-v10-to-v11-gates.sh ..."
          - shard: 3
            scripts: "..."
          - shard: 4
            scripts: "..."
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: build test fixtures (only if this shard needs them)
        if: always()
        run: |
          if python3 scripts/lib/ci-shard-plan.py --shard ${{ matrix.shard }} --needs-fixtures; then
            bash test-fixtures/build.sh --all --clean
            git checkout HEAD -- test-fixtures/manifest.txt   # BD-118 retro invariant (unchanged)
          fi
      - name: run shard ${{ matrix.shard }}
        if: always()
        run: |
          rc=0
          for t in ${{ matrix.scripts }}; do
            echo "::group::$t"; bash "$t" || rc=1; echo "::endgroup::"
          done
          exit $rc

  tests-result:    # UNCHANGED from §2.4 — the single signal
    needs: [tests]                       # (no more `plan` job to need)
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - name: assert all shards succeeded
        run: test "${{ needs.tests.result }}" = "success"
      - name: assert shard partition covers the wired set exactly
        run: python3 scripts/lib/ci-shard-plan.py --assert-coverage
```

Two deltas from the settled §2.4 shape, both forced by closing the gap (NOT a re-litigation of the settled elements):
- **The `plan` job is removed** and `tests` carries a STATIC `matrix.include` (was: `plan` emits dynamic `fromJSON`). `tests-result.needs` becomes `[tests]` (was `[plan, tests]`).
- `--shard N --needs-fixtures` and `--assert-coverage` are UNCHANGED in role — they read the SAME yml, just via the new `include`-array parse path (§2.3). The aggregator's run-time `--assert-coverage` (the defense-in-depth coverage re-check, §2.4/§6.3) stays and is now even more load-bearing (it is the run-time proof that the frozen `include` still equals the disk KEEP set).

### 2.3 The two parser re-points (the forward edits into C2)

Both parsers change their ANCHOR from the per-step `run: bash` regex to the `include[].scripts` strings, preserving the parse-equivalence invariant (Group 6) by construction (they still share one regex/extraction).

- **`scripts/lib/ci-shard-plan.py` `parse_wired_tests()`** — re-anchor: instead of `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` over the whole yml, extract every `scripts/…\.sh` token from the `matrix.include[].scripts` strings. Concretely: match the `scripts:` value lines under `include:` (or, more robustly, match `scripts/[^\s"]+\.sh` tokens that appear inside a `scripts:` mapping value), union them. `--emit-matrix` is DEMOTED to a maintenance-time generator: it still bin-packs and prints the matrix JSON, used by the maintainer (and the refresh procedure, §6.5 of the main doc) to REGENERATE the static `include` block — it is NO LONGER called at CI runtime. (A docstring note records this; the "Realized consumers" list in the module header drops the `plan` job and adds "maintenance-time `include`-block generator.")
- **`scripts/validate-pack.py` Check 42 `wired_pattern`** — re-anchor to the SAME `include[].scripts` extraction (keep it byte-identical to `parse_wired_tests`'s new anchor so Group 6's equivalence assertion holds). Check 42's invariant `disk_KEEP_set == wired_set` is UNCHANGED; only `wired_set`'s derivation moves.
- **Check 60** is unaffected in code (it shells `--assert-coverage`, which now reads the `include` array via the re-pointed `parse_wired_tests`).

### 2.4 measure-then-bound (the guard's source/scope changed → re-measure — ci-guard-design-measure-then-bound)

Because Check 42's SOURCE moves, I re-ran measure-then-bound at HEAD (§EE-D/§EE-H):
- disk test set = **72** (`scripts/test*.sh` + `scripts/tests/*.sh`).
- allowlist (STRIP) = **1** (`tracker-bd204-lossless-roundtrip-test.sh`, the live-GH manual-only oracle — unchanged; correctly the only STRIP per the C3 re-measure).
- `disk_KEEP_set` = 72 − 1 = **71**.
- wired set (today, from `run: bash`) = **71**; `disk_KEEP_set == wired_set` holds (§EE-D).
- **Post-C2 the wired set = `union(include[].scripts)`, which the C2 coder generates from THIS SAME 71-element KEEP set** via `--emit-matrix`. So the frozen `include` must enumerate exactly 71 tests; the allowlist stays sized to exactly the 1 STRIP entry — NO widening. The guard runs clean against the projected post-C2 tree because the `include` array is generated FROM the KEEP set (correct-by-construction), and Check 42 then verifies `disk_KEEP_set (71) == union(include[].scripts) (71)`.

The allowlist is NOT touched by C2 (it is correct and minimally bounded). No allowlist widening — the resolution adds no contamination tolerance.

### 2.5 runtime cost (ci-check-runtime-compounding — preserved)

The re-pointed Check 42 is the SAME cost class: one regex over the yml text + two dir globs + one small allowlist read — no subprocess-per-script, no real-tree scan; still routes through `run_check` (2.0 s WARN). `parse_wired_tests` is the same (string parse of one file). Removing the `plan` job removes one runner setup per CI run (a tiny net REDUCTION). Check 60 still does exactly ONE bounded subprocess (`--assert-coverage`) once per validate-pack run; the heavy per-script work stays off the validator path. No new compounding introduced.

---

## 3. PER-INVARIANT PRESERVATION (all 6)

| # | Invariant | How this resolution preserves it | Mechanism |
|---|---|---|---|
| 1 | **Effectiveness unchanged — every wired KEEP test runs exactly once per CI run, sharded, none dropped** | The frozen `include` enumerates all 71 KEEP tests; the run-loop `for t in ${{ matrix.scripts }}` runs each once. `--assert-coverage` (aggregator + Check 60) FAILs if any wired KEEP test is in no shard or in two. The empty-set collapse of the §2.4 design is eliminated (the `include` is literal data, not re-derived from deleted lines). | Static `include` + run-loop + run-time `--assert-coverage` |
| 2 | **Coverage correct-by-construction; `--assert-coverage` (`union(shards)==wired_KEEP_set`, pairwise-disjoint) meaningful + passing** | The `include` IS the partition; the wired set IS `union(include[].scripts)`. They are the SAME object, so `union(shards) == wired_KEEP_set` is a tautology at generation time, and `--assert-coverage` re-proves it at run time against `disk_KEEP_set`. Now MORE meaningful than §2.4: it catches a stale frozen `include` (a hand-edit that drops/dups a test), the new principal risk. | `--assert-coverage` reads the `include` array |
| 3 | **Wiring-drift still guarded — Check 42 catches a disk test NOT in CI; allowlist sizing preserved (measure-then-bound)** | Check 42 keeps invariant `disk_KEEP_set == wired_set`; only `wired_set`'s anchor moves to `include[].scripts`. A new disk test absent from the `include` FAILs Check 42 exactly as a new test absent from a `run: bash` step does today. Allowlist unchanged (1 STRIP, §2.4 measure). | Re-pointed `wired_pattern` over the same set-equality |
| 4 | **Balance preserved — `ci-shard-weights.tsv` drives LPT; fixture cohesion group co-located in one shard (BD-163/BD-118 ordering)** | The `include` is GENERATED by `ci-shard-plan.py --emit-matrix`, which still LPT-bin-packs over `ci-shard-weights.tsv` and PINS `FIXTURE_COHESION_GROUP` into one shard (unchanged module logic). The fixture-owning shard runs `--needs-fixtures` → build/restore(BD-118)/verify in BD-163 order (yml §2.2). `--assert-coverage` re-asserts cohesion co-location at run time. | Unchanged `compute_partition` + `--needs-fixtures` |
| 5 | **No hand-maintained shard map; single source of the partition** | The partition is still GENERATED by `ci-shard-plan.py` (the single source). The yml `include` is a FROZEN OUTPUT of that generator, refreshed by re-running `--emit-matrix` (main-doc §6.5 refresh procedure), never hand-bin-packed. The only hand act is pasting the generator's output — a maintenance-doc-documented mechanical step, with `--assert-coverage` + Check 42 as the safety net catching any paste error. (The static `include` is "frozen generated output," the same pattern as `_toc.md` generated indices — not a hand-maintained map.) | `ci-shard-plan.py` remains the partition source |
| 6 | **Checks 58/59/60 + `--only-check` registry invariant hold** | Check 58 (validate job carries no `--only-check`) is untouched — it reads the `validate` job invocations, which C2 does not change. Check 59 (`CHECK_REGISTRY` completeness) is untouched — `--only-check` and the registry are C1 work, orthogonal to the yml restructure. Check 60 (shard-coverage mirror) shells `--assert-coverage`, which keeps working via the re-pointed `parse_wired_tests`. Their test `test-validate-pack-checks-58-59-60.sh` is itself a wired KEEP test → it must appear in the frozen `include` (it is in the 71). | No change to 58/59; 60 rides the re-point |

---

## 4. EXACT C2 FILE-BY-FILE CHANGE LIST (post-resolution)

C2 expands from yml-only (the plan's omission) to the following. All edits are forward edits in C2; C1 (`3afccec`) and C3 (`38e0ae4`) are NOT rewritten.

1. **`.github/workflows/validate-pack.yml`** (the restructure):
   - DELETE the ~71 individual `- name: … / if: always() / run: bash scripts/…sh` steps in the `tests` job (the per-script steps at yml ~119–365, EXCLUDING the fixture build/restore/verify steps).
   - ADD `strategy: { fail-fast: false, matrix: { include: [ {shard:1, scripts:"…"}, …×4 ] } }` to the `tests` job, the `include` array generated by `python3 scripts/lib/ci-shard-plan.py --emit-matrix` run against the PRE-edit yml (which still has the `run: bash` lines) and pasted verbatim.
   - REPLACE the per-script steps with the conditional fixture-build step (`--needs-fixtures` guard → `build.sh --all --clean` + `git checkout HEAD -- test-fixtures/manifest.txt` + `build.sh --verify`, in BD-163 order) and the single run-loop step.
   - REMOVE the `plan` job (not introduced — the static `include` replaces it). DO NOT add a `plan` job.
   - ADD the `tests-result` job (`needs: [tests]`, `if: always()`, assert `needs.tests.result == 'success'` + `--assert-coverage`).
   - `validate` job UNCHANGED. `on: push` UNCHANGED. No path filter.
2. **`scripts/lib/ci-shard-plan.py`** (forward edit into C2): re-anchor `parse_wired_tests()` to extract `scripts/…\.sh` tokens from the `matrix.include[].scripts` strings (was: `run: bash` regex). Demote `--emit-matrix` to a maintenance-time generator in the docstrings + the "Realized consumers" header block (drop the `plan` job; note "maintenance-time `include`-block generator"). `compute_partition`, `--assert-coverage`, `--shard N --needs-fixtures`, `FIXTURE_COHESION_GROUP`, weights/allowlist loading: UNCHANGED.
3. **`scripts/validate-pack.py`** (forward edit into C2): re-anchor Check 42's `wired_pattern` to the SAME `include[].scripts` extraction (byte-identical to the new `parse_wired_tests` anchor, preserving Group 6 equivalence). Update Check 42's docstring lines that describe `wired_set` as "the `run: bash scripts/…sh` test runners in the yml" → "the `scripts/…sh` tokens in the `tests`-job `matrix.include[].scripts` strings". Check 60: code unchanged (rides `--assert-coverage`); update its docstring reference if it names the `run: bash` source. Checks 58/59: UNCHANGED.
4. **`scripts/tests/test-ci-shard-plan.sh`** (encoding surface — enumerate-encoding-surfaces): Group 6 (lines 230–253) hard-codes Check 42's old regex `r"run:\s+bash\s+(scripts/[^\s]+\.sh)"` to assert parse-equivalence. Update BOTH the in-test reference regex AND the comment to the new `include[].scripts` anchor. Groups 1/2 (emit-matrix non-empty, assert-coverage green) keep passing once the parser is re-pointed — but the coder MUST run them against the POST-C2 yml to prove non-empty (they fail against a half-migrated yml). Group 4 (`--needs-fixtures`) and Group 5 (graceful degradation) are unaffected.
5. **`scripts/tests/test-validate-pack-check-42.sh`** (encoding surface): asserts the Check 42 PASS message contains `disk_KEEP_set == wired_set` (line 139) — that string is preserved, so the assertion holds; BUT its FIXTURE setup (it likely synthesizes a yml with `run: bash` steps to exercise FAIL paths) MUST be updated to synthesize the `include`-array shape instead, or the FAIL-path cases (unwired KEEP, allowlist staleness) will no longer fire under the re-pointed parser. The coder MUST open this test and update its yml-fixture construction to the new anchor in lock-step.
6. **`test-fixtures/manifest.txt`**: regenerate (`bash test-fixtures/build.sh --all --clean`); stage iff the diff is non-empty (C2 now touches `scripts/` → v11-surface, so the manifest rule applies — the plan's "C2 is yml-only, no regen" note is SUPERSEDED by this resolution because C2 now edits `scripts/`).

**Scope-keyword consequence:** C2 stays `pack-only` (all six paths are pack-side). The plan's §C2 manifest note ("NO regen unless scripts/ co-changes") flips to "YES regen" because scripts/ DOES co-change now — flag this to the re-planner.

---

## 5. THE C2 CODER'S REQUIRED WIRED-SET-NON-EMPTY VERIFICATION

The original plan's "emit 4 non-empty shards" check would only have surfaced the empty-set collapse at coder time. Make it an explicit, ordered PREFLIGHT gate the C2 coder MUST pass (against the POST-restructure yml, in this order):

1. **Wired-set non-empty + complete (the gap's direct proof):**
   `python3 scripts/lib/ci-shard-plan.py --print-partition` → assert `wired: 71` and `KEEP: 71` (NOT 0); assert every shard line shows ≥1 test and no shard is empty.
2. **emit-matrix vs frozen include identity (no stale paste):** run `--emit-matrix` against the POST-C2 yml; assert it re-emits a partition whose `union == 71 KEEP` and (modulo deterministic ordering) matches the FROZEN `include` the yml carries. (If the parser is re-pointed correctly, the generator reading the `include` reproduces the `include`.)
3. **`--assert-coverage` green:** `python3 scripts/lib/ci-shard-plan.py --assert-coverage` exits 0 with `71 wired KEEP test(s)`, `union == wired_KEEP_set`, pairwise-disjoint, cohesion co-located.
4. **Check 42 green over the new source:** `python3 scripts/validate-pack.py` → Check 42 prints `…71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set…` (NOT a FAIL naming 72 unwired scripts).
5. **Parse-equivalence holds:** `bash scripts/tests/test-ci-shard-plan.sh` Group 6 passes (`ci-shard-plan wired-set parse == Check 42 wired-set parse`).
6. **Negative proof (the gap cannot silently recur):** in a scratch COPY of the yml, delete one shard's `scripts:` entry → assert (a) `--print-partition` shows < 71, (b) `--assert-coverage` FAILs naming the missing test, (c) Check 42 FAILs naming it unwired. Revert.
7. **Full battery (verify-full-ci-suite):** run general + deep `validate-pack` + EVERY wired test in the new `include` union (71), quoting each exit; plus Check 58/59/60 green.
8. **Empty-set tripwire (the precise gap):** assert `--emit-matrix` does NOT emit any shard with an empty `scripts` string and the union is exactly 71 — the literal condition that the §2.4 design would have produced ZERO of.

If ANY of 1–8 fails, the coder reports what failed INSTEAD of a partial IMPL-REPORT (preflight-stop-means-stop).

---

## 6. SURFACED (not absorbed — scope-deliverables-to-the-ask)

- The static-`include` choice ELIMINATES the `plan` job from the settled §2.4 shape. This is forced by closing the gap (the dynamic `plan` job IS the circularity), not a discretionary redesign — but it changes the settled workflow topology, so I SURFACE it for the re-planner/user rather than treat it as silently in-scope. If the user insists on retaining a dynamic `plan` job, the only non-circular alternative is a dedicated wired-list file (candidate A), which I rejected as a drift surface (§2.1); that tradeoff is the user's to override.
- The C2 manifest-regen status flips from NO to YES (C2 now edits `scripts/`). The re-plan must update PLAN §C2's manifest row + the `commit-subject` note accordingly.
- No other settled element (shard count 4, weights, allowlist, `--only-check`, Checks 58/59) is touched.

---

## EMPIRICAL-EVIDENCE BLOCKS

All measurements at HEAD `38e0ae4f6fc9ee5f872546e1622f990794b384dc`, branch `v11-dev`, 2026-06-15.

### §EE-A — both readers use the byte-identical `run: bash` wired-set regex
- **Claim:** `ci-shard-plan.py.parse_wired_tests()` and Check 42 `wired_pattern` share the regex `run:\s+bash\s+(scripts/[^\s]+\.sh)`.
- **Command + output:**
  `grep -n 'pat = re.compile\|wired_pattern = re.compile' scripts/lib/ci-shard-plan.py scripts/validate-pack.py` →
  `scripts/lib/ci-shard-plan.py:121:    pat = re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")`
  `scripts/validate-pack.py:6775:    wired_pattern = re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")`
- **Interpretation:** identical anchor; both parse the per-step `run: bash` lines as the wired-set source.
- **Conclusion: SUPPORTED.**

### §EE-B — the parse-equivalence is a committed run-time invariant (Group 6)
- **Claim:** `test-ci-shard-plan.sh` asserts `parse_wired_tests` == Check 42's regex set.
- **Command + output:** `sed -n '230,253p' scripts/tests/test-ci-shard-plan.sh` → Group 6 reads `.github/workflows/validate-pack.yml`, computes `csp.parse_wired_tests(text)` and `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)").findall(text)`, FAILs unless equal; `t_pass "…single source of truth"`.
- **Interpretation:** the wired-set source is one shared anchor, asserted in CI; any re-point must keep both sides equal.
- **Conclusion: SUPPORTED.**

### §EE-C — against the CURRENT yml, --emit-matrix + --assert-coverage are non-empty/green
- **Claim:** today (pre-C2) the partition is 4 non-empty shards / 71 wired, assert-coverage OK.
- **Command + output:**
  `python3 scripts/lib/ci-shard-plan.py --assert-coverage` → `ci-shard-plan --assert-coverage OK: 71 wired KEEP test(s) across 4 shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.`
  `python3 scripts/lib/ci-shard-plan.py --print-partition | head -2` → `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4` then `── shard 1 (load ~119.5s, 22 tests) [FIXTURE-OWNER] ──`.
- **Interpretation:** the green state depends entirely on the 71 `run: bash` lines being present.
- **Conclusion: SUPPORTED.**

### §EE-D — the current `tests` job has 71 `run: bash scripts/…sh` lines (the source C2 deletes)
- **Claim:** C2's loop removes the 71 lines both parsers read.
- **Command + output:** `grep -cE 'run:\s+bash\s+scripts/' .github/workflows/validate-pack.yml` → `71`. Job structure: `grep -nE '^jobs:|^  [a-z][a-z-]*:' …` → `84:jobs:`, `85:  validate:`, `106:  tests:` (no `plan` job today).
- **Interpretation:** the matrix run-loop (arch §2.4 147–154) replaces all 71 → wired set becomes empty under the current parsers.
- **Conclusion: SUPPORTED.**

### §EE-E — C2 "Files edited" = yml-only (the omission)
- **Claim:** the plan's C2 does not touch the parsers.
- **Command + output:** PLAN §C2 "Files edited" (lines 436–467) lists `.github/workflows/validate-pack.yml` (+ manifest only if scripts/ co-changes). No `ci-shard-plan.py`, no `validate-pack.py` entry. ARCH §8 C2 row (line 380): "`.github/workflows/validate-pack.yml` + manifest".
- **Interpretation:** the wired-set-source re-point is unscoped → the gap.
- **Conclusion: SUPPORTED.**

### §EE-F — three encoding surfaces break post-C2
- **Claim:** Check 42, Check 60, and `test-ci-shard-plan.sh` Groups 1/2/6 break when `wired_set` is parsed from the removed lines.
- **Command + output:** Check 42 set-equality `disk_keep_set - wired_set` (validate-pack.py 6781) with empty `wired_set` → all 71 KEEP named unwired → `fail()`. Check 60 shells `--assert-coverage` (6959–6960) → empty partition → exit 1. `test-ci-shard-plan.sh` Group 1 asserts `shard … has empty scripts` is an error (line 74) and `union == keep` (88); Group 6 asserts parse-equivalence (242) — all over the post-C2 yml.
- **Interpretation:** loud failures (good) but they signal a real ZERO-tests-run effectiveness collapse the design must prevent.
- **Conclusion: SUPPORTED.**

### §EE-G — the weights TSV is NOT a complete wired enumeration (rejects candidate B)
- **Claim:** 2 wired tests are absent from `ci-shard-weights.tsv` (so it cannot be the membership SSOT).
- **Command + output:** `comm -23 <(wired set, 71) <(TSV non-comment rows, 69)` → `scripts/tests/test-ci-shard-plan.sh`, `scripts/tests/test-validate-pack-checks-58-59-60.sh`. TSV non-comment rows = 69 (`grep -vE '^\s*#|^\s*$' … | wc -l`). Reverse diff (TSV − wired) = empty.
- **Interpretation:** the TSV is balance data with graceful-degradation gaps by design; using it as the wired set would silently drop those 2 tests (effectiveness loss).
- **Conclusion: SUPPORTED.**

### §EE-H — measure-then-bound at HEAD: 72 disk / 1 STRIP / 71 KEEP == 71 wired
- **Claim:** the post-C2 wired set must equal the 71-element KEEP set; allowlist stays at 1.
- **Command + output:** disk = `ls scripts/test*.sh scripts/tests/*.sh | wc -l` → `72`. allowlist = `grep -vE '^\s*#|^\s*$' scripts/ci-test-wiring-allowlist.txt` → 1 entry (`tracker-bd204-lossless-roundtrip-test.sh`). 72 − 1 = 71 = wired (§EE-D) = KEEP (§EE-C print-partition). Check 42 today prints `disk_KEEP_set == wired_set` (test-validate-pack-check-42.sh line 139 asserts this string).
- **Interpretation:** the frozen `include` must enumerate exactly 71; allowlist is correctly bounded; no widening.
- **Conclusion: SUPPORTED.**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §EE-A…§EE-H: every state-claim (identical regex @121/@6775; Group-6 invariant; current 71 wired / 4 non-empty shards / assert-coverage OK; 71 `run: bash` lines + no `plan` job; C2 yml-only omission; 3 broken encoding surfaces; TSV 69≠71; 72 disk / 1 STRIP / 71 KEEP==wired) carries command + verbatim output + HEAD `38e0ae4` + date 2026-06-15 + interpretation + SUPPORTED. | COMPLIANT |
| **preliminary-triage-architect-challenge** | Independently REPRODUCED the gap (ran `--emit-matrix`/`--assert-coverage`/`--print-partition` against the current yml — §EE-C — and confirmed the 71-line source the loop deletes — §EE-D), did not take the caller's word. CHALLENGED the simplest fix: rejected candidate A (new file = drift) and candidate B (TSV incomplete — §EE-G) before choosing C; verified all 6 invariants hold under C (§3). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Check 42's SOURCE changes → re-MEASURED at HEAD (§EE-H): 72 disk, 1 STRIP, 71 KEEP == 71 wired. Allowlist kept sized to EXACTLY the 1 genuine STRIP (no widening). Post-C2 `wired_set = union(include)` generated FROM the 71 KEEP set → guard verified to run clean against the projected post-fix tree (correct-by-construction + run-time `--assert-coverage`). | COMPLIANT |
| **ci-check-runtime-compounding** | The re-pointed Check 42 stays one-regex-over-the-yml + two globs + small allowlist read (no subprocess-per-script, no real-tree scan), still routed through `run_check` (2.0 s WARN); Check 60 still ONE bounded `--assert-coverage` subprocess once/run; removing the `plan` job nets one FEWER runner setup. No new compounding (§2.5). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Resolved EXACTLY the wired-set-source gap. Did NOT relitigate shard count, aggregator, guards, `--only-check`, weights, allowlist. SURFACED (not absorbed): `plan`-job removal as a topology delta + the user-override alternative; the C2 manifest-regen flip; both flagged for the re-planner (§6). | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git branch --show-current`, `git log --oneline`. No add/commit/push/checkout/restore/etc. Single Write = this addendum at `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md`. No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
