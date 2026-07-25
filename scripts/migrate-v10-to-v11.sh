#!/usr/bin/env bash
# migrate-v10-to-v11.sh — v10 → v11 migrator. Adapter against migrator-core.sh.
#
# This is a thin per-version adapter on the BD-119 migrator framework
# (`scripts/lib/migrator-core.sh` + `migrator-stages.sh` +
# `migrator-manifest.sh`). All shared safety concerns — preflight, backup,
# state-dir hygiene, three-way dispatch via BD-088, report rendering,
# exit codes — live in the framework. This file declares only what is
# v10→v11-specific.
#
# Replaces the pre-BD-119 monolith (refactor at BD-119 C-6).
#
# Design rationale, contract, and adapter-authoring rules:
#   maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
# Implementation plan + verification recipe:
#   maintenance-docs/v11-implementation/PLAN-BD-119.md
# A future migrate-v11-to-v12.sh is the same shape as this file: declare
# the MIGRATOR_* contract + the small set of hook functions, then source
# the framework and call migrator_run "$@".
#
# Architectural note on hook usage:
#
# The v10→v11 transition's post-dispatch work (BD-042 legacy-doc
# relocation; additive install of v11 artifacts like HELP-FRAGMENT,
# ISSUE_TEMPLATE forms, the pool-distributed pm-help skill (the client
# help runner scripts/pm-help.sh is a project-template/scripts/ file that
# ships via the directory sweep — NO pack-side file is copied to clients,
# no dual-use per BD-257); the Antigravity
# agent plugin bundle installed REPLACE-IF-DIFFERENT through the BD-088
# customization-preserve engine — BD-221 corrected agent-migration model;
# the lift of departing Gemini x- custom agents INTO that bundle; and the
# Gemini→Antigravity client-tree retirement to gemini-retired-docs/) is
# performed (tracker.toml.example is NO LONGER installed — tracker deferred,
# BD-214) inside `migrator_post_dispatch_hook` rather than via the
# framework's declarative `migrator_relocations` /
# `migrator_artifact_installs` hooks. Two reasons:
#   1. The pre-BD-119 monolith printed v10→v11-specific banners
#      ("── S4 — BD-042 relocation of legacy root docs (if any) ──",
#      "── S5 — install v11 client artifacts ──") and never recorded
#      additive installs into the BD-088 dispositions TSV. The
#      behavior-preservation harness (PLAN-BD-119.md §8) gates C-6 on
#      byte-equivalent stdout + report.md, which means the adapter
#      reproduces that wording and that no-record semantics exactly.
#   2. The framework's declarative hooks correctly record dispositions
#      (architecture §4.3, structural payoff M9). For a future v11→v12
#      adapter, using the declarative hooks is the right call. v10→v11
#      stays on `migrator_post_dispatch_hook` for backward compatibility.
#
# Usage:
#     PACK=/path/to/pack ./scripts/migrate-v10-to-v11.sh [target-dir] [mode-flag]
#
# Modes (BD-095 two-phase workflow):
#     --dry-run   Preview only; writes report + dispositions + a fingerprint
#                 the apply mode will check. No project files are mutated.
#     --apply     Default. Refuses to run unless a fresh (<24h) dry-run
#                 fingerprint exists for the current working tree (§6.G).
#                 Pauses cleanly before S4 if dispatch produces sidecars
#                 the user must reconcile.
#     --resume    Continues a paused --apply after sidecar reconciliation.
#                 Forward-only (§6.H). Accepts both `.resolved` flag-files
#                 AND extension removal as conflict-resolution signals.
#     <bare>      Backwards-compat: equivalent to --apply, BUT auto-runs
#                 --dry-run first if no fresh dry-run output exists. Users
#                 of pre-BD-095 invocations do not need to learn the new
#                 flags for the no-conflict path.
#
# Exit codes are inherited from the framework
# (`scripts/lib/migrator-core.sh`). The pre-refactor `EXIT_NOT_V10=13` is
# preserved as a synonym of `EXIT_NOT_BASELINE=13` per
# ARCHITECTURE-BD-119.md §C1 / PLAN §3.5.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Adapter-declared contract (read by migrator-core.sh) ───────────────────

MIGRATOR_FROM_VERSION="v10"
MIGRATOR_TO_VERSION="v11"
MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"
MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
# Prior-version sidecar suffixes the framework's preflight refuses to
# coexist with. Mirrors the monolith's stale-sidecar refusal at lines
# 99–108 (only `.pre-update`, the suffix `init-project.sh --update` writes).
MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")

# ── Hooks ──────────────────────────────────────────────────────────────────

# migrator_manifest — TSV of per-file v10→v11 transformations. Mirrors the
# monolith's S3 explicit-entry list (lines 185–200). One row per file:
#     <pack-relpath>\t<project-relpath>\t<class>\t<action>
# Trinity files (CLAUDE / AGENTS / GEMINI) ship with identical class +
# action so the framework's I5 trinity-parity validator succeeds.
migrator_manifest() {
    cat <<'EOF'
project-template/CLAUDE.md	CLAUDE.md	trinity	transform
project-template/AGENTS.md	AGENTS.md	trinity	transform
project-template/GEMINI.md	GEMINI.md	trinity	transform
project-template/.claude/settings.json	.claude/settings.json	claude-settings	transform
project-template/.codex/config.toml	.codex/config.toml	codex-config	transform
project-template/.codex/config.toml.example	.codex/config.toml.example	codex-config-example	transform
project-template/.codex/requirements.toml	.codex/requirements.toml	codex-config	transform
project-template/.mcp.json.example	.mcp.json	claude-mcp-example	transform
project-template/.agents/mcp_config.json.example	.agents/mcp_config.json	mcp-config-json	transform
project-template/docs/pack/PM-CHAT.md	docs/pack/PM-CHAT.md	pm-chat	transform
project-template/docs/pack/PLATFORM-SKILLS.md	docs/pack/PLATFORM-SKILLS.md	generic	transform
project-template/docs/pack/PACK-FEEDBACK.md	docs/pack/PACK-FEEDBACK.md	generic	transform
project-template/docs/pack/PROMPT-TEMPLATES.md	docs/pack/PROMPT-TEMPLATES.md	generic	transform
EOF
}

# migrator_directory_sweeps — `<pack-dir> <class>` rows for whole-directory
# iteration. Mirrors the monolith's S3 _stage_s3_iter_dir invocations at
# lines 226–231 (one for `scripts/`, two for the Claude/Codex loose
# agents/ dirs — Antigravity agents ship as a plugin bundle, not a
# loose per-CLI dir, so they are not directory-swept here).
migrator_directory_sweeps() {
    cat <<'EOF'
project-template/scripts pack-script
project-template/.claude/agents pack-agent
project-template/.codex/agents pack-agent
EOF
}

# migrator_relocations — empty. The v10→v11 BD-042 legacy-doc relocation
# is performed inside migrator_post_dispatch_hook with monolith-faithful
# wording (see the architectural note at the top of this file).
migrator_relocations() { :; }

# migrator_artifact_installs — empty. The v11-specific additive installs
# are performed inside migrator_post_dispatch_hook with monolith-faithful
# silent (no-record) semantics (see the architectural note).
migrator_artifact_installs() { :; }

