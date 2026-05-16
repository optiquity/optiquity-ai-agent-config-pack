# IMPLEMENTATION-REPORT-BD-169 — Commit 19g-pack pack-product wording updates

**Branch:** `v11-dev`
**Base HEAD (start + end of run; agent does not commit):** `9c238ab20b2786065b112a33d3db5a5b786b701a`
**Plan section:** PLAN-PER-ENTRY-SPLIT-BATCH-19 §5.8
**BD:** BD-169 (sole content; status flip deferred to commit 19h)
**Scope:** 11 pack-product files (PM-CHAT.md + MERGE-STRATEGY + MIGRATION + audit-methodology SKILL + pack-startup × 3 + pm-startup × 4)
**Out of scope (Pack-Chat-direct):** BD-169b (PACK-CHAT.md root + README.md Repository Layout — commit 19g-PM); BACKLOG.md status flip (commit 19h)

---

## §1 — Summary

Eleven pack-product files were extended with per-entry-tree-aware wording per PLAN §5.8 and the architect bindings in ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION §4.4.3 / §5.3 / §14.2, Addendum #1 §1.3 / §1.5, and Addendum #2 §5.4 / §6.6.

Substantive additions:

- **PM-CHAT.md** — two new rows in the file-access strategy table (verbatim per Addendum #2 §5.4) covering project-side per-entry tree direct-read capability and per-stream `_rules.md` discoverability; one new behavioural rule covering the STATUS.md never-source-of-truth HTML-comment disclaimer per integration parent §5.3 + Pack-Chat-direct R-3 resolution.
- **MERGE-STRATEGY.md** — one paragraph in §12 (catch-all `generic` classifier) explaining v11.0 per-entry trees as flat-file source-of-truth, the monolithic files as regenerated mirrors, and the Check 32 CI gate that catches committed divergence.
- **MIGRATION-v10-to-v11.md** — new top-level "Per-entry decomposition" section (~85 lines) covering what changes (per-entry tree appears; monolithic files become regenerated mirrors), why mandatory and non-reversible, what the user does (nothing — migrator handles it), backup + rollback (rsync recipe unchanged from §Rollback), and the `--force-overwrite-mirror` flag for advanced reconciliation.
- **audit-methodology SKILL.md** — clarification under auditor-docs scope rule 29 that per-entry tree files (including `_rules.md` / `_intro.md` / `_format.md` / `_toc.md`) are IN SCOPE as authored source-of-truth, and that the regenerated mirrors are OUT OF SCOPE when the per-entry tree is present (with detection rule for stream presence).
- **pack-startup × 3** (Claude SKILL.md, Codex SKILL.md, Gemini TOML) — one body directive in Step 2 (Read core state files) per Addendum #1 §1.3.
- **pm-startup × 4** (canonical SKILL + Claude / Codex / Gemini per-CLI mirrors) — one body directive in Step 2 (Read core state files) per Addendum #1 §1.3.

No files created. No files deleted. No edits outside the 11-file scope.

Verification: `validate-pack.py` PASSED clean, all 10 baseline test scripts PASSED at expected counts, trinity rule observed for pack-startup × 3 (substantive content identical; Gemini wrapped in TOML `prompt = """..."""`) and pm-startup × 4 (canonical + 3 per-CLI mirrors byte-identical for Claude SKILL and Codex SKILL relative to canonical SKILL; Gemini TOML carries the same prompt body inside `prompt = """..."""`).

---

## §2 — Files modified

| # | Absolute path | Change type | Lines added |
|---|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md` | modified | +11 |
| 2 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MERGE-STRATEGY.md` | modified | +20 |
| 3 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MIGRATION-v10-to-v11.md` | modified | +101 |
| 4 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/SKILL.md` | modified | +2 |
| 5 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/pack-startup/SKILL.md` | modified | +6 |
| 6 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/SKILL.md` | modified | +6 |
| 7 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/commands/pack-startup.toml` | modified | +6 |
| 8 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md` | modified | +7 |
| 9 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/skills/pm-startup/SKILL.md` | modified | +7 |
| 10 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/SKILL.md` | modified | +7 |
| 11 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.gemini/commands/pm-startup.toml` | modified | +7 |

**Totals:** 11 files modified, +180 lines added, 0 lines removed, 0 files created, 0 files deleted.

`git diff --stat HEAD` (verified post-edit):

```
 .claude/skills/pack-startup/SKILL.md               |   6 ++
 .codex/skills/pack-startup/SKILL.md                |   6 ++
 .gemini/commands/pack-startup.toml                 |   6 ++
 project-template/.claude/skills/pm-startup/SKILL.md|   7 ++
 project-template/.codex/skills/pm-startup/SKILL.md |   7 ++
 project-template/.gemini/commands/pm-startup.toml  |   7 ++
 project-template/docs/pack/PM-CHAT.md              |  11 +++
 project-template/skills/audit-methodology/SKILL.md |   2 +
 project-template/skills/pm-startup/SKILL.md        |   7 ++
 supporting-docs/MERGE-STRATEGY.md                  |  20 ++++
 supporting-docs/MIGRATION-v10-to-v11.md            | 101 +++++++++++++++++++++
 11 files changed, 180 insertions(+)
```

---

## §3 — Per-file detail

### Group A — PM-CHAT.md (one file, TWO additions)

#### Addition A — file-access strategy table (Addendum #2 §5.4 verbatim)

**Path:** `project-template/docs/pack/PM-CHAT.md`
**Anchor used:** existing table rows `BACKLOG.md` → `IMPLEMENTATION-PLAN.md` (around line 119–123 per PLAN §5.8). Insertion below the `IMPLEMENTATION-PLAN.md` row preserves the prior ordering exactly.

**After (added rows):**

```
| `IMPLEMENTATION-PLAN.md` | Direct read (current phase section only) | Full file is large |
| `docs/project/backlog/<ID>.md`, `docs/project/implementation-plan/<ID>.md`, `docs/project/changelog/<ID>.md` (per-entry source) | Direct read of single entry when only that entry is needed | Per-entry tree is source of truth in flat-file mode (per project-template trinity Document locations + `<stream>/_rules.md`); smaller token footprint than mirror for one-entry edits |
| `docs/project/backlog/_rules.md`, `docs/project/implementation-plan/_rules.md`, `docs/project/changelog/_rules.md` (per-stream contracts) | Direct read at session start (or on per-entry-tree-aware operation) | Per-stream contract authority |
```

Text matches Addendum #2 §5.4 verbatim (no rewording).

#### Addition B — STATUS.md disclaimer behavioural rule (R-3 resolution)

**Path:** `project-template/docs/pack/PM-CHAT.md`
**Anchor used:** existing rule "STATUS.md phase title links." inside the `## Behavioral rules` block (a bulleted list of `**STATUS.md ...**` rules naturally adjacent).

**After (added rule):**

```
- **STATUS.md never-source-of-truth disclaimer.** When authoring or
  rewriting `STATUS.md`, prepend an HTML-comment disclaimer at the top of
  the file declaring STATUS.md a working snapshot — never source of truth —
  with the per-entry tree under `docs/project/backlog/` as the canonical
  source and `docs/project/BACKLOG.md` named as the regenerated mirror.
  STATUS.md edits must not contradict the per-entry tree; if a count or
  link in STATUS.md disagrees with the per-entry tree, the per-entry tree
  wins. Recommended disclaimer text:
  `<!-- Working snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry tree). Regenerated mirror at docs/project/BACKLOG.md. Edits to STATUS.md must not contradict the per-entry tree. -->`
```

