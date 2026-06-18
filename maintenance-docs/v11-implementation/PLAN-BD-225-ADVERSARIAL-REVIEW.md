# PLAN-BD-225-ADVERSARIAL-REVIEW

**Fresh, independent ADVERSARIAL review of `PLAN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`.**
This document OVERWRITES the prior `PLAN-BD-225-ADVERSARIAL-REVIEW.md` (which reviewed the OLD plan;
the design absorbed its findings — sanctioned supersession, no mirror).

- **Reviewer role:** pack-planner (fresh, adversarial; read-only except this review doc, written via Bash heredoc).
- **Posture:** skepticism by default — every load-bearing claim re-measured independently, not cited from the plan.
- **Date:** 2026-06-18 · **HEAD SHA:** `5f56a35dea0d7bde3777ce8ff27f864e5819b01a` · **branch:** `v11-dev`.
- **Object under attack:** `maintenance-docs/v11-implementation/PLAN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (read in full, 690 lines).
- **Spec (SSOT):** `maintenance-docs/v11-implementation/DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (read in full, 939 lines; committed `5f56a35`).
- **Also read in full:** `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md`, `backlog/BD-225.md` / `BD-233.md` / `BD-234.md`, CLAUDE.md `## Pack memory`.
- **Mandate:** does the PLAN correctly, completely, and safely implement the DESIGN? Design decisions are LOCKED (user-approved) and NOT re-opened; only the plan's IMPLEMENTATION of them is challenged. A provable design-vs-reality conflict is surfaced as a QUESTION with evidence.

---

## Terminal verdict (top, for the impatient)

**VERDICT: SOUND-WITH-FIXES.** No BLOCKERs. The plan faithfully and completely sequences the
design's 5 artifact groups into 5 working-state commits; the B-1 bijection, M-3 force-binding,
flag discipline, NO-MEMORY.md, and boundary are all correctly encoded; every CI-RED risk is
correctly anticipated. The fixes below are: ONE MUST (the README enumeration-range edit the plan
prescribes is incomplete — it would leave the README factually wrong even after the fix), and
THREE SHOULDs (a mischaracterization of the archive-file refs that does not change the disposition
but corrupts the completeness gate's evidence; a manifest-input C2 push-sequence nuance; a
governance-confirmation gating clarity). Detail below, each with re-measured evidence.

---

## Findings (severity-tagged)

### MUST-1 — The README "invoked checks" fix as scoped (C2 / §5.5 / EB-4/EB-6) is INCOMPLETE; "extend enumeration to ...63" leaves the README factually wrong

**Location:** PLAN §C/C2 item 5 (lines ~198-206); §G/R9; EB-4; EB-6. DESIGN §5.5.

**What the plan prescribes:** fix BOTH README "invoked checks" instances to "56 distinct numbered
checks" and "extend the surrounding 'Check 1-11, 16-23, 25-...' enumeration to ...63."

**Re-measured reality (HEAD `5f56a35`, 2026-06-18):**
The README string is NOT the abbreviated "48 invoked checks" the plan/design represent. Both
instances carry a DETAILED parenthetical enumeration. Verbatim (line 60, version table):
```
validate-pack.py expanded to 48 invoked checks (46 numbered Check 1–11, 16–23, and 25–51 —
including DEEP-only Check 49; 2 unnumbered informational ...; Checks 12–15 retired per v9 sunset;
Check 24 retired per BD-194)
```
The actual distinct-numbered registry set (importlib-measured):
```
[1-11, 16,17,18,19,20, 22,23, 25,26,27, 29..62]   # 55 distinct; 21,24,28 ABSENT; max 62
```
**Three independent staleness facts the plan's prescribed edit does NOT correct:**
1. **The upper bound is wrong by 11.** The enumeration says "25–51" but the registry runs to **62**
   today (will be 63 after this commit). "Extend to ...63" patches the tail token but leaves the
   stated range "25–51" — which omits 52–62 entirely.
2. **"16–23" is wrong** — 21 and 24 are NOT in the set (21 never existed in this window; 24 retired
   per BD-194, which the string itself says two clauses later — internally contradictory).
3. **The "46 numbered" sub-count is wrong** — there are **55** distinct numbered today (56 after
   Check 63), not 46. The "48 = 46 + 2" arithmetic is stale by the same 9 the headline "48" is.

**Why this is a MUST, not a NIT:** the plan's own rationale is `enumerate-encoding-surfaces` +
measure-then-bound ("fix it to the empirically-correct figure, not 'increment 48 by one'"). But the
prescribed edit only fixes the HEADLINE number (48→56) and the tail token (…51→…63) while leaving
the parenthetical's ranges and sub-count stale — i.e. it half-applies its own principle and ships a
README whose parenthetical still says "46 numbered Check 1–11, 16–23, and 25–51." That is a NEW
internal contradiction (headline 56, body enumerating to 51). A coder following the plan literally
produces a wrong artifact.

