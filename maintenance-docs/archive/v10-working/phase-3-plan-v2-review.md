# Phase 3 Implementation Plan v2 — Review Report

**Reviewer:** pack-reviewer (sub-agent session)
**Date:** 2026-04-22
**Target:** `maintenance-docs/v10-working/phase-3-implementation-plan-v2.md` (2,149 lines)
**Primary source:** `maintenance-docs/V10-DESIGN.md` (APPROVED, 4,090 lines)
**Mode:** READ-ONLY.

---

## 0. Verdict

**NOT APPROVED (minor fixes required).**

The plan is structurally sound, commit-sequence-coherent, and faithful to
V10-DESIGN on the large majority of checks. However, four defects should
be corrected before Phase 4 execution begins:

- **F1 (major)** Renumbering sweep S6 Dimension 2 regex covers only
  partial scope — the sweep will miss stale cross-file references to
  pre-v10 rule numbers 15–23 in apple-architecture-core and 18–32 in
  python-best-practices. (Details §3.)
- **F2 (major)** `V-ADDCAP-03b` (role:python-server — Dimension-3 coverage)
  is absent from every "V-ADDCAP-01..16" enumeration in the plan.
  Gate E2 approves without testing the role dimension. (Details §3.)
- **F3 (minor)** detect.sh function count inconsistency — §6.7 lists
  **eight** function tests under B5, but Gate F entry criterion 4 says
  "all **nine** function tests." (Details §3.)
- **F4 (minor, criterion-specific)** No standalone deferred-items table.
  Part 13 items are covered as inline bullets in §6.9 only; the review
  criterion explicitly flags this. (Details §3.)

None of the four blocks Phase 4; all four are fixable with text-only
edits to the plan. Everything else audited below — commit sequencing,
gate structure, capability-addition integration, worktree procedure,
developer-correction integration (B1–B8), content-source map, risk
table coverage, BD-item coverage — is correct and Phase-4-ready.

---

## 1. Success-criterion sweep (per review prompt)

Each numbered criterion from the review brief is adjudicated. "PASS"
means the plan satisfies the criterion with no remedial work required.
"PASS-with-notes" means satisfied but with a minor observation.
"FAIL" means the criterion is not met and the finding is listed in §3.

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Every Part 8 §8.2 row 1–84 covered | **PASS-with-notes** | Plan §16 table; cross-checked against V10-DESIGN §§8.2.1–8.2.8 (see §2 below). |
| 2a | B1 — Rule 15 mandatory at Gate A | **PASS** | Plan §6.1 C-045-04, §7.1, §10 Gate A criteria all state "mandatory." |
| 2b | B2 — Fixture creation concrete & executable | **PASS** | Plan §5.1 fixture-A script (~90 lines bash, runnable). |
| 2c | B3 — Renumbering sweep rigor | **PARTIAL PASS** | Dimension 1 + Dimension 3 correct; **Dimension 2 regex incomplete** (F1). |
| 2d | B4 — Sentinel cleanup at S0 | **PASS** | Plan §6.4 C-046-15 "B4 — Sentinel cleanup in S0"; §7.2; R14; Gate D criteria 7. |
| 2e | B5 — detect.sh verification cases | **PASS-with-notes** | Plan §6.7 item 3 enumerates inputs + expected outputs for 8 functions; Gate F says "all nine" (F3 inconsistency). |
| 2f | B6 — merge-trinity.py pre-check | **PASS** | Plan §6.4 C-046-14 "B6 — Active-skills-line pre-check (new in v2)"; §7.3; R15. |
| 2g | B7 — Gate F all six sweeps | **PASS** | Plan §6.7 Gate F entry criterion 2 "All six §8.6 sweeps (S1–S6) produce expected results"; §8.1 marks Gate F as **mandatory** for every sweep. |
| 2h | B8 — Migration fixture concrete | **PASS-with-notes** | Plan §5.2 fixture-B script with profile options. `--with-x-files` body "(content elided for brevity)" — see §3 note 5. |
| 3  | Capability-addition sequencing + V-ADDCAP | **PARTIAL PASS** | C-046-ADD-01/02/03 sequenced correctly; Gate E2 exists; **V-ADDCAP-03b omitted** (F2). |
| 4  | Git worktree strategy | **PASS** | Plan §4.1 uses `git worktree add ../v10-dev v10-dev`; §6.8 merges from main worktree; worktree retirement documented. |
| 5  | Commit sequencing / no race conditions | **PASS** | Dependency chain audited (see §2.2). Every referenced file exists before use. Trinity TRIOs (C-045-01, C-046-03) atomic. |
| 6  | V10-DESIGN §N.N cross-references valid | **PASS** | Every cited section exists in V10-DESIGN. (See §2.3.) |
| 7  | Deferred items standalone table | **FAIL** | Plan §6.9 covers Part 13 items as inline bullets only (F4). |
| 8  | Approval-gate criteria unambiguous | **PASS** | Gates A/B/C/D/E/E2/F/Ship all have explicit numbered entry criteria in §6 and §10. |
| 9  | Risk table covers V10-DESIGN risks | **PASS** | Plan §13 has 20 risks (R1–R20) including migration, x-, trinity, renumbering, worktree, sentinel, pre-check, PLATFORM-SKILLS parsing, hand-edited Active skills line. |
| 10 | New-file content-source map | **PASS** | Plan §11 has 21-row mapping table; every new file lists Part 8 row, V10-DESIGN source sections, and additional input. |
| 11 | Plan does not contradict V10-DESIGN | **PASS-with-notes** | No contradictions found. One acceptable deviation (row 80 "Combine with rows 43 and 48" directive — plan splits Procedure 6 into C-046-ADD-02 with rationale; V10-DESIGN §12.5 permits both orderings). |

