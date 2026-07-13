#!/usr/bin/env bash
# validate-docs.sh — Operating-doc enforcement gate.
#
# Keeps the project's operating docs forward-only, terse, and
# referentially sound, AND the project's per-entry streams schema-
# conformant. Operating docs are the live instruction surface the agents
# and the PM chat execute: the project trinity (CLAUDE.md / AGENTS.md /
# GEMINI.md), the docs/pack/ reference docs, the per-agent prompts, the
# skills, the agent definitions, and the stream contract files
# (docs/project/*/_rules.md).
#
# Four operating-doc axes + a per-entry conformance leg + a session-state
# snapshot leg:
#   - HISTORY   — dates / SHAs / past-action narration / provenance
#                 belong in BACKLOG / CHANGELOG entries and completion
#                 reports, never in a forward-only operating doc.
#   - DEFERRED  — an operating doc must not advertise a deferred /
#                 unimplemented / off-by-default feature.
#   - BLOAT     — a single per-bullet character cap over the trinity
#                 "## Project rules" bullets (the mega-bullet axis).
#   - DANGLING  — a backtick / hyperlink / qualified-path file reference
#                 whose target does not resolve in the project tree.
#   - CONFORMANCE — the populated per-entry streams conform to the
#                 no-mirror form-family / structured schema declared in
#                 each stream's _rules.md (the same SSOT schema block the
#                 pack-side validate-pack.py leg parses; the two parsers
#                 cannot diverge). Validates: sanctioned sidecar
#                 vocabulary (no _format.md / _scaffolding.md), NO
#                 reintroduced monolith mirror, per-entry field /
#                 structure conformance (form-family for backlog +
#                 implementation-plan, structured for changelog, the
#                 closed byte-canonical grouping grammar for groupings
#                 incl. the reserved-GRP-000 branch), the impl-plan
#                 `_index.md` ordering properties, the groupings
#                 stream-level legs (member resolution, exclusivity,
#                 toc-sync), the optional
#                 `Target:` release-window vocabulary (schema
#                 `target-enum`), and target-coherence over dependency
#                 edges (a declared target must not exceed the provable
#                 dependency bound).
#   - SESSION-STATE — when the committed PM-Chat resume snapshot
#                 docs/project/pm-session-state.json is present it is
#                 validated (struct: required keys, one boundary SHA, one
#                 ISO-8601 checkpoint; grammar: anti-accretion bounds).
#                 Absent → skipped (runtime-authored; not in the bare
#                 template).
#
# History stores are EXCLUDED from the operating-doc scan (never scanned
# on the 4 axes): the per-entry streams under
# docs/project/{backlog,implementation-plan,changelog}/, STATUS.md,
# docs/reference/, completion reports, _intro.md / _toc.md /
# HELP-FRAGMENT*.md, and scripts/ + proto/ + source code. Those
# legitimately carry dates and deferral narrative. (The per-entry
# streams are NOT scanned on the 4 operating-doc axes, but ARE checked
# by the separate CONFORMANCE leg below.)
#
# Usage:
#   validate-docs.sh            scan the full operating-doc set +
#                               per-entry conformance + the session-state
#                               snapshot (when present)
#   validate-docs.sh <file.md>  gate one file only (per-edit fast path)
#   validate-docs.sh --self-test  run the built-in synthetic checks
#
# Legitimate exceptions live in scripts/.docs-gate-allowlist.txt
# (a (doc, pattern, snippet, reason) record file the developer extends).
#
# Self-contained: bash + an embedded python3 pass (python3 is already a
# project dependency via validate-python.sh). Safe to run directly.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[validate-docs] python3 not found — required for the operating-doc gate." >&2
  exit 1
fi

ALLOWLIST="$SCRIPT_DIR/.docs-gate-allowlist.txt"

MODE="scan"
ARG_FILE=""
case "${1:-}" in
  --self-test) MODE="selftest" ;;
  "")          MODE="scan" ;;
  *)           MODE="file"; ARG_FILE="$1" ;;
esac

# The embedded python3 pass does the matching. ROOT_DIR, ALLOWLIST, MODE,
# and ARG_FILE are passed via the environment.
ROOT_DIR="$ROOT_DIR" ALLOWLIST="$ALLOWLIST" GATE_MODE="$MODE" \
ARG_FILE="$ARG_FILE" python3 - <<'PYEOF'
import json
import os
import re
import sys

ROOT = os.environ["ROOT_DIR"]
ALLOWLIST = os.environ["ALLOWLIST"]
MODE = os.environ["GATE_MODE"]
ARG_FILE = os.environ.get("ARG_FILE", "")

# ---------------------------------------------------------------------------
# The operating-doc IN families (globbed relative to the project root). New
# x-<name> skills / agents are auto-discovered by the globs.
# ---------------------------------------------------------------------------
IN_GLOBS = [
    "CLAUDE.md", "AGENTS.md", "GEMINI.md",
    "docs/pack/*.md",
    "docs/pack/prompts/*.md",
    "skills/*/SKILL.md",
    ".claude/agents/*.md",
    ".codex/agents/*.toml",
    ".agents-plugin/optiquity-agents/agents/*.md",
    "docs/project/backlog/_rules.md",
    "docs/project/implementation-plan/_rules.md",
    "docs/project/changelog/_rules.md",
    "docs/project/groupings/_rules.md",
]

# Files matched by a glob above but EXCLUDED (help output / orientation are
# not operating instruction).
EXCLUDE_BASENAMES = {"HELP-FRAGMENT.md", "_intro.md", "_toc.md"}


def iter_in_set():
    import glob
    seen = []
    seenset = set()
    for pat in IN_GLOBS:
        for p in sorted(glob.glob(os.path.join(ROOT, pat))):
            rel = os.path.relpath(p, ROOT)
            base = os.path.basename(p)
            if base in EXCLUDE_BASENAMES:
                continue
            if rel not in seenset and os.path.isfile(p):
                seenset.add(rel)
                seen.append(rel)
    return seen


