# IMPL-REPORT — BD-221 C4: validate-pack.py validator green-maker (Antigravity conversion)

**Commit:** C4 (the `validate-pack.py` validator conversion — all OTHER checks + constants, NOT Check 25).
**Scope keyword:** `pack-only` (every touched path is under `scripts/`).
**Regime:** ISOLATED git worktree.
**Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a8e76afb45108f9bc`
**Branch:** `worktree-agent-a8e76afb45108f9bc`
**HEAD SHA (worktree, unchanged — no git state change):** `0053ef8bcf4253dc8b7ae08de5978cb4782da1b2`
**Patch status:** NO patch emitted (per the new live model). Edits left UNCOMMITTED in the worktree. Awaiting the post-review SendMessage to produce the patch ONLY if the read-only reviewer confirms CLEAN.

---

## 1. C4 PASS CRITERION — RESULT (the fail-LINE-level `comm` gate, plan §1/§7)

| Gate | Required | Measured | Verdict |
|---|---|---|---|
| BASE fail-lines (pre-edit, clean worktree at parent) | 52 (post-C3 baseline) | **52** | PASS |
| `AFTER` fail-lines (post-edit, general mode) | EMPTY (validate-pack GREEN) | **0** | PASS |
| `NEW = comm -13 base after` | EMPTY (no new fail-line) | **empty** | PASS |
| `CLEARED = comm -23 base after` | all 52 BASE lines | **52** | PASS |
| `python3 scripts/validate-pack.py` exit code | 0 | **0** | PASS |
| Registry count (Check 59) | 59 (was 61; −2 for retired 21/28) | **59** (computed == expected) | PASS |

BASE captured at `/tmp/c4-base-worktree.txt` (52 lines, matches the orchestrator's `/tmp/c4-base.txt`). AFTER at `/tmp/c4-after.txt` (0 lines). C4 is the validate-pack GREEN-MAKER: it clears all 52 baseline fail-lines to ZERO and introduces no new fail-line.

The 52 cleared lines map to: Check 5 (3), Check 11/17 leg (`.gemini/.env.example — missing`, 1), Check 18 ×2 (pack-root + project-template GEMINI.md H2), Check 21 pack-root leg (1, RETIRED), Check 27 (`project-template/.gemini/agents — directory missing`, 1), Check 28 ×3 (RETIRED), Check 52 ×5, Check 55 ×16, Check 56 ×2, Check 57 ×16, plus the `No Gemini agent files found` (Check 5 name-corr) and the project-template `.gemini/agents — directory missing` (Check 27). All STRIP per DESIGN §6 measure-then-bound; zero allowlist growth.

---

## 2. FILES CHANGED (inventory — 6 files, all `scripts/`)

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (constants, checks, retirements, comments) |
| `scripts/tests/test-validate-pack-check-18.sh` | modified (the `## Gemini CLI operating notes` → `## Antigravity CLI operating notes` synthetic fixture) |
| `scripts/tests/test-validate-pack-check-41.sh` | modified (removed dead `.gemini/commands/pm-startup.toml` token from a comment) |
| `scripts/tests/test-validate-pack-check-55.sh` | modified (re-expressed the "Gemini case" no-`tools:` semantic for the Antigravity bundle) |
| `scripts/tests/test-validate-pack-check-56.sh` | modified (`drop_surface` → `.agents-plugin/pack-agents/agents/pack-coder.md`) |
| `scripts/tests/test-validate-pack-check-57.sh` | modified (`drop_surface` → `.agents-plugin/optiquity-agents/agents/coder.md` + a prose comment) |

No new files. No deletions of files (only in-file code/function removals — Checks 21/28 + the `_extract_pm_startup_sections` helper, fully removed per `fail-loud-delete-old-source`). `test-fixtures/manifest.txt` UNTOUCHED (C4 changes zero fixture content — see §6).

---

## 3. validate-pack.py — PER-CONSTANT / PER-CHECK changes

