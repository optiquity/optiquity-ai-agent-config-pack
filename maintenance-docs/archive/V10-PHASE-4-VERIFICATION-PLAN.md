# V10-PHASE-4-VERIFICATION-PLAN.md — Per-section runbook for C-V10-15

*Status: Active (v10-dev). Companion plan to `V10-PHASE-4-PLAN.md` Part 4.*
*Authoritative spec for what evidence is required: `V10-PHASE-4-PLAN.md` Part 4 (§4.1–§4.5).*
*Authoritative spec for fixture sourcing: `V10-PHASE-3B-PLAN.md` Part 5 §5.1–§5.5 (carried forward by V10-PHASE-3B-PLAN-v2 §5).*
*Authoritative spec for cross-surface matrix: `V10-PHASE-3B-DESIGN-v2.md` Part 11.*
*Authoritative spec for the manual-mode pointer wording: `V10-PHASE-3B-PLAN-v2.md` §3.3.*

---

## Part 0 — Status, scope, and what this plan IS / ISN'T

### 0.1 Status

C-V10-01 through C-V10-14 have landed on `v10-dev`. Tip is **`459161b`** (or
a descendant). All 31 audit findings are resolved (AF-027 alone is "no
action — accepted plan-reality drift"). `scripts/test-detect.sh` exists
and passes 34/34. **One commit remains before Gate F: C-V10-15** — the
Phase 4 verification harness, which creates one new file
`maintenance-docs/V10-PHASE-4-VERIFICATION.md` capturing evidence from
five independent verification streams.

### 0.2 Scope of this plan

This plan governs **execution of C-V10-15 only.** It is a per-section
runbook that supplements `V10-PHASE-4-PLAN.md` Part 4 with:

- Copy-pasteable command sequences for every fixture, every check, and
  every cleanup.
- A "who runs what where" matrix that names the runner (this CLI / dev
  in another CLI / dev in browser) for each section.
- A surface-availability pre-flight that fires **before** any
  verification work begins, so an unavailable surface triggers F-B at
  the right moment instead of mid-run.
- A unified evidence-capture template applied uniformly to all five
  sections.
- An explicit rollback table for every state-creating operation.

### 0.3 What this plan is NOT

- It does **not** supersede `V10-PHASE-4-PLAN.md`. Where this plan's
  procedural detail conflicts with that plan's specification, the
  specification wins; flag back to project lead before proceeding.
- It does **not** change Gate F entry criteria. Those are
  `V10-PHASE-4-PLAN.md` Part 5 (12 numbered criteria).
- It does **not** authorise edits to any pack file other than
  `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (the one file C-V10-15
  creates).
- It does **not** change the eight flag-backs F-A..F-H in
  `V10-PHASE-4-PLAN.md` Part 8. Section runbooks below name flag-backs
  by ID; the wording lives in the parent plan.

### 0.4 Hard guardrails (every section must obey)

1. **Every fixture path is under `/tmp/phase-4-fixtures/`.** Never under
   `~/tmp/`, never under any pack worktree, never under
   `maintenance-docs/v10-working/`. `/tmp/` is volatile, ungitignored,
   and outside any tracked tree.
2. **Every state-creating operation has a rollback row in §10.** No
   exceptions. If the implementer adds a step that creates state, they
   add the matching rollback row first.
3. **No git command in this plan targets the live pack repo at
   `/Users/david/Developer/dhs-ai-agent-config-pack`.** Migration smoke
   (§4.4) operates exclusively on `/tmp/phase-4-fixtures/v9-project/`.
   The v9.3 pack source clone lives at `/tmp/v9-pack-source/`. Both are
   independent of any pack worktree.
4. **`PACK` always points at the v10-dev worktree** for verification
   purposes:
   `PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev`. The
   migration smoke uses this `PACK` value (it is the v10 source the
   v9.3 fixture is migrated against).
5. **`git status` clean on `v10-dev` before C-V10-15 begins**, and
   `git status` must remain clean throughout — only the single new
   verification file is touched at commit time.
6. **No silent deferrals.** Any unavailable surface, any failing run,
   any unexpected output triggers the corresponding F-B / F-G / F-H
   flag-back row recorded inline in `V10-PHASE-4-VERIFICATION.md` with
   project-lead acknowledgement.

### 0.5 Resolved environment facts (from this plan's preparation)

| Fact | Value | How verified |
|---|---|---|
| v10-dev worktree path | `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev` | `git status` shows clean tree at `459161b`. |
| Main pack worktree path | `/Users/david/Developer/dhs-ai-agent-config-pack` | Lives alongside v10-dev; **not touched** by this plan. |
| Latest v10-dev commit | `459161b` (`feat: v10 — scripts/test-detect.sh unit tests for detect.sh library functions`) | `git -C $PACK rev-parse HEAD`. |
| Available surfaces (this Mac) | `claude` (CLI), `codex`, `gemini` all on `$PATH` | `command -v claude codex gemini`. |
| v9.3 tag exists in remote | yes | `git -C $PACK tag --list 'v9*'` shows `v9 v9.0 v9.1 v9.2 v9.3`. |
| `bash scripts/test-detect.sh` | 34 passed, 0 failed | Re-run pre-§4.5 capture. |
| `init-project.sh` interactive prompts | Exactly one: `Proceed? [y/N]` at line 232; default `N` (must reply `y` to advance past preview gate). | `grep -nE 'read -[rp]' scripts/init-project.sh` returns one match. |
| Pack repo visibility | **PRIVATE** on GitHub. `git clone https://github.com/DShaneNYC/dhs-ai-agent-config-pack` requires auth and may fail. | `gh repo view DShaneNYC/dhs-ai-agent-config-pack --json visibility` returns `PRIVATE`. |
| v9.3 tag in live pack repo | Present (also v9.0, v9.1, v9.2, bare v9). | `git -C /Users/david/Developer/dhs-ai-agent-config-pack tag --list 'v9*'`. |
| §6.3 v9.3 source method | **Local clone** from live pack repo (NOT network clone from GitHub) — sidesteps private-repo auth and is faster (git hard-link optimization). | See §6.3 below. |
| Live worktree branch | `main` (independent of v10-dev) | `git -C /Users/david/Developer/dhs-ai-agent-config-pack rev-parse --abbrev-ref HEAD`. |

If any of these facts has shifted by execution time, **re-confirm in
the pre-flight (Part 1) and update this table inline** before starting
§4.1.

### 0.6 Scope decisions made before execution (project-lead resolved)

Project lead resolved several scope decisions before plan execution
began. These supersede the corresponding open questions in Part 12:

- **§4.2 cross-surface live runs are DEFERRED.** Per project-lead
  direction (2026-04-25): Codex CLI and Gemini CLI live runs are not
  required for v10.0; instead, a **docs-research pass** runs after
  §4.1 Claude Code CLI tests succeed, identifying where each surface
  would deviate from the Claude Code CLI behavior and what to flag
  for v10.1. Same applies to Desktop Commander. Resolves OQ-VP4-1
  and OQ-VP4-7 as MOOT.
- **§3.2.3 F3 simulator-empty test uses PATH-based stub** (option a
  from gap discussion), not chat-side fakery. Resolves OQ-VP4-2.
- **§4.4 fixture realism: thin v9.3 fixture for v10.0;** richer
  fixture (x-files, custom skills, populated PROMPT-TEMPLATES.md) is
  a v10.1 candidate. Resolves OQ-VP4-4.
- **Evidence file size: verbatim outputs preferred; no hard ceiling.**
  Resolves OQ-VP4-5.
- **§6.3 v9.3 source: local clone from `/Users/david/Developer/dhs-
  ai-agent-config-pack` (not GitHub).** No network egress required.
  Resolves OQ-VP4-6.

OQ-VP4-3 (F2 multi-scheme model behavior) remains open — needs
execution context.

### 0.7 Hybrid execution scope

Project lead chose **hybrid scope** (start minimal; expand if
anomalies surface). Practical execution order under hybrid scope:

1. **§4.5** — `test-detect.sh` capture (autonomous; this CLI session)
2. **§4.1 F1 only** — Claude Code CLI happy-path (developer in a
   separate `claude` session)
3. **Reassess.** If F1 surfaces no defects, proceed; if a defect
   appears, stop and re-plan.
4. **§4.4** — migration script smoke (autonomous; this CLI session)
5. **§4.3** — Claude Web manual-mode (developer in browser)
6. **Docs-research pass (replaces §4.2 live runs)** — autonomous;
   this CLI session
7. **§4.1 F2..F6 corner-case fixtures** — only if §4.1 F1 succeeds and
   the project lead opts in to expanded coverage

Sections F2..F6 are conditional on hybrid expansion. The "minimal"
scope is sections 1, 2, 4, 5, 6 (no F2..F6, no live cross-surface).

---

## Part 1 — Surface-availability pre-flight (run this FIRST)

**When:** Before any §4.1 / §4.2 / §4.3 / §4.4 work begins.
**Where:** This CLI session, in the v10-dev worktree.
**Why:** R-V10-2 (Phase 4 Plan Part 9) — discovering an unavailable
surface mid-run forces an awkward F-B at the wrong point. Pre-flight
fires F-B once, up front, and the project lead resolves it once.

### 1.1 Pre-flight commands (copy-paste verbatim)

```bash
# Anchor the pack path for the entire session.
export PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev

# Sanity: pack worktree exists and is on v10-dev.
[[ -d "$PACK" ]] && echo "OK: PACK exists" || echo "FAIL: PACK missing"
git -C "$PACK" rev-parse --abbrev-ref HEAD     # expect: v10-dev
git -C "$PACK" status --porcelain              # expect: empty (clean)
git -C "$PACK" rev-parse HEAD                  # expect: 459161b… or descendant

# v9.3 tag resolvable in pack remote (used by §4.4).
git -C "$PACK" rev-parse v9.3 >/dev/null && echo "OK: v9.3 resolvable" || echo "FAIL: v9.3 missing"

# Surface presence — record results into a scratch buffer.
{
  printf 'Pre-flight surface check (%s)\n' "$(date -u +%FT%TZ)"
  for tool in claude codex gemini bash python3 git; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '  %-10s present at %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '  %-10s MISSING\n' "$tool"
    fi
  done
  # Versions where they exist.
  command -v claude  >/dev/null && claude  --version 2>&1 | head -1 | sed 's/^/  claude:  /'
  command -v codex   >/dev/null && codex   --version 2>&1 | head -1 | sed 's/^/  codex:   /'
  command -v gemini  >/dev/null && gemini  --version 2>&1 | head -1 | sed 's/^/  gemini:  /'
} > /tmp/phase-4-preflight.txt
cat /tmp/phase-4-preflight.txt

# Fixture base directory — created here, removed by §10 row R10-1.
mkdir -p /tmp/phase-4-fixtures
ls -ld /tmp/phase-4-fixtures
```

### 1.2 Pre-flight pass criteria

All must be true before the implementer proceeds to §4.1:

- `PACK` exports to a directory that exists.
- `git -C "$PACK" status --porcelain` returns empty.
- `git -C "$PACK" rev-parse --abbrev-ref HEAD` returns `v10-dev`.
- `git -C "$PACK" rev-parse v9.3` returns a SHA (no error).
- `claude`, `bash`, `python3`, `git` all present on `$PATH`.
- `/tmp/phase-4-fixtures/` exists and is writable.

### 1.3 Surface unavailability handling (F-B status under §0.6 decisions)

Under §0.6 scope decisions, **Codex CLI / Gemini CLI / Desktop
Commander are pre-deferred** — they do not need to be present at
pre-flight, and their absence does NOT block C-V10-15. The §4.2 live
runs are replaced by a docs-research pass (Part 4) that runs
autonomously after §4.1 succeeds.

**Required surfaces for hybrid scope:**

| Surface | Required? | Why |
|---|---|---|
| `claude` (Claude Code CLI) | **Yes** | §4.1 fixture runs; §4.5 test-detect.sh capture; this implementer session |
| `bash`, `git`, `python3` | **Yes** | every section |
| Claude Web (in browser) | **Yes** for §4.3 | manual-mode smoke; developer-in-browser |
| `codex` | No (deferred) | docs-research pass instead |
| `gemini` | No (deferred) | docs-research pass instead |
| Claude Desktop + filesystem MCP | No (deferred) | docs-research pass instead |

If a **required** surface is missing (`claude` / `bash` / `git` /
`python3`), F-B fires and C-V10-15 cannot proceed until resolved.

If an **optional** surface (`codex` / `gemini` / Desktop Commander)
happens to be present anyway, the implementer records its presence
in the §4.5 evidence block "available surfaces" line; the docs-
research pass still runs (we do not opportunistically expand to live
runs without project-lead direction).

### 1.4 Verbatim wording for v10.1-deferred surface entries

The §4.2 docs-research-pass output (see Part 4 below) uses this
wording for each cross-surface row that names a deferred-to-v10.1
risk:

> **Surface deferred to v10.1 docs-research pass per §0.6 scope
> decision.** No live run was performed against `<surface name>`
> for v10.0. The behavior described in this row is derived from
> documentation (cite source) and architectural reasoning, not from
> direct observation. Tracked as v10.1 candidate per V10-PHASE-4-PLAN
> F-B resolution.

---

## Part 2 — Who runs what where (matrix)

One row per Part-4 section. Columns: section / surface / runner /
prerequisite-check command (run before starting that section).

| § | Surface | Runner | Where | Prerequisite check (run before starting) |
|---|---|---|---|---|
| 4.1 | Claude Code CLI | **Developer in a separate `claude` session** (this implementer cannot run claude inside claude) | Inside fixture `/tmp/phase-4-fixtures/<fixture>/` | `command -v claude && [[ -d /tmp/phase-4-fixtures ]] && echo OK` |
| 4.2 (docs-research) | (no live surface) | **This CLI session** | v10-dev worktree | §4.1 has captured at least F1; pack docs (`pm-chat.md`, `METHODOLOGY.md` Procedure 7, `V10-PHASE-3B-DESIGN-v2.md` Part 11) all readable. |
| 4.3 | Claude Web (no MCP) | **Dev in browser** at `claude.ai` | New chat, **no** project / no GitHub connector / no Desktop Commander | Dev opens a fresh chat window; pre-condition is "no tooling attached." |
| 4.4 | Bash | **This CLI session** | `/tmp/phase-4-fixtures/v9-project/` (NOT the pack worktree) | Pre-flight passes; v9.3 resolvable in live pack repo; `$PACK` set. |
| 4.5 | Bash | **This CLI session** | v10-dev worktree | `bash $PACK/scripts/test-detect.sh` was already run (and is re-run during §4.5 capture); already-passing per 0.5. |

### 2.1 Concurrency rules (see also Part 9 parallelization)

- §4.1 fixtures (F1 only under hybrid scope; F2..F6 conditional) are
  built and torn down per fixture. No reuse across sections under the
  current scope.
- §4.2 docs-research pass runs autonomously after §4.1 — it consumes
  the §4.1 evidence (specifically the F1 capture) and pack
  documentation, not live surfaces.
- §4.3 (browser) is independent of every other section. Run in
  parallel with §4.1 / §4.4 freely.
- §4.4 (migration smoke) operates on a **separate** fixture
  (`/tmp/phase-4-fixtures/v9-project/`) that has no overlap with §4.1
  fixtures. §4.4 may run in parallel with any other section.
- §4.5 is capture-only; the test runner already passed at C-V10-14.

### 2.2 Surfaces this plan does NOT exercise

ChatGPT Web is mentioned in `pm-chat.md` line 25 as a non-shell
surface. ChatGPT Web is **not** on the §4.2 cross-surface matrix and
is **not** required for §4.3 — Claude Web is the canonical manual-mode
surface per `V10-PHASE-3B-PLAN-v2` Part 7 criterion 8. Do not expand
§4.3 scope to ChatGPT Web; that is an F-E (silent scope expansion)
trigger.

---

## Part 3 — §4.1 Fixture evidence runbook

**Goal of §4.1.** For each of the six fixtures F1..F6, demonstrate that
the kickoff → Procedure 7 path produces the expected Form R / I / E /
M outputs (or the expected refusal / skip behavior) on at least one
Bash-capable surface (Claude Code CLI is canonical).

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.1 (six fixtures table);
`V10-PHASE-3B-PLAN.md` Part 5 §5.1–§5.4 (fixture sourcing strategy);
`supporting-docs/METHODOLOGY.md` Procedure 7 (the procedure under
test).

### 3.1 Prerequisites (run once before any fixture)

```bash
# Must already be exported from Part 1 pre-flight:
echo "PACK=$PACK"      # expect: /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
[[ -n "${PACK:-}" ]] || { echo "FAIL: re-run Part 1 pre-flight"; exit 1; }

# Fixture base directory.
mkdir -p /tmp/phase-4-fixtures
ls -ld /tmp/phase-4-fixtures
```

**`init-project.sh` interactive note.** Each fixture builder calls
`"$PACK/scripts/init-project.sh" .` which prompts exactly once with
`Proceed? [y/N]` (script line 232). Default is `N`. The fixture
builder must reply `y` (or `yes`) to advance past the preview gate.
No other prompts fire during init — the script auto-detects project
state from the filesystem.

### 3.2 Fixture-construction commands

Each fixture is constructed inline below. **Do NOT condense the
six blocks into a loop** — each fixture has subtle differences (Apple
vs Python, gRPC vs no-gRPC, single vs multi scheme, etc.) and a loop
hides those differences from the evidence record.

#### 3.2.1 F1 — `apple-spm-single-scheme`

**Exercises.** Single SPM scheme; happy-path Form R + I + E + M.

```bash
F1=/tmp/phase-4-fixtures/apple-spm-single-scheme
rm -rf "$F1"   # idempotent — safe even on first run
mkdir -p "$F1"
cd "$F1"
git init -q

# Pack-template install.
"$PACK/scripts/init-project.sh" .   # answer prompts: Apple/Swift, no gRPC

# Minimal SPM project — single scheme.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "F1App",
    products: [.library(name: "F1App", targets: ["F1App"])],
    targets: [
        .target(name: "F1App", path: "Sources/F1App"),
        .testTarget(name: "F1AppTests", dependencies: ["F1App"], path: "Tests/F1AppTests"),
    ]
)
EOF
mkdir -p Sources/F1App Tests/F1AppTests
cat > Sources/F1App/F1App.swift <<'EOF'
public struct F1App { public init() {} }
EOF
cat > Tests/F1AppTests/F1AppTests.swift <<'EOF'
import XCTest
@testable import F1App
final class F1AppTests: XCTestCase { func testInit() { _ = F1App() } }
EOF
git add -A && git commit -q -m "F1 baseline"
```

**Expected Procedure 7 behavior (for evidence comparison).**
- **Form R (G7-discovery).** `xcodebuild -list` reports exactly one
  scheme (`F1App`); `xcrun simctl list devices available` returns
  ≥1 simulator. Form R reply default `yes`; PM chat may proceed.
- **Form E (G7-edit).** Proposes edits to
  `scripts/validate-swift.sh`, `scripts/test-swift.sh`,
  `scripts/format-swift.sh`, and `.claude/settings.json`'s `env`
  block setting `XCODE_SCHEME="F1App"` and a chosen
  `XCODE_DESTINATION`. JSON is parse-mutate-serialise (not regex).
- **Form I (G7-install).** Proposes `brew install swift-format` if
  not already installed; default `skip`.
- **Form M (G7-machine).** Lists four `cp` invocations under
  `~/Library/Developer/Xcode/CodingAssistant/`; default `skip`.

**Capture for §4.1 evidence block.** Form R verbatim output; Form E
proposed diff (verbatim); Form I tool list; Form M
companion-files-batch list; pass/fail; deviations.

**Pre-built paste file (implementer adds this step).** After fixture
construction, pre-fill placeholders so the developer never edits
the paste text by hand:

```bash
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' \
    "$PACK/project-template/docs/pack/prompts/pm-chat.md" \
  | sed '$d' \
  | sed \
      -e 's/\[PROJECT_NAME\]/F1 Smoke Test/g' \
      -e 's/\[2-3 sentence description of what the project is and does\]/Phase 4 verification fixture (F1) — SPM single-scheme baseline; no real project./g' \
      -e 's|\[e\.g\., macOS 15+, Xcode 26\.3, Swift 6 / Python 3\.12+\]|macOS 15+, Xcode 26.3, Swift 6|g' \
      -e 's/Phase \[N\] — \[Phase title\] (\[not started \/ in progress\])/Phase 0 — Smoke (not started)/g' \
      -e 's/\[Architecture pattern, e\.g\., MVVM with layered domain\/data\/presentation\]/MVVM with layered domain\/data\/presentation/g' \
      -e 's/\[Key protocol decisions, e\.g\., DataStore protocol over SwiftData\]/none for smoke/g' \
      -e 's/\[Any other settled decisions\]/none for smoke/g' \
  > /tmp/phase-4-fixtures/kickoff-paste-F1.txt
wc -l /tmp/phase-4-fixtures/kickoff-paste-F1.txt
# Confirm no remaining bracketed placeholders:
grep -nE '\[[^]]+\]' /tmp/phase-4-fixtures/kickoff-paste-F1.txt | head -5
# Expect: zero matches in the project-context block (some [BRACKETED] text
# elsewhere in the variant body is fine — those are kickoff prose, not fields).
```

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-spm-single-scheme`
(safe to run after §4.1 F1 evidence capture is recorded; no cross-
section dependency under hybrid scope per §0.6 / §0.7).

#### 3.2.2 F2 — `apple-multi-scheme`

**Exercises.** Ambiguous scheme list; Form R presents choices.

```bash
F2=/tmp/phase-4-fixtures/apple-multi-scheme
rm -rf "$F2"
mkdir -p "$F2"
cd "$F2"
git init -q
"$PACK/scripts/init-project.sh" .

cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "F2",
    products: [
        .library(name: "F2Core", targets: ["F2Core"]),
        .executable(name: "F2CLI", targets: ["F2CLI"]),
    ],
    targets: [
        .target(name: "F2Core", path: "Sources/F2Core"),
        .executableTarget(name: "F2CLI", dependencies: ["F2Core"], path: "Sources/F2CLI"),
    ]
)
EOF
mkdir -p Sources/F2Core Sources/F2CLI
echo 'public struct F2Core { public init() {} }' > Sources/F2Core/F2Core.swift
echo 'import F2Core; @main struct F2CLI { static func main() { _ = F2Core() } }' > Sources/F2CLI/main.swift
git add -A && git commit -q -m "F2 baseline"
```

**Expected Procedure 7 behavior.** Form R lists ≥2 schemes
(`F2Core`, `F2CLI`); reply grammar (Procedure 7 §7.5) accepts
"bare scheme name" — PM chat re-prompts the developer to pick one.
Form E does not propose edits until a scheme is chosen.

**Capture.** Form R verbatim output (must show ≥2 schemes); the
re-prompt text the PM chat emits; the developer's reply (a chosen
scheme name); Form E diff after disambiguation.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-multi-scheme`.

