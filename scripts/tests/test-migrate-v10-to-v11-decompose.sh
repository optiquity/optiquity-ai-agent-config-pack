#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-decompose.sh — BD-165 retroactive
# fix regression-guard test runner.
#
# Covers BD-165's net-new functional surface, which the pre-existing
# test runners (test-migrate-v10-to-v11.sh, *-dry-run.sh, *-gates.sh,
# test-per-entry.sh) do not exercise:
#
#   Group 1 — 6th sub-op presence + sequencing
#     1.1 --dry-run dry-run banner names the new BD-165 decompose step
#     1.2 --dry-run emits the BD-206 no-mirror post-report advisory
#         paragraph (per-entry tree + _toc.md is the sole source of
#         truth; no monolithic mirror is regenerated)
#
#   Group 2 — --apply happy path against a transient v10-shape fixture
#             with seeded docs/project/{BACKLOG,CHANGELOG}.md and the
#             UNDERSCORE-spelled docs/project/IMPLEMENTATION_PLAN.md
#             monolithic INPUT files (hazard shapes: section heads with
#             content, Context: on every TD, one out-of-enum payload,
#             one fenced `## ` line in a TD body, a mid-file # Milestone
#             H1 divider, a same-date same-phase changelog pair, phases
#             without Status:, one phase without Goal:)
#     2.1 --apply produces per-entry trees under
#         docs/project/{backlog,implementation-plan,changelog}/
#     2.2 --apply leaves NO monolithic file at
#         docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}
#         (BD-206 no-mirror model + Option-A deletion — the v10 monolith
#         is read as INPUT, decomposed, then DELETED after the per-entry
#         tree is verified written; only the per-entry tree + _toc.md
#         remain)
#     2.3 --apply emits the BD-206 no-mirror post-report advisory
#         paragraph (same assertions as 1.2)
#     2.4 --apply Gate 2 PASSES
#     2.5 --apply HEAD unchanged before/after (migrator does NOT commit)
#
#   Group 2b — accounting-gated pipeline + synthesis + MIGRATION-TRIAGE
#             (real helpers; same migrated tree as Group 2):
#     2b.1 D-1: underscore plan renamed at docs/project/ then decomposed
#     2b.2 D-4: implementation-plan/_index.md generated
#     2b.3 accounting gate PASS recorded per stream (state-dir verdicts)
#     2b.4 D-6: synthesized field lines present (incl. the out-of-enum
#          payload synthesized VERBATIM; Status:/Goal: NOT synthesized)
#     2b.5 D-6 insert-only: original monolith entry lines still present
#          verbatim in their entry files (TD, fenced-body TD, phase)
#     2b.6 D-7 end-to-end: the out-of-enum TD fails the SHIPPED
#          validate-docs payload leg AND is listed in TRIAGE manual-fill
#     2b.7 TRIAGE structure: From-sections == captures; both membership
#          maps with expected orderings; Synthesized-fields block ==
#          state-dir TSVs; suggestion table + machine-class rows
#     2b.8 D-2: the same-date same-phase pair yields TWO changelog files
#
#   Group 3 — fail-safe: the source monolith is deleted ONLY after a
#             successful decompose; a FAILED/partial decompose leaves it
#             intact. Driven at the sub-op level by sourcing the migrator
#             adapter's decompose.sh with STUBBED per-entry helpers so the
#             decompose / accounting / TOC / index outcome is
#             deterministic:
#     3.1 decompose failure → sub-op fail_stages; monolith INTACT
#     3.2 decompose OK but TOC-regenerate failure → fail_stage; INTACT
#     3.3 decompose+TOC "OK" but no _toc.md written (belt-and-suspenders
#         guard) → fail_stage; monolith INTACT
#     3.4 decompose+TOC OK and _toc.md present → monolith DELETED
#     3.5 accounting gate FAIL → fail_stage (S5d-accounting); delete
#         REFUSED; monolith INTACT
#
# Build-your-own fixture: the in-tree v10-realistic-ot build artifact
# (under test-fixtures/) does not have docs/project/*.md files (per
# IMPL-REPORT-BD-165 §7.2); this runner synthesizes the minimum v10-shape
# fixture with the requisite
# docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md content directly
# under /tmp. It is NOT fixture-dependent — it builds its own under /tmp.
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO
# `&>`, NO GNU-only flags.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATE_SH="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"
PE_LIB_DIR="$REPO_ROOT/scripts/lib/per-entry"

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

