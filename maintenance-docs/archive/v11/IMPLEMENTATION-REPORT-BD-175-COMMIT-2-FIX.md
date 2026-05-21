# IMPLEMENTATION-REPORT — BD-175 Phase 5 Commit 2 fix-pass

**Author:** pack-coder (fix-coder)
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD at start:** `59a7dbb5fe7878b151064e0c9cb33268ae4dcfb1`
**HEAD at PREFLIGHT:** `59a7dbb5fe7878b151064e0c9cb33268ae4dcfb1` (working-tree-only changes; no commit)
**Reviewer report acted on:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-2.md` §1 defects D-1, D-2, D-3, D-4

---

## §1 Summary

4 reviewer-cited defects triaged for fix-all by the user; 3 fully applied as
specified; 1 (D-4) applied at 4 of 5 cited prose locations with one location
(L37) intentionally preserved because the reviewer-cited "stale prose" is the
exact sentinel string the awk regex in `scripts/pack-help.sh:86` matches to
substitute the tracker fragment at render time — changing it broke
`pack-help-test.sh` test 2.1. Full discussion in §5 below.

| Defect | Severity | File(s) | Status |
|---|---|---|---|
| D-1 | NIT | `CLAUDE.md:74`, `AGENTS.md:68` | FIXED (trinity-symmetric with GEMINI.md:47) |
| D-2 | SHOULD | `README.md:45` | FIXED |
| D-3 | MUST | `QUICKSTART.md:10`, `:43` | FIXED (Override 7 honored — link-targets only) |
| D-4 | SHOULD | `pack-ops/HELP-FRAGMENT-PACK.md` L5, L41, L42 | FIXED |
| D-4 | SHOULD | `pack-ops/HELP-FRAGMENT-PACK.md` L37 | DEFERRED with rationale (sentinel coupling — see §5.2) |

**Files modified (5):**
- `CLAUDE.md` (+1/−1)
- `AGENTS.md` (+1/−1)
- `README.md` (+1/−1)
- `QUICKSTART.md` (+2/−2)
- `pack-ops/HELP-FRAGMENT-PACK.md` (+3/−3)

Total: 8/8 line deltas. No files outside the 5-file scope modified.

---

## §2 D-1 trinity asymmetry fix

**Reviewer finding:** GEMINI.md L47's "BD numbering" prose was updated by
Commit 2 (`59a7dbb`) to reference `pack-ops/BACKLOG.md`, but the parallel
bulleted sentences in CLAUDE.md:74 + AGENTS.md:68 were missed. Trinity
asymmetry. Reviewer recommended aligning CLAUDE/AGENTS to GEMINI's
already-updated wording.

### CLAUDE.md:74

**BEFORE:**
```
**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
```

**AFTER:**
```
**BD-NNN numbering:**
- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
```

### AGENTS.md:68

**BEFORE:**
```
**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
```

**AFTER:**
```
**BD-NNN numbering:**
- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
```

### Trinity parity verification

```
$ grep -n "BD-NNN numbering\|BD numbering" CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:73:**BD-NNN numbering:**
CLAUDE.md:74:- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
AGENTS.md:67:**BD-NNN numbering:**
AGENTS.md:68:- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
GEMINI.md:47:**BD numbering:** Always read `pack-ops/BACKLOG.md` to find the highest existing BD
```

All 3 trinity files now reference `pack-ops/BACKLOG.md`. Wording differs
slightly (CLAUDE/AGENTS use bulleted form per Claude/Codex idiom; GEMINI
uses prose form per Gemini idiom) — this differential predates the defect
and is the intentional per-CLI presentation; the path reference is the
load-bearing parity claim and is now uniform.

---

## §3 D-2 README.md link fix

**Reviewer finding:** README.md L45 had `[\`OPTIONAL-FEATURES.md\`](OPTIONAL-FEATURES.md)`
in the "Optional features and settings" section — link target moved to
`pack-ops/` in Commit 2 but the prose link target was missed.

### README.md:45

**BEFORE:**
```
can plug into. See [`OPTIONAL-FEATURES.md`](OPTIONAL-FEATURES.md) for the
```

**AFTER:**
```
can plug into. See [`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md) for the
```

### Spot-check for other broken links

Per the prompt's "verify other markdown links in README.md don't have similar
staleness" instruction, ran:

```
$ grep -nE "\[.*\.md.*\]\(.*\.md\)" README.md | grep -iE "BACKLOG|CHANGELOG|PACK-CHAT|PACK-AGENTS|HELP-FRAGMENT-PACK|HELP-FRAGMENT-TRACKER|OPTIONAL-FEATURES"
45:can plug into. See [`OPTIONAL-FEATURES.md`](OPTIONAL-FEATURES.md) for the
```

Pre-fix: 1 broken link (L45). Post-fix: 0 broken links. No other links to
any of the 7 moved files exist in README.md.

---

## §4 D-3 QUICKSTART.md link fix

**Reviewer finding:** QUICKSTART.md contained 2 broken markdown links:
- L10: `[\`HELP-FRAGMENT-PACK.md\`](HELP-FRAGMENT-PACK.md)` — target moved
- L43: `[\`OPTIONAL-FEATURES.md\`](OPTIONAL-FEATURES.md)` — target moved

### Override 7 reconciliation (user-authorized interpretation)

Per `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 7
lines 59-65, the user mandated "NO SPLIT" of QUICKSTART.md and "stays at
root as-is." The Override's textual scope is the file's STRUCTURE and
LOCATION — it does not address internal link maintenance when sibling
files move out from under it.

The prompt for this fix-pass explicitly cites the user's interpretation:
> "Override 7's intent was 'no SPLIT, no MOVE of QUICKSTART itself' —
> preserved. Updating internal link targets when sibling files move is
> mechanical maintenance, NOT structural restructuring. Override 7 does
> NOT prohibit this fix."

Per that interpretation, this fix updates only the 2 link targets (no
content restructuring, no section reorganization, no prose rewriting
beyond the path-substring in each link). File remains at pack root.
File length unchanged at 47 lines.

### QUICKSTART.md:10

**BEFORE:**
```
> `/pack-help` — see [`HELP-FRAGMENT-PACK.md`](HELP-FRAGMENT-PACK.md).
```

**AFTER:**
```
> `/pack-help` — see [`pack-ops/HELP-FRAGMENT-PACK.md`](pack-ops/HELP-FRAGMENT-PACK.md).
```

### QUICKSTART.md:43

**BEFORE:**
```
For tracker opt-in (Phase B of the v11 migration), see
[`OPTIONAL-FEATURES.md`](OPTIONAL-FEATURES.md).
```

**AFTER:**
```
For tracker opt-in (Phase B of the v11 migration), see
[`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md).
```

### Spot-check for other broken links

```
$ grep -nE "\[.*\.md.*\]\(.*\.md\)" QUICKSTART.md | grep -iE "BACKLOG|CHANGELOG|PACK-CHAT|PACK-AGENTS|HELP-FRAGMENT-PACK|HELP-FRAGMENT-TRACKER|OPTIONAL-FEATURES"
10:> `/pack-help` — see [`pack-ops/HELP-FRAGMENT-PACK.md`](pack-ops/HELP-FRAGMENT-PACK.md).
43:[`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md).
```

Pre-fix: 2 broken links. Post-fix: 0 broken links. No other links to any
of the 7 moved files exist in QUICKSTART.md. Links to
`supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP-EXISTING.md`,
`supporting-docs/MIGRATION-*.md`, `supporting-docs/MERGE-STRATEGY.md`,
`README.md`, `LICENSE.md` are all unchanged (none of these targets moved
in Commit 2).

---

## §5 D-4 pack-ops/HELP-FRAGMENT-PACK.md prose fix

**Reviewer finding:** 4 line-locations in `pack-ops/HELP-FRAGMENT-PACK.md`
(L4-5, L37, L41-42) contained stale bare-root file-name prose printed by
`pack help` — `git mv` preserved content but didn't update file-name prose
for the new pack-ops/ location.

### §5.1 Successfully fixed locations (L5, L41, L42)

#### L4-5 "Full docs in" line

**BEFORE:**
```
Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`PACK-CHAT.md`, `OPTIONAL-FEATURES.md`.
```

**AFTER:**
```
Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md`.
```

`QUICKSTART.md` and `README.md` remain bare-root (per Overrides 7 + canonical
README.md root residency). `PACK-CHAT.md` + `OPTIONAL-FEATURES.md` get the
`pack-ops/` prefix.

#### L41-42 "See also" section

**BEFORE:**
```
## See also

`PACK-CHAT.md`, `PACK-AGENTS.md`, `OPTIONAL-FEATURES.md`, `BACKLOG.md`,
`CHANGELOG.md`.
```

**AFTER:**
```
## See also

`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/BACKLOG.md`,
`pack-ops/CHANGELOG.md`.
```

All 5 names get the `pack-ops/` prefix (all 5 files moved in Commit 2).

### §5.2 L37 — DEFERRED with rationale (sentinel-coupling discovery)

**BEFORE (unchanged):**
```
[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]
```

**Reason for deferral:** `scripts/pack-help.sh:86` contains the awk regex
`/^\[Included from \`HELP-FRAGMENT-TRACKER\.md\`/` which matches this exact
sentinel string to substitute the tracker fragment inline at render time.
The reviewer's D-4 classification of L37 as "stale prose" missed this
coupling — L37 is not user-visible prose, it is a sentinel marker the
script processes and replaces.

**Discovery path:** Applied the naive D-4 fix (changed L37 to
`[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via \`pack-help.sh\`.]`),
re-ran `bash scripts/tests/pack-help-test.sh`, and observed test
`2.1 colloquial mapping inlined` FAIL — the substitution didn't fire
because the regex pattern no longer matched. The rendered output kept
the placeholder line verbatim instead of inlining the tracker content,
so the "colloquial mapping" content (in the tracker fragment) was
absent from output. Reverted L37 to the original sentinel string;
re-ran tests; all 17/17 pass.

**Out-of-scope fix path:** A complete fix for L37's now-misleading-but-
functional prose ("at pack root" is no longer accurate post-Commit 2)
requires editing BOTH the sentinel string in `pack-ops/HELP-FRAGMENT-PACK.md`
AND the awk regex in `scripts/pack-help.sh:86` to a matching new form.
That second edit is outside this fix-pass's scope (prompt restricts to
5 named files; `scripts/pack-help.sh` is not in the list). It is also
a v11-surface change (under `scripts/`) which would require manifest
regen per RC9 — the prompt explicitly states "Manifest regen NOT
required per current RC9 (no project-template/ or scripts/ touched)."

