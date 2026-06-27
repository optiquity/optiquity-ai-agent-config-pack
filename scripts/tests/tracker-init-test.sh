#!/usr/bin/env bash
# scripts/tests/tracker-init-test.sh — offline test suite for the
# `pack tracker init` orchestrator (BD-066).
#
# Five groups:
#   1. Flag parsing — required vs missing, defaults, surface auto-
#      detection, dry-run plan.
#   2. Auth validation — missing-auth surfaces auth-missing typed code;
#      not-logged-in payload surfaces same.
#   3. Templates verification — missing template files surface
#      not-found typed code.
#   4. tracker.toml emission — written shape matches V1 §3.1; opted_in_at
#      preservation across re-runs; default values. No [mirror] table on
#      either surface (BD-206): no surface keeps a monolith mirror — both
#      pack and client configs omit the table.
#   5. Label canonical set — tracker_labels_canonical_set emits the
#      expected count + every required family member.
#
# Usage: bash scripts/tests/tracker-init-test.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

# Source the libs (same load order as scripts/pack-tracker.sh).
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-init.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: flag parsing
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: flag parsing ===\n"

# Legs 1.1-1.3 used to omit --repo-root, defaulting to $(pwd) — so a
# runtime .pack-tracker/id-map.json at the suite's cwd (e.g. the real
# pack tree in tracker mode) tripped the prior-state rail before flag
# validation. Point them at a scratch root with a pack-ops/ surface
# marker so they pass regardless of cwd state (BD-204 review NIT-2).
TR_FLAGVAL=$(mktemp -d -t tinit-flagval.XXXXXX)
mkdir -p "$TR_FLAGVAL/pack-ops"

# 1.1 missing --backend → validation error.
err=$(tracker_init_run --repo-root "$TR_FLAGVAL" --repo /x/y 2>&1 1>/dev/null) || true
assert_contains "1.1 missing --backend → validation" "$err" "ERROR: validation"
assert_contains "1.1 message names --backend"        "$err" "--backend is required"

# 1.2 missing --repo → validation error.
err=$(tracker_init_run --repo-root "$TR_FLAGVAL" --backend github 2>&1 1>/dev/null) || true
assert_contains "1.2 missing --repo → validation" "$err" "--repo is required"

# 1.3 unsupported backend.
err=$(tracker_init_run --repo-root "$TR_FLAGVAL" --backend gitlab --repo x/y 2>&1 1>/dev/null) || true
assert_contains "1.3 backend 'gitlab' rejected at v11.0" "$err" "not supported at v11.0"
rm -rf "$TR_FLAGVAL"

# 1.4 surface auto-detection — pack root (pack-ops/ marker present per BD-175).
TR_PACK=$(mktemp -d -t tinit-pack.XXXXXX)
mkdir -p "$TR_PACK/pack-ops"
output=$(tracker_init_run --repo-root "$TR_PACK" --backend github --repo a/b --dry-run 2>&1)
assert_contains "1.4 auto-detects pack surface"   "$output" "surface:    pack"
assert_contains "1.4 default id-prefix BD"        "$output" "id-prefix:  BD"
rm -rf "$TR_PACK"

# 1.5 surface auto-detection — client (docs/pack present).
TR_CLI=$(mktemp -d -t tinit-cli.XXXXXX)
mkdir -p "$TR_CLI/docs/pack"
output=$(tracker_init_run --repo-root "$TR_CLI" --backend github --repo a/b --dry-run 2>&1)
assert_contains "1.5 auto-detects client surface" "$output" "surface:    client"
assert_contains "1.5 default id-prefix TD"        "$output" "id-prefix:  TD"
rm -rf "$TR_CLI"

# 1.6 surface auto-detection — neither marker → validation error.
TR_AMB=$(mktemp -d -t tinit-ambig.XXXXXX)
err=$(tracker_init_run --repo-root "$TR_AMB" --backend github --repo a/b 2>&1 1>/dev/null) || true
assert_contains "1.6 ambiguous → validation"      "$err" "cannot auto-detect surface"
rm -rf "$TR_AMB"

