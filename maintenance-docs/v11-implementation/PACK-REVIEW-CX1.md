# PACK-REVIEW-CX1 — BD-221 agent-migration CORRECTION (fix-forward, supersedes C7)

**Reviewer:** pack-reviewer (read-only, isolated worktree)
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-adcb03ef07394ff01`
**HEAD:** `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` (== `c4beb8d`, confirmed)
**Date:** 2026-06-17
**Spec reviewed against:** `DESIGN-AGENT-MIGRATION-MODEL.md` §5 + `RECONCILIATION.md` C-1/C-2 (verified independently; IMPL-REPORT used only to locate items — none was supplied).

---

## VERDICT: CLEAN — ready to patch + commit

The keystone correction is **empirically proven correct on the real net-new
v10→v11 migration path**. All §3 behaviors (a–e + the `--update`/replace-if-
different proof) reproduce as designed; C-1 and C-2 are satisfied; OQ-1/2/3/6
hold; D1 + D2 are fixed; the boundary is exactly the 6 `scripts/` files;
grep-zero passes (every `.gemini`/`gemini` ref is KEEP-mandated). The full
wired CI suite is **72/72** and `validate-pack` is exit 0 in both modes.

Two **NIT** comment-accuracy defects remain (a code comment + a test comment
that misname a classification token). Neither changes runtime behavior on the
real migration path; both are accuracy-only and surfaced below for triage. The
§5 surfaced item is assessed as **correct / benign / out-of-CX1-scope** (no
gap).

---

## SECTION 0 — Worktree / scope confirmation

- `pwd` = the isolated worktree (confirmed).
- `git rev-parse HEAD` = `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` (matches).
- `git status --short` = exactly 6 modified files, all under `scripts/`:
  `init-project.sh`, `lib/customization-preserve.sh`, `migrate-v10-to-v11.sh`,
  `persona-contracts/contract-migration.sh`, `tests/test-customization-preserve.sh`,
  `tests/test-migrate-v10-to-v11.sh`. **MATCH.**
- `git diff --stat`: 6 files, +373 / −88.
- Working tree remained exactly these 6 files after all migrator runs + the
  full test battery (no stray writes; scratch dirs cleaned).

---

## SECTION 2 — GATE (all PASS)

| Gate | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **exit 0** ("PASSED — all checks clean") |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **exit 0** |
| New fail-lines (base green @ HEAD) | **EMPTY** — both modes green |
| Full wired suite (every script in validate-pack.yml, disk-derived) | **72/72 PASS** |
| `test-migrate-v10-to-v11.sh` | **PASS** |
| `test-customization-preserve.sh` | **PASS** |
| `test-persona-contracts.sh` (fixture-dependent) | **PASS** |
| `test-fixtures/build.sh --verify` (rebuilt SHAs == committed) | **PASS** |
| Manifest in diff? | **NO** — `git diff --name-only` excludes `test-fixtures/manifest.txt` (correct: CX1 touches only the `--update` leg + per-test `/tmp` runs; init-built committed fixtures unchanged — corroborates design EB-5) |

The wired set was extracted from disk via `ci-shard-plan.py --emit-matrix`
(72 scripts), fixtures were built, the committed manifest restored, then every
script run line-by-line with EXIT captured. PASS=72 FAIL=0.

---

## SECTION 3 — EMPIRICAL MIGRATOR BEHAVIOR (the keystone; independently reproduced)

Method: copied `test-fixtures/v10-realistic-ot` (custom `x-fakeot-domain` in
`.gemini/.claude/.codex` agents) to a `/tmp` scratch git repo, sourced the
PATCHED migrator, initialized the customization-preserve engine exactly as
`migrator-stages.sh::_stage_libs` does, then ran the post-dispatch helpers in
production order: `_v10_to_v11_install_v11_artifacts` →
`_v10_to_v11_lift_gemini_customs_to_bundle` → `_v10_to_v11_retire_gemini`.
Pre-seeded a STALE `coder.md` and an extra `x-foo.md` in the bundle before the
install step.

| Claim | Evidence | Verdict |
|---|---|---|
| **(a) bundle = 16 pack agents as v11 content, replace-if-different** | Pre-seeded STALE `coder.md` was REPLACED: bundle `coder.md` SHA `6a06aa94…` == pack source SHA `6a06aa94…`. All 16 pack agents byte-identical to pack source (`cmp -s` mismatches = **0**). | **CONFIRMED** |
| **(b) custom `x-*.md` landed IN the bundle (lifted from Gemini per OQ-1)** | `x-fakeot-domain.md` present in `.agents-plugin/optiquity-agents/agents/`; byte-identical to the `.gemini/` source; migrator logged `source: .gemini/agents/x-fakeot-domain.md`. | **CONFIRMED** |
| **(c) `gemini-retired-docs/` holds the `.gemini/` backup** | `gemini-retired-docs/.gemini/agents/x-fakeot-domain.md` present; original `.gemini/` removed (moved, not copied). | **CONFIRMED** |
| **(d) idempotent (re-run = no-op)** | Lift re-run: `bundle custom 'x-fakeot-domain.md' already present — left untouched`, `lifted 0`. Retire re-run: `no departing .gemini/ tree — nothing to retire`, rc=0. Agent CONTENT unchanged across re-run (coder/x-fakeot/x-foo SHAs identical). **Caveat — install step is NOT a clean no-op on re-run** (see NIT-1 below): it sidecars all 16 pack agents because the engine sees base="" + ours present → `project-shadows-new-pack` (never `unchanged-pack`). Content stays correct; spurious `.pre-update` sidecars accumulate. Does NOT occur on a real single-shot net-new migration. | **CONFIRMED for lift+retire; install caveat (NIT-1)** |
| **(e) non-clobber on a customized bundle** | Pre-seeded extra `x-foo.md` SURVIVED with original content after install+lift+retire. | **CONFIRMED** |
| **`--update`/D1 replace-if-different proof** | `test-customization-preserve.sh` 6.4 + my direct repro: bundle pack agent with a STALE client copy + different pack content → dest replaced with v11 content (class `pack-agent`). The init `--update` leg now self-classifies (forced `pack-agent` dropped) so a bundle `x-` is preserved on bump. | **CONFIRMED** |

The first-run (real-migration) path produced **zero** sidecars — `ours` absent
for every pack agent → `new-file-in-pack` → clean add. The keystone path is
clean.

---

## SECTION 4 — CORRECTIONS + OQs

- **C-1 (bundle-custom assertion is meaningful) — SATISFIED.** Group 6 calls
  `_v10_to_v11_lift_gemini_customs_to_bundle` THEN `_v10_to_v11_retire_gemini`
  in production order (post-LIFT state), and pre-creates the bundle agents dir.
  I sabotaged the lift (ran only retire): assertion 6.1 then finds
  `x-ot-domain.md` NOT in the bundle → would FAIL. The assertion is meaningful,
  not vacuous. Reconciliation C-1 met.
- **C-2 (lift is a DIRECT `cp`, not engine-routed) — CONFIRMED.** Verified at
  the engine level: `customization_preserve`'s `custom-agent` branch
  (customization-preserve.sh L443-451) records `removed-everywhere` with
  action `none` and NO copy when `ours` is absent — which it always is for a
  net-new bundle custom. The lift therefore uses a direct `cp "$src" "$dest"`
  (migrate-v10-to-v11.sh L582). Correct primitive. Reconciliation C-2 met.
- **OQ-1 (source selection + divergence flag) — CONFIRMED empirically.** Lift
  prefers `.gemini/agents/x-*.md` (Gemini source), falls back to
  `.claude/agents/x-*.md`. Reproduced: Gemini-absent/Claude-present → lifted
  from Claude; both-exist-and-differ → divergence note emitted + Gemini copy
  WINS (bundle content = "GEMINI version").
- **OQ-2 (invariant note: `x-` reserved for client) — PRESENT.**
  customization-preserve.sh L182-189 documents the SHARED-namespace invariant
  and that `x-` is reserved for client customs (so pack/custom never
  mis-classify).
- **OQ-3 (`cmp -s` byte-identity) — CONFIRMED.** `three_way_classify` uses
  `cmp -s` (three-way.sh L70-71, L108); "different" = byte-level. My (a)
  byte-identity check (0 mismatches) exercises this.
- **OQ-6 (fresh-init count guard left strict) — CONFIRMED.**
  `init-project.sh stage_s2_agents` retains the strict
  `bundle_count == pack_count` guard (L466) untouched. The ONLY init change is
  the `--update` self-classify leg (L1147/L1316-1317 region). Correct.
- **Classifier leg ordering (`x-` BEFORE `*.md`) — CONFIRMED.**
  customization-preserve.sh L190 (`.agents-plugin/*/agents/x-*` → custom-agent)
  precedes L192 (`.agents-plugin/*/agents/*.md` → pack-agent). Empirically:
  bundle `x-foo.md` → custom-agent, bundle `coder.md` → pack-agent,
  `plugin.json` → generic, `other-ns/agents/x-bar.md` → custom-agent
  (namespace-robust).
- **D1 + D2 fixed — CONFIRMED.** The C7 non-clobber bundle block
  (`[[ ! -f "$bundle_dest" ]]`) is GONE — replaced by engine-routed
  `customization_preserve` (replace-if-different). Customs are LIFTED
  (`_v10_to_v11_lift_gemini_customs_to_bundle` defined L525, called L153 after
  install / before retire), not merely retired.
- **Encoding surfaces updated in lock-step.** Classifier branch + docstring
  class-list (L23-25) + `test-customization-preserve.sh` (1.15–1.18, 6.3, 6.4)
  + `test-migrate-v10-to-v11.sh` Group 6 + persona-contract 3b. MERGE-STRATEGY.md
  class-7/8 prose is correctly DEFERRED to C8 (design §6.4 row 5) — not touched
  here (not scope creep).

---

## SECTION 5 — SURFACED ITEM (assessed, NOT fixed)

**Surfaced concern:** a CUSTOMIZED (or merely pre-existing) pack agent in the
bundle, on the migrator path, triggers the conservative
`project-shadows-new-pack` → needs-reconciliation sidecar gate.

**My independent reproduction confirms the mechanism precisely.** With
base="" (the bundle has no v10 baseline) + `ours` present + `theirs` present,
`three_way_classify` returns `project-shadows-new-pack` **regardless of
ours==theirs** (three-way.sh L99-102), which `_cp_strategy_text` routes to
`sidecar` + `cp theirs dest` (L294-305). The 6.4 scenario records disposition
`customization-detected-needs-reconciliation` and writes a `.pre-update`
sidecar.

**Assessment — the coder is CORRECT; this is benign and out-of-CX1-scope:**
1. The bundle is genuinely **net-new in v11**: `git ls-tree -r v10` has **0**
   `.agents-plugin/` paths; the `v10-realistic-ot` fixture has none. A real
   v10→v11 migration therefore has **no pre-existing bundle pack agent** →
   `ours` is ALWAYS absent → `new-file-in-pack` → clean add, **no sidecar**.
   My first-run keystone repro produced zero sidecars, confirming this.
2. The migrator apply path is sentinel-guarded single-shot (refuses bare
   re-run; requires `--resume`), so the second-run sidecar accumulation does
   not occur on a real migration.
3. The base-absent / `project-shadows-new-pack` behavior on a *re-bump* is the
   pre-existing-and-accepted domain of `init-project.sh --update` (base="" is
   passed deliberately, the same as the loose surfaces) per design §3.1 — NOT
   CX1's migrator scope.

**Verdict: NOT a gap and NOT a CX1 blocker.** The conservative gate is correct
behavior (it never silently clobbers; it sidecars). It is simply never reached
on the real net-new migration. No fix required in CX1.

---

## SECTION 6 — BOUNDARY + GREP-ZERO

- **Boundary:** `git diff --name-only` = exactly the 6 `scripts/` files (count
  6). **NO `three-way.sh`** (verify-only — correctly untouched), **NO
  `pack-ops/`**, **NO `supporting-docs/`**, **NO `test-fixtures/manifest.txt`**.
  All-`scripts/` → pack-only-clean (Check 36 safe; no `project-template/` or
  `supporting-docs/` touched).
- **grep-zero:** 70 `.gemini`/`gemini`/`Gemini`-family references appear in
  ADDED lines. **Every one is KEEP-LEGITIMATE** — the migration by definition
  READS `.gemini/agents/` as the lift source (OQ-1 mandate) and retires
  `.gemini/` to `gemini-retired-docs/` (decision 8). Categories, all mandated:
  - **Helper names:** `_v10_to_v11_lift_gemini_customs_to_bundle`,
    `_v10_to_v11_retire_gemini` (the migration's own functions).
  - **Live path reads:** `.gemini/agents/` (the lift source),
    `$_MIGRATOR_TARGET/.gemini/...`.
  - **Retirement target:** `gemini-retired-docs/` (the documented holding dir).
  - **Banners / client-facing prose:** `── S5a — lift departing Gemini x-
    custom agents …`, the retire user-message ("Your full .gemini/ tree was
    moved to gemini-retired-docs/ …").
  - **Code comments + test assertions/labels** describing the Gemini→
    Antigravity conversion and verifying lift+retire behavior.
  - **`GEMINI.md` / `.gemini/agents/` in the classifier docstring** — the
    legacy-READ carve-out (the classifier must recognize the departing shape).

  No stray / convertible occurrence exists — this is migration code that must
  handle the departing Gemini tree. **grep-zero gate: PASS** (zero
  non-allowlisted hits).

---

## FINDINGS (severity-tagged)

### NIT-1 — install-step idempotence comment is factually wrong
`scripts/migrate-v10-to-v11.sh` L379-380 comment:
> "Idempotent: a re-run sees ours==theirs → unchanged-pack, no-op."

This is inaccurate. The bundle has NO v10 baseline, so the engine is always
called with base="". On a re-run (ours present), `three_way_classify` returns
`project-shadows-new-pack` (NOT `unchanged-pack`) — even when ours==theirs —
and `_cp_strategy_text` writes a `.pre-update` sidecar for every pack agent.
The agent CONTENT is preserved (dest gets theirs == ours), but the install step
is NOT a clean no-op on re-run; it sidecars all 16 pack agents. Empirically
reproduced (16 spurious `.pre-update` files on a second helper run). **Impact:
documentation accuracy only** — the real net-new migration is single-shot and
ours is absent (clean add, no sidecar), so no user-visible effect on the
supported path. Recommend correcting the comment to state the true
classification (base="" + ours present → `project-shadows-new-pack`; on a real
v10→v11 migration ours is absent → `new-file-in-pack` → clean add; re-runs are
guarded against by the migrator's single-shot apply gate).

### NIT-2 — test 6.4 comment misnames the classification token
`scripts/tests/test-customization-preserve.sh` L376-378 comment:
> "Base "" + ours present + theirs differs → new-file-in-pack on the net-new
> bundle surface → copy theirs …"

Wrong token: with `ours` present the classification is
`project-shadows-new-pack`, not `new-file-in-pack` (which requires ours
ABSENT). The test's *assertions* (class = `pack-agent`; dest content replaced
with theirs) are CORRECT and PASS, because `project-shadows-new-pack` also does
`cp theirs dest`. But the comment misdescribes the path, and the test does not
assert the disposition token, so it silently masks that the scenario produces a
`customization-detected-needs-reconciliation` disposition + a `.pre-update`
sidecar. **Impact: documentation accuracy only.** Recommend correcting the
comment (and optionally asserting the disposition/sidecar so the test documents
the real engine behavior). Cross-references NIT-1 (same root: base="" + ours
present ≠ `new-file-in-pack`).

> Triage note: both NITs are accuracy-only and could be folded into a single
> small fix-coder pass on the two comment blocks; neither blocks the commit.
> Per `feedback-deferral-is-scope-creep` the default is FIX-now (they are
> one-block edits), but they do not gate CLEAN.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only throughout. Ran only read verbs (`git diff/status/rev-parse/ls-tree`), `validate-pack.py`, test scripts, and migrator helpers against `/tmp` scratch repos. No `git add/commit/...`; no state-changing git verb. Final `git status` = the same 6 files at HEAD `c4beb8d`. Single write = this report at the prompted `/tmp` path. | COMPLIANT |
| **verify-full-ci-suite** | Extracted the complete disk-derived wired set (`ci-shard-plan.py --emit-matrix` → 72 scripts), built fixtures, restored committed manifest, ran EVERY script line-by-line quoting per-test pass/fail: **PASS=72 FAIL=0**. Plus both `validate-pack` modes exit 0. Plus the empirical migrator run (the keystone) beyond the unit/integration shards. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Verified the diff is targeted in-place edits (hunks add legs/functions/tests; no full-file rewrite). The classifier `case` gained 2 ordered legs without reflowing existing legs; the install function was edited in place; the lift function is a clean insertion before retire. No section silently dropped (read the full files around each hunk). | COMPLIANT |
| **rename-plans-measure-then-bound** | Ran the grep-ZERO gate over the 6-file scope: `git diff | grep '^+' | grep -i gemini` = 70 hits, EVERY hit classified KEEP-mandated (migration reads `.gemini/agents/` + retires `.gemini/`; `GEMINI.md`/`.gemini` legacy-read carve-out). Zero non-allowlisted occurrences. Gate PASS. | COMPLIANT |
| **manifest-regen-on-v11-surface** | The CX1 change is `scripts/`-touching (v11-surface), so I ran `build.sh --all --clean` then `--verify`: rebuilt fixture SHAs == committed manifest (clean). `git diff --name-only` confirms `test-fixtures/manifest.txt` is NOT in the diff — correct/empty (migrator fix doesn't alter init-built committed fixtures; corroborates design EB-5). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly CX1 (the 6 files + the empirical migrator behavior). The §5 surfaced item was ASSESSED (verdict: benign/out-of-scope) not chased/fixed. MERGE-STRATEGY/C8 + C11 doc surfaces noted as correctly out-of-CX1-scope, not reviewed as in-scope. No edge-case sprawl. | COMPLIANT |
| **rules-applied-verification-block** | This block. Every rule above carries quoted/measured evidence + a terminal COMPLIANT conclusion (no AMBIGUOUS). | COMPLIANT |

---

## SUMMARY

- **§3 empirical (a–e + --update D1):** all CONFIRMED on the real net-new
  migration path; lift+retire idempotent; install-step re-run sidecar caveat is
  documentation-only (NIT-1) and never reached on the supported single-shot path.
- **C-1:** SATISFIED (assertion meaningful — fails if lift broken).
- **C-2:** CONFIRMED (direct `cp`; engine `custom-agent` no-copies when ours absent).
- **OQ-1/2/3/6:** all hold (Gemini-first + Claude fallback + divergence flag;
  invariant note; `cmp -s`; fresh-init strict guard untouched).
- **D1 + D2:** fixed (non-clobber block gone → engine replace-if-different;
  customs lifted).
- **§5 surfaced item:** correct/benign/out-of-scope — NOT a gap.
- **Boundary + grep-zero:** PASS (6 files; no forbidden paths; all gemini refs
  KEEP-mandated).
- **Findings:** 2 NITs (comment accuracy: NIT-1 install comment, NIT-2 test 6.4
  comment). No BLOCKER / MUST / SHOULD.

**VERDICT: CLEAN — ready to patch + commit.** (Optional single-pass NIT fix on
the two comment blocks recommended per default-fix-now, but does not gate the
commit.)
