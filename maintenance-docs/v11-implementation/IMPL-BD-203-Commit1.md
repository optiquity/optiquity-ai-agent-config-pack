# IMPL-BD-203-Commit1 — PRE-NORMALIZE the monolith (Phase B0; tasks B0a–B0c)

**Agent:** pack-coder (RE-SPAWN of the rejected Commit-1 coder) · **Date:** 2026-06-04 · **Branch:** v11-dev
**Worktree HEAD (start == end; agents never commit):** `fcdcbc49b2b6013ec02e9dcde0a63cda9767f3b4` (`fcdcbc4`)
**Scope:** B0a–B0c per `PLAN-BD-203.md` §2 Phase B0 + `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §C. Single in-scope EDIT file: `pack-ops/BACKLOG.md` (PM-only, scoped IN by the caller). NO `/backlog/` or `/changelog/` tree created (that is Commit 2).

> Re-spawn note: the prior Commit-1 coder's BACKLOG output was correct but its IMPL-REPORT was REJECTED for a read-in-full violation (it DERIVED the 6 named memory files from the `CLAUDE.md ## Pack memory` cache / the amendment instead of reading each DIRECTLY). This pass reads EACH named document directly via the Read tool and proves it per-file (see the READ-IN-FULL row).

---

## 1. HEADLINE RESULT (lead — scope-deliverables-to-the-ask)

- **BEFORE header count** (`grep -cE '^\*\*BD-'`, HEAD `fcdcbc4` == working tree at start): **191**
- **AFTER header count** (working tree post-edit): **210**  → **210 == 191 + 19** ✔ (measured, NOT hard-coded; the design docs measured 190 at an earlier HEAD — the BACKLOG grew by 1, exactly why the invariant is "BEFORE + 19", not a literal 209/210).
- **H2 sections remaining:** **0** (flat uniform list) ✔
- **v8 table rows remaining** (`^\| BD-0`): **0** ✔
- **Diff:** exactly +19 new BD-001..019 entry blocks + the scaffolding removals; **ZERO** change to any pre-existing entry body ✔
- **Files modified:** `pack-ops/BACKLOG.md` ONLY. No tree. No other file. ✔

---

## 2. WHAT WAS DONE (B0a / B0b / B0c)

### B0a — promote the 19 v8 table rows to real entries
Each `| BD-00N | <desc> | <hash> |` row became the canonical short entry (amendment §C), carrying the row's three fields verbatim (Item → header + Description; Commit hash → `Resolved:` line). NO history mining (D3). Shape per entry:

```
**BD-00N — <desc>**
Type: TODO(version)
Status: Resolved
Resolved: commit <hash> (v8, March 2026)
Description: <desc>.
```

The 19 entries, with the hash carried verbatim from the table:

| ID | Commit hash (verbatim) | ID | Commit hash | ID | Commit hash |
|---|---|---|---|---|---|
| BD-001 | 08f7158 | BD-008 | 2fc4a0c | BD-015 | 2fc4a0c |
| BD-002 | 08f7158 | BD-009 | 2fc4a0c | BD-016 | 9cd9a7f |
| BD-003 | 9cd9a7f | BD-010 | 2fc4a0c | BD-017 | 08f7158 |
| BD-004 | 08f7158 | BD-011 | 61b3381 | BD-018 | 9a6ba5b |
| BD-005 | 08f7158 | BD-012 | 2fc4a0c | BD-019 | 2fc4a0c |
| BD-006 | 61b3381 | BD-013 | 9a6ba5b | | |
| BD-007 | 2fc4a0c | BD-014 | 9a6ba5b | | |

### B0b — flatten the scaffolding to a uniform `**BD-NNN —**` list separated by `---`
Removed (preserved in git history; Commit 2 relocates the useful preamble part to `/backlog/_intro.md` — NOT relocated now per scope):
- `## How to use this file` preamble + its 8 bullets (BACKLOG L9-19).
- `## Active — v11 Scope` H2 + its 5-line blurb ("The v11.0 implementation surface…").
- `## Active — v10 Scope` H2 (the FALSE "Active" label drops; its 5 entries BD-059/020/021/022/023 SURVIVE with TRUE statuses {Resolved, Open, Deprecated×3}).
- `## Resolved — v8 (March 2026)` H2 + its blurb ("All BD-001 through BD-019 items resolved…") + the table WRAPPER (`| Item | Description | Commit |` + `|---|---|---|`).
- `## Deferred` H2 (its 11 entries survive with `Status: Deferred`).

