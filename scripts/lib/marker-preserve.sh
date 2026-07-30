# scripts/lib/marker-preserve.sh — trinity marker-aware merge engine (BD-136).
#
# Sourced by scripts/lib/customization-preserve.sh; the `trinity` dispatch
# case delegates to marker_preserve_trinity. Do NOT add a shebang — this file
# is sourced, not executed.
#
# ── What this is ──────────────────────────────────────────────────────────
# A CLIENT project wraps its trinity (CLAUDE.md / AGENTS.md / GEMINI.md)
# customizations in HTML-comment marker pairs so they survive byte-identical
# across pack updates. Two shapes (BD-136 spec):
#
#   Shape A — pack owns the H2 + canonical body; the project's additions are
#             wrapped in <!-- BEGIN project-owned --> … <!-- END project-owned -->
#             INSIDE the section body (the H2 sits OUTSIDE the markers).
#   Shape B — the project owns a whole section: the marker pair wraps the
#             heading line + entire body. Used for new project sections,
#             renamed [CONDITIONAL] sections, and overrides (same-H2-name
#             suppresses the pack version; a `renamed-from` annotation extends
#             the override match key, multi-name supported).
#
# ── The safety invariant (the whole engine in one sentence) ───────────────
# marker_preserve_trinity emits a clean `merged-with-customization` (pack
# skeleton adopted from THEIRS + project marker regions preserved byte-
# identical) ONLY when the out-of-marker pack-body reconciliation is provably
# safe. In EVERY other case it routes to the SAME legacy sidecar /
# needs-reconciliation path (_cp_strategy_text's real-merge behavior: THEIRS→
# DEST, full project copy→sidecar, disposition needs-reconciliation). So the
# WORST case for a marked trinity is EXACTLY today's behavior (a safe, loud
# sidecar) — never a silent overwrite/keep (BD-136 L-8; B1 fix). This is a
# BASE-PREFERRED, degrade-SAFE merge — never "BASE-independent".
#
# ── Two BASE regimes (out-of-marker pack body, per OURS pack section) ─────
#   Regime A — BASE present (migrator path). Compare the section's masked
#     out-of-marker body across BASE vs OURS:
#       base-body == ours-masked  → project did NOT edit pack body outside
#                                    markers → adopt THEIRS body (clean graft).
#       base-body != ours-masked  → project DID edit pack body outside markers
#                                    → sidecar / needs-reconciliation (never
#                                    silent). This gives the 3-way its teeth.
#   Regime B — BASE absent ("", the init --update path; migrator baseline
#     not-found). Cannot attribute a divergence:
#       ours-masked == theirs-body → clean graft (project only touched marker
#                                    regions, or is already on the shipping
#                                    pack body for this section).
#       ours-masked != theirs-body → sidecar / needs-reconciliation (never a
#                                    silent THEIRS-adoption). This is the
#                                    generalized L-2 "pack body diverged"
#                                    signal when no baseline can attribute it.
#
# ── Graft granularity (a documented, safe coarsening) ─────────────────────
# The engine reconciles WHOLE-FILE: it validates every OURS pack section's
# out-of-marker body under the active regime; if ANY section (or the preamble)
# conflicts, the WHOLE file routes to the sidecar. On a fully-clean file it
# emits the graft: the THEIRS canonical section sequence (the spine) with
# project Shape B overrides spliced in at their canonical position, project-
# original Shape B sections appended after the spine, and each Shape A
# project block re-grafted at the tail of its (adopted) host section body.
# Coarsening to whole-file conflict only WIDENS a conflict, never narrows
# safety (BD-136 architecture §1.2).
#
# ── Fail-loud gates (all route to the sidecar / needs-reconciliation path
#    with a SPECIFIC message; never a silent merge; the driver runs under
#    `set -euo pipefail`, so these RETURN 0, they do not exit non-zero) ────
#   Step 1 (L-9, HOISTED to the top, before the marker-count branch): any
#     `## `/`### ` heading in OURS carrying the literal [CONDITIONAL] prefix
#     → fail loud. Hoisting it above the marker-count branch makes a real
#     markerless v10/v9.3 trinity (which carries [CONDITIONAL] but ZERO
#     markers) fail loud instead of silently taking the no-marker fallback.
#   Step 2 (M2): the no-marker fallback triggers on zero marker TOKENS (not
#     zero PAIRS), fence-aware — so a lone orphan BEGIN (1 token, 0 pairs)
#     enters the graft where the L-6 gate adjudicates it, rather than being
#     swallowed by the legacy fallback.
#   L-6: orphan / unbalanced / nested markers, or a marker inside a fenced
#     code block → fail loud.
#   L-1 / V-2: a partial-wrap (a heading inside a Shape A region that is not
#     the Project-addenda seed-slot) → fail loud.
#   L-4 / V-6: an H2/H3 name appearing in BOTH Shape A and Shape B (or twice
#     in Shape B) → fail loud.
#   L-10 / O-9: a `renamed-from` name with no canonical match → BASE-aware
#     soft-classify: retirement (BASE had it, THEIRS dropped it) → benign
#     soft no-op; typo (BASE never had it) → hard conflict; BASE absent →
#     conservative conflict whose message names the retirement possibility.
#
# ── The single pinned fence predicate (BD-136 S2) ─────────────────────────
# A line whose first NON-whitespace run is >=3 backticks toggles fenced-code
# state. Tilde (~~~) lines and >3-backtick fences are OUT of scope for
# wrapping marker examples (do not use them). This bash engine and the
# Python Check 91 validator implement the SAME predicate; the shared fixture
# scripts/tests/fixtures/marker-fence-grammar/ cross-checks the two parsers.
#
# ── Reused from customization-preserve.sh (sourced before this at runtime) ─
#   _cp_record, _cp_write_diff, _cp_strategy_text, _CP_SIDECAR_SUFFIX,
#   _CP_DISP_NEEDS_RECONCILIATION.

