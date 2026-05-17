# IMPLEMENTATION REPORT — Batch 19b-2-RC9 — Trinity manifest-regen rule (RC9)

**Author:** pack-coder (19b-2-RC9 coder)
**Date:** 2026-05-17
**Branch:** v11-dev
**Base HEAD:** `ef9e5c7fe6adadc6d9deb27f3d2b73bf6a759c2a`
**Final HEAD:** `ef9e5c7fe6adadc6d9deb27f3d2b73bf6a759c2a` (unchanged — coder makes no git state changes)
**Architect doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`
**Ship target:** v11.0 (unlaunched)

---

## §1 — Summary

Appended one new bullet (RC9 — "Regenerate test-fixtures/manifest.txt on every v11-surface commit.") to the `### Repo conventions` sub-section in all three pack-root trinity files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`. Bullet text matches architect doc §4.1 verbatim (byte-identical across all three files). Placement is after RC8 (Architect-doc-vs-reality reconciliation), before the blank line that precedes `### Project goals (v11)` — per architect §5 (chronological-append pattern).

Working-tree state delta from base HEAD:
- `M CLAUDE.md` (+42 lines, 0 deletions)
- `M AGENTS.md` (+42 lines, 0 deletions)
- `M GEMINI.md` (+42 lines, 0 deletions)
- (Pre-existing, untouched: `M PACK-CHAT.md` from prior coder session; various untracked `maintenance-docs/v11-implementation/*.md` workflow artifacts)

Verification: `python3 scripts/validate-pack.py` PASS (all 35 checks). Baseline test spot-checks PASS: `scripts/tests/test-per-entry.sh` 57/57; `scripts/tests/test-init-project.sh` 67/67. Trinity parity diff returns empty (EXIT 0) for CLAUDE.md ↔ AGENTS.md and CLAUDE.md ↔ GEMINI.md `### Repo conventions` sub-sections post-edit, matching pre-edit parity state.

Manifest regen for this commit: **NOT NEEDED.** The trinity files at pack-root are NOT v11-surface (v11-surface = `project-template/` or `scripts/`, per the RC9 rule itself). This commit therefore does not require `test-fixtures/manifest.txt` regeneration — the recursive base case held: the rule that requires manifest regen for v11-surface edits is itself a non-v11-surface edit.

---

## §2 — Pre-edit trinity parity verification

### §2.1 — CLAUDE.md ↔ AGENTS.md `### Repo conventions` parity

Command:

```
diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) <(sed -n '/^### Repo conventions/,/^### /p' AGENTS.md)
```

Result: EMPTY output (no differences). Exit status: 0. CLAUDE.md and AGENTS.md `### Repo conventions` sub-sections were byte-identical pre-edit.

### §2.2 — CLAUDE.md ↔ GEMINI.md `### Repo conventions` parity

Command:

```
diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) <(sed -n '/^### Repo conventions/,/^### /p' GEMINI.md)
```

Result: EMPTY output (no differences). Exit status: 0. CLAUDE.md and GEMINI.md `### Repo conventions` sub-sections were byte-identical pre-edit.

### §2.3 — Per-CLI variants needed for GEMINI.md?

**NO.** Because GEMINI.md's `### Repo conventions` sub-section was byte-identical to CLAUDE.md/AGENTS.md pre-edit (per §2.2), GEMINI.md receives the same byte-identical RC9 bullet as the other two files. No tighter-prose variant required.

### §2.4 — Pre-edit line counts

```
     455 CLAUDE.md
     408 AGENTS.md
     393 GEMINI.md
```

(The line-count differences between files reflect divergence in OTHER sub-sections — primarily `### Sub-agent behavior (Claude-only)` which only exists in CLAUDE.md, and minor prose-form differences in `## Pack memory` sections that are not in scope for this edit.)

---

## §3 — Bullet text per file (verbatim final state)

### §3.1 — CLAUDE.md (final lines 449-490)

The RC9 bullet was inserted between the RC8 "Architect-doc-vs-reality reconciliation" closing line (`...existed in an architect doc.`) and the blank line preceding `### Project goals (v11)`. Final text:

```
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/` or `scripts/`. Any
  commit whose diff includes a file under either directory MUST also
  regenerate `test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the SAME commit. The trigger is intentionally
  inclusive — false positives (e.g., a `scripts/test-*.sh` edit that
  doesn't actually affect fixtures) cost ~30-90s of unnecessary
  rebuild but produce no incorrect manifest change; false negatives
  within v11-surface are impossible because every v11-surface file
  lives under one of these two directories. v11-* fixture row SHAs
  drift naturally with any v11-surface change (per
  `test-fixtures/README.md` § Determinism and the `_update_manifest`
  comment at `test-fixtures/build.sh:903-912`); a stale manifest
  fails CI's `fixture manifest verify` step (BD-115, RELEASE-GATE
  item 5) even when every functional test passes. **Why:** prevents
  the 2026-05-17 incident where commit `667d2dd` shipped v11-surface
  trinity edits without regenerating the manifest, CI failed on the
  manifest-comparison step alone (all 40+ functional steps PASSED),
  and recovery commit `ef9e5c7` had to land as a separate `fix:`
  commit; the drift was the cumulative effect of three intentional
  v11-surface commits (`cf67a96` BD-169 pack-product wording,
  `62f9eec` BD-169 review/fix, `479fef5` Batch 19 broad review/fix)
  since the last manifest regen at `a57dd04` (BD-160). **How to
  apply:** before staging a commit whose diff includes any file
  under `project-template/` or `scripts/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
