"""validate_checks.help_fragments — Cluster E: the trinity-addenda /
help-fragment family (BD-256 W6).

This module owns Cluster E's 3 check bodies (Checks 16, 22, 23) plus their
intra-cluster helpers and constants — the trinity `## Project addenda` H2 +
HTML-comment placeholder lock (16, generalized per BD-183 with a per-surface
exemption), the help-fragment freshness gate vs prose verb references (22), and
the help-fragment completeness gate vs `scripts/` executables (23). The three
are co-located because Checks 22 and 23 share the verb-shape regex `_VERB_RE`
and the `_is_pack_internal` marker scan, and Check 16 is the remaining
trinity-template structural gate that did not migrate with the Cluster C
trinity/agent-skill family at W4.

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.help_fragments
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name. Check 16 registers TWICE as a NAMED LAMBDA
(`check_trinity_addenda_h2[project-template]` / `[pack-root]`) — those lambdas
late-bind `check_trinity_addenda_h2` + `REPO_ROOT` from the facade's re-exported
globals, so the move keeps them resolving at invocation (V6 is the late-binding
catch). Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster E checks): the
Check-16 per-surface exemption set (`_CHECK_16_EXEMPT_SURFACES`), and the
Check-22/23 verb-regex + pack-internal-marker helpers (`_VERB_RE`,
`_PACK_INTERNAL_RE`, `_is_pack_internal`). None of these is read by a check
outside Cluster E (verified by grep at the extraction wave), so no core
promotion is needed — they are Cluster-E-owned, not a >=2-module seam. The
`# Check 21 RETIRED` breadcrumb that sat interstitially between
`check_trinity_addenda_h2` and `_VERB_RE` moves with the block verbatim to
preserve intra-module order; the parallel breadcrumb at the registry call-site
stays in the facade.

Spine + seams: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) are
imported `from .core` — the single SSOT for the spine + W1 seams. (`failures`
is imported for the V3 failures-identity invariant — `core.failures is
help_fragments.failures` — matching the W2–W5 module convention; the Cluster E
bodies append via `fail()`, never rebind `failures`.) Standard-library `re`,
`os`, and `Path` are imported directly at module top, mirroring the established
per-module convention (the spine `import *` does not re-export stdlib names).

See `scripts/lib/validate_checks/README.md` and
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
    failures,
)


# Surfaces where Check 16 (`## Project addenda` H2 + HTML-comment placeholder
# locking) does NOT apply. The mechanism is template-only infrastructure for
# Procedure 5-C.2 client reconciliation; surfaces that are NOT reconciled to
# client repos (e.g., pack-root trinity) have no `## Project addenda` H2 by
# design and the check short-circuits with an OK (exempt) message. Per
# BD-183 §2.4 Option (b) user-approved 2026-05-21.
_CHECK_16_EXEMPT_SURFACES: set[str] = {"pack-root"}


def check_trinity_addenda_h2(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 16 — v10 trinity templates carry `## Project addenda` H2
    with the HTML-comment placeholder (OQ-P6 / OQ-5C-1, BD-059 C9).

    The H2 is the landing point for project-original sections during
    Procedure 5-C.2 reconciliation. Locking it via this check prevents
    accidental future removal.

    Parameters:
        trinity_root: directory containing the 3 trinity files. Default
            `None` resolves to `REPO_ROOT / "project-template"`
            (preserves the original single-location behavior). Pass
            `REPO_ROOT` for the pack-root trinity location.
        label: human-readable surface name used in FAIL/OK messages
            and file-path prefixes. Examples: `"project-template"`,
            `"pack-root"`.

    Per BD-183 (Override 9 compliance, mirroring BD-181's Check 18
    generalization): Each invocation checks WITHIN its own trinity
    location only. There is NO cross-location coupling — pack-root
    and project-template trinity carry different audiences and
    different rules by design (per pack-root trinity § Rules →
    Trinity rule note paragraph). Call this function once per
    trinity location; the invocations are independent.

    Semantic scope (BD-183 §2.4 Option (b) — user-approved 2026-05-21):
    the `## Project addenda` H2 + HTML-comment placeholder marker is
    TEMPLATE-ONLY infrastructure tied to Procedure 5-C.2 reconciliation
    at client install / migration time. Surfaces that are NEVER
    reconciled (e.g., pack-root trinity — canonical ops-doc for
    pack-repo agents) have no `## Project addenda` H2 by design.
    Such surfaces are enumerated in `_CHECK_16_EXEMPT_SURFACES`
    (module-level constant immediately above this function). When the
    `label` parameter matches an exempt surface, this check short-
    circuits with an `OK (surface exempt)` message after printing
    its section header (so CI logs retain a uniform per-check
    structure). See IMPLEMENTATION-REPORT-BD-183.md §2.4 + §3.7 for
    the design record and the triage that landed Option (b).
    """
    # Sentinel pattern: callers in main() pass explicit (trinity_root, label).
    # `None` default kept for backward-compat with no-arg callers (test suite
    # / external use). Do not collapse to a literal default — call sites
    # declare their scope explicitly per BD-183 generalization design.
    if trinity_root is None:
        trinity_root = REPO_ROOT / "project-template"
    print(f"\n── Check 16 [{label}]: Trinity ## Project addenda H2 (BD-059, BD-183) ──")
    # Per-surface exemption (BD-183 §2.4 Option (b)): template-only check
    # short-circuits on surfaces that are NEVER reconciled to client repos.
    # See `_CHECK_16_EXEMPT_SURFACES` definition above for the exempt set.
    if label in _CHECK_16_EXEMPT_SURFACES:
        ok(f"[{label}] surface exempt — Check 16 is template-only "
           f"(`## Project addenda` mechanism has no purpose at non-reconciled "
           f"surface per BD-183 §2.4)")
        return
    any_failed = False
    for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        path = trinity_root / name
        if not path.is_file():
            fail(f"{label}/{name} — file missing")
            any_failed = True
            continue
        text = path.read_text()
        if "## Project addenda" not in text:
            fail(f"{label}/{name} — missing '## Project addenda' H2")
            any_failed = True
            continue
        if "<!-- Project addenda go here" not in text:
            fail(
                f"{label}/{name} — '## Project addenda' H2 present "
                f"but missing HTML-comment placeholder marker"
            )
            any_failed = True
            continue
        ok(f"[{label}] {name} — '## Project addenda' H2 with placeholder")
    if any_failed:
        return


