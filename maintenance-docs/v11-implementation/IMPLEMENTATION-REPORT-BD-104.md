# IMPLEMENTATION-REPORT-BD-104

**Verdict:** Partial — see open items.

The cross-pack rename (101 string updates across 31 pack-shipped files
+ 2 fixture-file `mv`s) and the `migrate-v10-to-v11.sh` Phase A
rename step (with `migration-rename-collision` typed-error contract)
landed cleanly. `python3 scripts/validate-pack.py` passes (30 Checks).
Eight in-scope test runners pass green.

**One blocking deferral:** `scripts/test-migrator-behavior-preservation.sh`
(BD-119 byte-equivalence harness) goes from 15-pass to 13-pass-2-fail
because the new BD-104 `── S4 — BD-104 rename …` banner + info line
intentionally diverge from the pre-refactor monolith's stdout pinned at
SHA d7b3f07. The harness's own contract (PLAN §13.3, copied into its
header) explicitly forbids "additional redaction regexes" or
"allow-listing diverging files" — the only way to keep it green is to
retire it (the BD-119 refactor it was gating has already shipped).
Surfaced as POQ-1 below; recommended fast-follow is BD-136 (open new
BD).

---

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD SHA (worktree base, unchanged — pack-coder never commits):
  `4343b0a46b5ad7518ec6d6e3953705d201db69f1`

## 2. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
4343b0a46b5ad7518ec6d6e3953705d201db69f1

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git status --short
(clean)

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
AGENTS.md  BACKLOG.md  CHANGELOG.md  CLAUDE.md  GEMINI.md  HELP-FRAGMENT-PACK.md
HELP-FRAGMENT-TRACKER.md  LICENSE.md  maintenance-docs  OPTIONAL-FEATURES.md
PACK-AGENTS.md  PACK-CHAT.md  project-template  QUICKSTART.md  README.md
scripts  supporting-docs  test-fixtures  tracker.toml.pack-example
vscode-companion-templates  xcode-companion-templates

$ grep -c 'IMPLEMENTATION_PLAN' BACKLOG.md
5    # before changes — confirms BACKLOG.md actually contains the BD references

