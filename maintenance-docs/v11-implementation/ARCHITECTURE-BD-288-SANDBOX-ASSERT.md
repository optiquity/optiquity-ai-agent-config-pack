# ARCHITECTURE-BD-288-SANDBOX-ASSERT — two folded-in items

**Author:** `pack-architect`, spawn `architect-bd288-sandboxassert`.
**Date:** 2026-08-24.
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack`, branch `main`.
**HEAD at every measurement:** `e8ea69e`.
**Tool grant:** `Read, Grep, Glob, Bash` — no `Write` tool. This document was authored with Bash
heredocs into my own owned handoff dir. No repo file was written; no denied capability was routed
around. Every demonstration ran in a `mktemp -d` scratch copy or a `git archive` extraction — the
repo was never mutated.

**Scope.** Two items the user folded into BD-288 after `PLAN-BD-288-READY.md` was written. Neither
appears in that plan.

- **ITEM 1** — the Codex read-only sandbox grant is prose-bounded, not mechanically bounded.
- **ITEM 2** — a test-assertion idiom that does not assert what it appears to.

**Bottom line, stated first.** Both items are materially smaller than their framing, and the
evidence is decisive in both cases — but neither is empty, and each yields concrete work.

- **ITEM 1: the requested fix is mechanically impossible, and the surface it would have protected
  is inert.** `writable_roots` is *additive to* `cwd`, not a narrowing of it (EE-1), so no value of
  `writable_roots` can make `workspace-write` narrower than the whole workspace. Separately, the
  pack repo has no `.codex/config.toml`, and Codex loads agent roles only from an `[agents.<role>]
  registration, so the five pack `.codex/agents/*.toml` files are not loaded by Codex on this repo
  at all (EE-2, EE-3). What the investigation *did* surface is a live instance of BD-288's own
  defect class on the same files: `codex --agent pack-<name>`, documented in three pack operating-doc
  sites, is not a valid flag in the installed Codex and errors (EE-4). That is the real work here.
- **ITEM 2: the defect population is 2, not 51.** The defect can only exist in a check that has
  BOTH a `fail()` and a `warn()` leg; measured, that is **3 of 87** check functions (EE-6). At
  `e8ea69e` there were exactly **2** true instances, both in one test file (EE-7). W1 fixed one; the
  other is **still live and proven at runtime** (EE-8). A guard IS mechanically possible, costs
  ≤60 ms, and — measured — needs an **empty** allowlist (EE-9, EE-10). The naive form of that guard
  misses half the known population, which is itself the finding that decides the design (EE-9).

---

## 0. Position, and one load-bearing correction to the brief

### 0.1 The canonical tree changed under me mid-session

At my first measurement the working tree carried one modified file (`pack-ops/session-state.json`).
Roughly forty minutes later the same command reported four:

```
 M pack-ops/session-state.json
 M scripts/lib/validate_checks/cross_bd.py
 M scripts/tests/test-validate-pack-check-81.sh
 M scripts/tests/test-validate-pack-check-82.sh
```

**W1's patch landed in the canonical checkout while I was measuring.** HEAD did not move (`e8ea69e`
throughout) — the work is applied but uncommitted.

This matters for reading every number below. I therefore report ITEM 2's census against **both**
tree states, and I distinguish them explicitly:

| Label | Meaning | How I obtained it |
|---|---|---|
| **HEAD** | `e8ea69e` as committed, W1 **not** applied | `git archive HEAD \| tar -x -C $(mktemp -d)` — a pristine extraction, never the live tree |
| **WT** | the live working tree, W1 **applied** | measured in place |

I did not enter, read from, or write to either live agent worktree
(`.claude/worktrees/agent-a6993edf7db89c0dc`, `.claude/worktrees/agent-abc719f7e784a0d5e`).

### 0.2 A correction to the brief's ITEM 2 framing

The brief describes W1 as having fixed a clause and "then built a mutation specifically to prove the
clause now bites", and says "Both were fixed to a discriminating substring." Measured against the
actual W1 diff (EE-11), **W1 changed exactly one assertion clause**:

```
-if fc < 1 or "BD-901" not in cap or "active design" not in cap:
+if fc < 1 or "BD-901" not in cap or "is in active design (session-state" not in cap:
```

The other lines the diff adds are *new* test legs (T10 `BD-910` … `BD-915`) authored in the fixed
form, not repairs of existing ones. The pre-existing sibling clause is still there, unrepaired, and
is the live instance §3.3 quantifies. This is not a criticism of W1 — its scope was the Check-81
matcher — but the brief's "both were fixed" is the premise that would have led me to conclude the
population was already zero, and it is wrong.

### 0.3 What I did not verify, and why

I could not execute a real Codex sandbox. `codex sandbox` aborts with SIGABRT and no output under
this session's own macOS Seatbelt sandbox — nested `sandbox_init` fails — and it fails identically
for `/bin/echo`, so the failure is environmental, not configuration-dependent (EE-5). Every ITEM 1
claim below therefore rests on (a) the installed binary's own embedded strings, (b) the CLI's
argument parser, and (c) config-load behaviour — never on an observed sandbox enforcement. Where
that limit bites, I say so at the claim rather than carrying an unverified assertion forward.

---

# ITEM 1 — the Codex RO sandbox grant

## 1. The measured problem

### 1.1 What commit `e8ea69e` actually changed on the Codex side

Four `.codex/agents/*.toml` files (`pack-architect`, `pack-planner`, `pack-docs-researcher`,
`pack-reviewer`) now carry an identical ten-line comment above `sandbox_mode = "workspace-write"`:

```toml
approval_policy = "on-request"
# workspace-write grants in-workspace writes; it does NOT reach the
# caller-specified deliverable path, which lies outside the workspace and
# is written via the `approval_policy = "on-request"` escalation above.
# It does not narrow writes either — no pack-side .codex/config.toml sets
# `writable_roots`. The prose policy below is what restricts this agent to
# that one file.
sandbox_mode = "workspace-write"
```

The comment is honest about the *outcome*. It is wrong about the *mechanism*, in a way that matters
precisely because it is the sentence a future maintainer would act on: **"It does not narrow writes
either — no pack-side `.codex/config.toml` sets `writable_roots`"** reads as *the narrowing is
absent because nobody configured it*. That implication is false. See §1.2.

### 1.2 `writable_roots` is additive. It cannot narrow anything.

The installed Codex binary embeds the exact prose it sends the model to describe each sandbox mode.
For `workspace-write` (EE-1):

> Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is
> `workspace-write`: The sandbox permits reading files, and **editing files in `cwd` and
> `writable_roots`**. Editing files in other directories requires approval.

`cwd` **and** `writable_roots`. The workspace is writable under `workspace-write` unconditionally;
`writable_roots` only ever *adds* roots. The CLI's own flag help says the same thing in the
imperative — `--add-dir <DIR>`: *"Additional directories that should be writable alongside the
primary workspace"* (EE-1).

**Consequence: the item as posed has no solution in this mechanism.** There is no value of
`[sandbox_workspace_write] writable_roots` — in a project config, a per-agent TOML, or anywhere
else — that makes `workspace-write` narrower than the whole workspace. A prior reviewer flagged the
*placement* of `writable_roots` as unverified; the more basic problem is its *polarity*. Adding a
pack-side `.codex/config.toml` with a narrow `writable_roots` would not reduce the grant by one
byte. It would only widen it further.

The only mode that is genuinely narrow is `read-only`, which is what `e8ea69e` moved away from —
and it moved away for a real reason: those three agents must write one report.

### 1.3 The out-of-workspace deliverable, and the `$XDG_STATE_HOME` question

The handoff root is defined at `pack-ops/PACK-CHAT.md:350` as
`${XDG_STATE_HOME:-$HOME/.local/state}/optiquity-pack-handoff/<bd>-<ts>/`, and the same
environment-relative form appears at `pack-ops/PACK-CHAT.md:365`, `pack-ops/OPTIONAL-FEATURES.md:353`,
and `pack-ops/DASHBOARD-SPEC-PACK.md:373`. It is outside every workspace by construction.

A prior pass called the `$XDG_STATE_HOME` expansion "unsolved" and used that as the reason not to
attempt the fix. **That reason does not hold**, and I record it because it will otherwise be
inherited: Codex 0.145.0's filesystem-permission validator accepts tilde-relative paths explicitly.
Its own error message enumerates the accepted forms (EE-1):

> filesystem path `…` must be absolute, use `~/…`, or start with `:`

So `~/.local/state/optiquity-pack-handoff/**` is expressible in a committed config without
hardcoding a machine-specific absolute path. The `:`-prefixed forms are named special roots —
`minimal`, `project_roots`, `subpath`, `tmpdir`, `slash_tmp` (EE-1).

**But this does not rescue the item**, for two reasons:

1. The `~/…` form belongs to the **new** `[permissions.<profile>]` model (§1.5), not to
   `[sandbox_workspace_write] writable_roots`. It is a different mechanism.
2. The residual gap it would close — reaching an out-of-workspace path — is already closed
   operationally: `approval_policy = "on-request"` escalates, and empirically the RO agents that hit
   this wrote their reports anyway.

The honest statement is: **the `$XDG_STATE_HOME` problem is solvable and was never the blocker. The
blocker is that `writable_roots` narrows nothing.**

### 1.4 The surface is not merely mis-narrowed. It is not loaded.

Codex registers an agent role from an `[agents.<role>]` table naming a `config_file`; the role file
itself is `RawAgentRoleFileToml` (EE-2). The pack's own client template does exactly this —
`project-template/.codex/config.toml:64-130` registers sixteen roles, each with
`config_file = "agents/<name>.toml"`.

**The pack repo has no `.codex/config.toml` — not tracked, not on disk** (EE-3). `.codex/` contains
only `agents/` and `skills/`. Nothing registers `pack-architect`, `pack-planner`,
`pack-docs-researcher`, `pack-reviewer`, or `pack-coder` with Codex.

So on this repo the `sandbox_mode` line in those five files is inert: it neither restricted anything
before `e8ea69e` nor grants anything after. **The security review's "control regression on all three
files" is a regression in a declaration Codex never reads on this surface.** That is not a reason to
leave it wrong — a reader, and a client copying the pattern, take it as true — but it is decisive
for proportionality, and it is why I do not recommend building a mechanism here.

I could not establish offline whether Codex *also* auto-discovers role files from a directory. The
binary carries two distinct duplicate-name diagnostics — `duplicate agent role name … declared in
config` and `duplicate agent role name … discovered in …` — and the second implies a discovery path
exists. I could not determine its root: `codex debug prompt-input` does not load agent roles (proven
— a role file missing its required `name` produced no diagnostic), and every other load path needs a
live model session. **This is recorded as PARTIAL, not SUPPORTED** (EE-3). It does not change any
recommendation: even if discovery exists and the files load, §1.2 still holds.

### 1.5 There IS a narrowing mechanism in 0.145.0 — and the pack does not use it

Codex 0.145.0 ships a permissions model that is strictly richer than `sandbox_mode` +
`[sandbox_workspace_write]`. Measured from the binary and from live config-load errors (EE-1):

- `[permissions.<profile>]` deserializes as `PermissionProfileToml`, five fields:
  `description`, `extends`, `workspace_roots`, `filesystem`, `network`.
- `FileSystemAccessMode` is `read` / `write` / `deny`.
- Paths accept absolute, `~/…`, and `:`-special forms; globs are accepted but `deny`-only unless
  written as an exact path or a trailing `/**` subtree.
- A profile is selected by `default_permissions` (config) or `-P/--permission-profile` (CLI).
- `codex sandbox` in 0.145.0 **requires** `--permission-profile`, and `default_permissions` hard-errors
  without a `[permissions]` table — this model is not optional plumbing, it is the current one.