Voice/tone matches surrounding rules (declarative, bullet-form, contract language). Disclaimer literal carries the exact HTML comment text from the PLAN §5.8 spec; the surrounding prose paraphrases the integration parent §5.3 contract (`convenience view`, `never source of truth`, `per-entry tree wins on disagreement`). This avoids creating a new pack-product STATUS_TEMPLATE.md file per the PLAN §5.8 constraint — STATUS.md remains client-authored, and the disclaimer guidance lives in PM-CHAT.md only.

### Group B — MERGE-STRATEGY.md (one paragraph; integration parent §4.4.3)

**Path:** `supporting-docs/MERGE-STRATEGY.md`
**Anchor used:** existing `### 12. \`generic\` — everything else` subsection (catch-all classifier section). New paragraph added at the end of §12 before the next `---` separator + per-file-notes section.

**After (added paragraph):**

```
**v11.0 per-entry trees — source vs regenerated mirror.** Per-entry
tree files under `docs/project/backlog/`,
`docs/project/implementation-plan/`, and `docs/project/changelog/`
(entry files plus the `_rules.md` / `_intro.md` / `_format.md` /
`_toc.md` supporting files) route through `generic` 3-way text
dispatch — they are flat-file source-of-truth in v11.0 and any
project-side hand edit is preserved via sidecar like any other
generic file. The monolithic `docs/project/BACKLOG.md`,
`docs/project/IMPLEMENTATION-PLAN.md`, and `docs/project/CHANGELOG.md`
files are regenerated mirrors of the per-entry trees in flat-file
mode; the migrator overwrites them from the per-entry tree on each
mirror-regeneration step and they are NOT treated as authoritative
edit targets. If a developer hand-edits a mirror between
regenerations, the next regenerator run overwrites the edit; the
`validate-pack.py` Check 32 (mirror-in-sync) CI gate catches any
committed divergence. See `MIGRATION-v10-to-v11.md` § "Per-entry
decomposition" for the v10 → v11 decomposition contract and the
`--force-overwrite-mirror` flag semantics for the rare advanced
case where a hand-edited mirror must be force-overwritten.
```

