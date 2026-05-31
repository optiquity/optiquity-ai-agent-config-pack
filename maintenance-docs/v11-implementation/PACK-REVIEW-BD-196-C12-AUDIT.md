# PACK-REVIEW-BD-196-C12-AUDIT — End-of-batch review + whole-repo completeness audit + mechanical re-prove

**Type:** Read-only end-of-batch audit (pack-reviewer output). C12 of the BD-196 doc-concision-guardrails series.
**Branch:** `v11-dev`. **HEAD:** `39221b7` (C11a — restore fenced format templates + manifest base-case to PACK-MEMORY-RATIONALE.md SSOT).
**Audit date:** 2026-05-31.
**Reference docs:** `PLAN-DOC-CONCISION-GUARDRAILS.md` + `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` + git history + the LIVE tree. NO prior `PACK-REVIEW-BD-196-*.md` report was read (independence; re-derived from the tree).
**Scope:** whole C1–C11a series (cross-commit), NOT C12's near-empty diff.

---

## OVERALL VERDICT: CLEAN — with 2 SHOULD findings + 4 reconciliation doc-count corrections

The series is correct, complete, and re-proven. `validate-pack.py` passes all checks (exit 0); all 13 per-check tests pass; manifest verifies clean; the slug bijection holds both directions with trinity parity; all ENCODING surfaces are lock-step. Two SHOULD findings concern design-intent deviations (not CI failures). The four reconciliation items are doc-count corrections to the PLAN/ARCHITECTURE (no code change).

---

## PART 1 — Cross-commit review (whole series)

Method: `git diff 96b174a..39221b7 --stat`; targeted bijection/parity re-derivation across C1→C2→C11a; anti-restate re-prove.

### 1.1 No silent undo across commits — SUPPORTED
- Slug bijection holds at HEAD in BOTH directions (no orphan corpus slug, no orphan rationale heading):
  ```
  comm -23 <corpus-slugs> <rationale-slugs>  → (empty)
  comm -13 <corpus-slugs> <rationale-slugs>  → (empty)
  ```
  Every `[rationale: slug]` tagged in C1 has its body landed in C2 under the SAME slug; no C1-tag/C2-body slug mismatch survived to HEAD.
- Trinity slug-set parity across CLAUDE/AGENTS/GEMINI is byte-identical:
  ```
  CLAUDE slugs md5: 05ad8fa70c1c472f221506302882dc28
  AGENTS slugs md5: 05ad8fa70c1c472f221506302882dc28
  GEMINI slugs md5: 05ad8fa70c1c472f221506302882dc28
  ```
- Anti-restate (Check 46) reports `0 verbatim imperative-body restatements across 6 spawn-relevant surfaces (45 candidate bodies scanned, >= 60 chars)` — the C5 collapse was NOT silently re-expanded by C8 (which edited PACK-CHAT) or any later commit.
- C8 routing pointers (PACK-CHAT, review skill, BOUNDARY self-home) all resolve under Check 46 (`boundary manifest: 11 surfaces resolve`). A C8 pointer to a section reshaped in C4/C9 would have failed Check 46 — it passes.

### 1.2 FINDING S1 (SHOULD) — two rules retain full Why/How bodies INLINE in the corpus, contradicting M2/C2
**Surface:** `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory` (trinity). **Owning commit:** C2 (the body-split commit).

Two rules carry full multi-paragraph `**Why:**` + `**How to apply:**` bodies INLINE in the corpus AND carry NO `[rationale:]` pointer:
- `Agent prompt enumerates ALL applicable rules inline` (CLAUDE.md ~L268–303, ~36 lines)
- `Pack Chat NO coder review; bounded reviewer/fix cycle` (CLAUDE.md ~L449–515, ~67 lines)

