# scripts/lib/migrate-v10-to-v11/checkpoint.sh — BD-101 shared verification
# helpers consumed by gate-1, gate-2, gate-3 of the v10 → v11 migrator.
#
# Sourced by `gate-1-dry-run-summary.sh`, `gate-2-phase-a-verify.sh`,
# `gate-3-phase-b-verify.sh`. Adapters never source this directly.
#
# Design rationale:
#   - Each helper is *pure* in the sense that it does not call `exit`.
#     Helpers print a single `[OK]` / `[FAIL]` / `[INFO]` line per
#     check and return 0 (pass) / 1 (fail). The orchestrating gate is
#     responsible for mapping a non-zero return to the framework's
#     EXIT_GATE_FAILED.
#   - Read-only on the project tree. Gate 2/3 may run after the migrator
#     has mutated the tree, but the helpers themselves do not write.
#   - macOS bash 3.2 + BSD utils compatible (no associative arrays, no
#     GNU-only `find` flags, no `sed -i` portability traps).
#
# Public helper API (all return 0 on PASS, 1 on FAIL, with one-line stdout):
#
#   checkpoint_check_dispositions_consistency <state-dir>
#       Verify dispositions.tsv exists, is non-empty, and contains no
#       `unknown-classification` rows. Used by Gate 1 (dry-run summary)
#       and Gate 2 (post-Phase-A re-verify).
#
#   checkpoint_check_trinity_addenda <target>
#       Verify trinity files (CLAUDE/AGENTS/GEMINI) all carry the v11
#       addenda H2 sections that Phase-A is supposed to install.
#
#   checkpoint_check_help_fragments <target> <pack>
#       Verify HELP-FRAGMENT.md was installed at <target>/docs/pack/ AND
#       that its contents match the pack-side mirror at
#       <pack>/project-template/docs/pack/.
#
#   checkpoint_check_relocated_docs <target>
#       Verify BD-042 / BD-091 legacy docs are no longer at the project
#       root (or, if both root + docs/pack/ existed, the root copy was
#       sidecared as `<f>.relocated-from-root`).
#
#   checkpoint_check_validate_pack <pack>
#       Run `python3 scripts/validate-pack.py` against the pack repo
#       and require a clean pass.
#
#   checkpoint_check_no_orphan_sidecars <target>
#       Verify the target tree contains zero `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}`
#       files. The expected post-Phase-A end-state is "all conflicts
#       reconciled and sidecars removed". The `--resume` precondition
#       check catches sidecars listed in `stage-S3.paused`; this
#       check catches stragglers that escaped that list (e.g. a sidecar
#       resolved by editing the destination but never deleted).
#
#   checkpoint_check_mapping_integrity <target>
#       Verify .pack-tracker/id-map.json is parseable JSON and each
#       entry's value is a positive integer (issue number).
#
#   checkpoint_check_mirror_freshness <target>
#       Verify BACKLOG.md mirror mtime ≥ tracker.toml
#       [migration].last_forward_run.
#
#   checkpoint_check_tracker_doctor <target>
#       Invoke `pack tracker doctor` (via scripts/pack-tracker.sh) and
#       require exit 0.
#
# Helper-emission convention:
#   - PASS line:    `  [OK]   <short message>`
#   - FAIL line:    `  [FAIL] <short message>  → Run: <recovery verb>`
#   - INFO line:    `  [INFO] <short message>`  (for skip / N/A states)
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── checkpoint_check_dispositions_consistency ────────────────────────────