# migrator_post_dispatch_hook — runs between the framework's S3 dispatch
# and S4 relocations stages. We use this hook to perform both S4 and S5
# in a single unit so the adapter retains the exact stdout + report.md
# shape the pre-refactor monolith produced.
migrator_post_dispatch_hook() {
    # In --dry-run mode the framework's stage helpers short-circuit
    # writes; the adapter's hook must do the same so BD-095 can rely on
    # a true dry-run for the fingerprint comparator. The pre-BD-095
    # invariant (single-shot only) made this gate unnecessary; with
    # BD-095 the gate is required.
    if _migrator_is_dryrun; then
        info "[dry-run] would run rename + relocation + v11 artifact install (incl. Antigravity agent bundle, replace-if-different) + lift Gemini x- customs into the Antigravity bundle + Gemini→Antigravity retirement + python-architecture skill rename + capability-token translation + per-entry decompose"
        return 0
    fi
    _v10_to_v11_rename_implementation_plan
    _v10_to_v11_relocate_legacy_docs
    _v10_to_v11_install_v11_artifacts
    # BD-221 corrected agent-migration model: lift the departing Gemini x-
    # custom agents INTO the Antigravity bundle BEFORE the .gemini/ tree is
    # retired (so the customs become live Antigravity agents, not holding-dir
    # backups requiring manual re-creation).
    _v10_to_v11_lift_gemini_customs_to_bundle
    _v10_to_v11_retire_gemini
    _v10_to_v11_rename_python_architecture_refs
    _v10_to_v11_translate_capability_tokens
    # BD-165 (per-entry split, mandatory v11.0): 6th sub-op decomposes
    # the just-installed v11-shape monolithic project-side files
    # (BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md) into the
    # per-entry trees under docs/project/<stream>/ + regenerated
    # mirrors + regenerated TOCs.
    #
    # Sequencing constraint per
    # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.1 / §9.6: this
    # MUST run AFTER all 5 prior sub-ops so the decompose step reads
    # the FINAL v11-shape monolithic content (post BD-104 rename, post
    # BD-042 relocation, post v11 artifact install incl. BD-167
    # canonical templates, post python-architecture skill rename, post
    # BD-144 capability-token translation). Anything that decomposed
    # BEFORE one of those upstream mutations would produce per-entry
    # files not reflecting the final v11 content.
    _v10_to_v11_decompose_streams
}

# Internal: BD-104 cross-pack rename of the client's IMPLEMENTATION_PLAN.md
# (underscore form) to IMPLEMENTATION-PLAN.md (hyphenated form). v11
# adopts the hyphenated all-caps convention for project state docs; the
# rename happens once, history-preserving, on every v10→v11 migration.
#
# Behavior:
#   - No-op if the source file does not exist (project never had one,
#     or the project-side adoption already happened out-of-band).
#   - Collision case (both old and new names present at the target root):
#     surface the typed error `migration-rename-collision` per BD-070 /
#     ARCHITECTURE.md §2.5 contract format (ERROR/MESSAGE/→ Run lines
#     to stderr) and fail the stage. The user resolves by inspecting
#     both files and deleting / merging before re-running.
#   - Tracked source: `git mv` (history-preserving). Untracked source
#     fallback: plain `mv` (matches the BD-042 _v10_to_v11_relocate_legacy_docs
#     pattern at lines 142–147 above).
_v10_to_v11_rename_implementation_plan() {
    # BD-139 F-3: sub-banner "S4a (rename)" disambiguates from the
    # BD-042 relocation that also runs inside migrator_post_dispatch_hook.
    # The fail_stage call still uses "S4" so the BD-095 sentinel filename
    # (`stage-S4.done`) and the framework exit-code formula (24 = 20+4)
    # remain stable; the failure-message prefix carries the sub-stage tag
    # ("S4a-rename: ...") so operators can tell rename vs. relocate apart
    # in a fail_stage report.
    say "── S4a (rename) — rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──"
    local src="$_MIGRATOR_TARGET/IMPLEMENTATION_PLAN.md"
    local dst="$_MIGRATOR_TARGET/IMPLEMENTATION-PLAN.md"
    if [[ ! -f "$src" ]]; then
        info "no IMPLEMENTATION_PLAN.md at target root — nothing to rename"
        return 0
    fi
    if [[ -f "$dst" ]]; then
        # Typed-error block per BD-070 / tracker-errors.sh format. Emitted
        # directly here rather than via tracker_error_emit because the
        # `migration-rename-collision` code is migrator-scoped, not part
        # of the tracker provider's V1 §2.5 ten-code surface.
        {
            printf 'ERROR: %s\n' "migration-rename-collision"
            printf 'MESSAGE: %s\n' \
                "both IMPLEMENTATION_PLAN.md and IMPLEMENTATION-PLAN.md exist at $_MIGRATOR_TARGET"
            printf '%s\n' \
                "  source: $src" \
                "  target: $dst" \
                "v11 expects only IMPLEMENTATION-PLAN.md (hyphenated). Inspect both" \
                "files; delete or merge whichever is stale; then re-run the migration."
            printf '→ Run: %s\n' "inspect both files, resolve, then re-run migrate-v10-to-v11.sh"
        } >&2
        fail_stage S4 "S4a-rename: collision: $dst already exists"
    fi
    local mv_stderr
    mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "IMPLEMENTATION_PLAN.md" "IMPLEMENTATION-PLAN.md" 2>&1) || {
        if [[ "$mv_stderr" == *"not under version control"* \
           || "$mv_stderr" == *"did not match"* ]]; then
            # BD-139 F-4: surface the captured git-mv stderr so operators
            # can distinguish the two fallback-trigger sentinels (and any
            # third-class git-mv message that happens to match either
            # substring) when diagnosing why the fallback fired.
            info "git mv hint (taking untracked-fallback branch): $mv_stderr"
            mv "$src" "$dst"
            info "renamed (untracked): IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
            return 0
        else
            fail_stage S4 "S4a-rename: git mv IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md failed: $mv_stderr"
        fi
    }
    [[ -f "$dst" ]] \
        || fail_stage S4 "S4a-rename: post-rename verification failed: IMPLEMENTATION-PLAN.md missing"
    info "renamed: IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
}

# Internal: BD-042 relocation of legacy v9-era root docs to docs/pack/.
# Mirrors monolith stage_s4_bd042_relocation (lines 261–301). git-mv
# first, plain `mv` fallback for untracked sources, sidecar-the-root
# branch when both root and docs/pack/ have the file. The framework's
# `say`/`info`/`fail_stage` helpers are inherited from migrator-core.sh.
_v10_to_v11_relocate_legacy_docs() {
    # BD-139 F-3: sub-banner "S4b (relocate)" disambiguates from the
    # BD-104 rename above. fail_stage call still uses "S4" so the
    # BD-095 sentinel filename and exit-code formula stay stable.
    say "── S4b (relocate) — relocation of legacy root docs (if any) ──"
    local moved=0
    local f
    for f in METHODOLOGY.md PROMPT-TEMPLATES.md PM-CHAT.md \
             PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
        if [[ -f "$_MIGRATOR_TARGET/$f" ]]; then
            mkdir -p "$_MIGRATOR_TARGET/docs/pack"
            if [[ -f "$_MIGRATOR_TARGET/docs/pack/$f" ]]; then
                mv "$_MIGRATOR_TARGET/$f" \
                   "$_MIGRATOR_TARGET/$f.relocated-from-root"
                info "relocated: $f → $f.relocated-from-root (docs/pack/$f already present)"
            else
                local mv_stderr untracked=0
                mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$f" "docs/pack/$f" 2>&1) || {
                    if [[ "$mv_stderr" == *"not under version control"* \
                       || "$mv_stderr" == *"did not match"* ]]; then
                        mv "$_MIGRATOR_TARGET/$f" "$_MIGRATOR_TARGET/docs/pack/$f"
                        untracked=1
                    else
                        fail_stage S4 "S4b-relocate: git mv $f → docs/pack/$f failed: $mv_stderr"
                    fi
                }
                [[ -f "$_MIGRATOR_TARGET/docs/pack/$f" ]] \
                    || fail_stage S4 "S4b-relocate: post-relocation verification failed: docs/pack/$f missing"
                if (( untracked == 1 )); then
                    info "relocated (untracked): $f → docs/pack/$f"
                else
                    info "relocated: $f → docs/pack/$f"
                fi
            fi
            moved=$((moved + 1))
        fi
    done
    info "relocation: $moved legacy doc(s) moved"
}