# 1.7 explicit --surface overrides auto-detection.
TR_OVR=$(mktemp -d -t tinit-ovr.XXXXXX)
mkdir -p "$TR_OVR/pack-ops"  # BD-175: pack surface marker
output=$(tracker_init_run --repo-root "$TR_OVR" --surface client --backend github --repo a/b --dry-run 2>&1)
assert_contains "1.7 explicit --surface client overrides pack-ops/ auto-detect" "$output" "surface:    client"
rm -rf "$TR_OVR"

# 1.8 --dry-run stops after plan.
TR_DRY=$(mktemp -d -t tinit-dry.XXXXXX)
mkdir -p "$TR_DRY/pack-ops"  # BD-175: pack surface marker
output=$(tracker_init_run --repo-root "$TR_DRY" --backend github --repo a/b --dry-run 2>&1)
rc=$?
assert_eq       "1.8 --dry-run rc=0"            "0" "$rc"
assert_contains "1.8 --dry-run stops after plan" "$output" "stopping after plan summary"
[[ ! -f "$TR_DRY/tracker.toml" ]] && t_pass "1.8 --dry-run writes no tracker.toml" \
    || t_fail "1.8 --dry-run writes no tracker.toml"
rm -rf "$TR_DRY"

# 1.9 unknown flag → validation error.
err=$(tracker_init_run --backend github --repo a/b --bogus 2>&1 1>/dev/null) || true
assert_contains "1.9 unknown flag → validation" "$err" "unknown option '--bogus'"

# 1.10 prior-state safety rail (F8): a tree with .pack-tracker/id-map.json
# rejects re-init absent --force, telling the user to run disable first.
TR_PRIOR=$(mktemp -d -t tr-prior.XXXXXX); mkdir -p "$TR_PRIOR/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_PRIOR/.pack-tracker"; echo '{}' > "$TR_PRIOR/.pack-tracker/id-map.json"
err=$(tracker_init_run --repo-root "$TR_PRIOR" --backend github --repo a/b --no-forward 2>&1 1>/dev/null) || true
assert_contains "1.10 prior id-map.json → validation"      "$err" "ERROR: validation"
assert_contains "1.10 message names prior tracker state"   "$err" "prior tracker state found"
assert_contains "1.10 message recommends disable or --force" "$err" "pack tracker disable"
# 1.10b --force bypasses the rail (still --dry-run so we don't touch the network).
output=$(tracker_init_run --repo-root "$TR_PRIOR" --surface pack --backend github --repo a/b --force --dry-run 2>&1)
assert_contains "1.10b --force bypasses the rail" "$output" "stopping after plan summary"
rm -rf "$TR_PRIOR"

# ─────────────────────────────────────────────────────────────────
# Group 2: auth validation (mocked gh)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: auth validation ===\n"

PATH_SAVED="$PATH"

# 2.1 gh exits non-zero → auth-missing.
FAKE_BIN_NA=$(mktemp -d -t tinit-na.XXXXXX)
cat > "$FAKE_BIN_NA/gh" <<'EOF'
#!/usr/bin/env bash
echo "You are not logged into any GitHub hosts." >&2
echo "Run: gh auth login" >&2
exit 1
EOF
chmod +x "$FAKE_BIN_NA/gh"

TR_NA=$(mktemp -d -t tinit-na-repo.XXXXXX)
mkdir -p "$TR_NA/pack-ops"  # BD-175: pack surface marker

export PATH="$FAKE_BIN_NA:$PATH_SAVED"
err=$(tracker_init_run --repo-root "$TR_NA" --backend github --repo a/b 2>&1 1>/dev/null) || true
export PATH="$PATH_SAVED"
assert_contains "2.1 gh exit≠0 → auth-missing typed code" "$err" "ERROR: auth-missing"
assert_contains "2.1 message includes gh stderr"          "$err" "not logged into"
rm -rf "$FAKE_BIN_NA" "$TR_NA"

# 2.2 gh exits 0 but no "Logged in to" line → auth-missing.
FAKE_BIN_NB=$(mktemp -d -t tinit-nb.XXXXXX)
cat > "$FAKE_BIN_NB/gh" <<'EOF'
#!/usr/bin/env bash
echo "Some unrelated output."
exit 0
EOF
chmod +x "$FAKE_BIN_NB/gh"

TR_NB=$(mktemp -d -t tinit-nb-repo.XXXXXX)
mkdir -p "$TR_NB/pack-ops"  # BD-175: pack surface marker

