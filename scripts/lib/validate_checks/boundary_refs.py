"""validate_checks.boundary_refs — Cluster A: the boundary / cross-reference /
operating-doc / deny-list check family (BD-256 W2).

This module owns Cluster A's 15 check bodies (Checks 35, 36, 37, 38, 39, 40, 41,
43, 47, 65, 67, 68, 69, 70, 71) plus their intra-cluster helpers and constants —
the pack/project boundary-prevention checks (36/37/38, BD-175), the bare-ref /
cross-reference checks (39/40/41/43, the `_DENY_LIST_*` + `_CHECK_40_*` /
`_CHECK_43_*` families), the operating-doc content gates (65/67/68/69, the
`_CHECK_OPERATING_DOC_*` auto-discovery infrastructure), the client doc-gate /
skill-mirror parity checks (70/71), the sanctioned-shipped freeze (47), and the
phase-task lib invariant (35).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.boundary_refs
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name. Single SSOT — no forked copy.

Spine + seams: the spine symbols (`fail`, `ok`, `failures`) and the cross-module
seams this cluster reads (`REPO_ROOT`, `_PACK_CHAT_ONLY_PERMITTED_PATHS`,
`_PACK_CHAT_ONLY_PERMITTED_PREFIXES`) are imported `from .core` — the single
SSOT for the spine + 8 W1 seams. `_parse_manifest_records` (the manifest-record
parser reused by the Check 65/67/68 allowlist loaders here AND by Check 44/66
(doc_concision) + Check 46 (its owning cluster)) is a cross-MODULE helper: it is
promoted to `core` in this wave (BD-256 W2 — its consumers span ≥2 modules, the
MUST-4 seam-promotion rule) and imported `from .core` so every consumer resolves
the single copy.

Load-time-order contract (MUST-3): `_CHECK_65_OPERATING_DOCS =
tuple(_iter_operating_docs())` executes at module load. `_iter_operating_docs`
+ its helpers (`_operating_doc_families`, `_operating_doc_is_exempt`) + the
`_CHECK_OPERATING_DOC_*` constants they read + `from .core import REPO_ROOT`
are all defined ABOVE that assignment (the source's existing relative order is
preserved by the verbatim move), so the module imports standalone with NO
NameError. See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import os
import re
import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
    warn,
    failures,
    _PACK_CHAT_ONLY_PERMITTED_PATHS,
    _PACK_CHAT_ONLY_PERMITTED_PREFIXES,
    _parse_manifest_records,
)




# ── Check 35: Phase-task lib invariants (BD-106 / V3.3 §3 line 27) ─────────
# (Renumbered from Check 32 in BD-168 to make room for the per-entry
# split validators.)

def check_tracker_phase_task_invariants() -> None:
    """Check 35 (renumbered from Check 32 in BD-168) — phase-task lib
    presence + Path-3-forbidden invariant.

    BD-106 lands `scripts/lib/tracker-phase-task.sh` and the V3.3 §3.5
    label family (`derived-from:`, `promoted-to:`). Path 3 is FORBIDDEN
    per V3.3 §3 line 27 — the tracker-labels.sh lib MUST NOT define a
    `tracker_labels_folded_into` constructor, and no script under
    `scripts/lib/` may carry the literal string `folded-into`.

    The runtime negative-test in `test-tracker-phase-task.sh` Test 5.6
    asserts the same invariant at lib-load time; this CI check is the
    static-analysis backstop catching the case where a future
    maintainer adds `tracker_labels_folded_into` to `tracker-labels.sh`
    without re-running the test runner.

    Three asserts:
      1. `scripts/lib/tracker-phase-task.sh` exists.
      2. `tracker_labels_folded_into` is NOT defined in
         `scripts/lib/tracker-labels.sh`.
      3. The literal `folded-into` does NOT appear anywhere in
         `scripts/lib/` (per V3.3 §3 line 27 invariant).
    """
    print("\n── Check 35: Phase-task lib invariants (BD-106) ──")
    lib_dir = REPO_ROOT / "scripts" / "lib"
    phase_task_lib = lib_dir / "tracker-phase-task.sh"
    labels_lib = lib_dir / "tracker-labels.sh"

    if not phase_task_lib.is_file():
        fail(
            f"{phase_task_lib.relative_to(REPO_ROOT)} — file missing "
            f"(BD-106 / V3.3 §2 D-21)"
        )
    else:
        ok(f"{phase_task_lib.relative_to(REPO_ROOT)} present")

    if labels_lib.is_file():
        # Detect a function DEFINITION (not a comment reference). A bash
        # function def matches `<name>()` or `function <name>` at the
        # start of a non-comment line. Comments may legitimately mention
        # the forbidden helper name when documenting the prohibition.
        defines_folded_into = False
        labels_def_lineno = 0
        for lineno, line in enumerate(labels_lib.read_text().splitlines(), start=1):
            stripped = line.lstrip()
            if stripped.startswith("#"):
                continue
            if (
                stripped.startswith("tracker_labels_folded_into(")
                or stripped.startswith("function tracker_labels_folded_into")
            ):
                defines_folded_into = True
                labels_def_lineno = lineno
                break
        if defines_folded_into:
            fail(
                f"{labels_lib.relative_to(REPO_ROOT)}:{labels_def_lineno} "
                f"— defines tracker_labels_folded_into; Path 3 is "
                f"FORBIDDEN per V3.3 §3 line 27"
            )
        else:
            ok(
                f"{labels_lib.relative_to(REPO_ROOT)} — no "
                f"tracker_labels_folded_into helper definition "
                f"(Path 3 forbidden)"
            )
    else:
        fail(f"{labels_lib.relative_to(REPO_ROOT)} — file missing")

    # Invariant 3: no `folded-into` literal in EXECUTABLE code under
    # scripts/lib/. Comments (lines whose first non-whitespace char is
    # `#`) are exempt because the libs explicitly DOCUMENT the
    # forbidden state in their docstrings (e.g. tracker-labels.sh
    # "Path 3 is forbidden by V3.3 §3 line 27 — Helpers below
    # intentionally have no `folded-into` constructor."). The grep is
    # performed in Python to avoid shelling out and to report all
    # offending files in one pass.
    #
    # BD-256 W2 EXEMPTION (measure-then-bound, self-scan only): this check's
    # OWN relocated source — `scripts/lib/validate_checks/boundary_refs.py` —
    # is excluded, and ONLY that file. Check 35's body
    # (`check_tracker_phase_task_invariants`, relocated here by BD-256 W2)
    # legitimately carries the literal `folded-into` — it is the check that
    # DETECTS it. Before BD-256 the check lived at `scripts/validate-pack.py`
    # (OUTSIDE `scripts/lib/`), so its own detection literals were never in
    # this scan; the BD-256 modularization relocated it under `scripts/lib/`,
    # so without this exemption the check would flag its own source. The
    # exemption is sized to exactly the measured self-scan set
    # (`{boundary_refs.py}`) — every OTHER file, INCLUDING the rest of the
    # `validate_checks/` package, stays in scope, so a stray `folded-into`
    # anywhere else is still caught.
    self_source = lib_dir / "validate_checks" / "boundary_refs.py"
    offenders = []
    if lib_dir.is_dir():
        for path in sorted(lib_dir.rglob("*")):
            if not path.is_file():
                continue
            if path == self_source:
                continue
            try:
                lines = path.read_text().splitlines()
            except (OSError, UnicodeDecodeError):
                continue
            for lineno, line in enumerate(lines, start=1):
                stripped = line.lstrip()
                if stripped.startswith("#"):
                    continue
                if "folded-into" in line:
                    offenders.append(
                        (path.relative_to(REPO_ROOT), lineno, line.strip())
                    )
    if offenders:
        for off, lineno, snippet in offenders:
            fail(
                f"{off}:{lineno} — contains literal `folded-into` in "
                f"executable code; V3.3 §3 line 27 forbids Path 3 "
                f"anywhere under scripts/lib/. Line: {snippet!r}"
            )
    else:
        ok(
            "scripts/lib/ — no `folded-into` literal in executable "
            "code (V3.3 §3 line 27); comment-only references allowed"
        )




# ── Check 36 / 37 / 38: BD-175 pack/project boundary prevention ────────────
#
# These three checks implement Architect C's M5a/M5b/M5c CI enforcement
# layer.
#   - Check 36 (M5a): commit-scope honesty — catches TYPE-1/TYPE-3.
#   - Check 37 (M5b): project-side deny-list — catches TYPE-4.
#   - Check 38 (M5c): pack-only-file siting — catches mis-located content.
#
# The behavior contracts and rationales are documented in the architect
# doc; the comments below explain the concrete code shape only.


# Allowed scope-keyword vocabulary per pack-root trinity §
# "Commit-subject scope-keyword convention" (added by BD-175 Commit 12).
_SCOPE_KEYWORDS_PACK_ONLY = ("pack-only",)


_SCOPE_KEYWORDS_PROJECT_ONLY = ("project-only",)


_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)




# `_PROJECT_SIDE_ROOTS` is REPLACED by `_iter_client_installed_files()`.
# See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3 for the contract.
# Reason: the previous constant restricted Check 37 to project-template/
# only, missing scripts/lib/detect.sh (installed verbatim per
# init-project.sh:894-895) and the other 4 client-installed files in
# pack-ops/ + supporting-docs/ + scripts/. The new helper parses the
# authoritative _CLIENT_INSTALLED_FILES inventory and walks the full
# client-installed surface.

# Pack-only path prefixes for scope honesty (Check 36 pack-only check):
# a `pack-only` commit MUST NOT touch any path under these prefixes.
_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")



# Scope-neutral generated artifact(s): auto-generated files that the
# `regenerate-manifest-v11-surface` rule FORCES to co-vary with a v11-surface
# edit on EITHER surface. They carry no surface-specific semantic content, so
# they are permitted in BOTH `project-only` and `pack-only` commits without
# counting as an offender. Sized EXACTLY to the measured forced-co-variant set
# (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17.3): manifest only.
# A hand-edited manifest is independently caught by `build.sh --verify`, so
# admitting it here does NOT let content smuggle past the boundary.
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})




def _read_boundary_exempt_root() -> set[str]:
    """Parse `pack-ops/.boundary-exempt-root.txt` (1-entry list per
    AUDIT-USER-CURATION.md Overrides 1 + 5 — only `tracker.toml.pack-example`
    post-B-fix). Returns the set of bare filenames permitted at pack root."""
    path = REPO_ROOT / "pack-ops" / ".boundary-exempt-root.txt"
    entries: set[str] = set()
    if not path.is_file():
        return entries
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        entries.add(stripped)
    return entries




def _commits_to_walk() -> list[tuple[str, str]]:
    """Return (sha, subject) pairs for commits to walk under Check 36.

    Range design (per Architect C §8.1 "implementation strategy" + the
    fact that v11-dev has historical commits with imperfect scoping that
    predate BD-175 Commit 12's convention codification):

    - Default: walk ONLY HEAD (the most-recent commit). This is the
      per-push CI gate pattern: enforce the convention on commits added
      in this push; historical commits stay un-audited. The trade-off
      is conservative — Check 36 catches new mis-scoping going forward,
      not historical violations. Historical violations are caught by
      the audit/review process, not the CI gate.

    - Environment override `PACK_CHECK_36_RANGE` may set a wider git
      log range (e.g., `origin/main..HEAD`) for one-shot audit runs.

    Returns (sha, subject) tuples in chronological order (oldest first);
    empty list means nothing to walk (e.g., merge commit with no diff).
    """
    range_spec = os.environ.get("PACK_CHECK_36_RANGE", "HEAD~0..HEAD")
    # `HEAD~0..HEAD` is a no-op range that returns nothing; use `-1`
    # form as the default.
    if range_spec == "HEAD~0..HEAD":
        cmd = ["git", "log", "-1", "--format=%H%x09%s", "HEAD"]
    else:
        cmd = ["git", "log", "--reverse", "--format=%H%x09%s", range_spec]
    try:
        res = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            cwd=str(REPO_ROOT),
        )
    except subprocess.CalledProcessError:
        return []
    out = res.stdout.strip()
    if not out:
        return []
    commits: list[tuple[str, str]] = []
    for line in out.splitlines():
        if "\t" not in line:
            continue
        sha, subject = line.split("\t", 1)
        commits.append((sha, subject))
    return commits




def _commit_paths(sha: str) -> list[str]:
    """Return the list of paths touched by the given commit (relative to
    repo root). Returns empty list on failure."""
    try:
        res = subprocess.run(
            ["git", "show", "--name-only", "--format=", sha],
            check=True,
            capture_output=True,
            text=True,
            cwd=str(REPO_ROOT),
        )
    except subprocess.CalledProcessError:
        return []
    return [line for line in res.stdout.splitlines() if line]




def _subject_has_keyword(subject: str, keywords: tuple[str, ...]) -> bool:
    """Case-insensitive boundary-anchored match of any keyword in the
    commit subject. The keyword must be preceded by start-of-string OR
    a non-keyword-character (whitespace, colon, em-dash, punctuation),
    and followed by a non-keyword-character (whitespace, colon, em-dash,
    punctuation, end-of-string).

    The keyword characters include `[a-z0-9-]`, so a keyword like
    `pack-only` does NOT match inside `pack-only-ish` (the trailing `-`
    is a keyword character, blocking the trailing boundary). This
    avoids spurious matches on prose words that happen to contain the
    keyword as a prefix or suffix.
    """
    subject_lower = subject.lower()
    # Boundary class: chars that are NOT part of a scope-keyword token
    # (whitespace, colon, em-dash, comma, period, semicolon, paren).
    # `-` is NOT in the boundary class because `-` appears INSIDE the
    # keywords (pack-only, project-only, etc.).
    boundary_class = r"[\s:—,.;()\[\]]"
    for kw in keywords:
        if kw not in subject_lower:
            continue
        pattern = (
            r"(^|" + boundary_class + r")"
            + re.escape(kw)
            + r"($|" + boundary_class + r")"
        )
        if re.search(pattern, subject_lower):
            return True
    return False




def _is_pack_only_path(path: str) -> bool:
    """A path is pack-only if it is NOT under any project-side prefix."""
    for prefix in _PROJECT_SIDE_PATH_PREFIXES:
        if path.startswith(prefix):
            return False
    return True




def _is_project_side_path(path: str) -> bool:
    """A path is project-side if it lives under one of the project-side
    path prefixes."""
    return path.startswith(_PROJECT_SIDE_PATH_PREFIXES)




def _is_scope_neutral_generated(path: str) -> bool:
    """True if `path` is an auto-generated, scope-neutral artifact that the
    regenerate-manifest rule forces to co-vary with v11-surface edits on
    EITHER surface (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17).
    Such paths are not offenders in either `project-only` or `pack-only`
    commits. Exact-string set-membership — NOT a `test-fixtures/` prefix, so
    the static `v11-trinity-marker-prepped/` snapshot + the `build.sh`/README
    recipe (real pack-side content) still count toward scope."""
    return path in _SCOPE_NEUTRAL_GENERATED_PATHS




def _is_pack_chat_only_permitted(path: str) -> bool:
    """A path is pack-chat-only-permitted if it appears in the canonical Files
    list OR under one of the canonical pack-chat-only directory prefixes."""
    if path in _PACK_CHAT_ONLY_PERMITTED_PATHS:
        return True
    return path.startswith(_PACK_CHAT_ONLY_PERMITTED_PREFIXES)




def check_commit_scope_honesty() -> None:
    """Check 36 — commit-scope honesty (BD-175 M5a per Architect C §8.1).

    For every commit in the walk range, parse the commit subject for scope
    keywords (`pack-only`, `project-only`, `pack-chat-only`)
    and verify the commit's touched paths match the claimed scope.

    Failure modes:
      - Subject claims `pack-only` but commit touches `project-template/`
        or `supporting-docs/`.
      - Subject claims `project-only` but commit touches paths outside
        `project-template/` + `supporting-docs/`.
      - Subject claims `pack-chat-only` but commit touches
        any path NOT in the pack-chat-only permitted-paths list (per
        `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" + the
        per-entry directory block).

    Implicit-scope commits (no keyword) are skipped — keyword opt-in per
    M1b convention.
    """
    print("\n── Check 36: Commit-scope honesty (BD-175, M5a) ──")
    commits = _commits_to_walk()
    if not commits:
        ok("Check 36 — no commits in walk range; nothing to verify")
        return

    any_failed = False
    checked = 0
    skipped = 0
    for sha, subject in commits:
        is_pack_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PACK_ONLY)
        is_project_only = _subject_has_keyword(
            subject, _SCOPE_KEYWORDS_PROJECT_ONLY
        )
        is_pack_chat_only = _subject_has_keyword(
            subject, _SCOPE_KEYWORDS_PACK_CHAT_ONLY
        )
        if not (is_pack_only or is_project_only or is_pack_chat_only):
            skipped += 1
            continue
        paths = _commit_paths(sha)
        if not paths:
            # Merge commit or empty diff — skip.
            skipped += 1
            continue
        checked += 1
        short_sha = sha[:7]
        offenders: list[str] = []
        if is_pack_only:
            offenders = [
                p for p in paths
                if _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `pack-only` "
                    f"but touches project-side paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_project_only:
            offenders = [
                p for p in paths
                if not _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `project-only` "
                    f"but touches pack-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_pack_chat_only:
            offenders = [p for p in paths if not _is_pack_chat_only_permitted(p)]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `pack-chat-only` but "
                    f"touches non-pack-chat-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                    + " (pack-chat-only permitted set per pack-ops/PACK-AGENTS.md "
                    "§ 'pack-chat-only files and directories')"
                )
                any_failed = True

    if not any_failed:
        ok(
            f"Check 36 — {checked} scope-claiming commit(s) verified clean; "
            f"{skipped} implicit-scope commit(s) skipped"
        )




# Check 37 deny-list — pack-only patterns that MUST NOT appear in
# project-side files (per Architect C §8.2 deny-list, with §16.1
# `pack-ops/` path-prefix addition). Each entry: (literal-pattern, why)
# — the literal pattern is a substring grep target. The exception is by
# anchor-phrase in the surrounding context window (see
# _DENY_LIST_ANCHOR_PHRASES).
_DENY_LIST_FILENAMES = (
    ("PACK-AGENTS.md", "Pack-repo only"),
    ("PACK-CHAT.md", "Pack-repo only"),
    ("HELP-FRAGMENT-PACK.md", "Pack-repo only"),
)



# Path prefixes that name pack-only directories. Each match flags as
# contamination unless an anchor-phrase exception is found in the
# context window.
_DENY_LIST_PATH_PREFIXES = (
    ("maintenance-docs/", "Pack-only; not installed"),
    ("pack-ops/", "Pack-only top-level dir (relocated PACK × OPERATIONS files)"),
)



# Pack-* agent names (word-boundary-anchored).
_DENY_LIST_AGENT_NAMES = (
    "pack-architect",
    "pack-coder",
    "pack-planner",
    "pack-reviewer",
    "pack-docs-researcher",
)



# Capitalized `Pack Chat` orchestrator role. Audit §D-4 LEGITIMATE exception
# is by anchor-phrase context window.
_DENY_LIST_ROLE_NAME = "Pack Chat"



# Anchor phrases that, when found within the per-pattern context window
# (matched line + N lines before + N lines after), mark the match as
# LEGITIMATE per audit §D-4 (feedback-flow / escalation-path context, or
# pack-vs-project disambiguation context — the latter per BD-175 Commit
# 12 anchor-phrase extension to handle pack-repo disambiguation patterns
# like "in the pack repo" on a pack-only filename callout).
_DENY_LIST_ANCHOR_PHRASES = (
    "feedback",
    "report back",
    "escalation",
    "stop and surface",
    # Pack-vs-project disambiguation context. These mark a deliberate
    # callout that a named entity lives at the pack repo (not at the
    # client install) — e.g., "tracker.toml.pack-example in the pack
    # repo, or tracker.toml.example at a client project root".
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "pack repo only",
)



_DENY_LIST_ANCHOR_WINDOW = 2  # lines before/after the match




def _context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any of the anchor phrases appears in the
    `lineno` line (1-indexed) or in the ±N surrounding lines."""
    start = max(0, lineno - 1 - _DENY_LIST_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _DENY_LIST_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _DENY_LIST_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False




# Pack-side-LOCATED, client-SHIPPED files. FROZEN EMPTY. No pack-side file
# currently ships to clients: the no-dual-use rule (dependency-direction-
# placement conjunct (c)) requires every client deliverable to be its OWN
# project-template/ copy, never a pack-side file reused as the client's copy.
# The set is SHRINK-ONLY and MAY NEVER GROW — there is NO admission path and
# NO sign-off exception. Check 47 CODE-ENFORCES this empty invariant (a non-
# empty value is a hard CI failure) in addition to the install-map
# set-equality freeze.
_SANCTIONED_PACK_SIDE_SHIPPED: tuple[str, ...] = ()


def _iter_client_installed_files() -> list[Path]:
    """Return the union of:
      (a) all regular files under project-template/ (recursive), and
      (b) the explicit non-project-template files in _CLIENT_INSTALLED_FILES,
          split into two admitted classes: `supporting-docs/` entries are
          client-installed sources and pass through WITHOUT a membership
          check; every OTHER non-template entry (pack-side-located) is
          admitted ONLY if it is in _SANCTIONED_PACK_SIDE_SHIPPED (the
          membership gate — currently EMPTY per BD-257's no-dual-use rule,
          so NO pack-side entry is admitted; NOT a content skip — any
          admitted file stays fully walked + cleanliness-enforced by Check
          43; an UNsanctioned pack-side entry is a hard error via Check 47).
          See ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.1/§8.2.

    This replaces _PROJECT_SIDE_ROOTS-based walks for Checks 37 + 43.
    The source-of-truth for (b) is _CLIENT_INSTALLED_FILES_START/_END
    in scripts/init-project.sh, parsed via Check 41's
    _parse_client_installed_files() helper.

    Returns repo-relative Path objects, sorted, deduplicated. Skips
    binary files (deferred to caller via UnicodeDecodeError handling).

    Contract: see `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
    §3.1 for the verbatim function body + §3.2 for the rationale
    (replaces `_PROJECT_SIDE_ROOTS` constant; reuses the authoritative
    `_CLIENT_INSTALLED_FILES_START`/`_END` inventory in
    `scripts/init-project.sh` per BD-180 G).
    """
    out: list[Path] = []
    # (a) project-template/ recursive walk (existing behavior).
    root = REPO_ROOT / "project-template"
    if root.is_dir():
        # ci-guard-measure-then-bound: content-bound + extension-filtered downstream
        # (Check 37/41/43 decode-skip + _CHECK_40_FILE_EXTS) → untracked junk is
        # junk-immune here; raw walk OK (not a verdict-bearing presence set).
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            out.append(path.relative_to(REPO_ROOT))
    # (b) explicit non-project-template entries from _CLIENT_INSTALLED_FILES.
    #     `supporting-docs/` entries are client-installed sources (walked as
    #     before). PACK-SIDE-LOCATED entries (neither project-template/ nor
    #     supporting-docs/) are MEMBERSHIP-GATED to _SANCTIONED_PACK_SIDE_SHIPPED:
    #     the gate authorizes WHICH pack-side files may be walked as client
    #     surfaces — it is NOT a content skip. The set is EMPTY per BD-257's
    #     no-dual-use rule, so no pack-side map entry is admitted here today;
    #     were one ever admitted it would stay fully walked and Check 43 would
    #     enforce cleanliness on it. An UNsanctioned pack-side map entry is
    #     silently NOT admitted here and is turned into a HARD CI error by
    #     Check 47 (empty-invariant + set-equality freeze).
    entries, _, _, _, _ = _parse_client_installed_files()
    for entry in entries:
        if entry.startswith("project-template/"):
            continue  # already covered by (a)
        if not entry.startswith("supporting-docs/") and (
            entry not in _SANCTIONED_PACK_SIDE_SHIPPED
        ):
            continue  # membership gate — Check 47 fails on unsanctioned entries
        full = REPO_ROOT / entry
        if full.is_file():
            rel = full.relative_to(REPO_ROOT)
            if rel not in out:  # dedup defensive (project-template/ first)
                out.append(rel)
    return out




# Companion-template directories — dev-environment configs a developer
# applies to their editor/IDE (NOT installed by init-project.sh, so NOT
# part of `_CLIENT_INSTALLED_FILES`). They are pack-shipped client-facing
# surfaces, so Check 37's pack-only deny-list applies to them as
# forward-protection (BD-196 C7, plan §3 D1). These are appended to
# Check 37's walk via `_iter_project_side_files()` ONLY — they are
# deliberately NOT added to `_iter_client_installed_files()`, which feeds
# Check 41's install inventory and Check 43's bare-cross-reference walk.
_CHECK_37_COMPANION_TEMPLATE_DIRS = (
    "xcode-companion-templates",
    "vscode-companion-templates",
)




def _iter_project_side_files() -> list[Path]:
    """Check 37's walk set: `_iter_client_installed_files()` PLUS the
    companion-template directories.

    Check 37 protects every pack-shipped client-facing surface from
    pack-only-reference contamination. That surface is the union of:
      (a) the client-installed inventory (`_iter_client_installed_files()`
          — project-template/ recursive + the explicit
          `_CLIENT_INSTALLED_FILES` extras), and
      (b) the companion-template directories
          (`_CHECK_37_COMPANION_TEMPLATE_DIRS`), which are dev-environment
          editor/IDE configs a developer applies manually — pack-shipped
          and client-facing, but NOT auto-installed by init-project.sh.

    The companion dirs are appended HERE (Check 37's walk) and NOT in
    `_iter_client_installed_files()` so that Check 41 (install inventory)
    and Check 43 (bare-cross-reference scanner) are unaffected — they
    walk only the auto-installed set. See ARCHITECTURE-V11-GUARDRAILS-
    CONTRACT.md §3.2 for the original alias rationale; BD-196 C7 plan §3
    D1 for the companion-template extension.
    """
    out = list(_iter_client_installed_files())
    seen = {str(p) for p in out}
    for dirname in _CHECK_37_COMPANION_TEMPLATE_DIRS:
        root = REPO_ROOT / dirname
        if not root.is_dir():
            continue
        # ci-guard-measure-then-bound: content-bound (Check 37 decode-skip) →
        # junk-immune; raw walk OK (not a verdict-bearing presence set).
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            rel = path.relative_to(REPO_ROOT)
            if str(rel) not in seen:
                out.append(rel)
                seen.add(str(rel))
    return out




# Per-line fence allowlist for Check 37 (Guardrail 2 — BD-173 H.13).
# Replaces the legacy `_is_legitimate_deny_list_doc()` whole-file
# exemption. Files on this list MAY contain deny-list patterns INSIDE
# paired `<!-- DENY-LIST-CONTENT-START -->` / `<!-- DENY-LIST-CONTENT-END -->`
# fence markers; outside the fence, normal Check 37 rules apply.
#
# Constant shape: tuple of repo-relative path strings (POSIX form).
# Membership test is exact-string match via `_has_per_line_fence`.
#
# Contract: see `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
# §2.3 (constant) and §2.4 (fence-placement plan per file). The 2 remaining
# dual-surface entries (METHODOLOGY.md, INSTALL-PROCEDURES.md) were added
# 2026-05-24 per the H.12/H.13 reorder. The scripts/ pair
# (detect.sh, pack-help.sh) was DROPPED per BD-257: both are de-shipped
# (empty pack→client ship-allowlist), so Check 37 no longer walks them as
# client surfaces — their fence membership was consulted zero times and is
# removed (`fail-loud-delete-old-source`).
_CHECK_37_PER_LINE_FENCE_FILES = (
    # Original 7 entries (project-template/ trinity + prompts + skill + PM-CHAT.md):
    "project-template/skills/boundary-investigation/SKILL.md",
    "project-template/docs/pack/PM-CHAT.md",
    "project-template/docs/pack/prompts/coder.md",
    "project-template/docs/pack/prompts/reviewer.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    # 2 dual-surface additions (added 2026-05-24 per H.12/H.13 reorder).
    # These files carry LEGITIMATE pack-internal references in pedagogical
    # role-name content (supporting-docs/) that the fence covers without
    # breaking the doc's explanatory purpose. (The former scripts/ pair
    # detect.sh + pack-help.sh was removed per BD-257 — both de-shipped, no
    # longer walked by Check 37 as client surfaces.)
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    # PACK-FEEDBACK.md (added 2026-05-24 during H.13 implementation —
    # architect-spec gap discovery). Architect §2.3 originally classified this file as
    # anchor-phrase-legitimate (and thus NOT on the per-line fence list),
    # but empirically the file's `Pack Chat` references throughout the
    # template body lack the ±2-line "feedback" anchor in every context
    # window — the file's whole-file domain-vocabulary nature was
    # previously covered by the (now-removed) `_is_legitimate_deny_list_doc()`
    # whole-file exemption. Placing this file on the per-line fence list
    # with a whole-file fence preserves the architectural intent
    # (pack-vs-client feedback flow is the doc's reason for existing —
    # `Pack Chat` is unavoidable vocabulary).
    "project-template/docs/pack/PACK-FEEDBACK.md",
)




def _has_per_line_fence(rel_path: Path) -> bool:
    """Return True if rel_path is on the per-line-fence allowlist
    (i.e., the file MAY contain deny-list patterns INSIDE the fence
    markers; outside the fence, normal Check 37 rules apply).

    Replaces the legacy `_is_legitimate_deny_list_doc()` whole-file
    exemption (per `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
    §2.3).
    """
    return str(rel_path) in _CHECK_37_PER_LINE_FENCE_FILES




# Fence-marker line strings. The parser matches each MARKER as a
# suffix of the line's stripped right-hand side, allowing an optional
# shell-comment prefix (`# `) — so the same marker works in both
# markdown files and shell scripts:
#
#   Markdown:  `<!-- DENY-LIST-CONTENT-START -->`
#   Shell:     `# <!-- DENY-LIST-CONTENT-START -->`
#
# Per architect §2.5 invariant "each marker MUST be on its own line",
# the parser admits leading whitespace + an optional shell-comment
# prefix and rejects any other text on the line.
_FENCE_MARKER_START = "<!-- DENY-LIST-CONTENT-START -->"


_FENCE_MARKER_END = "<!-- DENY-LIST-CONTENT-END -->"




def _line_is_fence_marker(line: str, marker: str) -> bool:
    """Return True if line is exactly the fence marker (modulo leading
    whitespace + an optional `# ` shell-comment prefix).

    Per architect §2.3 shell-script fence-marker note: the shell `#`
    comment form preceding the marker is admitted so the line is a
    valid shell comment AND a valid fence marker for the parser.
    """
    stripped = line.strip()
    if stripped == marker:
        return True
    # Admit shell-comment prefix (`# <marker>` or `#<marker>`).
    if stripped.startswith("#"):
        rest = stripped[1:].lstrip()
        if rest == marker:
            return True
    return False




def _build_fence_skip_lineset(text: str) -> set[int] | None:
    """Parse the text for paired DENY-LIST-CONTENT-START / -END
    markers and return the set of 1-indexed line numbers INSIDE any
    fence (i.e., lines between paired markers, exclusive of the marker
    lines themselves).

    Multiple non-overlapping fences supported; nested fences NOT
    supported (return None on imbalance — caller emits a Check 37
    fail with the "fence-marker imbalance" diagnostic).

    Per architect §2.5 invariants:
      - Pairs MUST be balanced (every START followed by a matching END
        before the next START).
      - Fence range is EXCLUSIVE of the marker lines themselves.
      - Empty fence (START immediately followed by END) is permitted.
    """
    skip: set[int] = set()
    in_fence = False
    fence_start_line = 0
    for lineno, line in enumerate(text.splitlines(), start=1):
        if _line_is_fence_marker(line, _FENCE_MARKER_START):
            if in_fence:
                # Nested START — imbalance.
                return None
            in_fence = True
            fence_start_line = lineno
        elif _line_is_fence_marker(line, _FENCE_MARKER_END):
            if not in_fence:
                # END without matching START — imbalance.
                return None
            in_fence = False
            # Mark the interior lines (exclusive of markers).
            for inner in range(fence_start_line + 1, lineno):
                skip.add(inner)
            fence_start_line = 0
    if in_fence:
        # Unterminated START — imbalance.
        return None
    return skip




def check_project_side_deny_list() -> None:
    """Check 37 — project-side pack-only-reference deny list
    (BD-175 M5b per Architect C §8.2).

    Walks the Check 37 surface (`_iter_project_side_files()` — the
    client-installed inventory PLUS the companion-template directories
    `xcode-companion-templates/` + `vscode-companion-templates/` per
    BD-196 C7) and greps for literal references to pack-only files /
    path prefixes / agent names / the capitalized `Pack Chat`
    orchestrator role. Each hit is a FAIL with file:line + matched
    pattern unless the context window contains a LEGITIMATE-context
    anchor phrase.

    Specific exemptions:
      - The `boundary-investigation` skill (Pattern A canonical single
        source at `project-template/skills/boundary-investigation/SKILL.md`,
        auto-distributed to all three CLI install paths via
        `stage_s4_skills()` at client install time) — its purpose is to
        teach the deny-list, so the entries appear as instructional
        content.
      - The project-side `coder.md` + `reviewer.md` prompt templates —
        same rationale.
      - The project trinity files — the "Project SSOT-first" bullet
        names the deny-list as instructional content.

    Anchor-phrase exception (per audit §D-4 LEGITIMATE designation):
      - `feedback`, `report back`, `escalation`, `stop and surface`
        (feedback-flow context per `PACK-FEEDBACK.md` / `PM-CHAT.md` /
        `METHODOLOGY.md` / `SETUP-EXISTING.md` LEGITIMATE designation)
      - `in the pack repo`, `at the pack repo`, `pack-repo`,
        `pack repo only` (pack-vs-project disambiguation context per
        BD-175 Commit 12 anchor-phrase extension — covers a pack-only
        filename callout that names a pack-repo location to disambiguate
        it from a client-side equivalent, e.g. a `tracker.toml.pack-example`
        callout marked "in the pack repo")
    """
    print("\n── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──")
    any_failed = False
    files_walked = 0
    hits_clean = 0
    hits_fenced = 0

    for rel_path in _iter_project_side_files():
        full_path = REPO_ROOT / rel_path
        try:
            text = full_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        lines = text.splitlines()

        # Guardrail 2 (BD-173 H.13): per-line fence skip-set for
        # fence-allowlisted files. Files NOT on the allowlist get an
        # empty skip-set (no fence support outside the allowlist).
        if _has_per_line_fence(rel_path):
            fence_skip = _build_fence_skip_lineset(text)
            if fence_skip is None:
                fail(
                    f"{rel_path} — fence-marker imbalance "
                    f"(unmatched `<!-- DENY-LIST-CONTENT-START -->` / "
                    f"`<!-- DENY-LIST-CONTENT-END -->` markers; nesting "
                    f"NOT supported per ARCHITECTURE-V11-GUARDRAILS-"
                    f"CONTRACT.md §2.5). Remediation: balance markers "
                    f"so every START has a matching END before the next "
                    f"START."
                )
                any_failed = True
                fence_skip = set()
        else:
            fence_skip = set()

        for lineno, line in enumerate(lines, start=1):
            if lineno in fence_skip:
                hits_fenced += 1
                continue
            # Filename matches (bare).
            for fname, why in _DENY_LIST_FILENAMES:
                if fname in line:
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"file `{fname}` ({why}); no LEGITIMATE-context "
                        f"anchor phrase in ±{_DENY_LIST_ANCHOR_WINDOW} line "
                        f"window. Remediation: replace with project-side "
                        f"SSOT (e.g., docs/pack/PM-CHAT.md for agent "
                        f"roster) or remove the reference."
                    )
                    any_failed = True
            # Path-prefix matches.
            for prefix, why in _DENY_LIST_PATH_PREFIXES:
                if prefix in line:
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"path prefix `{prefix}` ({why}); no LEGITIMATE-"
                        f"context anchor phrase in ±{_DENY_LIST_ANCHOR_WINDOW} "
                        f"line window. Remediation: drop the cross-reference "
                        f"or replace with a project-side SSOT path."
                    )
                    any_failed = True
            # Agent-name word-boundary matches.
            for agent in _DENY_LIST_AGENT_NAMES:
                pattern = r"\b" + re.escape(agent) + r"\b"
                if re.search(pattern, line):
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"agent name `{agent}` (pack-* agents are pack-"
                        f"repo only); no LEGITIMATE-context anchor in "
                        f"window. Remediation: use the project-side agent "
                        f"roster at docs/pack/PM-CHAT.md (unprefixed names: "
                        f"`architect`, `coder`, `planner`, `reviewer`, etc.)."
                    )
                    any_failed = True
            # Capitalized Pack Chat orchestrator-role match.
            if _DENY_LIST_ROLE_NAME in line:
                if _context_has_anchor(lines, lineno):
                    hits_clean += 1
                    continue
                fail(
                    f"{rel_path}:{lineno} — references `{_DENY_LIST_ROLE_NAME}` "
                    f"capitalized orchestrator role (pack-repo only — "
                    f"project-side equivalent is the project's PM chat); "
                    f"no LEGITIMATE-context anchor in window. Remediation: "
                    f"use `PM chat` (project-side orchestrator) or drop "
                    f"the reference."
                )
                any_failed = True

    if not any_failed:
        ok(
            f"Check 37 — {files_walked} project-side file(s) walked; "
            f"zero deny-list contamination "
            f"({hits_clean} anchored LEGITIMATE-context hit(s) accepted; "
            f"{hits_fenced} fenced LEGITIMATE-content line(s) exempt "
            f"per Guardrail 2)"
        )




# Check 38 — pack-only-file siting. For each file at pack-root (top-
# level), count pack-only signals (deny-list pattern hits); a file with
# count > threshold and not in the exempt list FAILs as "pack-only
# content sited outside pack-ops/".
_CHECK_38_PACK_ROOT_SCAN_GLOB = "*"


_CHECK_38_SIGNAL_THRESHOLD = 3  # heuristic; ≥N signals = pack-only content




def check_pack_only_file_siting() -> None:
    """Check 38 — pack-only-file siting (BD-175 M5c per Architect C §8.3).

    Per Architect C, the canonical post-B + B-fix design is that all
    PACK × OPERATIONS files live under `pack-ops/`. The only exception
    permitted at pack root is the 1-entry list in
    `pack-ops/.boundary-exempt-root.txt` (currently `tracker.toml.pack-
    example` per AUDIT-USER-CURATION.md Override 1).

    This check walks pack-root top-level files; for each, counts the
    pack-only-signal hits (deny-list patterns from Check 37) and FAILs
    when (a) the file is not in the exemption list AND (b) the file
    matches a pack-only-by-content heuristic via signal count > threshold.

    Implementation note: this is a coarse gate — semantic intent is
    not grep-detectable. The audit's V4 finding
    (`CONCEPTUAL-REVIEW-METHODOLOGY.md` is pack-only by content but was
    project-side by location) is the worked example this gate catches.
    Post B + B-fix, the relocations themselves cure the V4 case; this
    check is the regression guard.
    """
    print("\n── Check 38: Pack-only-file siting (BD-175, M5c) ──")
    exempt = _read_boundary_exempt_root()
    any_failed = False
    files_checked = 0

    # Walk pack root top-level files only (non-recursive).
    for path in sorted(REPO_ROOT.iterdir()):
        if not path.is_file():
            continue
        # Skip dotfiles (`.gitignore`, `.gitattributes`, etc. — these are
        # ecosystem-fixed names per trinity § Filename uniqueness exception).
        if path.name.startswith("."):
            continue
        # Skip the exemption list members.
        if path.name in exempt:
            continue
        # Skip files explicitly intended as pack-root user-facing (README,
        # QUICKSTART per AUDIT-USER-CURATION.md Override 7).
        if path.name in {"README.md", "QUICKSTART.md", "LICENSE", "Makefile"}:
            continue
        # Skip trinity at pack root (pack-root CLAUDE/AGENTS/GEMINI are
        # pack-chat-only operating rules and legitimately reference pack-only
        # mechanisms — they ARE pack-only by audience).
        if path.name in {"CLAUDE.md", "AGENTS.md", "GEMINI.md"}:
            continue
        # Skip TOML / shell / Python config files that aren't markdown
        # content (this check targets prose pack-only content that may
        # have been mis-sited).
        if path.suffix not in {".md", ".txt"}:
            continue
        files_checked += 1
        try:
            text = path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        # Count pack-only signals in this file.
        signals = 0
        for fname, _ in _DENY_LIST_FILENAMES:
            signals += text.count(fname)
        for prefix, _ in _DENY_LIST_PATH_PREFIXES:
            signals += text.count(prefix)
        for agent in _DENY_LIST_AGENT_NAMES:
            signals += len(re.findall(r"\b" + re.escape(agent) + r"\b", text))
        signals += text.count(_DENY_LIST_ROLE_NAME)
        if signals >= _CHECK_38_SIGNAL_THRESHOLD:
            fail(
                f"{path.name} — sited at pack root with {signals} "
                f"pack-only signal(s) (deny-list patterns from Check 37); "
                f"threshold is {_CHECK_38_SIGNAL_THRESHOLD}. Pack-only "
                f"content should live under `pack-ops/` per BD-175 "
                f"directory architecture. Allowed exemption files are "
                f"listed in `pack-ops/.boundary-exempt-root.txt` "
                f"(1-entry post-B-fix per AUDIT-USER-CURATION.md "
                f"Override 1 + 5)."
            )
            any_failed = True

    if not any_failed:
        ok(
            f"Check 38 — {files_checked} pack-root prose file(s) checked; "
            f"no pack-only content mis-sited outside `pack-ops/`. "
            f"Exemption list: {sorted(exempt) or 'empty'}."
        )




# ── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ─────
#
# Scope: bidirectional symmetry between the install map's `cmd_update` axis
# — the `_CLIENT_INSTALLED_FILES` and `_CLIENT_INSTALLED_GLOBS` comment
# blocks in `scripts/init-project.sh` — and project-template surface state.
#
# Forward direction (BD-175 F2a; `_CHECK_39_EXEMPTIONS`):
# `project-template/docs/pack/*.md` files must have explicit cmd_update
# mappings (catches the BD-175 Commit 10 OPTIONAL-FEATURES.md gap).
#
# Reverse direction (BD-180 observation E; `_CHECK_39_REVERSE_EXEMPTIONS`):
# every cmd_update row's `pack_relpath` must resolve to a file at HEAD
# (catches the pre-BD-180 PROMPT-TEMPLATES.md stale-mapping gap: retired
# in v10.0, yet its row persisted in the `_CLIENT_INSTALLED_FILES` block).
#
# Exemption allowlists (empty by default): files intentionally absent from
# `cmd_update` mappings (forward) or whose source intentionally lives
# outside repo HEAD (reverse). Surface-over-silently-exempt: when in
# doubt, leave OUT and let Check 39 FAIL — Pack Chat triage decides
# per-file. Each entry MUST include a one-line rationale comment.
#
# BOTH dicts are keyed by REPO-RELATIVE PATH, never by basename. The forward
# direction now spans two directories (`docs/pack/*.md` and
# `docs/pack/prompts/*.md`), so a basename key would be ambiguous across
# them — one key would silently exempt a same-named file in the other
# directory.
_CHECK_39_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD: every file under the two forward
    # directories has cmd_update coverage. Add entries here only with a
    # rationale comment, keyed by full repo-relative path.
}



