#!/usr/bin/env bash
# pack-internal: true  (sourced derivation library; not a user-facing verb)
# groupings-lib.sh — the SHARED groupings derivation library: the single
# implementation of grouping scan / reverse lookup / derived status /
# derived target / dependency and cascade derivations, consumed by the
# sibling project scripts that present groupings (sourced, never edited
# by consumers).
#
# SOURCEABLE-ONLY: this file defines functions and has NO top-level side
# effects; nothing executes on source (the capability-tables.sh
# discipline). Consumers: `source "$(dirname "$0")/groupings-lib.sh"`.
#
# Contracts this library implements (the client-side SSOTs):
#   - docs/project/groupings/_rules.md — the groupings stream contract
#     (closed entry grammar; the fixed Kind enum; the reserved GRP-000
#     declared-ungrouped ledger; membership rules).
#   - docs/project/implementation-plan/_rules.md `## Entry schema` +
#     `## Target semantics` — the phase Status / Target vocabulary. The
#     `target-enum:` schema line is read at call time; its DECLARATION
#     ORDER is the ordinal scale.
#   - The labeled-line field grammar and the four-field dependency
#     grammar are byte-twins of the shipped scripts/validate-docs.sh
#     conformance parsers (first matching `**Field**:` / `Field:` /
#     `- Field:` line wins; `Blockers` / `Dependencies` / `Prerequisite`
#     contribute prereq edges, `Unblocks` contributes dependent edges;
#     refs to absent phase files and self-edges drop).
#
# TOKEN RELATIVE-ORDER FREEZE: the `target-enum:` declaration order IS
# the ordinal scale consumed here (current < next-release < next-minor <
# next-major < future-unassigned in the shipped contract). The relative
# order of existing tokens is frozen — the library derives ordinals from
# the contract, and its tests assert lib-ordinal == contract declaration
# order.
#
# ── Public API (the frozen surface; row grammars below) ────────────────
#   grp_scan <groupings-dir>
#       All GRP-*.md records, ascending numeric ID. Row (TAB-separated,
#       5 fields; title last):
#         GRP-NNN<TAB>kind<TAB>reserved|real<TAB>members-csv<TAB>title
#       members-csv = comma-joined phase-N tokens as declared (empty
#       when none). `reserved` iff ID == GRP-000 (hardcoded here; the
#       stream contract's `reserved-id:` schema key is the declared
#       twin — the tests assert the pair agrees).
#   grp_real <groupings-dir>
#       grp_scan rows filtered to the REAL set (GRP-000 excluded).
#   grp_reverse_lookup <groupings-dir> <phase-N>
#       Grouping IDs containing the phase, one per line, ascending.
#   grp_reverse_map <groupings-dir>
#       Rows `phase-N GRP-A,GRP-B` (memberships CSV ascending) for every
#       phase appearing in >=1 grouping, phase-number ascending.
#   grp_deps <groupings-dir> <impl-plan-dir>
#       Derived inter-grouping edges over the REAL set: rows `GRP-A GRP-B`
#       (A must precede B), derived from member-phase dependency edges,
#       deduplicated, ascending.
#   grp_order <groupings-dir> <impl-plan-dir>
#       Topological order over grp_deps edges; ties alphabetical by ID;
#       mutually-dependent groupings print as one
#       `interleaved: GRP-A GRP-B` cluster row.
#   grp_shared_with <groupings-dir> <GRP-NNN>
#       Real groupings sharing >=1 member with the argument (argument
#       excluded), ascending. GRP-000 as argument is refused (reserved).
#   grp_phase_status_map <impl-plan-dir>
#       Rows `phase-N <token>`, ascending; EPIC-ONLY (phase-part files
#       are skipped — a part inherits by containment, so a part-typed or
#       dangling member resolves to `unknown`, the same class). token =
#       the parsed `Status:` when it is one of
#       done / in-progress / not-started / blocked / deferred /
#       superseded, else `unknown` (missing field / empty value /
#       out-of-enum).
#   grp_phase_target_map <impl-plan-dir>
#       Rows `phase-N <token|-|unknown>`, ascending; EPIC-ONLY (a
#       part-typed file's `Target:` never enters the map — the shipped
#       gate's part skip mirrored); STATUS-BLIND pure parse. `-` =
#       absent; `unknown` = present-but-illegal or present-but-empty.
#   grp_implied_target_map <impl-plan-dir>
#       The implied-bound DISPLAY values: rows
#       `phase-N <impl|-|unknown> <via|->`, ascending, one per epic.
#       impl = `unknown` on propagation-poisoned phases and on
#       unreadable-status phases themselves; else the provable bound
#       token when defined; else `-`. via = the arg-min direct witness
#       (`via` is `-` whenever impl is `-` or `unknown`). Consumes the
#       library's own three parse points (status map, target map, the
#       single edge-parse point) — no fourth parse of any grammar.
#   grp_rollup_map <groupings-dir> <impl-plan-dir>
#       Machine rollup rows, REAL set only, ascending. Row grammar
#       (byte-stable; all fields always emitted):
#         GRP-NNN <derived> <D>/<A> <pct|-> b=N d=N s=N u=N tgt=<token|-|unknown> t=K
#       derived per the counter frame: EXCLUDED = superseded members;
#       ACTIVE = the rest (deferred and unknown members are ACTIVE and
#       non-done); D = done in ACTIVE; A = |ACTIVE|; counters b/d/s/u
#       over the full member set. pct = floor(100*D/A); `-` when A = 0
#       OR any member is unreadable (u > 0 never renders a clean
#       fraction). tgt = max over the declarer set (members non-done AND
#       non-superseded carrying a present legal `Target:`) on the
#       ordinal scale; `-` when no member declares; `unknown` when any
#       non-superseded member (done included) carries a
#       present-but-illegal `Target:`. t=K = the declarer count.
#   grp_rollup <groupings-dir> <impl-plan-dir> <GRP-NNN>
#       The single-grouping accessor: one machine row (same grammar).
#       GRP-000 is refused (reserved — the refusal is target-blind).
#   grp_cascade <groupings-dir> <impl-plan-dir>
#       The deferral/supersession cascade: sources = phases whose
#       `Status:` is deferred or superseded; the poisoned set = every
#       phase reachable from a source over the dependency edges. Rows,
#       sources first then poisoned, each ascending:
#         source phase-N status=<deferred|superseded> groups=<csv|->
#         poisoned phase-N via=<csv> groups=<csv|->
#       via = the direct predecessors inside the source+poisoned set
#       (the per-phase edge attribution); groups = the phase's grouping
#       memberships (reverse map; GRP-000 included), `-` when none.
#   grp_nudge_counts <groupings-dir> <impl-plan-dir>
#       One row `N=<n> M=<m> K=<k>`: N = real groupings declared; M =
#       living (non-superseded) epics in NO grouping and NOT declared
#       ungrouped; K = declared-stays-ungrouped LIVING phases (GRP-000
#       members, superseded excluded).
#   grp_render_flags <b> <d> <s> <u>
#       The counter-keyed display flags: `[N blocked] [N deferred]
#       [N superseded] [N unreadable]` — fixed render order b, d, s, u;
#       a flag renders iff its counter > 0; empty output when all zero.
#   grp_render_pct <pct-field>
#       The machine row's <pct|-> field rendered for display: `-` -> `—`,
#       else `(NN%)`.
#
# ── Typed errors (directory-level only; member-level facts are never
#    errors — an unreadable member is data, not a failure) ──────────────
#   On error a function prints ONE line to stderr and returns 1:
#     groupings-lib: ERROR(<code>): <message>
#   Codes: no-tree     a required directory does not exist
#          parse       a grouping entry is structurally unreadable, or
#                      the impl-plan stream contract's target vocabulary
#                      is missing/unusable (the message names the file)
#          unknown-id  a GRP-NNN argument not present in the tree
#          reserved    GRP-000 used as a relational/rollup argument
#          bad-ref     a malformed phase-N / GRP-NNN argument
#   grp_scan parse-strictness: structural extraction failures fail
#   (missing/mismatched bold-pair header, Entry-Type != grouping,
#   missing/empty Kind, missing Member-phases field, a member token not
#   matching phase-N). Value-level conformance (Kind enum membership,
#   member order/duplicates, exception-field arity, byte canonicality)
#   is the validation gate's job — the library carries those records
#   as declared.
#
# Known scope note: the maps are epic-keyed. An off-contract phase-part
# FILE that carries its own `Status:` is treated as never-legible here
# (parts inherit by containment); the shipped gate reads such a file's
# raw field. On conforming trees (parts carry Entry-Type only) the two
# readers agree; the divergence is confined to that off-contract shape.
#
# Bash 3.2 + BSD utils compatible; the derivations run in one embedded
# python3 pass per call (the validate-docs.sh pattern; python3 is
# already a project dependency). One bounded scandir per tree; no
# subprocess-per-entry; rebuild-every-time (no cache).

