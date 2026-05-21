# IMPLEMENTATION-REPORT — BD-178

**Branch:** v11-dev
**Base HEAD (pre-edit):** `3870f1cbbec61652cd7dc809b366dd8e22c21ad2`
**Final HEAD:** `3870f1cbbec61652cd7dc809b366dd8e22c21ad2` (unchanged — no state-changing git verbs run; working-tree edits only)
**Date:** 2026-05-20
**BD:** BD-178 — Align pre-existing trinity asymmetries in `project-template/{CLAUDE,AGENTS,GEMINI}.md` + absorbed POQ-F4-3

## §1 Summary

BD-178 converged 3 known pre-existing asymmetric loci in
`project-template/{CLAUDE,AGENTS,GEMINI}.md` to the canonical wording
specified in the BD-178 entry (per-locus proposals + reasoning baked in),
applied 2 additional wording-equivalent convergences surfaced by the fresh
3-way diff sweep (per the General canonicalization heuristic), and absorbed
POQ-F4-3 by adding a 1-paragraph "Tier 0 installation note" to the Skill
loading section in all 3 trinity files. The note explains the
`stage_s4_skills()` auto-distribution mechanism (gap in the existing
language) while cross-referencing the existing Tier 0 loading mention
(precedence preserved, not duplicated). Decline-precedence rationale:
existing Skill-loading paragraph covers Tier 0 *loading* semantics but
NOT *install-time auto-distribution* — the F4-3 note fills the
auto-distribution gap.

Final trinity 3-way diff metrics:
- CLAUDE.md vs AGENTS.md: 256 → 248 lines (-8; the convergence at locus 3
  removed 1 logical asymmetry, locus 5 (PLATFORM_TESTING) removed 1, and the
  POQ-F4-3 paragraph added byte-identically across both so produces no diff)
- CLAUDE.md vs GEMINI.md: 156 → 123 lines (-33; loci 1+2+4+5 + POQ-F4-3 all
  collapsed GEMINI-only divergence)
- AGENTS.md vs GEMINI.md: 280 → 247 lines (-33; same loci converged)

All remaining diff is provably tool-specific (file identity headers,
tool-specific skill paths, GEMINI-only Agent roster + Gemini CLI operating
notes sections, AGENTS-specific conciseness style, etc.) — these are NOT
trinity violations per the Trinity rule's "asymmetry requires justification
as provably tool-specific" carve-out. Full surfacing in §5.

## §2 Files changed

| Path | Type | Δ lines | Notes |
|---|---|---|---|
| `project-template/CLAUDE.md` | modified | +9/-1 | Locus 5 (PLATFORM_TESTING wording) + POQ-F4-3 Tier 0 installation note paragraph |
| `project-template/AGENTS.md` | modified | +9/-1 | Locus 3 (phase-routing intro) + POQ-F4-3 Tier 0 installation note paragraph |
| `project-template/GEMINI.md` | modified | +21/-9 | Locus 1 (trinity rule bullet) + Locus 2 (no destructive) + Locus 4 (Project memory intro) + POQ-F4-3 Tier 0 installation note paragraph |
| `test-fixtures/manifest.txt` | modified | +3/-3 | v11-* SHAs drift per RC9; v10-* + existing-* unchanged |

Total: 4 modified files. No new files. No deleted files.

## §3 3 known loci convergence (per BD-178 entry §"Known asymmetric loci")

### Locus 1 — Trinity rule bullet (`project-template/` § Project memory)

**Decision:** adopt CLAUDE.md + AGENTS.md form into GEMINI.md (per BD-178 entry proposal).

**BEFORE (GEMINI.md ~L347-349):**
```
- **Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or
  `GEMINI.md` at the project root, the same change applies to all
  three. Asymmetry requires justification as provably tool-specific.
```

**AFTER (GEMINI.md L357-360):**
```
- **Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or
  `GEMINI.md` at the project root, the same change applies to all
  three in the same set of edits. Symmetry is the default;
  asymmetry requires justification as provably tool-specific.
```

**CLAUDE.md L362-365 + AGENTS.md L338-341 unchanged** (already canonical).

Restores the load-bearing "in the same set of edits" operational constraint
(prevents trinity drift across commits) and the "Symmetry is the default"
framing principle (burden of proof on the asymmetry, not the symmetry).

### Locus 2 — "No destructive operations" bullet (`project-template/` § Project memory)

**Decision:** adopt CLAUDE.md + AGENTS.md form into GEMINI.md (per BD-178 entry proposal).

