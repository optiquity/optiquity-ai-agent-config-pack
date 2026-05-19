# IMPLEMENTATION-REPORT — BD-175 Commit 10 (TASK-T8 OPTIONAL-FEATURES SPLIT)

**Branch:** v11-dev
**HEAD at start:** `00d777245db690f2c1212d4581cb92d062d6a613`
**HEAD at PREFLIGHT:** `00d777245db690f2c1212d4581cb92d062d6a613` (no commits made)
**Coder:** pack-coder
**Date:** 2026-05-19
**Plan reference:** `PLAN-BD-175-PHASE-5.md` §2.10
**Architecture references:** `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §6.1 TASK-T8; `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §13 (§13.1 – §13.6)

---

## §1 Summary

This commit implements TASK-T8 — the SPLIT of `OPTIONAL-FEATURES.md`
into independently-curated pack-side (`pack-ops/OPTIONAL-FEATURES.md`,
already in place since Commit 2) and project-side (NEW
`project-template/docs/pack/OPTIONAL-FEATURES.md`) files per Override 8
("One for pack. One for projects. There may be something common to both
and maybe some individual to both."). The project-side file is 188
lines (target was ~150-180; see §8 judgment call), structured per the
§13.3 9-row content-split table, written entirely in project-user
voice. Pack-tracker plumbing details (validate-pack Check 22, STREAMS
constant, per-entry-tree contract) are explicitly absent per §13.5
TYPE-2 contamination avoidance contract. The `MERGE-STRATEGY.md`
reference uses the "in the pack repo" qualifier per the Architect C
prevention contract.

The supporting edits comprise: (a) `scripts/init-project.sh` adds the
new file to the `--update` mapping list (fresh-install path already
covered by the S6 `*.md` glob — no S6 edit needed); (b)
`supporting-docs/DEPENDENCIES.md:162` D8.7 ref-update from bare
`OPTIONAL-FEATURES.md` to `docs/pack/OPTIONAL-FEATURES.md`; (c)
`test-fixtures/manifest.txt` regenerated per RC9 (all 3 v11-* fixture
rows drifted as expected, v10-* tag-pinned rows unchanged). A4-A8 (5
project-side references across 4 files) are now LEGITIMATE post-SPLIT
— grep-verified, no edits applied.

---

## §2 Files changed

| Path | Action | Line delta | Rationale |
|---|---|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | NEW | +188 | §13.3 / §6.1 TASK-T8 — project-side SPLIT target tailored per audience |
| `scripts/init-project.sh` | MODIFIED | +1 | `--update` mapping needs explicit OPTIONAL-FEATURES.md entry (fresh install auto-covered by S6 `*.md` glob) |
| `supporting-docs/DEPENDENCIES.md` | MODIFIED | ±1 (in-place token edit, no net) | D8.7 ref-update: `OPTIONAL-FEATURES.md` → `docs/pack/OPTIONAL-FEATURES.md` |
| `test-fixtures/manifest.txt` | MODIFIED | ±3 (3 v11-* SHA rows changed) | RC9 — project-template/ + scripts/ touched → v11-* fixture SHAs drift |

Total: 1 new file + 3 modified = 4 files (matches §2.10.2 expectation).

---

## §3 §13.3 row decisions (9 rows)

Per §13.3 9-row content-split table, applied row-by-row to project-side
file:

| # | Row (section) | Decision | One-sentence rationale |
|---|---|---|---|
| 1 | Intro paragraphs (no heading; lines 1-15) | **ADAPT** | Reframed to project-PM voice ("your project can opt into per-CLI features without abandoning cross-CLI parity") per §13.2 project-PM audience analysis. |
| 2 | `## Claude Code — Agent Teams` | **ADAPT** | Replaced pack-internal agent-path references with project-side paths (`.claude/agents/coder.md`, `.claude/agents/reviewer.md`, `.claude/agents/tester.md`); reframed "How to use pack agents as teammates" → "How to use your project's agents as teammates" per §13.3. |
| 3 | `## Codex CLI — Optional features` | **KEEP placeholder** | Verbatim per §13.3 (common-to-both forward-pointing stub). |
| 4 | `## Gemini CLI — Optional features` | **KEEP placeholder** | Verbatim per §13.3 (common-to-both forward-pointing stub). |
| 5 | `## Tracker integration (v11)` — pack surface (pack-repo CWD, pack-side example, pack-side signals) | **DROP** | Removed pack-repo CWD references; removed `tracker.toml.pack-example` (pack-side example dropped per §13.3 row); pack-side recommendation signals not mentioned — §13.3 pack-surface row says DROP from project-side. |
| 6 | `## Tracker integration (v11)` — project surface (client-repo CWD, client `tracker.toml.example`, project-side signals, client-side failure modes) | **KEEP FULL** | "From your project repo root", `tracker.toml.example` installed by `init-project.sh`, project-side signals (open BD count in your project, BACKLOG size, 30-day growth) per §13.3 project-surface row. |
| 7 | `customization-detected-needs-reconciliation` reference | **KEEP qualified** | "See `MERGE-STRATEGY.md` in the pack repo" — applies the "in the pack repo" qualifier per §13.3 reference row + Architect C TYPE-4 guardrail. |
| 8 | Pack-tracker plumbing details (validate-pack Check 22, STREAMS, per-entry-tree contract) | **OMIT** | Zero mentions in project-side file (grep-verified §9 result 4); §13.3 plumbing row + §13.5 anti-contamination contract explicitly forbid copying these. |
| 9 | `## Adding new entries` | **KEEP-OR-ADAPT** | Adapted to project-side framing emphasizing project's role ("If your project adopts a CLI-specific opt-in feature the pack does not yet document, add a section here..."); same shape contract (Status / What / When / Enable / Use / Caveats / Skip) preserved per §13.3 row. |

---

## §4 init-project.sh install-stage path

**Path taken:** S6 fresh-install path uses the existing `*.md` glob
at lines 544-552 — **no S6 edit needed**. The `--update` mapping at
lines 1108-1132 is an explicit per-file list — **explicit entry added**
at line 1125.

**Grep evidence (S6 fresh-install glob — auto-covers):**

```
scripts/init-project.sh:539:    local pack_docs="$PACK/project-template/docs/pack"
scripts/init-project.sh:544:    for f in "$pack_docs"/*.md; do
```

The `*.md` glob iterates every `.md` file in `project-template/docs/pack/`
and copies via `cp` (or `existing_classifier_copy` for the `existing-*`
class). The new `OPTIONAL-FEATURES.md` file lands in the directory and
is auto-picked-up by this glob on fresh install. Precedent: HELP-FRAGMENT.md
+ HELP-FRAGMENT-TRACKER.md + PACK-FEEDBACK.md + PLATFORM-SKILLS.md +
PM-CHAT.md all live in this directory and are installed via the same
glob, with no per-file special-casing in S6.

**Grep evidence (--update mapping — explicit entry added):**

```
scripts/init-project.sh:1119:        "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"
scripts/init-project.sh:1120:        "project-template/docs/pack/PLATFORM-SKILLS.md:docs/pack/PLATFORM-SKILLS.md:generic"
scripts/init-project.sh:1121:        "project-template/docs/pack/PACK-FEEDBACK.md:docs/pack/PACK-FEEDBACK.md:generic"
scripts/init-project.sh:1122:        "project-template/docs/pack/PROMPT-TEMPLATES.md:docs/pack/PROMPT-TEMPLATES.md:generic"
scripts/init-project.sh:1123:        "project-template/docs/pack/HELP-FRAGMENT.md:docs/pack/HELP-FRAGMENT.md:generic"
scripts/init-project.sh:1124:        "project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic"
scripts/init-project.sh:1125:        "project-template/docs/pack/OPTIONAL-FEATURES.md:docs/pack/OPTIONAL-FEATURES.md:generic"
```

The `--update` path iterates this explicit array (lines 1108-1132) and
calls `customization_preserve` for each entry — so without the new line
at 1125, `init-project.sh --update` on existing pack-configured projects
would silently fail to refresh `docs/pack/OPTIONAL-FEATURES.md`. The
`generic` class matches the precedent for the sibling docs at 1120-1124
(HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md, PACK-FEEDBACK.md,
PLATFORM-SKILLS.md).

**Why both paths matter:** Fresh installs use S6's glob (zero edit
needed); `--update` against existing projects uses the explicit
mapping. §2.10.2 says "scripts/init-project.sh — add install stage:
copy ... during init" and §2.10.3 says "if loop already covers `*.md`,
no special-casing needed" — the fresh-install loop IS already covered;
the `--update` map IS NOT and needs the new entry. Both paths covered.

