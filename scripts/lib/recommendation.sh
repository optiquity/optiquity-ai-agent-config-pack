# scripts/lib/recommendation.sh — D-19 inflection-point recommendation system.
# (BD-072 — V3 §28.1)
#
# Watches three pack-side or six client-side signals at session
# start; tests them against thresholds; if a signal has crossed (and
# none of the refusal guards apply) emits a recommendation prompt.
#
# Invoked from `pack-startup` Step 8 / `pm-startup` Step 8 (BD-074).
#
# Public API:
#   - recommendation_compute_signals <surface> <repo-root>
#       Emits JSON of signal values for the surface ("pack" or "client").
#   - recommendation_state_load <state-path>
#       Emits the state JSON (default state when file is missing or
#       corrupted; corrupted-file rebuild logged to stderr).
#   - recommendation_state_save <state-path> <json>
#       Atomic write (mktemp + rename).
#   - recommendation_should_recommend <signals-json> <state-json> <surface> <tracker-mode>
#       Emits "true" or "false" to stdout per V3 §28.1.5 pseudocode.
#       <tracker-mode> is "tracker" or "flat-file"; when "tracker",
#       always emits "false" (Guard 1).
#   - recommendation_render_prompt <signals-json> <surface>
#       Emits the V3 §28.1.7 prompt text to stdout. Picks the most
#       extreme crossed signal as the headline.
#   - recommendation_record_shown <state-path> <signals-json>
#       Updates `last_recommendation_shown_at` + `last_recommendation_signals`
#       in the state file.
#   - recommendation_set_persistent_refusal <state-path> <true|false>
#       Flips `persistent_refusal`; sets `persistent_refusal_at` when
#       true; increments `user_re_enable_count` when false.
#
# Reference:
#   - ARCHITECTURE-V3.md §28.1.1 (signals), §28.1.2 (thresholds),
#     §28.1.4 (state file schema), §28.1.5 (should-recommend test),
#     §28.1.6 (state machine), §28.1.7 (prompt shape).
#
# Bash 3.2 compatible (macOS default). Do NOT add a shebang — sourced.

# Source the typed-error formatter so corrupted-state recovery uses
# the canonical surface (V3 §27.1 Layer 2). Idempotent.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _rec_self="${BASH_SOURCE[0]}"
    _rec_dir="$(cd "$(dirname "$_rec_self")" && pwd)"
    [[ -f "$_rec_dir/tracker-errors.sh" ]] && source "$_rec_dir/tracker-errors.sh"
    unset _rec_self _rec_dir
fi

# ─────────────────────────────────────────────────────────────────
# Thresholds (V3 §28.1.2)
# ─────────────────────────────────────────────────────────────────

# Per-surface threshold table. Embedded in a here-doc lookup so
# tests can override individual thresholds via REC_THRESHOLD_<SURFACE>_<NAME>
# env vars without re-sourcing the lib.
_rec_threshold() {
    local surface="$1"
    local name="$2"
    local override_var="REC_THRESHOLD_${surface}_${name}"
    override_var="${override_var//-/_}"
    if [[ -n "${!override_var:-}" ]]; then
        echo "${!override_var}"
        return 0
    fi
    case "$surface:$name" in
        pack:bd_count_active)        echo 80 ;;
        pack:backlog_kb)             echo 18 ;;
        pack:backlog_growth_30d)     echo 10 ;;
        client:td_count_active)      echo 120 ;;
        client:backlog_kb)           echo 45 ;;
        client:phase_count)          echo 40 ;;
        client:implementation_plan_kb) echo 100 ;;
        client:td_tbd_comment_count) echo 60 ;;
        client:typed_deferral_count) echo 150 ;;
        *)                           echo "" ;;
    esac
}

# Signal names per surface (used by should_recommend to iterate).
_rec_signal_names() {
    local surface="$1"
    case "$surface" in
        pack)
            echo "bd_count_active"
            echo "backlog_kb"
            echo "backlog_growth_30d"
            ;;
        client)
            echo "td_count_active"
            echo "backlog_kb"
            echo "phase_count"
            echo "implementation_plan_kb"
            echo "td_tbd_comment_count"
            echo "typed_deferral_count"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Signal computation (V3 §28.1.1)
# ─────────────────────────────────────────────────────────────────

