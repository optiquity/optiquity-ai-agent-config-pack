#!/usr/bin/env bash
# Synthetic init-project.sh fragment — FAIL-path fixture for Check 39.
#
# The cmd_update function below has an entries=() array that omits
# BAZ.md (compared to the PASS fixture). _parse_cmd_update_entries()
# must yield only {FOO, BAR}; Check 39 must surface a FAIL with
# BAZ.md named and a cmd_update reference in the recommendation.

cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/BAR.md:docs/pack/BAR.md:generic"
    )
    echo "stub"
}
