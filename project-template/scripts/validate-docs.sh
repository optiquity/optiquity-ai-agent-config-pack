#!/usr/bin/env bash
# validate-docs.sh — Operating-doc enforcement gate.
#
# Keeps the project's operating docs forward-only, terse, and
# referentially sound. Operating docs are the live instruction surface
# the agents and the PM chat execute: the project trinity
# (CLAUDE.md / AGENTS.md / GEMINI.md), the docs/pack/ reference docs,
# the per-agent prompts, the skills, the agent definitions, and the
# stream contract files (docs/project/*/_rules.md, changelog/_format.md).
#
# Four axes:
#   - HISTORY   — dates / SHAs / past-action narration / provenance
#                 belong in BACKLOG / CHANGELOG entries and completion
#                 reports, never in a forward-only operating doc.
#   - DEFERRED  — an operating doc must not advertise a deferred /
#                 unimplemented / off-by-default feature.
#   - BLOAT     — a single per-bullet character cap over the trinity
#                 "## Project memory" bullets (the mega-bullet axis).
#   - DANGLING  — a backtick / hyperlink / qualified-path file reference
#                 whose target does not resolve in the project tree.
#
# History stores are EXCLUDED (never scanned): the per-entry streams
# under docs/project/{backlog,implementation-plan,changelog}/, the
# regenerated monolith mirrors (BACKLOG.md / IMPLEMENTATION-PLAN.md /
# CHANGELOG.md / STATUS.md), docs/reference/, completion reports,
# _intro.md / _toc.md / HELP-FRAGMENT*.md, and scripts/ + proto/ +
# source code. Those legitimately carry dates and deferral narrative.
#
# Usage:
#   validate-docs.sh            scan the full operating-doc set
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
    "docs/project/changelog/_format.md",
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
# A single per-bullet character cap over the trinity "## Project memory"
# bullets — the mega-bullet axis. Irreducible enumerations (e.g. the
# denied-git-verb list) are allowlisted by snippet.
BLOAT_BULLET_CHAR_CAP = 700
TRINITY = {"CLAUDE.md", "AGENTS.md", "GEMINI.md"}

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
    the '## Project memory' section. A bullet runs from a '- ' line until the
    next '- ' line, a blank line, or the next '## ' header."""
    start = None
    for i, l in enumerate(lines):
        if l.strip() == "## Project memory":
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
    "reference doc, a regenerated mirror, a project script) — add a "
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
        fails = run_scan([rel], ROOT, by_doc, dangling_targets)
    else:
        targets = iter_in_set()
        print(f"[validate-docs] scanning {len(targets)} operating docs "
              f"(4 axes: history / deferred / bloat / dangling)")
        fails = run_scan(targets, ROOT, by_doc, dangling_targets)

    if fails:
        print(f"[validate-docs] FAIL — {len(fails)} operating-doc "
              f"violation(s):")
        for f in fails:
            print(f"  - {f}")
        return 1
    print("[validate-docs] PASS — operating docs clean.")
    return 0


# ---------------------------------------------------------------------------
# --self-test: a synthetic PASS leg (a known-clean doc) + an injected-FAIL
# leg (a doc dirty on each axis). No shipped test file — the developer runs
# `validate-docs.sh --self-test` to confirm the gate's matchers still bite.
# ---------------------------------------------------------------------------
def run_selftest():
    import tempfile

    clean = (
        "## Project memory\n\n"
        "- **Trinity rule.** Keep CLAUDE.md, AGENTS.md, GEMINI.md in "
        "sync.\n\n"
        "See the roster doc (an orphan path `docs/pack/PM-CHAT.md` is "
        "carved out by the anchor word) for details.\n"
    )
    dirty_history = "Resolved on 2026-04-20 by the developer.\n"
    dirty_deferred = "This feature is deferred to a future release.\n"
    dirty_dangling = "See `docs/nonexistent/missing-file.md` for details.\n"
    dirty_bloat = (
        "## Project memory\n\n"
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

    if failures:
        print("[validate-docs --self-test] FAIL:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("[validate-docs --self-test] PASS — all 4 axes "
          "(history / deferred / bloat / dangling) bite correctly.")
    return 0


sys.exit(main())
PYEOF