checkpoint_check_dispositions_consistency() {
    local state_dir="${1:-}"
    local tsv="$state_dir/dispositions.tsv"
    if [[ -z "$state_dir" || ! -d "$state_dir" ]]; then
        printf '  [FAIL] dispositions: state dir missing (%s)\n' "$state_dir"
        return 1
    fi
    # MINOR-2 (BD-101 retro fix): in --resume mode the dispositions.tsv
    # has been truncated and re-initialized by `customization_preserve_init`
    # in resume.sh, so any pre-resume rows are gone by the time Gate 2
    # runs. Re-verifying "consistency" against a header-only TSV would be
    # no-op-equivalent and could falsely stamp PASS. Skip the check
    # explicitly with an INFO line so the user understands the gate's
    # contract on this code path.
    if [[ "${_MIGRATOR_MODE:-}" == "resume" ]]; then
        printf '  [INFO] dispositions: skipped (resume mode — pre-resume rows were truncated by resume.sh; the original --apply Gate 2 already validated them)\n'
        return 0
    fi
    if [[ ! -f "$tsv" ]]; then
        printf '  [FAIL] dispositions: dispositions.tsv not found at %s  → Run: re-run --dry-run\n' "$tsv"
        return 1
    fi
    if [[ ! -s "$tsv" ]]; then
        printf '  [FAIL] dispositions: dispositions.tsv is empty (no rows recorded)\n'
        return 1
    fi
    # `unknown-classification` is the catch-all — its presence means the
    # dispatch engine could not categorize a file. That is a defect, not
    # a clean migration plan.
    local n_unknown
    n_unknown=$(awk -F'\t' '$1 == "unknown-classification"' "$tsv" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$n_unknown" != "0" ]]; then
        printf '  [FAIL] dispositions: %s row(s) with unknown-classification  → Run: inspect %s\n' \
            "$n_unknown" "$tsv"
        return 1
    fi
    # MINOR-1 (BD-101 retro fix): `wc -l` over-counts by 1 because the
    # first line is the `# disposition\tclass\t...` header written by
    # `customization_preserve_init`. Count only data rows (any line whose
    # first column does NOT begin with `#`) so a fresh-init TSV with zero
    # data rows reports "0 row(s)" instead of "1 row(s)".
    local n_rows
    n_rows=$(awk -F'\t' '$1 !~ /^#/ {n++} END {print n+0}' "$tsv" 2>/dev/null)
    printf '  [OK]   dispositions: %s row(s), no unknown-classification\n' "$n_rows"
    return 0
}

# ── checkpoint_check_trinity_addenda ─────────────────────────────────────
#
# v11 trinity files carry an addenda block (the `## Addenda` H2 inserted
# by the BD-088 dispatch). Phase-A success means each of CLAUDE.md,
# AGENTS.md, GEMINI.md exists at the project root and contains the v11
# addenda marker. The exact addenda token is stable across v11.x — match
# either of the two known marker strings (validate-pack.py Check 27
# enforces the canonical-phrase shape).

checkpoint_check_trinity_addenda() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] trinity: target dir missing (%s)\n' "$target"
        return 1
    fi
    local missing=0 f
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        if [[ ! -f "$target/$f" ]]; then
            printf '  [FAIL] trinity: %s missing at target root\n' "$f"
            missing=$((missing + 1))
            continue
        fi
        # Trinity addenda H2 marker — `## Project memory` and / or
        # `## Project addenda` are the v11 canonical addenda H2s
        # (validate-pack.py Check 16/17 enforce the shape pack-side).
        # Either presence is evidence the file is at v11 shape and not
        # left at v10 baseline.
        if ! grep -q -E '^## (Project memory|Project addenda)' "$target/$f" 2>/dev/null; then
            printf '  [FAIL] trinity: %s lacks v11 H2 marker (## Project memory / ## Project addenda)\n' "$f"
            missing=$((missing + 1))
        fi
    done
    if (( missing > 0 )); then
        printf '  [FAIL] trinity: %s file(s) failed addenda check  → Run: inspect trinity at %s\n' \
            "$missing" "$target"
        return 1
    fi
    printf '  [OK]   trinity: CLAUDE / AGENTS / GEMINI all present with addenda markers\n'
    return 0
}