# ─────────────────────────────────────────────────────────────────────────
# Fixture builder
# ─────────────────────────────────────────────────────────────────────────
#
# Synthesizes a v10-shape target directory under /tmp with:
#   - Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md) sourced from v10 tag
#     so the BD-088 customization-preserve dispatch lands a clean unchanged-
#     pack path (no spurious sidecars).
#   - Minimal docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md
#     monolithic files with hand-authored entries so the BD-165 6th
#     sub-op (_v10_to_v11_decompose_streams) actually has content to
#     decompose.
#   - git init + initial commit so EXIT_DIRTY=12 preflight passes.
#
# Echoes the target absolute path on stdout.
make_v10_target_with_project_docs() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-bd165.XXXXXX")
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"

    mkdir -p "$d/.claude" "$d/docs/pack" "$d/docs/project" "$d/.codex" "$d/.gemini"
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null

    # docs/project/BACKLOG.md — hand-authored project backlog with 5
    # TD-NNN entries across TWO `## <section>` heads. Shape matches the
    # per-entry mirror grammar (intro + ## section + **TD-NNN — title**
    # bold-headers + `---` inter-entry separators) so the decompose
    # helper recognizes entries. Hazard shapes carried: section heads
    # with non-entry content (capture class), `Context:` on every TD,
    # ONE out-of-enum `Type:` payload (TD-004 — the D-7 carrier), and
    # ONE fenced code block with a `## ` line inside a TD body (TD-005).
    cat > "$d/docs/project/BACKLOG.md" <<'EOF'
# Project backlog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/backlog/`.

---

## Active

Entries in flight for the current milestone.

**TD-001 — Sample first project entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `app/Sources/Example.swift`
Description: Sample first project entry.
Context: Sample context for the first entry.

---

**TD-002 — Sample second project entry**
Type: TODO(version)
Status: Open
Blockers: TD-001
Unblocks: None
File/Symbol: `app/Sources/Other.swift`
Description: Sample second project entry depending on the first.
Context: Sample context for the second entry.

---

**TD-003 — Sample third project entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: TD-001
File/Symbol: `app/Sources/Third.swift`
Description: Sample third project entry resolved early.
Context: Sample context for the third entry.
Resolved: 2026-05-10 — sample resolution.

---

## Deferred

Entries parked until the next planning pass.

**TD-004 — Sample paperwork gap**
Type: KNOWN GAP(paperwork)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `app/Sources/Export.swift`
Description: Sample entry whose payload value is outside the enum.
Context: Sample context for the out-of-enum payload carrier.

---

**TD-005 — Sample fenced-heading entry**
Type: TODO(feature)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `app/scripts/notes.md`
Description: Sample entry with a fenced heading-like line in its body.
Context: The fenced block below is part of this entry's body.

```markdown
## Not a section — fenced sample heading
make sample
```
EOF

    # docs/project/IMPLEMENTATION_PLAN.md — UNDERSCORE spelling (the
    # D-1 carrier: the migrator's S4a docs/project/ location renames it
    # to IMPLEMENTATION-PLAN.md before the decompose sub-op reads it).
    # 2 phase-N.md entries carrying dependency fields for the synthesis
    # derivation, BOTH authored WITHOUT `Status:` and phase-2 WITHOUT
    # `Goal:`; a non-entry `## Sequencing notes` section carrying a
    # completion-checklist row for phase 1 (the Status suggestion
    # source); a `# Milestone` H1 divider mid-file between the phases.
    # The decompose parser anchors on `## Phase N — Title` H2 lines and
    # produces phase-N.md per-entry files.
    cat > "$d/docs/project/IMPLEMENTATION_PLAN.md" <<'EOF'
# Project implementation plan

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/implementation-plan/`.

---

## Sequencing notes

Build order tracks the completion checklist below.

| Phase | Deliverable | Build | Tests |
|---|---|---|---|
| Phase 1 | Initial scaffold | ✓ | ✓ |

---

## Phase 1 — Sample first phase

Goal: Stand up the initial scaffolding.
Prerequisite: none
Unblocks: phase-2

- Phase 1.1 — Initial repo setup
- Phase 1.2 — First feature scaffold

---

# Milestone 1 — Consolidation

Phases below this divider consolidate the feature set.

---

## Phase 2 — Sample second phase

Blockers: phase-1
Unblocks: none

- Phase 2.1 — Implement feature A
- Phase 2.2 — Implement feature B
EOF

    # docs/project/CHANGELOG.md — hand-authored project changelog with
    # 4 dated entries including a SAME-DATE SAME-PHASE pair with
    # distinct suffixes (the D-2 collision shape: under truncate-at-kind
    # naming both would map to 2026-04-29-phase-2.md; whole-suffix
    # naming yields two distinct files).
    cat > "$d/docs/project/CHANGELOG.md" <<'EOF'
# Project changelog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/changelog/`.

---

### 2026-04-15 — Phase 1 milestone

Initial scaffolding phase complete:
- Repo setup
- First feature scaffold

---

### 2026-04-22 — Phase 2 milestone

Feature implementation phase complete:
- Feature A
- Feature B

---

### 2026-04-29 — Phase 2 — Alpha notes

Alpha notes for the feature-implementation phase.

---