Findings are detailed in §3.

---

## 2. Detailed evidence (what the plan got right)

### 2.1 Part 8 row-by-row coverage audit

Cross-checked plan §16 against V10-DESIGN §8.2:

| §8.2 sub | Rows | V10-DESIGN source | Plan coverage | Verdict |
|---|---|---|---|---|
| 8.2.1 | 1–10 | Part 3 §§3.1–3.10 | C-045-01 (1–3), C-045-02 (4–6), C-045-03 (7–9), design artifact (10) | ✓ |
| 8.2.2 new+remove | 11–23 | Part 4 §§4.1–4.8 | C-046-01 (11–22), C-044-07 (23) | ✓ |
| 8.2.2 sweep | 24–37 | Part 4 §4.8, Part 5 §§5.3/5.10/5.13 | C-046-04 (24+38+81), C-046-06 (25), C-046-03 (26–28), C-046-07 (29), C-046-08 (30+43+48), C-044-05 (31+54+33 cp-r), C-046-10 (32, 34, 35), C-046-09 (36, 37) | ✓ |
| 8.2.3 | 38–43 | Part 5 §§5.2/5.3/5.6/5.7/5.10 | C-046-04 (38), C-046-03 (39–41), C-046-05 (42), C-046-08 (43) | ✓ |
| 8.2.4 | 44–48 | Part 6 §§6.5/6.6/6.8/6.9 | C-046-16 (44), C-046-15 (45), C-046-13 (46), C-046-14 (47), C-046-08 (48) | ✓ |
| 8.2.5 | 49–55 | Part 7 §§7.2/7.6/7.9/7.10/7.11/7.12 | C-044-02 (49), C-044-01 (50, 51), C-044-03 (52), C-044-04 (53), C-044-05 (54), C-044-06 (55) | ✓ |
| 8.2.6 | 56–61 | Part 5 §5.11, Part 7 §7.13 | C-046-02 (56), C-046-11 (57, 58), C-044-08 (59), C-045-02/03 re-verify (60), Gate-E CI confirmation (61) | ✓ |
| 8.2.7 | 62–66 | version bookkeeping | Already APPROVED (62), S-02 (63, 65), S-03 (64), S-01 (66) | ✓ |
| 8.2.8 | 78–84 | Part 5 §§5.7/5.14; AD-14..AD-18 | C-046-ADD-01 (78, 79), C-046-ADD-02 (80), C-046-04 (81, via combined rows 24+38+81), C-046-ADD-03 (82), S-03 (83), V-ADDCAP-01 runtime (84) | ✓ |
| 8.3 runtime | 67–77 | Part 8 §8.3 | Not pack-repo commits; validated by V-INIT-VERIFY-* / V-M1-* / V-PM5-* / V-INC-* / V-X-PRESERVE-* / V-ADDCAP-* | ✓ |

