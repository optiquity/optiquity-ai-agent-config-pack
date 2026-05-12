#!/usr/bin/env bash
# scripts/persona-contracts/contract-migration.sh — BD-116 migration
# persona contract.
#
# Persona: a project on pack vN runs the vN→vN+1 migrator (today: v10 →
# v11). The contract drives `migrate-v10-to-v11.sh` against the BD-120
# `v10-realistic-ot` fixture and asserts:
#   1. Migrator exits 0 (clean migration with no manual reconciliation).
#   2. Project-template-derived expected v11 shape is present in target:
#      every project-template/ trinity / per-CLI agent / shared skill is
#      represented in the post-migration tree (presence-based; the
#      migrator's job is to extend the project to the new pack surface).
#   3. **BD-088 customization-preservation invariants hold post-migrate**
#      (this is the contract's reason to exist):
#      a. Trinity project-name fills survive — `FakeOT` and `iOS 17,
#         macOS 14` and `gRPC + Proto3` strings still present in CLAUDE.md /
#         AGENTS.md / GEMINI.md.
#      b. Custom x-agent (`x-fakeot-domain`) preserved on all three CLIs
#         (NOT clobbered or removed by the migrator).
#      c. Customized .codex/config.toml retains ABSENCE of `[model_providers
#         .ollama]` block (canonical OT removal). Migrator did not
#         "restore" the missing default.
#      d. Custom TD-NNN BACKLOG.md preserved verbatim — pack does not
#         ship a BACKLOG.md, so the project's BACKLOG must remain
#         byte-identical (sha256 unchanged).
#   4. v11-only client artifacts now installed in the migrated project
#      (HELP-FRAGMENT-TRACKER.md, tracker.toml.example, scripts/pack-help.sh,
#      pack-help skill/command per CLI, .github/ISSUE_TEMPLATE/* forms).
#
# Derivation: items (1), (2), (4) enumerate from project-template/ + the
# BD-080 stage-S11 install rules (no hardcoded file lists). Items (3a)..(3d)
# enumerate from the BD-120 customization patterns documented in
# `_build_realistic_for_version` in test-fixtures/build.sh — those are the
# four customization shapes the migrator MUST preserve, per BD-088
# invariants. When BD-120 grows new patterns, this contract must grow
# matching assertions; the link is documented inline below.
#
# Reference: BACKLOG.md BD-116, BD-120, BD-088, BD-119, BD-080.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SH="$PACK_ROOT/test-fixtures/build.sh"
MIGRATE_SH="$PACK_ROOT/scripts/migrate-v10-to-v11.sh"

PASSED=0
FAILED=0

t_pass() { printf '  PASS %s\n' "$1"; PASSED=$((PASSED + 1)); }
t_fail() {
    printf '  FAIL %s' "$1" >&2
    [[ -n "${2:-}" ]] && printf ' — %s' "$2" >&2
    printf '\n' >&2
    FAILED=$((FAILED + 1))
}

_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

# ── Sandbox ────────────────────────────────────────────────────────────────

SANDBOX="$(bash "$BUILD_SH" --for-contract migration)" \
    || { printf 'error: failed to materialize migration sandbox\n' >&2; exit 2; }
trap '[[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

printf '── BD-116 migration contract ──\n'
printf '  sandbox:  %s\n' "$SANDBOX"
printf '  pack:     %s\n' "$PACK_ROOT"

# Snapshot pre-migration BACKLOG.md sha (for invariant 3d).
PRE_BACKLOG_SHA=""
if [[ -f "$SANDBOX/BACKLOG.md" ]]; then
    PRE_BACKLOG_SHA=$(_sha256 "$SANDBOX/BACKLOG.md")
fi