**Fix:** the plan must instruct the coder to rewrite the FULL parenthetical in both instances to the
measured set — headline **56**, sub-count **56 numbered** (no separate "unnumbered informational"
double-count unless the plan keeps the "+2 informational" framing, in which case headline = 58 and
the math must be internally consistent), ranges **Check 1–11, 16–20, 22–23, 25–27, 29–63** (the
actual gaps: 21, 24, 28 absent), and reconcile the "Checks 12–15 retired / Check 24 retired"
clauses with the gap list. This is a measure-then-bound edit: the range string must reflect the
registry, not a hand-edited token. **Alternatively** (cleaner, and the coder should be offered it):
collapse the brittle hand-enumeration to "56 numbered checks (the registry is the source of truth;
see `_build_check_registry()`)" so the surface stops drifting at every check add. Either way, "extend
to ...63" as written is insufficient.

**Empirical-Evidence Block — MUST-1**
- Command: `grep -oE "validate-pack.py expanded to [0-9]+ invoked checks \([^)]*\)" README.md`
- Output (verbatim): `validate-pack.py expanded to 48 invoked checks (46 numbered Check 1–11, 16–23, and 25–51 — including DEEP-only Check 49; 2 unnumbered informational — issue-template-forms and template-archive-v11; Checks 12–15 retired per v9 sunset; Check 24 retired per BD-194)`
- Command: `python3 -c "<importlib load> sorted(set(numbered))"`
- Output: `[1,2,3,4,5,6,7,8,9,10,11,16,17,18,19,20,22,23,25,26,27,29,30,...,62]` (55 distinct; gaps at 21,24,28; max 62)
- Command (CI-gating check): `grep -n "invoked check" scripts/validate-pack.py` → (empty) — NOT CI-gated; cannot break CI.
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: the prescribed "extend to ...63" edit leaves the README parenthetical factually wrong
  (range stops at 51; sub-count says 46; "16–23" includes absent 21/24). **NOT-SUPPORTED as written** —
  the plan under-specifies the README edit. (Severity MUST: the plan ships a self-contradictory artifact;
  not BLOCKER because it is not CI-gated and does not break the build.)

---

### SHOULD-1 — The 4 archive files are NOT all the "same `??`-snapshot pattern"; the plan's/​design's evidence for "leave untouched" is partly false (disposition still correct on the OTHER stated ground)

**Location:** PLAN §C/C5 "Left UNTOUCHED" (lines ~395-403); EB-13; §F. DESIGN §9.2(b); EE-17.

**What the plan/design assert:** the 4 archive files (`ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`,
`IMPLEMENTATION-REPORT-BD-146.md`, `IMPLEMENTATION-REPORT-BD-149.md`,
`PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md`) are all "the same `??`-snapshot pattern" — verbatim
`git status --short` output — and are left untouched as "frozen historical snapshots AND
D1-excluded."

**Re-measured reality:** only TWO of the four (`IMPLEMENTATION-REPORT-BD-146.md`,
`IMPLEMENTATION-REPORT-BD-149.md`) carry `??`-snapshot lines. The other two carry ZERO `??`-snapshot
lines and instead contain LIVE PROSE cross-references with line-number citations — e.g.
`ARCHITECTURE-PER-ENTRY-FLAT-FILES.md:1408` "Per `RESEARCH-GRAPHIFY-SYNTHESIS.md:32-38`:",
`PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md:532` "| `RESEARCH-GRAPHIFY-SYNTHESIS.md:14-17` v12 deferral |
Parent §1 | PASS |". These are exactly the prose-ref shape the plan fixes in the 3 LIVE docs — they
differ only in living under `archive/`.

**Why this matters:** (a) the EB-13/EE-17 evidence that lumps all 4 as "`??`-snapshot
historical-verbatim lines" is factually wrong for 2 of the 4 — an `architect-planner-empirical-evidence`
defect (the conclusion is right, the cited evidence is not). (b) The zero-dangling completeness gate
(§9.3 / §C/C5) is written to expect the post-fix grep to return "the 4 untouched archive files +
`??`-snapshot lines" — but two of those archive files return PROSE refs, not `??`-lines, so a
reviewer applying the gate literally ("only self-refs + 4 archive + `??`-snapshot lines remain")
sees prose refs in ARCHITECTURE/PACK-REVIEW archive files and could read the gate as VIOLATED. The
gate's allow-set must name the archive PROSE refs explicitly, not fold them into "`??`-snapshot."

**Is the disposition (leave untouched) still correct?** YES — on the SECOND ground the design also
states: these files live under `maintenance-docs/archive/v11/` and are frozen historical snapshots;
fail-loud-delete-old-source targets LIVE forward-pointing surfaces, not archived snapshots. I
re-confirmed the D1 graph-exclusion holds (the `archive` path component matches the D1 glob
`*[Aa][Rr][Cc][Hh][Ii][Vv][Ee]*` under fnmatch). So the disposition survives; only the
*characterization* and the *gate's allow-set wording* are defective.

