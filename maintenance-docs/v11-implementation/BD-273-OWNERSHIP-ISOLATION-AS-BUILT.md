# BD-273 — sub-agent ownership / deletion boundary, AS BUILT (pack-side)

**Scope.** A factual, consolidated description of the pack-side BD-273
deletion-boundary mechanism and its Claude-only mechanical enforcement, exactly as
committed across the BD-273 waves (the hook body + wiring + unit test + installer
tuple landed in P1 at `1e9a11b`; the readiness canaries + this runbook/as-built
land in P2). Every claim is grounded in the committed code, not the design docs;
where a design doc and the code differ, the code is authoritative (divergences are
called out inline).

**What this doc is NOT.** It carries no project-side (BD-274) design and no "how to
adapt it" recommendation. It describes the PACK side only. Consumers: (1) a
project-side (BD-274) adapter designer, who builds a separate client design from
this; (2) a source for updating user-facing docs so pack users know what is
installed and used.

**As-built surface (files this doc describes, by path — never line number):**

| Surface | Path | Role |
|---|---|---|
| Deletion-boundary hook | `scripts/hooks/deletion-boundary.py` | PreToolUse[Bash] sub-agent deletion deny-hook |
| Auto-wire | `.claude/settings.json` (pack-root, tracked) | wires the hook as its OWN Bash-matcher element |
| Installer | `scripts/install-modes-hook.sh` (3rd HOOKS tuple) | heal / opt-out / status stopgap (NOT primary install) |
| Unit test | `scripts/tests/test-deletion-boundary.sh` | decision-matrix unit test (disk-glob wired) |
| Owned-dirs registry | `${XDG_STATE_HOME:-$HOME/.local/state}/optiquity-pack-handoff/.pack-agent-owned-dirs.jsonl` | `{agent_id, owned_dir}` append-only ownership ledger (orchestrator-written, hook-read) |
| Readiness canary | `.claude/skills/pack-startup/SKILL.md` §6, `.claude/skills/pack-refresh/SKILL.md` §2b | function canary + wiring probe |
| Runbook | `pack-ops/OPTIONAL-FEATURES.md` § "modes-enforcement hooks (auto-wired)" → Hook 3 | opt-in user-facing runbook (honest residuals) |
| Rule SSOT | trinity `## Pack memory` `per-action-approval-sub-agents` + `pack-ops/PACK-MEMORY-RATIONALE.md` | the unconditional rule the hook backstops (lands in P3) |

---

## 1. Overview — the incident class and the two-layer control

BD-273 addresses one accident class: a spawned sub-agent, told to clean up "its
scratch," runs a broad top-level `rm -rf` (or a `mv`/`find -delete`/`git rm`) whose
literal target resolves OUTSIDE its owned scratch dir — sweeping a SIBLING agent's
handoff dir, a shared scratch root, or the working tree.

The control is TWO layers, soft-to-hard:

1. **The unconditional rule (primary, cross-CLI).** `per-action-approval-sub-agents`
   in the trinity `## Pack memory` (with its `PACK-MEMORY-RATIONALE.md` body):
   every spawned agent OWNS one work dir (its assigned handoff/scratch dir), writes
   all output there, and deletes or destructively overwrites NOTHING outside that
   dir + the OS temp roots. This is the GUARANTEE. (Rule text lands in wave P3.)

2. **The deletion-boundary hook (defense-in-depth, Claude-only).** A third
   `PreToolUse[Bash]` hook, `scripts/hooks/deletion-boundary.py`, that mechanically
   DENIES the common direct verb-head literal delete when the target resolves
   out-of-bounds. It is BEST-EFFORT for REGISTERED spawns, NOT a guarantee — it
   narrows the accident window; the rule closes it.

The hook is a sibling of the two BD-224 modes-enforcement hooks
(`modes-enforce.py`, `modes-commit-gate.py`) and follows the identical house
discipline (FAIL-OPEN, never `exit 2`, deny via JSON `permissionDecision`,
`# pack-internal: true`, in no install map, ships to no client, Claude-only) — but
it is NOT a modes hook: it reads NO `session-config.json`, because the deletion
boundary is a universal invariant, not a tunable mode.

