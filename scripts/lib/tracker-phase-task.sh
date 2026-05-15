# scripts/lib/tracker-phase-task.sh — phase-task entity model
# (BD-106; V3.3 §2 D-21 + §3.5 + §4.1 + §4.2 + §4.3 + §5.3).
#
# Phase tasks are first-class L2 entities under their phase-epic
# parent (V3.3 §2 D-21). Identifier scheme: `phase-N.M` (lowercase,
# dash-separated; M is the integer task number from
# IMPLEMENTATION-PLAN.md).
#
# This library lands the parser + emitter for `### Tasks` blocks and
# the helpers that downstream BDs (BD-107 promotion, BD-108 cross-
# entity dependency links) compose with. It is **deliberately
# single-file** — parse and emit operate on the same grammar surface
# (METHODOLOGY § Part 4; V3.3 §4.1/§4.2) and share the regex
# definitions; splitting them would force the regex to live in two
# places (drift risk). The existing `tracker-migrate-forward.sh` /
# `tracker-migrate-reverse.sh` split is justified by their disjoint
# algorithms (forward = create issues + checkpoint; reverse =
# reconstruct flat-file from canonical Issue JSON); BD-106's
# parse/emit are the same shape on opposite directions and stay
# co-located.
#
# Public API:
#   - tracker_phase_task_parse <path>
#       Parse IMPLEMENTATION-PLAN.md and emit a JSON document on
#       stdout shaped:
#         {
#           "phases": [
#             {
#               "phase_number": "3",
#               "title":        "Foundations",
#               "tasks": [
#                 {
#                   "pack_id":           "phase-3.1",
#                   "task_number":       "1",
#                   "title":             "First task",
#                   "problem":           "...",
#                   "files":             "...",
#                   "definition_of_done":"...",
#                   "dependencies": [
#                     {
#                       "kind":       "blocked-by",
#                       "target":     "phase-3.2",
#                       "annotation": "(must complete schema before this task)"
#                     },
#                     ...
#                   ]
#                 },
#                 ...
#               ],
#               "task_order": ["1", "2", ...]
#             },
#             ...
#           ]
#         }
#
#       The `dependencies` shape feeds directly into the sidecar
#       `dependency_edges` block (V3.3 §4.3 + the §5.3 prose-
#       annotation preservation contract: emitter MUST replay the
#       trailing free-text after the matched ID so round-trip is
#       byte-identical).
#
#   - tracker_phase_task_emit <parsed-json>
#       Reverse of parse. Emits the canonical METHODOLOGY § Part 4
#       text shape on stdout. Whitespace-tolerant per V1 §6.7; for
#       round-trip identity tests, the input parsed-json must come
#       directly from tracker_phase_task_parse on the file being
#       emitted (free-text body content is captured verbatim).
#
#   - tracker_phase_task_compose_pack_id <phase> <task>
#       Returns "phase-<N>.<M>" on stdout. Single source of truth
#       for the identifier scheme.
#
#   - tracker_phase_task_dependency_re
#       Echoes the regex (POSIX ERE) that matches a single
#       Dependencies entry: `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)`.
#       Open-string label / id grammar per V3.3 §5.3.
#
# Reference: ARCHITECTURE-V3.3-DELTA.md §2, §3.5, §4.1-§4.4, §5.3,
#            §6.4; ARCHITECTURE-V3.2-DELTA.md §4.1, §4.2, §4.3.
#
# Constraints:
#   - Bash 3.2 compatible (no associative arrays, no mapfile).
#   - Heavy parsing offloaded to python3 (already a hard dependency,
#     see tracker-migrate-forward.sh's tmf_parse_backlog).
#   - Path 3 is FORBIDDEN per V3.3 §3 line 27 — this library does
#     NOT recognize `(from TD-NNN)` body markers and does NOT emit
#     a `folded-into:` label.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Public: identifier scheme + grammar
# ─────────────────────────────────────────────────────────────────

# tracker_phase_task_compose_pack_id <phase-number> <task-number>
# Returns "phase-<N>.<M>" on stdout. Inputs must be integers; this
# function does no validation — callers (the parser) validate via
# regex before calling.
tracker_phase_task_compose_pack_id() {
    local n="$1"
    local m="$2"
    printf 'phase-%s.%s\n' "$n" "$m"
}