Evidence (each trinity file independently):
```
CLAUDE: 4 inline **Why:**/**How to apply:** matches in ## Pack memory
AGENTS: 4
GEMINI: 4
```
(4 = 2 rules × {Why, How-to-apply}.) Together ~100 corpus lines per trinity file (~300 trinity-wide) of Why/How/worked-example body remain inline.

This is the exact bloat the M2/C2 split exists to remove. ARCHITECTURE §5.1 makes `[rationale:]` OPTIONAL only for a "fully-application-grade, self-contained rule (whose two-clause imperative needs no further explanation)" — a rule carrying a multi-paragraph Why + How-to-apply body is the opposite of self-contained. The C2 IMPL-REPORT (§4) classified both as "untagged" and intentionally left their bodies inline, but that classification conflicts with the design: a rule with a genuine rationale body should EITHER (a) split that body to `PACK-MEMORY-RATIONALE.md` + carry `[rationale: slug]`, OR (b) be reduced to a self-contained two-clause imperative with the body removed. Leaving the full body inline + untagged is neither.

**Impact:** Not a CI failure — pack-root trinity is NOT in Check 44's `_CHECK_44_DURABLE_DOCS` (those are the 7 pack-ops/ docs), so the gate does not scan it. The deviation is from the design's concision INTENT, which the whole series is built to realize. **Fix owner:** C2 surface (a fix-coder would split these two bodies to RATIONALE.md under new slugs + tag, or reduce them to self-contained imperatives — a design-judgment call to route to user/architect before mechanical fix).

### 1.3 FINDING S2 (SHOULD) — BOUNDARY §6 carries stale transitional "added by a later commit" wording
**Surface:** `pack-ops/BOUNDARY-DEFINITION.md` §6 (L131). **Owning commit:** C4 (authored the forward-reference) — should have been swept when C6 landed the manifest+check.

L131 reads: "...the manifest file and its asserting check are added by a later commit in this batch; until then this line is a forward reference resolvable as plain prose." At HEAD the manifest (`pack-ops/.boundary-pointer-manifest.txt`) AND its asserting check (Check 46) both exist and pass — so "added by a later commit ... until then this line is a forward reference" is now stale transitional prose describing a state that no longer exists.

**Impact:** Not a CI failure (the phrase contains no Check-44 forbidden pattern — no date/SHA/`Commit N`/`Override N`/`post-Commit`/`will `). It is stale-by-construction prose in a durable forward-only rule doc — exactly the temporal-claim class the M4 reshape targets, just outside the regex. **Fix owner:** C4/C6 surface (a fix-coder would rewrite L131 to the present-tense form: "The pointer network is CI-asserted via `pack-ops/.boundary-pointer-manifest.txt` (Check 46)."). Note §6 also keeps the line "referenced from every operating-doc entry point in the pack" — the manifest binds 11 measured surfaces, so this is accurate, not the old aspirational claim.

### 1.4 BOUNDARY §6 not deleted but reshaped — NOT a defect
ARCHITECTURE §7 said "Cross-ref network (old §6) → DELETED, replaced by one line." The realized state keeps a `## §6 Pointer network` HEADING whose body is the one-line manifest pointer (+ the stale transitional clause, S2). This matches the design INTENT (one line referencing the manifest); the surviving heading is harmless and the line-135 self-reference ("update the pointer manifest (§6)") stays internally consistent. No finding beyond S2.

---

## PART 2 — Whole-repo completeness audit (evidence-backed)

