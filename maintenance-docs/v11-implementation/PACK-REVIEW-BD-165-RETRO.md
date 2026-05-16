# PACK-REVIEW-BD-165-RETRO — retroactive per-BD review of Commit 19c (Batch 19)

**Reviewer:** pack-reviewer (v11-dev, retro pass)
**Date:** 2026-05-16
**Scope under review:** BD-165 — `_v10_to_v11_decompose_streams` 6th post-dispatch sub-op + `--force-overwrite-mirror` flag (Commit `a5b4a6e`)
**Authoritative inputs:** PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.4; ARCHITECTURE-PER-ENTRY-SPLIT.md §1.3; ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.1 / §9.1 / §9.4 / §9.6 / §8.18 / §10.2 / §18.1 #3-4; ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md §5.3; ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md §4 / §4.5; existing migrator-core + per-entry helpers.

---

## §1 — Summary

BD-165 is **architecturally correct and functionally working**: the 6th sub-op (`_v10_to_v11_decompose_streams`) is placed at the correct position in `migrator_post_dispatch_hook` (after the 5 existing sub-ops per integration parent §3.1 / §9.6), the BD-119 frozen public surface is preserved (additive `_MIGRATOR_FORCE_OVERWRITE_MIRROR` internal state + additive `--force-overwrite-mirror` parser case + additive usage line; no new exit codes / hook functions / manifest rows), the mode-aware divergence routing in `mirror-generate.sh` faithfully implements Addendum #2 §4.5 (dry-run → stdout rc=0; apply/resume → stderr + `EXIT_GATE_FAILED=31`; fall-through preserves pre-BD-165 rc=2 for direct callers), and the dispatcher-level intercept in `migrate-v10-to-v11.sh` correctly compensates for the resume-path seam (where `_MIGRATOR_MODE` is set directly without invoking `_migrator_parse_args`). All existing test suites pass (19/19 + 57/57 + 43/43 + 61/61 + 87/87) and validate-pack PASSES.

