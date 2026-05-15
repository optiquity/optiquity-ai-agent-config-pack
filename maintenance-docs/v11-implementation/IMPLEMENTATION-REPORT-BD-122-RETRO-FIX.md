# IMPLEMENTATION-REPORT-BD-122-RETRO-FIX

Retro review-fix for BD-122 ("Document `test-fixtures/`
`<vN>-<persona>` versioning convention"), part of Batch 21c per the
2026-05-15 review/fix cycle memory revision. Source review:
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-122-RETRO.md`.

## 1. Summary

Applied 3 in-place edits to `test-fixtures/README.md` covering all
findings from PACK-REVIEW-BD-122-RETRO: F1 (SHOULD) wires the "Adding
a new fixture" procedure into the new Naming convention via a step 0
and an expanded step 3; F2 (NIT) adds a column-vocabulary micro-rule
to the version-pinned bullet so `<vN>-pinned` is no longer an unstated
inference; F3 (NIT) revises the picker prose to admit persona-overlay
fixtures (`v10-realistic-ot`, `v11-tracker-on`) which the original
"snapshot of pack output" wording technically excluded. Net delta:
+15 / −5 lines, single-file scope. No methodology friction acted on
in this fix (deferred to a future revision pass per the retro's own
notes).

## 2. Per-finding fix detail

### F1 — `Adding a new fixture` procedure does not reference the new convention (SHOULD)

**Finding (quoted from PACK-REVIEW-BD-122-RETRO.md):**

> BD-122 adds a "Naming convention" section and a new "Versioning"
> column to the fixture table, but the immediately-relevant
> contributor procedure ("Adding a new fixture", 4 numbered steps) was
> not updated. Step 3 ("Document the new fixture in this README's
> table") tells a future contributor to add a row but doesn't remind
> them to (a) populate the new `Versioning` cell or (b) consult the
> convention to choose the fixture name. The convention exists; the
> procedure that consumes it doesn't link in. Future contributors who
> jump straight to the procedure (the natural entry point — it has
> the imperative steps) can miss the convention.

**Fix:** Added step 0 referencing the Naming convention; expanded step 3
to enumerate the column vocabulary explicitly. Reviewer's concrete
proposal applied verbatim.

**Before** (`test-fixtures/README.md` lines 129–135 pre-fix):

```markdown
## Adding a new fixture

1. Add a `_build_<name>()` function to `build.sh` following the
   pattern of the existing builders.
2. Add the name to the `FIXTURE_NAMES` array near the top.
3. Document the new fixture in this README's table.
4. Run `bash build.sh --all` and commit the updated `manifest.txt`.
```

**After** (lines 134–145 post-fix):

```markdown
## Adding a new fixture

0. Pick a fixture name per the **Naming convention** above
   (`<vN>-<persona>` for version-pinned, bare hyphenated descriptor
   for version-agnostic).
1. Add a `_build_<name>()` function to `build.sh` following the
   pattern of the existing builders.
2. Add the name to the `FIXTURE_NAMES` array near the top.
3. Document the new fixture in this README's table — populate all
   columns including `Versioning` (`v10-pinned`, `v11-pinned`, …, or
   `version-agnostic`).
4. Run `bash build.sh --all` and commit the updated `manifest.txt`.
```

Step 0 is intentionally numbered `0` (not renumbered to `1` with
shifts) because (a) the reviewer's proposal uses `0`, and (b) it
preserves the "nothing-to-do-with-build-mechanics" character of the
naming-choice step versus the build-mechanics steps 1–4.

### F2 — `Versioning` column uses three values; convention text names two (NIT)

**Finding (quoted):**

> A reader of the convention section who looks at the table sees
> three distinct values where the rule names two classes. The
> inference is one short hop — `v10-pinned` and `v11-pinned` are
> obviously both version-pinned — but it is a hop, and the
> column-value pattern itself (`<vN>-pinned`) is a third implicit
> micro-rule the convention doesn't state. When `v12-flat-file` lands
> its row will use `v12-pinned`, reinforcing the unstated pattern.

**Fix:** Appended one sentence to the version-pinned bullet stating
the column-value pattern explicitly, mirroring the reviewer's
proposed wording with light prose tightening (added the phrase "in
the `Versioning` column" so the table-vs-name distinction is unambiguous).

**Before** (lines 39–47, last sentence of the version-pinned bullet):

```markdown
- **`<vN>-<persona>` for version-pinned fixtures.** The `vN` prefix
  (`v10-`, `v11-`, …) anchors the fixture to a specific pack-version
  baseline — either a tagged release (`v10-minimal` is built from the
  `v10` tag) or the current pack `HEAD` for the named major
  (`v11-flat-file`, `v11-tracker-on`). The `<persona>` half names the
  shape the fixture represents (`minimal`, `realistic-ot`, `flat-file`,
  `tracker-on`). When v12 lands, expect `v12-flat-file`,
  `v12-tracker-on`, etc., as siblings — never overwrite a v11 fixture
  in place.
```

**After** (lines 39–50 post-fix):

```markdown
- **`<vN>-<persona>` for version-pinned fixtures.** The `vN` prefix
  (`v10-`, `v11-`, …) anchors the fixture to a specific pack-version
  baseline — either a tagged release (`v10-minimal` is built from the
  `v10` tag) or the current pack `HEAD` for the named major
  (`v11-flat-file`, `v11-tracker-on`). The `<persona>` half names the
  shape the fixture represents (`minimal`, `realistic-ot`, `flat-file`,
  `tracker-on`). When v12 lands, expect `v12-flat-file`,
  `v12-tracker-on`, etc., as siblings — never overwrite a v11 fixture
  in place. In the **Available fixtures** table above, version-pinned
  rows take the form `<vN>-pinned` in the `Versioning` column
  (`v10-pinned`, `v11-pinned`, …); the version-agnostic class uses
  the literal value `version-agnostic`.
```

Diff vs. reviewer's verbatim proposal: replaced "In the table above"
with "In the **Available fixtures** table above" and added "in the
`Versioning` column" because the README has multiple tables (well, it
has one fixture table — but the disambiguating phrase costs nothing
and removes the question entirely for a future reader scanning out of
order). Both the directory-name pattern (`<vN>-<persona>`) and the
column-value pattern (`<vN>-pinned`) are now stated; the implicit
micro-rule is now explicit.

### F3 — Convention text "snapshot of pack output" elides persona overlay (NIT)

**Finding (quoted):**

> "Snapshot of pack output at a specific version" is technically
> inaccurate for `v10-realistic-ot` and `v11-tracker-on` — both layer
> persona-specific overlays on top of pack output. The intent is
> clear from context (the version-pinned class includes "pack +
> overlay" rows whose overlay content is itself version-coupled),
> but the precise wording reads as if version-pinned ⇒ raw pack
> output only, which excludes 2 of the 4 version-pinned fixtures
> shipped at this commit.

**Fix:** Replaced the elision-prone wording with a phrasing that
admits overlay-bearing fixtures, and named the two concrete examples
parenthetically so a reader can verify the rule against a row in the
table immediately above without needing to re-derive what counts as
"persona overlay."

**Before** (lines 55–57 pre-fix):

```markdown
Pick version-pinned when the fixture's content is a snapshot of pack
output at a specific version. Pick version-agnostic when the fixture is
input *to* the pack and is not itself a pack artifact.
```

**After** (lines 58–62 post-fix):

```markdown
Pick version-pinned when the fixture's content is a snapshot of (pack
output ± persona overlay) at a specific version — including fixtures
that layer hand-applied customizations on top of a pack install
(`v10-realistic-ot`, `v11-tracker-on`). Pick version-agnostic when the
fixture is input *to* the pack and is not itself a pack artifact.
```

Reviewer's suggested phrasing was "snapshot of (pack output ±
persona overlay) at a specific version" — used as-is. Added the
"including fixtures that layer hand-applied customizations on top of
a pack install (`v10-realistic-ot`, `v11-tracker-on`)" amplification
because the `±` operator is mathematically tidy but reads opaquely
to a contributor scanning quickly; naming the two example rows
makes the rule self-evident from the table above. The `±` notation
is preserved (vs. dropped in favor of "with or without") because it
parallels the convention's prevailing concise prose register.

## 3. Files modified

| Path | Change type | Line delta |
|---|---|---|
| `test-fixtures/README.md` | modified | +15 / −5 |

Verified via `git diff --stat`:

```
 test-fixtures/README.md | 20 +++++++++++++++-----
 1 file changed, 15 insertions(+), 5 deletions(-)
