# PACK-REVIEW-BD-142 — PLATFORM-SKILLS.md 5+3 model rewrite

**Reviewer:** pack-reviewer (v11-dev branch)
**Date:** 2026-05-11
**Scope:** BD-142 batch — major rewrite of
`project-template/docs/pack/PLATFORM-SKILLS.md` from implicit
4-dimension model to explicit 5-dimension + 3-load-mechanism model.
**Inputs:** `project-template/docs/pack/PLATFORM-SKILLS.md` (full),
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`
(§3, §4, §5, §7.4), pre-rewrite version via `git show HEAD:`,
`scripts/lib/detect.sh::python_data_marker_detected()`, all
`SKILL.md` directories under `project-template/`.

---

## 1. Verdict

**Findings — fixes recommended, user decides.**

No BLOCKERs. The rewrite is structurally sound, the skill-count math
reconciles (31 = 13 + 16 + 1 + 1), the validator passes, the scope is
clean (only PLATFORM-SKILLS.md modified plus the untracked
implementation report), the custom sections are byte-identical, and
all four POQ dispositions are defensible. Two SHOULD-FIX items
(POQ-1 header arithmetic, missing trigger-loaded skills note) and two
NITs are listed below; none gate commit on their own.

---

## 2. Coverage check (5 dimensions, Tier 0, intersection, trigger)

| Item | Status | Evidence |
|---|---|---|
| D1 framing rule + table | ✓ present | lines 51–66; framing prose at 53–55 |
| D2 framing rule + table | ✓ present | lines 84–99 |
| D3 framing rule + table | ✓ present | lines 101–119 |
| D4 framing rule + table | ✓ present | lines 121–136 |
| D5 framing rule + table (NEW) | ✓ present | lines 138–159 |
| Tier 0 base section (13 skills) | ✓ present | lines 176–204 |
| Intersection table (sparse cells) | ✓ present | lines 206–222 |
| Trigger-loaded section | ✓ present (partial — see §6.2) | lines 224–234 |
| Monorepo D5 scoping note (per arch §7.4) | ✓ present | lines 161–174 |
| Worked examples (5 total) refreshed with D5 | ✓ present | lines 236–291 |
| `python_data_marker_detected()` cited as canonical predicate | ✓ present at line 214 | matches arch §7.5 |

All five `### Dimension N` headings appear; framing-rule prose matches
ARCHITECTURE-SKILL-DIMENSIONS.md §3.1–§3.5.

---

## 3. Skill enumeration

I enumerated every skill under `project-template/skills/` (one
authority) and every skill cell-assigned in PLATFORM-SKILLS.md (the
other authority). Both yield 31, and the names align row-for-row.

### 3.1 Filesystem-side (31 directories under `project-template/skills/`)

api-design, apple-architecture-core, architecture-review,
audit-methodology, c-language, cpp-language, debugging,
dependency-intake, dependency-python, dependency-swift,
deployment-apple, deployment-python, documentation, error-handling,
grpc-patterns, implementation, ios-architecture, macos-architecture,
objc-language, planning, pm-startup, python-best-practices,
python-data-architecture, python-server-architecture, repo-ops,
rest-patterns, review, security-patterns, swift-best-practices,
testing, ui-test-strategy.

### 3.2 PLATFORM-SKILLS.md-side cell assignments

- **Tier 0 base (13)** — api-design, architecture-review, debugging,
  dependency-intake, documentation, error-handling, implementation,
  planning, repo-ops, review, security-patterns, testing,
  ui-test-strategy. (lines 408–420)
- **Dimensional / intersection (16)** — apple-architecture-core,
  ios-architecture, macos-architecture, swift-best-practices,
  objc-language, c-language, cpp-language, python-best-practices,
  dependency-python, dependency-swift, grpc-patterns, rest-patterns,
  deployment-apple, deployment-python, python-server-architecture,
  python-data-architecture. (lines 429–444)
- **Trigger-loaded (1)** — audit-methodology. (line 456)
- **PM chat operational (1)** — pm-startup. (line 468)