# recommendation_compute_signals <surface> <repo-root>
# Emits JSON object with the surface's signal values on stdout.
recommendation_compute_signals() {
    local surface="$1"
    local repo_root="$2"
    if [[ -z "$surface" || -z "$repo_root" ]]; then
        tracker_error_emit "validation" \
            "compute_signals: surface and repo-root required"
        return 1
    fi
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" \
            "compute_signals: repo-root not a directory: $repo_root"
        return 1
    fi
    case "$surface" in
        pack)   _rec_compute_pack_signals "$repo_root" ;;
        client) _rec_compute_client_signals "$repo_root" ;;
        *)
            tracker_error_emit "validation" \
                "compute_signals: surface must be pack|client; got '$surface'"
            return 1
            ;;
    esac
}

_rec_compute_pack_signals() {
    local repo_root="$1"
    # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.
    local backlog="$repo_root/pack-ops/BACKLOG.md"
    local bd_active=0 bd_total=0 backlog_kb=0 growth=0
    if [[ -f "$backlog" ]]; then
        bd_total=$(grep -cE '^\*\*BD-[0-9]+ ' "$backlog" 2>/dev/null || echo 0)
        bd_active=$(_rec_count_active_entries "$backlog" "BD")
        local bytes
        bytes=$(wc -c < "$backlog" | tr -d ' ')
        backlog_kb=$(( bytes / 1024 ))
    fi
    growth=$(_rec_backlog_growth_30d "$repo_root" "$backlog")
    printf '{"bd_count_active":%d,"bd_count_total":%d,"backlog_kb":%d,"backlog_growth_30d":%d}\n' \
        "$bd_active" "$bd_total" "$backlog_kb" "$growth"
}

_rec_compute_client_signals() {
    local repo_root="$1"
    # Per the project-template trinity `## Document locations` table,
    # client BACKLOG / STATUS / IMPLEMENTATION-PLAN live under
    # `docs/project/`. Fall back to the trinity-mandated path when the
    # repo-root copy is absent (legacy v9 layout fallback).
    local backlog="$repo_root/BACKLOG.md"
    [[ ! -f "$backlog" ]] && backlog="$repo_root/docs/project/BACKLOG.md"
    local plan="$repo_root/IMPLEMENTATION-PLAN.md"
    [[ ! -f "$plan" ]] && plan="$repo_root/docs/project/IMPLEMENTATION-PLAN.md"

    local td_active=0 td_total=0 backlog_kb=0 phase_count=0 plan_kb=0
    local td_tbd_count=0 deferral_count=0
    if [[ -f "$backlog" ]]; then
        td_total=$(grep -cE '^\*\*TD-[0-9]+ ' "$backlog" 2>/dev/null || echo 0)
        td_active=$(_rec_count_active_entries "$backlog" "TD")
        local bytes
        bytes=$(wc -c < "$backlog" | tr -d ' ')
        backlog_kb=$(( bytes / 1024 ))
    fi
    if [[ -f "$plan" ]]; then
        phase_count=$(grep -cE '^## Phase' "$plan" 2>/dev/null || echo 0)
        local pbytes
        pbytes=$(wc -c < "$plan" | tr -d ' ')
        plan_kb=$(( pbytes / 1024 ))
    fi
    td_tbd_count=$(_rec_grep_count_in_sources "$repo_root" 'TD-TBD')
    deferral_count=$(_rec_grep_count_in_sources "$repo_root" 'KNOWN GAP\|TODO\|FIXME')
    printf '{"td_count_active":%d,"td_count_total":%d,"backlog_kb":%d,"phase_count":%d,"implementation_plan_kb":%d,"td_tbd_comment_count":%d,"typed_deferral_count":%d}\n' \
        "$td_active" "$td_total" "$backlog_kb" "$phase_count" "$plan_kb" "$td_tbd_count" "$deferral_count"
}

# Count entries with Status: Open or Status: Unblocked under a given prefix.
_rec_count_active_entries() {
    local backlog="$1"
    local prefix="$2"
    python3 - "$backlog" "$prefix" <<'PYEOF'
import re, sys
path, prefix = sys.argv[1], sys.argv[2]
with open(path) as f:
    text = f.read()
header = re.compile(r'^\*\*' + re.escape(prefix) + r'-\d+\s', re.M)
status = re.compile(r'^Status:\s*(\S+)', re.M)
sep = re.compile(r'^---\s*$|^\*\*' + re.escape(prefix) + r'-\d+\s', re.M)
count = 0
for m in header.finditer(text):
    block = text[m.start(): m.start() + 2000]
    sm = status.search(block)
    if sm and sm.group(1) in ("Open", "Unblocked"):
        count += 1
print(count)
PYEOF
}