#### 3.2.3 F3 — `apple-no-simulator`

**Exercises.** `simctl list devices available` returns empty; Form R
reports no destination; G7-discovery declines.

```bash
F3=/tmp/phase-4-fixtures/apple-no-simulator
rm -rf "$F3"
mkdir -p "$F3"
cd "$F3"
git init -q
"$PACK/scripts/init-project.sh" .

# Same minimal Package.swift as F1, different name.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "F3App", products: [.library(name: "F3App", targets: ["F3App"])],
    targets: [.target(name: "F3App", path: "Sources/F3App")])
EOF
mkdir -p Sources/F3App
echo 'public struct F3App {}' > Sources/F3App/F3App.swift
git add -A && git commit -q -m "F3 baseline"
```

**Simulating "no simulator available" — PATH-based stub (per §0.6
gap-#4 decision).** This Mac genuinely has simulators installed, so
the empty-list condition cannot be reproduced naturally. We simulate
by placing a fake `xcrun` script earlier on `$PATH` than the real one,
**only for the F3 test session**. The agent's invocation of `xcrun`
genuinely runs (subprocess + exit code + stdout); the stub answers
the simulator-list query with empty output and passthrough-execs all
other `xcrun` invocations to the real binary. Procedure 7 sees real
empty output — no chat-side fakery.

```bash
# F3 fixture-local stub bin dir (CLEAN UP via R10-14 in Part 10).
F3_BIN=/tmp/phase-4-fixtures/F3-bin
mkdir -p "$F3_BIN"
cat > "$F3_BIN/xcrun" <<'STUB'
#!/usr/bin/env bash
# Test stub for F3 — simulates a Mac with no Xcode simulators installed.
# Active only when this directory is prepended to PATH.
if [[ "$1 $2 $3" == "simctl list devices available" ]]; then
  echo "== Devices =="
  exit 0
fi
exec /usr/bin/xcrun "$@"   # passthrough for any other xcrun call
STUB
chmod +x "$F3_BIN/xcrun"
which xcrun                       # before stub: /usr/bin/xcrun
export PATH="$F3_BIN:$PATH"
which xcrun                       # after stub:  $F3_BIN/xcrun
xcrun simctl list devices available    # quick sanity: prints "== Devices =="
xcrun --version                       # passthrough sanity: real version output
```

The developer then opens `claude` in `$F3` (the F3 fixture dir) **with
this same shell environment** so the stub PATH is inherited. After the
F3 capture is complete, the stub is removed and PATH restored:

```bash
# After F3 capture — restore PATH and remove stub.
PATH="${PATH#$F3_BIN:}"
which xcrun                       # back to /usr/bin/xcrun
rm -rf "$F3_BIN"
ls -ld "$F3_BIN" 2>&1              # expect: No such file or directory
```

**Expected Procedure 7 behavior.** `xcrun simctl list devices
available` returns the stub's empty output. Form R reports no
destinations. Procedure 7 §7.4 row 4 ("No simulators available")
fires — the assistant declines to compose Form E (cannot fill
`XCODE_DESTINATION` without a destination), proposes `platform=macOS`
only if `[PLATFORM_TARGETS]` includes macOS, otherwise reports the gap
and waits for developer input. G7-discovery yields a "no path
forward" report.

**Capture.** Form R output (verbatim — should show the stub's empty
output); the assistant's §7.4 row-4 behavior text; pass/fail; PATH
restoration confirmation.

**Cleanup.** Two operations (both required, see Part 10 R10-4 + R10-14):

```bash
rm -rf /tmp/phase-4-fixtures/apple-no-simulator
rm -rf /tmp/phase-4-fixtures/F3-bin
```

#### 3.2.4 F4 — `apple-non-spm-layout`

**Exercises.** Non-SPM layout; Form M skips on absence of expected SPM
markers.

```bash
F4=/tmp/phase-4-fixtures/apple-non-spm-layout
rm -rf "$F4"
mkdir -p "$F4"
cd "$F4"
git init -q
"$PACK/scripts/init-project.sh" .

# Stub Xcode-style project — NO Package.swift, NO Sources/.
mkdir -p F4App F4AppTests F4App.xcodeproj
cat > F4App/F4App.swift <<'EOF'
import Foundation
struct F4App {}
EOF
cat > F4AppTests/F4AppTests.swift <<'EOF'
import XCTest
final class F4AppTests: XCTestCase { func testNoOp() {} }
EOF
# Stub xcodeproj sentinel so the directory is recognisable as Xcode-shaped.
touch F4App.xcodeproj/project.pbxproj
git add -A && git commit -q -m "F4 baseline"
```

**Expected Procedure 7 behavior.** Form R discovery still runs (Apple
side). Form E proposes `SWIFT_SOURCE_DIRS="F4App F4AppTests"` in
`scripts/format-swift.sh` (the non-SPM branch documented in
SETUP-NEW.md § 5.A). Form M (companion files) defaults to `skip` per
§7.4 row 8 ("Source layout indeterminate" → conservative).

**Capture.** Form R output; Form E
`SWIFT_SOURCE_DIRS=` proposal verbatim; Form M skip behavior.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-non-spm-layout`.

#### 3.2.5 F5 — `python-grpc-server`

**Exercises.** Python + gRPC; Form I includes `grpcio-tools`.

```bash
F5=/tmp/phase-4-fixtures/python-grpc-server
rm -rf "$F5"
mkdir -p "$F5"
cd "$F5"
git init -q
"$PACK/scripts/init-project.sh" .

# Minimal Python + gRPC fixture.
cat > pyproject.toml <<'EOF'
[project]
name = "f5"
version = "0.0.1"
requires-python = ">=3.11"
dependencies = []
EOF
mkdir -p proto/f5/v1 server
cat > proto/f5/v1/echo.proto <<'EOF'
syntax = "proto3";
package f5.v1;
service Echo { rpc Say (EchoRequest) returns (EchoReply); }
message EchoRequest { string text = 1; }
message EchoReply   { string text = 1; }
EOF
cat > server/main.py <<'EOF'
def main() -> None:
    pass
if __name__ == "__main__":
    main()
EOF
git add -A && git commit -q -m "F5 baseline"
```

**Expected Procedure 7 behavior.** Form R Python lines (8–9 of the
discovery enum) detect `pyproject.toml` + `proto/`. K3 sub-flow fires.
§7.3.1 Form I proposes `brew install bufbuild/buf/buf swift-protobuf
grpc-swift` only if `[PLATFORM_TARGETS]` includes Apple targets;
otherwise skipped. §7.3.2 Form I proposes `uv add grpcio-tools grpcio
grpcio-status grpcio-reflection`.

**Capture.** Form R (Python + gRPC lines visible); §7.3.1 Form I
behavior; §7.3.2 Form I quadruplet verbatim.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/python-grpc-server`.

#### 3.2.6 F6 — `python-only`

**Exercises.** Python without gRPC; Form I skips proto deps.

```bash
F6=/tmp/phase-4-fixtures/python-only
rm -rf "$F6"
mkdir -p "$F6"
cd "$F6"
git init -q
"$PACK/scripts/init-project.sh" .

cat > pyproject.toml <<'EOF'
[project]
name = "f6"
version = "0.0.1"
requires-python = ">=3.11"
dependencies = []
EOF
mkdir -p src/f6
cat > src/f6/__init__.py <<'EOF'
def hello() -> str: return "f6"
EOF
git add -A && git commit -q -m "F6 baseline"
```

**Expected Procedure 7 behavior.** Form R detects `pyproject.toml`
but no `proto/` dir; K3 sub-flow does **not** fire. §7.3.1 / §7.3.2
Form I are not rendered. §7.2.* Apple sub-flow does not fire (no
`[PLATFORM_TARGETS]` Apple value).

**Capture.** Form R output (showing no `proto/`); confirmation that
Form I for gRPC is **not** emitted; pass/fail.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/python-only`.

### 3.3 Per-fixture run procedure (Claude Code CLI, the canonical surface)

The per-fixture run is a **manual step executed by the developer** in
a separate `claude` session. Explicit step-by-step instructions for
the developer live in **Part 13 — M1** (and M3..M7 for F2..F6 under
hybrid expansion). This section focuses on the implementer-side
preconditions and the rationale behind the runbook's reply choices.

**Implementer-side preconditions.** Before reporting "ready for M1"
to the developer, this CLI session must:

1. Have built the F1 fixture per §3.2.1 (or the relevant Fn per §3.2.x).
2. Have generated the placeholder-filled paste file per §3.2.x's
   "Pre-built paste file" sub-step (e.g., `kickoff-paste-F1.txt`).
3. Have confirmed `claude` is on the developer's PATH and the fixture
   path exists.
4. Have not yet started any other manual step that would conflict
   (see Part 9 ordering / parallelization).

**Why the developer replies `skip` rather than `yes` on Form E / I /
M.** The fixture is ephemeral; persisting Form E edits to it adds
nothing to the evidence record (we already capture the proposed diff
verbatim). Skipping preserves the fixture's baseline state — useful
if the developer needs to re-run the same fixture under hybrid
expansion or post-defect retest. Form I `yes` would actually `brew
install`; Form M `yes` would write to `~/Library/Developer/Xcode/`
machine-level. Both are real side effects we don't want in a smoke
test.

### 3.4 §4.1 evidence-block shape (per fixture)

Use the §8 unified template. Each fixture row in
`V10-PHASE-4-VERIFICATION.md` §4.1 has these fields populated:

- Timestamp (UTC, `date -u +%FT%TZ`)
- Surface (e.g., `Claude Code CLI v<output of claude --version>`)
- Fixture name (e.g., `F1 apple-spm-single-scheme`)
- Construction commands run (the §3.2.x block, abbreviated to the
  command list — not re-pasted in full)
- Form R output (verbatim, fenced)
- Form E proposed diff (verbatim, fenced)
- Form I proposed installs (verbatim, fenced)
- Form M proposed companion-files batch (verbatim, fenced)
- Pass / fail
- Deviations vs §3.2.x "Expected Procedure 7 behavior"
- Cleanup confirmation: `rm -rf` exit 0 + `ls -ld
  /tmp/phase-4-fixtures/<name>` returning "No such file" for the
  cleanup audit.

### 3.5 §4.1 failure-mode actions

| If… | Action |
|---|---|
| Form R produces no output (e.g., `xcodebuild` errors out on F4) | Capture the error verbatim; record as deviation; proceed — Procedure 7 §7.4 row 1/8 is the design behavior. |
| Form E produces a regex-style edit to `.claude/settings.json` (forbidden by Procedure 7 §7.2.2) | **Defect.** Flag-back F-G (defect in Procedure 7 wording). Stop §4.1; do not run remaining fixtures until resolved. |
| Form M proposes destructive overwrite without `cmp -s` byte-identity check | **Defect.** F-G. Stop §4.1. |
| Procedure 7 cannot be reached (e.g., kickoff variant breaks before pointer) | **Defect.** F-G mapped to Phase 3-B retrofit. Stop §4.1. |
| Fixture construction step fails (e.g., `init-project.sh` errors) | **Defect** in `init-project.sh` — flag-back F-G (init-project.sh is core infrastructure). Stop §4.1. |
| Surface-side claude/codex/gemini transient (network blip, rate limit) | Retry once. If second attempt fails, move on to the next fixture and note as "deferred — surface transient" (NOT F-B). Re-attempt at end of §4.1. |

### 3.6 §4.1 ordering

Run F1 → F2 → F3 → F4 → F5 → F6. Rationale: F1 is the happy path —
landing F1 first verifies the kickoff → Procedure 7 chain works at all
before exercising the corner cases. F3 (no-simulator) is mid-list
because it requires the manual-stub trick from §3.2.3, which is easier
to apply confidently after F1/F2 have established baseline behavior.

---

## Part 4 — §4.2 Cross-surface docs-research pass (replaces live runs per §0.6)

**Goal of §4.2 (revised under §0.6).** Identify, by close reading of
pack documentation and architectural reasoning, where Codex CLI /
Gemini CLI / Desktop Commander would deviate from the Claude Code CLI
behavior captured in §4.1 — so that any surface-specific defect is
documented for v10.1 follow-up rather than discovered in production.

**Why this replaces live runs.** Project-lead direction (§0.6): live
runs across three additional surfaces multiply test effort without
proportionate yield, given that the Procedure 7 abstraction layer is
designed to be surface-agnostic and the surface-specific behaviors
(Codex sandbox model, Gemini plan-mode handling, Desktop Commander
filesystem-MCP semantics) are documented. The docs-research pass
catches deviations the docs already imply; any deviation the docs do
NOT imply is by definition a v10.1-discoverable defect.

**Reference reading (mandatory before writing the §4.2 evidence
block).**

- `V10-PHASE-3B-DESIGN-v2.md` Part 11 (surface matrix) — the canonical
  per-surface behavior expectations.
- `project-template/docs/pack/prompts/pm-chat.md` lines 23–48 —
  surface-declaration block + plan-mode warning.
- `project-template/docs/pack/PM-CHAT.md` line 124 — RAG-vs-direct-read
  access pattern.
- `supporting-docs/METHODOLOGY.md` Procedure 7 §7.0–§7.7 — the
  procedure each surface executes.
- `maintenance-docs/V10-DESIGN.md` AD-N rows that reference cross-tool
  parity (search for "Codex", "Gemini", "Desktop").
- `maintenance-docs/TOOL-COMPARISON.md` — cross-tool capability
  reference.

### 4.1 Per-surface deviation analysis (one section per surface)

For each of the three deferred surfaces, the §4.2 evidence block
contains a deviation-analysis row covering five dimensions:

| Dimension | What to assess |
|---|---|
| **Surface declaration** | Will pm-chat.md's "Confirm one of: shell / manual" Q/A correctly classify this surface as shell-capable per its own `shell` bullet (lines 44–45)? Cite supporting docs. |
| **Plan-mode handling** | Does the surface have an equivalent of Gemini's plan mode that prevents shell execution? If yes, does pm-chat.md line 24 cover it adequately? |
| **Tool / shell sandbox** | Can the surface actually shell out (real subprocess)? Where is this documented? For sandboxed surfaces (Codex), what's the escalation pattern when a command needs higher privilege than the sandbox grants (e.g., `brew install`)? |
| **METHODOLOGY.md access** | Does the surface read METHODOLOGY.md directly (full procedure body) or via RAG (chunked)? Procedure 7 is order-sensitive; does the surface honor that? |
| **Form R/I/E/M rendering** | Is there any surface-specific rendering quirk (markdown rendering, tool-call wrapping, fence preservation) that would make Forms display incorrectly? |

For each dimension, the analyst notes:
- **Per-docs expected behavior** (cite source line).
- **Risk identified** (none / low / medium / high).
- **v10.1 follow-up flag** (yes / no — and the BACKLOG candidate text
  if yes).

### 4.2 Surfaces in scope (docs-research pass)

| ID | Surface | Authoritative docs | Live run status |
|---|---|---|---|
| DR1 | Codex CLI | `pm-chat.md` line 44 (`shell`-capable enumeration); `METHODOLOGY.md` Phase routing table; `TOOL-COMPARISON.md`; `V10-DESIGN.md` AD-1 cross-tool parity decision; Codex CLI public docs (workspace-write sandbox model) | Deferred to v10.1 per §0.6 |
| DR2 | Gemini CLI | `pm-chat.md` line 24 (plan-mode warning) + line 44 (shell-capable enumeration); `V10-DESIGN.md` BD-043 (Gemini native subagent architecture); `agent-run.sh` translation logic; Gemini CLI public docs | Deferred to v10.1 per §0.6 |
| DR3 | Desktop Commander | `pm-chat.md` line 44–45 ("Claude Desktop with Desktop Commander enabled"); `TOOL-COMPARISON.md`; filesystem-MCP capability docs; Procedure 7 §7.2.4 (machine-level Form M) | Deferred to v10.1 per §0.6 |

If any surface happens to be present in the implementer environment
(see §1.3 optional surfaces), record its presence in the §4.2 evidence
block but **do not opportunistically run a live test** — the scope
decision is "docs research only" and silent expansion is F-E (Phase 4
Plan flag-back).

### 4.3 §4.2 evidence-block shape (per deferred surface)

Use the §8 unified template, with deviation-analysis fields specific
to the docs-research pass. One row per surface (DR1 Codex, DR2 Gemini,
DR3 Desktop Commander). Fields:

- Timestamp
- Surface name (DR1 / DR2 / DR3)
- Reference docs cited (file paths + line numbers — every claim must
  cite a source)
- Per-dimension deviation analysis (table from §4.1, five rows)
- Risk summary (overall: low / medium / high)
- v10.1 follow-up flags (zero or more; each names a BACKLOG candidate
  with title + one-line description)
- Verbatim §1.4 deferred-status wording at the end of the row
- Note: this section emits **no live-run evidence** — that is the
  intended scope per §0.6.

### 4.4 §4.2 ordering

DR1 (Codex) → DR2 (Gemini) → DR3 (Desktop Commander). Rationale:
Codex's sandbox model is the most architecturally distinct from the
Claude Code CLI baseline, so its deviation analysis surfaces the most
likely v10.1 candidates first. Gemini's main risk is plan-mode
behavior (already documented in pm-chat.md). Desktop Commander is the
most surface-similar to Claude Code CLI of the three (same model,
different UI shell), so its analysis is shortest.

### 4.5 §4.2 fixture cleanup

The docs-research pass uses no fixtures. Nothing to clean up at the
end of §4.2. (Live-run procedures from earlier plan revisions used
F1 across all three surfaces; that approach is superseded by §0.6.)

---

## Part 5 — §4.3 Claude Web manual-mode smoke runbook

**Goal of §4.3.** Demonstrate that on a non-shell surface (Claude Web,
no Desktop Commander, no MCP), pasting the kickoff variant and
replying `manual` produces ONLY the `pm-chat.md` continuation pointer
naming `SETUP-NEW.md § Manual fallback` sub-sections 5.A–5.D — no tool
call, no inline command summary.

**Reference spec.** `V10-PHASE-3B-PLAN-v2.md` Part 7 criterion 8;
`V10-PHASE-3B-DESIGN-v2.md` Part 3 row 15 (pointer-only shape);
`V10-PHASE-3B-PLAN-v2.md` §3.3 (verbatim pointer wording).

### 5.1 Runner

**Developer in browser** at `claude.ai`. New chat. **No** project /
**no** GitHub connector / **no** Desktop Commander. The chat must be
unambiguously non-shell — that's the whole point of §4.3.

### 5.2 Paste content (implementer builds the paste file)

The implementer (this CLI session) pre-builds a placeholder-filled
paste file at a known path so the developer never edits the paste
text by hand:

```bash
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' \
    "$PACK/project-template/docs/pack/prompts/pm-chat.md" \
  | sed '$d' \
  | sed \
      -e 's/\[PROJECT_NAME\]/Phase 4 Web Smoke Test/g' \
      -e 's/\[2-3 sentence description of what the project is and does\]/Phase 4 Claude Web manual-mode smoke; no real project, no shell, browser-only./g' \
      -e 's|\[e\.g\., macOS 15+, Xcode 26\.3, Swift 6 / Python 3\.12+\]|macOS 15+, Xcode 26.3, Swift 6|g' \
      -e 's/Phase \[N\] — \[Phase title\] (\[not started \/ in progress\])/Phase 0 — Smoke (not started)/g' \
      -e 's/\[Architecture pattern, e\.g\., MVVM with layered domain\/data\/presentation\]/MVVM/g' \
      -e 's/\[Key protocol decisions, e\.g\., DataStore protocol over SwiftData\]/none for smoke/g' \
      -e 's/\[Any other settled decisions\]/none for smoke/g' \
  > /tmp/phase-4-fixtures/kickoff-paste-W3.txt
wc -l /tmp/phase-4-fixtures/kickoff-paste-W3.txt
# Expected: ~72 lines (variant body + pointer; the trailing
# `## Variant: backlog-status-update` line is stripped by sed '$d').
```

The developer never edits the paste file — they `cat` it (or `pbcopy
< file`) and paste into the Claude Web chat verbatim.

### 5.3 Run procedure

The §4.3 run is a **manual step executed by the developer** in a
browser session. Explicit step-by-step instructions for the developer
live in **Part 13 — M2**.

**Implementer-side preconditions.** Before reporting "ready for M2"
to the developer, this CLI session must:

1. Have generated the placeholder-filled web paste file per §5.2
   (`/tmp/phase-4-fixtures/kickoff-paste-W3.txt`).
2. Have run the §6.6 OQ-VP4-6 confirmation (no network needed for
   M2 — the file is local; just confirm the file exists and is
   the right size, ~70 lines).

The developer's manual sequence is in Part 13 — M2 (steps 1–10).
This section is the implementer's reference for what M2 covers and
how it's verified.

### 5.4 Expected assistant reply (pass criterion)

The assistant's reply must contain the verbatim continuation pointer's
`manual` branch from `pm-chat.md` lines 87–89:

> **On `manual`: I will point you at `supporting-docs/SETUP-NEW.md` §
> Manual fallback (sub-sections 5.A–5.D) and wait for you to report
> values back, then compose the corresponding edits for you to apply.**

**Pass.** The reply names `SETUP-NEW.md § Manual fallback` and the
`5.A–5.D` sub-section range and waits for the developer to report
values. No tool call. No inline `xcodebuild -list` /
`brew install` / `cp ...` command summary.

**Soft pass.** The reply paraphrases the pointer (e.g., "I'll point
you at SETUP-NEW.md's manual fallback section"), but the reference is
unambiguous and lacks tool calls / command summaries. Capture as soft
pass with a note; flag-back F-E if the project lead wants the wording
tightened to verbatim.

**Fail.** Any of:

- The reply contains a tool-call attempt (e.g., `<tool_use>` or
  similar) → defect; pm-chat.md kickoff variant has a defect or the
  surface-declaration prompt is being mis-classified by the model.
  **Flag-back F-G** mapped to Phase 3-B retrofit.
- The reply contains an inline command summary (e.g., a fenced shell
  block with `xcodebuild -list` etc.) → defect; pointer wording is
  wrong (the §3.3 contract is "pointer only, not summary").
  **Flag-back F-G** mapped to Phase 3-B retrofit.
- The reply names `SETUP-NEW.md` Steps 5–8 (the OLD step numbers,
  pre-Phase-3-B) instead of `Manual fallback 5.A–5.D` → **defect**;
  pm-chat.md continuation pointer was not updated. F-G.

### 5.5 Capture format

```
| Field | Value |
|---|---|
| Timestamp | <UTC> |
| Surface | Claude Web (no MCP, no project) |
| Paste source | $PACK/project-template/docs/pack/prompts/pm-chat.md (kickoff variant body, ~72 lines) |
| Reply text | `manual` |
| Assistant reply | <verbatim, fenced> |
| Outcome | pass / soft pass / fail |
| Notes | <deviation if any> |
```

### 5.6 §4.3 dependencies

§4.3 depends on **nothing** in §4.1 / §4.2 / §4.4 / §4.5. Run any
time after Part 1 pre-flight passes. See Part 9 — §4.3 is the
canonical parallelization candidate.

---

## Part 6 — §4.4 Migration script smoke runbook

**Goal of §4.4.** Demonstrate that `scripts/migrate-v9-to-v10.sh`
successfully migrates a representative v9.3 project to the v10 layout
without manual intervention beyond the script's interactive prompts,
and that the post-migration state matches `V10-DESIGN.md` Part 6
§6.10.

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.4;
`V10-DESIGN.md` Part 6;
`supporting-docs/MIGRATION-v9-to-v10.md` (user-facing migration guide).

### 6.1 Critical guardrail

**No git command in this section targets the live pack repo.** The
v9.3 fixture project is constructed entirely under `/tmp/phase-4-
fixtures/v9-project/`. The v9.3-pack-source clone lives at
`/tmp/v9-pack-source/`. Both are independent of the live main pack
worktree at `/Users/david/Developer/dhs-ai-agent-config-pack` and the
v10-dev worktree at `$PACK`. Verify before running each step that the
working directory is `/tmp/phase-4-fixtures/v9-project/` — `pwd`
**must** start with `/tmp/phase-4-fixtures/`.

### 6.2 Prerequisites

- Part 1 pre-flight passed.
- `$PACK` set to the v10-dev worktree.
- v9.3 tag resolvable: `git -C "$PACK" rev-parse v9.3` succeeds.
- `python3` on `$PATH` (used by `merge-platform-skills.py`,
  `validate-pack.py`).

### 6.3 Step 1 — clone the v9.3 pack source (LOCAL clone, no network)

Per §0.6 (OQ-VP4-6 resolution): the pack repo is private on GitHub, so
HTTPS clone would require auth. We sidestep entirely by cloning from
the **local** pack repo at `/Users/david/Developer/dhs-ai-agent-
config-pack`, which already has the v9.3 tag in its history. This is
faster (git uses hard-link optimization for local clones) and uses no
network egress.

```bash
# v9.3 pack source — local clone from live pack repo.
LIVE_PACK=/Users/david/Developer/dhs-ai-agent-config-pack
git -C "$LIVE_PACK" rev-parse v9.3 >/dev/null \
  || { echo "FAIL: v9.3 not in live pack repo"; exit 1; }

rm -rf /tmp/v9-pack-source
git clone --branch v9.3 --depth 1 \
  "$LIVE_PACK" \
  /tmp/v9-pack-source

git -C /tmp/v9-pack-source describe --tags --exact-match HEAD   # expect: v9.3
ls -la /tmp/v9-pack-source/project-template | head -20
```

**Expected.** Clone succeeds (a few seconds, no network); `git
describe` returns `v9.3`; `project-template/` contains the v9.3 layout
(`.claude/agents/`, `docs/pack/PROMPT-TEMPLATES.md`, etc. — the v9.3
baseline invariants the migration script's S0 stage checks for at
lines 130–139 of `scripts/migrate-v9-to-v10.sh`).

**Guardrail.** The local clone creates a fresh repo at
`/tmp/v9-pack-source/` with its own `.git/` directory. Operations on
that clone (or on the v9-project fixture migrated from it) **never**
push to a remote and **never** modify the live pack repo. The live
pack repo is read-only for the duration of §4.4.

### 6.4 Step 2 — construct a minimal v9.3 fixture project

The fixture must be **real enough** that `migrate-v9-to-v10.sh`
exercises the splice / replace / merge paths meaningfully, but **small
enough** that diff inspection is tractable.

```bash
F9=/tmp/phase-4-fixtures/v9-project
rm -rf "$F9"
mkdir -p "$F9"
cd "$F9"
git init -q

# Copy the v9.3 project-template into the fixture.
cp -R /tmp/v9-pack-source/project-template/. .

# Trinity placeholder fill — minimal substitutions.
# `[PROJECT_NAME]` and `[PLATFORM_TARGETS]` are present in CLAUDE.md / AGENTS.md / GEMINI.md.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  [[ -f "$f" ]] && sed -i.bak \
    -e 's/\[PROJECT_NAME\]/PhaseFourSmokeProject/g' \
    -e 's/\[PLATFORM_TARGETS\]/macOS 15+, Swift 6/g' \
    -e 's/\[TRANSPORT\]/(none)/g' \
    "$f" && rm -f "$f.bak"
done

# Active-skills line — fill so PLATFORM-SKILLS merge has something to reconcile.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  [[ -f "$f" ]] && python3 -c "
import sys, pathlib
p = pathlib.Path('$f')
s = p.read_text()
s = s.replace(
    '**Active skills:** [PM chat writes this line during project kickoff',
    '**Active skills:** swift-best-practices, apple-architecture-core, macos-architecture\n[PM chat writes this line during project kickoff'
)
p.write_text(s)
"
done

# Minimal Swift source so any post-migration validation has substance.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "PhaseFourSmokeProject",
    products: [.library(name: "PhaseFourSmokeProject", targets: ["PhaseFourSmokeProject"])],
    targets: [.target(name: "PhaseFourSmokeProject", path: "Sources/PhaseFourSmokeProject")]
)
EOF
mkdir -p Sources/PhaseFourSmokeProject
echo 'public struct PhaseFourSmokeProject { public init() {} }' > Sources/PhaseFourSmokeProject/PhaseFourSmokeProject.swift