### Constants
- **`GEMINI_AGENTS_DIR` (was ~L357)** — REMOVED; replaced by a clearly-named `OPTIQUITY_BUNDLE_AGENTS_DIR = project-template/.agents-plugin/optiquity-agents/agents`. Consumed by Checks 5 (count parity) and 27 (canonical phrases).
- **`PACK_SCAN_LOCATIONS`** — recast from 7 entries (4 dead: `.gemini/agents`, `.gemini/skills`, `.claude/skills`, `.codex/skills`) to 5 live Antigravity surfaces: `.claude/agents`, `.codex/agents`, `OPTIQUITY_BUNDLE_AGENTS_DIR`, `project-template/skills` (the shared pool), `docs/pack/prompts`. Check 8 skips non-existent dirs, stays green. The "seven pack scan locations" docstring (module summary item 8) was de-numbered to "the pack scan locations".
- **`GEMINI_INTRINSIC_H2S` (Check 18, local)** — `{"## Agent roster", "## Gemini CLI operating notes"}` → `{"## Agent roster", "## Antigravity CLI operating notes"}`. Plus docstring + the L1633/L1638 "Gemini-intrinsic" → "GEMINI.md-intrinsic" wording + the L1651 narration H2 name.
- **`_CHECK_51_RECOMMEND_SKILL_DIRS`** — the two `.gemini/commands` legs → `.agents/skills` + `project-template/.agents/skills` (Antigravity workspace-skill dirs). Non-existent dirs skipped; recommend-token absent everywhere → leg 3 stays green.
- **`_CHECK_52_AGENT_DIRS`** — 3rd leg `(.gemini/agents, md)` → `(.agents-plugin/pack-agents/agents, md)`.
- **`_CHECK_55_AGENT_DIRS`** — 3rd leg `(project-template/.gemini/agents, md)` → `(project-template/.agents-plugin/optiquity-agents/agents, md)`.
- **`_CHECK_56_VERB_PARITY_SURFACES`** — `.gemini/skills/commit-discipline/SKILL.md` → `.agents/skills/commit-discipline/SKILL.md`; `.gemini/agents/pack-coder.md` → `.agents-plugin/pack-agents/agents/pack-coder.md`. KEPT the `GEMINI.md` trinity-FILE surface. Enumeration set still 10 surfaces.
- **`_CHECK_57_AGENT_DIRS`** — 3rd leg `(project-template/.gemini/agents, md)` → `(project-template/.agents-plugin/optiquity-agents/agents, md)`.
- **`_CHECK_43_ALLOWLIST`** — the 8 agent-prompt-meta-reference entries (`coder.md`, `architect.md`, `reviewer.md`, `planner.md`, `tester.md`, `auditor.md`, `docs-researcher.md`, `auditor-architecture.md`): rationale strings rewritten basename-keyed, stripping the dead `gemini` token and naming the bundle path (`...the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents...`). NO behavior change — basename-keyed, value is documentation only; still exactly 8 entries (no growth). The L5645 comment + the L5725 `.gemini/.env.example` walk-example comment updated.
- **`CHECK_REGISTRY_EXPECTED_COUNT`** — `61` → `59` (−2 for retired Checks 21 + 28). The L458-475 prose comment updated to document the decrement.

### Check recasts (functions)
- **Check 5 `check_agent_count`** — recast to Claude↔Codex 2-way loose parity PLUS plugin-roster count parity (the `OPTIQUITY_BUNDLE_AGENTS_DIR` 16-agent roster). Names + counts compared 3-way (claude/codex/bundle). FAIL/OK messages updated ("Antigravity bundle").
- **Check 17 `check_tool_config_capability_parity`** — recast to Claude↔Codex 2-way; the entire Gemini `.gemini/.env.example` leg REMOVED (it was a missing-file FAIL). Docstring documents the Antigravity permissions-example rationale (decision b=B3).
- **Check 18 `check_trinity_h2_parity`** — `GEMINI_INTRINSIC_H2S` H2 string + docstring + narration text.
- **Check 19 `check_trinity_no_scaffolding_comments`** — docstring "Gemini-intrinsic H2s" → "GEMINI.md-intrinsic H2s" (no logic change; KEEP-FILE).
- **Check 20 `check_gitignore_env_example_exception`** — docstring `.gemini/.env.example` reference removed (the generic `.env.*` + `!.env.example` exception is unchanged; no `!.gemini/.env.example` leg ever existed in the function body).
- **Check 27 `check_agent_canonical_phrases`** — 3rd `agent_dirs` leg `GEMINI_AGENTS_DIR` → `OPTIQUITY_BUNDLE_AGENTS_DIR` (MUST-1: scans the Antigravity bundle agents for canonical phrases — no silent coverage loss). Verified all 16 bundle agents carry every COMMON + PROFILE canonical phrase.
- **Check 56 `check_destructive_git_verb_parity`** — leg recast (above) + a NEW whitespace-tolerant principle-phrase matcher (`_check_56_phrase_present`) — see §4 (plan deviation / new finding).