# ── checkpoint_check_help_fragments ──────────────────────────────────────
#
# v11 ships HELP-FRAGMENT.md under docs/pack/. Phase-A's S5 artifact-
# install copies it to the target; this check verifies it exists AND
# matches the pack-side mirror byte-for-byte (the install is a plain
# `cp` so identity is the expected relation).

checkpoint_check_help_fragments() {
    local target="${1:-}" pack="${2:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] help-fragments: target dir missing\n'
        return 1
    fi
    if [[ -z "$pack" || ! -d "$pack" ]]; then
        printf '  [FAIL] help-fragments: pack dir missing (PACK env unset?)\n'
        return 1
    fi
    local missing=0 mismatch=0 f
    for f in HELP-FRAGMENT.md; do
        local proj="$target/docs/pack/$f"
        local src="$pack/project-template/docs/pack/$f"
        if [[ ! -f "$proj" ]]; then
            printf '  [FAIL] help-fragments: %s missing at target docs/pack/\n' "$f"
            missing=$((missing + 1))
            continue
        fi
        if [[ ! -f "$src" ]]; then
            # No pack-side mirror → can only check presence, not byte
            # equality. Treat as INFO not FAIL because the absence is a
            # pack-side issue, not a migration-side one.
            printf '  [INFO] help-fragments: pack-side %s missing; skipping byte-equality\n' "$f"
            continue
        fi
        if ! cmp -s "$proj" "$src" 2>/dev/null; then
            printf '  [FAIL] help-fragments: %s differs from pack mirror  → Run: cp %s %s\n' \
                "$f" "$src" "$proj"
            mismatch=$((mismatch + 1))
        fi
    done
    if (( missing > 0 || mismatch > 0 )); then
        printf '  [FAIL] help-fragments: %s missing, %s mismatched\n' "$missing" "$mismatch"
        return 1
    fi
    printf '  [OK]   help-fragments: HELP-FRAGMENT(.md|-TRACKER.md) present + match pack mirror\n'
    return 0
}

# ── checkpoint_check_relocated_docs ──────────────────────────────────────
#
# BD-042 relocates METHODOLOGY / PROMPT-TEMPLATES / PM-CHAT /
# PLATFORM-SKILLS / PACK-FEEDBACK from the project root to docs/pack/.
# After Phase-A, none of these should exist at the root unless the
# migrator chose the sidecar branch (`<f>.relocated-from-root`).

checkpoint_check_relocated_docs() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] relocations: target dir missing\n'
        return 1
    fi
    local stragglers=0 f
    for f in METHODOLOGY.md PROMPT-TEMPLATES.md PM-CHAT.md \
             PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
        if [[ -f "$target/$f" ]]; then
            # The sidecar form `<f>.relocated-from-root` is acceptable;
            # the bare root file is a regression.
            printf '  [FAIL] relocations: %s still at project root  → Run: rm or move to docs/pack/\n' "$f"
            stragglers=$((stragglers + 1))
        fi
    done
    if (( stragglers > 0 )); then
        printf '  [FAIL] relocations: %s legacy doc(s) still at root\n' "$stragglers"
        return 1
    fi
    printf '  [OK]   relocations: no legacy v9-era docs left at project root\n'
    return 0
}

# ── checkpoint_check_validate_pack ───────────────────────────────────────
#
# Run validate-pack.py against the pack repo. The migrated *target* is
# a project, not a pack — we cannot run the pack validator against it
# directly. What this checks is that the pack we migrated FROM is a
# clean, valid pack (so its outputs we cp/git-mv into the target are
# trustworthy). A pack that fails validate-pack.py is a PACK defect,
# not a migration defect — surface as FAIL so the user knows the
# migration succeeded but the pack source needs attention.