All inter-entry `---` separators preserved; each removed H2 left a single `---` boundary so the list stays uniform.

### B0c — diff gate
The monolith→monolith diff is EXACTLY (a) +19 new entry blocks, (b) −preamble/−4 grouping H2s/−2 blurbs/−table-wrapper/−19 table rows, and NO change to any existing entry body. Evidence in §4.

---

## 3. EDIT METHOD (edit-in-place-not-full-rewrite)
Five TARGETED `Edit` calls (insert/delete specific blocks) — NOT a full-file rewrite. No entry body was reflowed, reordered, or dropped. The red-line invariant (preserve every entry) is verified by the BEFORE/AFTER header count (191 → 210 = +19, no losses) and by the diff containing zero deletions of any `**BD-NNN —**` body (§4).

| # | Block targeted | Action |
|---|---|---|
| 1 | `## Deferred` H2 | delete header, keep `---` + BD-031 |
| 2 | `## Resolved — v8` H2 + blurb + table wrapper + 19 rows | replace with 19 flat entries `---`-separated |
| 3 | `## Active — v10 Scope` H2 | delete header, keep `---` + BD-059 |
| 4 | `## Active — v11 Scope` H2 + blurb | delete, keep `---` + BD-060 |
| 5 | `## How to use this file` preamble | delete, keep intro paragraph + `---` |

---

## 4. VERIFICATION (all commands run; verbatim results — verify-full-ci-suite)

### V1 — header count BEFORE vs AFTER
```
$ git show HEAD:pack-ops/BACKLOG.md | grep -cE '^\*\*BD-'   → 191   (BEFORE)
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md                   → 210   (AFTER)
210 == 191 + 19   ✔
$ grep -oE '^\*\*BD-[0-9]+[a-z]* ' pack-ops/BACKLOG.md | sort -u | wc -l → 210  (unique IDs)
$ grep -nE '^## ' pack-ops/BACKLOG.md → (no H2 — flat)   ✔
$ grep -cE '^\| BD-0' pack-ops/BACKLOG.md → 0             ✔
```
Status distribution AFTER (Resolved 147→166 = +19; all other buckets unchanged):
```
1 Cancelled  11 Deferred  3 Deprecated  28 Open  166 Resolved  1 Unblocked   (= 210)
```
New BD-001..019 full-entry headers now exist (spot: BD-001/002/010/019 each → 1).

### V2 — B0c diff gate (git diff evidence)
```
$ git diff --stat -- pack-ops/BACKLOG.md
 pack-ops/BACKLOG.md | 198 +++++++++++++++++--------------
 1 file changed, 147 insertions(+), 51 deletions(-)
```
**Every removed non-blank/non-separator line** (`git diff -U0 | grep '^-' | grep -v '^---' | grep -v '^-$'`) is EXCLUSIVELY scaffolding + the 19 table rows:
- `## How to use this file` + its 8 preamble bullets
- `## Active — v11 Scope` + its 5-line blurb
- `## Active — v10 Scope`
- `## Resolved — v8 (March 2026)` + `All BD-001 through BD-019 items resolved across Groups 1–6.`
- `| Item | Description | Commit |` + `|---|---|---|` + the 19 `| BD-00N | … | hash |` rows
- `## Deferred`

**No `**BD-NNN —**` entry body line appears in the removed set.**

**Every ADDED non-blank/non-separator line belongs to a BD-001..019 block** — the categorize-all filter (`grep '^+'` minus the 4 permitted entry-line shapes for BD-001..019) returned EMPTY:
```
(none unexpected — all added lines belong to the 19 new entry blocks)
```

**Spot-prove ≥4 pre-existing entry bodies byte-unchanged (HEAD-span vs worktree-span, awk-extracted):**
```
BD-060: IDENTICAL (11 lines)   ← entry immediately after the removed v11 H2/blurb
BD-059: IDENTICAL (91 lines)   ← entry immediately after the removed v10 H2
BD-024: IDENTICAL (74 lines)   ← entry immediately after the removed v8 table
BD-031: IDENTICAL (14 lines)   ← entry immediately after the removed Deferred H2
```
These four were chosen because each sits adjacent to a scaffolding removal (highest risk of accidental body damage) — all byte-identical.