### Retirements (fully removed — `fail-loud-delete-old-source`)
- **Check 21 `check_pack_help_per_cli_parity`** — function REMOVED (replaced by a retirement comment); `CHECK_REGISTRY` entry REMOVED; the "references `scripts/pack-help.sh`" assertion FOLDED into Check 1 (OQ-C). No commented-out remnant; no per-check test existed.
- **Check 28 `check_pm_startup_per_cli_parity`** + its sole-consumer helper `_extract_pm_startup_sections` — both REMOVED (replaced by a retirement comment); `CHECK_REGISTRY` entry REMOVED. No per-check test existed.

### Check 1 fold (OQ-C)
- `check_skill_frontmatter` now additionally asserts: when the skill dir is `pack-help`, the SKILL.md body must reference `pack-help.sh`. Verified the pooled `project-template/skills/pack-help/SKILL.md` body references `scripts/pack-help.sh`.

### Comments converted (Antigravity surfaces)
- Module docstring summary items 5, 11, 17, 21 (RETIRED), 27, 28 (RETIRED). Check 11 docstring (`.gemini/.md` → bundle). Check 46 surfaces comment (`.codex / .gemini` → `.codex / .agents`). Check 52/55/57 "Gemini files carry no `tools:`" → "Antigravity bundle files carry no `tools:`". Check 57 file-extension comment.
- KEPT (allowlist class 3 — GEMINI.md trinity FILE): the `gemini`/`gemini_filtered` local variables in Check 18 (`gemini = h2_lists["GEMINI.md"]`), "CLAUDE/AGENTS/GEMINI" / "Claude/Codex/Gemini contract" trinity-file references (L4773/L5054/L8628), and `GEMINI-CLI-ANALYSIS.md` (removed-doc allowlist).

---

## 4. PLAN DEVIATIONS + NEW FINDINGS (must-read)

### DEVIATION-1 (NEW FINDING, in-scope fix) — Check 56 principle-phrase line-wrap in the bundle pack-coder.md

**What.** The plan recasts Check 56's 3rd pack-coder surface to
`.agents-plugin/pack-agents/agents/pack-coder.md`. That bundle template
carries the catch-all principle phrase `including but not limited to`
WRAPPED across a markdown line break: the bytes are
`including but not\nlimited to`. Check 56's principle-phrase test was a
plain byte-exact substring search (`_CHECK_56_PRINCIPLE_PHRASE not in
text`), which does NOT match a newline-wrapped phrase. So the bare leg
recast — exactly as the plan specifies — would have produced a NEW
fail-line (`Check 56 (Guard-C) — .agents-plugin/pack-agents/agents/pack-coder.md
is MISSING the catch-all principle phrase ...`), an UNEXPECTED red.

**Measured (via the actual Check 56 functions):**
- `.agents-plugin/pack-agents/agents/pack-coder.md`: all 28 canonical verbs present; principle-phrase plain-substring = **False** (the wrap).
- `.agents/skills/commit-discipline/SKILL.md`: all 28 verbs + phrase = True.
- All EXISTING Check-56 surfaces carry the phrase single-line.

**Fix (IN C4 scope — validate-pack.py).** Added a whitespace-normalizing
helper `_check_56_phrase_present(text, phrase)` (collapse runs of
whitespace to one space on both sides, then substring) and used it for
the principle-phrase leg. A catch-all phrase wrapped across a line is
semantically identical; the byte-exact dependency was brittle. The
verb-presence matcher (`_check_56_verb_present`) is UNCHANGED.

