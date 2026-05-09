# scripts/lib/tracker-header-snapshot.sh — BACKLOG.md header
# preservation across reverse migration round-trips (BD-133 / D-6).
#
# Problem:
#   `pack tracker disable` reverse-emits BACKLOG.md from tracker
#   issues. The emitter (`_tmr_emit_backlog` in tracker-migrate-
#   reverse.sh) writes `# BACKLOG\n` + per-entry blocks from scratch,
#   destroying ANY preamble the user had above the first entry — the
#   `# Backlog` title, the introductory paragraph, the
#   `## How to use this file` section, type/status conventions, etc.
#   Empirically caught during BD-102 Phase A dog-food: a 25-line
#   preamble vanished on the first init→disable cycle.
#
# Design (V1 §6.5 design intent: project-specific content not
# representable in the tracker is sidecar-preserved):
#
#   - Snapshot, on demand, the existing BACKLOG.md "header" (every
#     byte before the first `**BD-NNN — `, `**TD-NNN — `, or
#     `**phase-N` line) into `.pack-tracker/backlog-header.snapshot`.
#   - First-write-wins: the snapshot is taken once, the first time
#     reverse runs against a repo that has both a BACKLOG.md AND no
#     existing snapshot file. On every subsequent reverse the
#     snapshot is reused as-is, so the header does not degrade
#     across multiple round-trips (a degenerate snapshot would
#     otherwise eat itself; first-write-wins guarantees fixed-point
#     stability).
#   - Re-emit: after `_tmr_emit_backlog` writes the entries-only
#     BACKLOG.md, the snapshot is prepended back. The result is
#     header-preamble + entries — byte-identical to the original
#     header preamble plus a freshly-emitted entries section.
#
# Why this module (not a forward-side snapshot, and not the existing
# reverse sidecar):
#
#   - Forward-side snapshot (option a per BD-133) was rejected:
#     `tracker-migrate-forward.sh` is owned by BD-131 in this batch
#     and edits there would conflict.
#   - The dated reverse sidecar (`reverse.sidecar.YYYY-MM-DD.md`) is
#     designed for ephemeral per-run dumps (it auto-cleans older
#     dated files); the header snapshot is persistent, not ephemeral,
#     and is consumed at write time, not by humans.
#   - A separate, focused module keeps the responsibility narrow and
#     lets reverse import the function with one source line.
#
# Public API:
#
#   tracker_header_snapshot_path <repo-root>
#       Emit the snapshot file path on stdout. Pure function;
#       does not touch the filesystem.
#
#   tracker_header_snapshot_capture <repo-root>
#       If `<repo-root>/.pack-tracker/backlog-header.snapshot` is
#       missing AND `<repo-root>/BACKLOG.md` exists AND its preamble
#       is non-trivial (at least one non-blank line that is not the
#       bare `# BACKLOG` line emitted by a prior reverse), capture
#       the preamble into the snapshot file. No-op otherwise.
#       Returns 0 on capture, 0 on no-op, 1 on I/O failure.
#
#   tracker_header_snapshot_apply <repo-root> <backlog-path>
#       If a snapshot exists, prepend it to <backlog-path>. The
#       caller is responsible for having already written the
#       entries-only BACKLOG.md at <backlog-path>. The snapshot
#       replaces any leading `# BACKLOG\n\n` (or `# BACKLOG\n`)
#       header that the entries-only emitter wrote, so the final
#       file does not contain a redundant title.
#       Returns 0 on apply, 0 on no-op (snapshot absent), 1 on I/O
#       failure.
#
# Reference: BACKLOG.md BD-133, ARCHITECTURE.md §6.5 step 4,
#            §6.6 sidecar design intent.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Path resolver
# ─────────────────────────────────────────────────────────────────

tracker_header_snapshot_path() {
    local repo_root="$1"
    echo "$repo_root/.pack-tracker/backlog-header.snapshot"
}

# ─────────────────────────────────────────────────────────────────
# Capture: snapshot the header preamble (idempotent, first-write-wins)
# ─────────────────────────────────────────────────────────────────

# Internal: extract the header preamble (everything before the first
# entry/phase heading) from a BACKLOG.md file. Reads from $1, writes
# the preamble verbatim to stdout. If no entry/phase heading is
# found, the entire file is the "preamble" (the caller's filter
# decides whether to capture).
_ths_extract_preamble() {
    local backlog_path="$1"
    python3 - "$backlog_path" <<'PYEOF'
import re, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    text = f.read()

# Match the first line that looks like an entry or phase heading.
# Entry headings: `**BD-NNN — title**`, `**TD-NNN — title**`,
# `**phase-N — title**` (em-dash; the v10 grammar uses U+2014).
# Tolerate ASCII hyphen and en-dash too — defensive parsing.
pat = re.compile(
    r'^\*\*(?:BD|TD|phase)-\d+(?:\.\d+)?[ \t]*[—–\-][ \t]',
    re.M,
)
m = pat.search(text)
if m:
    sys.stdout.write(text[:m.start()])
else:
    sys.stdout.write(text)
PYEOF
}