# ---------------------------------------------------------------------------
# Allowlist parsing — (doc, pattern, snippet, reason) records, blank-line
# separated, '#'-comment lines ignored. A hit clears when the doc matches
# AND an allowlisted snippet is a substring of the offending line. The
# DANGLING axis also honors `target:` records (a ref resolving to that
# target path is legitimate — a will-exist-at-install cross-reference).
# ---------------------------------------------------------------------------
def load_allowlist():
    by_doc = {}          # doc -> [snippet, ...]
    dangling_targets = set()   # target paths legitimate everywhere
    if not os.path.isfile(ALLOWLIST):
        return by_doc, dangling_targets
    rec = {}
    with open(ALLOWLIST, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.strip().startswith("#"):
                continue
            if line.strip() == "":
                _commit_record(rec, by_doc, dangling_targets)
                rec = {}
                continue
            if ":" in line:
                k, v = line.split(":", 1)
                rec[k.strip()] = v.strip()
        _commit_record(rec, by_doc, dangling_targets)
    return by_doc, dangling_targets


def _commit_record(rec, by_doc, dangling_targets):
    if not rec:
        return
    target = rec.get("target")
    if target:
        dangling_targets.add(target.lstrip("./"))
        return
    doc = rec.get("doc")
    snippet = rec.get("snippet")
    if doc and snippet:
        by_doc.setdefault(doc, []).append(snippet)


# ---------------------------------------------------------------------------
# Code-block + deny-list-fence stripping. Fenced ``` blocks and
# <!-- DENY-LIST-CONTENT-START/END --> regions (deliberate
# not-to-be-referenced examples) are blanked, preserving line numbers.
# ---------------------------------------------------------------------------
def strip_blocks(text):
    out = []
    in_fence = False
    in_deny = False
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("```"):
            in_fence = not in_fence
            out.append("")
            continue
        if "DENY-LIST-CONTENT-START" in s:
            in_deny = True
            out.append("")
            continue
        if "DENY-LIST-CONTENT-END" in s:
            in_deny = False
            out.append("")
            continue
        out.append("" if (in_fence or in_deny) else line)
    return out


# ---------------------------------------------------------------------------
# AXIS: history
# date / SHA / Commit-N / Override-N / carry-over / incident / TD past-action
# / per-TD provenance. Project vocabulary is TD-, never BD-.
# ---------------------------------------------------------------------------
HISTORY_PATTERNS = [
    ("date", re.compile(r"20\d\d-\d\d-\d\d")),
    ("sha", re.compile(r"\b[0-9a-f]{7,40}\b")),
    ("commit-N", re.compile(r"Commit [0-9]")),
    ("override-N", re.compile(r"Override [0-9]")),
    ("carry-over", re.compile(r"carried from|carry-over")),
    ("incident", re.compile(r"\bincident\b")),
    ("td-past-action", re.compile(
        r"TD-\d+\s+(deleted|added|renamed|introduced|removed|created)")),
    ("per-TD", re.compile(r"per\s+TD-\d+")),
]

# AXIS: deferred
# Recall gate over deferral-marker prose. KEEP categories (rule self-ref /
# the live TD-deferral workflow / generic product advice) live in the
# allowlist. No version tokens (those would be a pack-internal leak).
DEFERRED_PATTERN = re.compile(
    r"\bdeferred\b|future (release|version)"
    r"|\bnot yet (created|implemented|built|shipped)\b"
    r"|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b",
    re.IGNORECASE,
)

# AXIS: bloat
# A single per-bullet character cap over the trinity memory heading
# bullets — the mega-bullet axis. Irreducible enumerations (e.g. the
# denied-git-verb list) are allowlisted by snippet.
BLOAT_BULLET_CHAR_CAP = 700
TRINITY = {"CLAUDE.md", "AGENTS.md", "GEMINI.md"}

# Client-local doc<->constant twin (the bijection leg target). The trinity
# memory-section heading the bloat matcher keys on lives here as the SINGLE
# source of truth, referenced by BOTH the bloat matcher (the load-bearing
# scan surface) AND the --self-test synthetic trinity docs (the verification
# surface). If the project renames this heading, both surfaces move together
# from this one constant; the --self-test bijection leg asserts the two
# surfaces never drift apart (a renamed matcher with a stale self-test doc,
# or vice versa, would silently break the bloat scan). Client-local: this
# gate polices its own twin; it imports nothing from the platform side.
TRINITY_MEMORY_HEADING = "## Project rules"

# AXIS: dangling
# Backtick / hyperlink qualified-path file refs (containing a '/') resolved
# against the project basename + relative-path index. Project-grammar
# placeholders and anchor-phrase self-flagged refs are carved out; the
# allowlist `target:` records cover will-exist-at-install cross-references.
_DANGLING_EXT = "md|sh|py|toml|yml|yaml|json|txt|proto|swift"
DANGLING_BACKTICK = re.compile(
    r"`([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:" + _DANGLING_EXT + r"))`")
DANGLING_HYPERLINK = re.compile(
    r"\]\(([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:" + _DANGLING_EXT + r"))\)")
DANGLING_PLACEHOLDERS = [re.compile(p, re.IGNORECASE) for p in (
    r"TD-N+\.md", r"TD-NNN", r"phase-N", r"\d{4}-MM-DD",
    r"x-[\w<>-]+", r"\[PROJECT_NAME\]", r"<\w+>",
)]
DANGLING_ANCHORS = (
    "archived", "does not exist", "no longer", "example", "e.g.",
    "placeholder", "for example", "such as", "orphan", "mirror",
    "regenerated", "installed by", "refreshed by", "the live file is",
)


def build_index(root):
    basenames = set()
    relpaths = set()
    for dp, dns, fns in os.walk(root):
        if os.sep + ".git" in dp:
            continue
        for fn in fns:
            basenames.add(fn)
            relpaths.add(os.path.relpath(os.path.join(dp, fn), root))
    return basenames, relpaths


def covered(line, snippets):
    return any(snip in line for snip in snippets)


def project_memory_bullets(lines):
    """Yield (start_lineno, char_count, preview) for each top-level bullet in
    the trinity memory section. A bullet runs from a '- ' line until the next
    '- ' line, a blank line, or the next '## ' header. The section heading is
    the single-source-of-truth TRINITY_MEMORY_HEADING constant (the
    bijection-leg twin)."""
    start = None
    for i, l in enumerate(lines):
        if l.strip() == TRINITY_MEMORY_HEADING:
            start = i
            break
    if start is None:
        return
    body = []
    for j, l in enumerate(lines[start + 1:], start=start + 2):
        if l.startswith("## "):
            break
        body.append((j, l))
    cur = None
    cur_line = None
    for ln, l in body:
        if re.match(r"^- ", l):
            if cur is not None:
                text = " ".join(x.strip() for x in cur)
                yield cur_line, len(text), text[:60]
            cur = [l]
            cur_line = ln
        elif cur is not None:
            if l.strip() == "":
                text = " ".join(x.strip() for x in cur)
                yield cur_line, len(text), text[:60]
                cur = None
            else:
                cur.append(l)
    if cur is not None:
        text = " ".join(x.strip() for x in cur)
        yield cur_line, len(text), text[:60]


REMEDIATION_HISTORY = (
    "Operating docs are forward-only. History / audit-trail text "
    "(dates / SHAs / Commit-N / past-action narration / provenance / "
    "incident or carry-over notes) belongs in BACKLOG / CHANGELOG "
    "entries and completion reports, never in an operating doc. "
    "Remediation: strip it, OR — if it is a rule self-reference, a live "
    "TD-deferral workflow line, or a format example — add a "
    "scripts/.docs-gate-allowlist.txt record with a reason:."
)
REMEDIATION_DEFERRED = (
    "An operating doc must not advertise a deferred / unimplemented / "
    "off-by-default feature (state only what currently operates). "
    "Remediation: strip the deferral mention, OR — if it is the rule "
    "self-reference, a live TD-deferral workflow line (a 'Deferred "
    "items' report section, a // TODO(scope): TD-TBD reference), or "
    "generic product advice — add a scripts/.docs-gate-allowlist.txt "
    "record with a reason:."
)
REMEDIATION_BLOAT = (
    "Operating-doc bullets stay terse. This '## Project rules' bullet "
    "exceeds the {cap}-character cap. Remediation: split or tighten it, "
    "OR — if it is an irreducible enumeration (e.g. a denied-git-verb "
    "list) — add a scripts/.docs-gate-allowlist.txt record with a "
    "reason:."
)
REMEDIATION_DANGLING = (
    "This file reference does not resolve in the project tree. "
    "Remediation: fix or remove the dead pointer, OR — if it points at "
    "a file that exists only after install / project use (a pack-shipped "
    "reference doc, a generated index, a project script) — add a "
    "scripts/.docs-gate-allowlist.txt `target:` record with a reason:."
)


def scan_doc(rel, root, by_doc, dangling_targets, basenames, relpaths):
    """Return list of failure strings for one doc."""
    fails = []
    path = os.path.join(root, rel)
    try:
        raw = open(path, encoding="utf-8").read()
    except OSError as e:
        return [f"{rel}: cannot read ({e})"]
    snippets = by_doc.get(rel, [])
    stripped = strip_blocks(raw)

    # AXIS: history
    for lineno, line in enumerate(stripped, 1):
        matched = [n for n, rx in HISTORY_PATTERNS if rx.search(line)]
        if not matched:
            continue
        if covered(line, snippets):
            continue
        fails.append(
            f"{rel}:{lineno} [history {matched}] {line.strip()[:90]}\n"
            f"    {REMEDIATION_HISTORY}")

    # AXIS: deferred
    for lineno, line in enumerate(stripped, 1):
        if not DEFERRED_PATTERN.search(line):
            continue
        if covered(line, snippets):
            continue
        fails.append(
            f"{rel}:{lineno} [deferred] {line.strip()[:90]}\n"
            f"    {REMEDIATION_DEFERRED}")

    # AXIS: bloat (trinity Project-rules bullets only)
    if rel in TRINITY:
        for lineno, count, preview in project_memory_bullets(raw.splitlines()):
            if count <= BLOAT_BULLET_CHAR_CAP:
                continue
            # a bullet is allowlisted iff a snippet is a substring of its head
            head = preview
            bullet_line = raw.splitlines()[lineno - 1]
            if covered(bullet_line, snippets):
                continue
            fails.append(
                f"{rel}:{lineno} [bloat] bullet is {count} chars (cap "
                f"{BLOAT_BULLET_CHAR_CAP}): {head}\n"
                f"    {REMEDIATION_BLOAT.format(cap=BLOAT_BULLET_CHAR_CAP)}")

    # AXIS: dangling
    for lineno, line in enumerate(stripped, 1):
        low = line.lower()
        refs = ([m.group(1) for m in DANGLING_BACKTICK.finditer(line)]
                + [m.group(1) for m in DANGLING_HYPERLINK.finditer(line)])
        for ref in refs:
            norm = ref.lstrip("./")
            base = os.path.basename(ref)
            if norm in relpaths or base in basenames:
                continue
            if norm in dangling_targets:
                continue
            if any(ph.search(ref) for ph in DANGLING_PLACEHOLDERS):
                continue
            if any(a in low for a in DANGLING_ANCHORS):
                continue
            fails.append(
                f"{rel}:{lineno} [dangling] `{ref}` does not resolve\n"
                f"    {REMEDIATION_DANGLING}")
    return fails


def run_scan(targets, root, by_doc, dangling_targets):
    basenames, relpaths = build_index(root)
    all_fails = []
    for rel in targets:
        all_fails.extend(
            scan_doc(rel, root, by_doc, dangling_targets,
                     basenames, relpaths))
    return all_fails


# ---------------------------------------------------------------------------
# AXIS: conformance — populated per-entry stream schema conformance (BD-206)
#
# The no-mirror flat-file model: docs/project/{backlog,implementation-plan,
# changelog}/ are per-entry trees (the SOLE source of truth), NOT regenerated
# from a monolith. This leg validates a POPULATED client project against the
# schema each stream declares in its own _rules.md — the SAME SSOT schema
# block the pack-side validate-pack.py Check 72 leg parses (Item-8: the schema
# is written once in _rules.md, the parser twice; the two validators cannot
# diverge on the schema, only the parser is re-implemented).
#
# Per stream this checks: (1) sanctioned sidecar vocabulary — no FORBIDDEN
# _format.md / _scaffolding.md sidecar, and the impl-plan stream admits
# _index.md; (2) NO reintroduced monolith mirror (BACKLOG.md /
# IMPLEMENTATION-PLAN.md / CHANGELOG.md); (3) per-entry conformance —
# form-family field grammar for backlog + implementation-plan, structured
# entry shape for changelog.
#
# Cheap (ci-check-runtime-compounding aware): parse each _rules.md schema
# ONCE per stream; a bounded os.scandir per stream; deterministic per-entry
# field scans — no subprocess, no whole-tree walk.
# ---------------------------------------------------------------------------

# Stream subdir -> (schema H2 header, monolith-mirror basename, admitted
# optional sidecars). FORBIDDEN sidecars + monoliths are global.
_CONF_PROJECT_DIR = "docs/project"
_CONF_STREAMS = (
    ("backlog",             "## Entry schema",    "BACKLOG.md",             ()),
    ("implementation-plan", "## Entry schema",    "IMPLEMENTATION-PLAN.md", ("_index.md",)),
    ("changelog",           "## Entry structure", "CHANGELOG.md",           ()),
    ("groupings",           "## Entry schema",    "GROUPINGS.md",           ()),
)
_CONF_FORBIDDEN_SIDECARS = ("_format.md", "_scaffolding.md")
_CONF_ENTRY_REGEX = {
    "backlog":             re.compile(r"^TD-\d+\.md$"),
    "implementation-plan": re.compile(r"^phase-\d+\.md$"),
    "changelog":           re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$"),
    # TIGHTENED per the stream contract's filename convention
    # (docs/project/groupings/_rules.md): exactly three digits zero-padded
    # through GRP-999, unpadded four-plus digits from GRP-1000 — GRP-0000
    # never matches (a mis-named entry, flagged stream-level).
    "groupings":           re.compile(r"^GRP-(\d{3}|[1-9]\d{3,})\.md$"),
}
_CONF_SIDECAR_RX = re.compile(r"^_.*\.md$")

REMEDIATION_CONFORMANCE = (
    "The per-entry stream must conform to the no-mirror flat-file schema "
    "declared in its _rules.md (the SOLE source of truth — no monolith "
    "mirror). Remediation: fix the offending entry / sidecar to match the "
    "stream's _rules.md schema block, OR — if the stream's contract has "
    "legitimately changed — update _rules.md (the SSOT) so both this gate "
    "and the pack-side validate-pack.py leg parse the new schema."
)


def _conf_parse_rules_section(text, header):
    """Parse a _rules.md schema block into a {key: tokens} map.

    Same grammar as the bash pe_supporting_files_admitted helper
    (scripts/lib/per-entry/_lib.sh) and the pack-side
    _check_72_parse_rules_section (scripts/validate-pack.py): inside the
    named `## <Section>` H2 block, each `- key: tokens` bullet contributes
    one entry; the block ends at the next `## ` line. Returns {} if the
    section is absent.
    """
    result = {}
    in_section = False
    for line in text.splitlines():
        if line.startswith(header):
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section and line.startswith("- ") and ":" in line:
            body = line[2:].strip()
            key, _, tokens = body.partition(":")
            result[key.strip()] = tokens.strip()
    return result


def _conf_parse_supporting(text):
    """Parse the `## Supporting files` section into a set of basenames.

    Bare `- basename` bullets (backticks optional), block ends at the next
    `## ` line. Mirrors the pack-side support-set parse + the bash
    pe_supporting_files_admitted grammar.
    """
    names = set()
    in_section = False
    for line in text.splitlines():
        if line.startswith("## Supporting files"):
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section and line.startswith("- "):
            names.add(line[2:].strip().strip("`"))
    return names


def _conf_schema_tokens(schema, key):
    """Whitespace-split a schema value's tokens, honoring "double-quoted"
    multi-word tokens (e.g. `marker-enum: TODO "KNOWN GAP" VERIFY`)."""
    raw = schema.get(key, "")
    return re.findall(r'"[^"]+"|\S+', raw)


def _conf_clean_token(tok):
    return tok.strip().strip('"')


def _conf_entry_field_present(body, field):
    """A form-family field is present if the entry carries a `**Field**:` or
    `Field:` labeled line, or an `- Field:` bullet (the gold uses bold
    labels; we tolerate the plain and bullet forms)."""
    # `Entry-Type` <-> `Entry Type`, `File/Symbol` etc. matched literally.
    esc = re.escape(field)
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + esc + r"\*{0,2}\s*:",
        re.MULTILINE)
    return rx.search(body) is not None


def _conf_field_value(body, field):
    """Return the trimmed value text of a `**Field**:`/`Field:` line, or ''."""
    esc = re.escape(field)
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + esc + r"\*{0,2}\s*:(.*)$",
        re.MULTILINE)
    m = rx.search(body)
    if not m:
        return ""
    return m.group(1).strip().strip("*").strip()


def _conf_check_backlog_entry(rel, body, schema):
    """Form-family conformance for one backlog TD entry (schema-driven)."""
    fails = []
    # Entry-Type present + == declared entry-type.
    want_type = (_conf_schema_tokens(schema, "entry-type") or [""])[0]
    want_type = _conf_clean_token(want_type)
    if not _conf_entry_field_present(body, "Entry-Type"):
        fails.append(f"{rel} [conformance] missing Entry-Type field")
    elif want_type:
        got = _conf_field_value(body, "Entry-Type").lower()
        if got and got != want_type.lower():
            fails.append(
                f"{rel} [conformance] Entry-Type '{got}' != schema "
                f"entry-type '{want_type}'")
    # Core fields present.
    for field in _conf_schema_tokens(schema, "core-fields"):
        field = _conf_clean_token(field)
        if field and not _conf_entry_field_present(body, field):
            fails.append(
                f"{rel} [conformance] missing core field '{field}'")
    # Marker ∈ marker-enum.
    marker_enum = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "marker-enum")]
    marker_val = _conf_field_value(body, "Marker")
    if marker_enum and marker_val and marker_val not in marker_enum:
        fails.append(
            f"{rel} [conformance] Marker '{marker_val}' not in "
            f"marker-enum {marker_enum}")
    # Status ∈ status-enum.
    status_enum = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "status-enum")]
    status_val = _conf_field_value(body, "Status")
    if status_enum and status_val and status_val not in status_enum:
        fails.append(
            f"{rel} [conformance] Status '{status_val}' not in "
            f"status-enum {status_enum}")
    # resolved-requires: Resolution present iff Status == Resolved.
    req = _conf_schema_tokens(schema, "resolved-requires")
    if req and status_val == "Resolved":
        req_field = _conf_clean_token(req[0])
        if req_field and not _conf_entry_field_present(body, req_field):
            fails.append(
                f"{rel} [conformance] Status=Resolved but '{req_field}' "
                f"field missing (resolved-requires)")
    return fails


# BD-206 O13 — the §3.5 GRACEFUL phase/part/task naming guard (a FORMAT check,
# not a structural migration). Phase-prefixed heading detectors (the trigger
# set) + the conforming templates they MUST match. Fixed inline-convention
# format (the same two regexes the pack-side validate-pack.py Check 75 applies —
# one rule, two parsers).
_CONF_IP_H3_PHASE_RE = re.compile(r"^### Phase-")
_CONF_IP_H4_PHASE_RE = re.compile(r"^#### Phase-")
_CONF_IP_H3_PART_OK_RE = re.compile(r"^### Phase-\d+\.Part-[a-z] — ")
_CONF_IP_H4_TASK_OK_RE = re.compile(r"^#### Phase-\d+\.Part-[a-z]\.Task-\d+ — ")


def _conf_ip_naming_violations(body):
    """Return the Phase-prefixed headings in `body` that VIOLATE the §3.5
    naming template (BD-206 O13). GRACEFUL: only Phase-prefixed
    (`### Phase-` / `#### Phase-`) headings are checked; epic-task
    `#### N.M — ` anchors + inline parts that are well-formed are tolerated
    (no fire). BD-185 (per-part-file migration) is OUT of scope."""
    bad = []
    for line in body.splitlines():
        if _CONF_IP_H3_PHASE_RE.match(line):
            if not _CONF_IP_H3_PART_OK_RE.match(line):
                bad.append(line.rstrip())
        elif _CONF_IP_H4_PHASE_RE.match(line):
            if not _CONF_IP_H4_TASK_OK_RE.match(line):
                bad.append(line.rstrip())
    return bad