**BEFORE (GEMINI.md ~L350-353):**
```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, deletion, overwrite, or `git reset --hard`,
  state what will be destroyed and wait for explicit approval — even
  when the overall task is approved.
```

**AFTER (GEMINI.md L361-364):**
```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
```

**CLAUDE.md L366-369 + AGENTS.md L342-345 unchanged** (already canonical).

Adopts "file deletion" (more specific than bare "deletion" which could
ambiguously refer to database rows, log lines, branches, etc.) and
"state exactly what will be destroyed" (more enforceable — vague paraphrases
like "I'll clean up" are not acceptable).

### Locus 3 — Phase-routing intro line (`project-template/` § Phase routing)

**Decision:** adopt CLAUDE.md + GEMINI.md form into AGENTS.md (per BD-178 entry proposal).

**BEFORE (AGENTS.md ~L366):**
```
Both Codex and Claude Code can execute any engineering phase in this repo.
```

**AFTER (AGENTS.md L373):**
```
All three tools (Claude Code, Codex, Gemini CLI) can execute any phase.
```

**CLAUDE.md L396 + GEMINI.md L391 unchanged** (already canonical).

Updates the stale two-tool framing to the current three-tool trinity
(Gemini CLI added during v10 era). Correctness defect, not style preference.
The shorter "any phase" is also cleaner (no information loss — context is
established by the section heading "Phase routing — default agent
assignments").

## §4 POQ-F4-3 note placement (per BD-178 entry §"POQ-F4-3 absorbed scope")

**Decline-precedence analysis:** The existing "Skill loading" section in
each trinity file already mentions Tier 0 base skills via the phrase
"Tier 0 base skills (loaded for every project, every agent)". This covers
the loading semantics — i.e., that Tier 0 skills load by default. However,
it does NOT mention:
- The `stage_s4_skills()` install-time auto-distribution mechanism
- That pack-template `project-template/skills/` source-of-truth is
  physically copied/synced to client `.claude/skills/`, `.codex/skills/`,
  and `.gemini/skills/`
- The BD-142 anchor for the every-agent-default-loading rule
- The `boundary-investigation` Tier 0 skill (the F4 bundle addition that
  motivated this note)

Therefore the note is NOT duplicative — it fills an explicit gap in the
existing language. Applied per trinity lockstep (byte-identical across all
3 files).

**Section chosen:** `## Skill loading` (existing section in all 3 trinity
files — natural placement immediately after the existing "Tier 0 base
skills" mention paragraph and before the "Active skills:" paragraph).

**Note text (byte-identical across all 3 trinity files):**

```
**Tier 0 installation note.** Skills at `project-template/skills/` in the
pack repo are auto-distributed to all three client CLI skill directories
(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
at install time; the Tier 0 base list is then loaded by every agent for every
project per BD-142. See `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" and the
`boundary-investigation` Tier 0 skill for the canonical reference.
```

**Placement verification:**
- CLAUDE.md L191
- AGENTS.md L175
- GEMINI.md L186

All 3 placements immediately follow the existing
"See `docs/pack/PLATFORM-SKILLS.md` for the authoritative D1–D5 tables,
the Tier 0 base list, the sparse intersection table, and the
trigger-loaded list." paragraph — natural topical placement.

## §5 Fresh 3-way diff sweep results

Sweep methodology: full `diff` across all 3 pairings
(CLAUDE↔AGENTS, CLAUDE↔GEMINI, AGENTS↔GEMINI) of
`project-template/{CLAUDE,AGENTS,GEMINI}.md`. Reviewed all 3 diff outputs
in full (~700 combined lines) for asymmetries beyond the 3 known loci.
Outcome: 2 additional wording-equivalent asymmetries surfaced and applied
under the General canonicalization heuristic; the rest of the diff content
is provably tool-specific (intentional, not subject to alignment per the
Trinity rule).

### Additional asymmetry 4 — Project memory section intro (CLAUDE/AGENTS vs GEMINI)

**Decision:** apply CLAUDE.md + AGENTS.md form to GEMINI.md per General
canonicalization heuristic (wording-equivalent; CLAUDE-first preference;
CLAUDE/AGENTS form is more explicit about "in this project" + "regardless
of agent role").

**BEFORE (GEMINI.md ~L340-345):**
```
These rules govern every agent invocation. Each agent's full operating
rules (Permission profile, Output policy, Hard rules) live in its own
definition file under `.claude/agents/<agent>.md`,
`.codex/agents/<agent>.toml`, and `.gemini/agents/<agent>.md` — the
agent file is authoritative. This section carries only universal
collaboration rules that apply project-wide.
```

**AFTER (GEMINI.md L347-354):**
```
These rules govern every agent invocation in this project. Each
agent's full operating rules (Permission profile, Output policy,
Hard rules) live in its own definition file under
`.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, and
`.gemini/agents/<agent>.md`. The agent file is authoritative for
what that agent may and must do; this section carries only the
universal collaboration rules that apply project-wide regardless
of agent role.
```

**Reasoning:** wording-only stylistic delta with no precision/policy delta
(both forms convey the same rules). Per BD-178 entry General canonicalization
heuristic: "If two variants are equally valid (wording-only stylistic
differences with no precision delta), prefer the CLAUDE.md form for
consistency with the pack-repo's existing CLAUDE-first convention." The
CLAUDE/AGENTS form is also slightly more explicit ("in this project",
"regardless of agent role") which reinforces the universal-applicability
framing intended by the section.

