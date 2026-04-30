# V10-PHASE-3B-DESIGN — PM chat kickoff auto-discovery + install-check

## Part 0 — Status + Linkage

**STATUS: DRAFT.** Architecture session output, awaiting pack chat
review and approval. No implementation begins until this design is
approved.

**Backlog item:** BD-047 (Unblocked; v10.0 ship-blocker per developer
decision 2026-04-24).

**Predecessor:** Phase 3-AC (capability-addition mechanism) —
Gate E2 passed. See `V10-DESIGN.md` Part 5 §5.14, METHODOLOGY.md
Procedure 6, `scripts/add-capability.sh`. Phase 3-B mirrors the
script-plus-PM-chat-procedure split discipline established there.

**Successor:** Phase 4 (final v10.0 release pass) — Gate F.

**Sequencing constraint:** Planner pass must run after this design is
approved. Implementation is 2–4 commits (see Part 12).

**Files this design touches at implementation time:**

- `project-template/docs/pack/prompts/pm-chat.md` — `Variant: kickoff`
  body (single-file edit; no trinity propagation needed).
- `supporting-docs/SETUP-NEW.md` — Steps 5, 6, 7, 8.
- `supporting-docs/SETUP-EXISTING.md` — Steps 5, 6.
- (Possibly) `project-template/docs/pack/PM-CHAT.md` — one new
  Behavioral rule clarifying the kickoff capability declaration. Only
  if the planner concludes the rule does not fit inside the kickoff
  variant itself.

**Files this design does NOT touch:**

- `scripts/init-project.sh`, `scripts/add-capability.sh`,
  `scripts/lib/detect.sh` — see Part 9.
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (project-template trinity) —
  no project-rule changes; trinity rule preserved by silence.
- `METHODOLOGY.md` — no new procedure; kickoff lives in the prompt
  variant where Procedure 6 patterns are mirrored, not duplicated.
- `validate-pack.py` — no new structural rules; no schema change.

---

## Part 1 — Problem Statement

`SETUP-NEW.md` Steps 5–8 and `SETUP-EXISTING.md` Steps 5–6 describe
manual copy/paste work that the developer must perform between command
output and target files:

| Step (NEW) | Manual work |
|---|---|
| 5 | Discover Xcode scheme via `xcodebuild -list`; discover simulator via `xcrun simctl list devices available`; paste both into `scripts/validate.sh`, `scripts/test.sh`, `.claude/settings.json` env block; paste `SWIFT_SOURCE_DIRS` into `scripts/format.sh` for non-SPM layout |
| 6 | `brew install swift-format` |
| 7 | `brew install bufbuild/buf/buf swift-protobuf grpc-swift`; optional `uv add grpcio-tools grpcio grpcio-status grpcio-reflection`; example `./scripts/proto-gen.sh` invocation |
| 8 | `cp` machine-level Xcode companion files to `~/Library/Developer/Xcode/CodingAssistant/...` |

`SETUP-EXISTING.md` Steps 5 and 6 cover the same Xcode scheme + Xcode
companion work.

This work is mechanical: every value is discoverable by a shell
command, every install is one `brew install`, every edit is a
deterministic substitution into a known file at a known anchor.
Nothing in this work needs developer judgment beyond approval.

The current model treats the developer as a copy/paste executor
between two CLI windows. This violates the principle (BD-047
Description) that the developer is the decision-maker, not the
mechanical step.

The PM chat is already running on a Bash-capable surface for the
common case (Claude Code CLI, Codex CLI, Gemini CLI, Claude Desktop
with Desktop Commander). It can do this work behind confirmation
gates and surface only the decisions to the developer. On surfaces
without shell capability (Claude Web without Desktop Commander,
ChatGPT Web), it must fall back cleanly to the existing manual
instructions.

---

## Part 2 — Goal + Success Criteria

**Goal.** The PM chat's `kickoff` variant executes the SETUP Steps
5–8 / 5–6 work behind confirmation gates on Bash-capable surfaces,
falls back to manual instructions on non-Bash surfaces, and surfaces
exactly the same decisions to the developer in either mode.
The developer approves every auto-discovered value and every write or
install action before it happens.

**Success criteria.** This design must answer six questions, each with
a defended decision and at least one rejected alternative recorded in
Part 13:

1. **Cross-tool parity** — how do the four Bash-capable surfaces
   differ in shell-execution model? Does the fifth surface require a
   structural fallback? (Part 3.)
2. **Capability detection** — how does kickoff detect Bash capability
   without running a probe that fails on non-Bash surfaces? (Part 4.)
3. **User interaction model** — auto-run-then-surface-choice vs.
   ask-first-then-run; can both coexist? (Part 5.)
4. **Error branches** — explicit behavior + visible information for
   nine failure / ambiguity conditions. (Part 6.)
5. **Variant structure** — single kickoff variant with conditional
   segments vs. split variants per project type? (Part 7.)
6. **Confirmation-gate pattern** — a single text-only prompt/response
   form usable identically across all four Bash-capable surfaces.
   (Part 8.)

Plus the cross-cutting requirements:

- **Scope boundary.** Why no script change is warranted. (Part 9.)
- **SETUP-NEW.md / SETUP-EXISTING.md update strategy.** (Part 10.)
- **Testing strategy.** (Part 11.)
- **Commit-sequence outline for the planner pass.** (Part 12.)
- **Open questions deferred to planner pass.** (Part 14.)

---

## Part 3 — Cross-tool Parity (Q1)

### 3.1 Five surfaces, three categories

Per `TOOL-COMPARISON.md` Part 1 file-write/MCP rows and the existing
`PM-CHAT.md` four-surface treatment, the surfaces fall into three
categories by shell-execution model:

| Category | Surfaces | Shell mechanism |
|---|---|---|
| **A. Native shell** | Claude Code CLI; Codex CLI; Gemini CLI | First-class shell tool with per-command approval. The agent runs commands directly and observes stdout/stderr in-band. |
| **B. MCP-mediated shell** | Claude Desktop with Desktop Commander (or any MCP server exposing `execute_command`) | Shell calls go through an MCP tool. Output is returned as a tool result. Per-call approval is enforced by the MCP client. |
| **C. No shell** | Claude Web (without Desktop Commander); ChatGPT Web | No mechanism to execute shell. The PM chat can only read files via GitHub connector and emit text. |

Categories A and B are the **Bash-capable surfaces** referenced in the
prompt. Category C requires the structural fallback.

### 3.2 Per-surface execution-model differences within Category A

Category A surfaces are not byte-identical in shell behavior. The
kickoff design must accommodate the lowest common denominator:

- **Claude Code CLI** — Bash tool, sandboxed by `.claude/settings.json`
  permissions. Approves each command unless the command pattern matches
  a pre-allowlisted entry. `xcodebuild`, `xcrun`, `brew`, `cp` are not
  by default allowlisted and will prompt.
- **Codex CLI** — workspace-write sandbox with `--ask-for-approval
  on-request` (TOOL-COMPARISON Part 4). `xcodebuild -list` and
  `xcrun simctl list devices available` are read-only and run within
  workspace bounds. **`brew install` writes outside the workspace
  sandbox** (`/opt/homebrew` or `/usr/local`) and triggers an explicit
  escalation prompt. The kickoff design must surface this as part of
  the approval flow rather than rely on silent escalation.
- **Gemini CLI** — shell tool with per-command approval in default
  mode. Plan mode (`/plan`) blocks shell entirely; the kickoff
  variant must instruct the developer not to be in plan mode for
  kickoff (single sentence in the prompt is sufficient).

### 3.3 Category B (Desktop Commander) caveats

Desktop Commander is not part of Claude Desktop by default — it
requires user-side MCP install. Kickoff cannot assume it is present
on a Claude Desktop surface; presence must be declared (Part 4).

When present, Desktop Commander's `execute_command` returns
combined stdout+stderr as a string with an exit-code envelope. The
kickoff prompt parses this output the same way it parses native
shell output — no special wrapping needed.

### 3.4 Category C structural fallback requirement

Surfaces in Category C cannot run any of the SETUP commands. The
kickoff variant must emit, on declaration of "no shell," the same
manual instructions currently in `SETUP-NEW.md` Steps 5–8 /
`SETUP-EXISTING.md` Steps 5–6 — verbatim, deterministically, in one
block, with all the discoverable values left as `<DISCOVER>` tokens
the developer fills in.

This is structurally identical to the current SETUP guidance, so the
fallback path is:

> "Run these commands locally and report the values back; I will
> generate the exact edits for you to paste."

The PM chat then composes the `XCODE_SCHEME=...` line from the
developer-reported value and emits the diff for paste. The developer
performs the file edit by hand (or asks Claude/ChatGPT for a "find
this line, replace with this line" instruction).

### 3.5 Trinity-symmetry implications

`pm-chat.md` lives in `docs/pack/prompts/` — single file, not
trinity-replicated. The kickoff variant's behavior must read the
**same** in any host, but the file itself is one file. Trinity
symmetry is not threatened by any of the design moves below.

If the planner concludes a Behavioral Rule must be added to
`PM-CHAT.md` to formalize the kickoff capability declaration,
`PM-CHAT.md` is also single-file (not trinity); still no symmetry
issue. The kickoff design **must not** put surface-detection rules
into trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) — those files
are project-rule files, not session-mode files.

---

## Part 4 — Capability Detection (Q2)

### 4.1 The probe-detection trap

A naïve detection model — "kickoff runs `xcodebuild -list` and
infers shell capability from whether it succeeds" — fails on
Category C surfaces because the call simply never executes; the model
sees no result and cannot distinguish "Bash-capable, command failed"
from "no Bash, prompt ignored." Worse, on Category B without Desktop
Commander, a tool call may produce an MCP-error string the model
might mistake for a shell error.

### 4.2 Decision: declarative-via-question, not probe-based

The kickoff variant **asks the developer once, in plain English,
near the top of the prompt**:

> "I am about to run a sequence of read-only discovery commands and
> propose installs and file edits for your approval. Confirm one of:
>
> - **shell** — I have shell access on this surface (Claude Code CLI,
>   Codex CLI, Gemini CLI, or Claude Desktop with Desktop Commander
>   enabled). Run the discovery commands.
> - **manual** — I have no shell on this surface (Claude Web, ChatGPT
>   Web). Print the manual instructions and I will run them locally
>   and report values back.
>
> Reply with the single word `shell` or `manual` before continuing."

The developer's reply is the source of truth. There is no probe.

This converges with how the existing `kickoff` variant already names
**Surface** information — the prompt already asks the developer to
fill placeholders before pasting — but it does so via a free-text
reply rather than a placeholder, because:

- Placeholders are filled before paste; the developer chooses surface
  at paste time on a per-session basis.
- Many developers will paste the kickoff into more than one surface
  during a project (Claude Web for context, Claude Code CLI for
  hands-on work). The reply-based form does not embed a surface
  choice into the pasteable text.
- A free-text reply works identically on every surface — it cannot
  fail, cannot partially execute, cannot leak.

### 4.3 Override and recovery

The developer may type `manual` even on a Bash-capable surface (e.g.,
they want to read the planned commands first without granting
execution). The PM chat must honor the choice — manual mode degrades
to printing instructions, which is harmless on any surface.

