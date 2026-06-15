#!/usr/bin/env python3
# pack-internal: true  (CI shard-partition module; not a user-facing verb,
# not a client deliverable, not a runtime dependency of any pack OPERATION —
# invoked only by CI [the BD-219 C2 plan/tests-result jobs] and by the
# validate-pack shard-coverage guard [BD-219 C3 Check 60]).
#
# scripts/lib/ci-shard-plan.py — BD-219 single-source CI shard partition.
#
# THE single source of truth for how the CI `tests` job is partitioned into
# N parallel shards (BD-219 lever 1). Everything that needs to know "which
# test runs in which shard" reads it FROM HERE — there is no hand-maintained
# shard map anywhere. Because the partition is GENERATED from the wired-test
# list (parsed from .github/workflows/validate-pack.yml — the SAME parse
# validate-pack.py Check 42 uses) by an LPT bin-packer, shard-coverage drift
# is correct-by-construction: every wired KEEP test is assigned to exactly
# one shard, and a non-wired test is never assigned.
#
# Realized consumers (architect-doc-reality-reconciliation; never line
# numbers — they drift):
#   - BD-219 C2 `.github/workflows/validate-pack.yml` `plan` job  → --emit-matrix
#   - BD-219 C2 `.github/workflows/validate-pack.yml` `tests-result` job
#                                                                → --assert-coverage
#   - BD-219 C2 `tests` matrix per-shard fixture-build guard      → --shard N --needs-fixtures
#   - BD-219 C3 scripts/validate-pack.py check_ci_shard_coverage (Check 60)
#                                                                → --assert-coverage (mirror)
#
# Inputs:
#   - .github/workflows/validate-pack.yml  (the wired-test list)
#   - scripts/ci-shard-weights.tsv         (<script-path>\t<measured_seconds>)
#   - scripts/ci-test-wiring-allowlist.txt (intentionally-OUT scripts — excluded)
#
# Portable: stdlib only (no PyYAML, no network). macOS bash 3.2 / BSD-safe
# callers — this module is pure Python 3, invoked via `python3`.
#
# Modes (exactly one per invocation):
#   --emit-matrix
#       Print the GitHub Actions matrix JSON to stdout, one line:
#         {"include":[{"shard":1,"scripts":"a.sh b.sh ..."},...]}
#       for the `plan` job's `$GITHUB_OUTPUT`.
#   --assert-coverage
#       Exit 0 iff union(shards) == wired_KEEP_set AND shards pairwise-
#       disjoint AND the fixture cohesion group is co-located in one shard.
#       Exit non-zero (naming the drift) otherwise.
#   --shard N --needs-fixtures
#       Exit 0 iff shard N owns at least one fixture-dependent (cohesion-
#       group) test; exit 1 otherwise. Drives the conditional fixture build
#       in the matrix `tests` job (BD-219 §2.5).
#   --print-partition
#       Human-readable partition dump (debugging / IMPL-REPORT evidence).
#
# Tuning knobs (rarely changed):
#   --shards N   override the shard count (default 4 — BD-219 §2.2 knee).

import argparse
import json
import os
import re
import sys

# ── Locate the repo root from this file's location (scripts/lib/<this>). ──
_THIS = os.path.realpath(__file__)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(_THIS)))

WORKFLOW_PATH = os.path.join(REPO_ROOT, ".github", "workflows", "validate-pack.yml")
WEIGHTS_PATH = os.path.join(REPO_ROOT, "scripts", "ci-shard-weights.tsv")
ALLOWLIST_PATH = os.path.join(REPO_ROOT, "scripts", "ci-test-wiring-allowlist.txt")

# Default shard count — BD-219 §2.2 "the knee": 4 puts the slowest shard
# close to the irreducible 94 s floor while keeping aggregate setup small
# and the matrix legible. The partition is dynamic, so this is just a knob.
DEFAULT_SHARDS = 4

