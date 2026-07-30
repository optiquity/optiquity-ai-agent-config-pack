"""validate_checks.trinity_markers — Check 91: trinity marker-section
well-formedness (BD-136).

The CLIENT trinity (`project-template/{CLAUDE,AGENTS,GEMINI}.md`) wraps its
project-owned customizations in `<!-- BEGIN project-owned -->` …
`<!-- END project-owned -->` marker pairs so they survive byte-identical across
pack updates (two shapes: Shape A body-wrap inside a pack section; Shape B a
whole project-owned section). This check validates that those markers — on the
pack's OWN shipped templates + seed files — are WELL-FORMED. It is the
static-analysis half of BD-136; the bash merge engine
(`scripts/lib/marker-preserve.sh`) is the runtime half. The two implement the
SAME pinned fence predicate (below) and are cross-checked by the shared fixture
`scripts/tests/fixtures/marker-fence-grammar/`.

Scope boundary (arch §4.3): Check 91 runs in the pack repo CI against the pack's
own project-template templates + seed files — it does NOT and cannot run on a
client's live trinity at update time. The merger's safety invariant + L-6 gate
are the client-side backstops; this validator is not a backstop for the client
merge path.

── The V-1..V-8 surface (BD-136 entry) ──────────────────────────────────────
  V-1  Well-formed pairs: matched count, no nesting, no orphan, BEGIN precedes
       its END. [all candidates]
  V-2  Each pair is Shape A (no heading inside the marked body) OR Shape B
       (BEGIN immediately precedes a heading; the region wraps a whole section).
       A partial wrap (a heading appears inside a Shape A body) is a defect. The
       `## Project addenda` seed slot is the ONE Shape A exception where H3/H4
       headings may appear inside the marked body. [all candidates]
  V-3  Fence-aware scan (the pinned predicate below): a marker inside a
       backtick fence is INERT (an illustrative example — not a real marker, not
       counted). This lets an all-fenced authoring doc (PM-CHAT.md) pass
       trivially. The fail-loud teeth: an UNTERMINATED fenced code block (a
       ``` opened but never closed) is rejected — it would silently swallow
       every subsequent real marker into inert state. [all candidates]
  V-4  The `## Project addenda` H2 exists AND contains ≥1 marker pair (the seed
       Shape A body wrap). Catches the absence-of-backing instance (a lost
       seed). [trinity-only]
  V-5  Trinity-symmetry: WARN (never fail) if the real marker-pair count differs
       across CLAUDE / AGENTS / GEMINI. [trinity-only]
  V-6  No H2/H3 name appears in BOTH Shape A and Shape B (nor twice in Shape B) —
       the override-mechanism contract (L-4). [all candidates]
  V-7  No `[CONDITIONAL]` literal appears ANYWHERE in a trinity file (O-3 — the
       strict any-literal reading, not H2-only; the retirement pass removes the
       preamble refs too). [trinity-only]
  V-8  A BEGIN marker carrying a `renamed-from "…"` annotation conforms to the
       L-10 grammar SYNTACTICALLY (double-quoted name(s), each an exact `## `/
       `### ` heading line). Semantic match (does the named canonical exist?) is
       the merger's job, not this validator's. [all candidates]

── The single pinned fence predicate (BD-136 S2) ────────────────────────────
A line whose first NON-whitespace run is >=3 backticks toggles fenced-code
state. A tilde (`~~~`) line is NOT a fence and a >3-backtick fence is out of
scope for wrapping marker examples. This Python validator and the bash merge
engine implement this SAME predicate; the shared fixture
`scripts/tests/fixtures/marker-fence-grammar/` (with its committed
`EXPECTED-TOKENS.tsv`) cross-checks the two parsers.

── Candidate set (SHOULD-5, `ci-guard-measure-then-bound`) ──────────────────
The candidate set is drawn from `git ls-files` (NEVER rglob/glob/os.walk — a
glob would enumerate a DIFFERENT set): the trinity ×3 ALWAYS, plus every
`project-template/docs/pack/*.md` file (the pathspec `*` spans `/`, so it also
reaches `docs/pack/prompts/*.md`) that CONTAINS the `<!-- BEGIN project-owned`
token. That token filter IS the candidate bound — today it resolves to exactly
PM-CHAT.md; a future `prompts/*.md` that grows a real (unfenced) marker
legitimately enters scope. O(lines) per `ci-check-runtime-compounding`: one
`git ls-files`, one read + one linear scan per candidate; no whole-tree walk,
no subprocess-per-row. SKIP-lenient for the docs/pack leg off a git work tree
(a scratch trinity_root outside REPO_ROOT skips it entirely).
"""