# Baseline commit — the migration script requires a clean working tree
# (S0 stage line 102 of migrate-v9-to-v10.sh).
git add -A
git commit -q -m "v9.3 baseline (Phase 4 smoke fixture)"

git status --porcelain   # expect: empty
git log --oneline        # expect: single commit "v9.3 baseline (Phase 4 smoke fixture)"
```

**Expected post-construction state.** Tree is clean; `.claude/agents/`
present; `.gemini/agents/` present (v9.3 carried BD-043);
`docs/pack/PROMPT-TEMPLATES.md` present; `docs/pack/PLATFORM-SKILLS.md`
present; trinity files have placeholder substitutions; one Swift
source. **Confirm before proceeding** — running migration against an
incomplete v9.3 baseline produces noise that's hard to distinguish
from script defects.

### 6.5 Step 3 — run the migration script

```bash
cd /tmp/phase-4-fixtures/v9-project   # MUST be /tmp/...; verify pwd
pwd | grep -q '^/tmp/phase-4-fixtures/v9-project$' || { echo "FAIL: wrong pwd"; exit 1; }

# Run with stdout + stderr captured to disjoint files for clean evidence.
"$PACK/scripts/migrate-v9-to-v10.sh" . \
  > /tmp/phase-4-fixtures/v9-migrate.stdout.txt \
  2> /tmp/phase-4-fixtures/v9-migrate.stderr.txt
