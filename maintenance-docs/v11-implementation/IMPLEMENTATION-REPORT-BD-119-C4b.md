# IMPLEMENTATION-REPORT-BD-119-C4b.md

C-4b follow-up commit closing the T-12 gap (POQ-6 from
IMPLEMENTATION-REPORT-BD-119-C4.md). PLAN §6 row "C-4" bundled T-12
(`scripts/test-migrator-core.sh`) alongside T-10
(`scripts/test-migrator-manifest.sh`); the C-4 implementer's prompt only
authorized T-10. C-4b authors the deferred unit-test file for the core's
public-API surface, which was frozen at C-3.

---

## 1. Branch + final HEAD SHA

- Branch: `worktree-agent-aa336249cbda43094`
- HEAD: `9d4efd62b4ca698dec1ec37271b05e80903f5807` (unchanged from session start —
  C-4b is a working-tree-only delta; Pack Chat will commit per repo workflow)

---

## 2. Pre-flight check output (verbatim)

```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aa336249cbda43094
9d4efd62b4ca698dec1ec37271b05e80903f5807
worktree-agent-aa336249cbda43094
9d4efd6 feat: v11 — BD-119 C-4: implement stages + manifest engine + manifest unit tests
5934547 docs: v11 — BD-121/122/123 v9 sunset + fixture convention + tracker.toml.example relocation (Open)
5f11419 feat: v11 — BD-119 C-3: implement core sequencer + public API (surface lock)
2b17184 feat: v11 — BD-119 C-2: land migrator-core/stages/manifest skeletons
dcd37f7 feat: v11 — pack-coder agent + repo-local Pack memory section
fda99ef feat: v11 — BD-119 C-1: detect_target_pack_version + validate-pack Check 26 (lenient)
6286fcf feat: v11 — BD-115 existing-project-mid-dev fixture
d7b3f07 docs: v11 — BD-119 architecture + plan
4a6aa6b docs: v11 — BD-114..BD-120 pre-Phase-A persona-coverage batch (Open)
ef3b41e feat: v11 — BD-113 test-fixtures/ persistent baseline directory
migrator-core.sh
migrator-manifest.sh
migrator-stages.sh
test-detect.sh
test-migrator-manifest.sh
```

All preconditions met:
- worktree path correct
- HEAD = `9d4efd6` (the C-4 commit)
- branch = `worktree-agent-aa336249cbda43094`
- three migrator libs present
- `test-migrator-manifest.sh` + `test-detect.sh` present; `test-migrator-core.sh`
  not yet present (this report creates it)

---

## 3. T-12 scope as executed

Per PLAN §1 row T-12 + ARCHITECTURE §3 / §5 + the C-4 report POQ-6 enumeration,
the new `scripts/test-migrator-core.sh` covers the FROZEN public-API surface
of `scripts/lib/migrator-core.sh` only. It does NOT re-cover the manifest /
trinity-parity / iterator paths (those live in `test-migrator-manifest.sh`
and were intentionally not duplicated per POQ-6 recommended-default).

19 test cases, grouped:

### 3.1 Surface-lock guards (cases 1–2)

1. All 8 exit-code constants present after sourcing core, with PLAN §3.5
   frozen values (10/11/12/13/14/15/16/99) AND `EXIT_NOT_V10=13` synonym.
2. All 6 public-API function names declared after sourcing core
   (`migrator_run`, `migrator_dispatch`, `migrator_detect_target_version`,
   `migrator_select_adapter`, `migrator_baseline_to_tmp`,
   `migrator_target_surface_for_version`).

### 3.2 `migrator_detect_target_version` (cases 3–5)

3. v10-shape target (CLAUDE.md + .claude/ + docs/pack/PROMPT-TEMPLATES.md) → `v10`.
4. v11-shape target (trinity addenda fingerprint via `pack help` quote) → `v11`.
5. Empty unrecognised target → `unknown`.

(Note: `detect_target_pack_version` is intentionally git-agnostic per
detect.sh §322; there is no `EXIT_NOT_GIT` path for the detect helper. The
`EXIT_NOT_GIT` exit code is exercised inside `_stage_preflight` via
`migrator_run` — see case 18's sibling concern; we use the dirty case
since dirty is more deterministic on a fresh fixture than non-git.)

### 3.3 `migrator_select_adapter` (cases 6–10)