export PATH="$FAKE_BIN_NB:$PATH_SAVED"
err=$(tracker_init_run --repo-root "$TR_NB" --backend github --repo a/b 2>&1 1>/dev/null) || true
export PATH="$PATH_SAVED"
assert_contains "2.2 missing 'Logged in to' → auth-missing" "$err" "ERROR: auth-missing"
rm -rf "$FAKE_BIN_NB" "$TR_NB"

# ─────────────────────────────────────────────────────────────────
# Group 3: templates verification + happy-path init
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: templates verification + happy-path init ===\n"

# 3.1 missing issue templates → not-found typed code.
FAKE_BIN_TPL=$(mktemp -d -t tinit-tpl.XXXXXX)
cat > "$FAKE_BIN_TPL/gh" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
    "auth status") echo "Logged in to github.com"; exit 0 ;;
    "label list") echo "[]" ;;
    "label create") ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN_TPL/gh"

TR_NOTPL=$(mktemp -d -t tinit-notpl.XXXXXX)
mkdir -p "$TR_NOTPL/pack-ops"  # BD-175: pack surface marker
# No .github/ISSUE_TEMPLATE/ exists.

export PATH="$FAKE_BIN_TPL:$PATH_SAVED"
err=$(tracker_init_run --repo-root "$TR_NOTPL" --backend github --repo a/b --no-forward 2>&1 1>/dev/null) || true
export PATH="$PATH_SAVED"
assert_contains "3.1 missing templates → not-found"     "$err" "ERROR: not-found"
assert_contains "3.1 message names work-item.yml"       "$err" "work-item.yml"
rm -rf "$TR_NOTPL"

# 3.2 happy-path init with --no-forward (writes config, validates auth,
# verifies templates, ensures labels via mocked gh; skips forward).
TR_OK=$(mktemp -d -t tinit-ok.XXXXXX)
mkdir -p "$TR_OK/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_OK/.github/ISSUE_TEMPLATE"
touch "$TR_OK/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_OK/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_OK/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_TPL:$PATH_SAVED"
output=$(tracker_init_run --repo-root "$TR_OK" --backend github --repo DShaneNYC/x --no-forward 2>&1)
rc=$?
export PATH="$PATH_SAVED"
assert_eq       "3.2 happy-path rc=0"                 "0" "$rc"
assert_contains "3.2 reports tracker.toml written"    "$output" "tracker.toml written"
assert_contains "3.2 reports gh auth status OK"       "$output" "gh auth status OK"
assert_contains "3.2 reports templates present"       "$output" "issue templates present"
assert_contains "3.2 reports labels canonical=count"  "$output" "canonical="
assert_contains "3.2 reports --no-forward skip"       "$output" "skipping forward migration"

# 3.3 verify the written tracker.toml matches V1 §3.1 schema.
cfg="$TR_OK/tracker.toml"
[[ -f "$cfg" ]] || t_fail "3.3 tracker.toml exists" "missing"
assert_eq "3.3 schema_version=1"        "1"      "$(tracker_config_get "$cfg" schema_version)"
assert_eq "3.3 backend.name=github"     "github" "$(tracker_config_get "$cfg" backend.name)"
assert_eq "3.3 backend.repo correct"    "DShaneNYC/x" "$(tracker_config_get "$cfg" backend.repo)"
assert_eq "3.3 mode.state=tracker"      "tracker" "$(tracker_config_get "$cfg" mode.state)"
assert_eq "3.3 id_namespace.prefix=BD"  "BD"     "$(tracker_config_get "$cfg" id_namespace.prefix)"
assert_eq "3.3 mapping_file path"       ".pack-tracker/id-map.json" \
    "$(tracker_config_get "$cfg" migration.mapping_file)"

# 3.3b BD-204: pack-surface init writes NO [mirror] table. The pack
# surface has no monolith mirrors post-BD-203 (per-entry trees are the
# sole flat representation); validate-pack.py Check 29′ treats the
# absent table as a no-mirror surface.
if grep -q '^\[mirror\]' "$cfg"; then
    t_fail "3.3b pack-surface config omits [mirror] table" "found [mirror] in $cfg"
else
    t_pass "3.3b pack-surface config omits [mirror] table"
fi
if grep -qE 'location_backlog|location_status|location_changelog|regenerate_on_write' "$cfg"; then
    t_fail "3.3c pack-surface config has no mirror keys" "found a mirror key in $cfg"