# ── The single embedded derivation pass ────────────────────────────────
# All grammars are parsed HERE, once each: the grouping entry grammar,
# the phase Status/Target labeled-line grammar, and the four-field
# dependency edge grammar. Every mode composes these shared parses.
grp__py() {
    if ! command -v python3 >/dev/null 2>&1; then
        printf 'groupings-lib: python3 not found — required for groupings derivations\n' >&2
        return 1
    fi
    GRP_MODE="$1" GRP_DIR="${2:-}" GRP_IMPL="${3:-}" GRP_ARG="${4:-}" \
    python3 - <<'PYEOF'
import os
import re
import sys

MODE = os.environ["GRP_MODE"]
GDIR = os.environ.get("GRP_DIR", "")
IDIR = os.environ.get("GRP_IMPL", "")
ARG = os.environ.get("GRP_ARG", "")

RESERVED_ID = "GRP-000"
# Tightened entry regex: exactly 3 digits zero-padded through GRP-999,
# unpadded 4+ digits from GRP-1000 (the stream contract's numbering
# sentence, enforced).
ENTRY_RE = re.compile(r"^GRP-(\d{3}|[1-9]\d{3,})\.md$")
GRP_ID_RE = re.compile(r"^GRP-(\d{3}|[1-9]\d{3,})$")
PHASE_FILE_RE = re.compile(r"^phase-(\d+)\.md$")
PHASE_TOKEN_RE = re.compile(r"^phase-\d+$")
# The six-token phase status vocabulary (the shipped impl-plan contract's
# status-enum; the cross-parser test asserts the pair agrees).
STATUS_TOKENS = ("done", "in-progress", "not-started", "blocked",
                 "deferred", "superseded")


def die(code, msg):
    sys.stderr.write("groupings-lib: ERROR(%s): %s\n" % (code, msg))
    sys.exit(1)


# ── Labeled-line field grammar (validate-docs.sh conformance twin) ──
def field_present(body, field):
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + re.escape(field) + r"\*{0,2}\s*:",
        re.MULTILINE)
    return rx.search(body) is not None


