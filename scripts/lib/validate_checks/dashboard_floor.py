"""validate_checks.dashboard_floor — Check 89: the committed /pack-dashboard
content floor (BD-224 OPTION-2 reconciled model), DEEP-gated.

This module owns the ONE mechanical, agent-INDEPENDENT CI backstop for the
/pack-dashboard render-cache (ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §3.4 +
§6.2). It re-derives `E_full` and the render floors in its OWN coder-authored
code and does NOT import `scripts/dashboard-build.py` — the GENUINE-INDEPENDENCE
property (§3.4): two independent derivations that must AGREE on a conformant
render. A bug in the script's shared `build`/`verify` derivation surfaces here as
a DIVERGENCE between the committed render and this re-derivation → FAIL CLOSED.
Check 89 is the un-fakeable gate that holds even when the render-time `verify` was
skipped or faked (the historical 0/54 incident is blocked at CI).

What it floors over the COMMITTED `pack-ops/dashboard-approvals/dashboard.html`
`#state` (the black-box JSON payload):

  - Total accountability + 100% parse-coverage (§3.3 Assertion B): every enumerated
    `backlog/BD-NNN.md` yields (id + parseable `Status:`) AND appears in
    `#state.bds`; a dropped/extra id or an unparseable Status → FAIL CLOSED.
  - Status-vocabulary CLOSURE (§3.2 Assertion A): the live `backlog/_rules.md`
    `## Lifecycle states admitted` vocab ⊆ the known tier-map universe, and every
    live BD Status ∈ that vocab; a NEW canonical status the tier-map cannot place
    → FAIL CLOSED.
  - The `E_full` full-set floor (§3.4 Assertion D): the set of `tier:"full"` ids ==
    the freshly re-derived `E_full` membership — `E_full` = (every non-terminal BD)
    ∪ (the 10 most-recently-`Resolved`, by `Resolved:`-date DESC then id DESC —
    the OBS-8 tie-break, a load-bearing invariant, §3.4 F5). A shortfall means
    deterministic work was skipped → FAIL.
  - Source-anchored bodies (§3.4 F4): each `tier:"full"` record carries a body that
    is ≥40 normalized chars, NOT a title/snippet echo, and shares a ≥20-char
    shingle OR content-word Jaccard ≥ 0.30 with the live `backlog/BD-NNN.md`
    Description/Context source — a strengthened, source-anchored fidelity check
    (declare-verify-backing: floors the LOAD-BEARING content, not a spoofable
    "non-empty" proxy).
  - The committed-history plans floor (§3.4, best-effort-respecting): each
    derived-active (`session-state.json active[]` prose ∩ non-terminal) / newest-10
    Resolved BD with real `git log --grep=BD-NNN` feat/fix landings MUST appear in
    `#state.plans` — keys on committed data only, so it is reproducible and safe to
    hard-FAIL (catches `plans{}=0` while an active BD has landed commits).
  - The read-fresh SECTION floors (§3.6): `metrics{resolved,total}` == the live
    backlog tally; `rules[]` count == the live `CLAUDE.md ## Pack memory` rule-bullet
    count; `changelog[]` count == the live `/changelog/` major-version file count;
    `help{}` non-empty when a help source exists. `deps[]` is NOT count-floored
    (§3.6: best-effort — a BD may legitimately have no blockers).

DEEP-gated (PACK_VALIDATE_DEEP=1, mirroring Check 49): the O(entries) cost — one
`git ls-files backlog/` + bounded per-file reads + one `#state` JSON parse +
O(active) `git log --grep` — runs ONLY in the DEEP battery, so the light battery
stays fast (ci-check-runtime-compounding). Per-commit verification runs DEEP anyway
(verify-full-ci-suite). Candidates come from `git ls-files` (never a raw FS walk —
ci-guard-measure-then-bound); SKIP-lenient off a git work tree and when no render is
committed (the approvals dir is untracked until the first render lands, so the check
lands BEFORE the render and BITES once it commits).

Own module per the FIRM own-module-per-new-check convention
(`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION") — it shares no
non-core symbol with any cluster (its candidate surfaces —
pack-ops/dashboard-approvals/dashboard.html + the live backlog/changelog/CLAUDE.md
— and its independent derivation belong to no existing cluster) and, critically,
shares NO code with `scripts/dashboard-build.py` (the independence that IS the
backstop). Bodies + helpers live only here; the facade (`scripts/validate-pack.py`)
re-exports `check_dashboard_committed_floor` via `from
validate_checks.dashboard_floor import *`, so `_build_check_registry()` resolves the
bare name. Single SSOT — no forked copy.

Spine: `REPO_ROOT`, `fail`, `failures`, `ok` are imported `from .core` (the single
SSOT for the spine). The module-private `_git_ls_files()` resolves the git root via
`cwd=REPO_ROOT` (the module constant), so a per-check test can monkeypatch
`dashboard_floor.REPO_ROOT` to a /tmp scratch repo (the Check 63 technique). The
module is definitions + literals only (no load-time CALL), so it imports standalone
with no `NameError` (the MUST-3 load-time-order contract).

See `scripts/lib/validate_checks/README.md` and
`~/Developer/_tmp/pack-bd224-design/ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md`.
"""