**Why this is the correct seam, not a bundle edit.** C4's file set is
strictly `validate-pack.py` + per-check tests (plan §3 C4). The bundle
templates are KEEP at HEAD (C5-NOTE). Editing
`.agents-plugin/pack-agents/agents/pack-coder.md` would be OUT of C4
scope. The whitespace-tolerant matcher is the in-scope, robust fix and
keeps Check 56 GREEN as the design's measure-then-bound table projects.

**Verification:** Check 56 prints `OK ... all 28 canonical §5.1 verbs +
the catch-all principle phrase present in each` across 10 surfaces.
`test-validate-pack-check-56.sh` PASSES (its synthetic surfaces are
self-contained, so the matcher change is behavior-preserving on them).

### DEVIATION-2 (line-number drift, not a substantive change)

The plan's line numbers (~L357, L367, L1599, L5656, L8407, L8631, L9104,
L9273, etc.) reference an older ~9000-line `validate-pack.py`; HEAD is
**10112 lines**. All anchors were located by symbol/grep, not line
number (`edit-in-place-not-full-rewrite`). Every recast landed on the
correct symbol. No mega-rewrite; targeted Edits only; touched regions
re-read after editing.

### DEVIATION-3 (PACK_SCAN_LOCATIONS target — design-vs-reality reconciliation, SURFACED)

The DESIGN §5.2 names the `PACK_SCAN_LOCATIONS` replacement as the
client bundle `agents/` + `project-template/.agents/skills`. At HEAD the
**project-side skills live in the pool `project-template/skills/`** (C0
collapsed the per-CLI dirs); `project-template/.agents/skills` is the
CLIENT-INSTALL target created by `init-project` (it does not exist in
the pack template tree). The pack-template surface where a stray `x-`
file could actually live is the POOL `project-template/skills/`. I
pointed PACK_SCAN_LOCATIONS at the live pack-template surfaces (bundle
`agents/` + the pool `project-template/skills`), which is the design's
intent (scan the pack template for `x-` files) realized against the
actual tree. Check 8 skips non-existent dirs, stays green either way.
**No SSOT conflict — this is a pack-side validator; the project-side
skill layout (pool) is the measured reality.** Surfaced per Section 7.

---

## 5. OUT-OF-SCOPE / PRE-EXISTING ISSUES (SURFACED, not fixed — Section 7)

These are NOT C4 regressions. C4's diff is exactly the 6 `scripts/`
files above; none of these failures touch a C4-edited surface.

### PRE-1 — `PACK_VALIDATE_DEEP=1` exits 1 on a BD-226 backlog-data issue (Check 49)

