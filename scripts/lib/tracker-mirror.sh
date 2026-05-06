# scripts/lib/tracker-mirror.sh — read-only mirror header write/strip
# (BD-067 refactor of BD-065 helpers).
#
# Sourced by tracker-migrate-forward.sh and tracker-migrate-reverse.sh.
#
# V1 §6.3 specifies the read-only mirror header that wraps every
# tracker-mode flat-file mirror. Forward migration prepends the
# header (with current backend slug + ISO timestamp); reverse
# migration strips it (the file is now authoritative).
#
# Public API:
#   - tracker_mirror_header_emit <backend-slug>
#       Emit the header block to stdout. Caller writes the rest of
#       the file content after one blank line.
#   - tracker_mirror_header_write <path> <backend-slug>
#       Idempotently rewrite the file at <path> with the header
#       prepended. N consecutive calls produce byte-equal output
#       modulo the timestamp line. Whitespace-tolerant input parsing.
#   - tracker_mirror_header_strip <path>
#       Remove a leading header block + adjacent blank-line gap.
#       Idempotent: if the file has no header, the file is unchanged.
#
# Reference: ARCHITECTURE.md §6.3, §6.5 step 8, §6.7.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

# Emit the header block on stdout, ending with `-->\n`. The caller
# writes one blank line + body content after it.
tracker_mirror_header_emit() {
    local backend_slug="$1"
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    cat <<EOF
<!--
  This file is a read-only mirror generated from the tracker.
  Tracker: github / $backend_slug
  Last regenerated: $now_iso
  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.
-->
EOF
}

# Idempotent in-place rewrite: prepend (or refresh) the header.
# N consecutive calls produce byte-equal output modulo the
# "Last regenerated" timestamp line.
tracker_mirror_header_write() {
    local path="$1"
    local backend_slug="$2"
    if [[ ! -f "$path" ]]; then
        return 0
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$path" "$backend_slug" "$now_iso" <<'PYEOF' || return 1
import re, sys
path, backend_slug, now_iso = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    text = f.read()

# Strip a leading header block + adjacent blank-line gap if present.
m = re.match(r'\s*<!--\s*\n.*?\n\s*-->\s*\n+', text, re.DOTALL)
body = text[m.end():] if m else text
body = body.rstrip('\n') + '\n'

header = (
    "<!--\n"
    "  This file is a read-only mirror generated from the tracker.\n"
    f"  Tracker: github / {backend_slug}\n"
    f"  Last regenerated: {now_iso}\n"
    "  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.\n"
    "-->\n"
)
with open(path, 'w') as f:
    f.write(header + "\n" + body)
PYEOF
}

# Strip a leading mirror-header block (V1 §6.5 step 8). Idempotent:
# files without a header are unchanged. After strip, the file
# starts at the first content line of the original body.
tracker_mirror_header_strip() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        return 0
    fi
    python3 - "$path" <<'PYEOF' || return 1
import re, sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()

# Match a leading header block + adjacent blank-line gap.
m = re.match(r'\s*<!--\s*\n.*?\n\s*-->\s*\n+', text, re.DOTALL)
if m:
    body = text[m.end():]
    # Normalize: file ends with exactly one trailing newline.
    body = body.rstrip('\n') + '\n'
    with open(path, 'w') as f:
        f.write(body)
PYEOF
}
