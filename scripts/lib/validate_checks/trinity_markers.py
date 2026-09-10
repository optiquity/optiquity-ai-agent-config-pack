"""validate_checks.trinity_markers — trinity marker checks: Check 91
(marker-section well-formedness, BD-136) and Check 98 (shipped client-editable
content is marker-backed, BD-294).

Check 91 asks whether the marker pairs that EXIST are well-formed. Check 98 asks
the complementary question — whether the shipped editable content the client is
told to touch is BACKED by a pair at all, and whether any shipped line instructs
an edit the graft engine would silently undo. The two share this module's single
`_scan_markers` pass (one marker parser, one fence predicate); Check 98's own
section sits at the foot of the file with its full rationale.

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
  V-6  No duplicate owned name — the override-mechanism contract (L-4), in two
       legs. In-region: no H2/H3 name appears in BOTH Shape A and Shape B, nor
       twice in Shape B. Out-of-marker: no Shape B owned name ALSO occurs
       outside every pair (two sections of one name; the merger's graft can
       emit only one, so the out-of-marker copy would be lost silently).
       [all candidates]
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

import re
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
      regions            list of {shape, head, host, begin_ln, end_ln,
                         begin_raw} (shape "A"/"B"; head = the Shape A host H2
                         or the Shape B owned heading; host = the enclosing
                         `## ` section the BEGIN line sits in — the region's
                         span expressed as a section, equal to head for
                         Shape A; both rstripped)
      errors             list of (code, message) for V-1/V-2 structural defects
                         (nest / orphan / partial / nohost)
      h2_list            ordered rstripped `## ` heading lines (fence-aware)
      real_pairs         count of BEGIN…END matched pairs (any shape)
      unterminated_fence line number of an unclosed ``` fence at EOF, else 0
      fenced             set of 1-based line numbers inside a ``` fence (the
                         fence delimiter lines included). Check 98 consumes it
                         so the module carries ONE fence parser, not two — the
                         same single-predicate discipline the S2 cross-check
                         applies across the Python/bash pair.

    The Shape classification MIRRORS the bash merger's `_mp_regions`: the
    exact `## Project addenda` seed slot is Shape A even with inner
    H3-and-below headings; a non-seed Shape A region whose body precedes a
    heading is a partial wrap; a region whose first content is a heading is
    Shape B — including inside the seed slot, where a first-content `## `
    heading opens the project section it names; a region with no enclosing H2
    (above the first `## `) has no host.

    Design rationale for that shape rule:
    `maintenance-docs/v11-implementation/ARCHITECTURE-BD-294.md` §2. The
    mirrored consumer of the same design is `scripts/lib/marker-preserve.sh`
    `_mp_regions`; `scripts/tests/test-marker-preserve-bd136.sh` M-23 is the
    leg that proves the two agree. That agreement is scoped to the regions each
    parser DETECTS: the two carry a deliberate divergence in the marker-token
    predicate (bash matches the token anywhere on a line, this parser only at
    line start after trim), documented at `_BEGIN_TOKEN` above, so a file whose
    prose MENTIONS a marker inline is seen by one and not the other.
    """
    infence = False
    fence_open_ln = 0
    curh2 = ""            # enclosing `## ` heading (outside a region + fence)
    region = None         # dict when a BEGIN is open
    regions = []
    errors = []
    h2_list = []
    real_pairs = 0
    fenced = set()

    for i, raw in enumerate(text.splitlines(), start=1):
        if raw.lstrip().startswith("```"):
            fenced.add(i)
            if not infence:
                infence, fence_open_ln = True, i
            else:
                infence = False
            if region is not None:
                region["sawbody"] = True   # fenced content counts as body
            continue
        if infence:
            fenced.add(i)
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
            if region["sawheading"]:
                regions.append({"shape": "B", "head": region["ownh"].rstrip(),
                                "host": region["beginh2"].rstrip(),
                                "begin_ln": region["begin_ln"], "end_ln": i,
                                "begin_raw": region["begin_raw"]})
            elif region["beginh2"].rstrip() == _ADDENDA_H2:
                # Seed-slot exception: a Shape A body under the exact
                # `## Project addenda` H2 may carry project H3-and-below
                # headings — Shape A.
                regions.append({"shape": "A", "head": region["beginh2"].rstrip(),
                                "host": region["beginh2"].rstrip(),
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
                                "host": region["beginh2"].rstrip(),
                                "begin_ln": region["begin_ln"], "end_ln": i,
                                "begin_raw": region["begin_raw"]})
            real_pairs += 1
            region = None
            continue

        if region is not None:
            if is_heading:
                seed = region["beginh2"].rstrip() == _ADDENDA_H2
                # A first-content `## ` head opens its own section anywhere,
                # seed slot included; inside the seed slot an H3-and-below
                # head, or any head after body text, is seed body.
                if (not region["sawheading"] and not region["sawbody"]
                        and (is_h2 or not seed)):
                    region["sawheading"] = True               # Shape B owned head
                    region["ownh"] = raw
                elif region["sawheading"]:
                    pass                                      # extra Shape B head
                elif seed:
                    region["sawbody"] = True                  # seed body
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
            "unterminated_fence": fence_open_ln if infence else 0,
            "fenced": fenced}


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

    # V-6 (in-region leg) — no name in BOTH Shape A and Shape B (nor twice in
    # Shape B).
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

    # V-6 (out-of-marker leg) — a Shape B owned name that ALSO occurs OUTSIDE
    # every pair. The loop above compares regions to EACH OTHER, so it can never
    # see an out-of-marker heading; this leg is what covers that. `h2_list`
    # EXCLUDES in-region heads, so the intersection IS the defect and a
    # legitimate single-occurrence Shape B section cannot appear in it.
    # The merger counterpart is `scripts/lib/marker-preserve.sh`'s OURS-head
    # loop, which routes the same shape to a reconciliation sidecar: two
    # sections of one name, of which the graft can emit only one, so the
    # out-of-marker copy would otherwise be dropped silently.
    out_of_marker = set(scan["h2_list"])
    b_owned = {r["head"] for r in regions if r["shape"] == "B" and r["head"]}
    for head in sorted(b_owned & out_of_marker):
        fail(f"{rel}:V-6 — heading {head!r} appears BOTH inside a "
             f"project-owned marker pair and outside every pair — two sections "
             f"of one name; keep exactly one copy")
        failed = True

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
        elif not any(
                (r["shape"] == "A" and r["head"].startswith(_ADDENDA_H2))
                or (r["shape"] == "B" and r["host"].startswith(_ADDENDA_H2))
                for r in regions):
            # The seed pair satisfies V-4 in EITHER shape: a pair whose first
            # content is its own `## ` heading is Shape B wherever it sits, seed
            # slot included, so a client that fills the slot that way still
            # carries the seed pair. `host` is the region's span expressed as a
            # section — the same span idea the merger's OURS-head loop uses. One
            # host predicate serves both legs, so they cannot drift apart.
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