---

## §5 D8.7 ref-update (supporting-docs/DEPENDENCIES.md:162)

**BEFORE (line 162):**
```
See `OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
```

**AFTER (line 162):**
```
See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
```

**Verification grep:**
```
$ grep -n "OPTIONAL-FEATURES" supporting-docs/DEPENDENCIES.md
162:See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
```

Exactly one OPTIONAL-FEATURES reference in DEPENDENCIES.md, and it now
reads `docs/pack/OPTIONAL-FEATURES.md` (the path that resolves at
client repos after init-project.sh installs the new file). Per
ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §3.5 D8.7 implementation hint:
"REPLACE the bare `OPTIONAL-FEATURES.md` reference with
`docs/pack/OPTIONAL-FEATURES.md` (the path that resolves at client
repos once SPLIT lands)." Done.

---

## §6 A4-A8 verify-only confirmations

Per §2.10.2 and §6.1 TASK-T8, 5 project-side references become
LEGITIMATE post-SPLIT with no edits required. Grep results:

| Ref ID | File | Line | Reference text | LEGITIMATE post-SPLIT |
|---|---|---|---|---|
| A4 | `project-template/.gemini/commands/pack-help.toml` | 11 | `docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md.` | YES — resolves to `<client>/docs/pack/OPTIONAL-FEATURES.md` post-install |
| A5 | `project-template/.claude/skills/pack-help/SKILL.md` | 14 | `` `docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`. `` | YES — same |
| A6 | `project-template/.codex/skills/pack-help/SKILL.md` | 14 | `` `docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`. `` | YES — same |
| A7 | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 49 | `` ...and `OPTIONAL-FEATURES.md` for full setup. `` | YES — bare filename resolves relative to file's directory `docs/pack/` |
| A8a | `project-template/docs/pack/HELP-FRAGMENT.md` | 5 | `` `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`. `` | YES — same |
| A8b | `project-template/docs/pack/HELP-FRAGMENT.md` | 31 | `` `docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`, `` | YES — same |

Note: plan text §2.10.2 refers to "5 references"; the inventory above
shows 6 hits because A8 contains 2 hits in the same file (front-matter
+ See-also section per Commit 11's §2.11.2 description). Both sites
are addressed by the SPLIT and need no edit — they all resolve to the
newly-created project-side file via the client install path
`<client>/docs/pack/OPTIONAL-FEATURES.md`. Total unique reference
locations: 5 files (A4 + A5 + A6 + A7 + A8 — counting HELP-FRAGMENT.md
as one file with 2 hits = 5 files, 6 hits — consistent with §2.10.2's
"5 project-side files" phrasing).

Line numbers drifted from the plan text (which referenced `:12`,
`:15`, `:15`, `:49`, `:6`, `:33`) — current line numbers are 11, 14,
14, 49, 5, 31. The drift is the cumulative effect of Commit 11's
QUICKSTART-ref removal (lands BEFORE Commit 10 in the parallel
ALPHA-EXPANDED set per §8.2.1). The references themselves are
preserved exactly — only the line numbers shifted because text above
them was deleted.

---

## §7 Manifest regen evidence

```
$ bash test-fixtures/build.sh --all --clean
[builds all 6 fixtures deterministically; output snipped]
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

