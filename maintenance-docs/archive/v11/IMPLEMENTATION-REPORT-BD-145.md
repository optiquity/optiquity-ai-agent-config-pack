# IMPLEMENTATION-REPORT-BD-145

**BD:** BD-145 — `scripts/init-project.sh` D1/D5 detection hint + python-data marker integration
**Batch:** 6 of skill-dimensions reframe
**Branch:** v11-dev
**Pre-batch HEAD SHA:** `9675066d8818de93f469287fe67857feb6ad0806`
**Post-edit HEAD SHA:** `9675066d8818de93f469287fe67857feb6ad0806` (no commits — agent does not commit)
**Author:** pack-coder
**Date:** 2026-05-12

---

## 1. Pre-flight state

- Working tree was clean on `scripts/init-project.sh` (other unrelated batches in flight: BD-143 had modified `architecture-review` SKILL.md trinity + audit-methodology + project-template trinity files; an `IMPLEMENTATION-REPORT-BD-143.md` was untracked. None of these overlap BD-145's single-file scope).
- File line count pre-edit: **1094 lines**.
- File line count post-edit: **1112 lines** (+18).
- File size pre-edit: 46120 bytes.
- File size post-edit: 47198 bytes.
- Permission bits pre-edit: `-rwxr-xr-x@` — confirmed exec-bit present.
- Post-BD-141 `pack_skill_coverage_for()` shape (lines 219–250): existed; included the new `target_dir` arg + the `python_data_marker_detected` predicate consultation for the python row. Header comment present (referenced architecture §7.8). No D1/D5 dimension comments yet.
- Post-install prompt block: located in `stage_s10_kickoff_prompt()` starting line 642. Heredoc at line 666 (`cat <<EOF`); no existing `Active skills:` line, no existing BD-136 trinity-marker mention. The prompt is plain prose — kickoff workflow framing → existing-docs block (conditional) → gaps block (conditional) → `/pm-startup` instruction.

---

## 2. Per-edit log

### Edit 2.1 — Header comment + per-language D1/D5 hint comments (lines 219–260)

**Before** (lines 219–250):

```bash
# Pack skill coverage table (per §7.8). Used for skill-gap detection.
#
# Args:
#   $1   Language marker (swift|python|proto|...).
#   $2   Optional target project directory. Used by the python row
#        (BD-141) to consult the python_data_marker_detected predicate
#        in scripts/lib/detect.sh; defaults to $TARGET if unset, else
#        the current working directory. Other rows ignore $2.
pack_skill_coverage_for() {
    local lang="$1"
    local target_dir="${2:-${TARGET:-.}}"
    case "$lang" in
        swift)      echo "apple-architecture-core,swift-best-practices" ;;
        python)
            # BD-141: python-data-architecture loads only when the
            # concrete predicate matches (architecture §7.5).
            # python-best-practices is unconditional for python.
            # Compare against the full literal helper-output line
            # rather than parsing — tighter contract; a future helper
            # output change is caught at compare time, not silently.
            local marker_line
            marker_line=$(python_data_marker_detected "$target_dir")
            if [[ "$marker_line" == "python-data: yes" ]]; then
                echo "python-data-architecture,python-best-practices"
            else
                echo "python-best-practices"
            fi
            ;;
        proto)      echo "grpc-patterns" ;;
        *)          echo "" ;;  # No coverage
    esac
}
```

**After**:

```bash
# Pack skill coverage table (per §7.8). Used for skill-gap detection.
#
# Per the v11 PLATFORM-SKILLS.md reframe (BD-142), skills load via a 5+3
# model: 5 dimensions (D1 substrate, D2 cross-platform languages, D3
# component role, D4 communication protocols, D5 deployment surface) and
# 3 orthogonal load mechanisms (Tier 0 base, intersection-cell, trigger-
# loaded). The per-language rows below emit each language's pack-bundled
# skill coverage; PLATFORM-SKILLS.md is authoritative for the dimension
# membership and the full intersection / trigger semantics.
#
# Args:
#   $1   Language marker (swift|python|proto|...).
#   $2   Optional target project directory. Used by the python row
#        (BD-141) to consult the python_data_marker_detected predicate
#        in scripts/lib/detect.sh; defaults to $TARGET if unset, else
#        the current working directory. Other rows ignore $2.
pack_skill_coverage_for() {
    local lang="$1"
    local target_dir="${2:-${TARGET:-.}}"
    case "$lang" in
        # swift: D1=ios|macos (D1-implied) + Apple-platform skills via D1
        swift)      echo "apple-architecture-core,swift-best-practices" ;;
        # python: D2=python (cross-platform language) + intersection-loaded data/server skills
        python)
            # BD-141: python-data-architecture loads only when the
            # concrete predicate matches (architecture §7.5).
            # python-best-practices is unconditional for python.
            # Compare against the full literal helper-output line
            # rather than parsing — tighter contract; a future helper
            # output change is caught at compare time, not silently.
            local marker_line
            marker_line=$(python_data_marker_detected "$target_dir")
            if [[ "$marker_line" == "python-data: yes" ]]; then
                echo "python-data-architecture,python-best-practices"
            else
                echo "python-best-practices"
            fi
            ;;
        # proto: D4=grpc + future protobuf-patterns intersection (BD-156)
        proto)      echo "grpc-patterns" ;;
        *)          echo "" ;;  # No coverage
    esac
}
```

**Diff summary:** added 8-line header paragraph documenting the 5+3 model with PLATFORM-SKILLS.md as the authoritative reference; added 3 inline comment lines (one above each language case: swift, python, proto) declaring D1/D2/D4 dimension membership.

### Edit 2.2 — Post-install prompt paragraph (heredoc near line 676)

**Before**:

```bash
    cat <<EOF

──── End-of-run PM chat kickoff prompt ────

You are the PM chat for [PROJECT_NAME at $target_abs].

The AI Agent Config Pack $pack_ver has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
the PM chat kickoff prompt (docs/pack/prompts/pm-chat.md,
Variant: kickoff).
EOF
    if (( ${#existing_docs[@]} > 0 )); then
```

**After**:

```bash
    cat <<EOF

──── End-of-run PM chat kickoff prompt ────

You are the PM chat for [PROJECT_NAME at $target_abs].

The AI Agent Config Pack $pack_ver has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
the PM chat kickoff prompt (docs/pack/prompts/pm-chat.md,
Variant: kickoff).

PLATFORM-SKILLS.md was reframed in v11 to use 5 dimensions
(D1 substrate, D2 cross-platform languages, D3 component role,
D4 communication protocols, D5 deployment surface) plus 3 orthogonal
load mechanisms (Tier 0 base, intersection-cell, trigger-loaded).
Read §"How skill selection works" for the new framing before
generating prompts.
EOF
    if (( ${#existing_docs[@]} > 0 )); then
```

**Diff summary:** inserted one 7-line paragraph (6 prose lines + 1 blank-line separator) inside the existing heredoc, between the "kickoff workflow" framing and the existing-docs/gaps logic. Wording is verbatim from the spec.

---

## 3. Smoke test output

### 3.1 `--help` smoke

```text
$ bash scripts/init-project.sh --help
Usage: PACK=/path/to/pack init-project.sh [--update] [target-dir]
```

Exit code 0. (Note: `--help` is not implemented as a documented flag — the script falls through to its usage line because no PACK env was set + no target. The script's `--help` invocation produces the usage banner cleanly without errors. This is the behavior verified by the spec's "succeeds without errors" criterion.)

### 3.2 Substantive smoke (scratch dir, full install)

Provisioned a fresh `/tmp/scratch-bd145-init` git repo (with `git init -q && git commit --allow-empty -q -m init`) and ran the script piping `yes y` to satisfy the `Proceed?` prompt:

```text
$ rm -rf /tmp/scratch-bd145-init && mkdir -p /tmp/scratch-bd145-init && \
  (cd /tmp/scratch-bd145-init && git init -q && git commit --allow-empty -q -m init) && \
  yes y | PACK=/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev \
    bash /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh \
    /tmp/scratch-bd145-init 2>&1 | sed -n '/End-of-run PM chat kickoff prompt/,/End of kickoff prompt/p'

──── End-of-run PM chat kickoff prompt ────

You are the PM chat for [PROJECT_NAME at /tmp/scratch-bd145-init].

The AI Agent Config Pack v11-dev has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
the PM chat kickoff prompt (docs/pack/prompts/pm-chat.md,
Variant: kickoff).

PLATFORM-SKILLS.md was reframed in v11 to use 5 dimensions
(D1 substrate, D2 cross-platform languages, D3 component role,
D4 communication protocols, D5 deployment surface) plus 3 orthogonal
load mechanisms (Tier 0 base, intersection-cell, trigger-loaded).
Read §"How skill selection works" for the new framing before
generating prompts.

Run /pm-startup (or your CLI's equivalent), then apply the kickoff
variant with the developer.

──── End of kickoff prompt ────
```

The new paragraph appears verbatim in the rendered kickoff prompt. Scratch dir was cleaned up post-test (`rm -rf /tmp/scratch-bd145-init`).

### 3.3 Bash syntax check

```text
$ bash -n scripts/init-project.sh
syntax OK
```

---

## 4. Permission bits

```text
$ ls -l scripts/init-project.sh
-rwxr-xr-x@ 1 david  staff  47198 May 12 00:14 scripts/init-project.sh
```

Exec bit (`-rwxr-xr-x`) preserved across both edits. No `chmod +x` restoration required.

---

## 5. Validate-pack output

```text
$ python3 scripts/validate-pack.py
…
============================================================
PASSED — all checks clean
```

All 30 checks PASS. Notably:

- Check 9 (init-project structure): PASS — the per-stage file-tree shape was untouched; only comments + a heredoc prose paragraph changed.
- Check 21 (per-agent canonical phrases): PASS — no agent files touched.
- Check 26 (migrator-core sourcing graph): PASS — no library files touched.
- Check 27 (per-agent skill list): PASS — no skill list edits.
- Check 28 (PM-startup parity): PASS — pm-startup files untouched.
- Check 29 / 30 (tracker schema, recommendation-state): PASS.

---

## 6. Grep verification

### 6.1 New 5-dimension prose hits

```text
$ grep -nE "5 dimensions|D1 substrate" scripts/init-project.sh
222:# model: 5 dimensions (D1 substrate, D2 cross-platform languages, D3
688:PLATFORM-SKILLS.md was reframed in v11 to use 5 dimensions
689:(D1 substrate, D2 cross-platform languages, D3 component role,
```

Three hits: (a) the new function-header paragraph at line 222, (b) the new prompt paragraph opening at line 688, (c) the prompt paragraph's D1-D5 enumeration line at 689. The spec required ≥1; we have 3.

### 6.2 New per-language D1/D5 dimension comments

```text
$ grep -nE "# (swift|python|proto):" scripts/init-project.sh
239:        # swift: D1=ios|macos (D1-implied) + Apple-platform skills via D1
241:        # python: D2=python (cross-platform language) + intersection-loaded data/server skills
257:        # proto: D4=grpc + future protobuf-patterns intersection (BD-156)
```

All three language-case comments present (note: the spec's example regex `^# (swift|python|proto):` was anchored to start-of-line, but the comments correctly live indented inside the `case` block — pattern adjusted to drop `^` for the verification grep).

---

## 7. POQs

### POQ 1 — Post-install prompt block exact location and format

**Question:** the spec said to insert "between PM chat framing prose and the BD-136 trinity-marker mention, if present." The BD-136 trinity-marker mention is **not** present in the current `init-project.sh` (verified via `grep -n "BD-136\|trinity marker\|PLATFORM-SKILLS" scripts/init-project.sh` — only one hit at line 899 in an unrelated `--update` per-file dispatch path).

**Disposition:** Inserted the new paragraph inside the existing `cat <<EOF … EOF` heredoc that prints the kickoff prompt header (line 666), placed immediately after the "kickoff workflow framing" paragraph (the `Variant: kickoff` line) and before the heredoc closer. This guarantees:

1. Every PM chat invocation receives the new framing (it is unconditional, sitting in the always-printed heredoc rather than the conditional existing-docs / gaps follow-on blocks).
2. The new paragraph reads as part of the prompt prose (it is contiguous with the kickoff workflow line above it).
3. No heredoc / shell-quoting hazards (the paragraph contains no `$`, no backticks, no `EOF` substring — interpolation-safe inside the existing `cat <<EOF`).

Plan deviation: zero. The plan's spec was tolerant ("between … if present") and explicitly allowed adapting to the actual prompt structure.

### POQ 2 — Substantive smoke test feasibility

**Question:** the spec asked for a substantive smoke (`bash scripts/init-project.sh --project /tmp/scratch-bd145-init`) and to skip if impractical.

**Disposition:** the script does not accept a `--project` flag (positional `target-dir` arg). Adapted invocation to `bash scripts/init-project.sh /tmp/scratch-bd145-init` with required `PACK=` env, `git init` precondition, and `yes y` to satisfy the interactive `Proceed?` prompt. Smoke succeeded — see §3.2. Scratch dir cleaned up post-run.

### POQ 3 — Header comment redundancy with BD-141 paragraph

**Question:** the function header now contains both BD-145's new 5+3-model paragraph and BD-141's original `§7.8` reference line on the first line.

**Disposition:** Kept both. The §7.8 reference is the architecture-doc backing for the table itself (BD-141's original anchor). The new paragraph documents the 5+3 model context (BD-145's task). They serve different purposes and read fluidly together.

### POQ 4 — `^# (swift|python|proto):` grep anchor mismatch

**Question:** the spec's verification grep was anchored to start of line (`^#`), but the new comments are correctly indented inside the `case` block.

**Disposition:** documented in §6.2. The comments are present and correct in their natural location (immediately above each case branch, matching the indentation of the case branch); the spec's anchor pattern was the loose intent, not the exact required regex. Used `grep -nE "# (swift|python|proto):"` (no `^`) for verification; all three hit.

---

## 8. Files touched

```text
$ git diff --stat scripts/init-project.sh
 scripts/init-project.sh | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)
```

**Inventory:**

| Path | Change type | Net delta |
|---|---|---|
| `scripts/init-project.sh` | modified | +18 / −0 |

No new files. No deletions. Single-file footprint as required by the spec's "Single file may be modified" constraint.

No other files in the working tree were touched by BD-145. (Other working-tree modifications visible at pre-flight time — `architecture-review` SKILL.md trinity, `audit-methodology` SKILL.md, project-template trinity files, the BD-143 implementation report — belong to the parallel BD-143 batch and were untouched by this agent.)

---

## 9. Maintainability sanity check (BD-159 §3.1)

BD-145's footprint:

- **1 file edited.** Single source file (`scripts/init-project.sh`).
- **+18 lines, no deletions.** Pure additive: header doc paragraph (8 lines), 3 inline `# lang:` comments (3 lines), 1 prompt-prose paragraph (7 lines including blank separator).
- **No structural changes.** No new functions, no new flags, no new args, no new call sites, no new dependencies, no new files in any other layer.
- **No fanned-out dependent edits.** The new prompt paragraph references PLATFORM-SKILLS.md (which already exists in its post-BD-142 reframe state); the per-language comments reference PLATFORM-SKILLS.md dimensions (which already exist).
- **Mechanical-edit nature.** Each of the 3 per-language comments is a one-line annotation following the pattern `# <lang>: D<N>=<dim> + <semantic>`. The header paragraph and prompt paragraph are prose adaptations of canonical phrasing already established in PLAN-SKILL-DIMENSIONS.md and PLATFORM-SKILLS.md.

This satisfies BD-159 §3.1 mechanical-edit threshold: the change is purely additive prose / annotation, the underlying behavior (`pack_skill_coverage_for` return values, prompt-rendering control flow) is byte-for-byte identical, and no other pack files require coordinated edits. **Maintainability check: PASS.**

---

## 10. Definition-of-done checklist

| # | Spec requirement | Status |
|---|---|---|
| 1 | `pack_skill_coverage_for()` header comment describes 5+3 model context | PASS (lines 219-227) |
| 2 | Header comment contains a one-line pointer to PLATFORM-SKILLS.md as authoritative | PASS (line 226-227 — "PLATFORM-SKILLS.md is authoritative…") |
| 3 | swift case has D1 dimension comment | PASS (line 239 — `# swift: D1=ios|macos…`) |
| 4 | python case has D-dimension comment | PASS (line 241 — `# python: D2=python…`) |
| 5 | proto case has D-dimension comment | PASS (line 257 — `# proto: D4=grpc…`) |
| 6 | Skill list emissions themselves unchanged (BD-141 work preserved) | PASS — `echo` lines + python conditional unchanged |
| 7 | Post-install prompt paragraph inserted with 5-dimension framing | PASS (lines 688-693 in rendered file; verified in §3.2 smoke) |
| 8 | New paragraph mentions all 5 dimensions explicitly | PASS — `D1 substrate, D2 cross-platform languages, D3 component role, D4 communication protocols, D5 deployment surface` |
| 9 | New paragraph mentions all 3 load mechanisms | PASS — `Tier 0 base, intersection-cell, trigger-loaded` |
| 10 | New paragraph instructs PM chat to read §"How skill selection works" | PASS — `Read §"How skill selection works" for the new framing before generating prompts.` |
| 11 | `python3 scripts/validate-pack.py` passes all 30 checks | PASS (`PASSED — all checks clean`) |
| 12 | `bash -n scripts/init-project.sh` syntax clean | PASS |
| 13 | `ls -l scripts/init-project.sh` shows `-rwxr-xr-x` (exec bit preserved) | PASS |
| 14 | `bash scripts/init-project.sh --help`-equivalent succeeds without errors | PASS — usage banner printed, exit 0 |
| 15 | Substantive smoke shows new paragraph in rendered prompt | PASS (see §3.2) |
| 16 | `grep -nE "5 dimensions|D1 substrate" scripts/init-project.sh` ≥ 1 hit | PASS (3 hits) |
| 17 | `grep -nE "# (swift|python|proto):" scripts/init-project.sh` shows 3 comments | PASS (3 hits) |
| 18 | Single-file scope honored | PASS — only `scripts/init-project.sh` modified |
| 19 | No state-changing git verbs run | PASS |
| 20 | BD-141's python-conditional logic preserved byte-identical | PASS — diff shows only additive edits in that block |
| 21 | Maintainability §3.1 mechanical-edit threshold satisfied | PASS (see §9) |

**All 21 DoD items: PASS.**

---

## 11. Plan deviations

**Zero substantive deviations.** Two adaptations to the spec wording, both authorized by the spec's own latitude:

1. The spec's example placement guidance ("between PM chat framing prose and the BD-136 trinity-marker mention, if present") was conditional. BD-136 trinity marker was absent; the new paragraph was placed inside the existing kickoff-prompt heredoc immediately after the kickoff workflow framing, preserving the paragraph's purpose as standing prose every PM chat receives. (Documented in POQ 1.)
2. The substantive smoke `--project /tmp/scratch-bd145-init` flag does not exist in the script; adapted to the positional `target-dir` form with `PACK=` env and `git init`. The substantive intent was preserved. (Documented in POQ 2.)

No new POQs requiring future BDs were introduced.

---

## 12. New POQs introduced

None requiring BD assignment. The four POQs in §7 are local clarifications about the implementation; they do not reflect gaps in the architecture or surface new design questions.

---

## 13. Coordination with parallel batches

- **BD-143 (parallel, in flight).** Modifies trinity / audit-methodology / architecture-review skill files. **Zero overlap** with BD-145 — BD-145 touched only `scripts/init-project.sh`.
- **BD-144 (parallel).** Modifies `add-capability.sh` / `lib/detect.sh` / `test-detect.sh` / `migrate-v10-to-v11.sh` + a new fixture. **Zero overlap** with BD-145 — `init-project.sh` is the only script touched.

No coordination conflicts. BD-145 can be committed by Pack Chat independently of BD-143 / BD-144's completion, ordering-wise.

---

## 14. Summary

`scripts/init-project.sh` extended with D1/D5 hints in `pack_skill_coverage_for()` (function-level header doc paragraph + 3 per-language dimension comments) and a 5+3-model framing paragraph in the end-of-run PM chat kickoff prompt. Validate-pack PASS (all 30 checks). Exec bit preserved (`-rwxr-xr-x`). Substantive smoke confirms the new prompt paragraph renders verbatim. Single-file scope, +18 lines net additive, zero behavioral change. Maintainability §3.1 mechanical-edit threshold satisfied.