# ═══════════════════════════════════════════════════════════════════════════
# Check 98 — shipped client-editable trinity content must be marker-backed
# (BD-294 D3). Self-contained unit: constants, helpers, check body.
# ═══════════════════════════════════════════════════════════════════════════
#
# WHY: the shipped `project-template/{CLAUDE,AGENTS,GEMINI}.md` are grafted into
# a client's live trinity by `scripts/lib/marker-preserve.sh`. That engine keeps
# ONLY what sits inside a `<!-- BEGIN project-owned -->` … `<!-- END
# project-owned -->` pair. So two shipped shapes are un-obeyable by construction:
#
#   (1) a fill-in placeholder OUTSIDE a pair — the client's filled-in value is
#       not marker-backed, so the next graft silently reverts it to the
#       placeholder; and
#   (2) an instruction telling the client to DELETE shipped pack content — the
#       graft restores whatever the client deleted, so the instruction cannot be
#       honoured (and a whole-section deletion that also takes the preceding
#       `OPTIONAL:` comment sidecars the WRONG section).
#
# The guard runs at push time so the shape is caught when it is AUTHORED, not
# when a client hits it. The suppress-not-delete alternative the shipped
# comments now name lives in `project-template/docs/pack/PM-CHAT.md` § "How to
# add project-owned content to trinity files".
#
# measure-then-bound (`ci-guard-measure-then-bound`): the matching logic was run
# over the real trinity BEFORE the guard was written. Pre-remediation bytes: 57
# findings across the three files (30 unbacked-placeholder lines + 27
# unhonourable-instruction lines). Every one classified STRIP (a real defect,
# all fixed in the same BD); the KEEP set is 0, so there is NO allowlist constant
# at all — an absent allowlist cannot grow. Post-remediation: 0.
#
# absence-of-backing (`declare-verify-backing`): leg 1 keys on the placeholder
# being OUTSIDE a pair, not on pairs existing somewhere in the file. Strip the
# pair from around a placeholder and the guard FAILs — that mutant is asserted in
# `scripts/tests/test-validate-pack-check-98.sh`.
#
# Cost (`ci-check-runtime-compounding`): ONE `git ls-files` subprocess, then one
# read + one linear pass per file over 3 files (~1600 lines). No filesystem walk,
# no rglob, no subprocess-per-file. Fence state comes from the module's single
# `_scan_markers` pass, so the module carries ONE fence parser, not two.