# tracker_phase_task_dependency_re
# Echoes the POSIX ERE that matches a single Dependencies-bullet
# entry. Anchored on `- ` (one dash + space) with optional leading
# whitespace; captures the ID prefix (group 1). Trailing free text
# after the ID is the "annotation" per V3.3 §5.3 — preserved by the
# parser as the `annotation` sub-field for lossless emit.
#
# Capture groups (POSIX ERE; bash `[[ =~ ]]` BASH_REMATCH indices):
#   group 1 = the pack-id (`phase-N(.M)?` | `TD-N` | `BD-N`)
#   group 2 = optional `.M` (internal sub-capture of group 1)
#   group 3 = optional ` <annotation-with-leading-whitespace>` (the
#            full `[[:space:]]+(.*)` match — analogous to the Python
#            `DEP_ENTRY` group 2)
#   group 4 = the annotation body alone, with leading whitespace
#            consumed by `[[:space:]]+` — analogous to the Python
#            `DEP_ENTRY` group 3 prior to `.strip()`. Callers may
#            apply trailing-whitespace trim via `${var%[[:space:]]*}`
#            if a stricter strip is needed (the canonical Python
#            parser uses `.strip()` to drop both ends).
#
# Capture-group equivalence with the internal Python `DEP_ENTRY`
# regex (line 187): group 1 is byte-identical; group 4 (bash) has
# the same trim-equivalent meaning as Python group 3 (Python applies
# `.strip()` after the regex; bash strips leading whitespace via
# `[[:space:]]+` consumption). Test Group 1 verifies group-1 parity
# and documents the group-3/4 mapping.
tracker_phase_task_dependency_re() {
    printf '%s\n' '^[[:space:]]*-[[:space:]]+(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)([[:space:]]+(.*))?$'
}

# ─────────────────────────────────────────────────────────────────
# Public: parser — IMPLEMENTATION-PLAN.md → JSON
# ─────────────────────────────────────────────────────────────────

# tracker_phase_task_parse <path>
# Parse the canonical METHODOLOGY § Part 4 phase structure:
#
#   ## Phase N — <title>
#   <prose>
#   ### Tasks
#   #### N.M — <title>
#   - **Problem / Goal / Success**: ...
#   - **Files created/modified**: ...
#   - **Definition of done**: ...
#   - **Dependencies**:
#     - phase-X.Y
#     - TD-NNN (annotation)
#   #### N.M+1 — <title>
#   ...
#   ### Verification
#   ...
#
# Recognized headings:
#   - Phase header:  ^## Phase (\d+) [—-] (.+)$           (H2)
#   - Tasks H3:      ^### Tasks\s*$                        (case-sensitive)
#   - Task header:   ^#### (\d+)\.(\d+) [—-] (.+)$         (H4)
#
# Sparse phases (missing `### Tasks`) yield phase entries with empty
# `tasks` array per V3.3 §4.1 (warning, not error — but warnings are
# emitted to stderr, not stdout).
#
# Malformed `#### N.M` headings (missing em-dash, non-integer M) are
# emitted as warnings to stderr; the malformed line is skipped.
#
# Path 3 forbidden (V3.3 §3 line 27): no `(from TD-NNN)` body marker
# is recognized; if such a marker appears in any bullet body, it is
# carried forward as part of the bullet text but does NOT influence
# parsing.
tracker_phase_task_parse() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        tracker_error_emit "not-found" "tracker_phase_task_parse: $path does not exist"
        return 1
    fi
    python3 - "$path" <<'PYEOF'
import json
import re
import sys

path = sys.argv[1]
with open(path) as f:
    text = f.read()

PHASE_HEADER = re.compile(r'^##\s+Phase\s+(\d+)\s*[—-]\s*(.+?)\s*$')
TASKS_H3     = re.compile(r'^###\s+Tasks\s*$')
OTHER_H3     = re.compile(r'^###\s+\S')
TASK_HEADER  = re.compile(r'^####\s+(\d+)\.(\d+)\s*[—-]\s*(.+?)\s*$')
MALFORMED_H4 = re.compile(r'^####\s+\S')
H1_OR_H2     = re.compile(r'^#{1,2}\s+\S')