`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → exit 1, ONE
fail-line: `FAIL: Check 49 — BD-226: stored title 288 codepoints
exceeds R-TITLE-1 limit 256`. The BD-226 backlog entry's bold title is
288 codepoints (> the 256 R-TITLE-1 limit). **Check 49's code + the
R-TITLE-1 limit are BYTE-IDENTICAL to HEAD** (C4's diff touches neither
Check 49 nor any backlog file — verified by `git diff` grep). The
failure is BD-226 backlog DATA, present at HEAD (commit 0053ef8, the
`pack-chat-only` BD-226-open commit). Out of C4 scope (backlog is
pack-chat-only; C4 only edits validate-pack checks/constants + per-check
tests). **ALL C4-recast checks (5/8/11/17/18/20/27/31/39/41/43/51/52/
55/56/57 + retired 21/28) are GREEN in DEEP mode too** — the BD-226
Check-49 line is the ONLY DEEP fail-line. Recommend Pack Chat shorten
the BD-226 title (≤256 codepoints) as a separate pack-chat-only fix.

### PRE-2 — `test-validate-pack-check-49-field-faithfulness.sh` fails on the same BD-226 data

The Check 49 per-check test runs the real-tree DEEP leg → fails on the
same BD-226 title-length line. NOT a C4 lockstep test; Check 49 code
unchanged. Same root cause as PRE-1.

### PRE-3 — `test-persona-contracts.sh` (fixture-dependent) fails — owned by C7

Fails on `FAIL v11 artifact .gemini/commands/pack-help.toml MISSING
post-migrate` (the migrator C3 dropped that artifact; the persona
contract still asserts the old `.gemini/` shape). The persona-contracts
+ their test are CONVERT targets in **C7** (plan §3 C7 / §5 census
table). C4 touches none of them. Expected intermediate-red per the
cluster model (plan §1: validate-pack-green ≠ full-suite-green; the
suite reaches green at the C11/C12 green-point).

### PRE-4 — `test-v11-realistic-ot.sh` (fixture-dependent) fails — fixture data / C6

Single failure: `A.16 backlog/ has >= 1 TD-NNN entry (found 0)` — a
v11-realistic-ot FIXTURE-DATA assertion (the fixture has no TD-NNN
entry), NOT a validate-pack assertion. The v11 fixture is reshaped at
**C6** (build.sh version-branch). The test's validate-pack legs (Group C
Check 32′/33/34) all PASS. C4 touches no fixture.

### PRE-5 — `test-fixtures/build.sh --all --clean` errors (EB-21 bug) — fixed at C6

`build.sh` fails at L315-316 (the un-version-branched unconditional
`.gemini/agents/x-fakeot-domain.md` copy) — the documented EB-21 bug the
plan (Section 3) says is fixed at C6. C4 changes ZERO fixture content,
so `test-fixtures/manifest.txt` is provably unaffected; I did NOT
regenerate it and did NOT hand-edit it or work around build.sh (per the
plan's explicit instruction). The committed fixtures already present in
the worktree let the fixture-dependent tests run against existing data.

---

## 6. MANIFEST CONFIRMATION

`test-fixtures/manifest.txt` is UNTOUCHED. C4's diff (`git diff
--name-only`) contains ZERO `test-fixtures/` paths — C4 edits only
`scripts/validate-pack.py` + 5 per-check test scripts, none of which is
part of any fixture tree. The manifest records per-fixture git SHAs, not
content-hashes of scripts, so it is provably unaffected (plan §3 grounded
fact). I did NOT regenerate it (build.sh hits the pre-existing EB-21 bug
— PRE-5 — which is a C6 action). `git status --short test-fixtures/` is
empty.

---

## 7. C4 VERIFY SET — per-check status (plan §7 reviewer checklist)

All measured GREEN in `python3 scripts/validate-pack.py` (general):

| Check | Status | Note |
|---|---|---|
| 5 (agent count) | GREEN | 2-way loose + bundle-roster count parity (16==16==16) |
| 8 (`x-` scan, delta 3) | GREEN | re-verified after PACK_SCAN_LOCATIONS repoint; no `x-` in bundle/pool/prompts; non-existent dirs skipped |
| 11 (trinity symmetry, informational) | GREEN | always-OK; docstring only |
| 16 (project addenda H2, KEEP-FILE) | GREEN | unchanged; test-check-16 PASS |
| 17 (capability parity) | GREEN | 2-way Claude↔Codex; Gemini leg removed |
| 18 (trinity H2 parity ×2) | GREEN | constant `## Antigravity CLI operating notes`; test-check-18 PASS |
| 19 (no-scaffolding ×2, KEEP-FILE) | GREEN | docstring only; test-check-19 PASS |
| 20 (gitignore exception) | GREEN | docstring only; generic exception intact |
| 21 | RETIRED | function + registry + count removed; script-ref folded into Check 1 |
| 27 (canonical phrases) | GREEN | 3rd leg → bundle; all 16 bundle agents carry phrases |
| 28 | RETIRED | function + helper + registry + count removed |
| 31 (skill-cell consistency) | GREEN | unchanged |
| 36/37/38 (boundary trio) | GREEN | checks-36-37-38 test PASS |
| 39 (cmd_update symmetry) | GREEN | already cleared at C2; verified still green; test PASS |
| 41 (`_CLIENT_INSTALLED_FILES`) | GREEN | already cleared at C2; verified still green; test PASS |
| 43 (bare cross-ref) | GREEN | allowlist rationale rewritten basename-keyed (8 entries, no behavior change); test PASS |
| 51 (tracker-deferral guard) | GREEN | recommend-dir legs → `.agents/skills`; token absent |
| 52 (pack RW/RO two-class) | GREEN | 3rd leg → pack-agents bundle; 5 agents × 3 surfaces; test-check-52 PASS |
| 55 (project RW/RO two-class) | GREEN | 3rd leg → optiquity bundle; 16 agents × 3 surfaces; test-check-55 PASS |
| 56 (pack verb parity) | GREEN | 2 surfaces recast; whitespace-tolerant phrase matcher (DEVIATION-1); test-check-56 PASS |
| 57 (project verb parity) | GREEN | 3rd leg → optiquity bundle; 52 surfaces; test-check-57 PASS |
| 25 (customization regression) | GREEN (stays-green) | NO C4 edit; fixture-row removed at C3; verified still green |
| 59 (registry completeness) | GREEN | count 59 == computed; checks-58-59-60 test PASS |

