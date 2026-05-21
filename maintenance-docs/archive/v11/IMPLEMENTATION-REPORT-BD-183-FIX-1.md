# IMPLEMENTATION-REPORT-BD-183-FIX-1 — BD-183 review-fix bundle (SHOULD-1 + NIT-2 + NIT-3)

**Author:** pack-coder (BD-175 emergency-batch fix-coder, 10th coder in chain)
**Date:** 2026-05-21
**Bundled scope:** PACK-REVIEW-BD-183 SHOULD-1 + NIT-2 + NIT-3 (NIT-1 SKIPPED per Pack Chat triage — commit subject immutable)
**Pre-fix HEAD:** `aeacbdc09dcf22f360efbd6c76668859c56b772c`
**Branch:** `v11-dev`
**Triage approved by user:** 2026-05-21 (FIX SHOULD-1, SKIP NIT-1, FIX NIT-2, FIX NIT-3; file-disjoint → single fix-coder)

---

## §1 Problem restatement (from PACK-REVIEW-BD-183)

**SHOULD-1 — `test-validate-pack-check-18.sh` not wired to CI.** BD-181's sibling test `scripts/tests/test-validate-pack-check-18.sh` (7 PASS assertions, present in tree since commit `c244314`, 2026-05-20) is NOT invoked in `.github/workflows/validate-pack.yml`. Same gap class BD-179 SHOULD-1 (commit `1e644d1`) already established as fix-now precedent ("test file silently dead in CI"). PACK-REVIEW-BD-183 §4 SHOULD-1 surfaced this as fix-now because the gap-class precedent forbids deferral: `.github/workflows/validate-pack.yml` was already being touched by the BD-183 commit (adjacent lines :169-174), and the fix shape is a single sister-step addition matching the existing convention.

**NIT-2 — IMPL-REPORT §10 Observation 4 framing.** `IMPLEMENTATION-REPORT-BD-183.md` §10 Observation 4 stated that if the IMPL-REPORT is moved or renamed (e.g., post-v11.0 archive sweep per Pattern B), in-code "BD-183 §2.4" references "would become stale." PACK-REVIEW-BD-183 §4 NIT-2 surfaced this as imprecise: section-number citations of the form `per BD-183 §2.4` remain VALID across file moves as long as the destination preserves the report's §X.Y addressability; only doc-RESTRUCTURE invalidates them. The framing should reflect "moved-not-stale."

**NIT-3 — Override 9 test asymmetry.** `scripts/tests/test-validate-pack-check-16.sh` Group 3 (Override 9) only asserted leak-prevention (one direction: "A does not leak B label, B does not leak A label"). `scripts/tests/test-validate-pack-check-19.sh` Group 3 additionally asserts label-presence-in-both-directions ("A carries its own label; B carries its own label"). PACK-REVIEW-BD-183 §4 NIT-3 surfaced the asymmetry as cosmetic test-completeness polish: Group 3 should be parity between the two test files.

---

## §2 Implementation

### §2.1 SHOULD-1 — `.github/workflows/validate-pack.yml` sister-step addition

**Position chosen.** The existing cluster (around `validate-pack.yml::tests`) reads:

- Check 36/37/38 (BD-175 Commit 12)
- Check 39 (BD-175 F2a)
- Check 40 (BD-179)
- Check 16 (BD-183)
- Check 19 (BD-183)

The empirical step-ordering convention in this cluster is **BD-creation order** (36/37/38 → 39 → 40 → 16 → 19), NOT numerical check# order — Check 16 and Check 19 follow Check 40 because BD-183 is newer than BD-179, even though Check 16/19 are numerically smaller. Therefore Check 18 (BD-181, between BD-179 and BD-183 chronologically) belongs **between Check 40 and Check 16** to preserve the BD-order convention.

**Before** (`.github/workflows/validate-pack.yml`, in the `tests:` job step sequence):

```yaml
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: validate-pack Check 16 tests (BD-183, trinity ## Project addenda H2 + Option (b) exemption)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-16.sh
      - name: validate-pack Check 19 tests (BD-183, trinity templates free of body scaffolding)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-19.sh
```

**After:**

```yaml
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-18.sh
      - name: validate-pack Check 16 tests (BD-183, trinity ## Project addenda H2 + Option (b) exemption)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-16.sh
      - name: validate-pack Check 19 tests (BD-183, trinity templates free of body scaffolding)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-19.sh
```