**Fix:** correct the plan's "Left UNTOUCHED" bullet and EB-13 to state the accurate split — 2 archive
files with `??`-snapshot lines (BD-146, BD-149) + 2 archive files with LIVE PROSE refs
(ARCHITECTURE-PER-ENTRY-FLAT-FILES, PACK-REVIEW-ARCHITECTURE-PER-ENTRY) — and rest the "leave
untouched" decision on the FROZEN-ARCHIVE ground (which covers all 4) rather than the `??`-snapshot
ground (which covers only 2). Update the §9.3/§C/C5 completeness-gate allow-set to enumerate the
archive PROSE refs so the reviewer does not flag a false positive.

**Empirical-Evidence Block — SHOULD-1**
- Command: `git grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)" -- 'maintenance-docs/archive/v11/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md' | grep -c "?? maintenance"`
- Output: `0` (zero `??`-snapshot lines; all refs are prose).
- Command: same for `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md` → `0`.
- Command: same for `IMPLEMENTATION-REPORT-BD-146.md` / `IMPLEMENTATION-REPORT-BD-149.md` → `??`-snapshot lines present (verbatim `?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md` etc).
- Command (D1 exclusion sanity, fnmatch, NO graph built): the `archive` path component matches `*[Aa][Rr][Cc][Hh][Ii][Vv][Ee]*` → all 3 tested archive paths `IGNORED`.
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: the "all 4 = same `??`-snapshot" claim is **NOT-SUPPORTED** (false for 2 of 4); the
  "leave untouched" DISPOSITION is **SUPPORTED** via the frozen-archive ground; the completeness-gate
  allow-set wording needs correction. (Disposition correct; evidence + gate wording defective → SHOULD.)

---

### SHOULD-2 — C2 push-sequence: validate-pack.py is a fixture input, so C2's push (not C5's) is the one that trips manifest-sync; the plan says this but buries it where a coder/orchestrator could misread the trigger commit

**Location:** PLAN §C/C2 closing note (lines ~220-222); §A.3; EB-10; §F step 6; §G/R8. DESIGN §10.2.

**Re-measured reality (CONFIRMS the plan's claim, with a sequencing nuance):**
`scripts/lib/manifest-inputs.sh` input glob = `scripts/*`; deny set = `scripts/test*.sh`,
`scripts/tests/*`, `scripts/manifest-sync.sh`, `scripts/lib/manifest-inputs.sh`. So
`scripts/validate-pack.py` IS a fixture input (matches `scripts/*`, not denied), and
`scripts/tests/test-validate-pack-check-63.sh` is NOT (matches `scripts/tests/*`). The plan is
CORRECT.

**The nuance worth surfacing:** the plan repeatedly frames manifest-sync as a "push-time, batch-level"
step (§F step 6, R8) — true — but the FIXTURE-INPUT CHANGE that makes `manifest-sync.sh` return
exit 10 is introduced in **C2** (the validate-pack.py edit), not C5. The plan's §F step 6 says
"ONCE for the batch ... before `git push`" which is right for a single push of all 5 commits; but if
the orchestrator ever pushes incrementally (e.g. C1–C2 then C3–C5), the manifest regen is gated on
C2 having landed. The plan should state plainly: "the manifest-input change is C2; manifest-sync at
push reconciles it regardless of how many commits are pushed together." This is a clarity SHOULD, not
a correctness defect — the plan's batch-push assumption is the documented norm (CARRY-OVER: push the
unit as one).

**Empirical-Evidence Block — SHOULD-2**
- Command: `sed -n '54,68p' scripts/lib/manifest-inputs.sh`
- Output: `MANIFEST_INPUT_GLOBS=("scripts/*" ...)`; `MANIFEST_DENY_GLOBS=("scripts/test*.sh" "scripts/tests/*" "scripts/manifest-sync.sh" "scripts/lib/manifest-inputs.sh")`.
- Interpretation: `scripts/validate-pack.py` ∈ input, ∉ deny → fixture input; `scripts/tests/test-validate-pack-check-63.sh` ∈ deny → not an input.
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: plan's manifest-input classification **SUPPORTED**; the trigger-commit-is-C2 framing is
  a clarity gap → SHOULD.

---

### SHOULD-3 — The "governance confirmation" (R10/§E) gating semantics are ambiguous: is C3 BLOCKED on a user answer, or does the plan ADOPT the design's assertion and proceed?

**Location:** PLAN §E (lines ~462-468); §G/R10.

