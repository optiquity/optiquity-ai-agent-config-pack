# V10-F-E-F-F-PLAN — Post-migration housekeeping (Procedure 5-S) patch (planner pass)

**Author:** pack-planner (v10.0 patch — F-E + F-F joint resolution)
**Date:** 2026-04-29
**Implements:** `maintenance-docs/V10-F-E-F-F-DESIGN.md` (architect pass, 2026-04-29; project-lead approved)
**Status:** Draft — planner output. Read-only on every pack source. No edits, no commits. Implementer (parent Pack Chat) executes after project-lead approval of this plan.
**Scope:** v10.0 patch resolving F-E (stale `**AI Agent Config Pack**: v9` markers in project-internal docs) and F-F (unfilled trinity placeholders) jointly via a new METHODOLOGY one-shot procedure (`Procedure 5-S — Post-migration housekeeping`), a sentinel-write in `migrate-v9-to-v10.sh` S7, a new `Step 0` block in the pm-startup SKILL, and an orientation bullet in `MIGRATION-v9-to-v10.md` Step 4. Companion to F-D + F-C patch already landed at commits `1de2d23` / `603234e` / `55d1834`.

---

## 0. How to read this plan

V10-F-E-F-F-DESIGN.md is the authoritative input. The decision (combined procedure, sentinel-file trigger, explicit per-procedure SKILL routing, tolerant marker scans) and rationale are baked-in here and not re-litigated. This plan adds:

- Per-file edit specifications (line numbers verified against current tip of `v10-dev`).
- Concrete text for the four edits (METHODOLOGY Procedure 5-S body, migrate S7 sentinel, SKILL Step 0, MIGRATION Step 4 bullet) — not pseudocode; copy-pasteable.
- Commit-shape decision and edit ordering.
- Verification harness — fixture builds, post-fix checks, evidence-block template (appended as §11 to existing V10-PHASE-4-VERIFICATION.md).
- Per-commit verification checklist.
- Open-question resolutions (already provided by project-lead decisions OQ-1..OQ-5; recorded inline at each affected edit).

The implementer can execute this plan literally without further architectural calls.

**Project-lead decisions baked-in (do not re-debate):**
- **D1.** Design approved. Procedure 5-S is canonical mechanism.
- **D2 (OQ-1).** Active-skills task uses simpler standalone Q&A (NOT Procedure 7 kickoff flow).
- **D3 (OQ-2).** Pack-version source = METHODOLOGY first 5 lines (matches pm-startup Step 6).
- **D4 (OQ-3).** STATUS.md priority list = `docs/project/STATUS.md` → `docs/STATUS.md` → `STATUS.md`.
- **D5 (OQ-4).** Both Task A (F-E) and Task B (F-F) ship at v10.0.
- **D6 (OQ-5).** Defer formalizing the "one-shot-procedure trigger" pattern.

---

## 1. Goal and BD items addressed

**Goal:** add a one-shot METHODOLOGY procedure (Procedure 5-S) that, on first PM chat after migration, scans the project for stale v9 pack-version markers in STATUS.md (Task A) and unfilled trinity placeholders (Task B), surfaces findings to the developer, applies developer-approved fixes, and self-cleans. Triggered by a sentinel file written by `migrate-v9-to-v10.sh` S7. Detected by a new pre-Step-1 block in the pm-startup SKILL that ALSO closes a latent gap in Procedure 5-R routing (currently surfaced only via MIGRATION-v9-to-v10.md prose, not in the SKILL).

**BD items in scope:**
- F-E + F-F combined → one BD-NNN (assigned at C-V10-18 BACKLOG sweep per project-lead D5).
- This plan does NOT file the BD entry; it produces the edits the BD entry's "Resolution" line will reference.

---

## 2. Commit shape decision

**Decision: 3 commits** following the F-D pattern:

| Commit | Type | Files | Purpose |
|---|---|---|---|
| **C1** | `docs:` | `maintenance-docs/V10-F-E-F-F-DESIGN.md`, `maintenance-docs/V10-F-E-F-F-PLAN.md` | Design + plan documents (already on disk; this commit just lands them in git). |
| **C2** | `feat:` | `supporting-docs/METHODOLOGY.md`, `scripts/migrate-v9-to-v10.sh`, `project-template/skills/pm-startup/SKILL.md`, `supporting-docs/MIGRATION-v9-to-v10.md` | Atomic 4-file behavioral patch implementing Procedure 5-S. |
| **C3** | `docs:` | `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (append §11) | Delta-verification evidence section. |

**Rationale (why atomic for C2; why the docs-vs-impl-vs-evidence split):**

1. **Atomic for C2 because the four edits are tightly coupled.** The METHODOLOGY procedure body is referenced by the SKILL Step 0 ("route to the named METHODOLOGY procedure"). The SKILL Step 0 is meaningless without the sentinel that the migration script writes. The MIGRATION doc bullet describes both. Splitting C2 into "METHODOLOGY first; migrate-v9-to-v10.sh second; SKILL third; MIGRATION fourth" leaves intermediate states where (a) the procedure exists in METHODOLOGY but no sentinel ever fires it, or (b) the SKILL routes to a non-existent procedure. Neither breaks `validate-pack.py` (no METHODOLOGY procedure-presence check exists), but both are misleading partial states. Atomic is cleaner.
2. **C1 separated from C2** because the design + plan documents are reference artifacts that exist regardless of whether the implementation lands. Same shape as the F-D patch (commit `1de2d23` was design + plan; commit `603234e` was the 5-file behavioral patch). Project lead approves the design before the implementation commit lands.
3. **C3 separated from C2** so the behavioral patch is reviewable independently of the evidence capture. Same as F-D's `docs:` follow-up. Evidence might be regenerated/refined; behavioral patch should not be re-edited each time.
4. **`validate-pack.py` does not assert any of the new artifacts.** No check enforces "Procedure 5-S exists in METHODOLOGY" or "sentinel write present in S7" or "SKILL has Step 0". Splitting C2 therefore offers no validate-pack.py-driven gating value.
5. **Trinity rule is not engaged in C2** (per design §7 / §9). No trinity-symmetry gate to satisfy commit-by-commit.
6. **Touch surface for C2 is small (4 files; ~50 lines of net new content).** A single coherent commit is easier to review than four thin ones.

**Rejected alternative — split C2 into separate commits per file:** doubles approval overhead; introduces intermediate misleading states; produces no checkpoint that validate-pack.py would gate on; harder to review than a single coherent diff.

**Rejected alternative — combine all three into one commit:** mixes design docs (which should be reviewable separately) with behavioral changes; mixes verification evidence (which must be captured AFTER the implementation runs) with the implementation itself.

---

## 3. Affected files (complete list)

### 3.1 Files edited in C2 (4)

| # | File | Edit area | Purpose |
|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | After line 1228 (last line of Procedure 5-R), before line 1230 (start of Procedure 6 heading) | Insert new `### Procedure 5-S — Post-migration housekeeping` section. ~35 lines including a small task table. |
| 2 | `scripts/migrate-v9-to-v10.sh` | `stage_s7_report` function, after line 449 (`} > "$report"`), before line 451 (`write_sentinel "S7"`) | Add `touch "$BACKUP_DIR/postrun-pending"`. Add a "Post-migration housekeeping" bullet to the report's "Next steps" list (within the heredoc, lines 437–443). |
| 3 | `project-template/skills/pm-startup/SKILL.md` | Insert new section between line 8 (last line of intro paragraph) and line 10 (`## Step 1 — Sync repo`) | Insert new "## Step 0 — Check for pending one-shot procedures" block. ~18 lines per design §5.1. Detects both 5-S sentinel AND existing 5-R `_v9-backup.md` (closes latent gap). |
| 4 | `supporting-docs/MIGRATION-v9-to-v10.md` | Step 4 "Expected behaviors" list, between lines 233 ("No flags raised") and 235 ("`_v9-backup.md` present...") | Insert one new bullet at the top of the Expected-behaviors list describing Procedure 5-S as always-runs orientation. |

