# scripts/lib/pack_provenance_keys.py — PER-KEY pack provenance for the
# structured (JSON / TOML) merge helpers.
#
# pack-internal: true  (imported only by scripts/merge-{json,toml}.py)
#
# WHAT THIS ANSWERS
#
# `scripts/lib/pack-provenance.sh` answers a WHOLE-FILE question: "are the
# client's bytes a blob the pack has ever held at this source path?" A `yes`
# licenses adopting the pack's file outright. A `no` licenses nothing — and a
# `no` is what one ordinary customization anywhere in the file produces.
#
# That whole-file bound is why an edited client stalls: with no BASE the
# key-merge cannot tell a STALE PACK value from a CLIENT edit, so its
# "both added with different values -> keep project value" rule protects the
# pack's own older value forever. Every diverged pack key in the file freezes,
# including keys the client never touched, and the run re-emits a `.pre-update`
# sidecar that the next run then refuses to start behind.
#
# This module answers the same provenance question one KEY at a time, and
# returns the missing BASE. It never decides the merge; it only supplies the
# common ancestor that lets the existing three-way rules decide correctly.
#
# THE DERIVATION, IN TWO STEPS
#
#   1. SELECT an ancestor. Score every historical pack blob at the source path
#      by how many of OURS's leaves it reproduces, and take the best. Ties go
#      to the OLDEST candidate — see TIE-BREAK below.
#
#   2. REFINE it per key. Wherever OURS's own value at a key is itself a value
#      the pack has held at that key, adopt OURS's value into the BASE. That
#      records "the client did not author this key", which is exactly what
#      makes the three-way take THEIRS there and deliver the pack's change.
#
# THE TWO STEPS ARE REDUNDANT ON THE MOTIVATING FILE, AND THAT IS THE POINT
#
# Measured against this repo's own object history at
# `project-template/.claude/settings.json`, driven by a client file that is
# missing the pack's newer `hooks` entry:
#
#   candidates (oldest-first) : 3
#   scores                    : [18, 18, 18]   -> a genuine tie
#   selected index            : 0              -> the tie-break keeps the OLDEST
#   selected `hooks`          : already EQUAL to the client's
#   selection-only BASE == refined BASE : True -> refinement is a NO-OP here
#
# So step 1 alone already produces the right ancestor on this file. Mutating
# each step out in turn, end-to-end through the merge helper on that same
# file, gives the whole picture:
#
#   shipped                             -> the missing key ARRIVES
#   refinement disabled                 -> the missing key ARRIVES
#   tie-break inverted to newest-wins   -> the missing key ARRIVES
#   BOTH disabled                       -> the missing key does NOT arrive
#
# The two steps are BELT-AND-BRACES: on THIS file each is independently
# sufficient and only removing both breaks it. Neither is dead code. Each is
# load-bearing on its own shape, and neither shape is this file:
#
#   * the TIE-BREAK, whenever a NEWER candidate carries a key OURS lacks —
#     select that one and the three-way reads the key as a project removal;
#   * REFINEMENT, whenever the best-scoring candidate's value at a key
#     differs from OURS's — selection alone then records the wrong ancestor.
#
# Both shapes are pinned by `scripts/tests/test-pack-provenance-keys.sh`, so
# removing either mechanism reds the suite: the tie-break at A3 and B1,
# refinement at A2, A6 and B6 — and group D re-proves refinement's bite by
# performing the mutation itself on every run.
#
# WHY DICTS AND SCALARS REFINE BUT LISTS DO NOT
#
# For a dict key or a scalar, adopting OURS's value into the BASE can only
# cause the merge to take THEIRS at that key — it can never delete client
# content, because the key stays present on every side. That is the same
# inference `pack_provenance_is_pack_authored` already makes for a whole file,
# applied at finer granularity, so it is strictly MORE conservative than the
# whole-file arm that already ships.
#
# For a LIST the inference is not the same shape and is not safe. `merge_list`
# reads an element that is in BASE but not in OURS as "the project removed it"
# and drops it from the result. So promoting an element into the BASE because
# some historical pack version happened to contain it would DELETE a value the
# client currently holds. Lists therefore keep the selected ancestor's list
# verbatim — or, at a key the selected ancestor does not have, are left out of
# the BASE entirely. Element-level provenance is deliberately not attempted,
# because its failure mode is client data loss rather than a stale key.
#
# WALKING THE UNION, NOT JUST THE SELECTED ANCESTOR'S KEYS
#
# Step 2 visits every key OURS holds, including keys the SELECTED ancestor
# does NOT have. Walking only the selected ancestor's keys re-opens the exact
# defect this module exists to close: a client on an old release whose file
# best matches a candidate PREDATING a key they nevertheless hold gets no BASE
# entry for it, so the merge falls back to "both added with different values
# -> keep project value" and the key freezes at rc 2, sidecar and all.
#
# At such a key there is no ancestor value to fall back to, so only the
# provenance test can answer: if some candidate has held OURS's value at that
# key, OURS's value IS the ancestor; if none has, the key is a genuine client
# addition and stays ABSENT from the BASE — recording an empty ancestor there
# would make the three-way read it as "the pack removed everything here".
#
# THE BOUNDS THIS LEAVES, STATED PLAINLY
#
# (1) A list element the SELECTED ancestor contains and THEIRS no longer does
# is dropped even if the client also holds it. That is the correct three-way
# reading — the pack retired the element and the client never edited it — and
# it is bounded by the selection: an element only enters the BASE by being in
# the ONE candidate that best explains the client's whole file, so "the client
# inherited it" is the reading the evidence supports. What does NOT happen is
# an element being pulled in from any OTHER candidate; that would make the
# drop unsupported by the evidence, and it is what the list rule above
# forbids.
#
# (2) The same shape at a dict key or a scalar: adopting OURS's value as the
# ancestor at a key THEIRS no longer ships makes the three-way honour the
# pack's retirement and drop a value the client currently holds. This is the
# intended semantics on both halves — a client's own deletion is honoured
# rather than silently re-granted — but it is not free, so it is NOT silent:
# the merge helpers run a post-merge census of everything OURS held that the
# result does not, and report it. See `pack-ops/MERGE-STRATEGY.md`
# § "What the derived BASE changes about removals".
#
# TIE-BREAK: OLDEST WINS, AND THE DIRECTION IS THE POINT
#
# Equal scores mean the candidates explain OURS equally well, so the choice is
# about which way to err. An OLDER ancestor holds FEWER of the pack's recent
# values, so:
#   * for a list, fewer elements are in BASE-minus-OURS, so fewer of the
#     pack's own additions are misread as "the project removed this" — the
#     pack's new entries are delivered instead of silently dropped;
#   * for a scalar, BASE is likelier to differ from OURS, which resolves to
#     "keep the project's value" — the client's edit is preserved.
# Both directions favour delivering pack content and preserving client
# content, which are the two things a refresh must not get wrong. A
# newest-wins tie-break inverts both.
#
# COST
#
# TWO subprocesses per structured file that actually reaches the key-merge:
# one `git rev-list` and one batched `git cat-file --batch`. Never one per
# key, and never one per candidate blob. Measured on this repo: the candidate
# population at each structured source path is 0-6 blobs and the `rev-list`
# costs ~36 ms. The derivation is skipped entirely when the caller already has
# a real BASE, and when the whole-file probe already proved OURS pack-authored.
#
# `removed_from_ours` adds NO subprocess of any kind: it is one walk of two
# in-memory documents, run once per merged file after the merge has finished.

