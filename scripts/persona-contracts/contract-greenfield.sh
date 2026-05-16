#!/usr/bin/env bash
# pack-internal: true  (CI persona contract; not a user-facing verb)
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
# F6: enable nullglob so an empty project-template/skills/ does not leave
# the literal pattern in the array (would otherwise count as a phantom
# entry filtered by `[[ -d ]]` but skews intent). Scoped tightly: enabled
# for the array assignment, disabled immediately afterward to avoid
# changing global glob semantics for the rest of the script.
shopt -s nullglob
skill_dirs=("$PACK_ROOT"/project-template/skills/*/)
shopt -u nullglob
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
        # F6: nullglob hygiene — empty per-CLI extras dir must not yield a
        # literal-pattern phantom entry.
        shopt -s nullglob
        cli_extras_list=("$cli_extras_dir"/*/)
        shopt -u nullglob
        for extra in "${cli_extras_list[@]}"; do
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
#   6. per-entry tree templates  → docs/project/{backlog,implementation-plan,
#                                  changelog}/_rules.md + _intro.md
#                                  (+ _format.md for changelog only —
#                                  project-side asymmetry). BD-166.
#   7. greenfield empty mirrors + → docs/project/{BACKLOG.md,
#      empty seed _toc.md         IMPLEMENTATION-PLAN.md, CHANGELOG.md}
#                                  + docs/project/{backlog,implementation-plan,
#                                  changelog}/_toc.md. BD-166 +
#                                  PACK-REVIEW-BD-166-RETRO MUST finding 2.
s11_files=(
    "docs/pack/HELP-FRAGMENT.md"
    "docs/pack/HELP-FRAGMENT-TRACKER.md"
    "tracker.toml.example"
    "scripts/pack-help.sh"
    "scripts/lib/detect.sh"
    ".claude/skills/pack-help/SKILL.md"
    ".codex/skills/pack-help/SKILL.md"
    ".gemini/commands/pack-help.toml"
    # Sub-stage 6: per-entry canonical templates (BD-166). Project-side
    # asymmetry: changelog HAS _format.md, backlog + implementation-plan
    # do NOT (per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §9.7).
    "docs/project/backlog/_rules.md"
    "docs/project/backlog/_intro.md"
    "docs/project/implementation-plan/_rules.md"
    "docs/project/implementation-plan/_intro.md"
    "docs/project/changelog/_rules.md"
    "docs/project/changelog/_intro.md"
    "docs/project/changelog/_format.md"
    # Sub-stage 7: greenfield empty mirrors at PARENT docs/project/
    # (NOT inside stream subdirs).
    "docs/project/BACKLOG.md"
    "docs/project/IMPLEMENTATION-PLAN.md"
    "docs/project/CHANGELOG.md"
    # Sub-stage 7: empty seed _toc.md files inside each stream subdir
    # (per-stream regenerated by BD-164 toc-regenerate.sh helper).
    "docs/project/backlog/_toc.md"
    "docs/project/implementation-plan/_toc.md"
    "docs/project/changelog/_toc.md"
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

# ── Results ────────────────────────────────────────────────────────────────

printf '\n=== greenfield contract: %d passed, %d failed ===\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
exit 0
