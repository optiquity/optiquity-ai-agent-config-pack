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
# Four operating-doc axes + a per-entry conformance leg:
#   - HISTORY   — dates / SHAs / past-action narration / provenance
#                 belong in BACKLOG / CHANGELOG entries and completion
#                 reports, never in a forward-only operating doc.
#   - DEFERRED  — an operating doc must not advertise a deferred /
#                 unimplemented / off-by-default feature.
#   - BLOAT     — a single per-bullet character cap over the trinity
#                 "## Project memory" bullets (the mega-bullet axis).
#   - DANGLING  — a backtick / hyperlink / qualified-path file reference
#                 whose target does not resolve in the project tree.
#   - CONFORMANCE — the populated per-entry streams conform to the
#                 no-mirror form-family / structured schema declared in
#                 each stream's _rules.md (the same SSOT schema block the
#                 pack-side validate-pack.py leg parses; the two parsers
#                 cannot diverge). Validates: sanctioned sidecar
#                 vocabulary (no _format.md / _scaffolding.md), NO
#                 reintroduced monolith mirror, and per-entry field /
#                 structure conformance (form-family for backlog +
#                 implementation-plan, structured for changelog).
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
#                               per-entry conformance
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
TRINITY_MEMORY_HEADING = "## Project memory"

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
    "Operating-doc bullets stay terse. This '## Project memory' bullet "
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

    # AXIS: bloat (trinity Project-memory bullets only)
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
)
_CONF_FORBIDDEN_SIDECARS = ("_format.md", "_scaffolding.md")
_CONF_ENTRY_REGEX = {
    "backlog":             re.compile(r"^TD-\d+\.md$"),
    "implementation-plan": re.compile(r"^phase-\d+\.md$"),
    "changelog":           re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$"),
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
    if status_enum and status_val and status_val not in status_enum:
        fails.append(
            f"{rel} [conformance] Status '{status_val}' not in "
            f"status-enum {status_enum}")
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
}


# ---------------------------------------------------------------------------
# `_index.md` MANDATORY validation (BD-206 O11 / G-3), client populated-tree
# leg. The impl-plan stream carries `_index.md` (the dependency-derived
# serial ordering); the backlog is unordered → no index. This leg enforces
# the TWO hard properties against the POPULATED client tree:
#   (1) hard-dependency-order consistency — the `_index.md` serial order is a
#       VALID topological order of the rule-based deps (from each phase's
#       Blockers / Unblocks / Dependencies SSOT — the deps stay SSOT in the
#       entry files; `_index.md` is not a competing source);
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


def _conf_check_index(rel_dir, stream_dir, names):
    """The two-property `_index.md` validator for the populated impl-plan
    tree. rel_dir is the stream's repo-relative dir; stream_dir its abspath;
    names the file basenames in it. Returns a list of failure strings."""
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
            f"ordering (regenerate via scripts/lib/per-entry/index-generate.sh)"
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
                    f"_toc.md" + (" / _index.md" if admitted else "") + ")\n"
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
            fails.extend(_conf_check_index(rel_dir, stream_dir, names))
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
    }
    conformance_self_test = all(os.path.isfile(p)
                                for p in rules_paths.values())

    if conformance_self_test:
        bl_rules = open(rules_paths["backlog"], encoding="utf-8").read()
        ip_rules = open(rules_paths["implementation-plan"],
                        encoding="utf-8").read()
        cl_rules = open(rules_paths["changelog"], encoding="utf-8").read()

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
                               ("changelog", cl_rules)):
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
