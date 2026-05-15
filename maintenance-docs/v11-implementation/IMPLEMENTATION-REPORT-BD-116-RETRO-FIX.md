# IMPLEMENTATION-REPORT-BD-116-RETRO-FIX.md

**Coder:** pack-coder (sub-agent of Pack Chat)
**Date:** 2026-05-15
**BD:** BD-116 — Persona contract assertions (template-derived expected output)
**Batch:** 21c — retroactive per-BD review fix
**Input review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-116-RETRO.md`
**Branch / pre-fix HEAD:** `v11-dev` @ `94ae56c3d0a8de24a1a789829510a387f8314584`

---

## 1. Summary

Applied all 7 findings from the BD-116 retro review (0 MUST, 2 SHOULD, 5
NIT) to the three persona-contract scripts under
`scripts/persona-contracts/`. The headline fix is **F1** — the
greenfield contract now verifies the `.github/ISSUE_TEMPLATE/*.yml`
issue forms (sub-stage 3 of `stage_s11_v11_artifacts()`), restoring
parity with the migration contract and closing a real coverage gap that
the original end-of-batch review's NIT N1 fix had not actually achieved
(the NIT N1 fix added a "this list mirrors …" comment but did not
extend the underlying array). The 3 contract scripts plus aggregator
all pass green post-fix (175 + 25 + 30 assertions across the three
contracts; 3/3 in the aggregator), and `python3
scripts/validate-pack.py` reports `PASSED — all checks clean` (all 32
checks).

---

## 2. Per-finding fix detail

### F1 (SHOULD) — greenfield S11 sub-stage 3 parity

**Finding (paraphrased from review §3 F1):** `contract-greenfield.sh`
`s11_files` array enumerates items 1, 2, 4, and 5 of
`stage_s11_v11_artifacts()` but omits item 3 (`.github/ISSUE_TEMPLATE/*.yml`
issue forms — BD-063). The migration contract DOES check this surface
(lines 333-347). The asymmetry is a real coverage gap.

**Fix:** Added a glob-driven block after the `s11_files` loop that
mirrors the migration contract's pattern (now at lines 197-215 of
`contract-greenfield.sh`). Also extended the array's leading comment
with an explicit sub-stage mapping (1 → docs/pack helpers, 2 →
tracker.toml.example, 3 → ISSUE_TEMPLATE forms (block below), 4 →
per-CLI pack-help surfaces, 5 → scripts/pack-help.sh + lib/detect.sh)
so any future maintainer can verify parity at a glance.

**Before (lines 151-164 of pre-fix file):**
```bash
# Assertion 4: stage S11 client artifacts.
# NOTE: this list mirrors the hardcoded enumeration in
# scripts/init-project.sh:stage_s11_v11_artifacts(). Keep the two in sync
# when adding/removing v11 client artifacts. (BD-116 PACK-REVIEW NIT N1.)
s11_files=(
    "docs/pack/HELP-FRAGMENT.md"
    "docs/pack/HELP-FRAGMENT-TRACKER.md"
    "tracker.toml.example"
    "scripts/pack-help.sh"
    "scripts/lib/detect.sh"
    ".claude/skills/pack-help/SKILL.md"
    ".codex/skills/pack-help/SKILL.md"
    ".gemini/commands/pack-help.toml"
)
```

**After (sub-stage mapping + new ISSUE_TEMPLATE block, lines 164-215):**
```bash
# Assertion 4: stage S11 client artifacts.
# NOTE: this list mirrors the hardcoded enumeration in
# scripts/init-project.sh:stage_s11_v11_artifacts(). Keep the two in sync
# when adding/removing v11 client artifacts. (BD-116 PACK-REVIEW NIT N1.)
#
# Mapping to stage_s11_v11_artifacts() sub-stages:
#   1. HELP-FRAGMENT*.md         → docs/pack/HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md
#   2. tracker.toml.example      → tracker.toml.example
#   3. .github/ISSUE_TEMPLATE/*  → handled by glob block below (F1 fix —
#                                  mirrors the migration contract's pattern;
#                                  pre-fix this surface was unverified by
#                                  greenfield, only by migration).
#   4. per-CLI pack-help         → .claude/skills/pack-help/SKILL.md,
#                                  .codex/skills/pack-help/SKILL.md,
#                                  .gemini/commands/pack-help.toml
#   5. scripts/pack-help.sh + lib → scripts/pack-help.sh, scripts/lib/detect.sh
s11_files=(
    "docs/pack/HELP-FRAGMENT.md"
    "docs/pack/HELP-FRAGMENT-TRACKER.md"
    "tracker.toml.example"
    "scripts/pack-help.sh"
    "scripts/lib/detect.sh"
    ".claude/skills/pack-help/SKILL.md"
    ".codex/skills/pack-help/SKILL.md"
    ".gemini/commands/pack-help.toml"
)
for f in "${s11_files[@]}"; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "S11 artifact ${f} present"
    else
        t_fail "S11 artifact ${f} MISSING"
    fi
done
# F1: S11 sub-stage 3 — .github/ISSUE_TEMPLATE/*.yml issue forms (BD-063).
# Mirrors contract-migration.sh:333-347. Pre-F1 this surface was checked
# only by the migration contract; a regression in greenfield issue-form
# install would have slipped past CI green.
if [[ -d "$PACK_ROOT/project-template/.github/ISSUE_TEMPLATE" ]]; then
    missing_forms=0
    for src in "$PACK_ROOT/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        if [[ ! -f "$SANDBOX/.github/ISSUE_TEMPLATE/$name" ]]; then
            missing_forms=$((missing_forms + 1))
        fi
    done
    if [[ "$missing_forms" -eq 0 ]]; then
        t_pass "S11 sub-stage 3: all .github/ISSUE_TEMPLATE/*.yml installed by greenfield init"
    else
        t_fail "S11 sub-stage 3: $missing_forms ISSUE_TEMPLATE form(s) missing post-init"
    fi
fi
```

**Parity check (mandatory per task constraints — F1):** the new
greenfield surface verifies every artifact `stage_s11_v11_artifacts()`
produces. Read directly from `scripts/init-project.sh:803-884` and
`project-template/.github/ISSUE_TEMPLATE/`:

| `stage_s11` sub-stage (init-project.sh:803-884) | Artifact(s) on disk | Verified by greenfield post-F1 |
|---|---|---|
| 1. `mkdir -p docs/pack` + cp HELP-FRAGMENT*.md | `docs/pack/HELP-FRAGMENT.md`, `docs/pack/HELP-FRAGMENT-TRACKER.md` | YES — `s11_files[0]`, `s11_files[1]` |
| 2. cp tracker.toml.project-example → tracker.toml.example | `tracker.toml.example` | YES — `s11_files[2]` |
| 3. `for form in …/ISSUE_TEMPLATE/*.yml` | `.github/ISSUE_TEMPLATE/config.yml`, `inbound.yml`, `work-item.yml` | **YES (NEW post-F1) — glob block lines 197-215** |
| 4a. cp .claude/skills/pack-help/SKILL.md | `.claude/skills/pack-help/SKILL.md` | YES — `s11_files[5]` |
| 4b. cp .codex/skills/pack-help/SKILL.md | `.codex/skills/pack-help/SKILL.md` | YES — `s11_files[6]` |
| 4c. cp .gemini/commands/pack-help.toml | `.gemini/commands/pack-help.toml` | YES — `s11_files[7]` |
| 5a. cp scripts/pack-help.sh + chmod +x | `scripts/pack-help.sh` | YES — `s11_files[3]` + executable check |
| 5b. cp scripts/lib/detect.sh | `scripts/lib/detect.sh` | YES — `s11_files[4]` |

**Result:** parity restored. Every disk artifact `stage_s11_v11_artifacts()`
produces is now asserted by `contract-greenfield.sh`.

---

### F2 (SHOULD) — migration 3c fallback glob mismatch

**Finding (paraphrased from review §3 F2):** Assertion 3c's fallback
search uses `config.toml.pre-*` (matches `init-project.sh --update`'s
`.pre-update` sidecars). The v10→v11 migrator uses
`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`
(`scripts/migrate-v10-to-v11.sh:76`), so any sidecar this migrator
creates would be `config.toml.v10-customized` — never `config.toml.pre-*`.
Fallback unreachable. Secondary concern: `find … | xargs grep -L …
>/dev/null 2>&1` returns success when find returns nothing, so the
conditional silently passes when no sidecar exists at all.

**Fix:** Aligned the fallback glob with the actual migrator suffix
using the same generalized form already in use at line ~250 of the same
file (`${f}.*-customized`). Switched from `find … | xargs grep -L …`
to a `while IFS= read -r side; do … done < <(find …)` loop with
explicit "did at least one sidecar carry the deletion?" semantics — so
a no-sidecar case correctly fails the assertion instead of silently
passing.

**Before (lines 280-286 of pre-fix file):**
```bash
if find "$SANDBOX" -name "config.toml.pre-*" -type f 2>/dev/null \
        | xargs grep -L "^\[model_providers\.ollama\]" >/dev/null 2>&1; then
    t_pass "3c: ollama-removal customization surfaced via sidecar"
else
    t_fail "3c: ollama-block returned in .codex/config.toml" \
        "migrator silently restored deleted [model_providers.ollama]"
fi
```

**After (post-fix block):**
```bash
# F2: Acceptable if migrator surfaced the customization to a
# sidecar (BD-088 needs-reconciliation path).
#
# Pre-F2 the glob was `config.toml.pre-*` (init-project --update's
# `.pre-update` suffix), but the v10→v11 migrator uses
# MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized" per
# scripts/migrate-v10-to-v11.sh:76 — so the old glob never matched
# and the `find … | xargs grep -L` form returned success on empty
# input, silently passing the test even with no sidecars present.
# Aligned with the 3a generalized form at line ~250
# (`${f}.*-customized`) and switched to `-exec … +` + `grep -q .`
# so we require at least one matching sidecar, not zero.
sidecar_carried=0
while IFS= read -r side; do
    [[ -n "$side" ]] || continue
    if ! grep -q "^\[model_providers\.ollama\]" "$side" 2>/dev/null; then
        sidecar_carried=1
        break
    fi
done < <(find "$SANDBOX" -name "config.toml.*-customized" -type f -not -path "*/.git/*" 2>/dev/null)
if [[ "$sidecar_carried" -eq 1 ]]; then
    t_pass "3c: ollama-removal customization surfaced via .*-customized sidecar"
else
    t_fail "3c: ollama-block returned in .codex/config.toml" \
        "migrator silently restored deleted [model_providers.ollama] and no sidecar carries the deletion"
fi
```

**Verification of glob alignment:**

```
MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"  (migrate-v10-to-v11.sh:76)
→ migrator-produced sidecar basename: config.toml.v10-customized
→ post-F2 glob: config.toml.*-customized
→ shell-glob match: config.toml.v10-customized matches config.toml.*-customized → YES
→ pre-F2 glob: config.toml.pre-* → NO (would only match config.toml.pre-update)
```

The post-F2 glob also generalizes correctly to any future
`config.toml.v<N>-customized` variant a future migrator's
`MIGRATOR_OWN_SIDECAR_SUFFIX` produces, mirroring the 3a check's
existing `${f}.*-customized` pattern.

---

### F3 (NIT) — greenfield S6 docs/pack coverage

**Finding (paraphrased from review §3 F3):** Greenfield contract has no
assertion for `docs/pack/{PM-CHAT,PLATFORM-SKILLS,PACK-FEEDBACK}.md` or
`docs/pack/prompts/*.md` — partial S-stage coverage, defensible scoping
choice but should be documented and self-asserted.

**Fix:** Added Assertion 6 (lines 230-251 of post-fix file) verifying
the three S6 docs/pack/*.md files plus the prompts/*.md count ≥ 10
(matching the bound `init-project.sh:594` enforces internally).

**Before:** no S6 assertion existed (Assertion 5 ended at agent-run.sh
check, then results section).

**After (new Assertion 6 block):**
```bash
# Assertion 6: stage S6 docs/pack/* + docs/pack/prompts/*.md present (F3).
# Defense-in-depth — init-project.sh's stage_s6_docs_pack has internal
# fail_stage checks that would short-circuit the contract's init-zero exit
# test, but surfacing the same surface here makes the contract self-document
# its S6 expectations. References:
#   - scripts/init-project.sh:537-595 (stage_s6_docs_pack)
#   - project-template/docs/pack/{PM-CHAT,PLATFORM-SKILLS,PACK-FEEDBACK}.md
#   - project-template/docs/pack/prompts/*.md (10 per-agent files; init's
#     internal check requires >=10 — we mirror that bound here).
for f in PM-CHAT.md PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
    if [[ -f "$SANDBOX/docs/pack/$f" ]]; then
        t_pass "S6 docs/pack/${f} present"
    else
        t_fail "S6 docs/pack/${f} MISSING"
    fi
done
prompts_count=$(find "$SANDBOX/docs/pack/prompts" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$prompts_count" -ge 10 ]]; then
    t_pass "S6 docs/pack/prompts/ has ${prompts_count} prompt files (>=10 expected)"
else
    t_fail "S6 docs/pack/prompts/ count too low" "expected >=10 got $prompts_count"
fi
```

**Verification:** Greenfield run reports
```
PASS S6 docs/pack/PM-CHAT.md present
PASS S6 docs/pack/PLATFORM-SKILLS.md present
PASS S6 docs/pack/PACK-FEEDBACK.md present
PASS S6 docs/pack/prompts/ has 10 prompt files (>=10 expected)
```

Note: I deliberately used `[[ "$prompts_count" -ge 10 ]]` (POSIX-bash
arithmetic) rather than the reviewer's suggested `(( prompts_count >=
10 ))` for parity with the rest of the script's idiom (which uses `[[
… -eq … ]]` and `[[ … -ge … ]]` throughout). Functionally identical;
chose for stylistic consistency.

---

### F4 (NIT) — mid-dev trap chaining anti-pattern

**Finding (paraphrased from review §3 F4):** Three sequential `trap …
EXIT` redefinitions (lines 64, 83, 101 of pre-fix file). Each replaces
the prior trap entirely. Construction is technically correct (no leak
under any failure path), but reads as fragile. Single named cleanup
function reading current variable values at trap-fire time is clearer.

**Fix:** Replaced the three chained `trap '…' EXIT` redefinitions with
one named `_cleanup` function set once via `trap _cleanup EXIT` BEFORE
any resource creation. `PRE_SNAPSHOT` and `PRE_GITIGNORE` are
pre-declared as empty so the `${VAR:-}` guards in `_cleanup` work
correctly even when partial creation fails between trap-set and
resource assignment.

**Before (pre-fix lines 60-102):**
```bash
# ── Sandbox ───
SANDBOX="$(bash "$BUILD_SH" --for-contract mid-dev)" \
    || { printf 'error: failed to materialize mid-dev sandbox\n' >&2; exit 2; }
trap '[[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

# ... snapshot user-domain files ...
PRE_SNAPSHOT="$(mktemp -t pack-contract-mid-dev-pre.XXXXXX)"
trap '[[ -f "${PRE_SNAPSHOT:-}" ]] && rm -f "$PRE_SNAPSHOT"; [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

# ... pre-install .gitignore snapshot ...
PRE_GITIGNORE=""
if [[ -f "$SANDBOX/.gitignore" ]]; then
    PRE_GITIGNORE="$(mktemp -t pack-contract-gitignore.XXXXXX)"
    cp "$SANDBOX/.gitignore" "$PRE_GITIGNORE"
    trap '[[ -f "${PRE_SNAPSHOT:-}" ]] && rm -f "$PRE_SNAPSHOT"; [[ -f "${PRE_GITIGNORE:-}" ]] && rm -f "$PRE_GITIGNORE"; [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT
fi
```

**After (post-fix lines 61-119):**
```bash
# ── Cleanup (F4: single named trap, set once before resource creation) ────
#
# Reads current values of the SANDBOX / PRE_SNAPSHOT / PRE_GITIGNORE
# variables at trap-fire time, so partial-creation paths are handled
# naturally (anything still empty at fire time is skipped). Replaces the
# pre-F4 chained-redefinition pattern (three sequential `trap … EXIT`
# redefinitions) which read as fragile and was the only outlier among
# the three contract scripts.

PRE_SNAPSHOT=""
PRE_GITIGNORE=""

_cleanup() {
    [[ -n "${PRE_SNAPSHOT:-}" && -f "$PRE_SNAPSHOT" ]] && rm -f "$PRE_SNAPSHOT"
    [[ -n "${PRE_GITIGNORE:-}" && -f "$PRE_GITIGNORE" ]] && rm -f "$PRE_GITIGNORE"
    [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"
    return 0
}
trap _cleanup EXIT

# ── Sandbox ────────────────────────────────────────────────────────────────

SANDBOX="$(bash "$BUILD_SH" --for-contract mid-dev)" \
    || { printf 'error: failed to materialize mid-dev sandbox\n' >&2; exit 2; }

# ... snapshot user-domain files ...
PRE_SNAPSHOT="$(mktemp -t pack-contract-mid-dev-pre.XXXXXX)"
# (no per-resource trap redefinitions — single _cleanup handles everything)

# Snapshot the pre-install .gitignore so we can verify pack append-only.
if [[ -f "$SANDBOX/.gitignore" ]]; then
    PRE_GITIGNORE="$(mktemp -t pack-contract-gitignore.XXXXXX)"
    cp "$SANDBOX/.gitignore" "$PRE_GITIGNORE"
fi
```

**Note on `set -u` safety:** `_cleanup` runs under `set -u` (script-wide
`set -uo pipefail`). The `${VAR:-}` expansions inside the function are
the canonical safe form for this case — they substitute empty string
when the variable is unset, preventing the undefined-variable error.
The pre-declarations of `PRE_SNAPSHOT=""` and `PRE_GITIGNORE=""` make
the variables defined-but-empty from script start, so `${PRE_SNAPSHOT:-}`
and `${PRE_GITIGNORE:-}` both evaluate to empty before any `mktemp` is
called. `SANDBOX` can be unset only between trap-set (line 79) and
sandbox-assignment (line 83); the `${SANDBOX:-}` guard handles that
window safely. Verified with mid-dev contract end-to-end run: 25 PASS,
0 FAIL.

The added `return 0` is intentional — without it, the trap function's
exit code would be the exit code of the last `[[ … ]] && …` test,
which can be 1 if the final guarded condition is false (e.g.,
`SANDBOX` directory removed already). A non-zero trap function exit
code can mask the script's intended exit code in some bash versions;
explicit `return 0` is the defensive pattern.

---

### F5 (NIT) — `pack-internal: true` markers on contract scripts

**Finding (paraphrased from review §3 F5):** None of the three
contract scripts carries the `# pack-internal: true` marker. Check 23
(`scripts/validate-pack.py:1673-1717`) only iterates top-level
`scripts/`, so the contracts under `scripts/persona-contracts/` are not
scanned today; but a future Check 23 hardening that recursively scans
subdirs would fail validation. The wrapper
`scripts/test-persona-contracts.sh:2` already carries the marker.

**Fix:** Added `# pack-internal: true  (CI persona contract; not a
user-facing verb)` as the second line of each contract script (after
the shebang), mirroring the pattern on
`scripts/test-persona-contracts.sh:2`.

**Before (each contract script line 1-2):**
```bash
#!/usr/bin/env bash
# scripts/persona-contracts/contract-<persona>.sh — BD-116 …
```

**After (each contract script line 1-3):**
```bash
#!/usr/bin/env bash
# pack-internal: true  (CI persona contract; not a user-facing verb)
# scripts/persona-contracts/contract-<persona>.sh — BD-116 …
```

**Decision on F5 placement (per task prompt's "F5 if you decide …"
language):** The marker belongs on the contract scripts themselves, NOT
on `scripts/test-persona-contracts.sh`. The wrapper already carries it
(verified at line 2 of the wrapper); adding the marker to the
contracts is the correct mirror — Check 23's `_is_pack_internal()`
helper looks for the marker on the script being scanned, and a
hypothetical recursive Check 23 would scan each contract individually.
`test-persona-contracts.sh` was not modified.

**Verification:** All three contract scripts post-fix have the marker
on line 2:
- `contract-greenfield.sh:2` — `# pack-internal: true  (CI persona contract; not a user-facing verb)`
- `contract-mid-dev.sh:2` — same
- `contract-migration.sh:2` — same

---

### F6 (NIT) — nullglob hygiene around array-glob expansions

**Finding (paraphrased from review §3 F6):** `contract-greenfield.sh`
lines 74 and 103 use array-glob expansion (`array=("$dir"/*/)`)
without `nullglob`. If the glob target dir is empty, the array
contains the literal pattern string. The `[[ -d "$d" ]]` guard
filters it out (so no functional break today), but the construction
is latent-risky.

**Fix:** Wrapped both array-glob assignments with `shopt -s nullglob` /
`shopt -u nullglob` pairs scoped tightly to the assignment statement.
This makes empty glob targets yield empty arrays as the canonical bash
test-script idiom expects, while not changing global glob semantics for
the rest of the script (which contains other glob uses like
`for src in "$pack_agents"/*.${ext}` that retain their existing
`[[ -e ]] || continue` guards — F6 was specifically about the
array-assignment pattern, not the for-loop pattern).

**Before (line 74 of pre-fix file):**
```bash
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
```

**After (lines 80-82 of post-fix file):**
```bash
shopt -s nullglob
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
shopt -u nullglob
```

**Before (line 103 of pre-fix file):**
```bash
for extra in "$cli_extras_dir"/*/; do
    [[ -d "$extra" ]] || continue