def _conf_check_implplan_entry(rel, body, schema):
    """Form-family conformance for one impl-plan phase entry (schema-driven).

    phase-epic carries the declared epic field set; phase-part is lightweight
    (Entry-Type only) and is tolerated gracefully (BD-206; per-part richness
    is BD-185). PLUS the BD-206 O13 §3.5 GRACEFUL naming guard: any Phase-
    prefixed heading (`### Phase-…` / `#### Phase-…`) MUST match the part /
    part-task template; epic-task `#### N.M — ` anchors + inline parts are
    tolerated; no forced refactor (FORMAT check, not a structural migration).
    """
    fails = []
    # O13 naming guard runs for EVERY impl-plan entry (epic or part) — it
    # scans the body's Phase-prefixed headings regardless of Entry-Type.
    for heading in _conf_ip_naming_violations(body):
        fails.append(
            f"{rel} [conformance] phase heading violates the §3.5 naming "
            f"template: {heading!r}")
    entry_types = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "entry-types")]
    if not _conf_entry_field_present(body, "Entry-Type"):
        fails.append(f"{rel} [conformance] missing Entry-Type field")
        return fails
    got_type = _conf_field_value(body, "Entry-Type").lower()
    if entry_types and got_type and got_type not in [t.lower()
                                                     for t in entry_types]:
        fails.append(
            f"{rel} [conformance] Entry-Type '{got_type}' not in "
            f"entry-types {entry_types}")
    # phase-part is lightweight — Entry-Type only; nothing more to check.
    if got_type == "phase-part":
        return fails
    # phase-epic: the declared epic field set.
    for field in _conf_schema_tokens(schema, "phase-epic-fields"):
        field = _conf_clean_token(field)
        if field and not _conf_entry_field_present(body, field):
            fails.append(
                f"{rel} [conformance] phase-epic missing field '{field}'")
    status_enum = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "status-enum")]
    status_val = _conf_field_value(body, "Status")
    # Present-but-EMPTY Status on a phase-epic FAILs (the empty-Status
    # close): the enum guard below skips empty values and the
    # missing-field guard fires only on absence, so without this
    # predicate an empty value would be validation-green while every
    # derived reader (status rollups, target coherence) treats the phase
    # as unreadable. Schema-driven — fires only when the schema declares
    # a status-enum; epic-only by the phase-part early-return above.
    if (status_enum and not status_val
            and _conf_entry_field_present(body, "Status")):
        fails.append(
            f"{rel} [conformance] Status present but empty")
    if status_enum and status_val and status_val not in status_enum:
        fails.append(
            f"{rel} [conformance] Status '{status_val}' not in "
            f"status-enum {status_enum}")
    # Target ∈ target-enum. OPTIONAL on phase-epics: absent = no claim (no
    # check). Present ⇒ exactly ONE enum token, non-empty: present-but-empty
    # FAILs; an out-of-enum value (including a token with a trailing
    # comment) FAILs. Schema-driven — the tokens come from the contract's
    # `target-enum:` line (declaration order IS the ordinal scale); a schema
    # without a `target-enum:` key skips the check (lenient, the marker-enum
    # precedent). Epic-only by construction: the phase-part early-return
    # above precedes this guard.
    target_enum = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "target-enum")]
    if target_enum and _conf_entry_field_present(body, "Target"):
        target_val = _conf_field_value(body, "Target")
        if not target_val:
            fails.append(
                f"{rel} [conformance] Target present but empty")
        elif target_val not in target_enum:
            fails.append(
                f"{rel} [conformance] Target '{target_val}' not in "
                f"target-enum {target_enum}")
    return fails


# ---------------------------------------------------------------------------
# Groupings conformance (the populated-tree leg): the CLOSED byte-canonical
# entry grammar the stream contract (docs/project/groupings/_rules.md)
# declares — one grouping per file, fixed field order, exact-byte line
# grammar (exactly one space after each field colon; no trailing whitespace;
# no blank lines between fields; exact ", " member separator; single
# trailing newline), plus the reserved-GRP-000 branch (min-members and
# zero-members-FAIL exempt; EMPTY Member-phases value admitted; the
# exception field FORBIDDEN at any member count; Kind and title pinned).
# Schema-driven: entry-type / core-fields / kind-enum / exception-field /
# min-members / field-order / reserved-id come from the `## Entry schema`
# block — the same SSOT the pack-side validate-pack.py Check 84 leg asserts.
# Member resolution (dangling / part-typed), GRP-000 exclusivity, and
# toc-sync are STREAM-level (_conf_check_groupings_stream below).
# ---------------------------------------------------------------------------
_CONF_GRP_HEADER_RE = re.compile(r"^\*\*(GRP-\d+) — (.+)\*\*$")
_CONF_GRP_MEMBER_RE = re.compile(r"^phase-(\d+)$")
_CONF_GRP_FILE_RE = re.compile(r"^GRP-.*\.md$")
_CONF_GRP_TOC_ROW_RE = re.compile(r"(?m)^- (GRP-\d+) — ")
_CONF_GRP_RESERVED_TITLE = "Ungrouped (declared)"
_CONF_GRP_RESERVED_KIND = "unassigned"


def _conf_grp_members(value):
    """Member tokens from a Member-phases value under the EXACT ", "
    separator (no tolerant split — the byte grammar is closed). Returns
    (tokens, first-bad-token-or-None); an empty value returns ([], None)
    (legality of the empty value is the caller's reserved-branch call)."""
    if value == "":
        return [], None
    toks = value.split(", ")
    for tok in toks:
        if not _CONF_GRP_MEMBER_RE.match(tok):
            return toks, tok
    return toks, None


def _conf_check_grouping_entry(rel, body, schema):
    """Closed-grammar conformance for one grouping entry (schema-driven).

    Line-walk validation: line 1 the exact back-pointer comment, line 2
    the bold-pair header `**GRP-NNN — <Title>**`, then ONLY
    `Field: value` lines in the declared field-order — nothing else is
    admitted (no free prose, no blank lines, no duplicate fields).
    Reserved branch: the schema's reserved-id entry is exempt from
    min-members and zero-members-FAIL, admits an EMPTY Member-phases
    value, FORBIDS the exception field at any member count, and pins
    Kind + the header title.
    """
    fails = []

    def bad(msg):
        fails.append(f"{rel} [conformance] {msg}")

    name = rel.rsplit("/", 1)[-1]
    file_id = name[:-3]
    rel_dir = rel.rsplit("/", 1)[0]
    reserved = _conf_clean_token(
        (_conf_schema_tokens(schema, "reserved-id") or [""])[0])
    is_reserved = bool(reserved) and file_id == reserved

    # Whole-file byte discipline.
    if not body.endswith("\n"):
        bad("file must end with a single trailing newline")
    elif body.endswith("\n\n"):
        bad("file must end with a SINGLE trailing newline "
            "(trailing blank line present)")
    lines = body.splitlines()
    for i, line in enumerate(lines, start=1):
        if line != line.rstrip():
            bad(f"trailing whitespace on line {i}")

    # Line 1 — the exact back-pointer.
    want_back = (f"<!-- per-entry source: {rel}; "
                 f"contract: {rel_dir}/_rules.md -->")
    if not lines or lines[0].rstrip() != want_back:
        bad(f"line 1 must be the back-pointer comment '{want_back}'")

    # Line 2 — the bold-pair header.
    if len(lines) < 2:
        bad("line 2 must be the bold-pair header **GRP-NNN — <Title>**")
        return fails
    m = _CONF_GRP_HEADER_RE.match(lines[1])
    if not m:
        bad("line 2 must be the bold-pair header **GRP-NNN — <Title>** "
            "(exactly one space each side of the em-dash; no trailing "
            "whitespace)")
    else:
        head_id, title = m.group(1), m.group(2)
        if head_id != file_id:
            bad(f"header ID {head_id} != filename ID {file_id}")
        if not title.strip() or title != title.strip():
            bad("header title spacing non-canonical (exactly one space "
                "each side of the em-dash; the title carries no leading/"
                "trailing whitespace)")
        elif is_reserved and title != _CONF_GRP_RESERVED_TITLE:
            bad(f"{reserved} title is pinned — the header must read "
                f"'**{reserved} — {_CONF_GRP_RESERVED_TITLE}**'")

    # Field lines — the closed serialization walk.
    field_order = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "field-order")]
    optional = set(_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "optional-fields"))
    exception_field = _conf_clean_token(
        (_conf_schema_tokens(schema, "exception-field") or [""])[0])
    core = [_conf_clean_token(t)
            for t in _conf_schema_tokens(schema, "core-fields")]
    # ID lives in the filename/header; the other core fields plus
    # Entry-Type are required field LINES.
    required = ["Entry-Type"] + [f for f in core if f and f != "ID"]
    admitted = field_order or (required + sorted(optional))

    seen = []
    values = {}
    for i, line in enumerate(lines[2:], start=3):
        if line == "":
            bad(f"blank line at line {i} — no blank lines inside the "
                f"closed entry serialization")
            continue
        fname, sep, rest = line.partition(":")
        if not sep or fname not in admitted:
            bad(f"line {i} is not an admitted 'Field: value' line — no "
                f"free-floating prose (admitted fields: "
                f"{', '.join(admitted)})")
            continue
        if fname in seen:
            bad(f"duplicate field '{fname}'")
            continue
        seen.append(fname)
        if rest == "":
            value = ""
        elif rest.startswith(" ") and not rest.startswith("  "):
            value = rest[1:]
        else:
            bad(f"'{fname}:' must be followed by exactly one space "
                f"(line {i})")
            value = rest.strip()
        if value == "" and fname != "Member-phases":
            bad(f"field '{fname}' present but empty")
        values[fname] = value

    if field_order:
        pos = dict((f, i) for i, f in enumerate(field_order))
        idxs = [pos[f] for f in seen if f in pos]
        if idxs != sorted(idxs):
            bad("field order violates the declared field-order ("
                + " ".join(field_order) + ")")
    for f in required:
        if f and f not in seen:
            bad(f"missing core field '{f}'")

    # Entry-Type == the declared entry-type (byte-exact — the closed
    # serialization admits one spelling).
    want_type = _conf_clean_token(
        (_conf_schema_tokens(schema, "entry-type") or [""])[0])
    got_type = values.get("Entry-Type", "")
    if want_type and got_type and got_type != want_type:
        bad(f"Entry-Type '{got_type}' != schema entry-type '{want_type}'")

    # Kind ∈ kind-enum; pinned on the reserved entry.
    kind_enum = [_conf_clean_token(t)
                 for t in _conf_schema_tokens(schema, "kind-enum")]
    kind_val = values.get("Kind", "")
    if kind_enum and kind_val and kind_val not in kind_enum:
        bad(f"Kind '{kind_val}' not in kind-enum {kind_enum}")
    if is_reserved and kind_val and kind_val != _CONF_GRP_RESERVED_KIND:
        bad(f"{reserved} Kind is pinned to '{_CONF_GRP_RESERVED_KIND}'")

    # Member-phases grammar + the membership rules / reserved branch.
    if "Member-phases" in values:
        toks, badtok = _conf_grp_members(values["Member-phases"])
        if badtok is not None:
            bad(f"Member-phases token '{badtok}' is not a phase-N member "
                f"(members are PHASES only, exact ', ' separator — "
                f"parts / tasks / other entry IDs are not admitted)")
        else:
            nums = [int(t[6:]) for t in toks]
            if len(set(nums)) != len(nums):
                bad("duplicate member in Member-phases")
            elif nums != sorted(nums):
                bad("Member-phases must list members in canonical "
                    "ascending phase-number order")
            count = len(toks)
            has_exc = bool(exception_field) and exception_field in seen
            if is_reserved:
                if has_exc:
                    bad(f"'{exception_field}' is FORBIDDEN on {reserved} "
                        f"at any member count (the reserved "
                        f"declared-ungrouped ledger is not an "
                        f"exceptional grouping)")
            else:
                if count == 0:
                    bad("zero members — never valid on a real grouping "
                        "(dissolution = delete the file)")
                elif count == 1 and not has_exc:
                    bad(f"1 member without '{exception_field}' — the "
                        f"exception field is required if and only if "
                        f"the member count is 1")
                elif count >= 2 and has_exc:
                    bad(f"stale '{exception_field}' — present with "
                        f"{count} members (the field is admitted if "
                        f"and only if the member count is 1)")
    return fails


_CONF_CL_NARRATIVE_RE = re.compile(
    r"^\s*(?:[-*]\s*)?\*{0,2}(?:Summary|Scope)\*{0,2}\s*:(.*)$", re.MULTILINE)


def _conf_cl_caps(schema):
    """Read the integer caps (entry-max-lines, summary-max-words) from the
    parsed `## Entry structure` schema (NOT literals — the _rules.md SSOT
    governs). A cap absent / unparseable is None (that rule does not fire)."""
    def _int(key):
        tok = _conf_schema_tokens(schema, key)
        if not tok:
            return None
        try:
            return int(_conf_clean_token(tok[0]))
        except ValueError:
            return None
    return _int("entry-max-lines"), _int("summary-max-words")