# The negative lookahead excludes an inline markdown LINK whose text is an
# ALL-CAPS token (`[CLAUDE.md](./CLAUDE.md)`, `[MERGE-STRATEGY](…)`) — a link is
# a cross-reference, not a fill-in slot. Measured: the shipped placeholder
# census is 30 either way, and a line carrying BOTH still reports only the
# placeholder (`[^\]\n]` cannot cross a `]`, so a later link on the same line
# cannot suppress an earlier placeholder). KNOWN residual false-positive class:
# a bracketed ALL-CAPS acronym with no link target (`[README]`) is
# byte-indistinguishable from a bare placeholder (`[TRANSPORT]`) and is still
# flagged. That is the fail-loud reading; the remedy is a deliberate edit here,
# never an allowlist (the measured legitimate set is empty — see the header).
_C98_PLACEHOLDER_RE = re.compile(r"\[[A-Z][A-Z_]{2,}(?![^\]\n]*\]\()")

# The instruction vocabulary is a pair of MODULE-LEVEL constants (not an inline
# literal) so the shipped `OPTIONAL:` wording and this guard cannot drift apart
# unnoticed: the per-check test asserts the built regex matches 0 lines in the
# shipped files and >0 in a pre-remediation-shaped fixture.
_C98_DELETION_VERBS = (
    "delete", "deletes", "deleting", "remove", "removes", "removing",
    "strip", "strips", "stripping", "erase", "erases", "erasing",
    "drop", "drops", "dropping", "cut", "excise", "excises", "excising",
)
# Bounded to the MEASURED set (`ci-guard-measure-then-bound`): every member was
# re-run over BOTH the shipped trinity (must stay 0) and the pre-remediation
# bytes before landing. `file` (singular) is DELIBERATELY ABSENT — it is a
# common noun in this prose and measured 3 FALSE POSITIVES on the shipped
# trinity, one per file, all on the destructive-ops line `…`git worktree`
# (add/remove/prune) — on a file with uncommitted…`. Do not assume coverage of
# an unlisted noun: widen only after re-measuring both corpora.
_C98_PACK_CONTENT_NOUNS = (
    "section", "sections", "subsection", "subsections",
    "block", "blocks", "heading", "headings", "placeholder", "placeholders",
    "text", "files", "lines", "paragraph", "content",
)
# An instruction NOT to delete is the correct shipped wording, so it is spared —
# the same negated-sentence carve-out Check 94 LEG 2 applies to the Case-3 KEEP
# sentence. The set is deliberately tight: `does not` is NOT a member, so
# "If it does not apply, delete the entire section" still BITEs.
_C98_NEGATION_TOKENS = (
    "do not", "don't", "never", "must not", "should not", "shouldn't",
    "cannot", "can't", "rather than", "instead of", "without",
)
_C98_NEG_WINDOW = 24      # chars of lead text searched for a negation
_C98_GAP = 40             # max chars allowed between the verb and its object


def _c98_alt(words):
    """Regex alternation, longest-first so a `\\b` cannot clip a longer member."""
    return "|".join(re.escape(w) for w in sorted(words, key=len, reverse=True))


# The gap class excludes `.` — a period ends the sentence, which bounds a match
# to one clause — but ALLOWS a backtick, because a markdown code span between
# the verb and its object (``delete the `## iOS 26` section``) is the most
# likely re-introduction wording: the pack backticks section names everywhere.
# Measured: allowing the backtick adds 0 findings on the shipped trinity and
# leaves the pre-remediation count at 57. Residual: a code span containing a
# `.` still blocks the match — the sentence bound wins over the span.
_C98_INSTRUCTION_RE = re.compile(
    r"\b(?:" + _c98_alt(_C98_DELETION_VERBS) + r")\b"
    r"[^.\n]{0," + str(_C98_GAP) + r"}?"
    r"\b(?:" + _c98_alt(_C98_PACK_CONTENT_NOUNS) + r")\b",
    re.IGNORECASE)
