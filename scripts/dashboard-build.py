#!/usr/bin/env python3
# pack-dashboard build script · spec: pack-ops/DASHBOARD-SPEC-PACK.md · spec-sha: 6833a4d70691b9cb9468129cbc8a9f4ff7c95f39 · structure-sha: 05497fac135b225cde3c7de430749302400abd6f140459f9cf49ed56c40077c1
"""scripts/dashboard-build.py — the ONE sanctioned committed build/verify script
for /pack-dashboard (BD-224 render-cache, OPTION-2 reconciled model).

This is COMMITTED, CODER-AUTHORED SOURCE (not runtime-authored): it is edited only
through the coder/review cycle on a spec OR format-contract change, never free-form
re-authored per render. It closes the F1 circularity (the `verify` oracle is no
longer itself a free-form artifact) and makes the tested fail-closed floor reach the
FIRST render. See ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §2 for the
committed-stable-vs-runtime-authored partition.

Two modes:

  build  — collect live state FRESH from the repo, select E_full deterministically,
           emit every `bds{}` record with a `tier:"full"|"minimal"` field (each
           `tier:"full"` record carries a SOURCE-ANCHORED body drawn from the live
           `backlog/BD-NNN.md` Description/Context), run the multi-source plan sweep
           + the committed-history plans floor, stamp the DUAL-fingerprint provenance
           ({spec-sha, structure-sha}), inject `#state` into the render shell, and
           write pack-ops/dashboard-approvals/dashboard.html (+ dashboard-shell.html
           when synthesizing a fresh shell).

  verify — the render-time fail-closed ORACLE (orchestrator-run, and re-derived
           INDEPENDENTLY of `build`'s in-memory objects). Parse the produced
           dashboard.html `#state` as a BLACK BOX, re-derive E_full FRESH from the
           live backlog, and HARD-FAIL (non-zero exit) on any shortfall or any input
           it cannot account for. Assertions (RECONCILED §3):
             A. Status-vocabulary CLOSURE vs the live backlog/_rules.md
                `## Lifecycle states admitted` section (a new canonical status the
                tier-map cannot place is fail-closed; empty-parse is fail-closed).
             B. total-accountability / 100% parse-coverage (every live BD yields an
                id + a parseable Status AND appears in `#state.bds`; a dropped or
                extra id is fail-closed).
             C. structure-sha + spec-sha match (the render's stamped fingerprints ==
                the freshly re-derived live fold; a format-contract / spec edit
                between build and verify is fail-closed).
             D. the E_full full-set floor: the set of `tier:"full"` ids == the freshly
                re-derived E_full membership, AND every `tier:"full"` record carries a
                SOURCE-ANCHORED body (len>=40 normalized, not a title/snippet echo,
                sharing a >=20-char shingle or content-word Jaccard>=0.30 with the
                live Description/Context).
             plans floor: each derived-active / newest-Resolved BD with real
                `git log --grep=BD-NNN` feat/fix landings MUST appear in `#state.plans`.
             section floors (§3.6, presence-driven): metrics{resolved,total} == the
                live backlog tally; changelog[] count == the live /changelog/ major-
                version file count; rules[] count == the live `CLAUDE.md ## Pack
                memory` rule-bullet count; help{} non-empty when a help source exists.

BAKED (spec-derived LOGIC, regenerated only by a reviewed edit on a spec/structure
change): the E_full selection FORMULA (incl. the OBS-8 tie-break), the tier
discriminator, the discovery precedence, the status->token map, the source-anchored
body predicate, serialize/escape. READ-FRESH every render (never baked): the BD
list / ids / total, each BD's Status / Resolved-date / body, session-state values,
rules[] / changelog[] / metrics / help, and live git history. Baking any read-fresh
datum is the stale-window regression; `verify`'s independent re-read locks the
no-bake property.

structure-sha fold (the FORMAT contract fingerprint — the exact byte-serialization
C2's Check 88 `_structure_sha()` MUST reproduce):

    structure_sha = sha256("".join(part + "\\n" for part in [
        git_blob_sha1(backlog/_rules.md),      # 40-hex
        git_blob_sha1(changelog/_rules.md),    # 40-hex
        <session-state "schema" token value>,  # e.g. pack-session-state/1
        repr(_SESSION_STATE_REQUIRED_KEYS),    # the tuple VALUE, ast-extracted
    ]))

`git_blob_sha1` is the pure-Python git blob object id (sha1 of `b"blob <len>\\0" +
content`); it equals `git hash-object` for LF content with no gitattributes filter,
so the script needs no subprocess for the hash and stays git-independent for its
fingerprints (portable to a /tmp fixture). The required-keys tuple is ast-extracted
from scripts/lib/validate_checks/core.py (`_SESSION_STATE_REQUIRED_KEYS`); its
absence is a fail-closed input error.

The mechanical, agent-INDEPENDENT CI backstop is DEEP Check 89
(check_dashboard_committed_floor, a NEW module that shares NO code with this script)
— it re-derives E_full and floors the COMMITTED dashboard.html, catching a
skipped/faked render-time `verify`. Check 89 and its qualified module land in a
LATER commit; this script references the CI floor as "Check 89" / "the mechanical CI
floor" by prose only.

Usage:
    python3 scripts/dashboard-build.py build  [--repo-root PATH]
    python3 scripts/dashboard-build.py verify [--repo-root PATH]

`--repo-root` defaults to the git toplevel of this script (or the parent of
`scripts/`); a per-test harness points it at a /tmp fixture tree.
"""

