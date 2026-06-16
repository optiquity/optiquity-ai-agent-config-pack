# PACK-REVIEW — BD-221 C1 (project agent-model fork → Antigravity plugin)

**Reviewer:** fresh pack-reviewer (IN-PLACE, read-only on the codebase; the
only write is this report). **Date:** 2026-06-15.
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
(branch `v11-dev`). **Live HEAD this review:** `e73ab3f` (`git rev-parse
HEAD` → `e73ab3f0bce201d2d9f39074b4cd52d54b0be3a5`). C1 is implemented
IN-PLACE in the working tree, UNCOMMITTED (parked for review).

> Note on HEAD: the C1 IMPL-REPORT records its run-time HEAD as `c9ef6c5`;
> the live HEAD is now `e73ab3f` because `backlog/BD-185.md` (deferred) was
> committed after the coder run. That commit is UNRELATED to C1 and is
> ignored per the prompt; the C1 working-tree delta is unchanged.

---

## 1. VERDICT

**CLEAN.** C1 does exactly what plan §3 C1 specifies — deletes the 16 client
agent files, creates the `optiquity-agents` Antigravity plugin bundle (18
files; 16 names preserved exactly; FORWARD-LOOKING markers in place; no
hard-coded schema/model guesses), and converts `agent-run.sh`'s Gemini leg
to an `agy` leg (targeted in-place edits; Claude + Codex legs and the
8-verb destructive-git `--disallowedTools` set intact). The validate-pack
red is EXPECTED-BY-DESIGN and is a strict SUBSET of the expected set: all 35
FAIL lines trace to the deleted `project-template/.gemini/agents/` dir
({Check 5, Check 55, Check 57}); NO unexpected check broke (Check 41/39/27/
17/20/11 all green). The client bundle carries zero pack-self concept. Scope
is exclusively `project-template/` (plus the allowed IMPL-REPORT). No
BLOCKER / MUST / SHOULD findings. Two NITs below are informational only and
require no action at C1.

---

## 2. FINDINGS

