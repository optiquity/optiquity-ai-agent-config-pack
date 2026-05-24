# IMPLEMENTATION-REPORT — BD-173 Batch 19c H.12/H.13 reorder (architect-spec gap correction + doc-revision-only commit)

**Status:** COMPLETE — doc-revision-only commit (pack-only; `maintenance-docs/` scope).

**Outcome:** 3 architect/planner docs revised + 1 new consolidated audit/IMPL-REPORT written. Source code unchanged. validate-pack.py PASS at HEAD post-revision. No v11-surface touched (no manifest regen required).

**Commit context:** Batch 19c, BD-173. This commit lands between H.11 (`6e2d406`) and the next implementation commit (post-reorder, this will be PLAN H.13 / Batch 19c.13). The commit captures the 2026-05-24 architect-spec gap correction following the STOP-AND-ESCALATE evidence produced by the failed initial H.12 (Guardrail 3) coder run.

---

## §1 Scope

### 1.1 Commit purpose

Doc-revision-only commit recording the 2026-05-24 reorder decision + scope expansion:

- **Reorder:** PLAN H.13 (Guardrail 2 per-line fence) executes BEFORE PLAN H.12 (Guardrail 3 scope expansion). PLAN H.N names are PRESERVED per Pack Chat user direction B2 (NOT renumbered).
- **Scope expansion:** PLAN H.13's `_CHECK_37_PER_LINE_FENCE_FILES` enumeration extends from 7 to 11 entries (+4 dual-surface files: `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/lib/detect.sh`, `scripts/pack-help.sh`).

### 1.2 Files modified by this commit

All under `maintenance-docs/v11-implementation/` (pack-only scope):

| Path | Change type | Lines (approx) |
|---|---|---|
| `PLAN-CLEANUP-BATCH-19C.md` | Modified — H.12 + H.13 + H.14 entries revised; §3 α-sliding summary updated; §4 per-commit table rows for H.12/H.13/H.14 revised; §4 breakdown paragraph revised | +60 / -20 |
| `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` | Modified — §H.12 + §H.13 + §H.14 entries revised; §I sliding-window summary updated; D-10 row in decisions table updated; §J.6 sliding-window refinement paragraph updated | +30 / -10 |
| `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | Modified — §0.3 implementation-order table revised; §2.3 `_CHECK_37_PER_LINE_FENCE_FILES` constant extended from 7 to 11 entries with rationale block; §2.4 fence placement plan table extended with 4 new dual-surface rows + shell-script fence-marker syntax note; §3.3 "Pre-sweep PASS verification" paragraph corrected (replaces the factually-wrong pre-2026-05-24 claim with the 26-leak STOP-AND-ESCALATE evidence + reordered commit sequence + corrected self-validating-change principle); §5.1 implementation-order table + sequence rationale revised; §5.1 alternative-order considered (Option A vs B vs C) added | +110 / -25 |
| `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md` | NEW — this consolidated audit / IMPL-REPORT | ~220 |

### 1.3 Out-of-scope confirmations

- **No source code changed.** `git diff --stat scripts/ project-template/ supporting-docs/ test-fixtures/` returns empty.
- **No CI/workflow files changed.** `.github/workflows/` untouched.
- **No PM-only files edited.** No `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `README.md` version table, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), or `project-template/` trinity edits.
- **No git state-changing verbs run.** Only read-only verbs (`git rev-parse`, `git status`, `git diff`, `git log`) used.
- **No manifest regen.** No v11-surface touched (per BD-176 4-directory trigger: `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`).

---

## §2 STOP-AND-ESCALATE evidence (from initial H.12 Guardrail 3 coder run)

### 2.1 Architect's original claim (GUARDRAILS-CONTRACT.md §3.3, pre-2026-05-24)

The original §3.3 "Pre-sweep PASS verification" paragraph asserted:

> "running Check 37 with the expanded scope at HEAD (pre-sweep) will FAIL on the 2 detect.sh leaks (which qualified `maintenance-docs/` prefix already triggers Check 37's path-prefix detection) ... detect.sh failures must be FIXED (Category D sweep) BEFORE Guardrail 3 commit lands."

The architect anticipated **2 leaks** (both in `scripts/lib/detect.sh` with `maintenance-docs/` path-prefix), to be cleared by H.10 (Cat D).

