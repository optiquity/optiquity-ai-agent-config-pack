"""validate_checks.cross_bd — Cluster G: the cross-BD design-governance
family (BD-256 W8).

This module owns Cluster G's 3 check bodies (Checks 80, 81, 82) — the generic
doc↔constant twin-bijection + completeness guard (80, BD-255 Part A), the
structured `File/Symbol` prerequisite for active-design BDs (81, BD-255 Part C
C-i), and the cross-BD shared-edit-surface advisory (82, BD-255 Part C C-ii).
The three are co-located because they all key on the per-entry `backlog/BD-*.md`
design-governance surface: Check 80 enforces the doc↔constant twin registry,
Checks 81 + 82 share the open-BD `File/Symbol` field walk
(`_check_81_iter_open_bds`) + the structured-surface path-token grammar
(`_CHECK_81_PATH_TOKEN_RE`).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.cross_bd import *`,
so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each `check_*` name (80/81/82). Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster G checks): the
A1-collapse presentation maps + render fn (`_PACK_CHAT_ONLY_PATH_ANNOTATIONS`,
`_PACK_CHAT_ONLY_PREFIX_ANNOTATIONS`, `_PACK_CHAT_ONLY_DOC_BEGIN`,
`_PACK_CHAT_ONLY_DOC_END`, `render_pack_chat_only_doc_section`), the twin
registry + count + extractors (`_DOC_CONSTANT_TWINS`,
`_DOC_CONSTANT_TWINS_EXPECTED_COUNT`, `_doc_constant_twin_doc_set`,
`_doc_constant_twin_const_set`), and the Check 81/82 surface grammar +
helpers (`_CHECK_81_OPEN_BD_STATES`, `_CHECK_81_TBD_MARKERS`,
`_CHECK_81_PATH_TOKEN_RE`, `_check_81_iter_open_bds`,
`_check_81_field_is_structured`, `_check_81_active_bd_ids`).

MUST-4 placement (DESIGN-BD256-RECONCILED.md §MUST-4):
`render_pack_chat_only_doc_section` is DEAD-IN-SOURCE (never called by any
check body) but is called by `test-validate-pack-check-80.sh` (BITE 1 renders
the live region), so it MUST be re-exported (it is in `__all__`). It travels
here WITH the `_PACK_CHAT_ONLY_DOC_BEGIN`/`_PACK_CHAT_ONLY_DOC_END` marker
pair and the two annotation maps, because the marker pair is consumed by
`_doc_constant_twin_doc_set` (the A1 bijection extractor, a Cluster G helper)
and the render fn that also uses them is test-coupled to Check 80 — keeping the
marker pair single-module avoids a NEW cross-module seam.

By-name constant resolution (the W8 design hazard, DESIGN HOLD-2):
`check_doc_constant_twin_bijection` resolves its 5 ENROLLED constants
(`_PACK_CHAT_ONLY_PERMITTED_PATHS`, `_TRACKER_BACKENDS`,
`_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`,
`CHECK_REGISTRY_EXPECTED_COUNT`) BY STRING NAME via
`module_ns = globals()` then `module_ns[symbol_name]`. Those 5 (+ the secondary
`_PACK_CHAT_ONLY_PERMITTED_PREFIXES` the A1 union builder reads) live in `core`
(the 4 W1-promoted twin seams + the spine `CHECK_REGISTRY_EXPECTED_COUNT`, the
OI-C README check-inventory twin). For the by-name resolution to find them after
the move, this module imports ALL 6 `from .core` so they appear in THIS module's
`globals()` — `module_ns[symbol_name]` then resolves, never KeyError. (The
KeyError guard in Check 80 covers a genuinely-deleted secondary constant, the
BITE-4 graceful-fail case.)

Spine + seams: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `warn`,
`failures`, `CHECK_REGISTRY_EXPECTED_COUNT` — the count the OI-C README twin
binds) and the W1 core seams (`_session_state_load` for Check 81's active-BD
trigger, plus the 4 W1-promoted enrolled twin constants +
`_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES`) are imported `from .core` — the
single SSOT for the spine + W1 seams. (`failures` is imported for the V3
failures-identity invariant — `core.failures is cross_bd.failures` — matching
the W2–W7 module convention; the Cluster G bodies append via `fail()`, never
rebind `failures`.) Standard-library `re` is imported directly at module top,
mirroring the established per-module convention (the spine `import *` does not
re-export stdlib names).
"""

import re

from .core import (
    REPO_ROOT,
    fail,
    ok,
    warn,
    failures,
    CHECK_REGISTRY_EXPECTED_COUNT,
    _session_state_load,
    _PACK_CHAT_ONLY_PERMITTED_PATHS,
    _PACK_CHAT_ONLY_PERMITTED_PREFIXES,
    _TRACKER_BACKENDS,
    _CHECK_54_REQUIRED_TOKENS,
    _CHECK_56_CANONICAL_VERBS,
)