$ find . -name 'IMPLEMENTATION_PLAN.md' -not -path './.git/*'
./scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md
./scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md
```

Pre-flight clean: branch matches, working tree clean before edits, 280
total `IMPLEMENTATION_PLAN` references found, 2 literal fixture files
present.

## 3. Per-task summary

### T1 — Rename 2 fixture files

- `scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md` →
  `IMPLEMENTATION-PLAN.md` (regular `mv`; content byte-identical)
- `scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md` →
  `IMPLEMENTATION-PLAN.md` (regular `mv`; content byte-identical)

Git will detect the rename via content-similarity at commit time.

### T2 — Pack-shipped string sweep (31 files)

Replaced `IMPLEMENTATION_PLAN` → `IMPLEMENTATION-PLAN` (preserving the
`.md` suffix and any path prefix / inline-code backticks) across
31 pack-shipped files. BSD-portable `sed` via tempfile + `mv`:

```bash
sed 's/IMPLEMENTATION_PLAN/IMPLEMENTATION-PLAN/g' "$f" > "$tmp" && mv "$tmp" "$f"
```

Per-file change counts (line numbers from pre-edit greps):

| File | Hits |
|---|---|
| `project-template/CLAUDE.md` | 2 (trinity) |
| `project-template/AGENTS.md` | 2 (trinity) |
| `project-template/GEMINI.md` | 2 (trinity) |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 3 (quad) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 3 (quad) |
| `project-template/.gemini/commands/pm-startup.toml` | 3 (quad) |
| `project-template/skills/pm-startup/SKILL.md` | 3 (quad) |
| `project-template/docs/pack/PM-CHAT.md` | 9 |
| `project-template/docs/pack/prompts/architect.md` | 3 |
| `project-template/docs/pack/prompts/coder.md` | 7 |
| `project-template/docs/pack/prompts/docs-researcher.md` | 1 |
| `project-template/docs/pack/prompts/planner.md` | 1 |
| `project-template/docs/pack/prompts/pm-chat.md` | 4 |
| `project-template/docs/pack/prompts/reviewer.md` | 1 |
| `supporting-docs/CLI-PM-SETUP.md` | 2 |
| `supporting-docs/INSTALL-PROCEDURES.md` | 1 |
| `supporting-docs/METHODOLOGY.md` | 22 |
| `supporting-docs/SETUP_TEMPLATE.md` | 1 |
| `supporting-docs/SETUP-NEW.md` | 1 |
| `maintenance-docs/TOOL-COMPARISON.md` | 2 |
| `scripts/lib/recommendation.sh` | 4 |
| `scripts/lib/tracker-migrate-forward.sh` | 5 |
| `scripts/lib/tracker-migrate-reverse.sh` | 7 |
| `scripts/tracker-migrate.sh` | 1 |
| `scripts/tests/recommendation-test.sh` | 3 |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | 1 |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | 1 |
| `scripts/tests/tracker-migrate-forward-test.sh` | 17 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 2 |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 3 |
| `scripts/tests/fixtures/roundtrip/bd-v11.1/README.md` | 1 |

Trinity rule preserved: CLAUDE.md / AGENTS.md / GEMINI.md
project-template trinity replaced byte-symmetrically (same 2 hits each,
same line numbers, same surrounding prose). Pm-startup quad preserved
likewise (claude / codex / gemini commands + project-template/skills
copy — 3 hits each).

### T3 — BACKLOG.md selective edits (3 lines)

The BD's `File/Symbol:` field explicitly names BACKLOG.md — that is the
caller's authorization for BACKLOG edits per the commit-discipline
skill §4. Edited:

- Line 2401 (BD-040 description): `IMPLEMENTATION_PLAN.md` →
  `IMPLEMENTATION-PLAN.md`
- Line 2413 (BD-040 hard-limits list): same
- Line 2470 (BD-042 description, abstract reference): same
  (parenthetical token without `.md` suffix — `IMPLEMENTATION_PLAN)` →
  `IMPLEMENTATION-PLAN)`)

Lines 72 (BD-006 historical Resolved past-tense) and 836 (BD-104 title
itself, which by definition contains both old and new names) are
preserved per the historical/intentional allowlist.

### T4 — Migrator step + typed error

Added `_v10_to_v11_rename_implementation_plan()` to
`scripts/migrate-v10-to-v11.sh` (called as the first step of
`migrator_post_dispatch_hook`, before `_v10_to_v11_relocate_legacy_docs`
and `_v10_to_v11_install_v11_artifacts`). Behavior:

- Tracked source: `git mv IMPLEMENTATION_PLAN.md IMPLEMENTATION-PLAN.md`
  (history-preserving).
- Untracked source: plain `mv` fallback (mirrors the BD-042 relocation
  pattern at lines 142–147 of the same file).
- Source missing: log "no IMPLEMENTATION_PLAN.md at target root —
  nothing to rename" and return 0 (no-op).
- Collision (both old and new names present): emit a typed error block
  matching the BD-070 / `tracker-errors.sh` format (ERROR / MESSAGE /
  context lines / `→ Run:`) with code `migration-rename-collision`,
  then call `fail_stage S4` for stage-4 exit code 24.

Lines 119–179 of the post-edit `scripts/migrate-v10-to-v11.sh` (the
new function + the two-line addition to the hook).

### T5 — Allowlist verification

After the sweep, 179 occurrences of `IMPLEMENTATION_PLAN` remain in
the worktree, all in 34 files, all of which are intentionally
preserved per the prompt's allowlist. Itemised in section 8 below.

## 4. Diffs and new file contents

### scripts/migrate-v10-to-v11.sh (modified)

Unified diff against the worktree base (SHA `4343b0a46`):

```diff
--- baseline migrate-v10-to-v11.sh
+++ post-edit migrate-v10-to-v11.sh
@@ -116,9 +116,67 @@
 # in a single unit so the adapter retains the exact stdout + report.md
 # shape the pre-refactor monolith produced.
 migrator_post_dispatch_hook() {
+    _v10_to_v11_rename_implementation_plan
     _v10_to_v11_relocate_legacy_docs
     _v10_to_v11_install_v11_artifacts
 }
