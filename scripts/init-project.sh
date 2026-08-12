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

# classify: new-empty | new-bare | existing-bare | existing-source | already-configured
classify_project_state() {
    local target="${1:-.}"
    local ai
    ai=$(detect_ai_config "$target" | awk -F': ' '{print $2}')
    if [[ "$ai" != "(none)" ]]; then
        echo "classify: already-configured"
        return
    fi
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
            if [[ "$CLASS" == existing-* ]]; then
                existing_classifier_copy "$pack_file" "$TARGET/$f"
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
        # gitignored `__pycache__`) — true parity with _cmd_update_iter_dir's
        # `find -type f` (this dir is a flat file set, no tracked subdirs).
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

# ── --update mode (BD-080) ─────────────────────────────────────────────────
#
# Refresh a previously-installed pack to the current pack version using the
# BD-088 customization-preservation contract. Does NOT run the full S1..S10
# install — that path is for fresh installs only. --update is conservative:
# it only touches files the BD-088 library knows how to dispatch, records a
# truthful report at .pack-update/report.md, and never overwrites a project
# customization without writing a sidecar (per BD-088 contract).

# Iterate every regular file under `$PACK/$pack_dir`, derive the parallel
# project-relative path under `$proj_dir`, and dispatch via BD-088. Mirror
# of stage S3's _stage_s3_iter_dir in migrate-v10-to-v11.sh so --update
# and the migrator share parity (PACK-REVIEW-BD-080-BD-085 M2).
_cmd_update_iter_dir() {
    local pack_dir="$1" proj_dir="$2" cls="${3:-}"
    [[ -d "$PACK/$pack_dir" ]] || return 0
    local f rel proj_rel theirs ours dest
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        rel="${f#"$PACK/$pack_dir/"}"
        proj_rel="$proj_dir/$rel"
        theirs="$f"
        ours="$TARGET/$proj_rel"
        dest="$TARGET/$proj_rel"
        [[ -f "$ours" ]] || ours=""
        # An EMPTY cls means "self-classify per the customization_classify
        # legs" — used by the Antigravity bundle leg (BD-221 corrected
        # agent-migration model), whose dir mixes pack agents (→ pack-agent,
        # replace-if-different) and client x- customs (→ custom-agent,
        # preserved). A NON-empty cls forces the class for whole-dir
        # single-class sweeps (the loose .claude/.codex/agents/ + scripts/).
        if [[ -n "$cls" ]]; then
            customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
        else
            customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" >/dev/null
        fi
    done < <(find "$PACK/$pack_dir" -type f -print 2>/dev/null)
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
       || ! -f "$lib_dir/customization-report.sh" ]]; then
        die "customization library missing under $lib_dir; cannot --update" \
            "$EXIT_UPDATE_LIB_MISSING"
    fi

    # Pre-check: refuse to proceed if any *.pre-update sidecars from a
    # prior --update run still exist. Single-slot sidecars must be
    # reconciled before re-running, else the second run silently
    # overwrites them and destroys the user's pre-update content.
    local stale_sidecars
    stale_sidecars=$(find "$TARGET" -type f -name "*.pre-update" \
        -not -path "*/.pack-update/*" -not -path "*/.git/*" 2>/dev/null | head -20)
    if [[ -n "$stale_sidecars" ]]; then
        say "refusing to proceed: prior --update sidecars present:"
        printf '  %s\n' $stale_sidecars >&2
        die "reconcile or remove the .pre-update sidecars above before re-running --update" \
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

    local state_dir="$TARGET/.pack-update"
    rm -rf "$state_dir"
    customization_preserve_init "$state_dir" ".pre-update"

    # The set of files --update touches. BASE is left empty (no prior pack
    # baseline available offline; the BD-088 classifier handles
    # `project-shadows-new-pack` for files where ours and theirs differ
    # without a base).
    #
    # Each entry is: pack_relpath:project_relpath:class
    #   pack_relpath     — path under $PACK (or $PACK/project-template/)
    #   project_relpath  — path under $TARGET
    #   class            — explicit class for customization_preserve
    #
    # Self-documenting fixture-affecting list lives below at
    # `_CLIENT_INSTALLED_FILES` (BD-180 observation G per
    # ARCHITECTURE-BD-176.md §5.3). validate-pack.py Check 41 asserts the
    # `_CLIENT_INSTALLED_FILES` list matches the actual copy-site state of
    # this script (cmd_update entries below + fresh-install stages
    # S3/S4/S5/S6/S7/S8/S11).
    local entries=(
        "project-template/CLAUDE.md:CLAUDE.md:trinity"
        "project-template/AGENTS.md:AGENTS.md:trinity"
        "project-template/GEMINI.md:GEMINI.md:trinity"
        "project-template/.claude/settings.json:.claude/settings.json:claude-settings"
        "project-template/.codex/config.toml:.codex/config.toml:codex-config"
        "project-template/.codex/config.toml.example:.codex/config.toml.example:codex-config-example"
        "project-template/.codex/requirements.toml:.codex/requirements.toml:codex-config"
        "project-template/.mcp.json.example:.mcp.json:claude-mcp-example"
        "project-template/.agents/mcp_config.json.example:.agents/mcp_config.json:mcp-config-json"
        "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"
        "project-template/docs/pack/PM-OPERATING-MODES.md:docs/pack/PM-OPERATING-MODES.md:generic"
        "project-template/docs/pack/PM-DASHBOARD-SPEC.md:docs/pack/PM-DASHBOARD-SPEC.md:generic"
        "project-template/docs/pack/PLATFORM-SKILLS.md:docs/pack/PLATFORM-SKILLS.md:generic"
        "project-template/docs/pack/PACK-FEEDBACK.md:docs/pack/PACK-FEEDBACK.md:generic"
        # BD-180 observation E (2026-05-20): PROMPT-TEMPLATES.md entry
        # REMOVED — the file was retired in v10.0 (replaced by per-agent
        # prompts under docs/pack/prompts/). The stale mapping had no
        # source file to copy from. Reverse-direction Check 39 now flags
        # such drift bidirectionally.
        "project-template/docs/pack/HELP-FRAGMENT.md:docs/pack/HELP-FRAGMENT.md:generic"
        "project-template/docs/pack/OPTIONAL-FEATURES.md:docs/pack/OPTIONAL-FEATURES.md:generic"
        # BD-214 (2026-06-13): tracker.toml.example entry REMOVED — tracker
        # integration is deferred indefinitely and flat-file is the sole
        # supported mode. The deferred flip material no longer ships to
        # clients (design D-C); the dormant config record stays committed
        # pack-side (project-template/tracker.toml.project-example).
        "project-template/.github/ISSUE_TEMPLATE/work-item.yml:.github/ISSUE_TEMPLATE/work-item.yml:generic"
        "project-template/.github/ISSUE_TEMPLATE/inbound.yml:.github/ISSUE_TEMPLATE/inbound.yml:generic"
        "project-template/.github/ISSUE_TEMPLATE/config.yml:.github/ISSUE_TEMPLATE/config.yml:generic"
        # BD-221 (2026-06-16): pm-help + pm-startup are ordinary pool
        # skills (project-template/skills/{pm-help,pm-startup}/SKILL.md)
        # distributed LOOSE to claude/codex/agents by stage S4. The former
        # per-CLI explicit-copy rows (.claude/.codex SKILL.md + the retired
        # `.toml` command surfaces) are gone — the S4 fresh-install loop
        # propagates pool-skill updates to existing clients (the BD-180
        # bulk-copy pattern), and Antigravity has no `.toml` command format.
        # BD-180 observation D (2026-05-20): per-entry skeleton templates
        # (BD-166/BD-167). Installed at fresh init by S11 step 6 (lines
        # 891-947 — explicit `"$copy_fn"` calls for each); without these
        # cmd_update entries, template updates (e.g., `_rules.md` schema
        # changes) would not propagate to existing clients via
        # `pack update`. BD-167 scaffolding contract is load-bearing.
        "project-template/docs/project/backlog/_rules.md:docs/project/backlog/_rules.md:generic"
        "project-template/docs/project/backlog/_intro.md:docs/project/backlog/_intro.md:generic"
        "project-template/docs/project/implementation-plan/_rules.md:docs/project/implementation-plan/_rules.md:generic"
        "project-template/docs/project/implementation-plan/_intro.md:docs/project/implementation-plan/_intro.md:generic"
        "project-template/docs/project/changelog/_rules.md:docs/project/changelog/_rules.md:generic"
        "project-template/docs/project/changelog/_intro.md:docs/project/changelog/_intro.md:generic"
        # BD-263 (groupings provisioning): fourth per-entry stream sidecars
        # (BD-262 contract). Without these rows an already-installed v11.0
        # tree (pre-groupings dev install) would never gain the groupings
        # stream via `pack update` — cmd_update is the live same-version
        # propagation surface (no v11.0→v11.x migrator exists by design).
        # Post-copy, cmd_update seeds the empty groupings `_toc.md` iff
        # absent (see the toc-seed block below the iter-dir legs).
        "project-template/docs/project/groupings/_rules.md:docs/project/groupings/_rules.md:generic"
        "project-template/docs/project/groupings/_intro.md:docs/project/groupings/_intro.md:generic"
        # BD-180 observation F (2026-05-20): supporting-docs/* installed
        # to docs/pack/ by S6 (lines 565-583 — separate copy blocks below
        # the docs/pack/*.md glob loop since these source files live under
        # $PACK/supporting-docs/, not under $PACK/project-template/). Same
        # gap class as observations B/D — files reached fresh-init clients
        # but not update clients. BD-175 Commit 8 CI-failure precedent
        # (METHODOLOGY.md manifest drift) confirms both files ARE
        # fixture-affecting + ARE distributed at install time.
        "supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic"
        "supporting-docs/INSTALL-PROCEDURES.md:docs/pack/INSTALL-PROCEDURES.md:generic"
    )

    local entry pack_rel proj_rel cls theirs ours dest
    for entry in "${entries[@]}"; do
        pack_rel="${entry%%:*}"
        local rest="${entry#*:}"
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
        customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
    done

    # Iterate pack-shipped scripts and per-CLI agents (parity with
    # migrate-v10-to-v11.sh stage S3). Without this, pack-shipped script
    # / agent updates would silently NOT be picked up by --update.
    _cmd_update_iter_dir "project-template/scripts" "scripts" pack-script
    local tool
    # Claude/Codex keep loose per-CLI agent dirs. Antigravity agents ship
    # as a plugin BUNDLE — the bundle updates via its own dir leg below.
    for tool in claude codex; do
        _cmd_update_iter_dir "project-template/.${tool}/agents" \
            ".${tool}/agents" pack-agent
    done
    # BD-221 corrected agent-migration model: the bundle dir mixes pack
    # agents AND client x- customs, so it must SELF-CLASSIFY per file (NO
    # forced class). With the .agents-plugin/*/agents/{x-*,*.md} classifier
    # legs, a bundle pack agent is replace-if-different and a bundle x-
    # custom is PRESERVED on a `--update` bump (a forced `pack-agent` would
    # 3-way the custom and risk sidecaring it). Empty 3rd arg = self-classify.
    _cmd_update_iter_dir "project-template/.agents-plugin/optiquity-agents/agents" \
        ".agents-plugin/optiquity-agents/agents"

    # BD-263 (groupings provisioning): seed the empty groupings `_toc.md`
    # iff absent. A groupings-less v11.0 tree gains docs/project/groupings/
    # {_rules.md,_intro.md} from the entries above; without this seed the
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

