# IMPLEMENTATION-REPORT-BD-144

**Batch:** 5 of skill-dimensions reframe (`PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 + §7.1 expanded scope).
**BD:** BD-144 — add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation stage.
**Branch:** `v11-dev`
**Pre-batch HEAD SHA:** `9675066d8818de93f469287fe67857feb6ad0806`
**Final HEAD SHA on worktree:** `9675066d8818de93f469287fe67857feb6ad0806` (no commits — pack-coder is read-only with respect to git state per Pack memory rule "Agents never commit").

---

## 1. Pre-flight state

### 1.1 Files in scope (pre-edit line counts and perm bits)

```
-rwxr-xr-x  20148 bytes  scripts/add-capability.sh                 (496 lines)
-rw-r--r--  17799 bytes  scripts/lib/detect.sh                     (471 lines)  — sourced, not executed
-rwxr-xr-x  32392 bytes  scripts/migrate-v10-to-v11.sh             (656 lines)
-rwxr-xr-x  13603 bytes  scripts/test-detect.sh                    (352 lines)
(new)                    scripts/test-migrator-capability-translation.sh
```

### 1.2 Pre-batch capability_skills() row inventory (scripts/add-capability.sh lines 107-132)

```
language:python    → python-best-practices python-data-architecture dependency-python
language:swift     → swift-best-practices apple-architecture-core dependency-swift
language:cpp       → cpp-language
language:c         → c-language
language:objc      → objc-language
platform:macos     → macos-architecture apple-architecture-core
platform:ios       → ios-architecture apple-architecture-core
protocol:grpc      → grpc-patterns
protocol:rest      → rest-patterns
protocol:graphql   → graphql-patterns
protocol:realtime  → realtime-patterns
protocol:messaging → messaging-patterns
protocol:soap      → soap-patterns
role:apple-app     → deployment-apple
role:python-server → python-server-architecture deployment-python
```

### 1.3 Pre-flight git status (relevant)

`v11-dev` clean at start of session (per the system git status snapshot).
Subsequent diff includes BD-143 in-flight files (architecture-review, audit-methodology, trinity, project-template/{CLAUDE,AGENTS,GEMINI}.md) and BD-145 in-flight `scripts/init-project.sh` — none of these are in BD-144's scope, all left untouched per the coordinated-parallel-batch rule.

### 1.4 Read-input verification

Read in full:
- `BACKLOG.md` BD-144 entry (line 1449-1456).
- `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 (line 396-466) + §7.1 expanded scope (line 1082-1158).
- `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3.7 (line 445-461) + §7.5 (python-data marker).
- `scripts/add-capability.sh` IN FULL (496 lines).
- `scripts/lib/detect.sh` IN FULL (471 lines) — `detect_installed_capabilities()` at lines 242-301; `python_data_marker_detected()` at lines 334-386 (referenced as the BD-141 helper shape).
- `scripts/test-detect.sh` IN FULL (352 lines).
- `scripts/migrate-v10-to-v11.sh` IN FULL (656 lines) — confirmed S5b ends at line 495, framework hook contract clear, `_MIGRATOR_TARGET` / `_MIGRATOR_STATE_DIR` / `say` / `info` / `fail_stage` API confirmed against `scripts/lib/migrator-core.sh`.
- `project-template/docs/pack/PLATFORM-SKILLS.md` D5 + intersection cells (BD-142 already shipped).
- `CLAUDE.md` (pack-repo root) `## Pack memory` § "Repo conventions" — confirmed the BD-159 maintainability principle is the published one (line 168-183).

---

## 2. Per-file edit log

### 2.1 `scripts/add-capability.sh` (modified)

Three edits:

**(a) `--help` text — recognized dimensions list (lines 36-39 region).**
Before:
```
#     --add <dim>:<val>  Capability to add. May be repeated.
#                        Recognized dimensions: platform, language, protocol, role.
#     --pack <path>      Override $PACK environment variable.
```
After:
```
#     --add <dim>:<val>  Capability to add. May be repeated.
#                        Recognized dimensions: platform, language, protocol,
#                        role, deployment.
#                        Examples: language:python, platform:ios,
#                        protocol:grpc, role:python-server, deployment:apple,
#                        deployment:linux-container.
#     --pack <path>      Override $PACK environment variable.
```

**(b) `capability_skills()` table — D5 rename + new rows + intersection fix.**

Replaced the two pre-Batch-5 `role:` rows with:

```
# BD-144: D5 deployment surface ...
deployment:apple)             echo "deployment-apple" ;;
deployment:linux-container)   echo "deployment-python" ;;

# BD-144: role:python-server preserved as legitimate D3 role.
# Resolved skill list now per architecture §3.7 intersection table:
role:python-server) echo "python-server-architecture python-data-architecture" ;;
```

Added three new forward-declared D1 platform rows with explanatory comment:
```
platform:android)      echo "android-architecture" ;;
platform:web-browser)  echo "web-architecture" ;;
platform:embedded-mcu) echo "embedded-mcu-architecture" ;;
```

**(c) New helper function `warn_if_missing_skills()` (placed immediately after `capability_skills()`).**

Iterates a list of skill names and emits a stderr `warning:` line via the existing `warn` helper for each whose `$PACK/project-template/skills/<skill>/SKILL.md` is absent. Returns 0 always (advisory).

**(d) Wired the helper into stage A1 (`stage_a1_resolve()`, after dedup).** Calls `warn_if_missing_skills "${RESOLVED_SKILLS[@]}"` so every resolved skill is checked against the pack roster. The forward-declared platform rows (android / web-browser / embedded-mcu) trip this warning today; the operation proceeds.

Net delta: +62 / -8 lines.

### 2.2 `scripts/lib/detect.sh` (modified)

Single edit in `detect_installed_capabilities()` (lines 289-290 of pre-batch file).

Before:
```
deployment-apple)      caps+=("role:apple-app") ;;
deployment-python)     caps+=("role:python-server") ;;
```
After (with explanatory comment):
```
# BD-144 (v11.0 skill-dimensions reframe Batch 5): D5 deployment
# surface — reciprocal of the renamed `deployment:apple` and the
# new `deployment:linux-container` rows in
# scripts/add-capability.sh::capability_skills(). The pre-Batch-5
# mappings (deployment-apple→role:apple-app,
# deployment-python→role:python-server) were misclassified per
# ARCHITECTURE-SKILL-DIMENSIONS.md §3.5; both flip atomically here.
deployment-apple)      caps+=("deployment:apple") ;;
deployment-python)     caps+=("deployment:linux-container") ;;
```

Net delta: +9 / -2 lines.

### 2.3 `scripts/test-detect.sh` (modified)

Two changes inside the `== detect_installed_capabilities ==` section:

- Updated the existing `caps-with-backticks` assertion expected value from `"capabilities: language:python, role:python-server"` to `"capabilities: deployment:linux-container, language:python"` to reflect the reciprocal-mapping flip.
- Added two new fixtures:
  - `caps-deployment-apple` — `**Active skills:** swift-best-practices, deployment-apple` → expected `"capabilities: deployment:apple, language:swift"`.
  - `caps-deployment-linux-container` — `**Active skills:** python-best-practices, deployment-python` (no backticks) → expected `"capabilities: deployment:linux-container, language:python"`.

Total assertions in `test-detect.sh`: 40 → 42 (was 40 pre-batch, now 42).

Net delta: +28 / -3 lines.

### 2.4 `scripts/migrate-v10-to-v11.sh` (modified)

Two edits:

**(a) `migrator_post_dispatch_hook()` — wire in the new translator.**
Updated the dry-run banner string to mention the new stage; added the new function call to the apply path.

```
- info "[dry-run] would run BD-104 rename + BD-042 relocation + v11 artifact install + python-architecture skill rename"
+ info "[dry-run] would run BD-104 rename + BD-042 relocation + v11 artifact install + python-architecture skill rename + BD-144 capability-token translation"
...
  _v10_to_v11_rename_python_architecture_refs
+ _v10_to_v11_translate_capability_tokens
```

**(b) New stage helper `_v10_to_v11_translate_capability_tokens()`.**

Inserted before `migrator_post_report_hook` (~190 lines including the leading documentation block). Behavior (per spec §7.1 step 9 + Step 5 of the agent prompt):

1. Iterates trinity files at `_MIGRATOR_TARGET/{CLAUDE,AGENTS,GEMINI}.md` (only those that exist).
2. Cheap fast paths: skips files lacking a `^capabilities:` line; skips files containing no v10.x legacy token (`role:apple-app` or `role:python-server`).
3. For each `capabilities:`-prefixed line:
   - **Rename pass** — replaces `role:apple-app` → `deployment:apple` using a `sed -E` boundary-anchored substitution (`(^|[^A-Za-z0-9_:-])role:apple-app($|[^A-Za-z0-9_:-])` → `\1deployment:apple\2`).
   - **Append pass** — when the line contains `role:python-server` (boundary-anchored) AND does NOT already contain `deployment:linux-container` (boundary-anchored), appends `, deployment:linux-container` (or just ` deployment:linux-container` if the line already ends with `,`). Idempotent.
4. Records every touch (rename or append) into `$_MIGRATOR_STATE_DIR/capability-rename.advisory` with a header comment block + per-touch `<file>:<line>: <kind>` / `before:` / `after:` / `rationale:` block.
5. Writes the rewritten line back atomically via temp-file + `mv`, only when at least one edit occurred for that file.
6. Banner: `── S5c — BD-144 capability-token translation … ──`. The sub-stage tag is `S5c` (after the BD-035 split's `S5b`); the `fail_stage` ID still uses `S5` so the BD-095 sentinel filename stays stable.

Stage placement rationale: chosen the position immediately after `_v10_to_v11_rename_python_architecture_refs` (S5b) so the trinity-file content the BD-035 helper just rewrote is the same content this translator scans. The BD-144 stage is fully self-contained — no shared state with S5b — keeping it cleanly separable from the BD-147 S5b extraction work.

Net delta: +192 / -2 lines.

### 2.5 `scripts/test-migrator-capability-translation.sh` (NEW)

A 247-line standalone test runner per spec Step 6:

- Builds a synthetic v10 fixture under `$TMPDIR/test-bd144-translate.XXXXXX/project/` with a minimal v10 surface marker (`docs/pack/PROMPT-TEMPLATES.md`) and three trinity files whose first body line is `capabilities: language:python, role:python-server, role:apple-app`.
- Sources `migrator-core.sh` for the `say`/`info`/`fail_stage` helpers, then extracts the new helper function `_v10_to_v11_translate_capability_tokens()` from the migrator script via `awk` and `.`-sources it (avoids triggering the BD-095 mode-dispatch logic at the bottom of the migrator).
- T1 — first-run translation (8 assertions): each trinity file's `capabilities:` line contains all four expected tokens (order-tolerant); no surviving `role:apple-app`; advisory file recorded exactly 6 line-touches (3 files × 2 edits each).
- T2 — re-run idempotency (4 assertions): advisory file is NOT recreated; trinity files are byte-identical to T1 post-state.

Total: 12 assertions, 12 PASS.

POQ rationale (also under §8): chose a sibling test file rather than extending `scripts/test-dry-run-migration.sh` because (a) `test-dry-run-migration.sh` exercises the BD-114 read-only harness, not the migrator itself; (b) the existing `v10-realistic-ot` fixture's trinity files have placeholder `**Active skills:**` lines, not `capabilities:` lines — would need fixture mutation to test BD-144; (c) a focused test file is cleaner per maintainability §3.1 (smallest-bounded-footprint principle).

Permission bit: created via `Write`, then `chmod +x` to set `-rwxr-xr-x`.

---

## 3. Smoke test output

### 3.1 detect.sh reciprocal mapping — deployment-apple

```
$ cd /tmp/bd144-smoke
$ cat CLAUDE.md
# CLAUDE.md
**Active skills:** deployment-apple
$ bash -c 'source /Users/david/Developer/.../scripts/lib/detect.sh; \
           detect_installed_capabilities .'
capabilities: deployment:apple
```

PASS — emits the new D5 token, not the deprecated D3 `role:apple-app`.

### 3.2 detect.sh reciprocal mapping — deployment-python

```
$ cat > CLAUDE.md <<'EOF'
# CLAUDE.md
**Active skills:** deployment-python
EOF
$ bash -c 'source /Users/david/Developer/.../scripts/lib/detect.sh; \
           detect_installed_capabilities .'
capabilities: deployment:linux-container
```

PASS — emits the new D5 token.

### 3.3 add-capability.sh --help mentions deployment:apple

```
$ bash scripts/add-capability.sh --help 2>&1 | grep -c "deployment:apple"
1
```

PASS — `≥ 1 hit` requirement satisfied (exactly 1 hit, in the example list).

### 3.4 Grep audit — pack-product files

```
$ grep -nR "role:apple-app" scripts/ project-template/ 2>/dev/null
scripts/migrate-v10-to-v11.sh:504:#   1. `role:apple-app` is renamed to `deployment:apple` (Apple-app is a
scripts/migrate-v10-to-v11.sh:519:# `role:apple-app-foo` (hypothetical) cannot be touched.
scripts/migrate-v10-to-v11.sh:522:#   - `role:apple-app` → `deployment:apple` is a one-shot replace; once
scripts/migrate-v10-to-v11.sh:533:    say "── S5c — BD-144 capability-token translation (role:apple-app → deployment:apple; deployment:linux-container append) ──"
scripts/migrate-v10-to-v11.sh:548:    local apple_pat='(^|[^A-Za-z0-9_:-])role:apple-app($|[^A-Za-z0-9_:-])'
scripts/migrate-v10-to-v11.sh:578:            # Edit 1: rename role:apple-app → deployment:apple, anchored
scripts/migrate-v10-to-v11.sh:583:            ... role:apple-app ... deployment:apple ...
scripts/migrate-v10-to-v11.sh:589:            ... v11 renames `role:apple-app` ...
scripts/migrate-v10-to-v11.sh:609:                printf '  rationale: role:apple-app renamed to deployment:apple ...
scripts/migrate-v10-to-v11.sh:640:                ... v11 renames `role:apple-app` ...
scripts/test-detect.sh:291:# BD-144: rename `role:apple-app` → `deployment:apple`. Verify the
scripts/add-capability.sh:142:        # surface. `role:apple-app` was renamed to `deployment:apple` (Apple-app
scripts/lib/detect.sh:293:            # mappings (deployment-apple→role:apple-app, ...
```

All hits are inside comments / sed-pattern strings / advisory-template strings / banner strings — they describe the rename rather than use the legacy token live. `project-template/` returns **zero** hits (the live pack-product surface is clean). PASS for the spec wording "should return zero hits in pack-product files (archive/maintenance-docs may retain historical references; those are out of scope)."

### 3.5 test-detect.sh full run

```
$ bash scripts/test-detect.sh
== detect_clean_working_tree == (3 PASS)
== detect_git_repo == (2 PASS)
== detect_pack_path == (5 PASS)
== detect_pack_version == (3 PASS)
== detect_ai_config == (3 PASS)
== detect_x_files == (4 PASS)
== detect_improperly_added_files == (7 PASS)
== detect_installed_capabilities == (8 PASS)  ← was 6, now 8 with two new BD-144 cases
== detect_target_pack_version == (6 PASS)
=== Results: 42 passed, 0 failed ===
```

PASS — all 42 (was 40; +2 new BD-144 cases) green.

---

## 4. Migrator translation test output

### 4.1 `bash scripts/test-migrator-capability-translation.sh`

```
== T1: first run translates capability tokens ==
  pass: T1.a CLAUDE.md — capabilities line contains all four expected tokens (order-tolerant)
  pass: T1.a AGENTS.md — capabilities line contains all four expected tokens (order-tolerant)
  pass: T1.a GEMINI.md — capabilities line contains all four expected tokens (order-tolerant)
  pass: T1.b CLAUDE.md — legacy role:apple-app token gone
  pass: T1.b AGENTS.md — legacy role:apple-app token gone
  pass: T1.b GEMINI.md — legacy role:apple-app token gone
  pass: T1.c advisory file written: ${TMP}/.pack-migrate-v10-to-v11/capability-rename.advisory
  pass: T1.c advisory records 6 line-touches (3 files × 2 edits)
== T2: re-run is a no-op (idempotency) ==
  pass: T2.a advisory not recreated — re-run produced zero new touches
  pass: T2.b CLAUDE.md unchanged after re-run
  pass: T2.b AGENTS.md unchanged after re-run
  pass: T2.b GEMINI.md unchanged after re-run

=== Results: 12 passed, 0 failed ===
```

PASS — 12/12.

### 4.2 Advisory file — sample content (post-T1, full file)

```
# capability-token translation advisory (BD-144)
#
# v11 renames `role:apple-app` to `deployment:apple` (D5 deployment
# surface, not a D3 architectural role per
# ARCHITECTURE-SKILL-DIMENSIONS.md §3.5).
# v11 also preserves `role:python-server` but its resolved skill
# list dropped `deployment-python` (now loads via the new
# `deployment:linux-container` D5 row); the migrator appends
# `deployment:linux-container` to lines containing
# `role:python-server` so projects do not silently lose the skill.
#
# Format: <file>:<line>: <kind>
#   before: <text>
#   after:  <text>
#   rationale: <one-line rationale>

CLAUDE.md:2: rename
  before: capabilities: language:python, role:python-server, role:apple-app
  after:  capabilities: language:python, role:python-server, deployment:apple
  rationale: role:apple-app renamed to deployment:apple (D5 deployment surface, ARCHITECTURE-SKILL-DIMENSIONS.md §3.5)
CLAUDE.md:2: append
  before: capabilities: language:python, role:python-server, deployment:apple
  after:  capabilities: language:python, role:python-server, deployment:apple, deployment:linux-container
  rationale: role:python-server preserved but deployment-python now loads via deployment:linux-container (D2 ∩ D5, ARCHITECTURE-SKILL-DIMENSIONS.md §3.7)
AGENTS.md:2: rename
  before: capabilities: language:python, role:python-server, role:apple-app
  after:  capabilities: language:python, role:python-server, deployment:apple
  rationale: role:apple-app renamed to deployment:apple (D5 deployment surface, ARCHITECTURE-SKILL-DIMENSIONS.md §3.5)
AGENTS.md:2: append
  before: capabilities: language:python, role:python-server, deployment:apple
  after:  capabilities: language:python, role:python-server, deployment:apple, deployment:linux-container
  rationale: role:python-server preserved but deployment-python now loads via deployment:linux-container (D2 ∩ D5, ARCHITECTURE-SKILL-DIMENSIONS.md §3.7)
GEMINI.md:2: rename
  before: capabilities: language:python, role:python-server, role:apple-app
  after:  capabilities: language:python, role:python-server, deployment:apple
  rationale: role:apple-app renamed to deployment:apple (D5 deployment surface, ARCHITECTURE-SKILL-DIMENSIONS.md §3.5)
GEMINI.md:2: append
  before: capabilities: language:python, role:python-server, deployment:apple
  after:  capabilities: language:python, role:python-server, deployment:apple, deployment:linux-container
  rationale: role:python-server preserved but deployment-python now loads via deployment:linux-container (D2 ∩ D5, ARCHITECTURE-SKILL-DIMENSIONS.md §3.7)
```

### 4.3 Post-translation `capabilities:` line — example (CLAUDE.md)

```
capabilities: language:python, role:python-server, deployment:apple, deployment:linux-container
```

Order: original tokens preserved in their input position; rename happens in-place; append goes to the end. All four expected tokens present. Order-tolerant assertion passes.

---

## 5. Permission bits — final

```
-rwxr-xr-x@ 1 david  staff  23220 May 12 00:15  scripts/add-capability.sh
-rw-r--r--@ 1 david  staff  18315 May 12 00:15  scripts/lib/detect.sh
-rwxr-xr-x@ 1 david  staff  42278 May 12 00:16  scripts/migrate-v10-to-v11.sh
-rwxr-xr-x@ 1 david  staff  14823 May 12 00:15  scripts/test-detect.sh
-rwxr-xr-x@ 1 david  staff   9827 May 12 00:18  scripts/test-migrator-capability-translation.sh
```

PASS — all four files that must remain `-rwxr-xr-x` are; `scripts/lib/detect.sh` correctly stays `-rw-r--r--` (sourced lib, not executed). The new test runner was written via `Write` (no exec bit), then `chmod +x`'d to match the project convention for `test-*.sh` runners.

---

## 6. validate-pack.py — final

```
$ python3 scripts/validate-pack.py | tail -3
============================================================
PASSED — all checks clean
```

PASS — all 30 checks clean. (No new check was added by BD-144; the new test runner is detected by Check 26 framework-conformance only if it imports `migrator-core.sh` constants — it does, and the source is benign.)

---

## 7. Bash syntax check (`bash -n`)

```
$ bash -n scripts/add-capability.sh \
         scripts/lib/detect.sh \
         scripts/migrate-v10-to-v11.sh \
         scripts/test-detect.sh \
         scripts/test-migrator-capability-translation.sh \
  && echo OK_ALL
OK_ALL
```

PASS — all five files syntax-clean.

---

## 8. POQs (points of question / planner-note resolutions)

### POQ-1 — Forward-declared platform-row directory-exists guard implementation

**Spec:** "When `add-capability.sh` resolves these tokens and the corresponding `project-template/.claude/skills/<skill>/SKILL.md` doesn't exist, emit a warning to stderr but allow the operation. Implementation choice: add a small wrapper or check function. Document in your report."

**Resolution.** Added a new helper `warn_if_missing_skills()` in `scripts/add-capability.sh` (placed immediately after `capability_skills()`). It iterates a list of skill names; for each whose `$PACK/project-template/skills/<skill>/SKILL.md` is absent, emits a stderr `warning:` line via the existing `warn` helper. Returns 0 always (advisory only).

Wired into `stage_a1_resolve()` post-dedup so every resolved skill is checked, not just forward-declared platform skills (cheap; one stat per skill; future skill renames also surface). The probe uses `$PACK/project-template/skills/<skill>/SKILL.md` rather than a per-CLI path because that's the canonical pack-source surface; the per-CLI distributions (`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) are derived.

This satisfies the spec's "warn on stderr but allow" requirement without rejecting the operation, so PM-chat-driven projects can declare `platform:android` / `platform:web-browser` / `platform:embedded-mcu` ahead of Phase 3 SKILL.md ship.

### POQ-2 — Migrator stage placement

**Spec:** "Add a new migrator stage at the appropriate location (study existing stages first; choose position consistent with existing stage ordering — likely late, after S5b which is the BD-035 helper)."

**Resolution.** Placed `_v10_to_v11_translate_capability_tokens()` immediately after `_v10_to_v11_rename_python_architecture_refs` (S5b) and named it `S5c` in the banner. This is the right neighbor because the BD-035 helper rewrites trinity-file skill names; this helper rewrites trinity-file capability tokens; both run after the framework's S3 dispatch has finished transforming trinity bodies, so they operate on the already-merged-and-transformed text.

The stage is a fully self-contained function with no shared state with S5b — keeps it cleanly separable from the BD-147 S5b-extraction work. The `fail_stage` ID stays `S5` so the BD-095 sentinel filename (`stage-S5.done`) and exit-code formula (25 = 20+5) are unchanged.

### POQ-3 — Test file location

**Spec:** "If the existing `scripts/test-migrate-v10-to-v11-dry-run.sh` is the natural extension point, add the assertions there; if not, create a sibling test file. Document the choice in your POQ."

**Resolution.** Created a sibling test runner: `scripts/test-migrator-capability-translation.sh`. Reasons:

1. There is no `scripts/test-migrate-v10-to-v11-dry-run.sh` — the closest existing file is `scripts/test-dry-run-migration.sh`, which exercises the BD-114 read-only **harness**, not the migrator itself.
2. The existing `test-fixtures/v10-realistic-ot/` trinity files have placeholder `**Active skills:**` lines, not `capabilities:` lines — testing BD-144 there would require fixture mutation that bleeds into other tests' contracts.
3. A focused test file matches the maintainability §3.1 "smallest-bounded-footprint" principle and parallels existing per-feature unit-test files (`test-detect.sh`, `test-migrator-core.sh`, `test-migrator-manifest.sh`, etc.).
4. The test sources `migrator-core.sh` for the `say` / `info` / `fail_stage` helpers, then extracts the new helper function via `awk` and `.`-sources it. This keeps the test focused on the BD-144 translation behavior without dragging in the BD-095 mode-dispatch machinery.

### POQ-4 — Translation idempotency invariant

**Spec:** "Idempotent — re-running on already-translated lines is a no-op (don't double-append `deployment:linux-container`)."

**Resolution.** The append pass is gated on (a) `role:python-server` present, AND (b) `deployment:linux-container` NOT already present (boundary-anchored grep). The rename pass is naturally idempotent because `role:apple-app` is replaced by `deployment:apple`; on a second run the source token is gone. Combined: each `capabilities:` line touches at most twice in any first run; re-runs touch zero times. T2 in the test runner asserts this empirically (advisory file not recreated, trinity files byte-identical post-T1).

### POQ-5 — Pre-existing test assertion update vs. the spec

**Spec context:** "Find the test at line 285 area that calls `add-capability.sh --add language:python --add role:python-server` (or similar)."

**Finding.** No test in `scripts/test-detect.sh` calls `add-capability.sh` directly. The line-285 test (`caps-with-backticks`) tests `detect_installed_capabilities()` against a CLAUDE.md whose `**Active skills:**` line lists `python-best-practices, deployment-python`. The expected output was `capabilities: language:python, role:python-server` (the v10.x reciprocal mapping). After our Step 2 flip, `deployment-python` reciprocally maps to `deployment:linux-container`, so the assertion expected value changes to `capabilities: deployment:linux-container, language:python` (sort order changes because `d` < `l`).

I also added two new fixtures (one for `deployment-apple` → `deployment:apple` rename verification, one for the same `deployment-python` mapping without backticks) for fuller coverage.

### POQ-6 — Migrator translation regex format

The boundary-anchored regexes use the same shape as `python_data_marker_detected()` (the BD-141 helper, lines 358-359 of `detect.sh`): `(^|[^A-Za-z0-9_:-])token($|[^A-Za-z0-9_:-])`. The `:` is included in the negated class so that `role:apple-app-foo` (hypothetical) cannot match — the trailing context is asserted not to be a name-continuation char. Mirrors the lesson called out in `python_data_marker_detected()`'s "bracket-escape landmine" comment (positive bracket classes are tricky under POSIX ERE; negated classes are portable and safe).

---

## 9. Files touched — `git diff --stat` (BD-144 scope only)

```
 scripts/add-capability.sh                     |  62 ++++++-
 scripts/lib/detect.sh                         |  11 +-
 scripts/migrate-v10-to-v11.sh                 | 192 ++++++++++++++++++++-
 scripts/test-detect.sh                        |  29 +++-
 scripts/test-migrator-capability-translation.sh | (NEW, 247 lines)
```

**Out-of-scope diffs in the working tree** (NOT touched by BD-144; from parallel batches BD-143 / BD-145):

```
 .claude/skills/architecture-review/SKILL.md
 .codex/skills/architecture-review/SKILL.md
 .gemini/skills/architecture-review/SKILL.md
 project-template/AGENTS.md
 project-template/CLAUDE.md
 project-template/GEMINI.md
 project-template/skills/architecture-review/SKILL.md
 project-template/skills/audit-methodology/SKILL.md
 scripts/init-project.sh
```

These are confirmed left untouched by BD-144 — verified by `git diff scripts/init-project.sh` (the diff is BD-145's "5+3 model" header comment plus a `pack_skill_coverage_for()` `--D1 hint` extension, not anything from this batch). Per the agent prompt's "coordinated with parallel batches" directive, they are out of BD-144's responsibility.

### 9.1 Inventory: files changed by BD-144 (paths + change type)

| Path | Change type |
|---|---|
| `scripts/add-capability.sh` | modified |
| `scripts/lib/detect.sh` | modified |
| `scripts/test-detect.sh` | modified |
| `scripts/migrate-v10-to-v11.sh` | modified |
| `scripts/test-migrator-capability-translation.sh` | new |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-144.md` | new (this report) |

Total: 4 modified, 2 new (1 of which is this report). Net production code: 4 modified, 1 new — comfortably within the maintainability §3.1 mechanical-edit threshold.

---

## 10. Maintainability sanity check (BD-159 §3.1)

The just-shipped maintainability principle (Pack memory § Repo conventions, "Skill and agent maintenance is mechanical by default", line 168-183 of `CLAUDE.md`) requires this batch to satisfy §3.1 mechanical-edit threshold conditions:

| Condition | Status | Evidence |
|---|---|---|
| Trinity-scope N/A | N/A | This batch touches no `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (those are BD-143's scope). The 6 trinity files in the working-tree diff are from BD-143, not BD-144. |
| Existing dimension fit | PASS | Both renames map onto existing PLATFORM-SKILLS.md (BD-142) D5 / D1 / intersection-table cells. `deployment:apple` and `deployment:linux-container` are listed in PLATFORM-SKILLS.md D5 table; `python-data-architecture` is the intersection-table cell for D2=python ∩ D3=server (architecture §3.7). No new dimension introduced. |
| Pattern fit | PASS | The translator stage follows the same shape as `_v10_to_v11_rename_python_architecture_refs` (S5b): per-trinity-file scan, regex-anchored token rewrite, advisory file output, framework `say`/`info`/`fail_stage` helpers, BD-119 `_MIGRATOR_TARGET` / `_MIGRATOR_STATE_DIR` API. The new test follows the `scripts/test-detect.sh` pass/fail/assert_eq shape. |
| Naming | PASS | Function name `_v10_to_v11_translate_capability_tokens` matches the existing migrator-helper convention (`_v10_to_v11_*`). Banner uses the existing sub-stage convention (`S5c`, after `S5b`). Helper `warn_if_missing_skills` follows the existing `warn`/`info`/`die` family. Test runner matches `test-*.sh` convention. |
| Existing validator coverage | PASS | `validate-pack.py` 30 checks all pass; no new check needed. `test-detect.sh` extended with 2 new BD-144 fixtures (8 caps cases now, was 6); `test-migrator-capability-translation.sh` adds 12 new BD-144-specific assertions. |
| Bounded footprint | PASS | 4 production-source files modified, 1 new test file. Net: ~+330 / -15 LoC. Well within §3.1 bounds. No skill / agent / trinity drift. |
| No agent-permission expansion | PASS | No agent file touched; no `permissions:` flag changes; no new tool-allowance fields anywhere. |

**Verdict:** BD-144 satisfies §3.1 mechanical-edit conditions. No structural escalation required.

---

## 11. Definition-of-done checklist

| # | Spec requirement | Status |
|---|---|---|
| 1 | Step 1a — Rename `role:apple-app` → `deployment:apple` in `capability_skills()` (skill `deployment-apple` unchanged) | PASS |
| 2 | Step 1b — Modify `role:python-server` skill list to drop `deployment-python` and add `python-data-architecture` | PASS |
| 3 | Step 1c — Add NEW row `deployment:linux-container` → `deployment-python` | PASS |
| 4 | Step 1d — Add NEW forward-declared platform rows: `platform:android`, `platform:web-browser`, `platform:embedded-mcu` | PASS |
| 5 | Step 1d — Directory-exists guard with stderr warning when SKILL.md absent | PASS (POQ-1) |
| 6 | Step 2 — Replace `deployment-apple → role:apple-app` with `→ deployment:apple` in `detect.sh::detect_installed_capabilities()` | PASS |
| 7 | Step 2 — Replace `deployment-python → role:python-server` with `→ deployment:linux-container` in `detect.sh::detect_installed_capabilities()` | PASS |
| 8 | Step 3 — Update existing `test-detect.sh` assertion for new skill resolution | PASS |
| 9 | Step 4 — Replace `role:apple-app` in `add-capability.sh --help` text | PASS — `--help` now lists `deployment` as a recognized dimension and includes `deployment:apple` and `deployment:linux-container` examples; no live `role:apple-app` reference remains in `--help` text |
| 10 | Step 5 — New migrator stage `_v10_to_v11_translate_capability_tokens()` (rename + append + idempotent + advisory) | PASS (POQ-2) |
| 11 | Step 5 — Stage cleanly separable from BD-147 S5b extraction | PASS — new function, no shared state with `_v10_to_v11_rename_python_architecture_refs` |
| 12 | Step 6 — Golden-snapshot test for migrator translation (12 assertions, idempotent re-run) | PASS (POQ-3) — `scripts/test-migrator-capability-translation.sh`, 12/12 PASS |
| 13 | Verification 1 — `python3 scripts/validate-pack.py` PASS | PASS — all 30 checks clean |
| 14 | Verification 2 — `bash -n` clean on 4 .sh files (extended to 5 with the new test) | PASS |
| 15 | Verification 3 — `ls -l`: 3 executable .sh files retain `-rwxr-xr-x`; new test runner has `-rwxr-xr-x` | PASS |
| 16 | Verification 4 — Smoke: `deployment-apple` → `deployment:apple`; `deployment-python` → `deployment:linux-container`; `--help` lists `deployment:apple` ≥ 1; `role:apple-app` 0 hits in pack-product | PASS |
| 17 | Verification 5 — Migrator test PASS with asserted state | PASS (12/12) |
| 18 | No state-changing git verbs run | PASS — only `git rev-parse HEAD`, `git status`, `git diff --stat`, `git diff` (read-only) |
| 19 | No edits to BD-143 / BD-145 scope files | PASS — verified `scripts/init-project.sh` diff is BD-145 (header + D1 hint), 6 trinity files + 4 architecture-review SKILL.md + audit-methodology SKILL.md untouched by this batch |
| 20 | Report file written at the spec'd path | PASS |
| 21 | Maintainability §3.1 sanity check (BD-159) — mechanical, bounded, dimension-fitting | PASS (§10) |

---

## 12. One-line summary

6 files modified (5 production + 1 new test runner; production deltas across `scripts/add-capability.sh`, `scripts/lib/detect.sh`, `scripts/test-detect.sh`, `scripts/migrate-v10-to-v11.sh`); smoke tests PASS; migrator translation stage idempotent (12/12 in the new golden-snapshot test); `validate-pack.py` 30/30 PASS; maintainability §3.1 sanity check passes.
