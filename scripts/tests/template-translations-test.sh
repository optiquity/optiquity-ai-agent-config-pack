#!/usr/bin/env bash
# scripts/tests/template-translations-test.sh — translation manifest
# reader + body-patch applier (BD-069).
#
# Three groups:
#   1. Manifest loader — empty, well-formed, missing file
#   2. Chain resolver — single-hop, multi-hop, no-chain
#   3. Body-patch applier — V2 §19.3 patch semantics
#   4. update-templates verb — end-to-end with synthetic fixture

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIX_DIR="$REPO_ROOT/scripts/tests/fixtures/template-versions"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }
assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-translations.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: manifest loader
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: manifest loader ===\n"

# 1.1 Missing file → empty array.
out=$(template_translations_load "/no/such/manifest.yaml")
assert_eq "1.1 missing file → []" "[]" "$out"

# 1.2 Empty manifest path → empty array.
out=$(template_translations_load "")
assert_eq "1.2 empty path → []" "[]" "$out"

# 1.3 Empty file → empty array.
empty=$(mktemp -t tt-empty.XXXXXX)
out=$(template_translations_load "$empty")
assert_eq "1.3 empty file → []" "[]" "$out"
rm -f "$empty"

# 1.4 Synthetic fixture loads to JSON array.
out=$(template_translations_load "$FIX_DIR/translations.yaml")
n_transitions=$(printf '%s' "$out" | jq 'length')
assert_eq "1.4 fixture loads 2 transitions" "2" "$n_transitions"
first_from=$(printf '%s' "$out" | jq -r '.[0].from')
first_to=$(printf '%s' "$out" | jq -r '.[0].to')
assert_eq "1.4 first transition from"   "bd-v11.0" "$first_from"
assert_eq "1.4 first transition to"     "bd-v11.1" "$first_to"
n_rules=$(printf '%s' "$out" | jq '.[0].rules | length')
assert_eq "1.4 first transition has 3 rules" "3" "$n_rules"

# 1.5 Malformed YAML → typed validation error.
malformed=$(mktemp -t tt-malformed.XXXXXX)
printf '[ this is not\n  valid : yaml :\n' > "$malformed"
err=$(template_translations_load "$malformed" 2>&1 1>/dev/null) || true
assert_contains "1.5 malformed → validation" "$err" "ERROR: validation"
rm -f "$malformed"

# ─────────────────────────────────────────────────────────────────
# Group 2: chain resolver
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: chain resolver ===\n"

manifest=$(template_translations_load "$FIX_DIR/translations.yaml")

# 2.1 Single-hop: bd-v11.0 → bd-v11.1.
out=$(template_translations_resolve_chain "bd-v11.0" "bd-v11.1" "$manifest")
n=$(printf '%s' "$out" | jq 'length')
assert_eq "2.1 single-hop chain has 3 rules"     "3" "$n"
assert_eq "2.1 first rule kind"                  "field-added" "$(printf '%s' "$out" | jq -r '.[0].kind')"

# 2.2 Multi-hop chain: bd-v11.0 → bd-v12.0 (chains v11.0→v11.1→v12.0)
out=$(template_translations_resolve_chain "bd-v11.0" "bd-v12.0" "$manifest")
n=$(printf '%s' "$out" | jq 'length')
# 3 rules from v11.0→v11.1 + 2 from v11.1→v12.0 = 5 rules
assert_eq "2.2 multi-hop chain has 5 rules" "5" "$n"
# Last rule should be from v11.1→v12.0 (field-added wi-impact).
last_kind=$(printf '%s' "$out" | jq -r '.[-1].kind')
last_to=$(printf   '%s' "$out" | jq -r '.[-1].to')
assert_eq "2.2 multi-hop last rule kind" "field-added" "$last_kind"
assert_eq "2.2 multi-hop last rule to"   "wi-impact"   "$last_to"

# 2.3 Identity (from == to) → empty rule list, rc=0.
out=$(template_translations_resolve_chain "bd-v11.0" "bd-v11.0" "$manifest")
assert_eq "2.3 identity → []" "[]" "$out"

