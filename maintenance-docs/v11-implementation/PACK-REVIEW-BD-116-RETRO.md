# PACK-REVIEW-BD-116-RETRO.md — Retroactive per-BD review

**Reviewer:** pack-reviewer (sub-agent of Pack Chat)
**Date:** 2026-05-15
**BD:** BD-116 — Persona contract assertions (template-derived expected output)
**Original commit:** `72789fc` (2026-05-12, Phase 3.5 Batch 3b)
**Batch:** 21c — retroactive per-BD review pass
**Methodology:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (six dimensions a-f, touch-point classification)

This review is performed cold — the reviewer has NOT read
`PACK-REVIEW-BD-116.md` or sibling RETRO reviews to avoid bias.

---

## 1. Scope

**In-scope (per BD-116 commit `72789fc`):**

- `scripts/persona-contracts/contract-greenfield.sh` (NEW, 190 lines)
- `scripts/persona-contracts/contract-mid-dev.sh` (NEW, 213 lines)
- `scripts/persona-contracts/contract-migration.sh` (NEW, 353 lines)
- `scripts/test-persona-contracts.sh` (NEW, 82 lines)
- `test-fixtures/build.sh` (MOD, +118/-16 — `--for-contract` flag + `_materialize_for_contract` helper)
- `.github/workflows/validate-pack.yml` (MOD, +3 lines — new `persona contracts` step)
- `README.md` (MOD, +5 lines — Repository Layout entries; reviewer NIT N2 fix)

**Authoritative scope source:** BACKLOG.md BD-116 entry (lines 1131-1158) +
IMPLEMENTATION-REPORT-BD-116.md.

**Out of scope (noted but not pursued):**

- BD-115 fixture content (covered by BD-115 retro review).
- BD-118 CI step ordering / RELEASE-GATE wiring (covered by BD-117 retro
  review and the later BD-163 reorder).
- BD-161 (POQ-BD-116-1 follow-on for migrator skill installs).
- BD-080 stage S11 contents proper (BD-116 only consumes the enumeration).

---

## 2. Methodology notes

Surveyed artifacts:

- `git show --stat 72789fc` — confirmed file list and line counts.
- `git show 72789fc -- <file>` — inspected the actual code shipped at
  commit time for `test-fixtures/build.sh`, the workflow change, and
  the README change.
- Read all four shipped scripts in their current `HEAD` form
  (post-commit; no further edits found via `git log --oneline -- <file>`).
- BACKLOG entry BD-116 (lines 1131-1158) for problem / acceptance
  criteria / File/Symbol.
- BACKLOG entry BD-161 (lines 1541-1546) for the POQ disposition.
- IMPLEMENTATION-REPORT-BD-116.md for the coder's claims.
- `scripts/init-project.sh:stage_s11_v11_artifacts()` (lines 803-884)
  for the S11 enumeration the contracts mirror.
- `scripts/migrate-v10-to-v11.sh` lines 76-80 for sidecar suffix
  contract (`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`).
- `scripts/lib/migrate-v10-to-v11/resume.sh` lines 40-272 for the
  apply→resume cycle behavior (sidecar `.resolved` flag handling).
- `scripts/lib/customization-preserve.sh` lines 18, 55, 113 for the
  default sidecar suffix (`.pre-update`, used by `init --update`, NOT
  by the v10→v11 migrator).
- `.github/workflows/validate-pack.yml` (current HEAD) to confirm CI
  step ordering after the BD-118 (`b93d22b`) and BD-163 (`422ec12`)
  follow-on reorders.
- `scripts/validate-pack.py` Check 23 implementation (lines 1673-1717)
  for the pack-internal helper marker discipline.
- `HELP-FRAGMENT-PACK.md` confirmed not to need a new entry (test
  scripts are pack-internal).
- `project-template/.github/ISSUE_TEMPLATE/` confirmed three forms
  shipped (config.yml, inbound.yml, work-item.yml).

Cross-references searched: every literal `test-persona-contracts.sh`,
`persona-contracts/`, `contract-greenfield`, `contract-mid-dev`,
`contract-migration`, `BD-116` token across repo (excluding
`PACK-REVIEW-*`).

Touch-point classifications applied per finding.

---

## 3. Findings

### Finding 1 — F1 (SHOULD)