`workspace_roots` + a `filesystem` map with `deny` **is** a genuine mechanical narrowing, and it is
the shape ITEM 1 was reaching for. I am nonetheless **not** recommending the pack adopt it in
BD-288, and I want the reason on the record rather than implied:

1. **I found no per-agent-role binding.** `RawAgentRoleFileToml`'s validated fields are `name`,
   `description`, `nickname_candidates`, `developer_instructions`, plus `model`, `approval_policy`,
   `sandbox_mode`, `model_reasoning_effort`. No permission-profile field appears, and I could not
   force the loader to tell me otherwise offline. A profile that cannot be bound per role is a
   session-wide setting — which would narrow `pack-coder` too, and `pack-coder` must write.
2. **`verify-availability-not-existence` is not satisfied.** I have the schema from a binary and from
   parse-time errors. I have not seen the mechanism enforce anything, because I cannot run a
   sandbox here (EE-5). Designing a security control on a mechanism I have only read about is the
   exact failure `declare-verify-backing` names.
3. **The blast radius is client-side.** Migrating off `sandbox_mode` would touch
   `project-template/.codex/config.toml`, sixteen `project-template/.codex/agents/*.toml`, and
   `xcode-companion-templates/Codex/config.toml` — all client-shipped. That is a `P-missed-7`
   surface, not a pack-hygiene edit.

This is surfaced as **OI-3** with options and a recommendation, not decided here.

## 2. ITEM 1 — the design

Given §1, the design is not a narrowing. It is a **truthfulness repair on three declarations that do
not match their backing** — which is BD-288's remit exactly, and which `declare-verify-backing`
covers verbatim: *any check or record that declares a mapping must verify the LOAD-BEARING reality,
not a necessary-but-insufficient property.*

### 2.1 D1 — the false invocation command (the substantive finding)

`codex --agent <name>` **is not a flag in codex-cli 0.145.0.** Both `codex --agent probe "hi"` and
`codex exec --agent probe "hi"` fail with `error: unexpected argument '--agent' found`, and `--agent`
is absent from the complete long-option list (EE-4). The Claude analogue is real and verified —
`claude --agent <agent>` is documented in `claude --help` on Claude Code 2.1.240 — so this is a
Codex-specific falsehood, not a shared convention.

Three pack-side sites assert it:

| Site | Form | Class |
|---|---|---|
| `pack-ops/PACK-AGENTS.md:94-96` | a three-line shell block under `# Codex CLI` | operating doc |
| `AGENTS.md:271` | "Pack agents are invoked via `codex --agent pack-<name>` (separate session)" | pack-root trinity, Codex audience — the operative rule |
| `AGENTS.md:749` | "pack agents are invoked via `codex --agent pack-<name>`" | pack-root trinity, restated in the graph-first bullet |

**Not in scope, deliberately:** `supporting-docs/SETUP-NEW.md:468`,
`supporting-docs/SETUP-EXISTING.md:398`, and `maintenance-docs/TOOL-COMPARISON.md:67` say
`./agent-run.sh codex --agent <name>`. That is the **client's** `agent-run.sh` wrapper, whose
documented job is to translate an `--agent` argument into whatever the platform actually accepts.
Those are a different claim on a different surface, and they are client-shipped
(`P-missed-7`/`dependency-direction-placement` both apply). BD-288 must not touch them, and I have
not verified them.

**What replaces the false lines.** I do not know the correct 0.145.0 invocation, and I will not
invent one. `operating-docs-no-history-no-bloat` says an operating doc states only what currently
exists and operates. Two shapes are available and they differ materially — this is **OI-1**, with a
recommendation.

### 2.2 D2 — the sandbox comment's mechanism claim

Replace the middle sentence on all four `.codex/agents/*.toml` RO definitions. The comment must stay
**byte-identical across all four** — that property was the point of `e8ea69e`'s NIT fix and is worth
preserving. Proposed replacement (mechanism-accurate, no history, no deferred-feature mention):

```toml
# workspace-write grants writes anywhere in the workspace and cannot be
# narrowed: `writable_roots` ADDS roots to `cwd`, it does not subtract from
# them. The caller-specified deliverable lies outside the workspace and is
# written via the `approval_policy = "on-request"` escalation above. On
# Codex the read-only guarantee is therefore the prose policy below, not a
# sandbox barrier.
```

Six lines against the current six-plus-four. `pack-coder.toml` carries no such comment and must not
gain one — it is RW and the comment is an RO-class artifact.

### 2.3 D3 — the `PACK-AGENTS.md` RO-class parenthetical

`pack-ops/PACK-AGENTS.md:179-185` currently reads, in part:

> (Each RO agent carries the capability to emit that one report — `Write, Edit` in the Claude
> `tools:` line, `workspace-write` in the Codex `sandbox_mode`, no capability field in the
> Antigravity bundle — and is still RO; the class is keyed off the prose mandate header, never the
> tool grant. **No grant is narrowed to the report path**, so the RO guarantee rests on that prose
> plus the spawn's rules-in-force block, not on a mechanical barrier.)

This is already accurate and needs **no change**. I checked it specifically because the natural
instinct after §1.2 is to "strengthen" it; strengthening it would be wrong. It says no grant is
narrowed and the guarantee is prose — which is exactly what I measured. The only defect on this file
is D1.

### 2.4 What this design deliberately does NOT do

- **No pack-side `.codex/config.toml`.** Adding one would make the five pack agent definitions live
  on Codex for the first time. That is a capability *expansion* dressed as a security fix, it is not
  what the item asked for, and it is unverifiable here (I cannot run a session). Surfaced as **OI-2**.
- **No `writable_roots` anywhere.** §1.2.
- **No migration to `[permissions]`.** §1.5, **OI-3**.
- **No change to the `**Read-only.**` mandate header** in any agent definition. Check 52 binds to
  that header as the class key (`pack-ops/PACK-AGENTS.md:23-25`); touching it changes the two-class
  model. Nothing here needs it touched.
- **No change to the Claude `tools:` lines.** The brief is right that the Claude leg changed nothing
  mechanically. It is also not *wrong* now: `tools:` matching the declared write is the correct
  state regardless of whether a hook enforces it.

### 2.5 Encoding surfaces — ITEM 1

| Surface | Edit | Why it is in the set |
|---|---|---|
| `.codex/agents/pack-architect.toml` | D2 comment | one of four byte-identical carriers |
| `.codex/agents/pack-planner.toml` | D2 comment | ” |
| `.codex/agents/pack-docs-researcher.toml` | D2 comment | ” |
| `.codex/agents/pack-reviewer.toml` | D2 comment | ” |
| `pack-ops/PACK-AGENTS.md` | D1 (lines 94-96) | operating doc; **pack-chat-only** — see §2.6 |
| `AGENTS.md` (pack root) | D1 (lines 271, 749) | pack-root trinity; **pack-chat-only** — see §2.6 |
| `CLAUDE.md` / `GEMINI.md` (pack root) | **none** | trinity parity is *not* byte-identity here; the Claude claim is verified true and the Antigravity claim is a different mechanism. Asymmetry is correct and must be stated in the commit message, per the trinity rule's "asymmetry requires justification". |
| `scripts/` validators, `scripts/tests/`, `.github/workflows/` | **none** | measured: no check, test, or workflow asserts on `codex --agent` or on the sandbox comment text (EE-4) |

`enumerate-encoding-surfaces` is satisfied: I enumerated the surface, every validator and test that
could assert its content, the workflow, and the cross-reference docs — and recorded the empty ones as
empty rather than omitting them.

### 2.6 Permission routing — this is not a Pack-Chat-direct edit

`pack-ops/PACK-AGENTS.md` and the pack-root trinity are **pack-chat-only** files. Per
`CLAUDE.md` § "Pack Chat scope" (`[rationale: pack-chat-minor-edits-only]`), D1 is a **MAJOR** edit —
it substantively edits already-landed content and alters a stated rule — so it routes to a
`pack-coder` **scoped in by Pack Chat's prompt**, which that rule names as "the supported path for
major pack-chat-only work — NOT a boundary violation". The `.codex/agents/*.toml` edits are ordinary
coder work.

### 2.7 Verification — how each ITEM 1 fix is proven to bite

`declare-verify-backing` applies to my own fixes, not only to the ones I am correcting.

| Fix | Proof it bites | Expected result |
|---|---|---|
| D1 | `git grep -n "codex --agent" -- pack-ops/ AGENTS.md CLAUDE.md GEMINI.md` | **zero** hits. Grep-zero is the gate, not "I edited three lines". |
| D1 (negative) | `git grep -c "codex --agent" -- supporting-docs/ maintenance-docs/` | **unchanged** from its pre-fix value — proves the client/history surfaces were not swept in |
| D1 (behaviour) | `codex --agent pack-architect "x"; echo $?` | still errors — the *doc* is corrected, no capability is claimed to have been added |
| D2 | `md5 .codex/agents/pack-{architect,planner,docs-researcher,reviewer}.toml`-style comment extraction, or `for f in …; do sed -n '/^# workspace-write/,/^sandbox_mode/p' $f; done \| sort -u \| wc -l` | exactly **1** distinct comment block across the four files — the byte-identity property |
| D2 (negative) | `grep -c "^# workspace-write" .codex/agents/pack-coder.toml` | **0** — the RW agent did not acquire an RO-class comment |
| all | `python3 scripts/validate-pack.py` + the full battery per `verify-full-ci-suite` | green; specifically Check 52 (prose-header set-equality) unchanged |

The D2 byte-identity assertion is worth stating as a gate because it is the property `e8ea69e`
established and the one a partial edit would silently break.

## 3. ITEM 1 — threat model, stated plainly

The brief asked me to be concrete about what the narrowing buys and to say so if the answer is that
it buys little. It is.

**What the control would protect against.** An RO pack agent — architect, planner,
docs-researcher, reviewer — writing a repo file it was not asked to write, on the developer's own
machine, in a repo the developer already trusts.

**What is already true without it.**

- The grant is **inert on this repo**: nothing registers those agent files with Codex (§1.4).
- Even if registered, the proposed mechanism **cannot narrow** (§1.2).
- The same model already runs the developer's interactive Codex session with `workspace-write`
  against the same tree.
- `pack-coder` is RW by design and holds the identical grant.
- The real protections are unaffected and remain: the `**Read-only.**` prose mandate (Check 52 binds
  the class to it), the spawn's rules-in-force block, `agents-never-commit` (nothing an agent writes
  reaches history without Pack Chat and explicit user approval), and the `deletion-boundary.py`
  PreToolUse hook backed by the owned-dirs ledger.

**Residual risk after the narrowing, had it been possible:** an RO agent could still write anywhere
in the workspace, because that is what `workspace-write` means. The narrowing was never going to
reduce the residual to zero; it was going to relabel it.

**Conclusion.** The mechanism is not worth building, and cannot be built as posed. The honest fix is
the truthfulness repair in §2 — which is smaller than the framing and is also the only part of this
item that is an actual instance of BD-288's defect class. I am saying this as a measured answer, not
as a way of scoping the work down: D1 in particular is a real, live, three-site falsehood on pack
operating docs that a reader would act on and get an error from.

---

# ITEM 2 — the non-discriminating test-assertion idiom

## 4. The measured problem

### 4.1 The idiom, and what is actually wrong with it

Every per-check test drives its check against a synthetic tree, captures stdout, and asserts:

```python
fc, cap = run(...)
if fc < 1 or "BD-901" not in cap or "active design" not in cap:
    failures.append(...)
```

`fc` is the count of entries appended to `core.failures` by `fail()`; `warn()` prints but never
appends. So `fc < 1` already discriminates FAIL from WARN perfectly.

The substring clause is there to assert **which** message fired — that the check failed *for the
stated reason*. It discharges that job only if the substring is absent from the check's other
output. When the same substring also appears in the check's WARN text, the clause is satisfied by
either leg and contributes nothing: `fc < 1` carries the whole load, and the test reads as verifying
message content while verifying none.