import json
import os
import re
import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    failures,
    ok,
)

# ── Independent spec-derived constants (re-authored here — NOT imported from
# scripts/dashboard-build.py; the genuine-independence property means this module
# shares NO code with the build script). Values mirror the reconciled §3 model. ──
# The six canonical lifecycle states the tier-map handles (§3.2 known universe).
_KNOWN_STATUS_UNIVERSE = frozenset(
    {"Open", "Unblocked", "Deferred", "Resolved", "Deprecated", "Cancelled"}
)
# Non-terminal = unresolved + revivable (the E_full non-terminal arm).
_NON_TERMINAL_STATUSES = frozenset({"Open", "Unblocked", "Deferred"})
_NEWEST_RESOLVED_N = 10  # E_full newest-Resolved arm size (OBS-8).
_BODY_MIN_NORMALIZED = 40  # source-anchored body floor (§3.4 F4).
_SHINGLE_LEN = 20  # contiguous shingle length for the source-anchor test.
_JACCARD_MIN = 0.30  # content-word Jaccard floor (fallback anchor test).

_DASHBOARD_HTML = "pack-ops/dashboard-approvals/dashboard.html"
_BACKLOG_DIR = "backlog"
_BACKLOG_RULES = "backlog/_rules.md"
_CHANGELOG_DIR = "changelog"
_SESSION_STATE = "pack-ops/session-state.json"
_CLAUDE = "CLAUDE.md"
_HELP_FRAGMENT = "pack-ops/HELP-FRAGMENT-PACK.md"
_PACK_HELP = "scripts/pack-help.sh"

_STATE_SCRIPT_RE = re.compile(r'(<script[^>]*id="state"[^>]*>)(.*?)(</script>)', re.S)
_STATUS_RE = re.compile(r"^Status:\s*(\w+)", re.M)
_RESOLVED_RE = re.compile(r"^Resolved:\s*(.+)$", re.M)
_DATE_RE = re.compile(r"(20\d\d-\d\d-\d\d)")
_TITLE_RE = re.compile(r"^\*\*BD-\d+\s*[—-]\s*(.+?)\*\*", re.M)
_BD_ID_RE = re.compile(r"BD-(\d+)")
_BD_FILE_RE = re.compile(r"^backlog/BD-\d+\.md$")
# The vocab bullet shape (§3.2 F9): dash + single backticked word + em-dash gloss.
_VOCAB_BULLET_RE = re.compile(r"^- `([A-Za-z]+)`\s*—", re.M)
# A rule bullet in CLAUDE.md ## Pack memory (§3.6): a top-level `- **`.
_RULE_BULLET_RE = re.compile(r"^- \*\*", re.M)
# Short metadata field labels stripped from the substantive-body fallback.
_META_FIELD_RE = re.compile(
    r"^(Type|Status|Target|Blockers|Unblocks|Resolved|Position|File/Symbol|"
    r"References|Source|Disposition):"
)


