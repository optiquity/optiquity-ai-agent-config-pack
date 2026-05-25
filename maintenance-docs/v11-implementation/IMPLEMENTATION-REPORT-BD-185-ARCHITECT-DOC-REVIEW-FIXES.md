# IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md

**Authored by:** pack-coder (fix-coder mode; BD-185 architect-doc post-review fixes).
**Date:** 2026-05-25 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at start of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363.
**Repo HEAD at end of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363 (no commits; doc edits only).
**Source review:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` (369 lines; PASS-WITH-MUSTS verdict; 13 findings + 1 INFO).
**Target doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`.
**Triage authority:** Pack Chat default FIX-ALL per `feedback_fix_all_review_findings`; user approved bulk-accept 2026-05-25.

---

## §1 — Scope

Applied 13 mechanical fixes from `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` to the architect doc:

- **4 MUST findings** — propagation gaps + a stale claim + a broken cross-reference.
- **4 SHOULD findings** — propagation polish.
- **5 NIT findings** — clarity polish + line-number-citation cleanups.
- **1 INFO finding (INFO-1)** — confirmed no architect-doc action (forwarded to planner).

No source code modified. No CI checks regressed (validate-pack.py PASSED — all 43 checks clean post-edits).

Total file deltas:
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`: 13 edits across §1.4, §3, §4.2, §4.4, §4.4a, §4.7, §5.2, §5.4, §6.3, §7, §8.2 (table), §10.1, §10.2, §11.1, §11.2, §11.4, §14.1.

---

## §2 — Inputs read

| Path | Purpose | HEAD SHA |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | Target doc | 4d1f9e5 (untracked) |
| `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` | Source review report (verbatim recommendations) | n/a (tmp) |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | Cross-reference target | a5c7e62 (untracked) |
| `scripts/lib/tracker-provider.sh` (lines 115-143) | Symbol-name resolution for NIT-3 L490 fix | 4d1f9e5 |
| `scripts/lib/tracker-migrate-reverse.sh` (lines 460-740) | Symbol-name resolution for NIT-3 L101 / L623 / L624 / L709 fixes | 4d1f9e5 |
| `scripts/validate-pack.py` (lines 125-160, 3420-3430) | Symbol-name resolution for NIT-3 L922 fix | 4d1f9e5 |
| `scripts/lib/per-entry/_lib.sh` (lines 380-410) | Symbol-name resolution for NIT-3 L100 / L524 fixes | 4d1f9e5 |
| `scripts/lib/tracker-sidecar.sh` (lines 285-313) | Symbol-name resolution for NIT-3 L305 fix | 4d1f9e5 |
| `supporting-docs/METHODOLOGY.md` (section list) | Section-name resolution for NIT-3 L965 / L973 fixes | 4d1f9e5 |
| `supporting-docs/MIGRATION-v10-to-v11.md` (section list) | Section-name resolution for NIT-3 L994 fix | 4d1f9e5 |
| `project-template/docs/project/implementation-plan/_rules.md` | Section-name resolution for NIT-3 L1019 fix | 4d1f9e5 |

---

## §3 — MUST fixes applied

### MUST-1 — D5 cancelled state propagation to Check 35

**Location:** `ARCHITECTURE-BD-185.md` §10.1 Check 35 extension list.

**Before:**

```
**Check 35 (`check_tracker_phase_task_invariants`, BD-106):**
- Existing: verifies `scripts/lib/tracker-phase-task.sh` exists; Path 3 forbidden.
- Extended: `scripts/lib/tracker-phase-part.sh` is CREATED per D11 (parallel to `tracker-phase-task.sh`); verify it follows the same lib-invariant pattern.
```

**After:**

```
**Check 35 (`check_tracker_phase_task_invariants`, BD-106):**
- Existing: verifies `scripts/lib/tracker-phase-task.sh` exists; Path 3 forbidden.
- Extended: `scripts/lib/tracker-phase-part.sh` is CREATED per D11 (parallel to `tracker-phase-task.sh`); verify it follows the same lib-invariant pattern.
- Status enumeration admits `cancelled` (per §4.4a; see also §11.1 SCHEMA archive extension).
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.4 (D5 propagation GAP) + §4 MUST-1 row.

---

### MUST-2 — D3 empty-Part rejection check (Check N+3)