# ── _CLIENT_INSTALLED_FILES (BD-180 observation G per ARCHITECTURE-BD-176.md §5.3) ──
#
# Self-documenting authoritative inventory of files this script installs to
# clients. `validate-pack.py` Check 41 (BD-180) verifies (a) each named
# `pack_relpath` below exists on disk at HEAD and (b) the inventory has
# coverage for the BD-088 update path (`cmd_update` entries above) and the
# fresh-install stages below. Adding a new explicit client-installed file
# requires updating BOTH this list AND the relevant copy-site (cmd_update
# entries OR a stage loop) — Check 41 enforces the discoverability anchor;
# Check 39 enforces the cmd_update mapping/glob symmetry.
#
# Format: one entry per line between START/END markers; each entry is
#   #   <pack_relpath>  ->  <project_relpath>  [stage:<copy-site ids>]
# where copy-site ids name the install paths (S3..S11 for fresh-install
# stages; `cmd_update` for the BD-088 explicit-mapping update path).
#
# Bulk-copied directories (mass-installed by stage loops; not enumerated
# file-by-file in the START/END block below):
#   * project-template/skills/*/SKILL.md
#       -> .{claude,codex,agents}/skills/*/SKILL.md   [S4 canonical-pool loop]
#   * project-template/.{claude,codex}/agents/*.md
#       -> .{claude,codex}/agents/*.md                (loose per-CLI agents)
#       [S2 per-CLI agent install + _cmd_update_iter_dir]
#   * project-template/.agents-plugin/optiquity-agents/   (Antigravity plugin BUNDLE)
#       -> .agents-plugin/optiquity-agents/          [S2 bundle stage + _cmd_update_iter_dir]
#       (recursive-walk-covered by the project-template/ inventory; no
#        per-file START/END rows)
#   * project-template/scripts/*
#       -> scripts/*                                  [S5 + _cmd_update_iter_dir]
#   * <conditional masters: project-template/{pyproject.toml,pyrightconfig.json,
#       server/,proto/} + project-template/scripts/{bootstrap,format,validate,
#       test}-{python,swift}.sh + proto-gen.sh + validate-proto.sh>
#       -> pack-capability-pool/*                     [stage:S5b]
#       (BD-200: the TRACKED client capability pool. Sources are all
#       project-template/ conditional masters — already on the inventory via
#       the project-template/ recursive walk; NOT a _SANCTIONED_PACK_SIDE_SHIPPED
#       entry, so Check 47's frozen 2-tuple is UNMOVED. Roster derived from
#       capability_files() in project-template/scripts/capability-tables.sh.)
#   * project-template/docs/pack/prompts/*.md
#       -> docs/pack/prompts/*.md                     [S6 loop]
#   * project-template/.github/ISSUE_TEMPLATE/*.yml
#       -> .github/ISSUE_TEMPLATE/*.yml               [S11 step 3 + cmd_update]
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
#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S7,cmd_update]
#   project-template/AGENTS.md  ->  AGENTS.md  [stage:S7,cmd_update]
#   project-template/GEMINI.md  ->  GEMINI.md  [stage:S7,cmd_update]
#   project-template/.claude/settings.json  ->  .claude/settings.json  [stage:S3,cmd_update]
#   project-template/.codex/config.toml  ->  .codex/config.toml  [stage:S3,cmd_update]
#   project-template/.codex/config.toml.example  ->  .codex/config.toml.example  [stage:S3,cmd_update]
#   project-template/.codex/requirements.toml  ->  .codex/requirements.toml  [stage:S3,cmd_update]
#   project-template/.mcp.json.example  ->  .mcp.json  [stage:S3,cmd_update]
#   project-template/.agents/mcp_config.json.example  ->  .agents/mcp_config.json  [stage:S3,cmd_update]
#   project-template/.github/ISSUE_TEMPLATE/work-item.yml  ->  .github/ISSUE_TEMPLATE/work-item.yml  [stage:S11,cmd_update]
#   project-template/.github/ISSUE_TEMPLATE/inbound.yml  ->  .github/ISSUE_TEMPLATE/inbound.yml  [stage:S11,cmd_update]
#   project-template/.github/ISSUE_TEMPLATE/config.yml  ->  .github/ISSUE_TEMPLATE/config.yml  [stage:S11,cmd_update]
#   project-template/docs/pack/HELP-FRAGMENT.md  ->  docs/pack/HELP-FRAGMENT.md  [stage:S6,S11,cmd_update]
#   project-template/docs/pack/OPTIONAL-FEATURES.md  ->  docs/pack/OPTIONAL-FEATURES.md  [stage:S6,cmd_update]
#   project-template/docs/pack/PACK-FEEDBACK.md  ->  docs/pack/PACK-FEEDBACK.md  [stage:S6,cmd_update]
#   project-template/docs/pack/PLATFORM-SKILLS.md  ->  docs/pack/PLATFORM-SKILLS.md  [stage:S6,cmd_update]
#   project-template/docs/pack/PM-CHAT.md  ->  docs/pack/PM-CHAT.md  [stage:S6,cmd_update]
#   project-template/docs/pack/PM-OPERATING-MODES.md  ->  docs/pack/PM-OPERATING-MODES.md  [stage:S6,cmd_update]
#   project-template/docs/pack/PM-DASHBOARD-SPEC.md  ->  docs/pack/PM-DASHBOARD-SPEC.md  [stage:S6,cmd_update]
#   (BD-221: pm-help + pm-startup are pool skills distributed LOOSE to
#    .{claude,codex,agents}/skills/* by the S4 canonical-pool loop — see the
#    bulk-copied-directories block above; no per-CLI START/END rows. The
#    former `.toml` command surfaces are retired.)
#   project-template/docs/project/backlog/_rules.md  ->  docs/project/backlog/_rules.md  [stage:S11,cmd_update]
#   project-template/docs/project/backlog/_intro.md  ->  docs/project/backlog/_intro.md  [stage:S11,cmd_update]
#   project-template/docs/project/implementation-plan/_rules.md  ->  docs/project/implementation-plan/_rules.md  [stage:S11,cmd_update]
#   project-template/docs/project/implementation-plan/_intro.md  ->  docs/project/implementation-plan/_intro.md  [stage:S11,cmd_update]
#   project-template/docs/project/changelog/_rules.md  ->  docs/project/changelog/_rules.md  [stage:S11,cmd_update]
#   project-template/docs/project/changelog/_intro.md  ->  docs/project/changelog/_intro.md  [stage:S11,cmd_update]
#   project-template/docs/project/groupings/_rules.md  ->  docs/project/groupings/_rules.md  [stage:S11,cmd_update]
#   project-template/docs/project/groupings/_intro.md  ->  docs/project/groupings/_intro.md  [stage:S11,cmd_update]
#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6,cmd_update]
#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_END

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
            --help|-h)
                say "Usage: PACK=/path/to/pack init-project.sh [--update] [--yes] [--no-interactive] [target-dir]"
                say "  --yes             fresh install only: bypass the confirm prompt (automation / CI)"
                say "  --no-interactive  fresh install only: never prompt; decline unless --yes is set"
                say "  (--yes / --no-interactive have no effect under --update, which never confirms)"
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
        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
    fi

    # Classification
    CLASS=$(classify_project_state "$TARGET" | awk -F': ' '{print $2}')
    if [[ "$CLASS" == "already-configured" ]]; then
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
