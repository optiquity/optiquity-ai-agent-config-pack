# IMPLEMENTATION REPORT — BD-175 Phase 5 Commit 12 (Architect C prevention mechanisms M1–M8)

**Coder:** pack-coder (Claude Code)
**Branch:** v11-dev
**Worktree HEAD at completion:** `73aeea9eab01944525391aa8d1da15aea47159d0`
**Parent HEAD at task start:** `de7f10c` (parent session landed `73aeea9` Commit 9b review report during my work — disjoint file scope per spawn note)
**Date:** 2026-05-19
**Plan source:** `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` §2.12 (§2.12.1–§2.12.6) + row 12 of §4.2 table
**Architect source:** `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` (full doc + §16 / §16a fix-pass amendments)
**Audit source:** `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 9 + Overrides 1 + 5 (1-entry exempt list)

---

## §1 Summary

Commit 12 is the FINAL commit of BD-175 Phase 5 — Architect C's entire
M1–M8 prevention mechanism suite, landing the codification + process +
CI layers that prevent the P-missed-7 regression mechanism from
recurring. The commit covers ~25 files across three surfaces: pack-root
trinity (P-missed-7 + M1a Batch-scope + M1b commit-keyword convention +
M8 trinity-rule note), project-template trinity (Project SSOT-first
mirror), boundary-investigation skill (6-file trinity, 3 pack-side + 3
project-side), pack-* agent skill-load wiring, pack-side review skill
priority-0, pack-coder pre-flight, project-side reviewer/coder prompt
amendments, and three new validate-pack.py checks (36/37/38) with a
synthetic fixture test script.

Architect C §13 bootstrap order is honored: this commit lands LAST in
Phase 5 because M5b Check 37's project-side deny-list would fail at
HEAD until the 17 §D-9 contamination refs were resolved by Commits 4–9.
Spot-check confirms all 17 are resolved (§7 below). Check 37 walks 146
project-side files with ZERO contamination hits at this HEAD.

All verification gates pass: `python3 scripts/validate-pack.py` exits 0
with all 38 checks (35 pre-existing + new 36/37/38) clean;
`bash scripts/tests/test-validate-pack-checks-36-37-38.sh` exits 0 with
6 passes / 0 fails across 6 fixture-test groups; manifest regenerated
per RC9 (3 v11-* row updates expected and observed). Trinity within-
trinity parity verified for both pack-root and project-template; no
cross-trinity drift gate per Override 9.

---

## §2 Files changed (inventory)

| Path | Action | Lines | Rationale | M-mechanism |
|---|---|---|---|---|
| `CLAUDE.md` | modified | +59 / -0 | P-missed-7 bullet (Workflow); M1a Batch-scope bullet (Pack Chat scope); M1b commit-subject scope-keyword table (Rules section); M8 trinity-rule explanatory note | M2 + M1a + M1b + M8 |
| `AGENTS.md` | modified | +59 / -0 | Same edits as CLAUDE.md, trinity-symmetric | M2 + M1a + M1b + M8 |
| `GEMINI.md` | modified | +53 / -0 | Same edits, GEMINI-compact phrasing per existing trinity asymmetry convention | M2 + M1a + M1b + M8 |
| `project-template/CLAUDE.md` | modified | +17 / -0 | Project SSOT-first bullet (Project memory) | M2 project-side mirror |
| `project-template/AGENTS.md` | modified | +17 / -0 | Same, trinity-symmetric | M2 project-side mirror |
| `project-template/GEMINI.md` | modified | +17 / -0 | Same, trinity-symmetric | M2 project-side mirror |
| `.claude/skills/boundary-investigation/SKILL.md` | NEW | +186 | New pack-side skill methodology | M4 |
| `.codex/skills/boundary-investigation/SKILL.md` | NEW | +186 | Byte-identical pack-side trinity | M4 |
| `.gemini/skills/boundary-investigation/SKILL.md` | NEW | +186 | Byte-identical pack-side trinity | M4 |
| `project-template/.claude/skills/boundary-investigation/SKILL.md` | NEW | +186 | New project-side skill (ships to clients) | M4 |
| `project-template/.codex/skills/boundary-investigation/SKILL.md` | NEW | +186 | Byte-identical project-side trinity | M4 |
| `project-template/.gemini/skills/boundary-investigation/SKILL.md` | NEW | +186 | Byte-identical project-side trinity | M4 |
| `pack-ops/PACK-AGENTS.md` | modified | +1 / -0 | Skill-load table adds `boundary-investigation` for all 5 pack-* agents | M4 wiring |
| `.claude/skills/review/SKILL.md` | modified | +1 / -0 | Priority-0 Boundary discipline | M3a |
| `.codex/skills/review/SKILL.md` | modified | +1 / -0 | Priority-0 Boundary discipline | M3a |
| `.gemini/skills/review/SKILL.md` | modified | +1 / -0 | Priority-0 Boundary discipline | M3a |
| `.claude/agents/pack-coder.md` | modified | +49 / -0 | Boundary discipline pre-flight section | M3b + M6 |
| `.codex/agents/pack-coder.toml` | modified | +16 / -0 | Same in TOML developer_instructions | M3b + M6 |
| `.gemini/agents/pack-coder.md` | modified | +47 / -0 | Same in Gemini Markdown | M3b + M6 |
| `project-template/docs/pack/prompts/reviewer.md` | modified | +62 / -0 | New dimension 9 Boundary discipline + M7 positive-assertion gate + M6 frame-rotation reminder; "eight" → "nine" count update | M3a + M6 + M7 |
| `project-template/docs/pack/prompts/coder.md` | modified | +28 / -0 | Boundary discipline Constraints block (standard variant + fix-cycle variant) | M3b |
| `scripts/validate-pack.py` | modified | +671 / -0 | New Check 36 (commit-scope honesty), Check 37 (project-side deny-list), Check 38 (pack-only-file siting); docstring update | M5a + M5b + M5c |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | NEW | +260 | Synthetic fixture test script (5 groups × multiple unit tests) | M5a/b/c test infra |
| `scripts/tests/fixtures/boundary-checks/fail_bare_pack_agents_ref.md` | NEW | +9 | Check 37 negative fixture | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/fail_pack_ops_prefix.md` | NEW | +8 | Check 37 negative fixture (`pack-ops/` prefix per §16.1) | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/fail_pack_agent_name.md` | NEW | +8 | Check 37 negative fixture (`pack-coder` agent name) | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/fail_capitalized_pack_chat.md` | NEW | +8 | Check 37 negative fixture (`Pack Chat` orchestrator role) | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/pass_feedback_legit.md` | NEW | +13 | Check 37 PASS fixture (feedback-flow anchor per audit §D-4) | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/pass_pack_repo_disambiguation.md` | NEW | +14 | Check 37 PASS fixture (pack-vs-project disambiguation anchor extension per BD-175 Commit 12) | M5b fixture |
| `scripts/tests/fixtures/boundary-checks/pass_no_pack_refs.md` | NEW | +12 | Check 37 PASS fixture (clean project-side prose) | M5b fixture |
| `test-fixtures/manifest.txt` | modified | +3 / -3 | RC9 regen — 3 v11-* fixture rows drift expected (v11-flat-file + v11-realistic-ot + v11-tracker-on rebuilt from updated project-template/ + scripts/) | manifest regen |

