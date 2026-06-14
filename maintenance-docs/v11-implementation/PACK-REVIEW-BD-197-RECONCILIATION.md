# PACK-REVIEW — BD-197 final design-reconciliation pass (Note-15 pre-Resolved gate)

**Reviewer:** fresh pack-reviewer (independent re-verification; did NOT trust the IMPL-REPORT).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD:** `7da3380fc61e2b8cd094163f5ecb0d75ffe275be` · **Date:** 2026-06-14.
**Scope reviewed:** `pack-only` (maintenance-docs design + plan reconciliation; no code/test/project change).

---

## VERDICT: APPROVE-WITH-FIXES

The four Note-15 deltas (Guard-C 56+57 split, as-built check numbers 52–57, the C7a D-1 project skill-name correction, the C7b NIT-1 won't-fix disposition) plus the dated reconciliation notes are all correctly and faithfully landed in BOTH the design and the plan; full CI is green and scope is clean. The single non-blocking fix is that the IMPL-REPORT's §11 surfacing of the out-of-scope stale-comment finding is INACCURATE (wrong line, wrong count — three comments, not one) — the docs themselves are correct; only the report's description of the deferred item needs correcting, and the cosmetic in-code comment itself should be dispositioned (recommend **defer to BD-219**, which lands next and edits this exact file).

---

## Read attestation

Read directly and in full before reviewing: `backlog/BD-197.md` (Note 15 + Notes 1–14 context); `git diff` of both reconciled docs; `IMPL-REPORT-BD-197-RECONCILIATION.md`; the relevant ranges of `scripts/validate-pack.py` (Check 52–57 headers/docstrings/constants/registrations; the three "54 reserved" comment sites); `backlog/BD-219.md`; `.github/workflows/validate-pack.yml` (CI wiring); `CLAUDE.md` § "## Pack memory" (the 8 rules in force).

---

## Findings by severity

### BLOCKER — none.

### MUST — none.

### SHOULD

**S-1 (report accuracy, not a doc defect) — IMPL-REPORT §11 mis-locates and under-counts the stale in-code comment.**
The IMPL-REPORT §11 says: *"Check 53's docstring/comment at `:8412`-ish notes '54 is reserved' … a stale in-code comment."* Two inaccuracies, independently measured at HEAD `7da3380`:
- **Wrong line.** `validate-pack.py:8412` is inside Check 53's measure-then-bound block (about the STRIP set), and has nothing to do with "54 reserved":
  `8412: #     AGENTS/GEMINI, the commit-discipline skill ×3, pack-ops operating`
- **Wrong count — there are THREE such comments, not one** (`grep -niE '54.{0,30}reserv|reserv.{0,30}54' scripts/validate-pack.py`):
  - `:9549` — in Check 54's OWN registration: *"Check number 54 — reserved for Guard-A′ across the prior BD-197 commits; with this landing, checks 52–57 are contiguous."*
  - `:9572` — in Check 55's registration: *"54 is reserved for the C8b Guard-A′ — a non-contiguous gap is expected and tolerated; numbers ≠ commit order."*
  - `:9587` — in Check 57's registration: *"Check number 57 (next available after 52/53/55/56; 54 is reserved for the C8b Guard-A′ — the gap is expected)."*

This is a SHOULD because the docs being reviewed are correct; the inaccuracy is confined to the IMPL-REPORT's description of a deferred out-of-scope item. It should be corrected so the defer anchor (below) carries the right location/count. No doc edit to the design/plan is required for this.

### NIT — none beyond S-1.

---

## The stale `scripts/validate-pack.py` "54 reserved" comment — assessment + recommendation

**Independently confirmed it exists, and characterized it correctly:**
- The three comments (`:9549/:9572/:9587`) all sit in the `main()` registration block, each explaining why **commit-order ≠ number-order**: Guard-A′ was assigned Check 54 early but lands LAST commit-wise (in C8b), so 55/56/57 register before 54.
- **Purely cosmetic — zero behavioral effect.** Check 54 IS correctly implemented and wired: header `:8569`, full docstring `:8635`, constants `_CHECK_54_REQUIRED_TOKENS` `:8628`, function `check_optional_features_presence` `:8635`, registration `:9552`, CI wiring `.github/workflows/validate-pack.yml:232` (`test-validate-pack-check-54.sh`). `test-validate-pack-check-54.sh` → EXIT 0 this pass. Check 54's own docstring makes NO stale "not yet landed" claim.
- The `:9549` comment is in fact ACCURATE history ("with this landing, checks 52–57 are contiguous"). The `:9572`/`:9587` comments use present-tense "is reserved" for a check that has now landed — mildly stale phrasing, but the surrounding clause ("numbers ≠ commit order / gap is expected") keeps the meaning correct.
- **This is the ONLY remaining as-built code inconsistency** for the BD-197 check numbers. Swept for other stale markers near 52–57 (`reserv`, `TBD`, `to land`, `will land`, `not yet`, `placeholder`, `forthcoming`) → no other stale "reserved"/placeholder comment about the BD-197 check numbers exists.

**RECOMMENDATION: DEFER to BD-219 (do NOT fix now).**
- It is correctly OUT OF SCOPE for this `pack-only` maintenance-docs pass (editing `scripts/` is not a doc-reconciliation delta, and is not in Note 15's list). Fixing it here would be scope creep against this gate.
- **BD-219 is a near-term, well-fit anchor** (independently confirmed `backlog/BD-219.md` exists, Status: Open, Target v11.0): it is sequenced to run **DIRECTLY AFTER BD-197 is Resolved** (user 2026-06-14), and it adds `--only-check` to `scripts/validate-pack.py` — i.e., it WILL touch this exact file imminently. Folding a one-line comment-phrasing cleanup into that touch is the right opportunistic home (matches the `deferred-work-tracked-anchor` rule: a live, scheduled anchor that edits the same file).
- Net: the comment is harmless, the fix is trivial, and the natural touch is the very next BD. Defer is the lower-risk, anchored choice over a fix-now that would expand this gate's `pack-only` doc-scope into `scripts/`.
- **One bookkeeping action recommended**: when BD-219 fires, its scope note (or a tracked TD anchor) should name the **three** sites `:9549/:9572/:9587` (per S-1), not the single mis-located one the IMPL-REPORT cited.

---

## Independent re-verification (command + verbatim output + HEAD + date)

All at HEAD `7da3380fc61e2b8cd094163f5ecb0d75ffe275be`, 2026-06-14.

### 1. As-built ground truth (Note 15(a)/(b))
`grep -oE 'Check [0-9]+' scripts/validate-pack.py | sort -un` → highest = **Check 57** (contiguous 1–57).
Header comments + function names verified verbatim:
```
8232: Check 52: BD-197 pack RW/RO two-class consistency (Guard-B)     def check_pack_rw_ro_two_class            (8315)
8390: Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A)  def check_worktree_isolation_prohibition_flip_block (8494)
8569: Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′)    def check_optional_features_presence      (8635)
8850: Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) def check_project_rw_ro_two_class    (8986)
8694: Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C)  def check_destructive_git_verb_parity (8790)
9096: Check 57: BD-197 PROJECT destructive-git-verb enumeration parity   def check_project_destructive_git_verb_parity (9246)
```
CI wiring (`.github/workflows/validate-pack.yml`): check-52 (`:217`), 53 (`:220`), 56 (`:223`), 55 (`:226`), 57 (`:229`), 54 (`:232`).
**Conclusion: SUPPORTED** — the realized map matches Note 15(b) exactly: Guard-B-pack=52, Guard-A=53, Guard-A′=54, Guard-B-project=55, Guard-C-pack=56, Guard-C-project=57; Guard-C IS two checks (56 pack + 57 project).

### 2. Delta 1 — Guard-C split documented (design §13.3)
`git diff` shows §13.3 retitled `### 13.3 Guard C — verb-enumeration parity — REALIZED AS TWO CHECKS (Check 56 pack + Check 57 project)`, with the design-intent paragraph, the AS-BUILT 56 (28-verb / 10 pack surfaces) + 57 (8-verb intersection / trinity-only catch-all / 52 project surfaces) descriptions, and the explicit measure-then-bound "why two, not one" reason (heterogeneous project surfaces → folding over-complicates → standalone per decision-8 escape hatch; C7b PRESENT → 12 commits). `grep -nE 'Guard C \(optional' …RECONCILED.md` → exit 1 (the old single-guard framing is gone). **SUPPORTED.**

### 3. Delta 2 — as-built check numbers (design §13.1/§13.1a/§13.2/§13.3 + new note)
Each guard heading now carries an "AS-BUILT: realized as Check NN (function), shipped in CN" line, matching the grep map: §13.1→53, §13.1a→54 (+ "lands last, number≠commit order"), §13.2→52 pack + 55 project, §13.3→56+57. The new "## Reconciliation pass" note carries the full map in one table. No stale/placeholder number stated as current (`grep -niE 'reserved.*(check|number)|Check NN'` on the design → only the reconciliation-statement line, which describes the supersession, not a live placeholder). **SUPPORTED.**

### 4. Delta 3 — D-1 project skill name (design §12.2 + plan line 138, P-missed-7)
`ls project-template/skills/implementation/SKILL.md` → exists (3699 bytes). `ls project-template/skills/implementation-report/` → "No such file or directory" (so the old reference WAS wrong). Both docs now reference `project-template/skills/implementation/SKILL.md` for the regime-aware report step, each with an explicit AS-BUILT correction note labelling the old `implementation-report` name non-existent/pack-style.
**Not over-corrected:** legitimate PACK-side `implementation-report` refs are PRESERVED — design `:456` (`.claude/.codex/.gemini/skills/implementation-report/SKILL.md`), plan `:89`, plan `:377`. `grep 'project-template/skills/implementation-report'` on both docs → only inside the explicit correction notes that label it the wrong name; no deliverable ref points to it. **SUPPORTED.**

### 5. Delta 4 — C7b NIT-1 disposition (design §13.3)
§13.3 records the WON'T-FIX / accepted-as-harmless disposition for Check 57's `_check_57_verb_present` ≥4-member slash-run branch: a theoretical false-positive on a benign 4-segment lowercase path can only make a surface look MORE compliant (never spurious-fail); no real surface relies on it (entire slash contribution = the 6 legitimate Codex `Forbidden:` lists); tightening would be gold-plating. **SUPPORTED.**

### 6. No stale references remain
`grep -nE 'project-template/skills/implementation-report'` (both docs) → only in the AS-BUILT correction notes (labelled wrong). `grep -nE 'Guard C \(optional'` (design) → exit 1. No stale single-Guard-C framing, no stale-as-current number, no project-side `implementation-report` deliverable ref. Plan-time contingent Guard-C phrases ("may drop to 11," "Check 56 ext," "C7b may be dropped") are intentionally LEFT as auditable planning history and superseded by a single authoritative AS-BUILT anchor under §J3 — consistent with `edit-in-place-not-full-rewrite`. **SUPPORTED.**

### 7. Stale validate-pack.py comment — see dedicated section above. Confirmed it exists (3 sites), purely cosmetic, Check 54 correctly implemented; no OTHER stale "reserved"/placeholder comment about BD-197 check numbers. Recommendation: **defer to BD-219.**

### 8. Full CI (independent)
- `python3 scripts/validate-pack.py` → **EXIT 0** (`PASSED — all checks clean`).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **EXIT 0** (`PASSED — all checks clean`).
- `test-validate-pack-check-{52,53,54,55,56,57}.sh` → all **EXIT 0**.
- `test-validate-pack-checks-32-33-34.sh` (cross-ref Check 34) → **EXIT 0** (doc edits don't break cross-ref).
- `test-per-entry.sh` → **EXIT 0**.
**Green.**

### 9. Scope
`git status --short`:
```
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
 M maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-RECONCILIATION.md
```
Only the design + plan + IMPL-REPORT (doc-only; no code/test/project change). `git diff --stat test-fixtures/manifest.txt` → empty (manifest unchanged; `maintenance-docs/` is not a v11-surface dir). Edits are targeted in-place; design section map (§0–§18 + the two pass-notes, §13.1/13.1a/13.2/13.3) and plan section map (§A–§K + attestation + Rules-Applied) both intact. **CLEAN.**

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | architect-doc-reality-reconciliation [verify] | Design's new "## Reconciliation pass (2026-06-14, BD-197 Note-15 gate)" note + §13.1/§13.1a/§13.2/§13.3 name the realized consumers (Check 52–57, `check_*` symbols, the project `implementation` skill) and cross-reference `backlog/BD-197.md` Note 15; the design §14 reconciliation section is present; in-code docstrings (Checks 52–57) cross-ref the design; IMPL-REPORT cross-refs both. No line numbers in the new note (verified `sed 35,53 | grep ':[0-9]{2,}'` → none) — files+symbols only. | COMPLIANT |
| 2 | edit-in-place-not-full-rewrite [verify] | `git diff` shows targeted hunks only (design +~38/−3; plan +3/−1). Section maps re-verified post-edit: design `grep '^## '` = §0–§18 + 2 pass-notes (ordered); §13.1–§13.3 sub-headings intact; plan `grep '^## '` = attestation + §A–§K + Rules-Applied. No wholesale rewrite; plan-time contingent phrases retained as history. | COMPLIANT |
| 3 | empirical-evidence-blocks [reviewer] | Every re-verification item (§1–§9) carries the command + verbatim output + HEAD `7da3380` + date 2026-06-14 + SUPPORTED/CLEAN conclusion. | COMPLIANT |
| 4 | enumerate-encoding-surfaces [verify] | BOTH encoding surfaces independently re-checked: DESIGN (§13.1/§13.1a/§13.2/§13.3/§12.2 + new note) AND PLAN (line 138 + §J3 note). Neither leaves a stale single-Guard-C / stale-number / project-`implementation-report` reference (§6). | COMPLIANT |
| 5 | verify-full-ci-suite [universal] | Re-ran validate-pack general + DEEP (both EXIT 0) + the 6 BD-197 guard tests (52–57, all EXIT 0) + cross-ref checks-32-33-34 (EXIT 0) + test-per-entry (EXIT 0). Green. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask [universal] | Reviewed exactly the doc-only reconciliation; assessed the stale-comment finding with an explicit defer-to-BD-219 recommendation; surfaced S-1 (IMPL-REPORT §11 wrong-line/wrong-count) and confirmed no OTHER stale BD-197-check comment. No scope expansion. | COMPLIANT |
| 7 | agents-never-commit [universal] | Only read-only git verbs run: `git rev-parse HEAD` → `7da3380fc61e2b8cd094163f5ecb0d75ffe275be`, `git status --short`, `git diff`, `git diff --stat`. No add/commit/push/stash/reset/restore/checkout/mv/rm/apply. The sole file write is THIS review doc at the prompted path. | COMPLIANT |
| 8 | rules-applied-verification-block [universal] | This block; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

*End of PACK-REVIEW-BD-197-RECONCILIATION.md — VERDICT APPROVE-WITH-FIXES (S-1: correct IMPL-REPORT §11's line/count for the deferred comment; recommend defer the cosmetic validate-pack.py "54 reserved" comment ×3 to BD-219). Docs themselves are correct; full CI green; scope clean; HEAD `7da3380` unchanged.*
