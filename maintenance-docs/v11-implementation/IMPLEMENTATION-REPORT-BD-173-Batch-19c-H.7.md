# IMPLEMENTATION-REPORT — BD-173 Batch 19c.7 (H.7)

**BD:** BD-173 (project-side cleanup Batch 19c)
**Commit slot:** H.7 — PM-CHAT.md per-project Claude memory cache convention (V2 §D.1 REVISED-WORDING)
**HEAD before edits:** `21a6ab713026917af93ad8883194e8736f7e65e8`
**Author:** pack-coder (Claude Code Opus 4.7)
**Date:** 2026-05-23
**Spec sources:**
- `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` §D.1
- `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` H.7

---

## §1 — Scope

**Task:** Land V2 §D.1 REVISED-WORDING — a NEW paragraph in
`project-template/docs/pack/PM-CHAT.md` documenting the per-project
Claude memory cache convention (Claude-only). REVISED-WORDING per V2
§D.1 + salvageability B3 + audit §3.2.1 drops the V1-draft cross-side
citation phrases ("Tier 1.5 design" and "pack memory pattern") and
describes the convention on its own merits.

**Files modified (in-scope):**
- `project-template/docs/pack/PM-CHAT.md` — 1 NEW paragraph (callout
  block) added in the `## Tool-specific: Claude Code CLI` section.

**Files modified (incidental — v11-surface manifest regen per RC9):**
- `test-fixtures/manifest.txt` — 3 v11-* fixture row SHAs updated.
  Left in working tree per pack-coder contract (no staging/commit);
  Pack Chat stages alongside the scope edits in the same commit per
  `feedback-manifest-regen-on-v11-surface`.

**Files created (this report):**
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.7.md`

**V1 CONDITIONAL H.7 — NOT touched (per V2 §D.7 disposition):**
V1's H.7 proposed a CONDITIONAL Claude-only `### Sub-agent behavior`
sub-section in `project-template/CLAUDE.md` (V1 D-1 Alt-2). V2 §D.7
RE-CONFIRMS V1's recommendation NO and DROPS the conditional —
OT-UT-1 content lands instead as a paragraph in METHODOLOGY.md Part 1
"Tool Roles" → "Claude Code CLI (agents)" sub-section (covered by
H.16, not H.7). This commit therefore does NOT modify
`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.

---

## §2 — Edits applied

### 2.1 V2 §D.1 REVISED-WORDING text (verbatim)

The V2 §D.1 proposed-text block (V2 §D.1 lines 620–636) reads:

```
> **Per-project Claude memory cache (Claude-only).** Claude Code
> projects may use per-project memory at
> `~/.claude/projects/<slug>/memory/` as a convenience pointer
> index to project rules. Treat the directory as pure pointers
> — short one-line bullets that cite anchors in
> `docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`, or the
> project trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at
> project root). No body text in the cache; trinity / PM-CHAT.md
> / METHODOLOGY.md remain authoritative. If a cache pointer
> disagrees with the authoritative source, the source wins.
> Codex CLI and Gemini CLI have no equivalent per-project memory
> mechanism; PM chat sessions running under those CLIs read
> trinity / PM-CHAT.md / METHODOLOGY.md directly each session.
```

This text was applied byte-identically (verbatim) to PM-CHAT.md.

### 2.2 Insertion anchor verification

**V2 spec (line 638):** `project-template/docs/pack/PM-CHAT.md`
"Tool-specific: Claude Code CLI" section — V1 cited around L552;
"coder confirms section heading at HEAD — may have shifted."

**PLAN H.7 spec (PLAN line 329):** "Insert as `>` callout block in
`## Tool-specific: Claude Code CLI` section (currently L552),
placement: after the existing 'Compaction handling' sub-section at
L592-595 and BEFORE the next `---` separator at L597."

**HEAD `21a6ab7` actual anchor positions (post H.2/H.3 line drift):**
- `## Tool-specific: Claude Code CLI` — line 679 (was L552; drifted
  +127 lines from V2 baseline due to H.1-H.6 additions to PM-CHAT.md).
