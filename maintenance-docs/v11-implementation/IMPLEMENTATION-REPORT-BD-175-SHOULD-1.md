# IMPLEMENTATION-REPORT — BD-175 SHOULD-1 (architect-doc reconciliation)

**Branch:** `v11-dev`
**Pre-edit HEAD:** `88a0aea1f086266460f6966500ffff175297176e`
**Post-edit HEAD:** `88a0aea1f086266460f6966500ffff175297176e` (no commits by agent)
**Scope:** 1 file modification (architect-doc addendum) + 1 new IMPL-REPORT
**Plan deviations:** None
**New POQs:** None

---

## §1 — Summary

Applied the F4-bundle per-commit reviewer's SHOULD-1 finding
(`PACK-REVIEW-BD-175-F4-BUNDLE.md`): added an "F4 supersession
addendum" to
`maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
§6 that documents how the F4-bundle commit (`8f6ce51`) superseded the
architect's original Pattern B prescription for the project-side
boundary-investigation skill with Pattern A (single canonical source +
auto-distribution via `stage_s4_skills()`).

The reconciliation follows the pack-memory rule "Architect-doc-vs-reality
reconciliation": the original §6 content was NOT rewritten (preserves
audit trail of the architect's original design); the addendum SUPPLEMENTS
the original prescription with an explicit naming of the supersession,
the new canonical path, the realized consumer
(`stage_s4_skills()` in `scripts/init-project.sh` — file + function
name, no line numbers because line numbers drift), the rationale for
Pattern A over Pattern B, and the back-pointer to commit `8f6ce51`.

Per the prompt's guidance, the (a) in-code docstring and (c) IMPL-REPORT
cross-reference legs of the full BD-119 §9.2 reconciliation triad are
out of scope for this fix (the consumer is shell-not-Python so has no
docstring slot; the F4-bundle IMPL-REPORT is already committed in
`8f6ce51`). Only the (b) architect-doc addendum leg is delivered here.

A small inline marker note was ALSO added at the existing "Project-side
skill trinity" paragraph (line 434 area) to forward-point readers from
the superseded paragraph to the new §6.1 sub-section, so a reader
following §6 top-to-bottom encounters the supersession notice at the
point where the Pattern B prescription appears rather than discovering
it 50 lines later.

The pack-side skill trinity at line 329 (pack-repo `.claude/skills/`
parallels — pack-repo agents loading at run-time) was NOT marked as
superseded because it is structurally unchanged from §6 and remains
correct; the supersession concerns only the project-side ship-via-
install path.

---

## §2 — File changed

| Path | Change type | Line delta |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` | modified | +52 / -0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md` | new (this file) | n/a |

`maintenance-docs/` is NOT v11-surface (v11-surface = files under
`project-template/` or `scripts/`) so no `test-fixtures/manifest.txt`
regen is required per pack-memory rule "Regenerate manifest on
v11-surface commits."

---

## §3 — Addendum applied

### Placement choice

Used a BOTH-AND placement (inline marker + dedicated sub-section)
rather than EITHER inline-only OR sub-section-only, because:

- The inline marker at line 434 keeps the reader who is scanning the
  doc top-to-bottom from missing the supersession (they'd hit the
  Pattern B paragraph and form an outdated mental model before reaching
  any end-of-section addendum).
- The dedicated sub-section §6.1 carries the full rationale + realized-
  consumer naming + back-pointer in the canonical
  architect-doc-addendum location (end of the section being amended),
  matching the BD-119 §9.2 worked-example pattern.

The doc uses `## §N — title` and (where present) `### §N.X — title`
headings; §6 had no prior sub-sections, so §6.1 is the first. The
existing §7/§8/etc. structure is untouched.

### New inline marker (at end of "Project-side skill trinity" paragraph,
between the old line 434 paragraph and the "Measurable test for M4"
paragraph)

```
> **F4 addendum (2026-05-19):** BD-175 commit `8f6ce51` superseded
> this Pattern B prescription with Pattern A. See §6.1 — F4 supersession
> addendum at the end of this section.
```

### New sub-section §6.1 (inserted after "Measurable test for M4"
paragraph, before the `---` separator that ends §6)