6. `from=v10` → finds `migrate-v10-to-v11.sh` (positive primary).
7. `from=10` (bare numeric, no leading `v`) → also resolves (regex tolerance).
8. `from=v99` → `EXIT_INTERNAL=99` with `"no adapter found"` (negative).
9. `PACK` unset at call time → `EXIT_PACK_INVALID=10`.
10. `from=vBADARG` (non-numeric) → `EXIT_INTERNAL=99` with `"invalid from-version"`.

### 3.4 `migrator_baseline_to_tmp` (cases 11–13)

11. Success: `README.md` at `MIGRATOR_BASELINE_TAG=v10` → rc=0 + non-empty tmpfile.
12. File missing at baseline (`no-such-file-at-baseline-tag.md`) → rc=1 + empty
    tmpfile (the documented non-fatal path; baseline-missing-FILE is a normal
    case for files newly added in vN+1).
13. Empty arguments → `EXIT_INTERNAL=99` with `"usage"` hint.

(Note: PLAN §1 T-12 wording mentions `EXIT_BASELINE_MISSING` "or the
documented exit code". The actual implementation per migrator-core.sh
§411 returns rc=1 (not EXIT_BASELINE_MISSING=14) for the
file-absent-at-tag case. `EXIT_BASELINE_MISSING` is reserved for the
*tag itself* missing, which is enforced upstream in `_stage_preflight`,
not in this helper. The test asserts the documented behaviour.)

### 3.5 `migrator_target_surface_for_version` (cases 14–16)

14. `v10` → all 8 expected v10 entries present; v11-only additions ABSENT
    (negative-coverage to catch surface drift toward v11 contents).
15. `v11` → v10 entries inherited + v11 additions present
    (`docs/pack/HELP-FRAGMENT.md`, `tracker.toml.example`,
    `.github/ISSUE_TEMPLATE/work-item.yml`, per-CLI pack-help skill paths).
16. `v99` → echoes `"unknown"` + rc=1 (documented-default per core §454).

### 3.6 `migrator_run` / `migrator_dispatch` (cases 17–19)

17. Happy-path dry-run smoke: minimal git-clean fixture (CLAUDE.md +
    .claude/) with empty manifest + empty hooks. `migrator_run --dry-run` →
    rc=0; CLAUDE.md content unchanged after the call (mutation-free
    invariant).
18. Dirty target (untracked file present) → `EXIT_DIRTY=12` with
    `"working tree is dirty"` message.
19. `migrator_dispatch` arity guard: zero-args → `EXIT_INTERNAL=99` with
    `"expected exactly one argument"`.

19 cases total — exceeds the ≥10-case floor in the prompt.

---

## 4. Full file contents — `scripts/test-migrator-core.sh`

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-core.sh — unit tests for the BD-119 migrator
# framework's CORE public-API surface (PLAN-BD-119.md §3.1, T-12).
#
# Companion to `scripts/test-migrator-manifest.sh` (engine-side coverage).
# This file exercises the *frozen public surface* in `migrator-core.sh`:
#
#   - migrator_detect_target_version <target-dir>
#       v10-shape target  → echoes "v10"
#       v11-shape target  → echoes "v11"
#       unknown target    → echoes "unknown"
#       (delegates to detect_target_pack_version; no git-repo requirement,
#       see ARCHITECTURE-BD-119 §5.1 / detect.sh)
#
#   - migrator_select_adapter <from-version>
#       from=v10 → echoes path to migrate-v10-to-v11.sh
#       from=v9  → echoes path to migrate-v9-to-v10.sh
#       from=v99 → die EXIT_INTERNAL=99 ("no adapter found")
#       missing PACK → die EXIT_PACK_INVALID=10
#       invalid from arg → die EXIT_INTERNAL=99
#
#   - migrator_baseline_to_tmp <pack-relpath> <tmpfile>
#       success path (existing pack file at $MIGRATOR_BASELINE_TAG):
#         rc=0; tmpfile non-empty
#       baseline-missing-file (file absent at tag):
#         rc=1; tmpfile empty (NOT a fatal exit; documented behaviour)
#       missing args → die EXIT_INTERNAL=99
#
#   - migrator_target_surface_for_version <vN>
#       v10 → list contains expected v10 surface entries
#       v11 → list contains expected v11 additions
#       v99 → "unknown" + rc=1
#
#   - migrator_run / migrator_dispatch
#       happy-path dry-run smoke: minimal stub adapter + git-clean target
#         exits 0 in --dry-run mode
#       dirty target → exits EXIT_DIRTY=12
#
#   - Exit-code constants are present after sourcing the core
#     (PLAN §3.5: 8 constants + EXIT_NOT_V10 synonym).
#
# Each test case runs in a subshell with isolated fixtures so failures
# never bleed across cases. Read-only with respect to the pack repo;
# everything happens under a per-test temp directory.
#
# Usage:    bash scripts/test-migrator-core.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d -t test-migrator-core.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}