### Additional asymmetry 5 — `[PLATFORM_TESTING]` marker wording (CLAUDE vs AGENTS/GEMINI)

**Decision:** apply AGENTS.md + GEMINI.md form to CLAUDE.md (deviation from
CLAUDE-first default — overridden by stronger consistency signal: this
brings CLAUDE.md into alignment with its OWN intra-file pattern, and the
2-vs-1 alignment side is AGENTS/GEMINI).

**BEFORE (CLAUDE.md ~L165):**
```
[PLATFORM_TESTING — fill in from testing skill]
```

**AFTER (CLAUDE.md L165):**
```
[PLATFORM_TESTING — fill in from loaded skills]
```

**AGENTS.md L149 + GEMINI.md L160 unchanged** (already canonical).

**Reasoning:** the previous CLAUDE.md wording "from testing skill" was
internally inconsistent with CLAUDE.md's own pattern for every other
`[PLATFORM_*]` marker, which use "from loaded skills":
- L83: `[PLATFORM_ARCHITECTURE — fill in from loaded skills]`
- L87: `[LANGUAGE_RULES — fill in from loaded skills]`
- L348: `[PLATFORM_ANTIPATTERNS — fill in from loaded skills]`

"Loaded skills" is also more accurate/general — multiple skills may
contribute platform testing content (e.g., `swift-best-practices`,
`apple-architecture-core`, plus any project-specific test skills), whereas
"the testing skill" implies a single canonical skill which doesn't match
the actual loading model. This is the rare case where General
canonicalization heuristic point (a) "more accurate" overrides CLAUDE-first
default — and the 2-vs-1 alignment side is AGENTS/GEMINI.

### Diff content reviewed and classified as provably tool-specific (NOT trinity violations)

The remaining ~120-250 lines of post-edit trinity diff are all
intentional tool-specific divergence — these are NOT trinity violations and
are NOT subject to alignment per the Trinity rule's "asymmetry requires
justification as provably tool-specific" carve-out:

1. **File identity headers** (`# CLAUDE.md` vs `# AGENTS.md` vs `# GEMINI.md`,
   "Copied from:" lines, intro paragraphs naming each tool) — required for
   each file to be self-identifying.
2. **Loading hierarchy phrasing** ("via the CLAUDE.md hierarchy" / "via
   the GEMINI.md hierarchy" — AGENTS.md has no equivalent because Codex
   does not have a hierarchical context-loading mechanism).
3. **Tool-specific skill paths** (`.claude/skills/<name>/` vs
   `.codex/skills/<name>/` vs `.gemini/skills/<name>/`) — physically
   required to match each tool's filesystem expectation.
4. **AGENTS.md style principle** — explicitly stated in AGENTS.md intro:
   "bodies may be more concise here, since the loaded skills carry the
   full detail." This is the deliberate AGENTS-conciseness contract that
   drives shorter bullets in Architecture, Dependencies, Antipatterns,
   Testing, Deferral comments, etc. Not a defect — it's a documented
   stylistic policy.
5. **GEMINI-only `## Agent roster` section** — explicitly marked as
   "Trinity-rule exception" in an inline HTML comment in the file:
   Gemini CLI auto-discovers agents via filesystem scan, but the explicit
   roster is a presentation aid for human readers of GEMINI.md.
6. **GEMINI-only `## Gemini CLI operating notes` section** —
   tool-specific operating notes (Session save/resume, /compress,
   save_memory, Approval mode, etc.) that have no Claude Code or
   Codex equivalent.
7. **AGENTS-specific BACKLOG write permissions table** — codifies
   write authority by agent role; AGENTS-specific elaboration choice.