# ─────────────────────────────────────────────────────────────────────────
# A1 COLLAPSE (BD-255 Part A, design §3.1 Layer 1): the pack-chat-only twin.
#
# `_PACK_CHAT_ONLY_PERMITTED_PATHS` + `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`
# above are the SOLE SSOT for the pack-chat-only permitted set. The
# `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" Files +
# Directories bullets are DERIVED from them via the annotation map +
# `render_pack_chat_only_doc_section()` below — the doc is generated output,
# never a hand-maintained second surface (the `fail-loud: delete-the-old-
# source` idiom applied to representation). The ordered annotation map fixes
# BOTH the rendering order AND the friendly parenthetical for each entry;
# its keys are asserted set-equal to the membership constants so the constant
# stays the membership authority and the map is the presentation layer in the
# same logical unit.
#
# The narrower `README.md version table` constraint is a Pack Chat DISCIPLINE
# (the constant holds bare `README.md`; the "version table" scope lives as the
# annotation, not as a separate constant member).
_PACK_CHAT_ONLY_PATH_ANNOTATIONS = (
    ("README.md", "version table"),
    ("pack-ops/PACK-CHAT.md", "PM chat operating rules"),
    ("pack-ops/PACK-AGENTS.md", "agent routing + permission rules"),
    (
        "pack-ops/PACK-MEMORY-RATIONALE.md",
        "rule↔rationale bijection partner for `## Pack memory`; "
        "edited only in lockstep with rule changes",
    ),
    ("CLAUDE.md", "pack-root trinity"),
    ("AGENTS.md", "pack-root trinity"),
    ("GEMINI.md", "pack-root trinity"),
    ("project-template/CLAUDE.md", "project-template trinity"),
    ("project-template/AGENTS.md", "project-template trinity"),
    ("project-template/GEMINI.md", "project-template trinity"),
    (
        "pack-ops/session-state.json",
        "live-session snapshot; Pack-Chat-overwritten on every state transition",
    ),
)

_PACK_CHAT_ONLY_PREFIX_ANNOTATIONS = (
    ("backlog/", "pack per-entry tree (entries)"),
    ("changelog/", "pack changelog per-entry tree"),
    (
        "project-template/docs/project/backlog/",
        "project per-entry tree canonical templates (ship into client projects)",
    ),
    ("project-template/docs/project/implementation-plan/", "project per-entry tree"),
    ("project-template/docs/project/changelog/", "project per-entry tree"),
)

# Markers delimiting the GENERATED bullet block inside the PACK-AGENTS.md
# § "pack-chat-only files and directories" section. The text between (and
# including) these markers is `render_pack_chat_only_doc_section()` output.
_PACK_CHAT_ONLY_DOC_BEGIN = (
    "<!-- GENERATED:pack-chat-only-permitted-set — do not hand-edit; "
    "`_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES` in scripts/validate-pack.py "
    "govern (never source of truth here) -->"
)
_PACK_CHAT_ONLY_DOC_END = "<!-- /GENERATED:pack-chat-only-permitted-set -->"


def render_pack_chat_only_doc_section() -> str:
    """Render the GENERATED pack-chat-only Files + Directories bullet block
    for `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories".

    The constant `_PACK_CHAT_ONLY_PERMITTED_PATHS` /
    `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` are the membership SSOT; the ordered
    annotation maps supply the rendering order + the friendly parenthetical.
    Raises ValueError if the annotation-map key sets diverge from the
    membership constants (the collapse invariant — neither surface may drift
    from the other because both derive from this single render).
    """
    path_keys = [p for p, _ in _PACK_CHAT_ONLY_PATH_ANNOTATIONS]
    prefix_keys = [p for p, _ in _PACK_CHAT_ONLY_PREFIX_ANNOTATIONS]
    if set(path_keys) != _PACK_CHAT_ONLY_PERMITTED_PATHS:
        raise ValueError(
            "pack-chat-only path annotation map diverges from "
            "_PACK_CHAT_ONLY_PERMITTED_PATHS: "
            f"only-in-map={sorted(set(path_keys) - _PACK_CHAT_ONLY_PERMITTED_PATHS)} "
            f"only-in-constant={sorted(_PACK_CHAT_ONLY_PERMITTED_PATHS - set(path_keys))}"
        )
    if set(prefix_keys) != set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES):
        raise ValueError(
            "pack-chat-only prefix annotation map diverges from "
            "_PACK_CHAT_ONLY_PERMITTED_PREFIXES: "
            f"only-in-map={sorted(set(prefix_keys) - set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES))} "
            f"only-in-constant={sorted(set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES) - set(prefix_keys))}"
        )
    lines: list[str] = [_PACK_CHAT_ONLY_DOC_BEGIN, ""]
    lines.append("Files:")
    for path, annotation in _PACK_CHAT_ONLY_PATH_ANNOTATIONS:
        lines.append(f"- `{path}` ({annotation})")
    lines.append("")
    lines.append("Directories:")
    for prefix, annotation in _PACK_CHAT_ONLY_PREFIX_ANNOTATIONS:
        lines.append(f"- `{prefix}` — {annotation}")
    lines.append("")
    lines.append(_PACK_CHAT_ONLY_DOC_END)
    return "\n".join(lines)