### 2026-04-29 — Phase 2 — Beta notes

Beta notes for the feature-implementation phase.
EOF

    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state + minimal docs/project/*.md" 2>/dev/null
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: 6th sub-op presence + sequencing (dry-run surface)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: 6th sub-op presence + sequencing ===\n"

T=$(make_v10_target_with_project_docs)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" 2>&1) ; rc=$?
assert_eq "1.0 setup --dry-run rc=0" "0" "$rc"
assert_contains "1.1 --dry-run banner names per-entry decompose" \
    "$out" "per-entry decompose"

# 1.2 — post-report advisory paragraph has the BD-206 no-mirror wording
# (per-entry tree + _toc.md is the sole source of truth; the v10 monolith
# is read as decomposition INPUT and is NOT regenerated as a mirror).
# The pre-BD-206 advisory described a regenerated mirror with a
# divergence-block (BLOCK + a non-zero gate exit + a flag-based override
# recovery); under the no-mirror model that entire narrative is gone, so
# the negative needles below assert the dead flag/wording are absent.
assert_contains "1.2a --dry-run advisory says 'sole source of truth'" \
    "$out" "sole source of truth"
assert_contains "1.2b --dry-run advisory states no monolithic mirror" \
    "$out" "no monolithic mirror under the v11 model"
# Negative: the removed mirror divergence-gate narrative must NOT be present.
assert_not_contains "1.2c --dry-run advisory does NOT name --force-overwrite-mirror (removed, BD-206)" \
    "$out" "force-overwrite-mirror"
assert_not_contains "1.2d --dry-run advisory does NOT have mirror divergence-block 'will BLOCK' wording (removed, BD-206)" \
    "$out" "will BLOCK"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: --apply happy path against fixture with docs/project/*.md
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: --apply happy path with project docs ===\n"

T=$(make_v10_target_with_project_docs)
HEAD_BEFORE=$(git -C "$T" rev-parse HEAD)

# Pre-apply snapshots for the Group 2b insert-only assertions (the
# migrator deletes the monoliths after decompose).
BL_SNAP=$(mktemp "${TMPDIR:-/tmp}/migrate10-bd291-bl.XXXXXX")
PL_SNAP=$(mktemp "${TMPDIR:-/tmp}/migrate10-bd291-pl.XXXXXX")
cp "$T/docs/project/BACKLOG.md" "$BL_SNAP"
cp "$T/docs/project/IMPLEMENTATION_PLAN.md" "$PL_SNAP"

# Run --dry-run first (--apply requires fresh fingerprint).
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1 ; rc=$?
assert_eq "2.0a setup --dry-run rc=0" "0" "$rc"

# --apply: plain (no divergence-override flag — removed in BD-206).
# Under the no-mirror model the decompose sub-op reads the v10 monolith
# as INPUT and regenerates only the per-entry tree + _toc.md; it never
# regenerates a mirror, so there is no divergence to block and no flag
# to acknowledge.
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
assert_eq "2.0b --apply rc=0 (no-mirror model; no flag)" "0" "$rc"

# 2.1 — per-entry trees produced under docs/project/<stream>/.
[[ -f "$T/docs/project/backlog/TD-001.md" ]] \
    && t_pass "2.1a per-entry backlog TD-001.md exists" \
    || t_fail "2.1a per-entry backlog TD-001.md missing"
[[ -f "$T/docs/project/backlog/TD-002.md" ]] \
    && t_pass "2.1b per-entry backlog TD-002.md exists" \
    || t_fail "2.1b per-entry backlog TD-002.md missing"
[[ -f "$T/docs/project/backlog/TD-003.md" ]] \
    && t_pass "2.1c per-entry backlog TD-003.md exists" \
    || t_fail "2.1c per-entry backlog TD-003.md missing"
[[ -f "$T/docs/project/implementation-plan/phase-1.md" ]] \
    && t_pass "2.1d per-entry implementation-plan phase-1.md exists" \
    || t_fail "2.1d per-entry implementation-plan phase-1.md missing"
[[ -f "$T/docs/project/implementation-plan/phase-2.md" ]] \
    && t_pass "2.1e per-entry implementation-plan phase-2.md exists" \
    || t_fail "2.1e per-entry implementation-plan phase-2.md missing"
[[ -f "$T/docs/project/changelog/2026-04-15-phase-1-milestone.md" ]] \
    && t_pass "2.1f per-entry changelog 2026-04-15-phase-1-milestone.md exists" \
    || t_fail "2.1f per-entry changelog 2026-04-15-phase-1-milestone.md missing"

# 2.2 — NO monolithic file at docs/project/ post-migration (BD-206
# no-mirror model + Option-A deletion). The per-entry tree + generated
# _toc.md is the sole source of truth + readable form; the decompose
# sub-op regenerates only the _toc.md index (never a mirror) and DELETES
# the v10 monolith INPUT after the per-entry tree is verified written, so
# no stale orphan monolith survives that the docs say no longer exists.
[[ -f "$T/docs/project/backlog/_toc.md" ]] \
    && t_pass "2.2a backlog/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2a backlog/_toc.md missing"
[[ -f "$T/docs/project/implementation-plan/_toc.md" ]] \
    && t_pass "2.2b implementation-plan/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2b implementation-plan/_toc.md missing"
[[ -f "$T/docs/project/changelog/_toc.md" ]] \
    && t_pass "2.2c changelog/_toc.md regenerated (no-mirror readable form)" \
    || t_fail "2.2c changelog/_toc.md missing"
# 2.2d — the v10 monolith INPUT files are DELETED after a successful
# decompose (Option A). All three project-side streams' monoliths must be
# gone; the per-entry tree + _toc.md is now the sole source of truth.
del_ok=1
for _mono in BACKLOG.md IMPLEMENTATION-PLAN.md CHANGELOG.md; do
    [[ -e "$T/docs/project/$_mono" ]] && del_ok=0
done
if [[ "$del_ok" -eq 1 ]]; then
    t_pass "2.2d v10 monoliths (BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG.md) DELETED after successful decompose"
else
    still=$(ls "$T/docs/project/"*.md 2>/dev/null | tr '\n' ' ')
    t_fail "2.2d v10 monolith(s) NOT deleted after decompose" "still present: $still"
fi
# 2.2e — no stray monolith left inside a stream subdir either.
stray_ok=1
for _spec in "BACKLOG.md|backlog" "IMPLEMENTATION-PLAN.md|implementation-plan" "CHANGELOG.md|changelog"; do
    _m="${_spec%%|*}"; _d="${_spec##*|}"
    [[ -e "$T/docs/project/$_d/$_m" ]] && stray_ok=0
done
[[ "$stray_ok" -eq 1 ]] \
    && t_pass "2.2e no stray monolith inside any stream subdir" \
    || t_fail "2.2e stray monolith found inside a stream subdir"

# 2.3 — post-report advisory paragraph has the BD-206 no-mirror wording.
assert_contains "2.3a --apply advisory says 'sole source of truth'" \
    "$out" "sole source of truth"
assert_contains "2.3b --apply advisory states no monolithic mirror" \
    "$out" "no monolithic mirror under the v11 model"
assert_not_contains "2.3c --apply advisory does NOT name --force-overwrite-mirror (removed, BD-206)" \
    "$out" "force-overwrite-mirror"
assert_not_contains "2.3d --apply advisory does NOT have mirror divergence-block 'will BLOCK' wording (removed, BD-206)" \
    "$out" "will BLOCK"

# 2.4 — Gate 2 PASS appears in the run output.
assert_contains "2.4 --apply Gate 2 PASS in output" "$out" "Gate 2 PASS"

# 2.5 — HEAD unchanged (migrator does NOT commit).
HEAD_AFTER=$(git -C "$T" rev-parse HEAD)
assert_eq "2.5 HEAD unchanged after --apply (migrator never commits)" \
    "$HEAD_BEFORE" "$HEAD_AFTER"

# ─────────────────────────────────────────────────────────────────────────
# Group 2b: accounting-gated pipeline + synthesis + TRIAGE (real helpers;
# asserts against the SAME migrated tree Group 2 produced)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2b: accounting-gated pipeline + synthesis + TRIAGE ===\n"

STATE="$T/.pack-migrate-v10-to-v11"
TRIAGE_PATH="$T/docs/project/MIGRATION-TRIAGE.md"

# 2b.1 (D-1) — underscore plan renamed at docs/project/, then decomposed.
assert_contains "2b.1a S4a renamed the underscore plan at docs/project/" \
    "$out" "renamed: docs/project/IMPLEMENTATION_PLAN.md → docs/project/IMPLEMENTATION-PLAN.md"
[[ ! -e "$T/docs/project/IMPLEMENTATION_PLAN.md" ]] \
    && t_pass "2b.1b underscore plan absent post-migrate" \
    || t_fail "2b.1b underscore plan still present"
[[ -f "$T/docs/project/implementation-plan/phase-2.md" ]] \
    && t_pass "2b.1c renamed plan decomposed (phase-2.md present)" \
    || t_fail "2b.1c phase-2.md missing (rename → decompose chain broken)"

# 2b.2 (D-4) — ordering index generated for the implementation-plan stream.
[[ -f "$T/docs/project/implementation-plan/_index.md" ]] \
    && t_pass "2b.2 implementation-plan/_index.md generated" \
    || t_fail "2b.2 implementation-plan/_index.md missing"

# 2b.3 — accounting gate PASS recorded per stream in the state dir.
acct_ok=1
for _k in project-backlog project-implementation-plan project-changelog; do
    grep -q "^${_k}"$'\t'"PASS"$'\t' "$STATE/accounting-verdicts.txt" 2>/dev/null \
        || acct_ok=0
done
[[ "$acct_ok" -eq 1 ]] \
    && t_pass "2b.3 accounting verdicts: PASS recorded for all three streams" \
    || t_fail "2b.3 accounting verdicts incomplete" \
        "$(cat "$STATE/accounting-verdicts.txt" 2>/dev/null)"

# 2b.4 (D-6) — synthesized field lines present; absent-by-design fields
# NOT synthesized; the out-of-enum payload synthesized VERBATIM.
td1=$(cat "$T/docs/project/backlog/TD-001.md")
assert_contains "2b.4a TD-001 Entry-Type synthesized" "$td1" "- **Entry-Type**: td"
assert_contains "2b.4b TD-001 ID synthesized" "$td1" "- **ID**: TD-001"
assert_contains "2b.4c TD-001 Marker synthesized" "$td1" "- **Marker**: TODO"
assert_contains "2b.4d TD-001 Scope payload synthesized verbatim" "$td1" "- **Scope**: version"
ph2=$(cat "$T/docs/project/implementation-plan/phase-2.md")
assert_contains "2b.4e phase-2 Entry-Type synthesized" "$ph2" "- **Entry-Type**: phase-epic"
assert_contains "2b.4f phase-2 ID synthesized" "$ph2" "- **ID**: phase-2"
assert_contains "2b.4g phase-2 Blockers derived from the dependency grammar" "$ph2" "- **Blockers**: phase-1"
td4=$(cat "$T/docs/project/backlog/TD-004.md")
assert_contains "2b.4h TD-004 out-of-enum payload synthesized VERBATIM" "$td4" "- **Severity**: paperwork"
assert_not_contains "2b.4i phase-2 Status NOT synthesized (OI-A3)" "$ph2" "Status"
assert_not_contains "2b.4j phase-2 Goal NOT synthesized (OI-A3)" "$ph2" "Goal"

# 2b.5 (D-6 insert-only) — every nonblank non-separator line of the
# original monolith entry span is still present VERBATIM in its entry
# file. Covered spans: TD-001 (fields), TD-005 (fenced `## ` body), and
# phase-1 (dependency fields).
assert_span_preserved() {
    # $1=snapshot $2=start-regex $3=end-regex ('' = EOF) $4=entry-file $5=label
    local ok=1 line="" bad=""
    while IFS= read -r line; do
        [[ -z "${line// }" ]] && continue
        [[ "$line" == "---" ]] && continue
        if ! grep -qxF -- "$line" "$4"; then ok=0; bad="$line"; fi
    done < <(awk -v s="$2" -v e="$3" \
        '$0 ~ s {f=1; print; next} f && e != "" && $0 ~ e {exit} f {print}' "$1")
    [[ "$ok" -eq 1 ]] \
        && t_pass "$5" \
        || t_fail "$5" "original line lost/mutated: $bad"
}
assert_span_preserved "$BL_SNAP" '^\*\*TD-001 — ' '^\*\*TD-002 — ' \
    "$T/docs/project/backlog/TD-001.md" \
    "2b.5a TD-001 span preserved verbatim (insert-only)"
assert_span_preserved "$BL_SNAP" '^\*\*TD-005 — ' '' \
    "$T/docs/project/backlog/TD-005.md" \
    "2b.5b TD-005 span (incl. fenced ## line) preserved verbatim"
assert_span_preserved "$PL_SNAP" '^## Phase 1 — ' '^# Milestone 1' \
    "$T/docs/project/implementation-plan/phase-1.md" \
    "2b.5c phase-1 span preserved verbatim (insert-only)"

# 2b.6 (D-7 end-to-end) — the SHIPPED validator (the installed client
# copy; it resolves its root from its own path) fails the out-of-enum
# payload via the payload-enum leg, and TRIAGE manual-fill declares it.
vout=$(bash "$T/scripts/validate-docs.sh" 2>&1); vrc=$?
[[ "$vrc" -ne 0 ]] \
    && t_pass "2b.6a shipped validate-docs exits non-zero on the migrated tree" \
    || t_fail "2b.6a shipped validate-docs unexpectedly clean (payload leg dead?)"
assert_contains "2b.6b validator names the out-of-enum Severity" \
    "$vout" "Severity 'paperwork' not in"
assert_contains "2b.6c validator names TD-004" "$vout" "TD-004"
# The fully-synthesized in-enum TD draws ZERO validator failures — the
# synthesized field-line byte shape parses through the shipped
# validator's own field grammar (schema-conformance green).
assert_not_contains "2b.6c2 validator finds NO failure on the fully-synthesized TD-001" \
    "$vout" "TD-001"
triage=$(cat "$TRIAGE_PATH" 2>/dev/null)
assert_contains "2b.6d TRIAGE manual-fill lists the TD-004 payload" \
    "$triage" "backlog/TD-004.md — Severity: paperwork"
assert_contains "2b.6e TRIAGE machine row for the TD-004 payload class" \
    "$triage" "$(printf 'backlog/TD-004.md\tpayload-out-of-enum:Severity=paperwork')"

# 2b.7 — TRIAGE structure.
[[ -f "$TRIAGE_PATH" ]] \
    && t_pass "2b.7a MIGRATION-TRIAGE.md assembled" \
    || t_fail "2b.7a MIGRATION-TRIAGE.md missing"

# From-sections equal the state-dir captures byte-for-byte (modulo the
# section headers + blank-edge framing).
extract_triage_section() {  # $1=file $2=exact-start-header $3=exact-next-header
    awk -v s="$2" -v e="$3" \
        '$0 == s {f=1; next} f && $0 == e {exit} f {print}' "$1"
}
trim_blank_edges() {
    awk 'NF {if (!s) s=1} s {buf[++n]=$0; if (NF) last=n}
         END {for (i=1; i<=last; i++) print buf[i]}'
}
for _spec in \
    "project-backlog|## From BACKLOG.md|## From IMPLEMENTATION-PLAN.md" \
    "project-implementation-plan|## From IMPLEMENTATION-PLAN.md|## From CHANGELOG.md" \
    "project-changelog|## From CHANGELOG.md|## Derived: section membership"; do
    _k="${_spec%%|*}"
    _rest="${_spec#*|}"
    _s="${_rest%%|*}"
    _e="${_rest##*|}"
    if diff -q \
        <(extract_triage_section "$TRIAGE_PATH" "$_s" "$_e" | trim_blank_edges) \
        <(trim_blank_edges < "$STATE/dropped-$_k.md") >/dev/null 2>&1; then
        t_pass "2b.7b '$_s' section equals the $_k capture verbatim"
    else
        t_fail "2b.7b '$_s' section diverges from the $_k capture"
    fi
done

# Membership maps with the expected orderings.
assert_contains "2b.7c section membership: Active ordered" \
    "$triage" "- Active: TD-001, TD-002, TD-003"
assert_contains "2b.7d section membership: Deferred ordered" \
    "$triage" "- Deferred: TD-004, TD-005"
assert_contains "2b.7e milestone membership ordered" \
    "$triage" "- Milestone 1 — Consolidation: phase-2"

# Synthesized-fields fenced block equals the state-dir TSVs (stream order).
if diff -q \
    <(awk '$0 == "## Synthesized fields" {f=1; next}
           f && $0 == "```" {if (g) exit; g=1; next}
           f && g {print}' "$TRIAGE_PATH") \
    <(cat "$STATE/synthesized-project-backlog.tsv" \
          "$STATE/synthesized-project-implementation-plan.tsv") >/dev/null 2>&1; then
    t_pass "2b.7f Synthesized-fields block equals the state-dir TSV record"
else
    t_fail "2b.7f Synthesized-fields block diverges from the state-dir TSVs"
fi

# Manual-fill: suggestion table + machine-class rows.
assert_contains "2b.7g phase-1 Status suggestion from the checklist row" \
    "$triage" "| implementation-plan/phase-1.md | done | completion-checklist row (suggestion — review before applying) |"
assert_contains "2b.7h phase-2 no-suggestion-source row" \
    "$triage" "| implementation-plan/phase-2.md | — | no suggestion source |"
assert_contains "2b.7i machine row: phase-1 missing-status" \
    "$triage" "$(printf 'implementation-plan/phase-1.md\tmissing-status')"
assert_contains "2b.7j machine row: phase-2 missing-status" \
    "$triage" "$(printf 'implementation-plan/phase-2.md\tmissing-status')"
assert_contains "2b.7k machine row: phase-2 missing-goal" \
    "$triage" "$(printf 'implementation-plan/phase-2.md\tmissing-goal')"
assert_contains "2b.7l Goal-missing human list names phase-2" \
    "$triage" "- implementation-plan/phase-2.md"

# 2b.8 (D-2) — the same-date same-phase pair produced TWO files.
if [[ -f "$T/docs/project/changelog/2026-04-29-phase-2-alpha-notes.md" \
   && -f "$T/docs/project/changelog/2026-04-29-phase-2-beta-notes.md" ]]; then
    t_pass "2b.8 same-date same-phase pair → two distinct changelog files"
else
    t_fail "2b.8 same-date same-phase pair did not yield two files" \
        "$(ls "$T/docs/project/changelog/" 2>/dev/null | tr '\n' ' ')"
fi

rm -f "$BL_SNAP" "$PL_SNAP"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: fail-safe — delete ONLY after a successful decompose
# ─────────────────────────────────────────────────────────────────────────
#
# The Option-A deletion MUST be fail-safe: the v10 source monolith is
# removed only after its per-entry decomposition is verified written; a
# failed / partial decompose leaves it intact (never destroy client data
# with no per-entry backing).
#
# We drive the migrator adapter's 6th sub-op
# (`_v10_to_v11_decompose_streams`, defined in
# scripts/lib/migrate-v10-to-v11/decompose.sh) directly, with STUBBED
# per-entry helpers so the decompose / TOC-regenerate outcome is
# deterministic. Pre-defining `pe_die` / `per_entry_decompose` /
# `per_entry_regenerate_toc` before sourcing the adapter satisfies the
# adapter's `type`-guarded source lines, so the real BD-164 helpers are
# NOT loaded and our stubs govern the outcome. `fail_stage` is stubbed to
# exit non-zero (matching the real fail_stage's abort semantics), so a
# failing sub-op is caught by running it in a subshell.

printf "\n=== Group 3: fail-safe (delete only after successful decompose) ===\n"

# ── Stubs (defined BEFORE sourcing the adapter) ──
pe_die() { printf 'per-entry: ERROR: %s\n' "$*" >&2; exit 1; }
# $1=key $2=mono_path $3=stream_dir. Returns the scenario-selected rc.
per_entry_decompose() { return "${STUB_DECOMPOSE_RC:-0}"; }
# $1=key $2=stream_dir. Optionally writes _toc.md, then returns the rc.
per_entry_regenerate_toc() {
    if [[ "${STUB_TOC_WRITE:-1}" == "1" ]]; then : > "$2/_toc.md"; fi
    return "${STUB_TOC_RC:-0}"
}
# $1..$5=accounting args. Returns the scenario-selected gate verdict rc.
per_entry_accounting_check() { return "${STUB_ACCT_RC:-0}"; }
# $1=key $2=stream_dir. Optionally writes _index.md, then returns the rc.
per_entry_regenerate_index() {
    if [[ "${STUB_INDEX_WRITE:-1}" == "1" ]]; then : > "$2/_index.md"; fi
    return "${STUB_INDEX_RC:-0}"
}
# Minimal adapter-context stand-ins.
say()  { printf '%s\n' "$*"; }
info() { printf '%s\n' "$*"; }
# Real fail_stage exits with a stage-derived non-zero code; the test only
# needs a non-zero exit to prove the sub-op aborted before deleting.
fail_stage() { printf 'error: stage %s failed: %s\n' "$1" "$2" >&2; exit 90; }

# Source the adapter — its `type`-guarded source lines now find our stubs
# and skip the real helpers; it defines `_v10_to_v11_decompose_streams`.
# shellcheck disable=SC1091
. "$REPO_ROOT/scripts/lib/migrate-v10-to-v11/decompose.sh"
if ! type _v10_to_v11_decompose_streams >/dev/null 2>&1; then
    t_fail "3.0 adapter sourced; _v10_to_v11_decompose_streams defined" \
        "function not defined after sourcing decompose.sh"
else
    t_pass "3.0 adapter sourced; _v10_to_v11_decompose_streams defined"
fi

# Minimal scratch target: 3 monoliths + 3 stream dirs + a state dir for
# the pipeline's captures/records/verdicts (no git needed — the sub-op
# only reads _MIGRATOR_TARGET + _MIGRATOR_STATE_DIR + the filesystem).
make_streams_scratch() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-bd205-failsafe.XXXXXX")
    mkdir -p "$d/docs/project/backlog" \
             "$d/docs/project/implementation-plan" \
             "$d/docs/project/changelog" \
             "$d/.state"
    printf 'monolith backlog\n'   > "$d/docs/project/BACKLOG.md"
    printf 'monolith plan\n'      > "$d/docs/project/IMPLEMENTATION-PLAN.md"
    printf 'monolith changelog\n' > "$d/docs/project/CHANGELOG.md"
    printf '%s\n' "$d"
}

# Assert all three monoliths still present (fail-safe: not deleted).
assert_all_monoliths_present() {
    local d="$1" label="$2" ok=1 m
    for m in BACKLOG.md IMPLEMENTATION-PLAN.md CHANGELOG.md; do
        [[ -e "$d/docs/project/$m" ]] || ok=0
    done
    [[ "$ok" -eq 1 ]] && t_pass "$label" || t_fail "$label" "a monolith was deleted"
}

# 3.1 — decompose FAILS → fail_stage → monolith INTACT.
T3=$(make_streams_scratch)
_MIGRATOR_TARGET="$T3"; _MIGRATOR_STATE_DIR="$T3/.state"
STUB_DECOMPOSE_RC=1; STUB_TOC_RC=0; STUB_TOC_WRITE=1
STUB_ACCT_RC=0; STUB_INDEX_RC=0; STUB_INDEX_WRITE=1
( _v10_to_v11_decompose_streams ) >/dev/null 2>&1; rc=$?
assert_eq "3.1a decompose failure aborts sub-op (rc != 0)" "1" "$([[ "$rc" -ne 0 ]] && echo 1 || echo 0)"
assert_all_monoliths_present "$T3" "3.1b decompose failure leaves all monoliths INTACT"
rm -rf "$T3"

# 3.2 — decompose OK but TOC-regenerate FAILS → fail_stage → INTACT.
T3=$(make_streams_scratch)
_MIGRATOR_TARGET="$T3"; _MIGRATOR_STATE_DIR="$T3/.state"
STUB_DECOMPOSE_RC=0; STUB_TOC_RC=1; STUB_TOC_WRITE=1
STUB_ACCT_RC=0; STUB_INDEX_RC=0; STUB_INDEX_WRITE=1
( _v10_to_v11_decompose_streams ) >/dev/null 2>&1; rc=$?
assert_eq "3.2a TOC-regenerate failure aborts sub-op (rc != 0)" "1" "$([[ "$rc" -ne 0 ]] && echo 1 || echo 0)"
assert_all_monoliths_present "$T3" "3.2b TOC-regenerate failure leaves all monoliths INTACT"
rm -rf "$T3"

# 3.3 — decompose+TOC "OK" but NO _toc.md written (belt-and-suspenders
# guard) → fail_stage → INTACT. Proves the sub-op refuses to delete when
# the readable-form index is absent, even if both helpers reported success.
T3=$(make_streams_scratch)
_MIGRATOR_TARGET="$T3"; _MIGRATOR_STATE_DIR="$T3/.state"
STUB_DECOMPOSE_RC=0; STUB_TOC_RC=0; STUB_TOC_WRITE=0
STUB_ACCT_RC=0; STUB_INDEX_RC=0; STUB_INDEX_WRITE=1
( _v10_to_v11_decompose_streams ) >/dev/null 2>&1; rc=$?
assert_eq "3.3a absent _toc.md aborts sub-op (rc != 0)" "1" "$([[ "$rc" -ne 0 ]] && echo 1 || echo 0)"
assert_all_monoliths_present "$T3" "3.3b absent _toc.md leaves all monoliths INTACT (guard fires)"
rm -rf "$T3"

# 3.4 — decompose+TOC OK and _toc.md present → monolith DELETED.
T3=$(make_streams_scratch)
_MIGRATOR_TARGET="$T3"; _MIGRATOR_STATE_DIR="$T3/.state"
STUB_DECOMPOSE_RC=0; STUB_TOC_RC=0; STUB_TOC_WRITE=1
STUB_ACCT_RC=0; STUB_INDEX_RC=0; STUB_INDEX_WRITE=1
( _v10_to_v11_decompose_streams ) >/dev/null 2>&1; rc=$?
assert_eq "3.4a successful decompose sub-op rc=0" "0" "$rc"
del_ok=1
for _m in BACKLOG.md IMPLEMENTATION-PLAN.md CHANGELOG.md; do
    [[ -e "$T3/docs/project/$_m" ]] && del_ok=0
done
[[ "$del_ok" -eq 1 ]] \
    && t_pass "3.4b successful decompose DELETES all three monoliths" \
    || t_fail "3.4b successful decompose did NOT delete all monoliths" \
        "still: $(ls "$T3/docs/project/"*.md 2>/dev/null | tr '\n' ' ')"
rm -rf "$T3"

# 3.5 — accounting gate FAILS → fail_stage (S5d-accounting) → delete
# REFUSED → monolith INTACT. The gate-refusal bite: a non-zero
# per_entry_accounting_check verdict must abort the sub-op BEFORE any
# monolith deletion, with the sub-stage tag on stderr.
T3=$(make_streams_scratch)
ERR35=$(mktemp "${TMPDIR:-/tmp}/migrate10-bd291-35err.XXXXXX")
_MIGRATOR_TARGET="$T3"; _MIGRATOR_STATE_DIR="$T3/.state"
STUB_DECOMPOSE_RC=0; STUB_TOC_RC=0; STUB_TOC_WRITE=1
STUB_ACCT_RC=1; STUB_INDEX_RC=0; STUB_INDEX_WRITE=1
( _v10_to_v11_decompose_streams ) >/dev/null 2>"$ERR35"; rc=$?
assert_eq "3.5a accounting-gate failure aborts sub-op (rc != 0)" "1" \
    "$([[ "$rc" -ne 0 ]] && echo 1 || echo 0)"
assert_all_monoliths_present "$T3" \
    "3.5b accounting-gate failure leaves all monoliths INTACT (delete refused)"
err35_content=$(cat "$ERR35")
assert_contains "3.5c failure message carries the S5d-accounting sub-stage tag" \
    "$err35_content" "S5d-accounting"
rm -f "$ERR35"
rm -rf "$T3"

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All BD-165 decompose tests passed."
    exit 0
fi
exit 1
