# PACK-REVIEW-BD-116.md — Persona contract assertions (BD-116)

**Verdict:** APPROVE WITH NITS — implementation is correct, all 221 assertions across 3 contracts pass, no regressions in 8 surrounding test suites; two advisory items concern (a) two hardcoded eight-item file lists for stage-S11 artifacts that mirror an enumeration source already hardcoded in `init-project.sh` and (b) a README Repository-Layout entry that should be added when Pack Chat commits.

**Reviewer:** pack-reviewer (read-only)
**Branch:** `v11-dev` (HEAD `bb78202`)
**Scope:** BD-116 working-tree footprint — 4 NEW + 2 MOD + 1 IMPL-REPORT (the 7 untracked `maintenance-docs/v11-research/*.md` files are out-of-band user work and were ignored per prompt).

---

## 1. Per-concern findings

### 1.1 Three persona contracts present (PASS)

All three live at the BACKLOG-mandated path `scripts/persona-contracts/`:

- `scripts/persona-contracts/contract-greenfield.sh` (188 lines, `-rwxr-xr-x`)
- `scripts/persona-contracts/contract-mid-dev.sh` (214 lines, `-rwxr-xr-x`)
- `scripts/persona-contracts/contract-migration.sh` (351 lines, `-rwxr-xr-x`)

Persona mapping matches the BD-116 spec verbatim:

| Spec persona | Driver | Sandbox source | Pass count |
|---|---|---|---|
| (1) greenfield | `init-project.sh` on empty git repo | fresh `mkdir + git init` (BD-116 builder helper) | **166 PASS / 0 FAIL** |
| (2) mid-dev | `init-project.sh` (default flow — see §1.8) | copy of `existing-project-mid-dev` (BD-115 fixture) | **25 PASS / 0 FAIL** |
| (3) migration | `migrate-v10-to-v11.sh` apply→resume | copy of `v10-realistic-ot` (BD-120 fixture) | **30 PASS / 0 FAIL** |

Total **221/221** assertions pass; verified locally by running `bash scripts/test-persona-contracts.sh`.

### 1.2 Derivation-not-hardwriting (PASS with one advisory)

Audited each contract for hand-written file lists; the derivation strategy is correct in the substantive cases:

- **greenfield Assertion 1** (skills) — derived: iterates `project-template/skills/*/` then asserts the per-CLI distribution at `contract-greenfield.sh:74-117`. Auto-evolves when skills are added or removed.
- **greenfield Assertion 2** (agents) — derived: iterates `project-template/.{tool}/agents/*.{md,toml}` at `contract-greenfield.sh:119-134`.
- **greenfield Assertion 3** (trinity) — derived: `cmp -s` against the live `project-template/{CLAUDE,AGENTS,GEMINI}.md` at `contract-greenfield.sh:136-149`.
- **mid-dev Assertion 1** (user-domain sha256 preservation) — derived: `find <sandbox> -type f` enumeration at `contract-mid-dev.sh:85-91`. Auto-evolves when the BD-115 fixture grows.
- **migration Assertion 2** (per-CLI agents) — derived from `project-template/.{tool}/agents/` at `contract-migration.sh:157-174`.
- **migration Assertion 3a/3b/3c/3d** — token-presence + sidecar-presence checks tied to the BD-120 customization patterns and BD-088 invariants. Sound.
- **migration Assertion 4 issue forms** — derived from `project-template/.github/ISSUE_TEMPLATE/*.yml` at `contract-migration.sh:330-344`.

**ADVISORY (minor)** — `contract-greenfield.sh:152-161` and `contract-migration.sh:310-319` each contain an eight-item array of stage-S11 artifacts:

```
docs/pack/HELP-FRAGMENT.md
docs/pack/HELP-FRAGMENT-TRACKER.md
tracker.toml.example
scripts/pack-help.sh
scripts/lib/detect.sh
.claude/skills/pack-help/SKILL.md
.codex/skills/pack-help/SKILL.md
.gemini/commands/pack-help.toml
```

