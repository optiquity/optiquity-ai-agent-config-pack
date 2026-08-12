#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-pre-reconcile.sh — BD-286 demo test
# proving the shipped PRE-RECONCILE-v10-to-v11.md guide's CORE claim on a real
# v10→v11 migrator run: a trinity file that a client PRE-RECONCILES per the
# guide's recipe migrates PAUSE-FREE while KEEPING the customization, and a
# WRONG prep BITES (the pause is load-bearing, not luck).
#
# The prep recipe (from the guide, measured in ARCHITECTURE-BD286.md EEB-2):
#   (i)   reconcile the v10→v11 pack-section renames — delete from OURS every
#         `## ` section whose heading is ABSENT from the v11 template (drops the
#         `## [CONDITIONAL] …` sections + `## Project memory`), so the graft's
#         "absent from the new canonical" gate never fires;
#   (ii)  keep every out-of-marker pack body byte-identical to v10 BASE — not
#         even a stray blank line (the graft compares OURS↔BASE with markers
#         stripped, Regime A);
#   (iii) fold the customization strictly INSIDE a well-formed
#         `<!-- BEGIN project-owned --> … <!-- END project-owned -->` pair
#         (Shape A seed slot under `## Project addenda`).
# Satisfying (i)+(ii)+(iii) reaches disposition `merged-with-customization`
# (NO sidecar, NO pause) — this is the guide's declare-verify-backing proof.
#
# CI wiring: this file lives at scripts/tests/ so it is AUTO-wired into the CI
# `tests` matrix by the disk-derived glob (ci-shard-plan.py parse_wired_tests +
# validate-pack Check 42). There is NO per-test workflow list to edit. It builds
# its OWN /tmp target (not a built fixture), so it is NOT fixture-dependent and
# is NOT in scripts/ci-test-wiring-allowlist.txt (it runs offline-deterministic:
# no `gh`, no network — Check 83 clean).
#
# Matrix (declare-verify-backing targets in parentheses):
#   P1  prepared trinity (variant G)          → PAUSE-FREE, merged-with-customization
#                                               (the guide's core claim)
#   P2a stray out-of-marker blank (variant H) → BITES: pause, HELP-FRAGMENT absent
#                                               (byte-exact contract is load-bearing)
#   P2b unreconciled rename (variant A)       → BITES: pause, HELP-FRAGMENT absent
#                                               (rename reconciliation is load-bearing)
# P2 is the NEGATIVE control: it proves P1's clean result is CAUSED by the
# correct prep, not by luck.
#
# bash-3.2 + BSD-utils safe. Uses `set -uo pipefail` (NOT -e) so assertions keep
# running after a failure. The migrator subprocess runs under `set -euo
# pipefail`, so a crash surfaces as a non-zero rc these tests would catch.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATE_SH="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }
assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' got='$3'"; fi
}

# Build a minimal v10-shaped target directory (identical fixture to
# test-migrate-v10-to-v11{,-interactive}.sh make_v10_target): real v10-tag
# trinity content + one seeded shared v10 skill per per-CLI home. Clean tree.
make_v10_target() {
    local d cli
    d=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-prerecon.XXXXXX")
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"

    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.gemini"
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null

    for cli in .claude .codex .agents; do
        mkdir -p "$d/$cli/skills/c-language"
        git -C "$REPO_ROOT" show "${V10_TAG:-v10}:project-template/skills/c-language/SKILL.md" \
            > "$d/$cli/skills/c-language/SKILL.md" 2>/dev/null
    done

    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state" 2>/dev/null
    printf '%s\n' "$d"
}

commit_all() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m "$2" 2>/dev/null; }

