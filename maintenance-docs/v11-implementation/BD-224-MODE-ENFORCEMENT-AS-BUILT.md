# BD-224 — mode + enforcement mechanisms, AS BUILT (pack-side)

**Scope.** A factual, consolidated description of the pack-side BD-224 operating-mode
system and its Claude-only mechanical enforcement, exactly as committed at
`c32e972`. Every claim is grounded in the committed code, not the design docs;
where a design doc and the code differ, the code is authoritative (divergences
are called out inline).

**What this doc is NOT.** It carries no project-side design and no "how to adapt
it" recommendation. It describes the PACK side only. Consumers: (1) a project-side
adapter designer, who builds a separate project design from this; (2) a source
for updating user-facing docs so pack users know what is installed and used.

**As-built surface (files this doc describes):**

| Surface | Path | Role |
|---|---|---|
| Isolation hook | `scripts/hooks/modes-enforce.py` | PreToolUse[Agent] isolation deny-hook |
| Commit-gate hook | `scripts/hooks/modes-commit-gate.py` | PreToolUse[Bash] intervention commit-gate |
| Auto-wire | `.claude/settings.json` (pack-root, tracked) | wires both hooks natively at session start |
| Installer | `scripts/install-modes-hook.sh` | heal / opt-out / status stopgap (NOT primary install) |
| Config | `pack-ops/session-config.json` (gitignored, per-clone) | the three mode fields |
| Token | `pack-ops/.commit-approval-token` (gitignored, per-clone) | single-use commit-approval token |
| Selectors | `.claude/skills/pack-{review,intervention,isolation}-mode/SKILL.md` | write the config |
| Behavior SSOT | `pack-ops/OPERATING-MODES.md` | the mode-behavior source of truth |
| Health/heal | `.claude/skills/pack-startup/SKILL.md` §6, `.claude/skills/pack-refresh/SKILL.md` §2b | canary + wiring probe |
| Token-write rule | `pack-ops/PACK-CHAT.md` (commit procedure) | who writes the token, when |
| Runbook | `pack-ops/OPTIONAL-FEATURES.md` § "modes-enforcement hooks" | opt-in user-facing runbook |

---

## 1. Overview — three modes, four layers

BD-224 defines **three independent operating-mode families**, each a single string
field with a default (`pack-ops/OPERATING-MODES.md` § "The three families"):

| Family | Field | Values | Default |
|---|---|---|---|
| Review | `review_mode` | `itemized`, `full`, `hybrid`, `none` | `itemized` |
| Intervention | `intervention_mode` | `full`, `pre-coder`, `ambiguity`, `none` | `full` |
| Isolation | `isolation_mode` | `read-write-only`, `full` | `read-write-only` (Claude-only) |

- **Review mode** governs how the user is asked to respond to the open items agents
  surface in reports.
- **Intervention mode** governs the pause/surface gates (commit-approval,
  reviewer-triage, planner-to-coder, design-review).
- **Isolation mode** governs which agent classes spawn into an isolated worktree
  (Claude-only, because worktree isolation is Claude-only).

The system is **four layers**, from soft to hard:

1. **Config** — `pack-ops/session-config.json` holds the three fields (per-clone,
   gitignored).
2. **Selection** — three slash-command selectors write the config.
3. **Salience** — each selector echoes the selected value's behavior text
   (read from the SSOT, "Design A"); `/pack-refresh` re-echoes it mid-session.
4. **Mechanical enforcement** — two Claude-only `PreToolUse` hooks backstop
   `isolation_mode` (at the spawn) and `intervention_mode`'s commit-approval gate
   (at `git commit`). The other gates and all of `review_mode` have no tool call
   to intercept and stay salience-only.

The defaults (`itemized` / `full` / `read-write-only`) equal pre-BD-224 Pack-Chat
behavior, so an unset config behaves exactly as before.

---

## 2. The mode-config system

### 2.1 `pack-ops/session-config.json`

Schema `pack-session-config/1`; three string fields, each defaulted
(`OPERATING-MODES.md` § "The config"):