# Default (median) weight, in seconds, for a wired script that is absent
# from the weights TSV. Graceful degradation (BD-219 §6.5): a new/un-weighted
# test never breaks the partition — it only mildly unbalances it until the
# next weight refresh. Chosen as a rough median of the measured set.
DEFAULT_WEIGHT_S = 3.0

# ── Fixture COHESION GROUP (BD-219 §2.5). ──
# These wired tests depend on BUILT fixtures (test-fixtures/<name>/ —
# gitignored build artifacts). They MUST be co-located in ONE shard so that
# shard alone runs `build.sh --all --clean` + the BD-118 manifest-restore +
# `build.sh --verify` before they run, preserving the BD-163 step-ordering
# invariant. The set is a MEASURED input (each member's fixture dependency
# was confirmed by reading its header), not a guess. Stored as basenames so
# the match is path-prefix-agnostic (scripts/ vs scripts/tests/).
#
# Members (basename → fixture dependency, confirmed BD-219 C3 measure step):
#   test-v11-realistic-ot.sh      → built fixtures (BD-160/170 + per-entry)
#   test-migrator-skills.sh       → v10-realistic-ot (G1 golden snapshot)
#   test-persona-contracts.sh     → existing-project-mid-dev + v10-realistic-ot
#   test-dry-run-migration.sh     → v10-realistic-ot (T1 happy-path; NEW wire)
#   test-add-capability.sh        → v11-flat-file (group 2 e2e; NEW wire)
FIXTURE_COHESION_GROUP = frozenset({
    "test-v11-realistic-ot.sh",
    "test-migrator-skills.sh",
    "test-persona-contracts.sh",
    "test-dry-run-migration.sh",
    "test-add-capability.sh",
})


def _die(msg):
    """Print a loud error to stderr and exit non-zero."""
    sys.stderr.write("ci-shard-plan: " + msg + "\n")
    sys.exit(1)


def parse_wired_tests(workflow_text):
    """Parse the wired test-runner list from the workflow yml.

    Matches `run: bash <path>` step lines, EXCLUDING the `test-fixtures/
    build.sh` build/verify steps (those are fixture-build orchestration,
    not test runners). This is the SAME wired-set parse validate-pack.py
    Check 42 (generalized in BD-219 C3) uses, so the two never disagree on
    "what is wired."

    Returns a sorted list of unique script paths (repo-relative).
    """
    # Anchor on `run: bash ` then capture a scripts/... path ending in .sh.
    pat = re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")
    found = set()
    for line in workflow_text.splitlines():
        m = pat.search(line)
        if m:
            found.add(m.group(1))
    # Exclude the fixture build orchestration (test-fixtures/build.sh is not
    # under scripts/, so the scripts/ anchor already excludes it — but be
    # explicit about the intent for future readers).
    return sorted(found)


def load_allowlist():
    """Load the intentionally-OUT (STRIP) script set from the allowlist file.

    Format: one repo-relative script path per line; `#` comment lines and
    blank lines ignored; an inline `# reason` after the path is ignored.
    Returns a set of script paths. Missing file → empty set (graceful).
    """
    out = set()
    if not os.path.isfile(ALLOWLIST_PATH):
        return out
    with open(ALLOWLIST_PATH, "r") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            # Allow `path   # reason` — take the first whitespace token.
            path = line.split()[0]
            out.add(path)
    return out


def load_weights():
    """Load <script-path>\\t<seconds> rows from the weights TSV.

    `#` comment lines and blank lines ignored. A malformed seconds value
    falls back to the default weight (graceful, never breaks). Returns a
    dict {script_path: float_seconds}. Missing file → empty dict.
    """
    weights = {}
    if not os.path.isfile(WEIGHTS_PATH):
        return weights
    with open(WEIGHTS_PATH, "r") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                # Tolerate space-separated as a fallback.
                parts = line.split()
            if len(parts) < 2:
                continue
            path = parts[0].strip()
            try:
                secs = float(parts[1].strip())
            except ValueError:
                secs = DEFAULT_WEIGHT_S
            weights[path] = secs
    return weights


def _weight_for(path, weights):
    """Return the measured weight for a script, or the default if unknown."""
    return weights.get(path, DEFAULT_WEIGHT_S)