_CHECK_39_REVERSE_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD per BD-180 observation E close: the
    # PROMPT-TEMPLATES.md stale entry was REMOVED from cmd_update in this
    # BD (retired in v10.0; mapping had been dead since the file deletion).
    # Add entries here only when a cmd_update source intentionally lives
    # outside the repo tree (e.g., a hypothetical extern-resolved path).
}


# ── Check 39 leg 3 (BD-093): the v10→v11 ADAPTER manifest reverse leg ──────
#
# WHY THIS LEG EXISTS. BD-180 observation E closed the stale-mapping class for
# `init-project.sh` `cmd_update` — but the SAME class was left open one file
# over: the migrator adapter declares its own pack→project path rows via the
# `migrator_manifest()` / `migrator_directory_sweeps()` hooks, and nothing
# verified those sources exist. The identical defect was still live at
# BD-093: `migrator_manifest()` declared
# `project-template/docs/pack/PROMPT-TEMPLATES.md`, retired in v10.0. It is
# benign at runtime (`_manifest_dispatch_transform` does
# `[[ -f "$theirs" ]] || theirs=""`, so the row is inert) — which is exactly
# why it survived: a declared mapping with NO backing, invisible to every
# gate. `declare-verify-backing`: a records-style check must verify the
# LOAD-BEARING reality (the source SHIPS), not merely that a row is
# well-formed.
#
# BOTH path-emitting hooks are covered, not just the file manifest. Guarding
# `migrator_manifest` while leaving `migrator_directory_sweeps` unguarded
# would reproduce the very asymmetric-coverage gap this leg closes
# (`enumerate-encoding-surfaces`); the two hooks are the same adapter
# contract — adjacent members of `_migrator_required_hooks` in
# `scripts/lib/migrator-core.sh` (an adapter that declares one declares
# both), and Check 47 already parses the pair JOINTLY via the shared
# `_migrator_heredoc_first_fields()`. Their CONSUMERS differ and that is
# immaterial here: `migrator_manifest` rows are read by `_manifest_parse`,
# sweep rows by `_manifest_sweep_dirs` (`scripts/lib/migrator-manifest.sh`).
#
# MEASURE-THEN-BOUND (ci-guard-measure-then-bound), measured at BD-093
# against the live tree BEFORE this leg was authored:
#   migrator_manifest()          13 rows -> 12 KEEP, 1 STRIP
#                                (STRIP = the PROMPT-TEMPLATES.md row, deleted
#                                 in this same change)
#   migrator_directory_sweeps()   3 rows ->  3 KEEP, 0 STRIP
# Post-STRIP the legitimate set is 100% backed, so the exemption allowlist is
# sized to EXACTLY ZERO — empty by construction, not by convenience (same
# shape as `_CHECK_39_REVERSE_EXEMPTIONS` above).
#
# TRACKED-NESS IS THE ORACLE, not `is_file()`: the question this leg answers
# is "does the declared source SHIP?", and an untracked-but-present working-
# tree file does not ship. One pathspec-scoped `git ls-files --
# project-template` call (the boundary_refs.py:_git_ls_files-multi precedent),
# never a raw filesystem walk.
#
# RUNTIME (ci-check-runtime-compounding): one bounded subprocess plus one
# read of the adapter file, then O(rows) set-membership tests over 16 rows.
# No per-row subprocess, no whole-tree walk. SKIP-lenient when git is
# unavailable or the adapter is absent.
_CHECK_39_MIGRATOR_EXEMPTIONS: dict[str, str] = {
    # Intentionally EMPTY at HEAD (measured: 0 legitimate-but-absent rows
    # across both hooks). Add an entry only when an adapter-declared source
    # intentionally lives outside tracked HEAD, with a one-line rationale.
}


# ── Forward leg 3 support: WHOLESALE-COPY roots (BD-293 F1) ─────────────────
#
# Forward legs 1 and 2 above bound copy sites that enumerate their members
# (the S6 `docs/pack/*.md` loop, the prompts loop). A WHOLESALE copy site —
# `cp -R "$dir"` or a `find "$dir"` walk — does the opposite: it reaches EVERY
# file beneath its source and therefore cannot omit one, while the install map
# declares members one at a time and `cmd_update` dispatches ONLY from that
# map. A file the wholesale site ships but the map does not declare is placed
# by a fresh install AND by a migration, yet is invisible to `--update`: it can
# be neither refreshed when the pack changes it nor repaired when it is
# missing. Leg 3 is that asymmetry's forward assertion, and it is the same
# question legs 1 and 2 ask, so it lives here rather than in a new check.
#
# The scripts scanned. Bounded to the two paths that copy pack sources into a
# client tree; the migrator's helper libs are excluded because their `find`
# walks target the CLIENT tree, not a pack source (measured: `checkpoint.sh`
# walks `"$target"`, which no `$PACK/project-template/...` assignment binds).
_CHECK_39_WHOLESALE_SCRIPTS: tuple[str, ...] = (
    "scripts/init-project.sh",
    "scripts/migrate-v10-to-v11.sh",
)

# `<VAR>="$PACK/project-template/<literal>"` — the only assignment shape that
# binds a shell variable to a LITERAL pack source path. A COMPOSED assignment
# (`local src="$pack_pt/$rel"`) deliberately does NOT match: its value is a
# runtime expression naming no single surface a guard could bound. Measured
# consequence: `stage_s5b_populate_pool`'s `cp -R "$src"` (the capability pool,
# declared as PROSE and fresh-install-only) resolves to nothing here and is
# correctly out of scope, with NO allowlist entry needed.
_CHECK_39_PACK_VAR_ASSIGN = re.compile(
    r'^[ \t]*(?:local[ \t]+)?([A-Za-z_]\w*)='
    r'"\$\{?PACK\}?/(project-template/[^"$]+)"[ \t]*$',
    re.M,
)

# A verb that reaches EVERY file beneath a directory: a recursive `cp` or a
# `find` walk.
#
# The leading guard is a LOOKBEHIND, not `(?:^|\s)`, and that is load-bearing:
# the migrator's walk is written `done < <(find "$bundle_src" -type f)`, where
# the character before `find` is `(`. A whitespace-or-start anchor silently
# misses it, which would shrink the bounded surface to whatever happens to be
# written with a leading space (measured: 1 site found instead of 2).
# `(?<![-\w])` still rejects the substring cases that matter — a longer word
# ending in `find`, and a flag like `--find`.
_CHECK_39_WHOLESALE_USE = re.compile(
    r'(?<![-\w])(?:cp[ \t]+-[A-Za-z]*[Rr][A-Za-z]*|find)[ \t]+"\$\{?([A-Za-z_]\w*)\}?"'
)

# A human-readable EXEMPLAR of the recursive-copy verb, used only to make the
# leg-3 diagnostic concrete. It is deliberately NOT the predicate: matching a
# bare `"cp -R"` substring is NARROWER than `_CHECK_39_WHOLESALE_USE`, which
# also accepts `cp -r`, `cp -pR`, and `find`. A tree left with only those
# shapes would report the marker ABSENT and the leg would skip silently —
# a vacuum inside the very backstop that exists to prevent one. The predicate
# below therefore derives from the regex, so the backstop can never be
# narrower than the thing it backstops.
_CHECK_39_WHOLESALE_MARKER = "cp -R"


def _check_39_wholesale_roots() -> dict[str, list[str]]:
    """Derive the pack-relative directories a wholesale copy site reaches.

    Returns `{pack_relative_dir: [<script>:<line> ...]}`. DERIVED from the copy
    sites themselves, never hard-coded: a rename of the source directory moves
    the assertion with it, and a copy site that disappears empties the mapping
    — which leg 3 treats as an absence-of-backing FAILURE rather than a
    vacuous pass.
    """
    roots: dict[str, list[str]] = {}
    for script in _CHECK_39_WHOLESALE_SCRIPTS:
        path = REPO_ROOT / script
        if not path.is_file():
            continue
        text = path.read_text()
        binding = {
            m.group(1): m.group(2).rstrip("/")
            for m in _CHECK_39_PACK_VAR_ASSIGN.finditer(text)
        }
        if not binding:
            continue
        for lineno, line in enumerate(text.splitlines(), start=1):
            if line.lstrip().startswith("#"):
                continue
            for m in _CHECK_39_WHOLESALE_USE.finditer(line):
                target = binding.get(m.group(1))
                if not target:
                    continue
                if not (REPO_ROOT / target).is_dir():
                    continue
                roots.setdefault(target, []).append(f"{script}:{lineno}")
    return roots


def _check_39_wholesale_marker_present() -> bool:
    """True iff any scanned install script still uses a recursive-copy verb.

    This is leg 3's "the derivation has something to find" predicate — the
    thing that separates a legitimately-inapplicable tree (a scaffold with no
    stage bodies) from a REGRESSED one (a real tree whose copy idiom changed
    shape).

    DERIVED from `_CHECK_39_WHOLESALE_USE` — the exact regex whose failure to
    resolve a root this predicate backstops — rather than from a narrower
    literal. A literal `"cp -R"` substring test accepts a strict SUBSET of the
    regex (it misses `cp -r`, `cp -pR`, and `find`), so a tree written only in
    those shapes would answer False and the leg would go silently vacuous
    instead of FAILing. Sharing one definition makes that impossible: the
    predicate is True on exactly the lines the derivation scans, so it can
    never be narrower than the derivation it guards.

    Uses the same comment-line skip as `_check_39_wholesale_roots()` so both
    read the identical line set — a verb mentioned only in a comment is not a
    use, and must not keep the backstop alive on a tree that stopped copying.
    """
    for script in _CHECK_39_WHOLESALE_SCRIPTS:
        path = REPO_ROOT / script
        if not path.is_file():
            continue
        for line in path.read_text().splitlines():
            if line.lstrip().startswith("#"):
                continue
            if _CHECK_39_WHOLESALE_USE.search(line):
                return True
    return False


def _parse_migrator_manifest_sources() -> tuple:
    """Parse the v10→v11 adapter's two path-emitting hooks.

    Returns `(file_rows, dir_rows)` — the pack-side source path of every
    `migrator_manifest()` row and every `migrator_directory_sweeps()` row
    (field 0 in both cases; the manifest is TAB-separated and the sweeps
    space-separated, which the shared whitespace split handles alike).

    Parsing is DELEGATED to `_migrator_heredoc_first_fields()` — the same
    helper Check 47 already runs over these exact two hooks — rather than
    re-implemented. A second, narrower parser here could disagree with
    Check 47 and, worse, go SILENTLY INERT (return no rows, so the leg's
    `if mig_files or mig_dirs:` short-circuits and Check 39 passes while
    checking nothing) on an adapter that merely renamed its heredoc marker,
    left it unquoted, used the `<<-` form, or put a comment before the
    `cat`. That is the exact defect class BD-093 exists to close. Returns
    `([], [])` only when the adapter FILE itself is absent.
    """
    adapter = REPO_ROOT / _MIGRATOR_REL
    if not adapter.is_file():
        return ([], [])
    text = adapter.read_text()
    file_rows = _migrator_heredoc_first_fields(text, "migrator_manifest")
    dir_rows = _migrator_heredoc_first_fields(text, "migrator_directory_sweeps")
    return ([p for p in file_rows if p], [p for p in dir_rows if p])




def check_cmd_update_symmetry() -> None:
    """Check 39 — cmd_update mapping/glob coverage symmetry (BD-175 F2a + BD-180 E).

    Bidirectional symmetry between the install map's `cmd_update` axis and
    the project-template surface. The `cmd_update` set is DERIVED from the
    install map in `scripts/init-project.sh` — the explicit rows tagged
    `cmd_update` UNION the GLOB-block family patterns tagged `cmd_update`.
    The map is the one declaration; this check never re-declares it.

    Forward direction (BD-175 F2a): every file under
    `project-template/docs/pack/*.md` (the S6 fresh-install glob target)
    must be covered by a map row. Catches the BD-175 Commit 10
    OPTIONAL-FEATURES.md fresh-init-only gap. A SECOND forward leg covers
    `project-template/docs/pack/prompts/*.md`, which the non-recursive
    `docs/pack/*.md` glob never descends into; a prompts file is covered by
    the GLOB-block family row, not by an explicit row.

    A THIRD forward leg (BD-293 F1) covers the WHOLESALE copy sites — the
    `cp -R "$dir"` / `find "$dir"` shapes that reach every file beneath a pack
    source directory and so cannot omit a member. Legs 1 and 2 bound sites
    that enumerate their members; this one bounds the sites that do not, which
    is how `plugin.json` and `RUNTIME-SUBAGENT-PATTERN.md` shipped in the
    Antigravity bundle while appearing in ZERO map rows on ANY axis — placed by
    a fresh install and by a migration, invisible to `--update`. The root set
    is DERIVED from the copy sites (never hard-coded), and the leg FAILs rather
    than passing vacuously when the recursive-copy marker is present but the
    derivation resolves nothing. It carries NO exemption list: a wholesale site
    ships every member, so every member must be refreshable.

    Note this leg is the forward twin of Check 41 clause (e), which asks the
    OPPOSITE question (does a DECLARED row have a copy site?) and is keyed to
    per-file copy literals — a `cp -R` row is structurally outside it.

    Reverse direction (BD-180 observation E): every explicit `cmd_update`
    row's `pack_relpath` must resolve to a file at HEAD, and every
    `cmd_update` GLOB row's pattern must match at least one real file.
    Catches stale mappings whose source file was retired (pre-BD-180
    example: PROMPT-TEMPLATES.md retired in v10.0 but the mapping
    persisted).

    Exemption allowlists:
    - `_CHECK_39_EXEMPTIONS` — forward (file-on-disk lacks mapping;
      intentional).
    - `_CHECK_39_REVERSE_EXEMPTIONS` — reverse (mapping points outside
      repo HEAD; intentional).

    Lenient mode: if `scripts/init-project.sh` is absent (unlikely;
    REPO_ROOT issue) the check skips with a notice.
    """
    print("\n── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──")
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return
    pack_docs_dir = REPO_ROOT / "project-template" / "docs" / "pack"
    if not pack_docs_dir.is_dir():
        ok("project-template/docs/pack absent — skipping (lenient)")
        return

    # The `cmd_update` axis, DERIVED from the install map's two blocks.
    stage_map = _parse_client_installed_file_stages()
    entries = {p for p, st in stage_map.items() if "cmd_update" in st}
    glob_rows = _parse_client_installed_globs()
    glob_patterns = [
        pat for pat, _dest, st, _cls in glob_rows if "cmd_update" in st
    ]
    if not entries and not glob_patterns:
        fail(
            "could not derive the `cmd_update` axis from the install map in "
            "scripts/init-project.sh — neither the explicit FILES block nor "
            "the GLOB block yielded a row tagged `cmd_update`. Check that "
            "both blocks' START/END markers appear exactly once and that "
            "each row carries a `[stage:...]` operand naming its copy sites."
        )
        return

    def _covered(pack_rel: str) -> bool:
        """True iff the map covers `pack_rel` on the `cmd_update` axis —
        by an explicit row or by a GLOB-block family pattern."""
        if pack_rel in entries:
            return True
        return any(_install_glob_matches(p, pack_rel) for p in glob_patterns)

    any_failed = False

    # ── Forward direction (BD-175 F2a) ───────────────────────────────────
    files_checked = 0
    exempted = 0
    for md in sorted(pack_docs_dir.glob("*.md")):
        files_checked += 1
        pack_rel = f"project-template/docs/pack/{md.name}"
        if _covered(pack_rel):
            continue
        if pack_rel in _CHECK_39_EXEMPTIONS:
            exempted += 1
            ok(
                f"{pack_rel} — exempt per _CHECK_39_EXEMPTIONS: "
                f"{_CHECK_39_EXEMPTIONS[pack_rel]}"
            )
            continue
        fail(
            f"{pack_rel} — installs at fresh init (stage S6 glob loop) but "
            f"the install map has no `cmd_update` coverage for it; existing "
            f"clients running `pack update` will silently skip this file. "
            f"Add a row to the EXPLICIT block of the install map in "
            f"scripts/init-project.sh of the form: "
            f"`#   {pack_rel}  ->  docs/pack/{md.name}  "
            f"[stage:S6,cmd_update,migrate]  [class:generic]`. If the file "
            f"is intentionally pre-install-only or otherwise not for "
            f"client install, add it to `_CHECK_39_EXEMPTIONS` in "
            f"scripts/validate-pack.py — keyed by the repo-relative path "
            f"`{pack_rel}`, not the basename — with a one-line rationale."
        )
        any_failed = True

    # ── Forward leg 2: docs/pack/prompts/ ────────────────────────────────
    # The `docs/pack/*.md` glob above is NON-recursive and never descends
    # into prompts/. A prompts file is covered by the GLOB-block family row,
    # so the remediation here names the GLOB block, not the explicit block.
    prompts_dir = pack_docs_dir / "prompts"
    prompts_checked = 0
    if prompts_dir.is_dir():
        for md in sorted(prompts_dir.glob("*.md")):
            prompts_checked += 1
            pack_rel = f"project-template/docs/pack/prompts/{md.name}"
            if _covered(pack_rel):
                continue
            if pack_rel in _CHECK_39_EXEMPTIONS:
                exempted += 1
                ok(
                    f"{pack_rel} — exempt per _CHECK_39_EXEMPTIONS: "
                    f"{_CHECK_39_EXEMPTIONS[pack_rel]}"
                )
                continue
            fail(
                f"{pack_rel} — installs at fresh init (stage S6 prompts "
                f"loop) but the install map has no `cmd_update` coverage "
                f"for it; existing clients running `pack update` will "
                f"silently skip this file. The prompts family ships as a "
                f"family: add or restore the GLOB-block row "
                f"`#   project-template/docs/pack/prompts/*.md  ->  "
                f"docs/pack/prompts/*.md  [stage:S6,cmd_update,migrate]  "
                f"[class:generic]` in scripts/init-project.sh. If the file "
                f"is intentionally not for client install, add it to "
                f"`_CHECK_39_EXEMPTIONS` in scripts/validate-pack.py — keyed "
                f"by the repo-relative path `{pack_rel}`, not the basename — "
                f"with a one-line rationale."
            )
            any_failed = True

    # ── Forward leg 3: WHOLESALE-copy roots (BD-293 F1) ──────────────────
    # Legs 1 and 2 bound copy sites that ENUMERATE their members. This leg
    # bounds the opposite shape: a site that copies a whole directory reaches
    # every file under it and cannot omit one, so the map is the only surface
    # that can disagree — and when it does, `--update` (which dispatches the
    # `cmd_update` axis and nothing else) can neither refresh nor repair the
    # undeclared file, permanently and silently.
    #
    # NO allowlist, deliberately: an exemption would re-admit exactly the gap
    # this leg closes, and the measured legitimate set is "everything under the
    # root" — a wholesale site ships all of it by construction, so no member
    # legitimately never updates.
    #
    # Two-part, so a vacuous pass is impossible (declare-verify-backing, the
    # absence-of-backing instance): the root set is DERIVED from the copy
    # sites, and when the recursive-copy marker is PRESENT but the derivation
    # resolves nothing — or resolves a root holding no tracked file — the leg
    # FAILs instead of quietly measuring an empty set.
    wholesale_checked = 0
    wholesale_roots = _check_39_wholesale_roots()
    if not wholesale_roots:
        if _check_39_wholesale_marker_present():
            fail(
                f"install map forward leg 3 — a recursive-copy verb "
                f"(e.g. `{_CHECK_39_WHOLESALE_MARKER}`) is still used in "
                f"{list(_CHECK_39_WHOLESALE_SCRIPTS)}, but NO wholesale copy "
                f"site resolves to a pack source directory. This leg bounds "
                f"sites that copy a WHOLE directory into a client "
                f"(`cp -R \"$var\"` / `find \"$var\"`, where `var` is assigned "
                f"a literal `\"$PACK/project-template/...\"` path). Resolving "
                f"NONE while the verb is still there means the assignment was "
                f"rewritten into a composed form or the idiom changed — the "
                f"leg would then pass vacuously forever, which is exactly the "
                f"silent state it exists to prevent. Restore the literal "
                f"assignment, or update `_CHECK_39_PACK_VAR_ASSIGN` / "
                f"`_CHECK_39_WHOLESALE_USE` to match the new shape."
            )
            any_failed = True
    else:
        for root in sorted(wholesale_roots):
            # `None` and `[]` are DIFFERENT answers and must never be folded
            # together. `None` means git could not be asked (not installed, or
            # not a work tree) — an UNKNOWN, which every other call site in
            # this module SKIPs leniently per the helper's own contract and per
            # `ci-guard-measure-then-bound`. `[]` means git WAS asked and the
            # root genuinely holds no tracked file — a real finding, because
            # the member sweep below would then pass vacuously. Collapsing the
            # two (`or []`) turns a lenient skip into a hard FAIL whose
            # diagnostic tells the operator to track files that are in fact
            # already tracked.
            tracked = _git_tracked_relpaths(root)
            if tracked is None:
                ok(
                    f"install map forward leg 3 — git is unavailable or this "
                    f"is not a work tree, so the members of `{root}/` cannot "
                    f"be enumerated; skipping the wholesale-coverage sweep for "
                    f"this root (lenient)."
                )
                continue
            members = [rel for rel in tracked if (REPO_ROOT / rel).is_file()]
            if not members:
                fail(
                    f"install map forward leg 3 — wholesale copy site "
                    f"{wholesale_roots[root]} copies `{root}/`, but that "
                    f"directory holds NO git-tracked file, so the coverage "
                    f"assertion below would be vacuously true. Either the "
                    f"directory was emptied (remove the copy site) or its "
                    f"contents are untracked (track them)."
                )
                any_failed = True
                continue
            for rel in sorted(members):
                wholesale_checked += 1
                if _covered(rel):
                    continue
                fail(
                    f"{rel} — shipped by the WHOLESALE copy site "
                    f"{wholesale_roots[root]} (`{root}/` is copied in full) "
                    f"but the install map has no `cmd_update` coverage for it. "
                    f"A fresh install and a migration both place this file; "
                    f"`--update` derives its whole dispatch set from the map, "
                    f"so it can neither refresh nor repair it — the client "
                    f"keeps whatever bytes it first received, forever. Add a "
                    f"row to the EXPLICIT block of the install map in "
                    f"scripts/init-project.sh of the form: "
                    f"`#   {rel}  ->  <project_relpath>  "
                    f"[stage:<copy-site>,cmd_update,migrate]  [class:<token>]`. "
                    f"There is no exemption list for this leg: a wholesale "
                    f"copy site ships every member, so every member must be "
                    f"refreshable."
                )
                any_failed = True

    # ── Reverse direction (BD-180 observation E) ─────────────────────────
    reverse_checked = 0
    reverse_exempted = 0
    for pack_rel in sorted(entries):
        reverse_checked += 1
        src_path = REPO_ROOT / pack_rel
        if src_path.is_file():
            continue
        if pack_rel in _CHECK_39_REVERSE_EXEMPTIONS:
            reverse_exempted += 1
            ok(
                f"{pack_rel} — exempt per _CHECK_39_REVERSE_EXEMPTIONS: "
                f"{_CHECK_39_REVERSE_EXEMPTIONS[pack_rel]}"
            )
            continue
        fail(
            f"{pack_rel} — install-map row references a source file that "
            f"does not exist at HEAD; the mapping is stale (likely the "
            f"source file was retired or moved without removing the row). "
            f"Either remove the row from the install map in "
            f"scripts/init-project.sh, or if the source intentionally "
            f"lives outside repo HEAD, add it to "
            f"`_CHECK_39_REVERSE_EXEMPTIONS` in scripts/validate-pack.py "
            f"with a one-line rationale. Empirical precedent: BD-180 "
            f"observation E removed the stale `project-template/docs/pack/"
            f"PROMPT-TEMPLATES.md` mapping (file retired in v10.0)."
        )
        any_failed = True

    # ── Reverse leg 2: every cmd_update GLOB pattern has real backing ────
    # `declare-verify-backing`: a family row that matches ZERO files is a
    # dead declaration, exactly the stale-mapping class the explicit
    # reverse leg catches one file at a time.
    #
    # Backing is measured against git-TRACKED HEAD, not the filesystem: a
    # filesystem glob is satisfied by a gitignored build artifact (a
    # `__pycache__/` directory sits inside `project-template/scripts/`
    # whenever the suite has run), which ships nothing and would make this
    # leg's own "backed at HEAD" wording false. Leg 3 already draws from
    # git-tracked HEAD; this matches it, with the pathspec DERIVED from the
    # declared patterns so the whole leg costs ONE subprocess.
    glob_tracked = None
    if glob_patterns:
        try:
            glob_pathspecs = sorted({
                p.split("/", 1)[0] for p in glob_patterns if p
            })
            res_g = subprocess.run(
                ["git", "ls-files", "--"] + glob_pathspecs,
                cwd=REPO_ROOT, capture_output=True, text=True,
            )
            if res_g.returncode == 0:
                glob_tracked = [
                    ln.strip() for ln in res_g.stdout.splitlines() if ln.strip()
                ]
        except (FileNotFoundError, OSError):
            glob_tracked = None
    if glob_patterns and glob_tracked is None:
        ok(
            "Check 39 reverse leg 2 — git unavailable (not a git work tree) — "
            "falling back to a filesystem match for GLOB-row backing (lenient)"
        )

    glob_reverse_checked = 0
    for pat in sorted(glob_patterns):
        glob_reverse_checked += 1
        if pat in _CHECK_39_REVERSE_EXEMPTIONS:
            reverse_exempted += 1
            ok(
                f"{pat} — exempt per _CHECK_39_REVERSE_EXEMPTIONS: "
                f"{_CHECK_39_REVERSE_EXEMPTIONS[pat]}"
            )
            continue
        if glob_tracked is not None:
            matched = any(_install_glob_matches(pat, c) for c in glob_tracked)
        else:
            try:
                matched = any(REPO_ROOT.glob(pat))
            except (ValueError, OSError):
                matched = False
        if matched:
            continue
        fail(
            f"{pat} — install-map GLOB-block row matches NO file at HEAD; "
            f"the family declaration has no backing (the source directory "
            f"was emptied, renamed, or the pattern is misspelled). Either "
            f"remove the row from the GLOB block in scripts/init-project.sh "
            f"or correct the pattern. A family row that matches nothing "
            f"silently drops its whole family from every derived consumer."
        )
        any_failed = True

    # ── Leg 3: v10→v11 adapter manifest reverse direction (BD-093) ───────
    # Same defect class as the BD-180 leg above, one file over: an adapter-
    # declared pack-side source that does not ship. See the leg-3 block
    # comment near `_CHECK_39_MIGRATOR_EXEMPTIONS` for the measurement.
    mig_files, mig_dirs = _parse_migrator_manifest_sources()
    mig_checked = 0
    mig_exempted = 0
    if mig_files or mig_dirs:
        try:
            # Pathspec DERIVED from the declared rows, never hard-coded.
            # The adapter contract imposes no project-template/ restriction
            # (`supporting-docs/` is an equally legitimate client-deliverable
            # root — see `_is_pack_side_ship_source`), so scoping to a fixed
            # prefix while testing EVERY row against that set would make a
            # row sourced elsewhere FAIL with a message falsely asserting it
            # "is NOT tracked at HEAD, so it does not ship". Deriving the
            # scope keeps the single-subprocess cost
            # (`ci-check-runtime-compounding`) with no false-FAIL possible.
            mig_pathspecs = sorted({
                p.split("/", 1)[0] for p in list(mig_files) + list(mig_dirs) if p
            })
            res = subprocess.run(
                ["git", "ls-files", "--"] + mig_pathspecs,
                cwd=REPO_ROOT, capture_output=True, text=True,
            )
            git_ok = res.returncode == 0
        except (FileNotFoundError, OSError):
            git_ok = False
        if not git_ok:
            ok(
                "Check 39 leg 3 — git unavailable (not a git work tree) — "
                "skipping the migrator-manifest reverse leg (lenient)"
            )
        else:
            tracked = {ln.strip() for ln in res.stdout.splitlines() if ln.strip()}
            tracked_dirs = {p.rsplit("/", 1)[0] for p in tracked if "/" in p}
            # A declared directory is backed if ANY tracked path sits under
            # it (a parent-of-a-tracked-file is itself a shipped directory).
            for d in list(tracked_dirs):
                parts = d.split("/")
                for i in range(1, len(parts)):
                    tracked_dirs.add("/".join(parts[:i]))

            for pack_rel in mig_files:
                mig_checked += 1
                if pack_rel in tracked:
                    continue
                if pack_rel in _CHECK_39_MIGRATOR_EXEMPTIONS:
                    mig_exempted += 1
                    ok(
                        f"{pack_rel} — exempt per "
                        f"_CHECK_39_MIGRATOR_EXEMPTIONS: "
                        f"{_CHECK_39_MIGRATOR_EXEMPTIONS[pack_rel]}"
                    )
                    continue
                fail(
                    f"{pack_rel} — `migrator_manifest()` in "
                    f"scripts/migrate-v10-to-v11.sh declares a pack-side "
                    f"source that is NOT tracked at HEAD, so it does not "
                    f"ship: the mapping is stale and the row is silently "
                    f"inert at migration time "
                    f"(`_manifest_dispatch_transform` blanks an absent "
                    f"`theirs`). Either delete the row from the "
                    f"`migrator_manifest()` heredoc, or — if the source "
                    f"intentionally lives outside tracked HEAD — add it to "
                    f"`_CHECK_39_MIGRATOR_EXEMPTIONS` in "
                    f"scripts/lib/validate_checks/boundary_refs.py with a "
                    f"one-line rationale. Same class as the BD-180 "
                    f"`cmd_update` stale-mapping fix; BD-093 closed it for "
                    f"the migrator adapter."
                )
                any_failed = True

            for pack_dir in mig_dirs:
                mig_checked += 1
                if pack_dir in tracked_dirs:
                    continue
                if pack_dir in _CHECK_39_MIGRATOR_EXEMPTIONS:
                    mig_exempted += 1
                    ok(
                        f"{pack_dir} — exempt per "
                        f"_CHECK_39_MIGRATOR_EXEMPTIONS: "
                        f"{_CHECK_39_MIGRATOR_EXEMPTIONS[pack_dir]}"
                    )
                    continue
                fail(
                    f"{pack_dir} — `migrator_directory_sweeps()` in "
                    f"scripts/migrate-v10-to-v11.sh declares a pack-side "
                    f"directory with no tracked files under it, so the "
                    f"sweep ships nothing. Either delete the row from the "
                    f"`migrator_directory_sweeps()` heredoc, or add it to "
                    f"`_CHECK_39_MIGRATOR_EXEMPTIONS` with a one-line "
                    f"rationale."
                )
                any_failed = True

    if not any_failed:
        ok(
            f"Check 39 — {files_checked} `project-template/docs/pack/*.md` "
            f"+ {prompts_checked} `docs/pack/prompts/*.md` file(s) "
            f"forward-checked against the install map; "
            f"{files_checked + prompts_checked - exempted} are covered by a "
            f"map row on the `cmd_update` axis, {exempted} on the forward "
            f"exemption allowlist. {wholesale_checked} wholesale-copied "
            f"member(s) across {len(wholesale_roots)} derived copy root(s) "
            f"forward-checked; all are covered on the `cmd_update` axis (no "
            f"exemption list for this leg). {reverse_checked} explicit `cmd_update` "
            f"row(s) + {glob_reverse_checked} `cmd_update` GLOB row(s) "
            f"reverse-checked; "
            f"{reverse_checked + glob_reverse_checked - reverse_exempted} "
            f"are backed at HEAD, {reverse_exempted} on the reverse "
            f"exemption allowlist. {mig_checked} v10→v11 adapter "
            f"manifest/sweep row(s) reverse-checked against git-tracked "
            f"HEAD; {mig_checked - mig_exempted} are backed by a shipped "
            f"source, {mig_exempted} on the migrator exemption allowlist. "
            f"No asymmetric coverage between the S6 fresh-install globs and "
            f"the install map's `cmd_update` axis; no stale mappings."
        )




# ── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──────────────
#
# Per ARCHITECTURE-BD-179.md §3-§8. Walks `pack-ops/*.md` (excluding the
# deleted-monolith basenames BACKLOG.md + CHANGELOG.md per §2.1 D1a — a
# defensive exemption retained post-BD-203; there is no regenerated mirror
# under the no-mirror model) and flags backtick-delimited filename refs
# that lack a directory qualifier.
#
# Detection: P1 (bullet) + P2 (prose) + P3 (table) + P5 (hyperlink) regex
# patterns over a code-block-stripped representation per §3 D2. The first
# regex matches backtick-delimited filename spans like `MIGRATION-v10-to-v11.md`
# (no `/` in character class — qualified paths skip by construction). The
# hyperlink regex matches `](FILENAME.md)` form for `[link](FILENAME.md)`.
#
# Exemption: two-tier per §6 D5.
#   - `_CHECK_40_ALLOWLIST` — hardcoded dict (per §6.6 self-documenting
#     comment): pack-root files / trinity / memory cache / concept-noun
#     placeholders. PASS-with-notice.
#   - `_CHECK_40_ANCHOR_PHRASES` — contextual anchors in ±2-line window
#     around the hit. PASS-with-notice.
#   - Same-dir-legitimate — bare ref whose basename has exactly one
#     candidate path AND that path is in the same directory as the
#     referencing doc (e.g., bare `MERGE-STRATEGY.md` inside `pack-ops/`
#     resolves to `pack-ops/MERGE-STRATEGY.md`). PASS-with-notice. Per
#     Phase 1 survey §7.1 implicit-rule classification.
#
# Failure: FAIL with file:line + candidate-paths suggestion. Per §5.1
# triage: 0 candidates = broken ref; 1 candidate = qualify to <path>;
# 2+ = qualify to one of <paths>.

# Check 40 — pack-ops/ bare-cross-reference scanner — hardcoded allowlist.
# Extend this list when new bare references in pack-ops/ markdown are
# explicitly authorized (e.g., new pack-root files, new trinity members,
# new tool-specific exempt patterns). Adding an entry here is the
# intentional escape hatch for legitimate bareness; prefer qualifying
# the ref over allowlisting it unless the ref's bareness is load-bearing.
# Each addition lands in a BD's IMPL-REPORT with rationale per
# ARCHITECTURE-BD-179.md §6.5. (Self-documenting comment per §6.6,
# user-approved Q-B 2026-05-20.)
_CHECK_40_ALLOWLIST: dict[str, str] = {
    # Pack-root landing-page files — always resolvable at pack root per
    # `pack-ops/BOUNDARY-DEFINITION.md` §2 C1 (PACK × PRODUCT) classification.
    "README.md": "Pack-root landing-page doc (BOUNDARY-DEFINITION.md C1)",
    "QUICKSTART.md": "Pack-root installer doc (BOUNDARY-DEFINITION.md C1 + Override 7)",
    "LICENSE.md": "Pack-root deliverable; standard repo convention",
    "LICENSE": "Pack-root deliverable; extension-less licence file",
    # Pack-root trinity — always at pack root by Claude/Codex/Gemini contract
    # (BOUNDARY-DEFINITION.md §2 C3). Bare ref in pack-ops/ disambiguates
    # via the doc's own audience qualifier (pack-internal) per discipline.
    "CLAUDE.md": "Pack-root trinity (C3); see also project-template/CLAUDE.md",
    "AGENTS.md": "Pack-root trinity (C3); see also project-template/AGENTS.md",
    "GEMINI.md": "Pack-root trinity (C3); see also project-template/GEMINI.md",
    # Pack-memory `MEMORY.md` — the Claude-Code memory cache; bare ref
    # legitimate from any pack-side doc (the file lives in `~/.claude/...`,
    # not in the pack repo; bare ref is the actual reference shape).
    "MEMORY.md": "Claude-Code memory cache (external to pack repo)",
    # Claude-Code `settings.json` — external user/project config the
    # developer authors; the pack ships NO settings file (BD-197 hard
    # constraint). Bare ref is load-bearing in OPTIONAL-FEATURES because
    # the same key (`worktree.baseRef`, `permissions.deny`) lives at EITHER
    # user scope (`~/.claude/settings.json`) OR project scope
    # (`.claude/settings.json`) — qualifying to one path would misrepresent
    # the documented "user OR project scope" choice. Same external-to-pack
    # class as MEMORY.md. (BD-197 C5; ARCHITECTURE-BD-179.md §6.5.)
    "settings.json": "Claude-Code user/project config (external to pack repo; scope-agnostic per BD-197 OPTIONAL-FEATURES)",
    # Concept-noun / generated-file / placeholder additions (OQ-S2,
    # user-approved 2026-05-20). Files generated at runtime / opt-in /
    # absent from pack repo at HEAD, or per-entry-tree filename
    # PATTERN placeholders (not real files).
    "tracker.toml": "Generated by `pack tracker init` (not in pack repo; pack ships tracker.toml.pack-example)",
    "id-map.json": "Generated tracker-mode metadata (not in pack repo)",
    "report.md": "Generated by scripts/lib/customization-report.sh (not in pack repo)",
    "manifest.txt": "RC9 manifest at test-fixtures/manifest.txt (per RC9 trigger rule)",
    "BD-NNN.md": "Per-entry backlog filename pattern (template)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Claude-Code memory-cache feedback file (OQ-S3 Option A,
    # user-approved 2026-05-20). Same class as MEMORY.md. (BD-243: the cited
    # name corrected feedback_review_fix_one_cycle.md → feedback_review_fix_cycle.md
    # at CG-14-prep-b; the allowlist entry tracks the corrected name in lock-step.)
    "feedback_review_fix_cycle.md": "Claude-Code memory cache feedback file (external to pack repo)",
    # Project-side help fragment. A bare ref resolves at the
    # client-installed location (docs/pack/HELP-FRAGMENT.md in the client
    # repo as a same-dir sibling). Resolves via Check 41
    # _CLIENT_INSTALLED_FILES.
    "HELP-FRAGMENT.md": "Project-side mirror exception; resolves at client-installed location (see Check 41 _CLIENT_INSTALLED_FILES)",
}



# Anchor phrases that, when found within the per-pattern context window
# (matched line + N lines before + N lines after), mark the match as
# legitimate per architect doc §6.4. A SUBSET of Check 37's anchor set,
# plus three new phrases scoped to Check 40's defect class.
_CHECK_40_ANCHOR_PHRASES = (
    # Inherit pack-vs-project disambiguation context from Check 37
    # (the pack/project boundary rules in pack-ops/BOUNDARY-DEFINITION.md).
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "in the project",
    "at the client",
    # Audience-bridge context (intentional client-path references in
    # pack-internal docs that discuss what happens after init-project.sh
    # runs). Per ARCHITECTURE-BD-179.md §7 D6. OQ-3 confirmed.
    "post-install",
    # OQ-S4 — self-flagging non-existence prose (e.g., L247
    # "...cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); ...").
    "does not exist",
    # OQ-S4 forward-compat — explicit "archived" qualifier in prose
    # (e.g., L195 "from the now-archived `ARCHITECTURE-V1.md` ...").
    "archived",
)



_CHECK_40_ANCHOR_WINDOW = 2  # lines before/after; matches Check 37 default



# Filename-extension classes Check 40 recognizes (per §3.3 final regex).
# Same set for the bullet/prose/table regex and the hyperlink regex.
_CHECK_40_FILE_EXTS = "md|sh|py|toml|yml|yaml|json|txt"



# Backtick-delimited bare ref (P1 + P2 + P3): `FILENAME.ext`. The first
# character class excludes `/` so qualified paths (`scripts/foo.sh`,
# `pack-ops/MERGE-STRATEGY.md`) are NOT matched. The first char is
# `[A-Za-z]` per §3.5 final (lowercase-starting filenames like
# `merge-json.py` must be admitted).
_CHECK_40_BARE_REF_PATTERN = re.compile(
    r"`([A-Za-z][A-Za-z0-9_.-]*\.(?:" + _CHECK_40_FILE_EXTS + r"))`"
)



# Markdown hyperlink (P5): `[link](FILENAME.ext)`. Same character class
# discipline as the bare-ref pattern.
_CHECK_40_HYPERLINK_PATTERN = re.compile(
    r"\]\(([A-Za-z][A-Za-z0-9_.-]*\.(?:" + _CHECK_40_FILE_EXTS + r"))\)"
)



# Code-block stripper: replace fenced code-block content (``` ... ```)
# AND indented 4-space code-block content with empty lines so line
# numbers are preserved. Single-backtick spans inside non-code-block
# prose are NOT stripped — those ARE the surface Check 40 looks for.
def _strip_code_blocks(text: str) -> list[str]:
    """Per `ARCHITECTURE-BD-179.md` §3.2 (code-block-stripping preprocess).

    Return list of lines with code-block content replaced by empty
    strings. Two mechanisms are recognized:

    1. **Fenced code blocks** (CommonMark §4.5) — lines whose first
       non-whitespace token is ` ``` ` (with optional language id) open
       and close the fence. All lines inside the fence (and the fence
       lines themselves) are replaced with empty strings.

    2. **Indented code blocks** (CommonMark §4.4) — outside a fenced
       block, a line that begins with 4 spaces of indentation AND
       follows a blank line begins an indented block. Consecutive
       lines that ALSO begin with 4-space indentation continue the
       block; blank lines INSIDE the block (between two indented
       lines) are tolerated. The block ends at the first non-blank
       line that is NOT 4-space-indented. All lines that participate
       in the block are replaced with empty strings.

       CommonMark edge cases (e.g., indented inside a list item is
       NOT an indented code block) are intentionally NOT modeled —
       pack-ops/ markdown convention favors fenced blocks, and the
       simple top-level "blank line then 4-space indent" rule covers
       every observed case without over-engineering (architect §3.2
       acknowledges the trade-off).

    Preserves total line count so file:line citations from Check 40
    remain accurate against the original file (matching Check 37
    convention).
    """
    raw_lines = text.splitlines()
    out: list[str] = []
    in_fence = False
    in_indented = False
    prev_blank = True  # treat "before line 0" as blank → indent can open at line 0
    for line in raw_lines:
        stripped = line.lstrip()
        # Fenced-block handling takes precedence over indented detection.
        if stripped.startswith("```"):
            in_fence = not in_fence
            in_indented = False  # fence trumps any pending indented context
            out.append("")  # the fence line itself is also stripped
            prev_blank = False
            continue
        if in_fence:
            out.append("")
            prev_blank = False
            continue

        # Indented-block handling.
        is_blank = line.strip() == ""
        is_indented_4 = line.startswith("    ")

        if in_indented:
            if is_indented_4:
                # Block continues.
                out.append("")
                prev_blank = False
                continue
            if is_blank:
                # Blank line inside indented block — keep block open;
                # emit empty line (line count preserved).
                out.append("")
                prev_blank = True
                continue
            # Non-indented non-blank line ends the block.
            in_indented = False
            # Fall through to emit this line as prose.
        else:
            if is_indented_4 and prev_blank:
                # Open new indented block at this line.
                in_indented = True
                out.append("")
                prev_blank = False
                continue

        out.append(line)
        prev_blank = is_blank
    return out




# EXCLUDE directories for the basename-index walk (per §5.1 D4).
# `scripts/tests/fixtures/` added per OQ-S1 ratification 2026-05-20.
_CHECK_40_EXCLUDE_PARTS = (
    ".git",
    "maintenance-docs/archive",
    "test-fixtures",
    "scripts/tests/fixtures",
    "node_modules",
)




def _git_tracked_relpaths(*trees: str) -> list[str] | None:
    """git-tracked repo-relative POSIX paths under the given trees (whole
    repo if none). Returns None if git is unavailable / not a work tree —
    the caller then SKIPs leniently (mirrors Check 63 / Check 69). Per
    `ci-guard-measure-then-bound`: enumerate git-TRACKED files, never a raw
    filesystem walk, so untracked OS/editor junk cannot mask or trip a hit."""
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z", "--", *trees],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return None
    if result.returncode != 0:
        return None
    return [rel for rel in result.stdout.split("\0") if rel.strip()]




def _build_basename_index(
    rels: list[str] | None = None,
) -> dict[str, list[Path]] | None:
    """Build a basename → [relative-paths] index from git-TRACKED files
    (`git ls-files`), NOT a raw `REPO_ROOT.rglob("*")` walk
    (`ci-guard-measure-then-bound`: an untracked artifact must not mask a
    dangling ref). Returns None if git is unavailable / not a work tree —
    the caller then SKIPs leniently (mirrors Check 63 / Check 69).
    Used for the §5.1 D4 candidate-path lookup.

    `rels` — an already-fetched `_git_tracked_relpaths()` result. A caller
    that needs the same tracked list for its OWN scope walk (Check 68,
    `check_dangling_file_refs`) passes it through, so the pair costs ONE
    `git ls-files` instead of two (`ci-check-runtime-compounding`: the
    second fetch is ~10.8 ms per invocation against the 10.0 s
    `RUN_CHECK_TOTAL_GENERAL_BUDGET_S`). Omitted, the index fetches its own
    list — the form Checks 40 and 43 use.

    Per §5.1 EXCLUDE list (with OQ-S1 expansion 2026-05-20):
      - `.git/` always skipped (pack-internal git state)
      - `maintenance-docs/archive/` (historical content with stale refs)
      - `test-fixtures/` (synthetic fixture content)
      - `scripts/tests/fixtures/` (per-script synthetic fixture trees)
      - `node_modules`-like dirs (defensive; not present at HEAD)
    """
    if rels is None:
        rels = _git_tracked_relpaths()
    if rels is None:
        return None
    index: dict[str, list[Path]] = {}
    for rel_str in rels:
        # Skip excluded paths.
        skip = False
        for excl in _CHECK_40_EXCLUDE_PARTS:
            if rel_str == excl or rel_str.startswith(excl + "/"):
                skip = True
                break
        if skip:
            continue
        rel = Path(rel_str)
        index.setdefault(rel.name, []).append(rel)
    return index