def field_value(body, field):
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + re.escape(field) + r"\*{0,2}\s*:(.*)$",
        re.MULTILINE)
    m = rx.search(body)
    if not m:
        return ""
    return m.group(1).strip().strip("*").strip()


# ── Grouping entry parse (the ONE grouping-grammar parse point) ──────
def scan_groupings(gdir):
    if not os.path.isdir(gdir):
        die("no-tree", "no groupings tree at %s" % gdir)
    recs = []
    for name in os.listdir(gdir):
        if not ENTRY_RE.match(name):
            continue
        path = os.path.join(gdir, name)
        if not os.path.isfile(path):
            continue
        try:
            body = open(path, encoding="utf-8").read()
        except OSError as e:
            die("parse", "%s: unreadable (%s)" % (name, e))
        gid = name[:-3]
        m = re.search(r"(?m)^\*\*(GRP-\d+) — (.*?)\*\*\s*$", body)
        if not m:
            die("parse",
                "%s: missing bold-pair header **GRP-NNN — <Title>**" % name)
        if m.group(1) != gid:
            die("parse", "%s: header ID %s != filename ID %s"
                % (name, m.group(1), gid))
        title = m.group(2)
        if field_value(body, "Entry-Type").lower() != "grouping":
            die("parse", "%s: Entry-Type must be 'grouping'" % name)
        kind = field_value(body, "Kind")
        if not kind:
            die("parse", "%s: missing or empty Kind field" % name)
        if not field_present(body, "Member-phases"):
            die("parse", "%s: missing Member-phases field" % name)
        mval = field_value(body, "Member-phases")
        members = []
        if mval.strip():
            for tok in mval.split(","):
                tok = tok.strip()
                if not PHASE_TOKEN_RE.match(tok):
                    die("parse",
                        "%s: Member-phases token '%s' is not phase-N"
                        % (name, tok))
                members.append(tok)
        flag = "reserved" if gid == RESERVED_ID else "real"
        recs.append((gid, kind, flag, members, title))
    recs.sort(key=lambda r: int(r[0][4:]))
    return recs


