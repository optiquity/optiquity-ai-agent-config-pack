#!/usr/bin/env python3
#
# scripts/pm-deletion-boundary.py — client sub-agent deletion-boundary guard.
#
# A Claude Code PreToolUse hook (matcher `Bash`) that fires on a spawned
# sub-agent's Bash tool call and DENIES a deletion whose LITERAL target resolves
# OUTSIDE the firing agent's owned scratch dir AND outside the OS temp roots. It
# is defense-in-depth behind the unconditional "No destructive operations"
# project rule — a best-effort backstop for REGISTERED sub-agent spawns, NOT a
# guarantee.
#
# Ownership lookup: the firing agent's `agent_id` (present only for sub-agents;
# absent on the main thread) keys an append-only owned-dirs registry
# ({"agent_id","owned_dir"} JSON lines, last-match-wins). A registry MISS ->
# fail-open ALLOW.
#
# FAIL-OPEN at EVERY uncertainty (identical discipline to pm-modes-commit-gate.py):
# unparseable payload, missing agent_id (main thread), registry
# absent/unreadable/miss, an unresolvable ($VAR/$(...)) or redirect target, an
# absent cwd for a relative target, a target UNDER the owned dir or an OS temp
# root, ANY exception -> ALLOW (print nothing, exit 0). The body NEVER exits 2 —
# the deny is expressed via the JSON permissionDecision, not the exit code. A
# wrongful DENY would wedge legitimate agent cleanup in every clone, so every
# uncertain branch errs to ALLOW.
#
# v1 deny-set (CORE deletion verbs + mv-source): rm, rmdir, unlink, shred,
# truncate, `git rm`, `find <literal> -delete/-exec <core>`, `find <literal> |
# xargs <core>`, `mv <src>`. Leading env-assignment tokens (VAR=value) are
# skipped; `command`/`builtin`/`\` prefixes stripped; one `bash -c` peek. Honest
# residual false-NEGATIVES (variable-assembled literals, `bash -c` nesting > 1,
# command substitution, non-find xargs, exotic verbs) are documented in the
# runbook — defense-in-depth only, not a guarantee.
#
# In-dir cleanup is ALLOWED: deletes under the owned dir (including the owned dir
# itself) and under the OS temp roots never deny — the rule (not the hook)
# governs owned-dir-itself cleanup.
#
# Reads NO pm-session-config.json (the deletion boundary is a universal
# invariant, not a tunable mode).
#
# Dependency direction: a client-side hook — it is read only by the client
# .claude/settings.json (which wires it via `python3 ./scripts/pm-deletion-
# boundary.py`) and depends on no other file. It is a self-contained client copy;
# it shares no code with any pack-repo hook.
#
# Test seams (mirror pm-modes-commit-gate.py's MODES_GATE_* seams):
#   DELBOUND_REGISTRY_FILE — override the owned-dirs registry path (inject a
#                            scratch registry). Else resolved from XDG/HOME.
#   DELBOUND_TEMP_ROOTS    — override the OS-temp-root allowlist (colon-separated)
#                            for deterministic tests independent of $TMPDIR.
# Production leaves both unset.

import json
import os
import re
import shlex
import sys

# CORE destructive verbs: every non-option arg is a delete target.
_CORE_VERBS = frozenset({"rm", "rmdir", "unlink", "shred", "truncate"})

# Shell interpreters whose `-c <script>` string is peeked ONCE.
_SHELL_VERBS = frozenset({"bash", "sh", "zsh", "dash", "ksh"})

# Leading wrapper tokens the shell strips before the verb.
_VERB_WRAPPERS = frozenset({"command", "builtin"})

# Verb-specific option flags that CONSUME the following token as a value, so the
# target scan skips option+value pairs (avoids treating an option value as a
# path — a false-DENY hazard for shred/truncate).
_VALUE_FLAGS = {
    "shred": frozenset({"-n", "--iterations", "-s", "--size", "--random-source"}),
    "truncate": frozenset({"-s", "--size", "-r", "--reference", "-o", "--io-blocks"}),
}

# Global git options that CONSUME the following token as a value (git -C <path>,
# git -c k=v, ...) — reused verbatim from pm-modes-commit-gate.py.
_GIT_VALUE_OPTS = frozenset({
    "-C", "-c", "--git-dir", "--work-tree", "--namespace",
    "--exec-path", "--super-prefix",
})

