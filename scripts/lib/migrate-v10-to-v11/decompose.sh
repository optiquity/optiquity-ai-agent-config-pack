# scripts/lib/migrate-v10-to-v11/decompose.sh — adapter-private 6th sub-op
# of the v10→v11 migrator's `migrator_post_dispatch_hook`. Decomposes the
# just-installed v11-shape monolithic BACKLOG.md / CHANGELOG.md /
# IMPLEMENTATION-PLAN.md files into per-entry trees + regenerated TOCs
# under `docs/project/<stream>/`, then DELETES each v10 source monolith
# after its decomposition is verified written. The per-entry tree +
# generated `_toc.md` is the sole source of truth + readable form; NO
# monolithic mirror is regenerated (BD-206 no-mirror model).
#
# Sourced by `scripts/migrate-v10-to-v11.sh` only. Not part of the
# BD-119 framework — adapter-scope, like `apply.sh` / `dry-run.sh` /
# `resume.sh` siblings under this directory.
#
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §1.3 (constraint statement: function name + placement)
#     §10.2 (post-dispatch hook is the right hook for this sub-op)
#
# Design constraints binding on this file (their source architecture + plan
# docs were deleted at BD-210; the constraints themselves still hold):
#   - Sequencing: this 6th sub-op MUST run AFTER all 5 existing sub-ops, so
#     the decompose step reads the FINAL v11-shape monolithic content.
#   - `_intro.md` and `_v8-resolved-archive.md` are installed initially.
#   - Helper location: this directory (the adapter-scope helpers), with the
#     shared per-entry helpers at scripts/lib/per-entry/.
#
# Public API (sourced into the adapter's shell):
#   _v10_to_v11_decompose_streams
#       Adapter-private 6th sub-op. Iterates the three project-side
#       streams (backlog, implementation-plan, changelog) with the
#       per-stream pipeline, in this fixed order:
#         1. decompose         (dropped-content capture sink at
#                               $_MIGRATOR_STATE_DIR/dropped-<stream>.md;
#                               the sink truncates the capture at start)
#         2. accounting gate   (per_entry_accounting_check; the line-
#                               multiset equation M == T ⊎ R must PASS
#                               BEFORE the monolith may be deleted; on
#                               FAIL → fail_stage S5 with the monolith,
#                               partial tree, and capture retained)
#         3. field synthesis   (backlog + implementation-plan only;
#                               insert-only; every inserted line recorded
#                               to $_MIGRATOR_STATE_DIR/synthesized-
#                               <stream>.tsv)
#         4. toc regenerate
#         5. index regenerate  (implementation-plan only)
#         6. delete-gate       (ALL of: accounting PASSED; `_toc.md`
#                               present; for implementation-plan
#                               `_index.md` present) → rm -f monolith
#       After the loop it assembles `docs/project/MIGRATION-TRIAGE.md`
#       from the per-stream captures + the derived membership maps + the
#       synthesis record + the manual-fill list (written iff captures ∪
#       synthesis ∪ manual-fill is nonempty), and writes the per-stream
#       accounting verdicts to
#       $_MIGRATOR_STATE_DIR/accounting-verdicts.txt. NO monolithic
#       mirror is regenerated (BD-206 no-mirror model). Idempotent: on a
#       re-run the source monolith is already gone, so the stream is
#       skipped (a no-op).
#
#   GATE SCOPE: the accounting gate proves NO-LOSS only. It does NOT
#   guarantee correct ROUTING between an entry file and the capture —
#   routing correctness is the walker tests' job
#   (scripts/tests/test-per-entry.sh). No future actor may cite the
#   gate to skip walker-routing tests.
#
# Implementation contract:
#   - Sources `scripts/lib/per-entry/_lib.sh` + `decompose.sh` +
#     `toc-regenerate.sh` + `index-generate.sh` + `accounting.sh` (the
#     shared per-entry helpers). Does NOT reimplement decompose / TOC /
#     index / accounting logic — that lives in the shared helpers and
#     serves the per-entry tree generation paths.
#   - Skips streams whose monolithic input is absent (a v10 client
#     may have only a `BACKLOG.md` and never a `CHANGELOG.md`; a
#     greenfield v10 may have neither — both are valid pre-states).
#   - Reads each v10 monolith as DECOMPOSE INPUT, then DELETES it after
#     the accounting gate passed and the per-entry tree + `_toc.md`
#     (+ `_index.md` for implementation-plan) are verified written
#     (fail-safe). It is never regenerated as a mirror (BD-206
#     no-mirror model).
#   - Emits `say` / `info` lines matching the prevailing adapter style
#     (see `_v10_to_v11_install_v11_artifacts` for the pattern).
#   - On any helper failure, calls `fail_stage S5` (the post-dispatch
#     hook fires inside the framework's S3 → S4 transition, but the
#     adapter's wording uses S4 / S5 sub-banners per the existing
#     `_v10_to_v11_*` precedent — this helper aligns with the S5
#     family because the BD-167 canonical templates install in S5).
#     Sub-stage tags on the failure messages: `S5d-decompose:`,
#     `S5d-accounting:`, `S5d-synthesize:`, `S5d-index:`, `S5d-triage:`.
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO
# `&>`, NO GNU-only flags.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Source the BD-164 per-entry helpers ────────────────────────────────────
#
# The helpers live one level up at `scripts/lib/per-entry/`. This file is
# at `scripts/lib/migrate-v10-to-v11/decompose.sh` so the helpers' dir is
# `../per-entry/` relative to BASH_SOURCE.
#
# Guard each source with a `type` check so re-sourcing this file is a
# no-op (matches the per-entry helpers' own convention at
# scripts/lib/per-entry/decompose.sh:30-33).