### (a) M4 durable docs 0-outside-allowlist — SUPPORTED
Independent grep of the 6 forbidden patterns (`20[0-9]{2}-[0-9]{2}-[0-9]{2}` / `\b[0-9a-f]{7,40}\b` / `Commit [0-9]` / `Override [0-9]` / `post-Commit` / `\bwill `) across the 7 `_CHECK_44_DURABLE_DOCS`:
```
BOUNDARY-DEFINITION            : 0
CONCEPTUAL-REVIEW-METHODOLOGY  : 0
DRY-RUN-MIGRATION              : 2   (L156 "It will say a sidecar", L185 "real run will start from")
HELP-FRAGMENT-PACK             : 0
HELP-FRAGMENT-TRACKER          : 0
MERGE-STRATEGY                 : 2   (L214 "will route through pack-script", L216 "not present...will hit")
OPTIONAL-FEATURES              : 2   (L176 "agent will consume", L194 "recommendation system will not nag")
```
Total = 6 hits, ALL `will`-pattern, ALL present in `.concision-allowlist.txt` as KEEP records with operational-behavioral justification (each describes what a shipped pack mechanism DOES, not a roadmap promise). STRIP-class (date/SHA/Commit N/Override N/post-Commit) = 0 across all 7. Check 44 independently reports "0 forbidden patterns outside the allowlist; 6 allowlisted operational occurrences admitted (KEEP set)." My independent grep matches exactly. The allowlist is sized to the KEEP set (measure-then-bound honored — no borderline widening). **SUPPORTED.**

### (b) Every spawn-relevant rule `[roles:]`-tagged + single-sourced — SUPPORTED
- `[roles:]` count: 21 in each of CLAUDE/AGENTS/GEMINI (trinity parity).
- `[rationale:]` count: 18 in each (trinity parity).
- Check 45 bijection: `18 corpus pointers; 18 rationale sections; sets equal (no orphans either direction)`. The 20 `## ` headings in RATIONALE.md reduce to 18 slugs because 2 (`## Rules-Applied Verification` L198, `## Empirical-Evidence Block` L228) are the C11a-restored fenced FORMAT TEMPLATES inside ``` blocks — they contain spaces/caps and do not match Check 45's kebab-slug regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`. Correctly excluded by design.
- Check 46 anti-restate: `0 verbatim imperative-body restatements across 6 spawn-relevant surfaces` — no surviving restatement in PACK-AGENTS / PACK-CHAT / skills.
**SUPPORTED** (with S1 caveat: 2 untagged rules retain inline bodies — that is a concision-intent gap, not a tagging/bijection failure; the bijection is over the PRESENT `[rationale:]` set and is clean).

### (c) Every reference resolves — SUPPORTED
- Check 46 boundary manifest: 11 surfaces resolve their BOUNDARY-DEFINITION pointer (README, 3 CLI boundary-investigation skills, project-template trinity ×3, project-template boundary-investigation skill, PACK-CHAT, review skill, BOUNDARY self-home).
- Check 46 spawn manifest: 6 rules resolve to `## Pack memory` (3 reference PACK-AGENTS, 3 reference PACK-CHAT).
- Check 34 (cross-reference) clean; Check 40 (pack-ops bare-ref) clean (10 docs walked, 0 unqualified); Check 43 (project-side bare-ref) clean.
**SUPPORTED.**

### (d) ENCODING surfaces lock-step (Check 37-extended / 44 / 45 / 46) — SUPPORTED
| Check | Validator fn | Per-check test | CI wiring line | Manifest/allowlist |
|---|---|---|---|---|
| 44 | `check_durable_doc_concision` (L6613) | `test-validate-pack-check-44.sh` | yml L189 | `.concision-allowlist.txt` ✓ |
| 45 | `check_pack_memory_rationale_bijection` (L6096) | `test-validate-pack-check-45.sh` | yml L192 | (reads CLAUDE.md + RATIONALE.md) ✓ |
| 46 | `check_boundary_and_spawn_pointer_manifests` (L6343) | `test-validate-pack-check-46.sh` | yml L195 | `.boundary-pointer-manifest.txt` + `.spawn-rule-manifest.txt` ✓ |
| 37 (ext) | walk set includes `xcode-companion-templates` (L4165) + `vscode-companion-templates` (L4166) | `test-validate-pack-checks-36-37-38.sh` (44 lines added) | yml L162 | n/a |

Check 42 CI-wiring guard: `13 per-check test files on disk; 13 workflow invocations; zero unwired` — count is correct (13/13). All four checks dispatched in `main()` (L6825/6833/6842 + Check 37 in its prior callsite). **SUPPORTED — no asymmetry.**