# xargs options that CONSUME the following token as a value (so the command word
# is found after them).
_XARGS_VALUE_OPTS = frozenset({
    "-n", "-I", "-i", "-P", "-L", "-s",
    "--max-args", "--replace", "--max-procs", "--max-lines", "--max-chars",
})

# Default OS temp roots (delete-allowed) when DELBOUND_TEMP_ROOTS is unset:
# the classic /tmp forms + macOS /var/folders (and its /private symlink form).
# $TMPDIR (if set) is appended at runtime.
_DEFAULT_TEMP_ROOTS = (
    "/tmp", "/private/tmp", "/var/folders", "/private/var/folders",
)

# Glob metacharacters — a target is truncated to its literal prefix before the
# first of these.
_GLOB_METACHARS = "*?[{"

# Leading shell env-assignment token (VAR=value), skipped as the shell does.
_ENV_ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")


# ── Registry resolution + lookup ──────────────────────────────────────────────

def _registry_candidates():
    """Candidate owned-dirs registry paths, in lookup order. The
    DELBOUND_REGISTRY_FILE seam (if set) is the sole candidate; else check the
    $XDG_STATE_HOME form (if XDG_STATE_HOME set) then the $HOME/.local/state
    form (SHOULD-3 two-candidate check covers an XDG_STATE_HOME set in one env
    but not the other). Empty list if neither HOME nor XDG is available."""
    seam = os.environ.get("DELBOUND_REGISTRY_FILE")
    if seam:
        return [seam]
    rel = os.path.join("optiquity-pack-handoff", ".pm-agent-owned-dirs.jsonl")
    out = []
    xdg = os.environ.get("XDG_STATE_HOME")
    if xdg:
        out.append(os.path.join(xdg, rel))
    home = os.environ.get("HOME")
    if home:
        p = os.path.join(home, ".local", "state", rel)
        if p not in out:
            out.append(p)
    return out


def _owned_dir(agent_id):
    """The recorded owned_dir for `agent_id` (LAST-match-wins across the scanned
    candidate files), or None on any miss/failure (fail-open). A malformed line
    is skipped, not fatal."""
    found = None
    for path in _registry_candidates():
        if not path or not os.path.exists(path):
            continue
        try:
            with open(path) as fh:
                for line in fh:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        rec = json.loads(line)
                    except ValueError:
                        continue
                    if isinstance(rec, dict) and rec.get("agent_id") == agent_id:
                        od = rec.get("owned_dir")
                        if isinstance(od, str) and od:
                            found = od  # last-match-wins
        except OSError:
            continue
    return found


def _temp_roots():
    """The OS temp-root allowlist (each os.path.normpath'd). DELBOUND_TEMP_ROOTS
    (colon-separated) overrides for deterministic tests; else the default set
    plus $TMPDIR (if set)."""
    seam = os.environ.get("DELBOUND_TEMP_ROOTS")
    if seam:
        raw = [p for p in seam.split(":") if p]
    else:
        raw = list(_DEFAULT_TEMP_ROOTS)
        tmpdir = os.environ.get("TMPDIR")
        if tmpdir:
            raw.append(tmpdir)
    return [os.path.normpath(p) for p in raw]


# ── Command splitting (verbatim reuse + an operator-aware superset) ────────────

def _split_segments(cmd):
    """Split a shell command on the top-level operators that start a new simple
    command (&&, ||, ;, |, newline) — QUOTE-AWARE. An operator inside a single-
    or double-quoted string is NOT a boundary, so a literal `&&`/`;`/`|` inside a
    quoted argument (e.g. `echo "rm -rf /"`) can never expose a spurious verb.
    Quote state toggles on an unescaped quote char; a backslash escapes the next
    char outside quotes and inside double quotes (literal inside single quotes).

    Reused VERBATIM from scripts/pm-modes-commit-gate.py (the proven matcher).
    Fail-open direction: this can only ever REDUCE spurious segments — a real
    delete after a merged operator is still detected because the per-segment scan
    tokenizes the whole segment."""
    out = []
    buf = []
    quote = None  # None | "'" | '"' — the active quote context
    i = 0
    n = len(cmd)
    while i < n:
        ch = cmd[i]
        if ch == "\\" and quote != "'":
            buf.append(ch)
            if i + 1 < n:
                buf.append(cmd[i + 1])
                i += 2
            else:
                i += 1
            continue
        if quote is not None:
            buf.append(ch)
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch == "'" or ch == '"':
            quote = ch
            buf.append(ch)
            i += 1
            continue
        two = cmd[i:i + 2]
        if two in ("&&", "||"):
            out.append("".join(buf))
            buf = []
            i += 2
            continue
        if ch in (";", "|", "\n"):
            out.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    out.append("".join(buf))
    return out