_v10_v11_decompose_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../per-entry" && pwd)"

if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/_lib.sh"
fi
if ! type per_entry_decompose >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/decompose.sh"
fi
if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/toc-regenerate.sh"
fi
if ! type per_entry_regenerate_index >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/index-generate.sh"
fi
if ! type per_entry_accounting_check >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/accounting.sh"
fi

# ── Adapter-private 6th sub-op ─────────────────────────────────────────────

_v10_to_v11_decompose_streams() {
    # Sub-banner per the BD-139 F-3 pattern (see
    # _v10_to_v11_relocate_legacy_docs at line 230 of
    # scripts/migrate-v10-to-v11.sh). The fail_stage call still uses
    # "S5" so the BD-095 sentinel filename + framework exit-code
    # formula stay stable; the failure-message prefix carries the
    # sub-stage tag ("S5d-decompose: ...") so operators can tell this
    # sub-op apart from S5 (artifact install), S5b (python-architecture
    # rename), and S5c (capability-token translation).
    say "── S5d (decompose) — per-entry decomposition + TOC regenerate ──"

    # Three project-side streams. Each tuple: stream_key + relative
    # monolith input filename + relative stream directory. Pack-side streams
    # (pack-backlog / pack-changelog) are NOT decomposed by this
    # migrator — pack-self decomposition lands in Batch 23 (BD-102)
    # dog-food. The v10→v11 client migrator only touches
    # docs/project/<stream>/.
    #
    # The _rules.md / _intro.md supporting files were installed in the
    # prior sub-op (_v10_to_v11_install_v11_artifacts) at the BD-167
    # templates step — verified by `ls scripts/migrate-v10-to-v11.sh:355-374`.
    # The decompose step relies on them being present.
    local stream_key mirror_rel stream_dir_rel mirror_path stream_dir
    local decomposed_count=0 skipped_count=0
    local capture_path synth_path acct_out acct_rc verdicts

    # Per-stream accounting verdicts, truncated at sub-op start (state
    # output; the sandbox-apply harness quotes these rows).
    verdicts="$_MIGRATOR_STATE_DIR/accounting-verdicts.txt"
    : > "$verdicts"

    for spec in \
        "project-backlog|docs/project/BACKLOG.md|docs/project/backlog" \
        "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan" \
        "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog"; do
        stream_key="${spec%%|*}"
        local rest="${spec#*|}"
        mirror_rel="${rest%%|*}"
        stream_dir_rel="${rest##*|}"
        mirror_path="$_MIGRATOR_TARGET/$mirror_rel"
        stream_dir="$_MIGRATOR_TARGET/$stream_dir_rel"

        # Skip if the monolithic input is absent (greenfield-v10
        # client may have only a partial set; that's a valid pre-
        # state). Don't skip merely because the stream dir is
        # absent — the BD-167 install (S5) creates it; if absent
        # here something went wrong upstream.
        if [[ ! -f "$mirror_path" ]]; then
            info "$stream_key: no monolithic mirror at $mirror_rel — skip"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        if [[ ! -d "$stream_dir" ]]; then
            info "$stream_key: stream dir $stream_dir_rel not present (templates not installed?) — skip"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        # Snapshot the monolith into the state dir BEFORE any pipeline
        # step: the MIGRATION-TRIAGE membership maps derive from it
        # after the monolith is deleted, and a failed gate leaves it
        # beside the capture for diagnosis.
        cp "$mirror_path" "$_MIGRATOR_STATE_DIR/monolith-$stream_key.md"

        # ── 1. Decompose (with the dropped-content capture sink) ──
        # The decompose helper writes per-entry files under
        # $stream_dir/<id>.md with line-1 HTML-comment back-pointers
        # (Addendum #2 §2). Idempotent: same input → byte-identical
        # output. PE_DECOMPOSE_DROPPED routes every ignored line
        # (preamble; section-break blocks; H1-break blocks) VERBATIM
        # into the per-stream capture file; the sink truncates the
        # capture at decompose start.
        capture_path="$_MIGRATOR_STATE_DIR/dropped-$stream_key.md"
        export PE_DECOMPOSE_DROPPED="$capture_path"
        if ! per_entry_decompose "$stream_key" "$mirror_path" "$stream_dir"; then
            unset PE_DECOMPOSE_DROPPED
            fail_stage S5 "S5d-decompose: per_entry_decompose failed for $stream_key (input=$mirror_rel, dir=$stream_dir_rel)"
        fi
        unset PE_DECOMPOSE_DROPPED

        # ── 2. Accounting gate (BEFORE synthesis, BEFORE deletion) ──
        # The line-multiset equation M == T ⊎ R (monolith == tree ⊎
        # capture, excluding only blank/`---` structural lines, line-1
        # back-pointers, and capture provenance delimiters) must hold.
        # At this point the tree is byte-faithful (synthesis has not
        # run), so the equation needs no exclusions beyond the fixed
        # classes. On FAIL: the monolith, the partial tree, and the
        # capture are all retained for diagnosis, and the stage fails.
        acct_rc=0
        acct_out=$(per_entry_accounting_check "$stream_key" "$mirror_path" "$stream_dir" "$capture_path") || acct_rc=$?
        if [[ "$acct_rc" -ne 0 ]]; then
            printf '%s\n' "$acct_out" >&2
            fail_stage S5 "S5d-accounting: line-accounting gate FAILED for $stream_key — monolith, partial tree, and capture retained for diagnosis (UNACCOUNTED/FABRICATED lines above)"
        fi
        printf '%s\tPASS\t%s\n' "$stream_key" "$acct_out" >> "$verdicts"
        info "$stream_key: accounting gate PASS ($acct_out)"

        # ── 3. Field synthesis (backlog + implementation-plan only) ──
        # Insert-only; every inserted line is recorded to the state-dir
        # TSV (the MIGRATION-TRIAGE § Synthesized fields record). The
        # changelog stream gets no synthesis.
        synth_path="$_MIGRATOR_STATE_DIR/synthesized-$stream_key.tsv"
        case "$stream_key" in
            project-backlog|project-implementation-plan)
                if ! _v10_to_v11_synthesize_form_family "$stream_key" "$stream_dir" "$synth_path"; then
                    fail_stage S5 "S5d-synthesize: field synthesis failed for $stream_key (dir=$stream_dir_rel)"
                fi
                ;;
        esac

        # ── 4. Regenerate the TOC ──
        # Always-emitted, deterministic, idempotent (matches the
        # BD-164 contract per scripts/lib/per-entry/toc-regenerate.sh).
        # No monolithic mirror is regenerated — the per-entry tree +
        # generated `_toc.md` is the sole source of truth + readable
        # form (BD-206 no-mirror model). The v10 monolith was read as
        # decompose INPUT above; it is not re-emitted. Subshell: the
        # helper manages a private EXIT trap for its temp file; the
        # subshell keeps the migrator's own EXIT trap armed.
        if ! ( per_entry_regenerate_toc "$stream_key" "$stream_dir" ); then
            fail_stage S5 "S5d-decompose: per_entry_regenerate_toc failed for $stream_key (dir=$stream_dir_rel)"
        fi

        # ── 5. Regenerate the ordering index (implementation-plan only) ──
        # `_index.md` is the dependency-derived serial order; the deps
        # stay SSOT in the entry files. Subshell for the same EXIT-trap
        # containment as the TOC step.
        if [[ "$stream_key" == "project-implementation-plan" ]]; then
            if ! ( per_entry_regenerate_index "$stream_key" "$stream_dir" ); then
                fail_stage S5 "S5d-index: per_entry_regenerate_index failed for $stream_key (dir=$stream_dir_rel)"
            fi
        fi

        # ── 6. Delete-gate + delete the v10 source monolith (fail-safe) ──
        # Under the BD-206 no-mirror model the per-entry tree + generated
        # `_toc.md` is the sole source of truth + readable form; the v10
        # monolith was consumed as decompose INPUT and is now retired.
        # Delete it so no stale orphan monolith survives that the docs +
        # runtime advisory say no longer exists (MIGRATION-v10-to-v11.md
        # "Monolithic files are deleted"; the `fail-loud-delete-old-source`
        # rule — delete the old source so dangling refs break loudly).
        #
        # FAIL-SAFE: delete ONLY after ALL of (a) the accounting gate
        # PASSED in step 2, (b) the regenerated `_toc.md` is present,
        # and (c) for implementation-plan the generated `_index.md` is
        # present. The real per-entry helpers abort DIRECTLY via
        # `pe_die` on any internal error, so a failing helper never
        # returns to this loop at all; the `if ! …; then fail_stage S5`
        # wrappers above are a defensive backstop for a non-`pe_die`
        # failure path (a helper that RETURNS non-zero instead of
        # exiting — e.g. the stubbed/alternate helpers the fail-safe
        # test drives). If any gate leg fails the tree is unverified/
        # partial — refuse to delete so client data is never destroyed
        # with no per-entry backing (a failed/partial decompose leaves
        # the source monolith intact).
        if [[ "$acct_rc" -ne 0 ]]; then
            fail_stage S5 "S5d-decompose: refusing to delete $mirror_rel — accounting gate did not PASS (source monolith preserved)"
        fi
        if [[ ! -f "$stream_dir/_toc.md" ]]; then
            fail_stage S5 "S5d-decompose: refusing to delete $mirror_rel — regenerated _toc.md absent at $stream_dir_rel/ (unverified decompose; source monolith preserved)"
        fi
        if [[ "$stream_key" == "project-implementation-plan" && ! -f "$stream_dir/_index.md" ]]; then
            fail_stage S5 "S5d-decompose: refusing to delete $mirror_rel — generated _index.md absent at $stream_dir_rel/ (unverified decompose; source monolith preserved)"
        fi
        rm -f "$mirror_path"

        info "$stream_key: decomposed $mirror_rel → $stream_dir_rel/ + accounting PASS + regenerated TOC; deleted source monolith $mirror_rel"
        decomposed_count=$((decomposed_count + 1))
    done

    # ── 7. Assemble docs/project/MIGRATION-TRIAGE.md (after the loop) ──
    # Written iff (captures ∪ synthesis ∪ manual-fill) is nonempty.
    if ! _v10_to_v11_assemble_triage; then
        fail_stage S5 "S5d-triage: MIGRATION-TRIAGE.md assembly failed"
    fi

    info "per-entry decomposition: $decomposed_count stream(s) decomposed, $skipped_count skipped"
}