- `### Compaction handling` — line 719.
- End of Compaction handling block ("...re-read state files from
  disk.") — line 722.
- `---` separator before `## Tool-specific: Claude Web Projects` —
  line 724.

**Insertion point applied:** Between line 722 (end of Compaction
handling paragraph) and line 724 (`---` separator). The new callout
block is added as the last sub-section content within `## Tool-
specific: Claude Code CLI` immediately before the section-closing
`---`. This matches the V2 §D.1 + PLAN H.7 placement contract:
inside the Claude Code CLI tool-specific section, after the
Compaction handling sub-section, before the `---` boundary.

### 2.3 BEFORE / AFTER

**BEFORE (PM-CHAT.md lines 719–726 at HEAD `21a6ab7`):**
```
### Compaction handling

Claude Code auto-compacts at 95% context capacity. After compaction, run
`/pm-startup` to re-read state files from disk.

---

## Tool-specific: Claude Web Projects
```

**AFTER (PM-CHAT.md lines 719–740 post-edit):**
```
### Compaction handling

Claude Code auto-compacts at 95% context capacity. After compaction, run
`/pm-startup` to re-read state files from disk.

> **Per-project Claude memory cache (Claude-only).** Claude Code
> projects may use per-project memory at
> `~/.claude/projects/<slug>/memory/` as a convenience pointer
> index to project rules. Treat the directory as pure pointers
> — short one-line bullets that cite anchors in
> `docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`, or the
> project trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at
> project root). No body text in the cache; trinity / PM-CHAT.md
> / METHODOLOGY.md remain authoritative. If a cache pointer
> disagrees with the authoritative source, the source wins.
> Codex CLI and Gemini CLI have no equivalent per-project memory
> mechanism; PM chat sessions running under those CLIs read
> trinity / PM-CHAT.md / METHODOLOGY.md directly each session.

---

## Tool-specific: Claude Web Projects
```

**Diff stat:** `+14 lines, 0 deletions` (14-line callout block plus
1 blank line above and 1 blank line below; net +14 lines because the
blank line before `---` already existed in BEFORE).

### 2.4 Cross-side citation drop verification

V2 §D.1 §"V2 wording cleanup per salvageability B3 + audit §3.2.1"
identifies the two V1-draft phrases that MUST be dropped:

| V1-draft phrase | Status in applied text |
|---|---|
| "Tier 1.5 design" | NOT PRESENT — confirmed by grep |
| "same Tier 1.5 design as the pack repo (per pack memory pattern)" | NOT PRESENT — confirmed by grep |

Neither phrase appears in the applied text. The applied text
describes the convention on its own project-side merits (Claude
Code per-project memory directory, pointer-only discipline,
authoritative source precedence on disagreement) without naming
pack-internal architecture (Tier 1.5, pack memory pattern,
pack-* agents, `pack-ops/`, `maintenance-docs/`).

---

## §3 — Verification

### 3.1 Commands run

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
git diff --stat project-template/docs/pack/PM-CHAT.md
git diff project-template/docs/pack/PM-CHAT.md | grep -E '^\+' | \
  grep -iE 'pack-ops|PACK-AGENTS|pack-coder|pack-reviewer|pack-architect|pack-planner|Tier 1\.5|pack memory pattern|maintenance-docs' \
  || echo "BOUNDARY OK — no pack-internal refs in additions"
grep -nE "Tier 1\.5|pack memory" project-template/docs/pack/PM-CHAT.md | grep -v "^\s*<!--" \
  || echo "PASS — no cross-side cite phrases present in PM-CHAT.md"
```

### 3.2 Results

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASS — all 42 checks clean** |
| `bash test-fixtures/build.sh --all --clean` | **PASS — manifest written; all 6 fixtures built deterministically (v10-base, v10-tracker-shape, v11-realistic-ot, v11-flat-file, v11-tracker-on, existing-project-mid-dev)** |
| `git diff --stat test-fixtures/manifest.txt` | **PASS — 3 rows changed (insertions=3, deletions=3); v11-* rows drifted as expected per RC9 (`project-template/` in v11-surface)** |
| `git diff --stat project-template/docs/pack/PM-CHAT.md` | **PASS — 14 insertions, 0 deletions; matches expected callout-block size** |
| Boundary grep (additions only) | **PASS — "BOUNDARY OK — no pack-internal refs in additions"** |
| PLAN H.7 verification grep (whole file) | **PASS — "PASS — no cross-side cite phrases present in PM-CHAT.md"** |

### 3.3 Detailed grep outputs

**Boundary grep (additions only):**
```
BOUNDARY OK — no pack-internal refs in additions
```
No matches against `pack-ops|PACK-AGENTS|pack-coder|pack-reviewer|
pack-architect|pack-planner|Tier 1\.5|pack memory pattern|
maintenance-docs` in added lines.

**PLAN H.7 verification grep (whole file, excluding HTML comments):**
```
PASS — no cross-side cite phrases present in PM-CHAT.md
```
No matches for "Tier 1.5" or "pack memory" anywhere in the file
(outside HTML comments, of which there are none containing these
phrases).

### 3.4 Manifest diff detail

`git diff --stat test-fixtures/manifest.txt`:
```
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

3 row SHAs updated (one each for the 3 v11-* fixtures:
v11-realistic-ot, v11-flat-file, v11-tracker-on). v10-* rows are
tag-pinned and unchanged. Manifest left in working tree per
pack-coder contract — Pack Chat stages alongside scope edits.

---

## §4 — Cross-references

### 4.1 V2 §D.1 (REVISED-WORDING source)

`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
§D.1 (lines 604–638):
- §D.1 establishes the V2 decision: YES land the per-project Claude
  memory cache convention paragraph in PM-CHAT.md, per V1 D.1 Alt-1
  (user-confirmed).
- §D.1 cleanup paragraph (lines 616–619) names the two V1-draft
  cross-side citations to drop per salvageability B3 + audit
  §3.2.1: "Tier 1.5 design" and "same Tier 1.5 design as the pack
  repo (per pack memory pattern)".
- §D.1 proposed text (lines 620–636) is the REVISED-WORDING that
  this commit applies verbatim.
- §D.1 insertion target (line 638) names PM-CHAT.md "Tool-specific:
  Claude Code CLI" section with the caveat that line numbers may
  have shifted from V1's L552 citation; this commit confirms the
  section anchor at HEAD line 679 (shifted +127 from V2 baseline).

### 4.2 PLAN H.7 (planner spec)

`maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` H.7
(lines 320–351):
- PLAN H.7 names the scope (§D.1 NEW paragraph), files modified
  (PM-CHAT.md only), edit specification (insert as `>` callout
  after Compaction handling, before next `---` separator),
  verification commands (run validate-pack.py + fixture build +
  manifest stat + grep `Tier 1\.5|pack memory`), RC9 manifest
  regen (REQUIRED), per-commit reviewer (SKIP per V2 §I —
  covered by H.9 sliding window), commit subject scope keyword
  (mixed, no keyword), commit message, and PREFLIGHT line shape.
- This implementation matches the PLAN H.7 contract on every line.

### 4.3 V2 §D.7 (V1 CONDITIONAL H.7 drop rationale)

`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
§D.7 (lines 870–953):
- §D.7 RE-CONFIRMS V1's recommendation NO on the question "should
  project-template trinity carry a `### Sub-agent behavior
  (Claude-only)` sub-section?" with strengthened post-BD-175
  rationale (Check 18 H2 within-trinity parity collision +
  project-side SSOT-first wording restrictiveness vs pack-side).
- §D.7.3 establishes that OT-UT-1 content (Agent Teams stage
  lifecycle + sub-agent backgrounding) lands instead as an
  informational paragraph in METHODOLOGY.md Part 1 "Tool Roles"
  → "Claude Code CLI (agents)" sub-section per V1 D-1 Alt-3
  reframed. This is covered by H.16, NOT H.7.
- Therefore this commit (H.7) does NOT modify
  `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`. The
  trinity surface remains untouched in H.7.

### 4.4 Salvageability B3 (cross-side cite drop authority)

`maintenance-docs/v11-implementation/ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`
§B3 (cross-side citation drop directive) — referenced from V2 §D.1
line 616: "V2 wording cleanup per salvageability B3 + audit
§3.2.1." The B3 directive establishes that V1's two phrases
("Tier 1.5 design" and "pack memory pattern") are pack-internal
terminology not present at client install, and therefore must not
appear in project-side surfaces. V2 §D.1's REVISED-WORDING is the
B3-compliant rewrite. This commit lands the B3-compliant text.

### 4.5 Audit §3.2.1 (leak confirmation)

`maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md`
§3.2.1 (confirmed leak) — referenced from V2 §D.1 line 616. The
audit identifies the V1-draft "Tier 1.5 design" phrase as a
confirmed cross-side leak (pack-internal architecture decision
referenced from project-side surface). V2 §D.1 REVISED-WORDING +
this commit close the leak.

---

## §5 — Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | PM-CHAT.md has a NEW paragraph in the "Tool-specific: Claude Code CLI" section per V2 §D.1 REVISED-WORDING | **PASS** — 14-line callout block inserted after Compaction handling, before `---` separator |
| 2 | Text is byte-identical to V2 §D.1 spec (verbatim) | **PASS** — direct copy from V2 §D.1 proposed-text block; diff confirms exact wording |
| 3 | NO cross-side citations introduced ("Tier 1.5 design", "pack memory pattern", pack-* references all absent) | **PASS** — boundary grep returns "BOUNDARY OK"; PLAN H.7 verification grep returns "PASS" |
| 4 | Other PM-CHAT.md content UNCHANGED (preserves H.2 + H.3 additions) | **PASS** — `git diff --stat` shows only 14 insertions, 0 deletions; no other lines touched |
| 5 | `python3 scripts/validate-pack.py` PASS | **PASS** — all 42 checks clean |
| 6 | Manifest v11-* row drift | **PASS** — 3 v11-* rows (v11-realistic-ot, v11-flat-file, v11-tracker-on) updated; manifest left in working tree |
| 7 | IMPL-REPORT at the specified path | **PASS** — `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.7.md` (this file) |

All 7 success criteria PASS.

---

## §6 — Out-of-scope confirmations

### 6.1 Only PM-CHAT.md touched

Confirmed via `git status` + `git diff --stat`:
- `project-template/docs/pack/PM-CHAT.md` — modified (+14 lines)
- `test-fixtures/manifest.txt` — modified (incidental RC9 regen;
  expected per pack-coder contract)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.7.md` — new (this report)

No other files modified.

### 6.2 Trinity NOT touched (V1 CONDITIONAL H.7 dropped per V2 §D.7)

`project-template/CLAUDE.md`, `project-template/AGENTS.md`,
`project-template/GEMINI.md` — all three NOT modified. V1's
CONDITIONAL H.7 (Claude-only `### Sub-agent behavior` sub-section
in `project-template/CLAUDE.md`) was DROPPED per V2 §D.7
disposition; the OT-UT-1 content lands in METHODOLOGY.md Part 1
via H.16 instead, not in trinity via H.7.