echo "Migration exit: $?"
```

**Interactive prompts.** The script may prompt for the
"Resume / Start fresh / Abort" sentinel-cleanup question (S0 stage
line 76); since this is a fresh fixture the prompt should not fire.
If it does fire, type `f` (start fresh) — but this indicates a stale
backup directory that should not exist on a fresh fixture; flag-back
F-E for unexpected state.

**Expected.** Exit 0; stdout shows `S0 complete.` ... `S7 complete.`;
stderr empty or contains only the standard `find` warnings.

### 6.6 Step 4 — post-migration verification

```bash
cd /tmp/phase-4-fixtures/v9-project

# 4a. Working tree dirty (the script does NOT commit — see comment line 19 of script).
git status --porcelain | head -30
git diff --stat | tee /tmp/phase-4-fixtures/v9-migrate.diff-stat.txt

# 4b. v10 layout present.
[[ -d docs/pack/prompts ]]                         && echo "OK: docs/pack/prompts/"
[[ -f docs/pack/METHODOLOGY.md ]]                  && echo "OK: METHODOLOGY.md"
grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md && echo "OK: Procedure 7 present" \
                                                    || echo "WARN: Procedure 7 missing — see §6.7 row 'Procedure 5-R note'"

# 4c. Trinity carries v10 layout.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  grep -q 'docs/pack/' "$f" && echo "OK: $f references docs/pack/" || echo "FAIL: $f missing docs/pack/"
  grep -q 'Capabilities pattern\|capabilities pattern' "$f" && echo "OK: $f mentions capabilities pattern" || echo "WARN: $f missing capabilities pattern"