import argparse
import ast
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

# ── Spec-derived constants (BAKED logic) ────────────────────────────────────
SPEC_REL = "pack-ops/DASHBOARD-SPEC-PACK.md"
BACKLOG_RULES_REL = "backlog/_rules.md"
CHANGELOG_RULES_REL = "changelog/_rules.md"
SESSION_STATE_REL = "pack-ops/session-state.json"
CORE_REL = "scripts/lib/validate_checks/core.py"
CLAUDE_REL = "CLAUDE.md"
APPROVALS_DIR_REL = "pack-ops/dashboard-approvals"
DASHBOARD_HTML_REL = APPROVALS_DIR_REL + "/dashboard.html"
DASHBOARD_SHELL_REL = APPROVALS_DIR_REL + "/dashboard-shell.html"

# The six canonical lifecycle states the tier-map handles (RECONCILED §3.2 the
# "known universe"). live_vocab (parsed from backlog/_rules.md) must be a subset.
KNOWN_STATUS_UNIVERSE = frozenset(
    {"Open", "Unblocked", "Deferred", "Resolved", "Deprecated", "Cancelled"}
)
# Non-terminal = unresolved + revivable (drives E_full's non-terminal arm).
# Deprecated / Cancelled are terminal-dead (treated like Resolved); Resolved is
# terminal (its newest-10 are the separate E_full arm).
NON_TERMINAL_STATUSES = frozenset({"Open", "Unblocked", "Deferred"})
# backlog Status: value -> §5.1 status token (spec §3 mapping).
STATUS_TOKEN = {
    "Open": "pending",
    "Unblocked": "unblocked",
    "Deferred": "deferred",
    "Resolved": "done",
    "Deprecated": "deprecated",
    "Cancelled": "cancelled",
}
NEWEST_RESOLVED_N = 10  # E_full newest-Resolved arm size (OBS-8).
BODY_MIN_NORMALIZED = 40  # source-anchored body floor (RECONCILED §3.4 F4).
SHINGLE_LEN = 20  # contiguous shingle length for the source-anchor test.
JACCARD_MIN = 0.30  # content-word Jaccard floor (fallback anchor test).

# Provenance line (pinned line 2, immediately after <!DOCTYPE html>, per spec §2
# step 4 / O10) and its extraction regexes (spec-sha 40-hex sha1; structure-sha
# 64-hex sha256).
PROV_SPEC_RE = re.compile(r"spec-sha:\s*([0-9a-f]{40})\b")
PROV_STRUCT_RE = re.compile(r"structure-sha:\s*([0-9a-f]{64})\b")
_STATE_SCRIPT_RE = re.compile(
    r'(<script[^>]*id="state"[^>]*>)(.*?)(</script>)', re.S
)
_STATUS_RE = re.compile(r"^Status:\s*(\w+)", re.M)
_RESOLVED_RE = re.compile(r"^Resolved:\s*(.+)$", re.M)
_DATE_RE = re.compile(r"(20\d\d-\d\d-\d\d)")
_TITLE_RE = re.compile(r"^\*\*BD-\d+\s*[—-]\s*(.+?)\*\*", re.M)
_BD_ID_RE = re.compile(r"BD-(\d+)")
# The vocab bullet shape (spec §5 / RECONCILED §3.2 F9): dash + single backticked
# word + em-dash gloss, section-scoped.
_VOCAB_BULLET_RE = re.compile(r"^- `([A-Za-z]+)`\s*—", re.M)
# A rule bullet in CLAUDE.md ## Pack memory (spec §7.7): a top-level `- **Title.**`.
_RULE_BULLET_RE = re.compile(r"^- \*\*", re.M)


class BuildError(Exception):
    """A fail-closed input error (a critical source the script cannot account
    for). Raised by build; verify converts the same conditions into a FAIL."""


# ── Repo-root resolution ────────────────────────────────────────────────────
def resolve_repo_root(explicit):
    if explicit:
        return Path(explicit).resolve()
    here = Path(__file__).resolve()
    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, cwd=here.parent,
        )
        if top.returncode == 0 and top.stdout.strip():
            return Path(top.stdout.strip()).resolve()
    except FileNotFoundError:
        pass
    # Fallback: the parent of scripts/ (this file lives at scripts/).
    return here.parent.parent


# ── Fingerprints (git-independent, portable) ────────────────────────────────
def git_blob_sha1(path):
    """The git blob object id of `path` (== `git hash-object`), pure-Python."""
    data = Path(path).read_bytes()
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(data))
    h.update(data)
    return h.hexdigest()