# 2.4 No chain available → typed validation error.
err=$(template_translations_resolve_chain "bd-v11.0" "td-v11.0" "$manifest" 2>&1 1>/dev/null) || true
assert_contains "2.4 no chain → validation" "$err" "ERROR: validation"
assert_contains "2.4 message names src + dst" "$err" "bd-v11.0"

# 2.5 Empty manifest → no chain (except identity).
out=$(template_translations_resolve_chain "bd-v11.0" "bd-v11.0" "[]")
assert_eq "2.5 empty manifest identity → []" "[]" "$out"
err=$(template_translations_resolve_chain "bd-v11.0" "bd-v11.1" "[]" 2>&1 1>/dev/null) || true
assert_contains "2.5 empty manifest non-identity → validation" "$err" "ERROR: validation"

# ─────────────────────────────────────────────────────────────────
# Group 3: body-patch applier (V2 §19.3)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: body-patch applier ===\n"

original_body='<!-- pack-id: BD-001 -->
<!-- template_version: bd-v11.0 -->
<!-- pack-version: v11 -->

## Description

The original description body.

## Context

Background.'

# 3.1 field-renamed: rewrite Description → Summary, preserve content.
rules='[{"kind":"field-renamed","from":"Description","to":"Summary"}]'
patched=$(template_translations_apply_rules "$original_body" "$rules")
assert_contains "3.1 field-renamed: Summary heading present" "$patched" "## Summary"
assert_contains "3.1 field-renamed: Description heading gone" \
    "$(printf '%s' "$patched" | grep -c '^## Description' | tr -d ' ')" "0"
assert_contains "3.1 field-renamed: content preserved" "$patched" "The original description body."

# 3.2 field-added: append new section at end with TODO marker.
rules='[{"kind":"field-added","to":"wi-priority","default":""}]'
patched=$(template_translations_apply_rules "$original_body" "$rules")
assert_contains "3.2 field-added: new section at end" "$patched" "## wi-priority"
assert_contains "3.2 field-added: TODO marker"        "$patched" "TODO: pack tracker update-templates added"
# Original sections preserved.
assert_contains "3.2 field-added: Description preserved"  "$patched" "## Description"
assert_contains "3.2 field-added: content preserved"      "$patched" "The original description body."

# 3.3 field-removed: rewrite to "Context (legacy <name>)".
rules='[{"kind":"field-removed","from":"Description"}]'
patched=$(template_translations_apply_rules "$original_body" "$rules")
assert_contains "3.3 field-removed: legacy heading"        "$patched" "## Context (legacy Description)"
assert_contains "3.3 field-removed: content preserved"     "$patched" "The original description body."
# Old heading gone.
assert_eq "3.3 field-removed: original heading gone" "0" \
    "$(printf '%s' "$patched" | grep -c '^## Description$' | tr -d ' ')"

# 3.4 label-renamed: body unchanged (label rewrite is separate).
rules='[{"kind":"label-renamed","from":"status:open","to":"status:active"}]'
patched=$(template_translations_apply_rules "$original_body" "$rules")
assert_eq "3.4 label-renamed: body unchanged" "$original_body" "$patched"

# 3.5 Multi-rule chain: field-renamed Description→Summary, field-added wi-priority.
rules='[
  {"kind":"field-renamed","from":"Description","to":"Summary"},
  {"kind":"field-added","to":"wi-priority","default":""}
]'
patched=$(template_translations_apply_rules "$original_body" "$rules")
assert_contains "3.5 multi-rule: Summary heading"     "$patched" "## Summary"
assert_contains "3.5 multi-rule: wi-priority section" "$patched" "## wi-priority"
# Original content of Description survives the rename.
assert_contains "3.5 multi-rule: content preserved"   "$patched" "The original description body."

# 3.6 Empty rules: body unchanged.
patched=$(template_translations_apply_rules "$original_body" "[]")
assert_eq "3.6 empty rules: body unchanged" "$original_body" "$patched"

# ─────────────────────────────────────────────────────────────────
# Group 4: update-templates verb (end-to-end)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: update-templates verb ===\n"