def _split_with_ops(cmd):
    """`_split_segments` + the operator that ENDED each segment — a superset the
    verbatim splitter cannot express, needed ONLY to group segments into
    pipelines for the `find <literal> | xargs <core>` case. Same quote/escape
    handling; returns (segment, op) where op is '|','&&','||',';','\\n', or '' for
    the final segment."""
    out = []
    buf = []
    quote = None
    i = 0
    n = len(cmd)
    while i < n:
        ch = cmd[i]
        if ch == "\\" and quote != "'":
            buf.append(ch)
            if i + 1 < n:
                buf.append(cmd[i + 1])
                i += 2
            else:
                i += 1
            continue
        if quote is not None:
            buf.append(ch)
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch == "'" or ch == '"':
            quote = ch
            buf.append(ch)
            i += 1
            continue
        two = cmd[i:i + 2]
        if two in ("&&", "||"):
            out.append(("".join(buf), two))
            buf = []
            i += 2
            continue
        if ch in (";", "|", "\n"):
            out.append(("".join(buf), ch))
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    out.append(("".join(buf), ""))
    return out


def _pipelines(cmd):
    """Group segments into pipelines — maximal runs joined by a single `|`. A
    `&&`/`||`/`;`/newline (or end) ends the current pipeline. Returns a list of
    pipelines, each a list of segment strings."""
    pipelines = []
    current = []
    for seg, op in _split_with_ops(cmd):
        current.append(seg)
        if op == "|":
            continue
        pipelines.append(current)
        current = []
    if current:
        pipelines.append(current)
    return pipelines


# ── Token cleaning + verb identification ──────────────────────────────────────

def _tokenize(seg):
    """shlex tokens for a segment; naive whitespace split on an unbalanced
    quote (fail-open — the caller only ever REDUCES to allow on a bad parse)."""
    try:
        return shlex.split(seg)
    except ValueError:
        return seg.split()


def _strip_redirects(toks):
    """Drop shell redirection noise so a redirect target is never mistaken for a
    delete target (`rmdir x 2>/dev/null` -> the `2>/dev/null` token is not a
    target). Removes bare redirect operators (and the following filename) and any
    combined-form token containing `<`/`>`."""
    out = []
    skip_next = False
    for t in toks:
        if skip_next:
            skip_next = False
            continue
        if t in (">", ">>", "<", "<<", "2>", "1>", "&>", "2>>", "&>>"):
            skip_next = True  # a bare operator consumes its target filename
            continue
        if (">" in t) or ("<" in t):
            continue  # combined form (2>/dev/null, >out, 2>&1)
        out.append(t)
    return out


def _strip_leading(toks):
    """Strip leading env-assignment tokens (VAR=value) and `command`/`builtin`
    wrappers, as the shell does, so the verb is correctly identified through an
    env prefix (`TMPDIR=/x rm ...`) or wrapper (`command rm ...`)."""
    i = 0
    n = len(toks)
    while i < n and _ENV_ASSIGN_RE.match(toks[i]):
        i += 1
    while i < n and toks[i] in _VERB_WRAPPERS:
        i += 1
    return toks[i:]


def _clean(seg):
    """Tokenize -> drop redirects -> strip leading env/wrapper tokens."""
    return _strip_leading(_strip_redirects(_tokenize(seg)))


def _verb_of(token):
    """The dispatch verb for a leading token: strip a leading backslash (`\\rm`),
    take the basename (`/bin/rm` -> `rm`)."""
    if token.startswith("\\"):
        token = token[1:]
    return os.path.basename(token)


# ── Per-verb target extraction ────────────────────────────────────────────────

def _positional_targets(verb, args):
    """Non-option positional args of a CORE verb, skipping option+value pairs for
    the verbs that take a value flag (shred/truncate). `--` ends option parsing."""
    out = []
    skip_next = False
    end_opts = False
    value_flags = _VALUE_FLAGS.get(verb, frozenset())
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if end_opts:
            out.append(a)
            continue
        if a == "--":
            end_opts = True
            continue
        if a.startswith("-") and a != "-":
            if a in value_flags:
                skip_next = True
            continue
        out.append(a)
    return out