```json
{
  "schema": "pack-session-config/1",
  "review_mode": "itemized",
  "intervention_mode": "full",
  "isolation_mode": "read-write-only"
}
```

- **Per-clone, gitignored** — `.gitignore` line 22 `pack-ops/session-config.json`
  ("Per-clone runtime mode selections; orchestrator-read-only. Never committed").
  It is a sibling of the committed `pack-ops/session-state.json`; only this config
  is local.
- **Orchestrator-read-only** — read only by Pack Chat, never by spawned agents, so
  its absence in an isolated worktree is harmless by construction.
- **Missing / absent / malformed ⇒ family defaults** — never an error, never a
  random value. Because it is not git-tracked, no CI check validates its content;
  the orchestrator validates at read time.
- **Read-at-point-of-use** — the mode is re-read at each decision, never a
  session-start-cached value (`OPERATING-MODES.md` § "Reading the config"). The
  canonical read idiom resolves the path from `git rev-parse --show-toplevel` and
  folds absent/malformed/unreachable to the default.

### 2.2 The three selector slash-commands

`.claude/skills/pack-review-mode`, `.claude/skills/pack-intervention-mode`,
`.claude/skills/pack-isolation-mode` — each a Pack-Chat-only selector with
`allowed-tools: Bash`. Each:

1. Presents its family's values (via `AskUserQuestion` on Claude; a numbered text
   menu on a CLI without that chooser).
2. Writes the chosen value into `pack-ops/session-config.json` in the current
   worktree, via the show-toplevel idiom; a missing file is created with all
   defaults plus the change. The write uses `cfg.setdefault(...)` for `schema` and
   all three fields, then overwrites the one field it owns.
3. Confirms the new active mode (§2.3).

**The `none ↔ none` coupling** (`OPERATING-MODES.md` § "Coupling"): the
intervention and review selectors write the paired field when `none` is chosen —
`pack-intervention-mode` sets `cfg["review_mode"] = "none"` on a `none` choice, and
`pack-review-mode` sets `cfg["intervention_mode"] = "none"`. Both first show an
explicit risk warning and require explicit confirmation. `pack-isolation-mode` has
no `none` value and no coupling. The two `none` states are always paired so an
unreviewed finding auto-applied under one family cannot land while the other still
gates. `none` intervention authorizes Pack-Chat auto-commit (never auto-push; agents
never commit).

### 2.3 `OPERATING-MODES.md` as behavior SSOT + Design A (read-not-copy)

`pack-ops/OPERATING-MODES.md` is the self-contained SSOT for the three families'
behavior. **Design A**: each selector's Confirm step READS the relevant
`### <Family> mode` section of `OPERATING-MODES.md` and echoes the selected value's
Behavior entry back to the user — it does NOT duplicate the behavior text into the
skill. This puts the active mode semantics into context without a second copy that
could drift. Each selector then points to `/pack-help` for the per-mode detail.

---

## 3. The enforcement layer

Two Claude-only `PreToolUse` hooks. Both live in `scripts/hooks/`, both carry a
`# pack-internal: true` header, both ship to no client and are in no install map
(dependency-direction: pack-ops-only). Both re-read the config at the instant of
the tool call. Both are FAIL-OPEN and NEVER exit 2 — a `deny` is expressed only via
the JSON `permissionDecision`, never the exit code.

### 3.1 `modes-enforce.py` — isolation deny-hook (PreToolUse[Agent])

Contract as built (`scripts/hooks/modes-enforce.py`):

- **Agent-class map** (the exact sets, lines 35-41):
  - `_RW_CLASSES = frozenset({"pack-coder"})` (a fix-coder is a `pack-coder`
    instance).
  - `_RO_CLASSES = frozenset({"pack-reviewer", "pack-architect", "pack-planner",
    "pack-docs-researcher"})`.
  - Any other `subagent_type` classifies as `UNKNOWN`.
- **Mode resolution** (`_resolve_mode`): `git -C <cwd> rev-parse --show-toplevel` →
  `<root>/pack-ops/session-config.json` → `.get("isolation_mode", "read-write-only")`.
  Empty root / non-git / absent / unreadable / malformed / non-string all fold to
  the default `read-write-only`.