# ─────────────────────────────────────────────────────────────────────────
# DOC↔CONSTANT TWIN REGISTRY (BD-255 Part A, design §3.1 Layer 3) + Check 80.
#
# A `_DOC_CONSTANT_TWINS` row enrolls a hand-authored doc↔constant twin (a
# prose set a doc maintains as its audience SSOT, restated by an enforcement
# constant, with nothing structurally forcing co-variance). Each row is tagged
# by GUARD-KIND:
#   - "bijection": the doc region's set is cleanly extractable, so Check 80
#     asserts doc-set == constant-set (the Check-45/52 idiom). Drift-proof.
#   - "recorded": the doc surface is a PROSE FLOOR — a clean set extraction is
#     infeasible (the rejected prose-parse the design forbids for Check 54/56).
#     Check 80 asserts only that the constant SYMBOL RESOLVES (the MUST-2
#     backstop record); the bespoke check (54/56) keeps its one-way guard.
#
# The F2 defeater — opt-in enrollment — is answered NOT by auto-discovery
# (infeasible; no syntactic twin-signal exists, design §2.5) but by the
# Check-59-style COMPLETENESS LEG in Check 80: len(...) == EXPECTED_COUNT +
# every symbol resolves. Enrollment is a count-gated, reviewable governance act.
#
# Row shape: (label, doc_paths, region/anchor, constant_symbol_name, guard_kind)
#   - label: a short human tag for messages.
#   - doc_paths: tuple of REPO_ROOT-relative doc files carrying the region.
#   - region: a human description of the region/anchor (for messages).
#   - constant_symbol_name: the module-attribute NAME (resolved via getattr at
#     check time — also the completeness-leg "symbol resolves" target).
#   - guard_kind: "bijection" | "recorded".
_DOC_CONSTANT_TWINS = (
    # A1 (BIJECTION) — LOCKS the A1 collapse: the generated PACK-AGENTS.md
    # pack-chat-only region (between the GENERATED markers) must EQUAL
    # render_pack_chat_only_doc_section() output (the constant-derived render).
    # This activates the A1 divergence guard that was dormant pending #80.
    (
        "A1 pack-chat-only permitted set",
        ("pack-ops/PACK-AGENTS.md",),
        "the GENERATED:pack-chat-only-permitted-set region",
        "_PACK_CHAT_ONLY_PERMITTED_PATHS",
        "bijection",
    ),
    # TRACKER (BIJECTION) — the "Supported at v11.0: ... reserved" backend
    # comment block in BOTH example files ↔ _TRACKER_BACKENDS. The comment is a
    # single delimited line (quoted first-class + a comma-delimited reserved
    # parenthetical), regex-clean, identical in both files → a real bijection.
    # (_TRACKER_MODES / _TRACKER_PREFER are NOT separate clean comment-block
    # twins — their tokens are scattered prose definitions across TOML tables,
    # not a single "supported set" comment; the backend line is the only clean
    # one, per the BD-255 census.)
    (
        "tracker supported backends",
        ("tracker.toml.pack-example", "project-template/tracker.toml.project-example"),
        'the "Supported at vN: ... reserved" backend comment line',
        "_TRACKER_BACKENDS",
        "bijection",
    ),
    # Check 54 (RECORDED residual) — OPTIONAL-FEATURES surfaces ↔
    # _CHECK_54_REQUIRED_TOKENS. The surface is rich human prose (a prose
    # floor); a set-equality bijection is the rejected prose-parse. Check 54
    # keeps its presence-only one-way guard; this row is the MUST-2 backstop
    # record (symbol-resolve only).
    (
        "OPTIONAL-FEATURES required tokens",
        (
            "pack-ops/OPTIONAL-FEATURES.md",
            "project-template/docs/pack/OPTIONAL-FEATURES.md",
        ),
        "OPTIONAL-FEATURES prose (presence-only; prose floor)",
        "_CHECK_54_REQUIRED_TOKENS",
        "recorded",
    ),
    # Check 56 (RECORDED residual) — trinity destructive-git-verb enumeration ↔
    # _CHECK_56_CANONICAL_VERBS. The surface is rich human prose with sub-form
    # parentheticals; a clean set extraction is infeasible (the prose-parse the
    # design rejects). Check 56 keeps its bespoke one-way guard; this row is the
    # MUST-2 backstop record (symbol-resolve only).
    (
        "destructive-git-verb canonical set",
        ("CLAUDE.md", "AGENTS.md", "GEMINI.md"),
        "the agents-never-commit destructive-verb enumeration across the "
        "_CHECK_56_VERB_PARITY_SURFACES set (prose floor; sub-form "
        "parentheticals make a clean extraction infeasible)",
        "_CHECK_56_CANONICAL_VERBS",
        "recorded",
    ),
    # README CHECK-INVENTORY (BIJECTION) — the README check-count prose ↔
    # CHECK_REGISTRY_EXPECTED_COUNT (OI-C, BD-205). The "<N> invoked checks" +
    # "<N> registry entries total" assertions at README.md:83 (version table) and
    # :205 (scripts/ layout) must all state the registry entry count (both phrases
    # equal len(registry) == the constant). This twin was NOT enrolled before C14,
    # which is exactly why the pre-C14 88-vs-89 count drift went undetected;
    # enrolling it makes that drift un-regressable. The doc set is the extracted
    # count number(s); the const set is the {str(constant)} singleton. (The sibling
    # "<N> numbered" / range-end numbers are DIFFERENT quantities — distinct-
    # numbered count / highest number — with no backing constant, so they are
    # intentionally NOT extracted; binding them would break the bijection.)
    (
        "README check-inventory count",
        ("README.md",),
        'the "<N> invoked checks" / "<N> registry entries total" assertions '
        "(README.md version table + scripts/ layout)",
        "CHECK_REGISTRY_EXPECTED_COUNT",
        "bijection",
    ),
)

# The count-gate (the CHECK_REGISTRY_EXPECTED_COUNT idiom). Check 80's
# completeness leg asserts len(_DOC_CONSTANT_TWINS) == this. Adding/removing a
# twin row is a deliberate, count-gated, reviewable edit.
_DOC_CONSTANT_TWINS_EXPECTED_COUNT = 5


