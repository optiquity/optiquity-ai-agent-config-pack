# IMPLEMENTATION-REPORT-BD-179-FIX-1.md

**BD:** BD-179
**Phase:** FIX-1 (BD-175 EMERGENCY BATCH parallel-fix wave)
**Scope:** PACK-REVIEW-BD-179.md §3.1 SHOULD-1 expanded to absorb §5 CF-1 (batch-wide carry-forward observation #1)
**Pre-fix HEAD:** `13feef31ab0aa2e8cd9a25f21fe6a81f70f5acea`
**Post-fix HEAD:** unchanged (working-tree edit only; commit performed by Pack Chat)
**Coder:** pack-coder
**Date:** 2026-05-20

---

## 1. Problem restatement

Per PACK-REVIEW-BD-179.md §3.1 (SHOULD-1) and §5 carry-forward observation
#1 (CF-1), three test-script harnesses landed under `scripts/tests/` over
the BD-175 EMERGENCY BATCH but were NOT invoked by CI in
`.github/workflows/validate-pack.yml`:

1. `scripts/tests/test-validate-pack-checks-36-37-38.sh` — added by
   BD-175 Commit 12 (2026-05-19), Checks 36/37/38 pack/project boundary
   surface.
2. `scripts/tests/test-validate-pack-check-39.sh` — added by BD-175
   F2a (2026-05-19), Check 39 install-coverage gate.
3. `scripts/tests/test-validate-pack-check-40.sh` — added by BD-179
   commit `13feef3` (2026-05-20), Check 40 pack-ops/ bare-cross-
   reference scanner; 8 test groups, all PASS locally.

**Architect-doc-as-authority breach.** `ARCHITECTURE-BD-179.md` §8.3
step 6 + §10.1 file-list explicitly mandate
`.github/workflows/validate-pack.yml` as an EDIT row with the disposition
*"add a new step that invokes `bash scripts/tests/test-validate-pack-
check-40.sh` … per the Check 39 CI-wiring pattern."* Empirically the
BD-179 commit modified 16 files; the workflow was NOT among them. The
review's CF-1 observation (§5) generalized the gap: the architect's
reference to "the Check 39 CI-wiring pattern" was itself empirically
wrong — Check 39 had no CI wiring either, and neither did Checks 36-38.
Three CI wirings were silently absent.

**Consequence at HEAD `13feef3`.** The 8-group Check 40 test harness
(plus the Check 36/37/38 and Check 39 harnesses) was dead-in-CI:
only the in-process `check_bare_pack_ops_refs()` (invoked indirectly
via `python3 scripts/validate-pack.py`) ran on push, exercising the
end-to-end PASS path but NOT the unit-level coverage of the regex
patterns, `_strip_code_blocks` helper, `_check_40_context_has_anchor`
anchor-phrase logic, `_build_basename_index` candidate-path builder,
or any of the explicit FAIL fixtures.

Pack Chat's FIX-1 triage (per `feedback-fix-all-review-findings`
default-FIX-ALL + `feedback-deferral-is-scope-creep`) chose option (a)
of the SHOULD-1 suggested-fix: wire all 3 missing CI steps in a single
batch-close fix commit attached to BD-179.

---

## 2. Files modified

| File | Action | Line delta | Purpose |
|---|---|---|---|
| `.github/workflows/validate-pack.yml` | EDIT | +9 / −0 | Add 3 new per-script steps for `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-39.sh`, `test-validate-pack-check-40.sh`, following the existing per-script step pattern at sibling Check 32/33/34 |

**Diff stat (working tree vs HEAD `13feef3`):**

```
 .github/workflows/validate-pack.yml | 9 +++++++++
 1 file changed, 9 insertions(+)
```

No other files modified. Scope is strict per the prompt.

---

## 3. Verification

### 3.1 YAML syntax — PASS

```sh
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"
# (no output; parse OK)
```

Result: `YAML PARSE: OK`; `tests` job now contains 47 steps (was 44;
delta +3 matches the 3 added invocations).

### 3.2 All 3 test scripts have CI invocation rows — PASS

`grep -n "test-validate-pack" .github/workflows/validate-pack.yml`
returns 4 hits in correct adjacent order:

```
159:        run: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
162:        run: bash scripts/tests/test-validate-pack-checks-36-37-38.sh
165:        run: bash scripts/tests/test-validate-pack-check-39.sh
168:        run: bash scripts/tests/test-validate-pack-check-40.sh
```

### 3.3 The 3 added steps in context

```yaml
      - name: validate-pack Check 32/33/34 tests (BD-168, per-entry split validators)
        if: always()
        run: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
      - name: validate-pack Check 36/37/38 tests (BD-175 Commit 12, pack/project boundary)
        if: always()
        run: bash scripts/tests/test-validate-pack-checks-36-37-38.sh
      - name: validate-pack Check 39 tests (BD-175 F2a, install-coverage gate)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-39.sh
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: tracker BD-129 gh-repo routing tests (BD-129)
        ...
```

### 3.4 Pattern match against existing invocations

The 3 added steps preserve the surrounding pattern exactly:

| Pattern element | Existing template (Check 32/33/34) | New steps |
|---|---|---|
| Step shape | `- name:` / `if: always()` / `run: bash <path>` | Identical |
| `name` format | `<group> tests (BD-NNN, <short context>)` | Identical |
| `if: always()` | Present (per workflow convention — every test step runs to surface all failures) | Present |
| `run` form | `bash scripts/tests/<script>.sh` (no env vars, no working-directory override, no conditional) | Identical |
| Placement | After `recommendation-state-schema tests (BD-079, validate-pack Check 30)`, before `tracker BD-129 gh-repo routing tests (BD-129)` | Inserted as a contiguous group of 3 directly after the Check 32/33/34 step (sister `test-validate-pack-check*` family stays adjacent) |

No env vars, no working-directory override, no conditional logic, no
label changes — this is a literal copy of the surrounding pattern with
the script name + name string substituted. No reinvention.

### 3.5 No other files modified — PASS

`git status --short` shows the workflow as the only new modification
introduced by this FIX-1 (all other dirty paths were already dirty
before FIX-1 started, per the parallel-fix-wave context).

---

## 4. RC9 manifest status

**RC9 trigger:** NOT FIRED.

Per pack-root `CLAUDE.md` § "Repo conventions" → "Regenerate
test-fixtures/manifest.txt on every v11-surface commit", the v11-surface
trigger fires when a commit's diff includes a file under
`project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`.

This FIX-1 modifies ONLY `.github/workflows/validate-pack.yml`. That
file lives under `.github/workflows/` — outside all four v11-surface
trigger directories. RC9 does NOT fire; no manifest regen needed.

No `test-fixtures/manifest.txt` edit is part of FIX-1.

---

## 5. Boundary discipline check

No project-side files modified. The single edit (`.github/workflows/
validate-pack.yml`) is a pack-only CI surface (lives at pack-repo root
under `.github/`; not under `project-template/` or `supporting-docs/`,
not copied to client repos by `scripts/init-project.sh` at any stage).
P-missed-7 SSOT-investigation pre-flight does not apply — there is no
project-side analog of the pack-repo CI workflow.

---

## 6. Definition-of-Done checklist

| Item | Status |
|---|---|
| All 3 test scripts have an invocation step in the workflow | PASS (§3.2) |
| Invocation pattern matches existing per-script steps | PASS (§3.4) |
| Workflow YAML is syntactically valid (`yaml.safe_load`) | PASS (§3.1) |
| IMPL-REPORT documents what was added + why + matches the pattern | PASS (this report §1–§4) |
| Scope strict — only `.github/workflows/validate-pack.yml` modified | PASS (§3.5) |
| No state-changing git verbs run by coder | PASS (read-only `git status` / `git rev-parse` only) |
| RC9 manifest-regen check considered | PASS (§4 — trigger not fired) |
| Boundary discipline check considered | PASS (§5 — no project-side files) |
| PREFLIGHT line emitted after IMPL-REPORT Write | See final assistant message |

---

## 7. Plan deviations

None. Pack Chat's prompt scoped the fix to "wire all 3 test scripts
into the existing CI workflow file"; the implementation does exactly
that, with no surface expansion and no judgment calls beyond placement
(chose adjacency to the Check 32/33/34 sister-step, the natural
grouping per `test-validate-pack-check*` filename family).

---

## 8. New POQs introduced

None. The architect-doc-vs-reality reconciliation noted in
PACK-REVIEW-BD-179.md §3.1 ("Either resolution should ALSO update the
architect doc §8.3 step 6 to reflect the chosen disposition for
future readers") is a separate documentation-debt item that the
review explicitly suggested but is OUT of FIX-1 scope (the prompt
constrains modification to ONLY `.github/workflows/validate-pack.yml`).
Pack Chat may surface the architect-doc-addendum as a separate small
fix or roll it into the end-of-batch review per its triage judgment;
this coder did not modify the architect doc per scope discipline.

---

## 9. Files-changed inventory

| Path | Change type |
|---|---|
| `.github/workflows/validate-pack.yml` | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-1.md` | new (this report) |

---

**End of IMPLEMENTATION-REPORT-BD-179-FIX-1.md.**
