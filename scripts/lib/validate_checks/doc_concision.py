"""validate_checks.doc_concision — Cluster D: the doc-concision /
anti-restate / pointer-manifest family (BD-256 W5).

This module owns Cluster D's 4 check bodies (Checks 45, 46, 44, 66) plus their
intra-cluster helpers and constants — the pack-memory rule↔rationale bijection
(45), the boundary + spawn-rule pointer manifests + anti-restate scan (46), the
M4 durable-doc concision gate (44), and the operating-doc bullet-concision gate
(66). The four are co-located because they form one connected component over the
concision / pointer-manifest surfaces (CLAUDE.md `## Pack memory`,
pack-ops/PACK-MEMORY-RATIONALE.md, the durable pack-ops/ rule docs, the trinity
memory-section bullet surfaces, and the two BD-196 pointer manifests).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.doc_concision
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name. Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster D checks): the
anti-restate constants/helper (`_CHECK_46_ANTI_RESTATE_SURFACES` /
`_CHECK_46_ANTI_RESTATE_MIN_LEN` /
`_check_46_extract_pack_memory_imperative_bodies`), the Check-44 durable-doc
constants/helper (`_CHECK_44_FORBIDDEN_PATTERNS` / `_CHECK_44_DURABLE_DOCS` /
`_check_44_load_allowlist`), and the Check-66 bullet-concision constants/helpers
(`_CHECK_66_BULLET_CHAR_CAP`, the A5-collapse trinity-memory-H2 constants
`_TRINITY_MEMORY_H2_PACK` / `_TRINITY_MEMORY_H2_PROJECT`,
`_CHECK_66_BULLET_SURFACE`, `_check_66_iter_bullets`, `_check_66_load_allowlist`).
None of these is read by a check outside Cluster D (verified by grep at the
extraction wave), so no core promotion is needed — they are Cluster-D-owned, not
a >=2-module seam.

Spine + seams: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) and the
one cross-module helper this cluster reads (`_parse_manifest_records` — promoted
to `core` at W2, consumed by Check 46's manifest-parse + Check 44/66's
allowlist-file reads) are imported `from .core` — the single SSOT for the spine +
W1 seams + the W2 cross-module helper. (`failures` is imported for the V3
failures-identity invariant — `core.failures is doc_concision.failures` —
matching the W2/W3/W4 module convention; the Cluster D bodies append via `fail()`,
never rebind `failures`.)

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
    failures,
    _parse_manifest_records,
)


def check_pack_memory_rationale_bijection() -> None:
    """Check 45 — pack-memory rule↔rationale bijection (BD-196).

    Enforces a set-equality bijection between two surfaces, over the
    PRESENT `[rationale:]` set (per ARCHITECTURE-DOC-CONCISION-
    GUARDRAILS.md §5.2):

      - the set of `[rationale: <slug>]` slugs tagged on imperative
        lines in `CLAUDE.md` `## Pack memory` (the corpus
        representative — trinity parity of AGENTS.md / GEMINI.md is
        separately enforced by Checks 16/18/19), AND

      - the set of `## <slug>` section headings in
        `pack-ops/PACK-MEMORY-RATIONALE.md`.

    FAIL if the two sets are not equal in EITHER direction:
      - an orphan corpus slug (a `[rationale: slug]` with no matching
        `## slug` heading), OR
      - an orphan rationale heading (a `## slug` with no live
        `[rationale: slug]` pointer in the corpus).

    Rules that carry NO `[rationale:]` tag are simply not in the set —
    the check does not require every spawn-rule to have a rationale.
    This makes drift impossible: you cannot delete a rule and orphan
    its rationale, or add a rationale for a rule that does not exist.

    Pattern: follows `check_mirror_in_sync` (Check 32) — a set-equality
    assertion between two surfaces. Trigger: any commit touching either
    file.

    Lenient mode: if either surface is absent (unlikely at any
    reasonable pack-repo HEAD) the check SKIPs with a notice rather
    than failing — a missing surface is an init/state problem, not a
    bijection violation.
    """
    print("\n── Check 45: pack-memory rule↔rationale bijection (BD-196) ──")

    corpus_path = REPO_ROOT / "CLAUDE.md"
    rationale_path = REPO_ROOT / "pack-ops" / "PACK-MEMORY-RATIONALE.md"

    if not corpus_path.is_file():
        ok("CLAUDE.md absent — skipping (lenient)")
        return
    if not rationale_path.is_file():
        ok("pack-ops/PACK-MEMORY-RATIONALE.md absent — skipping (lenient)")
        return

    # Restrict the corpus scan to the `## Pack memory` section so that a
    # `[rationale: slug]` appearing in unrelated prose elsewhere in
    # CLAUDE.md cannot pollute the set. The section runs from its `## `
    # heading to the next top-level `## ` heading (or EOF).
    corpus_lines = corpus_path.read_text().splitlines()
    in_pack_memory = False
    pack_memory_text_lines = []
    for line in corpus_lines:
        if line.startswith("## "):
            # Match the Pack memory H2 by its leading token; the heading
            # text is `## Pack memory (project-local learnings)`.
            in_pack_memory = line.startswith("## Pack memory")
            continue
        if in_pack_memory:
            pack_memory_text_lines.append(line)
    pack_memory_text = "\n".join(pack_memory_text_lines)

    rationale_re = re.compile(r"\[rationale:\s*([a-z0-9][a-z0-9-]*)\]")
    corpus_slugs = sorted(set(rationale_re.findall(pack_memory_text)))

    # Parse `## <slug>` headings from the rationale file. Slug headings
    # are the controlled-vocab kebab-case form; a `## ` heading that is
    # not a slug (e.g., a prose section header) would simply not match
    # the slug character class and be excluded — but by design every
    # `## ` heading in the rationale file IS a slug section.
    heading_re = re.compile(r"^##\s+([a-z0-9][a-z0-9-]*)\s*$", re.MULTILINE)
    rationale_text = rationale_path.read_text()
    rationale_slugs = sorted(set(heading_re.findall(rationale_text)))

    corpus_set = set(corpus_slugs)
    rationale_set = set(rationale_slugs)

    orphan_corpus_slugs = sorted(corpus_set - rationale_set)
    orphan_rationale_headings = sorted(rationale_set - corpus_set)

    if orphan_corpus_slugs:
        fail(
            f"CLAUDE.md `## Pack memory` carries {len(orphan_corpus_slugs)} "
            f"`[rationale: slug]` pointer(s) with NO matching `## <slug>` "
            f"heading in pack-ops/PACK-MEMORY-RATIONALE.md: "
            f"{orphan_corpus_slugs}. Per BD-196 / ARCHITECTURE-DOC-"
            f"CONCISION-GUARDRAILS.md §5.2 the rule↔rationale bijection "
            f"requires every corpus `[rationale: slug]` to resolve to "
            f"exactly one rationale section. Remediation: add the missing "
            f"`## <slug>` section(s) to pack-ops/PACK-MEMORY-RATIONALE.md "
            f"in the SAME commit, or remove the orphan `[rationale: slug]` "
            f"pointer(s) from the corpus."
        )
    if orphan_rationale_headings:
        fail(
            f"pack-ops/PACK-MEMORY-RATIONALE.md carries "
            f"{len(orphan_rationale_headings)} `## <slug>` heading(s) with "
            f"NO matching live `[rationale: slug]` pointer in CLAUDE.md "
            f"`## Pack memory`: {orphan_rationale_headings}. Per BD-196 / "
            f"ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2 the rule↔"
            f"rationale bijection requires every rationale section to map "
            f"to exactly one live corpus pointer. Remediation: add the "
            f"`[rationale: slug]` pointer to the matching corpus rule in "
            f"the SAME commit, or remove the orphan `## <slug>` section "
            f"from the rationale file."
        )

    if not orphan_corpus_slugs and not orphan_rationale_headings:
        ok(
            f"Check 45 — {len(corpus_slugs)} corpus `[rationale: slug]` "
            f"pointer(s); {len(rationale_slugs)} rationale `## <slug>` "
            f"section(s); sets are equal (bijection holds, no orphans "
            f"in either direction)."
        )


# ── Check 46: boundary + spawn-rule pointer manifests (BD-196 C6) ──────────
# Combined reference-resolution + anti-restate check over the two
# machine-readable manifests authored by BD-196 (C5 + C6):
#   - pack-ops/.boundary-pointer-manifest.txt  (B5; the deleted BOUNDARY §6
#     entry-point network — surface → expected pointer to BOUNDARY-DEFINITION)
#   - pack-ops/.spawn-rule-manifest.txt         (§9.6; spawn-relevant rule
#     slug → canonical `## Pack memory` home + the reference surfaces where
#     the collapsed one-line pointer now lives)
#
# Two assertions (per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 + §9.6):
#   (a) REFERENCE-RESOLUTION (Check-34 pattern) — every named surface in
#       either manifest exists AND carries its expected resolving pointer.
#   (b) ANTI-RESTATE (the §9.6 substring scan, SC7-bounded) — no canonical
#       `## Pack memory` imperative BODY reappears verbatim in any spawn-rule
#       reference surface or spawn-relevant skill. The predicate scans the
#       imperative BODY (first clause, whitespace-normalized, >= a minimum
#       length) NOT the rule NAME, so a legitimate one-line reference that
#       merely NAMES a rule ("Agents never commit — see trinity `## Pack
#       memory` ...") cannot false-positive (the SC7 / §4.2-storm shape).
#
# Implemented as ONE function per PLAN §2 G-A (the design left the 3-vs-4
# split as a coder call; one function over both manifests minimizes surface
# and shares the manifest-parse + resolution helpers).

# The anti-restate scan targets: the spawn-rule reference surfaces +
# the spawn-relevant skills (the 4 the design names). Skills live under
# `.claude/skills/`; the trinity skill mirrors (.codex / .agents) carry
# identical content (parity-checked elsewhere) — scanning the .claude
# copy is sufficient for the anti-restate teeth.
_CHECK_46_ANTI_RESTATE_SURFACES = (
    "pack-ops/PACK-AGENTS.md",
    "pack-ops/PACK-CHAT.md",
    ".claude/skills/commit-discipline/SKILL.md",
    ".claude/skills/review/SKILL.md",
    ".claude/skills/planning/SKILL.md",
    ".claude/skills/implementation-report/SKILL.md",
)

# SC7 bound (measured 2026-05-30, HEAD 0cbd6d5): the NAIVE rule-NAME
# predicate stormed 6/6 on legitimate name-bearing references; the BODY
# predicate at >= 60 chars yields 0 hits post-C5-collapse AND still catches
# an injected verbatim restatement. The scan targets the whitespace-
# normalized imperative BODY (the text AFTER the bold rule name — see
# _check_46_extract_pack_memory_imperative_bodies, which discards the NAME
# group entirely), NOT the rule name. Rule-NAME length is therefore
# irrelevant to the bound: names are never scanned, so a long name cannot
# false-positive. The >= 60-char window is chosen empirically — every real
# `## Pack memory` imperative BODY's leading clause exceeds it (no false-
# negative: a genuine verbatim restatement is caught), while a legitimate
# one-line reference (which names the rule and paraphrases, rather than
# reproducing 60+ contiguous verbatim chars of an imperative body) cannot
# reach the threshold (no false-positive). The bound separates one-line
# NAME references from verbatim BODY restatements — it is body-derived,
# not name-derived.
_CHECK_46_ANTI_RESTATE_MIN_LEN = 60


def _check_46_extract_pack_memory_imperative_bodies(min_len: int) -> list:
    """Extract the canonical `## Pack memory` imperative BODY strings.

    Each bullet is `- **<name>.** <body...>`. We take the BODY (everything
    after the bold name), collapse whitespace, and keep the leading window
    if it is at least `min_len` chars. Returns the candidate substrings used
    by the anti-restate scan. The NAME is deliberately excluded so a
    one-line reference that names the rule cannot match (SC7 bound).
    """
    corpus_path = REPO_ROOT / "CLAUDE.md"
    if not corpus_path.is_file():
        return []
    lines = corpus_path.read_text().splitlines()
    in_pack_memory = False
    pm_lines = []
    for line in lines:
        if line.startswith("## "):
            in_pack_memory = line.startswith("## Pack memory")
            continue
        if in_pack_memory:
            pm_lines.append(line)
    pm_text = "\n".join(pm_lines)

    # Bullet bodies: text after the bold name up to the next top-level
    # bullet, blank line, or EOF.
    bodies = re.findall(
        r"^- \*\*.+?\*\*\s*(.+?)(?=\n- \*\*|\n\n|\Z)",
        pm_text,
        re.MULTILINE | re.DOTALL,
    )
    candidates = []
    for body in bodies:
        normalized = re.sub(r"\s+", " ", body).strip()[:120]
        if len(normalized) >= min_len:
            candidates.append(normalized)
    return candidates


def check_boundary_and_spawn_pointer_manifests() -> None:
    """Check 46 — boundary + spawn-rule pointer manifests (BD-196 C6).

    (a) Reference-resolution (Check-34 pattern): every surface named in
        pack-ops/.boundary-pointer-manifest.txt and
        pack-ops/.spawn-rule-manifest.txt exists on disk AND carries its
        expected resolving pointer.
          - boundary manifest: the surface contains the `pointer` substring
            (the BOUNDARY-DEFINITION.md basename).
          - spawn manifest: every surface named in the record's `references`
            field exists AND references the canonical home (`## Pack memory`)
            so the collapsed one-line pointer resolves to the SSOT.
    (b) Anti-restate (§9.6, SC7-bounded): no `## Pack memory` imperative
        BODY (first clause, whitespace-normalized, >= 60 chars) reappears
        verbatim in any spawn-rule reference surface or spawn-relevant skill.

    Lenient mode: a manifest that is absent SKIPs with a notice (an
    init/state problem, not a resolution violation).

    Pattern: composes Check 34 (cross-reference integrity) for the
    resolution half and a measure-then-bound substring scan for the
    anti-restate half. Per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md
    §4.3 + §9.6; PLAN-DOC-CONCISION-GUARDRAILS.md §2 (G-A: one function).
    """
    print(
        "\n── Check 46: boundary + spawn-rule pointer manifests (BD-196) ──"
    )

    boundary_manifest = REPO_ROOT / "pack-ops" / ".boundary-pointer-manifest.txt"
    spawn_manifest = REPO_ROOT / "pack-ops" / ".spawn-rule-manifest.txt"

    if not boundary_manifest.is_file() and not spawn_manifest.is_file():
        ok(
            "neither pointer manifest present (skipping; lenient) — "
            "pack-ops/.boundary-pointer-manifest.txt + "
            "pack-ops/.spawn-rule-manifest.txt are authored by BD-196 C5/C6"
        )
        return

    any_fail = False

    # ── (a1) Boundary-pointer manifest reference-resolution ──────────────
    boundary_surfaces = 0
    if boundary_manifest.is_file():
        records = _parse_manifest_records(boundary_manifest.read_text())
        for rec in records:
            surface = rec.get("surface")
            pointer = rec.get("pointer")
            if not surface or not pointer:
                fail(
                    f"pack-ops/.boundary-pointer-manifest.txt: a record is "
                    f"missing a `surface:` or `pointer:` field "
                    f"(record={rec!r}). Each record requires both."
                )
                any_fail = True
                continue
            boundary_surfaces += 1
            surface_path = REPO_ROOT / surface
            if not surface_path.is_file():
                fail(
                    f"pack-ops/.boundary-pointer-manifest.txt names surface "
                    f"`{surface}` which does NOT exist on disk. Per BD-196 / "
                    f"ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 the "
                    f"boundary-pointer manifest is the deleted BOUNDARY §6 "
                    f"entry-point network; every named surface must exist. "
                    f"Remediation: restore the surface or remove its manifest "
                    f"record in the SAME commit."
                )
                any_fail = True
                continue
            if pointer not in surface_path.read_text():
                fail(
                    f"surface `{surface}` no longer carries its expected "
                    f"BOUNDARY-DEFINITION pointer (substring `{pointer}` not "
                    f"found). Per BD-196 the boundary pointer network is "
                    f"CI-asserted: a surface that silently loses its pointer "
                    f"breaks the discoverability invariant. Remediation: "
                    f"restore the pointer to `{surface}`, or remove its "
                    f"record from pack-ops/.boundary-pointer-manifest.txt in "
                    f"the SAME commit."
                )
                any_fail = True

    # ── (a2) Spawn-rule manifest reference-resolution ────────────────────
    spawn_records = 0
    if spawn_manifest.is_file():
        records = _parse_manifest_records(spawn_manifest.read_text())
        # A reference surface resolves the collapsed one-line pointer if it
        # exists AND points at the canonical home (`## Pack memory`). The
        # surface basename is parsed from the `references:` free-text by
        # matching the known reference-surface basenames.
        known_ref_files = {
            "PACK-AGENTS.md": REPO_ROOT / "pack-ops" / "PACK-AGENTS.md",
            "PACK-CHAT.md": REPO_ROOT / "pack-ops" / "PACK-CHAT.md",
        }
        for rec in records:
            slug = rec.get("slug")
            canonical = rec.get("canonical", "")
            references = rec.get("references", "")
            if not slug or not references:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt: a record is missing "
                    f"a `slug:` or `references:` field (record={rec!r})."
                )
                any_fail = True
                continue
            spawn_records += 1
            if "## Pack memory" not in canonical:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt slug `{slug}`: the "
                    f"`canonical:` field must name `## Pack memory` (the "
                    f"single spawn-source per §9.2); got `{canonical}`."
                )
                any_fail = True
            # Each named reference surface must exist + point at the canonical
            # home so the collapsed pointer resolves to the SSOT.
            named = [b for b in known_ref_files if b in references]
            if not named:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt slug `{slug}`: the "
                    f"`references:` field names no known reference surface "
                    f"(expected one of {sorted(known_ref_files)}); got "
                    f"`{references[:80]}`."
                )
                any_fail = True
                continue
            for basename in named:
                ref_path = known_ref_files[basename]
                if not ref_path.is_file():
                    fail(
                        f"pack-ops/.spawn-rule-manifest.txt slug `{slug}` "
                        f"references `{basename}` which does NOT exist."
                    )
                    any_fail = True
                    continue
                if "## Pack memory" not in ref_path.read_text():
                    fail(
                        f"reference surface `{basename}` (named by spawn-rule "
                        f"slug `{slug}`) no longer points at the canonical "
                        f"home `## Pack memory`. Per BD-196 §9.6 the collapsed "
                        f"one-line reference MUST resolve to the SSOT. "
                        f"Remediation: restore the `## Pack memory` reference "
                        f"in `{basename}`, or update the manifest record."
                    )
                    any_fail = True

    # ── (b) Anti-restate substring scan (SC7-bounded) ────────────────────
    candidates = _check_46_extract_pack_memory_imperative_bodies(
        _CHECK_46_ANTI_RESTATE_MIN_LEN
    )
    restate_hits = 0
    for surface in _CHECK_46_ANTI_RESTATE_SURFACES:
        surface_path = REPO_ROOT / surface
        if not surface_path.is_file():
            # A spawn-relevant surface absent at HEAD is unexpected but not
            # a restatement violation; skip it silently (the boundary/spawn
            # resolution halts above would surface a missing required file).
            continue
        normalized = re.sub(r"\s+", " ", surface_path.read_text())
        for body in candidates:
            if body in normalized:
                restate_hits += 1
                fail(
                    f"anti-restate violation: surface `{surface}` contains a "
                    f"verbatim `## Pack memory` imperative BODY "
                    f"(>= {_CHECK_46_ANTI_RESTATE_MIN_LEN} chars): "
                    f"`{body[:80]}...`. Per BD-196 §9.6 a spawn-relevant rule "
                    f"is authored ONCE in `## Pack memory`; reference surfaces "
                    f"carry a ONE-LINE pointer, never a verbatim restatement. "
                    f"Remediation: collapse the restatement back to a one-line "
                    f"reference of the form \"<name> — see trinity `## Pack "
                    f"memory` `[rationale: <slug>]`\"."
                )
                any_fail = True

    if not any_fail:
        ok(
            f"Check 46 — boundary manifest: {boundary_surfaces} surface(s) "
            f"resolve their BOUNDARY-DEFINITION pointer; spawn manifest: "
            f"{spawn_records} rule(s) resolve to `## Pack memory`; "
            f"anti-restate: 0 verbatim imperative-body restatements across "
            f"{len(_CHECK_46_ANTI_RESTATE_SURFACES)} spawn-relevant surface(s) "
            f"({len(candidates)} candidate bodies scanned, "
            f">= {_CHECK_46_ANTI_RESTATE_MIN_LEN} chars)."
        )


# ── Check 44: M4 durable-doc concision gate (BD-196 C10) ───────────────────
# The M4 concision gate over the 6 durable pack-ops/ non-mirror rule docs
# (the M4 class per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 +
# PLAN-DOC-CONCISION-GUARDRAILS.md EE-P1). Two parts:
#
#   (a) THE TEETH (hard-fail) — temporal `will ` count = 0 OUTSIDE the
#       allowlist. A temporal/roadmap `will ` is a report-only artifact that
#       MUST NOT appear in a forward-only durable rule doc. Any matched line
#       NOT covered by a pack-ops/.concision-allowlist.txt record FAILs.
#       The allowlist is sized to the KEEP set EXACTLY (measure-then-bound):
#       only legitimate operational-behavioral `will ` occurrences are
#       admitted; it is NOT widened to swallow contamination.
#
#   (b) LENGTH CEILING (BD-243 Gate 1a — HARDENED advisory→FAIL) — each doc
#       carries a per-doc ceiling DERIVED from its measured (bloat-reduced)
#       content (ceil(measured * 1.15) — a 15% growth headroom, per-doc, NOT a
#       uniform round cap). A doc OVER its ceiling FAILs the build: per the
#       user's BD-243 ruling the cleanup must not silently rot, and an advisory
#       that "never fails the build" was exactly the silent-rot mechanism.
#       Volume is now a hard gate at parity with the `will ` teeth. The ceiling
#       is a VOLUME measure only — it asserts nothing about meaning (legitimate
#       content is below it by construction; only a regression past the headroom
#       FAILs). DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1.
#
# The history axis (dates / 7-40-hex SHAs / Commit-N / Override-N /
# post-Commit) MOVED out of this check to Check 65
# (check_operating_doc_no_history), which owns the full history axis over
# the operating-doc IN set. Check 44 retains ONLY the `will ` teeth +
# advisory length.
#
# Pattern: a fresh scan + the existing _parse_manifest_records() allowlist-
# file read pattern (shared with Check 46). Per ARCHITECTURE-DOC-CONCISION-
# GUARDRAILS.md §6 (M1-M4) + §7; PLAN-DOC-CONCISION-GUARDRAILS.md §3 C10.

# The M4 forbidden-pattern set — the temporal `will ` probe (the C4/C9
# canonical probe form `\bwill `, trailing space). The history axis lives in
# Check 65.
_CHECK_44_FORBIDDEN_PATTERNS = (
    ("will", re.compile(r"\bwill ")),
)

# The 6 durable pack-ops/ non-mirror rule docs (M4 class) + each doc's
# per-doc line ceiling, DERIVED from its measured (BD-243 bloat-reduced)
# content as ceil(measured * 1.15). These are NOT round numbers: each is
# anchored to the doc's actual reduced size (BOUNDARY 135, CONCEPTUAL-REVIEW
# 279, DRY-RUN 198, HELP-PACK 48, MERGE 484, OPTIONAL 538) with a uniform 15%
# growth headroom. BACKLOG.md / CHANGELOG.md are regenerated MIRRORS, NOT in
# the M4 class.
#
# BD-243 Gate 1a (DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1): the length branch
# is HARDENED advisory→FAIL — a doc OVER its ceiling now FAILS the build, not a
# soft advisory. Volume is a hard gate so the cleanup cannot silently rot. The
# ceilings are sized measure-then-bound to the bloat-reduced reality + 15%
# headroom (so legitimate content is below the ceiling BY CONSTRUCTION; only a
# regression past the headroom FAILs — the gate is VOLUME-only, never a
# meaning judgment). The measured-reduced inputs are from IMPL-CB-01's
# recorded measured_reduced_lines (no re-measure of a drifted tree). Two
# ceilings change vs the prior advisory values (CONCEPTUAL 343→321 from
# measured 279; DRY-RUN 229→228 from measured 198); the other four were already
# ceil(measured*1.15) and stand. All 6 docs are UNDER their new FAIL ceilings.
_CHECK_44_DURABLE_DOCS = (
    ("pack-ops/BOUNDARY-DEFINITION.md", 156),
    ("pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md", 321),
    ("pack-ops/DRY-RUN-MIGRATION.md", 228),
    ("pack-ops/HELP-FRAGMENT-PACK.md", 56),
    ("pack-ops/MERGE-STRATEGY.md", 557),
    ("pack-ops/OPTIONAL-FEATURES.md", 619),
)


def _check_44_load_allowlist() -> dict:
    """Parse pack-ops/.concision-allowlist.txt into {doc: [snippet, ...]}.

    Each record carries `doc:`, `pattern:`, `snippet:`, `reason:`. The
    matching key is (doc, snippet-substring) — line numbers are NOT used
    (they drift). Returns a dict mapping each doc path to its list of
    allowlisted snippet substrings. Reuses _parse_manifest_records().
    """
    allowlist_path = REPO_ROOT / "pack-ops" / ".concision-allowlist.txt"
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


def check_durable_doc_concision() -> None:
    """Check 44 — M4 durable-doc concision gate (BD-196 C10).

    Scans the 6 durable pack-ops/ non-mirror rule docs (the M4 class) for
    the temporal `will ` pattern. THE TEETH: any matched line NOT covered
    by a pack-ops/.concision-allowlist.txt record (doc match AND an
    allowlisted snippet is a substring of the line) FAILs — temporal
    `will ` count must be 0 OUTSIDE the allowlist.

    LENGTH CEILING (BD-243 Gate 1a — HARDENED advisory→FAIL): each doc
    carries a per-doc line ceiling = ceil(measured_reduced * 1.15) (the
    bloat-reduced size + 15% headroom). A doc OVER its ceiling now FAILs —
    volume is a HARD gate so the BD-243 bloat reduction cannot silently
    rot. The ceiling is a VOLUME measure only; it asserts nothing about
    meaning (legitimate content is below the ceiling by construction;
    only a regression past the headroom FAILs).

    The history axis (dates / SHAs / Commit-N / Override-N / post-Commit)
    MOVED to Check 65 (check_operating_doc_no_history). Check 44 owns only
    the `will ` teeth + the BD-243 Gate-1a length ceiling (FAIL).

    Per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 (M1-M4) + §7;
    PLAN-DOC-CONCISION-GUARDRAILS.md §3 C10. The allowlist is sized to
    the KEEP set EXACTLY (measure-then-bound) — never widened to admit a
    contamination hit.

    Lenient mode: a durable doc absent at HEAD SKIPs that doc with a
    notice (an init/state problem, not a concision violation); a missing
    allowlist file means an empty allowlist (every `will ` hit then FAILs
    — fail-loud, never silently-pass).
    """
    print("\n── Check 44: M4 durable-doc concision gate (BD-196) ──")

    allowlist = _check_44_load_allowlist()

    any_fail = False
    scanned_docs = 0
    total_forbidden_outside = 0
    total_allowlisted = 0

    for doc_rel, ceiling in _CHECK_44_DURABLE_DOCS:
        doc_path = REPO_ROOT / doc_rel
        if not doc_path.is_file():
            ok(f"{doc_rel} absent — skipping that doc (lenient)")
            continue
        scanned_docs += 1
        snippets = allowlist.get(doc_rel, [])
        lines = doc_path.read_text().splitlines()

        for lineno, line in enumerate(lines, start=1):
            matched_patterns = [
                name for name, rx in _CHECK_44_FORBIDDEN_PATTERNS
                if rx.search(line)
            ]
            if not matched_patterns:
                continue
            # A line is allowlisted iff one of the doc's allowlist
            # snippets is a substring of the line (content-anchored, not
            # line-number-anchored — line numbers drift).
            covered = any(snip in line for snip in snippets)
            if covered:
                total_allowlisted += 1
                continue
            total_forbidden_outside += 1
            fail(
                f"{doc_rel}:{lineno} — M4 concision-gate temporal `will ` "
                f"{matched_patterns} OUTSIDE the allowlist: "
                f"`{line.strip()[:90]}`. Per BD-196 / ARCHITECTURE-DOC-"
                f"CONCISION-GUARDRAILS.md §6 (M4), durable pack-ops/ rule "
                f"docs are forward-only: a temporal/roadmap `will ` is a "
                f"report-only artifact (C2 surface-separation). Remediation: "
                f"STRIP it from the durable doc (an operational-behavioral "
                f"`will ` goes in the allowlist). The allowlist is sized to "
                f"the legitimate KEEP set EXACTLY and MUST NOT be widened to "
                f"admit this hit. (The history axis — dates / SHAs / "
                f"Commit-N / Override-N / post-Commit — moved to Check 65.)"
            )
            any_fail = True

        # Length ceiling — HARDENED advisory→FAIL (BD-243 Gate 1a). A doc OVER
        # its measure-then-bound ceiling (ceil(measured_reduced * 1.15)) FAILs:
        # volume is a hard gate so the bloat reduction cannot silently rot. The
        # ceiling is sized to the reduced reality + 15% headroom, so legitimate
        # content is below it by construction — only a regression past the
        # headroom FAILs (VOLUME-only; never a meaning judgment).
        n_lines = len(lines)
        if n_lines > ceiling:
            fail(
                f"{doc_rel} — BD-243 Gate 1a length ceiling: {n_lines} lines "
                f"exceeds the per-doc FAIL ceiling {ceiling} "
                f"(ceil(measured_reduced * 1.15) — the bloat-reduced size + 15% "
                f"headroom). Per DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1, doc "
                f"volume is a HARD gate (the cleanup must not silently rot). "
                f"This is a VOLUME measure only — it asserts nothing about "
                f"meaning. Remediation: reduce the doc's text amount (move new "
                f"content to a report/rationale surface) OR, if the growth is "
                f"genuinely load-bearing, re-derive the ceiling from the new "
                f"measured baseline (a reviewed governance act, NOT a default)."
            )
            any_fail = True

    if not any_fail:
        ok(
            f"Check 44 — {scanned_docs} durable doc(s) scanned; "
            f"{total_forbidden_outside} forbidden pattern(s) outside the "
            f"allowlist (0 = clean); {total_allowlisted} allowlisted "
            f"operational occurrence(s) admitted (KEEP set)."
        )


# ── Check 66 (Gate 1b): operating-doc bullet-concision gate (BD-243) ───────
# AUTHORED-UNREGISTERED at CG-14-prep-b — its body + constant + allowlist ship
# now but it is NOT in CHECK_REGISTRY (count stays 63); CG-14 registers it.
# Exercised meanwhile via its per-check test's in-process body invocation (NOT
# `--only-check 66`, which resolves against the registry and so cannot reach an
# unregistered check).
#
# WHAT IT CATCHES (DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1b): a single rule /
# bullet whose char length exceeds a per-bullet cap (the B1 mega-bullet pattern
# — e.g. the graph-first-context rule). A whole-DOC ceiling (Check 44 Gate 1a)
# cannot catch a mega-bullet inside an otherwise-reasonable doc; a per-bullet
# cap does. VOLUME only — the cap is a CHARACTER count; it asserts nothing
# about meaning (a bullet under the cap passes regardless of content).
#
# SCOPE (auto-discovered bullet surface): the pack + project trinity memory-
# section bullets (`## Pack memory` / `## Project rules`) + the
# PACK-MEMORY-RATIONALE.md rule bullets. These are the files that carry the
# `- **<rule>** ...` bullet structure where the B1 mega-bullet bloat lives.
#
# measure-then-bound: the cap (_CHECK_66_BULLET_CHAR_CAP = 1300) sits ABOVE the
# post-reduction dense-rule cluster (legitimate rule bullets max ~1260 chars)
# and BELOW the irreducible mega-bullet floor (1457). Over-cap bullets that are
# irreducibly load-bearing are admitted by pack-ops/.bullet-concision-
# allowlist.txt, sized EXACTLY to the measured over-cap KEEP set (8 records).
#
# RUNTIME COST (ci-check-runtime-compounding): reads the ~5 bullet-bearing
# files once, splits on bullet markers, measures each bullet's length —
# O(lines), no subprocess, no whole-tree scan. Cheap.

# The single per-bullet character cap (Gate 1b). A bullet over this and not
# allowlisted FAILs. measure-then-bound to the post-reduction tree (above the
# ~1260-char legitimate rule cluster, below the 1457 mega-bullet floor).
_CHECK_66_BULLET_CHAR_CAP = 1300

# The trinity memory-section H2 heading is a per-LOCATION constant, not a
# literal repeated inline. The two trinity locations carry DIFFERENT headings
# by design (Check 18 runs H2 parity per-location): pack-root keys on
# `## Pack memory`; the project-template rows key on `## Project rules`.
# Per-location constants make any future heading change a ONE-constant flip
# + the 3 template files; Check 66 follows automatically. A single shared
# constant is NOT used — it would conflate the two locations.
_TRINITY_MEMORY_H2_PACK = "## Pack memory"
_TRINITY_MEMORY_H2_PROJECT = "## Project rules"

# The bullet-bearing files + the memory-section header that opens the bullet
# region (None = scan the whole file's top-level bullets, for RATIONALE). The
# per-location heading reads the A5-collapse constants above so a future rename
# touches the constant, not this table.
_CHECK_66_BULLET_SURFACE = (
    ("CLAUDE.md", _TRINITY_MEMORY_H2_PACK),
    ("AGENTS.md", _TRINITY_MEMORY_H2_PACK),
    ("GEMINI.md", _TRINITY_MEMORY_H2_PACK),
    ("project-template/CLAUDE.md", _TRINITY_MEMORY_H2_PROJECT),
    ("project-template/AGENTS.md", _TRINITY_MEMORY_H2_PROJECT),
    ("project-template/GEMINI.md", _TRINITY_MEMORY_H2_PROJECT),
    ("pack-ops/PACK-MEMORY-RATIONALE.md", None),
)


def _check_66_iter_bullets(path: Path, section_marker):
    """Yield (first_lineno, char_len, first_line) for each top-level `- `
    bullet in `path`. If `section_marker` is given, scanning starts after the
    first line whose stripped form starts with it (the memory-section header);
    otherwise the whole file is scanned. A bullet spans its `- ` line plus any
    2-space-indented continuation lines, ending at a blank line, a header, or
    the next top-level bullet. char_len is the whitespace-collapsed length of
    the joined bullet text (the VOLUME measure)."""
    lines = path.read_text().splitlines()
    start = 0
    if section_marker:
        start = len(lines)  # if the marker is absent, scan nothing
        for i, line in enumerate(lines):
            if line.strip().startswith(section_marker):
                start = i + 1
                break
    cur = None
    cur_start = None
    i = start
    out = []

    def flush():
        nonlocal cur, cur_start
        if cur is not None:
            joined = " ".join(s.strip() for s in cur)
            out.append((cur_start, len(joined), cur[0]))
        cur, cur_start = None, None

    while i < len(lines):
        line = lines[i]
        if re.match(r"^- ", line):
            flush()
            cur = [line]
            cur_start = i + 1
        elif cur is not None and line.strip() == "":
            flush()
        elif cur is not None and line.startswith("  "):
            cur.append(line)
        elif line.startswith("#"):
            flush()
        else:
            flush()
        i += 1
    flush()
    return out


def _check_66_load_allowlist() -> dict:
    """Parse pack-ops/.bullet-concision-allowlist.txt into {doc: [snippet,...]}.

    Each record carries `doc:`, `snippet:`, `reason:`. The matching key is
    (doc, snippet-substring of the over-cap bullet's first line) — line numbers
    are NOT used (they drift). Reuses _parse_manifest_records()."""
    allowlist_path = (
        REPO_ROOT / "pack-ops" / ".bullet-concision-allowlist.txt"
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


def check_operating_doc_bullet_concision() -> None:
    """Check 66 (Gate 1b) — operating-doc bullet-concision gate (BD-243).

    Caps per-rule / per-bullet CHARACTER length over the bullet surface (the
    pack + project trinity memory-section bullets + PACK-MEMORY-RATIONALE.md
    rule bullets). THE TEETH: a bullet whose char length exceeds
    _CHECK_66_BULLET_CHAR_CAP and is NOT covered by a
    pack-ops/.bullet-concision-allowlist.txt record (doc match AND an
    allowlisted snippet is a substring of the bullet's first line) FAILs.

    This is the per-bullet companion to Check 44's per-DOC ceiling (Gate 1a):
    a whole-doc ceiling cannot catch a single mega-bullet inside an otherwise-
    reasonable doc. VOLUME only — the cap is a character count; it asserts
    nothing about meaning.

    AUTHORED-UNREGISTERED at CG-14-prep-b (not in CHECK_REGISTRY; count stays
    63). CG-14 registers it. Per DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1b.

    measure-then-bound: the allowlist is sized to the measured over-cap KEEP
    set EXACTLY — never widened to admit a reducible bullet. A reviewer
    re-verifies each `reason:` still names an irreducibly load-bearing bullet.

    Lenient mode: a bullet-surface file absent at HEAD SKIPs that file (an
    init/state problem, not a concision violation); a missing allowlist file
    means an empty allowlist (every over-cap bullet then FAILs — fail-loud).
    """
    print("\n── Check 66: operating-doc bullet-concision gate (BD-243) ──")

    allowlist = _check_66_load_allowlist()

    any_fail = False
    scanned_files = 0
    bullets_scanned = 0
    over_cap_outside = 0
    over_cap_allowlisted = 0

    for doc_rel, marker in _CHECK_66_BULLET_SURFACE:
        doc_path = REPO_ROOT / doc_rel
        if not doc_path.is_file():
            ok(f"{doc_rel} absent — skipping that file (lenient)")
            continue
        scanned_files += 1
        snippets = allowlist.get(doc_rel, [])
        for lineno, char_len, first_line in _check_66_iter_bullets(doc_path, marker):
            bullets_scanned += 1
            if char_len <= _CHECK_66_BULLET_CHAR_CAP:
                continue
            covered = any(snip in first_line for snip in snippets)
            if covered:
                over_cap_allowlisted += 1
                continue
            over_cap_outside += 1
            any_fail = True
            fail(
                f"{doc_rel}:{lineno} — BD-243 Gate 1b bullet over the "
                f"{_CHECK_66_BULLET_CHAR_CAP}-char cap ({char_len} chars): "
                f"`{first_line.strip()[:80]}`. Per DESIGN-BD-243-DURABLE-"
                f"GATES.md §3 Gate 1, a single rule/bullet must not balloon "
                f"(the B1 mega-bullet pattern). This is a VOLUME measure only — "
                f"it asserts nothing about meaning. Remediation: reduce the "
                f"bullet's text amount (move detail to PACK-MEMORY-RATIONALE.md "
                f"/ a reference doc) OR, if it is irreducibly load-bearing, add "
                f"a pack-ops/.bullet-concision-allowlist.txt record (doc + a "
                f"snippet of the bullet's first line + a reason a reviewer "
                f"re-verifies). The allowlist is sized to the KEEP set EXACTLY "
                f"and MUST NOT be widened to admit a reducible bullet."
            )

    if not any_fail:
        ok(
            f"Check 66 — {scanned_files} bullet-surface file(s) scanned; "
            f"{bullets_scanned} bullet(s) measured; {over_cap_outside} over the "
            f"{_CHECK_66_BULLET_CHAR_CAP}-char cap outside the allowlist "
            f"(0 = clean); {over_cap_allowlisted} over-cap KEEP bullet(s) "
            f"admitted (irreducibly load-bearing)."
        )


__all__ = [
    "check_pack_memory_rationale_bijection",
    "_CHECK_46_ANTI_RESTATE_SURFACES",
    "_CHECK_46_ANTI_RESTATE_MIN_LEN",
    "_check_46_extract_pack_memory_imperative_bodies",
    "check_boundary_and_spawn_pointer_manifests",
    "_CHECK_44_FORBIDDEN_PATTERNS",
    "_CHECK_44_DURABLE_DOCS",
    "_check_44_load_allowlist",
    "check_durable_doc_concision",
    "_CHECK_66_BULLET_CHAR_CAP",
    "_TRINITY_MEMORY_H2_PACK",
    "_TRINITY_MEMORY_H2_PROJECT",
    "_CHECK_66_BULLET_SURFACE",
    "_check_66_iter_bullets",
    "_check_66_load_allowlist",
    "check_operating_doc_bullet_concision",
]