**This is a vacuous-conjunct defect, not a false-green.** The test still fails if the check stops
failing. What it cannot catch is a check that keeps `fail()` but drifts its message into the WARN
wording — which is exactly the mutation W1 built.

### 4.2 The population is bounded by a property the census did not use

The brief measured "51 of 58 per-check test files use that assertion shape" and correctly noted that
this is not 51 defects. My own broadened census puts it at **52 of 58 files and 464 assertion
clauses** at WT (EE-6). Surveying those by hand would indeed be the wrong shape of answer — but it
is also unnecessary, because the defect has a hard structural precondition the census ignored:

> **A substring cannot fail to discriminate FAIL from WARN unless the check under test HAS a WARN
> leg.**

Measured across `scripts/lib/validate_checks/*.py` by AST — every `check_*` function, classified by
whether its body calls `fail()`, `warn()`, or both (EE-6):

| Property | Count |
|---|---|
| `check_*` functions with a `fail()` or `warn()` call | **87** |
| …with a `fail()` leg only | 84 |
| …with **both** `fail()` and `warn()` | **3** |
| `warn()` call sites in the entire check tree | **8**, across **6** of 21 modules |
| alternate WARN channels (direct `print("WARN…")` inside a check body) | **0** — `core.py:101` is the sole emitter |

The three dual-leg checks are:

| Check | Function | Module |
|---|---|---|
| **65** | `check_operating_doc_no_history` | `boundary_refs.py` |
| **78** | `check_session_state_fresh` | `session_state.py` |
| **81** | `check_open_bd_structured_surface_field` | `cross_bd.py` |

**The candidate population is 3 checks and the ~40 assertion clauses in their 3 test files — not 51
files and 464 clauses.** That is a 92 % reduction in the surface to be examined, obtained from one
AST pass, and it is what makes a bounded answer possible.

### 4.3 The true defect count: 2 at HEAD, 1 still live

Classifying every assertion substring in the three dual-leg test files against the FAIL-reachable and
WARN-reachable literal sets of the check it drives (EE-9):

| Tree | Assertions in dual-leg test files | Non-discriminating | Where |
|---|---:|---:|---|
| **HEAD** (`e8ea69e`, pre-W1) | 33 | **2** | `test-validate-pack-check-81.sh`: `"active design"`, `"missing"` |
| **WT** (post-W1) | 40 | **1** | `test-validate-pack-check-81.sh`: `"missing"` |

Checks 65 and 78 are **clean, and were already clean**. Their tests use genuinely FAIL-only
substrings (`"OUTSIDE the allowlist"`, `"does NOT resolve to a commit"`, `"NOT an ancestor of
HEAD"`) and genuinely WARN-only ones (`"matched NO line"`, `"ADVISORY ONLY"`, `"lags HEAD by"`).
Check 78's test even asserts the *absence* of WARN text on the clean leg
(`if "ADVISORY" in cap or "lags HEAD" in cap:`). Nothing to fix there — a fact worth stating,
because "51 files" invites a sweep that would churn two already-correct files.

### 4.4 The live instance, proven at runtime

`scripts/tests/test-validate-pack-check-81.sh` (WT line 241; HEAD line 221) — untouched by W1:

```python
# T6: FAIL — an ACTIVE BD with NO File/Symbol field at all (missing) FAILs.
fc, cap = run([("BD-906", "Open", None)], ["BD-906"])
if fc < 1 or "BD-906" not in cap or "missing" not in cap:
```

Check 81's FAIL leg reaches the word `missing` through an interpolated variable:

```python
detail = "missing" if not fs_value else "bare/TBD/placeholder"
fail(f"… but its `File/Symbol` field is {detail} (no structured repo-relative path list). …")
```

and its WARN leg contains it as a plain literal: `"has a bare/TBD/missing \`File/Symbol\` field"`.

**Runtime proof (EE-8).** Driving the check on a synthetic tree with a NON-active BD whose
`File/Symbol` is absent — the WARN-only path:

```
failure count: 0
'missing' in cap -> True
'WARN' in cap    -> True
WARN: backlog/BD-906.md — BD-906 (open, not yet in active design) has a bare/TBD/missing
`File/Symbol` field; …
```

`"missing" in cap` is satisfied with **zero** failures. The clause is confirmed non-discriminating.
This is a live defect in the working tree right now, in the file W1 owns.

## 5. ITEM 2 — the design

### 5.1 F1 — fix the one live instance (W1's file)

```python
-if fc < 1 or "BD-906" not in cap or "missing" not in cap:
+if fc < 1 or "BD-906" not in cap \
+        or "no structured repo-relative path list" not in cap \
+        or "field is missing" not in cap:
```

Two clauses, deliberately:

- `"no structured repo-relative path list"` is a **pure FAIL-leg literal** — statically visible,
  absent from the WARN text. This is the discriminating clause.
- `"field is missing"` preserves T6's actual intent (that the `detail` branch chose `missing` rather
  than `bare/TBD/placeholder`). It spans the `{detail}` interpolation boundary, so it exists only in
  the rendered output — correct at runtime, invisible to any static analyser, including the guard in
  §5.2. That is fine: the guard's job is to catch collisions, not to prove a substring exists.

### 5.2 F2 — Check 96, the guard

**What it asserts.** For every `check_*` function that has BOTH a `fail()` and a `warn()` leg, no
assertion clause in that check's per-check test file may test a substring that is reachable from both
legs.

**Algorithm.**

1. Candidate set from **`git ls-files scripts/lib/validate_checks scripts/tests`** — never a
   filesystem walk. Off a git work tree, or if `git` is unavailable: **SKIP, lenient**, and say so.
2. AST-parse each `scripts/lib/validate_checks/*.py`. For each `check_*` `FunctionDef`, collect three
   literal sets — string constants and f-string static parts:
   - `F` = literals inside `fail(...)` calls
   - `W` = literals inside `warn(...)` calls
   - `V` = literals in any assignment inside the function (the interpolation candidates)
3. Dual-leg set = `{fn : F ≠ ∅ and W ≠ ∅}`.
4. Map each `scripts/tests/test-validate-pack-check-*.sh` to its check(s): primary key
   `\bmod\.(check_[a-z0-9_]+)\s*\(`; fallback, a loose `\b(check_[a-z0-9_]+)\b` token intersected with
   the known check set. Keep only files resolving to ≥1 dual-leg check.
5. In those files, extract every `"…" [not] in (cap|captured|out|output)` clause.
6. **FAIL** any clause whose substring appears in `F ∪ V` **and** in `W ∪ V`, naming the file, the
   substring, and the check.

**Why `∪ V` is the load-bearing part of the design.** The obvious form of this guard — compare
against `F` and `W` only — **misses the `"missing"` instance**, because `missing` never appears
literally inside the `fail()` call. Measured (EE-9): the naive form finds **1 of the 2** instances at
HEAD. A guard with a 50 % miss rate on the only known population is precisely the defect BD-288
exists to eliminate; shipping it would be the fourth instance of this BD's own class. Including `V`
on **both** sides raises it to **2 of 2**.

`∪ V` is an over-approximation, and its error direction is the safe one: a literal assigned to a
variable used only in `fail()` is also credited to the WARN side, which can only produce a **false
positive** — visible, allowlistable — never a false negative.

**Measured false-positive rate: zero.** Across 33 clauses at HEAD, 2 flagged, both true. Across 40
clauses at WT, 1 flagged, true (EE-9).

### 5.3 `ci-guard-measure-then-bound`, step by step

| Step | Result |
|---|---|
| **1. Measure first** | Complete occurrence list captured at two tree states: HEAD → 2 occurrences; WT → 1. Full clause census: 464 clauses / 52 files, narrowed to 40 clauses / 3 files by the dual-leg precondition (EE-6, EE-9) |
| **2. Categorize every occurrence** | HEAD: `"active design"` → **STRIP**; `"missing"` → **STRIP**. Zero KEEPs. |
| **3. Fix-recipes for every STRIP** | `"active design"` → landed in W1. `"missing"` → §5.1 F1. Both STRIPs have a recipe. |
| **4. Allowlist sized exactly to the legitimate set** | The legitimate set is **empty**, so **Check 96 ships with no allowlist constant at all.** An empty allowlist is not a placeholder to be filled later — a future KEEP would be a *new* claim requiring its own measurement. |
| **5. Verify clean against the projected post-fix state** | Post-F1, the classifier reports `FLAGGED: 0` over 40 clauses. The gate for F2's commit is that run returning 0, executed on the tree that already contains F1. |
| **git-tracked candidate set** | `git ls-files scripts/lib/validate_checks scripts/tests`, lenient SKIP off a work tree (§5.2 step 1) |
| **Catches the ABSENCE-of-backing instance** | Yes, and this is the point: it fires on a declared assertion whose discriminating power is absent, which is the absence-of-backing form, not the target-exists form |

### 5.4 Runtime cost — `ci-check-runtime-compounding`

Budgets: **10.0 s** total hard-FAIL, **2.0 s** per-check WARN. Current baseline: `validate-pack.py`
completes in **1.92 s** wall (EE-10).

| Component | Measured |
|---|---|
| AST-parse all 21 check modules (905,129 bytes) | **37.0 ms** |
| `git ls-files` over the 2 prefixes (319 paths) | **11.7 ms** |
| Read + regex the 3 dual-leg test files | < 5 ms |
| **In-process total** | **≤ 60 ms** |
| Standalone prototype incl. interpreter startup, 5 runs | 0.10 s, 0.10, 0.10, 0.10, 0.10 |

≤ 60 ms is **3 % of the 2.0 s per-check WARN budget** and **0.6 % of the 10.0 s total**, lifting the
battery to ~1.98 s. The cost is O(bytes of the check modules), with no filesystem walk, no
subprocess per entry, and exactly one `git` subprocess for the whole check. It does **not** scale
with the 464-clause census — only the 3 dual-leg files are read.

**One honest caveat.** The 37 ms scales with the check-module corpus, which grows every time a check
is added. At the current 905 KB it is 37 ms; a doubling of the corpus makes it ~75 ms. Still
comfortably inside budget, but the guard should be listed in whatever the runtime-budget guard
(`run_check` timing, `core.py`) reports, so a future regression surfaces rather than accumulates.

### 5.5 Proving the guard bites — the self-application requirement

The brief is right that a guard prescribing this medicine must take it. Three probes, all in a
`mktemp -d` copy, none touching the repo:

| Probe | Mutation | Required result |
|---|---|---|
| **P1 — historical** | Revert W1's fix (`"is in active design (session-state"` → `"active design"`) in the test file only | Check 96 **FAILs**, naming `test-validate-pack-check-81.sh` and `active design`. Proves it catches the instance a human found. |
| **P2 — interpolation** | Revert F1 (`"no structured repo-relative path list"` → `"missing"`) | Check 96 **FAILs** on `missing`. **This is the probe the naive guard cannot pass** — it is the discriminator between the two designs, and it must be run against the naive form too, to record that it passes silently there. |
| **P3 — forward** | On the clean tree, add a WARN literal to Check 65 colliding with its test's `"OUTSIDE the allowlist"` assertion (e.g. append that phrase to a `warn()` string) | Check 96 **FAILs** on Check 65. Proves the guard generalises beyond the check that motivated it, and is not accidentally hard-coded to Check 81. |
| **P4 — negative** | Clean tree, no mutation | Check 96 **passes**, `FLAGGED: 0`. Proves it is not permanently red. |
| **P5 — lenient** | Run from a non-git directory | Check 96 **SKIPs**, exit 0, with the skip stated in its output |

P2 is the probe that earns the design. Without it, the naive form looks equally good.

### 5.6 Encoding surfaces — ITEM 2

`enumerate-encoding-surfaces` for a new check, per the brief's own enumeration, measured against
this tree:

| Surface | Edit | Measured anchor |
|---|---|---|
| `scripts/lib/validate_checks/wired_test_fragility.py` (**recommended home**) or a new module | the `check_*` body | see §5.7 |
| `scripts/validate-pack.py` | registry tuple `(96, "check_…", check_…, W)` | highest registered number is **94**; W3 takes 95; this is **96** |
| `scripts/lib/validate_checks/core.py:210` | `CHECK_REGISTRY_EXPECTED_COUNT` | currently **91**; W3 → 92; this → **93** |
| `scripts/lib/validate_checks/core.py:205-206` | ledger comment (`# numeric ID = 94.`) | must advance in lock-step |
| `scripts/tests/test-validate-pack-check-96.sh` | NEW | wired automatically — Check 42's coverage is **disk-derived**; per `PLAN-BD-288-READY.md` §2.2 there is **no** `.github/workflows/validate-pack.yml` edit to make |
| `scripts/lib/ci-shard-plan.py` | **none** | the shard matrix is emitted at CI run time from disk |
| `README.md:83` | the version-table check-count prose | the sentence enumerating "91 invoked checks (86 numbered Check 1–11, 16–20, …)" — two numbers move |
| `scripts/tests/test-validate-pack-check-81.sh` | F1 | the live instance |

**The `README.md` and `core.py` counts are the collision.** W3 already owns all four
(`validate-pack.py`, `core.py`, `README.md` ×2) for Check 95. See §6.

### 5.7 Where the check body lives

`scripts/lib/validate_checks/wired_test_fragility.py` already exists and its name states the concern:
guards over the *wired test suite's* own robustness. A guard asserting that a per-check test's
assertions discriminate is the same concern, and placing it there avoids a new module and a new
import seam — `filename-uniqueness-heuristic` and the pack's preference for fewer files both point
the same way. I recommend that home. I did not read its full body, so this is a **PARTIAL** claim: the
coder should confirm the module's existing helpers do not already provide the AST walk before adding
one, and should re-site if the module turns out to be narrowly scoped to a different mechanism.

### 5.8 What ITEM 2 deliberately does NOT do

- **No sweep of the 464 clauses / 52 files.** 84 of 87 checks have no WARN leg; their assertion
  substrings cannot collide with anything. Touching them is churn, and churn on 52 test files is a
  review surface nobody can read.