def _check_40_context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any Check-40 anchor phrase appears in the matched
    line or the ±_CHECK_40_ANCHOR_WINDOW surrounding lines.

    Parallel helper to `_context_has_anchor` (Check 37). Per §9.6, the
    coder may choose to refactor or to keep parallel; chose parallel
    here to avoid touching Check 37's code path for a non-Check-37 BD.
    """
    start = max(0, lineno - 1 - _CHECK_40_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _CHECK_40_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _CHECK_40_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False




def check_bare_pack_ops_refs() -> None:
    """Check 40 — pack-ops/ bare cross-reference scanner (BD-179 per
    ARCHITECTURE-BD-179.md §3-§8).

    Walks `pack-ops/*.md` and flags backtick-delimited filename refs that
    lack a directory qualifier and are not exempt. `pack-ops/BACKLOG.md`
    and `pack-ops/CHANGELOG.md` are excluded by basename: under the
    BD-203 no-mirror model these monoliths are deleted (the per-entry
    `/backlog/` + `/changelog/` trees are the SSOT), so once gone the
    glob never yields them and the exclusion is inert; while they still
    exist (during conversion) the exclusion keeps the scan off
    conversion-input content.
    qualifier and are not exempt per the allowlist / anchor-phrase /
    same-dir-legitimate mechanisms.

    Failure modes:
      - Bare ref with 0 candidate paths → "broken ref"
      - Bare ref with 1 candidate path → "qualify to <path>"
      - Bare ref with 2+ candidate paths → "qualify to one of <paths>"

    PASS notices:
      - Allowlist hit → "exempt: <rationale>"
      - Anchor-phrase hit → "anchor-phrase-exempt"
      - Same-dir-legit → "same-dir resolution"
    """
    print("\n── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──")
    pack_ops_dir = REPO_ROOT / "pack-ops"
    if not pack_ops_dir.is_dir():
        ok("pack-ops/ absent — skipping (lenient)")
        return

    # Build basename index ONCE per Check 40 invocation per §5.3.
    index = _build_basename_index()
    if index is None:
        ok("git unavailable (not a git work tree) — skipping (lenient)")
        return

    # Excluded basenames. BD-203 no-mirror model: BACKLOG.md /
    # CHANGELOG.md are the deleted monoliths (the `/backlog/` +
    # `/changelog/` per-entry trees are the SSOT); once deleted this set
    # never matches, and during conversion it keeps the scan off the
    # conversion-input monoliths. NOT "regenerated mirrors" — there is
    # no mirror.
    # DASHBOARD-SPEC-PACK.md is a verbatim USER-OWNED build spec committed
    # byte-faithfully; its bare `pack-help.sh` reference cannot be qualified
    # without violating byte-faithfulness (unlike a pack-authored doc the pack
    # keeps Check-40-clean itself), so the whole file is walk-excluded — sized
    # to EXACTLY the one un-remediable verbatim source. This walk does NOT
    # consult _iter_operating_docs()/_CHECK_OPERATING_DOC_EXEMPT, so the spec's
    # content-gate exemption (Checks 65/67/68/69) does NOT cover Check 40 — this
    # is the separate, parallel exclusion for the Check-40 surface.
    excluded_basenames = {"BACKLOG.md", "CHANGELOG.md", "DASHBOARD-SPEC-PACK.md"}

    any_failed = False
    files_walked = 0
    hits_allowlist = 0
    hits_anchor = 0
    hits_same_dir = 0
    hits_failed = 0

    for md_path in sorted(pack_ops_dir.glob("*.md")):
        if md_path.name in excluded_basenames:
            continue
        try:
            text = md_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        stripped_lines = _strip_code_blocks(text)
        rel_path = md_path.relative_to(REPO_ROOT)
        rel_dir = str(rel_path.parent).replace(os.sep, "/")

        for lineno, line in enumerate(stripped_lines, start=1):
            # Collect all bare-ref matches on this line (both regexes).
            matches: list[str] = []
            for m in _CHECK_40_BARE_REF_PATTERN.finditer(line):
                matches.append(m.group(1))
            for m in _CHECK_40_HYPERLINK_PATTERN.finditer(line):
                matches.append(m.group(1))
            if not matches:
                continue

            for basename in matches:
                # Tier 1: hardcoded allowlist.
                if basename in _CHECK_40_ALLOWLIST:
                    hits_allowlist += 1
                    continue
                # Tier 2: anchor-phrase exemption (±2-line window).
                if _check_40_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                # Tier 3: same-dir-legitimate per Phase 1 survey §7.1
                # implicit rule. If the basename has exactly one
                # candidate AND that candidate is in the same directory
                # as the referencing doc, the bareness is legitimate
                # (analogous to programming-language sibling-import
                # semantics).
                candidates = index.get(basename, [])
                if len(candidates) == 1:
                    candidate_dir = str(candidates[0].parent).replace(os.sep, "/")
                    if candidate_dir == rel_dir:
                        hits_same_dir += 1
                        continue

                # FAIL — emit triage per §5.1 D4 candidate-set size.
                if not candidates:
                    suggestion = (
                        "broken ref — no file with that basename exists "
                        "in the pack repo (excluding test-fixtures and "
                        "scripts/tests/fixtures synthetic trees)"
                    )
                elif len(candidates) == 1:
                    one = str(candidates[0]).replace(os.sep, "/")
                    suggestion = f"qualify to `{one}`"
                else:
                    paths = [str(c).replace(os.sep, "/") for c in candidates]
                    suggestion = (
                        "qualify to one of: " + ", ".join(f"`{p}`" for p in sorted(paths))
                    )
                fail(
                    f"{rel_path}:{lineno} — bare cross-reference "
                    f"`{basename}` (no directory qualifier). {suggestion}. "
                    f"Remediation: qualify the path OR add `{basename}` to "
                    f"`_CHECK_40_ALLOWLIST` in scripts/validate-pack.py with "
                    f"one-line rationale (per ARCHITECTURE-BD-179.md §6.5) "
                    f"OR wrap in a fenced code block if it is a shell/code "
                    f"example."
                )
                hits_failed += 1
                any_failed = True

    if not any_failed:
        ok(
            f"Check 40 — {files_walked} pack-ops/*.md file(s) walked; "
            f"zero unqualified bare cross-references "
            f"({hits_allowlist} allowlist-exempt + {hits_anchor} anchor-"
            f"phrase-exempt + {hits_same_dir} same-dir-legit hit(s) accepted)"
        )




# ── Check 43: project-side bare cross-reference scanner (BD-173 H.14) ──────
#
# Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1 (V11 leak-sweep
# prevention; class-test counterpart to Check 37's name-enumeration).
# Walks the canonical client-installed surface (`_iter_client_installed_files()`
# per Guardrail 3 §3.1) and flags bare backtick-delimited filename refs
# whose basename resolves into pack-only territory (`maintenance-docs/`
# or `pack-ops/` non-mirror) OR a non-client-installed `supporting-docs/`
# file. The class-test ("does this name resolve into pack-only
# territory?") is semantically different from Check 37's enumeration
# ("is this exact name in the deny-list?") — Check 43 catches future
# audit-vocabulary-gap leaks (e.g., `AUDIT-USER-CURATION.md`,
# `ARCHITECTURE-V3.md`) that the Check 37 enumeration would miss.
#
# Reuses Check 40 mechanism (basename index + code-block stripping +
# anchor-phrase aliases + bare/hyperlink regex). NO new regex. Different
# allowlist (project-side legitimate-resolution targets per §1.4).
#
# See `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
# §1.1-§1.12 for the verbatim contract.

# Check 43 — project-side bare-cross-reference scanner — hardcoded
# allowlist. Per §1.4 verbatim. Every entry maps to a file shipped to
# clients via `_CLIENT_INSTALLED_FILES` OR a name explicitly external/
# generated. Every entry carries a one-line rationale (Check 40 §6.5
# self-documenting allowlist convention).
_CHECK_43_ALLOWLIST: dict[str, str] = {
    # Project-side trinity (client-side resolution).
    "CLAUDE.md": "Project-side trinity at client root (also project-template/CLAUDE.md)",
    "AGENTS.md": "Project-side trinity at client root (also project-template/AGENTS.md)",
    "GEMINI.md": "Project-side trinity at client root (also project-template/GEMINI.md)",
    # Project-side README + LICENSE.
    "README.md": "Project-side or pack-side README (resolves at both)",
    "LICENSE.md": "Standard repo convention",
    "LICENSE": "Standard repo convention",
    # Pack-feedback cross-boundary product feature (PM chat writes here).
    "PACK-FEEDBACK.md": "Project-side cross-boundary feedback channel (docs/pack/)",
    # Project-side methodology / install docs (post-install at docs/pack/).
    "METHODOLOGY.md": "Project-side docs/pack/METHODOLOGY.md (client-installed)",
    "INSTALL-PROCEDURES.md": "Project-side docs/pack/INSTALL-PROCEDURES.md (client-installed)",
    "PM-CHAT.md": "Project-side docs/pack/PM-CHAT.md (client-installed orchestrator rules)",
    "PLATFORM-SKILLS.md": "Project-side docs/pack/PLATFORM-SKILLS.md (client-installed)",
    "OPTIONAL-FEATURES.md": "Project-side docs/pack/OPTIONAL-FEATURES.md (client-installed)",
    "HELP-FRAGMENT.md": "Project-side docs/pack/HELP-FRAGMENT.md (client-installed)",
    "SETUP-EXISTING.md": "Project-side docs/pack/SETUP-EXISTING.md (client-installed install doc)",
    # Per-entry skeleton filename PATTERNS (template placeholders, not real files).
    "BD-NNN.md": "Per-entry backlog filename pattern (template)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Per-entry tree sibling skeleton files (resolve same-dir within docs/project/<stream>/).
    "_rules.md": "Per-entry tree per-stream rules sibling (same-dir resolution)",
    "_intro.md": "Per-entry tree intro sibling (same-dir resolution)",
    "_index.md": "Per-entry tree ordering sibling (impl-plan; same-dir resolution)",
    # Project monolith basenames: under the no-mirror model these are NOT
    # regenerated mirrors — they are (a) the v10→v11 conversion-INPUT the
    # migrator reads, and (b) the bare-ref subject of Wave-D-pending agent
    # prompts / skills / trinity that BD-206 repoints to the per-entry
    # streams. Kept allowlisted as a client-resolvable basename until those
    # repoints land (ci-guard-measure-then-bound: sized to the live ref set).
    "BACKLOG.md": "Project-side conversion-input / Wave-D-pending bare-ref basename (no-mirror)",
    "CHANGELOG.md": "Project-side conversion-input / Wave-D-pending bare-ref basename (no-mirror)",
    "IMPLEMENTATION-PLAN.md": "Project-side conversion-input / Wave-D-pending bare-ref basename (no-mirror)",
    "STATUS.md": "Project-side STATUS.md (PM chat maintains)",
    "ARCHITECTURE.md": "Project-side docs/project/ARCHITECTURE.md (PM/architect maintains)",
    # Client /pm-dashboard runtime-output artifacts (the client renderer
    # pm-dashboard-render.py writes its OWN board into
    # docs/project/dashboard-approvals/ at build time). These generic
    # artifact basenames are the client's own runtime outputs — client-
    # resolvable — even though the only TRACKED copies at HEAD are the pack's
    # own pack-ops/dashboard-approvals/ files. Same client-generated class as
    # STATUS.md above (a basename that resolves client-side at runtime).
    "dashboard.html": "Client-side /pm-dashboard runtime output (docs/project/dashboard-approvals/dashboard.html)",
    "dashboard-shell.html": "Client-side /pm-dashboard spec-fingerprinted shell (docs/project/dashboard-approvals/dashboard-shell.html)",
    "dashboard-url.txt": "Client-side /pm-dashboard published-URL record (docs/project/dashboard-approvals/dashboard-url.txt)",
    # Generated / opt-in / external files.
    "tracker.toml": "Generated by `pack tracker init` (not in project repo at install)",
    "tracker.toml.example": "Project-side example shipped at client root",
    "id-map.json": "Generated tracker-mode metadata",
    "MEMORY.md": "Claude-Code memory cache (~/.claude/, external to project)",
    # Standard project scripts that resolve at client install.
    "agent-run.sh": "Project-side agent launcher at client root",
    # ── Option C absorption (BD-173 H.14 follow-up) — audit-vocabulary-gap
    # legitimates per H.14 IMPL-REPORT §7.2.2 Option A list. Per Pack Chat
    # triage (2026-05-24) Pack Chat user direction Option C hybrid:
    # allowlist legitimate audit-vocabulary-gap entries AND fix the
    # 5-6 real LEAK CLASS C catches. The entries below are basenames
    # the architect §1.4 spec did not anticipate but which are
    # ambiguous-by-design (generic basenames, agent prompt meta-refs),
    # template placeholders (generated by pm-chat), or legacy /
    # generated names (no real file at HEAD).
    # ── Template placeholders (generated by pm-chat self-prompt).
    "SETUP.md": "Template placeholder; generated by pm-chat self-prompt at install (no real file in pack repo)",
    "AGENT_KICKOFF.md": "Template placeholder; generated by pm-chat self-prompt at install (no real file in pack repo)",
    # ── Generic basenames (ambiguous-by-design at the meta-reference level).
    "SKILL.md": "Per-skill filename; ambiguous-by-design at the meta-reference level (~70 skills collide)",
    "config.toml": "Generic config basename; ambiguous (multiple candidate locations across CLIs)",
    "settings.json": "Generic config basename; ambiguous (xcode/vscode/CLI companion templates)",
    # ── Agent prompt meta-references (ambiguous-by-design; the basename exists
    #    in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity
    #    agent plugin bundle .agents-plugin/optiquity-agents/agents, and
    #    docs/pack/prompts). Basename-keyed; the value is documentation only.
    "coder.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "architect.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "reviewer.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "planner.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "tester.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "auditor.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "docs-researcher.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "auditor-architecture.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    # ── Per-entry skeleton variants (similar to phase-N.md / BD-NNN.md already allowlisted).
    "phase-N.M.md": "Per-entry implementation-plan filename pattern variant (sub-phase placeholder)",
    "phase-0.md": "Per-entry implementation-plan filename pattern variant (phase-zero placeholder)",
    "phase-NN.md": "Per-entry implementation-plan filename pattern variant (two-digit phase placeholder)",
    "phase-35.md": "Per-entry implementation-plan filename pattern variant (specific phase example)",
    "TD-001.md": "Per-entry tech-debt filename pattern; specific instance placeholder in docs",
    # ── Custom skill placeholder.
    "x-foo.md": "x-prefix custom skill placeholder example (template; not a real file)",
    # ── Legacy / generated filenames (no real file at HEAD; broken-ref-by-design).
    "report.md": "Generic agent report filename; no real file at HEAD (template / generated)",
    "PROMPT-TEMPLATES.md": "Legacy doc name; not in pack repo at HEAD (referenced for legacy continuity)",
    "FEATURES.md": "Generic feature-list basename; no real file at HEAD (template / placeholder)",
    "MIGRATION-v9-to-v10.md": "Legacy migration doc; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-v9-to-v10.sh": "Legacy migration script; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-vN-to-vM.sh": "Migrator framework filename pattern (placeholder per BD-119 architect doc)",
    # ── Audit-methodology teaching examples (illustrative content in skill docs).
    "user_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "order_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "inventory_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    # NOTE: proto self-imports are NOT allowlisted by basename. They are
    # exempted by the DURABLE resolve-within-tree rule
    # (`_check_43_proto_resolves_in_tree`, BD-195 C2 §2.2 Step-4): any
    # `.proto` reference whose basename resolves to an existing file under
    # `project-template/proto/` is legitimate project-side content
    # (gRPC/protobuf is a supported language with dedicated skill(s)). A
    # basename list would go stale as the proto tree grows or skills add
    # example protos; the resolve-within-tree predicate survives that. The
    # rule is bounded to in-tree imports only (`ci-guard-measure-then-bound`).
}



# Anchor-phrase reuse — Check 43 inherits Check 40's anchor-phrase set
# verbatim per §1.5. Aliases (rather than duplicates) so future anchor
# additions in Check 40 propagate. Implementation note: prefer aliasing
# over duplication; if a future maintainer needs to diverge, the alias
# is a one-line edit to a fresh tuple.
_CHECK_43_ANCHOR_PHRASES = _CHECK_40_ANCHOR_PHRASES  # alias; same set


_CHECK_43_ANCHOR_WINDOW = _CHECK_40_ANCHOR_WINDOW    # alias; 2



# Pack-internal target prefixes for the FAIL (pack-internal target)
# verdict per §1.7. A bare ref whose basename resolves into one of these
# directories (with the noted exception for the client-installed mirror)
# FAILs as a pack-internal cite.
_CHECK_43_PACK_INTERNAL_PREFIXES = ("maintenance-docs/", "pack-ops/")



# Qualified prefixes that are pack-internal when cited FROM a client-installed
# file. A client install has no `project-template/` directory — the tree under
# it IS the install — so such a path is dead at every install even though it
# resolves in the pack repo (which is why Check 68 never sees it).
#
# Deliberately NOT merged into `_CHECK_43_PACK_INTERNAL_PREFIXES`: that tuple
# ALSO feeds the bare-ref class test below, where `project-template/` would
# make every client-shipped basename a pack-internal target (measured: 130 new
# FAILures across 26 basenames).
_CHECK_43_SELF_TREE_PREFIXES = ("project-template/",)



# pack-ops/ files that ARE client-installed (excluded from the pack-
# internal-target FAIL because they resolve at client install time).
# Currently empty — no pack-ops/ file is a client-install source.
_CHECK_43_PACK_OPS_CLIENT_INSTALLED: tuple[str, ...] = ()



# ── JC-2 broadening (BD-195 C2 §2.2) ──────────────────────────────────────
# Four-axis broadening of the client-surface leak guard. See
# `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md`
# § "C2 — JC-2 client-surface leak-guard broadening" §2.2.
#
# (iii) Walk-extension broadening: Check 43's walk filter is the
#       `_CHECK_40_FILE_EXTS` set. The JC-2 broadening adds the
#       client-shipped config-example + proto extensions (`.example`
#       double-extension files like `config.toml.example` /
#       `.env.example`, and `.proto`) so the leak scanner inspects
#       `.codex/config.toml.example`, `.mcp.json.example`,
#       `.agents/mcp_config.json.example`, and the proto tree. Kept
#       Check-43-local
#       (NOT folded into `_CHECK_40_FILE_EXTS`) so Check 40's pack-ops/
#       walk + the shared bare-ref regexes are unchanged.
_CHECK_43_EXTRA_WALK_SUFFIXES = ("example", "proto")



# (i) Bare-prose pack-doc-basename inventory: basenames whose EVERY
#     repo location is under a pack-only top-level tree (`maintenance-docs/`
#     or `pack-ops/`), minus the deleted-monolith basenames and any basename on
#     `_CHECK_43_ALLOWLIST` (the curated client-resolvable set). Built
#     from the tree (NOT a hand-typed list) per
#     `ci-guard-measure-then-bound`. The "every
#     location pack-only" bound is the over-fire guard: a basename that
#     ALSO has a project-side / client-installed instance (e.g.
#     `ARCHITECTURE.md`, `README.md`, `IMPLEMENTATION-PLAN.md`) is NOT a
#     pack-only-doc and is excluded — only basenames that resolve
#     EXCLUSIVELY into pack-only territory (e.g.
#     `V10-CODEX-MCP-RESEARCH.md`, `MERGE-STRATEGY.md`) are targets. A
#     client surface that names one of these in NON-backtick prose (or
#     inside a qualified `docs/pack/<basename>` path the bare-ref regex's
#     `/`-exclusion misses) is a dead pointer.
_CHECK_43_PACK_ONLY_DOC_TREES = ("maintenance-docs", "pack-ops")



# (ii) commit-SHA-as-provenance: a `commit <7-40 hex>` provenance citation
#      on a client surface points at pack-repo git history the client
#      cannot resolve. Anchored to a `commit ` keyword to avoid matching
#      arbitrary hex tokens.
_CHECK_43_COMMIT_SHA_PATTERN = re.compile(r"\bcommit\s+[0-9a-f]{7,40}\b")



# JC-2 proto-validity rule (BD-195 C2 §2.2 Step-4): the shipped proto tree
# under this prefix. A proto reference whose basename resolves to an
# existing file WITHIN this tree is legitimate project-side content.
_CHECK_43_PROTO_TREE_PREFIX = "project-template/proto"




def _check_43_proto_resolves_in_tree(basename: str) -> bool:
    """Durable proto-validity rule (BD-195 C2 §2.2 Step-4).

    Return True iff `basename` is a `.proto` filename that resolves to an
    existing file WITHIN the shipped `project-template/proto/` tree. Such a
    reference is a legitimate proto self-import (gRPC/protobuf is a
    supported language with dedicated skill(s)) and is never a leak.

    This REPLACES the prior two hardcoded allowlist basenames
    (`common.proto`, `example_service.proto`) with a rule that survives the
    proto tree growing or skills adding example protos. It is bounded
    (`ci-guard-measure-then-bound`): it admits ONLY `.proto` basenames that
    actually resolve inside the proto tree — never an external/non-resolving
    proto path, never a pack-doc basename, never any other STRIP-class hit.
    A `google/protobuf/*` well-known import does NOT resolve in-tree and is
    therefore NOT admitted by this rule (it is an external import, out of
    scope for the leak guard).

    Defensive note: the current matcher tiers do not fire on proto imports
    at all (`.proto` is absent from `_CHECK_40_FILE_EXTS`, so the bare-ref /
    hyperlink regexes never produce a `.proto` basename), so this rule has
    no effect on the present fire-set. It exists so that any FUTURE
    matchable proto reference is correctly recognized as valid.
    """
    if not basename.endswith(".proto"):
        return False
    proto_root = REPO_ROOT / _CHECK_43_PROTO_TREE_PREFIX
    if not proto_root.is_dir():
        return False
    for cand in proto_root.rglob(basename):
        if cand.is_file():
            return True
    return False




def _build_pack_only_doc_basenames() -> set[str] | None:
    """Return the set of pack-only-doc basenames for the JC-2 bare-prose
    axis (i), measured from the git-TRACKED tree (`git ls-files`,
    `ci-guard-measure-then-bound`: never a raw `REPO_ROOT.rglob("*")` walk,
    so an untracked artifact under a pack-only tree cannot false-fire the
    bare-prose detector). Returns None if git is unavailable / not a work
    tree — the caller then SKIPs leniently (mirrors Check 63 / Check 69).

    A basename is a target iff EVERY repo file with that basename lives
    under a pack-only top-level tree (`_CHECK_43_PACK_ONLY_DOC_TREES`),
    minus: the deleted-monolith basenames (`BACKLOG.md` / `CHANGELOG.md`;
    no regenerated mirror under the no-mirror model) and any
    basename on `_CHECK_43_ALLOWLIST` (the curated client-resolvable set).
    The "every-location-pack-only" rule is the over-fire bound: basenames
    with a project-side / client-installed instance (`ARCHITECTURE.md`,
    `README.md`, `IMPLEMENTATION-PLAN.md`, …) are excluded; only
    exclusively-pack-only docs (`V10-CODEX-MCP-RESEARCH.md`,
    `MERGE-STRATEGY.md`) remain. `.git/` is
    skipped; the basename index's archive-exclusion does NOT apply here
    (archive docs ARE pack-only and must be catchable)."""
    rels = _git_tracked_relpaths()
    if rels is None:
        return None
    mirror_skip = {"BACKLOG.md", "CHANGELOG.md"}
    # Map basename -> set of top-level dirs it appears under.
    tops_by_basename: dict[str, set[str]] = {}
    for rel_str in rels:
        rel = Path(rel_str)
        parts = rel.parts
        if not parts or parts[0] == ".git":
            continue
        tops_by_basename.setdefault(rel.name, set()).add(parts[0])
    pack_only_trees = set(_CHECK_43_PACK_ONLY_DOC_TREES)
    out: set[str] = set()
    for basename, tops in tops_by_basename.items():
        if basename in mirror_skip:
            continue
        if basename in _CHECK_43_ALLOWLIST:
            continue
        if tops and tops <= pack_only_trees:
            out.add(basename)
    return out




# ── BD-199: Check 43 hot-path precompilation ─────────────────────────────
# Check 43's bare-prose tier formerly rebuilt a regex string and ran
# re.search PER (line × basename) — O(lines × 586 basenames) ≈ 9.4M
# re.compile cache-misses, ~355 s wall. The fix (ARCHITECTURE-BD-199-
# VALIDATE-PACK-PERF.md §2.1–§2.2) collapses the N per-basename patterns
# into ONE precompiled alternation, scanned ONCE per line, with a per-line
# basename dedupe to reproduce the prior "first match per distinct basename"
# fire-set EXACTLY. The two qualified-prefix patterns (§2.3 Lever C) are
# likewise hoisted from re.compile-in-loop to module-precompiled constants.


def _build_bare_prose_alternation(
    pack_only_doc_basenames: "set[str]",
) -> "re.Pattern[str] | None":
    """Build the single precompiled bare-prose alternation for Check 43.

    Semantically identical to the former per-basename pattern
    `(?<![A-Za-z0-9_.-]) + re.escape(basename) + (?![A-Za-z0-9_.-])`:
    the lookbehind/lookahead boundary classes are byte-copied, and the
    alternatives are exactly `re.escape(b)` for each `b` in the set.

    Correctness constraint (ARCHITECTURE-BD-199 §2.1): Python alternation
    is FIRST-alternative-wins, NOT longest-match, so the alternatives are
    sorted by DESCENDING LENGTH before joining. Longest-first guarantees
    the regex prefers the longest valid basename at any position, which —
    combined with the trailing boundary lookahead — reproduces the union
    of the 586 independent single-basename searches. Returns None when the
    set is empty (no detector to build; caller skips the tier).
    """
    if not pack_only_doc_basenames:
        return None
    ordered = sorted(pack_only_doc_basenames, key=lambda b: (-len(b), b))
    alternation = "|".join(re.escape(b) for b in ordered)
    return re.compile(
        r"(?<![A-Za-z0-9_.-])(?:" + alternation + r")(?![A-Za-z0-9_.-])"
    )




# Qualified pack-internal prefix detectors (§2.3 Lever C). Formerly
# re.compile'd per (line × prefix) inside the Check 43 line loop; hoisted
# to a module-precompiled (prefix -> compiled pattern) mapping. The pattern
# body is byte-identical to the former in-loop construction
# (`re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"`).
_CHECK_43_PACK_INTERNAL_PREFIX_PATTERNS = {
    prefix: re.compile(
        re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"
    )
    for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES
}


# Self-tree prefix detectors — same pattern body as the pack-internal
# detectors above, keyed off `_CHECK_43_SELF_TREE_PREFIXES`. Module-
# precompiled rather than built per (line x prefix) inside the line loop
# (`ci-check-runtime-compounding`).
_CHECK_43_SELF_TREE_PREFIX_PATTERNS = {
    prefix: re.compile(
        re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"
    )
    for prefix in _CHECK_43_SELF_TREE_PREFIXES
}




def check_project_side_bare_internal_refs() -> None:
    """Check 43 — project-side / client-installed bare cross-references
    to pack-internal files (V11 leak-sweep prevention; strategy §4.1).

    Walks the canonical client-installed surface
    (`_iter_client_installed_files()` per Guardrail 3 §3.1) and flags
    bare backtick-delimited filename refs whose basename resolves into
    pack-only territory (`maintenance-docs/` or `pack-ops/` non-mirror)
    or a non-client-installed `supporting-docs/` file.

    Reuses Check 40's mechanism (basename index + code-block stripping +
    anchor-phrase exemption + bare/hyperlink regex). Different from
    Check 40 in: (a) walked surface (project-side / client-installed
    instead of pack-ops/), (b) allowlist (project-side legitimate
    targets), (c) class-test FAIL semantic (resolves-into-pack-only
    instead of un-qualified candidate-suggestion).

    Failure modes:
      - FAIL (pack-internal target): basename resolves into
        `maintenance-docs/` OR `pack-ops/` (excluding any pack-ops/ file
        on `_CHECK_43_PACK_OPS_CLIENT_INSTALLED`, currently empty)
      - FAIL (pre-install-only `supporting-docs/`): basename resolves
        into `supporting-docs/<X>` AND `<X>` not in client-install set
      - FAIL (broken): 0 candidates AND not on allowlist AND no anchor
      - FAIL (ambiguous): 2+ candidates AND none is a client-installed
        legitimate target AND no same-dir match
      - FAIL (self-tree): a QUALIFIED `project-template/<X>` path on any
        walked file, where `<X>` ENDS IN A FILENAME WITH AN EXTENSION.
        There is no `project-template/` directory at a client install, so
        the pointer is dead there; the path DOES resolve in the pack
        repo, which is why the existence checks stay green on it. Keyed
        off `_CHECK_43_SELF_TREE_PREFIXES`, a separate tuple from
        `_CHECK_43_PACK_INTERNAL_PREFIXES` (see that constant for why
        merging them is wrong).
        BOUND (measured, not incidental): the matcher requires a dotted
        filename, so a bare `project-template/` or a bare-DIRECTORY
        reference (`project-template/skills/`) is OUT of its reach — 5
        occurrences matched vs 11 not matched on the current walk. The
        bound is deliberate; widening it needs a KEEP/STRIP census of
        those 11 first (`ci-guard-measure-then-bound`).

    PASS notices:
      - Allowlist hit → "exempt: <rationale>"
      - Anchor-phrase hit → "anchor-phrase-exempt"
      - Same-dir-legit → "same-dir resolution"
      - Client-installed pack-side resolution → "client-installed-exempt"
      - Self-provenance banner (`*Copied from: <self-path>*`, where the
        cited path EQUALS the citing file's own) → "self-provenance-banner"

    See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.1-§1.12 for the
    verbatim contract.
    """
    print("\n── Check 43: Project-side bare cross-reference scanner (BD-173) ──")

    # Build basename index ONCE per Check 43 invocation per §1.3
    # (same pattern as Check 40 §5.3). Reuses Check 40's _build_basename_index.
    index = _build_basename_index()
    if index is None:
        ok("git unavailable (not a git work tree) — skipping (lenient)")
        return

    # JC-2 axis (i): pack-only-doc basename set (built from the tree, not
    # a hand-list) for the bare-prose detector. BD-195 C2 §2.2 Step-3 (b).
    pack_only_doc_basenames = _build_pack_only_doc_basenames()
    if pack_only_doc_basenames is None:
        ok("git unavailable (not a git work tree) — skipping (lenient)")
        return
    # BD-199: collapse the 586 per-basename patterns into ONE precompiled
    # descending-length-sorted alternation, built ONCE per invocation (was
    # rebuilt+searched per line × basename → 9.4M re.compile cache-misses).
    bare_prose_pattern = _build_bare_prose_alternation(pack_only_doc_basenames)

    # Build the set of supporting-docs/ filenames that ARE installed at
    # client per §1.6. Parse via Guardrail 3's helper.
    installed_supporting_docs: set[str] = set()
    try:
        entries, _, _, _, _ = _parse_client_installed_files()
        for entry in entries:
            if entry.startswith("supporting-docs/"):
                installed_supporting_docs.add(entry[len("supporting-docs/"):])
    except Exception:
        # Defensive: if parse fails, the inventory check (Check 41)
        # will surface the issue; Check 43 falls back to empty set
        # (every supporting-docs/ cite will FAIL pre-install-only).
        pass

    any_failed = False
    files_walked = 0
    hits_allowlist = 0
    hits_anchor = 0
    hits_same_dir = 0
    hits_client_installed = 0
    hits_fenced = 0
    hits_self_provenance = 0

    walked_files = _iter_client_installed_files()

    for rel_path in walked_files:
        # Apply extension filter per §1.2 (matches Check 40's
        # _CHECK_40_FILE_EXTS) PLUS the JC-2 walk-extension broadening
        # (BD-195 C2 §2.2 axis iii: `.example` double-extension config
        # samples + `.proto`). Skip files whose extension is not in the
        # recognized set so we do not walk arbitrary binary content via
        # the basename regex.
        suffix = rel_path.suffix.lstrip(".")
        if (
            suffix not in _CHECK_40_FILE_EXTS.split("|")
            and suffix not in _CHECK_43_EXTRA_WALK_SUFFIXES
        ):
            continue
        full_path = REPO_ROOT / rel_path
        try:
            text = full_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        stripped_lines = _strip_code_blocks(text)
        rel_dir = str(rel_path.parent).replace(os.sep, "/")
        rel_posix = str(rel_path).replace(os.sep, "/")

        # Guardrail 2 (BD-173 H.13) fence skip-set — Check 43 inherits
        # the same per-line-fence semantics as Check 37 so deny-list-
        # teaching content (e.g., boundary-investigation/SKILL.md's
        # enumeration block) is exempt from class-test detection. Per
        # ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.12 — line 124
        # remediation note: "Catches only if line is OUTSIDE the
        # Guardrail 2 per-line fence."
        #
        # Note: imbalance is surfaced by Check 37; Check 43 silently
        # falls back to empty skip-set on imbalance so we do not
        # double-report the same failure.
        if _has_per_line_fence(rel_path):
            fence_skip = _build_fence_skip_lineset(text)
            if fence_skip is None:
                fence_skip = set()
        else:
            fence_skip = set()

        # Pre-compile a search across raw lines for qualified
        # supporting-docs/<X> path references (P1.10 LEAK CLASS C
        # — `supporting-docs/SETUP-NEW.md`, `supporting-docs/CLI-PM-SETUP.md`).
        # We scan the raw lines (post code-block stripping) for the
        # qualified path-prefix; bare-ref regex would not match the
        # qualified form because its first character class excludes `/`.
        for lineno, line in enumerate(stripped_lines, start=1):
            # Skip lines inside the Guardrail 2 fence (intentional
            # deny-list teaching content exempt per §1.12).
            if lineno in fence_skip:
                hits_fenced += 1
                continue
            # Qualified supporting-docs/<X> detection (pre-install-only FAIL).
            # Look for `supporting-docs/<filename>.<ext>` as a literal substring.
            import re as _re_local  # local alias for clarity
            for m in _re_local.finditer(
                r"supporting-docs/([A-Za-z0-9_-]+(?:\.[A-Za-z0-9]+)+)",
                line,
            ):
                fname = m.group(1)
                # JC-2 prefix tightening (BD-195 C2 §2.2 axis d): a
                # qualified `supporting-docs/<X>` path on a client surface
                # is a dead PATH regardless of whether <X> ships elsewhere
                # — there is no `supporting-docs/` directory at a client
                # install. Even an installed-elsewhere basename (e.g.
                # METHODOLOGY.md, which ships to docs/pack/) must be cited
                # by its client-resolvable `docs/pack/<X>` path, not the
                # pre-install `supporting-docs/` path. (Previously this
                # FAILed only when <X> was NOT in the installed set.)
                # Anchor-phrase exemption per §1.5 preserves intentional
                # pack-as-product cites; fenced lines are already skipped
                # above (disjoint from the client-surface prefix-hit set).
                if _check_43_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                installed_note = (
                    " (basename ships to a client-resolvable path; cite "
                    "that path, e.g. docs/pack/" + fname + ")"
                    if fname in installed_supporting_docs
                    else " (pre-install reference; not shipped to clients "
                    "via _CLIENT_INSTALLED_FILES inventory)"
                )
                fail(
                    f"{rel_path}:{lineno} — qualified reference "
                    f"`supporting-docs/{fname}` names the pre-install "
                    f"`supporting-docs/` directory, absent at a client "
                    f"install{installed_note}. Remediation: cite the "
                    f"client-resolvable `docs/pack/<X>` path OR drop the "
                    f"cite OR — if intentional pack-as-product cite — add "
                    f"an anchor phrase like \"in the pack repo\" within "
                    f"±2 lines."
                )
                any_failed = True

            # JC-2 axis (ii) — commit-SHA-as-provenance (BD-195 C2 §2.2).
            # A `commit <hex>` provenance citation on a client surface
            # points at pack-repo git history the client cannot resolve.
            if _CHECK_43_COMMIT_SHA_PATTERN.search(line):
                if not _check_43_context_has_anchor(stripped_lines, lineno):
                    fail(
                        f"{rel_path}:{lineno} — commit-SHA provenance "
                        f"citation (`commit <sha>`) names pack-repo git "
                        f"history not resolvable at a client install. "
                        f"Remediation: drop the commit-SHA provenance OR "
                        f"— if intentional pack-as-product cite — add an "
                        f"anchor phrase like \"in the pack repo\" within "
                        f"±2 lines."
                    )
                    any_failed = True
                else:
                    hits_anchor += 1

            # JC-2 axis (i) — bare-prose pack-doc-basename (BD-195 C2 §2.2).
            # A pack-only-doc basename named on a client surface in
            # NON-backtick prose (or inside a qualified `docs/pack/<X>`
            # path the bare-ref regex's `/`-exclusion misses) is a dead
            # pointer — the doc never ships to a client. The basename set
            # is built from the pack-only doc tree (NOT a hand-list) per
            # ci-guard-measure-then-bound. Match on word boundaries so a
            # basename inside a qualified path is caught; skip backtick-
            # isolated bare refs (those are handled by the bare-ref tier
            # below) to avoid double-flagging. Anchor-phrase exemption
            # preserves intentional pack-as-product cites.
            #
            # BD-199: ONE precompiled alternation (built once at function
            # entry) scanned per line via finditer, replacing the former
            # per-(line × basename) re.search loop. Each match's basename
            # is `m.group()`. Per-line dedupe by basename (`seen_on_line`)
            # reproduces the former "re.search = first occurrence, once per
            # distinct basename" fire-set EXACTLY — finditer yields ALL
            # occurrences (incl. the same basename twice on one line), so
            # the dedupe is the multiplicity-equivalence guarantee
            # (ARCHITECTURE-BD-199 §2.2). The boundary classes, backtick-
            # skip, anchor exemption, and fail() text are byte-identical to
            # the prior per-basename loop.
            if bare_prose_pattern is not None:
                seen_on_line: set[str] = set()
                for m in bare_prose_pattern.finditer(line):
                    doc_basename = m.group()
                    if doc_basename in seen_on_line:
                        continue
                    seen_on_line.add(doc_basename)
                    # Skip the backtick-isolated bare-ref form `X.md` — that
                    # is the existing bare-ref tier's surface (handled
                    # below); the bare-PROSE axis targets the non-backtick /
                    # qualified-path form the bare-ref regex misses.
                    start = m.start()
                    end = m.end()
                    if (
                        start > 0
                        and line[start - 1] == "`"
                        and end < len(line)
                        and line[end] == "`"
                    ):
                        continue
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — bare-prose reference to "
                        f"pack-only doc `{doc_basename}` (lives under "
                        f"maintenance-docs/ or pack-ops/; never shipped to a "
                        f"client). Remediation: drop the cite OR replace with "
                        f"a project-side SSOT (e.g., docs/pack/PM-CHAT.md) OR "
                        f"— if intentional pack-as-product cite — add an anchor "
                        f"phrase like \"in the pack repo\" within ±2 lines."
                    )
                    any_failed = True

            # Qualified pack-ops/<X> and maintenance-docs/<X> detection
            # (LEAK CLASS D in scripts/lib/detect.sh comments / LEAK
            # CLASS for any qualified pack-only path-prefix in project-
            # side prose). Bare-ref regex would not match these because
            # of the `/` separator; explicit substring detection.
            for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:
                # BD-199: pattern hoisted to a module-precompiled mapping
                # (was re.compile'd per line × prefix). Pattern body is
                # byte-identical to the former in-loop construction.
                pattern = _CHECK_43_PACK_INTERNAL_PREFIX_PATTERNS[prefix]
                for m in pattern.finditer(line):
                    rest = m.group(1)
                    full_target = prefix + rest
                    # Allow the client-installed pack-ops/ mirror.
                    if full_target in _CHECK_43_PACK_OPS_CLIENT_INSTALLED:
                        hits_client_installed += 1
                        continue
                    # Allow project-side trinity references to pack-ops/PACK-FEEDBACK
                    # via anchor-phrase context (handled by the anchor scan below).
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — qualified reference "
                        f"`{full_target}` to pack-internal target "
                        f"(pack-only — not at client install). Remediation: "
                        f"drop the cite OR replace with a project-side SSOT "
                        f"(e.g., docs/pack/PM-CHAT.md for orchestration rules) "
                        f"OR — if intentional pack-as-product cite — add an "
                        f"anchor phrase like \"in the pack repo\" within "
                        f"±2 lines."
                    )
                    any_failed = True

            # Qualified project-template/<X> detection (BD-288). A client
            # install has no `project-template/` directory, so such a path
            # is dead at every install; it stays invisible to Check 68
            # because it DOES resolve in the pack repo.
            #
            # The leg runs on the WHOLE walk with no citer scoping: Check
            # 43's walk IS the client-installed surface, so every walked
            # file is one where a `project-template/...` path is dead.
            # Scoping it to citers under `project-template/` would drop the
            # occurrences in the two client-installed `supporting-docs/`
            # files (measured: 3 of 9).
            #
            # BOUND: the pattern requires the prefix to be followed by a
            # path ENDING IN A DOTTED FILENAME, so a bare
            # `project-template/` or a bare-DIRECTORY reference is NOT
            # reached (measured on the current walk: 5 matched, 11 not).
            # That is deliberate — widening it needs a KEEP/STRIP census
            # of those 11 first (`ci-guard-measure-then-bound`), since
            # they are a mixed population (some anchor-cleared, some
            # deny-list teaching content, some genuine dead pointers).
            for prefix in _CHECK_43_SELF_TREE_PREFIXES:
                pattern = _CHECK_43_SELF_TREE_PREFIX_PATTERNS[prefix]
                for m in pattern.finditer(line):
                    full_target = prefix + m.group(1)
                    # Self-provenance banner: `*Copied from: <self-path>*`.
                    # Equality with the citing file's own repo-relative
                    # path means the reference is source attribution, not
                    # an actionable pointer, and it stays accurate at a
                    # client install (it names where the file came FROM).
                    if full_target == rel_posix:
                        hits_self_provenance += 1
                        continue
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — qualified file reference "
                        f"`{full_target}` names the pack-repo storage path "
                        f"of a client-installed file; there is no "
                        f"`project-template/` directory at a client "
                        f"install, so the pointer is dead there. "
                        f"Remediation: cite the client-resolvable path "
                        f"(drop the `{prefix}` prefix) OR drop the cite "
                        f"OR — if intentional pack-as-product cite — add "
                        f"an anchor phrase like \"in the pack repo\" "
                        f"within ±2 lines."
                    )
                    any_failed = True

            # Bare-ref matches (P1 + P2 + P3 + P5) reuse Check 40
            # regex patterns per §1.3 (NO new regex).
            matches: list[str] = []
            for m in _CHECK_40_BARE_REF_PATTERN.finditer(line):
                matches.append(m.group(1))
            for m in _CHECK_40_HYPERLINK_PATTERN.finditer(line):
                matches.append(m.group(1))
            if not matches:
                continue

            for basename in matches:
                # Tier 1: hardcoded allowlist (basename-keyed per §1.4).
                if basename in _CHECK_43_ALLOWLIST:
                    hits_allowlist += 1
                    continue
                # Tier 1b: durable proto-validity rule (BD-195 C2 §2.2
                # Step-4). A `.proto` basename that resolves WITHIN
                # `project-template/proto/` is a legitimate proto
                # self-import — never a leak. Bounded to resolve-in-tree
                # imports only (`ci-guard-measure-then-bound`); replaces the
                # prior two hardcoded proto basenames so the rule survives
                # the proto tree growing.
                if _check_43_proto_resolves_in_tree(basename):
                    hits_allowlist += 1
                    continue
                # Tier 2: anchor-phrase exemption (±2-line window per §1.5).
                if _check_43_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                # Tier 3: same-dir-legitimate per Check 40 §7.1 pattern.
                # If the basename has exactly one candidate AND that
                # candidate is in the same directory as the referencing
                # doc, the bareness is legitimate (sibling-import
                # semantics).
                candidates = index.get(basename, [])
                if len(candidates) == 1:
                    candidate_dir = str(candidates[0].parent).replace(os.sep, "/")
                    if candidate_dir == rel_dir:
                        hits_same_dir += 1
                        continue

                # Class-test FAIL: does the basename resolve into pack-
                # only territory (`maintenance-docs/` or `pack-ops/`
                # excluding the client-installed mirror)?
                pack_internal_candidates = []
                for cand in candidates:
                    cand_str = str(cand).replace(os.sep, "/")
                    if cand_str in _CHECK_43_PACK_OPS_CLIENT_INSTALLED:
                        # Resolves to a client-installed file — legitimate.
                        continue
                    for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:
                        if cand_str.startswith(prefix):
                            pack_internal_candidates.append(cand_str)
                            break

                if pack_internal_candidates:
                    targets = ", ".join(f"`{t}`" for t in sorted(pack_internal_candidates))
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` resolves to pack-internal target "
                        f"{targets} (pack-only — not at client install). "
                        f"Remediation: drop the cite OR replace with a "
                        f"project-side SSOT (e.g., docs/pack/PM-CHAT.md "
                        f"for orchestration rules) OR — if intentional "
                        f"pack-as-product cite — add an anchor phrase like "
                        f"\"in the pack repo\" within ±2 lines OR add "
                        f"`{basename}` to `_CHECK_43_ALLOWLIST` in "
                        f"scripts/validate-pack.py with one-line rationale."
                    )
                    any_failed = True
                    continue

                # supporting-docs/<X> resolution where <X> not in
                # client-install set — FAIL pre-install-only.
                supporting_candidates = []
                for cand in candidates:
                    cand_str = str(cand).replace(os.sep, "/")
                    if cand_str.startswith("supporting-docs/"):
                        sd_name = cand_str[len("supporting-docs/"):]
                        if sd_name not in installed_supporting_docs:
                            supporting_candidates.append(cand_str)

                if supporting_candidates:
                    targets = ", ".join(f"`{t}`" for t in sorted(supporting_candidates))
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` resolves to {targets} (pre-install "
                        f"reference; not shipped to clients via "
                        f"_CLIENT_INSTALLED_FILES inventory). Remediation: "
                        f"drop the cite OR replace with a project-side SSOT."
                    )
                    any_failed = True
                    continue

                # No candidates AND not on allowlist AND no anchor → broken.
                if not candidates:
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` — broken ref (no file with that "
                        f"basename exists in the pack repo, excluding "
                        f"test-fixtures and scripts/tests/fixtures synthetic "
                        f"trees). Remediation: qualify the path, fix the "
                        f"typo, OR remove the reference."
                    )
                    any_failed = True
                    continue

                # Ambiguous: 2+ candidates, none of which is pack-internal,
                # none in supporting-docs/<X> non-installed, no same-dir
                # match. This is a legitimate-resolution ambiguity rather
                # than a pack-only leak — but still fails because the
                # bare cite resolves to multiple candidates none of
                # which is on the allowlist.
                if len(candidates) >= 2:
                    paths = [str(c).replace(os.sep, "/") for c in candidates]
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` is ambiguous (resolves to multiple "
                        f"non-allowlisted candidates). Remediation: "
                        f"qualify to one of: "
                        + ", ".join(f"`{p}`" for p in sorted(paths))
                        + f" OR add `{basename}` to `_CHECK_43_ALLOWLIST` "
                        f"in scripts/validate-pack.py with one-line rationale."
                    )
                    any_failed = True
                    continue

                # Single candidate that is NOT pack-internal AND NOT
                # supporting-docs/<X> non-installed AND NOT same-dir —
                # this is a legitimate cross-directory project-side
                # reference (e.g., a docs/pack/ → docs/project/ cite).
                # Accept as client-installed-exempt.
                hits_client_installed += 1

    if not any_failed:
        ok(
            f"Check 43 — {files_walked} project-side / client-installed "
            f"file(s) walked; zero pack-internal bare cross-references "
            f"({hits_allowlist} allowlist-exempt + {hits_anchor} anchor-"
            f"phrase-exempt + {hits_same_dir} same-dir-legit + "
            f"{hits_client_installed} client-installed-legit + "
            f"{hits_self_provenance} self-provenance-banner + "
            f"{hits_fenced} fenced-line(s) accepted)"
        )




def _check_43_context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any Check-43 anchor phrase appears in the matched
    line or the ±_CHECK_43_ANCHOR_WINDOW surrounding lines.

    Parallel helper to `_check_40_context_has_anchor` (Check 40); uses
    the aliased anchor-phrase set per §1.5. Kept as a separate function
    to allow future divergence without touching Check 40's code path.
    """
    start = max(0, lineno - 1 - _CHECK_43_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _CHECK_43_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _CHECK_43_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False




# ── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ───
#
# Per ARCHITECTURE-BD-176.md §5.3 (forward-referenced from BD-176 D4
# deferral; landed in BD-180 per LOGICAL-FIT criterion). The
# `_CLIENT_INSTALLED_FILES_START` / `_CLIENT_INSTALLED_FILES_END` comment
# block in `scripts/init-project.sh` is an authoritative inventory of
# files this script installs to clients. Check 41 enforces the
# discoverability contract:
#   (a) START + END markers each appear exactly once,
#   (b) the block has at least one entry line,
#   (c) every entry's `pack_relpath` exists at HEAD,
#   (d) every `cmd_update` `pack_relpath` is listed in the block.
#
# (d) is the load-bearing assertion: it prevents drift between the
# self-documenting list and the actual `cmd_update` array — an actor
# adding a cmd_update entry without updating the list trips this check.
#
# Exemption allowlist (empty by default): inventory entries whose source
# intentionally lives outside repo HEAD. Surface-over-silently-exempt:
# when in doubt, leave OUT and let Check 41 FAIL.
_CHECK_41_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD per BD-180 close: every entry in the
    # `_CLIENT_INSTALLED_FILES_START`/`_END` block resolves to a real
    # source file. Add entries here only when the inventory references
    # a path that intentionally does not exist at HEAD.
}



# Inventory rows that ship via a runtime-basename directory GLOB inside their
# stage function (name=$(basename "$f")/"$form"), so the literal filename is
# computed at runtime and legitimately does NOT appear as a per-file copy
# literal. Sized to EXACTLY the 8 measured glob-shipped rows (3 S11 issue forms
# + 5 S6 docs/pack/*.md). A per-file omission is structurally impossible for a
# directory glob.
_CHECK_41_GLOB_LIST_EXEMPT: frozenset[str] = frozenset({
    "project-template/.github/ISSUE_TEMPLATE/work-item.yml",
    "project-template/.github/ISSUE_TEMPLATE/inbound.yml",
    "project-template/.github/ISSUE_TEMPLATE/config.yml",
    "project-template/docs/pack/OPTIONAL-FEATURES.md",
    "project-template/docs/pack/PACK-FEEDBACK.md",
    "project-template/docs/pack/PLATFORM-SKILLS.md",
    "project-template/docs/pack/PM-CHAT.md",
    # BD-257 B1: the client mode-subsystem behavior SSOT; ships via the
    # S6 docs/pack/*.md directory glob, same as its siblings above.
    "project-template/docs/pack/PM-OPERATING-MODES.md",
    # BD-257 B3: the client /pm-dashboard build spec; ships via the same
    # S6 docs/pack/*.md directory glob, not a per-file copy line.
    "project-template/docs/pack/PM-DASHBOARD-SPEC.md",
})


# Stages whose copy mechanism is a FIXED-LIST loop (loop var is the relpath/dest;
# S3 config list, S7 trinity list). A row tagged ONLY with these stages ships
# via a literal list element, not a hand-enumerated per-file copy that could be
# silently dropped — exempt from the per-file copy-site assertion.
_CHECK_41_LIST_LOOP_STAGES: frozenset[str] = frozenset({"S3", "S7"})


# Per-stage (function name, END sentinel) for the stages that host a guarded
# hand-enumerated KEEP row. The sentinel lives AFTER the last copy site; if the
# body-capture regex truncates (a future col-0 `}` inside the function), the
# sentinel is absent from the captured body -> clause (e) emits a diagnostic
# FAIL instead of a silent short body. Extend when a NEW stage hosts a KEEP row.
_CHECK_41_STAGE_SENTINELS: dict[str, tuple[str, str]] = {
    "S5":  ("stage_s5_scripts",          "agent-run.sh missing or not executable"),
    "S6":  ("stage_s6_docs_pack",        "blast_radius_sweep"),
    "S11": ("stage_s11_v11_artifacts",   "per_entry_regenerate_toc"),
}


# Copy-verb matcher: a non-comment stage line that performs a real copy. The
# basename signal keys on THIS (not bare basename presence) so a deletion of the
# copy line is caught even when the basename survives on an `if [[ -f ]]` guard
# or a warn/fail_stage message line.
_CHECK_41_COPY_VERB = re.compile(
    r'(^|\s)(cp\b|existing_classifier_copy\b)|"\$copy_fn"|\$copy_fn\b'
)

# A LITERAL pack-source operand on a copy-verb line, e.g.
# `cp "$PACK/project-template/agent-run.sh" ...`. Clause (g) uses it to walk
# copy sites BACK to inventory rows. Deliberately literal-only: a loop variable
# (`cp "$f" ...`) names no path here and a composed assignment is not a copy
# line at all, so both fall out without an exemption list. The captured group
# is the path relative to `project-template/`; the clause then keeps only the
# operands that resolve to a real FILE, which is what excludes the directory
# operand of the fixed-list loop (`"$PACK/project-template/scripts"`).
_CHECK_41_PACK_SRC_LITERAL = re.compile(
    r'\$PACK/project-template/([A-Za-z0-9._][A-Za-z0-9._/-]*)'
)


# Map-level `[class:...]` values that are legitimate WITHOUT a
# `customization_preserve()` dispatch arm. Exactly one: `self`, the
# self-classify sentinel, which `install-map.sh` `_install_map_resolved`
# converts to an EMPTY class so the copy site passes no class argument and
# `customization_preserve` falls through to `customization_classify`. Sized to
# the sentinel and nothing else — every other value must name a real arm.
_CHECK_41_CLASS_SENTINELS: frozenset[str] = frozenset({"self"})




def _parse_client_installed_files() -> tuple[list[str], int, int, bool, bool]:
    """Parse `_CLIENT_INSTALLED_FILES` block from `scripts/init-project.sh`.

    Returns `(entries, start_count, end_count, regex_matched, body_has_content)`:
      - `entries`: list of `pack_relpath` strings extracted from each
        entry line between START and END markers. Empty list if either
        marker is not present exactly once OR the regex body-extraction
        fails OR the body contains no parseable `->` entries.
      - `start_count`: integer count of `_CLIENT_INSTALLED_FILES_START`
        marker occurrences in the file. Caller enforces == 1.
      - `end_count`: integer count of `_CLIENT_INSTALLED_FILES_END`
        marker occurrences in the file. Caller enforces == 1.
      - `regex_matched`: True if the body-extraction regex
        `START\\s*\\n(.+?)\\n[^\\n]*END` successfully captured a block
        body. False if regex failed (e.g., END appears textually before
        START, START+END on the same line, no body between adjacent
        marker lines, or unusual whitespace prevents body capture).
        When markers are not exactly-once, `regex_matched` is False by
        short-circuit (the caller short-circuits on the marker check
        before consulting this field).
      - `body_has_content`: True iff the regex matched AND the captured
        body contains at least one non-empty, non-whitespace-only line.
        False when regex failed (no body to inspect) OR when regex
        matched but the body is whitespace-only.

    The caller uses the `(regex_matched, body_has_content, entries)`
    triple to distinguish three SHOULD-2 disambiguation cases:
      (i)   `regex_matched=False`: regex-shape-mismatch (markers exist
            exactly once but body capture failed).
      (ii)  `regex_matched=True`, `body_has_content=True`, `entries=[]`:
            regex-shape-mismatch within the entry-line shape (body has
            content but no line matches `#   <pack>  ->  <proj>`).
      (iii) `regex_matched=True`, `body_has_content=False`, `entries=[]`:
            genuinely-empty inventory (body is whitespace-only) —
            preserves pre-BD-180 "no parseable entries" diagnostic.

    Entry line format (one per line, between START/END):
      `#   <pack_relpath>  ->  <project_relpath>  [stage:<copy-site ids>]`

    Comment-only lines (e.g., header context) between START and END are
    skipped (must not contain `->`); empty lines and full-comment lines
    without `->` are ignored.

    Exactly-once contract: both markers MUST appear exactly once each.
    The header docstring for Check 41 promises `(a) START + END markers
    each appear exactly once`; this function enforces that contract by
    returning the raw counts so the caller can emit specific
    `"expected exactly one ..., found N"` failure messages and the
    validator FAILs rather than silently swallowing duplicate markers
    (the failure mode the exactly-once contract is meant to catch).
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return ([], 0, 0, False, False)
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_FILES_START"
    end_marker = "_CLIENT_INSTALLED_FILES_END"
    start_count = text.count(start_marker)
    end_count = text.count(end_marker)
    # Exactly-once contract: short-circuit if either count != 1.
    # Caller emits specific "expected exactly one, found N" failure.
    if start_count != 1 or end_count != 1:
        return ([], start_count, end_count, False, False)
    # Extract block body between START and END markers. The non-greedy
    # `(.+?)\n[^\n]*` capture stops at the END-marker line.
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text,
        re.DOTALL,
    )
    if not m:
        # Markers exist exactly once each, but the regex failed to
        # capture a body — e.g., END appears textually before START, or
        # START + END on the same line, or unusual whitespace (e.g.,
        # truly-empty body between adjacent marker lines also lands
        # here because the `.+?` capture requires at least one char).
        # Signal to caller via regex_matched=False so the caller can
        # emit the regex-shape-mismatch diagnostic.
        return ([], start_count, end_count, False, False)
    body = m.group(1)
    body_has_content = any(line.strip() for line in body.splitlines())
    entries: list[str] = []
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped or not stripped.startswith("#"):
            continue
        # Remove the leading `#` and surrounding whitespace.
        content = stripped.lstrip("#").strip()
        if "->" not in content:
            continue
        # Format: `<pack_relpath>  ->  <project_relpath>  [stage:...]`
        pack_rel = content.split("->", 1)[0].strip()
        if pack_rel:
            entries.append(pack_rel)
    return (entries, start_count, end_count, True, body_has_content)




def _parse_client_installed_file_stages() -> dict[str, set[str]]:
    """Map each `_CLIENT_INSTALLED_FILES` pack_relpath -> its `[stage:...]` set.

    Sibling of `_parse_client_installed_files()` (whose 5-tuple arity is
    UNCHANGED and whose unpack sites stay intact). Check 41 clause (e)
    consumes this map to verify each hand-enumerated row has a copy site.
    Returns {} if init-project.sh is absent or markers are not exactly-once
    (lenient — clause (e) skips when empty).
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return {}
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_FILES_START"
    end_marker = "_CLIENT_INSTALLED_FILES_END"
    if text.count(start_marker) != 1 or text.count(end_marker) != 1:
        return {}
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text, re.DOTALL,
    )
    if not m:
        return {}
    out: dict[str, set[str]] = {}
    for line in m.group(1).splitlines():
        s = line.strip()
        if not s.startswith("#"):
            continue
        content = s.lstrip("#").strip()
        if "->" not in content:
            continue
        pack_rel = content.split("->", 1)[0].strip()
        if not pack_rel:
            continue
        sm = re.search(r"\[stage:([^\]]*)\]", content)
        stages = (
            {t.strip() for t in sm.group(1).split(",") if t.strip()}
            if sm else set()
        )
        out[pack_rel] = stages
    return out


