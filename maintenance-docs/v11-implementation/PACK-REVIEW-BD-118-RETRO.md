# PACK-REVIEW-BD-118-RETRO.md — retroactive per-BD review

**BD:** BD-118 — CI wiring for persona contracts + fixture verification
**Original commit:** `b93d22b` (2026-05-12, "feat: v11 — BD-118 wire fixture-manifest verify + RELEASE-GATE traceability into CI")
**Reviewer:** pack-reviewer (retroactive per-BD pass, Batch 21c)
**Review date:** 2026-05-15
**Methodology:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` — 6 dimensions + touch-point classification.
**Review scope:** BD-118 in isolation. Out of scope: BD-115/116/117/119/163 except as integration touchpoints.
**Excluded by prompt:** prior `PACK-REVIEW-BD-118.md` and any sibling BD reviews — not read.

---

## 1. Scope declaration

**In-scope BD:** BD-118 only.

**In-scope file changes (per `git show --stat b93d22b`):**

- `.github/workflows/validate-pack.yml` (+29/-3) — primary surface.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-118.md` (new, sweep-exempt workflow artifact).

**Touch points read for context (not modified by BD-118 but consumed by its wiring):**

- `test-fixtures/build.sh` (`_verify`, `_update_manifest`, `main` dispatch) — owned by BD-115/116 surface; SHARED-RO from BD-118's perspective.
- `scripts/test-persona-contracts.sh` and `scripts/persona-contracts/contract-*.sh` — owned by BD-116; SHARED-RO from BD-118.
- `maintenance-docs/v11-implementation/RELEASE-GATE.md` — owned by BD-117; SHARED-RO from BD-118 (the new step name + header comment cite items 3/4/5).

**Out-of-scope concepts:**

