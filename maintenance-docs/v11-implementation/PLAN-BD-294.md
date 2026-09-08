# PLAN-BD-294 — implementation plan for the trinity/graft contract collision (D3) and the seed-slot over-capture (D5)

**Pass type:** PLAN. Nothing in the pack was modified. Every claim below was
re-measured at the current HEAD; nothing is inherited on trust.
**Pack under plan:** `/Users/david/Developer/optiquity-ai-agent-config-pack` @ `b40f111d84f361917aa09e93ff74c19194bbab9b`
**Measured from:** worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af6b1a356daf9e524`, HEAD `b40f111`, clean, `.git` = **101-byte pointer FILE** (trap #1 is live).
**Scratch root:** `/Users/david/.local/state/optiquity-pack-handoff/bd294-planner-20260907T070000Z/scratch.r8C7JW/` — `pack/` (pristine `git clone --no-hardlinks`, `.git` re-verified as a real **directory**), `eng-naive/`, `eng-d5/`, `eng-optB/`, `mut98/`. Overlays committed inside their own clone before measurement (trap #2).
**Date:** 2026-09-07
**Tracked entry:** `/Users/david/Developer/optiquity-ai-agent-config-pack/backlog/BD-294.md` (Status: Open, Target: v11.0, launch-gating)
**Design read:** `ARCHITECTURE-BD-294.md`, `OT-DEFECT-REPORT-CORRECTED.md` §6/§8, `CENSUS-CROSSPATH.md` (handoff dir `bd294-architect-20260903T020000Z`).

---

## 0. In plain language

**Today.** A client installs the trinity. At the top of `CLAUDE.md` the pack has
put a block that says *"Fill in placeholders and remove this block."* They do
exactly that — they type their project's name where it says `[PROJECT_NAME]`,
and they delete the block. On their next update the pack's merge engine looks at
the file, sees text it thinks it owns that no longer matches, refuses the merge,
copies the pack's own placeholder-bearing file back over their live `CLAUDE.md`,
and parks their edited copy in a side file. From that moment every agent that
reads `CLAUDE.md` at session start is told the project is called
`[PROJECT_NAME]`. If instead the client wraps their name in the pack's own
"this part is mine" marker pair, the engine rejects that too, because the text
sits above the first heading and a marker is not allowed there. There is no
third way to comply. The same trap is set seven more times per file, and five
more times by comments that say *"delete the entire section if not applicable"* —
where the deletion is silently put back with no message at all. Separately, a
client who tidies their own sections into marker pairs and appends them at the
end of the file — under a section the pack itself named `## Project addenda` —
has every one of those blocks reclassified, their content dropped from the
merge, and gets an error naming *their own new heading* as a **pack** section
that has gone missing.

**After.** The parts of the trinity a client is meant to edit ship already
wrapped in the pack's marker pairs, so filling them in is a clean merge that
keeps every value. The two blocks the file told clients to delete are simply not
shipped, so there is nothing left to delete. The five "delete the entire
section" comments say *suppress, do not delete*, and point at the procedure the
pack already ships for it. And the engine treats a marker pair that opens with
its own `##` heading as the section it plainly is, wherever in the file it sits.
Clients who already migrated are not repaired automatically by any of this — a
one-time, in-place remediation recipe ships with the fix and is proven below to
reach a clean merge with no re-migration and no loss of anything they typed.

**Cost: six commits.** One fixes the engine, one fixes the template, one adds
the standing guard, one ships the remediation recipe, one lands the design
record, one flips the entry closed. Four of the six can start in parallel; two
must wait their turn, for reasons measured in §4.

---

## 1. Adversarial re-verification of the design's load-bearing measurements

The design was measured at `9171243` on 2026-09-03. Since then five commits
landed (BD-293 Waves 3–4 + the RC2 version bump), touching **118 files**.
Every load-bearing claim was re-run at `b40f111`.

**First, the scope question — did BD-293 move anything BD-294 stands on?**