def _mv_sources(args):
    """mv source targets = all positional args except the destination (the last
    positional), unless -t/--target-directory is present (then ALL positionals
    are sources)."""
    positionals = []
    target_dir_mode = False
    skip_next = False
    end_opts = False
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if end_opts:
            positionals.append(a)
            continue
        if a == "--":
            end_opts = True
            continue
        if a.startswith("-") and a != "-":
            if a in ("-t", "--target-directory"):
                target_dir_mode = True
                skip_next = True
            elif a in ("-S", "--suffix"):
                skip_next = True
            elif a.startswith("--target-directory="):
                target_dir_mode = True
            continue
        positionals.append(a)
    if not positionals:
        return []
    if target_dir_mode:
        return positionals
    if len(positionals) < 2:
        return []  # `mv src` (no destination) — nothing certain
    return positionals[:-1]


def _git_rm_targets(args):
    """Targets of a `git rm <targets>` invocation (first non-option subcommand ==
    rm). git rm is also git-banned; the deny is intended. Global value-options
    (-C <path>, -c k=v, ...) consume their value."""
    j = 0
    n = len(args)
    while j < n:
        a = args[j]
        if a in _GIT_VALUE_OPTS:
            j += 2
            continue
        if a.startswith("-"):
            j += 1
            continue
        if a != "rm":
            return []  # first non-option subcommand is not `rm`
        return [t for t in args[j + 1:] if not t.startswith("-")]
    return []


def _find_roots(toks_after_find):
    """Leading literal path args of a `find` invocation (before the expression
    begins at the first `-primary` / `(` / `!`)."""
    roots = []
    for a in toks_after_find:
        if a.startswith("-") or a in ("(", ")", "!"):
            break
        roots.append(a)
    return roots


def _find_expr_deletes(toks_after_find):
    """True iff a find expression carries `-delete` or `-exec`/`-execdir <core>`."""
    i = 0
    n = len(toks_after_find)
    while i < n:
        a = toks_after_find[i]
        if a == "-delete":
            return True
        if a in ("-exec", "-execdir"):
            if i + 1 < n and _verb_of(toks_after_find[i + 1]) in _CORE_VERBS:
                return True
        i += 1
    return False


def _xargs_is_core(args):
    """True iff an `xargs` invocation runs a CORE deletion verb (the command word
    after the xargs options)."""
    skip_next = False
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if a.startswith("-"):
            if a in _XARGS_VALUE_OPTS:
                skip_next = True
            continue
        return _verb_of(a) in _CORE_VERBS
    return False


def _segment_targets(seg, depth):
    """Delete-target literals from ONE segment: CORE verbs, mv-source, git rm,
    find-with-delete/-exec, and a one-level `bash -c` peek."""
    toks = _clean(seg)
    if not toks:
        return []
    verb = _verb_of(toks[0])
    args = toks[1:]
    if verb in _CORE_VERBS:
        return _positional_targets(verb, args)
    if verb == "mv":
        return _mv_sources(args)
    if verb == "git":
        return _git_rm_targets(args)
    if verb == "find":
        if _find_expr_deletes(args):
            return _find_roots(args)
        return []
    if verb in _SHELL_VERBS:
        if depth >= 1:
            return []  # one peek only; deeper nesting -> fail-open
        for i, a in enumerate(args):
            if a == "-c" and i + 1 < len(args):
                return _delete_targets(args[i + 1], depth + 1)
        return []
    return []


def _find_xargs_targets(pipeline):
    """`find <literal> ... | ... | xargs <core-verb>`: the find-roots are delete
    targets. Precise (same-pipeline only) — a `find` and `xargs` separated by
    `;`/`&&` are in different pipelines and never combine."""
    if len(pipeline) < 2:
        return []
    find_roots = []
    has_xargs_core = False
    for stage in pipeline:
        toks = _clean(stage)
        if not toks:
            continue
        verb = _verb_of(toks[0])
        if verb == "find":
            find_roots.extend(_find_roots(toks[1:]))
        elif verb == "xargs":
            if _xargs_is_core(toks[1:]):
                has_xargs_core = True
    if find_roots and has_xargs_core:
        return find_roots
    return []


