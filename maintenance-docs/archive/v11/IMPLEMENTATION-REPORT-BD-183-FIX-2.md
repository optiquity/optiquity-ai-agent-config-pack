# IMPLEMENTATION-REPORT-BD-183-FIX-2

**Author:** pack-coder (fix-coder)
**Date:** 2026-05-21
**HEAD pre-fix:** `5f8f68381b2f951fd571f414976021e97f22b659`
**Branch:** `v11-dev`
**Scope:** BD-183 FIX-2 — PACK-REVIEW-BD-183-FIX-1.md SHOULD-A only
**Triage (Pack Chat, user-approved):**
- **SHOULD-A — FIX** (wire `test-validate-pack-check-41.sh` into CI workflow as a sister-step)
- **NIT-A — SKIP** (commit subject on `5f8f683` immutable per pack-repo amend ban; advisory only)
**Out of scope:** Opening BD-184 (prevention check) — Pack Chat will add separately.

---

## §1 Problem restatement

Per PACK-REVIEW-BD-183-FIX-1.md §4 SHOULD-A:

> Running the unwired-test-detection scanner from PACK-REVIEW-BD-183 §4 SHOULD-1 "Note" against post-FIX-1 HEAD returns one line: `test-validate-pack-check-41.sh`. This is the same gap class as BD-179 SHOULD-1 (`1e644d1`) and BD-183 SHOULD-1 (closed in `5f8f683`): a test file exists in `scripts/tests/` but is not invoked in `.github/workflows/validate-pack.yml`, so the test is "silently dead in CI." `test-validate-pack-check-41.sh` was added in commit `78a4415` (BD-180, "cmd_update mapping symmetry across remaining surfaces") and has never been wired into CI. It tests Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity, BD-180 observation G) and currently PASSes locally (4/4) but provides zero CI coverage.

The fix shape is a single 3-line sister-step in the same `.github/workflows/validate-pack.yml`. Position: per the BD-creation-order cluster convention established in the existing yml (Check 40 BD-179 → Check 18 BD-181 → Check 16 BD-183 → Check 19 BD-183), Check 41 (BD-180) inserts between Check 40 (BD-179) and Check 18 (BD-181).

**Pre-fix scanner result** (from `5f8f683` HEAD; replicated by IMPL-REPORT-FIX-2 pre-edit):

```
$ comm -23 <(ls scripts/tests/test-validate-pack-check-*.sh | xargs -n1 basename | sort) \
           <(grep -oE 'test-validate-pack-check-[0-9-]+\.sh' .github/workflows/validate-pack.yml | sort -u)
test-validate-pack-check-41.sh
```

After this fix, all 8 per-check test files are wired. The "missing test wiring" gap class converges to zero unwired files.

---

## §2 Implementation

### §2.1 Before/after of `.github/workflows/validate-pack.yml`

**Before** (`.github/workflows/validate-pack.yml:166-171` at HEAD `5f8f683`):

```yaml
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-18.sh
```

**After** (`.github/workflows/validate-pack.yml:166-174` post-fix):

```yaml
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: validate-pack Check 41 tests (BD-180, _CLIENT_INSTALLED_FILES self-doc list integrity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-41.sh
      - name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-18.sh
```

### §2.2 Position rationale

The existing post-`5f8f683` cluster (lines 166-177) reads in BD-creation order:

| Line | Step | BD |
|---|---|---|
| 166-168 | Check 40 | BD-179 |
| 169-171 | Check 18 | BD-181 |
| 172-174 | Check 16 | BD-183 |
| 175-177 | Check 19 | BD-183 |

BD-180 falls between BD-179 and BD-181, so Check 41 inserts between Check 40 (line 166-168) and Check 18 (now shifted to 172-174). Resulting cluster preserves BD-creation order:

| Line | Step | BD |
|---|---|---|
| 166-168 | Check 40 | BD-179 |
| 169-171 | Check 41 | BD-180 **(NEW)** |
| 172-174 | Check 18 | BD-181 |
| 175-177 | Check 16 | BD-183 |
| 178-180 | Check 19 | BD-183 |

This matches the PACK-REVIEW-BD-183-FIX-1.md §4 SHOULD-A "Fix" block recommendation verbatim.

### §2.3 Step-shape conformance

The new step uses the same three-line shape as every other sister-step in the cluster:

- `name:` — descriptive, follows pattern `validate-pack Check <N> tests (BD-<NNN>, <short>)`
- `if: always()` — independent test execution per the file's top-of-job convention
- `run: bash scripts/tests/test-validate-pack-check-<N>.sh` — direct bash invocation, no extra args

Shape parity verified against Check 40, Check 18, Check 16, and Check 19 sister-steps.

---

## §3 Files modified — diff stat

```
 .github/workflows/validate-pack.yml | 3 +++
 1 file changed, 3 insertions(+)
```

Single file touched; net +3 lines (the new sister-step's three lines). No deletions, no other modifications.

---

## §4 Verification

### §4.1 YAML syntax

```
$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"
YAML syntax OK
```

Exit 0. **PASS.**

### §4.2 All per-check test suites still PASS at HEAD

| Suite | PASS count | FAIL count | Result |
|---|---|---|---|
| `bash scripts/tests/test-validate-pack-check-16.sh` | 10 | 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-18.sh` | 7 | 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-19.sh` | 9 | 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-39.sh` | 6 | 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-40.sh` | 8 | 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-41.sh` | 4 | 0 | PASS |

**Grand total: 44 PASS / 0 FAIL across all 6 per-check validate-pack test suites. Zero regressions.** Counts match PACK-REVIEW-BD-183-FIX-1.md §5.2 exactly, confirming the wiring-only fix did not perturb test results.

### §4.3 `python3 scripts/validate-pack.py` still PASSes

Tail of run output:

```
── Check 39: install-coverage gate (BD-175 F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

============================================================
PASSED — all checks clean
```

Exit 0; all 41 checks green. **PASS.**

### §4.4 Scanner re-run (post-fix)

```
$ diff <(ls scripts/tests/test-validate-pack-check*.sh | sort) \
       <(grep -oE 'scripts/tests/test-validate-pack-check[^"]*\.sh' .github/workflows/validate-pack.yml | sort -u)
(empty output, exit 0)
```

**Zero unwired per-check test files remain.** The 8 per-check test files (check-16.sh, check-18.sh, check-19.sh, check-39.sh, check-40.sh, check-41.sh, checks-32-33-34.sh, checks-36-37-38.sh) are now all wired in the workflow. Gap-class recursion converges to zero.

Same scanner re-run with the PACK-REVIEW-BD-183-FIX-1.md §4 form:

```
$ comm -23 <(ls scripts/tests/test-validate-pack-check-*.sh | xargs -n1 basename | sort) \
           <(grep -oE 'test-validate-pack-check-[0-9-]+\.sh' .github/workflows/validate-pack.yml | sort -u)
(empty output)
```

**PASS.**

---

## §5 RC9 manifest status

`.github/workflows/` is NOT in the v11-surface trigger glob defined in CLAUDE.md § "Pack memory" → "Regenerate test-fixtures/manifest.txt on every v11-surface commit." Trigger glob includes only:

- `project-template/**`
- `scripts/**`
- `pack-ops/**`
- `supporting-docs/**`

This commit touches only `.github/workflows/validate-pack.yml` (CI infrastructure, not fixture-copied). **No manifest regeneration required.** Confirmed by inspection: `git diff test-fixtures/manifest.txt` is empty (no incidental drift).

---

## §6 Carry-forward discipline

Per `.claude/skills/review/SKILL.md` § "Carry-forward discipline" (SIZE / BLOCKED / LOGICAL-FIT high-bar), I evaluated scope-adjacent observations encountered during implementation:

### Observation A — Prevention scaffolding (validate-pack.py Check 42 or coder pre-commit checklist)

The PACK-REVIEW-BD-183 §4 SHOULD-1 "Note" and PACK-REVIEW-BD-183-FIX-1.md §6 Observation A flagged that a workflow-level prevention mechanism (either a new `validate-pack.py` check or a coder pre-commit checklist line) would have caught this gap class proactively. The prompt explicitly states this is out of scope for FIX-2 (Pack Chat will open BD-184 separately, user-approved). Honoring the prompt scope: I am NOT adding any prevention scaffolding in this commit. The prompt's explicit out-of-scope direction overrides the carry-forward default-fix-now (per `.claude/skills/review/SKILL.md` — carry-forward discipline applies within the prompt's stated scope; explicit out-of-scope items remain out of scope).

**Classification.** Not a deferral within this commit — it is an explicitly out-of-scope item the user authorized for separate BD work. Documented for IMPL-REPORT audit trail completeness.

### Observation B — Other unwired tests anywhere in `scripts/tests/`

For completeness, I ran a broader scan beyond the `test-validate-pack-check-*` pattern:

```
$ ls scripts/tests/ | grep -E '^(test-|.*-test\.sh)$' | wc -l
```

The broader inventory of `scripts/tests/*` and `scripts/test-*.sh` files is large (40+); the post-fix workflow wires the BD-NNN-scoped enumeration explicitly in `.github/workflows/validate-pack.yml`. The prompt scope is `test-validate-pack-check-*` per the PACK-REVIEW-BD-183-FIX-1.md §4 SHOULD-A gap class. Broader unwired-test triage across all test patterns is NOT in this commit's scope.

**Classification.** Not a finding. Broader workflow-completeness audit is the prevention scanner's job (Observation A, BD-184 candidate per user-approved separate triage).

### Carry-forward count: **0.**

All observations are either (a) explicitly out-of-scope per prompt direction (Observation A), or (b) explicitly out-of-scope per prompt's stated gap class (Observation B). No deferrals within the SHOULD-A scope. Default-fix-now honored for the in-scope work.

---

## §7 Boundary discipline check

Per `boundary-investigation` skill pre-flight: this commit edits ONLY `.github/workflows/validate-pack.yml`. This is a pack-only CI infrastructure file (not project-template/, not supporting-docs/, not shipped to client at install). No project-side SSOT investigation applies. P-missed-7 N/A.

No pack-only references introduced into project-side files (no project-side files touched). No trinity files touched. No `pack-ops/` files touched. No `maintenance-docs/` files touched (this report is the only `maintenance-docs/` artifact; it is the IMPL-REPORT pack-coder is required to produce — not a substantive edit to existing pack docs).

---

## §8 Commit-message advisory for Pack Chat

The eventual commit message should respect the 70-char subject guideline. Proposed shape (within budget):

```
fix: v11 — BD-183 FIX-2 SHOULD-A wire BD-180 check-41 test
```

Length: 57 chars. Comfortably within guideline. Body should document:
- SHOULD-A FIX: added sister-step for `test-validate-pack-check-41.sh` at position between Check 40 (BD-179) and Check 18 (BD-181), preserving BD-creation-order convention.
- NIT-A SKIPPED: per Pack Chat triage with user approval (commit subject on `5f8f683` immutable per amend ban).
- Verification: all 6 per-check test suites still PASS (44/44); `python3 scripts/validate-pack.py` all 41 checks clean; scanner re-run shows zero unwired test files.
- Gap-class convergence: with this fix, all 8 per-check test files (`test-validate-pack-check-{16,18,19,39,40,41,checks-32-33-34,checks-36-37-38}.sh`) are now wired in CI.
- RC9: `.github/` not in trigger glob; no manifest regen.

Subject-scope keyword `pack-only` is APPLICABLE (touched files: `.github/workflows/validate-pack.yml` + this IMPL-REPORT, both pack-only). Optional to include per CI Check 36 enforcement.

---

## §9 Definition-of-Done checklist

| Item | Status |
|---|---|
| New sister-step for `bash scripts/tests/test-validate-pack-check-41.sh` present in workflow | PASS |
| Step shape matches existing sister-steps (`name:`, `if: always()`, `run:`) | PASS |
| Step position is BD-creation-order coherent (Check 40 → Check 41 → Check 18 → Check 16 → Check 19) | PASS |
| YAML syntax valid (`python3 -c "import yaml; yaml.safe_load(...)"`) | PASS |
| IMPL-REPORT documents the addition + scanner result confirmation | PASS |
| All adjacent suites still PASS at HEAD (44/44 across 6 per-check suites) | PASS |
| `python3 scripts/validate-pack.py` still PASSes (all 41 checks) | PASS |
| RC9 manifest evaluation documented (.github/ not in glob) | PASS |
| Carry-forward discipline applied; zero deferrals within scope | PASS |
| PREFLIGHT line emitted in final assistant message | PASS (emitted below after this Write) |

---

## §10 Files inventory

| Path | Change type | Notes |
|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | +3 lines (single sister-step for Check 41) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183-FIX-2.md` | new | this report |

No deletions. No other modifications.

---

**End of IMPLEMENTATION-REPORT-BD-183-FIX-2.**