# Bullet header regex: matches "- **<name>**:". Strict-colon per
# METHODOLOGY § Part 4 line 304 canonical (em-dash and hyphen
# separators dropped per BD-106 review F5 to avoid silent round-trip
# drift — the emitter only ever produces `:`). Captures the bullet
# name (group 1) and the trailing inline content on the same line
# (group 2, may be empty).
BULLET_HEAD = re.compile(r'^-\s+\*\*([^*]+?)\*\*\s*:\s*(.*)$')
# Continuation bullets nested under a top-level bullet:
NESTED_BULLET = re.compile(r'^\s+-\s+(.*)$')

# Dependencies-entry regex (V3.3 §5.3). Captures ID (group 1) and
# annotation (group 3 — everything after the ID, trimmed).
DEP_ENTRY = re.compile(
    r'^\s*-\s+(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?\s*$'
)

# Map bullet-header names to canonical sidecar field names. The
# match is case-insensitive and tolerates the four names from
# METHODOLOGY § Part 4 (with minor variants).
def normalize_bullet_name(raw):
    s = raw.strip().lower()
    s = re.sub(r'\s+', ' ', s)
    if s in ('problem / goal / success', 'problem/goal/success', 'problem'):
        return 'problem'
    if s in ('files created/modified', 'files',
             'files created / modified', 'files-created-modified'):
        return 'files'
    if s in ('definition of done', 'definition-of-done', 'dod'):
        return 'definition_of_done'
    if s in ('dependencies', 'dependency'):
        return 'dependencies'
    return None  # unknown bullet — ignored

phases = []
current_phase = None
current_task = None
current_bullet = None      # canonical name being collected
in_tasks_h3 = False
warnings = []

def flush_task():
    """Finalize the current task — convert dependencies field into
    list-of-objects with kind/target/annotation per V3.3 §4.3 +
    §5.3 round-trip preservation."""
    global current_task
    if current_task is None:
        return
    deps_raw = current_task.get('dependencies', '')
    parsed_deps = []
    if isinstance(deps_raw, str) and deps_raw.strip():
        for raw_line in deps_raw.splitlines():
            m = DEP_ENTRY.match(raw_line)
            if not m:
                # Skip non-matching lines but warn (free-text inside
                # the dependencies bullet is supported per §5.3 only
                # as trailing annotation on a matching ID line).
                if raw_line.strip():
                    warnings.append(
                        f'phase-task {current_task["pack_id"]}: '
                        f'unrecognized Dependencies line ignored: '
                        f'{raw_line.strip()!r}'
                    )
                continue
            ident = m.group(1)
            annotation = (m.group(3) or '').strip()
            parsed_deps.append({
                'kind':       'blocked-by',  # V3.3 §5.2 canonical direction
                'target':     ident,
                'annotation': annotation,
            })
    current_task['dependencies'] = parsed_deps
    current_phase['tasks'].append(current_task)
    current_phase['task_order'].append(current_task['task_number'])
    current_task = None

def flush_phase():
    global current_phase, current_task, in_tasks_h3
    flush_task()
    if current_phase is not None:
        phases.append(current_phase)
    current_phase = None
    in_tasks_h3 = False

def append_to_current_bullet(line):
    """Append a continuation/body line to the active bullet."""
    if current_task is None or current_bullet is None:
        return
    if current_task[current_bullet]:
        current_task[current_bullet] += '\n' + line
    else:
        current_task[current_bullet] = line