# ── Check 21 RETIRED in BD-221 (Antigravity conversion) ──────────────────────
# `check_pack_help_per_cli_parity` is removed. pack-help is now an ordinary
# pooled skill (`project-template/skills/pack-help/SKILL.md`) distributed loose
# to all CLIs by init-project — there is no per-CLI parity triplet to enforce.
# The one load-bearing assertion ("the pack-help SKILL.md body references
# `scripts/pack-help.sh`") is FOLDED into Check 1 (SKILL.md frontmatter walk).
# The registry entry + the `CHECK_REGISTRY_EXPECTED_COUNT` were decremented in
# lock-step (61 → 59 with Check 28). No per-check test existed for Check 21.


# Shared pack-root help-fragment path (relative to REPO_ROOT), read by
# Checks 22, 23, and 89. RELATIVE on purpose: each reader resolves it as
# `REPO_ROOT / _HELP_FRAGMENT_PACK` at CALL time, so a per-check test that
# monkeypatches REPO_ROOT to a /tmp scratch repo still bites (an absolute
# `REPO_ROOT / "..."` bound here at import would freeze the real path).
_HELP_FRAGMENT_PACK = "pack-ops/HELP-FRAGMENT-PACK.md"


_VERB_RE = re.compile(
    # Match verb invocation shapes; existence-filter applied below to
    # filter project-template-only references and editorial mentions.
    # Allowed shapes:
    #   `pack <subcommand>[ <subcommand>]…`     — shell-verb form
    #   `/pack-<word>`                          — slash-command form
    #   `scripts/<path>.sh|.py`                 — explicit script path
    #   `<name>.sh` / `<name>.py`               — bare script name
    r"`(pack(?:\s\w+)+|/pack-\w+|scripts/[A-Za-z0-9._/-]+\.(?:sh|py)|[A-Za-z0-9][A-Za-z0-9._-]*\.(?:sh|py))`"
)
_PACK_INTERNAL_RE = re.compile(r"^#\s*pack-internal:\s*true\b", re.MULTILINE)