### V3 — validate-pack.py
```
$ python3 scripts/validate-pack.py ; echo rc=$?   → rc=1
FAIL lines: ONLY → Check 36 (BD-175, M5a):
  "FAIL: Commit fcdcbc4 subject claims `PM-only` but touches non-PM-only paths:
   pack-ops/BACKLOG.md …"
FAILED — 1 issue(s) found
```
**Confirmed: Check 36 is the ONLY failure, and it is INDEPENDENT of my working-tree edit.** Check 36 reads `git log -1 HEAD` (the committed commit `fcdcbc4` = `docs: v11 — BD-208 Resolved (PM-only)`, whose committed diff touched `pack-ops/BACKLOG.md`), NOT the BACKLOG content in the working tree. No check asserts the old H2 structure or the preamble; my pre-normalization introduced **NO new failure**. This is exactly the failure the prompt told me to expect.

### V4 — integration / per-entry tests
```
$ bash scripts/tests/test-per-entry.sh           → rc=0   PASS 58 / FAIL 0   (all 58 pass)
$ bash scripts/tests/test-v11-realistic-ot.sh     → rc=1   PASS 32 / FAIL 1
```
The single OT failure is **C.1 "validate-pack.py exits 0"** (`test-v11-realistic-ot.sh:331` asserts `VALIDATOR_RC == 0`). It fails SOLELY because `validate-pack.py` exits rc=1 on the SAME pre-existing Check 36 condition (commit `fcdcbc4`), which is INDEPENDENT of my edit. All 32 other OT assertions (incl. C.9/C.10 banner/wording asserts) PASS — proving no validator-OUTPUT surface was disturbed by the pre-normalization. See §6 (surfaced out-of-scope issue).

### V5 — manifest regeneration (manifest-regen-on-v11-surface)
```
$ bash test-fixtures/build.sh --all --clean       → rc=0
$ git status --short test-fixtures/manifest.txt    → (empty)   ✔ no manifest diff
$ git status --short | grep -v '^??'               →  M pack-ops/BACKLOG.md   (ONLY)
$ ls -d backlog changelog                          → (none — no tree)   ✔
```
`pack-ops/BACKLOG.md` IS a v11-surface dir, so the manifest was regenerated per the rule; the content edit produces no manifest-path change, so the diff is empty (nothing to stage). Only `pack-ops/BACKLOG.md` is modified — boundary-compliance ABSOLUTE.

---

## 5. DEFINITION-OF-DONE CHECKLIST

| Item | Result |
|---|---|
| B0a — 19 table rows → 19 real `**BD-00N —**` Resolved entries, hash carried verbatim, no history mining | PASS |
| B0b — preamble + 4 grouping H2s + 2 blurbs + table wrapper removed; flat `---`-separated list; v10's 5 entries survive with TRUE statuses | PASS |
| B0c — diff gate: +19 entry blocks + scaffolding removals only; ZERO pre-existing entry body changed | PASS |
| Red line — preserve every entry: AFTER (210) == BEFORE (191) + 19; 210 unique IDs | PASS |
| Monolith→monolith; NO `/backlog/` or `/changelog/` tree | PASS |
| Boundary — only `pack-ops/BACKLOG.md` modified | PASS |
| validate-pack: only pre-existing Check 36 fails (HEAD-commit, not my edit); no new failure | PASS |
| test-per-entry.sh green (58/58) | PASS |
| test-v11-realistic-ot.sh: only failure is C.1 = the pre-existing Check 36 rc; not my edit | PASS (out-of-scope failure surfaced, not worked around) |
| manifest regenerated; no diff; nothing else touched | PASS |
| Edit-in-place (5 targeted Edits, no full rewrite) | PASS |
| agents-never-commit — no git state-changing verb run | PASS |

---

## 6. OUT-OF-SCOPE ISSUES SURFACED (not silently fixed/worked around)