from __future__ import annotations

import json
import subprocess
from typing import Any, Callable

__all__ = ["historical_docs", "derive_base", "canonical_item",
           "removed_from_ours", "emit_removal_notices",
           "NOTICE_COUNT_PREFIX"]

# "no ancestor value can be derived at this position". Distinct from None,
# which is a real JSON/TOML value and so cannot signal absence.
_UNDERIVABLE = object()


def _canonical(item: Any) -> str:
    """Stable comparison key for a list element.

    Mirrors the `key()` helper inside `merge_list` in both merge helpers, so
    "shared element" here means exactly what "same item" means there.
    """
    if isinstance(item, (str, int, float, bool)) or item is None:
        return repr(item)
    try:
        return json.dumps(item, sort_keys=True, default=repr)
    except (TypeError, ValueError):
        return repr(item)


# Public alias. The merge helpers reuse this for their post-merge drop census,
# so "same element" means ONE thing across the derivation and the census.
canonical_item = _canonical


def historical_docs(
    pack_root: str,
    source_relpath: str,
    parse: Callable[[str], Any],
) -> list[Any]:
    """Every distinct blob the pack has held at `source_relpath`, parsed.

    Returned OLDEST-FIRST, which is the order `derive_base`'s tie-break
    depends on. Blobs that do not parse under `parse` are skipped rather than
    raising: a source path whose format changed across history must degrade to
    the candidates that do parse, never abort the merge.

    Returns [] when git is unavailable, the path has no history, or nothing
    parses — the caller then keeps its existing empty-BASE behaviour.

    `--all` and `--full-history` mirror `scripts/lib/pack-provenance.sh`
    constraints 2 and 3: the baseline tag is not an ancestor of HEAD, so a
    HEAD-only walk loses exactly the blobs a stale client is sitting on.
    """
    try:
        listing = subprocess.run(
            ["git", "-C", pack_root, "rev-list", "--all", "--objects",
             "--full-history", "--", source_relpath],
            capture_output=True, text=True, check=False,
        )
    except (OSError, ValueError):
        return []
    if listing.returncode != 0:
        return []

    shas: list[str] = []
    seen: set[str] = set()
    for line in listing.stdout.splitlines():
        sha, _, path = line.partition(" ")
        # `--objects` interleaves bare commit shas (no path field) with
        # `<sha> <path>` rows. Only an exact path match is a candidate; a
        # tree row's path is a directory and can never equal a file path.
        if path == source_relpath and sha not in seen:
            seen.add(sha)
            shas.append(sha)
    if not shas:
        return []

    try:
        # Binary on purpose: `--batch` frames each payload by a BYTE count, so
        # the stream must be sliced as bytes. Text mode would decode first and
        # any multi-byte character would shift every subsequent frame.
        batch = subprocess.run(
            ["git", "-C", pack_root, "cat-file", "--batch"],
            input=("\n".join(shas) + "\n").encode("utf-8"),
            capture_output=True, check=False,
        )
    except (OSError, ValueError):
        return []
    if batch.returncode != 0:
        return []

    docs: list[Any] = []
    raw = batch.stdout
    pos = 0
    for _ in shas:
        nl = raw.find(b"\n", pos)
        if nl < 0:
            break
        header = raw[pos:nl].split()
        # `<sha> missing` for an unresolvable object: no payload follows.
        if len(header) != 3:
            pos = nl + 1
            continue
        try:
            size = int(header[2])
        except ValueError:
            break
        body = raw[nl + 1: nl + 1 + size]
        pos = nl + 1 + size + 1  # payload is followed by a bare newline
        try:
            docs.append(parse(body.decode("utf-8")))
        except Exception:
            continue

    docs.reverse()  # rev-list walks newest-first; the tie-break wants oldest
    return docs


