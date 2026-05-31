# IMPLEMENTATION-REPORT — BD-193 Phase 5

**Pipeline stage:** Phase 5 of 5 (remediation of Phase 4 audit findings)
**Date:** 2026-05-27
**HEAD (start):** `50bca8542674236fe8c035c21b9d3e9a3d0a69f4`
**Branch:** `v11-dev`
**Phase 4 source-of-truth:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`
**Phase 3 anchor:** committed at `85196d4` (immutable; not modified in
this phase)

---

## §1 — Scope

This is the Phase 5 remediation commit closing the BD-193 Code Red 2
pack/project boundary cleanup family. Phase 4 (pack-reviewer) audited
the Phase 3 implementation and surfaced 10 distinct fix locations
across 5 MUST findings, 2 SHOULD findings (3rd deferred to BD-194),
2 NIT findings, and 1 AMBIGUOUS finding (user-locked Reading A —
REMOVE, applying to 2 schema files). All findings are user-disposed
per the Phase 4 report; this phase is mechanical application.

**3-rule triage stack (continued from Phase 3):**
- Rule 1 — `feedback_bd_pack_only_operational_rule`: client-facing
  content must not operationally treat BDs.
- Rule 2 — `feedback_pack_project_separation_of_concerns`: pack-side
  and project-side files are SEPARATE artifacts with SEPARATE
  audiences.
- Rule 3 — `feedback_client_facing_token_economy`: client-facing
  docs default REMOVE pack-only references unless client-necessary.

**Out-of-scope (deferred to BD-194 architect-led work):**
- `scripts/validate-pack.py` Check 24 / `check_help_fragment_tracker()`
  (SHOULD-3, deferred per user disposition during Phase 4 triage).

---

## §2 — Files modified

Inventory by finding class. Total: 14 source files + 1 manifest = 15
files modified in the working tree.

| # | Path | Finding class | Change summary |
|---|---|---|---|
| 1 | `project-template/docs/pack/OPTIONAL-FEATURES.md` | M-1 | 3 lines: BD-volume → work-item/TD volume |
| 2 | `project-template/skills/review/SKILL.md` | M-2 | 4 lines: sibling BD → sibling TD (project-side only; pack-root preserves "sibling BD") |
| 3 | `project-template/skills/pm-startup/SKILL.md` | M-3 | 1 line: "later BD" → "future pack version" (SoT) |
| 4 | `project-template/.claude/skills/pm-startup/SKILL.md` | M-3 | Mirror of #3 |
| 5 | `project-template/.codex/skills/pm-startup/SKILL.md` | M-3 | Mirror of #3 |
| 6 | `project-template/.gemini/commands/pm-startup.toml` | M-3 | Mirror of #3 (Gemini surface) |
| 7 | `project-template/.codex/config.toml.example` | M-4 | 1 line: "future BD" → "future pack version" |
| 8 | `supporting-docs/MIGRATION-v10-to-v11.md` | M-5 | 4 lines: file-a-BD/BD-volume → file inbound issue / TD volume |
| 9 | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | S-1 | Forms-file paragraph rewritten as forward-looking framing |
| 10 | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | S-2 | Updated v11.0 form description with D16 carve-out |
| 11 | `maintenance-docs/v11-research/templates-archive/README.md` | N-1 | "BD" → "BD (pack-internal)" disambiguation |
| 12 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md` | N-2 | §14 "Check 41" → `check_issue_template_forms()` |
| 13 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | A-1 | Drop "BD/TD entries or to" from parent constraint |
| 14 | `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | A-2 | Drop "BD/TD entries or to" from parent constraint |
| 15 | `test-fixtures/manifest.txt` | (verification side-effect) | 3 v11-* fixture SHAs regenerated per v11-surface change |

**Notes on the .codex/config.toml family:** Only the `.example` file
contains the L17 target text at HEAD. `project-template/.codex/config.toml`
does NOT contain the target line; M-4 modified the single applicable
file. No mirror-parity expectation between `.example` and `config.toml`
(they serve different roles — example is the install-time template,
`config.toml` is intentionally minimal).

---

## §3 — MUST applications

### M-1 — `project-template/docs/pack/OPTIONAL-FEATURES.md`

| Line | BEFORE | AFTER |
|---|---|---|
| L120 | `your project (open BD count, BACKLOG size, 30-day growth) and offers` | `your project (open work-item count, BACKLOG size, 30-day growth) and offers` |
| L123 | `**When it matters** — when your project's BD volume reaches the point` | `**When it matters** — when your project's work-item volume reaches the point` |
| L158 | `**When to skip** — if your BD volume is under ~50 open and` | `**When to skip** — if your TD/work-item volume is under ~50 open and` |

Rationale: client-facing optional-features doc; BD is pack-internal
terminology and adds no value to clients (Rule 3).

### M-2 — `project-template/skills/review/SKILL.md`

PROJECT-SIDE mirror only; pack-root `.claude/skills/review/SKILL.md`
preserved at "sibling BD" per separation-of-concerns (Rule 2). Both
files have distinct audiences: pack-root governs pack-internal reviews
(where BD is real); project-template governs client reviews (where
clients use TD).

| Line | BEFORE | AFTER |
|---|---|---|
| L32 | `defer to later phase / later BD / later batch` | `defer to later phase / later TD / later batch` |
| L35 | `a sibling BD's implementation` | `a sibling TD's implementation` |
| L36 | `another sibling BD/commit` | `another sibling TD or commit` |
| L50 | `which sibling BD` | `which sibling TD` |

### M-3 — pm-startup skill (1 line × 4 mirrors)

All 4 mirrors received identical edit (Source-of-Truth + 3 mirror
files). The `stage_s4_skills()` install-time mass-copy means all 4
must carry the same text post-edit; mirror parity verified.

| BEFORE (in all 4 files) | AFTER (in all 4 files) |
|---|---|
| `lands here in a later BD when tracker mode is wired into pm-startup` | `lands here in a future pack version when tracker mode is wired into pm-startup` |

Files:
1. `project-template/skills/pm-startup/SKILL.md` (source-of-truth)
2. `project-template/.claude/skills/pm-startup/SKILL.md` (CLI mirror)
3. `project-template/.codex/skills/pm-startup/SKILL.md` (CLI mirror)
4. `project-template/.gemini/commands/pm-startup.toml` (Gemini surface)

### M-4 — `.codex/config.toml` family

Only the `.toml.example` file had the target text at HEAD;
`config.toml` did not. M-4 applied to the single file:

| Line | BEFORE | AFTER |
|---|---|---|
| L17 | `# stability is research OQ-1 (defer to future BD if needed).` | `# stability is research OQ-1 (defer to a future pack version if needed).` |

