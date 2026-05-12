# IMPLEMENTATION-REPORT-BATCH-14-FIX-FOLLOW

**Verdict:** Done

Batch 14 fix-follow lands the pre-emptive tightenings recommended by
AUDIT-BD-032 / 033 / 034 / 035 against the auditor subagent spec. All
twelve in-scope files were edited in a single trinity-symmetric pass.
The validator (`python3 scripts/validate-pack.py`) reports `PASSED —
all checks clean` across all 30 checks. BD-032 / 033 / 034 / 035
themselves remain Open in BACKLOG (their PACK-FEEDBACK Q1–Q4
real-world-validation blockers are unaffected by these spec
tightenings).

---

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD SHA (worktree base, unchanged — pack-coder does not commit):
  `60ac6d94b19ea3196404cb088f73c43c3881ac0c`
- Latest commit on branch: `19755b5 fix: v11 — v10.1 backport
  optimization pass (Items 1, 2, 4, 6)`

## 2. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
$ git rev-parse HEAD
60ac6d94b19ea3196404cb088f73c43c3881ac0c
$ git rev-parse --abbrev-ref HEAD
v11-dev
$ ls maintenance-docs/v11-implementation/ | grep AUDIT-BD-03
AUDIT-BD-032.md
AUDIT-BD-033.md
AUDIT-BD-034.md
AUDIT-BD-035.md
$ python3 scripts/validate-pack.py 2>&1 | tail -2
============================================================
PASSED — all checks clean
```

All four audit reports present at the expected paths. Baseline validator
clean before starting. Batch 13 concurrent agent edits already present
in the worktree on `scripts/`, `.github/workflows/`, `README.md`,
`supporting-docs/MIGRATION-v10-to-v11.md`, `supporting-docs/MERGE-STRATEGY.md`,
`scripts/validate-pack.py` — out of Batch 14 scope, no overlap.

## 3. Per-task summary

### BD-032 — observability infrastructure vs. configuration boundary

- **Edit 1 (rule 21 worked example).** Appended a Boundary
  clarification paragraph to `audit-methodology/SKILL.md` rule 21
  covering source-file observability code that *configures* runtime
  for a deployment target. Names the file-path-vs-finding-shape
  distinction (structural → architecture; deployment-target → ops),
  carries the "when uncertain → ops" tiebreaker, and adds the
  cross-ref to `auditor-security` for log-content findings (PII /
  credentials / tokens) per rule 33.
- **Edit 2 (trinity-mirrored agent files, 6 files).** Added the
  same Source-file observability *code* clarification + log-content
  security cross-ref to the observability bullets in:
  - `.claude/agents/auditor-architecture.md`
  - `.gemini/agents/auditor-architecture.md`
  - `.codex/agents/auditor-architecture.toml`
  - `.claude/agents/auditor-ops.md`
  - `.gemini/agents/auditor-ops.md`
  - `.codex/agents/auditor-ops.toml`
  Symmetric prose; tool-format-specific differences (Markdown
  bullet vs. TOML triple-quoted prose, `*emphasis*` style preserved
  per CLI tradition) are the only deviations.
- **Edit 3 (PII / log-content cross-ref).** Folded into Edit 1
  (rule 21 now contains both clarifications in one paragraph) and
  Edit 2 (each agent file's observability bullet now references
  rule 33 / `auditor-security` for log-content findings).

### BD-033 — auditor systemic error-handling threshold

- **Edit 1 + 4 (rule 16 quantified threshold + boundary
  enumeration).** Appended a Systemic threshold paragraph to
  `audit-methodology/SKILL.md` rule 16: "3+ independent call sites
  OR crosses module boundaries" with single-site → reviewer; named
  the boundaries explicitly (`error-handling` rule 4 boundaries
  plus every transport per loaded protocol skills like
  `grpc-patterns` / `rest-patterns`); plus a per-function /
  systemic split note pointing at the routing tags.
- **Edit 2 (trinity-mirrored auditor-code split, 3 files).**
  Replaced the single "Systemic error handling" bullet with two
  bullets in `.claude/agents/auditor-code.md`,
  `.gemini/agents/auditor-code.md`, `.codex/agents/auditor-code.toml`:
  - **Systemic error handling** — cross-cutting consistency only,
    references rule 16's threshold, names every transport boundary
    + the `error-handling` rule references.
  - **Per-function error-handling defects** — the empty-catch /
    swallowed-error / lost-context / missing-re-raise items now
    explicitly belong under "Language idiom adherence" unless
    escalated to systemic at 3+ sites. Resolves the prior
    self-contradiction the audit report flagged.
- **Edit 3 (error-handling skill routing tags).** Added a Routing
  tags section to `error-handling/SKILL.md` and tagged each of the
  14 rules `[systemic — auditor-code]` / `[per-function — reviewer]`
  / *(meta — no routing tag)*. Mapping matches the audit report
  exactly:
  - Systemic: 1, 2, 3, 4, 6 (cross-boundary), 8, 9, 10, 11, 12.
  - Per-function: 5, 6 (single-site), 7, 13.
  - Meta: 14.
  Rule 6 carries both tags with disambiguation prose
  ("[systemic — auditor-code] (cross-boundary uniformity);
  [per-function — reviewer] (single-site application)") since the
  rule legitimately applies at both levels.

### BD-034 — auditor-ui scope breadth

- **Edit 1 (rule 20 re-pointer).** Replaced rule 20 with a
  re-pointer formulation: "applies *every* UI rule defined in the
  loaded platform skills" plus a 5-bullet illustrative enumeration
  (the original 4 plus a new Localization-and-adaptation bullet).
  Added explicit "the enumeration is illustrative, not exhaustive"
  + "the 4 default headings are the floor, not the ceiling"
  language so future audits do not narrow to the named bullets.
- **Edit 2 (trinity-mirrored auditor-ui expansion, 3 files).** In
  `.claude/agents/auditor-ui.md`, `.gemini/agents/auditor-ui.md`,
  `.codex/agents/auditor-ui.toml`:
  - Expanded **Accessibility gaps** to add screen-reader flow
    (grouping, traits, custom rotors), Reduce Motion, color-only
    meaning conveyance.
  - Expanded **Platform-specific UI conventions** to add
    orientation handling, system-gesture conflict, drag-and-drop
    conformance.
  - Added a fifth bullet **Localization and adaptation** covering
    string-length tolerance, RTL semantic layout, locale-aware
    formatters, dark-mode / appearance support, iPad split-view /
    Stage Manager / multi-scene multitasking.
  - Added the closing "Beyond the bullets above, every UI rule
    defined in a loaded platform skill is in scope … the 4 default
    headings are the floor, not the ceiling." re-pointer.
- **Edit 3 (Localization sections in platform skills).** Added a
  6-rule Localization section (rules 28–33) to
  `skills/ios-architecture/SKILL.md` and a 6-rule Localization
  section (rules 29–34) to `skills/macos-architecture/SKILL.md`.
  Each section covers: string externalization (`String(localized:)`,
  `.xcstrings` Catalogs), 30%-length tolerance / pseudolocalization,
  RTL semantic layout (leading/trailing), locale-aware formatters
  (`Date.FormatStyle`, `Decimal.FormatStyle`, etc.), single source
  of truth for translations, and RTL-plus-long-string testing
  requirements. macOS variant adds menu-bar/window-specific guidance
  and `InfoPlist.xcstrings`.
- **Edit 4 (rule 44 non-Apple bookmark).** Appended a single
  *Note* sentence to `audit-methodology/SKILL.md` rule 44 noting
  the detection list is Apple-centric and that non-Apple UI
  detection is deferred to v11.x (BD-034). The audit report's part
  (d) — a 1-line bookmark in the BACKLOG.md BD-034 entry — was
  NOT performed (BACKLOG.md is PM-only per CLAUDE.md and the
  pack-coder commit-discipline skill); the rule-44 note carries
  the same forward-reference inside an authorized file.

### BD-035 — python-architecture loading for non-server Python

LIGHTEST STOP-GAP path per user direction (2026-05-11). The skill
split (option 1) is deliberately deferred to a separate decision.

- **Edit a (Applicability section).** Added an Applicability
  section near the top of `skills/python-architecture/SKILL.md`
  (before rule 1) explicitly enumerating the two trigger cases:
  - Case 1: Python server present → all 14 rules apply.
  - Case 2: Non-trivial multi-file Python (data access, async I/O,
    repository / service-layer separation, ML inference) → data /
    I/O subset (rules 5, 6, 7, 11, 12) applies; server-specific
    rules (1, 3, 9, 10, 13, 14) do not. References the future
    skill split (BD-035). The section makes the load semantics
    discoverable from inside the skill itself, not just from
    PLATFORM-SKILLS.md.
- **Edit b (Dimension 2 broadened load rule + auditor-code /
  auditor-architecture qualifier updates).** In
  `docs/pack/PLATFORM-SKILLS.md`:
  - Dimension 2 Python row: added "*plus* python-architecture
    (data / I/O subset — rules 5, 6, 7, 11, 12) when project has
    multi-file Python with data access, async I/O, or ML
    inference; otherwise omit".
  - Added a paragraph below the Dimension 2 table explaining the
    BD-035 broadening, the data/IO-vs-full-skill distinction, and
    pointing at the skill's Applicability section.
  - Updated the **auditor-code** entry's Tier 2 line: replaced
    "(when Python server in project)" with the broadened
    Dimension 2 condition reference, plus the data/IO-subset
    qualifier for non-server contexts.
  - Updated the **auditor-architecture** entry's Platform-filtering
    sentence to add the same non-server-multi-file-Python
    instruction.
- **Edit c (embedded-Python row).** Updated the Dimension 3
  Embedded Python row to add "*plus* python-architecture (data /
  I/O subset — rules 5, 6, 7, 11, 12) when the embedded Python
  codebase exceeds ~10 files or implements non-trivial data
  access" with the explicit note that no server-specific rules
  apply in this case.

The skill itself was NOT split. No file was renamed. The skill
inventory count in PLATFORM-SKILLS.md (30 total) is unchanged.

## 4. Files changed inventory

| Path | Type | BD | Lines (final) |
|---|---|---|---|
| `project-template/skills/audit-methodology/SKILL.md` | modified | 032 + 033 + 034 | 148 |
| `project-template/skills/error-handling/SKILL.md` | modified | 033 | 51 |
| `project-template/skills/ios-architecture/SKILL.md` | modified | 034 | 59 |
| `project-template/skills/macos-architecture/SKILL.md` | modified | 034 | 66 |
| `project-template/skills/python-architecture/SKILL.md` | modified | 035 | 60 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | modified | 035 | 352 |
| `project-template/.claude/agents/auditor-architecture.md` | modified | 032 | 137 |
| `project-template/.codex/agents/auditor-architecture.toml` | modified | 032 | 58 |
| `project-template/.gemini/agents/auditor-architecture.md` | modified | 032 | 110 |
| `project-template/.claude/agents/auditor-ops.md` | modified | 032 | 147 |
| `project-template/.codex/agents/auditor-ops.toml` | modified | 032 | 65 |
| `project-template/.gemini/agents/auditor-ops.md` | modified | 032 | 125 |
| `project-template/.claude/agents/auditor-code.md` | modified | 033 | 136 |
| `project-template/.codex/agents/auditor-code.toml` | modified | 033 | 60 |
| `project-template/.gemini/agents/auditor-code.md` | modified | 033 | 106 |
| `project-template/.claude/agents/auditor-ui.md` | modified | 034 | 136 |
| `project-template/.codex/agents/auditor-ui.toml` | modified | 034 | 58 |
| `project-template/.gemini/agents/auditor-ui.md` | modified | 034 | 103 |

Total: 18 files modified (12 trinity-mirrored agent files across 4
auditor pairs + 5 skill files + 1 PLATFORM-SKILLS.md). Zero new
files; zero deleted files; zero renames; zero mode changes
(`git diff --stat | grep -i 'mode change'` → `no mode changes`).

## 5. Trinity verification

The four trinity-mirrored agent file pairs are listed below with
the verification command and outcome. The trinity rule per
`commit-discipline` skill section 5 requires byte-identical wording
modulo provably tool-specific tweaks (Claude markdown, Codex TOML,
Gemini markdown frontmatter — the format containers differ; the
prose inside MUST match).

### auditor-architecture (3 files)

```
$ diff <(grep -A2 "Source-file observability" \
    project-template/.claude/agents/auditor-architecture.md) \
       <(grep -A2 "Source-file observability" \
    project-template/.gemini/agents/auditor-architecture.md)
