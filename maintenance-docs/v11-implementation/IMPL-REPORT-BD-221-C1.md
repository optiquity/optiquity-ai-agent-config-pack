# IMPL-REPORT — BD-221 C1 (project agent-model fork → Antigravity plugin)

**Commit:** C1 of the BD-221 Gemini→Antigravity conversion cluster.
**Scope keyword:** `project-only`.
**Branch:** `v11-dev`. **HEAD this run:** `c9ef6c5056fbca1eb3acaad7917ce09c22e7cc73`
(`git rev-parse HEAD`).
**Regime:** IN-PLACE (pwd = `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`,
branch `v11-dev` — not a `worktree-agent-*` path). Edits left in the
working tree; no `/tmp` handoff dir named for C1; this report goes to the
named parent-tree path.
**Coder:** fresh pack-coder.
**Date:** 2026-06-15. **`agy --version`:** `1.0.8` (binary at
`/opt/homebrew/bin/agy`; recorded per the §5 forward-looking register
`agy --version` pin point).

> **INTERMEDIATE-RED cluster commit.** C1 deletes the 16 client agent
> files. validate-pack CANNOT be green after C1 — by design. This report's
> PREFLIGHT asserts EXPECTED-BREAK-ONLY (the failing checks are a SUBSET of
> {Check 5, Check 27, dir-dependent checks}), NOT a green claim. The
> content axis restores at C8; the install-map axis (untouched at C1)
> restores at C9.

---

## 0. PREFLIGHT line (emitted before this Write)

```
PREFLIGHT: C1 complete; expected-break-only confirmed (validate-pack red on
{Check 5, Check 55, Check 57} ⊆ {Check 5, Check 27, dir-dependent checks};
Check 27 stayed green — empty .gemini/agents/ dir survives the rm, benign
subset; NO unexpected break); 16 agents → plugin bundle (names preserved);
agent-run.sh agy leg done; manifest NOT regen (C10-only); about to Write
IMPL-REPORT
```

---

## 1. Pre-flight evidence (regime + base verification)

```
$ git rev-parse HEAD
c9ef6c5056fbca1eb3acaad7917ce09c22e7cc73          # matches the prompt's base
$ git rev-parse --abbrev-ref HEAD
v11-dev                                            # not worktree-agent-* ⇒ IN-PLACE
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev   # parent tree ⇒ IN-PLACE
$ git status --short                               # clean working tree at start
(empty)
$ ls project-template/.gemini/agents/*.md | wc -l
16                                                 # the 16 client agents present
$ ls project-template/.agents-plugin/ 2>&1
No such file or directory                          # bundle genuinely new (OQ-3)
$ agy --version
1.0.8                                              # agy installed
```

Base correct, regime IN-PLACE, expected pre-state present. Proceeded.

---

## 2. What C1 did (per plan §3 "C1" + §1.2 OQ-3 + §5 register)