### M-5 — `supporting-docs/MIGRATION-v10-to-v11.md`

| Lines | BEFORE | AFTER |
|---|---|---|
| L597-599 | `that's a defect — please file a BD against the customize-preserve library with the .pack-migrate-v10-to-v11/dispositions.tsv row attached.` | `that's a defect — please file an inbound issue (pack-feedback-friction or pack-feedback-prompt) against the pack with the .pack-migrate-v10-to-v11/dispositions.tsv row attached.` |
| L712 | `2. File a BD with the disposition row + the file's pre-migration content.` | `2. File an inbound issue with the disposition row + the file's pre-migration content.` |
| L714 | `4. Wait for the BD to land before re-attempting.` | `4. Wait for the pack-side fix to land before re-attempting.` |
| L727 | `2. **Decide on Phase B.** If your project's BD volume is moderate` | `2. **Decide on Phase B.** If your project's TD/work-item volume is moderate` |

Rationale: client-facing migration doc shipped as a pre-install
reference and to clients. Clients cannot "file a BD" because BD is
pack-internal grammar (Rule 1); the correct channel is the inbound
form's `pack-feedback-friction` / `pack-feedback-prompt` subcategories.

---

## §4 — SHOULD applications

### S-1 — `templates-archive/v11.1/INDEX.md` L53-61