- **Must-isolate-only** (`_must_isolate`): `full` requires isolation for both RW
  and RO; `read-write-only` requires it for RW only; any other mode requires
  nothing. It denies ONLY an UNDER-isolated spawn (should isolate but did not); it
  never denies an over-isolated spawn, so it stays compatible with an all-isolated
  posture.
- **Decision** (`main`): parse stdin (unparseable → allow); `tool_name != "Agent"`
  → allow; `UNKNOWN` class → allow; compute `iso_present = tool_input.get("isolation")
  == "worktree"`; if `_must_isolate(mode, cls)` and not `iso_present` → DENY; any
  exception → allow.
- **Deny schema** (compact separators so the substring `"permissionDecision":"deny"`
  is literally present — matched by the canary + the unit test):
  ```json
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<cls> spawn under isolation_mode=<mode> must set isolation:\"worktree\"; re-spawn with the isolation parameter"}}
  ```
- **INTENT not OUTCOME**: it enforces that the correct `isolation:"worktree"`
  parameter was PASSED — not whether isolation actually took effect. The outcome
  signal remains the agent's own runtime pwd/HEAD self-detect.

### 3.2 `modes-commit-gate.py` — intervention commit-gate (PreToolUse[Bash])

Contract as built (`scripts/hooks/modes-commit-gate.py`):

- **Enforce set** (line 65): `_ENFORCE_MODES = frozenset({"full", "pre-coder",
  "ambiguity"})` — the three non-`none` intervention values that keep the
  commit-approval gate. `none` authorizes auto-commit → allow. Any
  other/absent/malformed value → allow (INERT).
- **git-commit matcher** (`_is_git_commit` + `_split_segments` +
  `_segment_is_git_commit`): QUOTE-AWARE. `_split_segments` splits the command on
  top-level `&&`, `||`, `;`, `|`, newline but NOT operators inside single/double
  quotes (so `git log --grep="&& git commit"` cannot expose a spurious bare
  `git commit`). `_segment_is_git_commit` finds a `git` (or `.../git`) token, skips
  global option+value pairs (`_GIT_VALUE_OPTS = {-C, -c, --git-dir, --work-tree,
  --namespace, --exec-path, --super-prefix}`) and lone flags, and returns true iff
  the first non-option token is `commit`. Conservative + fail-open toward allow:
  under-splitting is safe; an unparseable segment falls back to a naive whitespace
  split; any surprise → the caller's try/except → allow.
- **Intervention resolution** (`_resolve_intervention`): reads `intervention_mode`
  from the session-config; returns `None` on ANY failure (path unresolvable / absent
  / unreadable / non-JSON / non-string). `None` → allow (inert). This is deliberately
  MORE lenient than the isolation hook's fold-to-default — a commit-gate denial would
  wedge the human's own commits.
- **Token check** (`_evaluate_token`) — three decisions:
  - `allow-consume` — a token within TTL (fresh; a future-dated token counts fresh,
    harmless clock-jitter tolerance) → allow AND delete the token (single-use).
  - `deny` — a clean no/expired signal: token ABSENT, or present-and-valid but STALE.
    This is the enforcement path.
  - `allow` — the hook cannot read the signal through no fault of the committer
    (path unresolvable, unreadable, parse error, non-numeric `approved_at`) →
    fail-open.
- **Decision** (`main`): parse stdin (unparseable → allow); `tool_name != "Bash"` →
  allow; not a git-commit → allow; mode not in `_ENFORCE_MODES` → allow (inert);
  `allow-consume` → delete token + allow; `allow` → allow; else DENY. Any exception →
  allow.
- **Deny schema** (`_deny`, compact separators):
  ```json
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"intervention_mode=<m> requires a fresh approved-commit token (pack-ops/.commit-approval-token); none present/fresh. Obtain user approval (which writes the token) before committing."}}
  ```
- **FAIL-OPEN HARDER than the isolation hook**: because this hook is auto-wired in
  every pack-dev clone, a wrongful deny would wedge the human's own commits, so every
  uncertain branch errs to allow; the deny fires ONLY on a fully-resolved
  {Bash + git commit + cleanly-parsed enforce-mode + no fresh token}.