# ── Fence-aware primitives (awk; onetrueawk / gawk / mawk safe — no interval
#    expressions, no gensub). ────────────────────────────────────────────

# Count marker TOKENS (BEGIN or END) outside fenced code blocks. Prints an
# integer. Load-bearing for the M2 zero-TOKEN fallback trigger AND the S2
# merger-side fence classification.
_mp_count_tokens() {
    awk '
      BEGIN{ infence=0; n=0 }
      {
        t=$0; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence = (infence?0:1); next }
        if (infence) next
        if (index($0,"<!-- BEGIN project-owned")>0) n++
        if (index($0,"<!-- END project-owned")>0)   n++
      }
      END{ print n+0 }
    ' "$1"
}

# Print each `## `/`### ` heading line (trimmed) in a file that carries the
# literal [CONDITIONAL] prefix outside a fenced code block (BD-136 L-9).
# Fence-aware.
_mp_conditional_headings() {
    awk '
      function trim(s){ sub(/[ \t]+$/,"",s); return s }
      BEGIN{ infence=0 }
      {
        t=$0; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence = (infence?0:1); next }
        if (infence) next
        if (($0 ~ /^## / || $0 ~ /^### /) && $0 ~ /\[CONDITIONAL\]/) print trim($0)
      }
    ' "$1"
}

# BD-136 L-9 Step-1 hoist, BASE-AWARE (POQ-1 fix — arch ARCHITECTURE-BD136-POQ1
# §3.1). Return 0 (FIRE the fail-loud hoist) iff a `[CONDITIONAL]` section is
# un-auto-retirable; return 1 (do NOT fire → the section is the v10 default and
# will be cleanly adopted from THEIRS by the markerless fallback).
#   - no `[CONDITIONAL]` heading in OURS        → 1 (nothing to fire on)
#   - BASE absent/empty                         → 0 (cannot attribute: client
#                                                    init --update anomaly, or a
#                                                    regressed v11 trinity — M-14a)
#   - BASE present, ANY `[CONDITIONAL]` section customized (base != ours) → 0
#                                                    (genuine keep/delete — M-14b)
#   - BASE present, EVERY `[CONDITIONAL]` section byte-identical base-vs-ours → 1
#                                                    (v10 default → auto-adopt — M-14c)
# Per-`[CONDITIONAL]`-SECTION granularity (OI-3): fire only for the customized
# section(s), so the L-9-specific message appears only when a `[CONDITIONAL]`
# section is itself the customized one. All O(lines): one fence-aware awk scan +
# one `_mp_extract_section`+string-compare per matched heading (<=5 per file).
_mp_conditional_needs_reconciliation() {
    local base="$1" ours="$2"
    local heads h
    heads=$(_mp_conditional_headings "$ours")
    [[ -n "$heads" ]] || return 1                 # no [CONDITIONAL] → do not fire
    if [[ -z "$base" || ! -e "$base" ]]; then
        return 0                                  # BASE absent → cannot attribute → fire
    fi
    while IFS= read -r h; do
        [[ -n "$h" ]] || continue
        if [[ "$(_mp_extract_section "$base" "$h")" != "$(_mp_extract_section "$ours" "$h")" ]]; then
            return 0                              # this optional section was customized → fire
        fi
    done <<EOF
$heads
EOF
    return 1                                      # all matched sections are the v10 default → do not fire
}

# Parse OURS into a marker-region manifest (fence-aware). Emits TSV lines:
#   REGION<TAB>A|B<TAB><host-or-owned-heading><TAB><begin-ln><TAB><end-ln><TAB><begin-raw>
#   ERR<TAB><code><TAB><message>
# Shape A: <heading> = the enclosing pack H2. Shape B: <heading> = the owned
# heading line. Detects orphan/nested (L-6) and partial-wrap (L-1/V-2), with
# the `## Project addenda` seed-slot exception (a seed Shape A body may carry
# project H3/H4 headings).
_mp_regions() {
    awk '
      function trim(s){ sub(/[ \t]+$/,"",s); return s }
      function isheading(s){ return (s ~ /^## / || s ~ /^### /) }
      BEGIN{ infence=0; open=0; ln=0; curh2=""; beginln=0; beginraw="";
             beginh2=""; ownh=""; sawbody=0; sawheading=0 }
      {
        ln++; raw=$0
        t=raw; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence=(infence?0:1); if(open) sawbody=1; next }
        if (infence){ if(open) sawbody=1; next }
        hasB = (index(raw,"<!-- BEGIN project-owned")>0)
        hasE = (index(raw,"<!-- END project-owned")>0)
        if (hasB){
          if (open){ print "ERR\tnest\tnested BEGIN marker at line " ln " (region still open from line " beginln ")" }
          open=1; beginln=ln; beginraw=raw; beginh2=curh2; ownh=""; sawbody=0; sawheading=0
          next
        }
        if (hasE){
          if (!open){ print "ERR\torphan\torphan END marker (no open BEGIN) at line " ln; next }
          if (beginh2 ~ /^## Project addenda/){
            # Seed-slot exception: a Shape A body under `## Project addenda`
            # may contain project headings — always Shape A.
            print "REGION\tA\t" trim(beginh2) "\t" beginln "\t" ln "\t" beginraw
          } else if (sawheading){
            print "REGION\tB\t" trim(ownh) "\t" beginln "\t" ln "\t" beginraw
          } else if (trim(curh2)==""){
            # BLOCKER-2 (L-8): a marker region above the first `## ` has no H2/H3
            # host — it is neither Shape A (needs a section) nor Shape B (needs an
            # owned heading). Fail loud, never silently drop it in the graft.
            print "ERR\tnohost\tproject-owned marker region beginning at line " beginln " has no enclosing H2 heading (it sits in the preamble, above the first H2) — a marker must wrap a section body (Shape A, inside a section) or a whole section (Shape B); move it under a heading"
          } else {
            print "REGION\tA\t" trim(curh2) "\t" beginln "\t" ln "\t" beginraw
          }
          open=0; next
        }
        if (open){
          if (isheading(raw)){
            if (beginh2 ~ /^## Project addenda/){ sawbody=1 }        # seed: headings allowed
            else if (!sawheading && !sawbody){ sawheading=1; ownh=raw }  # Shape B owned heading
            else if (sawheading){ }                                  # extra heading in Shape B body: owned, fine
            else { print "ERR\tpartial\theading inside a Shape A region under " (curh2==""?"(preamble)":trim(curh2)) " at line " ln }
          } else if (raw ~ /[^ \t]/){ sawbody=1 }
          next
        }
        if (isheading(raw) && raw ~ /^## /){ curh2=raw }
      }
      END{ if (open) print "ERR\torphan\tunclosed BEGIN marker (opened at line " beginln ")" }
    ' "$1"
}

# Print the ordered list of `## ` heading lines (trimmed) in a file, fence-aware.
_mp_h2_list() {
    awk '
      BEGIN{ infence=0 }
      {
        t=$0; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence=(infence?0:1); next }
        if (!infence && $0 ~ /^## /){ h=$0; sub(/[ \t]+$/,"",h); print h }
      }
    ' "$1"
}

# Print the section body for a given `## ` heading (heading line through the
# line before the next `## `, or EOF), fence-aware boundaries.
_mp_extract_section() {
    awk -v want="$2" '
      function trim(s){ sub(/[ \t]+$/,"",s); return s }
      BEGIN{ infence=0; grab=0 }
      {
        raw=$0; t=raw; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence=(infence?0:1); if(grab) print raw; next }
        if (!infence && raw ~ /^## /){
          if (trim(raw)==want){ grab=1; print raw; next }
          else if (grab){ grab=0 }
        }
        if (grab) print raw
      }
    ' "$1"
}

# Print everything before the first `## ` heading (the preamble), fence-aware.
_mp_extract_preamble() {
    awk '
      BEGIN{ infence=0 }
      {
        raw=$0; t=raw; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence=(infence?0:1); print raw; next }
        if (!infence && raw ~ /^## /){ exit }
        print raw
      }
    ' "$1"
}

# Strip Shape A marker blocks (BEGIN..END inclusive) from stdin, fence-aware.
# Yields a section's out-of-marker "masked" pack body.
_mp_strip_marker_blocks() {
    awk '
      BEGIN{ infence=0; skip=0 }
      {
        raw=$0; t=raw; sub(/^[ \t]+/,"",t)
        if (t ~ /^```/){ infence=(infence?0:1); if(!skip) print raw; next }
        if (infence){ if(!skip) print raw; next }
        if (index(raw,"<!-- BEGIN project-owned")>0){ skip=1; next }
        if (index(raw,"<!-- END project-owned")>0){ skip=0; next }
        if (!skip) print raw
      }
    '
}

# Print line range [b,e] (1-based, inclusive) of a file verbatim.
_mp_lines() {
    awk -v b="$2" -v e="$3" 'NR>=b && NR<=e { print }' "$1"
}

# ── The conflict + clean-graft sinks (mirror _cp_strategy_text semantics) ──

# Route the file to the legacy sidecar / needs-reconciliation path with a
# specific message. THEIRS→DEST (new canonical); full OURS→sidecar (project
# copy preserved byte-identical); records needs-reconciliation. Never silent.
_mp_sidecar_conflict() {
    local base="$1" ours="$2" theirs="$3" rel="$4" dest="$5" notes="$6"
    local sidecar="${dest}${_CP_SIDECAR_SUFFIX}"
    local diff_path
    mkdir -p "$(dirname "$dest")"
    diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
    cp "$ours" "$sidecar"
    cp "$theirs" "$dest"
    _cp_record "$_CP_DISP_NEEDS_RECONCILIATION" "trinity" "$rel" "sidecar" \
        "$sidecar" "$diff_path" "$notes"
}

# ── Public entry ──────────────────────────────────────────────────────────
#
# marker_preserve_trinity BASE OURS THEIRS REL DEST
#   BASE may be "" (Regime B). Records exactly one disposition, writes DEST
#   (and a sidecar where needed), returns 0.
marker_preserve_trinity() {
    local base="$1" ours="$2" theirs="$3" rel="$4" dest="$5"
    # ALL loop / read-into variables are declared local up front. This function
    # is sourced and CALLED FROM INSIDE another function's loop (the migrator
    # framework's manifest dispatch); a leaked `read` variable (e.g. `head`,
    # `re`, `th`, `oh`) would clobber the caller's loop state and silently drop
    # files. Never introduce an undeclared read/loop variable here.
    local tag shape head rb re beginraw th oh

    # Guard: the marker graft needs both an OURS and a THEIRS to graft
    # between. Add/remove/new-file/removed cases have no markers to preserve
    # → delegate to the legacy text strategy (identical to pre-BD-136).
    if [[ -z "$ours" || ! -e "$ours" || -z "$theirs" || ! -e "$theirs" ]]; then
        _cp_strategy_text "trinity" "$base" "$ours" "$theirs" "$rel" "$dest"
        return 0
    fi

    # Fast-path (unchanged): the client's trinity is byte-identical to the new
    # pack canonical (and to BASE where present) → nothing to merge →
    # unchanged-pack, NO sidecar. Covers an UNCHANGED v11 client on init --update
    # (both sides carry the shipped empty seed pair, base=""). Placed before the
    # [CONDITIONAL] hoist so an identical-to-pack file is never treated as a
    # carryover.
    if cmp -s "$ours" "$theirs" \
       && { [[ -z "$base" || ! -e "$base" ]] || cmp -s "$base" "$ours"; }; then
        _cp_record "unchanged-pack" "trinity" "$rel" "none" "-" "-" "-"
        return 0
    fi

    # Step 1 (L-9 HOIST, BASE-AWARE — POQ-1 fix): fail loud on an
    # UN-AUTO-RETIRABLE [CONDITIONAL] section — BEFORE the marker-count branch.
    # Fires when BASE is absent (client anomaly / M-14a) OR a [CONDITIONAL]
    # section body was customized (base != ours — M-14b). Stays SILENT on the
    # NORMAL migration path where the [CONDITIONAL] section is the untouched v10
    # default (base == ours — M-14c): the markerless fallback then resolves to
    # pack-update-applied and adopts THEIRS's already-retired canonical, so the
    # retirement is delivered by adopting THEIRS (no spurious sidecar, no
    # BD-095 pause). A markerless v10/v9.3 trinity still does NOT slip through
    # silently on the customized / BASE-absent branches.
    if _mp_conditional_needs_reconciliation "$base" "$ours"; then
        _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
            "project trinity carries a '[CONDITIONAL]' heading whose body you customized — decide: keep (rename + wrap Shape B, optionally with renamed-from) or delete; the literal prefix must not remain"
        return 0
    fi

    # Step 2 (M2): zero marker TOKENS → legacy fallback (byte-unaware 3-way).
    # A lone orphan (1 token, 0 pairs) has >0 tokens → it enters the graft
    # where the L-6 gate adjudicates it (not swallowed here).
    local tokens
    tokens=$(_mp_count_tokens "$ours")
    if [[ "$tokens" -eq 0 ]]; then
        _cp_strategy_text "trinity" "$base" "$ours" "$theirs" "$rel" "$dest"
        return 0
    fi

    # Step 3: parse OURS into a region manifest; L-6 / L-1 gate.
    local manifest
    manifest=$(_mp_regions "$ours")
    if printf '%s\n' "$manifest" | grep -q '^ERR	'; then
        local msg
        msg=$(printf '%s\n' "$manifest" | awk -F'\t' '$1=="ERR"{print $3; exit}')
        _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
            "marker well-formedness failure (L-6/L-1): ${msg}"
        return 0
    fi

    # Load regions into parallel indexed arrays (bash 3.2: no assoc arrays).
    local -a RSHAPE RHEAD RB RE RRF
    local n_reg=0
    while IFS=$'\t' read -r tag shape head rb re beginraw; do
        [[ "$tag" == "REGION" ]] || continue
        RSHAPE[$n_reg]="$shape"
        RHEAD[$n_reg]="$head"
        RB[$n_reg]="$rb"
        RE[$n_reg]="$re"
        local rf=""
        if [[ "$beginraw" == *renamed-from* ]]; then
            rf=$(printf '%s\n' "$beginraw" | grep -oE '"[^"]*"' | sed 's/^"//; s/"$//' | tr '\n' '\036')
        fi
        RRF[$n_reg]="$rf"       # rf names joined by RS (\036); empty if none
        n_reg=$((n_reg + 1))
    done <<EOF
$manifest
EOF

    # Step 4 (L-4 / V-6): no H2/H3 name in BOTH Shape A and Shape B, and no
    # Shape B owned name twice.
    local i j
    for ((i = 0; i < n_reg; i++)); do
        if [[ "${RSHAPE[$i]}" == "B" ]]; then
            for ((j = 0; j < n_reg; j++)); do
                [[ "$j" -eq "$i" ]] && continue
                if [[ "${RHEAD[$j]}" == "${RHEAD[$i]}" ]]; then
                    _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
                        "duplicate H2/H3 name across Shape A and Shape B (L-4/V-6): '${RHEAD[$i]}'"
                    return 0
                fi
            done
        fi
    done

    # THEIRS canonical H2 headings (ordered) + a BASE heading set for O-9.
    local theirs_heads base_heads=""
    theirs_heads=$(_mp_h2_list "$theirs")
    if [[ -n "$base" && -e "$base" ]]; then
        base_heads=$(_mp_h2_list "$base")
    fi

    # Step 5 (L-10 / O-9): validate every renamed-from name. A name with no
    # THEIRS match is BASE-aware soft-classified.
    for ((i = 0; i < n_reg; i++)); do
        [[ -n "${RRF[$i]}" ]] || continue
        local rfname
        while IFS= read -r rfname; do
            [[ -n "$rfname" ]] || continue
            if printf '%s\n' "$theirs_heads" | grep -qxF "$rfname"; then
                continue                              # override target present
            fi
            # No THEIRS match — soft-classify.
            if [[ -n "$base" && -e "$base" ]]; then
                if printf '%s\n' "$base_heads" | grep -qxF "$rfname"; then
                    continue                          # retirement: benign no-op
                fi
                _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
                    "renamed-from names a section absent from BOTH the new canonical and the baseline — likely a typo (L-10): '${rfname}'"
                return 0
            fi
            _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
                "renamed-from names '${rfname}', absent from the new canonical and no baseline to disambiguate — it may have been RETIRED (safe to drop from renamed-from) or MISTYPED; confirm (L-10)"
            return 0
        done <<EOF
$(printf '%s' "${RRF[$i]}" | tr '\036' '\n')
EOF
    done

    # Build the set of Shape B owned/renamed keys and the set of Shape A hosts.
    # Determine, per THEIRS heading, whether it is suppressed by a Shape B
    # override and (if so) which region emits at that (first-matching) slot.
    # NOTE: $work cleanup is EXPLICIT (rm before every return past this point).
    # Do NOT use a `trap … RETURN` here — a RETURN trap is a GLOBAL, single-slot
    # handler; setting one inside this function would CLOBBER any RETURN trap the
    # caller (e.g. the migrator framework) relies on, silently changing its
    # behavior.
    local work
    # NIT-1: on mktemp failure, do NOT return silently with no disposition (the
    # truthful-report contract / Check 25 expects a row per file). Fail loud to
    # the reconciliation sidecar (which records a disposition and preserves OURS).
    if ! work=$(mktemp -d "${TMPDIR:-/tmp}/bd136-mp.XXXXXX"); then
        _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
            "internal error: could not create a temp work directory for the marker merge — routed to a reconciliation sidecar"
        return 0
    fi

    # emit_head[idx] = the THEIRS heading where Shape B idx emits ("" = original)
    local -a SB_EMIT
    for ((i = 0; i < n_reg; i++)); do SB_EMIT[$i]=""; done

    # For each THEIRS heading in order, mark suppression + primary emit slot.
    # suppress file: one THEIRS heading per suppressed line.
    : > "$work/suppress"
    while IFS= read -r th; do
        [[ -n "$th" ]] || continue
        for ((i = 0; i < n_reg; i++)); do
            [[ "${RSHAPE[$i]}" == "B" ]] || continue
            local matched=0
            [[ "${RHEAD[$i]}" == "$th" ]] && matched=1
            if [[ $matched -eq 0 && -n "${RRF[$i]}" ]]; then
                if printf '%s' "${RRF[$i]}" | tr '\036' '\n' | grep -qxF "$th"; then
                    matched=1
                fi
            fi
            if [[ $matched -eq 1 ]]; then
                printf '%s\n' "$th" >> "$work/suppress"
                [[ -z "${SB_EMIT[$i]}" ]] && SB_EMIT[$i]="$th"
                break
            fi
        done
    done <<EOF
$theirs_heads
EOF

    # Step 6 (regime reconciliation): every OURS pack section (a `## ` section
    # whose heading is NOT a Shape B owned heading) must reconcile safely.
    # This closes the silent-loss hole for markerless pack sections too.
    local ours_heads
    ours_heads=$(_mp_h2_list "$ours")

    # Preamble reconciliation (pack-owned; a project preamble edit is caught).
    # SYMMETRIC skeleton compare (BLOCKER-1 / arch §1.2 `ours-skel == theirs-skel`):
    # strip markers from ALL THREE sides so a marker THEIRS/BASE carries (e.g. a
    # future v11 BASE with the seed pair) never spuriously mismatches.
    _mp_extract_preamble "$ours"   | _mp_strip_marker_blocks > "$work/o_pre"
    _mp_extract_preamble "$theirs" | _mp_strip_marker_blocks > "$work/t_pre"
    local pre_clean=0
    if [[ -n "$base" && -e "$base" ]]; then
        _mp_extract_preamble "$base" | _mp_strip_marker_blocks > "$work/b_pre"
        cmp -s "$work/b_pre" "$work/o_pre" && pre_clean=1
    else
        cmp -s "$work/o_pre" "$work/t_pre" && pre_clean=1
    fi
    if [[ $pre_clean -eq 0 ]]; then
        rm -rf "$work"
        _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
            "pack-owned preamble diverges (out-of-marker) — review before adopting the new canonical (L-8)"
        return 0
    fi

    while IFS= read -r oh; do
        [[ -n "$oh" ]] || continue
        # Skip Shape B owned sections (wholly project-owned).
        local is_sb=0
        for ((i = 0; i < n_reg; i++)); do
            if [[ "${RSHAPE[$i]}" == "B" && "${RHEAD[$i]}" == "$oh" ]]; then is_sb=1; break; fi
        done
        [[ $is_sb -eq 1 ]] && continue

        # This is a pack section in OURS. It MUST exist in THEIRS (else the
        # pack retired a section the project still carries → conservative
        # conflict).
        if ! printf '%s\n' "$theirs_heads" | grep -qxF "$oh"; then
            rm -rf "$work"
            _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
                "pack section '${oh}' present in your copy is absent from the new canonical — it may have been renamed or retired; reconcile (L-8)"
            return 0
        fi

        # SYMMETRIC skeleton compare (BLOCKER-1 / arch §1.2): strip markers from
        # ALL THREE sides. THEIRS ships the empty seed pair under `## Project
        # addenda`; an OURS-stripped-vs-THEIRS-unstripped compare would mismatch
        # on that section for EVERY client on EVERY init --update.
        _mp_extract_section "$ours" "$oh" | _mp_strip_marker_blocks > "$work/o_sec"
        _mp_extract_section "$theirs" "$oh" | _mp_strip_marker_blocks > "$work/t_sec"
        local clean=0
        if [[ -n "$base" && -e "$base" ]] && printf '%s\n' "$base_heads" | grep -qxF "$oh"; then
            _mp_extract_section "$base" "$oh" | _mp_strip_marker_blocks > "$work/b_sec"
            cmp -s "$work/b_sec" "$work/o_sec" && clean=1     # Regime A
        else
            cmp -s "$work/o_sec" "$work/t_sec" && clean=1     # Regime B
        fi
        if [[ $clean -eq 0 ]]; then
            rm -rf "$work"
            _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
                "pack-owned body outside your markers under '${oh}' diverges — review and either accept the new pack content or fold your edit into a marker (L-2/L-8/B1)"
            return 0
        fi
    done <<EOF
$ours_heads
EOF

    # Step 7: build the clean graft. THEIRS spine, Shape B splice, Shape A
    # re-graft, project-original append. Written to $work/out.
    : > "$work/out"
    _mp_extract_preamble "$theirs" >> "$work/out"

    while IFS= read -r th; do
        [[ -n "$th" ]] || continue
        # Suppressed by a Shape B override?
        if grep -qxF "$th" "$work/suppress"; then
            # Emit the Shape B region whose primary slot is THIS heading.
            for ((i = 0; i < n_reg; i++)); do
                if [[ "${RSHAPE[$i]}" == "B" && "${SB_EMIT[$i]}" == "$th" ]]; then
                    _mp_lines "$ours" "${RB[$i]}" "${RE[$i]}" >> "$work/out"
                fi
            done
            # (Secondary-suppressed headings emit nothing — collapsed.)
            continue
        fi
        # A Shape A host in OURS? Emit THEIRS body, then append its Shape A block(s).
        local hosts_a=0
        for ((i = 0; i < n_reg; i++)); do
            if [[ "${RSHAPE[$i]}" == "A" && "${RHEAD[$i]}" == "$th" ]]; then hosts_a=1; break; fi
        done
        if [[ $hosts_a -eq 1 ]]; then
            # Emit THEIRS's section body with its OWN markers STRIPPED (BLOCKER-1):
            # THEIRS ships the empty seed pair under `## Project addenda`; without
            # the strip the graft would emit BOTH the empty seed pair AND the
            # project's block, doubling the pair on every update. Then append the
            # project's Shape A block(s).
            _mp_extract_section "$theirs" "$th" | _mp_strip_marker_blocks >> "$work/out"
            for ((i = 0; i < n_reg; i++)); do
                if [[ "${RSHAPE[$i]}" == "A" && "${RHEAD[$i]}" == "$th" ]]; then
                    _mp_lines "$ours" "${RB[$i]}" "${RE[$i]}" >> "$work/out"
                fi
            done
        else
            # No project block here — adopt THEIRS's section as-is (preserving any
            # shipped seed pair for a section the client didn't touch).
            _mp_extract_section "$theirs" "$th" >> "$work/out"
        fi
    done <<EOF
$theirs_heads
EOF

    # Project-original Shape B sections (no THEIRS anchor) append after spine.
    for ((i = 0; i < n_reg; i++)); do
        if [[ "${RSHAPE[$i]}" == "B" && -z "${SB_EMIT[$i]}" ]]; then
            _mp_lines "$ours" "${RB[$i]}" "${RE[$i]}" >> "$work/out"
        fi
    done

    # Clean graft: write DEST, record merged-with-customization.
    mkdir -p "$(dirname "$dest")"
    cp "$work/out" "$dest"
    rm -rf "$work"
    _cp_record "merged-with-customization" "trinity" "$rel" "merged" "-" "-" \
        "grafted project marker regions byte-identical; pack body adopted (marker-aware)"
    return 0
}