```

### §3.2 — AGENTS.md (final lines 402-443)

Byte-identical to §3.1 above. Inserted at the same relative position (after RC8, before the blank line preceding `### Project goals (v11)`).

### §3.3 — GEMINI.md (final lines 377-418)

Byte-identical to §3.1 above. Inserted at the same relative position.

---

## §4 — Post-edit trinity parity verification

### §4.1 — CLAUDE.md ↔ AGENTS.md `### Repo conventions` parity

Command:

```
diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) <(sed -n '/^### Repo conventions/,/^### /p' AGENTS.md)
```

Result: EMPTY output. Exit status: 0. Parity preserved post-edit (now with new RC9 bullet present and byte-identical in both files).

### §4.2 — CLAUDE.md ↔ GEMINI.md `### Repo conventions` parity

Command:

```
diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) <(sed -n '/^### Repo conventions/,/^### /p' GEMINI.md)
```

Result: EMPTY output. Exit status: 0. Parity preserved post-edit (GEMINI.md byte-identical to CLAUDE.md/AGENTS.md `### Repo conventions` sub-section).

### §4.3 — Post-edit line counts (delta from pre-edit)

```
     497 CLAUDE.md   (+42 from 455)
     450 AGENTS.md   (+42 from 408)
     435 GEMINI.md   (+42 from 393)
```

Each trinity file grew by exactly 42 lines — matching the 42-line bullet size analyzed in architect §4.2. Delta is byte-identical across all three files.

---

## §5 — Verification evidence

### §5.1 — `python3 scripts/validate-pack.py` output tail

Final summary banner:

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

All 35 validator checks PASS — no regressions introduced by the trinity edits.

### §5.2 — `scripts/tests/test-per-entry.sh` output tail

```
=== Group 11: bash 3.2 compatibility smoke ===
  PASS 11.1 helpers source cleanly under bash --norc

=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

### §5.3 — `scripts/tests/test-init-project.sh` output tail

```
=== Group 5: BD-166 sub-step 7 idempotency (proof loop) ===
  PASS 5.1 helper-level re-invocation rc=0
  PASS 5.2 docs/project/BACKLOG.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/IMPLEMENTATION-PLAN.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/CHANGELOG.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/backlog/_toc.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/implementation-plan/_toc.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/changelog/_toc.md byte-identical after helper re-invocation (idempotent)