> **CORRECTION (2026-05-31, BD-195 S1 — SUPERSEDED).** This S-1 rewrite
> deepened the v11.1-archive-cut framing ("the v11.1 forms/ subdirectory
> will be populated when the v11.1 archive cut is completed"). Per
> BD-195 S1 there is no v11.1 archive cut — it was a mis-versioning
> contamination. Phase-parts are v11.0 scope; v11.0 is UNRELEASED and
> never frozen. The `templates-archive/v11.1/INDEX.md` this S-1 edited
> is RETIRED in BD-195 S1, and the phase-part row + 4-option form now
> live under `templates-archive/v11.0/`. This S-1 entry is preserved as
> historical record with the correction note in place; the AFTER text
> below is superseded.

The original paragraph asserted the v11.1 forms/ subdirectory has been
populated and is byte-identical to live pack-root and project-template
forms. Post-BD-193 the live forms are NO LONGER byte-identical
(pack-root admits `bd`, project does not), and the v11.1 archive cut
has not been completed.

**BEFORE (paragraph at L53-61):**
```
## v11.1 form file

The v11.1 form file at
`maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
is byte-identical to the live form
(`.github/ISSUE_TEMPLATE/work-item.yml` at pack root, mirrored
byte-identically to
`project-template/.github/ISSUE_TEMPLATE/work-item.yml`). The archive
form is CREATED in v11.1.
```

**AFTER:**
```
**Forms file** — Not yet created. The v11.1 forms/ subdirectory will be
populated when the v11.1 archive cut is completed (architect-pass
decision pending). When populated, the snapshot must reflect the
post-BD-193 pack/project divergence: pack-root admits the `bd` wi-type
option for filing pack-development backlog items; project-template
does NOT, since clients use TD entries. The two forms are SEPARATE
artifacts with SEPARATE audiences per the pack/project
separation-of-concerns principle.
```

### S-2 — `templates-archive/v11.0/INDEX.md` L30-32

| BEFORE | AFTER |
|---|---|
| `- [forms/work-item.yml](forms/work-item.yml) — composite form for BD, TD, phase-epic-skeleton, phase-task-skeleton (4-option wi-type dropdown per V3.3 §6.1).` | `- [forms/work-item.yml](forms/work-item.yml) — composite form for TD, phase-epic-skeleton, phase-task-skeleton (3-option wi-type dropdown per V3.3 §6.1 + BD-193 D16 carve-out). The original v11.0 shipped form admitted a 4th bd option; D16 removed it from the archive as a bug-fix carve-out.` |

The "3-option dropdown" reflects the BD-193 D16 carve-out: the
project-side archive form has `bd` removed; the v11.0 archive is now
accurate to the project surface, not the pre-D16 shipped form.

### NOT IN SCOPE — SHOULD-3 (Check 24)

Per user disposition: `scripts/validate-pack.py` Check 24 /
`check_help_fragment_tracker()` was NOT modified in this commit. It
is queued for BD-194 architect-led work.

---

## §5 — NIT applications

### N-1 — `templates-archive/README.md` L46

| BEFORE | AFTER |
|---|---|
| `  type per minor: BD, TD, phase-epic, phase-task, inbound at v11.0.` | `  type per minor: BD (pack-internal), TD, phase-epic, phase-task, inbound at v11.0.` |

Reader-clarity disambiguation: marks BD as the pack-internal entry
type so the archive README is unambiguous about the entry-type-by-
audience asymmetry.

### N-2 — `IMPLEMENTATION-REPORT-BD-193.md` §14

§14 L609 mis-labeled `check_issue_template_forms()` as "Check 41". The
actual Check 41 is `check_client_installed_files_self_doc()`. Corrected
to use the function name + printed label.

| BEFORE | AFTER |
|---|---|
| `1. **scripts/validate-pack.py** — Check 41 (issue-template-forms verifier) was hard-coded to expect identical wi-type options on` | `1. **scripts/validate-pack.py** — check_issue_template_forms() (printed label "Check: Issue template forms (BD-063)") was hard-coded to expect identical wi-type options on` |

Scope: §14 only (per prompt). L409 in §11 references "Check 41" for
the actual Check 41 (`_CLIENT_INSTALLED_FILES`) — correct labeling,
not modified.

The commit message of `85196d4` (which contains the §14 text) is
immutable and was NOT modified per prompt direction.

---

## §6 — AMBIGUOUS resolution applications

User-locked Reading A (REMOVE): the BD/TD mention on parent-constraint
sentences in phase-task/phase-part SCHEMAs adds noise rather than
tightening the constraint. Clients don't know what BD is; the positive
constraint ("parent is exactly one phase epic") is what matters.

### A-1 — `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:103`

| BEFORE | AFTER |
|---|---|
| `Phase tasks may not be parented to BD/TD entries or to other phase tasks — a phase task's parent is exactly one phase epic.` | `Phase tasks may not be parented to other phase tasks — a phase task's parent is exactly one phase epic.` |

### A-2 — `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md:170`

The file's actual text was "a Part's parent" (capitalized Part), not
"a phase part's parent" as shown in the prompt's BEFORE column. Per
the prompt's instruction "preserve the rest of the sentence," only the
BD/TD-mention clause was dropped; the existing "a Part's parent"
phrasing was preserved.

| BEFORE | AFTER |
|---|---|
| `Phase parts may not be parented to BD/TD entries or to phase tasks — a Part's parent is exactly one phase epic.` | `Phase parts may not be parented to phase tasks — a Part's parent is exactly one phase epic.` |

---

## §7 — Out-of-scope confirmation

The following were NOT modified per prompt direction:

| Item | Status |
|---|---|
| `scripts/validate-pack.py` Check 24 / `check_help_fragment_tracker()` | NOT modified (BD-194 work) |
| BD-185 H.1 NIT-2 / NIT-3 cosmetic fixes | NOT modified (pending Code Red 2 close) |
| Pack memory files (`~/.claude/projects/...`) | NOT modified |
| `pack-ops/BACKLOG.md` | NOT modified |
| Pack-side review skill at pack-root (`.claude/skills/review/SKILL.md`) | NOT modified (preserves "sibling BD") |
| ARCHITECTURE-BD-185 / PLAN-BD-185 | NOT modified |
| Commit message of `85196d4` | NOT modified (immutable; already landed) |
| §11 L409 "Check 41" reference (correct labeling for actual Check 41) | NOT modified (prompt scoped N-2 to §14 only) |

Pack-side review skill preservation verified:

```
$ grep "sibling BD" .claude/skills/review/SKILL.md
defer to later phase / later BD / later batch
a sibling BD's implementation
another sibling BD/commit
which sibling BD
```

Three "sibling BD" references at pack-root preserved as designed.

---

## §8 — Verification results

### §8.1 — validate-pack.py: PASS (43/43)

```
$ python3 scripts/validate-pack.py
[... all 43 checks ...]
============================================================
PASSED — all checks clean
```

All 43 checks PASS, including:
- Check 43 (V11 leak-sweep / pack-internal bare cross-reference
  scanner): PASS — 151 project-side files walked; zero pack-internal
  bare cross-references.
- Check 37 (Project-side pack-only deny-list): PASS — 158
  project-side files walked; zero deny-list contamination.
- Check 24 (HELP-FRAGMENT-TRACKER.md byte-identity): PASS at HEAD
  (not modified in this phase per prompt).
- Check 36 (Commit-scope honesty): PASS — 1 scope-claiming commit
  verified clean.

### §8.2 — Manifest regeneration

Ran `bash test-fixtures/build.sh --all --clean`. Manifest diff
non-empty (expected, given v11-surface edits):

```
$ git diff test-fixtures/manifest.txt
- v11-realistic-ot  f0bacc6c08be16bd59351648383d53b70800b24f
- v11-flat-file  cf19a42aa67f309b47e4aecef2d993225e4b76ee
- v11-tracker-on  092ec81e7917eb978b7992ed4fd413e02c8fef39
+ v11-realistic-ot  01e8aa40fabc464f149d459f912d4e9f10651c59
+ v11-flat-file  2cf7c719901aeb29d6354d2d6d0e78366f79bc68
+ v11-tracker-on  f51b4d3d48b8682fcff30bc7b9e0d1672d824c38
```

All 3 v11-* fixture SHAs drifted (project-template + supporting-docs
edits propagated through `stage_s4_skills()` + S6 + S11 mass-copies).
v10-* SHAs unchanged (tag-pinned). `existing-project-mid-dev` SHA
unchanged (no pack files). Per
`feedback_manifest_regen_on_v11_surface`, the manifest is staged in
the working tree for inclusion in the Phase 5 commit.

### §8.3 — Per-file grep verification

Ran `grep -nE "BD-\\b|sibling BD|file a BD|BD volume|future BD|later
BD"` across all 8 client-facing modified files:

- `OPTIONAL-FEATURES.md`: 0 hits (clean)
- `review/SKILL.md` (project-side): 0 hits (clean)
- All 4 pm-startup mirrors: 0 hits (clean)
- `.codex/config.toml.example`: 0 hits (clean)
- `MIGRATION-v10-to-v11.md`: 14 hits — ALL LEGITIMATE Class A
  migration cites: `BD-042` (×2), `BD-085` (×1), `BD-088` (×6),
  `BD-101` (×2), `BD-104` (×1), `BD-121` (×1). These are pack-history
  references describing migration mechanism provenance, NOT BD-as-
  active-grammar at client install.

Templates-archive files (under `maintenance-docs/`, pack-internal):
- All BD references in archive INDEX.md / SCHEMA.md files are within
  the Boundary-Layer-B "pack-internal under `maintenance-docs/`"
  surface (allowed to reference BDs).

### §8.4 — pm-startup mirror parity

```
$ diff <(grep -A1 -B1 "future pack version" project-template/skills/pm-startup/SKILL.md) \
       <(grep -A1 -B1 "future pack version" project-template/.claude/skills/pm-startup/SKILL.md)
(no output)
$ diff ... .codex/skills/pm-startup/SKILL.md
(no output)
$ diff ... .gemini/commands/pm-startup.toml
(no output)
ALL 4 MIRRORS PARITY OK
```

All 4 pm-startup mirrors have byte-identical text in the relevant
window.

---

## §9 — PREFLIGHT line emitted

The following line was emitted to the parent session before the
IMPL-REPORT Write:

```
PREFLIGHT: 14 files edited (5 MUST + 2 SHOULD + 2 NIT + 2
AMBIGUOUS-resolution; M-3 spans 4 mirrors); manifest regenerated;
validate-pack.py PASS (43/43); pm-startup mirror parity verified;
HEAD 50bca8542674236fe8c035c21b9d3e9a3d0a69f4; about to Write
IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-
REPORT-BD-193-PHASE-5.md
```

---

## §10 — Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | All 5 MUST fixes applied (M-1 through M-5) | PASS |
| 2 | Both SHOULD fixes applied (S-1, S-2); Check 24 NOT touched | PASS |
| 3 | Both NIT fixes applied (N-1, N-2) | PASS |
| 4 | Both AMBIGUOUS resolution fixes applied (A-1, A-2) | PASS |
| 5 | pm-startup mirror parity preserved across all 4 files | PASS |
| 6 | `.codex/config.toml` family parity (only .example has line; n/a) | PASS |
| 7 | Pack-side review skill at pack-root NOT modified | PASS |
| 8 | Manifest regenerated; staged in working tree | PASS |
| 9 | validate-pack.py PASS (43/43; Check 24 still PASSes at HEAD) | PASS |
| 10 | PREFLIGHT line emitted before IMPL-REPORT write | PASS |
| 11 | IMPL-REPORT written; no state-changing git verbs invoked | PASS |

---

## §11 — Plan deviations

**Zero structural plan deviations.**

Minor textual notes (no structural impact):

1. **M-4 single-file application.** Only
   `project-template/.codex/config.toml.example` contained the L17
   target at HEAD; `project-template/.codex/config.toml` did not.
   M-4 applied to the single applicable file. Prompt anticipated this
   ("grep both for the L17 line; apply to whichever has it").

2. **A-2 BEFORE-text variance from prompt.** The prompt's BEFORE
   column showed `a phase part's parent` but the file's actual text
   was `a Part's parent`. Per prompt instruction "preserve the rest
   of the sentence," only the BD/TD-mention clause was dropped; the
   existing "Part's parent" phrasing was preserved. The post-edit
   sentence retains the file's original capitalization style.

3. **N-2 scope confinement.** §14 L609 ("Check 41 (issue-template-
   forms verifier)") was corrected per N-2. §11 L409 also contains
   "Check 41" but as a CORRECT label for the actual Check 41
   (`_CLIENT_INSTALLED_FILES` self-doc list integrity). Prompt scoped
   N-2 to §14; L409 was NOT modified.

---

## §12 — New POQs introduced

**None.**

The Phase 4 audit findings were all user-disposed via the prompt's
explicit fix details. No new design decisions were made during this
mechanical remediation; all triage was already locked.

---

## §13 — Files changed inventory

**Modified (15):**

```
M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md
M maintenance-docs/v11-research/templates-archive/README.md
M maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md
M maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md
M maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
M maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md
M project-template/.claude/skills/pm-startup/SKILL.md
M project-template/.codex/config.toml.example
M project-template/.codex/skills/pm-startup/SKILL.md
M project-template/.gemini/commands/pm-startup.toml
M project-template/docs/pack/OPTIONAL-FEATURES.md
M project-template/skills/pm-startup/SKILL.md
M project-template/skills/review/SKILL.md
M supporting-docs/MIGRATION-v10-to-v11.md
M test-fixtures/manifest.txt
```

**New (none in this phase; PACK-REVIEW-BD-193-PHASE-4.md was created
by Phase 4 reviewer at HEAD and is untracked at start of Phase 5):**

```
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md  (Phase 4 input)
```

This IMPL-REPORT itself will be the second new file (created by this
phase):

```
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md
```

**Deleted:** None.

---

## §14 — Boundary discipline check

Per `feedback_pack_project_separation_of_concerns` (Pack memory
P-missed-7), the project-side files edited in this phase were each
checked against the project-side SSOT framing before applying the
edit:

| Project-side file | Project-side SSOT framing | Edit honors framing? |
|---|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | Client-facing optional-features doc; BD is pack-only grammar (Rule 1). | YES — generalized to work-item/TD volume |
| `project-template/skills/review/SKILL.md` | Project-side review skill; clients use TD per `project-template/CLAUDE.md`. | YES — sibling BD → sibling TD on project mirror only; pack-root preserved |
| `project-template/skills/pm-startup/SKILL.md` + 3 mirrors | Client-facing PM-startup skill; future feature must use pack-version framing not BD framing. | YES — "later BD" → "future pack version" |
| `project-template/.codex/config.toml.example` | Client-installed config example; pack-version framing required. | YES — "future BD" → "future pack version" |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Client-facing pre-install migration ref; clients use inbound issues for feedback. | YES — file-a-BD → file inbound issue; BD-volume → TD-volume |

**No pack-only reference acquisition.** No edit introduced a reference
to a pack-only file or surface in any project-side file.

---

## §15 — Final HEAD SHA at report write

HEAD at start of Phase 5 implementation: `50bca8542674236fe8c035c21b9d3e9a3d0a69f4`

(No commits made by this agent per `feedback_agents_never_commit`;
Pack Chat stages and commits the working-tree edits after review.)

---

**End of IMPLEMENTATION-REPORT-BD-193-PHASE-5.**