import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
    warn,
)

# Real markers are matched at LINE-START (after trim). This is STRICTER than the
# bash merger's `index(...)>0` (anywhere-on-line) probe on purpose: PM-CHAT.md
# carries an explanatory sentence that MENTIONS `<!-- BEGIN project-owned -->` /
# `<!-- END project-owned -->` inline inside prose; an anywhere probe would
# false-count those as real markers and orphan the file. The two predicates
# AGREE on the shared fence fixture (whose markers are all line-start), so the
# S2 cross-check holds.
_BEGIN_TOKEN = "<!-- BEGIN project-owned"
_END_TOKEN = "<!-- END project-owned"

_TRINITY_NAMES = ("CLAUDE.md", "AGENTS.md", "GEMINI.md")
_ADDENDA_H2 = "## Project addenda"
_CONDITIONAL_LITERAL = "[CONDITIONAL]"


def _count_real_marker_tokens(path) -> int:
    """Count REAL (out-of-fence) marker TOKENS in a file (pinned S2 predicate).

    The Python half of the two-parser cross-check: this MUST agree with the bash
    merger's `_mp_count_tokens` for every file in
    `scripts/tests/fixtures/marker-fence-grammar/`. Fence toggle = a line whose
    first non-whitespace run is >=3 backticks; a tilde line is NOT a fence.
    """
    n = 0
    infence = False
    for raw in Path(path).read_text().splitlines():
        if raw.lstrip().startswith("```"):
            infence = not infence
            continue
        if infence:
            continue
        t = raw.strip()
        if t.startswith(_BEGIN_TOKEN):
            n += 1
        if t.startswith(_END_TOKEN):
            n += 1
    return n


def _scan_markers(text: str) -> dict:
    """Single fence-aware walk producing everything V-1..V-8 need.

    Returns a dict with:
      regions            list of {shape, head, begin_ln, end_ln, begin_raw}
                         (shape "A"/"B"; head = the Shape A host H2 or the
                          Shape B owned heading, rstripped)
      errors             list of (code, message) for V-1/V-2 structural defects
                         (nest / orphan / partial / nohost)
      h2_list            ordered rstripped `## ` heading lines (fence-aware)
      real_pairs         count of BEGIN…END matched pairs (any shape)
      unterminated_fence line number of an unclosed ``` fence at EOF, else 0

    The Shape classification MIRRORS the bash merger's `_mp_regions`: the
    `## Project addenda` seed slot is Shape A even with inner headings; a
    non-seed Shape A region whose body precedes a heading is a partial wrap; a
    region whose first content is a heading is Shape B; a region with no
    enclosing H2 (above the first `## `) has no host.
    """
    infence = False
    fence_open_ln = 0
    curh2 = ""            # enclosing `## ` heading (outside a region + fence)
    region = None         # dict when a BEGIN is open
    regions = []
    errors = []
    h2_list = []
    real_pairs = 0

    for i, raw in enumerate(text.splitlines(), start=1):
        if raw.lstrip().startswith("```"):
            if not infence:
                infence, fence_open_ln = True, i
            else:
                infence = False
            if region is not None:
                region["sawbody"] = True   # fenced content counts as body
            continue
        if infence:
            if region is not None:
                region["sawbody"] = True
            continue

        t = raw.strip()
        is_begin = t.startswith(_BEGIN_TOKEN)
        is_end = t.startswith(_END_TOKEN)
        is_h2 = raw.startswith("## ")
        is_heading = is_h2 or raw.startswith("### ")

        if is_begin:
            if region is not None:
                errors.append(("nest",
                    f"nested BEGIN marker at line {i} (region still open from "
                    f"line {region['begin_ln']})"))
            region = {"begin_ln": i, "begin_raw": raw, "beginh2": curh2,
                      "ownh": "", "sawheading": False, "sawbody": False}
            continue

        if is_end:
            if region is None:
                errors.append(("orphan",
                    f"orphan END marker (no open BEGIN) at line {i}"))
                continue
            if region["beginh2"].startswith(_ADDENDA_H2):
                regions.append({"shape": "A", "head": region["beginh2"].rstrip(),
                                "begin_ln": region["begin_ln"], "end_ln": i,
                                "begin_raw": region["begin_raw"]})
            elif region["sawheading"]:
                regions.append({"shape": "B", "head": region["ownh"].rstrip(),
                                "begin_ln": region["begin_ln"], "end_ln": i,
                                "begin_raw": region["begin_raw"]})
            elif region["beginh2"].strip() == "":
                errors.append(("nohost",
                    f"project-owned marker region beginning at line "
                    f"{region['begin_ln']} has no enclosing H2 heading (it sits "
                    f"above the first `## `) — move it under a heading (Shape A) "
                    f"or wrap a whole section (Shape B)"))
            else:
                regions.append({"shape": "A", "head": region["beginh2"].rstrip(),
                                "begin_ln": region["begin_ln"], "end_ln": i,
                                "begin_raw": region["begin_raw"]})
            real_pairs += 1
            region = None
            continue

        if region is not None:
            if is_heading:
                if region["beginh2"].startswith(_ADDENDA_H2):
                    region["sawbody"] = True                  # seed: headings OK
                elif not region["sawheading"] and not region["sawbody"]:
                    region["sawheading"] = True               # Shape B owned head
                    region["ownh"] = raw
                elif region["sawheading"]:
                    pass                                      # extra Shape B head
                else:
                    host = region["beginh2"].strip() or "(preamble)"
                    errors.append(("partial",
                        f"heading inside a Shape A region under {host} at "
                        f"line {i} (a heading may not appear after body text "
                        f"inside a Shape A marked body — the `## Project "
                        f"addenda` seed slot is the only exception)"))
            elif t != "":
                region["sawbody"] = True
            continue

        if is_h2:
            curh2 = raw.rstrip()
            h2_list.append(raw.rstrip())

    if region is not None:
        errors.append(("orphan",
            f"unclosed BEGIN marker (opened at line {region['begin_ln']}) — no "
            f"matching END"))

    return {"regions": regions, "errors": errors, "h2_list": h2_list,
            "real_pairs": real_pairs,
            "unterminated_fence": fence_open_ln if infence else 0}


