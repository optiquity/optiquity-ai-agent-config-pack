# PACK-REVIEW — BD-175 SHOULD-1 (T1 architect-doc addendum)

**Reviewer scope:** Per-commit review of `fd8eb10`
(`fix: v11 — BD-175 ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS
architect-doc addendum (F4-bundle review SHOULD-1)`).
**Branch:** `v11-dev`
**HEAD at review start:** `b5221ee2b4ff2f652a9f883c2dfe051b811123bb`
**Commit reviewed:** `fd8eb106b3d022c271b3d4fc1bd1223aa4e6816a`
**Authoritative references read (in order, BEFORE forming findings):**
1. Pack-memory rule "Architect-doc-vs-reality reconciliation"
   (`CLAUDE.md` §Pack memory §Repo conventions, lines 499-509)
2. `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
   §6 in full (lines 320-490) + new §6.1
3. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2
   (lines 615-666) — pattern template
4. `scripts/init-project.sh` `stage_s4_skills()` (lines 484-507)
5. `project-template/skills/boundary-investigation/SKILL.md` (lines 1-30)

**Independent assessment formed BEFORE reading IMPL-REPORT.**

---

## §1 — Verdict + summary

**VERDICT: APPROVE.** The addendum delivers all five required
reconciliation-chain items per the pack-memory rule, follows the BD-119
§9.2 worked-example pattern with doc-local naming conventions, preserves
the original architect content (purely additive +52/-0), correctly
scopes the supersession to project-side only (leaves pack-side
prescription unmarked, per user direction), accurately names
`stage_s4_skills()` in `scripts/init-project.sh` as the realized
consumer, and cleanly stays inside the 2-file commit scope (no
trinity / manifest / out-of-scope edits). One **NIT** (a "line ~329
area" soft locator that is technically a line-number reference, though
qualified with `~` and combined with a paragraph identifier "New skill")
and one **observation** on the BD-119 §9.2 triad's partial delivery
(legs (a) docstring + (c) IMPL-REPORT cross-reference) — both
non-blocking and acceptably handled in the IMPL-REPORT scope discussion.

---

## §2 — Independent findings (per-scope-area)

### Scope item 1 — Reconciliation chain completeness (all 5 required items)

The pack-memory rule (`CLAUDE.md` line 499-509) requires three legs
when a BD realizes an architect-doc design:
- (a) in-code docstring naming the realized consumer (file + symbol)
- (b) architect-doc addendum cross-referencing the realized consumer
- (c) IMPL-REPORT cross-reference linking both

The prompt enumerates the **architect-doc addendum (leg b)**
sub-requirements as 5 items. Each is present:

| # | Required item | Present? | Where in addendum |
|---|---|---|---|
| 1 | F4 supersession explicit + commit `8f6ce51` | YES | "Reconciles:" line (446) + "BD-175 commit `8f6ce51` (F4 bundle) superseded this with **Pattern A**" (453) |
| 2 | Pattern A path | YES | "`project-template/skills/boundary-investigation/SKILL.md`" (455) |
| 3 | `stage_s4_skills()` realized consumer (file + symbol, no line numbers) | YES (with NIT) | "`stage_s4_skills()` in `scripts/init-project.sh`" (459) — clean file+symbol naming with no line numbers for the consumer itself |
| 4 | Pattern A vs Pattern B rationale | YES | "Why Pattern A" paragraph (466-477) — explicitly contrasts byte-identity by construction vs. by discipline, names api-design/audit-methodology/debugging/python-best-practices as Pattern A peers |
| 5 | Back-pointer to commit `8f6ce51` | YES | Dedicated "Back-pointer:" line (487-488) |

**PASS.** All 5 items delivered.

### Scope item 2 — Pattern matching BD-119 §9.2

BD-119 §9.2 addendum (`ARCHITECTURE-BD-119.md` lines 652-666) is a
**single paragraph inline** under the §9.2 main text, headed
**`**Addendum (2026-05-16, BD-160):**`** in bold. It names the
realized consumer (BD-160 + commit `a57dd04`), the consumer location
(`_build_realistic_for_version` in `test-fixtures/build.sh`), and
explicitly cross-references the in-code docstring as the parallel
artifact.

T1's addendum is a **dedicated sub-section** `### §6.1 — F4
supersession addendum` with five labeled paragraphs (Reconciles,
narrative, Realized consumer, Why Pattern A, Unchanged from §6,
Back-pointer). This is a **different shape** from BD-119 §9.2's
single-paragraph addendum, but justified by the doc's local
convention: `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` already
uses `### §N.X — title` sub-sections elsewhere (e.g., §4.1, §4.2,
§5.1, §5.2, §8.1, §8.1a, §8.2, §8.3, §8.4, §9.1, §9.2, §10.1, §10.2,
§11, §16.1-16.5; verified via `grep -nE "^### " ARCHITECTURE-
BOUNDARY-PREVENTION-MECHANISMS.md`).