### 3.2 Files edited in C1 (2)

- `maintenance-docs/V10-F-E-F-F-DESIGN.md` — already on disk (architect output); add to git in C1.
- `maintenance-docs/V10-F-E-F-F-PLAN.md` — this file; add to git in C1.

### 3.3 Files edited in C3 (1)

- `maintenance-docs/V10-PHASE-4-VERIFICATION.md` — append new `## §11 Delta verification — F-E + F-F patch` section after the existing `## §10` section (lines 934–1021). Template per §5 of this plan.

### 3.4 Files NOT edited (verified)

- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (trinity) — no edits required per design §7 / §9. The new procedure body lives in METHODOLOGY (which trinity already references). The `[PLATFORM_DEFAULTS]` / `[PLATFORM_ARCHITECTURE]` / `[LANGUAGE_RULES]` / `[GRPC_RULES]` / `[PLATFORM_SECURITY]` / `[PLATFORM_TESTING]` / `[PLATFORM_ANTIPATTERNS]` / `[PROJECT_NAME]` / `[PLATFORM_TARGETS]` / `[TRANSPORT]` placeholders the procedure scans for are documented in the existing trinity content and need no addition. Trinity-rule status: clean.
- Pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` — not affected. These govern pack-repo agent behavior, not project PM chat behavior.
- `project-template/docs/pack/PM-CHAT.md` — no edit. The new procedure is discovered via the SKILL Step 0; PM-CHAT.md does not enumerate procedures.
- `supporting-docs/SETUP-NEW.md` — Procedure 5-S is migration-specific (sentinel set by migrate, not by init). New projects have no stale v9 markers, and the kickoff flow already fills trinity placeholders. No edit.
- `scripts/init-project.sh` — no edit. The S4 stage already distributes `project-template/skills/pm-startup/SKILL.md` to `.claude/`, `.codex/`, `.gemini/` skill dirs (lines 295–305); the SKILL Step 0 propagates automatically on next init run.
- `scripts/validate-pack.py` — no edit. No check enforces presence of new artifacts. No path assertions to update.
- `scripts/test-detect.sh` — no edit. Detection logic (the 34/34 tests) does not exercise the new procedure or sentinel.
- `project-template/README.md` — no edit. Pack-version markers in README are about pack version, not project version, and are the live pack version (not stale v9).
- `BACKLOG.md` / `CHANGELOG.md` / `README.md` (pack root) — handled by Pack Chat at C-V10-18 BACKLOG sweep, out of plan scope.
- `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` — no edit. The new procedure is post-Phase-4 ship-blocker work; the v2 plan does not assert procedure presence.

### 3.5 Cross-reference audit (no hits found)

- `Procedure 5-S` references in pack content (excluding `maintenance-docs/V10-F-E-F-F-DESIGN.md` and this plan): zero hits before C2; one hit (the new METHODOLOGY section) and a small number of references in the SKILL Step 0 / MIGRATION bullet after C2.
- `postrun-pending` references in pack content: zero before C2; introduced in C2 (3 hits — METHODOLOGY procedure body, migration script, SKILL Step 0).
- `pm-startup.*Step 0` cross-references in any other doc: zero hits. The only existing pm-startup-by-step-number cross-reference is in `BACKLOG.md` line 561 ("METHODOLOGY.md (Procedure 1 step 6)") which references METHODOLOGY's Procedure 1 step 6, not the SKILL — no conflict.
- `PROMPT-TEMPLATES` references that the new edits introduce: zero. Procedure 5-S body does not mention PROMPT-TEMPLATES; the F-D `blast_radius_sweep --exclude='METHODOLOGY.md'` exclusion remains untouched and unaffected (METHODOLOGY already legitimately mentions PROMPT-TEMPLATES in Procedure 5-R, and Procedure 5-S adds no new PROMPT-TEMPLATES mentions).

---

## 4. Edit order within C2

The implementer applies edits in this order within the atomic C2 commit. Order is chosen so an interrupted edit session leaves the most-critical correctness in place first.

| Step | File | Why this order |
|---|---|---|
| E1 | `supporting-docs/METHODOLOGY.md` (Procedure 5-S body) | The procedure body is the spec the other three edits reference. Land it first so the SKILL Step 0 routing target exists before the SKILL gains the route. |
| E2 | `scripts/migrate-v9-to-v10.sh` S7 | Sentinel-write is independent of E1/E3/E4. Land it second; once a project migrates, the sentinel is ready, even if the SKILL still has no Step 0. |
| E3 | `project-template/skills/pm-startup/SKILL.md` Step 0 | Routing target now exists (E1) and trigger now exists (E2). Add the SKILL Step 0 last among the behavioral edits. |
| E4 | `supporting-docs/MIGRATION-v9-to-v10.md` Step 4 | User-facing prose. Once behavior is correct (E1/E2/E3), align the human-readable description. |

`validate-pack.py` is not run incrementally between these edits — it does not gate on any of the new artifacts. It is run **once** after all four edits land, before commit. See §6 per-commit verification checklist.

---

## 5. Per-file edit specifications

### 5.1 Edit E1 — `supporting-docs/METHODOLOGY.md` Procedure 5-S body

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** 1206–1228 contain Procedure 5-R; line 1229 is blank; line 1230 starts `### Procedure 6 — Adding a pack-supported capability`.
**Insertion point:** after line 1228 (end of Procedure 5-R), insert one blank line then the new Procedure 5-S section, then the existing blank line and Procedure 6 heading remain unchanged.

**Insert text (paste verbatim):**