# Internal: decide whether the extracted preamble is "non-trivial"
# enough to be worth snapshotting. A preamble of just whitespace or
# the bare `# BACKLOG\n` line that prior-reverse runs emit is a
# no-op snapshot — capturing it would lose the real preamble that
# the user wants preserved on a future first-cycle.
#
# Reads the candidate preamble from a file path passed as $1 (NOT
# stdin: `python3 - <<EOF` consumes stdin for the script body, so
# we'd lose the piped data; passing a path keeps the predicate
# composable with both file-input and pipe-input callers via mktemp).
# Returns 0 if non-trivial, 1 if trivial (caller should skip capture).
_ths_preamble_is_substantive() {
    local path="$1"
    python3 - "$path" <<'PYEOF'
import re, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    text = f.read()
# Strip whitespace-only and the canonical entries-only headers.
# Patterns considered "trivial":
#   (a) entirely blank
#   (b) just `# BACKLOG\n` (entries-only emitter output)
#   (c) just `# BACKLOG\n\n` with trailing blank
#   (d) just `# Backlog\n` (case-variant)
stripped = text.strip()
if not stripped:
    sys.exit(1)
trivial = re.fullmatch(r'#\s*BACKLOG\s*', stripped, re.IGNORECASE)
if trivial:
    sys.exit(1)
sys.exit(0)
PYEOF
}

# tracker_header_snapshot_capture <repo-root>
#
# Snapshot the BACKLOG.md preamble if (and only if):
#   - <repo-root>/BACKLOG.md exists
#   - .pack-tracker/backlog-header.snapshot does NOT yet exist
#   - the extracted preamble is substantive (per the predicate above)
#
# The first-write-wins rule is critical: after the first reverse
# emits an entries-only BACKLOG.md (then prepends the snapshot), the
# next reverse will see a file whose preamble IS the snapshot — and
# will refuse to re-snapshot because the snapshot file already exists.
# This guarantees the header survives N round-trips byte-identical to
# its first capture.
tracker_header_snapshot_capture() {
    local repo_root="$1"
    local backlog_path="$repo_root/BACKLOG.md"
    local snap_path
    snap_path=$(tracker_header_snapshot_path "$repo_root")

    # No-op cases.
    if [[ ! -f "$backlog_path" ]]; then
        return 0
    fi
    if [[ -f "$snap_path" ]]; then
        return 0
    fi

    # Extract preamble to a temp file (we need a file for the
    # substantive predicate, AND to atomically rename into place if
    # the predicate passes). One write, two reads — cheaper than two
    # extract calls, and avoids command-substitution trailing-newline
    # trim of the original preamble's bytes (printf '%s' "$preamble"
    # would still preserve embedded newlines, but a trailing-newline
    # round-trip via $() can drop one — atomic file write avoids that
    # ambiguity entirely).
    local tmp
    tmp=$(mktemp -t ths-snap.XXXXXX) || return 1
    if ! _ths_extract_preamble "$backlog_path" > "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        return 1
    fi

    # Substantive check. Predicate returns 0 (substantive) or 1
    # (trivial; skip).
    if ! _ths_preamble_is_substantive "$tmp"; then
        rm -f "$tmp"
        return 0
    fi

    # Ensure the .pack-tracker directory exists. Other modules
    # (tracker-migrate-forward.sh, tracker-sidecar.sh) also create
    # this directory; we mirror their idempotent mkdir pattern.
    mkdir -p "$(dirname "$snap_path")" || { rm -f "$tmp"; return 1; }

    # Atomic rename: tmp file already holds the snapshot bytes.
    mv "$tmp" "$snap_path" || { rm -f "$tmp"; return 1; }

    return 0
}

# ─────────────────────────────────────────────────────────────────
# Apply: prepend the snapshot to the freshly-emitted BACKLOG.md
# ─────────────────────────────────────────────────────────────────

# tracker_header_snapshot_apply <repo-root> <backlog-path>
#
# After `_tmr_emit_backlog` has written entries-only content at
# <backlog-path>, splice the snapshot back in. The snapshot file
# already contains the original `# Backlog` title (or whatever the
# project's actual title was), so the entries-only emitter's
# `# BACKLOG\n\n` prefix is stripped before the snapshot is
# prepended — otherwise the file would have two competing titles.
#
# No-op if the snapshot is absent (e.g. very first reverse on a
# brand-new repo with no BACKLOG.md preamble worth preserving).
tracker_header_snapshot_apply() {
    local repo_root="$1"
    local backlog_path="$2"
    local snap_path
    snap_path=$(tracker_header_snapshot_path "$repo_root")

    if [[ ! -f "$snap_path" ]]; then
        return 0
    fi
    if [[ ! -f "$backlog_path" ]]; then
        return 1
    fi

    # Read snapshot + entries-only body, strip the entries-only
    # `# BACKLOG\n\n?` header, write snapshot + body.
    python3 - "$snap_path" "$backlog_path" <<'PYEOF' || return 1
import re, sys
snap_path, body_path = sys.argv[1], sys.argv[2]
with open(snap_path, 'r', encoding='utf-8') as f:
    snapshot = f.read()
with open(body_path, 'r', encoding='utf-8') as f:
    body = f.read()

# Strip a leading `# BACKLOG` heading line + any blank lines that
# follow it — the entries-only emitter writes this prefix. Match
# case-insensitively to tolerate `# Backlog` variants too, in case
# a future emitter normalizes differently.
body = re.sub(r'^\s*#\s*BACKLOG\s*\n+', '', body, count=1,
              flags=re.IGNORECASE)

# Compose. Snapshot is preserved byte-identical; we add exactly one
# blank-line separator if the snapshot does not already end with
# one (so projects that authored a trailing blank line keep their
# spacing, and projects that did not still get a clean visual gap
# before the entries section).
if not snapshot.endswith('\n'):
    snapshot = snapshot + '\n'
if not snapshot.endswith('\n\n'):
    snapshot = snapshot + '\n'

with open(body_path, 'w', encoding='utf-8') as f:
    f.write(snapshot + body)
PYEOF
    return 0
}