def real_recs(recs):
    return [r for r in recs if r[2] == "real"]


def groups_of_map(recs):
    """phase-num -> sorted list of grouping IDs (ALL records)."""
    out = {}
    for gid, _kind, _flag, members, _title in recs:
        for m in members:
            out.setdefault(m[6:], []).append(gid)
    for num in out:
        out[num].sort(key=lambda g: int(g[4:]))
    return out


# ── Phase entry collection + the three phase-side parse points ──────
def load_phases(idir):
    if not os.path.isdir(idir):
        die("no-tree", "no implementation-plan tree at %s" % idir)
    entries = {}
    for name in os.listdir(idir):
        m = PHASE_FILE_RE.match(name)
        if not m:
            continue
        try:
            entries[m.group(1)] = open(
                os.path.join(idir, name), encoding="utf-8").read()
        except OSError:
            entries[m.group(1)] = ""
    return entries


def build_status_map(entries):
    """EPIC-ONLY `phase-num -> token` (token in STATUS_TOKENS or
    'unknown'). Part-typed files get NO row — a part-typed member
    resolves like a dangling one (containment)."""
    out = {}
    for num, body in entries.items():
        if field_value(body, "Entry-Type").lower() == "phase-part":
            continue
        val = field_value(body, "Status")
        out[num] = val if val in STATUS_TOKENS else "unknown"
    return out


def load_target_enum(idir):
    """The `target-enum:` tokens from the impl-plan _rules.md `## Entry
    schema` block (declaration order IS the ordinal scale)."""
    rules = os.path.join(idir, "_rules.md")
    try:
        text = open(rules, encoding="utf-8").read()
    except OSError:
        die("parse", "cannot read %s — the target vocabulary lives in the "
            "stream contract's target-enum schema line" % rules)
    in_sec = False
    for line in text.splitlines():
        if line.startswith("## Entry schema"):
            in_sec = True
            continue
        if in_sec and line.startswith("## "):
            break
        if in_sec and line.startswith("- ") and ":" in line:
            key, _, val = line[2:].partition(":")
            if key.strip() == "target-enum":
                toks = val.strip().split()
                if toks:
                    return toks
                break
    die("parse", "no usable target-enum in %s — the target vocabulary is "
        "undefined" % rules)


def build_target_map(entries, enum_tokens):
    """EPIC-ONLY, STATUS-BLIND `phase-num -> token|-|unknown` (a
    part-typed file's Target never enters the map — the shipped gate's
    part skip mirrored)."""
    out = {}
    for num, body in entries.items():
        if field_value(body, "Entry-Type").lower() == "phase-part":
            continue
        if not field_present(body, "Target"):
            out[num] = "-"
            continue
        val = field_value(body, "Target")
        out[num] = val if val in enum_tokens else "unknown"
    return out


def build_edges(entries):
    """The single edge-parse point (validate-docs.sh _conf_index_edges
    twin, over ALL entries): (a, b) = a-must-precede-b. Blockers /
    Dependencies / Prerequisite give prereq edges; Unblocks gives
    dependent edges. Self-edges + refs to absent phase files drop."""
    present = set(entries)
    edges = set()
    for num, body in entries.items():
        prereq = set()
        for fld in ("Blockers", "Dependencies", "Prerequisite"):
            prereq |= set(re.findall(r"phase-(\d+)", field_value(body, fld)))
        dep = set(re.findall(r"phase-(\d+)", field_value(body, "Unblocks")))
        for b in prereq:
            if b in present and b != num:
                edges.add((b, num))
        for u in dep:
            if u in present and u != num:
                edges.add((num, u))
    return present, edges