def _parse_client_installed_file_classes() -> dict[str, str]:
    """Map each `_CLIENT_INSTALLED_FILES` pack_relpath -> its `[class:...]` value.

    Sibling of `_parse_client_installed_file_stages()`, walking the same block
    with the same self-contained second parse; rows that omit the operand are
    absent from the map (omission is the self-classify form, not a value).
    Check 41 clause (f) consumes it. Returns {} on the same lenient conditions.
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return {}
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_FILES_START"
    end_marker = "_CLIENT_INSTALLED_FILES_END"
    if text.count(start_marker) != 1 or text.count(end_marker) != 1:
        return {}
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text, re.DOTALL,
    )
    if not m:
        return {}
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        s = line.strip()
        if not s.startswith("#"):
            continue
        content = s.lstrip("#").strip()
        if "->" not in content:
            continue
        pack_rel = content.split("->", 1)[0].strip()
        if not pack_rel:
            continue
        cm = re.search(r"\[class:([^\]]*)\]", content)
        if cm:
            out[pack_rel] = cm.group(1).strip()
    return out


def _customization_preserve_classes() -> set[str]:
    """The class vocabulary that actually DISPATCHES, read from its own source.

    Derived from the `case "$class" in` arms of `customization_preserve()` in
    `scripts/lib/customization-preserve.sh` — never a second hand-maintained
    copy of the token list, which would be a second SSOT free to drift from the
    dispatch it claims to describe.

    Returns set() when the library or the case block cannot be read, which
    makes clause (f) skip rather than fail (a synthetic scaffold legitimately
    ships no library).
    """
    lib = REPO_ROOT / "scripts" / "lib" / "customization-preserve.sh"
    if not lib.is_file():
        return set()
    text = lib.read_text()
    fn = re.search(
        r"\ncustomization_preserve\(\)\s*\{\n(.*?)\n^\}$",
        text, re.DOTALL | re.MULTILINE,
    )
    if not fn:
        return set()
    cm = re.search(r'case\s+"\$class"\s+in\n(.*?)\n\s*esac', fn.group(1), re.DOTALL)
    if not cm:
        return set()
    vocab: set[str] = set()
    for arm in re.findall(
        r"^\s*([a-z0-9-]+(?:\|[a-z0-9-]+)*)\)\s*$", cm.group(1), re.MULTILINE
    ):
        vocab |= set(arm.split("|"))
    return vocab


def _install_glob_matches(pattern: str, candidate: str) -> bool:
    """True iff `candidate` (a repo-relative posix path) matches an install-map
    GLOB-block source `pattern`.

    `*` matches within ONE path segment only — it never crosses `/`. That is
    the shell-glob semantics the copy sites use, and it is deliberately
    stricter than `fnmatch`, whose `*` DOES cross `/` and would silently widen
    every family row to its whole subtree.
    """
    rx = "".join(
        "[^/]*" if ch == "*" else re.escape(ch) for ch in pattern
    )
    return re.fullmatch(rx, candidate) is not None


def _parse_client_installed_globs() -> list[tuple[str, str, set[str], str]]:
    """Parse the install map's GLOB block from `scripts/init-project.sh`.

    Returns a list of `(source_pattern, dest_pattern, stages, cls)` tuples,
    one per row, in declaration order. `dest_pattern` keeps its `{a,b,c}`
    fan-out group UNEXPANDED — expansion is the consumer's job.

    A SEPARATE parser from `_parse_client_installed_files()`, whose 5-tuple
    arity and unpack sites are untouched. The glob block is deliberately NOT
    fed to `_iter_client_installed_files()`: a pattern is not a file, and
    admitting one there would put a non-existent path into the walked set.

    Returns [] if init-project.sh is absent or the GLOB markers are not
    exactly-once (lenient — the caller then sees no family rows).
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return []
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_GLOBS_START"
    end_marker = "_CLIENT_INSTALLED_GLOBS_END"
    if text.count(start_marker) != 1 or text.count(end_marker) != 1:
        return []
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text, re.DOTALL,
    )
    if not m:
        return []
    rows: list[tuple[str, str, set[str], str]] = []
    for line in m.group(1).splitlines():
        s = line.strip()
        if not s.startswith("#"):
            continue
        content = s.lstrip("#").strip()
        if "->" not in content:
            continue
        src, rest = content.split("->", 1)
        src = src.strip()
        if not src:
            continue
        sm = re.search(r"\[stage:([^\]]*)\]", rest)
        stages = (
            {t.strip() for t in sm.group(1).split(",") if t.strip()}
            if sm else set()
        )
        cm = re.search(r"\[class:([^\]]*)\]", rest)
        cls = cm.group(1).strip() if cm else ""
        # Same all-operand strip as the explicit-row reverse map: a
        # stage-only strip would leave `[class:...]` glued to the DEST.
        dest = re.sub(r"\[[^\]]*\]", "", rest).strip()
        if dest:
            rows.append((src, dest, stages, cls))
    return rows


