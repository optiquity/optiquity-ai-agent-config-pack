#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-interactive.sh — BD-283 fixture tests
# for the TURNKEY interactive reconciliation mode of the v10 → v11 migrator.
#
# These tests exercise the in-process prompt loop the migrator runs at a
# customization conflict (apply.sh `_v10_v11_apply_interactive_reconcile`).
# Interactive is forced via the PACK_PROMPT_FORCE_INTERACTIVE=1 test seam
# (prompt.sh) OR the `--interactive` flag; answers are piped on stdin. A
# conflict is forced with the Group-2c technique from
# test-migrate-v10-to-v11.sh: inject a unique line into a `## [CONDITIONAL]`
# body of a trinity file so the customization-preserve engine writes a
# `.v10-customized` sidecar + a `customization-detected-needs-reconciliation`
# disposition.
#
# CI wiring: this file lives at scripts/tests/ so it is AUTO-wired into the CI
# `tests` matrix by the BD-219 disk-derived glob (ci-shard-plan.py
# parse_wired_tests + validate-pack Check 42). There is NO per-test workflow
# list to edit. It is NOT in scripts/ci-test-wiring-allowlist.txt (it runs
# offline-deterministically: no `gh`, no network — Check 83 clean).
#
# Matrix (I1–I10; declare-verify-backing targets in parentheses):
#   I1  accept → auto-continue, honest report        (auto-continue + SHOULD-1)
#   I2  keep-yours → OURS restored                    (end-state, OI-5)
#   I3  merge-later → defer → --resume completes      (deferred path)
#   I4  skip → defer                                  (deferred path)
#   I5  accept then quit mid-loop → remainder deferred (SHOULD-4)
#   I6  EOF stdin → all deferred, no crash            (SHOULD-3 EOF lock)
#   I7  --no-interactive / non-TTY → byte-for-byte menu (non-interactive)
#   I8  TTY-auto seam (no flag) → interactive fires   (default auto-detect)
#   I9  bare turnkey (single process) → first answer consumed (SHOULD-2)
#   I10 full-visit partial-defer → pause + honest report (NIT-3 + SHOULD-1)
#
# bash-3.2 + BSD-utils safe. Uses `set -uo pipefail` (NOT -e) so assertions
# keep running after a failure. The migrator subprocess itself runs under
# `set -euo pipefail`, so an EOF/interactive-loop crash surfaces as a
# non-zero rc these tests catch.

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
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected NOT to contain '$3'"; fi
}