**Sum: 13 + 16 + 1 + 1 = 31.** Matches the on-disk count exactly.

I disagree with **no** cell assignment; every skill maps to the cell the
architecture spec assigns it (cross-checked vs ARCHITECTURE-SKILL-DIMENSIONS.md §4).

---

## 4. Per-agent reclassification check (architecture §5)

| Reclassification | Spec source | Doc location | Verdict |
|---|---|---|---|
| `security-patterns` → Tier 0 | arch §3.6, §4.1 | line 196, line 418 | ✓ |
| `api-design` → Tier 0 | arch §3.6, §4.1 | line 186, line 408 | ✓ |
| `debugging` → Tier 0 | arch §3.6, §4.1 | line 188, line 410 | ✓ |
| `ui-test-strategy` → Tier 0 (with UI precondition) | arch §3.6, §4.1 | line 198, line 420 | ✓ |
| `planner` gains `architecture-review` | arch §5.5 | line 321 | ✓ |
| `reviewer` gains `api-design` + `debugging` | arch §5.3 | line 313 | ✓ |
| `auditor-code` gains `security-patterns` | arch §5.9 | line 348, justified at 350 | ✓ |
| `architect` gains planning, documentation, error-handling, security-patterns | arch §5.1 | line 305 | ✓ |
| `coder` gains documentation | arch §5.2 | line 309 | ✓ |

All seven required reclassifications present. The "13 Tier 0 base
skills" reconciliation note at lines 200–204 explicitly explains the
promotion of the four formerly-Tier-1 skills, with the
documentation-only nature called out (no SKILL.md content changes) —
this matches arch §4.1 framing.

---

## 5. POQ scrutiny

### 5.1 POQ-1 — "15 header vs 16 rows"

**Status: SHOULD-FIX.** The Dimensional skills section header at line
422 reads `### Dimensional skills (15)`. I counted the table rows
manually and via `awk`: there are **16** data rows (apple-architecture-core
through python-data-architecture). The reconciliation paragraph at
lines 446–450 attempts to defend "15" by claiming
`python-data-architecture` is "counted once even though it appears
under D2 conceptually" — but the table only lists it once already. The
arithmetic does not work out: 15 in header, 16 visible rows, prose
saying "16 (15 + 1 counted-once)" — three different numbers in three
locations.

The total-count line at 470 says "**Total skills: 31** (13 Tier 0
base + 16 dimensional / intersection + 1 trigger-loaded + 1 PM chat
operational)" — this uses 16, which matches the actual row count and
sums to the correct on-disk total of 31. The (15) in the header is the
outlier.

**Proposed fix:** Change line 422 from `### Dimensional skills (15)`
to `### Dimensional skills (16)`. Delete or rewrite the confusing
reconciliation paragraph at lines 446–450 — it adds noise without
explaining anything that needs explaining (every row is one skill;
sum is 16). Replace with a one-line note: "16 dimensional /
intersection skills. Two of these (`python-server-architecture`,
`python-data-architecture`, `deployment-python`) are intersection-loaded
per the predicate column; the rest load directly from a single D1/D2/D4/D5
selector."

### 5.2 POQ-2 — Monorepo D1 multi-component selection

**Status: defensible.** The D1 framing-rule prose at lines 53–55 says
"One value per executable target. Multi-target projects select multiple
values (e.g., a universal Apple app selects both `ios` and `macos`)."
The third worked example (Universal Apple app + Python gRPC server,
lines 263–271) extends this to monorepos by selecting three D1 values
(`ios`, `macos`, `linux-server`) — proving in worked form that
monorepos chain D1 selections per component.

The framing rule technically uses "executable target" rather than
"component," which could create ambiguity when a single executable has
multiple architectures (e.g., universal binary). In practice the worked
example clarifies; the framing-rule wording is acceptable.

### 5.3 POQ-3 — Trigger-loaded scope (project-template only)