```

No other files were touched. The new report file
(`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-122-RETRO-FIX.md`)
is the agent's deliverable, not a code change.

## 4. Verification

This is a docs-only fix; no executable code changed, so no test
script needed re-running. Verification per the prompt's Success
criteria = end-to-end re-read for internal consistency.

**Re-read of `test-fixtures/README.md` after all 3 edits:**

The convention/column/procedure triplet is now self-consistent across
the file. Specifically:

- **Table (line 26 header, lines 28–33 rows):** `Versioning` column
  populated with values `v10-pinned`, `v10-pinned`, `v11-pinned`,
  `v11-pinned`, `version-agnostic`, `v11-pinned`. All values match
  one of the two patterns now stated explicitly in the convention.
- **Naming convention §, version-pinned bullet (lines 39–50):** the
  bullet describes the directory-name pattern (`<vN>-<persona>`)
  AND, after F2, names the column-value pattern (`<vN>-pinned`) and
  the version-agnostic literal. A reader who reads only this bullet
  has the full vocabulary the table uses.
- **Naming convention §, version-agnostic bullet (lines 51–56):**
  unchanged. Names `existing-project-mid-dev` as the canonical
  example; consistent with the table row at line 32.
- **Picker rule (lines 58–62):** after F3, correctly admits
  persona-overlay fixtures as version-pinned (covers
  `v10-realistic-ot`, `v11-tracker-on`, and by extension
  `v11-trinity-marker-prepped` whose row was added post-BD-122).
  No row in the table now contradicts the picker rule.
- **Adding a new fixture procedure (lines 134–145):** after F1,
  step 0 directs contributors to the convention before they pick a
  name; step 3 enumerates the same column-value vocabulary the
  convention's F2 sentence introduces. Procedure → convention →
  column triplet is closed.

**Cross-references re-verified:**

- `BD-115`/`BD-116` mentioned in the version-agnostic bullet (line
  56) — unchanged, still accurate.
- `BD-120` realistic-OT subsection (lines 154–168) — unchanged, not
  in F1/F2/F3 scope; flow into "## See also" still clean.
- "## See also" section (lines 170–178) — unchanged.

**Pack-rule compliance:**

- Trinity rule: not applicable (`test-fixtures/README.md` is not in
  the trinity set).
- Pack-ops vs. pack-product separation: `test-fixtures/` is pack-ops
  end-to-end; edit stayed within pack-ops boundary.
- Forbidden-file check: `BACKLOG.md`, `CHANGELOG.md`, scripts, other
  docs — none touched. Confirmed via `git diff --stat`.
- Git state: no state-changing git verbs run. `git status` and
  `git diff --stat` are read-only.

**Branch + HEAD SHA at session end:** `v11-dev` @
`64af9f70162564e6785b47f3aaea802833fab509` (unchanged from start —
agents never commit).

## 5. Out-of-scope items

The retro itself flagged two methodology-friction items in its
"Methodology friction notes" section. Neither is BD-122 fix work;
both are deferred to a future methodology revision pass:

1. **CONCEPTUAL-REVIEW-METHODOLOGY.md missing a "convention/naming
   docs" finding-mode checklist.** The retro suggests adding one
   alongside the existing race-condition heuristic. This is a
   structural change to the methodology doc and would require
   architect-then-planner per the pack-repo "skill and agent
   maintenance" rule. Not in scope for a docs-fix coder pass.
2. **Convention-evolution friction across adjacent batches**
   (BD-122 ↔ BD-136 M-8). The retro notes that the
   `v11-trinity-marker-prepped` "frozen real-world snapshot" class
   that emerged with BD-136 M-8 the day after BD-122 shipped is a
   textbook case where a convention established in BD-N+0 had to
   admit a new class introduced in BD-N+1. This is not a BD-122
   defect (the M-8 spec didn't exist at commit `400928a`), but the
   convention text as it stands today silently absorbs M-8 via the
   `v11-pinned` column value without naming the "frozen real-world
   snapshot" subclass distinct from the "tagged release" and
   "current pack HEAD" subclasses. Treating this as a methodology
   improvement (not a fix) is appropriate: the rule still works,
   the row still parses, the picker still picks correctly. A
   future BD could refactor the convention to name three subclasses
   of version-pinned (tagged release, current HEAD, frozen
   real-world snapshot) but doing so unilaterally during a retro
   fix would violate the "no architecture in fix work" boundary.

Sibling concerns noticed during the end-to-end re-read but **not**
acted on:

- The `## When to add a fixture here vs. elsewhere` section (lines
  64–78) and the `## Adding a new fixture` section (lines 134–145)
  are visually separated by 6 unrelated sections (How fixtures are
  used, Determinism, Why fixtures are gitignored). A future doc
  revision could collocate them, since they are conceptually
  adjacent (both answer "I have a new fixture, what do I do?").
  Not in scope: PACK-REVIEW-BD-122-RETRO did not flag this and
  reordering sections would be a structural edit beyond the fix
  mandate. No action taken.
- The phrase "snapshot of (pack output ± persona overlay)" uses a
  mathematical operator (`±`) for prose-register concision. Some
  readers may find this notation unidiomatic; an alternative
  ("pack output, with or without a persona overlay") is wordier
  but more accessible. Both are technically correct. The retro
  prefers the `±` form (per its suggested-fix block); this fix
  defers to the retro. A future style-pass could revisit if a
  pattern emerges across multiple convention docs.

No new POQs introduced. No plan deviations. Definition of Done:
all 3 findings addressed, scope tight to `test-fixtures/README.md`,
no forbidden files touched, end-to-end self-consistency verified.