# ── Graph helpers (deterministic; validate-docs.sh algorithm twins) ──
def scc_ids(nodes, edge_set, keyfn):
    adj = dict((n, []) for n in nodes)
    radj = dict((n, []) for n in nodes)
    for (a, b) in edge_set:
        adj[a].append(b)
        radj[b].append(a)
    order = []
    seen = set()
    for root in sorted(nodes, key=keyfn):
        if root in seen:
            continue
        seen.add(root)
        stack = [(root, iter(adj[root]))]
        while stack:
            node, it = stack[-1]
            advanced = False
            for s in it:
                if s not in seen:
                    seen.add(s)
                    stack.append((s, iter(adj[s])))
                    advanced = True
                    break
            if not advanced:
                order.append(node)
                stack.pop()
    comp = {}
    cid = 0
    for node in reversed(order):
        if node in comp:
            continue
        comp[node] = cid
        queue = [node]
        while queue:
            n = queue.pop()
            for s in radj[n]:
                if s not in comp:
                    comp[s] = cid
                    queue.append(s)
        cid += 1
    return comp


def kahn(nodes, edge_set, keyfn):
    indeg = dict((p, 0) for p in nodes)
    adj = dict((p, []) for p in nodes)
    for (a, b) in edge_set:
        adj[a].append(b)
        indeg[b] += 1
    ready = sorted((p for p in nodes if indeg[p] == 0), key=keyfn)
    order = []
    while ready:
        n = ready.pop(0)
        order.append(n)
        for m in sorted(adj[n], key=keyfn):
            indeg[m] -= 1
            if indeg[m] == 0:
                ready.append(m)
        ready.sort(key=keyfn)
    if len(order) < len(nodes):
        order.extend(sorted((p for p in nodes if p not in set(order)),
                            key=keyfn))
        return order, False
    return order, True


# ── The implied-bound display map (epic rows) ────────────────────────
def implied_rows(entries, smap, tmap, enum_tokens, edges):
    ordinal = dict((t, i) for i, t in enumerate(enum_tokens))
    fu_ord = ordinal.get("future-unassigned", len(enum_tokens))
    present = set(entries)

    def tok(n):
        return smap.get(n, "unknown")

    absorbing = set(n for n in present if tok(n) in ("done", "superseded"))
    live = present - absorbing
    legible = set(n for n in live if tok(n) != "unknown")
    sources = set(n for n in live
                  if tok(n) == "unknown" or tmap.get(n) == "unknown")

    ledges = set((a, b) for (a, b) in edges if a in live and b in live)
    lcomp = scc_ids(live, ledges, int)
    csize = {}
    for n in live:
        csize[lcomp[n]] = csize.get(lcomp[n], 0) + 1
    cyc = set(n for n in live if csize[lcomp[n]] > 1)
    bad = sources | cyc

    radj = dict((n, []) for n in live)
    for (a, b) in ledges:
        radj[b].append(a)
    poisoned = set(cyc)
    frontier = list(bad)
    visited = set()
    while frontier:
        n = frontier.pop()
        if n in visited:
            continue
        visited.add(n)
        for p in radj[n]:
            poisoned.add(p)
            if p not in visited:
                frontier.append(p)

    r0 = set((a, b) for (a, b) in edges if a in legible and b in legible)
    comp = scc_ids(legible, r0, int)
    r = set((a, b) for (a, b) in r0 if comp[a] != comp[b])
    atom = {}
    for n in legible:
        t = tmap.get(n)
        if t not in (None, "-", "unknown") and ordinal[t] < fu_ord:
            atom[n] = ordinal[t]
    adj_r = dict((n, []) for n in legible)
    for (a, b) in r:
        adj_r[a].append(b)
    order, _acyclic = kahn(legible, r, int)
    known = {}
    witness = {}
    for node in reversed(order):
        best = None
        best_w = None
        for d in sorted(adj_r[node], key=int):
            a_d = atom.get(d)
            k_d = known.get(d)
            if a_d is not None and (k_d is None or a_d <= k_d):
                c = a_d
            elif k_d is not None:
                c = k_d
            else:
                continue
            if best is None or c < best:
                best = c
                best_w = d
        if best is not None:
            known[node] = best
            witness[node] = best_w

    rows = []
    for n in sorted(smap, key=int):
        if n in poisoned or tok(n) == "unknown":
            impl, via = "unknown", "-"
        elif n in known:
            impl, via = enum_tokens[known[n]], "phase-" + witness[n]
        else:
            impl, via = "-", "-"
        rows.append("phase-%s %s %s" % (n, impl, via))
    return rows