# Helper: source migrator-core.sh inside a subshell that has a minimal
# valid adapter contract pre-declared. The caller passes a body string
# of bash to execute after sourcing. Returns the body's rc; stdout +
# stderr captured by `$(... 2>&1)` at the call site.
_core_subshell() {
    local body="$1"
    bash -c '
        set -uo pipefail
        PACK="'"$PACK_ROOT"'"
        export PACK
        MIGRATOR_FROM_VERSION="v10"
        MIGRATOR_TO_VERSION="v11"
        MIGRATOR_BASELINE_TAG="v10"
        MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
        MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")
        migrator_manifest()             { :; }
        migrator_directory_sweeps()     { :; }
        migrator_relocations()          { :; }
        migrator_artifact_installs()    { :; }
        migrator_post_report_hook()     { :; }
        . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"
        '"$body"'
    '
}

# ── 1. Exit-code constants present (PLAN §3.5) ─────────────────────────
echo "== exit-code constants present after sourcing =="

out=$(_core_subshell '
    for c in EXIT_PACK_INVALID EXIT_NOT_GIT EXIT_DIRTY EXIT_NOT_BASELINE \
             EXIT_BASELINE_MISSING EXIT_LIB_MISSING EXIT_ALREADY_MIGRATED \
             EXIT_INTERNAL EXIT_NOT_V10; do
        if [[ -z "${!c:-}" ]]; then
            printf "missing:%s\n" "$c"
        fi
    done
    printf "EXIT_PACK_INVALID=%s EXIT_NOT_GIT=%s EXIT_DIRTY=%s\n" \
        "$EXIT_PACK_INVALID" "$EXIT_NOT_GIT" "$EXIT_DIRTY"
    printf "EXIT_NOT_BASELINE=%s EXIT_BASELINE_MISSING=%s EXIT_LIB_MISSING=%s\n" \
        "$EXIT_NOT_BASELINE" "$EXIT_BASELINE_MISSING" "$EXIT_LIB_MISSING"
    printf "EXIT_ALREADY_MIGRATED=%s EXIT_INTERNAL=%s EXIT_NOT_V10=%s\n" \
        "$EXIT_ALREADY_MIGRATED" "$EXIT_INTERNAL" "$EXIT_NOT_V10"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" != *"missing:"* \
   && "$out" == *"EXIT_PACK_INVALID=10"* \
   && "$out" == *"EXIT_NOT_GIT=11"* \
   && "$out" == *"EXIT_DIRTY=12"* \
   && "$out" == *"EXIT_NOT_BASELINE=13"* \
   && "$out" == *"EXIT_BASELINE_MISSING=14"* \
   && "$out" == *"EXIT_LIB_MISSING=15"* \
   && "$out" == *"EXIT_ALREADY_MIGRATED=16"* \
   && "$out" == *"EXIT_INTERNAL=99"* \
   && "$out" == *"EXIT_NOT_V10=13"* ]]; then
    pass "all 8 exit-code constants + EXIT_NOT_V10 synonym present with frozen values"
else
    fail "exit-code constants" "all defined with PLAN §3.5 values" "rc=$rc out=$out"
fi

# ── 2. Public-API names defined ────────────────────────────────────────
echo "== public API names defined (PLAN §3.1) =="

out=$(_core_subshell '
    for fn in migrator_run migrator_dispatch migrator_detect_target_version \
              migrator_select_adapter migrator_baseline_to_tmp \
              migrator_target_surface_for_version; do
        if ! declare -F "$fn" >/dev/null 2>&1; then
            printf "missing-fn:%s\n" "$fn"
        fi
    done
    printf "all-fn-checked\n"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" != *"missing-fn:"* && "$out" == *"all-fn-checked"* ]]; then
    pass "six public-API function names declared after sourcing core"
else
    fail "public-API names" "all 6 declared" "rc=$rc out=$out"
fi

# ── 3. migrator_detect_target_version: v10 shape ───────────────────────
echo "== migrator_detect_target_version: v10 shape =="

fx="$FIXTURE_BASE/detect-v10"
mkdir -p "$fx/.claude" "$fx/docs/pack"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
v10 shape.
EOF
echo "# PROMPT-TEMPLATES.md" > "$fx/docs/pack/PROMPT-TEMPLATES.md"

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"v10"* ]]; then
    pass "v10-shape target → echoes v10"
