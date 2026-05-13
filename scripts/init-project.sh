#!/usr/bin/env bash
# init-project.sh — initialize an AI Agent Config Pack installation in
# a new or existing project directory, OR refresh an existing pack
# install (--update) without destroying project customization.
#
# Per V10-DESIGN §7.3..§7.8 the default flow classifies the target into
# one of five project classes, stops (exit 20) if AI config is already
# present, prints a preview report, asks for explicit confirmation
# (default No), then executes stages S0..S11 with inline verification
# at each step. A blast-radius sweep at the end of S6 and S11 checks
# for stale cross-references.
#
# v11 additions (BD-080): stage S11 installs v11 client-side artifacts
# (HELP-FRAGMENT.md + HELP-FRAGMENT-TRACKER.md, tracker.toml.example
# — sourced from project-template/tracker.toml.project-example,
# .github/ISSUE_TEMPLATE/* issue forms, per-CLI pack-help skills /
# command). The --update flag refreshes a previously-installed pack to
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
detect_language_markers() {
    local target="${1:-.}"
    local found=()
    # Swift: Package.swift, *.xcodeproj, *.xcworkspace
    if find "$target" -maxdepth 2 \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" \) \
            -not -path '*/.*' 2>/dev/null | grep -q .; then
        found+=("swift")
    fi
    # Python: pyproject.toml
    if find "$target" -maxdepth 2 -name "pyproject.toml" -not -path '*/.*' 2>/dev/null | grep -q .; then
        found+=("python")
    fi
    # Kotlin: build.gradle.kts, settings.gradle.kts, build.gradle
    if find "$target" -maxdepth 2 \( -name "build.gradle.kts" -o -name "settings.gradle.kts" -o -name "build.gradle" \) \
            -not -path '*/.*' 2>/dev/null | grep -q .; then
        found+=("kotlin")
    fi
    # TypeScript/Node: package.json, tsconfig.json
    if find "$target" -maxdepth 2 \( -name "package.json" -o -name "tsconfig.json" \) \
            -not -path '*/.*' 2>/dev/null | grep -q .; then
        found+=("typescript")
    fi
    # Proto: proto/ with ≥1 .proto file
    if [[ -d "$target/proto" ]] && find "$target/proto" -maxdepth 2 -name "*.proto" 2>/dev/null | grep -q .; then
        found+=("proto")
    fi

    # Weak evidence (extension count ≥ 3) only if no strong evidence for that language yet.
    if ! printf '%s\n' "${found[@]:-}" | grep -qx "swift"; then
        local c
        c=$(find "$target" -maxdepth 2 -name "*.swift" -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')
        (( c >= 3 )) && found+=("swift")
    fi
    if ! printf '%s\n' "${found[@]:-}" | grep -qx "python"; then
        local c
        c=$(find "$target" -maxdepth 2 -name "*.py" -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')
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
detect_source_files() {
    local target="${1:-.}"
    local s p
    s=$(find "$target" -maxdepth 2 -name "*.swift" -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')
    p=$(find "$target" -maxdepth 2 -name "*.py" -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')
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
  - Agent config: .claude/, .codex/, .gemini/
  - Context: CLAUDE.md, AGENTS.md, GEMINI.md at the project root
  - Methodology & templates: docs/pack/
  - Scripts: scripts/
  - Agent launcher: agent-run.sh at the project root

Existing README.md, LICENSE, language manifest, and project docs are
unchanged and will continue to be authoritative.
EOF
}

confirm_proceed() {
    local ans
    read -r -p "Proceed? [y/N] " ans || ans=""
    local lower
    lower=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        y|yes) return 0 ;;
        *)     say "Declined. No changes made."; return 1 ;;
    esac
}

# ── Stages S1..S10 ─────────────────────────────────────────────────────────

stage_s1_skeleton() {
    say "── S1 — directory skeleton ──"
    mkdir -p "$TARGET/.claude/agents" "$TARGET/.codex/agents" "$TARGET/.gemini/agents" \
             "$TARGET/.claude/skills" "$TARGET/.codex/skills" "$TARGET/.gemini/skills" \
             "$TARGET/docs/pack" "$TARGET/docs/project" "$TARGET/docs/reference" \
             "$TARGET/scripts"
    # Verification
    local d
    for d in .claude/agents .codex/agents .gemini/agents docs/pack scripts; do
        [[ -d "$TARGET/$d" ]] || fail_stage S1 "missing directory $d after creation"
    done
}

stage_s2_agents() {
    say "── S2 — copy pack agent files (three tools) ──"
    local tool ext pack_src dst
    for tool in claude codex gemini; do
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
    # Verify agent counts match pack
    local pack_count dst_count
    pack_count=$(find "$PACK/project-template/.claude/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    for tool in claude codex gemini; do
        case "$tool" in codex) ext="toml" ;; *) ext="md" ;; esac
        dst_count=$(find "$TARGET/.${tool}/agents" -maxdepth 1 -name "*.${ext}" | wc -l | tr -d ' ')
        (( dst_count == pack_count )) || \
            fail_stage S2 "agent count mismatch: .${tool}/agents has $dst_count, expected $pack_count"
    done
}

stage_s3_configs() {
    say "── S3 — copy pack configs ──"

    # proj-path → pack-path map for K-class files where the pack-side
    # template lives under a different name. `.gemini/.env` is read by
    # Gemini at the project level; the pack ships its template at
    # `.gemini/.env.example` (project-template/.gitignore blocks plain
    # `.env` to protect against secrets; `.env.example` is committable).
    # init-project writes the live `.env` from the example so Gemini picks
    # it up immediately. Implemented as a function (not associative array)
    # for bash 3.2 compatibility (macOS default bash).
    pack_template_for_proj_path() {
        case "$1" in
            .gemini/.env) echo ".gemini/.env.example" ;;
            *)            echo "$1" ;;
        esac
    }

    local f
    for f in \
        .codex/config.toml \
        .codex/config.toml.example \
        .codex/requirements.toml \
        .claude/settings.json \
        .mcp.json.example \
        .gemini/settings.json \
        .gemini/.env \
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
    [[ -f "$TARGET/.gemini/.env" ]] || fail_stage S3 ".gemini/.env missing after copy (BD-059 trinity-rule parity)"
    [[ -f "$TARGET/.gemini/settings.json" ]] || fail_stage S3 ".gemini/settings.json missing after copy (BD-059 trinity-rule parity)"
}

stage_s4_skills() {
    say "── S4 — distribute skills (SKILL.md only) ──"
    local skill_dir name tool
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex gemini; do
            mkdir -p "$TARGET/.${tool}/skills/$name"
            cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"
        done
    done
    # Verify: every pack skill has three destination SKILL.md files
    local missing=0
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex gemini; do
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
        for f in "$pack_scripts"/*; do
            [[ -e "$f" ]] || continue
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
    # METHODOLOGY.md lives at `docs/pack/METHODOLOGY.md` per V10-DESIGN.md Part 7 §7.6.
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
    # (per V10-F-D-DESIGN §5.3 — init warns; migrators remove. The historical
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

    # Python conditional removals
    if (( has_python == 0 )); then
        local f
        for f in pyproject.toml pyrightconfig.json \
                 scripts/bootstrap-python.sh scripts/format-python.sh \
                 scripts/validate-python.sh scripts/test-python.sh; do
            is_x_prefixed "$f" && continue
            if [[ -e "$TARGET/$f" ]]; then
                rm -rf "$TARGET/$f"
                removed=$((removed + 1))
            fi
        done
        if [[ -d "$TARGET/server" ]] && ! is_x_prefixed "server"; then
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
            if [[ -e "$TARGET/$f" ]]; then
                rm -f "$TARGET/$f"
                removed=$((removed + 1))
            fi
        done
        if [[ -d "$TARGET/proto" ]] && ! is_x_prefixed "proto"; then
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
    say "── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──"

    local copy_fn="cp"
    [[ "$CLASS" == existing-* ]] && copy_fn="existing_classifier_copy"

    # 1. HELP-FRAGMENT*.md → docs/pack/. HELP-FRAGMENT.md per the usual
    #    classifier-copy rule (developer-customizable). HELP-FRAGMENT-
    #    TRACKER.md is byte-identity-required across pack-root and client
    #    mirror per DELTA L1 (validate-pack Check 24); force-copy from
    #    pack-root canonical regardless of class so an existing-* re-run
    #    cannot leave stale tracker fragments in place.
    mkdir -p "$TARGET/docs/pack"
    if [[ -f "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" ]]; then
        "$copy_fn" "$PACK/project-template/docs/pack/HELP-FRAGMENT.md" \
            "$TARGET/docs/pack/HELP-FRAGMENT.md"
    fi
    if [[ -f "$PACK/HELP-FRAGMENT-TRACKER.md" ]]; then
        cp -f "$PACK/HELP-FRAGMENT-TRACKER.md" \
            "$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md"
    fi
    [[ -f "$TARGET/docs/pack/HELP-FRAGMENT.md" ]] \
        || fail_stage S11 "docs/pack/HELP-FRAGMENT.md missing after copy"
    [[ -f "$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
        || fail_stage S11 "docs/pack/HELP-FRAGMENT-TRACKER.md missing after copy"

    # 2. tracker.toml.example at project root.
    #    Source: project-template/tracker.toml.project-example (BD-135).
    #    Destination basename remains tracker.toml.example for client
    #    projects (only one such file exists client-side; no collision).
    if [[ -f "$PACK/project-template/tracker.toml.project-example" ]]; then
        "$copy_fn" "$PACK/project-template/tracker.toml.project-example" \
            "$TARGET/tracker.toml.example"
    fi

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

    # 4. Per-CLI pack-help surfaces (BD-077). Source files live under each
    #    CLI's directory in the pack template; targets mirror that layout.
    if [[ -d "$PACK/project-template/.claude/skills/pack-help" ]]; then
        mkdir -p "$TARGET/.claude/skills/pack-help"
        "$copy_fn" "$PACK/project-template/.claude/skills/pack-help/SKILL.md" \
            "$TARGET/.claude/skills/pack-help/SKILL.md"
    fi
    if [[ -d "$PACK/project-template/.codex/skills/pack-help" ]]; then
        mkdir -p "$TARGET/.codex/skills/pack-help"
        "$copy_fn" "$PACK/project-template/.codex/skills/pack-help/SKILL.md" \
            "$TARGET/.codex/skills/pack-help/SKILL.md"
    fi
    if [[ -f "$PACK/project-template/.gemini/commands/pack-help.toml" ]]; then
        mkdir -p "$TARGET/.gemini/commands"
        "$copy_fn" "$PACK/project-template/.gemini/commands/pack-help.toml" \
            "$TARGET/.gemini/commands/pack-help.toml"
    fi

    # 5. The pack-help shell script + its single dep (lib/detect.sh).
    #    The per-CLI skills/commands above invoke `bash scripts/pack-help.sh`
    #    relative to the project — without these copies the slash-command
    #    surfaces (`/pack-help` on Claude/Codex/Gemini) fail at first
    #    invocation in a freshly-installed project (BD-097 audit B-1).
    mkdir -p "$TARGET/scripts/lib"
    if [[ -f "$PACK/scripts/pack-help.sh" ]]; then
        cp -f "$PACK/scripts/pack-help.sh" "$TARGET/scripts/pack-help.sh"
        chmod +x "$TARGET/scripts/pack-help.sh"
    fi
    if [[ -f "$PACK/scripts/lib/detect.sh" ]]; then
        cp -f "$PACK/scripts/lib/detect.sh" "$TARGET/scripts/lib/detect.sh"
    fi
    [[ -x "$TARGET/scripts/pack-help.sh" ]] \
        || fail_stage S11 "scripts/pack-help.sh missing or not executable after copy"
    [[ -f "$TARGET/scripts/lib/detect.sh" ]] \
        || fail_stage S11 "scripts/lib/detect.sh missing after copy"
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
    local pack_dir="$1" proj_dir="$2" cls="$3"
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
        customization_preserve "" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
    done < <(find "$PACK/$pack_dir" -type f -print 2>/dev/null)
}

cmd_update() {
    say "── --update — refresh v11 artifacts via BD-088 customization-preserve ──"

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
        die "BD-088 customization library missing under $lib_dir; cannot --update" \
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
    local entries=(
        "project-template/CLAUDE.md:CLAUDE.md:trinity"
        "project-template/AGENTS.md:AGENTS.md:trinity"
        "project-template/GEMINI.md:GEMINI.md:trinity"
        "project-template/.claude/settings.json:.claude/settings.json:claude-settings"
        "project-template/.mcp.json.example:.mcp.json.example:claude-mcp-example"
        "project-template/.codex/config.toml:.codex/config.toml:codex-config"
        "project-template/.codex/config.toml.example:.codex/config.toml.example:codex-config-example"
        "project-template/.codex/requirements.toml:.codex/requirements.toml:codex-config"
        "project-template/.gemini/.env.example:.gemini/.env:gemini-env"
        "project-template/.gemini/settings.json:.gemini/settings.json:claude-settings"
        "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"
        "project-template/docs/pack/PLATFORM-SKILLS.md:docs/pack/PLATFORM-SKILLS.md:generic"
        "project-template/docs/pack/PACK-FEEDBACK.md:docs/pack/PACK-FEEDBACK.md:generic"
        "project-template/docs/pack/PROMPT-TEMPLATES.md:docs/pack/PROMPT-TEMPLATES.md:generic"
        "project-template/docs/pack/HELP-FRAGMENT.md:docs/pack/HELP-FRAGMENT.md:generic"
        "project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic"
        "project-template/tracker.toml.project-example:tracker.toml.example:generic"
        "project-template/.github/ISSUE_TEMPLATE/work-item.yml:.github/ISSUE_TEMPLATE/work-item.yml:generic"
        "project-template/.github/ISSUE_TEMPLATE/inbound.yml:.github/ISSUE_TEMPLATE/inbound.yml:generic"
        "project-template/.github/ISSUE_TEMPLATE/config.yml:.github/ISSUE_TEMPLATE/config.yml:generic"
        "project-template/.claude/skills/pack-help/SKILL.md:.claude/skills/pack-help/SKILL.md:generic"
        "project-template/.codex/skills/pack-help/SKILL.md:.codex/skills/pack-help/SKILL.md:generic"
        "project-template/.gemini/commands/pack-help.toml:.gemini/commands/pack-help.toml:generic"
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
    for tool in claude codex gemini; do
        _cmd_update_iter_dir "project-template/.${tool}/agents" \
            ".${tool}/agents" pack-agent
    done

    # Render truthful report.
    local report="$state_dir/report.md"
    customization_report "$state_dir/dispositions.tsv" "$report" \
        "AI Agent Config Pack — --update report"

    local count
    count=$(customization_findings_count)
    say ""
    say "Update complete. $count files processed."
    say "Report: $report"
    if grep -q "needs-reconciliation" "$state_dir/dispositions.tsv" 2>/dev/null; then
        say ""
        say "NOTE: one or more files need manual reconciliation. Search the"
        say "report for 'Files needing manual reconciliation' and inspect the"
        say "named .pre-update sidecars before continuing."
    fi
}

# Blast-radius sweep — §7.7
blast_radius_sweep() {
    # PROMPT-TEMPLATES must not appear in installed pack-owned files.
    local scope_dirs=(.claude .codex .gemini docs/pack scripts)
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
        if grep -rn --exclude='METHODOLOGY.md' --exclude='INSTALL-PROCEDURES.md' --exclude='PM-CHAT.md' --exclude='detect.sh' "PROMPT-TEMPLATES" "$TARGET/$d" >/dev/null 2>&1; then
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
            --help|-h)
                say "Usage: PACK=/path/to/pack init-project.sh [--update] [target-dir]"
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
        say "      no longer supported (sunset in v11 per BD-121)."
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
}

main "$@"