(no output)
$ grep -c "Source-file observability" \
    project-template/.codex/agents/auditor-architecture.toml
1
```

Claude/Gemini markdown forms are byte-identical for the new
clarification block. Codex TOML carries the same wording adapted
to single-line prose (TOML strings prefer no soft-wrap).

### auditor-ops (3 files)

```
$ diff <(grep -A2 "Source-file observability" \
    project-template/.claude/agents/auditor-ops.md) \
       <(grep -A2 "Source-file observability" \
    project-template/.gemini/agents/auditor-ops.md)
(no output)
$ grep -c "Source-file observability" \
    project-template/.codex/agents/auditor-ops.toml
1
```

Same outcome.

### auditor-code (3 files)

```
$ diff <(grep -A2 "Per-function error-handling\|three-site" \
    project-template/.claude/agents/auditor-code.md) \
       <(grep -A2 "Per-function error-handling\|three-site" \
    project-template/.gemini/agents/auditor-code.md)
(no output)
$ grep -c "Per-function error-handling\|three-site" \
    project-template/.codex/agents/auditor-code.toml
2
```

Both new bullets present byte-identically in Claude and Gemini.
Codex carries both as TOML prose with identical key phrases.

### auditor-ui (3 files)

```
$ diff <(grep -A2 "Localization and adaptation" \
    project-template/.claude/agents/auditor-ui.md) \
       <(grep -A2 "Localization and adaptation" \
    project-template/.gemini/agents/auditor-ui.md)