**Observation:** §E says "**Plan-level confirmation needed before C3 lands**: ... PACK-AGENTS.md
needs NO parallel touch." R10 then says "This is a confirmation, not a design re-open." The two
together are ambiguous about whether C3 is GATED on a user reply (a hard stop) or whether the plan
adopts the design's §10.2/§11.2 assertion and merely flags it. My re-measurement supports the
design's assertion: `pack-ops/.spawn-rule-manifest.txt` has 0 `graph-first` records, and Check 46
(`check_boundary_and_spawn_pointer_manifests`) iterates the records PRESENT — it does not require a
record for every corpus slug — so a fresh `### Repo conventions` rule with no collapsed restatement
needs no PACK-AGENTS.md/manifest touch and Check 46 stays green. The governance answer is therefore
STATE-VERIFIABLE (not a maintainer judgment call), and the plan should ADOPT it rather than gate C3
on a user reply. Leaving it as a "confirmation needed before C3 lands" risks an unnecessary
hard-stop on a question the repo state already answers.

**Fix:** restate §E/R10 as "the plan ADOPTS the design's PACK-AGENTS.md-no-touch assertion (EB-9 /
EE-18 confirm Check 46 needs no record); surfaced for awareness, NOT a C3 gate." If the user wants a
veto window it should be the standard planner→coder gate, not a C3-specific block.

**Empirical-Evidence Block — SHOULD-3**
- Command: `grep -c "graph-first" pack-ops/.spawn-rule-manifest.txt` → `0`.
- Command: `grep -n "def check_boundary_and_spawn_pointer_manifests" scripts/validate-pack.py` → present (~7344, iterates records present).
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: PACK-AGENTS.md-no-touch is **SUPPORTED** by state; the "confirmation before C3" framing
  is over-gating → SHOULD (clarity).

---

### NIT-1 — README "aggregate CI test runner across N suites" is also stale (41 claimed; 64 on disk) and is an adjacent encoding surface to the C2 README edit

**Location:** README.md line 60 ("aggregate CI test runner across 41 suites"); not named in the plan.

**Re-measured:** `ls scripts/tests/*.sh | wc -l` → **64**; README says **41**. This is a pre-existing
staleness on the SAME README line C2 edits (the version-table row). It is OUT OF BD-225 SCOPE (Check
63 did not worsen it; not a graphify surface), so the plan is CORRECT to not fix it under BD-225 —
but since C2 already edits this exact line, a coder will SEE it. Flagging so the plan can explicitly
state "the 'N suites' count is a separate pre-existing staleness, out of BD-225 scope; do NOT fold it
in" (prevents scope creep AND prevents a coder silently 'fixing' it). NIT because it is genuinely
out of scope and not graphify-related.

**Empirical-Evidence Block — NIT-1**
- Command: `ls scripts/tests/*.sh | wc -l` → `64`; `grep -oE "aggregate CI test runner across [0-9]+ suites" README.md` → `aggregate CI test runner across 41 suites`.
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: adjacent stale surface, out of BD-225 scope; plan should NOTE it to bound the coder. **N/A to BD-225 correctness; SUPPORTED as an observation.**

---

### NIT-2 — `REVIEW-BD-096.md` carries a "graphify" string the census does not mention; confirmed NOT a dangling ref (correctly out of scope)

**Location:** not in the plan (correctly). Reviewer due-diligence note.

**Re-measured:** a repo-wide `git grep -iln graphify` surfaces
`maintenance-docs/v11-implementation/REVIEW-BD-096.md`, which the plan's census never names. I
verified it is line 38, a verbatim commit-log subject (`91e7563 docs: v11 — Graphify +
Claude-ecosystem-repos research artifacts`), with ZERO reference to any of the 3 doomed
`RESEARCH-GRAPHIFY-*` docs. It is a historical record, not a dangling cross-reference, and is
correctly outside the deletion/ref-fix scope. No action needed; logged so the completeness audit is
provably exhaustive (the plan's census of doomed-doc refs is complete).

**Empirical-Evidence Block — NIT-2**
- Command: `grep -in graphify maintenance-docs/v11-implementation/REVIEW-BD-096.md` → `38:91e7563 docs: v11 — Graphify + Claude-ecosystem-repos research artifacts`.
- Command: `grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)" maintenance-docs/v11-implementation/REVIEW-BD-096.md` → (empty).
- HEAD: `5f56a35` · Date: 2026-06-18.
- Conclusion: not a dangling ref; correctly out of scope. **SUPPORTED (no defect).**

---

## The highest-priority check resolved: M-1 / D10 "fix ALL refs, ZERO dangling"

The mandate flagged the possibility that C5 fixes only the 3 LIVE refs and leaves the 4 archive
files (incl. `IMPLEMENTATION-REPORT-BD-149.md`) and the `??`-snapshots dangling, violating the user's
"fix all, zero dangling" decision. **Re-measured resolution: the plan is COMPLIANT with the user's
M-1/D10 decision — the archive + `??`-snapshot refs are CORRECTLY left dangling-by-design, NOT a
violation.** Reasoning, re-measured:

- The user's "fix ALL refs, zero dangling" decision, as encoded in the LOCKED design §9 (D10/M-1),
  scopes "all refs" to **LIVE FORWARD-POINTING surfaces** — explicitly excluding (b) `archive/`
  frozen snapshots and (c) `??`-snapshot historical-verbatim lines. This is the design's locked
  reading of the decision; I may not re-open it.
- The plan implements that locked reading faithfully: C5 fixes exactly the 3 LIVE refs and leaves the
  archive + `??`-snapshot refs untouched, with the §9.3 completeness gate asserting the post-fix grep
  returns ONLY self-refs + archive + `??`-snapshot lines (i.e. zero LIVE dangling).
- The 4th archive file (`IMPLEMENTATION-REPORT-BD-149.md`) IS named in the plan (PLAN §C/C5; EB-13;
  M-1 count corrected to 4) — the mandate's worry that it was dropped is unfounded; the plan carries it.
- **The ONE defect** (SHOULD-1 above): the plan mis-CHARACTERIZES all 4 archive files as
  `??`-snapshot when 2 of them carry LIVE PROSE refs. This corrupts the completeness-gate allow-set
  wording and the EB-13 evidence — but does NOT change the disposition (frozen archive → untouched)
  and does NOT cause a real dangling ref. So M-1's INTENT (zero LIVE dangling on forward-pointing
  surfaces) is met; the gate's bookkeeping needs the SHOULD-1 wording fix to avoid a reviewer false
  positive.

