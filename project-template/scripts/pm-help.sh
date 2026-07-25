#!/usr/bin/env bash
# scripts/pm-help.sh — `/pm-help` LCD shell form (this project).
#
# Prints the project verb manifest. A client install is ALWAYS the
# client surface, so no surface detection is needed — this reads the
# project's docs/pack/HELP-FRAGMENT.md and prints it to stdout. The
# per-CLI `/pm-help` skill invokes this same script.
#
# Usage: bash scripts/pm-help.sh   (run from anywhere in the project)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT="$SCRIPT_DIR/../docs/pack/HELP-FRAGMENT.md"

if [[ ! -f "$FRAGMENT" ]]; then
    echo "pm-help: fragment not found at $FRAGMENT" >&2
    echo "         expected docs/pack/HELP-FRAGMENT.md in this project." >&2
    exit 1
fi

cat "$FRAGMENT"
