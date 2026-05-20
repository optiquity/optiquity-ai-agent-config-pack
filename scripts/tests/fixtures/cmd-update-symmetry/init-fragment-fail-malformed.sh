#!/usr/bin/env bash
# Synthetic init-project.sh fragment — parser-degradation fixture for
# Check 39.
#
# The cmd_update function below has an entries=() array whose body is
# only a comment — no real entries. _parse_cmd_update_entries() must
# return an empty set; Check 39 must defensively FAIL with the
# parse-failure message (not silently PASS-by-vacuity).
#
# This fixture exists to lock in the defensive-failure contract: an
# unparseable or empty entries array MUST surface a FAIL, never a
# clean PASS.

cmd_update() {
    local entries=(
        # only a comment, no real entries
    )
    echo "stub"
}