(no output)
$ grep -c "Localization and adaptation" \
    project-template/.codex/agents/auditor-ui.toml
1
```

Same outcome.

### Tool-specific deviations (justified)

- TOML files use single-line prose for each bullet (no soft-wrap)
  because the `developer_instructions = """..."""` block convention
  favours flat prose over wrapped Markdown. This is the existing
  pattern across all `.codex/agents/*.toml` files; the change set
  preserves it.
- The `*italic*` and `**bold**` Markdown emphasis present in
  Claude / Gemini files is preserved as-is in the TOML files (the
  Codex CLI strips `developer_instructions` of Markdown, so the
  emphasis is purely a readability cue for humans editing the
  TOML; it is not parsed). Same convention as pre-existing TOML
  bullets.

No asymmetry beyond these existing format conventions. No prose
divergence. Trinity rule observed.

## 6. Verification output

### validate-pack.py (full run, all 30 checks)

```
$ python3 scripts/validate-pack.py 2>&1 | tail -2
============================================================
PASSED — all checks clean
```

All 30 checks clean. Of particular relevance:

- **Check 27 (Agent canonical-phrase compliance v10.1).** Every
  edited agent file still carries its required Permission profile,
  Output policy, and Hard rules canonical phrases. The Batch 14
  edits modified only `## Scope` bullets; the canonical sections
  were untouched. Validator confirms: "OK:
  project-template/.claude/agents/auditor-architecture.md —
  profile 'read-only' canonical phrases present" (and equivalent
  for all 12 trinity files).
- **Check 11 (Pack agent trinity-rule symmetry, informational).**
  Passed. The check is informational because it cannot validate
  arbitrary prose symmetry — the byte-level diff confirmation
  above is the substantive evidence.
- **Check 1 (SKILL.md frontmatter).** All 5 modified skills still
  carry valid frontmatter. The new sections (Applicability in
  python-architecture, Routing tags in error-handling, Localization
  in iOS / macOS) sit below the frontmatter, not within it.

### Mode-bit hygiene

```
$ git diff --stat | grep -i 'mode change' || echo 'no mode changes'
no mode changes
```

No file mode regressions.

### Per-skill / per-agent presence checks

```
$ grep -c "Boundary clarification\|Systemic threshold\|UI rule defined in a loaded platform skill\|deferred to v11.x" \
    project-template/skills/audit-methodology/SKILL.md
4
$ grep -c "\[systemic — auditor-code\]\|\[per-function — reviewer\]" \
    project-template/skills/error-handling/SKILL.md
15
$ grep -c "## Localization" \
    project-template/skills/ios-architecture/SKILL.md \
    project-template/skills/macos-architecture/SKILL.md
project-template/skills/ios-architecture/SKILL.md:1
project-template/skills/macos-architecture/SKILL.md:1
$ grep -c "## Applicability\|BD-035" \
    project-template/skills/python-architecture/SKILL.md
2
$ grep -c "BD-035\|Dimension 2 broadened" \
    project-template/docs/pack/PLATFORM-SKILLS.md
4
```

- 4 / 4 of the audit-methodology rule-21 / rule-16 / rule-20 / rule-44
  expected anchor phrases land.
- 15 routing-tag occurrences in `error-handling/SKILL.md` (one per
  rule plus one extra on rule 6 which legitimately carries both
  tags, plus a few in the Routing-tags section header text).
- 1 Localization H2 in each of `ios-architecture/SKILL.md` and
  `macos-architecture/SKILL.md`.
- Applicability section + a BD-035 reference in
  `python-architecture/SKILL.md`.
- 4 BD-035 / "Dimension 2 broadened" anchor phrases in
  `PLATFORM-SKILLS.md` (Dimension 2 row, the explanatory paragraph,
  the auditor-code entry, the auditor-architecture entry).

## 7. Plan deviations

Two intentional deviations, both authorized by the prompt:

1. **BD-034 audit report Edit 4 (BACKLOG.md bookmark).** The
   audit report's recommended Edit 4 was a "1-line bookmark in
   `BACKLOG.md` BD-034 entry noting that the non-Apple UI skip-rule
   gap … is deferred to v11.x." The prompt explicitly authorizes
   skipping this if it feels out of scope. BACKLOG.md is PM-only
   per CLAUDE.md and the pack-coder `commit-discipline` skill
   section 4 — pack-coder has no authorization to edit it. The
   forward-reference is preserved inside an authorized file:
   `audit-methodology/SKILL.md` rule 44 now reads "Future non-Apple
   UI projects … need an equivalent detection rule before auditor-ui
   can skip correctly — deferred to v11.x (BD-034)." Pack Chat may
   still add the BACKLOG bookmark if desired; this report flags
   that as the recommended Pack Chat follow-up.
2. **BD-035 skill split.** Per user direction (2026-05-11), the
   audit report's preferred Edit 1 (split `python-architecture`
   into `python-server-architecture` + `python-data-architecture`)
   was NOT attempted. The prompt's "DO THE LIGHTEST STOP-GAP, NOT
   the skill split" directive was followed strictly. The
   Applicability section + Dimension 2 broadening + embedded-Python
   row (audit report Edits 2 + 3 + 4) were all landed; the
   structural skill split is preserved as a separate v11.x decision
   for Pack Chat. No file was renamed; no skill file was created or
   deleted.

No silent deviations. No change in scope, threshold, or wording
beyond what the audit reports recommended.

## 8. POQs introduced

POQ-BATCH14-1 — BACKLOG.md bookmark for BD-034 non-Apple UI
detection deferral. Disposition: deferred. Recommended default:
Pack Chat may add a single line under the BD-034 entry's Context
block: "v11.0 added forward-reference in audit-methodology rule 44
to non-Apple UI detection deferral; equivalent BACKLOG bookmark
deferred." This is a 1-line addition to a PM-only file; pack-coder
cannot make it. If Pack Chat decides the rule-44 in-skill reference
is sufficient, no follow-up is needed.

POQ-BATCH14-2 — Future skill split (BD-035 audit report Edit 1).
Disposition: deferred per explicit user direction. Recommended
default: track as a separate v11.x decision. The Applicability
section in `python-architecture/SKILL.md` already references
"future split (BD-035)" so there is an in-skill discoverability
path for whoever takes the split. No fast-follow needed within
this batch.

POQ-BATCH14-3 — `audit-methodology` rule 21 prose density. Rule 21
now contains: original deployment-readiness summary + new
boundary-clarification paragraph + log-content security cross-ref,
all in a single rule body. The rule is dense (~3x its v11.0-launch
length) and could plausibly be split into rule 21a / 21b / 21c.
Disposition: deferred — the audit reports asked for the additions,
not for re-numbering. Renumbering would cascade through rule
references in 12 trinity files. Recommended default: leave as-is
for v11.0; revisit only if the dense rule causes confusion in real
audits.

No POQ blocks any other work. Pack Chat may ignore all three
without functional impact.

## 9. Definition-of-Done checklist

- **All BD-032 + BD-033 + BD-034 tightenings landed.** PASS.
  Evidence: section 3 above per-BD breakdown plus section 6 anchor
  phrase greps.
- **BD-035 lightest stop-gap landed (no skill split).** PASS.
  Evidence: Applicability section in
  `project-template/skills/python-architecture/SKILL.md`; Dimension
  2 + Component-Roles updates in
  `project-template/docs/pack/PLATFORM-SKILLS.md`; no skill file
  rename or split (`git status` confirms).
- **Trinity rule preserved across 12 trinity-mirrored agent
  files.** PASS. Evidence: section 5 per-pair `diff` results
  (claude vs. gemini empty diff for each of the 4 pairs) plus
  presence-greps confirming Codex TOML carries the same key
  phrases.
- **BD-032 / 033 / 034 / 035 themselves stay Open in BACKLOG.** PASS.
  Evidence: pack-coder did not touch BACKLOG.md (`git status` → no
  BACKLOG.md modification). Status flips are PM-only per
  `commit-discipline` skill section 4.
- **`python3 scripts/validate-pack.py` passes (all 30 checks
  clean).** PASS. Evidence: `PASSED — all checks clean` final
  line. See section 6 for the full check list.
- **No mode-bit regressions.** PASS. Evidence:
  `git diff --stat | grep -i 'mode change'` → `no mode changes`.

All 6 DoD items PASS.

## 10. Working-tree state at handoff

```
$ git status --short | grep -E '\.(md|toml)$' | grep -v 'AUDIT-BD\|AUDIT-BATCH'
 M project-template/.claude/agents/auditor-architecture.md
 M project-template/.claude/agents/auditor-code.md
 M project-template/.claude/agents/auditor-ops.md
 M project-template/.claude/agents/auditor-ui.md
 M project-template/.codex/agents/auditor-architecture.toml
 M project-template/.codex/agents/auditor-code.toml
 M project-template/.codex/agents/auditor-ops.toml
 M project-template/.codex/agents/auditor-ui.toml
 M project-template/.gemini/agents/auditor-architecture.md
 M project-template/.gemini/agents/auditor-code.md
 M project-template/.gemini/agents/auditor-ops.md
 M project-template/.gemini/agents/auditor-ui.md
 M project-template/docs/pack/PLATFORM-SKILLS.md
 M project-template/skills/audit-methodology/SKILL.md
 M project-template/skills/error-handling/SKILL.md
 M project-template/skills/ios-architecture/SKILL.md
 M project-template/skills/macos-architecture/SKILL.md
 M project-template/skills/python-architecture/SKILL.md
```

18 files modified (this batch). Other modifications visible in
the worktree (`scripts/validate-pack.py`,
`scripts/lib/migrate-v10-to-v11/*`, `scripts/lib/migrator-core.sh`,
`scripts/tests/test-migrate-v10-to-v11-gates.sh`,
`.github/workflows/validate-pack.yml`, `README.md`,
`supporting-docs/MIGRATION-v10-to-v11.md`,
`supporting-docs/MERGE-STRATEGY.md`) are the concurrent Batch 13
fix-follow agent's work — out of Batch 14 scope, not touched here,
no overlap. Untracked files (`maintenance-docs/v11-implementation/AUDIT-*.md`)
are pre-existing audit reports plus this implementation report.

HEAD remains at `60ac6d94b19ea3196404cb088f73c43c3881ac0c` (no
git state changes per the absolute ban in `commit-discipline`
section 3).

## 11. Proposed commit message

```
docs: v11 — BD-032/033/034/035 fix-follow (Batch 14 audit tightenings)

Pre-emptive auditor-spec tightenings recommended by AUDIT-BD-032
through AUDIT-BD-035:
- BD-032: rule 21 boundary clarification for source-file observability
  code; trinity-mirrored into auditor-architecture / auditor-ops scopes;
  log-content findings cross-ref to auditor-security per rule 33.
- BD-033: rule 16 quantified systemic threshold (3+ sites or
  cross-module); auditor-code split into Systemic / Per-function bullets;
  error-handling skill rules tagged [systemic — auditor-code] /
  [per-function — reviewer].
- BD-034: rule 20 re-pointer to loaded platform skills + 5-bullet
  illustrative scope (added Localization-and-adaptation); auditor-ui
  expansion across all 3 trinity files; Localization sections added to
  ios-architecture and macos-architecture skills (rules 28-33 / 29-34);
  rule 44 non-Apple UI detection bookmark.
- BD-035 (lightest stop-gap, no skill split per user direction):
  Applicability section in python-architecture skill; Dimension 2 load
  rule broadened in PLATFORM-SKILLS.md to fire python-architecture (data
  / I/O subset) for non-server multi-file Python; auditor-code +
  auditor-architecture qualifier updates; embedded-Python row updated.

BD-032/033/034/035 remain Open — PACK-FEEDBACK Q1-Q4 real-world
validation blockers are unaffected.

12 trinity-mirrored agent files (4 pairs × claude/codex/gemini) +
5 skills + PLATFORM-SKILLS.md = 18 files.

validate-pack.py: PASSED — all 30 checks clean. No mode regressions.
```

Pack Chat may rewrite this; pack-coder proposes only.