def _conf_check_changelog_entry(rel, body, schema):
    """Structured (not form-family) conformance for one changelog entry.

    Reads the rule set FROM the `## Entry structure` schema SSOT (the SAME
    block the pack-side validate-pack.py Check 74 parses — one schema, two
    parsers, one rule set):
      (1) a NARRATIVE field is required for EVERY entry — `**Summary**:` OR
          `**Scope**:` (`narrative-fields`); it is the sole required field;
      (2) `entry-max-lines` cap; (3) `summary-max-words` cap (the word cap
          reads whichever narrative field is present).
    `Test count` and `Files` (any `**Files <verb>**:` label) are ADVISORY /
    admitted, not required. The H3 anchor + not-form-family guard remain.
    The caps are read from the schema, so a _rules.md cap edit reaches this
    leg without a code change. Deterministic line/word counts
    (ci-check-runtime-compounding aware).
    """
    fails = []
    has_h3 = re.search(r"(?m)^###\s+\d{4}-\d{2}-\d{2}\b", body) is not None
    if not has_h3:
        fails.append(
            f"{rel} [conformance] missing structured changelog H3 anchor "
            f"(### YYYY-MM-DD — …)")
    # A changelog entry is structured, NOT form-family: it must not carry an
    # Entry-Type/Marker form-family field (would mean a mis-filed entry).
    if _conf_entry_field_present(body, "Entry-Type"):
        fails.append(
            f"{rel} [conformance] changelog entry carries a form-family "
            f"Entry-Type field (changelog is structured, not form-family)")

    # O12 reconciled conformance — narrative required; Test count + Files advisory.
    narrative_labels = [_conf_clean_token(t)
                        for t in _conf_schema_tokens(schema, "narrative-fields")] \
                       or ["Summary", "Scope"]
    if not any(_conf_entry_field_present(body, lbl) for lbl in narrative_labels):
        fails.append(
            f"{rel} [conformance] missing narrative field "
            f"({' or '.join(narrative_labels)})")

    entry_max_lines, summary_max_words = _conf_cl_caps(schema)
    # (2) entry-max-lines.
    if entry_max_lines is not None:
        nl = len(body.splitlines())
        if nl > entry_max_lines:
            fails.append(
                f"{rel} [conformance] entry has {nl} lines > "
                f"entry-max-lines {entry_max_lines}")
    # (3) summary-max-words — measured on the narrative field (Summary or Scope).
    if summary_max_words is not None:
        m = _CONF_CL_NARRATIVE_RE.search(body)
        sw = len(m.group(1).split()) if m else 0
        if sw > summary_max_words:
            fails.append(
                f"{rel} [conformance] narrative has {sw} words > "
                f"summary-max-words {summary_max_words}")
    return fails


_CONF_ENTRY_CHECKERS = {
    "backlog":             _conf_check_backlog_entry,
    "implementation-plan": _conf_check_implplan_entry,
    "changelog":           _conf_check_changelog_entry,
    "groupings":           _conf_check_grouping_entry,
}


# ---------------------------------------------------------------------------
# `_index.md` MANDATORY validation (BD-206 O11 / G-3), client populated-tree
# leg. The impl-plan stream carries `_index.md` (the dependency-derived
# serial ordering); the backlog is unordered → no index. This leg enforces
# the TWO hard properties against the POPULATED client tree:
#   (1) hard-dependency-order consistency — the `_index.md` serial order is a
#       VALID topological order of the rule-based deps (from each phase's
#       Blockers / Unblocks / Dependencies / Prerequisite SSOT — the deps
#       stay SSOT in the entry files; `_index.md` is not a competing source);
#   (2) per-entry ↔ `_index.md` membership sync — the `_index.md` membership
#       matches the tree's phase-*.md files EXACTLY (no missing / extra —
#       analogous to the `_toc.md`-sync Check 33).
# The pack-side empty-template leg is validate-pack.py Check 73; the
# generator + shared validator are scripts/lib/per-entry/index-generate.sh.
# All three implement the same two properties (the deps parsed with the same
# form-family-bullet grammar). Cheap: deps already read from the populated
# entries; one extra small read of `_index.md`; no subprocess.
# ---------------------------------------------------------------------------
_CONF_INDEX_PHASE_RE = re.compile(r"^phase-(\d+)\.md$")
_CONF_INDEX_BULLET_RE = re.compile(r"^- \[phase-(\d+)\]")


def _conf_index_phase_refs(value):
    """Every phase-N number referenced in a field value (tolerates none /
    comma- / space- / and-separated lists)."""
    return set(re.findall(r"phase-(\d+)", value))


def _conf_index_edges(entries):
    """entries: {phase-num: body}. Returns (present, edges) — the set of
    (prereq, dependent) ordering constraints: Blockers/Dependencies/
    Prerequisite give prereq edges (prereq before this), Unblocks gives
    dependent edges (this before dependent). Self-edges + edges to absent
    phases dropped (membership-sync flags missing files separately)."""
    present = set(entries)
    edges = set()
    for num, body in entries.items():
        prereq = set()
        for fld in ("Blockers", "Dependencies", "Prerequisite"):
            prereq |= _conf_index_phase_refs(_conf_field_value(body, fld))
        dep = _conf_index_phase_refs(_conf_field_value(body, "Unblocks"))
        for b in prereq:
            if b in present and b != num:
                edges.add((b, num))
        for u in dep:
            if u in present and u != num:
                edges.add((num, u))
    return present, edges


def _conf_index_toposort(present, edges):
    """Deterministic Kahn sort (ties by ascending phase number). Returns
    (order, acyclic)."""
    indeg = dict((p, 0) for p in present)
    adj = dict((p, []) for p in present)
    for (a, b) in edges:
        adj[a].append(b)
        indeg[b] += 1
    ready = sorted((p for p in present if indeg[p] == 0), key=int)
    order = []
    while ready:
        n = ready.pop(0)
        order.append(n)
        for m in sorted(adj[n], key=int):
            indeg[m] -= 1
            if indeg[m] == 0:
                ready.append(m)
        ready.sort(key=int)
    if len(order) < len(present):
        order.extend(sorted((p for p in present if p not in set(order)),
                            key=int))
        return order, False
    return order, True


def _conf_index_parse_order(text):
    """Ordered phase-number list from an `_index.md` `## Serial order`
    block, in file order ([] if absent)."""
    order = []
    in_section = False
    for line in text.splitlines():
        if line.startswith("## Serial order"):
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section:
            m = _CONF_INDEX_BULLET_RE.match(line)
            if m:
                order.append(m.group(1))
    return order


def _conf_scc_ids(nodes, edge_set):
    """Kosaraju strongly-connected-component ids over (nodes, edge_set):
    returns {node: component-id}. Iterative (no recursion), O(V+E)."""
    adj = dict((n, []) for n in nodes)
    radj = dict((n, []) for n in nodes)
    for (a, b) in edge_set:
        adj[a].append(b)
        radj[b].append(a)
    order = []
    seen = set()
    for root in sorted(nodes, key=int):
        if root in seen:
            continue
        seen.add(root)
        stack = [(root, iter(adj[root]))]
        while stack:
            node, it = stack[-1]
            advanced = False
            for s in it:
                if s not in seen:
                    seen.add(s)
                    stack.append((s, iter(adj[s])))
                    advanced = True
                    break
            if not advanced:
                order.append(node)
                stack.pop()
    comp = {}
    cid = 0
    for node in reversed(order):
        if node in comp:
            continue
        comp[node] = cid
        queue = [node]
        while queue:
            n = queue.pop()
            for s in radj[n]:
                if s not in comp:
                    comp[s] = cid
                    queue.append(s)
        cid += 1
    return comp


def _conf_check_target_coherence(rel_dir, entries, present, edges, schema):
    """Target-coherence gate (FAIL, not WARN): a declared `Target:` must not
    exceed the bound provable from dependency edges and other phases'
    declared targets — the impl-plan `_rules.md` `## Target semantics`
    contract. Rides the structures `_conf_check_index` already collected;
    runs whenever phase entries exist and the schema declares `target-enum`
    (else lenient no-op), even when `_index.md` is missing or unreadable.

    Closed form (the pair semantics — a poisoned/garbled region NEVER
    silences an independently provable conflict; the suppressed bounds are
    exactly the UNPROVABLE ones):
      - Ordinals: the schema's `target-enum` declaration order IS the scale.
        The literal token `future-unassigned` is non-constraining: it
        contributes no bound as a dependent but transmits bounds and
        conflicts as a declarer.
      - ABSORBING = Status in {done, superseded} (spent claims: they neither
        contribute, transmit, nor receive bounds). LIVE = non-absorbing;
        the live subgraph = the LIVE-induced edge set.
      - LEGIBLE = live phases whose Status parses to the schema status-enum.
        An unreadable Status (a garbled value, an empty value, or an
        unreadable entry file) is a poison source: its declared atom and
        every path through it are excluded from the provable bound (it may
        resolve to an absorbing state, which would evaporate both). A
        present-but-EMPTY `Status:` is itself a Status-leg FAIL (the
        empty-Status predicate in _conf_check_implplan_entry) AND stays a
        poison source here — its exclusion from the provable bound is
        independent of that red.
      - A present-but-illegal `Target:` is a poison source with NO atom,
        but the phase still transmits (a target garble never deletes an
        edge; its own enum FAIL is already red).
      - ROBUST graph R = the LEGIBLE-induced live subgraph MINUS its
        intra-SCC edges (any live-cycle edge may be the one a cycle fix
        deletes — a bound witnessed only through one is not provable).
        R is a DAG.
      - atom(D) = ordinal(declared(D)) iff `Target:` is present + legal +
        constraining (ordinal below `future-unassigned`); else UNDEFINED.
      - known(P) = min over direct R-successors D of contrib(D), where
        contrib(D) = min(atom(D), known(D)) over the DEFINED operands only:
        an undefined operand contributes NO constraint, and a D with
        neither defined drops out of the min entirely. known(P) is defined
        iff >= 1 direct R-successor contributes. Edge orientation:
        (a, b) = a-must-precede-b, so P's R-successors are its DEPENDENTS —
        bounds flow dependents -> blockers.
      - CONFLICT(P), for every LIVE LEGIBLE P with a present LEGAL declared
        target: known(P) defined AND ordinal(declared(P)) > known(P).
        Both classes FAIL identically; the class is a witness-chain
        property: DIRECT iff the chain has length 1 and the bound equals
        the witness's own declared atom, else TRANSITIVE (the full chain
        rides in the message). Witness = the arg-min direct R-successor,
        ties -> lowest phase number.
    Phase-part entries carry no independent target (containment
    inheritance): their `Target:` is ignored here. Runtime: set passes +
    one SCC pass + one Kahn toposort of R — O(V+E), once per gate run,
    inside the existing conformance pass; no re-read, no subprocess."""
    target_enum = [_conf_clean_token(t)
                   for t in _conf_schema_tokens(schema, "target-enum")]
    if not entries or not target_enum:
        return []
    status_enum = set(_conf_clean_token(t)
                      for t in _conf_schema_tokens(schema, "status-enum"))
    ordinal = dict((tok, i) for i, tok in enumerate(target_enum))
    fu_ord = ordinal.get("future-unassigned", len(target_enum))

    status = {}
    declared = {}   # phase -> legal declared token (epics only)
    for num, body in entries.items():
        status[num] = _conf_field_value(body, "Status")
        if _conf_field_value(body, "Entry-Type").lower() == "phase-part":
            continue  # parts inherit by containment — no independent target
        if _conf_entry_field_present(body, "Target"):
            val = _conf_field_value(body, "Target")
            if val in ordinal:
                declared[num] = val
            # illegal / empty -> no atom (the enum leg already FAILs it)

    absorbing = set(n for n in present
                    if status.get(n, "") in ("done", "superseded"))
    live = present - absorbing
    legible = set(n for n in live if status.get(n, "") in status_enum)
    r0 = set((a, b) for (a, b) in edges
             if a in legible and b in legible)
    comp = _conf_scc_ids(legible, r0)
    r = set((a, b) for (a, b) in r0 if comp[a] != comp[b])

    atom = {}
    for n, tok in declared.items():
        if ordinal[tok] < fu_ord:
            atom[n] = ordinal[tok]

    adj_r = dict((n, []) for n in legible)
    for (a, b) in r:
        adj_r[a].append(b)
    order, _acyclic = _conf_index_toposort(legible, r)
    known = {}
    witness = {}
    for node in reversed(order):
        best = None
        best_w = None
        for d in sorted(adj_r[node], key=int):
            a_d = atom.get(d)
            k_d = known.get(d)
            if a_d is not None and (k_d is None or a_d <= k_d):
                c = a_d
            elif k_d is not None:
                c = k_d
            else:
                continue  # neither defined — drops out of the min
            if best is None or c < best:
                best = c
                best_w = d
        if best is not None:
            known[node] = best
            witness[node] = best_w

    fails = []
    for p in sorted(legible & set(declared), key=int):
        kp = known.get(p)
        if kp is None or ordinal[declared[p]] <= kp:
            continue
        # Reconstruct the witness chain down to the atom realizing the bound.
        chain = []
        node = p
        while True:
            d = witness[node]
            chain.append(d)
            if atom.get(d) == kp:
                break  # the witness's own declared atom IS the bound
            node = d
        bound_tok = target_enum[kp]
        via = " → ".join("phase-" + c for c in chain)
        fails.append(
            f"{rel_dir}/phase-{p}.md [conformance] target conflict — "
            f"declared {declared[p]} exceeds provable dependency bound "
            f"{bound_tok} (via {via}, declared {bound_tok})"
            f"\n    {REMEDIATION_CONFORMANCE}")
    return fails


