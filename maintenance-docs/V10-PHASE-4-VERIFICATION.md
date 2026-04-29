# V10-PHASE-4-VERIFICATION.md — C-V10-15 evidence harness

*Captures evidence from Phase-4 verification streams.*
*Authoritative spec: V10-PHASE-4-PLAN.md Part 4.*
*Per-section runbook: V10-PHASE-4-VERIFICATION-PLAN-v2.md (this file's sibling).*
*Pack tip at capture start: 5e91d3e0e3714ab12d6c04cd1f9bdbcc13bbdf24 (post-BD-049 SHA fill).*
*Capture started: 2026-04-29T15:43:03Z.*

## Pre-flight

```text
Pre-flight surface check (2026-04-29T15:43:03Z)
  claude     present at /Users/david/.local/bin/claude
  codex      present at /Users/david/.nvm/versions/node/v22.14.0/bin/codex
  gemini     present at /Users/david/.nvm/versions/node/v22.14.0/bin/gemini
  bash       present at /bin/bash
  python3    present at /opt/homebrew/opt/python/bin/python3
  git        present at /usr/bin/git
  claude:  2.1.123 (Claude Code)
  codex:   codex-cli 0.121.0
  gemini:  0.38.1
```

**Required surfaces (per V10-PHASE-4-VERIFICATION-PLAN-v2 §1.3):** all present (`claude`, `bash`, `git`, `python3`).

**Optional surfaces present (recorded; not exercised live per §0.6 scope decision):** `codex` 0.121.0, `gemini` 0.38.1. Per §1.3 these are recorded but the §4.2 docs-research pass (Part 4) replaces live runs against them. Silent scope-expansion to live runs is forbidden by §9.3.

**Gate-F-readiness checklist (§11) outcome:** all 15 rows pass (rows 1–12 + v2 rows 13–15). One non-substantive deviation noted: row 1 was written for the C-V10-14 commit subject (`test-detect.sh`); pack tip is `5e91d3e` (BD-049 work landed two commits past C-V10-14). Row 2 (descendant-of-`459161b` ancestor check) confirms substantive intent.

**OT live-repo baseline (per row 13 / §6.5.3):**

| Field | Value |
|---|---|
| Live OT path | `/Users/david/Developer/OptiquityTrader/` |
| HEAD SHA | `d9e288ba8b897f967c52e99a0391d9495d5f8073` |
| Branch | `main` |
| Working tree porcelain | empty (0 lines) |
| Captured at | 2026-04-29T15:43:03Z |

This SHA + porcelain shape is re-verified after every OT-touching step in §4.6 / §4.7 / §4.8 per §6.5.7 / §6.7.9.

## §4.1 Fixture evidence

#### Evidence — §4.1 — F1 apple-spm-single-scheme

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T15:54:00Z to 2026-04-29T16:11:00Z (M1 walk-through) |
| Surface | Claude Code CLI 2.1.123 |
| Fixture or input | F1 apple-spm-single-scheme at `/tmp/phase-4-fixtures/apple-spm-single-scheme/`; SPM Package `F1App` (single library product, single scheme), no `.xcodeproj/.xcworkspace`; pack-installed via `init-project.sh` (S1–S10 stages); kickoff paste at `/tmp/phase-4-fixtures/kickoff-paste-F1.txt` (75 lines, all real placeholders filled) |
| Command(s) run | `cd /tmp/phase-4-fixtures/apple-spm-single-scheme; pbcopy < /tmp/phase-4-fixtures/kickoff-paste-F1.txt; claude` — paste kickoff, then user replies (in order): `(no surface-declaration reply asked)`, `yes` (Form R), `skip` (Form E + bundled kickoff edits) |
| Outcome | **soft pass** |
| Notes / deviations | Three deviations from strict Procedure 7, all in the same direction (gate auto-inference instead of explicit reply): (1) surface-declaration gate skipped — assistant printed `Surface: Claude Code CLI, shell confirmed.` and proceeded to Form R without a `shell` reply; (2) Form I (G7-install) collapsed into Form R results table — no separate gate; assistant declared "skipped by idempotency (swift-format 602.0.0 in-range)"; (3) Form M (G7-machine) collapsed into Form R results table — no separate gate; assistant declared "not applicable (no $PACK companion template source)". All substantive values correct (single scheme `F1App`, `XCODE_DESTINATION="platform=macOS"` inferred from macOS-only project, JSON edit shape parse-mutate-serialize not regex, SWIFT_SOURCE_DIRS correctly skipped for SPM layout, PLATFORM-SKILLS.md skill mapping correct: `apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift`). Procedure 7 §7.7 boundary correctly observed (E5/E6 kickoff placeholder edits separated from E1–E3 Procedure 7 edits). |
| Failure-mode link | F-A (proposed): kickoff surface-declaration gate auto-inferable from CLI environment; spec requires explicit reply per `pm-chat.md` kickoff line 50 ("Reply with the single word `shell` or `manual` before continuing.") and METHODOLOGY § Procedure 7.0 ("PM chat enters Procedure 7 when the kickoff-variant continuation pointer fires on a `shell` declaration."). To file as new BD-NNN at C-V10-18 BACKLOG sweep. |
| Cleanup | Pending — fixture preserved for §4.4 / §4.8 cross-reference until §10.1 single-command rollback. Final cleanup: `rm -rf /tmp/phase-4-fixtures/apple-spm-single-scheme /tmp/phase-4-fixtures/kickoff-paste-F1.txt /tmp/phase-4-fixtures/evidence-F1-*.txt`. |

**Discovery results (Form R, post-`yes`):**

```text
┌────────────────────────────────────────────┬────────────────────────────────────────────────────────┐
│                   Check                    │                         Result                         │
├────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ xcodebuild -list                           │ ✓ single scheme F1App — auto-fill                      │
├────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Simulators                                 │ many available, but macOS-only project → use           │
│                                            │ platform=macOS                                         │
├────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ swift-format                               │ 602.0.0 at /opt/homebrew/bin/swift-format (within      │
│                                            │ pack-tested ≥510.0.0)                                  │
├────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ brew                                       │ Homebrew 5.1.7                                         │
├────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ ~/Library/Developer/Xcode/CodingAssistant/ │ exists with ClaudeAgentConfig/ + codex/ already        │
│                                            │ populated                                              │
└────────────────────────────────────────────┴────────────────────────────────────────────────────────┘
```

**Form E — Procedure 7 edits proposed (E1–E3):**

```diff
-XCODE_SCHEME=""           # ← fill in after first Xcode target is created
-XCODE_DESTINATION=""      # ← e.g. "platform=iOS Simulator,name=iPhone 16,OS=latest"
+XCODE_SCHEME="F1App"
+XCODE_DESTINATION="platform=macOS"
```
*(Identical anchor pair in `scripts/validate-swift.sh` (E1) and `scripts/test-swift.sh` (E2).)*

```json
   "env": {
     "AGENT_CAPABILITIES": "planning,architecture,implementation,refactoring,debugging,testing,review,dependency-review,repo-ops,documentation",
-    "XCODE_SCHEME": "",
-    "XCODE_DESTINATION": ""
+    "XCODE_SCHEME": "F1App",
+    "XCODE_DESTINATION": "platform=macOS"
   }
```
*(E3 — `.claude/settings.json` env block. Shape is JSON parse-mutate-serialize, NOT regex on JSON. Procedure 7 §7.2.2 compliance ✓.)*

**E4 — `scripts/format-swift.sh` SWIFT_SOURCE_DIRS:** correctly skipped (standard SPM layout).

**Form E — kickoff placeholder edits proposed separately (E5–E6, per Procedure 7.7 boundary):**

E5 — `docs/pack/PM-CHAT.md`: replace `[PROJECT_NAME]` occurrences (lines 27, 31) with `F1 Smoke Test`; strip template comment block (lines 3–19) and italic banner (lines 21–25).

E6 — Trinity `Active skills:` line in `CLAUDE.md:258`, `AGENTS.md:181`, `GEMINI.md:212`: replace placeholder paragraph with:
```text
**Active skills:** apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift
```
*(Mapping derived from PLATFORM-SKILLS.md lines 127–128: macOS Swift app, no Python.)*

**Final kickoff status (post-`skip` reply):**

```text
┌──────────────────────┬─────────────────────────────────────────────────────────────────────────────┐
│         Gate         │                                   Outcome                                   │
├──────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ G7-discovery (Form R)│ ran — values recorded above                                                 │
├──────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ G7-install (Form I)  │ skipped by idempotency (swift-format 602.0.0 in-range)                      │
├──────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ G7-edit (Form E,     │ skipped by user — scripts/validate-swift.sh, scripts/test-swift.sh,         │
│ E1–E4)               │ .claude/settings.json env block left with empty                             │
│                      │ XCODE_SCHEME/XCODE_DESTINATION                                              │
├──────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ G7-machine (Form M)  │ not applicable (no $PACK companion template source)                         │
├──────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ Kickoff placeholder  │ skipped by user — PM-CHAT.md, CLAUDE.md/AGENTS.md/GEMINI.md Active skills   │
│ fills (E5, E6)       │ line still placeholder                                                      │
└──────────────────────┴─────────────────────────────────────────────────────────────────────────────┘
```

**Post-M1 fixture state verification:**

```text
$ cd /tmp/phase-4-fixtures/apple-spm-single-scheme
$ git status --porcelain
(empty — no writes)
$ git log --oneline
1fd05ee F1 baseline
```

Confirmed: no edits applied, fixture remains at `1fd05ee F1 baseline` (the construction commit). The `skip` replies were honored — no machine-level effects, no brew install, no file writes.

## §4.2 Cross-surface checks

*Per §0.6 scope decision and `V10-PHASE-4-VERIFICATION-PLAN-v2.md` Part 4: live runs against Codex CLI, Gemini CLI, and Desktop Commander are deferred to v10.1; this section is a docs-research deviation analysis derived from `TOOL-COMPARISON.md`, `pm-chat.md`, `METHODOLOGY.md` Procedure 7, and `V10-DESIGN.md`. Both `codex` 0.121.0 and `gemini` 0.38.1 happen to be present on the implementer's PATH (recorded in Pre-flight); per §1.3 / §9.3 silent-scope-expansion rule, neither was exercised live.*

#### Evidence — §4.2 — DR1 Codex CLI

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T16:35:00Z (docs-research pass) |
| Surface | Codex CLI (live presence: `codex` 0.121.0 at `/Users/david/.nvm/versions/node/v22.14.0/bin/codex` — recorded but not exercised per §0.6) |
| Reference docs cited | `project-template/docs/pack/prompts/pm-chat.md` lines 26, 46–47, 50; `maintenance-docs/TOOL-COMPARISON.md` Part 1 (line 41 capability table), Part 2 (line 68 invocation), Part 4 (lines 117–121 approval model); `supporting-docs/METHODOLOGY.md` Procedure 7 §7.0–§7.7 |
| Outcome | **deferred** (F-B (b) per V10-PHASE-4-PLAN.md Part 8) |
| Notes / deviations | See per-dimension table below. Risk summary: medium. One v10.1 candidate identified. |
| Failure-mode link | F-B (b) — surface deferred to v10.1 docs-research pass per §0.6 scope decision. |

| Dimension | Per-docs expected behavior | Risk | v10.1 follow-up |
|---|---|---|---|
| Surface declaration | `pm-chat.md` line 46–47 enumerates "Codex CLI" as shell-capable. Codex CLI on a TTY should classify as `shell`. **F-A pattern likely re-applies** — F1 evidence shows the assistant auto-infers `shell` from CLI environment without waiting for explicit reply; same model behavior expected on Codex's GPT-5.1 backbone (different model family, but the auto-inference pattern is a prompt-shape issue not a model-specific one). | medium | yes — single follow-up "Codex CLI: confirm surface-declaration gate behavior under workspace-write sandbox" |
| Plan-mode handling | Codex has no plan-mode equivalent. Approval model is `--ask-for-approval on-request` per TOOL-COMPARISON line 120 — each shell command pauses for approval. `pm-chat.md` line 26 plan-mode warning is Gemini-specific and does not apply. | low | no |
| Tool / shell sandbox | Codex CLI runs in a **workspace-write sandbox** by default (TOOL-COMPARISON line 120). `brew install` (Form I) would require explicit out-of-sandbox escalation. Procedure 7 §7.3 default `skip` on Form I means the typical happy path doesn't hit this; a developer who replies `yes` to Form I on Codex would see a sandbox-escalation prompt. | medium | yes — "Codex CLI: document Form I `yes`-path sandbox escalation in METHODOLOGY § Procedure 7.3" |
| METHODOLOGY.md access | TOOL-COMPARISON line 44: Codex CLI has filesystem repo read access. METHODOLOGY.md is read directly (not RAG-chunked). Procedure 7's order-sensitive sub-flow (§7.0 → §7.1 → §7.2 → §7.3 → §7.4) is preserved by direct read. | low | no |
| Form R/I/E/M rendering | Forms render as fenced markdown blocks (same as Claude Code CLI). Codex CLI's terminal is markdown-aware. No rendering deviation expected. | low | no |

> **Surface deferred to v10.1 docs-research pass per §0.6 scope decision.** No live run was performed against Codex CLI for v10.0. The behavior described above is derived from documentation (cite source) and architectural reasoning, not from direct observation. Tracked as v10.1 candidate per V10-PHASE-4-PLAN F-B resolution.

#### Evidence — §4.2 — DR2 Gemini CLI

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T16:38:00Z |
| Surface | Gemini CLI (live presence: `gemini` 0.38.1 at `/Users/david/.nvm/versions/node/v22.14.0/bin/gemini` — recorded but not exercised per §0.6) |
| Reference docs cited | `pm-chat.md` lines 24–28, 46–47; `TOOL-COMPARISON.md` Part 1, Part 2 line 68 (`@agent-name` invocation), Part 4 line 121 (plan mode); `V10-DESIGN.md` BD-043 (Gemini native subagent architecture); `agent-run.sh` translation logic |
| Outcome | **deferred** (F-B (b)) |
| Notes / deviations | See per-dimension table. Risk summary: medium. Two v10.1 candidates identified, one of which (plan-mode interaction) is partially mitigated by existing pm-chat.md line 26 warning. |
| Failure-mode link | F-B (b) |

| Dimension | Per-docs expected behavior | Risk | v10.1 follow-up |
|---|---|---|---|
| Surface declaration | `pm-chat.md` line 46–47 enumerates "Gemini CLI" as shell-capable. Should classify as `shell`. F-A pattern likely re-applies (same auto-inference shape). | medium | yes — "Gemini CLI: confirm surface-declaration gate" (covered by F-A's broader fix; flag if Gemini-specific) |
| Plan-mode handling | Gemini CLI has `/plan` mode that **blocks shell execution** (TOOL-COMPARISON line 121). `pm-chat.md` line 26 explicitly warns to exit plan mode before pasting kickoff. **Risk:** if a developer replies `shell` while in plan mode, Procedure 7 §7.1 Form R discovery fails because `xcodebuild`, `xcrun`, `swift-format`, `brew` cannot execute. The developer should observe a clear plan-mode-block error and re-enter without `/plan`. | medium | yes — "Gemini CLI: add plan-mode-detection check at start of Procedure 7 Form R; if shell tools blocked, ask developer to exit plan mode and retry" |
| Tool / shell sandbox | Gemini CLI runs commands via **PTY shell** (TOOL-COMPARISON line 74) — handles interactive prompts natively. No sandbox-escalation issue analogous to Codex's workspace-write. | low | no |
| METHODOLOGY.md access | TOOL-COMPARISON: filesystem with hierarchical GEMINI.md context loading. METHODOLOGY.md read directly. | low | no |
| Form R/I/E/M rendering | Gemini CLI's terminal is markdown-aware. Output rendering equivalent to Claude / Codex. No rendering deviation expected. | low | no |

> **Surface deferred to v10.1 docs-research pass per §0.6 scope decision.** No live run was performed against Gemini CLI for v10.0. The behavior described above is derived from documentation and architectural reasoning. Tracked as v10.1 candidate.

#### Evidence — §4.2 — DR3 Claude Desktop + Desktop Commander

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T16:41:00Z |
| Surface | Claude Desktop with Desktop Commander filesystem MCP enabled (not present on implementer's machine; pure docs research) |
| Reference docs cited | `pm-chat.md` line 46–47 ("Claude Desktop with Desktop Commander enabled"); `TOOL-COMPARISON.md` Part 1 line 45 ("File write access: Desktop Commander"); `METHODOLOGY.md` Procedure 7 §7.2.4 (machine-level Form M) |
| Outcome | **deferred** (F-B (b)) |
| Notes / deviations | See per-dimension table. Risk summary: medium. One v10.1 candidate identified. |
| Failure-mode link | F-B (b) |

| Dimension | Per-docs expected behavior | Risk | v10.1 follow-up |
|---|---|---|---|
| Surface declaration | `pm-chat.md` line 46–47 enumerates "Claude Desktop with Desktop Commander enabled" as shell-capable. Should classify as `shell`. F-A pattern almost certainly re-applies (same Claude model family as Claude Code CLI). | medium | partial — covered by F-A's broader fix |
| Plan-mode handling | No plan-mode equivalent on Desktop Commander. | low | no |
| Tool / shell sandbox | Filesystem-MCP mediated — **commands must be in the MCP server's allowlist**. `xcodebuild`, `xcrun`, `brew` must be present in the configured filesystem-MCP allowlist or invocation fails. **Form M (machine-level write) is the highest-risk dimension:** writing to `~/Library/Developer/Xcode/CodingAssistant/` requires Desktop Commander to have permission outside the project workspace; default filesystem-MCP configs typically scope to the project root only. | medium | yes — "Desktop Commander: METHODOLOGY § Procedure 7.2.4 Form M default `skip` is correct (machine-level write requires explicit allowlist); document the MCP-scope check in pre-Form-M discovery" |
| METHODOLOGY.md access | Desktop Commander reads METHODOLOGY.md via filesystem-MCP. Direct read (not RAG). Same order-preservation as Claude Code CLI. | low | no |
| Form R/I/E/M rendering | Claude Desktop's chat surface renders markdown identically to Claude Web. No rendering deviation expected. | low | no |

> **Surface deferred to v10.1 docs-research pass per §0.6 scope decision.** No live run was performed against Claude Desktop + Desktop Commander for v10.0. The behavior described above is derived from documentation and architectural reasoning. Tracked as v10.1 candidate.

**§4.2 risk summary across DR1–DR3:** medium overall. The most consequential cross-surface risk is the F-A auto-inference pattern (which appears likely to repeat across all three deferred surfaces given that it's a prompt-shape issue rather than a model-specific issue) and the Codex workspace-write sandbox interaction with Form I. None of these are v10.0 ship-blockers under the §0.6 scope decision; all are recorded as v10.1 candidates.

## §4.3 Claude Web manual-mode smoke

#### Evidence — §4.3 — Claude Web (no MCP)

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29 (M2 capture during this C-V10-15 session) |
| Surface | Claude Web (`claude.ai`) — no project, no GitHub connector, no Desktop Commander, no MCP |
| Paste source | `$PACK/project-template/docs/pack/prompts/pm-chat.md` kickoff variant body, 75 lines (paste file at `/tmp/phase-4-fixtures/kickoff-paste-W3.txt`) |
| Reply text | `manual` |
| Outcome | **pass** |
| Notes / deviations | Two bonus findings beyond the strict pass criterion: (1) the assistant's reply began with `Surface: **manual**.` — a confirmation/acknowledgment of the developer's reply, not a deviation. (2) The assistant proactively flagged two kickoff-variant prose accuracy issues: (a) the kickoff body says *"The GitHub connector is connected"* as a hard fact, but Claude Web with no project/connector shows only Gmail/GCal/GDrive/HF connectors — the kickoff prose has a baked-in assumption that doesn't hold for plain Web smoke; (b) the prompt asks the assistant to "search project knowledge" but no Claude Project context exists on a fresh chat. Both findings are kickoff-variant prose accuracy issues for the non-shell path; they strengthen the F-A flag-back narrative (kickoff variant has multiple environmental assumptions that should be conditional on the declared surface). |
| Failure-mode link | null (pass on the strict criterion); contributing data to F-A flag-back. |

**Assistant reply (verbatim):**

```text
Surface: **`manual`**.

I'm in the Claude.ai web interface — no shell on your machine. (I have a sandboxed Linux container for code execution, but it isn't your project environment, so it doesn't count as `shell` for this pack.)

Two things to flag before we proceed:

1. **GitHub connector not visible to me in this session.** Your kickoff states "the GitHub connector is connected," but the connectors available here are Gmail, Google Calendar, Google Drive, and Hugging Face. I cannot read `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `STATUS.md`, or `BACKLOG.md` from your repo. For a Phase 4 web smoke this is plausibly the point of the test, but worth confirming explicitly — if the connector is supposed to be wired up, the smoke caught a real gap.
2. **No Claude Project context.** This conversation is outside any Claude Project, so there is no project knowledge index to search either.

Per your kickoff's own `manual` branch, the next step is on you: open `supporting-docs/SETUP-NEW.md` § **Manual fallback** (sub-sections 5.A–5.D), run the read-only discovery there, and report the values back. Once I have them, I'll compose the corresponding edits for you to apply — `PM-CHAT.md` placeholder fill-in, the `Active skills` line in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, and any other one-time setup the kickoff calls for.

Standing by for 5.A–5.D output.
```

**Pass-criteria checks:**

- ✅ Names `supporting-docs/SETUP-NEW.md § Manual fallback (sub-sections 5.A–5.D)` — exact wording, correct sub-section range
- ✅ Does NOT name old `Steps 5–8` (pre-Phase-3-B numbering)
- ✅ No tool-call attempt
- ✅ No fenced shell block with `xcodebuild` / `brew install` / `cp …`
- ✅ Reply is short (≈12 lines), pointer-shaped, defers to developer for value capture

This is a strict pass on `V10-PHASE-3B-PLAN-v2.md` Part 7 criterion 8 (pointer-only shape, no command summary).

## §4.4 Migration script smoke

#### Evidence — §4.4 — migrate-v9-to-v10.sh on /tmp/phase-4-fixtures/v9-project

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T16:30:23Z |
| Surface | Bash on the implementer's Mac (this CLI session) |
| v9.3 source | `/tmp/v9-pack-source/` (LOCAL clone of `/Users/david/Developer/dhs-ai-agent-config-pack` at tag `v9.3` = SHA `2f937b08187d09a75131701881534d8b26aadd30`) |
| Fixture | `/tmp/phase-4-fixtures/v9-project/` (project-template/. + supporting-docs/PROMPT-TEMPLATES.md + supporting-docs/METHODOLOGY.md + minimal SPM source `PhaseFourSmokeProject`; baseline commit `017c8c9`) |
| Command(s) run | `cd /tmp/phase-4-fixtures/v9-project && "$PACK/scripts/migrate-v9-to-v10.sh" .` (stdout → `v9-migrate.stdout.txt`, stderr → `v9-migrate.stderr.txt`) |
| Migration exit code | **0** |
| Outcome | **pass** |
| Notes / deviations | Two plan-spec-drift observations (not defects): (1) plan §6.4 assumed `docs/pack/PROMPT-TEMPLATES.md` and root `METHODOLOGY.md` would land via project-template copy; reality: these live in `supporting-docs/` at pack-repo level in v9.3, so fixture construction had to copy them in explicitly. Adjusted fixture build documented in this evidence record. (2) plan §6.6 row 4b expected post-migration `METHODOLOGY.md` to be at `docs/pack/METHODOLOGY.md`; reality: script lines 348–352 keep METHODOLOGY at project root and replace its content. Procedure 7 wording verified present in the post-migration `METHODOLOGY.md` (root). Procedure 5-R paste-ready prompt is conditional on `_v9-backup.md` files existing under `docs/pack/prompts/`; v9.3 had no `docs/pack/prompts/` at all, so the conditional doesn't fire — trivially satisfied. |
| Failure-mode link | null |
| Cleanup | Pending — fixture preserved for §4.6 / §4.8 cross-reference until §10.1 single-command rollback. Final cleanup: `rm -rf /tmp/phase-4-fixtures/v9-project /tmp/v9-pack-source /tmp/phase-4-fixtures/v9-migrate.*.txt`. |

**Migration stdout (verbatim):**

```text
migrate-v9-to-v10.sh — v9.3 → v10.0 pack migration
target:  /tmp/phase-4-fixtures/v9-project
pack:    /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev

── S0 — pre-flight ──
creating and checking out branch migration-v9-to-v10
x-file audit:
  x-files: (none)
improperly-added-file audit:
  improperly-added: (none)
S0 complete.
── S1 — replace pack agents ──
S1 complete.
── S2 — replace pack skills ──
S2 complete.
── S3 — replace scripts, agent-run.sh, configs ──
S3 complete.
── S4 — create docs/pack/prompts/ ──
S4 complete.
── S5 — splice-merge trinity + pack docs ──
S5 complete.
── S6 — PROMPT-TEMPLATES.md diff vs v9.3 ──
customization: none — deleting PROMPT-TEMPLATES.md (backup preserved)
S6 complete.
── S7 — write migration report ──
S7 complete. Report written to .pack-migration-backup/v9.3-to-v10.0/report.md

Migration complete. Review `git diff` and `.pack-migration-backup/v9.3-to-v10.0/report.md`
before committing on branch migration-v9-to-v10.
```

**Migration stderr (verbatim — only the standard branch-switch notice):**

```text
Switched to a new branch 'migration-v9-to-v10'
```

**`git diff --stat` post-migration (verbatim):**

```text
 .claude/agents/auditor-architecture.md  |   9 +
 .codex/agents/auditor-architecture.toml |   1 +
 .gemini/agents/auditor-architecture.md  |   9 +
 .gitignore                              |   2 +
 .mcp.json.example                       |   2 +-
 AGENTS.md                               |  70 ++-
 CLAUDE.md                               |  65 ++-
 GEMINI.md                               |  71 ++-
 METHODOLOGY.md                          | 842 ++++++++++++++++++++++++++++----
 docs/pack/PLATFORM-SKILLS.md            |  35 ++
 docs/pack/PM-CHAT.md                    |  87 +++-
 docs/pack/PROMPT-TEMPLATES.md           | 741 ----------------------------
 scripts/bootstrap.sh                    |   3 +-
 13 files changed, 1054 insertions(+), 883 deletions(-)
```

Plus four new untracked directories (created by S4): `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`, `docs/pack/prompts/`.

**§6.6 verification check results (verbatim):**

```text
4a. git status — 13 modified, 1 deleted (PROMPT-TEMPLATES.md), 4 new untracked dirs
4b. v10 layout present:
    OK: docs/pack/prompts/  (with 10 prompt files: architect, auditor, coder,
        docs-researcher, grpc-schema, planner, pm-chat, repo-ops, reviewer, tester)
    OK: METHODOLOGY.md at project root (842-line update — Procedure 7 + Procedure 5-R + v10 content)
    OK: Procedure 7 present in root METHODOLOGY.md
    [Plan check 4b note: plan expected docs/pack/METHODOLOGY.md; reality keeps METHODOLOGY at root per script lines 348–352]
4c. Trinity carries v10 layout:
    OK: CLAUDE.md  — 2 references to docs/pack/, capabilities-pattern wording present
    OK: AGENTS.md  — 2 references to docs/pack/, capabilities-pattern wording present
    OK: GEMINI.md  — 2 references to docs/pack/, capabilities-pattern wording present
4d. Backup directory:
    OK: .pack-migration-backup/v9.3-to-v10.0/ present, populated (agent-run.sh, AGENTS.md,
        CLAUDE.md, GEMINI.md, METHODOLOGY.md, docs/, scripts/, docs-pack-PLATFORM-SKILLS.md,
        docs-pack-PROMPT-TEMPLATES.md, report.md)
    OK: .gitignore contains .pack-migration-backup/ entry
4e. PROMPT-TEMPLATES.md absent post-migration:
    OK: docs/pack/PROMPT-TEMPLATES.md removed (deleted by S6 stage; backup preserved)
4f. AF-001 parity:
    PASS — all matches are legitimate references to v10 wrapper scripts (validate.sh / test.sh /
    format.sh ARE the wrapper interface in v10; references in coder.md/reviewer.md prompts and
    in the wrapper files' own header comments are intentional).
4g. validate-pack.py at project level:
    SKIPPED per plan §6.6 — pack-repo-only check.
```

**Migration report `.pack-migration-backup/v9.3-to-v10.0/report.md` (verbatim, key fields):**

```text
# v9.3 → v10.0 migration report

**Date:** 2026-04-29T16:30:23Z
**Pack version:** v10-dev
**Target project:** /tmp/phase-4-fixtures/v9-project

## Customization status
customization: none

## x- files preserved
x-files: (none)

## Improperly-added files (post-migration Procedure 5.4 candidates)
improperly-added: (none)

## Next steps
1. Review `git diff` and this report.
2. If `_v9-backup.md` exists under `docs/pack/prompts/`, expect
   the PM chat to invoke Procedure 5-R on its next run.
3. Commit the migration ON THE `migration-v9-to-v10` BRANCH.
4. Follow `supporting-docs/MIGRATION-v9-to-v10.md` Steps 5–7.
```

**Pack-repo safety verification (post-§4.4):**

```text
Live pack repo (/Users/david/Developer/dhs-ai-agent-config-pack):
  status --porcelain: empty (clean)
  HEAD: f6721a42785fb62426660c3a2d425322e57abfb0 (unchanged from baseline)

v10-dev worktree ($PACK):
  status --porcelain: only V10-PHASE-4-VERIFICATION.md untracked (this evidence file)
  HEAD: 5e91d3e0e3714ab12d6c04cd1f9bdbcc13bbdf24 (unchanged from C-V10-15 start)
```

## §4.5 detect.sh unit-test results

#### Evidence — §4.5 — bash scripts/test-detect.sh

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T15:46:11Z |
| Surface | Bash (`/bin/bash`) + the implementer's own `scripts/test-detect.sh` runner |
| Fixture or input | None — unit tests run against in-memory test cases inside `scripts/test-detect.sh` |
| Command(s) run | `bash /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/test-detect.sh` |
| Output (verbatim) | see fenced block below |
| Outcome | pass |
| Notes / deviations | null |
| Failure-mode link | null |

```text
== detect_clean_working_tree ==
  pass: non-git dir → dirty (early-return guard)
  pass: empty git repo (no untracked) → clean
  pass: git repo with untracked file → dirty
== detect_git_repo ==
  pass: non-git dir → no
  pass: git-init'd dir → yes
== detect_pack_path ==
  pass: missing path → missing
  pass: exists but not a git repo → not-a-repo
  pass: git repo without project-template/ → not-a-repo
  pass: git repo with project-template/ → valid
  pass: real pack root → valid
== detect_pack_version ==
  pass: HEAD at exact tag v9.9 → v9.9
  pass: branch HEAD with no tag → branch name
  pass: detached HEAD with no tag → unknown
== detect_ai_config ==
  pass: no markers → (none)
  pass: .claude/ + CLAUDE.md → both listed
  pass: all six markers → comma-joined in scan order
== detect_x_files ==
  pass: no scan dirs → (none)
  pass: scan dirs present but no x- entries → (none)
  pass: one x- agent → one match
  pass: x- entries in three scan locations → three matches in scan order
== detect_improperly_added_files ==
  pass: empty target (no scan dirs) → (none)
  pass: target with only roster files → (none)
  pass: x- prefixed entries are skipped (legitimate per Procedure 5)
  pass: non-roster agent (no x- prefix) → flagged
  pass: non-roster skill dir → flagged
  pass: prompts dir with all-allowed entries → (none)
  pass: prompts dir with non-roster non-x file → flagged
  pass: PACK unset → error sentinel; non-zero exit
== detect_installed_capabilities ==
  pass: no CLAUDE.md → (no CLAUDE.md)
  pass: CLAUDE.md without Active-skills line → (no Active skills line)
  pass: Active-skills line still a placeholder → (placeholder)
  pass: Active-skills with three mappable skills → three caps, sorted
  pass: Active-skills with only architectural / agnostic skills → (none)
  pass: Active-skills with backticks → stripped + mapped correctly

=== Results: 34 passed, 0 failed ===
```

## §4.6 OT real-project migration smoke (v2 addition; conditional)

#### Evidence — §4.6 — migrate-v9-to-v10.sh on /tmp/phase-4-fixtures/ot-project

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T16:46:37Z (migration); live-OT verification at 2026-04-29T16:43:13Z (pre-clone), post-clone, post-migration, and post-§6.6-verification |
| Surface | Bash on the implementer's Mac (this CLI session) |
| Source | `/tmp/phase-4-fixtures/ot-project/` — clone of `/Users/david/Developer/OptiquityTrader/` via `git clone --no-hardlinks file:///Users/david/Developer/OptiquityTrader …`. Clone object storage independent (verified by inode comparison: live OT `.git/objects/` inode `171209947` vs clone inode `196361154` — distinct). |
| OT live baseline | HEAD SHA `d9e288ba8b897f967c52e99a0391d9495d5f8073`, branch `main`, porcelain count 0. Re-verified at 4 checkpoints during §4.6: pre-clone, immediately post-clone, immediately post-migration, post-§6.6-verification. Match exact at every checkpoint. |
| Command(s) run | `cd /tmp/phase-4-fixtures/ot-project && "$PACK/scripts/migrate-v9-to-v10.sh" .` (stdout → `ot-migrate.stdout.txt`, stderr → `ot-migrate.stderr.txt`) |
| Migration exit code | **0** |
| Outcome | **soft pass** |
| Notes / deviations | One real-project defect found (BD candidate): legacy `docs/pack/METHODOLOGY.md` is NOT removed by migration. The script (lines 347–352) writes `METHODOLOGY.md` at project root from `$PACK/supporting-docs/METHODOLOGY.md` but does not check for or remove a pre-existing `docs/pack/METHODOLOGY.md` (which is where OT had it pre-migration). Result: post-migration OT has TWO METHODOLOGY.md files — the new v10 at root and the stale v9 at docs/pack/ — with no signal indicating which is authoritative. The synthetic §4.4 fixture (METHODOLOGY at root from start) did not surface this. |
| Failure-mode link | F-C (proposed): legacy docs/pack/METHODOLOGY.md not cleaned up by migration when project had METHODOLOGY at non-root location. To file as new BD-NNN at C-V10-18. |
| Sanitization audit | This evidence block contains only structural counts, file paths, line counts, and pack-generated stdout. No OT source code body, no OT documentation body, no OT-derived names beyond the single token "OptiquityTrader" (a path component) and "OT" (an abbreviation used in this verification plan since v2 §0.8). Migration stdout/stderr are pack-generated text (not OT-derived). The clone's CLAUDE.md H1 is "# CLAUDE.md" (the template-default header — OT did not fill in `[PROJECT_NAME]`); the M-OT paste-file project name field uses the plan §6.6.4 fallback "OT (Phase 4 v2 smoke)" rather than any OT-derived value. |
| Cleanup | Deferred — OT clone preserved for §4.7 M-OT and §4.8 comparison until §6.7.9. Final cleanup at §10.1 single-command rollback: `rm -rf /tmp/phase-4-fixtures/ot-project /tmp/phase-4-fixtures/kickoff-paste-OT.txt /tmp/phase-4-fixtures/evidence-OT-*.txt /tmp/phase-4-fixtures/ot-migrate.*.txt`. Includes a final live-OT-unchanged byte-identity verification per §6.7.9. |

**Migration stdout (verbatim — pack-generated text, no OT body):**

```text
migrate-v9-to-v10.sh — v9.3 → v10.0 pack migration
target:  /tmp/phase-4-fixtures/ot-project
pack:    /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev

── S0 — pre-flight ──
creating and checking out branch migration-v9-to-v10
x-file audit:
  x-files: (none)
improperly-added-file audit:
  improperly-added: (none)
S0 complete.
── S1 — replace pack agents ──
S1 complete.
── S2 — replace pack skills ──
S2 complete.
── S3 — replace scripts, agent-run.sh, configs ──
S3 complete.
── S4 — create docs/pack/prompts/ ──
S4 complete.
── S5 — splice-merge trinity + pack docs ──
S5 complete.
── S6 — PROMPT-TEMPLATES.md diff vs v9.3 ──
customization: none — deleting PROMPT-TEMPLATES.md (backup preserved)
S6 complete.
── S7 — write migration report ──
S7 complete. Report written to .pack-migration-backup/v9.3-to-v10.0/report.md

Migration complete. Review `git diff` and `.pack-migration-backup/v9.3-to-v10.0/report.md`
before committing on branch migration-v9-to-v10.
```

**Migration stderr (verbatim):**

```text
Switched to a new branch 'migration-v9-to-v10'
```

**`git diff --shortstat` post-migration (sanitized: counts only — no body):**

```text
31 files changed, 1304 insertions(+), 1454 deletions(-)
```

| Type | Count |
|---|---|
| Modified files | 30 |
| Deleted files | 1 (docs/pack/PROMPT-TEMPLATES.md) |
| Untracked dirs | 2 (docs/pack/prompts/, .pack-migration-backup/) |

**File-class diff structure (sanitized: counts + filenames only — no OT body):**

| File class | Files | Notes |
|---|---|---|
| Pack agents (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`) | 3 | one auditor-architecture per tool, +9/+1/+9 lines |
| Pack skills (`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) | 15 | 5 skill paths × 3 tools — apple-architecture-core, architecture-review, audit-methodology, pm-startup, python-best-practices. **Real-project signal:** synthetic fixture had no pre-installed skills; OT had these from project setup. |
| Trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) | 3 | 588/322/286 lines diff — substantially larger than synthetic (65/70/71) because OT has more populated content for the splice/merge to reconcile |
| Pack docs (`docs/pack/PM-CHAT.md`, `docs/pack/PLATFORM-SKILLS.md`) | 2 | +154/+35 lines |
| Pack docs deletion (`docs/pack/PROMPT-TEMPLATES.md`) | 1 | -741 lines (S6 stage; same as synthetic — customization: none) |
| Project-side scripts (`scripts/test-swift.sh`, `scripts/validate-swift.sh`) | 2 | 4 lines each. **Real-project signal:** synthetic fixture had no language wrappers pre-installed; OT had these. |
| Other (`scripts/bootstrap.sh`, `.gitignore`, `.codex/config.toml`, `.mcp.json.example`) | 4 | small diffs (3/2/11/2 lines) |
| Untracked: `docs/pack/prompts/` | 1 dir, 10 files | architect.md, auditor.md, coder.md, docs-researcher.md, grpc-schema.md, planner.md, pm-chat.md, repo-ops.md, reviewer.md, tester.md (same set as synthetic) |
| Untracked: `.pack-migration-backup/v9.3-to-v10.0/` | 18 entries | backup of pre-migration state |

**§6.6 OT-adapted post-migration verification:**

```text
v10 layout present:
  OK: docs/pack/prompts/ — 10 prompt files (same set as synthetic)
  OK: METHODOLOGY.md at project root (Procedure 7 verified present)
  WARN: docs/pack/METHODOLOGY.md ALSO present — legacy v9 location
        not removed by migration. F-C flag-back proposed.

Trinity references:
  OK: CLAUDE.md  — 2 docs/pack/ refs, 3 capabilities-pattern mentions
  OK: AGENTS.md  — 2 docs/pack/ refs, 3 capabilities-pattern mentions
  OK: GEMINI.md  — 2 docs/pack/ refs, 3 capabilities-pattern mentions

Backup directory:
  OK: .pack-migration-backup/v9.3-to-v10.0/ present, 18 entries
  OK: .gitignore contains .pack-migration-backup/ entry

PROMPT-TEMPLATES.md absent post-migration:
  OK: docs/pack/PROMPT-TEMPLATES.md removed (S6 stage)

AF-001 parity:
  PASS — same shape as synthetic.

validate-pack.py at project level:
  SKIPPED per plan §6.6 — pack-repo-only check.
```

**Live-OT byte-identity verification across §4.6 checkpoints:**

| Checkpoint | Live OT HEAD | Porcelain | Match? |
|---|---|---|---|
| Pre-flight (Part 1, 2026-04-29T15:43:03Z) | `d9e288ba…` | 0 | baseline |
| Pre-clone re-capture (2026-04-29T16:43:13Z) | `d9e288ba…` | 0 | ✅ |
| Post-clone | `d9e288ba…` | 0 | ✅ |
| Post-migration | `d9e288ba…` | 0 | ✅ |
| Post-§6.6-verification | `d9e288ba…` | 0 | ✅ |

**OT HEAD SHA unchanged across all four post-baseline checkpoints. OT working tree still clean. The `--no-hardlinks file://` clone strategy held end-to-end.**

## §4.7 OT post-migration kickoff smoke (M-OT) (v2 addition; conditional)

#### Evidence — §4.7 — Claude Code CLI on /tmp/phase-4-fixtures/ot-project (post-migration)

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T17:07Z–17:09Z (M-OT walk-through) |
| Surface | Claude Code CLI 2.1.123, run from `/tmp/phase-4-fixtures/ot-project/` (post-migration OT clone, on `migration-v9-to-v10` branch) |
| Fixture or input | `/tmp/phase-4-fixtures/ot-project/` (the §4.6 post-migration OT clone, preserved across §4.6 → §4.7); kickoff paste at `/tmp/phase-4-fixtures/kickoff-paste-OT.txt` (75 lines, project name token "OT (Phase 4 v2 smoke)" via plan §6.6.4 fallback — OT did not fill in `[PROJECT_NAME]` in its trinity, so H1 extraction yielded the template-default) |
| Command(s) run | `cd /tmp/phase-4-fixtures/ot-project && pwd && pbcopy < /tmp/phase-4-fixtures/kickoff-paste-OT.txt && claude` — paste kickoff, then user replies (in order): `(no surface-declaration reply asked — F-A pattern repeats)`, `yes` (Form R), `skip` (Form E), `skip` (Form M); Form I auto-rendered as inline "preview, no action needed" with no separate gate |
| Outcome | **soft pass** |
| Notes / deviations | F-A pattern repeats on real-project surface (gate auto-inference; Form I collapsed into Form R results as "preview"). F-C independently confirmed by the assistant — its post-Procedure-7 surface section explicitly named the METHODOLOGY.md root-vs-docs/pack/ duplication and recommended `git mv` resolution. All substantive Procedure 7 invariants held: real `xcodebuild -list` discovery on OT's actual project (single scheme), real `xcrun simctl` enumeration with smart `platform=macOS` override based on declared kickoff target, JSON parse-mutate-serialize on `.claude/settings.json` (NOT regex), non-SPM `SWIFT_SOURCE_DIRS` branch fired correctly (synthetic F1 had SPM and skipped this branch), Form M used `cmp -s` for byte-identity check (3 of 4 identical, 1 differs), `skip` replies honored, no machine-level writes, no `brew install` attempts. **Live OT byte-identity check post-M-OT (per step 16):** HEAD SHA `d9e288ba8b897f967c52e99a0391d9495d5f8073`, porcelain empty — match exact with baseline. |
| Failure-mode link | F-A (pattern continues; same flag-back as §4.1 / §4.3); F-C (independently confirmed by the post-migration kickoff itself). No new failure-modes beyond those two. |
| Sanitization audit | Per §6.6.7 sanitization rules: this evidence block records only counts, structural shape descriptions, pack-generated diff anchors, and Procedure-7-format-derived gate outcomes. Project-internal content from the assistant's reply (specific OT phase names, test counts, architecture-pattern descriptions, business-domain identifiers) is NOT quoted into the evidence record. The OT scheme name `OptiquityTrader` appears in Form E discovered values because it is the discovered XCODE_SCHEME (an unavoidable identifier for the substantive correctness check) and as a single-token directory name — same token already present in `/Users/david/Developer/OptiquityTrader/` path. No source code body, no documentation body, no enumerations of OT-internal product names beyond the project root identifier. |

**Procedure 7 gate outcomes (post-skip):**

| Gate | Outcome |
|---|---|
| G7-discovery (Form R) | ✅ ran (read-only, against real OT clone state) |
| G7-edit (Form E) | ⏭ skipped by user — all 4 proposed edits |
| G7-install (Form I) | ⏭ N/A — swift-format already in pack-tested ≥510.0.0 range; gRPC sub-flow doesn't fire (no `proto/`); Python gRPC N/A (no Python in OT) |
| G7-machine (Form M) | ⏭ skipped by user — 3 of 4 companion files byte-identical; 1 differs (Codex/config.toml — pack source 2591 B vs installed 2643 B, dated 2026-04-19); rendered with "reinstall recommended" line and default skip per §7.2.4 |

**Form R discovery (sanitized — pack-generated structural shape, not OT business content):**

| Discovery item | Result |
|---|---|
| `xcodebuild -list` | single scheme detected — auto-fill |
| `xcrun simctl list devices available` | many iOS simulators present; project is macOS-targeted per kickoff → assistant overrode to `platform=macOS` (correct §7.2.1 override behavior given kickoff PLATFORM_TARGETS) |
| Source layout | non-SPM (no `Sources/`, no `Tests/`; project-named source dir + tests dir present) |
| `swift-format --version` | 602.0.0 (within pack-tested ≥510.0.0) |
| Environment | `brew`, `uv`, `python3` all present |
| gRPC tooling | not installed; sub-flow correctly skipped (no `proto/` dir, REST transport per Active skills) |
| `~/Library/Developer/Xcode/CodingAssistant/` companion files | 4 checked: 3 byte-identical to pack source, 1 differs (Codex/config.toml) |

**Form E proposed values (substantive correctness — quoted because they are pack-side anchors, not OT body):**

```diff
[1] scripts/validate-swift.sh
-XCODE_SCHEME=""
+XCODE_SCHEME="OptiquityTrader"
-XCODE_DESTINATION=""
+XCODE_DESTINATION="platform=macOS"

[2] scripts/test-swift.sh
(same anchor pair, same values as [1])

[3] .claude/settings.json (env block — JSON parse-mutate-serialize, NOT regex)
"env": {
  "AGENT_CAPABILITIES": "...",
- "XCODE_SCHEME": "",
+ "XCODE_SCHEME": "OptiquityTrader",
- "XCODE_DESTINATION": ""
+ "XCODE_DESTINATION": "platform=macOS"
}

[4] scripts/format-swift.sh (non-SPM branch — fired because no Sources/ or Tests/)
-SWIFT_SOURCE_DIRS=""
+SWIFT_SOURCE_DIRS="OptiquityTrader OptiquityTraderTests"
```

**Notable Form E behaviors (pack-design correctness checks):**

- ✅ **Smart destination override (Procedure 7.2.1):** `xcrun simctl` showed many iOS simulators — Procedure 7's default would pick the latest iOS sim. Assistant overrode to `platform=macOS` because kickoff declared macOS as the platform target. The assistant explicitly explained this override in its reply ("Reply edit if you'd rather target an iOS simulator"). This is correct §7.2.1 behavior.
- ✅ **Non-SPM detection (Procedure 7.2.2 and SETUP-NEW.md § 5.A):** SWIFT_SOURCE_DIRS branch correctly fired because no `Sources/` or `Tests/` exists. Synthetic F1 fixture had SPM layout so this branch did not fire there — §4.7 is the first time the non-SPM `SWIFT_SOURCE_DIRS` path was exercised in this verification.
- ✅ **JSON parse-mutate-serialize, not regex:** assistant's reply explicitly named the technique. Procedure 7.2.2 forbids regex on JSON; this is a critical compliance check.
- ✅ **Form M `cmp -s`:** assistant explicitly stated byte-identity comparison was performed against pack source path; 3 of 4 identical → skip; 1 differs → render with "reinstall recommended" + default `skip` per §7.2.4.

**Independent F-C confirmation (sanitized — paraphrased, not verbatim project body):**

The assistant's post-Procedure-7 "Items I'll surface after Procedure 7 completes (NOT touched by P7)" section flagged METHODOLOGY.md duplication as item #1: root copy (untracked, has Procedure 7) vs docs/pack/ copy (tracked, missing Procedure 7). Recommended resolution: `git mv` root copy to `docs/pack/` to canonicalize. This is independent confirmation of F-C from §4.6 — the post-migration kickoff itself catches the duplication and proposes a resolution, which is exactly the user-facing experience F-C's flag-back narrative predicts. The assistant correctly observed that this was outside Procedure 7's scope (§7.7 boundary respected) and waited for explicit instruction. **No action taken on the assistant's recommendation during the smoke test** — the M-OT walkthrough's `skip` discipline held.

**Procedure 7.7 boundary compliance:**

The assistant flagged three additional items as outside Procedure 7's scope and waited for separate decisions: (1) trinity placeholder fills (still bracketed per pre-migration state), (2) PM-CHAT.md fill (N/A — file doesn't exist at project root, correctly observed), (3) STATUS.md pack-version stale. Each was correctly identified as a §7.7 follow-on rather than a Procedure 7 action. Assistant did NOT propose to apply any of these without explicit instruction.

**Live-OT byte-identity verification across §4.7:**

| Checkpoint | Live OT HEAD | Porcelain | Match? |
|---|---|---|---|
| Pre-flight | `d9e288ba…` | 0 | baseline |
| Pre-clone | `d9e288ba…` | 0 | ✅ |
| Post-clone | `d9e288ba…` | 0 | ✅ |
| Post-§4.6 migration | `d9e288ba…` | 0 | ✅ |
| Post-§4.6 verification | `d9e288ba…` | 0 | ✅ |
| Post-M-OT (step 16) | `d9e288ba…` | 0 | ✅ |
| Post-§4.8 + supplementary | `d9e288ba…` | 0 | ✅ |
| **§6.7.9 final post-cleanup** | **`d9e288ba…`** | **0** | **✅** |

**OT HEAD SHA unchanged across all eight post-baseline checkpoints, including the final post-cleanup byte-identity check after `/tmp/phase-4-fixtures/`, `/tmp/v9-pack-source/`, and the two scratch files were removed by §10.1 single-command rollback. The `--no-hardlinks file://` clone strategy + `cd /tmp/phase-4-fixtures/ot-project/` discipline held end-to-end.**

## §4.8 OT-vs-synthetic comparison (v2 addition; conditional)

#### Evidence — §4.8 — Bash; structural comparison only

| Field | Value |
|---|---|
| Timestamp (UTC) | 2026-04-29T17:18:48Z |
| Surface | Bash (this CLI session); read-only across both `/tmp/phase-4-fixtures/v9-project/` (§4.4 synthetic post-migration tree) and `/tmp/phase-4-fixtures/ot-project/` (§4.6 OT post-migration tree); writes only to scratch files under `/tmp/phase-4-fixtures/cmp.*` |
| Outcome | **pass** (with one informational observation — see Notes) |
| Notes / deviations | Synthetic-only path count is 40, exceeding the plan's "≤~5" pass-criterion threshold. This is the fixture-thinness issue called out at OQ-VP4-4 (plan §0.6 "RESOLVED — thin v9.3 fixture for v10.0"): the synthetic fixture copied `project-template/.` directly, retaining v9.3's top-level `skills/`, `proto/`, `server/`, `Package.swift`, `pyproject.toml`, `pyrightconfig.json`, and `Sources/` artifacts. OT had these already distributed via prior `init-project.sh` runs to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`. Not a defect — informational fixture-design observation; §4.4 fixture's known thinness. The 40 synthetic-only paths are the v9.3 project-template's untouched top-level skill+source layout (39 of 40 are exactly that pattern). |
| Failure-mode link | null (informational only; no F-G; no F-E pursuant to plan §6.7.8 row 5 — synthetic fixture's thinness is project-lead-resolved per OQ-VP4-4) |
| Cleanup | Pending — `/tmp/phase-4-fixtures/cmp.*` scratch files removed at §10.1 single-command rollback alongside both fixtures. |

**Quantitative summary:**

```text
── §4.8 quantitative summary ──
Generated: 2026-04-29T17:18:48Z

File-count delta:
  synthetic post-migration paths:      218
  OT post-migration paths:             441
  common paths:                        178
  synthetic-only:                       40
  OT-only:                             263

Trinity section-count delta:
  CLAUDE.md — synthetic 23 sections; OT 23 sections; delta 0
  AGENTS.md — synthetic 19 sections; OT 19 sections; delta 0
  GEMINI.md — synthetic 26 sections; OT 26 sections; delta 0

Custom-skills count (x-* directories under .claude/skills/):
  synthetic: 0
  OT:        0
  delta:     0

x-files count (across .claude/agents, .codex/agents, .gemini/agents):
  synthetic: 0
  OT:        0
  delta:     0

validate-pack.py exit codes (run with cwd at each tree):
  synthetic: 0 (validates the absolute-path pack repo)
  OT:        0 (validates the absolute-path pack repo)
  match:     yes

Migration stdout diff lines:        9 (only target-path difference)
Procedure 5-R prompt: not emitted in either stdout (conditional on _v9-backup.md files; neither fixture had pre-v10 docs/pack/prompts/)
```

**Trinity-section count parity is the strongest §4.8 signal:** the migration's S5 splice/merge produced byte-identical section counts across the two trees (23/19/26 each), even though OT had substantially more populated trinity content pre-migration (per §4.6 diff-stat: OT trinity diffs 588/322/286 lines vs synthetic 65/70/71). This is direct evidence that the splice/merge stage's structural shape is invariant under real-project complexity.

**Migration stdout diff (9-line unified diff — pack-generated):**

```diff
--- /tmp/phase-4-fixtures/v9-migrate.stdout.txt	2026-04-29 12:30:24
+++ /tmp/phase-4-fixtures/ot-migrate.stdout.txt	2026-04-29 12:46:38
@@ -1,5 +1,5 @@
 migrate-v9-to-v10.sh — v9.3 → v10.0 pack migration
-target:  /tmp/phase-4-fixtures/v9-project
+target:  /tmp/phase-4-fixtures/ot-project
 pack:    /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
 
 ── S0 — pre-flight ──
```

**The two stdouts are byte-identical except for the `target:` path line.** This is exactly the §6.7.8 pass-criterion behavior (path-normalized stdouts equal).

**Synthetic-only paths (40, safe to enumerate per §6.7.7 — describes synthetic fixture):**

```text
Package.swift
proto/buf.gen.yaml
proto/buf.yaml
proto/common/v1/common.proto
proto/example/v1/example_service.proto
pyproject.toml
pyrightconfig.json
server/src/app/__init__.py
server/tests/test_smoke.py
skills/api-design/SKILL.md
skills/apple-architecture-core/SKILL.md
skills/architecture-review/SKILL.md
skills/audit-methodology/SKILL.md
skills/c-language/SKILL.md
skills/cpp-language/SKILL.md
skills/debugging/SKILL.md
skills/dependency-intake/SKILL.md
skills/dependency-python/SKILL.md
skills/dependency-swift/SKILL.md
skills/deployment-apple/SKILL.md
skills/deployment-python/SKILL.md
skills/documentation/SKILL.md
skills/error-handling/SKILL.md
skills/grpc-patterns/SKILL.md
skills/implementation/SKILL.md
skills/ios-architecture/SKILL.md
skills/macos-architecture/SKILL.md
skills/objc-language/SKILL.md
skills/planning/SKILL.md
skills/pm-startup/SKILL.md
skills/python-architecture/SKILL.md
skills/python-best-practices/SKILL.md
skills/repo-ops/SKILL.md
skills/rest-patterns/SKILL.md
skills/review/SKILL.md
skills/security-patterns/SKILL.md
skills/swift-best-practices/SKILL.md
skills/testing/SKILL.md
skills/ui-test-strategy/SKILL.md
Sources/PhaseFourSmokeProject/PhaseFourSmokeProject.swift
```

**OT-only paths (263, structural bucket counts only — top-level dir names sanitized per §6.7.7):**

```text
  135 entries in <bucket-1>
   58 entries in <bucket-2>
   47 entries in <bucket-3>
   19 entries in <bucket-4>
    3 entries in <bucket-5>
    1 entry  in <bucket-6>
```

The 6 buckets distribute as expected for a real-project layout (one large source-code bucket, multiple supporting directories). All bucket names are OT-derived and not reproduced here.

**§6.7.8 pass-criteria evaluation:**

| Check | Pass criterion | Observed | Result |
|---|---|---|---|
| Both trees still exist | yes | both present | ✅ |
| validate-pack.py exits match | yes (both same value) | both 0 | ✅ |
| Migration stdout diff bounded | informational | 9 lines, only target-path differs | ✅ |
| Procedure 5-R diff (path-normalized) | 0 lines if emitted | not emitted in either (conditional behavior; consistent) | ✅ N/A |
| Synthetic-only path count ≤ ~5 | yes | 40 | ⚠️ exceeded — informational only (OQ-VP4-4 thinness) |
| OT-only path count plausibly OT-derived | yes | 263 in 6 buckets — real layout | ✅ |
| Quantitative summary fully populated | yes | yes | ✅ |

**§4.8 verdict: PASS** — no defect specific to OT-shaped projects detected. The migration script's structural behavior is invariant under real-project complexity. The synthetic-only path-count overshoot is a fixture-design thinness, not a script defect.

## Supplementary findings — post-§4.8 real-project testing

*During project-lead inspection of the OT clone (after §4.8 evidence captured, before §10.1 cleanup), additional manual testing was performed: `claude` + `/pm-startup` in the OT clone, followed by paraphrased walk-throughs of two completed-in-real-life phases (Phase 28 and Phase 32) to test the v10 PM chat's prompt-generation discipline. This section captures the findings from that supplementary testing. No /tmp/ project-internal content (specific phase names, test counts, file paths under the project source tree, business-domain identifiers) is quoted here — only the process observations.*

**Supplementary scope:** project lead ran one `/pm-startup` invocation and two coder-prompt walk-throughs (read-only — explicitly framed as "this is only a test, never commit, never run destructive git"). No code was written. No commits to OT clone or live OT.

**Live OT verification post-supplementary:** HEAD SHA `d9e288ba8b897f967c52e99a0391d9495d5f8073`, porcelain empty — still match.

### Positive findings (P1–P8) — strong v10 design validation

These are direct evidence the v10 design is working substantively on a real project:

**P1 — `/pm-startup` works on a v10-migrated real project.** Generated a clean startup summary identifying current phase, open BACKLOG count, last commit, pack version, skills profile, active skills, and several anomalies (stale pack version in STATUS.md, unfilled trinity placeholders, the user-induced METHODOLOGY rename — see F-E / F-F).

**P2 — Active-skills coverage check (BD-038) fired correctly.** PM chat identified the next phase's tech surface (logging/file-I/O/UserDefaults/concurrency primitives) and confirmed current skills cover all of it — no gap to flag. **This is the BD-038 dynamic-skill-management feature from v9.1 working as intended.**

**P3 — Generated coder prompt is BD-049-compliant and high-quality.** Both walk-through prompts have the canonical labeled-section structure: Context / Required reading / **Problem** / **Goal** / **Success criteria** / Files in scope / Tasks / Test requirements / Constraints / **Completion report** with `REPORT FILE:` header. Required sections "Unplanned file modifications" and "Deferred items" present with the `(write "None" if no…)` markers. Typed deferral guidance with `TD-TBD` sentinel. **This is BD-049's labeled-section convention working exactly as designed.**

**P4 — Agent caught a real plan-spec defect.** Recognized that one of the phase's plan tasks contained a deferral comment NOT matching the project's typed deferral format (`// TODO(scope): TD-TBD — Short title`) and proposed a corrected version. **Direct evidence that v10's prompt-template discipline produces agents that catch project-spec drift — exactly the value proposition.**

**P5 — Phase-specific safety concerns added correctly.** For the second walk-through (a `#if DEBUG`-only debug panel phase), the PM chat added: (a) `#if DEBUG` discipline (top-to-bottom wrapping), (b) Release-build symbol-absence verification step, (c) layer-discipline reminder (no data-layer imports from view), (d) privacy reminder (no credentials/tokens in dumped state), (e) capabilities-pattern reminder (BD-045: do not branch on concrete types), (f) explicit no-op framing of a cross-reference task. Each is a phase-specific PM-chat fill-in — the agent applied judgment to add them.

**P6 — Architect-vs-coder routing decision reasoned correctly.** For the Phase 32 walk-through, the PM chat recognized the open design question was small and contained (protocol-vs-direct-service-access), baked the chosen architecture into the coder prompt as a constraint, and skipped the architect round-trip. Exactly the v10 "PM chat decides for small decisions" methodology.

**P7 — Cross-tool routing applied:** Coder → Codex CLI (Implementation default per CLAUDE.md routing table); Reviewer → Claude Code. Per the v10 cross-tool decision table.

**P8 — Boundary discipline preserved.** Both prompts include the explicit reminder: *Do not write to `BACKLOG.md / STATUS.md / CHANGELOG.md / PACK-FEEDBACK.md / ARCHITECTURE.md / IMPLEMENTATION_PLAN.md / CLAUDE.md / AGENTS.md / README.md` or any other root .md*. PM-chat-only writes are honored. Both prompts include caveat sections distinguishing "PM-chat fill-in" vs "template-shipped" content — good metadata transparency.

### Issues found in supplementary testing

**F-G surfaced in this testing — see Flag-backs invoked section below for the full text.** The Phase 32 walk-through revealed solution leakage in the PM-chat-generated prompt (specific polling rates, timer-suspend lifecycle, snapshot-as-value-type architectural details, presentation rendering choices). Phase 28 had milder leakage (parameter-injection-for-testability suggestion). **The labeled-section convention (BD-049) shipped, but the format-vs-solutions discipline behind it (METHODOLOGY § Prompt Authoring Principles) needs sharper guidance on this specific distinction.**

### Sanitization audit (supplementary)

This supplementary section paraphrases project-internal observations (current phase number, BACKLOG count, tech-surface descriptions, prompt-generation patterns) without quoting verbatim project content. The two walk-through coder prompts that the PM chat generated contain heavy OT-derived content (specific file paths under the project source tree, business-domain identifiers, phase-internal details) and are NOT preserved in the pack repo. The raw transcripts live in the conversation that produced them and in `/tmp/` working memory; per §6.5.10 / §6.6.7 sanitization rules, they don't migrate to the pack repo.

## Summary

| Section | Outcome | Notes |
|---|---|---|
| §4.1 | soft pass | F1 only (minimal scope per §0.7); 3 documented deviations from strict Procedure 7 (gate auto-inference); all substantive values correct. F-A flag-back proposed. |
| §4.2 | deferred (3 surfaces, F-B (b)) | DR1 Codex / DR2 Gemini / DR3 Desktop Commander — docs-research pass complete; medium overall risk; 4 v10.1 candidates noted |
| §4.3 | pass | M2 reply correctly names `SETUP-NEW.md § Manual fallback 5.A–5.D`, no tool calls, no inline shell block. Two bonus findings re: kickoff-variant prose accuracy — strengthen F-A. |
| §4.4 | pass | exit 0; all S0–S7 stages complete; v10 layout landed; trinity merged; PROMPT-TEMPLATES.md deleted with backup; 13 files changed +1054/-883. Two plan-spec-drift observations recorded (not defects). |
| §4.5 | pass | 34/34 passed |
| §4.6 *(v2)* | soft pass | exit 0; all S0–S7 stages complete; same v10 layout as synthetic; live OT verified unchanged at 4 checkpoints; one real-project defect found — F-C (legacy docs/pack/METHODOLOGY.md not cleaned by migration). |
| §4.7 *(v2)* | soft pass | F-A pattern repeats on real-project surface; substantively strong (single scheme + smart `platform=macOS` override + JSON parse-mutate-serialize + non-SPM branch + Form M `cmp -s` all correct); F-C independently confirmed by the assistant's post-P7 surface section. The assistant's recommendation to `git mv root → docs/pack/` for METHODOLOGY.md is also evidence of F-D (downstream agent confusion from v10 design contradiction). Live OT verified unchanged at 6 checkpoints total. |
| §4.8 *(v2)* | pass | trinity section parity (23/19/26 = 23/19/26) confirms splice/merge invariant under real-project complexity; migration stdout byte-identical modulo target path; no OT-shape defect detected; one informational fixture-thinness observation (synthetic-only count 40 exceeds plan's "≤5", consistent with OQ-VP4-4). |
| Supplementary | pass + flag-backs | `/pm-startup` + 2 paraphrased coder-prompt walk-throughs (Phase 28 + Phase 32) on OT clone. **Strong positive evidence (P1–P8):** /pm-startup works on v10-migrated real project, BD-038 active-skills coverage check fires correctly, BD-049 labeled-section convention produces high-quality prompts, agent caught real plan-spec defect (corrected non-typed deferral comment), phase-specific safety concerns added correctly (#if DEBUG discipline, layer reminders, privacy reminders, capabilities pattern), architect-vs-coder routing reasoned correctly, cross-tool routing applied, boundary discipline preserved. **Issues:** F-E (migration leaves "Pack version: v9" stale), F-F (migration doesn't address unfilled trinity placeholders), F-G (solution leakage in PM-chat-generated prompts). Live OT verified unchanged at every step. |

## Flag-backs invoked

**F-A (proposed) — Kickoff surface-declaration gate auto-inferable; kickoff variant prose has environmental assumptions.** Sections invoking: §4.1 F1 (soft pass), §4.3 Web manual smoke (pass with bonus findings), §4.2 docs-research pass (predicted across DR1/DR2/DR3). Two related defect surfaces:

1. **Gate auto-inference.** The assistant proceeds past the surface-declaration gate without an explicit `shell` reply when running on a CLI surface, in violation of `pm-chat.md` kickoff line 50 ("Reply with the single word `shell` or `manual` before continuing.") and METHODOLOGY § Procedure 7.0 ("PM chat enters Procedure 7 when the kickoff-variant continuation pointer fires on a `shell` declaration."). The same pattern collapses Form I (G7-install) and Form M (G7-machine) into the Form R results table rather than rendering them as separate gates. Substantively non-destructive (Form R is read-only; substantive determinations correct), but procedurally a deviation. Per §4.2 DR1/DR2/DR3 analysis, the pattern is a prompt-shape issue (not model-specific) and is likely to repeat on Codex CLI / Gemini CLI / Desktop Commander.

2. **Kickoff variant prose has hardcoded environmental assumptions.** Per §4.3 evidence, the kickoff body declares as fact: *"The GitHub connector is connected"* and asks the assistant to *"search project knowledge"* — but a fresh Claude Web chat with no Claude Project and no GitHub connector cannot do either. The prose should be conditional on the declared surface (or omitted in favor of a discovery-and-report pattern).

**Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep with both sub-defects scoped together; resolution scope (v10.0 patch vs. v10.1) to be decided by project lead at Gate F. Recommended scope: v10.1 patch — both sub-defects are non-destructive procedural deviations that don't block v10.0 ship.

**F-B (b) — Three cross-surface live-runs deferred to v10.1.** Sections: §4.2 DR1 Codex CLI, DR2 Gemini CLI, DR3 Desktop Commander. Per §0.6 scope decision and `V10-PHASE-4-VERIFICATION-PLAN-v2.md` Part 4, live runs against these three surfaces were replaced with a docs-research deviation analysis. Both `codex` and `gemini` happen to be present on the implementer's PATH but were not exercised live per §1.3 silent-scope-expansion rule. Four v10.1 candidates surfaced from the docs-research pass:

1. Codex CLI: confirm surface-declaration gate behavior under workspace-write sandbox.
2. Codex CLI: document Form I `yes`-path sandbox escalation in METHODOLOGY § Procedure 7.3.
3. Gemini CLI: add plan-mode-detection check at start of Procedure 7 Form R; if shell tools blocked, ask developer to exit plan mode and retry.
4. Desktop Commander: METHODOLOGY § Procedure 7.2.4 Form M default `skip` is correct; document the MCP-scope check in pre-Form-M discovery.

**Action:** file as v10.1 BACKLOG candidates at C-V10-18 BACKLOG sweep.

**F-C (proposed) — Legacy docs/pack/METHODOLOGY.md not cleaned up by migration.** Section: §4.6 OT real-project migration smoke (soft pass; surfaced only on OT, not in synthetic §4.4). Defect: `migrate-v9-to-v10.sh` lines 347–352 write `METHODOLOGY.md` at project root from `$PACK/supporting-docs/METHODOLOGY.md` but do not check for or remove a pre-existing `docs/pack/METHODOLOGY.md`. Real-world impact: a v9.3 user project that placed METHODOLOGY at `docs/pack/METHODOLOGY.md` (as OT did) ends up post-migration with two METHODOLOGY.md files — the new v10 at root and the stale v9 at docs/pack/ — with no signal indicating which is authoritative. The synthetic §4.4 fixture had METHODOLOGY at root from start, so this case was not exercised. **Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep. Recommended fix scope: v10.0 patch — the script can detect and remove a stale `docs/pack/METHODOLOGY.md` when writing the root copy (one ~3-line check); low risk; high real-project value. Project lead decides at Gate F whether this lands in v10.0 or v10.1.

**F-D (proposed; v10.0 ship-blocker candidate) — v10 design contradiction: trinity says `docs/pack/METHODOLOGY.md`, scripts install to project root.** Discovered during project-lead post-§4.8 inspection of the OT clone (2026-04-29, after §4.8 evidence captured). Defect: the v10 design is internally inconsistent about where METHODOLOGY.md belongs.

| Source | Says METHODOLOGY.md belongs at... |
|---|---|
| `project-template/CLAUDE.md` line 275 (trinity table row for `docs/pack/`) | **`docs/pack/METHODOLOGY.md`** |
| `project-template/CLAUDE.md` line 279 (Root-level files list) | METHODOLOGY.md is NOT in the root list |
| `scripts/init-project.sh` line 369 comment: *"METHODOLOGY.md lives at project root per v10 convention"* — `cp` to `"$TARGET/METHODOLOGY.md"` (line 373) | **project root** |
| `scripts/migrate-v9-to-v10.sh` lines 347–352 (S5 stage) | **project root** |
| Verified observation: F1 fixture (built fresh by `init-project.sh` during Pre-flight + §4.1 build) — `METHODOLOGY.md` lives at fixture root | **project root** (matches scripts; contradicts trinity) |
| Verified observation: synthetic v9-project (post-migration §4.4) — METHODOLOGY.md at root | **project root** |
| Verified observation: OT post-migration (§4.6) — new v10 METHODOLOGY at root, stale v9 still at `docs/pack/` | **both** (root from migration + docs/pack/ legacy unremoved per F-C) |

**Real-world impact (already observed in §4.7):** the M-OT assistant in §4.7 read the trinity, concluded `docs/pack/` was canonical, and recommended `git mv root → docs/pack/` to "canonicalize" — choosing the trinity over the scripts' actual behavior. This is a documented case of the contradiction confusing a downstream agent on a real project. The same confusion will happen on every v10 project (fresh or migrated) until the contradiction is resolved.

**Resolution options:**

| Option | Edit | Pros | Cons |
|---|---|---|---|
| (a) Make trinity match scripts (METHODOLOGY at root) | Update `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` trinity rule: remove METHODOLOGY.md from the `docs/pack/` row of the directory table; add it to "Root-level files: CLAUDE.md, AGENTS.md, GEMINI.md, README.md, agent-run.sh" line | Smaller change. METHODOLOGY at root matches user expectations of pack-vs-project file separation (METHODOLOGY is project-level convention; docs/pack/ is pack-distributed material). | Diverges from the M-OT assistant's recommendation; need to also update F-C scope (the F-C fix would still apply: remove legacy docs/pack/METHODOLOGY.md during migration). |
| (b) Make scripts match trinity (METHODOLOGY at docs/pack/) | Update `init-project.sh` line 373 to copy to `$TARGET/docs/pack/METHODOLOGY.md`; update `migrate-v9-to-v10.sh` S5 to write to `docs/pack/METHODOLOGY.md` instead of root; update F1 / verification fixtures to expect docs/pack/ location. | Aligns with the M-OT assistant's recommendation; treats METHODOLOGY as pack-distributed (which it is — comes from `$PACK/supporting-docs/METHODOLOGY.md`). | Larger change; multi-file. F-C becomes "remove stale root METHODOLOGY.md if present at migration time" instead of the reverse. |

**Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep. **Recommended scope: v10.0 ship-blocker** — every v10 project the pack creates is currently internally inconsistent at the metadocumentation level; the inconsistency is one or two trivial edits to resolve; the M-OT evidence shows real-world AI-agent confusion downstream. Project lead decides at Gate F: (a) trinity-matches-scripts (smaller fix), (b) scripts-match-trinity (larger fix), or (c) defer to v10.1 (absorbing the contradiction into v10.0 ship state).

**F-E (proposed) — Migration leaves "Pack version: v9" stale in project-internal docs.** Section: Supplementary findings — post-§4.8 real-project testing (`/pm-startup` on OT clone). Defect: `migrate-v9-to-v10.sh` does not update project-internal "Pack version" markers that v9.3 user projects commonly carry (e.g., a `**AI Agent Config Pack**: v9` line in `docs/project/STATUS.md`). Post-migration the project says it's still on v9 even though the pack content has been migrated to v10. The PM chat's `/pm-startup` correctly flagged the stale version in OT (reported `Pack version: v9` despite the v10-migrated content). Real-world impact: developers reading STATUS.md post-migration get inconsistent signals about which pack version they're on. **Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep. Recommended fix scope: v10.0 patch — the migration script can either (a) attempt a sed update of common pack-version markers in `docs/project/STATUS.md` (best-effort; structural pattern likely varies project-to-project), or (b) emit an end-of-run instruction telling the developer/PM chat to update STATUS.md and similar markers. Option (b) is lower risk. Project lead decides at Gate F.

**F-F (proposed) — Migration does not address unfilled trinity placeholders.** Section: Supplementary findings (same `/pm-startup` run as F-E). Defect: a v9.3 user project may have left `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, and Active-skills line placeholders unfilled in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (this is the case in OT — placeholders never filled). The migration script's S5 trinity splice/merge stage runs unconditionally regardless, but does not detect or surface unfilled placeholders to the developer. Real-world impact: post-migration projects can carry literal `[PROJECT_NAME]` text in their context files indefinitely; AI agents reading those files get template-default identifiers instead of the real project name. **Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep. Recommended fix scope: v10.1 patch — migration's S0 pre-flight or S7 report stage can grep trinity files for unfilled `\[[A-Z_]+\]` patterns and warn. Lower priority than F-D / F-E because it's a PM-chat-resolvable issue (`/pm-startup` correctly flagged it) and not a hard breakage.

**F-G (proposed) — Solution leakage in PM-chat-generated prompts.** Section: Supplementary findings (Phase 28 + Phase 32 paraphrased coder-prompt walk-throughs). Defect: the v10 prompt-template structure (BD-049 labeled-section convention) ships a strong scaffold, and the PM chat applies it well — but the generated prompts cross from "format/scope/constraints" into "solution territory" in several places. Examples observed (paraphrased; no OT body content):

| Phase | Leakage | Why it's a solution leak |
|---|---|---|
| Phase 28 (logging) | "must be injectable as a parameter (`maxFileSizeBytes`) so tests can drive rotation with small payloads" | Specifies a testability technique (parameter injection). The plan only required testable rotation; the coder should choose between parameter injection / overridable static / test seam protocol / etc. |
| Phase 28 (logging) | "Justify the actor-vs-queue choice in a brief comment at the type's declaration" | Implementation guidance about commenting that goes beyond the plan. |
| Phase 28 (logging) | `@unchecked Sendable` justification template specifying the safety argument verbatim | Pre-makes the reasoning that the coder should be making themselves. |
| Phase 32 (debug panel) | "via `WindowGroup` or `Window`, whichever is consistent with how the existing app declares scenes" | Names specific SwiftUI APIs. |
| Phase 32 (debug panel) | "DebugStateProvider is a protocol that returns a `DebugStateSnapshot` value type … snapshot has nested value types covering: …" | Specifies architectural shape (protocol return type, nested value-type composition). The plan only required the panel content sections; protocol+snapshot+nested-value-types is PM-chat invention. |
| Phase 32 (debug panel) | "polls the `DebugStateProvider` on a 1 Hz timer" | Specific polling rate. |
| Phase 32 (debug panel) | "suspend the timer when the window is not visible" | Lifecycle behavior choice. |
| Phase 32 (debug panel) | "section headers and monospaced value rendering where appropriate" | Presentation choice. |

**Files-in-scope is NOT solution leakage** (clarification — this is a recurring point of confusion worth recording explicitly): the prompt's "Files-in-scope" list relays file paths from `IMPLEMENTATION_PLAN.md`, which is the architect/planner's upstream output. File paths are scope/location guardrails (telling the coder where the work goes and where it does NOT go), not implementation choices. Saying "the new file lives in `Data/Logging/`" enforces an existing project layer-discipline rule, not a design decision. A genuine same-family solution leak would be specifying which API or data structure to use (e.g., "use `FileManager.default.url(for:in:)` to resolve the path" or "buffer entries in a `Deque<String>`") — those would cross into solution territory. The architectural chain is: `ARCHITECTURE.md` → `IMPLEMENTATION_PLAN.md` → PM chat coder prompt (relays plan's scope + project conventions; does NOT invent) → coder agent (chooses APIs / patterns / data structures).

**Action:** file as new BD-NNN at C-V10-18 BACKLOG sweep. **Recommended fix scope: v10.0 patch (low risk, high value)** — `supporting-docs/METHODOLOGY.md § Prompt Authoring Principles` already touches the format-vs-solutions distinction but apparently not in a way the prompt-generating PM chat fully internalizes. Add a sharper subsection: "Format-vs-solutions: worked examples." Cover (a) what counts as scope/constraint (file paths from plan, test requirements, `Sendable` declaration, success-criteria thresholds), (b) what counts as solution (specific APIs, data structures, polling rates, lifecycle behaviors, algorithmic choices), and (c) the rationale that solutions belong to the coder agent's judgment, not the PM chat's. Project lead decides at Gate F. Note: F-G is somewhat ironic — the F-G fix is itself an exercise in writing format-not-solution guidance.
