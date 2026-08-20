#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-persona-contracts.sh — BD-116 wrapper that runs every
# persona contract under scripts/persona-contracts/ and aggregates the
# pass/fail outcome into a single CI-step result.
#
# Each contract (greenfield, mid-dev, migration, existing-source) is a
# stand-alone bash script that:
#   - materializes a sandbox via test-fixtures/build.sh --for-contract,
#   - drives the relevant pack script (init / init / migrate),
#   - asserts derived expectations (template-derived enumerations + BD-088
#     customization-preservation invariants),
#   - cleans up its sandbox via trap.
#
# Each contract exits 0 on all-pass, non-zero on any failure. This wrapper
# runs every rostered contract sequentially (independent — different
# sandboxes), reports per-contract status, and exits non-zero if any
# contract failed. The
# wrapper does NOT short-circuit — every contract runs every time so a
# regression in one does not mask a regression in another (parallel to
# the validate-pack.yml `if: always():` per-step pattern).
#
# Usage:    bash scripts/test-persona-contracts.sh
# Exit 0 = all contracts PASS; exit 1 = at least one FAILED.
#
# Reference: BACKLOG.md BD-116, BD-118 (CI wiring).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/tests/fixture-dependent/ → the shared persona-contracts dir stays at
# scripts/persona-contracts/ (not moved); reach it two levels up (BD-219
# location-based fixture cohesion).
CONTRACTS_DIR="$SCRIPT_DIR/../../persona-contracts"

if [[ ! -d "$CONTRACTS_DIR" ]]; then
    printf 'error: persona-contracts dir missing: %s\n' "$CONTRACTS_DIR" >&2
    exit 2
fi

contracts=(
    "contract-greenfield.sh"
    "contract-mid-dev.sh"
    "contract-migration.sh"
    "contract-existing-source.sh"
)

failures=0
total=${#contracts[@]}
passed_names=()
failed_names=()

for c in "${contracts[@]}"; do
    path="$CONTRACTS_DIR/$c"
    if [[ ! -x "$path" ]]; then
        printf '\n──── %s ────\n' "$c"
        printf 'error: contract not found or not executable: %s\n' "$path" >&2
        failures=$((failures + 1))
        failed_names+=("$c")
        continue
    fi
    printf '\n──── %s ────\n' "$c"
    if bash "$path"; then
        passed_names+=("$c")
    else
        failures=$((failures + 1))
        failed_names+=("$c")
    fi
done

printf '\n============================================================\n'
printf 'Persona contract summary: %d/%d passed\n' "$((total - failures))" "$total"
if [[ "${#passed_names[@]}" -gt 0 ]]; then
    printf '  PASS:\n'
    for n in "${passed_names[@]}"; do
        printf '    - %s\n' "$n"
    done
fi
if [[ "$failures" -gt 0 ]]; then
    printf '  FAIL:\n'
    for n in "${failed_names[@]}"; do
        printf '    - %s\n' "$n"
    done
    exit 1
fi
printf '\nAll persona contracts PASS.\n'
exit 0
