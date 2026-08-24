"""validate_checks.discipline_parity — Cluster B: the RW/RO + git-verb-parity +
project-template-shape check family (BD-256 W3).

This module owns Cluster B's 13 check bodies (Checks 50, 51, 52, 53, 54, 55, 56,
57, 72, 73, 74, 75, 84) plus their intra-cluster helpers and constants — the
single-source codec guard (50, BD-204), the tracker-deferral flip-block (51,
BD-214), the BD-197 RW/RO two-class + worktree-isolation + OPTIONAL-FEATURES +
destructive-git-verb parity guards (52/53/54/55/56/57), the BD-206 project-side
empty-template / index / changelog / impl-plan-naming conformance gates
(72/73/74/75), and the BD-189 groupings contract schema-specifics gate (84).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.discipline_parity
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name. Single SSOT — no forked copy.

Spine + seams: the spine symbols (`fail`, `ok`, `warn`, `failures`) and the
cross-module seams this cluster reads (`REPO_ROOT`, `README`,
`_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`) are imported
`from .core` — the single SSOT for the spine + 8 W1 seams. (`README =
REPO_ROOT / "README.md"` is load-time-derived from `REPO_ROOT` and lives in
`core` beside it; `_CHECK_54_REQUIRED_TOKENS` / `_CHECK_56_CANONICAL_VERBS` are
the two `_DOC_CONSTANT_TWINS`-enrolled rosters Check 80 (Cluster G) resolves by
name, so they were promoted to `core` at W1 — the MUST-4 ≥2-module seam rule.)

Two behavior-preserving relocations (NOT byte-identical; flagged as POQ-W3-1 /
POQ-W3-2 in IMPL-W3): Check 50 and Check 53 both reference the file they were
relocated FROM (the facade `scripts/validate-pack.py`), so a verbatim move would
silently retarget them onto this module's own source —

  - Check 50 (`check_validate_pack_no_reproduced_codec`) scanned
    `Path(__file__).resolve()`. Pre-BD-256 the body lived at
    `scripts/validate-pack.py`, so `__file__` WAS the scanned target. Relocated,
    `__file__` would resolve to this module — guarding the WRONG file and
    silently false-GREENing the real guard (the `_CHECK_49_SEAM_SCRIPT` codec
    stays in the facade). Behavior preservation: scan
    `REPO_ROOT / "scripts" / "validate-pack.py"` explicitly (restores the
    pre-BD-256 scan target). Mirrors the W1 `REPO_ROOT`-depth adjustment.

  - Check 53 (`check_worktree_isolation_prohibition_flip_block`) self-skips the
    file whose `name == "validate-pack.py"` because that file carries the
    matcher regex literals (`no worktree isolation` / `Do not pass
    ...isolation...worktree`) and would self-match. Relocated, this module's
    OWN source now carries those literals but its name is NOT
    `validate-pack.py`, so it would self-match → false FAIL. Behavior
    preservation: add a measure-then-bound self-exception sized to EXACTLY the
    one offending file (`scripts/lib/validate_checks/discipline_parity.py`),
    never the package subtree. Mirrors the W2 POQ-W2-2 Check-35 self-scan fix.

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re
import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    README,
    fail,
    ok,
    warn,
    failures,
    _CHECK_54_REQUIRED_TOKENS,
    _CHECK_56_CANONICAL_VERBS,
)


# ── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ─────────────────
#
# Structurally enforces "the guard drives the REAL functions, never a copy":
# FAILs CI if a reproduced gz64/base64 codec is (re)introduced INTO
# `validate-pack.py`. The C-4.6 (revert-#2) regression reproduced the
# gzip+base64 codec in Python — an OQ-4 violation a lossy codec change could
# FALSE-PASS, since a second copy can drift from the production
# `_tmf_gz64_encode` / `_tmr_decode_body_blob`. Check 49 instead sub-invokes
# the SHARED BATCH codec; this check makes a re-reproduction un-shippable
# regardless of review attention.
#
# Measure-then-bound (the §3 discipline): the guard's matching logic must run
# clean against validate-pack.py at HEAD AFTER the fix (Check 49 calls the
# shared codec via a `bash -c` seam — there is NO `import gzip`/`base64` doing
# the transform in this file). So the bound is "zero codec-transform tokens in
# this file's Python"; the seam string + this prose are not transform code.
def _check_50_strip_quoted_spans(line: str) -> str:
    """Remove single- and double-quoted spans from a source line, returning the
    UNQUOTED residual (for Check 50's per-occurrence token test).

    A deliberately small, robust quote-span stripper — NOT a full Python
    tokenizer (over-engineering it is out of scope; this is sufficient for the
    exploit class, a reproduced codec line that self-quotes its own token in a
    trailing string/comment). It walks the line char-by-char, dropping any span
    bounded by a matching `'` or `"` (the opening quote selects the closer);
    quote chars escaped with a backslash inside a span do not close it. A
    forbidden token that lives ONLY inside a quoted span (the denylist literals,
    a self-quoting comment copy) is removed; a BARE executable token in the
    code outside any quote survives in the residual and is flagged.
    """
    out = []
    i = 0
    n = len(line)
    quote = None  # the active opening quote char, or None outside a span
    while i < n:
        ch = line[i]
        if quote is None:
            if ch == "'" or ch == '"':
                quote = ch  # enter a quoted span; drop its contents
            else:
                out.append(ch)
        else:
            # Inside a quoted span: an escaped quote does not close it.
            if ch == "\\" and i + 1 < n:
                i += 2
                continue
            if ch == quote:
                quote = None  # span closed; the span chars were dropped
        i += 1
    return "".join(out)


_CHECK_50_FORBIDDEN_CODEC_TOKENS = (
    # A Python-level import of the codec primitives in validate-pack.py would
    # only exist to reproduce the transform — the seam runs the codec in a
    # subprocess (`bash -c`), it does not import gzip/base64 into THIS module.
    "import gzip",
    "import base64",
    "gzip.GzipFile",
    "gzip.compress",
    "gzip.decompress",
    "base64.b64encode",
    "base64.b64decode",
)


def check_validate_pack_no_reproduced_codec() -> None:
    """Check 50 — OQ-4 single-source codec guard (BD-204 §4.5).

    Scans `validate-pack.py`'s OWN Python source for a reproduced gz64/base64
    codec. Any forbidden token OUTSIDE the bash-seam string literal / comments
    FAILs — Check 49 must sub-invoke the shared batch codec, never re-implement
    it (the guard cannot FALSE-PASS a lossy codec change if it shares the one
    production codec).
    """
    print("\n── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ──")
    # BD-256 W3 (POQ-W3-1, behavior-preserving relocation — NOT byte-identical):
    # pre-BD-256 this body lived AT `scripts/validate-pack.py`, so
    # `Path(__file__)` WAS the scanned target (the facade carries the real
    # `_CHECK_49_SEAM_SCRIPT` codec). Relocated to this module, `__file__` would
    # resolve HERE — guarding the wrong file and silently false-GREENing the
    # guard. Scan the facade explicitly via REPO_ROOT to restore the pre-BD-256
    # scan target (mirrors the W1 REPO_ROOT-depth adjustment in core.py).
    self_path = REPO_ROOT / "scripts" / "validate-pack.py"
    src_lines = self_path.read_text().splitlines()

    # Determine the bash-seam string-literal span so a `gzip`/`base64` token
    # INSIDE the seam (which runs in a subprocess, the single-sourced codec's
    # python3 — NOT a Python reproduction in this module) is not falsely
    # flagged. The seam is the `_CHECK_49_SEAM_SCRIPT = r'''` ... `'''` block.
    seam_start = seam_end = None
    for i, line in enumerate(src_lines):
        if line.startswith("_CHECK_49_SEAM_SCRIPT = r'''"):
            seam_start = i
        elif seam_start is not None and seam_end is None and line.rstrip() == "'''":
            seam_end = i
            break

    hits = []
    for lineno, line in enumerate(src_lines, start=1):
        idx0 = lineno - 1
        # Skip the seam string literal (the legitimate single-sourced codec
        # invocation that runs in a subprocess).
        if seam_start is not None and seam_end is not None and \
                seam_start <= idx0 <= seam_end:
            continue
        # Skip pure-comment lines and the forbidden-token tuple that NAMES the
        # tokens (this guard's own bound declaration) — a `#`-led line or the
        # `_CHECK_50_FORBIDDEN_CODEC_TOKENS` literal is prose/data, not codec
        # transform code.
        stripped = line.lstrip()
        if stripped.startswith("#"):
            continue
        # The token-list literal lines carry the tokens as quoted strings; the
        # span between the tuple open and close is data, not executable codec.
        #
        # Strip every quoted-string span (single- AND double-quoted) from the
        # line FIRST, then test for the BARE token in the UNQUOTED residual.
        # This is per-OCCURRENCE, not per-line: a line that carries BOTH a real
        # bare codec call AND a quoted copy of the same token in a trailing
        # comment/string (e.g. `gzip.compress(buf) # "gzip.compress"`) keeps the
        # executable `gzip.compress(buf)` in the residual and is FLAGGED — the
        # prior per-line `f'"{token}"' in line` escape excused the whole line on
        # the quoted copy alone, letting a self-quoting reproduced codec EVADE
        # the guard (BD-204 C-4.6 review F-1). Legitimate denylist literals
        # (the bare `"gzip.compress"` definitions) have NO unquoted occurrence,
        # so they survive the strip with no residual hit and still PASS.
        residual = _check_50_strip_quoted_spans(line)
        for token in _CHECK_50_FORBIDDEN_CODEC_TOKENS:
            if token in residual:
                hits.append((lineno, token, line.strip()))

    if hits:
        for lineno, token, text in hits:
            fail(
                f"Check 50 — validate-pack.py:{lineno} reproduces the gz64/"
                f"base64 codec (`{token}`): `{text}`. The faithfulness guard "
                f"(Check 49) MUST sub-invoke the SHARED batch codec "
                f"(`_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch`), "
                f"never a copy (OQ-4 — a second codec can drift and FALSE-PASS "
                f"a lossy migration). Remove the reproduced codec; call the "
                f"shared seam."
            )
        return

    ok(
        "Check 50 — no reproduced gz64/base64 codec in validate-pack.py; "
        "Check 49 sub-invokes the shared batch codec (OQ-4 single-source)"
    )


# ── Check 51: BD-214 tracker-deferral flip-block guard ─────────────────────
#
# Anti-regression guard for the BD-214 tracker deferral (design §6.3). Five
# cheap, bounded legs (grep over ≤3 named files or 2 bounded per-entry trees;
# no whole-tree scan, no subprocess-per-entry — satisfies the runtime-
# compounding rule). All FIVE legs are now asserted (legs 1/2/4 landed in C1;
# legs 3 and 5 land in C3 alongside their fix-recipes — the pm-startup ×4
# Step-8 strip completes leg-3's `== 0`, and the install-map removal makes
# leg-5's `tracker.toml.example` absent):
#   leg 1 — the deferral clamp marker is created by C1 (tracker-config.sh);
#   leg 2 — the three verb gates are created by C1 (pack-tracker.sh init +
#           enable-recommendations; tracker-migrate.sh forward arm);
#   leg 3 — `recommendation_should_recommend` occurrences OUTSIDE the
#           allowlist {scripts/lib/recommendation.sh, scripts/tests/,
#           maintenance-docs/} == 0 (the 7 skill files — pack-startup ×3 +
#           pm-startup ×4 — are stripped across C2/C3; the strip COMPLETES
#           at C3, so this leg is added here);
#   leg 4 — entry-content grep-zero is ALREADY true at HEAD (line-anchored
#           patterns; the one BD-204:24 mid-line prose hit is excluded by the
#           `^` anchor — empty allowlist by construction);
#   leg 5 — `tracker.toml.example` is absent from the init-project.sh install
#           map (anti-reintroduction); C3 removes it from the map + the
#           self-doc block in the SAME commit as this leg.
_CHECK_51_CLAMP_FILE = "scripts/lib/tracker-config.sh"
# Leg 3 — recommendation invoker grep. The ONLY surfaces that wire the D-19
# recommendation invocation are the per-CLI session-startup skill/command
# files (design §6.3 / EE-7: pack-startup ×3 + pm-startup ×4). The scan is
# BOUNDED to those skill/command directories — a whole-tree rglob would be a
# runtime-compounding hazard across the battery's ~151 validate-pack
# invocations (feedback-ci-check-runtime-compounding); the dormant lib + its
# tests + historical maintenance-docs (the legitimate carriers) live OUTSIDE
# this bounded surface, so no allowlist is needed within it.
_CHECK_51_RECOMMEND_TOKEN = "recommendation_should_recommend"
# MAINTENANCE GUARD: this tuple is the EXHAUSTIVE set of CLI-surface
# skill/command directories leg 3 scans for live D-19 recommendation
# invokers. The leg is a bounded scan over exactly these dirs (not a
# whole-tree rglob), so any FUTURE CLI surface that can host
# `recommendation_should_recommend` (a new per-CLI skill or command
# directory) MUST be ADDED here — otherwise leg 3 develops a blind spot
# and a re-armed recommendation invoker on the new surface would pass the
# guard undetected. Keep this set in lock-step with the per-CLI startup
# skill/command surface. BD-221 (Antigravity conversion): Antigravity reads
# workspace skills at `.agents/skills/<name>/SKILL.md`, so the Antigravity
# skill dirs (pack-root `.agents/skills` + the client
# `project-template/.agents/skills` install target) are the third legs.
# Non-existent dirs are skipped.
_CHECK_51_RECOMMEND_SKILL_DIRS = (
    ".claude/skills",
    ".codex/skills",
    ".agents/skills",
    "project-template/.claude/skills",
    "project-template/.codex/skills",
    "project-template/skills",
    "project-template/.agents/skills",
)
# Leg 4 line-anchored entry-content artifact patterns (empty allowlist).
_CHECK_51_ENTRY_TREES = ("backlog", "changelog")
_CHECK_51_ENTRY_PATTERNS = (
    re.compile(r"^<!-- pack-entry-body-gz64:"),
    re.compile(r"^<!-- pack-id:"),
)
# Leg 5 — the install-map source token that, if present in init-project.sh,
# would re-ship the deferred `tracker.toml.example` flip material to clients.
_CHECK_51_INSTALL_MAP_FILE = "scripts/init-project.sh"
_CHECK_51_INSTALL_MAP_TOKEN = "tracker.toml.project-example:tracker.toml.example"


def check_tracker_deferral_flip_block() -> None:
    """Check 51 — BD-214 tracker-deferral flip-block guard (legs 1–5).

    leg 1: `tracker-config.sh` carries the BD-214 deferral clamp marker
           (`PACK_TRACKER_DEFERRAL_OVERRIDE` + the dated BD-214 comment).
    leg 2: the three verb gates are present — `pack-tracker.sh` gates
           `cmd_init` + `cmd_enable_recommendations`, and
           `tracker-migrate.sh`'s forward arm refuses.
    leg 3: `recommendation_should_recommend` occurrences OUTSIDE the
           allowlist {scripts/lib/recommendation.sh, scripts/tests/,
           maintenance-docs/} == 0 (no live invoker re-arms the deferred
           D-19 recommendation seam).
    leg 4: line-anchored entry-content artifact grep-zero over the per-entry
           trees (`backlog/` + `changelog/`) == 0 (empty allowlist).
    leg 5: `tracker.toml.example` is absent from the init-project.sh install
           map (the deferred flip material no longer ships to clients).
    """
    print("\n── Check 51: BD-214 tracker-deferral flip-block guard (legs 1-5) ──")
    any_fail = False

    # ── leg 1 — clamp marker in tracker-config.sh ──
    clamp_path = REPO_ROOT / _CHECK_51_CLAMP_FILE
    if not clamp_path.is_file():
        any_fail = True
        fail(f"Check 51 leg 1 — {_CHECK_51_CLAMP_FILE} not found")
    else:
        clamp_text = clamp_path.read_text()
        if "PACK_TRACKER_DEFERRAL_OVERRIDE" not in clamp_text \
                or "BD-214" not in clamp_text:
            any_fail = True
            fail(
                f"Check 51 leg 1 — {_CHECK_51_CLAMP_FILE} is missing the BD-214 "
                f"deferral clamp marker (`PACK_TRACKER_DEFERRAL_OVERRIDE` + a "
                f"`BD-214` dated comment). The clamp must be the first statement "
                f"of `tracker_mode()` forcing flat-file while tracker is deferred."
            )

    # ── leg 2 — the three verb gates ──
    pack_tracker_path = REPO_ROOT / "scripts/pack-tracker.sh"
    tracker_migrate_path = REPO_ROOT / "scripts/tracker-migrate.sh"
    pt_text = pack_tracker_path.read_text() if pack_tracker_path.is_file() else ""
    tm_text = tracker_migrate_path.read_text() if tracker_migrate_path.is_file() else ""

    def _gate_in_function(text: str, func: str) -> bool:
        """True iff the named function body carries the BD-214 deferral gate.

        Accepts EITHER a direct `PACK_TRACKER_DEFERRAL_OVERRIDE` check OR a
        call to the shared `_tracker_deferral_gate` helper (which wraps the
        override seam + typed refusal). Both are valid encodings of the gate.
        """
        marker = f"{func}() {{"
        start = text.find(marker)
        if start == -1:
            return False
        # Function body = from the marker to the next top-level `\n}` (a `}`
        # at column 0). Bounded slice; no whole-file scan beyond this span.
        end = text.find("\n}", start)
        body = text[start:end] if end != -1 else text[start:]
        return ("PACK_TRACKER_DEFERRAL_OVERRIDE" in body
                or "_tracker_deferral_gate" in body)

    if not _gate_in_function(pt_text, "cmd_init"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/pack-tracker.sh `cmd_init` is missing the "
            "BD-214 deferral gate (must refuse `pack tracker init` while tracker "
            "is deferred, unless PACK_TRACKER_DEFERRAL_OVERRIDE=1)."
        )
    if not _gate_in_function(pt_text, "cmd_enable_recommendations"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/pack-tracker.sh "
            "`cmd_enable_recommendations` is missing the BD-214 deferral gate "
            "(must refuse re-arming the D-19 recommendation seam while deferred)."
        )
    if not _gate_in_function(tm_text, "cmd_forward"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/tracker-migrate.sh `cmd_forward` (the "
            "FORWARD arm — the low-level flip path) is missing the BD-214 "
            "deferral gate. The reverse arm stays un-gated (escape hatch)."
        )

    # ── leg 3 — recommendation-invoker grep-zero (bounded to skill dirs) ──
    # Scan ONLY the per-CLI session-startup skill/command directories (the
    # sole surfaces that wire the D-19 invocation). Bounded by construction —
    # no whole-tree scan (runtime-compounding rule). A token hit here is a
    # live invoker re-arming the deferred D-19 seam (BD-214 scope 6).
    leg3_hits = []
    for skill_dir in _CHECK_51_RECOMMEND_SKILL_DIRS:
        base = REPO_ROOT / skill_dir
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            try:
                text = path.read_text()
            except (OSError, UnicodeDecodeError):
                continue
            if _CHECK_51_RECOMMEND_TOKEN in text:
                leg3_hits.append(path.relative_to(REPO_ROOT).as_posix())
    if leg3_hits:
        any_fail = True
        for hit in leg3_hits:
            fail(
                f"Check 51 leg 3 — live `{_CHECK_51_RECOMMEND_TOKEN}` invoker "
                f"in a session-startup skill/command file: {hit}. The D-19 "
                f"tracker opt-in recommendation is deferred (BD-214); no live "
                f"skill surface may re-arm it. Replace the Step-8 body with a "
                f"deferred note (the dormant lib + its tests keep the token)."
            )

    # ── leg 4 — line-anchored entry-content artifact grep-zero ──
    leg4_hits = []
    for tree in _CHECK_51_ENTRY_TREES:
        tree_dir = REPO_ROOT / tree
        if not tree_dir.is_dir():
            continue
        for md in sorted(tree_dir.glob("*.md")):
            try:
                lines = md.read_text().splitlines()
            except OSError:
                continue
            for lineno, line in enumerate(lines, start=1):
                for pat in _CHECK_51_ENTRY_PATTERNS:
                    if pat.match(line):
                        leg4_hits.append(f"{tree}/{md.name}:{lineno}: {line[:60]}")
    if leg4_hits:
        any_fail = True
        for hit in leg4_hits:
            fail(
                f"Check 51 leg 4 — entry-content tracker artifact present "
                f"(line-anchored, empty allowlist): {hit}. Committed entries "
                f"must carry ZERO tracker body/id artifacts while tracker is "
                f"deferred (BD-214 scope 1)."
            )

    # ── leg 5 — tracker.toml.example absent from the install map ──
    install_map_path = REPO_ROOT / _CHECK_51_INSTALL_MAP_FILE
    if not install_map_path.is_file():
        any_fail = True
        fail(f"Check 51 leg 5 — {_CHECK_51_INSTALL_MAP_FILE} not found")
    else:
        install_map_text = install_map_path.read_text()
        if _CHECK_51_INSTALL_MAP_TOKEN in install_map_text:
            any_fail = True
            fail(
                f"Check 51 leg 5 — {_CHECK_51_INSTALL_MAP_FILE} still maps "
                f"`tracker.toml.example` into the client install "
                f"(`{_CHECK_51_INSTALL_MAP_TOKEN}` present). The deferred "
                f"tracker flip material must NOT ship to clients (BD-214 D-C); "
                f"remove the install-map entry, the S11 copy, and the self-doc "
                f"comment line in the same commit (Checks 39/41/46 re-pin)."
            )

    if not any_fail:
        ok(
            "Check 51 — BD-214 flip-block guard: clamp marker present (leg 1), "
            "init + enable-recommendations + forward-arm gates present (leg 2), "
            "no live recommendation invoker in skill files (leg 3), "
            "entry-content artifact grep-zero over backlog/ + changelog/ "
            "(leg 4), tracker.toml.example absent from the install map (leg 5)."
        )


# ── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ────────────
#
# Guard-B (design §13.2 / §4.3 pack): assert SET-EQUALITY between
#   {the PACK-AGENTS roster `Class` cells}  ↔  {the per-agent-file PROSE
#    mandate headers}
# for the 5 pack agents × 3 CLIs.
#
# BINDS TO THE PROSE HEADER, NEVER `tools:` (design §13.2). All four RO pack
# agents (`pack-architect`, `pack-planner`, `pack-reviewer`,
# `pack-docs-researcher`) carry `Write, Edit` in their Claude `tools:` line
# yet are RO — keying on `tools:` would misclassify them. The Antigravity
# bundle agent files carry NO `tools:` field at all (measured 0/5), so a
# `tools:`-keyed guard is impossible there anyway. The discriminator is the
# mandate header (`**Source-write within scope.**` = RW / `**Read-only.**`
# = RO) and the roster `Class` column; the tool list is irrelevant to the
# class.
#
# Measure-then-bound (ci-guard-design-measure-then-bound): sized to EXACTLY
# the measured 5-agent pack set (1 RW `pack-coder` + 4 RO) — no broader. A
# NEW pack agent or a CLI surface that is not in this measured set MUST be
# ADDED to `_CHECK_52_PACK_AGENTS` / `_CHECK_52_AGENT_DIRS` in lock-step,
# else the guard develops a blind spot.
#
# Runtime (ci-check-runtime-compounding): a SINGLE bounded pass — at most
# 5 agents × 3 CLI dirs = 15 file reads + one roster read; NO whole-tree
# scan, NO subprocess-per-entry. Negligible across the battery's ~191
# validate-pack invocations.
_CHECK_52_ROSTER_FILE = "pack-ops/PACK-AGENTS.md"
# The EXHAUSTIVE measured pack-agent set (design §4.3 / RESEARCH-BD-197-
# AGENT-PERMISSION-INVENTORY §1.1): 1 RW + 4 RO. The roster Class cells are
# read from PACK-AGENTS.md; this tuple only bounds WHICH agents the guard
# inspects (the SSOT for the class VALUE is the roster, not this tuple).
_CHECK_52_PACK_AGENTS = (
    "pack-architect",
    "pack-coder",
    "pack-docs-researcher",
    "pack-planner",
    "pack-reviewer",
)
# The three CLI agent surfaces + the per-CLI file extension. Bounded — adding
# a CLI surface requires extending this map (enumerate-encoding-surfaces).
# BD-221 (Antigravity conversion): the third leg is the Antigravity pack-agents
# plugin bundle (.agents-plugin/pack-agents/agents).
_CHECK_52_AGENT_DIRS = (
    (".claude/agents", "md"),
    (".codex/agents", "toml"),
    (".agents-plugin/pack-agents/agents", "md"),
)
# Prose mandate-header signatures (the class discriminator — NEVER `tools:`).
_CHECK_52_RW_HEADER = "**Source-write within scope.**"
_CHECK_52_RO_HEADER = "**Read-only.**"


def _check_52_roster_classes(roster_text: str) -> dict:
    """Parse the PACK-AGENTS `## Pack agents` roster table; return
    {agent_name: "RW"|"RO"|"<bad>"} from the `Class` column.

    The roster row shape is `| `agent` | Class | Role | Mode |`. We locate
    each measured agent by its backticked name cell and read the SECOND
    pipe-delimited cell (the Class column). Bounded string ops; no regex
    backtracking risk.
    """
    classes = {}
    for line in roster_text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        name_cell = cells[0].strip().strip("`")
        if name_cell in _CHECK_52_PACK_AGENTS:
            classes[name_cell] = cells[1].strip()
    return classes


def _check_52_header_class(text: str):
    """Classify an agent file by its PROSE mandate header. Returns
    "RW" / "RO" / None (no recognized header) — NEVER keys on `tools:`."""
    has_rw = _CHECK_52_RW_HEADER in text
    has_ro = _CHECK_52_RO_HEADER in text
    if has_rw and not has_ro:
        return "RW"
    if has_ro and not has_rw:
        return "RO"
    # Both present, or neither — ambiguous → treat as unclassified so the
    # set-equality leg FAILs loudly (a file must carry exactly one header).
    return None


def check_pack_rw_ro_two_class() -> None:
    """Check 52 — BD-197 pack RW/RO two-class consistency (Guard-B).

    Asserts set-equality between the PACK-AGENTS roster `Class` cells and
    the per-agent-file PROSE mandate headers, for the 5 pack agents × 3
    CLIs. Binds to the prose header, NEVER `tools:` (RO pack agents carry
    Write/Edit; Antigravity bundle files carry no `tools:`). Sized to
    exactly the measured 5-agent set.
    """
    print("\n── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ──")
    any_fail = False

    # ── Read the roster SSOT (the Class column). ──
    roster_path = REPO_ROOT / _CHECK_52_ROSTER_FILE
    if not roster_path.is_file():
        fail(f"Check 52 — roster SSOT {_CHECK_52_ROSTER_FILE} not found")
        return
    roster_classes = _check_52_roster_classes(roster_path.read_text())

    # Every measured agent MUST have a roster Class cell of RW or RO.
    for agent in _CHECK_52_PACK_AGENTS:
        cls = roster_classes.get(agent)
        if cls is None:
            any_fail = True
            fail(
                f"Check 52 — agent `{agent}` has NO `Class` cell in the "
                f"{_CHECK_52_ROSTER_FILE} `## Pack agents` roster. Every "
                f"pack agent MUST carry an RW/RO Class (the pack-side SSOT)."
            )
        elif cls not in ("RW", "RO"):
            any_fail = True
            fail(
                f"Check 52 — agent `{agent}` roster Class is `{cls}` "
                f"(expected exactly `RW` or `RO`) in {_CHECK_52_ROSTER_FILE}."
            )

    # ── Read each agent file's PROSE header; compare to the roster. ──
    for agent in _CHECK_52_PACK_AGENTS:
        roster_cls = roster_classes.get(agent)
        for dir_rel, ext in _CHECK_52_AGENT_DIRS:
            agent_path = REPO_ROOT / dir_rel / f"{agent}.{ext}"
            if not agent_path.is_file():
                any_fail = True
                fail(
                    f"Check 52 — agent file {dir_rel}/{agent}.{ext} not found "
                    f"(the measured pack set is 5 agents × 3 CLIs)."
                )
                continue
            header_cls = _check_52_header_class(agent_path.read_text())
            if header_cls is None:
                any_fail = True
                fail(
                    f"Check 52 — {dir_rel}/{agent}.{ext} carries no single "
                    f"recognized prose mandate header (expected exactly one of "
                    f"`{_CHECK_52_RW_HEADER}` or `{_CHECK_52_RO_HEADER}`)."
                )
                continue
            if roster_cls in ("RW", "RO") and header_cls != roster_cls:
                any_fail = True
                fail(
                    f"Check 52 — class MISMATCH for `{agent}`: roster Class "
                    f"`{roster_cls}` (in {_CHECK_52_ROSTER_FILE}) ≠ prose "
                    f"header `{header_cls}` (in {dir_rel}/{agent}.{ext}). The "
                    f"roster Class column and the per-agent prose mandate "
                    f"header must agree (set-equality; Guard-B binds to the "
                    f"prose header, never `tools:`)."
                )

    if not any_fail:
        ok(
            "Check 52 — pack RW/RO two-class set-equality holds: 5 agents × 3 "
            "CLIs; roster `Class` cells (1 RW `pack-coder` + 4 RO) ↔ per-agent "
            "prose mandate headers (bound to the header, never `tools:`)."
        )


# ── Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A) ───
#
# Guard-A (design §13.1 / §11.5 gate (a)): assert the worktree-isolation
# PROHIBITION PROSE — removed in C2 (the bug-era "Spawn all sub-agents with
# no worktree isolation" / "Do not pass `isolation:"worktree"`" rule) — does
# NOT reappear in any ACTIVE pack surface. This is the anti-regression /
# flip-block guard for the BD-197 un-prohibition.
#
# MATCHER — the PROHIBITION SIGNATURE ONLY (design §13.1, 2nd-adversarial
# G-1/G-2): `no worktree isolation` OR `Do not pass .*isolation.*worktree`.
# NEVER the bare setting-key names `baseRef`/`bgIsolation` — those are
# legitimate post-BD-197 content (the OPTIONAL-FEATURES section + the trinity
# mode-model bullet WRITE them); forbidding them would defeat the gate. The
# signature is the removed PROHIBITION wording, not the feature vocabulary.
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at C5
# commit-time (HEAD 9b7c74c, 2026-06-14): `rg -l --hidden --no-ignore
# 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git'
# -g '!test-fixtures'` returns 25 files — ALL under `maintenance-docs/`
# (9 under `maintenance-docs/archive/`, 16 under
# `maintenance-docs/v11-implementation/`). Categorization:
#   - STRIP set is EMPTY: every active rule surface (CLAUDE.md, root
#     AGENTS/GEMINI, the commit-discipline skill ×3, pack-ops operating
#     docs) returns 0 — C1/C2 stripped the active prohibition prose.
#   - KEEP set = the 25 process/history carriers, which by construction
#     live ONLY in `maintenance-docs/archive/` (retired history) and
#     `maintenance-docs/v11-implementation/` (the BD-196/BD-197 process
#     docs: research/design/plan/IMPL/review docs that QUOTE the
#     prohibition while documenting its removal). These two directories
#     are PROCESS/HISTORY surfaces — agents do not load them as rules — so
#     prohibition prose there is legitimate documentation of the removed
#     rule, not a re-instated active prohibition.
#
# ALLOWLIST = the two non-active process directories (sized to exactly where
# the legitimate carriers live, no broader). This is the measure-then-bound
# answer that is ALSO re-measure-stable: every future BD-197 review/IMPL doc
# lands under `maintenance-docs/v11-implementation/` and is absorbed without
# a static per-file list going stale (a per-file frozen list would be stale
# the moment this very C5 IMPL-REPORT lands). The directory scope is bounded
# to history/process — it does NOT admit any active rule surface.
#
# NARROW self-exception (decision 1; Check-51 self-skip precedent at
# `check_help_fragment_completeness` `entry.name == "validate-pack.py"`):
# because `scripts/` IS in the active scan scope, the validator source
# (this file, which QUOTES the matcher regex literal in the constants below)
# and the single new per-check test SELF-MATCH. So Guard-A:
#   (i)  self-skips the validator itself (`entry.name == "validate-pack.py"`);
#   (ii) allowlists ONLY the single new test file
#        `scripts/tests/test-validate-pack-check-53.sh` (NARROW — NOT the
#        whole `scripts/tests/` dir; that dir holds many unrelated tests and
#        a future test must not be able to smuggle prohibition prose).
#
# CANDIDATE SET (ci-guard-measure-then-bound): git-TRACKED files
# (`git ls-files`), NEVER a raw `REPO_ROOT.rglob("*")` filesystem walk. A raw
# walk enumerates whatever is ON DISK rather than what the repo CONTAINS, so it
# descends into live sub-agent worktrees (`.claude/worktrees/agent-*/`) and
# re-reports this repo's own files, seen through a second checkout, as fresh
# offenders — and it reads gitignored build output (`graphify-out/`) the repo
# does not own. Both are environment artifacts, not pack surfaces. Guard-A
# asserts a property of the REPO, so the REPO's file set is the only correct
# candidate set. Lenient SKIP when git is unavailable / this is not a work tree
# (the Check 63 + Check 69 posture — never hard-fail on a non-git environment).
#
# RUNTIME (ci-check-runtime-compounding): ONE `git ls-files` subprocess per
# invocation — NOT per-entry — then text/markdown files only and in-process
# `re` matching; no `rg` fork. Same single-subprocess shape as Checks 63/69.
# The 3-entry exclusion list (`test-fixtures/`, `scripts/tests/fixtures/`,
# `node_modules/`) plus the two allowlisted process dirs keeps the scanned set
# small. Negligible across
# the battery's ~202 validate-pack invocations; `run_check` times it and
# WARNs on the 2.0 s per-check budget.
_CHECK_53_PROHIBITION_PATTERNS = (
    re.compile(r"no worktree isolation"),
    re.compile(r"Do not pass .*isolation.*worktree"),
)
# Files Guard-A scans: regular files with these suffixes (rule/prose surfaces).
_CHECK_53_SCAN_SUFFIXES = (".md", ".txt", ".py", ".sh", ".toml")
# ALLOWLIST — directory prefixes whose prohibition-prose hits are LEGITIMATE
# (history + BD-197 process docs). Sized to exactly the measured KEEP set's
# bounding dirs (measure-then-bound; re-measure-stable). Both are process/
# history surfaces, never active rule surfaces.
_CHECK_53_ALLOWLIST_DIR_PREFIXES = (
    "maintenance-docs/archive/",
    "maintenance-docs/v11-implementation/",
)
# ALWAYS-EXCLUDED dirs (not scanned at all): pack-internal git state +
# synthetic fixtures (the latter can carry arbitrary injected strings).
# Under the git-TRACKED candidate set `.git/` is STRUCTURALLY unreachable (git
# never tracks its own metadata dir), so it was dropped. `node_modules/` is
# retained deliberately: it is NOT in `.gitignore`, so vendored deps could be
# committed into the tracked set and must stay excluded if they ever are.
_CHECK_53_EXCLUDE_DIR_PREFIXES = (
    "test-fixtures/",
    "scripts/tests/fixtures/",
    "node_modules/",
)
# NARROW self-exception (decision 1): the single new per-check test file is
# allowlisted by EXACT path (it QUOTES the matcher regex). NOT the whole
# `scripts/tests/` dir. The validator itself is self-skipped by name below.
_CHECK_53_SELF_TEST_ALLOWLIST = frozenset({
    "scripts/tests/test-validate-pack-check-53.sh",
})
_CHECK_53_SELF_SKIP_NAME = "validate-pack.py"
# BD-256 W3 (POQ-W3-2, measure-then-bound, behavior-preserving relocation):
# pre-BD-256 Check 53's body lived at `scripts/validate-pack.py` and was
# self-skipped by NAME. W3 relocated the body (and the matcher regex literals
# `_CHECK_53_PROHIBITION_PATTERNS`) into this module — whose name is NOT
# `validate-pack.py`, so the name self-skip no longer covers it and the walk
# would self-match its own quoted patterns → false FAIL. Allowlist EXACTLY the
# one offending file (this module's own source), never the package subtree —
# every OTHER file, including the rest of the validate_checks/ package, stays in
# full scan scope. Measured KEEP set for the relocated literals = exactly
# {scripts/lib/validate_checks/discipline_parity.py} (grep at W3: no other
# validate_checks module carries the prohibition prose). Mirrors the W2
# POQ-W2-2 Check-35 self-scan fix.
_CHECK_53_SELF_SOURCE = "scripts/lib/validate_checks/discipline_parity.py"


def _check_53_is_allowlisted(rel_str: str) -> bool:
    """True iff `rel_str` (POSIX relative path) is a legitimate prohibition-
    prose carrier: a process/history doc dir, the single new check-53 test,
    the self-skipped validator facade, or this validator module's own source
    (BD-256 W3 relocation). Bounded prefix/membership tests only."""
    if rel_str == f"scripts/{_CHECK_53_SELF_SKIP_NAME}":
        return True
    if rel_str == _CHECK_53_SELF_SOURCE:
        return True
    if rel_str in _CHECK_53_SELF_TEST_ALLOWLIST:
        return True
    for prefix in _CHECK_53_ALLOWLIST_DIR_PREFIXES:
        if rel_str.startswith(prefix):
            return True
    return False


def check_worktree_isolation_prohibition_flip_block() -> None:
    """Check 53 — BD-197 worktree-isolation prohibition flip-block (Guard-A).

    Asserts the removed worktree-isolation PROHIBITION PROSE
    (`no worktree isolation` / `Do not pass ...isolation...worktree`) does
    NOT reappear in any ACTIVE pack surface. The matcher keys on the
    prohibition SIGNATURE only — NEVER the legitimate setting keys
    `baseRef`/`bgIsolation`. Measure-then-bound allowlist = the two
    process/history directories that carry the legitimate documentation of
    the removed rule, PLUS the narrow self-exception (validator self-skip +
    ONLY the single check-53 test). Candidate set = git-TRACKED files
    (`git ls-files`), never a raw filesystem walk; lenient SKIP off a git
    work tree.
    """
    print("\n── Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A) ──")
    # Candidate set = git-TRACKED files, NOT a raw filesystem walk (see the
    # CANDIDATE SET note above). `git ls-files` already emits POSIX-relative
    # paths, so no separator normalization is needed.
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        ok("git not available — skipping (lenient)")
        return
    if result.returncode != 0:
        ok("git ls-files unavailable (not a git work tree) — skipping (lenient)")
        return

    offenders = []
    for rel_str in sorted(r for r in result.stdout.split("\0") if r.strip()):
        path = REPO_ROOT / rel_str
        # Self-skip the validator by NAME (Check-51 precedent) — it quotes
        # the matcher regex literal and would otherwise self-match.
        if path.name == _CHECK_53_SELF_SKIP_NAME:
            continue
        # tracked-but-absent (deleted-not-committed) — nothing to scan.
        if not path.is_file():
            continue
        if path.suffix not in _CHECK_53_SCAN_SUFFIXES:
            continue
        # Skip always-excluded dirs (git state, fixtures).
        skip = False
        for excl in _CHECK_53_EXCLUDE_DIR_PREFIXES:
            if rel_str == excl.rstrip("/") or rel_str.startswith(excl):
                skip = True
                break
        if skip:
            continue
        # Skip allowlisted legitimate carriers (process/history docs + the
        # single check-53 test).
        if _check_53_is_allowlisted(rel_str):
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            continue
        for pat in _CHECK_53_PROHIBITION_PATTERNS:
            if pat.search(text):
                offenders.append(rel_str)
                break

    if offenders:
        for off in sorted(offenders):
            fail(
                f"Check 53 (Guard-A) — worktree-isolation PROHIBITION prose "
                f"reappeared in an active pack surface: {off}. BD-197 REMOVED "
                f"the prohibition (`no worktree isolation` / `Do not pass "
                f"isolation:\"worktree\"`); it must not return. If this is a "
                f"legitimate process/history doc, it belongs under "
                f"`maintenance-docs/archive/` or "
                f"`maintenance-docs/v11-implementation/` (the measured KEEP "
                f"dirs); an active rule surface must NOT re-state the removed "
                f"prohibition. The matcher keys on the prohibition signature "
                f"only — never the legitimate `baseRef`/`bgIsolation` keys."
            )
        return

    ok(
        "Check 53 (Guard-A) — worktree-isolation prohibition stays removed: "
        "zero prohibition-prose hits in active surfaces (allowlist = the two "
        "process/history doc dirs + the narrow validator/check-53-test "
        "self-exception; matcher keys on the prohibition signature, never the "
        "`baseRef`/`bgIsolation` setting keys)."
    )


# ── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ────────────
#
# Guard-A′ (design §13.1a / §11.5 gate (b)): the POSITIVE presence-check —
# the INVERSE of Guard-A (Check 53). Guard-A asserts the removed PROHIBITION
# prose does NOT reappear; Guard-A′ asserts the worktree-isolation feature
# STAYS DOCUMENTED on BOTH surfaces — that each OPTIONAL-FEATURES file DOES
# mention the legitimate setting keys + the in-session backstop recipe. This
# keeps the un-prohibited feature from silently vanishing from the docs.
#
# MANDATED 3-TOKEN FORM (user-approved 2026-06-14; BD-197 Note 14; design
# §13.1a / §18.4): assert BOTH `pack-ops/OPTIONAL-FEATURES.md` (authored in
# C5) AND `project-template/docs/pack/OPTIONAL-FEATURES.md` (authored in C8a)
# each mention the THREE tokens — `baseRef` (the REQUIRED base setting key),
# `bgIsolation` (the background-SESSION gate / BD-218 pointer — documented in
# its correct role, NOT as a subagent control), and `permissions.deny` (the
# documented-optional in-session mechanical-backstop recipe token, §18.2(ii)).
# The `permissions.deny`-token assertion was originally framed "optional
# (P3-architect call)" in the design; BD-197 Note 14 SUPERSEDES that — it is
# now a MANDATED C8b deliverable.
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at C8b
# commit-time (HEAD 286b4b1, 2026-06-14): the exact token strings each file
# carries were measured —
#   `grep -c 'baseRef'         pack-ops/OPTIONAL-FEATURES.md            => 10`
#   `grep -c 'bgIsolation'     pack-ops/OPTIONAL-FEATURES.md            =>  6`
#   `grep -c 'permissions\.deny' pack-ops/OPTIONAL-FEATURES.md          =>  4`
#   `grep -c 'baseRef'         project-template/docs/pack/OPTIONAL-FEATURES.md => 10`
#   `grep -c 'bgIsolation'     project-template/docs/pack/OPTIONAL-FEATURES.md =>  6`
#   `grep -c 'permissions\.deny' project-template/docs/pack/OPTIONAL-FEATURES.md => 4`
# All three tokens are present in BOTH files → the guard is GREEN ON ARRIVAL
# (C5 authored the pack tokens, C8a the project tokens). The assertion is
# sized to EXACTLY these 3 tokens × 2 files — no broader. The prose
# per-spawn `isolation` PARAMETER is explicitly NOT folded into the bounded
# check (it is prose, not a settings key — design §13.1a). The third token
# is the EXACT recipe string the docs carry (`permissions.deny`, matched as a
# literal substring with a real dot), NOT a broad pattern.
#
# WHY SUBSTRING (not regex): the three tokens are literal identifiers
# (`baseRef`, `bgIsolation`) and a literal recipe heading (`permissions.deny`,
# whose `.` is a real dot in the file, e.g. the prose ``the `permissions.deny`
# recipe`` and the JSON `"permissions": { "deny": [ ... ] }` block). A plain
# substring test for `permissions.deny` matches the documented recipe heading
# exactly and is sized no broader than the authored token. No setting-key
# token false-matches unrelated prose (they are unique identifiers).
#
# RUNTIME (ci-check-runtime-compounding): exactly TWO single-file reads (one
# per OPTIONAL-FEATURES surface), each followed by three bounded `in` substring
# tests — NO whole-tree walk, NO subprocess, NO subprocess-per-entry. Trivial
# (well under the per-check WARN budget) across the battery's validate-pack
# invocations; `run_check` times it.
_CHECK_54_OPTIONAL_FEATURES_SURFACES = (
    "pack-ops/OPTIONAL-FEATURES.md",
    "project-template/docs/pack/OPTIONAL-FEATURES.md",
)


def check_optional_features_presence() -> None:
    """Check 54 — BD-197 OPTIONAL-FEATURES presence-check (Guard-A′).

    The POSITIVE inverse of Guard-A (Check 53): asserts BOTH OPTIONAL-FEATURES
    surfaces (`pack-ops/OPTIONAL-FEATURES.md` from C5 +
    `project-template/docs/pack/OPTIONAL-FEATURES.md` from C8a) each mention
    the MANDATED three tokens — `baseRef`, `bgIsolation`, and the
    `permissions.deny` recipe token (user-approved 2026-06-14; BD-197 Note 14;
    design §13.1a / §11.5 gate (b)). Keeps the un-prohibited worktree-isolation
    feature + its in-session backstop recipe DOCUMENTED on both surfaces.
    Measure-then-bound: sized to exactly the 3 authored tokens × 2 files. Two
    single-file reads + bounded substring tests; no subprocess, no whole-tree
    scan.

    Directionality (accepted one-way residual): this is a ONE-WAY presence
    floor — each mandated token must appear in each surface; there is no reverse
    leg. The 2 surfaces are PROSE OPTIONAL-FEATURES docs with no delimited
    enumeration region, so a reverse leg (a token in the surface not in the
    constant FAILs) would require parsing free prose — the rejected prose-parse.
    The constant↔doc pair is backstopped by the Layer-3 doc-constant-twin
    registry mechanism + the BD-255 Part B meta-audit record.
    """
    print("\n── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──")
    any_fail = False
    checked = 0
    for surface in _CHECK_54_OPTIONAL_FEATURES_SURFACES:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 54 (Guard-A′) — OPTIONAL-FEATURES surface {surface} not "
                f"found (the presence-check covers exactly 2 surfaces: pack + "
                f"project)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 54 (Guard-A′) — could not read {surface}.")
            continue
        checked += 1
        missing = [tok for tok in _CHECK_54_REQUIRED_TOKENS if tok not in text]
        if missing:
            any_fail = True
            fail(
                f"Check 54 (Guard-A′) — {surface} is MISSING worktree-isolation "
                f"documentation token(s): {', '.join(missing)}. BOTH "
                f"OPTIONAL-FEATURES surfaces MUST document the worktree "
                f"isolation feature — `baseRef` (required base setting), "
                f"`bgIsolation` (background-session gate / BD-218), and the "
                f"`permissions.deny` in-session backstop recipe (MANDATED per "
                f"BD-197 Note 14). The feature must not silently vanish from "
                f"the docs (design §13.1a, the positive inverse of Guard-A)."
            )

    if not any_fail:
        ok(
            f"Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across "
            f"{checked} surface(s) (pack + project): all "
            f"{len(_CHECK_54_REQUIRED_TOKENS)} mandated tokens "
            f"(`baseRef`, `bgIsolation`, `permissions.deny` recipe) documented "
            f"in each. The un-prohibited worktree-isolation feature + its "
            f"in-session backstop recipe stay documented (BD-197 Note 14)."
        )


# ── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ─────
#
# Guard-C (design §13.3 / §5.4): assert the §5.1 destructive-git-verb DENYLIST
# + the catch-all principle line are ENUMERATED CONSISTENTLY across every
# surface that carries the `agents-never-commit` ban — so no surface silently
# drifts to a stale/short verb list (the C4 verb-folding must stay in parity).
#
# FOLD-vs-STANDALONE (decision 8 / §J3): the plan PREFERS folding verb-parity
# into an existing parity check. Surveyed at C5 commit-time — NO existing check
# fits without over-complication:
#   - Checks 16/18/19 (trinity parity) enforce BYTE parity WITHIN a single
#     trinity location; they neither span the non-trinity surfaces (the
#     commit-discipline skill ×3, pack-coder ×3, PACK-MEMORY-RATIONALE) nor
#     model "verb-SET membership" (their unit is whole-H2-block byte-equality).
#   - Check 45 (rationale↔rule bijection) operates over `[rationale:]` SLUGS,
#     not verb tokens; Check 46 is an ANTI-RESTATE substring scan (the
#     opposite teeth — it forbids verbatim re-statement, it does not assert a
#     shared vocabulary).
#   The 10 surfaces use THREE heterogeneous phrasings (trinity prose; the
#   skill's bulleted `- `git <verb>`` list; the pack-coder per-CLI prose with
#   the Codex `.toml` carrying ONE mid-sentence block). Folding a verb-set
#   membership assertion into any of the above would force that check to grow
#   a second, structurally-different unit — over-complication. So Guard-C is
#   a STANDALONE Check 56 (decision 8 escape hatch).
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound): all 29 verbs of the
# FULL §5.1 set asserted below + the catch-all principle phrase `including but
# not limited to` are measured present in ALL 10 surfaces. The asserted
# CANONICAL set is the FULL §5.1 set with NO exceptions, sized to the
# measured-consistent set. `am` is matched word-bounded by
# `_check_56_verb_present` as `(?<![\w-])am(?![\w-])`, which does NOT
# false-match inside "stream" / "command" / "spam" / "amend"; it is
# present-and-consistent across all 10 surfaces and asserts cleanly at 29/29.
# Each verb is matched as `git <verb>` (the phrasing all surfaces share) OR the
# bare token in a context-bounded way via word boundaries.
#
# RUNTIME (ci-check-runtime-compounding): 10 single-file reads + bounded
# substring/regex tests; NO subprocess, NO whole-tree scan. Trivial across the
# battery's ~202 validate-pack invocations.
# The Antigravity surfaces are the third commit-discipline skill mirror
# `.agents/skills/commit-discipline/SKILL.md` (Antigravity reads workspace
# skills at `.agents/skills/<name>/SKILL.md`) and the third pack-coder agent
# surface, the Antigravity pack-agents plugin bundle
# (`.agents-plugin/pack-agents/agents/pack-coder.md`). The enumeration set is
# 10 surfaces.
_CHECK_56_VERB_PARITY_SURFACES = (
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "pack-ops/PACK-MEMORY-RATIONALE.md",
    ".claude/skills/commit-discipline/SKILL.md",
    ".codex/skills/commit-discipline/SKILL.md",
    ".agents/skills/commit-discipline/SKILL.md",
    ".claude/agents/pack-coder.md",
    ".codex/agents/pack-coder.toml",
    ".agents-plugin/pack-agents/agents/pack-coder.md",
)
# The catch-all principle phrase — the load-bearing closing of the denylist
# (design §5.2). Measured present in all 10 surfaces. BD-221: the phrase is
# matched WHITESPACE-NORMALIZED (runs of whitespace collapsed to one space)
# so a markdown LINE-WRAP between words ("including but not\nlimited to") still
# counts — the Antigravity pack-agents bundle pack-coder.md wraps the phrase
# across a line; a brittle byte-exact substring would miss it.
_CHECK_56_PRINCIPLE_PHRASE = "including but not limited to"


def _check_56_phrase_present(text: str, phrase: str) -> bool:
    """True iff `phrase` appears in `text` modulo whitespace runs (a
    markdown line-wrap inside the phrase still counts). Bounded string ops."""
    norm_text = " ".join(text.split())
    norm_phrase = " ".join(phrase.split())
    return norm_phrase in norm_text


def _check_56_verb_present(text: str, verb: str) -> bool:
    """True iff `verb` appears as a git-verb token in `text`. Word-bounded
    (so `pull` does not match inside `pull-request` etc.); the verb may be
    written as `git <verb>` (trinity/pack-coder prose) or as a bulleted
    `<verb>` token (the commit-discipline skill list)."""
    # `\b<verb>\b` with the verb's hyphen escaped — \b handles the boundary
    # for `cherry-pick`/`filter-branch`/`update-ref` (the `-` is a non-word
    # char so \b sits at the start/end of the whole hyphenated token).
    pat = re.compile(r"(?<![\w-])" + re.escape(verb) + r"(?![\w-])")
    return bool(pat.search(text))


def check_destructive_git_verb_parity() -> None:
    """Check 56 — BD-197 destructive-git-verb enumeration parity (Guard-C).

    Asserts the §5.1 denylist's canonical verb set + the catch-all principle
    phrase appear in every surface that enumerates the `agents-never-commit`
    ban (trinity ×3, PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder
    ×3). Standalone (decision 8 — folding over-complicates). Sized to the
    measured-consistent verb set. 10 single-file reads; no subprocess.

    ONE-WAY presence floor (constant→surface only): the 10 surfaces are three
    heterogeneous grammars (trinity backtick-comma prose with parentheticals +
    ALLOWED `git diff`/`git apply`, commit-discipline SKILL bullets, and TOML
    body with BARE `git <verb>` and no backticks) with no delimited enumeration
    region, so a reverse leg would be the rejected prose-parse; the
    constant↔doc pair is backstopped by the Layer-3 mechanism + the Part B
    meta-audit record.
    """
    print("\n── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ──")
    any_fail = False
    checked = 0
    for surface in _CHECK_56_VERB_PARITY_SURFACES:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — verb-parity surface {surface} not found "
                f"(the measured enumeration set is 10 surfaces)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 56 (Guard-C) — could not read {surface}.")
            continue
        checked += 1
        missing_verbs = [
            v for v in _CHECK_56_CANONICAL_VERBS
            if not _check_56_verb_present(text, v)
        ]
        if missing_verbs:
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — {surface} is MISSING destructive git "
                f"verb(s) from the §5.1 denylist: {', '.join(missing_verbs)}. "
                f"Every surface that enumerates the agents-never-commit ban "
                f"MUST carry the full canonical verb set (enumerate-encoding-"
                f"surfaces; the C4 verb-folding must stay in parity)."
            )
        if not _check_56_phrase_present(text, _CHECK_56_PRINCIPLE_PHRASE):
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — {surface} is MISSING the catch-all "
                f"principle phrase `{_CHECK_56_PRINCIPLE_PHRASE}` that closes "
                f"the denylist (design §5.2). The verb list AND the catch-all "
                f"must both appear so an unlisted future verb is still covered."
            )

    if not any_fail:
        ok(
            f"Check 56 (Guard-C) — destructive-git-verb enumeration parity "
            f"holds across {checked} surface(s) (trinity ×3, "
            f"PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder ×3): "
            f"all {len(_CHECK_56_CANONICAL_VERBS)} canonical §5.1 verbs + the "
            f"catch-all principle phrase present in each."
        )


# ── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
#
# Guard-B PROJECT (design §13.2 / §4.3 project): assert SET-EQUALITY across
# the THREE project legs:
#   {PM-CHAT.md `## Permission profiles` Read-only rows}
#     ↔ {`project-template/agent-run.sh` READONLY_AGENTS array}
#     ↔ {per-agent-file PROSE mandate headers (RO)}
# and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
# agents × 3 CLIs. This is the PROJECT analog of Guard-B(pack) (Check 52,
# C3). It ships in C6b AFTER C6a made the three legs set-consistent, so it
# is GREEN on arrival.
#
# BINDS TO THE PROSE HEADER, NEVER `tools:` (design §13.2). Several RO
# project agents (`reviewer`, `architect`, `auditor`, …) carry
# `Write, Edit` in their Claude `tools:` line yet are RO — keying on
# `tools:` would misclassify them. The Antigravity bundle agent files carry
# NO `tools:` field at all (measured 0/16), so a `tools:`-keyed guard is
# impossible there anyway. The discriminator is the prose mandate header
# (`**Read-only.**` = RO / `**Write-capable (scoped).**` /
# `**Write-capable (script).**` = RW), the PM-CHAT profile table, and the
# `READONLY_AGENTS` runtime array — never the tool list.
#
# Measure-then-bound (ci-guard-design-measure-then-bound): sized to EXACTLY
# the measured 16-agent project set (2 RW `coder`/`repo-ops` + 14 RO) — no
# broader. A NEW project agent or a CLI surface not in this measured set
# MUST be ADDED to `_CHECK_55_PROJECT_AGENTS` / `_CHECK_55_RW_AGENTS` /
# `_CHECK_55_AGENT_DIRS` in lock-step, else the guard develops a blind spot.
#
# Runtime (ci-check-runtime-compounding): a SINGLE bounded pass — at most
# 16 agents × 3 CLI dirs = 48 file reads + one PM-CHAT read + one
# agent-run.sh read; NO whole-tree scan, NO subprocess-per-entry. Negligible
# across the battery's ~200+ validate-pack invocations.
_CHECK_55_PM_CHAT_FILE = "project-template/docs/pack/PM-CHAT.md"
_CHECK_55_AGENT_RUN_FILE = "project-template/agent-run.sh"
# The EXHAUSTIVE measured project-agent set (design §4.3 / RESEARCH-BD-197-
# AGENT-PERMISSION-INVENTORY §1.2): 16 agents = 2 RW + 14 RO.
_CHECK_55_PROJECT_AGENTS = (
    "architect",
    "planner",
    "reviewer",
    "tester",
    "docs-researcher",
    "grpc-schema",
    "auditor",
    "auditor-architecture",
    "auditor-code",
    "auditor-docs",
    "auditor-ops",
    "auditor-security",
    "auditor-tests",
    "auditor-ui",
    "coder",
    "repo-ops",
)
# The measured RW set — exactly two agents (design §4.3 / §13.2 project).
# Everything else in `_CHECK_55_PROJECT_AGENTS` is RO. This tuple is the
# bound the guard asserts the three legs agree on.
_CHECK_55_RW_AGENTS = ("coder", "repo-ops")
# The three CLI agent surfaces + the per-CLI file extension (project-template/).
# Bounded — adding a CLI surface requires extending this map
# (enumerate-encoding-surfaces). BD-221 (Antigravity conversion): the third leg
# is the Antigravity client plugin bundle (.agents-plugin/optiquity-agents/
# agents).
_CHECK_55_AGENT_DIRS = (
    ("project-template/.claude/agents", "md"),
    ("project-template/.codex/agents", "toml"),
    ("project-template/.agents-plugin/optiquity-agents/agents", "md"),
)
# Prose mandate-header signatures (the class discriminator — NEVER `tools:`).
# RW has two flavors on the project side: `coder` is scoped, `repo-ops` is
# script. Either RW header classifies the file RW; the RO header classifies
# it RO.
_CHECK_55_RW_HEADERS = (
    "**Write-capable (scoped).**",
    "**Write-capable (script).**",
)
_CHECK_55_RO_HEADER = "**Read-only.**"


def _check_55_pm_chat_ro_rows(pm_chat_text: str) -> set:
    """Parse the PM-CHAT `## Permission profiles` profile-assignment table;
    return the SET of agent names whose Profile cell is `Read-only`.

    The table row shape is `| `agent` | <Profile> |`. We locate each
    measured agent by its backticked name cell and read the SECOND
    pipe-delimited cell (the Profile). Bounded string ops; no regex
    backtracking risk. A row whose profile starts with `Write-capable`
    is NOT in the RO set.
    """
    ro_rows = set()
    for line in pm_chat_text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        name_cell = cells[0].strip().strip("`")
        if name_cell in _CHECK_55_PROJECT_AGENTS:
            if cells[1].strip() == "Read-only":
                ro_rows.add(name_cell)
    return ro_rows


def _check_55_readonly_agents(agent_run_text: str) -> set:
    """Parse the `READONLY_AGENTS=( ... )` bash array in agent-run.sh; return
    the SET of agent names it lists. Bounded line scan between the opening
    `READONLY_AGENTS=(` and the closing `)`."""
    agents = set()
    in_array = False
    for line in agent_run_text.splitlines():
        stripped = line.strip()
        if not in_array:
            if stripped.startswith("READONLY_AGENTS=("):
                in_array = True
            continue
        if stripped.startswith(")"):
            break
        # Strip inline comments + whitespace; one agent token per line.
        token = stripped.split("#", 1)[0].strip()
        if token:
            agents.add(token)
    return agents


def _check_55_header_class(text: str):
    """Classify an agent file by its PROSE mandate header. Returns
    "RW" / "RO" / None (no recognized header) — NEVER keys on `tools:`."""
    has_rw = any(h in text for h in _CHECK_55_RW_HEADERS)
    has_ro = _CHECK_55_RO_HEADER in text
    if has_rw and not has_ro:
        return "RW"
    if has_ro and not has_rw:
        return "RO"
    # Both present, or neither — ambiguous → treat as unclassified so the
    # set-equality leg FAILs loudly (a file must carry exactly one header).
    return None


def check_project_rw_ro_two_class() -> None:
    """Check 55 — BD-197 project RW/RO two-class consistency (Guard-B project).

    Asserts set-equality across three project legs — the PM-CHAT
    `## Permission profiles` Read-only rows, the `agent-run.sh`
    READONLY_AGENTS array, and the per-agent-file PROSE mandate headers —
    and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
    agents × 3 CLIs. Binds to the prose header, NEVER `tools:` (project RO
    agents carry Write/Edit; Antigravity bundle files carry no `tools:`).
    Sized to the measured 16-agent set (2 RW + 14 RO).
    """
    print("\n── Check 55: BD-197 project RW/RO two-class consistency "
          "(Guard-B project) ──")
    any_fail = False

    expected_rw = set(_CHECK_55_RW_AGENTS)
    expected_ro = set(_CHECK_55_PROJECT_AGENTS) - expected_rw

    # ── Leg 1: the PM-CHAT profile-assignment table (the SSOT). ──
    pm_chat_path = REPO_ROOT / _CHECK_55_PM_CHAT_FILE
    if not pm_chat_path.is_file():
        fail(f"Check 55 — PM-CHAT SSOT {_CHECK_55_PM_CHAT_FILE} not found")
        return
    pm_ro = _check_55_pm_chat_ro_rows(pm_chat_path.read_text())

    # ── Leg 2: the agent-run.sh READONLY_AGENTS array. ──
    agent_run_path = REPO_ROOT / _CHECK_55_AGENT_RUN_FILE
    if not agent_run_path.is_file():
        fail(f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} not found")
        return
    run_ro = _check_55_readonly_agents(agent_run_path.read_text())
    # Bound the array RO set to the measured project agents (a stray token
    # would otherwise pollute the set-equality below).
    run_ro_measured = run_ro & set(_CHECK_55_PROJECT_AGENTS)

    # Leg 1 ↔ expected RO.
    if pm_ro != expected_ro:
        any_fail = True
        fail(
            f"Check 55 — PM-CHAT `## Permission profiles` Read-only rows "
            f"{sorted(pm_ro)} ≠ expected RO set {sorted(expected_ro)} "
            f"(measured 14 RO; the RW set is {sorted(expected_rw)}). The "
            f"PM-CHAT profile table is the project RW/RO SSOT — it must list "
            f"exactly the 14 Read-only agents."
        )

    # Leg 2 ↔ expected RO (the runtime projection must match the SSOT).
    if run_ro_measured != expected_ro:
        any_fail = True
        fail(
            f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} READONLY_AGENTS "
            f"{sorted(run_ro_measured)} ≠ expected RO set "
            f"{sorted(expected_ro)}. READONLY_AGENTS is a CI-checked "
            f"projection of the PM-CHAT profile table; the two must agree."
        )
    # Any token in the array that is NOT a known project agent is a defect.
    stray = run_ro - set(_CHECK_55_PROJECT_AGENTS)
    if stray:
        any_fail = True
        fail(
            f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} READONLY_AGENTS lists "
            f"unknown agent(s) {sorted(stray)} not in the measured 16-agent "
            f"project set (enumerate-encoding-surfaces: extend "
            f"_CHECK_55_PROJECT_AGENTS in lock-step)."
        )

    # ── Leg 3: each agent file's PROSE header; compare to expected class. ──
    for agent in _CHECK_55_PROJECT_AGENTS:
        expected_cls = "RW" if agent in expected_rw else "RO"
        for dir_rel, ext in _CHECK_55_AGENT_DIRS:
            agent_path = REPO_ROOT / dir_rel / f"{agent}.{ext}"
            if not agent_path.is_file():
                any_fail = True
                fail(
                    f"Check 55 — agent file {dir_rel}/{agent}.{ext} not found "
                    f"(the measured project set is 16 agents × 3 CLIs)."
                )
                continue
            header_cls = _check_55_header_class(agent_path.read_text())
            if header_cls is None:
                any_fail = True
                fail(
                    f"Check 55 — {dir_rel}/{agent}.{ext} carries no single "
                    f"recognized prose mandate header (expected exactly one of "
                    f"`{_CHECK_55_RO_HEADER}` or one of "
                    f"{list(_CHECK_55_RW_HEADERS)})."
                )
                continue
            if header_cls != expected_cls:
                any_fail = True
                fail(
                    f"Check 55 — class MISMATCH for `{agent}`: expected "
                    f"`{expected_cls}` (PM-CHAT table + READONLY_AGENTS) ≠ "
                    f"prose header `{header_cls}` (in {dir_rel}/{agent}.{ext}). "
                    f"The PM-CHAT profile table, the READONLY_AGENTS array, "
                    f"and the per-agent prose mandate header must agree "
                    f"(set-equality; Guard-B binds to the prose header, never "
                    f"`tools:`)."
                )

    if not any_fail:
        ok(
            "Check 55 — project RW/RO two-class set-equality holds: 16 agents "
            "× 3 CLIs; PM-CHAT `## Permission profiles` Read-only rows (14) ↔ "
            "agent-run.sh READONLY_AGENTS (14) ↔ per-agent prose mandate "
            "headers; RW set = {`coder`, `repo-ops`} (bound to the prose "
            "header, never `tools:`)."
        )


# ── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity ───────
#              (Guard-C project)
#
# Guard-C PROJECT (design §13.3 / §5.4): the project analog of Check 56
# (Guard-C pack). Asserts that the destructive-git-verb DENYLIST is
# ENUMERATED CONSISTENTLY across every PROJECT surface that carries the
# "No destructive operations" / agents-never-commit ban — so the project
# trinity rule, the 48 per-agent Hard rules, and the `agent-run.sh`
# `--disallowedTools` launcher flags cannot silently drift to a stale/short
# verb list. Without this guard, a future edit could drop `git checkout`
# from one project surface (say the launcher) while leaving it in the
# trinity prose, and nothing would catch the divergence. Ships in C7b AFTER
# C7a (3457569) made the project verb enumeration consistent, so it is GREEN
# on arrival.
#
# FOLD-vs-NEW-CHECK (decision 8 / §J3, the C7b coder's call): a NEW
# STANDALONE Check 57 — NOT folded into Check 56 (Guard-C pack). Rationale:
#   - Check 56 is sized to the FULL §5.1 29-verb set across 10 PACK surfaces
#     that all carry the AGENT ABSOLUTE ban (a closed enumeration). The
#     PROJECT surfaces are heterogeneous: the project trinity carries the
#     PM/human "No destructive operations — needs approval" rule (a SUBSET:
#     working-tree/ref mutators only, with the `including but not limited to`
#     catch-all), while the 48 agent files + the launcher carry the agent
#     ban. So the project-consistent verb set is a measured INTERSECTION of
#     8 verbs (below), NOT the 29-verb pack set, and the catch-all principle
#     phrase is TRINITY-ONLY (the agent files use a closed "Forbidden: …"
#     enumeration with no catch-all). Folding two different canonical verb
#     sets + a surface-conditional principle-phrase assertion into Check 56
#     would force it to model two structurally-different surface families —
#     the same over-complication the C5 coder cited for keeping Check 56
#     standalone. A separate, single-responsibility Check 57 is cleaner
#     (decision 8 escape hatch: "author a standalone check ONLY if folding
#     over-complicates").
#   - C7b is therefore PRESENT (not dropped); the plan's "may drop to 11
#     commits if folded" branch does not apply (this guard is standalone).
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound): the guard asserts a
# PER-TIER canonical verb set — each surface family carries exactly the verbs
# it structurally enumerates, so no surface FALSE-FAILs on a verb its family
# never lists. Re-measured with the `_check_57_verb_present` matcher below
# across all 52 project surfaces (trinity ×3 + 48 agent files + agent-run.sh):
#   - Tier-A trinity (3 surfaces) — 8 verbs, present 3/3:
#         checkout, clean, merge, rebase, reset, restore, stash, worktree
#     the working-tree/ref mutators the open needs-approval "No destructive
#     operations" bullet enumerates.
#   - Tier-B agent defs (48 surfaces = 16 agents × 3 CLIs) — 13 verbs, present
#     48/48: the trinity 8 PLUS the publish/index ops (add, commit, push, tag)
#     + `git apply` that the agents-never-commit Hard rule adds.
#   - Tier-C launcher (agent-run.sh) — 13 verbs, present 1/1: identical to the
#     def set; the --disallowedTools array denies the same publish/index ops +
#     apply (`Bash(git tag:*)` completes the launcher publish-op deny set).
# WHY per-tier, not a flat 8-verb intersection: the publish/index ops +
# `git apply` are absent from the TRINITY "No destructive operations" bullet
# (that rule is the human/PM needs-approval rule scoped to working-tree/ref
# mutators) but PRESENT in every agent Hard rule + the launcher. The old flat-8
# INTERSECTION under-covered Tier-B/C: a def or the launcher could silently
# drop commit/push/tag/apply and still pass. The per-tier sizing binds each
# family to its full measured set — a dropped def-only verb now FAILs.
# EXCLUDED from every tier (measured NOT enumerated as a deny verb anywhere
# consistent, so asserting it would FALSE-FAIL a legitimately-divergent
# surface): `rm`/`mv`/`config`/`switch`/`cherry-pick`/`revert`/`am`/etc.
# (`rm`/`mv` are in the trinity + launcher but NOT the agent Hard rules;
# `config` never appears as a project deny verb). `git apply` IS in the def +
# launcher tiers here; Check 56 (pack) covers pack-side `apply` parity.
#
# PRESENCE-MODEL LIMITATION (once-per-surface): the matcher tests each verb's
# PRESENCE once per surface; it does not count occurrences or verify ordering
# (Check 57 is set-presence, order-agnostic). A surface enumerating a verb once
# satisfies its tier; a reshape of WHICH verbs a tier carries must move here +
# in test-validate-pack-check-57.sh in lock-step (enumerate-encoding-surfaces).
#
# PRINCIPLE PHRASE (measure-then-bound, surface-scoped): the catch-all
# `including but not limited to` is asserted ONLY on the 3 trinity surfaces
# (measured present 3/3 there, 0/49 in the agent files + launcher). The
# trinity rule is open-ended (needs-approval, "including but not limited
# to the ones enumerated here"); the agent files carry a CLOSED absolute
# enumeration ("You MAY NOT run X, Y, Z" / "Forbidden: …") with no
# catch-all, and the launcher is a flag array. Asserting the catch-all on
# the agent files / launcher would FALSE-FAIL — so it is bounded to the
# trinity, where it is the load-bearing close of the open denylist.
#
# FORMAT-AGNOSTIC MATCHER (the project format variety the design names):
# the project surfaces enumerate verbs in THREE shapes —
#   (a) `git <verb>` prose (the trinity bullet + the agent Hard rules);
#   (b) `Bash(git <verb>:*)` launcher flags (agent-run.sh) — matched by the
#       same `git <verb>` rule since "Bash(git reset:" contains "git reset";
#   (c) a slash-separated `Forbidden: a/b/c/d` list (the 6 Codex auditor
#       `.toml` files) — matched by a slash-run of ≥4 verb tokens, which
#       distinguishes the deny list from the 3-member `(add/remove/prune)`
#       worktree-subcommand parenthetical.
# Word-boundary safe (so `clean` ≠ "cleanup", `merge` ≠ "merged"); no
# substring false-positive.
#
# RUNTIME (ci-check-runtime-compounding): 52 single-file reads (3 trinity +
# 48 agents + 1 launcher) + bounded regex tests per file; NO subprocess, NO
# whole-tree scan, NO per-entry subprocess storm. Trivial across the
# battery's ~200+ validate-pack invocations (measured wall-time in the C7b
# IMPL-REPORT).
_CHECK_57_TRINITY_SURFACES = (
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
)
# The 16 project agents × 3 CLIs (the same exhaustive set Check 55 binds to;
# kept as a local tuple so a NEW project agent or CLI surface must be added
# here in lock-step — enumerate-encoding-surfaces — else the guard develops a
# blind spot). The per-CLI extension differs (.md for Claude + the Antigravity
# bundle, .toml for Codex).
_CHECK_57_PROJECT_AGENTS = (
    "architect", "planner", "reviewer", "tester", "docs-researcher",
    "grpc-schema", "auditor", "auditor-architecture", "auditor-code",
    "auditor-docs", "auditor-ops", "auditor-security", "auditor-tests",
    "auditor-ui", "coder", "repo-ops",
)
# BD-221 (Antigravity conversion): the third leg is the Antigravity client
# plugin bundle (.agents-plugin/optiquity-agents/agents).
_CHECK_57_AGENT_DIRS = (
    ("project-template/.claude/agents", "md"),
    ("project-template/.codex/agents", "toml"),
    ("project-template/.agents-plugin/optiquity-agents/agents", "md"),
)
_CHECK_57_LAUNCHER_SURFACE = "project-template/agent-run.sh"
# The PER-TIER canonical verb sets (see the measure-then-bound block above for
# the per-tier sizing rationale + every excluded verb). Each surface family is
# bound to exactly the set it structurally enumerates: trinity 8 / defs 13 /
# launcher 13. A tuple per tier lets the check TIER-SELECT the expected set per
# surface — a def or the launcher silently dropping commit/push/tag/apply now
# FAILs (the old flat-8 intersection under-covered Tier-B/C).
# Tier-A (trinity ×3): 8 — the working-tree/ref mutators the open
# needs-approval "No destructive operations" bullet enumerates.
_CHECK_57_TRINITY_VERBS = (
    "checkout", "clean", "merge", "rebase",
    "reset", "restore", "stash", "worktree",
)
# Tier-B (48 agent Hard rules): 13 — the trinity 8 + the publish/index ops
# (add, commit, push, tag) + `git apply` the agents-never-commit ban adds.
_CHECK_57_DEF_VERBS = _CHECK_57_TRINITY_VERBS + (
    "add", "commit", "push", "tag", "apply",
)
# Tier-C (agent-run.sh launcher --disallowedTools): 13 — identical to the def
# set; the deny-flag array enumerates the same publish/index ops + apply
# (`Bash(git tag:*)` completes the launcher publish-op deny set).
_CHECK_57_LAUNCHER_VERBS = _CHECK_57_DEF_VERBS
# The catch-all principle phrase — asserted ONLY on the trinity surfaces
# (the open needs-approval rule); the agent files carry a closed enumeration
# with no catch-all (measure-then-bound, surface-scoped).
_CHECK_57_PRINCIPLE_PHRASE = "including but not limited to"


def _check_57_verb_present(text: str, verb: str) -> bool:
    """True iff `verb` appears as a destructive-git-verb token in `text`,
    format-agnostic across the project surface families:
      (a) `git <verb>` (trinity prose + agent Hard rules) — also matches the
          launcher `Bash(git <verb>:*)` form (it contains `git <verb>`);
      (b) a slash-separated deny list `a/b/c/d` with >=4 members (the Codex
          auditor `Forbidden: …` form).
    Word-bounded so `clean` does not match inside `cleanup`, and the
    >=4-member slash-run rule rejects the 3-member `(add/remove/prune)`
    worktree-subcommand parenthetical (so `add` is not a false positive)."""
    v = re.escape(verb)
    # (a) `git <verb>` form (covers prose + the launcher `Bash(git <verb>:`).
    if re.search(r"git\s+" + v + r"(?![\w-])", text):
        return True
    # (b) slash-separated forbidden list with >=4 slash-joined verb tokens.
    for m in re.finditer(r"(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*", text):
        if verb in m.group(0).split("/"):
            return True
    return False


def check_project_destructive_git_verb_parity() -> None:
    """Check 57 — BD-197 PROJECT destructive-git-verb enumeration parity
    (Guard-C project).

    The project analog of Check 56 (Guard-C pack). Asserts the
    project-consistent canonical verb set (the measured 8-verb intersection)
    appears in every project surface that enumerates the "No destructive
    operations" / agents-never-commit ban — the project trinity ×3, the 48
    per-agent Hard rules (16 agents × 3 CLIs), and the `agent-run.sh`
    `--disallowedTools` launcher flags — and that the catch-all principle
    phrase appears on the trinity (the open needs-approval rule). Standalone
    Check 57 (decision 8 — folding into Check 56 over-complicates: different
    canonical set + a trinity-only catch-all). Format-agnostic matcher
    (`git <verb>` prose / `Bash(git <verb>:*)` launcher / slash-list).
    52 single-file reads; no subprocess.
    """
    print(
        "\n── Check 57: BD-197 PROJECT destructive-git-verb enumeration "
        "parity (Guard-C project) ──"
    )
    any_fail = False
    checked = 0

    # Build the full project surface list: trinity ×3 + 48 agents + launcher.
    surfaces = list(_CHECK_57_TRINITY_SURFACES)
    for dir_rel, ext in _CHECK_57_AGENT_DIRS:
        for agent in _CHECK_57_PROJECT_AGENTS:
            surfaces.append(f"{dir_rel}/{agent}.{ext}")
    surfaces.append(_CHECK_57_LAUNCHER_SURFACE)

    for surface in surfaces:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — verb-parity surface {surface} "
                f"not found (the measured enumeration set is "
                f"{len(surfaces)} project surfaces: trinity ×3, 48 agent "
                f"files, agent-run.sh)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 57 (Guard-C project) — could not read {surface}.")
            continue
        checked += 1
        # TIER-SELECT the expected verb set per surface family (per-tier
        # measure-then-bound): trinity 8 / def 13 / launcher 13. A def or the
        # launcher silently dropping commit/push/tag/apply now FAILs.
        if surface in _CHECK_57_TRINITY_SURFACES:
            expected = _CHECK_57_TRINITY_VERBS
        elif surface == _CHECK_57_LAUNCHER_SURFACE:
            expected = _CHECK_57_LAUNCHER_VERBS
        else:
            expected = _CHECK_57_DEF_VERBS
        missing_verbs = [
            v for v in expected
            if not _check_57_verb_present(text, v)
        ]
        if missing_verbs:
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — {surface} is MISSING "
                f"destructive git verb(s) from the project-consistent "
                f"denylist: {', '.join(missing_verbs)}. Every project surface "
                f"that enumerates the No-destructive / agents-never-commit "
                f"ban MUST carry the full canonical verb set "
                f"(enumerate-encoding-surfaces; the project trinity rule, the "
                f"48 agent Hard rules, and the agent-run.sh --disallowedTools "
                f"flags must stay in parity)."
            )
        # The catch-all principle phrase is asserted ONLY on the trinity
        # surfaces (the open needs-approval rule; the agent files + launcher
        # carry a closed enumeration with no catch-all — measure-then-bound).
        if surface in _CHECK_57_TRINITY_SURFACES \
                and _CHECK_57_PRINCIPLE_PHRASE not in text:
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — trinity surface {surface} is "
                f"MISSING the catch-all principle phrase "
                f"`{_CHECK_57_PRINCIPLE_PHRASE}` that closes the open "
                f"No-destructive denylist. The verb list AND the catch-all "
                f"must both appear in the trinity so an unlisted future verb "
                f"is still covered."
            )

    if not any_fail:
        ok(
            f"Check 57 (Guard-C project) — destructive-git-verb enumeration "
            f"parity holds across {checked} project surface(s) (trinity ×3, "
            f"48 agent Hard rules [16 agents × 3 CLIs], agent-run.sh "
            f"--disallowedTools): the full per-tier canonical verb set present "
            f"in each surface (trinity {len(_CHECK_57_TRINITY_VERBS)} / defs "
            f"{len(_CHECK_57_DEF_VERBS)} / launcher "
            f"{len(_CHECK_57_LAUNCHER_VERBS)}); the catch-all principle phrase "
            f"present on each trinity surface."
        )


# ── Check 72: project-side empty-template shape + _rules.md schema (BD-206) ──

# Sanctioned sidecar vocabulary per ARCHITECTURE-BD-206.md §3.1. `_format.md`
# and `_scaffolding.md` are FORBIDDEN in every stream; the project monoliths
# (BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md / GROUPINGS.md) are
# FORBIDDEN under the no-mirror model. `_index.md` is admitted for the
# impl-plan stream only (groupings are orderless — no `_index.md`, and the
# fixed Kind enum means no extension sidecar).
_CHECK_72_PROJECT_TEMPLATE_DIR = "project-template/docs/project"
_CHECK_72_STREAMS = (
    # (stream subdir, schema-section header, admitted-optional sidecars)
    ("backlog",             "## Entry schema",    ()),
    ("implementation-plan", "## Entry schema",    ("_index.md",)),
    ("changelog",           "## Entry structure", ()),
    ("groupings",           "## Entry schema",    ()),
)
# Required + forbidden sidecar basenames (the EMPTY shipped template carries
# `_rules.md` + `_intro.md`; `_toc.md`/`_index.md` are generated at install,
# so they are ADMITTED-if-present but not required in the empty template).
_CHECK_72_REQUIRED_SIDECARS = ("_rules.md", "_intro.md")
_CHECK_72_FORBIDDEN_SIDECARS = ("_format.md", "_scaffolding.md")
_CHECK_72_FORBIDDEN_MONOLITHS = (
    "BACKLOG.md", "IMPLEMENTATION-PLAN.md", "CHANGELOG.md", "GROUPINGS.md",
)


def _check_72_parse_rules_section(text: str, header: str) -> dict[str, str]:
    """Parse a `_rules.md` schema block into a {key: tokens} map.

    Reuses the bash `pe_supporting_files_admitted` grammar
    (`scripts/lib/per-entry/_lib.sh`): inside the named `## <Section>`
    H2 block, each `- key: tokens` bullet contributes one entry; the
    block ends at the next `## ` line. Returns an empty dict if the
    section is absent.
    """
    result: dict[str, str] = {}
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


def check_project_template_empty_shape() -> None:
    """Check 72 — project-side empty-template shape + `_rules.md` schema (BD-206).

    Validates the SHIPPED EMPTY `project-template/docs/project/` template:
      - each stream carries the required sidecars (`_rules.md` + `_intro.md`);
      - no FORBIDDEN sidecar (`_format.md` / `_scaffolding.md`) is present;
      - no monolithic mirror (`{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`)
        is present (no-mirror model);
      - no entry file ships in the empty template (greenfield starts empty);
      - `_rules.md` parses and declares a well-formed schema block (the
        per-stream `## Entry schema` / `## Entry structure` section, parsed
        with the same grammar the bash validator uses — Item-8 schema SSOT).

    Pack-side scope: the template is EMPTY during pack development, so this
    leg validates the TEMPLATE SHAPE + schema-block well-formedness, NOT
    entries. SKIPs (lenient) if the template directory is absent.

    Cheap (ci-check-runtime-compounding): reads at most ~6 small files +
    a bounded `os.scandir` per stream; no subprocess, no whole-tree walk.
    """
    print("\n── Check 72: project empty-template shape + _rules.md schema (BD-206) ──")
    base = REPO_ROOT / _CHECK_72_PROJECT_TEMPLATE_DIR
    if not base.is_dir():
        ok(f"{_CHECK_72_PROJECT_TEMPLATE_DIR}/ absent — skipping (lenient)")
        return

    any_fail = False
    for subdir, schema_header, admitted in _CHECK_72_STREAMS:
        stream_dir = base / subdir
        rel = f"{_CHECK_72_PROJECT_TEMPLATE_DIR}/{subdir}"
        if not stream_dir.is_dir():
            fail(f"{rel}/ — stream directory missing")
            any_fail = True
            continue

        names = {p.name for p in stream_dir.iterdir() if p.is_file()}

        # Required sidecars present.
        for required in _CHECK_72_REQUIRED_SIDECARS:
            if required not in names:
                fail(f"{rel}/{required} — required sidecar missing")
                any_fail = True

        # Forbidden sidecars absent.
        for forbidden in _CHECK_72_FORBIDDEN_SIDECARS:
            if forbidden in names:
                fail(f"{rel}/{forbidden} — FORBIDDEN sidecar present "
                     f"(no-mirror form-family model)")
                any_fail = True

        # No monolithic mirror at the stream dir or its parent.
        for monolith in _CHECK_72_FORBIDDEN_MONOLITHS:
            if (base / monolith).is_file():
                fail(f"{_CHECK_72_PROJECT_TEMPLATE_DIR}/{monolith} — "
                     f"FORBIDDEN project monolith present (no-mirror model)")
                any_fail = True

        # No entry file in the EMPTY template (only `_`-prefixed sidecars).
        for name in names:
            if not name.startswith("_"):
                fail(f"{rel}/{name} — unexpected non-sidecar file in the "
                     f"EMPTY shipped template (greenfield starts empty)")
                any_fail = True

        # `_rules.md` parses + declares a well-formed schema block.
        rules = stream_dir / "_rules.md"
        if rules.is_file():
            try:
                rules_text = rules.read_text()
            except (UnicodeDecodeError, OSError) as exc:
                fail(f"{rel}/_rules.md — unreadable: {exc}")
                any_fail = True
                continue

            # Supporting-files section must NOT list a forbidden sidecar and
            # MUST list the admitted optional sidecars for this stream.
            # `## Supporting files` uses bare `- basename` bullets (no colon),
            # so parse it as a basename set directly.
            support_names = set()
            in_support = False
            for line in rules_text.splitlines():
                if line.startswith("## Supporting files"):
                    in_support = True
                    continue
                if in_support and line.startswith("## "):
                    break
                if in_support and line.startswith("- "):
                    support_names.add(line[2:].strip().strip("`"))
            for forbidden in _CHECK_72_FORBIDDEN_SIDECARS:
                if forbidden in support_names:
                    fail(f"{rel}/_rules.md — Supporting files lists FORBIDDEN "
                         f"sidecar {forbidden}")
                    any_fail = True
            for sidecar in admitted:
                if sidecar not in support_names:
                    fail(f"{rel}/_rules.md — Supporting files must admit "
                         f"{sidecar} for this stream")
                    any_fail = True

            # Schema block present + non-empty (well-formed key: tokens).
            schema = _check_72_parse_rules_section(rules_text, schema_header)
            if not schema:
                fail(f"{rel}/_rules.md — missing or empty schema block "
                     f"({schema_header})")
                any_fail = True

    if not any_fail:
        ok("Check 72 — project empty-template shape conforms: required "
           "sidecars present; no forbidden sidecar/monolith; no stray entry; "
           "each _rules.md declares a well-formed schema block.")


# ── Check 73: project impl-plan `_index.md` consistency (BD-206 O11) ─────────
#
# The MANDATORY `_index.md` validation (G-3), pack-side leg. The shipped
# `project-template/docs/project/implementation-plan/` stream is EMPTY
# during pack development (no `phase-*.md`), so this leg validates the
# MECHANISM / empty-state: (a) the impl-plan stream parses; (b) any
# `_index.md` present is membership-synced with the (empty) phase set;
# (c) the two hard properties' Python implementation BITES (a built-in
# synthetic self-check on a populated tree confirms the matcher still has
# teeth even though the shipped template has no entries to exercise it).
#
# The two hard properties (DECISIONS-BD-206-RESTART.md G-3):
#   (1) hard-dependency-order consistency — the `_index.md` serial order
#       is a VALID topological order of the rule-based deps (from each
#       phase's `Blockers` / `Unblocks` / `Dependencies` / `Prerequisite`
#       SSOT);
#   (2) per-entry ↔ `_index.md` membership sync — the `_index.md`
#       membership matches the tree's `phase-*.md` files EXACTLY
#       (analogous to the `_toc.md`-sync Check 33).
#
# The CLIENT-side leg (populated-tree validation, "both repos" per Item-7)
# lives in `project-template/scripts/validate-docs.sh` `run_conformance`;
# the dependency-derived GENERATOR + the shared validator live in
# `scripts/lib/per-entry/index-generate.sh` (the realized consumer named
# in that file's docstring, rule-8 chain). All three implement the same
# two properties; the Python here parses the phase deps with the same
# form-family-bullet grammar the bash lib + the client leg use (Item-8
# single-schema-SSOT spirit: one grammar, three implementations, one
# property set).
#
# Cheap (ci-check-runtime-compounding): a bounded os.scandir on one stream
# dir + at most ~N small reads; no subprocess, no whole-tree walk; the
# self-check builds its synthetic tree in-memory (no disk).

_CHECK_73_IMPLPLAN_DIR = (
    "project-template/docs/project/implementation-plan"
)
_CHECK_73_PHASE_RE = re.compile(r"^phase-(\d+)\.md$")
_CHECK_73_INDEX_BULLET_RE = re.compile(r"^- \[phase-(\d+)\]")


def _check_73_field_value(body: str, field: str) -> str:
    """Trimmed value of a `- **Field**:` / `Field:` form-family bullet, or
    ''. Mirrors the bash lib `field_value` + the client-leg grammar."""
    esc = re.escape(field)
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + esc + r"\*{0,2}\s*:(.*)$",
        re.MULTILINE)
    m = rx.search(body)
    return m.group(1).strip().strip("*").strip() if m else ""


def _check_73_phase_refs(value: str) -> set:
    """Every `phase-N` number referenced in a field value (tolerates
    `none` / comma- / space- / `and`-separated lists)."""
    return set(re.findall(r"phase-(\d+)", value))


def _check_73_collect(entries: dict):
    """entries: {phase-num: body}. Returns (present, titles, edges) where
    edges is the set of (prereq, dependent) ordering constraints derived
    from `Blockers`/`Dependencies`/`Prerequisite` (prereq edges) +
    `Unblocks` (dependent edges). Self-edges + edges to absent phases are
    dropped (membership-sync flags missing files separately)."""
    present = set(entries)
    titles = {}
    edges = set()
    for num, body in entries.items():
        tm = re.search(r"(?m)^## Phase %s — (.+)$" % re.escape(num), body)
        titles[num] = tm.group(1).strip() if tm else "phase-%s" % num
        prereq = set()
        for fld in ("Blockers", "Dependencies", "Prerequisite"):
            prereq |= _check_73_phase_refs(_check_73_field_value(body, fld))
        dep = _check_73_phase_refs(_check_73_field_value(body, "Unblocks"))
        for b in prereq:
            if b in present and b != num:
                edges.add((b, num))
        for u in dep:
            if u in present and u != num:
                edges.add((num, u))
    return present, titles, edges


def _check_73_toposort(present: set, edges: set):
    """Deterministic Kahn sort (ties by ascending phase number). Returns
    (order, acyclic)."""
    indeg = {p: 0 for p in present}
    adj = {p: [] for p in present}
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


def _check_73_parse_index_order(text: str) -> list:
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
            m = _CHECK_73_INDEX_BULLET_RE.match(line)
            if m:
                order.append(m.group(1))
    return order


def _check_73_validate(entries: dict, index_text) -> list:
    """The two-property validator, in-memory. entries: {num: body};
    index_text: the `_index.md` content (or None if absent). Returns a
    list of failure strings ([] = conformant)."""
    fails = []
    present, _titles, edges = _check_73_collect(entries)

    if not present:
        # No phase entries — an `_index.md`, if present, must list nothing.
        if index_text is not None:
            listed = _check_73_parse_index_order(index_text)
            if listed:
                fails.append(
                    "_index.md lists phases %s but the tree has no "
                    "phase-*.md entries (membership drift)"
                    % ["phase-%s" % n for n in sorted(set(listed), key=int)])
        return fails

    if index_text is None:
        fails.append(
            "_index.md missing — the impl-plan stream has %d phase "
            "entry/entries but no _index.md ordering" % len(present))
        return fails

    listed = _check_73_parse_index_order(index_text)
    listed_set = set(listed)

    # (2) membership sync.
    missing = sorted(present - listed_set, key=int)
    extra = sorted(listed_set - present, key=int)
    if missing:
        fails.append("missing from _index.md: %s"
                     % ["phase-%s" % n for n in missing])
    if extra:
        fails.append("extra in _index.md (no such phase-*.md): %s"
                     % ["phase-%s" % n for n in extra])
    if len(listed) != len(listed_set):
        fails.append("duplicate listing in _index.md")

    # (1) hard-dependency-order consistency.
    pos = {n: i for i, n in enumerate(listed)}
    for (a, b) in sorted(edges):
        if a in pos and b in pos and pos[a] >= pos[b]:
            fails.append(
                "hard-dependency violated: phase-%s must precede phase-%s "
                "but _index.md lists phase-%s first" % (a, b, b))

    _order, acyclic = _check_73_toposort(present, edges)
    if not acyclic:
        fails.append("dependency cycle — no valid topological order exists")
    return fails


def _check_73_self_check() -> list:
    """In-memory synthetic self-check: confirm the two-property matcher
    PASSES a conforming tree and BITES each violation class. Returns a
    list of self-check failure strings ([] = the matcher has teeth)."""
    sc_fails = []
    p0 = ("## Phase 0 — Bootstrap\n- **Blockers**: none\n"
          "- **Unblocks**: phase-1\n")
    p1 = ("## Phase 1 — Middle\n- **Blockers**: phase-0\n"
          "- **Unblocks**: phase-2\n")
    p2 = ("## Phase 2 — Final\n- **Blockers**: phase-1\n"
          "- **Unblocks**: none\n")
    entries = {"0": p0, "1": p1, "2": p2}
    good_idx = ("## Serial order\n\n"
                "- [phase-0](./phase-0.md) — Bootstrap\n"
                "- [phase-1](./phase-1.md) — Middle\n"
                "- [phase-2](./phase-2.md) — Final\n")

    def expect(label, entries_, idx, want_fail):
        got = bool(_check_73_validate(entries_, idx))
        if got != want_fail:
            sc_fails.append(
                "self-check %s: expected %s, got %s"
                % (label, "FAIL" if want_fail else "PASS",
                   "FAIL" if got else "PASS"))

    expect("clean", entries, good_idx, False)                 # conforming
    expect("empty-clean", {}, None, False)                    # greenfield
    # ORDER violation — reversed order.
    bad_order = ("## Serial order\n\n"
                 "- [phase-2](./phase-2.md) — Final\n"
                 "- [phase-1](./phase-1.md) — Middle\n"
                 "- [phase-0](./phase-0.md) — Bootstrap\n")
    expect("order-violation", entries, bad_order, True)
    # MEMBERSHIP missing — drop phase-2 from the index.
    miss_idx = ("## Serial order\n\n"
                "- [phase-0](./phase-0.md) — Bootstrap\n"
                "- [phase-1](./phase-1.md) — Middle\n")
    expect("membership-missing", entries, miss_idx, True)
    # MEMBERSHIP extra — index lists a phase not on disk.
    extra_idx = good_idx + "- [phase-9](./phase-9.md) — Ghost\n"
    expect("membership-extra", entries, extra_idx, True)
    # MISSING index entirely with phases present.
    expect("missing-index", entries, None, True)
    # CYCLE.
    cyc = {"0": "## Phase 0 — A\n- **Blockers**: phase-1\n",
           "1": "## Phase 1 — B\n- **Blockers**: phase-0\n"}
    cyc_idx = ("## Serial order\n\n"
               "- [phase-0](./phase-0.md) — A\n"
               "- [phase-1](./phase-1.md) — B\n")
    expect("cycle", cyc, cyc_idx, True)
    return sc_fails


def check_project_index_consistency() -> None:
    """Check 73 — project impl-plan `_index.md` consistency (BD-206 O11).

    Validates the MANDATORY `_index.md` property set (G-3) against the
    shipped `project-template/docs/project/implementation-plan/` stream.
    The shipped template is EMPTY (no `phase-*.md`), so this leg validates
    the MECHANISM / empty-state PLUS a synthetic self-check that the
    two-property matcher still bites. The client-side populated-tree leg
    lives in `validate-docs.sh`; the generator + shared validator live in
    `scripts/lib/per-entry/index-generate.sh`.

    SKIPs (lenient) if the impl-plan stream directory is absent.
    Cheap (ci-check-runtime-compounding): one bounded scandir + small
    reads + an in-memory self-check.
    """
    print("\n── Check 73: project impl-plan _index.md consistency (BD-206) ──")
    stream_dir = REPO_ROOT / _CHECK_73_IMPLPLAN_DIR
    if not stream_dir.is_dir():
        ok(f"{_CHECK_73_IMPLPLAN_DIR}/ absent — skipping (lenient)")
        return

    any_fail = False

    # Self-check the matcher has teeth (the empty shipped template cannot
    # exercise the order/membership legs otherwise).
    for sc in _check_73_self_check():
        fail(f"Check 73 self-check — {sc}")
        any_fail = True

    # Validate the live (empty) impl-plan stream.
    entries = {}
    try:
        names = [p.name for p in stream_dir.iterdir() if p.is_file()]
    except OSError as exc:
        fail(f"{_CHECK_73_IMPLPLAN_DIR}/ — cannot scan: {exc}")
        return
    for name in names:
        m = _CHECK_73_PHASE_RE.match(name)
        if not m:
            continue
        try:
            entries[m.group(1)] = (stream_dir / name).read_text()
        except (UnicodeDecodeError, OSError) as exc:
            fail(f"{_CHECK_73_IMPLPLAN_DIR}/{name} — unreadable: {exc}")
            any_fail = True

    index_path = stream_dir / "_index.md"
    index_text = None
    if index_path.is_file():
        try:
            index_text = index_path.read_text()
        except (UnicodeDecodeError, OSError) as exc:
            fail(f"{_CHECK_73_IMPLPLAN_DIR}/_index.md — unreadable: {exc}")
            any_fail = True

    for violation in _check_73_validate(entries, index_text):
        fail(f"{_CHECK_73_IMPLPLAN_DIR}/_index.md — {violation}")
        any_fail = True

    if not any_fail:
        n = len(entries)
        shape = ("empty template (no phase entries, no stray _index.md)"
                 if n == 0 else
                 f"{n} phase entry/entries, _index.md order + membership "
                 f"consistent")
        ok(f"Check 73 — impl-plan _index.md consistency holds: {shape}; "
           f"the two-property matcher (topological-order + membership-sync) "
           f"self-checks with teeth.")


# ── Check 74: project changelog conformance (BD-206 O12) ────────────────────
#
# The structured changelog conformance check (G-2/G-2b), pack-side leg. The
# shipped `project-template/docs/project/changelog/` stream is EMPTY during
# pack development (no `YYYY-MM-DD-*.md` entries), so this leg validates the
# MECHANISM / empty-state: (a) the changelog `_rules.md` `## Entry structure`
# block parses + declares the enforced keys; (b) any entry present is
# conformant; (c) a synthetic self-check confirms the matcher still BITES (the
# empty shipped template has no entries to exercise it).
#
# The reconciled rule (design §3.4, parsed from the changelog `_rules.md`
# `## Entry structure` schema SSOT — never hard-coded):
#   (1) a NARRATIVE field is required for EVERY entry — `**Summary**:` OR
#       `**Scope**:` (`narrative-fields`); it is the sole required field;
#   (2) `entry-max-lines` cap (≤ 180; gold max 130);
#   (3) `summary-max-words` cap (≤ 250; gold max 243; reads Summary OR Scope).
# `Test count` and `Files` (any `**Files <verb>**:` label) are ADVISORY /
# admitted, not required.
#
# The CLIENT-side leg (populated-tree validation, "both repos" per Item-7)
# lives in `project-template/scripts/validate-docs.sh` `_conf_check_changelog_entry`;
# both legs parse the SAME `## Entry structure` schema block with the same
# grammar (Item-8 single-schema-SSOT: one schema in `_rules.md`, two parsers,
# one rule set). The caps are read FROM the schema (not literals here), so a
# `_rules.md` cap edit reaches both legs without a code change.
#
# Cheap (ci-check-runtime-compounding): a bounded os.scandir on one stream dir
# + at most ~N small reads + deterministic line/word counts; no subprocess, no
# whole-tree walk; the self-check builds its synthetic entries in-memory.

_CHECK_74_CHANGELOG_DIR = (
    "project-template/docs/project/changelog"
)
_CHECK_74_ENTRY_RE = re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$")
_CHECK_74_NARRATIVE_RE = re.compile(
    r"^\s*(?:[-*]\s*)?\*{0,2}(?:Summary|Scope)\*{0,2}\s*:(.*)$", re.MULTILINE)


def _check_74_field_present(body: str, field: str) -> bool:
    """True iff the entry carries a `**Field**:` / `Field:` / `- Field:`
    labeled line. Mirrors the client-leg `_conf_entry_field_present`."""
    esc = re.escape(field)
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + esc + r"\*{0,2}\s*:", re.MULTILINE)
    return rx.search(body) is not None


def _check_74_summary_words(body: str) -> int:
    """Word count of the narrative field value (Summary or Scope, first line),
    or 0 if absent."""
    m = _CHECK_74_NARRATIVE_RE.search(body)
    return len(m.group(1).split()) if m else 0


def _check_74_caps(schema: dict):
    """Read the integer caps from the parsed `## Entry structure` schema
    (NOT literals). Returns (entry_max_lines, summary_max_words); a cap
    that is absent / unparseable is None (that rule then does not fire —
    the SSOT governs)."""
    def _int(key):
        tok = (schema.get(key, "") or "").split()
        if not tok:
            return None
        try:
            return int(tok[0])
        except ValueError:
            return None
    return _int("entry-max-lines"), _int("summary-max-words")


def _check_74_validate(entries: dict, schema: dict) -> list:
    """The reconciled changelog conformance validator, in-memory.
    Rule: a NARRATIVE field (Summary OR Scope) is required for every entry
    (the sole required field); Test count and Files are advisory. Plus the
    two schema-driven size caps. entries: {filename: body}."""
    fails = []
    narrative_labels = [t.strip().strip('"') for t in
                        re.findall(r'"[^"]+"|\S+',
                                   schema.get("narrative-fields", "Summary Scope"))]
    entry_max_lines, summary_max_words = _check_74_caps(schema)

    for name in sorted(entries):
        body = entries[name]
        # R1 — narrative required (Summary OR Scope).
        if not any(_check_74_field_present(body, lbl) for lbl in narrative_labels):
            fails.append(
                "%s: missing narrative field (%s)"
                % (name, " or ".join(narrative_labels)))
        # R2 — entry-max-lines cap.
        if entry_max_lines is not None:
            nl = len(body.splitlines())
            if nl > entry_max_lines:
                fails.append(
                    "%s: entry has %d lines > entry-max-lines %d"
                    % (name, nl, entry_max_lines))
        # R3 — narrative-max-words cap.
        if summary_max_words is not None:
            sw = _check_74_summary_words(body)
            if sw > summary_max_words:
                fails.append(
                    "%s: narrative has %d words > summary-max-words %d"
                    % (name, sw, summary_max_words))
    return fails


def _check_74_self_check() -> list:
    """In-memory synthetic self-check: confirm the reconciled matcher PASSES
    a conforming set (narrative required; Test count + Files advisory) and
    BITES each violation class (no narrative / over-lines / over-words).
    Returns a list of self-check failure strings ([] = the matcher has teeth)."""
    sc_fails = []
    schema = {
        "core-fields": "narrative",
        "narrative-fields": "Summary Scope",
        "advisory-fields": '"Test count" Files',
        "entry-max-lines": "180",
        "summary-max-words": "250",
    }
    code_ok = ("### 2026-04-20 — Phase 35 — Sample\n\n"
               "**Summary**: did the thing.\n"
               "**Test count**: 12 passing\n"
               "**Files modified (3)**: a.swift, b.swift, c.swift\n")
    narrative_ok = ("### 2026-03-30 — v8 Migration — Pack\n\n"
                    "**Summary**: narrative-only entry, no code changed.\n")
    scope_ok = ("### 2026-03-27 — Phase 14 — Test Audit\n\n"
                "**Scope**: 24-item audit adding test coverage.\n")

    def expect(label, entries, want_fail):
        got = bool(_check_74_validate(entries, schema))
        if got != want_fail:
            sc_fails.append(
                "self-check %s: expected %s, got %s"
                % (label, "FAIL" if want_fail else "PASS",
                   "FAIL" if got else "PASS"))

    expect("code-clean", {"a.md": code_ok}, False)
    expect("narrative-only-clean", {"b.md": narrative_ok}, False)
    expect("scope-only-clean", {"s.md": scope_ok}, False)
    expect("empty-clean", {}, False)
    # Missing Files (Summary + Test) → PASS (Files advisory).
    no_files = ("### 2026-04-20 — Phase 9 — X\n\n"
                "**Summary**: did it.\n**Test count**: 4 passing\n")
    expect("missing-files", {"c.md": no_files}, False)
    # Missing Test count (Summary + Files) → PASS (Test advisory).
    no_test = ("### 2026-04-20 — Phase 9 — X\n\n"
               "**Summary**: did it.\n**Files modified**: a.swift\n")
    expect("missing-testcount", {"e.md": no_test}, False)
    # Missing narrative (Files + Test, no Summary/Scope) → FAIL (R1).
    no_sum = ("### 2026-04-20 — Phase 9 — X\n\n"
              "**Files modified**: a.swift\n**Test count**: 4 passing\n")
    expect("missing-summary", {"d.md": no_sum}, True)
    # No narrative at all (prose only) → FAIL (R1).
    no_narrative = "### 2026-03-30 — Migration — Y\n\nSome prose, no narrative.\n"
    expect("no-narrative", {"f.md": no_narrative}, True)
    # entry-max-lines violation → FAIL.
    long_entry = code_ok + ("\nline\n" * 200)
    expect("entry-too-long", {"g.md": long_entry}, True)
    # summary-max-words violation → FAIL.
    long_sum = ("### 2026-04-20 — Phase 9 — X\n\n"
                "**Summary**: " + ("word " * 260) + "\n"
                "**Test count**: 4 passing\n"
                "**Files modified**: a.swift\n")
    expect("summary-too-long", {"h.md": long_sum}, True)
    # Scope narrative over the word cap → FAIL (R3 reads Scope now).
    scope_over = ("### 2026-03-27 — Phase 14 — Test Audit\n\n"
                  "**Scope**: " + ("word " * 260) + "\n")
    expect("scope-over-words", {"i.md": scope_over}, True)
    return sc_fails


def check_project_changelog_conformance() -> None:
    """Check 74 — project changelog conformance (BD-206 O12).

    Validates the structured changelog conformance rule set (G-2/G-2b)
    against the shipped `project-template/docs/project/changelog/` stream.
    The shipped template is EMPTY (no entries), so this leg validates the
    MECHANISM / empty-state PLUS a synthetic self-check that the reconciled
    matcher still bites. The client-side populated-tree leg lives in
    `validate-docs.sh` `_conf_check_changelog_entry`; both parse the SAME
    `## Entry structure` schema block (Item-8 single-schema-SSOT).

    The reconciled rule (read FROM the `_rules.md` schema, never hard-coded):
    a NARRATIVE field (`Summary` OR `Scope`, `narrative-fields`) required for
    EVERY entry — the sole required field; `entry-max-lines`; `summary-max-words`
    (reads whichever narrative field is present). `Test count` and `Files` are
    advisory/admitted.

    SKIPs (lenient) if the changelog stream directory is absent.
    Cheap (ci-check-runtime-compounding): one bounded scandir + small reads
    + deterministic line/word counts + an in-memory self-check.
    """
    print("\n── Check 74: project changelog conformance (BD-206) ──")
    stream_dir = REPO_ROOT / _CHECK_74_CHANGELOG_DIR
    if not stream_dir.is_dir():
        ok(f"{_CHECK_74_CHANGELOG_DIR}/ absent — skipping (lenient)")
        return

    any_fail = False

    # Parse the `## Entry structure` schema SSOT (one parse, Item-8). The
    # caps + narrative-fields drive the matcher; a missing schema is a FAIL.
    rules_path = stream_dir / "_rules.md"
    schema = {}
    if not rules_path.is_file():
        fail(f"{_CHECK_74_CHANGELOG_DIR}/_rules.md — missing (no schema to "
             f"parse)")
        return
    try:
        schema = _check_72_parse_rules_section(
            rules_path.read_text(), "## Entry structure")
    except (UnicodeDecodeError, OSError) as exc:
        fail(f"{_CHECK_74_CHANGELOG_DIR}/_rules.md — unreadable: {exc}")
        return
    if not schema:
        fail(f"{_CHECK_74_CHANGELOG_DIR}/_rules.md — missing or empty "
             f"`## Entry structure` schema block")
        any_fail = True

    # Self-check the matcher has teeth (the empty shipped template cannot
    # exercise the rule otherwise).
    for sc in _check_74_self_check():
        fail(f"Check 74 self-check — {sc}")
        any_fail = True

    # Validate the live (empty) changelog stream's entry files.
    entries = {}
    try:
        names = [p.name for p in stream_dir.iterdir() if p.is_file()]
    except OSError as exc:
        fail(f"{_CHECK_74_CHANGELOG_DIR}/ — cannot scan: {exc}")
        return
    for name in names:
        if not _CHECK_74_ENTRY_RE.match(name):
            continue
        try:
            entries[name] = (stream_dir / name).read_text()
        except (UnicodeDecodeError, OSError) as exc:
            fail(f"{_CHECK_74_CHANGELOG_DIR}/{name} — unreadable: {exc}")
            any_fail = True

    if schema:
        for violation in _check_74_validate(entries, schema):
            fail(f"{_CHECK_74_CHANGELOG_DIR}/{violation}")
            any_fail = True

    if not any_fail:
        n = len(entries)
        shape = ("empty template (no changelog entries)" if n == 0 else
                 f"{n} changelog entry/entries conform (narrative / size caps)")
        ok(f"Check 74 — changelog conformance holds: {shape}; the reconciled "
           f"matcher (narrative-fields / entry-max-lines / summary-max-words) "
           f"self-checks with teeth.")


# ── Check 75: project impl-plan phase/part/task naming conformance (BD-206 O13) ─
#
# The §3.5 GRACEFUL phase/part/task naming-conformance guard — a FORMAT check,
# NOT a structural migration. It codifies the EXISTING inline naming convention
# (the OT gold already conforms, EE-2) as a deterministic template-shape check on
# the Phase-prefixed headings inside each `phase-N.md` entry. The shipped
# `project-template/docs/project/implementation-plan/` stream is EMPTY during
# pack development (no `phase-N.md` entries), so this leg validates the
# MECHANISM / empty-state PLUS a synthetic self-check that the matcher BITES.
#
# The rule (design §3.5, the fixed inline-convention format — NOT a tunable
# schema field, like the changelog H3 anchor regex):
#   - any H3 starting `### Phase-` MUST match `^### Phase-\d+\.Part-[a-z] — `;
#   - any H4 starting `#### Phase-` MUST match
#     `^#### Phase-\d+\.Part-[a-z]\.Task-\d+ — `.
# The guard is GRACEFUL: it FIRES ONLY on a Phase-prefixed heading that violates
# the template. It does NOT require parts to exist, does NOT force a refactor,
# does NOT store an execution-order marker, and tolerates inline parts +
# epic-task `#### N.M — ` anchors (NOT Phase-prefixed) gracefully. The deeper
# per-part-file migration + part-membership/serializability enforcement is
# BD-185 (deferred out of v11.0) — explicitly OUT of scope here.
#
# The CLIENT-side leg (populated-tree validation, "both repos" per Item-7) lives
# in `project-template/scripts/validate-docs.sh` `_conf_check_implplan_entry`;
# both legs apply the SAME two template regexes (one rule, two parsers).
#
# Cheap (ci-check-runtime-compounding): a bounded os.iterdir over ONE stream dir
# (candidate set = that dir's files regex-filtered by the entry regex) + at most
# ~N small reads + per-entry regex line scans; no subprocess, no whole-tree walk;
# the self-check builds its synthetic entries in-memory. SKIP-lenient when the
# stream dir is absent (fresh clone / feature off).

_CHECK_75_IMPLPLAN_DIR = (
    "project-template/docs/project/implementation-plan"
)
_CHECK_75_ENTRY_RE = re.compile(r"^phase-\d+\.md$")
# Phase-prefixed heading detectors (the guard's trigger set).
_CHECK_75_H3_PHASE_RE = re.compile(r"^### Phase-")
_CHECK_75_H4_PHASE_RE = re.compile(r"^#### Phase-")
# The conforming templates the Phase-prefixed headings MUST match.
_CHECK_75_H3_PART_OK_RE = re.compile(r"^### Phase-\d+\.Part-[a-z] — ")
_CHECK_75_H4_TASK_OK_RE = re.compile(r"^#### Phase-\d+\.Part-[a-z]\.Task-\d+ — ")


def _check_75_violations(body: str) -> list:
    """Return the list of Phase-prefixed headings in `body` that VIOLATE the
    §3.5 naming template. GRACEFUL: only Phase-prefixed (`### Phase-` /
    `#### Phase-`) headings are checked; epic-task `#### N.M — ` anchors and
    inline parts that are well-formed are tolerated (no fire)."""
    bad = []
    for line in body.splitlines():
        if _CHECK_75_H3_PHASE_RE.match(line):
            if not _CHECK_75_H3_PART_OK_RE.match(line):
                bad.append(line.rstrip())
        elif _CHECK_75_H4_PHASE_RE.match(line):
            if not _CHECK_75_H4_TASK_OK_RE.match(line):
                bad.append(line.rstrip())
    return bad


def _check_75_validate(entries: dict) -> list:
    """The naming-conformance validator, in-memory. entries: {filename: body}.
    Returns a flat list of `<name>: <message>` failure strings."""
    fails = []
    for name in sorted(entries):
        for heading in _check_75_violations(entries[name]):
            fails.append(
                "%s: phase heading violates the §3.5 naming template: %r"
                % (name, heading))
    return fails


def _check_75_self_check() -> list:
    """In-memory synthetic self-check: confirm the matcher PASSES a conforming
    set (well-formed parts/tasks + tolerated epic-task `#### N.M — ` + a
    parts-free epic) and BITES each violation class (malformed part H3 /
    malformed part-task H4). Returns a list of self-check failure strings
    ([] = the matcher has teeth)."""
    sc_fails = []
    conforming = (
        "<!-- back -->\n"
        "## Phase 3 — Sample epic\n\n"
        "- **Entry-Type**: phase-epic\n\n"
        "### Tasks\n\n"
        "#### 3.1 — An epic task (tolerated; not Phase-prefixed)\n"
        "#### 3.2 — Another epic task\n\n"
        "### Phase-3.Part-a — A well-formed part\n\n"
        "#### Phase-3.Part-a.Task-1 — A well-formed part task\n"
        "#### Phase-3.Part-a.Task-2 — Another part task\n\n"
        "### Phase-3.Part-b — A second part\n")
    parts_free = (
        "<!-- back -->\n"
        "## Phase 4 — Parts-free epic\n\n"
        "- **Entry-Type**: phase-epic\n\n"
        "### Tasks\n\n"
        "#### 4.1 — Only epic tasks here\n")
    part_lightweight = (
        "<!-- back -->\n"
        "## Phase 5 — Epic\n\n"
        "- **Entry-Type**: phase-part\n")  # lightweight part-entry, no headings
    bad_h3 = (
        "<!-- back -->\n"
        "## Phase 6 — Epic\n\n"
        "### Phase-6.Part-A — Capital part letter is malformed\n")
    bad_h3_nodash = (
        "<!-- back -->\n"
        "## Phase 7 — Epic\n\n"
        "### Phase-7.Part-a No em-dash separator\n")
    bad_h4 = (
        "<!-- back -->\n"
        "## Phase 8 — Epic\n\n"
        "### Phase-8.Part-a — OK part\n\n"
        "#### Phase-8.Part-a.Task-x — Non-numeric task index malformed\n")

    def expect(label, entries, want_fail):
        got = bool(_check_75_validate(entries))
        if got != want_fail:
            sc_fails.append(
                "self-check %s: expected %s, got %s"
                % (label, "FAIL" if want_fail else "PASS",
                   "FAIL" if got else "PASS"))

    expect("conforming-clean", {"phase-3.md": conforming}, False)
    expect("parts-free-clean", {"phase-4.md": parts_free}, False)
    expect("lightweight-part-clean", {"phase-5.md": part_lightweight}, False)
    expect("empty-clean", {}, False)
    expect("bad-part-h3", {"phase-6.md": bad_h3}, True)
    expect("bad-part-h3-nodash", {"phase-7.md": bad_h3_nodash}, True)
    expect("bad-part-task-h4", {"phase-8.md": bad_h4}, True)
    return sc_fails


def check_project_implplan_naming() -> None:
    """Check 75 — project impl-plan phase/part/task naming conformance (BD-206 O13).

    Validates the §3.5 GRACEFUL phase/part/task naming convention (a FORMAT
    check, not a structural migration) against the shipped
    `project-template/docs/project/implementation-plan/` stream. The shipped
    template is EMPTY (no `phase-N.md` entries), so this leg validates the
    MECHANISM / empty-state PLUS a synthetic self-check that the matcher bites.
    The client-side populated-tree leg lives in `validate-docs.sh`
    `_conf_check_implplan_entry`; both apply the SAME two template regexes.

    The rule (the fixed inline-convention format):
      - any H3 `### Phase-…` MUST match `### Phase-N.Part-x — `;
      - any H4 `#### Phase-…` MUST match `#### Phase-N.Part-x.Task-k — `.
    GRACEFUL: fires ONLY on a Phase-prefixed heading that violates the template;
    epic-task `#### N.M — ` anchors + inline parts are tolerated; no forced
    refactor; no stored execution-order marker. BD-185 (per-part-file migration
    + serializability enforcement) is OUT of scope.

    SKIPs (lenient) if the impl-plan stream directory is absent.
    Cheap (ci-check-runtime-compounding): one bounded iterdir + small reads +
    deterministic per-line regex scans + an in-memory self-check.
    """
    print("\n── Check 75: project impl-plan phase/part/task naming (BD-206) ──")
    stream_dir = REPO_ROOT / _CHECK_75_IMPLPLAN_DIR
    if not stream_dir.is_dir():
        ok(f"{_CHECK_75_IMPLPLAN_DIR}/ absent — skipping (lenient)")
        return

    any_fail = False

    # Self-check the matcher has teeth (the empty shipped template cannot
    # exercise the rule otherwise).
    for sc in _check_75_self_check():
        fail(f"Check 75 self-check — {sc}")
        any_fail = True

    # Validate the live (empty) impl-plan stream's entry files. The candidate
    # set is a filesystem iterdir bounded to ONE stream dir, regex-filtered to
    # the `phase-N.md` shape (the sanctioned per-stream pattern shared with
    # Checks 73/74) — never a whole-tree walk.
    entries = {}
    try:
        names = [p.name for p in stream_dir.iterdir() if p.is_file()]
    except OSError as exc:
        fail(f"{_CHECK_75_IMPLPLAN_DIR}/ — cannot scan: {exc}")
        return
    for name in names:
        if not _CHECK_75_ENTRY_RE.match(name):
            continue
        try:
            entries[name] = (stream_dir / name).read_text()
        except (UnicodeDecodeError, OSError) as exc:
            fail(f"{_CHECK_75_IMPLPLAN_DIR}/{name} — unreadable: {exc}")
            any_fail = True

    for violation in _check_75_validate(entries):
        fail(f"{_CHECK_75_IMPLPLAN_DIR}/{violation}")
        any_fail = True

    if not any_fail:
        n = len(entries)
        shape = ("empty template (no phase entries)" if n == 0 else
                 f"{n} phase entry/entries conform (graceful naming template)")
        ok(f"Check 75 — impl-plan naming conformance holds: {shape}; the §3.5 "
           f"graceful guard (fires only on a malformed Phase-prefixed heading; "
           f"tolerates inline parts + epic-task anchors) self-checks with teeth.")


# ── Check 84: project groupings contract schema specifics (BD-189) ──────────
#
# The Check-74 analog for the groupings stream, pack-side leg. Check 72
# asserts schema-block PRESENCE + well-formedness for every stream; this
# focused check asserts the shipped groupings `_rules.md` `## Entry schema`
# block's SPECIFICS — the values the twin parsers (the client validate-docs.sh
# `_conf_check_grouping_entry` leg + the client groupings-lib.sh derivations)
# are built against:
#   - entry-type: grouping; core-fields: ID Kind Member-phases;
#   - kind-enum: exactly 10 UNIQUE lowercase-kebab slugs incl. `unassigned`
#     (the FIXED enum — no extension sidecar);
#   - exception-field declared; member-ref-pattern: phase-N; min-members: 2;
#   - field-order declared, carrying Entry-Type + the non-ID core fields +
#     the exception field;
#   - reserved-id: GRP-000, PLUS the schema↔lib CROSS-AGREEMENT line: the
#     shipped groupings-lib.sh `RESERVED_ID` constant carries the SAME ID
#     (the lib hardcodes the reserved refusal; a drifted pair would refuse
#     one ID while validation reserved another). A missing lib file or a
#     missing RESERVED_ID line FAILs (absence-of-backing).
#
# Cheap (ci-check-runtime-compounding): TWO small file reads (the contract +
# the lib), no tree walk, no subprocess; the self-check is in-memory.

_CHECK_84_GROUPINGS_RULES = (
    "project-template/docs/project/groupings/_rules.md"
)
_CHECK_84_GROUPINGS_LIB = "project-template/scripts/groupings-lib.sh"
_CHECK_84_KIND_ENUM_COUNT = 10
_CHECK_84_SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
_CHECK_84_LIB_RESERVED_RE = re.compile(r'(?m)^RESERVED_ID = "([^"]*)"$')


def _check_84_tokens(schema: dict, key: str) -> list:
    """Whitespace-split schema tokens honoring "double-quoted" multi-word
    tokens (the client `_conf_schema_tokens` twin)."""
    return [t.strip().strip('"')
            for t in re.findall(r'"[^"]+"|\S+', schema.get(key, ""))]


def _check_84_validate(schema: dict, lib_text) -> list:
    """The groupings schema-specifics matcher, in-memory.

    schema: the parsed `## Entry schema` {key: tokens} map; lib_text: the
    groupings-lib.sh text, or None when the lib file is missing (the
    cross-agreement line then FAILs on absence-of-backing). Returns a list
    of failure strings ([] = conformant)."""
    fails = []
    et = _check_84_tokens(schema, "entry-type")
    if not et or et[0] != "grouping":
        fails.append("entry-type must be 'grouping' (got %r)"
                     % schema.get("entry-type", ""))
    core = _check_84_tokens(schema, "core-fields")
    if core != ["ID", "Kind", "Member-phases"]:
        fails.append("core-fields must be 'ID Kind Member-phases' (got %r)"
                     % schema.get("core-fields", ""))
    kinds = _check_84_tokens(schema, "kind-enum")
    if len(kinds) != _CHECK_84_KIND_ENUM_COUNT:
        fails.append("kind-enum must carry exactly %d slugs (got %d)"
                     % (_CHECK_84_KIND_ENUM_COUNT, len(kinds)))
    if len(set(kinds)) != len(kinds):
        fails.append("kind-enum carries duplicate slugs")
    for k in kinds:
        if not _CHECK_84_SLUG_RE.match(k):
            fails.append("kind-enum slug %r is not lowercase-kebab" % k)
    if kinds and "unassigned" not in kinds:
        fails.append("kind-enum must include 'unassigned' (the catch-all + "
                     "the reserved GRP-000 pinned Kind)")
    exc = _check_84_tokens(schema, "exception-field")
    if not exc:
        fails.append("exception-field must be declared")
    mrp = _check_84_tokens(schema, "member-ref-pattern")
    if mrp != ["phase-N"]:
        fails.append("member-ref-pattern must be 'phase-N' (got %r)"
                     % schema.get("member-ref-pattern", ""))
    mm = _check_84_tokens(schema, "min-members")
    if mm != ["2"]:
        fails.append("min-members must be '2' (got %r)"
                     % schema.get("min-members", ""))
    order = _check_84_tokens(schema, "field-order")
    if not order:
        fails.append("field-order must be declared")
    else:
        need = ["Entry-Type"] + [f for f in core if f != "ID"] + exc[:1]
        for f in need:
            if f and f not in order:
                fails.append("field-order must carry %r" % f)
    rid = _check_84_tokens(schema, "reserved-id")
    if len(rid) != 1 or rid[0] != "GRP-000":
        fails.append("reserved-id must be 'GRP-000' (got %r)"
                     % schema.get("reserved-id", ""))
    else:
        # CROSS-AGREEMENT: the shipped lib's hardcoded reserved-refusal
        # constant must carry the schema-declared reserved ID.
        if lib_text is None:
            fails.append("groupings-lib.sh missing — the reserved-id "
                         "cross-agreement line has no lib to agree with")
        else:
            lm = _CHECK_84_LIB_RESERVED_RE.search(lib_text)
            if not lm:
                fails.append(
                    'groupings-lib.sh carries no RESERVED_ID = "..." line '
                    "(the schema-declared reserved ID has no lib backing)")
            elif lm.group(1) != rid[0]:
                fails.append(
                    "reserved-id cross-agreement broken: the schema "
                    "declares %r but groupings-lib.sh RESERVED_ID is %r"
                    % (rid[0], lm.group(1)))
    return fails


def _check_84_self_check() -> list:
    """In-memory synthetic self-check: the matcher PASSES a conforming
    schema/lib pair and BITES each violation class. Returns self-check
    failure strings ([] = the matcher has teeth)."""
    sc_fails = []
    good_schema = {
        "entry-type": "grouping",
        "core-fields": "ID Kind Member-phases",
        "kind-enum": ("user-journey ambient-feature foundational-batch "
                      "refactor-cluster release-package shared-feature "
                      "architectural-pattern tech-debt-removal bug-fix "
                      "unassigned"),
        "optional-fields": '"Single-member exception" Doc-links Comment',
        "exception-field": '"Single-member exception"',
        "member-ref-pattern": "phase-N",
        "min-members": "2",
        "field-order": ('Entry-Type Kind Member-phases '
                        '"Single-member exception" Doc-links Comment'),
        "reserved-id": "GRP-000",
    }
    good_lib = 'x\nRESERVED_ID = "GRP-000"\ny\n'

    def expect(label, schema, lib_text, want_fail):
        got = bool(_check_84_validate(schema, lib_text))
        if got != want_fail:
            sc_fails.append("self-check %s: expected %s, got %s"
                            % (label, "FAIL" if want_fail else "PASS",
                               "FAIL" if got else "PASS"))

    def mutated(**kv):
        s = dict(good_schema)
        for k, v in kv.items():
            if v is None:
                s.pop(k, None)
            else:
                s[k] = v
        return s

    expect("conforming", good_schema, good_lib, False)
    # 9-slug enum (unassigned dropped) → FAIL.
    expect("nine-slug-enum", mutated(
        **{"kind-enum": good_schema["kind-enum"].replace(" unassigned", "")}),
        good_lib, True)
    # Missing reserved-id → FAIL.
    expect("missing-reserved-id", mutated(**{"reserved-id": None}),
           good_lib, True)
    # min-members: 3 → FAIL.
    expect("min-members-3", mutated(**{"min-members": "3"}), good_lib, True)
    # Missing field-order → FAIL.
    expect("missing-field-order", mutated(**{"field-order": None}),
           good_lib, True)
    # Duplicate slug (count preserved) → FAIL.
    expect("dup-slug", mutated(
        **{"kind-enum": good_schema["kind-enum"].replace(
            "unassigned", "bug-fix")}), good_lib, True)
    # Non-kebab slug → FAIL.
    expect("non-kebab-slug", mutated(
        **{"kind-enum": good_schema["kind-enum"].replace(
            "unassigned", "Bad_Slug")}), good_lib, True)
    # Wrong member-ref-pattern → FAIL.
    expect("wrong-member-ref", mutated(
        **{"member-ref-pattern": "phase-N.Part-x"}), good_lib, True)
    # Wrong entry-type → FAIL.
    expect("wrong-entry-type", mutated(**{"entry-type": "td"}),
           good_lib, True)
    # Missing exception-field → FAIL.
    expect("missing-exception-field", mutated(**{"exception-field": None}),
           good_lib, True)
    # Lib disagreement (schema GRP-000, lib GRP-111) → FAIL.
    expect("lib-disagreement", good_schema,
           'RESERVED_ID = "GRP-111"\n', True)
    # Lib line ABSENT (absence-of-backing) → FAIL.
    expect("lib-line-absent", good_schema, "no constant here\n", True)
    # Lib file missing entirely → FAIL.
    expect("lib-file-missing", good_schema, None, True)
    return sc_fails


def check_project_groupings_contract() -> None:
    """Check 84 — project groupings contract schema specifics (BD-189).

    Validates the shipped groupings `_rules.md` `## Entry schema` block's
    SPECIFICS (the Check-74 analog: Check 72 asserts presence +
    well-formedness; this check asserts values): entry-type / core-fields /
    kind-enum (exactly 10 unique lowercase-kebab slugs incl. `unassigned`) /
    exception-field / member-ref-pattern phase-N / min-members 2 /
    field-order / reserved-id GRP-000, PLUS the schema↔lib cross-agreement
    line (the shipped groupings-lib.sh RESERVED_ID constant carries the
    schema-declared reserved ID; a missing lib or missing line FAILs —
    absence-of-backing). A synthetic self-check proves the matcher bites.

    SKIPs (lenient) if the groupings stream directory is absent.
    Cheap (ci-check-runtime-compounding): two small file reads + an
    in-memory self-check; no subprocess, no tree walk.
    """
    print("\n── Check 84: project groupings contract schema specifics (BD-189) ──")
    rules_path = REPO_ROOT / _CHECK_84_GROUPINGS_RULES
    stream_dir = rules_path.parent
    if not stream_dir.is_dir():
        ok(f"{_CHECK_84_GROUPINGS_RULES} stream absent — skipping (lenient)")
        return

    any_fail = False
    for sc in _check_84_self_check():
        fail(f"Check 84 self-check — {sc}")
        any_fail = True

    if not rules_path.is_file():
        fail(f"{_CHECK_84_GROUPINGS_RULES} — missing (no schema to assert)")
        return
    try:
        schema = _check_72_parse_rules_section(
            rules_path.read_text(), "## Entry schema")
    except (UnicodeDecodeError, OSError) as exc:
        fail(f"{_CHECK_84_GROUPINGS_RULES} — unreadable: {exc}")
        return
    if not schema:
        fail(f"{_CHECK_84_GROUPINGS_RULES} — missing or empty "
             f"`## Entry schema` block")
        return

    lib_path = REPO_ROOT / _CHECK_84_GROUPINGS_LIB
    lib_text = None
    if lib_path.is_file():
        try:
            lib_text = lib_path.read_text()
        except (UnicodeDecodeError, OSError) as exc:
            fail(f"{_CHECK_84_GROUPINGS_LIB} — unreadable: {exc}")
            any_fail = True

    for violation in _check_84_validate(schema, lib_text):
        fail(f"{_CHECK_84_GROUPINGS_RULES} — {violation}")
        any_fail = True

    if not any_fail:
        ok("Check 84 — groupings contract schema specifics hold: "
           "entry-type / core-fields / kind-enum (10 unique lowercase-kebab "
           "slugs incl. unassigned) / exception-field / member-ref-pattern / "
           "min-members / field-order asserted; reserved-id GRP-000 "
           "cross-agrees with the shipped groupings-lib.sh RESERVED_ID; the "
           "matcher self-checks with teeth.")


# ── __all__ — every Cluster B symbol (the facade re-exports via `import *`) ──
# Three-source union: owned `check_*` + every tested/cross-referenced private
# helper/constant + the intra-cluster symbols, so the facade `from
# validate_checks.discipline_parity import *` re-exports everything the registry
# + the per-check tests reach. Core-imported seams (`REPO_ROOT`, `README`,
# `fail`, `ok`, `warn`, `failures`, `_CHECK_54_REQUIRED_TOKENS`,
# `_CHECK_56_CANONICAL_VERBS`) are NOT listed — they are imported from core and
# re-exported by core's own `__all__`. Listed in module definition order.
__all__ = [
    "_check_50_strip_quoted_spans",
    "_CHECK_50_FORBIDDEN_CODEC_TOKENS",
    "check_validate_pack_no_reproduced_codec",
    "_CHECK_51_CLAMP_FILE",
    "_CHECK_51_RECOMMEND_TOKEN",
    "_CHECK_51_RECOMMEND_SKILL_DIRS",
    "_CHECK_51_ENTRY_TREES",
    "_CHECK_51_ENTRY_PATTERNS",
    "_CHECK_51_INSTALL_MAP_FILE",
    "_CHECK_51_INSTALL_MAP_TOKEN",
    "check_tracker_deferral_flip_block",
    "_CHECK_52_ROSTER_FILE",
    "_CHECK_52_PACK_AGENTS",
    "_CHECK_52_AGENT_DIRS",
    "_CHECK_52_RW_HEADER",
    "_CHECK_52_RO_HEADER",
    "_check_52_roster_classes",
    "_check_52_header_class",
    "check_pack_rw_ro_two_class",
    "_CHECK_53_PROHIBITION_PATTERNS",
    "_CHECK_53_SCAN_SUFFIXES",
    "_CHECK_53_ALLOWLIST_DIR_PREFIXES",
    "_CHECK_53_EXCLUDE_DIR_PREFIXES",
    "_CHECK_53_SELF_TEST_ALLOWLIST",
    "_CHECK_53_SELF_SKIP_NAME",
    "_CHECK_53_SELF_SOURCE",
    "_check_53_is_allowlisted",
    "check_worktree_isolation_prohibition_flip_block",
    "_CHECK_54_OPTIONAL_FEATURES_SURFACES",
    "check_optional_features_presence",
    "_CHECK_56_VERB_PARITY_SURFACES",
    "_CHECK_56_PRINCIPLE_PHRASE",
    "_check_56_phrase_present",
    "_check_56_verb_present",
    "check_destructive_git_verb_parity",
    "_CHECK_55_PM_CHAT_FILE",
    "_CHECK_55_AGENT_RUN_FILE",
    "_CHECK_55_PROJECT_AGENTS",
    "_CHECK_55_RW_AGENTS",
    "_CHECK_55_AGENT_DIRS",
    "_CHECK_55_RW_HEADERS",
    "_CHECK_55_RO_HEADER",
    "_check_55_pm_chat_ro_rows",
    "_check_55_readonly_agents",
    "_check_55_header_class",
    "check_project_rw_ro_two_class",
    "_CHECK_57_TRINITY_SURFACES",
    "_CHECK_57_PROJECT_AGENTS",
    "_CHECK_57_AGENT_DIRS",
    "_CHECK_57_LAUNCHER_SURFACE",
    "_CHECK_57_TRINITY_VERBS",
    "_CHECK_57_DEF_VERBS",
    "_CHECK_57_LAUNCHER_VERBS",
    "_CHECK_57_PRINCIPLE_PHRASE",
    "_check_57_verb_present",
    "check_project_destructive_git_verb_parity",
    "_CHECK_72_PROJECT_TEMPLATE_DIR",
    "_CHECK_72_STREAMS",
    "_CHECK_72_REQUIRED_SIDECARS",
    "_CHECK_72_FORBIDDEN_SIDECARS",
    "_CHECK_72_FORBIDDEN_MONOLITHS",
    "_check_72_parse_rules_section",
    "check_project_template_empty_shape",
    "_CHECK_73_IMPLPLAN_DIR",
    "_CHECK_73_PHASE_RE",
    "_CHECK_73_INDEX_BULLET_RE",
    "_check_73_field_value",
    "_check_73_phase_refs",
    "_check_73_collect",
    "_check_73_toposort",
    "_check_73_parse_index_order",
    "_check_73_validate",
    "_check_73_self_check",
    "check_project_index_consistency",
    "_CHECK_74_CHANGELOG_DIR",
    "_CHECK_74_ENTRY_RE",
    "_CHECK_74_NARRATIVE_RE",
    "_check_74_field_present",
    "_check_74_summary_words",
    "_check_74_caps",
    "_check_74_validate",
    "_check_74_self_check",
    "check_project_changelog_conformance",
    "_CHECK_75_IMPLPLAN_DIR",
    "_CHECK_75_ENTRY_RE",
    "_CHECK_75_H3_PHASE_RE",
    "_CHECK_75_H4_PHASE_RE",
    "_CHECK_75_H3_PART_OK_RE",
    "_CHECK_75_H4_TASK_OK_RE",
    "_check_75_violations",
    "_check_75_validate",
    "_check_75_self_check",
    "check_project_implplan_naming",
    "_CHECK_84_GROUPINGS_RULES",
    "_CHECK_84_GROUPINGS_LIB",
    "_CHECK_84_KIND_ENUM_COUNT",
    "_CHECK_84_SLUG_RE",
    "_CHECK_84_LIB_RESERVED_RE",
    "_check_84_tokens",
    "_check_84_validate",
    "_check_84_self_check",
    "check_project_groupings_contract",
]