### (e) No stale content/refs repo-wide — SUPPORTED
- `(new top-level pack-only dir)` wording: 0 live hits.
- `discoverability invariant|cross-reference network|rule×audience index|unified index`: only 2 hits, both INTENTIONAL forward-state references — the `.boundary-pointer-manifest.txt` comment describing what the manifest REPLACED, and the review skill explicitly stating "there is no enumerated rule×audience index." Neither resurfaces stale content.
- `separated-not-combined check|labeled-block check|§4.2 check`: 0 live hits (the dropped §4.2 check is not referenced as if it exists).
- C5/C9 collapsed restatements: Check 46 anti-restate = 0 (none resurface).
- BOUNDARY §5/§6/§7 inbound refs: the only live `§6` cite is BOUNDARY's own internally-consistent self-reference (L131/L135); BACKLOG.md `§6` hits are unrelated doc sections (V3.3-DELTA §6.3, BD-175 §6.2) in a regenerated mirror.
**SUPPORTED** (the S2 transitional wording is a stale-temporal nit, captured separately; it is not a stale REFERENCE — the pointer it carries resolves).

---

## PART 3 — Mechanical re-prove

### 3.1 `python3 scripts/validate-pack.py` — PASS (exit 0)
Final line: `PASSED — all checks clean`. New checks reported clean: Check 45 (18==18 bijection), Check 46 (11 boundary surfaces + 6 spawn rules + 0 restatements), Check 44 (7 docs, 0-outside-allowlist, 6 KEEP). All pre-existing checks (1–43) green.

### 3.2 All 13 per-check test scripts — PASS
```
check-16, 18, 19, 39, 40, 41, 42, 43, 44, 45, 46  → "All tests passed." (exit 0)
checks-32-33-34  → "65/65 PASSED" (exit 0)
checks-36-37-38  → "All tests passed." (exit 0)
```
(The `FAIL: 0` lines are negative-test-case counters internal to each harness, not failures — each script terminates with "All tests passed" and exit 0.)

### 3.3 Final 7b whole-repo dangling-reference sweep — clean
Swept C2 (corpus body relocations), C4 (BOUNDARY §5/§6/§7 relocations), C5 (PACK-AGENTS/PACK-CHAT restatement collapse), C8 (routing pointers), C9 (6-doc reshape + M3). No dangling reference repo-wide on live surfaces. Archive history files exist and are referenced consistently:
- `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md` ← cited from BOUNDARY L5, L112, manifest L8.
- `maintenance-docs/archive/v11/CONCEPTUAL-REVIEW-METHODOLOGY-HISTORY.md` ← cited from CONCEPTUAL-REVIEW L7.

### 3.4 `test-fixtures/manifest.txt` verify — clean
`bash test-fixtures/build.sh --verify` → all 5 fixtures OK (exit 0):
```
v10-realistic-ot OK; v11-realistic-ot OK; v11-flat-file OK; v11-tracker-on OK; existing-project-mid-dev OK
```

---

## RECONCILIATION ITEMS (measured truth + stale-doc location; flagged for fix-coder, NOT edited)

