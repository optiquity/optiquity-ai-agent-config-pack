# ADVERSARIAL-REVIEW-PLAN-BD-239 — independent adversarial review of PLAN-BD-239

**Role:** pack-planner (RO), FRESH + INDEPENDENT adversary. I did NOT author
`PLAN-BD-239.md`, `DESIGN-BD-239-RECONCILED.md`, or any prior BD-239 doc. I
re-measured every load-bearing claim FROM SOURCE at the current HEAD; I did NOT
defer to the plan's or design's claims. **Input under review:**
`/tmp/pack-handoff-bd239-plan/PLAN-BD-239.md`. **Output:** this review only (sole
Write, under `/tmp`). **Next stage:** PM-chat triage → reconciliation planner (only
if NEEDS-REWORK) → user planner-to-coder gate → pack-coder.

---

## 0. Runtime regime (RO; verified by me)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `d720873b6010a4059a2ebb919070ef85b7d2d5c6` |
| branch | `v11-dev` |
| `git status --short` | clean (the work I review is plan-stage; RO placement = this main checkout) |
| graph | DISCOVERY queried at the injected path; returned maintenance-doc review nodes only (operating-doc rule bodies not node-indexed at rule granularity) → grep/Read/python3 for VERIFICATION (G2 fallback, sanctioned for exact-bytes/anchor/predicate reads). |
| writes | EXACTLY ONE: this review at `/tmp/pack-handoff-bd239-plan/ADVERSARIAL-REVIEW-PLAN-BD-239.md` (Bash heredoc). No source edits. Read-only git only. No memory store read/written (MEMORY PROHIBITION 2026-06-23 honored). |

The plan measured at HEAD `d720873`; I am at the SAME HEAD `d720873` — no drift to
reconcile. Every plan anchor was re-verified at this exact HEAD.

---

## 1. Verdict

**VERDICT: NEEDS-REWORK (0 blocking; 1 major)**

The plan is faithful to the reconciled design, the manifest STATE-CORRECTION is
independently CONFIRMED correct (and is a real, load-bearing improvement over the
design), the 688-codepoint bullet re-measures EXACTLY, all trinity / PM-CHAT
anchors are byte-parallel ×3 at live HEAD, the scope keywords are correct, and
the vocabulary-purity grep on the shipped text returns ZERO leaks. The single
MAJOR is a wrong/conflated METHODOLOGY text-anchor in §4.1 that would mis-place
the SSOT body if a coder follows it literally — a precision defect in the most
important placement in the plan, and it violates the text-anchor-not-line-number
contract the plan otherwise honors. Fix it and the plan is coder-ready. The
remaining findings are MINOR/NIT polish.

I deliberately set the bar high (this is a LARGE-phase, client-shipping,
launch-window deliverable). I found NO purpose-defeating gap and NO blocker. The
plan is close.

---

## 2. Findings

### MAJOR-1 — The METHODOLOGY Part-5 insertion anchor (§4.1) names a WRONG, conflated text anchor that would mis-place the SSOT body

**Where:** §4.1, the "Anchor (placement)" paragraph:

> "insert after the end of the `### Planner trigger rule` / Workflow 4 fix-cycle
> block, before the `### Audit` / Workflow 5 heading."