else
    t_pass "3.3c pack-surface config has no mirror keys"
fi

# 3.4 opted_in_at persists across re-runs.
prior_opted_in=$(tracker_config_get "$cfg" mode.opted_in_at)
sleep 1   # ensure timestamp would change if we re-wrote it
export PATH="$FAKE_BIN_TPL:$PATH_SAVED"
tracker_init_run --repo-root "$TR_OK" --backend github --repo DShaneNYC/x --no-forward >/dev/null 2>&1
export PATH="$PATH_SAVED"
new_opted_in=$(tracker_config_get "$cfg" mode.opted_in_at)
assert_eq "3.4 opted_in_at preserved across re-runs" "$prior_opted_in" "$new_opted_in"

# 3.5 BD-206: client-surface init writes NO [mirror] table either — no
# surface keeps a monolith mirror (the per-entry tree + `_toc.md` is the
# sole SSOT and readable form). The client config matches the pack
# config's no-[mirror] shape.
TR_CLIOK=$(mktemp -d -t tinit-cliok.XXXXXX)
mkdir -p "$TR_CLIOK/docs/pack"  # client surface marker
mkdir -p "$TR_CLIOK/.github/ISSUE_TEMPLATE"
touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_TPL:$PATH_SAVED"
output=$(tracker_init_run --repo-root "$TR_CLIOK" --backend github --repo your-org/y --no-forward 2>&1)
rc=$?
export PATH="$PATH_SAVED"
assert_eq "3.5 client happy-path rc=0" "0" "$rc"
cfg_cli="$TR_CLIOK/docs/pack/tracker.toml"
[[ -f "$cfg_cli" ]] || t_fail "3.5 client tracker.toml exists at docs/pack/" "missing $cfg_cli"
if grep -q '^\[mirror\]' "$cfg_cli"; then
    t_fail "3.5 client-surface config omits [mirror] table" "found [mirror] in $cfg_cli"
else
    t_pass "3.5 client-surface config omits [mirror] table"
fi
if grep -qE 'location_backlog|location_status|location_changelog|regenerate_on_write' "$cfg_cli"; then
    t_fail "3.5 client-surface config omits mirror location keys" "found mirror key in $cfg_cli"
else
    t_pass "3.5 client-surface config omits mirror location keys"
fi
assert_eq "3.5 id_namespace.prefix=TD"   "TD"           "$(tracker_config_get "$cfg_cli" id_namespace.prefix)"
rm -rf "$TR_CLIOK"

rm -rf "$FAKE_BIN_TPL" "$TR_OK"

# ─────────────────────────────────────────────────────────────────
# Group 4: tracker_labels_canonical_set
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: label canonical set ===\n"

labels=$(tracker_labels_canonical_set)
n=$(printf '%s' "$labels" | wc -l | tr -d ' ')

# 4.1 sane upper-bound count (v11.0 set is ~45 labels).
assert_eq "4.1 canonical-set count >= 40" "1" "$([[ "$n" -ge 40 ]] && echo 1 || echo 0)"
assert_eq "4.1 canonical-set count <= 60" "1" "$([[ "$n" -le 60 ]] && echo 1 || echo 0)"

# 4.2 entry-type provenance family.
for fam in bd-entry td-entry phase-epic phase-task work-item inbound external pack-feedback needs-triage; do
    if printf '%s\n' "$labels" | grep -qFx "$fam"; then
        t_pass "4.2 has $fam"
    else
        t_fail "4.2 has $fam" "missing"
    fi
done

# 4.3 status family (V3.3 §6.3).
for s in status:open status:unblocked status:in-review status:resolved \
         status:cancelled status:deprecated status:pending status:in-progress \
         status:done status:deferred; do
    printf '%s\n' "$labels" | grep -qFx "$s" && t_pass "4.3 has $s" \
        || t_fail "4.3 has $s" "missing"
done

# 4.4 type family (METHODOLOGY § Part 7).
for t in type:feat type:fix type:refactor type:docs type:chore type:infra type:bug type:feature; do
    printf '%s\n' "$labels" | grep -qFx "$t" && t_pass "4.4 has $t" \
        || t_fail "4.4 has $t" "missing"
done