done

# 4d. Backup directory populated and gitignored.
[[ -d .pack-migration-backup/v9.3-to-v10.0 ]] && echo "OK: backup dir present"
ls .pack-migration-backup/v9.3-to-v10.0/ | head -10
grep -Fxq '.pack-migration-backup/' .gitignore && echo "OK: .gitignore entry present"

# 4e. PROMPT-TEMPLATES.md deleted (per V10-DESIGN Part 6).
[[ ! -f docs/pack/PROMPT-TEMPLATES.md ]] && echo "OK: PROMPT-TEMPLATES.md removed" || echo "FAIL: PROMPT-TEMPLATES.md still present"

# 4f. AF-001 parity — no references to validate.sh / test.sh / format.sh
# in the SETUP-derived files (the AF-001 ship-blocker fix's invariant).
grep -rnE '\b(validate|test|format)\.sh\b' docs/ scripts/ 2>/dev/null \
  | grep -v -- '-swift\.sh\|-python\.sh\|-proto\.sh\|wrappers detect' \
  | head -10
# Expect: only references to wrapper-detect prose and language-specific variants.

# 4g. validate-pack.py is a pack-repo-only check; running it against the
# project tree is NOT part of v10.0's project-level invariants.
# Per V10-PHASE-4-PLAN §4.4: "if it does not apply at the project level,
# skip with note." This plan calls SKIP and records the rationale.
echo "validate-pack.py: SKIPPED at project level — pack-repo-only check per V10-PHASE-4-PLAN §4.4."
```

### 6.7 Pass / fail criteria for §4.4

| Check | Pass | Fail behavior |
|---|---|---|
| Migration exit code | 0 | non-zero → F-G; v10.0 hold; defect in `migrate-v9-to-v10.sh`. |
| `docs/pack/prompts/` exists | yes | F-G; S4 stage failed. |
| `docs/pack/METHODOLOGY.md` exists | yes | F-G; S5 / S6 stage failed. |
| `docs/pack/METHODOLOGY.md` contains `### Procedure 7` | yes (post-Phase-3-B v10) | If missing: evaluate per `V10-PHASE-4-PLAN §4.4` failure-modes row 4 — Procedure 7 in the project copy is sourced from the v10 pack source, so it should land. If the migration somehow installs an older METHODOLOGY.md, F-G. |
| Trinity `docs/pack/` references | present | F-G; trinity splice failure (S5). |
| Capabilities-pattern wording in trinity | present | F-G; trinity splice / merge failed to land BD-045 content. |
| Backup directory present + gitignored | yes | F-G; S0 backup setup defective. |
| PROMPT-TEMPLATES.md absent post-migration | yes (V10-DESIGN §6) | F-G; deletion stage skipped. |
| AF-001 parity (no `validate.sh` / `test.sh` / `format.sh` outside wrapper-detect prose) | yes | F-G; the AF-001 fix did not propagate via migration — likely a script defect. |
| `validate-pack.py` at project level | skipped (per spec) | n/a — not a fail criterion. |
| **Procedure 5-R prompt note.** Script's stdout (per V10-DESIGN §6.10) emits a paste-ready PM-chat prompt that names the right files. | yes | If the prompt names files that do not exist post-migration → F-G. |