8. **AGENTS-specific "Fill in or remove conditional sections" intro line
   variation** vs CLAUDE.md's more verbose tutorial guidance — CLAUDE.md
   intro has additional "Fill in the Platform and Stack Defaults section"
   + "(e.g., remove iOS 26 section...)" guidance which AGENTS+GEMINI omit
   per AGENTS.md's conciseness principle.
9. **CLAUDE.md `$XCODE_APP` env-var override on the iOS 26 docs path** —
   CLAUDE-specific because only Claude Code supports the env-block
   override in `.claude/settings.json`. AGENTS+GEMINI use the hardcoded
   `/Applications/Xcode.app` path.
10. **Bullet ordering variations** in "Style and discipline" section
    (final bullets ordered differently between CLAUDE / AGENTS / GEMINI) —
    no policy delta, but ordering is wording-equivalent and the existing
    variation falls within AGENTS-conciseness principle; not flagged as
    substantive.

All 10 categories above are valid pre-existing tool-specific divergence.
No additional alignment work is needed for any of them. No substantive
asymmetries (changes meaning/policy) were found that required
Pack-Chat-triage escalation.

## §6 Manifest regen evidence

Command run: `bash test-fixtures/build.sh --all --clean`

Result: all 6 fixtures rebuilt deterministically. v11-* SHAs drift as
expected (v11-* fixtures contain `project-template/` content which we
modified); v10-* + `existing-project-mid-dev` SHAs unchanged.

```
v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16    (unchanged)
v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258   (unchanged)
v11-realistic-ot  e7ddf08128edc087ea827d6724965dde6ff42d20 → ede6a325782d3c38150b72da7f804ff9ffe8dce2  (drift)
v11-flat-file  c7a5bc9d9815671c0ecfdaf0a8f5dbcbc7542095 → 76b6baadb489f2688873b20de142da4e92752324  (drift)
v11-tracker-on  544b8ebc24e8a701b2786b656a0d878aff1573ae → 0e258e522979ff2d79c02fc58418723bb7acb75d  (drift)
existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619  (unchanged)
```

git diff stat: `test-fixtures/manifest.txt | 6 +++---` (3 v11-* lines
swapped). Expected outcome per RC9.

## §7 validate-pack.py + 3 persona contract results

**validate-pack.py:** exit 0, all 39 checks PASS. Check 18 (Trinity H2
structure parity — BD-059) explicitly green:

```
── Check 18: Trinity H2 structure parity (BD-059) ──
  OK: CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)
```

The "GEMINI.md adds 2 intrinsic H2(s)" is the expected Trinity-rule
exception (Agent roster + Gemini CLI operating notes — both
tool-specific). Total sections match: 26 in CLAUDE.md / AGENTS.md;
26+2 in GEMINI.md.

**3 persona contracts (all GREEN):**

```
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
```

Total: 253 / 253 PASS.

## §8 Verification command output

| # | Command | Result |
|---|---|---|
| 1 | `git rev-parse HEAD` | `3870f1cbbec61652cd7dc809b366dd8e22c21ad2` (unchanged before+after) |
| 2 | Pre-edit `sed -n '345,375p' project-template/CLAUDE.md` | Confirmed pre-edit 3-locus state for CLAUDE.md |
| 2 | Pre-edit `sed -n '325,355p' project-template/AGENTS.md` | Confirmed pre-edit 3-locus state for AGENTS.md |
| 2 | Pre-edit `sed -n '340,370p' project-template/GEMINI.md` | Confirmed pre-edit 3-locus state for GEMINI.md |
| 3 | Pre-edit `diff project-template/CLAUDE.md project-template/AGENTS.md` | 256 lines (baseline) |
| 3 | Pre-edit `diff project-template/CLAUDE.md project-template/GEMINI.md` | 156 lines (baseline) |
| 3 | Pre-edit `diff project-template/AGENTS.md project-template/GEMINI.md` | 280 lines (baseline) |
| 4 | Post-edit `diff project-template/CLAUDE.md project-template/AGENTS.md` | 248 lines (-8 vs baseline) |
| 4 | Post-edit `diff project-template/CLAUDE.md project-template/GEMINI.md` | 123 lines (-33 vs baseline) |
| 4 | Post-edit `diff project-template/AGENTS.md project-template/GEMINI.md` | 247 lines (-33 vs baseline) |
| 5 | `grep -n "Tier 0 installation note\|in the same set of edits\|state exactly what will be destroyed\|All three tools (Claude Code, Codex, Gemini CLI) can execute any phase" project-template/*.md` | All 4 canonical phrases present in all 3 trinity files (12 hits) |
| 6 | `bash test-fixtures/build.sh --all --clean` | 6 fixtures built; manifest written |
| 6 | `git diff --stat test-fixtures/manifest.txt` | `1 file changed, 3 insertions(+), 3 deletions(-)` |
| 7 | `python3 scripts/validate-pack.py` | exit 0; "PASSED — all checks clean"; Check 18 OK |
| 7 | `bash scripts/persona-contracts/contract-greenfield.sh` | 191/191 PASS |
| 7 | `bash scripts/persona-contracts/contract-mid-dev.sh` | 25/25 PASS |
| 7 | `bash scripts/persona-contracts/contract-migration.sh` | 37/37 PASS |
| 8 | `git status --short` | 4 modified files (3 trinity + manifest) |
| 8 | `git diff --stat` | `4 files changed, 39 insertions(+), 15 deletions(-)` |
| 9 | `git rev-parse HEAD` (final) | `3870f1cbbec61652cd7dc809b366dd8e22c21ad2` (unchanged) |