# ── The rollup (derived status + derived target, one member scan) ────
def rollup_row(rec, smap, tmap, enum_tokens):
    gid, _kind, _flag, members, _title = rec
    ordinal = dict((t, i) for i, t in enumerate(enum_tokens))
    toks = [smap.get(m[6:], "unknown") for m in members]
    b = toks.count("blocked")
    d = toks.count("deferred")
    s = toks.count("superseded")
    u = toks.count("unknown")
    active = [t for t in toks if t != "superseded"]
    A = len(active)
    D = active.count("done")
    nd = [t for t in active if t != "done"]
    if not toks:
        derived = "unknown"
    elif u > 0:
        derived = "unknown"
    elif A == 0:
        derived = "superseded"
    elif D == A:
        derived = "complete"
    elif d > 0 and all(t == "deferred" for t in nd):
        derived = "deferred"
    elif d > 0:
        derived = "blocked"
    elif nd and all(t == "blocked" for t in nd):
        derived = "blocked"
    elif D == 0 and all(t in ("not-started", "blocked") for t in active):
        derived = "not-started"
    else:
        derived = "in-progress"
    pct = "-" if (A == 0 or u > 0) else str((100 * D) // A)
    poison = False
    declared_ords = []
    for m in members:
        num = m[6:]
        st = smap.get(num, "unknown")
        tv = tmap.get(num)
        if st != "superseded" and tv == "unknown":
            poison = True
        if st not in ("done", "superseded") and \
                tv not in (None, "-", "unknown"):
            declared_ords.append(ordinal[tv])
    K = len(declared_ords)
    if poison:
        tgt = "unknown"
    elif K == 0:
        tgt = "-"
    else:
        tgt = enum_tokens[max(declared_ords)]
    return "%s %s %d/%d %s b=%d d=%d s=%d u=%d tgt=%s t=%d" % (
        gid, derived, D, A, pct, b, d, s, u, tgt, K)


# ── Mode dispatch ────────────────────────────────────────────────────
def emit(lines):
    for ln in lines:
        sys.stdout.write(ln + "\n")


if MODE in ("scan", "real"):
    recs = scan_groupings(GDIR)
    if MODE == "real":
        recs = real_recs(recs)
    emit("%s\t%s\t%s\t%s\t%s" % (gid, kind, flag, ",".join(members), title)
         for (gid, kind, flag, members, title) in recs)

elif MODE == "reverse-lookup":
    if not PHASE_TOKEN_RE.match(ARG):
        die("bad-ref", "'%s' is not a phase-N reference" % ARG)
    recs = scan_groupings(GDIR)
    emit(gid for (gid, _k, _f, members, _t) in recs if ARG in members)

elif MODE == "reverse-map":
    recs = scan_groupings(GDIR)
    gmap = groups_of_map(recs)
    emit("phase-%s %s" % (num, ",".join(gmap[num]))
         for num in sorted(gmap, key=int))

elif MODE == "shared-with":
    if not GRP_ID_RE.match(ARG):
        die("bad-ref", "'%s' is not a GRP-NNN reference" % ARG)
    if ARG == RESERVED_ID:
        die("reserved", "%s is the reserved declared-ungrouped ledger — "
            "it answers no relational query" % RESERVED_ID)
    recs = scan_groupings(GDIR)
    reals = real_recs(recs)
    mine = None
    for (gid, _k, _f, members, _t) in reals:
        if gid == ARG:
            mine = set(members)
            break
    if mine is None:
        die("unknown-id", "no such grouping: %s" % ARG)
    emit(gid for (gid, _k, _f, members, _t) in reals
         if gid != ARG and mine.intersection(members))

elif MODE == "deps":
    recs = scan_groupings(GDIR)
    entries = load_phases(IDIR)
    _present, edges = build_edges(entries)
    gmap = groups_of_map(real_recs(recs))
    dep_pairs = set()
    for (a, b) in edges:
        for ga in gmap.get(a, []):
            for gb in gmap.get(b, []):
                if ga != gb:
                    dep_pairs.add((ga, gb))
    emit("%s %s" % (ga, gb) for (ga, gb) in
         sorted(dep_pairs, key=lambda p: (int(p[0][4:]), int(p[1][4:]))))

elif MODE == "order":
    recs = scan_groupings(GDIR)
    entries = load_phases(IDIR)
    _present, edges = build_edges(entries)
    reals = real_recs(recs)
    nodes = set(gid for (gid, _k, _f, _m, _t) in reals)
    gmap = groups_of_map(reals)
    dep_pairs = set()
    for (a, b) in edges:
        for ga in gmap.get(a, []):
            for gb in gmap.get(b, []):
                if ga != gb:
                    dep_pairs.add((ga, gb))
    comp = scc_ids(nodes, dep_pairs, str)
    clusters = {}
    for n in nodes:
        clusters.setdefault(comp[n], []).append(n)
    for cid in clusters:
        clusters[cid].sort()
    cnodes = set(clusters)
    cedges = set((comp[a], comp[b]) for (a, b) in dep_pairs
                 if comp[a] != comp[b])
    corder, _ac = kahn(cnodes, cedges, lambda c: clusters[c][0])
    rows = []
    for cid in corder:
        members = clusters[cid]
        if len(members) == 1:
            rows.append(members[0])
        else:
            rows.append("interleaved: " + " ".join(members))
    emit(rows)

elif MODE == "status-map":
    entries = load_phases(IDIR)
    smap = build_status_map(entries)
    emit("phase-%s %s" % (n, smap[n]) for n in sorted(smap, key=int))

elif MODE == "target-map":
    entries = load_phases(IDIR)
    enum_tokens = load_target_enum(IDIR)
    tmap = build_target_map(entries, enum_tokens)
    emit("phase-%s %s" % (n, tmap[n]) for n in sorted(tmap, key=int))

elif MODE == "implied-map":
    entries = load_phases(IDIR)
    enum_tokens = load_target_enum(IDIR)
    smap = build_status_map(entries)
    tmap = build_target_map(entries, enum_tokens)
    _present, edges = build_edges(entries)
    emit(implied_rows(entries, smap, tmap, enum_tokens, edges))

elif MODE in ("rollup-map", "rollup"):
    recs = scan_groupings(GDIR)
    if MODE == "rollup":
        if not GRP_ID_RE.match(ARG):
            die("bad-ref", "'%s' is not a GRP-NNN reference" % ARG)
        if ARG == RESERVED_ID:
            die("reserved", "%s is the reserved declared-ungrouped ledger "
                "— it has no derived status" % RESERVED_ID)
    entries = load_phases(IDIR)
    enum_tokens = load_target_enum(IDIR)
    smap = build_status_map(entries)
    tmap = build_target_map(entries, enum_tokens)
    reals = real_recs(recs)
    if MODE == "rollup":
        match = [r for r in reals if r[0] == ARG]
        if not match:
            die("unknown-id", "no such grouping: %s" % ARG)
        reals = match
    emit(rollup_row(rec, smap, tmap, enum_tokens) for rec in reals)

elif MODE == "cascade":
    recs = scan_groupings(GDIR)
    entries = load_phases(IDIR)
    smap = build_status_map(entries)
    _present, edges = build_edges(entries)
    gmap = groups_of_map(recs)
    sources = set(n for n in smap if smap[n] in ("deferred", "superseded"))
    adj = {}
    for (a, b) in edges:
        adj.setdefault(a, []).append(b)
    poisoned = set()
    frontier = list(sources)
    visited = set()
    while frontier:
        n = frontier.pop()
        if n in visited:
            continue
        visited.add(n)
        for dnode in adj.get(n, []):
            if dnode not in sources:
                poisoned.add(dnode)
            if dnode not in visited:
                frontier.append(dnode)
    marked = sources | poisoned
    rows = []
    for n in sorted(sources, key=int):
        gcsv = ",".join(gmap.get(n, [])) or "-"
        rows.append("source phase-%s status=%s groups=%s"
                    % (n, smap[n], gcsv))
    radj = {}
    for (a, b) in edges:
        radj.setdefault(b, []).append(a)
    for n in sorted(poisoned, key=int):
        via = sorted((p for p in radj.get(n, []) if p in marked), key=int)
        vcsv = ",".join("phase-" + p for p in via) or "-"
        gcsv = ",".join(gmap.get(n, [])) or "-"
        rows.append("poisoned phase-%s via=%s groups=%s" % (n, vcsv, gcsv))
    emit(rows)

elif MODE == "nudge-counts":
    recs = scan_groupings(GDIR)
    entries = load_phases(IDIR)
    smap = build_status_map(entries)
    reals = real_recs(recs)
    n_count = len(reals)
    g0_members = []
    for (gid, _k, flag, members, _t) in recs:
        if flag == "reserved":
            g0_members = members
            break
    realmem = set()
    for (_g, _k, _f, members, _t) in reals:
        realmem.update(members)
    k_count = sum(1 for m in g0_members
                  if m[6:] in smap and smap[m[6:]] != "superseded")
    m_count = sum(1 for num in smap
                  if smap[num] != "superseded"
                  and ("phase-" + num) not in realmem
                  and ("phase-" + num) not in g0_members)
    sys.stdout.write("N=%d M=%d K=%d\n" % (n_count, m_count, k_count))

else:
    die("bad-ref", "unknown mode '%s'" % MODE)
PYEOF
}

