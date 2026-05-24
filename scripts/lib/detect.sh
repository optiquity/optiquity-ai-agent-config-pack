# scripts/lib/detect.sh — shared detection helpers for v10 pack scripts.
#
# Sourced by init-project.sh, migrate-v9-to-v10.sh, and add-capability.sh.
# Every function prints a single `key: value` line (or multiple lines, one
# per match, for list-valued functions) to stdout. Every function is
# read-only with respect to the target project — no file writes, no git
# writes.
#
# Environment:
#   PACK   Absolute path to the pack repo. Required by detect_pack_path
#          (when no positional argument is given), detect_pack_version
#          (likewise), and detect_improperly_added_files (for roster
#          lookup).
#
# Functions default the target project to the current working directory;
# pass a path as the first positional argument to override.
#
# Do NOT add a shebang — this file is sourced, not executed.

# pack-surface: pack | client | ambiguous
#
# Surface routing (post BD-175 directory reorganization):
#   - Pack repo:    BACKLOG.md at <target>/pack-ops/ with `^\*\*BD-` entries
#                   (canonical post-v11.0 location).
#   - Client repo:  BACKLOG.md at <target>/docs/project/ (canonical) OR
#                   <target>/ (legacy v9 layout fallback) with `^\*\*TD-`
#                   entries.
#   - Both present: ambiguous (caller decides — pack-help prints both).
#   - Neither:      ambiguous (no signal to disambiguate).
#
# Candidate scan order: pack-ops/ (post-BD-175 pack-side canonical),
# docs/project/ (client-side canonical), root (legacy fixture / v9-layout
# fallback; retained for test-fixture and back-compat coverage — see
# scripts/tests/pack-help-test.sh fixture 1.3 "client repo (root
# BACKLOG.md, TD entries)" which still writes the legacy shape).
#
# Used by scripts/pack-help.sh (BD-075) and any future verb that needs
# to dispatch by surface without consulting tracker.toml.
detect_pack_surface() {
    local target="${1:-.}"
    local bd_seen=0 td_seen=0
    local backlog
    for backlog in "$target/pack-ops/BACKLOG.md" "$target/docs/project/BACKLOG.md" "$target/BACKLOG.md"; do
        [[ -f "$backlog" ]] || continue
        if grep -qE '^\*\*BD-[0-9]+ ' "$backlog" 2>/dev/null; then
            bd_seen=1
        fi
        if grep -qE '^\*\*TD-[0-9]+ ' "$backlog" 2>/dev/null; then
            td_seen=1
        fi
    done
    if (( bd_seen == 1 && td_seen == 0 )); then
        echo "pack-surface: pack"
    elif (( td_seen == 1 && bd_seen == 0 )); then
        echo "pack-surface: client"
    else
        echo "pack-surface: ambiguous"
    fi
}

# working-tree: clean|dirty
detect_clean_working_tree() {
    local target="${1:-.}"
    if ! git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
        echo "working-tree: dirty"
        return
    fi
    if [[ -z "$(git -C "$target" status --porcelain 2>/dev/null)" ]]; then
        echo "working-tree: clean"
    else
        echo "working-tree: dirty"
    fi
}

# git-repo: yes|no
detect_git_repo() {
    local target="${1:-.}"
    if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
        echo "git-repo: yes"
    else
        echo "git-repo: no"
    fi
}

# pack-path: valid|missing|not-a-repo
detect_pack_path() {
    local pack="${1:-${PACK:-}}"
    if [[ -z "$pack" || ! -d "$pack" ]]; then
        echo "pack-path: missing"
        return
    fi
    if ! git -C "$pack" rev-parse --git-dir >/dev/null 2>&1; then
        echo "pack-path: not-a-repo"
        return
    fi
    if [[ ! -d "$pack/project-template" ]]; then
        echo "pack-path: not-a-repo"
        return
    fi
    echo "pack-path: valid"
}

# pack-version: v<N.M> (exact tag at HEAD) | <branch-name> | unknown
detect_pack_version() {
    local pack="${1:-${PACK:-.}}"
    local tag
    tag=$(git -C "$pack" describe --tags --exact-match HEAD 2>/dev/null)
    if [[ -n "$tag" ]]; then
        echo "pack-version: $tag"
        return
    fi
    local branch
    branch=$(git -C "$pack" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
        echo "pack-version: $branch"
    else
        echo "pack-version: unknown"
    fi
}

# ai-config-markers: <comma list> | (none)
detect_ai_config() {
    local target="${1:-.}"
    local markers=()
    [[ -d "$target/.claude" ]]   && markers+=(".claude/")
    [[ -d "$target/.codex" ]]    && markers+=(".codex/")
    [[ -d "$target/.gemini" ]]   && markers+=(".gemini/")
    [[ -f "$target/CLAUDE.md" ]] && markers+=("CLAUDE.md")
    [[ -f "$target/AGENTS.md" ]] && markers+=("AGENTS.md")
    [[ -f "$target/GEMINI.md" ]] && markers+=("GEMINI.md")
    if (( ${#markers[@]} == 0 )); then
        echo "ai-config-markers: (none)"
    else
        local joined
        joined=$(IFS=,; printf '%s' "${markers[*]}")
        echo "ai-config-markers: $joined"
    fi
}

# x-files: <loc>/<name> lines (one per match) | x-files: (none)
# Scans the seven pack scan locations for `x-`-prefixed entries.
detect_x_files() {
    local target="${1:-.}"
    local found=0
    local loc entry name
    for loc in \
        ".claude/agents" \
        ".codex/agents" \
        ".gemini/agents" \
        ".claude/skills" \
        ".codex/skills" \
        ".gemini/skills" \
        "docs/pack/prompts"
    do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/x-*; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            echo "x-files: $loc/$name"
            found=1
        done
    done
    (( found == 0 )) && echo "x-files: (none)"
}

# improperly-added: <loc>/<name> lines | improperly-added: (none)
# Entries in the seven scan locations that are NOT pack-supplied (by
# roster lookup against $PACK/project-template/) and NOT `x-` prefixed.
# Requires $PACK to be set and to point at a valid pack repo.
detect_improperly_added_files() {
    local target="${1:-.}"
    local pack="${PACK:-}"
    if [[ -z "$pack" || ! -d "$pack/project-template" ]]; then
        echo "improperly-added: (error — PACK not set or pack invalid)"
        return 1
    fi

    # Build pack roster sets (newline-separated, sorted, deduped).
    local agent_roster skill_roster
    agent_roster=$(
        cd "$pack/project-template/.claude/agents" 2>/dev/null || return 1
        for f in *.md; do
            [[ -e "$f" ]] && printf '%s\n' "${f%.md}"
        done | sort -u
    )
    skill_roster=$(
        cd "$pack/project-template/skills" 2>/dev/null || return 1
        for d in */; do
            [[ -d "$d" ]] && printf '%s\n' "${d%/}"
        done | sort -u
    )

    local found=0
    local loc entry name stem

    # Agent dirs: top-level .md or .toml files; stem must be in agent_roster.
    for loc in ".claude/agents" ".codex/agents" ".gemini/agents"; do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/*.md "$target/$loc"/*.toml; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            stem="${name%.md}"
            stem="${stem%.toml}"
            if ! printf '%s\n' "$agent_roster" | grep -qx "$stem"; then
                echo "improperly-added: $loc/$name"
                found=1
            fi
        done
    done

    # Skills dirs: top-level subdirectories; name must be in skill_roster.
    for loc in ".claude/skills" ".codex/skills" ".gemini/skills"; do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/*/; do
            [[ -d "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            if ! printf '%s\n' "$skill_roster" | grep -qx "$name"; then
                echo "improperly-added: $loc/$name"
                found=1
            fi
        done
    done

    # Prompts dir: .md files; stem must be in agent_roster, start with
    # x-, or equal the reserved pm-chat identifier.
    if [[ -d "$target/docs/pack/prompts" ]]; then
        for entry in "$target/docs/pack/prompts"/*.md; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            stem="${name%.md}"
            [[ "$stem" == "pm-chat" ]] && continue
            if ! printf '%s\n' "$agent_roster" | grep -qx "$stem"; then
                echo "improperly-added: docs/pack/prompts/$name"
                found=1
            fi
        done
    fi

    (( found == 0 )) && echo "improperly-added: (none)"
}

# capabilities: <dim>:<val>, <dim>:<val>, ... | (none) | (placeholder) | (no CLAUDE.md) | (no Active skills line)
# Reads the `**Active skills:**` line from the target project's CLAUDE.md
# and maps each skill to a dimension value using a hardcoded table that
# mirrors the PLATFORM-SKILLS.md dimension rows. Consumed by
# add-capability.sh stage A2 per V10-DESIGN §5.14.2.
detect_installed_capabilities() {
    local target="${1:-.}"
    local claude="$target/CLAUDE.md"
    if [[ ! -f "$claude" ]]; then
        echo "capabilities: (no CLAUDE.md)"
        return
    fi

    local skills_line content
    skills_line=$(grep -m1 "^\*\*Active skills:\*\*" "$claude" 2>/dev/null || true)
    if [[ -z "$skills_line" ]]; then
        echo "capabilities: (no Active skills line)"
        return
    fi
    content="${skills_line#*\*\*Active skills:\*\* }"
    content="${content# }"
    if [[ "$content" == "["* ]]; then
        echo "capabilities: (placeholder)"
        return
    fi

    # Normalize skill list: strip backticks, split on commas, trim whitespace.
    local normalized skill
    normalized=$(printf '%s' "$content" | tr -d '`' | tr ',' '\n' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true)

    # Map skills → dimension:value. Skills that don't map to a standalone
    # dimension (architectural components, language-agnostic skills, or
    # general-purpose helpers) are silently ignored — they don't represent
    # independently-addable capabilities.
    local caps=()
    while IFS= read -r skill; do
        [[ -z "$skill" ]] && continue
        case "$skill" in
            swift-best-practices)  caps+=("language:swift") ;;
            python-best-practices) caps+=("language:python") ;;
            cpp-language)          caps+=("language:cpp") ;;
            c-language)            caps+=("language:c") ;;
            objc-language)         caps+=("language:objc") ;;
            macos-architecture)    caps+=("platform:macos") ;;
            ios-architecture)      caps+=("platform:ios") ;;
            grpc-patterns)         caps+=("protocol:grpc") ;;
            rest-patterns)         caps+=("protocol:rest") ;;
            graphql-patterns)      caps+=("protocol:graphql") ;;
            realtime-patterns)     caps+=("protocol:realtime") ;;
            messaging-patterns)    caps+=("protocol:messaging") ;;
            soap-patterns)         caps+=("protocol:soap") ;;
            # BD-144 (v11.0 skill-dimensions reframe Batch 5): D5 deployment
            # surface — reciprocal of the renamed `deployment:apple` and the
            # new `deployment:linux-container` rows in
            # scripts/add-capability.sh::capability_skills(). The pre-Batch-5
            # mappings (deployment-apple→role:apple-app,
            # deployment-python→role:python-server) were misclassified per
            # ARCHITECTURE-SKILL-DIMENSIONS.md §3.5; both flip atomically here.
            deployment-apple)      caps+=("deployment:apple") ;;
            deployment-python)     caps+=("deployment:linux-container") ;;
        esac
    done <<< "$normalized"

    if (( ${#caps[@]} == 0 )); then
        echo "capabilities: (none)"
    else
        local joined
        joined=$(printf '%s\n' "${caps[@]}" | sort -u | paste -sd, - | sed 's/,/, /g')
        echo "capabilities: $joined"
    fi
}

# python-data: yes|no
#
# BD-141 (v11.0 skill-dimensions reframe Batch 2). Concrete load
# predicate for the `python-data-architecture` skill. Replaces the
# fuzzy "multi-file Python with data access, async I/O, or ML
# inference; otherwise omit" prose previously used in
# PLATFORM-SKILLS.md.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `python-data: no` (no error to stderr).
#
# Output:
#   Single line `python-data: yes` or `python-data: no` on stdout.
#
# Markers (any one true → yes):
#   (a) requirements.txt OR pyproject.toml OR setup.py OR setup.cfg
#       lists any of these third-party dependencies (case-insensitive,
#       package-name boundary anchored): sqlalchemy, alembic, pydantic,
#       aiohttp, httpx, psycopg, psycopg2, aiomysql, asyncpg, redis,
#       pymongo, motor, boto3, aioboto3, pyarrow, pandas, numpy,
#       scikit-learn, torch, tensorflow.
#       NOTE: `protobuf` and `grpc-tools` were previously in this list
#       but are now covered exclusively by `protobuf_marker_detected()`
#       (BD-156). A protobuf-only project (e.g., `swift-protobuf` deps,
#       Python wire-format library) does not imply data-architecture
#       concerns — removing the over-trigger here keeps
#       `python-data-architecture` scoped to actual data handling.
#       (BD-035 audit finding F5 fix — see AUDIT-BD-035.md §3.)
#   (b) >= 5 *.py files outside tests/ and test_*.py / *_test.py.
#   (c) any *.py file outside tests/ contains an `import` of a
#       stdlib data-handling module — currently `sqlite3` or `csv`.
#       This catches the small pure-stdlib data-shaped CLI shape
#       (e.g., a 3-file SQLite-backed task runner) that the skill's
#       own applicability prose names ("files-as-DB") but markers (a)
#       and (b) miss because stdlib imports never appear in dependency
#       manifests and the file count is below the (b) threshold.
#       (BD-035 audit finding F1 fix — see AUDIT-BD-035.md §3.)
#
# Callers: scripts/init-project.sh (pack_skill_coverage_for python row);
# scripts/add-capability.sh references the predicate by comment only
# (the language:python skill set is coarser than init-project's
# auto-detect). PLATFORM-SKILLS.md cites the helper as the canonical
# predicate for the python-data-architecture row.
python_data_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "python-data: no"
        return 0
    fi

    # Marker (a): dependency manifests. Case-insensitive, anchored to
    # package-name boundaries via negated character classes. Lead
    # boundary asserts the byte before the name is NOT a name-char
    # ([A-Za-z0-9_-]) — this rejects substring matches like "numpy"
    # inside "numpyro" or "redis" inside "aioredis". Trail boundary
    # asserts the byte after the name is NOT a name-char or version-spec
    # continuation ([A-Za-z0-9_.-]) — this rejects "psycopg2-binary" via
    # "psycopg2", "redis-py-cluster" via "redis", etc. The `^` and `$`
    # alternatives cover line-start and line-end positions.
    #
    # Note: an earlier construction used a positive bracket class with
    # `\]` to include `]` as a literal — that was incorrect under POSIX
    # ERE (the first `]` after the class contents closes the class), so
    # versioned manifest entries like `sqlalchemy>=2.0` silently failed
    # to match. The negated-class construction below is portable and
    # avoids the bracket-escape landmine.
    local manifest pkg
    # F5 fix (BD-035 audit): `protobuf` and `grpc-tools` removed from
    # this list — they belong to `protobuf_marker_detected()` (BD-156).
    local pkgs="sqlalchemy|alembic|pydantic|aiohttp|httpx|psycopg|psycopg2|aiomysql|asyncpg|redis|pymongo|motor|boto3|aioboto3|pyarrow|pandas|numpy|scikit-learn|torch|tensorflow"
    local pattern="(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])"
    for manifest in \
        "$target/requirements.txt" \
        "$target/pyproject.toml" \
        "$target/setup.py" \
        "$target/setup.cfg"
    do
        [[ -f "$manifest" ]] || continue
        if grep -iqE "$pattern" "$manifest" 2>/dev/null; then
            echo "python-data: yes"
            return 0
        fi
    done

    # Marker (b): >= 5 .py files outside tests/.
    local py_files py_count
    py_files=$(find "$target" -name "*.py" \
        -not -path "*/tests/*" \
        -not -name "test_*.py" \
        -not -name "*_test.py" \
        -type f 2>/dev/null)
    py_count=$(printf '%s\n' "$py_files" | grep -c . | tr -d '[:space:]')
    if [[ -n "$py_count" ]] && (( py_count >= 5 )); then
        echo "python-data: yes"
        return 0
    fi

    # Marker (c): stdlib data-handling imports in any non-test .py file.
    # Scope is intentionally narrow — `sqlite3` (files-as-DB / persistent
    # state) and `csv` (tabular ETL) are both explicitly named in the
    # python-data-architecture SKILL.md applicability prose and are the
    # canonical stdlib data-handling stories for small Python tools.
    # The grep pattern is line-anchored to defeat prose mentions in
    # comments / docstrings ("we don't import sqlite3 here") — only an
    # actual `import sqlite3` / `from sqlite3 import ...` statement
    # at line start (with optional leading whitespace) qualifies.
    # Other stdlib modules (json, urllib, http.client, asyncio) are
    # deliberately excluded — `json` is too noisy on its own (config
    # files, simple parsing) and `asyncio`/`urllib` blocking-I/O
    # concerns are already covered by `python-best-practices` rule 26
    # which loads unconditionally for D2=python.
    if [[ -n "$py_files" ]]; then
        if printf '%s\n' "$py_files" \
           | xargs grep -lE '^[[:space:]]*(import|from)[[:space:]]+(sqlite3|csv)([[:space:]]|\.|,|$)' \
                  2>/dev/null | head -n 1 | grep -q .; then
            echo "python-data: yes"
            return 0
        fi
    fi

    echo "python-data: no"
}

# protobuf-marker: yes|no
#
# BD-156 (v11.0 PLATFORM-SKILLS.md naming-convention codification batch).
# Concrete load predicate for the `protobuf-patterns` skill. Mirrors the
# BD-141 `python_data_marker_detected()` shape: single positional
# argument defaulting to cwd; tolerates missing target as a `no`;
# emits a single `protobuf-marker: yes|no` line on stdout.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `protobuf-marker: no` (no error to stderr).
#
# Output:
#   Single line `protobuf-marker: yes` or `protobuf-marker: no`.
#
# Markers (any one true → yes):
#   (a) project tree contains any `.proto` file (excluding nested
#       node_modules/, .git/, build/, .venv/ — common large vendored
#       trees that should not influence detection).
#   (b) dependency manifests list any of these protobuf-tooling
#       packages (case-insensitive, package-name boundary anchored):
#         Python (requirements.txt / pyproject.toml / setup.py /
#                 setup.cfg): `protobuf`, `grpc-tools`, `grpcio-tools`,
#                 `protoc`.
#         Swift  (Package.swift / Package.resolved): `swift-protobuf`,
#                 `SwiftProtobuf`, `grpc-swift-2`, `grpc-swift`.
#         Generic (any of the above filenames OR `buf.yaml` /
#                 `buf.gen.yaml` present).
#
# Manifest scan reuses the BD-141 negated-character-class pattern
# construction (rejects substring matches and version-suffix matches
# like `protobuf-c` via `protobuf`).
#
# Callers: scripts/init-project.sh `pack_skill_coverage_for proto` row
# (BD-156 — wires alongside the existing `grpc-patterns` coverage);
# scripts/add-capability.sh references the predicate by comment only
# (the protocol:grpc skill set declaratively adds grpc-patterns; the
# protobuf-marker → protobuf-patterns load is intersection-table-driven
# and applies regardless of capability declaration).
# PLATFORM-SKILLS.md cites the helper as the canonical predicate for
# the protobuf-patterns intersection row.
protobuf_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "protobuf-marker: no"
        return 0
    fi

    # Marker (a): any `.proto` file in the project tree, excluding
    # large vendored / generated trees.
    if find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \) -prune \
        -o -type f -name '*.proto' -print 2>/dev/null \
        | head -n 1 | grep -q .; then
        echo "protobuf-marker: yes"
        return 0
    fi

    # Marker (b): dependency manifests. Same negated-character-class
    # boundary construction as python_data_marker_detected() (BD-141)
    # — rejects substring matches like `protobuf-c-bindings` via
    # `protobuf` and `swift-protobuf-runtime` via `swift-protobuf`.
    local manifest pkg_pattern
    # Python-side packages (case-insensitive grep handles the `iqE`).
    local py_pkgs="protobuf|grpc-tools|grpcio-tools|protoc"
    local py_pattern="(^|[^A-Za-z0-9_-])(${py_pkgs})($|[^A-Za-z0-9_.-])"
    for manifest in \
        "$target/requirements.txt" \
        "$target/pyproject.toml" \
        "$target/setup.py" \
        "$target/setup.cfg"
    do
        [[ -f "$manifest" ]] || continue
        if grep -iqE "$py_pattern" "$manifest" 2>/dev/null; then
            echo "protobuf-marker: yes"
            return 0
        fi
    done
    # Swift-side packages.
    local swift_pkgs="swift-protobuf|SwiftProtobuf|grpc-swift-2|grpc-swift"
    local swift_pattern="(^|[^A-Za-z0-9_-])(${swift_pkgs})($|[^A-Za-z0-9_.-])"
    for manifest in \
        "$target/Package.swift" \
        "$target/Package.resolved"
    do
        [[ -f "$manifest" ]] || continue
        if grep -qE "$swift_pattern" "$manifest" 2>/dev/null; then
            echo "protobuf-marker: yes"
            return 0
        fi
    done
    # Generic buf-tooling configs — strong signal that protobuf is in
    # use even when no `.proto` file is yet committed (e.g., a fresh
    # repo skeleton).
    if [[ -f "$target/buf.yaml" || -f "$target/buf.gen.yaml" ]]; then
        echo "protobuf-marker: yes"
        return 0
    fi

    echo "protobuf-marker: no"
}

# swiftdata-marker: yes|no
#
# BD-157 (v11.0 PLATFORM-SKILLS.md naming-convention codification batch).
# Concrete load predicate for the `apple-swiftdata-patterns` skill.
# Mirrors the BD-156 `protobuf_marker_detected()` shape: single
# positional argument defaulting to cwd; tolerates missing target as a
# `no`; emits a single `swiftdata-marker: yes|no` line on stdout.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `swiftdata-marker: no` (no error to stderr).
#
# Output:
#   Single line `swiftdata-marker: yes` or `swiftdata-marker: no`.
#
# Markers (any one true → yes), per architecture §3.7 / BD-157:
#   (a) any `.swift` file in the project tree contains
#       `import SwiftData` (excluding nested vendored / build trees:
#       node_modules/, .git/, build/, .venv/, venv/, .tox/, .build/,
#       DerivedData/, Pods/, Carthage/).
#   (b) any `.swift` file in the project tree contains an `@Model`
#       macro attribute on a class declaration. The grep pattern
#       matches `@Model` followed by EOL, whitespace, or `(` so that
#       custom-annotation lookalikes (`@ModelAttribute`, `@Modeled`)
#       are rejected by the boundary.
#   (c) `Package.swift` / `Package.resolved` / `Podfile` /
#       `Podfile.lock` lists SwiftData explicitly. SwiftData ships as
#       a first-party Apple framework on iOS 17+ / macOS 14+, so a
#       project rarely declares it as an explicit SPM / CocoaPods
#       dependency — markers (a) and (b) are the primary signals,
#       and marker (c) is included for completeness (e.g. cross-
#       compile shims, indirect SwiftData wrappers, or CocoaPods
#       binary distributions of SwiftData-bridging helpers).
#
# Callers: scripts/init-project.sh `pack_skill_coverage_for swift` row
# (BD-157 — wires alongside the existing apple-architecture-core /
# swift-best-practices coverage); scripts/add-capability.sh references
# the predicate by comment only (the platform:ios / platform:macos
# capability rows declare apple-architecture-core deterministically;
# the swiftdata-marker → apple-swiftdata-patterns load is intersection-
# table-driven and applies regardless of capability declaration).
# PLATFORM-SKILLS.md cites the helper as the canonical predicate for
# the apple-swiftdata-patterns intersection row.
swiftdata_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "swiftdata-marker: no"
        return 0
    fi

    # Markers (a) and (b): scan `.swift` files, excluding common
    # vendored / generated / build trees. Combine into a single find
    # → grep pipeline so we only enumerate the file list once.
    local swift_hits
    swift_hits=$(find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \
           -o -path '*/.build' -o -path '*/DerivedData' \
           -o -path '*/Pods' -o -path '*/Carthage' \) -prune \
        -o -type f -name '*.swift' -print 2>/dev/null)
    if [[ -n "$swift_hits" ]]; then
        # Marker (a): `import SwiftData` (line-anchored to defeat
        # comment-prose mentions like `// not import SwiftData`).
        if printf '%s\n' "$swift_hits" \
           | xargs grep -lE '^[[:space:]]*import[[:space:]]+SwiftData([[:space:]]|$)' \
                  2>/dev/null | head -n 1 | grep -q .; then
            echo "swiftdata-marker: yes"
            return 0
        fi
        # Marker (b): `@Model` attribute. Boundary rejects
        # `@ModelAttribute`, `@Modeled`, and similar look-alikes —
        # the trailing class is `[^A-Za-z0-9_]` (`@Model` followed
        # by EOL, whitespace, or `(` for `@Model(...)` parameter
        # forms).
        if printf '%s\n' "$swift_hits" \
           | xargs grep -lE '@Model([[:space:]]|\(|$)' \
                  2>/dev/null | head -n 1 | grep -q .; then
            echo "swiftdata-marker: yes"
            return 0
        fi
    fi

    # Marker (c): dependency manifests. SwiftData is first-party so
    # this rarely fires; supports cross-compile shims and indirect
    # bridging helpers. Same negated-character-class boundary
    # construction as protobuf_marker_detected() (BD-156) — rejects
    # substring matches like `SwiftDataMocks` or `SwiftDataKit` via
    # `SwiftData`.
    local manifest sd_pattern
    sd_pattern='(^|[^A-Za-z0-9_-])(SwiftData|swift-data)($|[^A-Za-z0-9_.-])'
    for manifest in \
        "$target/Package.swift" \
        "$target/Package.resolved" \
        "$target/Podfile" \
        "$target/Podfile.lock"
    do
        [[ -f "$manifest" ]] || continue
        if grep -qE "$sd_pattern" "$manifest" 2>/dev/null; then
            echo "swiftdata-marker: yes"
            return 0
        fi
    done

    echo "swiftdata-marker: no"
}

# python-observability-marker: yes|no
#
# BD-162 (v11.0 python-observability-patterns skill batch).
# Concrete load predicate for the `python-observability-patterns` skill.
# Mirrors the BD-141 `python_data_marker_detected()` and BD-156
# `protobuf_marker_detected()` and BD-157 `swiftdata_marker_detected()`
# shape: single positional argument defaulting to cwd; tolerates
# missing target as a `no`; emits a single
# `python-observability-marker: yes|no` line on stdout.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `python-observability-marker: no` (no error
#        to stderr).
#
# Output:
#   Single line `python-observability-marker: yes` or
#   `python-observability-marker: no`.
#
# Markers (any one true → yes):
#   (a) Dependency manifests (requirements.txt OR pyproject.toml OR
#       setup.py OR setup.cfg OR uv.lock) list any of these
#       observability third-party dependencies (case-insensitive,
#       package-name boundary anchored):
#         OpenTelemetry exact-name packages: opentelemetry-api,
#           opentelemetry-sdk, opentelemetry-distro,
#           prometheus-client, prometheus_client, structlog,
#           python-json-logger.
#         OpenTelemetry contrib prefix-match packages:
#           opentelemetry-instrumentation-* (any package whose name
#           starts with opentelemetry-instrumentation-) and
#           opentelemetry-exporter-* (any package whose name starts
#           with opentelemetry-exporter-).
#       The exact-name list uses the BD-141 negated-character-class
#       boundary construction `(^|[^A-Za-z0-9_-])(<pkgs>)($|[^A-Za-z0-9_.-])`
#       to reject substring matches like `not-opentelemetry-clone`
#       via `opentelemetry-api`. The prefix-match packages use a
#       leading-boundary anchor with a trailing `[A-Za-z0-9_.-]+`
#       continuation to admit legitimate sub-packages
#       (e.g., `opentelemetry-instrumentation-grpc`,
#       `opentelemetry-exporter-otlp-proto-grpc`) while preserving
#       the substring-rejection invariant.
#   (b) Source file imports. Any `.py` file in the project tree
#       (excluding nested vendored / build trees: node_modules/,
#       .git/, build/, .venv/, venv/, .tox/, per the BD-156 prune
#       list) contains a line matching
#       `^[[:space:]]*(import|from)[[:space:]]+(opentelemetry|prometheus_client|structlog)([[:space:]]|\.|,|$)`.
#       Line-anchored to defeat prose mentions in comments /
#       docstrings (per BD-141 marker-c convention). Matches
#       `import opentelemetry`, `from opentelemetry import …`,
#       `from opentelemetry.foo import …` (via the `\.`
#       alternative), `import prometheus_client`,
#       `from prometheus_client import …`, `import structlog`,
#       `from structlog import …`.
#
# Callers: scripts/init-project.sh `pack_skill_coverage_for python` row
# (BD-162 — wires alongside the existing python-best-practices /
# python-data-architecture coverage); scripts/add-capability.sh
# references the predicate by comment only (the language:python
# capability set declaratively adds python-observability-patterns;
# the role:python-server capability adds it as well — the marker-
# gated intersection-table load applies regardless of capability
# declaration). PLATFORM-SKILLS.md cites the helper as the canonical
# predicate for the python-observability-patterns intersection row.
python_observability_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "python-observability-marker: no"
        return 0
    fi

    # Marker (a): dependency manifests. Two patterns combined —
    # exact-name packages via BD-141 negated-character-class boundary,
    # and prefix-match packages (opentelemetry-instrumentation-*,
    # opentelemetry-exporter-*) via leading-boundary + trailing
    # name-char continuation. Both run case-insensitive (-iqE).
    local manifest
    local exact_pkgs="opentelemetry-api|opentelemetry-sdk|opentelemetry-distro|prometheus-client|prometheus_client|structlog|python-json-logger"
    local exact_pattern="(^|[^A-Za-z0-9_-])(${exact_pkgs})($|[^A-Za-z0-9_.-])"
    local prefix_pattern="(^|[^A-Za-z0-9_-])opentelemetry-(instrumentation|exporter)-[A-Za-z0-9_.-]+"
    for manifest in \
        "$target/requirements.txt" \
        "$target/pyproject.toml" \
        "$target/setup.py" \
        "$target/setup.cfg" \
        "$target/uv.lock"
    do
        [[ -f "$manifest" ]] || continue
        if grep -iqE "$exact_pattern" "$manifest" 2>/dev/null; then
            echo "python-observability-marker: yes"
            return 0
        fi
        if grep -iqE "$prefix_pattern" "$manifest" 2>/dev/null; then
            echo "python-observability-marker: yes"
            return 0
        fi
    done

    # Marker (b): source file imports. Scan `.py` files outside
    # vendored / build trees. Line-anchored grep rejects prose
    # mentions in comments / docstrings (per BD-141 marker-c
    # convention). Module-name boundary uses the
    # `([[:space:]]|\.|,|$)` trailing alternative to admit
    # `import opentelemetry`, `from opentelemetry.trace import ...`,
    # and `from opentelemetry import trace, metrics`.
    local py_files
    py_files=$(find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \) -prune \
        -o -type f -name '*.py' -print 2>/dev/null)
    if [[ -n "$py_files" ]]; then
        if printf '%s\n' "$py_files" \
           | xargs grep -lE '^[[:space:]]*(import|from)[[:space:]]+(opentelemetry|prometheus_client|structlog)([[:space:]]|\.|,|$)' \
                  2>/dev/null | head -n 1 | grep -q .; then
            echo "python-observability-marker: yes"
            return 0
        fi
    fi

    echo "python-observability-marker: no"
}

# target-pack-version: vN | unknown
#
# Detect the major pack version installed in the *target* project (NOT the
# pack repo). Used by the BD-119 migrator framework to decide which adapter
# applies, and by external harnesses (BD-114) to dispatch correctly.
#
# Signal cascade (architecture §5.1, cheapest first; first positive match wins):
#   1. tracker.toml `[pack]\nversion = "vN"` field, when present (opt-in:
#      absence is NOT a v10 signal — the cascade continues).
#   2. Trinity addenda fingerprint — v11 trinity files contain the line
#      `run \`pack help\` for the full verb list`.
#   3. Surface markers — v11-only files: pack-help SKILL.md per CLI,
#      ISSUE_TEMPLATE/work-item.yml, docs/pack/HELP-FRAGMENT.md.
#   4. Negative markers — v10-shape: docs/pack/PROMPT-TEMPLATES.md present
#      AND none of the v11 surface markers above.
#   5. Otherwise: `unknown`.
#
# Echoes a single line to stdout with no prefix, e.g. `v11`, `v10`, or
# `unknown`. Read-only with respect to the target.
detect_target_pack_version() {
    local target="${1:-.}"

    # Signal 1: explicit tracker.toml [pack].version field. Opt-in.
    if [[ -f "$target/tracker.toml" ]]; then
        local pack_ver
        pack_ver=$(awk '
            /^\[pack\]/    { in_pack = 1; next }
            /^\[/          { in_pack = 0 }
            in_pack && /^[[:space:]]*version[[:space:]]*=/ {
                # Extract value between quotes; tolerate either kind.
                line = $0
                sub(/^[^=]*=[[:space:]]*/, "", line)
                gsub(/[[:space:]]*$/, "", line)
                gsub(/^"/, "", line); gsub(/"$/, "", line)
                gsub(/^\x27/, "", line); gsub(/\x27$/, "", line)
                print line
                exit
            }
        ' "$target/tracker.toml" 2>/dev/null)
        if [[ -n "$pack_ver" ]]; then
            echo "$pack_ver"
            return 0
        fi
    fi

    # Signal 2: trinity addenda fingerprint (v11+).
    local trinity
    for trinity in CLAUDE.md AGENTS.md GEMINI.md; do
        if [[ -f "$target/$trinity" ]]; then
            if grep -q 'run `pack help` for the full verb list' \
               "$target/$trinity" 2>/dev/null; then
                echo "v11"
                return 0
            fi
        fi
    done

    # Signal 3: v11-only surface markers.
    if [[ -f "$target/.claude/skills/pack-help/SKILL.md" \
       || -f "$target/.codex/skills/pack-help/SKILL.md" \
       || -f "$target/.gemini/commands/pack-help.toml" \
       || -f "$target/.github/ISSUE_TEMPLATE/work-item.yml" \
       || -f "$target/docs/pack/HELP-FRAGMENT.md" ]]; then
        echo "v11"
        return 0
    fi

    # Signal 4: v10-shape (negative markers — v9-era root docs already
    # relocated, AND no v11 surface).
    if [[ -f "$target/CLAUDE.md" && -d "$target/.claude" ]]; then
        if [[ -f "$target/docs/pack/PROMPT-TEMPLATES.md" \
           || -f "$target/docs/pack/PM-CHAT.md" \
           || -f "$target/docs/pack/METHODOLOGY.md" ]]; then
            echo "v10"
            return 0
        fi
        # CLAUDE.md + .claude/ but none of the v10/v11 distinguishing markers:
        # treat as v10 (the migrator's existing sanity check accepts this).
        echo "v10"
        return 0
    fi

    echo "unknown"
}