def extract_required_keys(root):
    """ast-extract `_SESSION_STATE_REQUIRED_KEYS` from core.py (fail-closed on
    absence). Returns the tuple VALUE (folded via repr into structure-sha)."""
    core_path = root / CORE_REL
    if not core_path.is_file():
        raise BuildError(
            f"{CORE_REL} absent — cannot fold the required-keys tuple into "
            f"structure-sha (fail-closed input)"
        )
    tree = ast.parse(core_path.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for tgt in node.targets:
                if isinstance(tgt, ast.Name) and tgt.id == "_SESSION_STATE_REQUIRED_KEYS":
                    return ast.literal_eval(node.value)
    raise BuildError(
        f"_SESSION_STATE_REQUIRED_KEYS not found in {CORE_REL} (fail-closed input)"
    )


def read_schema_token(root):
    ss_path = root / SESSION_STATE_REL
    if not ss_path.is_file():
        raise BuildError(f"{SESSION_STATE_REL} absent (fail-closed input)")
    obj = json.loads(ss_path.read_text(encoding="utf-8"))
    schema = obj.get("schema")
    if not schema:
        raise BuildError(f"{SESSION_STATE_REL} carries no `schema` token (fail-closed)")
    return schema, obj


def compute_structure_sha(root):
    """The FORMAT-contract fingerprint. Exact byte-fold — see the module docstring;
    C2's Check 88 `_structure_sha()` must reproduce this serialization byte-for-byte."""
    for rel in (BACKLOG_RULES_REL, CHANGELOG_RULES_REL):
        if not (root / rel).is_file():
            raise BuildError(f"{rel} absent — cannot compute structure-sha (fail-closed)")
    schema, _ = read_schema_token(root)
    keys = extract_required_keys(root)
    parts = [
        git_blob_sha1(root / BACKLOG_RULES_REL),
        git_blob_sha1(root / CHANGELOG_RULES_REL),
        schema,
        repr(keys),
    ]
    payload = "".join(part + "\n" for part in parts)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def compute_spec_sha(root):
    """The LOGIC-contract fingerprint = git blob id of THIS spec."""
    spec_path = root / SPEC_REL
    if not spec_path.is_file():
        raise BuildError(f"{SPEC_REL} absent — cannot compute spec-sha (fail-closed)")
    return git_blob_sha1(spec_path)


# ── Backlog parsing (READ-FRESH) ────────────────────────────────────────────
def normalize(text):
    return " ".join((text or "").lower().split())


def collapse_ws(text):
    """Case-PRESERVING whitespace collapse — the DISPLAY transform for stored prose
    (deep-page body + Archive snippet). Identical folding to `normalize` MINUS the
    lowercase, so stored prose keeps its source case (`**Problem:**`, not
    `**problem:**`). Length-identical to `normalize(text)` (lowercasing is
    length-preserving), so the snippet-cap arithmetic is unchanged. verify's
    source-anchor predicate normalizes BOTH sides, so the case-preserving store is
    predicate-safe (verify never sees the case)."""
    return " ".join((text or "").split())


def _field_block(text, name):
    """Return the `Name:` field block (up to the next top-level `Word:` header)."""
    lines = text.splitlines()
    hdr = re.compile(r"^[A-Za-z][A-Za-z/ _-]*:")
    start = re.compile(r"^" + re.escape(name) + r":\s?(.*)$")
    out = []
    capturing = False
    for ln in lines:
        if not capturing:
            m = start.match(ln)
            if m:
                capturing = True
                if m.group(1):
                    out.append(m.group(1))
        else:
            if hdr.match(ln) and not ln.startswith((" ", "\t")):
                break
            out.append(ln)
    return "\n".join(out).strip()


def _first_line(text):
    text = (text or "").strip()
    return text.splitlines()[0].strip() if text else ""


# Short metadata field labels (stripped from the substantive-body fallback so a
# body drawn from a BD lacking Description/Context anchors on its Problem / Scope /
# Goal prose, not its Type/Status/Blockers header).
_META_FIELD_RE = re.compile(
    r"^(Type|Status|Target|Blockers|Unblocks|Resolved|Position|File/Symbol|"
    r"References|Source|Disposition):"
)


def substantive_src(text):
    """The BD's own substantive prose body (the source the tier:full body anchors
    on). Prefer the named Description/Context; when neither is populated, fall back
    to the entry's flush-left prose (Problem / Scope / Goal / Acceptance / …) with
    the back-pointer, bold header, short metadata fields, and indented sub-bullets
    stripped. Every real BD carries ample prose either way."""
    desc = _field_block(text, "Description")
    ctx = _field_block(text, "Context")
    primary = (desc + " " + ctx).strip()
    if len(normalize(primary)) >= BODY_MIN_NORMALIZED:
        return primary
    kept = []
    for ln in text.splitlines():
        if ln.startswith("<!--") or ln.startswith("**BD-"):
            continue
        if _META_FIELD_RE.match(ln):
            continue
        if ln[:1] in (" ", "\t"):  # indented continuation / sub-bullet
            continue
        if ln.strip():
            kept.append(ln.strip())
    return " ".join(kept).strip()


def _tracked_backlog_bd_files(root):
    """The git-TRACKED `backlog/BD-NNN.md` set — the deterministic enumeration
    boundary (the committed set CI Check 89 also floors against). `git ls-files
    backlog/` yields the committed/tracked paths, so `build` and `verify` (both
    route through parse_backlog) enumerate IDENTICALLY and can never disagree, and
    an untracked scratch file or a locally-modified-but-tracked path never shifts
    the set the way a raw filesystem glob could. O(entries) — git-tracked
    candidates only, never a whole-tree walk (ci-check-runtime-compounding).
    Fail-closed LOUDLY off a git work tree; NEVER a silent raw-FS fallback.
    Returns a sorted list of absolute Paths."""
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "ls-files", "backlog/"],
            capture_output=True, text=True,
        )
    except FileNotFoundError:
        raise BuildError(
            "git not found — the backlog enumeration reads the committed set via "
            "`git ls-files backlog/` and does NOT fall back to a filesystem walk "
            "(fail-closed input)"
        )
    if out.returncode != 0:
        raise BuildError(
            f"`git ls-files backlog/` failed (rc={out.returncode}) — {root} is not a "
            f"git work tree; the backlog enumeration is git-tracked and does NOT fall "
            f"back to a filesystem walk (fail-closed input): {out.stderr.strip()}"
        )
    paths = []
    for line in out.stdout.splitlines():
        rel = line.strip()
        if re.match(r"^backlog/BD-\d+\.md$", rel):
            paths.append(root / rel)
    return sorted(paths)