_C98_NEGATION_RE = re.compile(
    r"\b(?:" + _c98_alt(_C98_NEGATION_TOKENS) + r")\b", re.IGNORECASE)


def _c98_candidate_files(trinity_root: Path):
    """Return `(available, paths)` — the git-TRACKED trinity ×3 under `trinity_root`.

    `available` is False when `trinity_root` sits outside REPO_ROOT, when the
    `git` binary is absent, or when the tree is not a git work tree — all three
    ⇒ the caller SKIPs lenient (a fresh non-git checkout is never a violation).
    Enumeration is git-TRACKED (`git ls-files`), NEVER a filesystem walk: an
    untracked stray `CLAUDE.md` is not shipped, so it is not this guard's
    business. ONE bounded subprocess. Resolves through the module's REPO_ROOT so
    a per-check test can monkeypatch it to a scratch repo (the Check 63/93
    technique).
    """
    try:
        rel = trinity_root.resolve().relative_to(REPO_ROOT.resolve())
    except ValueError:
        return (False, [])
    pathspecs = [(rel / name).as_posix() for name in _TRINITY_NAMES]
    try:
        result = subprocess.run(
            ["git", "ls-files", "--"] + pathspecs,
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [REPO_ROOT / row.strip()
                   for row in result.stdout.splitlines() if row.strip()])


def _c98_scan_text(text: str):
    """Return one file's findings: sorted list of (lineno, kind, evidence).

    ONE `_scan_markers` pass supplies BOTH the fenced-line set and the
    project-owned regions; then one linear pass over the lines.

    LEG 1 `unbacked-placeholder` — a `[UPPER_TOKEN` occurrence on a line that is
    NOT strictly inside a marker region. Reported once per line (the tokens are
    listed in the evidence), so the count is a LINE count. A line inside an
    UNCLOSED pair counts as unbacked: `_scan_markers` emits no region for an
    orphan BEGIN, which is the fail-loud reading — an unterminated pair backs
    nothing (Check 91 V-1 reports the orphan itself). A third shape lands the
    same way: a WELL-FORMED pair opened above the first `## ` heading also
    yields no region (`_scan_markers` reports it as `nohost`), so its contents
    are unbacked too — Check 91 fails that shape independently, so it can never
    ship.

    LEG 2 `unhonourable-instruction` — an affirmative deletion verb aimed at a
    pack-content noun. Matched on a SLIDING TWO-LINE WINDOW (line i joined to
    line i+1) so a phrase broken across a hard wrap is still caught; a match
    whose first character falls in the i+1 half is skipped because window i+1
    owns it — that attribution rule is what keeps the two-line window from
    double-counting. Leg 2 does NOT skip marker-backed lines: a seed pair's
    contents are shipped pack bytes too, so a delete-instruction inside one is
    just as un-obeyable.

    Both legs skip fenced lines AS ATTRIBUTION SITES: content inside a ``` fence
    is an illustrative example, not a shipped fill-in slot — the same INERT
    reading the pinned S2 fence predicate gives markers. Leg 2's WINDOW is the
    deliberate exception: the i+1 half is taken unconditionally, so a
    hard-wrapped instruction whose object half lands on a fence opener carrying
    a language tag is still attributed to the NON-fenced prose line that opened
    it. An instruction is an instruction however its object is typeset, and that
    reading is fail-loud (a red CI on a clean tree), never a silent miss.
    """
    scan = _scan_markers(text)
    fenced = scan["fenced"]
    backed = set()
    for region in scan["regions"]:
        backed.update(range(region["begin_ln"] + 1, region["end_ln"]))

    lines = text.splitlines()
    out = []
    for i, raw in enumerate(lines, start=1):
        if i in fenced:
            continue
        if i not in backed:
            tokens = sorted({m.group(0)
                             for m in _C98_PLACEHOLDER_RE.finditer(raw)})
            if tokens:
                out.append((i, "unbacked-placeholder",
                            ", ".join(t + "…]" for t in tokens)))
        window = raw + " " + (lines[i] if i < len(lines) else "")
        for m in _C98_INSTRUCTION_RE.finditer(window):
            if m.start() > len(raw):
                continue                      # window i+1 owns this match
            lead = window[max(0, m.start() - _C98_NEG_WINDOW):m.start()]
            if _C98_NEGATION_RE.search(lead):
                continue                      # "do not delete it" is the FIX
            out.append((i, "unhonourable-instruction", m.group(0)))
            break                             # one finding per line per leg
    out.sort()
    return out