def removed_from_ours(ours: Any, merged: Any, _path: str = "") -> list[str]:
    """Every value OURS holds that `merged` does not — the drop census.

    A pure POST-pass over two finished documents. It reads the merge's answer
    and never participates in reaching it, so no three-way rule is touched.

    It exists because a derived BASE makes a class of drop possible that a
    base-absent merge could not produce: the pack RETIRED a value the client
    still holds, so the three-way honours the retirement and removes it at
    rc 0 — no warning, no sidecar. That is the intended semantics (bound 2 in
    the module header), and the whole objection to it is that it would
    otherwise be invisible. The census is what makes it visible.
    """
    out: list[str] = []
    if isinstance(ours, dict):
        if not isinstance(merged, dict):
            return [_path or "(root)"]
        for k, v in ours.items():
            sub = f"{_path}.{k}" if _path else str(k)
            if k not in merged:
                out.append(sub)
            else:
                out.extend(removed_from_ours(v, merged[k], sub))
        return out
    if isinstance(ours, list):
        if not isinstance(merged, list):
            return [_path or "(root)"]
        have = {_canonical(x) for x in merged}
        for item in ours:
            if _canonical(item) not in have:
                shown = repr(item)
                if len(shown) > 60:
                    shown = shown[:57] + "..."
                out.append(f"{_path}[] {shown}")
        return out
    return out


#: Most a single run reports before collapsing the rest into a count. A
#: pathological input must not turn a disclosure into an unreadable wall.
_NOTICE_CAP = 20

#: The machine-readable half of the disclosure. `customization-preserve.sh`
#: greps for this exact token to put the count in the disposition report, so
#: it is a CONTRACT between the two files, not a message.
NOTICE_COUNT_PREFIX = "pack-retired-removals="