$ git diff test-fixtures/manifest.txt
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index 837d59b..143e672 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  d409ff7f8fb256db1948da1f35e65c832ba6637b
-v11-flat-file  e522d9b424a2db43aaa01e2148372f2b9c62a62b
-v11-tracker-on  fe4c1d5bdf7167b30636a05ad0c376424a65c684
+v11-realistic-ot  07bebb297174b5c4e4fac523fb0aa0b05249358a
+v11-flat-file  ac200c28852f5fac70f37a7541b2b538d8d18bc2
+v11-tracker-on  2d9811a5415c76ba865ca793a2e4cc5ee53ae6f0
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Expected pattern: 3 v11-* fixture rows drifted (v11-realistic-ot,
v11-flat-file, v11-tracker-on); v10-* rows tag-pinned and unchanged;
existing-project-mid-dev unchanged (synthesized pre-install shape,
unaffected by project-template/ changes). Result matches expectation.

---

## §8 Judgment calls

### §8.1 — Line count overshoot (188 vs target 150-180)

**Issue:** The project-side file landed at 188 lines, 8 lines above
the §13.3 / §2.10 stated target of "~150-180 lines (shorter; plumbing
details omitted)".

**Decision:** Accept the 188-line landing as the judgment-call
ceiling.

**Rationale (per §13.3 + §13.2 + the §2.10 "approximate" qualifier):**

