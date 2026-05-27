# IMPLEMENTATION-REPORT — Review skill ENCODING-surface enumeration section

**Branch:** `v11-dev`
**Pre-edit HEAD:** `f19b585bc36ba9f566d4f2d822c5c0c0c1551f5e`
**Post-edit HEAD:** `f19b585bc36ba9f566d4f2d822c5c0c0c1551f5e` (no commit; coder does not commit)
**Date:** 2026-05-27
**Coder:** pack-coder (sub-agent)
**Companion-to:** `f19b585` (trinity Pack memory rule "Enumerate ENCODING surfaces in pack-side audits")

---

## §1 Scope

Apply the operational companion to the trinity Pack memory rule that landed in commit `f19b585`. The trinity rule added two paragraphs at trinity § Pack memory § Repo conventions:

1. "Project-side concepts on pack-side surfaces — deliverable-only" (PM-only file edit, already landed).
2. "Enumerate ENCODING surfaces in pack-side audits" (PM-only file edit, already landed).

This commit lands the operational checklist in the review skill at all 3 CLI mirrors (pack-root `.claude/.codex/.gemini/skills/review/SKILL.md`). The review skill files are pack-coder territory (NOT on PM-only list per `pack-ops/PACK-AGENTS.md:140-164`), so they require a separate pack-coder commit per `feedback_pack_chat_does_no_fixes`.

---

## §2 Files modified

Three byte-identical mirrors, each gained one new H2 section (18 lines added):

| File | Lines added |
|---|---|
| `.claude/skills/review/SKILL.md` | +18 |
| `.codex/skills/review/SKILL.md` | +18 |
| `.gemini/skills/review/SKILL.md` | +18 |

Total: 3 files modified, 54 lines added, 0 lines deleted.

The new section is inserted between item 10 (last item of "What to examine") and the existing "Reporting findings" H2 — i.e., the new H2 sits between the existing "What to examine" and "Reporting findings" H2 sections.

---

## §3 Section content (the new H2 block)

```markdown
## Surface-rule audits — enumerate ENCODING surfaces

When auditing a pack-side surface (form, config, library, doc) for rule compliance — e.g., applying the trinity Pack memory rule "Project-side concepts on pack-side surfaces — deliverable-only" — enumerate ALL surfaces that ENCODE expected state of the audited surface before finalizing the review:

1. The audited surface itself (form file, config file, library, doc).
2. Any validator that asserts content invariants on the surface (e.g., `scripts/validate-pack.py` per-surface tables).
3. Any TEST file that asserts content invariants on the surface (e.g., `scripts/tests/test-issue-forms.sh` for issue forms).
4. Any CI workflow definition that references the surface or its tests.
5. Any cross-reference docs (architect docs, planner docs, IMPL-REPORTs) describing the surface's expected state.

Each ENCODING surface must update in lock-step with the audited surface. Asymmetric coverage (walking validators but not tests, or vice versa) misses lock-step dependencies and creates audit gaps.

**Verdict sub-class.** LEAK (operational, test-encoded) — pack-self-management state encoded in a test file's assertions, where the assertion's truth value depends on whether the audited surface admits a forbidden concept. Treat the same as a LEAK in the audited surface itself.

**Worked example.** The BD-185 reconciliation pack-side audit walked the form file (F1) + the validator's per-surface dict (F2) but missed `scripts/tests/test-issue-forms.sh` Group 2 + Group 5 assertions (F3'). The test's hardcoded pack-root assertions encoded the pre-cleanup state and required lock-step update with F1 + F2. Caught post-fact by the PREFLIGHT per-check-test-runs gate, not by the audit itself. Reference: trinity Pack memory § Repo conventions § "Enumerate ENCODING surfaces in pack-side audits".

**Note:** This methodology is specifically for surface-rule audits (compliance with pack memory rules like deliverable-only or pack/project separation). For standard per-commit code review, the test-coverage check at item 9 above is the relevant principle.
```

---

## §4 Verification results

### Cross-CLI parity (3 mirrors byte-identical)

```
$ diff .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md
(no output — files identical)

$ diff .claude/skills/review/SKILL.md .gemini/skills/review/SKILL.md
(no output — files identical)
```

PASS — all 3 mirrors byte-identical.

### Section heading grep

```
$ grep -c "^## Surface-rule audits" .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md .gemini/skills/review/SKILL.md
.codex/skills/review/SKILL.md:1
.claude/skills/review/SKILL.md:1
.gemini/skills/review/SKILL.md:1
```