> **EEB-P1 — the D3/D5 code and template surfaces are byte-untouched since the design.**
> Command: `git log --oneline 9171243..b40f111`; `git diff --stat 9171243 b40f111`, in my own worktree, 2026-09-07.
> Output: 5 commits (`b40f111`, `e46ebf6`, `aa2e90c`, `ec4aeb1`, `1df7ade`); `118 files changed, 3828 insertions(+), 510 deletions(-)`.
> **Absent from that file list:** `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `scripts/lib/marker-preserve.sh`, `scripts/lib/validate_checks/trinity_markers.py`, `project-template/skills/resolve-merge-conflicts/SKILL.md`, `supporting-docs/PRE-RECONCILE-v10-to-v11.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/tests/test-marker-preserve-bd136.sh`, `test-fixtures/v11-trinity-marker-prepped/*`.
> **Present in that file list:** `pack-ops/MERGE-STRATEGY.md` (+11/−…), `supporting-docs/MIGRATION-v10-to-v11.md` (+53/−…), `scripts/validate-pack.py` (+18), `scripts/lib/validate_checks/core.py` (+6/−1), `README.md` (+5/−2), `scripts/ci-shard-weights.tsv` (+4), `scripts/init-project.sh` (+191), `scripts/migrate-v10-to-v11.sh` (+188), `scripts/lib/customization-preserve.sh` (+4/−…).
> Corroboration: the pristine `marker-preserve.sh` hashes to `ee492a9b96f2…` in my clone — **byte-identical to the sha the design recorded** (`ee492a9b96f24f113549ae3a354dfa603e2a2338`).
> Interpretation: the two defect mechanisms and their primary fix surfaces are exactly as designed; the drift is confined to the *doc* and *CI-wiring* surfaces, which is where my line-reference corrections land.
> **SUPPORTED.**

### 1.1 Re-verification table

| # | Design claim | Re-measured at `b40f111` | Verdict |
|---|---|---|---|
| 1 | EEB-1 — `## Project addenda` is the last H2 in all three files: `CLAUDE.md` 511/522, `AGENTS.md` 488/499, `GEMINI.md` 545/556; seed pair on the final two lines | identical, to the line | **CONFIRMED** |
| 2 | Identity lines at `CLAUDE.md:26–27`, `AGENTS.md:24–25`, `GEMINI.md:22–23`; first H2 at 29/27/25 | identical | **CONFIRMED** |
| 3 | EEB-7 — D3 leg (a): filling in place → `customization-detected-needs-reconciliation`, *"pack-owned preamble diverges (out-of-marker) … (L-8)"*; filled identity in DEST **0**, `[PROJECT_NAME]` back in DEST **2** | identical disposition, identical message, identical counts | **CONFIRMED** |
| 4 | EEB-7 — D3 leg (b): also deleting both preamble blocks → same L-8 | identical | **CONFIRMED** |
| 5 | EEB-7 — the marker route → *"marker well-formedness failure (L-6/L-1): project-owned marker region beginning at **line 26** has no enclosing H2 heading"* | identical, same line number | **CONFIRMED** |
| 6 | EEB-8 — leg (d): a raw section deletion returns `merged-with-customization` with the section **silently restored**; a same-name Shape B override is honoured (pack body absent, client note present) | reproduced exactly | **CONFIRMED**, and **EXTENDED** — a third outcome exists (§1.2) |
| 7 | EEB-9 — census: 54 occurrences, **STRIP 30 / KEEP 0**, 24 remove/delete instructions; CLAUDE STRIP lines `9,26,27,58,86,91,96,104,168,365` | 54 / 30 / 0 / 24, identical line list | **CONFIRMED exactly** |
| 8 | EEB-2 — D5 both signatures: `at-eof` → sidecar with *"pack section '&lt;your own heading&gt;' … is absent from the new canonical … (L-8)"*, content in DEST **0**; `mid-file` → clean, content **1** | reproduced on fixtures that are **pure line permutations** of one another (multiset identical by construction) | **CONFIRMED** |
| 9 | EEB-3 — the "naive" close-time reorder alone is a **no-op**, not a hazard (overturning the incoming census) | **0** classification deltas and **0** disposition deltas across 9 fixtures | **CONFIRMED** |
| 10 | EEB-4 — the D5 fix repairs both signatures; the three placements produce a **byte-identical** graft; idempotent | `s1` all `dest-sha=25574fab9e7ca67e`, `s2` all `9b6d6ec1e07c8b45`; re-feed → `merged-with-customization` | **CONFIRMED** |
| 11 | EEB-5 — the fix changes **exactly one** seed-shape classification (`##`-first); `###`-first, prose-then-`###`, prose-only all unchanged | exactly so within the sd1–sd4 set | **CONFIRMED** (see §1.2 for the precise wording) |
| 12 | EEB-6 — the two parsers must move together | at HEAD both parsers **agree** on all 6 fixtures; after the bash-only fix they **disagree on exactly the 3** whose classification moved | **CONFIRMED** (the design states it as disagree-then-agree; same fact, stated from the post-fix side) |
| 13 | EEB-12 — the Option-B tree passes the battery with **no test and no check modified** | `68 / 19 / 22 / 13 passed`, Checks 91/19/16 pass, `validate-pack.py` exit 0, **and `PACK_VALIDATE_DEEP=1` exit 0** | **CONFIRMED** (extended to DEEP, which the design did not run) |
| 14 | EEB-12 — a compliant new client grafts clean, all 8 values preserved, **0 residual placeholders** | `merged-with-customization`; identity 1, `FILLED-*` 7, residual **0** | **CONFIRMED** |
| 15 | EEB-12 — the remediation recipe reaches a clean, idempotent graft with no loss | `merged-with-customization`, residual 0, all 8 values present, re-feed clean | **CONFIRMED** |
| 16 | EEB-10 / OI-8 — the reference fixture preamble is bare and becomes byte-identical under Option B | fixture preambles are exactly `# CLAUDE.md` / `# AGENTS.md` / `# GEMINI.md`; Option B produces exactly those | **CONFIRMED** |
| 17 | EEB-11 / OI-5 — *"a standing cost on every future v11.x content release"* | **false at `b40f111`** — BD-293 seeded the R1 baseline ledger on both entry paths (§3) | **STALE** |
| 18 | EEB-16 — collision scan: BD-289 scores **`none`** | **wrong** — BD-289 collides on 5 paths that BD-294's own T-3 recommendation must edit (§2) | **STALE / INCOMPLETE** |
| 19 | `supporting-docs/MIGRATION-v10-to-v11.md` is 1098 lines | **1127** | **MOVED** |
| 20 | `pack-ops/MERGE-STRATEGY.md` is 680 lines, Shape A/B prose at `:200–:206` | **689** lines; the Shape A/B prose is **still at `:200–:206`** | **MOVED** (length), **CONFIRMED** (anchor) |
| 21 | `SKILL.md` 287 lines, order-independence claim at `:129` | 287 / `:129` | **CONFIRMED** |
| 22 | `PRE-RECONCILE-v10-to-v11.md` 298 lines; `INSTALL-PROCEDURES.md` 1390; `test-marker-preserve-bd136.sh` 669 | 298 / 1390 / 669 | **CONFIRMED** |

**Where I could not reproduce a claim, and how I plan around it.** There is one.
The design's EEB-8 measured leg (d) with the `<!-- OPTIONAL: … -->` comment left
in place; my first attempt deleted the comment along with the section — the
literal reading of *"delete the entire section"* — and got a **different**
disposition. Rather than inherit either result, I measured both, and both are
real. §1.2 records the third outcome and folds it into the plan. Nothing else in
the design failed to reproduce.

### 1.2 Three corrections the plan is built on

**(a) Leg (d) has THREE outcomes, not two — and the worst one is a second
misdiagnosis.** The `<!-- OPTIONAL: … -->` comment sits *above* the heading it
describes, so it is lexically part of the **preceding** section's body.

> **EEB-P2 — the third leg-(d) outcome.**
> Command: `python3 h/run2.py`, engine = pristine clone, Regime B (`BASE=""`), controls `unchanged-pack` / `customization-detected-needs-reconciliation` / `merged-with-customization` → `CONTROL-RESULT: PASS -> VALID`, 2026-09-07.
> Output:
> ```
> optd-delete                merged-with-customization
>     '## gRPC and Proto3 rules' in DEST (1=restored): 1 ; pack '[GRPC_RULES' body in DEST: 1
> optd-suppress              merged-with-customization
>     '## gRPC and Proto3 rules' in DEST (1=restored): 1 ; pack body in DEST: 0 ; 'Not applicable' in DEST: 1
> optd-delete-with-comment   customization-detected-needs-reconciliation
>     notes=pack-owned body outside your markers under '## Language-specific coding rules' diverges …(L-2/L-8/B1)
> ```
> Also measured: `gRPC section heading..next-heading = lines 94..97 ; OPTIONAL comment is L[92]` — i.e. the comment is the last line of the *previous* section's body.
> Interpretation: a client who deletes heading+body only gets a **silent revert**; a client who deletes what the comment plainly calls "the entire section" (comment included) gets a **sidecar blaming a section they never touched**. Both are defects, and the second is structurally the same misdiagnosis class as D5. The reword must therefore stop the delete *and* the plan must cover this leg in T-2.
> **SUPPORTED.**

**(b) "Exactly one classification changes" is true of the seed-shape set, and
should be stated that way.** Measured across nine fixtures on three engines:

> **EEB-P3 — classification deltas, three engines, controls PASS on each.**
> Command: `python3 h/run3.py`, 2026-09-07. Fixture pairs are pure line permutations (`s1` multiset `cdd5a4616eb7`, `s2` `0e09aa08ead2`, `GROUP-IDENTICAL` by construction). Controls on each engine: `PASS -> VALID`.
> Output (abridged):
> ```
> fixture           pack-HEAD                    eng-naive                    eng-d5
> s1-at-eof         SIDECAR A:addenda;A:addenda  SIDECAR (same)               clean   A:addenda;B:## Xcode 26.4…
> s2-at-eof         SIDECAR A:addenda;A:addenda  SIDECAR (same)               clean   A:addenda;B:## Release checklist
> sd1-h3-first      clean   A:addenda            clean   A:addenda            clean   A:addenda
> sd2-prose-h3      clean   A:addenda            clean   A:addenda            clean   A:addenda
> sd3-prose         clean   A:addenda            clean   A:addenda            clean   A:addenda
> sd4-h2-first      SIDECAR A:addenda            SIDECAR A:addenda            clean   B:## Release checklist
> oi1-addenda-notes SIDECAR A:## Project addenda notes  (same)                SIDECAR B:## Client extra section
> REGION-classification deltas pack-HEAD -> eng-d5:    4 :: [s1-at-eof, s2-at-eof, sd4-h2-first, oi1-addenda-notes]
> REGION-classification deltas pack-HEAD -> eng-naive: 0 :: []
> ```
> Interpretation: **within the four sanctioned seed shapes exactly one (`sd4`, the defect) moves** — the design's claim, confirmed. The other three deltas are the two D5 defect fixtures (the point of the fix) and the OI-1 leg (a deliberate second change). The naive reorder moves **nothing**, confirming EEB-3 and confirming that a coder who ships it and sees green has shipped nothing.
> **SUPPORTED.**

**(c) The OI-1 test leg must assert CLASSIFICATION, not disposition.** The
`oi1-addenda-notes` row above is the proof: under the exact-match tightening the
classification correctly flips `A:## Project addenda notes` → `B:## Client extra
section`, but the **disposition stays `SIDECAR`** — for a different and correct
reason (the client also added an unwrapped H2, which the engine rightly refuses).
A test that asserted the disposition would report the tightening as a failure.
This is exactly the hazard EEB-5 warned about and it fires here. The plan pins
the assertion to `_mp_regions` output.

---

## 2. Cross-BD collision scan (re-run, corrected)

The design's scan used a **15-path** blast radius that omitted every surface its
own T-3 recommendation requires. Re-run with the corrected set.

> **EEB-P4 — corrected collision scan.**
> Command: open set read from `backlog/_toc.md` § Open (19 entries: BD-020, 036, 037, 039, 109, 110, 171, 172, 187, 192, 202, 223, 247, 254, 279, 289, 292, 293, 294); each entry's `File/Symbol` + body intersected against BD-294's **corrected 22-path** blast radius, 2026-09-07.
> Paths added to the design's 15: `scripts/validate-pack.py`, `scripts/lib/validate_checks/core.py`, `README.md`, `scripts/lib/ci-shard-plan.py`, `scripts/ci-shard-weights.tsv`, `scripts/tests/` (new files), `maintenance-docs/v11-implementation/`.
> Output:
> - **BD-289** (`Status: Open`, `Target: v11.1`) — **COLLISION on 5 paths.** Quoted from `backlog/BD-289.md:8`: *"`scripts/validate-pack.py` (registry tuple); `scripts/lib/validate_checks/core.py` (`CHECK_REGISTRY_EXPECTED_COUNT` and the running ledger comment); `README.md` (two check-count claims); `scripts/tests/` (new per-check tests for 95 and 96); `scripts/lib/ci-shard-plan.py` (coverage assertion)"*. The design scored this `none`.
> - **BD-293** (`Status: Open`, `Target: v11.0`) — COLLISION on `supporting-docs/MIGRATION-v10-to-v11.md` (both entries add remediation prose) and on `scripts/init-project.sh` / `scripts/migrate-v10-to-v11.sh` / `scripts/lib/customization-preserve.sh` (BD-293's surface, **not** in BD-294's edit set).
> - 17 other open entries: `none`.
> Interpretation: **two** real collisions, not one.
> **SUPPORTED.**

**How each is handled — both are COORDINATE signals, neither is a gate.**

- **BD-289 (v11.1, lands later).** The collision is *forward-directional*: BD-294
  ships first and must not consume BD-289's reserved slots. Measured from the
  pack's own ledger, `scripts/lib/validate_checks/core.py:207–214`:
  *"Check 97 … 91 → 92. **(Next free numeric ID = 98.)**"* and, in `README.md`,
  *"Checks 95–96 reserved for BD-289, unlanded"*. **BD-294's guard is Check 98.**
  Commit C3 must (i) take 98, (ii) bump the count 92 → 93, (iii) advance the
  ledger comment to *"Next free numeric ID = 99"*, and (iv) **preserve the
  "95–96 reserved for BD-289" sentence verbatim** in both README claim sites.
  Getting this wrong silently steals a slot from an open entry.
- **BD-293 (v11.0, in flight).** Sequence the two `MIGRATION-v10-to-v11.md`
  commits; do not run them in the same wave. BD-294's C4 touches only that file
  and nothing else BD-293 owns.

---

## 3. The two things I was told to measure, not assume

### 3.1 OI-3 — the replacement wording for the five `OPTIONAL:` comments

**The user's rule:** *"If this is done often, use a self-contained recipe in the
file. If infrequent or done only once, use a pointer to the skill."* So the
question is purely one of **frequency**, and it is measurable.

> **EEB-P5 — suppressing an optional trinity section is a ONE-TIME, setup-only act.**
> Commands + outputs, 2026-09-07:
> 1. `sed -n '560,600p' supporting-docs/INSTALL-PROCEDURES.md` — the decision is **step 5 of a numbered one-time procedure**, and the doc names its entry paths: *"applies on every entry path: fresh install (`SETUP-NEW.md` § Customizing the trinity files), existing-project adoption (`SETUP-EXISTING.md` § Customizing the trinity files), and v10→v11 migration."* A given project traverses **exactly one** of those, **once**.
> 2. `grep -n 'optional section\|OPTIONAL:\|delete the entire section' supporting-docs/MIGRATION-v10-to-v11.md` → **no output**. The migration guide never re-presents the choice.
> 3. Cross-version churn: `git show v10:project-template/CLAUDE.md` → the v10 optional sections are `[CONDITIONAL]`-prefixed at lines 52, 74, 78, 82, 292 = **5 sections**. v11 ships `OPTIONAL:` comments at CLAUDE.md lines 60, 83, 88, 93, 351 = **5 sections**. **Across an entire major version the count went 5 → 5 — the pack added not one new optional section**, so the "client re-faces the decision on update" path did not fire even once.
> Interpretation: the action is performed **once per project, at setup**, and a whole major version produced zero repeat occasions. Under the user's rule this is unambiguously the *infrequent / done-once* branch. **The POINTER form wins.**
> **SUPPORTED.**

**So my answer differs from the architect's.** The design recommended option (a),
the self-contained recipe; the user's rule, applied to the measurement, selects
option **(b), the pointer**. The design's argument for (a) — *"(b) costs a
document hop at exactly the moment the client is deciding"* — is a real cost, but
the user's rule prices that cost explicitly and resolves it against the recipe
for infrequent actions.

**Where the pointer points, and why it is not the merge skill.** The action is
*authoring*, not *merge resolution*, and the pack already names its authoring
SSOT.

> **EEB-P6 — the pointer target exists, ships, and is already the pack's own convention.**
> Commands + outputs, 2026-09-07:
> 1. `supporting-docs/INSTALL-PROCEDURES.md:582` — *"The full Shape A (body-wrap) / Shape B (whole-section) authoring procedure lives in `docs/pack/PM-CHAT.md` (how to add project-owned content to trinity files)"*.
> 2. `grep -n '^#\{1,4\} ' project-template/docs/pack/PM-CHAT.md` → `1256:## How to add project-owned content to trinity files`, `1280:### The two shapes`. Body verified at `:1284–:1336` — it carries Shape A, Shape B, the choose-between rule, and RIGHT/WRONG examples. This is **backing verified**, not existence asserted.
> 3. It ships on every axis: `scripts/init-project.sh:2417` — *"`project-template/docs/pack/PM-CHAT.md -> docs/pack/PM-CHAT.md [stage:S6,cmd_update,migrate]`"*.
> 4. The pack **already emits this exact pointer for this exact concept**: `scripts/init-project.sh:2337` and `:2633` — *"see docs/pack/PM-CHAT.md (project-owned marker authoring) before editing."*
> Interpretation: the pointer form is not an invention; it is the shipped convention, targeting a project-side SSOT that already carries the procedure (`P-missed-7` satisfied — no pack-side mechanism is imported).
> **SUPPORTED.**

**The exact proposed sentence** (shown for the first of the five; the other four
substitute their own condition clause verbatim):

```
<!-- OPTIONAL: keep this section if your project targets iOS 26 / macOS 26. If it does not
     apply, suppress it — do not delete it; see docs/pack/PM-CHAT.md § "How to add
     project-owned content to trinity files". -->
```

Rendered as one line per the file's existing style. The transformation is
mechanical: split each comment at `"; delete the entire section if not
applicable"`, keep the head, append the fixed tail. Verified: all 15 occurrences
(5 per file × 3) match that split, and after it `"delete the entire section"`
occurs **zero** times in all three files (asserted in `h/build_optB.py`).

The sixth instruction, `[GRPC_RULES — fill in from grpc-patterns skill, **or
delete section**]`, drops its tail in the same commit — it is the same
instruction in a different costume, and leaving it is the partial-Option-B the
design's own EEB-12 row 2 disproves.

### 3.2 OI-5 — the `--update` empty-BASE attribution problem, re-measured

The design measured this on 2026-09-03 as *"a standing cost on every future v11.x
content release"* and routed it to BD-293. **At `b40f111` that is no longer
true**, because BD-293 landed the machinery in the interim.

> **EEB-P7 — `cmd_update` now resolves a real BASE through a four-rung cascade, and both entry paths seed it.**
> Commands + outputs, 2026-09-07:
> 1. `sed -n '1709,1775p' scripts/init-project.sh` — the cascade is documented in the source: *"R1 a prior run's ledger names the blob it installed here — materialise it; R2 OURS is itself a blob the pack has held at this SOURCE path, so OURS IS a pack baseline — pass OURS as BASE; R3' OURS is not provably pack-authored — BASE stays EMPTY; R4' the run cannot reach the baseline anchor"*.
> 2. `sed -n '1588,1599p' scripts/init-project.sh` — the fresh-install seed, and the defect it closed, in the pack's own words: *"ORIGINATE the BASE-cascade rung-R1 ledger this install's client will need the FIRST time they run `--update`. … The ledger was only ever written BY an update FOR the next update, so **every client lost their customizations on the first update of their life** and preserved correctly from the second onward."*
> 3. `scripts/init-project.sh:2086–2088` — the R1 READ consults **three** state dirs: `$state_dir/`, `$TARGET/.pack-install-reconcile/`, `$TARGET/.pack-migrate-*/`.
> 4. `sed -n '640,657p' scripts/migrate-v10-to-v11.sh` — the **migrator writes it**: *"R1 WRITE. ONE `git hash-object --stdin-paths` pass for the whole set … That state dir is one of the three the update path's R1 READ loop consults"*, emitting *"R1 baseline ledger written: N row(s) (lets the first --update after this migration preserve your edits to pack files)"*, and a `warn` when it is empty.
> 5. Behavioural confirmation, `python3 h/run5.py` (controls PASS), THEIRS = the canonical with one out-of-marker line changed:
> ```
> R2/R1 (BASE present) untouched client      -> merged-with-customization
> R3'  (BASE empty)    untouched client      -> customization-detected-needs-reconciliation
> R3'  (BASE empty)    filled IN-MARKER      -> customization-detected-needs-reconciliation
> ```
> Interpretation: the sidecar the design measured is the **R3'** row, and R3' is now reached only by a client with **no ledger from any entry path** — which, after BD-293, is neither a migrated client nor a freshly-installed one. For the two populations that exist, a pack-authored trinity edit resolves through R1/R2 into Regime A and grafts cleanly.
> **NOT-SUPPORTED** (the design's "standing cost on every release" claim, at this HEAD).

**Does the D3 change make it better or worse? Strictly better, and measured.**
Under Option B the client's own values live *inside* marker pairs, and the engine
strips marker content from both sides before the skeleton compare — so the
client's fill no longer diverges the skeleton **even when BASE is empty**. That
is the `B-compliant-filled → merged-with-customization` row of EEB-P8 below,
produced at `BASE=""`. Before Option B, the identical client is the
`B-already-migrated-today → sidecar` row.

**Residual, stated plainly.** One case survives: a client in R3' (no ledger on
any of the three paths, e.g. a hand-assembled v11 tree, or the `warn` branch
where the migrator's ledger came out empty) who has edited the file, when the
**pack** changes an out-of-marker line. Option B does not remove that, and
nothing in BD-294 can — it is `cmd_update`'s attribution, i.e. BD-293's surface.
BD-293 already emits an explicit operator warning naming exactly that state.

**Recommendation: drop OI-5 from BD-294 and open no work anywhere.** This is not
a deferral — there is no residual work item to defer. The problem the design
routed to BD-293 has **already been fixed by BD-293**, in this same version, and
I verified the fix rather than assuming it. The narrow remainder is a documented,
warned-about degradation of a shipped cascade, not an open defect. If the user
disagrees, the only sensible home is still BD-293's cascade, never BD-294 and
never a new entry.

---

## 4. Commit sequence

Six commits. Each leaves the tree green: `validate-pack.py`,
`PACK_VALIDATE_DEEP=1`, the wired test battery, and
`ci-shard-plan.py --assert-coverage` all pass at every boundary.

| # | Goal (one line) | Files | Scope keyword | Order rationale — what breaks if reversed |
|---|---|---|---|---|
| **C1** | The engine classifies a marker pair that opens with its own `##` heading as the section it is, wherever it sits — and the second parser agrees | `scripts/lib/marker-preserve.sh`, `scripts/lib/validate_checks/trinity_markers.py`, `scripts/tests/test-marker-preserve-bd136.sh`, `pack-ops/MERGE-STRATEGY.md`, `project-template/skills/resolve-merge-conflicts/SKILL.md`, `supporting-docs/PRE-RECONCILE-v10-to-v11.md`, `test-fixtures/v11-trinity-marker-prepped/README.md` | **none** (mixed: pack + `project-template/` + `supporting-docs/`) | Independent of C2 on mechanism (measured, §5.2), but **shares `SKILL.md` + `PRE-RECONCILE` with C2 → must serialize.** First because it is small, self-contained, and lets C2's template work be validated against an engine that already classifies correctly. |
| **C2** | The shipped trinity's editable content lives inside shipped marker pairs; nothing instructs a deletion the engine undoes | `project-template/{CLAUDE,AGENTS,GEMINI}.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `project-template/skills/resolve-merge-conflicts/SKILL.md`, `supporting-docs/PRE-RECONCILE-v10-to-v11.md`, **new** `scripts/tests/test-trinity-template-obeyable.sh` | **none** (mixed: `project-template/` + `supporting-docs/` + `scripts/tests/`) | Must precede C3 — see below. Must not precede C1 only because of the shared docs. |
| **C3** | A push-time guard makes the defect class unrepeatable | `scripts/lib/validate_checks/trinity_markers.py`, `scripts/validate-pack.py`, `scripts/lib/validate_checks/core.py`, `README.md`, `scripts/ci-shard-weights.tsv`, **new** `scripts/tests/test-validate-pack-check-98.sh` | `pack-only` | **HARD: must follow C2.** Measured — Check 98 returns **54 findings** against the tree as it stands today (EEB-P9). Landing it before C2 makes that commit boundary **red**. This is the identical trap BD-289 documents for Check 95. |
| **C4** | Already-migrated clients get a one-time, in-place repair | `supporting-docs/MIGRATION-v10-to-v11.md` | `project-only` | Must follow C2 — the recipe's target shape *is* the C2 canonical, and it names the shipped seed pairs. Shares no file with C1/C2/C3; **serialize against any BD-293 commit touching the same file.** |
| **C5** | The design record lands where the repo keeps them | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-294.md`, `maintenance-docs/v11-implementation/PLAN-BD-294.md` | `pack-only` | No dependency. Parallelizable with everything. |
| **C6** | Entry closed | `backlog/BD-294.md`, `backlog/_toc.md`, `pack-ops/session-state.json` | `pack-chat-only` | Last, by definition. Pack-Chat-direct per the implicit-status-flip rule. |

### 4.1 Parallelization map (rule 10)

```
        ┌── C1 ──┐                      (marker-preserve.sh, trinity_markers.py, SKILL.md, PRE-RECONCILE)
        │        ▼