The developer may switch mid-kickoff: "stop, I want to run those
manually." The PM chat treats this as a re-declaration to `manual`
from that point onward. No prior state is invalidated; commands
already run cannot be unrun.

### 4.4 Why not detect by reading the host name

Some hosts expose their identity (Codex CLI prints a banner; Gemini
CLI's `GEMINI.md` is auto-loaded; Claude Code CLI sets
`CLAUDE_CODE_*` env vars). A "look at your environment" detection
would work for Category A but offers no signal for Category B
(Desktop Commander presence is per-install, not per-host) and no
signal at all for Category C. Detection would be partial; the
declarative model is uniform.

---

## Part 5 — Interaction Model (Q3)

### 5.1 The two options

- **(a) Auto-run silently, surface choice.** Kickoff runs all
  read-only discovery commands without asking, then surfaces the
  results: "Two schemes found — pick one."
- **(b) Ask first, then run after approval.** Kickoff says "May I
  run `xcodebuild -list`?" before each command.

### 5.2 Decision: (b), with batched approvals for read-only discovery

Pure (a) is unacceptable on Category A surfaces — Codex CLI's
sandbox prompt and Claude Code CLI's per-command approval will
already pause the agent at every command, so "silent" is fictional
in practice. Pure (b) is unacceptable for friction — asking
permission for `xcodebuild -list` and `xcrun simctl list devices
available` separately is two confirmations for one logical step.

The model is **batched approval per logical group**:

| Group | Approval form |
|---|---|
| **Read-only discovery** (`xcodebuild -list`, `xcrun simctl list`, `which swift-format`, `which buf`, `which brew`, `command -v`, `cat .claude/settings.json` reads, `ls` of `~/Library/Developer/Xcode/...`) | One approval for the whole group; the prompt lists every command in advance |
| **Each install** (one `brew install <pkg>` per approval) | Per-install approval — install impact differs per package |
| **Each file edit** | Per-file approval — preview the diff before write |
| **Each machine-level `cp`** (Xcode companion files) | Single approval for the whole companion-files batch (one logical "install Xcode companion files for this machine" decision) |

### 5.3 Why the groups are not collapsed further