def _doc_constant_twin_doc_set(label, doc_paths, region, symbol_name):
    """Extract the doc-region SET for a BIJECTION twin row, per its label.

    Returns a `set[str]` of the tokens the doc region enumerates, or raises
    ValueError if the region/markers are absent (a structural break the check
    surfaces as a FAIL). Dispatches on the row label because each bijection
    twin has its own (small, bespoke) region grammar — exactly the Check-45/52
    pattern, scoped to the measured surfaces (measure-then-bound).
    """
    if symbol_name == "_PACK_CHAT_ONLY_PERMITTED_PATHS":
        # A1: the doc set IS the membership the rendered region encodes. The
        # rendered block is the constant-derived SSOT; the bijection is the
        # doc's region == render_pack_chat_only_doc_section() output. We compare
        # the extracted path/prefix backtick tokens, not the whole block, so a
        # cosmetic whitespace edit is not a false RED.
        doc_path = REPO_ROOT / doc_paths[0]
        text = doc_path.read_text()
        begin = _PACK_CHAT_ONLY_DOC_BEGIN
        end = _PACK_CHAT_ONLY_DOC_END
        if begin not in text or end not in text:
            raise ValueError(
                f"{doc_paths[0]} is missing the GENERATED pack-chat-only "
                f"region markers"
            )
        region_text = text.split(begin, 1)[1].split(end, 1)[0]
        # Each rendered bullet is `- `<path-or-prefix>` (...)` / `- `<...>` — ...`.
        return set(re.findall(r"^- `([^`]+)`", region_text, re.MULTILINE))
    if symbol_name == "_TRACKER_BACKENDS":
        # Backend comment line: # Supported at <ver>: "<first>". Others
        # (<a>, <b>, <c>) reserved. The full set = first-class ∪ reserved.
        line_re = re.compile(
            r'#\s*Supported at [^:]+:\s*"([^"]+)"\.\s*Others\s*'
            r'\(([^)]+)\)\s*reserved\.'
        )
        sets_per_file = []
        for rel in doc_paths:
            doc_path = REPO_ROOT / rel
            text = doc_path.read_text()
            m = None
            for line in text.splitlines():
                mm = line_re.search(line)
                if mm:
                    m = mm
                    break
            if m is None:
                raise ValueError(
                    f"{rel} is missing the 'Supported at ...: ... reserved' "
                    f"backend comment line"
                )
            first_class = m.group(1).strip()
            reserved = [t.strip() for t in m.group(2).split(",") if t.strip()]
            sets_per_file.append(frozenset([first_class] + reserved))
        # All example files must agree (the shipped comment is identical).
        if len(set(sets_per_file)) != 1:
            raise ValueError(
                f"tracker backend comment sets diverge across {list(doc_paths)}: "
                f"{[sorted(s) for s in sets_per_file]}"
            )
        return set(sets_per_file[0])
    if symbol_name == "CHECK_REGISTRY_EXPECTED_COUNT":
        # README check-inventory prose (OI-C, BD-205): every "<N> invoked checks"
        # and "<N> registry entries total" assertion states the registry entry
        # count. Both phrases equal len(registry) == the constant, so the doc-set
        # is the SET of those numbers (a consistent doc collapses to one element).
        # A partial drift (one phrase updated, the other stale) yields a 2-element
        # set != the {constant} singleton → a clean, named bijection FAIL.
        count_re = re.compile(
            r"(\d+)\s+invoked checks|(\d+)\s+registry entries total"
        )
        found = set()
        for rel in doc_paths:
            doc_path = REPO_ROOT / rel
            text = doc_path.read_text()
            for g_invoked, g_registry in count_re.findall(text):
                if g_invoked:
                    found.add(g_invoked)
                if g_registry:
                    found.add(g_registry)
        if not found:
            raise ValueError(
                f"{list(doc_paths)} carry no '<N> invoked checks' / "
                f"'<N> registry entries total' count assertion"
            )
        return found
    raise ValueError(
        f"no bijection doc-set extractor for twin '{label}' "
        f"(symbol {symbol_name})"
    )


def _doc_constant_twin_const_set(module_ns, symbol_name):
    """Return the CONSTANT-side SET for a BIJECTION twin row.

    `module_ns` is this module's globals() (robust under either import path).
    The row names ONE representative symbol; the A1 twin's membership SSOT is
    actually TWO constants (paths + prefixes) whose UNION the rendered doc
    region encodes — so the A1 const set is that union. Other bijection twins
    are a single set-like constant.
    """
    if symbol_name == "_PACK_CHAT_ONLY_PERMITTED_PATHS":
        return set(module_ns["_PACK_CHAT_ONLY_PERMITTED_PATHS"]) | set(
            module_ns["_PACK_CHAT_ONLY_PERMITTED_PREFIXES"]
        )
    if symbol_name == "CHECK_REGISTRY_EXPECTED_COUNT":
        # SCALAR constant (an int) → the singleton set of its string form, to
        # compare against the README doc-set of number STRINGS. `set(<int>)` would
        # TypeError (int is not iterable), so this branch is required — the generic
        # `set(module_ns[symbol_name])` fall-through below only handles iterables.
        return {str(module_ns[symbol_name])}
    return set(module_ns[symbol_name])