def _is_pack_internal(path: Path) -> bool:
    """Scan the first 2000 bytes of `path` for a `# pack-internal: true`
    marker. Used by Checks 22 and 23 to exempt internal helpers (CI test
    runners, migrator-only merge helpers) from user-facing-fragment rules.
    """
    try:
        head = path.read_text(errors="replace")[:2000]
    except OSError:
        return False
    return bool(_PACK_INTERNAL_RE.search(head))


def check_help_fragment_freshness() -> None:
    """Check 22 — Help-fragment freshness vs prose verb references (BD-082).

    Every verb-shape token (e.g. `pack help`, `/pack-help`, `pack tracker init`,
    `scripts/pack-help.sh`) referenced in the named user-facing docs must
    appear somewhere in the matching HELP-FRAGMENT*.md. Prevents prose
    docs drifting ahead of the help fragment.

    Conservative: only flags verbs that match the regex shape AND are
    absent from the fragment. Editorial mentions of unrelated commands
    are not flagged.

    Per surface: verbs are compared against that surface's own help
    fragment (no cross-surface concatenation).
    """
    print("\n── Check 22: Help-fragment freshness (BD-082) ──")
    # Per-surface fragment lookup per the surface dictionary; no
    # cross-surface concatenation.
    surfaces = {
        "pack-root": {
            "root": REPO_ROOT,
            "docs": [
                REPO_ROOT / "pack-ops" / "PACK-CHAT.md",
                REPO_ROOT / "QUICKSTART.md",
                REPO_ROOT / "pack-ops" / "OPTIONAL-FEATURES.md",
                REPO_ROOT / "supporting-docs" / "INSTALL-PROCEDURES.md",
            ],
            "fragment": REPO_ROOT / _HELP_FRAGMENT_PACK,
        },
        "project-template": {
            "root": REPO_ROOT / "project-template",
            "docs": [
                REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md",
            ],
            "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
        },
    }

    any_failed = False
    for surface, cfg in surfaces.items():
        frag = cfg["fragment"]
        if not frag.is_file():
            fail(f"{surface}: help fragment missing: {frag.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        frag_text = frag.read_text()
        surface_root = cfg["root"]
        verbs_referenced = set()
        for doc in cfg["docs"]:
            if not doc.is_file():
                continue
            for m in _VERB_RE.finditer(doc.read_text()):
                token = m.group(1)
                # Resolve script-shaped references against the surface
                # root so client-doc references resolve against the
                # client (project-template) tree, not the pack root.
                # Bare-name refs (e.g. `init-project.sh`) only count if
                # the file actually exists at scripts/<name> on the
                # surface — filters editorial mentions of names that
                # aren't real scripts on this surface.
                if token.startswith("scripts/"):
                    # Skip library / test directories — those are
                    # implementation details, not user-facing verbs.
                    if (token.startswith("scripts/lib/") or
                            token.startswith("scripts/tests/")):
                        continue
                    script_path = surface_root / token
                    if not script_path.is_file():
                        continue
                    if _is_pack_internal(script_path):
                        continue
                elif token.endswith(".sh") or token.endswith(".py"):
                    if "/" in token:
                        continue
                    script_path = surface_root / "scripts" / token
                    if not script_path.is_file():
                        continue
                    if _is_pack_internal(script_path):
                        continue
                verbs_referenced.add(token)
        missing = sorted(v for v in verbs_referenced if v not in frag_text)
        if missing:
            fail(f"{surface}: verbs referenced in prose but absent from help fragment ({frag.relative_to(REPO_ROOT)}):")
            for v in missing:
                fail(f"  missing: `{v}`")
            any_failed = True
            continue
        ok(f"{surface}: {len(verbs_referenced)} prose-referenced verb(s) all present in fragment")
    if any_failed:
        return


def check_help_fragment_completeness() -> None:
    """Check 23 — Help-fragment completeness vs scripts/ executables (BD-082).

    Every top-level executable script in scripts/ must appear in
    HELP-FRAGMENT-PACK.md unless the script declares `# pack-internal: true`
    near the top. Prevents the fragment going stale as new scripts ship.
    """
    print("\n── Check 23: Help-fragment completeness (BD-082) ──")
    fragment = REPO_ROOT / _HELP_FRAGMENT_PACK
    if not fragment.is_file():
        fail(f"pack-root help fragment missing: {fragment.name}")
        return
    text = fragment.read_text()

    scripts_dir = REPO_ROOT / "scripts"
    missing = []
    flagged_internal = []
    listed = []
    for entry in sorted(scripts_dir.iterdir()):
        if not entry.is_file():
            continue
        if entry.suffix not in (".sh", ".py"):
            continue
        if not os.access(entry, os.X_OK):
            continue
        # Skip the validate-pack helper itself — it's CI-only.
        if entry.name == "validate-pack.py":
            flagged_internal.append(entry.name)
            continue
        if _is_pack_internal(entry):
            flagged_internal.append(entry.name)
            continue
        if entry.name in text:
            listed.append(entry.name)
        else:
            missing.append(entry.name)
    if missing:
        fail(f"scripts/ executables missing from HELP-FRAGMENT-PACK.md (or mark with `# pack-internal: true`):")
        for n in missing:
            fail(f"  {n}")
        return
    ok(f"all {len(listed)} non-internal scripts/ executables listed in HELP-FRAGMENT-PACK.md "
       f"({len(flagged_internal)} marked pack-internal)")


# Check 89 — HELP-FRAGMENT /pack-* command ↔ backing-skill parity (BD-224).
# Anchored slash-row regex: a COMPLETE backtick span `/pack-<name>`. Does NOT
# reuse _VERB_RE — _VERB_RE's `/pack-\w+` arm uses \w (no hyphen) and would
# truncate `/pack-isolation-mode` -> `isolation` (a guaranteed false FAIL).
# The closing-backtick anchor also excludes `scripts/pack-td.sh`-shape spans
# (they start `scripts/`, never a bare `/pack-`), so no allowlist is needed.
# NOTE (raw-vs-set): findall over the current fragment returns 10 raw matches
# (`/pack-help` and `/pack-startup` each appear twice in HELP-FRAGMENT-PACK.md);
# the SET comprehension below dedups them to the 8 distinct advertised names.
# Every count/membership decision is on the SET `advertised`, NEVER on
# len(_PACK_SLASH_ROW_RE.findall(...)) (which is 10, not 8).
_PACK_SLASH_ROW_RE = re.compile(r"`/pack-([a-z0-9][a-z0-9-]*)`")

# Command-skill roots (all three CLI roots must back every advertised command).
_PACK_SKILL_ROOTS = (".claude", ".codex", ".agents")


def _git_ls_files_multi(pathspecs):
    """Return (available, tracked_paths) for `git ls-files <pathspec>...`.

    `available` is False when git is absent (FileNotFoundError) OR the tree is
    not a git work tree (non-zero exit) — both ⇒ the caller SKIPs lenient.
    Resolves the git root via cwd=REPO_ROOT (the module global), so a per-check
    test can monkeypatch help_fragments.REPO_ROOT to a /tmp scratch repo. ONE
    bounded subprocess over the given pathspecs; never a whole-tree walk, never
    a subprocess-per-row. Mirrors pack_ops_hygiene._git_ls_files but takes
    MULTIPLE pathspecs (the 3 CLI roots); kept inline per §6.2 (do not refactor
    shared infra for one addition).
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", *pathspecs],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [ln for ln in result.stdout.splitlines() if ln.strip()])


def check_help_fragment_command_skill_parity() -> None:
    """Check 89 — HELP-FRAGMENT /pack-* ↔ backing-skill parity (BD-224).

    Bidirectional gate closing the advertised-but-unimplemented hole that let
    /pack-isolation-mode ship with no skill:
      - FORWARD (help → skill): every backticked `/pack-<name>` slash row in
        pack-ops/HELP-FRAGMENT-PACK.md must have a git-TRACKED skill at
        <root>/skills/pack-<name>/SKILL.md in ALL THREE CLI roots
        (.claude, .codex, .agents). Absence from ANY one root FAILs (partial
        -root bite).
      - REVERSE (skill → help): every git-TRACKED pack-*-named command skill
        must be advertised as a `/pack-<name>` row. The reverse candidate set is
        restricted to pack-*-named dirs, which cleanly excludes the non-command
        engine/pooled skills (e.g. dashboard-render, the shipped render engine
        invoked by /pack-dashboard, which correctly has no help row).

    declare-verify-backing: uses git-TRACKED membership (git ls-files), never
    Path.is_file() — an untracked on-disk dir would not ship, so tracked
    membership is the correct backing signal. Bites the absence-of-backing
    instance, including partial-root absence (stronger than Check 71, which
    only fires once .claude already has the skill and is blind to total
    absence).

    measure-then-bound / O(rows): one `git ls-files` (3 pathspecs) + one
    fragment read + set algebra over <=8 elements. No allowlist (the category
    split is clean by token shape). SKIP-lenient off a git work tree; a missing
    fragment FAILs (a committed pack surface, not an env artifact).

    EXTENSION POINT (no exemption is wired today — none is measured-necessary
    against the current 8<->8 bijection): if a future non-command skill must
    carry the `pack-` prefix, mark its SKILL.md `# pack-internal: true` and add
    an `_is_pack_internal` filter to the reverse candidate set in the SAME
    commit that introduces it, so Check 89 stops treating it as an unadvertised
    command. That reuses the existing _is_pack_internal idiom already in this
    module.
    """
    print("\n── Check 89: HELP-FRAGMENT /pack-* command ↔ backing-skill parity (BD-224) ──")

    # Enumerate the git-TRACKED command-skill set across all 3 roots (one call).
    pathspecs = [f"{root}/skills/pack-*/SKILL.md" for root in _PACK_SKILL_ROOTS]
    available, tracked = _git_ls_files_multi(pathspecs)
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    # Read the advertised /pack-* set from the fragment (FAIL if absent — a
    # committed pack surface, mirroring Check 23's fragment-missing FAIL).
    frag_path = REPO_ROOT / _HELP_FRAGMENT_PACK
    if not frag_path.is_file():
        fail(f"pack-root help fragment missing: {_HELP_FRAGMENT_PACK}")
        return
    frag_text = frag_path.read_text()
    # SET comprehension: dedups the raw findall (10 on the current fragment) to
    # the DISTINCT advertised names (8). All downstream logic is on this set.
    advertised = {f"pack-{m}" for m in _PACK_SLASH_ROW_RE.findall(frag_text)}

    # Partition the tracked skills into per-root dir-name sets. Each tracked
    # path is `<root>/skills/pack-<name>/SKILL.md`.
    root_sets = {root: set() for root in _PACK_SKILL_ROOTS}
    for path in tracked:
        parts = path.split("/")
        # parts = [<root>, "skills", "pack-<name>", "SKILL.md"]
        if len(parts) >= 4 and parts[1] == "skills" and parts[-1] == "SKILL.md":
            root = parts[0]
            if root in root_sets:
                root_sets[root].add(parts[-2])

    any_failed = False

    # ── FORWARD leg: every advertised command backed in ALL THREE roots. ──
    for name in sorted(advertised):
        missing_roots = [
            f"{root}/skills/{name}/"
            for root in _PACK_SKILL_ROOTS
            if name not in root_sets[root]
        ]
        if missing_roots:
            any_failed = True
            fail(
                f"/{name} advertised in HELP-FRAGMENT-PACK.md but no backing "
                f"skill in: {', '.join(missing_roots)}. Every advertised "
                f"`/pack-<name>` slash command needs a git-TRACKED "
                f"pack-<name>/SKILL.md in all three CLI roots "
                f"(.claude/.codex/.agents)."
            )

    # ── REVERSE leg: every pack-*-named command skill is advertised. Candidate
    # set = the .claude pack-* dirs (Check 71 guarantees mirror parity). ──
    for name in sorted(root_sets[".claude"]):
        if name not in advertised:
            any_failed = True
            fail(
                f"{name} command skill exists (.claude/skills/{name}/) but is "
                f"not advertised in HELP-FRAGMENT-PACK.md — add a `/{name}` row "
                f"(or, if it is a non-command engine skill, it must not carry "
                f"the `pack-` prefix / must be marked `# pack-internal: true`)."
            )

    if any_failed:
        return
    ok(
        f"Check 89 — HELP-FRAGMENT /pack-* commands ({len(advertised)}) <-> "
        f"backing command skills bijective across all three CLI roots "
        f"(forward: all advertised commands backed; reverse: all pack-* command "
        f"skills advertised)."
    )


__all__ = [
    "_CHECK_16_EXEMPT_SURFACES",
    "check_trinity_addenda_h2",
    "_VERB_RE",
    "_PACK_INTERNAL_RE",
    "_is_pack_internal",
    "check_help_fragment_freshness",
    "check_help_fragment_completeness",
    "_HELP_FRAGMENT_PACK",
    "_PACK_SLASH_ROW_RE",
    "check_help_fragment_command_skill_parity",
]