1. **The Agent Teams section is intrinsically content-rich.** It needs
   to convey: what Agent Teams is, when it matters for project work,
   the env-var enable mechanism (with the JSON snippet), how to use
   project agents as teammates (with the invocation example), 5
   distinct caveats (Claude-Code-only, Experimental, Higher token
   cost, Teams config location, Permissions-at-spawn), and 3 when-to-
   skip cases. All of these are actionable content for the project-PM
   audience per §13.2.

2. **Aggressive trimming was applied where it preserved fidelity.**
   Initial draft was 235 lines (effectively pack-side parity);
   tightening passes reduced "When this matters" paragraph spans,
   consolidated the "How to use your project's agents as teammates"
   prose, removed the `[graph] cycle_check_k` paragraph (plumbing
   detail per §13.5), tightened the disable section into a single
   paragraph, and consolidated the "Adding new entries" prose. Each
   pass brought line count down by ~5-20 lines; further passes hit
   diminishing returns where the next trim would compromise actionable
   content.

3. **The target is explicitly "approximate".** §13.3 says "Approximate
   length: ~150-180 lines"; §2.10 says "~150-180 lines per B-fix
   §13.3 content-split sketch". 188 lines is 4.4% over the upper
   bound — well within the "approximate" tolerance and significantly
   shorter than the pack-side file (235 lines post-Commit-2).

4. **Plumbing-detail-omitted criterion IS met.** Zero hits for
   STREAMS, Check 22, validate-pack, tracker.toml.pack-example, or
   pack-repo CWD references in the project-side file. The
   contamination-avoidance contract per §13.5 is satisfied
   independently of the line-count target.

**Heuristic citation:** §13.3 audience-tailoring principle + §13.5
TYPE-2 contamination avoidance contract. The 188 vs 180 gap is bounded
content density, not contamination spillage.

### §8.2 — `--update` mapping required edit (vs §2.10.3 "likely yes" guidance)

**Issue:** §2.10.3 says "verify existing install-loop already handles
`project-template/docs/pack/*.md` files (likely yes — INSTALL-PROCEDURES.md
and PM-CHAT.md are installed via this loop). If yes, no script edit
needed (just confirm via grep + dry-run). If not, add explicit install
line." The §2.10.2 entry says "MODIFIED: `scripts/init-project.sh`".

The grep result reveals a two-path reality: S6 fresh-install uses the
`*.md` glob (auto-covers), but `--update` (lines 1108-1132) uses an
explicit per-file mapping that does NOT auto-cover.

**Decision:** Apply the explicit `--update` mapping edit at line 1125;
do NOT edit S6 (already covered).

**Rationale:**

1. §2.10.3 says "if loop already covers `*.md`, no special-casing
   needed" — true for the S6 fresh-install loop. §2.10.3 also
   contemplates "if not, add explicit install line" — true for the
   `--update` mapping list which IS the "explicit install line"
   pattern for the `--update` path.