def check_doc_constant_twin_bijection() -> None:
    """Check 80 — generic doc↔constant twin-bijection + completeness leg (BD-255).

    The generic A-mechanism (design §3.1 Layer 3). For each enrolled
    `_DOC_CONSTANT_TWINS` row:
      - guard_kind "bijection": assert the doc-region SET equals the constant
        SET (the Check-45/52 set-equality idiom — missing/extra two-sided). This
        LOCKS the A1 collapse + guards the tracker backend twin.
      - guard_kind "recorded": assert only that the constant SYMBOL RESOLVES to
        a real module attribute (the MUST-2 backstop record; the surface is a
        prose floor — its bespoke check keeps the one-way guard).

    PLUS the Check-59-style COMPLETENESS LEG:
      - len(_DOC_CONSTANT_TWINS) == _DOC_CONSTANT_TWINS_EXPECTED_COUNT
        (enrollment is count-gated — adding/removing a twin without the count
        bump FAILs), AND
      - every registered constant symbol resolves to a real module attribute.

    This does NOT auto-discover unregistered twins (infeasible, design §2.5 — no
    syntactic twin-signal exists), but makes enrollment a deliberate, reviewable,
    count-gated governance act + makes each enrolled bijection drift-proof.

    Cheap (ci-check-runtime-compounding): per row = one small doc read + a
    region extract + a set compare; the completeness leg is in-memory set
    arithmetic. Same cost class as Check 45/52/59 — no subprocess, no tree walk.

    Lenient: a doc-surface file absent at HEAD SKIPs that row's bijection leg
    (an init/state problem, not a drift); the completeness leg always runs.
    """
    print("\n── Check 80: doc↔constant twin-bijection + completeness (BD-255) ──")

    # Resolve registered symbols against THIS module's globals (robust whether
    # the module is imported by name or loaded via spec_from_file_location).
    module_ns = globals()

    # ── Completeness leg (count-gate) ──
    n = len(_DOC_CONSTANT_TWINS)
    if n != _DOC_CONSTANT_TWINS_EXPECTED_COUNT:
        fail(
            f"_DOC_CONSTANT_TWINS has {n} row(s) but "
            f"_DOC_CONSTANT_TWINS_EXPECTED_COUNT == "
            f"{_DOC_CONSTANT_TWINS_EXPECTED_COUNT}. A twin was enrolled or "
            f"removed without the count bump (the count-gate, like "
            f"CHECK_REGISTRY_EXPECTED_COUNT). Set the constant to {n} if the "
            f"change is intentional, or restore the missing row. Per BD-255 "
            f"design §3.1 Layer 3 the completeness leg makes enrollment loud."
        )
        return

    # ── Completeness leg (every symbol resolves) ──
    unresolved = [
        sym for (_l, _d, _r, sym, _k) in _DOC_CONSTANT_TWINS
        if sym not in module_ns
    ]
    if unresolved:
        fail(
            f"_DOC_CONSTANT_TWINS registers {len(unresolved)} constant "
            f"symbol(s) that do NOT resolve to a module attribute: "
            f"{unresolved}. Per BD-255 design §3.1 Layer 3 every registered "
            f"twin symbol must name a real constant. Remediation: fix the "
            f"symbol name in the row, or remove the row + bump the count."
        )
        return

    any_fail = False
    bijection_rows = 0
    recorded_rows = 0
    skipped_rows = 0

    for label, doc_paths, region, sym, kind in _DOC_CONSTANT_TWINS:
        if kind == "recorded":
            # Symbol-resolve already verified above; record-only row.
            recorded_rows += 1
            continue
        if kind != "bijection":
            any_fail = True
            fail(
                f"twin '{label}' has unknown guard_kind {kind!r} "
                f"(expected 'bijection' | 'recorded')."
            )
            continue
        # Lenient: skip the bijection leg if any doc surface is absent at HEAD.
        missing_files = [p for p in doc_paths if not (REPO_ROOT / p).is_file()]
        if missing_files:
            ok(
                f"twin '{label}' — doc surface(s) {missing_files} absent; "
                f"skipping bijection (lenient)"
            )
            skipped_rows += 1
            continue
        try:
            doc_set = _doc_constant_twin_doc_set(label, doc_paths, region, sym)
            const_set = _doc_constant_twin_const_set(module_ns, sym)
        except ValueError as exc:
            any_fail = True
            fail(
                f"twin '{label}' — could not extract the doc-region set from "
                f"{region} ({list(doc_paths)}): {exc}. The region/markers may "
                f"have drifted. Per BD-255 design §3.1 Layer 3."
            )
            continue
        except KeyError as exc:
            # A constant the const-set builder resolves did NOT exist in
            # module_ns. The completeness leg already covers every DIRECTLY
            # named row symbol, but a bijection builder may read a SECONDARY
            # un-named constant (e.g. the A1 row's union reads both
            # `_PACK_CHAT_ONLY_PERMITTED_PATHS` and
            # `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`). A missing such constant
            # must FAIL loud-but-clean (naming the symbol), never crash with an
            # uncaught traceback (a guard fails gracefully — design §3.1
            # Layer 3 / ci-guard-measure-then-bound).
            any_fail = True
            fail(
                f"twin '{label}' — could not resolve a constant the bijection "
                f"const-set builder reads (row symbol `{sym}`): missing "
                f"module attribute {exc}. A required SSOT constant was "
                f"deleted/renamed. Remediation: restore the named constant or "
                f"update the builder + row. Per BD-255 design §3.1 Layer 3."
            )
            continue
        only_doc = sorted(doc_set - const_set)
        only_const = sorted(const_set - doc_set)
        if only_doc or only_const:
            any_fail = True
            fail(
                f"twin '{label}' — doc↔constant DRIFT (bijection broken). "
                f"In {region} ({list(doc_paths)}) but NOT in `{sym}`: "
                f"{only_doc}. In `{sym}` but NOT in the doc region: "
                f"{only_const}. Per BD-255 design §3.1 Layer 3 the enrolled "
                f"twin must be a set-equality bijection. Remediation: edit the "
                f"SSOT then regenerate/sync the derived surface in the SAME "
                f"change (for A1 the constant is the SSOT; re-render the "
                f"PACK-AGENTS.md region via render_pack_chat_only_doc_section())."
            )
            continue
        bijection_rows += 1

    if not any_fail:
        ok(
            f"Check 80 — {n} twin(s) enrolled (== "
            f"_DOC_CONSTANT_TWINS_EXPECTED_COUNT); every symbol resolves; "
            f"{bijection_rows} bijection row(s) hold set-equality, "
            f"{recorded_rows} recorded-residual row(s) resolve, "
            f"{skipped_rows} bijection leg(s) skipped (surface absent)."
        )


# ── Checks 81 + 82: cross-BD shared-edit-surface collision detection
# (BD-255 Part C, sub-type C; design §3.3 C-i prereq + C-ii backstop) ──────────
#
# Open-backlog states whose entries are subject to the surface checks. The
# lifecycle enum (`backlog/_rules.md` § "Lifecycle states admitted") is
# Open / Unblocked / Deferred / Resolved / Deprecated / Cancelled. Only the
# ACTIVE (not-postponed, not-closed) entries matter for collision detection:
# Open + Unblocked. Deferred/Resolved/Deprecated/Cancelled are excluded
# (sized EXACTLY to the active-design population — measure-then-bound).
_CHECK_81_OPEN_BD_STATES = ("Open", "Unblocked")