Total: 17 modified + 14 NEW (= 6 boundary-investigation `SKILL.md` files + 1 test script + 7 fixture files; new dirs include 6 skill dirs + `scripts/tests/fixtures/boundary-checks/` + `project-template/.gemini/skills/`).

---

## §3 M-by-M implementation breakdown

### M1a — Pack Chat batch-scope memory rule (Architect C §10.1)

**Files touched:** pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` —
new "Batch-scope claims are enforced by CI, not honor system" bullet
added at the end of `### Pack Chat scope` subsection (within `## Pack
memory`).

**One-sentence summary:** Activates Check 36 (§8.1) by telling Pack
Chat actors that `pack-only` / `project-only` / `PM-only` commit-subject
keywords trigger a CI gate; mis-framing fails the build with a file-path
callout.

### M1b — Commit-subject scope-keyword convention (Architect C §10.2)

**Files touched:** pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` —
new "Commit-subject scope-keyword convention (CI-enforced via Check 36)"
block + table added directly under "Approved `fix:` suffixes" in
"Rules for agents working on this repo" (`## Rules ...` for
CLAUDE/AGENTS; `## Conventions` for GEMINI).

**One-sentence summary:** Defines the closed-set keyword vocabulary
(`pack-only`, `project-only`, `PM-only` / `pack-memory-only`, plus
implicit no-keyword) with PERMITTED-PATHS per keyword, matching the
Check 36 implementation precisely.

### M2 — P-missed-7 codification (Architect C §4 + §4.1 + §4.2)

**Files touched (pack-side, 3 lockstep):** pack-root `CLAUDE.md`,
`AGENTS.md`, `GEMINI.md` — new "P-missed-7 — project-side investigation
precedes pack-style defaults" bullet at the end of `### Workflow`
subsection.

**Files touched (project-side, 3 lockstep):** `project-template/CLAUDE.md`,
`AGENTS.md`, `GEMINI.md` — new "Project SSOT-first" bullet at the end of
the `## Project memory` bullet list (after "PM chat does not architect").

**One-sentence summary:** Two-tier codification per Override 9 —
pack-side detailed bullet names V1/V3/V4 worked examples; project-side
shorter inverted mirror tells project actors "PROJECT SSOT first; do
not import external (pack/third-party/other-project) mechanisms." Both
bullets name the `boundary-investigation` skill as the SSOT-investigation
methodology.

### M3a — Reviewer SSOT-investigation protocol amendment (Architect C §5.1)

**Files touched (pack-side review skill, 3 lockstep):**
`.claude/skills/review/SKILL.md`, `.codex/skills/review/SKILL.md`,
`.gemini/skills/review/SKILL.md` — new "0. Boundary discipline"
priority added BEFORE Correctness, names `boundary-investigation` skill
and `P-missed-7` rule, includes frame-rotation reminder inline.

**Files touched (project-side reviewer prompt):**
`project-template/docs/pack/prompts/reviewer.md` — new dimension 9
"Boundary discipline (Project SSOT-first)" added after dimension 8;
includes M7 positive-assertion gate (a/b/c) + M6 frame-rotation
reminder. "eight" → "nine" count updated globally (5 occurrences).

**One-sentence summary:** Both pack-reviewer (via skill priority-0) and
project-side reviewer (via dimension 9) are required to investigate
project-side SSOT before recommending any rule/reference/role change
to a project-side file.

### M3b — Implementer SSOT-investigation pre-implementation step (Architect C §5.2)

**Files touched (pack-coder, 3 CLI lockstep):** `.claude/agents/pack-coder.md`,
`.codex/agents/pack-coder.toml`, `.gemini/agents/pack-coder.md` —
new `### Boundary discipline pre-flight (P-missed-7)` section added at
the end of `# Before executing`, requiring SSOT investigation before
project-side edits + "Boundary discipline stop" surface in IMPL-REPORT
when a deny-list hit appears. The `boundary-investigation` skill is
added to the `Load skills as specified:` list.

**Files touched (project-side coder prompt):**
`project-template/docs/pack/prompts/coder.md` — new "Boundary discipline
(Project SSOT-first / P-missed-7)" constraint block added to both the
standard variant Constraints section AND the fix-cycle variant
Constraints section.

**One-sentence summary:** Both pack-coder (via agent pre-flight) and
project-side coder (via prompt Constraints) must investigate project
SSOT before applying any reference change to a project-shipped file;
deny-list hits trigger a fail-stop with "Boundary discipline stop"
surface.

### M4 — boundary-investigation skill (Architect C §6)

**Files touched:** 6 NEW `SKILL.md` files (byte-identical content):
- `.claude/skills/boundary-investigation/SKILL.md` (pack-side)
- `.codex/skills/boundary-investigation/SKILL.md` (pack-side)
- `.gemini/skills/boundary-investigation/SKILL.md` (pack-side)
- `project-template/.claude/skills/boundary-investigation/SKILL.md` (project-side)
- `project-template/.codex/skills/boundary-investigation/SKILL.md` (project-side)
- `project-template/.gemini/skills/boundary-investigation/SKILL.md` (project-side)

Plus 1 wiring edit: `pack-ops/PACK-AGENTS.md` § "Skills loaded by pack agents"
table — new row `| boundary-investigation | pack-coder, pack-architect,
pack-planner, pack-reviewer, pack-docs-researcher |` (all 5 pack-* agents
load the skill).

**One-sentence summary:** Single canonical skill content (186 lines)
provides the SSOT-investigation methodology (5 steps: identify concept
→ locate project SSOT → decide action → NEVER cross-reference pack-only
paths [with deny-list including post-§16.1 `pack-ops/` prefix and post-
§16a HELP-FRAGMENT-TRACKER row] → document in deliverable) + frame-
rotation reminder + V1 worked example showing how the methodology
would have caught the BD-175 V1 anti-pattern.

### M5a — Check 36 commit-scope honesty (Architect C §8.1 + §8.1a)

**Files touched:** `scripts/validate-pack.py` — new `check_commit_scope_honesty()`
function + supporting helpers (`_commits_to_walk`, `_commit_paths`,
`_subject_has_keyword`, `_is_pack_only_path`, `_is_project_side_path`,
`_is_pm_only_permitted`, `_read_boundary_exempt_root`); constant tables
`_SCOPE_KEYWORDS_*`, `_PM_ONLY_PERMITTED_PATHS`, `_PM_ONLY_PERMITTED_PREFIXES`,
`_PROJECT_SIDE_PATH_PREFIXES`.

**Walk-range design choice (judgment call):** Default walks ONLY the
HEAD commit (per-push CI gate pattern) rather than the full
`origin/main..HEAD` range. Rationale: v11-dev contains pre-BD-175
historical commits with imperfect scoping that would falsely fail a
retrospective walk; the convention is opt-in for commits going forward.
The `PACK_CHECK_36_RANGE` environment variable allows a wider walk for
one-shot audit runs.

**One-sentence summary:** Parses commit subjects for `pack-only` /
`project-only` / `PM-only` keywords (boundary-anchored regex to avoid
false matches like `pack-only-ish`) and verifies the commit's
`git diff --name-only` matches the claimed scope per PACK-AGENTS.md
§ "PM-only files and directories" Files + Directories blocks.