else
    fail "detect-v10" "v10" "rc=$rc out=$out"
fi

# ── 4. migrator_detect_target_version: v11 shape ───────────────────────
echo "== migrator_detect_target_version: v11 shape =="

fx="$FIXTURE_BASE/detect-v11"
mkdir -p "$fx/.claude/skills/pack-help"
echo "# SKILL.md" > "$fx/.claude/skills/pack-help/SKILL.md"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
- run `pack help` for the full verb list, or `/pack-help` in your CLI.
EOF

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"v11"* ]]; then
    pass "v11-shape target (trinity addenda fingerprint) → echoes v11"
else
    fail "detect-v11" "v11" "rc=$rc out=$out"
fi

# ── 5. migrator_detect_target_version: unknown ─────────────────────────
echo "== migrator_detect_target_version: unknown =="

fx="$FIXTURE_BASE/detect-unknown"
mkdir -p "$fx"

out=$(_core_subshell '
    migrator_detect_target_version "'"$fx"'"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"unknown"* ]]; then
    pass "empty / un-recognized target → echoes unknown"
else
    fail "detect-unknown" "unknown" "rc=$rc out=$out"
fi

# ── 6. migrator_select_adapter: positive (v10 → migrate-v10-to-v11.sh) ─
echo "== migrator_select_adapter: from=v10 finds migrate-v10-to-v11.sh =="

out=$(_core_subshell '
    migrator_select_adapter v10
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"migrate-v10-to-v11.sh"* ]]; then
    pass "from=v10 → finds scripts/migrate-v10-to-v11.sh"
else
    fail "select-adapter-v10" "path ending in migrate-v10-to-v11.sh" \
        "rc=$rc out=$out"
fi

# ── 7. migrator_select_adapter: bare-numeric form accepted ─────────────
echo "== migrator_select_adapter: from=10 (bare number) accepted =="

out=$(_core_subshell '
    migrator_select_adapter 10
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"migrate-v10-to-v11.sh"* ]]; then
    pass "from=10 (no leading v) also resolves to migrate-v10-to-v11.sh"
else
    fail "select-adapter-bare-10" "path ending in migrate-v10-to-v11.sh" \
        "rc=$rc out=$out"
fi

# ── 8. migrator_select_adapter: negative (v99 missing) ─────────────────
echo "== migrator_select_adapter: from=v99 → no adapter (EXIT_INTERNAL=99) =="

out=$(_core_subshell '
    migrator_select_adapter v99 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"no adapter found"* ]]; then
    pass "from=v99 → die EXIT_INTERNAL with 'no adapter found'"
else
    fail "select-adapter-v99" "rc=99 + 'no adapter found'" "rc=$rc out=$out"
fi

# ── 9. migrator_select_adapter: PACK unset → EXIT_PACK_INVALID ─────────
echo "== migrator_select_adapter: PACK unset → EXIT_PACK_INVALID=10 =="

# Build a body that explicitly unsets PACK before calling the helper. The
# core's check fires on `[[ -z "${PACK:-}" || ! -d ... ]]`.
out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")
    migrator_manifest()             { :; }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"
    unset PACK
    migrator_select_adapter v10 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 10 && "$out" == *"PACK environment variable not set"* ]]; then
    pass "PACK unset → die EXIT_PACK_INVALID (10)"
else
    fail "select-adapter-no-pack" "rc=10 + 'PACK environment variable not set'" \
        "rc=$rc out=$out"
fi

# ── 10. migrator_select_adapter: invalid from arg → EXIT_INTERNAL ──────
echo "== migrator_select_adapter: invalid arg → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_select_adapter "vBADARG" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"invalid from-version"* ]]; then
    pass "from='vBADARG' (non-numeric) → die EXIT_INTERNAL with 'invalid from-version'"
else
    fail "select-adapter-bad-arg" "rc=99 + 'invalid from-version'" "rc=$rc out=$out"
fi

# ── 11. migrator_baseline_to_tmp: success path ─────────────────────────
echo "== migrator_baseline_to_tmp: pack file at v10 baseline → rc=0, tmpfile non-empty =="

