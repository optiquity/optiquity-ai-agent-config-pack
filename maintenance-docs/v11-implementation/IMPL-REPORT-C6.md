# IMPL-REPORT — BD-221 Commit C6 (pack-only)

`compare-agent-trinity.py` + `test-compare-agent-trinity.sh` + `test-fixtures/build.sh`
version-branch (EB-21 fix) + `test-fixtures/README.md` + manifest regen.

## Execution context

- **Regime:** ISOLATED WORKTREE (per `Sub-agents run in-place by default; isolation is opt-in` — verified at runtime).
- **Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1a6909a337744783`
- **Branch:** `worktree-agent-a1a6909a337744783`
- **HEAD (unchanged):** `33ac5ac227e2f41b5cb48b3d347e774c1457a20c`
- **BASE FAIL lines:** EMPTY (HEAD green) — `/tmp/c6-base.txt`.
- **Patch emitted?** NO. Edits left UNCOMMITTED in the worktree. Awaiting post-review SendMessage to produce the patch (per Section 1 of the prompt). The orchestrator stages `test-fixtures/manifest.txt` via pathspec at commit — I did NOT `git add` it.

## Files changed (inventory)

| Path | Change type | Lines |
|---|---|---|
| `scripts/compare-agent-trinity.py` | modified | +44 / −16 |
| `scripts/test-compare-agent-trinity.sh` | modified | +22 / −11 |
| `test-fixtures/build.sh` | modified | +32 / −2 |
| `test-fixtures/README.md` | modified | +2 / −2 |
| `test-fixtures/manifest.txt` | modified (regenerated) | +3 / −3 |

`git diff --name-only` returns exactly these 5 — all `pack-only` (`scripts/` + `test-fixtures/`). No `project-template/`, no `supporting-docs/`. `scripts/merge-trinity.py` confirmed UNTOUCHED (Section 2D).

---

## Task A — `test-fixtures/build.sh` version-branch (EB-21 fix, LOAD-BEARING)

### The bug (confirmed)
`_build_realistic_for_version()` (takes `$ver`) wrote the third-CLI custom agent
UNCONDITIONALLY: `cp .claude/agents/x-fakeot-domain.md → .gemini/agents/x-fakeot-domain.md`.
This function is called for BOTH v10 and v11. For v11 the v11 skeleton creates no
`.gemini/agents/` dir, so the `cp` fails. **Baseline reproduction:**

```
$ bash test-fixtures/build.sh --name v11-realistic-ot
── building v11-realistic-ot ──
cp: .../test-fixtures/v11-realistic-ot/.gemini/agents/x-fakeot-domain.md: No such file or directory
EXIT: (die)
```

This is why the fixture-dependent shard failed in C4/C5: the v11 fixture could not
be built, so every test that consumes it errored "fixture missing".

### The fix — version-branch the third-CLI write
The Claude (`.claude/agents/`) and Codex (`.codex/agents/`) loose dirs are
version-agnostic (both v10 and v11 carry them) — the custom agent always lands
there. Only the THIRD-CLI write is branched:

- **v10** → KEEP `cp ... .gemini/agents/x-fakeot-domain.md` (carve-out i — v10
  source fixtures stay Gemini-shaped as migration inputs).
- **v11** → `mkdir -p .agents-plugin/optiquity-agents/agents` then
  `cp ... .agents-plugin/optiquity-agents/agents/x-fakeot-domain.md` (the
  Antigravity client plugin bundle).

Implemented as a `case "$ver" in v10) ... ;; v11) ... ;; esac` block (bash 3.2
compatible). `$ver` is in scope (set as `${1:?...}` at function entry).

### How I verified the v11 custom-agent surface against init-project.sh (Section 2A — the riskiest decision)
The fixture's `x-fakeot-domain` is a CUSTOM (`x-` prefix, project-owned) agent. I
traced the v11 install shape against the C2-converted `scripts/init-project.sh`
and `scripts/lib/detect.sh`:

1. **`init-project.sh` `stage_s1_skeleton` (L422-423):** v11 creates
   `.claude/agents`, `.codex/agents`, `.claude/skills`, `.codex/skills`,
   `.agents/skills` — **NO loose `.agents/agents/`** dir. Antigravity has no
   loose per-CLI agent dir.
2. **`init-project.sh` `stage_s2_agents` (L433-468):** Claude/Codex agents are
   loose; **Antigravity agents ship as a plugin BUNDLE** —
   `cp -R project-template/.agents-plugin/optiquity-agents` into the target.
3. **`detect.sh` `detect_improperly_added_files` (L223-225):** explicit comment —
   "Antigravity agents ship as a plugin bundle (.agents-plugin/), not a loose
   per-CLI dir, so only the Claude/Codex loose dirs are scanned." There is no
   loose Antigravity custom-agent surface.
4. **DESIGN §5 mapping table (L191):** `.gemini/agents/*.md (client, loose)` →
   `project-template/.agents-plugin/optiquity-agents/agents/*.md (bundle)` —
   "client agents are a plugin BUNDLE (decision a)".

**Conclusion:** the only v11 Antigravity agent surface is the client plugin
bundle `.agents-plugin/optiquity-agents/agents/`, so a project-owned `x-` custom
Antigravity agent lives there. This is the v11 fixture target. Verified at build
time: the v11 fixture now carries
`.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md` and NO `.gemini/`
dir; the v10 fixture still carries `.gemini/agents/x-fakeot-domain.md`.

### Also (build.sh existing-project comment)
`# but with zero pack-shipped files (no .claude/, .codex/, .gemini/,` →
`(no .claude/, .codex/, .agents/,`. KEPT the adjacent
`# CLAUDE.md / AGENTS.md / GEMINI.md` trinity-FILE line. KEPT the trinity comment
(L183 `CLAUDE/AGENTS/GEMINI`) + the trinity fill loop (L273
`for f in CLAUDE.md AGENTS.md GEMINI.md`).

---

## Task B — `scripts/compare-agent-trinity.py`

Re-expressed the 3rd (`gemini`) leg from `.gemini/agents` to the plugin bundle
roster `project-template/.agents-plugin/optiquity-agents/agents/`. The COMPARISON
LOGIC is unchanged (it already excludes tool-specific frontmatter incl. `model`
per "What is NOT compared"). Edits:

- **Module docstring (L7-17):** the three-format list now names
  `.agents-plugin/optiquity-agents/agents/<name>.md` as the third (Antigravity
  plugin-bundle) leg + a BD-221 note that the comparison logic is unchanged.
- **`The script reads ...` docstring (L46-49):** names the three read paths
  (Claude loose, Codex loose, Antigravity client bundle).
- **`read_agent` (L111+):** added a `tool == "agents"` branch that resolves the
  bundle path `.agents-plugin/optiquity-agents/agents/<name>.{ext}`; the
  Claude/Codex branch is unchanged. Added a docstring note.
- **`compare_one` (L167+):** renamed the local var `gemini` → `agents`; the 3rd
  `read_agent` call now passes `"agents"`; all labels/messages updated
  (`agents=...`, "the Antigravity bundle agent differs"); logic identical.

Bundle roster verified identical to `.claude/agents` (non-`x-`): both 16 names
{architect, auditor, auditor-*, coder, docs-researcher, grpc-schema, planner,
repo-ops, reviewer, tester}. Bundle files are Markdown-with-frontmatter carrying
`name:` (e.g. `coder.md` → `name: coder`), so the comparator's existing parser
applies unchanged.

Python syntax check: `ast.parse` → SYNTAX OK. No `gemini`/`Gemini` token remains
in the file (grep exit 1 = none).

---

## Task C — `scripts/test-compare-agent-trinity.sh` (LOCKSTEP)

- **`mkpack`:** now creates `.agents-plugin/optiquity-agents/agents` for the 3rd
  leg instead of `.gemini/agents` (KEEPS `.claude/agents` + `.codex/agents`).
- **`write_gemini_agent` → `write_agents_agent`:** writes to
  `.agents-plugin/optiquity-agents/agents/$name.md`; **REMOVED the
  `model: gemini-2.5-pro` fixture string (OQ-4)** — the synthetic fixture frontmatter
  is now `name:` + `description:` only (the comparator ignores tool-specific
  frontmatter). Added a comment explaining the omitted-model rationale (the
  bundle templates carry a forward-looking `#27305` model hedge).
- **All 7 call sites:** `write_gemini_agent` → `write_agents_agent` (Tests 1, 2,
  3, 4, 6×2, 7).
- **Test 5 comment:** `# (no gemini variant)` → `# (no Antigravity bundle variant)`.
- No `GEMINI.md` writes exist in this test (none to KEEP).

bash syntax check: SYNTAX OK. No `gemini`/`Gemini` token remains (grep exit 1).

---

## Task D — `scripts/merge-trinity.py`
**NO change** (trinity-FILE only — KEEP). Confirmed UNTOUCHED via
`git diff --name-only | grep merge-trinity` → no match.

---

## Task E — `test-fixtures/README.md`
- **L30 (v11-realistic-ot):** `C3 writes x-fakeot-domain to v11's .codex/agents/,
  .claude/agents/, .gemini/agents/` → `..., .claude/agents/, and the Antigravity
  client plugin bundle .agents-plugin/optiquity-agents/agents/`.
- **L33 (existing-project-mid-dev):** `no .claude/, .codex/, .gemini/,
  CLAUDE.md/AGENTS.md/GEMINI.md` → `no .claude/, .codex/, .agents/,
  CLAUDE.md/AGENTS.md/GEMINI.md` (matches the build.sh L617 comment conversion;
  KEEPS the trinity-FILE list).
- **KEPT L29 (v10-realistic-ot narration `Claude/Codex/Gemini`)** — v10 narration
  carve-out.
- **KEPT L34 (`v11-trinity-marker-prepped` row, `CLAUDE/AGENTS/GEMINI`)** — trinity
  FILE references (Section 2E explicit KEEP).

---

## Task F — `test-fixtures/manifest.txt` regen (LOCKSTEP with A)

Ran `bash test-fixtures/build.sh --all --clean` (now SUCCEEDS — EB-21 fixed; all 6
fixtures built) then `bash test-fixtures/build.sh --verify` → all 6 OK (fixtures
match the regenerated manifest), exit 0.

**Manifest diff:**

```
 v10-minimal  19558cbac...                       (UNCHANGED — carve-out)
 v10-realistic-ot  4c62945f7...                   (UNCHANGED — carve-out)
-v11-realistic-ot  e9972b936...
+v11-realistic-ot  83fa42ec1...                   (CHANGED — custom agent .gemini → bundle)
-v11-flat-file  03f85550f...
+v11-flat-file  8176d3193...                      (CHANGED — see note below)
-v11-tracker-on  39652fea6...
+v11-tracker-on  6f41c7eb9...                     (CHANGED — see note below)
 existing-project-mid-dev  a54e081a9...           (UNCHANGED)
```

- **v10 SHAs UNCHANGED** (carve-out i preserved) ✓
- **v11-realistic-ot SHA CHANGED** — directly attributable to the C6 fix (custom
  agent moved `.gemini/agents/` → bundle) ✓

### Note: v11-flat-file / v11-tracker-on SHA change (investigated — NOT a C6 defect)
These two fixtures do NOT use `_build_realistic_for_version` (they use
`_build_v11_flat_file` / `_build_v11_tracker_on` — disjoint build functions), so
my build.sh edit cannot affect their content. Investigation:

1. Fixture SHAs are content-deterministic: `_fixture_commit_all` pins
   `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE`/name/email to fixed `$FIXTURE_EPOCH` /
   `$FIXTURE_AUTHOR_*`. Rebuilding v11-flat-file twice yields the identical SHA
   `8176d319...` (STABLE).
2. The HEAD manifest was last regenerated at commit `b2f08d0` (2026-06-15,
   BD-219) — BEFORE the BD-221 cluster commits C0–C5 (which landed at/before
   `33ac5ac`). C0–C5 touched v11-surface scripts (init-project.sh etc.) whose
   output flows into these fixtures, so the HEAD manifest rows for
   flat-file/tracker-on were STALE relative to current pack content.
3. C6 is a v11-surface commit, so the `regenerate-manifest-v11-surface` rule
   mandates the regen — which correctly refreshes these stale rows. This is the
   intended behavior, not a regression.

**Surfaced (not silently fixed):** the HEAD manifest carried two stale v11
fixture SHAs from a prior v11-surface commit that did not regen them. C6's
mandated regen resolves it. No action needed beyond what C6 does.

---

## Verification gate results (Section 3)

| Gate | Command | Result |
|---|---|---|
| validate default | `python3 scripts/validate-pack.py` | exit 0; FAIL lines EMPTY; `PASSED — all checks clean` |
| NEW delta | `comm -13 /tmp/c6-base.txt /tmp/c6-after.txt` | EMPTY (no new fail-line) |
| validate DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | exit 0; `PASSED — all checks clean` |
| build verify | `bash test-fixtures/build.sh --verify` | exit 0; all 6 fixtures OK |
| shard coverage | `python3 scripts/lib/ci-shard-plan.py --assert-coverage` | exit 0; 72 wired, union==KEEP, disjoint, cohesion co-located |

### Full wired CI suite (`verify-full-ci-suite`) — 72 tests across 4 shards

**Result: 71 PASS / 1 FAIL.** The ONLY failure is the KNOWN C7-owned
`test-persona-contracts.sh`.

| Shard | Tests | Passed | Failed |
|---|---|---|---|
| 1 (fixture-owner) | 22 | 21 | `test-persona-contracts.sh` (C7-owned) |
| 2 | 14 | 14 | — |
| 3 | 18 | 18 | — |
| 4 | 18 | 18 | — |

**The four C6-relevant fixture-dependent / comparator tests (failing in C4/C5
due to EB-21) now PASS:**
- `test-v11-realistic-ot.sh` → exit 0; "All v11-realistic-ot integration tests PASSED (33/33)."
- `test-migrator-skills.sh` → exit 0; "19 passed, 0 failed".
- `test-dry-run-migration.sh` → exit 0; "7 passed, 0 failed".
- `scripts/test-compare-agent-trinity.sh` → exit 0; "10 total, 10 passed, 0 failed" (converted in B/C, GREEN).

**`test-persona-contracts.sh` failure is C7-owned (confirmed cause):** it asserts
the pre-conversion `gemini` skill install legs —
`FAIL skill gemini/api-design/SKILL.md MISSING`, `gemini/audit-methodology/...`,
etc. (the contract scripts iterate `for tool in claude codex gemini` and check
`gemini/<skill>/SKILL.md`). The persona-contracts conversion is assigned to C7
(plan §3 C7), not C6. This is the ONLY remaining wired-suite failure after C6 —
confirmed: nothing else failed.

---

## grep-zero residue (`rename-plans-measure-then-bound`) — the 4 converted files + build.sh + README

Gate A (`grep -rnI "\.gemini/"`) + Gate B (`grep -rniI "gemini"`) over
`compare-agent-trinity.py`, `test-compare-agent-trinity.sh`, `build.sh`,
`README.md`. Every remaining token is KEEP-LEGITIMATE per the §6 allowlist:

| File:line | Token | KEEP class | Justification |
|---|---|---|---|
| `compare-agent-trinity.py` | (none) | — | fully gemini-free (grep exit 1) |
| `test-compare-agent-trinity.sh` | (none) | — | fully gemini-free (grep exit 1) |
| `build.sh:183` | `CLAUDE/AGENTS/GEMINI` | 3 | trinity-FILE names (trinity comment — Section 2A KEEP) |
| `build.sh:273` | `CLAUDE.md AGENTS.md GEMINI.md` | 3 | trinity-FILE fill loop (Section 2A KEEP) |
| `build.sh:306` | `.gemini/agents/x-fakeot-domain.md` | 1 | v10 carve-out comment (v10 fixtures stay Gemini-shaped) |
| `build.sh:307` | `Gemini-shaped` | 1 | v10 carve-out comment |
| `build.sh:334` | `Gemini-shaped` | 1 | v10 carve-out comment |
| `build.sh:336` | `.gemini/agents/x-fakeot-domain.md` | 1 | v10 carve-out WRITE (the only v10-third-CLI custom-agent write) |
| `build.sh:646` | `CLAUDE.md / AGENTS.md / GEMINI.md` | 3 | trinity-FILE names (existing-project comment — Section 2A KEEP GEMINI.md) |
| `README.md:29` | `Claude/Codex/Gemini` | 1 | v10-realistic-ot narration (v10 narration carve-out) |
| `README.md:33` | `GEMINI.md` | 3 | trinity-FILE name |
| `README.md:34` | `CLAUDE/AGENTS/GEMINI`, `GEMINI` | 3 | trinity-FILE names (`v11-trinity-marker-prepped` row — Section 2E KEEP) |

**Zero contamination remains.** No `.gemini/` PATH or bare `gemini` token exists
outside the documented v10 carve-out (class 1) and the GEMINI.md trinity-FILE /
trinity-comment surfaces (class 3).

---

## Plan deviations

**ZERO functional deviations.** All C6 surfaces converted exactly as the plan §3
C6 + DESIGN §5.12 specify. Two non-deviation notes:

1. **Worktree base differs from the plan's stated parent baseline.** The plan §7
   PREFLIGHT-0 cites a CONTAMINATED-vs-clean 62/61-baseline for C0's parent
   `9d8bf22`. My worktree bases at `33ac5ac` where C0–C5 have already landed and
   validate-pack is GREEN (BASE FAIL lines empty). C6's job here is to re-green
   the fixture shard against the already-green validator state — which the
   verification confirms. This is the prompt's stated regime, not a deviation
   from the C6 surface spec.
2. **v11-flat-file / v11-tracker-on manifest SHAs changed** (documented in Task F
   note) — pre-existing stale-manifest rows from a prior v11-surface commit,
   correctly refreshed by C6's mandated regen. Not a C6 content change.

## New POQs introduced
**None.**

---

## Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| build.sh EB-21 version-branch (v10 KEEP `.gemini`, v11 → bundle) | PASS | `case "$ver"` block L332-344; baseline `cp` failure reproduced + now resolved |
| v11 custom-agent path verified against init-project.sh | PASS | detect.sh L223-225 + init-project S1/S2 + DESIGN L191 → client plugin bundle |
| compare-agent-trinity.py 3rd leg → bundle (logic unchanged) | PASS | `read_agent` `tool=="agents"` branch; docstrings; SYNTAX OK |
| test-compare-agent-trinity.sh LOCKSTEP (bundle fixtures, model removed) | PASS | `write_agents_agent`; `model: gemini-2.5-pro` removed; 10/10 PASS |
| merge-trinity.py NO change | PASS | git diff — UNTOUCHED |
| README.md v11 + existing-project converted; v10 + trinity KEPT | PASS | L30/L33 converted; L29/L34 kept |
| manifest regen + stage (v11 SHA changes, v10 unchanged) | PASS | `--all --clean` + `--verify` exit 0; diff shows v11 changed, v10 unchanged |
| validate-pack default GREEN; NEW=0 | PASS | exit 0; FAIL empty; `comm` NEW empty |
| validate-pack DEEP GREEN | PASS | exit 0; clean |
| Full wired CI suite (72) run | PASS | 71/72 pass; only `test-persona-contracts.sh` (C7-owned) fails |
| fixture shard GREEN (the 4 named) | PASS | v11-realistic-ot 33/33, migrator-skills 19, dry-run 7, compare-trinity 10 |
| persona-contracts is the ONLY remaining wired failure | PASS | all 71 others green; cause = pre-conversion gemini skill legs (C7) |
| grep-zero residue = KEEP allowlist only | PASS | residue table above; all class 1 (v10 carve-out) / class 3 (GEMINI.md trinity) |
| boundary: only scripts/ + test-fixtures/ touched | PASS | `git diff --name-only` = 5 files, all pack-only |
| no state-changing git verb; edits uncommitted | PASS | git status shows ` M` only; manifest not `git add`-ed |
| no patch emitted | PASS | awaiting post-review SendMessage |

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Only Edit/Write tools used for edits; only read-only git (`status`, `diff`, `rev-parse`, `log`) + build/verify commands run. `git status --short` shows ` M` (working-tree modified, not staged). manifest.txt NOT `git add`-ed. No commit/stage/apply/checkout/etc. invoked. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op run on own authority. The v11-flat-file/tracker-on SHA-change anomaly was INVESTIGATED + SURFACED in the report (not silently "fixed"); `build.sh --all --clean` is explicitly sanctioned C6 work (Section 1 exception). No `rm -rf`/`git rm`/trusted-file overwrite. | COMPLIANT |
| `preflight-stop-means-stop` | Single `PREFLIGHT:` line emitted ONLY after all Section 3 gates PASS (validate default+DEEP green, NEW=0, fixture shard green, build --verify OK, manifest staged). No stop/halt message received. | COMPLIANT |
| `regenerate-manifest-v11-surface` | C6 touches `scripts/` (v11-surface) AND changes v11 fixture shape. Ran `bash test-fixtures/build.sh --all --clean`; manifest diff NON-EMPTY (3 v11 rows changed); `--verify` exit 0. Left as working-tree change for the orchestrator to stage via pathspec. | COMPLIANT |
| `verify-full-ci-suite` | Ran EVERY one of the 72 wired test scripts in `.github/workflows/validate-pack.yml` (derived via `ci-shard-plan.py --print-partition`), recording each shard's pass/fail. 71 PASS; the 1 FAIL (`test-persona-contracts.sh`) is the prompt-acknowledged C7-owned test, cause confirmed (pre-conversion `gemini` skill legs). Plus validate default+DEEP + `--assert-coverage`. NOT sampled. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | All 5 files edited via targeted `Edit` calls (no full-file Write of an existing file). Re-read the comparator docstring region (L3-24) + build.sh version-branch (L300-347) after editing to confirm the actual bytes match intent. | COMPLIANT |
| `rename-plans-measure-then-bound` | Ran the two-family grep-zero gate (Gate A `.gemini/` + Gate B bare `gemini`) over the converted file set; every residue categorized in the residue table; all are KEEP class 1 (v10 carve-out) or class 3 (GEMINI.md trinity) — zero contamination. | COMPLIANT |
| `ci-check-runtime-compounding` | Comparator edit changed only the 3rd-leg PATH + var names + docstrings; introduced NO new whole-tree scan, NO subprocess-per-entry loop. `read_agent` still reads ONE file per leg. Check 11 (its caller) is informational/unchanged. | COMPLIANT |
| `rules-applied-verification-block` | This block. Each rule has quoted evidence + a terminal COMPLIANT/N-A/VIOLATED conclusion; isolation-model behavior recorded below. | COMPLIANT |

### Isolation-model behavior (Section 1)
Confirmed isolated worktree at runtime (`pwd` = `.claude/worktrees/agent-...`,
HEAD `33ac5ac`, branch `worktree-agent-...`). Edits left UNCOMMITTED. NO patch
emitted (awaiting post-review SendMessage per the prompt). manifest.txt is a
working-tree change, NOT `git add`-ed — the orchestrator stages it via pathspec
at commit time.