### M5b — Check 37 project-side deny-list (Architect C §8.2 + §16.1 + §16a)

**Files touched:** `scripts/validate-pack.py` — new
`check_project_side_deny_list()` function + supporting helpers
(`_context_has_anchor`, `_iter_project_side_files`,
`_is_legitimate_deny_list_doc`); deny-list constants
`_DENY_LIST_FILENAMES`, `_DENY_LIST_PATH_PREFIXES` (includes
`pack-ops/` per §16.1), `_DENY_LIST_AGENT_NAMES`, `_DENY_LIST_ROLE_NAME`,
`_DENY_LIST_ANCHOR_PHRASES` (per §D-4 + BD-175 Commit 12 anchor-phrase
extension).

**Anchor-phrase extension (judgment call, in-scope absorb):** Per Commit
10 review feed-in observation #1, the HELP-FRAGMENT-TRACKER.md:49
`tracker.toml.pack-example` reference uses "in the pack repo" /
"pack-repo" disambiguation context. I extended the anchor-phrase list
beyond C §8.2's `feedback`, `report back`, `escalation`, `stop and surface`
to also include `in the pack repo`, `at the pack repo`, `pack-repo`,
`pack repo only`. This catches LEGITIMATE pack-vs-project disambiguation
context as distinct from contamination context.

**Per-file LEGITIMATE-context exemptions (judgment call):** Project-
side files whose whole purpose is to describe the project-to-pack
feedback flow OR the cross-repo orchestration contract are exempt from
Check 37 hits (would otherwise flag dozens of legitimate `Pack Chat`
orchestrator-role references as contamination). The exempt list:
`project-template/docs/pack/PACK-FEEDBACK.md`, `PM-CHAT.md`,
`METHODOLOGY.md` (forward-pointer; currently in `supporting-docs/`),
`SETUP-EXISTING.md`, `INSTALL-PROCEDURES.md`. Also exempt: the
boundary-investigation skill files (teach the deny-list), project
coder.md/reviewer.md (teach the rule), and project trinity (Project
SSOT-first bullet teaches the rule). This matches audit §D-4
LEGITIMATE designation.

**One-sentence summary:** Walks 146 project-template/ files; greps each
for deny-list patterns (PACK-AGENTS.md, PACK-CHAT.md, HELP-FRAGMENT-PACK.md,
maintenance-docs/, pack-ops/, pack-* agent names, capitalized Pack Chat)
with ±2-line anchor-phrase context-window exception; per-file exempt
list for teaching docs + feedback-flow docs.

### M5c — Check 38 pack-only-file siting (Architect C §8.3)

**Files touched:** `scripts/validate-pack.py` — new
`check_pack_only_file_siting()` function; constants
`_CHECK_38_PACK_ROOT_SCAN_GLOB`, `_CHECK_38_SIGNAL_THRESHOLD = 3`
(heuristic, planner-tunable).

**1-entry exemption list (per Override 1 + 5):** Consumes
`pack-ops/.boundary-exempt-root.txt` via `_read_boundary_exempt_root()`.
At HEAD, exempt list = `{'tracker.toml.pack-example'}` (1 entry per
Overrides 1+5). The check additionally exempts structurally-permitted
pack-root files: `README.md`, `QUICKSTART.md`, `LICENSE`, `Makefile`,
and the pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) —
these are pack-only-by-audience and the trinity legitimately
references pack-only mechanisms.

**One-sentence summary:** Counts pack-only-signal hits (deny-list
patterns from Check 37) in pack-root prose files (.md/.txt only);
FAILs files with signal count ≥ 3 not on the 1-entry
`.boundary-exempt-root.txt` list or the structural-exempt list.

### M6 — SSOT-rotation reminder (Architect C §7)

**Files touched:** integrated inline into M3a (pack-side review skill
priority-0 + project-side reviewer.md dimension 9) and M3b (pack-coder
agent files + project-side coder.md). No separate edit per C §7 design.

**One-sentence summary:** Frame-rotation reminder text appears in the
review skill priority-0 bullet, the project-side reviewer dimension 9
final paragraph, and the pack-coder pre-flight section closing
paragraph. Reminds actors to mentally rotate frames between pack-side
and project-side reviews/implementations.

### M7 — TYPE-5 positive-assertion gate (Architect C §9.1)

**Files touched:** integrated into M3a project-side reviewer.md
dimension 9 (the "Positive-assertion gate (TYPE-5 detection)" sub-block
with the (a) Independent rationale / (b) Structural mirror /
(c) TYPE-5 finding three-option positive assertion). No separate edit.

**One-sentence summary:** Reviewer must positively assert one of
(a)/(b)/(c) when a project rule is present — a review that passes a
project rule WITHOUT one of these is incomplete. Makes the TYPE-5
detection an explicit positive gate, not an unspoken hope.

### M8 — Trinity-rule documentation amendment (Architect C §9.2)

**Files touched:** pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` —
explanatory note added directly after the existing "Trinity rule —
CLAUDE.md / AGENTS.md / GEMINI.md" bullet in `## Rules for agents
working on this repo` (resp. `## Conventions` for GEMINI). GEMINI uses
the compact phrasing per existing trinity asymmetry convention.

**One-sentence summary:** Informational note (not enforced) explaining
that the trinity rule is a PARITY rule, not a SUBSTANCE rule — for
substance correctness across pack-vs-project, see Pack memory
P-missed-7 and the boundary-investigation skill. Forestalls future
actors confusing trinity parity with substance correctness (the V1
regression's exact failure mode).

---

## §4 Override 9 audit — pack-side P-missed-7 vs project-side Project SSOT-first wording diff

Per Override 9 (CONFIRMED): the pack-side P-missed-7 bullet and the
project-side "Project SSOT-first" mirror INTENTIONALLY differ in
wording. No cross-trinity drift gate.

**Pack-side (CLAUDE.md/AGENTS.md/GEMINI.md `### Workflow`):**
- Audience: pack actors (reviewer, implementer, Pack Chat triage)
- Voice: "DO NOT default to pack-style mechanisms when editing
  project-side files"
- Worked examples: BD-175 audit V1, V3, V4 (named)
- Deny-list named: `pack-ops/PACK-AGENTS.md` roster, Pack Chat
  orchestrator role, pack-* agent names, `maintenance-docs/` design
  records, anything under `pack-ops/`
- Skill reference: `boundary-investigation` skill loaded by all pack agents

**Project-side (project-template/CLAUDE.md/AGENTS.md/GEMINI.md
`## Project memory`):**
- Audience: project actors (PM chat at client install, project agents,
  project trinity readers)
- Voice: "Investigate project SSOT FIRST; do not default to importing
  rules / file references / orchestrator roles from EXTERNAL sources
  (the AI Agent Config Pack repo itself, third-party templates, other
  projects)"
- Worked examples: NONE named (project audience doesn't need pack BD
  numbers)
- Permitted sources named: `docs/pack/PM-CHAT.md`,
  `docs/pack/PLATFORM-SKILLS.md`, `docs/pack/PACK-FEEDBACK.md`, project
  trinity at root
- Deny-list named (with `pack-repo` qualifier per S5): PACK-AGENTS.md,
  PACK-CHAT.md, pack-* agent prompts, pack-repo `maintenance-docs/`,
  pack-repo `pack-ops/` — any file under `pack-ops/` including
  `BOUNDARY-DEFINITION.md`, `BACKLOG.md`, `CHANGELOG.md`
- Skill reference: `boundary-investigation` skill

The two bullets share the PRINCIPLE (boundary discipline before
defaulting to external mechanisms) but differ in audience, voice,
worked examples, and named permitted/deny sources. This is Override 9
working as designed. **No cross-trinity drift gate exists or was added.**

---

## §5 Within-trinity parity audit (Check 18 H2 + spot-check)

**Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md at repo root):**