# Internal: v11 artifact install. Mirrors monolith stage_s5_v11_artifacts
# (lines 305–370). Plain `cp` with no BD-088 disposition record so the
# behavior-preservation harness's report.md A3 axis stays clean (the
# pre-refactor monolith never recorded these).
_v10_to_v11_install_v11_artifacts() {
    say "── S5 — install v11 client artifacts ──"

    # HELP-FRAGMENT.md
    mkdir -p "$_MIGRATOR_TARGET/docs/pack"
    local help_src
    for help_src in HELP-FRAGMENT.md; do
        local pack_file="$PACK/project-template/docs/pack/$help_src"
        if [[ -f "$pack_file" && ! -f "$_MIGRATOR_TARGET/docs/pack/$help_src" ]]; then
            cp "$pack_file" "$_MIGRATOR_TARGET/docs/pack/$help_src"
        fi
    done

    # tracker.toml.example — NO LONGER INSTALLED (BD-214, 2026-06-13).
    #   Tracker integration is deferred indefinitely and flat-file
    #   per-entry is the sole supported mode, so the v10→v11 migrator no
    #   longer lays down the flip-material config template (design D-C).
    #   The dormant config record stays committed pack-side at
    #   project-template/tracker.toml.project-example for a future resumption.

    # .github/ISSUE_TEMPLATE/*
    if [[ -d "$PACK/project-template/.github/ISSUE_TEMPLATE" ]]; then
        mkdir -p "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE"
        local form
        for form in "$PACK/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
            [[ -e "$form" ]] || continue
            local name; name=$(basename "$form")
            [[ -f "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE/$name" ]] && continue
            cp "$form" "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE/$name"
        done
    fi

    # pm-help is a pooled SSOT skill distributed LOOSE to each CLI's
    # workspace skill dir (.claude/.codex/.agents — Antigravity reads
    # `.agents/skills/`), matching the net-new skill fan-out below. The
    # pool `project-template/skills/pm-help/SKILL.md` is fanned out here,
    # iff the destination is absent (additive, no overwrite of project
    # edits). The client help RUNNER `scripts/pm-help.sh` is an ordinary
    # `project-template/scripts/` file that ships via the
    # `project-template/scripts` directory sweep — NO pack-side file
    # (pack-help.sh / lib/detect.sh) is copied into the client here:
    # no dual-use, and the ship-allowlist is empty per BD-257
    # (dependency-direction-placement conjunct (c)).
    if [[ -f "$PACK/project-template/skills/pm-help/SKILL.md" ]]; then
        local ph_cli
        for ph_cli in .claude .codex .agents; do
            if [[ ! -f "$_MIGRATOR_TARGET/$ph_cli/skills/pm-help/SKILL.md" ]]; then
                mkdir -p "$_MIGRATOR_TARGET/$ph_cli/skills/pm-help"
                cp "$PACK/project-template/skills/pm-help/SKILL.md" \
                    "$_MIGRATOR_TARGET/$ph_cli/skills/pm-help/SKILL.md"
            fi
        done
    fi

    # Antigravity agent plugin BUNDLE — net-new v11 surface (BD-221). v11
    # ships the third-CLI agents as a plugin bundle at
    # project-template/.agents-plugin/optiquity-agents/ (16 agents/*.md +
    # plugin.json + RUNTIME-SUBAGENT-PATTERN.md).
    #
    # CORRECTED agent-migration model (BD-221, supersedes C7): the bundle
    # installs through the SAME BD-088 customization-preserve engine the
    # loose .claude/.codex/agents/ surfaces use, NOT a hand-rolled
    # non-clobber cp. The engine gives the frozen contract:
    #   - a pack bundle agent is REPLACE-IF-DIFFERENT (a config-pack bump
    #     CAN update pack agents — so an older client copy is replaced when
    #     the v11 pack version differs, cmp -s byte-identity);
    #   - a client x- custom agent already in the bundle is PRESERVED
    #     (never overwritten), via the .agents-plugin/*/agents/x-* →
    #     custom-agent classifier leg added in customization-preserve.sh.
    # Self-classify (NO forced class arg) so each bundle file gets the
    # right class per the corrected classifier legs. Base is "" — the
    # bundle is a net-new v11 surface with no v10 baseline (the v10 tag has
    # no .agents-plugin/ path); on a v10→v11 migration `ours` is absent so
    # three_way_classify yields new-file-in-pack → clean add. The departing
    # Gemini x- customs are lifted INTO this bundle by the separate
    # _v10_to_v11_lift_gemini_customs_to_bundle step (runs after this, before
    # the .gemini/ retire). Re-run disposition: on a second pass `ours` is now
    # present (installed on the first pass) while base stays "", so
    # three_way_classify yields project-shadows-new-pack (NOT unchanged-pack —
    # that branch needs all three inputs present; with base="" the classifier
    # is presence-based and never reaches the cmp-driven no-op). That routes
    # through the conservative sidecar gate (needs-reconciliation). This is the
    # benign, never-reached case on a real single-shot net-new v10→v11
    # migration (which only ever sees the first pass = new-file-in-pack); it
    # belongs to the --update path's pre-existing-accepted domain. Runs before
    # _v10_to_v11_retire_gemini (the departing .gemini/ tree and this
    # .agents-plugin/ surface are disjoint).
    local bundle_src="$PACK/project-template/.agents-plugin/optiquity-agents"
    if [[ -d "$bundle_src" ]]; then
        local bundle_file rel proj_rel bundle_dest bundle_ours
        while IFS= read -r bundle_file; do
            rel="${bundle_file#"$bundle_src/"}"
            proj_rel=".agents-plugin/optiquity-agents/$rel"
            bundle_dest="$_MIGRATOR_TARGET/$proj_rel"
            bundle_ours="$bundle_dest"
            [[ -f "$bundle_ours" ]] || bundle_ours=""
            mkdir -p "$(dirname "$bundle_dest")"
            # Engine-routed, self-classify (no forced class): bundle pack
            # agents → replace-if-different; bundle x- customs → preserved.
            # Base "" — net-new surface, no v10 baseline (NEW design §3.1).
            customization_preserve \
                "" "$bundle_ours" "$bundle_file" "$proj_rel" "$bundle_dest" \
                >/dev/null
        done < <(find "$bundle_src" -type f)
        # Superset-tolerant count guard (NOT init's strict ==): the
        # replace-if-different + preserve-x- semantics mean a project that
        # customized its .agents-plugin/agents/ (kept an x- custom, removed
        # a pack agent) legitimately diverges from the pack count. Assert
        # every PACK bundle agent is PRESENT at the target (no pack agent
        # silently skipped); project extras (x- customs) are allowed.
        local pack_agent agent_name missing_bundle=0
        for pack_agent in "$bundle_src"/agents/*.md; do
            [[ -e "$pack_agent" ]] || continue
            agent_name=$(basename "$pack_agent")
            if [[ ! -f "$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/agents/$agent_name" ]]; then
                missing_bundle=$((missing_bundle + 1))
            fi
        done
        (( missing_bundle == 0 )) || \
            fail_stage S5 "Antigravity bundle install incomplete: $missing_bundle pack agent(s) missing under .agents-plugin/optiquity-agents/agents"
    fi

    # BD-167 (per-entry split, mandatory v11.0): canonical project-side
    # per-entry tree skeletons.
    #
    # Source: project-template/docs/project/<stream>/{_rules.md,
    # _intro.md}. Four streams: backlog,
    # implementation-plan, changelog, groupings (the fourth stream per
    # BD-262/BD-263). Client-immutable per
    # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.3 — the
    # supporting-file installation creates the directory if absent and
    # copies each support file iff the destination is absent (additive,
    # no overwrite of client-customized supporting files; BD-088
    # truthful-report mechanism handles divergence at next pack
    # version-bump per ARCHITECTURE-PER-ENTRY-SPLIT.md §4.2).
    #
    # Per-entry decompose of the project's existing monolithic
    # BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md is BD-165's
    # job (6th sub-op in this hook; lands in commit 19c). BD-167
    # installs the contract templates ONLY. Groupings has no decompose
    # sub-op — v10 has no groupings monolith.
    local stream_dir support_basenames base
    for stream_dir in backlog implementation-plan changelog groupings; do
        local pack_stream_dir="$PACK/project-template/docs/project/$stream_dir"
        local target_stream_dir="$_MIGRATOR_TARGET/docs/project/$stream_dir"
        [[ -d "$pack_stream_dir" ]] || continue
        mkdir -p "$target_stream_dir"
        # All four streams ship _rules.md + _intro.md.
        support_basenames="_rules.md _intro.md"
        for base in $support_basenames; do
            if [[ -f "$pack_stream_dir/$base" \
               && ! -f "$target_stream_dir/$base" ]]; then
                cp "$pack_stream_dir/$base" "$target_stream_dir/$base"
            fi
        done
    done

    # Integrity manifest — generate at migration by hashing the installed
    # _rules.md; the shipped verify-immutable.sh checks the client tree
    # against this install-time baseline (client-immutable set).
    bash "$PACK/scripts/immutable-manifest.sh" --client-tree "$_MIGRATOR_TARGET" \
        || fail_stage S5 "immutable-manifest generation failed against $_MIGRATOR_TARGET"

    # BD-263 (F10 fold): seed the empty groupings `_toc.md` iff absent.
    # The skeleton loop above ships docs/project/groupings/{_rules.md,
    # _intro.md}; without this seed the migrator path would yield a
    # groupings stream whose SOLE readable index is missing — the
    # BD-165 decompose sub-op regenerates TOCs for the three v10-monolith
    # streams only (v10 has no groupings monolith to decompose). Guarded
    # by absence so a re-entrant run (or a tree with a populated
    # groupings stream) keeps its existing `_toc.md` untouched. Parity
    # with init-project.sh stage S11 step 7. `per_entry_regenerate_toc`
    # is already sourced at adapter load
    # (scripts/lib/migrate-v10-to-v11/decompose.sh, type-guarded).
    local groupings_dir="$_MIGRATOR_TARGET/docs/project/groupings"
    if [[ -d "$groupings_dir" && ! -f "$groupings_dir/_toc.md" ]]; then
        per_entry_regenerate_toc "project-groupings" "$groupings_dir" \
            || fail_stage S5 "per_entry_regenerate_toc failed for project-groupings (groupings _toc.md seed)"
    fi

    # BD-161 (absorbed into BD-167 per
    # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §17.2 + §8.14):
    # net-new v11 SKILL.md dirs that did not exist in v10 must install
    # to all three per-CLI skill homes during the v10→v11 migration.
    # Without this, a v10→v11-migrated client silently lacks the new
    # v11 skills and the PM chat will not load them.
    #
    # The six net-new skills are:
    #   - swift-concurrency-patterns (BD-158)
    #   - apple-swiftdata-patterns (BD-157)
    #   - protobuf-patterns (BD-156)
    #   - python-server-architecture (BD-162 split)
    #   - python-data-architecture (BD-162 split)
    #   - python-observability-patterns (BD-162)
    #
    # Each ships from project-template/skills/<name>/SKILL.md; the
    # migrator copies it into all three per-CLI skill homes
    # (.claude/skills/, .codex/skills/, .agents/skills/ — Antigravity
    # reads `.agents/skills/`) iff the destination is absent (additive,
    # no overwrite of client-customized skill files; the BD-088
    # truthful-report mechanism handles divergence on later pack
    # version-bumps).
    local skill_name skill_src cli skill_dest
    for skill_name in swift-concurrency-patterns apple-swiftdata-patterns \
                      protobuf-patterns python-server-architecture \
                      python-data-architecture python-observability-patterns; do
        skill_src="$PACK/project-template/skills/$skill_name/SKILL.md"
        [[ -f "$skill_src" ]] || continue
        for cli in .claude .codex .agents; do
            skill_dest="$_MIGRATOR_TARGET/$cli/skills/$skill_name/SKILL.md"
            if [[ ! -f "$skill_dest" ]]; then
                mkdir -p "$_MIGRATOR_TARGET/$cli/skills/$skill_name"
                cp "$skill_src" "$skill_dest"
            fi
        done
    done
}

# Internal: lift departing Gemini x- custom agents INTO the Antigravity
# plugin bundle (BD-221 corrected agent-migration model). Runs AFTER
# _v10_to_v11_install_v11_artifacts (which lays down the pack bundle agents
# via the customization-preserve engine) and BEFORE
# _v10_to_v11_retire_gemini (which moves the whole departing `.gemini/` tree
# into the gemini-retired-docs/ backup holding dir).
#
# Frozen model #2/#3: the client's custom (`x-`) agents are KEPT — placed
# INTO the Antigravity bundle so they become live Antigravity agents,
# rather than retired into the holding dir requiring manual re-creation.
# The Gemini→Antigravity conversion is literally "lift the Gemini customs
# into the new surface."
#
# Source selection (BD-221 OQ-1): the custom agent exists in up to three
# places in a v10 project — `.gemini/agents/x-*.md`, `.claude/agents/x-*.md`
# (both `.md`, the bundle's format), and `.codex/agents/x-*.toml` (a
# different format, not a bundle source). Prefer the `.gemini/agents/x-*.md`
# copy (the literal departing-Gemini source), falling back to
# `.claude/agents/x-*.md` when the Gemini copy is absent. If BOTH exist and
# their content DIVERGED, the Gemini copy WINS and the divergence is FLAGGED
# in the migrator output (the client should reconcile by hand).
#
# C-2 (BD-221 reconciliation): the lift is a DIRECT `cp`, NOT engine-routed.
# The customization-preserve `custom-agent` branch returns
# `removed-everywhere` with NO copy when `ours` is absent — which it always
# is for a net-new bundle custom on the first migration. So a direct cp is
# the correct primitive here. Non-clobber: never overwrite a same-named
# custom already present in the bundle (a re-run, or a client who already
# placed it). The loose `.claude`/`.codex` x- copies remain preserved in
# place (Claude/Codex still read their loose dirs — they are NOT retired).
#
# Idempotent: a second run finds the bundle custom already present → skip.
_v10_to_v11_lift_gemini_customs_to_bundle() {
    say "── S5a — lift departing Gemini x- custom agents into the Antigravity bundle ──"

    local bundle_agents="$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/agents"
    local gemini_agents="$_MIGRATOR_TARGET/.gemini/agents"
    local claude_agents="$_MIGRATOR_TARGET/.claude/agents"

    # Build the candidate set: every x-*.md custom that exists in the
    # departing .gemini/agents/ OR the loose .claude/agents/. Use basenames
    # so a custom present in both surfaces is considered once (Gemini-first).
    local names="" f name
    if [[ -d "$gemini_agents" ]]; then
        for f in "$gemini_agents"/x-*.md; do
            [[ -e "$f" ]] || continue
            names="$names $(basename "$f")"
        done
    fi
    if [[ -d "$claude_agents" ]]; then
        for f in "$claude_agents"/x-*.md; do
            [[ -e "$f" ]] || continue
            name=$(basename "$f")
            case " $names " in *" $name "*) : ;; *) names="$names $name" ;; esac
        done
    fi

    [[ -n "${names// }" ]] || { info "no Gemini/Claude x- custom agents to lift"; return 0; }

    mkdir -p "$bundle_agents"
    local gemini_src claude_src src dest lifted=0
    for name in $names; do
        gemini_src="$gemini_agents/$name"
        claude_src="$claude_agents/$name"
        dest="$bundle_agents/$name"

        # OQ-1 source selection: Gemini preferred, Claude fallback.
        if [[ -f "$gemini_src" ]]; then
            src="$gemini_src"
            # Divergence flag: both copies exist but differ → Gemini wins,
            # surface the conflict for hand reconciliation.
            if [[ -f "$claude_src" ]] && ! cmp -s "$gemini_src" "$claude_src"; then
                say "  note: custom agent '$name' differs between .gemini/agents/ and"
                say "        .claude/agents/. The .gemini/ copy was lifted into the"
                say "        Antigravity bundle; reconcile by hand if the .claude/ copy"
                say "        was the one you intended to keep."
            fi
        elif [[ -f "$claude_src" ]]; then
            src="$claude_src"
        else
            continue
        fi

        # Non-clobber: never overwrite a same-named custom already in the
        # bundle (re-run / pre-placed). Direct cp (C-2 — not engine-routed).
        if [[ -f "$dest" ]]; then
            info "bundle custom '$name' already present — left untouched"
            continue
        fi
        cp "$src" "$dest"
        lifted=$((lifted + 1))
        info "lifted custom agent '$name' → .agents-plugin/optiquity-agents/agents/ (source: ${src#"$_MIGRATOR_TARGET/"})"
    done

    info "lifted $lifted Gemini/Claude x- custom agent(s) into the Antigravity bundle"
}

# Internal: retire a departing `.gemini/` tree on the v10→v11 migration
# (BD-221, decision 8).
#
# The pack-standard v11 Antigravity surfaces (`.agents/skills/` distributed
# loose, the agent plugin bundle `.agents-plugin/optiquity-agents/`,
# `.agents/mcp_config.json`) are installed by
# `_v10_to_v11_install_v11_artifacts` (the bundle through the
# customization-preserve engine, replace-if-different — see that function).
# The departing Gemini x- custom agents are already lifted INTO the bundle
# by `_v10_to_v11_lift_gemini_customs_to_bundle` (runs immediately before
# this step). This step then handles the DEPARTING `.gemini/` tree:
#
#   - pack-STANDARD `.gemini/` skills (mirrors of pool skills) are
#     superseded by the loose `.agents/skills/` install above; the legacy
#     `.gemini/` copies are moved into the holding dir (not re-converted —
#     the pool already shipped the v11 form to `.agents/skills/`).
#   - client-CUSTOMIZED `.gemini/` files (x- customs + project-edited
#     config that has no Antigravity target) are MOVED, NEVER deleted,
#     into a root-level `gemini-retired-docs/` holding dir as a BACKUP. The
#     x- customs were ALREADY lifted into the Antigravity bundle by the lift
#     step above (so they are live, not lost); this whole-tree move is the
#     recoverable safety copy of the entire departing `.gemini/`. Originals
#     also remain in the project's git history.
#   - the holding-dir move is whole-tree: the entire departing `.gemini/`
#     is relocated under `gemini-retired-docs/` preserving its internal
#     structure, then the empty `.gemini/` is removed.
#
# Idempotent across "EITHER Gemini OR Antigravity already present":
#   - no `.gemini/` present → nothing to retire (a fresh-Antigravity or
#     already-migrated project); no-op.
#   - `.agents/` already present → respect it; the engine-routed install
#     above never clobbers a client-customized Antigravity bundle, and this
#     step only moves the legacy `.gemini/` aside.
#
# If `gemini-retired-docs/` trips the client's CI, the client gitignores
# it (documented in the setup/migration docs); the holding dir is a
# recovery convenience, not a tracked deliverable.
_v10_to_v11_retire_gemini() {
    say "── S5b — retire departing Gemini tree → gemini-retired-docs/ ──"

    local legacy="$_MIGRATOR_TARGET/.gemini"
    if [[ ! -d "$legacy" ]]; then
        info "no departing .gemini/ tree at target — nothing to retire"
        return 0
    fi

    local holding="$_MIGRATOR_TARGET/gemini-retired-docs"
    mkdir -p "$holding"

    # Move the entire departing .gemini/ tree (customizations + legacy
    # pack copies alike) into the holding dir, preserving structure. Use a
    # timestamp-free `.gemini` subdir so the original layout is obvious and
    # recoverable. Never delete client content.
    local dest="$holding/.gemini"
    if [[ -e "$dest" ]]; then
        # A prior retirement already populated the holding dir — sidecar
        # this run's tree so nothing is overwritten (never delete).
        dest="$holding/.gemini.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$legacy" "$dest"
    info "retired: .gemini/ → gemini-retired-docs/$(basename "$dest") (preserved, not deleted)"

    # User-facing note. No `agy plugin import gemini` recommendation (that
    # targets the user's global ~/.gemini and skips project agents). No
    # BD-NNN reference (this prose ships into client-facing migrator
    # output). Antigravity docs pointer kept for orientation. Customs are
    # AUTO-LIFTED into the Antigravity bundle by the lift step above — the
    # holding dir is a BACKUP, not a manual-re-creation TODO.
    say ""
    say "v11 uses Antigravity. Your custom (x-) agents were copied into the"
    say "Antigravity bundle at .agents-plugin/optiquity-agents/agents/ — they"
    say "are live Antigravity agents now, nothing to re-create by hand. Your"
    say "full .gemini/ tree was moved to gemini-retired-docs/ as a backup"
    say "(preserved, not deleted). If gemini-retired-docs/ trips your CI, add"
    say "it to your .gitignore. See https://antigravity.google/docs for the"
    say "Antigravity skill/agent model."
}

# Internal: BD-035-split client-side rename of `python-architecture`
# references to the post-split skill names (`python-server-architecture`
# / `python-data-architecture`).
#
# As of BD-147 this is a thin dispatch into the shared
# `migrator_skill_rename` API in `scripts/lib/migrator-skills.sh` (split
# mode). The per-line scan, disambiguation rules, advisory preamble, and
# atomic-write semantics live there; this function contributes only the
# v10→v11-specific banner and the `python-architecture` →
# (`python-server-architecture` | `python-data-architecture`) parameters.
# Behavior is byte-equivalent to the pre-extraction inline implementation
# (verified by `scripts/tests/fixture-dependent/test-migrator-skills.sh`
# golden-snapshot harness).
#
# Files scanned (project-root-relative; only those that exist):
#   docs/pack/PLATFORM-SKILLS.md
#   CLAUDE.md, AGENTS.md, GEMINI.md
#
# Disambiguation rules (per-line) — implemented in
# scripts/lib/migrator-skills.sh::migrator_skill_rename split mode:
#   1. Line contains `python-server-architecture` already → rewrite
#      stale `python-architecture` to `python-server-architecture`.
#   2. Line contains `python-data-architecture` already → rewrite
#      stale `python-architecture` to `python-data-architecture`.
#   3. Line contains another server-tier signal (`grpc-patterns`,
#      `deployment-python`, `Python server`, `python-server`) AND
#      no data-tier signal → rewrite to `python-server-architecture`.
#   4. Line contains a data-tier signal (`repository`, `N+1`,
#      `Pydantic`, `data / I/O`) AND no server-tier signal → rewrite
#      to `python-data-architecture`.
#   5. Otherwise → record an ambiguous-rename advisory entry; leave
#      the file untouched at this site.
#
# Advisory output: $_MIGRATOR_STATE_DIR/python-architecture-rename.advisory
# (created only when at least one ambiguous site is found). The advisory
# enumerates file:line pairs the user should reconcile by hand. The
# customization-preserve sidecar contract is intentionally NOT used
# here because none of the files in scope are customization-preserve
# managed at this point in the migration (PLATFORM-SKILLS.md is a
# `transform` target; the trinity files are `trinity` transforms; the
# v10→v11 transform pipeline has already replaced their pack-managed
# content). The advisory file is the canonical user-facing surface.
_v10_to_v11_rename_python_architecture_refs() {
    say "── S5b — split: rename stale python-architecture refs ──"

    # Dispatch into the shared library. Split mode is selected by the two
    # MIGRATOR_SKILLS_SPLIT_TO_* env vars; the library reads them, applies
    # the BD-035 disambiguation rules, and writes the BD-035-preamble
    # advisory when ambiguity is found. The default file list covers the
    # four BD-035 targets (PLATFORM-SKILLS.md + trinity); the default
    # signal patterns are the BD-035 verbatim regexes — no overrides
    # needed at this call site.
    MIGRATOR_SKILLS_SPLIT_TO_SERVER="python-server-architecture" \
    MIGRATOR_SKILLS_SPLIT_TO_DATA="python-data-architecture" \
        migrator_skill_rename \
            "python-architecture" \
            "python-server-architecture" \
            "$_MIGRATOR_STATE_DIR/python-architecture-rename.advisory"
}

# Internal: BD-144 (v11.0 skill-dimensions reframe Batch 5) — translate
# v10.x capability tokens on each trinity file's `capabilities:` line.
#
# Per ARCHITECTURE-SKILL-DIMENSIONS.md §3.5 + §3.7 and
# PLAN-SKILL-DIMENSIONS.md §7.1, two v10.x tokens are realigned in v11:
#
#   1. `role:apple-app` is renamed to `deployment:apple` (Apple-app is a
#      D5 deployment surface, not a D3 architectural role).
#   2. `role:python-server` is preserved but its resolved skill list
#      changed: `deployment-python` was dropped from it (now loads via
#      the new `deployment:linux-container` D5 row). Append
#      `deployment:linux-container` to any line containing
#      `role:python-server` so the project doesn't silently lose the
#      `deployment-python` skill.
#
# Files scanned (project-root, only those that exist):
#   CLAUDE.md, AGENTS.md, GEMINI.md
#
# The stage scans every line for the literal `^capabilities:` prefix.
# Token boundaries are anchored via the surrounding character class
# `[^A-Za-z0-9_:-]` (or line start/end) so substring matches like
# `role:apple-app-foo` (hypothetical) cannot be touched.
#
# Idempotency:
#   - `role:apple-app` → `deployment:apple` is a one-shot replace; once
#     applied the source token is gone.
#   - `deployment:linux-container` is only appended when the line
#     contains `role:python-server` AND does NOT already contain
#     `deployment:linux-container` (token boundary anchored).
#
# Advisory output: $_MIGRATOR_STATE_DIR/capability-rename.advisory
# (created only when at least one site is touched). Format mirrors the
# BD-035 S5b advisory: comment header + per-touch entries with
# file:line: before / after / rationale.
_v10_to_v11_translate_capability_tokens() {
    say "── S5c — capability-token translation (role:apple-app → deployment:apple; deployment:linux-container append) ──"

    local advisory="$_MIGRATOR_STATE_DIR/capability-rename.advisory"
    local touches=0
    local rel f tmp linenum line new_line had_change

    local files=(
        "CLAUDE.md"
        "AGENTS.md"
        "GEMINI.md"
    )

    # Token-boundary anchors — bare-token form, similar to the §3 pattern
    # used in python_data_marker_detected(). Lead/trail boundary asserts
    # the byte before / after the token is NOT a token-continuation char.
    local apple_pat='(^|[^A-Za-z0-9_:-])role:apple-app($|[^A-Za-z0-9_:-])'
    local pyserver_pat='(^|[^A-Za-z0-9_:-])role:python-server($|[^A-Za-z0-9_:-])'
    local lxc_pat='(^|[^A-Za-z0-9_:-])deployment:linux-container($|[^A-Za-z0-9_:-])'

    for rel in "${files[@]}"; do
        f="$_MIGRATOR_TARGET/$rel"
        [[ -f "$f" ]] || continue
        # Cheap fast path: skip if the file has no `capabilities:` line at
        # all, or if it has one but contains neither legacy token.
        if ! grep -qE '^capabilities:' "$f" 2>/dev/null; then
            continue
        fi
        if ! grep -qE "$apple_pat|$pyserver_pat" "$f" 2>/dev/null; then
            continue
        fi

        tmp=$(mktemp -t pack-cap-rename.XXXXXX) || \
            fail_stage S5 "S5c-translate: mktemp failed for $rel"
        linenum=0
        had_change=0
        # Read line-by-line; only `capabilities:`-prefixed lines are
        # candidates for translation. Other lines are passed through.
        while IFS= read -r line || [[ -n "$line" ]]; do
            linenum=$((linenum + 1))
            if [[ "$line" != capabilities:* ]]; then
                printf '%s\n' "$line" >>"$tmp"
                continue
            fi
            new_line="$line"
            local before_apple="$new_line"
            # Edit 1: rename role:apple-app → deployment:apple, anchored
            # to token boundaries via sed groups that preserve the
            # surrounding (non-token) chars.
            if printf '%s' "$new_line" | grep -qE "$apple_pat"; then
                new_line=$(printf '%s' "$new_line" | sed -E \
                    "s/(^|[^A-Za-z0-9_:-])role:apple-app($|[^A-Za-z0-9_:-])/\\1deployment:apple\\2/g")
                if [[ "$new_line" != "$before_apple" ]]; then
                    if (( touches == 0 )); then
                        {
                            printf '# capability-token translation advisory\n'
                            printf '#\n'
                            printf '# v11 renames `role:apple-app` to `deployment:apple` (D5 deployment\n'
                            printf '# surface, not a D3 architectural role per\n'
                            printf '# ARCHITECTURE-SKILL-DIMENSIONS.md §3.5).\n'
                            printf '# v11 also preserves `role:python-server` but its resolved skill\n'
                            printf '# list dropped `deployment-python` (now loads via the new\n'
                            printf '# `deployment:linux-container` D5 row); the migrator appends\n'
                            printf '# `deployment:linux-container` to lines containing\n'
                            printf '# `role:python-server` so projects do not silently lose the skill.\n'
                            printf '#\n'
                            printf '# Format: <file>:<line>: <kind>\n'
                            printf '#   before: <text>\n'
                            printf '#   after:  <text>\n'
                            printf '#   rationale: <one-line rationale>\n'
                            printf '\n'
                        } >"$advisory"
                    fi
                    {
                        printf '%s:%d: rename\n' "$rel" "$linenum"
                        printf '  before: %s\n' "$before_apple"
                        printf '  after:  %s\n' "$new_line"
                        printf '  rationale: role:apple-app renamed to deployment:apple (D5 deployment surface, ARCHITECTURE-SKILL-DIMENSIONS.md §3.5)\n'
                    } >>"$advisory"
                    touches=$((touches + 1))
                    had_change=1
                fi
            fi
            # Edit 2: append `, deployment:linux-container` to lines
            # containing `role:python-server` AND not already containing
            # `deployment:linux-container`. Idempotent.
            local before_lxc="$new_line"
            if printf '%s' "$new_line" | grep -qE "$pyserver_pat" \
               && ! printf '%s' "$new_line" | grep -qE "$lxc_pat"; then
                # Append with a comma separator, preserving any trailing
                # whitespace on the line by appending before it. Simplest:
                # rstrip trailing whitespace, append, restore newline.
                local rstripped
                rstripped=$(printf '%s' "$new_line" | sed -E 's/[[:space:]]+$//')
                # If the rstripped line ends with a comma, append without
                # adding a second comma; otherwise add `, `. Preserves
                # the human-readable comma-space convention used by the
                # detect_installed_capabilities() output.
                if [[ "$rstripped" == *, ]]; then
                    new_line="${rstripped} deployment:linux-container"
                else
                    new_line="${rstripped}, deployment:linux-container"
                fi
                if [[ "$new_line" != "$before_lxc" ]]; then
                    if (( touches == 0 )); then
                        {
                            printf '# capability-token translation advisory\n'
                            printf '#\n'
                            printf '# v11 renames `role:apple-app` to `deployment:apple` (D5 deployment\n'
                            printf '# surface, not a D3 architectural role per\n'
                            printf '# ARCHITECTURE-SKILL-DIMENSIONS.md §3.5).\n'
                            printf '# v11 also preserves `role:python-server` but its resolved skill\n'
                            printf '# list dropped `deployment-python` (now loads via the new\n'
                            printf '# `deployment:linux-container` D5 row); the migrator appends\n'
                            printf '# `deployment:linux-container` to lines containing\n'
                            printf '# `role:python-server` so projects do not silently lose the skill.\n'
                            printf '#\n'
                            printf '# Format: <file>:<line>: <kind>\n'
                            printf '#   before: <text>\n'
                            printf '#   after:  <text>\n'
                            printf '#   rationale: <one-line rationale>\n'
                            printf '\n'
                        } >"$advisory"
                    fi
                    {
                        printf '%s:%d: append\n' "$rel" "$linenum"
                        printf '  before: %s\n' "$before_lxc"
                        printf '  after:  %s\n' "$new_line"
                        printf '  rationale: role:python-server preserved but deployment-python now loads via deployment:linux-container (D2 ∩ D5, ARCHITECTURE-SKILL-DIMENSIONS.md §3.7)\n'
                    } >>"$advisory"
                    touches=$((touches + 1))
                    had_change=1
                fi
            fi
            printf '%s\n' "$new_line" >>"$tmp"
        done <"$f"

        if (( had_change == 1 )); then
            if ! mv "$tmp" "$f"; then
                rm -f "$tmp"
                fail_stage S5 "S5c-translate: failed to write rewritten $rel"
            fi
            info "translated capability tokens in $rel"
        else
            rm -f "$tmp"
        fi
    done

    if (( touches > 0 )); then
        info "capability-token translation: $touches capability-token edit(s) recorded in $advisory"
    else
        info "capability-token translation: no v10.x capability tokens found (no-op)"
    fi
}

# migrator_post_report_hook — version-specific guidance text printed after
# the report is rendered. v10→v11 surfaces the per-entry decomposition
# advisory; tracker integration is deferred (BD-214), so no `pack tracker
# init` opt-in is advertised. Mirrors the monolith's stage_s6_report tail.
#
# Also surfaces the BD-165 v11.0 per-entry decomposition advisory per
# ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §8.18 / §9.4. v11.0
# decomposition is non-reversible (the per-entry trees are now the sole
# source of truth — no monolithic mirror is regenerated, BD-206); the
# backup directory created by `_stage_backup`
# (scripts/lib/migrator-stages.sh:146) is the rollback path. Surface the
# advisory here so the user reviews it alongside the customization-
# preserve report.
migrator_post_report_hook() {
    say ""
    say "v11.0 introduces per-entry decomposition of BACKLOG / CHANGELOG /"
    say "IMPLEMENTATION-PLAN. The per-entry trees under"
    say "  docs/project/backlog/, docs/project/implementation-plan/,"
    say "  docs/project/changelog/"
    say "are now the sole source of truth + readable form. Each stream's"
    say "generated _toc.md is the index. The v10 monolithic"
    say "  docs/project/BACKLOG.md, docs/project/IMPLEMENTATION-PLAN.md,"
    say "  docs/project/CHANGELOG.md"
    say "files were read as decomposition INPUT and are NOT regenerated as"
    say "mirrors — there is no monolithic mirror under the v11 model."
    say ""
    say "This decomposition is non-reversible by design. To revert to the v10"
    say "monolithic-as-source shape, restore from the backup directory at"
    say "  $_MIGRATOR_BACKUP_DIR"
    say "(or, if you committed the v10 state, \`git reset --hard <pre-migration-commit>\`)."
    say "After restore, re-running this migrator will re-decompose."
    say ""
    say "Issue-tracker integration is DEFERRED: flat-file per-entry is"
    say "the sole supported mode in v11. The tracker code is retained dormant for"
    say "a future resumption; there is no tracker opt-in to run at this time."
}

# ── Source the framework + run ─────────────────────────────────────────────

# Source the framework via SCRIPT_DIR — the lib lives in the same pack as
# this adapter, so we do NOT need $PACK to be set just to source it. This
# preserves `--help` / unknown-option behavior even when PACK is unset, and
# lets the framework's `_stage_preflight` enforce the documented
# `EXIT_PACK_INVALID=10` path (architecture §3.2 invariant I1) when the
# user actually attempts a migration without exporting PACK.
#
# Do NOT auto-resolve PACK here. The architecture/PLAN treat unset PACK as
# a fatal preflight, not a recoverable default; substituting a fallback
# silently breaks the documented exit-code contract.

# shellcheck source=lib/migrator-core.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrator-core.sh"

# ── BD-095 two-phase mode dispatch ─────────────────────────────────────────
#
# The three mode libs sit under scripts/lib/migrate-v10-to-v11/. dry-run.sh
# stamps a fingerprint, apply.sh enforces freshness + sentinel-based
# pause/resume, resume.sh continues a paused run after sidecar
# reconciliation. Each lib exposes a `migrate_v10_to_v11_<mode>_run`
# function that wraps `migrator_run` with the mode-specific concerns.
#
# We parse the FIRST `--<mode>` flag here and dispatch. The framework's
# arg parser still validates other flags + positional args downstream.

# shellcheck source=lib/migrate-v10-to-v11/dry-run.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/dry-run.sh"
# shellcheck source=lib/migrate-v10-to-v11/apply.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/apply.sh"
# shellcheck source=lib/migrate-v10-to-v11/resume.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/resume.sh"

# BD-165 — adapter-private 6th post-dispatch sub-op (per-entry split).
# Sources the BD-164 helpers from scripts/lib/per-entry/; defines
# `_v10_to_v11_decompose_streams` consumed by the post-dispatch hook
# above. Architecture: ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.1
# / §9.6 / §10.2 + ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
# §4.5 + research-side ARCHITECTURE-PER-ENTRY-SPLIT.md §1.3 (constraint
# statement on function naming / placement).
# shellcheck source=lib/migrate-v10-to-v11/decompose.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/decompose.sh"

# BD-101 — verification gates (read-only checks at stage transitions).
# Each gate sources `checkpoint.sh` for its shared helpers.
# shellcheck source=lib/migrate-v10-to-v11/checkpoint.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/checkpoint.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh"

# Mode detection: scan args for the first explicit mode flag. Drop the
# matched flag from the forwarded args because each mode dispatcher
# re-supplies its own canonical mode flag to `migrator_run`.
#
# Source-guard: when this file is SOURCED (e.g. a unit test sourcing it to
# exercise an internal helper like `_v10_to_v11_retire_gemini` in
# isolation) rather than executed, skip the arg-parse + mode dispatch
# below. Executed-as-script is the normal path. `${BASH_SOURCE[0]}` equals
# `${0}` only when the file is run directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
_mode=""
_passthru=()
for _a in "$@"; do
    case "$_a" in
        --dry-run|--apply|--resume)
            if [[ -z "$_mode" ]]; then
                _mode="$_a"
                continue
            fi
            # F5 (BD-095 retro fix): duplicate mode flags fail loud at the
            # dispatcher (this is where the contract is owned). The
            # pre-fix behavior pushed the second flag to passthru and let
            # the framework parser run with contradictory state — e.g.
            # `--dry-run --apply` ran with _MIGRATOR_DRY_RUN=1 and
            # _MIGRATOR_MODE="apply", and `--dry-run --resume` produced
            # a confusing "framework call path was not intercepted"
            # error. (See PACK-REVIEW-BD-095-RETRO.md F5.)
            {
                printf 'error: multiple mode flags: %s and %s (only one of --dry-run / --apply / --resume permitted)\n' \
                    "$_mode" "$_a"
            } >&2
            exit "${EXIT_INTERNAL:-99}"
            ;;
        *)
            _passthru+=("$_a")
            ;;
    esac
done

# Helper: scan passthru for --help and route through framework usage if present.
_dispatch_help_passthru() {
    local _a
    for _a in "${_passthru[@]:-}"; do
        case "$_a" in
            --help|-h)
                migrator_run "${_passthru[@]:-}"
                exit $?
                ;;
        esac
    done
}

case "$_mode" in
    --dry-run)
        _dispatch_help_passthru
        migrate_v10_to_v11_dry_run_run "${_passthru[@]:-}"
        ;;
    --resume)
        _dispatch_help_passthru
        migrate_v10_to_v11_resume_run "${_passthru[@]:-}"
        ;;
    --apply)
        # Explicit --apply: STRICTLY enforce the freshness gate. Refuses
        # to run without a pre-existing fresh dry-run fingerprint
        # (architecture §6.G). Users who want the auto-dry-run-then-
        # apply convenience drop the flag and use the bare invocation.
        _dispatch_help_passthru
        migrate_v10_to_v11_apply_run "${_passthru[@]:-}"
        ;;
    "")
        # Bare invocation: backwards-compat with the pre-BD-095 UX.
        # Auto-runs --dry-run first if no fresh dry-run output exists,
        # then runs --apply. Users of the legacy `migrate.sh <target>`
        # invocation pattern do NOT need to learn the new flags for the
        # no-conflict path.
        _dispatch_help_passthru
        _target="."
        for _a in "${_passthru[@]:-}"; do
            case "$_a" in
                -*|--*) ;;
                *) _target="$_a"; break ;;
            esac
        done
        _target_abs="$(cd "$_target" 2>/dev/null && pwd || printf '%s' "$_target")"
        # F3 (BD-095 retro fix): bare-invocation-after-pause guard. If
        # `stage-S3.paused` exists the previous `--apply` paused for
        # sidecar reconciliation and the user must `--resume`, NOT bare-
        # rerun. Without this guard the bare path would either skip the
        # auto-dry-run (fingerprint still fresh) and call `--apply`,
        # which would wipe `dispositions.tsv` and reach S1 with the
        # backup-dir-already-exists error — telling the user to remove
        # the backup when the right answer is `--resume`. (See PACK-REVIEW-
        # BD-095-RETRO.md F3.)
        _paused_sentinel="$_target_abs/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
        if [[ -f "$_paused_sentinel" ]]; then
            {
                printf 'error: a paused migration exists for this target\n'
                printf '  paused-sentinel: %s\n' "$_paused_sentinel"
                printf '\n'
                printf '→ Resolve the listed sidecars then run:\n'
                printf '    PACK=%s scripts/migrate-v10-to-v11.sh --resume %s\n' \
                    "${PACK:-/path/to/pack}" "$_target_abs"
                printf '\n'
                printf '  Or to start over, restore from %s and re-run.\n' \
                    "$_target_abs/.pack-migrate-v10-to-v11-backup"
            } >&2
            exit "${EXIT_INTERNAL:-99}"
        fi
        _fp="$_target_abs/.pack-migrate-v10-to-v11/dry-run.fingerprint"
        # Determine whether a re-dry-run is needed:
        #   - fingerprint absent
        #   - fingerprint older than 24h (would fail freshness in apply)
        #   - working-tree fingerprint drifted from recorded fingerprint
        # Any of those → auto-rerun --dry-run so the bare-invocation UX
        # mirrors the pre-BD-095 single-shot path.
        _need_dry_run=0
        if [[ ! -f "$_fp" ]]; then
            _need_dry_run=1
        else
            _now=$(date +%s)
            _rec_epoch=$(grep '^epoch=' "$_fp" | head -1 | cut -d= -f2-)
            if [[ -z "$_rec_epoch" ]] \
               || (( _now - _rec_epoch > ${V10_V11_DRYRUN_MAX_AGE_SECS:-86400} )); then
                _need_dry_run=1
            else
                _rec_sha=$(grep '^target_sha256=' "$_fp" | head -1 | cut -d= -f2-)
                _cur_line=$(migrate_v10_to_v11_dry_run_compute_fingerprint "$_target_abs")
                _cur_sha=$(printf '%s' "$_cur_line" | awk '{print $1}')
                if [[ "$_rec_sha" != "$_cur_sha" ]]; then
                    _need_dry_run=1
                fi
            fi
        fi
        if (( _need_dry_run == 1 )); then
            say "── backwards-compat: no fresh dry-run found ──"
            say "Auto-running --dry-run first; --apply will follow on success."
            say ""
            migrate_v10_to_v11_dry_run_run "${_passthru[@]:-}" || exit $?
            say ""
            say "── proceeding to --apply ──"
            say ""
        fi
        migrate_v10_to_v11_apply_run "${_passthru[@]:-}"
        ;;
esac
fi  # end source-guard (executed-as-script dispatch)