=== Summary ===
Passed: 67
Failed: 0
All tests passed.
```

### §5.4 — `wc -l` for each trinity file before and after

| File | Pre-edit lines | Post-edit lines | Delta |
|---|---|---|---|
| `CLAUDE.md` | 455 | 497 | +42 |
| `AGENTS.md` | 408 | 450 | +42 |
| `GEMINI.md` | 393 | 435 | +42 |

Each file grew by exactly 42 lines; deltas are byte-identical (same insertion text).

### §5.5 — Manifest regen evidence

**Not applicable for this commit.** Per the RC9 rule itself (and architect §6 / success criterion #6), the trinity files at pack-root are NOT v11-surface — v11-surface is defined as `project-template/` or `scripts/`. The edited paths are:

- `/CLAUDE.md` — pack-root, not under either trigger directory
- `/AGENTS.md` — pack-root, not under either trigger directory
- `/GEMINI.md` — pack-root, not under either trigger directory

No file under `project-template/` or `scripts/` was edited; therefore no manifest rebuild is required for this commit. This is the recursive base case noted in the success criteria: the rule that requires manifest regen for v11-surface edits is itself a non-v11-surface edit.

---

## §6 — Out-of-scope check

`git status --short` after all edits:

```
 M AGENTS.md                  <-- IN SCOPE (RC9 trinity edit)
 M CLAUDE.md                  <-- IN SCOPE (RC9 trinity edit)
 M GEMINI.md                  <-- IN SCOPE (RC9 trinity edit)
 M PACK-CHAT.md               <-- PRE-EXISTING from prior 19b-2 coder session; NOT touched by this coder
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md   <-- pre-existing untracked architect doc (this coder's input)
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md                    <-- pre-existing untracked
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md                       <-- pre-existing untracked
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md                         <-- pre-existing untracked
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md        <-- pre-existing untracked
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2.md        <-- pre-existing untracked
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-1.md                  <-- pre-existing untracked
?? maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md                               <-- pre-existing untracked
?? maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md                 <-- pre-existing untracked
```

The new file `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md` (this report) will appear as additional `??` after the Write — it is this coder's IMPL-REPORT output and is not part of the scope-edit set.

**Scope check PASS:**
- Only the three trinity files at pack-root were modified by this coder.
- `PACK-CHAT.md` was NOT touched by this coder (modification predates this session; left as-is per instructions).
- No edits to `project-template/`, `supporting-docs/`, `scripts/`, `test-fixtures/`, `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `PACK-AGENTS.md`, or any other file outside the trinity-edit scope.
- No edits to any other section within the trinity files (only `### Repo conventions` got the new bullet).

---

## §7 — Coder flags / open questions for Pack Chat

None. Implementation went mechanically per architect §4.1 (verbatim bullet text), §5 (end-of-`### Repo conventions` placement after RC8), and §6 (UNIVERSAL classification, byte-identical across all three trinity files — confirmed appropriate by pre-edit parity check showing all three files were byte-identical for this sub-section).

### §7.1 — Notes for Pack Chat commit step

1. **Files to stage for this commit:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (these three only). PACK-CHAT.md modification is from a different coder session and is explicitly out of scope per this prompt. The IMPL-REPORT itself (`IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md`) is a maintenance-docs workflow artifact — Pack Chat handles its disposition (stage with commit or leave untracked per existing 19b artifact handling).
2. **Manifest regen for this commit:** Not needed (recursive base case — see §5.5). Do NOT run `bash test-fixtures/build.sh --all --clean` before staging — the diff would be empty and the action would waste 30-90s.
3. **Commit message:** Suggested template per architect §10.4 (Pack Chat may refine). NOT a `fix:` commit (no BD anchor; adds a standing rule) — use `feat: v11 — Batch 19b-2 trinity manifest-regen rule (RC9)` shape per architect.
4. **No deviations from architect plan.** Bullet text matches §4.1 verbatim; placement matches §5; classification matches §6; cross-references match §7; trigger form is Form C (fuzzy directory) per architect §2.1 and §8.3.

### §7.2 — Definition-of-Done checklist

| Item | Status |
|---|---|
| Pre-edit parity diff CLAUDE.md ↔ AGENTS.md ↔ GEMINI.md | PASS (all byte-identical) |
| Bullet text matches architect §4.1 verbatim in all three files | PASS |
| Bullet placement after RC8 in all three files | PASS |
| Bullet byte-identical across CLAUDE.md / AGENTS.md / GEMINI.md | PASS |
| No edits to other sub-sections within trinity files | PASS |
| No edits to files outside the three trinity files (this coder) | PASS |
| Post-edit parity diff CLAUDE.md ↔ AGENTS.md ↔ GEMINI.md | PASS (all byte-identical, with new bullet) |
| `validate-pack.py` PASS | PASS (35/35 checks) |
| Baseline test spot-checks PASS | PASS (`test-per-entry.sh` 57/57, `test-init-project.sh` 67/67) |
| Manifest regen for this commit | N/A (non-v11-surface edit) |
| IMPL-REPORT written to specified path | PASS |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |
| No state-changing git verbs used by coder | PASS (only `rev-parse`, `status`, `diff --stat` — all read-only) |
| HEAD unchanged on coder's worktree | PASS (`ef9e5c7fe6adadc6d9deb27f3d2b73bf6a759c2a` at start and end) |

### §7.3 — Files-changed inventory

| Path | Change type | Notes |
|---|---|---|
| `/CLAUDE.md` | modified | +42 lines (RC9 bullet appended to `### Repo conventions`) |
| `/AGENTS.md` | modified | +42 lines (byte-identical RC9 bullet) |
| `/GEMINI.md` | modified | +42 lines (byte-identical RC9 bullet) |
| `/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md` | new | This report |

No deletions. No renames. No file-mode changes.

### §7.4 — Plan deviations

**Zero deviations.** Architect doc was specific about bullet text (§4.1 verbatim), placement (§5 after RC8), classification (§6 UNIVERSAL byte-identical), and trigger form (§2.1 / §8.3 fuzzy directory). Pre-edit parity check confirmed GEMINI.md does NOT use a tighter prose form for this sub-section, so the contingent "produce a tighter-wording GEMINI variant" path in the prompt's Goal #3 was not triggered — byte-identical was correct for all three files.

### §7.5 — New POQs introduced

None.

---

## §8 — Cross-reference for Pack Chat

- **Architect doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`
- **Prior batch commits in lineage:**
  - `667d2dd` — Batch 19b-1 trinity `## Pack memory` restructure (the v11-surface commit that motivated this rule)
  - `ef9e5c7` — fix: manifest regen recovery (the proximate-cause incident this rule prevents)
- **Worked-example anchors named in RC9 bullet body:** `667d2dd`, `ef9e5c7`, `cf67a96`, `62f9eec`, `479fef5`, `a57dd04` (commit SHAs); `test-fixtures/README.md` § Determinism (file + section); `test-fixtures/build.sh:903-912` `_update_manifest` (file + symbol + line range); BD-115 RELEASE-GATE item 5 (`fixture manifest verify` CI gate)
- **Cross-references within bullet body:** "Test infra is self-provisioned" bullet (RC4 — distinguished as test-provisioning-vs-manifest-maintenance)

End of report.
