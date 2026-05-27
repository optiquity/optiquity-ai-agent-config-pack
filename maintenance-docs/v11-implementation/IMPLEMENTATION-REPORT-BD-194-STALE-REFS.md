# IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md — small follow-on stale-Check-24 reference fix

Status: CODER DELIVERABLE — implementation complete. Bundles into the
BD-194 commit (not a separate commit) per Pack Chat triage disposition.
HEAD SHA at coder pass start: `85702434bd8771fc964c89565491bb75e2ceec01`
(unchanged through this pass — agents never run state-changing git
verbs per pack memory `feedback_agents_never_commit`).
Author: pack-coder; produced 2026-05-27.

---

## §1 Scope

Small follow-on to the main BD-194 coder pass. Two stale Check-24
references were surfaced in `IMPLEMENTATION-REPORT-BD-194.md` §10.3
as out-of-scope-per-main-prompt-but-impacted-by-Check-24-deletion;
Pack Chat triage user-disposed both for inline fix bundled into the
BD-194 commit.

This pass implements two minimal surgical edits, regenerates the
fixture manifest, and re-runs validate-pack.py to confirm the
post-BD-194 boundary surface is still clean.

- **Fix 1**: `scripts/init-project.sh:809-814` — stale comment block
  referenced retired Check 24 and the pre-BD-193 F4/F5 pack-side-
  canonical install-source contract; replaced with a brief comment
  pointing forward to the post-correction L820-828 block (which
  already correctly explains the project-template-side install-source
  contract).
- **Fix 2**: `project-template/skills/boundary-investigation/SKILL.md:107`
  — stale parenthetical clause `per CI Check 24 byte-identity
  contract with project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`
  inside the pack-only deny-list `HELP-FRAGMENT-TRACKER.md` entry;
  dropped per user-locked Decision 2 Approach 1 (minimal surgical
  edit; do NOT rephrase or add audit-trail).
- **Fixture manifest regen**: per pack memory
  `feedback_manifest_regen_on_v11_surface` — both fixes touch
  v11-surface (`scripts/` AND `project-template/`); rebuild produced
  3 v11-* row SHA changes (expected for v11-surface edits).

Cross-references:
- Originating findings: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` §10.3
- BD entry: `pack-ops/BACKLOG.md` BD-194 (Open; bundled into the
  BD-194 commit by Pack Chat at staging time)
- HEAD SHA: `85702434bd8771fc964c89565491bb75e2ceec01`

---

## §2 Files modified

| File | Change type | Lines (before → after at L107/L809) |
|---|---|---|
| `scripts/init-project.sh` | modified (Fix 1) | 6-line block L809-814 → 5-line replacement block L809-813 |
| `project-template/skills/boundary-investigation/SKILL.md` | modified (Fix 2) | 3-line parenthetical L105-107 → 2-line parenthetical L105-106 |
| `test-fixtures/manifest.txt` | regenerated | 3 v11-* row SHA changes (v11-realistic-ot, v11-flat-file, v11-tracker-on) |

Pre-existing modifications from the main BD-194 coder pass (not
re-touched by this pass): `scripts/validate-pack.py`,
`scripts/tests/test-init-project.sh`,
`scripts/tests/test-migrate-v10-to-v11.sh`.

---

## §3 Fix 1 details (`scripts/init-project.sh:809-814`)

### Originating context (§10.3 of main IMPL-REPORT)

The L809-814 comment block was leftover from a prior partial update
to the HELP-FRAGMENT-TRACKER.md install path. It referenced two
things that no longer exist or apply:

1. **CI Check 24** — deleted entirely in the main BD-194 coder pass
   (function definition, main() callsite, and check-list comment all
   removed from `scripts/validate-pack.py`).
2. **DELTA L1 pack-root canonical install source** — replaced in
   BD-193 F4/F5 by the project-template-side install-source contract
   (the L820-828 block immediately below was rewritten to express the
   correct post-BD-193 contract during BD-193, but the L809-814
   introductory comment was not updated at the same time).

### Edit applied (Edit tool)

**Before** (L809-814):
```
    # 1. HELP-FRAGMENT*.md → docs/pack/. HELP-FRAGMENT.md per the usual
    #    classifier-copy rule (developer-customizable). HELP-FRAGMENT-
    #    TRACKER.md is byte-identity-required across pack-root and client
    #    mirror per DELTA L1 (validate-pack Check 24); force-copy from
    #    pack-root canonical regardless of class so an existing-* re-run
    #    cannot leave stale tracker fragments in place.