```markdown
### Procedure 5-S — Post-migration housekeeping

Triggered by presence of `.pack-migration-backup/v9.3-to-v10.0/postrun-pending`
at PM chat startup. Written by `migrate-v9-to-v10.sh` stage S7. Combines two
post-migration housekeeping tasks; either may report "nothing to do" without
defect. Procedure is re-entrant — partial completion preserves the sentinel
and re-runs at next `/pm-startup`.

| Task | Scope | Action |
|---|---|---|
| **A** | STATUS.md pack-version markers (F-E) | Search `docs/project/STATUS.md`, then `docs/STATUS.md`, then `STATUS.md` (first existing wins). Grep case-insensitively for lines containing both `AI Agent Config Pack` (or `Pack version`) and a `v9` token. For each match, propose updating the version to the current pack version (read from `docs/pack/METHODOLOGY.md` first 5 lines, matching pm-startup Step 6). Developer approves / edits / skips per match. If no STATUS.md found or no v9 markers found: report "Task A — nothing to do." |
| **B** | Trinity placeholder reconciliation (F-F) | Grep `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` for occurrences of the closed-form whitelist: `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`. Also grep for the literal Active-skills placeholder line (`Active skills: [PM chat writes`). For project-identifier placeholders, ask the developer for the values (project name, platform targets, transport) and offer to fill them consistently across all three trinity files (TRIO — byte-identical content). For section placeholders, reference the loaded skills' content. For the Active-skills line, run a simpler standalone Q&A (NOT the full Procedure 7 kickoff flow): "What skills are active for this project? Read `docs/pack/PLATFORM-SKILLS.md` to see options. PM chat proposes the set based on project type; developer approves." If no whitelist matches found and Active-skills line is filled: report "Task B — nothing to do." |

1. Detect sentinel; read `docs/pack/METHODOLOGY.md` first 5 lines for current
   pack version (Task A reference value).
2. Run Task A. Surface findings (or "nothing to do"); apply developer-approved
   edits to STATUS.md.
3. Run Task B. Surface findings (or "nothing to do"); apply developer-approved
   edits to the trinity files (TRIO; byte-identical across CLAUDE.md /
   AGENTS.md / GEMINI.md for every section the trinity rule covers).
4. If both tasks completed (no deferred items remain), PM chat offers to
   remove the sentinel `.pack-migration-backup/v9.3-to-v10.0/postrun-pending`
   and records the housekeeping in the commit message. Once removed,
   Procedure 5-S does not run again. If either task has deferred items,
   leave the sentinel in place — Procedure 5-S re-runs at next `/pm-startup`,
   re-scans (skipping items already addressed), and resurfaces the rest.
```

**Verification check for this edit:**

```bash
# After edit, confirm the new procedure section is present and well-formed.
grep -n '^### Procedure 5-S — Post-migration housekeeping' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit, between the line currently at 1206 (Procedure 5-R) and the
# line currently at 1230 (Procedure 6) — i.e., the new heading is somewhere
# in lines 1230–1234 post-edit.

grep -n 'postrun-pending' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 2 hits (in the procedure body — the trigger description and the
# step 4 cleanup).

grep -c '^### Procedure 6 — Adding a pack-supported capability' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 (Procedure 6 heading still exists; not accidentally removed).
```

### 5.2 Edit E2 — `scripts/migrate-v9-to-v10.sh` S7 sentinel + report bullet

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh`
**Lines (current):** 408–453 (`stage_s7_report` function). The heredoc that writes the report runs lines 416–449. The `write_sentinel "S7"` call is at line 451.
**BACKUP_DIR scope:** confirmed in scope — declared at line 24 (`readonly BACKUP_DIR=".pack-migration-backup/v9.3-to-v10.0"`); referenced throughout.
**Logging style:** `say` for stdout (line 30); `warn` for stderr (line 32 typical pattern). Use `say` for the new touch-result message.

**Edit E2a — add the postrun-pending bullet inside the heredoc.**

**Before (lines 437–443, current text):**

```bash
        echo "## Next steps"
        echo ""
        echo "1. Review \`git diff\` and this report."
        echo "2. If \`_v9-backup.md\` exists under \`docs/pack/prompts/\`, expect"
        echo "   the PM chat to invoke Procedure 5-R on its next run."
        echo "3. Commit the migration ON THE \`$MIGRATION_BRANCH\` BRANCH."
        echo "4. Follow \`supporting-docs/MIGRATION-v9-to-v10.md\` Steps 5–7."
```

**After (replacement text):**

```bash
        echo "## Next steps"
        echo ""
        echo "1. Review \`git diff\` and this report."
        echo "2. At your next PM chat session, expect the PM chat to invoke"
        echo "   Procedure 5-S (post-migration housekeeping): scans STATUS.md"
        echo "   for stale pack-version markers and trinity files for unfilled"
        echo "   placeholders. The procedure self-cleans on completion."
        echo "3. If \`_v9-backup.md\` exists under \`docs/pack/prompts/\`, expect"
        echo "   the PM chat to invoke Procedure 5-R on its next run."
        echo "4. Commit the migration ON THE \`$MIGRATION_BRANCH\` BRANCH."
        echo "5. Follow \`supporting-docs/MIGRATION-v9-to-v10.md\` Steps 5–7."
```

**Edit E2b — add the sentinel `touch` after the heredoc closes, before `write_sentinel "S7"`.**

**Before (lines 449–451, current text):**

```bash
    } > "$report"

    write_sentinel "S7"
```

**After (replacement text):**

```bash
    } > "$report"

    # Post-migration housekeeping sentinel — triggers METHODOLOGY Procedure 5-S
    # at next PM-chat /pm-startup. Procedure deletes the sentinel as its final
    # step. Always written; Procedure 5-S handles "nothing to do" gracefully.
    touch "$BACKUP_DIR/postrun-pending"
    say "  wrote post-migration housekeeping sentinel: $BACKUP_DIR/postrun-pending"

    write_sentinel "S7"
```

**Verification checks for this edit:**

```bash
grep -n 'touch "\$BACKUP_DIR/postrun-pending"' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh
# Expect: 1 hit, in stage_s7_report.

grep -n 'Procedure 5-S' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh
# Expect: 1 hit (in the heredoc's Next-steps list, "invoke Procedure 5-S").

# Confirm S7's order is preserved (sentinel BEFORE write_sentinel "S7"):
sed -n '/^stage_s7_report/,/^}/p' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh \
  | grep -nE 'postrun-pending|write_sentinel "S7"'
# Expect: postrun-pending touch line appears BEFORE write_sentinel "S7" line.
```

### 5.3 Edit E3 — `project-template/skills/pm-startup/SKILL.md` Step 0

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/pm-startup/SKILL.md`
**Lines (current):** YAML frontmatter at lines 1–5; intro paragraph lines 7–8; Step 1 heading at line 10. The new Step 0 inserts between line 8 and line 10 (or, equivalently, immediately before the existing `## Step 1 — Sync repo` heading).
**Cross-reference impact:** existing pm-startup-step-by-number references in pack content: `BACKLOG.md` line 561 references "METHODOLOGY.md (Procedure 1 step 6)" — that is a METHODOLOGY procedure step, not a SKILL step; no conflict. No other doc references pm-startup steps by number. Renumbering Steps 1–6 is NOT performed; the new step is "Step 0" so existing numbering is preserved.

**Before (lines 7–10, current text):**

```markdown
You are the PM chat for this project. Run this startup sequence now and report
the result. Do not ask questions — execute each step in order.

## Step 1 — Sync repo
```

**After (replacement text):**

```markdown
You are the PM chat for this project. Run this startup sequence now and report
the result. Do not ask questions — execute each step in order.

## Step 0 — Check for pending one-shot procedures

Before running the standard startup sequence, check whether any one-shot
post-migration procedures are pending. Run:

```bash
[[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] && \
    echo "POSTRUN-PENDING: Procedure 5-S"
[[ -f docs/pack/prompts/_v9-backup.md ]] && \
    echo "PROMPT-RECON-PENDING: Procedure 5-R"
```

If either line is emitted, do NOT run the standard startup sequence yet.
Instead, route to the named METHODOLOGY procedure(s) (Procedure 5-S for
POSTRUN-PENDING; Procedure 5-R for PROMPT-RECON-PENDING) and run them now.
After all triggered procedures complete (or the developer explicitly defers
remaining items), resume the standard startup sequence at Step 1.

If neither file exists, this step is a no-op — proceed directly to Step 1.

## Step 1 — Sync repo
```

**Verification checks for this edit:**

```bash
grep -n '^## Step 0 — Check for pending one-shot procedures' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/pm-startup/SKILL.md
# Expect: 1 hit.

grep -n 'POSTRUN-PENDING: Procedure 5-S' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/pm-startup/SKILL.md
# Expect: 1 hit.

grep -n 'PROMPT-RECON-PENDING: Procedure 5-R' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/pm-startup/SKILL.md
# Expect: 1 hit.

grep -nE '^## Step [0-6]' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/pm-startup/SKILL.md
# Expect: 7 hits — Step 0, Step 1, Step 2, Step 3, Step 4, Step 5, Step 6
# (existing Steps 1–6 unchanged; new Step 0 inserted before Step 1).
```

### 5.4 Edit E4 — `supporting-docs/MIGRATION-v9-to-v10.md` Step 4 bullet

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md`
**Line (current):** insertion point is between line 233 (the `**No flags raised.**` bullet) and line 235 (the `**\`_v9-backup.md\` present...**` bullet) within the "Expected behaviors" list under Step 4.
**Routing-inventory addition:** add the new bullet at the TOP of the list (immediately after the introduction "Expected behaviors depending on what the migration report flagged:" line) because Procedure 5-S is described by the design as "always runs" — most prominent placement matches that semantic.