- **RITUAL not SEMANTICS**: it enforces that a fresh token EXISTS per commit — it
  cannot verify the user truly approved (the token is a self-attested proxy).
- **Test seams** (production leaves all unset): `MODES_GATE_CONFIG_FILE`,
  `MODES_GATE_TOKEN_FILE`, `MODES_GATE_NOW` (deterministic clock; malformed →
  real clock).

### 3.3 The token lifecycle

`pack-ops/.commit-approval-token` — gitignored (`.gitignore` line 25), per-clone,
transient runtime state.

- **Content**: JSON `{"approved_at": <epoch_seconds>}`.
- **TTL**: `_TTL_SECONDS = 120` (a single tunable constant in the gate body). A
  token older than 120s is stale → deny.
- **Single-use**: consumed (deleted) by the hook on the allow path — one approval
  authorizes one commit. Deleting a per-clone runtime file is the hook's own
  bookkeeping, NOT a git verb (`agents-never-commit` untouched).
- **Who writes it** (`pack-ops/PACK-CHAT.md` commit procedure, "Write the commit-
  approval token before committing (Claude-only)"): when the active
  `intervention_mode` is not `none`, the LAST step of processing the user's commit
  approval — after they say yes, immediately before the pathspec `git commit` — Pack
  Chat writes the token:
  ```bash
  python3 -c 'import json,time,sys; open(sys.argv[1],"w").write(json.dumps({"approved_at":int(time.time())}))' "$(git rev-parse --show-toplevel)/pack-ops/.commit-approval-token"
  ```
  It is a SEPARATE step because the hook fires pre-execution — the token must exist
  before the `git commit` tool call runs. Under `intervention_mode: none`
  (auto-commit) no token is written.
- **Consume-before-run edge**: consume happens in `PreToolUse` (before the commit
  runs), so a commit that then FAILS (nothing staged) has already spent its token →
  re-approve. This errs toward requiring approval (the fail-safe direction).

---

## 4. Auto-install (as built)

The auto-wire is **declarative committed wiring**, not a self-running installer.

- **`.claude/settings.json` at pack root (tracked)** wires BOTH `PreToolUse` hooks
  via `$CLAUDE_PROJECT_DIR` (resolves the body path per-clone regardless of session
  cwd):
  ```json
  {
    "hooks": {
      "PreToolUse": [
        { "matcher": "Agent", "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/scripts/hooks/modes-enforce.py" } ] },
        { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/scripts/hooks/modes-commit-gate.py" } ] }
      ]
    }
  }
  ```
  It carries ONLY the hooks (no `permissions` key), so a user's
  `.claude/settings.local.json` `permissions` merge on top and is never clobbered.
- **Applied natively at session start** — Claude Code reads project `settings.json`
  and applies its hooks with no install step and no run-mechanism that can silently
  rot. The user's gitignored `.claude/settings.local.json` is NEVER auto-written.
- **One-time trust prompt** — on a fresh clone's first session Claude Code shows its
  native project-hooks trust prompt; until accepted the `/pack-startup` canary reports
  the hooks not active. This is a conscious per-clone opt-in, native safe behavior,
  not a defect.
- **Fires live, no restart** — in the landing session the committed
  `.claude/settings.json` fired live mid-session with no restart (SPIKE-B positive;
  see §7). Both hook bodies carry a `#!/usr/bin/env python3` shebang and are `+x`.
- **Re-scoped installer** — `scripts/install-modes-hook.sh` is NO LONGER the primary
  install path. It is the secondary heal / opt-out / status convenience, now aware of
  BOTH hooks:
  - default (install) — deep-merge BOTH hook entries into this clone's gitignored
    `.claude/settings.local.json` (a heal stopgap: a dev who removed the committed
    file or wants a local override). Idempotent, preserves every existing key.
  - `--uninstall` — remove BOTH modes entries from `settings.local.json` only.
  - `--dedup` — remove from `settings.local.json` ONLY the modes entries ALSO wired
    in the committed `.claude/settings.json` (the one-time migration for a clone that
    installed the isolation hook locally BEFORE the committed file landed — that local
    Agent entry would otherwise double-fire). A local-only override is preserved.
  - `--status` — report the MERGED per-hook reality across committed + local:
    `isolation: <committed+local|committed|local|none>` and `commit-gate: <...>`.
  - Install/uninstall/dedup MUTATE the live `.claude/settings.local.json`, so the
    orchestrator runs them with user approval — never a coder/sub-agent; `--status`
    is read-only. Test seams: `MODES_HOOK_SETTINGS_FILE`, `MODES_HOOK_COMMITTED_FILE`.

---

## 5. Health + self-heal

Verification is LOCAL only — there is NO CI gate and NO committed sentinel (§7,
the BD-237 lesson). Both surfaces use the same probe and NEVER fail/block the
session; each is Claude-only behind a runtime `CLAUDECODE` branch.

### 5.1 `/pack-startup` Step 6 — modes-enforce hook readiness

`.claude/skills/pack-startup/SKILL.md` § "Step 6 — Modes-enforce hook readiness"
computes the `**Modes enforce:**` line. It VERIFIES (does not install):

- **Wiring probe** — grep the tracked `.claude/settings.json` for BOTH hook body
  paths (`modes-enforce.py` and `modes-commit-gate.py`; deterministic, O(1)).
  Missing → `wiring MISSING — restore .claude/settings.json`.
- **Function canary per body** — a dry-run payload piped into each hook body,
  asserting the substring `"permissionDecision":"deny"`:
  - isolation: an `Agent` payload for `pack-coder` with no `isolation` param →
    must deny → `isolation self-test PASS`.
  - commit-gate: a `Bash` `git commit` payload driven through the body's
    `MODES_GATE_CONFIG_FILE` / `MODES_GATE_TOKEN_FILE` scratch seams under a forced
    `intervention_mode=full` with no token → must deny → `commit-gate self-test PASS`.
    Because it uses the seams, the canary touches NO live config or token.
- If the hook bodies are absent → `hook body absent (feature not built in this
  clone)`. Non-Claude CLI → `n/a (non-Claude CLI — isolation_mode + hooks are
  Claude-only; modes honored by orchestrator discipline)`.

It NEVER fails startup (reports absent / MISSING / self-test FAIL, does not error).
On MISSING wiring it points to restoring the tracked `.claude/settings.json`, with
`bash scripts/install-modes-hook.sh` (+`--dedup`) as the local heal stopgap.

### 5.2 `/pack-refresh` Step 2b — re-verify + offer-to-heal

`.claude/skills/pack-refresh/SKILL.md` § "Step 2b" re-heals mid-session,
report-only — it never fails, blocks, or writes settings:

1. **Re-echo behaviors** — re-echo the three active modes' behavior text from
   `OPERATING-MODES.md` (Design A), putting the live mode semantics back at the
   front of context (the drift the user means by "deteriorating").
2. **Re-run the function canary for BOTH hooks + verify committed wiring** — the
   same probe Step 6 uses (commit-gate canary via `MODES_GATE_*` scratch seams,
   touching no live config or token).
3. **On a fault → REPORT + OFFER, never auto-mutate**: a canary FAIL means a broken
   tracked body → the true fix is a git-level restore (a user action; the skill does
   not run a git verb). Wiring MISSING → report and point to restoring
   `.claude/settings.json`; MAY offer `bash scripts/install-modes-hook.sh` as a LOCAL
   stopgap, run only on explicit user OK (it mutates `.claude/`). Green → noted on the
   confirm line.

Both skills mirror the byte-identical `.claude` / `.codex` / `.agents` triplet; the
Claude-only logic sits behind the `CLAUDECODE` runtime branch, not an asymmetric edit.

---

## 6. What gets INSTALLED and what's USED

Enumerated for a user-facing surface — every artifact that ships/activates, what it
does at runtime, and what the user experiences.

| Artifact | Committed? | What it does at runtime |
|---|---|---|
| `.claude/settings.json` (pack root) | tracked | Read natively at session start; wires both `PreToolUse` hooks. THE auto-install. |
| `scripts/hooks/modes-enforce.py` | tracked | Fires on every sub-agent spawn; denies an under-isolated spawn when `isolation_mode` requires it. |
| `scripts/hooks/modes-commit-gate.py` | tracked | Fires on every `git commit` Bash call; denies when `intervention_mode` is non-`none` and no fresh token exists. |
| `.claude/skills/pack-{review,intervention,isolation}-mode/SKILL.md` | tracked | The `/pack-*-mode` selectors; write the config, echo the selected behavior. |
| `pack-ops/session-config.json` | gitignored, per-clone | Holds the three mode fields; created/updated by a selector; read by the orchestrator + both hooks. |
| `pack-ops/.commit-approval-token` | gitignored, per-clone | Written by Pack Chat at the approval gate (non-`none` intervention); consumed by the commit-gate. |
| `scripts/install-modes-hook.sh` | tracked | Heal / opt-out / status stopgap for the local settings file (secondary to the committed wiring). |
| `pack-ops/OPERATING-MODES.md` | tracked | Behavior SSOT the selectors + skills read. |
| `pack-ops/OPTIONAL-FEATURES.md` § modes-enforcement | tracked | The user-facing runbook (what/how/honest bounds). |
| `/pack-startup` §6 + `/pack-refresh` §2b | tracked | Local canary + wiring probe; the did-it-actually-fire signal. |

**What the user experiences:**

- **First session on a fresh clone** — Claude Code's one-time native project-hooks
  trust prompt (accept once to enable enforcement). Until accepted, the enforcement
  is inactive and `/pack-startup` reports it not active.
- **A denied spawn** — if the orchestrator spawns an RW agent without
  `isolation:"worktree"` under a must-isolate `isolation_mode`, the spawn is blocked
  with the isolation deny reason; the fix is to re-spawn with the parameter.
- **A denied commit** — under a non-`none` `intervention_mode`, a `git commit` with
  no fresh approval token is blocked with the commit-gate deny reason; the fix is to
  obtain user approval (which writes the token).
- **Mode echoes** — running a `/pack-*-mode` selector confirms the new value and
  echoes its behavior from `OPERATING-MODES.md`; `/pack-refresh` re-echoes all three
  and re-runs the canary.

---

## 7. Findings + constraints an adapter must respect

This section carries the honest bounds and the spike evidence — the most important
material for anyone building a client-facing adaptation.

### 7.1 The honest per-mode reality (what is and is NOT mechanically enforced)

| Mode / gate | Enforcement | Note |
|---|---|---|
| `isolation_mode` (Agent spawn) | Mechanically enforced at **INTENT** | Enforces the `isolation:"worktree"` parameter, not the isolation OUTCOME (the agent's pwd/HEAD self-detect stays the outcome backstop). |
| `intervention_mode` — commit-approval gate | Mechanically enforced at **RITUAL** | The token gate catches a ritual-skipping commit; it cannot verify the user truly approved (self-attested proxy). |
| `intervention_mode` — triage / planner-to-coder / design-review / ambiguity | **NEITHER** | Conversational gates; no tool call, no signal to intercept. |
| `review_mode` (all values) | **NEITHER** | Freeform chat presentation; no tool call. |

The commit-gate closes ONE of intervention's four gates at the ritual level. It does
NOT make intervention "enforced" and does nothing for `review_mode`. An adapter must
not overstate the coverage: only isolation (intent) and the commit-approval gate
(ritual) have a machine boundary; everything else is salience/discipline.

### 7.2 The spikes (measured, in-session, under auto-mode)

- **Isolation deny (OPEN-1 spike)** — a `PreToolUse` `deny` BLOCKS a sub-agent spawn
  AND survives auto-mode (auto-mode does not bypass a `PreToolUse` deny). The spawn
  tool reports `tool_name:"Agent"` (NOT `"Task"` — a `Task` matcher would miss every
  spawn); `isolation` + `subagent_type` are present in `tool_input`; hooks HOT-LOAD
  (fire on the next call, no restart) and hot-unload cleanly. The working deny schema
  is exactly the compact `{"hookSpecificOutput":{... "permissionDecision":"deny" ...}}`.
- **Commit deny (SPIKE-A)** — a `PreToolUse[Bash]` `deny` FIRES + BLOCKS a `git commit`
  AND survives auto-mode (a sentinel commit was blocked with the exact deny reason; the
  payload carried `permission_mode:"auto"` and `tool_input.command` verbatim).
- **`ask` is auto-answered under auto-mode (SPIKE-A)** — a `PreToolUse[Bash]`
  `permissionDecision:"ask"` is AUTO-ANSWERED (allowed) under auto-mode, so a stronger
  native-prompt gate is IMPOSSIBLE under auto-mode. This is why the commit-gate is a
  DENY-based token gate, not an `ask`-based native-prompt gate.
- **Committed settings fires live (SPIKE-B)** — the committed pack-root
  `.claude/settings.json` applied and its hooks fired live mid-session with no
  restart, confirming the declarative auto-install model.

### 7.3 FAIL-OPEN discipline

Both hooks NEVER exit 2; a `deny` is expressed only via the JSON `permissionDecision`.
Every uncertain branch (config absent/unreadable/malformed, git unavailable, ambiguous
parse, token parse error, unknown class, any exception) folds to ALLOW. The commit-gate
fails open HARDER (even a cleanly-parsed-but-unknown intervention value → allow) because
a wrongful deny would wedge the human's own commits in every auto-wired clone. An
internal error degrades to the pre-existing honor-system, never to a wedged session.

### 7.4 The BD-237 lesson

BD-237 recorded a prior hand-installed hook that shipped un-verified and silently never
ran (three failures: implemented wrong, reviewer missed it, no check verified it). The
remedy the user accepted was a LOCAL readiness/freshness check, and the user explicitly
REJECTED a CI sentinel. The load-bearing lesson: verification stays LOCAL, never a CI
gate/sentinel. BD-224 honors this — the committed-wiring model has no per-clone
run-mechanism to fail, and its verification lives LOCALLY on `/pack-startup` +
`/pack-refresh` (a function canary), NEVER a CI gate or committed sentinel;
`validate-pack` gains no new check for this feature.

### 7.5 Claude-only vs conceptually cross-CLI

An adapter must respect this split precisely:

- **Claude-only (mechanism)** — the two `PreToolUse` hooks, the committed
  `.claude/settings.json` auto-wire, the installer, and the whole `isolation_mode`
  family. Hooks + worktree isolation are Claude Code primitives; Codex / Antigravity
  have neither the hook mechanism nor an `isolation_mode` to enforce, and their commit
  flows are platform-native. The committed `.claude/settings.json` has no `.codex` /
  `.agents` sibling — correct, not an asymmetry defect. Do not "restore parity" by
  porting the hook wiring.
- **Cross-CLI (semantics)** — the `review_mode` and `intervention_mode` behaviors are
  orchestrator-discipline concepts that apply on any CLI; on a non-Claude CLI they are
  honored by orchestrator discipline with no mechanical backstop (the canary reports
  `n/a`).
- **Cross-CLI (config + selectors)** — `pack-ops/session-config.json` is CLI-agnostic,
  and the selectors present the same options as a numbered text menu on a CLI without
  `AskUserQuestion`. Only `isolation_mode` is Claude-only within the config.

---

## Appendix — code-vs-design divergence found

One stale in-code comment (does NOT affect behavior): `scripts/hooks/modes-enforce.py`
header lines 22-26 still describe the OLD wiring model — "wires it into the gitignored
per-clone `.claude/settings.local.json` with `scripts/install-modes-hook.sh`". The
as-built wiring is the tracked pack-root `.claude/settings.json` (§4), and the sibling
`scripts/hooks/modes-commit-gate.py` header (lines 39-42) correctly states "The
orchestrator wires it (with `modes-enforce.py`) via the tracked pack-root
`.claude/settings.json`." The isolation body's header was not updated when the
auto-wire model landed. Behavior is unaffected (the header is a comment); flagged here
for a future header reconciliation.