**Shape conformance.** The new step matches the existing sister-step shape exactly: 3-line block (`name:` with check# + BD# + short description; `if: always()`; `run: bash <path>`). The `name:` follows the established phrasing pattern (`validate-pack Check N tests (BD-NNN, <one-line summary>)`).

### §2.2 NIT-2 — IMPL-REPORT §10 Observation 4 wording tightening

**Before** (`IMPLEMENTATION-REPORT-BD-183.md` §10 Observation 4, 4 bullets):

```
**Observation 4: Inline source-code cross-references to this IMPL-REPORT.**
- Multiple source-code citations of "BD-183 §2.4" (in the `_CHECK_16_EXEMPT_SURFACES` comment block; in the exempt-OK message text; in the `check_trinity_addenda_h2` docstring; in the `main()` inline comment for Check 16). These are content references, not line numbers — they cite section numbers within a named report.
- Future maintenance risk: if this IMPL-REPORT is moved or renamed (e.g., post-v11.0 archive sweep per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` § Pattern B), the in-code references would become stale. Per "Architect-doc-vs-reality reconciliation" pattern, this is acceptable risk: comments should reference symbols + named sections (not line numbers); the report is findable by name via the standard `maintenance-docs/` archive layout.
- The exempt-OK message itself ("per BD-183 §2.4") is part of `check_trinity_addenda_h2` USER-VISIBLE OUTPUT (printed to CI logs every run). This citation is doubly useful: it's both an in-code design record AND a CI-log diagnostic pointer that anyone debugging a Check 16 exemption can grep for and immediately find this report.
- **Carry-forward outcome:** None. Standard practice for IMPL-REPORT cross-references; the user-visible CI-log pointer is a benefit, not a risk.
```

**After:**

```
**Observation 4: Inline source-code cross-references to this IMPL-REPORT.**
- Multiple source-code citations of "BD-183 §2.4" (in the `_CHECK_16_EXEMPT_SURFACES` comment block; in the exempt-OK message text; in the `check_trinity_addenda_h2` docstring; in the `main()` inline comment for Check 16). These are content references, not line numbers — they cite section numbers within a named report.
- Robustness profile: section-number citations of the form "per BD-183 §2.4" remain VALID as long as the referenced report preserves its §X.Y addressability — that is, the section heading stays at the same number. File MOVES (e.g., post-v11.0 archive sweep per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` § Pattern B, which would relocate this report to `maintenance-docs/archive/v11/`) do NOT invalidate these citations: the report is findable by BD-number + name regardless of path, and §2.4 still resolves to the same content within. Only a doc-RESTRUCTURE that renumbers or removes §2.4 would invalidate them. Per "Architect-doc-vs-reality reconciliation" pattern: comments should reference symbols + named sections (not line numbers) precisely to inherit this robustness — line numbers drift on any edit; named-section citations only drift on intentional restructure.
- The exempt-OK message itself ("per BD-183 §2.4") is part of `check_trinity_addenda_h2` USER-VISIBLE OUTPUT (printed to CI logs every run). This citation is doubly useful: it's both an in-code design record AND a CI-log diagnostic pointer that anyone debugging a Check 16 exemption can grep for and immediately find this report.
- **Carry-forward outcome:** None. Standard practice for IMPL-REPORT cross-references; the user-visible CI-log pointer is a benefit, not a risk; section-number citations are robust to file moves under the standard `maintenance-docs/` archive convention.
```

**Substance preserved.** First bullet unchanged (citations enumerated). Third bullet unchanged (user-visible CI output detail). Second bullet rewritten as recommended by NIT-2: replaces "would become stale" framing with explicit move-vs-restructure distinction, explains why named-section citations are robust (the per-rule statement: line numbers drift on any edit; named-section citations only drift on intentional restructure). Fourth bullet (carry-forward outcome) tightened with closing clause restating the robustness conclusion.

### §2.3 NIT-3 — `test-validate-pack-check-16.sh` Group 3 parity addition

**Reference pattern verified before mirroring.** `scripts/tests/test-validate-pack-check-19.sh` Group 3 asserts (a) `[loc-a]` in `out_a` (location A's bracket-form label in PASS output, where the section header AND the OK message both contain `[label]`), and (b) `loc-b/` in `out_b` (location B's path-prefix label in FAIL output, where `check_trinity_no_scaffolding_comments`'s FAIL lines use the `{label}/{name}` form). The pattern is sound: both forms are empirically what the underlying check function emits.

For Check 16, the parallel forms are: location A (PASS) emits both `[c16-loc-a]` (header + OK lines) and (no FAIL lines because all 3 placeholders pass); location B (FAIL) emits `[c16-loc-b]` in the header but the 3 FAIL lines use the path-prefix form `c16-loc-b/CLAUDE.md`, `c16-loc-b/AGENTS.md`, `c16-loc-b/GEMINI.md` (verified at `scripts/validate-pack.py::check_trinity_addenda_h2` FAIL messages, e.g., `fail(f"{label}/{name} — file missing")`).

**Before** (`scripts/tests/test-validate-pack-check-16.sh` Group 3, after the `shutil.rmtree(tmpdir, ignore_errors=True)` line in the Python heredoc):

```python
if fc_a != 0:
    failures.append(f"Override 9 (Check 16) — clean location A flagged failures: {out_a}")
if fc_b != 3:
    failures.append(f"Override 9 (Check 16) — failing location B expected 3 failures, got {fc_b}: {out_b}")
if "c16-loc-b" in out_a:
    failures.append(f"Override 9 (Check 16) — A leaks B label: {out_a}")
if "c16-loc-a" in out_b:
    failures.append(f"Override 9 (Check 16) — B leaks A label: {out_b}")
```

**After:**

```python
if fc_a != 0:
    failures.append(f"Override 9 (Check 16) — clean location A flagged failures: {out_a}")
if fc_b != 3:
    failures.append(f"Override 9 (Check 16) — failing location B expected 3 failures, got {fc_b}: {out_b}")
# Leak prevention (both directions): neither location's output references the other's label.
if "c16-loc-b" in out_a:
    failures.append(f"Override 9 (Check 16) — A leaks B label: {out_a}")
if "c16-loc-a" in out_b:
    failures.append(f"Override 9 (Check 16) — B leaks A label: {out_b}")
# Label presence (both directions; parity with -19.sh Group 3): each output must
# carry its own label. Location A (PASS path) carries the bracket form `[label]`
# in the section header + OK lines; location B (FAIL path) carries the
# `label/name` form in FAIL lines per `check_trinity_addenda_h2`'s
# `fail(f"{label}/{name} — …")` message shape.
if "[c16-loc-a]" not in out_a:
    failures.append(f"Override 9 (Check 16) — location A label missing from PASS output: {out_a}")
if "c16-loc-b/" not in out_b:  # FAIL lines use the label/file form, not the bracket form
    failures.append(f"Override 9 (Check 16) — location B label-prefix missing from FAIL output: {out_b}")
```

**Parity verified.** Both files' Group 3 now assert: (a) outer FAIL-count expectations, (b) leak prevention in both directions, (c) label presence in both directions (PASS uses `[label]` bracket form; FAIL uses `label/` path-prefix form). The inline comment block above the new assertions explains the form choice for future maintainers (so the asymmetry between `[c16-loc-a]` and `c16-loc-b/` is documented as intentional — the former is the OK-message form, the latter is the FAIL-message form, mirroring `-19.sh`'s same intentional asymmetry).

**Test-count behavior.** The PASS count on `-16.sh` stays at 10 (not 11). The new assertions are added INSIDE the existing Group 3's `failures` accumulator; the harness counts test CASES (groups), not individual `failures.append(...)` calls. This matches `-19.sh` Group 3's shape exactly (which has 4 leak-prevention + 2 label-presence assertions inside one outer Group 3 test case for a 9-case total). Post-fix, `-16.sh` has 10 cases, `-19.sh` has 9 cases — the parity is at the per-assertion level within Group 3, not at the test-case count level.

---

## §3 Files modified — diff stat + per-file purpose

| File | Change type | Lines (added/removed/touched) | Purpose |
|---|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | +3 / -0 | SHOULD-1: add Check 18 (BD-181) sister-step between Check 40 and Check 16; preserves BD-creation-order convention in the trinity-check cluster |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md` | modified | ~1 net (2nd + 4th bullets rewritten; 1st + 3rd bullets unchanged) | NIT-2: replace imprecise "would become stale" framing in §10 Observation 4 with the moved-vs-restructure distinction; tighten closing carry-forward bullet to restate the robustness conclusion |
| `scripts/tests/test-validate-pack-check-16.sh` | modified | +9 / -0 (Group 3 only) | NIT-3: add label-presence-in-both-directions assertions to Group 3 (Override 9), achieving parity with `-19.sh` Group 3 |

**Total.** 3 files modified; ~+13 lines added net; zero files created; zero files deleted; zero files renamed.

---

## §4 Verification

### §4.1 YAML syntax (SHOULD-1)

```
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"
```

**Result.** Exit 0. PASS.

### §4.2 Test suites (all)

| Suite | Pre-fix | Post-fix |
|---|---|---|
| `bash scripts/tests/test-validate-pack-check-16.sh` | `PASS: 10, FAIL: 0` | `PASS: 10, FAIL: 0` (Group 3 now carries 2 additional assertions, but they live inside the same outer test case so the count stays 10 — see §2.3 "Test-count behavior") |
| `bash scripts/tests/test-validate-pack-check-19.sh` | `PASS: 9, FAIL: 0` | `PASS: 9, FAIL: 0` (file unchanged per prompt scope; reference for parity) |
| `bash scripts/tests/test-validate-pack-check-18.sh` | `PASS: 7, FAIL: 0` | `PASS: 7, FAIL: 0` (now wired in CI per SHOULD-1) |
| `bash scripts/tests/test-validate-pack-check-39.sh` | `PASS: 6, FAIL: 0` | `PASS: 6, FAIL: 0` (adjacent regression check) |
| `bash scripts/tests/test-validate-pack-check-40.sh` | `PASS: 8, FAIL: 0` | `PASS: 8, FAIL: 0` (adjacent regression check) |
| `bash scripts/tests/test-validate-pack-check-41.sh` | `PASS: 4, FAIL: 0` | `PASS: 4, FAIL: 0` (adjacent regression check) |

**Grand total.** 44 PASS / 0 FAIL across all 6 validate-pack test suites. Zero regressions.

### §4.3 `python3 scripts/validate-pack.py`

**Result.** Exit 0. `PASSED — all checks clean`. All 41 checks green. Check 16 [project-template] + Check 16 [pack-root] + Check 18 [project-template] + Check 18 [pack-root] + Check 19 [project-template] + Check 19 [pack-root] all OK.

### §4.4 Sanity check on Group 3 parity assertions

Grep confirms both files' Group 3 carry the parallel assertion shape:

```
scripts/tests/test-validate-pack-check-19.sh:337:    failures.append(f"Override 9 — location A label missing: {out_a}")
scripts/tests/test-validate-pack-check-19.sh:339:    failures.append(f"Override 9 — location B label-prefix missing from FAIL output: {out_b}")
scripts/tests/test-validate-pack-check-16.sh:328:    failures.append(f"Override 9 (Check 16) — location A label missing from PASS output: {out_a}")
scripts/tests/test-validate-pack-check-16.sh:330:    failures.append(f"Override 9 (Check 16) — location B label-prefix missing from FAIL output: {out_b}")
```

Both files now assert (a) leak-prevention in both directions and (b) label-presence in both directions within their Override 9 Group 3.

---

## §5 RC9 manifest status

**Trigger fired.** Edits touched `.github/workflows/validate-pack.yml`, `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md`, and `scripts/tests/test-validate-pack-check-16.sh`. The `scripts/` path is in the RC9 v11-surface trigger glob, so the rebuild was run per the rule.

**Rebuild outcome.**

```
bash test-fixtures/build.sh --all --clean       # exit 0
git diff test-fixtures/manifest.txt             # empty (0 lines)
```

**Outcome documented.** Empty diff. Pack-internal scopes: `scripts/tests/test-validate-pack-check-16.sh` is not copied to client projects by `scripts/init-project.sh` (test-runner-only); `.github/workflows/` is pack-internal CI; `maintenance-docs/v11-implementation/` is a pack-internal design-record area. None of these surfaces are in any of the six fixture-bake-in paths (matches the prompt's a-priori RC9 expectation: "scripts/ + .github/ touched but pack-internal. Rebuild expected empty diff. Document outcome."). **No manifest staging needed.**

---

## §6 Carry-forward discipline

Per `.claude/skills/review/SKILL.md` § "Carry-forward discipline" (SIZE / BLOCKED / LOGICAL-FIT high-bar — operationalizes pack memory "Deferral IS scope creep"):

**Zero deferrals. Zero carry-forwards.**

Scope-adjacent observations encountered during the fix work:

- **None.** The 3 fixes are fully bounded by the PACK-REVIEW-BD-183 triage decisions. No new scope-adjacent observations surfaced. SHOULD-1 is a single sister-step addition; NIT-2 is a wording polish; NIT-3 is a 9-line test-parity addition. Each is mechanical, file-disjoint, and verified in isolation. NIT-1 is explicitly SKIPPED per Pack Chat triage (commit subject is immutable on the already-landed `aeacbdc`).

**Carry-forward count: 0.** No new findings; no new BDs surfaced; no observations needing future attention.

---

## §7 PREFLIGHT

PREFLIGHT: 3/3 in-scope file edits complete; verification PASS (validate-pack.py exit 0; test-validate-pack-check-{16,18,19,39,40,41}.sh all PASS — 44/44; YAML syntax PASS; RC9 manifest diff empty); HEAD `aeacbdc09dcf22f360efbd6c76668859c56b772c`; IMPL-REPORT Write complete at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183-FIX-1.md`.