# 4.5 template-version family (V3.3 §6.5 D-18).
for tv in template:work-item-v11.0 template:inbound-v11.0 template:bd-v11.0 \
          template:td-v11.0 template:phase-epic-v11.0 template:phase-task-v11.0; do
    printf '%s\n' "$labels" | grep -qFx "$tv" && t_pass "4.5 has $tv" \
        || t_fail "4.5 has $tv" "missing"
done

# 4.6 pack-feedback subcategory family (V2 §4.3).
for pf in pf-category:workflow pf-category:prompt pf-category:agent-perf \
          pf-category:friction pf-category:open-question; do
    printf '%s\n' "$labels" | grep -qFx "$pf" && t_pass "4.6 has $pf" \
        || t_fail "4.6 has $pf" "missing"
done

# 4.7 NO open-string label-family members in the canonical set
# (derived-from:TD-NNN, promoted-to:phase-N, scope:phase-N specific
# numbers are created at promotion/derivation time, not init time).
if printf '%s\n' "$labels" | grep -qE "^(derived-from:TD-[0-9]|promoted-to:phase-[0-9]|scope:phase-[0-9])$"; then
    t_fail "4.7 canonical set excludes open-string members" "found a concrete derived-from/promoted-to/scope-phase-N entry"
else
    t_pass "4.7 canonical set excludes open-string members"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────
# Group 5: interactive dialogue (V1 §6.1 step 1)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: interactive dialogue ===\n"

# Setup: a fake gh that always returns auth-OK + empty labels (so
# init can run end-to-end with --no-forward).
FAKE_BIN_INT=$(mktemp -d -t tinit-int.XXXXXX)
cat > "$FAKE_BIN_INT/gh" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
    "auth status") echo "Logged in to github.com"; exit 0 ;;
    "label list")  echo "[]" ;;
    "label create") ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN_INT/gh"

# 5.1 prompt path: --backend and --repo missing, force interactive
# via env var, pipe answers via stdin. Surface auto-detected from
# pack-ops/ directory marker (BD-175).
TR_INT1=$(mktemp -d -t tinit-int1.XXXXXX)
mkdir -p "$TR_INT1/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_INT1/.github/ISSUE_TEMPLATE"
touch "$TR_INT1/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT1/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT1/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
# Pipe order: id-prefix (default BD), backend (default github), repo
export _TRACKER_INIT_FORCE_INTERACTIVE=1
output=$(printf 'BD\ngithub\nDShaneNYC/x\n' | \
    tracker_init_run --repo-root "$TR_INT1" --no-forward 2>&1)
rc=$?
export PATH="$PATH_SAVED"

assert_eq       "5.1 interactive happy-path rc=0"      "0" "$rc"
assert_contains "5.1 prompt 'ID prefix' visible"        "$output" "ID prefix"
assert_contains "5.1 prompt 'Backend' visible"          "$output" "Backend (github)"
assert_contains "5.1 prompt 'Repo slug' visible"        "$output" "Repo slug"
# tracker.toml written with the piped repo value.
assert_eq "5.1 backend.repo from prompt" "DShaneNYC/x" \
    "$(tracker_config_get "$TR_INT1/tracker.toml" backend.repo)"
rm -rf "$TR_INT1"

# 5.2 default-accept: blank lines accept the offered defaults.
TR_INT2=$(mktemp -d -t tinit-int2.XXXXXX)
mkdir -p "$TR_INT2/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_INT2/.github/ISSUE_TEMPLATE"
touch "$TR_INT2/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT2/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT2/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
# Empty answer for id-prefix → default BD
# Empty answer for backend → default github
# Repo answer (non-empty; required)
output=$(
    printf '\n\nDShaneNYC/y\n' | \
    tracker_init_run --repo-root "$TR_INT2" --no-forward 2>&1)
rc=$?
export PATH="$PATH_SAVED"

assert_eq "5.2 default-accept happy-path rc=0" "0" "$rc"
assert_eq "5.2 id-prefix defaulted to BD"  "BD"     "$(tracker_config_get "$TR_INT2/tracker.toml" id_namespace.prefix)"
assert_eq "5.2 backend defaulted to github" "github" "$(tracker_config_get "$TR_INT2/tracker.toml" backend.name)"
assert_eq "5.2 repo from prompt"           "DShaneNYC/y" "$(tracker_config_get "$TR_INT2/tracker.toml" backend.repo)"
rm -rf "$TR_INT2"