# --dry-run stamps the fingerprint --apply requires (non-interactive).
dry_run() { PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$1" >/dev/null 2>&1; }

# ── prep building blocks (the guide's recipe, as executable steps) ───────────

# _delete_nonv11_sections <target> <trinity>
# Recipe step (i): remove from OURS every `## ` section whose heading is ABSENT
# from the v11 template's `## ` heading set. GENERIC — the v11 template drives
# the keep-set, so this reconciles the v10→v11 renames (drops `## [CONDITIONAL]
# …` + `## Project memory`) WITHOUT hard-coding those names, and stays robust to
# future trinity edits. onetrueawk/gawk/mawk safe (getline into a set + a keep
# flag; no gensub / interval expressions).
_delete_nonv11_sections() {
    local target="$1" trinity="$2"
    local src="$target/$trinity"
    local tpl="$REPO_ROOT/project-template/$trinity"
    local tmp="$src.prep.$$"
    awk -v tpl="$tpl" '
      BEGIN {
        while ((getline line < tpl) > 0)
          if (line ~ /^## /) keep[line] = 1
        close(tpl)
        emit = 1               # emit the preamble (before the first `## `)
      }
      /^## / { emit = ($0 in keep) ? 1 : 0 }
      emit   { print }
    ' "$src" > "$tmp" && mv "$tmp" "$src"
}

# _append_marker_fold <target> <trinity> <marker> <leading_blank(0|1)>
# Recipe step (iii): append a well-formed Shape A project-owned marker fold at
# EOF (v10 `## Project addenda` is the trailing section, so the fold lands
# inside it). leading_blank=1 inserts ONE stray OUT-OF-MARKER blank line before
# `<!-- BEGIN -->` — the variant-H bite that violates step (ii).
_append_marker_fold() {
    local target="$1" trinity="$2" marker="$3" leading_blank="$4"
    local src="$target/$trinity"
    [[ "$leading_blank" -eq 1 ]] && printf '\n' >> "$src"
    printf '<!-- BEGIN project-owned -->\n- Custom rule %s.\n<!-- END project-owned -->\n' \
        "$marker" >> "$src"
}

# prepare_trinity_clean <target> <trinity> <marker>
# The measured variant-G clean shape: reconcile renames (i) THEN fold into a
# well-formed marker pair with NO stray out-of-marker byte (ii)+(iii).
prepare_trinity_clean() {
    _delete_nonv11_sections "$1" "$2"
    _append_marker_fold "$1" "$2" "$3" 0
}

# Read the recorded disposition token for a trinity file from dispositions.tsv
# (col 1 = disposition, col 3 = project-relpath).
trinity_disposition() {
    awk -F'\t' -v f="$2" '$3==f{print $1}' "$1/$DISPOSITIONS_REL" 2>/dev/null
}

PAUSED_SENTINEL_REL=".pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
HELP_FRAGMENT_REL="docs/pack/HELP-FRAGMENT.md"
DISPOSITIONS_REL=".pack-migrate-v10-to-v11/dispositions.tsv"
DISP_MERGED="merged-with-customization"
DISP_NEEDS_RECON="customization-detected-needs-reconciliation"

# ─────────────────────────────────────────────────────────────────────────
# P1 — a prepared trinity migrates PAUSE-FREE, keeping the customization
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== P1: prepared trinity (variant G) → PAUSE-FREE + merged-with-customization ===\n"
T=$(make_v10_target)
P1_MARKER="PRE-RECONCILE-P1-$$"
prepare_trinity_clean "$T" CLAUDE.md "$P1_MARKER"
# AGENTS.md / GEMINI.md left RAW (markerless v10 → base==ours → pack-update-applied,
# no pause) — isolating the prepared CLAUDE.md as the variable under test.
commit_all "$T" "P1 pre-reconcile CLAUDE (clean graft)"
dry_run "$T"
# The full-completion process rc is NOT the contract here and is deliberately
# NOT asserted: it couples to the migrator's post-Phase-A verification gate
# (Gate 2), which is a separate concern from the pause-free MERGE this test
# proves. The load-bearing contract is the END-STATE below (no pause,
# HELP-FRAGMENT installed = S4/S5 ran to full completion, merged-with-
# customization, customization kept, v11 canonical adopted). Same design
# decision as test-migrate-v10-to-v11-interactive.sh case I2 ("Gate 2 rc is NOT
# the contract here — the file end-state is. Do NOT assert rc.").
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" </dev/null 2>&1) ; rc=$?
[[ ! -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "P1.1 NO stage-S3.paused (prepared trinity migrated pause-free)" \
    || t_fail "P1.1 stage-S3.paused present (prepared trinity still paused)"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "P1.2 HELP-FRAGMENT installed (S4/S5 ran → full completion)" \
    || t_fail "P1.2 HELP-FRAGMENT missing (migration did not complete)"
assert_eq "P1.3 CLAUDE.md disposition == merged-with-customization (not needs-reconciliation)" \
    "$DISP_MERGED" "$(trinity_disposition "$T" CLAUDE.md)"
grep -q "$P1_MARKER" "$T/CLAUDE.md" 2>/dev/null \
    && t_pass "P1.4 merged CLAUDE.md CONTAINS the customization marker (kept, not discarded)" \
    || t_fail "P1.4 merged CLAUDE.md missing the customization marker (customization lost)"
grep -q "^## Quick reference" "$T/CLAUDE.md" 2>/dev/null \
    && t_pass "P1.5 merged CLAUDE.md CONTAINS '## Quick reference' (v11 canonical adopted)" \
    || t_fail "P1.5 merged CLAUDE.md missing '## Quick reference' (v11 canonical not adopted)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# P2a — a stray out-of-marker blank line BITES (variant H)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== P2a: stray out-of-marker blank line (variant H) → BITES (pause) ===\n"
T=$(make_v10_target)
P2A_MARKER="PRE-RECONCILE-P2A-$$"
_delete_nonv11_sections "$T" CLAUDE.md          # renames reconciled …
_append_marker_fold "$T" CLAUDE.md "$P2A_MARKER" 1   # … but ONE stray blank line → bite
commit_all "$T" "P2a stray blank line before marker"
dry_run "$T"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" </dev/null 2>&1) ; rc=$?
assert_eq "P2a.1 apply rc=0 (clean pause, not a crash)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "P2a.2 stage-S3.paused present (one stray blank line paused the graft)" \
    || t_fail "P2a.2 stage-S3.paused missing (stray blank line did NOT bite)"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "P2a.3 HELP-FRAGMENT NOT installed (paused before S4/S5)" \
    || t_fail "P2a.3 HELP-FRAGMENT installed (pause not load-bearing)"
assert_eq "P2a.4 CLAUDE.md disposition == needs-reconciliation (byte-exact contract enforced)" \
    "$DISP_NEEDS_RECON" "$(trinity_disposition "$T" CLAUDE.md)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# P2b — an unreconciled rename BITES (variant A: `## [CONDITIONAL] …` kept)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== P2b: unreconciled rename (variant A) → BITES (pause) ===\n"
T=$(make_v10_target)
P2B_MARKER="PRE-RECONCILE-P2B-$$"
# SKIP the delete-renamed-headings step: leave the v10 `## [CONDITIONAL] …`
# sections in place; fold cleanly otherwise. The unreconciled rename bites the
# graft's "absent from the new canonical" gate (Step 6 regime reconciliation).
_append_marker_fold "$T" CLAUDE.md "$P2B_MARKER" 0
commit_all "$T" "P2b unreconciled rename (CONDITIONAL kept)"
dry_run "$T"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" </dev/null 2>&1) ; rc=$?
assert_eq "P2b.1 apply rc=0 (clean pause, not a crash)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "P2b.2 stage-S3.paused present (unreconciled rename paused the graft)" \
    || t_fail "P2b.2 stage-S3.paused missing (unreconciled rename did NOT bite)"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "P2b.3 HELP-FRAGMENT NOT installed (paused before S4/S5)" \
    || t_fail "P2b.3 HELP-FRAGMENT installed (pause not load-bearing)"
assert_eq "P2b.4 CLAUDE.md disposition == needs-reconciliation (rename reconciliation enforced)" \
    "$DISP_NEEDS_RECON" "$(trinity_disposition "$T" CLAUDE.md)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
printf "\n=== pre-reconcile migration (BD-286): %s passed, %s failed ===\n" "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] && exit 0 || exit 1