def _conf_check_index(rel_dir, stream_dir, names, schema):
    """The two-property `_index.md` validator for the populated impl-plan
    tree, plus the target-coherence gate over the same collected entries.
    rel_dir is the stream's repo-relative dir; stream_dir its abspath;
    names the file basenames in it; schema the parsed `## Entry schema`
    block. Returns a list of failure strings."""
    fails = []
    entries = {}
    for name in names:
        m = _CONF_INDEX_PHASE_RE.match(name)
        if not m:
            continue
        try:
            entries[m.group(1)] = open(
                os.path.join(stream_dir, name), encoding="utf-8").read()
        except OSError:
            entries[m.group(1)] = ""
    present, edges = _conf_index_edges(entries)
    # Target coherence runs off the collected entries/edges BEFORE the
    # `_index.md` early-returns — a populated tree with a missing or
    # unreadable `_index.md` still gets coherence-checked.
    fails.extend(_conf_check_target_coherence(
        rel_dir, entries, present, edges, schema))
    index_path = os.path.join(stream_dir, "_index.md")
    index_text = None
    if os.path.isfile(index_path):
        try:
            index_text = open(index_path, encoding="utf-8").read()
        except OSError as e:
            fails.append(f"{rel_dir}/_index.md [conformance] unreadable ({e})")
            return fails

    if not present:
        # No phase entries — an `_index.md`, if present, must list nothing.
        if index_text is not None:
            listed = _conf_index_parse_order(index_text)
            if listed:
                fails.append(
                    f"{rel_dir}/_index.md [conformance] lists phases "
                    f"{['phase-' + n for n in sorted(set(listed), key=int)]} "
                    f"but the tree has no phase-*.md entries (membership drift)"
                    f"\n    {REMEDIATION_CONFORMANCE}")
        return fails

    if index_text is None:
        fails.append(
            f"{rel_dir}/_index.md [conformance] missing — the impl-plan "
            f"stream has {len(present)} phase entry/entries but no _index.md "
            f"ordering (regenerate _index.md per the "
            f"docs/project/implementation-plan/_rules.md Ordering section)"
            f"\n    {REMEDIATION_CONFORMANCE}")
        return fails

    listed = _conf_index_parse_order(index_text)
    listed_set = set(listed)
    # (2) membership sync.
    missing = sorted(present - listed_set, key=int)
    extra = sorted(listed_set - present, key=int)
    if missing:
        fails.append(
            f"{rel_dir}/_index.md [conformance] missing phase(s) "
            f"{['phase-' + n for n in missing]} (membership drift)"
            f"\n    {REMEDIATION_CONFORMANCE}")
    if extra:
        fails.append(
            f"{rel_dir}/_index.md [conformance] lists phase(s) "
            f"{['phase-' + n for n in extra]} with no phase-*.md file "
            f"(membership drift)\n    {REMEDIATION_CONFORMANCE}")
    if len(listed) != len(listed_set):
        fails.append(
            f"{rel_dir}/_index.md [conformance] duplicate phase listing"
            f"\n    {REMEDIATION_CONFORMANCE}")
    # (1) hard-dependency-order consistency.
    pos = dict((n, i) for i, n in enumerate(listed))
    for (a, b) in sorted(edges):
        if a in pos and b in pos and pos[a] >= pos[b]:
            fails.append(
                f"{rel_dir}/_index.md [conformance] hard-dependency "
                f"violated: phase-{a} must precede phase-{b} but _index.md "
                f"lists phase-{b} first\n    {REMEDIATION_CONFORMANCE}")
    _order, acyclic = _conf_index_toposort(present, edges)
    if not acyclic:
        fails.append(
            f"{rel_dir}/_index.md [conformance] dependency cycle — no valid "
            f"topological order exists\n    {REMEDIATION_CONFORMANCE}")
    return fails


def _conf_check_groupings_stream(rel_dir, stream_dir, names, schema, base):
    """Stream-level groupings legs (data one entry alone cannot see):

      - mis-named GRP-* files: under the tightened numbering a
        GRP-prefixed file that fails the entry regex (e.g. GRP-0000.md)
        is a mis-named ENTRY, not an out-of-scope file — FAIL, not SKIP;
      - member resolution: every well-formed member token resolves to a
        docs/project/implementation-plan/phase-N.md entry (dangling
        FAILs) that is NOT phase-part-typed (parts inherit membership by
        containment — the member must be the parent phase);
      - reserved-entry exclusivity: a phase declared ungrouped (a member
        of the schema's reserved-id entry) that is also a member of any
        real grouping is a contradiction — FAIL naming the phase + both
        files;
      - toc-sync (ID-set equality, the groupings stream only): every
        entry appears in _toc.md and every _toc.md row resolves to an
        entry. NOT byte-exact (row format is the contract's Write
        authority spec); the stream's _toc.md is its SOLE readable index
        — strict from birth.

    Cheap (ci-check-runtime-compounding): rides the file list already
    scanned; one bounded read per entry + one per UNIQUE referenced
    phase + one _toc.md read; no subprocess, no tree walk.
    """
    fails = []
    entry_rx = _CONF_ENTRY_REGEX["groupings"]
    reserved = _conf_clean_token(
        (_conf_schema_tokens(schema, "reserved-id") or [""])[0])

    members = {}   # grouping id -> [phase-num, ...] (well-formed tokens)
    for name in sorted(names):
        if _CONF_SIDECAR_RX.match(name):
            continue
        if not entry_rx.match(name):
            if _CONF_GRP_FILE_RE.match(name):
                fails.append(
                    f"{rel_dir}/{name} [conformance] mis-named grouping "
                    f"entry — filenames are GRP-NNN.md: exactly three "
                    f"digits zero-padded through GRP-999, unpadded from "
                    f"GRP-1000 (no extra zeros, no re-padding)"
                    f"\n    {REMEDIATION_CONFORMANCE}")
            continue
        gid = name[:-3]
        try:
            body = open(os.path.join(stream_dir, name),
                        encoding="utf-8").read()
        except OSError:
            continue  # unreadable — already FAILed in the per-entry loop
        toks, _bad = _conf_grp_members(
            _conf_field_value(body, "Member-phases"))
        members[gid] = [t[6:] for t in toks
                        if _CONF_GRP_MEMBER_RE.match(t)]

    # Member resolution — dangling + part-typed (containment). One read
    # per UNIQUE referenced phase, cached across groupings.
    ip_dir = os.path.join(base, "implementation-plan")
    ip_rel = f"{_CONF_PROJECT_DIR}/implementation-plan"
    resolution = {}
    for gid in sorted(members):
        for num in members[gid]:
            if num not in resolution:
                p = os.path.join(ip_dir, f"phase-{num}.md")
                if not os.path.isfile(p):
                    resolution[num] = "dangling"
                else:
                    try:
                        pb = open(p, encoding="utf-8").read()
                    except OSError:
                        pb = ""
                    et = _conf_field_value(pb, "Entry-Type").lower()
                    resolution[num] = ("part" if et == "phase-part"
                                       else "ok")
            state = resolution[num]
            if state == "dangling":
                fails.append(
                    f"{rel_dir}/{gid}.md [conformance] dangling member "
                    f"ref phase-{num} — no {ip_rel}/phase-{num}.md entry"
                    f"\n    {REMEDIATION_CONFORMANCE}")
            elif state == "part":
                fails.append(
                    f"{rel_dir}/{gid}.md [conformance] member phase-{num} "
                    f"resolves to a phase-part entry "
                    f"({ip_rel}/phase-{num}.md) — parts inherit "
                    f"membership by containment; list the parent phase "
                    f"instead\n    {REMEDIATION_CONFORMANCE}")

    # Reserved-entry exclusivity: members(reserved) ∩ members(any real
    # grouping) must be empty.
    if reserved and reserved in members:
        res_set = set(members[reserved])
        for gid in sorted(g for g in members if g != reserved):
            for num in members[gid]:
                if num in res_set:
                    fails.append(
                        f"{rel_dir}/{reserved}.md [conformance] "
                        f"exclusivity violation — phase-{num} is "
                        f"declared ungrouped in {rel_dir}/{reserved}.md "
                        f"AND is a member of {rel_dir}/{gid}.md "
                        f"({reserved} membership asserts membership in "
                        f"nothing)\n    {REMEDIATION_CONFORMANCE}")

    # toc-sync — ID-set equality between the tree and _toc.md.
    toc_path = os.path.join(stream_dir, "_toc.md")
    tree_ids = set(members)
    if not os.path.isfile(toc_path):
        if tree_ids:
            fails.append(
                f"{rel_dir}/_toc.md [conformance] missing — the "
                f"groupings stream has {len(tree_ids)} entry/entries "
                f"but no _toc.md index (regenerate _toc.md per the "
                f"{rel_dir}/_rules.md Write authority section)"
                f"\n    {REMEDIATION_CONFORMANCE}")
        return fails
    try:
        toc_text = open(toc_path, encoding="utf-8").read()
    except OSError as e:
        fails.append(f"{rel_dir}/_toc.md [conformance] unreadable ({e})")
        return fails
    toc_ids = set(_CONF_GRP_TOC_ROW_RE.findall(toc_text))
    for gid in sorted(tree_ids - toc_ids):
        fails.append(
            f"{rel_dir}/_toc.md [conformance] missing entry {gid} "
            f"(toc-sync: every {rel_dir}/GRP-NNN.md appears in _toc.md)"
            f"\n    {REMEDIATION_CONFORMANCE}")
    for gid in sorted(toc_ids - tree_ids):
        fails.append(
            f"{rel_dir}/_toc.md [conformance] lists {gid} with no "
            f"{gid}.md entry file (toc-sync)"
            f"\n    {REMEDIATION_CONFORMANCE}")
    return fails


def run_conformance(root):
    """Validate the POPULATED per-entry streams against their _rules.md schema.

    Returns a list of failure strings. Lenient when a stream directory is
    absent (a bare template / partial install is not a conformance violation)
    and when a stream has no _rules.md (pre-v11 client — nothing to parse).
    """
    fails = []
    base = os.path.join(root, _CONF_PROJECT_DIR)
    if not os.path.isdir(base):
        return fails  # no project tree — nothing to validate (lenient)

    for subdir, schema_header, monolith, admitted in _CONF_STREAMS:
        stream_dir = os.path.join(base, subdir)
        rel_dir = f"{_CONF_PROJECT_DIR}/{subdir}"
        if not os.path.isdir(stream_dir):
            continue  # stream absent — lenient

        try:
            names = [e.name for e in os.scandir(stream_dir) if e.is_file()]
        except OSError as e:
            fails.append(f"{rel_dir} [conformance] cannot scan ({e})")
            continue

        # (1) No reintroduced monolith mirror (at the stream dir or parent).
        for cand in (os.path.join(base, monolith),
                     os.path.join(stream_dir, monolith)):
            if os.path.isfile(cand):
                relm = os.path.relpath(cand, root)
                fails.append(
                    f"{relm} [conformance] FORBIDDEN monolith mirror present "
                    f"(no-mirror flat-file model — the per-entry tree is the "
                    f"SOLE source of truth)\n    {REMEDIATION_CONFORMANCE}")

        # (2) Sanctioned sidecar vocabulary — no forbidden sidecar present.
        for forbidden in _CONF_FORBIDDEN_SIDECARS:
            if forbidden in names:
                fails.append(
                    f"{rel_dir}/{forbidden} [conformance] FORBIDDEN sidecar "
                    f"present (sanctioned vocabulary: _rules.md / _intro.md / "
                    f"_toc.md"
                    + "".join(f" / {s}" for s in admitted) + ")\n"
                    f"    {REMEDIATION_CONFORMANCE}")

        # Parse the stream's _rules.md schema ONCE (Item-8 SSOT).
        rules_path = os.path.join(stream_dir, "_rules.md")
        if not os.path.isfile(rules_path):
            continue  # pre-v11 / no contract — lenient
        try:
            rules_text = open(rules_path, encoding="utf-8").read()
        except OSError as e:
            fails.append(f"{rel_dir}/_rules.md [conformance] unreadable ({e})")
            continue

        # _rules.md Supporting-files must not list a forbidden sidecar AND
        # must admit the stream's optional sidecars (e.g. impl-plan _index.md).
        support = _conf_parse_supporting(rules_text)
        for forbidden in _CONF_FORBIDDEN_SIDECARS:
            if forbidden in support:
                fails.append(
                    f"{rel_dir}/_rules.md [conformance] Supporting files lists "
                    f"FORBIDDEN sidecar {forbidden}\n"
                    f"    {REMEDIATION_CONFORMANCE}")
        for sidecar in admitted:
            if sidecar not in support:
                fails.append(
                    f"{rel_dir}/_rules.md [conformance] Supporting files must "
                    f"admit {sidecar} for this stream\n"
                    f"    {REMEDIATION_CONFORMANCE}")

        schema = _conf_parse_rules_section(rules_text, schema_header)
        if not schema:
            fails.append(
                f"{rel_dir}/_rules.md [conformance] missing or empty schema "
                f"block ({schema_header})\n    {REMEDIATION_CONFORMANCE}")
            # Without a schema we cannot field-check entries; report + move on.
            continue

        # (3) Per-entry conformance — only files matching the entry regex.
        entry_rx = _CONF_ENTRY_REGEX[subdir]
        checker = _CONF_ENTRY_CHECKERS[subdir]
        for name in sorted(names):
            # Skip sidecars (anything _-prefixed) and non-entry files.
            if _CONF_SIDECAR_RX.match(name):
                continue
            if not entry_rx.match(name):
                continue  # SKIP: not-entry, not-sidecar → out of scope
            entry_path = os.path.join(stream_dir, name)
            rel_entry = f"{rel_dir}/{name}"
            try:
                body = open(entry_path, encoding="utf-8").read()
            except OSError as e:
                fails.append(
                    f"{rel_entry} [conformance] unreadable ({e})")
                continue
            for f in checker(rel_entry, body, schema):
                # Attach the shared remediation if the checker did not.
                fails.append(f if "\n" in f
                             else f + f"\n    {REMEDIATION_CONFORMANCE}")

        # (4) `_index.md` MANDATORY validation (BD-206 O11) — impl-plan only
        #     (the backlog is unordered → no index). The two hard properties:
        #     topological-order consistency + per-entry↔_index.md membership
        #     sync. The deps are parsed from the populated phase entries (SSOT).
        if subdir == "implementation-plan":
            fails.extend(_conf_check_index(rel_dir, stream_dir, names,
                                           schema))

        # (5) Groupings stream-level legs (mis-named GRP files, member
        #     resolution incl. the part-typed close, reserved-entry
        #     exclusivity, toc-sync) — groupings only.
        if subdir == "groupings":
            fails.extend(_conf_check_groupings_stream(
                rel_dir, stream_dir, names, schema, base))
    return fails


