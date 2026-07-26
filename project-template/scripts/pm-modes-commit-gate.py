#!/usr/bin/env python3
#
# scripts/pm-modes-commit-gate.py — client intervention_mode commit-approval gate.
#
# A Claude Code PreToolUse hook (matcher `Bash`) that fires on a `git commit`
# tool call, re-reads the active intervention_mode from
# docs/project/pm-session-config.json, and DENIES the commit unless a FRESH,
# single-use approval token exists (docs/project/.pm-commit-approval-token). It
# enforces the commit-approval RITUAL (a fresh token must exist per commit) —
# NOT the SEMANTICS (the hook cannot verify the user truly approved; the token
# is a self-attested proxy the PM chat writes at the approval gate). It is
# genuine DRIFT protection: a commit that skipped the "present approval -> user
# says yes -> write token" ritual also lacks the token, so the omission fails
# loudly.
#
# FAIL-OPEN, HARDER THAN THE ISOLATION HOOK: any uncertainty — config
# absent/unreadable/malformed/unknown value, git unavailable, an ambiguous
# command parse, a token-parse error, ANY exception — -> ALLOW (print nothing,
# exit 0). The body NEVER exits 2 (exit 2 = blocking). A wrongful DENY would
# wedge the developer's own commits, so every uncertain branch errs to ALLOW.
# The deny fires ONLY on a fully-resolved {Bash + git commit + cleanly-parsed
# enforce-mode + no fresh token}.
#
# Enforce set: intervention_mode in {full, pre-coder, ambiguity} keeps the
# commit-approval gate (per docs/pack/PM-OPERATING-MODES.md). intervention_mode=
# none authorizes auto-commit -> ALLOW. Any other/absent/malformed value ->
# ALLOW (INERT) — a fresh clone that has not opted into modes must not have its
# commits gated by a token it does not know to write.
#
# Token lifecycle: content is {"approved_at": <epoch_seconds>}; the hook denies
# if now - approved_at > TTL (freshness) and DELETES the token on the allow path
# (single-use — one approval authorizes one commit). Deleting a per-clone
# runtime file is the hook's own bookkeeping, NOT a git verb. Because consume
# happens in PreToolUse (before the commit runs), a commit that then FAILS has
# already spent the token -> re-approve; this errs toward requiring approval (the
# fail-safe direction).
#
# Dependency direction: a client-side hook — it is read only by the client
# .claude/settings.json (which wires it via `python3 ./scripts/pm-modes-commit-
# gate.py`) and depends on no other file. It is a self-contained client copy; it
# shares no code with any pack-repo hook.
#
# Test seams:
#   MODES_GATE_CONFIG_FILE — override the session-config path (else derived from
#                            `git -C <cwd> rev-parse --show-toplevel`).
#   MODES_GATE_TOKEN_FILE  — override the token path (else derived the same way).
#   MODES_GATE_NOW         — override "now" (epoch seconds) for deterministic TTL
#                            tests. Malformed -> ignored (real clock used).
# Production leaves all three unset.

import json
import os
import shlex
import subprocess
import sys
import time

# Freshness bound: a token older than TTL seconds is stale -> deny. A single
# constant — trivially tunable.
_TTL_SECONDS = 120

# The intervention_mode values that KEEP the commit-approval gate (all three
# non-`none` values, per PM-OPERATING-MODES.md). Any other value -> allow (inert).
_ENFORCE_MODES = frozenset({"full", "pre-coder", "ambiguity"})

# Global git options that CONSUME the following token as a value, so the
# subcommand scan skips option+value pairs (git -C <path>, git -c k=v, ...).
_GIT_VALUE_OPTS = frozenset({
    "-C", "-c", "--git-dir", "--work-tree", "--namespace",
    "--exec-path", "--super-prefix",
})


def _toplevel(cwd):
    """The worktree root for `cwd`, or "" on any failure (non-git / git absent)."""
    try:
        proc = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
        )
    except Exception:
        return ""
    return proc.stdout.strip()


def _config_path(cwd):
    """Resolve the session-config path (test seam MODES_GATE_CONFIG_FILE first,
    else <toplevel>/docs/project/pm-session-config.json). "" if unresolvable."""
    seam = os.environ.get("MODES_GATE_CONFIG_FILE")
    if seam:
        return seam
    root = _toplevel(cwd)
    if not root:
        return ""
    return os.path.join(root, "docs", "project", "pm-session-config.json")


def _token_path(cwd):
    """Resolve the approval-token path (test seam MODES_GATE_TOKEN_FILE first,
    else <toplevel>/docs/project/.pm-commit-approval-token). "" if unresolvable."""
    seam = os.environ.get("MODES_GATE_TOKEN_FILE")
    if seam:
        return seam
    root = _toplevel(cwd)
    if not root:
        return ""
    return os.path.join(root, "docs", "project", ".pm-commit-approval-token")


def _resolve_intervention(cwd):
    """Return the active intervention_mode string, or None on ANY failure
    (config path unresolvable / file absent / unreadable / not-JSON / non-string
    value). None -> allow (inert); this is deliberately MORE lenient than the
    isolation hook's fold-to-default, because a commit-gate denial wedges the
    developer's own commits."""
    cfg = _config_path(cwd)
    if not cfg:
        return None
    try:
        with open(cfg) as fh:
            mode = json.load(fh).get("intervention_mode")
    except Exception:
        return None
    return mode if isinstance(mode, str) else None


def _now():
    """Current epoch seconds, honoring the MODES_GATE_NOW test seam (malformed ->
    the real clock)."""
    seam = os.environ.get("MODES_GATE_NOW")
    if seam:
        try:
            return float(seam)
        except (TypeError, ValueError):
            pass
    return time.time()