### 2.2 Actual leak inventory at HEAD post-H.11 (`6e2d406`)

The initial H.12 (Guardrail 3) coder applied Edits 1+2+3 verbatim per architect §3.1 + §3.2 (added `_iter_client_installed_files()` helper; replaced `_PROJECT_SIDE_ROOTS` constant; rewrote `_iter_project_side_files()` body as thin alias). Then ran `python3 scripts/validate-pack.py`.

**Result: 26 Check 37 failures** (not 2):

| File | Leak count | Sites | Pattern type | Architect-anticipated? |
|---|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | 5 | L119, L1561, L1579, L1585, L1587 | `Pack Chat` capitalized role-name (pedagogical) | NO |
| `supporting-docs/INSTALL-PROCEDURES.md` | 2 | L301, L609 | `Pack Chat` escalation references (pedagogical) | NO |
| `scripts/pack-help.sh` | 22 (15 distinct lines × ~1.5 hits each) | L38, L39, L86, L87, L92, L106, L112, L113, L114, L115, L119, L120, L133, L136, L153, L169 | `HELP-FRAGMENT-PACK.md` filename + `pack-ops/` path-prefix in functional dual-surface code | NO |
| `scripts/lib/detect.sh` | 3 | L23, L31, L43 | `pack-ops/` path-prefix in functional code comments (NOT the 2 `maintenance-docs/` leaks H.10 cleared) | NO (architect anticipated different leaks in this file) |
| **Total** | **26** | | | |

**Architect-anticipation gap:** 24 unanticipated leaks (~92% of total).

### 2.3 Nature of the 26 unanticipated leaks

These are NOT contamination leaks the BD-175 / BD-179 framework is designed to catch. They are:

**(a) Legitimate explanatory content** about pack-vs-client roles. Example from `supporting-docs/METHODOLOGY.md:1561`:

```
The PM chat is the only entity that observes the AI Agent Config Pack
running on real production work. The Pack Chat (the upstream maintainer
of the pack) has no visibility into how the pack behaves outside the
pack repo. The PM chat's responsibility is to observe, record, and
report back.
```

This is LEGITIMATE explanatory content about the pack-vs-client distinction in a CLIENT-INSTALLED file. Removing the `Pack Chat` reference would damage the doc's explanatory purpose. The architect's `_is_legitimate_deny_list_doc()` whole-file exemption list (validate-pack.py L4124) covers `project-template/docs/pack/METHODOLOGY.md` (the SHIPPING path), but the source path `supporting-docs/METHODOLOGY.md` (where the file lives in the pack repo, and what `_CLIENT_INSTALLED_FILES` lists) does not match the exemption — the source path is what `_iter_client_installed_files()` returns.

**(b) Functional code references** to pack-side paths in dual-surface scripts that branch on detected surface. Example from `scripts/pack-help.sh`:

```sh
if [[ -f "$root/pack-ops/HELP-FRAGMENT-PACK.md" ]]; then
    echo "$root/pack-ops/HELP-FRAGMENT-PACK.md"
elif [[ -f "$root/HELP-FRAGMENT-PACK.md" ]]; then
    echo "$root/HELP-FRAGMENT-PACK.md"
fi
```