---

## 2. The probe (GO) and the feasibility rationale

A `PreToolUse[Bash]` hook fires for a spawned sub-agent's Bash tool call, and the
payload carries `agent_id` populated only for a sub-agent (absent on the main
thread). A non-gating measurement found NO agent-readable self-id in the
environment (`env | grep -i agent` surfaced only `AI_AGENT` +
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` — "not FOUND", not "proven absent by every
channel"). The payload fields the hook relies on: `tool_name`,
`tool_input.command`, `agent_id`, `cwd`. The spawn `name` is NOT in the payload
(this drove the registry decision, §4).

The probe returned GO; the hook SHIPS, Claude-only. Per
`operating-docs-no-history-no-bloat`, this GO/NO-GO narration lives ONLY here in the
as-built — the shipped rule / rationale / runbook carry none of it.

---

## 3. The parser + path-scope decision tree (as coded)

`scripts/hooks/deletion-boundary.py` reuses the proven quote-aware `_split_segments`
matcher from `modes-commit-gate.py` verbatim (so `echo "rm -rf /"` and
`git log --grep="rm -rf"` never expose a spurious verb) and adds an operator-aware
superset (`_split_with_ops` / `_pipelines`) needed only to group a
`find <literal> | xargs <core>` pipeline. Per segment (`_segment_targets`):

1. **Tokenize** (`_tokenize`: `shlex.split`; naive whitespace split on an unbalanced
   quote → fail-open).
2. **Clean** (`_clean` → `_strip_redirects` then `_strip_leading`): drop
   redirection noise (so `rmdir x 2>/dev/null` never treats `2>/dev/null` as a
   target); strip leading `VAR=value` env-assignments and `command`/`builtin`
   wrappers as the shell does; `_verb_of` strips a leading `\` and takes the
   basename (`/bin/rm` → `rm`).
3. **Dispatch on the verb:**
   - CORE destroy verbs `_CORE_VERBS = {rm, rmdir, unlink, shred, truncate}` →
     `_positional_targets` (skips option+value pairs for `shred`/`truncate`).
   - `mv` → `_mv_sources` (all positionals except the destination; `-t`/`--target-directory`
     makes ALL positionals sources).
   - `git` … `rm` → `_git_rm_targets` (also git-banned; double cover).
   - `find` → `_find_roots` when `_find_expr_deletes` (a `-delete` or
     `-exec`/`-execdir <core>`) is present.
   - `find <literal> | … | xargs <core>` (`_find_xargs_targets`, same-pipeline only)
     → the find-roots are targets.
   - `bash`/`sh`/`zsh`/`dash`/`ksh -c '<script>'` → recurse ONCE (`depth >= 1` →
     fail-open on deeper nesting).
   - anything else → ALLOW.
4. **Extract + classify each target** (`_resolve_target`): resolve `~`→`$HOME`; take
   the literal directory PREFIX before the first glob metachar (`* ? [ {`) via
   `_glob_prefix`; resolve a relative path against payload `cwd` (absent `cwd` →
   fail-open ALLOW). An UNRESOLVABLE target (`$VAR`/`${VAR}`, `$(…)`/backticks,
   redirect char, or a fully-glob with an EMPTY literal prefix) → ALLOW (fail-open).
5. **Normalize before compare:** `os.path.normpath` on the resolved target AND on
   every owned_dir / temp-root candidate (collapses `..` so `/tmp/../Users/…` is not
   mis-classed as temp). `realpath` is NOT used (the target may not exist; a
   symlink-escape is a stated residual).
6. **Decision** (`_first_out_of_bounds`, fail-open toward ALLOW at every
   uncertainty): a target UNDER the firing agent's `owned_dir` → ALLOW; UNDER an OS
   temp root → ALLOW; a literal resolving ANYWHERE ELSE → DENY (`_deny`).

---

## 4. The registry (MUST-2 decision, decided against a hook-computed formula)

The hook sees only `{agent_id, cwd}` for identity — NOT the spawn `name`, NOT the
handoff dir. The owned/handoff dir is chosen by the orchestrator BEFORE the spawn
(it must be in the initial prompt) and is keyed on `<bd>-<ts>`/the spawn name, NOT
on `agent_id` (assigned POST-spawn). Under background spawning the agent runs
concurrently the instant the tool returns.

Two formula variants were evaluated and REJECTED:

- **Plain formula** (`owned_dir = f(agent_id)`, agent writes there) — NOT VIABLE:
  `agent_id` is unknown at prompt-build time, so the orchestrator cannot inject that
  path pre-spawn; and an `agent_id`-keyed owned dir would break the per-cycle
  handoff sharing (coder→reviewer→fix-coder read the SAME dir).
- **Symlink-formula variant** — REJECTED on FAIL-OPEN: a missing symlink would
  wrongly DENY the agent's legit in-handoff-dir cleanup (a wedge in every clone),
  violating the cardinal fail-open discipline.

**DECISION: the REGISTRY** (best-effort, fail-open-safe). Because the hook is
defense-in-depth behind an unconditional rule and the non-negotiable is fail-open,
a best-effort hook that NEVER wrongly denies beats a guaranteed hook that CAN wedge
legit work. Mechanics as coded (`_registry_candidates` / `_owned_dir`):

- The orchestrator records `{agent_id, owned_dir}` to the owned-dirs ledger
  `${XDG_STATE_HOME:-$HOME/.local/state}/optiquity-pack-handoff/.pack-agent-owned-dirs.jsonl`
  in the SAME post-spawn action as the existing per-clone spawn record (one habit,
  not two — the mandate lands in wave P3 / `PACK-CHAT.md`). The ledger is
  append-only, per-machine, worktree-visible, never committed.
- Lookup is LAST-match-wins by `agent_id` (a re-used id resolves to the most recent
  line). A registry MISS / absent / unreadable → fail-open ALLOW (a coverage gap,
  never a wrong deny — the unconditional rule covers the unregistered spawn).
- Path resolution honors the `DELBOUND_REGISTRY_FILE` seam; else checks
  `$XDG_STATE_HOME/…` (if set) then `$HOME/.local/state/…` (the two-candidate check
  covers `XDG_STATE_HOME` set in one env but not the other).

The registry co-locates under BD-248's single canonical handoff root
(`${XDG_STATE_HOME:-$HOME/.local/state}/optiquity-pack-handoff/`); BD-248 is
UNCHANGED. It lives OUTSIDE any worktree, so it is inherently never-committed AND
visible to a hook firing in an isolated worktree.

---

## 5. Fail-open branches, deny schema, seams

FAIL-OPEN toward ALLOW on EVERY uncertainty (`main`): unparseable payload; a
`tool_name` other than `Bash`; missing `agent_id` (main thread → not a tracked
sub-agent → ALLOW); registry unreadable/absent/miss; empty command; target
unresolvable; `cwd` absent for a relative target; any exception. The body NEVER
`exit 2`. The deny fires ONLY on the fully-resolved conjunction {sub-agent
`agent_id` present + registry hit + CORE verb (or mv-source / find-root / git rm) +
LITERAL target resolving outside {owned_dir, temp roots}}.

Deny schema (`_deny`, compact `separators=(",",":")` so `"permissionDecision":"deny"`
is a literal substring, matching the canary + unit test):

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Delete target <path> is outside your owned scratch dir (<owned_dir>) and outside the OS temp roots. Agents delete nothing outside their owned dir; surface it — the orchestrator/harness handles cleanup."}}
```

Test seams (mirror `modes-commit-gate.py`'s `MODES_GATE_*`; production leaves both
unset):
- `DELBOUND_REGISTRY_FILE` — override the owned-dirs registry path (inject a scratch
  registry).
- `DELBOUND_TEMP_ROOTS` — override the OS-temp-root allowlist (colon-separated) for
  deterministic tests independent of the runner's `$TMPDIR`.

Default OS temp roots (`_DEFAULT_TEMP_ROOTS` + `$TMPDIR` if set): `/tmp`,
`/private/tmp`, `/var/folders`, `/private/var/folders`.

---

## 6. Wiring, installer, unit test, readiness canary (realized consumers)

- **Wiring.** `deletion-boundary.py` is its OWN `Bash`-matcher array ELEMENT in the
  tracked pack-root `.claude/settings.json` (NOT appended into the commit-gate
  entry's hooks array — matches the installer's one-element-per-hook model and
  Claude's "all matching Bash entries run; any deny blocks"). commit-gate +
  deletion-boundary coexist with no ordering dependency.
- **Installer.** `scripts/install-modes-hook.sh` carries a THIRD `HOOKS` tuple
  `("deletion-boundary", "Bash", "scripts/hooks/deletion-boundary.py",
  "$CLAUDE_PROJECT_DIR/scripts/hooks/deletion-boundary.py")`; merge / uninstall /
  dedup / status became three-hook-aware mechanically (the loop is data-driven).
- **Unit test.** `scripts/tests/test-deletion-boundary.sh` drives the decision
  matrix (incident deny; owned/temp/variable/miss allow; env-prefix / find|xargs /
  mv-source / `command`/`\rm` / git-rm / `..`-normalize / `bash -c` one-peek; the
  fail-open branches). Wired by the existing disk-glob test matrix.
- **Readiness canary (the realized consumer of the wiring).**
  `.claude/skills/pack-startup/SKILL.md` §6 and `.claude/skills/pack-refresh/SKILL.md`
  §2b grep the tracked `.claude/settings.json` for `deletion-boundary.py` and drive
  the wired body through its `DELBOUND_REGISTRY_FILE` + `DELBOUND_TEMP_ROOTS` seams
  (a synthetic registry + synthetic temp root): a subagent-tagged out-of-owned `rm`
  payload must emit `"permissionDecision":"deny"`; an under-owned / synthetic-temp /
  unresolvable-variable payload must be silent. The result reports on the
  `**Modes enforce:**` readiness line as `deletion-boundary self-test PASS/FAIL`.
  Local-only, never-fail, no committed CI sentinel — the canary is the
  did-it-actually-fire (`declare-verify-backing`) signal.

---

## 7. Honest residuals (best-effort, not a guarantee)

Stated in the runbook (`pack-ops/OPTIONAL-FEATURES.md`) and here; deliberately NOT
in the rule/rationale. The hook matches only the common direct verb-head literal
form; these shapes slip (fail-open false-NEGATIVES):

- variable-assembled literals (`D=$HOME/x; rm -rf "$D/bd-*"` — `$D` unresolvable → ALLOW);
- `bash -c` nesting beyond the one peeked layer;
- command-substitution targets (`rm -rf $(cat list)`);
- `xargs` fed by a non-`find` source (`echo /p | xargs rm`);
- exotic verbs outside the CORE set;
- a literal mis-extracted from brace / parameter expansion;
- a fully-glob target with NO literal directory prefix (`rm -rf *` → `_glob_prefix`
  returns an empty prefix → unresolvable → ALLOW). A glob WITH a literal prefix
  (`rm -rf /out/dir/*`) IS evaluated (prefix `/out/dir` → deny if out-of-bounds);
- a symlink-escape (target normpath'd, not realpath'd).

Coverage residual: a registry MISS (the orchestrator did not record this spawn's
owned-dir before its first delete) → that spawn is unprotected → the unconditional
rule is the guarantee. `mv`-destination overwrite, redirect-overwrite, `dd`, and
`cp`-over are NOT in the v1 deny-set (runbook residuals).

---

## 8. Reconciliation chain (architect-doc ↔ reality)

- **In-code docstring** — `scripts/hooks/deletion-boundary.py` header names the
  registry, the seams, the fail-open discipline, and the v1 deny-set.
- **Design doc** — `recon-bd273-20260726/RECONCILED-OWNERSHIP-ARCH.md` §4
  (parser/registry/wiring/canary), §5 (rule text). This as-built is the reality
  reconciliation of that design.
- **Realized consumers** — the wiring (`.claude/settings.json`), the installer tuple
  (`scripts/install-modes-hook.sh`), the unit test
  (`scripts/tests/test-deletion-boundary.sh`), and the readiness canaries
  (`.claude/skills/pack-startup/SKILL.md` §6, `.claude/skills/pack-refresh/SKILL.md`
  §2b) — all named by path (never line number, which drifts).