PASS — exactly one heading per mirror.

### validate-pack.py

```
$ python3 scripts/validate-pack.py
... (all 30+ checks)
PASSED — all checks clean
```

PASS — no regression at HEAD.

### Fixture manifest

```
$ bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 570b7f8628abaa0ebe8d5580797f790f1165eea7
  v11-flat-file OK: 4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
  v11-tracker-on OK: 8f584b117f39d5826c7360f0e45a56cc6bfc1fce
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

PASS — all 6 fixtures verify clean. Manifest regen NOT required because edited files live at pack-root `.claude/.codex/.gemini/skills/review/` — outside the 4 v11-surface trigger directories (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`) per the v11-surface manifest-regen rule.

### Diff scope (no out-of-scope edits)

```
$ git diff --stat
 .claude/skills/review/SKILL.md | 18 ++++++++++++++++++
 .codex/skills/review/SKILL.md  | 18 ++++++++++++++++++
 .gemini/skills/review/SKILL.md | 18 ++++++++++++++++++
 3 files changed, 54 insertions(+)
```

PASS — exactly the 3 scoped files modified; no out-of-scope drift.

---

## §5 PREFLIGHT line

```
PREFLIGHT: 3 files edited (.claude/.codex/.gemini/skills/review/SKILL.md byte-identical); validate-pack.py PASS; cross-CLI parity verified; HEAD f19b585; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-REVIEW-SKILL-ENCODING-SECTION.md
```

Emitted before IMPL-REPORT Write call.

---

## §6 Cross-reference to f19b585 trinity rule

The trinity Pack memory rule (already landed at `f19b585`) lives at:

- `CLAUDE.md` § Pack memory § Repo conventions § "Enumerate ENCODING surfaces in pack-side audits"
- `AGENTS.md` § Pack memory § Repo conventions § "Enumerate ENCODING surfaces in pack-side audits"
- `GEMINI.md` § Pack memory § Repo conventions § "Enumerate ENCODING surfaces in pack-side audits"

The companion operational checklist (this commit) lives at:

- `.claude/skills/review/SKILL.md` § "Surface-rule audits — enumerate ENCODING surfaces"
- `.codex/skills/review/SKILL.md` § "Surface-rule audits — enumerate ENCODING surfaces"
- `.gemini/skills/review/SKILL.md` § "Surface-rule audits — enumerate ENCODING surfaces"

The skill section explicitly back-references the trinity rule in the worked-example paragraph ("Reference: trinity Pack memory § Repo conventions § 'Enumerate ENCODING surfaces in pack-side audits'.") so reviewers operating from the skill file can locate the authoritative rule, and triage actors reading the trinity rule can locate the operational checklist.

The worked example (BD-185 reconciliation audit) is consistent across both the trinity rule (which establishes the policy) and the review skill (which operationalizes the audit checklist), so the reader can trace from rule to operational application from either entry point.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| New "Surface-rule audits" H2 section added in all 3 review skill mirrors | PASS |
| Section inserted between "What to examine" (item 10) and "Reporting findings" (item 11) | PASS |
| 3 mirrors byte-identical post-edit (cross-CLI parity preserved) | PASS |
| validate-pack.py PASS (no regression) | PASS |
| Fixture manifest verify PASS (no drift; regen not required) | PASS |
| No out-of-scope file edits | PASS |
| No state-changing git verbs invoked | PASS |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |
| IMPL-REPORT written | PASS |

---

## Plan deviations

None. The implementation followed the prompt scope exactly:
- Edited exactly the 3 scoped mirror files.
- Used the exact section content provided in the prompt.
- Inserted at the prompted location (between item 10 and "Reporting findings" H2).
- Ran all 4 prompted verification checks.

## New POQs introduced

None.

## Boundary discipline check

This edit modifies pack-root review skill mirrors (`.claude/.codex/.gemini/skills/review/SKILL.md`). These files are pack-side (NOT under `project-template/`), so the P-missed-7 project-side SSOT investigation does not apply.

The section's content correctly references pack-internal artifacts (the trinity Pack memory rule, `scripts/validate-pack.py`, `scripts/tests/test-issue-forms.sh`, BD-185) since the skill operates on pack-side audit work — that's the legitimate audience match.

## Files changed inventory

| Path | Change type |
|---|---|
| `.claude/skills/review/SKILL.md` | Modified |
| `.codex/skills/review/SKILL.md` | Modified |
| `.gemini/skills/review/SKILL.md` | Modified |