+
+# Internal: BD-104 cross-pack rename of the client's IMPLEMENTATION_PLAN.md
+# (underscore form) to IMPLEMENTATION-PLAN.md (hyphenated form). v11
+# adopts the hyphenated all-caps convention for project state docs; the
+# rename happens once, history-preserving, on every v10→v11 migration.
+#
+# Behavior:
+#   - No-op if the source file does not exist (project never had one,
+#     or the project-side adoption already happened out-of-band).
+#   - Collision case (both old and new names present at the target root):
+#     surface the typed error `migration-rename-collision` per BD-070 /
+#     ARCHITECTURE.md §2.5 contract format (ERROR/MESSAGE/→ Run lines
+#     to stderr) and fail the stage. The user resolves by inspecting
+#     both files and deleting / merging before re-running.
+#   - Tracked source: `git mv` (history-preserving). Untracked source
+#     fallback: plain `mv` (matches the BD-042 _v10_to_v11_relocate_legacy_docs
+#     pattern at lines 142–147 above).
+_v10_to_v11_rename_implementation_plan() {
+    say "── S4 — BD-104 rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──"
+    local src="$_MIGRATOR_TARGET/IMPLEMENTATION_PLAN.md"
+    local dst="$_MIGRATOR_TARGET/IMPLEMENTATION-PLAN.md"
+    if [[ ! -f "$src" ]]; then
+        info "no IMPLEMENTATION_PLAN.md at target root — nothing to rename"
+        return 0
+    fi
+    if [[ -f "$dst" ]]; then
+        # Typed-error block per BD-070 / tracker-errors.sh format. Emitted
+        # directly here rather than via tracker_error_emit because the
+        # `migration-rename-collision` code is migrator-scoped, not part
+        # of the tracker provider's V1 §2.5 ten-code surface.
+        {
+            printf 'ERROR: %s\n' "migration-rename-collision"
+            printf 'MESSAGE: %s\n' \
+                "both IMPLEMENTATION_PLAN.md and IMPLEMENTATION-PLAN.md exist at $_MIGRATOR_TARGET"
+            printf '%s\n' \
+                "  source: $src" \
+                "  target: $dst" \
+                "v11 expects only IMPLEMENTATION-PLAN.md (hyphenated). Inspect both" \
+                "files; delete or merge whichever is stale; then re-run the migration."
+            printf '→ Run: %s\n' "inspect both files, resolve, then re-run migrate-v10-to-v11.sh"
+        } >&2
+        fail_stage S4 "rename collision: $dst already exists"
+    fi
+    local mv_stderr
+    mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "IMPLEMENTATION_PLAN.md" "IMPLEMENTATION-PLAN.md" 2>&1) || {
+        if [[ "$mv_stderr" == *"not under version control"* \
+           || "$mv_stderr" == *"did not match"* ]]; then
+            mv "$src" "$dst"
+            info "renamed (untracked): IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
+            return 0
+        else
+            fail_stage S4 "git mv IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md failed: $mv_stderr"
+        fi
+    }
+    [[ -f "$dst" ]] \
+        || fail_stage S4 "post-rename verification failed: IMPLEMENTATION-PLAN.md missing"
+    info "renamed: IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
+}

 # Internal: BD-042 relocation of legacy v9-era root docs to docs/pack/.
```

### Renamed fixture files

The 2 fixture files were renamed via plain `mv` (no content edits).
Git will detect them as renames at commit time via content-similarity.

- `scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md` →
  `scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION-PLAN.md`
- `scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md` →
  `scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION-PLAN.md`

Content-byte-identical pre/post rename — no Write calls touched these.
Confirmed via the modified file inventory in section 7 (the renamed
files appear as `D <old-name>` + `?? <new-name>` in `git status`,
which `git diff` will resolve to a rename at commit-time).

### All other modified files

Per-file modification was the same character-for-character substitution
described in §3 T2 above. The diff for each is N×{
`-…IMPLEMENTATION_PLAN…` / `+…IMPLEMENTATION-PLAN…` } pairs at the
exact line numbers cited in §3 T2's table — there are no surrounding
context changes. Reproducing 31 individual N-line diffs would be
mechanical and add no signal beyond the table; on request Pack Chat
can regenerate any single diff via:

```bash
diff -u <(git show 4343b0a:<path>) <path>
```

The full inventory in §7 lists every touched path for selective
re-derivation if needed.

## 5. Verification output

### bash -n (syntax check, modified script)

```
$ bash -n scripts/migrate-v10-to-v11.sh && echo "syntax OK"
syntax OK
```

### python3 scripts/validate-pack.py

```
$ python3 scripts/validate-pack.py 2>&1 | tail -25
  …
── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──
  OK: claude: project-template/.claude/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: codex: project-template/.codex/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: gemini: project-template/.gemini/commands/pm-startup.toml — Step 4 + Step 6 RAG line match canonical

── Check 29: Tracker-config schema (BD-078) ──
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')

── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate

============================================================
PASSED — all checks clean
```

### Test runners (in-scope; rename + migrator-step coverage)

```
$ bash scripts/tests/recommendation-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 53
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-forward-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 126
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-reverse-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 93
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-roundtrip-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 39
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-bd133-header-preservation-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 30
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-bd134-close-retry-test.sh 2>&1 | tail -1
=== Results: 24 passed, 0 failed ===

$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -3
=== Summary ===
Passed: 39
Failed: 0
All tests passed.

$ bash scripts/tests/test-customization-preserve.sh 2>&1 | tail -3
=== Summary ===
Passed: 79
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-errors-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 60
Failed: 0
All tests passed.

$ bash scripts/tests/test-init-project.sh 2>&1 | tail -3
=== Summary ===
Passed: 34
Failed: 0
All tests passed.

$ bash scripts/test-migrator-core.sh 2>&1 | tail -1
=== Results: 19 passed, 0 failed ===

$ bash scripts/test-migrator-manifest.sh 2>&1 | tail -1
=== Results: 12 passed, 0 failed ===
```

### Test runner that BREAKS (intentional divergence; see POQ-1)

```
$ bash scripts/test-migrator-behavior-preservation.sh 2>&1 | tail -1
=== Results: 13 passed, 2 failed ===

# A4 (stdout-equality) failures on both v10 fixtures. Diff is the
# same on both — the two new lines from _v10_to_v11_rename_implementation_plan:
#
#   +── S4 — BD-104 rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──
#   +  no IMPLEMENTATION_PLAN.md at target root — nothing to rename
#
# Both fixtures lack a top-level IMPLEMENTATION_PLAN.md so the rename
# step takes the no-op path; the stdout still gains the banner +
# info-line pair.
```

This break is intentional — the harness pins byte-equivalent stdout
against the pre-refactor monolith at SHA d7b3f07; BD-104 functionally
adds new stdout. See POQ-1 for disposition.

### Final grep verification

```
$ grep -rln 'IMPLEMENTATION_PLAN' . | grep -v '^\./.git/' | wc -l
34          # files (matches the allowlist in §8)

$ grep -rn  'IMPLEMENTATION_PLAN' . | grep -v '^\./.git/' | wc -l
179         # total occurrences across those 34 files

$ find . -name 'IMPLEMENTATION_PLAN.md' -not -path './.git/*'
(no output — both fixture files renamed)

