#!/usr/bin/env bash
# Synthetic init-project.sh fragment — PASS-path fixture for Check 39.
#
# The cmd_update function below has an entries=() array with explicit
# mappings for every project-template/docs/pack/*.md file in the
# associated synthetic docs/pack/ inventory (FOO.md, BAR.md, BAZ.md).
# _parse_cmd_update_entries() must yield {FOO, BAR, BAZ} entry shapes;
# Check 39 must report zero asymmetric coverage.

cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/BAR.md:docs/pack/BAR.md:generic"
        "project-template/docs/pack/BAZ.md:docs/pack/BAZ.md:generic"
    )
    echo "stub"
}