# ── Module-private git helper (candidates via git ls-files; SKIP off a work tree) ─
def _git_ls_files(pathspec):
    """Return `(available, tracked_paths)` for `git ls-files <pathspec>` at
    REPO_ROOT. `available` is False when git is absent OR the tree is not a git
    work tree (caller SKIPs lenient). ONE bounded subprocess; O(files under the
    pathspec); never a whole-tree scan (ci-guard-measure-then-bound)."""
    try:
        result = subprocess.run(
            ["git", "ls-files", pathspec],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [line for line in result.stdout.splitlines() if line.strip()])


def _git_landings(bd_id):
    """Real feat/fix landings for `bd_id` (committed data; reproducible). Returns a
    list of short SHAs; [] on git error / off a work tree (no committed history to
    floor against)."""
    try:
        out = subprocess.run(
            ["git", "log", "--grep=" + bd_id, "--oneline", "-n", "50",
             "--format=%h %s"],
            capture_output=True, text=True, cwd=REPO_ROOT,
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


# ── Independent text helpers (re-authored; mirror the §3 logic) ─────────────
def _normalize(text):
    return " ".join((text or "").lower().split())


def _content_words(text):
    return set(re.findall(r"[a-z0-9]{3,}", _normalize(text)))


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


def _bd_source(text):
    """The BD's substantive prose body (the source a tier:full body must anchor
    to). Prefer named Description/Context; when neither is populated, fall back to
    the entry's flush-left prose with the back-pointer, bold header, short metadata
    fields, and indented sub-bullets stripped. Mirrors dashboard-build.py's
    substantive_src() logic (re-authored, not imported)."""
    desc = _field_block(text, "Description")
    ctx = _field_block(text, "Context")
    primary = (desc + " " + ctx).strip()
    if len(_normalize(primary)) >= _BODY_MIN_NORMALIZED:
        return primary
    kept = []
    for ln in text.splitlines():
        if ln.startswith("<!--") or ln.startswith("**BD-"):
            continue
        if _META_FIELD_RE.match(ln):
            continue
        if ln[:1] in (" ", "\t"):
            continue
        if ln.strip():
            kept.append(ln.strip())
    return " ".join(kept).strip()


def _source_anchored(body, title, snippet, src):
    """True iff `body` is source-anchored: len≥40 normalized, not a title/snippet
    echo, and shares a ≥20-char shingle OR content-word Jaccard≥0.30 with the live
    source. Returns (ok, reason)."""
    nb = _normalize(body)
    if len(nb) < _BODY_MIN_NORMALIZED:
        return False, f"body too short ({len(nb)} < {_BODY_MIN_NORMALIZED} normalized chars)"
    if nb == _normalize(title):
        return False, "body is a title echo"
    if nb == _normalize(snippet):
        return False, "body is a snippet echo"
    nsrc = _normalize(src)
    shingle_hit = any(
        nb[i:i + _SHINGLE_LEN] in nsrc
        for i in range(0, max(0, len(nb) - _SHINGLE_LEN) + 1)
    )
    if shingle_hit:
        return True, "shingle match"
    wb, ws = _content_words(body), _content_words(src)
    if wb and ws:
        jacc = len(wb & ws) / len(wb | ws)
        if jacc >= _JACCARD_MIN:
            return True, f"jaccard {jacc:.2f}"
    return False, "body is not source-anchored (no shingle, Jaccard below floor)"


# ── Independent backlog parse + E_full derivation (re-authored) ─────────────
def _parse_backlog(bd_paths):
    """Return (records dict keyed by id, parse_failures list). Each record:
    {id, num, status, resolved_date, title, src}. A BD file with no parseable
    Status is a parse failure (fail-closed)."""
    records = {}
    failures_local = []
    for rel in bd_paths:
        path = Path(REPO_ROOT) / rel
        bd_id = path.stem  # BD-NNN
        m = _BD_ID_RE.match(bd_id)
        if not m:
            continue
        num = int(m.group(1))
        try:
            body_text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            failures_local.append(bd_id)
            continue
        sm = _STATUS_RE.search(body_text)
        if not sm:
            failures_local.append(bd_id)
            continue
        status = sm.group(1)
        rm = _RESOLVED_RE.search(body_text)
        resolved_date = None
        if rm:
            dm = _DATE_RE.search(rm.group(1))
            resolved_date = dm.group(1) if dm else ""
        tm = _TITLE_RE.search(body_text)
        title = tm.group(1).strip() if tm else bd_id
        records[bd_id] = {
            "id": bd_id, "num": num, "status": status,
            "resolved_date": resolved_date, "title": title,
            "src": _bd_source(body_text),
        }
    return records, failures_local


def _compute_e_full(records):
    """E_full = (every non-terminal BD) ∪ (the 10 most-recently-Resolved, by
    Resolved:-date DESC then id DESC — OBS-8). Re-authored independently."""
    non_terminal = {
        r["id"] for r in records.values() if r["status"] in _NON_TERMINAL_STATUSES
    }
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:_NEWEST_RESOLVED_N]}
    return non_terminal | newest