def parse_backlog(root):
    """Return (records dict keyed by id, parse_failures list).

    Each record: {id, num, status, token, resolved_date, title, type, target,
    blockers, unblocks, src (Description+Context), snippet}. A BD file with no
    parseable Status is a parse failure (fail-closed for verify). The BD set is
    enumerated from the git-TRACKED `backlog/` tree (`git ls-files backlog/` — the
    committed set, deterministic and matching the CI Check-89 boundary), NOT a
    filesystem glob; off a git work tree this fail-closes (no raw-FS fallback)."""
    backlog_dir = root / "backlog"
    if not backlog_dir.is_dir():
        raise BuildError("backlog/ tree absent (fail-closed input)")
    records = {}
    failures = []
    for path in _tracked_backlog_bd_files(root):
        bd_id = path.stem  # e.g. BD-224
        num = int(_BD_ID_RE.match(bd_id).group(1))
        text = path.read_text(encoding="utf-8")
        sm = _STATUS_RE.search(text)
        if not sm:
            failures.append(bd_id)
            continue
        status = sm.group(1)
        rm = _RESOLVED_RE.search(text)
        resolved_date = None
        if rm:
            dm = _DATE_RE.search(rm.group(1))
            resolved_date = dm.group(1) if dm else ""
        tm = _TITLE_RE.search(text)
        title = tm.group(1).strip() if tm else bd_id
        src = substantive_src(text)
        # snippet is the O4-capped Archive-row preview; cap it STRICTLY shorter
        # than the full body (≤160, and never the whole src) so a legitimate body
        # is never a false "snippet echo" while a render that copies the emitted
        # snippet into `body` is still caught by the F4 predicate. Case-PRESERVING
        # (collapse_ws, not normalize) so the Archive preview keeps source case;
        # the F4 predicate normalizes both sides, so the cap arithmetic (length-
        # identical to normalize) and the snippet-echo guard are unaffected.
        cs = collapse_ws(src)
        snippet = cs[:min(160, max(1, len(cs) - 1))] if cs else ""
        records[bd_id] = {
            "id": bd_id,
            "num": num,
            "status": status,
            "token": STATUS_TOKEN.get(status, status.lower()),
            "resolved_date": resolved_date,
            "title": title,
            "type": _first_line(_field_block(text, "Type")),
            "target": _first_line(_field_block(text, "Target")),
            "blockers": _first_line(_field_block(text, "Blockers")),
            "unblocks": _first_line(_field_block(text, "Unblocks")),
            "src": src,
            "snippet": snippet,
        }
    return records, failures


def compute_e_full(records):
    """E_full = (every non-terminal BD) ∪ (the 10 most-recently-Resolved, by
    Resolved:-date descending then id descending — OBS-8). BAKED formula."""
    non_terminal = {
        r["id"] for r in records.values() if r["status"] in NON_TERMINAL_STATUSES
    }
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    # OBS-8 tie-break: date desc, then id (num) desc. Empty date sorts last.
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:NEWEST_RESOLVED_N]}
    return non_terminal | newest


def parse_vocab(root):
    """Parse the live backlog/_rules.md `## Lifecycle states admitted` section
    for the canonical Status set (only the `- `X` — <gloss>` bullet shape,
    section-scoped). Empty parse => fail-closed (return empty set; caller FAILs)."""
    rules_path = root / BACKLOG_RULES_REL
    if not rules_path.is_file():
        raise BuildError(f"{BACKLOG_RULES_REL} absent (fail-closed input)")
    lines = rules_path.read_text(encoding="utf-8").splitlines()
    start = None
    end = len(lines)
    for i, ln in enumerate(lines):
        if ln.startswith("## Lifecycle states admitted"):
            start = i
        elif start is not None and ln.startswith("## ") and i > start:
            end = i
            break
    if start is None:
        return set()
    section = "\n".join(lines[start:end])
    return set(_VOCAB_BULLET_RE.findall(section))