# Approximate 30-day BACKLOG.md growth via git log commit count (each
# commit assumed ~average growth). Falls back to 0 outside a git repo.
_rec_backlog_growth_30d() {
    local repo_root="$1"
    local backlog="$2"
    if ! command -v git >/dev/null 2>&1; then
        echo 0
        return 0
    fi
    if [[ ! -d "$repo_root/.git" ]]; then
        echo 0
        return 0
    fi
    local commits
    commits=$(git -C "$repo_root" log --since="30 days ago" --pretty=format:'%h' -- "$backlog" 2>/dev/null | wc -l | tr -d ' ')
    # Each commit ≈ one entry added. Simple proxy.
    echo "${commits:-0}"
}

# Count occurrences of a regex in source files (excluding pack-controlled
# / generated dirs). Bash 3.2 compatible — avoids process substitution
# in array context; uses pipeline through wc -l.
_rec_grep_count_in_sources() {
    local repo_root="$1"
    local pattern="$2"
    if ! command -v grep >/dev/null 2>&1; then
        echo 0
        return 0
    fi
    grep -rE --include='*.swift' --include='*.py' --include='*.ts' \
        --include='*.tsx' --include='*.js' --include='*.go' \
        --include='*.rs' --include='*.c' --include='*.h' \
        --include='*.cpp' --include='*.m' --include='*.mm' \
        --exclude-dir='.git' --exclude-dir='.build' \
        --exclude-dir='node_modules' --exclude-dir='__pycache__' \
        --exclude-dir='generated' --exclude-dir='.venv' \
        "$pattern" "$repo_root" 2>/dev/null | wc -l | tr -d ' '
}

# ─────────────────────────────────────────────────────────────────
# State file I/O (V3 §28.1.4)
# ─────────────────────────────────────────────────────────────────

# recommendation_state_default <surface>
# Emits the default state JSON.
recommendation_state_default() {
    local surface="${1:-pack}"
    jq -n --arg s "$surface" \
        '{schema_version:"v1",surface:$s,persistent_refusal:false,persistent_refusal_at:null,last_recommendation_shown_at:null,last_recommendation_signals:{},user_re_enable_count:0}'
}

# recommendation_state_load <state-path> [<surface>]
# Emits the state JSON. When the file is absent or corrupted, emits
# the default state (and rebuilds the file on corruption — V3 §28.1.4
# failure-mode contract).
recommendation_state_load() {
    local path="$1"
    local surface="${2:-pack}"
    if [[ -z "$path" ]]; then
        tracker_error_emit "validation" "state_load: path required"
        return 1
    fi
    if [[ ! -f "$path" ]]; then
        recommendation_state_default "$surface"
        return 0
    fi
    local raw
    raw=$(cat "$path" 2>/dev/null)
    # Validate JSON. On parse failure, write fresh default + warn (V3 §28.1.4).
    if ! printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
        echo "recommendation: state file at $path is corrupted; rebuilding with default" >&2
        local fresh
        fresh=$(recommendation_state_default "$surface")
        recommendation_state_save "$path" "$fresh"
        # Per V3 §28.1.4: stamp last_recommendation_shown_at to defer this
        # session's recommendation (avoid firing in the same session as
        # the rebuild — disorienting after a corruption warning).
        local stamped
        stamped=$(printf '%s' "$fresh" | jq --arg t "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
            '.last_recommendation_shown_at = $t')
        recommendation_state_save "$path" "$stamped"
        printf '%s\n' "$stamped"
        return 0
    fi
    printf '%s\n' "$raw"
}

# recommendation_state_save <state-path> <json>
recommendation_state_save() {
    local path="$1"
    local data="$2"
    if [[ -z "$path" || -z "$data" ]]; then
        tracker_error_emit "validation" "state_save: path and data required"
        return 1
    fi
    local dir tmp
    dir=$(dirname "$path")
    mkdir -p "$dir"
    tmp=$(mktemp -t rec-state.XXXXXX)
    printf '%s\n' "$data" > "$tmp"
    mv "$tmp" "$path"
}