# 5.3 prompt path: empty repo answer → validation error.
TR_INT3=$(mktemp -d -t tinit-int3.XXXXXX)
mkdir -p "$TR_INT3/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_INT3/.github/ISSUE_TEMPLATE"
touch "$TR_INT3/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT3/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT3/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
# Pipe: id-prefix=BD, backend=github, repo=<empty>
err=$(
    printf 'BD\ngithub\n\n' | \
    tracker_init_run --repo-root "$TR_INT3" --no-forward 2>&1) || true
export PATH="$PATH_SAVED"
assert_contains "5.3 empty repo answer → validation" "$err" "ERROR: validation"
assert_contains "5.3 message names repo slug"        "$err" "repo slug is required"
rm -rf "$TR_INT3"

# 5.4 surface prompt: when both pack-ops/ and docs/pack/ absent (BD-175)
# AND interactive mode, prompt for surface.
TR_INT4=$(mktemp -d -t tinit-int4.XXXXXX)
mkdir -p "$TR_INT4/.github/ISSUE_TEMPLATE"
touch "$TR_INT4/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT4/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT4/.github/ISSUE_TEMPLATE/config.yml"
# No pack-ops/, no docs/pack/ (BD-175).

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
# Pipe: surface=pack, id-prefix=BD, backend=github, repo
output=$(
    printf 'pack\nBD\ngithub\nDShaneNYC/z\n' | \
    tracker_init_run --repo-root "$TR_INT4" --no-forward 2>&1)
rc=$?
export PATH="$PATH_SAVED"
assert_eq       "5.4 surface-prompt happy-path rc=0" "0" "$rc"
assert_contains "5.4 surface prompt visible"          "$output" "Surface (pack | client)"
rm -rf "$TR_INT4"

# 5.5 invalid surface answer → validation.
TR_INT5=$(mktemp -d -t tinit-int5.XXXXXX)
mkdir -p "$TR_INT5/.github/ISSUE_TEMPLATE"
touch "$TR_INT5/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT5/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT5/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
err=$(
    printf 'desktop\n' | \
    tracker_init_run --repo-root "$TR_INT5" --no-forward 2>&1) || true
export PATH="$PATH_SAVED"
assert_contains "5.5 invalid surface answer → validation" "$err" "ERROR: validation"
assert_contains "5.5 message names valid options"        "$err" "must be 'pack' or 'client'"
rm -rf "$TR_INT5"

# 5.6 --no-interactive disables prompts (regression: existing flag-only
# tests in Group 1 already exercise this implicitly because tests run
# in non-TTY context, but make the override explicit).
TR_INT6=$(mktemp -d -t tinit-int6.XXXXXX)
mkdir -p "$TR_INT6/pack-ops"  # BD-175: pack surface marker
err=$(
    tracker_init_run --repo-root "$TR_INT6" --no-interactive 2>&1) || true
assert_contains "5.6 --no-interactive overrides force flag → validation" "$err" "ERROR: validation"
assert_contains "5.6 still requires --backend"  "$err" "--backend is required"
rm -rf "$TR_INT6"

# 5.7 EOF on stdin (closed input) accepts default and proceeds.
TR_INT7=$(mktemp -d -t tinit-int7.XXXXXX)
mkdir -p "$TR_INT7/pack-ops"  # BD-175: pack surface marker
mkdir -p "$TR_INT7/.github/ISSUE_TEMPLATE"
touch "$TR_INT7/.github/ISSUE_TEMPLATE/work-item.yml"
touch "$TR_INT7/.github/ISSUE_TEMPLATE/inbound.yml"
touch "$TR_INT7/.github/ISSUE_TEMPLATE/config.yml"

export PATH="$FAKE_BIN_INT:$PATH_SAVED"
# /dev/null stdin → read returns rc=1 immediately → default accepted
# for all prompts. Repo has no default → validation error.
err=$(
    tracker_init_run --repo-root "$TR_INT7" --no-forward < /dev/null 2>&1) || true
export PATH="$PATH_SAVED"
assert_contains "5.7 EOF + empty-default repo → validation" "$err" "repo slug is required"
rm -rf "$TR_INT7"

rm -rf "$FAKE_BIN_INT"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
