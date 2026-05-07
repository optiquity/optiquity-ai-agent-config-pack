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
        printf 'audit what was preserved (BD-059 truthfulness contract).\n\n'

        # Sections in stable order. Each section names every file in that
        # disposition; absent dispositions are omitted (cleaner output).
        _cp_report_section "$tsv" "pack-update-applied" \
            "Files updated to new pack version" \
            "These had no project customizations; pack updates were applied directly."
        _cp_report_section "$tsv" "merged-with-customization" \
            "Files merged (project customizations preserved)" \
            "These had project customizations; the migrator merged pack updates while preserving your edits."
        _cp_report_section "$tsv" "customization-detected-needs-reconciliation" \
            "Files needing manual reconciliation" \
            "Both you and the pack edited these. The migrator wrote the new pack template to the live file and saved your pre-update copy as a sidecar (see paths below). Please review and reconcile."
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
        unhandled=$(awk -F '\t' 'NR > 1 && NF > 0 \
            && $1 != "pack-update-applied" \
            && $1 != "merged-with-customization" \
            && $1 != "customization-detected-needs-reconciliation" \
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