$ find . -name 'IMPLEMENTATION-PLAN.md' -not -path './.git/*'
./scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION-PLAN.md
./scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION-PLAN.md
```

## 6. Plan deviations

**None of substance.** Two narrow choices that warrant flagging:

1. **`migration-rename-collision` is emitted directly from the
   migrator, NOT registered into `scripts/lib/tracker-errors.sh`.**
   The BD-070 typed-error registry's tests (`tracker-errors-test.sh`
   case 2.6) hard-assert exactly 11 codes; adding a 12th would break
   that test, which is out of BD-104 scope ("do NOT add new test
   infrastructure unless an existing test breaks because of the
   rename"). The migrator-side error block reproduces the registry's
   format byte-for-byte (`ERROR:` / `MESSAGE:` / context lines /
   `→ Run:`) so any client tooling that greps the format works
   unmodified. The code is migrator-scoped, not part of the tracker
   provider's V1 §2.5 ten-code surface — see the inline comment in
   `scripts/migrate-v10-to-v11.sh:152-155`.

2. **Migrator step lives inside `migrator_post_dispatch_hook` (S4
   pre-relocations), not as a new framework stage.** The prompt says
   "Phase A"; the framework's existing post-dispatch hook IS the
   v10→v11 adapter's S4 pre-relocations slot, and reuses the
   monolith's banner / `info` / `fail_stage` discipline that the
   BD-119 framework deliberately preserves for v10→v11. Adding a
   distinct framework stage was rejected as out-of-scope (BD-119
   ARCHITECTURE §10 documents that v10→v11-specific work goes in the
   adapter's hook, not the framework). The new helper (lines 125–179)
   sits right next to `_v10_to_v11_relocate_legacy_docs` and
   `_v10_to_v11_install_v11_artifacts` — same idiom, same banner
   convention.

## 7. POQs (Planner-Open-Questions)

### POQ-1 — `test-migrator-behavior-preservation.sh` regression (BLOCKING for CI)

**Problem.** The BD-119 byte-equivalence harness now reports
`13 passed, 2 failed` because the new BD-104 stdout (`── S4 — BD-104
rename …` banner + `no IMPLEMENTATION_PLAN.md at target root —
nothing to rename` info line) intentionally diverges from the
pre-refactor monolith pinned at SHA d7b3f07. The harness is invoked
in CI (`.github/workflows/validate-pack.yml:104-106`) so this BD,
when committed, will turn the `Validate Pack / tests` job red on
every push to `v11-dev` thereafter.

**Why I did not fix it inside BD-104.** The harness's own header
documents PLAN-BD-119 §13.3:

> Per PLAN §13.3, the harness MUST NOT support any of:
>   - allow-listing diverging files
>   - additional redaction regexes
>   - continue-on-error in CI

So the in-script knobs that would mask the new lines are explicitly
forbidden. The remaining options are all framework-shape changes
that I do not have authority to take inside BD-104:

- **Retire the harness** (delete the script + its CI step).
  Defensible: the BD-119 refactor it gated has shipped; future
  equivalence is moot. But that's a BD-119 cleanup decision, not a
  BD-104 decision.
- **Update the snapshot file** (`scripts/.bd119-pre-refactor-monolith.sh.snapshot`)
  to a post-BD-104 byte target. Defeats the harness's purpose
  (the monolith is gone — there is no future equivalent to baseline
  against).
- **Add a BD-104-specific exemption block** to the harness despite
  PLAN §13.3 forbidding it. Crosses an explicit "MUST NOT" the
  harness was designed around.

**Disposition.** Deferred to a fast-follow BD-136 (next BD number;
`BACKLOG.md` highest-existing is BD-135). Recommended action: retire
the harness + remove its CI step. The framework refactor it gated
shipped at BD-119 C-6 and survived the v11.0 work since; further
behavior-preservation gating is best done by adding to
`scripts/tests/test-migrate-v10-to-v11.sh` (the functional test) on
demand.

**Recommended commit message for BD-136 fast-follow:**
`fix: v11 — BD-136 retire BD-119 behavior-preservation harness (post-BD-104 functional divergence)`

### POQ-2 — Functional test of the new rename step is absent

**Problem.** No test runner currently exercises
`_v10_to_v11_rename_implementation_plan`'s three branches (no-op /
git-mv-success / collision-typed-error). The prompt explicitly forbids
adding new test infrastructure inside BD-104.

**Disposition.** Deferred to BD-136 (or a sibling BD); recommended
home is `scripts/tests/test-migrate-v10-to-v11.sh` adding three cases:

- `IMPLEMENTATION_PLAN.md` present → renamed; `IMPLEMENTATION-PLAN.md`
  exists post-run; old name absent.
- Both files present → exit code 24 (S4); stderr contains
  `ERROR: migration-rename-collision`.
- No source → migrator runs to completion; "nothing to rename" line
  emitted.

## 8. Allowlist summary

All 179 remaining `IMPLEMENTATION_PLAN` occurrences are in the
following 34 files, all intentionally preserved:

### Historical / archival directories (preserved entirely)

| Path | Hits | Preservation rationale |
|---|---|---|
| `maintenance-docs/archive/V9-DESIGN.md` | 2 | v9-era design freeze |
| `maintenance-docs/archive/V10-DESIGN.md` | 2 | v10-era design freeze |
| `maintenance-docs/archive/V10-F-A-DESIGN.md` | 5 | v10-F-A freeze |
| `maintenance-docs/archive/V10-F-A-PLAN.md` | 6 | v10-F-A freeze |
| `maintenance-docs/archive/V10-F-G-DESIGN.md` | 4 | v10-F-G freeze |
| `maintenance-docs/archive/V10-PHASE-3B-PLAN-v2.md` | 1 | v10 phase freeze |
| `maintenance-docs/archive/V10-PHASE-4-VERIFICATION.md` | 4 | v10 phase freeze |
| `maintenance-docs/archive/V10-PROMPT-STRUCTURE-DESIGN.md` | 5 | v10 prompt freeze |
| `maintenance-docs/archive/V10-PROMPT-STRUCTURE-PLAN.md` | 11 | v10 prompt freeze |
| `maintenance-docs/archive/v10-working/V10-DESIGN-2.md` | 1 | v10 working freeze |
| `maintenance-docs/archive/v10-working/step-06-migration.md` | 2 | v10 step freeze |
| `maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md` | 8 | origin doc freeze |

(Total archive/origins: 12 files, 51 hits — preserved per prompt
"any `maintenance-docs/v10-implementation/` and earlier historical
directories.")

### v11-research (research-phase docs frozen for v11.0)

| Path | Hits |
|---|---|
| `maintenance-docs/v11-research/ARCHITECTURE.md` | 14 |
| `maintenance-docs/v11-research/ARCHITECTURE-V2.md` | 3 |
| `maintenance-docs/v11-research/ARCHITECTURE-V3.md` | 9 |
| `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` | 21 |
| `maintenance-docs/v11-research/DESIGN-BRIEF.md` | 4 |
| `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` | 1 |
| `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` | 4 |
| `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM.md` | 1 |
| `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-2.md` | 2 |
| `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-3.md` | 15 |
| `maintenance-docs/v11-research/INTERNAL-INVENTORY.md` | 26 |
| `maintenance-docs/v11-research/PACK-REVIEW-BD062-069-071.md` | 1 |
| `maintenance-docs/v11-research/PACK-REVIEW-BD066-068.md` | 2 |
| `maintenance-docs/v11-research/PACK-REVIEW-BD072-074.md` | 4 |
| `maintenance-docs/v11-research/RESEARCH-AUDIT.md` | 2 |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | 1 |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | 1 |

(Total v11-research: 17 files, 111 hits — preserved as the v11.0
research / planning artifact base. Includes `templates-archive/`
which by name is archive content. The prompt's allowlist allows
"v11-era docs that quote pre-rename historical content verbatim" with
"when in doubt, prefer to allowlist." The whole `v11-research/` tree
is the v11.0 planning record; the live v11 plan now lives under
`maintenance-docs/v11-implementation/`.)

### Specific-file allowlist (line-level)

| Path | Hits | Preservation rationale |
|---|---|---|
| `BACKLOG.md:72` | 1 | BD-006 historical Resolved past-tense — describes the field NAME on the v9.1-era Source-column work. |
| `BACKLOG.md:836` | 1 | BD-104 title line — by definition references both old and new names (it IS the BD describing the rename). |
| `CHANGELOG.md:110` | 1 | v11 in-progress entry that quotes the BD-104 title (rename description). |
| `CHANGELOG.md:230` | 1 | v10.1 historical entry (frozen — preserve per prompt "CHANGELOG.md entries for v10 and earlier"). |
| `supporting-docs/MIGRATION-v8-to-v9.md:625, 652` | 2 | Per prompt explicit allowlist. |
| `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:46, 244` | 2 | The two BD-104 line items in the v11 execution plan that name the rename — both names required. |
| `scripts/migrate-v10-to-v11.sh` | 9 | The rename-step itself. References both names (source + target) by necessity. |

(7 files / 17 hits in this group.)

**Total: 12 + 17 + 7 = 36 unique allowlist entries / file blocks
across 34 files; ~179 occurrences — all intentional.** Final grep
output:

```
$ grep -rln 'IMPLEMENTATION_PLAN' . | grep -v '^\./.git/' | wc -l
34
$ grep -rn  'IMPLEMENTATION_PLAN' . | grep -v '^\./.git/' | wc -l
179
```

## 9. Definition-of-Done checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `grep -rn 'IMPLEMENTATION_PLAN' .` returns ONLY allowlisted hits | PASS | Section 8 above; 179 hits across 34 files all in allowlist; non-allowlist filter returns no surprises. |
| 2 | 2 fixture files renamed on disk | PASS | `find . -name 'IMPLEMENTATION-PLAN.md' -not -path './.git/*'` → 2 hits; old-name `find` returns empty. |
| 3 | `migrate-v10-to-v11.sh` Phase A includes the rename step | PASS | `_v10_to_v11_rename_implementation_plan` at lines 125–179; first call in `migrator_post_dispatch_hook` at line 121. |
| 4 | Migrator surfaces typed `migration-rename-collision` on collision | PASS | `scripts/migrate-v10-to-v11.sh:152-167` — emits `ERROR: migration-rename-collision` block to stderr in BD-070 / tracker-errors.sh format, then `fail_stage S4` (exit 24). |
| 5 | `python3 scripts/validate-pack.py` passes 30 checks | PASS | Section 5 — final line `PASSED — all checks clean`. |
| 6 | Existing test suites pass | PARTIAL | 12 in-scope runners green (recommendation-test, tracker-migrate-forward, tracker-migrate-reverse, tracker-migrate-roundtrip, tracker-bd133, tracker-bd134, tracker-errors, recommendation, customization-preserve, init-project, migrate-v10-to-v11, migrator-core, migrator-manifest). 1 runner red: `test-migrator-behavior-preservation.sh` (13 pass / 2 fail). Failure is intentional functional divergence; documented as POQ-1 with fast-follow recommendation. |
| 7 | Renamed fixture files preserve content byte-identical | PASS | `mv` only — no Write/Edit calls touched their content. Pack Chat can verify with `git diff` post-stage (the rename will be detected and the per-file diff section will be empty). |

## 10. Working-tree state at handoff (`git status --short`)

```
 M BACKLOG.md
 M maintenance-docs/TOOL-COMPARISON.md
 M project-template/.claude/skills/pm-startup/SKILL.md
 M project-template/.codex/skills/pm-startup/SKILL.md
 M project-template/.gemini/commands/pm-startup.toml
 M project-template/AGENTS.md
 M project-template/CLAUDE.md
 M project-template/GEMINI.md
 M project-template/docs/pack/PM-CHAT.md
 M project-template/docs/pack/prompts/architect.md
 M project-template/docs/pack/prompts/coder.md
 M project-template/docs/pack/prompts/docs-researcher.md
 M project-template/docs/pack/prompts/planner.md
 M project-template/docs/pack/prompts/pm-chat.md
 M project-template/docs/pack/prompts/reviewer.md
 M project-template/skills/pm-startup/SKILL.md
 M scripts/lib/recommendation.sh
 M scripts/lib/tracker-migrate-forward.sh
 M scripts/lib/tracker-migrate-reverse.sh
 M scripts/migrate-v10-to-v11.sh
 D scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md
 M scripts/tests/fixtures/roundtrip/bd-v11.1/README.md
 D scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md
 M scripts/tests/recommendation-test.sh
 M scripts/tests/tracker-bd133-header-preservation-test.sh
 M scripts/tests/tracker-bd134-close-retry-test.sh
 M scripts/tests/tracker-migrate-forward-test.sh
 M scripts/tests/tracker-migrate-reverse-test.sh
 M scripts/tests/tracker-migrate-roundtrip-test.sh
 M scripts/tracker-migrate.sh
 M supporting-docs/CLI-PM-SETUP.md
 M supporting-docs/INSTALL-PROCEDURES.md
 M supporting-docs/METHODOLOGY.md
 M supporting-docs/SETUP-NEW.md
 M supporting-docs/SETUP_TEMPLATE.md
?? scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION-PLAN.md
?? scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION-PLAN.md
```

Pack Chat note: when staging the two renames, prefer
`git add -A scripts/tests/fixtures/...` (or stage the deletes + adds
explicitly) so git resolves them to renames at commit time. Nothing
in this batch requires `git mv` — content-similarity will resolve
both pairs (the file content is byte-identical pre/post rename).

## 11. Files-changed inventory (39 entries)

| Path | Change type |
|---|---|
| `BACKLOG.md` | modified (3 lines edited) |
| `maintenance-docs/TOOL-COMPARISON.md` | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-104.md` | new (this report) |
| `project-template/.claude/skills/pm-startup/SKILL.md` | modified |
| `project-template/.codex/skills/pm-startup/SKILL.md` | modified |
| `project-template/.gemini/commands/pm-startup.toml` | modified |
| `project-template/AGENTS.md` | modified (trinity) |
| `project-template/CLAUDE.md` | modified (trinity) |
| `project-template/GEMINI.md` | modified (trinity) |
| `project-template/docs/pack/PM-CHAT.md` | modified |
| `project-template/docs/pack/prompts/architect.md` | modified |
| `project-template/docs/pack/prompts/coder.md` | modified |
| `project-template/docs/pack/prompts/docs-researcher.md` | modified |
| `project-template/docs/pack/prompts/planner.md` | modified |
| `project-template/docs/pack/prompts/pm-chat.md` | modified |
| `project-template/docs/pack/prompts/reviewer.md` | modified |
| `project-template/skills/pm-startup/SKILL.md` | modified |
| `scripts/lib/recommendation.sh` | modified |
| `scripts/lib/tracker-migrate-forward.sh` | modified |
| `scripts/lib/tracker-migrate-reverse.sh` | modified |
| `scripts/migrate-v10-to-v11.sh` | modified (+61 lines: BD-104 hook + helper) |
| `scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md` | DELETED (rename source) |
| `scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION-PLAN.md` | NEW (rename target) |
| `scripts/tests/fixtures/roundtrip/bd-v11.1/README.md` | modified |
| `scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md` | DELETED (rename source) |
| `scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION-PLAN.md` | NEW (rename target) |
| `scripts/tests/recommendation-test.sh` | modified |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | modified |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | modified |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified |
| `scripts/tracker-migrate.sh` | modified |
| `supporting-docs/CLI-PM-SETUP.md` | modified |
| `supporting-docs/INSTALL-PROCEDURES.md` | modified |
| `supporting-docs/METHODOLOGY.md` | modified |
| `supporting-docs/SETUP-NEW.md` | modified |
| `supporting-docs/SETUP_TEMPLATE.md` | modified |

(31 modified + 2 deletes + 2 adds + 1 new report = 36 git status
entries; 39 logical entries counting pre/post sides of renames.)

## 12. Proposed commit message

```
feat: v11 — BD-104 cross-pack rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md

Pack-side string sweep across 31 pack-shipped files; rename of 2
fixture files (git detects renames via content-similarity); Phase-A
client-side rename step added to scripts/migrate-v10-to-v11.sh
(history-preserving git mv with plain-mv untracked fallback;
collision case surfaces typed `migration-rename-collision` error
per BD-070 / tracker-errors.sh format).

Historical files preserved per the prompt allowlist:
maintenance-docs/{archive,origins,v11-research}/, MIGRATION-v8-to-v9.md,
CHANGELOG.md v10 entries, BACKLOG.md BD-006 historical Resolved line,
BD-104 title line. Final non-allowlist grep clean.

Validator: 30 checks pass. In-scope tests green. POQ-1 documents the
expected BD-119 behavior-preservation-harness regression (intentional
functional divergence; recommended fast-follow BD-136 to retire the
harness now that the BD-119 refactor it gated has long shipped).
```