**Severity:** SHOULD
**Dimension:** (a) Completeness
**Touch-point class:** OWNED (contract-greenfield.sh is owned by BD-116)
**Evidence:** `scripts/persona-contracts/contract-greenfield.sh:155-164`
vs. `scripts/init-project.sh:838-847` and
`scripts/persona-contracts/contract-migration.sh:333-347`.

**Description:** The greenfield contract's `s11_files` array enumerates
items 1, 2, 4, and 5 of `stage_s11_v11_artifacts()` but **omits item 3
(`.github/ISSUE_TEMPLATE/*.yml` issue forms — BD-063)**. The migration
contract DOES check this surface (lines 333-347). The asymmetry is a
real coverage gap: a regression in `stage_s11_v11_artifacts()` step 3
that broke greenfield issue-form installs would slip past CI green
(only the migration contract would catch it, and only because the v10
fixture has issue forms in the post-migrate state).

The N1 fix added the comment "this list mirrors the hardcoded
enumeration in scripts/init-project.sh:stage_s11_v11_artifacts(). Keep
the two in sync …" at lines 152-154 — but the array was not actually
brought to parity. The mirror is incomplete.

**Suggested fix.** Extend the `s11_files` array in
`contract-greenfield.sh` to include the issue forms, mirroring the
migration contract's pattern (lines 333-347):

```bash
# Issue forms (BD-063): every project-template/.github/ISSUE_TEMPLATE/*.yml
# should be present after stage S11.
if [[ -d "$PACK_ROOT/project-template/.github/ISSUE_TEMPLATE" ]]; then
    missing_forms=0
    for src in "$PACK_ROOT/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        if [[ ! -f "$SANDBOX/.github/ISSUE_TEMPLATE/$name" ]]; then
            missing_forms=$((missing_forms + 1))
        fi
    done
    if [[ "$missing_forms" -eq 0 ]]; then
        t_pass "all .github/ISSUE_TEMPLATE/*.yml installed by greenfield init"
    else
        t_fail "$missing_forms ISSUE_TEMPLATE form(s) missing post-init"
    fi
fi
```

**Cross-concept impact:** None. Contract-internal change.

**Rule violated:** Pack memory `feedback_filename_uniqueness.md` /
single source of truth principle — the comment claims the array is the
mirror of `stage_s11_v11_artifacts()`, but the mirror is incomplete.
Methodology dimension (a) Completeness: the BD's stated goal is
"derived from project-template/" with "auto-evolve" semantics; a
hardcoded list missing one of the five S11 sub-stages contradicts
both halves.

---

### Finding 2 — F2 (SHOULD)

**Severity:** SHOULD
**Dimension:** (b) Edge cases (bounded)
**Touch-point class:** OWNED (contract-migration.sh is owned by BD-116)
**Evidence:** `scripts/persona-contracts/contract-migration.sh:280-281`
vs. `scripts/migrate-v10-to-v11.sh:76`
(`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`) and
`scripts/lib/customization-preserve.sh:113`
(`local sidecar_suffix="${2:-.pre-update}"`).

**Description:** Assertion 3c's fallback search uses the wrong sidecar
glob:

```bash
if find "$SANDBOX" -name "config.toml.pre-*" -type f 2>/dev/null \
        | xargs grep -L "^\[model_providers\.ollama\]" >/dev/null 2>&1; then
```

The `config.toml.pre-*` pattern matches `init-project.sh --update`'s
`.pre-update` sidecar suffix. The v10→v11 migrator uses
`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`, so any sidecar this
migrator creates would be named `config.toml.v10-customized` — never
`config.toml.pre-*`. The fallback is therefore unreachable in the
contract's actual execution context (a v10→v11 migration via
`scripts/migrate-v10-to-v11.sh`).