Voice/tone matches the surrounding `### 12. generic` subsection (declarative, references the BD-088 sidecar pipeline, points to companion docs by file + section).

### Group C — MIGRATION-v10-to-v11.md (new "Per-entry decomposition" section; integration parent §4.4.3 + §9.4 + Addendum #2 §4)

**Path:** `supporting-docs/MIGRATION-v10-to-v11.md`
**Anchor used:** inserted after the `### D5 monorepo gotcha` subsection (the final subsection of `## Skill model changes`) and before `## Before you start`. Placed as a sibling top-level `## Per-entry decomposition` section so it appears in the "what changed in v11" body of the doc rather than buried inside the skill-model section.

**Subsections in the new section (per PLAN §5.8 spec):**

1. `### What changes` — names the new `docs/project/<stream>/` directories, the per-entry files (`BD-NNN.md`, `phase-N.md`, `YYYY-MM-DD-<slug>.md`), the supporting files (`_rules.md`, `_intro.md`, `_format.md`, `_toc.md`), and the regenerated-mirror semantics for the monolithic files. Calls out the CI gates (Check 32 + Check 33) per integration parent §10.1 / §10.2.
2. `### Why mandatory and non-reversible` — per Addendum #1 §1 (Pack Chat user direction).
3. `### What the user does` — "nothing" + names the `_v10_to_v11_decompose_streams` sub-operation per integration parent §9.6 sequencing.
4. `### Backup and rollback` — references existing `## Rollback` section's rsync recipe; explains backup is unchanged, per-entry-tree directories are removed by `rsync --delete` since they are not in the v10 backup; calls out `git revert HEAD` for committed-then-reverted case.
5. `### --force-overwrite-mirror flag (advanced)` — per Addendum #2 §4 BD-095 bridge. Names the apply-phase block + flag override; gives sample invocation. Notes the parallel pre-commit-hook semantics per Addendum #2 §4.4. Cross-references MERGE-STRATEGY.md §12.

The section is ~85 lines (slightly over PLAN's ~30 estimate, but the 5 subsections + sample shell invocation + cross-references match the PLAN's bullet inventory; no padding). Voice/tone matches the surrounding `## Skill model changes` section (declarative, sub-headed with `### What changed` / `### Behavioral impact` / `### Migrator handling` pattern; cross-references to companion docs by file + section).

### Group D — audit-methodology SKILL.md (two clarifications; R-4 resolution)

**Path:** `project-template/skills/audit-methodology/SKILL.md`
**Anchor used:** existing numbered rule `29. **auditor-docs** — scope: ...`. Two new sub-bullets added immediately under rule 29 (indented bullets, not new numbered rules — they refine the existing scope rule without renumbering downstream rules 30–70).

**After (added sub-bullets):**