**Status: defensible disposition; doc gap noted.** Architecture §3.8
lists 5 trigger-loaded skills: `audit-methodology`, `pm-startup`,
`verification-harness`, `implementation-report`, `commit-discipline`.
I confirmed via `find` that the latter three exist ONLY in the pack
repo's own `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
directories (pack-repo agent infrastructure for `pack-coder` etc.) —
not in `project-template/`. Excluding them from a project-scope
PLATFORM-SKILLS.md is correct.

However, the doc currently makes no statement that these three exist
elsewhere or why they were omitted. A reader comparing
PLATFORM-SKILLS.md against the architecture doc will see a 5→2
discrepancy and may file a defect or duplicate the entries
incorrectly.

**Proposed fix (SHOULD-FIX):** After the trigger-loaded table (line
234) add a short note: "Pack-repo development uses three additional
trigger-loaded skills (`verification-harness`, `implementation-report`,
`commit-discipline`) that live in the pack repo's own
`.claude/skills/`, `.codex/skills/`, `.gemini/skills/` directories and
are not part of the project-scope skill catalog. They are documented
in the pack repo's `PACK-AGENTS.md`."

### 5.4 POQ-4 — `embedded-runtime` cell

**Status: defensible.** D3 row at line 113 has `embedded-runtime` with
example "embedded Python inside a Swift app — D1 + D2 carry it; no
`python-server-architecture`". Architecture §3.3 uses identical
semantics. D1's `embedded-mcu` (deferred) is a different concept
entirely (bare-metal MCU OS substrate vs. an embedded language runtime
hosted inside another app). No semantic clash; the worked example
"macOS Swift app with embedded Python" (lines 273–281) demonstrates
the D3=embedded-runtime path correctly.

---

## 6. Cross-reference correctness

### 6.1 `python_data_marker_detected` references

`grep -c` returned 7 references; I read each in context:

| Line | Context | Verdict |
|---|---|---|
| 93 | D2 python row notes | ✓ name-drop with link to intersection table; appropriate |
| 214 | Intersection table cell — canonical predicate cite | ✓ authoritative cite with file path and dependency list |
| 259 | Worked example "Python gRPC server" | ✓ used as predicate verb |
| 279 | Worked example "macOS Swift app + embedded Python" | ✓ used as predicate verb with marker explanation |
| 344 | auditor-architecture per-agent block | ✓ cited as the predicate for non-server multi-file Python |
| 349 | auditor-code per-agent block | ✓ cited as the predicate for the data-architecture skill load |
| 444 | Inventory-table Cell column | ✓ predicate path cited inline |

All 7 references are contextually appropriate citations of the helper
as the canonical predicate where the data-marker branch matters. No
empty name-drops. The doc accurately describes the helper's behavior
(I read `scripts/lib/detect.sh` lines 334–384): both manifest-marker
detection and `>=5 .py` file count are covered.

### 6.2 Stale framing references

Searched for "four dimension", "four-dimension", "Tier 1", "Tier 2",
"Dimension 4":

| Match | Line | Verdict |
|---|---|---|
| "Dimension 4 — Communication protocols" | 121 | Legitimate (D4 in new model) |
| "the four-dimension model (`deployment-apple` was implicitly carried..." | 155 | Legitimate (historical retrospective) |
| "Several of these were classified as 'Tier 1 role skills' in the pre-v11 model" | 200 | Legitimate (explicit historical reference) |
| "Tier 1 skills | Tier 2 skills" (Custom agents table column headers) | 510 | **Stale, but byte-identical-preservation per spec** — see §7 |

No genuine survivors of the old framing in the rewritten content. The
Custom agents column-header tension is discussed in §7.

### 6.3 No references to nonexistent skills

I spot-checked the following skill names against the on-disk SKILL.md
inventory:

| Skill name in doc | On-disk? |
|---|---|
| `apple-architecture-core` (line 429) | ✓ |
| `python-server-architecture` (line 443) | ✓ |
| `python-data-architecture` (line 444) | ✓ |
| `deployment-python` (line 442) | ✓ |
| `audit-methodology` (line 456) | ✓ |
| `pm-startup` (line 468) | ✓ |
| `architecture-review` (line 409) | ✓ |
| Future `swift-server-architecture` (line 216) | Marked `*(future)*` — correctly noted as deferred |