- BD-114 dry-run-migration.sh wiring (intentionally excluded from CI per BD-117 spec; correctly absent from BD-118).
- BD-163 step-ordering invariant (post-BD-118; refactored migrator-skills placement and added the second header invariant block).
- Validator check count drift (current: 28 numbered headers; the BD-118 commit's "31 Checks" string was correct at commit time).

---

## 2. Methodology notes

**Dimensions exercised** (per `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` §"The six review dimensions"):

- (a) Completeness — verified the BD-118 spec's 5 tasks were all implemented per `BACKLOG.md` line 1186-1194 and `IMPLEMENTATION-REPORT-BD-118.md` §2.
- (b) Edge cases (bounded) — failure-mode coverage for each new/modified step in CI.
- (c) Touch points + cross-concept impact — manifest.txt as a SHARED-RO artifact owned by build.sh; cross-references to RELEASE-GATE items.
- (d) Pack rule adherence — no untrusted input in workflow, no secrets, `if: always()` discipline, BD-NNN comment markers, no trinity files touched.
- (e) Design best practice adherence — failure attribution (principle: clear separation of concerns), idempotency, single-source-of-truth for the RELEASE-GATE wiring map.
- (f) Concept-specific — CI workflow as a release-gate proxy: does each step ACTUALLY verify what its name claims to verify on a fresh CI runner?

**Tools used to ground findings:**

- `git show b93d22b -- <file>` — exact BD-118 diff and commit message.
- `git show b93d22b:test-fixtures/build.sh` — build.sh state at commit time (verified unchanged in current HEAD vs commit).
- `Read` on workflow current state — confirmed wiring still present.
- `Read` on RELEASE-GATE.md and CONCEPTUAL-REVIEW-METHODOLOGY.md.
- `grep` on manifest.txt consumers (`_verify` is the only consumer in scripts/ + test-fixtures/).
- `cat .gitignore` and `git ls-files test-fixtures/manifest.txt` — confirmed manifest.txt is committed (tracked), not gitignored.
- `python3 scripts/validate-pack.py | grep "^── Check"` — current Check headers (28; not relevant to BD-118 finding directly).

---

## 3. Findings

### Finding 1 — `fixture manifest verify` step is structurally tautological in CI (cannot detect manifest drift)

- **Severity:** **MUST**
- **Dimension:** (b) Edge cases (bounded) and (f) Concept-specific (CI step must verify what its name claims).
- **Touch-point class:** SHARED-RO — the bug is in BD-118's USE of `build.sh` (read-only consumer), not in build.sh itself; the fix can land in BD-118's surface alone.
- **Evidence:**
    - `.github/workflows/validate-pack.yml` lines 160-165 (current state) — `tests` job runs `bash test-fixtures/build.sh --all --clean` (step a, line 162) immediately followed by `bash test-fixtures/build.sh --verify` (step b, line 165), both with `if: always()`.
    - `test-fixtures/build.sh` lines 860-866 (`main()`) — the `--all` branch terminates with `_update_manifest`, which **writes** `$THIS_DIR/manifest.txt` from the freshly built fixtures' SHAs (lines 702-722). It does so unconditionally; there is no `--no-update-manifest` flag.
    - `test-fixtures/build.sh` lines 725-753 (`_verify`) — reads `$THIS_DIR/manifest.txt` from disk and compares to the local fixtures.
    - `test-fixtures/.gitignore` lines 1-15 — `!manifest.txt` exception confirms manifest.txt is committed and tracked. `git ls-files test-fixtures/manifest.txt` returns the path.
    - On a fresh GitHub Actions runner: checkout pulls the committed `manifest.txt` (with the canonical expected SHAs); step (a) overwrites that file with the freshly-built SHAs; step (b) then compares freshly-built fixtures against the just-written manifest. The comparison passes by construction, regardless of whether the committed manifest matched.
- **Description:** The intent of step (b), per the workflow header comment lines 21-28 ("(b) fixture manifest verify — compares rebuilt SHAs vs committed manifest.txt (catches manifest drift)") and per `RELEASE-GATE.md` Item 5 ("This catches non-deterministic fixture drift (timestamps, locale, env-var bleed) that would otherwise silently invalidate downstream tests") is to detect drift between the **committed** `test-fixtures/manifest.txt` and the rebuilt fixtures. As wired, step (b) cannot detect that condition: by the time `--verify` runs, the committed manifest on disk has been replaced by step (a)'s `_update_manifest` call, so `_verify` reads a manifest that was just generated from the very SHAs it is about to compare. The only narrow case where step (b) catches anything net-new is when step (a) **partially** fails such that `_update_manifest` is never reached (because `_build_one` calls `die` mid-loop), leaving the committed manifest intact on disk for `_verify` to read; that case is already turned red by step (a)'s exit code, and step (b) is incidental noise rather than a distinct signal.

  Failure-mode-coverage table the workflow header (line 26-28) claims:
    - (a) red → builder non-determinism. **Holds.**
    - (b) red → "missing manifest update / fixture content drift." **Does not hold in CI.** Step (b) cannot reach this state when step (a) succeeded; step (a) overwrote the committed manifest with the freshly-built SHAs.
    - (c) red → pack behavior regression. **Holds** (contracts use `--for-contract` sandboxes, independent of the manifest).
- **Suggested fix (one of):**
    - **Option A (preferred — minimal workflow edit):** between steps (a) and (b), restore the committed manifest from git so `_verify` reads the canonical version, e.g.,

      ```yaml
      - name: restore committed manifest before verify (BD-115)
        if: always()
        run: git checkout HEAD -- test-fixtures/manifest.txt
      - name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
        if: always()
        run: bash test-fixtures/build.sh --verify
      ```

      Pros: zero change to `build.sh`; semantics match the workflow header comment exactly; the verify step now actually compares freshly-built SHAs against the committed manifest.
      Cons: introduces a `git checkout HEAD -- <path>` (read-only-form, allowed under commit-discipline §3) but worth a comment line explaining why.
    - **Option B (preferred for long term — fix in build.sh):** add a `--no-update-manifest` flag (or split `_update_manifest` out of the `--all` happy path entirely) so the workflow can run `bash test-fixtures/build.sh --all --clean --no-update-manifest` and `--verify` reads the unmodified committed manifest. Larger surface area (touches BD-115's owned file) but eliminates the semantic ambiguity at the source.
    - **Option C (lightweight defense-in-depth):** stash the committed manifest before step (a) and diff against the post-build manifest as the verify step:

      ```yaml
      - name: snapshot committed manifest (BD-115)
        if: always()
        run: cp test-fixtures/manifest.txt /tmp/manifest.committed.txt
      - name: build test fixtures (BD-115/116/117)
        if: always()
        run: bash test-fixtures/build.sh --all --clean
      - name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
        if: always()
        run: diff -u /tmp/manifest.committed.txt test-fixtures/manifest.txt
      ```

      This bypasses `--verify` entirely and uses `diff` as the gate. Equivalent semantics, easier to audit.

  Recommendation: **Option A** — single new step, leaves BD-115's surface untouched, makes the wiring honest about what it verifies. Pack Chat to schedule a fix BD or fix-in-place per the standing rules.
- **Cross-concept impact:**
    - BD-115 (build.sh `--verify` and `--update_manifest` semantics): fix in Option A leaves BD-115 untouched. Option B requires a BD-115 surface change.
    - BD-117 (RELEASE-GATE item 5 wording): item 5's pre-tag command is `bash test-fixtures/build.sh --verify` run **standalone** (no preceding `--all`), which works correctly in a maintainer's working tree where fixtures already exist. The item-5 spec is fine; the CI realisation deviates from it.
    - No other concept consumes manifest.txt (`_verify` is the sole consumer per grep).
- **Rule/principle violated:**
    - `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` §"Design best practices" #1 (single source of truth) — the workflow comment claims a property the wiring does not deliver; the comment and the actual semantics are now divergent sources of truth.
    - General principle: a CI step's name and emitted failure mode must correspond to the condition it actually exercises. The current step's red light cannot signal "manifest drift" in CI.

### Finding 2 — README and `_verify` doc-string mismatch (rebuild claim)

- **Severity:** **NIT**
- **Dimension:** (a) Completeness (documentation completeness of the surface BD-118 wires) and (e) Design best practice (single source of truth).
- **Touch-point class:** SHARED-RO — `test-fixtures/README.md` is BD-115's surface, but BD-118's wiring inherits the doc claim by referencing the same `--verify` verb in the workflow header comment.
- **Evidence:**
    - `test-fixtures/README.md` line 112: "`build.sh --verify` rebuilds + compares against the committed manifest."
    - `test-fixtures/build.sh` lines 839-842 (`main`): `--verify` calls `_verify` and exits; **no rebuild is performed**.
- **Description:** README says `--verify` rebuilds; code does not rebuild. The workflow author relied on the README claim for the failure-mode mapping comment (header lines 21-28). If BD-118's verify step were ever moved to run **before** `--all --clean`, the README's "rebuilds + compares" claim would suggest verify is sufficient on its own, but in fact the fixtures wouldn't exist on a fresh runner and `_verify` would `warn ... not present locally` for every fixture and return non-zero. Today the workflow happens to run `--all` first, so the gap is latent.
- **Suggested fix:** update `test-fixtures/README.md` line 112 to read "`build.sh --verify` compares the local fixture HEAD SHAs against the committed manifest. It does **not** rebuild — run `build.sh --all` first if you want a fresh-build comparison." This is a 1-line README edit owned by BD-115's surface; not strictly inside BD-118 scope, but exposed by BD-118's CI consumption. Pack Chat may either fold into a fix BD or queue as tech debt against BD-115's owned docs.
- **Cross-concept impact:** BD-115 doc surface only. No code change required for this finding.
- **Rule/principle violated:** CONCEPTUAL-REVIEW-METHODOLOGY.md §"Design best practices" #1 (single source of truth) — README and code disagree on the verb's semantic.

### Finding 3 — Workflow header's "31 Checks" hardcoded count is a recurring drift surface (no BD-118 regression at commit time, but the pattern itself is a maintenance hazard)

- **Severity:** **NIT** (advisory; no BD-118 defect; offered as a methodology-friction note rather than a fix BD-118 must own).
- **Dimension:** (e) Design best practice — single source of truth.
- **Touch-point class:** OWNED by BD-118 (header comment lines 6 + step name line 78 are exactly what BD-118 last touched).
- **Evidence:**
    - `.github/workflows/validate-pack.yml` line 6 (current): "validate: runs scripts/validate-pack.py (31 structural Checks)".
    - `.github/workflows/validate-pack.yml` line 78 (current): "Run pack validation (31 Checks)".
    - `python3 scripts/validate-pack.py | grep -E "^── Check" | wc -l` → **28** numbered/unnumbered headers in the current validator output (Checks 1-11, 16-32 with gaps + two unnumbered "Check:" lines).
    - The BD-118 commit message acknowledges this drift hazard explicitly: "Stale '26 Checks' → '31 Checks' in two header strings — count was last touched at BD-119; the reframe cluster + BD-146 took it to 31." So BD-118 itself was already a count-fix tag-along.
- **Description:** BD-118 correctly fixed the stale `26 Checks` strings to `31 Checks` at commit time, AND added 19 lines of header comment that further entrenches the convention of putting the check count in workflow strings. Three BDs later (BD-146 era already factored in by BD-118; subsequent BDs have nudged the count again), the count is once again drifted. This is a structural maintenance hazard the BD-118 surface co-owns: every time someone adds a numbered Check to `validate-pack.py`, a maintainer must remember to update two strings in `validate-pack.yml`. This is a guaranteed-to-be-stale convention.
- **Suggested fix (advisory, not a BD-118 must-fix):** drop the count from the workflow strings entirely, e.g.,
    - line 6 → `# - validate: runs scripts/validate-pack.py (structural Checks)`
    - line 78 → `name: Run pack validation`

  Or, if the count signal is genuinely valuable to the GHA UI, derive it from the validator at runtime:

  ```yaml
  - name: Run pack validation
    run: |
      python3 scripts/validate-pack.py
      n=$(python3 scripts/validate-pack.py 2>&1 | grep -cE '^── Check')
      echo "::notice::validate-pack ran $n Checks"
  ```

  Prefer the deletion: the count is not load-bearing for any consumer.
- **Cross-concept impact:** purely cosmetic; no consumers depend on the strings.
- **Rule/principle violated:** CONCEPTUAL-REVIEW-METHODOLOGY.md §"Design best practices" #1 (single source of truth) — the validator's actual Check count is the one source of truth; the workflow string is a manually-mirrored copy that drifts.

### Finding 4 — Workflow header lists "items 1/2 NOT in CI" but does not call out item 4 self-reference subtlety

- **Severity:** **NIT**
- **Dimension:** (a) Completeness — header documentation completeness.
- **Touch-point class:** OWNED by BD-118 (header comment lines 10-19).
- **Evidence:**
    - `.github/workflows/validate-pack.yml` lines 10-19 (current) — header maps items 3/4/5 to CI steps and explains why 1/2 are not in CI.
    - Item 4 is documented as: "Gate item 4 (BD-118 CI green) → this workflow itself."
    - `RELEASE-GATE.md` lines 159-185 (Item 4) — "Asserts: the GitHub Actions workflow `.github/workflows/validate-pack.yml` shows both the `validate` and `tests` jobs green on the **exact candidate-tag SHA**."
- **Description:** Item 4's CI-eligibility is fundamentally different from items 3 and 5: items 3 and 5 are run **by** the workflow as `tests` job steps; item 4 is the **state of the workflow** itself on the candidate-tag SHA. The header comment list-form treats all three as if they were the same kind of thing ("Gate item N → step Y"), which is mildly misleading. A reader scanning the header could plausibly look for an "item 4 step" inside the file and not find one.
- **Suggested fix:** clarify line 13 with a parenthetical, e.g.,

  ```
  - Gate item 4 (BD-118 CI green) → this workflow's overall status on the
    candidate-tag SHA (no dedicated step; the workflow's own pass/fail is
    the signal).
  ```

  One-line clarification.
- **Cross-concept impact:** none; documentation-only.
- **Rule/principle violated:** none specifically; clarity nit only.

### Finding 5 — Rebuild step uses `--all --clean` without manifest pre-snapshot (defense-in-depth gap, related to Finding 1)

- **Severity:** **SHOULD** (related to Finding 1 but separately actionable).
- **Dimension:** (b) Edge cases (bounded) and (e) Design best practice — idempotency / round-trip safety (#2).
- **Touch-point class:** OWNED by BD-118 (workflow step composition).
- **Evidence:**
    - `.github/workflows/validate-pack.yml` line 160-162 — step (a) `bash test-fixtures/build.sh --all --clean`. The `--clean` flag wipes-and-rebuilds; combined with `_update_manifest` at the end of `--all`, the runner's `manifest.txt` is mutated regardless of whether the committed manifest matches.
    - On a CI runner, this is mostly benign (the runner is ephemeral). On a self-hosted runner or a developer who runs `act` locally to reproduce CI, the user's working-tree `test-fixtures/manifest.txt` ends up modified. They might `git diff` and see drift that was caused by the simulated run, not by their local edits.
- **Description:** Independent of Finding 1's tautology issue, the BD-118 workflow uses a side-effecting build verb (`--all --clean`, which writes `manifest.txt`) at CI step depth without isolation. A side-effecting CI step that touches a tracked file is a design smell because (a) the round-trip "run CI locally → check git status" is dirty, (b) it makes Finding 1's fix harder to spot. The workflow header makes no mention of the side effect.
- **Suggested fix:** Combine with Finding 1's fix. If Option A (snapshot/restore) is taken, add a single header line documenting that step (a) mutates `manifest.txt` on the runner and step (a.5) restores it before verify. If Option B (build.sh `--no-update-manifest` flag) is taken, the side effect goes away naturally. Either way, document in the workflow header that step (a)'s effect on `manifest.txt` is intentional / managed.
- **Cross-concept impact:** BD-115 (build.sh) if Option B is chosen; otherwise none.
- **Rule/principle violated:** CONCEPTUAL-REVIEW-METHODOLOGY.md §"Design best practices" #6 (idempotency) — running the workflow modifies a tracked file in the working tree without flagging it.

### Finding 6 — Step name uses non-ASCII em-dash inside the workflow header but plain ASCII inside step names (cosmetic consistency)

- **Severity:** **NIT** (truly cosmetic; will likely be declined).
- **Dimension:** (e) Design best practice — convention consistency.
- **Touch-point class:** OWNED by BD-118.
- **Evidence:**
    - `.github/workflows/validate-pack.yml` line 6: "`validate: runs scripts/validate-pack.py (31 structural Checks)`" (no em-dash).
    - Lines 22-25 use em-dashes ("`—`") in the comment block to separate name from rationale.
    - Step names at lines 162-175 are pure ASCII.
- **Description:** Pure cosmetic. The header comment uses em-dashes; step names do not. No semantic effect; YAML parses fine; GHA UI renders both correctly.
- **Suggested fix:** decline; not worth a touch.
- **Cross-concept impact:** none.
- **Rule/principle violated:** none.

---

## 4. Acknowledgements (what BD-118 got right)

- **`if: always()` on every step.** Failures attribute per surface; one step's failure does not mask another's. Verified at every new and modified step.
- **Step ordering rationale documented in-line.** The header comment block (lines 21-28) is a textbook example of self-documenting wiring; the (a)/(b)/(c) failure-attribution map is exactly the kind of guidance a future maintainer needs.
- **Persona-contracts step uses the aggregator (`scripts/test-persona-contracts.sh`)**, not the three individual contract scripts. Reduces step count, ensures all three always run, single exit code per BD-116's design.
- **BD-114 real-OT dry-run correctly NOT added.** The header comment explicitly documents the exclusion (lines 16-19) so a future maintainer is unlikely to "helpfully" add it. This is exactly the right discipline for a pre-tag-only manual gate.
- **No untrusted input, no secrets.** The workflow's existing security note still holds; BD-118 added no new attack surface.
- **No trinity files touched.** BD-118 stays in its lane; no PM-only files modified.
- **Step name traceability suffix (`RELEASE-GATE item N`).** Makes the GHA UI scan-readable for release engineers verifying gate items.
- **Validator + adjacent regression evidence.** IMPLEMENTATION-REPORT-BD-118.md §3.2 records 31/31 validator + 210/210 adjacent test cases passing.

---

## 5. Coverage notes

**In scope but NOT exhaustively reviewed:**

- The detailed semantics of `_build_one` and per-fixture builders inside `build.sh` — those are BD-115/116 surfaces; only the dispatch logic and `_verify` / `_update_manifest` were inspected because they are what BD-118's wiring consumes.
- The persona-contracts internals — only entry point (`test-persona-contracts.sh`) and sandbox-materialization mechanism were sampled; per-contract assertions are BD-116 scope.
- Checks emitted by `validate-pack.py` — only their count was sampled (Finding 3); content review is BD-159 / per-check BD scope.
- BD-163's later step-ordering invariant block (workflow header lines 30-49) — present in the current file but added post-BD-118. Out of scope for BD-118 review.

**Out of scope per prompt and not reviewed:**

- Prior `PACK-REVIEW-BD-118.md` and any sibling per-BD reviews (excluded to avoid bias).

---

## 6. Re-architect summary (ARCH findings)

**No `ARCH` findings.** Finding 1 (the tautology) is a single-concept fix that lands inside BD-118's owned surface (workflow file) or, optionally, with a small additive change to BD-115's build.sh. Neither path requires re-architecture across multiple concepts.

---

## 7. Methodology friction notes

- **Prompt phrasing on `--verify` was correct but the implementation report's success-criteria evidence (IMPL-REPORT §3.2) showed the verify step "passing" without distinguishing tautological-pass from real-pass.** The reviewer-pattern is to interrogate "did the test exercise the failure mode it claims to?" — when a CI step is added to catch X, but X is structurally unreachable from the surrounding wiring, the green light is misleading. Future per-BD review prompts for CI work should explicitly call this out: "for every new CI step, identify a concrete change that would turn it red, and confirm the wiring would actually surface that change."
- **The retroactive review benefited from being done in isolation from the prior PACK-REVIEW-BD-118.md.** The prior review (per the prompt's exclusion rule) was withheld; this allowed Finding 1 to surface fresh. Per the user's CONCEPTUAL-REVIEW-METHODOLOGY.md §"No prior reviews to reviewer" rule, this is the intended outcome.
- **No prompt-level gap.** The 6-dimension scaffold + touch-point classification + ARCH-trigger heuristic worked for this one-file CI change. Time-box per finding (5 min reasoning) was respected.
- **Review-fix loop reminder (per CLAUDE.md "One review/fix cycle per batch"):** since this is a retroactive review against a shipped commit, the standing process is: Pack Chat reads this report, decides per finding (fix-in-current-batch vs queue-as-tech-debt); fix-it-now lands in the current Batch 21c session; nothing here triggers a separate BD unless Pack Chat / user opens one. Findings 2 (README) and 3 (count drift) are arguably tech-debt / next-batch material; Finding 1 (MUST) merits in-batch fix.

---

## 8. Summary of findings

| # | Severity | Dimension | Touch class | Description |
|---|---|---|---|---|
| 1 | **MUST** | (b) (f) | SHARED-RO | `fixture manifest verify` is tautological in CI — `--all` overwrites manifest before `--verify` reads it; cannot detect committed-manifest drift. |
| 2 | NIT | (a) (e) | SHARED-RO | `test-fixtures/README.md` line 112 says `--verify` rebuilds; code does not. |
| 3 | NIT | (e) | OWNED | "31 Checks" hardcoded count drifts; consider deletion or runtime derivation. |
| 4 | NIT | (a) | OWNED | Header item-4 description doesn't flag the self-reference (no dedicated step). |
| 5 | SHOULD | (b) (e) | OWNED | `--all --clean` mutates a tracked file in the runner; defense-in-depth + documentation gap (related to #1). |
| 6 | NIT | (e) | OWNED | Cosmetic: em-dash usage between header and step names. |

**Verdict:** **NOT clean** — one MUST finding (#1) plus one SHOULD (#5, related). The other four are nits, several declinable. The MUST finding is structural (the new CI step does not actually verify what its name + RELEASE-GATE wiring claim it verifies on a fresh CI runner) and warrants a fix-in-batch. Suggested fix path: Option A in Finding 1 (single new step `git checkout HEAD -- test-fixtures/manifest.txt` between (a) and (b)), which simultaneously addresses Finding 5's documentation gap with a one-line header note.