# ── Adapter-private field synthesis ────────────────────────────────────────
#
# _v10_to_v11_synthesize_form_family <stream_key> <stream_dir> <record_path>
#     Insert the mechanically-derivable form-family field lines into each
#     just-decomposed entry file. INSERT-ONLY by construction: no original
#     line is modified or removed; every inserted line is recorded to
#     <record_path> as a TSV row `<entry-relpath>\t<inserted-line-verbatim>`
#     (the record MIGRATION-TRIAGE § Synthesized fields carries and the
#     sandbox-apply harness verifies; the relpath's basename resolves
#     within the stream dir — the accounting reader's reduced-mode
#     resolution). The record file is truncated at start.
#
#     Recipes:
#       project-backlog (per entry, after the bold-header line):
#         `- **Entry-Type**: td`; `- **ID**: TD-NNN` (from the filename);
#         iff a `Type: <KIND>(<value>)` line parses (KIND ∈ TODO /
#         KNOWN GAP / VERIFY): `- **Marker**: <KIND>` plus the
#         marker-keyed payload line (Scope / Severity / Verify-Source)
#         with the parenthetical value VERBATIM — an out-of-enum value is
#         synthesized verbatim (the shipped validator's payload legs then
#         name it; fabricating an in-enum guess is prohibited). The
#         original `Type:` line is untouched (the form-family schema
#         admits extras). No parseable `Type:` → no Marker synthesis.
#       project-implementation-plan (per entry, after the H2):
#         `- **Entry-Type**: phase-epic`; `- **ID**: phase-N`;
#         `- **Blockers**:` / `- **Unblocks**:` derived from the entry's
#         own declared dependency fields via the SAME grammar
#         scripts/lib/per-entry/index-generate.sh reads (`field_value`
#         over Blockers/Dependencies/Prerequisite/Unblocks +
#         `parse_phase_refs` extraction — the semantic twin; the
#         identical parse that orders `_index.md`); `none` when empty.
#         `Status:` is NEVER synthesized and `Goal:` is NEVER
#         synthesized (no mechanical source; the MIGRATION-TRIAGE
#         manual-fill list names each absent field).
#
#     Design anchor: ARCHITECTURE-BD-291.md §3.3
#     (maintenance-docs/v11-implementation/).
_v10_to_v11_synthesize_form_family() {
    local key="$1"
    local stream_dir="$2"
    local record_path="$3"
    V10_SYNTH_KEY="$key" \
    V10_SYNTH_DIR="$stream_dir" \
    V10_SYNTH_RECORD="$record_path" \
        python3 - <<'PYEOF'
import os
import re
import sys

key = os.environ["V10_SYNTH_KEY"]
stream_dir = os.environ["V10_SYNTH_DIR"]
record_path = os.environ["V10_SYNTH_RECORD"]

TYPE_RE = re.compile(r"^Type:\s*(TODO|KNOWN GAP|VERIFY)\(([^)]+)\)", re.MULTILINE)
PAYLOAD_BY_MARKER = {"TODO": "Scope", "KNOWN GAP": "Severity",
                     "VERIFY": "Verify-Source"}


def field_value(body, field):
    """Semantic twin of field_value() in
    scripts/lib/per-entry/index-generate.sh — the identical parse that
    orders `_index.md` (same regex, same trimming)."""
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + re.escape(field) + r"\*{0,2}\s*:(.*)$",
        re.MULTILINE)
    m = rx.search(body)
    return m.group(1).strip().strip("*").strip() if m else ""