Found **6 findings: 1 MUST, 3 SHOULD, 2 NIT.** The MUST is the misleading advisory paragraph wording in `migrator_post_report_hook` (claims hand-edits are "silently overwritten" when in fact they are BLOCKED — this directly contradicts Addendum #2 §4 contract and would confuse users about the actual safety mechanism). The SHOULDs cover: stale public-API docstring header in `mirror-generate.sh`, the README Repository Layout missing the new `decompose.sh`, and the absence of any wired CI test covering BD-165's net-new functional surface (`--force-overwrite-mirror` flag, dispatcher intercept, mode-aware divergence routing, 6th sub-op call).

---

## §2 — Findings

### M1 — Post-report advisory paragraph misrepresents the actual safety contract

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh:699-700`

**Quoted text:**
```
say "Hand-edits to the mirrors are silently overwritten on the next"
say "regeneration unless --force-overwrite-mirror is acknowledged."
```

**Architect-doc binding:** Addendum #2 §4.2 (Updated §5.3 specification) — "**the migrator NEVER silently overwrites the mirror in `--apply` or `--resume` mode**. Stderr warning is INSUFFICIENT because stderr can be buffered, lost, or unreviewed in CI/automation contexts; explicit blocking with exit code is the safety mechanism." Per the IMPLEMENTED behavior (mirror-generate.sh:305-318), apply/resume mode BLOCKS with `EXIT_GATE_FAILED=31` unless `--force-overwrite-mirror` is explicitly passed.

**Why MUST.** The current wording REVERSES the safety contract semantics. The phrase "silently overwritten ... unless --force-overwrite-mirror is acknowledged" tells the user the default is silent overwrite and the flag is needed to BLOCK it. The actual contract is the inverse: the default is BLOCK with rc=31; the flag is needed to ALLOW overwrite. A user reading the post-report advisory would conclude their hand-edits are at risk by default and would feel compelled to pass `--force-overwrite-mirror` to "make it safe" — which would have the opposite effect. This is the highest-stakes context (user is reading a migrator report describing what just happened to their working tree); imprecise wording at this surface defeats the entire BD-095 bridge safety mechanism the BD-165 commit implements.

**Concrete fix.** Replace lines 699-700 with text that matches the actual contract. Sample:
```
say "Hand-edits to the mirrors that diverge from the per-entry tree will BLOCK"
say "the next regeneration with exit code 31 (EXIT_GATE_FAILED). Re-run with"
say "--force-overwrite-mirror to acknowledge and overwrite the hand-edits, or"
say "reconcile the per-entry tree with the mirror by hand first."
```
Optionally extend to mention that the per-entry tree under `docs/project/<stream>/` is the source-of-truth, so the canonical resolution is to edit the per-entry files (not the mirror) before re-running.

### S1 — `mirror-generate.sh` public-API header docstring is stale (pre-BD-165)

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh:17-24`

**Quoted text (header docstring describing the public API):**
```
#       If the on-disk mirror already exists and differs from what the
#       generator would produce (divergence), behavior depends on
#       context:
#           - Interactive (TTY on stdin AND stdout): prompt user to
#             confirm overwrite; abort on rejection (Addendum #1 §5.3).
#           - Non-interactive: emit divergence warning to stderr and
#             return non-zero exit (BD-095-mode wiring in 19c
#             interprets the exit code per Addendum #2 §4).
```

**Architect-doc binding:** Addendum #2 §4.2 (Updated §5.3 specification replaces Addendum #1 §5.3 non-interactive routing): non-interactive context now has THREE possible behaviors (dry-run / apply-resume / fall-through) instead of one. The body comment at lines 266-291 + the `case "${_MIGRATOR_MODE:-}" in` block at lines 292-319 implements this correctly, but the file-level public-API docstring still describes the pre-BD-165 single non-interactive path.

**Why SHOULD.** The body comment is correct and complete; the stale docstring is the API surface readers see first when sourcing the helper. The risk is a future maintainer (or BD-166 / BD-168 author working with the helper) reads the docstring, assumes the simpler pre-BD-165 contract, and misuses the helper or duplicates routing logic.

**Concrete fix.** Replace the docstring's non-interactive bullet (lines 22-24) with three bullets matching the implementation:
```
#           - Non-interactive with _MIGRATOR_MODE=dry-run: report divergence
#             to stdout (informational); return 0.
#           - Non-interactive with _MIGRATOR_MODE=apply|resume: BLOCK with
#             EXIT_GATE_FAILED=31 + recovery instruction naming
#             --force-overwrite-mirror (Addendum #2 §4 BD-095 bridge).
#           - Non-interactive with _MIGRATOR_MODE unset (direct callers
#             outside the migrator): preserve pre-BD-165 stderr warning +
#             rc=2 behavior for backward compatibility.
```

### S2 — README Repository Layout omits the new adapter-private helper

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md:206-209`

**Quoted text (current layout block for `migrate-v10-to-v11/`):**
```
    └── migrate-v10-to-v11/                 v10→v11 adapter-private libs (v11; BD-095 + BD-101)
        ├── dry-run.sh, apply.sh, resume.sh    Two-phase mode dispatchers (BD-095)
        ├── checkpoint.sh                       BD-101 verification helpers
        └── gate-{1,2,3}-*.sh                   Pre/post Phase-A/Phase-B gates (BD-101)
```

**Review-checklist binding:** "**README layout.** If files are added, moved, or removed, verify the Repository Layout section in README.md is updated." BD-165 added a NEW adapter-private file `scripts/lib/migrate-v10-to-v11/decompose.sh` (the 6th adapter-private library in this directory) — but the README layout list still enumerates only 5 file groups (`dry-run.sh, apply.sh, resume.sh`, `checkpoint.sh`, `gate-{1,2,3}-*.sh`).

**Why SHOULD.** The README Repository Layout is the authoritative discovery surface for "what lives where" per `CLAUDE.md`. Pack agents reading the README to locate the BD-165 helper would not find it listed; cross-references in future ARCHITECTURE / PLAN docs that quote the README layout would understate the inventory.

**Concrete fix.** Add a line under the `migrate-v10-to-v11/` block:
```
        ├── decompose.sh                        BD-165 — 6th post-dispatch sub-op + --force-overwrite-mirror bridge
```
Order it after `dry-run.sh, apply.sh, resume.sh` (mode dispatchers) since `decompose.sh` is a post-dispatch helper invoked by the post-dispatch hook of all three modes' migrator runs. Or alphabetize as `checkpoint.sh, decompose.sh, dry-run.sh, ...`. Pack Chat picks ordering preference.

### S3 — No wired CI test covers BD-165's net-new functional surface

**Files:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml`; `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-migrate-v10-to-v11*.sh` (existing); `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-per-entry.sh` (existing)

**Architect-doc binding + checklist binding:** Per the CI-step interrogation discipline (review checklist + Batch 21c heuristic): "**For the new `--force-overwrite-mirror` flag + 6th sub-op behavior: what concrete change would turn an existing CI test red? Confirm the existing wiring would actually surface a regression.**" Per IMPL-REPORT §4.3, the BD-165 behavior is validated by 4 manual smoke tests against transient `/tmp` fixtures, NOT codified in any wired test runner.

**Concrete coverage gaps verified by grep:**
- `grep -nE "force-overwrite-mirror|_MIGRATOR_FORCE_OVERWRITE_MIRROR|decompose_streams|S5d" scripts/tests/test-migrate-v10-to-v11*.sh scripts/test-migrator-core.sh` returns ZERO matches.
- `test-per-entry.sh` Group 8 exercises only the fall-through path of `mirror-generate.sh` (no `_MIGRATOR_MODE` set; rc=2). The NEW dry-run / apply-resume mode-aware branches in `mirror-generate.sh:292-319` are NOT exercised.
- The dispatcher intercept in `migrate-v10-to-v11.sh:804-810` (set `_MIGRATOR_FORCE_OVERWRITE_MIRROR` before mode dispatch so resume mode honors the flag) has no CI coverage.
- The post-report advisory paragraph emission has no CI coverage.

**Why SHOULD.** Concrete regression scenarios that would NOT turn any existing CI test red:
1. Someone removes `_v10_to_v11_decompose_streams` from `migrator_post_dispatch_hook` (line 164) — all 5 prior sub-ops still run; all existing tests still pass; the 6th sub-op silently vanishes.
2. Someone reorders `_v10_to_v11_decompose_streams` to run BEFORE `_v10_to_v11_translate_capability_tokens` — violates the integration parent §3.1 / §9.6 sequencing constraint (decompose then reads pre-translation content); all existing tests still pass.
3. Someone removes the dispatcher intercept (`--force-overwrite-mirror) ... ;;` case in the for-loop at line 804) — flag-on-resume silently ignored; no test catches it.
4. Someone breaks the `case "${_MIGRATOR_MODE:-}" in` block (e.g., swaps the `dry-run)` and `apply|resume)` branches) — dry-run blocks with rc=31, apply silently reports + rc=0; no test catches it (Group 8 doesn't set `_MIGRATOR_MODE`).

**Concrete fix.** Add a new test runner `scripts/tests/test-migrate-v10-to-v11-decompose.sh` (or extend `scripts/tests/test-migrate-v10-to-v11.sh`) with cases that:
1. Build a transient v10-shape fixture with `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` (mimicking the IMPL-REPORT §4.3 `/tmp/scratch-v10-19c-rich4` setup but codified).
2. Run `--dry-run` and assert the post-dispatch banner names "BD-165 per-entry decompose" + advisory paragraph emitted.
3. Run `--apply` and assert: per-entry trees produced under `docs/project/<stream>/`; mirror SHAs unchanged on first migration (round-trip identity) OR overwritten + warning emitted under `--force-overwrite-mirror`; post-report advisory paragraph contains the backup directory path.
4. Hand-edit a mirror; re-invoke the regenerator with `_MIGRATOR_MODE=apply` (or via the migrator's resume flow); assert rc=31 + stderr names `--force-overwrite-mirror`.
5. Same as 4 with `--force-overwrite-mirror`; assert rc=0 + stderr audit warning + mirror SHA changed.
6. Wire the new runner into `.github/workflows/validate-pack.yml` between the existing `migrate-v10-to-v11 verification gates (BD-101)` step and `migrator-core tests (BD-119)` step.

Alternative narrower fix: extend `test-per-entry.sh` Group 8 with cases that set `_MIGRATOR_MODE=dry-run` and `_MIGRATOR_MODE=apply` explicitly and assert the mode-aware branches behave correctly. This catches regressions in the routing logic but does NOT catch regressions in the migrator-level wiring (sub-op call, dispatcher intercept, advisory paragraph). Comprehensive fix is preferred.

### N1 — IMPL-REPORT post-report advisory line-count claim is imprecise

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md:236-241` (claim) vs `scripts/migrate-v10-to-v11.sh:689-710` (actual)

**Quoted text (IMPL-REPORT §3.4 C):**
> "Added 16 say-lines (~12 displayed paragraph lines) before the existing 'To opt into the v11 issue-tracker integration' pointer."

**Architect-doc binding:** Integration parent §8.18 sample text is ~12 displayed lines (sample inspected at lines 2175-2193).

**Actual count.** `awk 'NR>=690 && NR<=706'` returns 18 say lines (16 if blanks at lines 690, 701, 707 are excluded — the count depends on whether you include the section-separator `say ""` lines). The IMPL-REPORT §5 Definition-of-Done table at line 490 then reconciles by claiming "16 `say` lines (the say lines render as ~12 displayed paragraph lines because some are short / blank)" — internally consistent, but the §3.4 C claim of "16" depends on which counting convention you use.

**Why NIT.** This is a cosmetic doc-internal inconsistency, not a behavioral defect. The advisory is the correct length per §8.18 (12 displayed lines).

**Concrete fix.** In the IMPL-REPORT, clarify whether the count includes section-separator blank `say ""` lines, OR re-count to 18 say-lines total (including 3 blanks). Optional fix — IMPL-REPORTs are archived per Pattern B.

### N2 — IMPL-REPORT references `scripts/lib/migrate-v10-to-v11/resume.sh:226-232` but the relevant lines are 226-232

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md:559` (claim) vs `scripts/lib/migrate-v10-to-v11/resume.sh` (actual)

**Quoted text (IMPL-REPORT §7.1):**
> "This is intentional given the resume path's existing 'do-not-call-`_migrator_parse_args`' architectural seam (which predates BD-165 per `scripts/lib/migrate-v10-to-v11/resume.sh:226-232`)..."

**Actual.** Lines 226-232 in `resume.sh` are:
```
226    _MIGRATOR_DRY_RUN="0"
227    _MIGRATOR_MODE="resume"
228    _MIGRATOR_REPORT_DONE="0"
229    TARGET="$target"
230    STATE_DIR="$state_dir"
231    BACKUP_DIR="$state_dir-backup"
232
```
This DOES match the IMPL-REPORT's claim (line 227 is the `_MIGRATOR_MODE="resume"` direct-set the IMPL-REPORT cites as the seam). Verified accurate. NO finding here — this line reference is correct, contrary to my initial concern. Striking N2.

**Resolution: WITHDRAW.** Verified that the IMPL-REPORT line reference is accurate. (I am leaving this entry in the report under §2 to document the verification but classifying it as resolved-no-finding.)

---

## §3 — Verification

### §3.1 — Commands executed (read-only)

```
$ bash -n scripts/lib/migrator-core.sh
   OK
$ bash -n scripts/lib/per-entry/mirror-generate.sh
   OK
$ bash -n scripts/lib/migrate-v10-to-v11/decompose.sh
   OK
$ bash -n scripts/migrate-v10-to-v11.sh
   OK

$ bash scripts/test-migrator-core.sh
   === Results: 19 passed, 0 failed ===

$ bash scripts/tests/test-per-entry.sh
   All per-entry tests PASSED (57/57).

$ bash scripts/tests/test-migrate-v10-to-v11.sh
   Passed: 43, Failed: 0

$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
   Passed: 61, Failed: 0

$ bash scripts/tests/test-migrate-v10-to-v11-gates.sh
   Passed: 87, Failed: 0

$ python3 scripts/validate-pack.py
   PASSED — all checks clean
```

### §3.2 — Architect-binding spot-checks

| Binding | Verified against | Status |
|---|---|---|
| 6th sub-op runs AFTER 5 existing sub-ops | `scripts/migrate-v10-to-v11.sh:144-164` (call order: rename → relocate → install_v11 → rename_py_arch → translate_caps → decompose_streams) | PASS |
| Helper sources BD-164 helpers (no reimpl) | `scripts/lib/migrate-v10-to-v11/decompose.sh:83-100` (sources `_lib.sh`, `decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh` from `../per-entry/`) | PASS |
| `_MIGRATOR_FORCE_OVERWRITE_MIRROR` default "0" | `scripts/lib/migrator-core.sh:141` (`_MIGRATOR_FORCE_OVERWRITE_MIRROR="0"` in `_migrator_reset_state`) | PASS |
| Block path uses `EXIT_GATE_FAILED=31` | `scripts/lib/per-entry/mirror-generate.sh:317` (`return "${EXIT_GATE_FAILED:-31}"`) | PASS |
| BD-095 contract preserved | no other flag added; `_MIGRATOR_MODE` / `_MIGRATOR_DRY_RUN` semantics unchanged | PASS |
| Backup contract preserved (`_stage_backup` at `migrator-stages.sh:146`) | `scripts/lib/migrator-stages.sh:146` (`_stage_backup() {`); file NOT modified by BD-165 | PASS |
| BD-119 framework unchanged | no new exit codes (still 10 originals + `EXIT_GATE_FAILED=31` + `EXIT_INTERNAL=99` + `EXIT_NOT_V10` synonym); no new hook functions; `migrator_manifest()` unchanged (14 rows) | PASS |
| Bash 3.2 + macOS BSD compat | `bash --version` 3.2.57; `bash -n` clean on all 4 modified files; tested `case "${VAR:-}" in ...` idiom on bash 3.2 | PASS |
| Mode-aware case block | `scripts/lib/per-entry/mirror-generate.sh:292-319` (`case "${_MIGRATOR_MODE:-}" in dry-run) ... ;; apply\|resume) ... ;; esac`) | PASS |
| Dry-run REPORTS divergence rc=0 | `mirror-generate.sh:293-304` (`printf` to stdout, `return 0`) | PASS |
| Apply/resume BLOCKS rc=31 | `mirror-generate.sh:305-318` (`printf` to stderr, `return "${EXIT_GATE_FAILED:-31}"`) | PASS |
| Fall-through preserves pre-BD-165 rc=2 | `mirror-generate.sh:321-330` (default warn + rc=2 outside the case block) | PASS |
| Interactive TTY routing UNCHANGED | `mirror-generate.sh:244-264` (prompts user; no changes from Addendum #1 §5.3 shape) | PASS |
| `PE_FORCE_OVERWRITE_MIRROR=1` short-circuit at top of function UNCHANGED | `mirror-generate.sh:236-242` (force path; immediate overwrite + warn) | PASS |
| Dispatcher intercept | `scripts/migrate-v10-to-v11.sh:804-810` (`--force-overwrite-mirror)` case in mode-detection for-loop; sets state var AND passthrus the flag) | PASS |
| Trinity rule | no edits to `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root or `project-template/`) per `git show a5b4a6e --stat` | PASS |
| Banner + fail_stage routing | `decompose.sh:113` (banner `── S5d (decompose) — BD-165 per-entry decomposition + mirror+TOC regenerate ──`); `decompose.sh:178, 197, 204` (`fail_stage S5 "S5d-decompose: ..."`) | PASS |
| Bridges `_MIGRATOR_FORCE_OVERWRITE_MIRROR=1` → `export PE_FORCE_OVERWRITE_MIRROR=1` | `decompose.sh:124-126` (`if [[ "${_MIGRATOR_FORCE_OVERWRITE_MIRROR:-0}" == "1" ]]; then export PE_FORCE_OVERWRITE_MIRROR=1; fi`) | PASS |

### §3.3 — Trinity rule verification

Per `git show a5b4a6e --stat`, the 5 files touched are:
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md` (NEW — agent report, not pack content)
- `scripts/lib/migrate-v10-to-v11/decompose.sh` (NEW — adapter-private)
- `scripts/lib/migrator-core.sh` (MODIFIED — framework)
- `scripts/lib/per-entry/mirror-generate.sh` (MODIFIED — helper)
- `scripts/migrate-v10-to-v11.sh` (MODIFIED — adapter)

Zero trinity touches. **PASS.**

### §3.4 — Cross-reference integrity spot-check

- IMPL-REPORT §3.3 cites `scripts/lib/per-entry/decompose.sh:30-33` as the precedent for the `BASH_SOURCE`-relative source guard — verified accurate (`Read scripts/lib/per-entry/decompose.sh:29-33` shows the matching `if ! type pe_die >/dev/null 2>&1; then` block).
- IMPL-REPORT §7.1 cites `scripts/lib/migrate-v10-to-v11/resume.sh:226-232` for the `_MIGRATOR_MODE="resume"` direct-set seam — verified accurate (`Read scripts/lib/migrate-v10-to-v11/resume.sh:226-232` shows line 227 `_MIGRATOR_MODE="resume"`).
- IMPL-REPORT §2 file count matches `git show a5b4a6e --stat` (4 modified/created files in scripts/ + 1 IMPL-REPORT).

---

## §4 — Out-of-scope observations

(Non-defer language; surfaced for visibility; not BD-165 fixes.)

### §4.1 — README test-case counts are stale across the v10→v11 test surface (pre-BD-165 drift)

**File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md:219-220`

The README enumerates test case counts: "BD-095 tests — dry-run / apply / resume modes (40 cases)" and "BD-101 tests — Gate 1 / 2 / 3 verification (39 cases)". Actual counts (from this review's test run): 61 BD-095 cases + 87 BD-101 cases. The stale counts predate BD-165 (the test files were not modified by BD-165). Out-of-scope for this review but flagged as cross-reference drift any future maintenance pass should reconcile.

### §4.2 — `_passthru` + dispatcher intercept introduces a "set-then-reset-then-reset-again" pattern for `_MIGRATOR_FORCE_OVERWRITE_MIRROR`

In dry-run / apply paths, the flag is set THREE times: (1) dispatcher intercept sets it to "1" at `migrate-v10-to-v11.sh:808`; (2) `migrator_run` calls `_migrator_reset_state` resetting to "0" at `migrator-core.sh:141`; (3) `_migrator_parse_args` re-sets to "1" from the passthru-forwarded flag at `migrator-core.sh:328`. This is functionally correct (the passthru ensures the parser sees the flag) but is conceptually awkward. The asymmetry is intentional and documented (per the dispatcher comment at `migrate-v10-to-v11.sh:771-780` + IMPL-REPORT §7.1), but is worth flagging for future reviewers. A future cleanup could either: (a) move the dispatcher intercept INSIDE the resume case only (so dry-run/apply paths rely solely on the parser); or (b) keep the intercept symmetric across all three modes and document the redundancy more prominently. Out-of-scope for BD-165.

### §4.3 — `_v10_to_v11_decompose_streams` operates project-side only; pack-side per-entry decomp lands in Batch 22 (BD-102 dog-food)

Confirmed by the comment block at `scripts/lib/migrate-v10-to-v11/decompose.sh:128-134` and the tuple list at lines 145-148 (project-backlog / project-implementation-plan / project-changelog only — no pack-backlog / pack-changelog tuples). This matches integration parent §10.5 last paragraph. **Not a finding** — surfaced for visibility as it matches the IMPL-REPORT §7.4 observation.

### §4.4 — First-migration divergence is the expected contract; users with pre-existing `docs/project/*.md` will need `--force-overwrite-mirror` on first apply

Per IMPL-REPORT §7.3. This is the correct behavior per Addendum #2 §4 — the migrator NEVER silently overwrites. However, the post-report advisory does not explicitly call out "first-migration users with existing `docs/project/*.md` will likely see divergence on first regenerate". If M1 (above) is fixed, the same fix opportunity covers adding one sentence about this case. Surfaced as related to M1 but not a separate finding.

### §4.5 — BACKLOG.md BD-165 entry is still `Status: Open` (correct pre-retro-review state)

`BACKLOG.md:1498` shows `Status: Open` for BD-165. Per the implicit-BD-status-flip-on-batch-completion rule, BD-165 status flips to `Resolved` as part of the batch's final status-flip commit (commit 19h per plan §0). The retro review is BEFORE that flip; current state is correct. Not a finding.

---

## §5 — Closing

**Findings to fix in v11.0 (per `feedback_no_deferral_without_user_direction`):** M1 (post-report wording correction), S1 (mirror-generate.sh docstring), S2 (README layout), S3 (CI test coverage).

**Definition-of-Done verification:** all architect-doc bindings PASS; all baseline tests PASS; one MUST + three SHOULDs + two NITs (one of which self-resolved during verification) surfaced for Pack Chat decision.