2. The `--update` mapping precedent at lines 1120-1124 shows
   PLATFORM-SKILLS.md, PACK-FEEDBACK.md, PROMPT-TEMPLATES.md,
   HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md all have explicit
   entries. OPTIONAL-FEATURES.md follows the same `generic` class
   pattern. Without the entry, `init-project.sh --update` on
   existing pack-configured projects silently fails to refresh the
   new file — a regression vs the precedent.

3. The §2.10.2 line "MODIFIED: scripts/init-project.sh — add install
   stage: copy `project-template/docs/pack/OPTIONAL-FEATURES.md` →
   `<client>/docs/pack/OPTIONAL-FEATURES.md` during init" is honored
   by the explicit `--update` map entry (the fresh-install path was
   already honored by the existing S6 glob; no additional edit
   needed there).

**Heuristic citation:** §13.4 step 3 "Existing install-stage
scaffolding (e.g., the loop in `init-project.sh` that copies all
`project-template/docs/pack/*.md` files) likely already handles this
— Phase 5 coder verifies no special-casing needed." Verified S6 path
covered; identified `--update` path needed explicit entry — both paths
ultimately covered.

---

## §9 Verification output

### Command 1 — File existence + line count

```
$ ls -la project-template/docs/pack/OPTIONAL-FEATURES.md
-rw-r--r--@ 1 david  staff  7872 May 19 14:40 project-template/docs/pack/OPTIONAL-FEATURES.md
$ wc -l project-template/docs/pack/OPTIONAL-FEATURES.md
     188 project-template/docs/pack/OPTIONAL-FEATURES.md
```

PASS — file exists, 188 lines (judgment-call landing per §8.1).

### Command 2 — init-project.sh install stage

```
$ grep -n "OPTIONAL-FEATURES\|docs/pack/\*\.md\|project-template/docs/pack" scripts/init-project.sh
539:    local pack_docs="$PACK/project-template/docs/pack"
562:    # Source path is `$PACK/supporting-docs/METHODOLOGY.md`; the docs/pack/*.md loop
563:    # above iterates `$PACK/project-template/docs/pack/`, which does not contain
816:    if [[ -f "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" ]]; then
817:        "$copy_fn" "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" \
1119:        "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"
1120:        "project-template/docs/pack/PLATFORM-SKILLS.md:docs/pack/PLATFORM-SKILLS.md:generic"
1121:        "project-template/docs/pack/PACK-FEEDBACK.md:docs/pack/PACK-FEEDBACK.md:generic"
1122:        "project-template/docs/pack/PROMPT-TEMPLATES.md:docs/pack/PROMPT-TEMPLATES.md:generic"
1123:        "project-template/docs/pack/HELP-FRAGMENT.md:docs/pack/HELP-FRAGMENT.md:generic"
1124:        "project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic"
1125:        "project-template/docs/pack/OPTIONAL-FEATURES.md:docs/pack/OPTIONAL-FEATURES.md:generic"
```

PASS — S6 glob path (L539, L544 from earlier read) auto-covers fresh
install; explicit `--update` entry added at L1125. See §4 for path
analysis.

### Command 3 — D8.7 ref-update

```
$ sed -n '160,165p' supporting-docs/DEPENDENCIES.md
- Reference: https://github.com/yahsan2/gh-sub-issue

See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
walkthrough.

---

$ grep -n "OPTIONAL-FEATURES" supporting-docs/DEPENDENCIES.md
162:See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (v11)" for the full
```

PASS — L162 now reads `docs/pack/OPTIONAL-FEATURES.md`; ONLY ref in
file.

### Command 4 — A4-A8 verify-only (grep each ref location)

```
$ grep -rn "docs/pack/OPTIONAL-FEATURES\|OPTIONAL-FEATURES" project-template/
project-template/.gemini/commands/pack-help.toml:11:docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md.
project-template/.claude/skills/pack-help/SKILL.md:14:`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49:See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
project-template/docs/pack/HELP-FRAGMENT.md:5:`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.
project-template/docs/pack/HELP-FRAGMENT.md:31:`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
project-template/.codex/skills/pack-help/SKILL.md:14:`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
```

