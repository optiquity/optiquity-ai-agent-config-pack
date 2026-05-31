# PACK-REVIEW — BD-196 Commit C6 (Reviewer pass 1 of max-3)

**Target:** C6 working-tree changes (wire Check 46 + B5 boundary-pointer
manifest + spawn-rule reference-resolution + SC7-bounded anti-restate).
**Method:** read-only review against DESIGN
(`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §4.3 / §9.6 / SC7) + PLAN
(`PLAN-DOC-CONCISION-GUARDRAILS.md` C6 + G-A). All checks/tests RUN, not
trusted. No prior `PACK-REVIEW-*.md` consulted.

**VERDICT: CLEAN.** No BLOCKER / MUST. Two SHOULD-class observations
(NIT-level accuracy + comment-completeness); both are non-blocking and the
underlying mechanism is sound. The two load-bearing verdicts requested:

- **SC7 bound — SOUND.** The bounded BODY predicate is the correct
  measure-then-bound mitigation; independently reproduced (0 hits at HEAD;
  catches injected restatement; naive predicate storms 6/6).
- **8-surface manifest scope — CORRECT.** Binding to the 8 surfaces that
  actually resolve at HEAD is the right measure-then-bound call; the
  §6-claimed-but-missing surfaces are accounted for by design (§11.3 / C8),
  with one factual-plan-gap noted below (not a C6 defect).

---

## 1. Verification runs (all PASS)

| Run | Result |
|---|---|
| `python3 scripts/validate-pack.py` | EXIT 0 — `PASSED — all checks clean`; Check 46 OK (8 surfaces / 6 rules / 0 restatements / 45 candidate bodies). |
| `test-validate-pack-check-46.sh` | PASS 3 / FAIL 0 (Group 0 import + T1–T6 + Group 2 HEAD e2e). |
| `test-validate-pack-check-45.sh` (neighbor) | PASS 3 / FAIL 0. |
| `test-validate-pack-checks-32-33-34.sh` (neighbor) | PASS 65 / FAIL 0. |
| `test-validate-pack-check-42.sh` (CI-wiring guard) | PASS 4 / FAIL 0. |
| `test-validate-pack-check-43.sh` (leak-sweep) | PASS 7 / FAIL 0. |
| Check 42 count | 12 test files on disk; 12 workflow invocations; test-46 wired; zero unwired. |
| Diff confinement | Exactly the 4 intended files modified/added (+ IMPL-REPORT deliverable); no stray edits. |
| Filename uniqueness | `.boundary-pointer-manifest.txt` + `test-validate-pack-check-46.sh` both unique repo-wide. |

---

## 2. Item-by-item verification (per the review prompt)

### Item 1 — Check 46 logic (§4.3 + §9.6): CONFIRMED
- (a) Reference-resolution runs over BOTH manifests. Boundary half: each
  `surface:` must EXIST and CONTAIN its `pointer:` substring (Check-34
  pattern). Spawn half: each record's `canonical:` must name `## Pack
  memory`, and each named `references:` surface must EXIST and itself
  reference `## Pack memory`. Both halves verified by reading the code
  (`scripts/validate-pack.py` `check_boundary_and_spawn_pointer_manifests`)
  and by T2/T3/T6 in the test.
- (b) Anti-restate scan runs over the 6 spawn-relevant surfaces
  (`_CHECK_46_ANTI_RESTATE_SURFACES`). Faithful to design §9.6 line 273
  ("NO ... imperative TEXT appears verbatim ... a substring-match ... FAILS
  on a hit"). Full suite + Check 46 PASS at HEAD.

### Item 2 — SC7 PREDICATE (load-bearing): SOUND
Independently reproduced all three sub-claims:
- **(a) 0 hits at HEAD / no false-positive on legitimate references.**
  Re-ran the bounded BODY scan over the 6 surfaces → 0 hits. Confirmed.
- **(b) Catches a real restatement.** Injected a verbatim ≥60-char body
  into a surface → caught (`caught = True`); T4 in the test exercises this
  against `.claude/skills/review/SKILL.md` and FAILs as intended.
- **(c) ≥60-char bound is not a false-negative hole.** Two findings:
  - **No short-body hole at HEAD.** Measured all 45 `## Pack memory`
    bodies — every one is ≥60 chars (none dropped from the scan). So no
    rule's body silently escapes the predicate.
  - **Wholesale re-paste IS caught** (the primary threat — the 6 EE-6
    restatements returning). Verified: pasting a full body verbatim into a
    surface trips the predicate. The only evadable shape is
    paraphrase-the-opening-120-chars + verbatim-copy-a-later-passage — a
    narrow leading-window limitation inherent to a substring scan, and
    OUTSIDE the design's threat model ("imperative TEXT appears verbatim").
    Acceptable bounded tradeoff; see SHOULD-1 (document it).
- **Naive predicate storm independently reproduced 6/6** — exact match to
  the report's §5 list (rule-NAME proxy hits 6 legitimate name-bearing
  references). The decision to reject the naive predicate and wire the
  BODY-bounded one is the correct measure-then-bound move per the
  `feedback-ci-guard-design-measure-then-bound` rule.

**SC7 VERDICT: the predicate is sound, not merely non-storming.**

### Item 3 — B5 manifest scope ("aspirational §6" call): CORRECT
- The coder bound the manifest to the 8 surfaces that actually carry a
  `BOUNDARY-DEFINITION.md` pointer at HEAD. Verified by grep: all 8 carry
  exactly 1 pointer; the §6-claimed-but-missing surfaces (PACK-CHAT.md,
  PACK-AGENTS.md, pack-root trinity, project PM-CHAT.md, the pack-* agents)
  carry **0**.
- **The §6 prose was genuinely aspirational, not freshly stripped.**
  `git log -S "BOUNDARY-DEFINITION" -- pack-ops/PACK-CHAT.md` is EMPTY —
  PACK-CHAT.md never carried the pointer in repo history, despite §6's
  prose calling it "the most consequential pointer." Binding the manifest
  to reality (vs. adding all the missing pointers in C6) is the correct
  measure-then-bound call: naming an aspirational surface would self-
  inflict a working-state FAIL.
- **Discoverability accounting — adequate, with one plan-gap (not a C6
  defect):** The most consequential historical pointers (PACK-CHAT.md;
  project PM-CHAT.md for the V1-regression pattern) are absent from both
  the tree AND the manifest. The DESIGN's v8 §11.3 (lines 337-364) re-
  architected discovery: the routing-pointer hosts are PACK-CHAT.md
  "File access strategy" (4 pointers), BOUNDARY self-homed, and the
  `review` skill — authored in **C8** (PLAN §3 C8 line 109). So PACK-CHAT
  discoverability IS scheduled (C8). **However** §11.3 does NOT re-add a
  project PM-CHAT.md boundary pointer — the project-side PM-CHAT pointer
  the §6 prose called "critical for the V1 regression pattern" is dropped
  by the v8 design and not re-homed anywhere. This is a DESIGN/PLAN
  decision, surfaced here for awareness; it is outside C6's scope and not
  a C6 defect. **No silent drop within C6's scope.**

**MANIFEST-SCOPE VERDICT: the 8-surface binding-to-reality is correct.**

### Item 4 — Test catches failures: CONFIRMED (RUN)
`test-validate-pack-check-46.sh` PASS 3/0. Injected-FAIL cases all genuinely
FAIL Check 46: T2 (missing pointer → "no longer carries its expected"),
T3 (missing surface → "does NOT exist on disk"), T4 (reintroduced restate →
"anti-restate violation"), T6 (lost canonical → "no longer points at the
canonical home"). SC7-no-storm case T5 (name-bearing reference) is exercised
and PASSES (0 failures). The injected-FAIL assertions check both the failure
COUNT and the diagnostic substring — good teeth.

### Item 5 — CI wiring + Check 42: CONFIRMED (RUN)
test-46 wired in `.github/workflows/validate-pack.yml` (one step, `if:
always()`, after Check 45). Check 42 = 12 files on disk / 12 invocations /
zero unwired (test-42 PASS 4/0). The fn + `main()` callsite + per-check test
+ CI wiring all land in this one commit (new-check-wiring discipline met).

### Item 6 — Diff confined; no regression: CONFIRMED (RUN)
`git status --short` = exactly ` M validate-pack.yml`, ` M validate-pack.py`,
`?? .boundary-pointer-manifest.txt`, `?? test-validate-pack-check-46.sh`
(+ `?? IMPLEMENTATION-REPORT-BD-196-C6.md` deliverable). Neighbors 32-33-34
(65/0), 45 (3/0), and Check 43 leak-sweep (7/0) all green. No regression.

### Item 7 — C6-vs-C8 §11.3: CONFIRMED correct
C6 correctly did NOT author the §11.3 routing pointers (left to C8). The
coder followed the spawn prompt's SCOPE CLARIFICATION and surfaced the
plan-internal inconsistency (IMPL-REPORT §8) rather than silently resolving
it — the correct behavior per `feedback-no-resolving-plan-contradictions`.
The PLAN inconsistency is REAL and verified (see Finding SHOULD-2). Not a
C6 defect.

---

## 3. Findings

### SHOULD-1 (NIT, non-blocking) — inaccurate NAME-length claim in source comment + IMPL-REPORT §5
- **Surface:** `scripts/validate-pack.py` `_CHECK_46_ANTI_RESTATE_MIN_LEN`
  comment; mirrored in `IMPLEMENTATION-REPORT-BD-196-C6.md` §5.
- **Evidence (quoted from the source comment):** "60 chars is comfortably
  longer than any rule NAME (the longest, 'Project-side concepts on
  pack-side surfaces — deliverable-only', is 56 chars ...)".
- **Measured reality:** there are **4** rule NAMES ≥60 chars; the longest is
  65 chars (`Regenerate test-fixtures/manifest.txt on every v11-surface
  commit`). The cited name "Project-side concepts ... deliverable-only" is
  **62 chars** (em-dash included), not 56. The comment's claim "longer than
  any rule NAME" is false.
- **Why non-blocking:** the predicate scans the BODY, not the NAME — so a
  NAME being ≥60 chars does NOT cause a false-positive. The justification
  prose is wrong but the MECHANISM is sound (T5 + the live 0-hit scan
  confirm name references don't trip the check). The comment's reasoning
  (bound chosen because it exceeds name lengths) is the inaccurate part.
- **Cited clause:** `feedback-architect-planner-empirical-evidence` /
  `feedback-ci-guard-design-measure-then-bound` (a stated measurement in
  the bound's justification should be accurate). **FIX recommendation:**
  correct the comment + IMPL-REPORT §5 to state the real distinction —
  the bound separates one-line NAME references (which the predicate does
  not scan) from verbatim BODY restatements; drop the false "longer than
  any name" claim or restate it accurately.

### SHOULD-2 (observation, surfaced — not a C6 fix) — PLAN C6/C8 routing-pointer attribution conflict + 7b factual gap
- **Surface:** `PLAN-DOC-CONCISION-GUARDRAILS.md` §3 C6 (lines 93-94) +
  §8 step-map row 4e (line 163) vs §3 C8 (line 109).
- **Evidence:** PLAN C6 line 94 — manifest "includes the §11.3 routing
  pointers (PACK-CHAT 'File access strategy' 4 pointers; ... review skill)";
  PLAN C8 line 109 — "the PACK-CHAT/BOUNDARY routing pointers were already
  folded in C6." The C6 spawn prompt re-scoped these to C8. These conflict
  on WHERE the routing pointers are authored/folded.
- **Additional factual gap:** PLAN line 81 (7b sweep) asserts the §6-claimed
  inbound pointers "(README, PACK-CHAT, PACK-AGENTS, pack-* agents, project
  PM-CHAT) reference the DOC (still valid)." Measured: PACK-CHAT /
  PACK-AGENTS / pack-* agents / project PM-CHAT carry **0**
  `BOUNDARY-DEFINITION` references — they do NOT reference the doc at all.
  The 7b sweep's premise is factually wrong for those surfaces.
- **Disposition:** the coder correctly followed the spawn prompt (C8 owns
  the pointers) and SURFACED the conflict per
  `feedback-no-resolving-plan-contradictions`. This is a PLAN defect to
  reconcile before C8, NOT a C6 defect. **Recommendation:** Pack Chat route
  the PLAN reconciliation to the planner so C8's prompt makes the
  manifest-fold explicitly C8's and corrects the 7b "references the DOC
  (still valid)" premise for the 0-pointer surfaces.

---

## 4. Items explicitly NOT findings (sound by verification)
- One-combined-function (G-A): minimizes surface, shares parse + resolution
  helpers — coder's call, plan-sanctioned. Sound.
- Lenient mode (both manifests absent → SKIP): correct init/state handling.
- `_parse_manifest_records` continuation-line handling: correctly joins
  wrapped/repeated keys; the spawn manifest's semicolon-separated multi-ref
  `references:` (record `triage-all-fix-all`) resolves (6/6 rules pass).
- Boundary discipline (P-missed-7): the new manifest is pack-only
  (`pack-ops/`); it NAMES project-side surfaces as reference-resolution
  TARGETS (allowed — same pattern as Check 37/43 walking project-side
  trees) and EDITS none. Compliant.
- Trinity: 0 trinity files edited. N/A.

---

## 5. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews to reviewer | No `PACK-REVIEW-*.md` read; reviewed against DESIGN §4.3/§9.6/SC7 + PLAN C6 + the C6 IMPL-REPORT (verified against files), nothing else. | COMPLIANT |
| CI guard design — measure-then-bound | Independently reproduced: naive NAME predicate storms 6/6 (REJECTED was correct); bounded BODY predicate 0 hits + catches injected restatement (WIRED is correct); manifest sized to the 8 surfaces that actually resolve at HEAD (grep: 8×1 pointer; §6-claimed-missing surfaces 0). Allowlist not widened to admit aspirational surfaces. | COMPLIANT |
| Architect/planner state-claims require Empirical-Evidence | C6 is a coder commit; reviewed the IMPL-REPORT's state-claims against measurement — §4 design-vs-reality claim VERIFIED (git log empty for PACK-CHAT); §5 0-hit + injected-catch claims VERIFIED; §5 "longest name 56 chars" claim FALSIFIED (real = 65; see SHOULD-1). | COMPLIANT (claims independently checked) |
| Never resolve plan contradictions yourself | The C6/C8 routing-pointer conflict + the 7b factual gap are SURFACED (SHOULD-2), routed to planner via Pack Chat; not resolved in this review. | COMPLIANT |
| Agents never commit | Read-only review; ran only `validate-pack.py` + tests + grep + read-only git (`status`/`log`/`show`/`diff`). No state-changing git verb. Sole Write = this report. | COMPLIANT |
| Prison rule | No `maintenance-docs/prison/` file read or cited. `archive/v11/BOUNDARY-DEFINITION-HISTORY.md` (readable history) consulted via `git show` for the §6 entry-point list. | COMPLIANT |
| Trinity rule | C6 edits 0 trinity files. The manifest NAMES project trinity as resolution targets but edits none. | N/A: trinity not triggered |
| Filename uniqueness | `find` confirms `.boundary-pointer-manifest.txt` + `test-validate-pack-check-46.sh` unique repo-wide. | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |

**End of PACK-REVIEW-BD-196-C6.md.**
