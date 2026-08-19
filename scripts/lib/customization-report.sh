# scripts/lib/customization-report.sh — render a truthful migration report
# from the dispositions TSV produced by customization-preserve.sh (BD-088).
#
# Sourced (no shebang). Public API:
#   customization_report TSV_PATH OUT_PATH [TITLE]
#       Read TSV_PATH, write OUT_PATH (markdown). TITLE is the H1; defaults
#       to "Migration customization report".
#
# Truthful contract per BD-059: every file recorded in the TSV appears in
# the report. No file is silently dropped. The "preserved files" section
# lists every project-customized file (so the developer can audit).
#
# TSV format (from customization-preserve.sh):
#   # disposition\tclass\trel_path\taction\tsidecar\tdiff\tnotes
#   <disposition>\t<class>\t<rel_path>\t<action>\t<sidecar>\t<diff>\t<notes>

# Mirror the canonical disposition token from customization-preserve.sh so
# report.sh and preserve.sh cannot drift on the long-form name.
: "${_CP_DISP_NEEDS_RECONCILIATION:=customization-detected-needs-reconciliation}"

customization_report() {
    local tsv="$1" out="$2"
    local title="${3:-Migration customization report}"
    if [[ ! -f "$tsv" ]]; then
        printf 'error: customization_report: TSV not found: %s\n' "$tsv" >&2
        return 1
    fi
    mkdir -p "$(dirname "$out")"

    local total
    total=$(awk 'NR > 1 && NF > 0' "$tsv" | wc -l | tr -d ' ')

    {
        printf '# %s\n\n' "$title"
        printf 'Total files processed: **%s**\n\n' "$total"
        printf 'This report lists every file the migration touched. Files\n'
        printf 'with project customizations are explicitly named so you can\n'
        printf 'audit what was preserved.\n\n'

        # Sections in stable order. Each section names every file in that
        # disposition; absent dispositions are omitted (cleaner output).
        _cp_report_section "$tsv" "pack-update-applied" \
            "Files updated to new pack version" \
            "These had no project customizations; pack updates were applied directly."
        _cp_report_section "$tsv" "merged-with-customization" \
            "Files merged (project customizations preserved)" \
            "These had project customizations; the migrator merged pack updates while preserving your edits."
        # BD-287 (§2.1): the needs-reconciliation disposition renders as ONE
        # H2 with FOUR class/action-keyed H3 sub-groups (no new disposition
        # token — OI-7), each carrying the correct pointer prose. A fifth
        # catch-all sub-group preserves the truthful-report contract for any
        # other needs-reconciliation shape (e.g. a structured-config rc-error
        # sidecar fallback).
        _cp_report_reconcile_section "$tsv"
        _cp_report_section "$tsv" "removed-by-design" \
            "Files retired by pack" \
            "The new pack version no longer ships these files. Where you had customized them, the original is in a sidecar."
        _cp_report_section "$tsv" "project-only-file" \
            "Project-only files (preserved untouched)" \
            "These files exist only in your project; the migrator did not touch them."
        _cp_report_section "$tsv" "project-deleted-pack-kept" \
            "Files you removed (honored; pack still ships them)" \
            "You had previously removed these; the migrator did not restore them."
        _cp_report_section "$tsv" "removed-everywhere" \
            "Files removed everywhere" \
            "These files are absent in both your project and the new pack version. No action."
        _cp_report_section "$tsv" "unchanged-pack" \
            "Unchanged files" \
            "These are byte-identical between the previous pack baseline, your project, and the new pack version. No action."

        # Catch-all for any disposition not listed above (defensive: this
        # surfaces unknown tokens rather than dropping them).
        local unhandled
        unhandled=$(awk -F '\t' -v needs="$_CP_DISP_NEEDS_RECONCILIATION" '
            NR > 1 && NF > 0 \
            && $1 != "pack-update-applied" \
            && $1 != "merged-with-customization" \
            && $1 != needs \
            && $1 != "removed-by-design" \
            && $1 != "project-only-file" \
            && $1 != "project-deleted-pack-kept" \
            && $1 != "removed-everywhere" \
            && $1 != "unchanged-pack" \
            { print $1 }' "$tsv" | sort -u)
        if [[ -n "$unhandled" ]]; then
            printf '## Unhandled dispositions\n\n'
            printf 'The following disposition tokens were recorded but are not in the\n'
            printf 'report renderer. This is likely a defect; please file an issue.\n\n'
            while read -r token; do
                printf '### `%s`\n\n' "$token"
                _cp_report_table "$tsv" "$token"
            done <<< "$unhandled"
        fi
    } > "$out"
}

# Internal: emit one section if the disposition has any rows.
#   $1 tsv path; $2 disposition token; $3 H2 heading; $4 explanatory paragraph.
_cp_report_section() {
    local tsv="$1" disp="$2" heading="$3" intro="$4"
    local count
    count=$(awk -F '\t' -v d="$disp" 'NR > 1 && $1 == d' "$tsv" | wc -l | tr -d ' ')
    [[ "$count" -eq 0 ]] && return 0
    printf '## %s (%s)\n\n%s\n\n' "$heading" "$count" "$intro"
    _cp_report_table "$tsv" "$disp"
}

# Internal: emit a markdown table for one disposition.
_cp_report_table() {
    local tsv="$1" disp="$2"
    printf '| File | Class | Action | Sidecar | Notes |\n'
    printf '| --- | --- | --- | --- | --- |\n'
    awk -F '\t' -v d="$disp" '
        NR > 1 && $1 == d {
            sidecar = ($5 == "-" ? "—" : "`" $5 "`")
            notes   = ($7 == "-" ? "—" : $7)
            printf("| `%s` | %s | %s | %s | %s |\n", $3, $2, $4, sidecar, notes)
        }
    ' "$tsv"
    printf '\n'
}

# BD-287 (§2.1): render the needs-reconciliation disposition as ONE H2 with
# class/action-keyed H3 sub-groups. Both you and the pack edited these; HOW to
# resolve each depends on the file type, so the report prose splits four ways
# (prose-markers / trinity / scripts-agents / structured-key-merge) plus a
# truthful catch-all. Keyed on the EXISTING action verb + class columns — no new
# disposition token (OI-7). Emits nothing if the disposition has no rows.
_cp_report_reconcile_section() {
    local tsv="$1"
    local total
    total=$(awk -F '\t' -v d="$_CP_DISP_NEEDS_RECONCILIATION" \
        'NR > 1 && $1 == d' "$tsv" | wc -l | tr -d ' ')
    [[ "$total" -eq 0 ]] && return 0
    printf '## Files needing manual reconciliation (%s)\n\n' "$total"
    printf 'Both you and the pack edited these. How you resolve each depends on\n'
    printf 'the file type, grouped below.\n\n'

    # (a) prose auto-merge that left conflict markers (action `merged`, prose
    #     class generic/pm-chat only — structured `merged` rows go to (d)).
    _cp_report_reconcile_subsection "$tsv" merged \
        "Auto-merged — resolve remaining conflict markers" \
        "The migrator 3-way merged the pack and project edits, but some lines overlapped so the live file carries conflict markers. Resolve them by hand, or run the resolve-merge-conflicts skill; then mark it resolved (remove the sidecar or add its .resolved companion)."
    # (b) trinity sidecar (action `sidecar`, class `trinity`).
    _cp_report_reconcile_subsection "$tsv" trinity \
        "Trinity files — fold your prior copy into the new pack version" \
        "The live file holds the new pack trinity; your prior copy is in the sidecar. The resolve-merge-conflicts skill folds it in section-aware, or fold by hand per the pre-reconcile guide; then mark it resolved (remove the sidecar or add its .resolved companion)."
    # (c) scripts/agents sidecar (action `sidecar`, class pack-script/pack-agent).
    _cp_report_reconcile_subsection "$tsv" handreapply \
        "Scripts and agents — re-apply your customization by hand" \
        "The live file is the valid pack v11 version; your prior copy is in the sidecar. The skill does not merge executables/agents — re-apply your edit by hand over the pack file; then mark it resolved (remove the sidecar or add its .resolved companion)."
    # (d) structured config key-merged with reconciliation warnings (action
    #     `merged`, structured class e.g. claude-settings/codex-config/
    #     mcp-config-json). No diff3 conflict markers; the skill does not apply
    #     to JSON/TOML — point at the merged file + warnings, not the markers.
    _cp_report_reconcile_subsection "$tsv" structured \
        "Structured configs — auto key-merged (review the reconciliation warnings)" \
        "The migrator key-merged your JSON/TOML config with the new pack version and wrote the result to the live file, flagging reconciliation warnings where keys overlapped (see each row's notes). There are no conflict markers and the resolve-merge-conflicts skill does not apply. Review the merged file: accept the pack version (re-installs the pack config over the merge), keep your version (restore it from the sidecar), or adjust the merged keys by hand; then mark it resolved (remove the sidecar or add its .resolved companion)."
    # (e) catch-all: any other needs-reconciliation shape (truthful contract).
    _cp_report_reconcile_subsection "$tsv" other \
        "Other files needing reconciliation" \
        "Accept the pack version (the live file already holds it — remove the sidecar), keep your version (restore it from the sidecar), or merge by hand; then mark it resolved (remove the sidecar or add its .resolved companion)."
}

# Internal: emit one H3 sub-group of the needs-reconciliation area if it has
# rows. $1 tsv; $2 mode (merged|trinity|handreapply|structured|other); $3 H3 heading; $4
# intro. The mode predicate keys on the action verb + class columns.
_cp_report_reconcile_subsection() {
    local tsv="$1" mode="$2" heading="$3" intro="$4"
    local rows count
    rows=$(awk -F '\t' -v d="$_CP_DISP_NEEDS_RECONCILIATION" -v mode="$mode" '
        NR > 1 && $1 == d {
            m = "other"
            if ($4 == "merged" && ($2 == "generic" || $2 == "pm-chat")) m = "merged"
            else if ($4 == "merged") m = "structured"
            else if ($4 == "sidecar" && $2 == "trinity") m = "trinity"
            else if ($4 == "sidecar" && ($2 == "pack-script" || $2 == "pack-agent")) m = "handreapply"
            if (m == mode) {
                sidecar = ($5 == "-" ? "—" : "`" $5 "`")
                notes   = ($7 == "-" ? "—" : $7)
                printf("| `%s` | %s | %s | %s | %s |\n", $3, $2, $4, sidecar, notes)
            }
        }' "$tsv")
    [[ -z "$rows" ]] && return 0
    count=$(printf '%s\n' "$rows" | grep -c '^|')
    printf '### %s (%s)\n\n%s\n\n' "$heading" "$count" "$intro"
    printf '| File | Class | Action | Sidecar | Notes |\n'
    printf '| --- | --- | --- | --- | --- |\n'
    printf '%s\n\n' "$rows"
}
