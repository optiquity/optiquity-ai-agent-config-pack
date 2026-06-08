# DESIGN-REVIEW-BD-204-C46-RUNTIME — non-recurrence gate for the C-4.6 runtime-compounding failure

> **Agent:** pack-reviewer (ADVERSARIAL — re-measured independently; the architect's numbers were
> NOT trusted). **Mode:** READ-ONLY review of an UNCOMMITTED design (§4 of
> `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`). This file is my sole write.
> **HEAD (verified):** `9cc0e887ca775ba2f3a7c81c7b25a8252e27ec7d` (`git rev-parse HEAD`). NOTE: the
> design doc header cites HEAD `feaa45d`, but the working tree is now at `9cc0e88` — HEAD advanced
> (C-4.5 landed in d578626 + 9cc0e88 since the doc was authored). All my §4.6/§4.7-relevant
> measurements were taken at `9cc0e88`, matching the doc's own §4.6/§4.7 Empirical-Evidence Blocks
> (which already cite `9cc0e88`). **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Mission:** prove the C-4.6 runtime failure CANNOT RECUR under this redesign, or REJECT.

---

## State reconciliation (what is landed vs. what this review gates)

Before the proofs, the actual repo state at `9cc0e88` (re-measured — material to the verdict):

- **C-4.5 IS LANDED.** The gz64 verbatim-body-blob carrier (`_tmf_gz64_encode`, `raw_body`, the
  `<!-- pack-entry-body-gz64: ... -->` marker, emit rewrite, size budget, autolink neutralization)
  is in the production libs at HEAD.
  - `CMD`: `grep -rn 'pack-entry-body-gz64\|_tmf_gz64_encode\|raw_body' scripts/lib/tracker-migrate-forward.sh | head`
  - `OUT`: `:443 raw_body_by_pid`, `:574 e["raw_body"]=...`, `:704 _tmf_gz64_encode()`,
    `:846 printf '<!-- pack-entry-body-gz64: %s -->\n'`, `:817 local raw_body="${6:-}"`.
  - `AT`: `9cc0e88`, 2026-06-07. `CONCL`: SUPPORTED — §3 is implemented; commits `d578626`+`9cc0e88`.
- **C-4.6 (the failing check) + §4.7 timing harness are ABSENT.** This is precisely the work the §4
  redesign governs and what this gate covers.
  - `CMD`: `grep -c 'check_migrator_field_faithfulness\|def run_check\|PACK_VALIDATE_DEEP\|RUNTIME-BUDGET\|monotonic' scripts/validate-pack.py`
  - `OUT`: `0`. `AT`: `9cc0e88`, 2026-06-07. `CONCL`: SUPPORTED — the recurrence-prone check is NOT in
    the tree; the failing C-4.6 version was reverted. The design is prospective. **This review therefore
    gates a DESIGN PRESCRIPTION, not landed code** — the test of "structurally impossible" is whether
    the design's prescription, faithfully implemented, makes recurrence impossible AND whether the
    surrounding structural forces (Check 42, the env-gate placement, the batch seam) compel that
    faithful implementation.
- **The parked C-7 oracle was deleted** (`c0151c1`); to be rebuilt per §5.c. Not relevant to runtime.

---

## RE-MEASUREMENTS (independent; the architect's numbers challenged)

| Claim (design) | Design value | My re-measured value | Verdict |
|---|---|---|---|
| Battery validate-pack invocation count | 151 (17 files) | **151 (17 files)** | REPRODUCED |
| Baseline general validate-pack run | 1.37 s | **1.34 s** | REPRODUCED (within noise) |
| BATCH parse all 211 (one python3) | 0.44 s | **0.036 s** (isolated parse); 1.38 s incl. subshell+source | REPRODUCED — even FASTER isolated |
| PER-ENTRY parse (211 python3 spawns) | 5.28 s | **6.30 s** | REPRODUCED (same order; ~175× the batch) |