**Before (lines 231–243, current text):**

```markdown
Expected behaviors depending on what the migration report flagged:

- **No flags raised.** PM chat reports the project is cleanly
  migrated; proceed with Workflow 2 / next phase as normal.
- **`_v9-backup.md` present in `docs/pack/prompts/`.** PM chat invokes
  Procedure 5-R (METHODOLOGY.md Part 7): reads `_v9-backup.md`,
  surfaces each customization with a proposed v10 placement (variant
  slug), and asks you to approve / modify / reject each item. After
  reconciliation, PM chat offers to remove `_v9-backup.md`.
- **Improperly-added files flagged.** PM chat routes to Procedure 5.4
  (adopt / remove / defer) for each flagged file.
- **Unregistered custom files flagged.** PM chat routes to
  Procedure 5.3 (complete registration).
```

**After (replacement text):**

```markdown
Expected behaviors depending on what the migration report flagged:

- **Procedure 5-S — Post-migration housekeeping (always runs).** The PM
  chat detects the `postrun-pending` sentinel written by `migrate-v9-to-v10.sh`
  S7 and invokes Procedure 5-S (METHODOLOGY.md Part 7). The procedure
  scans STATUS.md for stale `**AI Agent Config Pack**: v9` markers and
  the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) for unfilled
  placeholders (`[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`,
  `[PLATFORM_*]`, and the Active-skills line). Findings are surfaced;
  the developer approves / edits / skips each item. The procedure
  self-cleans on completion (deletes the sentinel). If either task
  reports "nothing to do," the procedure exits cleanly.
- **No flags raised (beyond Procedure 5-S).** PM chat reports the
  project is cleanly migrated; proceed with Workflow 2 / next phase as
  normal.
- **`_v9-backup.md` present in `docs/pack/prompts/`.** PM chat invokes
  Procedure 5-R (METHODOLOGY.md Part 7): reads `_v9-backup.md`,
  surfaces each customization with a proposed v10 placement (variant
  slug), and asks you to approve / modify / reject each item. After
  reconciliation, PM chat offers to remove `_v9-backup.md`.
- **Improperly-added files flagged.** PM chat routes to Procedure 5.4
  (adopt / remove / defer) for each flagged file.
- **Unregistered custom files flagged.** PM chat routes to
  Procedure 5.3 (complete registration).
```

**Verification check for this edit:**

```bash
grep -n 'Procedure 5-S — Post-migration housekeeping' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md
# Expect: 1 hit, in Step 4's Expected-behaviors list.

grep -nE 'postrun-pending sentinel' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md
# Expect: 1 hit, in the new Step-4 bullet.
```

---

## 6. Per-commit verification checklist

Adapted from `V10-PHASE-4-PLAN.md` Part 7 / `V10-F-D-PLAN.md` §6, specialized for this patch. Three commits → three checklists. The implementer runs every check, captures output, presents to project lead before each commit.

### 6.1 C1 (`docs:` design + plan) — pre-commit

```
[ ] git status                          — staged files: V10-F-E-F-F-DESIGN.md, V10-F-E-F-F-PLAN.md
[ ] git diff --stat                     — only the two maintenance-docs files; no behavioral file changes
[ ] python3 scripts/validate-pack.py    — exits 0 (regression guard; should be unaffected by docs-only commit)
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`
```

### 6.1.1 C1 — post-commit

```
[ ] git log --oneline -1                — commit message matches §8 spec for C1
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm)
[ ] gh run watch (or: monitor Actions)  — Validate Pack workflow green
```

### 6.2 C2 (`feat:` 4-file behavioral patch) — pre-commit

```
[ ] git status                          — staged files match the 4 listed in §3.1:
       supporting-docs/METHODOLOGY.md
       scripts/migrate-v9-to-v10.sh
       project-template/skills/pm-startup/SKILL.md
       supporting-docs/MIGRATION-v9-to-v10.md
[ ] git diff --stat                     — line-count delta is ~80–100 lines total (METHODOLOGY +35; migrate +9; SKILL +18; MIGRATION +12)
[ ] git diff --name-only                — names match exactly (no surprise file additions)
[ ] §5.1 grep checks (E1 METHODOLOGY)   — all expected hit-counts match
[ ] §5.2 grep checks (E2 migrate)       — all expected hit-counts match
[ ] §5.3 grep checks (E3 SKILL)         — all expected hit-counts match (Step 0 present; 7 step headings total)
[ ] §5.4 grep checks (E4 MIGRATION)     — all expected hit-counts match
[ ] python3 scripts/validate-pack.py    — exits 0 (no METHODOLOGY-procedure check; no sentinel-path check; this is a regression guard)
[ ] bash scripts/test-detect.sh         — exits 0; reports 34/34 passing (regression guard)
[ ] Trinity rule N/A                    — verify by `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns empty
[ ] §7 delta verification harness       — all four fixture builds pass (§7.3–§7.7); output captured to /tmp; ready for §11 evidence section
[ ] Cross-reference audit               — `grep -rn "Procedure 5-S" supporting-docs/ project-template/ scripts/ | grep -v 'maintenance-docs/'` returns exactly the expected hits (METHODOLOGY new section + SKILL Step 0 + MIGRATION Step 4 bullet + migrate-v9-to-v10.sh report bullet)
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`
```

### 6.2.1 C2 — post-commit

```
[ ] git log --oneline -1                — commit message matches §8 spec for C2
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm post-commit)
[ ] bash scripts/test-detect.sh         — exits 0; 34/34 (re-confirm)
[ ] gh run watch                        — Validate Pack workflow green on v10-dev
```

**If validate-pack.py fails post-commit:** roll back per V10-PHASE-4-PLAN.md Part 7: `git reset --soft HEAD~1`, fix, recommit. Pack must remain working at every intermediate commit.

### 6.3 C3 (`docs:` §11 delta evidence) — pre-commit

```
[ ] git status                          — staged: maintenance-docs/V10-PHASE-4-VERIFICATION.md only
[ ] git diff --stat                     — appended-only (no edits to existing §1–§10 content; new §11 added)
[ ] §11 evidence template fully filled  — every [bracketed value] replaced with actual harness output
[ ] §11 sanitization                    — no OT content; all fixtures synthetic (per §6.7.7 of V10-PHASE-4-VERIFICATION-PLAN-v2.md)
[ ] python3 scripts/validate-pack.py    — exits 0 (regression guard; docs-only)
[ ] Approval gate                       — explicit project-lead "approved"
```

### 6.3.1 C3 — post-commit

```
[ ] git log --oneline -1                — commit message matches §8 spec for C3
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm)
[ ] gh run watch                        — Validate Pack workflow green
```

---

## 7. Verification harness — delta evidence

Delta-only re-verification (matching the F-D pattern). The implementer does NOT re-run §4.6 / §4.7 / §4.8 in full. The implementer DOES run a targeted §11 delta harness covering: SKILL distribution propagation; sentinel-write under migration; SKILL Step-0 detection (static check, since interactive PM-chat invocation is out of harness scope); 5-R routing latent-gap closure (static check, plus a fixture with `_v9-backup.md` present); pack-level regression guards.

**All operations within `/tmp/`. Live OT untouched. Live pack repo on `main` untouched.** The implementer's working pack repo is the `v10-dev` worktree; its scripts are the patched ones being tested.

### 7.1 Pre-flight — pack repo state

```bash
cd /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
git status --porcelain        # Expect: empty (post-commit) or only the 4 patched files (pre-commit on staged tree).
git rev-parse HEAD            # Capture for evidence.
PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev   # The patched pack repo.