### 6.3 H.2 + H.3 additions preserved

H.2 + H.3 commits added content to PM-CHAT.md (causing the +127
line drift between V2 baseline L552 and HEAD L679 for the
"Tool-specific: Claude Code CLI" section heading). This commit's
diff shows only the 14-line additive callout block; no
deletions, no modifications to existing lines. H.2 + H.3
additions remain intact.

### 6.4 No cross-side cites introduced

Confirmed by two independent grep passes:
- Additions-only grep against expanded pack-internal pattern set
  (`pack-ops|PACK-AGENTS|pack-coder|pack-reviewer|pack-architect|
  pack-planner|Tier 1\.5|pack memory pattern|maintenance-docs`):
  no matches → "BOUNDARY OK".
- Whole-file grep for the two PLAN H.7-named phrases (`Tier 1\.5`
  / `pack memory`): no matches → "PASS — no cross-side cite
  phrases present in PM-CHAT.md".

### 6.5 No git state-changing operations performed

Per pack-coder contract + STOP-MEANS-STOP preamble obligations.
Only read-only git verbs used (`git status`, `git diff`,
`git rev-parse`). No `git add`, no `git commit`, no `git push`,
no `git mv`, no `git rm`, no `git reset`, no `git checkout --`.
Working tree changes are staged for Pack Chat to commit alongside
the scope edits.