wave 1  │      C2 ──► C3 ──► C4         C2 shares SKILL.md + PRE-RECONCILE with C1  → serialize
        │                               C3 reds if it precedes C2                   → serialize
        │                               C4 needs C2's canonical to point at         → serialize
        └── C5 ────────────────────────  no shared file with anything                → parallel
                                        C6 last
```

- **Serial chain:** C1 → C2 → C3 → C4. Four commits, one worktree, sequential.
- **Parallel:** C5 may run in its own worktree concurrently with C1 (it touches
  only `maintenance-docs/`, which nothing else in this plan reads or writes).
- **Same-file serialization inside the chain, named explicitly:**
  `project-template/skills/resolve-merge-conflicts/SKILL.md` (C1 + C2),
  `supporting-docs/PRE-RECONCILE-v10-to-v11.md` (C1 + C2),
  `scripts/lib/validate_checks/trinity_markers.py` (C1 + C3).
- **Cross-BD serialization:** `supporting-docs/MIGRATION-v10-to-v11.md` (C4 vs any
  BD-293 commit).

---

## 5. Per-commit detail

### 5.1 C1 — the engine, both parsers, and the docs that encode the contract

**Commit subject:** `fix: v11 — BD-294 a marker pair that opens with its own heading is that section, wherever it sits`
**Scope keyword:** none. The file set spans `scripts/`, `pack-ops/`,
`project-template/` and `supporting-docs/`, so no exclusive keyword is truthful.
Check 36 is skipped for un-keyworded commits by design; claiming `pack-only`
here would be a CI failure, not a discipline note.

**Region 1 — `scripts/lib/marker-preserve.sh`, `_mp_regions` (the awk program, lines ~180–225).**

Two edits, both inside the `awk '…'` program.

- *Close side* (currently lines 194–200): today the seed-slot branch is tested
  **before** `sawheading`. Reorder so `sawheading` is tested first, and tighten
  the seed test from the prefix regex `beginh2 ~ /^## Project addenda/` to an
  exact trimmed compare `trim(beginh2) == "## Project addenda"` (OI-1 (c)).
- *Open side* (currently line 212, `if (beginh2 ~ /^## Project addenda/){ sawbody=1 }`):
  inside a seed-slot region, a `^## ` heading that is the region's **first
  content** (`!sawheading && !sawbody`) is promoted to the owned Shape-B heading;
  a `### ` heading, or any heading after body text, still sets `sawbody=1` and
  stays Shape A. Same exact-match tightening.

> **CODER TRAP, measured.** The awk program lives inside a **single-quoted bash
> string**. An apostrophe anywhere in an added comment or string terminates it.
> My first patch attempt wrote *"the region's OWN section"* and produced
> `marker-preserve.sh: line 219: syntax error near unexpected token '{'`. The
> controls caught it (all three returned empty); a suite without must-pass
> controls would have reported it as a behaviour change. **Write no apostrophe
> inside `_mp_regions`**, and run `bash -n scripts/lib/marker-preserve.sh` as the
> first verification step.

**Region 2 — the OURS-head loop, `marker-preserve.sh` ~lines 539–556 (OI-6 (b)).**
The `[[ $is_sb -eq 1 ]] && continue` skip matches Shape B heads *by name*. Widen
it: skip any head whose line number falls inside **any** region's `[RB,RE]` span,
Shape A or B. The region arrays `RSHAPE/RHEAD/RB/RE` are already loaded in scope.
This makes it structurally impossible for a marker-enclosed heading to be
adjudicated a pack section and fire the L-8 *"absent from the new canonical"*
branch at `:554`.

**Region 3 — `scripts/lib/validate_checks/trinity_markers.py`, `_scan_markers`.**
The identical two edits, at the identical two decision points: `:182`
(close side) and `:206` (open side). Plus the docstring at `:133–:137`, which
states the mirror contract in words — *"The Shape classification MIRRORS the bash
merger's `_mp_regions`: the `## Project addenda` seed slot is Shape A even with
inner headings"* — and must now say **H3-and-below** inner headings.