In practice the contract still PASSes today because the primary check
at line 275 succeeds: the v10-realistic-ot fixture's
`.codex/config.toml` ollama-removal customization is preserved
byte-identical by the migrator (the file isn't touched). But a future
regression that DID restore the ollama block would skip silently past
the intended fallback (sidecar variant) and fail directly — which is
acceptable behavior, but the broken fallback path is misleading
documentation about how the contract is supposed to handle the BD-088
needs-reconciliation path.

There is also a secondary concern: `xargs grep -L … >/dev/null 2>&1`
returns success when `xargs` is invoked with no inputs (since `find`
returns nothing), so the conditional is technically true even when
no sidecars exist. Combined with the wrong glob, the fallback would
incorrectly pass on a future failure case where the live file
contains the restored block AND no sidecar carries the customization.

**Suggested fix.** Either align the glob with the actual migrator
sidecar suffix or drop the fallback as dead code:

Option A (align):
```bash
if find "$SANDBOX" -name "config.toml.v10-customized" -type f 2>/dev/null \
        -exec grep -L "^\[model_providers\.ollama\]" {} + 2>/dev/null \
        | grep -q .; then
    t_pass "3c: ollama-removal customization surfaced via .v10-customized sidecar"
else
    t_fail "3c: ollama-block returned in .codex/config.toml" \
        "migrator silently restored deleted [model_providers.ollama]"
fi
```

Option B (drop the fallback): if BD-088 invariants guarantee the
config.toml customization is preserved live (which is currently true
for v10-realistic-ot), document that and `t_fail` directly when the
ollama block reappears.

The pattern at line 250 of the same file (`find "$SANDBOX" -name
"${f}.*-customized" -type f -not -path "*/.git/*"`) already uses the
correct generalized form for the trinity 3a check — this fallback
should follow the same pattern.

**Cross-concept impact:** Touches BD-088 sidecar-suffix coupling.
Touch-point class is OWNED (the contract is the consumer of the
sidecar contract; the migrator's sidecar suffix is a CONTRACT, but
this finding is about a hard-coded mismatch in the consumer, not a
change to the contract itself).

**Rule violated:** Methodology dimension (b) Edge cases — the
documented BD-088 needs-reconciliation path is the very edge case the
fallback exists to cover, but the fallback can't fire. Also CLAUDE.md
"empirical anchoring" — the comment at line 278-279 ("Acceptable if
migrator surfaced the customization to a sidecar (BD-088
needs-reconciliation path)") asserts behavior the code can't actually
verify.

---

### Finding 3 — F3 (NIT)

**Severity:** NIT
**Dimension:** (a) Completeness
**Touch-point class:** OWNED (contract-greenfield.sh is owned by BD-116)
**Evidence:** `scripts/persona-contracts/contract-greenfield.sh` —
no assertion for `docs/pack/PM-CHAT.md`, `docs/pack/PLATFORM-SKILLS.md`,
`docs/pack/PACK-FEEDBACK.md`, or `docs/pack/prompts/*.md` files
installed by `init-project.sh:stage_s6_*` (lines 539-595 in
`init-project.sh`).

**Description:** The greenfield contract verifies skills (S4), agents
(S2), trinity (S7), S11 client artifacts (partial — see F1), and
`agent-run.sh` (S5). It does NOT verify `docs/pack/` content beyond
the two HELP-FRAGMENT files (which are S11-installed, not S6).

Specifically uncovered:
- `docs/pack/PM-CHAT.md` (the PM chat operating doc shipped with every
  install).
- `docs/pack/PLATFORM-SKILLS.md` (the 5+3 dimension intersection
  table; authoritative for skill loading per V3.3 §8.4).
- `docs/pack/PACK-FEEDBACK.md` (the user-feedback channel).
- `docs/pack/prompts/*.md` (10 per-agent prompt templates verified by
  init-project at line 594 with a `>= 10` count assertion).

A regression that broke S6 would be caught by `init-project.sh` itself
(stage S6 has internal `fail_stage` checks) — so this is partial
defense-in-depth, not a gaping hole. The init-project internal checks
short-circuit the contract's `[[ "$INIT_SH" exit 0 ]]` test if S6
fails, so the contract IS protected indirectly. Surfacing this as NIT
because the contract should self-document its surface assumptions.

**Suggested fix.** Add a short S6 assertion family to
`contract-greenfield.sh` (after the trinity check at line 149):

```bash
# Assertion 6: stage S6 docs/pack/* + docs/pack/prompts/*.md present.
# (Defense-in-depth — init-project.sh's stage_s6 has internal fail_stage
# checks; this surfaces the same surface to the contract for clarity.)
for f in PM-CHAT.md PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
    if [[ -f "$SANDBOX/docs/pack/$f" ]]; then
        t_pass "S6 docs/pack/${f} present"
    else
        t_fail "S6 docs/pack/${f} MISSING"
    fi
done
prompts_count=$(find "$SANDBOX/docs/pack/prompts" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if (( prompts_count >= 10 )); then
    t_pass "S6 docs/pack/prompts/ has ${prompts_count} prompt files (>=10 expected)"
else
    t_fail "S6 docs/pack/prompts/ count too low" "expected >=10 got $prompts_count"
fi
```

**Cross-concept impact:** None. Contract-internal change.

**Rule violated:** Methodology dimension (a) Completeness — the BD-116
goal is to assert the install is "correct"; partial S-stage coverage
is a defensible scoping choice but should be documented.

---

### Finding 4 — F4 (NIT)

**Severity:** NIT
**Dimension:** (e) Design best practice adherence
**Touch-point class:** OWNED (contract-mid-dev.sh is owned by BD-116)
**Evidence:** `scripts/persona-contracts/contract-mid-dev.sh:60-102`
(three sequential `trap … EXIT` redefinitions).

**Description:** The mid-dev contract sets the EXIT trap three times
in 40 lines:

- Line 64: `trap '… SANDBOX cleanup …' EXIT`
- Line 83: `trap '… PRE_SNAPSHOT + SANDBOX cleanup …' EXIT`
- Line 101: `trap '… PRE_SNAPSHOT + PRE_GITIGNORE + SANDBOX cleanup …' EXIT`

Each redefinition replaces the prior trap entirely (bash trap
semantics). If `mktemp -t pack-contract-mid-dev-pre.XXXXXX` (line 82)
fails AFTER the SANDBOX is created but BEFORE the second trap is set
on line 83, the script aborts (because `set -u` is in effect and the
`PRE_SNAPSHOT="…"` assignment would leave `$PRE_SNAPSHOT` unset on
expansion in the OLD trap body). However the OLD trap body uses
`${SANDBOX:-}` and only references `$SANDBOX`, so SANDBOX cleanup
would still fire. Net effect: no leak.

Similarly for line 101's redefinition: if `cp "$SANDBOX/.gitignore"
"$PRE_GITIGNORE"` fails between lines 99 and 101, the second trap
(line 83) is still in effect and PRE_SNAPSHOT cleanup fires. Net
effect: no leak.

So the construction is technically correct, but reads as fragile and
error-prone. A single trap function defined once, reading current
state of the variables at trap-fire time, is clearer:

```bash
_cleanup() {
    [[ -n "${PRE_SNAPSHOT:-}" && -f "$PRE_SNAPSHOT" ]] && rm -f "$PRE_SNAPSHOT"
    [[ -n "${PRE_GITIGNORE:-}" && -f "$PRE_GITIGNORE" ]] && rm -f "$PRE_GITIGNORE"
    [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"
}
trap _cleanup EXIT
```

Set the function trap once, then create resources. The function reads
current values at trap-fire time, so partial creation is handled
naturally.

**Suggested fix.** Refactor mid-dev contract to use a single named
cleanup function (snippet above). Apply same pattern to migration
contract (which has only one trap so is already clean) and greenfield
(also single-trap). Mid-dev is the only file with the chained-redef
pattern.

**Cross-concept impact:** None. Contract-internal change. Pattern
already followed in greenfield + migration; mid-dev is the outlier.

**Rule violated:** Design best practice principle — single source of
truth (CONCEPTUAL-REVIEW-METHODOLOGY.md §"Design best practices" #1)
applied to trap handlers.

---

### Finding 5 — F5 (NIT)

**Severity:** NIT
**Dimension:** (d) Pack rule adherence
**Touch-point class:** OWNED
**Evidence:** `scripts/persona-contracts/contract-greenfield.sh` and
`contract-mid-dev.sh` and `contract-migration.sh` — none has a header
`# pack-internal: true` marker.

**Description:** `validate-pack.py` Check 23 (lines 1673-1717) only
iterates the TOP-LEVEL `scripts/` directory, so the three contract
scripts under `scripts/persona-contracts/` are not scanned today.
However, the BD-082 convention codified by Check 23 is that every
internal script (one not exposed in `HELP-FRAGMENT-PACK.md`) carries
a `# pack-internal: true` marker as a self-documenting flag.
`scripts/test-persona-contracts.sh` (the wrapper at the top level)
correctly carries the marker.

The three contract scripts are conceptually pack-internal (CI test
runners) but lack the marker. If a future Check 23 extension
recursively scans `scripts/` subdirs (a plausible BD-082 hardening),
they'd fail validation.

**Suggested fix.** Add `# pack-internal: true  (CI persona contract; not a user-facing verb)`
as the second line of each contract script (after the shebang),
mirroring the existing marker on
`scripts/test-persona-contracts.sh:2`.

**Cross-concept impact:** Could affect a future BD-082 hardening
(would prevent regression).

**Rule violated:** Pack convention from `scripts/validate-pack.py`
Check 23 docstring + BD-082 — the `pack-internal: true` marker is the
self-documentation standard for internal scripts.

---

### Finding 6 — F6 (NIT)

**Severity:** NIT
**Dimension:** (e) Design best practice adherence
**Touch-point class:** OWNED
**Evidence:** `scripts/persona-contracts/contract-greenfield.sh:74-75`
relies on glob expansion of an array literal to enumerate skills.

**Description:** Lines 74-75:
```bash
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
expected_skill_count=0
for d in "${skill_dirs[@]}"; do
    [[ -d "$d" ]] || continue
```

If `project-template/skills/` is empty (no skill subdirs), the glob
expands to the literal string `…/project-template/skills/*/` (bash
default behavior with `nullglob` unset). The `[[ -d "$d" ]]` guard
filters out the literal, but the loop also computes `expected_skill_count`
as zero — and then the per-CLI count-sanity check (lines 98-117) would
compare against 0 + per-CLI extras count. If `project-template/skills/`
is empty AND the per-CLI extras dir has skills, the count check would
still work. If both are empty, the contract passes vacuously (zero
checks for skills). This is a latent edge case unlikely to fire in
practice (the pack always ships skills) but worth noting.

The same pattern at lines 103-110 (CLI extras enumeration) is
similarly affected: if `cli_extras_dir` exists but is empty, the loop
runs once with the literal `*/`, the `[[ -d "$extra" ]]` check fails,
loop continues. Net: no count contribution — correct.

**Suggested fix.** Add `shopt -s nullglob` near the top of each
contract script that uses array-glob expansion, OR use an explicit
`find` for enumeration. The `nullglob` form is canonical for
modern bash test scripts:

```bash
shopt -s nullglob
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
shopt -u nullglob
```

Or a one-liner alternative:
```bash
mapfile -t skill_dirs < <(find "$PACK_ROOT/project-template/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
```

**Cross-concept impact:** None.

**Rule violated:** Pack memory `feedback_test_infra_self_provisioned.md`
spirit (test infra should be deterministic and not silently degrade in
edge cases). Methodology dimension (e) — robustness as a design best
practice.

---

### Finding 7 — F7 (NIT)

**Severity:** NIT
**Dimension:** (b) Edge cases
**Touch-point class:** OWNED
**Evidence:** `scripts/persona-contracts/contract-greenfield.sh` lacks
a `.gitignore` assertion.

**Description:** `init-project.sh:stage_s8_gitignore()` (lines
613-642) installs the pack's `.gitignore` from
`project-template/.gitignore` (cp directly when the target has no
`.gitignore`; append-and-dedup otherwise). For the greenfield case
the sandbox is initialized via `_fixture_git_init` (no `.gitignore`),
so init-project does a plain `cp`. The greenfield contract does NOT
verify `.gitignore` exists post-install, even though it's a documented
S8 output.

Symmetric to F3 (S6 docs) — the init-project internal `fail_stage`
catches catastrophic failure, but the contract self-documentation is
incomplete.

**Suggested fix.** Add a one-line assertion:
```bash
if [[ -f "$SANDBOX/.gitignore" ]]; then
    t_pass "S8 .gitignore installed"
else
    t_fail "S8 .gitignore MISSING"
fi
```

**Cross-concept impact:** None.

**Rule violated:** Methodology dimension (a) — completeness
self-documentation.

---

## 4. Coverage notes

**In scope but not deeply reviewed:**

- `test-fixtures/build.sh` `_materialize_for_contract` helper: read
  in full (lines 780-819); construction is correct (mktemp + git init
  for greenfield; cp -R + git config repin for mid-dev / migration).
  No findings.
- `scripts/test-persona-contracts.sh` aggregator: read in full; the
  `if: always()` parallel pattern + per-contract result tracking +
  PASS/FAIL summary is sound. No findings.
- README.md Repository Layout entries (lines 214-218): correctly
  reflect the four shipped scripts. No findings.
- `.github/workflows/validate-pack.yml` BD-116 step (current line 173-175):
  ordering is now correct after BD-118/BD-163 reorder (persona contracts
  run after `build test fixtures` and `fixture manifest verify`,
  before `template-translations tests`). No findings — this surface
  was reviewed and reordered post-BD-116 by BD-118 + BD-163.

**Out of scope (explicit):**

- BD-115 fixture content (separate retro review).
- BD-118 CI wiring details (separate retro review).
- BD-120 `_build_realistic_for_version` builder (separate retro review).
- BD-088 customization-preserve library (the contract consumes; not
  the consumer's responsibility to re-review the producer).
- BD-080 stage S11 implementation (the contract consumes the
  enumeration; finding F1 is about the contract's mirror, not the
  source).
- BD-161 follow-on (POQ-BD-116-1) — explicit out-of-scope per BACKLOG
  triage.

**Acceptance criteria check (per BACKLOG BD-116 lines 1131-1158):**

| Criterion | Status | Note |
|---|---|---|
| 3 contracts under `scripts/persona-contracts/` | PASS | greenfield + mid-dev + migration shipped |
| greenfield: init on empty dir matches template | PASS (with F1 + F3 + F7 NITs) | partial S6/S8/S11 enumeration |
| mid-dev: init on BD-115 fixture preserves users files + lands pack | PASS | spec deviation `--update`→default flow documented (POQ-BD-116-2) |
| migration: synthetic OT through migrator → expected v11 + customizations preserved | PASS (with F2 NIT) | unreachable fallback at 3c |
| derived from project-template/ + BD-088 invariants (no hand-written file lists) | PARTIAL | F1 is precisely a hand-written list; partial-mirror was the cause |

---

## 5. Re-architect summary

**No ARCH findings.** All findings are SHOULD or NIT. None require
re-architecture across multiple concepts. Touch-point classifications
are all OWNED (contract scripts) — no CONTRACT touch points were
modified by BD-116.

The greenfield/migration S11 enumeration asymmetry (F1) is a real
cross-contract consistency gap but the fix is local to one script;
no architecture revisit needed.

---

## 6. Methodology friction notes

The calling prompt was complete and well-structured:

- The original commit SHA + the `git show 72789fc -- <file>` recipe
  were directly actionable.
- The `Reference docs` list correctly excluded the prior PACK-REVIEW
  to prevent bias.
- "Six dimensions a-f" + "touch-point classification" anchors mapped
  cleanly onto the methodology doc.
- "Clean review (zero findings) is acceptable" framing was helpful
  and avoided the "must-find-something" anti-pattern.

Minor friction:

- The reference to `maintenance-docs/v11-implementation/IMPLEMENTATION-PLAN-V11.0.md`
  in the prompt does not exist in the repo; the actual file is
  `EXECUTION-PLAN-V11.0.md`. Found via `find`. Recommend the prompt
  template for retroactive reviews use the actual filename.
- The prompt says "ARCHITECTURE-V3.md and any V3.x deltas/addendums
  referenced from the BACKLOG entry" — BD-116's BACKLOG entry has no
  V3.x references, so this section was vacuous. Recommend retroactive
  review prompts only list architecture refs that the BD's BACKLOG
  entry actually cites.

Findings are surfaced as MUST/SHOULD/NIT/ARCH per methodology;
empirical evidence + file:line references provided per finding.

---

## 7. Final verdict

**APPROVE WITH NITS.** Two SHOULD findings (F1, F2) and five NIT
findings (F3-F7). No MUST or ARCH. The shipped surface is functional
and meets BD-116's stated acceptance criteria; the findings are
quality and completeness improvements that would strengthen the
contracts' self-documentation and edge-case coverage.

The original end-of-batch review's NIT N1 ("contracts should
cross-reference the S11 source") was correctly flagged but
under-scoped — the cross-reference comment was added without bringing
the array to parity. F1 is the per-BD review catching what the
end-of-batch review's NIT N1 fix didn't fully resolve. This validates
the Batch 21c retroactive-per-BD-review hypothesis.

**Six dimensions exercised.** (a) Completeness — F1, F3, F7. (b) Edge
cases — F2. (c) Touch points — surveyed (no findings; all touch
points are OWNED, no CONTRACT changes). (d) Pack rule adherence — F5.
(e) Design best practice — F4, F6. (f) Concept-specific — surveyed
(no concept-specific invariants beyond what's in (a)-(e)).