**Disposition:** Recorded as a new OQ in §8 below for Pack Chat to
open as a follow-on BD post-fix. The "stale prose" is contained to a
single sentinel line that is substituted out before user sees output,
so the user-impact severity is effectively 0 (no user ever sees
"at pack root via pack-help.sh" in `pack help` output — they see the
inlined tracker fragment). Reviewer's SHOULD severity for D-4 was
predicated on user-visibility; for L37 specifically the user-visibility
is zero, so deferral does not regress the user experience.

### §5.3 Spot-check for additional staleness

Per the prompt's "Spot-check the entire file for any other similar
staleness" instruction:

```
$ grep -n -E "BACKLOG\.md|CHANGELOG\.md|PACK-CHAT\.md|PACK-AGENTS\.md|HELP-FRAGMENT-PACK\.md|HELP-FRAGMENT-TRACKER\.md|OPTIONAL-FEATURES\.md" pack-ops/HELP-FRAGMENT-PACK.md
5:`pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md`.
37:[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]
41:`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/BACKLOG.md`,
42:`pack-ops/CHANGELOG.md`.
```

Post-fix: 4 references on L5, 41, 42 all correctly use `pack-ops/`. L37 is
the documented deferral. No other moved-file references in the file.

---

## §6 Verification results

All 5 prompted verification steps executed; results below.