def parse_phase_refs(value):
    """Semantic twin of parse_phase_refs() in
    scripts/lib/per-entry/index-generate.sh."""
    return set(re.findall(r"phase-(\d+)", value))


if key == "project-backlog":
    entry_file_re = re.compile(r"^TD-\d+\.md$")
    anchor_re = re.compile(r"^\*\*TD-\d+\s+— ")
elif key == "project-implementation-plan":
    entry_file_re = re.compile(r"^phase-\d+\.md$")
    anchor_re = re.compile(r"^## Phase \d+ — ")
else:
    sys.stderr.write(
        f"form-family synthesis: unsupported stream key: {key}\n")
    sys.exit(3)

subdir = os.path.basename(stream_dir.rstrip("/"))
record_rows = []

try:
    names = sorted(n for n in os.listdir(stream_dir)
                   if entry_file_re.match(n))
except OSError as e:
    sys.stderr.write(f"form-family synthesis: cannot list {stream_dir}: {e}\n")
    sys.exit(3)

for name in names:
    path = os.path.join(stream_dir, name)
    with open(path, "r", encoding="utf-8", newline="") as f:
        text = f.read()
    lines = text.splitlines(keepends=True)

    anchor_idx = None
    for i, line in enumerate(lines):
        if anchor_re.match(line):
            anchor_idx = i
            break
    if anchor_idx is None:
        sys.stderr.write(
            f"form-family synthesis: no entry anchor in {subdir}/{name}\n")
        sys.exit(3)

    entry_id = name[:-3]  # filename stem IS the entry id
    body = "".join(lines)
    fields = []
    if key == "project-backlog":
        fields.append("- **Entry-Type**: td")
        fields.append(f"- **ID**: {entry_id}")
        m = TYPE_RE.search(body)
        if m:
            kind, val = m.group(1), m.group(2)
            fields.append(f"- **Marker**: {kind}")
            fields.append(f"- **{PAYLOAD_BY_MARKER[kind]}**: {val}")
        # No parseable Type: → no Marker synthesis (the entry surfaces
        # via the shipped validator's core-field leg; never guessed).
    else:
        fields.append("- **Entry-Type**: phase-epic")
        fields.append(f"- **ID**: {entry_id}")
        prereq = set()
        for fld in ("Blockers", "Dependencies", "Prerequisite"):
            prereq |= parse_phase_refs(field_value(body, fld))
        dep = parse_phase_refs(field_value(body, "Unblocks"))
        blockers_val = ", ".join(
            "phase-%s" % n for n in sorted(prereq, key=int)) or "none"
        unblocks_val = ", ".join(
            "phase-%s" % n for n in sorted(dep, key=int)) or "none"
        fields.append(f"- **Blockers**: {blockers_val}")
        fields.append(f"- **Unblocks**: {unblocks_val}")

    for fl in fields:
        if "\t" in fl:
            sys.stderr.write(
                f"form-family synthesis: TAB in synthesized line for "
                f"{subdir}/{name}: {fl}\n")
            sys.exit(3)
        record_rows.append(f"{subdir}/{name}\t{fl}")

    new_lines = (lines[:anchor_idx + 1]
                 + [fl + "\n" for fl in fields]
                 + lines[anchor_idx + 1:])
    tmp_path = path + ".synth-tmp"
    with open(tmp_path, "w", encoding="utf-8", newline="") as f:
        f.write("".join(new_lines))
    os.replace(tmp_path, path)