checkpoint_check_validate_pack() {
    local pack="${1:-}"
    if [[ -z "$pack" || ! -d "$pack" ]]; then
        printf '  [FAIL] validate-pack: PACK env unset or invalid\n'
        return 1
    fi
    local validator="$pack/scripts/validate-pack.py"
    if [[ ! -f "$validator" ]]; then
        printf '  [INFO] validate-pack: %s not found; skipping (pre-v11 pack?)\n' "$validator"
        return 0
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        printf '  [INFO] validate-pack: python3 not on PATH; skipping\n'
        return 0
    fi
    local out rc
    out=$(cd "$pack" && python3 "$validator" 2>&1)
    rc=$?
    if (( rc != 0 )); then
        printf '  [FAIL] validate-pack: validator exited %s  → Run: python3 %s\n' \
            "$rc" "$validator"
        return 1
    fi
    printf '  [OK]   validate-pack: pack repo passes all structural checks\n'
    return 0
}

# ── checkpoint_classify_sidecar ──────────────────────────────────────────
#
# Single source of truth for "is this sidecar resolved?" semantics per
# the BD-095 contract (see resume.sh:38-57 + ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §3). Both Gate 2's orphan-sidecar check (C3) and resume.sh's precondition
# scanner (C2) classify sidecars through this helper so they can never
# diverge on the BD-095 two-signal `.resolved` / removed contract.
#
# Returns one of (echoed to stdout, single token + newline):
#   resolved-flag    — sidecar present AND companion `<sidecar>.resolved` exists
#                      (state (c) in ARCHITECTURE-SIDECAR-LIFECYCLE.md §1)
#   resolved-removed — sidecar absent (user merged + rm'd, OR accepted pack
#                      default + rm'd) — state (d)/(e)
#   unresolved       — sidecar present, no `.resolved` companion — state (b)
#   unknown          — empty / missing arg; returns 1 (caller error)
#
# Pure read-only. Caller decides what counts as orphan / FAIL.
checkpoint_classify_sidecar() {
    local sidecar="${1:-}"
    if [[ -z "$sidecar" ]]; then
        printf 'unknown\n'
        return 1
    fi
    if [[ -f "${sidecar}.resolved" ]]; then
        printf 'resolved-flag\n'
    elif [[ ! -f "$sidecar" ]]; then
        printf 'resolved-removed\n'
    else
        printf 'unresolved\n'
    fi
    return 0
}

# ── checkpoint_check_no_orphan_sidecars ──────────────────────────────────
#
# MINOR-3 (BD-101 retro fix), updated per
# maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §6: Gate 2 should observe zero UNRESOLVED own-suffix sidecar files at
# the project root. The BD-095 contract (resume.sh:38-57) accepts TWO
# resolution signals: (a) companion `<sidecar>.resolved` flag-file, and
# (b) sidecar absence (user merged + `rm`'d). A sidecar in state (c)
# "flagged-resolved" — present on disk WITH a `.resolved` companion —
# is legitimate audit-trail residue and MUST NOT be counted as orphan.
#
# Classification is delegated to `checkpoint_classify_sidecar` so this
# helper and resume.sh's `_v10_v11_resume_classify_sidecars` (C2) share
# one source of truth (option (e) in ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §6.5).
#
# What this catches that other Gate 2 checks don't:
#   - M3-α (cross-execution forgot-to-remove): sidecar present, no
#     `.resolved` companion, no `stage-S3.paused` guard active because
#     a later run wiped state-dir or completed. C2 (resume.sh
#     precondition) only sees paused-list entries; this catches the
#     residual class.
#   - M3-β (unknown-lineage stragglers): sidecar matching this
#     migrator's suffix at any path under target, regardless of whether
#     it appears in stage-S3.paused.
#
# Lifecycle states (§1):
#   (b) created     → sidecar present, no .resolved → UNRESOLVED → FAIL
#   (c) flagged     → sidecar present + .resolved   → RESOLVED   → OK
#   (d)/(e) absent  → sidecar gone                  → RESOLVED   → not seen by find