OQ-1 PREFLIGHT (bundle RW/RO headers, plan CONFIRMED-E) — measured present
BEFORE the 52/55/56/57 recasts:
- Check 52 pack-self bundle: 1 source-write (`pack-coder`, `**Source-write
  within scope.**`) + 4 read-only (`**Read-only.**`). PASS.
- Check 55 client bundle: 1 scoped (`coder`, `**Write-capable (scoped).**`)
  + 1 script (`repo-ops`, `**Write-capable (script).**`) + 14 read-only.
  PASS.
No C1/C5 REDO trigger.

Note on header vocabulary: the prompt's Section 2/5 says Check 55 uses
`**Write-capable (scoped/script).**`. The actual SSOT (the code constant
`_CHECK_55_RW_HEADERS`) and DESIGN §5.2 use the TWO distinct headers
`("**Write-capable (scoped).**", "**Write-capable (script).**")`. The
code is the SSOT; the bundle templates carry the two distinct headers and
pass. No change needed — flagging the prompt's compressed shorthand for
transparency.

---

## 8. FULL CI SUITE — every wired test (`verify-full-ci-suite`)

Ran EVERY script wired in `.github/workflows/validate-pack.yml`:
- `validate` job: `python3 scripts/validate-pack.py` → **exit 0**.
- `validate` job DEEP: `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`
  → exit 1 on the PRE-EXISTING BD-226 Check-49 backlog-data line ONLY
  (PRE-1; not a C4 surface).