# Confirm live pack repo on main is untouched:
git -C "$PACK" rev-parse main
```

### 7.2 Fixture base directory

```bash
mkdir -p /tmp/v10-feff-fixtures
cd /tmp/v10-feff-fixtures
```

### 7.3 §11.1 — Fresh init: SKILL distribution propagation harness

Verifies the patched pm-startup `SKILL.md` (with new Step 0) is correctly distributed to all three tool-specific skill directories by `init-project.sh` S4.

```bash
mkdir -p /tmp/v10-feff-fixtures/fresh-init
cd /tmp/v10-feff-fixtures/fresh-init
git init -q
echo "# fresh-init test fixture" > README.md
git add README.md && git commit -q -m "seed"

PACK="$PACK" "$PACK/scripts/init-project.sh" . \
  > /tmp/v10-feff-fixtures/fresh-init.stdout.txt 2> /tmp/v10-feff-fixtures/fresh-init.stderr.txt
echo "init-project.sh exit: $?"

# Assert: pm-startup SKILL.md present in all 3 tool dirs.
for tool in claude codex gemini; do
  f=".${tool}/skills/pm-startup/SKILL.md"
  if [[ -f "$f" ]]; then
    echo "OK: $f present"
    grep -q '^## Step 0 — Check for pending one-shot procedures' "$f" \
      && echo "OK: $f has Step 0" \
      || echo "FAIL: $f missing Step 0"
    grep -q 'POSTRUN-PENDING: Procedure 5-S' "$f" \
      && echo "OK: $f has 5-S detection" \
      || echo "FAIL: $f missing 5-S detection"
    grep -q 'PROMPT-RECON-PENDING: Procedure 5-R' "$f" \
      && echo "OK: $f has 5-R detection" \
      || echo "FAIL: $f missing 5-R detection"
  else
    echo "FAIL: $f missing"
  fi
done
```

### 7.4 §11.2 — Migration sentinel-write harness (state B-style synthetic v9.3 fixture)

Verifies `migrate-v9-to-v10.sh` S7 writes the postrun-pending sentinel to the expected path.

```bash
# Build a v9.3-shaped fixture (re-uses the §7 of V10-F-D-PLAN.md pattern).
mkdir -p /tmp/v10-feff-fixtures/v9-state-B
cd /tmp/v10-feff-fixtures/v9-state-B
git init -q
V93_PACK=/tmp/v10-feff-fixtures/v9-pack-source
git clone -q --branch v9.3 /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev "$V93_PACK" 2>/dev/null \
  || git -C "$V93_PACK" fetch --tags origin 2>/dev/null
cp -r "$V93_PACK/project-template/." .
mkdir -p docs/pack
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
git add -A && git commit -q -m "v9.3 baseline"

# Run patched v10-dev migration.
PACK="$PACK" "$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/v10-feff-fixtures/state-B.stdout.txt 2> /tmp/v10-feff-fixtures/state-B.stderr.txt
echo "migrate exit: $?"