The script runs both on the pack repo (where `pack-ops/` exists) AND in client repos (where it doesn't, and the script branches accordingly). The `pack-ops/` and `HELP-FRAGMENT-PACK.md` references cannot be removed without breaking the script.

Example from `scripts/lib/detect.sh:43`:

```sh
for backlog in "$target/pack-ops/BACKLOG.md" "$target/docs/project/BACKLOG.md" "$target/BACKLOG.md"; do
```

Same dual-surface pattern — functional code that literally needs to look at `$target/pack-ops/BACKLOG.md` when running in the pack repo.

### 2.4 Initial H.12 coder action: STOP-AND-ESCALATE

Per system-prompt rule "If you find a real gap, document it in the report as a new POQ and proceed with the plan's recommended default" — and per pack memory `feedback_pack_agent_rule_hallucination` (no silent absorption of out-of-scope fixes) — the initial H.12 coder reverted both edits and produced a STOP-AND-ESCALATE report at `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md`. The working tree was returned to clean state at `6e2d406`. No commit was produced from the initial H.12 run.

The initial H.12 coder's recommendation: **Option B (re-order H.13 before H.12)** as the architecturally cleanest approach. Pack Chat then triaged + surfaced to user; user direction was Option B + B2 (preserve PLAN H.N names; commit log shows "Batch 19c.13" before "Batch 19c.12").

### 2.5 Cross-references to initial STOP-AND-ESCALATE evidence

- `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (still in working tree as untracked file at HEAD `df64afc`; will be overwritten when the new H.12 Guardrail 3 coder runs against the revised spec post-H.13). Sections preserved here:
  - §3.1 architect's original assumption text
  - §3.2 26-leak inventory at HEAD
  - §3.3 architect contract evidence on the gap
  - §3.4 nature of unanticipated leaks (LEGITIMATE explanatory + functional dual-surface)
  - §3.5 framework-fit: Guardrail 2's per-line fence (H.13) is the architecturally correct tool for the dual-surface code blocks
  - §7 POQ-H.12-1 (architect-spec gap + 3 disposition options)
  - §10 Pack Chat next-steps recommendation

---

## §3 Pack Chat triage + user direction

### 3.1 Triage timeline (2026-05-24)

1. **Pack Chat read** the STOP-AND-ESCALATE report from the initial H.12 coder.
2. **Pack Chat triaged** the 3 disposition options surfaced in the report's §7 POQ-H.12-1:
   - **Option A:** Extend `_is_legitimate_deny_list_doc()` whole-file exemption from 11 to 15 entries (add 4 dual-surface files as whole-file-exempt).
   - **Option B:** Re-order H.13 (per-line fence) BEFORE H.12 (scope expansion); expand H.13's `_CHECK_37_PER_LINE_FENCE_FILES` from 7 to 11 to cover the 4 dual-surface files via per-line fence.
   - **Option C:** Insert a new Cat G commit between H.11 and H.12 covering the 4 dual-surface files as a separate sweep commit (procedurally equivalent to Option A, architecturally identical).
3. **Pack Chat surfaced** the triage to user with implementer-side recommendation = Option B.

### 3.2 User direction (2026-05-24)

User directed **Option B** with the following sub-direction on naming:

- **B1 (option not chosen):** Renumber PLAN H.13 → PLAN H.12 and PLAN H.12 → PLAN H.13 so the PLAN H.N names match commit order.
- **B2 (option chosen):** Preserve PLAN H.N names; commit log shows "Batch 19c.13" landing BEFORE "Batch 19c.12" — intentional per reorder.

**Rationale for B2:** existing PLAN H.13 references in:
- Committed BD-190 entry at `pack-ops/BACKLOG.md` lines L2832, L2836, L2850, L2852 (4 references).
- `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` at 6 sites (§5.1 commit-sequence table, §5.1 sequence rationale, multiple cross-references).

Renumbering under B1 would break all 10+ references and require cascading edits across committed-history docs. B2 preserves naming stability at the cost of unusual commit-log ordering (which is documented in the reorder paragraph itself).

### 3.3 Why Option A was rejected

Per the initial H.12 coder's §7 analysis:
> "extends the whole-file exemption surface from 11 to 15 files when the H.13 fence framework was designed to REDUCE whole-file exemptions toward per-line fence-based exemptions. May be a step in the wrong direction architecturally."

The BD-175 / BD-179 framework + GUARDRAILS-CONTRACT.md §2 explicitly moves AWAY from whole-file exemption toward per-line fence. Option A would have moved AGAINST the architectural direction.

### 3.4 Why Option C was rejected

Per the initial H.12 coder's §7 analysis:
> "shape is essentially the same as Option A, just split into 2 commits. Doesn't change architectural direction."

Option C was procedurally honest (explicit Cat G commit) but architecturally identical to Option A.

---

## §4 Edits applied

### 4.1 PLAN-CLEANUP-BATCH-19C.md (3 entries revised + summary text)

**§3 H.12 entry:** Added "EXECUTION ORDER" preamble + revised "Ordering dependency" paragraph. The new ordering text names: "MUST land AFTER H.13 (per-line fence covers 4 dual-surface files so scope expansion ratifies cleanly) AND AFTER H.10 (Cat D detect.sh fixes)." References the 26-leak STOP-AND-ESCALATE evidence + this audit doc.

**§3 H.13 entry:** Added "EXECUTION ORDER" preamble; revised scope (7 → 11 files); extended **Files modified** list with 4 new dual-surface entries (METHODOLOGY.md, INSTALL-PROCEDURES.md, detect.sh, pack-help.sh); added shell-script fence-marker syntax note; revised per-commit reviewer paragraph (now H.13 alone, not H.12+H.13); revised PREFLIGHT line shape (9 → 13 file edits); revised commit subject + Ordering dependency text.

**§3 H.14 entry:** Revised per-commit reviewer paragraph (now H.12+H.14, not H.14 alone); added sliding-window H.12-coverage bullet.

**§3 prelude:** Updated the α-sliding summary paragraph to reflect new ordering H.13 → H.12 → H.14.

**§3 H.12 item 4 (Group 7 sequencing note):** Updated to reflect Group 6 lands first (via H.13) then Group 7 (via H.12) — natural numerical sequencing under reorder.

**§3 H.13 item 10 (Group 6 ordering comment):** Updated to remove the §2.6-vs-§3.4 ordering-inversion note (resolved by reorder).

**§4 per-commit table rows:** Revised H.12 + H.13 + H.14 rows. Annotated row execution order in the row label.

**§4 breakdown paragraph:** Revised sliding-window mapping summary to reflect new ordering.

### 4.2 ARCHITECTURE-CLEANUP-BATCH-19C-V2.md (3 entries revised + summary text)

**§H.12 entry:** Added "EXECUTION ORDER" preamble + revised SKIP-per-commit reviewer note (now "covered by H.14 sliding-window picks up H.12+H.14"); revised Rationale paragraph with 26-leak evidence + corrected "self-validating change" principle text.

**§H.13 entry:** Added "EXECUTION ORDER" preamble; revised scope (7 → 11 files); extended **Files modified** list with 4 new dual-surface entries; revised Per-commit reviewer text (H.13 alone); revised RC9 manifest regen line (now adds supporting-docs/); revised commit subject; revised Rationale paragraph.

**§H.14 entry:** Revised Per-commit reviewer text (now H.12+H.14).

**§D-10 row:** Updated to reflect post-reorder coverage windows.

**§I sliding-window summary:** Updated to reflect new ordering.

**§J.6 sliding-window refinement paragraph:** Updated to reflect new ordering.

### 4.3 ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md (5 sections revised)

**§0.3 Implementation order table:** Added PLAN H.N column; reordered rows so Guardrail 2 / PLAN H.13 lands BEFORE Guardrail 3 / PLAN H.12; updated Guardrail 2 row to indicate "11 files — expanded from 7"; added per-row reorder annotations.

**§2.3 `_CHECK_37_PER_LINE_FENCE_FILES` constant:** Extended from 7 to 11 entries with inline rationale comment block before the 4 new entries (`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/lib/detect.sh`, `scripts/pack-help.sh`). Each entry carries a one-line rationale (sites + reason). Added a paragraph after the constant block noting the difference between deny-list-enumeration files (original 6) vs LEGITIMATE pedagogical/functional pack-internal references (4 new). Added a shell-script fence-marker syntax block describing `# <!-- DENY-LIST-CONTENT-START -->` form for detect.sh + pack-help.sh.

**§2.4 fence placement plan table:** Extended from 4 row-groups to 8 row-groups (added rows for PM-CHAT.md + 4 new dual-surface files). Each new row names: current behavior, new fence placement (including specific line numbers per leak inventory), and rationale. Added a post-table shell-script fence-marker syntax note.

**§3.3 "Pre-sweep PASS verification" paragraph:** Replaced the factually-wrong pre-2026-05-24 wording (which claimed only 2 leaks would surface at HEAD) with:
- Statement that the original wording was factually wrong at HEAD.
- 26-leak inventory table.
- Statement that the 26 leaks are LEGITIMATE pack-internal references (NOT contamination).
- Corrected ordering contract: H.10 (sweep) + H.13 (per-line fence covering 11 files) MUST BOTH land BEFORE H.12 (scope expansion) ratifies the cleaned state.
- Reordered commit sequence (post-2026-05-24).
- Note on PLAN H.N name preservation per user direction B2.
- Updated "self-validating change" principle.
- Cross-reference to this audit doc.

**§5.1 Implementation order (commit sequence):** Revised the commit-sequence table (Guardrail 2 / PLAN H.13 now lands BEFORE Guardrail 3 / PLAN H.12; PLAN H.N labels added); revised sequence rationale (Leak sweep first → Guardrail 2 second → Guardrail 3 third → Guardrail 1 fourth → Guardrail 4 last); added "Alternative order considered 2026-05-24 (Options A + B + C)" paragraph documenting why Option A and Option C were rejected.

### 4.4 New audit/IMPL-REPORT doc (this file)

Written from scratch as consolidated audit + IMPL-REPORT. Sections §1-§9 per Pack Chat's audit-doc conventions (Scope, STOP-AND-ESCALATE evidence, Pack Chat triage + user direction, Edits applied, Execution-order note, Verification, Out-of-scope confirmations, Definition-of-Done, Cross-references).

---

## §5 Execution-order note (going forward)

### 5.1 Commit-log ordering convention

Per Pack Chat user direction B2 (2026-05-24): PLAN H.N names are PRESERVED across the reorder. Going forward:

- Batch suffixes (`Batch 19c.NN`) reflect PLAN H.N names, NOT execution order.
- Commit log will show "Batch 19c.13" landing BEFORE "Batch 19c.12" — intentional per the reorder.
- Cross-references to PLAN H.N continue to read the same as before (H.12 = Guardrail 3 scope expansion; H.13 = Guardrail 2 per-line fence).
- The reorder is documented inline in each H.N entry of PLAN + V2 + GUARDRAILS-CONTRACT (per Edits §4.1 + §4.2 + §4.3) so a future reader landing in any of those docs sees the execution-order note without needing this audit doc.

### 5.2 Sliding-window reviewer mapping (post-reorder)

Post-2026-05-24-reorder execution order: H.13 → H.12 → H.14 → H.15 → H.16 → H.17.

Sliding-window mapping (per PLAN §3 + V2 §I + §J.6):

| INLINE reviewer | Covers | Notes |
|---|---|---|
| H.4 | H.1-H.4 (4 commits) | Unchanged from pre-reorder |
| H.5 | H.5 alone | Unchanged |
| H.9 | H.6+H.7+H.9 (3 commits; H.8 removed) | Unchanged |
| H.10 | H.10 alone | Unchanged |
| H.11 | H.11 alone | Unchanged |
| **H.13** | **H.13 alone** (post-reorder; H.12 has not yet executed) | CHANGED per reorder (was: covered H.12+H.13) |
| **H.14** | **H.12+H.14** (post-reorder sliding-window picks up intervening SKIP-per-commit H.12) | CHANGED per reorder (was: covered H.14 alone) |
| H.15 | H.15 alone | Unchanged |
| H.16 | H.16 alone | Unchanged |
| H.17 | End-of-batch backstop over full H.0 → H.16 diff | Unchanged |

### 5.3 Architect-doc-vs-reality reconciliation chain

Per pack memory `Architect-doc-vs-reality reconciliation` (CLAUDE.md `## Pack memory` § "Repo conventions"):

When PLAN H.13 commit lands (post-reorder, with expanded 11-file fence), the IMPL-REPORT for PLAN H.13 must cross-reference:
1. The realized consumer (the 4 dual-surface files now fence-allowlisted): `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` + `scripts/lib/detect.sh` + `scripts/pack-help.sh`.
2. The architect-doc cite naming the realized consumer: `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §2.3 (`_CHECK_37_PER_LINE_FENCE_FILES` constant; 4 new entries with rationale).
3. This reorder audit doc.

When PLAN H.12 commit lands (post-reorder, scope expansion), the IMPL-REPORT for PLAN H.12 must cross-reference:
1. The cleaned-state precondition (PLAN H.13 fence covers 11 files).
2. The architect-doc cite: `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §3.3 (corrected Pre-sweep PASS verification).
3. This reorder audit doc.

---

## §6 Verification

### 6.1 validate-pack.py PASS at HEAD post-revision

```
$ python3 scripts/validate-pack.py
... (42 checks) ...
PASSED — all checks clean
```

Doc-revision-only commits do not change validate-pack.py behavior; CI continues to pass.

### 6.2 No source code changed

```
$ git diff --stat scripts/ project-template/ supporting-docs/ test-fixtures/
(empty — no files in these paths changed)
```

Confirmed: this commit touches only `maintenance-docs/v11-implementation/`.

### 6.3 Pre-existing untracked file preserved

The initial H.12 coder's STOP-AND-ESCALATE report at `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (343 lines; untracked at HEAD `df64afc`) is LEFT IN PLACE per the system prompt's explicit direction. The new H.12 (Guardrail 3) coder, when it runs against the revised spec post-H.13, will eventually overwrite this file with its own (PASS-ing) IMPL-REPORT. This audit doc preserves the STOP-AND-ESCALATE evidence in §2.

### 6.4 Doc-internal cross-references

Verified by grep:

```
$ grep -c "IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md" \
    maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md \
    maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md \
    maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md
PLAN-CLEANUP-BATCH-19C.md: 3 references (H.12 entry execution-order note, H.13 entry execution-order note, H.12 Ordering dependency)
ARCHITECTURE-CLEANUP-BATCH-19C-V2.md: 2 references (§H.12 execution-order note, §H.13 execution-order note)
ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md: 4 references (§2.3 constant block, §3.3 corrected verification statement, §3.3 cross-reference paragraph, §5.1 sequence rationale)
```

All 3 revised docs cross-reference this audit doc. This audit doc cross-references all 3 revised docs in §4 above.

---

## §7 Out-of-scope confirmations + boundary discipline check

### 7.1 Confirmed out-of-scope behavior

- **No project-template/ edits.** Confirmed via `git diff --stat project-template/` → empty.
- **No supporting-docs/ edits.** Confirmed via `git diff --stat supporting-docs/` → empty.
- **No scripts/ edits.** Confirmed via `git diff --stat scripts/` → empty.
- **No test-fixtures/ edits.** Confirmed via `git diff --stat test-fixtures/` → empty.
- **No .github/workflows/ edits.** Confirmed via `git diff --stat .github/` → empty.
- **No PM-only files edited.** No `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `README.md` version table, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, root or `project-template/` trinity edits.
- **No git state-changing verbs.** Only read-only verbs (`git rev-parse`, `git status`, `git diff`, `git log`) used.
- **No manifest regen.** No v11-surface touched (per BD-176 4-directory trigger: `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`); only `maintenance-docs/` modified, which is NOT a v11-surface directory.

### 7.2 Boundary discipline check (pack-only scope)

This commit only modifies `maintenance-docs/v11-implementation/` content. None of the edits touch project-side surfaces or client-installed surfaces. The edits are PACK-INTERNAL architect/planner/IMPL-REPORT docs — pack-coder/Pack-Chat operating state, not pack product.

- No `project-template/` edits → no SSOT-investigation required for project-side surfaces.
- No `supporting-docs/` edits → no client-installed-doc impact.
- No project-side surface affected → no Pack Chat→project boundary discipline concern.

**Pack-only scope keyword justification:** the planned commit subject `feat: v11 — BD-173 doc-revision-only for H.12/H.13 reorder + scope expansion (pack-only)` carries `(pack-only)`. CI Check 36 would PASS scope honesty — only `maintenance-docs/` paths are touched.

### 7.3 Subsequent commits (per the reorder; H.12 + H.13 coders run separately)

- **Next implementation commit (post-this-doc-revision):** PLAN H.13 / Batch 19c.13 = Guardrail 2 per-line fence (`_is_legitimate_deny_list_doc()` → `_has_per_line_fence()` + fence-skip-lineset + 11 fenced files). A fresh pack-coder spawn against the revised PLAN/V2/GUARDRAILS-CONTRACT specs.
- **Commit after that:** PLAN H.12 / Batch 19c.12 = Guardrail 3 scope expansion (`_PROJECT_SIDE_ROOTS` → `_iter_client_installed_files()`). A fresh pack-coder spawn against the (now factually correct) revised spec. The new H.12 coder will overwrite the pre-existing untracked STOP-AND-ESCALATE file `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` with its own PASS-ing IMPL-REPORT.
- **Commits after that:** PLAN H.14 (Check 43), PLAN H.15 (PREFLIGHT extension), PLAN H.16 (METHODOLOGY Part 1 additions), PLAN H.17 (end-of-batch reviewer + BD-173 status flip).

---

## §8 Definition-of-Done

| Item | Status |
|---|---|
| Branch + final HEAD SHA on worktree | PASS — `v11-dev` at `df64afc` (unchanged from start; this is a doc-revision-only commit not yet staged/committed) |
| Per-task summary (files touched + verification commands + results) | PASS — see §4 + §6 |
| Full file contents for new files | PASS — this doc IS the new file (full contents present) |
| Plan deviations | ZERO — all 4 revisions match the architect-spec gap correction per Pack Chat user direction B2 (no scope/spec deviations) |
| New POQs introduced | ZERO new POQs (the original POQ-H.12-1 from the initial H.12 coder's report is now RESOLVED by this reorder) |
| Definition-of-Done checklist | this table |
| Files changed inventory | see §1.2 above |
| validate-pack.py PASS at HEAD post-revision | PASS — see §6.1 |
| No source code changed (diff against scripts/, project-template/, supporting-docs/, test-fixtures/ empty) | PASS — see §6.2 + §7.1 |
| Architect-doc-vs-reality reconciliation chain documented | PASS — see §5.3 (deferred enactment lands when PLAN H.13 + H.12 IMPL-REPORTs are written by their respective coders) |
| Pre-existing STOP-AND-ESCALATE file preserved | PASS — see §6.3 |

---

## §9 Cross-references

### 9.1 Pack memory anchors

- `feedback_no_destructive_without_approval` — no destructive ops; all edits are doc-revision Edit calls; no file deletions.
- `feedback_pack_chat_does_no_fixes` — this commit was implemented by pack-coder (doc-revision mode), NOT by Pack Chat directly.
- `feedback_review_carry_forward_discipline` — the reorder decision was prompted by a STOP-AND-ESCALATE (architect-spec gap), surfaced per OQ-1 / `feedback_deferral_is_scope_creep`. Pack Chat triaged + user-directed in real-time; no deferral.
- `feedback_user_prescriptive_authority` — Pack Chat surfaced Options A/B/C with implementer-side recommendation (B); user retained authority and prescribed B + B2; default-accept on the implementer recommendation, with user-prescriptive sub-direction on the naming question.
- `feedback_manifest_regen_on_v11_surface` — no v11-surface touched by this commit; manifest regen NOT required.

### 9.2 Pack-repo docs touched + referenced

- **Touched (revised):** `PLAN-CLEANUP-BATCH-19C.md`, `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`, `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`.
- **Touched (NEW):** this doc (`IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`).
- **Referenced (read-only):** `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (untracked STOP-AND-ESCALATE evidence preserved into §2 above).
- **Referenced (read-only):** `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` (background context for the leak-sweep framework; not edited).
- **Referenced (read-only):** `pack-ops/BACKLOG.md` BD-190 entry (committed at `df64afc`; not edited; cited as a B2-rationale-driver).

### 9.3 Recommended Pack Chat next steps

1. **Stage + commit this doc-revision-only commit** with the user-approved commit message:
   ```
   docs: v11 — BD-173 H.12/H.13 reorder + scope expansion doc revisions (pack-only)
   ```
   Or the user's preferred shape.
2. **Spawn fresh pack-coder for PLAN H.13** (Guardrail 2 per-line fence; 11 files; expanded scope per revised spec). The coder prompt cites the revised PLAN H.13 + V2 §H.13 + GUARDRAILS-CONTRACT.md §2 (with the 2026-05-24 11-file `_CHECK_37_PER_LINE_FENCE_FILES` constant + §2.4 placement plan + the shell-script fence-marker syntax block).
3. **After PLAN H.13 commit lands (Batch 19c.13):** spawn fresh pack-coder for PLAN H.12 (Guardrail 3 scope expansion; spec unchanged from original architect text; the precondition state is now H.13-cleared so validate-pack.py PASSES post-H.12).
4. **After PLAN H.12 commit lands (Batch 19c.12):** spawn fresh pack-coder for PLAN H.14 (Check 43); INLINE reviewer covers H.12+H.14 per the post-reorder sliding-window mapping.
5. **Continue per PLAN §3 + §4 reviewer-coverage column for H.15, H.16, H.17.**

---

**End of report.**