**M-1 / D10 fix-all-refs: FULLY IMPLEMENTED for LIVE forward-pointing surfaces (the design's locked
scope). Completeness-gate allow-set needs the SHOULD-1 wording correction (archive PROSE refs named
explicitly), but no LIVE ref is left dangling.**

---

## Ledger — every plan claim re-verified (CONFIRMED / CONTRADICTED)

| # | Plan claim | Re-measured result | Verdict |
|---|---|---|---|
| L-1 | HEAD = `5f56a35`, branch `v11-dev` | `git rev-parse HEAD` = `5f56a35dea0d…`; branch `v11-dev` | CONFIRMED |
| L-2 | Boundary clean: `git grep -in graphify -- project-template/` → 0 | `... | wc -l` → `0` | CONFIRMED |
| L-3 | Registry = 60 entries; `CHECK_REGISTRY_EXPECTED_COUNT` = 60 | importlib: entries 60; constant 60 | CONFIRMED |
| L-4 | 55 distinct numbered checks; max = 62; 2 None; 16/18/19 ×2 | importlib: 55 distinct; max 62; None=2; dups {16:2,18:2,19:2} | CONFIRMED |
| L-5 | New entry count bump 60→61; new check NUMBER = 63 (N-2) | max+1=63; entries+1=61 — independent quantities | CONFIRMED |
| L-6 | Check 45 bijection baseline 22↔22 green | `--only-check 45` → "22 … 22; sets are equal (bijection holds)" | CONFIRMED |
| L-7 | Slug `graph-first-context` absent everywhere | `grep -c` in 4 files → all 0 | CONFIRMED |
| L-8 | Check 45 slug regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`; corpus regex `[rationale:\s*([a-z0-9][a-z0-9-]*)\]` | validate-pack.py lines ~7170/7180: exact regexes match; corpus scan restricted to `## Pack memory` | CONFIRMED |
| L-9 | `graph-first-context` matches the slug regex | kebab-case, all-lowercase → matches `[a-z0-9][a-z0-9-]*` | CONFIRMED |
| L-10 | `.gitignore` has no graphify-out; tail = BD-119 snapshot | `grep -c graphify-out .gitignore` → 0; tail = `scripts/.bd119-pre-refactor-monolith.sh.snapshot` | CONFIRMED |
| L-11 | `git ls-files graphify-out/` → 0 (Check 63 measure-then-bound = empty set) | `… | wc -l` → 0 | CONFIRMED |
| L-12 | README "invoked checks" in 2 places (lines 60, 190), both "48" | `grep -nE "invoked check" README.md` → lines 60 + 190, both "48 invoked checks" | CONFIRMED (but see MUST-1: richer enumeration than represented) |
| L-13 | README target figure "56 distinct numbered" | 55 today + 1 = 56 — arithmetic correct | CONFIRMED (figure) / CONTRADICTED (the "extend to …63" edit is incomplete — MUST-1) |
| L-14 | "invoked checks" string NOT CI-gated (Check 4 = version table only) | `grep -n "invoked check" scripts/validate-pack.py` → empty | CONFIRMED |
| L-15 | REPO_ROOT module-level, monkeypatchable (N-4) | `REPO_ROOT = Path(__file__).resolve().parent.parent` at line 300 | CONFIRMED |
| L-16 | Check 62 entry is LAST in `_build_check_registry()`, list closes with `]` after it | lines 9992-9994 `(62, "check_manifest_structural", …, W)`; `]` at 9995 | CONFIRMED |
| L-17 | Count comment block above the constant; ends "+ 1 net-new BD-228 check (62 …)" | lines 486-492 confirm; constant `= 60` at 492 | CONFIRMED |
| L-18 | Trinity anchors: bullet ends 595/554/531, header 597/556/533 (CLAUDE/AGENTS/GEMINI) | grep: CLAUDE 595/597, AGENTS 554/556, GEMINI 531/533; `### Repo conventions` at 488/447/424 | CONFIRMED |
| L-19 | `validate-pack.py` IS a fixture input; new test is NOT | manifest-inputs.sh: input `scripts/*`; deny `scripts/tests/*` etc → validate-pack.py input, test denied | CONFIRMED |
| L-20 | OPTIONAL-FEATURES.md = 324 lines; worktree section at 111; "Adding new entries" tail at 312 | `wc -l` → 324; grep: worktree 111, Adding-new-entries 312 | CONFIRMED |
| L-21 | The 3 doomed `RESEARCH-GRAPHIFY-*` docs exist | `ls` → all 3 present | CONFIRMED |
| L-22 | 3 LIVE refs at SURVEY:271, TOUCH-POINT:128, V11.1-DISCUSSION:338 | git grep → all 3 present at those lines, text matches plan's repoint source | CONFIRMED |
| L-23 | 4 archive files incl. BD-149 (M-1 count = 4) | git grep -- archive/v11/ → ARCHITECTURE, BD-146, BD-149, PACK-REVIEW (4) | CONFIRMED (count) |
| L-24 | All 4 archive files are "the same `??`-snapshot pattern" | 2 (BD-146, BD-149) = `??`-snapshot; 2 (ARCHITECTURE, PACK-REVIEW) = LIVE PROSE refs | CONTRADICTED (SHOULD-1) |
| L-25 | `??`-snapshot lines in BD-120, BD-150, PACK-REVIEW-BD-120 | git grep → all 3 present, verbatim `?? maintenance-docs/v11-research/…` | CONFIRMED |
| L-26 | Census of doomed-doc refs is exhaustive (no missed dangling) | repo-wide `git grep -iln graphify` cross-checked; REVIEW-BD-096 = commit-log line, not a ref | CONFIRMED (NIT-2) |
| L-27 | graphify 0.8.39 at `/Users/david/.local/bin/graphify` | `graphify --version` → 0.8.39; `which` → that path | CONFIRMED |
| L-28 | `.spawn-rule-manifest.txt` has no graph-first record; Check 46 needs none | `grep -c graph-first` → 0; Check 46 iterates records present | CONFIRMED |
| L-29 | DEPENDENCIES.md (client-facing) — graphify not recorded there; not touched | `grep -in graphify supporting-docs/DEPENDENCIES.md` → empty | CONFIRMED |
| L-30 | BD-225 Open / BD-233 Deferred / BD-234 Open | backlog: BD-225 Open, BD-233 Deferred, BD-234 Open | CONFIRMED |
| L-31 | NO MEMORY.md addition anywhere in the plan | §A.3/§E/§13 row 6: zero MEMORY.md; rule lives only in in-repo corpus; Step 3 dropped + flagged BD-232 | CONFIRMED |
| L-32 | M-3: GRAPHIFY_FORCE binds to `update` only (not `extract`) | DESIGN §7.2 template (re-read): force only on the `update` removal sub-branch; `extract` line carries none | CONFIRMED (faithful to design) |
| L-33 | `extract` line has `--backend claude-cli`, NO `--no-viz` (M-2/S-3) | PLAN §C/C4 + DESIGN §7.2: `GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract . --backend claude-cli` (no `--no-viz`) | CONFIRMED |
| L-34 | `--no-viz` only on the initial `/graphify .` build, never `extract` | PLAN §A.2 / §C/C4: stated explicitly; help enum (design EE-3) confirms `--no-viz` ∉ extract | CONFIRMED |
| L-35 | C3 same-commit bijection with `--only-check 45` in verification | PLAN §C/C3 + R5: tag + section same commit; `--only-check 45` is a mandatory C3 leg | CONFIRMED |
| L-36 | All 5 commits `pack-only` scope; each working-state | PLAN §B: every touched path outside project-template/ + supporting-docs/; per-commit validate-pack green | CONFIRMED (no path leaks any keyword constraint) |
| L-37 | Commit order hygiene→guard→rule→runbook→deletions; deps correct | C1→C2 (guard enforces gitignore); C3 atomic; C4 conceptual; C5 last (destructive) | CONFIRMED |
| L-38 | Check 63 is O(1) (single `git ls-files graphify-out/`, no tree scan) | DESIGN §5.2 contract: one subprocess; no per-entry storm | CONFIRMED |