# Record file truncated at start of every synthesis run (re-entry never
# double-appends); one row per inserted line, in insertion order.
with open(record_path, "w", encoding="utf-8", newline="") as f:
    for row in record_rows:
        f.write(row + "\n")

sys.stderr.write(
    f"form-family synthesis: {key}: inserted {len(record_rows)} field "
    f"line(s) across {len(names)} entry file(s)\n")
PYEOF
}

# ── Adapter-private MIGRATION-TRIAGE assembly ──────────────────────────────
#
# _v10_to_v11_assemble_triage
#     Assemble `docs/project/MIGRATION-TRIAGE.md` (a migrator-GENERATED,
#     client-owned, migration-transient file — never a template) from:
#       - the per-stream capture files (verbatim, provenance delimiters
#         included) → `## From <monolith>` sections;
#       - a fence-aware second pass over the state-dir monolith
#         snapshots → `## Derived: section membership` (backlog `##`
#         section heads → ordered TD ids) and `## Derived: milestone
#         membership` (plan mid-file `#` H1 heads seen after the first
#         phase anchor → ordered phase ids);
#       - the synthesis-record TSVs → `## Synthesized fields` (one
#         fenced machine block, rows verbatim);
#       - the migrated tree + the installed backlog `_rules.md` schema →
#         `## Manual fill required` (Status-missing suggestion table
#         derived from completion-checklist rows in the captured
#         content; Goal-missing list; out-of-enum payload list; plus
#         one fenced machine block of `<entry-relpath>\t<class>` rows).
#     All lists are computed from the actual data at run time — never
#     hard-coded. Written iff (captures ∪ synthesis ∪ manual-fill) is
#     nonempty; sections are derived/generated content OUTSIDE the
#     accounting equation by construction (the equation reads the
#     capture files, not this file).
_v10_to_v11_assemble_triage() {
    V10_TRIAGE_TARGET="$_MIGRATOR_TARGET" \
    V10_TRIAGE_STATE="$_MIGRATOR_STATE_DIR" \
        python3 - <<'PYEOF'
import os
import re
import sys

target = os.environ["V10_TRIAGE_TARGET"]
state = os.environ["V10_TRIAGE_STATE"]

STREAMS = [
    ("project-backlog", "BACKLOG.md", "backlog"),
    ("project-implementation-plan", "IMPLEMENTATION-PLAN.md",
     "implementation-plan"),
    ("project-changelog", "CHANGELOG.md", "changelog"),
]


def read_text(path):
    try:
        with open(path, "r", encoding="utf-8", newline="") as f:
            return f.read()
    except OSError:
        return None


def field_present(body, field):
    """Same field-line grammar the shipped validate-docs.sh conformance
    leg parses (`**Field**:` / `Field:` / `- Field:` forms)."""
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + re.escape(field) + r"\*{0,2}\s*:",
        re.MULTILINE)
    return rx.search(body) is not None