def _check_renamed_from_syntax(begin_raw: str):
    """V-8: SYNTACTIC conformance of a `renamed-from` annotation (L-10 grammar).

    Returns None if OK (or no annotation), else a defect message. The grammar:
    `<!-- BEGIN project-owned: renamed-from "<heading>"[, "<heading>"]* -->`
    where each <heading> is double-quoted and an exact `## `/`### ` heading
    line. Semantic match (does the heading exist in canonical?) is NOT checked
    here — that is the merger's job.
    """
    if "renamed-from" not in begin_raw:
        return None
    after = begin_raw.split("renamed-from", 1)[1]
    # Collect double-quoted names; a lone/odd quote leaves an unmatched tail.
    names, rest, in_quote, buf = [], after, False, ""
    for ch in after:
        if ch == '"':
            if in_quote:
                names.append(buf)
                buf = ""
            in_quote = not in_quote
        elif in_quote:
            buf += ch
    if in_quote:
        return (f"malformed `renamed-from` annotation (unbalanced quote): "
                f"{begin_raw.strip()[:100]!r}")
    if not names:
        return (f"`renamed-from` annotation with no double-quoted heading name: "
                f"{begin_raw.strip()[:100]!r}")
    for nm in names:
        if not (nm.startswith("## ") or nm.startswith("### ")):
            return (f"`renamed-from` name {nm!r} is not an exact `## `/`### ` "
                    f"heading line: {begin_raw.strip()[:100]!r}")
    return None


