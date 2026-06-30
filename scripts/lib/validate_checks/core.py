"""validate_checks.core — shared validator spine + 8 cross-module seams.

This module owns the cross-module SPINE and the 8 cross-module SEAM symbols of
the pack structural validator (`scripts/validate-pack.py`). The facade
re-exports every symbol here via `from validate_checks.core import *`, so a bare
reference to `REPO_ROOT`/`failures`/`fail`/`run_check`/the seams in the
still-inline check bodies (and in `_build_check_registry()` / `main()`) resolves
from this single SSOT — no forked copy.

Spine: `REPO_ROOT`, `failures`, `fail`/`ok`/`warn`, `run_check`,
`_check_timings`, the `RUN_CHECK_*` budget constants, and
`CHECK_REGISTRY_EXPECTED_COUNT`.

8 cross-module seams (each consumed by a check that lands in a LATER BD-256
wave; the consuming check imports its seam `from .core import …`): `STREAMS`,
`README`, `_session_state_load` + the `_SESSION_STATE_*` constants,
`_PACK_CHAT_ONLY_PERMITTED_PATHS`, `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`,
`_TRACKER_BACKENDS`, `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`.

Load-time-order contract (MUST-3 / README.md): this module is DEFINITIONS +
LITERALS only — it has NO load-time function CALLS. Symbols derived at load
time from another symbol (`README = REPO_ROOT / "README.md"`, `STREAMS`, the
`_SESSION_STATE_*` block) are defined AFTER what they derive from. See
`scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import tomllib
from pathlib import Path

# REPO_ROOT — the repo root, derived from this module's location.
#
# NOTE (BD-256 W1 — the ONE non-byte-identical relocation): the facade
# (`scripts/validate-pack.py`) computed `REPO_ROOT = Path(__file__).resolve()
# .parent.parent` because the facade sits at `scripts/validate-pack.py` (parent
# = scripts/, parent.parent = repo root). This module sits one package deeper at
# `scripts/lib/validate_checks/core.py`, so reaching the repo root requires FOUR
# `.parent`s (validate_checks → lib → scripts → repo). Behavior preservation
# requires the VALUE be the repo root (a byte-identical 2-parent copy would
# resolve to `scripts/lib` and break every check + V4); only the `.parent` depth
# is adjusted to keep the resolved VALUE identical to the facade's.
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent

# ── Per-entry tree streams (BD-168 Checks 32 / 33 / 34) ─────────────────────
#
# Each stream tuple: (stream_key, stream_dir_relative, mirror_relative,
# entry_regex). Pack-side scope only per
# ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.6 — `validate-pack.py`
# runs in the pack repo CI; project-side per-entry trees under
# `project-template/docs/project/<stream>/` are pack-shipped canonical
# templates without entries during pack development, so they are NOT
# loaded here. Client projects validate their own per-entry trees
# (the regenerator's idempotency provides the implicit invariant).
#
# Stream keys MUST match the BD-164 helper keys in
# `scripts/lib/per-entry/_lib.sh` (`PE_STREAM_KEYS`); the bash regex
# strings here are mirrored from `pe_entry_regex_for_stream` for the
# Python-side filename conformance pre-check (Check 32 pre-check b).
STREAMS = [
    # (stream_key,        stream_dir_relative,  mirror_relative,                entry_regex)
    # BD-203: `mirror_relative` is retained as the deletion-target reference
    # only — for the PACK the per-entry tree + `_toc.md` is the SOLE SSOT;
    # there is no regenerated monolithic mirror (Check 32 inverted to 32′).
    # BD-211: pack-backlog regex is canonical `BD-NNN.md` — NO letter
    # suffix (the former suffix sub-entries were folded into their base
    # entries); A3: pack-changelog regex is per-release granularity (`vN.md`).
    ("pack-backlog",      "backlog",            "pack-ops/BACKLOG.md",          r"^BD-\d+\.md$"),
    ("pack-changelog",    "changelog",          "pack-ops/CHANGELOG.md",        r"^v\d+\.md$"),
]

README = REPO_ROOT / "README.md"

failures = []


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    failures.append(msg)


def ok(msg: str) -> None:
    print(f"  OK: {msg}")


def warn(msg: str) -> None:
    """Soft-advisory output — informational only, NEVER a gate failure.

    A `warn()` line is printed for the operator's attention but does NOT
    append to `failures`, so it never changes the exit code. Used by the
    JC-5 soft-advisory removed-doc guard (Check 48, BD-195 C6): accurate
    v8/v9 + process-history citations to removed docs must surface as a
    WARN without breaking CI.
    """
    print(f"WARN: {msg}")


# ── RUNTIME-BUDGET GUARD (BD-204 §4.7) ─────────────────────────────────────
#
# The durable prevention the prior >2h→<5min C-4.6 fix lacked. `main()` routes
# EVERY check through `run_check`, which times the wrapped call. Per the
# `ci-check-runtime-compounding` memory rule, a check that is fine ONCE is
# catastrophic at the battery's ~151× validate-pack invocation count, so a
# pathologically-slow check must not silently ship. The harness times each
# check (per-check WARN on overrun) and `main()` enforces a TOTAL-RUN HARD-FAIL
# on the GENERAL path only.
#
# Budget VALUES (measured-then-bounded per §4.7; the §3 measure-then-bound
# discipline, RUNTIME axis):
#   - Per-check WARN budget = 2.0 s. The slowest GENERAL check is well under
#     the ~1.3-1.4 s whole-run baseline (§4.6 EE), so 2.0 s per check is a
#     generous ceiling no current check approaches.
#   - Total general-run budget = 10 s. ~1.37 s baseline × a generous ~7×
#     safety factor; a general run over 10 s means a check regressed into the
#     general path (the C-4.6 shape) → hard FAIL. The 10 s total bound is NOT
#     applied to the deep (`PACK_VALIDATE_DEEP=1`) run — the deep run carries
#     its own larger TOTAL budget (~35 s = ~5 s general allowance + the 30 s
#     deep faithfulness-leg) so a legitimate deep run is never falsely failed.
RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0
RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0
RUN_CHECK_TOTAL_DEEP_BUDGET_S = 35.0
# Deep FAITHFULNESS-LEG per-check budget = 30 s (§4.7: "Deep faithfulness-check
# budget = 30 s"). This is the per-check WARN budget for Check 49's deep leg —
# DISTINCT from the deep TOTAL-run budget (35 s = ~5 s general allowance + this
# 30 s leg), which `main()` enforces below. The deep leg is MEASURED ~2.9 s, so
# 30 s is ~10× headroom; an Option-A per-entry-spawn regression (~142 s) blows
# it immediately.
RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S = 30.0

# ── BD-219 C3: CHECK_REGISTRY expected size — the registry-completeness
# bookkeeping constant (Check 59). The no-flag full run executes EVERY entry
# of `_build_check_registry()`; this constant is the explicit invariant that
# replaces the implicit "the per-check e2e leg proves the check is wired into
# main()" property that `--only-check` (BD-219 C1) would otherwise drop.
# UPDATE IN LOCK-STEP whenever a check is added/removed (a one-line edit, like
# the agent-count check). At the BD-219 dynamic-autoregen redesign the registry
# held 61 entries; BD-221 (Antigravity conversion) RETIRED Checks 21 + 28
# (−2), then BD-228 (push-time manifest method) ADDED Check 62 (+1), and BD-225
# (Graphify pack integration) ADDED Check 63 (+1), and BD-231 (cross-CLI MCP
# config example) ADDED Check 64 (+1), and BD-243 (durable doc-hygiene gates +
# skill-mirror identity) ADDED Checks 65–71 (+7), so the registry now holds 69
# entries:
#   57 entries at C1's CHECK_REGISTRY introduction (§EE-P5)
# + 3 net-new C3 checks (58 validate-no-flag, 59 registry-completeness,
#                        60 shard-coverage mirror)
# + 1 net-new BD-219-redesign check (61 fixture-location backstop)
# − 2 retired in BD-221 (21 pack-help per-CLI parity, 28 pm-startup per-CLI
#                        parity — both obsoleted by the pooled-skill model)
# + 1 net-new BD-228 check (62 manifest structural well-formedness screen)
# + 1 net-new BD-225 check (63 graphify-out-never-tracked guard)
# + 1 net-new BD-231 check (64 dangling-.example deliverable gate)
# + 1 net-new BD-243 check (65 operating-doc no-history gate)
# + 1 net-new BD-243 check (66 operating-doc bullet-concision gate)
# + 1 net-new BD-243 check (67 operating-doc deferred-feature recall gate)
# + 1 net-new BD-243 check (68 dangling-file-reference gate)
# + 1 net-new BD-243 check (69 operating-doc scope-completeness meta-check)
# + 1 net-new BD-243 check (70 client doc-gate structural parity)
# + 1 net-new BD-243 check (71 pack-root skill-mirror byte-identity)
# + 1 net-new BD-206 check (72 project empty-template shape, A1)
# + 1 net-new BD-206 check (73 project impl-plan _index.md consistency, C3)
# + 1 net-new BD-206 check (74 project changelog conformance, C4)
# + 1 net-new BD-206 check (75 project impl-plan phase/part/task naming, C5).
# CAUTION: a new check's NUMBER is the next free integer (66–75 for the BD-243
# gate wave + the BD-206 legs) but this constant is the registry ENTRY COUNT —
# bump it +1 per net-new entry, NOT to the new number. Numbers != entry count
# (Checks 16/18/19 each register TWICE and 2 checks carry number=None), so the
# count always lags the max number; setting it to the max number makes Check 59
# FAIL. The Check-44 pattern-tuple reduction (BD-243) changes NO entry count
# (+0). This constant is the explicit invariant; the actual count is COMPUTED
# from len(_build_check_registry()) and asserted equal by Check 59 — never
# hard-coded anywhere else. BD-255 Part A adds Check 80 (the generic doc↔
# constant twin-bijection check): 77 → 78. BD-255 Part C adds Check 81
# (structured File/Symbol prereq for active-design BDs) + Check 82 (cross-BD
# shared-edit-surface advisory): 78 → 79 → 80.
CHECK_REGISTRY_EXPECTED_COUNT = 80

# Accumulated per-check timings (name, elapsed_s) for the total-run guard.
_check_timings = []


def run_check(name, fn, budget_s=RUN_CHECK_PER_CHECK_WARN_BUDGET_S):
    """Time the wrapped check `fn` (a zero-arg callable); WARN on per-check
    budget overrun (§4.7).

    Records `(name, elapsed_s)` in `_check_timings` so `main()` can enforce the
    TOTAL-RUN budget after all checks complete. A per-check overrun is a LOUD
    WARN (validate-pack still completes — a slow check must not block unrelated
    work mid-investigation); the TOTAL-RUN budget is the hard FAIL (`main()`).
    """
    t0 = time.monotonic()
    fn()
    elapsed = time.monotonic() - t0
    _check_timings.append((name, elapsed))
    if elapsed > budget_s:
        warn(
            f"RUNTIME-BUDGET: check '{name}' took {elapsed:.2f}s > budget "
            f"{budget_s:.2f}s — investigate before merge"
        )


# ── Cross-module seam: _TRACKER_BACKENDS (Check 29 + Check 80 twin) ─────────
# Supported backend names per the example file comments
# ("github" first-class at v11.0; others reserved). Keep in lockstep
# with the comment block in the two example files.
_TRACKER_BACKENDS = ("github", "linear", "jira", "redmine")

# ── Cross-module seam: pack-chat-only permitted PATHS / PREFIXES ────────────
# (Check 36 `_is_pack_chat_only_permitted` in boundary_refs reads these; the
# Check 80 twin-registry in cross_bd reads `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`.
# Each consuming check imports these `from .core import …`.)
#
# pack-chat-only PERMITTED-PATHS per `pack-ops/PACK-AGENTS.md` § "pack-chat-only
# files and directories" Files list, with the post-Architect-B + B-fix path
# substitution: pack-root operational files now live under `pack-ops/`.
# README.md is permitted in full (the
# version-table-only narrower constraint stays a Pack Chat discipline rule
# per the §8.1a (README.md) note in the architect doc).
_PACK_CHAT_ONLY_PERMITTED_PATHS = {
    # BD-203 Commit 2 (A13-INVERSE): `pack-ops/BACKLOG.md` +
    # `pack-ops/CHANGELOG.md` are DELETED at BD-203 Commit 2 — the
    # per-entry trees `/backlog/` + `/changelog/` (covered by
    # `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` below) are the sole SSOT under
    # the no-mirror model. A `git rm`'d file cannot be a pack-chat-only
    # permitted PATH, so the two monolith entries are removed here in
    # lockstep with the deletion (the inverse of BD-209's A13 fold, which
    # had restored them transiently while both files still existed).
    "README.md",
    "pack-ops/PACK-CHAT.md",
    "pack-ops/PACK-AGENTS.md",
    "pack-ops/PACK-MEMORY-RATIONALE.md",
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    # `pack-ops/session-state.json` is a legitimate pack-chat-only target: the
    # committed live-session snapshot, Pack-Chat-overwritten on every state
    # transition (trinity `## Pack memory` `[rationale: session-state-snapshot]`;
    # `_SESSION_STATE_REQUIRED_KEYS` schema below). Membership here lets a future
    # `pack-chat-only` commit that touches it pass Check 36.
    "pack-ops/session-state.json",
}

# pack-chat-only PERMITTED-PATH PREFIXES — the per-entry tree directories per
# `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" Directories list.
_PACK_CHAT_ONLY_PERMITTED_PREFIXES = (
    "backlog/",
    "changelog/",
    "project-template/docs/project/backlog/",
    "project-template/docs/project/implementation-plan/",
    "project-template/docs/project/changelog/",
)

# ── Cross-module seam: session-state snapshot (BD-252 Checks 77/78/79) ──────
# `_session_state_load()` + the `_SESSION_STATE_*` constants are consumed by
# checks 77/78/79 (session_state.py, a later wave), which import them
# `from .core import …`. The committed, CLI-agnostic resumable session-state
# snapshot (`pack-ops/session-state.json`). A non-`.md` JSON DATA file under the
# `pack-ops` scanned tree (so it carries ONE _CHECK_OPERATING_DOC_OUT_OF_FAMILY
# literal — see that tuple — declaring it a data file, not an operating doc).
# `json` is already imported (above); no new dependency.
_SESSION_STATE_FILE = "pack-ops/session-state.json"

# The required key set, sized EXACTLY to P1-P9 (DESIGN-RECONCILED §2) as
# realized by the PLAN §0 seed schema (N1: where DESIGN §9 and PLAN §0 disagree
# — DESIGN §9 omits `schema` — the PLAN's seed schema governs). measure-then-
# bound: this set is the seed body's keys, no broader.
_SESSION_STATE_REQUIRED_KEYS = (
    "schema",            # the schema name/version literal (P-meta)
    "boundary_commit",   # P7 — durable-boundary reference (one SHA, 7-40 hex)
    "checkpoint",        # P8 — freshness marker (one ISO-8601 timestamp)
    "active",            # P1 — active BD(s) + per-BD sub-step
    "in_flight_agents",  # P2 — in-flight agent set (to re-spawn)
    "queue",             # P3 — queue order (user-decided sequence)
    "parallelization",   # P4a — parallelization mode (serial|parallel)
    "wave",              # P4b — current wave grouping
    "pending_decisions", # P5 — pending (unapplied) decisions
    "cycle_position",    # P9 — in-commit review/fix-cycle position
)
# The single sanctioned home for a SHA and a date — the keys whose VALUES may
# carry the one boundary SHA / one checkpoint date. The C-grammar accretion
# detector FORBIDS any second SHA, any off-field SHA, and any second date.
_SESSION_STATE_SHA_KEY = "boundary_commit"
_SESSION_STATE_DATE_KEY = "checkpoint"

_SESSION_STATE_SHA_RE = re.compile(r"\b[0-9a-f]{7,40}\b")
_SESSION_STATE_SHA_FULL_RE = re.compile(r"^[0-9a-f]{7,40}$")
_SESSION_STATE_DATE_RE = re.compile(r"20\d\d-\d\d-\d\d")
# ISO-8601 timestamp the seed authors (e.g. `2026-06-29T00:00:00Z`); a bare
# `20\d\d-\d\d-\d\d` date also satisfies C-struct's date assertion.
_SESSION_STATE_ISO_RE = re.compile(
    r"^20\d\d-\d\d-\d\d([T ]\d\d:\d\d(:\d\d)?(\.\d+)?(Z|[+-]\d\d:?\d\d)?)?$"
)
# Bare `BD-\d+` tags are PERMITTED (legitimate STATE — the whole point of the
# snapshot). Used by C-grammar to STRIP legal BD-tags before the narration scan.
_SESSION_STATE_BD_TAG_RE = re.compile(r"BD-\d+")
# The accretion / narration FAIL set (the Check-65 history shapes adapted to the
# snapshot grammar). These are the DECISIVE accretion detectors (N3: the byte
# cap below is only a BACKSTOP). Each pattern is matched against the snapshot's
# string values AFTER bare BD-tags are stripped.
_SESSION_STATE_NARRATION_PATTERNS = (
    ("bd-past-action", re.compile(
        r"BD-\d+\s+(deleted|added|renamed|introduced|removed|created|"
        r"retired|broadened|landed|did)")),
    ("per-bd", re.compile(r"per BD-\d+")),
    ("carry-over", re.compile(r"carried from|carry-over|carryover", re.I)),
    ("user-locked", re.compile(r"User-locked", re.I)),
    ("incident", re.compile(r"\bincident\b", re.I)),
    ("commit-n", re.compile(r"Commit [0-9]")),
    ("override-n", re.compile(r"Override [0-9]")),
    ("post-commit", re.compile(r"post-Commit", re.I)),
    ("pre-date", re.compile(r"pre-20\d\d")),
    ("lessons-marker", re.compile(r"\b(LESSONS|lessons)\b")),
    ("update-marker", re.compile(r"\bUPDATE-\d")),
)
# Anti-growth BACKSTOP byte cap (N3: the DECISIVE detector is the date/SHA/
# narration bounds above; the cap is the structural teeth against append-growth
# — a snapshot that grows over time is accreting). A true current-frontier
# snapshot is well under this (the seed is ~350 B). Measured-with-headroom
# (DESIGN-RECONCILED §4(4); PLAN §12 Q4 default 4096).
_SESSION_STATE_BYTE_CAP = 4096
# C-fresh advisory-WARN threshold: how many commits the boundary may lag HEAD
# before C-fresh advisory-WARNs (NOT a fail — GATE DECISION 2). N2: C-fresh
# advisory-WARNs as HEAD advances past a committed seed — EXPECTED, not a
# failure (the seed lags by the count of commits since it was authored).
# (DESIGN-RECONCILED §4 / PLAN §12 Q3 default <=5.)
_SESSION_STATE_FRESH_WARN_THRESHOLD = 5


def _session_state_load():
    """Read + json.load the snapshot. Returns (data, raw_bytes) or None.

    None signals the SKIP-lenient absent-file leg (the snapshot is a live-state
    artifact, absent on a fresh clone / pre-feature HEAD — the Check 47/76
    init_sh.is_file() idiom). A parse error returns the special sentinel
    (None, raw_bytes) so the caller can FAIL on malformed JSON distinctly.
    """
    path = REPO_ROOT / _SESSION_STATE_FILE
    if not path.is_file():
        return None
    raw = path.read_bytes()
    try:
        data = json.loads(raw.decode("utf-8"))
    except (ValueError, UnicodeDecodeError) as exc:  # malformed / non-UTF-8
        return ("PARSE_ERROR", raw, str(exc))
    return (data, raw)


# ── Cross-module seam: _CHECK_54_REQUIRED_TOKENS (Check 54) ─────────────────
# The MANDATED 3-token set (design §13.1a / BD-197 Note 14), sized to exactly
# the C5/C8a-authored tokens measured at C8b commit-time (no broader). Matched
# as literal substrings. `permissions.deny` is the in-session backstop recipe
# token (the `.` is a literal dot in the docs); the prose `isolation` param is
# deliberately NOT in this set.
_CHECK_54_REQUIRED_TOKENS = (
    "baseRef",
    "bgIsolation",
    "permissions.deny",
)

# ── Cross-module seam: _CHECK_56_CANONICAL_VERBS (Check 56) ─────────────────
# The CANONICAL §5.1 verb set — the FULL §5.1 destructive-git-verb denylist,
# the complete 29-verb set with NO exceptions, measured present in ALL 10
# surfaces. `apply` is INCLUDED (the verb-precise deny; design §5.1 G-4 —
# denied for agents while `git diff` stays allowed). `fetch` is INCLUDED —
# `git fetch` writes remote-tracking refs / FETCH_HEAD / new objects (a ref +
# repository state change), and `pull` (= fetch+merge) is already denied, so
# denying the composite while permitting its fetching half would be incoherent.
# The 8 short/long verbs `add`/`rm`/`mv`/`config`/`remote`/`gc`/`tag`/`notes`
# and `am` were each added after measuring them present-and-consistent across
# all 10 surfaces with the actual `_check_56_verb_present` matcher (no
# false-positive: each is genuinely enumerated in every surface's denylist).
# `am` matches word-bounded via `(?<![\w-])am(?![\w-])`, which does NOT
# false-match inside "stream" / "command" / "spam" / "amend". Sized to the
# measured-consistent set, which IS the full §5.1 set. Each is matched
# word-bounded.
_CHECK_56_CANONICAL_VERBS = (
    "commit", "push", "stash", "reset", "restore", "checkout",
    "clean", "merge", "rebase", "cherry-pick", "revert", "apply",
    "switch", "worktree", "update-ref", "update-index", "pull", "fetch",
    "filter-branch", "replace",
    "add", "rm", "mv", "config", "remote", "gc", "tag", "notes",
    "am",
)


# ── Cross-MODULE helper: _parse_manifest_records (BD-256 W2) ────────────────
# A blank-line-separated `key: value` manifest parser. Promoted to core in
# BD-256 W2 because its consumers span ≥2 modules (the MUST-4 seam-promotion
# rule): the Check 65/67/68 allowlist loaders (`_check_65/67/68_load_allowlist`)
# in boundary_refs (A), the Check 44/66 allowlist loaders in doc_concision (D),
# and Check 46 (`check_boundary_and_spawn_pointer_manifests`) in its own cluster.
# A single SSOT here keeps every consumer reading one copy (no fork). Pure
# function — depends only on `re` (imported above); no load-order constraint.
def _parse_manifest_records(text: str) -> list:
    """Parse a blank-line-separated `key: value` manifest into records.

    Lines beginning with `#` are comments. A blank line ends a record.
    Repeated keys within a record are joined with a space (wrapped
    `references:` continuation lines). Returns a list of dicts.
    """
    records = []
    cur = {}
    for raw in text.splitlines():
        if raw.lstrip().startswith("#"):
            continue
        if not raw.strip():
            if cur:
                records.append(cur)
                cur = {}
            continue
        m = re.match(r"(\w+):\s*(.*)", raw)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if key in cur:
                cur[key] = (cur[key] + " " + val).strip()
            else:
                cur[key] = val
        elif cur:
            # A continuation line with no `key:` prefix (indented wrap of
            # the previous value). Append to the last key seen.
            last_key = list(cur.keys())[-1]
            cur[last_key] = (cur[last_key] + " " + raw.strip()).strip()
    if cur:
        records.append(cur)
    return records


# ── __all__ — EVERY moved symbol, incl. the underscore seams ────────────────
# `from validate_checks.core import *` skips underscore names UNLESS they are
# listed in `__all__`; the underscore seams (`_session_state_load`,
# `_SESSION_STATE_*`, `_PACK_CHAT_ONLY_PERMITTED_*`, `_TRACKER_BACKENDS`,
# `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`) MUST therefore be
# enumerated here so the facade re-exports them and the still-inline check
# bodies + the later category modules resolve them.
__all__ = [
    # ── spine ──
    "REPO_ROOT",
    "failures",
    "fail",
    "ok",
    "warn",
    "run_check",
    "_check_timings",
    "RUN_CHECK_PER_CHECK_WARN_BUDGET_S",
    "RUN_CHECK_TOTAL_GENERAL_BUDGET_S",
    "RUN_CHECK_TOTAL_DEEP_BUDGET_S",
    "RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S",
    "CHECK_REGISTRY_EXPECTED_COUNT",
    # ── 8 cross-module seams ──
    "STREAMS",
    "README",
    "_session_state_load",
    "_SESSION_STATE_FILE",
    "_SESSION_STATE_REQUIRED_KEYS",
    "_SESSION_STATE_SHA_KEY",
    "_SESSION_STATE_DATE_KEY",
    "_SESSION_STATE_SHA_RE",
    "_SESSION_STATE_SHA_FULL_RE",
    "_SESSION_STATE_DATE_RE",
    "_SESSION_STATE_ISO_RE",
    "_SESSION_STATE_BD_TAG_RE",
    "_SESSION_STATE_NARRATION_PATTERNS",
    "_SESSION_STATE_BYTE_CAP",
    "_SESSION_STATE_FRESH_WARN_THRESHOLD",
    "_PACK_CHAT_ONLY_PERMITTED_PATHS",
    "_PACK_CHAT_ONLY_PERMITTED_PREFIXES",
    "_TRACKER_BACKENDS",
    "_CHECK_54_REQUIRED_TOKENS",
    "_CHECK_56_CANONICAL_VERBS",
    # ── cross-MODULE helper (BD-256 W2) ──
    "_parse_manifest_records",
]
