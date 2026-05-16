# PACK-REVIEW-BATCH-19-BROAD.md — Batch 19 broad batch review (cross-BD, post-coder, pre-flip)

**Review subject:** Batch 19 per-entry split — broad batch review across all 9 new BDs
(BD-164, BD-165, BD-166, BD-167, BD-167b, BD-168, BD-169, BD-169b, BD-170) + BD-160 +
BD-161 (absorbed). 11 BD-tracked items, 10 coder/PM commits, ready for 19h status flip.

**Review type:** BROAD BATCH review (cross-BD; not per-BD). This complements the
per-BD reviews already run for every BD in the batch; the broad review's job is
cross-BD consistency, integration coherence, CI coverage holism, and forward-pointing
convention. Per-BD review findings are out of scope (already triaged + fixed).

**Reviewed against:**
- `PLAN-PER-ENTRY-SPLIT-BATCH-19.md` (1,728 lines)
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (3,477 lines)
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` (2,053 lines)
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` (1,400 lines)
- All 8 BD IMPL-REPORTs (BD-164, BD-165, BD-166, BD-167, BD-167b synthesized via RETRO-FIX, BD-168, BD-169, BD-160-170)
- All 8 fix IMPL-REPORTs (BD-164-RETRO-FIX, BD-167-RETRO-FIX, BD-167b-RETRO-FIX, BD-165-RETRO-FIX, BD-166-RETRO-FIX, BD-168-RETRO-FIX, BD-160-170-FIX, BD-169-FIX)
- `CLEANUP-INPUTS-SESSION-RULES.md`
- Working-tree state at HEAD `27374b4` (live source spot-checks)

**Reviewer:** pack-reviewer (sub-agent)
**Date:** 2026-05-16
**HEAD reviewed:** `27374b4` (BD-169b PACK-CHAT.md + README.md Repository Layout)
**Branch:** `v11-dev`

---

## §1 — Summary

**Verdict: READY TO FLIP after addressing 1 MUST + 3 SHOULD findings.** The Batch 19
per-entry split feature is internally coherent end-to-end across the three call sites
(BD-165 v10→v11 migrator, BD-166 init-project greenfield, BD-160/170 fixture builder)
plus the BD-168 validators and BD-169/169b operator-facing surfaces. All 11 BDs read
`Status: Open` in BACKLOG.md as expected; their cross-references (Blockers / Unblocks)
are consistent and resolvable. Trinity rule is honored across both the pack-root and
project-template trinity sets; PACK-AGENTS.md and CLAUDE.md pack-memory carry the
mode-aware language verbatim per Addendum #1 §3.4. Forward-pointing notes consistently
name "Batch 23 (BD-102 dog-food)" as the resolution anchor for the pack-self per-entry
trees that don't exist yet.

**Finding totals:** 1 MUST + 3 SHOULD + 5 NIT + 6 observations.

**Integration coherence verdict:** PASS with one defect — the BD-165 helper
(`scripts/lib/migrate-v10-to-v11/decompose.sh:131`) still references "Batch 22" instead
of "Batch 23" (renumber-cascade miss). All other forward-pointing surfaces (PACK-AGENTS.md
forward note, README.md Repository Layout, validate-pack.py OK-message wording, IMPL-REPORT
BD-167 / BD-167b-RETRO-FIX) correctly say "Batch 23." This is a one-line code-comment
sweep; mechanical fix.

**Pre-flip sanity:** all 11 BDs are flip-ready. Resolved-line claims for BD-160 (combined
with BD-170 in commit 19f per R-2) and BD-161 (absorbed into BD-167 per integration parent
§17.2) have established IMPL-REPORT anchors. No BD blocks the flip.

**Test surface:** validate-pack.py PASSED (33 invoked checks clean); test-per-entry.sh
57/57; test-validate-pack-checks-32-33-34.sh 65/65; test-migrate-v10-to-v11-decompose.sh
45/45; test-init-project.sh 67/67; test-migrate-v10-to-v11.sh 43/43; test-migrate-v10-to-v11-dry-run.sh
61/61; test-migrate-v10-to-v11-gates.sh 87/87; tracker-agent-read-test.sh 52/52;
test-migrator-core.sh 19/19; test-persona-contracts.sh 3/3.

---

## §2 — Findings

### MUST findings (1)

#### MUST-1 — Stale "Batch 22" reference in BD-165 adapter-private decompose helper

- **Severity:** MUST (cross-BD inconsistency that affects user-visible behavior — code-comment
  defect leaves a future reader pointing at the wrong batch label after the renumber cascade)
