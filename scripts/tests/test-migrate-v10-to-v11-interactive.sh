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

# BD-287 — seed a generic PROSE doc (docs/pack/PLATFORM-SKILLS.md, class
# `generic`, same path v10↔v11 so no relocation) into the target with a
# SAME-LINE customization that collides with the pack's own v10→v11 change,
# forcing a prose merged-with-markers row (class generic, action `merged`, a
# KEPT sidecar). The colliding line is discovered at RUNTIME (the first line
# that differs between the v10 baseline and the current pack template), so the
# fixture is robust to pack content drift. Writes docs/pack/PLATFORM-SKILLS.md.
seed_prose_conflict() {
    local target="$1" marker="$2"
    local rel="docs/pack/PLATFORM-SKILLS.md"
    local base theirs ln
    base="$target/.seed-base.$$"
    theirs="$REPO_ROOT/project-template/$rel"
    git -C "$REPO_ROOT" show "${V10_TAG:-v10}:project-template/$rel" > "$base" 2>/dev/null
    # First 1-based line number where BASE (v10) and THEIRS (pack v11) differ.
    ln=$(awk 'NR==FNR{a[FNR]=$0; n=FNR; next}
              {if ($0 != a[FNR]) {print FNR; f=1; exit}}
              END{if (!f) print n+1}' "$base" "$theirs")
    mkdir -p "$target/docs/pack"
    awk -v L="$ln" -v M="$marker" 'NR==L{print M; next}{print}' "$base" > "$target/$rel"
    rm -f "$base"
}

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
# BD-287 (F3/§2.2): a trinity conflict stashes CLAUDE.md.v10-base at dispatch;
# accept-pack on a trinity row clears it so no `.v10-base` clutter survives.
[[ ! -f "$T/CLAUDE.md.v10-base" ]] \
    && t_pass "I1.3b CLAUDE.md.v10-base cleared on accept (trinity stash cleanup)" \
    || t_fail "I1.3b CLAUDE.md.v10-base still present after accept"
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
# BD-287 (§2.2): keep-yours on a trinity row also clears the `.v10-base` stash.
[[ ! -f "$T/CLAUDE.md.v10-base" ]] \
    && t_pass "I2.3 CLAUDE.md.v10-base cleared on keep-yours (trinity stash cleanup)" \
    || t_fail "I2.3 CLAUDE.md.v10-base still present after keep-yours"
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
# BD-287 (§2.2): the trinity BASE stash is written at dispatch and a DEFER keeps
# it (only accept/keep/skill-fold clear it). Proves the stash exists to clear.
[[ -f "$T/CLAUDE.md.v10-base" ]] \
    && t_pass "I3.3b CLAUDE.md.v10-base present on defer (dispatch stash retained)" \
    || t_fail "I3.3b CLAUDE.md.v10-base missing on defer (stash not written)"
# BD-287: the .v10-base name does NOT match the *.v10-customized orphan glob, so
# it is invisible to Gate 2's checkpoint_check_no_orphan_sidecars.
[[ ! "CLAUDE.md.v10-base" == *".v10-customized" ]] \
    && t_pass "I3.3c .v10-base invisible to the *.v10-customized orphan-sidecar glob" \
    || t_fail "I3.3c .v10-base wrongly matches the orphan-sidecar glob"
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
# I11 — BD-287: prose merged-with-markers row. [1] accept RE-INSTALLS THEIRS
#       (F3, no markers remain); [3] defer leaves the markers (no in-bash merge)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I11: prose merged row → accept re-installs THEIRS / defer keeps markers ===\n"
PS_REL="docs/pack/PLATFORM-SKILLS.md"
MARKER_RE='^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)'
# (a) accept → re-install the clean pack template over the marked live file.
T=$(make_v10_target)
seed_prose_conflict "$T" "I11-PROSE-$$-accept"
commit_all "$T" "I11a prose conflict"
dry_run "$T"
out=$(printf '1\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I11a.1 accept merged-row rc=0 (auto-continue)" "0" "$rc"
[[ ! -f "$T/$PS_REL.v10-customized" ]] \
    && t_pass "I11a.2 sidecar removed (accept applied)" \
    || t_fail "I11a.2 sidecar still present after accept"
grep -qE "$MARKER_RE" "$T/$PS_REL" 2>/dev/null \
    && t_fail "I11a.3 live file STILL has conflict markers (THEIRS not re-installed)" \
    || t_pass "I11a.3 live file has NO conflict markers (accept re-installed clean pack template)"
if cmp -s "$T/$PS_REL" "$REPO_ROOT/project-template/$PS_REL"; then
    t_pass "I11a.4 live file byte-identical to pack v11 template (THEIRS re-installed)"
else
    t_fail "I11a.4 live file != pack v11 template (re-install wrong)"
fi
[[ ! -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I11a.5 NO stage-S3.paused (single conflict resolved → auto-continue)" \
    || t_fail "I11a.5 stage-S3.paused present (did not auto-continue / extra conflict)"
[[ -f "$T/$HELP_FRAGMENT_REL" ]] \
    && t_pass "I11a.6 HELP-FRAGMENT installed (S4/S5 ran)" \
    || t_fail "I11a.6 HELP-FRAGMENT missing"
rm -rf "$T"
# (b) defer (resolve-via-skill-later) → pause, markers UNTOUCHED (no in-bash
#     merge ran); the pause menu points at the skill + shows the cp-template
#     accept command (not a bare sidecar rm).
T=$(make_v10_target)
seed_prose_conflict "$T" "I11-PROSE-$$-defer"
commit_all "$T" "I11b prose conflict"
dry_run "$T"
out=$(printf '3\n' | PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply --interactive "$T" 2>&1) ; rc=$?
assert_eq "I11b.1 defer merged-row rc=0 (clean pause)" "0" "$rc"
[[ -f "$T/$PAUSED_SENTINEL_REL" ]] \
    && t_pass "I11b.2 stage-S3.paused present (deferred → pause)" \
    || t_fail "I11b.2 stage-S3.paused missing"
grep -qE "$MARKER_RE" "$T/$PS_REL" 2>/dev/null \
    && t_pass "I11b.3 deferred live file STILL has conflict markers (no in-bash merge ran)" \
    || t_fail "I11b.3 markers gone on defer (an in-bash merge wrongly ran)"
[[ -f "$T/$PS_REL.v10-customized" ]] \
    && t_pass "I11b.4 sidecar retained on defer" \
    || t_fail "I11b.4 sidecar removed on defer"
assert_contains "I11b.5 pause menu points at the resolve-merge-conflicts skill" \
    "$out" "resolve-merge-conflicts skill"
assert_contains "I11b.6 pause menu accept re-installs the pack template (cp project-template/...)" \
    "$out" "project-template/$PS_REL"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# I12 — BD-287: report needs-reconciliation 3-way split (class+action-keyed H3
#       sub-groups under one H2, each with the correct pointer prose)
# ─────────────────────────────────────────────────────────────────────────
printf "\n=== I12: report needs-reconciliation 3-way split ===\n"
T=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-rep.XXXXXX")
TSV="$T/dispositions.tsv"
{
  printf '# disposition\tclass\trel_path\taction\tsidecar\tdiff\tnotes\n'
  printf 'customization-detected-needs-reconciliation\tgeneric\tdocs/pack/FOO.md\tmerged\t%s/FOO.md.v10-customized\t-\tprose markers\n' "$T"
  printf 'customization-detected-needs-reconciliation\ttrinity\tCLAUDE.md\tsidecar\t%s/CLAUDE.md.v10-customized\t-\t-\n' "$T"
  printf 'customization-detected-needs-reconciliation\tpack-script\tscripts/foo.sh\tsidecar\t%s/scripts/foo.sh.v10-customized\t-\t-\n' "$T"
  printf 'customization-detected-needs-reconciliation\tpack-agent\t.claude/agents/bar.md\tsidecar\t%s/.claude/agents/bar.md.v10-customized\t-\t-\n' "$T"
  # BD-287 S1 regression: a STRUCTURED config key-merge with rc==2 records
  # action `merged` with a structured class (claude-settings), NOT a prose
  # class. It must render in the structured sub-group, NOT the prose
  # "conflict markers / run the skill" bucket.
  printf 'customization-detected-needs-reconciliation\tclaude-settings\t.claude/settings.json\tmerged\t%s/.claude/settings.json.v10-customized\t-\tstructured merge with reconciliation warnings\n' "$T"
} > "$TSV"
( . "$REPO_ROOT/scripts/lib/customization-report.sh"; \
  customization_report "$TSV" "$T/report.md" "v10 to v11 report" )
rep=$(cat "$T/report.md" 2>/dev/null)
assert_contains "I12.1 single H2 kept with total count 5" "$rep" "## Files needing manual reconciliation (5)"
assert_contains "I12.2 merged H3 sub-group"        "$rep" "### Auto-merged"
assert_contains "I12.3 trinity H3 sub-group"       "$rep" "### Trinity files"
assert_contains "I12.4 scripts/agents H3 sub-group" "$rep" "### Scripts and agents"
assert_contains "I12.5 prose/trinity point at the skill" "$rep" "resolve-merge-conflicts skill"
assert_contains "I12.6 trinity points at the pre-reconcile guide" "$rep" "pre-reconcile guide"
assert_contains "I12.7 scripts/agents: skill does not merge them" \
    "$rep" "does not merge executables/agents"
for rel in "docs/pack/FOO.md" "CLAUDE.md" "scripts/foo.sh" ".claude/agents/bar.md" ".claude/settings.json"; do
    assert_contains "I12.8 truthful: $rel present" "$rep" "$rel"
done
merged_ln=$(grep -n "### Auto-merged" "$T/report.md" | head -1 | cut -d: -f1)
trinity_ln=$(grep -n "### Trinity files" "$T/report.md" | head -1 | cut -d: -f1)
scripts_ln=$(grep -n "### Scripts and agents" "$T/report.md" | head -1 | cut -d: -f1)
if [[ -n "$merged_ln" && -n "$trinity_ln" && -n "$scripts_ln" \
      && "$merged_ln" -lt "$trinity_ln" && "$trinity_ln" -lt "$scripts_ln" ]]; then
    t_pass "I12.9 sub-groups render in stable order (merged < trinity < scripts)"
else
    t_fail "I12.9 sub-group order wrong" "merged=$merged_ln trinity=$trinity_ln scripts=$scripts_ln"
fi

# I12.10-I12.14 — BD-287 S1 regression: a STRUCTURED config `merged` row
# (`.claude/settings.json`, class claude-settings) must render in its OWN
# structured sub-group with key-merge/warnings prose — NOT in the prose
# "conflict markers / run the skill" bucket (that guidance is false for a
# JSON/TOML key-merge). Extract each H3 block and assert membership.
section_block() {
    awk -v h="$1" '
        index($0, "### " h) == 1 { grab=1; print; next }
        grab && (/^### / || /^## /) { grab=0 }
        grab { print }
    ' "$T/report.md"
}
automerged_block=$(section_block "Auto-merged")
structured_block=$(section_block "Structured configs")
assert_contains "I12.10 structured H3 sub-group present" "$rep" "### Structured configs"
assert_contains "I12.11 structured row lands in the structured sub-group" \
    "$structured_block" ".claude/settings.json"
assert_not_contains "I12.12 structured row NOT mislabeled into the prose/markers bucket" \
    "$automerged_block" ".claude/settings.json"
assert_not_contains "I12.13 structured group does NOT tell the user to run the skill" \
    "$structured_block" "run the resolve-merge-conflicts skill"
assert_not_contains "I12.14 structured group does NOT claim conflict markers exist" \
    "$structured_block" "carries conflict markers"
# The Auto-merged bucket still carries ONLY the prose row (no structured spill).
assert_contains "I12.15 prose Auto-merged bucket still holds the prose row" \
    "$automerged_block" "docs/pack/FOO.md"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
printf "\n=== interactive migration (BD-283): %s passed, %s failed ===\n" "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] && exit 0 || exit 1