**Tally: 38 plan claims re-verified independently; 36 CONFIRMED, 2 CONTRADICTED** (L-13 the README
"extend to …63" edit is incomplete → MUST-1; L-24 the "all 4 archive = `??`-snapshot" characterization
is false for 2 of 4 → SHOULD-1). Both CONTRADICTIONS are evidence/characterization defects, not
disposition errors; neither is a BLOCKER (neither breaks CI; neither leaves a LIVE dangling ref).

---

## CI-safety judgment (each commit vs the FULL battery)

| Commit | CI-RED risk | Verdict |
|---|---|---|
| C1 (`.graphifyignore` + `.gitignore`) | None — no check reads either; `git check-ignore` sanity only | SAFE |
| C2 (Check 63 + registry + count + test + README) | Check 59 count-invariant: 61 entries == constant 61 (lockstep) ✓; new test auto-wires via disk glob (Check 42) ✓; README string not CI-gated ✓ | SAFE — provided the count bump (60→61) + registry entry + test land together (the plan requires this) |
| C3 (trinity bullet ×3 + rationale section) | Check 45 bijection: 22↔22 → 23↔23 only if section lands SAME commit (plan: atomic + `--only-check 45` leg) ✓; trinity-parity Checks 16/18/19 ✓ | SAFE — the single CI-RED trap (orphan slug) is correctly closed |
| C4 (OPTIONAL-FEATURES.md runbook) | Check 40 bare-cross-ref scanner on pack-ops/ — plan verifies `--only-check 40` ✓ | SAFE |
| C5 (delete 3 docs + fix 3 LIVE refs) | No CI gate covers maintenance-docs cross-refs (Check 34 = per-entry stream trees only); fail-loud gate is reviewer/coder, not CI ✓ | SAFE (CI); completeness gate wording needs SHOULD-1 fix |