def emit_removal_notices(ours: Any, merged: Any, stream: Any) -> int:
    """Write the drop census to `stream` as `notice:` lines. Returns the count.

    Lives here, not in each merge helper, so the two helpers cannot drift into
    reporting the same event with different words.

    `notice:` and NOT `warning:` on purpose, and the distinction is
    load-bearing rather than cosmetic: a warning is what the helpers return
    rc 2 for, rc 2 is what writes a `.pre-update` sidecar, and a sidecar is
    what makes the next `--update` refuse to start. Reporting an INTENDED
    outcome through that channel would re-create the reconciliation loop this
    whole derivation exists to end.
    """
    census = removed_from_ours(ours, merged)
    if not census:
        return 0
    # STABLE MACHINE LINE, emitted first and exactly once. The disposition
    # report reads its count from HERE rather than by counting `notice:`
    # lines, so the truncation line below cannot inflate the total and a
    # reworded human line cannot silently change a reported number.
    # `scripts/tests/test-pack-provenance-keys.sh` group E pins the format.
    print(f"notice: {NOTICE_COUNT_PREFIX}{len(census)}", file=stream)
    for entry in census[:_NOTICE_CAP]:
        print(f"notice: {entry}: value the project held is not in the merge "
              f"result (the pack no longer ships it here)", file=stream)
    if len(census) > _NOTICE_CAP:
        print(f"notice: … and {len(census) - _NOTICE_CAP} more", file=stream)
    return len(census)


def _score(ours: Any, cand: Any) -> int:
    """How many of OURS's leaves `cand` reproduces.

    Driven by OURS's shape on purpose: a candidate is being judged on how well
    it explains the CLIENT's file, so keys the candidate has and OURS does not
    neither help nor hurt it.
    """
    if isinstance(ours, dict) and isinstance(cand, dict):
        return sum(_score(ours[k], cand[k]) for k in ours if k in cand)
    if isinstance(ours, list) and isinstance(cand, list):
        return len({_canonical(x) for x in ours} & {_canonical(x) for x in cand})
    return 1 if ours == cand else 0


def _refine(ours: Any, selected: Any, candidates: list[Any]) -> Any:
    """Step 2 — adopt OURS's value wherever the pack has held that value here.

    `candidates` holds every historical value AT THIS PATH (the recursion
    narrows it alongside `selected`), so the test is per-key, not whole-file.

    `selected` is `_UNDERIVABLE` at a key OURS holds that the SELECTED
    ancestor does not — those keys are visited too, see WALKING THE UNION in
    the module header. The return is `_UNDERIVABLE` when no ancestor can be
    derived at that position, and the caller drops the key from the BASE.
    """
    if any(ours == c for c in candidates):
        # The client's value here is one the pack itself has shipped at this
        # key, so the client did not author it. Recording it as the ancestor
        # makes the three-way read a divergence from THEIRS as a pack update
        # the client has not yet received.
        return ours

    sel_is_dict = isinstance(selected, dict)
    if isinstance(ours, dict) and (sel_is_dict or selected is _UNDERIVABLE):
        out: dict[Any, Any] = {}
        # The SELECTED ancestor's keys in its own order, then OURS's extras.
        keys = list(selected) if sel_is_dict else []
        keys += [k for k in ours if not (sel_is_dict and k in selected)]
        for key in keys:
            sub = [c[key] for c in candidates
                   if isinstance(c, dict) and key in c]
            if key in ours:
                sel_val = selected[key] if sel_is_dict and key in selected \
                    else _UNDERIVABLE
                val = _refine(ours[key], sel_val, sub)
                if val is not _UNDERIVABLE:
                    out[key] = val
            else:
                # Absent from OURS: keep the ancestor's value so the merge can
                # see the client's removal and honour it. Promoting OURS here
                # is impossible — there is no OURS value to promote.
                out[key] = selected[key]
        if selected is _UNDERIVABLE and not out:
            # Nothing anywhere under this key was ever pack-held, so the whole
            # subtree is a client addition. Recording `{}` would make the
            # three-way read it as "the pack removed everything here".
            return _UNDERIVABLE
        return out

    if selected is _UNDERIVABLE:
        # A list or scalar at a key the SELECTED ancestor lacks, whose value
        # no candidate has ever held: a client addition, so no ancestor.
        return _UNDERIVABLE

    # Lists and scalars: the selected ancestor verbatim. See the module header
    # for why list elements are never promoted into the BASE.
    return selected


def derive_base(ours: Any, docs: list[Any]) -> Any | None:
    """The derived common ancestor for OURS, or None when none can be derived.

    `docs` must be OLDEST-FIRST (what `historical_docs` returns).
    """
    if not docs:
        return None
    best_i = 0
    best_s = _score(ours, docs[0])
    for i in range(1, len(docs)):
        s = _score(ours, docs[i])
        # STRICTLY greater, walking oldest-first: ties keep the OLDER
        # candidate. See TIE-BREAK in the module header.
        if s > best_s:
            best_i, best_s = i, s
    derived = _refine(ours, docs[best_i], docs)
    # `selected` is a real document at the top level, so `_UNDERIVABLE` cannot
    # surface here — the guard is for the caller's contract, not for a path
    # this function can currently take.
    return None if derived is _UNDERIVABLE else derived