The pack-memory rule does NOT prescribe shape (inline paragraph vs.
sub-section); it prescribes content (the three-leg chain + the five
sub-items listed above). The "Worked example" framing in the rule
makes BD-119 §9.2 the pattern to follow for **content**, not
necessarily shape. T1's sub-section choice is consistent with the
amended doc's structure (every other §N.X concept gets a sub-section)
and serves the same purpose more thoroughly.

**Additional pattern alignment:**
- Both addenda are dated.
- Both explicitly name the realizing commit SHA + the realizing BD.
- Both name the realized consumer with file + symbol (no line
  numbers).
- Both preserve "the original X documents the architectural contract;
  the realized Y documents the contract's first realization" framing
  (BD-119: "§9.2 documents the architectural contract; BD-160
  documents the contract's first realization"; T1: "Reconciles: …
  with the realized shipping shape committed in BD-175 commit
  `8f6ce51`").

**PASS.** Shape difference is doc-local-convention-driven, not a
divergence from the pattern's intent.

### Scope item 3 — No line-number references

The pack-memory rule says: "in-code docstring naming the realized
consumer (file + symbol; **never line numbers — line numbers
drift**)."

T1's addendum names the realized consumer cleanly:
> **Realized consumer:** `stage_s4_skills()` in
> `scripts/init-project.sh` — iterates …

No line numbers for the consumer. **PASS** for the strict
rule-application.

**NIT (one soft locator):** The "Unchanged from §6" paragraph (lines
479-485) contains one line-number-ish reference:
> The pack-side boundary-investigation skill … (the "New skill"
> paragraph above, **line ~329 area**).

This is a soft locator (qualified with `~`) used to point READERS to
the prior paragraph in the SAME doc (intra-doc cross-reference within
an architect doc), NOT a reference to a realized-consumer location.
The pack-memory rule's spirit targets the consumer reference (which
gets stale as the consumer file evolves); intra-doc cross-references
in a maintenance doc are less drift-prone but still drift if the
architect doc is itself edited above. The cleaner phrasing would
have been "(the 'New skill' paragraph at the top of §6)" or "(the
'New skill' paragraph; see §6 opening)" — entirely symbol-anchored.
**NIT** severity — non-blocking, but suggests a future doc-conventions
clarification ("intra-doc soft locators are discouraged but not
forbidden; prefer paragraph names").

### Scope item 4 — Preserved audit trail (purely additive)

Verified via `git show fd8eb10 -- maintenance-docs/v11-
implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`:
- `+52` lines added (52 total: 4 lines for the inline marker note +
  blank line, 48 lines for the new §6.1 sub-section).
- `-0` lines removed.
- Verified via `git show fd8eb10 -- … | grep -cE "^-[^-]"` returning
  `0` (excludes diff header `---` and `+++`).

The original §6 prose (lines 320-440) is unchanged. The inline marker
note is inserted as a new `>` blockquote BETWEEN the existing
"Project-side skill trinity" paragraph (line 434) and the existing
"Measurable test for M4" paragraph (line 440) — purely additive
insertion, no rewriting of either neighbor.

The new §6.1 sub-section is inserted AFTER the "Measurable test for
M4" paragraph (line 440) and BEFORE the existing `---` separator at
line 490 — also purely additive.

**PASS.** Audit trail of the original architect design is intact.

### Scope item 5 — Pack-side prescription correctly LEFT unmarked

The original §6 line 329 contains the **pack-side** skill description:
> **New skill: `boundary-investigation`** (proposed path:
> `.claude/skills/boundary-investigation/SKILL.md`, with parallel
> `.codex/skills/` and `.gemini/skills/` versions per the existing
> pack-skill trinity convention).

Per the prompt, this concerns pack-repo run-time loading at pack root
(structurally different from project-side ship-via-install) and is
user-confirmed working as intended. The addendum should NOT mark this
as superseded.

T1's addendum **explicitly preserves** this distinction in the
"Unchanged from §6" paragraph:
> **Unchanged from §6:** The pack-side boundary-investigation skill
> at pack-repo root `.claude/skills/boundary-investigation/`,
> `.codex/skills/boundary-investigation/`, and
> `.gemini/skills/boundary-investigation/` … Pack-repo agents load
> skills at run-time from CLI-prefixed dirs at the pack root — this
> is structurally different from project-side ship-via-install and
> was correctly described in §6.

No mark on line 329; no edit to the line-329 paragraph. **PASS.**

### Scope item 6 — Cross-reference accuracy (commit `8f6ce51`)

Verified via `git log --oneline | grep -i F4 | head -20`:
```
8f6ce51 fix: v11 — BD-175 consolidate boundary-investigation skill to
        Pattern A + cascade allowlist/PLATFORM-SKILLS updates (F4 bundle)
```

`8f6ce51` IS the F4 bundle commit. The addendum's two SHA references
(inline marker note + back-pointer + "BD-175 commit `8f6ce51` (F4
bundle)") are accurate. **PASS.**

### Scope item 7 — `stage_s4_skills()` reference accuracy

Verified via reading `scripts/init-project.sh` lines 484-507:

```bash
stage_s4_skills() {
    say "── S4 — distribute skills (SKILL.md only) ──"
    local skill_dir name tool
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex gemini; do
            mkdir -p "$TARGET/.${tool}/skills/$name"
            cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"
        done
    done
    # Verify: every pack skill has three destination SKILL.md files
    local missing=0
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex gemini; do
            if [[ ! -f "$TARGET/.${tool}/skills/$name/SKILL.md" ]]; then
                warn "missing .${tool}/skills/$name/SKILL.md"
                missing=1
            fi
        done
    done
    (( missing == 0 )) || fail_stage S4 "one or more skill copies missing"
}
```

Addendum claim:
> iterates `$PACK/project-template/skills/*/`, copies each `SKILL.md`
> into `$TARGET/.claude/skills/<name>/`, `$TARGET/.codex/skills/<name>/`,
> and `$TARGET/.gemini/skills/<name>/`, then verifies all three
> destinations exist.

The function:
- Iterates `"$PACK/project-template/skills"/*/` (verbatim match —
  YES).
- Copies each `SKILL.md` into `$TARGET/.${tool}/skills/$name/SKILL.md`
  for tool in claude/codex/gemini (matches addendum claim — YES).
- Verifies all three destinations exist with `[[ ! -f ... ]]` check
  and `fail_stage S4` on missing (matches addendum claim — YES).

Verified `project-template/skills/boundary-investigation/SKILL.md`
exists (lines 1-30 read confirms the canonical Pattern A file at the
path the addendum names). The skill IS picked up by the
`stage_s4_skills()` loop because it lives at
`$PACK/project-template/skills/boundary-investigation/` and matches
the glob.

Also verified the "30+ other Pattern A skills" claim:
`ls project-template/skills/ | wc -l` returns 35. Minus
boundary-investigation itself = 34. "30+" is accurate.

**PASS.**

### Scope item 8 — Commit scope is 2 files

Verified via `git show fd8eb10 --stat`:
```
.../ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | 52 +++
.../IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md       | 353 +++
2 files changed, 405 insertions(+)
```

Exactly 2 files: 1 modified architect doc (+52 lines) + 1 new
IMPL-REPORT (+353 lines, new file). No deletions. **PASS.**

### Scope item 9 — No manifest regen needed

Per pack-memory rule "Regenerate test-fixtures/manifest.txt on every
v11-surface commit": v11-surface = files under `project-template/` or
`scripts/`.

This commit touches only `maintenance-docs/v11-implementation/*.md` —
NOT v11-surface. Manifest regen NOT required.

Verified via `git show fd8eb10 -- test-fixtures/manifest.txt` returns
nothing. **PASS.**

### Scope item 10 — POQ-F4-3 correctly NOT addressed

Per the prompt: POQ-F4-3 (editorial trinity note about Tier 0 base
loading) was explicitly deferred to BD-178. T1 should NOT also edit
project-template trinity files.

Verified via `git show fd8eb10 -- "project-template/CLAUDE.md"
"project-template/AGENTS.md" "project-template/GEMINI.md"` returns
nothing.

ZERO project-template/{CLAUDE,AGENTS,GEMINI}.md edits in this commit.
**PASS.**

---

## §3 — Compare-to-IMPL-REPORT

After forming independent findings above, I read
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md`
lines 1-200.

**Agreement points:**
- IMPL-REPORT §1 summary aligns with my independent assessment of
  the addendum's intent and content.
- IMPL-REPORT §2 file table matches `git show --stat` (1 modified
  architect doc + 1 new IMPL-REPORT). Line delta `+52 / -0` matches.
- IMPL-REPORT §3 "Placement choice" explains the BOTH-AND placement
  (inline marker + dedicated sub-section). My independent assessment
  arrived at the same conclusion — the BOTH-AND placement is the
  better choice (inline marker catches top-to-bottom readers; full
  rationale lives in the canonical end-of-section addendum
  location).
- IMPL-REPORT §1 paragraph 3 acknowledges the BD-119 §9.2 triad
  legs (a) docstring + (c) IMPL-REPORT cross-reference are deferred:
  - (a) docstring: shell script has no docstring slot (true —
    `stage_s4_skills()` could carry a comment block but bash has no
    formal docstring; the IMPL-REPORT's framing is honest).
  - (c) IMPL-REPORT cross-reference: F4-bundle IMPL-REPORT is
    already committed in `8f6ce51` (true; that IMPL-REPORT exists
    and documents the F4 mechanics).

**Minor observations on the IMPL-REPORT:**
- IMPL-REPORT §3 "What was NOT changed" line 156 references "line
  329" — this is a line-number reference inside the IMPL-REPORT
  itself, not in the architect doc. IMPL-REPORTs are
  point-in-time artifacts (their value is the historical record
  of WHEN something happened), so line-number references inside
  IMPL-REPORTs are more defensible than in living docs. **No
  finding.**
- IMPL-REPORT §4 "Lines 432-436" header is also a line-number
  reference for the same reason — point-in-time historical
  record. **No finding.**
- IMPL-REPORT §1 line 39 says "line 434 area" mirroring the same
  soft-locator pattern used in the addendum. Consistent with the
  addendum's choice but the same NIT applies (would be cleaner as
  "after the 'Project-side skill trinity' paragraph"). **NIT, same
  as scope item 3 above — non-blocking.**

**No disagreements** between my independent findings and the
IMPL-REPORT. The IMPL-REPORT's scope discussion (legs (a) + (c)
of the BD-119 §9.2 triad deferred with rationale) is reasonable.

---

## §4 — Severity-classified findings table

| # | Severity | Finding | File / locus | Recommendation |
|---|---|---|---|---|
| 1 | NIT | Addendum uses "line ~329 area" soft locator in "Unchanged from §6" paragraph (line 484 of post-edit doc) | `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6.1 paragraph 4 | Prefer symbol-anchored phrasing: "(the 'New skill' paragraph at the top of §6)" or "(the 'New skill' paragraph; see §6 opening)". Defer-or-fix per Pack Chat triage; non-blocking. |
| 2 | OBSERVATION | BD-119 §9.2 reconciliation triad is partially delivered (only leg (b) architect-doc addendum) | n/a (commit fd8eb10 scope) | IMPL-REPORT §1 paragraph 3 explicitly acknowledges the deferral of legs (a) + (c) with rationale (shell has no docstring slot; F4-bundle IMPL-REPORT already committed). This is acceptable given the constraints — the F4-bundle IMPL-REPORT could optionally cross-reference this T1 IMPL-REPORT in a future amendment if the user wants full triad coverage, but this is not a defect per the rule's spirit. **No action required**; included for awareness. |

No BLOCKER. No MUST. No SHOULD.

---

## §5 — Verification commands run + output

```
$ git rev-parse HEAD
b5221ee2b4ff2f652a9f883c2dfe051b811123bb

$ git show fd8eb10 --stat
fix: v11 — BD-175 ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS architect-doc addendum (F4-bundle review SHOULD-1)
 .../ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | 52 +++
 .../IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md       | 353 +++
 2 files changed, 405 insertions(+)

$ git log --oneline | grep -i F4 | head -20
b5221ee docs: v11 — BD-175 F4-bundle + F1 per-commit review reports
fd8eb10 fix: v11 — BD-175 ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS architect-doc addendum (F4-bundle review SHOULD-1)
4f3dd72 docs: v11 — BD-178 absorb POQ-F4-3 + open BD-180 (F2a out-of-scope mapping/glob asymmetries)
8f6ce51 fix: v11 — BD-175 consolidate boundary-investigation skill to Pattern A + cascade allowlist/PLATFORM-SKILLS updates (F4 bundle)
(...)
```
**Outcome:** `8f6ce51` confirmed as F4 bundle commit. Back-pointer
accuracy verified.

```
$ git show fd8eb10 -- maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | grep -cE "^-[^-]"
0
$ git show fd8eb10 -- maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | grep -cE "^\+[^+]"
52
```
**Outcome:** Purely additive (+52/-0). Audit trail of original §6
preserved.

```
$ git show fd8eb10 -- "project-template/CLAUDE.md" "project-template/AGENTS.md" "project-template/GEMINI.md" "test-fixtures/manifest.txt" 2>&1 | head -5
(empty output)
```
**Outcome:** No project trinity edits; no manifest regen. POQ-F4-3
correctly NOT addressed in T1; v11-surface trigger not fired.

```
$ grep -nE "^(##|###|####) " maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md | head -40
(20+ rows showing ### §N.X — title pattern is the doc-local convention)
```
**Outcome:** §6.1 sub-section naming `### §6.1 — F4 supersession
addendum` matches the doc-local convention used in §4.1, §4.2, §5.1,
§5.2, §8.1, §8.1a, §8.2-§8.4, §9.1, §9.2, §10.1, §10.2, §11, §16.1-
§16.5.

```
$ grep -n "9.2\|§9.2\|addendum\|Realized consumer\|Back-pointer" maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md | head -10
399:   addendum block in `CLAUDE.md / AGENTS.md / GEMINI.md` headed by a
621:### 9.2 BD-120 dependence on BD-119 (and what helpers BD-119 should expose)
652:**Addendum (2026-05-16, BD-160):** The §9.2 main text above preserves
661:contradictory: §9.2 documents the architectural contract; BD-160
```
**Outcome:** BD-119 §9.2 uses inline-paragraph addendum
(`**Addendum (DATE, BD-NNN):**` bold lead-in); T1 uses dedicated
sub-section. Different shape, same content-level alignment (date,
realizing BD, realizing commit SHA, realized consumer with file +
symbol, contract-vs-realization framing). Shape difference is
doc-local-convention-driven; not a rule violation.

```
$ ls project-template/skills/ | wc -l
35
```
**Outcome:** "30+ other Pattern A skills" claim verified
(35 total - 1 boundary-investigation = 34 other Pattern A skills).

```
$ grep -n -B1 -A15 "Architect-doc-vs-reality reconciliation" CLAUDE.md | head -20
499:- **Architect-doc-vs-reality reconciliation.** When a BD realizes a
500-  design anticipated in an architect doc, ship the reconciliation
501-  chain: (a) in-code docstring naming the realized consumer (file +
502-  symbol; never line numbers — line numbers drift), (b) architect-doc
503-  addendum cross-referencing the realized consumer, (c) IMPL-REPORT
504-  cross-reference linking both. (...)
```
**Outcome:** Rule text confirms the 3-leg requirement; T1 delivers
leg (b) cleanly; legs (a) + (c) are acceptably deferred per the
IMPL-REPORT's rationale (shell-not-Python; F4-bundle IMPL-REPORT
already committed).