- **No mutation-testing harness.** The general property ("does removing this clause change the
  verdict?") is mutation testing, which is unbounded and cannot be a per-battery CI check under
  `ci-check-runtime-compounding`. The dual-leg collision is the tractable, decidable projection of
  it, and it is the one with measured instances.
- **No guard on "asserted substring appears in NO emitter".** I considered this — a stale or typo'd
  substring in a *negative* assertion (`if "X" in cap:`) is permanently vacuous and silent. But
  measured, 322 of 464 clauses assert substrings that appear in no check literal, because they come
  from the synthetic fixture (`"BD-901"`, `"2026-05-30"`, `"deadbeef1234"`, `"ZZZ-MATCHES-NOTHING-ZZZ"`).
  A guard there has a ~70 % false-positive rate and an allowlist larger than the thing it guards.
  Rejected on measurement, and recorded so it is not re-proposed.

---

## 6. Placement relative to W1–W4, and the parallel-vs-dependent map

### 6.1 File-contention against the wave plan

`PLAN-BD-288-READY.md` §3.1 gives each wave's file set. Intersecting mine against it:

| This document's work | Files | ∩ W1 | ∩ W2 | ∩ W3 | ∩ W4 |
|---|---|:--:|:--:|:--:|:--:|
| **ITEM 1** (D1, D2) | `.codex/agents/pack-{architect,planner,docs-researcher,reviewer}.toml`, `pack-ops/PACK-AGENTS.md`, `AGENTS.md` | ∅ | ∅ | ∅ | ∅ |
| **ITEM 2 / F1** | `scripts/tests/test-validate-pack-check-81.sh` | **●** | ∅ | ∅ | ∅ |
| **ITEM 2 / F2** | `wired_test_fragility.py`, `scripts/validate-pack.py`, `core.py`, `README.md`, `scripts/tests/test-validate-pack-check-96.sh` (NEW) | ∅ | ∅ | **●●●** | ∅ |

W3 owns `scripts/validate-pack.py`, `core.py`, and `README.md` for Check 95's registry / count /
ledger / README lock-step set. F2 needs the same four surfaces for Check 96. **They must serialize.**
W4 touches none of them, so F2 and W4 are independent.

`ITEM 1` intersects nothing in any wave and is unblocked today.

### 6.2 The resulting map

```
   W1 ────────────────────────────────────────────────►                (in review cycle)

   W2 ──────► W3 ──────► W4
                 └─────► W6  (ITEM 2: F1 + Check 96)     — parallel with W4

   W5 (ITEM 1) ───────────────────────────────────────►  — parallel from now, gated only on OI-1
```

- **W5 = ITEM 1.** No file contention with anything. Startable as soon as OI-1 closes.
- **W6 = ITEM 2, F1 and F2 in ONE commit.** Depends on W3 (the lock-step surfaces). Parallel with W4.

### 6.3 Why F1 and F2 land together, and not F1 in W1

The brief names the trap correctly: *"a guard committed before its fix-set lands red."* Check 96 on a
tree still containing the `"missing"` clause is **RED on arrival**. So the ordering constraint is
hard: **F1 must be in the tree at or before F2's commit.**

Two shapes satisfy it.

| Shape | For | Against |
|---|---|---|
| **(a) F1 into W1; F2 alone in W6** | same file, same reviewer already reading it; 3-line change | adds scope to a wave **mid-review-cycle**, spending W1's bounded budget on work W1 was not scoped for; and it makes F2's step-5 gate depend on a *different* commit having landed |
| **(b) F1 + F2 together in W6** ✅ | one commit is self-consistent — the defect and the guard that catches it; F2's `ci-guard-measure-then-bound` step-5 gate is provable **in its own tree**, not contingent on W1; the red-guard trap cannot occur by construction | leaves one known non-discriminating clause live through W2/W3 — cosmetic only, since `fc < 1` still gates T6 correctly |

**Recommendation: (b).** This is a sequencing choice inside BD-288 with both parts landing in v11.0
— not a deferral. The `deferral-is-scope-creep` test is satisfied on **LOGICAL FIT** with concrete
evidence: F1 *is* F2's fix-set, and step 5 of `ci-guard-measure-then-bound` requires the guard to be
verified against the post-fix tree, which is only true if they share one.

If W1's review cycle is still open and has budget when this is read, (a) is not wrong — it just buys
less than it costs. Recorded as **OI-4**.

### 6.4 A live operational constraint W6 inherits

`PLAN-BD-288-READY.md` §1.4 makes Check 81's liveness a pre-flight for every wave after W1: seven
open BDs carry a bare/TBD `File/Symbol`, and if any is placed in `pack-ops/session-state.json`
`active[]` while waves are in flight, the tree goes RED. W6 edits Check 81's test and must run that
pre-flight before attributing any red to its own edits. This is the guard biting correctly, not a
defect.

---

### 6.5 One bookkeeping consequence for `backlog/BD-288.md`

`backlog/_rules.md` requires a BD in active design to carry a structured `File/Symbol` list, and
Check 81 gates it. BD-288 is in `active[]`. The surfaces this document adds are **not** in BD-288's
current `File/Symbol` field:

`.codex/agents/pack-{architect,planner,docs-researcher,reviewer}.toml` (present — added by the
session-hygiene item), `pack-ops/PACK-AGENTS.md` (present), **`AGENTS.md` (pack root) — absent**,
**`scripts/lib/validate_checks/wired_test_fragility.py` — absent**,
**`scripts/tests/test-validate-pack-check-96.sh` — absent**.

That is a `pack-chat-only` bookkeeping append to an existing entry, and it should land before W5/W6
so the cross-BD collision scan (Check 82) can key on the real surfaces. It is Pack Chat's edit, not a
coder's, and it is not part of either wave.

---

## 7. Bounded-cycle fit

`bounded-review-fix-cycle`: max 2 review/fix pairs + 1 final reviewer pass per commit. I size each
wave by **remaining discovery**, not file count — a wave with no open questions converges even when
it touches many files, and a wave with one unresolved question does not converge even when it
touches one.

### 7.1 W5 (ITEM 1) — fits, once OI-1 closes

| | |
|---|---|
| Files | 6 |
| Distinct edits | 2 (a byte-identical comment replayed across 4 files; a text correction at 3 sites in 2 files) |
| Remaining discovery **inside** the wave | **none** — §2.2 gives the exact replacement text; §2.7 gives the grep-zero gates |
| Remaining discovery **before** the wave | **one**: OI-1, the replacement wording for the invocation claim. It is a *decision*, not an investigation, and must close before the coder spawns |
| Review surface | small and mechanical; the only subtle property is D2's byte-identity across four files, which §2.7 makes an explicit assertion rather than a reviewer's eyeball |
| Risk of a second dirty pass | low — the failure mode is a partial 4-file edit, and the byte-identity gate catches it before the reviewer sees it |

**Verdict: one cycle.** W5 must not be spawned before OI-1 closes; spawning it with the wording
unresolved is what would burn both fix passes.

### 7.2 W6 (ITEM 2) — fits

| | |
|---|---|
| Files | 6 (F1's test file, the check body's module, `validate-pack.py`, `core.py`, `README.md`, the new test file) |
| Remaining discovery | **near zero.** The algorithm is fully specified (§5.2); a working prototype exists and has been run against two tree states; the false-positive rate is measured at 0; the allowlist is measured empty; the runtime is measured; the five probes are specified with required results |
| The one open piece | §5.7 — whether `wired_test_fragility.py` is the right home. A single file read resolves it, and re-siting is a move, not a redesign. **OI-5** |
| Review surface | one new check body plus a lock-step count set. The count set is the classic partial-edit hazard, and the pack already has Check 59 / Check 64 asserting registry-vs-constant agreement, so a partial edit fails the battery rather than reaching the reviewer |
| Risk of a second dirty pass | moderate on the lock-step counts, low on the algorithm — because the algorithm has already been executed rather than only described |

**Verdict: one cycle.** The reason I can claim that is not the file count (6, the same as W5's) — it
is that every number this wave will assert has already been produced by a run recorded in §9.

### 7.3 What would break the fit

- Spawning W6 **before W3 lands.** The count surfaces collide; the coder would be reconciling
  against a moving target and the second fix pass would go to merge repair rather than defects.
- Renumbering. If W3's scope changes and Check 95 does not land, Check 96 becomes Check 95 and every
  lock-step number shifts. **OI-6.**
- Treating ITEM 2 as "51 files". §4.2 is the whole reason this fits one cycle.

---

## 8. Open items

Each carries context, my own options, and an evidence- or logic-based recommendation — or an explicit
"no recommendation can be given". None defers work to another BD or a later version; every option
lands inside BD-288 and inside v11.0.

### OI-1 — what replaces `codex --agent pack-<name>` (BLOCKS W5)

**Context.** Three pack operating-doc sites assert an invocation that errors (EE-4):
`pack-ops/PACK-AGENTS.md:94-96`, `AGENTS.md:271`, `AGENTS.md:749`. I established that the command is
invalid. I did **not** establish what the valid one is: Codex registers roles from an
`[agents.<role>]` table (EE-2), the pack has no such table (EE-3), and I could not exercise the
loader offline (EE-3). So I know the current text is false and I do not know the true text.

Note the trinity is **already asymmetric here by design**, which removes the obvious objection:
`CLAUDE.md:269-273` states a verified-true `claude --agent pack-<name>`; `GEMINI.md:234-240` states a
plugin-bundle + `agy` mechanism with its own re-verify hedge. Three platforms, three native
mechanisms. Correcting only the Codex one is consistent with that, not a parity break — but the
commit message must say so explicitly, per the trinity rule's "asymmetry requires justification".

**Options.**

- **(a) State only what is true today.** Replace the three sites with: pack Codex agent definitions
  live at `.codex/agents/*.toml` and are invoked as sub-agents within Pack Chat; there is no
  standalone Codex launcher for them in this repo. Cost: 3 edits. Risk: if a launcher does exist,
  the doc under-claims.
- **(b) Run a `pack-docs-researcher` pass first**, scoped to "establish the invocation path for a
  project-registered Codex agent role in codex-cli 0.145.0", then write the verified form. Cost: one
  extra agent pass inside W5. Risk: none to correctness; it delays W5 by one spawn.
- **(c) Delete the lines outright.** Cheapest. Leaves `PACK-AGENTS.md` § "How to invoke pack agents"
  with a Claude block and an Antigravity block and a hole where Codex was — which a reader will
  read as an omission and may re-fill with the same guess.

**Recommendation: (b), then (a) as the fallback if (b) returns nothing usable.** The evidence
supports this rather than a coin-flip: the researcher-first pipeline is the pack's own standard when
work depends on external CLI semantics verified against authoritative sources, and this is exactly
that case. The pass is cheap, it is in-BD, and it converts a guess into a fact. (a) is a sound
fallback because an under-claim on an operating doc is recoverable, whereas the current over-claim
produces an error at the terminal. (c) is rejected: `operating-docs-no-history-no-bloat` asks for
terse *accurate* content, not absence.

### OI-2 — should the pack gain a `.codex/config.toml`?

**Context.** Without one, the five pack `.codex/agents/*.toml` are unregistered and unread on this
repo (EE-3). Adding one would register them and make Codex a live orchestration surface for pack
development for the first time.

**Options.** (a) Add it, registering all five roles, mirroring
`project-template/.codex/config.toml`'s shape. (b) Do not add it; keep the agent definitions as
trinity-parity artifacts. (c) Add it *and* narrow with `[permissions]` — see OI-3.

**Recommendation: (b), do not add it in BD-288.** Evidence: BD-288 is a *guard-coverage* entry; its
remit is checks that do not bite. Registering a CLI surface is a capability expansion with a
different risk profile, it is unverifiable in this environment (EE-5), and nothing in BD-288's
acceptance criteria touches it. It is also the option that would make the sandbox question *newly*
live rather than settle it. Recording (b) is a decision to leave a surface inert, not to defer work:
there is no work item here that BD-288 opened.

### OI-3 — should the pack migrate from `sandbox_mode` to `[permissions]`?

**Context.** Codex 0.145.0 ships `[permissions.<profile>]` with `workspace_roots` + a `filesystem`
map supporting `deny`, `~/…` paths, and `:special` roots (EE-1). `codex sandbox` now *requires*
`--permission-profile`. This is plausibly the successor model, and the pack — pack-side and
client-side — is entirely on the legacy keys.

**Options.** (a) Migrate now. (b) Leave as-is. (c) Run a `pack-docs-researcher` pass inside BD-288
to establish whether `sandbox_mode` / `[sandbox_workspace_write]` are deprecated in 0.145.0, and act
on the finding within BD-288.

**Recommendation: (c).** Evidence for not doing (a) blind: I have the schema from binary strings and
parse-time errors, and I have **not observed enforcement** (EE-5) — `verify-availability-not-existence`
is unsatisfied, and designing a security control on an unverified mechanism is the failure this BD
exists to prevent. Evidence for not doing (b) silently: if the legacy keys are deprecated, the
**client-shipped** `project-template/.codex/config.toml`, sixteen `project-template/.codex/agents/*.toml`,
and `xcode-companion-templates/Codex/config.toml` are all carrying keys that will stop working for
real users — which is a live client-facing correctness question, not a nice-to-have. (c) is bounded
(one researcher spawn), lands in BD-288, and is the only option that produces a decision on evidence.
Note `P-missed-7`: any resulting change to `project-template/` is a project-side surface and must be
investigated on its own terms, never patterned off the pack-side fix.

### OI-4 — F1's placement: fold into W1, or land with F2 in W6?

Covered in §6.3 with the full comparison. **Recommendation: land F1 with F2 in W6.** Logical-fit
evidence: F1 is F2's fix-set, and `ci-guard-measure-then-bound` step 5 requires the guard to be
verified against the post-fix tree — a property that is self-contained only if they share a commit.
The alternative (F1 into W1) is acceptable but adds scope to a wave already inside its review cycle.

### OI-5 — the module home for Check 96

**Context.** §5.7 recommends `scripts/lib/validate_checks/wired_test_fragility.py` on the strength of
its name and the pack's preference for fewer files. I did not read its body, so the claim is PARTIAL.

**Options.** (a) `wired_test_fragility.py`. (b) A new module. (c) `cross_bd.py`, where Check 81 lives.

**Recommendation: (a), with a one-read confirmation by the coder before writing.** (c) is rejected on
evidence: the guard is not about cross-BD anything, and siting it there would make its scope unreadable
from the module name. (b) is rejected unless (a)'s body turns out to be narrowly bound to a different
mechanism — a new module costs an import seam and a new name for a ~100-line check.

### OI-6 — check numbering depends on W3

**Context.** §5.6 assigns Check **96** and `CHECK_REGISTRY_EXPECTED_COUNT` **93** on the assumption
that W3 lands Check 95 first (measured: highest registered number is 94, constant is 91 — EE-10).

**Options.** (a) Hard-code 96 and require W3-first ordering (already required by file contention,
§6.1). (b) Have the coder re-derive the next number at wave start from the registry.

**Recommendation: (b), which subsumes (a).** The plan's own convention is that line numbers and
counts are navigation aids re-measured at execution; the same applies to a check number. The coder
re-reads `_build_check_registry()` and `CHECK_REGISTRY_EXPECTED_COUNT` at W6 pre-flight and uses
whatever it finds. This removes a whole class of merge-order breakage at zero cost.

### OI-7 — the guard's cost grows with the check corpus

**Context.** §5.4 measures 37.0 ms to AST-parse the 905 KB check corpus. That term grows every time a
check is added; the rest of the guard does not.

**Options.** (a) Accept it — 37 ms is 1.9 % of the per-check WARN budget. (b) Cache the parse across
checks (several checks already parse these modules). (c) Restrict the parse to modules containing a
`warn(` textual hit before AST-parsing — measured: 6 modules of 21.

**Recommendation: (c).** It is a two-line pre-filter (`if "warn(" not in src: continue`) that cuts the
dominant term from **37.0 ms to 15.7 ms** with no change in result, because a module with no `warn(`
call cannot contain a dual-leg check. The pre-filter scan itself costs **0.5 ms** to read all 21
modules, and it narrows 21 modules / 905,129 bytes to 6 / 394,225 bytes (43.6 %). Evidence: 8
`warn()` call sites across 6 of 21 modules (EE-6, EE-10). (b) is rejected as a cross-check caching
seam — real complexity for a term already inside budget. (a) is acceptable but (c) is strictly better
for the same effort.

### OI-8 — the ITEM-1 sandbox comment could be dropped entirely

**Context.** §2.2 replaces the four-file comment. An alternative is to delete it: if the Codex leg is
unregistered and inert (EE-3), a ten-line comment explaining a sandbox nuance on an unread file is
arguably bloat, and `operating-docs-no-history-no-bloat` asks operating docs to stay terse.

**Options.** (a) Replace with the corrected six-line form (§2.2). (b) Delete entirely, leaving
`sandbox_mode = "workspace-write"` bare. (c) Delete from the four TOMLs and state the mechanism once
in `pack-ops/PACK-AGENTS.md` § "Two agent classes", which already says the right thing (§2.3).

**No recommendation can be given between (a) and (c).** Both are defensible and the evidence does not
discriminate: (a) keeps the warning where a maintainer editing `sandbox_mode` will see it, which is
where it does its work; (c) has one copy instead of four and no byte-identity property to maintain,
which is the pack's stated preference for fewer conventions. I can rule out **(b)** on evidence —
deleting it restores the pre-`e8ea69e` state in which a reader assumes `workspace-write` is narrowable,
which is the misconception this whole item started from. Between (a) and (c) this is a judgement about
where the pack wants its mechanism notes to live, and that is the user's call, not mine.

---

## 9. Empirical-Evidence Blocks

Every state-claim in this document maps to a block below. Each records the command run, the output as
captured (not paraphrased), the measurement point, the interpretation, and a conclusion of
SUPPORTED / NOT-SUPPORTED / PARTIAL.

**Measurement point for all blocks:** repo `/Users/david/Developer/optiquity-ai-agent-config-pack`,
branch `main`, **HEAD `e8ea69e`**, date **2026-08-24**. Where a block distinguishes HEAD from WT, it
says so. Environment: macOS (Darwin 25.6.0), `codex-cli 0.145.0` at `/opt/homebrew/bin/codex`,
Claude Code `2.1.240`, `git 2.50.1`.

---

### EE-1 — `writable_roots` is additive; the 0.145.0 permission vocabulary

**Commands.**
```
strings -a /opt/homebrew/lib/node_modules/@openai/codex/node_modules/@openai/\
codex-darwin-arm64/vendor/aarch64-apple-darwin/bin/codex > codex_strings.txt
grep -n "Filesystem sandboxing defines" codex_strings.txt
codex exec --help | grep -A2 add-dir
codex sandbox -P narrow -C <scratch> /bin/echo hello     # with staged CODEX_HOME configs
```

**Output (captured).**
```
523156:… `sandbox_mode` is `read-only`: The sandbox only permits reading files. …
523157:Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is
        `workspace-write`: The sandbox permits reading files, and editing files in `cwd` and
        `writable_roots`. Editing files in other directories requires approval. …
523158:… `sandbox_mode` is `danger-full-access`: No filesystem sandboxing …

      --add-dir <DIR>
          Additional directories that should be writable alongside the primary workspace
```
Staged-config probe sequence, each line the complete error returned:
```
[permission_profiles.narrow] + -P narrow   -> Error: default_permissions requires a `[permissions]` table
[permissions] (empty)        + -P narrow   -> Error: default_permissions refers to undefined profile `narrow`
[permissions] edit="workspace"             -> invalid type: string "workspace", expected struct PermissionProfileToml
```
Struct/field blobs recovered from the same strings dump:
```
struct PermissionProfileToml with 5 elements
…extendsworkspace_rootsfilesystemnetworkFileSystemAccessModereadwritedeny…
…untagged enum FilesystemPermissionToml…
restrictedFileSystemSpecialPathminimalproject_rootssubpathtmpdirslash_tmpunrestricted
filesystem path `…` must be absolute, use `~/...`, or start with `:`
filesystem glob path `…` only supports `deny` access; use an exact path or trailing `/**` …
Configured filesystem path `…` is not recognized by this version of Codex and will be ignored.
```

**Interpretation.** The binary's own model-facing prose states the writable set under
`workspace-write` as `cwd` **and** `writable_roots` — a union, not a restriction. `--add-dir`'s help
text ("Additional directories … alongside the primary workspace") states the same polarity in the
CLI surface. Separately, 0.145.0 carries a distinct `[permissions.<profile>]` model with five fields
(`description`, `extends`, `workspace_roots`, `filesystem`, `network`), a `read`/`write`/`deny`
access vocabulary, and a path grammar accepting `~/…` and `:`-special roots.

**Conclusion.**
- `writable_roots` cannot narrow `workspace-write`: **SUPPORTED.**
- `~/…` is an expressible path form (so `$XDG_STATE_HOME`'s default is encodable without a
  machine-specific literal): **SUPPORTED**, for the `[permissions]` model only.
- A `[permissions]` profile could express a genuine narrowing: **PARTIAL** — the schema is
  established from binary strings and live parse errors; enforcement was not observed (EE-5).

---

### EE-2 — how Codex registers an agent role

**Commands.**
```
grep -n "config_file" codex_strings.txt | awk 'length($0)<500'
sed -n '469352,469365p' codex_strings.txt
sed -n '64,130p' project-template/.codex/config.toml
```

**Output (captured).**
```
L513440: versiontransportvoiceRealtimeTomldescriptionconfig_filenickname_candidatesAgentRoleTomltrust_level
struct AgentRoleToml with 3 elements
core/src/config/agent_roles.rs
agents. .description
agents. .nickname_candidates
agents. .config_file must point to a file:
agents. .config_file must point to an existing file at
duplicate agent role name `…` declared in config
duplicate agent role name `…` discovered in …
agent role file at … must define a non-empty `name`
agent role `…` must define a description
agent role file at … must define `developer_instructions`
```
```
[agents.architect]
description = "Read-only architecture specialist …"
config_file = "agents/architect.toml"
…  (16 such tables)
```

**Interpretation.** `AgentRoleToml` has three fields — `description`, `config_file`,
`nickname_candidates` — and lives under `[agents.<role>]`. The pack's own client template uses
exactly this registration for 16 roles. A separate "discovered in" diagnostic implies a directory
discovery path also exists.

**Conclusion.** `[agents.<role>] config_file` is a registration mechanism: **SUPPORTED.** That it is
the *only* mechanism: **NOT-SUPPORTED** — the "discovered in" string is direct evidence against
exclusivity.

---

### EE-3 — the pack has no `.codex/config.toml`; the agent-role loader is not reachable offline

**Commands.**
```
git ls-files | grep -i 'config\.toml'
ls -la .codex/ ; test -f .codex/config.toml && echo YES || echo "NO — absent"
git status --porcelain .codex/
# offline load probe, isolated CODEX_HOME + scratch project:
#   role file stripped of its required `name`, plus duplicate-named role files
#   placed in both $CODEX_HOME/agents/ and <proj>/.codex/agents/
codex debug prompt-input "hi" 2>&1 | grep -i "duplicate|agent role|malformed"
```

**Output (captured).**
```
project-template/.codex/config.toml
project-template/.codex/config.toml.example
scripts/tests/fixtures/customization-preserve/… (6 fixture copies)
xcode-companion-templates/Codex/config.toml
```
```
.codex/
  agents/
  skills/
NO — absent
(git status .codex/ : no output — nothing untracked, nothing modified)
```
```
EXIT=0     (no diagnostic emitted for a name-less role file, and none for the duplicate names)
```

**Interpretation.** No `.codex/config.toml` exists at the pack root — not tracked, not on disk, not
untracked-but-present. The only `config.toml` files in the repo are the client template, its
`.example`, six merge fixtures, and the Xcode companion template. Nothing registers the five pack
agent roles. Separately, `codex debug prompt-input` does not exercise the agent-role loader (a role
file missing its mandatory `name` produced no diagnostic), so the discovery question could not be
resolved offline.

**Conclusion.**
- No pack-side `.codex/config.toml` exists: **SUPPORTED.**
- Therefore no `[agents.*]` registration exists for the five pack roles: **SUPPORTED.**
- Therefore the pack's `.codex/agents/*.toml` are never loaded by Codex on this repo: **PARTIAL** —
  follows only if registration is the sole load path, which EE-2 leaves open. The weaker claim —
  *no registration exists* — is unconditional.

---

### EE-4 — `codex --agent` is not a valid flag; `claude --agent` is

**Commands.**
```
codex --agent probe "hi"            ; codex exec --agent probe "hi"
codex --help | grep -o "^\s*--[a-z-]*" | sort -u
claude --help | grep agent ; claude --version
git grep -n "codex --agent" -- .
grep -rn "codex --agent" scripts/ .github/ 2>/dev/null
```

**Output (captured).**
```
error: unexpected argument '--agent' found
  tip: to pass '--agent' as a value, use '-- --agent'
Usage: codex [OPTIONS] [PROMPT]
(identical for `codex exec --agent`)

complete long-option list: --add-dir --dangerously-bypass-approvals-and-sandbox
  --dangerously-bypass-hook-trust --disable --enable --local-provider --no-alt-screen
  --remote --remote-auth-token-env --search --strict-config
```
```
  --agent <agent>    Agent for the current session. Overrides the 'agent' setting.
2.1.240 (Claude Code)
```
```
AGENTS.md:271:- **Pack agent invocation.** Pack agents are invoked via `codex --agent
AGENTS.md:749:  the same way; pack agents are invoked via `codex --agent pack-<name>`.
pack-ops/PACK-AGENTS.md:94:codex --agent pack-architect
pack-ops/PACK-AGENTS.md:95:codex --agent pack-planner
pack-ops/PACK-AGENTS.md:96:codex --agent pack-coder
supporting-docs/SETUP-EXISTING.md:398:2. Run the coder via `./agent-run.sh codex --agent coder`.
supporting-docs/SETUP-NEW.md:468:| Implement | `./agent-run.sh codex --agent coder` |
maintenance-docs/TOOL-COMPARISON.md:67:| … `agent-run.sh codex --agent <name>` …
maintenance-docs/origins/…:769 · maintenance-docs/v11-implementation/…:201, :448, :908
```
```
(grep over scripts/ and .github/ : no output)
```

**Interpretation.** `--agent` is absent from Codex 0.145.0's option set and errors on both the root
and `exec` subcommands. It is present and documented in Claude Code 2.1.240. Three pack-side
operating-doc sites assert the Codex form as a bare command; the `supporting-docs/` and
`maintenance-docs/` hits are the client `agent-run.sh` wrapper form and history, not the same claim.
No validator, test, or workflow asserts on the string.

**Conclusion.**
- `codex --agent` is invalid in the installed Codex: **SUPPORTED.**
- `claude --agent` is valid: **SUPPORTED.**
- The three pack-side sites are a live false claim: **SUPPORTED.**
- No encoding surface in `scripts/` or `.github/` depends on the string: **SUPPORTED.**

---

### EE-5 — sandbox enforcement could not be observed in this environment

**Commands.**
```
codex sandbox -P narrow -C <scratch> /usr/bin/touch <scratch>/repo/sub/x.txt   ; echo $?
codex sandbox -P narrow -C <scratch> /bin/echo hello                            ; echo $?
codex sandbox --log-denials -P narrow -C <scratch> /bin/echo hello
```

**Output (captured).**
```
EXIT=134   (no stdout, no stderr)
EXIT=134   (no stdout, no stderr)
=== Sandbox denials ===
None found.
```

**Interpretation.** Exit 134 is SIGABRT. The harness itself runs (it printed the denials banner) but
every sandboxed child aborts, including `/bin/echo`, which has no filesystem dependency on the
configuration. This is nested-Seatbelt failure — this session's Bash already runs inside a macOS
sandbox — not a configuration error.

**Conclusion.** Codex sandbox enforcement was **not observed**: **NOT-SUPPORTED as a positive
finding**, and recorded as the explicit limit on EE-1's `[permissions]` conclusion and on OI-3.

---

### EE-6 — the dual-leg precondition bounds ITEM 2's population

**Commands.**
```
# idiom census, per file, over git-tracked per-check tests
for f in $(git ls-files 'scripts/tests/test-validate-pack-check-*.sh'); do
    grep -cE '"[^"]*" (not )?in (cap|captured|out|output|txt|text|stdout|msg)\b' "$f"; done
# AST classification of every check_* function by which emitters it calls
python3 - (AST walk over scripts/lib/validate_checks/*.py)
grep -n 'print(f\?"WARN' scripts/lib/validate_checks/*.py scripts/validate-pack.py
```

**Output (captured).**
```
per-check test files (git-tracked): 58
files matching the idiom (narrow, "in cap" only):  47
files matching the idiom (broadened, 8 capture var names):  52
total check_* funcs with fail or warn: 87
  with BOTH fail() and warn(): 3
   BOTH: boundary_refs.py  check_operating_doc_no_history
   BOTH: cross_bd.py       check_open_bd_structured_surface_field
   BOTH: session_state.py  check_session_state_fresh
warn() call sites: 8, across 6 of 21 modules
   boundary_refs.py 2 · core.py 1 · cross_bd.py 2 · migrator_docs.py 1
   session_state.py 1 · trinity_markers.py 1
direct WARN prints: scripts/lib/validate_checks/core.py:101:    print(f"WARN: {msg}")   [the emitter itself]
```
Registry mapping of the three:
```
scripts/validate-pack.py:1186  (65, "check_operating_doc_no_history", …, W)
scripts/validate-pack.py:1273  (78, "check_session_state_fresh", …, W)
scripts/validate-pack.py:1298  (81, "check_open_bd_structured_surface_field", …, W)
```

**Interpretation.** The idiom is widespread (52/58 files) but the defect requires a WARN leg, and only
3 of 87 check functions have one alongside `fail()`. `core.py:101` is the sole WARN emitter — no
check body bypasses it with a direct print — so the AST classification is complete, not a sample.

**Conclusion.** The candidate population is 3 checks / 3 test files, not 51-52 files:
**SUPPORTED.**

---

### EE-7 — the true defect count, HEAD vs WT

**Commands.**
```
W=$(mktemp -d); git archive HEAD | tar -x -C "$W"     # pristine HEAD, live tree untouched
python3 classify2.py "$W"        # HEAD
python3 classify2.py .           # WT
```
`classify2.py`: AST-collects, per `check_*` function, `F` = literals in `fail()` calls, `W` =
literals in `warn()` calls, `V` = literals in assignments; resolves each test file to its check via
`mod.check_*(` (fallback: loose `check_*` token ∩ known checks); flags any
`"…" [not] in (cap|captured|out|output)` clause whose substring is in `F∪V` **and** `W∪V`.

**Output (captured).**
```
TREE=<HEAD extraction>
  dual-leg checks: ['check_open_bd_structured_surface_field', 'check_operating_doc_no_history',
                    'check_session_state_fresh']
  assertions in dual-leg test files: 33
  FLAGGED (substring reachable from BOTH legs): 2
      test-validate-pack-check-81.sh | 'active design'
      test-validate-pack-check-81.sh | 'missing'

TREE=.  (working tree, W1 applied)
  dual-leg checks: [same 3]
  assertions in dual-leg test files: 40
  FLAGGED: 1
      test-validate-pack-check-81.sh | 'missing'
```
Whole-corpus classification for context (WT): 464 assertion clauses, `{'NEITHER': 322,
'FAILONLY': 135, 'WARNONLY': 7}`.

**Interpretation.** Two true instances at HEAD, both in one file, both against Check 81. One remains
at WT. Checks 65 and 78 contribute zero at either state. The 322 `NEITHER` clauses are fixture
strings (`"BD-901"`, `"2026-05-30"`, `"ZZZ-MATCHES-NOTHING-ZZZ"`), which is why §5.8 rejects a
substring-must-exist guard.

**Conclusion.** Defect population = 2 at HEAD, 1 at WT: **SUPPORTED.**

---

### EE-8 — runtime proof that the surviving clause is non-discriminating

**Command.** Drove `check_open_bd_structured_surface_field` in-process against a synthetic
`tempfile.TemporaryDirectory()` tree — one **non-active** open BD with **no** `File/Symbol` field,
`active[]` empty — replicating the test harness's own `run()` (REPO_ROOT patched, `failures`
saved/restored, stdout captured). The repo tree was never mutated.

**Output (captured).**
```
=== WARN-ONLY RUN (non-active BD, missing File/Symbol) ===
failure count: 0
'missing' in cap -> True
'WARN' in cap    -> True
--- captured ---
── Check 81: structured File/Symbol prereq for active-design BDs (BD-255) ──
WARN: backlog/BD-906.md — BD-906 (open, not yet in active design) has a bare/TBD/missing
`File/Symbol` field; structure it into a repo-relative path list before the architect stage so the
cross-BD collision scan can key on it (advisory only — NOT a gate failure; Check-48 warn idiom).
Per BD-255 design §3.3 C-i.
  OK: Check 81 — every active-design BD (0 in session-state `active[]`; …
```

**Interpretation.** `"missing" in cap` is satisfied with **zero** failures — by WARN output alone.
The T6 clause `"missing" not in cap` therefore cannot distinguish the FAIL leg from the WARN leg;
`fc < 1` carries the entire load, which is the defect exactly as W1 characterised it for
`"active design"`.

**Conclusion.** The clause at WT line 241 is a live non-discriminating assertion: **SUPPORTED.**

---

### EE-9 — the naive guard misses half the population; the `∪ V` form misses none

**Commands.** Two classifier variants over the same HEAD extraction:
```
classify.py   — FAIL set = literals inside fail() only; WARN set = literals inside warn() only
classify2.py  — FAIL set = fail() literals ∪ assigned literals; WARN set = warn() literals ∪ assigned
```

**Output (captured).**
```
classify.py  @ HEAD : {'NEITHER': 312, 'FAILONLY': 133, 'WARNONLY': 7, 'BOTH': 1}
                       BOTH: test-validate-pack-check-81.sh | 'active design'
                       ('missing' classified WARNONLY — MISSED)
classify2.py @ HEAD : FLAGGED 2 of 33  ->  'active design', 'missing'
classify2.py @ WT   : FLAGGED 1 of 40  ->  'missing'
```
Why the naive form misses it, from the check body:
```python
detail = "missing" if not fs_value else "bare/TBD/placeholder"
fail(f"… but its `File/Symbol` field is {detail} (no structured repo-relative path list). …")
```

**Interpretation.** `missing` reaches the FAIL output through an interpolated variable, so it is
absent from the `fail()` call's own literals. The naive guard finds 1 of 2 (50 % miss). Including
assignment literals on both sides finds 2 of 2. Over 33 clauses at HEAD and 40 at WT the `∪ V` form
produced **zero** false positives, so the required allowlist is **empty**.

**Conclusion.**
- Naive form: 50 % miss rate on the known population: **SUPPORTED.**
- `∪ V` form: 2/2 recall, 0 false positives, empty allowlist: **SUPPORTED** at these two tree states.
  Generalisation of the 0 % false-positive rate to future assertions is an extrapolation, not a
  measurement — it is bounded by the over-approximation's known error direction (false positives
  only), which is why it is safe to ship without an allowlist constant.

---

### EE-10 — runtime cost, budget headroom, and the count surfaces

**Commands.**
```
/usr/bin/time -p python3 scripts/validate-pack.py
python3 - (timed: ast.parse over scripts/lib/validate_checks/*.py ; git ls-files over 2 prefixes)
for i in 1..5; do /usr/bin/time -p python3 classify2.py . ; done
grep -oE "^\s*\(([0-9]+), \"check_" scripts/validate-pack.py | grep -oE "[0-9]+" | sort -n | tail -3
grep -n "^CHECK_REGISTRY_EXPECTED_COUNT" scripts/lib/validate_checks/core.py
grep -n "numeric ID = " scripts/lib/validate_checks/core.py
```

**Output (captured).**
```
PASSED — all checks clean          real 1.92   user 1.53   sys 0.34
parse all 21 check modules: 37.0 ms      total bytes: 905,129
parse only the 6 warn-bearing:  15.7 ms  bytes: 394,225 (43.6%)
read all 21 (pre-filter scan):   0.5 ms
git ls-files (2 prefixes, 319 paths): 11.7 ms
prototype wall clock: real 0.10 / 0.10 / 0.10 / 0.10 / 0.10
highest registered check number: 92, 93, 94
scripts/lib/validate_checks/core.py:210:CHECK_REGISTRY_EXPECTED_COUNT = 91
scripts/lib/validate_checks/core.py:205:# numeric ID = 94.)
```

**Interpretation.** Baseline battery is 1.92 s against a 10.0 s hard-FAIL budget. The guard's
in-process cost is ≤60 ms (37.0 + 11.7 + file reads), 3 % of the 2.0 s per-check WARN budget and
0.6 % of the total; with OI-7's pre-filter, ≤35 ms. The lock-step count surfaces are the registry in
`validate-pack.py`, the constant at `core.py:210`, the ledger comment at `core.py:205`, and
`README.md:83`.

**Conclusion.** The guard fits both budgets with wide margin: **SUPPORTED.** Check number 96 and
constant 93 are **PARTIAL** — correct only if W3 lands Check 95 first, which is why OI-6 recommends
re-deriving at wave start.

---

### EE-11 — what W1 actually changed, and the mid-session tree movement

**Commands.**
```
git rev-parse --short HEAD ; git status --porcelain ; git worktree list
git diff -- scripts/tests/test-validate-pack-check-81.sh \
            scripts/tests/test-validate-pack-check-82.sh | grep -E "^[+-].*in cap"
git show HEAD:scripts/tests/test-validate-pack-check-81.sh | grep -n 'active design|"missing"'
```

**Output (captured).**
```
e8ea69e
 M pack-ops/session-state.json
 M scripts/lib/validate_checks/cross_bd.py
 M scripts/tests/test-validate-pack-check-81.sh
 M scripts/tests/test-validate-pack-check-82.sh
/…/optiquity-ai-agent-config-pack                                    e8ea69e [main]
/…/.claude/worktrees/agent-a6993edf7db89c0dc                         e8ea69e [worktree-…]
/…/.claude/worktrees/agent-abc719f7e784a0d5e                         e8ea69e [worktree-…]
```
```
-if fc < 1 or "BD-901" not in cap or "active design" not in cap:
+if fc < 1 or "BD-901" not in cap or "is in active design (session-state" not in cap:
+if fc < 1 or "BD-910" not in cap or "is in active design (session-state" not in cap:
+if fc != 0 or "WARN" not in cap or "BD-912" not in cap:
+if fc < 2 or "BD-913" not in cap or "BD-914" not in cap:
+if fc != 0 or "BD-915" in cap:
+elif "WARN" not in cap or ".claude/agents/pack-planner.md" not in cap \
```
```
HEAD:194:if fc < 1 or "BD-901" not in cap or "active design" not in cap:
HEAD:221:if fc < 1 or "BD-906" not in cap or "missing" not in cap:
WT  :214:if fc < 1 or "BD-901" not in cap or "is in active design (session-state" not in cap:
WT  :241:if fc < 1 or "BD-906" not in cap or "missing" not in cap:
```

**Interpretation.** My first `git status` in this session reported one modified file; the same
command later reported four. HEAD never moved. W1's work is applied to the canonical checkout and
uncommitted. The diff shows exactly **one** `-`/`+` assertion pair — the `"active design"` repair;
every other `+` line is a newly added test leg (`BD-910`…`BD-915`). Line 221/241's `"missing"` clause
is byte-identical at both states.

**Conclusion.**
- W1 repaired exactly one assertion clause: **SUPPORTED.**
- The brief's "Both were fixed to a discriminating substring" is **NOT-SUPPORTED**; a second
  pre-existing non-discriminating clause survives.
- W1's patch landed in the canonical tree during this session: **SUPPORTED.**

---

## 10. Rules-Applied Verification Block

One row per rule named in this spawn's "Rules in force" block. Evidence is the actual command result,
path, count, or quoted line — quoted, not summarised. `AMBIGUOUS` is not an allowed terminal state.

### agents-never-commit
**Evidence.** No state-changing git verb was issued. Verbs used, exhaustively: `git rev-parse`,
`git status`, `git ls-files`, `git grep`, `git log`, `git show`, `git diff`, `git worktree list`,
`git reflog`, `git archive`. Post-work state, unchanged from my first measurement in every respect
except W1's externally-applied patch:
```
e8ea69e
 M pack-ops/session-state.json
 M scripts/lib/validate_checks/cross_bd.py
 M scripts/tests/test-validate-pack-check-81.sh
 M scripts/tests/test-validate-pack-check-82.sh
git reflog -3:  e8ea69e HEAD@{0}: commit: fix: v11 — BD-288 RO agent capability grants …
                47f8467 HEAD@{1}: …            cfd5b02 HEAD@{2}: …
```
No new reflog entry, no index change, no ref change. `git archive HEAD | tar -x -C $(mktemp -d)` was
used for the HEAD comparison specifically to avoid `git checkout`/`git stash`.
**Conclusion: COMPLIANT.**

### per-action-approval-sub-agents
**Evidence.** No `rm`, `rm -rf`, `rmdir`, `unlink`, `git rm`, `find … -delete`, `mv`, `shred`, or
`truncate` was run at any point. All scratch work went to `mktemp -d` roots
(`/var/folders/mt/…/T/tmp.LNx7eIqTwz`, `tmp.PeSHwkEWXN`, `tmp.tb0lN2tfL4`) and to the session
scratchpad; none was deleted by me. My owned dir holds exactly the one deliverable:
```
/Users/david/.local/state/optiquity-pack-handoff/bd288-arch3-20260824-104225/
  ARCHITECTURE-BD-288-SANDBOX-ASSERT.md
```
No other agent's handoff dir was written to; `bd288-planreconcile-20260823-215731/` was read only.
Neither live worktree was entered.
**Conclusion: COMPLIANT.**

### empirical-evidence-blocks
**Evidence.** §9 carries EE-1 … EE-11, each with the command, captured output, the measurement point
(HEAD `e8ea69e`, 2026-08-24), interpretation, and an explicit SUPPORTED / NOT-SUPPORTED / PARTIAL.
Four conclusions are deliberately **not** SUPPORTED: EE-2 (sole-mechanism claim, NOT-SUPPORTED),
EE-3 (the "never loaded" inference, PARTIAL), EE-5 (enforcement, NOT-SUPPORTED as a positive
finding), EE-10 (check numbering, PARTIAL). EE-11 records a NOT-SUPPORTED finding against the
spawn brief itself.
**Conclusion: COMPLIANT.**

### ci-guard-measure-then-bound
**Evidence.** §5.3 discharges all five steps for Check 96 with measured values, and the five-step
table is reproduced against real numbers rather than described: (1) complete occurrence list at two
tree states — 2 at HEAD, 1 at WT (EE-7); (2) every occurrence categorised — 2 STRIP, 0 KEEP;
(3) fix-recipes — `"active design"` landed in W1, `"missing"` is §5.1 F1; (4) allowlist sized to the
legitimate set, which is **empty**, so no allowlist constant ships; (5) projected post-fix state
verified — `FLAGGED: 0` over 40 clauses. Candidate set is `git ls-files scripts/lib/validate_checks
scripts/tests` with a lenient SKIP off a work tree (§5.2 step 1). The guard catches the
absence-of-backing form by construction — it fires on a declared assertion whose discriminating power
is absent. §5.8 records two candidate guards **rejected on measurement** (the 52-file sweep; the
substring-must-exist guard at a measured ~70 % false-positive rate).
**Conclusion: COMPLIANT.**

### declare-verify-backing
**Evidence.** Applied in three directions. (a) Diagnosis: both items are instances — ITEM 1 is a
declared restriction with no mechanical backing (EE-1), ITEM 2 an assertion with no discriminating
power (EE-8). (b) Self-application: §2.7 and §5.5 specify how each of my own fixes is proven to bite,
including P2, the probe that distinguishes the working guard from the naive one, and P3, which proves
the guard is not hard-coded to the check that motivated it. (c) Refusal to declare without backing:
§1.5 and OI-3 decline to design on the `[permissions]` model precisely because its enforcement was
not observed.
**Conclusion: COMPLIANT.**

### verify-availability-not-existence
**Evidence.** `codex --version` → `codex-cli 0.145.0` at `/opt/homebrew/bin/codex`, npm-vendored
binary confirmed via `codex doctor`. `claude --version` → `2.1.240`. The `--agent` flag was tested for
**usability**, not documented existence, on the actual installed binary — `error: unexpected argument
'--agent' found` on both `codex` and `codex exec`, and absent from the complete long-option list
(EE-4). Conversely, where I could only establish existence and not usability — the `[permissions]`
model — EE-1's conclusion is downgraded to PARTIAL and EE-5 records why:
`EXIT=134` (SIGABRT) for every sandboxed child including `/bin/echo`.
**Conclusion: COMPLIANT.**

### ci-check-runtime-compounding
**Evidence.** Budgets named and measured against: 10.0 s total hard-FAIL, 2.0 s per-check WARN,
current baseline `real 1.92`. Guard cost decomposed and measured: 37.0 ms AST parse (905,129 bytes) +
11.7 ms `git ls-files` (319 paths) + <5 ms file reads = ≤60 ms — 3 % of the per-check budget, 0.6 %
of the total (EE-10). No filesystem walk, no subprocess per entry, exactly one `git` subprocess. The
cost is O(check-module bytes) and does **not** scale with the 464-clause census — only 3 files are
read. OI-7 surfaces the one growing term and recommends a measured pre-filter cutting 37.0 ms → 15.7 ms.
**Conclusion: COMPLIANT.**

### enumerate-encoding-surfaces
**Evidence.** Two tables. §2.5 for ITEM 1 — 6 edited files plus three rows recorded as **empty after
measurement** (`CLAUDE.md`/`GEMINI.md`; `scripts/` validators; `scripts/tests/`; `.github/`), backed
by `grep -rn "codex --agent" scripts/ .github/` returning no output (EE-4). §5.6 for ITEM 2 — the
check body, its test, the registry tuple, `CHECK_REGISTRY_EXPECTED_COUNT` (`core.py:210`), the
`core.py:205` ledger comment, the `README.md:83` count prose, and the shard plan recorded as
**no-edit** because Check 42's coverage is disk-derived. Empty surfaces are listed as empty rather
than omitted, which is the point of the rule.
**Conclusion: COMPLIANT.**

### dependency-direction-placement
**Evidence.** Nothing proposed here is dual-use or crosses the boundary. ITEM 1 edits only pack-side
files (`.codex/agents/`, `pack-ops/`, pack-root `AGENTS.md`) and §2.1 **explicitly excludes** the
client-shipped `supporting-docs/SETUP-NEW.md:468` and `SETUP-EXISTING.md:398` hits from scope. ITEM 2
edits only `scripts/`. No `_SANCTIONED_PACK_SIDE_SHIPPED` entry is proposed; the set is untouched.
OI-3 flags that any `[permissions]` migration would reach `project-template/` and must be treated as
a separate project-side surface, never a mirror of the pack-side change.
**Conclusion: COMPLIANT.**

### boundary-investigation-precedes-pack-defaults (P-missed-7)
**Evidence.** I propose **no** project-side change. Where a project-side surface came into view I
investigated rather than patterned: `project-template/.codex/config.toml:64-130` was read to establish
how Codex registration actually works (EE-2) — a read, not an edit — and OI-3 states explicitly that
a client-side `[permissions]` migration "is a project-side surface and must be investigated on its own
terms, never patterned off the pack-side fix". §2.1 keeps the client `agent-run.sh` claim out of scope
because it is a different mechanism on a different surface.
**Conclusion: COMPLIANT.**

### public-bound-no-leak
**Evidence.** This document is a reference doc in a handoff dir — not `project-template/`,
`supporting-docs/`, `.github/`, the repo-root `README.md`, or the pack-root trinity — so it is not a
Check-93 surface. Independently, it contains no target-project name and no domain vocabulary: the
only proper nouns are tool names (Codex, Claude Code, Antigravity), pack file paths, and BD numbers.
No proposed edit adds a name or vocabulary token to any client/public surface; §2.1 in fact **removes**
scope from `supporting-docs/`.
**Conclusion: COMPLIANT.**

### operating-docs-no-history-no-bloat
**Evidence.** Applies to what I propose *writing into* operating docs, not to this reference doc.
§2.2's replacement comment is six lines, mechanism-only, with zero dates, SHAs, BD-provenance, or
past-action narration, and it describes only what currently exists. §2.1's OI-1 options are all
framed as "state only what is true today", and option (c) is **rejected** on the grounds that a hole
invites a re-guess — terseness is not the same as absence. OI-8 weighs one-copy-vs-four explicitly
against this rule. No proposed operating-doc text mentions a deferred or unimplemented feature: OI-2
and OI-3 are decisions recorded *here*, not text destined for an operating doc.
**Conclusion: COMPLIANT.**

### skill-agent-maintenance-mechanical
**Evidence.** I am the escalation this rule specifies for ITEM 1 — a structural question about agent
capability grants routed to an architect rather than folded into a mechanical fix. §2.6 routes the
resulting `pack-chat-only` edits through a Pack-Chat-scoped `pack-coder` under the bounded cycle
rather than a direct edit. The client `x-` contract is untouched — nothing here reaches
`project-template/` agent files. §2.4 explicitly preserves the `**Read-only.**` mandate header that
Check 52 binds to, so the two-class model is unchanged.
**Conclusion: COMPLIANT.**

### graph-first-context
**Evidence.** Discipline was **partially** met, and I record the failure rather than paper over it.
I ran grep/AST discovery first on both items and only afterwards ran the graph to corroborate. Query
1 (ITEM 2's discovery question) returned the correct and complete answer:
```
Traversal: BFS depth=2 | Start: ['warn()','warn()','warn()'] | 106 nodes found
NODE check_open_bd_structured_surface_field() [src=…/cross_bd.py loc=L714]
NODE check_operating_doc_no_history()         [src=…/boundary_refs.py loc=L3758]
NODE check_session_state_fresh()              [src=…/session_state.py loc=L194]
NODE check_trinity_marker_wellformed()        [src=…/trinity_markers.py loc=L370]
```
That set is **identical** to the AST measurement in EE-6 (the three dual-leg checks, plus the one
warn-only check), so the graph surfaced no candidate my census missed — but it would have found them
faster, and running it first is what the rule requires. Query 2 (ITEM 1's Codex-surface question)
returned nothing relevant (`Start: ['Agent','Codex','PACK'] | 20 nodes`, resolving to
`maintenance-docs/origins/` prose and unrelated test fixtures), so **G2 fallback** applied and
grep/Read carried it — recorded honestly rather than as a graph success. The injected absolute path
`/Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json` was used verbatim with
`--budget 1500 --backend claude-cli`; I never recomputed it from my own toplevel. Consistent with the
brief's warning, I did **not** treat any empty graph result as proof of absence — every negative in
this document (no `.codex/config.toml`, no validator asserting `codex --agent`, zero KEEPs) rests on
a `git ls-files`/`git grep`/AST measurement, never on a graph miss.
**Conclusion: VIOLATED — ordering.** Discovery was grep-first with the graph run afterwards as
corroboration, where the rule requires graph-first for P1 discovery. Impact on the findings:
**none, and measured** — query 1's result set is set-identical to the AST census, and query 2 fell
through to G2 legitimately.

### deferral-is-scope-creep / no-deferral-without-user-direction
**Evidence.** Zero deferrals. No follow-on BD, no phase 2, no v11.1 item, no "record it and move on"
is proposed anywhere. Every option in every open item lands inside BD-288 and inside v11.0, including
the two researcher passes (OI-1(b), OI-3(c)), which are in-BD spawns. The one sequencing decision
that could be mistaken for a deferral — F1 landing in W6 rather than W1 (§6.3, OI-4) — is defended on
**LOGICAL FIT** with file evidence: F1 is F2's fix-set and `ci-guard-measure-then-bound` step 5
requires the guard verified against the post-fix tree, a property that is self-contained only if they
share a commit. OI-2's recommendation to leave the Codex surface unregistered is a decision that
there is no work item, not a decision to postpone one.
**Conclusion: COMPLIANT.**

### open-item-surfacing
**Evidence.** Eight open items (OI-1 … OI-8), each with context, my own enumerated options, and an
evidence- or logic-based recommendation. Recommendations are drawn from measurements in §9, never
from memory. One item — **OI-8** — carries an explicit *"No recommendation can be given between (a)
and (c)"* with the reason the evidence does not discriminate, while still ruling out (b) on evidence.
No recommendation defers or delays work to another or a new BD.
**Conclusion: COMPLIANT.**

### memory-not-an-ssot
**Evidence.** Every rule and contract cited was re-read from the live in-repo SSOT during this task:
`CLAUDE.md` § "Pack memory" (the trinity rules, the pack-chat-only list, the commit-scope keyword
table), `pack-ops/PACK-AGENTS.md` (§ "Two agent classes" at 158-185, § "How to invoke pack agents" at
49-96), `pack-ops/PACK-CHAT.md` (the handoff-root definition at 350-365), `backlog/BD-288.md` (the
full entry), `backlog/_rules.md` (the stream contract, incl. the `File/Symbol` requirement cited in
§6.5), `README.md:83` (the version-table count prose). No pack or project rule was sourced from a
CLI memory. No state was written to a memory; the sole artifact is this document.
**Conclusion: COMPLIANT.**

### bounded-review-fix-cycle
**Evidence.** §7 sizes both proposed waves against the 2+1 budget, and does so by **remaining
discovery** rather than file count, as instructed: W5 is 6 files / 2 distinct edits with zero
in-wave discovery but **one blocking pre-wave decision** (OI-1), stated as a gate on the spawn; W6 is
6 files with near-zero remaining discovery because "every number this wave will assert has already
been produced by a run recorded in §9". §7.3 names the three conditions that would break the fit
(spawning W6 before W3, renumbering, and treating ITEM 2 as a 51-file sweep).
**Conclusion: COMPLIANT.**

### rules-applied-verification-block
**Evidence.** This section, covering every rule in the spawn's "Rules in force" block, each with
quoted evidence and a terminal conclusion. One conclusion is **VIOLATED** (`graph-first-context`,
ordering) rather than softened, and its measured impact is stated. No row carries empty evidence and
no row is left AMBIGUOUS.
**Conclusion: COMPLIANT.**

### spawn-unique-naming
**Evidence.** Spawn name `architect-bd288-sandboxassert` — shape `<role>-<bd>-<facet>` =
`architect` / `bd288` / `sandboxassert`, lowercase kebab, 29 characters, matching
`^[a-z0-9][a-z0-9-]{2,47}$`. It is carried in this document's header and is distinct from every other
live spawn in the session roster (`architect-bd288-adversarial`, `-fullscope`, `-guardbite`,
`-reconcile`).
**Conclusion: COMPLIANT.**

---

## 11. Summary — what lands

| # | Wave | Item | Files | Depends on | Gate |
|---|---|---|---:|---|---|
| **W5** | ITEM 1 — invocation-claim correction (D1) + sandbox-comment correction (D2) | 1 | 6 | — (parallel now) | **OI-1 must close first** |
| **W6** | ITEM 2 — F1 (the live clause) + F2 (Check 96, empty allowlist) | 2 | 6 | **W3** (registry/count/ledger/README lock-step) | — |

**Totals.** 1 new check. 1 assertion fix. 3 false-claim sites corrected. 1 comment corrected across
4 byte-identical carriers. **Allowlist growth: zero** — Check 96 ships without an allowlist constant,
because the legitimate KEEP set measured empty. 5 guard probes (P1–P5), of which P2 is the one that
distinguishes the working design from the naive one. **Zero deferrals. No new BD. No phase 2. No
v11.1 item.**

**What did not survive measurement.** The `writable_roots` narrowing (mechanically impossible —
EE-1). A 51-file assertion sweep (the real population is 2 — EE-6, EE-7). The naive form of the
guard (50 % miss rate — EE-9). A substring-must-exist guard (~70 % false-positive rate — §5.8). Each
is recorded with its evidence so it is not re-proposed.

END OF ARCHITECTURE-BD-288-SANDBOX-ASSERT