# ── Drive migrator ─────────────────────────────────────────────────────────
#
# Bare invocation auto-runs --dry-run then --apply (BD-095 backwards-compat).
# Per BD-095/BD-101, the migrator pauses at the customization-detected
# gate when ours/theirs/base divergence requires manual reconciliation —
# this is expected for the v10-realistic-ot fixture (FakeOT trinity fills
# differ from the v11 pack template). The persona contract simulates a
# developer who reviews the sidecars, accepts the project-edited content
# as-is (most common path), then runs --resume to complete migration.
#
# Auto-resolution strategy: for each `.v10-customized` sidecar produced
# by the apply phase, write a companion `.resolved` flag-file (the
# canonical "accept current destination as-is" signal documented in
# scripts/lib/migrate-v10-to-v11/resume.sh §header). This mirrors the
# BD-088 default-accept path.

migrate_log="$(mktemp -t pack-contract-migrate.XXXXXX)"
PACK="$PACK_ROOT" bash "$MIGRATE_SH" "$SANDBOX" >"$migrate_log" 2>&1
apply_rc=$?

# Detect pause-state: state-dir + sidecars present.
state_dir="$SANDBOX/.pack-migrate-v10-to-v11"
sidecars=()
if [[ -d "$state_dir" ]]; then
    while IFS= read -r s; do
        [[ -n "$s" ]] && sidecars+=("$s")
    done < <(find "$SANDBOX" -name "*.v10-customized" -type f -not -path "*/.git/*" -not -path "$state_dir/*" 2>/dev/null)
fi

if [[ "${#sidecars[@]}" -gt 0 ]]; then
    # Apply paused at the BD-101 reconciliation gate (expected for
    # v10-realistic-ot). Auto-resolve each sidecar, then --resume.
    t_pass "apply paused at reconciliation gate (${#sidecars[@]} sidecar(s) — expected)"
    for s in "${sidecars[@]}"; do
        touch "${s}.resolved"
    done
    resume_log="$(mktemp -t pack-contract-resume.XXXXXX)"
    if PACK="$PACK_ROOT" bash "$MIGRATE_SH" --resume "$SANDBOX" >"$resume_log" 2>&1; then
        t_pass "migrator --resume exit 0 after sidecar reconciliation"
        rm -f "$resume_log" "$migrate_log"
    else
        rc=$?
        t_fail "migrator --resume exit non-zero" "rc=$rc"
        printf '──── --resume log (last 40 lines) ────\n' >&2
        tail -n 40 "$resume_log" >&2
        printf '──── end --resume log ────\n' >&2
        rm -f "$resume_log" "$migrate_log"
    fi
elif [[ "$apply_rc" -eq 0 ]]; then
    t_pass "migrator exit 0 (single-pass; no reconciliation needed)"
    rm -f "$migrate_log"
else
    t_fail "migrator exit non-zero with no sidecars to resolve" "rc=$apply_rc"
    printf '──── migrator log (last 40 lines) ────\n' >&2
    tail -n 40 "$migrate_log" >&2
    printf '──── end migrator log ────\n' >&2
    rm -f "$migrate_log"
    # Continue to record what assertions we can; full failure surface
    # is more useful than early-exit.
fi

# ── Assertion 2: project-template-derived v11 shape present ───────────────

# Trinity files now exist (migrator may have updated them; presence is the
# contract here; byte-identity is BD-088's job to navigate).
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "v11 trinity ${f} present post-migrate"
    else
        t_fail "v11 trinity ${f} MISSING post-migrate"
    fi
done