**Why this is MAJOR (not MINOR):** the METHODOLOGY subsection is the PRIMARY SSOT
surface (the whole standard's body lives here). The plan's own rules forbid
line-number anchors and require TEXT anchors (§4 header: "exact anchors (text
anchors, not line numbers)"). This anchor names TWO text strings, and BOTH are
wrong/misleading:

1. **`### Planner trigger rule` is NOT the end of Workflow 4.** I measured the
   actual section structure (EB-R1): `### Planner trigger rule` is at **L311**,
   inside Part 3/4 — ~210 lines ABOVE Workflow 4. The actual Workflow-4 block runs
   L523-692 and its LAST sub-block is `#### Planner trigger conditions (mid-phase)`
   (L659-692). A coder grepping for the literal `### Planner trigger rule` lands at
   L311 — the WRONG location, inside an unrelated Part-3/4 heading, ~330 lines
   above the intended insertion point. The plan conflates the Part-3/4
   `### Planner trigger rule` (the up-front trigger) with the Workflow-4
   `#### Planner trigger conditions (mid-phase)` (the mid-cycle trigger) — two
   distinct headings.

2. **`### Audit` is not the Workflow-5 heading either.** The actual heading is
   `### Workflow 5 — Full-codebase audit (auditor agent)` (L693); `### Audit
   subagents (7 clusters)` is a DIFFERENT heading at L1076 in Part 6. A coder
   grepping `### Audit` could match the L1076 Part-6 heading (wrong Part entirely).

**Evidence (EB-R1):** the measured METHODOLOGY heading map. The high-level intent
("a new subsection between Workflow 4 and Workflow 5") IS correct and recoverable
— but the named text anchors are not, and the plan's contract is text-anchor
precision.

**Concrete fix:** replace the anchor sentence with the CORRECT text anchors:

> Insert a NEW `###` subsection between the END of Workflow 4 and the START of
> Workflow 5: AFTER the last line of `#### Planner trigger conditions (mid-phase)`
> (the final sub-block of `### Workflow 4 — Fix cycle (when reviewer finds issues)`)
> and immediately BEFORE the `### Workflow 5 — Full-codebase audit (auditor agent)`
> heading.

Drop the `### Planner trigger rule` and `### Audit` strings entirely from the
anchor (they are the wrong headings). The §4.1 cross-reference to the P5 source
(`### Planner trigger rule` "more than ~5 tasks" at L311/L317) is FINE as a
CONTENT reference — the defect is only its use as the INSERTION anchor.

---

### MINOR-1 — The §9 manifest correction overstates exit-10 as certain; the predicate guarantees a REBUILD, not necessarily a CHANGED manifest

**Where:** §9 + the §11 step 10 + R7: "push-time `manifest-sync.sh` is expected to
report MANIFEST-CHANGED (exit 10) — a REAL SHA change, NOT a NOOP."

**The correction's CORE is RIGHT — I independently confirmed it.** The design's
NOOP basis (`grep -c basename manifest.txt → 0`) IS against the wrong artifact;
`manifest.txt` stores fixture-name→SHA pairs, never source paths (EB-R2). All
seven BD-239 edit paths ARE fixture inputs per `manifest_path_is_input` (EB-R3).
This is a genuine, load-bearing improvement on the design.

**But the exit-10 CLAIM is one inferential step beyond what the predicate
proves.** I read `manifest-sync.sh` (EB-R4): `manifest_path_is_input → true`
guarantees `_regen_manifest` RUNS (`build.sh --all --clean`), but the exit code
then forks THREE ways — `MANIFEST-SKIP` (exit 0, no input changed),
`MANIFEST-NOOP` (exit 0: an input changed but the rebuilt manifest is byte-
identical), and `MANIFEST-CHANGED` (exit 10: the rebuilt manifest differs).
Exit 10 fires ONLY if the edited content actually flows into a BUILT fixture and
changes its SHA. The predicate-is-input fact alone does NOT prove that — it only
proves a rebuild is triggered.

**I closed the gap the plan left open (so this stays MINOR, not MAJOR):** I
verified the edited files actually LAND in the built fixtures (EB-R5):
`v11-flat-file/` contains `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
`docs/pack/METHODOLOGY.md`, `docs/pack/PM-CHAT.md`, AND
`.claude/skills/{architecture-review,planning}/` — all the BD-239 edit targets.
Since the edited content is copied verbatim into the fixtures, the fixture SHAs
WILL change → exit 10 IS the correct expectation. So the plan's CONCLUSION is
right; its REASONING skips the "do the inputs reach a built fixture and change a
SHA" link.

**Concrete fix:** add one clause to §9 grounding exit-10 on the fixture-copy
fact, not the predicate alone — e.g.: "The seven inputs are not merely
predicate-matched; they are copied verbatim into the built fixtures (confirmed:
the v11 fixture trees contain CLAUDE/AGENTS/GEMINI + docs/pack/METHODOLOGY +
docs/pack/PM-CHAT + both skills), so the deterministic fixture SHAs change →
MANIFEST-CHANGED (exit 10), not MANIFEST-NOOP." This converts the plan's
predicate-only inference into a proof. (It also future-proofs the claim: were
some path NOT installed into a fixture, the predicate could be true while the
manifest stayed NOOP.)

---

### MINOR-2 — The manifest commit's scope keyword + which commit carries `test-fixtures/manifest.txt` is unstated

**Where:** §7 (commit-scope keywords) + §11 step 10. The plan correctly leaves the
push-time manifest regen to the orchestrator, but it never states which commit
carries the regenerated `test-fixtures/manifest.txt` nor what scope keyword that
commit may carry.

**Why it matters (and why it's only MINOR):** I confirmed (EB-R6)
`test-fixtures/manifest.txt` is in `_SCOPE_NEUTRAL_GENERATED_PATHS` — Check 36
exempts it from BOTH `project-only` and `pack-only` offender sets. So a manifest-
regen commit can carry either keyword (or none) without a Check-36 trap. The risk
is therefore bounded; but the plan's §7 enumerates only C1/C2 keywords and is
silent on the manifest commit, leaving a small ambiguity for the orchestrator.

**Concrete fix:** add a one-line note to §7 or §11 step 10: "the push-time
manifest-regen commit carries `test-fixtures/manifest.txt`, which is scope-neutral
per Check 36's `_SCOPE_NEUTRAL_GENERATED_PATHS` — it may carry any (or no) scope
keyword without tripping Check 36."

---

### MINOR-3 — PREFLIGHT-7's memory-token grep will false-POSITIVE on legitimate "memory" content the plan itself introduces nowhere — but the existing `Reconciliation` framing nuance deserves an explicit carve

**Where:** §6 PREFLIGHT-7: "grep BD-239's diff for memory-feature tokens
(`memory` / `session memory` / `memory cache` / `~/.claude` / `~/.gemini`) → 0
hits in BD-239's NEW text."

**The concern:** the bare token `memory` is a broad grep. BD-239's NEW shipped
text (the Option-A bullet + the METHODOLOGY chain) carries ZERO memory tokens — I
re-confirmed the bullet is clean (EB-R7). So PREFLIGHT-7 as written PASSES today.
BUT: the plan's §4.1 content spec directs the METHODOLOGY subsection to reference
the existing `Reconciliation-instance independence` trinity rule, and §5.3 / §11-
no-conflict note the "the repo is the authoritative memory, not session history"
framing. If a coder, authoring the METHODOLOGY prose, writes "the repo is the
authoritative memory" (the KEEP framing BD-245 preserves, per BD-245's own KEEP
set), the bare-`memory` grep would FALSE-FAIL PREFLIGHT-7 on legitimate,
sanctioned text.

**Why MINOR:** it's a PREFLIGHT-design sharpness issue, not a content error — and
the plan's §11 no-conflict table explicitly distinguishes the
repo-is-authoritative-memory framing (KEEP) from the CLI-memory-FEATURE
endorsement (forbidden). The grep just needs to encode that distinction so it
doesn't trip on the KEEP phrasing.

**Concrete fix:** tighten PREFLIGHT-7's grep to the FEATURE-endorsement tokens
(`session memory` / `memory cache` / `~/.claude` / `~/.gemini` / "per-project …
memory" / "cross-session memory") and EXCLUDE the bare-`memory` token, OR add an
explicit carve: "the KEEP phrasing 'the repo is the authoritative memory' (per
BD-245's KEEP set) is NOT a feature endorsement and does not count as a hit."
This keeps PREFLIGHT-7 a true gate on the HARD CONSTRAINT without false-failing
sanctioned content.

---

### NIT-1 — §2.1 row 8 (C2 audit-set preservation) double-counts as an "EDITED file"

**Where:** §2.1 "Files EDITED (the edit-set)" table, row 8 lists
`maintenance-docs/v11-implementation/` (the C2 doc MOVE) as a row alongside the
seven C1 edits. The C2 doc-move is a separate commit (correctly C2, `pack-only`)
and is NOT part of the C1 edit-set the PREFLIGHT-6 "only in-scope paths"
diff-check (§6) bounds. Listing it in the same table as the C1 edits could lead a
coder to expect it in the C1 diff. The plan's prose elsewhere (§3.1, §4.5, §11)
correctly separates C1 from C2, so this is cosmetic.

**Concrete fix:** move row 8 to its own "C2 edit-set" mini-table or annotate the
row clearly as "C2 (separate commit) — NOT in the C1 diff that PREFLIGHT-6
bounds."

---

### NIT-2 — The `wc -c` byte-trap caution is excellent; consider mandating the ASCII substitution to retire R1+R2 entirely

**Where:** §4.2 caution 2 + R1/R2. The plan offers the ASCII `->`/`>=`
substitution as OPTIONAL ("a wording call that does not change meaning"). I
confirmed Option A is 688 code points / 708 bytes / 9 arrows + 1 `≥` (EB-R8). The
12-char margin (R1) AND the byte/code-point trap (R2) are BOTH MEDIUM-likelihood
risks the plan flags. The single ASCII substitution removes the byte/code-point
ambiguity entirely (byte-count == code-point-count) AND buys margin headroom
(`->` is 2 bytes vs `→`'s 3; ten multi-byte glyphs → ASCII reclaims 20 bytes,
though code-point length is unchanged). Making the substitution the DEFAULT (not
merely optional) would collapse two MEDIUM risks to LOW at zero meaning cost.

**Concrete fix (optional, planner/coder call):** consider recommending the ASCII-
arrow form as the DEFAULT for the trinity bullet, demoting the Unicode form to
the fallback. This is a judgment call, not a defect — flagged as a NIT.

---

## 3. What I CONFIRMED accurate (independently re-measured — carried unchanged)

These are the plan's load-bearing claims I re-measured FROM SOURCE and found
CORRECT. I am NOT redesigning them; I record the confirmation so the
reconciliation pass knows they are SOUND.

| Plan claim | My independent measurement | Verdict |
|---|---|---|
| All 7 BD-239 edit paths are `manifest_path_is_input` INPUTs (§9, EB-P2) | Sourced `manifest-inputs.sh`, ran the predicate on all 7 → 7×`INPUT` (EB-R3) | CONFIRMED |
| `manifest.txt` stores fixture-name→SHA pairs, not source paths (§9, EB-P1) | `cat test-fixtures/manifest.txt` → header + 6 fixture-name SHA rows; `grep -c supporting-docs` → 0 (EB-R2) | CONFIRMED — the design's NOOP basis IS the wrong artifact |
| Option A = 688 code points ≤ 700 (12 margin), 708 bytes, 9 `→` + 1 `≥` (§4.2, EB-P8) | Replicated the gate's exact `" ".join(x.strip())`+`len()` collapse → 688 cp / 708 bytes / 9 arrows / 1 ≥ (EB-R8) | CONFIRMED EXACTLY |
| Trinity insert anchor = after `**Reconciliation-instance independence.**`, before `## Phase routing` (§4.2, EB-P4) | All 3 files: last `## Project memory` bullet = Reconciliation; next H2 = `## Phase routing — default agent assignments` (EB-R9) | CONFIRMED byte-parallel ×3 |
| PM-CHAT anchors (Merge-back ~L513; roster ~L47/Behavioral ~L172) + memory passages OUTSIDE them (L889/L981) (§4.3, EB-P10) | grep → L47/L172/L513 anchors; L889/L981 memory passages, both outside edit regions (EB-R10) | CONFIRMED |
| The existing `target: docs/pack/METHODOLOGY.md` allowlist record at L390 covers the qualified PM-CHAT cite (§4.3, EB-P5) | L390 record present with the install-doc reason; PM-CHAT already cites the path at L138/150/167/894 (EB-R11) | CONFIRMED — no new allowlist record needed |
| DANGLING bare-word "METHODOLOGY" exempt; only `/`-qualified path matches (PREFLIGHT-4, EB-P12) | Replicated `DANGLING_BACKTICK` regex: bare + non-slash-backtick → no match; `docs/pack/METHODOLOGY.md` → match (EB-R12) | CONFIRMED |
| DEFERRED regex lacks "groupings"; bare mention does NOT trip the axis (§5.2, EB-P12) | Read `DEFERRED_PATTERN` (L202-207): deferral PHRASING only; "groupings" not in the alternation (EB-R13) | CONFIRMED |
| Check 64 = MCP/config `.example`-only; Check 70 = `validate-docs.sh`-structure — neither gates BD-239 (PREFLIGHT-4, M1) | Check 64 failure text "dangling MCP/config .example"; `_CHECK_70_CLIENT_GATE = project-template/scripts/validate-docs.sh` (EB-R14) | CONFIRMED — M1 retarget is right |
| C1 = `project-only`, C2 = `pack-only` correct under Check 36 (§7) | Read Check 36: `project-only` offender = non-project-side; C1's 7 paths all project-side → 0 offenders. `pack-only` offender = project-side; C2's maintenance-docs/ → 0 offenders (EB-R6) | CONFIRMED |
| BD-239↔BD-245 overlap = 3 surfaces (trinity / METHODOLOGY / PM-CHAT); hand-off note enumerates all 3 (§5.4) | Read BD-245 File/Symbol: rename set names trinity ×3 + `supporting-docs/METHODOLOGY.md` + `PM-CHAT.md` + `validate-docs.sh`; the 3 BD-239-edited surfaces match the hand-off note exactly (EB-R15) | CONFIRMED — hand-off enumerates every overlapping surface |
| Project-vocabulary purity: zero pack-concept leak in the shipped Option-A bullet (PREFLIGHT-VOCAB) | grep the verbatim bullet for `BD-?[0-9]`/`backlog-item`/`pack-[a-z]`/`pack memory`/`pack-ops`/`PACK-CHAT`/`PACK-AGENTS`/`[rationale` → NONE (EB-R7) | CONFIRMED — no leak |
| METHODOLOGY structure: Part 5 / Workflow 4 / Workflow 5 exist; P5 source ("more than ~5 tasks") at L317 (§4.1, EB-P7) | grep → Part 5 L446, Workflow 4 L523, Workflow 5 L693, Planner-trigger "more than ~5 tasks" L317 (EB-R1) | CONFIRMED (the P5 CONTENT ref is right; only the INSERTION anchor is wrong — MAJOR-1) |
| No "Workflow 4.5" / "large-phase pipeline" title collision; only existing trinity adversarial mention is the Reconciliation bullet | grep → zero collisions; trinity "adversarial" appears only in the Reconciliation bullet (EB-R16) | CONFIRMED |

---

## 4. Faithfulness to the reconciled design (the adversarial mandate)

The plan IMPLEMENTS the reconciled design — it does not drift or redesign:

- **The 9-stage chain** (§4.1) reproduces design §4.1 stage-for-stage (researcher
  → architect → adversarial architect → reconciliation → design review → planner
  → adversarial planner → reconciliation → coder waves → OPTIONAL audit). FAITHFUL.
- **Size-tiering incl. P5** (§4.1 item 2) reproduces design §4.2's 5 signals +
  the P1-alone-OR-≥2 consequence + when-in-doubt-LARGE + the P5/planner-trigger
  reuse. FAITHFUL.
- **The Option-A pointer bullet** (§4.2) is the design's §7.2 text VERBATIM
  (re-measured 688 cp). FAITHFUL.
- **The 5 roster divergences (D1-D5)** are carried (§1 acceptance table, §4.1
  content). FAITHFUL.
- **The parity-DROP** (§8) carries design §8 (no new guard, DROP not defer).
  FAITHFUL.
- **The 3 wrinkle resolutions** (§5: wrinkle-C=(b) BD-239-first; groupings OMIT;
  zero-CLI-memory) carry the design's §3 verbatim, incl. the verbatim hand-off
  note (§5.4 = design §3.C). FAITHFUL.

**The ONE substantive deviation from the design — the manifest correction (§9) —
is CORRECT and is the plan doing its job** (a planner re-measures and corrects a
design state-error on evidence; reconciliation-instance-independence in action).
I independently confirm the correction (MINOR-1 only sharpens its proof). This is
NOT unauthorized redesign — it is an evidence-grounded state-fact correction, and
the right call.

**Locked-decision compliance (flag only on violation):** I checked the three
locked decisions. (a) Wrinkle C = (b): the plan lands BD-239 first under
`## Project memory`, queue unchanged, with the verbatim 3-surface hand-off note —
COMPLIANT. (b) Zero CLI-memory: the plan's edits are additive pipeline-only;
PREFLIGHT-7 attests the memory passages byte-unchanged — COMPLIANT (MINOR-3
sharpens the grep, does not violate the decision). (c) Parity guard DROPPED,
groupings OMITTED, gate target = validate-docs DANGLING axis — all COMPLIANT
(§8, §5.2, PREFLIGHT-4). NO locked decision is violated.

---

## 5. Empirical-Evidence Blocks

All measured at HEAD `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, branch
`v11-dev`, 2026-06-23, in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EB-R1 — METHODOLOGY heading map (MAJOR-1 + the P5 source).**
- Command: `grep -n "^## Part 5\|^## Part 6\|^### Workflow 4\|^### Workflow 5\|^### Planner trigger rule\|^### Audit\|more than ~5 tasks" supporting-docs/METHODOLOGY.md` ; `awk 'NR>=523&&NR<=693&&/^###/' supporting-docs/METHODOLOGY.md`
- Output (verbatim): `311:### Planner trigger rule`; `317:1. The phase has more than ~5 tasks, or task dependencies …`; `446:## Part 5 — Standard Workflows`; `523:### Workflow 4 — Fix cycle (when reviewer finds issues)`; `693:### Workflow 5 — Full-codebase audit (auditor agent)`; `1047:## Part 6 — Audit Checkpoints`; `1076:### Audit subagents (7 clusters)`. Sub-blocks inside Workflow 4: `571:#### PM chat triage protocol`; `605:#### Architect trigger conditions`; `635:#### What the PM chat does when a trigger fires`; `659:#### Planner trigger conditions (mid-phase)`.
- Interpretation: `### Planner trigger rule` (L311) sits in Part 3/4, ~210 lines ABOVE Workflow 4; it is NOT the end of Workflow 4. Workflow 4's last sub-block is `#### Planner trigger conditions (mid-phase)` (L659-692), ending just before Workflow 5 (L693). `### Audit subagents (7 clusters)` is a DIFFERENT heading (L1076, Part 6). The plan's §4.1 anchor names two wrong/conflated strings.
- Conclusion: NOT-SUPPORTED for the plan's §4.1 INSERTION anchor (MAJOR-1). SUPPORTED for the P5 CONTENT reference (the "more than ~5 tasks" L317 source is real).

**EB-R2 — `manifest.txt` stores fixture-name→SHA pairs, not source paths.**
- Command: `cat test-fixtures/manifest.txt` ; `wc -l test-fixtures/manifest.txt` ; `grep -c supporting-docs test-fixtures/manifest.txt`
- Output (verbatim): header `# Format: <fixture-name>  <sha>` + 6 data rows (`v10-minimal`, `v10-realistic-ot`, `v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`, `existing-project-mid-dev`); `10 test-fixtures/manifest.txt`; `supporting-docs` count = `0`.
- Interpretation: `manifest.txt` indexes built FIXTURE SHAs by fixture-name, never source paths. Grepping it for a source basename returns 0 for EVERY source file. The design's NOOP basis (a basename grep) IS the wrong artifact.
- Conclusion: SUPPORTED — the plan's §9 STATE-CORRECTION is correctly grounded; the design's NOOP claim is wrong.

**EB-R3 — all 7 BD-239 edit paths are `manifest_path_is_input` INPUTs.**
- Command: `source scripts/lib/manifest-inputs.sh; for p in <the 7 paths>; do manifest_path_is_input "$p" && echo INPUT || echo not; done`
- Output (verbatim): `INPUT -> supporting-docs/METHODOLOGY.md`; `INPUT -> project-template/CLAUDE.md`; `INPUT -> project-template/AGENTS.md`; `INPUT -> project-template/GEMINI.md`; `INPUT -> project-template/docs/pack/PM-CHAT.md`; `INPUT -> project-template/skills/architecture-review/SKILL.md`; `INPUT -> project-template/skills/planning/SKILL.md`.
- Interpretation: `MANIFEST_INPUT_GLOBS` has `project-template/*` (recursive-subtree prefix match) + `supporting-docs/METHODOLOGY.md` explicit; no deny glob matches any of the 7. Every path is an input → a rebuild is triggered.
- Conclusion: SUPPORTED — the plan's predicate verdict (7/7 INPUT) is correct.

**EB-R4 — `manifest-sync.sh` exit code forks 3 ways; predicate-true ≠ exit-10 (MINOR-1).**
- Command: `sed -n '95,166p' scripts/manifest-sync.sh` (read `_fixture_inputs_changed` + `_regen_manifest` + `main`).
- Output (verbatim, key): `_regen_manifest` runs `bash "$BUILD_SH" --all --clean`, then `if git diff --quiet -- "test-fixtures/manifest.txt"; then return EXIT_OK # unchanged → NOOP; fi; return EXIT_CHANGED`; `main` cases — `MANIFEST-SKIP` (exit OK, no input changed), `MANIFEST-NOOP` (exit OK, "input changed but … unchanged after rebuild"), `MANIFEST-CHANGED` (exit 10).
- Interpretation: `manifest_path_is_input → true` guarantees `_regen_manifest` RUNS, but exit 10 fires ONLY if the rebuilt `manifest.txt` differs on disk (the edited content reached a built fixture and changed its SHA). The predicate alone does not prove that link.
- Conclusion: SUPPORTED — the plan's exit-10 claim needs the fixture-copy link (EB-R5) to be a proof, not the predicate alone (MINOR-1).

**EB-R5 — the BD-239 edit targets are copied into the built fixtures → exit 10 IS correct (closes MINOR-1).**
- Command: `for p in CLAUDE.md AGENTS.md GEMINI.md docs/pack/METHODOLOGY.md docs/pack/PM-CHAT.md; do test -e "test-fixtures/v11-flat-file/$p" && echo PRESENT; done` ; `ls -d test-fixtures/v11-flat-file/.claude/skills/{architecture-review,planning}` ; `head -1 test-fixtures/v11-flat-file/docs/pack/METHODOLOGY.md` ; `grep -n "docs/pack/METHODOLOGY.md\|TARGET/docs/pack\|stage_s4_skills" scripts/init-project.sh`
- Output (verbatim): all 5 files `PRESENT` in `v11-flat-file/`; both skill dirs present; METHODOLOGY first line `# METHODOLOGY.md — AI-Assisted Project Development Methodology`; init-project S6 copies `supporting-docs/METHODOLOGY.md` → `$TARGET/docs/pack/METHODOLOGY.md` (L680-685) + docs/pack/ content (S6) + trinity (L273/717).
- Interpretation: the edited content flows verbatim into the built fixture trees. Editing any of the 7 paths changes the fixture content → its deterministic git SHA → `manifest.txt` differs after rebuild → exit 10. The plan's CONCLUSION (exit 10, not NOOP) is CORRECT; only its REASONING skips this link.
- Conclusion: SUPPORTED — exit-10 is the right expectation; MINOR-1 is a proof-completeness fix, not a wrong conclusion.

**EB-R6 — Check 36 keyword correctness + the manifest is scope-neutral (MINOR-2).**
- Command: `sed -n '3980,3994p' scripts/validate-pack.py` ; `sed -n '4191,4218p' scripts/validate-pack.py`
- Output (verbatim): `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`; `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})`; `is_pack_only` offenders = project-side & not scope-neutral; `is_project_only` offenders = NOT project-side & not scope-neutral.
- Interpretation: C1's 7 paths are all under `project-template/`+`supporting-docs/` → 0 `project-only` offenders → `project-only` CORRECT. C2's `maintenance-docs/` is NOT project-side → 0 `pack-only` offenders → `pack-only` CORRECT. `test-fixtures/manifest.txt` is scope-neutral → exempt from both offender sets → the push-time manifest commit can carry any/no keyword (MINOR-2 ambiguity is bounded, not a trap).
- Conclusion: SUPPORTED — keywords correct; the manifest commit's keyword is unstated but Check-36-safe (MINOR-2).

**EB-R7 — vocabulary purity + zero memory-feature tokens in the shipped Option-A bullet.**
- Command: python3 regex scan of the verbatim §4.2 Option-A bullet for `\bBD-?[0-9]`/`backlog-item`/`pack-[a-z]`/`pack memory`/`pack-ops`/`PACK-CHAT`/`PACK-AGENTS`/`\[rationale` (vocab) — separately for `memory`/`session memory`/`memory cache`/`~/.claude`/`~/.gemini` (PREFLIGHT-7).
- Output (verbatim): vocab `LEAKS: NONE`; memory-feature tokens — NONE.
- Interpretation: the shipped trinity bullet carries ZERO pack-concept tokens and ZERO memory-feature tokens. PREFLIGHT-VOCAB passes; PREFLIGHT-7 passes for the bullet.
- Conclusion: SUPPORTED — no leak in the only verbatim shipped text the plan fixes; MINOR-3 concerns the METHODOLOGY prose the coder authors (broad-`memory` grep false-positive risk), not this bullet.

**EB-R8 — Option A = 688 code points (12 margin) / 708 bytes / 9 `→` + 1 `≥`.**
- Command: python3 replication of the gate collapse `" ".join(x.strip() for x in lines)` + `len()` + `.encode("utf-8")` + `.count("→")` / `.count("≥")` on the verbatim §4.2 Option-A bullet.
- Output (verbatim): `collapsed code-point len: 688`; `<=700? True | margin: 12`; `UTF-8 byte len: 708`; `arrows (→): 9 | >= signs (≥): 1`.
- Interpretation: Option A fits the gate's CODE-POINT measure (688 ≤ 700, 12 margin) but is 708 bytes — a `wc -c` measure would falsely flag it. The plan's PREFLIGHT-2 code-point-not-byte mandate + thin-margin/Option-B fallback are necessary and CORRECT.
- Conclusion: SUPPORTED — exact match to the plan's §4.2/EB-P8.

**EB-R9 — the trinity insertion anchor is byte-parallel ×3 (after Reconciliation, before Phase routing).**
- Command: `for f in CLAUDE AGENTS GEMINI; do grep -n "^## Project memory\|^## Phase routing" project-template/$f.md; awk '/^## Project memory/{f=1} f&&/^## /&&!/^## Project memory/{exit} f&&/^- \*\*/{print NR": "$0}' project-template/$f.md | tail -1; done`
- Output (verbatim): CLAUDE — `## Project memory`@360, `## Phase routing`@429, last bullet `418: - **Reconciliation-instance independence.**`; AGENTS — `## Project memory`@339, `## Phase routing`@408, last bullet `397: - **Reconciliation-instance independence.**`; GEMINI — `## Project memory`@357, `## Phase routing`@426, last bullet `415: - **Reconciliation-instance independence.**`.
- Interpretation: in all three trinity files the LAST `## Project memory` bullet is `**Reconciliation-instance independence.**` and the next H2 is `## Phase routing — default agent assignments`. The plan's §4.2 anchor is precise and byte-parallel ×3.
- Conclusion: SUPPORTED — the trinity anchor (the plan's most-replicated insertion) is correct ×3.

**EB-R10 — PM-CHAT anchors + memory passages.**
- Command: `grep -n "Merge-back\|^## Behavioral rules\|^## Pack agent roster\|Per-project Claude memory\|Cross-session memory" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `47:## Pack agent roster`; `172:## Behavioral rules`; `513:**Merge-back — the patch comes only after review-clean.**`; `889:> **Per-project Claude memory cache (Claude-only).**`; `981:### Cross-session memory`.
- Interpretation: the execution-half anchor goes at/near L513; the roster/behavioral pointer at L47/L172. The CLI-memory passages (L889, L981) are well outside both edit regions. The plan's §4.3 + PREFLIGHT-7 leave-alone targets are precise.
- Conclusion: SUPPORTED.

**EB-R11 — the L390 allowlist record covers the qualified METHODOLOGY cite.**
- Command: `sed -n '386,393p' project-template/scripts/.docs-gate-allowlist.txt` ; `grep -n "docs/pack/METHODOLOGY.md" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `390:target: docs/pack/METHODOLOGY.md` + reason "pack-shipped reference doc installed into docs/pack/ at project init; present in a real install, absent from the bare template."; PM-CHAT cites `docs/pack/METHODOLOGY.md` at L138, L150, L167, L894.
- Interpretation: the qualified cite is already DANGLING-allowlisted (L390) — which is why PM-CHAT's existing cites pass today. BD-239's anchor cite of the same path rides the existing record; no new record needed.
- Conclusion: SUPPORTED — PREFLIGHT-4's "byte-identical to L390" check is right.

**EB-R12 — DANGLING regex: bare "METHODOLOGY" exempt; only `/`-qualified path matches.**
- Command: python3 replication of `DANGLING_BACKTICK = re.compile(r"`([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:md|sh|…))`")` against three test strings.
- Output (verbatim): `'the stages live in METHODOLOGY.' -> no match`; `'the stages live in `METHODOLOGY`.' -> no match`; `'see `docs/pack/METHODOLOGY.md`.' -> MATCH ['docs/pack/METHODOLOGY.md']`.
- Interpretation: the trinity bullet's bare "METHODOLOGY" (no `/`, no backtick path) is DANGLING-EXEMPT; even a non-slash backtick `METHODOLOGY` is exempt; only the qualified `docs/pack/METHODOLOGY.md` matches (and rides L390).
- Conclusion: SUPPORTED — PREFLIGHT-4's bare-word-exempt handling is correct.

**EB-R13 — DEFERRED regex lacks "groupings".**
- Command: `sed -n '202,207p' project-template/scripts/validate-docs.sh`
- Output (verbatim): `DEFERRED_PATTERN = re.compile(r"\bdeferred\b|future (release|version)|\bnot yet (created|implemented|built|shipped)\b|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b", re.IGNORECASE)`.
- Interpretation: the DEFERRED axis matches deferral PHRASING only; "groupings" is not in the alternation. The plan's §5.2 OMIT-on-grep-zero-+-BD-189-grounds (NOT a DEFERRED fear) is the correct rationale.
- Conclusion: SUPPORTED.

**EB-R14 — Check 64 (MCP/config `.example`-only) + Check 70 (`validate-docs.sh`-structure) — neither gates BD-239.**
- Command: `grep -n "_CHECK_70_CLIENT_GATE\|dangling MCP/config" scripts/validate-pack.py`
- Output (verbatim): `7144: … dangling MCP/config .example reference …`; `9024:_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"`.
- Interpretation: Check 64 evaluates MCP/config `.example` cites only — never a doc-to-doc METHODOLOGY cite; Check 70 polices `validate-docs.sh` structural integrity — fires only on a gate edit (which §6.5 forbids). The plan's M1 retarget (DANGLING axis + L390, not Check 64/70) is right.
- Conclusion: SUPPORTED.

**EB-R15 — BD-245's rename set overlaps BD-239 on exactly the 3 hand-off surfaces.**
- Command: `grep -n "SECTION RENAME\|METHODOLOGY\|PM-CHAT\|validate-docs\|Project memory\|Project rules\|Target:" backlog/BD-245.md`
- Output (verbatim, key): BD-245 SECTION RENAME set = "the trinity heading ×3 — `project-template/CLAUDE.md` (~L360), `AGENTS.md` (~L339), `GEMINI.md` (~L357) — PLUS … `project-template/docs/pack/PM-CHAT.md` (~L35 …), `supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory"), and the SHIPPED client gate … `validate-docs.sh`"; `Target: v11.0 — directly after BD-232`.
- Interpretation: BD-245 edits the trinity ×3 + `supporting-docs/METHODOLOGY.md` + `project-template/docs/pack/PM-CHAT.md` — the SAME three surfaces BD-239 adds to. The plan's §5.4 hand-off note enumerates exactly these three (plus the validate-docs.sh lock-step note BD-239 does NOT touch). The hand-off is complete — BD-245's census provably re-sweeps every BD-239 addition.
- Conclusion: SUPPORTED — the hand-off note (M2) enumerates all 3 overlapping surfaces.

**EB-R16 — no title collision; the only existing trinity adversarial mention is the Reconciliation bullet.**
- Command: `grep -rn "Workflow 4.5\|large-phase pipeline\|large-phase development pipeline" project-template/ supporting-docs/` ; `grep -ni "adversarial\|pipeline standard" project-template/{CLAUDE,AGENTS,GEMINI}.md`
- Output (verbatim): zero hits for the titles; trinity "adversarial" appears only inside `**Reconciliation-instance independence.**` (CLAUDE L419-420, AGENTS L398-399, GEMINI L416-417).
- Interpretation: the suggested subsection title does not collide with existing content; the new bullet's reference-by-concept to the Reconciliation rule does not duplicate an existing adversarial-pipeline bullet (none exists).
- Conclusion: SUPPORTED — no collision; the consolidation is genuinely NEW content.

---

## 6. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Ran only read-only verbs: `git rev-parse HEAD` → `d720873b6010a4059a2ebb919070ef85b7d2d5c6`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty; plus `grep`/`sed`/`cat`/`head`/`ls`/`awk`/`source`/`python3`/`Read`/`graphify query` measurement. NO `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase/apply` or any state-changing verb. Sole Write = this review at `/tmp/pack-handoff-bd239-plan/ADVERSARIAL-REVIEW-PLAN-BD-239.md` (Bash heredoc). No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **reconciliation-instance-independence / fresh-agent-default** | I am a FRESH independent adversary — NOT the plan author, NOT the design author, NOT the design's adversarial reviewer. I re-measured EVERY load-bearing claim FROM SOURCE at the live HEAD (EB-R1…EB-R16) rather than deferring to the plan: independently re-ran `manifest_path_is_input` (EB-R3), replicated the gate's exact bloat collapse (EB-R8) + the DANGLING/DEFERRED regexes (EB-R12/R13), re-read manifest-sync's exit-fork (EB-R4), verified fixture-copy (EB-R5), and cross-checked BD-245's rename set (EB-R15). I overturned NO confirmed finding without evidence; I raised MAJOR-1 from my OWN measurement (the plan's anchor strings vs the actual heading map), not from the plan's text. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §5 carries EB-R1…EB-R16: every finding + every confirmation backed by command + verbatim output + HEAD `d720873` + interpretation + SUPPORTED/NOT-SUPPORTED conclusion. MAJOR-1 cites EB-R1 (the heading map); MINOR-1 cites EB-R4+R5 (the exit-fork + fixture-copy); the confirm-table §3 cites EB-R2/R3/R6-R16. | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only** | I grepped the ONLY verbatim shipped text the plan fixes (the §4.2 Option-A trinity bullet) for pack-concept tokens (`\bBD-?[0-9]`/`backlog-item`/`pack-[a-z]`/`pack memory`/`pack-ops`/`PACK-CHAT`/`PACK-AGENTS`/`\[rationale`) → `LEAKS: NONE` (EB-R7). The plan's METHODOLOGY/PM-CHAT prose is authored by the coder (not verbatim in the plan), and the plan's PREFLIGHT-VOCAB (§6) gates it. No leak found in scope; MINOR-3 flags a PREFLIGHT-7 false-POSITIVE risk on the KEEP "repo is the authoritative memory" framing (a grep-sharpness fix, not a leak). | COMPLIANT |
| 5 | **operating-docs-no-history-no-bloat** | I re-measured the trinity pointer bullet vs the 700 cap: 688 code points (EB-R8), a terse pointer (full chain in METHODOLOGY, uncapped) — within cap, no history. I confirmed the HISTORY axis (dates/SHAs/Commit-N/carry-over/incident/TD-past-action) does NOT block the pipeline tokens (adversarial/reconciliation/worktree absent from validate-docs.sh axes). The plan correctly keeps the trinity bullet a pointer + bans history/deferral in the METHODOLOGY subsection (§4.1, PREFLIGHT-3). NIT-2 suggests the ASCII-arrow default to retire the byte-trap; not a violation. | COMPLIANT |
| 6 | **regenerate-manifest-v11-surface** | I independently confirmed the plan's manifest correction: `manifest.txt` is fixture-name→SHA pairs not source paths (EB-R2); all 7 edit paths are inputs (EB-R3); the edited files are copied into the built fixtures (EB-R5) → push-time `manifest-sync.sh` exits 10 (MANIFEST-CHANGED), NOT NOOP. The plan correctly defers regen to the orchestrator at push (coder leaves the manifest untouched). MINOR-1 sharpens the exit-10 PROOF (predicate→fixture-copy), not the conclusion. | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — rules 1-7, each name + quoted evidence + terminal conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

---

*End of ADVERSARIAL-REVIEW-PLAN-BD-239. Fresh independent adversarial planner
(not the plan author, not the design author, not the design's adversary); one
Write (this review) under /tmp; read-only git only; no memory store used.*

**VERDICT: NEEDS-REWORK (0 blocking/1 major)** — MAJOR-1 (wrong/conflated
METHODOLOGY insertion text-anchor in §4.1; fix to the correct Workflow-4-end /
Workflow-5-start anchors). MINOR-1 (exit-10 proof needs the fixture-copy link —
which I verified; conclusion is right), MINOR-2 (manifest commit keyword unstated
but Check-36-scope-neutral), MINOR-3 (PREFLIGHT-7 bare-`memory` grep false-
positive risk on the KEEP framing). NIT-1 (C2 row in the C1 edit table), NIT-2
(consider ASCII-arrow default). The manifest STATE-CORRECTION is independently
CONFIRMED correct and is a genuine improvement on the design. All trinity /
PM-CHAT / allowlist anchors are byte-parallel ×3 at live HEAD; the 688-codepoint
bullet re-measures EXACTLY; the scope keywords are correct; zero vocabulary leak.
The plan is faithful to the reconciled design and close to coder-ready — fix
MAJOR-1 (and ideally fold MINOR-1's proof + MINOR-3's grep) and it is ready.