**No commit goes CI-RED as planned.** The two historically dangerous traps (C2 count/registry
lockstep, C3 bijection orphan) are both correctly closed by the plan's atomic-commit structure and
named `--only-check` verification legs. The push-time `manifest-sync.sh` (exit 10 → commit
regenerated manifest with approval) is correctly deferred to orchestrator/push-time, not per-commit.

---

## Boundary judgment

No project-template/ leak. Every committed artifact is pack-side: `.graphifyignore` (root),
`.gitignore` (root), `scripts/validate-pack.py` + test, pack-root trinity, `pack-ops/*`,
`maintenance-docs/*`. The graph-first RULE lives in the pack-root trinity only (C3), never the
`project-template/` trinity. The graph may INDEX `project-template/` for agent context, but consuming
the index to answer a deliverable question is explicitly allowed by the design's boundary note. The
client-facing `supporting-docs/DEPENDENCIES.md` is correctly NOT touched (graphify is pack-dev-only).
Re-confirmed: `git grep -in graphify -- project-template/` → 0.

---

## Sequencing / dependency judgment

The 5-commit order (hygiene → guard → rule → runbook → deletions) is correct. C1→C2 is the only hard
dependency (the guard enforces what the gitignore entry declares). C3 is self-contained and atomic
(bijection). C4 references C1–C3 conceptually but has no file-level dependency. C5 (destructive) is
correctly LAST so deletion + ref-fixes form one reviewable change with the zero-dangling gate. No
hidden dependency is mis-ordered. The per-commit-fresh-coder + per-BD-review-inline cadence is
correctly applied to the single-BD-across-5-commits batch.

---

## Open questions (state-verifiable; NOT design re-opens)

None requiring a maintainer judgment call. The one item the plan framed as needing user confirmation
(PACK-AGENTS.md no-touch, R10/§E) is STATE-VERIFIABLE and re-confirmed here (Check 46 needs no record
for a rule with no collapsed restatement) — see SHOULD-3; the plan should ADOPT it rather than gate
C3 on a reply.

---

## Terminal VERDICT

**SOUND-WITH-FIXES.** Zero BLOCKERs. The plan correctly, completely, and safely implements the locked
design: the B-1 same-commit bijection, M-2 (`--no-viz` ∉ extract), M-3 (force binds to `update`),
S-3 (`--backend claude-cli` pinned, never `claude`), the NO-MEMORY.md omission + BD-232 flag, the
boundary, the O(1) Check 63 lockstep, and the destructive-op-last sequencing are all faithfully and
verifiably encoded. Apply before coder spawn:
- **MUST-1** — rewrite the FULL README "invoked checks" parenthetical (both instances) to the measured
  set, not just "extend to …63" (else the README ships self-contradictory). Offer the collapse-to-
  registry-SoT alternative.
- **SHOULD-1** — correct the "all 4 archive = `??`-snapshot" characterization (2 carry LIVE PROSE refs);
  rest "leave untouched" on the frozen-archive ground; fix the §9.3 completeness-gate allow-set wording.