> **Empirical-Evidence Block (battery invocation count = 151 across 17 files).**
> `CMD`: `grep -rhcE 'validate-pack\.py' scripts/tests/*.sh | awk '{s+=$1} END{print s}'`
> `OUT`: `151`. Per-file top: `test-validate-pack-check-40.sh` 14, `...checks-36-37-38.sh` 12,
> `...check-45.sh` 12, `...check-46.sh` 11, `...check-44.sh` 11, `...check-43.sh` 11, ...,
> `test-v11-realistic-ot.sh` 7. `AT`: `9cc0e88`, 2026-06-07. `INTERP`: the 151× multiplier the failure
> depended on is REAL and reproduced exactly. Any per-invocation cost added to the general `main()` is
> paid 151×. `CONCL`: SUPPORTED — the multiplier is 151, matching the design.

> **Empirical-Evidence Block (baseline general validate-pack = 1.34 s).**
> `CMD`: `/usr/bin/time -p python3 scripts/validate-pack.py`
> `OUT`: `real 1.34 / user 0.94 / sys 0.37`. `AT`: `9cc0e88`, 2026-06-07. `INTERP`: matches the design's
> 1.37 s within run-to-run noise; the 10 s total-run budget sits ~7× above it. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (BATCH 0.036 s vs PER-ENTRY 6.30 s — the seam contrast reproduced).**
> `CMD`: source `tracker-migrate-forward.sh`; build the concatenated 211-entry stream via the real
> `pe_list_entry_files`+`pe_strip_backpointer_stdin`; `time _tmf_parse_backlog_file "$stream"` (ONE
> spawn) vs a 211-iteration loop each calling `_tmf_parse_backlog_file` on a one-entry temp (211 spawns).
> `OUT`: BATCH `real 0m0.036s` (5054-line stream, all 211 entries, ONE python3); PER-ENTRY
> `real 0m6.298s` (211 python3 spawns). `AT`: `9cc0e88`, 2026-06-07. `INTERP`: the per-entry
> subprocess-storm cost (the §1.6b-style C-4.6 driver) is REAL — 6.30 s for ONE leg; the C-4.6 bug ran
> ~4 legs × round-trip ≈ 2,000 spawns, consistent with the 2–5 min/run the failure reports. The batch
> seam collapses it to 36 ms. `CONCL`: SUPPORTED — the batch seam is the correct structural cure; the
> contrast is even larger than the design claimed (the design's 0.44 s batch figure was inflated by its
> `/usr/bin/time -p` subshell + source overhead; the genuine isolated parse is 36 ms).

> **Empirical-Evidence Block (no test sets any deep gate today).**
> `CMD`: `grep -rniE 'VALIDATE_DEEP|PACK_VALIDATE_' scripts/tests/ scripts/*.sh`
> `OUT`: ZERO env-gate SETs (only prose "faithful" substring hits, none an env assignment).
> `AT`: `9cc0e88`, 2026-06-07. `INTERP`: there is no pre-existing battery test that would set
> `PACK_VALIDATE_DEEP=1` and re-introduce the heavy leg into the 151× path. `CONCL`: SUPPORTED.

---

## THE SIX PROOFS

### Proof 1 — PLACEMENT: the deep leg runs only when `PACK_VALIDATE_DEEP=1`; the 151× path early-returns at ~0 ms. **PREVENTED.**

The design (§4.6 (P), lines 914-928; §4.5 row line 849-851) prescribes ONE env gate: the
faithfulness check's heavy whole-real-tree leg runs ONLY under `PACK_VALIDATE_DEEP=1`; in the default
(unset) path — the 151× battery path and ordinary `python3 scripts/validate-pack.py` — the check is a
NO-OP that prints `SKIP: field-faithfulness deep check (set PACK_VALIDATE_DEEP=1)` and returns,
paying one `os.environ.get` + a print ≈ 0 ms. The two deep homes are exactly (a) the new per-check
test `test-validate-pack-check-<NN>-field-faithfulness.sh` (sets the env, points at the real tree),
invoked ONCE by the `tests` job; (b) a dedicated workflow step
(`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`) run ONCE per push.