| # | Item | Measured truth at HEAD `39221b7` | Stale-doc location | Disposition |
|---|---|---|---|---|
| R1 | "26 per-rule cache files" premise | Cache dir `~/.claude/.../memory/` has **28** `.md` files = MEMORY.md + **27** per-rule files (was 26 at baseline; grew by 1). **4** carry a `[rationale: slug]` pointer (= expected 4): `feedback_agent_output_rules_applied_block`, `feedback_architect_planner_empirical_evidence`, `feedback_ci_guard_design_measure_then_bound`, `feedback_manifest_regen_on_v11_surface` — all 4 slugs are valid rationale slugs. **14** of the 18 slugs have NO cache file (= expected 14). | PLAN L133 ("26 per-rule cache files"), PLAN L277-equiv, ARCH §9.7 L277 ("26 per-rule cache files"); ARCH EE-6 L248 already says "27 files = MEMORY.md + 26 per-rule" (consistent with baseline-26). | DOC-COUNT correction: 26 → 27 per-rule. Out-of-repo, no pack gate; informational only. |
| R2 | PLAN/ARCH "21" rule-count claim | No literal "21" appears in either doc. Realized corpus: **21** `[roles:]`-tagged + **18** `[rationale:]`-tagged. The 21 = 18 rationale-tagged + 3 self-contained roles-only. Docs use the baseline approximation **"~22 of 45"** (PLAN L54, ARCH EE-6 L236/L253). 21 tagged ≈ "~22 spawn-relevant" — consistent. Corpus still has **45** top-level bullets post-series (bodies moved to RATIONALE; bullets retained). | PLAN L22 ("45 top-level bullets") + L54 ("~22 of 45"); ARCH L236/L253 ("45 rule bullets / ~22 spawn-relevant / all 22"). | NO stale doc — the "~22 of 45" approximation holds against realized 21-tagged. The prompt's "21 = 18+3" relationship is the realized truth; docs never claimed a literal 21. No correction needed (the 45-bullet count is also still accurate). |
| R3 | ARCH EE-6 "3 PACK-CHAT restatements" | Realized `.spawn-rule-manifest.txt`: 6 slugs, exactly **3** reference PACK-AGENTS, **3** reference PACK-CHAT — matches "6 ... (3 each)." | ARCH EE-6 L249 ("6 in PACK-AGENTS/PACK-CHAT (3 each)"). | NO stale doc — count is accurate. |
| R4 | C11a (inserted commit) accounted-for | C11a IS HEAD `39221b7` (last commit). It restored the 2 fenced FORMAT TEMPLATES (`## Rules-Applied Verification` L198, `## Empirical-Evidence Block` L228) + the manifest base-case to RATIONALE.md. Both are inside ``` fences and correctly excluded from Check 45's 18-slug count (20 headings − 2 non-slug = 18). The PLAN §3 commit table stops at C10/C12 (C11 = out-of-repo cache, not a commit); C11a is NOT in the PLAN commit table. | PLAN §3 commit sequence (lists C1–C12; no C11a row); PLAN §5 trigger matrix (no C11a row). | DOC correction: the PLAN commit table predates the C11a insertion (a review-driven fix commit). C11a is a legitimate per-commit-cycle fix; the PLAN is a pre-execution plan and does not retroactively log fix commits. Informational — no functional impact (Check 45 clean with the restored templates). |

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews fed in | Read only PLAN + ARCHITECTURE + git history + live tree; did NOT open any `PACK-REVIEW-BD-196-*.md` (independence preserved; bijection/parity/anti-restate re-derived from the tree). | COMPLIANT |
| Empirical-Evidence for state-claims | Every Part 1/2/3 conclusion backed by a quoted command/output (validate-pack run, per-test runs, independent forbidden-pattern grep, comm bijection, md5 parity, manifest verify) + HEAD `39221b7`. | COMPLIANT |
| Enumerate ENCODING surfaces | Part 2(d) table verifies fn + test + CI line + manifest/allowlist for Checks 37-ext/44/45/46; Check 42 = 13/13; no asymmetry found. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | Read-only verbs only (`git diff/log/show`, `grep`, `wc`, `comm`, `md5`, `python3 validate-pack.py`, per-check test scripts, `build.sh --verify`); no state-changing git; single Write to the designated audit-report path. | COMPLIANT |
| Prison rule | Did not read `maintenance-docs/prison/`; excluded it from every sweep. | COMPLIANT |
| Chunk Writes >300 lines | Report is ~225 lines; single Write. | COMPLIANT |

**End of PACK-REVIEW-BD-196-C12-AUDIT.md.**