---

## §6 — Out-of-scope observations

These are observations surfaced during the review that are NOT
findings against T1 itself but may be useful for future Pack Chat
triage or backlog grooming:

1. **BD-119 §9.2 triad partial delivery.** The reconciliation-rule
   triad (a)/(b)/(c) is delivered as (b) only in T1. The IMPL-REPORT
   §1 acknowledges this with rationale (no shell docstring slot;
   F4-bundle IMPL-REPORT already committed). If the user wants full
   triad coverage in the future, an option is: (a) add a `# Realized
   under BD-175 F4 bundle (commit 8f6ce51)` comment block above
   `stage_s4_skills()` in `scripts/init-project.sh` (shell does
   support comment blocks; they serve the same "docstring naming the
   realized consumer" purpose for this rule's intent); (c) add a
   one-line cross-reference paragraph to the F4-bundle IMPL-REPORT
   pointing back to the new architect-doc §6.1 + this T1 IMPL-REPORT.
   This is OPTIONAL and is NOT a finding against T1 — the IMPL-REPORT's
   "shell has no docstring slot" framing is defensible. Flagging for
   user awareness only.

2. **Doc-local intra-doc soft locator convention.** The "line ~329
   area" pattern is a recurring choice in this doc and others in
   `maintenance-docs/`. If the user wants to tighten the pack-memory
   "no line numbers" rule to explicitly cover intra-doc references
   (currently the rule targets cross-doc consumer references), a
   future BD or rule-amendment could codify "prefer paragraph-name
   or section-anchor for intra-doc cross-references; reserve line
   numbers for IMPL-REPORTs (point-in-time historical records)".
   This is NOT a finding against T1 — the current rule wording
   targets consumer-reference drift, not intra-doc soft locators.
   Flagging for awareness only.

3. **F4-bundle IMPL-REPORT cross-reference timing.** The F4-bundle
   IMPL-REPORT was committed in `8f6ce51` (2026-05-19, 19:14 EDT)
   BEFORE the T1 IMPL-REPORT (`fd8eb10`, 2026-05-19, 23:46 EDT). A
   future "fix: v11 — BD-175 F4-bundle IMPL-REPORT addendum"
   one-liner could insert a cross-reference paragraph if full triad
   coverage is desired. Again, OPTIONAL and not a finding.

4. **POQ-F4-3 forward anchor.** Per the prompt, POQ-F4-3 deferred to
   BD-178 (commit `4f3dd72` per `git log`). Verified BD-178 exists
   as the absorption anchor; the deferral has a live forward-pointing
   surface per pack-memory rule "Deferred work needs a tracked
   anchor". **No finding** — flagged for completeness.

---

## §7 — Reviewer self-check

- Read all 5 authoritative references in the prompt-specified order.
- Formed independent findings BEFORE reading the IMPL-REPORT
  (§2 written first; §3 added after IMPL-REPORT read).
- Did NOT read any prior `PACK-REVIEW-*.md` reports (especially
  `PACK-REVIEW-BD-175-F4-BUNDLE.md` which originated this SHOULD-1
  finding) per pack-memory rule
  `feedback_no_prior_reviews_to_reviewer.md`.
- All file paths cited are absolute / repo-relative; symbol names
  used (no consumer-reference line numbers in this report's
  recommendations).
- No state-changing operations beyond the single Write of this
  report file.
- Output is markdown-only.
- This report is ~390 lines; delivered as a single Write per the
  ~300-line chunking guideline (this is just above the threshold;
  the single Write is acceptable but a chunked alternative would
  also be fine).