- `plan` job: `python3 scripts/lib/ci-shard-plan.py --assert-coverage`
  → **exit 0** ("72 wired KEEP test(s) across 4 shard(s); union == wired
  KEEP set; pairwise-disjoint; cohesion co-located").
- `tests` job: ALL 72 wired test scripts run individually (full list at
  `/tmp/wired-tests.txt`; per-test exit codes at
  `/tmp/c4-fullsuite-results.txt`).

**Result: 69/72 PASS. 3 fail — ALL pre-existing / out-of-C4-scope:**
1. `test-validate-pack-check-49-field-faithfulness.sh` — BD-226 title
   data (PRE-2; Check 49 code unchanged).
2. `scripts/tests/fixture-dependent/test-persona-contracts.sh` — C7-owned
   `.gemini/` migrate artifact (PRE-3).
3. `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh` — C6-owned
   fixture TD-NNN data (PRE-4).

Every C4-relevant test PASSES: test-validate-pack-check-{16,18,19,39,41,
43,45,46,52,53,54,55,56,57,61}, checks-{32-33-34,36-37-38,58-59-60},
test-init-project, test-detect, test-customization-preserve, all migrator
tests, all tracker tests, etc.

Proof the 3 failures are not C4-caused: `git diff --name-only` = exactly
{validate-pack.py, test-check-18/41/55/56/57.sh}; none of the 3 failing
tests is in that set; each failing assertion is about a non-C4 surface
(BD-226 backlog data / `.gemini/` migrate artifact / fixture TD-NNN data);
Check 49 + R-TITLE-1 code is byte-identical to HEAD (`git diff` grep on
TITLE/256/codepoint/faithful = empty).

---

## 9. DEFINITION-OF-DONE CHECKLIST

| Item | Verdict |
|---|---|
| Pre-flight: worktree at HEAD 0053ef8, isolated path confirmed | PASS |
| BASE = 52 fail-lines (post-C3 baseline) | PASS |
| `validate-pack.py` exit 0 (AFTER empty, GREEN) | PASS |
| `NEW` (comm -13) empty — no new fail-line | PASS |
| `CLEARED` (comm -23) = all 52 | PASS |
| Registry count → 59 (Check 59 green; count test PASS) | PASS |
| Checks 21 + 28 fully retired (no dead/commented code) | PASS |
| Check-21 script-ref folded into Check 1 | PASS |
| Check 8 re-verified after PACK_SCAN_LOCATIONS repoint (delta 3) | PASS |
| Check 25 stays-green (no C4 edit) | PASS |
| All 5 lockstep per-check tests (18/41/55/56/57) PASS | PASS |
| Full wired CI suite: only pre-existing/out-of-scope failures | PASS |
| `_CHECK_43_ALLOWLIST` unchanged count (8); rationale-only | PASS |
| `_CHECK_47_SANCTIONED...` untouched (no allowlist growth) | PASS (not edited) |
| Manifest untouched (zero fixture content changed) | PASS |
| OQ-1 bundle RW/RO headers present before recasts | PASS |
| Boundary: all edits `scripts/` only (pack-only) | PASS |
| No git state change (edits uncommitted; HEAD unchanged) | PASS |
| Gate A (`.gemini/` paths) ZERO in all 6 edited files | PASS |
| New POQs introduced | 0 (see §10) |

---

## 10. NEW POQs

None introduced. Three out-of-scope items SURFACED for Pack Chat triage
(not POQs — they are pre-existing conditions with named owning commits):
- BD-226 title length (288 > 256 codepoints) trips DEEP Check 49 +
  test-check-49 — recommend a pack-chat-only BD-226 title trim (PRE-1/PRE-2).
- test-persona-contracts (C7) + test-v11-realistic-ot (C6) +
  build.sh EB-21 (C6) are expected intermediate-red owned by later
  cluster commits (PRE-3/PRE-4/PRE-5).

---

## 11. BOUNDARY DISCIPLINE CHECK (P-missed-7)

C4 is `pack-only`. Every edited file is under `scripts/`
(`scripts/validate-pack.py` + `scripts/tests/*.sh`) — a pack-side
surface, NOT a `project-template/` / `supporting-docs/` client surface.
No project-side file was edited, so the project-side-SSOT pre-flight
does not apply. No pack-only reference was added to any client surface
(none touched). No boundary-discipline STOP. The recast targets
(`.agents-plugin/optiquity-agents/agents`, `.agents/skills`,
`project-template/skills`) are the project-side Antigravity surfaces the
pack-side validator legitimately measures — naming a project-template
path inside the pack validator is the validator's defined job (it
validates `project-template/`), not a boundary leak.

---

## 12. NEXT STEP (isolation model)

Edits are UNCOMMITTED in the worktree
(`…/.claude/worktrees/agent-a8e76afb45108f9bc`). NO patch emitted. I
await the post-review SendMessage to produce the `git diff` patch ONLY
if the read-only reviewer confirms CLEAN. HEAD unchanged
(`0053ef8bcf4253dc8b7ae08de5978cb4782da1b2`). I never staged, committed,
applied, or ran any state-changing git verb.

---