- **Pre-existing Check 36 FAIL on committed HEAD `fcdcbc4`.** The committed commit `docs: v11 — BD-208 Resolved (PM-only)` claims `PM-only` in its subject but its committed diff touches `pack-ops/BACKLOG.md`. This is **pre-existing at HEAD, independent of my working-tree edit** (Check 36 reads `git log -1 HEAD`, not the BACKLOG content). It causes both the `validate-pack.py` rc=1 AND the OT C.1 assertion failure. **Surfaced for Pack Chat triage — NOT fixed here** (out of B0a–B0c scope; the prompt itself flagged this as the expected sole failure; touching it would require editing files outside my single scoped-in file and/or a git operation, both forbidden).

## 7. PLAN DEVIATIONS
**None.** B0a–B0c implemented exactly per `PLAN-BD-203.md` §2 Phase B0 + amendment §C. The one numeric difference (191→210 vs the docs' 190→209) is NOT a deviation — it is the measure-at-conversion-time rule working as designed (the BACKLOG advanced by 1 entry since the docs were measured; the invariant AFTER == BEFORE + 19 holds).

## 8. NEW POQs
**None.**

## 9. FILES CHANGED INVENTORY
| Path | Change type |
|---|---|
| `pack-ops/BACKLOG.md` | modified (pre-normalize: +19 entries, −scaffolding) |
| `maintenance-docs/v11-implementation/IMPL-BD-203-Commit1.md` | modified (this report; overwrote the rejected prior coder's report) |

No tree created. No other file touched. `test-fixtures/manifest.txt` regenerated (no diff → unchanged).

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED) | Conclusion |
|---|---|---|
| **read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION** | Every named doc Read DIRECTLY via the Read tool; per-file proof in the READ-IN-FULL row below (line count + first/last line, from my own Read calls). `CLAUDE.md ## Pack memory` read in full via the provided system context AND the 6 named memory files each Read SEPARATELY + directly (none derived, none "YES (substance)", none "via the cache"). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the one-line PREFLIGHT only AFTER all edits + V1–V5 PASS: `PREFLIGHT: B0a-B0c complete; AFTER==BEFORE+19; diff-gate clean; HEAD fcdcbc4; about to Write IMPL-REPORT…`. No stop/halt message received. | COMPLIANT |
| **agents-never-commit** | No `git add`/`commit`/`rm`/`stash`/`checkout` run. Only read-only `git rev-parse`/`status`/`diff`/`show`. HEAD unchanged: `fcdcbc4` start == end. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | 5 targeted `Edit` calls (insert/delete specific blocks), NOT a `Write` of the whole BACKLOG. Red-line proof: BEFORE 191 → AFTER 210 (= +19, zero losses); diff shows zero deletions of any `**BD-NNN —**` body (§4 V2). | COMPLIANT |
| **regenerate-manifest-on-v11-surface** | `pack-ops/BACKLOG.md` is v11-surface → ran `bash test-fixtures/build.sh --all --clean` (rc=0); `git status --short test-fixtures/manifest.txt` empty → no manifest diff to stage. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Did exactly B0a–B0c on the single scoped file; created no tree; surfaced the pre-existing Check-36 issue (§6) rather than fixing it; report leads with the headline result. No edge-case sprawl. | COMPLIANT |
| **verify-full-ci-suite-not-just-validate-pack** | Ran validate-pack.py (V3) AND the integration tests test-v11-realistic-ot.sh + test-per-entry.sh (V4) + manifest build (V5) — not validate-pack alone; identified the OT C.1 failure as the pre-existing Check-36 rc, not a new break. | COMPLIANT |
| **agent-output-rules-applied-block** | This block; every row QUOTED non-empty evidence; READ-IN-FULL row with per-file direct-read proof below. | COMPLIANT |

### READ-IN-FULL row (per-file DIRECT-READ proof — every named doc + memory file)

| Document | Direct Read (this session)? | Per-file proof (line count + first/last line, from my own Read-tool call) |
|---|---|---|
| `maintenance-docs/v11-implementation/PLAN-BD-203.md` (incl. §2 Phase B0) | YES | 762 lines (read in two pages: 1–518 + 519–762). L1 `# PLAN-BD-203 — Implementation plan: pack self-migration Phase 1 (monolith → per-entry sole-SSOT)` → L762 `**End of PLAN-BD-203.md**`. §2 Phase B0 tasks B0a–B0c at L201–217 read directly. |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-203-V3-AMENDMENT.md` (incl. §C) | YES | 244 lines. L1 `# ARCHITECTURE-BD-203-V3-AMENDMENT — pre-normalize the monolith; convert BD-001..019; flatten the version-grouping scaffolding` → L244 `**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**`. §C canonical-shape fenced block (the `**BD-001 — Rename ios-architect → apple-architect**` exemplar, L46-52) read directly. |
| `pack-ops/BACKLOG.md` (v8 table + 4 H2 sections) | YES | 5107 lines (too large for one Read; read targeted regions directly: L1–40 preamble+v11 H2/blurb; L3435–3494 v10 boundary; L3705–3720 v10→v8 boundary; L3716–3775 v8 table+wrapper+blurb+first full entry; L4915–4934 Deferred boundary). H2 map grepped directly: L9/23/3443/3716/4925. First line `# Backlog`; the 19 rows `| BD-001 | … | 08f7158 |` … `| BD-019 | … | 2fc4a0c |` read directly. |
| `CLAUDE.md` `## Pack memory` (IN FULL) | YES | Read in full via the provided project-instructions system context (the entire `## Pack memory` section: Workflow → Agent invocation rules → Sub-agent behavior → Pack Chat scope → Repo conventions → Project goals). Unique mid-line proof: `**Dependency-direction governs file location; client deliverables default to project-side.**` (Repo conventions). NOTE: this does NOT substitute for the 6 named memory files below — each is a SEPARATE direct Read. |
| `…/memory/feedback_fail_loud_delete_old_source.md` | YES (direct Read tool call) | 54 lines (`wc -l`); Read returned L1 `---` (frontmatter open) → last content line `do not invent scope.` Unique mid-line: `the OLD artifact entirely — NOT a "regenerated mirror," NOT any` (principle 1). |
| `…/memory/feedback_edit_in_place_not_full_rewrite.md` | YES (direct Read tool call) | 14 lines (`wc -l`); L1 `---` → last line `Related: [[feedback_agent_output_rules_applied_block]] (verify artifact, not intent), [[feedback_pack_chat_no_coder_review]] (independent verification).` Unique mid-line: `the v5 pass it silently DROPPED an entire section (§9.8 classification table)`. |
| `…/memory/feedback_verify_full_ci_suite.md` | YES (direct Read tool call) | 42 lines (`wc -l`); L1 `---` → last line `enumerate-encoding-surfaces (CLAUDE.md), [[feedback_manifest_regen_on_v11_surface]].` Unique mid-line: references `scripts/tests/test-v11-realistic-ot.sh:333` hard-asserting the OLD Check-32 banner. |
| `…/memory/feedback_agent_output_rules_applied_block.md` | YES (direct Read tool call) | 14 lines (`wc -l`); L1 `---` → last line `Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]].` Unique mid-line: `Every sub-agent output ends with a **Rules-Applied Verification Block**`. |
| `…/memory/feedback_agents_read_rule_docs_in_full.md` | YES (direct Read tool call) | 117 lines (`wc -l`); L1 `---` → last line (No-cache-substitution clause) `accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases.` Unique mid-line: `Reading \`CLAUDE.md ## Pack memory\` IN FULL does NOT substitute for directly reading each NAMED memory file`. |
| `…/memory/feedback_scope_deliverables_to_the_ask.md` | YES (direct Read tool call) | 34 lines (`wc -l`); L1 `---` → last line `Sharpens feedback_no_solutions_in_agent_prompts and the user's standing preference for terse, exactly-scoped work.` Unique mid-line: `the OT supersession-map prompt *I wrote* returned coverage tables…` (BD-195 Step-1 exemplar). |

**No named document was derived rather than read.** Each of the 6 curated memory files was opened with its OWN Read-tool call this session (not inferred from `CLAUDE.md ## Pack memory`, not "YES (substance)", not "via the cache"). All load-bearing numbers (BEFORE 191, AFTER 210, +19, 0 H2, 0 table rows, the only-Check-36 failure) were independently measured this pass at HEAD `fcdcbc4` via Bash/Read.

**End of IMPL-BD-203-Commit1.md**