### 6.6 No out-of-scope directories touched

Pack-root trinity, `pack-ops/`, `scripts/`, `supporting-docs/`,
`.claude/`, `.codex/`, `.gemini/`, `maintenance-docs/v11-research/`
— all UNTOUCHED. Only allowed targets touched: PM-CHAT.md (the
1 in-scope file), manifest.txt (incidental RC9 regen), this
IMPL-REPORT (the required new file).

---

## §7 — Open questions / deferrals

### 7.1 Anchor ambiguity

NONE. The PLAN H.7 spec named the insertion contract precisely
("after the existing 'Compaction handling' sub-section ... and
BEFORE the next `---` separator"), and the actual file state at
HEAD `21a6ab7` matches this contract structurally despite line-
number drift from V2 baseline (V2 cited L552 for the section
heading; HEAD has it at L679 due to H.1-H.6 PM-CHAT.md additions).
The structural anchor (Compaction handling → callout → `---` →
next H2 section) is unambiguous.

### 7.2 REVISED-WORDING discrepancy

NONE. The V2 §D.1 proposed-text block (lines 620–636) was applied
byte-identically. No editorial substitutions, no formatting
deviations, no whitespace normalization. The diff against
HEAD shows the exact V2 text inside the `> ... >` callout
prefix.

### 7.3 Deferrals

NONE. No work was deferred from this commit. The full H.7 scope
(per PLAN H.7 specification) is implemented.

### 7.4 New POQs / open questions surfaced

NONE. The implementation followed V2 §D.1 + PLAN H.7 exactly.
No new architect-pass material surfaced; no new BD candidates
identified.

### 7.5 Boundary discipline check (P-missed-7)

This edit touches a project-side surface (`project-template/docs/
pack/PM-CHAT.md`). Per the boundary-investigation pre-flight:

- **Project-side SSOT investigated:** `project-template/docs/pack/
  PM-CHAT.md` is the project-side PM-chat operating rules document
  (the project-side analog of pack-side `pack-ops/PACK-CHAT.md`).
  V2 §D.1 + PLAN H.7 prescribe this exact target.
- **REVISED-WORDING is project-side-safe:** the V2 REVISED-WORDING
  cites only project-side surfaces (`docs/pack/PM-CHAT.md`,
  `docs/pack/METHODOLOGY.md`, project trinity at project root). No
  pack-only files referenced. No pack-* agent names. No pack-only
  orchestrator role. No `pack-ops/`, no `maintenance-docs/`, no
  PACK-AGENTS.md, no PACK-CHAT.md.
- **Pack-only file references avoided:** the boundary grep
  confirms zero pack-internal references introduced in additions.
- **STOP per P-missed-7?** NO — this edit uses the project-side
  SSOT (`docs/pack/PM-CHAT.md`) and cites only project-side
  surfaces. No pack-only references introduced; no boundary-
  discipline stop required.

---

## §A — Files-changed inventory

| Path | Change type | Notes |
|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | modified | +14 lines (NEW callout block after Compaction handling) |
| `test-fixtures/manifest.txt` | modified | Incidental RC9 regen; 3 v11-* row SHAs updated; left in working tree for Pack Chat to stage |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.7.md` | new | This report |

**Final HEAD on worktree (pre-commit, as expected for pack-coder):**
`21a6ab713026917af93ad8883194e8736f7e65e8` (unchanged from start;
no commit performed per pack-coder contract).

---

## §B — Definition-of-Done checklist

| Item | Status |
|---|---|
| In-scope file edits complete (1/1) | PASS |
| validate-pack.py PASS | PASS (all 42 checks clean) |
| Fixture build SUCCESS | PASS (all 6 fixtures built; manifest written) |
| Manifest v11-* drift confirmed | PASS (3 rows updated) |
| Boundary discipline grep PASS | PASS (BOUNDARY OK) |
| PLAN H.7 verification grep PASS | PASS (no cross-side cite phrases) |
| V2 §D.1 text applied verbatim | PASS |
| No out-of-scope files touched | PASS |
| No git state-changing operations | PASS |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |
| IMPL-REPORT written at specified path | PASS (this file) |

**All Definition-of-Done items PASS. H.7 ready for Pack Chat commit.**