# ─────────────────────────────────────────────────────────────────
# Should-recommend test (V3 §28.1.5)
# ─────────────────────────────────────────────────────────────────

# recommendation_should_recommend <signals-json> <state-json> <surface> <mode>
# Emits "true" / "false" on stdout. <mode> is "tracker" or "flat-file".
recommendation_should_recommend() {
    local signals="$1"
    local state="$2"
    local surface="$3"
    local mode="$4"

    # Guard 1: tracker mode disables recommendations.
    if [[ "$mode" == "tracker" ]]; then
        echo "false"
        return 0
    fi

    # Guard 2: persistent refusal.
    local refusal
    refusal=$(printf '%s' "$state" | jq -r '.persistent_refusal // false')
    if [[ "$refusal" == "true" ]]; then
        echo "false"
        return 0
    fi

    # Guard 3: any signal threshold crossed?
    local crossed=""
    local name now thr
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        thr=$(_rec_threshold "$surface" "$name")
        [[ -z "$thr" ]] && continue
        now=$(printf '%s' "$signals" | jq -r --arg k "$name" '.[$k] // 0')
        if [[ "$now" -ge "$thr" ]] 2>/dev/null; then
            crossed="$crossed $name"
        fi
    done < <(_rec_signal_names "$surface")
    crossed=$(echo "$crossed" | sed 's/^ //')
    if [[ -z "$crossed" ]]; then
        echo "false"
        return 0
    fi

    # Guard 4: material change since last recommendation?
    local last_shown
    last_shown=$(printf '%s' "$state" | jq -r '.last_recommendation_shown_at // ""')
    if [[ -z "$last_shown" || "$last_shown" == "null" ]]; then
        # First time over threshold; fire (Guard 5).
        echo "true"
        return 0
    fi
    # For each crossed signal, check whether it has grown ≥ 25% over
    # last snapshot. If any crossed signal is materially higher, fire.
    local last_v
    for name in $crossed; do
        thr=$(_rec_threshold "$surface" "$name")
        now=$(printf '%s' "$signals" | jq -r --arg k "$name" '.[$k] // 0')
        last_v=$(printf '%s' "$state" | jq -r --arg k "$name" '.last_recommendation_signals[$k] // 0')
        # If the prior snapshot was below threshold, this crossing is
        # the first material event — fire.
        if [[ "$last_v" -lt "$thr" ]] 2>/dev/null; then
            echo "true"
            return 0
        fi
        # Both prior and current are over threshold (last_v >= thr > 0
        # at this point — the "$last_v -lt $thr" branch above already
        # returned for the under-threshold case). Require ≥ 25% growth.
        # Bash arithmetic only; (now * 100) / last >= 125.
        if (( (now * 100) >= (last_v * 125) )); then
            echo "true"
            return 0
        fi
    done
    echo "false"
}

# ─────────────────────────────────────────────────────────────────
# Prompt rendering (V3 §28.1.7)
# ─────────────────────────────────────────────────────────────────

# _rec_signal_label <signal-key>
# Maps a signal JSON key to the human label V3 §28.1.7 + §D.2 prescribe
# for the rendered prompt. The lib emits the human label so the prompt
# reads as the worked-example shows; the raw key only appears in JSON.
_rec_signal_label() {
    case "$1" in
        bd_count_active)        echo "BACKLOG entries (active)" ;;
        bd_count_total)         echo "BACKLOG entries (total)" ;;
        td_count_active)        echo "TD entries (active)" ;;
        td_count_total)         echo "TD entries (total)" ;;
        backlog_kb)             echo "BACKLOG.md size (KB)" ;;
        backlog_growth_30d)     echo "BACKLOG growth (30 days)" ;;
        phase_count)            echo "phase count" ;;
        implementation_plan_kb) echo "IMPLEMENTATION-PLAN.md size (KB)" ;;
        td_tbd_comment_count)   echo "TD-TBD comments" ;;
        typed_deferral_count)   echo "typed deferral comments" ;;
        *)                      echo "$1" ;;
    esac
}