def field_value(body, field):
    rx = re.compile(
        r"^\s*(?:[-*]\s*)?\*{0,2}" + re.escape(field) + r"\*{0,2}\s*:(.*)$",
        re.MULTILINE)
    m = rx.search(body)
    return m.group(1).strip().strip("*").strip() if m else ""


def fence_aware_lines(text):
    """Yield (line, in_fence) with the walker's fence semantics: a
    line starting with ``` toggles fence state and is itself routed by
    the PRE-toggle state."""
    in_fence = False
    for line in text.splitlines():
        toggled = line.startswith("```")
        yield line, in_fence
        if toggled:
            in_fence = not in_fence


# ── Captures + synthesis records (stream order) ──────────────
captures = []    # (monolith display name, capture text) — nonempty only
synth_rows = []  # verbatim TSV rows
for skey, mono_name, _subdir in STREAMS:
    cap = read_text(os.path.join(state, "dropped-%s.md" % skey))
    if cap and cap.strip():
        captures.append((mono_name, cap))
    tsv = read_text(os.path.join(state, "synthesized-%s.tsv" % skey))
    if tsv:
        synth_rows.extend(r for r in tsv.splitlines() if r.strip())

# ── Membership maps (fence-aware second pass over the snapshots) ──
section_map = []  # ordered (heading text, [TD ids])
snap = read_text(os.path.join(state, "monolith-project-backlog.md"))
if snap:
    td_re = re.compile(r"^\*\*(TD-\d+)\s+— ")
    current = None
    for line, in_fence in fence_aware_lines(snap):
        if in_fence:
            continue
        m = td_re.match(line)
        if m:
            if current is not None:
                current[1].append(m.group(1))
            continue
        if line.startswith("## "):
            current = (line[3:].strip(), [])
            section_map.append(current)
    section_map = [(h, ids) for h, ids in section_map if ids]