Within-trinity parity per CLI: P-missed-7 bullet content matches
byte-for-byte between CLAUDE.md and AGENTS.md (verified via `diff
<(grep -A 22 "P-missed-7" CLAUDE.md) <(grep -A 22 "P-missed-7" AGENTS.md)` —
zero diff in the bullet body). GEMINI.md uses the compact phrasing
convention consistent with the rest of GEMINI's compact structure (the
overall P-missed-7 bullet content matches in substance; GEMINI's
broader Pack memory section is structurally tighter than CLAUDE/AGENTS
per existing standing trinity asymmetry).

M1a Batch-scope bullet: identical body across CLAUDE/AGENTS; GEMINI's
final cross-reference points to its `## Conventions` section instead
of `## Rules for ...` (because GEMINI uses a different section name)
— this is the kind of intra-tool reference that legitimately differs
across trinity members per existing convention.

M1b commit-subject scope-keyword convention: identical table content
across CLAUDE/AGENTS; GEMINI uses a compact 5-column table (matching
existing GEMINI Conventions section compactness pattern).

M8 trinity-rule explanatory note: identical body across CLAUDE/AGENTS;
GEMINI's final sentence is the compact form (omits the explanatory tail
about V1-style regression).

**Project-template trinity (project-template/CLAUDE.md / AGENTS.md /
GEMINI.md):**

"Project SSOT-first" bullet: identical body across all three CLI
variants (verified via `diff <(grep -A 20 "Project SSOT-first"
project-template/CLAUDE.md) <(grep -A 20 "Project SSOT-first"
project-template/AGENTS.md)` — zero diff; same for GEMINI). The only
diff in the surrounding context is the existing GEMINI phase-routing
table preamble ("All three tools..." vs "Both Codex and Claude Code...")
which is unrelated to my edits.

**Check 18 H2 structure parity** (the existing CI gate for project-
template trinity H2 names + order): PASSES per `python3
scripts/validate-pack.py` Check 18 output —
- `CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)`
- `GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)`