# recommendation_render_prompt <signals-json> <surface>
# Emits the V3 §28.1.7 prompt block on stdout. Selects the most
# quantitatively-extreme crossed signal (max value/threshold) as the
# headline; mentions other crossed signals on a follow-up line.
recommendation_render_prompt() {
    local signals="$1"
    local surface="$2"

    local headline_name="" headline_value=0 headline_thr=0
    local headline_ratio_num=0 headline_ratio_den=1
    local also=""

    local name now thr ratio_num ratio_den label
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        thr=$(_rec_threshold "$surface" "$name")
        [[ -z "$thr" ]] && continue
        now=$(printf '%s' "$signals" | jq -r --arg k "$name" '.[$k] // 0')
        if [[ "$now" -ge "$thr" ]] 2>/dev/null; then
            # Compare ratios as cross-products to avoid floating point.
            ratio_num="$now"
            ratio_den="$thr"
            if [[ -z "$headline_name" ]] || \
               (( ratio_num * headline_ratio_den > headline_ratio_num * ratio_den )); then
                if [[ -n "$headline_name" ]]; then
                    label=$(_rec_signal_label "$headline_name")
                    if [[ -n "$also" ]]; then also="$also; "; fi
                    also="${also}${label}: $headline_value (threshold ≥ $headline_thr)"
                fi
                headline_name="$name"
                headline_value="$now"
                headline_thr="$thr"
                headline_ratio_num="$ratio_num"
                headline_ratio_den="$ratio_den"
            else
                label=$(_rec_signal_label "$name")
                if [[ -n "$also" ]]; then also="$also; "; fi
                also="${also}${label}: $now (threshold ≥ $thr)"
            fi
        fi
    done < <(_rec_signal_names "$surface")

    if [[ -z "$headline_name" ]]; then
        # No crossed signals; caller shouldn't have invoked us.
        return 0
    fi

    local headline_label
    headline_label=$(_rec_signal_label "$headline_name")
    cat <<EOF
─────────────────────────────────────────────────────────────────
You're at $headline_label: $headline_value (threshold ≥ $headline_thr).
EOF
    if [[ -n "$also" ]]; then
        printf 'Also past threshold: %s.\n' "$also"
    fi
    cat <<'EOF'

At this scale, GH Issues lets you filter and search faster than
reading BACKLOG.md in full. The migration is one command, and it's
fully reversible — you can switch back to flat files any time
with `pack tracker disable`.

Want to enable the tracker now?

  yes              → run `pack tracker init` (3-5 minutes; reversible)
  not now          → don't ask me again *this* session
  don't ask again  → don't recommend the tracker until I re-enable

Or run `pack help` to see all pack commands.
─────────────────────────────────────────────────────────────────
EOF
}

# ─────────────────────────────────────────────────────────────────
# State mutators
# ─────────────────────────────────────────────────────────────────

# recommendation_record_shown <state-path> <signals-json>
# Updates last_recommendation_shown_at + last_recommendation_signals.
recommendation_record_shown() {
    local path="$1"
    local signals="$2"
    if [[ -z "$path" || -z "$signals" ]]; then
        tracker_error_emit "validation" "record_shown: path and signals required"
        return 1
    fi
    local now state surface updated
    now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    state=$(recommendation_state_load "$path")
    surface=$(printf '%s' "$state" | jq -r '.surface // "pack"')
    updated=$(printf '%s' "$state" | jq \
        --arg t "$now" --argjson s "$signals" \
        '.last_recommendation_shown_at = $t | .last_recommendation_signals = $s')
    recommendation_state_save "$path" "$updated"
}

# recommendation_set_persistent_refusal <state-path> <true|false>
# When true, sets persistent_refusal=true + persistent_refusal_at=now.
# When false, sets persistent_refusal=false + increments user_re_enable_count.
recommendation_set_persistent_refusal() {
    local path="$1"
    local value="$2"
    if [[ -z "$path" || -z "$value" ]]; then
        tracker_error_emit "validation" \
            "set_persistent_refusal: path and value (true|false) required"
        return 1
    fi
    if [[ "$value" != "true" && "$value" != "false" ]]; then
        tracker_error_emit "validation" \
            "set_persistent_refusal: value must be 'true' or 'false'; got '$value'"
        return 1
    fi
    local state updated now
    state=$(recommendation_state_load "$path")
    if [[ "$value" == "true" ]]; then
        now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
        updated=$(printf '%s' "$state" | jq --arg t "$now" \
            '.persistent_refusal = true | .persistent_refusal_at = $t')
    else
        updated=$(printf '%s' "$state" | jq \
            '.persistent_refusal = false | .user_re_enable_count = ((.user_re_enable_count // 0) + 1)')
    fi
    recommendation_state_save "$path" "$updated"
}