- **Location:** `scripts/lib/migrate-v10-to-v11/decompose.sh:131`
- **Finding:** A comment in the BD-165 adapter says "pack-self decomposition lands in Batch 22
  dog-food" — but per Addendum #1 §2.2 (renumber cascade), the dog-food batch was renamed Batch
  22 → Batch 23 throughout v11.0. BD-168 retro-fix swept all "pre-Batch-22 pack-self" wording
  in validate-pack.py to "pre-BD-102 dog-food pack-self," but BD-165's decompose.sh missed the
  parallel sweep.
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/decompose.sh:131` reads
    `"# migrator — pack-self decomposition lands in Batch 22 dog-food"`
  - `scripts/validate-pack.py:2898/3072/3295` consistently uses
    `"pre-BD-102 dog-food pack-self"` (BD-168 retro-fix swept)
  - `PACK-AGENTS.md:180` correctly says
    `"created at Batch 23 (BD-102 dog-food)"`
  - `README.md:189` correctly says
    `"populated at Batch 23 BD-102 dog-food"`
  - `IMPLEMENTATION-REPORT-BD-167.md:656` correctly says
    `"Batch 23 dog-food per the v11.0 batch sequence"`
  - `IMPLEMENTATION-REPORT-BD-165.md:634` also still says "Batch 22 dog-food"
    (parallel defect in the IMPL-REPORT itself)
- **Suggested remediation:** mechanical text sweep: rewrite the decompose.sh comment block
  at line 131 to "pack-self decomposition lands in Batch 23 (BD-102) dog-food" matching
  the durable BD-102 anchor + the correct batch number; same sweep in
  `IMPLEMENTATION-REPORT-BD-165.md:634` ("pack-self decomposition is Batch 23 (BD-102)
  dog-food's job, not the v10→v11 client migrator's").
- **Scope:** BD-165 (commit 19c) — landed before BD-168 retro-fix swept the "Batch-22"
  wording elsewhere; was missed in that sweep because BD-168 focused on validate-pack.py.

### SHOULD findings (3)

#### SHOULD-1 — README claim "33 invoked checks (numbered Check 1-11 and 16-35)" is internally inconsistent

- **Severity:** SHOULD (incorrect cross-BD documentation; the parenthetical math doesn't
  add up to the leading number)
- **Location:** `README.md:60`, `README.md:195`, `IMPLEMENTATION-REPORT-BD-168.md:349`
- **Finding:** The repeated claim "33 invoked checks (numbered Check 1-11 and 16-35;
  Checks 12-15 retired per v9 sunset)" has an arithmetic gap: `1-11 = 11` plus `16-35 = 20`
  totals **31 numbered checks**, not 33. The actual `validate-pack.py` source has 33
  `def check_*` invocations in `main()`, but **only 31 print a numbered banner**; the
  remaining two (`check_issue_template_forms`, `check_template_archive_v11`) print
  unnumbered "informational" banners.
- **Evidence:**
  - `grep -E "^    check_" scripts/validate-pack.py | wc -l` → 33 (invocations in main())
  - `python3 scripts/validate-pack.py | grep -c "^── Check [0-9]"` → 31 (numbered banners)
  - `scripts/validate-pack.py:980`: `"── Check: Issue template forms (BD-063) ──"` (no number)
  - `scripts/validate-pack.py:1083`: `"── Check: Template archive v11.0 integrity (BD-064;
    informational) ──"` (no number)
  - `README.md:60` and `README.md:195` both say "33 invoked checks (numbered Check 1-11
    and 16-35; Checks 12-15 retired per v9 sunset)"
  - `IMPLEMENTATION-REPORT-BD-168.md:349` repeats the same wording
- **Suggested remediation:** harmonize the count + parenthetical. Two acceptable shapes:
  (a) "33 invoked checks (31 numbered Check 1-11 and 16-35; 2 unnumbered informational —
  issue-template-forms and template-archive-v11; Checks 12-15 retired per v9 sunset)" or
  (b) "31 numbered checks (Check 1-11 and 16-35; Checks 12-15 retired per v9 sunset)
  plus 2 informational checks" — pick one and apply to all three sites.
- **Scope:** BD-168 (introduced the new "33 invoked checks" wording in BD-168 retro-fix
  FIX N3), README (BD-169b touched the Repository Layout but inherited the prior wording),
  IMPL-REPORT-BD-168 (retro-fix author).

#### SHOULD-2 — No CI test consumes the v11-realistic-ot fixture post-build

- **Severity:** SHOULD (integration-boundary test gap; the fixture exists for round-trip
  verification at build time, but no separate test consumes it to detect regressions in
  the consumer chain)
- **Location:** `.github/workflows/validate-pack.yml`, `scripts/persona-contracts/`,
  `test-fixtures/build.sh`
