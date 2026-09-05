#!/usr/bin/env bash
# init-project.sh — initialize an AI Agent Config Pack installation in
# a new or existing project directory, OR refresh an existing pack
# install (--update) without destroying project customization.
#
# The default flow classifies the target into
# one of five project classes, stops (exit 20) if AI config is already
# present, prints a preview report, asks for explicit confirmation
# (default No), then executes stages S0..S11 with inline verification
# at each step. A blast-radius sweep at the end of S6 and S11 checks
# for stale cross-references.
#
# v11 additions (BD-080): stage S11 installs v11 client-side artifacts
# (HELP-FRAGMENT.md,
# .github/ISSUE_TEMPLATE/* issue forms). NOTE (BD-214, 2026-06-13):
# tracker.toml.example is NO LONGER
# installed — tracker integration is deferred and flat-file is the sole
# supported mode (the dormant config record stays committed pack-side at
# project-template/tracker.toml.project-example). The --update flag
# refreshes a previously-installed pack to
# the current pack version using the BD-088 customization-preservation
# contract; no destructive overwrites of project edits.
#
# Usage:
#     PACK=/path/to/pack ./scripts/init-project.sh [target-dir]
#     PACK=/path/to/pack ./scripts/init-project.sh --update [target-dir]
#
# Target directory defaults to the current working directory.
#
# Exit codes (§7.7):
#     0   Success, or developer declined confirmation
#     10  $PACK invalid
#     11  Target is not a git repo
#     12  Working tree not clean
#     20  STOP — existing AI config (default flow only)
#     21–30 Stage N (20 + stage number; clamped to 30) failure
#     31  Blast-radius sweep failure
#     40  Conditional-removal failure
#     50  --update: target is not currently pack-configured
#     51  --update: BD-088 customization library unavailable
#     99  Internal error (set -euo pipefail trap)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exit codes
readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_AI_CONFIG=20
readonly EXIT_SWEEP=31
readonly EXIT_CONDITIONAL=40
readonly EXIT_UPDATE_NOT_CONFIGURED=50
readonly EXIT_UPDATE_LIB_MISSING=51
readonly EXIT_INTERNAL=99

# Confirm-flow flags (BD-284). Module-level (NOT main() locals) so the separate
# confirm_proceed function sees them: --yes bypasses the confirm for automation;
# --no-interactive / INTERACTIVE steer prompt_should_interact. Set by the argv
# parser in main().
YES=0
NO_INTERACTIVE=0
INTERACTIVE=0

# Trinity-handling flags (BD-285 C2). Module-level so main()'s dispatch,
# handle_handwritten_trinity, and stage_s7_trinity all see them. TRINITY_FLAG
# is the explicit `--trinity=keep|replace|merge` automation selector (the SOLE
# trinity-automation selector — evaluated INDEPENDENT of prompt_should_interact;
# --yes alone does NOT name it). TRINITY_CHOICE is the RESOLVED handling
# (keep|replace|merge) for a handwritten trinity; empty for every non-guided
# install, so stage_s7_trinity's normal path is unaffected.
TRINITY_FLAG=""
TRINITY_CHOICE=""

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

fail_stage() {
    local stage="$1" msg="$2"
    # Stage number is S0..S10; exit code is 20 + N. S0 uses pre-confirm codes.
    local n="${stage#S}"
    local code=$(( 20 + n ))
    (( code > 30 )) && code=30
    printf 'error: stage %s failed: %s\n' "$stage" "$msg" >&2
    printf 'hint: inspect state with `git status`; reset with `git reset --hard && git clean -fd`\n' >&2
    exit "$code"
}

# ── Source shared libraries ────────────────────────────────────────────────

if [[ ! -f "$SCRIPT_DIR/lib/detect.sh" ]]; then
    die "missing shared detection library: $SCRIPT_DIR/lib/detect.sh" "$EXIT_INTERNAL"
fi
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"

if [[ ! -f "$SCRIPT_DIR/lib/three-way.sh" ]]; then
    die "missing three-way classifier library: $SCRIPT_DIR/lib/three-way.sh" "$EXIT_INTERNAL"
fi
# shellcheck source=lib/three-way.sh
source "$SCRIPT_DIR/lib/three-way.sh"

if [[ ! -f "$SCRIPT_DIR/lib/prompt.sh" ]]; then
    die "missing interactive-prompt library: $SCRIPT_DIR/lib/prompt.sh" "$EXIT_INTERNAL"
fi
# shellcheck source=lib/prompt.sh
source "$SCRIPT_DIR/lib/prompt.sh"

# ── Existing-project classifier wrapper (BD-059 OQ-5) ──────────────────────
#
# When --existing path encounters a target file that already exists, run
# the four-case classifier with BASE absent (init has no v9.3 baseline).
# If the project file differs from the pack file, write the pack version
# as a `.pack-template` sidecar alongside so the developer can reconcile
# manually. If they are identical, do nothing. In all cases, the project
# file is left untouched (conservative — preserves prior init-project.sh
# behaviour while surfacing the pack template for comparison).
#
# Returns 0 always; emits an info line per resolution.
existing_classifier_copy() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
        return 0
    fi
    if [[ ! -f "$dst" ]]; then
        cp "$src" "$dst"
        return 0
    fi
    if cmp -s "$src" "$dst"; then
        # Identical content; nothing to surface.
        return 0
    fi
    local classification
    classification=$(three_way_classify "" "$dst" "$src")
    case "$classification" in
        project-shadows-new-pack)
            cp "$src" "${dst}.pack-template"
            info "EXISTS $dst — pack template preserved at ${dst}.pack-template (differs; reconcile manually)"
            ;;
        *)
            info "EXISTS $dst — classifier=$classification; left untouched (manual review)"
            ;;
    esac
    return 0
}

# ── BD-285 P5/F6/SHOULD-1/SHOULD-2 — structured-config 2-way key-union ──────
#
# On an existing-source install, a STRUCTURED-class config that collides with a
# project's pre-existing file is merged via the shipped empty-BASE key-union
# (OURS wins a scalar conflict, pack-only keys added, project-only keys kept)
# instead of being sidecar-preserved. customization-preserve.sh is CONSUMED
# (sourced + called), NEVER edited.

# _ensure_customization_lib — lazily source customization-preserve.sh (guarded)
# and set _CP_PACK_ROOT. Returns non-zero if the library is unavailable so the
# caller can fall back to existing_classifier_copy.
_ensure_customization_lib() {
    if ! declare -F customization_preserve >/dev/null 2>&1; then
        [[ -f "$SCRIPT_DIR/lib/customization-preserve.sh" ]] || return 1
        export _CP_PACK_ROOT="$PACK"
        # shellcheck disable=SC1091
        source "$SCRIPT_DIR/lib/customization-preserve.sh"
    fi
    export _CP_PACK_ROOT="$PACK"
    return 0
}

# _s3_structured_keyunion SRC DST REL CLASS — THROWAWAY-probe structured merge.
#
# SHOULD-2 lifecycle: runs customization_preserve against a SCRATCH dest inside
# a THROWAWAY (mktemp) state dir, inspects the recorded action, and promotes
# ONLY merged bytes to the live tree; the throwaway dir (incl. any probe-side
# sidecar) is discarded. It NEVER creates the persistent .pack-install-reconcile/
# dir (that is created ONLY by the trinity merge writer, s7_reconcile_append_row).
# The probe uses an install-flavored sidecar_suffix (NOT the .pre-update default).
#
# ROI-1: the merger's rc0 (clean) AND rc2 (warn) arms both record action
# `merged` with valid merged bytes → promote, write NO live sidecar (the key-
# union already folded OURS in). Only the rc-error arm records action `sidecar`
# (THEIRS in the scratch dest) → this function returns NON-ZERO so the caller
# falls back to existing_classifier_copy (F6 — never a silent THEIRS adoption).
#
# Returns 0 iff merged bytes were promoted; non-zero to signal the F6 fallback.
_s3_structured_keyunion() {
    local src="$1" dst="$2" rel="$3" class="$4"
    local probe_dir scratch_dest disp_file action rc=1
    probe_dir=$(mktemp -d "${TMPDIR:-/tmp}/pack-s3-probe.XXXXXX") || return 1
    scratch_dest="$probe_dir/scratch-dest"
    if customization_preserve_init "$probe_dir/state" ".pack-preserve-orig"; then
        # OURS = live dst, THEIRS = pack src, empty BASE, DEST = scratch.
        # Guard the call: it returns 0 normally, but never let a stray non-zero
        # trip the `set -euo pipefail` trap mid-install — the action inspection
        # below is the real decision point.
        customization_preserve "" "$dst" "$src" "$rel" "$scratch_dest" "$class" \
            >/dev/null 2>&1 || true
        disp_file=$(customization_findings_tsv_path)
        action=$(awk -F'\t' 'END{print $4}' "$disp_file" 2>/dev/null)
        if [[ "$action" == "merged" && -f "$scratch_dest" ]]; then
            cp "$scratch_dest" "$dst"
            info "MERGED $dst — structured key-union (project keys preserved; pack keys added)"
            rc=0
        fi
    fi
    rm -rf "$probe_dir"
    return "$rc"
}

# s3_config_copy SRC DST REL — existing-source S3 config copy (BD-285 P5).
# Routes a STRUCTURED-class config (the classes customization_preserve dispatches
# to _cp_strategy_structured — mirror scripts/lib/customization-preserve.sh's
# claude-settings|claude-mcp-example|mcp-config-json|codex-config|codex-config-example
# dispatch) through the 2-way key-union; any other class, an unavailable library,
# or a merger parse-error (F6) falls back to existing_classifier_copy (user file
# stays LIVE + pack → .pack-template). Driving off customization_classify covers
# ALL structured S3 files (incl. .agents/mcp_config.json + .codex/requirements.toml)
# and auto-joins a future structured config with no init edit.
s3_config_copy() {
    local src="$1" dst="$2" rel="$3"
    # Absent live file → plain install (nothing to merge).
    if [[ ! -f "$dst" ]]; then
        cp "$src" "$dst"
        return 0
    fi
    # Identical → nothing to surface (matches existing_classifier_copy).
    if cmp -s "$src" "$dst"; then
        return 0
    fi
    if ! _ensure_customization_lib; then
        existing_classifier_copy "$src" "$dst"
        return 0
    fi
    local class
    class=$(customization_classify "$rel")
    case "$class" in
        claude-settings|claude-mcp-example|mcp-config-json|codex-config|codex-config-example)
            if ! _s3_structured_keyunion "$src" "$dst" "$rel" "$class"; then
                existing_classifier_copy "$src" "$dst"
            fi
            ;;
        *)
            existing_classifier_copy "$src" "$dst"
            ;;
    esac
    return 0
}

# ── Init-only detection helpers ────────────────────────────────────────────

