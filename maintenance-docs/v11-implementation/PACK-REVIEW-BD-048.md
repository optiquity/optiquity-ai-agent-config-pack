# PACK-REVIEW-BD-048

**Verdict:** APPROVE WITH NITS — implementation is correct, complete, and tests/validator green; only one stale "stage A7" reference in `METHODOLOGY.md` (line 1194) needs flipping to "stage A8" to match the renumber.

---

## 1. Scope confirmed

- Working-tree footprint matches spec exactly: 4 files
  (`scripts/add-capability.sh` MOD, `supporting-docs/METHODOLOGY.md` MOD,
  `scripts/tests/test-add-capability.sh` NEW,
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-048.md` NEW).
  Verified via `git status --short`.
- Out-of-band research files in `maintenance-docs/v11-research/` and
  `RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` correctly untouched (they
  appear as `??` only — pre-existing user/parallel-BD work).
- BD-048 BACKLOG entry status still `Open` — correct; the implicit-flip
  to `Resolved` is Pack Chat's post-review action.

---

## 2. Per-concern findings

### 2.1 Option A vs Option B — APPROVED

Coder selected Option A (extend `add-capability.sh` script-side with a
new discovery stage + table-driven install-check rows; update
METHODOLOGY Procedure 6 to add G6-install). Rationale in
`IMPLEMENTATION-REPORT-BD-048.md` §2 is sound:

1. Discovery is a deterministic `command -v` probe; no PM-chat reasoning
   needed — round-trip avoidance is real.
2. The new `capability_install_checks()` table colocates with the
   existing `capability_skills()` and `capability_files()` tables in
   `scripts/add-capability.sh:121-339`. Single-source-of-truth for the
   capability-row contract is preserved.
3. Option B would have introduced a new pm-chat.md variant with no
   parallel in `init-project.sh` (which doesn't invoke pm-chat variants
   either — kickoff emits a prompt that the developer pastes). Option A
   maintains symmetry across both surfaces.
4. The discovery output flows naturally into the existing A8 prompt
   without inventing a new artifact.

No escalation needed. Option A is the correct call.

### 2.2 `capability_install_checks()` table — APPROVED

`scripts/add-capability.sh:252-339`. Table is structurally parallel to
`capability_skills()` (lines 121-194) and `capability_files()`
(lines 218-229) — same `case "$cap" in ... esac` shape, same dimension
namespace. Coverage:

- `language:python` — python3, uv (2 rows)
- `language:swift` — swift, swift-format (2 rows)
- `platform:macos|platform:ios` — xcodebuild, xcrun (shared row)
- `platform:android` — adb, java
- `platform:web-browser` — node
- `platform:embedded-mcu` — cmake, arm-none-eabi-gcc
- `language:cpp|language:c` — clang, cmake (shared row)
- `language:objc` — clang
- `protocol:grpc` — buf, protoc-gen-swift, protoc-gen-grpc-swift,
  grpcio-tools, grpcio (5 rows)
- `protocol:rest|graphql|realtime|messaging|soap` — explicitly empty
  (library-level only) with comment at lines 317-321
- `deployment:apple` — xcodebuild
- `deployment:linux-container` — docker
- `role:python-server` — uv

Comment at lines 244-251 documents the three-parallel-tables contract for
extension. Good maintainability cue.

### 2.3 `probe_tool_present()` helper — APPROVED

`scripts/add-capability.sh:347-354`. Centralized as required; default
case uses `command -v "$tool" >/dev/null 2>&1` (POSIX, portable across
macOS bash 3.2 + Linux). Comment at line 350-351 reserves a `py:*`
prefix pattern for future Python-package probes — clean extension point.
Returns 0/1 cleanly without `set -e` interference.

### 2.4 `stage_a7_install_check()` stage — APPROVED

`scripts/add-capability.sh:633-690`. Correctly placed after
`stage_a6_gitignore` and before `stage_a8_prompt` in `main()`
(lines 805-806). Implements:

- Per-capability row iteration with `awk -F':::'` parsing
- Cross-capability tool dedup via `probed_tools` accumulator
  (lines 642, 663-666) — `xcodebuild` implied by both
  `platform:macos` and `deployment:apple` is probed once. Manual test
  in IMPL §4.4 confirms this.
- Empty-row capability falls through to a "no machine-level installs
  implied" line (lines 647-650).
- Final summary at lines 681-689 prints either "all probed tools
  present" or the missing-tools list with install commands.

Read-only contract preserved: no writes, no installs, no `eval`. The
comment header at lines 621-631 is explicit about Form R analog status.

### 2.5 Stage renumbering A7→A8 — MOSTLY CLEAN, 1 STALE REF

The script-side renumber is clean: `stage_a8_prompt()` at
`scripts/add-capability.sh:776-784`, banner "── A8 — end-of-run PM
chat prompt ──", header comment at lines 24 / 30 reflects "nine stages
A0..A8".

**Stale ref (NIT)** — `supporting-docs/METHODOLOGY.md:1194`:

```
- The developer pastes the end-of-run prompt emitted by
  `scripts/add-capability.sh` stage A7 (V10-DESIGN §5.14.3).
```

The prompt is now emitted by stage **A8**, not A7 (the new A7 is the
install-check discovery stage). Step 6.1 at line 1214 correctly says
"written by stage A8" — the lead-paragraph mention at line 1194 was
missed in the renumber. The `(V10-DESIGN §5.14.3)` cross-ref is also
stale by transitivity but harmless (V10-DESIGN is a frozen historical
artifact).

The other "stage A7" reference at lines 1239-1241 is CORRECT — it
describes the new A7 install-check discovery stage as G7-discovery's
capability-addition equivalent.

Recommended fix (one-character delta): change "stage A7" to "stage A8"
on line 1194 only. Optionally drop or update the V10-DESIGN §5.14.3
cite.

No stale references in `project-template/docs/pack/PM-CHAT.md` or
`project-template/docs/pack/HELP-FRAGMENT.md` (those don't reference
specific stages).

### 2.6 `write_prompt_file()` discovery + install-hint blocks — APPROVED

`scripts/add-capability.sh:694-774`. The new prompt blocks at
lines 748-768 do exactly what the spec asks:

- Guards `${#DISCOVERY_LINES[@]:-0}` and `${#INSTALL_HINTS[@]:-0}`
  protect the already-active early-exit path that calls
  `write_prompt_file` before stage A7 runs (belt-and-suspenders with
  the `main()` initializer at lines 795-796). Verified safe under
  `set -euo pipefail`.
- Discovery section title: `Capability install-check discovery
  (read-only, BD-048):` — matches Form R prose shape.
- Install-hint section title: `Missing tools — proposed install
  commands (run with developer approval per Procedure 6 G6-install):`
  — names the gate explicitly.
- Concluding instruction at line 764: `Render a Form I
  (INSTALL-PROCEDURES.md § 7.2.3 shape) for each missing tool before
  running any install. Skip-by-default: a missing tool is reported,
  never auto-installed.` — matches BD-047 Form I shape contract.

### 2.7 Field-delimiter `:::` regression-guard — APPROVED

Verified independently:

- Table function at line 252 uses `:::` consistently across all 12
  capability rows.
- Stage A7 parses with `awk -F':::'` at lines 657-659. Comment at
  lines 654-656 documents the rationale (install commands contain `|`
  as platform-alternative).
- Test runner has TWO regression guards:
  1. Group 1 line 99-104: counts `:::` occurrences in the
     `protocol:grpc` row block (asserts ≥5).
  2. Group 2 line 138-139: `assert_not_contains "prompt does not leak
     install cmd into purpose column" "$PROMPT" "[missing] buf — go
     install"` — directly catches the original bug shape.

Both pass on this machine (independent re-run, see §3 below).

### 2.8 METHODOLOGY.md Procedure 6 — APPROVED (with §2.5 NIT)

`supporting-docs/METHODOLOGY.md:1189-1249`. Procedure 6 expanded from
6 steps to 7 steps:

- Lead paragraph (line 1200-1205) mentions BD-048 install-check.
- Gates list (lines 1207-1210) updated to {G6-drafts, G6-install,
  G6-commit}.
- Step 6.5 inserted (line 1218) with G6-install gate; references
  INSTALL-PROCEDURES.md § 7.2.3 Form I shape and idempotency rule.
- Existing 6.5 → 6.6 (detection scan); existing 6.6 → 6.7 (commit
  gate). Renumber clean.
- "Symmetry with Procedure 7 (kickoff)" paragraph (lines 1234-1242)
  documents §7.2.3 / 7.3.1 / 7.3.2 mirror, idempotency, and why no
  G6-discovery gate exists. Clear and accurate.
- "Adding a new capability row" paragraph (lines 1244-1249) names the
  three parallel tables. Matches the comment at
  `add-capability.sh:244-251`.

Sole defect: lead-paragraph stage reference at line 1194 (see §2.5).

### 2.9 Permission bits — APPROVED

```
-rwxr-xr-x@ scripts/add-capability.sh
-rwxr-xr-x@ scripts/tests/test-add-capability.sh
```

Both executable as required.

### 2.10 Test coverage — APPROVED (independent re-run green)

```
$ bash scripts/tests/test-add-capability.sh
[…]
── Summary ──
  passed: 19
  failed: 0
```

19/19 PASS, matching the IMPL report's claim. The test runner follows
the established shape under `scripts/tests/`:
`set -uo pipefail`, ANSI-colored t_pass/t_fail counters, summary-then-
exit pattern. Group 1 sources only the function definition via `sed`
slice (line 43) — clean isolation; Group 2 builds an isolated fixture
clone via `mktemp -d`, runs end-to-end, then cleans up at line 144.

### 2.11 Manual fixture test — APPROVED

IMPL §4.4 transcript reproduced for `--add protocol:grpc` against
`test-fixtures/v11-flat-file`:

- Stage A1 resolves `grpc-patterns` skill + `proto/`,
  `scripts/proto-gen.sh`, `scripts/validate-proto.sh` files — matches
  `capability_files()` row at line 226.
- Stage A7 probes 5 tools (buf, protoc-gen-swift, protoc-gen-grpc-swift,
  grpcio-tools, grpcio) — matches `protocol:grpc` row at lines 309-315.
- Stage A8 prompt receives both blocks. The "5 tool(s) missing" line
  matches the expected output from the table.

The dedup case (`--add platform:macos --add deployment:apple`) is also
described in IMPL §4.4 as verified — `xcodebuild` probed once. Reading
the code at lines 663-666 confirms the dedup mechanism works.

### 2.12 No regressions — APPROVED

```
$ python3 scripts/validate-pack.py
[…]
============================================================
PASSED — all checks clean
```

All 31 checks PASS (independent re-run). No new files trigger
validate-pack rules; the new test under `scripts/tests/` follows the
existing convention and isn't validator-gated.

### 2.13 No out-of-scope edits — APPROVED

`git status` shows only the 4 in-scope files modified/added. The 7
untracked `maintenance-docs/v11-research/` files and one parallel-BD
`RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` are pre-existing.

### 2.14 BD-159 §3.1 mechanical-edit sanity — APPROVED

This is structural (new stage, new gate), but:

- Structural shape was prescribed in the BD-048 BACKLOG entry itself
  (drafted under v10 architect review) — architect-pass equivalent
  pre-exists.
- File count: 4 (≤10 cap satisfied).
- No top-level docs added; new test lives under existing
  `scripts/tests/`.
- No client `x-` files touched.
- All existing contracts preserved: trinity rule (N/A here, no trinity
  files modified); `x-` forward contract (script remains add-only);
  table-driven capability extension pattern (extended, not violated);
  never-install design rule (preserved — script proposes, never
  installs).

IMPL §7 self-assessment is accurate. No threshold conditions tripped.

---

## 3. BD-047 kickoff symmetry — VERIFIED

The Form R/I/E/M kickoff vocabulary lives in
`supporting-docs/INSTALL-PROCEDURES.md:935-1163`:

- §7.1 K1 — read-only discovery (Form R, G7-discovery)
- §7.2.3 — swift-format install (Form I, G7-install)
- §7.3.1 — Apple-side gRPC tooling (Form I, G7-install)
- §7.3.2 — Python-side gRPC tooling (Form I, G7-install)

BD-048 mirror at capability-addition time:

| Kickoff (BD-047) | Capability-add (BD-048) | Implementation |
|---|---|---|
| Form R (G7-discovery) PM-chat-driven | Stage A7 install-check (script-side, no gate) | `add-capability.sh:633-690` |
| Form I per-tool (G7-install) | Step 6.5 Form I per-tool (G6-install) | `METHODOLOGY.md:1218` + prompt at `add-capability.sh:759-764` |
| Form E (G7-edit) | (N/A — A5 file copy is non-editorial) | — |
| Form M (G7-machine) | (N/A — no machine-file generation) | — |

The script-side discovery vs PM-chat-side discovery asymmetry is
deliberate and well-documented in METHODOLOGY.md lines 1238-1242. Both
surfaces converge on the same Form I gate at install execution. This is
structural symmetry on the user-facing semantics with implementation
asymmetry on the discovery medium — exactly what the spec asks for.

---

## 4. Field-delimiter regression guard — RE-VERIFIED

- Switch documented in `add-capability.sh:236-247` and `654-659`.
- Table uses `:::` exclusively (grep confirms).
- Test guard 1: `test-add-capability.sh:99-104` — counts separator
  occurrences in protocol:grpc rows; asserts ≥5. PASS.
- Test guard 2: `test-add-capability.sh:138-139` — asserts the
  prompt does NOT contain `[missing] buf — go install` (the bug
  signature where `awk -F'|'` would have leaked install-command head
  into the purpose column). PASS.

Both guards explicitly catch the originally-observed bug; selecting
`:::` (3-char ASCII unlikely in any real install command or purpose
prose) is a sound design call.

---

## 5. Defects summary

| ID | Severity | File:line | Description | Fix |
|---|---|---|---|---|
| N1 | NIT | `supporting-docs/METHODOLOGY.md:1194` | Lead paragraph references `add-capability.sh` stage A7 as the prompt-emit stage; renumber moved that to A8. Step 6.1 at line 1214 already correctly says "stage A8". | Change "stage A7" → "stage A8" on line 1194; optionally drop or update the `(V10-DESIGN §5.14.3)` cross-ref since the section number predates the renumber. |

No major or blocking defects. Tests + validator are green; the
script's stage 1-9 flow works correctly end-to-end on the fixture; no
regressions in the existing 31-check validator suite.

---

## 6. Recommendation

**APPROVE WITH NITS.** Pack Chat may either:

(a) Land the BD-048 commit as-is and ship N1 as a one-line follow-up
    (the stale ref is in a "Triggered when" lead paragraph, not in any
    operative gate or step).

(b) Fix N1 in the same batch (one-character `A7`→`A8` edit on line
    1194) before flipping BD-048 to Resolved.

Recommendation (b) — the fix is a single-character delta with zero
behavioral risk and brings the renumber to byte-clean state across the
file.

---

*End of PACK-REVIEW-BD-048.*