# ── Public API (thin wrappers over the single derivation pass) ─────────
grp_scan()               { grp__py scan          "$1" ""   ""; }
grp_real()               { grp__py real          "$1" ""   ""; }
grp_reverse_lookup()     { grp__py reverse-lookup "$1" ""  "$2"; }
grp_reverse_map()        { grp__py reverse-map   "$1" ""   ""; }
grp_deps()               { grp__py deps          "$1" "$2" ""; }
grp_order()              { grp__py order         "$1" "$2" ""; }
grp_shared_with()        { grp__py shared-with   "$1" ""   "$2"; }
grp_phase_status_map()   { grp__py status-map    ""   "$1" ""; }
grp_phase_target_map()   { grp__py target-map    ""   "$1" ""; }
grp_implied_target_map() { grp__py implied-map   ""   "$1" ""; }
grp_rollup_map()         { grp__py rollup-map    "$1" "$2" ""; }
grp_rollup()             { grp__py rollup        "$1" "$2" "$3"; }
grp_cascade()            { grp__py cascade       "$1" "$2" ""; }
grp_nudge_counts()       { grp__py nudge-counts  "$1" "$2" ""; }

# The counter-keyed display flags: fixed render order b, d, s, u; a flag
# renders iff its counter > 0 (pure presentation over the always-emitted
# machine counters); empty output when all four are zero.
grp_render_flags() {
    local out=""
    if [ "${1:-0}" -gt 0 ]; then out="${out}[$1 blocked] "; fi
    if [ "${2:-0}" -gt 0 ]; then out="${out}[$2 deferred] "; fi
    if [ "${3:-0}" -gt 0 ]; then out="${out}[$3 superseded] "; fi
    if [ "${4:-0}" -gt 0 ]; then out="${out}[$4 unreadable] "; fi
    printf '%s' "${out% }"
}

# The machine row's <pct|-> field rendered for display: `-` (no clean
# fraction: an empty ACTIVE set or an unreadable member) renders the
# em-dash; a numeric percent renders `(NN%)`.
grp_render_pct() {
    if [ "${1:-}" = "-" ]; then
        printf '—'
    else
        printf '(%s%%)' "${1:-0}"
    fi
}