PASS — A4-A8 (5 files, 6 hit locations) all resolve to the new
project-side file post-SPLIT. See §6 for per-ref table.

### Command 4b — TYPE-2 contamination avoidance grep

```
$ grep -n "STREAMS\|Check 22\|validate-pack" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "tracker.toml.pack-example" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits)

$ grep -n "pack-ops/" project-template/docs/pack/OPTIONAL-FEATURES.md
(no output — zero hits; the MERGE-STRATEGY ref uses 'in the pack repo' qualifier instead)

$ grep -n "in the pack repo" project-template/docs/pack/OPTIONAL-FEATURES.md
174:your pre-migration content. See `MERGE-STRATEGY.md` in the pack repo
```

PASS — Zero pack-tracker plumbing leaks; zero unqualified `pack-ops/`
references; MERGE-STRATEGY ref carries the prescribed "in the pack
repo" qualifier per Architect C's TYPE-4 prevention contract.

### Command 5 — Manifest regen

```
$ bash test-fixtures/build.sh --all --clean
[snipped — see §7 for full output]
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

PASS — 3 v11-* fixture rows drifted as expected per RC9.

### Command 6 — Working-tree scope

```
$ git status --short
 M scripts/init-project.sh
 M supporting-docs/DEPENDENCIES.md
 M test-fixtures/manifest.txt
?? project-template/docs/pack/OPTIONAL-FEATURES.md
```

PASS — Exactly the 4 in-scope files, no spillage outside Commit 10
scope.

### Command 7 — HEAD SHA for PREFLIGHT line

```
$ git rev-parse HEAD
00d777245db690f2c1212d4581cb92d062d6a613
```

HEAD unchanged from start of session — no state-changing git verbs
executed.

---

## §10 PREFLIGHT line

```
PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD 00d777245db690f2c1212d4581cb92d062d6a613; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-10.md
```

---

## Appendix A — Definition-of-Done checklist

| Criterion | Status |
|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` exists, follows §13.3 table decisions, project-user voice | PASS (judgment call on line count documented in §8.1; 188 vs target 150-180) |
| `scripts/init-project.sh` install loop handles new file | PASS (S6 glob auto-covers; `--update` mapping explicit entry added L1125; see §4) |
| `supporting-docs/DEPENDENCIES.md:162` reads `docs/pack/OPTIONAL-FEATURES.md` | PASS (§5) |
| A4-A8 refs grep-resolve correctly | PASS (§6) |
| `bash test-fixtures/build.sh --all --clean` succeeds; manifest regenerated | PASS (§7) |
| No edits outside 4 in-scope files | PASS (§9 Command 6 — `git status --short` shows exactly 4 entries) |
| No state-changing git verbs run | PASS (§9 Command 7 — HEAD unchanged at `00d7772`) |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS (§10) |

---

## Appendix B — Plan deviations

**None.** All implementation choices map to a specific §2.10 / §13
authority:
- File location: §2.10.2 + §6.1 TASK-T8 (`project-template/docs/pack/OPTIONAL-FEATURES.md`)
- Section structure: §13.3 9-row content-split table
- Line count: §13.3 "Approximate length: ~150-180 lines" (188 within "approximate" tolerance; §8.1 documents the judgment)
- init-project.sh path: §13.4 step 3 ("verify ... if loop already covers ..., no special-casing needed; if not, add explicit install line") — both paths exist; S6 auto-covers, `--update` explicit add
- D8.7 ref-update: §2.10.2 + §3.5 D8.7 implementation hint
- A4-A8 verify-only: §2.10.2 NOT MODIFIED list + §4 A4-A8 decisions

---

## Appendix C — New POQs introduced

**None.** No design ambiguities encountered that required Pack Chat
escalation. Implementation guidance in §13.3 + §13.4 + §13.5 was
sufficient to execute mechanically with the two judgment-call gates
(§8.1 line count, §8.2 init-project.sh path) handled via documented
heuristic application per the architect docs.