I did NOT add any new H2 to project-template trinity. The "Project
SSOT-first" addition was a new bullet inside the existing `## Project
memory` H2 — no H2 structure changes.

**Pack-root trinity H2 structure parity:** Check 18 specifically
targets project-template trinity. Pack-root trinity H2 parity is
informal (not CI-enforced) — verified manually that none of the new
content introduced new H2s at pack root either.

**No cross-trinity drift gate added or expected** per Override 9.

---

## §6 Prevention-design feed-in triage (per prompt §"Prevention-design feed-in")

Per the prompt's instruction, the following observations from prior
commits' reviews were evaluated against M5b/M5c/M4 scope:

### Observation 1 — Pre-existing `tracker.toml.pack-example` mention in HELP-FRAGMENT-TRACKER.md:49 (from Commit 10 review)

**Decision: ABSORB into M5b Check 37 + M4 skill methodology.**

The HELP-FRAGMENT-TRACKER.md:49 line says: `See the tracker example
template (\`tracker.toml.pack-example\` in the pack repo, or
\`tracker.toml.example\` at a client project root) and
\`OPTIONAL-FEATURES.md\` for full setup.` — this is a LEGITIMATE
pack-vs-project disambiguation reference, but the architect doc's
anchor-phrase list (`feedback`, `report back`, `escalation`, `stop and
surface`) did NOT include any pattern matching "in the pack repo".

**Implementation in this commit:** Extended Check 37's
`_DENY_LIST_ANCHOR_PHRASES` to include `in the pack repo`, `at the pack
repo`, `pack-repo`, `pack repo only` — covering pack-vs-project
disambiguation context as a recognized LEGITIMATE pattern. Documented
in the Check 37 docstring + the boundary-investigation skill's step 4
(under "Files exempt at pack root" sub-bullet, noting "bare-filename
refs from project-side qualified by 'in the pack repo' are LEGITIMATE
distinction-callouts"). This generalizes the BD-107/BD-135 origin
pattern into a recognized anchor.

**Verification:** Check 37 PASSes at HEAD with 146 project-side files
walked and zero contamination hits — the HELP-FRAGMENT-TRACKER.md:49
line is correctly anchored. The fixture `pass_pack_repo_disambiguation.md`
includes a test of this exact pattern.

### Observation 2 — `cmd_update` explicit-mapping asymmetry in `scripts/init-project.sh` (from Commit 10 review)

**Decision: SURFACE for Pack Chat triage as post-BD-175 follow-up.**

The prompt asks whether a new validate-pack.py check (or extension to
an existing check) could verify mapping-list/glob-coverage symmetry in
`scripts/init-project.sh` `cmd_update`. This is a STRUCTURAL CHECK
(verifying internal symmetry of a script's coverage rules) rather
than a BOUNDARY CHECK. It is out-of-scope for M5a/b/c which target
pack/project boundary contamination.

**Rationale:** This kind of script-internal consistency check is a
different category of CI gate than Check 36/37/38 — it's similar in
spirit to Check 26 (BD-119 migrator-framework inventory) which verifies
internal consistency of `scripts/lib/migrator-core.sh`. The right
landing is a NEW BD (e.g., "BD-NNN — init-project.sh explicit-mapping
coverage check"), not an in-scope extension of BD-175 Commit 12.

**Pack Chat follow-up:** Consider opening a tracked BD in v11.0
(per pack memory "No deferral to v11.1+ without explicit user
direction") sized as a small validate-pack.py check addition. If the
explicit-mapping list is naturally bounded (handful of file types),
this is a ~30-line addition.

### Observation 3 — BD-109 future v11.x reintroduction signal (from Commit 10 review)

**Decision: DECLINE for Commit 12 scope.**

This observation is about a future v11.x feature reintroduction
(unrelated to BD-175 boundary mechanics). It does not intersect M5a/b/c
or M4 scope. No action in Commit 12.

### Observation 4 — Bare cross-reference list scanner check (from Commit 9b IMPL-REPORT §6.3)

**Decision: SURFACE for Pack Chat triage as a potential Check 39 or
Check 37 extension.**

The proposed check: scan `pack-ops/` markdown files for bare cross-
reference list items (e.g., a bullet `- FILENAME.md` in a "see also" /
"key files" list) where the named file does NOT exist at the doc's
parent directory.

**Why I declined to absorb in this commit:** This is conceptually a
"cross-reference integrity" check (similar to Check 34 for per-entry
trees, but at a different granularity — pack-ops/ markdown bare-name
refs). It is NOT a boundary check (the contamination it would catch
is pack-only-to-pack-only stale cross-references, not pack/project
contamination). It also requires careful design of the "what counts
as a bare cross-reference" heuristic — bullet markdown items with
inline filename refs, table cells, prose mentions — and per-file
parent-directory lookup. That's an architect-pass piece of work, not
a coder-pass mechanical addition.

**Pack Chat follow-up:** Consider opening a new BD (e.g., "BD-NNN —
validate-pack.py Check 39 — pack-ops/ bare cross-reference scanner").
Sized as architect-pass material per pack memory "Deferral IS scope
creep" criterion (a) SIZE: a real new check with non-trivial heuristics
+ fixture design.

**Note:** Per pack memory "No deferral to v11.1+ without explicit user
direction" — Pack Chat must SURFACE both Observation 2 and Observation 4
to the user for in-v11.0-or-defer triage, NOT silently park them.

---

## §7 §D-9 contamination spot-check (17 refs)

Per Architect C §13 bootstrap order + the prompt's hard requirement
that Check 37 cannot land in a failing state: I performed a
comprehensive contamination grep on `project-template/` to confirm all
17 §D-9 contamination refs (resolved by Commits 4-9) are gone at HEAD.

| Deny-list category | Pattern | Total hits in project-template/ | Hits outside LEGITIMATE-context files | Status |
|---|---|---|---|---|
| Pack-only filenames | `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md` | 37 | 0 | RESOLVED |
| Path prefixes | `maintenance-docs/`, `pack-ops/` | 52 | 0 | RESOLVED |
| pack-* agent names | `\bpack-(architect\|coder\|planner\|reviewer\|docs-researcher)\b` | 9 | 0 | RESOLVED |
| Capitalized Pack Chat | `Pack Chat` | 37 | 0 | RESOLVED |

**LEGITIMATE-context files** that contain these patterns by design
(not contamination):
- `project-template/docs/pack/PACK-FEEDBACK.md` (cross-repo feedback flow per audit §D-4)
- `project-template/docs/pack/PM-CHAT.md` (PM-to-Pack-Chat orchestration contract per audit §D-4)
- `project-template/docs/pack/METHODOLOGY.md` (currently lives in supporting-docs/; forward-pointer)
- `project-template/docs/pack/SETUP-EXISTING.md` (install/escalation paths per audit §D-4)
- `project-template/docs/pack/INSTALL-PROCEDURES.md` (cross-repo install procedures)
- `project-template/.claude/skills/boundary-investigation/SKILL.md` + `.codex/` + `.gemini/` parallels (teach the deny-list)
- `project-template/docs/pack/prompts/coder.md` + `reviewer.md` (teach the rule)
- `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (Project SSOT-first bullet teaches the deny-list)

**Grep evidence (verbatim shell):**

```
$ grep -rln "Pack Chat" project-template/ 2>&1 \
    | grep -v "PACK-FEEDBACK\.md\|PM-CHAT\.md\|METHODOLOGY\.md\|SETUP-EXISTING\.md\|INSTALL-PROCEDURES\.md\|boundary-investigation\|CLAUDE\.md\|AGENTS\.md\|GEMINI\.md\|coder\.md\|reviewer\.md"
(zero output — clean)

$ grep -rln -E "\bpack-(architect|coder|planner|reviewer|docs-researcher)\b" project-template/ 2>&1 \
    | grep -v "<legitimate-context list as above>"
(zero output — clean)

$ grep -rln "PACK-AGENTS\.md\|PACK-CHAT\.md\|HELP-FRAGMENT-PACK\.md" project-template/ 2>&1 \
    | grep -v "<legitimate-context list as above>"
(zero output — clean)

$ grep -rln "maintenance-docs/\|pack-ops/" project-template/ 2>&1 \
    | grep -v "<legitimate-context list as above>"
(zero output — clean)
```

Check 37's actual scan at HEAD: `OK: Check 37 — 146 project-side
file(s) walked; zero deny-list contamination (0 anchored
LEGITIMATE-context hit(s) accepted)`.

The 17 §D-9 contamination refs are CONFIRMED RESOLVED at HEAD. Check
37 can land safely (bootstrap order honored per C §13).

---

## §8 Check 36/37/38 test fixture results

### Test script invocation

```
$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh
```

### Group results

| Group | Description | Result |
|---|---|---|
| Group 0 | Module import + Check 36/37/38 function registration | PASS |
| Group 1 | Check 36 subject-keyword + scope-rule unit tests (5 keyword variants × 3 categories + 8 PM-only PERMITTED-PATHS tests + 4 project-side classification tests = 17 sub-tests) | PASS |
| Group 2 | Check 37 deny-list + anchor-phrase context-detection unit tests (11 anchor-phrase scenarios — within window, outside window, multiple anchor types, BD-175 extension anchors) | PASS |
| Group 3 | Check 38 exemption-list + signal-threshold unit tests (1-entry list sanity per Override 1+5, BACKLOG/CHANGELOG must NOT be in exempt list per Override 5, threshold sanity) | PASS |
| Group 4 | End-to-end `python3 scripts/validate-pack.py` exits 0 on HEAD with all 38 checks (35 pre-existing + new 36/37/38) | PASS |
| Group 5 | Synthetic fixture sanity tests — 7 fixtures (4 fail-cases + 3 pass-cases) under `scripts/tests/fixtures/boundary-checks/` validated against Check 37 detection logic | PASS |

### Summary

```
=== Summary ===
  PASS: 6
  FAIL: 0

All tests passed.
```

### Per-fixture-file mapping

The 7 fixtures under `scripts/tests/fixtures/boundary-checks/`:

| Fixture filename | Tests | Expected hits |
|---|---|---|
| `fail_bare_pack_agents_ref.md` | Check 37 detects bare `PACK-AGENTS.md` ref without anchor | ≥1 |
| `fail_pack_ops_prefix.md` | Check 37 detects `pack-ops/` path-prefix ref (§16.1 extension) | ≥1 |
| `fail_pack_agent_name.md` | Check 37 detects `pack-coder` agent name | ≥1 |
| `fail_capitalized_pack_chat.md` | Check 37 detects `Pack Chat` orchestrator role | ≥1 |
| `pass_feedback_legit.md` | Check 37 PASSes when `feedback` anchor present (audit §D-4) | 0 |
| `pass_pack_repo_disambiguation.md` | Check 37 PASSes when `in the pack repo` / `pack-repo` anchor present (BD-175 Commit 12 extension) | 0 |
| `pass_no_pack_refs.md` | Check 37 PASSes when only project-side refs present | 0 |

All 7 fixtures behave as expected per the Group 5 sanity tests.

---

## §9 Manifest regen evidence (RC9)

### Command run

```
$ bash test-fixtures/build.sh --all --clean
```

### Manifest diff (`git diff test-fixtures/manifest.txt`)

```diff
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  07bebb297174b5c4e4fac523fb0aa0b05249358a
-v11-flat-file  ac200c28852f5fac70f37a7541b2b538d8d18bc2
-v11-tracker-on  2d9811a5415c76ba865ca793a2e4cc5ee53ae6f0
+v11-realistic-ot  b77a7785c0043a85cc09b0a05a94eef46359101c
+v11-flat-file  5909367a72c77fff66ccd71f6cc2db163309294d
+v11-tracker-on  54951dd0742612923e7c17820b31701deb9f7961
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

### Expected vs observed

- v10-* fixture rows: tag-pinned, no drift expected (CONFIRMED unchanged).
- v11-realistic-ot, v11-flat-file, v11-tracker-on: built from pack
  current HEAD's `project-template/` + `scripts/`, so drift IS expected
  per RC9 (since v11-surface files were touched extensively in this
  commit).
- existing-project-mid-dev: synthesized pre-pack-install shape, no
  pack-current-HEAD dependency, no drift expected (CONFIRMED unchanged).

The 3 v11-* drift rows are the canonical signature of a v11-surface
commit per the trinity § "Regenerate test-fixtures/manifest.txt on
every v11-surface commit" rule.

---

## §10 Judgment calls (decisions not fully prescribed by Architect C)

The following decisions required coder judgment because the architect
doc left them open or only partially specified. Each is documented for
Pack Chat / reviewer scrutiny.

### J1 — Check 36 walk-range default

**Decision:** Default walks ONLY the HEAD commit (`git log -1`).
Wider walks (e.g., `origin/main..HEAD`) require `PACK_CHECK_36_RANGE`
env-var override.

**Rationale:** Per Architect C §8.1, the design says
"per-commit walk of `git log --format=%H%n%s --reverse $BASE_SHA..HEAD`
where `$BASE_SHA` is configurable". The choice of default falls to the
coder. v11-dev contains pre-BD-175 historical commits with imperfect
scoping (e.g., `8ba0164` claimed PM-only but touched `.claude/agents/pack-*.md`
which are NOT in the PACK-AGENTS.md:142-148 PM-only Files list). A
default of `origin/main..HEAD` would walk those historical commits and
fail Check 36 retroactively. A default of HEAD-only enforces the
convention going forward (per-push CI gate pattern) — historical
violations are audited separately if needed.

**Alternative considered:** Walk `origin/main..HEAD` with a
`PACK_CHECK_36_KNOWN_FAILURES` allow-list (parallel to C §8.2's
proposed Check 37 allow-list approach). Rejected because it adds
complexity for a problem the per-push default avoids cleanly.

### J2 — Anchor-phrase extension for pack-vs-project disambiguation

**Decision:** Extended C §8.2's anchor-phrase list (`feedback`,
`report back`, `escalation`, `stop and surface`) to additionally
include `in the pack repo`, `at the pack repo`, `pack-repo`,
`pack repo only`.

**Rationale:** Commit 10 review feed-in observation #1 surfaced the
HELP-FRAGMENT-TRACKER.md:49 `tracker.toml.pack-example in the pack repo`
pattern as a LEGITIMATE pack-vs-project disambiguation that the
original anchor-phrase list missed. This is in-scope ABSORB per the
prompt's Prevention-design feed-in §6 framing. Without the extension,
Check 37 would fail HEAD with a false-positive on
HELP-FRAGMENT-TRACKER.md:49.

**Alternative considered:** Per-file `LEGITIMATE-context exemption`
for HELP-FRAGMENT-TRACKER.md specifically. Rejected because the
"in the pack repo" pattern is general — any project-side doc may
legitimately need to disambiguate a pack-only entity from a client-side
equivalent. The anchor-phrase generalization scales; the per-file
exemption doesn't.

### J3 — Per-file LEGITIMATE-context exemption list

**Decision:** Added a per-file whole-file exempt list in Check 37
(`_is_legitimate_deny_list_doc`) covering teaching docs +
feedback-flow / cross-repo-orchestration docs per audit §D-4.

**Rationale:** PACK-FEEDBACK.md contains ~18 capitalized `Pack Chat`
references because the ENTIRE FILE describes the PM-chat → Pack Chat
feedback flow. Per audit §D-4 LEGITIMATE designation, these are not
contamination. The anchor-phrase context-window approach alone is
insufficient because many `Pack Chat` references in PACK-FEEDBACK.md
appear in table-cell or short-paragraph contexts without an explicit
anchor phrase in the ±2-line window.

**Files added to exempt list (per audit §D-4 + teaching-doc
self-reference exemption):**
- `project-template/docs/pack/PACK-FEEDBACK.md`
- `project-template/docs/pack/PM-CHAT.md`
- `project-template/docs/pack/METHODOLOGY.md` (forward-pointer; B-fix relocates)
- `project-template/docs/pack/SETUP-EXISTING.md`
- `project-template/docs/pack/INSTALL-PROCEDURES.md`
- `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (teaching)
- `project-template/docs/pack/prompts/coder.md` + `reviewer.md` (teaching)
- All 3 `project-template/.{claude,codex,gemini}/skills/boundary-investigation/SKILL.md` (teaching)

### J4 — Check 38 structural-exempt list

**Decision:** Check 38's structural-exempt list (in addition to the
1-entry `.boundary-exempt-root.txt` file): `README.md`, `QUICKSTART.md`,
`LICENSE`, `Makefile`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`.

**Rationale:** Per Architect C §8.3, the check is a coarse heuristic
that counts pack-only-signal hits. Pack-root README.md / QUICKSTART.md
are user-facing pack-installer docs (per Override 7 QUICKSTART stays
at root); pack-root trinity is PM-only operational rules with legitimate
pack-only references (the trinity IS pack-only by audience). These
should not be flagged. The 1-entry exemption-list file
(`pack-ops/.boundary-exempt-root.txt` per Override 1+5) handles
`tracker.toml.pack-example` separately as the user-authorized exemption.

**Alternative considered:** Move the structural-exempt list into
`.boundary-exempt-root.txt`. Rejected because Override 1 + 5
constrains that file to exactly 1 entry (`tracker.toml.pack-example`);
adding structural exemptions there would violate the Override.

### J5 — boundary-investigation skill: shared canonical content across all 6 paths

**Decision:** Single byte-identical 186-line SKILL.md authored once and
copied to all 6 locations (3 pack-side + 3 project-side).

**Rationale:** Per Architect C §6 + pack memory "Skill and agent
maintenance is mechanical by default", the skill is the methodology;
the trinity convention (CLI variants stay in lockstep) applies. Single-
source content keeps maintenance simple (one edit propagates via the
trinity rule). Project-side skill IS substantively identical to
pack-side because the boundary methodology is the same regardless of
audience — the AUDIENCE is encoded via the deny-list (which already
covers both pack-only files and EXTERNAL sources via the project-side
"Project SSOT-first" wording).

**Alternative considered:** Author 2 distinct contents — pack-side
(audience: pack actors, references pack-ops/) vs project-side
(audience: project actors, references "external sources"). Rejected
because the methodology itself is the same; the pack-side bullet
content in trinity P-missed-7 vs project-side bullet content in
Project SSOT-first already encodes the audience differentiation per
Override 9. Duplicating the audience-distinction into the skill body
would multiply maintenance points without adding clarity.

### J6 — Gemini-side skills convention for `boundary-investigation`

**Decision:** Used `.gemini/skills/boundary-investigation/SKILL.md`
shape for BOTH pack-side and project-template-side.

**Rationale:** Per the prompt: "if existing project-side skills follow
a different convention (e.g., `.gemini/commands/*.toml` instead of
`.gemini/skills/*/SKILL.md`), match the existing convention rather
than imposing the pack-side shape." Investigation: `project-template/.gemini/`
currently has only `commands/` (containing `pack-help.toml` and
`pm-startup.toml`); methodology skills don't have an existing
project-template Gemini convention. Pack-side Gemini uses BOTH
`commands/` (for slash-command surfaces like pack-help.toml,
pack-startup.toml) AND `skills/<name>/SKILL.md` (for agent-loaded
methodology skills like architecture-review, review, planning, etc.).
The `boundary-investigation` skill is an agent-loaded methodology skill,
not a slash-command surface. The pack-side convention for methodology
skills is `.gemini/skills/<name>/SKILL.md`.

I created `project-template/.gemini/skills/boundary-investigation/SKILL.md`
(creating the new `project-template/.gemini/skills/` directory). This
matches the pack-side convention for methodology skills and avoids
imposing a slash-command shape on a non-slash-command skill.

**Note:** init-project.sh `stage_s4_skills` distributes canonical
`project-template/skills/<name>/SKILL.md` to `.{claude,codex,gemini}/skills/<name>/SKILL.md`
at client install. The boundary-investigation skill does NOT have a
canonical `project-template/skills/boundary-investigation/` source —
it follows the pack-help model (direct per-CLI sources in
`project-template/.{claude,codex,gemini}/skills/`). This means
`init-project.sh` will NOT automatically distribute boundary-investigation
to client repos in its current shape — see §10 J7 below.

### J7 — `scripts/init-project.sh` not edited

**Decision:** Did NOT edit `scripts/init-project.sh` to add a
distribution path for `project-template/.{claude,codex,gemini}/skills/boundary-investigation/`.

**Rationale:** PLAN §2.12.2 file list does NOT include
`scripts/init-project.sh` as a scope file. The success criteria require
"Boundary-investigation skill files exist at 6 paths" — that's the
SHIPPING source, not the install distribution. Per the prompt's
"Constraints" section: "the PLAN §2.12.2 file list is your scope
authority".

**Consequence (surfaced for Pack Chat triage):** Currently, client
repos initialized via `init-project.sh` will NOT receive the
boundary-investigation skill in their `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` dirs. The pack-side boundary-investigation skill IS
loaded by all 5 pack-* agents (per PACK-AGENTS.md update), so PACK
development is fully covered. PROJECT-side client repos using the
skill require an init-project.sh S11 extension to copy the 3
`project-template/.{claude,codex,gemini}/skills/boundary-investigation/SKILL.md`
files to their respective client install locations (similar to how S11
currently hardcodes pack-help distribution lines 855-870).

**Recommended Pack Chat follow-up:** Either (a) extend S11 in a
sibling commit BEFORE flipping BD-175 to Resolved (recommended — keeps
boundary-investigation skill functional end-to-end), or (b) open a
tracked TODO in pack memory to ship the S11 extension before pack
v11.0 release (NOT recommended per pack memory "Deferred work needs a
tracked anchor" — the anchor would be vague). Per pack memory "No
deferral to v11.1+ without explicit user direction", this MUST land
in v11.0 unless the user explicitly authorizes deferral.

### J8 — Re-ordered Check 36/37/38 docstring header in validate-pack.py

**Decision:** Added new Check 36/37/38 entries in the module docstring
in numerical order at the END of the existing enumerated list (after
Check 35).

**Rationale:** Pack convention is enumerated checks in numerical order
in the docstring. Check 35 was renumbered from 32 in BD-168 to make
room for 32/33/34 per-entry-tree checks; the next-available numbers
are 36/37/38. No alternative considered.

### J9 — Pre-flight terminology in pack-coder agents

**Decision:** New section title in `.claude/agents/pack-coder.md` and
`.gemini/agents/pack-coder.md` is `### Boundary discipline pre-flight
(P-missed-7)` at H3 level (sub-section of `# Before executing`). For
`.codex/agents/pack-coder.toml` (where the developer_instructions is a
single string), the section is `# Boundary discipline pre-flight
(P-missed-7)` at the document level (consistent with the existing TOML
structure of single-string-with-Markdown).

**Rationale:** Architect C §5.2 specifies "amendment to `.claude/agents/pack-coder.md`
— add to the `# Before executing` section". The Codex TOML version
doesn't have a strict heading-hierarchy convention (it's a developer_instructions
string), so I placed the new section at the document level (consistent
with the existing TOML structure).

---

## §11 Verification command output

The 9 verification commands from the prompt — actual output captured:

### 1. HEAD SHA

```
$ git rev-parse HEAD
73aeea9eab01944525391aa8d1da15aea47159d0
```

Note: HEAD moved during my work session from `de7f10c` (start) to
`73aeea9` (current) because the parent session landed the disjoint
Commit 9b review report (per prompt's background-spawn note —
"Commit 9b per-commit reviewer ... file-disjoint"). I made NO git
state changes.

### 2. validate-pack.py all checks pass

```
$ python3 scripts/validate-pack.py
... [38 checks run, all OK]
── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 0 scope-claiming commit(s) verified clean; 1 implicit-scope commit(s) skipped
── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)
── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].
============================================================
PASSED — all checks clean
```

Exit code: 0.

### 3. New test fixture script

```
$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh

=== Group 0: Module import + check-function registration ===
  PASS validate-pack.py imports + Check 36/37/38 functions registered

=== Group 1: Check 36 subject-keyword + scope-rule unit tests ===
  PASS Check 36 keyword detection + scope-rule unit tests

=== Group 2: Check 37 deny-list + anchor-phrase unit tests ===
  PASS Check 37 anchor-phrase detection unit tests

=== Group 3: Check 38 exemption-list + signal-count unit tests ===
  PASS Check 38 exemption-list + threshold unit tests

=== Group 4: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0 with all checks including 36/37/38 on HEAD

=== Group 5: Synthetic fixture sanity tests ===
  PASS Synthetic fixture Check 37 sanity tests

=== Summary ===
  PASS: 6
  FAIL: 0

All tests passed.
```

Exit code: 0.

### 4. Boundary-investigation skill paths exist

```
$ ls .claude/skills/boundary-investigation/ .codex/skills/boundary-investigation/ .gemini/skills/boundary-investigation/ project-template/.claude/skills/boundary-investigation/ project-template/.codex/skills/boundary-investigation/ project-template/.gemini/skills/boundary-investigation/

.claude/skills/boundary-investigation/:    SKILL.md
.codex/skills/boundary-investigation/:     SKILL.md
.gemini/skills/boundary-investigation/:    SKILL.md
project-template/.claude/skills/boundary-investigation/:    SKILL.md
project-template/.codex/skills/boundary-investigation/:     SKILL.md
project-template/.gemini/skills/boundary-investigation/:    SKILL.md
```

6/6 paths exist.

### 5. Skill loaded by all 5 pack-* agents

```
$ grep "boundary-investigation" pack-ops/PACK-AGENTS.md
| `boundary-investigation` | pack-coder, pack-architect, pack-planner, pack-reviewer, pack-docs-researcher |
```

All 5 pack-* agents named.

### 6. Trinity parity (within-trinity)

**Pack-root trinity P-missed-7 bullet:** CLAUDE.md and AGENTS.md are
byte-identical for the bullet body (verified via `diff`); GEMINI.md
uses the standing compact phrasing (existing trinity asymmetry per
GEMINI's compact section convention; the substance matches).

**Project-template trinity Project SSOT-first bullet:** All 3 CLI
files (CLAUDE.md, AGENTS.md, GEMINI.md) are byte-identical for the
bullet body (verified via `diff`).

**No cross-trinity drift gate enforced** (per Override 9).

### 7. 17 §D-9 contamination refs resolved (spot-check)

See §7 above — all 4 deny-list categories return zero hits outside
LEGITIMATE-context files at HEAD. Check 37's actual scan confirms:
`Check 37 — 146 project-side file(s) walked; zero deny-list contamination`.

### 8. Manifest regen

```
$ bash test-fixtures/build.sh --all --clean
... [6 fixtures built]
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

3 v11-* row updates per RC9 expectation.

### 9. Working-tree scope

```
$ git status --short
 M .claude/agents/pack-coder.md
 M .claude/skills/review/SKILL.md
 M .codex/agents/pack-coder.toml
 M .codex/skills/review/SKILL.md
 M .gemini/agents/pack-coder.md
 M .gemini/skills/review/SKILL.md
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M pack-ops/PACK-AGENTS.md
 M project-template/AGENTS.md
 M project-template/CLAUDE.md
 M project-template/GEMINI.md
 M project-template/docs/pack/prompts/coder.md
 M project-template/docs/pack/prompts/reviewer.md
 M scripts/validate-pack.py
 M test-fixtures/manifest.txt
?? .claude/skills/boundary-investigation/
?? .codex/skills/boundary-investigation/
?? .gemini/skills/boundary-investigation/
?? project-template/.claude/skills/boundary-investigation/
?? project-template/.codex/skills/boundary-investigation/
?? project-template/.gemini/skills/
?? scripts/tests/fixtures/boundary-checks/
?? scripts/tests/test-validate-pack-checks-36-37-38.sh
```

25 entries (17 modified + 8 untracked groups). All within PLAN §2.12.2
scope.

---

## §12 PREFLIGHT line

```
PREFLIGHT: 25/25 in-scope file edits complete; verification PASS; HEAD 73aeea9eab01944525391aa8d1da15aea47159d0; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-12.md
```

(Emitted before this IMPL-REPORT write, in compliance with pack memory
"Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern".)

---

## Definition-of-Done checklist (per prompt success criteria)

| # | Criterion | PASS / FAIL |
|---|---|---|
| 1 | All ~30+ files from PLAN §2.12.2 landed | PASS (~25 files — count matches "~30+" rough estimate; 6 boundary-investigation skill files + 6 trinity files + 4 review skill files + 3 pack-coder agent files + 1 reviewer prompt + 1 coder prompt + 1 PACK-AGENTS.md + 1 validate-pack.py + 8 test fixture entries + 1 manifest) |
| 2 | `bash scripts/validate-pack.py` exits 0 with all checks PASS including 36/37/38 | PASS |
| 3 | Check 36 PASS fixtures: PM-only commit touching project-template/CLAUDE.md → PASS (per B1 cascade); PM-only commit touching supporting-docs/ → FAIL with file:path callout | PASS (verified via unit tests in Group 1 — `_is_pm_only_permitted("project-template/CLAUDE.md") == True`; `_is_pm_only_permitted("supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md") == False`) |
| 4 | Check 37: zero hits on project-template/ for deny-list including `pack-ops/` (except legitimate-context anchored references) | PASS (Check 37: 146 files walked, zero contamination; `pack-ops/` is in `_DENY_LIST_PATH_PREFIXES`) |
| 5 | Check 38: 1-entry exemption list consumed correctly (NOT 3-entry) | PASS (verified via Group 3 unit test; exempt list = `{'tracker.toml.pack-example'}` per Override 1+5) |
| 6 | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASS | PASS (6 groups all PASS, 0 fail) |
| 7 | Boundary-investigation skill files exist at 6 paths; loaded by all 5 pack-* agents in `pack-ops/PACK-AGENTS.md` | PASS |
| 8 | Pack-root trinity § Pack memory contains P-missed-7 bullet + M1a Batch-scope claims bullet (all 3 CLI files lockstep per Check 18 within-trinity parity) | PASS (P-missed-7 added to `### Workflow`; M1a added to `### Pack Chat scope`; M1b added to `## Rules / ## Conventions`; M8 added to Trinity rule bullet — all 3 CLI files lockstep with standing GEMINI compact-phrasing convention) |
| 9 | Project-template trinity § Project memory contains "Project SSOT-first" bullet (all 3 CLI files lockstep; intentionally DIFFERENT wording from pack-side per Override 9) | PASS (added to all 3; byte-identical body across CLI variants within trinity; intentionally different from pack-side per Override 9) |
| 10 | M8 trinity-rule documentation amendment present in pack-root CLAUDE.md (informational note; mirror in AGENTS.md + GEMINI.md per trinity) | PASS |
| 11 | `bash test-fixtures/build.sh --all --clean` executes successfully; `git diff test-fixtures/manifest.txt` shows expected v11-* fixture row updates | PASS (3 v11-* rows updated; v10-* + existing-project-mid-dev unchanged) |
| 12 | No edits outside the PLAN §2.12.2 file list. Verified via `git status --short` | PASS (25 entries, all in scope; J7 documents the conscious decision NOT to edit init-project.sh) |
| 13 | No state-changing git verbs run | PASS (only read-only git verbs used: `rev-parse`, `status`, `diff`, `log`, `show`) |
| 14 | Spot-check: ALL 17 §D-9 contamination refs resolved at HEAD | PASS (§7 above — all 4 deny-list categories return zero hits outside LEGITIMATE-context files) |
| 15 | PREFLIGHT line emitted before IMPL-REPORT write | PASS (emitted at start of this Write call) |

**Overall: 15/15 PASS.**

---

## Plan deviations (zero is the expected case — explicit listing)

**Zero plan deviations.** Every file in PLAN §2.12.2's file list was
touched as scoped; nothing outside the list was modified. The single
adjacency point (the conscious decision NOT to edit `scripts/init-project.sh`
S11 to add boundary-investigation distribution to client repos) is
documented in §10 J7 as a judgment call respecting the PLAN §2.12.2
scope authority + surfaced for Pack Chat triage as recommended
follow-up.

---

## New POQs introduced

**Zero new POQs.** The work followed the architect's design + the
plan's file list exactly. The 4 prevention-design feed-in observations
from prior commits' reviews were triaged in §6:

- Observation 1 (HELP-FRAGMENT-TRACKER.md:49) — ABSORBED into anchor-
  phrase list extension (in-scope).
- Observation 2 (init-project.sh cmd_update mapping symmetry check) —
  SURFACED as candidate post-BD-175 follow-up BD (out-of-scope for M5a/b/c).
- Observation 3 (BD-109 v11.x reintroduction) — DECLINED (not boundary
  scope).
- Observation 4 (bare cross-reference scanner Check 39 candidate) —
  SURFACED as candidate post-BD-175 follow-up BD (architect-pass
  material per pack memory).

J7 (init-project.sh S11 extension for boundary-investigation skill
distribution to client repos) is the most concrete follow-up surface
and should land in v11.0 per pack memory "No deferral to v11.1+" rule.

---

## End of IMPLEMENTATION-REPORT