### 6.8 Step 5 — fixture cleanup

After §4.4 evidence is captured into
`V10-PHASE-4-VERIFICATION.md`, tear down the fixture and pack-source
clone:

```bash
cd /tmp                                              # leave the fixture
rm -rf /tmp/phase-4-fixtures/v9-project
rm -rf /tmp/v9-pack-source
ls -ld /tmp/phase-4-fixtures/v9-project /tmp/v9-pack-source 2>&1
# Expect: both "No such file or directory"
```

**Do not skip this cleanup** — `/tmp/v9-pack-source` is a full
pack-repo clone with its own `.git` directory (~5 MB+), and orphaning
it confuses any future `find /tmp -name '*.git' -type d` audit.

### 6.9 §4.4 evidence-block shape

Use the §8 unified template. Fields:

- Timestamp
- Surface (Bash on the implementer's Mac)
- Fixture: `/tmp/phase-4-fixtures/v9-project/` (constructed per §6.4)
- v9.3 source: `/tmp/v9-pack-source/` (cloned per §6.3)
- Migration command: `"$PACK/scripts/migrate-v9-to-v10.sh" .` from
  fixture root
- Migration exit code (verbatim)
- `git diff --stat` output (verbatim, fenced)
- §6.6 verification check results (each line of "OK:" / "FAIL:" /
  "WARN:" pasted verbatim)
- Procedure 5-R prompt from script stdout (verbatim, fenced — copied
  from `/tmp/phase-4-fixtures/v9-migrate.stdout.txt`)
- Pass / fail per §6.7 criteria
- Cleanup confirmation (§6.8)

### 6.10 §4.4 ordering and parallelism

§4.4 may run in parallel with §4.1 / §4.2 / §4.3 — it operates on a
disjoint fixture and uses no shared state. In practice, run §4.4 in
this CLI session while the developer runs §4.3 in the browser.

---

## Part 7 — §4.5 detect.sh test results runbook

**Goal of §4.5.** Capture the verbatim output of
`scripts/test-detect.sh` into `V10-PHASE-4-VERIFICATION.md`.

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.5; `scripts/test-detect.sh`
(landed in C-V10-14, commit `459161b`).

### 7.1 Status

The runner already passes 34/34 (re-run during this plan's drafting:
`=== Results: 34 passed, 0 failed ===`). §4.5 is **capture only** —
no fixture construction (the runner builds and tears down its own
fixtures via `mktemp -d`), no decisions, no failure modes that aren't
already F-G.

### 7.2 Capture command

```bash
cd "$PACK"
bash scripts/test-detect.sh > /tmp/phase-4-fixtures/test-detect.out.txt 2>&1
echo "test-detect exit: $?"
tail -5 /tmp/phase-4-fixtures/test-detect.out.txt
wc -l /tmp/phase-4-fixtures/test-detect.out.txt
```

**Expected.** Exit 0; final line `=== Results: 34 passed, 0 failed
===`; ~80 lines total output.

### 7.3 Pass / fail

| Outcome | Action |
|---|---|
| Exit 0 + `34 passed, 0 failed` | Pass. Paste output verbatim into §4.5 evidence block. |
| Exit 0 + count differs from 34 (e.g., 33 passed, 1 failed; or 35 passed if a test was added) | If a failure: F-G; v10.0 hold per Phase 4 Plan F-G (detect.sh defect). If count grew without a failure: flag-back F-E (silent scope expansion — was a test added in scope without plan update?). |
| Exit non-zero | F-G. v10.0 hold. |
| Runner cannot be sourced (e.g., `lib/detect.sh` missing) | F-G. v10.0 hold. |

### 7.4 §4.5 evidence-block shape

Use the §8 unified template. Fields:

- Timestamp
- Surface (Bash; this CLI session)
- Test runner: `scripts/test-detect.sh`
- Pack tip: `git rev-parse HEAD` (e.g., `459161b…`)
- Command: `bash scripts/test-detect.sh`
- Exit code
- Output (verbatim, fenced — paste the entire 34-test output)
- Pass / fail
- Note: re-run was performed at C-V10-15 capture time (not just
  inheriting the C-V10-14 result).

### 7.5 §4.5 dependencies

§4.5 depends on `scripts/test-detect.sh` existing, which lands in
C-V10-14 (`459161b`). Per Gate F entry criterion 6 the harness must
pass before Gate F. §4.5 is the verification artifact for that
criterion.

---

## Part 8 — Unified evidence-capture template

Apply this template to **every** evidence entry across §4.1–§4.5.
Same field set, same shape, different fixture / surface values per
section. Embed inside `maintenance-docs/V10-PHASE-4-VERIFICATION.md`
as the §4.x evidence block(s).

### 8.1 Template (markdown, copy verbatim into V10-PHASE-4-VERIFICATION.md)

```markdown
#### Evidence — <section> — <fixture-or-surface label>

| Field | Value |
|---|---|
| Timestamp (UTC) | YYYY-MM-DDTHH:MM:SSZ |
| Surface | <e.g., Claude Code CLI vX.Y.Z / Codex CLI vX.Y.Z / Gemini CLI vX.Y.Z / Claude Desktop + filesystem MCP / Claude Web (no MCP) / Bash> |
| Fixture or input | <e.g., F1 apple-spm-single-scheme at /tmp/phase-4-fixtures/apple-spm-single-scheme; or "v9.3 fixture project at /tmp/phase-4-fixtures/v9-project"; or "kickoff variant body, ~72 lines from pm-chat.md"> |
| Command(s) run | <copy-paste-safe shell line(s) or chat action(s)> |
| Output (verbatim) | <fenced block> |
| Outcome | pass / soft pass / fail / unavailable (F-B (b)) |
| Notes / deviations | <one-line summary; null if none> |
| Failure-mode link | <flag-back F-N from V10-PHASE-4-PLAN.md Part 8 if outcome is fail or unavailable; null if pass> |
```

### 8.2 Rules for filling the template

- **Verbatim outputs go in fenced blocks.** Use ` ```text ` fences for
  shell stdout; ` ```diff ` for proposed Form E diffs; ` ```json ` for
  `.claude/settings.json` proposals.
- **Soft pass requires a one-line note** explaining the deviation
  from the strict pass criterion.
- **Fail and unavailable rows MUST link to a flag-back ID** from
  `V10-PHASE-4-PLAN.md` Part 8. No silent fail / silent unavailable.
- **Cleanup confirmation is part of the evidence**, not separate. For
  fixture-using sections (§4.1, §4.2, §4.4), append a `Cleanup` field
  to the table:

  ```markdown
  | Cleanup | rm -rf /tmp/phase-4-fixtures/<name>/ — exit 0; ls confirms "No such file or directory". |
  ```

- **Single template, all sections.** Resist the urge to specialise
  per-section schemas. Reviewers reading V10-PHASE-4-VERIFICATION.md
  benefit from one mental model.

### 8.3 Evidence file structure (skeleton of V10-PHASE-4-VERIFICATION.md)

```markdown
# V10-PHASE-4-VERIFICATION.md — C-V10-15 evidence harness

*Captures evidence from five Phase-4 verification streams.*
*Authoritative spec: V10-PHASE-4-PLAN.md Part 4.*
*Per-section runbook: V10-PHASE-4-VERIFICATION-PLAN.md (this file's sibling).*
*Pack tip at capture: <git rev-parse HEAD>.*

## Pre-flight

<paste of /tmp/phase-4-preflight.txt from §1.1>

## §4.1 Fixture evidence

#### Evidence — §4.1 — F1 apple-spm-single-scheme
<template>

#### Evidence — §4.1 — F2 apple-multi-scheme
<template>

... (F3, F4, F5, F6)

## §4.2 Cross-surface checks

#### Evidence — §4.2 — C1 Codex CLI on F1
<template>

#### Evidence — §4.2 — C2 Gemini CLI on F1
<template>

#### Evidence — §4.2 — C3 Desktop Commander on F1
<template>

## §4.3 Claude Web manual-mode smoke

#### Evidence — §4.3 — Claude Web (no MCP)
<template>

## §4.4 Migration script smoke

#### Evidence — §4.4 — migrate-v9-to-v10.sh on /tmp/phase-4-fixtures/v9-project
<template>

## §4.5 detect.sh unit-test results

#### Evidence — §4.5 — bash scripts/test-detect.sh
<template>

## Summary

| Section | Outcome | Notes |
|---|---|---|
| §4.1 | <pass/partial/fail> | <e.g., 6/6 passed> |
| §4.2 | <pass/partial/fail> | <e.g., 3/3 passed; or "C3 unavailable, deferred to v10.1 per F-B (b)"> |
| §4.3 | <pass/soft pass/fail> | |
| §4.4 | <pass/fail> | |
| §4.5 | <pass/fail> | <e.g., 34/34 passed> |

## Flag-backs invoked

<list of F-N rows fired during execution; null if none>
```

---

## Part 9 — Ordering and parallelization

### 9.1 Ordering with rationale (hybrid scope per §0.7)

| Order | Section | Runner | Why this position |
|---|---|---|---|
| 1 | Part 1 pre-flight | this CLI session | Catches missing required surfaces / dirty tree before any state is created. |
| 2 | §4.5 detect.sh capture | this CLI session | Already passing; cheapest evidence; lands first to clear one of five sections. |
| 3 | §4.1 fixture F1 (`apple-spm-single-scheme`) | dev in separate `claude` session | F1 is the happy path; verifies the kickoff → Procedure 7 chain works at all. |
| 4 | **Reassessment checkpoint** | project lead | If F1 surfaces a defect, stop and re-plan. If F1 succeeds, decide whether to expand to F2..F6. |
| 5 | §4.4 migration script smoke | this CLI session | Independent fixture; runs in parallel with §4.3 (next row). |
| 6 | §4.3 manual-mode smoke | dev in browser | Independent of §4.1 / §4.4; runs in parallel with §4.4. |
| 7 | §4.2 docs-research pass | this CLI session | Consumes §4.1 evidence + pack docs; runs after §4.1 capture exists. |
| 8 | §4.1 F2..F6 (CONDITIONAL on hybrid expansion) | dev in separate `claude` session | Only if project lead opts in after step 4 reassessment. Each fixture independently constructed + torn down. |
| 9 | Final cleanup pass (§10.1 single-command rollback) | this CLI session | Tears down all `/tmp/` state. |

### 9.2 Parallelization opportunities

Under hybrid scope:

| Stream A (this CLI session, autonomous) | Stream B (dev-in-claude) | Stream C (dev-in-browser) |
|---|---|---|
| §4.5 capture | (idle) | (idle) |
| (waiting on F1 evidence) | §4.1 F1 build + capture | (idle) |
| §4.4 migration smoke | (idle or continues if F2..F6) | §4.3 manual-mode smoke (parallel) |
| §4.2 docs-research pass | (idle or continues if F2..F6) | (idle) |
| §10.1 cleanup pass | (idle) | (idle) |

Wall-clock estimate (minimal scope, no F2..F6): ~45–75 minutes.

### 9.3 Ordering anti-patterns to avoid

- **Do not** start §4.4 before §4.5 capture if `test-detect.sh` is
  somehow not passing — §4.5 is a Gate F gating signal that should be
  confirmed first.
- **Do not** start §4.2 docs-research pass before §4.1 F1 capture
  exists — the docs-research compares against the F1 evidence.
- **Do not** opportunistically run a live test on Codex / Gemini /
  Desktop Commander even if those surfaces are present — silent scope
  expansion is F-E (Phase 4 Plan flag-back).
- **Do not** parallelize §4.1 F1 build with anything that depends on
  F1 evidence. F1 is the gating fixture.

---

## Part 10 — Rollback table

One row per state-creating operation in this plan. The rollback
command **fully undoes** the state created by the operation. Verify
rollback succeeded with the named verification command.

| # | Operation | State created | Rollback command | Verify rollback |
|---|---|---|---|---|
| R10-1 | Part 1 pre-flight `mkdir /tmp/phase-4-fixtures` | Empty fixture base directory | `rm -rf /tmp/phase-4-fixtures` | `ls -ld /tmp/phase-4-fixtures 2>&1` returns "No such file or directory" |
| R10-2 | §3.2.1 F1 construction | `/tmp/phase-4-fixtures/apple-spm-single-scheme/` with git history + SPM source | `rm -rf /tmp/phase-4-fixtures/apple-spm-single-scheme` | `ls` confirms absence |
| R10-3 | §3.2.2 F2 construction | `/tmp/phase-4-fixtures/apple-multi-scheme/` | `rm -rf /tmp/phase-4-fixtures/apple-multi-scheme` | `ls` confirms |
| R10-4 | §3.2.3 F3 construction | `/tmp/phase-4-fixtures/apple-no-simulator/` | `rm -rf /tmp/phase-4-fixtures/apple-no-simulator` | `ls` confirms |
| R10-5 | §3.2.4 F4 construction | `/tmp/phase-4-fixtures/apple-non-spm-layout/` | `rm -rf /tmp/phase-4-fixtures/apple-non-spm-layout` | `ls` confirms |
| R10-6 | §3.2.5 F5 construction | `/tmp/phase-4-fixtures/python-grpc-server/` | `rm -rf /tmp/phase-4-fixtures/python-grpc-server` | `ls` confirms |
| R10-7 | §3.2.6 F6 construction | `/tmp/phase-4-fixtures/python-only/` | `rm -rf /tmp/phase-4-fixtures/python-only` | `ls` confirms |
| R10-8 | §6.3 v9.3 pack-source clone | `/tmp/v9-pack-source/` (~5 MB+ git clone) | `rm -rf /tmp/v9-pack-source` | `ls -ld /tmp/v9-pack-source 2>&1` returns "No such file or directory" |
| R10-9 | §6.4 v9.3 fixture project | `/tmp/phase-4-fixtures/v9-project/` (project + git history + .pack-migration-backup/) | `rm -rf /tmp/phase-4-fixtures/v9-project` | `ls` confirms |
| R10-10 | §5.2 kickoff-paste extract | `/tmp/phase-4-fixtures/kickoff-variant-paste.txt` | `rm -f /tmp/phase-4-fixtures/kickoff-variant-paste.txt` | `ls` confirms |
| R10-11 | §6.5 migration stdout/stderr | `/tmp/phase-4-fixtures/v9-migrate.{stdout,stderr,diff-stat}.txt` | `rm -f /tmp/phase-4-fixtures/v9-migrate.*` | `ls /tmp/phase-4-fixtures/v9-migrate.* 2>&1` returns "No such file" |
| R10-12 | §7.2 detect.sh capture | `/tmp/phase-4-fixtures/test-detect.out.txt` | `rm -f /tmp/phase-4-fixtures/test-detect.out.txt` | `ls` confirms |
| R10-13 | §1.1 pre-flight scratch | `/tmp/phase-4-preflight.txt` | `rm -f /tmp/phase-4-preflight.txt` | `ls` confirms |
| R10-14 | §3.2.3 F3 PATH stub | `/tmp/phase-4-fixtures/F3-bin/xcrun` (exec stub) + PATH env modification | `PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"; rm -rf /tmp/phase-4-fixtures/F3-bin` | `which xcrun` returns `/usr/bin/xcrun` (NOT the stub); `ls -ld /tmp/phase-4-fixtures/F3-bin 2>&1` returns "No such file or directory" |

### 10.1 Single-command full-rollback

After C-V10-15 lands and Gate F is approved, all `/tmp/` state can be
torn down with one command. **Important: also restore PATH if the
F3 stub was used** — the stub PATH modification is process-local, but
if the implementer is still in the shell where they exported it,
restoring is required:

```bash
# If F3 stub was used, restore PATH first.
PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"

# Then tear down all /tmp/ state.
rm -rf /tmp/phase-4-fixtures /tmp/v9-pack-source /tmp/phase-4-preflight.txt
ls -ld /tmp/phase-4-fixtures /tmp/v9-pack-source /tmp/phase-4-preflight.txt 2>&1
# Expect: three "No such file or directory" lines.

# Sanity: confirm xcrun resolves to the real binary.
which xcrun
# Expect: /usr/bin/xcrun
```

This is the canonical Phase-4 cleanup. Run it as the last step of
C-V10-15 evidence capture (after the V10-PHASE-4-VERIFICATION.md file
is written and reviewed) — recorded as a single line in the §4.x
cleanup field.

### 10.2 Rollback for partial-failure states

If §4.1 / §4.2 / §4.4 is interrupted mid-run (e.g., implementer pauses
for an F-B / F-G decision), **do NOT rollback partial fixture state
yet.** Leave fixtures in place so resume can pick up cleanly. The
fixture base `/tmp/phase-4-fixtures/` is volatile across reboots, so
even an indefinite pause is tolerable.

When a fixture is permanently abandoned (e.g., F-G escalates to a
v10.0 hold and the pack drops back to a `fix:` cycle), the
implementer:

1. Notes the abandoned-fixture state in the V10-PHASE-4-VERIFICATION.md
   §4.x evidence block (mark the row "incomplete — fixture preserved
   for resume").
2. Decides whether to retain or tear down the fixture; default is
   tear down (per §10.1 single-command rollback) and reconstruct on
   resume.

### 10.3 What never gets rolled back from `/tmp/`

Nothing. Every `/tmp/` artifact created by this plan has a rollback
row. If during execution the implementer creates additional `/tmp/`
state not covered here, **add a row to §10 before proceeding**.

---

## Part 11 — Gate-F-readiness entry checklist (prerequisites for C-V10-15 execution)

C-V10-15 may begin only when all rows below are true. Run each check
verbatim; capture the output for the C-V10-15 commit-approval request.

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | C-V10-14 landed cleanly | `git -C "$PACK" log --oneline -1` | First word of message: `feat:`; subject mentions `test-detect.sh`. SHA is `459161b…` or descendant. |
| 2 | v10-dev tip is at or descended from `459161b` | `git -C "$PACK" merge-base --is-ancestor 459161b HEAD && echo OK` | `OK` |
| 3 | `PACK` exported to v10-dev | `echo "$PACK"` | `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev` |
| 4 | Working tree clean | `git -C "$PACK" status --porcelain` | empty |
| 5 | On `v10-dev` branch | `git -C "$PACK" rev-parse --abbrev-ref HEAD` | `v10-dev` |
| 6 | `validate-pack.py` passes at HEAD | `python3 "$PACK/scripts/validate-pack.py"` | exit 0 |
| 7 | `test-detect.sh` passes at HEAD | `bash "$PACK/scripts/test-detect.sh" \| tail -1` | `=== Results: 34 passed, 0 failed ===` |
| 8 | v9.3 tag resolvable | `git -C "$PACK" rev-parse v9.3` | non-empty SHA |
| 9 | `/tmp/phase-4-fixtures/` available (writable, no stale fixtures) | `mkdir -p /tmp/phase-4-fixtures && ls /tmp/phase-4-fixtures` | empty (or pre-existing fixtures from a prior run that the implementer accepts via §10.1 cleanup before starting) |
| 10 | Surface-availability pre-flight (Part 1) recorded | Part 1 §1.1 commands run; results captured to `/tmp/phase-4-preflight.txt` | F-B fired only if a surface is missing; project lead resolution noted |
| 11 | `V10-PHASE-4-VERIFICATION.md` does NOT yet exist | `ls "$PACK/maintenance-docs/V10-PHASE-4-VERIFICATION.md" 2>&1` | "No such file or directory" |
| 12 | Live pack worktree (`/Users/david/Developer/dhs-ai-agent-config-pack`) is independent | `git -C /Users/david/Developer/dhs-ai-agent-config-pack rev-parse --abbrev-ref HEAD` | `main` (NOT v10-dev — this plan never touches the live worktree) |

If any row fails, **do not start C-V10-15.** Resolve first.

### 11.1 Approval surface for C-V10-15

Beyond the entry checklist, the C-V10-15 commit itself follows the
`V10-PHASE-4-PLAN.md` Part 7 per-commit verification checklist:

- Staged file is exactly one: `maintenance-docs/V10-PHASE-4-VERIFICATION.md`.
- Diff scope ~150–300 lines added (per Part 3 of Phase 4 Plan).
- All five sections present (§4.1, §4.2, §4.3, §4.4, §4.5).
- Every fail / unavailable entry references a Part 8 flag-back row.
- `validate-pack.py` exits 0 post-stage.
- Approval gate **G-V10-15** before `git commit`.

---

## Part 12 — Open questions for the project lead

Status legend: **RESOLVED** = decided pre-execution per §0.6 / §0.7;
**MOOT** = no longer applies after a related decision; **DEFERRED** =
needs execution context to answer.

1. **OQ-VP4-1 — Desktop Commander confirmation method.** **MOOT.**
   §0.6 deferred Desktop Commander to the §4.2 docs-research pass;
   no live-presence check is required. Original question: is the
   project lead comfortable with self-reported Desktop Commander
   availability vs. a config-file check? Resolution: irrelevant under
   docs-research scope.

2. **OQ-VP4-2 — F3 simulator stub method.** **RESOLVED — PATH-based
   stub** (§0.6, gap-#4 decision). §3.2.3 uses a fixture-local
   `/tmp/phase-4-fixtures/F3-bin/xcrun` script that the agent really
   invokes; the stub returns empty for `simctl list devices available`
   and passes through every other invocation. Real subprocess +
   exit code + stdout — no chat-side fakery.

3. **OQ-VP4-3 — F2 multi-scheme disambiguation reply.** **DEFERRED to
   execution context.** Whether the model genuinely re-prompts for a
   scheme name (per Procedure 7 §7.5) or auto-picks must be observed
   live. F2 only fires under hybrid-expansion scope (§0.7 step 7), so
   this OQ may not need to be resolved for v10.0 if minimal scope
   holds. Default if F2 runs: auto-pick = fail (defect, Procedure 7
   requires explicit disambiguation).

4. **OQ-VP4-4 — §4.4 fixture realism.** **RESOLVED — thin v9.3
   fixture for v10.0** (§0.6). §6.4 builds the minimal fixture; a
   richer v9.3 fixture (x-files, custom skills, populated
   PROMPT-TEMPLATES.md) is a v10.1 candidate. BACKLOG entry to be
   filed if this resolution holds at Gate F.

5. **OQ-VP4-5 — Evidence-file size discipline.** **RESOLVED — verbatim
   beats abbreviation; no hard ceiling** (§0.6). The file is one-shot
   reference, not steady-state; reviewer cost is one-time. Implementer
   does not abbreviate Form R / Form E outputs.

6. **OQ-VP4-6 — Network egress for §6.3 clone.** **RESOLVED — local
   clone from `/Users/david/Developer/dhs-ai-agent-config-pack`**
   (§0.6). §6.3 was rewritten to clone from the live pack repo
   (which has the v9.3 tag locally), eliminating network dependency
   and sidestepping the private-repo HTTPS auth issue. No offline-
   fallback needed.

7. **OQ-VP4-7 — Brew-install escalation wording.** **MOOT.** §0.6
   deferred Codex CLI live runs to the §4.2 docs-research pass; the
   docs-research pass cites the V10-PHASE-3B-DESIGN-v2 Part 3 §3.2
   wording as the documented expectation, without comparing against a
   live Codex output. Original question (live wording exact-match vs.
   equivalent) is not asked under docs-research scope.

---

## Part 13 — Manual-step instructions (developer-facing)

These are the explicit, copy-pasteable instructions for **every** step
the developer (project lead) executes during C-V10-15. The implementer
(this CLI session) handles fixture construction, paste-file generation,
migration smoke, docs-research, evidence assembly, and cleanup. The
developer's only manual touchpoints are listed here.

Under hybrid scope (§0.7 minimal path), the developer executes **M1**
and **M2** only. **M3..M7** are conditional on hybrid expansion.

Each manual step assumes:

- The implementer has reported "ready for **M-N**" in this CLI session.
- The relevant fixture and paste file exist (the implementer confirms
  this before handing off).
- The developer has at least two terminal windows open (or one terminal
  + one browser) at the same time.

### M1 — Run §4.1 F1 smoke in a separate `claude` session

**When:** After the implementer reports "F1 fixture built; paste file
at `/tmp/phase-4-fixtures/kickoff-paste-F1.txt`; ready for M1."

**Estimated time:** 5–10 minutes (mostly waiting on the assistant).

**Where:** A NEW terminal window (NOT the one this CLI session is
running in).

**What you'll do:** Open a fresh `claude` session inside the F1
fixture, paste the kickoff variant, walk through Form R / E / I / M,
and save the assistant's outputs to two evidence files.

**Steps:**

1. Open a new terminal window.
2. Run:

   ```bash
   cd /tmp/phase-4-fixtures/apple-spm-single-scheme
   ```

3. Confirm the paste file is present:

   ```bash
   ls -la /tmp/phase-4-fixtures/kickoff-paste-F1.txt
   ```

   Expect: a file ~70 lines long. If missing, stop and tell the
   implementer.

4. Optionally peek at the paste content:

   ```bash
   cat /tmp/phase-4-fixtures/kickoff-paste-F1.txt | head -30
   ```

5. Copy the paste content to your clipboard:

   ```bash
   pbcopy < /tmp/phase-4-fixtures/kickoff-paste-F1.txt
   ```

6. Start a fresh Claude Code CLI session in this terminal:

   ```bash
   claude
   ```

   You should see the Claude Code CLI prompt.

7. Paste the kickoff variant into the `claude` session (Cmd+V). Press
   Enter to send.

8. Wait for the assistant's reply. Within a turn or two, it should ask
   the surface-declaration question (looks like: "Reply with the single
   word `shell` or `manual` before continuing.").

9. Type exactly: `shell`

   Press Enter.

10. Wait for the assistant to read METHODOLOGY.md Procedure 7 and
    present **Form R** — a code-fenced block headed
    `PROPOSED ACTION — read-only discovery`. The block lists ~11
    discovery commands (xcodebuild, simctl, brew, etc.).

11. Type exactly: `yes`

    Press Enter. The assistant runs the discovery commands.

12. Wait for the assistant's next reply showing the discovery results.
    Once you have the assistant's full reply visible, COPY the entire
    reply (every line of the assistant's message — from the start of
    the message to the next user-input prompt).

13. Save the copied reply to an evidence file. Easiest method:

    ```bash
    # In a third terminal (or pause the claude session with Ctrl+Z and
    # `bg` if you prefer), run:
    open -e /tmp/phase-4-fixtures/evidence-F1-form-r.txt
    # In the editor that opens: paste (Cmd+V), save (Cmd+S), close.
    ```

    Or via clipboard:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-F1-form-r.txt
    ```

14. Back in the `claude` session: the assistant should now propose
    **Form E** (file edits to validate-swift.sh / test-swift.sh /
    .claude/settings.json / format-swift.sh).

    Type exactly: `skip`

    Press Enter.

15. The assistant should now propose **Form I** (install swift-format
    via brew). Type exactly: `skip`. Press Enter.

16. The assistant should now propose **Form M** (Xcode companion
    files). Type exactly: `skip`. Press Enter.

17. The assistant should now print a "kickoff complete" or equivalent
    summary. COPY the entire summary reply.

18. Save the summary to:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-F1-final.txt
    ```

19. Exit the `claude` session: type `/exit` (or press Ctrl+D).

20. Return to the terminal running this implementer CLI session and
    say (in chat):

    > **M1 done. Evidence files at:
    > `/tmp/phase-4-fixtures/evidence-F1-form-r.txt`
    > `/tmp/phase-4-fixtures/evidence-F1-final.txt`.**

The implementer will then read those files and ask follow-up questions
if anything looks off.

**If anything diverges (no Form R, error message, surface-declaration
question doesn't fire, assistant tries to actually run brew install
without asking, etc.) — STOP** and tell the implementer what happened.
Do not try to "fix" the assistant's behavior; the test is to observe
what it does.

---

### M2 — Run §4.3 Claude Web manual-mode smoke

**When:** After the implementer reports "Web paste file at
`/tmp/phase-4-fixtures/kickoff-paste-W3.txt`; ready for M2." Can run
in parallel with the implementer's §4.4 migration smoke.

**Estimated time:** 2–3 minutes.

**Where:** Browser at `claude.ai`.

**What you'll do:** Open a fresh non-shell Claude Web chat, paste the
kickoff variant, reply `manual`, and save the assistant's reply to an
evidence file.

**Steps:**

1. Open a browser to `https://claude.ai`.

2. Start a NEW chat. Critical preconditions:

    - **No project** selected (top-left should not show a project
      name; if it does, click "New Chat" without a project).
    - **No GitHub connector** active (if a connector banner shows
      at the top of the chat, dismiss it or start over).
    - **No Desktop Commander / no MCP** — Claude Web has no MCP
      surface by default; just confirm you're at `claude.ai` and
      not Claude Desktop.

3. (Switch to your terminal.) Copy the Web paste file to clipboard:

    ```bash
    pbcopy < /tmp/phase-4-fixtures/kickoff-paste-W3.txt
    ```

4. Switch back to the browser. Paste into the chat input (Cmd+V).
   Press Enter (or click Send).

5. Wait for the assistant's first reply. It may proceed directly to
   the surface-declaration question or first echo back your project
   context.

6. Once the surface-declaration question appears (asking for `shell`
   or `manual`), type exactly: `manual`

    Press Enter (or click Send).

7. Wait for the assistant's next reply. It should be SHORT (a few
   lines) and contain wording like:

    > On `manual`: I will point you at `supporting-docs/SETUP-NEW.md`
    > § Manual fallback (sub-sections 5.A–5.D) and wait for you to
    > report values back, then compose the corresponding edits for
    > you to apply.

8. COPY the entire assistant reply.

9. (Switch to your terminal.) Save the reply:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-web-manual.txt
    ```

10. Return to this implementer CLI session and say:

    > **M2 done. Evidence file at
    > `/tmp/phase-4-fixtures/evidence-web-manual.txt`.**

**Pass / fail clues for M2 (what to watch for during step 7):**

- ✅ **PASS:** Reply is short, names `SETUP-NEW.md § Manual fallback`
  and the `5.A–5.D` sub-section range. No tool calls. No inline shell
  commands.
- ⚠️ **SOFT PASS:** Reply paraphrases the pointer but reference is
  unambiguous and contains no tool calls / no command lists. Tell
  the implementer; we'll evaluate together.
- ❌ **FAIL — tool call:** Reply contains text like "let me run
  xcodebuild..." with actual command output, OR a `<tool_use>` block.
  Stop, tell the implementer; this is a defect.
- ❌ **FAIL — inline command summary:** Reply contains a fenced shell
  block with `xcodebuild`, `brew install`, etc. instead of pointing
  at SETUP-NEW.md. Stop, tell the implementer; this is a defect.

---

### M3..M7 — Run §4.1 F2..F6 smokes (CONDITIONAL on hybrid expansion)

**When:** ONLY if §4.1 F1 (M1) succeeded and the project lead opts
to expand coverage to corner cases (§0.7 step 7). Implementer will
explicitly ask before kicking off any of M3..M7.

**Estimated time:** 5–10 minutes per fixture.

**Pattern:** Identical to M1, with these per-fixture substitutions:

| ID | Fixture | Paste file | Evidence files |
|---|---|---|---|
| M3 | F2 `apple-multi-scheme` | `/tmp/phase-4-fixtures/kickoff-paste-F2.txt` | `evidence-F2-form-r.txt`, `evidence-F2-final.txt` |
| M4 | F3 `apple-no-simulator` | `/tmp/phase-4-fixtures/kickoff-paste-F3.txt` | `evidence-F3-form-r.txt`, `evidence-F3-final.txt` |
| M5 | F4 `apple-non-spm-layout` | `/tmp/phase-4-fixtures/kickoff-paste-F4.txt` | `evidence-F4-form-r.txt`, `evidence-F4-final.txt` |
| M6 | F5 `python-grpc-server` | `/tmp/phase-4-fixtures/kickoff-paste-F5.txt` | `evidence-F5-form-r.txt`, `evidence-F5-final.txt` |
| M7 | F6 `python-only` | `/tmp/phase-4-fixtures/kickoff-paste-F6.txt` | `evidence-F6-form-r.txt`, `evidence-F6-final.txt` |

**M4 (F3 no-simulator) special handling.** Before starting `claude`
in step 6 of M1, the F3 PATH stub (§3.2.3) must be active in your
shell:

```bash
cd /tmp/phase-4-fixtures/apple-no-simulator
export PATH="/tmp/phase-4-fixtures/F3-bin:$PATH"
which xcrun                       # MUST show /tmp/phase-4-fixtures/F3-bin/xcrun
xcrun simctl list devices available  # MUST print "== Devices ==" (empty)
claude
# Continue with M1 steps 7–20.
```

After M4 completes, **restore PATH** before any other manual step:

```bash
PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"
which xcrun                       # Must show /usr/bin/xcrun
```

Per-fixture pass criteria differ slightly (F2 expects multi-scheme
disambiguation prompt; F3 expects "no destinations" report; F4 expects
SWIFT_SOURCE_DIRS proposal; F5 expects gRPC Form I; F6 expects no
gRPC Form I). The implementer will tell you what to watch for before
each one.

---

### M-Index — How to know which step is next

After each manual step completes, the implementer reports back:

| Reported message | Next step |
|---|---|
| "F1 fixture built; ready for M1." | Run M1. |
| "Web paste file ready; you can run M2 in parallel with §4.4 if you like." | Run M2 any time. |
| "F1 capture good; recommend hybrid expansion to F2 (M3)." | Decide: expand or stop. |
| "F2 fixture built; ready for M3." | Run M3 (only if you opted in). |
| (similarly for M4..M7) | Same pattern. |
| "All manual steps done; assembling evidence file." | No action — wait for commit-approval request. |

**You never proceed to a manual step without an explicit "ready for
M-N" signal from the implementer.** That signal means the fixture is
built, the paste file exists, and any prerequisite stubs are in place.

---

*End of V10-PHASE-4-VERIFICATION-PLAN.md.*