| # | Severity | File | Evidence | Recommended action |
|---|----------|------|----------|--------------------|
| — | (none) | — | No BLOCKER, MUST, or SHOULD finding. C1 is clean against plan §3 C1, the §5 forward-looking register, and the frozen decisions. | — |
| N1 | NIT | `project-template/.agents-plugin/optiquity-agents/agents/auditor-ops.md` (L35), `auditor-architecture.md` (L41) | These two templates retain the cross-ref `project-template/skills/audit-methodology/SKILL.md` verbatim. Verified BYTE-IDENTICAL to the sibling `.claude` agent at HEAD (`git show HEAD:project-template/.claude/agents/auditor-architecture.md` → L37 carries the same path). This is the established cross-CLI convention; the IMPL-REPORT discloses it as intentional faithfulness (deviation #2). | NONE for C1. Path-normalization (if ever desired) is a separate cross-roster concern, out of C1 scope — do not "fix" it here (it would break parity with the unconverted `.claude`/`.codex` roster). |
| N2 | NIT | `scripts/validate-pack.py` Check 27 (`check_agent_canonical_phrases`) | The C1 prompt + IMPL-REPORT PREFLIGHT predicted Check 27 would `fail("directory missing")`. It stayed GREEN: `rm *.md` removed the files but left the empty `project-template/.gemini/agents/` directory on disk (`ls -la` → `total 0`), so `agent_dir.is_dir()` is True and the per-file glob iterates zero files. Fewer breaks than predicted ⇒ still a strict SUBSET of the expected set ⇒ still expected-break-only. | NONE. Benign-subset deviation; the IMPL-REPORT discloses it accurately (deviation #1). The empty dir disappears at C2 (deletes the rest of `.gemini/`); Check 27 is re-expressed at C8 regardless. |

---

## 3. EXPECTED-RED CONFIRMATION

`python3 scripts/validate-pack.py` → **EXIT 1; `FAILED — 35 issue(s)
found`.** RED-by-design (C1 is an intermediate-red cluster commit).

**Failing-check set (quoted banners):**
```
── Check 5:  Agent file count consistency ──
── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity (Guard-C project) ──
```

**FAIL-line accounting (all 35 traced):**
| Source | FAIL lines |
|---|---|
| Check 5 (`No Gemini agent files` + `Agent count mismatch — Claude:16, Codex:16, Gemini:0` + `Agents in Claude but not Gemini: [...]`) | 3 |
| Check 55 (`agent file project-template/.gemini/agents/<name>.md not found`, ×16) | 16 |
| Check 57 (`verb-parity surface project-template/.gemini/agents/<name>.md not found`, ×16) | 16 |
| **Total** | **35** |

A `grep '^FAIL:'` excluding the lines that mention `.gemini/agents` /
`No Gemini agent files` / `Agent count mismatch` / `Agents in Claude but not
Gemini` returns ZERO lines: **every one of the 35 FAIL lines traces to the
deleted `project-template/.gemini/agents/` contents.**

**Subset check vs the expected set {Check 5, Check 27, dir-dependent checks
(55, 57)}:**
- **Check 5** — `check_agent_count`: `gemini_count == 0`. NAMED in the
  prompt. EXPECTED.
- **Check 55** — `check_project_rw_ro_two_class` reads the 16
  `.gemini/agents/` files. Dir-dependent; NAMED in the prompt as the
  example. EXPECTED.
- **Check 57** — `check_destructive_git_verb_parity` (project) reads the
  same 16 files. Dir-dependent (within "checks that read the deleted dir").
  EXPECTED.
- **Check 27** — predicted to fail; stayed GREEN (empty-dir survives the
  `rm`). Fewer breaks ⇒ still a strict subset. EXPECTED-OR-BENIGNER.

**No unexpected break (positive controls — quoted OK banners):**
```
OK: Check 39 — ... 34 `cmd_update` entries reverse-checked; 34 resolve to existing files at HEAD ...
OK: Check 41 — 36 `_CLIENT_INSTALLED_FILES` entr(y/ies) checked; 36 resolve to existing files at HEAD ... 0 drift(s) ...
```
Check 41 (install-map), Check 39 (cmd_update), Check 27, Check 17, Check 20,
and Check 11 all carry NO FAIL line. This is correct: the install-map axis
(Check 41/39) breaks only when C2 deletes the row-referenced `.gemini/`
SOURCE files (settings.json / .env.example / the 2 .toml) — those files are
still present in the tree at C1 (`find project-template/.gemini -type f`
confirms all 4 remain), so the install-map rows still resolve. The new
`.agents-plugin/` bundle is admitted cleanly by Check 41's recursive walk
(no FAIL line, no new explicit rows needed) — consistent with OQ-3.

**Conclusion: the validate-pack red is EXPECTED-ONLY. The failing set
{Check 5, Check 55, Check 57} is a strict subset of {Check 5, Check 27,
dir-dependent checks}. No unexpected check (no install-map Check 41/39, no
fixture check, nothing outside the deleted-dir blast radius) broke.**

---

## 4. INDEPENDENT VERIFICATION EVIDENCE

### 4.1 The 16 agent deletions + 16 created names (1:1, exact)
- `git status --short` shows exactly 16 ` D project-template/.gemini/agents/*.md`
  rows; `ls project-template/.gemini/agents/*.md` → no matches (all gone).
- `git ls-tree HEAD project-template/.gemini/agents/` → 16 originals.
- The bundle `agents/` stems and the deleted-original stems are an EXACT
  set match (sorted, both lists identical):
  `architect, auditor, auditor-architecture, auditor-code, auditor-docs,
  auditor-ops, auditor-security, auditor-tests, auditor-ui, coder,
  docs-researcher, grpc-schema, planner, repo-ops, reviewer, tester`.

### 4.2 Bundle shape (18 files at the OQ-3 path)
`find project-template/.agents-plugin -type f` →
`project-template/.agents-plugin/optiquity-agents/` containing:
- `plugin.json` — **valid JSON** (`python3 -c json.load` OK; keys
  `name, version, description, comment-RE-VERIFY, agents`). `name` =
  `optiquity-agents`; `agents` = `./agents`. The `comment-RE-VERIFY` key
  carries the FORWARD-LOOKING field-schema marker (gemini-cli #27305 +
  antigravity.google/docs/cli-plugins) — schema is NOT hard-coded beyond
  the confirmed-stable name/version/description layout.
- `agents/` — 16 templates (count verified 16).
- `RUNTIME-SUBAGENT-PATTERN.md` — the A3 hedge.

### 4.3 Template faithfulness (full diff, all 16 vs HEAD originals)
A line-level diff of every new template against its deleted HEAD original
shows:
- **15 of 16 templates:** the ONLY changes are (a) the model frontmatter
  line `model: gemini-2.5-pro` / `gemini-2.5-flash` → `model: default`, and
  (b) two prepended RE-VERIFY markers (inner-schema HTML comment at L1 +
  model-IDs marker at L5). The entire body — permission profile, output
  policy, hard rules, the `coder` merge-back-emit-a-patch contract, the
  `repo-ops` script-write contract, per-agent scope/skill text — is
  byte-identical. Spot-confirmed in full for `coder.md` (the RW/patch-emit
  contract is preserved verbatim).
- **`auditor.md` (the only template with CLI-specific orchestration prose):**
  faithfully converted — `Gemini CLI subagents cannot call other subagents`
  → `On the Antigravity CLI subagents are conversation-scoped ... a subagent
  does not delegate to a sibling subagent`; `@auditor` / `@auditor-security`
  activation → subagent-direct language; `./agent-run.sh gemini --agent
  auditor` → `./agent-run.sh agy --agent auditor`; `Gemini session` → `agy
  session`; a `<!-- RE-VERIFY at impl: subagent invocation ... -->` marker
  added. The consolidation logic (audit-methodology rules 44–55, skip rules,
  severity reconciliation, `## Next steps`) is preserved verbatim. "PM chat"
  terminology kept (project-side SSOT) — no "Pack Chat" / pack-self concept
  introduced.

### 4.4 FORWARD-LOOKING / RE-VERIFY markers (no hard-coded guesses)
- All 16 templates carry exactly 2 RE-VERIFY markers (auditor.md carries 3,
  the extra for subagent invocation). All 16 set `model: default` (not a
  pinned Gemini string).
- `RUNTIME-SUBAGENT-PATTERN.md` carries RE-VERIFY markers for the runtime
  `define_subagent`/`invoke_subagent` verb shapes and `--print` semantics,
  and frames the plugin bundle as PRIMARY with the runtime pattern as the
  hedge. References only client-side paths (`agents/`, `agent-run.sh`,
  `docs/pack/OPTIONAL-FEATURES.md`) — no pack-self leak.

### 4.5 `agent-run.sh` conversion (targeted in-place; legs + verbs intact)
- `bash -n project-template/agent-run.sh` → SYNTAX OK.
- `KNOWN_CLIS=(claude codex agy)` (gemini removed; claude/codex retained).
- `AGY_READONLY_FLAGS=("--sandbox")`,
  `AGY_WRITE_FLAGS=("--sandbox" "--dangerously-skip-permissions")` — matches
  plan §3 C1; `--model` referenced only in a RE-VERIFY marker (not
  hard-coded); all `GEMINI_*_FLAGS` removed.
- `run_gemini_auditor()` → `run_agy_auditor()`; headless leg uses
  `agy "${AGY_READONLY_FLAGS[@]}" -p ...` (`-p` / `--print`).
- The interactive launch dispatch is `if [[ "$CLI" == "agy" ]]` (was
  `gemini`); `exec agy ... "$activation_msg"` names the role file
  (`.agents-plugin/optiquity-agents/agents/${AGENT}.md`) — the `@agent-name`
  translation is genuinely replaced (no `@`, no `-i`). The `codex` `elif`
  branch follows intact.
- **Claude + Codex legs intact:** the `git diff` shows `claude)` / `codex)`
  dispatch lines and `CLAUDE_READONLY_FLAGS=` / `CODEX_READONLY_FLAGS=`
  array declarations appear only as CONTEXT lines (no `+`/`-` on their
  bodies). The conversion is a targeted Gemini→agy substitution, not a full
  rewrite (88 insertions / 64 deletions, all in the Gemini/agy region +
  shebang/usage prose).
- **Destructive-git-verb `--disallowedTools` set preserved:** each of the 8
  canonical verbs appears exactly once in `CLAUDE_READONLY_FLAGS`
  (`Bash(git checkout`, `clean`, `merge`, `rebase`, `reset`, `restore`,
  `stash`, `worktree` — each count = 1). The Check 57 leg is untouched.
- Only residual "gemini" token in the script is the intentional explanatory
  prose comment (L367: "Antigravity has no @agent-name; the script names the
  role file") — no `gemini` binary call, no `.gemini/agents/` activation, no
  `--approval-mode`.

### 4.6 No pack-self leak in the client bundle (bd-pack-only-operational-rule)
`grep -rnE 'BD-[0-9]|pack-ops|maintenance-docs|Pack Chat|pack-architect|
pack-coder|pack-reviewer|pack-planner|pack-docs-researcher|PACK-AGENTS|
PACK-CHAT|pack-self' project-template/.agents-plugin/` → **CLEAN (zero
hits).** A broad `grep -rnE 'pack-' project-template/.agents-plugin/` → no
`pack-` substring at all. The bundle carries NO pack-self concept.
(Residual `GEMINI.md` tokens in the templates' Trinity-rule bullet are the
project trinity FILE NAME — STABLE-now per §5 register "trinity survives";
the `gemini-cli #27305` / "Gemini model string" tokens are inside RE-VERIFY
markers — both legitimate, neither a leak.)

### 4.7 Scope (exclusively project-template/; no out-of-scope edits)
- `git status --short` filtered to exclude `project-template/` and the
  allowed `maintenance-docs/.../IMPL-REPORT-BD-221-C1.md` → EMPTY. Every
  change is under `project-template/` (plus the IMPL-REPORT).
- `test-fixtures/manifest.txt` NOT modified (correct — C10-only).
- `scripts/validate-pack.py` + `scripts/init-project.sh` NOT modified
  (correct — those are C8 / C9).
- `backlog/` clean in the working tree (BD-185 already committed; unrelated
  to C1).
- The C2-owned `.gemini/` config sources (`settings.json`, `.env.example`,
  `commands/pack-help.toml`, `commands/pm-startup.toml`) remain present —
  correctly untouched at C1.

---

## 5. RULES-APPLIED VERIFICATION BLOCK

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Git verbs this review were read-only ONLY: `git rev-parse HEAD` (→ `e73ab3f0bce201d2d9f39074b4cd52d54b0be3a5`), `git rev-parse --abbrev-ref HEAD` (→ `v11-dev`), `git status --short`, `git diff`/`git diff --stat`/`git diff --name-only`, `git show HEAD:<path>`, `git ls-tree`. NO add/commit/push/checkout/restore/stash/mv/rm/reset/merge/apply/worktree. No source edit. The single write is this report at the prompted path. | COMPLIANT |
| 2 | scope-deliverables-to-the-ask | Reviewed EXACTLY C1 (plan §3 C1): the 16 deletions, the bundle, agent-run.sh, the no-leak grep, the expected-red set, the scope guard. Led the report with the verdict (§1). Out-of-scope edits checked (`git status` filter → none). No padding; only 2 informational NITs (no invented findings). | COMPLIANT |
| 3 | bd-pack-only-operational-rule | `grep -rnE 'BD-[0-9]\|pack-ops\|maintenance-docs\|Pack Chat\|pack-architect\|pack-coder\|pack-reviewer\|pack-planner\|pack-docs-researcher\|PACK-AGENTS\|PACK-CHAT\|pack-self' project-template/.agents-plugin/` → ZERO hits; broad `grep -rnE 'pack-' ...` → none. The client bundle carries no pack-self concept (§4.6). | COMPLIANT |
| 4 | verify-full-ci-suite | Ran `python3 scripts/validate-pack.py` (EXIT 1; `FAILED — 35`). Did NOT declare "green" (impossible at C1). Verified the expected-break-only condition: all 35 FAIL: lines trace to the deleted dir; failing set {Check 5, 55, 57} ⊆ {Check 5, Check 27, dir-dependent}; positive controls Check 41/39/27/17/20/11 carry NO FAIL (OK banners quoted §3). No unexpected break. | COMPLIANT |
| 5 | edit-in-place-not-full-rewrite | `git diff project-template/agent-run.sh` → 88 ins / 64 del, confined to the Gemini→agy region (flag arrays, `run_*_auditor`, dispatch, launch block) + shebang/usage prose; `claude)` / `codex)` dispatch and `CLAUDE_READONLY_FLAGS=` / `CODEX_READONLY_FLAGS=` arrays appear only as unchanged CONTEXT lines (§4.5). The 18 bundle files are NEW (full Write correct for new files). Not a full rewrite. | COMPLIANT |
| 6 | agents-read-rule-docs-in-full | Read IN FULL by direct Read-tool (not derived): the C1 IMPL-REPORT (`maintenance-docs/v11-implementation/IMPL-REPORT-BD-221-C1.md`, 456 ln); the plan (`/tmp/handoff-bd221-planner/PLAN-BD-221-ANTIGRAVITY-CONVERSION-FINAL-v2.md`, 452 ln — incl. §3 C1, §5 forward-looking register, §4 cluster-push, §9 EB blocks); the frozen decisions (`/tmp/handoff-bd221-decisions/DECISIONS-BD-221-FROZEN.md`, 46 ln); CLAUDE.md `## Pack memory` (full content via system-reminder). No prior `PACK-REVIEW-*` report read. | COMPLIANT |
| 7 | rules-applied-verification-block | This table; every prompt rule has quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---
*End of PACK-REVIEW-BD-221-C1.md — IN-PLACE review, read-only on the
codebase, live HEAD `e73ab3f`, 2026-06-15. Verdict: CLEAN. C1 is an
intermediate-red cluster commit; validate-pack red on {Check 5, Check 55,
Check 57} ⊆ {Check 5, Check 27, dir-dependent checks} is EXPECTED-BY-DESIGN
(content axis restores at C8; install-map axis at C9). No BLOCKER/MUST/SHOULD
findings; 2 informational NITs requiring no C1 action. Pack Chat applies its
triage + stages/commits with user approval; agents never commit.*
