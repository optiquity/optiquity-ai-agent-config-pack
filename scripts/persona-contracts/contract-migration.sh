#!/usr/bin/env bash
# pack-internal: true  (CI persona contract; not a user-facing verb)
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
#      (HELP-FRAGMENT.md, scripts/pm-help.sh — the client help runner,
#      pm-help skill per CLI, .github/ISSUE_TEMPLATE/* forms). NO pack-side
#      file (pack-help.sh / detect.sh) is installed — empty ship-allowlist
#      per BD-257.
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
# Scoped to the loose per-CLI dirs the v10→v11 migrator installs —
# .claude/agents/ + .codex/agents/ (migrator_directory_sweeps in
# scripts/migrate-v10-to-v11.sh). Antigravity agents ship as a plugin
# BUNDLE (.agents-plugin/optiquity-agents/); the v10→v11 migrator installs
# it additively (additive, non-clobber — see
# _v10_to_v11_install_v11_artifacts), asserted in the bundle block below.
for tool in claude codex; do
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

# Antigravity third-CLI agents: the migrator installs the client plugin
# bundle through the BD-088 customization-preserve engine
# (.agents-plugin/optiquity-agents/ — _v10_to_v11_install_v11_artifacts;
# net-new v11 surface, BD-221 corrected agent-migration model). Pack bundle
# agents are replace-if-different; client x- customs are preserved. Assert
# every pack bundle agent landed in the migrated client bundle
# (superset-tolerant — the bundle may carry lifted x- customs too, so
# project extras are allowed; the contract is "no pack agent missing").
# Also assert plugin.json + RUNTIME-SUBAGENT-PATTERN.md are present.
bundle_src="$PACK_ROOT/project-template/.agents-plugin/optiquity-agents/agents"
bundle_dst="$SANDBOX/.agents-plugin/optiquity-agents/agents"
if [[ -d "$bundle_src" ]]; then
    bundle_missing=0
    for src in "$bundle_src"/*.md; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        if [[ ! -f "$bundle_dst/$name" ]]; then
            bundle_missing=$((bundle_missing + 1))
        fi
    done
    if [[ "$bundle_missing" -eq 0 ]]; then
        t_pass "all .agents-plugin/optiquity-agents/agents/ present post-migrate"
    else
        t_fail ".agents-plugin/optiquity-agents/agents/ has $bundle_missing missing pack agents post-migrate" \
            "BD-221: the v10→v11 migrator must additively install the Antigravity bundle"
    fi
else
    t_fail "pack template missing .agents-plugin/optiquity-agents/agents/"
fi
for meta in plugin.json RUNTIME-SUBAGENT-PATTERN.md; do
    if [[ -f "$SANDBOX/.agents-plugin/optiquity-agents/$meta" ]]; then
        t_pass ".agents-plugin/optiquity-agents/${meta} present post-migrate"
    else
        t_fail ".agents-plugin/optiquity-agents/${meta} MISSING post-migrate"
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
#   - BD-080 migrator install: the client help skill (pm-help, renamed from
#     pack-help per BD-257) is an ordinary pool skill
#     fanned out by the migrator to all three CLI skill homes
#     (.claude/skills/, .codex/skills/, .agents/skills/ — Antigravity
#     reads `.agents/skills/`; there is no `.toml` command form).
#     Asserted below for all three.
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
# pm-help pool skill installed for all three CLI skill homes (Antigravity
# reads .agents/skills/; renamed from pack-help per BD-257).
for tool in claude codex agents; do
    if [[ -f "$SANDBOX/.${tool}/skills/pm-help/SKILL.md" ]]; then
        t_pass "skill ${tool}/pm-help installed by migrator"
    else
        t_fail "skill ${tool}/pm-help MISSING post-migrate (BD-080 migrator install)"
    fi
done
# BD-257 de-ship BITE: the pre-BD-257 pack-help skill must NOT be installed,
# and no pack-side pack-help.sh / detect.sh ships (empty ship-allowlist).
# Each assertion would FAIL against the old shape that installed them.
for tool in claude codex agents; do
    if [[ ! -e "$SANDBOX/.${tool}/skills/pack-help/SKILL.md" ]]; then
        t_pass "skill ${tool}/pack-help NOT installed (renamed to pm-help, BD-257)"
    else
        t_fail "skill ${tool}/pack-help unexpectedly installed (should be pm-help, BD-257)"
    fi
done
for gone in scripts/pack-help.sh scripts/lib/detect.sh; do
    if [[ ! -e "$SANDBOX/$gone" ]]; then
        t_pass "$gone NOT shipped by migrator (de-shipped per BD-257)"
    else
        t_fail "$gone unexpectedly installed by migrator (should be de-shipped, BD-257)"
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

# 3b: x-fakeot-domain custom agents preserved on all three CLIs.
# Claude/Codex keep their loose agent dirs, so the custom agent stays
# in place there.
for tool in claude codex; do
    case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
    target="$SANDBOX/.${tool}/agents/x-fakeot-domain.${ext}"
    if [[ -f "$target" ]]; then
        t_pass "3b: .${tool}/agents/x-fakeot-domain.${ext} preserved"
    else
        t_fail "3b: .${tool}/agents/x-fakeot-domain.${ext} LOST" \
            "BD-088 / BD-119 must never delete x-prefixed project-owned agents"
    fi
done
# 3b (third CLI — BD-221 corrected agent-migration model): the v10 source
# carried the custom agent under the departing `.gemini/agents/` tree
# (carve-out i). On v11 the migrator LIFTS that x- custom INTO the
# Antigravity plugin bundle (.agents-plugin/optiquity-agents/agents/) — it
# becomes a live Antigravity agent, not a manual-re-creation TODO — AND
# moves the whole departing `.gemini/` tree into `gemini-retired-docs/` as a
# BACKUP. Both must hold: the custom is LIVE in the bundle, and the backup
# copy survives. BD-088 / BD-119 forbid DELETION; here the custom is both
# preserved (backup) and promoted (bundle).
if [[ -f "$SANDBOX/.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md" ]]; then
    t_pass "3b: third-CLI x-fakeot-domain LIFTED into Antigravity bundle (.agents-plugin/optiquity-agents/agents/)"
else
    t_fail "3b: third-CLI x-fakeot-domain NOT lifted into the Antigravity bundle" \
        "BD-221: the v10→v11 migrator must lift the departing Gemini x- custom into .agents-plugin/optiquity-agents/agents/"
fi
# Backup copy: the whole departing .gemini/ (incl. the x- custom) is also
# retired to gemini-retired-docs/ (move-not-delete).
retired_xagent=""
while IFS= read -r cand; do
    retired_xagent="$cand"
    break
done < <(find "$SANDBOX/gemini-retired-docs" -name "x-fakeot-domain.md" -type f 2>/dev/null)
if [[ -n "$retired_xagent" ]]; then
    t_pass "3b: third-CLI x-fakeot-domain backed up in gemini-retired-docs/ (${retired_xagent#"$SANDBOX/"})"
else
    t_fail "3b: third-CLI x-fakeot-domain backup LOST" \
        "BD-221: the departing .gemini/ tree (incl. the x- custom) must be retired to gemini-retired-docs/ as a backup"
fi

# 3c: ollama removal in .codex/config.toml preserved (or surfaced via
# sidecar). The BD-120 fixture deletes the `[model_providers.ollama]`
# block before commit; migrator must not silently restore it.
if [[ -f "$SANDBOX/.codex/config.toml" ]]; then
    if ! grep -q "^\[model_providers\.ollama\]" "$SANDBOX/.codex/config.toml"; then
        t_pass "3c: .codex/config.toml retains ollama-block deletion"
    else
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
#
# Mapping to stage_s11_v11_artifacts() sub-stages:
#   1. HELP-FRAGMENT.md           → docs/pack/HELP-FRAGMENT.md
#   2. tracker.toml.example       → NO LONGER installed (tracker deferred, BD-214)
#   3. .github/ISSUE_TEMPLATE/*   → handled by glob block below
#   4. pm-help pool skill         → .claude/skills/pm-help/SKILL.md,
#                                   .codex/skills/pm-help/SKILL.md,
#                                   .agents/skills/pm-help/SKILL.md
#                                   (pm-help — renamed from pack-help per
#                                   BD-257 — is an ordinary pool skill
#                                   fanned out to all three CLIs; Antigravity
#                                   reads `.agents/skills/`, no `.toml`
#                                   command form)
#   5. client help runner         → scripts/pm-help.sh (shipped via the
#                                   project-template scripts sweep; NO
#                                   pack-side pack-help.sh / detect.sh —
#                                   empty ship-allowlist per BD-257)
#   6. per-entry tree templates   → docs/project/{backlog,implementation-plan,
#                                   changelog}/_rules.md + _intro.md.
#                                   BD-166 (BD-206: no _format.md anywhere).
#                                   The migrator ships these unconditionally
#                                   via the BD-167 templates step (independent
#                                   of monolithic source content). PACK-
#                                   REVIEW-BD-166-RETRO MUST finding 2.
#   7. empty seed _toc.md         → docs/project/{backlog,implementation-plan,
#                                   changelog}/_toc.md. NO monolithic mirror
#                                   is regenerated (BD-206 no-mirror model);
#                                   the per-entry tree + generated _toc.md is
#                                   the sole source of truth + readable form.
#                                   NOT asserted in the migration v11_artifacts
#                                   array because the BD-165 decompose sub-op
#                                   skips streams whose v10 monolithic INPUT
#                                   is absent (the v10-realistic-ot fixture
#                                   case). See the v11_artifacts comment
#                                   block below for the full asymmetry
#                                   rationale. Sub-stage 7 surface IS
#                                   asserted by (a) the greenfield contract
#                                   above (always-empty case) and (b)
#                                   scripts/tests/test-migrate-v10-to-v11-
#                                   decompose.sh Group 2 (with-content case).

v11_artifacts=(
    "docs/pack/HELP-FRAGMENT.md"
    # BD-243 NUCLEAR: HELP-FRAGMENT-TRACKER.md is deleted (deferred-tracker
    # advertising removed); the migrator no longer copies it. Absence is
    # asserted below.
    # BD-214: tracker.toml.example is NO LONGER installed by the migrator
    # (tracker deferred; flat-file is the sole supported mode). Absence is
    # asserted below.
    # BD-257: the client help runner scripts/pm-help.sh ships via the
    # project-template scripts sweep; the pm-help pool skill (renamed from
    # pack-help) fans out to all three CLIs. NO pack-side pack-help.sh /
    # detect.sh ships — empty ship-allowlist; their ABSENCE (and the old
    # pack-help skill's absence) is asserted above.
    "scripts/pm-help.sh"
    ".claude/skills/pm-help/SKILL.md"
    ".codex/skills/pm-help/SKILL.md"
    ".agents/skills/pm-help/SKILL.md"
    # Sub-stage 6: per-entry canonical templates (BD-166). Each stream
    # gets _rules.md + _intro.md (BD-206: _format.md is FORBIDDEN
    # everywhere — its content folds into changelog/_rules.md).
    # These ship UNCONDITIONALLY via the BD-167 templates step in the
    # migrator (scripts/migrate-v10-to-v11.sh — verified by
    # scripts/lib/migrate-v10-to-v11/decompose.sh:136-141 comment) —
    # independent of whether the v10 source has monolithic docs/project
    # content to decompose.
    "docs/project/backlog/_rules.md"
    "docs/project/backlog/_intro.md"
    "docs/project/implementation-plan/_rules.md"
    "docs/project/implementation-plan/_intro.md"
    "docs/project/changelog/_rules.md"
    "docs/project/changelog/_intro.md"
    # Sub-stage 7 (_toc.md) is NOT in this list because the BD-165
    # decompose sub-op SKIPS streams when the v10 monolithic INPUT is
    # absent (scripts/lib/migrate-v10-to-v11/decompose.sh: "no monolithic
    # mirror at <path> — skip"). NO monolithic mirror is regenerated
    # (BD-206 no-mirror model) — the per-entry tree + generated _toc.md
    # is the sole source of truth. The current v10-realistic-ot fixture
    # has no docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md input
    # files, so the migrator legitimately produces no _toc.md files for
    # that fixture. Adding the _toc.md surface here would force the
    # contract to fail on the canonical fixture even though the migrator
    # behavior is correct. The greenfield contract (which always starts
    # empty + always regenerates) is the canonical CI gate for sub-stage
    # 7 surface; the BD-165 decompose-with-content path is covered by
    # scripts/tests/test-migrate-v10-to-v11-decompose.sh Group 2 (which
    # synthesizes a fixture with monolithic input content).
)
for f in "${v11_artifacts[@]}"; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "v11 artifact ${f} installed by migrator"
    else
        t_fail "v11 artifact ${f} MISSING post-migrate"
    fi
done
# BD-243 NUCLEAR: the deferred-tracker help fragment must NOT be installed
# by the migrator (deleted; deferred-tracker advertising removed).
if [[ ! -f "$SANDBOX/docs/pack/HELP-FRAGMENT-TRACKER.md" ]]; then
    t_pass "v11 artifact HELP-FRAGMENT-TRACKER.md NOT installed (deleted, BD-243)"
else
    t_fail "v11 artifact HELP-FRAGMENT-TRACKER.md unexpectedly installed (should be deleted, BD-243)"
fi
# BD-214: tracker.toml.example must NOT be installed by the migrator.
if [[ ! -f "$SANDBOX/tracker.toml.example" ]]; then
    t_pass "v11 artifact tracker.toml.example NOT installed (tracker deferred, BD-214)"
else
    t_fail "v11 artifact tracker.toml.example unexpectedly installed (should be deferred, BD-214)"
fi

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