def _basename(path):
    return path.rsplit("/", 1)[-1]


def compute_partition(wired, allowlist, weights, n_shards):
    """LPT bin-pack the wired KEEP set into `n_shards` shards.

    KEEP set = wired − allowlist. The fixture cohesion group is PINNED into
    a single shard first (so the build/restore/verify triple stays
    co-located, BD-219 §2.5), then the remaining tests are LPT-assigned
    (longest-processing-time-first greedy: descending weight, each to the
    currently-lightest shard).

    Returns a list of `n_shards` lists, each a list of script paths in
    deterministic (weight-desc, then path) order.
    """
    keep = [s for s in wired if s not in allowlist]

    # Partition KEEP into cohesion-group members and the rest.
    cohesion = [s for s in keep if _basename(s) in FIXTURE_COHESION_GROUP]
    rest = [s for s in keep if _basename(s) not in FIXTURE_COHESION_GROUP]

    shards = [[] for _ in range(n_shards)]
    loads = [0.0] * n_shards

    def _assign(scripts):
        # LPT: sort descending by weight (ties broken by path for
        # determinism), assign each to the currently-lightest shard.
        ordered = sorted(
            scripts, key=lambda s: (-_weight_for(s, weights), s)
        )
        for s in ordered:
            idx = loads.index(min(loads))
            shards[idx].append(s)
            loads[idx] += _weight_for(s, weights)

    # Pin the ENTIRE cohesion group into the currently-lightest shard FIRST
    # (as one atomic unit), so build/restore/verify run once in that shard.
    if cohesion:
        idx = loads.index(min(loads))
        # Deterministic intra-group order (weight-desc then path).
        ordered_group = sorted(
            cohesion, key=lambda s: (-_weight_for(s, weights), s)
        )
        for s in ordered_group:
            shards[idx].append(s)
            loads[idx] += _weight_for(s, weights)

    _assign(rest)

    # Keep each shard's listing deterministic (weight-desc then path) so the
    # emitted matrix is stable across runs.
    for i in range(n_shards):
        shards[i] = sorted(
            shards[i], key=lambda s: (-_weight_for(s, weights), s)
        )
    return shards


def shard_owns_fixture(shard_scripts):
    """True iff this shard's script list includes a cohesion-group member."""
    return any(_basename(s) in FIXTURE_COHESION_GROUP for s in shard_scripts)


def _load_all(n_shards):
    """Read inputs and compute the partition. Returns (wired, allowlist,
    weights, shards)."""
    if not os.path.isfile(WORKFLOW_PATH):
        _die("workflow not found: " + WORKFLOW_PATH)
    with open(WORKFLOW_PATH, "r") as fh:
        workflow_text = fh.read()
    wired = parse_wired_tests(workflow_text)
    allowlist = load_allowlist()
    weights = load_weights()
    shards = compute_partition(wired, allowlist, weights, n_shards)
    return wired, allowlist, weights, shards


def cmd_emit_matrix(n_shards):
    _, _, _, shards = _load_all(n_shards)
    include = []
    for i, scripts in enumerate(shards, start=1):
        include.append({"shard": i, "scripts": " ".join(scripts)})
    # Compact single-line JSON (no spaces) for $GITHUB_OUTPUT cleanliness.
    print(json.dumps({"include": include}, separators=(",", ":")))
    return 0