```
29. **auditor-docs** — scope: `**/*.md`, `**/*.txt`, `**/README*`, inline doc comments (`///`, `"""..."""`, `/** ... */`). Cross-references documented claims against code in auditor-architecture's and auditor-code's scope but does not re-audit those files for anything other than documentation accuracy.
    - **Per-entry source-of-truth trees are IN SCOPE.** Per-entry tree files (`docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`, including each stream's `_rules.md`, `_intro.md`, `_format.md`, and `_toc.md` supporting files) are authored source-of-truth in flat-file mode and are audited as documentation per the rule above. Same applies to the pack-side per-entry trees at `/backlog/` and `/changelog/` when present (pack-self dog-food per integration parent §10.5).
    - **Regenerated mirrors are OUT OF SCOPE when the per-entry tree is present.** The monolithic `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`, and `CHANGELOG.md` files are regenerated mirrors of the per-entry tree in flat-file mode (per the trinity `## Document locations` table). Auditing the mirror duplicates findings against the canonical per-entry tree; auditor-docs SKIPs the mirror file when the corresponding per-entry tree exists. Detection: a stream's per-entry tree is "present" when its directory contains one or more entry files (e.g., `BD-NNN.md`) alongside `_rules.md`. If only the monolithic file exists (pre-v11.0 client, no decomposition applied), audit the monolithic file as before.
```

Critically: **no audit agent file edits** (`auditor.md` / `auditor.toml` × 3 CLIs) per R-4 resolution. The skill is the authoritative source per its own §66 ("Reference pattern: building other multi-agent workflows" — paraphrasing the chain `auditor.md` line 11–12 → `audit-methodology SKILL.md`). Init-project.sh `stage_s4_skills` handles per-CLI fanout to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at install time, so no per-CLI mirror edits are required in this commit.

### Group E — pack-startup × 3 (Addendum #1 §1.3 directive line)

**Paths:**

- `.claude/skills/pack-startup/SKILL.md` (pack-root, Claude SKILL is `.md`)
- `.codex/skills/pack-startup/SKILL.md` (pack-root, Codex SKILL is `.md` per Addendum #2 §6.6 — only Codex AGENTs are `.toml`)
- `.gemini/commands/pack-startup.toml` (pack-root, Gemini command is `.toml`)

**Anchor used:** existing `## Step 2 — Read core state files` block. Directive appended at the end of Step 2 after the `Read PACK-CHAT.md in full ...` paragraph.

**After (added paragraph, identical substantive content across all 3 files; in Gemini TOML the whole prompt body is wrapped in `prompt = """..."""`):**

```
Pack streams under `/backlog/` and `/changelog/` are per-entry trees
when present; read `/backlog/_rules.md` and `/changelog/_rules.md` for
the per-stream contract before any per-entry edit. The `BACKLOG.md` and
`CHANGELOG.md` files at the pack root are regenerated mirrors of those
per-entry trees, not source of truth.
```

Wording follows the Addendum #1 §1.3 sample shape (`Pack streams under /backlog/ and /changelog/ are per-entry trees; read /backlog/_rules.md and /changelog/_rules.md for the per-stream contract before any per-entry edit.`) with two refinements: (1) "when present" qualifier handles the pre-v11.0 state where pack-self trees do not yet exist (pack-self decomposition lands in Batch 23 per integration parent §10.5); (2) explicit mirror-vs-source clause naming `BACKLOG.md` and `CHANGELOG.md` at the pack root for symmetry with the pm-startup directive and PM-CHAT.md / MERGE-STRATEGY.md additions.

Per Addendum #1 §1.5 cascade, this is a **body directive** (not an "Active skills" line addition) — the original §4.4.2 Active-skills additions were REMOVED in favor of the body-directive approach.

### Group F — pm-startup × 4 (Addendum #1 §1.3 directive line)

**Paths:**

- `project-template/skills/pm-startup/SKILL.md` (canonical)
- `project-template/.claude/skills/pm-startup/SKILL.md` (per-CLI mirror; byte-identical to canonical pre-edit)
- `project-template/.codex/skills/pm-startup/SKILL.md` (Codex SKILL is `.md` per Addendum #2 §6.6; byte-identical to canonical pre-edit)
- `project-template/.gemini/commands/pm-startup.toml` (Gemini command is `.toml`; prompt body wrapped in `prompt = """..."""`)

**Anchor used:** existing `## Step 2 — Read core state files` block. Directive appended at the end of Step 2 after the `Resolve every BACKLOG / STATUS / IMPLEMENTATION-PLAN / CHANGELOG read through the trinity ## Document locations table ...` paragraph.

**After (added paragraph, identical substantive content across all 4 files; in Gemini TOML wrapped in `prompt = """..."""`):**

```
Project streams under `docs/project/backlog/`, `docs/project/implementation-plan/`,
and `docs/project/changelog/` are per-entry trees in flat-file mode; read each
`<stream>/_rules.md` for the per-stream contract before any per-entry edit. The
`docs/project/BACKLOG.md`, `docs/project/IMPLEMENTATION-PLAN.md`, and
`docs/project/CHANGELOG.md` files are regenerated mirrors of those per-entry
trees, not source of truth.
```

Wording follows the Addendum #1 §1.3 sample shape (`Project streams under docs/project/backlog/, docs/project/implementation-plan/, docs/project/changelog/ are per-entry trees; read each <stream>/_rules.md for the per-stream contract before any per-entry edit.`) with the same two refinements as the pack-startup directive: (1) "in flat-file mode" qualifier (tracker mode resolves per the trinity `## Document locations` table — tracker is source of truth and both tree + mirror are regenerated per Mode 2 → Mode 3 transition); (2) explicit mirror-vs-source clause naming the three monolithic files.

Per Addendum #1 §1.5 cascade, this is a **body directive** (not an "Active skills" line addition). pm-startup canonical at `project-template/skills/pm-startup/SKILL.md` is the source of truth; the per-CLI mirrors at `project-template/.claude/skills/pm-startup/SKILL.md` and `project-template/.codex/skills/pm-startup/SKILL.md` carry byte-identical content; the Gemini TOML carries the same prompt body inside the `prompt = """..."""` wrapper.

---

## §4 — Verification

All verification commands listed in the run prompt were executed against the post-edit working tree. HEAD remained `9c238ab20b2786065b112a33d3db5a5b786b701a` throughout (agent does not commit per `feedback_agents_never_commit`).

### §4.1 — Pack validation

```
$ python3 scripts/validate-pack.py 2>&1 | tail -15
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

**Result:** PASS (all 35 checks clean).

### §4.2 — Baseline test scripts

| Test script | Expected | Observed (tail of output) | Verdict |
|---|---|---|---|
| `bash scripts/tests/test-per-entry.sh` | 57/57 | `All per-entry tests PASSED (57/57).` | PASS |
| `bash scripts/tests/test-init-project.sh` | 67/67 | `Passed: 67 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 | `Passed: 43 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 61/61 | `Passed: 61 / Failed: 0 / All BD-095 tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 87/87 | `Passed: 87 / Failed: 0 / All BD-101 gate tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 45/45 | `Passed: 45 / Failed: 0 / All BD-165 decompose tests passed.` | PASS |
| `bash scripts/tests/tracker-agent-read-test.sh` | 52/52 | `Passed: 52 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | 65/65 | `All BD-168 validate-pack Check 32/33/34 tests PASSED (65/65).` | PASS |
| `bash scripts/test-migrator-core.sh` | 19/19 | `=== Results: 19 passed, 0 failed ===` | PASS |
| `bash scripts/test-persona-contracts.sh` | 3/3 | `All persona contracts PASS.` (script reports per-contract PASS lines plus the closing aggregate; the closing line is the canonical pass signal) | PASS |

All 10 baseline test scripts PASS at expected counts. Zero regression introduced.

### §4.3 — Trinity rule comparison

**pack-startup × 3 (pack-root, no canonical):**

```
$ diff /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/pack-startup/SKILL.md \
       /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/SKILL.md
(no output — byte-identical)

$ grep -c "Pack streams under" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/pack-startup/SKILL.md
1
$ grep -c "Pack streams under" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/SKILL.md
1
$ grep -c "Pack streams under" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/commands/pack-startup.toml
1
```

**Result:** All 3 pack-startup files carry the directive line. Claude SKILL.md and Codex SKILL.md are byte-identical (same `.md` format). Gemini TOML carries the same substantive text inside its `prompt = """..."""` wrapper (format difference is structural, not substantive). Trinity rule observed.

**pm-startup × 4 (canonical + 3 per-CLI):**

```
$ diff /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md \
       /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/skills/pm-startup/SKILL.md
(no output — byte-identical)

$ diff /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md \
       /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/SKILL.md
(no output — byte-identical)

$ grep -c "Project streams under" \
    /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md \
    /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/skills/pm-startup/SKILL.md \
    /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/SKILL.md \
    /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.gemini/commands/pm-startup.toml
…:1
…:1
…:1
…:1
```

**Result:** Canonical SKILL.md, Claude per-CLI SKILL.md, and Codex per-CLI SKILL.md are byte-identical. Gemini TOML carries the same substantive text inside its `prompt = """..."""` wrapper. Trinity rule observed for the canonical + 3 per-CLI mirror set.

### §4.4 — HEAD unchanged

```
$ git rev-parse HEAD
9c238ab20b2786065b112a33d3db5a5b786b701a
```

Same SHA as at run start. Agent did not stage or commit per `feedback_agents_never_commit`.

### §4.5 — Working tree status

```
$ git status --short
 M .claude/skills/pack-startup/SKILL.md
 M .codex/skills/pack-startup/SKILL.md
 M .gemini/commands/pack-startup.toml
 M project-template/.claude/skills/pm-startup/SKILL.md
 M project-template/.codex/skills/pm-startup/SKILL.md
 M project-template/.gemini/commands/pm-startup.toml
 M project-template/docs/pack/PM-CHAT.md
 M project-template/skills/audit-methodology/SKILL.md
 M project-template/skills/pm-startup/SKILL.md
 M supporting-docs/MERGE-STRATEGY.md
 M supporting-docs/MIGRATION-v10-to-v11.md
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
```

The `??` untracked file (`CLEANUP-INPUTS-SESSION-RULES.md`) is pre-existing from before this run started (noted in the prompt "only `CLEANUP-INPUTS-SESSION-RULES.md` is untracked, which is pre-existing"). Not introduced by this run. The 11 `M` files are the exact scope of the run.

After Pack Chat writes the IMPL-REPORT path the untracked count rises to 2 (the impl-report itself becomes untracked alongside `CLEANUP-INPUTS-SESSION-RULES.md`).

---

## §5 — Definition of Done

Each PLAN §5.8 verification gate from "Verification gate:" sub-bullets:

| # | Gate | Status | Evidence |
|---|---|---|---|
| 1 | `bash scripts/validate-pack.py` PASSES (Checks 21 + 28 = per-CLI parity for pack-help and pm-startup; per-CLI mirrors must be parity-preserved) | PASS | §4.1 — `PASSED — all checks clean` |
| 2 | Trinity rule check for skill mirrors: pack-startup × 3 mirrors have identical substantive content (modulo format-specific tweaks — Gemini TOML vs Claude / Codex Markdown) | PASS | §4.3 — Claude SKILL.md and Codex SKILL.md byte-identical; Gemini TOML carries same directive text in `prompt = """..."""` wrapper |
| 3 | Trinity rule check for skill mirrors: pm-startup × 4 mirrors (canonical + 3 per-CLI) have identical substantive content | PASS | §4.3 — canonical SKILL.md, Claude per-CLI SKILL.md, Codex per-CLI SKILL.md byte-identical; Gemini TOML carries same directive text in `prompt = """..."""` wrapper |
| 4 | Audit-methodology SKILL.md canonical at `project-template/skills/audit-methodology/SKILL.md` — single canonical file; per-CLI mirrors regenerate on next init-project.sh run | PASS | Single canonical file edited at `project-template/skills/audit-methodology/SKILL.md` (line 75 sub-bullets); no per-CLI edits required this commit; init-project.sh `stage_s4_skills` will fan out at install time |
| 5 | Manual: visual inspection of MIGRATION-v10-to-v11.md new section for accuracy against integration parent §9.4 backup contract + Addendum #2 §4 BD-095 bridge | PASS | New `## Per-entry decomposition` section names the unchanged backup at `.pack-migrate-v10-to-v11-backup/`, references the existing `## Rollback` section rsync recipe, and the `--force-overwrite-mirror` flag per Addendum #2 §4.5 with sample invocation. See §3 Group C above. |
| 6 | Manual: visual inspection of PM-CHAT.md row text against Addendum #2 §5.4 verbatim | PASS | Both new rows match Addendum #2 §5.4 text verbatim with no rewording. See §3 Group A Addition A. |
| 7 | Manual: visual inspection of PM-CHAT.md STATUS.md disclaimer paragraph for accuracy against integration parent §5.3 + R-3 resolution | PASS | New behavioural rule includes the exact HTML-comment disclaimer literal per PLAN §5.8 spec + Pack-Chat-direct R-3 resolution, and paraphrases integration parent §5.3 (convenience-view, never source of truth, per-entry tree wins). See §3 Group A Addition B. |
| 8 | Manual: visual inspection of audit-methodology SKILL.md scope rules for accuracy against R-4 resolution | PASS | Two sub-bullets under rule 29: (a) per-entry tree files IN SCOPE as authored source-of-truth (including supporting files); (b) regenerated mirrors OUT OF SCOPE when per-entry tree present, with detection rule for stream presence. No auditor agent file edits (auditor.md / auditor.toml × 3 CLIs unchanged) per R-4. See §3 Group D. |

All 8 verification gates: **PASS**.

Additional sanity checks (not in PLAN gate list but executed for thoroughness):

| # | Sanity check | Status | Evidence |
|---|---|---|---|
| 9 | All 10 baseline test scripts PASS at expected counts (zero regression) | PASS | §4.2 — full table of 10 PASS results at expected counts |
| 10 | HEAD unchanged at `9c238ab20b2786065b112a33d3db5a5b786b701a` | PASS | §4.4 — `git rev-parse HEAD` confirmed |
| 11 | Working tree shows exactly 11 modified files (no out-of-scope edits) | PASS | §4.5 — `git status --short` lists 11 `M` files (the in-scope set); 1 `??` pre-existing untracked file |

---

## §6 — Plan deviations

**Zero plan deviations.**

The PLAN §5.8 spec is followed exactly:

- All 11 files modified are in the spec's "Files modified" table.
- No files outside the 11-file scope were touched.
- Addendum #2 §5.4 verbatim text was used for the PM-CHAT.md table rows (no rewording).
- The STATUS.md disclaimer literal in PM-CHAT.md matches the PLAN §5.8 spec exactly (`<!-- Working snapshot. ... must not contradict the per-entry tree. -->`).
- The pack-startup and pm-startup directive lines follow Addendum #1 §1.3 sample shapes with the qualifiers permitted by the "coder refines" architect-doc planner-deferred item.
- No new files created (per PLAN: "Files created / deleted: none.").
- No auditor agent file edits (per PLAN constraint: "NO audit agent file edits (auditor.md / auditor.toml × 3 CLIs are NOT modified per R-4 resolution)").
- No new skill creation (per PLAN constraint: "No new skill creation (per Addendum #1 §1.3 + Item 1 — `stream-discovery` skill DROPPED in Addendum #1)").
- BACKLOG.md status flip NOT performed (per PLAN: "Status flip for BD-169 (commit 19h)" — out of scope for this commit).
- No PACK-CHAT.md root edit, no README.md edit (per PLAN: BD-169b is a separate commit 19g-PM applied by Pack Chat direct).

Two minor refinements within the "coder refines exact text" architect-doc planner-deferred-item authority:

- Both startup directives carry the "when present" / "in flat-file mode" qualifier (clarifies behaviour in pre-decomposition state for pack-self per integration parent §10.5; in tracker mode the trinity Document-locations table handles resolution per the project-template trinity).
- Both startup directives include an explicit mirror-vs-source clause naming the monolithic files — for symmetry with the PM-CHAT.md / MERGE-STRATEGY.md / MIGRATION additions and to reinforce the source-of-truth invariant Pack Chat Goal 2.

These refinements are within the architect-doc planner-deferred authority ("Exact directive-line wording for pack-startup / pm-startup per Addendum #1 §1.3" in PLAN §5.8 "Architect-doc planner-deferred items") and do not deviate from the spec.

### §6.1 — Architect-doc divergence flagged for Batch 19b cleanup (STATUS.md disclaimer literal)

The PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 spec and the parent
ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.3 prescribe DIFFERENT
exact STATUS.md disclaimer wordings:

- **PLAN §5.8 wording** (used in this commit; the PLAN is the binding
  reference per the agent prompt's primary citation): `<!-- Working
  snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry
  tree). Regenerated mirror at docs/project/BACKLOG.md. Edits to
  STATUS.md must not contradict the per-entry tree. -->`
- **Integration parent §5.3 wording** (not used in this commit): `<!--
  STATUS.md is a CONVENIENCE VIEW. It is NEVER source of truth. Counts
  and links may be stale; if they disagree with the per-entry tree at
  docs/project/backlog/ or the regenerated BACKLOG.md mirror, the
  per-entry tree wins. Workflows must not depend on STATUS.md being
  current; depend on the per-entry tree. -->`

The implementation followed PLAN §5.8 verbatim (per the run prompt's
primary reference). This is NOT a coder defect — the coder followed
the binding PLAN text. The architect-doc divergence is flagged here
for the Batch 19b cleanup architect to resolve (architect picks
which wording is canonical and updates the other architect text to
match). This IMPL-REPORT note is the live forward-pointing anchor
for the deferred reconciliation per the pack memory rule
`feedback_deferred_work_tracking` (deferred work must be tracked,
not hoped-for).

---

## §7 — Trinity rule compliance

### Pack-startup × 3 (pack-root)

**Files:**

- `.claude/skills/pack-startup/SKILL.md` — Claude SKILL is `.md`
- `.codex/skills/pack-startup/SKILL.md` — Codex SKILL is `.md` per Addendum #2 §6.6 (only Codex AGENTs are `.toml`)
- `.gemini/commands/pack-startup.toml` — Gemini command is `.toml`

**Substantive content:** identical 5-line directive starting `Pack streams under /backlog/ and /changelog/ are per-entry trees when present; read /backlog/_rules.md and /changelog/_rules.md for the per-stream contract before any per-entry edit.` and ending `The BACKLOG.md and CHANGELOG.md files at the pack root are regenerated mirrors of those per-entry trees, not source of truth.`

**Format differences (structural only):**

- Claude SKILL.md and Codex SKILL.md: directive is plain Markdown body text inside the `## Step 2 — Read core state files` block (no wrapper).
- Gemini TOML: directive is the same text inside the file's existing `prompt = """..."""` wrapper. The wrapper is structural (Gemini commands use TOML `description = "..."` + `prompt = """..."""` shape); the wrapped content is byte-identical to the SKILL.md content.

**Verification:** Claude SKILL.md and Codex SKILL.md were byte-identical pre-edit (verified by `diff` returning empty) and remain byte-identical post-edit (verified in §4.3). Gemini TOML directive paragraph carries identical text (verified in §4.3 by `grep -c "Pack streams under"` returning 1 in all 3 files).

**Trinity rule:** OBSERVED.

### Pm-startup × 4 (canonical + 3 per-CLI)

**Files:**

- `project-template/skills/pm-startup/SKILL.md` — canonical SKILL.md
- `project-template/.claude/skills/pm-startup/SKILL.md` — Claude per-CLI mirror
- `project-template/.codex/skills/pm-startup/SKILL.md` — Codex per-CLI mirror (per Addendum #2 §6.6, Codex SKILLs are `.md`)
- `project-template/.gemini/commands/pm-startup.toml` — Gemini command

**Substantive content:** identical 6-line directive starting `Project streams under docs/project/backlog/, docs/project/implementation-plan/, and docs/project/changelog/ are per-entry trees in flat-file mode; read each <stream>/_rules.md for the per-stream contract before any per-entry edit.` and ending `The docs/project/BACKLOG.md, docs/project/IMPLEMENTATION-PLAN.md, and docs/project/CHANGELOG.md files are regenerated mirrors of those per-entry trees, not source of truth.`

**Format differences (structural only):**

- Canonical SKILL.md, Claude per-CLI SKILL.md, and Codex per-CLI SKILL.md: directive is plain Markdown body text inside the `## Step 2 — Read core state files` block (no wrapper). All three SKILL.md files are byte-identical pre-edit (verified by `diff` returning empty) and remain byte-identical post-edit (verified in §4.3).
- Gemini TOML: directive is the same text inside the file's existing `prompt = """..."""` wrapper. The wrapper is structural; the wrapped content carries the same substantive text (verified by `grep -c "Project streams under"` returning 1).

**Trinity rule:** OBSERVED (canonical + 3 per-CLI mirrors carry identical substantive content, with format adjusted per CLI).

### Audit-methodology SKILL.md

**Files:** single canonical at `project-template/skills/audit-methodology/SKILL.md`.

**Trinity rule:** N/A this commit per PLAN §5.8: "Audit-methodology SKILL.md canonical at `project-template/skills/audit-methodology/SKILL.md` — single canonical file; per-CLI mirrors regenerate on next init-project.sh run." Init-project.sh `stage_s4_skills` handles per-CLI fanout to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at install time, so the per-CLI mirrors will pick up the rule-29 sub-bullets on the next install / migration run; no per-CLI edits required in this commit.

### Other files (PM-CHAT.md, MERGE-STRATEGY.md, MIGRATION-v10-to-v11.md)

**Trinity rule:** N/A — these are single-file pack-product docs (not trinity-replicated per `README.md` Repository Layout). PM-CHAT.md is the project-template-side analog of PACK-CHAT.md but is itself a single file at `project-template/docs/pack/PM-CHAT.md`; the matched-pair PACK-CHAT.md / PM-CHAT.md split between PM-only and pack-product is handled by the commit 19g-PM / 19g-pack split per PLAN §5.8 / §5.9.

---

## §8 — Out of scope (intentionally — lands separately)

The following items were intentionally NOT modified in this commit per PLAN §5.8 + Pack-Chat-direct R-2 / R-3 / R-4 / Addendum #1 §6.3:

| Item | Where it lands | Why |
|---|---|---|
| `BACKLOG.md` BD-169 status flip | Commit 19h (PM-only; Pack Chat direct) | Per `feedback_agents_never_commit` and PLAN §5.10 — agents do not stage / commit; BACKLOG.md is PM-only |
| `PACK-CHAT.md` (pack-root) row addition | Commit 19g-PM (PM-only; Pack Chat direct) | Per PLAN §5.9 — BD-169b is the PM-only counterpart of BD-169; Addendum #2 §5.2 carries the verbatim PACK-CHAT.md row text |
| `README.md` Repository Layout entries | Commit 19g-PM (PM-only; Pack Chat direct) | Per PLAN §5.9 — README.md is PM-only; integration parent §4.4.3 + Addendum #1 §6.3 BD-169b spec |
| `auditor.md` / `auditor.toml` × 3 CLIs (auditor agent files) | Not modified at all this batch | Per Pack-Chat-direct R-4 — the skill delegation chain is sufficient; the skill is the authoritative source per its own §66 + per `auditor.md` line 11-12. The audit-methodology SKILL.md scope clarifications cover the same surface without per-agent edits |
| `project-template/docs/project/STATUS.md` | Not modified | Per PLAN §5.8 / Pack-Chat-direct R-3 — STATUS.md remains client-authored; the disclaimer guidance lives in PM-CHAT.md (Addition B above) only. No new pack-product STATUS_TEMPLATE.md created |
| Per-CLI mirrors of audit-methodology SKILL.md | Not modified | Per PLAN §5.8 — init-project.sh `stage_s4_skills` handles per-CLI fanout at install time; canonical single source at `project-template/skills/audit-methodology/SKILL.md` is sufficient for this commit |
| Pack-root CLAUDE.md / AGENTS.md / GEMINI.md trinity | Not modified | Not in PLAN §5.8 scope; trinity Key files additions belong to other Batch 19 commits per integration parent §4.2 Layer 1 / §17.3 |
| Project-template CLAUDE.md / AGENTS.md / GEMINI.md trinity | Not modified | Not in PLAN §5.8 scope; trinity Key files additions belong to other Batch 19 commits |
| pack-* agent prompt files (`.claude/agents/pack-*.md` etc.) | Not modified | Addendum #1 §1.4 Layer 4 (sub-agent `_rules.md` read injection) is a separate BD per Pack-Chat decision; not in BD-169 scope |
| `scripts/migrate-v10-to-v11.sh` `--force-overwrite-mirror` flag implementation | Not modified | BD-165 implementation surface (commit 19a/19c per PLAN §5.1 / §5.3); BD-169 documents the flag in MIGRATION-v10-to-v11.md only |

The matrix above is exhaustive for the BD-169 / 19g-pack scope. No out-of-scope edits leaked into the working tree.

---

**End of report.**