def _candidate_files(trinity_root: Path):
    """Return (trinity_files, extra_marker_files).

    trinity ×3 ALWAYS (from trinity_root); extra marker files = the token-
    filtered `<trinity_root>/docs/pack/*.md` set via `git ls-files` — only when
    trinity_root is under REPO_ROOT (a scratch root skips the docs/pack leg).
    """
    trinity_files = [trinity_root / n for n in _TRINITY_NAMES]
    extra = []
    try:
        rel = trinity_root.resolve().relative_to(REPO_ROOT.resolve())
    except ValueError:
        return trinity_files, extra          # scratch root: trinity only
    try:
        result = subprocess.run(
            ["git", "ls-files", f"{rel.as_posix()}/docs/pack/*.md"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return trinity_files, extra          # git absent → SKIP-lenient
    if result.returncode != 0:
        return trinity_files, extra          # not a work tree → SKIP-lenient
    for row in result.stdout.splitlines():
        row = row.strip()
        if not row:
            continue
        path = REPO_ROOT / row
        try:
            if _BEGIN_TOKEN in path.read_text():   # the candidate bound (SHOULD-5)
                extra.append(path)
        except OSError:
            continue
    return trinity_files, extra


def _validate_file(path: Path, label: str, is_trinity: bool) -> bool:
    """Validate one candidate. Returns True on a failure (any V-rule), else
    False. Emits per-defect `fail()` lines. WARN-only V-5 is handled by the
    caller (it is a cross-file comparison)."""
    rel = f"{label}/{path.name}"
    if not path.is_file():
        fail(f"{rel} — file missing")
        return True
    text = path.read_text()
    scan = _scan_markers(text)
    failed = False

    # V-3 — unterminated fence (fail-loud teeth on the fence-aware scan).
    if scan["unterminated_fence"]:
        fail(f"{rel}:V-3 — unterminated fenced code block opened at line "
             f"{scan['unterminated_fence']} (it would swallow every subsequent "
             f"marker as inert)")
        failed = True

    # V-1 / V-2 — structural pairing + shape defects.
    for _code, msg in scan["errors"]:
        fail(f"{rel}:V-1/V-2 — {msg}")
        failed = True

    # V-6 — no name in BOTH Shape A and Shape B (nor twice in Shape B).
    regions = scan["regions"]
    for i, ri in enumerate(regions):
        if ri["shape"] != "B" or not ri["head"]:
            continue
        for j, rj in enumerate(regions):
            if j != i and rj["head"] == ri["head"]:
                fail(f"{rel}:V-6 — heading {ri['head']!r} appears in both a "
                     f"Shape A and a Shape B region (or twice in Shape B) — "
                     f"the override contract forbids duplicate names")
                failed = True
                break

    # V-8 — renamed-from syntactic conformance (all candidates).
    for r in regions:
        msg = _check_renamed_from_syntax(r["begin_raw"])
        if msg:
            fail(f"{rel}:V-8 — {msg}")
            failed = True

    # V-4 / V-7 — trinity-only.
    if is_trinity:
        if _ADDENDA_H2 not in text:
            fail(f"{rel}:V-4 — missing `## Project addenda` H2")
            failed = True
        elif not any(r["shape"] == "A" and r["head"].startswith(_ADDENDA_H2)
                     for r in regions):
            fail(f"{rel}:V-4 — `## Project addenda` H2 present but carries no "
                 f"project-owned marker pair (the seed slot)")
            failed = True
        if _CONDITIONAL_LITERAL in text:
            fail(f"{rel}:V-7 — `[CONDITIONAL]` literal present (O-3: the "
                 f"retirement drops the prefix from every trinity surface)")
            failed = True

    return failed


def check_trinity_marker_wellformed(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 91 — trinity marker-section well-formedness (BD-136 V-1..V-8).

    Validates the pack's OWN client-trinity templates + seed files. Registered
    ONCE (project-template only — see the loud deviation note at the
    `validate-pack.py` registration site + the `core.py` count constant).

    Parameters:
        trinity_root: directory holding the 3 trinity files. `None` resolves to
            `REPO_ROOT / "project-template"`. A scratch root (outside REPO_ROOT,
            e.g. a per-check test tmpdir) validates the 3 trinity files only —
            the git-tracked docs/pack candidate leg is skipped.
        label: surface name used in FAIL/OK messages.
    """
    if trinity_root is None:
        trinity_root = REPO_ROOT / "project-template"
    print(f"\n── Check 91 [{label}]: Trinity marker-section well-formedness "
          f"(BD-136 V-1..V-8) ──")

    trinity_files, extra = _candidate_files(trinity_root)
    any_failed = False

    trinity_pair_counts = {}
    for path in trinity_files:
        if path.is_file():
            trinity_pair_counts[path.name] = \
                _scan_markers(path.read_text())["real_pairs"]
        if _validate_file(path, label, is_trinity=True):
            any_failed = True

    for path in extra:
        if _validate_file(path, label, is_trinity=False):
            any_failed = True

    # V-5 — trinity-symmetry WARN (never a failure). Only when all three
    # trinity files were present + parsed.
    if len(trinity_pair_counts) == 3 and len(set(trinity_pair_counts.values())) > 1:
        warn(f"[{label}] Check 91 V-5 — trinity marker-pair counts differ "
             f"across CLAUDE/AGENTS/GEMINI: {trinity_pair_counts} (advisory "
             f"only — asymmetric customization surfaces are allowed)")

    if not any_failed:
        n_extra = len(extra)
        ok(f"[{label}] Trinity + {n_extra} seed marker file(s) — all "
           f"project-owned marker pairs well-formed (V-1..V-8)")


__all__ = ["check_trinity_marker_wellformed"]