checkpoint_check_no_orphan_sidecars() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] sidecars: target dir missing (%s)\n' "$target"
        return 1
    fi
    local suffix="${MIGRATOR_OWN_SIDECAR_SUFFIX:-}"
    if [[ -z "$suffix" ]]; then
        # Adapter contract violation — treat as INFO not FAIL so the
        # gate does not block on a framework-loading defect.
        printf '  [INFO] sidecars: MIGRATOR_OWN_SIDECAR_SUFFIX unset; skipping orphan-sidecar check\n'
        return 0
    fi
    # Find candidates under target, excluding migrator state dirs and
    # .git/. The `head -10` cap is applied to the orphans listing below
    # (not to the find output) so we classify every match before listing.
    local candidates
    candidates=$(find "$target" -type f -name "*.${suffix}" \
        -not -path '*/.pack-migrate-*' \
        -not -path '*/.git/*' \
        2>/dev/null)
    if [[ -z "$candidates" ]]; then
        printf '  [OK]   sidecars: no *.%s files at target\n' "$suffix"
        return 0
    fi
    # Per BD-095 §6.H + ARCHITECTURE-SIDECAR-LIFECYCLE.md §3.1: only
    # sidecars classified `unresolved` count as orphan. `resolved-flag`
    # (state (c)) is legitimate audit-trail residue and skipped.
    local s status orphans=()
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        status=$(checkpoint_classify_sidecar "$s")
        if [[ "$status" == "unresolved" ]]; then
            orphans+=("$s")
        fi
    done <<< "$candidates"
    if (( ${#orphans[@]} > 0 )); then
        printf '  [FAIL] sidecars: %d unresolved *.%s file(s) at target  → Run: resolve and rm each listed sidecar (or touch <sidecar>.resolved if accepting pack default)\n' \
            "${#orphans[@]}" "$suffix"
        printf '         %s\n' "${orphans[@]:0:10}"
        return 1
    fi
    printf '  [OK]   sidecars: no unresolved *.%s files at target (resolved-via-flag sidecars present are OK)\n' "$suffix"
    return 0
}

# ── checkpoint_check_mapping_integrity ───────────────────────────────────
#
# Tracker mode: id-map.json must exist, be valid JSON, and every value
# must be a positive integer (the issue number on the backend).

checkpoint_check_mapping_integrity() {
    local target="${1:-}"
    local mapping="$target/.pack-tracker/id-map.json"
    if [[ ! -f "$mapping" ]]; then
        printf '  [FAIL] mapping: %s missing  → Run: tracker-migrate.sh forward\n' "$mapping"
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        printf '  [INFO] mapping: jq not on PATH; skipping content validation\n'
        return 0
    fi
    if ! jq -e 'type == "object"' "$mapping" >/dev/null 2>&1; then
        printf '  [FAIL] mapping: %s is not a JSON object  → Run: tracker-migrate.sh forward\n' "$mapping"
        return 1
    fi
    # Every value must be a positive integer.
    # NIT-2 (BD-101 retro fix): JSON has no integer type — `1.5` is type
    # "number" and > 0, so the bare numeric / positivity check accepts
    # floats. Tracker issue numbers are strict positive integers, so we
    # additionally reject any value where `floor(v) != v`. Defense in
    # depth: the forward migrator writes integers; a float would mean a
    # hand-edit or a future tracker provider regression.
    local bad_values
    bad_values=$(jq -r 'to_entries[] | select((.value | type) != "number" or .value <= 0 or ((.value | floor) != .value)) | .key' \
        "$mapping" 2>/dev/null | head -5)
    if [[ -n "$bad_values" ]]; then
        printf '  [FAIL] mapping: entries with non-positive-integer values  → Run: tracker-migrate.sh forward\n'
        printf '         %s\n' $bad_values
        return 1
    fi
    local n
    n=$(jq 'length' "$mapping" 2>/dev/null || echo 0)
    printf '  [OK]   mapping: %s entries, all values are positive integers\n' "$n"
    return 0
}

# ── checkpoint_check_mirror_freshness ────────────────────────────────────

checkpoint_check_mirror_freshness() {
    local target="${1:-}"
    local backlog="$target/BACKLOG.md"
    local cfg="$target/tracker.toml"
    if [[ ! -f "$backlog" ]]; then
        printf '  [INFO] mirror: BACKLOG.md absent; skipping freshness check\n'
        return 0
    fi
    if [[ ! -f "$cfg" ]]; then
        printf '  [INFO] mirror: tracker.toml absent; skipping freshness check\n'
        return 0
    fi
    # `head -1` cheap — mirror header is the first line `<!--`.
    local first
    first=$(head -n 1 "$backlog" 2>/dev/null)
    if [[ "$first" != "<!--" ]]; then
        printf '  [FAIL] mirror: BACKLOG.md does not begin with mirror header  → Run: pack tracker forward\n'
        return 1
    fi
    # Compare mtime vs last_forward_run if the helper is loadable.
    local mirror_mtime last_forward
    mirror_mtime=$(date -r "$backlog" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
    if declare -F tracker_config_get >/dev/null 2>&1; then
        last_forward=$(tracker_config_get "$cfg" "migration.last_forward_run" 2>/dev/null || echo "")
    fi
    if [[ -n "$mirror_mtime" && -n "$last_forward" ]]; then
        if [[ "$mirror_mtime" < "$last_forward" ]]; then
            printf '  [FAIL] mirror: BACKLOG.md older than last_forward_run (mtime=%s, last=%s)\n' \
                "$mirror_mtime" "$last_forward"
            return 1
        fi
    fi
    printf '  [OK]   mirror: BACKLOG.md present with mirror header (mtime=%s)\n' "${mirror_mtime:-unknown}"
    return 0
}

# ── checkpoint_check_tracker_doctor ──────────────────────────────────────

checkpoint_check_tracker_doctor() {
    local target="${1:-}" pack="${2:-${PACK:-}}"
    local doctor_sh="$pack/scripts/pack-tracker.sh"
    if [[ ! -f "$doctor_sh" ]]; then
        printf '  [INFO] doctor: pack-tracker.sh not in PACK; skipping\n'
        return 0
    fi
    local out rc
    out=$( cd "$target" && bash "$doctor_sh" doctor 2>&1 )
    rc=$?
    if (( rc != 0 )); then
        printf '  [FAIL] doctor: `pack tracker doctor` exited %s  → Run: pack tracker doctor (review output)\n' "$rc"
        # Surface the doctor's own output indented for context.
        printf '%s\n' "$out" | sed 's/^/         /'
        return 1
    fi
    printf '  [OK]   doctor: `pack tracker doctor` clean\n'
    return 0
}

# ── checkpoint_tracker_mode_active ───────────────────────────────────────
#
# Helper used by Gate 3 to decide PASS-vs-SKIP. Returns 0 when the
# target is in tracker mode (tracker.toml present and mode.state=tracker
# and migration.forward_complete=true), 1 otherwise. Echoes nothing —
# pure boolean.
checkpoint_tracker_mode_active() {
    local target="${1:-}"
    local cfg="$target/tracker.toml"
    [[ -f "$cfg" ]] || return 1
    if ! declare -F tracker_mode >/dev/null 2>&1; then
        # Loader did not source tracker-config.sh — fall back to a
        # text-grep heuristic so the helper is self-contained.
        grep -q 'state[[:space:]]*=[[:space:]]*"tracker"' "$cfg" 2>/dev/null \
            && grep -q 'forward_complete[[:space:]]*=[[:space:]]*true' "$cfg" 2>/dev/null
        return $?
    fi
    local mode
    mode=$(tracker_mode "$cfg" 2>/dev/null || echo "flat-file")
    [[ "$mode" == "tracker" ]]
}
