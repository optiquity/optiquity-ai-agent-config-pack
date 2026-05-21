# IMPLEMENTATION-REPORT — BD-179 FIX-4 (NIT-1)

**Branch:** v11-dev
**Pre-fix HEAD:** `13feef31ab0aa2e8cd9a25f21fe6a81f70f5acea`
**Date:** 2026-05-20
**Scope:** PACK-REVIEW-BD-179.md §3.4 NIT-1 — correct §2 architect-doc row
diff stat from inaccurate `+93 / -0 (additive only)` to actual
`+89 / -4 (additive sections + in-place revisions)`.
**File touched (single):**
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md`

## §1 Problem restatement (from PACK-REVIEW-BD-179.md §3.4 NIT-1)

The IMPLEMENTATION-REPORT-BD-179.md §2 Files Changed table contains a
row for `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md`
that records the diff stat as `+93 / -0 (Phase-2 addenda only, all
additive)`. The actual `git diff` of commit `13feef3` against parent
`ac500b7` shows `+89 / -4` on that file — a mix of additive prose and
in-place revisions to existing prose, not an additive-only delta. The
review flagged the cell as inaccurate on two axes: (a) the +/- counts
are wrong (89 vs 93; -4 vs -0), and (b) the qualifier "(additive only)"
misrepresents the diff shape.

## §2 Evidence — `git diff ac500b7..13feef3 -- maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md --stat`

```
 .../v11-implementation/ARCHITECTURE-BD-179.md | 93 ++++++++++++++++++++++++--
 1 file changed, 89 insertions(+), 4 deletions(-)
```

Numstat confirmation (`git diff ac500b7..13feef3 --numstat -- maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md`):

```
89	4	maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md
```

The `93` in the `--stat` shortbar (`93 ++++...`) is the total touched
line count (89 + 4 = 93); the canonical insertions/deletions split is
89 / 4. The actual diff contains both additive blocks (new §5.1
addendum paragraph, new OQ-S2/OQ-S3/HELP-FRAGMENT.md allowlist entries,
new `does not exist` + `archived` anchor-phrase entries, new §8.6 /
§8.7 sections, new §10.2 BOUNDARY mapping addendum and table rows) AND
in-place revisions to existing prose (§5.1 "Decision" sentence
rewritten to add `scripts/tests/fixtures/` to the EXCLUDE list; §6.4
`post-install` inline comment block rewritten to add the Phase 1 survey
confirmation; §6.4 `post-install` bullet appended with the Phase 1
confirmation sentence).

## §3 Before/after of §2 architect-doc row

### Before

```
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` | modified | +93 / -0 (Phase-2 addenda only, all additive) | OQ-S resolution landings: §5.1 EXCLUDE addendum (OQ-S1); §6.2 OQ-S2 + OQ-S3 + HELP-FRAGMENT.md allowlist additions; §6.4 OQ-S4 anchor phrases (`does not exist`, `archived`) + rationale paragraphs; §6.6 self-documenting allowlist comment block (Q-B); §8.4 main()-call-site comment alignment; §8.6 OQ-S4 final resolution + Edit 4 record; §8.7 OQ-S resolution summary table; §10.2 BOUNDARY mapping addendum for OQ-S8. |
```

### After

```
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` | modified | +89 / -4 (Phase-2 addenda: additive sections + in-place revisions to existing §5.1 "Decision" prose, the §6.4 `post-install` anchor-comment block, and the §6.4 `post-install` bullet) | OQ-S resolution landings: §5.1 EXCLUDE addendum (OQ-S1) — in-place revision of the §5.1 "Decision" sentence to add `scripts/tests/fixtures/` to the EXCLUDE list plus an additive addendum paragraph; §6.2 OQ-S2 + OQ-S3 + HELP-FRAGMENT.md allowlist additions (additive block inside the `_CHECK_40_ALLOWLIST` code sample); §6.4 OQ-S4 anchor phrases (`does not exist`, `archived`) — in-place revision of the `post-install` inline comment lines plus additive `does not exist` / `archived` entries; in-place revision of the §6.4 `post-install` bullet appending the Phase 1 survey confirmation sentence plus two additive bullets for the new OQ-S4 anchors; §6.6 self-documenting allowlist comment block (Q-B); §8.4 main()-call-site comment alignment; §8.6 OQ-S4 final resolution + Edit 4 record (additive section); §8.7 OQ-S resolution summary table (additive section); §10.2 BOUNDARY mapping addendum for OQ-S8 (additive paragraph + additive table rows). |
```

### Substantive changes

- `+93 / -0` → `+89 / -4` (matches `git diff --numstat` ground truth).
- `(Phase-2 addenda only, all additive)` → `(Phase-2 addenda: additive
  sections + in-place revisions to existing §5.1 "Decision" prose, the
  §6.4 `post-install` anchor-comment block, and the §6.4 `post-install`
  bullet)` — names the three specific in-place-revision sites that
  account for the `-4` deletions.
- The per-OQ purpose breakdown is augmented to flag which sub-changes
  are additive vs in-place. (Example: §5.1 is "in-place revision of
  the 'Decision' sentence ... plus an additive addendum paragraph";
  §6.4 anchor phrases are "in-place revision of the `post-install`
  inline comment lines plus additive `does not exist` / `archived`
  entries".) Other rows are explicitly tagged "additive section" or
  "additive paragraph" so the reader can reconcile the delta breakdown.

## §4 Verification — visual diff confirms only §2 architect-doc row changed

`git diff --stat` of the IMPL-REPORT-BD-179.md edit:

```
 maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

`git diff` (single-line replacement):

- Old line at row index 147 of the §2 Files Changed table (the
  architect-doc row): removed.
- New line at row index 147 (the corrected architect-doc row):
  inserted.

No other row in §2 changed (scripts/validate-pack.py, BOUNDARY-DEFINITION.md,
MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md, CONCEPTUAL-REVIEW-METHODOLOGY.md,
HELP-FRAGMENT-PACK.md, test harness, fixture directory). No other section
of the IMPL-REPORT changed (§1, §3 through §11 untouched). Header
metadata (HEAD SHA, branch, date) untouched.

## §5 RC9 manifest status

The single file modified
(`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md`)
lives under `maintenance-docs/v11-implementation/`. The RC9 trigger glob
is `project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`.
`maintenance-docs/` is NOT in the RC9 trigger glob; no fixture rebuild
required; no manifest regen needed for this FIX-4 commit.

## §6 Definition-of-Done

| Item | Status |
|---|---|
| §2 architect-doc row reflects actual `git diff --stat` output (89 / 4) | PASS |
| "(additive only)" qualifier replaced with accurate "additive sections + in-place revisions" phrasing | PASS |
| No other content in the IMPL-REPORT touched | PASS — `git diff --stat` shows 1 line changed in IMPL-REPORT-BD-179.md, 1 insertion + 1 deletion |
| FIX-4 IMPL-REPORT documents before/after and `git diff --stat` evidence | PASS (§2 + §3 above) |
| No state-changing git verbs run | PASS — only `git rev-parse HEAD`, `git status --short`, `git diff --stat`, `git diff --shortstat`, `git diff --numstat`, `git diff` (all read-only) |

## §7 PREFLIGHT line

```
PREFLIGHT: 1/1 in-scope file edits complete (IMPLEMENTATION-REPORT-BD-179.md §2 architect-doc row); verification PASS (git diff --stat shows 1 file / 1 insertion / 1 deletion; only the §2 architect-doc row touched); HEAD 13feef31ab0aa2e8cd9a25f21fe6a81f70f5acea; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-4.md
```