**Location:** `ARCHITECTURE-BD-185.md` §10.2 new-checks list (appended after Check N+2).

**Before:** §10.2 enumerated Check N, Check N+1, Check N+2 (no entry for the D3 empty-Part check that §4.7 L359 references as "Check 44 or next available").

**After (new entry added):**

```
**Check N+3 (`check_part_has_member_task`):**
- Verifies every Part entity in tracker has at least one task as a sub-issue child OR is marked `status:deferred`.
- Tracker-side check only.
- Per D3 §4.7 L353-L359.
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.4 (D3 propagation GAP) + §4 MUST-2 row.

---

### MUST-3 — Stale "19th in the surface" claim

**Location:** `ARCHITECTURE-BD-185.md` §3 §12.7 row.

**Before:**

```
| §12.7 | Provider abstraction lacks sub-issue-reprioritize op | LOAD-BEARING | §5.2 + §7 add `provider_sub_issue_reprioritize` as a new op (19th in the surface + raw). Forgejo/Gitea fallback uses it. |
```

**After:**

```
| §12.7 | Provider abstraction lacks sub-issue-reprioritize op | LOAD-BEARING | §5.2 + §7 add `provider_sub_issue_reprioritize` as a new op (designed in v11.0 surface; implementation deferred to v11.1+ per D9; v11.0 ships at 18→20, v11.1+ at 20→21). Forgejo/Gitea fallback uses it. |
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.4 (D9 op-count consistency GAP) + §4 MUST-3 row + §4 NIT-4 row (NIT-4 resolved by this same fix per `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §4 NIT-4 row).

---

### MUST-4 — D4 cross-reference "§10" broken

**Location:** Two sites — `ARCHITECTURE-BD-185.md` §1.4 Decision log D4 row + §4.7 body text.

**Site 1 (§1.4 D4 row):**

**Before:**

```
| D4 | Mid-life re-parenting between Parts | User-driven (2026-05-25) | FORBIDDEN — supersede only via `pack task supersede` | §4.7, §10 |
```

**After:**

```
| D4 | Mid-life re-parenting between Parts | User-driven (2026-05-25) | FORBIDDEN — supersede only via `pack task supersede` | §4.7, §4.8 |
```

**Site 2 (§4.7 body):**

**Before:** "Tasks that need to move work to a different Part use `pack task supersede` (per D4 / §10) — ..."

**After:** "Tasks that need to move work to a different Part use `pack task supersede` (per D4 / §4.8) — ..."

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.3 (BROKEN D4 cross-ref) + §4 MUST-4 row.

---

## §4 — SHOULD fixes applied

### SHOULD-1 — D6 verification note for GH `_sub_issue_reprioritize`

**Location:** `ARCHITECTURE-BD-185.md` §7 ops table, `provider_sub_issue_reprioritize` row, GH backend column.

**Before:** "GH: REST `PATCH /sub_issues/priority` (§4.2). Forgejo/Gitea: ..."

**After:** "GH: REST `PATCH /sub_issues/priority` (§4.2) (primary-source verification of REST param names at implementation-time per D6). Forgejo/Gitea: ..."

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.4 (D6 verify-at-implementation-time PARTIAL) + §4 SHOULD-1 row.

---

### SHOULD-2 — C-2(2) Part-identity rejection not explicit

**Location:** `ARCHITECTURE-BD-185.md` §4.2 (after "Parts MUST be tracker entities in tracker mode" line).

**Before:** §4.2 implicitly rejected C-2(2) by choosing first-class sub-issue Parts; no explicit statement.

**After (new sentence added):**

```
C-2(2) Issue Fields shape for Part identity is REJECTED — Parts are first-class sub-issue entities (per this section's decision), not Issue Field annotations on phase tasks. Issue Fields are reserved for execution-order (§5.1).
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.4 (C-2(2) Part-identity Issue Field decision GAP) + §4 SHOULD-2 row.

---

### SHOULD-3 — D11 cross-reference "§11" broken

**Location:** `ARCHITECTURE-BD-185.md` §1.4 Decision log D11 row.

**Before:**

```
| D11 | NEW `tracker-phase-part.sh` library | Architect POQ-7 | ACCEPTED new file (parallel to `tracker-phase-task.sh`) | §11 |
```

**After:**

```
| D11 | NEW `tracker-phase-part.sh` library | Architect POQ-7 | ACCEPTED new file (parallel to `tracker-phase-task.sh`) | §10.1, §14.2, §14.9 |
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.3 (BROKEN D11 cross-ref) + §4 SHOULD-3 row.

---

### SHOULD-4 — D4 supersede verb in §11.1 not explicit enough

**Location:** `ARCHITECTURE-BD-185.md` §11.1 Multi-part phases extension list (inserted between Task immutability rule and Execution-note-status marker convention).

**Before:** §11.1 list carried Task immutability rule (D4 — supersede only) but did not name the supersede verb as the "canonical mid-life task-move mechanism" — implicit only.

**After (new bullet inserted):**

```
- **Supersede verb is the canonical mid-life task-move mechanism (D4):** Document the supersede verb as the canonical mid-life task-move mechanism; reject mid-life re-parenting between Parts (see §4.8).
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §4 SHOULD-4 row.

---

## §5 — NIT fixes applied

### NIT-1 — Deferred Part state trigger ambiguous

**Location:** `ARCHITECTURE-BD-185.md` §4.4 Part state taxonomy table, deferred row notes column.

**Before:** "Part deferred mid-work; member tasks stay assigned (re-parenting forbidden per D4 — see §4.7 supersede-only rule)"

**After:** "Part deferred mid-work; member tasks stay assigned (re-parenting forbidden per D4 — see §4.7 supersede-only rule). Trigger: all member tasks are in a terminal state (done / deferred / cancelled / superseded) but NOT all done — see §4.7 operational paths."

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.5 + §4 NIT-1 row.

---

### NIT-2 — "likely Check 35" weasel hedge

**Location:** `ARCHITECTURE-BD-185.md` §4.4a (closing line of the section).

**Before:** "Validator extension noted: existing Check (likely Check 35) gains `cancelled` as an admitted state value."

**After:** "Validator extension: Check 35 gains `cancelled` as an admitted state value (per §10.1)."

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.5 (weasel words) + §4 NIT-2 row. Per the reviewer's hint, this presumes MUST-1 has landed — confirmed MUST-1 landed in this same fix-pass, so the §10.1 reference is accurate.

---

### NIT-3 — Line-number citations replaced with symbol/section names

**Locations:** Multiple sites in `ARCHITECTURE-BD-185.md`. All citations from the explicit prompt list resolved.

#### NIT-3 site 1 — `tracker-provider.sh` "line 141"

**Before (§5.2 fallback section):** "The `provider_capabilities` op (existing — line 141 of `tracker-provider.sh`) gains a new capability flag:"

**After:** "The `provider_capabilities` op (existing — `provider_capabilities` function in `tracker-provider.sh`) gains a new capability flag:"

**Resolution method:** Read `scripts/lib/tracker-provider.sh` lines 115-143 — confirmed line 141 is the `provider_capabilities()` dispatcher definition.

#### NIT-3 site 2 — `tracker-migrate-reverse.sh` "line 683" and "line 712"

**Before (§6.3 reverse-migration table):**

```
| `_tmr_emit_implementation_plan` (line 683) | ... |
| `_tmr_emit_status` (line 712) | ... |
```

**After:**

```
| `_tmr_emit_implementation_plan` | ... |
| `_tmr_emit_status` | ... |
```

**Resolution method:** Read `scripts/lib/tracker-migrate-reverse.sh` lines 680-720 — confirmed lines 683 / 712 are the function-definition lines of `_tmr_emit_implementation_plan` and `_tmr_emit_status` respectively. The function names are self-sufficient (no line-number qualifier needed).

#### NIT-3 site 3 — `validate-pack.py` "(line 136)"

**Before (§10.1 Check 34 extension):** "Cross-ref regex (line 136) extends from ..."

**After:** "Cross-ref regex (`CROSS_REF_RE` in `validate-pack.py`; Check 34 docstring) extends from ..."

**Resolution method:** Read `scripts/validate-pack.py` lines 125-160 (Check 34 docstring) and lines 3420-3430 (`CROSS_REF_RE` regex compile). The regex is named `CROSS_REF_RE`; line 136 is the docstring line citing the regex's responsibility.

#### NIT-3 site 4 — `_lib.sh:393-401` (two occurrences)

**Before (§3 observation §12.3 row):** "...verified `_lib.sh:393-401`. ..."

**After:** "...verified in `pe_sort_entries` function in `scripts/lib/per-entry/_lib.sh`. ..."

**Before (§5.3 mirror-generator paragraph):** "(`scripts/lib/per-entry/mirror-generate.sh` + `_lib.sh:393-401`)"

**After:** "(`scripts/lib/per-entry/mirror-generate.sh` + `pe_sort_entries` function in `scripts/lib/per-entry/_lib.sh`)"

**Resolution method:** Read `scripts/lib/per-entry/_lib.sh` lines 380-410 — confirmed lines 393-401 are the docstring + body of `pe_sort_entries`.

#### NIT-3 site 5 — `tracker-migrate-reverse.sh:697, 733`

**Before (§3 observation §12.4 row):** "Verified `tracker-migrate-reverse.sh:697, 733` sort by `int(phase_number)`."

**After:** "Verified `_tmr_emit_implementation_plan` and `_tmr_emit_status` functions in `tracker-migrate-reverse.sh` sort phases by `int(phase_number)`."

**Resolution method:** Read `scripts/lib/tracker-migrate-reverse.sh` lines 695-735 — confirmed line 697 is the sort line in `_tmr_emit_implementation_plan` and line 733 is the sort line in `_tmr_emit_status`. Both are inside the named functions; function names suffice.

#### NIT-3 site 6 — §11.1 "(currently at line ~414-441)" (Multi-part phases)

**Before:** "**Section: Part 4 § "Multi-part phases" (currently at line ~414-441).**"

**After:** "**Section: Part 4 § "Multi-part phases" (under the Part 4 § "Multi-part phases" subhead).**"

**Resolution method:** Grepped `supporting-docs/METHODOLOGY.md` section list — confirmed Part 4 § "Multi-part phases" is the correct subhead name.

#### NIT-3 site 7 — §11.1 "(currently at line ~407-412)" (Phase numbering rules)

**Before:** "**Section: Part 4 § "Phase numbering rules" (currently at line ~407-412).**"

**After:** "**Section: Part 4 § "Phase numbering rules" (under the Part 4 § "Phase numbering rules" subhead).**"

**Resolution method:** Grepped `supporting-docs/METHODOLOGY.md` section list — confirmed Part 4 § "Phase numbering rules" is the correct subhead name.

#### NIT-3 site 8 — §11.2 "(currently at line ~243-313)" (Per-entry decomposition)

**Before:** "**Section: § "Per-entry decomposition" (currently at line ~243-313).**"

**After:** "**Section: § "Per-entry decomposition" (under the top-level § "Per-entry decomposition" heading).**"

**Resolution method:** Grepped `supporting-docs/MIGRATION-v10-to-v11.md` section list — confirmed lines 243-313 correspond to the top-level `## Per-entry decomposition` heading.

#### NIT-3 site 9 — §11.4 "(currently lines 18-24)" (_rules.md entry contract)

**Before:** "Extend the entry contract (currently lines 18-24):"

**After:** "Extend the entry contract (under the § "Entry contract" subhead):"

**Resolution method:** Read `project-template/docs/project/implementation-plan/_rules.md` — confirmed lines 18-24 are under the `## Entry contract` subhead.

#### NIT-3 site 10 — Additional line-number citation found in §5.4 (`tracker-migrate-reverse.sh:712`)

**Discovered during NIT-3 sweep but not on the explicit prompt list; fixed as same-class violation.**

**Before (§5.4 STATUS.md role):** "Implementation lives in `_tmr_emit_status` (`tracker-migrate-reverse.sh:712`) — modify the phase sort key from `phase_number` to the read execution-order value."

**After:** "Implementation lives in `_tmr_emit_status` function in `tracker-migrate-reverse.sh` — modify the phase sort key from `phase_number` to the read execution-order value."

**Resolution method:** Already verified in NIT-3 site 2; line 712 is the function definition.

#### NIT-3 site 11 — Additional line-number citation found in §4.6 (`tracker-sidecar.sh:289-303`)

**Discovered during NIT-3 sweep; fixed as same-class violation.**

**Before (§4.6 task_order discussion):** "The existing per-phase `task_order` sidecar field (`tracker-sidecar.sh:289-303`) stays per-phase."

**After:** "The existing per-phase `task_order` sidecar field (per `tracker_sidecar_compose_phase_tasks_block` function docstring in `tracker-sidecar.sh`) stays per-phase."

**Resolution method:** Read `scripts/lib/tracker-sidecar.sh` lines 285-313 — confirmed lines 289-303 are the docstring of `tracker_sidecar_compose_phase_tasks_block` (function defined at line 312).

#### NIT-3 site 12 — Additional line-number citation found in §7 (`tracker-migrate-reverse.sh:467-477`)

**Discovered during NIT-3 sweep; fixed as same-class violation.**

**Before (§7 ops table, `provider_sub_issue_create` row):** "Updates `tracker-migrate-reverse.sh:467-477` regex `^phase-\d+$` to admit ..."

**After:** "Updates the sub-issue parent regex `^phase-\d+$` (in `_tmr_decode_blockers` function in `tracker-migrate-reverse.sh`) to admit ..."

**Resolution method:** Read `scripts/lib/tracker-migrate-reverse.sh` lines 460-490 — confirmed line 467-477 is inside `_tmr_decode_blockers()` (regex match at line 473).

**Source finding for all NIT-3 sites:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.5 (line-number citations enumeration) + §4 NIT-3 row + §6 pack memory `feedback_filename_uniqueness`.

**NIT-3 residual:** Two remaining doc-cite line numbers (`ARCHITECTURE-V3.md:603` at §3 §12.6 row; `EXTERNAL-RESEARCH.md:53` at §4.2 sub-issue depth cite) were NOT on the explicit prompt list and were not modified — preserved per prompt scope discipline. Two label-namespace literals (`order:001`, `order:010` at §5.2) are NOT line-number citations (they're literal label values) — false positives from the broad grep pattern, intentionally preserved.

---

### NIT-4 — Same as MUST-3 (duplicate)

No separate fix. MUST-3's update to the §3 §12.7 evidence text resolves NIT-4's complaint about wording inconsistency between the §3 triage table and the §7 ops table. Confirmed by reading the post-fix doc: §3 §12.7 row now references "v11.0 ships at 18→20, v11.1+ at 20→21" which matches §7 §7 L696-L697.

---

### NIT-5 — §14.1 manifest-regen cross-reference

**Location:** `ARCHITECTURE-BD-185.md` §14.1 Schema + form-family files (below the table).

**Before:** §14.1 table listed `project-template/.github/ISSUE_TEMPLATE/work-item.yml` and pack-side mirror without a callout to the BD-176 manifest-regen trigger.

**After (note inserted below table):**

```
Note: edits to `project-template/.github/ISSUE_TEMPLATE/work-item.yml` and pack-side mirror trigger `test-fixtures/manifest.txt` regeneration per pack memory `feedback_manifest_regen_on_v11_surface` (BD-176 v11-surface trigger; cross-ref §14.9).
```

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §4 NIT-5 row + §6 pack memory `feedback_manifest_regen_on_v11_surface`.

---

## §6 — INFO-1 — no architect-doc action

**Source finding:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §4 INFO-1 row.

**Reviewer's INFO-1 framing:** §4.8 supersede verb spec defines the old-task → `status:superseded-by:Phase-N.Part-x.Task-M` transition but does not specify behavior when the old task is currently `in-progress` (open). The D4 spec is intentionally silent on this edge.

**Disposition:** No architect-doc action. Per D6 (`/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` §3.2 D6 row), the supersede-of-in-progress edge case is a verify-at-implementation-time detail for the planner / coder pass to resolve when the `pack task supersede` verb is implemented. The architect doc correctly leaves the choice open (force-close vs refuse-with-error) — planner / coder will resolve based on user workflow preference at implementation time and document the chosen behavior in the IMPL-REPORT for that verb's coder pass.

**Forward pointer:** Planner pass for BD-185 receives this INFO-1 as a forward-pointer attention item; coder pass for the `pack task supersede` verb implementation surfaces the decision in the per-commit IMPL-REPORT.

---

## §7 — Verification

### §7.1 — validate-pack.py output

Command: `python3 scripts/validate-pack.py`

Result (tail):

```
── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 1 scope-claiming commit(s) verified clean; 0 implicit-scope commit(s) skipped

── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 159 project-side file(s) walked; zero deny-list contamination (6 anchored LEGITIMATE-context hit(s) accepted; 585 fenced LEGITIMATE-content line(s) exempt per Guardrail 2)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

── Check 43: Project-side bare cross-reference scanner (BD-173) ──
  OK: Check 43 — 152 project-side / client-installed file(s) walked; zero pack-internal bare cross-references (578 allowlist-exempt + 18 anchor-phrase-exempt + 12 same-dir-legit + 140 client-installed-legit + 585 fenced-line(s) accepted)

── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

All 43 checks PASS — no regression from the architect-doc edits.

### §7.2 — Grep checks per prompt

| Check | Command | Expected | Actual |
|---|---|---|---|
| MUST-3 stale claim removed | `grep -c "19th in the surface" ARCHITECTURE-BD-185.md` | 0 | 0 PASS |
| MUST-4 both sites fixed | `grep -cE "per D4 / §4\.8\|D4.*§4\.7, §4\.8" ARCHITECTURE-BD-185.md` | ≥2 | 2 PASS |
| MUST-1 cancelled propagation | `grep -c "cancelled" ARCHITECTURE-BD-185.md` | increased | 11 (vs pre-fix ~10) PASS |
| NIT-3 line citations reduced | `grep -cE "line [0-9]+\|line ~[0-9]+\|:[0-9]+(-[0-9]+)?[^\\d]" ARCHITECTURE-BD-185.md` | significantly reduced | 4 (vs pre-fix ~13) PASS |

The 4 residual matches are:
- 2 doc-cites (`ARCHITECTURE-V3.md:603`, `EXTERNAL-RESEARCH.md:53`) NOT on the explicit prompt list — out of NIT-3 scope per prompt discipline.
- 2 false positives (`order:001`, `order:010`) which are literal label-namespace values, not line numbers.

---

## §8 — Cross-references

- **Source review report:** `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md` (PASS-WITH-MUSTS; 4 MUST + 4 SHOULD + 5 NIT + 1 INFO).
- **Architect doc edited:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (untracked at start; still untracked post-edits — Pack Chat to stage + commit per `feedback_agents_never_commit`).
- **Prior coder IMPL-REPORT:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md` (preserved unchanged — historical record of the prior 20-edit coder pass).
- **Researcher inventory:** `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` (unchanged; cross-reference target).
- **Pack memory pointers applied:**
  - `feedback_filename_uniqueness` — NIT-3 symbol-name substitutions.
  - `feedback_fix_all_review_findings` — triage authority for default FIX-ALL.
  - `feedback_manifest_regen_on_v11_surface` — NIT-5 cross-reference target.
  - `feedback_agents_never_commit` — no state-changing git verbs run during this fix pass.

---

## §9 — Success criteria checklist

| Criterion | Status |
|---|---|
| 1. All 4 MUST findings fixed | PASS — MUST-1 / MUST-2 / MUST-3 / MUST-4 applied |
| 2. All 4 SHOULD findings fixed | PASS — SHOULD-1 / SHOULD-2 / SHOULD-3 / SHOULD-4 applied |
| 3. All 5 NIT findings fixed (NIT-4 resolved by MUST-3) | PASS — NIT-1 / NIT-2 / NIT-3 (12 sites) / NIT-4 (by MUST-3) / NIT-5 applied |
| 4. INFO-1 confirmed no-action | PASS — documented in §6 of this report; planner forward-pointer noted |
| 5. validate-pack.py PASS | PASS — all 43 checks clean |
| 6. No source code changed | PASS — only `ARCHITECTURE-BD-185.md` modified |
| 7. No other docs modified | PASS — review report preserved at `/tmp/PACK-REVIEW-BD-185-ARCHITECT-DOC.md`; prior IMPL-REPORT preserved at `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md`; inventory preserved at `TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` |
| 8. IMPL-REPORT written | PASS — this document at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md` |

---

## §10 — Files touched inventory

| Path | Change type | Lines changed (approx.) | Notes |
|---|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | MODIFIED | ~24 edits across 17 sections | 13 review findings + 3 additional NIT-3 same-class violations swept in; untracked at start; still untracked post-edits |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md` | NEW | this document | The fix-coder IMPL-REPORT |

**No other files modified.** No state-changing git verbs run. Branch state unchanged from HEAD `4d1f9e55a895a64e0304b8d13bd0c3b020c46363`.

---

## End of fix-coder IMPL-REPORT