This is a hand-written file list; if `stage_s11_v11_artifacts()` in `scripts/init-project.sh` (line 778-) grows new artifacts the contracts will silently miss them. Mitigating: the source of truth itself (`init-project.sh:778-845`) is not a derivable enumeration — each artifact has bespoke install rules — so a programmatic derivation would just shift the hardcoding upstream. The IMPL report (§3.1 item 4) acknowledges this as "explicit list derived from `stage_s11_v11_artifacts`."  Recommendation: leave as-is; add a brief comment in both contracts pointing readers to `init-project.sh:stage_s11_v11_artifacts()` so future skill-additions to S11 stay synchronized. Not blocking.

No other hand-written file lists found.

### 1.3 Aggregator wrapper (PASS)

`scripts/test-persona-contracts.sh` (83 lines, `-rwxr-xr-x`) follows the same shape as the existing `scripts/test-detect.sh` / `scripts/test-migrator-skills.sh`:

- Iterates a name array of contracts (`scripts/test-persona-contracts.sh:37-41`).
- Runs each contract bash, captures pass/fail per contract, does NOT short-circuit on first failure (`scripts/test-persona-contracts.sh:48-64`).
- Aggregated pass/fail reported with named-list pretty output (`scripts/test-persona-contracts.sh:66-82`).
- Exit 0 / 1 contract honored.

Live run shows the wrapper is correctly invokable: `Persona contract summary: 3/3 passed`.

### 1.4 CI wiring (PASS)

`.github/workflows/validate-pack.yml` diff (lines 113-118 in updated file):

```yaml
      - name: build test fixtures (BD-115/116/117)
        if: always()
        run: bash test-fixtures/build.sh --all --clean
      - name: persona contracts (BD-116)
        if: always()
        run: bash scripts/test-persona-contracts.sh
```

- Step name labeled with the BD identifier (matches surrounding `(BD-N/M/...)` labelling pattern).
- `if: always()` matches the surrounding pattern so the result surfaces alongside other failures rather than masking them.
- Placed immediately AFTER the fixture-build step, which is its prerequisite (the migration contract needs `v10-realistic-ot` and the mid-dev contract needs `existing-project-mid-dev` already-built). Ordering correct.
- Single command (the wrapper), no env, no inputs — minimal CI surface.

### 1.5 `test-fixtures/build.sh --for-contract <persona>` flag (PASS)

Verified the `--for-contract` flag at `test-fixtures/build.sh:752-823` (the `_materialize_for_contract` helper) and the parser changes at lines 825-851:

- **Persona dispatch correct.** `greenfield` → fresh `git init` with deterministic identity; `mid-dev` → `cp -R existing-project-mid-dev`; `migration` → `cp -R v10-realistic-ot`. All three produce a writable sandbox under `mktemp -d`.
- **Existing flags not regressed.** `--all`, `--name <fixture>`, `--clean`, `--verify` parser branches preserved verbatim; `case` arm only adds `--for-contract` between `--name` and `--clean` (`test-fixtures/build.sh:826-836`).
- **Bash 3.2 compatible / BSD-safe.** `cp -R` (not GNU `--preserve`); no associative arrays; uses `_sha256` cross-platform helper inside contracts.
- **Pre-condition guards correct.** mid-dev and migration die if the source fixture is not built yet (`test-fixtures/build.sh:799-800, 813-814`), exit code 5.
- **Identity re-pin defensive.** `git config user.name / user.email` re-applied on the cloned sandbox even though `cp -R` preserves config (`test-fixtures/build.sh:805-807, 818-820`).
- **No regression to fixture SHAs.** `bash test-fixtures/build.sh --verify` post-modification:
  ```
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258  ← BD-120 baseline matches byte-identically
  v11-flat-file OK: e54ab38fbb5d0099826b384de3c39d61bd7cb171
  v11-tracker-on OK: ae6f0ae6d8fb3b27c29d1ba8a61e2af12edaac2f
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
  ```
  v10-realistic-ot SHA matches the BD-120 baseline exactly.

### 1.6 Migration contract apply→resume realism (PASS)