# Assert: sentinel present at expected path.
[[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] \
  && echo "OK: postrun-pending sentinel present" \
  || echo "FAIL: postrun-pending sentinel missing"

# Assert: stdout reports the sentinel write.
grep -q 'wrote post-migration housekeeping sentinel' /tmp/v10-feff-fixtures/state-B.stdout.txt \
  && echo "OK: stdout reports sentinel write" \
  || echo "FAIL: stdout missing sentinel write line"

# Assert: report.md mentions Procedure 5-S in Next steps.
grep -q 'Procedure 5-S' .pack-migration-backup/v9.3-to-v10.0/report.md \
  && echo "OK: report.md mentions Procedure 5-S" \
  || echo "FAIL: report.md missing Procedure 5-S bullet"
```

### 7.5 §11.3 — Static checks: METHODOLOGY procedure body + SKILL routing present

Procedure 5-S is detected and run by an interactive PM-chat session, which is out of harness scope. The harness instead asserts the static artifacts that interactive PM-chat invocation depends on.

```bash
# Procedure body present in pack source METHODOLOGY:
grep -q '^### Procedure 5-S — Post-migration housekeeping' "$PACK/supporting-docs/METHODOLOGY.md" \
  && echo "OK: Procedure 5-S in pack METHODOLOGY" \
  || echo "FAIL: Procedure 5-S missing in pack METHODOLOGY"

# Procedure body propagated to fresh-init project copy:
grep -q '^### Procedure 5-S — Post-migration housekeeping' \
  /tmp/v10-feff-fixtures/fresh-init/docs/pack/METHODOLOGY.md \
  && echo "OK: Procedure 5-S in fresh-init project METHODOLOGY" \
  || echo "FAIL: Procedure 5-S missing in fresh-init project METHODOLOGY"

# Procedure body propagated to migrated project:
grep -q '^### Procedure 5-S — Post-migration housekeeping' \
  /tmp/v10-feff-fixtures/v9-state-B/docs/pack/METHODOLOGY.md \
  && echo "OK: Procedure 5-S in migrated project METHODOLOGY" \
  || echo "FAIL: Procedure 5-S missing in migrated project METHODOLOGY"

# SKILL Step 0 present in all three tool dirs of the migrated project:
for tool in claude codex gemini; do
  f="/tmp/v10-feff-fixtures/v9-state-B/.${tool}/skills/pm-startup/SKILL.md"
  if [[ -f "$f" ]]; then
    grep -q '^## Step 0 — Check for pending one-shot procedures' "$f" \
      && echo "OK: migrated $f has Step 0" \
      || echo "FAIL: migrated $f missing Step 0"
  fi
done
```

### 7.6 §11.4 — 5-R latent-gap closure harness

Builds a synthetic post-migration fixture that has `_v9-backup.md` present (the 5-R trigger), then asserts the SKILL Step 0 would route to 5-R.

```bash
mkdir -p /tmp/v10-feff-fixtures/v9-customized
cd /tmp/v10-feff-fixtures/v9-customized
git init -q
cp -r "$V93_PACK/project-template/." .
mkdir -p docs/pack docs/pack/prompts
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
# Synthesize a customized PROMPT-TEMPLATES.md that diverges from the v9.3 baseline,
# so migrate's S6 will preserve it as _v9-backup.md.
if [[ -f "$V93_PACK/project-template/supporting-docs/PROMPT-TEMPLATES.md" ]]; then
  cp "$V93_PACK/project-template/supporting-docs/PROMPT-TEMPLATES.md" supporting-docs/PROMPT-TEMPLATES.md
elif [[ -f "$V93_PACK/supporting-docs/PROMPT-TEMPLATES.md" ]]; then
  mkdir -p supporting-docs
  cp "$V93_PACK/supporting-docs/PROMPT-TEMPLATES.md" supporting-docs/PROMPT-TEMPLATES.md
fi
echo "" >> supporting-docs/PROMPT-TEMPLATES.md
echo "# divergent customization for 5-R harness" >> supporting-docs/PROMPT-TEMPLATES.md
git add -A && git commit -q -m "v9.3 customized baseline"

PACK="$PACK" "$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/v10-feff-fixtures/v9-customized.stdout.txt 2> /tmp/v10-feff-fixtures/v9-customized.stderr.txt
echo "migrate exit: $?"

# Assert: _v9-backup.md present.
[[ -f docs/pack/prompts/_v9-backup.md ]] \
  && echo "OK: _v9-backup.md present (5-R trigger condition)" \
  || echo "INFO: _v9-backup.md absent — divergence not detected by migrate (acceptable; depends on v9.3 baseline content)"

# Assert: postrun-pending also present (5-S always fires).
[[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] \
  && echo "OK: postrun-pending also present (5-S unconditional)"

# Assert: SKILL Step 0 (in all 3 tool dirs) explicitly checks for both triggers.
for tool in claude codex gemini; do
  f=".${tool}/skills/pm-startup/SKILL.md"
  if [[ -f "$f" ]]; then
    grep -q 'docs/pack/prompts/_v9-backup.md' "$f" \
      && echo "OK: $f checks for 5-R trigger" \
      || echo "FAIL: $f missing 5-R trigger check"
  fi
done
```

### 7.7 §11.5 — Pack-level regression guards

```bash
cd "$PACK"
python3 scripts/validate-pack.py
echo "validate-pack.py exit: $?"           # Expect: 0

bash scripts/test-detect.sh
echo "test-detect.sh exit: $?"             # Expect: 0; reports 34/34 passing
```

### 7.8 §11.6 — Cleanup

```bash
rm -rf /tmp/v10-feff-fixtures
ls -ld /tmp/v10-feff-fixtures 2>&1
# Expect: "No such file or directory"
```

### 7.9 Evidence destination — append §11 to V10-PHASE-4-VERIFICATION.md

The implementer appends the new section to `maintenance-docs/V10-PHASE-4-VERIFICATION.md` AFTER C2 has committed and the §7 harness has run. The §11 append is **commit C3**, separate from the behavioral patch C2.

**Section template (paste verbatim, fill bracketed values):**

```markdown
## §11 Delta verification — F-E + F-F patch

**Date:** [ISO 8601 UTC timestamp]
**Patch commits:** [C1 short SHA] (design + plan docs), [C2 short SHA] (4-file behavioral patch)
**Scope:** Delta-only re-verification per project-lead Decision 2 (F-D precedent). Confirms the patched migration script writes the postrun-pending sentinel; the patched pm-startup SKILL gains Step 0 detection for both 5-S and 5-R triggers; the new METHODOLOGY Procedure 5-S section is present and propagates to migrated/init projects. Full §4.6 / §4.7 / §4.8 NOT re-run; historical evidence retained as-was.

### §11.1 Fresh init — SKILL distribution propagation (state D)

- Fixture: `/tmp/v10-feff-fixtures/fresh-init/`.
- init-project.sh exit: [0].
- `.claude/skills/pm-startup/SKILL.md` Step 0 present: [OK].
- `.codex/skills/pm-startup/SKILL.md` Step 0 present: [OK].
- `.gemini/skills/pm-startup/SKILL.md` Step 0 present: [OK].
- All three SKILLs include POSTRUN-PENDING (5-S) and PROMPT-RECON-PENDING (5-R) detection blocks: [OK].

### §11.2 Migration sentinel-write (synthetic v9.3 → v10)

- Fixture: `/tmp/v10-feff-fixtures/v9-state-B/` (v9.3 scaffold from v9.3-tag pack).
- migrate-v9-to-v10.sh exit: [0].
- `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` present post-migration: [OK].
- stdout reports sentinel write: [OK].
- `.pack-migration-backup/v9.3-to-v10.0/report.md` Next-steps mentions Procedure 5-S: [OK].

### §11.3 Static-artifact propagation

- Procedure 5-S section in pack METHODOLOGY.md: [OK].
- Procedure 5-S section in fresh-init project `docs/pack/METHODOLOGY.md`: [OK].
- Procedure 5-S section in migrated project `docs/pack/METHODOLOGY.md`: [OK].
- SKILL Step 0 in all 3 tool dirs of the migrated project: [OK].

### §11.4 5-R latent-gap closure

- Fixture: `/tmp/v10-feff-fixtures/v9-customized/` (synthetic divergent PROMPT-TEMPLATES).
- migrate-v9-to-v10.sh exit: [0].
- `_v9-backup.md` trigger condition: [present / absent — depends on v9.3 baseline; either is acceptable for this test].
- `postrun-pending` sentinel always present: [OK].
- All 3 tool-dir SKILLs check for 5-R trigger (`docs/pack/prompts/_v9-backup.md`) in Step 0: [OK].
- **Latent gap closure confirmed:** 5-R routing is now reachable via SKILL Step 0 (previously surfaced only via MIGRATION-v9-to-v10.md prose).

### §11.5 Pack-level regressions

- `python3 scripts/validate-pack.py` exit: [0].
- `bash scripts/test-detect.sh` exit: [0]; reports [34/34] passing.

### §11.6 Sanitization

All fixtures synthetic — built under `/tmp/v10-feff-fixtures/` from the v9.3-tag pack source. No OT content involved. No sanitization required per §6.7.7 rules. Live OT clone untouched (no OT_LIVE rev-parse occurred during this delta).

### §11.7 Pass / fail summary

| Check | Result |
|---|---|
| Fresh init SKILL distribution (3 tool dirs, both detection blocks) | [PASS] |
| Migration sentinel write (postrun-pending at expected path) | [PASS] |
| Migration report Next-steps mentions Procedure 5-S | [PASS] |
| Procedure 5-S body in pack METHODOLOGY | [PASS] |
| Procedure 5-S body propagates to fresh-init project | [PASS] |
| Procedure 5-S body propagates to migrated project | [PASS] |
| SKILL Step 0 detects 5-S trigger | [PASS] |
| SKILL Step 0 detects 5-R trigger (latent-gap closure) | [PASS] |
| validate-pack.py | [PASS exit 0] |
| test-detect.sh | [PASS 34/34] |

**Outcome:** F-E + F-F jointly resolved via Procedure 5-S. Latent 5-R routing gap closed as a side benefit.
```

---

## 8. Commit messages (proposed)

Per CLAUDE.md commit message format. Pack version is v10 (current major).

### 8.1 C1 — `docs:` design + plan documents

```
docs: v10 — V10-F-E-F-F design + plan (Procedure 5-S post-migration housekeeping)

Architecture and implementation plan for resolving F-E (stale v9 pack-version
markers in project-internal docs) and F-F (unfilled trinity placeholders)
jointly via a new METHODOLOGY one-shot procedure (Procedure 5-S), a sentinel
written by migrate-v9-to-v10.sh S7, and a new pre-Step-1 routing block in the
pm-startup SKILL.

Project-lead approved both documents; this commit lands them in git ahead of
the behavioral patch.

Files:
  maintenance-docs/V10-F-E-F-F-DESIGN.md  — architect pass (701 lines)
  maintenance-docs/V10-F-E-F-F-PLAN.md    — planner pass

BD-NNN to be assigned at C-V10-18 BACKLOG sweep.
```

### 8.2 C2 — `feat:` 4-file behavioral patch

```
feat: v10 — Procedure 5-S post-migration housekeeping (F-E + F-F)

Resolves F-E (stale "AI Agent Config Pack: v9" markers in project-internal
docs, typically docs/project/STATUS.md) and F-F (unfilled trinity placeholders
[PROJECT_NAME] / [PLATFORM_TARGETS] / [TRANSPORT] / [PLATFORM_*] / Active-
skills line) jointly via a new METHODOLOGY one-shot procedure triggered at
PM-chat startup. Same shape as the existing Procedure 5-R precedent.

Implements V10-F-E-F-F-DESIGN.md (architect 2026-04-29) and
V10-F-E-F-F-PLAN.md (planner 2026-04-29).

Files touched:
  supporting-docs/METHODOLOGY.md            — insert Procedure 5-S section
                                              after Procedure 5-R (Part 7)
  scripts/migrate-v9-to-v10.sh              — S7 stage: write postrun-pending
                                              sentinel; add 5-S bullet to
                                              report's Next-steps
  project-template/skills/pm-startup/SKILL.md — insert Step 0 block detecting
                                              both 5-S and 5-R triggers
                                              (closes latent 5-R routing gap)
  supporting-docs/MIGRATION-v9-to-v10.md    — Step 4: orientation bullet
                                              describing Procedure 5-S

Side benefit: closes a latent gap in the existing Procedure 5-R routing
(previously surfaced only via MIGRATION-v9-to-v10.md prose; now in the SKILL).

Trinity rule: clean — no trinity edits required (procedure body lives in
METHODOLOGY which trinity already references).

Verification: §11 delta-evidence harness in V10-PHASE-4-VERIFICATION.md
(separate docs: commit) — fresh init SKILL distribution, migration sentinel
write, static artifact propagation, 5-R latent-gap closure, pack-level
regression guards. validate-pack.py exits 0; test-detect.sh 34/34.

BD-NNN to be assigned at C-V10-18 BACKLOG sweep.
```

### 8.3 C3 — `docs:` §11 delta evidence

```
docs: v10 — V10-PHASE-4-VERIFICATION §11 delta evidence (F-E + F-F)
```

---

## 9. Risks and assumptions

### 9.1 Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | The Procedure 5-S body in METHODOLOGY mentions "PROMPT-TEMPLATES" indirectly via the `[PLATFORM_*]` whitelist, which could trip `init-project.sh`'s blast_radius_sweep grep. | Very low — Procedure 5-S body does NOT mention PROMPT-TEMPLATES. The whitelist references `[PLATFORM_*]` placeholders by trinity name; PROMPT-TEMPLATES is unrelated. | Verified by §3.5 cross-reference audit. The F-D `--exclude='METHODOLOGY.md'` exclusion remains in place; even if a future METHODOLOGY edit added a PROMPT-TEMPLATES reference, the sweep would skip METHODOLOGY. |
| R2 | The new "Step 0" in pm-startup SKILL might break a hardcoded reference to Step 1/2/3/etc. in another doc. | Very low — only one cross-reference exists pack-wide (`BACKLOG.md` line 561, which references "METHODOLOGY.md (Procedure 1 step 6)" — METHODOLOGY procedure step, not SKILL step). Existing SKILL Steps 1–6 are not renumbered. | Verified by §3.5 audit. |
| R3 | The sentinel path `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` collides with another existing file or fixture. | Very low — the `.pack-migration-backup/` directory is gitignored (per pack convention) and is only created by migrate-v9-to-v10.sh S0. The `postrun-pending` filename is novel. | Verified by `find . -name postrun-pending` against the pack repo and existing fixtures: 0 hits. |
| R4 | The 4-file C2 commit might accidentally include unrelated changes (e.g., editor cruft, automatic formatters). | Low — implementer follows §6.2 git status / git diff --name-only checklist. | Pre-commit checklist explicitly enumerates the 4 expected files. |
| R5 | The Procedure 5-S body's "tolerant scan" semantics depend on PM-chat-side behavior that is not validated by any automated test. The harness can only check static presence of the procedure text, not its runtime execution. | Medium — known limitation. | Same risk shape as Procedure 5-R, which is also PM-chat-runtime. The procedure body is terse enough that it can be reviewed for correctness; runtime correctness will be validated organically on the next OT migration / kickoff cycle. |
| R6 | The sentinel never gets cleaned up if the developer never runs `/pm-startup` (e.g., they migrate then immediately run `/coder` or similar). | Low — the sentinel is harmless dormant data; it persists until `/pm-startup` runs. | Sentinel is small (~0 bytes); no adverse effect. The `.pack-migration-backup/` directory cleanup at MIGRATION Step 7 also removes the sentinel. |
| R7 | OQ-1 mandates simpler standalone Q&A for Active-skills (NOT Procedure 7). The Task B description in the procedure body must be precise about this — if it instead says "invoke Procedure 7," runtime PM-chat behavior diverges from project-lead intent. | Low — explicit decision recorded. | The procedure body in §5.1 explicitly says "(NOT the full Procedure 7 kickoff flow)". Verified by grep check in §5.1's verification block (implicit — the text is what it is). |
| R8 | CI (`Validate Pack` GitHub Actions workflow) does not exercise migration script or pm-startup SKILL behavior — only validate-pack.py. The §7 harness must be run locally; CI will not catch a script regression. | Medium — known limitation of existing CI shape (matches F-D's R5). | The §7 harness IS the verification. Project lead reviews evidence; CI is regression backstop only. |

### 9.2 Assumptions

| # | Assumption | Resolution |
|---|---|---|
| A1 | `BACKUP_DIR` in scope at line 449 of `migrate-v9-to-v10.sh` (where the sentinel `touch` lands). | **Confirmed** — declared at line 24 (`readonly BACKUP_DIR=...`); referenced at lines 162, 314, 325, 340, 354–358, 412, 425. The S7 stage writes `report` to `$BACKUP_DIR/report.md` at line 412, so `BACKUP_DIR` is unambiguously in scope at line 449 where the new `touch` lands. |
| A2 | `say` is the right log helper for the sentinel-write status message. | **Confirmed** — `say` is the script's standard stdout helper (line 30); used throughout the file including S7 (line 409, line 452). |
| A3 | The pm-startup SKILL has no YAML/markdown reference that breaks when a new H2 (`## Step 0 ...`) is inserted before the existing H2 (`## Step 1 ...`). | **Confirmed** — file inspected (81 lines; no SKILL-internal cross-references between steps; no TOC; no anchor-link references). |
| A4 | The MIGRATION Step 4 list ordering (new bullet at top vs. inline) does not break any cross-reference. | **Confirmed** — no other doc references MIGRATION Step 4 by bullet position. Insertion at top of list (per design "always runs" semantic) is purely an editorial choice, not a structural one. |
| A5 | The v9.3 tag is resolvable for §7.4 / §7.6 fixture builds. | **Confirmed** — same assumption as F-D's A7; if the implementer's clone is missing v9.3, fix before harness runs. |
| A6 | `init-project.sh` S4 distributes the patched pm-startup SKILL.md to all three tool dirs. | **Confirmed** — verified at lines 295–305 of `init-project.sh`. The `for skill_dir in "$PACK/project-template/skills"/*/; do` loop iterates pm-startup; the inner `for tool in claude codex gemini` distributes. The patched SKILL.md is read fresh on each invocation. |
| A7 | `migrate-v9-to-v10.sh` S2 stage propagates skill changes (in case the implementer wants to confirm migration also distributes the patched SKILL). | **Confirmed** — `stage_s2_skills` (lines ~210–230 area) re-distributes skills from `$PACK/project-template/skills/` to `.${tool}/skills/`, matching init-project.sh S4 behavior. The patched SKILL.md will land in migrated projects. |

### 9.3 Flag-backs (conditions where implementer pauses)

The implementer MUST flag-back to the parent agent before proceeding if:

- **FB-1.** Any §3.5 cross-reference grep returns a hit not anticipated in this plan (e.g., a script or doc references `Procedure 5-S` or `postrun-pending` outside the four expected locations).
- **FB-2.** The v9.3 tag is not resolvable from the implementer's pack clone (blocks §7.4 / §7.6 fixture builds).
- **FB-3.** Any §11 harness assertion fails. Do NOT commit C2 before the failure is diagnosed.
- **FB-4.** `validate-pack.py` exits non-zero post-C2 commit. Roll back per §6.2.1; do not proceed to C3.
- **FB-5.** Trinity-rule `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns non-empty after C2. The plan asserts no trinity edits — any trinity diff is unexpected.
- **FB-6.** `test-detect.sh` reports anything other than 34/34 passing. Detection logic is not in scope of this patch; any change is unexpected.
- **FB-7.** The fresh-init harness or migration harness exits non-zero. Both should exit 0.
- **FB-8.** The patched migrate-v9-to-v10.sh's report.md does not include the new "Procedure 5-S" Next-steps bullet, OR includes it but the existing 5-R bullet is missing (regression on existing routing).

---

## 10. Cascading-effect check (per the prompt's §8)

The prompt explicitly enumerated cascading-effect checks. Each is verified:

1. **Will Procedure 5-S body added to METHODOLOGY trigger validate-pack.py Check 6 (PROMPT-AUTHORING.md absence)?**
   **No.** `check_prompts_directory()` (validate-pack.py line 285) inspects `project-template/docs/pack/prompts/`, not METHODOLOGY. METHODOLOGY is not in the prompts/ directory and is not in scope for Check 6.

2. **Will the sentinel file path conflict with any existing fixture or check?**
   **No.** The path `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` is novel (verified by §3.5 audit). The `.pack-migration-backup/` directory is gitignored per pack convention. No existing test, fixture, or check references the `postrun-pending` filename.

3. **Will the SKILL Step 0 pre-Step-1 placement break existing numbered step references?**
   **No.** Existing Steps 1–6 are NOT renumbered — they keep numbers 1–6. The new Step 0 inserts before Step 1 with its own number. No other doc in the pack references pm-startup steps by number; the only `pm-startup.*step` cross-reference (`BACKLOG.md` line 561) is to METHODOLOGY's Procedure 1 step 6, not the SKILL.

4. **Will the new Procedure 5-S in METHODOLOGY interact with the F-D fix's blast_radius_sweep PROMPT-TEMPLATES exclusion?**
   **No.** Procedure 5-S body does not mention PROMPT-TEMPLATES. The F-D `--exclude='METHODOLOGY.md'` was added because Procedure 5-R legitimately references PROMPT-TEMPLATES (lines 1209/1211). The exclusion remains in place and is unaffected by Procedure 5-S. Even if a future edit adds a PROMPT-TEMPLATES reference to METHODOLOGY for any reason, the exclusion already covers it.

5. **Side-cascade:** the SKILL Step 0 reads the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) at project root. The F-D fix moved METHODOLOGY to `docs/pack/METHODOLOGY.md`, NOT the trinity files. Trinity remains at project root. The Step 0 grep paths (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — relative paths) resolve correctly post-F-D. **No conflict.**

6. **Side-cascade:** the SKILL Step 4 (RAG ingest freshness check) already references `docs/pack/METHODOLOGY.md` — this was set correctly by the F-D fix. The new Step 0 does not interact with Step 4.

7. **Side-cascade:** the existing latent 5-R routing gap (architect §5.1) is closed by the same Step 0 block. This is a side benefit, not a separate edit. No new file or commit required.

---

## 11. Self-check

- **Can the implementer execute the 4 edits and post-fix verification without further architectural calls?** **Yes** — every edit has its file, line range, before/after snippet, and grep verification check. The Procedure 5-S body, the migration script bash, the SKILL Step 0 block, and the MIGRATION bullet are all written verbatim (not pseudocode). The §7 harness is copy-pasteable bash. No design questions remain.
- **Is the Procedure 5-S body actually correct (not pseudocode) and terse?** **Yes** — ~35 lines including the task table; references TRIO and Procedure 7 by name without restating their bodies; explicitly per OQ-1 says "NOT the full Procedure 7 kickoff flow"; per OQ-2 says "read from `docs/pack/METHODOLOGY.md` first 5 lines"; per OQ-3 lists `docs/project/STATUS.md` → `docs/STATUS.md` → `STATUS.md` priority; describes both tasks with "nothing to do" tolerant exits per §6.4 of design; final step deletes sentinel per §4.1 of design.
- **Is the SKILL Step 0 actually correct?** **Yes** — two if-checks (5-S sentinel + 5-R `_v9-backup.md`); explicit routing-target names; explicit "do NOT run standard sequence yet"; explicit resume path; no-op semantics if neither file exists.
- **Is the migration script S7 sentinel-write actually correct?** **Yes** — `touch "$BACKUP_DIR/postrun-pending"` after the report heredoc closes, before `write_sentinel "S7"`; with a `say` status message; comment explains why. Position is correct: report-write completes first, then sentinel, then S7-stage sentinel — order preserves "S7 sentinel only fires after S7 work completes" property.
- **OQ-1..OQ-5 all addressed in the procedure body?** **Yes** — explicitly recorded inline at §5.1 (the procedure body and edit specifications); cross-referenced in §0 D2..D6.
- **Trinity rule respected?** **Yes** — verified no trinity edits required (design §7); §6.2 checklist includes a `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` empty-diff guard.
- **Cascading effects with F-D / F-C work?** **Yes** — checked in §10. No conflicts; sentinel path under `.pack-migration-backup/v9.3-to-v10.0/` confirmed safe (matches F-D's backup-directory pattern); SKILL Step 4's `docs/pack/METHODOLOGY.md` path remains correct under F-D's fix; no PROMPT-TEMPLATES blast_radius interaction.

---

## 12. Summary

**Decision:** 3-commit shape (C1 docs, C2 atomic 4-file behavioral patch, C3 docs evidence) following the F-D pattern.

**Edits in C2:**
1. `supporting-docs/METHODOLOGY.md` — insert Procedure 5-S section after Procedure 5-R (Part 7), ~35 lines.
2. `scripts/migrate-v9-to-v10.sh` S7 — write `postrun-pending` sentinel; add 5-S bullet to report's Next-steps, ~9 lines.
3. `project-template/skills/pm-startup/SKILL.md` — insert Step 0 block detecting both 5-S and 5-R triggers, ~18 lines. Closes latent 5-R routing gap.
4. `supporting-docs/MIGRATION-v9-to-v10.md` Step 4 — insert orientation bullet for Procedure 5-S, ~12 lines.

**Verification:** five-section §11 harness under `/tmp/v10-feff-fixtures/` — fresh-init SKILL distribution; migration sentinel write; static artifact propagation; 5-R latent-gap closure; pack-level regression guards. validate-pack.py exit 0; test-detect.sh 34/34. All within /tmp; live OT and live pack-on-main untouched.

**Trinity rule:** clean (no trinity edits).

**Project-lead decisions baked-in:** D1..D6 (design approved; OQ-1 simpler standalone Q&A for Active-skills; OQ-2 METHODOLOGY first 5 lines for pack version; OQ-3 STATUS.md priority list; OQ-4 both tasks ship at v10.0; OQ-5 defer one-shot-procedure pattern formalization).

**Flag-backs surfaced:** FB-1..FB-8 in §9.3.

**BD entry:** combined F-E + F-F, assigned at C-V10-18 BACKLOG sweep (out of plan scope).

**Side benefit:** closes a latent gap in the existing Procedure 5-R routing — previously surfaced only via MIGRATION-v9-to-v10.md prose, now reachable via SKILL Step 0.