# Build a minimal v10-shaped target directory (identical fixture to
# test-migrate-v10-to-v11.sh make_v10_target): real v10-tag trinity content
# + one seeded shared v10 skill per per-CLI home. Working tree is clean.
make_v10_target() {
    local d cli
    d=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-int.XXXXXX")
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

# Inject a unique customization line into the FIRST `## [CONDITIONAL]` /
# `### [CONDITIONAL]` heading body of a trinity file, forcing a genuine
# needs-reconciliation conflict (base != ours for that optional section). The
# heading is discovered at runtime (never hard-coded). onetrueawk/gawk/mawk
# safe (no gensub / interval expressions).
inject_conditional_custom() {
    local target="$1" trinity="$2" marker="$3"
    awk -v cust="$marker" '
      BEGIN{ done=0 }
      { print }
      (!done && ($0 ~ /^## / || $0 ~ /^### /) && $0 ~ /\[CONDITIONAL\]/) { print cust; done=1 }
    ' "$target/$trinity" > "$target/$trinity.itmp" \
      && mv "$target/$trinity.itmp" "$target/$trinity"
}

commit_all() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m "$2" 2>/dev/null; }

# --dry-run stamps the fingerprint --apply requires. Two-phase drive: dry-run
# (non-interactive) THEN --apply --interactive with piped answers.
dry_run() { PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$1" >/dev/null 2>&1; }

# Count needs-reconciliation rows still in dispositions.tsv (post-prune).
recon_row_count() {
    awk -F'\t' '$1=="customization-detected-needs-reconciliation"{c++} END{print c+0}' \
        "$1" 2>/dev/null
}

# Print the "Files needing manual reconciliation" section of a report (from
# its H2 to the next H2), so content assertions are scoped, not whole-file.
report_recon_section() {
    awk '/^## Files needing manual reconciliation/{f=1; next} /^## /{f=0} f' "$1" 2>/dev/null
}

PAUSED_SENTINEL_REL=".pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
HELP_FRAGMENT_REL="docs/pack/HELP-FRAGMENT.md"
REPORT_REL=".pack-migrate-v10-to-v11/report.md"
DISPOSITIONS_REL=".pack-migrate-v10-to-v11/dispositions.tsv"

# ─────────────────────────────────────────────────────────────────────────
# I1 — accept → auto-continue (no --resume), honest report
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I1: accept → auto-continue (no --resume) ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I1-CUSTOM-$$-claude-accept"
commit_all "$T" "I1 customize CLAUDE"
dry_run "$T"
out=$(printf '1\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I1.1 accept rc=0 (clean auto-continue)" "0" "$rc"
[[ ! -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I1.2 NO stage-S3.paused (auto-continued, not paused)" \
    || t_fail "I1.2 stage-S3.paused present (did NOT auto-continue)"
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I1.3 CLAUDE.md.v10-customized removed (accept-pack applied in-process)" \
    || t_fail "I1.3 sidecar still present after accept"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I1.4 HELP-FRAGMENT installed (S4/S5 ran → auto-continue proven)" \
    || t_fail "I1.4 HELP-FRAGMENT missing (S4/S5 did not run)"
[[ -f "$T/$REPORT_REL" ]] \
    && t_pass "I1.5 report.md written (S6 ran)" \
    || t_fail "I1.5 report.md missing"
report=$(cat "$T/$REPORT_REL" 2>/dev/null)
assert_not_contains "I1.6 report has NO needs-reconciliation section (SHOULD-1 prune → honest)" \
    "$report" "Files needing manual reconciliation"
assert_eq "I1.7 dispositions.tsv has 0 needs-reconciliation rows (resolved+pruned)" \
    "0" "$(recon_row_count "$T/$DISPOSITIONS_REL")"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I2 — keep-yours → OURS restored (assert end-state, not gate-dependent rc)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I2: keep-yours (restore OURS) ===\n"
T=$(make_v10_target)
I2_MARKER="I2-CUSTOM-$$-claude-keepyours"
inject_conditional_custom "$T" CLAUDE.md "$I2_MARKER"
commit_all "$T" "I2 customize CLAUDE"
dry_run "$T"
# OI-5: keep-yours restores OURS over the v11 template; Gate 2 rc is NOT the
# contract here — the file end-state is. Do NOT assert rc.
out=$(printf '2\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I2.1 sidecar removed (keep-yours applied)" \
    || t_fail "I2.1 sidecar still present after keep-yours"
grep -q "$I2_MARKER" "$T/CLAUDE.md" 2>/dev/null \
    && t_pass "I2.2 live CLAUDE.md contains YOUR customization line (OURS restored over template)" \
    || t_fail "I2.2 live CLAUDE.md missing the restored customization"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I3 — merge-later → defer → --resume completes
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I3: merge-later → defer → --resume ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I3-CUSTOM-$$-claude-merge"
commit_all "$T" "I3 customize CLAUDE"
dry_run "$T"
out=$(printf '3\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I3.1 merge-later rc=0 (clean pause)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I3.2 stage-S3.paused present (deferred → pause)" \
    || t_fail "I3.2 stage-S3.paused missing (did NOT defer)"
grep -q "CLAUDE.md.v10-customized" "$T/$PAUSED_SENTINEL_REL" 2>/dev/null \
    && t_pass "I3.3 deferred sidecar listed in stage-S3.paused" \
    || t_fail "I3.3 deferred sidecar not listed"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I3.4 HELP-FRAGMENT NOT installed (paused before S4/S5)" \
    || t_fail "I3.4 HELP-FRAGMENT installed (pause not load-bearing)"
assert_contains "I3.5 pause prints the copy-paste menu (Migration paused)" "$out" "Migration paused"
# Resolve the deferred sidecar with the .resolved flag, then --resume.
touch "$T/CLAUDE.md.v10-customized.resolved"
out2=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc2=$?
assert_eq "I3.6 --resume after resolve rc=0" "0" "$rc2"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I3.7 HELP-FRAGMENT installed after --resume (S4–S6 completed)" \
    || t_fail "I3.7 HELP-FRAGMENT missing after --resume"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I4 — skip → defer (same deferred shape as I3)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I4: skip → defer ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I4-CUSTOM-$$-claude-skip"
commit_all "$T" "I4 customize CLAUDE"
dry_run "$T"
out=$(printf 's\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I4.1 skip rc=0 (clean pause)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I4.2 stage-S3.paused present (skip deferred)" \
    || t_fail "I4.2 stage-S3.paused missing"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I4.3 HELP-FRAGMENT NOT installed (paused)" \
    || t_fail "I4.3 HELP-FRAGMENT installed (skip did not defer)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I5 — accept then quit mid-loop → applied kept, remainder deferred (SHOULD-4)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I5: quit mid-loop (defer current + remainder) ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I5-CUSTOM-$$-claude"
inject_conditional_custom "$T" AGENTS.md "I5-CUSTOM-$$-agents"
commit_all "$T" "I5 customize CLAUDE + AGENTS"
dry_run "$T"
# stage-S3.paused order follows manifest order: CLAUDE (idx 0), AGENTS (idx 1).
# Answer 1 (accept CLAUDE), then q (quit at AGENTS → defer AGENTS + rest).
out=$(printf '1\nq\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I5.1 accept-then-quit rc=0 (clean pause)" "0" "$rc"
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I5.2 first conflict (CLAUDE) resolved before quit (applied choice kept)" \
    || t_fail "I5.2 CLAUDE sidecar still present (applied choice lost on quit)"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I5.3 stage-S3.paused present (quit deferred remainder)" \
    || t_fail "I5.3 stage-S3.paused missing"
grep -q "AGENTS.md.v10-customized" "$T/$PAUSED_SENTINEL_REL" 2>/dev/null \
    && t_pass "I5.4 UNVISITED AGENTS deferred in TRIMMED sentinel (SHOULD-4 current+remainder)" \
    || t_fail "I5.4 AGENTS not in trimmed stage-S3.paused (remainder dropped)"
grep -q "CLAUDE.md.v10-customized" "$T/$PAUSED_SENTINEL_REL" 2>/dev/null \
    && t_fail "I5.5 resolved CLAUDE wrongly still in trimmed sentinel" \
    || t_pass "I5.5 resolved CLAUDE trimmed OUT of stage-S3.paused"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I5.6 HELP-FRAGMENT NOT installed (S4/S5 withheld on partial defer)" \
    || t_fail "I5.6 HELP-FRAGMENT installed (auto-continued despite deferral)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I6 — EOF stdin → all deferred, no crash under set -euo pipefail (SHOULD-3)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I6: EOF stdin → all deferred, no crash ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I6-CUSTOM-$$-claude"
commit_all "$T" "I6 customize CLAUDE"
dry_run "$T"
# --interactive forces the loop; </dev/null gives prompt_choice an immediate
# EOF → rc!=0 → defer current+remainder (split-rc form). Must NOT crash.
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" </dev/null 2>&1) ; rc=$?
assert_eq "I6.1 EOF stdin rc=0 (no crash under set -euo pipefail; EOF-safe abort)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I6.2 stage-S3.paused present (EOF deferred all)" \
    || t_fail "I6.2 stage-S3.paused missing (EOF did not defer)"
[[ -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I6.3 sidecar untouched on EOF (no accidental accept/keep)" \
    || t_fail "I6.3 sidecar wrongly mutated on EOF"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I6.4 HELP-FRAGMENT NOT installed (EOF → pause, not auto-continue)" \
    || t_fail "I6.4 HELP-FRAGMENT installed (EOF wrongly auto-continued)"
assert_contains "I6.5 EOF falls back to copy-paste pause menu" "$out" "Migration paused"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I7 — non-interactive path byte-for-byte (a: --no-interactive; b: non-TTY)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I7: non-interactive byte-for-byte menu ===\n"
# (a) --no-interactive forces the menu even with the force-interactive seam
#     set (force_off wins in prompt_should_interact). The piped answer is
#     never consumed (the menu path reads no stdin).
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I7-CUSTOM-$$-claude"
commit_all "$T" "I7 customize CLAUDE"
dry_run "$T"
out=$(printf '1\n' | PACK="$REPO_ROOT" PACK_PROMPT_FORCE_INTERACTIVE=1 \
      bash "$MIGRATE_SH" --apply --no-interactive "$T" 2>&1) ; rc=$?
assert_eq "I7.1 --no-interactive rc=0 (force-off beats the interactive seam)" "0" "$rc"
assert_contains "I7.2 menu: 'Migration paused'"      "$out" "Migration paused"
assert_contains "I7.3 menu: 'requires attention'"    "$out" "requires attention"
assert_contains "I7.4 menu: 'Accept the pack'"       "$out" "Accept the pack"
assert_contains "I7.5 menu: per-sidecar keep-yours command (mv ')" "$out" "mv '"
assert_contains "I7.6 menu: .resolved merge command" "$out" ".resolved"
assert_contains "I7.7 menu: --resume finish command" "$out" "--resume"
assert_not_contains "I7.8 no interactive prompt echoed ('[1] accept pack')" \
    "$out" "[1] accept pack"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I7.9 stage-S3.paused present (non-interactive pause)" \
    || t_fail "I7.9 stage-S3.paused missing"
rm -rf "$T"
# (b) non-TTY default: no flag, no seam, stdin redirected from /dev/null →
#     prompt_should_interact TTY auto-detect is false → non-interactive.
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I7b-CUSTOM-$$-claude"
commit_all "$T" "I7b customize CLAUDE"
dry_run "$T"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" </dev/null 2>&1) ; rc=$?
assert_eq "I7.10 non-TTY default rc=0 (auto non-interactive)" "0" "$rc"
assert_contains "I7.11 non-TTY default prints copy-paste menu" "$out" "Migration paused"
assert_not_contains "I7.12 non-TTY default did NOT prompt" "$out" "[1] accept pack"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I7.13 non-TTY default paused (stage-S3.paused present)" \
    || t_fail "I7.13 non-TTY default did not pause"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I8 — TTY-auto seam (no flag) → interactive fires → auto-continue
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I8: TTY-auto seam (no flag) → interactive fires ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I8-CUSTOM-$$-claude"
commit_all "$T" "I8 customize CLAUDE"
dry_run "$T"
out=$(printf '1\n' | PACK="$REPO_ROOT" PACK_PROMPT_FORCE_INTERACTIVE=1 \
      bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
assert_eq "I8.1 no-flag + force-interactive seam accept rc=0 (auto-continue)" "0" "$rc"
assert_contains "I8.2 interactive prompt fired via seam ('[1] accept pack')" \
    "$out" "[1] accept pack"
[[ ! -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I8.3 NO stage-S3.paused (seam-driven interactive → auto-continue)" \
    || t_fail "I8.3 stage-S3.paused present (seam did not trigger interactive)"
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I8.4 sidecar removed (accept applied in seam-driven loop)" \
    || t_fail "I8.4 sidecar present (interactive did not fire)"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I8.5 HELP-FRAGMENT installed (auto-continue)" \
    || t_fail "I8.5 HELP-FRAGMENT missing"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I9 — bare turnkey (single-process dry-run→apply, piped answer) (SHOULD-2)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I9: bare turnkey (single process, first answer consumed) ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I9-CUSTOM-$$-claude"
commit_all "$T" "I9 customize CLAUDE"
# BARE invocation: NO mode flag → single process auto dry-run then apply. The
# dry-run reads NOTHING from fd 0, so the apply loop must consume the FIRST
# piped answer. If the dry-run consumed it, apply would EOF → defer → pause
# (sidecar present, HELP-FRAGMENT absent) and these assertions bite.
out=$(printf '1\n' | PACK="$REPO_ROOT" PACK_PROMPT_FORCE_INTERACTIVE=1 \
      bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "I9.1 bare turnkey accept rc=0 (auto-continue)" "0" "$rc"
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I9.2 apply loop consumed the FIRST piped answer (resolved, no dry-run offset)" \
    || t_fail "I9.2 sidecar present (dry-run consumed stdin → offset, or no auto-continue)"
[[ ! -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I9.3 NO stage-S3.paused (bare turnkey auto-continued)" \
    || t_fail "I9.3 stage-S3.paused present (bare turnkey paused)"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I9.4 HELP-FRAGMENT installed (S4/S5 ran in single process)" \
    || t_fail "I9.4 HELP-FRAGMENT missing"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I10 — full-visit partial-defer → pause + honest report (NIT-3 + SHOULD-1)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I10: full-visit partial-defer → pause + honest report ===\n"
T=$(make_v10_target)
inject_conditional_custom "$T" CLAUDE.md "I10-CUSTOM-$$-claude"
inject_conditional_custom "$T" AGENTS.md "I10-CUSTOM-$$-agents"
commit_all "$T" "I10 customize CLAUDE + AGENTS"
dry_run "$T"
# Visit BOTH (no quit): accept CLAUDE (1), merge-later AGENTS (3). Resolve-some
# + defer-some MUST pause (not auto-continue).
out=$(printf '1\n3\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I10.1 accept + merge-later (full visit) rc=0 (clean pause)" "0" "$rc"
[[ ! -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "I10.2 accepted CLAUDE sidecar removed" \
    || t_fail "I10.2 CLAUDE sidecar present"
grep -q "AGENTS.md.v10-customized" "$T/$PAUSED_SENTINEL_REL" 2>/dev/null \
    && t_pass "I10.3 deferred AGENTS in TRIMMED stage-S3.paused" \
    || t_fail "I10.3 AGENTS not in trimmed sentinel"
grep -q "CLAUDE.md.v10-customized" "$T/$PAUSED_SENTINEL_REL" 2>/dev/null \
    && t_fail "I10.4 resolved CLAUDE wrongly still in trimmed sentinel" \
    || t_pass "I10.4 resolved CLAUDE trimmed OUT of sentinel"
[[ ! -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I10.5 HELP-FRAGMENT NOT installed (partial defer → pause, not auto-continue)" \
    || t_fail "I10.5 HELP-FRAGMENT installed (wrongly auto-continued)"
# SHOULD-1 on the pause report: the needs-reconciliation section lists ONLY the
# deferred file. Directly assert the pruned dispositions.tsv too.
report=$(cat "$T/$REPORT_REL" 2>/dev/null)
assert_contains "I10.6 pause report has a needs-reconciliation section" \
    "$report" "Files needing manual reconciliation"
recon_section=$(report_recon_section "$T/$REPORT_REL")
assert_contains "I10.7 needs-reconciliation section lists the DEFERRED AGENTS.md" \
    "$recon_section" "AGENTS.md"
assert_not_contains "I10.8 needs-reconciliation section does NOT list RESOLVED CLAUDE.md (SHOULD-1)" \
    "$recon_section" "CLAUDE.md"
recon_files=$(awk -F'\t' '$1=="customization-detected-needs-reconciliation"{print $3}' \
    "$T/$DISPOSITIONS_REL" 2>/dev/null)
assert_contains "I10.9 dispositions.tsv keeps AGENTS.md needs-reconciliation row" \
    "$recon_files" "AGENTS.md"
assert_not_contains "I10.10 dispositions.tsv pruned CLAUDE.md needs-reconciliation row" \
    "$recon_files" "CLAUDE.md"
# --resume completes the deferred file.
touch "$T/AGENTS.md.v10-customized.resolved"
out2=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc2=$?
assert_eq "I10.11 --resume after resolving the deferred file rc=0" "0" "$rc2"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I10.12 HELP-FRAGMENT installed after --resume (S4–S6 completed)" \
    || t_fail "I10.12 HELP-FRAGMENT missing after --resume"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
printf "\n=== interactive migration (BD-283): %s passed, %s failed ===\n" "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] && exit 0 || exit 1