### §6.1 `python3 scripts/validate-pack.py`

```
============================================================
PASSED — all checks clean
```

All 35 checks PASS (Check 32/33/34 emit "not present (skipping)" per
the BD-168 forward-pointing pack-self per-entry-tree note — this is
the documented in-design behavior pre-BD-102 dog-food).

### §6.2 `bash scripts/tests/pack-help-test.sh`

```
=== Summary ===
Passed: 17
Failed: 0
All tests passed.
```

All 17 sub-tests pass:
- Group 1 (detect_pack_surface): 5/5
- Group 2 (pack-help.sh end-to-end): 12/12 including `2.1 colloquial
  mapping inlined` (the test whose failure surfaced the L37 sentinel-
  coupling discovery — now passes again after L37 revert).

### §6.3 Trinity grep: `grep -n "BD numbering" CLAUDE.md AGENTS.md GEMINI.md`

Adjusted from prompt's exact grep (which would miss CLAUDE/AGENTS's
"BD-NNN numbering:" header) to cover both header styles:

```
$ grep -n "BD-NNN numbering\|BD numbering" CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:73:**BD-NNN numbering:**
AGENTS.md:67:**BD-NNN numbering:**
GEMINI.md:47:**BD numbering:** Always read `pack-ops/BACKLOG.md` to find the highest existing BD
```