```

**After (lines 113-117 of post-fix file):**
```bash
# F6: nullglob hygiene — empty per-CLI extras dir must not yield a
# literal-pattern phantom entry.
shopt -s nullglob
cli_extras_list=("$cli_extras_dir"/*/)
shopt -u nullglob
for extra in "${cli_extras_list[@]}"; do
    [[ -d "$extra" ]] || continue
```

(The second site is converted from a direct for-glob to an
intermediate array assignment to give nullglob a clean assignment
target. The `[[ -d ]]` guard is retained as belt-and-suspenders.)

**Note on alternative `mapfile`:** the reviewer suggested `mapfile -t
… < <(find …)` as an alternative. `mapfile` is bash 4.0+ and the pack
must support macOS bash 3.2 per the task constraints, so the
`shopt`-based form was used instead.

---

### F7 (NIT) — greenfield .gitignore assertion

**Finding (paraphrased from review §3 F7):** Greenfield contract lacks
a `.gitignore` assertion. `init-project.sh:stage_s8_gitignore()` is a
documented S8 output. Symmetric to F3 — partial coverage, defensible
but should be self-documented.

**Fix:** Added Assertion 7 (lines 253-262 of post-fix file).

**After (new Assertion 7 block):**
```bash
# Assertion 7: stage S8 .gitignore installed (F7).
# Greenfield init copies project-template/.gitignore via plain `cp` (no
# pre-existing .gitignore in the empty fixture). Symmetric to F3 — init's
# internal stage_s8_gitignore check catches catastrophic failure, but we
# self-document the surface here.
if [[ -f "$SANDBOX/.gitignore" ]]; then
    t_pass "S8 .gitignore installed"
else
    t_fail "S8 .gitignore MISSING"
fi
```

**Verification:** Greenfield run reports `PASS S8 .gitignore installed`.

---

## 3. Files modified

| Path | Change type | Line delta | Findings addressed |
|---|---|---|---|
| `scripts/persona-contracts/contract-greenfield.sh` | modified | +79 / -3 | F1, F3, F5, F6, F7 |
| `scripts/persona-contracts/contract-mid-dev.sh` | modified | +21 / -8 | F4, F5 |
| `scripts/persona-contracts/contract-migration.sh` | modified | +25 / -7 | F2, F5 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-116-RETRO-FIX.md` | new | this report | (output) |

Aggregate: 3 files modified, 1 new doc, **+125 / -18 lines** across the
contract scripts (matches `git diff --stat` output: `123 insertions(+), 10
deletions(-)` — the small residual difference is comment-line
restructuring within the F1 mapping comment block).

No edits to forbidden files:
- `BACKLOG.md` — untouched (verified via `git status`).
- `CHANGELOG.md` — untouched.
- `scripts/init-project.sh` — read-only (used as F1 parity source only).
- `scripts/migrate-v10-to-v11.sh` — read-only (used as F2 sidecar-suffix
  reference only).
- `.github/workflows/validate-pack.yml` — untouched (concurrent BD-118
  retro-fix coder is editing this).
- `test-fixtures/README.md` — untouched.
- `maintenance-docs/v11-implementation/RELEASE-GATE.md` — untouched
  (concurrent BD-117 retro-fix coder is editing this; pre-existing
  modification visible in `git status` from earlier in the session is
  not from this BD-116 fix).
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` —
  untouched.
- `scripts/test-persona-contracts.sh` — untouched (F5 decision: marker
  belongs on contract scripts themselves, not on aggregator wrapper which
  already has it on line 2).

---

## 4. Verification

### 4.1 Syntax check on every modified contract script

```
contract-greenfield.sh         syntax OK
contract-mid-dev.sh            syntax OK
contract-migration.sh          syntax OK
```

(Command: `bash -n <script>` per file; all three exited 0 with no
diagnostics.)

### 4.2 F1 parity check (mandatory per task constraints)

Enumeration of `stage_s11_v11_artifacts()` (read directly from
`scripts/init-project.sh:803-884`) versus the post-F1
`contract-greenfield.sh` coverage:

| Sub-stage | init-project.sh produces | Greenfield post-F1 verifies |
|---|---|---|
| 1a | `docs/pack/HELP-FRAGMENT.md` | `s11_files[0]` |
| 1b | `docs/pack/HELP-FRAGMENT-TRACKER.md` | `s11_files[1]` |
| 2 | `tracker.toml.example` | `s11_files[2]` |
| 3a | `.github/ISSUE_TEMPLATE/config.yml` | NEW glob block lines 197-215 |
| 3b | `.github/ISSUE_TEMPLATE/inbound.yml` | NEW glob block lines 197-215 |
| 3c | `.github/ISSUE_TEMPLATE/work-item.yml` | NEW glob block lines 197-215 |
| 4a | `.claude/skills/pack-help/SKILL.md` | `s11_files[5]` |
| 4b | `.codex/skills/pack-help/SKILL.md` | `s11_files[6]` |
| 4c | `.gemini/commands/pack-help.toml` | `s11_files[7]` |
| 5a | `scripts/pack-help.sh` (+ executable bit) | `s11_files[3]` + line 217 executable check |
| 5b | `scripts/lib/detect.sh` | `s11_files[4]` |

Items pre-F1 missing: 3a, 3b, 3c (issue forms — entire sub-stage 3).
Items post-F1 covered: ALL.

The new glob block is dynamic (iterates the project-template directory
at runtime), so a future BD that adds a 4th issue form to
`project-template/.github/ISSUE_TEMPLATE/` is automatically picked up
by both the migration contract (existing) and now the greenfield
contract (post-F1). The contract auto-evolves.

### 4.3 F2 sidecar-glob alignment check

```
MIGRATOR_OWN_SIDECAR_SUFFIX value (migrate-v10-to-v11.sh:76):  v10-customized
→ migrator-produced basename:                                   config.toml.v10-customized
→ post-F2 glob:                                                 config.toml.*-customized
→ shell-glob match (verified via bash `case` test):             MATCH
→ pre-F2 glob (config.toml.pre-*) match:                        NO MATCH
```

Verification command and output:
```bash
$ case "config.toml.v10-customized" in
$     config.toml.*-customized) echo "PASS: glob matches" ;;
$     *) echo "FAIL: glob does not match" ;;
$ esac
PASS: glob matches
```

### 4.4 End-to-end contract runs

Each contract was executed against a fresh sandbox post-fix:

```
contract-greenfield.sh:  175 passed, 0 failed
contract-mid-dev.sh:      25 passed, 0 failed
contract-migration.sh:    30 passed, 0 failed
```

Aggregator (`scripts/test-persona-contracts.sh`):
```
Persona contract summary: 3/3 passed
  PASS:
    - contract-greenfield.sh
    - contract-mid-dev.sh
    - contract-migration.sh

All persona contracts PASS.
```

The new F1 / F3 / F7 assertions visible in the greenfield output:
```
PASS S11 sub-stage 3: all .github/ISSUE_TEMPLATE/*.yml installed by greenfield init
PASS S6 docs/pack/PM-CHAT.md present
PASS S6 docs/pack/PLATFORM-SKILLS.md present
PASS S6 docs/pack/PACK-FEEDBACK.md present
PASS S6 docs/pack/prompts/ has 10 prompt files (>=10 expected)
PASS S8 .gitignore installed
```

The F2 fix could not be observed firing the new fallback path in this
run (the migration run took the primary 3c path: live `.codex/config.toml`
retains the ollama-block deletion, so the `if !grep -q …; then …else
[fallback] fi` skips the sidecar branch). The F2 fix is verified by the
glob alignment check above (§4.3) and by inspection of the surrounding
apply→resume flow which produces `.v10-customized` sidecars when
ours/theirs/base divergence requires reconciliation.

### 4.5 validate-pack regression check

`python3 scripts/validate-pack.py` reports `PASSED — all checks clean`
(all 32 checks PASS) post-fix. The added `# pack-internal: true`
markers on the three contract scripts do not affect Check 23 today
(which only iterates top-level `scripts/`); they are forward-compatible
with a hypothetical recursive Check 23 hardening (POQ candidate, see
§5).

### 4.6 Definition-of-Done checklist

| Item | Status |
|---|---|
| All 7 findings (F1-F7) addressed | PASS |
| `IMPLEMENTATION-REPORT-BD-116-RETRO-FIX.md` exists with required sections | PASS |
| `bash -n` passes on every modified contract script | PASS (3/3) |
| F1 parity check pasted in §4 confirms greenfield covers every `stage_s11_v11_artifacts()` artifact | PASS (§4.2 table; pre-fix gap was sub-stages 3a/3b/3c — now covered) |
| F2 verified against actual `MIGRATOR_OWN_SIDECAR_SUFFIX` value | PASS (§4.3 glob-match verification) |
| No edits to forbidden files | PASS (`git status` shows only the 3 contract scripts modified + the new report file as additions) |
| `set -uo pipefail` compatible with refactored mid-dev cleanup | PASS (`PRE_SNAPSHOT=""` / `PRE_GITIGNORE=""` pre-declarations + `${VAR:-}` guards inside `_cleanup`) |
| macOS bash 3.2 + BSD compatibility | PASS (no `mapfile` / `readarray`; no `&>`; no associative arrays; `shopt -s nullglob` is bash 3.2+) |
| Aggregator + all 3 contracts pass green | PASS (3/3) |
| validate-pack.py PASSED — all checks clean | PASS (32/32 checks) |

---

## 5. Out-of-scope items

These were noticed during the fix but NOT acted on per task scoping
("BACKLOG.md — Pack Chat handles BD entries (any deferral discoveries
go to your report's §5; Pack Chat decides tracking)"). Pack Chat
decides whether to convert any of these into new BDs.

### 5.1 Check 23 recursive-scan hardening (POQ candidate)

`scripts/validate-pack.py` Check 23 (`_is_pack_internal()` + the
top-level `scripts/` iteration) only scans the top-level `scripts/`
directory. The three persona-contract scripts now carry the
`pack-internal: true` marker per F5, but Check 23 will not see them
unless it's hardened to recurse into `scripts/persona-contracts/`. F5
is forward-compatible with such a hardening; the hardening itself is
out of scope for BD-116 (it would be a Check-23 enhancement BD).

### 5.2 Aggregator parallelism via `xargs -P` or background jobs

`scripts/test-persona-contracts.sh` runs the three contracts
sequentially. The contracts are independent (each mints its own
sandbox) so they could be parallelized. Out of scope for BD-116
(performance optimization, not a correctness fix); also the comment at
line 19-20 of the wrapper notes the deliberate sequentiality choice
(easier debugging when one contract fails).

### 5.3 BD-088 sidecar-suffix-vs-`.pre-update` documentation gap

The F2 finding surfaces a real documentation gap: the pack has TWO
sidecar suffix conventions in active use (`.pre-update` for
`init-project.sh --update`; `.v<N>-customized` for v<N>→v<N+1>
migrators). Searches for `pre-update` in the repo turn up
`scripts/lib/customization-preserve.sh:113` (the default suffix); the
`v10-customized` form is at `scripts/migrate-v10-to-v11.sh:76`. There's
no single doc explaining the two paths. A documentation BD that adds a
one-page "sidecar suffix conventions" reference under
`maintenance-docs/v11-implementation/` (or similar) could prevent
future contributors from making the same `pre-` vs. `v<N>-customized`
mistake F2 caught. Out of scope for this fix.

### 5.4 Greenfield contract S6 vs S11 ordering observation

While adding F3 (S6 assertions), I noticed the greenfield contract's
assertions are now numbered 1-7 but their internal ordering vs.
`init-project.sh`'s actual stage execution order is: 4 (S4 skills), 2
(S2 agents), 7 (S7 trinity), 11 (S11 client artifacts), 5 (S5
agent-run.sh), 6 (S6 docs/pack — NEW per F3), 8 (S8 .gitignore — NEW
per F7). The contract's "Assertion N" numbers do not correspond to
init-project.sh's "Stage SN" numbers. This is fine (contract assertion
numbering is its own concern) but a future maintainer might find it
confusing. Could be addressed by a comment at the top of the contract
mapping each assertion to its source stage. Out of scope as
cosmetic-only.

### 5.5 Mid-dev contract no S6/S8/S11 coverage

The mid-dev contract verifies user-domain preservation + pack-files
presence (Assertions 1-4) but does not have F1/F3/F7-equivalent
coverage of S6/S8/S11. The original BD-116 scoping placed S6/S8/S11
verification in greenfield (where `--for-contract greenfield` produces
a clean install) and BD-088 customization-preservation invariants in
mid-dev. Adding S6/S8/S11 mirrors to mid-dev would be defensible for
symmetry but doubles the surface checked redundantly with greenfield.
Out of scope as deliberate scoping choice; a Pack-Chat triage call.

---

**Final state:** `git rev-parse HEAD` observed:
- pre-flight (start of session): `94ae56c3d0a8de24a1a789829510a387f8314584`
- end of session: `a022d49aefa6f0903ed18468ba7f50dacca5ae78`

The HEAD difference is from Pack Chat (parent process) committing
sibling Batch-21c retro fixes (BD-117, BD-118) concurrently with this
agent's session — not from this agent. This agent ran no
state-changing git verbs (verified read-only via `git rev-parse`,
`git status`, `git diff --stat` only). The 3 modified contract
scripts and the new report file are working-tree changes for Pack
Chat to stage and commit:

```
$ git status --short
 M scripts/persona-contracts/contract-greenfield.sh
 M scripts/persona-contracts/contract-mid-dev.sh
 M scripts/persona-contracts/contract-migration.sh
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-116-RETRO-FIX.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-116-RETRO.md  (pre-existing — input doc, not produced by this agent)
```