# The bare/TBD/placeholder markers that disqualify a `File/Symbol` field from
# being a STRUCTURED repo-relative path list (the F4 enabler — design §3.3).
# A field carrying any of these (case-insensitive) is a placeholder, NOT a
# parseable surface set, even if it also names a concrete backtick path
# (e.g. a field reading "n/a — new file `...` to be created", "TBD by
# architect. Likely surfaces: `...`", or "candidate surfaces"). The
# set is sized EXACTLY to the design's enumerated reject-list (measure-then-
# bound — DESIGN-RECONCILED §3.3 C-i / the FAIL-leg spec), no broader.
_CHECK_81_TBD_MARKERS = (
    "tbd",
    "to be determined",
    "to be created",
    "architect to detail",
    "candidate surfaces",
    "n/a",
)

# A backtick-quoted repo-relative path token inside a `File/Symbol` field — a
# backtick span whose first segment is followed by EITHER another `/<segment>`
# (a multi-segment path), OR a `.<ext>` suffix (a repo-root file like
# `CLAUDE.md` / `validate-pack.py`), OR a single trailing `/` (a repo-relative
# directory like `project-template/` / `backlog/` — including a single-segment
# directory the multi-segment alternative would otherwise miss). This is the
# structured-surface signal the collision scan keys on (design §3.3: the
# researcher blast-radius / structured surface set, NOT free-text prose). The
# trailing-slash directory case keeps the matcher sized to the real structured
# File/Symbol population (ci-guard-measure-then-bound) — a bare backtick word
# with NO slash and NO extension is still NOT a path token (no false
# positives). Used by BOTH Check 81 (≥1 token ⇒ structured) and Check 82 (the
# surface→BDs map keys). Bounded to the field VALUE (no tree walk, no
# subprocess).
#
# Dot-leading surfaces: the FIRST character class admits a leading `.`, so a
# dot-directory surface (`.claude/agents/pack-planner.md`, `.github/workflows/`,
# `.codex/`) tokenizes like any other path and is visible to the collision
# scan. The CONTINUATION grammar is UNCHANGED, which is what keeps a backticked
# bare extension (`.md`, `.sh`, `.gitignore`) from tokenizing: a token still
# requires a `/<segment>`, a `.<ext>` suffix, or a trailing `/` AFTER its first
# segment. Bounded (ci-guard-measure-then-bound): measured corpus-wide over
# `backlog/BD-*.md`, the widening is purely ADDITIVE — no existing token is
# lost and no existing token's occurrence count changes.
#
# Placeholder-segment terminator: a path token may ALSO be terminated by a
# `<placeholder>` SEGMENT — a `<` that immediately follows a `/` — in which
# case the captured token is the literal DIRECTORY PREFIX up to (and
# including) that `/` (`project-template/skills/<command>/SKILL.md` ⇒
# `project-template/skills/`). Without this, a backtick span carrying a
# placeholder segment never reaches its closing backtick within the token
# grammar (the `<`/`>` chars are outside the path char-class), so the WHOLE
# span tokenizes to nothing and a BD whose surface is written with a
# placeholder segment is INVISIBLE to the collision scan on that path — the
# BD-257↔BD-037 `project-template/skills/` blind spot. Bounded (ci-guard-
# measure-then-bound): the `(?<=/)(?=<)` terminator fires ONLY when `<`
# directly follows a `/` (a FULL placeholder segment), so a mid-segment
# placeholder (`scripts/pack-<noun>.sh`), a leading placeholder
# (`<repo>/docs/...`), or a bare prose `<` (`a < b`) yields NO token from that
# span — the broadening is sized exactly to genuine directory-prefix surfaces,
# and the captured token always ends in `/` (a clean directory). Non-
# placeholder paths tokenize EXACTLY as before (the closing-backtick branch is
# unchanged; the single capture group is preserved so `.group(1)` call sites
# are untouched).
_CHECK_81_PATH_TOKEN_RE = re.compile(
    r"`([A-Za-z0-9_.][A-Za-z0-9_./-]*"
    r"(?:/[A-Za-z0-9_./-]+|\.[A-Za-z0-9_]+|/))"
    r"(?:`|(?<=/)(?=<))"
)


def _check_81_iter_open_bds():
    """Yield `(rel_path, bd_id, status, file_symbol_value)` for every
    git-tracked-shape `backlog/BD-*.md` entry in an active-design state
    (`_CHECK_81_OPEN_BD_STATES`).

    The candidate set is the per-entry `backlog/BD-*.md` files (the tree IS
    the SSOT — `ci-guard-measure-then-bound`: the enumeration is the tracked
    per-entry entry set, NOT a filesystem walk of the whole repo). Entries
    whose `Status:` is not active (Deferred/Resolved/Deprecated/Cancelled) or
    whose name is a supporting `_`-prefixed file are SKIPPED.

    `file_symbol_value` is the `File/Symbol:` field VALUE — the colon-tail of
    the field header line PLUS any subsequent indented/bulleted continuation
    lines, up to the next top-level field line (`^<Field>:` or `^**`). `None`
    when the entry carries no `File/Symbol` field. Cheap: one small read +
    line scan per entry; no subprocess, no tree walk.
    """
    backlog_dir = REPO_ROOT / "backlog"
    if not backlog_dir.is_dir():
        return
    field_line_re = re.compile(r"^[A-Z][A-Za-z0-9/ _-]*:")
    for entry in sorted(backlog_dir.glob("BD-*.md")):
        if entry.name.startswith("_"):
            continue
        try:
            text = entry.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        rel = entry.relative_to(REPO_ROOT)
        m_id = re.match(r"(BD-\d+)\.md$", entry.name)
        bd_id = m_id.group(1) if m_id else entry.stem
        m_st = re.search(r"^Status:\s*(\S+)", text, re.MULTILINE)
        status = m_st.group(1) if m_st else None
        if status not in _CHECK_81_OPEN_BD_STATES:
            continue
        # Extract the File/Symbol field VALUE (header colon-tail + bulleted
        # continuation up to the next top-level field).
        lines = text.splitlines()
        fs_value = None
        for i, line in enumerate(lines):
            if re.match(r"^File/Symbol\b", line):
                head = line.split(":", 1)
                value_lines = [head[1] if len(head) > 1 else ""]
                for cont in lines[i + 1:]:
                    if field_line_re.match(cont) or cont.startswith("**"):
                        break
                    value_lines.append(cont)
                fs_value = "\n".join(value_lines)
                break
        yield (rel, bd_id, status, fs_value)