# ---------------------------------------------------------------------------
# AXIS: session-state — PM-Chat resume-snapshot struct + grammar
#
# docs/project/pm-session-state.json is the committed, runtime-authored
# PM-Chat resume snapshot: the current live-orchestration frontier (active
# phase/TD work + sub-step, in-flight agents, queue order, parallelization
# mode, wave, pending decisions, cycle position, boundary commit,
# checkpoint), overwritten on every state transition — current-snapshot-
# ONLY, never appended. It does not ship in the bare template (no live
# session at install), so this leg SKIPs leniently when the file is absent
# and validates it when present:
#   - struct  — parses as a JSON object; the required key set is present;
#               boundary_commit is a 7-40-char lowercase-hex commit SHA;
#               checkpoint is an ISO-8601 timestamp.
#   - grammar — anti-accretion: PERMITS bare TD-N tags + exactly one date
#               (only in checkpoint) + exactly one SHA (only in
#               boundary_commit); FORBIDS a 2nd date/SHA, any off-field
#               date/SHA, history/narration shapes, and serialized size
#               over the byte cap (a snapshot that grows is accreting).
#
# Cheap (one bounded file): one isfile + one read + one json parse + regex
# scans over a byte-capped object — no tree walk, no subprocess.
# ---------------------------------------------------------------------------
_SS_FILE = "docs/project/pm-session-state.json"
_SS_REQUIRED_KEYS = (
    "schema",            # "pm-session-state/1"
    "boundary_commit",   # last commit SHA — the durable resume boundary
    "checkpoint",        # ISO-8601 timestamp — the ONE permitted date
    "active",            # in-flight phase/TD work + sub-step
    "in_flight_agents",  # agents to re-spawn on resume
    "queue",             # queued work + user-decided order
    "parallelization",   # "serial" | "parallel"
    "wave",              # current parallel wave
    "pending_decisions", # decisions needed to resume
    "cycle_position",    # in-commit review/fix cycle position
)
_SS_SHA_KEY = "boundary_commit"
_SS_DATE_KEY = "checkpoint"
_SS_SHA_RE = re.compile(r"\b[0-9a-f]{7,40}\b")
_SS_SHA_FULL_RE = re.compile(r"^[0-9a-f]{7,40}$")
_SS_DATE_RE = re.compile(r"20\d\d-\d\d-\d\d")
_SS_ISO_RE = re.compile(
    r"^20\d\d-\d\d-\d\d([T ]\d\d:\d\d(:\d\d)?(\.\d+)?(Z|[+-]\d\d:?\d\d)?)?$")
# Bare TD-N tags are PERMITTED (legitimate state — the point of the
# snapshot). Stripped before the narration scan so a legal "TD-42" value
# never trips a narration pattern on its own.
_SS_TD_TAG_RE = re.compile(r"TD-\d+")
# The accretion / narration FAIL set (history shapes in project vocabulary
# — TD-, phases). Matched against the snapshot's string values after bare
# TD-tags are stripped (td-past-action and per-td scan the ORIGINAL value —
# they need the TD-N; the strip protects bare TD-tags from every other
# pattern).
_SS_NARRATION_PATTERNS = (
    ("td-past-action", re.compile(
        r"TD-\d+\s+(deleted|added|renamed|introduced|removed|created|"
        r"retired|broadened|landed|did)")),
    ("per-td", re.compile(r"per TD-\d+")),
    ("carry-over", re.compile(r"carried from|carry-over|carryover", re.I)),
    ("user-locked", re.compile(r"User-locked", re.I)),
    ("incident", re.compile(r"\bincident\b", re.I)),
    ("commit-n", re.compile(r"Commit [0-9]")),
    ("override-n", re.compile(r"Override [0-9]")),
    ("post-commit", re.compile(r"post-Commit")),
    ("pre-date", re.compile(r"pre-20\d\d")),
    ("lessons-marker", re.compile(r"\b(LESSONS|lessons)\b")),
    ("update-marker", re.compile(r"\bUPDATE-\d")),
)
# Anti-growth backstop byte cap: a true current-frontier snapshot is small
# + bounded; growth over time is accretion.
_SS_BYTE_CAP = 4096

REMEDIATION_SESSION_STATE = (
    "docs/project/pm-session-state.json is the PM-Chat resume snapshot: "
    "current STATE only (bare TD-tags OK), one checkpoint date, one "
    "boundary SHA, overwritten on every state transition. Remediation: "
    "fix the named field, and move history (dated notes, lessons, "
    "past-action narration) to a backlog / changelog entry — never the "
    "snapshot."
)


def _ss_iter_string_values(obj):
    """Yield every STRING value nested in the parsed snapshot (dict values
    + list items; keys are structure, not state)."""
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from _ss_iter_string_values(v)
    elif isinstance(obj, (list, tuple)):
        for v in obj:
            yield from _ss_iter_string_values(v)


def run_session_state(root):
    """Validate the PM-Chat resume snapshot when present (struct + grammar).

    Returns a list of failure strings. SKIP-lenient when the snapshot is
    absent — the bare template and every fresh install lack it (it is
    runtime-authored by the PM chat), so absence is never a violation.
    """
    fails = []
    path = os.path.join(root, _SS_FILE)
    if not os.path.isfile(path):
        return fails  # absent — lenient (runtime-authored artifact)
    try:
        raw = open(path, encoding="utf-8").read()
    except OSError as e:
        fails.append(f"{_SS_FILE} [session-state] cannot read ({e})\n"
                     f"    {REMEDIATION_SESSION_STATE}")
        return fails

    # -- struct: valid JSON object.
    try:
        data = json.loads(raw)
    except ValueError as e:
        fails.append(
            f"{_SS_FILE} [session-state] INVALID JSON ({e}) — the snapshot "
            f"must parse deterministically for the PM chat to resume from "
            f"it\n    {REMEDIATION_SESSION_STATE}")
        return fails
    if not isinstance(data, dict):
        fails.append(
            f"{_SS_FILE} [session-state] top-level JSON must be an OBJECT "
            f"(got {type(data).__name__})\n    {REMEDIATION_SESSION_STATE}")
        return fails

    # -- struct: required key set + the two structural field shapes.
    missing = sorted(set(_SS_REQUIRED_KEYS) - set(data.keys()))
    if missing:
        fails.append(
            f"{_SS_FILE} [session-state] missing required key(s): {missing} "
            f"(required set: {list(_SS_REQUIRED_KEYS)})\n"
            f"    {REMEDIATION_SESSION_STATE}")
    bc = data.get(_SS_SHA_KEY)
    if _SS_SHA_KEY in data and (
            not isinstance(bc, str) or not _SS_SHA_FULL_RE.match(bc)):
        fails.append(
            f"{_SS_FILE} [session-state] {_SS_SHA_KEY} must be a 7-40-char "
            f"lowercase-hex commit SHA (got {bc!r}) — the single durable "
            f"resume boundary\n    {REMEDIATION_SESSION_STATE}")
    cp = data.get(_SS_DATE_KEY)
    if _SS_DATE_KEY in data and (
            not isinstance(cp, str) or not _SS_ISO_RE.match(cp)):
        fails.append(
            f"{_SS_FILE} [session-state] {_SS_DATE_KEY} must be an ISO-8601 "
            f"timestamp (got {cp!r}) — the single permitted date\n"
            f"    {REMEDIATION_SESSION_STATE}")

    # -- grammar: anti-accretion bounds over the snapshot's string values.
    sha_field_values = list(_ss_iter_string_values(data.get(_SS_SHA_KEY)))
    date_field_values = list(_ss_iter_string_values(data.get(_SS_DATE_KEY)))
    all_values = list(_ss_iter_string_values(data))

    # Dates: at most one, only in checkpoint.
    total_dates = sum(len(_SS_DATE_RE.findall(v)) for v in all_values)
    in_field_dates = sum(
        len(_SS_DATE_RE.findall(v)) for v in date_field_values)
    off_field_dates = total_dates - in_field_dates
    if total_dates > 1:
        fails.append(
            f"{_SS_FILE} [session-state] ACCRETION: {total_dates} date(s) "
            f"(20YY-MM-DD) — the snapshot permits exactly ONE, only in "
            f"{_SS_DATE_KEY} (a 2nd dated note is a history stack)\n"
            f"    {REMEDIATION_SESSION_STATE}")
    if off_field_dates > 0:
        fails.append(
            f"{_SS_FILE} [session-state] ACCRETION: a date appears OUTSIDE "
            f"{_SS_DATE_KEY} ({off_field_dates} off-field) — the single "
            f"checkpoint date lives ONLY in {_SS_DATE_KEY}\n"
            f"    {REMEDIATION_SESSION_STATE}")

    # SHAs: at most one, only in boundary_commit.
    total_shas = sum(len(_SS_SHA_RE.findall(v)) for v in all_values)
    in_field_shas = sum(
        len(_SS_SHA_RE.findall(v)) for v in sha_field_values)
    off_field_shas = total_shas - in_field_shas
    if total_shas > 1:
        fails.append(
            f"{_SS_FILE} [session-state] ACCRETION: {total_shas} commit "
            f"SHA(s) (7-40 hex) — the snapshot permits exactly ONE, only "
            f"in {_SS_SHA_KEY} (stacked SHAs are a history stack)\n"
            f"    {REMEDIATION_SESSION_STATE}")
    if off_field_shas > 0:
        fails.append(
            f"{_SS_FILE} [session-state] ACCRETION: a commit SHA appears "
            f"OUTSIDE {_SS_SHA_KEY} ({off_field_shas} off-field) — the "
            f"single boundary SHA lives ONLY in {_SS_SHA_KEY}\n"
            f"    {REMEDIATION_SESSION_STATE}")

    # Narration: zero history shapes (bare TD-tags stripped first).
    for v in all_values:
        stripped_v = _SS_TD_TAG_RE.sub("TD", v)
        for name, pat in _SS_NARRATION_PATTERNS:
            scan_target = (
                v if name in ("td-past-action", "per-td") else stripped_v)
            if pat.search(scan_target):
                fails.append(
                    f"{_SS_FILE} [session-state] ACCRETION: history/"
                    f"narration pattern '{name}' matched value {v[:80]!r} "
                    f"— the snapshot is current state only\n"
                    f"    {REMEDIATION_SESSION_STATE}")
                break

    # Byte-cap backstop (checked last — the precise bounds above catch the
    # SHAPE of accretion; the cap catches its GROWTH).
    size = len(raw.encode("utf-8"))
    if size > _SS_BYTE_CAP:
        fails.append(
            f"{_SS_FILE} [session-state] ANTI-GROWTH: {size} bytes exceeds "
            f"the {_SS_BYTE_CAP}-byte cap — a true current-frontier "
            f"snapshot is small + bounded\n"
            f"    {REMEDIATION_SESSION_STATE}")
    return fails


def main():
    by_doc, dangling_targets = load_allowlist()

    if MODE == "selftest":
        return run_selftest()

    if MODE == "file":
        # A relative ARG_FILE is relative to the project root (both the
        # validate.sh and the agent-post-edit-check.sh callers run from
        # there). realpath both sides so a /tmp -> /private/tmp symlink (or
        # any symlinked checkout) does not break the relative-path compute.
        root_real = os.path.realpath(ROOT)
        if os.path.isabs(ARG_FILE):
            file_real = os.path.realpath(ARG_FILE)
        else:
            file_real = os.path.realpath(os.path.join(root_real, ARG_FILE))
        rel = os.path.relpath(file_real, root_real)
        # Only gate operating docs; a non-IN .md (e.g. a stream entry,
        # a reference doc, a report) is skipped with a clean pass.
        in_set = set(iter_in_set())
        if rel not in in_set:
            print(f"[validate-docs] {rel} is not an operating doc "
                  f"(history store / report / reference) — skipping.")
            return 0
        # File mode is the per-edit operating-doc fast path; the conformance
        # leg is a whole-stream check (run in the full scan), not per-file.
        fails = run_scan([rel], ROOT, by_doc, dangling_targets)
    else:
        targets = iter_in_set()
        print(f"[validate-docs] scanning {len(targets)} operating docs "
              f"(4 axes: history / deferred / bloat / dangling) + per-entry "
              f"stream conformance")
        fails = run_scan(targets, ROOT, by_doc, dangling_targets)
        fails += run_conformance(ROOT)
        fails += run_session_state(ROOT)

    if fails:
        print(f"[validate-docs] FAIL — {len(fails)} violation(s) "
              f"(operating-doc + per-entry conformance):")
        for f in fails:
            print(f"  - {f}")
        return 1
    print("[validate-docs] PASS — operating docs clean + per-entry streams "
          "schema-conformant.")
    return 0