1. **DELETED** the 16 `project-template/.gemini/agents/*.md` files (the
   client roster) via filesystem `rm` (a working-tree edit, not a git
   verb — `agents-never-commit` honored). The now-empty `.gemini/agents/`
   directory itself remains on disk (git does not track empty dirs; the
   rest of the `.gemini/` tree is C2's concern).
2. **CREATED** the client plugin bundle at
   `project-template/.agents-plugin/optiquity-agents/` (OQ-3 source path):
   - `plugin.json` — the bundle marker. Inner FIELD schema marked
     FORWARD-LOOKING.
   - `agents/` — 16 templates, one per agent, **names preserved EXACTLY**.
   - `RUNTIME-SUBAGENT-PATTERN.md` — the A3 hedge (thin runtime-
     `define_subagent` pattern doc, FORWARD-LOOKING).
3. **CONVERTED** `project-template/agent-run.sh` — replaced the Gemini leg
   with an `agy` leg (targeted in-place edits; the Claude + Codex legs are
   intact). Per `edit-in-place-not-full-rewrite`.

The manifest was NOT regenerated (C10-only, plan F3). No validator,
init-project, install-map, or pack-self surface was touched (scope guard).

---

## 3. The 16 preserved agent names (old → new)

Names preserved EXACTLY (1:1). Each new template faithfully adapts the
role / permission profile / output policy / hard rules from the deleted
Gemini file.

| # | Deleted (old) | Created (new) — role preserved |
|---|---|---|
| 1 | `project-template/.gemini/agents/architect.md` | `project-template/.agents-plugin/optiquity-agents/agents/architect.md` |
| 2 | `…/.gemini/agents/coder.md` | `…/optiquity-agents/agents/coder.md` |
| 3 | `…/.gemini/agents/reviewer.md` | `…/optiquity-agents/agents/reviewer.md` |
| 4 | `…/.gemini/agents/planner.md` | `…/optiquity-agents/agents/planner.md` |
| 5 | `…/.gemini/agents/tester.md` | `…/optiquity-agents/agents/tester.md` |
| 6 | `…/.gemini/agents/docs-researcher.md` | `…/optiquity-agents/agents/docs-researcher.md` |
| 7 | `…/.gemini/agents/grpc-schema.md` | `…/optiquity-agents/agents/grpc-schema.md` |
| 8 | `…/.gemini/agents/repo-ops.md` | `…/optiquity-agents/agents/repo-ops.md` |
| 9 | `…/.gemini/agents/auditor.md` | `…/optiquity-agents/agents/auditor.md` |
| 10 | `…/.gemini/agents/auditor-architecture.md` | `…/optiquity-agents/agents/auditor-architecture.md` |
| 11 | `…/.gemini/agents/auditor-code.md` | `…/optiquity-agents/agents/auditor-code.md` |
| 12 | `…/.gemini/agents/auditor-docs.md` | `…/optiquity-agents/agents/auditor-docs.md` |
| 13 | `…/.gemini/agents/auditor-ops.md` | `…/optiquity-agents/agents/auditor-ops.md` |
| 14 | `…/.gemini/agents/auditor-security.md` | `…/optiquity-agents/agents/auditor-security.md` |
| 15 | `…/.gemini/agents/auditor-tests.md` | `…/optiquity-agents/agents/auditor-tests.md` |
| 16 | `…/.gemini/agents/auditor-ui.md` | `…/optiquity-agents/agents/auditor-ui.md` |

Faithfulness notes (per-template adaptations vs. the deleted Gemini file):
- **Frontmatter `model:`** — the deleted files pinned `gemini-2.5-pro` /
  `gemini-2.5-flash`. The new templates set `model: default` with a
  `# RE-VERIFY at impl: model IDs — reference the Antigravity default
  model` marker (plan §5: "do NOT pin; reference the Antigravity default
  model"). All other frontmatter (`name`, `description`, `temperature`,
  `max_turns`) preserved verbatim.
- **Permission profile / Output policy / Hard rules** — copied
  byte-faithfully from each source (these are role-defining prose; the
  read-only/RW distinction, the merge-back-emit-a-patch contract on
  `coder`, the script-write contract on `repo-ops`, and the per-agent
  scope/skill text all preserved).
- **`auditor.md` orchestration prose** — the only template with
  Gemini-CLI-specific orchestration text. Adapted faithfully: "Gemini CLI
  subagents cannot call other subagents" → "On the Antigravity CLI
  subagents are conversation-scoped … and a subagent does not delegate to
  a sibling"; `./agent-run.sh gemini --agent auditor` →
  `./agent-run.sh agy --agent auditor`; `@auditor-security` activation
  language → runtime define_subagent reference (cross-ref to
  `RUNTIME-SUBAGENT-PATTERN.md`). Added a `<!-- RE-VERIFY at impl:
  subagent invocation … -->` marker. The consolidation logic (rules
  44–55, skip rules, severity reconciliation, `## Next steps`) is
  preserved verbatim. "PM chat" terminology kept (project-side SSOT);
  no "Pack Chat" / pack-self concept introduced.
- **`project-template/skills/audit-methodology/SKILL.md` ref** (in
  `auditor-architecture.md` + `auditor-ops.md`) — kept BYTE-IDENTICAL to
  the sibling `.claude`/`.codex` agent files (established cross-CLI
  convention; verified those carry the same `project-template/skills/…`
  path). Path normalization is a separate concern (not C1); preserving
  parity with the established roster was the faithful call.

---

## 4. FORWARD-LOOKING markers placed (per §5 register)

| Marker (verbatim text seed) | Where placed | §5 register item |
|---|---|---|
| `RE-VERIFY at impl: plugin.json field schema, gemini-cli #27305, antigravity.google/docs/cli-plugins` | `plugin.json` (`comment-RE-VERIFY` key) | plugin.json field schema |
| `RE-VERIFY at impl: plugin agents/ inner template schema + frontmatter field set, gemini-cli #27305, antigravity.google/docs/cli-plugins` | top HTML comment of ALL 16 `agents/*.md` templates | plugin agents/ inner template schema |
| `RE-VERIFY at impl: model IDs — reference the Antigravity default model …` | frontmatter of ALL 16 templates | model IDs |
| `RE-VERIFY at impl: runtime define_subagent invocation shape + plugin agents/ inner template schema …` | top HTML comment of `RUNTIME-SUBAGENT-PATTERN.md` | runtime subagent hedge (A3) |
| `RE-VERIFY at impl: exact define_subagent / invoke_subagent verb names …` + `RE-VERIFY at impl: headless subagent activation + --print semantics` | body of `RUNTIME-SUBAGENT-PATTERN.md` | agent invocation |
| `RE-VERIFY at impl: subagent invocation + whether a subagent may invoke another, antigravity.google/docs/subagents` | `agents/auditor.md` Orchestration section | agent invocation |
| `# RE-VERIFY at impl: agent invocation, antigravity.google/docs/subagents` (×3) | `agent-run.sh` header note + `run_agy_auditor` docstring + per-subagent prompt comment + the interactive-launch block | agent invocation |
| `# RE-VERIFY at impl: agy --sandbox semantics + read-only flag profile …` / `# RE-VERIFY at impl: agy --dangerously-skip-permissions flag spelling + --model selection …` | `agent-run.sh` `AGY_READONLY_FLAGS` / `AGY_WRITE_FLAGS` comments | plugin install / flags |

A3 hedge shipped: `RUNTIME-SUBAGENT-PATTERN.md` provides the
runtime-`define_subagent` fallback while the plugin `agents/` schema is
undocumented (gemini-cli #27305 open).

---

## 5. agent-run.sh conversion detail (Gemini leg → agy leg)

Targeted in-place edits (NOT a full rewrite); Claude + Codex legs
untouched. Per-element conversion:

| Gemini element (removed/converted) | agy replacement |
|---|---|
| header shebang comment "Claude Code, Codex, or Gemini" | "Claude Code, Codex, or Antigravity" |
| usage example `gemini --agent auditor` | `agy --agent auditor` |
| "Gemini CLI: no --agent flag … `@agent-name` syntax" notes block | "Antigravity CLI (agy): … plugin bundle … `agy plugin install` … headless `agy -p`" notes block + RE-VERIFY marker |
| `KNOWN_CLIS=(claude codex gemini)` | `KNOWN_CLIS=(claude codex agy)` |
| `GEMINI_READONLY_FLAGS=()` | `AGY_READONLY_FLAGS=("--sandbox")` |
| `GEMINI_WRITE_FLAGS=("--approval-mode=yolo")` | `AGY_WRITE_FLAGS=("--sandbox" "--dangerously-skip-permissions")` |
| `print_usage` per-CLI flag descriptions (gemini rows) | agy rows (`--sandbox` / `--sandbox --dangerously-skip-permissions`) |
| `print_usage` auditor-orchestration `gemini:` paragraph (`@agent-name`) | `agy:` paragraph (headless `agy -p`, role text) |
| `run_gemini_auditor()` fn name + docstring + `mktemp -t gemini-auditor-` | `run_agy_auditor()` + Antigravity docstring + `agy-auditor-` |
| per-subagent prompt `@${sub}` activation + `.gemini/agents/<sub>.md` ref | role-file-named activation + `.agents-plugin/optiquity-agents/agents/<sub>.md` ref (no `@`) |
| parent consolidation `@auditor` activation | role-file-named activation (`…/agents/auditor.md`) |
| `gemini "${GEMINI_READONLY_FLAGS[@]}" -p` (subagent run) | `agy "${AGY_READONLY_FLAGS[@]}" -p` |
| `gemini "${GEMINI_READONLY_FLAGS[@]}" … < parent_prompt` (consolidation) | `agy "${AGY_READONLY_FLAGS[@]}" … < parent_prompt` |
| `--skip is only valid for 'gemini --agent auditor'` guard | `… 'agy --agent auditor'` |
| special-case dispatch `if CLI == gemini && AGENT == auditor` → `run_gemini_auditor` | `CLI == agy` → `run_agy_auditor` |
| EXTRA `case` `gemini) … GEMINI_*_FLAGS` (RO + write) | `agy) … AGY_*_FLAGS` (RO + write) |
| launch block `if CLI == gemini` → `exec gemini … -i "@${AGENT} … .gemini/agents/${AGENT}.md"` | `if CLI == agy` → `exec agy … "$activation_msg"` (role file `…/agents/${AGENT}.md`, no `@`, no `-i`) |

**Verb-parity preserved (Check 57 leg):** the 8 canonical destructive-git
verbs in `--disallowedTools` (in `CLAUDE_READONLY_FLAGS`) are UNTOUCHED —
verified each appears exactly once: `checkout`, `clean`, `merge`,
`rebase`, `reset`, `restore`, `stash`, `worktree` (all `1`).

**Residual `gemini`/`@agent` tokens** (2, both intentional explanatory
prose, not invocations): line ~150 "the Antigravity analog of an
auto-approve/yolo mode"; line ~367 "Antigravity has no @agent-name; the
script names the role file." No `gemini` binary call, no `.gemini/agents/`
activation, no `--approval-mode`.

**Smoke tests:** `bash -n` = SYNTAX OK; `--help` renders with `agy` in the
CLI list; `agy --agent coder` path reachable; `gemini --agent coder` now
correctly rejected (`error: unknown CLI 'gemini'. Supported: claude codex
agy`).

---

## 6. MODIFIED-PREFLIGHT verification (expected-break-only confirmation)

### 6.1 validate-pack (general mode)

```
$ python3 scripts/validate-pack.py ; echo EXIT $?
…
FAILED — 35 issue(s) found
EXIT 1
```

EXIT 1 is RED-BY-DESIGN (C1 is an intermediate-red commit). The failing
checks (the banners that contain ≥1 FAIL):

```
── Check 5:  Agent file count consistency ──
── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity (Guard-C project) ──
```

**Failing set = {Check 5, Check 55, Check 57}.** This is a SUBSET of the
expected set **{Check 5, Check 27, dir-dependent checks}**:
- **Check 5** — `check_agent_count`: `gemini_count == 0` → fail. NAMED in
  the prompt. EXPECTED.
- **Check 55** — `check_project_rw_ro_two_class`: Leg 3 reads
  `project-template/.gemini/agents/<agent>.md` for all 16 agents
  (`_CHECK_55_AGENT_DIRS`) → 16 "not found" fails. Dir-dependent; the
  prompt named this check explicitly as the example. EXPECTED.
- **Check 57** — `check_destructive_git_verb_parity` (project): reads the
  same 16 `.gemini/agents/` files (`_CHECK_57_AGENT_DIRS`) → 16 "not
  found" fails. Dir-dependent (within "dir-dependent checks"). EXPECTED.

**Check 27 did NOT fail (benign subset deviation).** The prompt predicted
Check 27 (`check_agent_canonical_phrases`) would `fail("directory
missing")`. It stayed GREEN because `rm project-template/.gemini/agents/*.md`
removed the FILES but left the empty `.gemini/agents/` DIRECTORY on disk,
so `agent_dir.is_dir()` is still True and the per-file glob loop simply
iterates zero files (no fail). Fewer breaks than predicted ⇒ still a
SUBSET of the expected set ⇒ still expected-break-only. (When C2 deletes
the rest of the `.gemini/` tree, this directory disappears; Check 27 is
re-expressed at C8 regardless, per the plan.)

**Every one of the 35 FAIL lines traces to the deleted
`project-template/.gemini/agents/` contents** (verified: a grep of all
FAIL lines excluding `.gemini/agents` / "Gemini agent files" / "Agent
count mismatch" / "Agents in Claude but not Gemini" returns ZERO lines).
NO UNEXPECTED check broke.

### 6.2 No regression from the NEW surfaces (controls)

- The new `.agents-plugin/` bundle does NOT appear in any FAIL line
  (Check 41/Check 47/recursive-walk admit it cleanly; OQ-3).
- `agent-run.sh` does NOT appear as a FAILING surface — Check 57's
  per-file "not found" messages mention `agent-run.sh` only inside the
  descriptive enumeration text "(…48 agent files, agent-run.sh)"; there is
  NO Check 57 verb-DRIFT failure (a `grep "Check 57" | grep -v "not
  found"` returns NONE), and Check 57's own synthetic-tree T1-T7 logic
  tests PASS. The agent-run.sh launcher's verb enumeration + READONLY_AGENTS
  array are intact.

### 6.3 Install-map axis still GREEN at C1 (breaks only at C2)

```
OK: Check 39 — 6 …*.md file(s) forward-checked … 34 cmd_update entries reverse-checked; 34 resolve to existing files at HEAD …
OK: Check 41 — 36 _CLIENT_INSTALLED_FILES entr(y/ies) checked; 36 resolve to existing files at HEAD … 0 drift(s) …
```

Correct: C1 deletes the agents dir (no explicit install-map rows; agent
bulk-copy is admitted via the recursive walk), NOT the `.gemini/` config
source files. The install-map axis (Check 41 + Check 39) breaks at C2 and
restores at C9 — not C1's concern.

### 6.4 C1-relevant per-check tests

| Test | EXIT | Verdict | Why |
|---|---|---|---|
| `scripts/tests/test-validate-pack-check-55.sh` | 1 | EXPECTED RED | Synthetic-tree T1-T8 PASS (logic intact); only the "validate-pack exits non-zero on HEAD" assertion fails — the 16 `.gemini/agents/` files are gone. Repinned in C8/C9 per plan. |
| `scripts/tests/test-validate-pack-check-57.sh` | 1 | EXPECTED RED | Synthetic-tree T1-T7 PASS (logic intact); same HEAD-exit assertion fails on the deleted files. Repinned in C8/C9 per plan. |
| `scripts/tests/test-validate-pack-check-56.sh` (control — pack destructive verb) | 0 | PASS | C1 did not touch pack-self surfaces. |
| `scripts/tests/test-validate-pack-check-43.sh` (control) | 0 | PASS | Unaffected by C1. |

The check-55/57 test reds are EXPECTED (they pin the green steady state of
checks C1 deliberately puts in the red window; their internal logic tests
all PASS — no logic break, no verb-drift). The two controls PASS,
confirming C1's edits did not leak.

### 6.5 Bash compatibility (CLEAN-ROOM note)

`agent-run.sh` ran under macOS bash (`bash -n` + smoke). No bash-4+
construct was introduced by C1's edits (the new `AGY_*_FLAGS` arrays and
the converted branches use the same array/`[[ ]]`/`case` idioms already in
the file). The Gemini→agy conversion is a string/array substitution, not a
new shell construct.

---

## 7. Boundary discipline check (non-negotiable for project-side edits)

All C1 edits touch `project-template/` (a client-shipped surface). Per the
P-missed-7 / `bd-pack-only-operational-rule` pre-flight:

- **Concept changed:** the client agent roster + the agent launcher.
- **Project-side SSOTs investigated:**
  - `project-template/docs/pack/PM-CHAT.md` (agent roster / PM operating
    rules) — the auditor template's orchestration prose was kept aligned
    with the project's "PM chat" role and the existing roster; no pack-side
    orchestrator role was imported.
  - `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (project
    trinity) — the per-agent permission-profile prose + the trinity rule
    references in the templates use the project trinity vocabulary; not
    edited in C1 (that is C3).
  - The deleted `.gemini/agents/*.md` files + the sibling `.claude`/`.codex`
    agent files — used as the faithful adaptation source for each new
    template (role text, permission headers, the
    `project-template/skills/audit-methodology/SKILL.md` cross-ref
    convention).
- **No reference to a pack-only file was added.** The client bundle and
  the converted `agent-run.sh` carry NO BD-NNN, `maintenance-docs/`,
  `pack-ops/`, `pack-*` agent name, or capitalized "Pack Chat" role
  (verified by grep — see Rules-Applied row for `bd-pack-only-operational-rule`).
- **No SSOT augmentation needed:** the conversion is a faithful 1:1
  port of existing client content to the Antigravity shape per Pack Chat's
  prompt; no new client rule was authored.

**Boundary discipline stop:** NONE. No proposed edit pointed at a pack-only
target.

---

## 8. Files-changed inventory (for Pack Chat to stage)

**Deleted (16) — `git status` shows ` D`:**
```
project-template/.gemini/agents/architect.md
project-template/.gemini/agents/auditor-architecture.md
project-template/.gemini/agents/auditor-code.md
project-template/.gemini/agents/auditor-docs.md
project-template/.gemini/agents/auditor-ops.md
project-template/.gemini/agents/auditor-security.md
project-template/.gemini/agents/auditor-tests.md
project-template/.gemini/agents/auditor-ui.md
project-template/.gemini/agents/auditor.md
project-template/.gemini/agents/coder.md
project-template/.gemini/agents/docs-researcher.md
project-template/.gemini/agents/grpc-schema.md
project-template/.gemini/agents/planner.md
project-template/.gemini/agents/repo-ops.md
project-template/.gemini/agents/reviewer.md
project-template/.gemini/agents/tester.md
```

**Modified (1) — `git status` shows ` M`:**
```
project-template/agent-run.sh
```

**New (18, untracked under `?? project-template/.agents-plugin/`):**
```
project-template/.agents-plugin/optiquity-agents/plugin.json
project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md
project-template/.agents-plugin/optiquity-agents/agents/architect.md
project-template/.agents-plugin/optiquity-agents/agents/coder.md
project-template/.agents-plugin/optiquity-agents/agents/reviewer.md
project-template/.agents-plugin/optiquity-agents/agents/planner.md
project-template/.agents-plugin/optiquity-agents/agents/tester.md
project-template/.agents-plugin/optiquity-agents/agents/docs-researcher.md
project-template/.agents-plugin/optiquity-agents/agents/grpc-schema.md
project-template/.agents-plugin/optiquity-agents/agents/repo-ops.md
project-template/.agents-plugin/optiquity-agents/agents/auditor.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-architecture.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-code.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-docs.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-ops.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-security.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-tests.md
project-template/.agents-plugin/optiquity-agents/agents/auditor-ui.md
```

**Scope guard:** `git status --short | grep -v "project-template/"`
returns EMPTY → every change is under `project-template/` (project-only
keyword honored). `scripts/validate-pack.py`, `scripts/init-project.sh`,
`test-fixtures/manifest.txt`, pack-self surfaces, and BD-185 files were
NOT touched.

> **Note for Pack Chat (manifest):** do NOT regenerate
> `test-fixtures/manifest.txt` for the C1 commit — manifest regen is
> C10-only (plan F3; `build.sh` is not Antigravity-aware until C10). C1 is
> a v11-surface commit but the manifest model is explicitly carved to
> C10. (If the `regenerate-manifest-v11-surface` gate is asserted at
> commit time, this is the documented C10-only exception per the plan.)

---

## 9. Plan deviations

| # | Deviation | Disposition |
|---|---|---|
| 1 | Prompt predicted **Check 27** would fail ("directory missing"); it stayed GREEN. | BENIGN. Cause: `rm *.md` left the empty `.gemini/agents/` directory on disk, so `is_dir()` is True. Failing set is a strict SUBSET of the expected set — still expected-break-only. Check 27 is re-expressed at C8 regardless. No action needed. |
| 2 | `auditor-architecture.md` / `auditor-ops.md` retain the `project-template/skills/audit-methodology/SKILL.md` cross-ref path verbatim (initially I normalized it, then reverted). | INTENTIONAL faithfulness call. The sibling `.claude`/`.codex` agent files carry the identical path (established cross-CLI convention); preserving roster parity is correct for C1. Path normalization (if desired) is a separate, out-of-scope concern. |

No other deviations. No out-of-scope file modifications. No deferrals.

---

## 10. New POQs introduced

None. (The plugin.json inner field schema + the per-template inner schema
+ the agy invocation + global paths are pre-existing FORWARD-LOOKING items
from plan §5, carried as inline `RE-VERIFY` markers — not new POQs.)

---

## 11. Definition-of-Done checklist

| Item | PASS/FAIL | Evidence |
|---|---|---|
| 16 `.gemini/agents/*.md` deleted | PASS | `git status` shows 16 ` D` rows; `ls .../agents/*.md` → none |
| Bundle created at OQ-3 path with `plugin.json` + 16 `agents/` + `RUNTIME-SUBAGENT-PATTERN.md` | PASS | `find` shows 18 files; agent count = 16; `plugin.json` valid JSON |
| 16 roster names preserved EXACTLY | PASS | §3 old→new table; new `agents/` stems == deleted stems |
| `plugin.json` field schema marked FORWARD-LOOKING | PASS | `comment-RE-VERIFY` key present |
| per-template inner schema marked FORWARD-LOOKING | PASS | top HTML comment in all 16 templates |
| `RUNTIME-SUBAGENT-PATTERN.md` A3 hedge shipped + FORWARD-LOOKING | PASS | file present + top RE-VERIFY comment |
| `agent-run.sh` Gemini leg → `agy` leg (in-place, Claude+Codex intact) | PASS | §5 table; `bash -n` OK; `KNOWN_CLIS=(claude codex agy)`; claude/codex blocks unchanged |
| agent invocation marked FORWARD-LOOKING in agent-run.sh | PASS | `# RE-VERIFY at impl: agent invocation` markers present |
| `agy --version` recorded | PASS | 1.0.8 (§0/§1) |
| validate-pack expected-break-only (subset of {5, 27, dir-dependent}) | PASS | §6.1 — failing set {5, 55, 57} ⊆ expected; no unexpected break |
| No pack-self leak in client bundle (`bd-pack-only-operational-rule`) | PASS | grep returns CLEAN (§12 Rules block) |
| project-only scope honored (no out-of-scope edit) | PASS | §8 scope guard EMPTY |
| manifest NOT regenerated (C10-only) | PASS | `test-fixtures/manifest.txt` untouched |
| no validator / init-project / pack-self / BD-185 edits | PASS | `git status` shows only project-template/ paths |
| agents-never-commit | PASS | no git state-changing verb run (only `rev-parse`/`status`/`diff` read-only); deletions via `rm` |

---

## 12. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Git verbs run this session were read-only ONLY: `git rev-parse HEAD` (→ `c9ef6c5056fbca1eb3acaad7917ce09c22e7cc73`), `git status --short`. The 16 deletions were done with filesystem `rm project-template/.gemini/agents/*.md` (a working-tree edit, NOT a git verb). NO `git add`/`commit`/`push`/`mv`/`rm`/`checkout`/`restore`/`stash`/`apply`/`reset`/`worktree`. Edits left in the working tree for Pack Chat to stage/commit with user approval. | COMPLIANT |
| 2 | preflight-stop-means-stop | Single PREFLIGHT line emitted (§0) only AFTER all edits + the MODIFIED verification passed (expected-break-only confirmed: failing set {5,55,57} ⊆ {5,27,dir-dependent}; NO unexpected break — §6.1). No partial IMPL-REPORT was written before verification completed. No parent stop/halt/revert message received. | COMPLIANT |
| 3 | bd-pack-only-operational-rule | `grep -rnE "BD-[0-9]\|maintenance-docs\|pack-ops\|Pack Chat\|pack-architect\|pack-coder\|pack-reviewer\|pack-planner\|pack-docs-researcher\|PACK-AGENTS\|PACK-CHAT" project-template/.agents-plugin/` → "CLEAN: no pack-self concept found in client bundle". The converted `agent-run.sh` carries none of these tokens either (it references `docs/pack/PM-CHAT.md`/`docs/pack/OPTIONAL-FEATURES.md` — client-side paths — and the project "PM chat" role, all project-side). | COMPLIANT |
| 4 | edit-in-place-not-full-rewrite | `agent-run.sh` converted via targeted in-place Edit calls to its Gemini leg (§5 table); the file was NOT rewritten — Claude + Codex legs, worktree helper, arg-parsing, and structure are byte-unchanged except the converted elements. The 18 plugin files are NEW (full Write is correct for new files). | COMPLIANT |
| 5 | scope-deliverables-to-the-ask | Implemented EXACTLY plan §3 C1 + §1.2 OQ-3 paths + §5 register markers — the 3 C1 actions (delete 16, create bundle, convert agent-run.sh) and nothing more. No validator/init-project/pack-self/fixture/manifest/BD-185 edit (§8 scope guard EMPTY of non-`project-template/` paths). Surfaced (did not fix) the Check 27 benign deviation (§6.1/§9). | COMPLIANT |
| 6 | verify-full-ci-suite | Ran `python3 scripts/validate-pack.py` (general; EXIT 1, RED-by-design, failing set quoted §6.1) + the C1-coupled per-check tests `test-validate-pack-check-55.sh` (EXIT 1, expected), `-57.sh` (EXIT 1, expected), and controls `-56.sh` (EXIT 0), `-43.sh` (EXIT 0) — each EXIT quoted §6.4. Full green is NOT expected at C1 (modified contract); the expected-break-only condition is the gate and is met. | COMPLIANT |
| 7 | rules-applied-verification-block | This table; every prompt rule has quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---
*End of IMPL-REPORT-BD-221-C1.md — IN-PLACE regime, live HEAD `c9ef6c5`,
2026-06-15. C1 is an intermediate-red cluster commit; validate-pack red on
{Check 5, Check 55, Check 57} ⊆ {Check 5, Check 27, dir-dependent checks}
is EXPECTED-BY-DESIGN (content axis restores at C8). Pack Chat applies the
review/fix cycle + stages/commits with user approval; agents never commit.*