No references to skills that do not exist. The "Deferred skills"
section (lines 478–496) lists future names appropriately tagged.

---

## 7. Custom-section preservation

I diffed the `## Custom agents` section (line 500 to next `---`) and
the `## Custom skills` section (line 520 to next `---`) between
HEAD and the working tree:

```
diff <(sed -n '/^## Custom agents$/,/^---$/p' /tmp/old-platform-skills.md) \
     <(sed -n '/^## Custom agents$/,/^---$/p' project-template/docs/pack/PLATFORM-SKILLS.md)
# (no output — byte-identical)

diff <(sed -n '/^## Custom skills$/,/^---$/p' /tmp/old-platform-skills.md) \
     <(sed -n '/^## Custom skills$/,/^---$/p' project-template/docs/pack/PLATFORM-SKILLS.md)
# (no output — byte-identical)
```

Both confirmed byte-identical — independent of Pack Chat's pre-review
check.

**Side observation (NIT, not blocker):** The Custom agents
illustrative-row column headers (line 510) carry `Tier 1 skills | Tier
2 skills`, which are the deprecated framing names. Preserving the
section byte-identical was the correct choice given the spec, but the
illustrative row is now slightly inconsistent with the new model
(promoted skills like `security-patterns` no longer have a "Tier"
designation). This is an acceptable tension to leave for a follow-up
batch — projects using Procedure 5 will replace the illustrative row
anyway.

---

## 8. Validator output

```
$ python3 scripts/validate-pack.py
[...all 30 checks listed pass...]
============================================================
PASSED — all checks clean
```

No regression. Check 21 (per-agent canonical phrases) and Check 28
(PM-startup parity) both pass.

---

## 9. Scope discipline

```
$ git diff --stat HEAD
 project-template/docs/pack/PLATFORM-SKILLS.md | 557 +++++++++++++++++---------
 1 file changed, 375 insertions(+), 182 deletions(-)

$ git status
On branch v11-dev
Changes not staged for commit:
	modified:   project-template/docs/pack/PLATFORM-SKILLS.md
Untracked files:
	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-142.md
```

Only the rewrite target was modified, plus the expected untracked
implementation report. No collateral edits. Pre-rewrite was 355 lines;
post-rewrite is 549 — a 194-line expansion consistent with the scope
of the reframe (new D5 dimension, intersection table, trigger-loaded
table, expanded inventory, monorepo scoping note).

---

## 10. Findings (numbered, severity-tagged)

### F1 — POQ-1 header arithmetic does not match table rows

- **Severity:** SHOULD-FIX
- **Location:** `project-template/docs/pack/PLATFORM-SKILLS.md` line 422
  (header `### Dimensional skills (15)`); reconciliation paragraph
  lines 446–450; total-count line 470.
- **Issue:** Header says 15, table has 16 rows, total at line 470 says
  16. The reconciliation paragraph attempts to defend "15 + 1
  counted-once" but the table only lists `python-data-architecture`
  once, so the math is not "15 + 1" — it is just 16.
- **Impact:** Downstream readers (BD-143 trinity prose, BD-146
  validator Check 31) will trip on the header/row mismatch and may
  encode the wrong number. Reviewers running `wc -l` on the table will
  see 16 and challenge the header.
- **Proposed fix:** (a) Change line 422 to `### Dimensional skills
  (16)`. (b) Replace lines 446–450 with: "16 dimensional /
  intersection skills. The Cell column is the authoritative load
  predicate; three rows (`python-server-architecture`,
  `python-data-architecture`, `deployment-python`) are
  intersection-loaded per the §"Intersection table" predicates; the
  remaining 13 load directly from a single D1/D2/D4/D5 selector."

### F2 — Trigger-loaded section silently omits 3 pack-repo-scope skills

- **Severity:** SHOULD-FIX
- **Location:** `project-template/docs/pack/PLATFORM-SKILLS.md`
  lines 224–234 (in-text trigger table) and line 456 (inventory).
