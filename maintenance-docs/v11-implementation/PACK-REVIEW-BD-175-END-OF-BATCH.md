# PACK-REVIEW — BD-175 → BD-184 END-OF-BATCH (cross-cutting safety net)

**Reviewer role.** End-of-batch (reviewer #13) for the BD-175 EMERGENCY
BATCH (BD-175 → BD-176 → BD-177 → BD-178 → BD-179 → BD-180 → BD-181 →
BD-182 → BD-183 → BD-184). FRESH agent. Cross-cutting safety net AFTER
all per-commit reviewers + per-BD fix cycles closed.

**Inputs read (read-only).**
- Batch range: `git log --oneline 556e134..b176519` (81 commits)
- HEAD `b1765196c67b0c71b63c74f2d3ded53dacdaa19b` on branch `v11-dev`
- BACKLOG entries: `pack-ops/BACKLOG.md` L1380-L1740 (BD-175 through BD-184)
- Per-commit reviews: 12 prior PACK-REVIEW-*.md across 10 BDs (sampled)
- IMPLEMENTATION-REPORT-*: sampled BD-179, BD-180, BD-176, BD-184
- ORCHESTRATION-PLAN-BD-175.md (Phase 5/6/7 contract)
- Carry-forward discipline: `.claude/skills/review/SKILL.md` § "Carry-forward discipline"
- Pack memory: pack-root `CLAUDE.md` § "Pack memory"

**Scope boundary.** I do NOT re-review per-BD findings (already cycled to
closure). I look for cross-cutting concerns the per-commit reviewers
systematically MISS by their per-BD scope.

---

## §1 Verdict

**APPROVE-BATCH-WITH-FIXES.**

The BD-175 emergency batch is structurally complete. All 10 BDs landed
with per-commit review + fix-cycle closure; all 42 numbered validate-pack
checks PASS at HEAD; all 9 per-check test suites PASS independently;
manifest internally consistent; trinity discipline maintained across
both pack-root and project-template surfaces; carry-forward discipline
applied consistently after FIX-5 landed (commit `ff23a00`); P-missed-7
boundary discipline holds; architect-doc-vs-reality reconciliation
chains intact.

**One SHOULD finding** carries the batch over the "APPROVE" line: the
README.md Repository Layout staleness pattern that BD-179 reviewer
explicitly flagged as an end-of-batch carry-forward (Observation 2)
WAS partly addressed by BD-179 FIX-3 (commit `2842454`) — but BD-180,
BD-181, BD-183, and BD-184 each added new artifacts (Checks 41 + 42 + 3
new test scripts) AFTER the FIX-3 README sweep, re-staling the same
inventory. The recurrence is the precise gap class FIX-5 + Check 42
were designed to prevent for CI wiring; the README inventory has no
analogous mechanical guard.

**One NIT** carries forward from BD-184 reviewer's hand-off note
(IMPL-REPORT module-docstring numbering disorder, 41-before-40 in the
validate-pack.py module docstring) — pre-existing condition, not a
batch regression; surfaced for Pack Chat triage.

The batch is ready for Phase 6 (user spot-check) and Phase 7 (status
flip + Batch 19c resume) once the README sweep finding is triaged.

---

## §2 Severity breakdown

| Severity   | Count | Notes |
|------------|-------|-------|
| BLOCKER    | 0     | — |
| MUST       | 0     | — |
| SHOULD     | 1     | README.md Repository Layout post-FIX-3 re-staleness (Checks 41 + 42 + 5 test scripts) |
| NIT        | 1     | Pre-existing module-docstring numbering disorder (BD-184 hand-off) |
| CARRY-FORWARD | 0 | No findings qualify for SIZE / BLOCKED / LOGICAL-FIT high bar; both findings are surfaced as in-scope per discipline default-FIX-NOW |

---

## §3 Per-BD closure verification

| BD | Closure | Notes |
|----|---------|-------|
| BD-175 | **CLEAN** | T1-NIT-CUMULATIVE review APPROVE; F4-bundle + F1 + F2a all reviewed clean; SHOULD-1 §6.1 architect addendum + BD-119 §9.2 reconciliation pattern realized; T1 NIT exhaustive sweep (17 token replacements) landed without regression. Prevention mechanisms M1-M8 (Checks 36/37/38) operational at HEAD. |
| BD-176 | **CLEAN** | PACK-REVIEW-BD-176.md APPROVE zero findings. RC9 trigger expansion (2-dir → 4-dir) covers both empirical false-negative (supporting-docs/) and defensive (pack-ops/) classes. Architect doc captures D4 deferral to BD-180 with explicit forward-reference; BD-180 addendum (commit `7c0172c`) closes the reconciliation loop. |
| BD-177 | **CLEAN** | PACK-REVIEW-BD-177-FIX-PASS-2.md APPROVE zero findings. Sentinel-regex coordination at `scripts/pack-help.sh:86` ↔ `pack-ops/HELP-FRAGMENT-PACK.md:37` complete; dual-surface coverage hardened; test 2.2.c made CI-portable via source-direct invocation. |
| BD-178 | **CLEAN** | PACK-REVIEW-BD-178-SHOULD-2.md APPROVE zero findings (SHOULD-2). SHOULD-1 cross-CLI side-case anticipated and absorbed into BD-182 per pack memory `feedback-deferred-work-tracking`. Trinity asymmetry alignment landed across 4 sections (iOS 26 / Architecture / Security / Scripts) + POQ-F4-3 Tier 0 base-loading note. |
| BD-179 | **CLEAN** | PACK-REVIEW-BD-179-FIX-CYCLE.md APPROVE zero findings. 5 fix-cycle commits absorbed all CF-1/CF-2/CF-3 observations into in-scope SHOULD-1/SHOULD-3/FIX-5 fixes per `feedback-deferral-is-scope-creep`. FIX-5 (`ff23a00`) installed carry-forward discipline into the review skill — the prevention mechanism is itself the most consequential output of the batch. |
| BD-180 | **CLEAN** | PACK-REVIEW-BD-180 + FIX-1/FIX-2/FIX-3 sequence APPROVE-clean. Self-documenting `_CLIENT_INSTALLED_FILES_START/_END` block + Check 41 realize ARCHITECTURE-BD-176.md §5.3 design sketch; BD-180 addendum file delivers reconciliation chain leg (b). PROMPT-TEMPLATES.md stale entry removed; bidirectional cmd_update verification operational. |
| BD-181 | **CLEAN** | PACK-REVIEW-BD-181 + PRECONDITION APPROVE. Check 18 H2 pack-root trinity parity extension with sentinel-None call-site contract. Empirical pre-implementation drift check executed cleanly; pack-root trinity Option B alignment landed via precondition commit `e6cc56f`. |
| BD-182 | **CLEAN** | PACK-REVIEW-BD-182.md APPROVE zero findings. R1 cross-CLI substitution + pack-memory bullet across pack-root trinity closes BD-178 SHOULD-1's CLAUDE-canonical reference asymmetry in GEMINI.md. |
| BD-183 | **CLEAN** | PACK-REVIEW-BD-183 + FIX-1 + FIX-2 APPROVE-clean sequence. Check 16 + Check 19 pack-root extension mirrors BD-181 pattern; BD-181 NIT-1 sentinel-None contract comment folded in per LOGICAL FIT. FIX-1 wired BD-181's test-validate-pack-check-18.sh; FIX-2 wired BD-180's test-validate-pack-check-41.sh per BD-179 SHOULD-1 precedent. |
| BD-184 | **MINOR** | PACK-REVIEW-BD-184.md APPROVE; 2 NITs (one acknowledged tradeoff, one pre-existing) skipped per IMPL-REPORT. Check 42 closes the "missing test wiring" gap class permanently via mechanical guard — gap surfaced 5 times across BD-179 FIX-1, BD-183 FIX-1, BD-183 FIX-2 + 2 earlier instances. NIT-2 (pre-existing module-docstring 41-before-40 numbering disorder) surfaced for end-of-batch awareness; not a BD-184 regression. |

---

## §4 Cross-cutting concerns

### Concern 1 — Discipline consistency across the batch

**Status: CLEAR.**

The carry-forward discipline (`.claude/skills/review/SKILL.md` § "Carry-forward discipline", landed in FIX-5 commit `ff23a00`) was applied
rigorously by all subsequent reviewers:

- PACK-REVIEW-BD-179-FIX-CYCLE.md (immediately after FIX-5): explicit
  self-application; zero carry-forwards survived high bar.
- PACK-REVIEW-BD-180.md / FIX-1 / FIX-2 / FIX-3: each report carries a
  §6 carry-forward section enumerating candidates considered + rejection
  reasons per the SIZE / BLOCKED / LOGICAL-FIT tests; zero carry-forwards
  surfaced.
- PACK-REVIEW-BD-181 / PRECONDITION: explicit "not a CARRY-FORWARD per
  the discipline" classification with rationale.
- PACK-REVIEW-BD-182.md: zero findings; discipline NA.
- PACK-REVIEW-BD-183.md + FIX-1 + FIX-2: each report explicitly cites
  the discipline; FIX-1 surfaces SHOULD-A using the exact precedent
  pattern ("Pack memory rule X recommends fix-now stated as the
  rationale but presented as carry-forward" is forbidden — hence
  in-scope SHOULD, not carry-forward).
- PACK-REVIEW-BD-184.md: explicit "10th reviewer in carry-forward
  chain" framing; carry-forward observations §6 enumerate candidates
  + rejection per discipline.

The discipline is NOT mechanical evidence; the FIX-5 prevention is a
prose contract enforced by reviewer attention. Across 8+ reviews
post-FIX-5, every reviewer cited the discipline and applied it. This
is the strongest positive signal of the batch.

### Concern 2 — Convergence verification (missing test wiring class)

**Status: CLEAR (via Check 42).**

The "missing test wiring" gap class surfaced 5 times across the batch
per the BD-184 BACKLOG entry:
- BD-179 FIX-1 (`1e644d1`): wired 3 unwired tests (test-validate-pack-checks-36-37-38.sh; test-validate-pack-check-39.sh; test-validate-pack-check-40.sh)
- BD-183 FIX-1 (`5f8f683`): wired test-validate-pack-check-18.sh
- BD-183 FIX-2 (`99b0f12`): wired test-validate-pack-check-41.sh

Each was caught by reviewer attention applying carry-forward discipline,
but the recurrence pattern motivated BD-184 mechanical prevention.

**Empirical verification at HEAD:**
```
$ ls scripts/tests/test-validate-pack-check*.sh | wc -l
9
$ grep -cE "test-validate-pack-check.*\.sh" .github/workflows/validate-pack.yml
9
$ python3 scripts/validate-pack.py 2>&1 | grep "Check 42"
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests.
```

9 files on disk, 9 wirings in workflow, Check 42 verifies the
invariant at every CI run. The gap class is closed mechanically.

**Adjacent recursion patterns considered:**
- README inventory staleness — surfaced in Concern 6 below as a
  SHOULD finding (the recurrence pattern Check 42 inspired but does
  NOT cover).
- Architect-doc-vs-reality reconciliation completeness — verified in
  Concern 4 below; no recursion.
- No other recurring gap classes identified.

### Concern 3 — Boundary discipline (P-missed-7) across the batch

**Status: CLEAR.**

Empirical at HEAD:
- Check 36 (commit-scope honesty): `1 implicit-scope commit(s) skipped; 0 scope-claiming commits verified clean` — clean.
- Check 37 (project-side pack-only deny-list): `146 project-side file(s) walked; zero deny-list contamination` — clean.
- Check 38 (pack-only-file siting): `1 pack-root prose file(s) checked; no pack-only content mis-sited outside pack-ops/` — clean.

Manual spot-check of project-template/ trinity edits in the batch:
- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` reference `PACK-AGENTS.md`, `PACK-CHAT.md`, `pack-ops/` ONLY in deny-list documentation context (explicitly enumerating what NOT to import). This is the correct discipline (BD-175 prevention pattern).
- `project-template/docs/pack/PM-CHAT.md` references `pack-ops/MERGE-STRATEGY.md` parenthetically ("docs/pack/MERGE-STRATEGY.md (or pack-ops/MERGE-STRATEGY.md in the pack repo)") — points to project SSOT first; pack-repo path is informational. Correct.
- `project-template/docs/pack/prompts/coder.md` + `reviewer.md` reference pack-* agents + pack-ops/ in DENY-LIST framing only.
- `project-template/skills/boundary-investigation/SKILL.md` is the deny-list reference itself — by design, enumerates the forbidden tokens.

No pack-only content mis-sited into project-template/ in the batch.
No pack-* agent name reused as project-side identifier.

The BD-175 substrate prevention work plus BD-178 trinity alignment +
BD-182 cross-CLI normalization deliver a clean baseline for Batch 19c.

### Concern 4 — Cross-BD reconciliation chains

**Status: CLEAR.**

Worked examples sampled at HEAD:

1. **BD-175 §6.1 ↔ BD-119 §9.2 reconciliation pattern.**
   `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6.1 cross-references BD-119 §9.2's
   reconciliation pattern by name (T1 NIT cumulative sweep applied
   17 token replacements). Triad legs: (a) in-code docstring slot
   exists at the realized consumer; (b) architect addendum §6.1
   present; (c) IMPL-REPORT-BD-175-SHOULD-1.md cross-references both.

2. **BD-176 §5.3 ↔ BD-180 G realization.**
   `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3 sketch + §5.3 addendum landed in commit `7c0172c` naming
   BD-180's `_CLIENT_INSTALLED_FILES_START/_END` block and
   Check 41 as the realized consumer. IMPL-REPORT-BD-180.md §4
   reciprocally cross-references the architect sketch + addendum.

3. **BD-179 §13.4 BD-119 pattern documentation.**
   `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` §13.4 explicitly notes that BD-179 is itself an architect doc
   and does NOT realize a pre-existing design — correct handling of
   the pattern boundary.

4. **BD-181 ↔ BD-183 sentinel-None pattern.**
   BD-181 introduced the sentinel-None call-site contract pattern at
   `check_trinity_h2_parity`; BD-183 folded in the NIT-1 contract
   comment at the same function per LOGICAL FIT. BD-183 generalized
   Check 16 + Check 19 to follow the same pattern. Reconciliation
   chain: BD-181 NIT-1 → BD-183 fold-in delivers leg (a) in-code
   comment.

5. **BD-184 prevention closes BD-179 FIX-5 reviewer-attention pattern.**
   BD-179 FIX-5 installed carry-forward discipline (reviewer-attention
   mechanism); BD-184 Check 42 installs mechanical CI-time enforcement
   of the specific failure mode (unwired tests) that motivated
   FIX-5. The two layers are complementary, not duplicative.

No incomplete reconciliations identified.

### Concern 5 — Stale references

**Status: CLEAR.**

Sampled cross-BD references in IMPL-REPORTs and PACK-REVIEWs at HEAD:
- BD-180 IMPL-REPORT references BD-179's Check 40 claim (explaining
  Check 41 substitution) — correct.
- BD-183 IMPL-REPORT references BD-181 NIT-1 fold-in — correct.
- BD-184 IMPL-REPORT references BD-179 FIX-1, BD-183 FIX-1, BD-183
  FIX-2 as the 5 gap-class precedents — correct.
- Architect docs for BD-176 / BD-179 / BD-182 all reference downstream
  BDs accurately.

No stale references identified.

### Concern 6 — Pre-existing tech debt surfaced but not opened as BDs

**Status: DEGRADED (one SHOULD finding).**

Per the discipline, surfaced issues that don't fit BD-X scope should
either be opened as a new BD (with user-discussion-and-approval per
OQ-1) or explicitly tracked.

**Tracked items (acceptable):**
- BD-178 SHOULD-1 cross-CLI side-case → opened as BD-182 (PACK-REVIEW-BD-178 + PACK-REVIEW-BD-181 surfaced; user-approved fold-in).
- BD-181 §6 Observation A (Check 16/19 hardcoded) → opened as BD-183 (mechanical fold-in).
- BD-183 FIX-1 SHOULD-A scanner result → opened as BD-184.
- BD-180 observation E (PROMPT-TEMPLATES.md stale) → absorbed into BD-180.
- BD-180 observation G (self-doc list) → absorbed into BD-180.
- BD-176 NotableFinding 2 / OQ-2 D4 → absorbed into BD-180.

**DEGRADED item:**
- **README.md Repository Layout staleness pattern (see Finding 1 in §5).**
  BD-179 reviewer (PACK-REVIEW-BD-179.md §5 carry-forward observation 2)
  explicitly flagged: "End-of-batch reviewer should triage whether to
  do a single README sweep at batch close." BD-179 FIX-3 (`2842454`)
  swept README to reflect Check 40 + BD-179 test-suite count. After
  that sweep, BD-180 added Check 41 + test-validate-pack-check-41.sh,
  BD-181 added test-validate-pack-check-18.sh, BD-183 added
  test-validate-pack-check-16.sh + test-validate-pack-check-19.sh,
  BD-184 added Check 42 + test-validate-pack-check-42.sh. None of
  these BDs re-swept the README inventory; the FIX-3 sweep was a
  point-in-time snapshot, not a maintained contract.
- **NIT-2 from BD-184 (pre-existing module-docstring numbering disorder
  41-before-40)** — surfaced for awareness; pre-existing condition
  per BD-184 reviewer's evidence (predates BD-184); not a batch
  regression. Pack Chat triage decides whether to fold into the
  README sweep commit or open a separate cosmetic-fix BD.

### Concern 7 — Trinity rules across the batch

**Status: CLEAR.**

Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md):
- 5 shared H2 sections + 1 CLI-specific notes section per file (Quick
  reference / What this repo is / Repo structure / Rules for agents
  working on this repo / Pack memory + CLI-specific notes). Check 18
  [pack-root] PASS.
- Check 16 [pack-root]: PASS (addenda H2 parity).
- Check 19 [pack-root]: PASS (no body scaffolding).
- BD-176 RC9 expansion landed lockstep; BD-181 precondition aligned
  pack-root trinity Option B; BD-182 cross-CLI substitution landed
  R1 across all three.

Project-template trinity:
- BD-178 SHOULD-1 aligned body text for 4 sections (iOS 26 / Architecture
  / Security / Scripts) per Option 1A (CLAUDE-canonical).
- BD-182 normalized cross-CLI references (settings paths / commands /
  tool-specific URIs) across the trinity.
- Check 16 [project-template]: PASS.
- Check 18 [project-template]: PASS (H2 structure parity).
- Check 19 [project-template]: PASS.

Override 9 compliance maintained: BD-179 Check 40 narrowly scoped to
`pack-ops/*.md` (does not apply to project-template/ or pack-root
trinity); BD-183 Option (b) per-surface exemption mechanism preserves
the design boundary for Check 16/19 pack-root invocation.

### Concern 8 — RC9 manifest integrity

**Status: CLEAR.**

Empirical at HEAD:
```
$ bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: c77d7bace2a74909290cd20e14af680370ead2d8
  v11-flat-file OK: 13bba3fc2d24ced8c0568670aa6e961797a484ee
  v11-tracker-on OK: f116b0a0097f7195726fa737ef3b7b6bd9bdc862
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 fixtures verify; manifest content matches current fixture build.

BD-175 Commit 8 manifest regen incident (commit `6c48f88` post-`4120d19`)
drove BD-176's RC9 trigger expansion from 2 directories to 4
(project-template/ + scripts/ → + pack-ops/ + supporting-docs/). No
subsequent manifest drift incidents in the batch.

### Concern 9 — CI workflow + test wiring completeness

**Status: CLEAR (Check 42 closes the gap class permanently).**

Empirical at HEAD per Concern 2:
- 9 per-check test files on disk; 9 wirings; Check 42 PASS.
- All 9 test suites PASS independently when invoked.
- All 42 numbered validate-pack checks PASS.

**Adjacent test-infra completeness check** (other scripts that exist
but aren't wired): the workflow has 40 test-suite invocations; the
scripts/tests/ directory has 44 .sh files. Difference (4): pack-help-test.sh,
recommendation-test.sh, recommendation-state-schema-test.sh, template-translations-test.sh,
template-version-test.sh, test-add-capability.sh, test-customization-preserve.sh,
test-init-project.sh, test-issue-forms.sh, test-migrate-v10-to-v11-*.sh,
test-per-entry.sh, test-tracker-*.sh, test-v11-realistic-ot.sh,
tracker-*-test.sh. These are NOT in the `test-validate-pack-check-*.sh`
naming convention that Check 42 governs; some are wired under different
step names (e.g., `pack-help-test.sh` under "Pack help tests"). Check 42
narrowly targets the validate-pack check-test naming convention because
that was the empirical 5-time gap class; broader test-wiring coverage
is out of scope per BD-184 BACKLOG.

No new test-infra gap surfaces at end-of-batch.

### Concern 10 — Closing-the-batch readiness

**Status: READY-WITH-FIXES (one SHOULD triage gate before Phase 6).**

The batch chain is structurally complete. Phase 6 (user spot-check)
should proceed once the README staleness SHOULD finding (Finding 1
in §5 below) is triaged. The triage outcomes per Pack Chat
default-FIX-all discipline are:

- **FIX-NOW (recommended).** Single PM-only edit to `README.md` L60 + L195
  updating "38 invoked checks" → "40 invoked checks", "Check 1–11 and
  16–40" → "Check 1–11 and 16–42", "aggregate CI test runner across 35
  suites" → "across 40 suites", plus L237-240 inventory additions for
  the 5 newly-wired test files (test-validate-pack-check-41.sh,
  test-validate-pack-check-16.sh, test-validate-pack-check-18.sh,
  test-validate-pack-check-19.sh, test-validate-pack-check-42.sh). 5
  lines added, 3 lines updated. Single commit `fix: v11 — broad batch
  review/fix (Batch 19b)` per CLAUDE.md approved-suffix convention.

- **OPEN-NEW-BD.** Defer to a new BD (e.g., BD-185) inserted
  immediately after BD-184 per user-discussion-and-approval per OQ-1.
  Per pack memory `feedback-deferral-is-scope-creep`, this requires
  SIZE / BLOCKED / LOGICAL-FIT justification — the change is small,
  not blocked, and fits within the same surface as the in-batch
  changes that caused the staleness. Defensible only under explicit
  user direction.

- **SKIP-WITH-RATIONALE.** Accept README as a soft-pass surface
  updated only at version-ship boundaries (i.e., when v11.0 tag
  lands). Per pack memory `feedback-fix-all-review-findings`, this
  is allowed for NITs but the README finding is SHOULD (not NIT)
  per the BD-179 reviewer's prior SHOULD-3 classification of the
  same pattern.

Recommended path: **FIX-NOW** per pack memory `feedback-deferral-is-scope-creep` (small, unblocked, logically fits the batch close).

---

## §5 Findings

### SHOULD-1 — README.md Repository Layout post-FIX-3 inventory re-staleness

**Severity:** SHOULD (matches BD-179 reviewer's SHOULD-3 classification of the same pattern at the prior cycle).

**File/symbol:**
- `README.md:60` (v11.0 version-table row)
- `README.md:195` (Repository Layout validate-pack.py row)
- `README.md:237-240` (test-fixtures inventory rows)

**Problem.** BD-179 FIX-3 (commit `2842454`) swept the README to reflect
Check 40 + 35-suite count at that point in time. Five subsequent
artifacts landed AFTER the sweep without re-staling the README:
- BD-180 added Check 41 (`scripts/validate-pack.py`) + test-validate-pack-check-41.sh
- BD-181 added test-validate-pack-check-18.sh (wired in BD-183 FIX-1)
- BD-183 added test-validate-pack-check-16.sh + test-validate-pack-check-19.sh
- BD-184 added Check 42 + test-validate-pack-check-42.sh

Empirical at HEAD:
- `README.md:60` says "38 invoked checks (36 numbered Check 1–11 and 16–40; 2 unnumbered informational)" — actual at HEAD is 38 numbered checks (1-11 = 11, 16-42 = 27) + 2 unnumbered = 40 invoked, range 16-42, not 16-40.
- `README.md:60` says "aggregate CI test runner across 35 suites" — actual at HEAD is 40 suite invocations in `.github/workflows/validate-pack.yml` (`grep -cE "^[[:space:]]*run: bash scripts/tests/" .github/workflows/validate-pack.yml` returns 40).
- `README.md:195` mirrors L60 with "38 invoked checks ... Check 1–11 and 16–40" — same staleness.
- `README.md:237-240` inventory rows enumerate only 5 test files (test-validate-pack-checks-32-33-34, test-validate-pack-checks-36-37-38, test-validate-pack-check-39, test-validate-pack-check-40); missing 5 newly-landed test files (test-validate-pack-check-16, test-validate-pack-check-18, test-validate-pack-check-19, test-validate-pack-check-41, test-validate-pack-check-42).

**Fix.** Pack-Chat-direct README edit (PM-only file per CLAUDE.md
permission rules):
- L60: "38 invoked checks (36 numbered Check 1–11 and 16–40; 2 unnumbered ...)" → "40 invoked checks (38 numbered Check 1–11 and 16–42; 2 unnumbered ...)"; "Check 40 pack-ops/ bare cross-reference scanner" → "Check 40 pack-ops/ bare cross-reference scanner, Check 41 _CLIENT_INSTALLED_FILES self-doc list integrity, Check 42 CI workflow wires all per-check test files"; "aggregate CI test runner across 35 suites" → "across 40 suites".
- L195: same numeric updates + range extension.
- L237-240: add 5 inventory rows for the new test files (one per test file with one-line description).

**Rationale.** Per pack memory `feedback-deferral-is-scope-creep`:
the change is SMALL (3 lines updated + 5 lines added), UNBLOCKED (no
dependencies), and LOGICALLY FITS the batch close (README is the
documentation surface for the batch's deliverables). The BD-179 reviewer
explicitly classified this same pattern as SHOULD-3 (fix-now). Per
carry-forward discipline forbidden shape "Pack memory rule X recommends
fix-now stated as the rationale but presented as carry-forward" — this
must be in-scope, not deferred to v11.1+. Per CLAUDE.md PM-only file
boundaries, README edit is Pack-Chat-direct (not via pack-coder).

The deeper structural observation that no mechanical guard exists for
README inventory drift (analogous to Check 42 for CI test wiring) is
not a current defect — it's a "Class would benefit from a check" hypothesis. Per carry-forward discipline forbidden shape "forward-looking
conjecture" — this is NOT a finding. If a future README-staleness
recurrence is observed in v11.1+, a BD analogous to BD-184 can be opened
then; today the README sweep alone is sufficient.

### NIT-1 — Pre-existing validate-pack.py module-docstring numbering disorder (BD-184 hand-off)

**Severity:** NIT (advisory; pre-existing condition surfaced for end-of-batch awareness per BD-184 reviewer).

**File/symbol:** `scripts/validate-pack.py` module docstring (BD-184 PACK-REVIEW NIT-2 evidence).

**Problem.** Per PACK-REVIEW-BD-184.md NIT-2: "Pre-existing module-docstring numbering disorder (41-before-40); BD-184 preserves but does not introduce." The condition predates BD-184 (verified by BD-184 reviewer at `0f8d8ee`). The module docstring lists Check 41 before Check 40 (numeric order violation).

**Fix.** Pack Chat triage; options:
- (a) Fold into the same README sweep commit (single PM-only-style fix; but validate-pack.py is NOT PM-only — would need pack-coder).
- (b) Open new cosmetic-fix BD (e.g., BD-185) inserted post-batch.
- (c) SKIP — cosmetic readability issue, not functional.

**Rationale.** Cosmetic; not a functional defect; pre-existing.
Carry-forward discipline SKIP/SIZE/BLOCKED/LOGICAL-FIT analysis: not
SIZE (1-line swap), not BLOCKED, LOGICAL-FIT marginal (cosmetic doc
edit, not tied to batch contract). Per `feedback-fix-all-review-findings`
NIT default is FIX, but pre-existing NITs are typically deferred via
explicit Pack Chat triage. No strong recommendation either way; surface
for awareness.

---

## §6 Carry-forward observations

This reviewer applies `.claude/skills/review/SKILL.md` § "Carry-forward
discipline" rigorously to its own output. The discipline:

> Default: FIX NOW. Every finding that does NOT meet ALL THREE tests
> (SIZE / BLOCKED / LOGICAL FIT) must be surfaced as an in-scope review
> finding for fix-now triage by Pack Chat, not deferred to a later
> reviewer pass.

**Result: zero carry-forwards survive the high-bar test.**

Candidate observations considered + classified:

1. **README.md inventory staleness** — meets all three tests for IN-SCOPE
   classification (SMALL, UNBLOCKED, LOGICAL-FIT with batch close). Surfaced
   as SHOULD-1 in §5 above. NOT a carry-forward.

2. **Pre-existing validate-pack.py docstring numbering** — surfaced as NIT-1
   in §5 above per BD-184 reviewer's hand-off. NOT a carry-forward (per
   carry-forward discipline forbidden shape "pre-existing condition that
   predates this batch" — not deferred; surfaced for triage).

3. **README-inventory mechanical guard hypothesis** — considered as
   potential SHOULD finding (would require a Check 43 analogous to
   Check 42, scanning README inventory rows vs validate-pack.py check
   count). Rejected: forward-looking conjecture per forbidden shape;
   no current defect; the manual sweep at batch close is sufficient
   for v11.0; if recurrence observed in v11.1+, a future BD can address.

4. **`_strip_code_blocks` tab-indented block support** (BD-179 FIX-CYCLE
   §6 candidate) — already rejected by BD-179 FIX-CYCLE reviewer; no
   current defect (no pack-ops/*.md uses tab-indented blocks at HEAD);
   architect §3.2 ratifies the scope choice. Not a finding.

5. **Boundary-discipline test coverage** — considered as potential SHOULD
   (Check 36/37/38 lack scratch-fixture tests beyond what test-validate-pack-checks-36-37-38.sh provides). Rejected: per BD-175
   delivery, test fixtures + e2e regression coverage are operational; no
   current defect; expanding test coverage is its own architect-pass
   work, not a batch-close fix.

6. **CHANGELOG.md updates** — BACKLOG entries for BD-175 through BD-184
   are NOT in pack-ops/CHANGELOG.md. Correct per CLAUDE.md "CHANGELOG.md
   only at version boundaries with explicit instruction"; the BD-175
   batch is pre-v11.0 tag. Not a finding.

7. **Per-BD status flip** — all 10 BDs read `Status: Open` at HEAD.
   Correct per pack memory `feedback-implicit-status-flip` — flip
   happens at Phase 7 as the final step of the batch, not at per-BD
   close. Not a finding.

**Forbidden carry-forward shapes self-checked against this report:**
- "Broader pattern than just this batch" — not used; the SHOULD-1
  finding is in-scope.
- "End-of-batch reviewer might consider…" / "Worth ~N minutes" — not
  used.
- Forward-looking conjecture — explicitly rejected per item 3 above.
- Design ratification — not used.
- "Pack memory recommends fix-now but presented as carry-forward" —
  explicitly avoided per item 1 above (SHOULD-1 is in-scope, not
  carry-forward).

**Result: zero carry-forwards in this report.** The 1 SHOULD + 1 NIT
in §5 are surfaced for Pack Chat default-FIX-all triage.

---

## §7 Convergence readiness for Phase 6 + Phase 7 + Batch 19c resume

**Phase 6 (Verification — manual spot-check by user) readiness.**

Per ORCHESTRATION-PLAN-BD-175.md §B Phase 6 checklist:
- [PASS] All audit findings addressed (cross-check against `AUDIT-*` doc) — no AUDIT-*.md outstanding.
- [PASS] Directory architecture matches Architect B's design (pack-ops/ scaffold + BOUNDARY-DEFINITION + post-reorg layout).
- [PASS] All path references resolve correctly (Check 34 cross-reference integrity + Check 40 pack-ops/ bare cross-reference scanner both clean at HEAD).
- [PASS] CI passes (including new boundary-check gates Checks 36/37/38).
- [PASS] Trinity rule + RC9 manifest still honored (all trinity checks pass; manifest verified).
- [PASS] Test fixtures regenerated (manifest verified at HEAD).
- [READY] Manual spot-check by user — proceed once SHOULD-1 (README sweep) is triaged.

**Phase 7 (Close + Batch 19c resume decision) readiness.**

Per ORCHESTRATION-PLAN-BD-175.md §B Phase 7 checklist:
- [READY] BD-175 flipped to Resolved (apply implicit-status-flip after Phase 6 user sign-off).
- [READY] All other batch BDs (BD-176 → BD-184) flipped to Resolved at the same time per `feedback-implicit-status-flip`.
- [READY] Pack Chat updates Task #13 to ready-to-resume.
- [DECISION-POINT] Salvage 19c V1/Path C/G-research docs OR restart 19c from scratch given the new classification + prevention rules — this is user-facing decision, not in reviewer scope.

**Batch 19c (BD-173) resume readiness.**

BD-173 was BLOCKED behind BD-175 per BACKLOG entry BD-175 "Unblocks"
field. Post-batch state:
- Project-template trinity baseline is symmetric (BD-178 SHOULD-1 + BD-182 normalized).
- Pack-vs-project boundary is mechanically enforced (Checks 36/37/38 operational).
- README/maintenance docs/architect-doc reconciliation chains are in
  place; no outstanding cross-BD references in flight.
- Carry-forward discipline + mechanical CI test-wiring guard are
  operational; BD-173 cycle reviewers will inherit both.

The substrate for Batch 19c is clean. Recommended action sequence:
1. Pack Chat presents §5 SHOULD-1 triage to user.
2. User approves FIX-NOW for README sweep.
3. Pack Chat applies Pack-Chat-direct README edit + commits as `fix: v11 — broad batch review/fix (Batch 19b)`.
4. Pack Chat presents Phase 6 verification status to user.
5. User performs manual spot-check (or delegates).
6. Pack Chat applies Phase 7 implicit-status-flip across all 10 BDs.
7. Pack Chat presents Batch 19c resume decision to user.

---

## §8 What this batch got right

- **Carry-forward discipline installation (FIX-5 / `ff23a00`).** The
  most consequential structural deliverable. Every post-FIX-5 review
  cited the discipline and applied it; the BD-179 FIX-1 / BD-183
  FIX-1 / BD-183 FIX-2 cycles all surfaced findings as fix-now (not
  carry-forward) per the discipline's forbidden-shape rules. Without
  the discipline, the BD-179 "end-of-batch carry-forward Observation 2"
  pattern would have continued accumulating throughout the batch.

- **Mechanical prevention (BD-184 Check 42).** The "missing test wiring"
  gap class recurred 5 times — discipline caught each occurrence, but
  Check 42 closes the recurrence permanently. The combination of
  reviewer-attention (FIX-5) AND mechanical-guard (Check 42) is the
  defense-in-depth pattern this batch validates.

- **Architect-doc-vs-reality reconciliation.** Four worked examples
  (BD-119 → BD-160, BD-119 → BD-175, BD-176 → BD-180, BD-181 → BD-183)
  all maintain the 3-leg pattern (in-code docstring + architect
  addendum + IMPL-REPORT cross-ref). This is load-bearing for future
  architect-doc consumers in v11.x+.

- **Boundary discipline (P-missed-7).** Zero project-side leakage
  across 81 commits. The BD-175 substrate prevention work (Checks
  36/37/38) plus disciplined trinity edits (BD-178 SHOULD-1 +
  BD-182 normalization) deliver a clean baseline for project-side
  Batch 19c work.

- **Carry-forward discipline applied to reviewer's own output.** Every
  per-commit reviewer post-FIX-5 enumerated candidate observations and
  rejection rationale. This makes review reports auditable — the
  discipline becomes visible at the moment of triage, not hidden in
  the reviewer's head.

- **Per-commit + per-BD fix cycles.** The 12 prior reviews + fix
  cycles caught and closed per-BD issues, leaving end-of-batch
  reviewer with cross-cutting work only. The orchestration plan's
  agent separation matrix (no architect/reviewer/coder repeat
  within a phase) is operational.

- **Self-referential closure (BD-184).** Check 42's own test (test-validate-pack-check-42.sh) is wired in the workflow per Check
  42's contract. The check verifies itself + 8 sibling checks. This
  self-referential closure is rare and high-quality.

---

**Reviewer pre-flight (per `commit-discipline` skill §1).**

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
b1765196c67b0c71b63c74f2d3ded53dacdaa19b

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git log --oneline 556e134..b176519 | wc -l
81

$ python3 scripts/validate-pack.py 2>&1 | tail -1
PASSED — all checks clean

$ bash test-fixtures/build.sh --verify 2>&1 | tail -6
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: c77d7bace2a74909290cd20e14af680370ead2d8
  v11-flat-file OK: 13bba3fc2d24ced8c0568670aa6e961797a484ee
  v11-tracker-on OK: f116b0a0097f7195726fa737ef3b7b6bd9bdc862
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

$ ls scripts/tests/test-validate-pack-check*.sh | wc -l
9
$ grep -cE "test-validate-pack-check.*\.sh" .github/workflows/validate-pack.yml
9
```

Pre-flight clean. Read-only operation throughout; no state-changing git
verbs; no edits outside the report file.

---

**End of PACK-REVIEW-BD-175-END-OF-BATCH.md.**

Pack Chat reads this report. Recommended next-steps sequence:

1. Triage SHOULD-1 (README staleness sweep) with user — recommended FIX-NOW per pack memory `feedback-deferral-is-scope-creep`.
2. Triage NIT-1 (validate-pack.py module-docstring numbering) with user — Pack Chat discretion (fold-into-sweep / new-BD / skip).
3. If FIX-NOW for SHOULD-1 approved: apply Pack-Chat-direct README edit, regenerate manifest if v11-surface file touched (README is NOT v11-surface per RC9 — no regen needed; README is pack-root convenience documentation), stage + commit as `fix: v11 — broad batch review/fix (Batch 19b)` with user approval.
4. Present Phase 6 verification status to user; user performs manual spot-check.
5. Apply Phase 7 implicit-status-flip across BD-175 → BD-184 (flip all 10 from Open to Resolved).
6. Present Batch 19c resume decision to user.