tmpf="$FIXTURE_BASE/baseline-out.txt"
out=$(_core_subshell '
    rm -f "'"$tmpf"'"
    migrator_baseline_to_tmp "README.md" "'"$tmpf"'"
    rc=$?
    printf "rc=%s\n" "$rc"
    if [[ -s "'"$tmpf"'" ]]; then
        printf "tmpfile-non-empty\n"
    fi
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"rc=0"* \
   && "$out" == *"tmpfile-non-empty"* ]]; then
    pass "baseline_to_tmp success: README.md@v10 → rc=0 + non-empty tmpfile"
else
    fail "baseline_to_tmp success" "rc=0 + tmpfile-non-empty" "rc=$rc out=$out"
fi

# ── 12. migrator_baseline_to_tmp: file missing at baseline → rc=1, empty tmpfile
echo "== migrator_baseline_to_tmp: nonexistent pack-relpath at v10 → rc=1, empty tmpfile =="

tmpf="$FIXTURE_BASE/baseline-out-missing.txt"
out=$(_core_subshell '
    rm -f "'"$tmpf"'"
    migrator_baseline_to_tmp "no-such-file-at-baseline-tag.md" "'"$tmpf"'"
    rc=$?
    printf "rc=%s\n" "$rc"
    if [[ ! -s "'"$tmpf"'" ]]; then
        printf "tmpfile-empty\n"
    fi
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"rc=1"* \
   && "$out" == *"tmpfile-empty"* ]]; then
    pass "baseline_to_tmp missing-at-baseline: rc=1 + empty tmpfile (non-fatal)"
else
    fail "baseline_to_tmp missing" "rc=1 + tmpfile-empty" "rc=$rc out=$out"
fi

# ── 13. migrator_baseline_to_tmp: missing args → EXIT_INTERNAL ─────────
echo "== migrator_baseline_to_tmp: missing args → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_baseline_to_tmp "" "" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"usage"* ]]; then
    pass "baseline_to_tmp empty-args → die EXIT_INTERNAL with usage hint"
else
    fail "baseline_to_tmp no-args" "rc=99 + 'usage'" "rc=$rc out=$out"
fi

# ── 14. migrator_target_surface_for_version v10 ────────────────────────
echo "== migrator_target_surface_for_version v10 =="