# language-markers: <comma list> | (none)
# Checks for language manifest files at depth ≤ 2.
#
# BD-200: the TRACKED capability pool (pack-capability-pool/) holds COPIES of
# the full conditional-master set (pyproject.toml, *.py under server/, etc.)
# regardless of the project's actual languages. Those copies are NOT project
# source — they exist so activate-capability.sh can re-materialize a capability
# without a pack clone. Detection MUST ignore them, else a Swift-only project
# would mis-detect python from its own pool and S9 would wrongly skip the
# live-tree removal. Each marker find therefore excludes the pool path
# (parallel to the existing dotted-dir exclusion).
detect_language_markers() {
    local target="${1:-.}"
    local found=()
    # Dot exclusions below are ANCHORED to "$target" so they drop only dot-entries
    # UNDER the client tree (.git, .venv, …), NOT a client whose own checkout path
    # contains a dot-component (e.g. ~/.config/proj) — a loose '*/.*' mis-detects
    # such a client as (none).
    # Swift: Package.swift, *.xcodeproj, *.xcworkspace
    if find "$target" -maxdepth 2 \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" \) \
            -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | grep -q .; then
        found+=("swift")
    fi
    # Python: pyproject.toml
    if find "$target" -maxdepth 2 -name "pyproject.toml" -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | grep -q .; then
        found+=("python")
    fi
    # Kotlin: build.gradle.kts, settings.gradle.kts, build.gradle
    if find "$target" -maxdepth 2 \( -name "build.gradle.kts" -o -name "settings.gradle.kts" -o -name "build.gradle" \) \
            -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | grep -q .; then
        found+=("kotlin")
    fi
    # TypeScript/Node: package.json, tsconfig.json
    if find "$target" -maxdepth 2 \( -name "package.json" -o -name "tsconfig.json" \) \
            -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | grep -q .; then
        found+=("typescript")
    fi
    # Proto: proto/ with ≥1 .proto file (keyed on the LIVE-tree proto/ dir only,
    # so the pool's pack-capability-pool/proto/ never trips it — defensive
    # exclusion added for parity / future refactors).
    if [[ -d "$target/proto" ]] && find "$target/proto" -maxdepth 2 -name "*.proto" \
            -not -path '*/pack-capability-pool/*' 2>/dev/null | grep -q .; then
        found+=("proto")
    fi

    # CLIENT-LANGUAGE-EVIDENCE CONTRACT: a weak extension count is evidence of a
    # CLIENT language ONLY for source in client-owned territory (the project root,
    # or a client source dir at depth ≤ 2 — src/, server/, Sources/). It MUST
    # exclude every directory the PACK populates with its own tooling:
    #   - scripts/ — pack tooling (conditional *.sh + the PM *.py + any future
    #     pack-shipped script); excluded via -not -path "$target/scripts/*".
    #   - pack-capability-pool/ — the tracked capability pool (already excluded).
    # A pack file dropped into scripts/ is non-evidence BY CONSTRUCTION — no
    # per-file exclusion to maintain. STRONG markers (manifest filenames) need no
    # scripts/ exclusion: the pack ships no strong-marker filename into scripts/.
    # Weak evidence (extension count ≥ 3) only if no strong evidence for that language yet.
    if ! printf '%s\n' "${found[@]:-}" | grep -qx "swift"; then
        local c
        c=$(find "$target" -maxdepth 2 -name "*.swift" -not -path "$target/scripts/*" -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
        (( c >= 3 )) && found+=("swift")
    fi
    if ! printf '%s\n' "${found[@]:-}" | grep -qx "python"; then
        local c
        c=$(find "$target" -maxdepth 2 -name "*.py" -not -path "$target/scripts/*" -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
        (( c >= 3 )) && found+=("python")
    fi

    if (( ${#found[@]} == 0 )); then
        echo "language-markers: (none)"
    else
        local IFS=,
        echo "language-markers: ${found[*]}"
    fi
}

# source-files: <summary> — depth ≤ 2 counts for the covered languages.
# The pack-capability-pool/ exclusion mirrors detect_language_markers()
# for consistency / forward-safety: this diagnostic runs at preview time
# (before S5b populates the pool), so the pool is absent today, but
# excluding it here keeps the count honest if this helper is ever called
# post-install.
detect_source_files() {
    local target="${1:-.}"
    local s p
    s=$(find "$target" -maxdepth 2 -name "*.swift" -not -path "$target/scripts/*" -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
    p=$(find "$target" -maxdepth 2 -name "*.py" -not -path "$target/scripts/*" -not -path "$target/.*" -not -path "$target/*/.*" -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
    echo "source-files: *.swift=$s, *.py=$p"
}

# classify_project_state_no_ai: new-empty | new-bare | existing-bare | existing-source
#
# BD-285 C2: the underlying class for the NON-trinity files, computed WITHOUT
# the AI-config gate. Used (a) by classify_project_state below (delegated —
# behavior unchanged for the non-configured path) and (b) by
# handle_handwritten_trinity to re-classify a handwritten-trinity target after
# the guided branch routes the trinity separately (so the S1..S11 stages route
# by the real project shape, not `already-configured`).
classify_project_state_no_ai() {
    local target="${1:-.}"
    # Language markers?
    local lm
    lm=$(detect_language_markers "$target" | awk -F': ' '{print $2}')
    if [[ "$lm" != "(none)" ]]; then
        echo "classify: existing-source"
        return
    fi
    # README + docs/ with markdown only?
    if [[ -f "$target/README.md" && -d "$target/docs" ]]; then
        if find "$target/docs" -type f -not -name "*.md" 2>/dev/null | grep -q .; then
            echo "classify: existing-source"   # docs has non-md files — treat as source
        else
            echo "classify: existing-bare"
        fi
        return
    fi
    # README only?
    if [[ -f "$target/README.md" ]]; then
        echo "classify: new-bare"
        return
    fi
    # Empty or only .gitignore/LICENSE?
    echo "classify: new-empty"
}

# classify: new-empty | new-bare | existing-bare | existing-source | already-configured
#
# The AI-config gate is factored out here; the underlying non-trinity class is
# computed by classify_project_state_no_ai (delegated). Behavior for the
# non-configured path is byte-unchanged from before the BD-285 refactor.
classify_project_state() {
    local target="${1:-.}"
    local ai
    ai=$(detect_ai_config "$target" | awk -F': ' '{print $2}')
    if [[ "$ai" != "(none)" ]]; then
        echo "classify: already-configured"
        return
    fi
    classify_project_state_no_ai "$target"
}

# Pack skill coverage table (per §7.8). Used for skill-gap detection.
#
# Per the v11 PLATFORM-SKILLS.md reframe (BD-142), skills load via a 5+3
# model: 5 dimensions (D1 substrate, D2 cross-platform languages, D3
# component role, D4 communication protocols, D5 deployment surface) and
# 3 orthogonal load mechanisms (Tier 0 base, intersection-cell, trigger-
# loaded). The per-language rows below emit each language's pack-bundled
# skill coverage; PLATFORM-SKILLS.md is authoritative for the dimension
# membership and the full intersection / trigger semantics.
#
# Args:
#   $1   Language marker (swift|python|proto|...).
#   $2   Optional target project directory. Used by the python row
#        (BD-141) to consult the python_data_marker_detected predicate
#        in scripts/lib/detect.sh; defaults to $TARGET if unset, else
#        the current working directory. Other rows ignore $2.
pack_skill_coverage_for() {
    local lang="$1"
    local target_dir="${2:-${TARGET:-.}}"
    case "$lang" in
        # swift: D1=ios|macos (D1-implied) + Apple-platform skills via D1.
        # BD-157: apple-swiftdata-patterns intersection-loads when the
        # canonical predicate `swiftdata_marker_detected()` matches
        # (markers: any `.swift` file with `import SwiftData` OR an
        # `@Model` attribute, OR a manifest listing SwiftData
        # explicitly — see scripts/lib/detect.sh). Mirrors the
        # BD-141 python and BD-156 proto cases. Uses a tight literal
        # comparison so a future helper-output change is caught at
        # compare time.
        # BD-158: swift-concurrency-patterns is D1-implied for D1 ∈
        # {ios, macos} (architecture §3.2 D1-implied semantics) — it
        # loads unconditionally for any Apple project alongside
        # swift-best-practices, with no marker predicate. Every Apple
        # project deals with concurrency. The skill carries Modern
        # Swift Concurrency rules (async/await, actors, Sendable,
        # Swift 6 strict checking, AsyncSequence / AsyncStream,
        # continuation bridging) and Grand Central Dispatch
        # (DispatchQueue selection, DispatchGroup, semaphore caveats,
        # barrier writes, QoS, DispatchSource, do-not-mix
        # anti-patterns, GCD ↔ async-await modernization).
        swift)
            local swiftdata_marker_line
            swiftdata_marker_line=$(swiftdata_marker_detected "$target_dir")
            if [[ "$swiftdata_marker_line" == "swiftdata-marker: yes" ]]; then
                echo "apple-architecture-core,swift-best-practices,swift-concurrency-patterns,apple-swiftdata-patterns"
            else
                echo "apple-architecture-core,swift-best-practices,swift-concurrency-patterns"
            fi
            ;;
        # python: D2=python (cross-platform language) + intersection-loaded data/server skills
        # BD-141: python-data-architecture loads only when the
        # concrete predicate matches (architecture §7.5).
        # BD-162: python-observability-patterns intersection-loads
        # when the canonical predicate
        # `python_observability_marker_detected()` matches (markers:
        # OpenTelemetry / Prometheus client / structured-logging
        # dependencies in requirements.txt / pyproject.toml /
        # setup.py / setup.cfg / uv.lock; OR source-file imports of
        # opentelemetry / prometheus_client / structlog — see
        # scripts/lib/detect.sh and the BD-162 architecture document
        # at maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md).
        # The "OR D3=server" branch of the architect §4.1
        # intersection predicate is intentionally NOT computed here:
        # init-project.sh does not have a D3 selector — it auto-
        # detects from language markers only. The D3=server load
        # path applies at PM-chat skill-selection time
        # (PLATFORM-SKILLS.md drives the agent prompts), not at
        # scaffold-time skill copying. stage_s4_skills copies ALL
        # pack skills to the per-CLI directories unconditionally,
        # so python-observability-patterns/SKILL.md is always
        # physically present after init; PM-chat decides which
        # agents load it per project shape.
        # python-best-practices is unconditional for python.
        # Compare against the full literal helper-output lines
        # rather than parsing — tighter contract; a future helper
        # output change is caught at compare time, not silently.
        # Build the comma-joined skill list via 0/1-style booleans
        # and conditional appends so the case-arm doesn't explode
        # combinatorially as more intersection skills are added.
        python)
            local data_marker_line obs_marker_line
            data_marker_line=$(python_data_marker_detected "$target_dir")
            obs_marker_line=$(python_observability_marker_detected "$target_dir")
            local skills="python-best-practices"
            [[ "$data_marker_line" == "python-data: yes" ]] && skills="$skills,python-data-architecture"
            [[ "$obs_marker_line" == "python-observability-marker: yes" ]] && skills="$skills,python-observability-patterns"
            echo "$skills"
            ;;
        # proto: D4=grpc + protobuf-patterns intersection (BD-156).
        # grpc-patterns loads unconditionally for the proto language
        # marker (a `.proto` file is itself a strong gRPC-D4 signal);
        # protobuf-patterns loads when the canonical predicate
        # `protobuf_marker_detected()` matches (the same `.proto`
        # presence will trigger it, but the predicate also matches
        # standalone protobuf scenarios — manifest-only signals — so
        # routing through the helper preserves the architecture §3.7
        # intersection-cell loading model).
        proto)
            local proto_marker_line
            proto_marker_line=$(protobuf_marker_detected "$target_dir")
            if [[ "$proto_marker_line" == "protobuf-marker: yes" ]]; then
                echo "grpc-patterns,protobuf-patterns"
            else
                echo "grpc-patterns"
            fi
            ;;
        *)          echo "" ;;  # No coverage
    esac
}

# ── Preview + confirmation ─────────────────────────────────────────────────

# Prints the detection report per §7.5 format.
print_preview() {
    local target="$1" pack="$2" classification="$3" language_markers="$4"
    cat <<EOF
init-project.sh detection report
=================================
Target project:  $target
Pack:            $pack  ($(detect_pack_version "$pack" | awk -F': ' '{print $2}'))

Classification:  $classification
$(detect_git_repo "$target")
$(detect_clean_working_tree "$target")

Language markers: $language_markers
$(detect_source_files "$target")

Existing AI config: $(detect_ai_config "$target" | awk -F': ' '{print $2}')

Pack skill coverage:
EOF
    local lang coverage
    local IFS=,
    for lang in $language_markers; do
        [[ "$lang" == "(none)" ]] && continue
        coverage=$(pack_skill_coverage_for "$lang" "$target")
        if [[ -n "$coverage" ]]; then
            echo "  $lang:   FULL ($coverage)"
        else
            echo "  $lang:   NO COVERAGE    <-- gap reported"
        fi
    done
    unset IFS
    cat <<'EOF'

Planned operations
------------------
  [ADD — new files and directories]  per stages S1–S7
  [MERGE — appended and deduplicated] .gitignore (stage S8)
  [CONDITIONAL REMOVE]               per stage S9 (language-aware)
  [END-OF-RUN OUTPUT]                PM chat kickoff prompt (stage S10)

Developer transition notice
---------------------------
After this run, the project will use the pack's file names and
locations as the standard going forward:
  - Agent config: .claude/, .codex/, .agents/
  - Context: CLAUDE.md, AGENTS.md, GEMINI.md at the project root
  - Methodology & templates: docs/pack/
  - Scripts: scripts/
  - Agent launcher: agent-run.sh at the project root

Existing README.md, LICENSE, language manifest, and project docs are
unchanged and will continue to be authoritative.
EOF
}

confirm_proceed() {
    # --yes bypasses the confirm entirely (automation / CI).
    if [[ "${YES:-0}" == "1" ]]; then return 0; fi
    # Interactive (a TTY, or forced) -> preview+confirm, default No (a human's
    # path is UNCHANGED). Non-TTY without --yes -> decline, naming --yes so the
    # scripted caller learns the automation flag (the fix for the silent CI
    # foot-gun).
    if prompt_should_interact "${NO_INTERACTIVE:-0}" "${INTERACTIVE:-0}"; then
        if prompt_confirm "Proceed?" "n"; then return 0; fi
        say "Declined. No changes made."; return 1
    fi
    say "Declined: non-interactive context and --yes not set."
    say "Re-run with --yes to install without prompting."
    return 1
}

# ── BD-285 C2 — handwritten-trinity guided branch ─────────────────────────
#
# Called from main() when detect_trinity_provenance == handwritten. Resolves
# the trinity handling, sets the module-level TRINITY_CHOICE (read by
# stage_s7_trinity), and reassigns the module-level CLASS via
# classify_project_state_no_ai so the S1..S11 stages route by the real project
# shape (not `already-configured`). Returns 0 to continue into main()'s
# preview/confirm/stages; a null/absent choice STOPs here (exit 20).
#
# P2/F5/N3 PINS:
#   * --trinity=keep|replace|merge (TRINITY_FLAG) is the SOLE trinity-automation
#     selector, honored INDEPENDENT of prompt_should_interact (N3).
#   * --yes alone does NOT name a trinity choice (F5): without --trinity, a
#     non-interactive run reaches the null-choice STOP below.
#   * The k/r/m prompt NEVER reuses confirm_proceed's YES→proceed idiom.
#   * A null/absent TRINITY_CHOICE STOPs and NEVER reaches stage_s7_trinity's
#     bare-cp path (the trinity is left byte-untouched).
handle_handwritten_trinity() {
    local choice=""
    if [[ -n "${TRINITY_FLAG:-}" ]]; then
        # Explicit --trinity= is honored independent of TTY / prompt state (N3).
        choice="$TRINITY_FLAG"
    elif prompt_should_interact "${NO_INTERACTIVE:-0}" "${INTERACTIVE:-0}"; then
        say ""
        say "A handwritten trinity (CLAUDE.md / AGENTS.md / GEMINI.md) was detected"
        say "in $TARGET. Choose how init should handle it:"
        say "  (k) keep    — keep your files live; save the pack versions as"
        say "                <file>.pack-template for manual reconcile"
        say "  (r) replace — install the pack trinity live; save yours as"
        say "                <file>.user-orig (recovery copy)"
        say "  (m) merge   — install the pack trinity live; save yours as"
        say "                <file>.user-orig; record a 2-way fold for the"
        say "                resolve-merge-conflicts skill"
        local reply
        if reply=$(prompt_choice "Trinity handling? [k/r/m]" "k,r,m"); then
            case "$reply" in
                k) choice="keep" ;;
                r) choice="replace" ;;
                m) choice="merge" ;;
            esac
        fi
        # EOF/closed-stdin (prompt_choice returns non-zero) leaves choice empty
        # → the null-choice STOP below (never a default-yes).
    fi

    if [[ -z "$choice" ]]; then
        say ""
        say "STOP — a handwritten trinity is present in $TARGET and no handling was"
        say "chosen. Re-run naming the trinity handling explicitly, e.g.:"
        say "  scripts/init-project.sh --trinity=merge   [target]"
        say "  scripts/init-project.sh --trinity=replace [target]"
        say "  scripts/init-project.sh --trinity=keep    [target]"
        say "(Your trinity files are left byte-untouched.)"
        exit "$EXIT_AI_CONFIG"
    fi

    TRINITY_CHOICE="$choice"
    # Reassign CLASS from the underlying non-trinity project shape.
    CLASS=$(classify_project_state_no_ai "$TARGET" | awk -F': ' '{print $2}')
    return 0
}

# ── Stages S1..S10 ─────────────────────────────────────────────────────────

stage_s1_skeleton() {
    say "── S1 — directory skeleton ──"
    mkdir -p "$TARGET/.claude/agents" "$TARGET/.codex/agents" \
             "$TARGET/.claude/skills" "$TARGET/.codex/skills" "$TARGET/.agents/skills" \
             "$TARGET/docs/pack" "$TARGET/docs/project" "$TARGET/docs/reference" \
             "$TARGET/scripts"
    # Verification
    local d
    for d in .claude/agents .codex/agents docs/pack scripts; do
        [[ -d "$TARGET/$d" ]] || fail_stage S1 "missing directory $d after creation"
    done
}