milestone_map = []  # ordered (heading text, [phase ids])
snap = read_text(os.path.join(state, "monolith-project-implementation-plan.md"))
if snap:
    ph_re = re.compile(r"^## Phase (\d+) — ")
    current = None
    seen_first_anchor = False
    for line, in_fence in fence_aware_lines(snap):
        if in_fence:
            continue
        m = ph_re.match(line)
        if m:
            seen_first_anchor = True
            if current is not None:
                current[1].append("phase-" + m.group(1))
            continue
        # A mid-file H1 seen AFTER the first phase anchor is a
        # milestone divider (the walker's H1-break class); a
        # pre-anchor H1 is the document title.
        if line.startswith("# ") and seen_first_anchor:
            current = (line[2:].strip(), [])
            milestone_map.append(current)
    milestone_map = [(h, ids) for h, ids in milestone_map if ids]

# ── Status suggestions from completion-checklist rows in captures ──
# Suggestion-grade only: a table row whose first cell names a phase,
# with unambiguous checked/unchecked cells. Every suggestion row is
# marked review-before-applying in the rendered table.
suggestions = {}
CHECK_YES = {"✓", "✅", "x", "X", "[x]", "yes"}
CHECK_NO = {"", "-", "—", "[ ]", "no"}
for _name, cap in captures:
    for line in cap.splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells:
            continue
        pm = re.search(r"[Pp]hase[ -]?(\d+)", cells[0])
        if not pm:
            continue
        yes = sum(1 for c in cells[1:] if c in CHECK_YES)
        no = sum(1 for c in cells[1:] if c in CHECK_NO)
        if yes == 0 and no == 0:
            continue
        if yes > 0 and no == 0:
            suggestions[pm.group(1)] = "done"
        elif yes > 0:
            suggestions[pm.group(1)] = "in-progress"
        else:
            suggestions[pm.group(1)] = "not-started"

# ── Manual fill (computed from the migrated tree + installed schema) ──
status_missing = []  # (relpath, filename)
goal_missing = []    # relpath
impl_dir = os.path.join(target, "docs", "project", "implementation-plan")
if os.path.isdir(impl_dir):
    phase_names = sorted(
        (n for n in os.listdir(impl_dir) if re.match(r"^phase-\d+\.md$", n)),
        key=lambda n: int(re.match(r"^phase-(\d+)\.md$", n).group(1)))
    for n in phase_names:
        body = read_text(os.path.join(impl_dir, n)) or ""
        rel = "implementation-plan/" + n
        if not field_present(body, "Status"):
            status_missing.append((rel, n))
        if not field_present(body, "Goal"):
            goal_missing.append(rel)

payload_bad = []  # (relpath, field, value)
rules = read_text(os.path.join(target, "docs", "project", "backlog",
                               "_rules.md"))