Structural confirmation that the general path has NO existing env/arg seam (so the gate is a clean,
single addition and the default sequence stays a flat ~1.34 s):

> **Empirical-Evidence Block (`main()` is a flat sequence of direct `check_*()` calls; no env/arg gating today).**
> `CMD`: `grep -nE 'sys\.argv|os\.environ|argparse|def main' scripts/validate-pack.py`
> `OUT`: only `:4003 os.environ.get("PACK_CHECK_36_RANGE", ...)` (a Check-36-local var) and
> `:7336 def main()`; `main()` (read lines 7336-7497) is a flat unguarded sequence ending in
> `if failures: sys.exit(1) else sys.exit(0)`. `AT`: `9cc0e88`, 2026-06-07. `INTERP`: there is NO
> top-level CLI/env seam today — the design's env gate is the first one, added at the head of the new
> check; the 151 other checks are untouched, so the default battery cost stays ~1.34 s × 151 ≈ 202 s
> (unchanged), NOT hours. `CONCL`: SUPPORTED — placement is sound; the default path pays ~0 increment.

The placement matches the `ci-check-runtime-compounding` rule verbatim ("heavy whole-real-tree
verification runs ONCE, a dedicated CI step / the per-check test, NOT inside the general
validate-pack"). **Proof 1: PREVENTED.**

### Proof 2 — TEETH PRESERVED (the critical adversarial check): the env-gate is NOT toothless. **PREVENTED, with one SHOULD.**

An env-gate that CI never sets would be a toothless guard. I verified the teeth are real on TWO
independent structural forces:

1. **The dedicated DEEP workflow step.** The design (§4.5 workflow row line 851; §4.6 (P) lines
   923-925) prescribes a dedicated step that SETS `PACK_VALIDATE_DEEP=1` and runs the deep check on
   the real `/backlog/` on every push. Today's `.github/workflows/validate-pack.yml:97` runs the
   general `python3 scripts/validate-pack.py` WITHOUT the env — so the design CORRECTLY does not rely
   on the existing step for teeth; it adds a new deep home.
2. **Check 42 COMPELS the per-check test to be wired (no exemption).** This is the load-bearing
   structural force: even if a coder forgot the dedicated deep workflow step, the new per-check test
   file (which itself sets `PACK_VALIDATE_DEEP=1`) CANNOT exist on disk unwired — Check 42 fails CI.

> **Empirical-Evidence Block (Check 42 fails any per-check test file lacking a workflow `bash` invocation; no exemption).**
> `CMD`: read `check_ci_workflow_wires_per_check_tests` (`scripts/validate-pack.py:6486-6573`).
> `OUT`: globs `scripts/tests/test-validate-pack-check*.sh` on disk; regex
> `bash\s+scripts/tests/(test-validate-pack-check[^\s]+\.sh)` over the yml; `unwired = disk - wired`;
> on any `unwired` it `fail(...)` per file with the remediation step; docstring: "This check
> intentionally has no exemption mechanism." `AT`: `9cc0e88`, 2026-06-07. `INTERP`: the new
> `test-validate-pack-check-<NN>-field-faithfulness.sh` matches the glob, so it MUST be wired into the
> `tests` job in the SAME commit or CI goes RED. Since that test sets `PACK_VALIDATE_DEEP=1`, wiring it
> = the deep leg runs against the real tree on every push. `CONCL`: SUPPORTED — the teeth are
> CI-enforced, not honor-system. The env-gate-OFF default does NOT disarm the "lossy migration is
> UN-MERGEABLE" property, because the per-check test (env-ON) is a mandatory CI participant.

**SHOULD-1 (teeth wiring redundancy):** the design names TWO deep homes (the per-check test AND a
dedicated `PACK_VALIDATE_DEEP=1` workflow step). Check 42 hard-enforces the FIRST; the SECOND is
prescribed in prose but NOT independently enforced by any check. The teeth survive on the Check-42-
enforced per-check test alone, so this is not a BLOCKER — but the coder MUST actually add BOTH per
§4.5/§4.6, and the implementation reviewer should confirm the per-check test's body genuinely sets
`PACK_VALIDATE_DEEP=1` AND points the check at the real `REPO_ROOT/backlog` (a per-check test that set
the env but pointed at a 3-entry fixture would be green-but-toothless on the real tree). Recommend the
implementation-stage reviewer assert, against the real tree, that the deep check actually executes
≥211 entries (not a fixture) in at least one CI home. **Proof 2: PREVENTED (teeth CI-enforced via
Check 42); SHOULD-1 logged for the coder/impl-reviewer.**

### Proof 3 — NO RE-COMPOUNDING: no battery test re-enters the heavy path. **PREVENTED.**

The compounding required BOTH: heavy work IN the 151× path AND per-entry spawns. I hunted for any
re-entry:

- **No battery test sets `PACK_VALIDATE_DEEP=1`** (re-measurement above: ZERO env-gate sets in
  `scripts/tests/`). The 17 battery files that invoke validate-pack 151× all hit the DEFAULT path,
  which SKIPs the deep leg.
- **The per-check test is invoked exactly ONCE** by the `tests` job (Check 42's wiring is a single
  `bash scripts/tests/<file>` step; the workflow's per-suite steps are one-per-name, not looped). The
  deep workflow step is one step. So the deep leg's total CI executions = 2 (per-check test once +
  deep step once), NOT 151.
- **The target-tree scoping (Proof 4) removes the silent real-tree fallback** that let a fixture test
  pay the real-211 cost — the other half of the C-4.6 bug.

Worst case under the redesign: `151 general runs × ~0 increment + 2 deep runs × the batch cost`.
There is no surviving multiplicative term. **Proof 3: PREVENTED.**

### Proof 4 — TARGET-TREE SCOPING: `tree_dir` is the caller's target with NO `REPO_ROOT/backlog` fallback. **PREVENTED (prescription is explicit and correct).**

The exact C-4.6 bug was `backlog_dir = tree_dir or REPO_ROOT/"backlog"` — the `or` silently reverted
to the real 211-tree whenever the caller passed nothing. The design (§4.6 (T) lines 937-941; §4.6
step 1 lines 708-712; §4.5 row line 849) prescribes: the check takes `tree_dir` = the CALLER's
target; the per-check test passes its fixture tree; the deep CI step passes `REPO_ROOT/backlog`;
**"There is NO `tree_dir or REPO_ROOT/"backlog"` fallback that silently reverts to the real 211 — that
exact fallback was the C-4.6 bug."** The design names the anti-pattern explicitly and forbids it. This
is the correct fix and is the FIRST mandatory constraint.

The design also leans on the EXISTING batch entry-point `tmf_parse_backlog_tree`, which itself takes
the caller's `stream_dir` with NO real-tree fallback — confirming the seam the design reuses already
honors target-scoping:

> **Empirical-Evidence Block (`tmf_parse_backlog_tree` scopes to the caller's `stream_dir`; no REPO_ROOT fallback).**
> `CMD`: read `tmf_parse_backlog_tree` (`scripts/lib/tracker-migrate-forward.sh:588-613`).
> `OUT`: `local stream_dir="$2"; if [[ ! -d "$stream_dir" ]]; then tracker_error_emit "not-found" ...; return 1; fi` — it ERRORS on a missing dir, it does NOT default to `REPO_ROOT/backlog`; it
> enumerates via `pe_list_entry_files "$key" "$stream_dir"` and parses with ONE `_tmf_parse_backlog_file`.
> `AT`: `9cc0e88`, 2026-06-07. `INTERP`: the seam the check drives already scopes strictly to the passed
> dir, so a fixture caller pays only its fixture cost; there is no hidden real-tree fall-through inside
> the batch function. The check's own `tree_dir` param must mirror this (no `or REPO_ROOT/backlog`),
> per §4.6 (T). `CONCL`: SUPPORTED — the prescription is explicit AND the reused seam already enforces
> it. **Coder verification owed:** the new check's argument resolution must NOT reintroduce the `or`
> fallback (impl-reviewer grep: `tree_dir or` / `REPO_ROOT.*backlog` in the new check body = REJECT).

**Proof 4: PREVENTED.**

### Proof 5 — BATCH SEAM: drives the real `tmf_parse_backlog_tree` (one parse), small-constant spawns, OQ-4 holds. **PREVENTED. Spawn count = a small constant (~4–6 batch passes), NOT per-entry.**

The design (§4.6 (S) lines 943-962; §4.6 step 2 lines 713-721) drives the EXISTING real batch
entry-point `tmf_parse_backlog_tree` — ONE `python3` over the whole concatenated stream (the parser
loops internally), then runs compose/reconstruct/emit + the 4 legs in ONE sub-invocation looping over
the parsed array. Per-run subprocess count drops from ~2,000 (per-entry × per-leg) to **a small
constant: on the order of ~4–6 spawns total** (one sub-shell sourcing the libs + a handful of
`python3`/`jq` batch passes: parse, compose-loop, reconstruct-loop, emit-loop) regardless of entry
count. My isolated measurement confirms the single parse pass over all 211 entries is **36 ms** (one
spawn) vs **6.30 s** for the 211-spawn per-entry shape.

OQ-4 (drive the REAL functions, no codec re-impl) holds: `tmf_parse_backlog_tree`,
`_tmf_parse_backlog_file`, `tmf_compose_issue_body`, `tracker_migrate_reverse_reconstruct`,
`_tmr_emit_pack_tree` are the SAME functions the migration uses (verified present:
`grep -n tmf_parse_backlog_tree scripts/lib/tracker-migrate-forward.sh` → defined `:588`, used in
production `:1072`). The check is a BATCH DRIVER over real functions, not a re-implementation.

**Spawn-count statement:** per deep run, a SMALL CONSTANT (~4–6 batch passes), NOT ~10/entry and NOT
~2,000. **Proof 5: PREVENTED.**

### Proof 6 — RUNTIME-BUDGET GUARD: total-run hard-FAIL catches the compounding shape; budgets are measure-then-bounded and don't false-FAIL the legitimate deep run. **PREVENTED, with one coherence SHOULD.**

The §4.7 guard wraps every check in `run_check(name, fn, budget_s)` (`t0 = time.monotonic()` →
`elapsed` → budget compare). Policy: per-check overrun in the general path = LOUD WARN;
**TOTAL-RUNTIME budget on the whole general run = hard FAIL** (`RUNTIME-BUDGET: validate-pack total
<elapsed>s > <total_budget>s`) → CI RED. So the C-4.6 compounding shape (a check that re-enters the
general path and inflates it into minutes) is caught by the total-run hard-FAIL even if a future coder
re-introduces it. This is the durable backstop the prior >2h fix lacked.

Budgets are measure-then-bounded and bracket the measured reality both directions:
- **Total general-run budget = 10 s** vs my measured baseline **1.34 s** (~7× margin → no
  false-positive) and vs the failure's 2–5 min/run (far above 10 s → caught). Confirmed bracketing.
- **Per general check = 2.0 s** (no current check approaches it; the design tells the coder to set it
  to ~2× the measured-slowest, never below the max).
- **Deep faithfulness-check budget = 30 s** vs the measured ≤~5 s batch deep run (~6× headroom → no
  false-fail; a coder reintroducing per-entry spawns would blow 30 s → caught).

> **Empirical-Evidence Block (budgets bracket the measured reality).**
> `CMD`: baseline `/usr/bin/time` 1.34 s (above) vs 10 s total; isolated batch parse 0.036 s vs 30 s
> deep; per-entry 6.30 s/leg (the regression shape) vs 30 s deep.
> `OUT`: 1.34 s ≪ 10 s (general healthy passes); 0.036 s ≪ 30 s (deep healthy passes); a 4-leg
> per-entry regression (~25 s+ and climbing) approaches/breaches 30 s and a real-tree re-entry into the
> general path breaches 10 s. `AT`: `9cc0e88`, 2026-06-07. `INTERP`: every budget sits above the
> healthy measured value and below the failure shape — no false-positive on the healthy baseline, and
> the compounding class is caught. `CONCL`: SUPPORTED — measure-then-bounded, both directions verified.

**SHOULD-2 (deep-run total-budget coherence — the exact concern the prompt flagged):** §4.7 states the
total-run hard-FAIL is "on the whole general run" and that "the deep run carries its own larger
PER-CHECK budget (30 s)." It does NOT state the deep run's TOTAL-RUN budget explicitly. If a coder
applied the 10 s total-run hard-FAIL UNCONDITIONALLY (including the deep run), a legitimate deep run —
general checks (~1.3 s) + the deep faithfulness check (up to its own 30 s budget) — could reach ~31 s
TOTAL and FALSE-FAIL against a 10 s total bound. The design's intent is clearly that the 10 s total-
run FAIL is GENERAL-PATH-ONLY (the deep run gets the larger budget), but the prose leaves the deep
run's total bound IMPLICIT. This is a SHOULD, not a BLOCKER for non-recurrence: (a) the deep run lives
in its own home and runs twice total, so even a false-fail there would not COMPOUND — it would just
RED a legitimate run, the opposite failure mode (annoying, not a 2h hang); (b) the recurrence the gate
targets (the 151× compounding) is structurally killed by Proofs 1+3+4+5 independently of this budget.
Recommend the design/coder state explicitly: **when `PACK_VALIDATE_DEEP=1`, the total-run budget is
the deep total budget (e.g. ~35 s = general 5 s allowance + deep 30 s), NOT the 10 s general bound** —
so the deep run is never subject to a budget it would breach. The coder must re-measure the full 4-leg
deep run and confirm it is < its deep budget with margin (§4.7 already directs this for the 30 s
per-check budget; extend the same to the deep total). **Proof 6: PREVENTED; SHOULD-2 logged.**

---

## VERDICT

### PREVENTED.

The redesign makes all three C-4.6 failure modes structurally impossible, on independent grounds:

- **The 151× multiplier is eliminated** by the env-gate placement (Proof 1) + the no-re-entry property
  (Proof 3): the heavy leg is OUT of the default `main()` the battery calls 151×; it runs in exactly
  two deep homes, twice total.
- **The real-211 silent fallback is eliminated** by strict target-tree scoping with the C-4.6 `or
  REPO_ROOT/backlog` fallback explicitly named and forbidden (Proof 4), backed by the reused batch
  seam which already errors-not-defaults on a missing dir.
- **The ~2,000-subprocess storm is eliminated** by the batch seam over the real `tmf_parse_backlog_tree`
  (Proof 5): ONE parse pass (re-measured 36 ms vs 6.30 s per-entry), ~4–6 spawns/run total.
- **The teeth survive the OFF-by-default gate** because Check 42 (no exemption) compels the per-check
  test — which sets `PACK_VALIDATE_DEEP=1` against the real tree — to be CI-wired (Proof 2). A lossy
  migration remains UN-MERGEABLE.
- **A future recurrence of the CLASS is caught** by the §4.7 total-run hard-FAIL backstop, with budgets
  measure-then-bounded above the healthy baseline and below the failure shape (Proof 6).

Either the placement fix (Proof 1) or the seam fix (Proof 5) alone would prevent the hours-long hang;
together with the scoping fix (Proof 4) the compounding term is removed three ways over. The verdict
is **PREVENTED — safe to plan/code.**

Two SHOULDs accompany the verdict (neither blocks; both are implementation-stage verifications, not
design gaps that could let the failure recur):
- **SHOULD-1** — the coder must add BOTH deep homes (per-check test + dedicated `PACK_VALIDATE_DEEP=1`
  workflow step); only the per-check test is Check-42-enforced. The impl-reviewer must confirm the deep
  check actually runs the REAL ≥211 tree (not a fixture) in ≥1 CI home, and that the per-check test
  body genuinely sets the env.
- **SHOULD-2** — §4.7 should state explicitly that the 10 s TOTAL-run hard-FAIL is general-path-only;
  the deep run's total budget must be the larger deep bound so a legitimate deep run is never subject
  to a budget it would breach. (False-fail risk only; cannot reintroduce the hang.)

Implementation-stage verification owed (grep gates for the impl-reviewer): (a) no `tree_dir or` /
`REPO_ROOT.*backlog` fallback in the new check; (b) the new check early-returns under unset
`PACK_VALIDATE_DEEP` BEFORE any tree scan; (c) the new per-check test is wired (Check 42 enforces) AND
sets the env AND targets the real tree; (d) the deep run measures < its deep budget with margin.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Ran only read-only Bash (`git rev-parse`, `grep`, `time`, `ls`, `sed`/`cat` via Read) + this single Write. No `git add/commit/push/tag`; no edit to any file but this report. | COMPLIANT |
| `empirical-evidence-blocks` | Every state-claim carries an EE block with CMD + verbatim OUT + `AT: 9cc0e88, 2026-06-07` + INTERP + CONCL (invocation-count, baseline-runtime, batch-vs-per-entry, no-deep-set, main()-flat, Check-42, tmf_parse_backlog_tree, budget-bracketing). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly the 6 proofs + independent re-measurements + verdict + the two SHOULDs the prompt's coherence question surfaced. No redesign authoring; no out-of-scope §1/§2/§3 review (read only as context). | COMPLIANT |
| `rules-applied-verification-block` | This table: each prompt rule named + evidence + terminal conclusion; no empty-evidence cell, no AMBIGUOUS. | COMPLIANT |

## READ-IN-FULL attestation

| Required reading | Read? | Evidence |
|---|---|---|
| `feedback_ci_check_runtime_compounding.md` | FULL | Read lines 1-51 (entire file); the cost = per-run × battery-count rule, the 4 application bullets, and the runtime-guard mandate are quoted/applied in Proofs 1/3/5/6. |
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §4 + §4.6 + §4.6.1 + §4.7 + §4.5 | FULL | Read lines 1-476, 477-951, 952-1301 (the doc is 1539 lines; §4 spans 661-1029, §5 surfaces 1031-1300 read for context). §4.5 surface table (844-868), §4.6 (892-969), §4.6.1 (971-985), §4.7 (987-1029) read line-by-line. |
| `scripts/validate-pack.py` main() + registry + Check 42 | FULL (relevant spans) | Read `main()` 7336-7497 (flat dispatch, failures/exit), `check_ci_workflow_wires_per_check_tests` 6486-6575 (no-exemption wiring gate), env/argv grep. |
| `.github/workflows/validate-pack.yml` | FULL | Read lines 1-287 entire; confirmed `validate` step `:97` runs general (no env), `tests` job per-suite steps, Check-42-test wired `:181-183`. |
| `scripts/lib/tracker-migrate-forward.sh` `tmf_parse_backlog_tree` :588 | FULL | Read 588-647 (the batch seam body) + gz64 carrier grep (`_tmf_gz64_encode` :704, `raw_body` :443/:574, marker :846). |
| battery test files (validate-pack invocations + PACK_VALIDATE_DEEP) | FULL (grep census) | `grep -rcE 'validate-pack\.py'` (151/17) + `grep -rniE 'VALIDATE_DEEP|PACK_VALIDATE_'` (zero sets) across `scripts/tests/`. |
| `CLAUDE.md` `## Pack memory` | FULL | Read in full via the project-instructions context block at session start (Workflow, Agent-invocation, Repo-conventions, ci-guard-measure-then-bound, enumerate-encoding-surfaces, etc.). |