def cmd_assert_coverage(n_shards):
    wired, allowlist, _, shards = _load_all(n_shards)
    keep_set = set(s for s in wired if s not in allowlist)

    # Union + disjointness.
    union = set()
    overlap = set()
    for scripts in shards:
        for s in scripts:
            if s in union:
                overlap.add(s)
            union.add(s)

    problems = []
    if overlap:
        problems.append(
            "shards are NOT pairwise-disjoint — duplicated: "
            + ", ".join(sorted(overlap))
        )
    missing = keep_set - union
    if missing:
        problems.append(
            "wired KEEP test(s) in NO shard: " + ", ".join(sorted(missing))
        )
    extra = union - keep_set
    if extra:
        problems.append(
            "shard contains non-wired/allowlisted script(s): "
            + ", ".join(sorted(extra))
        )

    # Fixture cohesion group must be co-located in exactly ONE shard.
    owning = [i for i, scripts in enumerate(shards, start=1)
              if shard_owns_fixture(scripts)]
    # Only consider cohesion members that are actually in the KEEP set
    # (a member could be unwired — then it is simply not partitioned).
    present_members = [s for s in keep_set
                       if _basename(s) in FIXTURE_COHESION_GROUP]
    if present_members and len(owning) != 1:
        problems.append(
            "fixture cohesion group is split across "
            + str(len(owning))
            + " shard(s) (must be exactly 1): shards "
            + ", ".join(str(x) for x in owning)
        )

    if problems:
        sys.stderr.write("ci-shard-plan --assert-coverage FAILED:\n")
        for p in problems:
            sys.stderr.write("  - " + p + "\n")
        return 1
    print(
        "ci-shard-plan --assert-coverage OK: "
        + str(len(keep_set))
        + " wired KEEP test(s) across "
        + str(n_shards)
        + " shard(s); union == wired_KEEP_set; pairwise-disjoint; "
        + "fixture cohesion group co-located in one shard."
    )
    return 0


def cmd_shard_needs_fixtures(n_shards, shard_n):
    _, _, _, shards = _load_all(n_shards)
    if shard_n < 1 or shard_n > len(shards):
        _die("--shard out of range 1.." + str(len(shards)) + ": " + str(shard_n))
    return 0 if shard_owns_fixture(shards[shard_n - 1]) else 1


def cmd_print_partition(n_shards):
    wired, allowlist, weights, shards = _load_all(n_shards)
    keep_set = set(s for s in wired if s not in allowlist)
    print("wired: %d   allowlisted (STRIP): %d   KEEP: %d   shards: %d"
          % (len(wired), len(allowlist), len(keep_set), n_shards))
    for i, scripts in enumerate(shards, start=1):
        load = sum(_weight_for(s, weights) for s in scripts)
        fx = " [FIXTURE-OWNER]" if shard_owns_fixture(scripts) else ""
        print("── shard %d  (load ~%.1fs, %d tests)%s ──"
              % (i, load, len(scripts), fx))
        for s in scripts:
            print("    %6.1fs  %s" % (_weight_for(s, weights), s))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="ci-shard-plan.py",
        description="BD-219 single-source CI shard partition (generated, "
                    "measure-balanced, coverage-correct-by-construction).",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--emit-matrix", action="store_true",
                      help="print the GitHub Actions matrix JSON")
    mode.add_argument("--assert-coverage", action="store_true",
                      help="exit non-zero unless union(shards)==wired_KEEP_set, "
                           "disjoint, cohesion-group co-located")
    mode.add_argument("--needs-fixtures", action="store_true",
                      help="(with --shard N) exit 0 iff shard N owns a "
                           "fixture-dependent test")
    mode.add_argument("--print-partition", action="store_true",
                      help="human-readable partition dump")
    parser.add_argument("--shard", type=int, default=None,
                        help="shard number (1-based; with --needs-fixtures)")
    parser.add_argument("--shards", type=int, default=DEFAULT_SHARDS,
                        help="shard count (default %d)" % DEFAULT_SHARDS)
    args = parser.parse_args(argv)

    if args.shards < 1:
        _die("--shards must be >= 1")

    if args.emit_matrix:
        return cmd_emit_matrix(args.shards)
    if args.assert_coverage:
        return cmd_assert_coverage(args.shards)
    if args.needs_fixtures:
        if args.shard is None:
            _die("--needs-fixtures requires --shard N")
        return cmd_shard_needs_fixtures(args.shards, args.shard)
    if args.print_partition:
        return cmd_print_partition(args.shards)
    # argparse `required=True` guarantees one mode; defensive fallthrough.
    _die("no mode selected")


if __name__ == "__main__":
    sys.exit(main())