def _is_git_commit(cmd):
    """True iff `cmd` invokes `git commit`. CONSERVATIVE + fail-open-toward-allow:
    return True ONLY when confident. Splits the command on shell separators,
    finds a `git` token, skips global options (option+value pairs consumed), and
    checks the first non-option token is `commit`. An unparseable segment falls
    back to a naive whitespace split (balanced-quote commits never reach it).
    Any surprise -> the caller's try/except -> allow."""
    if not cmd:
        return False
    segments = _split_segments(cmd)
    for seg in segments:
        try:
            toks = shlex.split(seg)
        except ValueError:
            toks = seg.split()
        if _segment_is_git_commit(toks):
            return True
    return False


def _split_segments(cmd):
    """Split a shell command on the top-level operators that start a new simple
    command (&&, ||, ;, |, newline) — QUOTE-AWARE. An operator that sits INSIDE a
    single- or double-quoted string is NOT a boundary, so a literal `&&`/`;`/`|`
    inside a quoted argument (e.g. `git log --grep="&& git commit &&"`) can NEVER
    expose a spurious bare `git commit` segment and wrongly deny a non-commit.
    Quote state toggles on an unescaped quote char; a backslash escapes the next
    char outside quotes and inside double quotes (literal inside single quotes).

    Fail-open direction: this can only ever REDUCE spurious segments. UNDER-
    splitting is safe — a real `git commit` after a merged operator is still
    detected because _segment_is_git_commit scans the whole token list for a
    `git ... commit` pair — so the conservative bias is toward allow, never a
    wrong deny."""
    out = []
    buf = []
    quote = None  # None | "'" | '"' — the active quote context
    i = 0
    n = len(cmd)
    while i < n:
        ch = cmd[i]
        # Backslash escape: literal inside single quotes; otherwise consumes the
        # next char (outside quotes, or inside double quotes) so an escaped quote
        # / operator does not flip state or split.
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


def _segment_is_git_commit(toks):
    """True iff a token list is a `git ... commit ...` invocation."""
    n = len(toks)
    idx = 0
    while idx < n:
        t = toks[idx]
        if t == "git" or t.endswith("/git"):
            j = idx + 1
            while j < n:
                a = toks[j]
                if a in _GIT_VALUE_OPTS:
                    j += 2  # option consumes the next token as its value
                    continue
                if a.startswith("-"):
                    j += 1  # a flag / --opt=value single token
                    continue
                return a == "commit"  # first non-option token = the subcommand
            return False  # `git` with no subcommand in this segment
        idx += 1
    return False


def _evaluate_token(cwd, now):
    """Classify the approval token into a (decision, token_path) pair. The three
    decisions encode the fail-open-HARDER discipline:

      "allow-consume" — a FRESH token (within TTL) -> allow + delete (single-use).
                        A future-dated token counts as fresh (harmless — it is
                        self-written; avoids a wrongful deny on clock jitter).
      "deny"          — a CLEAN no/expired-approval signal the hook read
                        confidently: the token is ABSENT, or present-and-valid
                        but STALE. These are the enforcement path.
      "allow"         — the hook CANNOT read the signal through no fault of the
                        committer: path unresolvable, file unreadable, or a
                        token-PARSE error / non-numeric approved_at. Fail-open
                        (never wedge a commit on the hook's own read failure)."""
    tok_path = _token_path(cwd)
    if not tok_path:
        return "allow", ""            # path unresolvable -> fail-open
    if not os.path.exists(tok_path):
        return "deny", tok_path       # ABSENT -> clean no-approval -> enforce
    try:
        with open(tok_path) as fh:
            approved_at = json.load(fh).get("approved_at")
    except Exception:
        return "allow", tok_path      # token-PARSE error -> fail-open
    if not isinstance(approved_at, (int, float)):
        return "allow", tok_path      # malformed content -> fail-open
    if (now - approved_at) <= _TTL_SECONDS:
        return "allow-consume", tok_path  # FRESH
    return "deny", tok_path           # STALE -> enforce


def _deny(mode):
    """Emit the deny schema (compact separators, so the substring
    `"permissionDecision":"deny"` is literally present) and return 0. NEVER
    exits 2 — the deny is expressed via the JSON permissionDecision, not the
    exit code."""
    reason = (
        "intervention_mode={mode} requires a fresh approved-commit token "
        "(docs/project/.pm-commit-approval-token); none present/fresh. Obtain "
        "user approval (which writes the token) before committing."
    ).format(mode=mode)
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

        tool_input = data.get("tool_input") or {}
        cmd = tool_input.get("command", "")
        if not _is_git_commit(cmd):
            return 0  # not a commit (or an ambiguous parse) -> allow

        cwd = data.get("cwd") or os.getcwd()
        mode = _resolve_intervention(cwd)
        if mode not in _ENFORCE_MODES:
            # none / unknown / absent / malformed -> allow (inert).
            return 0

        now = _now()
        decision, tok_path = _evaluate_token(cwd, now)
        if decision == "allow-consume":
            # Single-use: consume (delete) on the fresh-token allow path.
            try:
                os.remove(tok_path)
            except OSError:
                pass
            return 0  # allow (print nothing)
        if decision == "allow":
            return 0  # fail-open (hook could not read the signal) -> allow

        return _deny(mode)  # enforce-mode + absent/stale token -> DENY
    except Exception:
        # Any internal error -> allow (NEVER exit 2 — fail-open, harder here).
        return 0


if __name__ == "__main__":
    sys.exit(main())
