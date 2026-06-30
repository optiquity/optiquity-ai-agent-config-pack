"""validate_checks.prompts — Cluster I: the per-agent prompt-directory family
(BD-256 W10).

This module owns Cluster I's 2 check bodies (Checks 6, 10) — the
`project-template/docs/pack/prompts/` per-agent prompt-template guards: the
prompts-directory FORMAT gate (6, per-agent frontmatter + variant→H2
consistency) and the prompt-template TRIAD compliance gate (10, every in-scope
variant carries `**Problem:**` / `**Goal:**` / `**Success criteria:**` + a
file-based completion-report indicator, modulo the kickoff `**Convention
exception:**` variant). The two are co-located because they both key on the
single prompts surface (`PROMPTS_DIR` = `project-template/docs/pack/prompts/`)
and scan the same per-agent `*.md` files.

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.prompts import *`,
so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each `check_*` name (6/10). Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster I checks):
the prompts-directory path constant `PROMPTS_DIR` and the frontmatter-key sets
`REQUIRED_PROMPT_FRONTMATTER` / `RESERVED_PROMPT_FRONTMATTER` (read by Check 6's
frontmatter rules and Check 10's directory existence guard). None of these is
read by a check outside Cluster I (verified by grep at the extraction wave: the
only consumers of `PROMPTS_DIR` / `REQUIRED_PROMPT_FRONTMATTER` /
`RESERVED_PROMPT_FRONTMATTER` are Checks 6 and 10), so no core promotion is
needed — they are Cluster-I-owned, not a >=2-module seam. No per-check test
reaches a Cluster I symbol (there is no `test-validate-pack-check-6.sh` /
`-10.sh`), so this is a zero-test-rework wave: the bodies move, `__all__`
generates, the facade re-import + V0/V1/V2/V3/V6 run; no test site is touched.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) are
imported `from .core` — the single SSOT for the spine + W1 seams. (`failures`
is imported for the V3 failures-identity invariant — `core.failures is
prompts.failures` — matching the W2–W9 module convention; the Cluster I bodies
append via `fail()`, never rebind `failures`.) Standard-library `re` is imported
directly at module top (Checks 6 and 10 use `re.match` / `re.findall` /
`re.compile` / `re.MULTILINE` / `re.DOTALL`), mirroring the established
per-module convention (the spine `import *` does not re-export stdlib names).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re

from .core import (
    REPO_ROOT,
    fail,
    ok,
    failures,
)


# ── Cluster-I-exclusive constants (read by Checks 6 and 10) ─────────────────
PROMPTS_DIR = REPO_ROOT / "project-template" / "docs" / "pack" / "prompts"
REQUIRED_PROMPT_FRONTMATTER = {"agent", "variants"}
RESERVED_PROMPT_FRONTMATTER = {"description", "deprecated-by", "notes"}


def check_prompts_directory() -> None:
    print("\n── Check 6: Prompts-directory format ──")
    if not PROMPTS_DIR.is_dir():
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — directory missing")
        return

    agent_files = sorted(PROMPTS_DIR.glob("*.md"))
    if not agent_files:
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — no per-agent prompt files found")
        return

    for f in agent_files:
        rel = f.relative_to(REPO_ROOT)
        content = f.read_text()

        # Rule 1: frontmatter opener + closer
        if not content.startswith("---\n"):
            fail(f"{rel} — no frontmatter (missing opening ---)")
            continue
        fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
        if not fm_match:
            fail(f"{rel} — malformed frontmatter (no closing ---)")
            continue
        fm = fm_match.group(1)

        # Parse frontmatter: simple line-based.
        # Supports `key: value` on one line and a `variants:` list in either
        # block style (indented `  - slug` lines) or inline `[a, b]` / `[]`.
        agent_value = None
        variants_slugs: list[str] = []
        seen_keys: list[str] = []
        current_list_key = None
        for line in fm.split("\n"):
            if not line.strip():
                current_list_key = None
                continue
            if line.startswith("  - "):
                if current_list_key == "variants":
                    variants_slugs.append(line[4:].strip())
                continue
            if line.startswith(" ") or line.startswith("\t"):
                # unrecognized indented content
                continue
            # top-level key line
            current_list_key = None
            if ":" in line:
                key, _, val = line.partition(":")
                key = key.strip()
                val = val.strip()
                seen_keys.append(key)
                if key == "agent":
                    agent_value = val
                elif key == "variants":
                    if val.startswith("["):
                        inner = val.strip("[]").strip()
                        if inner:
                            variants_slugs = [
                                s.strip().strip('"').strip("'") for s in inner.split(",")
                            ]
                        else:
                            variants_slugs = []
                    else:
                        # block-style list follows on subsequent indented lines
                        current_list_key = "variants"

        # Rule 2: required keys present
        missing = REQUIRED_PROMPT_FRONTMATTER - set(seen_keys)
        if missing:
            for m in sorted(missing):
                fail(f"{rel} — missing required frontmatter key: {m}")
            continue

        # Rule 3: no unknown top-level keys
        allowed = REQUIRED_PROMPT_FRONTMATTER | RESERVED_PROMPT_FRONTMATTER
        unknown = set(seen_keys) - allowed
        if unknown:
            for k in sorted(unknown):
                fail(f"{rel} — unknown frontmatter key: {k}")
            continue

        # Rule 4: stem matches agent: value
        if f.stem != agent_value:
            fail(f"{rel} — file stem '{f.stem}' does not match agent: '{agent_value}'")
            continue

        # Rule 5: variant slug ↔ H2 consistency
        body = content[fm_match.end():]
        h2_slugs = re.findall(r"^## Variant: (\S+)\s*$", body, re.MULTILINE)
        listed = set(variants_slugs)

        orphans = [s for s in h2_slugs if s not in listed]
        if orphans:
            fail(f"{rel} — orphan `## Variant:` H2 not listed in variants: {sorted(set(orphans))}")
            continue

        bad_slug = False
        for s in variants_slugs:
            count = h2_slugs.count(s)
            if count == 0:
                fail(f"{rel} — variant slug '{s}' listed but no matching `## Variant: {s}` H2")
                bad_slug = True
            elif count > 1:
                fail(f"{rel} — variant slug '{s}' has {count} `## Variant: {s}` H2s (expected 1)")
                bad_slug = True
        if bad_slug:
            continue

        ok(f"{rel} — {len(variants_slugs)} variant(s)")


def check_prompt_triad_compliance() -> None:
    print("\n── Check 10: Prompt template triad compliance ──")
    if not PROMPTS_DIR.is_dir():
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — directory missing")
        return

    agent_files = sorted(PROMPTS_DIR.glob("*.md"))
    if not agent_files:
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — no per-agent prompt files found")
        return

    required_labels = ("**Problem:**", "**Goal:**", "**Success criteria:**")
    completion_indicators = ("REPORT FILE:", "**Completion report:**")
    exception_marker = "**Convention exception:**"
    variant_h2 = re.compile(r"^## Variant: (\S+)\s*$", re.MULTILINE)

    for f in agent_files:
        rel = f.relative_to(REPO_ROOT)
        content = f.read_text()

        # Body = text after the closing --- of YAML frontmatter, if present.
        if content.startswith("---\n"):
            fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
            body = content[fm_match.end():] if fm_match else content
        else:
            body = content

        matches = list(variant_h2.finditer(body))
        if not matches:
            ok(f"{rel} — 0 variant(s) (placeholder file)")
            continue

        in_scope_pass = 0
        exempt: list[str] = []
        file_failed = False

        for i, m in enumerate(matches):
            slug = m.group(1)
            start = m.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
            variant_body = body[start:end]

            # Rule N.1 — Kickoff exception detection
            if exception_marker in variant_body:
                exempt.append(slug)
                continue

            # Rule N.2 — Triad presence
            missing_labels = [lbl for lbl in required_labels if lbl not in variant_body]

            # Rule N.3 — File-based completion-report indicator
            has_report_indicator = any(ind in variant_body for ind in completion_indicators)

            if missing_labels or not has_report_indicator:
                missing = list(missing_labels)
                if not has_report_indicator:
                    missing.append("REPORT FILE: or **Completion report:**")
                fail(f"{rel} — Variant: {slug} — missing labeled section(s): {missing}")
                file_failed = True
                continue

            in_scope_pass += 1

        if not file_failed:
            if exempt:
                ok(
                    f"{rel} — {in_scope_pass} variant(s) pass triad+report-file rule "
                    f"({len(exempt)} exempt: {', '.join(exempt)})"
                )
            else:
                ok(f"{rel} — {in_scope_pass} variant(s) pass triad+report-file rule")


# ── __all__ — every Cluster-I-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.prompts import *` skips underscore names UNLESS they are
# listed here; and once `__all__` is declared it ALSO gates the non-underscore
# names — so the two `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The Cluster-I-exclusive
# constants `PROMPTS_DIR` / `REQUIRED_PROMPT_FRONTMATTER` /
# `RESERVED_PROMPT_FRONTMATTER` are enumerated so the facade re-exports them
# (they are non-underscore module-level names the facade carried before the
# split; re-exporting them keeps the facade's public surface byte-stable, and
# the `__all__` gate would otherwise still pass them through — listing them is
# the explicit, audited choice). The `from .core` spine (`REPO_ROOT`, `fail`,
# `ok`, `failures`) is NOT re-listed — those are core-owned (the facade
# re-exports them via `from validate_checks.core import *`); `__all__` enumerates
# only prompts's OWN symbols.
__all__ = [
    # ── Cluster-I-exclusive constants (read by Checks 6 and 10) ──
    "PROMPTS_DIR",
    "REQUIRED_PROMPT_FRONTMATTER",
    "RESERVED_PROMPT_FRONTMATTER",
    # ── Cluster I check bodies (6, 10) ──
    "check_prompts_directory",
    "check_prompt_triad_compliance",
]
