# scripts/lib/per-entry/accounting.sh — independent line-accounting gate
# for a per-entry decompose (BD-291).
#
# Public API:
#   per_entry_accounting_check <stream_key> <mono_path> <stream_dir> \
#       <dropped_path> [<synth_record_path>]
#       Prove that decomposing <mono_path> into <stream_dir> (with the
#       optional dropped-content capture at <dropped_path>) lost
#       nothing: the multiset equation M == T ⊎ R must hold, where
#
#         M = lines of the monolith, EXCLUDING (i) blank/whitespace-only
#             lines and (ii) lines that are exactly `---` (optionally
#             whitespace-padded) — the SANCTIONED-STRUCTURAL class, the
#             only shapes the walker's normalize_entry may trim and the
#             only shapes carrying zero content.
#         T = lines of every <stream_dir> file matching the stream's
#             entry regex (pe_entry_regex_for_stream), excluding each
#             file's line-1 back-pointer (pe_strip_backpointer_stdin
#             semantics — drop line 1 iff it matches the back-pointer
#             comment shape) and excluding blank/`---`-only lines.
#         R = lines of <dropped_path> (empty multiset when the argument
#             is empty or the file is absent), excluding blank/`---`-only
#             lines and provenance delimiters matching exactly
#             `^<!-- v10 monolith lines \d+–\d+ -->$` (the only line
#             shape the capture sink ADDS).
#
#       Returns 0 iff the equation holds. On mismatch: prints every
#       line in M − (T ⊎ R) with its FIRST monolith line number,
#       prefixed `UNACCOUNTED`; every line in (T ⊎ R) − M with its
#       file, prefixed `FABRICATED`; returns non-zero.
#
#   Reduced mode (optional 5th argument): <synth_record_path> is a TSV
#       of rows `<entry-relpath>\t<inserted-line-verbatim>` (the file
#       field may be any path form; its basename resolves within
#       <stream_dir>). Each recorded line is SUBTRACTED from T,
#       matching on the (file, line) pair; a record row whose line is
#       NOT present in the named tree file fails as
#       `RECORDED-BUT-ABSENT: <file>: <line>`; after subtraction the
#       equation runs as normal, so a tree addition OUTSIDE the record
#       surfaces as FABRICATED — both directions verified.
#
# GATE SCOPE: the gate proves NO-LOSS only. It does NOT guarantee
# correct ROUTING between an entry file and the capture — routing
# correctness is the walker tests' job (scripts/tests/test-per-entry.sh).
# No future actor may cite the gate to skip walker-routing tests.
#
# READ SYMMETRY: the accounting reader uses the identical read + split
# semantics as the walker — open(…, encoding="utf-8", newline=""),
# ensure one trailing newline, text.splitlines(keepends=True) — so no
# line-boundary class can produce an asymmetric false verdict.
#
# COST: one pass per file, O(lines), collections.Counter multiset math,
# no subprocess-per-entry, no tree walk beyond <stream_dir>.
#
# Implementation: bash dispatch + python3 for the multiset math
# (sibling precedent: decompose.sh). Bash 3.2 + macOS BSD utility
# compatible.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source sibling _lib.sh if not already loaded.
if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