def _check_81_field_is_structured(fs_value):
    """True iff `fs_value` is a STRUCTURED repo-relative path list (the F4
    enabler): it carries ≥1 backtick repo-relative path token AND no bare/TBD
    placeholder marker. A `None`/empty field, a bare-TBD field, or a
    "candidate surfaces"/placeholder field (even one that also names a path)
    is NOT structured. design §3.3 C-i FAIL-leg spec."""
    if not fs_value:
        return False
    low = fs_value.lower()
    if any(marker in low for marker in _CHECK_81_TBD_MARKERS):
        return False
    return bool(_CHECK_81_PATH_TOKEN_RE.search(fs_value))


def _check_81_active_bd_ids():
    """Return the set of BD-IDs in the committed session-state `active[]`
    list (the in-design trigger — BD-252's mechanism, NOT a new backlog Status
    token; design DECISION C2-a). Reads `pack-ops/session-state.json` via the
    shared `_session_state_load()`; returns an EMPTY set (SKIP-lenient) when
    the snapshot is absent, unparseable, or carries no usable `active[]` (a
    fresh clone / pre-feature HEAD must not crash the check).

    TWO member SHAPES are matched, because the surface carries both:
    - a STRING whose LEADING token is the BD-ID (`"BD-288 @ <free text>"`) —
      the shape `pack-ops/session-state.json` and `scripts/dashboard-render.py`
      (`" ".join(session.get("active", []) or [])`) use;
    - a DICT carrying a `bd` key (`{"bd": "BD-288", ...}`).

    The string leg anchors at the START of the member (`re.match`, a leading
    whitespace skip, and a trailing word boundary), so ONLY the BD-ID that
    OPENS the member is gated. A mid-string BD-ID is free text naming some
    OTHER entry (a member of the form
    `"BD-224 @ design pass ... (BD-25...)"`), not a second active BD, so a
    permissive scan of the whole member would gate entries that are not in
    active design."""
    loaded = _session_state_load()
    if loaded is None or loaded[0] == "PARSE_ERROR":
        return set()
    data = loaded[0]
    if not isinstance(data, dict):
        return set()
    active = data.get("active")
    if not isinstance(active, list):
        return set()
    ids = set()
    for member in active:
        if isinstance(member, dict):
            bd = member.get("bd")
            if isinstance(bd, str) and re.match(r"^BD-\d+$", bd):
                ids.add(bd)
        elif isinstance(member, str):
            m = re.match(r"\s*(BD-\d+)\b", member)
            if m:
                ids.add(m.group(1))
    return ids


def check_open_bd_structured_surface_field() -> None:
    """Check 81 — structured `File/Symbol` prerequisite for active-design BDs
    (BD-255 Part C, design §3.3 C-i; TWO-MODE).

    The F4 enabler: the cross-BD collision scan keys on a STRUCTURED surface
    set, so at least ONE side of any pair must be parseable. This check
    GUARANTEES that for every BD in active design.

    - FAIL leg (gate): for every open `backlog/BD-*.md` whose BD-ID is in the
      committed session-state `active[]` list (the in-design trigger —
      DECISION C2-a; BD-252's existing mechanism, NOT a new backlog Status
      token), its `File/Symbol` field MUST be a structured repo-relative path
      list (≥1 backtick path token + no bare/TBD placeholder). A bare/TBD or
      missing field for an active BD FAILs.
    - WARN leg (advisory, NEVER fail): for every OTHER active-state open BD
      with a bare/TBD/missing `File/Symbol`, WARN (visibility without
      false-blocking legitimately-early entries — the Check-48 warn idiom).

    SKIP-lenient: if `pack-ops/session-state.json` is absent/unparseable the
    `active[]` set is empty (no FAIL leg fires), so the check degrades to the
    WARN leg only — a fresh clone / pre-feature HEAD never crashes or
    false-fails.

    Net exit semantics: the check exits non-zero ONLY when the FAIL leg
    fires (an `active[]` BD carries a bare/TBD/missing `File/Symbol`); a
    bare/TBD field on any NON-active open BD takes the WARN leg and never
    affects the exit code.

    Cheap (ci-check-runtime-compounding): one small JSON read + a line scan of
    each small open entry (~28 entries today). No subprocess, no tree walk.
    """
    print(
        "\n── Check 81: structured File/Symbol prereq for active-design BDs "
        "(BD-255) ──"
    )

    active_ids = _check_81_active_bd_ids()
    failed = 0
    warned = 0
    active_ok = 0
    for rel, bd_id, _status, fs_value in _check_81_iter_open_bds():
        structured = _check_81_field_is_structured(fs_value)
        if bd_id in active_ids:
            if not structured:
                failed += 1
                detail = "missing" if not fs_value else "bare/TBD/placeholder"
                fail(
                    f"{rel} — {bd_id} is in active design (session-state "
                    f"`active[]`) but its `File/Symbol` field is {detail} (no "
                    f"structured repo-relative path list). The cross-BD "
                    f"collision scan (Check 82 / the design-time blast-radius "
                    f"intersection) needs ≥1 parseable surface side. "
                    f"Remediation: replace the placeholder with a structured "
                    f"backtick repo-relative path list. Per BD-255 design "
                    f"§3.3 C-i (the F4 structured-surface prerequisite)."
                )
            else:
                active_ok += 1
        else:
            if not structured:
                warned += 1
                warn(
                    f"{rel} — {bd_id} (open, not yet in active design) has a "
                    f"bare/TBD/missing `File/Symbol` field; structure it into a "
                    f"repo-relative path list before the architect stage so "
                    f"the cross-BD collision scan can key on it (advisory only "
                    f"— NOT a gate failure; Check-48 warn idiom). Per BD-255 "
                    f"design §3.3 C-i."
                )

    if failed == 0:
        ok(
            f"Check 81 — every active-design BD ({len(active_ids)} in "
            f"session-state `active[]`; {active_ok} with a structured "
            f"File/Symbol) carries a structured repo-relative path list; "
            f"{warned} not-yet-active open BD(s) with a bare/TBD field WARNed "
            f"(advisory, exit code unaffected)."
        )