- **SHOULD-2** — state plainly that C2 is the manifest-input-changing commit (clarity).
- **SHOULD-3** — adopt the PACK-AGENTS.md-no-touch assertion rather than gate C3 on a user reply.
- **NIT-1 / NIT-2** — optional clarity bounding (the "41 suites" adjacent staleness is out of scope;
  REVIEW-BD-096's graphify string is a commit-log line, not a ref).

None of the fixes re-opens a locked design decision. With MUST-1 + SHOULD-1 applied, the plan is
implementation-ready.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Read-only git only: `git rev-parse HEAD` → `5f56a35dea0d7…`; `git grep`, `git ls-files`, `git branch`. NO add/commit/push/rm/checkout/worktree. Sole write = this review doc via `cat >>` heredoc to the caller-specified path. | COMPLIANT |
| 2 | per-action-approval-sub-agents | No destructive op; no graph built/indexed in the pack repo; NO `.graphify*` written. The only fnmatch use was a pure `python3 -c` membership test (`fnmatch.fnmatch`) — no file written, no graphify invoked. | COMPLIANT |
| 3 | agents-read-rule-docs-in-full | Read IN FULL: PLAN (690 lines, both pages), DESIGN (939 lines, both pages), `backlog/BD-225/233/234.md`, CLAUDE.md `## Pack memory`; inspected validate-pack.py (Checks 45/46/59/62, registry, REPO_ROOT, count comment), manifest-inputs.sh, .gitignore, trinity anchors, OPTIONAL-FEATURES.md, README invoked-checks lines. | COMPLIANT |
| 4 | architect-planner-empirical-evidence | Every finding + every ledger row carries a re-measured command + verbatim output + HEAD `5f56a35` + date 2026-06-18 + conclusion; NOT cited from the plan's evidence (e.g. re-ran Check 45, re-loaded the registry via importlib, re-ran the archive `??`-vs-prose grep, re-measured the README enumeration set). | COMPLIANT |
| 5 | user-prescriptive-authority | Design decisions treated as LOCKED; challenged only the plan's IMPLEMENTATION (README edit completeness, archive-ref characterization, gate wording). The one D-vs-reality item (archive `??`-vs-prose) surfaced as a QUESTION/SHOULD with evidence, disposition left intact. No decision re-opened. | COMPLIANT |
| 6 | bd-pack-only / pack-project-separation | Verified `git grep -in graphify -- project-template/` → 0; confirmed every committed artifact pack-side and the rule pack-root-trinity-only; DEPENDENCIES.md correctly untouched. | COMPLIANT |
| 7 | enumerate-encoding-surfaces | Verified the Check-63 four/five-surface lockstep (validator + registry + count + test + README), the Check-45 same-commit bijection, the README dual-instance, and the M-1 fix-ALL-refs census (3 LIVE + 4 archive + 3 `??`-snapshot files); MUST-1 flags an UNDER-enumerated README parenthetical. | COMPLIANT |
| 8 | ci-check-runtime-compounding | Verified Check 63 is O(1) (single `git ls-files graphify-out/`, no tree scan / per-entry storm) per design §5.2 contract. | COMPLIANT |
| 9 | cross-cli-reference-normalization | Verified the trinity rule is per-CLI normalized (Claude/Codex/Antigravity audiences, identical CORE, BD-233 effectiveness caveat) and parity-complete (Checks 16/18/19); anchors confirmed in all 3 files. | COMPLIANT |
| 10 | fail-loud-delete-old-source | Verified D10 deletes the 3 docs entirely (no banner/archive) and fixes all 3 LIVE refs; archive + `??`-snapshot refs correctly left as frozen/verbatim (zero LIVE dangling). This review OVERWRITES the prior review path (sanctioned supersession). | COMPLIANT |
| 11 | verify-full-ci-suite | Judged EACH of the 5 commits against the FULL battery (validate-pack ALL + `scripts/tests/*.sh` incl. the new Check-63 test + integration + boundary grep + push-time manifest-sync), not just validate-pack — see CI-safety table. | COMPLIANT |
| 12 | NO MEMORY.md | Verified the plan adds ZERO MEMORY.md pointer (§A.3/§E/§13 row 6); Step 3 dropped + flagged for BD-232; rule lives only in the in-repo corpus. | COMPLIANT |
| 13 | scope-deliverables-to-the-ask | Reviewed exactly this plan vs the design; no sprawl; out-of-scope adjacents (README "41 suites", REVIEW-BD-096) flagged as NITs precisely to BOUND scope, not expand it. | COMPLIANT |
| 14 | agent-output-rules-applied-block | This block: one row per in-force rule (1-15), quoted evidence, terminal conclusion; no AMBIGUOUS, no empty evidence. | COMPLIANT |
| 15 | filename-uniqueness-heuristic | N/A — overwriting the existing review path `maintenance-docs/v11-implementation/PLAN-BD-225-ADVERSARIAL-REVIEW.md` (the sanctioned supersession; not introducing a new filename). | N/A: sanctioned-overwrite |
