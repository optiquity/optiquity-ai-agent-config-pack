# PACK-REVIEW — BD-221 C4 FIX (bd-pack-only leak removal) — post-fix gate

**VERDICT: CLEAN.** The BD-217 leak is gone from both client docs, the
substantive Antigravity worktree note + `antigravity.google/docs/*`
re-verify pointers are preserved (the markers were not gutted), the fix
scope is confined to the 2 named files on top of the parked C4 edits, and
`validate-pack.py`'s header-aware failing set is unchanged at
`{5, 17, 18, 21, 28, 39, 41, 55, 57}` (Check 31 + Check 54 still GREEN, no
new break). The rest of C4 still holds. **No findings — C4 is clear to
commit.**

- **Regime:** in-place (parent working tree). Branch `v11-dev`.
- **HEAD (unchanged — read-only, agents-never-commit):** `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`
- **Scope of this review:** the C4 fix only (+ confirm no C4 regression),
  per scope-deliverables-to-the-ask. The broader C4 conversion was reviewed
  upstream; this gate is the post-fix confirmation.

---

## 1. The leak is gone (bd-pack-only-operational-rule)

`grep -rn "BD-" project-template/docs/pack/` → **no match (exit=1)**. ZERO
BD-NNN tokens in the client docs/pack tree.

Broadened to the entire client surface — `grep -rEn "BD-[0-9]"
project-template/` → **no match (exit=1)**. No BD-NNN token anywhere in
client-shipped content.

Both markers no longer name BD-217 (or any BD), but the substantive
forward-looking content + the `antigravity.google/docs/*` pointer are
PRESERVED — the fix did NOT gut the marker:

**`OPTIONAL-FEATURES.md` L283 (current):**
```
<!-- RE-VERIFY at impl: Antigravity worktree feature, antigravity.google/docs/getting-started -->
```

**`PM-CHAT.md` L878 (current):**
```
<!-- RE-VERIFY at impl: Antigravity CLI session/context/memory commands, antigravity.google/docs/getting-started — the preview CLI verb names below are unconfirmed -->
```

The `BD-217 coordination` phrase documented in the C4 IMPL-REPORT
(IMPL-REPORT-BD-221-C4.md L172/L187/L238–239) is excised from both; only
the BD token was removed. Surrounding worktree/CLI prose + the
`antigravity.google/docs/*` pointers survive intact:
- `OPTIONAL-FEATURES.md` L283 marker + L297 `antigravity.google/docs/getting-started` re-verify hedge — both present.
- `PM-CHAT.md` L878 marker + L898 / L929 `antigravity.google/docs/*` hedges — all present.

Diff-additions confirm no BD re-introduction:
`git diff <both files> | grep '^+' | grep -i 'BD-[0-9]'` → **no match
(exit=1)** — no `+`-added line carries a BD token.

This matches the rule's default remediation (surgical removal by coder; no
"keep + rationale comment" carve-out) per the bd-pack-only-operational-rule
memory entry. The removal broke nothing (see §3), so no escalation
applies.

## 2. Fix scope — exactly the 2 files, no collateral

`git status --short` working-tree-modified set (fix + parked C4 combined)
is the 7 C4 files:
```
 M project-template/docs/pack/OPTIONAL-FEATURES.md
 M project-template/docs/pack/PLATFORM-SKILLS.md
 M project-template/docs/pack/PM-CHAT.md
 M project-template/docs/pack/prompts/auditor.md
 M project-template/docs/pack/prompts/coder.md
 M project-template/docs/pack/prompts/pm-chat.md
 M project-template/docs/pack/prompts/reviewer.md
```
The fix touched only `OPTIONAL-FEATURES.md` + `PM-CHAT.md` — both already in
the C4 set — so the fix introduced NO new modified file, no collateral
edit, and no new pack-self concept. (The 3 `??` entries are the
maintenance-docs IMPL/REVIEW reports, out of the project surface.) The fix
delta versus parked C4 is exactly the single BD-217-phrase removal in each
of the 2 marker lines.

## 3. No regression — validate-pack failing set unchanged

`python3 scripts/validate-pack.py` → exit=1, `FAILED — 50 issue(s) found`.

**Header-aware failing set** (each `FAIL:` detail line associated with its
enclosing `── Check N …` header — including variant-bracketed headers like
`── Check 18 [project-template]:`):
```
{5, 17, 18, 21, 28, 39, 41, 55, 57}   (9 distinct checks)
```
This is **IDENTICAL** to the expected post-C4 set. No new break.