def _client_install_dest_to_source() -> dict[str, str]:
    """Reverse the `_CLIENT_INSTALLED_FILES` inventory: project_relpath ->
    pack_relpath.

    Sibling of `_parse_client_installed_files()` (whose 5-tuple arity is
    UNCHANGED and whose unpack sites stay intact) and of
    `_parse_client_installed_file_stages()`, which solves the same
    different-column problem with the same self-contained second parse.
    Check 68 (`check_dangling_file_refs`, leg B) consumes this to resolve a
    reference written in the CLIENT's post-install path form against the
    pack-storage path it is copied FROM — a reference that resolves at a
    client install but has no pack-repo file at its literal path.
    ALL bracketed operands (`[stage:...]`, `[class:...]`, any future operand)
    are stripped from the DEST column; a stage-only strip would leave a
    trailing operand glued to the path and silently void leg B.
    Returns {} if init-project.sh is absent or the markers are not
    exactly-once (lenient — leg B then resolves nothing and the ref falls
    through to the anchor window / allowlist / FAIL).
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return {}
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_FILES_START"
    end_marker = "_CLIENT_INSTALLED_FILES_END"
    if text.count(start_marker) != 1 or text.count(end_marker) != 1:
        return {}
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text, re.DOTALL,
    )
    if not m:
        return {}
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        s = line.strip()
        if not s.startswith("#"):
            continue
        content = s.lstrip("#").strip()
        if "->" not in content:
            continue
        pack_rel, rest = content.split("->", 1)
        pack_rel = pack_rel.strip()
        # Strip ALL bracketed operands, not only `[stage:...]`. A row carries
        # `[stage:...]` AND `[class:...]`; a stage-only strip leaves the class
        # operand glued to the DEST, and the reverse lookup then never matches
        # a real client path.
        proj_rel = re.sub(r"\[[^\]]*\]", "", rest).strip()
        if pack_rel and proj_rel:
            out[proj_rel] = pack_rel
    return out




def check_client_installed_files() -> None:
    """Check 41 — _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G).

    Verifies the install map's explicit block in `scripts/init-project.sh`
    is well-formed, every row maps to a real file at HEAD, every
    hand-enumerated row has a fresh-install copy site, and every declared
    `[class:...]` names a class that really dispatches (clause (f), which reads
    the vocabulary from `customization_preserve()` rather than restating it).

    There is no `cmd_update`-is-named-in-the-inventory clause. With ONE
    declaration, the `cmd_update` axis IS a subset of the map, so such a
    clause would test `map ⊆ map` — a tautology with no load-bearing
    backing. Coverage of the `cmd_update` axis is Check 39's job.

    Allowlist: `_CHECK_41_EXEMPTIONS` (default: empty) admits inventory
    entries whose source intentionally lives outside repo HEAD.

    Lenient mode: if `scripts/init-project.sh` is absent (unlikely;
    REPO_ROOT issue) the check skips with a notice.
    """
    print("\n── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──")
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return

    entries, start_count, end_count, regex_matched, body_has_content = (
        _parse_client_installed_files()
    )

    # Exactly-once marker contract (BD-180 SHOULD-1 hardening). Distinct
    # diagnostics for missing-marker (count 0) vs duplicate-marker
    # (count >= 2) so a future maintainer who copy-pastes the inventory
    # block during a refactor sees a clear "found N" failure rather
    # than silent first-marker-wins behaviour.
    if start_count != 1 or end_count != 1:
        marker_errors: list[str] = []
        if start_count == 0:
            marker_errors.append(
                "missing `_CLIENT_INSTALLED_FILES_START` marker in "
                "scripts/init-project.sh (found 0; expected exactly 1)"
            )
        elif start_count > 1:
            marker_errors.append(
                f"duplicate `_CLIENT_INSTALLED_FILES_START` marker in "
                f"scripts/init-project.sh (found {start_count}; "
                f"expected exactly 1)"
            )
        if end_count == 0:
            marker_errors.append(
                "missing `_CLIENT_INSTALLED_FILES_END` marker in "
                "scripts/init-project.sh (found 0; expected exactly 1)"
            )
        elif end_count > 1:
            marker_errors.append(
                f"duplicate `_CLIENT_INSTALLED_FILES_END` marker in "
                f"scripts/init-project.sh (found {end_count}; "
                f"expected exactly 1)"
            )
        fail(
            "self-documenting list marker contract violated: "
            + "; ".join(marker_errors)
            + ". The block must be delimited by exactly one "
            "`_CLIENT_INSTALLED_FILES_START` marker and exactly one "
            "`_CLIENT_INSTALLED_FILES_END` marker per ARCHITECTURE-BD-176.md "
            "§5.3 / BD-180 observation G. Remove any duplicate markers or "
            "add the missing marker(s)."
        )
        return

    # Markers are exactly-once; disambiguate the empty-entries failure
    # modes (BD-180 SHOULD-2 hardening). Three distinct cases per
    # parser-output triple `(regex_matched, body_has_content, entries)`:
    #   (i)   `regex_matched=False`: markers exist exactly once each but
    #         their relative position / shape (e.g., END appears
    #         textually before START, START+END on the same line, no
    #         body between adjacent marker lines, or unusual whitespace)
    #         prevents body capture. This is a regex-shape-mismatch at
    #         the BODY-CAPTURE level — surface the specific diagnostic
    #         with concrete likely-cause guidance.
    #   (ii)  `regex_matched=True`, `body_has_content=True`, `entries=[]`:
    #         body captured successfully and has non-empty content lines,
    #         but no line matched the expected entry-line shape (e.g.,
    #         garbage between markers, non-comment shell content,
    #         comment lines without `->` separator). This is a regex-
    #         shape-mismatch at the ENTRY-SHAPE level — surface the
    #         entry-shape diagnostic NOT the legacy "no parseable
    #         entries" message (the block has content but the wrong
    #         shape; "no parseable entries" would be misleading).
    #   (iii) `regex_matched=True`, `body_has_content=False`, `entries=[]`:
    #         body captured but is whitespace-only (e.g., a single
    #         indented line that captured as ` ` between markers).
    #         Inventory is genuinely empty per the consumer's view;
    #         surface the legacy "no parseable entries" diagnostic
    #         (preserved pre-BD-180 message).
    if not entries:
        if not regex_matched:
            fail(
                "scripts/init-project.sh has exactly one "
                "`_CLIENT_INSTALLED_FILES_START` and exactly one "
                "`_CLIENT_INSTALLED_FILES_END` marker, but the block "
                "body could not be captured — the regex pattern "
                "`START\\s*\\n(.+?)\\n[^\\n]*END` did not match. Likely "
                "causes: (a) END marker appears textually before the "
                "START marker, (b) START and END markers on the same "
                "line, (c) no body between adjacent marker lines, "
                "(d) unusual whitespace around the markers (e.g., "
                "missing trailing newline after START, or missing "
                "leading newline before END). Note on case (c): an "
                "empty inventory is not a supported state in Check 41 "
                "at HEAD; if the pack genuinely no longer installs "
                "files to clients, Check 41 requires contract redesign "
                "(see ARCHITECTURE-BD-176.md §5.3 for design intent). "
                "The check intentionally surfaces this state rather "
                "than silently passing. Restore the canonical marker "
                "shape per ARCHITECTURE-BD-176.md §5.3 / BD-180 "
                "observation G: each marker on its own comment line, "
                "START preceding END, with body content between them."
            )
            return
        if body_has_content:
            fail(
                "scripts/init-project.sh has `_CLIENT_INSTALLED_FILES_START`/"
                "`_END` markers and the block body was captured by the "
                "regex, but the block body could not be parsed into "
                "inventory entries — the body has content lines but no "
                "line matches the expected entry shape. Likely causes: "
                "(a) entry lines missing the `->` separator, (b) entry "
                "lines not commented (must start with `#`), (c) "
                "malformed whitespace around `->`, (d) non-inventory "
                "content (e.g., shell statements) between the markers. "
                "Each entry line must be of the form "
                "`#   <pack_relpath>  ->  <project_relpath>  [stage:...]` "
                "between the START/END markers per ARCHITECTURE-BD-176.md "
                "§5.3 / BD-180 observation G."
            )
            return
        # regex_matched=True, body_has_content=False: body is captured
        # but whitespace-only. Preserve the pre-BD-180 diagnostic shape
        # so existing tests / documentation references remain valid.
        fail(
            "scripts/init-project.sh has `_CLIENT_INSTALLED_FILES_START`/"
            "`_END` markers but the block contains no parseable entries. "
            "Each entry must be a comment line of the form "
            "`#   <pack_relpath>  ->  <project_relpath>  [stage:...]` "
            "between the START/END markers."
        )
        return

    any_failed = False

    # (c) Every entry's pack_relpath exists at HEAD.
    files_checked = 0
    exempted = 0
    for pack_rel in entries:
        files_checked += 1
        if (REPO_ROOT / pack_rel).is_file():
            continue
        if pack_rel in _CHECK_41_EXEMPTIONS:
            exempted += 1
            ok(
                f"{pack_rel} — exempt per _CHECK_41_EXEMPTIONS: "
                f"{_CHECK_41_EXEMPTIONS[pack_rel]}"
            )
            continue
        fail(
            f"{pack_rel} — `_CLIENT_INSTALLED_FILES` inventory entry "
            f"references a source file that does not exist at HEAD. "
            f"Either remove the entry from the inventory block in "
            f"scripts/init-project.sh (between `_CLIENT_INSTALLED_FILES_"
            f"START` and `_CLIENT_INSTALLED_FILES_END`), update the "
            f"path to match the actual source location, or — if the "
            f"source intentionally lives outside repo HEAD — add it to "
            f"`_CHECK_41_EXEMPTIONS` in scripts/validate-pack.py with a "
            f"one-line rationale."
        )
        any_failed = True

    # (e) Every HAND-ENUMERATED per-file inventory row has a fresh-install copy
    #     site: its source basename appears on a copy-verb line in the body of a
    #     stage named by its [stage:] tag. Glob/list-loop rows are exempt
    #     (per-file omission is structurally impossible). Catches the
    #     ships-on-update / missing-on-fresh-install split-brain class.
    #
    #     LAZY: only the sentinel-registered stages actually referenced by a
    #     surviving non-exempt KEEP row are extracted. GRACEFUL-ABSENCE: when a
    #     referenced stage function is absent from the init-project.sh under
    #     check (a synthetic test scaffold legitimately omits it), that stage is
    #     skipped and rows with no available modelled stage body are skipped —
    #     the guard never emits a "could not locate" failure for a fixture that
    #     does not model the production stages. On the REAL tree both functions
    #     are present, so the guard runs at full strength.
    stage_map = _parse_client_installed_file_stages()

    # Restrict each row to its real-stage tokens (drop cmd_update / extern).
    def _row_stages(pack_rel: str) -> set[str]:
        return {t for t in stage_map.get(pack_rel, set()) if re.fullmatch(r"S\d+", t)}

    def _is_keep(pack_rel: str, sx: set[str]) -> bool:
        if not sx:
            return False  # cmd_update-only / extern — no fresh-install copy site expected
        if pack_rel in _CHECK_41_GLOB_LIST_EXEMPT:
            return False  # runtime-basename glob — basename absent by design
        if sx <= _CHECK_41_LIST_LOOP_STAGES:
            return False  # fixed-list loop — not a hand-enumerated per-file copy
        return True

    # EVERY sentinel-registered stage, not only the ones surviving KEEP rows
    # reference. Clause (g) below walks the copy sites to find literals with NO
    # row, and a DELETED row is precisely the case that would drop its stage
    # out of a demand-driven set — the guard would go blind on exactly the
    # mutation it exists to catch. The registry holds 3 stages and `init_text`
    # is already in memory, so this is 3 regex matches, not 3 file reads
    # (`ci-check-runtime-compounding`). Clause (e)'s verdict is unchanged: it
    # filters `stage_copy_bodies` down to each row's own stages, so bodies no
    # row references cannot affect it.
    init_text = init_sh.read_text()
    needed_stages: set[str] = set(_CHECK_41_STAGE_SENTINELS)
    # Extract + validate the copy-verb body for each NEEDED stage. A stage whose
    # function is ABSENT is skipped (graceful-absence); a stage whose captured
    # body is TRUNCATED (sentinel missing) is a loud diagnostic FAIL.
    stage_copy_bodies: dict[str, str] = {}
    for sid in sorted(needed_stages):
        fnname, sentinel = _CHECK_41_STAGE_SENTINELS[sid]
        bm = re.search(
            r"\n" + re.escape(fnname) + r"\(\)\s*\{\n(.*?)\n^\}$",
            init_text, re.DOTALL | re.MULTILINE,
        )
        if bm is None:
            continue  # graceful-absence: function not modelled in this init-project.sh
        body = bm.group(1)
        if sentinel not in body:
            fail(
                f"Check 41 clause (e): captured body of `{fnname}()` is missing "
                f"the END sentinel `{sentinel}` — the body-extraction regex "
                f"likely truncated at a line-initial `}}` inside the function. "
                f"Fix the function shape or update _CHECK_41_STAGE_SENTINELS."
            )
            any_failed = True
            continue
        stage_copy_bodies[sid] = "\n".join(
            ln for ln in body.splitlines()
            if not ln.lstrip().startswith("#") and _CHECK_41_COPY_VERB.search(ln)
        )

    copy_sites_checked = 0
    for pack_rel in entries:
        sx = _row_stages(pack_rel)
        if not _is_keep(pack_rel, sx):
            continue
        # Only the row's stages whose bodies were actually extracted are usable.
        usable = [s for s in sx if s in stage_copy_bodies]
        if not usable:
            continue  # graceful-absence: no modelled stage body for this row
        copy_sites_checked += 1
        bn = Path(pack_rel).name
        present = any(bn in stage_copy_bodies[s] for s in usable)
        if not present:
            fail(
                f"{pack_rel} — `_CLIENT_INSTALLED_FILES` inventory row tagged "
                f"{sorted(sx)} has NO fresh-install copy site: source basename "
                f"`{bn}` does not appear on a copy-verb line "
                f"(cp / existing_classifier_copy / $copy_fn) in the body of "
                f"{[_CHECK_41_STAGE_SENTINELS[s][0] for s in usable]}. "
                f"Add the per-file copy step to the stage function, OR — if the "
                f"row genuinely ships via a directory glob — add it to "
                f"`_CHECK_41_GLOB_LIST_EXEMPT` with a one-line rationale. (This "
                f"is the ships-on-update/missing-on-fresh-install class.)"
            )
            any_failed = True

    # (f) Every `[class:...]` the map declares names a class that really
    #     DISPATCHES. The shape gate in `install-map.sh` proves a class operand
    #     is a bare lowercase token; it cannot prove the token means anything.
    #     `customization_preserve()` ends in a `*)` catch-all that falls back to
    #     the generic 3-way TEXT merge, so a well-shaped typo — `slef` for
    #     `self`, `trinty` for `trinity`, `codex-confg` for `codex-config` — is
    #     not an error anywhere: it silently CHANGES the merge strategy, which
    #     is how a client `x-` custom gets three-wayed or a TOML gets text-merged
    #     instead of key-unioned. This is the load-bearing backing test for a
    #     declared mapping: the arm must exist, not merely the token.
    #
    #     The vocabulary is DERIVED from the dispatch itself, never copied here.
    #     LENIENT: an unreadable library or case block yields an empty
    #     vocabulary and the clause skips, so a synthetic scaffold that ships no
    #     library is not failed for it.
    classes_checked = 0
    vocab = _customization_preserve_classes()
    if vocab:
        declared: list[tuple[str, str]] = [
            (pack_rel, cls)
            for pack_rel, cls in sorted(_parse_client_installed_file_classes().items())
        ]
        declared += [
            (src, cls)
            for src, _dest, _st, cls in _parse_client_installed_globs()
            if cls
        ]
        for pack_rel, cls in declared:
            if not cls:
                continue
            classes_checked += 1
            if cls in vocab or cls in _CHECK_41_CLASS_SENTINELS:
                continue
            fail(
                f"{pack_rel} — install map row declares `[class:{cls}]`, which "
                f"has NO dispatch arm in `customization_preserve()` "
                f"(scripts/lib/customization-preserve.sh). An unrecognised "
                f"class is not an error at merge time: it falls through that "
                f"function's `*)` catch-all to the generic 3-way TEXT merge, "
                f"silently changing the preservation strategy for this file. "
                f"Use one of {sorted(vocab)}, or omit `[class:...]` entirely to "
                f"self-classify. (If a NEW class is intended, add its arm to "
                f"`customization_preserve()` first — this check reads the "
                f"vocabulary from that dispatch, so it needs no update here.)"
            )
            any_failed = True

    # (g) The REVERSE of (e): every PER-FILE copy literal in a registered stage
    #     body has an inventory row. Clause (e) walks rows -> copy sites and so
    #     can only catch a row whose copy site went missing; it is structurally
    #     blind to a copy site whose ROW went missing, because a deleted row is
    #     simply not iterated. That blind spot is not hypothetical — it is the
    #     defect class that lost `project-template/agent-run.sh` from the map in
    #     the first place, and Check 39's wholesale leg does not cover it either
    #     (that leg bounds sites which copy a WHOLE DIRECTORY; this is the
    #     per-file `cp "$PACK/project-template/<file>"` shape).
    #
    #     A file with a copy site and no row installs on a fresh install and is
    #     then unreachable forever: `--update` derives its entire dispatch set
    #     from the map, so it can neither refresh nor repair the file.
    #
    #     NO allowlist, and none is needed — the clause is self-bounding. It
    #     considers only LITERAL `$PACK/project-template/...` operands on
    #     copy-verb lines, and only those resolving to a real FILE. A directory
    #     operand (`"$PACK/project-template/scripts"`, the fixed-list loop) and
    #     a loop variable (`cp "$f" ...`) both fall out by construction, which
    #     is what keeps the legitimate-set EMPTY (`ci-guard-measure-then-bound`).
    reverse_sites_checked = 0
    for sid in sorted(stage_copy_bodies):
        fnname = _CHECK_41_STAGE_SENTINELS[sid][0]
        # De-duplicated per stage: a single file is routinely named on TWO
        # copy-verb lines (the `existing_classifier_copy` arm and the plain
        # `cp` fallback of the same `if`), and one missing row is one finding,
        # not two.
        literals = {
            f"project-template/{m.group(1)}"
            for m in _CHECK_41_PACK_SRC_LITERAL.finditer(stage_copy_bodies[sid])
        }
        for pack_rel in sorted(literals):
            if not (REPO_ROOT / pack_rel).is_file():
                continue  # directory operand / stale literal — not a per-file ship
            reverse_sites_checked += 1
            if pack_rel in entries:
                continue
            fail(
                f"{pack_rel} — `{fnname}()` (stage {sid}) copies this file to "
                f"the client from a per-file literal, but it has NO "
                f"`_CLIENT_INSTALLED_FILES` inventory row. A fresh install "
                f"places the file and `--update` then cannot see it at all: "
                f"the dispatch set is derived entirely from the map, so the "
                f"client keeps whatever bytes it first received, forever. Add "
                f"a row to the inventory block in scripts/init-project.sh of "
                f"the form `#   {pack_rel}  ->  <project_relpath>  "
                f"[stage:{sid},cmd_update]  [class:<token>]`. There is no "
                f"exemption list for this clause: a per-file copy site ships "
                f"the file, so the file must be refreshable."
            )
            any_failed = True

    if not any_failed:
        ok(
            f"Check 41 — {files_checked} `_CLIENT_INSTALLED_FILES` entry "
            f"(entries) checked; {files_checked - exempted} resolve to "
            f"existing files at HEAD, {exempted} on exemption allowlist. "
            f"{copy_sites_checked} hand-enumerated row(s) verified to have a "
            f"fresh-install copy site. {reverse_sites_checked} per-file copy "
            f"literal(s) verified to have an inventory row. "
            f"{classes_checked} declared `[class:]` "
            f"operand(s) resolve to a real dispatch arm. "
            f"Self-documenting list is consistent with copy-site state."
        )




# ── Shared operating-doc auto-discovery infrastructure (BD-243) ────────────
# The operating-doc IN set, discovered by GLOBBING the operating-doc families
# then SUBTRACTING the frozen EXEMPT set. This is the SINGLE source of truth
# for the operating-doc content gates (Check 65 history; Checks 67/68 land at
# CG-14-prep-b). Auto-discovery — NOT a frozen IN list — is the durable fix
# for the silent-rot hole: a NEW operating doc in a globbed family is scanned
# automatically; the only way to EXCLUDE a new doc is to add it to EXEMPT or
# OUT-OF-FAMILY WITH A RATIONALE (a reviewable governance act). Gate 4
# (Check 69, below) asserts the glob's own completeness.
#
# DESIGN: DESIGN-BD-243-DURABLE-GATES.md §2 (families + EXEMPT + the discovery
# function) + §5 (auto-discover − EXEMPT + meta-check is the adopted scope
# model). The frozen auditable surface is the small EXEMPT + OUT-OF-FAMILY +
# family-pattern lists, NOT the ~136-member IN set.
#
# NOTE: pack skills are .claude/skills/*/SKILL.md ONLY — the .codex / .agents
# skill MIRRORS are governed by their own byte-identity check, NOT scanned
# here (scanning them would double-count identical content).

# The operating-doc families. Each entry is either a LITERAL repo-relative
# path (trinity + the two pack stream-meta _rules + the project changelog
# _format + RUNTIME-SUBAGENT-PATTERN) or a Path.glob() pattern (relative to
# REPO_ROOT). _iter_operating_docs() expands the globs, collects the literals,
# subtracts EXEMPT, and returns a sorted unique list. (§2.1)
_CHECK_OPERATING_DOC_FAMILIES = (
    # pack trinity
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    # pack-ops operating docs (HELP-FRAGMENT-PACK is EXEMPT)
    "pack-ops/*.md",
    # pack skills (the .claude mirror only; .codex/.agents mirrors are
    # byte-identity-checked, not scanned here)
    ".claude/skills/*/SKILL.md",
    # pack agents
    ".claude/agents/pack-*.md",
    # pack stream-meta write-contracts
    "backlog/_rules.md",
    "changelog/_rules.md",
    # project trinity
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    # project docs/pack operating docs (HELP-FRAGMENT is EXEMPT)
    "project-template/docs/pack/*.md",
    # the runtime-subagent pattern doc (lives beside the Antigravity plugin,
    # not under docs/pack — an explicit family member, not a tree glob)
    "project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md",
    # project per-agent prompt templates
    "project-template/docs/pack/prompts/*.md",
    # project skills
    "project-template/skills/*/SKILL.md",
    # project agent-defs — the three platform families
    "project-template/.claude/agents/*.md",
    "project-template/.agents-plugin/optiquity-agents/agents/*.md",
    "project-template/.codex/agents/*.toml",
    # project stream-meta write-contracts (the changelog format spec folds
    # into changelog/_rules.md's `## Entry structure` section)
    "project-template/docs/project/*/_rules.md",
    # newly-operating supporting-docs (BD-250 targeted reversal of BD-243's
    # EXEMPT ruling for exactly these 2 — they issue live instruction the PM
    # chat / agents EXECUTE; the other supporting-docs/*.md stay reference).
    # POINT LITERALS, never a supporting-docs/*.md glob (a glob would wrongly
    # pull in the reference files BD-243 measured EXEMPT). Reached by Check 69
    # as point family-members (NOT tree-scanned) — same posture as the trinity
    # + _rules.md literals; _CHECK_OPERATING_DOC_SCANNED_TREES is UNCHANGED.
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
)



# Globbed-but-EXEMPT: a family glob picks these up but they are NOT operating
# docs (human orientation / generated index / help OUTPUT). The frozen,
# small, rationale'd auditable surface that REPLACES freezing the whole IN
# set. (§2.2) Matched by exact basename (`_intro.md` / `_toc.md`) or basename
# prefix (`HELP-FRAGMENT*`).
#   _intro.md         — human orientation, ZERO rules
#   _toc.md           — generated index
#   HELP-FRAGMENT*.md — help OUTPUT (HELP-FRAGMENT-PACK / HELP-FRAGMENT), not
#                       executed as instruction
_CHECK_OPERATING_DOC_EXEMPT = (
    "_intro.md",
    "_toc.md",
    "HELP-FRAGMENT",  # prefix match: HELP-FRAGMENT-PACK.md, HELP-FRAGMENT.md
    # EXACT-basename entry (matched by the `elif name == ex` branch below, NOT
    # the HELP-FRAGMENT prefix branch — the bare token "DASHBOARD-SPEC" would be
    # a silent no-op). The dashboard build spec is a verbatim USER-OWNED
    # reference SOURCE (read fresh every render), not a terse operating doc the
    # chat executes — its length + verbatim bare refs are fine there. This
    # exempts it from the content gates Checks 65/67/68/69. Check 40 walks
    # pack-ops/*.md on its OWN glob (see `excluded_basenames` in
    # check_bare_pack_ops_refs) and needs its own separate exclusion.
    "DASHBOARD-SPEC-PACK.md",
    # The client analog: the project-template build spec for /pm-dashboard, a
    # verbatim USER-OWNED reference SOURCE (read fresh every render) shipped at
    # project-template/docs/pack/PM-DASHBOARD-SPEC.md. It sits in a scanned
    # operating-doc family (project-template/docs/pack/*.md), so it needs the
    # same exact-basename exemption from Checks 65/67/68/69. (Check 40 scans
    # pack-ops/*.md only, not project-template/, so no Check-40 exclusion is
    # needed here.)
    "PM-DASHBOARD-SPEC.md",
)




def _operating_doc_is_exempt(path: Path) -> bool:
    """True iff a family-globbed path is EXEMPT (orientation / index / help
    output). Exact-basename match for `_intro.md`/`_toc.md`; prefix match for
    `HELP-FRAGMENT*`."""
    name = path.name
    for ex in _CHECK_OPERATING_DOC_EXEMPT:
        if ex.startswith("HELP-FRAGMENT"):
            if name.startswith("HELP-FRAGMENT"):
                return True
        elif name == ex:
            return True
    return False




def _operating_doc_families() -> list:
    """Expand _CHECK_OPERATING_DOC_FAMILIES into a flat list of repo-relative
    POSIX path strings (globs expanded against REPO_ROOT, literals kept if the
    file exists). Does NOT subtract EXEMPT — that is _iter_operating_docs()'s
    job. (§2.1)"""
    out = []
    for entry in _CHECK_OPERATING_DOC_FAMILIES:
        if any(ch in entry for ch in "*?[") :
            out.extend(
                p.relative_to(REPO_ROOT).as_posix()
                for p in REPO_ROOT.glob(entry)
                if p.is_file()
            )
        else:
            if (REPO_ROOT / entry).is_file():
                out.append(entry)
    return out




def _iter_operating_docs() -> list:
    """The operating-doc IN set, auto-discovered by family glob minus EXEMPT.

    Single source of truth for Check 65 (history) and the CG-14-prep-b content
    gates (67 deferred-feature, 68 dangling-ref). Gate 4's meta-check
    (Check 69) asserts every file under the operating-doc trees is family-
    globbed OR EXEMPT OR OUT-OF-FAMILY, so this discovery cannot silently miss
    a doc. Returns a sorted, de-duplicated list of repo-relative POSIX path
    strings. (§2.3)"""
    seen = set()
    for rel in _operating_doc_families():
        if rel in seen:
            continue
        if _operating_doc_is_exempt(REPO_ROOT / rel):
            continue
        seen.add(rel)
    return sorted(seen)




# ── Check 69 (Gate 4): operating-doc scope-completeness meta-check (BD-243) ─
# THE HOLE IT CLOSES: auto-discovery (_iter_operating_docs) is only as good as
# its family patterns + EXEMPT list. A doc added in an un-globbed LOCATION (a
# family the glob does not cover) would still escape the content gates. Gate 4
# asserts: every file under the operating-doc top-level trees is (i) matched by
# a family glob, (ii) EXEMPT, or (iii) on the frozen OUT-OF-FAMILY list. A file
# that is none of these FAILs with "add it to a family glob / EXEMPT it / mark
# it OUT-OF-FAMILY with a rationale" — converting "silently escapes" into a
# loud build failure. (DESIGN §3 Gate 4 + §5.)
#
# SCOPE NOTE: the SCANNED trees are the operating-doc-ONLY directories. The
# pack/project trinity (repo root + project-template root) and the
# backlog/changelog stream-meta _rules are point family-members, NOT tree-
# scanned: scanning the repo root or the backlog/ + changelog/ PER-ENTRY
# STORES would pull in the entire repo and the 243 BD + 11 changelog HISTORY
# entries (the history-home — explicitly NOT operating docs). So Gate 4 scans
# only the dirs that hold operating docs and would hide a stray un-globbed doc.
#
# GIT-TRACKED-ONLY SCAN (DESIGN-BD-243-CHECK69-ENV-ROBUSTNESS.md §3, fix A).
# The completeness assertion below is a CLOSED-WORLD cover: every scanned path
# must be family-globbed OR EXEMPT OR OUT-OF-FAMILY, else FAIL. The candidate
# file set is therefore the git-TRACKED files under each scanned tree
# (`git ls-files <tree>`), NOT a raw `tree.rglob("*")` filesystem walk. Check 69
# asserts a fact about the COMMITTED pack surface, and the committed surface IS
# the tracked set — so tracked-only is the property-fit, not a workaround (the
# prior art is Check 63, which uses `git ls-files` for exactly this "assert over
# the tracked surface" class, with the same lenient git-unavailable SKIP). This
# makes the env irrelevant by construction: gitignored/untracked OS junk
# (`.DS_Store`, editor temp files, `.venv`, build artifacts) is never in the
# tracked set, so it can never trip the closed-world assertion on ANY checkout —
# closing the green-CI / red-local trap where a dev's `.DS_Store` failed local
# verify while a fresh worktree/CI clone (tracked content only) passed. An
# untracked-but-legitimate brand-new operating doc not yet `git add`-ed is
# invisible to this scan — acceptable and correct: CI runs on committed state
# where it IS tracked, so the scan asserts exactly what ships.
#
# META-PRINCIPLE GUARD (DESIGN §6): any validate-pack check (or shipped client
# check) that ENUMERATES THE FILESYSTEM and asserts a CLOSED-WORLD completeness /
# coverage property over an operating-doc tree MUST (a) scan the git-tracked
# surface only (pack-side; lenient git-unavailable SKIP per Check 63), or use a
# glob/extension-bounded enumeration that cannot admit OS junk; AND (b) carry a
# junk-injection test proving it ignores gitignored/untracked artifacts (see
# scripts/tests/test-validate-pack-check-69.sh — the junk-injection Group is
# Check 69's executable teeth). A closed-world assertion over a raw
# `rglob("*")` / `os.walk` of the live filesystem is PROHIBITED — it makes the
# check env-sensitive. REVIEWER PROTOCOL: when reviewing a new closed-world
# filesystem-completeness check, confirm the junk-injection assertion EXISTS,
# not merely that the live tree happens to pass.
#
# RUNTIME COST: one `git ls-files <tree>` subprocess per scanned tree + set
# arithmetic. Gate 4 reads NO file bodies — it enumerates PATHS only. Cheap.

# The operating-doc-only top-level trees Gate 4 walks (repo-relative). NOT the
# repo root, NOT the backlog/ + changelog/ per-entry stores.
_CHECK_OPERATING_DOC_SCANNED_TREES = (
    "pack-ops",
    ".claude/skills",
    ".claude/agents",
    "project-template/docs/pack",
    "project-template/skills",
    "project-template/.claude/agents",
    "project-template/.agents-plugin/optiquity-agents",
    "project-template/.codex/agents",
    "project-template/docs/project",
)



# FROZEN: files under the scanned trees that are legitimately NOT operating
# docs and NOT EXEMPT — data files consumed by checks + a plugin manifest.
# Sized EXACTLY by measuring the trees (measure-then-bound); a new entry here
# is a reviewable governance act. Adding an operating doc does NOT touch this
# list (it is family-globbed); adding a NON-doc data file under a scanned tree
# DOES (or Gate 4 FAILs loudly). (DESIGN §3 Gate 4 ENCODING SURFACES.)
_CHECK_OPERATING_DOC_OUT_OF_FAMILY = (
    # pack-ops/ data files (allowlists + manifests consumed by other checks)
    "pack-ops/.boundary-exempt-root.txt",
    "pack-ops/.boundary-pointer-manifest.txt",
    "pack-ops/.bullet-concision-allowlist.txt",
    "pack-ops/.concision-allowlist.txt",
    "pack-ops/.dangling-ref-allowlist.txt",
    "pack-ops/.operating-doc-deferred-feature-allowlist.txt",
    "pack-ops/.operating-doc-history-allowlist.txt",
    "pack-ops/.spawn-rule-manifest.txt",
    # the BD-252 session-state snapshot: a JSON live-state DATA file (the
    # committed resumable current-frontier snapshot), not an operating doc. Its
    # no-history protection is supplied by the bespoke C-grammar check (79), NOT
    # the `.md` content gates (it matches no operating-doc family glob).
    "pack-ops/session-state.json",
    # the BD-224 pack-dashboard rendered board: generated non-doc DATA files (the
    # HTML board + its reusable spec-fingerprinted shell + the published-URL
    # record), NOT operating docs — no `.md` content gate applies. dashboard.html
    # is git-tracked but marked `-diff -merge` (whole-file overwrite; churn by
    # design). Their tracked-set + shell-spec-sha invariants are enforced by
    # Checks 86/88, not the operating-doc content gates.
    "pack-ops/dashboard-approvals/dashboard.html",
    "pack-ops/dashboard-approvals/dashboard-shell.html",
    "pack-ops/dashboard-approvals/dashboard-url.txt",
    # the Antigravity plugin manifest (machine config, not an operating doc)
    "project-template/.agents-plugin/optiquity-agents/plugin.json",
)




def check_operating_doc_scope_completeness() -> None:
    """Check 69 (Gate 4) — operating-doc scope-completeness meta-check (BD-243).

    Walks the operating-doc-only trees (_CHECK_OPERATING_DOC_SCANNED_TREES) and
    asserts EVERY file is (i) family-globbed (in _iter_operating_docs's
    pre-EXEMPT family expansion), (ii) EXEMPT (_CHECK_OPERATING_DOC_EXEMPT), or
    (iii) on the frozen _CHECK_OPERATING_DOC_OUT_OF_FAMILY list. A file that is
    none of these FAILs — a new operating doc (or a new data file) under a
    scanned tree that escaped the family globs / EXEMPT / OUT-OF-FAMILY surface
    is caught LOUDLY instead of silently escaping the content gates.

    This is the backstop that makes auto-discovery (_iter_operating_docs)
    trustworthy: the glob's coverage becomes an ASSERTED invariant, not an
    implicit one. Reads NO file bodies (path enumeration + set arithmetic).

    GIT-TRACKED-ONLY scan (DESIGN-BD-243-CHECK69-ENV-ROBUSTNESS.md §3, fix A):
    the candidate file set is the git-TRACKED files under each scanned tree
    (`git ls-files <tree>`), NOT a raw `tree.rglob("*")` filesystem walk, so
    gitignored/untracked OS junk (`.DS_Store`, editor temp files) can NEVER trip
    the closed-world assertion — the env is irrelevant by construction. See the
    header comment for the META-PRINCIPLE GUARD + reviewer protocol.

    Per DESIGN-BD-243-DURABLE-GATES.md §3 Gate 4 + §5 and
    DESIGN-BD-243-CHECK69-ENV-ROBUSTNESS.md.

    Lenient mode: `git` unavailable or the cwd is not a git work tree
    (`git ls-files` raises FileNotFoundError / returns non-zero) → SKIP the
    whole check (mirrors Check 63's lenient posture — never hard-fail on a
    non-git environment).
    """
    print(
        "\n── Check 69: operating-doc scope-completeness meta-check (BD-243) ──"
    )

    family_members = set(_operating_doc_families())
    out_of_family = set(_CHECK_OPERATING_DOC_OUT_OF_FAMILY)

    # Candidate file set = git-TRACKED files under the scanned trees (NOT a raw
    # rglob filesystem walk). One `git ls-files <tree>...` over all scanned
    # trees; lenient SKIP if git is unavailable / not a work tree (mirrors
    # Check 63). gitignored/untracked OS junk is never in the tracked set, so it
    # can never trip the closed-world completeness assertion.
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z", "--", *_CHECK_OPERATING_DOC_SCANNED_TREES],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        ok("git not available — skipping (lenient)")
        return
    if result.returncode != 0:
        ok("git ls-files unavailable (not a git work tree) — skipping (lenient)")
        return

    tracked_rels = sorted(
        rel for rel in result.stdout.split("\0") if rel.strip()
    )

    any_fail = False
    scanned_files = 0
    family_count = 0
    exempt_count = 0
    out_count = 0

    for rel in tracked_rels:
        path = REPO_ROOT / rel
        if not path.is_file():
            # tracked-but-absent (e.g. a deleted-not-committed path) — nothing
            # to classify; skip silently (the completeness assertion is over
            # files that EXIST on the committed surface).
            continue
        scanned_files += 1
        if rel in family_members:
            family_count += 1
            continue
        if _operating_doc_is_exempt(path):
            exempt_count += 1
            continue
        if rel in out_of_family:
            out_count += 1
            continue
        any_fail = True
        fail(
            f"{rel} — file under an operating-doc tree is NEITHER family-"
            f"globbed NOR EXEMPT NOR on _CHECK_OPERATING_DOC_OUT_OF_FAMILY. "
            f"Per BD-243 Gate 4, every file under the operating-doc trees "
            f"must be covered so a new doc cannot silently escape the "
            f"content gates (Check 65 history + the CG-14-prep-b gates). "
            f"Remediation: if it is an operating doc, add its location to a "
            f"family glob in _CHECK_OPERATING_DOC_FAMILIES; if it is "
            f"orientation/index/help output, add it to "
            f"_CHECK_OPERATING_DOC_EXEMPT; if it is a non-doc data file, "
            f"add it to _CHECK_OPERATING_DOC_OUT_OF_FAMILY — each WITH a "
            f"rationale a reviewer re-verifies."
        )

    if not any_fail:
        ok(
            f"Check 69 — {scanned_files} file(s) under "
            f"{len(_CHECK_OPERATING_DOC_SCANNED_TREES)} operating-doc tree(s) "
            f"scanned; all covered ({family_count} family-globbed, "
            f"{exempt_count} EXEMPT, {out_count} out-of-family); 0 uncovered "
            f"(complete). IN set = {len(_iter_operating_docs())} operating doc(s)."
        )




# ── Check 65: operating-doc no-history gate (BD-243) ───────────────────────
# The history axis over the operating-doc IN set. An operating doc issues
# system-wide operating instructions to chat sessions / agents; it must be
# forward-only — historical / audit-trail text (dates, SHAs, Commit-N,
# Override-N, post-Commit, BD past-action / provenance, incident / carry-over
# narration) belongs in IMPL reports + reference docs, never in an operating
# doc. THE TEETH: any history-pattern hit on a scanned IN doc, NOT covered by
# a pack-ops/.operating-doc-history-allowlist.txt snippet, FAILs. The
# allowlist is sized to the KEEP set EXACTLY (measure-then-bound) — the live
# doc-refs, the live transitional pointer, the format examples — never widened
# to admit contamination.
#
# Scope is the auto-discovered operating-doc IN set: _CHECK_65_OPERATING_DOCS
# is repointed (model B) to tuple(_iter_operating_docs()) at module load
# (BD-243 CG-14-prep-a), so a NEW operating doc is scanned automatically and
# the silent-rot hole of a frozen IN list is closed. The constant NAME is
# preserved so the per-check test's monkeypatch seam (save/restore +
# substitute a synthetic doc) is unchanged.
#
# This check owns the date / SHA / Commit-N / Override-N / post-Commit axis
# moved from Check 44, PLUS the BD/TD provenance axis Check 44 never had.

_CHECK_65_FORBIDDEN_PATTERNS = (
    ("date", re.compile(r"20[0-9]{2}-[0-9]{2}-[0-9]{2}")),
    ("sha", re.compile(r"\b[0-9a-f]{7,40}\b")),
    ("commit-N", re.compile(r"Commit [0-9]")),
    ("override-N", re.compile(r"Override [0-9]")),
    ("post-Commit", re.compile(r"post-Commit")),
    ("bd-past-action", re.compile(
        r"BD-\d+\s+(deleted|added|renamed|introduced|removed|created|"
        r"retired|broadened|did)"
    )),
    ("per-BD", re.compile(r"per\s+BD-\d+")),
    ("pre-date", re.compile(r"pre-20[0-9]{2}-[0-9]{2}-[0-9]{2}")),
    ("user-locked", re.compile(r"User-locked")),
    ("incident", re.compile(r"\bincident\b")),
    ("carry-over", re.compile(r"carried from|carry-over")),
    ("bd-tag", re.compile(r"BD-\d+")),
)



# The operating-doc IN set scanned by Check 65. REPOINTED (BD-243 CG-14-prep-a,
# model B) from a frozen empty tuple to the AUTO-DISCOVERED IN set
# (tuple(_iter_operating_docs()) — the family globs minus EXEMPT) evaluated at
# module load. This ACTIVATES Check 65 over the full pack+project operating-doc
# IN set and closes the frozen-IN silent-rot hole (a NEW operating doc is
# scanned automatically; Gate 4 / Check 69 asserts the discovery is complete).
# The constant NAME is preserved (not inlined into the loop) so the per-check
# test's monkeypatch seam — test-validate-pack-check-65.sh saves/restores
# mod._CHECK_65_OPERATING_DOCS and substitutes a synthetic doc — stays intact.
_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())




def _check_65_load_allowlist() -> dict:
    """Parse pack-ops/.operating-doc-history-allowlist.txt into
    {doc: [snippet, ...]}.

    Each record carries `doc:`, `pattern:`, `snippet:`, `reason:`. The
    matching key is (doc, snippet-substring) — line numbers are NOT used
    (they drift). Returns a dict mapping each doc path to its list of
    allowlisted snippet substrings. Reuses _parse_manifest_records()
    (the same pattern as Check 44's allowlist read).
    """
    allowlist_path = (
        REPO_ROOT / "pack-ops" / ".operating-doc-history-allowlist.txt"
    )
    if not allowlist_path.is_file():
        return {}
    records = _parse_manifest_records(allowlist_path.read_text())
    by_doc: dict = {}
    for rec in records:
        doc = rec.get("doc")
        snippet = rec.get("snippet")
        if doc and snippet:
            by_doc.setdefault(doc, []).append(snippet)
    return by_doc




def check_operating_doc_no_history() -> None:
    """Check 65 — operating-doc no-history gate (BD-243).

    Scans the operating-doc IN set (_CHECK_65_OPERATING_DOCS) for history /
    audit-trail patterns (dates / 7-40-hex SHAs / Commit-N / Override-N /
    post-Commit / BD past-action / per-BD provenance / pre-date /
    User-locked / incident / carry-over / bare BD-NNN tag). THE TEETH: any
    matched line NOT covered by a
    pack-ops/.operating-doc-history-allowlist.txt record (doc match AND an
    allowlisted snippet is a substring of the line) FAILs — history-pattern
    count must be 0 OUTSIDE the allowlist.

    The allowlist is ANCHOR-EXEMPT FIRST (an allowlisted snippet on the line
    clears it) THEN residue FAILs — the bare BD-NNN tag overlaps the live
    doc-refs, the live transitional pointer, and the format examples, all of
    which are KEEP snippets in the allowlist.

    Per BD-243 / DESIGN-BD-243-FINAL.md §E + ARCHITECTURE-DOC-CONCISION-
    GUARDRAILS.md (the MOVE addendum). The allowlist is sized to the KEEP
    set EXACTLY (measure-then-bound) — never widened to admit a
    contamination hit. A reviewer re-verifies each `reason:` still names
    LIVE-and-CURRENT work.

    Lenient mode: an IN doc absent at HEAD SKIPs that doc (an init/state
    problem, not a history violation); a missing allowlist file means an
    empty allowlist (every history hit then FAILs — fail-loud, matching
    Check 44, never silently-pass).
    """
    print("\n── Check 65: operating-doc no-history gate (BD-243) ──")

    allowlist = _check_65_load_allowlist()

    any_fail = False
    scanned_docs = 0
    total_forbidden_outside = 0
    total_allowlisted = 0

    # DEAD-RECORD TRACKING (declare-verify-backing). The allowlist header
    # claims it is "sized to the KEEP set EXACTLY" and that a reviewer
    # re-verifies each `reason:` — but nothing verified a record still
    # matches anything. A record whose exempted line was edited or deleted
    # simply stops firing and sits here invisibly, which is precisely what
    # the removed K6 record had become. Recording which records actually
    # FIRE makes that records-style claim load-bearing.
    #
    # ADVISORY ONLY, never a gate: a record can be legitimately un-triggered
    # (its doc absent at HEAD, or momentarily outside the IN set), so a hard
    # FAIL here would red CI on a false positive.
    scanned_doc_set: set = set()
    used_records: set = set()

    for doc_rel in _CHECK_65_OPERATING_DOCS:
        doc_path = REPO_ROOT / doc_rel
        if not doc_path.is_file():
            ok(f"{doc_rel} absent — skipping that doc (lenient)")
            continue
        scanned_docs += 1
        scanned_doc_set.add(doc_rel)
        snippets = allowlist.get(doc_rel, [])
        lines = doc_path.read_text().splitlines()

        for lineno, line in enumerate(lines, start=1):
            matched_patterns = [
                name for name, rx in _CHECK_65_FORBIDDEN_PATTERNS
                if rx.search(line)
            ]
            if not matched_patterns:
                continue
            # ANCHOR-EXEMPT FIRST: a line is allowlisted iff one of the
            # doc's allowlist snippets is a substring of the line
            # (content-anchored, not line-number-anchored — lines drift).
            # Iterate rather than `any(...)`: the short-circuit would hide a
            # second snippet that also covers this line and mis-report its
            # record as dead below. Cost is O(snippets), and only on a line
            # that already matched a forbidden pattern.
            covered = False
            for snip in snippets:
                if snip in line:
                    covered = True
                    used_records.add((doc_rel, snip))
            if covered:
                total_allowlisted += 1
                continue
            total_forbidden_outside += 1
            fail(
                f"{doc_rel}:{lineno} — operating-doc history pattern "
                f"{matched_patterns} OUTSIDE the allowlist: "
                f"`{line.strip()[:90]}`. Per BD-243, operating docs are "
                f"forward-only: history / audit-trail text (dates / SHAs / "
                f"Commit-N / Override-N / post-Commit / BD past-action / "
                f"per-BD provenance / incident / carry-over / bare BD-NNN "
                f"tag) is a report-only artifact and belongs in IMPL reports "
                f"+ reference docs, never in an operating doc. Remediation: "
                f"STRIP it (a live doc-ref / transitional pointer / format "
                f"example goes in the allowlist). The allowlist is sized to "
                f"the legitimate KEEP set EXACTLY and MUST NOT be widened to "
                f"admit this hit."
            )
            any_fail = True

    # O(records) set difference — no extra file read, no subprocess, no
    # tree walk (ci-check-runtime-compounding).
    declared = {(d, s) for d, snips in allowlist.items() for s in snips}
    dead = sorted(
        r for r in declared if r[0] in scanned_doc_set and r not in used_records
    )
    unscanned = sorted(r for r in declared if r[0] not in scanned_doc_set)

    for doc_rel, snip in dead:
        warn(
            f"Check 65 allowlist — record `doc: {doc_rel}` / "
            f"`snippet: {snip}` matched NO line in that doc. The allowlist "
            f"is declared 'sized to the KEEP set EXACTLY', so a record that "
            f"never fires is dead weight: either the line it exempted was "
            f"edited/removed (drop the record) or the snippet drifted "
            f"(re-anchor it). Advisory only — exit code unaffected."
        )
    for doc_rel, snip in unscanned:
        warn(
            f"Check 65 allowlist — record `doc: {doc_rel}` / "
            f"`snippet: {snip}` names a doc outside the scanned operating-doc "
            f"IN set (absent at HEAD, or not an IN doc), so the record can "
            f"never fire. Advisory only — exit code unaffected."
        )

    if not any_fail:
        ok(
            f"Check 65 — {scanned_docs} operating doc(s) scanned; "
            f"{total_forbidden_outside} history pattern(s) outside the "
            f"allowlist (0 = clean); {total_allowlisted} allowlisted KEEP "
            f"occurrence(s) admitted. Allowlist backing: {len(declared)} "
            f"record(s) declared, {len(used_records)} live, {len(dead)} dead, "
            f"{len(unscanned)} on unscanned docs."
        )




# ── Check 67 (Gate 2): operating-doc deferred-feature recall gate (BD-243) ─
# WHAT IT CATCHES (DESIGN-BD-243-DURABLE-GATES.md §3 Gate 2): an operating-doc
# line that ADVERTISES a deferred / unimplemented / future-version FEATURE
# ("tracker integration is deferred", "deferred to a future release", "once
# those skills land", "v11.1 work"). A RECALL gate, NOT precision: no regex
# decides "is this feature shipped?"; it flags every marker-bearing line, and
# the allowlist (sized to the genuine operative KEEPs) clears the legitimate
# ones — anything else FAILs.
#
# SCOPE (auto-discovered): _iter_operating_docs() — the family-globbed-minus-
# EXEMPT IN set. A NEW operating doc that advertises a deferred feature is
# exactly the silent-rot case this gate exists to catch.
#
# measure-then-bound: the allowlist (pack-ops/.operating-doc-deferred-feature-
# allowlist.txt) is sized EXACTLY to the measured KEEP set across four
# categories (C1 the deferral/operating-docs RULES; C2 generic client-product
# advice; C3 operative current-state caveats; C4 the LIVE TD-deferral
# workflow). PLATFORM-SKILLS.md contributes ZERO records (the CB-08 D-1 strip
# cleaned its deferred-skills catalog) — any future PLATFORM-SKILLS hit is a
# regression caught loudly.
#
# SPAN MASK (twin of mask_spans() in the client gate,
# project-template/scripts/validate-docs.sh — the two change in LOCK-STEP): a
# deferral word inside an inline code span or a Markdown link target is a NAME
# — a status token, a rationale slug, a path — not an advertisement, so the
# marker scan reads a MASKED copy of the line. The mask is bound to the marker
# scan ALONE and must never reach:
#   * covered() — allowlist snippets are RAW substrings and some quote a code
#     span, so a masked line would stop matching its own record and a doc the
#     allowlist has already cleared would start FAILing;
#   * the fail() message — a reviewer adjudicates the line as written;
#   * Check 68 (dangling), whose entire input IS code spans and link targets.
#     Masking there would leave it scanning blanks while still reporting clean.
# A code span becomes a SPACE, not nothing, so the words on either side stay
# separate tokens for the \b anchors below.
#
# RUNTIME COST (ci-check-runtime-compounding), per IN line: ONE
# _check_67_mask_spans call (2 compiled substitutions), then one compiled-
# pattern search per entry of _CHECK_67_DEFERRED_PATTERNS over that masked
# copy — the tuple below is separate patterns, NOT one alternation, and a
# list comprehension evaluates every element, so there is no short-circuit.
# The mask is HOISTED out of that comprehension: called inside it, a pure
# function would be re-derived once per pattern for a byte-identical result.
# Plus one allowlist parse, an O(snippets) covered() scan only on a line that
# already matched, and an O(records) backing set-difference at the end. No
# subprocess, no whole-tree scan. Bounded to the IN set, whose read shape it
# shares with Check 65.

_CHECK_67_DEFERRED_PATTERNS = (
    ("deferred",        re.compile(r"\bdeferred\b", re.I)),
    ("future-version",  re.compile(r"future (pack )?version|future release|in a future", re.I)),
    ("coming",          re.compile(r"\bcoming soon\b", re.I)),
    ("not-yet",         re.compile(r"\bnot yet (created|implemented|built|shipped)\b", re.I)),
    ("lands-ships",     re.compile(r"once .{0,40}\b(land|lands|ship|ships)\b", re.I)),
    ("roadmap",         re.compile(r"\broadmap\b", re.I)),
    ("planned-post",    re.compile(r"\bplanned post\b|currently planned post", re.I)),
    ("will-ship",       re.compile(r"\bwill ship\b", re.I)),
    ("vnext",           re.compile(r"v11\.1|v11\.x")),
    ("slated",          re.compile(r"\bslated\b", re.I)),
    ("expected-offer",  re.compile(r"\bexpected to offer\b", re.I)),
)


# The span/link mask (see SPAN MASK above). _check_67_mask_spans has exactly
# ONE call site — the marker search inside
# check_operating_doc_no_deferred_feature — and that scoping is load-bearing.
_CHECK_67_MASK_CODE_SPAN = re.compile(r"`[^`\n]*`")
_CHECK_67_MASK_LINK_TARGET = re.compile(r"\]\([^)\n]*\)")


def _check_67_mask_spans(line: str) -> str:
    """Blank inline code spans and Markdown link targets in one line.

    Line length is NOT preserved — the only consumer is a position-independent
    regex search. A code span is replaced by a SPACE rather than deleted so the
    words on either side stay separate tokens; the word-boundary anchors in
    _CHECK_67_DEFERRED_PATTERNS depend on that separation.
    """
    return _CHECK_67_MASK_LINK_TARGET.sub(
        "]()", _CHECK_67_MASK_CODE_SPAN.sub(" ", line)
    )




def _check_67_load_allowlist() -> dict:
    """Parse pack-ops/.operating-doc-deferred-feature-allowlist.txt into
    {doc: [snippet, ...]}.

    Each record carries `doc:`, `snippet:`, `reason:`. The matching key is
    (doc, snippet-substring) — line numbers are NOT used (they drift). Clone of
    _check_65_load_allowlist; reuses _parse_manifest_records()."""
    allowlist_path = (
        REPO_ROOT / "pack-ops"
        / ".operating-doc-deferred-feature-allowlist.txt"
    )
    if not allowlist_path.is_file():
        return {}
    records = _parse_manifest_records(allowlist_path.read_text())
    by_doc: dict = {}
    for rec in records:
        doc = rec.get("doc")
        snippet = rec.get("snippet")
        if doc and snippet:
            by_doc.setdefault(doc, []).append(snippet)
    return by_doc




def check_operating_doc_no_deferred_feature() -> None:
    """Check 67 (Gate 2) — operating-doc deferred-feature recall gate (BD-243).

    Scans the operating-doc IN set (_iter_operating_docs) for deferred-feature
    markers (deferred / future version / coming soon / not-yet-created / once X
    lands|ships / roadmap / planned post / will ship / v11.1|v11.x / slated /
    expected to offer). THE TEETH: any matched line NOT cleared by a
    pack-ops/.operating-doc-deferred-feature-allowlist.txt record (doc match
    AND an allowlisted snippet is a substring of the line) FAILs — deferred-
    feature marker count must be 0 OUTSIDE the allowlist.

    The marker scan reads a span/link-MASKED copy of each line
    (_check_67_mask_spans), so a deferral word that is a NAME inside a code
    span or a link target is not an advert. covered() and the failure message
    read the RAW line — see the SPAN MASK block above for why that scoping is
    load-bearing.

    A RECALL gate, not precision (no regex decides "is this feature shipped?").
    The human adjudicates each hit: STRIP it (it advertises a deferred pack
    feature) OR add an allowlist record (a live workflow / generic advice / the
    rule itself). The allowlist is sized to the measured KEEP set EXACTLY
    (measure-then-bound) — never widened to admit a contamination hit.

    Per DESIGN-BD-243-DURABLE-GATES.md §3 Gate 2.

    Lenient mode: an IN doc absent at HEAD SKIPs that doc; a missing allowlist
    file means an empty allowlist (every marker hit then FAILs — fail-loud).
    """
    print(
        "\n── Check 67: operating-doc deferred-feature recall gate (BD-243) ──"
    )

    allowlist = _check_67_load_allowlist()

    any_fail = False
    scanned_docs = 0
    total_outside = 0
    total_allowlisted = 0

    # DEAD-RECORD TRACKING (declare-verify-backing), the twin of Check 65's
    # leg. This allowlist also declares itself "sized to the KEEP set
    # EXACTLY", and nothing verified a record still matches anything. The
    # span mask makes that worse, not better: wrapping an exempted word in
    # backticks now hides the line from the marker scan, so the record that
    # cleared it silently stops firing and sits here as dead weight.
    # Recording which records actually FIRE makes the sizing claim
    # load-bearing.
    #
    # ADVISORY ONLY, never a gate: a record can be legitimately un-triggered
    # (its doc absent at HEAD, or momentarily outside the IN set), so a hard
    # FAIL here would red CI on a false positive.
    scanned_doc_set: set = set()
    used_records: set = set()

    for doc_rel in _iter_operating_docs():
        doc_path = REPO_ROOT / doc_rel
        if not doc_path.is_file():
            ok(f"{doc_rel} absent — skipping that doc (lenient)")
            continue
        scanned_docs += 1
        scanned_doc_set.add(doc_rel)
        snippets = allowlist.get(doc_rel, [])
        lines = doc_path.read_text().splitlines()

        for lineno, line in enumerate(lines, start=1):
            # MASKED — a deferral word inside a code span / link target is a
            # name, not an advert. The mask stops here: covered() and the
            # fail() message below both read the RAW line (see SPAN MASK).
            # Hoisted OUT of the comprehension deliberately: the mask is pure,
            # so calling it inside would re-derive the same string once per
            # pattern (ci-check-runtime-compounding).
            masked = _check_67_mask_spans(line)
            matched = [
                name for name, rx in _CHECK_67_DEFERRED_PATTERNS
                if rx.search(masked)
            ]
            if not matched:
                continue
            # UNMASKED on purpose (see SPAN MASK). Iterate rather than
            # `any(...)`: the short-circuit would hide a second snippet that
            # also covers this line and mis-report its record as dead below.
            # Cost is O(snippets), and only on a line that already matched.
            covered = False
            for snip in snippets:
                if snip in line:
                    covered = True
                    used_records.add((doc_rel, snip))
            if covered:
                total_allowlisted += 1
                continue
            total_outside += 1
            any_fail = True
            fail(
                f"{doc_rel}:{lineno} — operating-doc deferred-feature marker "
                f"{matched} OUTSIDE the allowlist: `{line.strip()[:90]}`. Per "
                f"BD-243 Gate 2, an operating doc must not ADVERTISE a deferred "
                f"/ unimplemented / future-version FEATURE (state only what "
                f"currently exists and operates; the mention is re-added when "
                f"the feature ships). Remediation: STRIP the deferred-feature "
                f"mention OR, if this documents a LIVE workflow / generic "
                f"client-product advice / the rule itself, add a pack-ops/"
                f".operating-doc-deferred-feature-allowlist.txt record (doc + a "
                f"snippet + a reason a reviewer re-verifies). The allowlist is "
                f"sized to the KEEP set EXACTLY and MUST NOT be widened to "
                f"admit this hit."
            )

    # O(records) set difference — no extra file read, no subprocess, no
    # tree walk (ci-check-runtime-compounding).
    declared = {(d, s) for d, snips in allowlist.items() for s in snips}
    dead = sorted(
        r for r in declared if r[0] in scanned_doc_set and r not in used_records
    )
    unscanned = sorted(r for r in declared if r[0] not in scanned_doc_set)

    for doc_rel, snip in dead:
        warn(
            f"Check 67 allowlist — record `doc: {doc_rel}` / "
            f"`snippet: {snip}` matched NO line in that doc. The allowlist "
            f"is declared 'sized to the KEEP set EXACTLY', so a record that "
            f"never fires is dead weight: either the line it exempted was "
            f"edited/removed (drop the record), the snippet drifted "
            f"(re-anchor it), or the marker now sits inside a code span / "
            f"link target and the span mask exempts the line without it. "
            f"Advisory only — exit code unaffected."
        )
    for doc_rel, snip in unscanned:
        warn(
            f"Check 67 allowlist — record `doc: {doc_rel}` / "
            f"`snippet: {snip}` names a doc outside the scanned operating-doc "
            f"IN set (absent at HEAD, or not an IN doc), so the record can "
            f"never fire. Advisory only — exit code unaffected."
        )

    if not any_fail:
        ok(
            f"Check 67 — {scanned_docs} operating doc(s) scanned; "
            f"{total_outside} deferred-feature marker(s) outside the allowlist "
            f"(0 = clean); {total_allowlisted} allowlisted KEEP occurrence(s) "
            f"admitted. Allowlist backing: {len(declared)} record(s) declared, "
            f"{len(used_records)} live, {len(dead)} dead, {len(unscanned)} on "
            f"unscanned docs."
        )




# ── Check 68 (Gate 3): dangling-reference gate (BD-243) ────────────────────
# WHAT IT CATCHES (DESIGN-BD-243-DURABLE-GATES.md §3 Gate 3): a file/path
# reference in an operating doc (and the deliverable surface) whose target does
# NOT exist — a dead pointer. Generalizes Check 64's existence-precedent from
# the 3-member `.example` family to the full file-reference surface. This is the
# axis that let deleted-doc refs (HELP-FRAGMENT-TRACKER, the
# feedback_review_fix_one_cycle.md ref) slip past CI.
#
# REF EXTRACTION (reuse Check 40's machinery, no new regex risk): (1) backtick
# bare-ref via _CHECK_40_BARE_REF_PATTERN; (2) markdown hyperlink via
# _CHECK_40_HYPERLINK_PATTERN; (3) the ONE new bounded qualified-path pattern
# _CHECK_68_QUALIFIED_PATH_PATTERN (`dir/.../FILE.ext`, >=1 slash — the shape
# Check 40's `/`-exclusion DELIBERATELY misses, exactly where deleted-doc refs
# hid). All run AFTER _strip_code_blocks() (fenced/indented code is not a prose
# citation).
#
# EXISTENCE CHECK: a QUALIFIED-path ref resolves through a 3-leg
# install-path-aware ladder, in this order — (1) DIRECT: <path> is git-TRACKED;
# (2) leg A: project-template/<path> is git-TRACKED, the client-install prefix,
# so a client-audience relative path that resolves at an install resolves here
# too; (3) leg B: <path> is a `_CLIENT_INSTALLED_FILES` DEST whose pack-storage
# SOURCE is git-TRACKED (_client_install_dest_to_source). Every leg tests the
# TRACKED set, never the filesystem (`ci-guard-measure-then-bound`), so the
# verdict is identical on a developer box and on a fresh CI clone. The
# ladder is install-path-aware, NOT citer-audience-aware: leg A is an
# unconditional union, deliberately un-scoped by citing tree.
# A BARE ref resolves if its basename is in the once-built basename index —
# bareness is a different axis and that leg is unchanged.
# A ref within the _CHECK_40_ANCHOR_PHRASES window ("archived"/"does not
# exist"/"post-install") is intentional non-existence, auto-cleared. A ref that
# clears NO resolution leg AND is not anchor-cleared AND is not on
# pack-ops/.dangling-ref-allowlist.txt FAILs.
#
# WHY THE QUALIFIED LEG IS NOT BASENAME-MATCHED: resolving `a/b/DOC.md` because
# SOME `DOC.md` exists anywhere in the tree makes the gate blind to a MOVED
# file — the reference keeps pointing at a path that no longer holds anything
# and the guard stays green. The leg order above is load-bearing; in
# particular the allowlist escape stays BELOW every resolution leg.
#
# measure-then-bound: the allowlist is sized EXACTLY to the measured
# intentional-non-existence KEEP set (grammar patterns, deleted/retired
# monolith names + Wave-D-pending project-monolith path refs,
# self-flagged retired/declined/orphan, runtime outputs, template placeholders,
# out-of-repo memory files, teaching/example client paths). The genuine
# residual dangling ref (feedback_review_fix_one_cycle.md) is FIXED at
# CG-14-prep-b, not allowlisted.
#
# RUNTIME COST (ci-check-runtime-compounding): one pass over the IN set + the
# Check-64 deliverable trees, extracting refs (3 compiled patterns) and
# resolving each against a basename index BUILT ONCE (_build_basename_index,
# the same builder Check 40 uses) plus an install-map reverse index parsed ONCE
# (~0.13 ms). ONE `git ls-files` serves both the index and the deliverable-tree
# walk. No per-ref subprocess, no per-entry storm, no filesystem walk of the
# deliverable trees.

# The ONE new bounded pattern: a backtick qualified-path ref (>=1 slash), first
# char [A-Za-z] (so a `.dotfile` qualified ref is out of scope — Check 64 owns
# the leading-dot `.example` family). Same extension class as Check 40.
_CHECK_68_QUALIFIED_PATH_PATTERN = re.compile(
    r"`([A-Za-z][\w./-]*/[\w.-]+\.(?:" + _CHECK_40_FILE_EXTS + r"))`"
)



# The operating-doc IN set is auto-discovered (_iter_operating_docs); the
# deliverable surface mirrors Check 64's INCLUDE. EXCLUDE: history-home +
# pack-only stores + fixtures (the per-entry BD/changelog bodies are history,
# not a citation surface).
_CHECK_68_INCLUDE_TREES = ("project-template", "supporting-docs")


# The two history-tree members are ENTRY-shaped, not TREE-shaped, and that is
# deliberate: a per-entry BODY is history and stays out of scope, but each
# tree's `_rules.md` write-contract is an ACTIVE citation surface and belongs
# on this EXISTENCE axis. `changelog/v` admits `changelog/_rules.md` exactly as
# `backlog/BD-` already admits `backlog/_rules.md` — the two are symmetric.
# A gate on a DIFFERENT axis over the same trees may legitimately exclude them
# wholesale; do not harmonize this constant to that shape.
_CHECK_68_EXCLUDE_PREFIXES = (
    "changelog/v",
    "backlog/BD-",
    "maintenance-docs/",
    "test-fixtures/",
    "scripts/tests/fixtures/",
    ".git/",
)




def _check_68_load_allowlist() -> set:
    """Parse pack-ops/.dangling-ref-allowlist.txt into a set of allowlisted
    tokens (the exact dangling references that are non-existent BY DESIGN).

    Each record carries `token:` + `reason:`. Returns the set of tokens.
    Reuses _parse_manifest_records()."""
    allowlist_path = REPO_ROOT / "pack-ops" / ".dangling-ref-allowlist.txt"
    if not allowlist_path.is_file():
        return set()
    records = _parse_manifest_records(allowlist_path.read_text())
    return {rec["token"] for rec in records if rec.get("token")}




def check_dangling_file_refs() -> None:
    """Check 68 (Gate 3) — dangling-reference gate (BD-243).

    Extracts file/path references (backtick bare-ref, markdown hyperlink, and
    the new qualified-path backtick) from the operating-doc IN set + the
    Check-64 deliverable surface (README + project-template/** +
    supporting-docs/**, minus EXCLUDE), and FAILs on any reference whose target
    does not exist — a dead pointer. Generalizes Check 64's existence gate.

    Reuses Check 40's extraction (_strip_code_blocks, the bare-ref/hyperlink
    regex, the _CHECK_40_ANCHOR_PHRASES self-flagging-non-existence window, the
    _build_basename_index index). A QUALIFIED ref resolves through the 3-leg
    install-path-aware ladder — the git-TRACKED path itself, then the
    `project-template/` client-install prefix, then the
    `_CLIENT_INSTALLED_FILES` dest->source reverse map
    (_client_install_dest_to_source) — and NEVER by bare basename, which would
    make the gate blind to a moved file. A BARE ref resolves by basename-index
    membership (unchanged). An anchor-windowed ref is intentional non-existence
    (auto-cleared); else the allowlist
    (pack-ops/.dangling-ref-allowlist.txt, token-keyed) must clear it.

    Every RESOLUTION leg is git-TRACKED (`ci-guard-measure-then-bound`): the
    basename index and the three qualified legs read the same one
    `git ls-files` result, so an untracked artifact can never resolve a
    reference. The SCANNED set is tracked for the deliverable trees only — its
    operating-doc half (`_iter_operating_docs()`'s family globs, shared with
    Checks 65/67/69) and the README literal are filesystem-based, so an
    untracked file in a globbed family location IS scanned. Polarity is
    benign: that can only add scrutiny locally, never remove it, and a fresh
    CI clone carries no untracked files.

    Per DESIGN-BD-243-DURABLE-GATES.md §3 Gate 3.

    measure-then-bound: the allowlist is sized to the measured intentional-non-
    existence KEEP set EXACTLY — never widened to admit a real dead pointer. A
    reviewer re-verifies each token's `reason:`.

    Lenient mode: a file unreadable (binary/decode error) is skipped silently;
    a missing allowlist means an empty allowlist (every unresolved ref then
    FAILs — fail-loud).
    """
    print("\n── Check 68: dangling-reference gate (BD-243) ──")

    allowlist = _check_68_load_allowlist()
    # ONE `git ls-files` feeds BOTH the basename index and the deliverable-tree
    # walk below (ci-check-runtime-compounding).
    rels = _git_tracked_relpaths()
    index = _build_basename_index(rels) if rels is not None else None
    if index is None:
        ok("git unavailable (not a git work tree) — skipping (lenient)")
        return
    # Both built ONCE, before the file loop — never per line, never per ref.
    # `tracked` is a SET: the qualified ladder does up to 3 membership tests per
    # reference, and a list scan there would be O(refs x tracked-files).
    tracked = set(rels)
    dest_to_source = _client_install_dest_to_source()
    anchor_window = _CHECK_40_ANCHOR_WINDOW

    def _excluded(rel_posix: str) -> bool:
        return any(rel_posix.startswith(p) for p in _CHECK_68_EXCLUDE_PREFIXES)

    def _has_anchor(lines: list, lineno: int) -> bool:
        start = max(0, lineno - 1 - anchor_window)
        end = min(len(lines), lineno - 1 + anchor_window + 1)
        for i in range(start, end):
            for anchor in _CHECK_40_ANCHOR_PHRASES:
                if anchor in lines[i]:
                    return True
        return False

    # Build the scope file set: operating-doc IN set ∪ deliverable surface.
    scope: set = set()
    for rel in _iter_operating_docs():
        if not _excluded(rel):
            scope.add(rel)
    readme = REPO_ROOT / "README.md"
    if readme.is_file():
        scope.add("README.md")
    for tree in _CHECK_68_INCLUDE_TREES:
        prefix = tree + "/"
        for rel_posix in rels:
            if rel_posix.startswith(prefix) and not _excluded(rel_posix):
                scope.add(rel_posix)

    any_fail = False
    files_scanned = 0
    refs_checked = 0
    resolved = 0
    anchor_cleared = 0
    allowlisted = 0

    for rel in sorted(scope):
        path = REPO_ROOT / rel
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        files_scanned += 1
        stripped = _strip_code_blocks(text)
        for lineno, line in enumerate(stripped, start=1):
            # collect (token, is_qualified) per line
            tokens = []
            for m in _CHECK_68_QUALIFIED_PATH_PATTERN.finditer(line):
                tokens.append((m.group(1), True))
            for m in _CHECK_40_BARE_REF_PATTERN.finditer(line):
                tokens.append((m.group(1), False))
            for m in _CHECK_40_HYPERLINK_PATTERN.finditer(line):
                tokens.append((m.group(1), False))
            if not tokens:
                continue
            for token, is_qualified in tokens:
                refs_checked += 1
                # Existence resolution. Leg order is load-bearing: direct ->
                # client-install prefix -> install-map reverse -> anchor ->
                # allowlist -> FAIL. Never hoist the allowlist escape above a
                # resolution leg, and never resolve a QUALIFIED path by bare
                # basename (that is what made a moved file invisible). Every
                # qualified leg tests git-TRACKED membership, never the
                # filesystem: an untracked artifact present on a developer box
                # but absent from a fresh clone must not resolve a reference.
                if is_qualified:
                    if token in tracked:
                        resolved += 1
                        continue
                    if "project-template/" + token in tracked:
                        resolved += 1
                        continue
                    src = dest_to_source.get(token)
                    if src and src in tracked:
                        resolved += 1
                        continue
                else:
                    if token in index:
                        resolved += 1
                        continue
                # intentional-non-existence anchor window
                if _has_anchor(stripped, lineno):
                    anchor_cleared += 1
                    continue
                # explicit allowlist
                if token in allowlist:
                    allowlisted += 1
                    continue
                any_fail = True
                fail(
                    f"{rel}:{lineno} — dangling reference `{token}`: the cited "
                    f"target is not a git-TRACKED file (for a qualified "
                    f"path also no `project-template/` client-install prefix "
                    f"and no `_CLIENT_INSTALLED_FILES` dest->source match; no "
                    f"self-flagging anchor). An UNTRACKED file present on your "
                    f"box does NOT resolve a reference — CI would not see it. "
                    f"Per BD-243 Gate 3, a file/path "
                    f"reference in an operating doc / deliverable must resolve "
                    f"to an existing target. NOTE: a qualified path is NOT "
                    f"resolved by bare basename — if the target MOVED, correct "
                    f"the path; a same-named file elsewhere does not clear it. "
                    f"Remediation: restore/correct the "
                    f"target OR drop the cite OR, if it is non-existent BY "
                    f"DESIGN (a filename/path grammar pattern, a regenerated "
                    f"mirror, a self-flagged retired/declined ref, a runtime-"
                    f"generated output, a template placeholder, an out-of-repo "
                    f"memory file, or a teaching example path), add a "
                    f"pack-ops/.dangling-ref-allowlist.txt record (token + a "
                    f"reason a reviewer re-verifies). The allowlist is sized to "
                    f"the KEEP set EXACTLY and MUST NOT be widened to admit a "
                    f"real dead pointer."
                )

    if not any_fail:
        ok(
            f"Check 68 — {files_scanned} file(s) scanned; {refs_checked} "
            f"file/path reference(s) checked; {resolved} resolved, "
            f"{anchor_cleared} self-flagged-non-existent (anchor-cleared), "
            f"{allowlisted} allowlisted (non-existent by design); 0 dangling "
            f"outside the allowlist (complete)."
        )




# ── Check 70 (parity): shipped client doc-gate structural parity (BD-243) ──
# DESIGN-BD-243-CLIENT-GATE.md §C.3 (the parity check that polices the shipped
# client gate). The pack ships a CLIENT-side operating-doc enforcement gate
# `project-template/scripts/validate-docs.sh` (the dual-surface mirror of the
# pack's own validate-pack gates). validate-pack.py never ships, so without a
# pack-side guard the shipped gate could silently vanish or lose an axis over
# pack versions. Check 70 asserts STRUCTURAL parity (presence / executable /
# axis-coverage / wiring), NOT behavioral parity — behavioral parity would be a
# maintenance trap. This is the legitimate dependency direction: a PACK
# operation READS a client deliverable to police it (it never EDITS the gate,
# never makes the gate a runtime dependency of a pack op). The 6 client axes
# the gate must declare (axis-marker comments it carries):
#   # AXIS: history   # AXIS: deferred   # AXIS: bloat   # AXIS: dangling
#   # AXIS: conformance   # AXIS: session-state
_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"


_CHECK_70_AXIS_MARKERS = (
    "# AXIS: history",
    "# AXIS: deferred",
    "# AXIS: bloat",
    "# AXIS: dangling",
    "# AXIS: conformance",
    "# AXIS: session-state",
)


_CHECK_70_WIRING_FILES = (
    "project-template/scripts/validate.sh",
    "project-template/scripts/agent-post-edit-check.sh",
)




def check_client_doc_gate_parity() -> None:
    """Check 70 (parity) — shipped client doc-gate structural parity (BD-243).

    Asserts the shipped client operating-doc enforcement gate
    `project-template/scripts/validate-docs.sh` (a) EXISTS, (b) is executable,
    (c) declares EXACTLY the constant's axis-markers
    (`# AXIS: history|deferred|bloat|dangling|conformance|session-state`),
    and (d) is wired into the shipped `validate.sh` +
    `agent-post-edit-check.sh`.
    STRUCTURAL parity only (presence / executable / axis-coverage / wiring) —
    NOT behavioral (the two gates re-implement the same logic per DC-1; drift is
    mitigated by the shared trinity rule-text anchor + THIS presence guard, not
    a behavioral comparison that would be a maintenance trap).

    Axis-coverage is a BIDIRECTIONAL set-equality bijection between
    `_CHECK_70_AXIS_MARKERS` and the gate's `# AXIS: <marker>` declarations:
    forward — a constant marker absent from the gate FAILs; reverse — a gate
    `# AXIS:` marker absent from the constant FAILs. The gate's `# AXIS:`
    grammar is a clean delimited extraction (one marker per line,
    `# AXIS: <marker>` regex-extractable), so the reverse leg is non-brittle.
    A future pack version that adds/removes a client axis updates BOTH the gate
    and `_CHECK_70_AXIS_MARKERS` in the same change.

    Dependency direction (dependency-direction-placement): this is a PACK check
    that READS the project-template client deliverable to police it — the
    legitimate direction (a pack op reads a client deliverable for
    verification). It NEVER edits the gate and NEVER makes the gate a runtime
    dependency of a pack operation.

    Per DESIGN-BD-243-CLIENT-GATE.md §C.3 + PLAN-BD-243-FINAL-V4.md §3.3.
    No lenient mode — the check runs against the live shipped deliverable.

    Lenient mode: the gate file WHOLLY ABSENT SKIPs (an init/state problem, not
    a parity violation — mirrors the lenient-absent posture of the other gates);
    a PRESENT-but-incomplete gate (not executable / missing an axis / not wired)
    FAILs (the teeth).
    """
    print(
        "\n── Check 70: shipped client doc-gate structural parity (BD-243) ──"
    )

    gate_path = REPO_ROOT / _CHECK_70_CLIENT_GATE
    if not gate_path.is_file():
        ok(
            f"{_CHECK_70_CLIENT_GATE} absent — skipping (lenient; the shipped "
            f"client gate is an init/state artifact when absent, not a parity "
            f"violation). When present it must be executable, declare exactly "
            f"the {len(_CHECK_70_AXIS_MARKERS)} axis-markers (bidirectional "
            f"set-equality), and be wired into validate.sh + "
            f"agent-post-edit-check.sh."
        )
        return

    any_fail = False

    # (b) executable
    if not os.access(gate_path, os.X_OK):
        any_fail = True
        fail(
            f"{_CHECK_70_CLIENT_GATE} — the shipped client doc-gate exists but "
            f"is NOT executable. Per BD-243 the gate must ship executable "
            f"(install runs `chmod +x scripts/*.sh`, but the committed source "
            f"must carry the executable bit). Remediation: `chmod +x "
            f"{_CHECK_70_CLIENT_GATE}`."
        )

    gate_text = gate_path.read_text(encoding="utf-8", errors="replace")

    # (c) axis-coverage — BIDIRECTIONAL set-equality bijection between the
    # constant and the gate's `# AXIS: <marker>` declarations.
    constant_axes = {m.split(": ", 1)[1] for m in _CHECK_70_AXIS_MARKERS}
    gate_axes = set(re.findall(r"# AXIS: ([a-z-]+)", gate_text))

    # (c-forward) a constant marker absent from the gate FAILs (the gate
    # dropped/renamed an axis the constant still expects).
    missing_axes = sorted(constant_axes - gate_axes)
    if missing_axes:
        any_fail = True
        fail(
            f"{_CHECK_70_CLIENT_GATE} — the shipped client doc-gate is missing "
            f"axis-marker(s): {['# AXIS: ' + a for a in missing_axes]}. Per "
            f"DESIGN-BD-243-CLIENT-GATE.md §C.3 the gate must declare exactly "
            f"the {len(constant_axes)} axes "
            f"({sorted(constant_axes)}) as `# AXIS: <axis>` marker "
            f"comments so this parity check can confirm axis-coverage "
            f"structurally. Remediation: restore the dropped axis (its matcher "
            f"+ its `# AXIS:` marker) in the gate; a future pack version that "
            f"adds/removes a client axis updates BOTH the gate and "
            f"_CHECK_70_AXIS_MARKERS in the same change."
        )

    # (c-reverse) a gate `# AXIS:` marker absent from the constant FAILs (the
    # gate added an axis the constant has not tracked — the reverse-drift the
    # one-way floor used to miss). The gate's `# AXIS:` grammar is a clean
    # delimited extraction, so this leg is non-brittle.
    extra_axes = sorted(gate_axes - constant_axes)
    if extra_axes:
        any_fail = True
        fail(
            f"{_CHECK_70_CLIENT_GATE} — the shipped client doc-gate declares "
            f"`# AXIS:` marker(s) NOT tracked by _CHECK_70_AXIS_MARKERS: "
            f"{['# AXIS: ' + a for a in extra_axes]}. Axis-coverage is a "
            f"BIDIRECTIONAL set-equality bijection: a gate axis the constant "
            f"does not list is a reverse divergence. Remediation: add the new "
            f"axis ({['# AXIS: ' + a for a in extra_axes]}) to "
            f"_CHECK_70_AXIS_MARKERS, or remove it from the gate; the gate and "
            f"_CHECK_70_AXIS_MARKERS must change in the same commit."
        )

    # (d) wired into validate.sh + agent-post-edit-check.sh
    gate_basename = Path(_CHECK_70_CLIENT_GATE).name
    for wiring_rel in _CHECK_70_WIRING_FILES:
        wiring_path = REPO_ROOT / wiring_rel
        if not wiring_path.is_file():
            any_fail = True
            fail(
                f"{wiring_rel} — the shipped client wiring host is MISSING, so "
                f"the doc-gate cannot be wired into it. Per BD-243 "
                f"{gate_basename} must be invoked from both validate.sh (the "
                f"full-run path) and agent-post-edit-check.sh (the per-`.md`-"
                f"edit fast path)."
            )
            continue
        wiring_text = wiring_path.read_text(encoding="utf-8", errors="replace")
        if gate_basename not in wiring_text:
            any_fail = True
            fail(
                f"{wiring_rel} — the shipped client doc-gate {gate_basename} is "
                f"NOT wired into this host (no reference found). Per "
                f"DESIGN-BD-243-CLIENT-GATE.md §C.2 the gate runs via two hooks: "
                f"validate.sh (always-run full path) + agent-post-edit-check.sh "
                f"(per-`.md`-edit fast path). Remediation: re-add the "
                f"{gate_basename} invocation to {wiring_rel}."
            )

    if not any_fail:
        ok(
            f"Check 70 — {_CHECK_70_CLIENT_GATE} exists, is executable, "
            f"declares EXACTLY the {len(_CHECK_70_AXIS_MARKERS)} axis-markers "
            f"({', '.join(sorted(constant_axes))}) — bidirectional set-equality "
            f"with _CHECK_70_AXIS_MARKERS (no missing, no extra) — and is wired "
            f"into "
            f"{', '.join(Path(w).name for w in _CHECK_70_WIRING_FILES)} "
            f"(structural parity complete)."
        )




# ── Check 71: pack-root skill-mirror byte-identity (BD-243) ────────────────
# DESIGN-BD-243-SKILL-MIRROR-UNIFICATION.md §5.3. The user's binding ruling is
# that the pack skills MUST be byte-identical across all 3 CLIs. The canonical
# is `.claude/skills` (index 0); CB-04 reduces the canonical and byte-copies it
# to the `.codex`/`.agents` mirrors. This gate makes that invariant durable: a
# mirror that byte-diverges from the canonical FAILs. It composes with Check 65
# by the gate-the-canonical-once + assert-identity model — Check 65 scans the
# `.claude` canonical for history; Check 71 asserts the 2 mirrors are byte-equal
# to it, so the mirrors inherit cleanliness transitively (no triple-scan). NO
# allowlist: byte-identity is absolute (any divergence is a defect by the
# user's ruling). The dir set REUSES the pack-root subset Check 51 lists.
_CHECK_71_SKILL_MIRROR_DIRS = (
    ".claude/skills",
    ".codex/skills",
    ".agents/skills",
)




def check_pack_skill_mirror_identity() -> None:
    """Check 71 — pack-root skill-mirror byte-identity (BD-243).

    For each skill `<s>` in the canonical `.claude/skills`, compares the BYTES
    of `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md` to
    `.claude/skills/<s>/SKILL.md`. THE TEETH: any byte-difference (or a missing
    mirror file, or an extra mirror skill the canonical lacks) FAILs with the
    skill name + which mirror + a "re-propagate the reduced canonical"
    remediation.

    Why byte-identity (pattern-matching-out-of-context): pack SKILLS share ONE
    format (`SKILL.md` Markdown) across all 3 CLIs and the user ruled them
    identical, so byte-equality is the achievable, strongest, cheapest
    invariant. This is the WRONG property for AGENTS (3 different formats —
    md/toml/md — can never byte-equal), which keep Check 11 lenient parity +
    Check 56 semantic-verb-presence instead. Do not reuse this mechanism for
    agents.

    measure-then-bound: the gate is sized EXACTLY to the 3 pack-root mirror
    trees × the canonical skill set — no allowlist (byte-identity is absolute),
    no project mirrors (out of scope for this pack-root gate).

    Runtime cost (ci-check-runtime-compounding): reads the canonical once per
    skill + byte-compares the 2 mirror files — O(skill bytes), no regex, no
    subprocess, no whole-tree scan. Far cheaper than re-running Check 65's
    history regexes over 22 more files.

    Lenient mode: a WHOLLY-ABSENT mirror tree (a fresh-clone / init artifact)
    SKIPs that mirror with a note (mirrors Check 65's lenient-absent posture);
    a PRESENT mirror tree with a divergent/missing file FAILs (the teeth).
    """
    print("\n── Check 71: pack-root skill-mirror byte-identity (BD-243) ──")

    canonical_dir_rel = _CHECK_71_SKILL_MIRROR_DIRS[0]
    mirror_dirs_rel = _CHECK_71_SKILL_MIRROR_DIRS[1:]
    canonical_root = REPO_ROOT / canonical_dir_rel

    if not canonical_root.is_dir():
        ok(
            f"{canonical_dir_rel} absent — skipping (lenient; the canonical "
            f"skill tree is a fresh-clone/init artifact when absent, not an "
            f"identity violation)."
        )
        return

    # Canonical skill set: every <s> with a SKILL.md under .claude/skills.
    canonical_skills = sorted(
        p.parent.name
        for p in canonical_root.glob("*/SKILL.md")
        if p.is_file()
    )

    any_fail = False
    skills_checked = 0
    pairs_compared = 0
    mirrors_skipped = []

    for mirror_dir_rel in mirror_dirs_rel:
        mirror_root = REPO_ROOT / mirror_dir_rel
        if not mirror_root.is_dir():
            mirrors_skipped.append(mirror_dir_rel)
            ok(
                f"{mirror_dir_rel} tree absent — skipping that mirror (lenient; "
                f"a wholly-absent mirror tree is a fresh-clone/init artifact, "
                f"not a divergence)."
            )

    for skill in canonical_skills:
        canonical_file = canonical_root / skill / "SKILL.md"
        try:
            canonical_bytes = canonical_file.read_bytes()
        except OSError:
            continue
        skills_checked += 1
        for mirror_dir_rel in mirror_dirs_rel:
            mirror_root = REPO_ROOT / mirror_dir_rel
            if not mirror_root.is_dir():
                continue  # wholly-absent tree already reported lenient above
            mirror_file = mirror_root / skill / "SKILL.md"
            if not mirror_file.is_file():
                any_fail = True
                fail(
                    f"{mirror_dir_rel}/{skill}/SKILL.md — MISSING mirror file: "
                    f"the canonical {canonical_dir_rel}/{skill}/SKILL.md has no "
                    f"counterpart in this mirror. Per BD-243 the pack skills "
                    f"must be byte-identical across all 3 CLI mirrors. "
                    f"Remediation: re-propagate the reduced canonical "
                    f"(`cp {canonical_dir_rel}/{skill}/SKILL.md "
                    f"{mirror_dir_rel}/{skill}/SKILL.md`)."
                )
                continue
            pairs_compared += 1
            try:
                mirror_bytes = mirror_file.read_bytes()
            except OSError:
                continue
            if mirror_bytes != canonical_bytes:
                any_fail = True
                fail(
                    f"{mirror_dir_rel}/{skill}/SKILL.md — byte-DIVERGES from "
                    f"the canonical {canonical_dir_rel}/{skill}/SKILL.md "
                    f"({len(mirror_bytes)} vs {len(canonical_bytes)} bytes). "
                    f"Per DESIGN-BD-243-SKILL-MIRROR-UNIFICATION.md §5.3 the "
                    f"pack skills MUST be byte-identical across all 3 CLI "
                    f"mirrors (no allowlist — byte-identity is absolute). "
                    f"Remediation: re-propagate the reduced canonical "
                    f"(`cp {canonical_dir_rel}/{skill}/SKILL.md "
                    f"{mirror_dir_rel}/{skill}/SKILL.md`); NEVER hand-edit a "
                    f"mirror — reduce the canonical once and copy it."
                )

    # Extra-skill detection: a mirror skill the canonical lacks (the canonical
    # set is authoritative; an orphan mirror skill is a divergence too).
    canonical_set = set(canonical_skills)
    for mirror_dir_rel in mirror_dirs_rel:
        mirror_root = REPO_ROOT / mirror_dir_rel
        if not mirror_root.is_dir():
            continue
        mirror_skills = {
            p.parent.name
            for p in mirror_root.glob("*/SKILL.md")
            if p.is_file()
        }
        for orphan in sorted(mirror_skills - canonical_set):
            any_fail = True
            fail(
                f"{mirror_dir_rel}/{orphan}/SKILL.md — EXTRA mirror skill not "
                f"present in the canonical {canonical_dir_rel}. The canonical "
                f"skill set is authoritative; an orphan mirror skill is a "
                f"divergence. Remediation: drop the orphan mirror skill OR add "
                f"it to the canonical and re-propagate."
            )

    if not any_fail:
        skip_note = (
            f" ({len(mirrors_skipped)} mirror tree(s) absent — lenient SKIP)"
            if mirrors_skipped
            else ""
        )
        ok(
            f"Check 71 — {skills_checked} canonical skill(s) × "
            f"{len(mirror_dirs_rel)} mirror(s); {pairs_compared} mirror file(s) "
            f"byte-identical to the {canonical_dir_rel} canonical; 0 divergent "
            f"(complete){skip_note}."
        )




# ── Check 47: sanctioned pack-side-shipped freeze — EMPTY invariant (BD-195 C3d; BD-257) ──
# _SANCTIONED_PACK_SIDE_SHIPPED is FROZEN EMPTY: no pack-side file ships to
# clients (no-dual-use rule / dependency-direction-placement conjunct (c) —
# every client deliverable is its OWN project-template/ copy). This check
# CODE-ENFORCES three invariants:
#   (1) EMPTY invariant — a non-empty _SANCTIONED_PACK_SIDE_SHIPPED FAILS CI.
#       The set is SHRINK-ONLY and MAY NEVER GROW: there is NO admission path
#       and NO sign-off exception. Growth is FORBIDDEN, not gated.
#   (2) Set-equality freeze (install path 1) — the install map's pack-side
#       subset (non-project-template/, non-supporting-docs/ entries from
#       _CLIENT_INSTALLED_FILES) EQUALS _SANCTIONED_PACK_SIDE_SHIPPED exactly.
#       With the empty constant the map ships ZERO pack-side files; adding one
#       (the lazy `ship a new file from scripts/` path) FAILS CI.
#   (3) Migrator empty-ship (install path 2, BD-257) — the v10→v11 migrator
#       (scripts/migrate-v10-to-v11.sh) copies NO pack-side file into clients
#       across any of its declared copy vectors (direct `cp "$PACK/…"`, the
#       directory-sweep rows, the manifest rows). A pack-side source FAILS CI.
# A new client-shipped file's home is project-template/scripts/ — always. See
# ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.0/§8.2 for the
# dependency-direction rationale (§8.3's admission path is SUPERSEDED by
# BD-257 — growth forbidden).

# BD-257 — the migrator (second client-install path) copy-vector scan.
# scripts/migrate-v10-to-v11.sh reaches a client through three declared copy
# vectors: a direct `cp "$PACK/<path>" …`, the migrator_directory_sweeps rows,
# and the migrator_manifest rows. The no-dual-use rule forbids ANY pack-side
# source (outside project-template/ + supporting-docs/) on ANY vector.
_MIGRATOR_REL = "scripts/migrate-v10-to-v11.sh"

# Vector 1 — a direct `cp "$PACK/<path>" …` copy; group 1 is the pack-repo-
# relative source path.
_MIGRATOR_CP_PACK_SRC_RE = re.compile(r'cp\s+"\$PACK/([^"]+)"')


def _is_pack_side_ship_source(path: str) -> bool:
    """A migrator copy SOURCE is pack-side (a no-dual-use violation when copied
    into a client) UNLESS it lives under project-template/ or supporting-docs/
    (the two client-deliverable roots)."""
    return not (
        path.startswith("project-template/")
        or path.startswith("supporting-docs/")
    )


def _migrator_heredoc_first_fields(text: str, func_name: str) -> list:
    """Return the first whitespace-delimited field of each content row inside
    the `cat <<'EOF' … EOF` heredoc of the named migrator adapter hook
    (migrator_manifest / migrator_directory_sweeps). Blank + comment rows are
    skipped. Empty list if the function or its heredoc is absent."""
    fields: list = []
    fn = re.search(r"(?m)^" + re.escape(func_name) + r"\(\)\s*\{", text)
    if not fn:
        return fields
    # Bound the scan to THIS hook's own body. Unbounded, a hook that has no
    # heredoc of its own (the `{ :; }` empty form) runs on and returns the
    # NEXT hook's rows — a silently WRONG answer rather than an empty one,
    # which is the same false-confidence class both callers (Check 39 leg 3,
    # Check 47) exist to prevent. The body ends at the first column-0 `}` or
    # the next column-0 function definition, whichever comes first.
    rest_all = text[fn.end():]
    end = len(rest_all)
    for _bound in (r"(?m)^\}", r"(?m)^\w[\w.-]*\(\)\s*"):
        _m = re.search(_bound, rest_all)
        if _m and _m.start() < end:
            end = _m.start()
    body = rest_all[:end]
    opener = re.search(r"<<-?'?(\w+)'?\s*\n", body)
    if not opener:
        return fields
    marker = opener.group(1)
    rest = body[opener.end():]
    closer = re.search(r"(?m)^\s*" + re.escape(marker) + r"\s*$", rest)
    if not closer:
        return fields
    for row in rest[: closer.start()].splitlines():
        s = row.strip()
        if not s or s.startswith("#"):
            continue
        fields.append(s.split()[0])
    return fields


def _check_migrator_no_pack_side_client_copies() -> None:
    """Check 47 (BD-257) — the v10→v11 migrator must copy NO pack-side file
    into clients (install path 2). Scans scripts/migrate-v10-to-v11.sh across
    its three declared copy vectors; any source outside project-template/ +
    supporting-docs/ is a no-dual-use violation. Lenient-skip if the migrator
    is absent (mirrors the init-project.sh handling). O(lines): one file read +
    regex, no tree walk, no subprocess."""
    migrator = REPO_ROOT / _MIGRATOR_REL
    if not migrator.is_file():
        ok(f"{_MIGRATOR_REL} absent — skipping migrator copy scan (lenient)")
        return
    text = migrator.read_text(encoding="utf-8", errors="replace")
    offenders: list = []

    # Vector 1 — direct `cp "$PACK/<pack-side>"` copies (skip comment lines).
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            continue
        m = _MIGRATOR_CP_PACK_SRC_RE.search(line)
        if m and _is_pack_side_ship_source(m.group(1)):
            offenders.append(f"direct-cp:{m.group(1)}")

    # Vectors 2 + 3 — the declared directory-sweep + manifest copy rows.
    for func in ("migrator_directory_sweeps", "migrator_manifest"):
        for src in _migrator_heredoc_first_fields(text, func):
            if _is_pack_side_ship_source(src):
                offenders.append(f"{func}:{src}")

    if offenders:
        fail(
            f"{_MIGRATOR_REL} copies pack-side file(s) into clients "
            f"(no-dual-use rule / dependency-direction-placement conjunct (c) "
            f"— the ship-allowlist is EMPTY on BOTH install paths): "
            f"{sorted(offenders)}. A client deliverable must be its OWN "
            f"project-template/ (or supporting-docs/) file, never a pack-side "
            f"file copied into the client."
        )
        return
    ok(f"{_MIGRATOR_REL} copies NO pack-side file into clients (3 vectors clean)")


def check_sanctioned_pack_side_shipped() -> None:
    """Check 47 — sanctioned pack-side-shipped set freeze + EMPTY invariant
    (BD-195 C3d; BD-257 no-dual-use)."""
    print("\n── Check 47: sanctioned pack-side-shipped freeze (BD-195/BD-257) ──")

    # EMPTY invariant (BD-257 — CODE-enforced shrink-only floor). The
    # sanctioned set is frozen empty: no pack-side file ships to clients
    # (no-dual-use rule / dependency-direction-placement conjunct (c)). Growth
    # is FORBIDDEN — there is NO admission path and NO sign-off exception. A
    # non-empty constant is a hard CI failure regardless of install-map state
    # (this makes the empty floor a machine invariant, not merely rule text).
    if _SANCTIONED_PACK_SIDE_SHIPPED:
        fail(
            "_SANCTIONED_PACK_SIDE_SHIPPED must be EMPTY (no-dual-use rule): "
            "the set is frozen empty and SHRINK-ONLY — growth is FORBIDDEN, "
            "no admission, no sign-off exception. Non-empty value: "
            f"{sorted(_SANCTIONED_PACK_SIDE_SHIPPED)}. A client deliverable "
            "must be its OWN project-template/ copy, never a pack-side file "
            "reused as the client's copy."
        )
        return

    # Install path 2 (BD-257): the v10→v11 migrator must also ship ZERO
    # pack-side files. Runs independently of the init-project.sh install-map
    # check below — both enforce the same empty-ship invariant, one per client-
    # install path (the migrator scan is lenient-skipped if the migrator is
    # absent, exactly like the init-project.sh check).
    _check_migrator_no_pack_side_client_copies()

    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return

    entries, start_count, end_count, _, _ = _parse_client_installed_files()
    if start_count != 1 or end_count != 1:
        ok(
            "_CLIENT_INSTALLED_FILES markers not exactly-once — deferring to "
            "Check 41 (skipping set-equality)"
        )
        return

    # The ship-source set is the UNION of both install-map blocks: explicit
    # row sources AND GLOB-block source patterns. A pack-side source is
    # unsanctioned whether it is declared one file at a time or as a family —
    # checking only the explicit block would leave a family row (e.g.
    # `scripts/lib/*.sh -> scripts/lib/*.sh`) free to ship pack-side files.
    # Partitioned, not merged: the remediation must send the maintainer to the
    # block the offending row actually lives in. A union-only set would name a
    # family pattern while pointing at the EXPLICIT block, where it is not.
    glob_sources = [pat for pat, _dest, _st, _cls in _parse_client_installed_globs()]
    explicit_pack_side = {e for e in entries if _is_pack_side_ship_source(e)}
    glob_pack_side = {e for e in glob_sources if _is_pack_side_ship_source(e)}
    map_pack_side = explicit_pack_side | glob_pack_side
    frozen = set(_SANCTIONED_PACK_SIDE_SHIPPED)

    membership_test = (
        "_SANCTIONED_PACK_SIDE_SHIPPED is FROZEN EMPTY (no-dual-use rule / "
        "dependency-direction-placement conjunct (c)): no pack-side file ships "
        "to clients. The set is SHRINK-ONLY and MAY NEVER GROW — growth is "
        "FORBIDDEN, with NO admission path and NO sign-off exception. A client "
        "deliverable is ALWAYS its OWN project-template/ copy; a pack-side file "
        "a pack op depends on stays pack-side and unshipped."
    )

    if map_pack_side == frozen:
        ok(
            f"install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED "
            f"({len(frozen)} entr(ies)): {sorted(frozen)}"
        )
        return

    unsanctioned = sorted(map_pack_side - frozen)
    missing = sorted(frozen - map_pack_side)
    if unsanctioned:
        offenders = set(unsanctioned)
        blocks = []
        exp_off = sorted(offenders & explicit_pack_side)
        glob_off = sorted(offenders & glob_pack_side)
        if exp_off:
            blocks.append(
                f"the EXPLICIT block (_CLIENT_INSTALLED_FILES): {exp_off}"
            )
        if glob_off:
            blocks.append(
                f"the GLOB block (_CLIENT_INSTALLED_GLOBS): {glob_off}"
            )
        fail(
            f"the install map ships pack-side file(s) NOT in "
            f"_SANCTIONED_PACK_SIDE_SHIPPED: {unsanctioned}. Offending row(s) "
            f"live in {'; and '.join(blocks)} — delete the row from THAT block "
            f"in scripts/init-project.sh. {membership_test}"
        )
    if missing:
        fail(
            f"_SANCTIONED_PACK_SIDE_SHIPPED entr(ies) absent from the install "
            f"map: {missing}. A sanctioned file must ship (conjunct 2); if it "
            f"no longer ships, remove it from the frozen constant. {membership_test}"
        )



# ── __all__ — every Cluster A symbol (the facade re-exports via `import *`) ──
# Three-source union: owned `check_*` + every tested/cross-referenced private
# helper/constant + the intra-cluster symbols, so the facade `from
# validate_checks.boundary_refs import *` re-exports everything the registry +
# the per-check tests reach. (`_parse_manifest_records` is NOT listed — it is
# imported from core and re-exported by core's own `__all__`.)
__all__ = [
    "check_tracker_phase_task_invariants",
    "_SCOPE_KEYWORDS_PACK_ONLY",
    "_SCOPE_KEYWORDS_PROJECT_ONLY",
    "_SCOPE_KEYWORDS_PACK_CHAT_ONLY",
    "_PROJECT_SIDE_PATH_PREFIXES",
    "_SCOPE_NEUTRAL_GENERATED_PATHS",
    "_read_boundary_exempt_root",
    "_commits_to_walk",
    "_commit_paths",
    "_subject_has_keyword",
    "_is_pack_only_path",
    "_is_project_side_path",
    "_is_scope_neutral_generated",
    "_is_pack_chat_only_permitted",
    "check_commit_scope_honesty",
    "_DENY_LIST_FILENAMES",
    "_DENY_LIST_PATH_PREFIXES",
    "_DENY_LIST_AGENT_NAMES",
    "_DENY_LIST_ROLE_NAME",
    "_DENY_LIST_ANCHOR_PHRASES",
    "_DENY_LIST_ANCHOR_WINDOW",
    "_context_has_anchor",
    "_SANCTIONED_PACK_SIDE_SHIPPED",
    "_iter_client_installed_files",
    "_CHECK_37_COMPANION_TEMPLATE_DIRS",
    "_iter_project_side_files",
    "_CHECK_37_PER_LINE_FENCE_FILES",
    "_has_per_line_fence",
    "_FENCE_MARKER_START",
    "_FENCE_MARKER_END",
    "_line_is_fence_marker",
    "_build_fence_skip_lineset",
    "check_project_side_deny_list",
    "_CHECK_38_PACK_ROOT_SCAN_GLOB",
    "_CHECK_38_SIGNAL_THRESHOLD",
    "check_pack_only_file_siting",
    "_CHECK_39_EXEMPTIONS",
    "_CHECK_39_REVERSE_EXEMPTIONS",
    "_CHECK_39_MIGRATOR_EXEMPTIONS",
    "_parse_migrator_manifest_sources",
    "check_cmd_update_symmetry",
    "_CHECK_40_ALLOWLIST",
    "_CHECK_40_ANCHOR_PHRASES",
    "_CHECK_40_ANCHOR_WINDOW",
    "_CHECK_40_FILE_EXTS",
    "_CHECK_40_BARE_REF_PATTERN",
    "_CHECK_40_HYPERLINK_PATTERN",
    "_strip_code_blocks",
    "_CHECK_40_EXCLUDE_PARTS",
    "_git_tracked_relpaths",
    "_build_basename_index",
    "_check_40_context_has_anchor",
    "check_bare_pack_ops_refs",
    "_CHECK_43_ALLOWLIST",
    "_CHECK_43_ANCHOR_PHRASES",
    "_CHECK_43_ANCHOR_WINDOW",
    "_CHECK_43_PACK_INTERNAL_PREFIXES",
    "_CHECK_43_SELF_TREE_PREFIXES",
    "_CHECK_43_PACK_OPS_CLIENT_INSTALLED",
    "_CHECK_43_EXTRA_WALK_SUFFIXES",
    "_CHECK_43_PACK_ONLY_DOC_TREES",
    "_CHECK_43_COMMIT_SHA_PATTERN",
    "_CHECK_43_PROTO_TREE_PREFIX",
    "_check_43_proto_resolves_in_tree",
    "_build_pack_only_doc_basenames",
    "_build_bare_prose_alternation",
    "_CHECK_43_PACK_INTERNAL_PREFIX_PATTERNS",
    "_CHECK_43_SELF_TREE_PREFIX_PATTERNS",
    "check_project_side_bare_internal_refs",
    "_check_43_context_has_anchor",
    "_CHECK_41_EXEMPTIONS",
    "_CHECK_41_GLOB_LIST_EXEMPT",
    "_CHECK_41_LIST_LOOP_STAGES",
    "_CHECK_41_STAGE_SENTINELS",
    "_CHECK_41_COPY_VERB",
    "_parse_client_installed_files",
    "_parse_client_installed_file_stages",
    "_parse_client_installed_file_classes",
    "_customization_preserve_classes",
    "_CHECK_41_CLASS_SENTINELS",
    "_parse_client_installed_globs",
    "_install_glob_matches",
    "_client_install_dest_to_source",
    "check_client_installed_files",
    "_CHECK_OPERATING_DOC_FAMILIES",
    "_CHECK_OPERATING_DOC_EXEMPT",
    "_operating_doc_is_exempt",
    "_operating_doc_families",
    "_iter_operating_docs",
    "_CHECK_OPERATING_DOC_SCANNED_TREES",
    "_CHECK_OPERATING_DOC_OUT_OF_FAMILY",
    "check_operating_doc_scope_completeness",
    "_CHECK_65_FORBIDDEN_PATTERNS",
    "_CHECK_65_OPERATING_DOCS",
    "_check_65_load_allowlist",
    "check_operating_doc_no_history",
    "_CHECK_67_DEFERRED_PATTERNS",
    "_CHECK_67_MASK_CODE_SPAN",
    "_CHECK_67_MASK_LINK_TARGET",
    "_check_67_mask_spans",
    "_check_67_load_allowlist",
    "check_operating_doc_no_deferred_feature",
    "_CHECK_68_QUALIFIED_PATH_PATTERN",
    "_CHECK_68_INCLUDE_TREES",
    "_CHECK_68_EXCLUDE_PREFIXES",
    "_check_68_load_allowlist",
    "check_dangling_file_refs",
    "_CHECK_70_CLIENT_GATE",
    "_CHECK_70_AXIS_MARKERS",
    "_CHECK_70_WIRING_FILES",
    "check_client_doc_gate_parity",
    "_CHECK_71_SKILL_MIRROR_DIRS",
    "check_pack_skill_mirror_identity",
    "check_sanctioned_pack_side_shipped",
    "_CHECK_39_WHOLESALE_SCRIPTS",
    "_CHECK_39_PACK_VAR_ASSIGN",
    "_CHECK_39_WHOLESALE_USE",
    "_CHECK_39_WHOLESALE_MARKER",
    "_check_39_wholesale_roots",
    "_check_39_wholesale_marker_present",
]
