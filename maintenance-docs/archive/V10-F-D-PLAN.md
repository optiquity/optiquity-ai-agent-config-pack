# V10-F-D-PLAN — METHODOLOGY.md canonical-location patch (planner pass)

**Author:** pack-planner (v10.0 patch — F-D + F-C joint resolution)
**Date:** 2026-04-29
**Implements:** `maintenance-docs/V10-F-D-DESIGN.md` (architect pass, 2026-04-29; project-lead approved)
**Status:** Draft — planner output. Read-only on every pack source. No edits, no commits. Implementer (parent Pack Chat) executes after project-lead approval of this plan.
**Scope:** v10.0 ship-blocker patch resolving F-D (trinity-vs-scripts contradiction) and F-C (legacy `docs/pack/METHODOLOGY.md` not cleaned up by migration). Per V10-F-D-DESIGN.md §6, the two are unified into one cohesive script edit and one BD-NNN entry (assigned at C-V10-18 BACKLOG sweep).

---

## 0. How to read this plan

V10-F-D-DESIGN.md is the authoritative input. The decision (canonical = `docs/pack/METHODOLOGY.md`), the rationale, and the cascade list are baked-in here and not re-litigated. This plan adds:

- Per-file edit specifications (line numbers verified against current tip of `v10-dev`).
- Concrete bash for the migration script S5 stage and init-project.sh S6 stage (not pseudocode).
- Commit-shape decision and edit ordering.
- Verification harness — fixture builds, post-fix checks, evidence-block template.
- Per-commit verification checklist.
- Resolution of OQ-F-D-1, OQ-F-D-2, OQ-F-D-5.

The implementer can execute this plan literally without further architectural calls.

---

## 1. Goal and BD items addressed

**Goal:** Restore implementation to match V10-DESIGN.md by writing METHODOLOGY.md to `docs/pack/METHODOLOGY.md` (not project root) in both `init-project.sh` (fresh installs) and `migrate-v9-to-v10.sh` (v9.3 → v10 migration), update the user-facing migration prose to match, and update the `project-template/README.md` two prose lines that still reference root.

**BD items in scope:**
- F-D + F-C combined → one BD-NNN (assigned at C-V10-18 BACKLOG sweep per project-lead Decision 3).
- This plan does NOT file the BD entry; it produces the edits that the BD entry's "Resolution" line will reference.

---

## 2. Commit shape decision

**Decision: atomic single commit.**

**Rationale:**

1. **Coupling is tight across the five edits.** The migration script's S5 write target, the init-project.sh S6 write target, the user-facing MIGRATION doc's S5 stage description, and `project-template/README.md`'s setup hint all describe the same thing (where METHODOLOGY.md lands). Splitting the commit into "scripts first, prose second" leaves an intermediate commit where the migration script has been corrected but the user-facing doc still tells operators it lands at root — actively misleading anyone running mid-window.
2. **`validate-pack.py` does not assert the METHODOLOGY install path.** Per `grep METHODOLOGY scripts/validate-pack.py`, the only mention is a comment about `supporting-docs/METHODOLOGY.md § Prompt Authoring Principles`. No check enforces "METHODOLOGY at root" or "METHODOLOGY at docs/pack/" — splitting the commit therefore offers no validate-pack.py-driven gating value.
3. **Trinity rule is not engaged.** The trinity already says `docs/pack/METHODOLOGY.md` (per V10-F-D-DESIGN.md §4.3 / §7). No trinity edits in this patch — no trinity-symmetry gate to satisfy commit-by-commit.
4. **Touch surface is small (5 files, ~25 lines of diff).** A single coherent commit is easier to review than two thin ones.
5. **Diff atomicity matches the BD-NNN scope.** F-D + F-C resolve as one fix per design §6; one commit per fix preserves clean git-blame lineage to the BD entry.

**Rejected alternative — sequenced commits (Commit A: scripts; Commit B: docs):** No technical benefit; introduces a misleading intermediate state; doubles the commit-approval overhead; risks one of the two getting forgotten.

---

## 3. Affected files (complete list)

### 3.1 Files edited (5)

| # | File | Edit area | Purpose |
|---|---|---|---|
| 1 | `scripts/migrate-v9-to-v10.sh` | S5 stage, lines 347–353 | Backup both possible source locations; write to `docs/pack/METHODOLOGY.md`; remove stale root copy if present. |
| 2 | `scripts/init-project.sh` | S6 stage, lines 368–375 | Write to `docs/pack/METHODOLOGY.md`; warn (do not delete) if a stale root copy exists for `existing-*` classes. Update comment to cite V10-DESIGN.md §7.6. |
| 3 | `supporting-docs/MIGRATION-v9-to-v10.md` | Line 150 (S5 stage table cell) | Change "PM-CHAT.md at `docs/pack/`; METHODOLOGY.md at project root" to uniform `docs/pack/`. |
| 4 | `project-template/README.md` | Line 12 (`cp` example) | Change destination to `docs/pack/METHODOLOGY.md`; add `mkdir -p docs/pack` before the `cp`. |
| 5 | `project-template/README.md` | Line 37 (prose: "docs copied individually during setup (METHODOLOGY.md)") | Update prose to reflect docs/pack destination. |

### 3.2 Files NOT edited (verified)