bl_dir = os.path.join(target, "docs", "project", "backlog")
if rules and os.path.isdir(bl_dir):
    def schema_raw(key):
        m = re.search(r"^- %s:(.*)$" % re.escape(key), rules, re.MULTILINE)
        return re.findall(r'"[^"]+"|\S+', m.group(1)) if m else []

    def clean(tok):
        return tok.strip().strip('"')

    marker_enum = [clean(t) for t in schema_raw("marker-enum")]
    scope_enum = [clean(t) for t in schema_raw("scope-enum")]
    severity_enum = [clean(t) for t in schema_raw("severity-enum")]
    pairs = []
    for tok in schema_raw("payload-by-marker"):
        if tok.startswith("=") and pairs:
            pairs[-1] += tok
        else:
            pairs.append(tok)
    payload_by_marker = {}
    for pair in pairs:
        mk, _, pf = pair.partition("=")
        mk, pf = clean(mk), clean(pf)
        if mk and pf:
            payload_by_marker[mk] = pf

    for n in sorted(n for n in os.listdir(bl_dir)
                    if re.match(r"^TD-\d+\.md$", n)):
        body = read_text(os.path.join(bl_dir, n)) or ""
        rel = "backlog/" + n
        marker = field_value(body, "Marker")
        if not marker or marker not in marker_enum:
            continue
        pf = payload_by_marker.get(marker, "")
        if not pf:
            continue
        val = field_value(body, pf)
        if not val:
            continue
        if pf == "Scope" and scope_enum:
            ok = (val in scope_enum
                  or ("phase-N" in scope_enum
                      and re.fullmatch(r"phase-\d+", val) is not None))
            if not ok:
                payload_bad.append((rel, "Scope", val))
        elif pf == "Severity" and severity_enum:
            if val not in severity_enum:
                payload_bad.append((rel, "Severity", val))
        # Verify-Source is presence-only (open string) — never
        # out-of-enum.

# ── Existence rule: written iff anything needs triage ────────
if not captures and not synth_rows \
        and not (status_missing or goal_missing or payload_bad):
    sys.exit(0)

# ── Assemble ─────────────────────────────────────────────────
out = []
out.append("# MIGRATION-TRIAGE — v10 content preserved for triage\n\n")
out.append("Content your v10 monoliths carried outside entry spans, "
           "preserved\nverbatim for triage — plus the migration's "
           "synthesized-field record and\nthe manual-fill list. The "
           "triage procedure lives in\nMIGRATION-v10-to-v11.md "
           "§ \"What the user does\". Delete this file when\n"
           "every section is triaged.\n")

for mono_name, cap in captures:
    out.append("\n## From %s\n\n" % mono_name)
    out.append(cap if cap.endswith("\n") else cap + "\n")

if section_map:
    out.append("\n## Derived: section membership\n\n")
    for head, ids in section_map:
        out.append("- %s: %s\n" % (head, ", ".join(ids)))

if milestone_map:
    out.append("\n## Derived: milestone membership\n\n")
    for head, ids in milestone_map:
        out.append("- %s: %s\n" % (head, ", ".join(ids)))

if synth_rows:
    out.append("\n## Synthesized fields\n\n```\n")
    for row in synth_rows:
        out.append(row + "\n")
    out.append("```\n")

if status_missing or goal_missing or payload_bad:
    out.append("\n## Manual fill required\n")
    if status_missing:
        out.append("\n### Status: missing — suggestion table "
                   "(review each suggestion before applying)\n\n")
        out.append("| Entry | Suggested Status | Source |\n|---|---|---|\n")
        for rel, n in status_missing:
            num = re.match(r"^phase-(\d+)\.md$", n).group(1)
            if num in suggestions:
                out.append("| %s | %s | completion-checklist row "
                           "(suggestion — review before applying) |\n"
                           % (rel, suggestions[num]))
            else:
                out.append("| %s | — | no suggestion source |\n" % rel)
    if goal_missing:
        out.append("\n### Goal: missing — author each "
                   "(narrative; never auto-filled)\n\n")
        for rel in goal_missing:
            out.append("- %s\n" % rel)
    if payload_bad:
        out.append("\n### Payload out of enum — correct each to a "
                   "valid enum member\n\n")
        for rel, fld, val in payload_bad:
            out.append("- %s — %s: %s\n" % (rel, fld, val))
    out.append("\n```\n")
    for rel, _n in status_missing:
        out.append("%s\tmissing-status\n" % rel)
    for rel in goal_missing:
        out.append("%s\tmissing-goal\n" % rel)
    for rel, fld, val in payload_bad:
        out.append("%s\tpayload-out-of-enum:%s=%s\n" % (rel, fld, val))
    out.append("```\n")

path = os.path.join(target, "docs", "project", "MIGRATION-TRIAGE.md")
tmp = path + ".triage-tmp"
with open(tmp, "w", encoding="utf-8", newline="") as f:
    f.write("".join(out))
os.replace(tmp, path)
sys.stderr.write(
    "per-entry decompose: assembled docs/project/MIGRATION-TRIAGE.md\n")
PYEOF
}