**Every row 1 → 84 has a committed home.** No row forgotten. The §16
"scope completeness check" table is independently verifiable — this
reviewer reproduced it end-to-end.

### 2.2 Commit-dependency chain audit

Each commit's stated dependencies are satisfied by a prior commit in
the same v10-dev branch:

- `C-045-01` → none (first).
- `C-045-02` → C-045-01 (trinity capabilities section is the authority reference).
- `C-045-03` → C-045-02 (skills first express the pattern; auditor bullet points at them).
- `C-045-04` → C-045-03 (auditor bullet is the authority-chain endpoint).
- `C-046-01` → Phase 1 complete.
- `C-046-02` → C-046-01 (target files must exist before the check lands).
- `C-046-03` → Phase 1 + C-046-01.
- `C-046-04` → C-046-01, C-046-03.
- `C-046-05` → C-046-04.
- `C-046-06` → C-046-01.
- `C-046-07` → C-046-01.
- `C-046-08` → C-046-04, C-046-05.
- `C-046-09` → C-046-01.
- `C-046-10` → C-046-01.
- `C-046-11` → C-046-01, C-046-04 (roster exists), C-046-05.
- `C-044-01` → Phase 2b complete.
- `C-046-13` → C-046-05 (PLATFORM-SKILLS Custom sections).
- `C-046-14` → C-046-03 (trinity `### Custom agents` sub-section).
- `C-046-15` → C-044-01, C-046-13, C-046-14.
- `C-046-16` → C-046-15.
- `C-044-02` → C-044-01 + Phase 2a/2b.
- `C-044-03` → C-044-02, C-046-01.
- `C-044-04` → C-044-02, C-044-03.
- `C-044-05` → C-044-03, C-044-04, C-046-16.
- `C-044-06` → C-044-02..05.
- `C-044-07` → C-044-05, C-044-06 (README no longer lists PROMPT-TEMPLATES).
- `C-044-08` → C-044-02..07.
- `C-046-ADD-01` → C-044-01, C-046-15, C-046-08, C-044-02 (§7.6 table landed).
- `C-046-ADD-02` → C-046-ADD-01, C-046-08.
- `C-046-ADD-03` → C-044-06, C-046-ADD-01.
- `S-01..03` → Gate F approval.

No file is referenced before it exists. No check runs against content
that has not yet landed. No race condition detected.

### 2.3 V10-DESIGN §N.N cross-reference audit

Every V10-DESIGN citation in the plan was checked against
`grep -n "^### " V10-DESIGN.md`:

- **Part 3.** §§3.1, 3.2, 3.3, 3.4, 3.5 (language placeholder), 3.6,
  3.7, 3.8, 3.9, 3.10 — all cited sections exist. ✓
- **Part 4.** §§4.1 (token budget), 4.2, 4.3, 4.5, 4.6, 4.7, 4.8 — ✓.
- **Part 5.** §§5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10,
  5.11, 5.12, 5.13, 5.14, 5.14.1, 5.14.2, 5.14.3, 5.14.4, 5.14.5,
  5.14.6, 5.14.7 — all exist. ✓
- **Part 6.** §§6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10,
  6.11 — all exist. ✓
- **Part 7.** §§7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10,
  7.11, 7.12, 7.13 — all exist. ✓
- **Part 8.** §§8.1, 8.2, 8.2.1, 8.2.2, 8.2.3, 8.2.4, 8.2.5, 8.2.6,
  8.2.7, 8.2.8, 8.3, 8.4, 8.5, 8.6 — all exist. ✓