# 4.1 No tracker.toml / no mapping → "no upgrades available" or
# "nothing to upgrade" message + rc=0.
TR_NOMAP=$(mktemp -d -t tt-nomap.XXXXXX)
touch "$TR_NOMAP/PACK-CHAT.md"
mkdir -p "$TR_NOMAP/.github/ISSUE_TEMPLATE"
touch "$TR_NOMAP/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_NOMAP/.github/ISSUE_TEMPLATE/inbound.yml"
out=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" update-templates --repo-root "$TR_NOMAP" 2>&1)
rc=$?
assert_eq       "4.1 no mapping rc=0"             "0" "$rc"
assert_contains "4.1 reports nothing to upgrade"  "$out" "Nothing to upgrade"
rm -rf "$TR_NOMAP"

# 4.2 Production manifest is empty (no shipped translations.yaml at v11.0
# in templates-archive root). Verb reports "no upgrades available."
TR_PROD=$(mktemp -d -t tt-prod.XXXXXX)
touch "$TR_PROD/PACK-CHAT.md"
mkdir -p "$TR_PROD/.github/ISSUE_TEMPLATE" "$TR_PROD/.pack-tracker"
touch "$TR_PROD/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_PROD/.github/ISSUE_TEMPLATE/inbound.yml"
echo '{}' > "$TR_PROD/.pack-tracker/id-map.json"
out=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" update-templates --repo-root "$TR_PROD" 2>&1)
rc=$?
assert_eq       "4.2 prod manifest absent rc=0" "0" "$rc"
assert_contains "4.2 reports no upgrades"       "$out" "no upgrades available"
rm -rf "$TR_PROD"

# 4.3 Synthetic manifest + dry-run → reports plan with transitions.
TR_SYN=$(mktemp -d -t tt-syn.XXXXXX)
touch "$TR_SYN/PACK-CHAT.md"
mkdir -p "$TR_SYN/.github/ISSUE_TEMPLATE" "$TR_SYN/.pack-tracker"
# Live work-item.yml carries the form-level template_version marker
# the verb reads.
cat > "$TR_SYN/.github/ISSUE_TEMPLATE/work-item.yml" <<'EOF'
name: test
description: test
body:
  - type: markdown
    attributes:
      value: |
        <!-- template_version: work-item-v11.0 -->
EOF
cat > "$TR_SYN/.github/ISSUE_TEMPLATE/inbound.yml" <<'EOF'
name: test
description: test
body:
  - type: markdown
    attributes:
      value: |
        <!-- template_version: inbound-v11.0 -->
EOF
echo '{"BD-001":{"id":"42","url":"x"}}' > "$TR_SYN/.pack-tracker/id-map.json"

out=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" update-templates \
    --repo-root "$TR_SYN" \
    --manifest "$FIX_DIR/translations.yaml" \
    --dry-run 2>&1)
rc=$?
assert_eq       "4.3 synthetic manifest rc=0"           "0" "$rc"
assert_contains "4.3 plan reports manifest path"        "$out" "$FIX_DIR/translations.yaml"
assert_contains "4.3 plan lists v11.0→v11.1 transition" "$out" "bd-v11.0 → bd-v11.1"
assert_contains "4.3 plan lists v11.1→v12.0 transition" "$out" "bd-v11.1 → bd-v12.0"
assert_contains "4.3 plan reports current work-item"    "$out" "work-item=work-item-v11.0"
assert_contains "4.3 dry-run stops after summary"       "$out" "stopping after plan summary"
rm -rf "$TR_SYN"

# 4.4 Bad scope value → typed validation error.
TR_BAD=$(mktemp -d -t tt-bad.XXXXXX)
touch "$TR_BAD/PACK-CHAT.md"
mkdir -p "$TR_BAD/.github/ISSUE_TEMPLATE"
touch "$TR_BAD/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_BAD/.github/ISSUE_TEMPLATE/inbound.yml"
err=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" update-templates \
    --repo-root "$TR_BAD" --scope=bogus 2>&1) || true
assert_contains "4.4 bad --scope → validation" "$err" "ERROR: validation"
rm -rf "$TR_BAD"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