- `project-template/CLAUDE.md` line 275 — already says `docs/pack/METHODOLOGY.md`. Trinity-rule clean.
- `project-template/AGENTS.md` line 198 — already aligned.
- `project-template/GEMINI.md` line 229 — already aligned.
- `project-template/skills/pm-startup/SKILL.md` line 45 — already runs `git log ... -- docs/pack/METHODOLOGY.md`. (Latent defect under root convention is implicitly fixed by this patch.)
- `maintenance-docs/V10-DESIGN.md` — already canonical (`docs/pack/`); this patch brings impl into line with V10-DESIGN, not the other way.
- `scripts/validate-pack.py` — no path assertion to update.
- `CLAUDE.md` (pack repo) and `README.md` (pack repo) — neither references METHODOLOGY install path.
- `project-template/.mcp.json.example` — line 3 mentions METHODOLOGY but no path. No edit. (See OQ-F-D-5 resolution §10.3.)
- `supporting-docs/SETUP-NEW.md` line 311 — "Ingest METHODOLOGY.md into the RAG index" — natural-language instruction, no hardcoded path. No edit.
- `project-template/skills/pm-startup/SKILL.md` line 45 — `git log -1 --format="%H %cd" --date=short -- docs/pack/METHODOLOGY.md` — already correct; **the latent defect this fix repairs is here.**
- `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (existing committed evidence) — historical evidence captured against the root-canonical implementation; per project-lead Decision 2 (delta-only re-verification), historical sections are NOT rewritten. New §10 "Delta verification" appended (see §7 of this plan).

### 3.3 Files where assertion paths require an update (V10-PHASE-4-VERIFICATION-PLAN-v2.md)

`maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` carries METHODOLOGY-path checks at the following lines (verified by grep):

| Line | Context | Current text | Action |
|---|---|---|---|
| 1251 | §6.6 §4.4 post-migration verification | `[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: METHODOLOGY.md"` | Already uses `docs/pack/`. No edit. |
| 1252 | §6.6 §4.4 Procedure 7 grep | `grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md ...` | Already uses `docs/pack/`. No edit. |
| 1289 | §6.7 pass/fail row | `docs/pack/METHODOLOGY.md exists` | Already uses `docs/pack/`. No edit. |
| 1611 | §6.5.8 §4.6 OT post-migration | `[[ -f docs/pack/METHODOLOGY.md ]] \|\| [[ -f METHODOLOGY.md ]] && echo "OK: METHODOLOGY.md present (one of the two paths)"` | **Edit:** drop the `\|\| [[ -f METHODOLOGY.md ]]` clause; canonical is now docs/pack only. |
| 1612 | §6.5.8 §4.6 Procedure 7 grep | `grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md METHODOLOGY.md 2>/dev/null` | **Edit:** remove second arg `METHODOLOGY.md`. |
| 1662 | §6.5.9 pass/fail row | `METHODOLOGY.md present (either path)` | **Edit:** change to `docs/pack/METHODOLOGY.md present`. |

These three edits to V10-PHASE-4-VERIFICATION-PLAN-v2.md are **optional but recommended** for the same atomic commit. They are doc-hygiene only — V10-PHASE-4-VERIFICATION-PLAN-v2.md is a reference plan, not a script the implementer reruns. Treating them as in-scope keeps the patch fully self-consistent.

**Recommendation:** include the V10-PHASE-4-VERIFICATION-PLAN-v2.md edits in the same commit. Total touch surface becomes 6 files; coherence improves; no risk introduced.

### 3.4 Cross-reference audit (no hits found)

- `@METHODOLOGY` / `@docs/pack/METHODOLOGY` / `@METHODOLOGY.md` patterns: zero hits across pack content (verified by recursive grep over `*.md`, `*.toml`, `*.json`, `*.sh`). See OQ-F-D-2 §10.2.
- Hardcoded `cp .../METHODOLOGY.md` other than rows 1, 2, 4 above: zero hits in pack content.
- Hardcoded `METHODOLOGY.md` ingest path in any script or skill: zero hits. The `mcp-local-rag` server uses `BASE_DIR` (project root) and recursively indexes; no hardcoded METHODOLOGY-specific path. See OQ-F-D-5 §10.3.

---

## 4. Edit order within the commit

The implementer applies edits in this order. Order is chosen so an interrupted edit session leaves the most-critical correctness in place first.

| Step | File | Why this order |
|---|---|---|
| E1 | `scripts/migrate-v9-to-v10.sh` (S5) | Highest behavioral risk — migration scripts touch real user projects. Land the corrected behavior first. |
| E2 | `scripts/init-project.sh` (S6) | Second-highest behavioral risk — creates fresh projects. |
| E3 | `supporting-docs/MIGRATION-v9-to-v10.md` line 150 | User-facing prose; once scripts are correct, the prose must agree. |
| E4 | `project-template/README.md` line 12 (cp example) | Dev/orientation prose; align with E3. |
| E5 | `project-template/README.md` line 37 (notes line) | Same file as E4; same edit window. |
| E6 (optional) | `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` lines 1611/1612/1662 | Reference-plan hygiene; doc-only. |

`validate-pack.py` is not run incrementally between these edits — it does not gate METHODOLOGY's path. It is run **once** after all edits land, before commit. See §6 per-commit verification checklist.

---

## 5. Per-file edit specifications

### 5.1 Edit E1 — `scripts/migrate-v9-to-v10.sh` S5 stage

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh`
**Lines (current):** 347–353 (within `stage_s5_trinity_splice` function).
**BACKUP_DIR scope:** confirmed in scope — declared at line 24 (`readonly BACKUP_DIR=...`), referenced throughout the function (lines 314, 325, 340–341, 349). `mkdir -p "$BACKUP_DIR/docs/pack"` is already a known idiom in the function (line 340 for PM-CHAT.md).
**Logging style:** function uses `say` (line 308 `say "── S5 — splice-merge trinity + pack docs ──"`, line 356 `say "S5 complete."`). No `info` helper exists in this script; use `say` for emitted messages. `warn` exists for stderr.

**Before (current text, lines 347–353):**

```bash
    # METHODOLOGY.md: pack `supporting-docs/METHODOLOGY.md` → project root `METHODOLOGY.md`.
    if [[ -f METHODOLOGY.md ]]; then
        cp METHODOLOGY.md "$BACKUP_DIR/METHODOLOGY.md"
    fi
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        cp "$PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md
    fi
```

**After (replacement text):**

```bash
    # METHODOLOGY.md: pack `supporting-docs/METHODOLOGY.md` → project `docs/pack/METHODOLOGY.md`
    # per V10-DESIGN.md Part 7 §7.6 S6 (and migration S5 stage spec). Pre-migration
    # state may have METHODOLOGY at docs/pack/ (v9.3 OT-shape), at root (synthetic
    # §4.4-shape), at both (mid-flight v10-dev migration), or neither. Back up
    # whichever is present, write canonical v10 content to docs/pack/, remove any
    # stale root copy. Resolves F-D + F-C jointly.
    if [[ -f docs/pack/METHODOLOGY.md ]]; then
        mkdir -p "$BACKUP_DIR/docs/pack"
        cp docs/pack/METHODOLOGY.md "$BACKUP_DIR/docs/pack/METHODOLOGY.md"
    fi
    if [[ -f METHODOLOGY.md ]]; then
        cp METHODOLOGY.md "$BACKUP_DIR/METHODOLOGY.md"
    fi
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        mkdir -p docs/pack
        cp "$PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
    fi
    if [[ -f METHODOLOGY.md ]]; then
        rm METHODOLOGY.md
        say "  removed stale METHODOLOGY.md at project root (canonical is docs/pack/METHODOLOGY.md; backup at \$BACKUP_DIR/METHODOLOGY.md)"
    fi
```

**State-matrix correctness check (per V10-F-D-DESIGN §5.1):**

| Pre-state | docs/pack/M.md | root M.md | Behavior |
|---|---|---|---|
| A | present | absent | docs/pack backed up; rm skipped (no root file); docs/pack overwritten with v10. |
| B | absent | present | root backed up; mkdir docs/pack; docs/pack written; rm root → fired with say message. |
| C | present | present | both backed up; docs/pack overwritten; root removed → fired. |
| D | absent | absent | nothing backed up; docs/pack written fresh; rm skipped. |

All four states yield post-state: `docs/pack/METHODOLOGY.md` with v10 content; no root copy. Backup contract preserved.

**Verification check for this edit:**

```bash
# After edit, confirm the function body contains the four expected branches:
sed -n '/^stage_s5_trinity_splice/,/^}/p' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh \
  | grep -c 'METHODOLOGY'
# Expect: 7 (the comment line + 6 references in the four branches; verify by visual read).
grep -n 'cp "$PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md' \
     /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh
# Expect: 1 hit, in stage_s5_trinity_splice.
grep -n 'cp "\$PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md' \
     /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/migrate-v9-to-v10.sh
# Expect: 0 hits (the old root-write line is gone).
```

### 5.2 Edit E2 — `scripts/init-project.sh` S6 stage

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/init-project.sh`
**Lines (current):** 368–375 (within `stage_s6_docs_pack` function).
**Logging style:** function uses `say` and `info` (line 44 `info() { printf '  %s\n' "$*"; }`). The S6 stage already uses `info` for skip messages (line 371). The asymmetry per V10-F-D-DESIGN §5.3 — init warns; migrate removes — is preserved here via `info "WARN: ..."` (the script does not have a dedicated `warn-via-info` helper but `info` with a `WARN:` prefix matches local style; alternatively use the script's `warn()` which writes to stderr — see decision below).

**Logging-helper choice:** use `warn` (line 45 — writes to stderr). The stale root METHODOLOGY.md is a real anomaly the operator should notice; stderr surfaces it appropriately. Other "SKIP X (exists)" messages use `info` because they are routine.

**Before (current text, lines 368–375):**

```bash
    # METHODOLOGY.md lives at project root per v10 convention.
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        if [[ "$CLASS" == existing-* && -f "$TARGET/METHODOLOGY.md" ]]; then
            info "SKIP METHODOLOGY.md at root (exists)"
        else
            cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/METHODOLOGY.md"
        fi
    fi
```

**After (replacement text):**

```bash
    # METHODOLOGY.md lives at `docs/pack/METHODOLOGY.md` per V10-DESIGN.md Part 7 §7.6.
    # Source path is `$PACK/supporting-docs/METHODOLOGY.md`; the docs/pack/*.md loop
    # above iterates `$PACK/project-template/docs/pack/`, which does not contain
    # METHODOLOGY — keep this as a separate copy.
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        mkdir -p "$TARGET/docs/pack"
        if [[ "$CLASS" == existing-* && -f "$TARGET/docs/pack/METHODOLOGY.md" ]]; then
            info "SKIP METHODOLOGY.md at docs/pack/ (exists)"
        else
            cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
        fi
    fi
    # Stale-root cleanup advisory: init-project.sh does NOT delete project files
    # (per V10-F-D-DESIGN §5.3 — init warns; migrate-v9-to-v10.sh removes).
    if [[ "$CLASS" == existing-* && -f "$TARGET/METHODOLOGY.md" ]]; then
        warn "stale METHODOLOGY.md at project root — canonical location is docs/pack/METHODOLOGY.md (move or delete manually)"
    fi
```

**Verification check for this edit:**

```bash
# After edit, confirm the loop now writes to docs/pack/ and the warn fires for existing-*.
grep -n 'cp "\$PACK/supporting-docs/METHODOLOGY.md" "\$TARGET/docs/pack/METHODOLOGY.md"' \
     /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/init-project.sh
# Expect: 1 hit, in stage_s6_docs_pack.
grep -n 'cp "\$PACK/supporting-docs/METHODOLOGY.md" "\$TARGET/METHODOLOGY.md"' \
     /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/init-project.sh
# Expect: 0 hits (the old root-write line is gone).
grep -n 'stale METHODOLOGY.md at project root' \
     /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/scripts/init-project.sh
# Expect: 1 hit (the new warn).
```

### 5.3 Edit E3 — `supporting-docs/MIGRATION-v9-to-v10.md` line 150

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md`
**Line (current):** 150 (S5 stage table row).

**Before:**

```
| **S5** | Splice-merge `PLATFORM-SKILLS.md` (via `merge-platform-skills.py`) and the three trinity files (via `merge-trinity.py`) — project-owned `## Custom agents` / `## Custom skills` sections, `### Custom agents` sub-section, and the `**Active skills:**` line are preserved. Pack-owned docs (PM-CHAT.md at `docs/pack/`; METHODOLOGY.md at project root) are copied verbatim from pack. |
```

**After:**

```
| **S5** | Splice-merge `PLATFORM-SKILLS.md` (via `merge-platform-skills.py`) and the three trinity files (via `merge-trinity.py`) — project-owned `## Custom agents` / `## Custom skills` sections, `### Custom agents` sub-section, and the `**Active skills:**` line are preserved. Pack-owned docs (PM-CHAT.md and METHODOLOGY.md, both at `docs/pack/`) are copied verbatim from pack. If a stale root-level `METHODOLOGY.md` is present pre-migration (legacy v10-dev shape), it is backed up and removed. |
```

**Verification check:**

```bash
grep -n "METHODOLOGY.md at project root" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md
# Expect: 0 hits.
grep -n "PM-CHAT.md and METHODOLOGY.md, both at \`docs/pack/\`" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/MIGRATION-v9-to-v10.md
# Expect: 1 hit on line ~150.
```

### 5.4 Edit E4 — `project-template/README.md` line 12

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/README.md`
**Lines (current):** 9–13 (the `cp` example block).

**Before:**

```markdown
Then copy the supporting docs individually (they are not part of this template):

```bash
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your/project/
```
```

**After:**

```markdown
Then copy the supporting docs individually (they are not part of this template). METHODOLOGY.md lives under `docs/pack/` per V10-DESIGN.md Part 7 §7.6 (alongside other pack-distributed docs):

```bash
mkdir -p /path/to/your/project/docs/pack
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your/project/docs/pack/METHODOLOGY.md
```
```

**Verification check:**

```bash
grep -nA3 "Then copy the supporting docs individually" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/README.md
# Expect: shows the new prose; the cp target ends in docs/pack/METHODOLOGY.md.
```

### 5.5 Edit E5 — `project-template/README.md` line 37

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/README.md`
**Line (current):** 37 (within Directory boundary rule section).

**Before:**

```markdown
- **`supporting-docs/`** — docs copied individually during setup (METHODOLOGY.md)
  or read from the pack without copying (QUICKSTART.md, DEPENDENCIES.md,
  CLI-PM-SETUP.md, etc.). These are process and reference docs.
```

**After:**

```markdown
- **`supporting-docs/`** — docs copied individually during setup (METHODOLOGY.md
  to `docs/pack/`) or read from the pack without copying (QUICKSTART.md,
  DEPENDENCIES.md, CLI-PM-SETUP.md, etc.). These are process and reference docs.
```

**Verification check:**

```bash
grep -n "METHODOLOGY.md to \`docs/pack/\`" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/README.md
# Expect: 1 hit on line ~37.
```

### 5.6 Edit E6 (optional) — `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` lines 1611, 1612, 1662

**Three small alignment edits.** The file is a reference plan; these change pass-criteria assertions to match the new canonical path.

**At line 1611:**
- Before: `[[ -f docs/pack/METHODOLOGY.md ]] || [[ -f METHODOLOGY.md ]] && echo "OK: METHODOLOGY.md present (one of the two paths)"`
- After: `[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: METHODOLOGY.md present at docs/pack/"`

**At line 1612:**
- Before: `grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md METHODOLOGY.md 2>/dev/null && echo "OK: Procedure 7 present" \`
- After: `grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md 2>/dev/null && echo "OK: Procedure 7 present" \`

**At line 1662:**
- Before: `| METHODOLOGY.md present (either path) | yes | F-G; S5 / S6 stage failed against OT. |`
- After: `| docs/pack/METHODOLOGY.md present | yes | F-G; S5 / S6 stage failed against OT. |`

**Verification check:**

```bash
grep -n "either path\||| \[\[ -f METHODOLOGY.md \]\]" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md
# Expect: 0 hits (no remaining root-fallback assertions).
```

---

## 6. Per-commit verification checklist

Adapted from `V10-PHASE-4-PLAN.md` Part 7 (lines 932–963), specialized for this patch. The implementer runs every check, captures output, presents to project lead before commit.

### 6.1 Pre-commit checks

```
[ ] git status                          — staged files match the 5 (or 6) listed in §3.1 / §3.3
[ ] git diff --stat                     — line-count delta is ~30–50 lines total (no surprise file additions)
[ ] git diff --name-only                — names match exactly:
       scripts/migrate-v9-to-v10.sh
       scripts/init-project.sh
       supporting-docs/MIGRATION-v9-to-v10.md
       project-template/README.md
       (optional) maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md
[ ] python3 scripts/validate-pack.py    — exits 0 (no METHODOLOGY-path check exists; this is a regression guard)
[ ] bash scripts/test-detect.sh         — exits 0; reports 34/34 passing (regression guard for unrelated detection logic)
[ ] §5.1 grep checks (E1)               — all expected hit-counts match
[ ] §5.2 grep checks (E2)               — all expected hit-counts match
[ ] §5.3 grep checks (E3)               — all expected hit-counts match
[ ] §5.4 grep checks (E4)               — all expected hit-counts match
[ ] §5.5 grep checks (E5)               — all expected hit-counts match
[ ] §5.6 grep checks (E6, if included)  — all expected hit-counts match
[ ] Trinity rule N/A                    — no trinity edits in this patch (verify by `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns empty)
[ ] Cross-reference audit               — `grep -rn "METHODOLOGY.md" project-template/ supporting-docs/ scripts/ | grep -v 'docs/pack/METHODOLOGY.md\|supporting-docs/METHODOLOGY.md\|§\|Procedure'` returns no surprise hits
[ ] §7 delta verification harness       — all four fixture builds pass; output captured to /tmp; ready for §7 evidence section
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`
```

### 6.2 Post-commit checks

```
[ ] git log --oneline -1                — commit message matches the spec in §8 below
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm post-commit)
[ ] gh run watch                        — Validate Pack workflow green on v10-dev branch
```

**If validate-pack.py fails post-commit:** roll back per V10-PHASE-4-PLAN.md Part 7 (lines 957–962): `git reset --soft HEAD~1`, fix, recommit. Pack must remain working at every intermediate commit.

---

## 7. Verification harness — delta evidence

Per project-lead Decision 2 (delta-only re-verification), the implementer does NOT re-run §4.6, §4.7, or §4.8 in full. The implementer DOES run a targeted §10 delta-verification harness covering all four pre-states (A/B/C/D from §5.1 of this plan / §5.1 of the design).

**All operations within `/tmp/`. Live OT untouched. Live pack repo on `main` untouched.** The implementer's working pack repo is the `v10-dev` worktree; clone or copy it to `/tmp/` before running mutation tests against scripts.

### 7.1 Pre-flight — pack repo state

```bash
cd /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
git status --porcelain        # Expect: empty (post-commit) or only the patched files (pre-commit on staged tree).
git rev-parse HEAD            # Capture for evidence.
PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev   # The patched pack repo.

# Confirm the live pack repo on main is untouched:
git -C "$PACK" rev-parse main
# (this is just a SHA read; main is not checked out, no risk)
```

### 7.2 Fixture base directory

```bash
mkdir -p /tmp/v10-fd-fixtures
cd /tmp/v10-fd-fixtures
```

### 7.3 §10.1 — Fresh init harness (state D coverage)

```bash
# Build a minimal new-project fixture and run init-project.sh against it.
mkdir -p /tmp/v10-fd-fixtures/fresh-init
cd /tmp/v10-fd-fixtures/fresh-init
git init -q
echo "# fresh-init test fixture" > README.md
git add README.md && git commit -q -m "seed"

PACK="$PACK" "$PACK/scripts/init-project.sh" . \
  > /tmp/v10-fd-fixtures/fresh-init.stdout.txt 2> /tmp/v10-fd-fixtures/fresh-init.stderr.txt
echo "init-project.sh exit: $?"

# Assert: METHODOLOGY at docs/pack/, no root copy.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present" || echo "FAIL: docs/pack/METHODOLOGY.md missing"
[[ ! -f METHODOLOGY.md ]] && echo "OK: no root METHODOLOGY.md" || echo "FAIL: root METHODOLOGY.md present"
grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md && echo "OK: Procedure 7 present" || echo "WARN: Procedure 7 missing"
```

### 7.4 §10.2 — Migration harness state B (root-only pre-state, synthetic §4.4-style)

Per V10-PHASE-4-VERIFICATION-PLAN-v2.md §6.4 fixture pattern: build a synthetic v9.3 project, then place METHODOLOGY at root only, then migrate.

```bash
# Build a v9.3-shaped fixture by checking out the pack at v9.3 and copying its project layout.
mkdir -p /tmp/v10-fd-fixtures/v9-state-B
cd /tmp/v10-fd-fixtures/v9-state-B
git init -q
# Use v9.3 pack source to scaffold (mirrors §6.4 of v2 plan).
V93_PACK=/tmp/v10-fd-fixtures/v9-pack-source
git clone -q --branch v9.3 /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev "$V93_PACK" 2>/dev/null || \
  git -C "$V93_PACK" fetch --tags origin
# Copy the v9.3 project-template/ scaffold:
cp -r "$V93_PACK/project-template/." .
# v9.3 placed METHODOLOGY at root: copy from v9.3 supporting-docs.
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md
# Confirm pre-state B: METHODOLOGY at root, NOT at docs/pack.
[[ -f METHODOLOGY.md ]] && echo "pre-state B: root present"
[[ ! -f docs/pack/METHODOLOGY.md ]] && echo "pre-state B: docs/pack absent"
git add -A && git commit -q -m "v9.3 baseline (state B)"

# Run migration with the patched v10-dev pack.
PACK="$PACK" "$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/v10-fd-fixtures/state-B.stdout.txt 2> /tmp/v10-fd-fixtures/state-B.stderr.txt
echo "migrate exit: $?"

# Assert post-state.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present"
[[ ! -f METHODOLOGY.md ]] && echo "OK: root METHODOLOGY.md gone"
grep -q "removed stale METHODOLOGY.md at project root" /tmp/v10-fd-fixtures/state-B.stdout.txt \
  && echo "OK: stdout reports root removal"
[[ -f .pack-migration-backup/v9.3-to-v10.0/METHODOLOGY.md ]] && echo "OK: root pre-state backed up"
```

### 7.5 §10.3 — Migration harness state A (docs/pack-only pre-state, OT-shape)

```bash
mkdir -p /tmp/v10-fd-fixtures/v9-state-A
cd /tmp/v10-fd-fixtures/v9-state-A
git init -q
cp -r "$V93_PACK/project-template/." .
# State A places METHODOLOGY at docs/pack only.
mkdir -p docs/pack
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
[[ -f docs/pack/METHODOLOGY.md ]] && echo "pre-state A: docs/pack present"
[[ ! -f METHODOLOGY.md ]] && echo "pre-state A: root absent"
git add -A && git commit -q -m "v9.3 baseline (state A — OT shape)"

PACK="$PACK" "$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/v10-fd-fixtures/state-A.stdout.txt 2> /tmp/v10-fd-fixtures/state-A.stderr.txt
echo "migrate exit: $?"

# Assert post-state — docs/pack overwritten, no root file appears.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present"
[[ ! -f METHODOLOGY.md ]] && echo "OK: no root METHODOLOGY.md created"
[[ -f .pack-migration-backup/v9.3-to-v10.0/docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack pre-state backed up"
# Verify content is v10 (not v9.3) — diff against the v10 source.
diff -q docs/pack/METHODOLOGY.md "$PACK/supporting-docs/METHODOLOGY.md" \
  && echo "OK: docs/pack content matches v10 source"
```

### 7.6 §10.4 — Migration harness state C (both present pre-state, mid-flight v10-dev shape)

```bash
mkdir -p /tmp/v10-fd-fixtures/v9-state-C
cd /tmp/v10-fd-fixtures/v9-state-C
git init -q
cp -r "$V93_PACK/project-template/." .
mkdir -p docs/pack
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" docs/pack/METHODOLOGY.md
cp "$V93_PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md
git add -A && git commit -q -m "v9.3 baseline (state C — both)"

PACK="$PACK" "$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/v10-fd-fixtures/state-C.stdout.txt 2> /tmp/v10-fd-fixtures/state-C.stderr.txt
echo "migrate exit: $?"

# Assert post-state.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present"
[[ ! -f METHODOLOGY.md ]] && echo "OK: root METHODOLOGY.md removed"
[[ -f .pack-migration-backup/v9.3-to-v10.0/docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack backed up"
[[ -f .pack-migration-backup/v9.3-to-v10.0/METHODOLOGY.md ]] && echo "OK: root backed up"
```

### 7.7 §10.5 — Pack-level regression guards

```bash
cd "$PACK"
python3 scripts/validate-pack.py
echo "validate-pack.py exit: $?"           # Expect: 0

bash scripts/test-detect.sh
echo "test-detect.sh exit: $?"             # Expect: 0; output reports 34/34 passing
```

### 7.8 §10.6 — Cleanup

```bash
rm -rf /tmp/v10-fd-fixtures
ls -ld /tmp/v10-fd-fixtures 2>&1
# Expect: "No such file or directory"
```

### 7.9 Evidence destination — append §10 to `V10-PHASE-4-VERIFICATION.md`

The implementer appends a new section to the existing `maintenance-docs/V10-PHASE-4-VERIFICATION.md` file (last committed at SHA `945377e` per project lead's note). The append happens **after** all five (or six) edits have committed and the §7 harness has run, but the §10 append itself is a separate, smaller commit (`docs:` prefix) — it documents the patch's verification, it is not part of the patch behavior itself.

**Section template (paste verbatim, fill bracketed values):**

```markdown
## §10 Delta verification — F-D + F-C patch

**Date:** [ISO 8601 UTC timestamp]
**Patch commit:** [short SHA of the F-D + F-C atomic commit]
**Scope:** Delta-only re-verification per project-lead Decision 2. Confirms the patched migration script and init-project.sh write METHODOLOGY.md to `docs/pack/` and clean up any stale root copy. Full §4.6 / §4.7 / §4.8 NOT re-run; historical evidence in those sections retained as-was.

### §10.1 Fresh init (state D)

- Fixture: `/tmp/v10-fd-fixtures/fresh-init/`.
- init-project.sh exit: [0].
- `docs/pack/METHODOLOGY.md` present: [OK].
- root `METHODOLOGY.md` absent: [OK].
- Procedure 7 present: [OK].

### §10.2 Migration state B (root-only pre-state)

- Fixture: synthetic v9.3 scaffold + root METHODOLOGY (per V10-PHASE-4-VERIFICATION-PLAN-v2 §6.4 pattern).
- migrate-v9-to-v10.sh exit: [0].
- Pre-state confirmed: root present, docs/pack absent.
- Post-state: docs/pack present, root removed.
- Backup: `$BACKUP_DIR/METHODOLOGY.md` (root pre-state preserved).
- stdout reports root removal: [OK].

### §10.3 Migration state A (docs/pack-only pre-state, OT-shape)

- Fixture: synthetic v9.3 scaffold + docs/pack METHODOLOGY.
- migrate-v9-to-v10.sh exit: [0].
- Post-state: docs/pack overwritten with v10 content; no root file appears.
- Backup: `$BACKUP_DIR/docs/pack/METHODOLOGY.md` (docs/pack pre-state preserved).
- v10 content match (diff vs `$PACK/supporting-docs/METHODOLOGY.md`): [empty diff].

### §10.4 Migration state C (both present)

- Fixture: synthetic v9.3 scaffold + METHODOLOGY at both locations.
- migrate-v9-to-v10.sh exit: [0].
- Post-state: docs/pack overwritten with v10; root removed.
- Backup: both pre-states preserved.

### §10.5 Pack-level regressions

- `python3 scripts/validate-pack.py` exit: [0].
- `bash scripts/test-detect.sh` exit: [0]; reports [34/34] passing.

### §10.6 Sanitization

All fixtures synthetic — built under `/tmp/v10-fd-fixtures/` from the v9.3-tag pack source. No OT content involved. No sanitization required per §6.7.7 rules. Live OT clone untouched (no OT_LIVE rev-parse occurred during this delta).

### §10.7 Pass / fail summary

| Check | Result |
|---|---|
| State A migration → docs/pack only | [PASS] |
| State B migration → docs/pack + root removed | [PASS] |
| State C migration → docs/pack + root removed + both backups | [PASS] |
| State D fresh init → docs/pack only | [PASS] |
| validate-pack.py | [PASS exit 0] |
| test-detect.sh | [PASS 34/34] |

**Outcome:** F-D + F-C jointly resolved. v10.0 ship-blocker cleared.
```

---

## 8. Commit message (proposed)

Per CLAUDE.md commit message format and BD-049 labeled-section convention adapted for code commits:

```
fix: v10 — METHODOLOGY.md canonical location → docs/pack/

Resolves F-D (v10 design contradiction: trinity says docs/pack,
scripts install to root) and F-C (legacy docs/pack/METHODOLOGY.md
not cleaned up by migration). The two share one root cause and one
fix per V10-F-D-DESIGN.md §6 — combined into a single patch.

Implements V10-F-D-DESIGN.md (architect 2026-04-29; project-lead
approved) and V10-F-D-PLAN.md (planner 2026-04-29).

Files touched:
  scripts/migrate-v9-to-v10.sh         — S5 stage: write to docs/pack/METHODOLOGY.md;
                                         back up both possible source locations;
                                         remove stale root copy if present
  scripts/init-project.sh              — S6 stage: write to docs/pack/METHODOLOGY.md;
                                         warn (do not delete) on stale root for existing-*
  supporting-docs/MIGRATION-v9-to-v10.md  — S5 stage prose: METHODOLOGY at docs/pack/
  project-template/README.md           — setup-cp example + directory-boundary note
  maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md  — assertion paths aligned

Trinity rule: clean — trinity files already say docs/pack/METHODOLOGY.md
(line 275 / 198 / 229), no trinity edits required.

Verification: §10 delta-evidence harness in V10-PHASE-4-VERIFICATION.md
(separate docs: commit) — four pre-state fixtures (A/B/C/D), all pass.
validate-pack.py exits 0; test-detect.sh 34/34.

BD-NNN to be assigned at C-V10-18 BACKLOG sweep.
```

The §10 evidence append is a **separate small follow-up commit** (`docs:` prefix) so the behavioral patch is reviewable independently of the evidence capture:

```
docs: v10 — V10-PHASE-4-VERIFICATION §10 delta evidence (F-D + F-C)
```

---

## 9. Risks and assumptions

### 9.1 Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | Stale references to `METHODOLOGY` at project root remain in pack content after the patch (the audit grep missed something). | Low | The §3.4 grep audit covers `*.md`, `*.toml`, `*.json`, `*.sh`. If the implementer finds a hit during the per-commit verification §6.1 cross-reference audit step, FLAG-BACK before commit. |
| R2 | The migration script's `mkdir -p docs/pack` happens during S4 (line 292) for the prompts/ directory, so docs/pack/ already exists by S5 — but we add a defensive `mkdir -p docs/pack` at S5 anyway in case a future stage reorder breaks the assumption. | Very low | Defensive `mkdir -p` is idempotent; no harm. |
| R3 | A v9.3 user project with both files present (state C) may have meaningfully customized one of them. The script overwrites docs/pack with v10 content per spec; the user's customization is in the backup. | Low — V10-DESIGN.md §6 already establishes pack-owned files are not project-customized. | Backup at `$BACKUP_DIR/docs/pack/METHODOLOGY.md` preserves the pre-state; rollback per MIGRATION-v9-to-v10.md §12 restores it. |
| R4 | The `warn` in init-project.sh fires noisily for `existing-*` projects that legitimately have METHODOLOGY at root from a pre-fix v10-dev install. | Expected — that is the intent. The operator should move or delete it. | The warning text explicitly says "move or delete manually" so the operator has guidance. |
| R5 | CI (`Validate Pack` GitHub Actions workflow) does not exercise the migration script against fixtures — only validate-pack.py. So the §7 harness must be run locally; CI will not catch a script regression. | Medium — known limitation of the existing CI shape. | The §7 harness IS the verification. The implementer runs it; project lead reviews evidence; CI is a regression backstop, not the primary gate. |
| R6 | The §10 evidence-append commit might be made with stale data if the implementer reruns the harness post-commit-1 and forgets to refresh the evidence. | Low | The §6.2 post-commit checklist re-runs validate-pack.py and gh run watch — neither requires refreshing the §10 capture. The §10 capture happens once during §6.1, immediately before commit-1. |

### 9.2 Assumptions

| # | Assumption | Resolution |
|---|---|---|
| A1 | `BACKUP_DIR` is in scope at line 347 of `migrate-v9-to-v10.sh`. | **Confirmed** — declared at line 24 (`readonly BACKUP_DIR=...`); referenced inside `stage_s5_trinity_splice` at lines 314, 325, 340–341, 349. |
| A2 | `info` helper exists in `init-project.sh`; `warn` writes to stderr. | **Confirmed** — line 44 (`info`), line 45 (`warn`). |
| A3 | `say` is the right log helper in `migrate-v9-to-v10.sh`; no `info` helper exists. | **Confirmed** — line 30 (`say`); no `info` defined. The new "removed stale" message uses `say`. |
| A4 | `project-template/README.md` is dev-only (not shipped to projects). | **Confirmed** — neither `init-project.sh` nor `migrate-v9-to-v10.sh` references `project-template/README.md`. See OQ-F-D-1 §10.1. |
| A5 | No `@-reference` patterns to METHODOLOGY exist in pack content. | **Confirmed** — recursive grep on `@METHODOLOGY` and `@docs/pack/METHODOLOGY` returns no hits. See OQ-F-D-2 §10.2. |
| A6 | `mcp-local-rag` does not hardcode METHODOLOGY's path; it uses `BASE_DIR` and recurses. | **Confirmed** — `.mcp.json.example` only sets `BASE_DIR` to project root; `DB_PATH` to `./.claude/rag-index`. No METHODOLOGY-specific path. SETUP-NEW.md line 311 ("Ingest METHODOLOGY.md into the RAG index") is natural-language operator instruction. See OQ-F-D-5 §10.3. |
| A7 | The v9.3 tag is resolvable from the `v10-dev` worktree for §7.4–7.6 fixture builds. | **Confirmed** — migrate-v9-to-v10.sh S0 (line 122–123) already enforces this; if the implementer's `v10-dev` clone is missing v9.3, fix before harness runs. |

### 9.3 Flag-backs (conditions where implementer pauses)

The implementer MUST flag-back to the parent agent before proceeding if:

- **FB-1.** Any §3.4 cross-reference grep returns a hit not anticipated in this plan (e.g., a script or doc references `METHODOLOGY.md` at root that this plan did not enumerate).
- **FB-2.** The v9.3 tag is not resolvable from the implementer's pack clone (blocks §7.4–7.6 fixture builds).
- **FB-3.** Any of the four state harnesses (§7.3–7.6) fails an assertion. Do NOT commit before the failure is diagnosed.
- **FB-4.** `validate-pack.py` exits non-zero post-commit. Roll back per §6.2 and diagnose; do not proceed to the §10 evidence-append commit.
- **FB-5.** The trinity-rule `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns non-empty. The plan asserts no trinity edits — any trinity diff is unexpected and requires diagnosis before commit.

---

## 10. Open-question resolutions

### 10.1 OQ-F-D-1 — Is `project-template/README.md` shipped to projects?

**Resolution: NO. `project-template/README.md` is dev-only.**

**Evidence:**
- `grep -n "project-template/README" scripts/init-project.sh` — 0 hits.
- `grep -n "project-template/README" scripts/migrate-v9-to-v10.sh` — 0 hits.
- `init-project.sh` S6 (line 351 `local pack_docs="$PACK/project-template/docs/pack"`) and S7 (lines 384–396 trinity copy) do not reference `project-template/README.md`. The `cp -r project-template/.` pattern in `project-template/README.md` line 6 is documentation aimed at humans manually scaffolding (or pack maintainers), not invoked by any script.

**Implication:** rows E4 and E5 in §3.1 are doc-hygiene edits (dev-orientation prose), not user-facing. Urgency lower than scripts; correctness still required for plan coherence.

### 10.2 OQ-F-D-2 — `@-reference` patterns to METHODOLOGY?

**Resolution: NO `@METHODOLOGY` or `@docs/pack/METHODOLOGY` references exist in pack content.**

**Evidence:**
```
grep -rn "@METHODOLOGY\|@docs/pack/METHODOLOGY\|@.*METHODOLOGY" pack repo (excluding maintenance-docs/V10-F-D-DESIGN.md self-references) — 0 hits.
```

The pm-startup `SKILL.md` line 45 reference is a shell `git log -- docs/pack/METHODOLOGY.md` invocation, not an `@-reference`. Already correct under the new canonical path.

**Implication:** no additional file edits required for `@-reference` updates.

### 10.3 OQ-F-D-5 — `mcp-local-rag` hardcoded ingest path?

**Resolution: NO hardcoded METHODOLOGY path in any ingest invocation.**

**Evidence:**
- `project-template/.mcp.json.example` (full file inspected): sets `BASE_DIR` to project root and `DB_PATH` to `./.claude/rag-index`. Line 3 mentions METHODOLOGY in a `_tools` description string ("It provides semantic search over METHODOLOGY.md"), but no path. The `mcp-local-rag` server scans `BASE_DIR` recursively; a METHODOLOGY at `docs/pack/METHODOLOGY.md` is discoverable without configuration changes.
- `supporting-docs/SETUP-NEW.md` line 311 ("Ingest METHODOLOGY.md into the RAG index"): natural-language instruction to a human PM-chat operator. The operator types this into a CLI session; the LLM tools the kickoff prompt enumerates handle the actual ingest. No script-level hardcoded path.
- `project-template/skills/pm-startup/SKILL.md` lines 41–50: instruction to re-ingest if `git log -1 ... -- docs/pack/METHODOLOGY.md` reports a recent edit. **Already references docs/pack/.** Latent defect under the previous root-canonical implementation now silently resolves with this patch — pm-startup will start working as intended on existing v10 projects after migration.

**Implication:** no edit required to `.mcp.json.example` or `SETUP-NEW.md`. The pm-startup `SKILL.md` is *also* clean — no edit required, and the patch implicitly fixes its previously-latent defect.

### 10.4 OQ-F-D-3 (project-lead resolved) — delta evidence sufficient?

Resolved by project lead Decision 2: **delta-only re-verification.** This plan §7 implements the delta harness; full §4.6/§4.7/§4.8 not re-run.

### 10.5 OQ-F-D-4 (project-lead resolved) — combine F-C and F-D BD entry?

Resolved by project lead Decision 3: **combine into one BD-NNN at C-V10-18 BACKLOG sweep.** This plan does not file the BD entry.

---

## 11. Self-check

- **Can the implementer execute the 5–6 edits and post-fix verification without further architectural calls?** Yes — every edit has its file, line range, before/after snippet, and grep verification check. The §7 harness is copy-pasteable bash. No design questions remain.
- **Is the migration script S5 bash actually correct?** Yes — verified against the function's existing variable scope (`BACKUP_DIR`, `say`), existing patterns (`mkdir -p "$BACKUP_DIR/docs/pack"` already used at line 340 for PM-CHAT.md), and the four-state matrix from V10-F-D-DESIGN §5.1.
- **Are the §7 fixtures buildable with the same patterns as V10-PHASE-4-VERIFICATION-PLAN-v2.md §3.2 / §6.4?** Yes — uses the same `git clone --branch v9.3` source-pack pattern, same `cp -r project-template/.` scaffolding, same `/tmp/` containment, same teardown discipline.
- **OQ-F-D-1 / 2 / 5 resolved?** Yes — see §10.1 / §10.2 / §10.3.
- **Trinity rule respected?** Yes — verified no trinity edits required (V10-F-D-DESIGN §4.3 / §7); §6.1 checklist includes a `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` empty-diff guard.

---

## 12. Summary

**Decision:** atomic single commit (5 files; 6 with the optional V10-PHASE-4-VERIFICATION-PLAN-v2.md alignment), followed by a separate `docs:` commit appending §10 delta evidence to V10-PHASE-4-VERIFICATION.md.

**Edits:**
1. `scripts/migrate-v9-to-v10.sh` S5 — write to docs/pack; back up both locations; remove stale root.
2. `scripts/init-project.sh` S6 — write to docs/pack; warn on stale root for existing-*.
3. `supporting-docs/MIGRATION-v9-to-v10.md` line 150 — uniform docs/pack prose.
4. `project-template/README.md` line 12 — docs/pack cp example.
5. `project-template/README.md` line 37 — directory-boundary note.
6. (Optional) `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` — three pass-criteria alignments.

**Verification:** four pre-state harnesses (A/B/C/D) under `/tmp/v10-fd-fixtures/`; validate-pack.py exit 0; test-detect.sh 34/34. All within /tmp; live OT and live pack-on-main untouched.

**Trinity rule:** clean (no trinity edits).

**Open questions resolved:** OQ-F-D-1 (README dev-only), OQ-F-D-2 (no @-references), OQ-F-D-5 (no hardcoded ingest path).

**Flag-backs surfaced:** FB-1..FB-5 in §9.3.

**BD entry:** combined F-C + F-D, assigned at C-V10-18 BACKLOG sweep (out of plan scope).