def derived_active_ids(session_obj, records):
    """derived_active = {n : "BD-<n>" ∈ active[] prose} ∩ non-terminal (RECONCILED
    §3.4 F6 — the STATUS filter keys on the git-tracked backlog; prose supplies
    only candidate ids)."""
    prose = " ".join(session_obj.get("active", []) or [])
    # Match prose-mentioned ids against actual record ids (handles zero-padding
    # variance), intersected with the non-terminal set (the F6 status filter).
    result = set()
    for m in _BD_ID_RE.findall(prose):
        for candidate in (f"BD-{m}", f"BD-{int(m):03d}"):
            if candidate in records and records[candidate]["status"] in NON_TERMINAL_STATUSES:
                result.add(candidate)
    return result


def git_landings(root, bd_id):
    """Real feat/fix landings for `bd_id` (committed data; reproducible). Returns
    a list of short SHAs. On git error / off a work tree => [] (no committed
    history to floor against)."""
    try:
        out = subprocess.run(
            ["git", "log", "--grep=" + bd_id, "--oneline", "-n", "50",
             "--format=%h %s"],
            capture_output=True, text=True, cwd=root,
        )
    except FileNotFoundError:
        return []
    if out.returncode != 0:
        return []
    shas = []
    for line in out.stdout.splitlines():
        parts = line.split(None, 1)
        if len(parts) != 2:
            continue
        sha, subject = parts
        low = subject.lower()
        if (low.startswith("feat") or low.startswith("fix")) and bd_id.lower() in low:
            shas.append(sha)
    return shas


# ── Source-anchored body predicate (RECONCILED §3.4 F4) ─────────────────────
def _content_words(text):
    return set(re.findall(r"[a-z0-9]{3,}", normalize(text)))


def source_anchored_ok(body, title, snippet, src):
    """True iff `body` is a source-anchored body: len>=40 normalized, not a
    title/snippet echo, and shares a >=20-char shingle OR content-word
    Jaccard>=0.30 with the live source. Returns (ok, reason)."""
    nb = normalize(body)
    if len(nb) < BODY_MIN_NORMALIZED:
        return False, f"body too short ({len(nb)} < {BODY_MIN_NORMALIZED} normalized chars)"
    if nb == normalize(title):
        return False, "body is a title echo"
    if nb == normalize(snippet):
        return False, "body is a snippet echo"
    nsrc = normalize(src)
    shingle_hit = any(
        nb[i:i + SHINGLE_LEN] in nsrc
        for i in range(0, max(0, len(nb) - SHINGLE_LEN) + 1)
    )
    if shingle_hit:
        return True, "shingle match"
    wb, ws = _content_words(body), _content_words(src)
    if wb and ws:
        jacc = len(wb & ws) / len(wb | ws)
        if jacc >= JACCARD_MIN:
            return True, f"jaccard {jacc:.2f}"
    return False, "body is not source-anchored (no shingle, Jaccard below floor)"


def build_body(rec):
    """Draw a source-anchored body from the BD's own live Description/Context,
    case-PRESERVING (collapse_ws, not normalize) so the deep-page prose keeps its
    source case (`**Problem:**`, not `**problem:**`). verify's source-anchor
    predicate normalizes both sides, so the case-preserving store is predicate-safe."""
    return collapse_ws(rec["src"])[:600]


# ── Section sources (READ-FRESH) ────────────────────────────────────────────
def live_rule_count(root):
    claude = root / CLAUDE_REL
    if not claude.is_file():
        return None
    lines = claude.read_text(encoding="utf-8").splitlines()
    start = None
    end = len(lines)
    for i, ln in enumerate(lines):
        if ln.startswith("## Pack memory"):
            start = i
        elif start is not None and ln.startswith("## ") and i > start:
            end = i
            break
    if start is None:
        return None
    section = "\n".join(lines[start:end])
    return len(_RULE_BULLET_RE.findall(section))


def live_changelog_count(root):
    cl = root / "changelog"
    if not cl.is_dir():
        return None
    return len([p for p in cl.glob("v*.md") if not p.name.startswith("_")])


def live_help_present(root):
    for cand in ("pack-ops/HELP-FRAGMENT-PACK.md", "scripts/pack-help.sh"):
        if (root / cand).is_file():
            return True
    return False


def collect_help(root):
    frag = root / "pack-ops/HELP-FRAGMENT-PACK.md"
    if frag.is_file():
        cmds = re.findall(r"`(/?pack-[\w-]+)`", frag.read_text(encoding="utf-8"))
        return {"commands": sorted(set(cmds)) or ["pack-help"]}
    if (root / "scripts/pack-help.sh").is_file():
        return {"commands": ["pack-help"]}
    return {}