for raw in text.splitlines():
    # H1 or H2 boundary closes a phase context.
    pm = PHASE_HEADER.match(raw)
    if pm:
        flush_phase()
        current_phase = {
            'phase_number': pm.group(1),
            'title':        pm.group(2).strip(),
            'tasks':        [],
            'task_order':   [],
        }
        in_tasks_h3 = False
        continue
    if H1_OR_H2.match(raw) and not pm:
        # Some other H1/H2 (e.g. "## Phases" wrapper, or doc heading).
        # Close any in-flight phase but do not start a new one.
        flush_phase()
        in_tasks_h3 = False
        continue

    # H3 boundaries: enter Tasks zone or leave it for sibling H3s.
    if TASKS_H3.match(raw):
        flush_task()
        in_tasks_h3 = True
        continue
    if OTHER_H3.match(raw):
        # Leaving the Tasks zone (e.g. "### Verification").
        flush_task()
        in_tasks_h3 = False
        continue

    # Task header (only when in a Tasks zone of a phase).
    if in_tasks_h3 and current_phase is not None:
        tm = TASK_HEADER.match(raw)
        if tm:
            flush_task()
            n_str = tm.group(1)
            m_str = tm.group(2)
            title = tm.group(3).strip()
            # Cross-check: phase number must match.
            if n_str != current_phase['phase_number']:
                warnings.append(
                    f'task #### {n_str}.{m_str} appears under '
                    f'## Phase {current_phase["phase_number"]} '
                    f'(numbering mismatch; accepted as-is)'
                )
            current_task = {
                'pack_id':            f'phase-{n_str}.{m_str}',
                'task_number':        m_str,
                'title':              title,
                'problem':            '',
                'files':              '',
                'definition_of_done': '',
                'dependencies':       '',
            }
            current_bullet = None
            continue
        # Malformed `#### ` heading inside Tasks H3 — warn + skip.
        if MALFORMED_H4.match(raw):
            warnings.append(
                f'malformed task heading ignored under ## Phase '
                f'{current_phase["phase_number"]}: {raw.strip()!r}'
            )
            continue

    # Bullet handling (only inside an active task).
    if current_task is not None and in_tasks_h3:
        bm = BULLET_HEAD.match(raw)
        if bm:
            name = normalize_bullet_name(bm.group(1))
            tail = bm.group(2)
            if name is not None:
                current_bullet = name
                # Inline content on the same line as the bullet
                # header (e.g. "- **Problem**: short value"). For
                # the Dependencies bullet, inline content is rare —
                # the entries are usually on nested bullets below.
                if tail.strip():
                    if name == 'dependencies':
                        # Treat inline content on the Dependencies
                        # header as the first dependency line.
                        current_task[name] = '- ' + tail.strip()
                    else:
                        current_task[name] = tail
                else:
                    current_task[name] = ''
            else:
                current_bullet = None
            continue
        # Nested or continuation line for the active bullet.
        if current_bullet is not None:
            if current_bullet == 'dependencies':
                # Dependencies bullets live as nested `- <id>` lines
                # under the top-level bullet header. Capture the raw
                # nested-bullet line for downstream parsing.
                if NESTED_BULLET.match(raw):
                    append_to_current_bullet(raw.lstrip())
                elif raw.strip() == '':
                    # Blank line is allowed inside the dependencies
                    # block; state is unchanged until the next bullet
                    # header (BULLET_HEAD or NESTED_BULLET) resets it.
                    pass
                # Anything else falls through (loose annotation
                # outside an entry) — warn at flush time.
                else:
                    pass
            else:
                # For Problem/Files/DoD, indented or unindented
                # continuation lines append until the next bullet
                # header. Blank lines are part of the body (for
                # paragraph spacing) — preserved verbatim for
                # round-trip identity.
                append_to_current_bullet(raw)
            continue

    # Anything else outside a recognized context is ignored
    # (preamble prose, blank lines between sections, etc.).

# End-of-file flush.
flush_phase()

# Strip trailing whitespace from collected body fields (parser
# normalization; emitter re-pads as needed).
for ph in phases:
    for t in ph['tasks']:
        for k in ('problem', 'files', 'definition_of_done'):
            if isinstance(t[k], str):
                t[k] = t[k].rstrip()

doc = {'phases': phases}
print(json.dumps(doc, ensure_ascii=False))

if warnings:
    for w in warnings:
        print(f'WARNING: tracker_phase_task_parse: {w}', file=sys.stderr)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Public: emitter — JSON → IMPLEMENTATION-PLAN.md fragment
# ─────────────────────────────────────────────────────────────────