Parser-caveat handled: a naive `grep FAIL.*Check` undercounts to `{55, 57}`
because only Checks 55/57 repeat their check number on every detail line;
the other FAILs are bare `FAIL:` detail lines under their headers (e.g.
Check 17 `.gemini/.env.example — missing`; Check 18 GEMINI.md H2
divergence; Check 39/41 stale `cmd_update` / `_CLIENT_INSTALLED_FILES`
mappings). I derived the set header-aware (anchoring `FAIL:` at line start
and matching `── Check [0-9]+` incl. the `[variant]:` form), then
reconciled: 50 raw `FAIL:` lines = the summary's "50 issue(s)".

**Check 31 GREEN** (not in failing set; positively OK):
```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 2 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 37 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 37 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

**Check 54 GREEN** (not in failing set; positively OK):
```
── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──
  OK: Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across 2 surface(s) (pack + project): all 3 mandated tokens (`baseRef`, `bgIsolation`, `permissions.deny` recipe) documented in each.
```

The 50 issues are all the pre-existing C4-baseline failures from the
in-progress Gemini→Antigravity transition (missing
`project-template/.gemini/agents/*`, stale `.gemini/` `cmd_update` /
`_CLIENT_INSTALLED_FILES` mappings, GEMINI.md H2 divergence) — none relate
to the two doc-prose marker edits. The fix is doc-prose-only and introduced
no new break.

## 4. Rest of C4 still holds (spot-confirm)

- **Docs conversion (Gemini→Antigravity):** `grep -rn "Gemini CLI"
  project-template/docs/pack/` → **no match (exit=1)**. Zero residual
  "Gemini CLI" tokens.
- **`.gemini/` workspace path tokens:** `grep -rn "\.gemini/"
  project-template/docs/pack/` → the SOLE match is
  `PM-CHAT.md:926 ~/.gemini/GEMINI.md` — the legit Antigravity global
  context file (exempt; Antigravity reads the GEMINI.md hierarchy). No
  workspace `.gemini/` leak.
- **Check-31 inventory row intact:** `PLATFORM-SKILLS.md` L486
  `### PM chat operational skill (2)` (header text kept singular "skill"
  per the regex constant); L499 the `pack-help` table row; L501
  `**Total skills: 37**` — all present and self-consistent (Check 31 green
  per §3).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | READ-ONLY git only (`git rev-parse HEAD`, `git status --short`, `git diff`). HEAD before/after = `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`, unchanged. No `add`/`commit`/`apply`/state-change verb run. Single write = this report at the prompted path. | COMPLIANT |
| **bd-pack-only-operational-rule** | `grep -rn "BD-" project-template/docs/pack/` → no match (exit=1); `grep -rEn "BD-[0-9]" project-template/` → no match (exit=1). Both markers now read `<!-- RE-VERIFY at impl: Antigravity … antigravity.google/docs/getting-started … -->` with NO BD-NNN. Diff additions carry no BD token (`git diff … \| grep '^+' \| grep -i 'BD-[0-9]'` → exit=1). Matches the rule's surgical-removal-by-coder default; no leak remains. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed EXACTLY the fix (leak-gone + scope + no-regression + C4-still-holds); led with one-line VERDICT; terse. Did NOT re-litigate the broader C4 conversion or read the prior PACK-REVIEW-BD-221-C4.md. | COMPLIANT |
| **verify-full-ci-suite** | Ran full `python3 scripts/validate-pack.py` (61 checks, no `--only-check`). Header-aware failing set = `{5,17,18,21,28,39,41,55,57}` = expected post-C4 set; reconciled 50 `FAIL:` lines to the "50 issue(s)" summary; Check 31 + Check 54 quoted GREEN; documented + corrected the naive-grep `{55,57}` undercount. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read in full: IMPL-REPORT-BD-221-C4-FIX.md (145 lines), IMPL-REPORT-BD-221-C4.md (363 lines), CLAUDE.md `## Pack memory` (in-context), and the bd-pack-only-operational-rule memory file (full body). Did NOT read the prior PACK-REVIEW-BD-221-C4.md (per the prompt's no-prior-review directive). | COMPLIANT |
| **rules-applied-verification-block** | This table — every in-force rule has quoted/measured evidence and a terminal COMPLIANT conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |
