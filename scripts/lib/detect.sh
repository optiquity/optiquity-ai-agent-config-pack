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
# <!-- DENY-LIST-CONTENT-START -->
# Surface routing:
#   - Pack repo:    the `/backlog/` per-entry tree at <target>/backlog/
#                   with `BD-NNN[suffix].md` entry files (BD-203 no-mirror
#                   SSOT; there is no monolithic pack-ops/BACKLOG.md).
#   - Client repo:  the `docs/project/backlog/` per-entry tree at
#                   <target>/docs/project/backlog/ with `TD-NNN.md` entry
#                   files (BD-206 no-mirror SSOT). Pre-v11 fallback: a
#                   BACKLOG.md monolith at <target>/docs/project/ OR
#                   <target>/ (legacy layout) with `^\*\*TD-` entries.
#   - Both present: ambiguous (caller decides — pack-help prints both).
#   - Neither:      ambiguous (no signal to disambiguate).
#
# Candidate scan order: pack-side `/backlog/` per-entry tree (pack-side
# canonical), then client-side `docs/project/backlog/` per-entry tree
# (client-side canonical, BD-206 no-mirror), then the legacy monolith
# probe (docs/project/BACKLOG.md canonical, root BACKLOG.md legacy-layout
# fallback) — retained as a pre-v11 fallback for test-fixture and
# back-compat coverage (see scripts/tests/pack-help-test.sh fixtures 1.2
# "docs/project/BACKLOG.md" + 1.3 "root BACKLOG.md, TD entries" which
# still write the legacy shape). BD-203 repointed the pack-side branch to
# the tree; BD-206 repoints the client-side branch to the
# `docs/project/backlog/` per-entry tree (this probe lives OUTSIDE the
# DENY-LIST-CONTENT markers; the legacy monolith probe stays inside).
# <!-- DENY-LIST-CONTENT-END -->
#
# Used by scripts/pack-help.sh and any future verb that needs to
# dispatch by surface without consulting tracker.toml.
detect_pack_surface() {
    local target="${1:-.}"
    local bd_seen=0 td_seen=0
    local backlog
    # BD-203 A14b — PACK-SURFACE branch (repointed to the no-mirror tree):
    # the pack signal is a `/backlog/` per-entry tree carrying at least
    # one `BD-NNN[suffix].md` entry file. The CLIENT-surface per-entry
    # probe below (BD-206 O5) is its parallel; the legacy monolith probe
    # remains as a pre-v11 fallback inside the DENY-LIST-CONTENT markers.
    # detect.sh is in `_SANCTIONED_PACK_SIDE_SHIPPED` (CI Check 47); these
    # within-file conditionals leave the install map↔constant equality
    # unaffected.
    if [[ -d "$target/backlog" ]]; then
        local ent
        for ent in "$target/backlog"/BD-*.md; do
            [[ -f "$ent" ]] || continue
            if printf '%s\n' "$(basename "$ent")" | grep -qE '^BD-[0-9]+\.md$'; then
                bd_seen=1
                break
            fi
        done
    fi
    # BD-206 O5 — CLIENT-SURFACE branch (repointed to the no-mirror tree,
    # PARALLEL to the pack-surface branch above): the client signal is a
    # `docs/project/backlog/` per-entry tree carrying at least one
    # `TD-NNN.md` entry file (the no-mirror SSOT). This probe lives OUTSIDE
    # the `DENY-LIST-CONTENT` markers (pack-surface style) so Check 40 is
    # unaffected; the legacy-monolith probe stays inside the markers below
    # as a pre-v11 fallback (a client mid-migration may still carry the
    # monolith INPUT). detect.sh is in `_SANCTIONED_PACK_SIDE_SHIPPED` (CI
    # Check 47); this within-file conditional adds no install entry and
    # leaves the install map↔constant equality unaffected.
    if [[ -d "$target/docs/project/backlog" ]]; then
        local cli_ent
        for cli_ent in "$target/docs/project/backlog"/TD-*.md; do
            [[ -f "$cli_ent" ]] || continue
            if printf '%s\n' "$(basename "$cli_ent")" | grep -qE '^TD-[0-9]+\.md$'; then
                td_seen=1
                break
            fi
        done
    fi
    # <!-- DENY-LIST-CONTENT-START -->
    # Legacy pre-v11 monolith fallback: a client mid-migration (or a v9
    # legacy-layout tree) may still carry a `BACKLOG.md` monolith INPUT
    # rather than the per-entry tree. Retained for back-compat + the
    # test-fixture coverage (pack-help-test.sh fixtures 1.2/1.3 still write
    # the legacy shape).
    for backlog in "$target/docs/project/BACKLOG.md" "$target/BACKLOG.md"; do
    # <!-- DENY-LIST-CONTENT-END -->
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
    [[ -d "$target/.agents" ]]   && markers+=(".agents/")
    # Legacy-READ carve-out: a departing v10 `.gemini/` tree is still
    # detected so the migrator can find + relocate it (carve-out ii).
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

# _tp_dir_nonempty <path> — return-code predicate: 0 iff <path> is a directory
# containing at least one entry (dotfiles included). A BARE (empty) dot-dir
# returns 1. Used by detect_trinity_provenance's P1 config-shape guard.
_tp_dir_nonempty() {
    local d="$1"
    [[ -d "$d" ]] || return 1
    local e
    for e in "$d"/* "$d"/.[!.]*; do
        [[ -e "$e" ]] && return 0
    done
    return 1
}

# trinity-provenance: pack | handwritten | ambiguous  (single bare token)
#
# BD-285 C2 narrow provenance classifier for the guided keep/replace/merge
# branch. Distinguishes a HANDWRITTEN trinity (a human's own CLAUDE.md /
# AGENTS.md / GEMINI.md — possibly a lone starter file) from a PACK-installed
# trinity (any pack version) so init offers the guided branch ONLY for the
# handwritten case. Read-only with respect to the target.
#
# Returns (bare token on stdout, no key prefix):
#   pack        — a load-bearing pack fingerprint is present: the v11 /pm-help
#                 verb line, a project-owned marker pair, a v11 client surface
#                 file, or the v10 marker-bearing shape. Route to the migrator
#                 STOP.
#   handwritten — a trinity FILE is present, NO pack fingerprint, and the
#                 AI-config agent/skill trees are all BARE/absent (only a lone
#                 structured config file and/or a bare dot-dir). Route to guided.
#   ambiguous   — no trinity file, OR a POPULATED foreign agent/skill tree
#                 (.claude/agents|skills, .codex/agents|skills, .agents/agents|skills,
#                 .gemini/agents|skills non-empty). Generic STOP.
#
# EXCLUDES detect_target_pack_version's lenient "CLAUDE.md + .claude/ ⇒ v10"
# fallback (Signal 4's bare arm): a bare CLAUDE.md + empty .claude/ is exactly
# the handwritten starter this branch serves, so that lenient arm must NOT
# force a `pack` verdict here. detect_target_pack_version + detect_ai_config are
# left byte-unchanged.
#
# F-6: `.github/ISSUE_TEMPLATE/work-item.yml` is NOT in this helper's v11
# surface set (a hand-authored repo may carry a GitHub issue form that is not a
# pack signal); detect_target_pack_version keeps its own copy of that marker.
detect_trinity_provenance() {
    local target="${1:-.}"
    local t

    # A trinity file must be present at all — else this is not a guided case.
    local has_trinity=0
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        [[ -f "$target/$t" ]] && { has_trinity=1; break; }
    done
    if (( has_trinity == 0 )); then
        echo "ambiguous"
        return 0
    fi

    # Fingerprint 1: the v11 /pm-help verb line in any trinity file.
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        [[ -f "$target/$t" ]] || continue
        if grep -q 'run `/pm-help` for the full verb list' "$target/$t" 2>/dev/null; then
            echo "pack"
            return 0
        fi
    done

    # Fingerprint 2: a project-owned marker pair (BEGIN + END) in any trinity
    # file — only a pack-installed trinity carries the marker seed slots.
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        [[ -f "$target/$t" ]] || continue
        if grep -q '<!-- BEGIN project-owned' "$target/$t" 2>/dev/null \
           && grep -q '<!-- END project-owned' "$target/$t" 2>/dev/null; then
            echo "pack"
            return 0
        fi
    done

    # Fingerprint 3: a v11-only client surface file (F-6: work-item.yml is NOT
    # in this set).
    if [[ -f "$target/.claude/skills/pm-help/SKILL.md" \
       || -f "$target/.codex/skills/pm-help/SKILL.md" \
       || -f "$target/.agents/skills/pm-help/SKILL.md" \
       || -f "$target/docs/pack/HELP-FRAGMENT.md" ]]; then
        echo "pack"
        return 0
    fi

    # Fingerprint 4: the DISTINGUISHING v10 marker-bearing shape — a relocated
    # v10 doc under docs/pack/ alongside CLAUDE.md + .claude/. (This is NOT the
    # lenient bare CLAUDE.md+.claude fallback, which is excluded on purpose.)
    if [[ -f "$target/CLAUDE.md" && -d "$target/.claude" ]]; then
        if [[ -f "$target/docs/pack/PROMPT-TEMPLATES.md" \
           || -f "$target/docs/pack/PM-CHAT.md" \
           || -f "$target/docs/pack/METHODOLOGY.md" ]]; then
            echo "pack"
            return 0
        fi
    fi

    # P1 config-shape guard: a POPULATED foreign agent/skill tree is NOT a
    # handwritten trinity — reaching the guided branch would layer v11 over a
    # foreign tool's agents/skills. Only a trinity FILE + at most a lone
    # structured config file and/or a BARE dot-dir may reach the guided branch.
    # (Scoped to the agent/skill SUBTREES — not the whole .codex/.agents dirs —
    # so a lone structured config (.claude/settings.json, .agents/mcp_config.json,
    # .codex/config.toml, .codex/requirements.toml) still reaches the guided
    # branch's safe 2-way structured key-union.)
    # `.gemini/agents|skills` is included for detection completeness: v11 never
    # writes `.gemini/` (it is a migrator-only legacy-READ carve-out, recognized
    # by detect_ai_config), but v10 used `.gemini/agents` as its Antigravity
    # agent roster, so a POPULATED `.gemini/agents|skills` is a bona-fide foreign
    # agent/skill tree. Routing it to `ambiguous` STOPs the guided fresh-install
    # and points the user at the migrator (whose job is to retire `.gemini/`)
    # rather than silently layering v11 alongside a stranded legacy roster.
    if _tp_dir_nonempty "$target/.claude/agents" \
       || _tp_dir_nonempty "$target/.claude/skills" \
       || _tp_dir_nonempty "$target/.codex/agents" \
       || _tp_dir_nonempty "$target/.codex/skills" \
       || _tp_dir_nonempty "$target/.agents/agents" \
       || _tp_dir_nonempty "$target/.agents/skills" \
       || _tp_dir_nonempty "$target/.gemini/agents" \
       || _tp_dir_nonempty "$target/.gemini/skills"; then
        echo "ambiguous"
        return 0
    fi

    # A trinity FILE, no pack fingerprint, no populated foreign agent/skill
    # tree → the handwritten starter this branch serves.
    echo "handwritten"
    return 0
}

# x-files: <loc>/<name> lines (one per match) | x-files: (none)
# Scans the six pack scan locations for `x-`-prefixed entries.
detect_x_files() {
    local target="${1:-.}"
    local found=0
    local loc entry name
    for loc in \
        ".claude/agents" \
        ".codex/agents" \
        ".claude/skills" \
        ".codex/skills" \
        ".agents/skills" \
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
# Entries in the six scan locations that are NOT pack-supplied (by
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
    # Antigravity agents ship as a plugin bundle (.agents-plugin/), not a
    # loose per-CLI dir, so only the Claude/Codex loose dirs are scanned.
    for loc in ".claude/agents" ".codex/agents"; do
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
    for loc in ".claude/skills" ".codex/skills" ".agents/skills"; do
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

# antigravity-skills-layout: loose | bundled | none
#
# Classifies how an EXISTING Antigravity project lays out its skills, so a
# first-time pack install into that project preserves the project's choice
# rather than forcing one (frozen decision 2 / OQ-E; see
# DESIGN-BD-221 §2.1). The pack itself distributes skills LOOSE to
# `.agents/skills/<name>/SKILL.md`; this helper only governs the
# existing-install path.
#
# Deterministic classification (order matters):
#   1. A loose `.agents/skills/` layout present → `loose`. If BOTH a loose
#      `.agents/skills/` AND a plugin `skills/` layout exist, LOOSE wins
#      (deterministic tie-break, per decision 2). New installs → loose.
#   2. Else, a plugin that bundles skills (`.agents-plugin/<plugin>/skills/`)
#      AND no loose `.agents/skills/` → `bundled` ONLY when the plugin is
#      the pack's own `optiquity-agents` bundle. A foreign / non-standard
#      plugin is NOT respected as a bundled-skills host → falls through to
#      `loose` (the pack distributes loose alongside it).
#   3. Else → `none` (no Antigravity skills layout present; a new install
#      will create the loose layout).
detect_antigravity_skills_layout() {
    local target="${1:-.}"

    # (1) Loose layout wins whenever present (also the BOTH-present tie-break).
    if [[ -d "$target/.agents/skills" ]]; then
        echo "antigravity-skills-layout: loose"
        return 0
    fi

    # (2) Bundled skills are respected ONLY for the pack's own bundle.
    if [[ -d "$target/.agents-plugin/optiquity-agents/skills" ]]; then
        echo "antigravity-skills-layout: bundled"
        return 0
    fi

    # A foreign plugin's bundled skills are NOT respected — the pack
    # distributes loose alongside it. Any other `.agents-plugin/*/skills`
    # falls through here to `none` so the install creates the loose layout.
    echo "antigravity-skills-layout: none"
    return 0
}

# capabilities: <dim>:<val>, <dim>:<val>, ... | (none) | (placeholder) | (no CLAUDE.md) | (no Active skills line)
# Reads the `**Active skills:**` line from the target project's CLAUDE.md
# and maps each skill to a dimension value using a hardcoded table that
# mirrors the skill-to-dimension rows. Consumed by add-capability.sh
# stage A2.
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
            # D5 deployment surface — reciprocal of the `deployment:apple`
            # and `deployment:linux-container` rows in
            # capability-tables.sh::capability_skills(). Earlier
            # mappings (deployment-apple→role:apple-app,
            # deployment-python→role:python-server) were misclassified; both
            # flip to the deployment dimension here.
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
# Concrete load predicate for the `python-data-architecture` skill.
# Replaces a fuzzy "multi-file Python with data access, async I/O, or
# ML inference; otherwise omit" prose heuristic with deterministic
# markers.
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
#       NOTE: `protobuf` and `grpc-tools` are intentionally absent here —
#       they are covered exclusively by `protobuf_marker_detected()`. A
#       protobuf-only project (e.g., `swift-protobuf` deps, Python
#       wire-format library) does not imply data-architecture concerns,
#       so excluding them keeps `python-data-architecture` scoped to
#       actual data handling.
#   (b) >= 5 *.py files outside tests/ and test_*.py / *_test.py.
#   (c) any *.py file outside tests/ contains an `import` of a
#       stdlib data-handling module — currently `sqlite3` or `csv`.
#       This catches the small pure-stdlib data-shaped CLI shape
#       (e.g., a 3-file SQLite-backed task runner) that the skill's
#       own applicability prose names ("files-as-DB") but markers (a)
#       and (b) miss because stdlib imports never appear in dependency
#       manifests and the file count is below the (b) threshold.
#
# Callers: scripts/init-project.sh (pack_skill_coverage_for python row);
# scripts/add-capability.sh references the predicate by comment only
# (the language:python skill set is coarser than init-project's
# auto-detect). This helper is the canonical predicate for the
# python-data-architecture row.
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
    # `protobuf` and `grpc-tools` are intentionally absent from this
    # list — they belong to `protobuf_marker_detected()`.
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

    # Marker (b): >= 5 .py files outside tests/. Two exclusions are
    # LOAD-BEARING (not defensive), both because the pack ships its own
    # `.py` into every installed project and those must never count as
    # client data-architecture evidence:
    #   - `pack-capability-pool/` — the BD-200 tracked pool ships
    #     `server/**/*.py` masters on every installed project.
    #   - `scripts/` — the pack ships PM tooling (`pm-*.py`) into the
    #     client `scripts/` dir. Anchored to `"$target/scripts/*"` (the
    #     pack populates only the top-level `scripts/`, never a nested
    #     client `scripts/`), mirroring the anchored `scripts/` exclusion
    #     in init-project.sh `detect_language_markers`.
    # Without these, the pack's own `.py` copies could inflate the count
    # past the threshold and mis-fire `python-data: yes` on a project
    # with too few OWN `.py` files.
    local py_files py_count
    py_files=$(find "$target" -name "*.py" \
        -not -path "$target/scripts/*" \
        -not -path "*/tests/*" \
        -not -path "*/pack-capability-pool/*" \
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
# Concrete load predicate for the `protobuf-patterns` skill. Mirrors the
# `python_data_marker_detected()` shape: single positional argument
# defaulting to cwd; tolerates missing target as a `no`; emits a single
# `protobuf-marker: yes|no` line on stdout.
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
# Manifest scan reuses the negated-character-class pattern construction
# from python_data_marker_detected() (rejects substring matches and
# version-suffix matches like `protobuf-c` via `protobuf`).
#
# Callers: scripts/init-project.sh `pack_skill_coverage_for proto` row
# (wires alongside the existing `grpc-patterns` coverage);
# scripts/add-capability.sh references the predicate by comment only
# (the protocol:grpc skill set declaratively adds grpc-patterns; the
# protobuf-marker → protobuf-patterns load is intersection-table-driven
# and applies regardless of capability declaration). This helper is the
# canonical predicate for the protobuf-patterns intersection row.
protobuf_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "protobuf-marker: no"
        return 0
    fi

    # Marker (a): any `.proto` file in the project tree, excluding
    # large vendored / generated trees. The `pack-capability-pool/`
    # prune is LOAD-BEARING (not defensive): the BD-200 tracked pool
    # ships `pack-capability-pool/proto/*.proto` masters on EVERY
    # installed project, so without this exclusion a Swift-only client
    # would mis-fire `protobuf-marker: yes` off its own pool.
    if find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \
           -o -path '*/pack-capability-pool/*' \) -prune \
        -o -type f -name '*.proto' -print 2>/dev/null \
        | head -n 1 | grep -q .; then
        echo "protobuf-marker: yes"
        return 0
    fi

    # Marker (b): dependency manifests. Same negated-character-class
    # boundary construction as python_data_marker_detected()
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
# Concrete load predicate for the `apple-swiftdata-patterns` skill.
# Mirrors the `protobuf_marker_detected()` shape: single positional
# argument defaulting to cwd; tolerates missing target as a `no`;
# emits a single `swiftdata-marker: yes|no` line on stdout.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `swiftdata-marker: no` (no error to stderr).
#
# Output:
#   Single line `swiftdata-marker: yes` or `swiftdata-marker: no`.
#
# Markers (any one true → yes):
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
# (wires alongside the existing apple-architecture-core /
# swift-best-practices coverage); scripts/add-capability.sh references
# the predicate by comment only (the platform:ios / platform:macos
# capability rows declare apple-architecture-core deterministically;
# the swiftdata-marker → apple-swiftdata-patterns load is intersection-
# table-driven and applies regardless of capability declaration). This
# helper is the canonical predicate for the apple-swiftdata-patterns
# intersection row.
swiftdata_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "swiftdata-marker: no"
        return 0
    fi

    # Markers (a) and (b): scan `.swift` files, excluding common
    # vendored / generated / build trees. Combine into a single find
    # → grep pipeline so we only enumerate the file list once. The
    # `pack-capability-pool/` prune is LOAD-BEARING (not defensive):
    # the BD-200 tracked pool ships `*-swift.sh` masters and may carry
    # `.swift` masters on every installed project, so without this
    # exclusion the pool's own copies could mis-fire detection.
    local swift_hits
    swift_hits=$(find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \
           -o -path '*/.build' -o -path '*/DerivedData' \
           -o -path '*/Pods' -o -path '*/Carthage' \
           -o -path '*/pack-capability-pool/*' \) -prune \
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
    # construction as protobuf_marker_detected() — rejects substring
    # matches like `SwiftDataMocks` or `SwiftDataKit` via `SwiftData`.
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
# Concrete load predicate for the `python-observability-patterns` skill.
# Mirrors the `python_data_marker_detected()`,
# `protobuf_marker_detected()`, and `swiftdata_marker_detected()`
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
#       The exact-name list uses the negated-character-class
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
#       .git/, build/, .venv/, venv/, .tox/, per the standard prune
#       list) contains a line matching
#       `^[[:space:]]*(import|from)[[:space:]]+(opentelemetry|prometheus_client|structlog)([[:space:]]|\.|,|$)`.
#       Line-anchored to defeat prose mentions in comments /
#       docstrings (per the marker-c line-anchoring convention).
#       Matches `import opentelemetry`, `from opentelemetry import …`,
#       `from opentelemetry.foo import …` (via the `\.`
#       alternative), `import prometheus_client`,
#       `from prometheus_client import …`, `import structlog`,
#       `from structlog import …`.
#
# Callers: scripts/init-project.sh `pack_skill_coverage_for python` row
# (wires alongside the existing python-best-practices /
# python-data-architecture coverage); scripts/add-capability.sh
# references the predicate by comment only (the language:python
# capability set declaratively adds python-observability-patterns;
# the role:python-server capability adds it as well — the marker-
# gated intersection-table load applies regardless of capability
# declaration). This helper is the canonical predicate for the
# python-observability-patterns intersection row.
python_observability_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "python-observability-marker: no"
        return 0
    fi

    # Marker (a): dependency manifests. Two patterns combined —
    # exact-name packages via the negated-character-class boundary,
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
    # mentions in comments / docstrings (per the marker-c
    # line-anchoring convention). Module-name boundary uses the
    # `([[:space:]]|\.|,|$)` trailing alternative to admit
    # `import opentelemetry`, `from opentelemetry.trace import ...`,
    # and `from opentelemetry import trace, metrics`. The
    # `pack-capability-pool/` prune is LOAD-BEARING (not defensive):
    # the BD-200 tracked pool ships `server/**/*.py` masters on every
    # installed project, so without this exclusion the pool's own `.py`
    # copies could mis-fire detection.
    local py_files
    py_files=$(find "$target" \
        \( -path '*/node_modules' -o -path '*/.git' \
           -o -path '*/build' -o -path '*/.venv' \
           -o -path '*/venv' -o -path '*/.tox' \
           -o -path '*/pack-capability-pool/*' \) -prune \
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
# pack repo). Used by the migrator framework to decide which adapter
# applies, and by external harnesses to dispatch correctly.
#
# Signal cascade (cheapest first; first positive match wins):
#   1. tracker.toml `[pack]\nversion = "vN"` field, when present (opt-in:
#      absence is NOT a v10 signal — the cascade continues).
#   2. Trinity addenda fingerprint — v11 trinity files contain the line
#      `run \`/pm-help\` for the full verb list` (client help renamed from
#      `/pack-help` per BD-257).
#   3. Surface markers — v11-only files: pm-help SKILL.md per CLI (renamed
#      from pack-help per BD-257), ISSUE_TEMPLATE/work-item.yml,
#      docs/pack/HELP-FRAGMENT.md.
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
            if grep -q 'run `/pm-help` for the full verb list' \
               "$target/$trinity" 2>/dev/null; then
                echo "v11"
                return 0
            fi
        fi
    done

    # Signal 3: v11-only surface markers. The per-CLI help skill is the
    # loose `pm-help` SKILL.md across the three CLI homes (claude/codex/agents
    # — Antigravity reads `.agents/skills/`), renamed from `pack-help` per
    # BD-257.
    if [[ -f "$target/.claude/skills/pm-help/SKILL.md" \
       || -f "$target/.codex/skills/pm-help/SKILL.md" \
       || -f "$target/.agents/skills/pm-help/SKILL.md" \
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