def check_cross_bd_surface_advisory() -> None:
    """Check 82 — cross-BD shared-edit-surface advisory (BD-255 Part C,
    design §3.3 C-ii; ADVISORY backstop).

    Parses every active-state open `backlog/BD-*.md` `File/Symbol` field for
    its backtick repo-relative path tokens, builds a `surface → [BD-IDs]` map,
    and WARNs (advisory, NEVER `fail()` — the Check-48 precedent; two open BDs
    legitimately co-editing a surface is NORMAL, the signal is "coordinate,"
    not "forbidden") when ≥2 open BDs name the SAME surface. The design-time
    blast-radius intersection scan (the C-i pipeline rule, landed separately)
    is the load-bearing prevention; this CI backstop is defense-in-depth.

    WARN shape: when ≥2 open BDs name the SAME repo-relative surface in their
    structured File/Symbol fields, the single WARN names BOTH that shared
    surface AND the co-editing BD IDs — the "coordinate" signal points at the
    exact set of open BDs claiming it.

    Cheap (ci-check-runtime-compounding): one line scan + regex over each
    small open entry's File/Symbol field (~28 entries today) + an in-memory
    map build. No subprocess, no tree walk.
    """
    print(
        "\n── Check 82: cross-BD shared-edit-surface advisory (BD-255) ──"
    )

    surface_to_bds = {}
    for _rel, bd_id, _status, fs_value in _check_81_iter_open_bds():
        if not fs_value:
            continue
        seen = set()  # de-dup repeated paths within one entry's field
        for m in _CHECK_81_PATH_TOKEN_RE.finditer(fs_value):
            surface = m.group(1)
            if surface in seen:
                continue
            seen.add(surface)
            surface_to_bds.setdefault(surface, []).append(bd_id)

    overlaps = 0
    for surface in sorted(surface_to_bds):
        bds = sorted(set(surface_to_bds[surface]))
        if len(bds) >= 2:
            overlaps += 1
            warn(
                f"shared edit surface `{surface}` is claimed by {len(bds)} "
                f"open BDs: {', '.join(bds)} — coordinate/sequence these "
                f"(advisory only, NOT a gate failure; the load-bearing "
                f"prevention is the design-time blast-radius intersection "
                f"scan). Per BD-255 design §3.3 C-ii."
            )

    ok(
        f"Check 82 — cross-BD surface advisory: {overlaps} shared "
        f"surface(s) WARNed across {len(surface_to_bds)} distinct surface(s) "
        f"named by active-state open BDs; advisory only (exit code "
        f"unaffected)."
    )


# ── __all__ — every Cluster-G-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.cross_bd import *` skips underscore names UNLESS they
# are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the three `check_*` (resolved by bare name in the
# facade's `_build_check_registry()`) and `render_pack_chat_only_doc_section`
# (called by test-validate-pack-check-80.sh L165 even though it is dead in
# source) MUST be enumerated. Membership = the three-source UNION (SHOULD-5):
# tested privates the test-80/82 suites reach + registry-referenced `check_*` +
# the cross-module test-called helper, intersected with THIS module's OWNED
# symbols. The 5 `from .core` seams (`_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES`,
# `_TRACKER_BACKENDS`, `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`)
# are NOT re-listed here — they are core-owned (the facade re-exports them via
# `from validate_checks.core import *`); they appear in THIS module's globals()
# (so Check 80's by-name `module_ns[symbol]` resolves) but `__all__` only
# enumerates cross_bd's OWN symbols.
__all__ = [
    # ── A1-collapse presentation maps + markers + render fn (Check 80) ──
    "_PACK_CHAT_ONLY_PATH_ANNOTATIONS",
    "_PACK_CHAT_ONLY_PREFIX_ANNOTATIONS",
    "_PACK_CHAT_ONLY_DOC_BEGIN",
    "_PACK_CHAT_ONLY_DOC_END",
    "render_pack_chat_only_doc_section",
    # ── doc↔constant twin registry + extractors + Check 80 ──
    "_DOC_CONSTANT_TWINS",
    "_DOC_CONSTANT_TWINS_EXPECTED_COUNT",
    "_doc_constant_twin_doc_set",
    "_doc_constant_twin_const_set",
    "check_doc_constant_twin_bijection",
    # ── Check 81/82 surface grammar + helpers + bodies ──
    "_CHECK_81_OPEN_BD_STATES",
    "_CHECK_81_TBD_MARKERS",
    "_CHECK_81_PATH_TOKEN_RE",
    "_check_81_iter_open_bds",
    "_check_81_field_is_structured",
    "_check_81_active_bd_ids",
    "check_open_bd_structured_surface_field",
    "check_cross_bd_surface_advisory",
]