```markdown
### §6.1 — F4 supersession addendum

**Reconciles:** The "Project-side skill trinity" paragraph above (Pattern
B prescription) with the realized shipping shape committed in BD-175
commit `8f6ce51` (F4 bundle).

The original §6 design above prescribed **Pattern B** for the
project-side boundary-investigation skill — 3 byte-identical SKILL.md
files at `project-template/.claude/skills/boundary-investigation/`,
`project-template/.codex/skills/boundary-investigation/`, and
`project-template/.gemini/skills/boundary-investigation/`. BD-175
commit `8f6ce51` (F4 bundle) superseded this with **Pattern A**, the
pack's canonical skill-source convention: a single source at
`project-template/skills/boundary-investigation/SKILL.md` that
auto-distributes to all 3 client CLI skill directories at client install
time.

**Realized consumer:** `stage_s4_skills()` in `scripts/init-project.sh`
— iterates `$PACK/project-template/skills/*/`, copies each `SKILL.md`
into `$TARGET/.claude/skills/<name>/`, `$TARGET/.codex/skills/<name>/`,
and `$TARGET/.gemini/skills/<name>/`, then verifies all three
destinations exist. The boundary-investigation skill participates in
this loop alongside the 30+ other Pattern A skills.

**Why Pattern A:** Pack convention for byte-identical-across-CLIs skills
(no per-CLI content variation) is the canonical
`project-template/skills/<name>/` location, matching how 30+ other
project-side skills already ship (`api-design`, `audit-methodology`,
`debugging`, `python-best-practices`, etc.). Pattern A guarantees
byte-identity by construction (single source) rather than by
maintenance discipline (three trinity files that drift if maintainers
diverge). Pattern B remains valid for skills with genuinely CLI-specific
content variation (e.g., skills whose invocation syntax differs per
CLI); boundary-investigation has no such variation. Pattern B was
inadvertently prescribed in the original architect design and not caught
until F4-bundle implementation.

**Unchanged from §6:** The pack-side boundary-investigation skill at
pack-repo root `.claude/skills/boundary-investigation/`,
`.codex/skills/boundary-investigation/`, and
`.gemini/skills/boundary-investigation/` (the "New skill" paragraph
above, line ~329 area). Pack-repo agents load skills at run-time from
CLI-prefixed dirs at the pack root — this is structurally different
from project-side ship-via-install and was correctly described in §6.

**Back-pointer:** commit `8f6ce51` (BD-175 F4 bundle) is the realizing
commit for this supersession.
```

### What was NOT changed

- Original §6 lines 325-434 (the M4 mechanism design, skill content
  sketch, agent loading table, "Project-side skill trinity" paragraph)
  preserved verbatim. Audit trail of the original architect design is
  intact.
- Pack-side prescription at line 329 NOT marked superseded — it is
  unchanged from §6 and remains correct (pack-repo agents load from
  CLI-prefixed dirs at pack root; this is structurally different from
  project-side ship-via-install).
- §7 and below: untouched.

---

## §4 — Pre-edit context

### Lines 325-340 (§6 opening, including the pack-side prescription)

```
325	## §6 — Mechanism M4: boundary-investigation skill (new pack skill)
326	
327	**Goal:** Concentrate the SSOT-investigation methodology into a single skill loaded by every actor whose work could trigger the regression. Single canonical home for the methodology; agent prompts reference the skill by name instead of duplicating the methodology in N places.
328	
329	**New skill: `boundary-investigation`** (proposed path: `.claude/skills/boundary-investigation/SKILL.md`, with parallel `.codex/skills/` and `.gemini/skills/` versions per the existing pack-skill trinity convention).
```

Note: line 329 describes the PACK-SIDE skill at pack-repo root, not
the project-side skill. This is unchanged from §6 and was correctly
described — pack-repo agents load from CLI-prefixed dirs at pack root.
No edit required at this locus.

### Lines 432-436 (end of §6, including the Pattern B prescription)

```
432	The skill loads for ALL pack agents because all five may be invoked against project-side surfaces.
433	
434	**Project-side skill trinity:** The skill ALSO ships to `project-template/.claude/skills/boundary-investigation/` and `.codex/` / `.gemini/` parallels — project-side coders / reviewers / architects / planners working in client repos hit the same regression mechanism in their own workflows. (This is Trinity Pack memory's "Repo conventions — Skill and agent maintenance is mechanical by default" pattern: the skill is the methodology, agent prompts reference it, both pack-side and project-side surfaces get the same skill loaded.)
435	
436	**Measurable test for M4:** After M4 lands, both pack-reviewer and pack-coder regression tests (proposed; see §11) include a synthetic boundary-violation prompt and assert the skill's methodology was applied (IMPL-REPORT / review-report mentions the SSOT-investigation step). A baseline gold-image of the skill content is checked into `test-fixtures/` for byte-identity testing (parallels Check 31 skill-cell internal-consistency gate).
```

Line 434 is the locus of the Pattern B prescription that was
superseded by F4. The inline marker note was inserted immediately
after this paragraph (between line 434 and line 436); the §6.1
sub-section was inserted after line 436 (after the "Measurable test for
M4" paragraph, before the `---` separator).

### Realized consumer context

`scripts/init-project.sh` lines 484-507 — `stage_s4_skills()` function
that realizes Pattern A by iterating
`$PACK/project-template/skills/*/` and copying each `SKILL.md` to all
three client CLI skill dirs:

```bash
484	stage_s4_skills() {
485	    say "── S4 — distribute skills (SKILL.md only) ──"
486	    local skill_dir name tool
487	    for skill_dir in "$PACK/project-template/skills"/*/; do
488	        [[ -d "$skill_dir" ]] || continue
489	        name=$(basename "$skill_dir")
490	        for tool in claude codex gemini; do
491	            mkdir -p "$TARGET/.${tool}/skills/$name"
492	            cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"
493	        done
494	    done
495	    # Verify: every pack skill has three destination SKILL.md files
496	    [...]
507	}
```

(Line numbers shown for context only; addendum text references
file + function name, not line numbers, per pack memory rule "When
citing a code location in a report, use the symbol name not the line
number. Line numbers drift with every edit; symbol names are stable.")

---

## §5 — Verification command output

### Verification 1 — HEAD SHA

```
$ git rev-parse HEAD
88a0aea1f086266460f6966500ffff175297176e
```

### Verification 2 — Post-edit grep for F4/8f6ce51/Pattern A/supersession terms

```
$ grep -n "F4\|8f6ce51\|stage_s4_skills\|Pattern A\|supersession" \
    maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md \
    | head -20
436:> **F4 addendum (2026-05-19):** BD-175 commit `8f6ce51` superseded
437:> this Pattern B prescription with Pattern A. See §6.1 — F4 supersession
442:### §6.1 — F4 supersession addendum
446:commit `8f6ce51` (F4 bundle).
453:commit `8f6ce51` (F4 bundle) superseded this with **Pattern A**, the
459:**Realized consumer:** `stage_s4_skills()` in `scripts/init-project.sh`
464:this loop alongside the 30+ other Pattern A skills.
466:**Why Pattern A:** Pack convention for byte-identical-across-CLIs skills
470:`debugging`, `python-best-practices`, etc.). Pattern A guarantees
477:until F4-bundle implementation.
487:**Back-pointer:** commit `8f6ce51` (BD-175 F4 bundle) is the realizing
488:commit for this supersession.
```

PASS — 12 hits across the inline marker (lines 436-437) and the §6.1
sub-section (lines 442-488), covering F4 / 8f6ce51 / Pattern A /
stage_s4_skills / supersession terms as required.

### Verification 3 — Working-tree scope

```
$ git status --short
 M maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F1.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F4-BUNDLE.md
```

The `M` entry is the in-scope architect-doc modification. The `??`
entries are pre-existing untracked review reports from prior F1 and
F4-bundle reviewer passes (NOT modified by this session). This
IMPL-REPORT itself was written AFTER the `git status --short`
verification snapshot above, so it appears as a 4th untracked file in
any post-Write recheck — that is the expected single-new-file IMPL-
REPORT artifact named in the prompt.

Note: an earlier pre-edit `git status --short` snapshot captured at
session start (before this session's first command) showed an
unrelated `M scripts/validate-pack.py` and other untracked files
(IMPLEMENTATION-REPORT-BD-175-F2A.md, scripts/tests/fixtures/cmd-
update-symmetry/, scripts/tests/test-validate-pack-check-39.sh) —
those disappeared from the working tree between the initial snapshot
and the second verification snapshot (likely parent-session commit /
cleanup activity outside this agent's scope). No edits were made by
this agent to any file outside the in-scope architect doc.

### Verification 4 — Diff stat

```
$ git diff --stat
 .../ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | 52 ++++++++++++++++++++++
 1 file changed, 52 insertions(+)
```

PASS — single file, +52 / -0 (addendum is purely additive; no
original content removed or rewritten).

---

## §6 — PREFLIGHT line

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 88a0aea1f086266460f6966500ffff175297176e; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md
```

---

## §7 — Definition-of-Done checklist

| Criterion | Status | Evidence |
|---|---|---|
| §6 addendum names F4 supersession + Pattern A path + `stage_s4_skills()` realized consumer + back-pointer to `8f6ce51` | PASS | §6.1 (lines 442-488) names all four; verification 2 grep confirms |
| Original §6 content (lines 325-436) NOT deleted or rewritten | PASS | `git diff --stat` shows +52 / -0 (purely additive) |
| Addendum mentions Pattern A vs Pattern B distinction + why byte-identical skills use Pattern A | PASS | §6.1 "Why Pattern A" paragraph |
| No state-changing git verbs run | PASS | Only `git rev-parse`, `git status`, `git diff` used |
| PREFLIGHT line emitted before IMPL-REPORT Write | PASS | Emitted in §6 above; also emitted as assistant text before the Write call to this file |
| Working-tree scope: only architect doc modified + this IMPL-REPORT new | PASS | `git status --short` shows only the `M` for the architect doc; this IMPL-REPORT is the only new file added by this session |
| No manifest regen needed (maintenance-docs/ is NOT v11-surface) | PASS | Edit is in `maintenance-docs/` only; no `project-template/` or `scripts/` files touched |

All DoD criteria PASS.

---

## §8 — Plan deviations

None. The implementation followed the prompt's "Suggested addendum
text" with light editorial polish (preserved all five required content
items: supersession naming, new canonical path, realized consumer
naming, Pattern A rationale, back-pointer). The placement was BOTH
inline-marker AND dedicated sub-section, per the prompt's allowed
range (the prompt offered either sub-section OR inline as alternatives
and gave the coder choice based on doc style — BOTH was selected
because the linear reading flow benefits from forward-pointing at the
superseded paragraph AND from a dedicated reconciliation surface at
the end of §6).

---

## §9 — New POQs introduced

None.

---

## §10 — Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` | modified (added inline marker after line 434 paragraph + new §6.1 sub-section after line 436 paragraph; +52 lines, -0 lines) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md` | new (this file) |

End of report.