- **Part 10.** §§10.1, 10.2, 10.3, 10.4, 10.5..10.17 — all exist,
  including 10.17 for V-ADDCAP-*. ✓
- **Part 11.** V9 Lessons L4, L5 cited; both exist. ✓
- **Part 12.** §§12.1, 12.2, 12.3, 12.4, 12.5 — all exist. ✓
- **Part 13.** §§13.1, 13.2, 13.3, 13.4, 13.6 — all exist. §13.5
  (catch-all resolution list) not cited by the plan; not required.
- **ADs cited.** AD-5, AD-10, AD-13, AD-14, AD-15, AD-16, AD-17,
  AD-18 — all exist.

Zero stale references.

### 2.4 What the plan got right on each developer correction (B1–B8)

- **B1** — §6.1 C-045-04 spells out Outcome A / Outcome B; §10 Gate A
  entry criterion 4 names the decision file; §7.1 repeats the
  blocker; R11 is the associated risk. Developer cannot bypass.
- **B2** — §5.1 fixture-A script is a runnable 90-line bash block
  with explicit `mkdir`, `cp`, `git init`, `git commit` steps and
  asserted post-conditions (16 agents × 3, 30 skills × 3, 10 prompts
  + PROMPT-AUTHORING, executable agent-run.sh).
- **B3** — §8.2 expands the single-line V10-DESIGN sweep into three
  dimensions with concrete regex per file + full scope
  `project-template/ supporting-docs/ maintenance-docs/`. (Gap in
  Dimension 2 — F1 below.)
- **B4** — §6.4 C-046-15 "B4 — Sentinel cleanup in S0" with resume/
  fresh/abort prompt, default abort, clean-re-run procedure. §14 of
  the migration guide documents the flow. R14 is the associated risk.
- **B5** — §6.7 item 3 enumerates explicit input/expected-output
  pairs for each detect.sh function; comments preserved in the test
  harness for regression reference. (Count inconsistency — F3 below.)
- **B6** — §6.4 C-046-14 "B6 — Active-skills-line pre-check (new in
  v2)" with four numbered steps; stops on missing or duplicate
  pattern; smoke tests for both failure modes. R15 is the associated
  risk.
- **B7** — §6.7 Gate F entry criterion 2 mandates **all six** §8.6
  sweeps with expected-result matching. Intermediate gates run
  targeted sweeps; Gate F is the full-set pass.
- **B8** — §5.2 fixture-B script with profile switches (swift|
  python|monorepo|grpc), `--with-x-files`, `--with-custom-prompt-
  templates`. Used across V-M1-*, V-M1-ROLLBACK, V-M1-CUSTOM-*,
  V-X-PRESERVE-01.

### 2.5 Worktree procedure audit

§4.1 uses `git worktree add ../v10-dev v10-dev` — not a simple
checkout. Rationale explained (two-directory split for safety).
Operational rules clear (commits run from `../v10-dev`; pack-chat
agents read from appropriate working directory; trinity files are
identical via shared git history). Ship merge runs from the main
working directory (§6.8 `cd /Users/david/Developer/dhs-ai-agent-
config-pack`). Worktree retirement documented. R18 covers the
"wrong working dir" risk.

### 2.6 Gate structure audit

Every gate's entry criteria are numbered and objective:

- **Gate A** — 6 numbered criteria including mandatory rule-15
  decision and renumbering-sweep expected counts.
- **Gate B** — 3 criteria including Check 6 active + green.
- **Gate C** — 5 criteria including sweep S1 residuals enumerated.
- **Gate D** — 7 criteria including negative tests for B6 and B4.
- **Gate E** — 7 criteria including all nine validate-pack.py checks
  active and blast-radius sweep clean.
- **Gate E2** — 7 criteria including V-ADDCAP-15 manual test and
  Procedure 6 presence.
- **Gate F** — 6 criteria including **all six** sweeps mandatory
  (per B7) and detect.sh unit tests.
- **Ship** — 4 criteria including developer explicit approval.

No gate criterion is ambiguous or deferred-to-implementer.