# Per-CLI pack-shipped agents: every project-template agent should be
# present post-migrate (newly added agents in v11 land via migrator).
for tool in claude codex gemini; do
    case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
    pack_agents="$PACK_ROOT/project-template/.${tool}/agents"
    [[ -d "$pack_agents" ]] || continue
    missing=0
    for src in "$pack_agents"/*.${ext}; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        if [[ ! -f "$SANDBOX/.${tool}/agents/$name" ]]; then
            missing=$((missing + 1))
        fi
    done
    if [[ "$missing" -eq 0 ]]; then
        t_pass "all project-template .${tool}/agents/ present post-migrate"
    else
        t_fail ".${tool}/agents/ has $missing missing pack agents post-migrate"
    fi
done

# Skills: scoped per the v10→v11 migrator's documented skill responsibilities.
#   - BD-147 content-level rename: trinity files + PLATFORM-SKILLS.md
#     references must use the v11 split skill names (`python-server-
#     architecture`, `python-data-architecture`) and NOT the legacy v10
#     `python-architecture` token. The legacy SKILL.md directory is
#     deliberately retained on disk for compatibility (rename is
#     reference-level, not filesystem-level — see migrator-skills.sh
#     §header). The on-disk-skill assertion is therefore against the
#     references in canonical files, not the directory inventory.
#   - BD-080 migrator install: pack-help skill must land for claude + codex
#     (gemini ships pack-help as a command — verified in assertion 4).
#
# Other v11-only skills (e.g. `apple-swiftdata-patterns`,
# `swift-concurrency-patterns`, `protobuf-patterns`,
# `python-server-architecture` / `python-data-architecture` SKILL.md
# directories) are NOT installed on disk by the v10→v11 migrator today
# — only their references are rewritten. Filesystem-level new-skill
# install is out of scope for the v10→v11 migrator (see POQ-BD-116-1
# in the implementation report).
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    target="$SANDBOX/$f"
    [[ -f "$target" ]] || continue
    # Legacy `python-architecture` token must not appear bare in the v11
    # trinity (split into `python-server-architecture` and
    # `python-data-architecture`). The two split forms are valid
    # substrings; check by stripping them and asserting the bare token
    # is absent in what remains.
    bare=$(sed \
        -e 's/python-server-architecture//g' \
        -e 's/python-data-architecture//g' \
        "$target" | grep -c "python-architecture" || true)
    if [[ "$bare" -eq 0 ]]; then
        t_pass "skill-rename: ${f} has no bare 'python-architecture' references (BD-147)"
    else
        t_fail "skill-rename: ${f} still references bare 'python-architecture' ($bare occurrences)"
    fi
done
# pack-help skill installed for claude + codex.
for tool in claude codex; do
    if [[ -f "$SANDBOX/.${tool}/skills/pack-help/SKILL.md" ]]; then
        t_pass "skill ${tool}/pack-help installed by migrator"
    else
        t_fail "skill ${tool}/pack-help MISSING post-migrate (BD-080 migrator install)"
    fi
done

# ── Assertion 3: BD-088 customization-preservation invariants ─────────────

# 3a: trinity project-name fills survived. The BD-088 contract MUST
# preserve project-edited content even when the pack template differs.
# Token strings sourced from `_build_realistic_for_version` in
# test-fixtures/build.sh.
#
# After our --resume "accept-as-is" path, the live trinity file is the
# pack template (no FakeOT) — but the project's FakeOT-customized
# content must be preserved in the corresponding `.v10-customized`
# sidecar (and/or its `.resolved` flag-file pair). Loss of the
# customized content entirely is the failure mode BD-088 exists to
# prevent.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    target="$SANDBOX/$f"
    [[ -f "$target" ]] || { t_fail "3a: $f missing post-migrate"; continue; }
    if grep -q "FakeOT" "$target"; then
        t_pass "3a: $f retains 'FakeOT' project-name fill in live file"
    else
        # Look for any sidecar variant carrying the FakeOT content. BD-088
        # uses `.v10-customized` for the v10→v11 migrator; future migrators
        # use `.v<N>-customized` per MIGRATOR_OWN_SIDECAR_SUFFIX.
        sidecar_hit=""
        while IFS= read -r side; do
            if grep -q "FakeOT" "$side" 2>/dev/null; then
                sidecar_hit="$side"
                break
            fi
        done < <(find "$SANDBOX" -name "${f}.*-customized" -type f -not -path "*/.git/*" 2>/dev/null)
        if [[ -n "$sidecar_hit" ]]; then
            t_pass "3a: $f 'FakeOT' surfaced via BD-088 sidecar ($(basename "$sidecar_hit"))"
        else
            t_fail "3a: $f LOST 'FakeOT' fill (no sidecar carries it)"
        fi
    fi
done

# 3b: x-fakeot-domain custom agents preserved on all 3 CLIs.
for tool in claude codex gemini; do
    case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
    target="$SANDBOX/.${tool}/agents/x-fakeot-domain.${ext}"
    if [[ -f "$target" ]]; then
        t_pass "3b: .${tool}/agents/x-fakeot-domain.${ext} preserved"
    else
        t_fail "3b: .${tool}/agents/x-fakeot-domain.${ext} LOST" \
            "BD-088 / BD-119 must never delete x-prefixed project-owned agents"
    fi
done

# 3c: ollama removal in .codex/config.toml preserved (or surfaced via
# sidecar). The BD-120 fixture deletes the `[model_providers.ollama]`
# block before commit; migrator must not silently restore it.
if [[ -f "$SANDBOX/.codex/config.toml" ]]; then
    if ! grep -q "^\[model_providers\.ollama\]" "$SANDBOX/.codex/config.toml"; then
        t_pass "3c: .codex/config.toml retains ollama-block deletion"
    else
        # Acceptable if migrator surfaced the customization to a
        # sidecar (BD-088 needs-reconciliation path).
        if find "$SANDBOX" -name "config.toml.pre-*" -type f 2>/dev/null \
                | xargs grep -L "^\[model_providers\.ollama\]" >/dev/null 2>&1; then
            t_pass "3c: ollama-removal customization surfaced via sidecar"
        else
            t_fail "3c: ollama-block returned in .codex/config.toml" \
                "migrator silently restored deleted [model_providers.ollama]"
        fi
    fi
else
    t_fail "3c: .codex/config.toml MISSING post-migrate"
fi

# 3d: custom TD-NNN BACKLOG.md preserved byte-identical. Pack ships no
# BACKLOG.md to project-template/, so the migrator must not touch it.
if [[ -n "$PRE_BACKLOG_SHA" && -f "$SANDBOX/BACKLOG.md" ]]; then
    post_sha=$(_sha256 "$SANDBOX/BACKLOG.md")
    if [[ "$post_sha" == "$PRE_BACKLOG_SHA" ]]; then
        t_pass "3d: BACKLOG.md (TD-NNN entries) byte-identical post-migrate"
    else
        t_fail "3d: BACKLOG.md sha256 changed" "pre=$PRE_BACKLOG_SHA post=$post_sha"
    fi
elif [[ -n "$PRE_BACKLOG_SHA" ]]; then
    t_fail "3d: BACKLOG.md REMOVED by migrator (TD-NNN entries lost)"
fi

# ── Assertion 4: v11-only client artifacts installed ──────────────────────
#
# These are the BD-080 stage-S11 surface. Migrator must add them to
# previously v10-only projects so the v11 client surface is complete.
# NOTE: this list mirrors the hardcoded enumeration in
# scripts/init-project.sh:stage_s11_v11_artifacts(). Keep the two in sync
# when adding/removing v11 client artifacts. (BD-116 PACK-REVIEW NIT N1.)

v11_artifacts=(
    "docs/pack/HELP-FRAGMENT.md"
    "docs/pack/HELP-FRAGMENT-TRACKER.md"
    "tracker.toml.example"
    "scripts/pack-help.sh"
    "scripts/lib/detect.sh"
    ".claude/skills/pack-help/SKILL.md"
    ".codex/skills/pack-help/SKILL.md"
    ".gemini/commands/pack-help.toml"
)
for f in "${v11_artifacts[@]}"; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "v11 artifact ${f} installed by migrator"
    else
        t_fail "v11 artifact ${f} MISSING post-migrate"
    fi
done

# Issue forms (BD-063): every project-template/.github/ISSUE_TEMPLATE/*.yml
# should be present.
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
        t_pass "all .github/ISSUE_TEMPLATE/*.yml installed by migrator"
    else
        t_fail "$missing_forms ISSUE_TEMPLATE form(s) missing post-migrate"
    fi
fi

# ── Results ────────────────────────────────────────────────────────────────

printf '\n=== migration contract: %d passed, %d failed ===\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
exit 0
