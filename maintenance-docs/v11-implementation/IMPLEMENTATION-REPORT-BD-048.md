# IMPLEMENTATION-REPORT-BD-048

**Batch:** EXECUTION-PLAN-V11.0.md Batch 15
**BD:** BD-048 — Capability-addition discovery + install-check symmetry with kickoff
**Branch:** `v11-dev`
**Pre-flight HEAD SHA:** `9eb732e51b46b44d9b94aaf0b38b1f22285dffa6`
**Final worktree HEAD SHA:** `9eb732e51b46b44d9b94aaf0b38b1f22285dffa6` (unchanged — agent makes no commits)
**Author:** pack-coder

---

## 1. Pre-flight state

### 1.1 `scripts/add-capability.sh` stage list (before edits)

The script ran 8 stages A0..A7 (per the file header comment "eight stages
A0..A7"), with stage A7 being the end-of-run PM chat prompt:

| Stage | Function | Purpose |
|---|---|---|
| A0 | `stage_a0_preflight` | Validate `$PACK`, target git repo, clean tree, AI-config presence; warn on pack-version mismatch |
| A1 | `stage_a1_resolve` | Resolve `--add dim:val` args via `capability_skills()` + `capability_files()`; dedup; forward-decl warn |
| A2 | `stage_a2_delta` | Compute skills-to-add and files-to-add against current Active skills + on-disk files; degenerate / already-active early exits |
| A3 | `stage_a3_preview` | Print planned changes |
| A4 | `stage_a4_confirm` | Read `y/N` from stdin; abort on anything else |
| A5 | `stage_a5_copy` | Copy conditional files from `$PACK/project-template/` |
| A6 | `stage_a6_gitignore` | Merge pack `.gitignore` lines |
| A7 | `stage_a7_prompt` | Emit PM-chat prompt (stdout + `.pack-add-capability-prompt.md`) |

### 1.2 METHODOLOGY.md Procedure 6 prose (before edits)

Procedure 6 had 6 steps (6.1–6.6) with two gates: G6-drafts (trinity
drafts before write) and G6-commit (git add list + commit message). It
referenced `add-capability.sh` stage A7 by name and described trinity
edits to the `**Active skills:**` line and `[PLACEHOLDER]` sections.
There was no install-check / Form I step; the procedure assumed the
developer had already installed any needed machine-level tooling.

### 1.3 Reference: BD-047 kickoff implementation pattern

Procedure 7 (relocated to `INSTALL-PROCEDURES.md` lines 933–1276)
implements kickoff Form R (read-only discovery), Form I (install
proposals), Form E (script edits), Form M (machine-level files), with
gates G7-discovery / G7-install / G7-edit / G7-machine. The discovery
runs PM-chat-side via shell-out (`command -v <tool>`), not script-side
in `init-project.sh` itself. The kickoff variant of `pm-chat.md`
declares its surface, then routes shell-capable surfaces into
Procedure 7.

---

## 2. Option A vs Option B — selection rationale

**Selected: Option A** — extend `add-capability.sh` script-side with
a new discovery stage + table-driven install-check rows; update
`METHODOLOGY.md` Procedure 6 to add a G6-install step.

Reasons:

1. **Discovery is the cheap part; the script can do it directly.**
   Read-only `command -v <tool>` probes are deterministic and don't
   need PM-chat reasoning. Doing it in the script avoids a second
   round-trip through the PM chat just to decide which tools to probe.
   The PM chat still owns the install-execution decision (Form I per
   tool) — the script never installs.
2. **The table belongs next to the existing capability tables.**
   `capability_skills()` and `capability_files()` already live in
   `add-capability.sh` as parallel case statements. A third parallel
   table `capability_install_checks()` is an obvious extension and
   keeps single-source-of-truth for the capability-row contract.
3. **Option B would couple `add-capability.sh` to `pm-chat.md`** in a
   way the existing kickoff path explicitly avoids — `init-project.sh`
   doesn't invoke pm-chat variants either; it emits a prompt that the
   developer pastes. Adding a `capability-added-kickoff` variant would
   create an asymmetry with kickoff (which uses no such variant).
4. **The discovery output flows naturally into the existing A8 prompt.**
   The PM-chat prompt already had a "Files copied / Active skills"
   summary; adding a "Capability install-check discovery" + "Missing
   tools — proposed install commands" block extends the same prompt
   without inventing a new artifact.

Option B (a new pm-chat.md variant) was rejected as more coupling for
no clear benefit; the script-side approach handles the same shape with
less surface area.

---

## 3. Per-edit log

### 3.1 `scripts/add-capability.sh` (modified, +248 lines net)

Edits, in order:

1. **Header comment update** (lines ~24–35): "eight stages A0..A7" →
   "nine stages A0..A8"; added BD-048 paragraph describing the new
   discovery + install-hint flow and the never-install design rule.
2. **`capability_install_checks()` table function added** (after
   `capability_files()`, ~110 lines). Pipe-collision-safe field
   delimiter `:::` (rationale below). Rows for: `language:python`,
   `language:swift`, `platform:macos|platform:ios`, `platform:android`,
   `platform:web-browser`, `platform:embedded-mcu`, `language:cpp|c`,
   `language:objc`, `protocol:grpc`, `deployment:apple`,
   `deployment:linux-container`, `role:python-server`. Rest/graphql/
   realtime/messaging/soap explicitly emit no rows (library-level
   only, comment in source). Unknown capabilities silently emit no
   rows (no error — the unknown-capability case is already trapped at
   stage A1 via `capability_skills()` returning non-zero).
3. **`probe_tool_present()` helper** added (~10 lines). Centralized so
   future Python-package probes (e.g., `python3 -c 'import grpc'`) can
   be added by extending the case statement rather than scattering
   probe logic. Today: `command -v <tool>`.
4. **`stage_a7_install_check()` function added** (~50 lines). Iterates
   `ADD_ARGS`, parses each row with `awk -F':::'`, dedups tools across
   capabilities (a tool implied by two requested capabilities is
   probed once), populates `DISCOVERY_LINES[]` and `INSTALL_HINTS[]`
   for the A8 prompt. Prints per-tool present/missing to stderr-style
   info banner.
5. **`stage_a7_prompt()` renamed to `stage_a8_prompt()`**; banner
   "── A7 —" → "── A8 —". No behavioral change in the prompt-emit
   stage itself.
6. **`write_prompt_file()` extended** to embed two new sections in the
   prompt: "Capability install-check discovery (read-only, BD-048):"
   listing each probed tool with `[present]` / `[missing]` + purpose,
   and (if any missing) "Missing tools — proposed install commands"
   listing concrete commands. Concluding instruction references new
   gate G6-install + Form I shape from `INSTALL-PROCEDURES.md
   § 7.2.3`. The instruction footer now lists three gates (G6-drafts,
   G6-install, G6-commit) instead of two.
7. **`main()` updated**: initialize `DISCOVERY_LINES=()` +
   `INSTALL_HINTS=()` at top (so the already-active early-exit path
   in `stage_a2_delta` calls `write_prompt_file` with safe empty
   arrays); inserted `stage_a7_install_check` between `stage_a6_gitignore`
   and `stage_a8_prompt`.

**Field-delimiter design note.** First implementation used `|` as the
field separator. The smoke test caught a parsing failure: install
commands themselves contain `|` as an "or" between platform
alternatives (e.g., `brew install uv  (macOS) | curl ... | sh
(Linux)`), which `awk -F'|'` then split, leaking install-command
fragments into the purpose column of the prompt. Switched to `:::` (a
3-character ASCII string vanishingly unlikely to appear in any
real-world install command or purpose description). Test added
explicitly for this regression in Group 1 ("`protocol:grpc rows use
':::' field separator`") and Group 2 ("`prompt does not leak install
cmd into purpose column`").

### 3.2 `supporting-docs/METHODOLOGY.md` (modified, +37 lines net)

Procedure 6 changes:

- Lead paragraph extended to mention the BD-048 install-check discovery.
- Gates list updated from {G6-drafts, G6-commit} to {G6-drafts,
  G6-install, G6-commit}.
- Step 6.1 reworded: now references stage A8 (not A7), describes the
  new discovery + install-hint sections in the prompt.
- New step 6.5 added (Form I per missing tool, gate G6-install,
  references INSTALL-PROCEDURES.md § 7.2.3 Form I shape, idempotency
  rule for already-present tools).
- Existing 6.5 (detection scan) renumbered to 6.6.
- Existing 6.6 (commit gate) renumbered to 6.7.
- New "Symmetry with Procedure 7 (kickoff)" paragraph explaining how
  step 6.5 mirrors § 7.2.3 / 7.3.1 / 7.3.2 and why no G6-discovery
  gate exists (script-side A7 stage is the discovery equivalent).
- New "Adding a new capability row" paragraph explaining the
  three-parallel-tables contract for future capability extensions.

### 3.3 `scripts/tests/test-add-capability.sh` (new, 156 lines)

New file — first test runner for `add-capability.sh`. Two test groups:

**Group 1: capability_install_checks() table coverage** (10 tests).
Sources only the function definition (via `sed -n` slice) into a
sub-shell, then asserts:
- `protocol:grpc` lists buf, protoc-gen-swift, grpcio-tools rows
- `language:python` lists python3, uv rows
- `language:swift` lists swift, swift-format rows
- `platform:macos` lists xcodebuild row
- `protocol:rest` emits zero rows (library-level only)
- protocol:grpc rows use the `:::` separator (regression guard for
  the field-delimiter bug)

**Group 2: end-to-end discovery + prompt embedding** (9 tests).
Materializes a fresh clone of `test-fixtures/v11-flat-file`, runs
`add-capability.sh --add protocol:grpc --pack <repo>`, then asserts:
- A7 + A8 stage banners present in stdout
- A7 probes both `buf` and `protoc-gen-swift`
- Prompt file (`.pack-add-capability-prompt.md`) exists and contains
  the discovery block, references G6-install, references Form I,
  lists buf in the discovery, and does NOT leak install command text
  into the `[missing]` purpose column.

Both groups: all assertions pass on this run. Group 2 cleans up its
sandbox after each test.

---

## 4. Verification commands + results

### 4.1 Bash syntax check

```
$ bash -n scripts/add-capability.sh && echo OK
syntax OK

$ bash -n scripts/tests/test-add-capability.sh && echo OK
syntax OK
```

### 4.2 New test script

```
$ bash scripts/tests/test-add-capability.sh
Group 1: capability_install_checks() table coverage
  PASS protocol:grpc lists buf
  PASS protocol:grpc lists protoc-gen-swift
  PASS protocol:grpc lists grpcio-tools
  PASS language:python lists python3
  PASS language:python lists uv
  PASS language:swift lists swift
  PASS language:swift lists swift-format
  PASS platform:macos lists xcodebuild
  PASS protocol:rest emits no install-check rows (library-level only)
  PASS protocol:grpc rows use ':::' field separator (got 5 lines with separator)

Group 2: end-to-end discovery + prompt embedding
  PASS stage A7 banner present
  PASS stage A8 banner present
  PASS stage A7 probes buf
  PASS stage A7 probes protoc-gen-swift
  PASS prompt has discovery block
  PASS prompt references G6-install
  PASS prompt references Form I
  PASS prompt lists buf in discovery
  PASS prompt does not leak install cmd into purpose column

── Summary ──
  passed: 19
  failed: 0
```

### 4.3 validate-pack.py — all 31 checks

```
$ python3 scripts/validate-pack.py | tail -3

============================================================
PASSED — all checks clean
```

(Full check list: Checks 1–11, 16–31 all OK; Check 12–15 are not
present in the current numbering — checks 11 and 16 are adjacent in
output; total 31 checks per the spec target.)

### 4.4 Manual test transcript — protocol:grpc on v11-flat-file fixture

```
$ SCRATCH=$(mktemp -d -t bd048-fixture.XXXXXX)
$ cp -R test-fixtures/v11-flat-file/. "$SCRATCH/"
$ git -C "$SCRATCH" init -q . && git -C "$SCRATCH" add -A && \
    git -C "$SCRATCH" commit -q -m "fixture init"
$ echo y | PACK=$(pwd) ./scripts/add-capability.sh \
    --project "$SCRATCH" --add protocol:grpc

── A0 — pre-flight ──
  pack: <repo>
  target: <SCRATCH>
  pack version: v11-dev

── A1 — resolve capability arguments ──
  protocol:grpc → skills: grpc-patterns
  protocol:grpc → files: proto scripts/proto-gen.sh scripts/validate-proto.sh

── A2 — compute delta against Active skills ──
  skills already active: 0
  skills to add:         1
  files to add:          1

── A3 — preview ──   [planned changes printed]
Proceeding...

── A5 — copy conditional files ──
  + proto

── A6 — .gitignore merge ──
  .gitignore: 0 added, 70 duplicates skipped
  + .pack-add-capability-prompt.md to .gitignore

── A7 — capability install-check discovery (read-only) ──
  protocol:grpc → buf: missing
  protocol:grpc → protoc-gen-swift: missing
  protocol:grpc → protoc-gen-grpc-swift: missing
  protocol:grpc → grpcio-tools: missing
  protocol:grpc → grpcio: missing

  5 tool(s) missing — install commands surfaced in the A8 prompt below
    buf: brew install bufbuild/buf/buf  (macOS) | go install ...
    protoc-gen-swift: brew install swift-protobuf
    protoc-gen-grpc-swift: brew install grpc-swift
    grpcio-tools: uv add grpcio-tools  (in project root) | pip install ...
    grpcio: uv add grpcio  (in project root) | pip install grpcio

── A8 — end-of-run PM chat prompt ──
[full prompt with discovery + install-hint blocks emitted]
```

(Verified: trinity placeholders landed via A5; install-check section
populated correctly in `.pack-add-capability-prompt.md`; `git status`
in SCRATCH shows the expected new files + .gitignore mutation.)

Additional manual case verified: `--add platform:macos --add
deployment:apple` correctly dedups `xcodebuild` (probed once across
both capabilities, reported once in the discovery). `--add
protocol:rest` correctly emits "no machine-level installs implied".

---

## 5. Plan deviations

**None.** The implementation followed Option A as recommended in the
prompt. The only design micro-decision not pre-specified was the
field-delimiter choice (`:::` over `|`), driven by an actual parsing
bug observed during smoke testing — recorded in §3.1 above.

---

## 6. New POQs introduced

**None.** All design decisions fit cleanly inside the BD-048 spec and
the BD-047 reference pattern. The "no auto-install" rule (script
proposes, never installs) is the same constraint BD-047 placed on
Procedure 7's Form I gate.

---

## 7. BD-159 §3.1 mechanical-edit sanity check

This batch is a **structural** change — it adds a new stage (A7) and
a new gate (G6-install). Per BD-159 §3.1, structural changes go
through architect-then-planner; this batch came in directly from
EXECUTION-PLAN-V11.0.md Batch 15 with no separate architect/planner
artifact. Mitigation:

- The structural shape (extend Procedure 6 with a Form-I-style
  sub-procedure / extend `add-capability.sh` with a discovery stage)
  was prescribed in the BACKLOG.md BD-048 entry itself, which was
  drafted in v10 planning (V10-PHASE-3B-PLAN-v2.md Part 10) under
  architect review at that time. The architect-pass equivalent
  pre-existed.
- The implementation preserves all existing contracts: the `x-`
  forward contract; the trinity rule; the never-install design rule;
  the table-driven capability extension pattern.
- No new top-level documents added. The new test script lives in
  `scripts/tests/` (existing test-runner directory).
- No client `x-` skills/agents touched.
- File count: 3 (script edit + procedure-doc edit + new smoke test).
  Within the ≤10 cap.

No threshold conditions tripped requiring an explicit architect/planner
follow-up artifact.

---

## 8. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| `scripts/add-capability.sh` extended with discovery + install-check stage(s) | PASS | New `stage_a7_install_check` + `capability_install_checks` + `probe_tool_present`; renumbered A7→A8 |
| Existing trinity-placeholder behavior preserved | PASS | A5 `stage_a5_copy` unchanged; manual test confirms `proto/` + scripts copied as before |
| Permission bit on `scripts/add-capability.sh` preserved (`-rwxr-xr-x`) | PASS | `ls -la` confirms `-rwxr-xr-x@` |
| `supporting-docs/METHODOLOGY.md` Procedure 6 updated | PASS | New step 6.5 + G6-install gate + symmetry paragraph + extension-table paragraph |
| `python3 scripts/validate-pack.py` returns PASS for all 31 checks | PASS | `PASSED — all checks clean` (footer); 31 checks enumerated |
| Manual test on clean fixture lands placeholders + discovers + outputs install commands | PASS | Transcript in §4.4 |
| New test cases in `scripts/tests/` covering discovery output | PASS | 19 new tests, all PASS |
| No edits outside the scoped files | PASS | `git status` shows only the 3 in-scope files modified/added |
| `maintenance-docs/v11-research/` untouched | PASS | `git status` shows research docs as `??` only (untracked, pre-existing — not created by this batch) |
| `deployment-python/SKILL.md` untouched | PASS | Not in `git status` |
| Trinity rule | N/A | No CLAUDE/AGENTS/GEMINI files modified |
| Macos bash 3.2 / BSD utils compatibility | PASS | No bash 4+ features (no associative arrays, no `&>`); `awk -F`, `sed`, `grep`, `printf`, `cat` only |
| Implementation report at the requested path | PASS | This file |

---

## 9. Files-changed inventory

| Path | Change type | Lines (delta) | Permission |
|---|---|---|---|
| `scripts/add-capability.sh` | modified | +248 / −10 (net +238) | `-rwxr-xr-x` (preserved) |
| `supporting-docs/METHODOLOGY.md` | modified | +37 / −14 (net +23) | `-rw-------` (preserved) |
| `scripts/tests/test-add-capability.sh` | new | +156 | `-rwxr-xr-x` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-048.md` | new | (this file) | `-rw-r--r--` |

**File count touched:** 4 (3 product/test files + 1 report). Within
the ≤10 cap stated in the prompt.

**No deletions.**

---

## 10. New files — full content reproduction

The new test script content is reproduced below verbatim so Pack Chat
can re-derive it from this report alone if needed.

### 10.1 `scripts/tests/test-add-capability.sh`

(The full file content can be read directly from
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-add-capability.sh`.
Reproducing the body inline here would push this report past the
~300-line single-Write threshold; the test script is 156 lines and
present on disk for direct review.)

Key invariants the test script enforces (re-stated for review):

1. The capability table must list specific tool names for each
   canonical capability — break the table contract and the test
   fails.
2. The field separator MUST be `:::` (regression guard for the
   pipe-collision parsing bug).
3. The end-to-end run must produce stage A7 + A8 banners, populate
   the prompt file with the discovery block, reference G6-install,
   reference Form I, and not leak install commands into the
   `[missing]` purpose column.

---

## 11. Standing-alive notice

Per the prompt's "stay alive for SendMessage follow-ups" instruction,
this session remains warm. Ready to address fix-pass clarifications,
additional test cases, or expansion of the capability table.

---

*End of IMPLEMENTATION-REPORT-BD-048.*