def collect_version(root):
    """The CURRENT version, read from the README Version-History TABLE's FIRST data
    row (the top row is the current release — CLAUDE.md § Versioning "the bare
    number is the launched steady state"), NOT the first `vN.N` token anywhere in
    the file (the versioning-convention PROSE above the table carries example
    versions like `v11.0.0` / `v9.1` that would otherwise win). The Version cell is
    `vMAJOR.MINOR[.PATCH]` with an optional ` (qualifier)` display suffix; the Date
    cell is the release date. Version display is cosmetic (not in the verify floored
    set), so an absent/parse-miss table degrades to (None, None, None)."""
    readme = root / "README.md"
    if not readme.is_file():
        return None, None, None
    in_table = False
    for ln in readme.read_text(encoding="utf-8").splitlines():
        if re.match(r"^\|\s*Version\s*\|\s*Date\b", ln):
            in_table = True
            continue
        if not in_table:
            continue
        if re.match(r"^\|\s*:?-+", ln):  # header/body separator row — skip
            continue
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if len(cells) < 2:
            break  # blank line / table ended before a data row
        vm = re.match(r"v(\d+\.\d+(?:\.\d+)?)\s*(?:\(([^)]+)\))?", cells[0])
        if not vm:
            break  # first data row is not a version row — degrade cosmetically
        return vm.group(1), (vm.group(2) or None), (cells[1] or None)
    return None, None, None


# ── State assembly (build) ──────────────────────────────────────────────────
def assemble_state(root):
    records, failures = parse_backlog(root)
    if failures:
        raise BuildError(
            f"{len(failures)} backlog entr(y/ies) have no parseable Status: "
            f"{', '.join(failures)} (fail-closed — 100% parse-coverage required)"
        )
    schema, session_obj = read_schema_token(root)
    e_full = compute_e_full(records)

    counts = {"open": 0, "unblocked": 0, "deferred": 0, "resolved": 0,
              "deprecated": 0, "cancelled": 0, "total": len(records)}
    for r in records.values():
        key = r["status"].lower()
        if key in counts:
            counts[key] += 1

    bds = {}
    for bd_id, r in records.items():
        tier = "full" if bd_id in e_full else "minimal"
        rec = {
            "id": r["id"], "num": r["num"], "title": r["title"],
            "status": r["token"], "tier": tier, "snippet": r["snippet"],
            "type": r["type"], "target": r["target"],
            "blockers": r["blockers"], "unblocks": r["unblocks"],
        }
        if tier == "full":
            rec["body"] = build_body(r)
        bds[bd_id] = rec

    # plans{}: the committed-history FLOOR ONLY (ratified spec EDIT B). Every
    # derived-active / newest-10 Resolved BD with real `git log --grep` feat/fix
    # landings gets a stub evidence record. This is the CONFORMANCE floor that
    # verify + the mechanical CI floor (Check 89) bite on; richer wave/step
    # structure (a multi-source plan-doc merge, real progress{done,total}) is
    # BEST-EFFORT ABOVE this floor, NOT a conformance requirement. On the PACK
    # surface the best-effort plan-doc sweep is a no-op: pack BDs are single-file
    # backlog/BD-NNN.md entries with no per-BD plan-doc tree (unlike the project-
    # side implementation-plan/ stream), so the committed git landings ARE the
    # pack's plan-progress source and the stub progress:{done:0,total:0} is
    # intentional — a floored evidence record, not an unfinished TODO.
    da = derived_active_ids(session_obj, records)
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:NEWEST_RESOLVED_N]}
    plans = {}
    for bd_id in sorted(da | newest):
        shas = git_landings(root, bd_id)
        if shas:
            plans[bd_id] = {
                "sizeTier": "small",
                "progress": {"done": 0, "total": 0},
                "evidence": shas,
            }

    version, qualifier, date = collect_version(root)
    state = {
        "version": version, "qualifier": qualifier, "date": date,
        "counts": counts,
        "metrics": {"resolved": counts["resolved"], "total": counts["total"],
                    "pct": round(100 * counts["resolved"] / counts["total"])
                    if counts["total"] else 0},
        "bds": bds,
        "plans": plans,
        "rules": [{"i": i} for i in range(live_rule_count(root) or 0)],
        "changelog": [{"i": i} for i in range(live_changelog_count(root) or 0)],
        "help": collect_help(root),
    }
    return state