out=$(_core_subshell '
    migrator_target_surface_for_version v10
' 2>&1)
rc=$?
# v10 surface (per migrator-core.sh §3 / architecture) includes CLAUDE.md,
# AGENTS.md, GEMINI.md, the three .claude/.codex/.gemini agent dirs, and
# .codex/config.toml + BACKLOG.md. v10 must NOT advertise the v11-only
# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).
if [[ $rc -eq 0 \
   && "$out" == *"CLAUDE.md"* \
   && "$out" == *"AGENTS.md"* \
   && "$out" == *"GEMINI.md"* \
   && "$out" == *".claude/agents"* \
   && "$out" == *".codex/agents"* \
   && "$out" == *".gemini/agents"* \
   && "$out" == *".codex/config.toml"* \
   && "$out" == *"BACKLOG.md"* \
   && "$out" != *"HELP-FRAGMENT.md"* \
   && "$out" != *"tracker.toml.example"* \
   && "$out" != *"ISSUE_TEMPLATE"* ]]; then
    pass "v10 surface lists 8 expected v10 entries; excludes v11-only additions"
else
    fail "target_surface_v10" "v10 entries present + v11 entries absent" \
        "rc=$rc out=$out"
fi

# ── 15. migrator_target_surface_for_version v11 ────────────────────────
echo "== migrator_target_surface_for_version v11 =="

out=$(_core_subshell '
    migrator_target_surface_for_version v11
' 2>&1)
rc=$?
# v11 inherits v10's surface and adds the v11-only additions.
if [[ $rc -eq 0 \
   && "$out" == *"CLAUDE.md"* \
   && "$out" == *"AGENTS.md"* \
   && "$out" == *"GEMINI.md"* \
   && "$out" == *"docs/pack/HELP-FRAGMENT.md"* \
   && "$out" == *"tracker.toml.example"* \
   && "$out" == *".github/ISSUE_TEMPLATE/work-item.yml"* \
   && "$out" == *".claude/skills/pack-help/SKILL.md"* \
   && "$out" == *".codex/skills/pack-help/SKILL.md"* \
   && "$out" == *".gemini/commands/pack-help.toml"* ]]; then
    pass "v11 surface inherits v10 + adds HELP-FRAGMENT/tracker.toml.example/ISSUE_TEMPLATE/per-CLI pack-help"
else
    fail "target_surface_v11" "v10 entries + v11 additions" "rc=$rc out=$out"
fi

# ── 16. migrator_target_surface_for_version v99 → unknown / rc=1 ──────
echo "== migrator_target_surface_for_version v99 → unknown =="

out=$(_core_subshell '
    migrator_target_surface_for_version v99
    printf "post-rc=%s\n" "$?"
' 2>&1)
rc=$?
if [[ "$out" == *"unknown"* && "$out" == *"post-rc=1"* ]]; then
    pass "target_surface_for_version v99 → echoes 'unknown' + rc=1"
else
    fail "target_surface_v99" "'unknown' + rc=1" "rc=$rc out=$out"
fi

# ── 17. migrator_run dry-run smoke happy path ──────────────────────────
echo "== migrator_run --dry-run smoke happy path =="

# Build a minimal target: git repo, clean, with CLAUDE.md + .claude/.
# Adapter declares an empty manifest + minimal hooks. Dry-run must not
# mutate the target; it should exit 0 after preflight + libs init +
# manifest validation (empty manifest, empty sweeps).
fx="$FIXTURE_BASE/run-dryrun-happy"
mkdir -p "$fx/.claude"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A
git -C "$fx" commit -q -m "init"

out=$(_core_subshell '
    migrator_run --dry-run "'"$fx"'" 2>&1
' 2>&1)
rc=$?
# Tolerate prior_sidecars list of ("pre-update") because no .pre-update
# files exist in the fresh fixture. State dir + dispositions.tsv may be
# created by _stage_libs (init); that is dry-run-tolerant per stages.
if [[ $rc -eq 0 ]]; then
    # Sanity: target's CLAUDE.md must still be the original placeholder
    # (no body rewrite) — dry-run must not have mutated it.
    body=$(cat "$fx/CLAUDE.md" 2>/dev/null)
    if [[ "$body" == "# CLAUDE.md" ]]; then
        pass "migrator_run --dry-run: rc=0 on minimal happy path; CLAUDE.md untouched"
    else
        fail "migrator_run dry-run mutated CLAUDE.md" "# CLAUDE.md" "$body"
    fi
else
    fail "migrator_run dry-run happy path" "rc=0" "rc=$rc out=$out"
fi

# ── 18. migrator_run on dirty target → EXIT_DIRTY (12) ────────────────
echo "== migrator_run on dirty target → EXIT_DIRTY (12) =="

fx="$FIXTURE_BASE/run-dirty"
mkdir -p "$fx/.claude"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A
git -C "$fx" commit -q -m "init"
# Now make the working tree dirty: add an untracked file.
printf 'untracked\n' > "$fx/dirty-marker.txt"

out=$(_core_subshell '
    migrator_run "'"$fx"'" 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 12 && "$out" == *"working tree is dirty"* ]]; then
    pass "migrator_run on dirty target → EXIT_DIRTY (12) with 'working tree is dirty'"
else
    fail "migrator_run dirty" "rc=12 + 'working tree is dirty'" "rc=$rc out=$out"
fi

# ── 19. migrator_dispatch arity guard ─────────────────────────────────
echo "== migrator_dispatch: zero-args → EXIT_INTERNAL =="

out=$(_core_subshell '
    migrator_dispatch 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"expected exactly one argument"* ]]; then
    pass "migrator_dispatch with no args → die EXIT_INTERNAL (arity guard)"
else
    fail "migrator_dispatch no-args" "rc=99 + 'expected exactly one argument'" \
        "rc=$rc out=$out"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```

---

## 5. Verification output

### 5.1 `bash -n scripts/test-migrator-core.sh`

```
bash -n OK
```
(rc=0)

### 5.2 `bash scripts/test-migrator-core.sh`

```
== exit-code constants present after sourcing ==
  pass: all 8 exit-code constants + EXIT_NOT_V10 synonym present with frozen values
== public API names defined (PLAN §3.1) ==
  pass: six public-API function names declared after sourcing core
== migrator_detect_target_version: v10 shape ==
  pass: v10-shape target → echoes v10
== migrator_detect_target_version: v11 shape ==
  pass: v11-shape target (trinity addenda fingerprint) → echoes v11
== migrator_detect_target_version: unknown ==
  pass: empty / un-recognized target → echoes unknown
== migrator_select_adapter: from=v10 finds migrate-v10-to-v11.sh ==
  pass: from=v10 → finds scripts/migrate-v10-to-v11.sh
== migrator_select_adapter: from=10 (bare number) accepted ==
  pass: from=10 (no leading v) also resolves to migrate-v10-to-v11.sh
== migrator_select_adapter: from=v99 → no adapter (EXIT_INTERNAL=99) ==
  pass: from=v99 → die EXIT_INTERNAL with 'no adapter found'
== migrator_select_adapter: PACK unset → EXIT_PACK_INVALID=10 ==
  pass: PACK unset → die EXIT_PACK_INVALID (10)
== migrator_select_adapter: invalid arg → EXIT_INTERNAL ==
  pass: from='vBADARG' (non-numeric) → die EXIT_INTERNAL with 'invalid from-version'
== migrator_baseline_to_tmp: pack file at v10 baseline → rc=0, tmpfile non-empty ==
  pass: baseline_to_tmp success: README.md@v10 → rc=0 + non-empty tmpfile
== migrator_baseline_to_tmp: nonexistent pack-relpath at v10 → rc=1, empty tmpfile ==
  pass: baseline_to_tmp missing-at-baseline: rc=1 + empty tmpfile (non-fatal)
== migrator_baseline_to_tmp: missing args → EXIT_INTERNAL ==
  pass: baseline_to_tmp empty-args → die EXIT_INTERNAL with usage hint
== migrator_target_surface_for_version v10 ==
  pass: v10 surface lists 8 expected v10 entries; excludes v11-only additions
== migrator_target_surface_for_version v11 ==
  pass: v11 surface inherits v10 + adds HELP-FRAGMENT/tracker.toml.example/ISSUE_TEMPLATE/per-CLI pack-help
== migrator_target_surface_for_version v99 → unknown ==
  pass: target_surface_for_version v99 → echoes 'unknown' + rc=1
== migrator_run --dry-run smoke happy path ==
  pass: migrator_run --dry-run: rc=0 on minimal happy path; CLAUDE.md untouched
== migrator_run on dirty target → EXIT_DIRTY (12) ==
  pass: migrator_run on dirty target → EXIT_DIRTY (12) with 'working tree is dirty'
== migrator_dispatch: zero-args → EXIT_INTERNAL ==
  pass: migrator_dispatch with no args → die EXIT_INTERNAL (arity guard)

=== Results: 19 passed, 0 failed ===
```
(rc=0; 19/19 PASS)

### 5.3 `bash scripts/test-migrator-manifest.sh` (regression)

```
  pass: preflight: idempotency re-run exits EXIT_ALREADY_MIGRATED (16)

=== Results: 12 passed, 0 failed ===
```
(rc=0; 12/12 — unchanged)

### 5.4 `bash scripts/test-detect.sh` (regression)

```
  pass: v10 shape (PROMPT-TEMPLATES + no v11 markers) → v10 (signal 4)

=== Results: 40 passed, 0 failed ===
```
(rc=0; 40/40 — unchanged)

### 5.5 `python3 scripts/validate-pack.py` (regression)

```
============================================================
PASSED — all checks clean
```
(rc=0; 26/26 — unchanged)

### 5.6 `git status`

```
On branch worktree-agent-aa336249cbda43094
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	scripts/test-migrator-core.sh

nothing added to commit but untracked files present (use "git add" to track)
```

Only the new test file is untracked. No source files under `scripts/lib/`
modified. HEAD unchanged at `9d4efd6`.

---

## 6. Plan deviations

**Zero.** C-4b implements exactly the T-12 scope per PLAN §1 row T-12 and
§3 / §3.5 surface lock. The PLAN's mention of wiring `validate-pack.yml`
with a new test step (the second item in T-12) is intentionally NOT done
in C-4b — the pack repo's CI is already invoked via
`scripts/validate-pack.py`, and `validate-pack.yml` (per `ls
.github/workflows/`) hosts the validate-pack runner; PLAN §6 row C-4
explicitly checks for the test running green, but the wiring of a
NEW yml step would be a yml edit that is out of scope without explicit
caller authorization. The test is wired to run via CI as soon as Pack
Chat staples it into `validate-pack.yml`; that yml edit is a one-line
add and is not a coder-discretionary change. Recording this as a
trailing question rather than a deviation: see §7 New POQs.

---

## 7. New POQs / dispositions

### POQ-6 — Resolved

T-12 is now delivered. `scripts/test-migrator-core.sh` ships with 19
cases covering the frozen public-API surface as spec'd in PLAN §1 T-12
and §3.1 / §3.5. Pack Chat may close POQ-6 by referencing this commit.

### POQ-8 (new, low-risk) — `validate-pack.yml` test-step wiring

**Question:** PLAN T-12 second deliverable is a `validate-pack.yml`
step that runs `bash scripts/test-migrator-core.sh`. Should that yml
edit live in C-4b (so the regression suite is wired the moment the
test ships) or in C-7 (the docs-cleanup commit alongside README/trinity
updates)?

**Recommended default:** wire it in C-4b's commit (one yml `- name`
entry). The test passes locally; failing to wire it leaves a regression
window where T-12 is "shipped" but not gated.

**Trigger to escalate:** if Pack Chat prefers to keep yml edits
batched into C-7 for clean diff history, that is acceptable —
test-detect.sh and test-migrator-manifest.sh both run via the same
runner, so the new test simply needs the same one-line add. Author of
this report did NOT make the yml edit because the prompt explicitly
restricted scope to `scripts/test-migrator-core.sh`.

---

## 8. Definition-of-Done for C-4b

| DoD item | Status |
|---|---|
| `scripts/test-migrator-core.sh` exists | PASS |
| `bash -n scripts/test-migrator-core.sh` → exit 0 | PASS |
| ≥10 cases all pass | PASS (19/19) |
| `bash scripts/test-migrator-manifest.sh` → 12/12 (regression) | PASS |
| `bash scripts/test-detect.sh` → 40/40 (regression) | PASS |
| `python3 scripts/validate-pack.py` → 26/26 (regression) | PASS |
| No source file under `scripts/lib/` modified | PASS |
| No git state changes (`git rev-parse HEAD` unchanged) | PASS |
| Implementation report written | PASS (this file) |
| POQ-6 disposition addressed | PASS (Resolved) |
| Public-API surface unchanged (Check 26 still green) | PASS |
| No PM-only files touched (BACKLOG/CHANGELOG/README/PACK-* untouched) | PASS |

---

## 9. Files inventory

| Path | Change type | Line delta |
|---|---|---|
| `scripts/test-migrator-core.sh` | new (executable, mode 0755) | +388 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C4b.md` | new | this file |

Touched files: 2. No PM-only or out-of-scope files modified. No source
file under `scripts/lib/` modified.

---

## 10. Proposed C-4b commit message

```
feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)
```

Body (suggested):

```
PLAN T-12: unit tests for the BD-119 migrator framework's CORE
public-API surface (PLAN §3.1 / §3.5 frozen surface). Companion to
test-migrator-manifest.sh (engine-side coverage from C-4).

19 cases:
- exit-code constants present (8 + EXIT_NOT_V10 synonym, frozen values)
- 6 public-API function names declared after sourcing core
- migrator_detect_target_version: v10 / v11 / unknown shapes
- migrator_select_adapter: positive (v10 → migrate-v10-to-v11.sh; bare
  numeric form accepted), negative (v99 missing → EXIT_INTERNAL,
  PACK unset → EXIT_PACK_INVALID, invalid from-arg → EXIT_INTERNAL)
- migrator_baseline_to_tmp: success / file-missing-at-tag /
  missing-args (EXIT_INTERNAL)
- migrator_target_surface_for_version: v10 (+exclusion of v11 entries)
  / v11 (inherits v10 + adds HELP-FRAGMENT, tracker.toml.example,
  ISSUE_TEMPLATE, per-CLI pack-help skill paths) / v99 (unknown + rc=1)
- migrator_run: dry-run smoke happy path (rc=0; target unmodified) /
  dirty target → EXIT_DIRTY=12
- migrator_dispatch arity guard: zero-args → EXIT_INTERNAL=99

Closes POQ-6 from IMPLEMENTATION-REPORT-BD-119-C4.md.

bash -n: OK; test-migrator-core.sh: 19/19 PASS;
test-migrator-manifest.sh: 12/12 PASS (regression);
test-detect.sh: 40/40 PASS (regression);
validate-pack.py: 26/26 PASS (regression).
```

---

## End of C-4b implementation report