## 13. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git (`git rev-parse HEAD`, `git status --short`, `git diff --name-only`, `git show HEAD:...`, `git log`). `git rev-parse HEAD` = `0053ef8...` (unchanged). `git status --short` shows ` M` on 6 files (uncommitted). No `add`/`commit`/`apply`/`stash`/`checkout`/`restore` run. No patch emitted (per the new model). | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op run on own authority. Surfaced (did not delete) the BD-226 title, the EB-21 build.sh bug, the C6/C7-owned test failures. Did NOT hand-edit/regen the manifest. Code-removals (Checks 21/28) are the approved C4 task per plan §3. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted exactly ONE `PREFLIGHT: 6/6 in-scope edits complete; verification PASS; HEAD 0053ef8...; about to Write IMPL-REPORT to /tmp/handoff-bd221-C4/IMPL-REPORT-C4.md` AFTER all edits + full-suite verification + the comm gate (NEW empty, AFTER empty) passed. No stop message received. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All edits via targeted Edit tool on a 10112-line file; zero full-file Write of validate-pack.py. Touched regions re-read after editing (constants, Check 5/17/18/27/56, registry). No section dropped (Python `ast.parse` OK; Check 59 registry count == computed 59). | COMPLIANT |
| **verify-full-ci-suite** | Ran `validate-pack.py` (exit 0) + DEEP + `ci-shard-plan --assert-coverage` (exit 0) + ALL 72 wired test scripts individually (`/tmp/c4-fullsuite-results.txt`). 69/72 PASS; 3 failures proven pre-existing/out-of-scope (§8). Enumerated validator-output-pinning tests (test-check-18 `## Antigravity CLI operating notes`, test-check-55/56/57 surface asserts, checks-58-59-60 count). | COMPLIANT |
| **enumerate-encoding-surfaces** | Each check recast moved WITH its per-check test in the same commit: Check 18→test-check-18; Check 55→test-check-55; Check 56→test-check-56 (drop_surface); Check 57→test-check-57 (drop_surface). Registry count change (61→59)→verified the count-pinning test (checks-58-59-60 reads `mod.CHECK_REGISTRY_EXPECTED_COUNT` dynamically) PASSES. No per-check test exists for retired 21/27/28 (nothing to update). | COMPLIANT |
| **ci-check-runtime-compounding** | No recast widened a check's scan scope into a whole-real-tree scan or a subprocess-per-entry loop. Check 8/27/51/52/55/56/57 still scan the same bounded dir sets (now Antigravity surfaces). The new `_check_56_phrase_present` is a bounded `" ".join(text.split())` normalize — O(file), no subprocess, no new loop. Check 56 OK message confirms "10 single-file reads; no subprocess". | COMPLIANT |
| **rename-plans-measure-then-bound** | After editing, grepped the 6 edited files for `.gemini/` (Gate A) → ZERO in validate-pack.py + ZERO in all 5 edited tests. Remaining bare `gemini`/`Gemini` tokens in validate-pack.py categorized: 3 are GEMINI.md trinity-FILE refs (KEEP, allowlist class 3) + the Check-18 `gemini`=`h2_lists["GEMINI.md"]` local (KEEP) + `GEMINI-CLI-ANALYSIS.md` (removed-doc allowlist) + `GEMINI_INTRINSIC_H2S` constant name. No dead `.gemini/` path token remains in C4's files. | COMPLIANT |
| **fail-loud-delete-old-source** | Checks 21 + 28 + the `_extract_pm_startup_sections` helper FULLY REMOVED (function body + registry entry + count decrement) — replaced with a one-line retirement comment, NO commented-out code body. Verified: `grep check_pack_help_per_cli_parity / check_pm_startup_per_cli_parity / _extract_pm_startup_sections` returns only the two retirement comments, no live code. | COMPLIANT |
| **pack-repo-code-comment-deferrals** | C4 introduced ZERO deferral comments (no `# TODO`/`# FIXME`/`# KNOWN GAP`). The retirement comments are factual ("RETIRED in BD-221"), not deferrals. | N/A: no deferral comment introduced |
| **rules-applied-verification-block** | This block. Each rule has quoted evidence + a terminal conclusion (no AMBIGUOUS). | COMPLIANT |
| **isolation-model behavior (Section 1)** | First action confirmed `pwd` = `…/.claude/worktrees/agent-a8e76afb45108f9bc` + HEAD = 0053ef8. All edits in THIS worktree only; main checkout untouched. NO patch emitted; edits left uncommitted; STOP after IMPL-REPORT; await post-review SendMessage. | COMPLIANT |
| **manifest-untouched fact (Section 3)** | `git diff --name-only` contains zero `test-fixtures/` paths; `git status --short test-fixtures/manifest.txt` empty. Did not regenerate (build.sh hits the pre-existing EB-21 bug, a C6 action) and did not hand-edit. Manifest provably unaffected (C4 changes zero fixture content). | COMPLIANT |