per_entry_accounting_check() {
    local key="$1"
    local mono_path="$2"
    local stream_dir="$3"
    local dropped_path="${4:-}"
    local synth_record="${5:-}"

    [[ -n "$key" ]] || pe_die "per_entry_accounting_check: stream key required"
    [[ -n "$mono_path" ]] || pe_die "per_entry_accounting_check: monolith path required"
    [[ -n "$stream_dir" ]] || pe_die "per_entry_accounting_check: stream dir required"

    # Validate stream key.
    local entry_regex
    entry_regex=$(pe_entry_regex_for_stream "$key") || \
        pe_die "per_entry_accounting_check: unknown stream key: $key"

    [[ -f "$mono_path" ]] || pe_die "per_entry_accounting_check: monolith input not found: $mono_path"
    [[ -d "$stream_dir" ]] || pe_die "per_entry_accounting_check: stream dir not found: $stream_dir"

    # Dispatch to the python helper for the multiset math. The function's
    # return value is the python exit code: 0 = gate PASS, 1 = gate FAIL
    # (verdict lines on stdout), 2 = usage/internal error.
    PE_ACCT_KEY="$key" \
    PE_ACCT_MONO="$mono_path" \
    PE_ACCT_DIR="$stream_dir" \
    PE_ACCT_REGEX="$entry_regex" \
    PE_ACCT_DROPPED="$dropped_path" \
    PE_ACCT_SYNTH="$synth_record" \
        python3 - <<'PYEOF'
import os
import re
import sys
from collections import Counter

key = os.environ.get("PE_ACCT_KEY", "")
mono_path = os.environ.get("PE_ACCT_MONO", "")
stream_dir = os.environ.get("PE_ACCT_DIR", "")
entry_regex = os.environ.get("PE_ACCT_REGEX", "")
dropped_path = os.environ.get("PE_ACCT_DROPPED", "")
synth_path = os.environ.get("PE_ACCT_SYNTH", "")

if not (key and mono_path and stream_dir and entry_regex):
    sys.stderr.write("per-entry accounting: missing required env var\n")
    sys.exit(2)

def read_lines(path):
    """The accounting reader uses the identical read + split semantics
    as the walker: open(…, encoding="utf-8", newline=""), ensure one
    trailing newline, splitlines(keepends=True)."""
    with open(path, "r", encoding="utf-8", newline="") as f:
        text = f.read()
    if not text.endswith("\n"):
        text += "\n"
    return text.splitlines(keepends=True)

def is_structural(line):
    """The SANCTIONED-STRUCTURAL class: blank/whitespace-only lines and
    `---`-only lines (optionally whitespace-padded)."""
    s = line.strip()
    return s == "" or s == "---"

# Line-1 back-pointer shape (pe_strip_backpointer_stdin semantics).
BP_RE = re.compile(r"^<!-- per-entry source: .*; contract: .* -->[ \t]*$")
# Capture provenance delimiter — the only line shape the sink ADDS.
DELIM_RE = re.compile(r"^<!-- v10 monolith lines \d+–\d+ -->$")

# ─── M: monolith multiset (+ first-occurrence line numbers) ──
M = Counter()
first_line = {}
for lineno, line in enumerate(read_lines(mono_path), start=1):
    if is_structural(line):
        continue
    M[line] += 1
    first_line.setdefault(line, lineno)

# ─── T: tree multiset (per entry file) ───────────────────────
entry_re = re.compile(entry_regex)
T = Counter()
t_per_file = {}  # basename -> Counter of its counted lines
try:
    names = sorted(os.listdir(stream_dir))
except OSError as e:
    sys.stderr.write(f"per-entry accounting: cannot list {stream_dir}: {e}\n")
    sys.exit(2)
for name in names:
    if not entry_re.match(name):
        continue
    path = os.path.join(stream_dir, name)
    if not os.path.isfile(path):
        continue
    per_file = Counter()
    for i, line in enumerate(read_lines(path), start=1):
        if i == 1 and BP_RE.match(line.rstrip("\n")):
            continue
        if is_structural(line):
            continue
        per_file[line] += 1
    t_per_file[name] = per_file
    T.update(per_file)

# ─── R: capture multiset ─────────────────────────────────────
R = Counter()
if dropped_path and os.path.isfile(dropped_path):
    for line in read_lines(dropped_path):
        if is_structural(line):
            continue
        if DELIM_RE.match(line.rstrip("\n")):
            continue
        R[line] += 1

failures = []

# ─── Reduced mode: subtract the recorded insertions from T ───
if synth_path:
    if not os.path.isfile(synth_path):
        sys.stderr.write(
            f"per-entry accounting: synth record not found: {synth_path}\n")
        sys.exit(2)
    with open(synth_path, "r", encoding="utf-8", newline="") as f:
        rows = f.read().splitlines()
    for row in rows:
        if not row.strip():
            continue
        if "\t" not in row:
            sys.stderr.write(
                f"per-entry accounting: malformed synth-record row (no TAB): {row}\n")
            sys.exit(2)
        rel, inserted = row.split("\t", 1)
        base = os.path.basename(rel)
        cand = inserted + "\n"
        per_file = t_per_file.get(base)
        if per_file is None or per_file[cand] <= 0:
            failures.append(f"RECORDED-BUT-ABSENT: {base}: {inserted}")
            continue
        per_file[cand] -= 1
        T[cand] -= 1

# ─── The gate: M == T ⊎ R ────────────────────────────────────
TR = T + R
missing = M - TR   # UNACCOUNTED (per-line deficit)
extra = TR - M     # FABRICATED (per-line surplus)

for line in sorted(missing, key=lambda l: first_line.get(l, 0)):
    n = missing[line]
    where = first_line.get(line, "?")
    count = f" (x{n})" if n > 1 else ""
    failures.append(
        f"UNACCOUNTED: monolith line {where}{count}: {line.rstrip(chr(10))}")

for line in sorted(extra):
    n = extra[line]
    sources = [nm for nm in sorted(t_per_file) if t_per_file[nm][line] > 0]
    if R[line] > 0:
        sources.append(os.path.basename(dropped_path) if dropped_path else "capture")
    src = ",".join(sources) if sources else "?"
    count = f" (x{n})" if n > 1 else ""
    failures.append(f"FABRICATED: {src}{count}: {line.rstrip(chr(10))}")

m_total = sum(M.values())
t_total = sum(T.values())
r_total = sum(R.values())

if failures:
    for item in failures:
        print(item)
    rba = sum(1 for item in failures if item.startswith("RECORDED-BUT-ABSENT"))
    print(
        f"per-entry accounting: FAIL ({key}): M={m_total} T={t_total} "
        f"R={r_total}; unaccounted={sum(missing.values())} "
        f"fabricated={sum(extra.values())} recorded-but-absent={rba}")
    sys.exit(1)

print(
    f"per-entry accounting: PASS ({key}): {m_total} monolith line(s) == "
    f"{t_total} tree + {r_total} capture line(s)")
sys.exit(0)
PYEOF
}