- **Issue:** ARCHITECTURE-SKILL-DIMENSIONS.md §3.8 enumerates 5
  trigger-loaded skills (`audit-methodology`, `pm-startup`,
  `verification-harness`, `implementation-report`,
  `commit-discipline`). The doc lists only the first two. The decision
  to omit the latter three is **correct** (they live only under the
  pack repo's `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
  trees, not under `project-template/`), but the omission is silent.
  A reader cross-checking the architecture doc will perceive a
  defect.
- **Impact:** Modest. POQ-3 disposition is sound; the issue is purely
  documentary clarity.
- **Proposed fix:** After the trigger-loaded table at line 234 add:
  "Pack-repo development additionally uses `verification-harness`,
  `implementation-report`, and `commit-discipline` as trigger-loaded
  skills. Those skills live in the pack repo's own `.claude/skills/`,
  `.codex/skills/`, `.gemini/skills/` trees (not under
  `project-template/`) and are out of scope for project-side skill
  selection. See `PACK-AGENTS.md` in the pack repo for their use."

### F3 — Custom agents illustrative row uses deprecated tier framing

- **Severity:** NIT
- **Location:** `project-template/docs/pack/PLATFORM-SKILLS.md` line
  510 (column header `Tier 1 skills | Tier 2 skills`).
- **Issue:** The new model has no Tier 1 or Tier 2 — only Tier 0 base,
  dimensional, intersection, and trigger. The Custom agents
  illustrative row (which the spec correctly required to be preserved
  byte-identical) now uses framing terms that no longer exist.
- **Impact:** Low. Procedure 5 (which writes real Custom agents rows)
  will need to invent its own column convention regardless; the
  illustrative row is replaced when the PM chat fills it in.
- **Proposed fix:** Defer to a separate follow-up batch coordinated
  with whatever Procedure 5 doc updates ship next. Do not block this
  commit. (If the user wants the column rename now, propose new
  headers like `Skills loaded` or `Dimensional skills | Tier 0
  skills` — but this is a per-procedure-5 decision, not a per-BD-142
  decision.)

### F4 — D1 framing-rule wording uses "executable target" rather than "component"

- **Severity:** NIT
- **Location:** `project-template/docs/pack/PLATFORM-SKILLS.md` lines
  53–55.
- **Issue:** "One value per executable target" is technically less
  precise than "one value per component" for the monorepo case. A
  monorepo can have multiple executable targets in a single component
  (e.g., a universal Apple binary with one ios + one macos slice) and
  multiple components with non-overlapping executable targets. The
  worked example at lines 263–271 disambiguates by example, but the
  framing-rule wording could mislead a reader who skims only the
  table.
- **Impact:** Low; worked example covers the intent.
- **Proposed fix:** Soften wording to "One value per executable target
  per component. Multi-target projects (e.g., a universal Apple app)
  select multiple values; monorepos with multiple components also
  select multiple values, one per component (see worked examples
  below)."

---

## 11. Verdict rationale

The rewrite is correct, complete, and consistent with the architecture
spec on every load-bearing axis: 5 dimensions present and accurately
framed, 3 load mechanisms explicit, 31 skills enumerated and on-disk,
all four Tier 0 promotions and three per-agent additions implemented,
intersection-table predicates accurate (verified against
`scripts/lib/detect.sh`), worked examples refreshed for D5, monorepo
scoping note added per architecture §7.4, custom sections preserved
byte-identical, validator green, scope discipline clean. The two
SHOULD-FIX findings (F1 header arithmetic, F2 silent trigger-loaded
omission) are documentation-clarity issues with concrete, narrow
fixes; neither blocks downstream batches from consuming this doc as
authoritative truth, but both warrant correction in the BD-142 commit
or as an immediate fix-follow before BD-143/BD-146 begin. The two NITs
(F3 deprecated tier headers in preserved Custom section, F4 D1
"executable target" wording) are deferrable. Verdict: **Findings —
fixes recommended, user decides.**

---

**Doc path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-142.md`