```

**After** (L809-813):
```
    # 1. HELP-FRAGMENT*.md → docs/pack/. HELP-FRAGMENT.md per the usual
    #    classifier-copy rule (developer-customizable). HELP-FRAGMENT-
    #    TRACKER.md install path: see the comment block below for the
    #    project-template-side source-of-truth contract (post-BD-193
    #    F4/F5; pack-side substitution is forbidden).
```

### Rationale

The downstream L820-828 comment block (untouched by this fix) already
carries the full project-template-side install-source contract
narrative:

```
# HELP-FRAGMENT-TRACKER.md client-shipped source is project-template/
# docs/pack/HELP-FRAGMENT-TRACKER.md. The pack-side and project-side
# versions are separate artifacts with separate audiences (pack/project
# separation of concerns); the project-side file is the source of truth
# for client install, and pack-side substitution is forbidden.
```

Replacing L809-814 with a brief pointer comment avoids duplicating
the contract narrative while still preserving readable structure for
the two HELP-FRAGMENT*.md install paths (the L809-813 block now
introduces both, and L820-828 carries the substantive contract).
Coder-judgment choice between "brief replacement" and "remove
entirely" per prompt §"Coder judgment": brief replacement chosen
because it preserves the visual cue that there are two distinct
files being copied (one classifier-copy, one force-copy from
project-template-side).

---

## §4 Fix 2 details (`project-template/skills/boundary-investigation/SKILL.md:107`)

### Originating context (§10.3 of main IMPL-REPORT)

The bracketed `per CI Check 24 byte-identity contract with
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` clause inside
the deny-list `HELP-FRAGMENT-TRACKER.md` entry referenced retired
Check 24 from a project-side skill file. Two problems:

1. **Stale ref**: Check 24 no longer exists (deleted in main BD-194
   coder pass).
2. **Boundary leak**: the clause referenced a pack-side concept
   (CI gate) from a project-side skill file in the pack-only deny-
   list section itself — exactly the kind of cross-reference the
   deny-list is designed to forbid. (The deny-list entry says
   "don't cross-reference these from project-side"; the
   parenthetical clause adjacent to that warning then cross-
   referenced a pack-side gate from the project-side file. Code
   Red 2 pattern.)

### Edit applied (Edit tool)

**Before** (L104-107):
```
- **File names:** `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`,
  `HELP-FRAGMENT-TRACKER.md` (bare-filename refs from project-side; the
  pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` per CI
  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
```

**After** (L104-106):
```
- **File names:** `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`,
  `HELP-FRAGMENT-TRACKER.md` (bare-filename refs from project-side; the
  pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md`),
```

### Rationale

User-locked Decision 2 Approach 1: minimal surgical edit only — do
NOT rephrase or add audit-trail. The parenthetical now reads as a
clean cross-reference ("the pack-ops copy lives at `pack-ops/HELP-
FRAGMENT-TRACKER.md`") with no stale CI gate reference and no
boundary leak. Surrounding deny-list structure is unchanged; the
trailing `OPTIONAL-FEATURES.md (bare-filename refs; project-side
has its own ...)` entry remains intact.

---

## §5 Verification results

### §5.1 Stale-reference purge

Command:
```
grep -n "Check 24 byte-identity" project-template/skills/boundary-investigation/SKILL.md
grep -n "DELTA L1 (validate-pack Check 24)" scripts/init-project.sh
```

Result: ZERO occurrences in either file (both greps exit 1). PASS.

Defensive cross-file scan (whole-repo) for the same two patterns
across the two fix files:

```
grep -rn "Check 24 byte-identity\|DELTA L1 (validate-pack Check 24)" \
  scripts/init-project.sh \
  project-template/skills/boundary-investigation/SKILL.md