def check_trinity_editable_marker_backed(trinity_root, label) -> None:
    """Check 98 — shipped client-editable trinity content must be marker-backed (BD-294).

    Two legs over the git-TRACKED client trinity (the section header above
    carries the WHY, the measure-then-bound record, and the cost argument):

      LEG 1  a fill-in placeholder OUTSIDE a `<!-- BEGIN/END project-owned -->`
             pair — the client's filled-in value would not survive the next
             graft. Catches the ABSENCE-of-backing instance (a placeholder whose
             enclosing pair was removed), not merely "pairs exist somewhere".
      LEG 2  an affirmative instruction to DELETE shipped pack content — the
             graft restores it, so the instruction cannot be honoured. A negated
             instruction ("suppress it — do not delete it") is the correct
             shipped wording and is spared.

    NO allowlist: the measured legitimate set is empty, and an absent allowlist
    cannot grow. NEVER vacuous: zero tracked trinity files with git AVAILABLE is
    a FAILURE, not a silent pass — and so is zero READABLE files among tracked
    ones, because `except OSError: continue` would otherwise let an empty corpus
    report the all-clear. Lenient: git absent / not a work tree / a root outside
    REPO_ROOT ⇒ SKIP.
    """
    print(f"\n── Check 98: [{label}] shipped client-editable trinity content is "
          f"marker-backed (BD-294) ──")
    available, paths = _c98_candidate_files(Path(trinity_root))
    if not available:
        ok(f"[{label}] git ls-files unavailable (git absent / not a git work "
           f"tree / root outside the repo) — skipping (lenient)")
        return
    if not paths:
        fail(f"[{label}] Check 98 — no git-TRACKED trinity file found under "
             f"{trinity_root} (expected {', '.join(_TRINITY_NAMES)}). The guard "
             f"refuses to pass vacuously: either the trinity moved and this "
             f"check's root is stale, or the shipped templates were untracked.")
        return

    findings = []
    scanned = 0
    for path in paths:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue                          # tracked but unreadable — skip
        scanned += 1
        for lineno, kind, evidence in _c98_scan_text(text):
            findings.append((path.name, lineno, kind, evidence))

    if not scanned:
        fail(f"[{label}] Check 98 — {len(paths)} git-TRACKED trinity file(s) "
             f"under {trinity_root}, but NONE could be read "
             f"({', '.join(p.name for p in paths)}). The guard refuses to pass "
             f"vacuously here too: `except OSError: continue` tolerates one "
             f"unreadable file so the rest are still scanned, but an EMPTY "
             f"corpus is 'nothing scanned', never 'nothing wrong' — restore "
             f"the tracked files in the work tree.")
        return

    if findings:
        counts = {}
        for _, _, kind, _ in findings:
            counts[kind] = counts.get(kind, 0) + 1
        detail = "; ".join(f"{n}:{ln} [{k}] {ev}"
                           for n, ln, k, ev in findings[:20])
        more = "" if len(findings) <= 20 else f" (+{len(findings) - 20} more)"
        # `findings` carries one entry per (file, line, LEG), so a line tripping
        # BOTH legs contributes two. The banner reports both numbers rather than
        # labelling one as the other: the LINE count is what a maintainer counts
        # when they open the file, and the FINDING count is what the `{kind: n}`
        # tally and the `(+N more)` overflow are computed from.
        n_lines = len({(n, ln) for n, ln, _, _ in findings})
        fail(
            f"[{label}] Check 98 — {n_lines} shipped trinity line(s) "
            f"({len(findings)} finding(s)) the "
            f"client cannot obey {counts}: {detail}{more}. `unbacked-placeholder` "
            f"= a fill-in slot outside a `<!-- BEGIN project-owned -->` … "
            f"`<!-- END project-owned -->` pair, so the client's value is "
            f"reverted by the next graft — wrap the placeholder in a seed pair. "
            f"`unhonourable-instruction` = an instruction to delete shipped pack "
            f"content, which the graft restores — reword it to suppress-not-"
            f"delete and point at `docs/pack/PM-CHAT.md` § \"How to add "
            f"project-owned content to trinity files\".")
        return

    ok(f"[{label}] Check 98 — {scanned} trinity file(s): every fill-in "
       f"placeholder sits inside a project-owned marker pair and no shipped line "
       f"instructs a deletion the graft would undo")


__all__ = ["check_trinity_marker_wellformed",
           "check_trinity_editable_marker_backed"]