---

## 3. Findings (must-fix before Phase 4)

### F1 — Renumbering sweep Dimension 2 regex is incomplete (MAJOR)

**Location.** Plan §8.2 "Dimension 2 — Cross-file specific references
to old rule numbers," apple-architecture-core and python-best-practices
regex blocks (lines ~1833–1848 in the plan).

**What is wrong.** The apple regex is
`apple-architecture-core.*(rule|rules)\s+(1[1-4])\b` — it captures old
rule numbers **11–14 only**. Per V10-DESIGN §3.3 and §8.2 row 4, old
apple rules **11–23** shift to new 15–27. Cross-file references
written against old rule numbers 15–23 (e.g., "see apple-architecture-
core rule 15" referring to old rule 15 content) will **not** be
flagged by this sweep, yet they now silently point at the new rule 15
(a Capabilities section rule, different content).

Same defect in the python regex:
`python-best-practices.*(rule|rules)\s+(1[4-7])\b` captures old 14–17
only. Old rules 18–32 (which shift to new 22–36) are not swept.

**Impact.** Stale cross-file references to pre-v10 numbering in the
mid-to-high rule range will slip past Gate A. This is exactly the
failure mode B3 was designed to prevent.

**Action.** Extend the apple regex to
`apple-architecture-core.*(rule|rules)\s+(1[1-9]|2[0-3])\b` to capture
the full old-rule-number range 11–23. Extend the python regex to
`python-best-practices.*(rule|rules)\s+(1[4-9]|2[0-9]|3[0-2])\b` to
capture 14–32. Update the post-match decision rule to remind the
implementer: a match on any of these numbers must be resolved by
evaluating whether the referent is the pre-v10 content (now at +4 /
new range) or the new Capabilities section rules (11–14 / 14–17).

**Architecture-review** is unaffected (only old 14–15 exist, and the
existing regex `1[4-5]` covers them).

---

### F2 — V-ADDCAP-03b omitted from Gate E2 and Phase 4 test enumeration (MAJOR)

**Location.** Every plan enumeration of capability-addition tests
uses `V-ADDCAP-01..16`. Explicit occurrences (grep-verified):
- §6.6 C-046-ADD-01 verification: "V-ADDCAP-01..08 run."
- §6.6 Gate E2 entry criterion 4: "V-ADDCAP-01..16 all pass on Fixture A".
- §6.7 Phase 4 activity 4: "V-ADDCAP-01..16."
- §10 Gate E2 summary row: "V-ADDCAP-01..16 pass on Fixture A".
- §5.1 Fixture A "Used by tests" list: "V-ADDCAP-01..16".

**What is wrong.** V10-DESIGN §10.17 defines **seventeen** V-ADDCAP
tests: 01, 02, 03, **03b**, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13,
14, 15, 16. V-ADDCAP-03b tests `--add role:python-server` on an Apple-
client monorepo — the **Dimension-3 (role) coverage**. V10-DESIGN
§10.17 "Matrix coverage" paragraph is explicit: "V-ADDCAP-01, 02, 03,
03b cover all four PLATFORM-SKILLS.md dimensions: language
(V-ADDCAP-01), platform (V-ADDCAP-02), protocol (V-ADDCAP-03), role
(V-ADDCAP-03b)."

Interpreting "V-ADDCAP-01..16" as a contiguous range of 16 tests
excludes V-ADDCAP-03b — and with it, the only test that exercises the
role dimension of AD-17. Gate E2 would approve without role-dimension
test coverage.

**Impact.** The capability-addition mechanism ships with an unverified
code path for `role:<value>` arguments. The implementer may carry this
gap forward into runtime usage, where a bug in the role-dimension
branch of `add-capability.sh` A1 / A5 / §7.6 conditional-file table
lookup would surface only at first OT project use.

**Action.** Replace every "V-ADDCAP-01..16" occurrence with
"V-ADDCAP-01..16 plus V-ADDCAP-03b" or, equivalently,
"V-ADDCAP-01/02/03/03b/04..16." At a minimum, update:
- §5.1 fixture-A Used-by-tests list.
- §6.6 C-046-ADD-01 verification block (explicit V-ADDCAP-03b row).
- §6.6 Gate E2 entry criterion 4.
- §6.7 Phase 4 activity 4.
- §10 Gate E2 summary.
- §15 commit list (optional, for completeness).

---

### F3 — detect.sh function count inconsistency (MINOR)

**Location.**
- §6.7 Phase 4 activity 3 ("detect.sh unit tests (B5)") lists
  eight function tests: `detect_clean_working_tree`,
  `detect_git_repo`, `detect_pack_path`, `detect_pack_version`,
  `detect_ai_config`, `detect_x_files`,
  `detect_improperly_added_files`, `detect_installed_capabilities`.
- §6.7 Gate F entry criterion 4: "`detect.sh` unit-test harness
  passes all **nine** function tests."

**What is wrong.** Eight vs. nine mismatch. V10-DESIGN §7.2 also
enumerates eight functions (seven base + `detect_installed_
capabilities` added in Phase 3-AC). There is no ninth function in
the design.

**Impact.** A pedantic reader at Gate F may halt on "where is the
ninth test?" No functional risk, but contradicts plan-as-
ground-truth principle.

**Action.** Change Gate F criterion 4 wording to "all **eight**
function tests" — or, if a ninth function is intended (the plan
does not name one), add its name explicitly to the §6.7 list.