def _parse_vocab():
    """Parse the live backlog/_rules.md `## Lifecycle states admitted` section for
    the canonical Status set (only the `- `X` — <gloss>` bullet shape,
    section-scoped). Empty parse => fail-closed (return empty set; caller FAILs)."""
    rules_path = Path(REPO_ROOT) / _BACKLOG_RULES
    if not rules_path.is_file():
        return set()
    lines = rules_path.read_text(encoding="utf-8", errors="replace").splitlines()
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


def _derived_active_ids(records):
    """derived_active = {n : "BD-<n>" ∈ session-state active[] prose} ∩ non-terminal
    (§3.4 F6). The STATUS filter keys on the git-tracked backlog; prose supplies
    only candidate ids. Missing/unparseable session-state ⇒ empty set."""
    ss_path = Path(REPO_ROOT) / _SESSION_STATE
    try:
        obj = json.loads(ss_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return set()
    prose = " ".join(obj.get("active", []) or [])
    result = set()
    for m in _BD_ID_RE.findall(prose):
        for candidate in (f"BD-{m}", f"BD-{int(m):03d}"):
            if candidate in records and records[candidate]["status"] in _NON_TERMINAL_STATUSES:
                result.add(candidate)
    return result


def _live_rule_count():
    claude = Path(REPO_ROOT) / _CLAUDE
    if not claude.is_file():
        return None
    lines = claude.read_text(encoding="utf-8", errors="replace").splitlines()
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


def _live_changelog_count():
    cl = Path(REPO_ROOT) / _CHANGELOG_DIR
    if not cl.is_dir():
        return None
    return len([p for p in cl.glob("v*.md") if not p.name.startswith("_")])


def _live_help_present():
    for cand in (_HELP_FRAGMENT, _PACK_HELP):
        if (Path(REPO_ROOT) / cand).is_file():
            return True
    return False


def check_dashboard_committed_floor() -> None:
    """Check 89 — the committed /pack-dashboard content floor (BD-224, DEEP).

    DEEP-GATED: runs the O(entries) re-derivation + floor ONLY under
    PACK_VALIDATE_DEEP=1 (§6.2, mirroring Check 49); the default path is a ~0 ms
    SKIP. Re-derives `E_full` INDEPENDENTLY of scripts/dashboard-build.py (its own
    coder-authored derivation) and HARD-FLOORS the COMMITTED
    pack-ops/dashboard-approvals/dashboard.html `#state`: total accountability +
    parse-coverage, Status-vocabulary closure, the E_full full-set floor,
    source-anchored bodies, the committed-history plans floor, and the read-fresh
    section floors (§3.2–3.6). Fail-closed on any unaccountable input (a new Status
    value, a dropped BD, an unparseable Status) and any shortfall.

    measure-then-bound (ci-guard-measure-then-bound): candidates via `git ls-files`
    (never a raw FS walk); SKIP off a git work tree; SKIP-lenient when no render is
    committed (the approvals dir is untracked until the first render lands, so the
    check lands BEFORE the render and BITES once it commits). O(entries),
    DEEP-gated — no whole-tree scan (ci-check-runtime-compounding).
    """
    # (P) ENV-GATE — the FIRST statement, BEFORE any tree read. The general
    # battery early-returns here paying ~0.
    if os.environ.get("PACK_VALIDATE_DEEP") != "1":
        ok("SKIP: dashboard content-floor deep check (set PACK_VALIDATE_DEEP=1)")
        return

    print("\n── Check 89: committed /pack-dashboard content floor (BD-224, DEEP) ──")

    # measure-then-bound: candidates via git ls-files; SKIP off a work tree.
    available, tracked = _git_ls_files(_DASHBOARD_HTML)
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return
    if _DASHBOARD_HTML not in set(tracked):
        ok(
            "pack-ops/dashboard-approvals/dashboard.html is not tracked (no render "
            "committed yet / fresh runtime state) — skipping (lenient)"
        )
        return

    # Parse the committed render's #state (black box).
    html_path = Path(REPO_ROOT) / _DASHBOARD_HTML
    try:
        html = html_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        ok("pack-ops/dashboard-approvals/dashboard.html is tracked but unreadable — skipping (lenient)")
        return
    sm = _STATE_SCRIPT_RE.search(html)
    if not sm:
        fail(
            "Check 89 — pack-ops/dashboard-approvals/dashboard.html carries no "
            "`<script id=\"state\">` element (fail-closed; the render is malformed)."
        )
        return
    try:
        state = json.loads(sm.group(2))
    except (ValueError, json.JSONDecodeError) as exc:
        fail(
            f"Check 89 — the committed dashboard.html `#state` is not parseable JSON "
            f"({exc}; fail-closed)."
        )
        return

    # Re-derive FRESH from the live tree (INDEPENDENT of the render / the script).
    bl_available, bl_tracked = _git_ls_files(_BACKLOG_DIR + "/")
    if not bl_available:
        ok("git ls-files backlog/ unavailable (not a git work tree) — skipping (lenient)")
        return
    bd_paths = sorted(rel for rel in bl_tracked if _BD_FILE_RE.match(rel))
    if not bd_paths:
        ok("no tracked backlog/BD-*.md entries — skipping (lenient)")
        return
    records, parse_failures = _parse_backlog(bd_paths)

    pre = len(failures)

    # Assertion B — 100% parse-coverage.
    if parse_failures:
        fail(
            f"Check 89 — parse-coverage < 100%: {len(parse_failures)} backlog "
            f"BD(s) with no parseable Status: {sorted(parse_failures)[:8]} "
            f"(fail-closed — total-accountability requires 100% coverage)."
        )

    # Assertion A — Status-vocabulary CLOSURE.
    vocab = _parse_vocab()
    if not vocab:
        fail(
            "Check 89 — Status-vocabulary parse extracted 0 states from "
            "backlog/_rules.md `## Lifecycle states admitted` (reformat broke it) — "
            "fail-closed."
        )
    else:
        extra_vocab = vocab - _KNOWN_STATUS_UNIVERSE
        if extra_vocab:
            fail(
                f"Check 89 — the live vocab carries canonical status(es) the "
                f"tier-map cannot place: {sorted(extra_vocab)} — fail-closed (a NEW "
                f"Status value needs a tier-map + this check update)."
            )
        offvocab = {r["status"] for r in records.values() if r["status"] not in vocab}
        if offvocab:
            fail(
                f"Check 89 — backlog Status value(s) outside the live vocab: "
                f"{sorted(offvocab)} — fail-closed."
            )

    # Assertion B (cont.) — total accountability: render.bds covers exactly the tree.
    state_bds = state.get("bds", {})
    if not isinstance(state_bds, dict):
        fail("Check 89 — `#state.bds` is not an object (fail-closed).")
        state_bds = {}
    live_ids = set(records.keys())
    render_ids = set(state_bds.keys())
    dropped = live_ids - render_ids
    extra = render_ids - live_ids
    if dropped:
        fail(
            f"Check 89 — the committed render dropped {len(dropped)} live BD(s): "
            f"{sorted(dropped)[:8]} (total-accountability fail-closed)."
        )
    if extra:
        fail(
            f"Check 89 — the committed render carries {len(extra)} phantom BD(s) not "
            f"in the tree: {sorted(extra)[:8]} (fail-closed)."
        )

    # Assertion D — the E_full full-set floor + source-anchored bodies.
    e_full = _compute_e_full(records)
    render_full = {
        bid for bid, r in state_bds.items()
        if isinstance(r, dict) and r.get("tier") == "full"
    }
    missing = e_full - render_full
    surplus = render_full - e_full
    if missing:
        fail(
            f"Check 89 — E_full floor: {len(missing)} of |E_full|={len(e_full)} "
            f"member(s) not marked tier:full — {sorted(missing)[:8]} (deterministic "
            f"work skipped; the committed render is short, e.g. the 0/54 or 41/54 "
            f"incident)."
        )
    if surplus:
        fail(
            f"Check 89 — E_full floor: {len(surplus)} tier:full record(s) outside "
            f"E_full — {sorted(surplus)[:8]} (fail-closed)."
        )
    for bid in sorted(render_full & e_full):
        rec = state_bds[bid]
        r = records.get(bid)
        if not r:
            continue
        ok_body, reason = _source_anchored(
            rec.get("body", ""), rec.get("title", ""), rec.get("snippet", ""), r["src"]
        )
        if not ok_body:
            fail(
                f"Check 89 — {bid} tier:full body is not source-anchored ({reason}) "
                f"— a vacuous / title-echo / fabricated body (fail-closed)."
            )

    # Plans floor — committed-history: each derived-active / newest-10 Resolved BD
    # with real feat/fix landings MUST appear in `#state.plans`.
    render_plans = state.get("plans", {})
    if not isinstance(render_plans, dict):
        fail("Check 89 — `#state.plans` is not an object (fail-closed).")
        render_plans = {}
    da = _derived_active_ids(records)
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:_NEWEST_RESOLVED_N]}
    for bid in sorted(da | newest):
        if _git_landings(bid) and bid not in render_plans:
            fail(
                f"Check 89 — plans floor: {bid} has committed feat/fix landings but "
                f"is absent from `#state.plans` (fail-closed)."
            )

    # Section floors (§3.6, presence-driven).
    metrics = state.get("metrics", {})
    if not isinstance(metrics, dict):
        fail("Check 89 — `#state.metrics` is not an object (fail-closed).")
        metrics = {}
    live_resolved = sum(1 for r in records.values() if r["status"] == "Resolved")
    if metrics.get("resolved") != live_resolved:
        fail(
            f"Check 89 — metrics.resolved {metrics.get('resolved')} != live "
            f"{live_resolved} (section floor)."
        )
    if metrics.get("total") != len(records):
        fail(
            f"Check 89 — metrics.total {metrics.get('total')} != live "
            f"{len(records)} (section floor)."
        )
    rc = _live_rule_count()
    if rc is not None and len(state.get("rules", []) or []) != rc:
        fail(
            f"Check 89 — rules[] count {len(state.get('rules', []) or [])} != live "
            f"CLAUDE.md ## Pack memory rule-bullet count {rc} (section floor — a "
            f"blanked/short rules page)."
        )
    cc = _live_changelog_count()
    if cc is not None and len(state.get("changelog", []) or []) != cc:
        fail(
            f"Check 89 — changelog[] count {len(state.get('changelog', []) or [])} "
            f"!= live /changelog/ major-version file count {cc} (section floor — a "
            f"missing version panel)."
        )
    if _live_help_present() and not state.get("help"):
        fail("Check 89 — help{} is empty but a help source exists (section floor).")

    if len(failures) == pre:
        ok(
            f"Check 89 — committed dashboard.html floors satisfied: {len(live_ids)} "
            f"BDs (100% parse-coverage, vocab-closed), |E_full|={len(e_full)} "
            f"tier:full source-anchored, plans floor + section floors OK."
        )


# ── __all__ — the check body the facade's _build_check_registry() resolves ──
# `from validate_checks.dashboard_floor import *` skips underscore names UNLESS
# listed here; once `__all__` is declared it ALSO gates the non-underscore names —
# so the ONE public `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The module-private helpers +
# `_*` constants stay module-internal (`import *` skips underscore names anyway).
__all__ = [
    "check_dashboard_committed_floor",
]