And the body content lines that follow:

```
CLAUDE.md:74:- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
AGENTS.md:68:- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
GEMINI.md:47:**BD numbering:** Always read `pack-ops/BACKLOG.md` to find the highest existing BD
```

All 3 trinity files reference `pack-ops/BACKLOG.md` consistently. PASS.

### §6.4 Link check: stale moved-file links in README + QUICKSTART

```
$ grep -nE "\[.*\.md.*\]\(.*\.md\)" README.md QUICKSTART.md | grep -iE "BACKLOG|CHANGELOG|PACK-CHAT|PACK-AGENTS|HELP-FRAGMENT-PACK|HELP-FRAGMENT-TRACKER|OPTIONAL-FEATURES"
QUICKSTART.md:10:> `/pack-help` — see [`pack-ops/HELP-FRAGMENT-PACK.md`](pack-ops/HELP-FRAGMENT-PACK.md).
QUICKSTART.md:43:[`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md).
README.md:45:can plug into. See [`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md) for the
```

All 3 matches now have `pack-ops/` prefix. No bare-root stale targets
remain. PASS.

### §6.5 `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt`

```
$ bash test-fixtures/build.sh --all --clean
... [6 fixtures rebuilt] ...
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff test-fixtures/manifest.txt
(empty)
```

ZERO diff. Confirms the 5 fixed files (CLAUDE.md, AGENTS.md, README.md,
QUICKSTART.md, pack-ops/HELP-FRAGMENT-PACK.md) are all NON-v11-surface
per RC9 (none under `project-template/` or `scripts/`). No manifest staging
needed in the upcoming commit. PASS.

---

## §7 Plan deviations

NONE within the user-authorized fix-all scope.

One reviewer-cited sub-line of D-4 (L37) is intentionally not fixed
in this commit due to the sentinel-coupling discovery documented in
§5.2 — that is not a plan deviation but a scope-boundary recognition:
the prompt scoped the fix to 5 named files; L37's full fix requires
editing a 6th file (`scripts/pack-help.sh`) which is out of scope.
The deferral is captured as a new OQ in §8 with a recommended
follow-on BD framing.

---

## §8 New OQs

### OQ-FIX-1 — `pack-ops/HELP-FRAGMENT-PACK.md:37` sentinel-prose mismatch

**Issue:** L37's text `[Included from \`HELP-FRAGMENT-TRACKER.md\` at pack
root via \`pack-help.sh\`.]` says "at pack root" but the file is now at
`pack-ops/HELP-FRAGMENT-TRACKER.md` (post-Commit-2). The L37 string is a
sentinel matched by `scripts/pack-help.sh:86` awk regex
`/^\[Included from \`HELP-FRAGMENT-TRACKER\.md\`/`; changing the prose
without coordinating the regex breaks tracker-fragment substitution in
`pack-help.sh` output (verified via test 2.1 colloquial-mapping FAIL).

**User-impact severity:** Effectively 0. The sentinel line is substituted
out at render time — users see the inlined tracker fragment content, never
the sentinel text itself. The misleading "at pack root" prose is invisible
in the user-facing `pack help` output.

**Recommended disposition:** Open a small follow-on BD post-fix that
coordinates a 2-file edit: (a) update L37 sentinel in
`pack-ops/HELP-FRAGMENT-PACK.md` to a path-accurate form (e.g.,
`[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via \`pack-help.sh\`.]`),
(b) update the awk regex in `scripts/pack-help.sh:86` to match the new
sentinel form, (c) re-run pack-help-test.sh to verify substitution still
fires, (d) regen manifest (the `scripts/pack-help.sh` edit is v11-surface
per RC9). This is a ~3-line, ~10-minute fix once correctly scoped; it
was out of scope for this Commit-2 fix-pass.

**Anchor:** Per pack-memory rule "Deferred work needs a tracked anchor"
(CLAUDE.md `## Pack memory` `### Workflow`), this OQ must land in a live
forward-pointing surface. Pack Chat to open the BD inline in BACKLOG at
the user's discretion (BD numbering: read live
`pack-ops/BACKLOG.md` to assign next BD-NNN per the now-trinity-symmetric
"BD numbering" rule).

---

## §9 PREFLIGHT line

PREFLIGHT: 5/5 in-scope file edits complete; verification PASS; HEAD
`59a7dbb5fe7878b151064e0c9cb33268ae4dcfb1`; about to Write IMPL-REPORT
to `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-2-FIX.md`.