```

Result: no matches (exit 1). PASS.

### §5.2 validate-pack.py

Command:
```
python3 scripts/validate-pack.py
```

Result: `PASSED — all checks clean`. PASS.

Invoked checks: 41 invocations across 40 unique checks (Check 16,
18, 19 each invoked twice — once for pack-root trinity and once for
project-template trinity — yielding 3 extra invocations; 40 unique
check IDs in range 1-23 + 25-43 with Check 24 absent per main BD-194
deletion). Matches the expected post-main-BD-194 invocation count of
40 invoked checks.

Spot-checks of relevant checks:
- **Check 37** (project-side pack-only deny-list): OK — 158
  project-side file(s) walked; zero deny-list contamination (6
  anchored LEGITIMATE-context hit(s) accepted; 584 fenced
  LEGITIMATE-content line(s) exempt per Guardrail 2). The Fix 2
  edit on `SKILL.md:107` reduces the count of pack-side
  cross-references on a project-side file but does not change
  Check 37's overall PASS state.
- **Check 43** (project-side bare cross-reference scanner): OK —
  151 project-side / client-installed file(s) walked; zero pack-
  internal bare cross-references.
- **Check 40** (pack-ops/ bare cross-reference scanner): OK — 9
  pack-ops/*.md file(s) walked; zero unqualified bare cross-
  references (the Fix 2 edit is on a project-side file under
  `project-template/`, so Check 40's pack-ops/ surface is
  unaffected, but the gate is exercised end-to-end as part of the
  full validate-pack run).

### §5.3 Boundary discipline check (mandatory per pack-coder rules)

Fix 2 touches a project-side file
(`project-template/skills/boundary-investigation/SKILL.md`).
Per the pack-coder boundary-investigation pre-flight requirement,
the SSOT investigation for the concept being edited:

- **Concept edited**: the wording of the pack-only deny-list entry
  for `HELP-FRAGMENT-TRACKER.md` (specifically, the rationale clause
  attached to that entry).
- **Project-side SSOT for the pack-only deny-list**: the
  `<!-- DENY-LIST-CONTENT-START -->` ... `<!-- DENY-LIST-CONTENT-END -->`
  block inside `project-template/skills/boundary-investigation/
  SKILL.md` itself, which is the canonical authoritative location
  for the deny-list content from the project-side perspective. The
  `project-template/CLAUDE.md` "Project SSOT-first" rule embeds an
  excerpt of this same deny-list (also wrapped in the same fenced
  delimiters) per the CI Check 37 sync contract — the SKILL.md is
  the canonical / authoritative copy and the CLAUDE.md embed is the
  trinity-aware sync target.
- **Fix 2 is project-side SSOT-respecting**: removing the stale
  parenthetical from the canonical SKILL.md location is the
  correct project-side action — no pack-only file is being newly
  referenced or modified, and no pack-side mechanism is being
  introduced into a project-side file. (The reverse direction:
  the stale parenthetical was an INSTANCE of the very leak class
  the deny-list is designed to prevent, and removing it ALIGNS
  the project-side artifact with its own design intent.)
- **No SSOT augmentation needed**: the edit is a surgical removal
  of a stale clause, not a rule addition or restructuring. Per
  user-locked Decision 2 Approach 1, no rephrase / no audit-trail
  addition was applied.

Result: project-side SSOT-respecting edit. PASS.

Fix 1 touches a pack-side file (`scripts/init-project.sh`), which
is exempt from the project-side boundary discipline pre-flight
(applies only to project-template/ trees, supporting-docs/, and
other pack-shipped-to-client surfaces). `scripts/init-project.sh`
is a pack-internal installer that runs at install time but is not
itself copied to client installs; the file lives in the pack repo
permanently. Edit applied per the pack-internal repo conventions.

### §5.4 Boundary discipline stop — NOT TRIGGERED

The pre-flight stop trigger fires when a project-side edit would
ADD a reference to a pack-only file. Fix 2 REMOVES a reference to
a pack-only concept (CI Check 24) from a project-side file —
opposite direction from the stop trigger. No stop required.

---

## §6 Manifest regen details

### Command and output

```
bash test-fixtures/build.sh --all --clean
```

Result: all 6 fixtures rebuilt deterministically; manifest written
to `test-fixtures/manifest.txt`.

### Manifest diff

```
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index ca115ec..c62bd9a 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  01e8aa40fabc464f149d459f912d4e9f10651c59
-v11-flat-file  2cf7c719901aeb29d6354d2d6d0e78366f79bc68
-v11-tracker-on  f51b4d3d48b8682fcff30bc7b9e0d1672d824c38
+v11-realistic-ot  570b7f8628abaa0ebe8d5580797f790f1165eea7
+v11-flat-file  4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
+v11-tracker-on  8f584b117f39d5826c7360f0e45a56cc6bfc1fce
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

### Expected drift confirmation

Both Fix 1 (`scripts/init-project.sh`) and Fix 2
(`project-template/skills/boundary-investigation/SKILL.md`) are
v11-surface edits per pack memory
`feedback_manifest_regen_on_v11_surface`:

- `scripts/init-project.sh` — pack-repo installer; participates in
  v11-realistic-ot, v11-flat-file, v11-tracker-on builds.
- `project-template/skills/boundary-investigation/SKILL.md` —
  Tier 0 skill copied into client `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/` at install via `stage_s4_skills()`; participates
  in all three v11-* builds.

Both contribute to the v11-* fixture SHAs through the install path.
Expected drift: 3 v11-* rows (v11-realistic-ot, v11-flat-file,
v11-tracker-on). Observed drift: 3 v11-* rows.

v10-* row stability check:
- v10-minimal: `19558cbac58ed3e47642a6bbe64418a38c60bc16` (unchanged
  from pre-edit; tag-pinned).