# ---------------------------------------------------------------------------
# --self-test: a synthetic PASS leg (a known-clean doc) + an injected-FAIL
# leg (a doc dirty on each axis). No shipped test file — the developer runs
# `validate-docs.sh --self-test` to confirm the gate's matchers still bite.
# ---------------------------------------------------------------------------
def run_selftest():
    import tempfile

    clean = (
        TRINITY_MEMORY_HEADING + "\n\n"
        "- **Trinity rule.** Keep CLAUDE.md, AGENTS.md, GEMINI.md in "
        "sync.\n\n"
        "See the roster doc (an orphan path `docs/pack/PM-CHAT.md` is "
        "carved out by the anchor word) for details.\n"
    )
    dirty_history = "Resolved on 2026-04-20 by the developer.\n"
    dirty_deferred = "This feature is deferred to a future release.\n"
    dirty_dangling = "See `docs/nonexistent/missing-file.md` for details.\n"
    dirty_bloat = (
        TRINITY_MEMORY_HEADING + "\n\n"
        "- **Big rule.** " + ("word " * 200) + "\n"
    )

    failures = []

    def gate(text, expect_fail, label, fname="CLAUDE.md"):
        with tempfile.TemporaryDirectory() as td:
            # mirror the trinity location so bloat + IN membership apply
            p = os.path.join(td, fname)
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(text)
            basenames, relpaths = build_index(td)
            fails = scan_doc(fname, td, {}, set(), basenames, relpaths)
            got_fail = bool(fails)
            if got_fail != expect_fail:
                failures.append(
                    f"{label}: expected {'FAIL' if expect_fail else 'PASS'}, "
                    f"got {'FAIL' if got_fail else 'PASS'} "
                    f"({len(fails)} hit(s))")

    gate(clean, False, "clean-doc")
    gate(dirty_history, True, "history")
    gate(dirty_deferred, True, "deferred")
    gate(dirty_dangling, True, "dangling")
    gate(dirty_bloat, True, "bloat")

    # --- BLOAT-HEADING BIJECTION leg: assert the bloat matcher's heading and
    #     the synthetic self-test docs' heading are the SAME literal. Both
    #     read TRINITY_MEMORY_HEADING (the single source of truth), so the
    #     two surfaces co-vary: a rename of one without the other cannot
    #     reach the live tree. The leg PROVES the co-variance by feeding the
    #     matcher a trinity doc built from the gate's own heading constant and
    #     confirming it finds the bullet (heads agree); the BITE leg feeds a
    #     DIVERGENT heading and confirms the matcher does NOT find it (a
    #     heading drift IS detectable, so the bloat scan cannot silently
    #     scan-nothing after a one-sided rename). Client-local: no platform
    #     import. ---
    matcher_heading = TRINITY_MEMORY_HEADING
    # (agree) self-test doc built from the same constant -> matcher finds it.
    agree_doc = (matcher_heading + "\n\n"
                 + "- **Sized rule.** " + ("word " * 200) + "\n")
    agree_bullets = list(
        project_memory_bullets(agree_doc.splitlines()))
    if not agree_bullets:
        failures.append(
            "bloat-heading-bijection: the bloat matcher did NOT find a "
            "bullet under a doc built from TRINITY_MEMORY_HEADING — the "
            "matcher heading and the self-test doc heading have drifted "
            "apart (one was renamed without the other).")
    # (bite) self-test doc built from a DIVERGENT heading -> matcher must
    # find nothing, proving a one-sided rename is detectable. The divergence
    # is a value-AGNOSTIC sentinel suffix (not a substring mutation of a
    # specific word), so the BITE leg keeps biting across ANY future rename
    # of the heading -- the appended sentinel guarantees the divergent
    # heading never equals the matcher's literal regardless of its words.
    divergent_heading = matcher_heading + " ZZ-DIVERGENCE-ZZ"
    bite_doc = (divergent_heading + "\n\n"
                + "- **Sized rule.** " + ("word " * 200) + "\n")
    bite_bullets = list(project_memory_bullets(bite_doc.splitlines()))
    if bite_bullets:
        failures.append(
            "bloat-heading-bijection BITE: the matcher matched a DIVERGENT "
            "heading — a heading rename would go undetected (the bijection "
            "leg cannot prove the matcher/self-test surfaces co-vary).")

    # --- CONFORMANCE leg self-test: build a synthetic populated project tree
    #     and confirm the conformance matchers PASS on a conforming tree and
    #     BITE on each violation class (sidecar vocabulary / monolith mirror /
    #     form-family field / status-enum / changelog structure). The schema
    #     is the live shipped _rules.md (the SSOT) for each stream, so the
    #     self-test also confirms the parser reads the shipped schema. SKIPs
    #     the conformance legs (with a note) if the shipped _rules.md set is
    #     absent (a partial checkout) — the 4 operating-doc axes still run. ---
    rules_root = os.path.join(ROOT, "docs", "project")
    rules_paths = {
        "backlog": os.path.join(rules_root, "backlog", "_rules.md"),
        "implementation-plan": os.path.join(
            rules_root, "implementation-plan", "_rules.md"),
        "changelog": os.path.join(rules_root, "changelog", "_rules.md"),
        "groupings": os.path.join(rules_root, "groupings", "_rules.md"),
    }
    conformance_self_test = all(os.path.isfile(p)
                                for p in rules_paths.values())

    if conformance_self_test:
        bl_rules = open(rules_paths["backlog"], encoding="utf-8").read()
        ip_rules = open(rules_paths["implementation-plan"],
                        encoding="utf-8").read()
        cl_rules = open(rules_paths["changelog"], encoding="utf-8").read()
        gr_rules = open(rules_paths["groupings"], encoding="utf-8").read()

    good_td = (
        "<!-- back -->\n"
        "**TD-001 — Sample**\n\n"
        "- **Entry-Type**: td\n"
        "- **ID**: TD-001\n"
        "- **Marker**: TODO\n"
        "- **Status**: Open\n"
        "- **Blockers**: none\n"
        "- **Unblocks**: none\n"
        "- **File/Symbol**: foo.swift\n"
        "- **Description**: a thing\n"
        "- **Context**: because\n"
        "- **Scope**: feature\n"
    )
    good_phase = (
        "<!-- back -->\n"
        "## Phase 0 — Bootstrap\n\n"
        "- **Entry-Type**: phase-epic\n"
        "- **ID**: phase-0\n"
        "- **Status**: not-started\n"
        "- **Blockers**: none\n"
        "- **Unblocks**: phase-1\n"
        "- **Goal**: bootstrap\n"
        "- **Prerequisite**: none\n"
    )
    good_cl = (
        "<!-- back -->\n"
        "### 2026-04-20 — Phase 35 — Sample\n\n"
        "**Summary**: did things.\n"
    )
    # A second impl-plan phase + a conforming `_index.md` ordering, for the
    # _index.md two-property self-test (BD-206 O11).
    good_phase1 = (
        "<!-- back -->\n"
        "## Phase 1 — Middle\n\n"
        "- **Entry-Type**: phase-epic\n"
        "- **ID**: phase-1\n"
        "- **Status**: not-started\n"
        "- **Blockers**: phase-0\n"
        "- **Unblocks**: none\n"
        "- **Goal**: middle\n"
        "- **Prerequisite**: none\n"
    )
    good_index_single = (
        "# Index — ordering — project-implementation-plan\n\n"
        "## Serial order\n\n"
        "- [phase-0](./phase-0.md) — Bootstrap\n"
    )
    good_index_two = (
        "# Index — ordering — project-implementation-plan\n\n"
        "## Serial order\n\n"
        "- [phase-0](./phase-0.md) — Bootstrap\n"
        "- [phase-1](./phase-1.md) — Middle\n"
    )

    def conf_gate(files, expect_fail, label):
        """files: {relpath_under_docs_project: content}. Always seeds each
        stream's shipped _rules.md so the parser has the SSOT schema."""
        with tempfile.TemporaryDirectory() as td:
            for sub, rules in (("backlog", bl_rules),
                               ("implementation-plan", ip_rules),
                               ("changelog", cl_rules),
                               ("groupings", gr_rules)):
                d = os.path.join(td, "docs", "project", sub)
                os.makedirs(d, exist_ok=True)
                with open(os.path.join(d, "_rules.md"), "w",
                          encoding="utf-8") as fh:
                    fh.write(rules)
                with open(os.path.join(d, "_intro.md"), "w",
                          encoding="utf-8") as fh:
                    fh.write("# intro\n")
            for relp, content in files.items():
                p = os.path.join(td, "docs", "project", relp)
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p, "w", encoding="utf-8") as fh:
                    fh.write(content)
            fails = run_conformance(td)
            got_fail = bool(fails)
            if got_fail != expect_fail:
                failures.append(
                    f"{label}: expected "
                    f"{'FAIL' if expect_fail else 'PASS'}, got "
                    f"{'FAIL' if got_fail else 'PASS'} ({len(fails)} hit(s))")

    if conformance_self_test:
        # Conforming populated tree → PASS (impl-plan carries a conforming
        # `_index.md` listing its single phase).
        conf_gate({"backlog/TD-001.md": good_td,
                   "implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/_index.md": good_index_single,
                   "changelog/2026-04-20-phase-35.md": good_cl},
                  False, "conformance-clean")
        # Empty (sidecar-only) tree → PASS (greenfield).
        conf_gate({}, False, "conformance-empty")
        # FORBIDDEN sidecar present → FAIL.
        conf_gate({"backlog/_format.md": "x\n"}, True,
                  "conformance-forbidden-sidecar")
        # Monolith mirror reintroduced → FAIL.
        conf_gate({"BACKLOG.md": "# mono\n"}, True,
                  "conformance-monolith-mirror")
        # backlog entry missing a core field (no Status) → FAIL.
        conf_gate({"backlog/TD-002.md": good_td.replace(
                      "- **Status**: Open\n", "")}, True,
                  "conformance-missing-core-field")
        # backlog entry with an out-of-enum Status → FAIL.
        conf_gate({"backlog/TD-003.md": good_td.replace(
                      "- **Status**: Open\n", "- **Status**: Bogus\n")}, True,
                  "conformance-bad-status-enum")
        # impl-plan phase-epic missing the Goal field → FAIL.
        conf_gate({"implementation-plan/phase-1.md": good_phase.replace(
                      "- **Goal**: bootstrap\n", "")}, True,
                  "conformance-implplan-missing-field")

        # --- impl-plan §3.5 GRACEFUL naming guard (BD-206 O13) ---
        # A phase-epic with well-formed inline parts + tasks + tolerated
        # epic-task `#### N.M — ` anchors → PASS (the gold heading shapes).
        good_phase_named = (good_phase
            + "\n### Tasks\n\n"
              "#### 0.1 — An epic task (tolerated; not Phase-prefixed)\n\n"
              "### Phase-0.Part-a — A well-formed part\n\n"
              "#### Phase-0.Part-a.Task-1 — A well-formed part task\n")
        conf_gate({"implementation-plan/phase-0.md": good_phase_named,
                   "implementation-plan/_index.md": good_index_single},
                  False, "conformance-implplan-naming-clean")
        # A parts-free epic (epic tasks only) → PASS (parts not required).
        conf_gate({"implementation-plan/phase-0.md": good_phase
                   + "\n### Tasks\n\n#### 0.1 — Only epic tasks here\n",
                   "implementation-plan/_index.md": good_index_single},
                  False, "conformance-implplan-naming-parts-free")
        # A lightweight phase-part entry (Entry-Type only, no headings) → PASS
        # (the naming guard does not fire; `_index.md` lists the entry).
        conf_gate({"implementation-plan/phase-0.md":
                   "<!-- back -->\n## Phase 0 — Epic\n\n"
                   "- **Entry-Type**: phase-part\n",
                   "implementation-plan/_index.md": good_index_single},
                  False, "conformance-implplan-naming-lightweight-part")
        # Malformed part H3 (capital part letter) → FAIL (R1 fires).
        conf_gate({"implementation-plan/phase-0.md": good_phase
                   + "\n### Phase-0.Part-A — Capital part letter is malformed\n"},
                  True, "conformance-implplan-naming-bad-part-h3")
        # Malformed part H3 (no em-dash separator) → FAIL.
        conf_gate({"implementation-plan/phase-0.md": good_phase
                   + "\n### Phase-0.Part-a No em-dash separator\n"},
                  True, "conformance-implplan-naming-bad-part-h3-nodash")
        # Malformed part-task H4 (non-numeric task index) → FAIL (R2 fires).
        conf_gate({"implementation-plan/phase-0.md": good_phase
                   + "\n### Phase-0.Part-a — OK part\n\n"
                     "#### Phase-0.Part-a.Task-x — Non-numeric index malformed\n"},
                  True, "conformance-implplan-naming-bad-part-task-h4")

        # changelog entry carrying a form-family Entry-Type → FAIL.
        conf_gate({"changelog/2026-05-01-x.md": good_cl
                   + "- **Entry-Type**: td\n"}, True,
                  "conformance-changelog-formfamily")

        # --- changelog deep conformance (BD-206 O12; reconciled) ---
        # A code-bearing changelog entry carries a Summary + advisory fields.
        good_cl_code = (
            "<!-- back -->\n"
            "### 2026-04-20 — Phase 9 — Sample\n\n"
            "**Summary**: did the code thing.\n"
            "**Test count**: 12 passing\n"
            "**Files modified (3)**: a.swift, b.swift, c.swift\n")
        # Code-bearing entry with Summary + advisory fields → PASS.
        conf_gate({"changelog/2026-04-20-phase-9.md": good_cl_code},
                  False, "conformance-changelog-core-clean")
        # Narrative-only entry (Summary, no advisory fields) → PASS.
        conf_gate({"changelog/2026-03-30-migration.md": good_cl},
                  False, "conformance-changelog-narrative-only-clean")
        # Scope-only narrative (no Summary, no advisory fields) → PASS.
        conf_gate({"changelog/2026-03-27-phase-14.md":
                   "<!-- back -->\n"
                   "### 2026-03-27 — Phase 14 — Test Audit\n\n"
                   "**Scope**: 24-item audit adding test coverage.\n"},
                  False, "conformance-changelog-scope-only")
        # Missing Files (Summary + Test) → PASS (Files advisory).
        conf_gate({"changelog/2026-04-20-no-files.md":
                   "### 2026-04-20 — Phase 9 — X\n\n"
                   "**Summary**: did it.\n**Test count**: 4 passing\n"},
                  False, "conformance-changelog-no-files")
        # Missing Test count (Summary + Files) → PASS (Test advisory).
        conf_gate({"changelog/2026-04-20-no-test.md":
                   "### 2026-04-20 — Phase 9 — X\n\n"
                   "**Summary**: did it.\n**Files modified**: a.swift\n"},
                  False, "conformance-changelog-no-test")
        # Missing narrative (Files + Test, no Summary/Scope) → FAIL (R1).
        conf_gate({"changelog/2026-04-20-no-summary.md":
                   "### 2026-04-20 — Phase 9 — X\n\n"
                   "**Test count**: 4 passing\n"
                   "**Files modified**: a.swift\n"},
                  True, "conformance-changelog-no-summary")
        # No narrative at all (prose only) → FAIL (R1).
        conf_gate({"changelog/2026-03-30-no-narrative.md":
                   "### 2026-03-30 — Migration — Y\n\nSome prose.\n"},
                  True, "conformance-changelog-no-narrative")
        # entry-max-lines violation (>180) → FAIL.
        conf_gate({"changelog/2026-04-20-too-long.md":
                   good_cl_code + ("\nline\n" * 200)},
                  True, "conformance-changelog-entry-too-long")
        # summary-max-words violation (>250) → FAIL.
        conf_gate({"changelog/2026-04-20-summary-too-long.md":
                   "### 2026-04-20 — Phase 9 — X\n\n"
                   "**Summary**: " + ("word " * 260) + "\n"
                   "**Test count**: 4 passing\n"
                   "**Files modified**: a.swift\n"},
                  True, "conformance-changelog-summary-too-long")
        # narrative word-cap also bites a Scope-expressed over-words entry → FAIL.
        conf_gate({"changelog/2026-03-27-scope-too-long.md":
                   "### 2026-03-27 — Phase 14 — Audit\n\n"
                   "**Scope**: " + ("word " * 260) + "\n"},
                  True, "conformance-changelog-scope-too-long")
        # NIT-1: strict filename (mandatory kebab slug). A bare-date file
        # no longer matches the entry regex → SKIPped (not an entry), so a
        # tree with only a bare-date file + a conforming kebab entry PASSes.
        conf_gate({"changelog/2026-04-20.md": good_cl_code,
                   "changelog/2026-04-20-phase-9.md": good_cl_code},
                  False, "conformance-changelog-strict-filename")

        # --- _index.md MANDATORY validation (BD-206 O11) two-property leg ---
        # Two conforming phases + a valid topological `_index.md` → PASS.
        conf_gate({"implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/phase-1.md": good_phase1,
                   "implementation-plan/_index.md": good_index_two},
                  False, "conformance-index-clean")
        # Phases present but NO _index.md → FAIL (mandatory ordering missing).
        conf_gate({"implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/phase-1.md": good_phase1},
                  True, "conformance-index-missing")
        # _index.md ORDER violates the hard dep (phase-1 blocked by phase-0
        # but listed first) → FAIL.
        bad_order = (
            "## Serial order\n\n"
            "- [phase-1](./phase-1.md) — Middle\n"
            "- [phase-0](./phase-0.md) — Bootstrap\n")
        conf_gate({"implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/phase-1.md": good_phase1,
                   "implementation-plan/_index.md": bad_order},
                  True, "conformance-index-order-violation")
        # _index.md MEMBERSHIP missing (phase-1 not listed) → FAIL.
        conf_gate({"implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/phase-1.md": good_phase1,
                   "implementation-plan/_index.md": good_index_single},
                  True, "conformance-index-membership-missing")
        # _index.md MEMBERSHIP extra (lists a phase with no file) → FAIL.
        extra_idx = good_index_two + "- [phase-9](./phase-9.md) — Ghost\n"
        conf_gate({"implementation-plan/phase-0.md": good_phase,
                   "implementation-plan/phase-1.md": good_phase1,
                   "implementation-plan/_index.md": extra_idx},
                  True, "conformance-index-membership-extra")

        # --- Target legs (BD-261): the target-enum guard + the coherence
        #     gate. Every coherence tree carries a CONFORMING `_index.md`
        #     in a legal order so the boolean verdict isolates the leg
        #     under test (a missing index would FAIL for the wrong
        #     reason). Fixture builders: ---
        def t_phase(num, status="not-started", target=None,
                    blockers="none", unblocks="none"):
            body = (
                "<!-- back -->\n"
                f"## Phase {num} — T{num}\n\n"
                "- **Entry-Type**: phase-epic\n"
                f"- **ID**: phase-{num}\n"
                f"- **Status**: {status}\n"
                f"- **Blockers**: {blockers}\n"
                f"- **Unblocks**: {unblocks}\n"
                "- **Goal**: g\n"
                "- **Prerequisite**: none\n")
            if target is not None:
                body += f"- **Target**: {target}\n"
            return body

        def t_index(*nums):
            return ("# Index — ordering — project-implementation-plan\n\n"
                    "## Serial order\n\n"
                    + "".join(f"- [phase-{n}](./phase-{n}.md) — T{n}\n"
                              for n in nums))

        # Legal token → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="current"),
                   "implementation-plan/_index.md": t_index(0)},
                  False, "conformance-target-valid")
        # Out-of-enum token → FAIL.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="v2.0"),
                   "implementation-plan/_index.md": t_index(0)},
                  True, "conformance-bad-target-enum")
        # Present-but-empty → FAIL.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target=""),
                   "implementation-plan/_index.md": t_index(0)},
                  True, "conformance-empty-target")
        # Absent = no claim → PASS.
        conf_gate({"implementation-plan/phase-0.md": t_phase(0),
                   "implementation-plan/_index.md": t_index(0)},
                  False, "conformance-target-absent")
        # A phase-part carrying a (even illegal) Target is tolerated —
        # epic-only posture (parts inherit by containment) → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       "<!-- back -->\n## Phase 0 — Part\n\n"
                       "- **Entry-Type**: phase-part\n"
                       "- **Target**: v9.9\n",
                   "implementation-plan/_index.md": t_index(0)},
                  False, "conformance-part-target-tolerated")
        # One-token grammar: a trailing comment is not a token → FAIL.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="current — see note"),
                   "implementation-plan/_index.md": t_index(0)},
                  True, "conformance-target-trailing-comment")
        # Coherence: declared blocker later than its declared dependent
        # (direct edge conflict) → FAIL.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="next-major", unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="current", blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1)},
                  True, "coherence-conflict-direct")
        # Coherence: the bound proves TRANSITIVELY through an untargeted
        # intermediate → FAIL (same class semantics: still a gate FAIL).
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="next-major", unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, blockers="phase-0", unblocks="phase-2"),
                   "implementation-plan/phase-2.md":
                       t_phase(2, target="current", blockers="phase-1"),
                   "implementation-plan/_index.md": t_index(0, 1, 2)},
                  True, "coherence-conflict-transitive")
        # Coherence: an UNTARGETED blocker of targeted work carries only an
        # implied bound — merely-implied bounds are never gate lines → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="current", blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1)},
                  False, "coherence-implied-clean")
        # Coherence: a DONE blocker's late claim is spent (absorbing —
        # neither contributes, transmits, nor receives) → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, status="done", target="next-major",
                               unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="current", blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1)},
                  False, "coherence-done-blocker-exempt")
        # Coherence: a future-unassigned DEPENDENT imposes no bound (the
        # non-constraining token) → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="next-major", unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="future-unassigned",
                               blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1)},
                  False, "coherence-fu-dependent-unbounded")
        # Coherence: an untargeted DEFERRED blocker of targeted work emits
        # no gate line (the state tension is advisory, not a gate FAIL —
        # deferred is non-absorbing but carries no declared claim) → PASS.
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, status="deferred", unblocks="phase-1"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="current", blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1)},
                  False, "coherence-deferred-blocker-no-line")
        # Coherence: MIXED dependents — one declares current (contributes
        # the bound), one is untargeted (UNDEFINED — drops out of the min
        # entirely; it never poisons the min). The conflict fires on the
        # blocker → FAIL. (Bites the undefined-poisons-the-min misread,
        # which would leave this tree green.)
        conf_gate({"implementation-plan/phase-0.md":
                       t_phase(0, target="next-major",
                               unblocks="phase-1 phase-2"),
                   "implementation-plan/phase-1.md":
                       t_phase(1, target="current", blockers="phase-0"),
                   "implementation-plan/phase-2.md":
                       t_phase(2, blockers="phase-0"),
                   "implementation-plan/_index.md": t_index(0, 1, 2)},
                  True, "coherence-mixed-dependents-conflict")

        # --- Groupings conformance (BD-189): the closed byte-canonical
        #     grammar + reserved-GRP-000 branch + stream-level legs +
        #     the empty-Status / part-member closes. Fixture builders
        #     emit the closed serialization byte-exactly: ---
        def g_entry(gid, kind, members, exception=None, title=None):
            t = title if title is not None else f"Sample {gid}"
            body = (
                f"<!-- per-entry source: docs/project/groupings/{gid}.md;"
                f" contract: docs/project/groupings/_rules.md -->\n"
                f"**{gid} — {t}**\n"
                f"Entry-Type: grouping\n"
                f"Kind: {kind}\n"
                "Member-phases:"
                + (" " + ", ".join(members) if members else "") + "\n")
            if exception is not None:
                body += f"Single-member exception: {exception}\n"
            return body

        def g_toc(*rows):
            return ("# Table of contents — project-groupings\n\n"
                    "## unassigned\n\n"
                    + "".join(f"- {gid} — x (phases: {n})\n"
                              for gid, n in rows))

        grp_base = {
            "implementation-plan/phase-0.md": t_phase(0,
                                                      unblocks="phase-1"),
            "implementation-plan/phase-1.md": t_phase(1,
                                                      blockers="phase-0"),
            "implementation-plan/_index.md": t_index(0, 1),
        }
        # Conforming populated groupings tree (2 members + toc) → PASS.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc(("GRP-001", 2))}),
            False, "conformance-groupings-clean")
        # Reserved GRP-000: single member, NO exception field → PASS.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-000.md": g_entry(
                "GRP-000", "unassigned", ["phase-0"],
                title="Ungrouped (declared)"),
            "groupings/_toc.md": g_toc(("GRP-000", 1))}),
            False, "conformance-groupings-grp000-single-clean")
        # Reserved GRP-000: EMPTY member value → PASS (legal-empty).
        conf_gate(dict(grp_base, **{
            "groupings/GRP-000.md": g_entry(
                "GRP-000", "unassigned", [],
                title="Ungrouped (declared)"),
            "groupings/_toc.md": g_toc(("GRP-000", 0))}),
            False, "conformance-groupings-grp000-empty-clean")
        # Out-of-enum Kind → FAIL.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "made-up", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc(("GRP-001", 2))}),
            True, "conformance-groupings-bad-kind")
        # Zero members on a REAL grouping → FAIL (GRP-000 alone is
        # empty-legal — the contrast pair to grp000-empty-clean).
        conf_gate(dict(grp_base, **{
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", []),
            "groupings/_toc.md": g_toc(("GRP-001", 0))}),
            True, "conformance-groupings-zero-members")
        # Exception field on GRP-000 (any count) → FAIL (forbidden).
        conf_gate(dict(grp_base, **{
            "groupings/GRP-000.md": g_entry(
                "GRP-000", "unassigned", ["phase-0"],
                exception="never legal here",
                title="Ungrouped (declared)"),
            "groupings/_toc.md": g_toc(("GRP-000", 1))}),
            True, "conformance-groupings-grp000-exception-forbidden")
        # Exclusivity: a phase in GRP-000 AND a real grouping → FAIL.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-000.md": g_entry(
                "GRP-000", "unassigned", ["phase-0"],
                title="Ungrouped (declared)"),
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc(("GRP-000", 1),
                                       ("GRP-001", 2))}),
            True, "conformance-groupings-exclusivity")
        # Mis-named GRP-0000.md (tightened numbering) → FAIL.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-0000.md": g_entry(
                "GRP-0000", "user-journey", ["phase-0", "phase-1"])}),
            True, "conformance-groupings-misnamed-grp0000")
        # Reintroduced GROUPINGS.md monolith → FAIL.
        conf_gate(dict(grp_base, **{
            "GROUPINGS.md": "# mono\n",
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc(("GRP-001", 2))}),
            True, "conformance-groupings-monolith-mirror")
        # toc-sync drift (entry present, no _toc.md row) → FAIL.
        conf_gate(dict(grp_base, **{
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc()}),
            True, "conformance-groupings-toc-drift")
        # Empty-Status close: present-but-EMPTY Status on a phase-epic
        # → FAIL (the A2 predicate; no groupings entry needed).
        conf_gate({"implementation-plan/phase-0.md": t_phase(0, status=""),
                   "implementation-plan/_index.md": t_index(0)},
                  True, "conformance-empty-status")
        # Part-member close: a member token resolving to a phase-part
        # entry → FAIL (parts inherit membership by containment).
        conf_gate(dict(grp_base, **{
            "implementation-plan/phase-1.md":
                "<!-- back -->\n## Phase 1 — Part\n\n"
                "- **Entry-Type**: phase-part\n",
            "groupings/GRP-001.md": g_entry(
                "GRP-001", "user-journey", ["phase-0", "phase-1"]),
            "groupings/_toc.md": g_toc(("GRP-001", 2))}),
            True, "conformance-groupings-part-member")

    if failures:
        print("[validate-docs --self-test] FAIL:")
        for f in failures:
            print(f"  - {f}")
        return 1
    conf_note = ("+ the per-entry conformance leg" if conformance_self_test
                 else "(conformance self-test SKIPPED — shipped _rules.md "
                      "set absent)")
    print("[validate-docs --self-test] PASS — all 4 operating-doc axes "
          "(history / deferred / bloat / dangling) " + conf_note
          + " bite correctly.")
    return 0


sys.exit(main())
PYEOF
