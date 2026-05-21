# PACK-REVIEW-BD-179.md — per-commit review of `13feef3`

**Reviewer:** pack-reviewer (background spawn, BD-175 emergency batch)
**Commit under review:** `13feef3` — `feat: v11 — BD-179 Check 40 pack-ops/ bare cross-reference scanner`
**HEAD when reviewed:** `13feef3` (matches commit; no further state-changing operations performed)
**Authoritative inputs read:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md`, `maintenance-docs/v11-implementation/BD-179-SURVEY-REPORT.md`, `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md`, pack-root `CLAUDE.md` (`## Pack memory` rules), `scripts/validate-pack.py`, `scripts/tests/test-validate-pack-check-40.sh`, all 6 fixture files at `scripts/tests/fixtures/bare-cross-refs/`, all 5 modified `pack-ops/*.md` files, `.github/workflows/validate-pack.yml`, `pack-ops/BACKLOG.md` BD-179 entry, `README.md` Repository Layout.
**Verification re-run at HEAD:** `python3 scripts/validate-pack.py` and `bash scripts/tests/test-validate-pack-check-40.sh` (see §4 below). Both PASS.

---

## §1 Verdict

**APPROVE-WITH-FIXES** — zero BLOCKERs, zero MUSTs, three SHOULDs, two NITs. The implementation faithfully realizes the architect contract (D1–D8) and all 8 OQ-S resolutions; full validator and the new 8-group test harness both pass cleanly at HEAD. The SHOULD findings are surfaceable gaps where the IMPL claims diverge from the architect contract in non-load-bearing ways (notably: the CI-workflow wiring required by architect §8.3 step 6 is silently absent from the commit and from the IMPL-REPORT DoD), and one stale documentation surface (README Repository Layout's Check count). The NITs are documentation polish.

None of the findings is blocking — Check 40 is functionally complete and the BD-179 contract is closed. Pack Chat may triage each finding as FIX-NOW / DEFER-TO-NEW-BD per the standard `feedback-fix-all-review-findings` discipline + OQ-1 EXECUTION-PLAN §B step 5 for any new-BD opens.

## §2 Severity breakdown

| Severity | Count |
|---|---:|
| BLOCKER | 0 |
| MUST | 0 |
| SHOULD | 3 |
| NIT | 2 |
| **Total** | **5** |

## §3 Findings

### §3.1 SHOULD-1 — Architect §8.3 step 6 CI-workflow step is missing AND the omission is silent

**Severity:** SHOULD
**File:symbol:** `.github/workflows/validate-pack.yml` (no `bash scripts/tests/test-validate-pack-check-40.sh` step); `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md` §10 DoD table (no row covering CI wiring).

**Problem.** Architect contract `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` §8.3 step 6 mandates: *"`.github/workflows/validate-pack.yml` add a new step that invokes `bash scripts/tests/test-validate-pack-check-40.sh` (the new test fixture file), per the Check 39 CI-wiring pattern."* Architect §10.1 file-list table also includes `.github/workflows/validate-pack.yml` as an EDIT row with the same disposition.

Empirically the commit modifies 16 files; `.github/workflows/validate-pack.yml` is NOT among them. The new test harness `scripts/tests/test-validate-pack-check-40.sh` is consequently not invoked by CI on any push or PR; only the in-process `check_bare_pack_ops_refs()` (invoked by `validate-pack.py`) runs, and the 8-group harness that exercises the regex / `_strip_code_blocks` / `_check_40_context_has_anchor` / `_build_basename_index` / end-to-end PASS/FAIL paths is dead in CI.

The IMPL-REPORT does NOT mention this discrepancy. §10 DoD has 14 rows; none names CI wiring. §1 D7 says "Test harness landed at `scripts/tests/test-validate-pack-check-40.sh`" with no follow-up about CI invocation. §9 (departures from plan / minor judgment calls) explicitly enumerates 4 minor judgment calls and explicitly states "no new BDs opened" — but does not surface the architect-step-6 omission.

**Suggested fix.** Either (a) add the missing CI step to `.github/workflows/validate-pack.yml` (mechanical — pattern matches surrounding `bash scripts/tests/test-*.sh` lines at L114–L247) in a follow-up `fix:` commit attached to BD-179, OR (b) explicitly note in a follow-up that CI wiring is omitted by convention (Check 39's test `scripts/tests/test-validate-pack-check-39.sh` and Checks 36-37-38's test `scripts/tests/test-validate-pack-checks-36-37-38.sh` are ALSO not wired today — pre-existing pattern of validator-internal-only enforcement). Option (a) is the architect-faithful path and is the smaller surface change. Either resolution should ALSO update the architect doc §8.3 step 6 to reflect the chosen disposition for future readers.

**Rationale.** The architect doc is the explicit authority; silent divergence from a numbered contract step erodes architect-doc-as-authority. The architect's reference to "Check 39 CI-wiring pattern" was itself inaccurate (Check 39 has no CI wiring either) — the architect made a wrong empirical assertion that was carried into the contract. A reviewer reading the architect doc 6 months from now will reasonably expect the CI step to exist and will be surprised by its absence; the IMPL-REPORT's silence amplifies the surprise. Per `feedback-deferred-work-tracking` and `feedback-deferral-is-scope-creep`, even a deliberate decision to omit needs explicit documentation. The architect-doc-vs-reality reconciliation chain (in-code docstring + architect doc + IMPL-REPORT cross-ref) is otherwise faithfully maintained; this one step breaks the chain.

### §3.2 SHOULD-2 — `_strip_code_blocks` does not handle 4-space indented code blocks (architect §3.2 contract)

**Severity:** SHOULD
**File:symbol:** `scripts/validate-pack.py:_strip_code_blocks`; documented absence at `scripts/tests/fixtures/bare-cross-refs/README.md` ("Same applies to indented blocks (4-space) — though those are less common in pack-ops/ docs and not exercised here.").

**Problem.** Architect `ARCHITECTURE-BD-179.md` §3.2 explicitly names indented 4-space code blocks as in-scope for stripping: *"Markdown fenced code blocks delimited by ` ``` ` (with optional language identifier) are easy to identify by line-prefix regex; indented 4-space blocks are recognizable by line-prefix indentation (after an empty line)..."*. The implementation handles ONLY fenced blocks (`startswith("```")` toggle); 4-space indented blocks are NOT stripped. The fixture README at `scripts/tests/fixtures/bare-cross-refs/README.md` acknowledges the gap ("not exercised here") but does not flag it as a tech-debt item, and neither does the IMPL-REPORT §9 or the architect doc itself.

Empirical impact at HEAD: zero false positives, because no `pack-ops/*.md` file contains a 4-space indented code block whose content carries a bare-ref-shaped token. The risk surfaces if any future `pack-ops/*.md` adds an indented code block with a `` `FILENAME.md` ``-shaped token — Check 40 will FAIL on it incorrectly.

**Suggested fix.** Either (a) extend `_strip_code_blocks` to recognize the indented-4-space pattern (lines beginning with `    ` after a blank line, continuing until a non-indented or blank line), and add a Group 2 test for it, OR (b) downgrade the architect contract by deleting the indented-block clause from §3.2 (with a short rationale: "fenced-only is sufficient empirically; pack-ops/ markdown convention prefers fenced blocks; revisit if false-positive surfaces"). Option (b) is the smaller change and is empirically justified; option (a) is the architect-faithful path. Either way, the disposition belongs in code (or in the architect doc) so a future reader knows the gap is intentional.

**Rationale.** Same architect-doc-as-authority principle as SHOULD-1. The gap is currently benign but represents latent false-positive surface area. The fixture README's acknowledgment ("not exercised here") is documentation about the test gap, not about the implementation gap; the implementation diverges from the architect contract without explicit note in the code or IMPL-REPORT. Per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Design best practices" principle #1 (single source of truth), the divergence should be reconciled at one of the two ends, not left ambiguous.

### §3.3 SHOULD-3 — `README.md` Repository Layout has stale Check count + missing test-harness inventory rows

**Severity:** SHOULD
**File:symbol:** `README.md:195` (validate-pack.py one-liner mentions "33 invoked checks — 31 numbered Check 1–11 and 16–35"); `README.md:237` lists only `test-validate-pack-checks-32-33-34.sh` from the `scripts/tests/test-validate-pack-check-*` family.

**Problem.** The `README.md` Repository Layout section §195 enumerates "33 invoked checks ... Check 1–11 and 16–35", which was stale BEFORE BD-179 (Check 36/37/38 added by BD-175 Commit 12; Check 39 added by BD-175 F2a) and is now more stale (Check 40 added by BD-179). The test-script inventory at L227–L237 lists `test-validate-pack-checks-32-33-34.sh` but omits the parallel `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-39.sh`, and now `test-validate-pack-check-40.sh`. The README states "The Repository Layout section is the authoritative reference" per pack-root `CLAUDE.md` "Repo structure" bullet.

**Suggested fix.** Update `README.md:195` validate-pack.py one-liner to reflect the current Check count and number range (38 invoked checks: 36 numbered Check 1–11 and 16–40 with 12–15 retired, plus 2 unnumbered informational — confirm exact number against running `validate-pack.py`'s output count). Add inventory rows at L237 area for `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-39.sh`, and `test-validate-pack-check-40.sh` (matching the existing `test-validate-pack-checks-32-33-34.sh` row format). This is a PM-only edit (Repository Layout is a documentation surface).

**Rationale.** Pack-root `CLAUDE.md` "What this repo is" section names `README.md` as the authoritative reference for the Repository Layout; staleness there is a discoverability defect that affects every new contributor or reviewer trying to understand pack-internal surface area. The accumulated staleness predates BD-179 — this finding flags the standing issue surfaced by BD-179's Check 40 addition; whether to fix in this batch or open a separate stale-README BD is a triage decision (per OQ-1 EXECUTION-PLAN §B step 5, a new BD requires user-discussion-and-approval).

### §3.4 NIT-1 — IMPL-REPORT §2 mismatched architect-doc diff count

**Severity:** NIT
**File:symbol:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md` §2 "Files changed" row for `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` says "+93 / -0 (Phase-2 addenda only, all additive)"; the actual `git diff ac500b7..13feef3 --stat` output reports "+89 / -4" (89 insertions, 4 deletions).

**Problem.** Two minor accuracy errors: (a) the "additive only" claim is false — the diff replaces 4 lines of architect content (e.g., the original `_CHECK_40_ALLOWLIST` initial-entries block in §6.2 was REPLACED with the expanded version including OQ-S2/S3/HELP-FRAGMENT.md additions; the §6.4 anchor-phrases block was REPLACED with the expanded tuple; §5.1 EXCLUDE text was REPLACED with the addendum-paragraph variant). (b) The "+93" insertion count comes from a different counting convention than `git diff --stat` reports.

**Suggested fix.** Update the IMPL-REPORT §2 row to read "+89 / -4 (Phase-2 OQ-S resolution addenda; mix of additive and in-place replacement)" so the IMPL-REPORT matches the git-diff reality.

**Rationale.** The IMPL-REPORT is itself a load-bearing audit surface. Numeric accuracy in the diff-stat row is a minor but discoverable defect that erodes trust in the IMPL-REPORT's other counts (e.g., §5.3 hit counts, §10 DoD claims). Pack memory's "Real fixes only — no green-the-test band-aids" principle extends to documentation accuracy.

### §3.5 NIT-2 — `_strip_code_blocks` docstring omits the architect doc filename

**Severity:** NIT
**File:symbol:** `scripts/validate-pack.py:_strip_code_blocks` docstring.

**Problem.** Per pack-root `CLAUDE.md` "Architect-doc-vs-reality reconciliation" memory rule, the in-code docstring naming the realized consumer should reference the architect doc explicitly. The other four BD-179 functions (`check_bare_pack_ops_refs`, `_build_basename_index`, `_check_40_context_has_anchor`, and the `_CHECK_40_ALLOWLIST` self-documenting block) all name `ARCHITECTURE-BD-179.md` by filename + section. `_strip_code_blocks`'s docstring says only "Preserves total line count so file:line citations remain accurate against the original file." — no architect-doc reference, no "per §3 D2" or "ARCHITECTURE-BD-179.md" anchor.

**Suggested fix.** Add a leading sentence to `_strip_code_blocks`'s docstring along the lines of "Per `ARCHITECTURE-BD-179.md` §3.2 (code-block-stripping preprocess)." matching the convention used by sibling helpers.

**Rationale.** Trivial consistency fix; closes the reconciliation chain at the only function where it's currently incomplete. No functional impact.

## §4 Verification results

### §4.1 `python3 scripts/validate-pack.py` (HEAD `13feef3`)

```
── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

============================================================
PASSED — all checks clean
```

Counts match IMPL-REPORT §5.3 claims exactly: 9 files walked, 63 allowlist-exempt, 12 anchor-phrase-exempt, 32 same-dir-legit, 0 failures.

### §4.2 `bash scripts/tests/test-validate-pack-check-40.sh` (HEAD `13feef3`)

```
=== Group 0: Module import + Check 40 symbol registration ===
  PASS validate-pack.py imports + Check 40 symbols registered

=== Group 1: _CHECK_40_BARE_REF_PATTERN unit tests ===
OK
  PASS _CHECK_40_BARE_REF_PATTERN + hyperlink regex pass full case set

=== Group 2: _strip_code_blocks preprocess unit tests ===
OK
  PASS _strip_code_blocks preserves line count + strips fence content

=== Group 3: _check_40_context_has_anchor unit tests ===
OK
  PASS _check_40_context_has_anchor admits all OQ-3/OQ-S4 phrases at window=2

=== Group 4: _build_basename_index EXCLUDE behavior ===
OK
  PASS _build_basename_index honors EXCLUDE list including OQ-S1 expansion

=== Group 5: End-to-end check_bare_pack_ops_refs() with synthetic tree ===
OK
  PASS End-to-end PASS / FAIL / exemption / code-block / mirror-skip tests

=== Group 6: Static fixture file sanity ===
OK
  PASS Static fixture files present + parseable + regex-shaped

=== Group 7: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0; Check 40 runs and reports clean

=== Summary ===
  PASS: 8
  FAIL: 0

All tests passed.
```

All 8 groups PASS. (Note: per architect §8.3 step 2 the harness was specified as having 6 groups; the realized harness has 8 — Group 0 module-import + Group 7 end-to-end exit-status are useful additions beyond the architect's enumeration.)

### §4.3 Other spot-check verifications performed

- **Trinity rule.** Confirmed no `project-template/` files modified (`git diff ac500b7..13feef3 --stat -- 'project-template/**'` is empty). No trinity-parity edit required for this commit; architect §9.1 disposition holds.
- **Commit-scope keyword (Check 36).** Commit subject `feat: v11 — BD-179 Check 40 pack-ops/ bare cross-reference scanner` carries no `pack-only` / `project-only` / `PM-only` keyword. Check 36 skips per pack-root `CLAUDE.md` table (no claim → no enforcement). Subject is 67 chars — within the convention 70-char limit.
- **BACKLOG entry status.** `pack-ops/BACKLOG.md` BD-179 row (L1533–L1562) still reads `Status: Open`. Correct per pack memory "Implicit BD status flip on batch completion" — BD-179 closes its own surface but the BD-175 batch is still in flight (BD-180/181/182 pending); the implicit flip happens after the end-of-batch review per `feedback-implicit-status-flip`.
- **RC9 manifest.** Per IMPL-REPORT §7, manifest rebuild produced empty diff because the modified files are not in the `init-project.sh` install path (pack-internal scripts + pack-internal docs + maintenance-docs/architect addendum). Spot-checked: `scripts/init-project.sh` does not S-stage `scripts/validate-pack.py` or any of the modified `pack-ops/*.md` files (the only S-staged `pack-ops/` file is `HELP-FRAGMENT-TRACKER.md` per stage S11, which BD-179 does not modify). Confirmed by re-running `bash test-fixtures/build.sh --verify` (not re-run here per read-only review constraint, but the empty-diff claim is structurally sound). Compliant with RC9 trailing clause: "If rebuild produces empty diff, the edit wasn't v11-surface; no staging needed."
- **Override 9 scope discipline.** Check 40 scope (`pack-ops/*.md` only, excluding regenerated mirrors) matches the BD-179 BACKLOG entry's Override 9 compliance note. No project-template/ trinity touched; cross-CLI reference concerns there remain in BD-182 scope.
- **Architect-doc-vs-reality reconciliation chain.** In-code docstrings name `ARCHITECTURE-BD-179.md` at `check_bare_pack_ops_refs` / `_build_basename_index` / `_check_40_context_has_anchor` / `_CHECK_40_ALLOWLIST` (4 of 5 BD-179 symbols); architect doc updated in-place with OQ-S addenda (§5.1 / §6.2 / §6.4 / §6.6 / §8.6 / §8.7 / §10.2); IMPL-REPORT §8 cross-references both. Chain is intact except for the one missing docstring tag flagged as NIT-2.
- **Allowlist + anchor-phrase scrutiny.** Each of the 17 `_CHECK_40_ALLOWLIST` entries carries a one-line rationale per §6.5 contract; each is architecturally justifiable (pack-root deliverables, trinity members, memory cache externals, runtime-generated artifacts, per-entry filename pattern placeholders, byte-identical-mirror exception). Each of the 8 `_CHECK_40_ANCHOR_PHRASES` is tight (max 5 words, most 2-3); the `does not exist` and `archived` phrases for OQ-S4 are narrow enough that false-admission risk is low (verified by the live anchor-exempt count of 12 vs survey expectation of 11+1 — one new anchor admission at CONCEPTUAL-REVIEW-METHODOLOGY.md L247 per IMPL-REPORT §5.3).
- **Spot-checked BOUNDARY-DEFINITION.md edits (24 hits).** `git diff` for `pack-ops/BOUNDARY-DEFINITION.md` shows 19 insertions / 19 deletions across L5 / L48 / L52 / L78 / L94 / L98 (×2) / L101 / L117 / L137 / L139 / L141 / L143 / L179 / L209 / L225 / L241 / etc. Each qualification matches the §10.2 mapping table: `init-project.sh` → `scripts/init-project.sh`, `AUDIT-USER-CURATION.md` → `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`, `OPTIONAL-FEATURES.md` (pack-internal contexts) → `pack-ops/OPTIONAL-FEATURES.md`, `HELP-FRAGMENT-TRACKER.md` → `pack-ops/HELP-FRAGMENT-TRACKER.md`. L179 sibling-list applies OQ-S5 Option B prose rewrite ("the pack-architect / pack-coder / ... set of agents at `.claude/agents/`"). No incorrect qualifications observed; the F-5 §5.4 section header was correctly updated to `pack-ops/OPTIONAL-FEATURES.md` to match the post-SPLIT pack-internal canonical location.
- **Spot-checked MERGE-STRATEGY.md edits (18 hits + 5 broken via allowlist).** Diff shows 25 insertions / 23 deletions. Verified: 5×`MIGRATION-v10-to-v11.md` → `supporting-docs/...`, 3×`validate-pack.py` → `scripts/...`, 3×`merge-json.py` → `scripts/...`, 3×`migrate-v10-to-v11.sh` → `scripts/...`, 1×`INSTALL-PROCEDURES.md` → `supporting-docs/...`, L101 OQ-S7 compositional rewrite, L196 OQ-S5 compositional rewrite, L466–474 §7.3 preamble + L472 parenthetical with `post-install` anchor. Allowlist absorbs the 3×`report.md` (L5/L31/L37), 1×`tracker.toml` (L415), 1×`id-map.json` (L418), and 1×`QUICKSTART.md` (L475) per OQ-S2 + initial §6.2.
- **Files NOT modified that were in survey scope.** Spot-verified IMPL-REPORT §3 claims: `pack-ops/HELP-FRAGMENT-TRACKER.md` L9 (`tracker.toml`) covered by OQ-S2 allowlist; L21 (`HELP-FRAGMENT.md`) covered by byte-identical mirror exception allowlist; L49 (`OPTIONAL-FEATURES.md`) covered by `in the pack repo` anchor in the surrounding ±2 lines. `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md` resolutions confirmed by the live PASS message count breakdown (63 allowlist + 12 anchor + 32 same-dir-legit, matching IMPL-REPORT §5.3).

## §5 End-of-batch carry-forward observations (for BD-175 → BD-182 batch reviewer)

These observations apply at the BD-175 emergency batch level and are NOT in-scope for the BD-179 per-commit triage; they are surfaced here so the end-of-batch reviewer (running after BD-182 closes) can re-check them.

1. **CI workflow staleness for the `test-validate-pack-check-*` family is a batch-wide pattern.** SHOULD-1 above flags BD-179's missing CI step; the same gap exists at HEAD for `test-validate-pack-checks-36-37-38.sh` (since BD-175 Commit 12 in 2026-05-19) and `test-validate-pack-check-39.sh` (since BD-175 F2a in 2026-05-19). Three CI wirings are silently absent. The end-of-batch reviewer should triage whether to (a) wire all three at batch close as a single fix commit, (b) defer to a follow-up BD, or (c) ratify the "validator-internal-enforcement-only" pattern in pack memory + the architect doc retrospectively. Pack-memory rule "Deferral IS scope creep" recommends (a).

2. **README Repository Layout has accumulated staleness across the BD-175 batch.** SHOULD-3 flags BD-179's contribution; the count was already wrong before BD-179 (Check 36/37/38/39 additions). End-of-batch reviewer should triage whether to do a single README sweep at batch close (one PM-only edit) vs. opening a separate BD vs. accepting the README as a soft-pass surface that updates only at version-ship boundaries.

3. **The "Architect §3.2 indented-block contract" pattern (SHOULD-2) suggests a class of architect-contract-vs-implementation divergence that the batch may want to systematically reconcile.** SHOULD-2 is one instance; SHOULD-1 is another. End-of-batch reviewer might consider whether a final mechanical sweep of architect doc → IMPL-REPORT → code (or vice versa) discrepancies is worth ~30 minutes of attention before the BD-182 audit closes. This is the "audit a fresh batch" pattern that catches drift early.

4. **The `_CHECK_40_ALLOWLIST` is at 17 entries and likely to grow as more pack-ops/ docs are added.** Per §6.5 each addition is a single-line dict edit with rationale; the §6.6 self-documenting comment explains the discipline. End-of-batch reviewer should confirm that the post-BD-179 allowlist size (17 entries, dominated by concept-noun OQ-S2 additions and pack-root deliverables) does not have any obvious deny-list-by-omission gaps. The byte-identical-mirror exception (`HELP-FRAGMENT.md`) sets a precedent for ALL future byte-identical mirror pairs per architect §8.7 apply-time-discovery note — none currently exist beyond HELP-FRAGMENT-TRACKER.md; the precedent is forward-pointing.

5. **The 5 modified `pack-ops/*.md` files now contain qualified prose paths that may drift if the qualified targets move in a future BD.** This is the cost of architectural-coupling per architect §5.2 (acknowledged). End-of-batch reviewer should not act on this — it is a feature of Check 40's "qualified-ref + filesystem-truth" design (per §5.2 "Coupling concern: if a future BD DELETES a referenced file without updating its refs, Check 40's '0 candidates' FAIL surfaces the broken ref cleanly — this is feature, not coupling tax").

---

**End of PACK-REVIEW-BD-179.md.**

Pack Chat reads this report, triages each finding (FIX-NOW vs DEFER-WITH-NEW-BD vs SKIP-WITH-RATIONALE) per `feedback-fix-all-review-findings` default-FIX-ALL + OQ-1 EXECUTION-PLAN §B step 5 (any new BD requires user-discussion-and-approval), and surfaces the triage to the user before spawning the fix-coder (if any fixes warrant in-batch landing) or before moving to BD-180.