---

### F4 — No standalone deferred-items table (MINOR, criterion-specific)

**Location.** Plan §6.9 Phase 6, step 2 ("Deferred-item follow-
through"). Part-13 items are listed as inline bullets only.

**What is wrong.** Per the review prompt criterion 7, the plan
should have a "standalone deferred-items table (not just inline
bullets)." Current form is five indented bullets.

**Impact.** Stylistic. Implementer can still locate each item; the
plan names §13.1 / §13.2 / §13.3 / §13.4 / §13.6 explicitly.

**Action.** Replace the §6.9 step-2 bullets with a small table:

```
| § | Item | Resolution target | Status at ship |
|---|---|---|---|
| 13.1 | Codex skill loading with x- prefix | Gate F smoke test | Resolved on v10-dev or docs: fix commit |
| 13.2 | Gemini CLI Hooks verification | Future v10.x if needed | Not v10 scope |
| 13.3 | Claude Code .claude/agents/*.md live reload | Gate F smoke test | Resolved on v10-dev or docs: fix commit |
| 13.4 | audit-methodology rule 15 back-reference | Gate A | Resolved via C-045-04 (Outcome A or B) |
| 13.6 | pack-version banner formalization | Future v10.x minor | Not v10 scope |
```

---

## 4. Advisory findings (should fix, not blocking)

### A1 — Deviation from V10-DESIGN §8.2.8 row 80 "Combine with rows 43 and 48" directive

Row 80 (METHODOLOGY.md Procedure 6) is marked "Combine with rows 43
and 48" in V10-DESIGN §8.2.8. C-046-08 lands rows 30+43+48 in one
commit; row 80 is then deferred to C-046-ADD-02 (Phase 3-AC), a
separate commit modifying METHODOLOGY.md a second time.

Plan §12 coordination table acknowledges: "Procedure 6 joins
Procedures 5 and 5-R; row 80 | C-046-ADD-02 (separate from C-046-08
because the script exists only after C-046-ADD-01)." V10-DESIGN §12.5
table also shows Procedure 6 as a separate commit, and §12.5 allows
alternative placements. The deviation is rationalized and acceptable,
but readers unfamiliar with §12.5 may flag it. **Action optional** —
plan could cite V10-DESIGN §12.5 explicitly at C-046-ADD-02's
"v1-to-v2 note" to reinforce that the split is authorized by the
merged design.

### A2 — Fixture B `--with-x-files` body elided

Plan §5.2 line 503: `: # (content elided for brevity; identical to
§5.1 --with-x-files block)`. A Phase-4 implementer must inline the
block from §5.1. Non-self-contained; minor friction risk.

**Action.** Replace the elision with the inlined block copied from
§5.1, or with a `source` of a shared helper.

### A3 — Fixture A `scripts/` scope clarification

Plan §5.1 fixture copies `"$PACK"/project-template/scripts/*` into
the fixture's `scripts/` directory. This is the project-level scripts
(bootstrap, validate, test, etc.) — not the top-level pack scripts
(`init-project.sh`, `migrate-v9-to-v10.sh`, `add-capability.sh`).
The latter are invoked against the fixture by absolute path, never
copied in. The fixture description is accurate but the distinction
between pack-repo `scripts/` and project `scripts/` is implicit.

**Action.** Add a one-line note under §5.1 "Files counted on
creation" clarifying: "Fixture's `scripts/` mirrors the pack
template's project-level scripts; pack-repo `scripts/init-project.sh`,
`migrate-v9-to-v10.sh`, and `add-capability.sh` are invoked against
the fixture by absolute `$PACK` path, never copied in."

### A4 — Fixture B uses `git worktree add ... v9.3` (implicit precondition)

Plan §5.2 runs `git -C "$PACK" worktree add "$TMP" v9.3`. This
requires the `v9.3` tag to exist on the pack repo (which it does).
Not a defect, but the precondition is not stated. If a future fresh
clone has shallow history, the command fails.

**Action.** Add a pre-condition line to §5.2: "Requires `v9.3` tag
present in `$PACK`. Run `git -C "$PACK" fetch --tags` if absent."

### A5 — Plan §2 principle 7 mentions MIGRATION-v8-to-v9.md annotation; C-046-09 does not

Plan §2 principle 7 lists "MIGRATION-v8-to-v9.md" among files that
"receive supersession banners or annotations only." But C-046-09
only annotates V9-DESIGN.md and V9-AUDIT-REPORT.md; MIGRATION-v8-to-
v9.md annotation is deferred into C-046-10 as "optional single-line
pointer to MIGRATION-v9-to-v10.md — acceptable to skip." Net effect
depends on implementer choice; not contradictory, but principle 7
is more assertive than the plan's actual landing commits.

**Action.** Either commit to the annotation in C-046-10 (non-
optional) or soften principle 7 to: "…receive supersession banners
or annotations where applicable (V9-DESIGN.md, V9-AUDIT-REPORT.md
annotated in C-046-09; V10-PREDESIGN.md banner at S-02; MIGRATION-
v8-to-v9.md optional pointer at C-046-10)."

### A6 — "V-ADDCAP-01..16" notation ambiguity (related to F2)

Even with F2 fixed, the compact "01..16" notation obscures the
skip in V-ADDCAP-03b. Future readers may assume a contiguous range.

**Action.** Prefer explicit enumeration in the plan's Gate criteria
and summary tables (e.g., "V-ADDCAP-01/02/03/03b/04/05/…/16").

---

## 5. Consistency spot-checks (passed)

1. **Trinity rule.** BD-045 trinity edit (C-045-01) and BD-046
   trinity layered edit (C-046-03) are each TRIO commits. No trinity
   file is half-edited at any gate. ✓
2. **validate-pack.py sequencing.** Checks 6/7/8/9 land in or after
   the commit that creates their target content (§9 table). No
   check references non-existent files at any intermediate CI run. ✓
3. **`x-` invariant.** Pack ships zero `x-` files; Check 8 enforces
   from C-046-11 onward; fixture-A / fixture-B `--with-x-files`
   seeds are against project directories, not pack template. Plan
   §5.1 "Used by tests" explicitly notes this distinction. ✓
4. **Commit messages.** Every commit's proposed message follows
   CLAUDE.md pack-repo format (`feat: v10 — BD-NNN …` or `docs:
   …` or `fix: …`). ✓
5. **Commit-ID placeholders vs. actual.** V10-DESIGN §12.5 warns
   commit IDs are placeholders and the dependency chain is
   authority. Plan uses the same IDs (C-046-ADD-01/02/03) and keeps
   dependencies consistent. ✓
6. **Migration guide path.** `supporting-docs/MIGRATION-v9-to-
   v10.md` (consistent). ✓
7. **AD-15 sibling placement** of `scripts/add-capability.sh`
   preserved — plan §6.6 C-046-ADD-03 adds the README layout line
   under `scripts/`. ✓
8. **Conditional-file table "single source of truth" principle**
   preserved — §2 principle 8 + C-046-ADD-01 dependency on
   C-044-02 (init-project.sh's §7.6 table is the authority inverted
   by add-capability.sh). ✓

---

## 6. Risk-table coverage confirmation

V10-DESIGN primary risks (migration failure modes, x- preservation,
trinity asymmetry, renumbering orphans, CI check sequencing,
sentinel corruption, pre-check bypass, PLATFORM-SKILLS parse
instability, hand-edited Active skills, worktree confusion) are all
covered in plan §13 R1–R20. No major risk is unmitigated.

Two plan-specific risks added beyond V10-DESIGN content (acceptable
additions):
- R18 — Worktree confusion (new in v2 due to worktree strategy).
- R19 — Phase 3-AC landed before Gate E (new in v2 due to capability
  addition split).
- R20 — `$PACK` points at wrong pack version during Phase 4
  verification.

---

## 7. Summary of required edits

Before Phase 4 begins, make the following edits to
`phase-3-implementation-plan-v2.md`:

1. **F1 — fix renumbering sweep regex** (§8.2 Dimension 2, apple +
   python patterns). Extend regex ranges to cover full old-rule-
   number scopes.
2. **F2 — add V-ADDCAP-03b** to every "V-ADDCAP-01..16" enumeration.
   Six call sites to update (§5.1, §6.6 twice, §6.7, §10, §15).
3. **F3 — reconcile detect.sh function count.** Change Gate F
   criterion 4 from "nine" to "eight," or add a ninth function to
   §6.7 item 3.
4. **F4 — add a standalone deferred-items table** in §6.9 Phase 6
   step 2 (template provided in §3 F4 above).

Strongly recommended (advisory):

5. **A1** — cite V10-DESIGN §12.5 at C-046-ADD-02's v1-to-v2 note.
6. **A2** — inline fixture-B `--with-x-files` block.
7. **A3** — note pack-repo vs. project `scripts/` distinction in §5.1.
8. **A4** — add `v9.3` tag precondition to §5.2.
9. **A5** — reconcile §2 principle 7 with C-046-09/10 actual scope.
10. **A6** — prefer explicit V-ADDCAP enumeration over "01..16" ranges.

After edits, re-run this review on the corrected plan to confirm no
regressions, then approve for Phase 4 execution.

---

## 8. What the plan got right (explicit acknowledgement)

Per the review skill's guidance, a review that only lists problems
is incomplete. The plan v2 is a substantial improvement over v1:

- The capability-addition mechanism (AD-14..AD-18) is cleanly
  integrated without polluting the core BD-044/045/046 sequencing
  — three appended commits, one new gate (E2), precise dependency
  chain.
- Every one of the eight developer corrections B1..B8 is visibly
  integrated in multiple places (principle, commit, gate, risk).
  Not a single B-correction is merely name-dropped.
- The §5 fixture strategy is executable. The two bash scripts are
  concrete enough that a Phase-4 implementer can copy them into
  `maintenance-docs/v10-working/fixtures/` and run them against a
  fresh checkout without inventing structure.
- The §8 sweep schedule fixes the v1 weakness of "grep and see
  what comes back" — expected results are enumerated per sweep per
  gate.
- The §11 new-file content-source map gives every new file an
  authoritative V10-DESIGN section plus (where applicable) a
  line-range pointer into the v9.3 PROMPT-TEMPLATES.md. An
  implementer never has to guess.
- The §13 risk table is concrete and mitigation-bearing — every
  risk names both a detection mechanism and the commit/gate that
  catches it.

The plan is 97% of the way to Phase-4-ready. The four must-fix
findings are textual precision issues, not architectural or
sequencing defects.

---

*End of review report.*