def serialize_state(state):
    txt = json.dumps(state, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    # O9: for the JSON-<script> path only `<` (the `</script` breakout) must be
    # escaped; `<` round-trips through json.loads.
    return txt.replace("<", "\\u003c")


def provenance_line(spec_sha, structure_sha):
    return (
        "<!-- pack-dashboard shell · spec: " + SPEC_REL + " · spec-sha: "
        + spec_sha + " · structure-sha: " + structure_sha + " -->"
    )


def synth_shell(prov):
    """A MINIMAL fail-safe shell (bare <main></main> + an empty `#state` script),
    synthesized ONLY when no fingerprint-matching rich shell exists (do_build's
    reuse arm). It is a richness FLOOR, NOT the intended presentation: the rich,
    styled shell is authored at RUNTIME by the `dashboard-render` skill (RECONCILED
    §2.1) and, once committed with matching {spec-sha, structure-sha} fingerprints,
    is REUSED verbatim by do_build (this fallback never overwrites it). A minimal
    shell still carries the FULLY-FLOORED `#state` — verify PASSes on it — so the
    gap over a rich shell is presentation richness, never data loss. The
    render-skill authorship + first committed rich shell are the render/first-render
    commits' concern, above this committed-floor script."""
    return (
        "<!DOCTYPE html>\n" + prov + "\n"
        '<html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        "<title>Pack frontier — Optiquity Config Pack dashboard</title></head>\n"
        "<body><main></main>\n"
        '<script type="application/json" id="state"></script>\n'
        "</body></html>\n"
    )


def inject_state(shell_html, state_txt):
    if not _STATE_SCRIPT_RE.search(shell_html):
        return None
    return _STATE_SCRIPT_RE.sub(
        lambda m: m.group(1) + state_txt + m.group(3), shell_html, count=1
    )


def shell_fingerprints(text):
    sm = PROV_SPEC_RE.search(text)
    stm = PROV_STRUCT_RE.search(text)
    return (sm.group(1) if sm else None, stm.group(1) if stm else None)


def do_build(root):
    spec_sha = compute_spec_sha(root)
    structure_sha = compute_structure_sha(root)
    state = assemble_state(root)
    state_txt = serialize_state(state)
    prov = provenance_line(spec_sha, structure_sha)

    approvals = root / APPROVALS_DIR_REL
    approvals.mkdir(parents=True, exist_ok=True)
    shell_path = root / DASHBOARD_SHELL_REL

    # Reuse an existing shell only when BOTH fingerprints already match live;
    # else synthesize a fresh minimal shell and (re)write it.
    reuse = False
    if shell_path.is_file():
        s_spec, s_struct = shell_fingerprints(shell_path.read_text(encoding="utf-8"))
        reuse = (s_spec == spec_sha and s_struct == structure_sha)
    if reuse:
        shell_html = shell_path.read_text(encoding="utf-8")
    else:
        shell_html = synth_shell(prov)
        shell_path.write_text(shell_html, encoding="utf-8")

    dashboard = inject_state(shell_html, state_txt)
    if dashboard is None:
        raise BuildError(
            "render shell carries no `<script id=\"state\">` element to inject "
            "into (fail-closed)"
        )
    (root / DASHBOARD_HTML_REL).write_text(dashboard, encoding="utf-8")

    full_count = sum(1 for r in state["bds"].values() if r["tier"] == "full")
    print(
        f"build: wrote {DASHBOARD_HTML_REL} — {len(state['bds'])} bds "
        f"({full_count} tier:full), {len(state['plans'])} plans; "
        f"spec-sha {spec_sha[:12]}… structure-sha {structure_sha[:12]}… "
        f"(shell {'reused' if reuse else 'synthesized'})"
    )
    return 0


# ── verify (the fail-closed oracle) ─────────────────────────────────────────
def do_verify(root):
    failures = []

    def fail(msg):
        failures.append(msg)

    dashboard_path = root / DASHBOARD_HTML_REL
    if not dashboard_path.is_file():
        print(f"verify: FAIL — {DASHBOARD_HTML_REL} absent (nothing to verify; "
              f"fail-closed)")
        return 1
    html = dashboard_path.read_text(encoding="utf-8")

    # Provenance (fingerprints).
    render_spec, render_struct = shell_fingerprints(html)
    if not render_spec or not render_struct:
        fail("render carries no {spec-sha, structure-sha} provenance line")

    # #state (black-box parse).
    sm = _STATE_SCRIPT_RE.search(html)
    if not sm:
        print(f"verify: FAIL — no `<script id=\"state\">` element in "
              f"{DASHBOARD_HTML_REL} (fail-closed)")
        return 1
    try:
        state = json.loads(sm.group(2))
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"verify: FAIL — `#state` is not parseable JSON ({exc}; fail-closed)")
        return 1

    # Re-derive fresh from the live tree (INDEPENDENT of build's in-memory objects).
    try:
        records, parse_failures = parse_backlog(root)
        schema, session_obj = read_schema_token(root)
        live_spec = compute_spec_sha(root)
        live_struct = compute_structure_sha(root)
        vocab = parse_vocab(root)
    except BuildError as exc:
        print(f"verify: FAIL — {exc}")
        return 1

    # Assertion C — fingerprint match (render stamped == freshly re-derived live).
    if render_struct and render_struct != live_struct:
        fail(f"structure-sha mismatch: render {render_struct[:12]}… != live "
             f"{live_struct[:12]}… (a format-contract change since the render)")
    if render_spec and render_spec != live_spec:
        fail(f"spec-sha mismatch: render {render_spec[:12]}… != live "
             f"{live_spec[:12]}… (the spec changed since the render)")

    # Assertion B — 100% parse-coverage.
    if parse_failures:
        fail(f"parse-coverage < 100%: {len(parse_failures)} BD(s) with no parseable "
             f"Status: {', '.join(parse_failures)}")

    # Assertion A — Status-vocabulary CLOSURE.
    if not vocab:
        fail("Status-vocabulary parse extracted 0 states from backlog/_rules.md "
             "(reformat broke it) — fail-closed")
    else:
        extra_vocab = vocab - KNOWN_STATUS_UNIVERSE
        if extra_vocab:
            fail(f"live vocab carries canonical status(es) the tier-map cannot "
                 f"place: {sorted(extra_vocab)} — fail-closed")
        offvocab = {r["status"] for r in records.values()
                    if r["status"] not in vocab}
        if offvocab:
            fail(f"backlog Status value(s) outside the live vocab: "
                 f"{sorted(offvocab)} — fail-closed")

    # Assertion B (cont.) — total accountability (render.bds covers exactly the tree).
    state_bds = state.get("bds", {})
    if not isinstance(state_bds, dict):
        fail("`#state.bds` is not an object")
        state_bds = {}
    live_ids = set(records.keys())
    render_ids = set(state_bds.keys())
    dropped = live_ids - render_ids
    extra = render_ids - live_ids
    if dropped:
        fail(f"render dropped {len(dropped)} live BD(s): {sorted(dropped)[:8]} "
             f"(total-accountability fail-closed)")
    if extra:
        fail(f"render carries {len(extra)} phantom BD(s) not in the tree: "
             f"{sorted(extra)[:8]} (fail-closed)")

    # Assertion D — the E_full full-set floor + source-anchored bodies.
    e_full = compute_e_full(records)
    render_full = {bid for bid, r in state_bds.items()
                   if isinstance(r, dict) and r.get("tier") == "full"}
    missing = e_full - render_full
    surplus = render_full - e_full
    if missing:
        fail(f"E_full floor: {len(missing)} member(s) not marked tier:full — "
             f"{sorted(missing)[:8]} (deterministic work skipped)")
    if surplus:
        fail(f"E_full floor: {len(surplus)} tier:full record(s) outside E_full — "
             f"{sorted(surplus)[:8]}")
    for bid in sorted(render_full & e_full):
        rec = state_bds[bid]
        r = records.get(bid)
        if not r:
            continue
        ok, reason = source_anchored_ok(
            rec.get("body", ""), rec.get("title", ""), rec.get("snippet", ""), r["src"]
        )
        if not ok:
            fail(f"{bid} tier:full body is not source-anchored ({reason})")

    # plans floor — committed-history: each derived-active / newest-10 Resolved BD
    # with real feat/fix landings MUST appear in `#state.plans`.
    render_plans = state.get("plans", {})
    if not isinstance(render_plans, dict):
        fail("`#state.plans` is not an object")
        render_plans = {}
    da = derived_active_ids(session_obj, records)
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:NEWEST_RESOLVED_N]}
    for bid in sorted(da | newest):
        if git_landings(root, bid) and bid not in render_plans:
            fail(f"plans floor: {bid} has committed feat/fix landings but is "
                 f"absent from `#state.plans` (fail-closed)")

    # Section floors (RECONCILED §3.6, presence-driven).
    metrics = state.get("metrics", {})
    live_resolved = sum(1 for r in records.values() if r["status"] == "Resolved")
    if metrics.get("resolved") != live_resolved:
        fail(f"metrics.resolved {metrics.get('resolved')} != live {live_resolved}")
    if metrics.get("total") != len(records):
        fail(f"metrics.total {metrics.get('total')} != live {len(records)}")
    rc = live_rule_count(root)
    if rc is not None and len(state.get("rules", [])) != rc:
        fail(f"rules[] count {len(state.get('rules', []))} != live "
             f"CLAUDE.md ## Pack memory count {rc}")
    cc = live_changelog_count(root)
    if cc is not None and len(state.get("changelog", [])) != cc:
        fail(f"changelog[] count {len(state.get('changelog', []))} != live "
             f"/changelog/ major-version file count {cc}")
    if live_help_present(root) and not state.get("help"):
        fail("help{} is empty but a help source exists")

    if failures:
        print(f"verify: FAIL — {len(failures)} shortfall(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(
        f"verify: PASS — {len(live_ids)} BDs (100% parse-coverage), "
        f"|E_full|={len(e_full)} tier:full source-anchored, vocab-closed, "
        f"structure-sha {live_struct[:12]}… matched, plans floor + section floors OK"
    )
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="dashboard-build.py",
        description="The sanctioned committed build/verify script for /pack-dashboard.",
    )
    parser.add_argument("mode", choices=["build", "verify"])
    parser.add_argument("--repo-root", default=None,
                        help="repo root (default: git toplevel of this script)")
    args = parser.parse_args(argv)
    root = resolve_repo_root(args.repo_root)
    try:
        if args.mode == "build":
            return do_build(root)
        return do_verify(root)
    except BuildError as exc:
        print(f"{args.mode}: FAIL — {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