> **Scope bound, measured.** `_ADDENDA_H2` has **four** use sites in that file:
> `:182`, `:206`, `:354`, `:357`. Only `:182` and `:206` are classification
> sites and only those two get the exact-match tightening. `:354` (*"does this
> file contain an addenda section at all"*) and `:357` (*"is there a Shape A
> region hosted by it"*) are a different question on a different check leg;
> changing them would be an unmeasured behaviour change. The design named two
> sites total; there are two **per parser** plus two unrelated.

**Region 4 — tests, `scripts/tests/test-marker-preserve-bd136.sh` (669 lines, M-1…M-19 today).**
Four new legs, ~140–180 lines. Every fixture pair is built as a **pure line
permutation** — construct the mid-file variant, then *move* the exact block to
EOF — so an identical sorted-line multiset is guaranteed by construction rather
than asserted after the fact. My own first attempt built the two variants
independently and they diverged (`GROUP-IDENTICAL: False`); the permutation
construction cannot.

- **M-20** — placement invariance of a Shape B override with `renamed-from`
  (Regime B). Assert (a) the two fixtures' sorted line multisets are equal,
  (b) both dispositions `merged-with-customization`, (c) the two DEST files are
  **byte-identical**, (d) the override body is present in each DEST.
- **M-21** — same for a brand-new section with no `renamed-from`. Additionally
  assert **the `notes` field does not name a project-owned heading** (OI-6's
  containment assertion — it costs one line here rather than a new test).
- **M-22** — the seed slot keeps its exception: four shapes inside the shipped
  seed pair (`###`-first, prose-then-`###`, prose-only, `##`-first). Assert the
  first three are **Shape A** hosted by `## Project addenda` and clean; the
  fourth is **Shape B** with owned head, and clean. **Assert via `_mp_regions`
  directly, not only via the disposition.**
- **M-22b** — the OI-1 leg: a client H2 literally named `## Project addenda
  notes` with an H2-first pair beneath it. **Assert the classification is
  `B:<owned head>`, not the disposition** — measured, the disposition stays
  `customization-detected-needs-reconciliation` for a correct and unrelated
  reason (§1.2(c)).
- **M-23** — bash↔python classification parity: for each M-20/M-21/M-22 fixture,
  `_mp_regions`' `shape:head` sequence equals `_scan_markers`' `shape:head`
  sequence.

**Region 5 — the docs that encode the contract (lockstep, `enumerate-encoding-surfaces`).**

| Surface | Line anchor (verified at `b40f111`) | Change |
|---|---|---|
| `pack-ops/MERGE-STRATEGY.md` | `:200–:206` (Shape A/B prose) | Shape B is a whole owned section **wherever it appears, including inside the addenda seed**; the seed exception admits H3-and-below only. ~2 lines. |
| `project-template/skills/resolve-merge-conflicts/SKILL.md` | `:129–:131` (the order-independence claim) | Keep the claim; add that the addenda seed no longer special-cases an H2-first pair, so the claim now holds literally. ~2 lines. |
| `supporting-docs/PRE-RECONCILE-v10-to-v11.md` | §(d) pitfall list | State the seed-slot carve-out on the "heading inside a Shape A region" bullet. ~3 lines. |
| `test-fixtures/v11-trinity-marker-prepped/README.md` | `:28–:35`, `:77`, `:87` | The README states the exception as *"the seed-slot exception permits project H3"* — still true, but tighten to name H3-and-below explicitly so the fixture's rationale matches the narrowed rule. ~2 lines. **The fixture bytes do not change**, so no manifest impact from C1. |

**Verification that proves C1:**
1. `bash -n scripts/lib/marker-preserve.sh` (the apostrophe gate).
2. `bash scripts/tests/test-marker-preserve-bd136.sh` — was 68, becomes ~68+N.
3. The five mutants below, each run and each reddening exactly its listed legs.
4. Full wired battery + `PACK_VALIDATE_DEEP=1` + `ci-shard-plan.py --assert-coverage` (still **142** — C1 adds no test *file*).

**Every new guard must be able to fail — C1's mutation table.**

| Mutation (the coder builds and runs each) | Must red | Must stay green |
|---|---|---|
| Revert `marker-preserve.sh` to `b40f111` | M-20 (at-eof), M-21, M-22 (`##`-first) | M-22 (`###`-first / prose-then-`###` / prose-only) |
| Apply **only** the close-time reorder (the naive fix) | M-20, M-21, M-22 — **the load-bearing mutant**: measured 0 classification deltas and 0 disposition deltas, so a weaker suite calls it green while it changes nothing | the whole rest of the battery |
| Delete the seed-slot exception entirely | M-22 (`prose-then-###` → sidecar; `###`-first reclassified) | M-20, M-21 |
| Fix bash but **not** `trinity_markers.py` | **M-23 only** — measured: the other 68 assertions, Checks 91/19/16 and `validate-pack.py` **all stay green** while the two parsers provably disagree | everything else (that is the point) |
| Build the M-20 fixtures independently instead of by permutation | M-20 leg (a) | — |

### 5.2 C2 — the template, all four legs as one change

**Commit subject:** `fix: v11 — BD-294 the shipped trinity can be filled in as instructed and still graft`
**Scope keyword:** none (mixed: `project-template/` + `supporting-docs/` + `scripts/tests/`).

**Region 1 — `project-template/{CLAUDE,AGENTS,GEMINI}.md`, four legs, parallel edits in all three (trinity rule).**

1. **Stop shipping the `<!-- HOW TO USE THIS TEMPLATE -->` block** (user decision,
   OI-4 (a)). `CLAUDE.md:3–19`, `AGENTS.md:3–17`, `GEMINI.md:3–15`. Its guidance
   already lives at `supporting-docs/INSTALL-PROCEDURES.md:484` and `:631`.
   *Bonus, measured:* the three blocks are already asymmetric — `GEMINI.md`'s
   omits the "optional sections" sentence and says *"the Antigravity CLI
   equivalent of CLAUDE.md"* without naming `AGENTS.md`. Deleting the block
   removes a live trinity asymmetry rather than creating one.
2. **Stop shipping the banner block** (`---` / `*Copied from: …*` / *"Fill in
   placeholders and remove this block."* / `---`). It carries the second
   delete-instruction, and its removal is what makes the preamble bare.
3. **Relocate the identity under a new first H2 `## Project identity`** (user
   decision — that exact capitalization), with the two identity lines inside a
   shipped `<!-- BEGIN project-owned -->` … `<!-- END project-owned -->` pair.
4. **Wrap each of the 7 in-section placeholders in its own shipped seed pair**
   (`PLATFORM_DEFAULTS`, `PLATFORM_ARCHITECTURE`, `LANGUAGE_RULES`, `GRPC_RULES`,
   `PLATFORM_SECURITY`, `PLATFORM_TESTING`, `PLATFORM_ANTIPATTERNS` — the same
   seven tokens in all three files, verified), **and** reword the 5 `OPTIONAL:`
   comments per §3.1 **and** drop the `, or delete section` tail from the
   `GRPC_RULES` line.

Legs 1–4 land together. The design's own EEB-12 row 2 is the proof that a
partial Option B is a partial fix, and my EEB-P2 adds a second proof: relocating
the identity while leaving the delete-instruction in place leaves *both* the
silent-revert and the wrong-section-blamed failure live.

**Measured result of the transformation** (`h/build_optB.py`, every edit
anchor-asserted present-before / gone-after):

```
CLAUDE.md  preamble='# CLAUDE.md'  lines 522 -> 517  OPTIONAL reworded=5
AGENTS.md  preamble='# AGENTS.md'  lines 499 -> 496  OPTIONAL reworded=5
GEMINI.md  preamble='# GEMINI.md'  lines 556 -> 555  OPTIONAL reworded=5
```
committed in scratch as `project-template/{AGENTS,CLAUDE,GEMINI}.md | 49/51/47 +-`,
**69 insertions / 78 deletions across 3 files**.

**OI-8 discharged here, not deferred.** The three preambles become exactly
`# CLAUDE.md` / `# AGENTS.md` / `# GEMINI.md`, which is **byte-identical** to
`test-fixtures/v11-trinity-marker-prepped/{CLAUDE,AGENTS,GEMINI}.md`'s preambles
(measured). Add the assertion to the new test file: *for each of the three files,
the shipped canonical's preamble equals the reference fixture's preamble.* M-8
is **not** modified — its THEIRS-from-OURS synthesis exists on purpose.

**Region 2 — `supporting-docs/INSTALL-PROCEDURES.md` (1390 lines).**
`5-C.2` at `:479–:500` and the repeat at `:628–:656`: the "remove the how-to
block" and "remove the banner" steps become obsolete and must go (they would
otherwise instruct the removal of text that no longer ships). The placeholder
step points at the shipped seed pairs. The `:572–:582` passage already names
`docs/pack/PM-CHAT.md` as the authoring SSOT and needs only the "delete the
entire section" quotation at `:574` updated to the new comment text. ~15–25 lines.

**Region 3 — `SKILL.md` + `PRE-RECONCILE-v10-to-v11.md` (shared with C1 — this is
the serialization constraint).**
`SKILL.md`: name the shipped seed pairs as where filled values live, and the
suppress-not-delete rule (~8 lines). `PRE-RECONCILE` §(c): keep the
byte-for-byte-preamble rule and name the new destination for identity values;
§(d): add the **one new interaction** — because Option B ships a seed pair
*inside* several sections, a client who wraps such a whole section in a Shape B
pair *without replacing its body* nests the shipped pair and gets a loud
`L-6 nested BEGIN marker` failure. Loud and safe; the correct path (replace the
body) works. ~10 lines.

**Region 4 — new test file `scripts/tests/test-trinity-template-obeyable.sh`.**
This is the leg that closes the family, because it derives its input from the
shipped file rather than a hand-written fixture, so it cannot drift from what
actually ships.

- **T-1 — obey-the-template round-trip.** For each of the three tracked files:
  read the shipped canonical; mechanically apply the template's own instructions
  (substitute every `[A-Z_]{3,}` placeholder with a sentinel); feed through
  `marker_preserve_trinity "" <filled> <canonical>`; assert
  `merged-with-customization`, **every sentinel present in DEST**, and **no
  `[A-Z_]{3,}` token remaining in DEST**.
- **T-2 — optional-section round-trip, all three legs** (this is where my
  EEB-P2 correction lands): (a) a same-name Shape B override → clean **and** the
  pack body absent from DEST; (b) a heading+body deletion leaving the comment →
  must **not** be a clean disposition that silently restores the section;
  (c) **a deletion that also removes the `OPTIONAL:` comment → must not
  sidecar blaming the preceding section.** Leg (c) is the one the design did not
  cover and is the worse of the two failure modes.
- **T-3-preamble** — the OI-8 assertion above.

**Verification that proves C2** (all measured on the committed scratch overlay):
```
test-marker-preserve-bd136.sh            68 passed 0 failed
test-install-trinity-fold-gate.sh        19 passed 0 failed
test-resolve-merge-conflicts-skill.sh    22 passed 0 failed
test-validate-pack-check-91/19/16.sh     All tests passed
test-migrate-v10-to-v11-pre-reconcile.sh 13 passed 0 failed
validate-pack.py                         rc=0  PASSED — all checks clean
PACK_VALIDATE_DEEP=1 validate-pack.py    rc=0  PASSED — all checks clean
```
plus the client scenarios of EEB-P8 (§6). `ci-shard-plan.py --assert-coverage`
goes **142 → 143** (one new test file).

**C2's mutation table.**

| Mutation | Must red | Must stay green |
|---|---|---|
| Revert the three templates to `b40f111` | T-1 (all three files) | the rest of the battery — measured: the *entire* unmodified battery passes on both the broken and the fixed template, which is precisely why T-1 must exist |
| Relocate the identity but keep the how-to/banner blocks | T-1 (the delete step diverges the preamble) | T-2 |
| Relocate the identity but leave `delete the entire section` in the comments | T-2 (a) and (b) | T-1 |
| Delete a section including its `OPTIONAL:` comment | T-2 (c) | T-1, T-2 (a) |
| Change the shipped preamble to anything but `# <NAME>.md` | T-3-preamble | T-1 |

### 5.3 C3 — Check 98, the standing guard

**Commit subject:** `fix: v11 — BD-294 shipped client-editable trinity content must be marker-backed (Check 98) (pack-only)`
**Scope keyword:** `pack-only`. Verified against the file set: `scripts/lib/…`,
`scripts/validate-pack.py`, `scripts/lib/validate_checks/core.py`, `README.md`,
`scripts/ci-shard-weights.tsv`, `scripts/tests/…` — nothing under
`project-template/` or `supporting-docs/`. Check 36 will verify the claim.

**The number is 98**, from the pack's own ledger: `core.py:207–214` ends
*"(Next free numeric ID = 98.)"*, and `README.md` records *"Checks 95–96 reserved
for BD-289, unlanded"*.

**Guard design (`ci-guard-measure-then-bound`, measured before it was bounded).**
Body in `scripts/lib/validate_checks/trinity_markers.py` (the trinity module, per
the pack's own-module-per-isolated-check convention recorded at
`validate-pack.py:535–543`).

- **Candidate set:** `git ls-files project-template/{CLAUDE,AGENTS,GEMINI}.md` —
  **git-tracked, never a filesystem walk**. `git` absent / not a work tree ⇒
  SKIP-lenient, matching `_candidate_files`' existing pattern at `:273–:304`.
- **Cost:** one pass over 3 files, ~1600 lines. No subprocess per entry, no walk,
  no rglob. Satisfies `ci-check-runtime-compounding`.
- **Two legs:** FAIL on any line matching `\[[A-Z][A-Z_]{2,}` **outside** a
  project-owned marker pair (marker depth tracked in the same pass); FAIL on any
  line matching the remove/delete instruction vocabulary.
- **Allowlist: `_CHECK_98_ALLOWLIST = ()` — EMPTY**, sized exactly to the
  measured KEEP set of **0 of 54** occurrences, with a fixed `len(...) == 0`
  assertion in the test so growth is itself a failure.
- **Registration:** one registry tuple `(98, "check_trinity_editable_marker_backed", …)`
  in `_build_check_registry()`, **registered once for `project-template` only**
  (see OI-D).

> **ENCODING SURFACE THE DESIGN DID NOT NAME.** `trinity_markers.py` ends with
> `__all__ = ["check_trinity_marker_wellformed"]`, and `validate-pack.py:543`
> imports it with `from validate_checks.trinity_markers import *`. **A new check
> function that is not added to `__all__` will not exist at the registry site**,
> and the failure surfaces as a `NameError` inside `_build_check_registry()`.

**Lockstep surfaces for a new check (measured from Check 97's own commit `1df7ade`, which is the template to copy):**

| Surface | Change |
|---|---|
| `scripts/lib/validate_checks/trinity_markers.py` | check body + `__all__` entry + module docstring |
| `scripts/validate-pack.py` | registry tuple in `_build_check_registry()` |
| `scripts/lib/validate_checks/core.py:207–214` | new ledger comment paragraph; `CHECK_REGISTRY_EXPECTED_COUNT` **92 → 93**; advance to *"(Next free numeric ID = 99.)"* — Check 59 asserts count == len(registry) |
| `README.md:83` (v11.0 version-table row) | `92 invoked checks` → `93`; add `98` to the numbered range; **keep "Checks 95–96 reserved for BD-289, unlanded" verbatim** |
| `README.md:204` (Repository Layout) | the same two edits |
| `scripts/ci-shard-weights.tsv` | a weight row for `scripts/tests/test-validate-pack-check-98.sh` (Check 97's commit added `2.0` for its per-check test) |
| **new** `scripts/tests/test-validate-pack-check-98.sh` | the per-check test |
| `.github/workflows/validate-pack.yml` | **no change** — the wired set is DISK-derived (`ci-shard-plan.py parse_wired_tests()`); measured, adding test files moved the count without touching the yml |

**Check 98's mutation table — measured, not asserted.**

> **EEB-P9 — the guard bites on all three legs and is provably empty-allowlisted.**
> Command: `python3 h/check98.py`, 2026-09-07.
> Output:
> ```
> MUST-FAIL control: HEAD tree (b40f111)         FAIL  files=3 findings=54
>                    {'unbacked-placeholder': 30, 'unhonourable-instruction': 24}
> MUST-PASS control: Option B tree               PASS  files=3 findings=0
> MUTANT: seed pair stripped, placeholder kept   FAIL  files=3 findings=1
>                    {'unbacked-placeholder': 1}
> ALLOWLIST assertion                            len(_CHECK_98_ALLOWLIST)=0 (must be 0)
> BITE-RESULT: PASS -> the guard can fail, and does, on all three legs
> ```
> The MUTANT leg is the **absence-of-backing** case the rule demands: the
> enclosing `<!-- BEGIN/END project-owned -->` pair around `[PLATFORM_DEFAULTS …]`
> was removed while the placeholder stayed (anchor asserted present-before /
> gone-after). The guard catches it — it is not merely checking that pairs exist
> somewhere in the file.
> Interpretation: nine guards on the sibling entry shipped structurally unable to
> fail; this one is proven able to fail before it is written. Note also the exact
> reconciliation with the design's EEB-9: **54 = 30 + 24**, the same numbers.
> **SUPPORTED.**

**Verification that proves C3:** the three legs above run as the per-check test;
plus `validate-pack.py` rc=0, `PACK_VALIDATE_DEEP=1` rc=0, and
`ci-shard-plan.py --assert-coverage` reporting **144** (measured: adding exactly
these two new test files across C2+C3 moved 142 → 144).

### 5.4 C4 — the remediation recipe (a BD-294 acceptance criterion)

**Commit subject:** `fix: v11 — BD-294 one-time in-place trinity remediation for already-migrated clients (project-only)`
**Scope keyword:** `project-only`. The commit touches
`supporting-docs/MIGRATION-v10-to-v11.md` and nothing else.

**Where it lives.** `supporting-docs/MIGRATION-v10-to-v11.md` (**1127** lines at
`b40f111` — the design said 1098), per BD-294's own `File/Symbol` line.
`supporting-docs/` is a client/public surface, so the recipe is a shipped client
deliverable. **No pack-side mechanism is imported into it** — no `pack-ops/`
path, no Pack Chat, no `pack-*` agent name, no `maintenance-docs/` reference
(`P-missed-7`, `dependency-direction-placement`).

**What it instructs — four steps, each mechanically checkable by the client.**

1. **Harvest.** From your live `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, copy out
   the values you filled in: the project identity line pair, and the seven
   section values that replaced `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`,
   `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`,
   `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`.
2. **Adopt.** Copy the new pack canonical over each of the three files.
3. **Paste back.** Put each harvested value **inside the shipped marker pair**
   that now sits where the placeholder was — the identity under
   `## Project identity`, each section value inside its own pair.
4. **For any optional section you previously deleted**, do not re-delete it:
   wrap its heading and a one-line note in a same-name project-owned pair, per
   `docs/pack/PM-CHAT.md` § "How to add project-owned content to trinity files".
5. **Verify.** Run the `resolve-merge-conflicts` Case-3 gate and require
   `merged-with-customization`. Anything else means a value landed outside a
   pair.

**How the plan PROVES it** — on a scratch clone of an already-migrated tree, with
no re-migration and no loss:

> **EEB-P8 — Option B client scenarios and the remediation, end to end.**
> Command: `python3 h/run5.py`, engine = `eng-optB` (committed scratch overlay: D5 fix + Option B template), THEIRS = the Option-B canonical, Regime B (`BASE=""`), 2026-09-07. Controls `unchanged-pack` / `customization-detected-needs-reconciliation` / `merged-with-customization` → `CONTROL-RESULT: PASS -> VALID`.
> Output:
> ```
> B-compliant-filled              merged-with-customization
>     'Acme Ledger' in DEST: 1 | FILLED-* in DEST: 7 | residual placeholders: 0
> B-compliant-nogrpc              merged-with-customization
>     suppression STICKS (pack body absent): True | client note present: True
> B-already-migrated-today        customization-detected-needs-reconciliation
>     'Acme Ledger' in DEST: 0 | FILLED-* in DEST: 0 | residual placeholders: 10
>     residual sample: ['[PROJECT_NAME]', '[PLATFORM_TARGETS]', '[TRANSPORT]']
>     live file still carries the client identity: False
> B-already-migrated-remediated   merged-with-customization
>     'Acme Ledger' in DEST: 1 | FILLED-* in DEST: 7 | residual placeholders: 0
>     no loss: all 7 in-section values + identity present in the remediated file: True
> B-remediated-idem               merged-with-customization  (idempotent: True)
> ```
> The remediation was executed **mechanically** (harvest → adopt → paste), and
> the harvest step asserts each of the 8 values is recoverable before it
> proceeds — a value it cannot find is a hard failure, not a silent drop.
> Interpretation: an already-migrated client reaches a clean, idempotent graft
> in place, with every filled-in value preserved and **zero** residual
> placeholders. Row 3 is the harm being repaired: without the recipe the live
> context file loses the identity entirely and reverts to 10 placeholders.
> **SUPPORTED.** This discharges BD-294's remediation acceptance criterion.

**Verification that proves C4:** re-run the above against the committed C2 tree;
`validate-pack.py` + DEEP green (a docs-only commit cannot move a check, but the
gate still runs). No new test file, so `--assert-coverage` stays at 144.

### 5.5 C5 — the design record lands in the repo

**Commit subject:** `docs: v11 — BD-294 architecture + plan records (pack-only)`
**Scope keyword:** `pack-only`.

The design currently exists only in a handoff dir. The repo keeps these under
`maintenance-docs/v11-implementation/` — verified: 45 files, naming
`ARCHITECTURE-BD-NNN.md` (e.g. `ARCHITECTURE-BD-119.md`, `ARCHITECTURE-BD-182.md`,
`ARCHITECTURE-BD-204.md`).

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-294.md`
- `maintenance-docs/v11-implementation/PLAN-BD-294.md`

**One required edit on the way in.** `ARCHITECTURE-BD-294.md` carries five
statements this plan measured as stale or imprecise at `b40f111`. A maintenance
doc is a reference doc, so its history is fine — but a *wrong* state-claim is
not. Add a short **"Reconciled at `b40f111` (BD-294 planning)"** addendum to the
architecture doc recording: (1) OI-5 is resolved by BD-293's R1 ledger seeding,
so EEB-11's "standing cost" no longer holds; (2) EEB-16 missed the BD-289
collision on five check-wiring paths; (3) leg (d) has a third outcome; (4) OI-3's
measurement selects the pointer, not the recipe; (5) `MIGRATION-v10-to-v11.md` is
1127 lines and `MERGE-STRATEGY.md` 689. This is the
`architect-doc-reality-reconciliation` chain: the addendum cross-references the
realized consumers by file + symbol, never by line number.

These are **reference** docs, not operating docs, so
`operating-docs-no-history-no-bloat` does not bind them — and correspondingly,
none of the prose these commits add to `SKILL.md`, `PRE-RECONCILE`,
`INSTALL-PROCEDURES`, `MERGE-STRATEGY` or the trinity carries a date, a
`per BD-NNN`, a SHA, or a mention of anything deferred.

### 5.6 C6 — close the entry

`backlog/BD-294.md` `Status: Open → Resolved` + a filled `Resolved:` line;
regenerate `backlog/_toc.md`; advance `pack-ops/session-state.json` to the new
frontier. Pack-Chat-direct (`pack-chat-only`), per the implicit-status-flip rule
once the batch's review and fixes are clean.

**The entry resolves in place — there is no Resolved section to move it to.**

### 5.7 Manifest

`test-fixtures/build.sh:280` loops over `CLAUDE.md AGENTS.md GEMINI.md`, so the
built v11 fixtures embed the trinity and **C2 will change fixture SHAs**.
`test-fixtures/manifest.txt` is **not** a per-commit chore: it regenerates at
**push**, by `scripts/manifest-sync.sh`, run by the orchestrator, and correctness
is enforced by CI `build.sh --verify` + Check 62.

**C1 has no manifest impact — measured.** `test-fixtures/manifest.txt` tracks
exactly seven BUILT fixtures (`v10-minimal`, `v10-realistic-ot`,
`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`,
`existing-project-mid-dev`, `existing-project-collision`).
`v11-trinity-marker-prepped` is **not among them** and does not appear in
`build.sh` at all — it is a committed static fixture directory, so C1's edit to
its `README.md` changes no fixture SHA.

---

## 6. Acceptance-criteria closure

Every BD-294 acceptance criterion, mapped to the commit that satisfies it and the
evidence that proves it.

| BD-294 acceptance criterion (quoted) | Where | Proof |
|---|---|---|
| *"the D3 direction is chosen by the user from architect-measured options, each option's blast radius on EXISTING installs measured before the choice"* | pre-C2 (done) | Option B chosen; blast radius on existing installs measured in EEB-P8 rows 3–5 and re-measured against the corrected base rate in EEB-P7 |
| *"after the fix, a client that follows the trinity's own instruction grafts cleanly — proven by round-tripping the filled-in shape through the engine and observing a clean verdict, not by inspection"* | C2 | EEB-P8 row 1: `B-compliant-filled → merged-with-customization`, 8/8 values in DEST, **0** residual placeholders. Locked in by T-1, which round-trips the **shipped** file. |
| *"the in-section placeholder bodies are covered by the same resolution or explicitly scoped out with evidence"* | C2 | **Covered, not scoped out.** All 7 per file get their own shipped seed pair; EEB-P8 shows `FILLED-* in DEST: 7`. |
| *"D5 is resolved in the direction the measurement dictates (engine fix if the position dependency is real, doc fix if the contract is wrong)"* | C1 | The dependency is real and is a code defect: EEB-P3 shows two fixtures identical up to line ORDER producing different dispositions. Engine fix. |
| *"with a regression test that BITES on the reported reproduction"* | C1 | M-20/M-21 are built from the client's reported shape (`renamed-from "## iOS 26 / Xcode 26.3 platform features"` → `## Xcode 26.4 platform features`, appended at EOF). Mutation table proves each mutant reds, including the no-op naive fix. |
| *"a one-time in-place remediation recipe ships and is PROVEN on a scratch clone of an already-migrated client tree — the trinity reaches the resolved shape with no re-migration and no loss of the client's filled-in content"* | C4 | EEB-P8 rows 4–5: clean, idempotent, all 8 values present, 0 residual. Executed mechanically on a scratch clone; no re-migration invoked. |
| *"full CI battery green"* | every commit | 68/19/22/13 + Checks 91/19/16 + `validate-pack.py` + `PACK_VALIDATE_DEEP=1` + `--assert-coverage`, measured on the committed scratch overlays |

**Nothing in BD-294's scope is left undone, and no new BD is created.** The one
item the design routed elsewhere (OI-5) is **not deferred** — it was re-measured
and found already fixed by an entry that landed in this same version (§3.2).

---

## 7. Risk register

| # | Risk | Commit | Cheapest signal that catches it |
|---|---|---|---|
| R1 | The coder ships the **naive close-time reorder** alone, sees 68/19/22/13 + `validate-pack.py` green, and believes the defect fixed. **Measured: it changes literally nothing** (0 classification deltas, 0 disposition deltas). | C1 | M-22's `##`-first leg asserted **via `_mp_regions`**, plus the mandated naive-fix mutant run. A disposition-only assertion does not catch it. |
| R2 | An **apostrophe** in a comment added to `_mp_regions` silently terminates the single-quoted awk string. I hit this exactly. | C1 | `bash -n scripts/lib/marker-preserve.sh` as the first verification step; and the must-pass control returning empty rather than a verdict. |
| R3 | The bash engine is fixed but **`trinity_markers.py` is not**. **Measured: the entire battery stays green** while the two parsers provably disagree on 3 of 6 fixtures. | C1 | M-23 (classification parity) is the **only** leg that catches it. Nothing else does. |
| R4 | The OI-1 test leg asserts the **disposition** and reports the correct tightening as a failure. Measured: `oi1-addenda-notes` stays `SIDECAR` after the fix, for a correct unrelated reason. | C1 | Pin M-22b's assertion to `_mp_regions` output; a reviewer checking "does the test assert shape or verdict?" catches it in one read. |
| R5 | Check 98 lands **before** C2 and reds the boundary with **54 findings**. | C3 | The ordering constraint is measured, not stylistic. `python3 scripts/validate-pack.py --only 98` on the pre-C2 tree returns FAIL — run it once to confirm the ordering before committing. |
| R6 | The new check function is added to `trinity_markers.py` but **not to `__all__`**, so the star-import at `validate-pack.py:543` never exports it and `_build_check_registry()` raises `NameError`. | C3 | `python3 scripts/validate-pack.py` fails immediately at registry build — loud, first run. |
| R7 | Check 98 takes number **95 or 96**, silently stealing BD-289's reserved slots; or the README's *"95–96 reserved for BD-289"* sentence is dropped in the count edit. | C3 | `grep -n 'reserved for BD-289' README.md` must still return **2** hits after the edit; `core.py`'s ledger must read *"Next free numeric ID = 99"*. |
| R8 | `CHECK_REGISTRY_EXPECTED_COUNT` is bumped but a README claim site is missed (there are **two**: `README.md:83` and `:204`). | C3 | Check 59 catches the count/registry mismatch; the README twin is caught by `grep -c '93 invoked checks' README.md` == 2. |
| R9 | A partial Option B — identity relocated, `delete the entire section` left in place. Measured to still yield a silent revert **and** a wrong-section sidecar. | C2 | T-2 legs (a)+(b)+(c). Also a one-line grep gate: `"delete the entire section"` must occur **0** times across the three files. |
| R10 | The `OPTIONAL:` comment is moved or deleted along with a section, diverging the **preceding** section. This is the third leg-(d) outcome, undocumented before this plan. | C2 | T-2 leg (c). Without it the worse of the two failure modes ships uncaught. |
| R11 | The three trinity files drift — an edit lands in `CLAUDE.md` but not `AGENTS.md`/`GEMINI.md`. All four legs are 3× edits. | C2 | `check_trinity_h2_parity` (registered twice) fires on an H2 asymmetry; for body-level drift, the builder's per-file assertions (`OPTIONAL reworded=5`, `delete the entire section` absent, preamble == `# <NAME>.md`) must pass for all three. |
| R12 | The M-20/M-21 fixture pairs are built independently and differ by more than placement, so the test proves nothing. I hit this: `GROUP-IDENTICAL: False`. | C1 | Build the EOF variant by **moving** the block (a permutation), and keep the multiset assertion as a hard gate. |
| R13 | C4's prose collides with a BD-293 commit in `supporting-docs/MIGRATION-v10-to-v11.md`. | C4 | Serialize the two commits; `git diff --name-only` on the in-flight BD-293 commit before scheduling C4's wave. |
| R14 | `manifest.txt` regenerated per-commit, against the standing rule. | C2 | It regenerates at **push** via `scripts/manifest-sync.sh`; CI `build.sh --verify` + Check 62 are the correctness gate. Do not touch it in C1–C6. |
| R15 | A doc edit smuggles history/provenance narration into an operating doc (`SKILL.md`, `PRE-RECONCILE`, `INSTALL-PROCEDURES`, `MERGE-STRATEGY`, the trinity). | C1, C2 | `grep -nE 'per BD-[0-9]|carried from|User-locked|[0-9]{4}-[0-9]{2}-[0-9]{2}'` over the changed doc hunks must be empty. |
| R16 | The reworded `OPTIONAL:` comment and Check 98's instruction vocabulary drift apart, so the guard stops matching what ships. | C3 | Check 98's vocabulary is a module-level constant with the test asserting it matches **0** lines in the shipped files and **>0** in a `b40f111`-shaped fixture. |

---

## 8. Open items

Each carries context, **my own** options, and an evidence- or logic-based
recommendation. None defers work to a later BD, a later version, or a new entry.

**OI-A — C1 and C2 share two documentation files, which forces a serial chain
where the mechanisms are independent.**
*Context.* The two fixes touch disjoint code (§5.2 measured: D5 is
`_mp_regions`; D3 as recommended touches no engine code at all), so they could
run as parallel worktree waves. They cannot, because both must edit
`project-template/skills/resolve-merge-conflicts/SKILL.md` and
`supporting-docs/PRE-RECONCILE-v10-to-v11.md`.
*My options.* (a) Serialize C1 → C2 as planned. (b) Split the doc edits into a
third commit that lands after both, running C1 and C2 in parallel worktrees.
(c) Give C1 the `SKILL.md`/`PRE-RECONCILE` edits and let C2 append to them
serially anyway (this is (a) with extra words).
*Recommendation.* **(a).** (b) buys parallelism for two commits at the cost of a
window in which the engine's behaviour and the docs that describe it disagree —
which is the exact `enumerate-encoding-surfaces` asymmetry the pack forbids, and
the chain is only four commits deep. The parallelism that is actually available
(C5, and any BD-293 wave that avoids `MIGRATION-v10-to-v11.md`) is already in
the map.

**OI-B — my OI-3 measurement contradicts the architect's recommendation, so the
exact sentence needs the user's sign-off before C2.**
*Context.* The architect recommended a self-contained recipe (option a). Applying
**the user's own rule** to the measurement (EEB-P5: the action is performed once
per project, at setup, and a whole major version added zero new occasions)
selects the **pointer** (option b). The pointer target is verified to exist,
ship on all three axes, and already be the pack's own emitted convention for
this concept (EEB-P6).
*My options.* (a) The pointer, as drafted in §3.1 — *"suppress it — do not
delete it; see `docs/pack/PM-CHAT.md` § …"*. (b) The architect's inline recipe.
(c) A hybrid: name the shape in one clause **and** point (this is what my draft
sentence actually is — *"suppress it"* is the shape, the rest is the pointer).
*Recommendation.* **(a), which as drafted is (c).** The measurement is
unambiguous on frequency, and the pointer target is a project-side SSOT already
cited by `INSTALL-PROCEDURES.md:582` — so this is not a document hop the client
must discover, it is the hop the install procedure already sends them on.
Evidence against (b): a self-contained recipe duplicates `PM-CHAT.md`'s Shape
A/B procedure in 15 places across 3 files, creating 15 copies that drift from
their SSOT — the failure mode `memory-not-an-ssot` generalizes.
**This is a wording decision on client-facing prose; it is the user's to
approve, and it is the one gate before C2 can start.**

**OI-C — the `OPTIONAL:` comment sits above the heading it describes, so
"the entire section" is ambiguous in a way that damages a neighbour.**
*Context.* New in this plan (EEB-P2). Deleting heading+body → silent revert;
deleting comment+heading+body → sidecar blaming the **previous** section. Option
B's reword stops clients being *told* to delete, but the ambiguity remains for
anyone who deletes anyway.
*My options.* (a) Reword only, and cover both deletion shapes in T-2 (the plan as
written). (b) Additionally **move each `OPTIONAL:` comment below its heading**,
so it is lexically inside the section it describes and a whole-section deletion
can no longer touch a neighbour. (c) Additionally ship each optional section
already wrapped in a Shape B pair, so suppression is an edit-in-place.
*Recommendation.* **(a) for BD-294, with (b) surfaced now as a cheap, measurable
follow-on inside the same commit if the user wants it.** Evidence for (a): the
reword removes the *instruction*, which is the shipped defect; T-2 leg (c)
converts the residual ambiguity into a covered, asserted behaviour. Evidence
against (c): it would put five more shipped marker pairs into every trinity file
and multiply the nested-pair interaction EEB-15 identified — a real cost for a
case the reword already addresses. Evidence on (b): it is a 15-line mechanical
move with the same anchor discipline as the reword, and it would make R10
structurally impossible rather than merely tested; I did not measure its effect
on the engine, so I cannot recommend it without that measurement, and measuring
it is ~20 minutes of the coder's C2 work if the user wants it in.

**OI-D — Check 98 registration: once (project-template) or twice
(project-template + pack-root)?**
*Context.* Checks 16/18/19 each register twice — once per trinity location.
Check 91 registers once, for `project-template`. Measured:
`grep -nE '\[[A-Z][A-Z_]{2,}|delete the entire section|Remove this comment block|Fill in placeholders and remove' CLAUDE.md AGENTS.md GEMINI.md`
at the pack root returns **no output** — the pack-root trinity carries zero
placeholders and zero delete-instructions, so a second registration would pass
today either way.
*My options.* (a) Register once, for `project-template`. (b) Register twice, as
cheap insurance against a future paste into the pack-root trinity.
*Recommendation.* **(a).** The pack's own trinity text states the principle:
*"pack-root trinity vs project-template trinity carry different audiences and
different rules by design"*. The placeholder contract is a **project-template**
contract — the pack-root trinity is not a template, nobody fills it in, and no
graft engine consumes it. Registering it there would assert a contract that
does not exist on that surface, which is the `P-missed-7` boundary error in
miniature. (b)'s insurance is worth little: a placeholder pasted into the
pack-root trinity is not a client-facing defect.

**OI-E — the `--update` attribution item (design OI-5) should be dropped, not
carried.**
*Context.* §3.2. The design's premise was measured true at `9171243` and is
false at `b40f111`; BD-293 landed the four-rung cascade and seeded the R1
ledger on both the fresh-install and the migration paths.
*My options.* (a) Drop it; record the finding in the architecture-doc addendum
(C5) so the next reader is not misled. (b) Keep a note in BD-294. (c) Add work
to BD-293.
*Recommendation.* **(a).** (c) is excluded — there is no residual defect to fix,
only a documented, warned-about degradation of a shipped cascade for a client
with no ledger on any of three paths. (b) would put a stale claim into a live
entry. The finding belongs in the reconciliation addendum, which is exactly what
`architect-doc-reality-reconciliation` prescribes.

**OI-F — the design's collision scan scored BD-289 as `none`; it collides on five
paths.**
*Context.* §2. The scan's blast-radius set omitted every surface its own T-3
recommendation must edit.
*My options.* (a) Absorb the correction into this plan (done: §2 + R7 + R8 +
§5.3's lockstep table) and record it in the C5 addendum. (b) Re-run a full
independent collision pass before C3. (c) Treat it as a gate on BD-294.
*Recommendation.* **(a).** It is a COORDINATE signal, not a gate: BD-289 targets
**v11.1** and lands after BD-294, so the only obligations are forward-directional
and mechanical — take 98, bump 92→93, advance the ledger to 99, preserve the
"95–96 reserved" sentence in both README sites. All four are in the plan and all
four have a cheap grep signal in the risk register. (c) would block a
launch-gating v11.0 entry on a v11.1 entry, which inverts the dependency.

**OI-G — the commit-subject scope keywords for C1 and C2 are necessarily absent,
and that is worth stating so it is not read as an oversight.**
*Context.* C1 spans `scripts/` + `pack-ops/` + `project-template/` +
`supporting-docs/`; C2 spans `project-template/` + `supporting-docs/` +
`scripts/tests/`. Neither `pack-only` nor `project-only` is truthful for either.
*My options.* (a) No keyword on C1 and C2 (Check 36 skips, no claim to verify).
(b) Split each into a pack-side and a project-side commit to earn keywords.
*Recommendation.* **(a).** The pack's own rule says so in as many words: *"Use no
keyword for mixed-surface commits."* (b) would split a behaviour change from the
docs and tests that encode it, breaking `enumerate-encoding-surfaces` to win a
label. C3, C4 and C5 do carry keywords, and each is verified against its actual
file set above.

**OI-H — no recommendation can be given: whether C2 should also delete the
`*Copied from: project-template/<NAME>.md — AI Agent Config Pack v11*`
provenance line, independently of the delete-instruction it sits beside.**
*Context.* The banner block is four lines: two `---` rules, a provenance line,
and the *"Fill in placeholders and remove this block"* instruction. Only the
instruction is a defect. Deleting the whole block is what produces the bare
preamble that makes the shipped canonical byte-identical to the reference fixture
(OI-8), which is why the plan deletes all four lines. But that also drops a
provenance marker that a client or a support conversation may rely on to
identify which pack version a file came from.
*What I measured.* Nothing in the pack requires the line: `validate-pack.py`,
`PACK_VALIDATE_DEEP=1` and the full battery are green on the Option-B tree with
it gone (EEB-P8's tree). I did **not** find, and did not look for, evidence about
whether any human process or external tooling reads it.
*Options.* (a) Delete the whole block (the plan as written; gives the bare
preamble and the OI-8 equality). (b) Keep the provenance line, delete only the
instruction — the preamble is then no longer bare and the OI-8 equality does not
resolve on its own, so OI-8 would need its own change. (c) Move the provenance
line inside the `## Project identity` seed pair — but then it becomes client-owned
and the pack can never update it.
*Recommendation.* **None can be given from the evidence I have.** The technical
consequences of each are measured and (a) is clean; but the question is whether
anyone *uses* the provenance line, and that is knowledge about the maintainer's
and clients' practice that I have no way to measure. If the user confirms nobody
reads it, (a) stands with no further work. If it is read, (b) is the safe
choice and OI-8 then needs an explicit assertion change instead of resolving as
a side effect.

---

## 9. Empirical-Evidence Block index

All nine blocks are inline above, each carrying the command, the captured output
(quoted, not paraphrased), the HEAD `b40f111` and date 2026-09-07, the
interpretation, and a verdict.

| Block | Claim | Verdict |
|---|---|---|
| EEB-P1 (§1) | The D3/D5 code + template surfaces are byte-untouched since the design; drift is confined to doc and CI-wiring surfaces | SUPPORTED |
| EEB-P2 (§1.2) | Leg (d) has a **third** outcome: deleting the `OPTIONAL:` comment with the section sidecars, blaming the preceding section | SUPPORTED |
| EEB-P3 (§1.2) | Within the four seed shapes exactly one classification moves; the naive reorder moves nothing (0 deltas across 9 fixtures, 3 engines) | SUPPORTED |
| EEB-P4 (§2) | The corrected collision scan finds **two** collisions (BD-289 on 5 check-wiring paths, BD-293 on the migration guide), not one | SUPPORTED |
| EEB-P5 (§3.1) | Suppressing an optional trinity section is a one-time setup act; v10→v11 added zero new optional sections (5 → 5) | SUPPORTED |
| EEB-P6 (§3.1) | The pointer target exists, carries the procedure, ships on all three axes, and is already the installer's own emitted convention | SUPPORTED |
| EEB-P7 (§3.2) | `cmd_update` now resolves a real BASE via a four-rung cascade seeded on both entry paths | **NOT-SUPPORTED** (the design's "standing cost on every release" claim) |
| EEB-P8 (§5.4) | Option B client scenarios + the remediation recipe: clean, idempotent, 8/8 values preserved, 0 residual placeholders | SUPPORTED |
| EEB-P9 (§5.3) | Check 98 bites on all three legs (54 findings at HEAD, 0 on the fixed tree, 1 on the absence-of-backing mutant) and is provably empty-allowlisted | SUPPORTED |

Additional measurements quoted inline without their own block, each with the
command and output shown at the point of use: the `142 → 144` shard-count delta;
the `CHECK_REGISTRY_EXPECTED_COUNT = 92` / *"Next free numeric ID = 98"* ledger;
the two README count sites; the baseline battery (`68/19/22/13`,
`validate-pack.py` rc=0) on the pristine clone; the same battery plus
`PACK_VALIDATE_DEEP=1` on the Option-B tree; the `__all__` export surface; the
seven manifest-tracked fixtures; the pack-root trinity placeholder census
(empty).

**Harness validity (traps #1–#8).**

| Trap | How it was handled |
|---|---|
| **#1** linked worktree `.git` is a pointer FILE | Verified live: my worktree's `.git` is a **101-byte** file. The scratch clone was made with `git clone --no-hardlinks` and its `.git` re-verified: `ls -ld` → `drwxr-xr-x`, `file` → `directory`. No `cp -R` of a linked worktree. |
| **#2** `git clone` carries committed state only | Both candidate overlays were **committed inside their own scratch clone** before measurement, and the landing proven: `eng-d5` → `edc0ff0`, `scripts/lib/marker-preserve.sh \| 18 ++++-, 14 insertions 4 deletions`; `eng-optB` → `project-template/{AGENTS,CLAUDE,GEMINI}.md`, `69 insertions 78 deletions`. The `v10` tag was confirmed to resolve in the clone (`git -C … tag` lists `v10`, `v10.0`, `v10.1`) before any v10-dependent read. |
| **#3** a mutation can silently fail to apply | No sed, no Perl. Every mutation is a Python `str.replace` wrapped in assertions that the anchor occurs **exactly once before**, is **absent after** (or, for a wrap, that the wrapped form is present the expected number of times), and that the replacement **is present after**. Each printed `anchor present-before=1 OK / gone-after OK`. Two real misses were caught this way: the `s2-mid-file` self-containing anchor, and the wrap-vs-replace guard inversion. |
| **#4** measuring in the wrong regime | Every disposition is labelled with its BASE regime. Regime B (`BASE=""`) is used for every gate claim; the OI-5 comparison reports Regime A and Regime B **side by side** and never substitutes one for the other. |
| **#5** a scanner that classifies nothing reports clean zeros | Every run carries three controls — `CTRL-identical` → `unchanged-pack`, `CTRL-mustfail-outofmarker` → `customization-detected-needs-reconciliation`, `CTRL-mustpass-seed` → `merged-with-customization` — and prints `CONTROL-RESULT`. The census scanner carries its own self-check (non-empty buckets, a must-match probe, a must-not-match probe). **The controls fired for real:** a broken engine patch returned three empty verdicts and the run was declared VOID rather than reported. |
| **#6** zsh quoting | Every variable expansion in a path context is written `"${VAR}/path"`. One unquoted `--include=*.py` glob failed loudly (`no matches found`) and was requoted before the result was used. |
| **#7** a presence check against a committed tree is blind to gitignored paths | The one presence question that mattered — the knowledge graph — was answered against the **injected absolute path**, not derived from my own toplevel. Check 98's candidate set is deliberately `git ls-files`, and that is a design requirement, not a measurement blind spot. |
| **#8** the harness scratchpad is a SHARED root | Every scratch artefact lives under `mktemp -d` **inside my owned dir**: `/Users/david/.local/state/optiquity-pack-handoff/bd294-planner-20260907T070000Z/scratch.r8C7JW/`. Nothing was written to `/private/tmp/.../scratchpad`, and nothing outside my own scratch was deleted. |

---

## 10. Rules-Applied Verification Block

| Rule | Verification evidence (quoted, not summarised) | Conclusion |
|---|---|---|
| `agents-never-commit` | Zero state-changing git verbs against any pack tree. Every git call against the pack or my worktree was read-only: `git log`, `git diff --stat`, `git rev-parse`, `git status --porcelain`, `git show v10:project-template/CLAUDE.md`, `git tag`, `git ls-files`. The two `git add`/`git commit` pairs ran **inside throwaway scratch clones** (`…/scratch.r8C7JW/eng-d5`, `…/eng-optB`), which the task brief explicitly permits (*"git inside your own scratch clone is fine"*), producing `edc0ff0` and the Option-B commit — no branch, tag, ref, index or working tree of the pack was touched. `git status --porcelain` in my worktree at start: empty. | COMPLIANT |
| `per-action-approval-sub-agents` | Every write landed under my owned dir: the plan at `/Users/david/.local/state/optiquity-pack-handoff/bd294-planner-20260907T070000Z/PLAN-BD-294.md` and harness/scratch files under `…/bd294-planner-20260907T070000Z/scratch.r8C7JW/`. The only deletions were `rm -f` of two stub test files I had myself created inside `…/scratch.r8C7JW/eng-optB/scripts/tests/`, and `shutil.rmtree` of `eng-*`/`mut98` directories I created, all inside my own scratch. **Nothing outside my owned dir was created, modified, or deleted**; the architect handoff dir's three input files are untouched. | COMPLIANT |
| `empirical-evidence-blocks` | Nine numbered blocks (EEB-P1…EEB-P9), each with the exact command, captured output, HEAD `b40f111`, date 2026-09-07, interpretation, and a SUPPORTED / NOT-SUPPORTED verdict. One returns **NOT-SUPPORTED** (EEB-P7, overturning the design's OI-5 premise). The §1.1 re-verification table carries 22 rows each marked CONFIRMED / MOVED / STALE. | COMPLIANT |
| `cross-bd-collision-scan` | EEB-P4: 19 open BDs read from `backlog/_toc.md` § Open, intersected against a **corrected 22-path** blast radius keyed on structured paths, not prose. Result: `BD-289 COLLISION` on 5 paths (quoted from `backlog/BD-289.md:8`), `BD-293 COLLISION` on `supporting-docs/MIGRATION-v10-to-v11.md` plus its own three scripts, 17 × `none`. The design's `BD-289 none` is recorded as STALE rather than inherited. BD-293's `cmd_update` surface is explicitly excluded from BD-294's edit set. | COMPLIANT |
| `ci-guard-measure-then-bound` | EEB-P9 ran the guard's matching logic against the **real current tree first**: candidate set from `git ls-files project-template/{CLAUDE,AGENTS,GEMINI}.md` (3 files, **no filesystem walk**, `git`-absent ⇒ SKIP-lenient). Every occurrence categorised: `unbacked-placeholder: 30` + `unhonourable-instruction: 24` = 54 STRIP; **KEEP = 0**. Allowlist sized exactly to the KEEP set: `len(_CHECK_98_ALLOWLIST)=0 (must be 0)`. Fix-recipe = C2, which strips all 54 (`MUST-PASS control: Option B tree PASS files=3 findings=0`). The **absence-of-backing** leg is measured, not asserted: `MUTANT: seed pair stripped, placeholder kept → FAIL findings=1`. | COMPLIANT |
| `ci-check-runtime-compounding` | §5.3: *"one pass over 3 files, ~1600 lines. No subprocess per entry, no walk, no rglob."* One `git ls-files` invocation per check run, matching the module's existing `_candidate_files` pattern. | COMPLIANT |
| `enumerate-encoding-surfaces` | Each commit's lockstep set is enumerated with its anchor: C1 — both parsers, the test file, `MERGE-STRATEGY.md:200–206`, `SKILL.md:129`, `PRE-RECONCILE` §(d), the fixture README. C3 — the check body, **`__all__`** (a surface the design did not name), the registry tuple, `core.py`'s count + ledger, **both** README claim sites, the shard weights, the per-check test; and the measured non-surface (`validate-pack.yml`, disk-derived). The asymmetric case the rule warns of is closed by M-23 and by Check 98's own test. | COMPLIANT |
| `P-missed-7` (boundary investigation) | Before specifying any `project-template/` or `supporting-docs/` edit I looked for the project-side SSOT and found it: `INSTALL-PROCEDURES.md:582` names `docs/pack/PM-CHAT.md` as the Shape A/B **authoring** SSOT; `PM-CHAT.md:1256` § "How to add project-owned content to trinity files" carries it (backing verified at `:1284–:1336`); `init-project.sh:2337`/`:2633` already emit that exact pointer. The OI-3 wording therefore points at the project-side SSOT. No `pack-ops/` path, Pack Chat reference, `pack-*` agent name or `maintenance-docs/` reference is proposed for any client surface, including the C4 recipe. | COMPLIANT |
| `dependency-direction-placement` | No dual-use file is introduced. The remediation recipe lands in `supporting-docs/MIGRATION-v10-to-v11.md`, a client/public surface, per BD-294's own `File/Symbol` line. Check 98 is pack-side and reads project-side content (pack→project, the permitted direction); nothing project-side becomes a runtime dependency of a pack operation. **No addition to `_SANCTIONED_PACK_SIDE_SHIPPED` is proposed** — the allowlist is untouched and does not grow. | COMPLIANT |
| `deferral-is-scope-creep` / `no-deferral-without-user-direction` | Every item lands in v11.0 inside BD-294. **No new BD is created.** The one item the design routed elsewhere (OI-5) is not deferred: it was re-measured (EEB-P7) and found **already fixed** by BD-293 in this same version, so there is no work to defer — OI-E records that with evidence and recommends recording the finding, not scheduling work. The one item I cannot resolve (OI-H) is surfaced with an explicit "no recommendation can be given" rather than pushed to a later entry. | COMPLIANT |
| `operating-docs-no-history-no-bloat` | The prose these commits add to operating docs (`SKILL.md`, `PRE-RECONCILE`, `INSTALL-PROCEDURES`, `MERGE-STRATEGY`, the trinity, the reworded `OPTIONAL:` comments) states only what currently exists and operates — no dated note, no `per BD-NNN`, no SHA, no incident reference, no mention of anything deferred. R15 makes that a grep gate on the changed hunks. The history and the corrections live in the C5 **reference** docs, where the ban does not bind. This plan is itself a reference doc. | COMPLIANT |
| `public-bound-no-leak` | The reporting client is referred to only as "the reporting client" / "an already-migrated client". Its project name, repository path and domain vocabulary appear **nowhere** in this document — verified by grep over the finished file. All fixture values are invented and domain-neutral (`Acme Ledger`, `macOS 26 and iOS 26`, `gRPC + Proto3`, `FILLED-*`). | COMPLIANT |
| `open-item-surfacing` | §8 carries eight open items (OI-A…OI-H). Each states context, **my own** options, and an evidence- or logic-based recommendation. None recommends from memory — each cites a measurement or a quoted source line. **OI-H carries an explicit "no recommendation can be given"** with the reason (the question is about human practice, which I cannot measure). None defers or delays work to another or a new BD. | COMPLIANT |
| `memory-not-an-ssot` | Every rule and every fact is sourced from live in-repo text or my own measurement at `b40f111`, quoted at the point of use: the check-numbering ledger from `core.py:207–214`, the reserved slots from `README.md`, the scope-keyword table from `CLAUDE.md`, the BASE cascade from `init-project.sh:1709–1775`, the authoring SSOT from `INSTALL-PROCEDURES.md:582`. Nothing is cited from a remembered value, and the design doc's own claims were re-measured rather than trusted. | COMPLIANT |
| `graph-first-context` | Discovery ran graph-first at the **injected absolute path**: `graphify query "trinity template placeholder preamble marker-preserve seed slot Project addenda OPTIONAL section suppression" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --backend claude-cli --budget 1500` → `11420 nodes | 13 nodes found`. It widened recall beyond my grep set, surfacing `test-fixtures/v11-trinity-marker-prepped/README.md` (→ the C1 lockstep row), `scripts/lib/template-version.sh` (checked and **excluded** — it versions tracker entries, not the trinity), and `seed_r1_ledger()` at `init-project.sh:1626` (→ corroborating EEB-P7). Verification of each named surface was then Read/grep, per the two-phase rule. | COMPLIANT |
| Read-only agent class / single permitted write | One Write plus three Edits to the caller-specified path `/Users/david/.local/state/optiquity-pack-handoff/bd294-planner-20260907T070000Z/PLAN-BD-294.md`. **No file in `/Users/david/Developer/optiquity-ai-agent-config-pack` was created, modified, or deleted.** Harness files were written only under my own scratch dir. No patch is produced (RO). | COMPLIANT |
| Worktree isolation / injected canonical facts | Regime verified at runtime, not assumed: `pwd` → `…/.claude/worktrees/agent-af6b1a356daf9e524`; `git rev-parse HEAD` → `b40f111d84f361917aa09e93ff74c19194bbab9b` (matching the injected canonical fact); `git status --porcelain` → empty; `ls -ld .git` → **101-byte file**. All git ran in my own worktree or my own scratch clones; four cross-tree / over-complex invocations were platform-refused and were **split into plain commands rather than worked around**. | COMPLIANT |
| `verify-full-ci-suite` | Stated rather than glossed. I ran, on each candidate tree: `test-marker-preserve-bd136.sh`, `test-install-trinity-fold-gate.sh`, `test-resolve-merge-conflicts-skill.sh`, `test-validate-pack-check-91/19/16.sh`, `test-migrate-v10-to-v11-pre-reconcile.sh`, `validate-pack.py`, **`PACK_VALIDATE_DEEP=1 validate-pack.py`**, and `ci-shard-plan.py --assert-coverage` — 122 assertions plus both validator modes plus the coverage gate. I did **not** run the whole two-job workflow, `--emit-matrix` end to end, or the full fixture-dependent shard (which needs built fixtures). The plan makes the full battery a per-commit obligation on the coder; my numbers bound the risk, they do not discharge it. | PARTIAL — scope stated, residual obligation named in §5 |
| `architect-doc-reality-reconciliation` | C5 ships the reconciliation chain: the architecture doc gains a "Reconciled at `b40f111`" addendum naming the five corrected claims and cross-referencing the realized consumers **by file + symbol, never by line number**; this plan is the second link; the coder's IMPL-REPORT is the third. | COMPLIANT |
| `pack-entry-type-semantics` | No backlog or changelog entry is created, restructured, or given parts/phases/tasks by this pass. C6 flips one `Status:` field in place and regenerates `_toc.md` — the `/backlog/` tree has no Resolved section and the entry does not move. | COMPLIANT |
| `preflight-stop-means-stop` | The single-line preflight was emitted before the final write. No parent stop/halt/revert instruction was received at any point. | COMPLIANT |