def _delete_targets(cmd, depth=0):
    """All concrete literal delete-target strings the command would act on
    (best-effort). Unresolvable targets ($VAR/$(...)/redirects) are NOT collected
    (fail-open — they never force a deny)."""
    targets = []
    for seg in _split_segments(cmd):
        targets.extend(_segment_targets(seg, depth))
    for pipeline in _pipelines(cmd):
        targets.extend(_find_xargs_targets(pipeline))
    return targets


# ── Target resolution + boundary decision ─────────────────────────────────────

def _glob_prefix(raw):
    """The literal path prefix up to (not including) the first glob metachar. A
    leading metachar yields '' (fully-glob -> unresolvable)."""
    cut = len(raw)
    for mc in _GLOB_METACHARS:
        p = raw.find(mc)
        if p != -1 and p < cut:
            cut = p
    return raw[:cut]


def _resolve_target(raw, cwd):
    """Resolve a raw target to an absolute normpath, or None if UNRESOLVABLE
    (shell var / command substitution / redirect char, a fully-glob prefix, ~
    with no HOME, or a relative path with no usable cwd -> fail-open)."""
    if not raw:
        return None
    if "$" in raw or "`" in raw or ">" in raw or "<" in raw:
        return None
    path = _glob_prefix(raw)
    if not path:
        return None
    if path == "~" or path.startswith("~/"):
        home = os.environ.get("HOME")
        if not home:
            return None
        path = home + path[1:]
    if not os.path.isabs(path):
        if not cwd or not os.path.isabs(cwd):
            return None  # relative target, no usable cwd -> fail-open
        path = os.path.join(cwd, path)
    return os.path.normpath(path)


def _is_under(path, root):
    """True iff `path` is `root` itself or nested beneath it (root normpath'd)."""
    root = os.path.normpath(root)
    if path == root:
        return True
    return path.startswith(root + os.sep)


def _first_out_of_bounds(cmd, cwd, owned_dir):
    """The first resolved delete target that lands OUTSIDE {owned_dir, temp
    roots}, or None if none does (-> allow). Unresolvable targets are skipped
    (fail-open); an under-owned or under-temp target is allowed."""
    temp_roots = _temp_roots()
    owned = os.path.normpath(owned_dir) if owned_dir else None
    for raw in _delete_targets(cmd):
        resolved = _resolve_target(raw, cwd)
        if resolved is None:
            continue
        if owned and _is_under(resolved, owned):
            continue
        if any(_is_under(resolved, tr) for tr in temp_roots):
            continue
        return resolved
    return None


def _deny(target, owned_dir):
    """Emit the compact deny schema (separators=(",",":") so
    `"permissionDecision":"deny"` is a literal substring, matching the canary +
    unit test) and return 0. NEVER exits 2 — the deny is the JSON decision."""
    reason = (
        "Delete target {t} is outside your owned scratch dir ({o}) and outside "
        "the OS temp roots. Agents delete nothing outside their owned dir; "
        "surface it — the PM chat/harness handles cleanup."
    ).format(t=target, o=owned_dir)
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    sys.stdout.write(json.dumps(out, separators=(",", ":")))
    return 0


def main():
    # Parse the hook payload. An unparseable payload -> allow (fail-open).
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        # Belt-and-suspenders: the matcher already scopes to Bash.
        if data.get("tool_name") != "Bash":
            return 0

        # Sub-agent gating: agent_id is present ONLY for a spawned sub-agent. The
        # main thread (PM chat) has none -> not a tracked subagent -> ALLOW.
        agent_id = data.get("agent_id")
        if not isinstance(agent_id, str) or not agent_id:
            return 0

        owned_dir = _owned_dir(agent_id)
        if not owned_dir:
            return 0  # registry miss / absent / unreadable -> fail-open ALLOW

        tool_input = data.get("tool_input") or {}
        cmd = tool_input.get("command", "")
        if not cmd:
            return 0

        cwd = data.get("cwd")  # may be absent -> relative targets fail-open
        target = _first_out_of_bounds(cmd, cwd, owned_dir)
        if target is not None:
            return _deny(target, owned_dir)
        return 0
    except Exception:
        # Any internal error -> allow (NEVER exit 2 — fail-open).
        return 0


if __name__ == "__main__":
    sys.exit(main())