## §9 PREFLIGHT line

```
PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD 3870f1cbbec61652cd7dc809b366dd8e22c21ad2; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md
```

## §10 Success criteria — Definition-of-Done checklist

| # | Criterion | PASS/FAIL |
|---|---|---|
| 1 | 3 known asymmetric loci converged to canonical wording per BD-178 entry's per-locus proposals — applied across all 3 project-template trinity files byte-identically (within-trinity parity at the relevant bullets) | PASS |
| 2 | Fresh 3-way diff sweep completed; any additional asymmetries found are either applied (wording-equivalent) or surfaced to Pack Chat (substantive) | PASS — 2 wording-equivalent asymmetries (Project memory intro + PLATFORM_TESTING marker) found + applied; zero substantive asymmetries surfaced |
| 3 | POQ-F4-3 informational note added per trinity-lockstep (or skipped with decline-precedence rationale documented) | PASS — added byte-identically in all 3 files (gap-filler, not duplicative; rationale in §4) |
| 4 | `test-fixtures/manifest.txt` regenerated; v11-* rows drift as expected (v10-* + existing-* unchanged) | PASS — 3 v11-* SHAs drifted; v10-* + existing-* row SHAs unchanged |
| 5 | `python3 scripts/validate-pack.py` exit 0 — all 39 checks PASS (including Check 18 H2 within-project-template-trinity parity) | PASS — exit 0; Check 18 explicit OK; 39/39 checks PASS |
| 6 | 3 persona contracts STILL GREEN | PASS — greenfield 191/191, mid-dev 25/25, migration 37/37 |
| 7 | Working tree at PREFLIGHT: exactly 4 modified files (3 trinity + manifest) + IMPL-REPORT | PASS — 4 modified, IMPL-REPORT created at expected path |
| 8 | No state-changing git verbs run | PASS — only `git status`, `git diff`, `git rev-parse` invoked (read-only) |
| 9 | PREFLIGHT line emitted before IMPL-REPORT write | PASS — emitted as standalone plain-text line preceding this Write call |

## §11 Plan deviations

None. The BD-178 entry specified per-locus proposals for the 3 known loci
(applied verbatim), authorized a fresh full 3-way diff sweep with General
canonicalization heuristic application (applied as authorized to 2
additional wording-equivalent asymmetries), and absorbed POQ-F4-3 with
explicit decline-precedence carve-out (decline-precedence analysis
performed and documented; note added as gap-filler, not duplicative).
Implementation matches plan scope exactly.

## §12 New POQs introduced

None. The fresh 3-way diff sweep surfaced ZERO substantive asymmetries
that would require Pack Chat triage. The 2 wording-equivalent extras
found (Project memory intro, PLATFORM_TESTING marker) were applied
under the General canonicalization heuristic per BD-178 entry's explicit
authorization for that pattern. The 10 categories of tool-specific
divergence enumerated in §5 are all pre-existing and intentional (per
Trinity rule's "asymmetry requires justification as provably
tool-specific" carve-out); none require new BDs.

## §13 Files-changed inventory

| Path | Change type |
|---|---|
| `project-template/CLAUDE.md` | modified (1 line wording + 7 lines added in Skill loading section) |
| `project-template/AGENTS.md` | modified (1 line wording + 7 lines added in Skill loading section + 1 line phase-routing) |
| `project-template/GEMINI.md` | modified (4 logical loci: trinity rule, no destructive, Project memory intro, plus 7 lines added in Skill loading section) |
| `test-fixtures/manifest.txt` | modified (3 v11-* SHA rows updated; v10-* + existing-* untouched) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md` | new (this report) |

End of BD-178 IMPL-REPORT.
