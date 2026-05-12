#!/usr/bin/env bash
# scripts/persona-contracts/contract-greenfield.sh — BD-116 greenfield
# persona contract.
#
# Persona: a developer with an empty git repo runs `init-project.sh`.
# Asserts that the resulting install matches what `project-template/` and
# the install rules say should be there. No hand-written file lists; every
# expectation is derived from `project-template/` itself, so when the
# template grows or shrinks for v12 the contract auto-evolves.
#
# Derivation logic (per BD-116):
#   1. For every `project-template/skills/<name>/SKILL.md`, assert
#      `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`,
#      and `.gemini/skills/<name>/SKILL.md` are present in the install.
#      (init-project.sh stage S4 distributes one SKILL.md per CLI.)
#   2. For every `project-template/.claude/agents/*.md`, assert a copy
#      under the install's `.claude/agents/`. Same shape for
#      `project-template/.codex/agents/*.toml` → `.codex/agents/` and
#      `project-template/.gemini/agents/*.md` → `.gemini/agents/`.
#      (Stage S2.)
#   3. Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md) byte-identical to
#      `project-template/` originals (greenfield path uses `cp`, not the
#      existing-classifier fork). Stage S7.
#   4. Stage S11 client artifacts present:
#      docs/pack/HELP-FRAGMENT.md, docs/pack/HELP-FRAGMENT-TRACKER.md,
#      tracker.toml.example, scripts/pack-help.sh (executable),
#      scripts/lib/detect.sh, .claude/skills/pack-help/SKILL.md,
#      .codex/skills/pack-help/SKILL.md, .gemini/commands/pack-help.toml.
#   5. agent-run.sh present and executable (stage S5).
#
# Exit 0 = contract holds. Non-zero = at least one assertion failed; each
# failure is printed to stderr.
#
# Reference: BACKLOG.md BD-116, BD-088, BD-115, BD-120.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SH="$PACK_ROOT/test-fixtures/build.sh"
INIT_SH="$PACK_ROOT/scripts/init-project.sh"

PASSED=0
FAILED=0

t_pass() { printf '  PASS %s\n' "$1"; PASSED=$((PASSED + 1)); }
t_fail() {
    printf '  FAIL %s' "$1" >&2
    [[ -n "${2:-}" ]] && printf ' — %s' "$2" >&2
    printf '\n' >&2
    FAILED=$((FAILED + 1))
}

# ── Sandbox ────────────────────────────────────────────────────────────────

SANDBOX="$(bash "$BUILD_SH" --for-contract greenfield)" \
    || { printf 'error: failed to materialize greenfield sandbox\n' >&2; exit 2; }
trap '[[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

printf '── BD-116 greenfield contract ──\n'
printf '  sandbox:  %s\n' "$SANDBOX"
printf '  pack:     %s\n' "$PACK_ROOT"

# ── Drive init-project.sh ──────────────────────────────────────────────────

if ! PACK="$PACK_ROOT" bash "$INIT_SH" "$SANDBOX" >/dev/null 2>&1 <<<"y"; then
    printf 'error: init-project.sh exited non-zero on greenfield sandbox\n' >&2
    exit 3
fi

# ── Derived assertions ─────────────────────────────────────────────────────

# Assertion 1: every project-template skill present in all three CLIs.
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
expected_skill_count=0
for d in "${skill_dirs[@]}"; do
    [[ -d "$d" ]] || continue
    expected_skill_count=$((expected_skill_count + 1))
    name=$(basename "$d")
    for tool in claude codex gemini; do
        target="$SANDBOX/.${tool}/skills/$name/SKILL.md"
        if [[ -f "$target" ]]; then
            t_pass "skill ${tool}/${name}/SKILL.md present"
        else
            t_fail "skill ${tool}/${name}/SKILL.md MISSING"
        fi
    done
done
# Sanity: every CLI's skill dir count matches expected. Per-CLI extras are
# derived from project-template/.${tool}/skills/ (pack-help + pm-startup
# under claude/codex; gemini ships pack-help as a command, not a skill —
# see project-template/.gemini/commands/pack-help.toml). pm-startup is
# also in the shared `project-template/skills/` tree (S4 distributes it
# to all three CLIs); skills that appear in BOTH the per-CLI extras dir
# AND the shared skills tree count once (the per-CLI copy overwrites or
# is overwritten by S4 — same name == same slot). Expected count is
# therefore the union: shared + CLI-specific minus overlap.
for tool in claude codex gemini; do
    actual=$(find "$SANDBOX/.${tool}/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    cli_extras_dir="$PACK_ROOT/project-template/.${tool}/skills"
    expected_unique="$expected_skill_count"
    if [[ -d "$cli_extras_dir" ]]; then
        for extra in "$cli_extras_dir"/*/; do
            [[ -d "$extra" ]] || continue
            extra_name=$(basename "$extra")
            # Add only if NOT already in shared project-template/skills/.
            if [[ ! -d "$PACK_ROOT/project-template/skills/$extra_name" ]]; then
                expected_unique=$((expected_unique + 1))
            fi
        done
    fi
    if [[ "$actual" -eq "$expected_unique" ]]; then
        t_pass "${tool}/skills/ has expected count ($actual)"
    else
        t_fail "${tool}/skills/ count mismatch" "expected $expected_unique got $actual"
    fi
done

# Assertion 2: every project-template agent present per CLI.
for tool in claude codex gemini; do
    case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
    pack_agents="$PACK_ROOT/project-template/.${tool}/agents"
    [[ -d "$pack_agents" ]] || { t_fail "pack template missing .${tool}/agents/"; continue; }
    for src in "$pack_agents"/*.${ext}; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        target="$SANDBOX/.${tool}/agents/$name"
        if [[ -f "$target" ]]; then
            t_pass "agent ${tool}/${name} present"
        else
            t_fail "agent ${tool}/${name} MISSING"
        fi
    done
done

# Assertion 3: trinity files byte-identical to project-template/.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    src="$PACK_ROOT/project-template/$f"
    dst="$SANDBOX/$f"
    if [[ ! -f "$dst" ]]; then
        t_fail "trinity ${f} MISSING"
        continue
    fi
    if cmp -s "$src" "$dst"; then
        t_pass "trinity ${f} byte-identical to project-template"
    else
        t_fail "trinity ${f} differs from project-template"
    fi
done

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
for f in "${s11_files[@]}"; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "S11 artifact ${f} present"
    else
        t_fail "S11 artifact ${f} MISSING"
    fi
done
# pack-help.sh executable.
if [[ -x "$SANDBOX/scripts/pack-help.sh" ]]; then
    t_pass "scripts/pack-help.sh executable"
else
    t_fail "scripts/pack-help.sh not executable"
fi

# Assertion 5: agent-run.sh present and executable.
if [[ -x "$SANDBOX/agent-run.sh" ]]; then
    t_pass "agent-run.sh present and executable"
else
    t_fail "agent-run.sh missing or not executable"
fi

# ── Results ────────────────────────────────────────────────────────────────

printf '\n=== greenfield contract: %d passed, %d failed ===\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
exit 0