`contract-migration.sh:82-141` drives the bare migrator (auto-runs `--dry-run` then `--apply` per BD-095), detects pause via state-dir + sidecar enumeration, then auto-resolves via `touch <sidecar>.resolved`.

Realism check against `scripts/lib/migrate-v10-to-v11/resume.sh:13-14, 37-38, 48-49`:

> `(a) companion .resolved flag-file alongside the sidecar (e.g. foo.v10-customized.resolved)`
> `resolved-flag — <sidecar>.resolved file exists alongside`

The contract uses the **documented** developer-facing reconciliation signal — not a backdoor, not a bypass. This is exactly what a developer would do after reviewing each sidecar and choosing the canonical "accept current destination as-is" path (the most common BD-088 outcome). `--resume` then completes cleanly (verified in live run).

Three sidecars are produced (CLAUDE.md.v10-customized + AGENTS.md + GEMINI.md), matching the expected FakeOT trinity divergence. Assertion 3a then verifies the FakeOT customization survives in the sidecar — the contract's reason to exist (BD-088 invariant). All three `3a` checks pass via the sidecar path, which is correct BD-088 behavior on the accept-as-is resume path.

Faithful simulation, not a test bypass.

### 1.7 POQ-BD-116-1 disposition (PASS)

POQ raised in IMPL-REPORT §6.1: v10→v11 migrator does NOT install net-new v11 SKILL.md directories (BD-156/157/158 + python-server-architecture / python-data-architecture).

Pack Chat opened **BD-161** in commit `bb78202` to capture the gap as a separate scope item, with a thorough implementation outline in the BACKLOG entry (lines 1354-1364). The contract correctly narrows its skill-presence assertion to what the v10→v11 migrator IS responsible for (BD-080 pack-help install + BD-147 reference-level skill rename), and `contract-migration.sh:176-194` documents the scoping decision inline.

Disposition correctly out-of-scope for this BD; nothing for BD-116 to do.

### 1.8 POQ-BD-116-2 disposition (PASS — clear inline doc)

The mid-dev contract uses the **default init flow**, not `--update`. The BD-116 spec literally said "init-project.sh `--update` on the BD-115 fixture," but `--update` exits 50 (`EXIT_UPDATE_NOT_CONFIGURED`) on a project that is not yet pack-configured — and the BD-115 fixture has zero pack files by design.

Inline documentation in `contract-mid-dev.sh:22-29` is clear and self-contained:

> `Note on --update vs default flow: BD-116's BACKLOG entry literally says init-project.sh --update on the BD-115 fixture, but --update exits with EXIT_UPDATE_NOT_CONFIGURED (50) on a project that is not yet pack-configured (the BD-115 fixture has zero pack files by design). The persona BD-115 actually models is "pack added on top of in-progress project," which is the DEFAULT init flow against an existing-source classification. We therefore drive the default init flow here. Documented in IMPLEMENTATION-REPORT-BD-116.md as a deliberate spec deviation, with the corresponding POQ raised.`

The deviation is in service of the spec's intent (BD-115's persona). IMPL §6.2 also surfaces this for Pack Chat with two remediation paths if stricter spec-literal adherence is wanted. No action required.

### 1.9 Permission bits (PASS)

```
-rwxr-xr-x  scripts/persona-contracts/contract-greenfield.sh
-rwxr-xr-x  scripts/persona-contracts/contract-mid-dev.sh
-rwxr-xr-x  scripts/persona-contracts/contract-migration.sh
-rwxr-xr-x  scripts/test-persona-contracts.sh
-rwxr-xr-x  test-fixtures/build.sh                 (preserved)
```

All correct; matches the surrounding pattern (existing `scripts/test-*.sh` are also `-rwxr-xr-x`).

### 1.10 No regressions (PASS)

Smoke-test sweep run against modified working tree:

| Suite | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASSED — all 31 checks clean** |
| `bash scripts/test-detect.sh` | **64 passed, 0 failed** |
| `bash scripts/test-migrator-core.sh` | **19 passed, 0 failed** |
| `bash scripts/test-migrator-skills.sh` | **19 passed, 0 failed** |
| `bash scripts/test-migrator-manifest.sh` | **12 passed, 0 failed** |
| `bash scripts/test-migrator-capability-translation.sh` | **12 passed, 0 failed** |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | **43 passed, 0 failed** |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | **40 passed, 0 failed** |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | **41 passed, 0 failed** |
| `bash test-fixtures/build.sh --verify` | **all 5 fixture SHAs match manifest** |
| `bash scripts/test-persona-contracts.sh` (new) | **3/3 contracts PASS (221 assertions)** |

Zero regressions.

### 1.11 BD-159 §3.1 mechanical-edit sanity check

The IMPL report's §12 self-assessment claims BD-116 is mechanical (file count 6 ≤ 10, no validator changes, etc.). On a strict reading of `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 condition 6, "Adding a new top-level `scripts/*.sh`" is itself a structural signal — and BD-116 adds `scripts/test-persona-contracts.sh` as a new top-level script.

However, BD-159 is **scoped to skill-and-agent maintenance** (see ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §1 lines 1-30 — the rule's title and four worked examples are all skill additions; the principle calibrates against BD-141/BD-156/BD-157/BD-158, all skill-shaped). BD-116 is test infrastructure for new test behavior (persona contracts), not a skill or agent change. Applying the BD-159 mechanical/structural threshold to test infrastructure work is a category error.

Pack-coder framing as "test infrastructure for new behavior is acceptable per §3.1" is benign but technically out-of-scope; the more accurate framing is "BD-159 doesn't apply." No blocking concern.

---

## 2. Cross-reference integrity check

Grepped for `persona-contract` / `test-persona-contracts` references across the pack:

- `BACKLOG.md` BD-116 (lines 1130-1157) — original spec, intact.
- `BACKLOG.md` BD-117 (line 1171) — references "all three BD-116 persona contracts pass" — accurate.
- `BACKLOG.md` BD-118 (line 1185) — references BD-116 persona contracts for CI wiring — accurate.
- `BACKLOG.md` BD-161 (line 1360) — POQ-BD-116-1 carry-forward — accurate.
- `EXECUTION-PLAN-V11.0.md` §1.1 lines 30 + §4 line 255 — Batch 3 sequencing entry intact.

**ADVISORY (minor) — README.md Repository Layout** (lines 210-214 list test-runner scripts) does NOT yet enumerate `scripts/test-persona-contracts.sh`. The new directory `scripts/persona-contracts/` is also not listed. README is on the PM-only list per `CLAUDE.md` line 90 ("never modify without explicit instruction"), so this is correctly held for Pack Chat to handle at commit time. **Recommendation:** Pack Chat should add a `scripts/test-persona-contracts.sh` line and the `scripts/persona-contracts/` directory line as part of the BD-116 commit (or at the next PM-only README touch point).

`CHANGELOG.md` is not yet updated (per `CLAUDE.md` rules, only at version boundaries with explicit instruction — correctly deferred).

---

## 3. Trinity rule check (PASS — N/A)

BD-116 does not touch `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, nor the pack-repo trinity copies. Trinity rule does not apply.

---

## 4. Maintenance-docs consistency (PASS)

`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` Batch 3 (line 255) describes "BD-120 → BD-116" sequencing. The BD-120 commit `3fa3322` shipped first; BD-116 builds on the parameterization correctly. The plan's batch description ("both touch `test-fixtures/build.sh`") is satisfied by the new `--for-contract` flag added in this BD.

`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-116.md` is comprehensive (507 lines), well-structured, and matches the working-tree state. The Definition-of-Done checklist (§11) and the BD-159 sanity check (§12) are both honest self-assessments; the only quibble is the §12 framing addressed above.

---

## 5. validate-pack.py alignment (PASS)

The new `scripts/persona-contracts/` directory does not require a new `validate-pack.py` Check. The CI already enumerates the new step explicitly in `validate-pack.yml`; no globbing of test-runner scripts in `validate-pack.py` was found that would need extension.

---

## 6. Migration safety (PASS — N/A)

BD-116 is test infrastructure that lives in `scripts/persona-contracts/` and `scripts/test-persona-contracts.sh`. Neither file is installed into client projects by `init-project.sh` or `migrate-v10-to-v11.sh`. No MIGRATION guide or QUICKSTART update is needed.

---

## 7. BACKLOG accuracy (PASS — flip pending)

BD-116 entry (BACKLOG.md:1130-1157) is correctly `Status: Open` at HEAD `bb78202`. Per `CLAUDE.md` "Pack memory" (Implicit BD status flip on batch completion) and the prompt's batch-completion semantics, Pack Chat should flip BD-116 to `Resolved` as the final step of this batch with a `Resolved:` line citing the pending commit hash and date 2026-05-12.

---

## 8. Acknowledgements — what the implementation got right

- **Faithful BD-088 invariant coverage.** The migration contract's four invariant families (3a/3b/3c/3d in `contract-migration.sh:222-303`) are exactly the four customization shapes the BD-120 fixture installs — the contract auto-evolves with that fixture.
- **Correct sidecar-aware accept-as-is verification (3a).** The contract recognizes that on the `--resume` accept-as-is path, the live trinity reverts to the pack template AND the customization is preserved in the sidecar — and verifies the sidecar carries it. This is the correct BD-088 contract; a naive "FakeOT must still be in the live file" check would be wrong.
- **Per-CLI agent enumeration is fully derived.** Both greenfield Assertion 2 and migration Assertion 2 enumerate `project-template/.{tool}/agents/*.{md,toml}` at runtime — when v12 adds new agents, both contracts pick them up automatically.
- **Cross-platform sha256 helper.** `_sha256()` falls back to `shasum -a 256` on macOS / BSD where `sha256sum` is missing — runs locally on Apple silicon and on the GitHub Actions Linux runner without environment branching.
- **No short-circuit in the wrapper.** `scripts/test-persona-contracts.sh:48-64` runs every contract every time; a regression in one cannot mask a regression in another.
- **POQs raised promptly + correctly scoped.** POQ-BD-116-1 became BD-161 with a thorough implementation outline; POQ-BD-116-2 is documented inline in the contract and surfaced in the IMPL report with two remediation options for Pack Chat to evaluate.
- **Existing classifier respected.** Mid-dev contract Assertion 4 verifies zero spurious `.pack-template` sidecars — the existing-classifier sidecar must fire only on genuine ours-vs-theirs divergence; the contract correctly tests that the classifier is not over-firing on the BD-115 fixture.

---

## 9. Summary of advisory (NIT) items

| # | Severity | File:line | Item | Action |
|---|---|---|---|---|
| N1 | minor | `contract-greenfield.sh:152-161` + `contract-migration.sh:310-319` | Eight-item hand-written list of stage-S11 artifacts mirrors a hardcoded enumeration in `init-project.sh:stage_s11_v11_artifacts()`. Will go stale silently if new artifacts are added to S11. | Add a one-line cross-reference comment in both contracts pointing readers to `init-project.sh:stage_s11_v11_artifacts()`. Not blocking. Optional fix-pass item. |
| N2 | minor | `README.md:210-214` (Repository Layout) | New `scripts/test-persona-contracts.sh` and `scripts/persona-contracts/` directory not yet listed; README is PM-only so Pack Chat must handle. | Pack Chat to add the layout entries as part of (or shortly after) the BD-116 commit. Not blocking. |

---

## 10. Verdict (restated)

**APPROVE WITH NITS.** All 13 IMPL-REPORT DoD criteria are satisfied; all 221 contract assertions pass; all 8 surrounding test suites pass; v10-realistic-ot SHA byte-identical with BD-120 baseline; permission bits correct; CI wiring correct; both POQs handled correctly; the apply→resume cycle is a faithful simulation of the developer experience using the documented `.resolved` flag-file mechanism. Two minor advisory items above (S11 cross-reference comment + README layout entries) are optional / Pack-Chat-handled and do not gate commit.

BD-116 ready for Pack Chat to commit and flip to `Resolved`.