- One mega-approval for the entire kickoff is a No: the developer
  loses the ability to skip a single install (e.g., "no swift-format,
  I use a different formatter") without restarting the whole flow.
- One approval per command is a No: the friction tax destroys the
  point of automation.
- Grouping by **side-effect class** (read-only / install / write /
  machine-level) maps to the developer's mental model of risk.

### 5.4 Quiet vs. explicit: do they coexist?

No. There is no value in a "quiet mode" that runs reads silently and
asks for writes — the per-command host approvals on Category A
already ensure the developer sees every command. The kickoff design
adopts a single mode (explicit, batched) and relies on the host's
own approval mechanism to mediate quietness if the developer chooses.

If a developer wants to run the kickoff non-interactively, the right
escape hatch is the **manual** declaration in Part 4 — manual mode is
the "I'll run it myself" mode, not a silent-execute mode.

---

## Part 6 — Error Branches (Q4)

For each condition the kickoff must specify exactly what happens and
what the developer sees. This is the contract the kickoff variant's
text encodes.

| # | Condition | Detection | PM chat behavior | What developer sees |
|---|---|---|---|---|
| 1 | **Xcode not installed** (project is not Apple) | `xcodebuild -version` exits non-zero; or kickoff skips Apple branch entirely if the trinity files were filled with a non-Apple platform | Skip the entire Apple-conditional segment. Do not propose `brew install swift-format`. Do not offer Xcode companion files. | "No Xcode detected — skipping Apple-only steps." Single line. Continues to the next applicable group (e.g., gRPC/Python). |
| 2 | **One scheme detected** | `xcodebuild -list` parses to exactly one scheme name | Auto-fill the single value; surface it for confirmation in the same prompt that proposes the file edits. No separate "is this right?" round-trip. | "Scheme `MyApp` (only one found) — used as `XCODE_SCHEME`. Approve the edits below to commit it." |
| 3 | **Multiple schemes** | `xcodebuild -list` parses to ≥2 scheme names | Present a numbered list; ask the developer to reply with the number or the name. Do not present an interactive menu (unsupported on Category B). | `Schemes found:` `  1. MyApp` `  2. MyAppTests` `  3. MyAppExtension` `Reply with the number (1–3) or the scheme name.` |
| 4 | **No simulators available** | `xcrun simctl list devices available` returns empty for all runtimes | Fall back to `XCODE_DESTINATION="platform=macOS"` if the project is macOS-only; otherwise, ask the developer to specify a destination string and offer to run `xcrun simctl list runtimes` to help diagnose | "No simulators available. If this is a macOS project, I can use `platform=macOS`. Otherwise, reply with a destination string or say `diagnose` to inspect available runtimes." |
| 5 | **`brew` not installed** | `command -v brew` returns nothing | Do not attempt installs. Print Homebrew install URL and the exact `brew install` lines the developer must run. Then continue to non-brew steps. | "Homebrew not installed. Install from https://brew.sh and re-run kickoff (or skip the formatter and proto-gen tooling for now)." |
| 6 | **Required brew tool missing** | `command -v swift-format` (etc.) returns nothing | Propose `brew install <pkg>` as a per-install approval (Part 5). On `skip`, record the skipped tool and proceed; format/proto scripts will warn at runtime per current design. | Per-install confirmation prompt (Part 8 form). On skip: "Skipped `swift-format`. `scripts/format.sh` will print a warning until installed." |
| 7 | **Brew tool installed at possibly-incompatible version** | After detection, run `<tool> --version` for installed tools; compare against the pack's known-good range (TBD per planner) | Print observed version, print known-good range, propose `brew upgrade <pkg>` as a per-install approval. On `skip`, record and proceed. | "swift-format 503.0.0 installed; pack tested with 510.x+. Reply `yes` to upgrade or `skip` to keep current version." |
| 8 | **Source layout indeterminate** (SPM vs Xcode-generated) | `Package.swift` present AND non-`Sources/`-rooted `.swift` directories present at depth ≤2 | Ask the developer once, then auto-set `SWIFT_SOURCE_DIRS` accordingly. Do not guess. | "Both `Sources/` and `MyApp/` contain Swift sources. Reply with the directories `format-swift.sh` should target (space-separated), or `default` to leave `SWIFT_SOURCE_DIRS=\"\"`." |
| 9 | **Network required (`brew update`) but unavailable** | `brew install` fails with a network-error stderr signature | Do not retry silently. Print the failed command and the stderr tail; treat the install as `skip`-by-failure; record it; proceed. | "`brew install swift-format` failed with network error. Skipped. Re-run kickoff after restoring network, or run the install manually." |

Common discipline across all branches:

- **Never silently skip.** Every condition that does not produce the
  ideal outcome is named in the PM chat's reply.
- **Never block the entire kickoff on a single failure.** The
  developer can complete the rest of the kickoff and re-attempt the
  failing step later. This matches `add-capability.sh` Stage A4
  semantics (V10-DESIGN §5.14.5): aborting at any gate leaves the
  project in the pre-gate state.
- **Always print the command that was run and its observed output**
  before drawing a conclusion. The developer can override.

---

## Part 7 — Variant Structure (Q5)

### 7.1 The two options

- **(a)** One `Variant: kickoff` with Apple-conditional and
  gRPC-conditional segments inline, gated by detection / by what the
  trinity placeholders say about the project.
- **(b)** Multiple variants — `kickoff`, `kickoff-apple`,
  `kickoff-apple-grpc`, `kickoff-python`, `kickoff-python-grpc`, etc.
  — chosen by the developer at session start or by `init-project.sh`
  output.

### 7.2 Decision: (a), single kickoff variant with inline conditionals

Rationale, in priority order:

1. **Variant proliferation conflicts with the v10 design's "fewer
   files, fewer conventions" principle.** The pack already shipped
   per-agent prompt files in v10 (V10-DESIGN Part 4 §4.2) where
   variants are kept tight; pm-chat.md currently has four variants
   total. Adding 3–5 kickoff variants for project-type permutations
   is a 2× growth on the file's variant count for content that is
   80% shared.
2. **The conditional logic is detection-driven.** `init-project.sh`
   already emits language/platform information. The kickoff prompt
   reads the trinity files (filled by `init-project.sh` and/or
   `Step 4 — Fill in context file placeholders`) and branches on
   what it finds. The developer does not need to choose a variant —
   the PM chat detects.
3. **Splitting forces a selection step.** The developer would have
   to decide which variant to paste before pasting. That is exactly
   the kind of mechanical decision the BD-047 principle ("developer
   is decision-maker, not copy/paste executor") rejects.
4. **Single variant is consistent with `kickoff` already being one
   prompt** that adapts to what it finds in `CLAUDE.md`. Adding
   inline Apple/gRPC/Python conditional segments matches the existing
   pattern.

### 7.3 When (b) would be reconsidered

Split the variant **only if** at least one of:

- The conditional segments grow beyond ~40% of the file's total
  length (token-budget concern).
- The Apple and Python paths develop genuinely incompatible
  top-level instructions (today they don't — both branch on
  detection of installed tools).
- A future host begins to charge prompt tokens linearly with the
  full variant body and the unused conditional content becomes a
  measurable cost.

None of these conditions hold today.

### 7.4 Selection / detection mechanism inside the single variant

The kickoff variant declares branches roughly:

```
[After surface declaration in Part 4 + read-only discovery in Part 5]

If the project trinity files indicate an Apple platform target
   (PLATFORM_TARGETS contains `iOS`, `iPadOS`, `macOS`, `tvOS`,
   `watchOS`, or `visionOS`), execute the Apple sub-flow:
   - Xcode scheme + destination discovery (Part 6 #2/#3)
   - `swift-format` install check (Part 6 #6)
   - SWIFT_SOURCE_DIRS resolution (Part 6 #8)
   - Xcode companion files install offer (Part 5, machine-level group)

If the project trinity files indicate a Python/server platform target,
   no Apple sub-flow.

If the trinity TRANSPORT line includes `gRPC` OR `proto/` exists in
   the project, execute the gRPC sub-flow:
   - `buf`, `swift-protobuf`, `grpc-swift` install checks
   - On Python branches: optional `uv add grpcio-tools ...` with the
     usual per-install approval
   - Print the `./scripts/proto-gen.sh` example invocation
```

Each sub-flow is text inside the same `## Variant: kickoff` H2 block.
No new files, no new variants.

---

## Part 8 — Confirmation-gate Pattern (Q6)

### 8.1 Constraints the pattern must satisfy

- **Identical across Category A and Category B.** No interactive
  menus (Desktop Commander returns text; CLI surfaces support
  in-band text reply but not modal dialogs).
- **Natural in chat.** The developer should be able to reply in
  natural language without remembering syntax.
- **Distinct visually** so it cannot be confused with normal
  conversation. Code-fenced blocks with a leading marker.
- **Fail-safe defaults.** Empty / unrecognized reply = no action
  (matches `add-capability.sh` A4 default-No semantics).

### 8.2 The pattern — three forms

**Form R (read-only batch):**

```
PROPOSED ACTION — read-only discovery
  Commands (all read-only, no side effects):
    1. xcodebuild -list
    2. xcrun simctl list devices available
    3. command -v swift-format
    4. command -v buf
    5. command -v brew

Reply: `yes` to run all · `skip` to skip discovery and ask manually
       · `abort` to stop kickoff
```

**Form I (single install):**

```
PROPOSED ACTION — install
  Command:        brew install swift-format
  Purpose:        enables scripts/format.sh to format Swift sources
  Side effects:   writes to /opt/homebrew/Cellar; ~5MB; network required
  Skip impact:    format.sh emits a warning but does not block validation

Reply: `yes` to install · `skip` to leave uninstalled · `abort` to stop
```

**Form E (single file edit):**

```
PROPOSED EDIT — scripts/validate.sh
  Discovered values:
    XCODE_SCHEME       = "MyApp"        (from xcodebuild -list)
    XCODE_DESTINATION  = "platform=iOS Simulator,name=iPhone 16,OS=latest"
                                        (from xcrun simctl list)

  Diff:
    -XCODE_SCHEME=""
    +XCODE_SCHEME="MyApp"
    -XCODE_DESTINATION=""
    +XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"

Reply: `yes` to apply · `edit` to provide your own values
       · `skip` to leave the file unchanged · `abort` to stop
```

**Form M (machine-level batch — Xcode companion files):**

```
PROPOSED ACTION — install Xcode companion files (machine-level)
  Target:   ~/Library/Developer/Xcode/CodingAssistant/
  Files:
    1. ClaudeAgentConfig/CLAUDE.md     (replaces if present)
    2. ClaudeAgentConfig/settings.json (replaces if present)
    3. codex/AGENTS.md                  (replaces if present)
    4. codex/config.toml                (replaces if present)
  Side effects: writes to your home directory; one-time per Mac

Reply: `yes` to install all · `skip` to leave companion files alone
       · `abort` to stop
```

### 8.3 Reply grammar

Atomic-token replies, one per prompt:

- `yes` (or `y`) — proceed.
- `no` / `skip` — do not proceed; record the skip.
- `abort` — exit kickoff entirely; commit nothing further.
- `edit` (Form E only) — invites the developer to provide overriding
  values in the next message.
- A bare integer or scheme name — for the multi-scheme branch
  (Part 6 #3).
- A bare destination string — for the no-simulator branch (Part 6 #4).
- A space-separated list — for the SWIFT_SOURCE_DIRS branch
  (Part 6 #8).

Empty reply, unrecognized reply, or any reply containing "no" /
"don't" / "wait" → treat as `no` and re-prompt with a clarifying
question. **Never default to `yes`.**

This grammar mirrors the atomic-token discipline established in
V10-DESIGN AD-17 (dimension-uniform invocation grammar for
add-capability.sh): one bare token per logical action, no flag
syntax in chat.

### 8.4 Why this works on every Bash-capable surface

- **Code fences** render visibly distinct on every chat surface
  (Claude Code CLI renders them as code; Codex CLI / Gemini CLI
  preserve them in the output stream; Claude Desktop renders them
  natively).
- **Single-word replies** are the lowest common denominator across
  any chat input; no surface has trouble processing them.
- **No menu state machine** means the PM chat does not need to
  remember "user is currently in install-step 3"; the prompt's
  context is contained in the latest message.

---

## Part 9 — Scope Boundary (What Phase 3-B Does NOT Touch)

### 9.1 `init-project.sh` — out of scope, by design

`init-project.sh` runs **before the PM chat exists for the project**.
It plants files, distributes skills, sets executable bits, and emits
an end-of-run kickoff prompt. It does not yet know:

- The Xcode scheme name (the trinity files have `[PLATFORM_TARGETS]`
  placeholders that haven't been filled).
- Whether the developer wants `swift-format` installed.
- Which simulator the developer prefers.
- Whether this Mac already has the Xcode companion files installed.

Putting kickoff auto-discovery into `init-project.sh` would require:

- An interactive shell flow inside the script (more complex than
  Stage A4's single y/N).
- The script to invent the same approval-gate text grammar Phase 3-B
  already needs in the PM chat.
- The script to know about Xcode at all — currently `init-project.sh`
  is platform-agnostic and only inspects the working tree.

The PM chat is the right home because:

- The developer is already in conversation at kickoff time.
- The PM chat already reads the (now-filled) trinity files to know
  the project's platform targets.
- Approval grammar already exists in the PM chat's repertoire (it
  is the same grammar Procedure 6 uses for G6-drafts and G6-commit).

### 9.2 `add-capability.sh` — out of scope, by design

`add-capability.sh` runs **mid-project, when the developer adds a new
capability dimension** (V10-DESIGN §5.14). Its end-of-run prompt
hands off to METHODOLOGY.md Procedure 6 — a PM-chat-side procedure
that updates trinity files for the newly-active dimension.

Procedure 6 does NOT do install / discovery work — it updates
markdown placeholders. The fact that adding `language:python` might
imply "you may want to `brew install grpcio-tools`" is **not a
Procedure 6 concern**; it is a future enhancement either to
Procedure 6 or to a successor of the kickoff design (Part 14
Open Question 5).

For v10.0 Phase 3-B: kickoff handles install/discovery on initial
project setup only. Capability-addition install/discovery is
explicitly out of scope.

### 9.3 `scripts/lib/detect.sh` — out of scope

`detect.sh` is a shell library sourced by both `init-project.sh`
and `add-capability.sh`. It detects file-system state. It does not
know about Xcode tooling versions or simulators. Phase 3-B's
discovery work happens in the PM chat at the chat layer — not in
shell — because the discovery results need approval-gating and
free-form developer reply, neither of which fits a shell library.

### 9.4 `validate-pack.py` — out of scope

No new file conventions, no new schema, no new directory rules. The
kickoff variant's body lengthens; nothing structural changes.

---

## Part 10 — SETUP-NEW.md / SETUP-EXISTING.md Update Strategy

### 10.1 SETUP-NEW.md restructure

**Current Steps 5, 6, 7, 8** collapse to a single new **Step 5 — PM
chat completes setup**, followed by a clearly-labeled **Manual
fallback** sub-section that preserves the current commands verbatim.

Proposed replacement (the planner pass refines wording):

```
## Step 5 — PM chat completes setup

The PM chat's `kickoff` variant (run in Step 10 below) auto-discovers
your Xcode scheme and simulator, checks for required brew tools,
proposes installs and file edits, and offers to install the Xcode
companion files — all behind per-action approval prompts.

If your PM chat surface has shell access (Claude Code CLI, Codex CLI,
Gemini CLI, or Claude Desktop with Desktop Commander), you do not
need to perform the work below manually. Continue to Step 9.

If your PM chat surface has NO shell access (Claude Web without
Desktop Commander, or ChatGPT Web), see the **Manual fallback**
sub-section below, then continue to Step 9.

### Manual fallback

[The current Steps 5, 6, 7, 8 content, verbatim, in their current
order, with their current commands and value examples. Re-titled as
sub-sections 5.A (Apple Xcode scheme variables), 5.B (Apple
swift-format install), 5.C (gRPC tooling install), 5.D (Apple Xcode
companion files install).]
```

The downstream **Step 9 — Initial commit** and **Step 10 — Set up the
PM chat** keep their existing numbering by shifting current Step 9 to
new Step 6, current Step 10 to new Step 7, etc. **Or** new Step 5
absorbs the old Steps 5–8 and the rest renumber down by 3. Planner
chooses; the call has no design implications.

### 10.2 SETUP-EXISTING.md restructure

Identical pattern. Current Step 5 (Apple Xcode scheme variables —
which today already cross-references `SETUP-NEW.md` Step 5 for
detail) and Step 6 (Xcode companion files) collapse to a single new
**Step 5 — PM chat completes setup**, with the same Manual fallback
sub-section pointing to the same content as `SETUP-NEW.md` (do not
duplicate; cross-reference).

### 10.3 Why the manual fallback ships verbatim

- It is the contract for non-Bash surfaces. Removing it would break
  Category C entirely.
- It is also the **diff-able specification of what the kickoff
  variant must do.** A reviewer can compare the kickoff variant's
  generated commands against the manual instructions to verify
  parity. If they diverge, one is wrong.
- It is the fallback for any failure mode the kickoff didn't
  anticipate. "If the PM chat couldn't figure it out, here's the
  manual recipe."

### 10.4 Cross-reference update sweep

Files that mention SETUP-NEW.md Step 5 or SETUP-EXISTING.md Step 5
must be re-checked. Known suspect:

- `MIGRATION-v9-to-v10.md` (if it references SETUP step numbers).
- `QUICKSTART.md` (the three-path router).
- `PM-CHAT.md` (`Behavioral rules` already mentions kickoff).

Planner pass owns the sweep.

---

## Part 11 — Testing Strategy

The kickoff variant is a prompt, not code. It cannot be unit-tested.
Verification is **manual fixture-based** plus **prompt review**.

### 11.1 Fixture matrix

Build six lightweight fixture project directories under
`maintenance-docs/v10-working/phase-3b-fixtures/` (created at
implementation, not committed long-term). Each fixture is a minimal
v10-installed project (run `init-project.sh` once into an empty
git repo with a stub `Xcode project` / `Package.swift` / etc.):

| Fixture | What it covers |
|---|---|
| `apple-spm-single-scheme` | Validates Q4 #2 (one scheme), Form E |
| `apple-multi-scheme` | Validates Q4 #3 (multiple schemes), reply-by-name and reply-by-number |
| `apple-no-simulator` | Validates Q4 #4, the macOS fallback path |
| `apple-non-spm-layout` | Validates Q4 #8, SWIFT_SOURCE_DIRS resolution |
| `python-grpc-server` | Validates Apple skip + gRPC proto sub-flow |
| `python-only` | Validates Apple skip and gRPC skip — kickoff does almost nothing |

For each fixture: a reviewer pastes the kickoff prompt into a real
CLI surface (Claude Code CLI is the cheapest to run), declares
`shell`, walks through every approval, and verifies:

- The PM chat ran exactly the commands the prompt promised.
- The PM chat surfaced the exact decisions Part 6 specifies for that
  fixture's branches.
- The file edits land at the specified anchors with the discovered
  values.
- An `abort` at any gate leaves the project in the pre-gate state
  (matches V10-DESIGN §5.14.5 discipline).

### 11.2 Manual surface checks

For each Bash-capable surface other than the primary fixture host
(Codex CLI, Gemini CLI, Claude Desktop with Desktop Commander), do
**one** end-to-end run with the `apple-spm-single-scheme` fixture
to validate cross-surface parity. The reviewer notes any
surface-specific behavior the kickoff variant must accommodate
(e.g., Codex CLI's brew-install escalation prompt; Gemini CLI's
plan-mode blocker).

### 11.3 Non-Bash surface check

Paste the kickoff into Claude Web (no Desktop Commander). Reply
`manual`. Verify:

- The PM chat does not attempt any tool call.
- The PM chat emits the manual instructions in the same order and
  with the same content as SETUP-NEW.md Step 5 Manual fallback.
- The PM chat invites the developer to report values back and
  generates the file diffs in chat for paste.

### 11.4 Diff-vs-manual parity check

Hand-compare the commands the kickoff variant emits in shell mode
against the SETUP-NEW.md Manual fallback section. Every command in
the manual fallback must have a Form-R / Form-I / Form-M / Form-E
analog in the variant. If a step exists in the manual fallback but
not in the variant (or vice versa), one of the two is wrong.

### 11.5 What is NOT tested

- Cross-version brew tooling compatibility (Q4 #7 known-good range
  is a planner-pass open question).
- Non-Apple, non-Python platforms (Kotlin, TypeScript, Rust, etc.) —
  the pack does not ship skills for them in v10.0; kickoff has
  nothing to discover.
- Concurrent kickoffs on the same project — explicitly disallowed by
  PM-CHAT.md ("Never run two PM chats simultaneously for the same
  project").

---

## Part 12 — Rough Commit Sequence Outline (Planner-pass Input)

Initial estimate: 2–3 commits + the design doc itself.

### Commit 0 (already made by this session)
`docs: v10 — BD-047 V10-PHASE-3B-DESIGN.md (architecture pass)`

### Commit 1 — kickoff variant
`feat: v10 — BD-047 PM chat kickoff auto-discovery + install-check`

Touches: `project-template/docs/pack/prompts/pm-chat.md` only.

Content of the commit:
- Insert the surface-declaration block (Part 4) at the top of
  `## Variant: kickoff`, after the placeholder-paste block.
- Insert the read-only discovery batch + Form-R confirmation (Part 8).
- Insert the Apple-conditional sub-flow (Part 7 §7.4 outline) using
  Form I, Form E, Form M as appropriate.
- Insert the gRPC-conditional sub-flow.
- Insert the Manual-mode branch printing the SETUP fallback content.
- Append the error-branch behaviors from Part 6 Table inline as
  PM chat behavioral rules within the variant.

### Commit 2 — SETUP guides
`docs: v10 — BD-047 SETUP-NEW.md / SETUP-EXISTING.md fold steps 5–8 into PM chat`

Touches: `supporting-docs/SETUP-NEW.md`,
`supporting-docs/SETUP-EXISTING.md`.

Content:
- Replace Steps 5–8 (NEW) with new Step 5 + Manual fallback per
  Part 10.
- Replace Steps 5–6 (EXISTING) with new Step 5 cross-referencing the
  NEW Manual fallback.
- Renumber subsequent steps.
- Sweep cross-references in `QUICKSTART.md`, `MIGRATION-v9-to-v10.md`,
  `PM-CHAT.md` for stale step numbers.

### Commit 3 (conditional) — PM-CHAT.md behavioral rule
`docs: v10 — BD-047 PM-CHAT.md kickoff capability declaration rule`

Touches: `project-template/docs/pack/PM-CHAT.md` only.

Content (only if planner concludes the rule does not fit inside
the kickoff variant):
- Add one Behavioral Rule clarifying that the PM chat must declare
  shell capability before running any kickoff discovery commands.
- Possibly add one row to the File access strategy table for
  kickoff-time machine-level paths
  (`~/Library/Developer/Xcode/CodingAssistant/`).

The planner decides whether commit 3 fires. If the kickoff variant's
own text suffices, commit 3 is dropped and Phase 3-B is two commits.

### Commit 4 (conditional) — fixture cleanup
`chore: v10 — BD-047 Phase 3-B test fixture cleanup`

Touches: `maintenance-docs/v10-working/phase-3b-fixtures/` removal.

Only fires if the test fixtures land in a committed location (the
expected disposition is they are throwaway and never committed).

---

## Part 13 — Rejected Alternatives (per question)

### Q1 (Cross-tool parity) — rejected: per-surface variants

Rejected: ship `kickoff-claude-code-cli`, `kickoff-codex`,
`kickoff-gemini`, `kickoff-desktop-commander` as four separate
variants tuned to each surface.

Why rejected: the surfaces differ only in **how shell calls are
mediated** (per-call approval, sandbox escalation, MCP wrapping),
not in **what shell calls are needed**. Per-surface variants would
duplicate 95% of content for differences the host already mediates.
Single variant + declarative surface (Part 4) carries the host
differences in two sentences.

### Q2 (Capability detection) — rejected: probe-based detection

Rejected: kickoff opens with `xcodebuild -list || echo NOSHELL` and
infers shell capability from the result.

Why rejected: on Category C surfaces, the call simply doesn't
execute — the model sees no result. The model cannot distinguish
"call executed, command failed" from "call never executed." The
declarative-via-question model (Part 4) has zero ambiguity and
zero failure modes on any surface.

Also rejected: detect by environment variables (`CLAUDE_CODE_*`,
`CODEX_*`, etc.) — partial coverage, no signal for Desktop Commander
presence, no signal for Category C at all.

### Q3 (Interaction model) — rejected: pure auto-run silent mode

Rejected: kickoff runs all discovery commands and installs without
asking, only prompting on ambiguity.

Why rejected: violates BD-047's stated principle ("developer is the
decision-maker, not a copy/paste executor" — but also not a
silent-execution rubber-stamp). Also fictional in practice on
Category A — every surface's host approval intercepts at the command
level. A "silent mode" that the host then de-silences is worse than
an explicit batched-approval mode that matches what the host does
anyway.

Also rejected: pure per-command ask (no batching) — see Part 5 §5.2
friction argument.

### Q4 (Error branches) — rejected: hard-stop on any failure

Rejected: any failed install / no scheme / no simulator / etc.
aborts the entire kickoff and the developer must restart.

Why rejected: kickoff is many small independent decisions. Hard-stop
means re-paying the cost of every approval already made. The
per-branch `skip` semantics of Part 6 + Part 8 mean each failure
costs the developer one item, not the whole kickoff.

### Q5 (Variant structure) — rejected: split into per-project-type variants

Rejected: ship `kickoff`, `kickoff-apple`, `kickoff-apple-grpc`,
`kickoff-python-grpc`, `kickoff-python-only`.

Why rejected: see Part 7 §7.2 four-point rationale. Variant
proliferation is inversely consistent with the v10 design's
"fewer files, fewer conventions" pillar. The conditional logic is
detection-driven, not selection-driven.

Also rejected: split into `kickoff-shell` and `kickoff-manual`. The
shell-vs-manual difference is one declaration plus one branch in the
variant body — splitting it doubles the maintenance surface for what
is structurally a single decision tree.

### Q6 (Confirmation-gate pattern) — rejected: interactive numbered menus

Rejected: present "1) install · 2) skip · 3) abort" with the
expectation the developer types `1`.

Why rejected: works on Category A surfaces but **bare integers
collide with the multi-scheme branch** (Part 6 #3) where `2` means
"the second scheme." Mixed grammar (digits sometimes mean menu,
sometimes mean choice) is a bug source. Atomic word tokens (`yes`,
`skip`, `abort`) eliminate the collision.

Also rejected: free-form natural language confirmation ("sure",
"go ahead", "do it"). These work conversationally but are
ambiguous-by-default and require the PM chat to interpret intent.
Atomic tokens are unambiguous; natural-language replies that map
clearly (`yes`, `okay`, `proceed`) can still be accepted as `yes`,
but the **prompt asks for the canonical form**.

---

## Part 14 — Open Questions Deferred to Planner Pass

These are concrete decisions the planner pass must make. None of them
threaten the architecture above; each is a refinement.

1. **Read-only discovery batch granularity.** Form R (Part 8) shows
   a single batched approval for all read-only commands. Should the
   batch be one prompt for everything (Apple + gRPC + brew presence
   + companion files presence), or split per project-type sub-flow
   (one batch for Apple discovery, one batch for gRPC discovery)?
   Architecture argument can support either; planner picks based on
   approval-load empirical feel.

2. **Brew tool known-good version range source of truth.** Q4 #7
   requires a "known-good range" per brew tool. Options: hardcode in
   the kickoff variant text; load from a new file
   (`project-template/docs/pack/TOOL-VERSIONS.md`); defer to a future
   minor version. Architecture leans toward hardcode for v10.0
   simplicity (no new file) with a reference comment pointing at the
   source. Planner confirms.

3. **Companion-files install: opt-in or opt-out by default?** Form M
   default is `skip` per Part 8 §8.3 fail-safe. Should kickoff
   surface a more strongly-worded recommendation when it detects a
   stale companion-files install? (`stat ~/Library/Developer/Xcode/
   CodingAssistant/ClaudeAgentConfig/CLAUDE.md` newer than $PACK is
   detectable.) Defer to planner.

4. **Should kickoff offer to commit?** Current kickoff variant does
   not commit; the developer commits in SETUP Step 9 (current
   numbering). Phase 3-B does not propose to change this — kickoff
   leaves the working tree dirty, the developer reviews
   `git status` / `git diff`, the developer commits. **But:** the
   companion-files Form M batch writes to `~/Library/...`, which is
   not in the project tree at all. Should kickoff offer a single
   final commit for the in-tree edits with a fixed commit message
   shape (`feat: project — fill kickoff-discovered values`)? Planner
   decides.

5. **Capability-addition kickoff symmetry.** `add-capability.sh`
   today only does the file-system plumbing; it does not propose
   `brew install grpcio-tools` when the developer adds
   `language:python` to a previously Apple-only project. If this
   is desirable, it implies a **Procedure 6 enhancement** (or a
   Phase 3-B-II in a future minor version) that mirrors the kickoff
   discovery pattern at capability-addition time. Out of scope for
   v10.0 Phase 3-B. Logged as a **deferred item** for the planner
   to optionally promote into a separate BACKLOG entry.

6. **Surface declaration: placeholder vs. opening question.** Part 4
   §4.2 chose "opening question" to keep the pasteable text
   surface-agnostic. Counter-argument: pasted text is what the
   developer hands to other agents / saves as a snippet; baking
   `**Surface:** [shell|manual]` into the placeholders matches the
   existing placeholder model. Planner picks; both work.

7. **Plan-mode protection (Gemini CLI).** Part 3 §3.2 notes that
   Gemini CLI's plan mode blocks shell. Should the kickoff variant
   open with a one-line "if you are in Gemini plan mode, exit it
   before continuing" instruction, or should the variant simply
   describe what to do if a command is blocked unexpectedly?
   Architecture leans toward the explicit instruction (transparency
   over recovery). Planner confirms.

8. **Form M companion-files: parity with `xcode-companion-templates/`
   structure?** The current SETUP Step 8 (NEW) hardcodes four file
   paths. Phase 3-B implementation should read the canonical structure
   from `xcode-companion-templates/` rather than re-hardcoding.
   Planner confirms reading vs. hardcoding tradeoff.

9. **Existing-project reconciliation.** SETUP-EXISTING.md Step 9
   (existing-docs pointer) runs **before** SETUP Step 5 in the
   current ordering. After Phase 3-B, the new collapsed Step 5 is
   PM-chat-driven and runs at kickoff (Step 10). Order of operations
   for existing-project flow: does kickoff do the discovery before,
   during, or after the existing-docs pointer step? Architecture
   leans "during the kickoff workflow, after existing-docs pointer
   completes" — discovery does not depend on existing docs. Planner
   confirms.