- **Finding:** The BD-160+170 fixture `v11-realistic-ot` is built in CI step "build test
  fixtures (BD-115/116/117)" at line 208 of validate-pack.yml, then `fixture manifest
  verify` validates its SHA. But no downstream test step consumes the built fixture's
  contents. The round-trip byte-identity verification happens inline in `build.sh:539`,
  so a regression in the BD-164 helpers that breaks the v11 fixture's round-trip would
  trip the build step itself — but only if the build doesn't short-circuit. The contract
  -migration.sh persona test consumes ONLY v10-realistic-ot (line 41-46 references); it
  does NOT exercise the post-decompose v11 state. The v11-realistic-ot post-decompose
  per-entry tree state is only verified at build time inside build.sh, not as a separate
  test consumer.
- **Evidence:**
  - `grep -rn "v11-realistic-ot" scripts/` returns the docstring update +
    `test-fixtures/manifest.txt:7` + `test-fixtures/build.sh:52,433,893` only
  - `scripts/persona-contracts/contract-migration.sh:8`: "drives `migrate-v10-to-v11.sh`
    against the BD-120 `v10-realistic-ot` fixture and asserts..." (does not use
    v11-realistic-ot)
  - `.github/workflows/validate-pack.yml:208-225`: build → restore manifest → verify
    manifest SHA only; no post-decompose checks against the v11 fixture
  - `test-fixtures/build.sh:539`: round-trip byte-identity check is inline in build.sh,
    not in a separate test runner
- **Suggested remediation:** add a test runner (e.g., `scripts/tests/test-v11-realistic-ot.sh`)
  that consumes the built fixture and asserts: (a) per-entry trees materialize at
  `docs/project/{backlog,implementation-plan,changelog}/<id>.md`; (b) regenerated mirrors
  byte-identical to source; (c) validate-pack.py Check 32/33/34 PASSES when run inside the
  built fixture (this is the most load-bearing — Check 32 should detect any decomposer
  regression against a real fixture). Wire this test step AFTER "build test fixtures"
  (line 208) and AFTER "restore committed manifest" (line 220). Without this test, a
  future BD-164 helper change that breaks decompose for the v11 surface would only trip
  if it also breaks the build step — silent regressions are possible if the round-trip
  check happens to no-op-pass.
- **Scope:** Cross-BD — affects BD-160 + BD-164 + BD-168 integration verification.
  Currently the integration boundary is implicit (lives inside build.sh's round-trip
  check); explicit CI coverage would catch regressions earlier.

#### SHOULD-3 — `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md` test-suite count snapshot is stale (46/46) but accurate as historical record

- **Severity:** SHOULD (the IMPL-REPORT's "46/46" tail of `validate-pack` output is a
  pre-BD-168-retro-fix snapshot; current state at HEAD `27374b4` is 65/65; reading the
  IMPL-REPORT post-flip would mislead about the current state)
- **Location:** `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md:337-345, 369-379`
- **Finding:** The BD-164 retro-fix IMPL-REPORT captures `validate-pack` output showing
  "pre-Batch-22 pack-self" OK-message wording and the BD-168 test-suite count at 46/46.
  Both are accurate AT THE TIME OF THAT FIX'S COMMIT (`03d0dd9`). But BD-168 retro-fix
  (commit `bd022e9`) subsequently swept the OK-message wording to "pre-BD-102 dog-food
  pack-self" AND expanded the BD-168 test suite from 46/46 to 65/65. A future reader of
  the IMPL-REPORT-BD-164-RETRO-FIX would see captured-output that no longer matches the
  current state. The IMPL-REPORT is a per-BD historical artifact, but it will sweep into
  `maintenance-docs/archive/v11/` at v11.0 ship (Pattern B) — at that point the staleness
  is permanent.
- **Evidence:**
  - `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md:337-345` shows captured `validate-pack`
    output with "pre-Batch-22 pack-self" wording (now obsolete)
  - `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md:376-378` reports BD-168 test count as
    "46/46" (now 65/65 after BD-168 retro-fix)
  - `IMPLEMENTATION-REPORT-BD-168-RETRO-FIX.md:34` documents the 46 → 65 expansion as
    "BD-168 test runner expanded 46 → 65 PASS"
  - Current `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` returns 65/65 PASS
- **Suggested remediation:** add a one-line annotation at the start of the BD-164-RETRO-FIX
  §4 verification section noting "captured tool output reflects state at commit `03d0dd9`;
  subsequent BD-168 retro-fix (commit `bd022e9`) expanded BD-168 test suite to 65/65 and
  swept OK-message wording to 'pre-BD-102 dog-food pack-self'." This makes the snapshot
  honest about its scope. Alternative: leave as-is and add a forward-pointing note in the
  CLEANUP-INPUTS file noting that pre-Pattern-B-sweep IMPL-REPORTs can carry stale captured
  output that the archive process should not "freshen" (the historical capture IS the
  audit-trail evidence; "freshening" it would erase the chronology).
- **Scope:** BD-164 retro-fix IMPL-REPORT — the report is per-BD, but the staleness is a
  cross-BD consequence (BD-168 retro-fix landed after BD-164 retro-fix).

### NIT findings (5)

#### NIT-1 — Minor wording divergence in pack-root trinity Key files block

- **Severity:** NIT (trinity files have a minor wording difference but substantive content
  is identical; the trinity rule permits this when the change is provably tool-specific OR
  when prose voice differs)
- **Location:** `CLAUDE.md:29`, `AGENTS.md:23`
- **Finding:** `CLAUDE.md:29` says `"- README.md — version history and layout"` while
  `AGENTS.md:23` says `"- README.md — version history and repo layout"`. The word "repo"
  added in AGENTS.md is the only difference between the two lines. GEMINI.md uses inline
  prose form ("Key docs: ..."), which is a known trinity-acceptable format divergence
  (Gemini convention is prose-block; Claude/Codex convention is bullet-block).
- **Evidence:**
  - `CLAUDE.md:29`: `"- README.md — version history and layout"`
  - `AGENTS.md:23`: `"- README.md — version history and repo layout"`
  - `GEMINI.md:5-11`: prose form (acceptable per `feedback_clarg_trinity` tool-specific
    exception)
- **Suggested remediation:** harmonize CLAUDE.md and AGENTS.md to the same wording (either
  "layout" or "repo layout" — pick one). Verify GEMINI.md prose carries the equivalent
  meaning.
- **Scope:** BD-167b PM-only edits (trinity Key files block).

#### NIT-2 — BD-119 §9.2 architect-doc update pattern not added to CLEANUP-INPUTS-SESSION-RULES.md

- **Severity:** NIT (this is a session learning that could inform the cleanup architect's
  pattern review, but is not strictly required for cleanup architect's job)
- **Location:** `CLEANUP-INPUTS-SESSION-RULES.md` (would be a new L9 or sub-section)
- **Finding:** The BD-119 §9.2 architect addendum (added 2026-05-16 alongside BD-160 ship)
  is a worked example of the pattern: "architect doc surfaces design intent; reality lands
  in a later BD; addendum cross-references the realized consumer." The pattern is
  load-bearing for v11.x onward (every future shipped surface that pre-existed in architect
  docs needs the same pattern). The CLEANUP-INPUTS-SESSION-RULES.md captures L1-L8 session
  learnings + L8.1 STATUS.md disclaimer divergence, but does not capture this BD-119 §9.2
  resolution pattern as a documented convention.
- **Evidence:**
  - `ARCHITECTURE-BD-119.md:652-666` is the worked example (Addendum (2026-05-16, BD-160))
  - `CLEANUP-INPUTS-SESSION-RULES.md` has no mention of "addendum" / "first realized
    consumer" / "BD-160 docstring carry-forward" pattern
  - BD-160 docstring update at `scripts/lib/migrator-core.sh:505-518` (verified in
    `IMPLEMENTATION-REPORT-BD-160-170.md:38`) is the in-code half of the same pattern
- **Suggested remediation:** add a new section to CLEANUP-INPUTS-SESSION-RULES.md (e.g.,
  L9 — "Architect-doc-vs-reality reconciliation pattern (BD-119 §9.2 addendum + BD-160
  docstring carry-forward)") naming the pattern and its three components (architect doc
  addendum + in-code docstring update + IMPL-REPORT cross-reference). The cleanup architect
  can then triage whether the pattern needs codification as a standing rule.
- **Scope:** Cleanup architect input; touches BD-119 + BD-160 worked example.

#### NIT-3 — `STATUS.md` disclaimer divergence already captured in L8.1 — no further action needed

- **Severity:** NIT (informational; calls out a properly-handled case)
- **Location:** `CLEANUP-INPUTS-SESSION-RULES.md:440-450`
- **Finding:** Per L8.1, the STATUS.md disclaimer wording divergence between PLAN §5.8
  and integration parent §5.3 is documented as routed-to-cleanup-architect. The IMPL-REPORT
  -BD-169.md §6.1 is the live forward-pointing anchor. This is correctly handled per
  `feedback_deferred_work_tracking`. No additional action needed for the batch flip.
- **Evidence:**
  - `CLEANUP-INPUTS-SESSION-RULES.md:440-450` (L8.1 sub-section)
  - `IMPLEMENTATION-REPORT-BD-169.md:391` (§6.1)
  - Implementation followed PLAN §5.8 verbatim (correct precedence per agent prompt)
- **Suggested remediation:** none — this is an observation that the deferred-work tracking
  rule was followed correctly.
- **Scope:** BD-169 (PLAN-vs-integration-parent reconciliation).

#### NIT-4 — `test-per-entry.sh` test-group narrative skip groups 6 + 11 of the original 11

- **Severity:** NIT (the BD-164 IMPL-REPORT mentions 11 test groups but the test-per-entry.sh
  has 11 groups; this is consistent. Filed for completeness only)
- **Location:** `scripts/tests/test-per-entry.sh`
- **Finding:** BD-164 IMPL-REPORT §3 lists "11 test groups" and §5 lists "57/57 PASS";
  current run at HEAD `27374b4` shows 57/57 PASS — consistent. No defect; filed as a
  spot-check observation.
- **Suggested remediation:** none.
- **Scope:** BD-164.

#### NIT-5 — Validator silently discards regenerator audit-trail warning on divergence path

- **Severity:** NIT (documented intentional asymmetry per BD-168 retro-fix S5; surfaced
  here so the cleanup architect has visibility if revisiting validator-vs-helper UX)
- **Location:** `scripts/validate-pack.py:2972-2982`
- **Finding:** The Check 32 path captures the helper's `pe_warn "PE_FORCE_OVERWRITE_MIRROR=1;
  overwriting hand-edited mirror"` into `result.stderr` and silently discards it. The
  decision is documented in-place ("the validator's FAIL message IS the audit trail; the
  §4.5 audit-trail intent was anchored on the migrator path"). This is intentional but
  surfaces the asymmetry: in the migrator path the warning IS the audit trail; in the CI
  validator path the FAIL message replaces it. If the cleanup architect ever revisits
  audit-trail uniformity (e.g., for tracker-mode reverse-direction validation), this
  decision should be re-examined.
- **Suggested remediation:** none for v11.0; documented in code with sufficient context.
  Cleanup architect input.
- **Scope:** BD-168.

---

## §3 — Cross-BD consistency check

### §3.1 — Helper public-API contract consistency (PASS)

All three call sites use the same BD-164 public-API function names + argument order:

| Call site | Function | Argument order |
|---|---|---|
| `scripts/lib/migrate-v10-to-v11/decompose.sh:177` | `per_entry_decompose` | `key, mono_path, stream_dir` |
| `scripts/init-project.sh` (no decompose; greenfield never has source) | (n/a) | (n/a) |
| `test-fixtures/build.sh:521` | `per_entry_decompose` | `key, mirror, dir` |
| `scripts/lib/migrate-v10-to-v11/decompose.sh:195` | `per_entry_regenerate_mirror` | `key, stream_dir, mirror_path` |
| `scripts/init-project.sh:1005` | `per_entry_regenerate_mirror` | `key, pe_dir, pe_mirror` |
| `test-fixtures/build.sh:527` | `per_entry_regenerate_mirror` | `key, dir, mirror` |
| `scripts/lib/migrate-v10-to-v11/decompose.sh:203` | `per_entry_regenerate_toc` | `key, stream_dir` |
| `scripts/init-project.sh:1009` | `per_entry_regenerate_toc` | `key, pe_dir` |
| `test-fixtures/build.sh:532` | `per_entry_regenerate_toc` | `key, dir` |

All three call sites use the SAME `key|mirror|dir` spec tuple format:

| Call site | Spec format |
|---|---|
| `scripts/lib/migrate-v10-to-v11/decompose.sh:145-148` | `"project-backlog\|docs/project/BACKLOG.md\|docs/project/backlog"` |
| `scripts/init-project.sh:990-993` | `"project-backlog\|docs/project/BACKLOG.md\|docs/project/backlog"` |
| `test-fixtures/build.sh:498-501` | `"project-backlog\|docs/project/BACKLOG.md\|docs/project/backlog"` |

VERDICT: helper public-API contract is byte-aligned across three call sites. No drift.

### §3.2 — Forward-pointing convention (PASS with one defect — see MUST-1)

The "Batch 23 (BD-102 dog-food)" anchor is correctly used in:
- `PACK-AGENTS.md:178-187` (forward-pointing note inside PM-only directories block)
- `README.md:189, 191` (Repository Layout entries for `/backlog/` and `/changelog/`)
- `scripts/validate-pack.py:128, 2898, 3072, 3295` (validator OK-message wording, post
  BD-168 retro-fix sweep)
- `IMPLEMENTATION-REPORT-BD-167.md:656, 666` (post-decompose narrative)
- `IMPLEMENTATION-REPORT-BD-167b-RETRO-FIX.md:20, 81, 104-113, 338, 345`

DEFECT (MUST-1): `scripts/lib/migrate-v10-to-v11/decompose.sh:131` still says "Batch 22
dog-food" — missed by the BD-168 retro-fix sweep. Parallel defect in
`IMPLEMENTATION-REPORT-BD-165.md:634`.

### §3.3 — Vocabulary consistency (PASS)

Term: "per-entry tree" — used uniformly across `scripts/lib/per-entry/`, `scripts/lib/migrate-v10-to-v11/decompose.sh`,
`scripts/init-project.sh`, `test-fixtures/build.sh`. No instances of "decomposed tree"
or "decompose tree" alternative wording. Vocabulary lock is honored.

Term: "per-stream contract" (referring to `_rules.md`) — used uniformly in trinity Key
files block + PACK-CHAT.md + PACK-AGENTS.md. No alternative wording in evidence.

Term: "regenerated mirror" — used uniformly in trinity pack-memory bullet + README +
PM-CHAT + MERGE-STRATEGY + MIGRATION + audit-methodology SKILL. No alternative ("derived
mirror" / "generated mirror") in evidence.

### §3.4 — Stream key naming (PASS)

The five stream keys defined in `scripts/lib/per-entry/_lib.sh:64` are:
- `pack-backlog`
- `pack-changelog`
- `project-backlog`
- `project-implementation-plan`
- `project-changelog`

Same keys used in:
- `scripts/validate-pack.py:189-193` STREAMS constant (pack-side only — pack-backlog +
  pack-changelog)
- `scripts/lib/migrate-v10-to-v11/decompose.sh:145-148` (project-side only)
- `scripts/init-project.sh:990-993` (project-side only)
- `test-fixtures/build.sh:498-501` (project-side only)

VERDICT: stream-key vocabulary is byte-aligned. No drift.

### §3.5 — Trinity rule application (PASS)

Pack-root trinity:
- `CLAUDE.md:34` + `AGENTS.md:28` + `GEMINI.md:23-24` carry the same per-entry source-of-
  truth reference (CLAUDE/AGENTS bullet form; GEMINI inline-prose form per tool convention)
- `CLAUDE.md:155-170` + `AGENTS.md:132-147` + `GEMINI.md:113-128` carry the byte-identical
  pack-memory bullet "Per-entry trees vs mirrors — mode-dependent source of truth"

Project-template trinity:
- `project-template/CLAUDE.md:229` + `project-template/AGENTS.md:213` +
  `project-template/GEMINI.md:224` carry the parallel "Per-entry source-of-truth trees
  (v11.0)" paragraph

Pack-* agent trinity (5 agents × 3 CLIs = 15 files): per BD-167b retro-fix verification,
all 15 carry the same "Inputs to read" addition. Codex `.toml` format wraps in `prompt =
"""..."""` per Addendum #2 §1.4. (See BD-167b-RETRO-FIX O1 — `.gemini/agents/pack-planner.md`
self-reference was corrected from "CLAUDE.md" to "GEMINI.md" — pre-existing trinity defect
unrelated to BD-167b's scope but fixed in passing.)

NIT-1 surfaces a minor wording divergence in the Key files line (CLAUDE.md "layout" vs
AGENTS.md "repo layout"), but it's not a trinity violation per the wording-tolerance
heuristic.

### §3.6 — Codex `.toml` vs `.md` discipline (PASS)

Per Addendum #2 §1 BLOCKER correction: pack-* Codex agents are `.toml`, not `.md`.
Verified at `.codex/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.toml`
(5 files). Codex skills are `.md` (Addendum #2 §6.6) — verified at
`.codex/skills/pack-startup/SKILL.md`. Gemini commands are `.toml` — verified at
`.gemini/commands/pack-startup.toml`. Format selection is uniform per CLI.

---

## §4 — Integration coherence check

### §4.1 — End-to-end chain (PASS)

The per-entry split feature integrates end-to-end across three call sites + validators +
audit-methodology + operator-discoverability:

**Call site 1: v10→v11 migrator (BD-165).** `scripts/migrate-v10-to-v11.sh` post-dispatch
hook 6th sub-op `_v10_to_v11_decompose_streams` (defined in
`scripts/lib/migrate-v10-to-v11/decompose.sh`) sources BD-164 helpers, decomposes project-
side monolithic mirrors into per-entry trees, regenerates mirrors + TOCs. BD-095 mode
bridge (`--force-overwrite-mirror`) plumbed through `migrator-core.sh:328`.

**Call site 2: greenfield init (BD-166).** `scripts/init-project.sh:961-1014` extends
stage_s11_v11_artifacts to install canonical templates from `project-template/docs/project/<stream>/`
(created by BD-167) and invoke BD-164 helpers against empty input to produce empty mirrors
+ TOCs.

**Call site 3: fixture builder (BD-160/170).** `test-fixtures/build.sh:480-548` extends
v11 case dispatch to apply C2/C3 customizations + invoke BD-164 helpers + verify byte-
identity round-trip.

**Validators (BD-168).** `scripts/validate-pack.py:189` defines STREAMS constant; lines
2841/3049/3248 define Check 32/33/34 each invoking BD-164 helpers via subprocess against
the on-disk pack-self per-entry tree (when present). Currently SKIPs because pack-self
trees don't materialize until Batch 23.

**Audit-methodology (BD-169).** `project-template/skills/audit-methodology/SKILL.md:75-77`
extends rule 29 (auditor-docs) to declare per-entry trees IN SCOPE and regenerated mirrors
OUT OF SCOPE when per-entry tree is present. Detection criterion (`stream_dir.is_dir()` +
`_rules.md` presence) aligned with validator's Check 32/33/34 detection per BD-169-FIX S1.

**Operator surface (BD-169 + BD-169b).** PM-CHAT.md, PACK-CHAT.md, MERGE-STRATEGY,
MIGRATION-v10-to-v11, pack-startup, pm-startup, trinity Key files, PACK-AGENTS.md, README
Repository Layout — all carry per-entry tree references with correct vocabulary +
forward-pointing Batch 23 note.

VERDICT: the chain integrates end-to-end. The MUST-1 defect (stale "Batch 22" in
decompose.sh:131) does not block end-to-end function — it's a code-comment defect with
no behavioral impact.

### §4.2 — Helper sourcing pattern (PASS)

All three call sites use the same `type`-guard sourcing pattern (idempotent re-source):

- `scripts/lib/migrate-v10-to-v11/decompose.sh:85-100` (the canonical reference per
  documentation)
- `scripts/init-project.sh:968-983` (cites decompose.sh:85-100 in comments)
- `test-fixtures/build.sh:480-490` (cites decompose.sh:85-100 in comments)
- `scripts/lib/per-entry/decompose.sh:30-33` (self-loading guard for `_lib.sh`)

VERDICT: sourcing pattern is uniform; future stream additions are mechanical.

### §4.3 — `_v8-resolved-archive.md` scoping (PASS)

Per integration parent §11.2 + §2.6: `_v8-resolved-archive.md` is pack-`/backlog/` only;
project-side streams have no analog. Verified:
- `scripts/lib/per-entry/_lib.sh:73`: `pack-backlog` support set includes
  `_v8-resolved-archive.md`
- `scripts/lib/per-entry/_lib.sh:82, 89, 102, 114`: other 4 stream support sets do NOT
- `scripts/validate-pack.py:2886-2889`: validator's `known_supporting_for` map has
  `_v8-resolved-archive.md` only for `pack-backlog`
- `project-template/skills/audit-methodology/SKILL.md:76`: rule 29 supporting-file list
  carries `(pack /backlog/ only per integration parent §2.6 + §10.5)` qualifier per
  BD-169-FIX S2

VERDICT: scoping is consistently enforced.

### §4.4 — `_format.md` scoping (PASS)

Per integration parent §3.2 + §9.7 + sidecar §3.5: `_format.md` is project-changelog only;
pack-changelog has no analog. Verified:
- `scripts/lib/per-entry/_lib.sh:114`: `project-changelog` support set includes
  `_format.md`
- Other 4 stream support sets do NOT
- `project-template/skills/audit-methodology/SKILL.md:76`: rule 29 supporting-file list
  carries `(changelog-stream-only per integration parent §3.2 + §10.5)` qualifier per
  BD-169-FIX N2
- `project-template/docs/project/changelog/_format.md` ships from BD-167
- `project-template/docs/project/{backlog,implementation-plan}/_format.md` do NOT exist

VERDICT: scoping is consistently enforced.

### §4.5 — Architect-doc binding compliance (PASS)

Spot-checked architect bindings from PLAN §5.X "Constraints (architect-doc bindings)":

- Layer 2 of discoverability is HTML-comment line-1 only (Addendum #2 §2) — VERIFIED in
  `scripts/lib/per-entry/_lib.sh:281-298` (no body field; line-1 HTML comment only).
- Pack-side per-entry-tree paths are non-dot per Addendum #1 §10 (`/backlog/`, `/changelog/`)
  — VERIFIED in `_lib.sh:73-83` (support sets), `_lib.sh:289` (back-pointer composition).
- Codex pack-* agent file extension is `.toml` per Addendum #2 §1 — VERIFIED via
  `ls .codex/agents/pack-*.toml` (5 files).
- Codex auditor agent file extension is `.toml` per Addendum #2 §1.5 — VERIFIED via
  `ls project-template/.codex/agents/auditor.toml`.
- Regenerator divergence in apply/resume BLOCKS unless `--force-overwrite-mirror`
  (Addendum #2 §4) — VERIFIED in `scripts/lib/per-entry/mirror-generate.sh:241-247` +
  `scripts/lib/migrate-v10-to-v11/decompose.sh:124-126` + `scripts/lib/migrator-core.sh:328`.
- PACK-CHAT.md row text per Addendum #2 §5.2 — VERIFIED at `PACK-CHAT.md:47-48`.
- PM-CHAT.md row text per Addendum #2 §5.4 — VERIFIED at
  `project-template/docs/pack/PM-CHAT.md` (Group A Addition A per BD-169 IMPL-REPORT).
- BD-167 absorption of BD-161 net-new SKILL.md installs per integration parent §17.2 —
  VERIFIED in `scripts/migrate-v10-to-v11.sh` install step extension.

VERDICT: all spot-checked architect bindings are honored. (Full coverage was the per-BD
review's responsibility; broad review confirms no cross-BD architectural drift.)

---

## §5 — CI coverage holism

### §5.1 — Test runner inventory (PASS)

Per-BD test runners and their wire-in to validate-pack.yml:

| BD | Test runner | Wired in | Order |
|---|---|---|---|
| BD-164 | `scripts/tests/test-per-entry.sh` | YES (line 154-156) | Before BD-168 tests |
| BD-168 | `scripts/tests/test-validate-pack-checks-32-33-34.sh` | YES (line 157-159) | After BD-164 tests |
| BD-165 | `scripts/tests/test-migrate-v10-to-v11-decompose.sh` | YES (line 196-198) | After base migrator tests |
| BD-166 | (folded into) `scripts/tests/test-init-project.sh` | YES (line 184-186) | Stage S11 test groups added |
| BD-160 + BD-170 | `test-fixtures/build.sh` round-trip (inline) | YES (build at line 208) | Build → verify manifest |

VERDICT: every Batch 19 BD has CI coverage. The test-per-entry → validate-pack-checks-32/33/34
ordering ensures BD-164 helpers are validated before BD-168 validators that depend on them.

### §5.2 — CI step build-order dependencies (PASS)

Per validate-pack.yml step header comments (lines 24-70):
- "build test fixtures" (line 208) is the side-effect step that materializes
  `test-fixtures/v11-realistic-ot/` (gitignored)
- "restore committed manifest" (line 220) restores the pinned SHAs
- "fixture manifest verify" (line 223) compares built vs pinned
- "migrator-skills tests" (line 230) — depends on `v10-realistic-ot` (BD-147 G1
  golden-snapshot) — runs AFTER build
- "persona contracts" (line 233) — depends on `v10-realistic-ot` and
  `existing-project-mid-dev` — runs AFTER build

VERDICT: build-order dependencies are correctly declared and tested. The `v11-realistic-ot`
fixture is built (line 208) and SHA-verified (line 223), but no downstream test step
consumes its contents — see SHOULD-2 for this integration-boundary gap.

### §5.3 — Integration gap (SHOULD-2)

No test step consumes the built v11-realistic-ot fixture beyond manifest verification.
The fixture's round-trip byte-identity is verified inline in `test-fixtures/build.sh:539`
at build time. If the round-trip check ever no-op-passes (e.g., due to a future bug that
makes both sides byte-identical for the wrong reason), there's no second validator. See
SHOULD-2 for remediation.

---

## §6 — CLEANUP-INPUTS-SESSION-RULES.md completeness assessment

### Present and load-bearing
- L1-L8 from the prompt (pack-chat undocumented rules + v11-dev session learnings)
- User strategic concerns (cross-CLI parity for rules; version update propagation;
  greenfield install propagation)
- L8 — Sub-agent SendMessage-stop defiance + PREFLIGHT pattern (added 2026-05-16)
- L8.1 — STATUS.md disclaimer literal divergence between PLAN §5.8 and integration
  parent §5.3 (added during BD-169 fix pass per N1)

### MISSING — recommended additions for the cleanup architect

1. **L9 — Architect-doc-vs-reality reconciliation pattern (BD-119 §9.2 addendum + BD-160
   docstring carry-forward).** See NIT-2. This is a worked example of the
   architect-anticipates → BD-realizes → addendum-cross-references pattern. The cleanup
   architect should triage whether this needs codification as a standing rule. Anchor:
   `ARCHITECTURE-BD-119.md:652-666` + `scripts/lib/migrator-core.sh:505-518` +
   `IMPLEMENTATION-REPORT-BD-160-170.md:38`.

2. **L10 — Captured-output staleness in IMPL-REPORTs (SHOULD-3).** When an IMPL-REPORT
   captures tool output in §4 verification, subsequent retro-fix work may sweep the
   output's wording or expand the test count. The historical capture remains accurate
   AT-COMMIT but becomes a misleading snapshot when read post-batch. The cleanup architect
   should decide: (a) annotate captured-output as commit-pinned, or (b) freshen all
   captured-output at Pattern B archive sweep. Anchor:
   `IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md:337-345, 376-378` vs current state.

3. **L11 — "33 invoked checks" wording inconsistency (SHOULD-1).** The arithmetic gap in
   the README claim is a minor wording defect that propagated across multiple sites. The
   cleanup architect should decide on the durable phrasing (numbered-only count vs
   numbered+informational count) and apply it to all three sites at once. Anchor:
   `README.md:60, 195` + `IMPLEMENTATION-REPORT-BD-168.md:349`.

### Suggested L8.1-style sub-section format

The L8.1 sub-section pattern (small declarative paragraph naming the divergence + cross-
references + routing to cleanup architect) works well. Recommend matching it for the
above additions.

### Completeness verdict

The cleanup-inputs file is substantially complete for the cleanup architect's job. The
three suggested additions (L9 + L10 + L11) are NIT-level — they would help but are not
strictly required. The L1-L8 + L8.1 corpus covers the load-bearing session learnings.

---

## §7 — Pre-flip sanity check

### §7.1 — Status field accuracy (PASS)

All 11 BDs verified `Status: Open` at HEAD `27374b4`:

| BD | Line | Status |
|---|---|---|
| BD-170 | 1401 | Open |
| BD-169b | 1414 | Open |
| BD-169 | 1426 | Open |
| BD-168 | 1442 | Open |
| BD-167b | 1454 | Open |
| BD-167 | 1471 | Open |
| BD-166 | 1487 | Open |
| BD-165 | 1498 | Open |
| BD-164 | 1511 | Open |
| BD-161 | 1557 | Open |
| BD-160 | 1568 | Open |

No BDs have been prematurely flipped. The 19h commit will flip all 11 to `Status: Resolved`
in the PM-only commit.

### §7.2 — Resolved-line readiness (PASS)

Each BD's Resolved-line can be cleanly written:

| BD | Resolution claim |
|---|---|
| BD-164 | Helpers landed in commit `2b6ad7f` (BD-164 IMPL-REPORT cites SHA); retro-fix in commit `03d0dd9` |
| BD-165 | Migrator sub-op + flag landed in commit `a5b4a6e`; retro-fix in commit `c0723b7` |
| BD-166 | Init-project extension landed in commit `91e497c`; retro-fix in commit `b2b7e4c` |
| BD-167 | Pack-product templates + install plumbing in commit `ab51d76` (per IMPL-REPORT); retro-fix in commit `80b025a`; absorbs BD-161 |
| BD-167b | PM-only edits landed in commit `8fac7d0` (BD-167b-RETRO-FIX cites parent SHA `80b025a`); separate PM commit per agents-never-commit |
| BD-168 | Validator Checks 32/33/34 landed in commit `6696182`; retro-fix in commit `bd022e9` |
| BD-160 | Combined in commit `a57dd04` with BD-170 (per R-2); inline review-fix in `9c238ab` |
| BD-170 | Combined in commit `a57dd04` with BD-160; round-trip verified at build |
| BD-169 | Pack-product wording in commit `cf67a96`; inline review-fix in `62f9eec` |
| BD-169b | PM-only wording in commit `27374b4` |
| BD-161 | Absorbed into BD-167 per integration parent §17.2 |

All Resolved-line claims can be written cleanly with the commit SHAs from the ledger.
BD-160's Resolved-line should reference the combined commit `a57dd04` with the R-2
rationale per PLAN §10.2. BD-161's Resolved-line should reference BD-167 absorption per
integration parent §17.2 + Addendum #1 §6.4 BD table.

### §7.3 — Blockers / Unblocks integrity (PASS)

Spot-checked:
- BD-164 Blockers: BD-104 (Resolved), BD-128 (Resolved), BD-131..BD-134 (Resolved),
  BD-111 (Resolved) — all blockers cleared
- BD-165 Blockers: BD-164 (about to flip in 19h) — internal-to-batch dependency, valid
- BD-166 Blockers: BD-164 + BD-167 — internal-to-batch, valid
- BD-167 Blockers: BD-164 — internal-to-batch, valid
- BD-167b Blockers: BD-167 — internal-to-batch, valid
- BD-168 Blockers: BD-164 + BD-167 — internal-to-batch, valid
- BD-169 Blockers: BD-167 — internal-to-batch, valid
- BD-169b Blockers: BD-169 — internal-to-batch, valid
- BD-170 Blockers: BD-164 (+ trivially BD-160 per R-2) — internal-to-batch, valid

BD-170 Unblocks: BD-102 dog-food (Batch 23) — forward-pointing, resolves at Batch 23.
BD-160 Unblocks: includes "BD-120 NIT 2 carry-forward" — BD-120 already Resolved; the
carry-forward narrative is informational.

All references resolve.

### §7.4 — Blockers for flip (NONE)

No BD has an unresolved blocker or a known-defect note that would block the flip. The
MUST-1 defect is a code-comment in BD-165 — it does not block correctness of BD-165's
landed function. Pack Chat can choose to (a) apply the MUST-1 fix as a pre-flip patch
or (b) flip first and apply as a follow-up — either is defensible. The recommended
sequence is (a) since the fix is one-line mechanical.

VERDICT: all 11 BDs are flip-ready.

---

## §8 — Observations (informational; not findings)

1. **CI step naming inconsistency between Batch number and BD number.** Some CI steps
   say "BD-N" (e.g., line 188 "migrate-v10-to-v11 tests (BD-085)"); some say "BD-N/M"
   (e.g., line 208 "build test fixtures (BD-115/116/117)"). Not a defect; cosmetic.

2. **The `_v8-resolved-archive.md` is pack-self only and pack-self doesn't have it yet.**
   The architect docs + helpers + validator all correctly scope it to pack-backlog stream;
   the actual file lands at Batch 23 (BD-102 dog-food). Currently checked by helpers when
   present, SKIP when absent. Correct per integration parent §10.5.

3. **`test-init-project.sh` reports 67/67 PASS** — up from the BD-164-RETRO-FIX-reported
   34/34. BD-166 retro-fix added 33 new test groups for the S11 sub-step 6/7 surface.
   The BD-169-FIX IMPL-REPORT correctly reports 67/67 at current HEAD.

4. **`test-validate-pack-checks-32-33-34.sh` reports 65/65 PASS** — up from BD-168
   IMPL-REPORT's original 46/46. BD-168 retro-fix expanded the suite +19. All three
   call sites' downstream IMPL-REPORTs (BD-160-170, BD-169-FIX) cite the current 65/65.
   Only BD-164-RETRO-FIX still cites 46/46 (historical snapshot — see SHOULD-3).

5. **The BD-119 §9.2 architect addendum (2026-05-16) about BD-160 first-realized-consumer**
   is a pattern worth codifying — the cleanup architect should see NIT-2.

6. **Trinity rule for `.gemini/agents/pack-planner.md`** was corrected in BD-167b retro-fix
   O1 (file referenced CLAUDE.md instead of GEMINI.md). This was a pre-existing trinity
   defect predating Batch 19, fixed in passing during BD-167b retro-fix because BD-167b
   touched all 15 pack-* agent files. Now corrected.

---

**End of report.** Pack Chat should triage the 1 MUST + 3 SHOULD + 5 NIT findings and
spawn a fix-coder per `feedback_pack_chat_does_no_fixes`. The MUST-1 defect (one-line
text sweep) is the only blocker for the cleanest possible 19h flip; the SHOULD findings
are documentation accuracy + test-coverage gaps that should be addressed pre-flip per
`feedback_no_deferral_without_user_direction` and `feedback_deferral_is_scope_creep`.
The NIT findings are quality-of-life improvements. Per `feedback_fix_all_review_findings`
default-to-fix-all behavior applies.

Reviewed: 2026-05-16 by pack-reviewer sub-agent. HEAD `27374b4` (Batch 19 commit 19g-PM).
Read-only; no source modifications. Report file is the sole Write deliverable.