# tracker_phase_task_emit <parsed-json>
# Emit phase blocks back to canonical METHODOLOGY § Part 4 text. The
# input must be the JSON document tracker_phase_task_parse produces.
# Output shape, per phase:
#
#   ## Phase N — <title>
#
#   ### Tasks
#   #### N.M — <title>
#   - **Problem / Goal / Success**: <body>
#   - **Files created/modified**: <body>
#   - **Definition of done**: <body>
#   - **Dependencies**:
#     - <id> [<annotation>]
#     - ...
#
# Whitespace contract (V1 §6.7):
#   - one blank line after the `## Phase` header
#   - one blank line between tasks
#   - inline body fields are emitted as captured during parse
#     (verbatim). For round-trip identity tests, the emitter is
#     byte-identical with the source bullet bodies.
#
# Round-trip byte-identity preconditions (per BD-106 review F4):
#   Byte-identity (`parse → emit → diff = empty`) holds ONLY when the
#   source text already uses the canonical bullet shape:
#     1. Canonical bullet names — `Problem / Goal / Success`,
#        `Files created/modified`, `Definition of done`, `Dependencies`.
#        Non-canonical aliases (e.g. `Problem`, `Files`, `DoD`) parse
#        semantically but are CANONICALIZED on emit (the emitter
#        always produces the canonical name).
#     2. Canonical separator — `: ` after the bullet name. The parser
#        is strict to colon (per F5); the emitter always produces `:`.
#     3. No trailing whitespace on any line — the parser strips
#        trailing whitespace on body fields during normalization
#        (lines 410-414); a source line with trailing spaces will
#        not round-trip byte-identically.
#   Inputs that satisfy all three conditions round-trip byte-identically
#   (the `ROUNDTRIP.md` fixture is built to satisfy them — proof in
#   Test 3.1 SHA-256). Inputs that violate any condition still round-
#   trip semantically (parse → emit → re-parse preserves the parsed
#   document equality — proof in Test 3.3 / 3.4).
#
# The emitter does NOT re-emit prose between `## Phase` and
# `### Tasks` (e.g. Goal / Prerequisite paragraphs, ### Verification,
# ### Agent, ### Risks) because BD-106's scope is the `### Tasks`
# block grammar; surrounding prose is phase-epic body content owned
# by the existing tracker-migrate-forward.sh phase parser. The
# round-trip identity test exercises only the `### Tasks` slice (the
# fixture is built without surrounding prose so byte-identity holds);
# the broader-fixture test asserts task content is preserved
# semantically (parse → re-parse equality on the emitter output).
#
# Implementation note: the JSON document is passed via an env var
# (TPT_DOC_JSON) instead of stdin because bash heredocs (`<<'PYEOF'`)
# replace stdin with the heredoc body — a stdin pipe would be
# silently dropped. Env var is bash-3.2-portable and preserves
# arbitrary content (json.loads handles any UTF-8 string).
tracker_phase_task_emit() {
    local doc_json="$1"
    if [[ -z "$doc_json" ]]; then
        tracker_error_emit "validation" "empty input to tracker_phase_task_emit"
        return 1
    fi
    TPT_DOC_JSON="$doc_json" python3 - <<'PYEOF'
import json
import os
import sys

doc = json.loads(os.environ['TPT_DOC_JSON'])
phases = doc.get('phases', [])

def format_bullet(name, body):
    """Emit a top-level bullet whose value is `body`. If body is
    multi-line, the first line follows the colon inline; subsequent
    lines are emitted verbatim (parser captured them verbatim, so
    round-trip identity holds)."""
    lines = []
    if body == '' or body is None:
        lines.append(f'- **{name}**: ')
        return lines
    body_lines = body.split('\n')
    lines.append(f'- **{name}**: {body_lines[0]}')
    for extra in body_lines[1:]:
        lines.append(extra)
    return lines

out_lines = []
first_phase = True

for ph in phases:
    if not first_phase:
        out_lines.append('')
    first_phase = False
    out_lines.append(f'## Phase {ph["phase_number"]} — {ph["title"]}')
    out_lines.append('')
    out_lines.append('### Tasks')
    first_task = True
    order = ph.get('task_order') or [t['task_number'] for t in ph['tasks']]
    by_number = {t['task_number']: t for t in ph['tasks']}
    for task_num in order:
        t = by_number.get(task_num)
        if t is None:
            continue
        if not first_task:
            out_lines.append('')
        first_task = False
        out_lines.append(f'#### {ph["phase_number"]}.{task_num} — {t["title"]}')
        out_lines.extend(format_bullet('Problem / Goal / Success', t.get('problem', '')))
        out_lines.extend(format_bullet('Files created/modified',  t.get('files', '')))
        out_lines.extend(format_bullet('Definition of done',      t.get('definition_of_done', '')))
        deps = t.get('dependencies', [])
        if isinstance(deps, list):
            out_lines.append('- **Dependencies**:')
            for dep in deps:
                target = dep.get('target', '')
                annotation = (dep.get('annotation') or '').strip()
                if annotation:
                    out_lines.append(f'  - {target} {annotation}')
                else:
                    out_lines.append(f'  - {target}')
        else:
            out_lines.extend(format_bullet('Dependencies', deps if isinstance(deps, str) else ''))

sys.stdout.write('\n'.join(out_lines))
sys.stdout.write('\n')
PYEOF
}