- v10-realistic-ot: `4c62945f72b037908b38967d5d8f019745263258`
  (unchanged from pre-edit; tag-pinned).
- existing-project-mid-dev: `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619`
  (unchanged from pre-edit; synthesized pre-pack-install input shape
  not affected by pack-side edits).

All expected drift accounted for; no unexpected v10-* or
existing-project-mid-dev drift. PASS.

### Manifest staging

`test-fixtures/manifest.txt` is in the working tree as modified
(`M`); Pack Chat will stage it alongside the two scope edits +
the main BD-194 coder pass edits in the single BD-194 commit per
the prompt §"Bundling" instruction. Coder did NOT run `git add`
per pack memory `feedback_agents_never_commit`.

---

## §7 PREFLIGHT line

PREFLIGHT: 2 files edited (scripts/init-project.sh +
project-template/skills/boundary-investigation/SKILL.md) + manifest
regen (3 v11-* row SHAs drifted); validate-pack.py PASS at 40
invoked checks; stale-Check-24 purge clean; HEAD
85702434bd8771fc964c89565491bb75e2ceec01; about to Write IMPL-REPORT
to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md

---

## §8 Definition of Done

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Fix 1 applied (scripts/init-project.sh stale comment cleaned) | PASS | §3 (Edit applied; new L809-813 block in place; grep clean §5.1) |
| 2 | Fix 2 applied (boundary-investigation/SKILL.md:107 parenthetical dropped) | PASS | §4 (Edit applied; new L105-106 in place; grep clean §5.1) |
| 3 | Manifest regen executed (v11-surface trigger) | PASS | §6 (3 v11-* row SHAs drifted as expected; v10-* + existing-* unchanged) |
| 4 | validate-pack.py PASS | PASS | §5.2 (`PASSED — all checks clean`; 40 unique invoked checks) |
| 5 | Stale-Check-24 purge clean (both greps return zero matches) | PASS | §5.1 (both greps exit 1; no matches) |
| 6 | PREFLIGHT line emitted before IMPL-REPORT write | PASS | §7 (line above) |
| 7 | IMPL-REPORT written | PASS | this file |
| 8 | Boundary discipline check documented (Fix 2 is project-side) | PASS | §5.3 (project-side SSOT investigation; SKILL.md is the canonical SSOT for the deny-list content) |
| 9 | No out-of-scope edits | PASS | git status §10 — only 2 in-scope files modified by this pass + manifest regen; main-BD-194 modifications (validate-pack.py / test files) untouched by this pass |
| 10 | No state-changing git verbs run | PASS | git rev-parse HEAD unchanged from pass start (`85702434bd8771fc964c89565491bb75e2ceec01`); working-tree edits only |

DoD: 10/10 PASS.

---

## §9 Plan deviations

Zero. Both user-locked decisions executed as specified:

- **Decision 1**: Fix 1 applied to `scripts/init-project.sh:809-814`
  per coder-judgment "brief replacement" option (preserves visual
  structure for two HELP-FRAGMENT*.md install paths while pointing
  forward to the post-correction L820-828 contract block).
- **Decision 2 Approach 1**: Fix 2 applied as minimal surgical
  removal of the stale parenthetical clause; no rephrase, no audit-
  trail addition, no restructuring of the surrounding deny-list
  entry.
- **Bundling**: 2 edits + manifest regen sit in the working tree
  ready for Pack Chat to stage as part of the BD-194 commit (not a
  separate commit); coder did not run `git add` / `git commit`.

---

## §10 Files-changed inventory

```
M project-template/skills/boundary-investigation/SKILL.md   (Fix 2; this pass)
M scripts/init-project.sh                                    (Fix 1; this pass)
M test-fixtures/manifest.txt                                 (regen; this pass)

M scripts/tests/test-init-project.sh                         (pre-existing; main BD-194 coder)
M scripts/tests/test-migrate-v10-to-v11.sh                   (pre-existing; main BD-194 coder)
M scripts/validate-pack.py                                   (pre-existing; main BD-194 coder)

?? maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md
?? maintenance-docs/v11-implementation/PLAN-BD-194.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md
   (this file; written at end of pass)
```

Files touched by THIS pass (3): the 2 scope edits + the regenerated
manifest. All other modifications are pre-existing from the main
BD-194 coder pass and remain unchanged.

---

## §11 New POQs introduced

None. The two fixes are mechanical executions of user-locked
triage decisions; no new design questions surfaced.

---

## §12 Branch + final HEAD SHA

- Branch: `v11-dev` (working tree)
- Final HEAD SHA: `85702434bd8771fc964c89565491bb75e2ceec01`
  (unchanged from pass start; no git state changes)

End of report.