stage_s2_agents() {
    say "── S2 — copy pack agent files (Claude/Codex loose + Antigravity bundle) ──"
    local tool ext pack_src dst
    # Claude/Codex keep the loose per-CLI agent dirs.
    for tool in claude codex; do
        case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
        pack_src="$PACK/project-template/.${tool}/agents"
        dst="$TARGET/.${tool}/agents"
        [[ -d "$pack_src" ]] || fail_stage S2 "pack source missing: $pack_src"
        local f
        for f in "$pack_src"/*.${ext}; do
            [[ -e "$f" ]] || continue
            cp "$f" "$dst/"
        done
    done
    # Antigravity agents ship as a plugin BUNDLE (not loose) — stage the
    # whole client bundle dir.
    local bundle_src="$PACK/project-template/.agents-plugin/optiquity-agents"
    local bundle_dst="$TARGET/.agents-plugin/optiquity-agents"
    [[ -d "$bundle_src" ]] || fail_stage S2 "pack source missing: $bundle_src"
    mkdir -p "$TARGET/.agents-plugin"
    cp -R "$bundle_src" "$TARGET/.agents-plugin/"
    # Verify agent counts match pack
    local pack_count dst_count
    pack_count=$(find "$PACK/project-template/.claude/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    for tool in claude codex; do
        case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
        dst_count=$(find "$TARGET/.${tool}/agents" -maxdepth 1 -name "*.${ext}" | wc -l | tr -d ' ')
        (( dst_count == pack_count )) || \
            fail_stage S2 "agent count mismatch: .${tool}/agents has $dst_count, expected $pack_count"
    done
    local bundle_count
    bundle_count=$(find "$bundle_dst/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    (( bundle_count == pack_count )) || \
        fail_stage S2 "agent count mismatch: .agents-plugin/optiquity-agents/agents has $bundle_count, expected $pack_count"
}

stage_s3_configs() {
    say "── S3 — copy pack configs ──"

    # proj-path → pack-path map for K-class files where the pack-side
    # template lives under a different name. `.agents/mcp_config.json` is
    # Antigravity's workspace MCP config; the pack ships its template at
    # `.agents/mcp_config.json.example` (project-template/.gitignore blocks
    # the live `.agents/mcp_config.json` to protect against secrets; the
    # `.example` is committable). init-project writes the live
    # `mcp_config.json` from the example so Antigravity picks it up
    # immediately. Implemented as a function (not associative array) for
    # bash 3.2 compatibility (macOS default bash).
    pack_template_for_proj_path() {
        case "$1" in
            .mcp.json)               echo ".mcp.json.example" ;;
            .agents/mcp_config.json) echo ".agents/mcp_config.json.example" ;;
            *)                       echo "$1" ;;
        esac
    }

    local f
    for f in \
        .codex/config.toml \
        .codex/config.toml.example \
        .codex/requirements.toml \
        .claude/settings.json \
        .mcp.json \
        .agents/mcp_config.json \
    ; do
        local src_relpath
        src_relpath=$(pack_template_for_proj_path "$f")
        local pack_file="$PACK/project-template/$src_relpath"
        if [[ -f "$pack_file" ]]; then
            mkdir -p "$TARGET/$(dirname "$f")"
            # BD-285 P5: route structured configs through the PROTECTED path
            # (s3_config_copy → structured 2-way key-union driven off
            # customization_classify; .pack-template sidecar for a non-structured
            # collision; F6 parse-error fallback to existing_classifier_copy)
            # whenever a live file could need protection — an existing-* install
            # OR a GUIDED trinity install (TRINITY_CHOICE set). A handwritten-
            # trinity target with a lone user config and no language markers
            # reclassifies to new-empty/new-bare (classify_project_state_no_ai),
            # so gating on CLASS alone would silently plain-cp-overwrite that
            # config. Genuine greenfield (no TRINITY_CHOICE, new-* class) keeps
            # the plain cp — no live file to protect.
            if [[ -n "${TRINITY_CHOICE:-}" || "$CLASS" == existing-* ]]; then
                s3_config_copy "$pack_file" "$TARGET/$f" "$f"
            else
                cp "$pack_file" "$TARGET/$f"
            fi
        fi
    done
    [[ -f "$TARGET/.codex/config.toml" ]] || fail_stage S3 ".codex/config.toml missing after copy"
    [[ -s "$TARGET/.claude/settings.json" ]] || fail_stage S3 ".claude/settings.json empty or missing"
    [[ -f "$TARGET/.mcp.json" ]] || fail_stage S3 ".mcp.json missing after copy (Claude Code project MCP config)"
    [[ -f "$TARGET/.agents/mcp_config.json" ]] || fail_stage S3 ".agents/mcp_config.json missing after copy (Antigravity workspace MCP config)"
}

stage_s4_skills() {
    say "── S4 — distribute skills (SKILL.md only) ──"
    # Antigravity reads workspace skills at `.agents/skills/<name>/SKILL.md`.
    # The 3-way distribution is now claude/codex/agents.
    local skill_dir name tool dst_tool_dir
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex agents; do
            dst_tool_dir=".${tool}/skills/$name"
            mkdir -p "$TARGET/$dst_tool_dir"
            # For existing installs, route through the classifier-aware copy
            # so a project's pre-existing Antigravity skill layout is
            # preserved rather than overwritten (detect.sh classify path).
            if [[ "$CLASS" == existing-* ]]; then
                existing_classifier_copy "$skill_dir/SKILL.md" "$TARGET/$dst_tool_dir/SKILL.md"
            else
                cp "$skill_dir/SKILL.md" "$TARGET/$dst_tool_dir/SKILL.md"
            fi
        done
    done
    # Verify: every pack skill has three destination SKILL.md files
    local missing=0
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex agents; do
            if [[ ! -f "$TARGET/.${tool}/skills/$name/SKILL.md" ]]; then
                warn "missing .${tool}/skills/$name/SKILL.md"
                missing=1
            fi
        done
    done
    (( missing == 0 )) || fail_stage S4 "one or more skill copies missing"
}

stage_s5_scripts() {
    say "── S5 — copy scripts + agent-run.sh ──"
    local pack_scripts="$PACK/project-template/scripts"
    if [[ -d "$pack_scripts" ]]; then
        local f
        # Include DOTFILES: `*` skips leading-dot names, so a bare `*` would
        # drop client-shipped dotfiles (e.g. `.docs-gate-allowlist.txt`, which
        # validate-docs.sh reads — absent, it false-positives on a bare
        # install). The `.[!.]*` pattern adds dotfiles while excluding `.`/`..`.
        # The `-f` guard skips the literal pattern when nothing matches
        # (nullglob is not set) AND skips any stray subdirectory (e.g. a
        # gitignored `__pycache__`). The install map's family expansion applies
        # the same `.[!.]*` companion for the same reason, so the declared set
        # and the set installed here agree on dotfiles.
        for f in "$pack_scripts"/* "$pack_scripts"/.[!.]*; do
            [[ -f "$f" ]] || continue
            local name; name=$(basename "$f")
            if [[ "$CLASS" == existing-* ]]; then
                existing_classifier_copy "$f" "$TARGET/scripts/$name"
            else
                cp "$f" "$TARGET/scripts/"
            fi
        done
        chmod +x "$TARGET/scripts"/*.sh 2>/dev/null || true
    fi
    if [[ -f "$PACK/project-template/agent-run.sh" ]]; then
        if [[ "$CLASS" == existing-* ]]; then
            existing_classifier_copy "$PACK/project-template/agent-run.sh" "$TARGET/agent-run.sh"
        else
            cp "$PACK/project-template/agent-run.sh" "$TARGET/agent-run.sh"
        fi
        chmod +x "$TARGET/agent-run.sh" 2>/dev/null || true
    fi
    [[ -x "$TARGET/agent-run.sh" ]] || fail_stage S5 "agent-run.sh missing or not executable"
}

# stage_s5b_populate_pool — populate the TRACKED client capability pool.
#
# BD-200: materialize $TARGET/pack-capability-pool/ with the FULL conditional
# master roster so the client can ACTIVATE a capability (re-materialize its
# conditional files into the live tree) on a fresh clone with NO pack present.
#
# Language-INDEPENDENT: runs for EVERY install regardless of detected
# languages, so even a Swift-only project ships a COMPLETE pool. It runs after
# S5 and BEFORE S9 (S9 removes the *live-tree* copies for absent languages; the
# pool retains all masters — the two stages are independent).
#
# GAP-A (load-bearing, ADVERSARIAL-REVIEW §3.2): the ROOT conditional files
# (pyproject.toml / pyrightconfig.json / server/ / proto/) are NEVER installed
# into the live tree by any stage — only the conditional SCRIPTS are S5-copied.
# So the pool MUST be sourced DIRECTLY from $PACK/project-template/, not
# captured from the (never-populated-with-root-files) live tree.
#
# Roster is single-sourced: derived from capability_files() in
# project-template/scripts/capability-tables.sh (sourced pack->pack), so the
# pool set never drifts from the capability-resolution table. FRESH-INSTALL
# only — NO `pack update` refresh / wipe-repopulate (that is BD-202).
stage_s5b_populate_pool() {
    say "── S5b — populate capability pool (pack-capability-pool/) ──"
    local pack_pt="$PACK/project-template"
    local tables="$pack_pt/scripts/capability-tables.sh"
    [[ -f "$tables" ]] || fail_stage S5b "missing capability tables: $tables"
    # Source the single-source table (pack->pack read; sourceable-only,
    # no top-level side effects). Defines capability_files().
    # shellcheck source=../project-template/scripts/capability-tables.sh
    source "$tables"

    # Derive the conditional-master roster = union of capability_files() over
    # every capability the table knows. Keeping it derived (not hardcoded)
    # single-sources the roster against the capability-resolution table.
    local all_caps="language:python language:swift language:cpp language:c \
language:objc platform:macos platform:ios platform:android platform:web-browser \
platform:embedded-mcu protocol:grpc protocol:rest protocol:graphql \
protocol:realtime protocol:messaging protocol:soap deployment:apple \
deployment:linux-container role:python-server"
    local roster="" cap files
    for cap in $all_caps; do
        files=$(capability_files "$cap")
        [[ -n "$files" ]] && roster="$roster $files"
    done
    # Dedup + stable order.
    roster=$(printf '%s\n' $roster | sort -u)

    local pool="$TARGET/pack-capability-pool"
    mkdir -p "$pool"
    local rel copied=0 missing=0
    for rel in $roster; do
        local src="$pack_pt/$rel"
        local dst="$pool/$rel"
        if [[ ! -e "$src" ]]; then
            warn "pool master absent (skipped): $src"
            missing=$((missing + 1))
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        if [[ -d "$src" ]]; then
            cp -R "$src" "$(dirname "$dst")/"
        else
            cp "$src" "$dst"
        fi
        copied=$((copied + 1))
    done
    # Conditional scripts in the pool stay executable (they may be copied into
    # the live tree at activation time).
    chmod +x "$pool/scripts"/*.sh 2>/dev/null || true
    info "capability pool populated: $copied master(s) copied${missing:+, $missing absent}"
}

stage_s6_docs_pack() {
    say "── S6 — copy docs/pack/ content ──"
    local pack_docs="$PACK/project-template/docs/pack"
    if [[ ! -d "$pack_docs" ]]; then
        fail_stage S6 "pack source missing: $pack_docs"
    fi
    local f
    for f in "$pack_docs"/*.md; do
        [[ -e "$f" ]] || continue
        local name; name=$(basename "$f")
        if [[ "$CLASS" == existing-* ]]; then
            existing_classifier_copy "$f" "$TARGET/docs/pack/$name"
        else
            cp "$f" "$TARGET/docs/pack/"
        fi
    done
    # prompts/ directory (entire; 10 per-agent files; PROMPT-AUTHORING.md
    # was removed in v10.0 — directory guidance lives in METHODOLOGY.md
    # § Prompt Authoring Principles).
    mkdir -p "$TARGET/docs/pack/prompts"
    for f in "$pack_docs/prompts"/*.md; do
        [[ -e "$f" ]] || continue
        cp "$f" "$TARGET/docs/pack/prompts/"
    done
    # METHODOLOGY.md lives at `docs/pack/METHODOLOGY.md`.
    # Source path is `$PACK/supporting-docs/METHODOLOGY.md`; the docs/pack/*.md loop
    # above iterates `$PACK/project-template/docs/pack/`, which does not contain
    # METHODOLOGY — keep this as a separate copy.
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        mkdir -p "$TARGET/docs/pack"
        if [[ "$CLASS" == existing-* ]]; then
            existing_classifier_copy "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
        else
            cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
        fi
    fi
    # INSTALL-PROCEDURES.md (v10 BD-059): same pattern as METHODOLOGY.md.
    # Source: $PACK/supporting-docs/INSTALL-PROCEDURES.md. Hosts Procedures
    # 5 / 5-C / 5-S / 7 (relocated from METHODOLOGY).
    if [[ -f "$PACK/supporting-docs/INSTALL-PROCEDURES.md" ]]; then
        mkdir -p "$TARGET/docs/pack"
        if [[ "$CLASS" == existing-* ]]; then
            existing_classifier_copy "$PACK/supporting-docs/INSTALL-PROCEDURES.md" "$TARGET/docs/pack/INSTALL-PROCEDURES.md"
        else
            cp "$PACK/supporting-docs/INSTALL-PROCEDURES.md" "$TARGET/docs/pack/INSTALL-PROCEDURES.md"
        fi
    fi
    # Stale-root cleanup advisory: init-project.sh does NOT delete project files
    # (init warns; migrators remove. The historical
    # v9->v10 migrator was sunset in v11 per BD-121; the v10->v11 migrator and
    # any future migrators handle removals on their own paths.)
    if [[ "$CLASS" == existing-* && -f "$TARGET/METHODOLOGY.md" ]]; then
        warn "stale METHODOLOGY.md at project root — canonical location is docs/pack/METHODOLOGY.md (move or delete manually)"
    fi
    # Verify prompts dir content (10 per-agent files expected post-v10.0).
    local prompts_count
    prompts_count=$(find "$TARGET/docs/pack/prompts" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    (( prompts_count >= 10 )) || fail_stage S6 "docs/pack/prompts/ has $prompts_count files (expected ≥ 10)"
    # End-of-S6 blast-radius sweep (one match allowed: existing PROMPT-TEMPLATES ref in legacy docs — but expected zero in pack-installed files)
    blast_radius_sweep || exit "$EXIT_SWEEP"
}

stage_s7_trinity() {
    say "── S7 — copy trinity from pack template ──"
    # BD-285 C2: a handwritten-trinity target routes through the guided
    # keep/replace/merge branch (TRINITY_CHOICE set by handle_handwritten_trinity).
    # A null/absent TRINITY_CHOICE means a NON-guided install (normal fresh /
    # existing-source) — the standard routing below (never the guided branch).
    if [[ -n "${TRINITY_CHOICE:-}" ]]; then
        stage_s7_trinity_guided
        return
    fi
    local f
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        local pack_file="$PACK/project-template/$f"
        [[ -f "$pack_file" ]] || fail_stage S7 "pack template missing: $pack_file"
        if [[ "$CLASS" == existing-* ]]; then
            existing_classifier_copy "$pack_file" "$TARGET/$f"
        else
            cp "$pack_file" "$TARGET/$f"
        fi
    done
}

# ── BD-285 C2 — guided keep/replace/merge trinity install ──────────────────

# _s7_guarded_trinity_install THEIRS DST REL — the per-file GUARDED never-lose
# install for the merge (m) / replace (r) paths (BLOCKER-1). The caller MUST
# have already confirmed DST EXISTS (a live user trinity file). The order is
# NON-REORDERABLE and must be impossible to implement backwards:
#   1. CAPTURE OURS FIRST — cp the live DST (still OURS) to <DST>.user-orig.
#      N1 guard: a pre-existing <DST>.user-orig ⇒ fail_stage LOUD (never a
#      silent overwrite of a purpose-built recovery copy).
#   2. VERIFY THE SIDECAR — cmp -s the live DST against <DST>.user-orig while
#      DST still holds OURS; ANY mismatch ⇒ fail_stage LOUD, do NOT overwrite.
#   3. ONLY THEN OVERWRITE — cp the pack template (THEIRS) onto the live DST.
#      The pack template touches the live file LAST.
# Invariant: "stash-then-verify-then-overwrite; the pack template touches the
# live file ONLY after <DST>.user-orig is confirmed byte-equal to the pre-
# overwrite DST." Safe under `set -euo pipefail` (all three cp/cmp are valid).
_s7_guarded_trinity_install() {
    local theirs="$1" dst="$2" rel="$3"
    local sidecar="${dst}.user-orig"
    # N1 guard.
    if [[ -e "$sidecar" ]]; then
        fail_stage S7 "refusing to overwrite pre-existing sidecar $sidecar for $rel (reconcile it first)"
    fi
    # 1. CAPTURE OURS FIRST.
    cp "$dst" "$sidecar"
    # 2. VERIFY THE SIDECAR (DST still holds OURS here).
    if ! cmp -s "$dst" "$sidecar"; then
        fail_stage S7 "sidecar verification failed for $rel ($sidecar != live $rel before overwrite)"
    fi
    # 3. ONLY THEN OVERWRITE — pack template touches the live file LAST.
    cp "$theirs" "$dst"
}

# s7_reconcile_append_row REL — F8/SHOULD-2: record one merge-2way row into the
# PERSISTENT <TARGET>/.pack-install-reconcile/dispositions.tsv so the
# resolve-merge-conflicts skill (Case 3) can locate the install 2-way folds.
# The persistent dir is created HERE ONLY (lazily, on the first merge row) —
# NEVER by a no-trinity install (SHOULD-2). customization-preserve.sh is
# CONSUMED (its _cp_record writer + customization_preserve_init), NOT edited.
# Column 2 (class) = trinity; column 4 (action) = merge-2way (the wire token
# the F9 static check + the skill's Case-3 selector match).
s7_reconcile_append_row() {
    local rel="$1"
    if [[ -z "${_S7_RECONCILE_READY:-}" ]]; then
        _ensure_customization_lib \
            || fail_stage S7 "customization-preserve library missing (cannot record merge-2way)"
        customization_preserve_init "$TARGET/.pack-install-reconcile" ".user-orig" \
            || fail_stage S7 "failed to init .pack-install-reconcile state dir"
        _S7_RECONCILE_READY=1
    fi
    _cp_record "merged-with-customization" "trinity" "$rel" "merge-2way" \
        "${rel}.user-orig" "-" "install 2-way trinity fold (resolve-merge-conflicts Case 3)"
}

# stage_s7_trinity_guided — the k/r/m branch for a handwritten trinity.
#   keep (k):    user trinity stays LIVE; pack → <f>.pack-template. Reuses
#                existing_classifier_copy (absent-tolerant — a missing sibling
#                is plain-installed from the pack).
#   replace (r): F1-ordered install of the pack trinity + <f>.user-orig (pure
#                recovery copy); NO merge-2way row.
#   merge (m):   F1-ordered install + <f>.user-orig + a merge-2way row per
#                PRESENT file + the resolve-merge-conflicts hint ONCE.
# BLOCKER-1 absent-sibling arm: for r/m, a MISSING live sibling (e.g. a lone-
# CLAUDE.md starter's absent AGENTS.md/GEMINI.md) is a plain pack install with
# NO .user-orig and NO merge-2way row — so the skill's Case-3 locate never
# points at a .user-orig (OURS) that never existed.
stage_s7_trinity_guided() {
    local choice="${TRINITY_CHOICE}"
    local wrote_row=0
    local f
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        local pack_file="$PACK/project-template/$f"
        [[ -f "$pack_file" ]] || fail_stage S7 "pack template missing: $pack_file"
        local dst="$TARGET/$f"
        case "$choice" in
            keep)
                existing_classifier_copy "$pack_file" "$dst"
                ;;
            replace|merge)
                if [[ -f "$dst" ]]; then
                    _s7_guarded_trinity_install "$pack_file" "$dst" "$f"
                    if [[ "$choice" == "merge" ]]; then
                        s7_reconcile_append_row "$f"
                        wrote_row=1
                    fi
                else
                    # Absent sibling: plain pack install, NO sidecar, NO row.
                    cp "$pack_file" "$dst"
                fi
                ;;
            *)
                fail_stage S7 "internal: unexpected TRINITY_CHOICE '$choice'"
                ;;
        esac
    done
    if [[ "$choice" == "merge" && "$wrote_row" == "1" ]]; then
        say ""
        say "One or more trinity files were merge-installed: your original is saved"
        say "as <file>.user-orig and the pack version is now live. To fold your"
        say "customizations back into the pack structure, run the"
        say "resolve-merge-conflicts skill (Case 3 — install 2-way trinity fold)."
    fi
}

stage_s8_gitignore() {
    say "── S8 — merge .gitignore ──"
    local pack_gi="$PACK/project-template/.gitignore"
    if [[ ! -f "$pack_gi" ]]; then
        info "no pack .gitignore template — skipping"
        return
    fi
    local header="# --- AI Agent Config Pack additions (v11.0) ---"
    if [[ ! -f "$TARGET/.gitignore" ]]; then
        cp "$pack_gi" "$TARGET/.gitignore"
        return
    fi
    # Append-and-dedup: for each line in pack .gitignore, append if not present.
    local existing dup=0 added=0 line
    existing=$(cat "$TARGET/.gitignore")
    {
        printf '\n%s\n' "$header"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^# ]] && { printf '%s\n' "$line"; continue; }
            if printf '%s\n' "$existing" | grep -Fxq "$line"; then
                dup=$((dup + 1))
                continue
            fi
            printf '%s\n' "$line"
            added=$((added + 1))
        done < "$pack_gi"
    } >> "$TARGET/.gitignore"
    info ".gitignore merged: $added added, $dup duplicates skipped"
}

stage_s9_conditional_remove() {
    say "── S9 — conditional removal ──"
    # For new-empty / new-bare, copy everything (no removal).
    if [[ "$CLASS" == "new-empty" || "$CLASS" == "new-bare" ]]; then
        info "no language markers detected — keeping all conditional files"
        return
    fi
    local lm
    lm=$(detect_language_markers "$TARGET" | awk -F': ' '{print $2}')
    local has_swift=0 has_python=0 has_proto=0
    local IFS=,
    for lang in $lm; do
        case "$lang" in
            swift) has_swift=1 ;;
            python) has_python=1 ;;
            proto) has_proto=1 ;;
        esac
    done
    unset IFS

    local removed=0
    # OQ-6(b) defensive guard: project-added files prefixed with `x-` are
    # never deleted by pack-controlled removal sites, even when their
    # name happens to collide with a pack-roster filename in this loop.
    # The current loop iterates fixed pack-roster names so the guard is
    # defensive, but it pins the contract for future refactors.
    is_x_prefixed() { [[ "$(basename "$1")" == x-* ]]; }

    # BD-200 defensive guard: S9 must NEVER remove anything under the TRACKED
    # capability pool (pack-capability-pool/), which is populated by S5b and
    # retains ALL conditional masters regardless of detected languages. The
    # current S9 roster names no pool paths, so this is defensive — but it pins
    # the contract for future refactors, mirroring is_x_prefixed above.
    is_pool_path() {
        case "$1" in
            pack-capability-pool|pack-capability-pool/*) return 0 ;;
            *) return 1 ;;
        esac
    }

    # Python conditional removals
    if (( has_python == 0 )); then
        local f
        for f in pyproject.toml pyrightconfig.json \
                 scripts/bootstrap-python.sh scripts/format-python.sh \
                 scripts/validate-python.sh scripts/test-python.sh; do
            is_x_prefixed "$f" && continue
            is_pool_path "$f" && continue
            if [[ -e "$TARGET/$f" ]]; then
                rm -rf "$TARGET/$f"
                removed=$((removed + 1))
            fi
        done
        if [[ -d "$TARGET/server" ]] && ! is_x_prefixed "server" && ! is_pool_path "server"; then
            rm -rf "$TARGET/server"
            removed=$((removed + 1))
        fi
    fi
    # Swift conditional removals
    if (( has_swift == 0 )); then
        local f
        for f in scripts/bootstrap-swift.sh scripts/format-swift.sh \
                 scripts/validate-swift.sh scripts/test-swift.sh; do
            is_x_prefixed "$f" && continue
            is_pool_path "$f" && continue
            if [[ -e "$TARGET/$f" ]]; then
                rm -f "$TARGET/$f"
                removed=$((removed + 1))
            fi
        done
    fi
    # Proto conditional removals
    if (( has_proto == 0 )); then
        local f
        for f in scripts/proto-gen.sh scripts/validate-proto.sh; do
            is_x_prefixed "$f" && continue
            is_pool_path "$f" && continue
            if [[ -e "$TARGET/$f" ]]; then
                rm -f "$TARGET/$f"
                removed=$((removed + 1))
            fi
        done
        if [[ -d "$TARGET/proto" ]] && ! is_x_prefixed "proto" && ! is_pool_path "proto"; then
            rm -rf "$TARGET/proto"
            removed=$((removed + 1))
        fi
    fi
    info "conditional removal: $removed files/dirs removed"
}

stage_s10_kickoff_prompt() {
    say "── S10 — generate end-of-run PM chat kickoff prompt ──"
    local target_abs
    target_abs=$(cd "$TARGET" && pwd)
    local pack_ver
    pack_ver=$(detect_pack_version "$PACK" | awk -F': ' '{print $2}')
    # Compute skill gaps
    local lm
    lm=$(detect_language_markers "$TARGET" | awk -F': ' '{print $2}')
    local gaps=()
    local IFS=,
    for lang in $lm; do
        [[ "$lang" == "(none)" ]] && continue
        [[ -z "$(pack_skill_coverage_for "$lang" "$TARGET")" ]] && gaps+=("$lang")
    done
    unset IFS

    # Existing docs pointer (existing-project path only)
    local existing_docs=()
    if [[ "$CLASS" == existing-* ]]; then
        [[ -f "$TARGET/docs/ARCHITECTURE.md" ]] && existing_docs+=("docs/ARCHITECTURE.md")
        [[ -f "$TARGET/README.md" ]] && existing_docs+=("README.md")
    fi

    cat <<EOF

──── End-of-run PM chat kickoff prompt ────

You are the PM chat for [PROJECT_NAME at $target_abs].

The AI Agent Config Pack $pack_ver has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
the PM chat kickoff prompt (docs/pack/prompts/pm-chat.md,
Variant: kickoff).

PLATFORM-SKILLS.md was reframed in v11 to use 5 dimensions
(D1 substrate, D2 cross-platform languages, D3 component role,
D4 communication protocols, D5 deployment surface) plus 3 orthogonal
load mechanisms (Tier 0 base, intersection-cell, trigger-loaded).
Read §"How skill selection works" for the new framing before
generating prompts.
EOF
    if (( ${#existing_docs[@]} > 0 )); then
        echo ""
        echo "This is an existing project with prior documentation. Before"
        echo "proceeding with the usual context-file placeholder fill-in, read"
        echo "the following existing documents for context, and confirm with the"
        echo "developer which other existing docs they want you to read:"
        echo ""
        local d
        for d in "${existing_docs[@]}"; do
            echo "  - $d"
        done
        echo ""
        echo "If the developer points you at additional files (inline design notes,"
        echo "ADRs, wiki exports, etc.), read those too before generating"
        echo "architecture content."
    fi
    if (( ${#gaps[@]} > 0 )); then
        echo ""
        echo "init-project.sh detected language/platform markers for which this"
        echo "pack version has no skill coverage:"
        echo ""
        local g
        for g in "${gaps[@]}"; do
            echo "  - $g"
        done
        echo ""
        echo "When you complete kickoff, append an entry to"
        echo "docs/pack/PACK-FEEDBACK.md under the \"Language/platform coverage gaps\""
        echo "section, including:"
        echo "  - The language or platform name"
        echo "  - The project stage (from the PM chat kickoff output)"
        echo "  - A short note on the kinds of guidance the project would benefit from"
    fi
    echo ""
    echo "Run /pm-startup (or your CLI's equivalent), then apply the kickoff"
    echo "variant with the developer."
    echo ""
    echo "──── End of kickoff prompt ────"
}

# ── Stage S11 — v11 client-side artifacts (BD-080) ────────────────────────

stage_s11_v11_artifacts() {
    say "── S11 — v11 client artifacts (HELP-FRAGMENT, issue forms) ──"

    local copy_fn="cp"
    [[ "$CLASS" == existing-* ]] && copy_fn="existing_classifier_copy"

    # 1. HELP-FRAGMENT.md → docs/pack/, per the usual classifier-copy
    #    rule (developer-customizable).
    mkdir -p "$TARGET/docs/pack"
    if [[ -f "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" ]]; then
        "$copy_fn" "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" \
            "$TARGET/docs/pack/HELP-FRAGMENT.md"
    fi
    [[ -f "$TARGET/docs/pack/HELP-FRAGMENT.md" ]] \
        || fail_stage S11 "docs/pack/HELP-FRAGMENT.md missing after copy"

    # 2. tracker.toml.example — NO LONGER INSTALLED (BD-214, 2026-06-13).
    #    Tracker integration is deferred indefinitely and flat-file
    #    per-entry is the sole supported mode, so the flip-material config
    #    template is not copied to clients (design D-C). The dormant config
    #    record stays committed pack-side at
    #    project-template/tracker.toml.project-example for a future
    #    resumption; existing clients keep any inert copy (the BD-214 clamp
    #    makes it harmless).

    # 3. .github/ISSUE_TEMPLATE/* issue forms (BD-063).
    if [[ -d "$PACK/project-template/.github/ISSUE_TEMPLATE" ]]; then
        mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
        local form
        for form in "$PACK/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
            [[ -e "$form" ]] || continue
            local name; name=$(basename "$form")
            "$copy_fn" "$form" "$TARGET/.github/ISSUE_TEMPLATE/$name"
        done
    fi

    # 4. pm-help + pm-startup are ordinary pool skills (project-template/
    #    skills/{pm-help,pm-startup}/SKILL.md) distributed LOOSE to all
    #    three CLIs by stage S4 (claude/codex/agents). No explicit per-CLI
    #    copy block is needed here — Antigravity has no `.toml` command
    #    format, so the skill IS the command. The client help runner is
    #    project-template/scripts/pm-help.sh, an ordinary flat client
    #    script shipped by stage S5 — NO pack-side file is copied here
    #    (no dual-use; the ship-allowlist is empty per BD-257).

    # 5. Per-entry tree skeleton install (BD-166).
    #    Ships the project-side per-entry source-of-truth surface so
    #    a greenfield v11 client has the v11.0-shape skeleton from
    #    the first init. Four streams (backlog, implementation-plan,
    #    changelog, groupings — the fourth per BD-262/BD-263) each get
    #    `_rules.md` + `_intro.md`. No entry files
    #    (`TD-NNN.md`, `phase-N.md`, `GRP-NNN.md`, `YYYY-MM-DD-*.md`) —
    #    greenfield starts empty; entries are authored client-side. No
    #    `_toc.md` written directly — the TOC regenerator (step 7 below
    #    for greenfield) produces it as the empty seed.
    #
    #    Canonical templates are client-immutable per integration
    #    parent §3.3 + §9.7. We use `$copy_fn` so existing-* re-runs
    #    go through the `existing_classifier_copy` path (a
    #    customized `_rules.md` is preserved with the pack version
    #    written as a `.pack-template` sidecar for manual reconcile;
    #    BD-088 truthful-report territory).
    local pe_src pe_dst
    pe_src="$PACK/project-template/docs/project"
    pe_dst="$TARGET/docs/project"
    [[ -d "$pe_src/backlog" && -d "$pe_src/implementation-plan" && -d "$pe_src/changelog" && -d "$pe_src/groupings" ]] \
        || fail_stage S11 "canonical per-entry templates missing under project-template/docs/project/ (install incomplete)"

    mkdir -p "$pe_dst/backlog" "$pe_dst/implementation-plan" "$pe_dst/changelog" "$pe_dst/groupings"

    # backlog: _rules.md + _intro.md.
    [[ -f "$pe_src/backlog/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/backlog/_rules.md"
    [[ -f "$pe_src/backlog/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/backlog/_intro.md"
    "$copy_fn" "$pe_src/backlog/_rules.md" "$pe_dst/backlog/_rules.md"
    "$copy_fn" "$pe_src/backlog/_intro.md" "$pe_dst/backlog/_intro.md"

    # implementation-plan: _rules.md + _intro.md.
    [[ -f "$pe_src/implementation-plan/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/implementation-plan/_rules.md"
    [[ -f "$pe_src/implementation-plan/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/implementation-plan/_intro.md"
    "$copy_fn" "$pe_src/implementation-plan/_rules.md" "$pe_dst/implementation-plan/_rules.md"
    "$copy_fn" "$pe_src/implementation-plan/_intro.md" "$pe_dst/implementation-plan/_intro.md"

    # changelog: _rules.md + _intro.md.
    [[ -f "$pe_src/changelog/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/changelog/_rules.md"
    [[ -f "$pe_src/changelog/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/changelog/_intro.md"
    "$copy_fn" "$pe_src/changelog/_rules.md" "$pe_dst/changelog/_rules.md"
    "$copy_fn" "$pe_src/changelog/_intro.md" "$pe_dst/changelog/_intro.md"

    # groupings: _rules.md + _intro.md (BD-262 fourth stream; BD-263
    # provisioning). `GRP-NNN.md` entries are never shipped, never
    # overwritten; `_kinds.md` is never shipped (client-authored).
    [[ -f "$pe_src/groupings/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/groupings/_rules.md"
    [[ -f "$pe_src/groupings/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/groupings/_intro.md"
    "$copy_fn" "$pe_src/groupings/_rules.md" "$pe_dst/groupings/_rules.md"
    "$copy_fn" "$pe_src/groupings/_intro.md" "$pe_dst/groupings/_intro.md"

    # 6b. Integrity manifest — generate at install (hash the installed
    #     _rules.md). The baseline verify-immutable.sh checks the 4
    #     client-immutable _rules.md against; generating AFTER the
    #     _rules.md placement above makes the manifest reflect the
    #     actually-installed files. Generated for every class.
    bash "$PACK/scripts/immutable-manifest.sh" --client-tree "$TARGET" \
        || fail_stage S11 "immutable-manifest generation failed"
    [[ -f "$pe_dst/immutable-manifest.txt" ]] \
        || fail_stage S11 "docs/project/immutable-manifest.txt missing after generation"

    # 6. Empty-seed TOC regenerate (greenfield path only).
    #    For greenfield (CLASS=new-*) the project starts empty — no
    #    entry files exist — so the TOC regenerator produces the empty
    #    seed `_toc.md` for each stream. No monolithic mirror is
    #    generated: the per-entry tree + `_toc.md` is the sole source of
    #    truth and readable form (no `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`).
    #
    #    Existing-* path is skipped: an existing source project that
    #    runs init-project.sh (rare; would normally STOP at
    #    `already-configured`) should not have its tree disturbed. The
    #    v10→v11 migrator is the canonical path for clients with prior
    #    monolithic content.
    if [[ "$CLASS" == new-* ]]; then
        # Source the per-entry helpers. Helpers live at
        # $PACK/scripts/lib/per-entry/. Guard each source with a `type`
        # check so re-sourcing is a no-op (matches the per-entry
        # helpers' own convention at
        # scripts/lib/per-entry/decompose.sh:30-33 and the migrator-
        # private adapter at
        # scripts/lib/migrate-v10-to-v11/decompose.sh:85-100).
        local _pe_lib_dir="$PACK/scripts/lib/per-entry"
        [[ -d "$_pe_lib_dir" ]] \
            || fail_stage S11 "per-entry helpers missing at $_pe_lib_dir (install incomplete)"
        if ! type pe_die >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/_lib.sh"
        fi
        if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/toc-regenerate.sh"
        fi

        # Four project-side streams. Each tuple: stream_key + relative
        # stream directory.
        local pe_spec pe_key pe_dir_rel pe_dir
        for pe_spec in \
            "project-backlog|docs/project/backlog" \
            "project-implementation-plan|docs/project/implementation-plan" \
            "project-changelog|docs/project/changelog" \
            "project-groupings|docs/project/groupings"; do
            pe_key="${pe_spec%%|*}"
            pe_dir_rel="${pe_spec##*|}"
            pe_dir="$TARGET/$pe_dir_rel"

            # Empty-seed TOC regenerate. Always produces _toc.md.
            per_entry_regenerate_toc "$pe_key" "$pe_dir" \
                || fail_stage S11 "per_entry_regenerate_toc failed for $pe_key (greenfield empty TOC)"
        done

        info "per-entry skeleton installed under docs/project/{backlog,implementation-plan,changelog,groupings}/ (per-entry tree + _toc.md; no monolithic mirror)"
    fi
}

# ── R1 baseline seed (fresh install) ───────────────────────────────────────
#
# ORIGINATE the BASE-cascade rung-R1 ledger this install's client will need
# the FIRST time they run `--update`.
#
# Without it that first run has no merge BASE for any file: a pack-shipped
# file the client edited is not a blob the pack has held (R2 says no), BASE
# stays empty (R3'), and the classifier answers `project-shadows-new-pack` —
# the pack version installed over their edit, their bytes parked in a
# `.pre-update` sidecar. The ledger was only ever written BY an update FOR
# the next update, so every client lost their customizations on the first
# update of their life and preserved correctly from the second onward.
#
# DERIVED FROM THE INSTALL MAP, not from a hand list and not by instrumenting
# eleven copy sites: the map is the one declaration of what the pack ships,
# and `cmd_update` resolves its own dispatch set from the same rows, so the
# seeded set and the set the next run looks up cannot disagree. The
# `cmd_update` token is the right filter for the same reason — a row the next
# `--update` never dispatches is a row it never looks up.
#
# DEST-EXISTS is the second filter and it is load-bearing: a row this install
# did not land (a conditional file S9 removed, a stage that did not run) must
# NOT get a ledger row, or the next run would materialise a BASE for a file
# the client never received and read its absence as a deliberate client
# deletion.
#
# The recorded blob is the PACK SOURCE's, per the ledger contract — the common
# ancestor the next three-way diffs against — even on the arms where DEST does
# not hold it (a `keep` collision leaves the client's own file live). That is
# the same value `cmd_update` records for the same path, so the seed and a
# subsequent update agree.
#
# COST: one map parse (memoised) plus ONE `git hash-object --stdin-paths` pass
# for the whole set. No fork per file.
#
# NON-FATAL by contract: the ledger is an accelerator, and an install that
# cannot write one still installed correctly. It is LOUD, though — a silent
# skip is exactly the failure mode that let this ship.
seed_r1_ledger() {
    say "── R1 baseline ledger ──"

    local lib_dir="$PACK/scripts/lib"
    local why=""
    if [[ ! -f "$lib_dir/install-map.sh" ]]; then
        why="install-map library missing under $lib_dir"
    elif ! _ensure_customization_lib; then
        why="customization-preserve library missing under $SCRIPT_DIR/lib"
    fi
    if [[ -n "$why" ]]; then
        warn "R1 baseline ledger NOT written ($why); the first \`--update\` will route every pack file you customize to reconciliation with a .pre-update sidecar"
        return 0
    fi
    if ! declare -F install_map_dispatch_set >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        source "$lib_dir/install-map.sh"
    fi

    local dispatch=""
    if ! dispatch=$(install_map_dispatch_set cmd_update) || [[ -z "$dispatch" ]]; then
        warn "R1 baseline ledger NOT written (install map declares no cmd_update rows); the first \`--update\` will route every pack file you customize to reconciliation with a .pre-update sidecar"
        return 0
    fi

    local stage
    stage=$(mktemp "${TMPDIR:-/tmp}/init-r1.XXXXXX") || {
        warn "R1 baseline ledger NOT written (no writable temp); the first \`--update\` will route every pack file you customize to reconciliation with a .pre-update sidecar"
        return 0
    }

    # Column 4 records THIS run's origin rather than a three-way verdict:
    # a fresh install computed no classification for these paths, and
    # manufacturing one would be a claim the run never made. The column is
    # provenance for a human reading the ledger; the R1 READ join reads
    # columns 1 and 3 only.
    local row rest pack_rel proj_rel
    while IFS= read -r row; do
        [[ -n "$row" ]] || continue
        pack_rel="${row%%:*}"
        rest="${row#*:}"
        proj_rel="${rest%%:*}"
        [[ -f "$PACK/$pack_rel" ]] || continue
        [[ -f "$TARGET/$proj_rel" ]] || continue
        printf '%s\t%s\t%s\t%s\n' \
            "$proj_rel" "$pack_rel" "fresh-install" "$PACK/$pack_rel" >> "$stage"
    done <<< "$dispatch"

    # LEDGER-ONLY init: `.pack-update/` is the update mechanism's state dir and
    # the first path the R1 READ loop consults. A full customization_preserve_init
    # would also publish an empty dispositions.tsv + diffs/ there, which reads
    # as "an --update ran and found nothing" — a claim this install cannot make.
    # `.pack-install-reconcile/` is deliberately NOT used: its PRESENCE is the
    # signal a `--trinity=merge` fold is pending (INSTALL-PROCEDURES.md
    # "State-dir lifecycle"), and creating it on every install would destroy
    # that signal.
    if ! customization_preserve_ledger_init "$TARGET/.pack-update"; then
        rm -f "$stage"
        warn "R1 baseline ledger NOT written (cannot create $TARGET/.pack-update); the first \`--update\` will route every pack file you customize to reconciliation with a .pre-update sidecar"
        return 0
    fi
    customization_preserve_ledger_flush "$stage"
    rm -f "$stage"

    local rows
    rows=$(awk 'substr($0, 1, 1) != "#" && NF > 0' \
        "$TARGET/.pack-update/$_CP_LEDGER_BASENAME" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "${rows:-0}" -gt 0 ]]; then
        info "R1 baseline ledger written: $rows row(s) at .pack-update/ledger.tsv (lets the first --update preserve your edits to pack files)"
    else
        warn "R1 baseline ledger is EMPTY; the first \`--update\` will route every pack file you customize to reconciliation with a .pre-update sidecar"
    fi
}

# ── --update mode (BD-080) ─────────────────────────────────────────────────
#
# Refresh a previously-installed pack to the current pack version using the
# BD-088 customization-preservation contract. Does NOT run the full S1..S10
# install — that path is for fresh installs only. --update is conservative:
# it only touches files the BD-088 library knows how to dispatch, records a
# truthful report at .pack-update/report.md, and never overwrites a project
# customization without writing a sidecar (per BD-088 contract).

# Resolve the merge BASE for ONE text-class file, per the four-rung cascade.
# Sets `_CU_BASE` ("" = no base), `_CU_BASE_TMP` (a materialised temp the
# caller must remove), and `_CP_OURS_BLOB` (read by customization-preserve.sh
# for the R2 recoverability note).
#
#   R1  a prior run's ledger names the blob it installed here — materialise it
#   R2  OURS is itself a blob the pack has held at this SOURCE path, so OURS
#       IS a pack baseline — pass OURS as BASE
#   R3' OURS is not provably pack-authored — BASE stays EMPTY, which routes to
#       project-shadows-new-pack, i.e. needs-reconciliation with a sidecar and
#       a three-way diff
#   R4' the run cannot reach the baseline anchor — BASE stays EMPTY for every
#       file, i.e. R3' semantics run-wide
#
# R3' keeps the EMPTY base deliberately. A base that made the classifier answer
# `merged-with-customization` would keep the client's file, drop the pack
# update, and write neither sidecar nor diff — stale content, silently. An
# empty base costs a sidecar the client may not need: noisy, never stale.
#
# R1's prior-run sha is NOT searched for here. The caller joins the whole
# prior ledger onto the dispatch set in ONE awk pass before the loop and hands
# each row's sha in as $3, because a per-file lookup is what makes this
# function's cost compound: searching a ~35 KB ledger string with a
# leading-`*` parameter expansion is quadratic on bash 3.2 (the macOS system
# shell, and this script carries no version guard), and 260 of them dominated
# the whole `--update` wall clock. Costs per call, measured: ZERO forks on an
# R1 miss, and THREE on a hit (`mktemp` + `cat-file` + `rm`) — the sole
# remaining per-file forks in the cascade.
_cmd_update_resolve_base() {
    local pack_rel="$1" ours="$2" sha="$3"
    _CU_BASE=""
    _CU_BASE_TMP=""
    _CP_OURS_BLOB=""

    # R4' — evaluated once per run by the caller; nothing here can establish
    # provenance without the baseline objects.
    [[ "${_CU_BASELINE_OK:-0}" -eq 1 ]] || return 0
    # No installed file means there is nothing to establish a baseline for.
    [[ -n "$ours" ]] || return 0

    # R1 — materialise the blob the prior run recorded for this path.
    if [[ -n "$sha" ]]; then
        local tmp=""
        tmp=$(mktemp "${TMPDIR:-/tmp}/cu-base.XXXXXX") || tmp=""
        if [[ -n "$tmp" ]]; then
            if git -C "$PACK" cat-file blob "$sha" > "$tmp" 2>/dev/null; then
                _CU_BASE="$tmp"
                _CU_BASE_TMP="$tmp"
                return 0
            fi
            rm -f "$tmp"
        fi
    fi

    # R2 — the probe is keyed by the PACK SOURCE path, never the client
    # relpath (pack-provenance.sh header); the dispatch triple carries it.
    local blob=""
    if blob=$(pack_provenance_is_pack_authored "$pack_rel" "$ours" 2>/dev/null); then
        _CU_BASE="$ours"
        _CP_OURS_BLOB="$blob"
        return 0
    fi

    # R3' — leave BASE empty.
    return 0
}

# Resolve the provenance answers for ONE STRUCTURED-class file WITHOUT
# resolving a BASE. Sets `_CP_OURS_PACK_AUTHORED` (1 = OURS is itself a blob
# the pack has held at this SOURCE path), `_CP_OURS_BLOB`, and
# `_CP_OURS_PACK_SOURCE` (the SOURCE path itself).
#
# Deliberately NOT `_cmd_update_resolve_base`: that function's job is to hand
# the classifier a BASE, and the SCOPING GATE below documents why a non-empty
# BASE must never reach a structured file. This one answers the SAME question
# and hands the answer over as a separate signal, so the structured strategy
# can act on the proof while the classifier keeps seeing an empty BASE.
#
# TWO GRANULARITIES, ONE RUNG. `_CP_OURS_PACK_AUTHORED` answers WHOLE-FILE and
# clears only a client who never touched the file. `_CP_OURS_PACK_SOURCE`
# carries the key the merge helper needs to answer the same question PER KEY,
# which is the only thing that reaches a client who edited anything at all —
# and their frozen key is generally not the key they edited, so the whole-file
# answer alone leaves the pack's change undelivered indefinitely.
#
# R1 has no analogue here on purpose. The ledger blob is a DIFFERENT blob from
# OURS, so consuming it would mean supplying a base — exactly what the gate
# forbids. R2 is the only rung whose answer is a property OF OURS.
#
# Cost: ONE index membership test plus ONE `git hash-object` fork per
# structured file (the index itself is built once per run by
# pack_provenance_init), over the 6 structured rows in the whole dispatch set
# — no per-file object walk. The per-key derivation costs two further forks,
# but only on the files that actually reach the key-merge.
_cmd_update_probe_pack_authored() {
    local pack_rel="$1" ours="$2"
    _CP_OURS_PACK_AUTHORED=0
    _CP_OURS_BLOB=""
    _CP_OURS_PACK_SOURCE=""

    # R4' — same whole-run gate the base cascade obeys: without the baseline
    # objects nothing can establish provenance. The per-key derivation is
    # gated here too, and for a sharper reason than symmetry: it reads the
    # object history, so a clone missing the baseline would derive an ancestor
    # from the recent blobs alone. That ancestor claims the client REMOVED
    # every list element the pack has added since — turning today's harmless
    # key-union into a silent deletion. Unreachable baseline therefore keeps
    # exactly today's behaviour, and the operator already has the notice and
    # the `git fetch` remedy from pack_provenance_baseline_reachable.
    [[ "${_CU_BASELINE_OK:-0}" -eq 1 ]] || return 0
    [[ -n "$ours" ]] || return 0

    _CP_OURS_PACK_SOURCE="$pack_rel"

    local blob=""
    if blob=$(pack_provenance_is_pack_authored "$pack_rel" "$ours" 2>/dev/null); then
        _CP_OURS_PACK_AUTHORED=1
        _CP_OURS_BLOB="$blob"
    fi
    return 0
}

# BASE-cascade rung R1 WRITE. Pair the staged rows with the blob shas of the
# files this run installed, and hand each to the ledger.
#
# The one-pass hash + record idiom lives in customization-preserve.sh, beside
# the record writer and the ledger's own contract, because THREE paths
# originate a ledger now (this one, the fresh-install seed below, and the
# migrator's map-derived install). A second copy here would let the recorded
# shape drift between them, and the shape is what the R1 READ join parses.
_cmd_update_write_ledger() {
    customization_preserve_ledger_flush "$1"
}

# ── the `.resolved` companion's CONTENT BINDING ──────────────────────────
#
# `<sidecar>.resolved` is the client's second reconciliation signal (the
# BD-095 two-signal contract). Honouring its mere EXISTENCE turns it into a
# permanent opt-out for that path: nothing in the tree ever clears the flag,
# and the shipped docs tell the client to keep it and commit it, so every
# LATER, DIFFERENT, unreconciled sidecar at that path would be waved through
# in silence, forever. Measured on the pre-binding gate: a stale flag against
# a brand-new differing sidecar exited 0 and never named the file, while the
# same tree with the flag removed exited 50.
#
# So the flag is bound to the sidecar CONTENT it was created for. A flag the
# client has just `touch`ed carries no stamp, and the first run that honours
# it records the sidecar's hash into it. From then on it exempts THAT
# reconciliation and no other: when the sidecar's bytes change, the client's
# prior content has been parked again — a new reconciliation event — and the
# gate says so instead of staying silent.
#
# Fail CLOSED. No hash tool, an unreadable flag, or a stamp that does not
# match all mean NO exemption; the run falls through to the byte-identity
# check and blocks if that does not cover it either. An exemption that cannot
# verify its own basis is the escape hatch this binding exists to remove.
#
# COST: one hash per FLAGGED sidecar, computed only where a flag exists —
# never one per file. A run with no flagged sidecars forks nothing here.
_CU_RESOLVED_STAMP_PREFIX='pack-resolved-sidecar-sha256: '

# Hash one file. `shasum -a 256` first (BSD/macOS ship it), `sha256sum`
# second (GNU/Linux) — the same order dry-run.sh and immutable-manifest.sh
# use. Non-zero when neither exists, which the caller treats as "no
# exemption".
_cu_sidecar_sha() {
    local out
    if command -v shasum > /dev/null 2>&1; then
        out=$(shasum -a 256 "$1" 2>/dev/null) || return 1
    elif command -v sha256sum > /dev/null 2>&1; then
        out=$(sha256sum "$1" 2>/dev/null) || return 1
    else
        return 1
    fi
    [[ -n "$out" ]] || return 1
    printf '%s\n' "${out%% *}"
}

# Return 0 only when `<sidecar>.resolved` exempts this sidecar's CURRENT
# content. Reading the flag is pure bash (no fork); the single fork is the
# hash, and only when a flag is actually present.
_cu_resolved_flag_binds() {
    local sc_file="$1" flag="$1.resolved" line recorded='' current
    [[ -f "$flag" ]] || return 1
    current=$(_cu_sidecar_sha "$sc_file") || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            "$_CU_RESOLVED_STAMP_PREFIX"*)
                recorded=${line#"$_CU_RESOLVED_STAMP_PREFIX"}
                break
                ;;
        esac
    done < "$flag"
    if [[ -z "$recorded" ]]; then
        # An unstamped flag is the client's fresh, explicit act. Honour it
        # and BIND it, so it cannot silently cover a different sidecar later.
        printf '%s%s\n' "$_CU_RESOLVED_STAMP_PREFIX" "$current" >> "$flag" \
            || return 1
        return 0
    fi
    [[ "$recorded" == "$current" ]]
}

cmd_update() {
    say "── --update — refresh v11 artifacts via customization-preserve ──"

    # Pre-check: target must be currently pack-configured (else this is a
    # fresh install, not an update).
    if [[ ! -f "$TARGET/CLAUDE.md" || ! -d "$TARGET/.claude" ]]; then
        die "target is not currently pack-configured (CLAUDE.md or .claude/ missing); run init-project.sh without --update for a fresh install" \
            "$EXIT_UPDATE_NOT_CONFIGURED"
    fi

    # Pre-check: BD-088 library must be available.
    local lib_dir="$PACK/scripts/lib"
    if [[ ! -f "$lib_dir/three-way.sh" \
       || ! -f "$lib_dir/customization-preserve.sh" \
       || ! -f "$lib_dir/customization-report.sh" \
       || ! -f "$lib_dir/install-map.sh" \
       || ! -f "$lib_dir/pack-provenance.sh" ]]; then
        die "customization library missing under $lib_dir; cannot --update" \
            "$EXIT_UPDATE_LIB_MISSING"
    fi

    # Pre-check: refuse to proceed if any *.pre-update sidecars from a
    # prior --update run still exist. Single-slot sidecars must be
    # reconciled before re-running, else the second run silently
    # overwrites them and destroys the user's pre-update content.
    #
    # THE ESCAPE: a sidecar whose bytes are IDENTICAL to the live file it
    # shadows is exempt. Without the exemption this gate has a state with no
    # way out. A structured file the client edited in a way that warns every
    # run — deleting a whole key the pack is still editing is the measured
    # case — is re-sidecarred every run, and because the merge honours the
    # removal the live file never changes, so each new sidecar is a byte-copy
    # of it. The gate then blocked the WHOLE tree's refresh on a file whose
    # sidecar preserved nothing, and the only offered remedy (delete the
    # sidecar) was answered by the next run re-creating it.
    #
    # The exemption costs the gate nothing, and that is a property of the
    # gate's own rationale rather than a judgement call: the content it
    # protects is the client's pre-update bytes, and those bytes are still in
    # the live file, so overwriting this sidecar cannot destroy them. Any
    # sidecar that DIFFERS from its live file still blocks — that one has real
    # unreconciled content, and its block terminates, because reconciling the
    # file is an act the client can actually complete.
    #
    # Nothing is deleted here. An exempt sidecar is left on disk and is simply
    # not treated as a blocker; the next run overwrites it with the same bytes.
    #
    # THE SECOND SIGNAL: a `<sidecar>.resolved` companion is equally exempt.
    # This is the BD-095 two-signal contract the migrator's resume + Gate-2
    # checkpoints already implement (`scripts/lib/migrate-v10-to-v11/
    # resume.sh`, `checkpoint.sh`): a sidecar is reconciled when it is REMOVED
    # **or** when the client flags it resolved and keeps it as a record. Both
    # signals mean the same thing, and honouring only one made `--update`
    # contradict its OWN report: `customization_report` — which cmd_update
    # renders to `.pack-update/report.md` at the end of every run — tells the
    # client, for every needs-reconciliation row, to "mark it resolved (remove
    # the sidecar or add its .resolved companion)". A client who took the
    # second option was then refused by the next run, with the flag file
    # sitting right beside the sidecar it was created to clear.
    #
    # The byte-identity exemption above cannot cover this case and never
    # could: a file the client CORRECTLY merged differs from its sidecar by
    # definition — that difference IS the merge — so `cmp` is guaranteed to
    # say "differs" for exactly the state `.resolved` exists to describe.
    #
    # Costs the gate nothing it was protecting: the flag is an explicit client
    # act on that one file, which is the same act removing the sidecar was.
    # A sidecar with neither signal still blocks.
    #
    # The flag is bound to the sidecar CONTENT it was created for — see
    # `_cu_resolved_flag_binds` above. It therefore exempts ONE
    # reconciliation, not the path forever: when the sidecar's bytes change,
    # the client's prior content has been parked again and the gate blocks
    # again. A flag that does not bind falls through to the byte-identity
    # check below, exactly as if it were absent.
    local stale_sidecars sc_file sc_live
    stale_sidecars=$(
        find "$TARGET" -type f -name "*.pre-update" \
            -not -path "*/.pack-update/*" -not -path "*/.git/*" 2>/dev/null \
        | while IFS= read -r sc_file; do
              if _cu_resolved_flag_binds "$sc_file"; then
                  continue
              fi
              sc_live="${sc_file%.pre-update}"
              if [[ -f "$sc_live" ]] && cmp -s "$sc_file" "$sc_live"; then
                  continue
              fi
              printf '%s\n' "$sc_file"
          done | head -20
    )
    if [[ -n "$stale_sidecars" ]]; then
        say "refusing to proceed: prior --update sidecars present:"
        printf '  %s\n' $stale_sidecars >&2
        die "reconcile or remove the .pre-update sidecars above before re-running --update — or keep one as a record by adding its .resolved companion (touch <sidecar>.resolved). A .resolved companion exempts only the sidecar CONTENT it was created for; if a sidecar listed above already has one, its bytes have changed since you resolved it — reconcile them, then re-flag it with: rm <sidecar>.resolved && touch <sidecar>.resolved" \
            "$EXIT_UPDATE_NOT_CONFIGURED"
    fi

    # Source libs and initialize state.
    # shellcheck source=lib/customization-preserve.sh
    export _CP_PACK_ROOT="$PACK"
    # shellcheck disable=SC1091
    source "$lib_dir/three-way.sh"
    # shellcheck disable=SC1091
    source "$lib_dir/customization-preserve.sh"
    # shellcheck disable=SC1091
    source "$lib_dir/customization-report.sh"
    # shellcheck disable=SC1091
    source "$lib_dir/install-map.sh"
    # shellcheck disable=SC1091
    source "$lib_dir/pack-provenance.sh"

    local state_dir="$TARGET/.pack-update"

    # The set of files --update touches, DERIVED from the install map below:
    # every row whose `[stage:]` carries `cmd_update`, with family rows
    # expanded to concrete files and their DEST brace groups fanned out.
    # Enumerated ONCE for the whole run, never per file.
    #
    # Each emitted triple is `pack_relpath:project_relpath:class`:
    #   pack_relpath     — path under $PACK (or $PACK/project-template/)
    #   project_relpath  — path under $TARGET
    #   class            — explicit class for customization_preserve; EMPTY
    #                      means self-classify (no class argument is passed).
    #                      That is what the Antigravity bundle needs: its dir
    #                      mixes pack agents (pack-agent, replace-if-different)
    #                      with client `x-` customs (custom-agent, preserved),
    #                      so a forced class would three-way a custom and risk
    #                      sidecaring it.
    #
    # Resolved FIRST, before this function touches anything. It reads only the
    # map, so it has no ordering dependency on the state dir or the ledger —
    # and running it here means both `die`s below fire before `rm -rf
    # "$state_dir"` has destroyed the prior ledger the cascade reads, and
    # before any temp file exists to leak on the way out.
    local dispatch
    dispatch=$(install_map_dispatch_set cmd_update) \
        || die "install map is unreadable; cannot --update" \
               "$EXIT_UPDATE_LIB_MISSING"

    # The parser's non-empty floor guards each BLOCK; the stage-token filter
    # runs AFTER it, so a map whose blocks parse but whose `cmd_update` axis
    # selects nothing still returns rc 0 with zero rows. There is no legitimate
    # pack in which `--update` has nothing to dispatch, so treat that as the
    # same failure an unreadable map is: without this, a mistyped stage token
    # makes `--update` exit 0 having refreshed not one file.
    [[ -n "$dispatch" ]] \
        || die "install map declares no cmd_update rows; cannot --update" \
               "$EXIT_UPDATE_LIB_MISSING"

    # BASE-cascade rung R1 READ. The ledger the run that put the pack here
    # left behind names the blob it installed at each path; it must be copied
    # OUT BEFORE the state dir is cleared two lines down, or the cascade would
    # delete its own input. Every origination path is enumerated, because the
    # FIRST `--update` in a client's life is the one with no prior update to
    # read from, and it is the run that reverts their work if it finds
    # nothing:
    #
    #   `.pack-update/`             a prior `--update`, or this client's own
    #                               fresh-install seed (seed_r1_ledger below)
    #   `.pack-install-reconcile/`  a `--trinity=merge` install
    #   `.pack-migrate-*/`          a migration's state dir
    #
    # All three are directories those paths already create, so no new
    # client-tree artefact appears. Order is most-recent-authority first: a
    # later run's record supersedes the arrival-path seed at the same path.
    # An unmatched `.pack-migrate-*` glob stays literal and simply fails the
    # `-s` test, so no `nullglob` (a global shell-option change) is needed.
    # The filename comes from the library that writes it, never a second copy.
    #
    # Kept as a FILE, never slurped into a shell string: the join below reads
    # it in one `awk` pass, and a whole-ledger string is what made the old
    # per-file lookup quadratic (see _cmd_update_resolve_base).
    local prior_ledger=""
    local _cu_prior
    for _cu_prior in "$state_dir/$_CP_LEDGER_BASENAME" \
                     "$TARGET/.pack-install-reconcile/$_CP_LEDGER_BASENAME" \
                     "$TARGET"/.pack-migrate-*/"$_CP_LEDGER_BASENAME"; do
        if [[ -s "$_cu_prior" ]]; then
            prior_ledger=$(mktemp "${TMPDIR:-/tmp}/cu-prior.XXXXXX") || prior_ledger=""
            if [[ -n "$prior_ledger" ]]; then
                # A failed `cp` disables the accelerator, and the temp it
                # would have filled is removed HERE: blanking the variable is
                # what makes the `rm -f` at the end of the join block
                # unreachable, so without this the partial file survives the
                # run.
                if ! cp "$_cu_prior" "$prior_ledger"; then
                    rm -f "$prior_ledger"
                    prior_ledger=""
                fi
            fi
            break
        fi
    done

    rm -rf "$state_dir"
    customization_preserve_init "$state_dir" ".pre-update"

    # R4' — the whole-run baseline gate, evaluated ONCE before the loop.
    # Without the baseline objects no rung can establish provenance, so every
    # file falls back to R3' semantics. The run PROCEEDS rather than dying:
    # under R3' DEST still becomes THEIRS, so nothing is left stale — the cost
    # is a spurious sidecar, which is noisy, never stale.
    # pack_provenance_baseline_reachable prints the condition and the
    # `git fetch origin v10:v10` remedy on stderr.
    _CU_BASELINE_OK=1
    if ! pack_provenance_baseline_reachable "$PACK"; then
        _CU_BASELINE_OK=0
        say "NOTE: the pack baseline is unreachable, so provenance cannot be"
        say "      established; every file whose content differs from the pack"
        say "      is routed to manual reconciliation with a .pre-update sidecar."
    fi

    # Build the provenance index ONCE, in THIS shell. pack_provenance_init
    # memoises into the shell it runs in, so letting the first probe build it
    # inside a `$(...)` subshell would discard the memo every time and re-walk
    # the object store once per file (pack-provenance.sh constraint 1).
    if [[ "$_CU_BASELINE_OK" -eq 1 ]]; then
        pack_provenance_init "$PACK" || _CU_BASELINE_OK=0
    fi

    # R1 READ, resolved for the WHOLE RUN in one pass. Attach each dispatch
    # row's prior-run blob sha as a trailing TAB column, joining on the client
    # relpath (ledger column 1). One `awk` fork for the run, mirroring the
    # single-pass `hash-object` idiom the WRITE side uses.
    #
    # The ledger is an accelerator, never a requirement: if the join fails the
    # rows keep their unjoined form, every sha reads empty, and the cascade
    # falls through to R2/R3'. That costs sidecars, never staleness.
    #
    # `!($1 in m)` keeps the FIRST row for a repeated path, matching the
    # shortest-match lookup this replaced. `-F'\t'` is load-bearing — the
    # default splitter would break any path containing a space.
    if [[ -n "$prior_ledger" ]]; then
        local joined=""
        if joined=$(printf '%s\n' "$dispatch" | awk -F'\t' '
            NR == FNR {
                if (substr($0, 1, 1) == "#") next
                if ($1 != "" && !($1 in m)) m[$1] = $3
                next
            }
            {
                i = index($0, ":")
                r = substr($0, i + 1)
                j = index(r, ":")
                k = (j ? substr(r, 1, j - 1) : r)
                print $0 "\t" (k in m ? m[k] : "")
            }
        ' "$prior_ledger" - 2>/dev/null); then
            # Adopt the join ONLY if it produced rows. The two-file `NR == FNR`
            # idiom has exactly one degenerate mode: a first file holding ZERO
            # records makes every stdin record satisfy `NR == FNR`, so the whole
            # dispatch set is consumed as ledger rows and nothing is printed.
            # `awk` still exits 0, so the rc test above cannot see it. Adopting
            # that result would empty the value the loop below reads, refreshing
            # not one file — the failure the non-empty guard above exists to
            # prevent, reintroduced downstream of it where that guard can no
            # longer see it. The run does not even end quietly: with nothing
            # installed it fails later at the immutable-manifest gate, whose
            # diagnostic names a missing installed file and says nothing about
            # the dispatch set. The fallback is the UNJOINED set rather than a
            # `die` because the ledger is an accelerator: without it every sha
            # reads empty and the cascade resolves through R2/R3'.
            if [[ -n "$joined" ]]; then
                dispatch="$joined"
            fi
        fi
        rm -f "$prior_ledger"
    fi

    # R1 WRITE staging: `proj_rel<TAB>pack_source<TAB>disposition<TAB>abs_path`.
    # Blob shas for the whole set are computed in ONE pass after the loop.
    # An unwritable stage is a no-op, not a failure — same contract as the
    # ledger itself, and the guard keeps `set -e` from aborting the run.
    local ledger_stage
    ledger_stage=$(mktemp "${TMPDIR:-/tmp}/cu-ledger.XXXXXX") || ledger_stage=""

    local row row_sha rest pack_rel proj_rel cls eff_cls theirs ours dest
    while IFS=$'\t' read -r row row_sha; do
        [[ -n "$row" ]] || continue
        pack_rel="${row%%:*}"
        rest="${row#*:}"
        proj_rel="${rest%%:*}"
        cls="${rest##*:}"
        theirs="$PACK/$pack_rel"
        ours="$TARGET/$proj_rel"
        dest="$TARGET/$proj_rel"
        # BD-088 contract: passing ""=absent for missing files. Library
        # records a finding for every entry — including removed-everywhere
        # — so the truthful-report contract is preserved.
        [[ -f "$theirs" ]] || theirs=""
        [[ -f "$ours" ]]   || ours=""

        # SCOPING GATE — the BASE cascade is TEXT-CLASS ONLY. `trinity` and
        # the five structured classes keep empty-BASE dispatch.
        #   * Structured: a non-empty BASE lets the classifier answer
        #     `merged-with-customization`, and _cp_strategy_structured returns
        #     on that token BEFORE the key-merge helper runs — the pack's new
        #     keys would never reach the client. Today they arrive via the
        #     key-union path, and they must keep arriving.
        #   * Trinity: marker_preserve_trinity's first step is base-aware with
        #     three branches, so supplying a non-empty BASE moves which branch
        #     fires.
        # Widening this case list to either family is a regression, not a
        # completion.
        #
        # The structured arm below is NOT a widening of that list: it resolves
        # the SAME R2 question and hands the ANSWER to the strategy as a
        # separate signal, leaving `_CU_BASE` empty. Empty-BASE dispatch is
        # what the gate protects, and empty-BASE dispatch is what the
        # structured classes still get. What the signal repairs is the gate's
        # unintended cost: with BASE always empty the key-merge cannot tell a
        # stale PACK value from a client edit, so its "keep project value" rule
        # protects an older pack value forever and re-emits a sidecar every run
        # — and the sidecar pre-check above then refuses the next run. Trinity
        # is deliberately NOT given the signal: its engine branches on BASE
        # itself, so the same proof would have to change which branch fires,
        # which is the regression this gate exists to prevent.
        #
        # Two signals, two granularities. The whole-file answer only clears a
        # client who never touched the file; ONE edited key anywhere makes it
        # NO, and then every diverged pack key in that file freezes — the key
        # the client is missing is generally not the key they edited. The
        # SOURCE path is therefore handed over as well, so the merge helper can
        # derive the ancestor PER KEY. That derivation reaches only the helper:
        # `three_way_classify` still runs on the empty BASE two lines below, so
        # the `merged-with-customization` short-circuit this gate protects
        # remains unreachable from a caller-supplied base.
        eff_cls="$cls"
        [[ -n "$eff_cls" ]] || eff_cls=$(customization_classify "$proj_rel")
        _CU_BASE=""
        _CU_BASE_TMP=""
        _CP_OURS_BLOB=""
        _CP_OURS_PACK_AUTHORED=0
        _CP_OURS_PACK_SOURCE=""
        # Reset alongside the three above: the staged row below reads it, and
        # an arm that returned without recording would otherwise stage the
        # PREVIOUS file's disposition against this path.
        _CP_LAST_DISP=""
        case "$eff_cls" in
            generic|pm-chat|pack-script|pack-agent)
                _cmd_update_resolve_base "$pack_rel" "$ours" "$row_sha"
                ;;
            claude-settings|claude-mcp-example|mcp-config-json|codex-config|codex-config-example)
                _cmd_update_probe_pack_authored "$pack_rel" "$ours"
                ;;
        esac

        if [[ -n "$cls" ]]; then
            customization_preserve "$_CU_BASE" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
        else
            customization_preserve "$_CU_BASE" "$ours" "$theirs" "$proj_rel" "$dest" >/dev/null
        fi
        if [[ -n "$_CU_BASE_TMP" ]]; then
            rm -f "$_CU_BASE_TMP"
        fi

        # Stage the R1 row: the pack blob that is the merge BASE for the NEXT
        # run at this path. On the adopt arms that blob is also what DEST now
        # holds; on the merged and needs-reconciliation arms it is not, and it
        # is still the right value — the pack blob is the common ancestor the
        # next three-way has to diff against. Only rows the pack ships.
        if [[ -n "$theirs" && -n "$ledger_stage" ]]; then
            printf '%s\t%s\t%s\t%s\n' "$proj_rel" "$pack_rel" \
                "${_CP_LAST_DISP:--}" "$theirs" >> "$ledger_stage"
        fi
    done <<< "$dispatch"

    if [[ -n "$ledger_stage" ]]; then
        _cmd_update_write_ledger "$ledger_stage"
        rm -f "$ledger_stage"
    fi

    # BD-263 (groupings provisioning): seed the empty groupings `_toc.md`
    # iff absent. A groupings-less v11.0 tree gains docs/project/groupings/
    # {_rules.md,_intro.md} from the dispatch above; without this seed the
    # stream's SOLE readable index would be missing until the client's
    # first TOC regenerate. Guarded by absence — a tree with a populated
    # groupings stream keeps its regenerated `_toc.md` untouched, and a
    # re-run of --update is a no-op (SC16.12). Helpers are type-guard
    # sourced (same convention as stage S11 step 7).
    if [[ -d "$TARGET/docs/project/groupings" \
       && ! -f "$TARGET/docs/project/groupings/_toc.md" ]]; then
        local _pe_lib_dir="$PACK/scripts/lib/per-entry"
        [[ -d "$_pe_lib_dir" ]] \
            || die "per-entry helpers missing at $_pe_lib_dir (cannot seed groupings _toc.md)"
        if ! type pe_die >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/_lib.sh"
        fi
        if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/toc-regenerate.sh"
        fi
        per_entry_regenerate_toc "project-groupings" "$TARGET/docs/project/groupings" \
            || die "per_entry_regenerate_toc failed for project-groupings (--update toc seed)"
    fi

    # Integrity manifest — regenerate against the UPDATED installed
    # _rules.md (there is no tracked manifest to copy; hashing the
    # post-update installed files keeps the manifest reflecting actual
    # installed state).
    bash "$PACK/scripts/immutable-manifest.sh" --client-tree "$TARGET" \
        || die "immutable-manifest generation failed against $TARGET"

    # Render truthful report.
    local report="$state_dir/report.md"
    customization_report "$state_dir/dispositions.tsv" "$report" \
        "AI Agent Config Pack — --update report"

    local count
    count=$(customization_findings_count)
    say ""
    say "Update complete. $count files processed."
    say "Report: $report"
    say "Trinity files include marker-pair seed slots for project customizations —"
    say "see docs/pack/PM-CHAT.md (project-owned marker authoring) before editing."
    if grep -q "needs-reconciliation" "$state_dir/dispositions.tsv" 2>/dev/null; then
        say ""
        say "NOTE: one or more files need manual reconciliation. Search the"
        say "report for 'Files needing manual reconciliation' and inspect the"
        say "named .pre-update sidecars before continuing."
    fi
}

# ── _CLIENT_INSTALLED_FILES — the client install map ──
#
# THE single machine-readable declaration of what this script installs to
# clients. Every consumer DERIVES from it; no consumer re-declares it.
# Two blocks share one row grammar:
#
#   * the FILES block — explicit, one row per installed file;
#   * the GLOBS block — bulk families, one row per source pattern.
#
# Row grammar (a comment line between a block's START/END markers):
#   #   <pack_relpath>  ->  <project_relpath>  [stage:<ids>]  [class:<token>]
#
# Operands:
#   [stage:<ids>]   comma-separated copy-site ids. Token vocabulary:
#                     S<N>         a fresh-install stage (S2..S11)
#                     cmd_update   the explicit-mapping update path
#                     migrate      the vN->vN+1 migration install path
#   [class:<token>] the customization-preservation class the copy site hands
#                   to `customization_preserve`. The reserved value `self`
#                   means SELF-CLASSIFY: no class argument is passed and the
#                   copy site derives the class per file.
#
# In the GLOBS block ONLY, a `{a,b,c}` group in the DEST is a FAN-OUT
# operand — the row expands to one destination per brace member. Only the
# DEST may carry a brace group.
#
# Adding a client-installed file means adding its row here AND wiring the
# copy site named by its `[stage:]` operand. Shell consumers read the blocks
# through `scripts/lib/install-map.sh`; `validate-pack.py` Checks 39/41/43/
# 47/68 parse them directly.
#
# Fresh-install-only, so declared as prose rather than as a machine row (it
# is on neither the update nor the migration axis):
#   * <conditional masters: project-template/{pyproject.toml,pyrightconfig.json,
#       server/,proto/} + project-template/scripts/{bootstrap,format,validate,
#       test}-{python,swift}.sh + proto-gen.sh + validate-proto.sh>
#       -> pack-capability-pool/*                     [stage:S5b]
#       The TRACKED client capability pool. Its sources are all
#       project-template/ conditional masters — already covered by the
#       project-template/ recursive walk; NOT a _SANCTIONED_PACK_SIDE_SHIPPED
#       entry, so Check 47's frozen EMPTY set is UNMOVED. Roster derived from
#       capability_files() in project-template/scripts/capability-tables.sh.
#
# Intentionally NOT installed to clients (rationale per BD-180 observation):
#   * project-template/.claude/settings.local.example.json
#       -- BD-180 observation C (2026-05-20): `settings.local.*` is the
#       Claude Code convention for per-developer customization; clients
#       author their own; the pack does not seed. Listed here for
#       discoverability — searchable when an actor asks "why does this
#       exist if it never installs?"
#
# _CLIENT_INSTALLED_FILES_START
#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S7,cmd_update,migrate]  [class:trinity]
#   project-template/AGENTS.md  ->  AGENTS.md  [stage:S7,cmd_update,migrate]  [class:trinity]
#   project-template/GEMINI.md  ->  GEMINI.md  [stage:S7,cmd_update,migrate]  [class:trinity]
#   project-template/.claude/settings.json  ->  .claude/settings.json  [stage:S3,cmd_update,migrate]  [class:claude-settings]
#   project-template/.codex/config.toml  ->  .codex/config.toml  [stage:S3,cmd_update,migrate]  [class:codex-config]
#   project-template/.codex/config.toml.example  ->  .codex/config.toml.example  [stage:S3,cmd_update,migrate]  [class:codex-config-example]
#   project-template/.codex/requirements.toml  ->  .codex/requirements.toml  [stage:S3,cmd_update,migrate]  [class:codex-config]
#   project-template/.mcp.json.example  ->  .mcp.json  [stage:S3,cmd_update,migrate]  [class:claude-mcp-example]
#   project-template/.agents/mcp_config.json.example  ->  .agents/mcp_config.json  [stage:S3,cmd_update,migrate]  [class:mcp-config-json]
#   project-template/.agents-plugin/optiquity-agents/plugin.json  ->  .agents-plugin/optiquity-agents/plugin.json  [stage:S2,cmd_update,migrate]  [class:self]
#   project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md  ->  .agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md  [stage:S2,cmd_update,migrate]  [class:self]
#   project-template/agent-run.sh  ->  agent-run.sh  [stage:S5,cmd_update,migrate]  [class:pack-script]
#   project-template/.github/ISSUE_TEMPLATE/work-item.yml  ->  .github/ISSUE_TEMPLATE/work-item.yml  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/.github/ISSUE_TEMPLATE/inbound.yml  ->  .github/ISSUE_TEMPLATE/inbound.yml  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/.github/ISSUE_TEMPLATE/config.yml  ->  .github/ISSUE_TEMPLATE/config.yml  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/HELP-FRAGMENT.md  ->  docs/pack/HELP-FRAGMENT.md  [stage:S6,S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/OPTIONAL-FEATURES.md  ->  docs/pack/OPTIONAL-FEATURES.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/PACK-FEEDBACK.md  ->  docs/pack/PACK-FEEDBACK.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/PLATFORM-SKILLS.md  ->  docs/pack/PLATFORM-SKILLS.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/PM-CHAT.md  ->  docs/pack/PM-CHAT.md  [stage:S6,cmd_update,migrate]  [class:pm-chat]
#   project-template/docs/pack/PM-OPERATING-MODES.md  ->  docs/pack/PM-OPERATING-MODES.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/PM-DASHBOARD-SPEC.md  ->  docs/pack/PM-DASHBOARD-SPEC.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/backlog/_rules.md  ->  docs/project/backlog/_rules.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/backlog/_intro.md  ->  docs/project/backlog/_intro.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/implementation-plan/_rules.md  ->  docs/project/implementation-plan/_rules.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/implementation-plan/_intro.md  ->  docs/project/implementation-plan/_intro.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/changelog/_rules.md  ->  docs/project/changelog/_rules.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/changelog/_intro.md  ->  docs/project/changelog/_intro.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/groupings/_rules.md  ->  docs/project/groupings/_rules.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   project-template/docs/project/groupings/_intro.md  ->  docs/project/groupings/_intro.md  [stage:S11,cmd_update,migrate]  [class:generic]
#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/skills/*/SKILL.md  ->  .{claude,codex,agents}/skills/*/SKILL.md  [stage:S4,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/prompts/*.md  ->  docs/pack/prompts/*.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/.claude/agents/*.md  ->  .claude/agents/*.md  [stage:S2,cmd_update,migrate]  [class:pack-agent]
#   project-template/.codex/agents/*.toml  ->  .codex/agents/*.toml  [stage:S2,cmd_update,migrate]  [class:pack-agent]
#   project-template/.agents-plugin/optiquity-agents/agents/*  ->  .agents-plugin/optiquity-agents/agents/*  [stage:S2,cmd_update,migrate]  [class:self]
#   project-template/scripts/*  ->  scripts/*  [stage:S5,cmd_update,migrate]  [class:pack-script]
# _CLIENT_INSTALLED_GLOBS_END

# Blast-radius sweep — §7.7
blast_radius_sweep() {
    # PROMPT-TEMPLATES must not appear in installed pack-owned files.
    local scope_dirs=(.claude .codex .agents .agents-plugin docs/pack scripts)
    local scope_files=(CLAUDE.md AGENTS.md GEMINI.md agent-run.sh)
    local matches=0
    local d f
    for d in "${scope_dirs[@]}"; do
        [[ -d "$TARGET/$d" ]] || continue
        # Files that legitimately reference the retired
        # PROMPT-TEMPLATES.md name and must be excluded from the
        # active-reference sweep:
        #   - INSTALL-PROCEDURES.md (docs/pack/) documents the v9→v10
        #     PROMPT-TEMPLATES.md migration in Procedure 5-C.1 (formerly
        #     Procedure 5-R in METHODOLOGY pre-C7).
        #   - METHODOLOGY.md (docs/pack/) retains a stub pointer that
        #     may also reference the legacy name.
        #   - PM-CHAT.md (docs/pack/, v10.1+) names PROMPT-TEMPLATES.md
        #     in the RAG orphan-files table so users can purge stale
        #     RAG entries citing dead paths.
        #   - detect.sh (scripts/lib/) uses PROMPT-TEMPLATES.md as a
        #     v10-shape negative marker for pack-version detection;
        #     this is functional library code, not stale narrative.
        #   - .docs-gate-allowlist.txt (scripts/) records the retired
        #     PROMPT-TEMPLATES.md name as a `target:` exception (legacy
        #     v9-era artifact guarded by migration text); the allowlist
        #     by construction enumerates legitimate references.
        if grep -rn --exclude='METHODOLOGY.md' --exclude='INSTALL-PROCEDURES.md' --exclude='PM-CHAT.md' --exclude='detect.sh' --exclude='.docs-gate-allowlist.txt' "PROMPT-TEMPLATES" "$TARGET/$d" >/dev/null 2>&1; then
            warn "PROMPT-TEMPLATES reference found in $d"
            matches=1
        fi
    done
    for f in "${scope_files[@]}"; do
        [[ -f "$TARGET/$f" ]] || continue
        if grep -n "PROMPT-TEMPLATES" "$TARGET/$f" >/dev/null 2>&1; then
            warn "PROMPT-TEMPLATES reference found in $f"
            matches=1
        fi
    done
    (( matches == 0 )) || return 1
    return 0
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
    # Argv parsing — accept --update flag in any position.
    local update_mode=0
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            --update) update_mode=1 ;;
            --yes) YES=1 ;;
            --no-interactive) NO_INTERACTIVE=1 ;;
            --trinity=*)
                TRINITY_FLAG="${1#*=}"
                case "$TRINITY_FLAG" in
                    keep|replace|merge) ;;
                    *) die "invalid --trinity value: '$TRINITY_FLAG' (expected keep|replace|merge)" "$EXIT_INTERNAL" ;;
                esac
                ;;
            --trinity)
                die "--trinity requires a value: --trinity=keep|replace|merge" "$EXIT_INTERNAL" ;;
            --help|-h)
                say "Usage: PACK=/path/to/pack init-project.sh [--update] [--yes] [--no-interactive] [--trinity=keep|replace|merge] [target-dir]"
                say "  --yes             fresh install only: bypass the confirm prompt (automation / CI)"
                say "  --no-interactive  fresh install only: never prompt; decline unless --yes is set"
                say "  --trinity=k|r|m   handwritten-trinity target: keep | replace | merge (the SOLE"
                say "                    trinity-automation selector; honored non-interactively)"
                say "  (--yes / --no-interactive / --trinity have no effect under --update)"
                exit 0
                ;;
            --*) die "unknown option: $1 (try --help)" "$EXIT_INTERNAL" ;;
            *)   positional+=("$1") ;;
        esac
        shift
    done
    TARGET="${positional[0]:-.}"
    TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

    # Pre-flight (pre-confirm)
    if [[ -z "${PACK:-}" ]]; then
        die "PACK environment variable not set" "$EXIT_PACK_INVALID"
    fi
    local pack_status
    pack_status=$(detect_pack_path "$PACK" | awk -F': ' '{print $2}')
    if [[ "$pack_status" != "valid" ]]; then
        die "PACK ($PACK) is not a valid pack repo: $pack_status" "$EXIT_PACK_INVALID"
    fi
    if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
        die "target is not a git repo: $TARGET (run \`git init\` first)" "$EXIT_NOT_GIT"
    fi

    # --update branch: skip classification + confirmation. Run before the
    # global clean-tree check so cmd_update's sidecar pre-check can issue
    # an actionable error on re-run (the global check would shadow it
    # with a generic "tree dirty" message). cmd_update has its own
    # safety gates (sidecar presence, pack-configured precondition).
    if (( update_mode == 1 )); then
        cmd_update
        exit 0
    fi

    local wt
    wt=$(detect_clean_working_tree "$TARGET" | awk -F': ' '{print $2}')
    if [[ "$wt" != "clean" ]]; then
        # BD-285 P0: the commit-first gate is UNCHANGED; the message now names
        # the trinity/starter case + the one-step workaround so a user who
        # just hand-created a starter trinity knows to commit it first.
        die "target working tree is dirty; commit or stash first. If you just created a starter trinity (CLAUDE.md / AGENTS.md / GEMINI.md) to seed this project, commit it so init can safely install over it: run \`git add -A && git commit -m 'starter trinity'\`, then re-run init-project.sh." "$EXIT_DIRTY"
    fi

    # Classification
    CLASS=$(classify_project_state "$TARGET" | awk -F': ' '{print $2}')
    if [[ "$CLASS" == "already-configured" ]]; then
        # BD-285 C2: a provenance-gated three-way dispatch replaces the blanket
        # already-configured STOP. detect_trinity_provenance keys on load-bearing
        # signals (excluding detect_target_pack_version's lenient fallback).
        local provenance
        provenance=$(detect_trinity_provenance "$TARGET")
        case "$provenance" in
            handwritten)
                # A handwritten trinity — offer the guided keep/replace/merge
                # branch. handle_handwritten_trinity sets TRINITY_CHOICE +
                # reassigns CLASS, then returns 0 to continue into the
                # preview/confirm/stages below. A null choice STOPs inside it.
                handle_handwritten_trinity
                ;;
            pack)
                say "STOP — existing AI config detected in $TARGET:"
                detect_ai_config "$TARGET" | sed 's/^/  /'
                say ""
                say "Your options:"
                say "  (a) already using this pack — run the migrator for your"
                say "      current → target version (e.g. scripts/migrate-v10-to-v11.sh"
                say "      and supporting-docs/MIGRATION-v10-to-v11.md). v9.x is"
                say "      no longer supported (sunset in v11)."
                say "  (b) using other AI tooling — remove or archive those files before"
                say "      running init-project.sh"
                exit "$EXIT_AI_CONFIG"
                ;;
            *)
                # ambiguous — a populated foreign agent/skill tree, or no
                # trinity file: cannot safely offer the guided branch.
                say "STOP — existing AI config detected in $TARGET:"
                detect_ai_config "$TARGET" | sed 's/^/  /'
                say ""
                say "Your options:"
                say "  (a) already using this pack — run the migrator for your"
                say "      current → target version (e.g. scripts/migrate-v10-to-v11.sh)."
                say "  (b) using other AI tooling — remove or archive those files before"
                say "      running init-project.sh"
                say "  (c) a POPULATED foreign agent/skill tree was detected"
                say "      (.claude/agents|skills, .codex/agents|skills, or"
                say "      .agents/agents|skills); reconcile or remove it first."
                exit "$EXIT_AI_CONFIG"
                ;;
        esac
    fi

    # Preview + confirmation
    local lm
    lm=$(detect_language_markers "$TARGET" | awk -F': ' '{print $2}')
    print_preview "$TARGET" "$PACK" "$CLASS" "$lm"
    echo ""
    if ! confirm_proceed; then
        exit 0
    fi

    # Execute stages
    say ""
    stage_s1_skeleton
    stage_s2_agents
    stage_s3_configs
    stage_s4_skills
    stage_s5_scripts
    stage_s5b_populate_pool
    stage_s6_docs_pack
    stage_s7_trinity
    stage_s8_gitignore
    stage_s9_conditional_remove
    stage_s11_v11_artifacts
    seed_r1_ledger
    stage_s10_kickoff_prompt

    # End-of-S10 blast-radius sweep
    blast_radius_sweep || exit "$EXIT_SWEEP"

    say ""
    say "Initialization complete. Review \`git diff\` / \`git status\`, then"
    say "start a PM chat session with the kickoff prompt above."
    say "Trinity files include marker-pair seed slots for project customizations —"
    say "see docs/pack/PM-CHAT.md (project-owned marker authoring) before editing."
}

main "$@"
