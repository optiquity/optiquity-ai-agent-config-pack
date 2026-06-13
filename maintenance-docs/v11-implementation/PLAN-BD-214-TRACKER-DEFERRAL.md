# PLAN — BD-214 Tracker-Deferral Cleanup + Track-2 ENTRY Re-scope (Track A only)

**Author:** pack-planner (fresh spawn). **Date:** 2026-06-12.
**HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747` (branch `v11-dev`) + working-tree
` M backlog/BD-214.md`, `?? ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md`,
`?? RESEARCH-TRACKER-DEFERRAL-CENSUS.md` (verified `git status --short`).
**Source design:** `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` (read in full incl. Update log,
§6.6, §7–§11, §10.5, §14a). **Census:** `RESEARCH-TRACKER-DEFERRAL-CENSUS.md` (read in full).
**Read-only except this file.** Decisions are FIXED inputs (US-1..US-9, D-A..D-J′); this plan
sequences them — it does not re-open them.

## Revision log (2026-06-13) — three user-approved gap resolutions + commit renumbering

This is a TARGETED in-place revision of the original 2026-06-12 plan applying three
FIXED user resolutions (decisions not re-opened):

- **GAP-1 — incremental Check 51.** The 5 Check-51 legs no longer all land in one
  commit. Each leg lands in the commit that makes its condition TRUE, so no commit
  asserts a not-yet-true condition. Legs 1 (clamp marker), 2 (verb gates), 4
  (entry-content grep-zero, already true) land in **C1**; leg 3 (recommendation
  removed from the 7 skill files) lands in **C3** — the 7 skill files split pack-startup ×3
  (stripped at C2) + pm-startup ×4 (stripped at C3), so leg-3's `== 0` is not true until C3
  (this REFINES the user's "leg 3 in C3" under the post-renumber map — see **GAP-NEW** in §11);
  leg 5 (`tracker.toml.example` absent from the install map) also lands in **C3** (project-side
  + installers). The Check-51 dedicated test grows in lock-step — each commit adding a
  leg also updates the test (Check 42). validate-pack is GREEN at every commit.
- **GAP-2 — Node-24 actions bump hoisted to C1.** The `actions/checkout` /
  `actions/setup-python` Node-24 major bump (yml lines 88/91/109/112) is independent of
  the flip-block work and is deadline-bound (2026-06-16). It moved OUT of the old C2
  and rides **C1** (the first `pack-only` `scripts/`+`.github/` commit).
- **GAP-3 — old C6 split into two commits** (the user's "C6a + C6b"; **renumbered to
  C5a + C5b** here since old C2 collapsed). C5a = the coder MAJOR Track-2 entry re-scopes;
  C5b = Pack-Chat bookkeeping (new-entry authoring + status flips + `_toc.md` regen),
  consistent with the "Batch close commit shapes" rule (fixes commit separate from the
  status-flip commit).
- **GAP-4 / GAP-5 folded as instructions** (not new commits): the `pack-td.sh` typo fix
  stays in C1 and its prose edit in C2 (lane discipline); the C2/C3 reviewers MUST
  EMPIRICALLY re-run Checks 22/23 after the fragment-stub rewrite, not assume pass.

**COMMIT RENUMBERING (the consequent re-sequencing).** With the Node-24 bump hoisted
(GAP-2) and Check-51 legs 1/2/4 + the Check-50 dedicated test folded into C1 (GAP-1),
the original C2 ("Check 51 + test, Check 50 test, Node bump") is left with no
independent, single-purpose content — so **old C2 COLLAPSES into C1** and everything
downstream renumbers down by one, then old-C6 splits:

| Old # | New # | Commit |
|---|---|---|
| C1 | **C1** | flip-block code + Check-51 scaffold/legs 1+2+4 (+ test) + Check-50 dedicated test (+ both wired) + **Node-24 bump** + pack-td typo |
| C2 | — | COLLAPSED into C1 (its residual content after GAP-1/GAP-2 was not single-purpose) |
| C3 | **C2** | pack-side surface sweep (strips pack-startup ×3 of leg-3's 7) + pack-td prose |
| C4 | **C3** | project-side + installers + **Check-51 leg 3 (final pm-startup ×4 strip) + leg 5** (test grows) + atomic validator re-pin |
| C5 | **C4** | maintenance-docs deletion (93 files) |
| C6 | **C5a + C5b** | C5a = coder MAJOR Track-2 entry re-scopes; C5b = Pack-Chat bookkeeping + `_toc.md` regen |

All section bodies below use the NEW numbering. The held GH deletion remains POST-train,
user-GO-gated.

## 0. Scope of this plan

- **Track A ONLY** — the cleanup C1–C5b (six commits post-renumber: C1, C2, C3, C4, C5a, C5b) + the held GH deletion (post-C5b, gated).
- **Track B is CARVED OUT** (design §10.5): the phase-parts/ordering IMPLEMENTATION
  (BD-185 flat-file build, BD-206 conversion + `_order.md`, BD-216 tracker legs). C1–C5b write
  the BD-185/BD-206/BD-216 **ENTRY re-scope TEXT** only (decided scope + constraints +
  pointers). The Track-B implementation is its own docs-researcher → architect → planner →
  coder pipeline AFTER C5b and is NOT planned here. **Do not let any C-commit touch a Track-B
  implementation surface** (METHODOLOGY phase-parts mechanism, project-stream conversion
  tooling, `_order.md`, work-item.yml Part field).

## 1. Goal + BD items addressed

**Goal:** make flat-file per-entry the sole supported mode on both surfaces; block the
ability to flip to tracker mode; strip tracker-as-usable advertisement; add the regression
guard (Check 51) + the missing Check 50 test; delete 93 process-churn maintenance docs;
re-baseline all 43 non-resolved Track-2 entries by TEXT.

**BD items:** BD-214 (primary — flip-block + cleanup + held deletion). Track-2 entry-TEXT
re-scope touches (status-only or TEXT): BD-039, BD-040, BD-093, BD-100, BD-102, BD-105,
BD-109, BD-110, BD-136, BD-171, BD-172, BD-174, BD-185, BD-187, BD-188, BD-189, BD-192,
BD-197, BD-198, BD-202, BD-205, BD-206, BD-210, BD-212, BD-213, BD-215, BD-204 (dated note),
+ AUTHOR BD-216. (14 no-change entries per §9 untouched.) BD-185/BD-206/BD-216
implementation = Track B (not here).

## 2. Per-commit dependency / ordering proof

Order **C1 → C2 → C3 → C4 → C5a → C5b** is forced (post-renumber):

| Edge | Why this order | What breaks if reordered |
|---|---|---|
| C1 first | C1 lands the clamp + verb gates AND Check 51 (scaffold + legs 1/2/4). Legs 1/2/4 measure state C1 itself creates (clamp marker, verb gates) or already-true state (entry grep-zero), so Check 51 PASSES at the C1 boundary. The Node-24 bump rides here (independent, deadline-bound 2026-06-16). | If the gates landed without their legs, the guard would be silent; if a leg landed before its fix-recipe (leg 3/leg 5), CI would go red. Incremental-leg ordering (GAP-1) prevents both. |
| C1 before C2/C3 | C2/C3 rewrite prose to say "tracker refuses / is deferred"; the refusal must already exist so prose is truthful and tests that exercise refusals pass. Every C2/C3 commit is also already guarded by Check 51 (anti-reintroduction). | Prose advertises a refusal that does not exist ⇒ misleading + test drift; later commits unguarded. |
| Check-51 leg 3 in **C3** | Leg 3 (skill files == 0) becomes TRUE only after BOTH the pack-startup ×3 (C2) AND the pm-startup ×4 (C3) strips. The full strip completes at C3, so leg 3 is ADDED at C3 (same commit as the final fix-recipe) to keep the guard green. **This refines GAP-1's "leg 3 in C3"** — see GAP-NEW. | Adding leg 3 at C1 ⇒ 7 hits ⇒ red; at C2 ⇒ 4 hits (pm-startup unstripped) ⇒ red. |
| Check-51 leg 5 in C3 | Leg 5 (install-map absent) becomes TRUE only after C3 removes `tracker.toml.example` from the install map. Adding leg 5 in C3 (same commit as its fix-recipe) keeps the guard green. | Adding leg 5 at C1/C2 ⇒ measures 1 hit ⇒ red CI. |
| C2 before C3 | Keeps each surface sweep independently reviewable (pack-side vs project/installers); C3's install-map removal depends only on C1's clamp, not on C2. | A merged C2+C3 is a huge mixed-scope diff, harder to review, and forfeits C2's `pack-only` keyword. |
| C3 atomic | install-map removal + `_CLIENT_INSTALLED_FILES` self-doc removal + Checks 39/41/46 re-pin + Check-51 leg 5 MUST be one commit (enumerate-encoding-surfaces / set-equality / leg-fix lock-step). | Split ⇒ Check 39/41 set-equality OR Check 51 leg 5 fails mid-sequence ⇒ red CI. |
| C4 independent | maintenance-docs deletion gates on no validator (Check 48 advisory, set NOT grown). Could float, but placed mid-sequence so C5a/C5b entry text can cite a clean tree. | None hard; placement is for reviewability. |
| C5a before C5b | C5a (coder MAJOR entry re-scopes) lands the substantive entry TEXT; C5b (Pack-Chat bookkeeping: new BD-216 + status flips + `_toc.md` regen) follows so the regen reflects all entry edits and the status-flip commit is separate from the substantive-edit commit ("Batch close commit shapes"). | A single C5 commit mixes coder-MAJOR + bookkeeping; `_toc.md` regen before all edits land ⇒ Check 33 toc-out-of-sync. |
| C5a/C5b last | Entry re-scope TEXT references the LANDED state (deleted docs, new checks, blocked flip). | Entry text would cite not-yet-existing state. |

**Flat-file behavior never breaks at any boundary:** the C1 clamp only STRENGTHENS the
existing flat-file fallback in `tracker_mode()` (design §3, EE-6); validate-pack never calls
`tracker_mode` (EE-6); all dormant tracker tests stay green via the
`PACK_TRACKER_DEFERRAL_OVERRIDE=1` test-only export. Each commit ends CI-green (validate-pack
full + integration `test-v11-realistic-ot.sh` + the per-check tests).

**Green-per-commit invariant — incremental Check 51 (GAP-1).** Each leg appears only once
its condition is TRUE at that commit boundary:

| Commit | Check-51 legs PRESENT (asserted) | All present legs PASS because |
|---|---|---|
| **C1** | 1, 2, 4 | leg1 clamp marker + leg2 verb gates are created BY C1; leg4 entry grep-zero is already true at HEAD (EE-8). |
| **C2** | 1, 2, 4 | leg3 NOT added here — C2 strips only 3 of 7 skill-file occurrences (pack-startup ×3); the pm-startup ×4 are stripped at C3, so leg-3 `== 0` is not yet true (GAP-NEW). |
| **C3** | 1, 2, **3**, 4, **5** | leg3 added in the SAME commit that completes the strip (pm-startup ×4) ⇒ measures 0; leg5 added in the SAME commit that removes `tracker.toml.example` from the install map ⇒ measures absent. |
| **C4, C5a, C5b** | 1, 2, 3, 4, 5 (all, inherited) | no leg's fix is reverted; the guard stays green. |

The Check-51 dedicated test (`test-validate-pack-check-51-flip-block.sh`) is authored at C1
asserting ONLY legs 1/2/4, and is EXTENDED at C3 (leg 3 AND leg 5) in lock-step — Check
42 (CI wires all per-check tests) stays satisfied because the test file exists + is wired from
C1 onward. (Leg 3 is added at C3, not C2, because the skill-file strip completes at C3 — GAP-NEW.)

## 3. Bounded review/fix cycle (every commit)

Each commit takes the STANDARD bounded cycle: pack-coder → pack-reviewer → Pack-Chat triage
(present to user) → fix-coder → … **max 2 review/fix pairs + 1 final reviewer pass** = 3
reviewer / 2 fix-coder spawns per commit. If dirty after the final reviewer pass, STOP and
spawn pack-architect (no fix-coder pass 3). Fresh coder per commit and per fix.

**Extra-scrutiny flags:**
- **C2** (was C3) — largest surface sweep (root trinity ×3 parity + many docs + the
  `changelog/v11.md` literal reword) + leg-3 PARTIAL strip (pack-startup ×3; leg 3 itself
  added at C3, GAP-NEW); high enumerate-encoding-surfaces risk (tests pin fragment
  content / prose). Reviewer MUST empirically re-run Checks 22/23 (GAP-5).
- **C3** (was C4) — mixed-scope (no keyword) + atomic validator re-pin + Check-51 legs 3
  (final strip) & 5; the BD-203-lesson risk (integration test pins validator OUTPUT) is
  highest here and at C2. Reviewer MUST empirically re-run Checks 22/23 on the project-copy
  stub (GAP-5).
- **C5a** (was C6, coder half) — MAJOR entry edits (re-scoping landed content) routed to coder.
  **C5b** (Pack-Chat half) — BD-216 authoring (new-entry, Pack-Chat-eligible) + status flips +
  `_toc.md` regen. Split routing — see §9.

## 4. C1 — flip-block code + Check-51 (legs 1/2/4) + Check-50 test + Node-24 bump

**Scope keyword:** `pack-only` (touches only `scripts/`; no `project-template/` or
`supporting-docs/`). **Manifest regen:** YES (diff touches `scripts/`). **Trinity:** none.
**Verification battery:** `validate-pack.py` (full — Check 51 PASSES with legs 1/2/4 against
the C1-landed clamp + gates; Check 50 + Check 51 dedicated tests; Check 42 per-check-test
wiring PASSES for both new test files) + the affected tracker/recommendation test scripts run
green with the override export; integration `test-v11-realistic-ot.sh`. **Coder runs Check 51
against the C1 tree and confirms legs 1/2/4 PASS** (legs 3/5 are NOT added here — see GAP-1
note). Run `bash test-fixtures/build.sh --all --clean` and stage `test-fixtures/manifest.txt`
if the diff is non-empty.

| File | Edit (design §-ref) | Surface note |
|---|---|---|
| `scripts/lib/tracker-config.sh` | Insert the BD-214 deferral clamp as the FIRST statement of `tracker_mode()` (def at :187). `PACK_TRACKER_DEFERRAL_OVERRIDE != 1` ⇒ one-line stderr "tracker mode is deferred; operating flat-file" + `echo flat-file; return 0`. (§3 Layer A, EE-6) | the chokepoint |
| `scripts/pack-tracker.sh` | Add deferral refusal in `cmd_init` (:147, BEFORE `tracker_init_run`) and `cmd_enable_recommendations` (:738). Refusal text: tracker deferred indefinitely; flat-file is the supported mode; recorded in BD-214/BD-204. Gated by the same override seam. (§3 Layer B) | verb gates |
| `scripts/tracker-migrate.sh` | Add deferral refusal in the FORWARD arm (`cmd_forward`, dispatch :187). Reverse arm (:189) UN-gated. (§3 Layer B, missed-seam #2) | low-level flip path |
| `scripts/pack-td.sh` | Fix the advisory typo `Resolution: n/a` → `Resolved: n/a` (BD-204 note line 30, fold-here fix-now). NOTE: tracker-mode prose reword in `pack-td.sh` is a §4 Axis-B "UPDATE where prose says usable" item — assign it to **C2**'s pack-side sweep to keep C1 code-only (GAP-4 lane discipline). (§4 Axis B) | shared code; typo only in C1 |
| tracker + recommendation test scripts (`scripts/tests/tracker-*.sh`, `test-tracker-*.sh`, `recommendation-test.sh`, etc.) | Add `export PACK_TRACKER_DEFERRAL_OVERRIDE=1` so dormant code stays exercised. (§3, D-B) | keeps dormant tests green |
| NEW behavioral gate tests | Author non-check-numbered tests asserting the refusals fire WITHOUT the override (init, enable-recommendations, tracker-migrate forward) + each un-gated verb on a flat-file root returns non-zero + typed error, no crash (§3 Layer B planner verification item). | plain behavioral tests, not check-numbered |
| `scripts/validate-pack.py` — ADD Check 51 (legs 1/2/4 ONLY) | leg1: clamp marker (`PACK_TRACKER_DEFERRAL_OVERRIDE` + dated comment) present in tracker-config.sh; leg2: init + enable-recommendations gates + tracker-migrate forward gate present; leg4: line-anchored `^<!-- pack-entry-body-gz64:` and `^<!-- pack-id:` over `backlog/ changelog/` == 0 (empty allowlist). **Legs 3 + 5 are deferred to C2/C3** (GAP-1) — their fix-recipes have not landed yet. (§6.3) | the regression guard, incremental |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | NEW dedicated test asserting ONLY legs 1/2/4 (Check 42 requires the file to exist + be wired; grows at C2/C3). | wired in this commit |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | NEW dedicated test for existing Check 50 (closes the EE-2 asymmetry, D-E). | wired in this commit |
| `.github/workflows/validate-pack.yml` | WIRE both new per-check tests as run steps (Check 42 enforces wiring). **Node-24 actions bump (GAP-2, deadline 2026-06-16):** `actions/checkout@v4`→ current Node-24 major (lines 88, 109) and `actions/setup-python@v5`→ current Node-24 major (lines 91, 112). Coder verifies the exact latest majors at implementation time (§6.5). | guards + CI in C1 |

**Coder verification item (design §3):** run each `pack tracker` verb
(`status/doctor/disable/tree-rebuild/edit/new-entry/mirror-rebuild/update-templates`) on a
flat-file root and assert non-zero + typed error (no crash) under the clamp.

**Sequencing note on Check-51 (post-renumber, GAP-1).** Check 51 SCAFFOLD + legs 1/2/4 +
its dedicated test + `.yml` wiring land HERE in **C1** (old C2 collapsed in). The dedicated
test asserts ONLY legs 1/2/4 at C1 and is EXTENDED in lock-step: leg 3 added at C2 (with its
Step-8 fix-recipe), leg 5 added at C3 (with its install-map fix-recipe). Because the test FILE
exists + is wired from C1, Check 42 stays satisfied at every commit; because each leg is added
only with its fix-recipe, Check 51 stays GREEN at every commit. The non-check-numbered
behavioral refusal tests above are separate plain scripts.

## 5. (collapsed) — old C2 guards/CI folded into C1

**Old C2 no longer exists.** After GAP-1 (Check-51 legs 1/2/4 + dedicated test land at C1)
and GAP-2 (Node-24 bump hoisted to C1), the original C2's residual content (only the Check-50
dedicated test) had no independent single-purpose footprint — it is the same `pack-only`
`scripts/`+`.github/` scope as C1. Therefore the Check-50 dedicated test (+ wiring), the
Check-51 scaffold/legs 1/2/4 (+ test + wiring), and the Node-24 actions bump ALL land in **C1**
(§4). Everything downstream renumbers down one (old C3→C2, C4→C3, C5→C4), and old C6 splits
into C5a + C5b (§9).

**Why this keeps every boundary green:** Check 51 at C1 asserts only legs 1/2/4 — all true at
the C1 boundary (clamp + gates created by C1; entry grep-zero already true per EE-8). Check 50
is a cheap static self-guard that already passes against the current tree; its NEW dedicated
test simply exercises it. Check 42 (per-check-test wiring) is satisfied because both new test
files exist + are wired in C1. The Node-24 bump is a pure CI-runner version change with no
effect on validate-pack results. **Legs 3 and 5 are NOT present at C1** — they are added at the
commits that land their fix-recipes (leg 3 → C2; leg 5 → C3), so the guard never asserts a
not-yet-true condition (GAP-1).

## 6. C2 (was C3) — pack-side surface sweep (leg-3 partial strip: pack-startup ×3)

**Scope keyword:** `pack-only` (all paths are pack ops/state, README, QUICKSTART, changelog,
backlog `_rules`/`_intro`, pack-ops docs, pack-side skills — none under `project-template/` or
`supporting-docs/`). **Keyword-token trap:** the subject MUST NOT contain `project-only` or
`pack-chat-only` tokens even in prose. **Manifest regen:** YES (`scripts/` via pack-td.sh
prose? + `pack-ops/` touched). **Trinity:** YES — root `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`
edited ⇒ parallel edits at PACK-ROOT in the SAME commit. **Verification battery:**
`validate-pack.py` full (**Check 51 still asserts legs 1/2/4** — leg 3 is NOT added at C2:
C2 strips only 3 of the 7 skill-file occurrences (pack-startup ×3), so leg-3's `== 0` does not
hold until C3 strips the pm-startup ×4 — see GAP-NEW in §11; Checks 22/23
help-fragment freshness still green with the stub verb tokens retained; Check 32′/33/34 green;
Check 42 still green — the Check-51 test is EXTENDED with leg 3 this commit); `pack-help-test.sh`
(26 tracker refs — pins fragment content); `test-v11-realistic-ot.sh`; any test pinning swept
prose/banners. **GAP-5 (reviewer instruction):** the C2 reviewer MUST EMPIRICALLY re-run
Checks 22/23 against the rewritten `HELP-FRAGMENT-TRACKER.md` stub — do NOT assume the retained
verb tokens keep them green; confirm by running validate-pack, not by assertion.

| File | Edit (design §-ref) |
|---|---|
| root `CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (trinity, pack-root) | § Repo conventions "Per-entry trees — sole SSOT" bullet → flat-file-only + 2-sentence deferral note (Mode-3 contract prose deleted); "Resolved section" bullet drops its tracker-mode write-channel arm; § Project goals v11 first bullet → "flat-file per-entry is the sole supported mode; tracker integration is deferred (no version)". Parallel in all three, SAME commit. (§4 Axis E) |
| `pack-ops/PACK-CHAT.md` | "Backlog write paths by mode" (lines 53-121) → flat-file procedure + deferral note; "Recommendation routing (v11+)" / D-19 prose (288-307) → deferral note. (§4 Axis E) |
| `backlog/_rules.md` | REWRITE "Source of truth — mode-dependent" → flat-file-only (tree is SOLE SSOT, no monolith) + short "Tracker mode (deferred)" paragraph; DELETE "Published tree + single writing authority" tracker arm; KEEP field-faithful paragraph, reword justification format-neutral. (§4 Axis A) |
| `backlog/_intro.md` | mode pointer line → deferral wording. (§4 Axis A) |
| `changelog/_rules.md` | "Mode invariance" § → "flat-file in all cases" + one deferral sentence. (§4 Axis A) |
| `changelog/v11.md` | Apply the LITERAL old→new from design §6.6: line 4 H3 title `### v11.0 — Issue-tracker integration + customization-preservation fix` → `### v11.0 — Flat-file per-entry model + customization-preservation fix`; line 6 Scope-A H4 → `**Scope A — Issue-tracker integration (D-1..D-23) — DEFERRED / DORMANT in v11.0**` + insert the §6.6 blockquote preface; KEEP D-1..D-23 bullets verbatim. If live lines drift from §6.6 quote, SURFACE drift, do not force-apply. (§6.6, US-2 RESOLVED). Verified current text matches §6.6 quote at this HEAD. |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | Rewrite as deferred STUB: heading "Tracker commands (deferred)"; 2-3 sentences; RETAIN the verb TOKENS (e.g. `pack tracker init` named as *refusing*) so Check 22 stays green. (§4 Axis F) |
| `pack-ops/HELP-FRAGMENT-PACK.md` | tracker verb rows get "(deferred)" qualifier or collapse to one deferred row. (§4 Axis F) |
| `pack-ops/OPTIONAL-FEATURES.md` (§125 "Tracker integration (v11)") | REPLACE walkthrough with a short deferred section (what it was; deferred; code dormant; no opt-in steps). (§4 Axis F) |
| `pack-ops/MERGE-STRATEGY.md`, `DRY-RUN-MIGRATION.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md` | mechanical "(deferred)" row annotations. (§4 Axis F) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` (3 occ), `BOUNDARY-DEFINITION.md` (2 occ) | mechanical deferral rewording. (§4 Axis E) |
| `scripts/pack-td.sh` | UPDATE tracker-mode prose → "deferred" (the prose half of the §4 Axis-B pack-td row; the typo fix already landed at C1). |
| `scripts/pack-help.sh` | fragment content changes ride through; mechanism KEEP (no structural edit). (§4 Axis B) |
| pack-startup skills Step 8 ×3 (`.claude/skills/pack-startup/SKILL.md`, `.codex/.../SKILL.md`, `.gemini/commands/pack-startup.toml`) | Step-8 BODY → 3-line deferred note (step NUMBER kept). This STRIPS 3 of the 7 leg-3 occurrences. (§3 Layer C, EE-7) |
| (Check-51 leg 3 — NOT added here) | C2 STRIPS only 3 of the 7 leg-3 occurrences (pack-startup ×3); the other 4 (pm-startup ×4) are STRIPPED at C3. Leg 3 (== 0) therefore cannot be TRUE until C3. **Per the green-per-commit rule, leg 3 is ADDED at C3** (where it becomes true), NOT here. ⚠ This refines GAP-1's "leg 3 lands in C3" — under the post-renumber map, the pack-side sweep is C2, but leg 3's condition completes only at C3 (project-side, where pm-startup is stripped). See **GAP-NEW** in §11. |
| `scripts/pack-td.sh` (prose) | UPDATE tracker-mode prose → "deferred" (the prose half of the §4 Axis-B pack-td row; the typo fix already landed at C1). (GAP-4 lane discipline) |
| `boundary-investigation` skill mentions (pack ×3 CLIs) | KEEP as historical worked-example + one-word "deferred" qualifier where it implies usable. (§4 Axis E) |
| `README.md` | v11.0 version-table row reworded (tracker = "deferred (dormant)"); layout rows for tracker files KEEP but annotate "(dormant, deferred)" (:107, :138, :197-215, :255-271). (§4 Axis F) |
| `QUICKSTART.md` :43 | deferral rewording. (§4 Axis F) |
| Lock-step tests | `pack-help-test.sh` (fragment-content pins) + any test pinning swept prose/banners — UPDATE in this commit (enumerate-encoding-surfaces; BD-203 lesson). (§4 Axis D) |

## 7. C3 (was C4) — project-side + installers + Check-51 legs 3 (final) & 5 (mixed scope; atomic validator re-pin)

**Scope keyword:** NONE — genuinely MIXED (touches `scripts/` pack-side AND
`project-template/` + `supporting-docs/` client-side). Use neutral subject framing
("BD-214 cross-surface installer + project sweep"); NO `pack-only`/`project-only`/
`pack-chat-only` token anywhere (Check 36 token-trap). **Manifest regen:** YES (`scripts/`,
`project-template/`, `supporting-docs/` all touched). **Trinity:** YES — `project-template/`
CLAUDE/AGENTS/GEMINI edited ⇒ parallel at PROJECT-TEMPLATE location, SAME commit. **Cross-CLI
reference normalization** applies to project-template trinity edits (per ARCHITECTURE-BD-182
§4.1 canonical table — audience-correct values, NOT byte-copy). **Verification battery:**
`validate-pack.py` full (**Check 51 now asserts ALL 5 legs** — leg 3 added THIS commit and
PASSES because the pm-startup ×4 strip below completes leg-3's `== 0`; leg 5 added THIS commit
and PASSES because the install-map removal below makes `tracker.toml.example` absent; Checks
39/41/46 PASS post-re-pin; Check 42 still green — the Check-51 test is EXTENDED with legs 3+5
this commit); `test-init-project.sh`, `test-migrate-v10-to-v11-gates.sh`,
`template-translations-test.sh`; `test-v11-realistic-ot.sh`. **GAP-5 (reviewer instruction):**
the C3 reviewer MUST EMPIRICALLY re-run Checks 22/23 against the project-copy
`HELP-FRAGMENT-TRACKER.md` deferred stub — confirm by running validate-pack, not by assertion.

**ATOMIC LOCK-STEP SET (install-map removal + self-doc + validator re-pins — one commit):**

| Surface | Edit (design §-ref + verified line) |
|---|---|
| `scripts/init-project.sh` install-map ARRAY | DELETE `"project-template/tracker.toml.project-example:tracker.toml.example:generic"` (verified :1250). (§3 Layer C, EE-9) |
| `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES` self-doc block | DELETE the matching self-doc comment line (verified :1405, inside START 1386 / END 1424). **Both occurrences must go together or Check 41 self-doc-list integrity fails.** |
| `scripts/init-project.sh` S11 copy | Remove the `tracker.toml.example` copy (verified :937-943) + S11 banner wording (:908) drops the tracker advertisement. (§3 Layer C) |
| `scripts/validate-pack.py` Checks 39 / 41 / 46 | RE-PIN cmd_update symmetry + `_CLIENT_INSTALLED_FILES` set-equality + project-side mirror so the removed entry no longer expected. SAME commit (§6.1, enumerate-encoding-surfaces). |
| `scripts/validate-pack.py` — ADD Check-51 **leg 5** | leg5: `tracker.toml.example` absent from init-project.sh install map (anti-reintroduction). Added THIS commit — the SAME commit removing it from the map (above) ⇒ measures absent ⇒ PASS. (§6.3, GAP-1) |

**Rest of C4 (project sweep + migrator):**

| Surface | Edit |
|---|---|
| `scripts/migrate-v10-to-v11.sh` | Remove example-copy (verified :299-305); rewrite post-report `pack tracker init` pointer (:678/:710-711) to a deferral sentence. (§3 Layer C) |
| `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (trinity, project-template) | parallel deferral edits to project-side mode prose (cross-CLI-normalized), SAME commit. (§4 Axis E) |
| `project-template/docs/pack/PM-CHAT.md` | D-19 prose (512-531) + tracker-mode read/write paths (591-884) → flat-file procedure + deferral note. (§4 Axis F) |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` (§110) | deferred section (mirror of pack-side). (§4 Axis F) |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | deferred STUB (project copy, retain verb tokens). (§4 Axis F) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | tracker verb rows "(deferred)". (§4 Axis F) |
| pm-startup skills Step 8 ×4 (`project-template/{.claude,.codex,skills}/pm-startup/SKILL.md` + `.gemini/commands/pm-startup.toml`) | Step-8 BODY → deferred note (number reserved). STRIPS the remaining 4 leg-3 occurrences — this COMPLETES the 7-file strip (pack-startup ×3 landed at C2). (§3 Layer C, EE-7) |
| `scripts/validate-pack.py` — ADD Check-51 **leg 3** | leg3: `recommendation_should_recommend` OUTSIDE allowlist `{scripts/lib/recommendation.sh, scripts/tests/, maintenance-docs/}` == 0. Added THIS commit because the strip COMPLETES here (pm-startup ×4) ⇒ measures 0 ⇒ PASS. (§6.3, GAP-1, GAP-NEW) |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | EXTEND to assert legs 3 AND 5 (in addition to 1/2/4). Check 42 stays satisfied (file already wired at C1). |
| `project-template/docs/pack/prompts/{reviewer,pm-chat,coder,auditor,tester}.md` (×5) | "flat-file mode reads X; tracker mode reads the tracker" → "reads X (the per-entry tree)". (§4 Axis F) |
| `project-template/docs/project/{backlog,implementation-plan,changelog}/_intro.md` (×3) | mode paragraphs → flat-file-only + deferral sentence. (client `_rules.md` = zero refs, no edit.) (§4 Axis F) |
| `supporting-docs/DEPENDENCIES.md` | gh / gh-sub-issue rows (129-162) → "required only for the deferred tracker feature (dormant)". (§4 Axis F) |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Phase B section → "Phase B (tracker opt-in) — DEFERRED"; migration is Phase-A complete without it. (§4 Axis F) |
| `supporting-docs/METHODOLOGY.md` (1 occ) | mechanical deferral. (§4 Axis F) |
| `.github/ISSUE_TEMPLATE/config.yml` (root + project) | verify blurbs don't sell tracker mode; mechanical UPDATE if so. (§3 Layer C) |
| Lock-step tests | `test-init-project.sh` (recommendation/S11 refs), `test-migrate-v10-to-v11-gates.sh`, `template-translations-test.sh` — UPDATE same commit. (§4 Axis D) |

**Boundary note (dependency-direction):** `_SANCTIONED_PACK_SIDE_SHIPPED` is NOT touched
(stays `{scripts/lib/detect.sh, scripts/pack-help.sh}`); the removed install is a SHRINK, not
a new ship; Check 47 unaffected (design §5).

## 8. C4 (was C5) — maintenance-docs deletion (93 files)

**Scope keyword:** `pack-only` (deletions under `maintenance-docs/` only). **Manifest regen:**
NO (`maintenance-docs/` is not a v11-surface dir). **Trinity:** none. **Verification battery:**
`validate-pack.py` full (Check 48 advisory; `_REMOVED_DOC_BASENAMES` NOT grown — §6.1; Check 34
ID-form refs only); `test-v11-realistic-ot.sh`.

- DELETE the 93 files enumerated in design §8 (41 IMPL-REPORT + 42 PACK-REVIEW + 4
  DESIGN-REVIEW + 3 PLAN + 2 SWEEP + 1 ANALYSIS). KEEP the 14 §8 KEEP files + the 2 LIVE
  BD-214 inputs (this census + RESEARCH-BD-212).
- **Execution channel:** US-9 = user-approved DESTRUCTIVE op. Per pack memory
  (`per-action-approval-sub-agents`, `feedback-no-destructive-without-approval`), the
  deletion is executed by **Pack Chat** (not a coder) with the final file list surfaced at the
  C4 gate for explicit user approval before `git rm`. Coder role here is NIL (deletion is not
  a content edit). **Flag for Pack Chat: this is a Pack-Chat-executed `git rm` batch, gated.**
- Dangling citations from Deferred history (e.g. BD-204 notes naming deleted IMPL-REPORTs) are
  FAIL-LOUD-ACCEPTABLE per the memory rule (design §8).

## 9. C5a + C5b (was C6) — Track-2 entry applications (TEXT only), SPLIT per GAP-3

GAP-3 splits the old single C6 into **two commits** so the substantive coder-applied entry
re-scopes are a separate commit from the Pack-Chat bookkeeping — consistent with the "Batch
close commit shapes" rule (fixes/substantive commit separate from the status-flip commit).
**Both commits carry the `pack-chat-only` keyword** (both touch only the `/backlog/` tree +
`_toc.md`, which are pack-chat-only per PACK-AGENTS.md; the keyword is a FILE-SCOPE claim, and
a coder scoped into pack-chat-only paths is the supported path, not a boundary violation).
**Manifest regen:** NO for both (`backlog/` is not a v11-surface dir). **Trinity:** none.

### C5a — coder MAJOR Track-2 entry re-scopes

**Route:** coder (Pack Chat scopes the `/backlog/BD-NNN.md` paths into the coder prompt).
**Scope keyword:** `pack-chat-only`. **Verification battery:** `validate-pack.py` full (Check
32′ no-monolith, Check 33 toc-in-sync — `_toc.md` regen at C5b, NOT here, OR regen here if C5a
lands entry edits that change the index and re-regen at C5b; see the toc note below; Check 34
cross-ref); `test-v11-realistic-ot.sh`.

C5a applies the MAJOR (substantive landed-content) edits to: **BD-185** flat-file re-scope
(incl. `Blockers:`/`Unblocks:` → BD-185 blocks BD-215 wiring), **BD-206**, **BD-215** scope
addition (incl. US-3 BD-204/BD-215 cycle-validator notes on BD-215), the **BD-100→BD-205
merge**, **BD-102/BD-174** deprecations, **BD-205** REFRESH, the REFRESH/RE-SCOPE/RE-ANCHOR
cluster (BD-039/040/093/105/109/110/136/171/172/187/189/192/197/202/210), and **BD-198**
Resolve if its reconciling `Resolved:` line is substantive (else C5b). See the per-entry table
(Route column = `coder (C5a)`).

### C5b — Pack-Chat bookkeeping + `_toc.md` regen

**Route:** Pack-Chat-direct (new-entry authoring + status flips + dated notes are
Pack-Chat-eligible per `pack-chat-minor-edits-only`). **Scope keyword:** `pack-chat-only`.
**Verification battery:** `validate-pack.py` full (Check 32′/33/34); **regenerate `_toc.md` via
`per_entry_regenerate_toc pack-backlog /backlog` AFTER all C5a + C5b entry edits land, before
staging C5b** (so Check 33 toc-in-sync passes on the FINAL entry set); `test-v11-realistic-ot.sh`.

C5b applies: **AUTHOR new BD-216** (new-entry; names BD-185 as semantic source), the
**BD-188/BD-212/BD-213** Deferred-no-version status flips + the **BD-198** status flip (if not
substantive), the **BD-204** dated note (US-3 cycle-check re-anchor), the "no version = lands
with the tracker-resumption release" cluster wording, and the **`_toc.md` regen**.

**`_toc.md` regen sequencing:** the toc reflects the entry set. To keep Check 33 green at BOTH
boundaries: regenerate `_toc.md` in C5a after C5a's entry edits AND again in C5b after C5b's
edits (BD-216 authoring changes the index). Each commit ends with a toc-in-sync tree.

**Per-entry edit spec (design §9):**

| Entry | Disposition | Route | Edit |
|---|---|---|---|
| BD-216 | AUTHOR NEW (Deferred, no version) | **Pack-Chat (C5b)** — new-entry | Tracker legs of BD-185 (work-item Part field + part:M label SC6; TrackerProvider part/order sync SC7; tracker native ordering P3/SC4-tracker; flat→tracker ordering init SC8-tracker). BLOCKED on BD-215→BD-204/207. NAMES BD-185 as semantic source. "No version = lands with the tracker-resumption release cluster." (§9 BD-216 row; next integer 216 verified). |
| BD-185 | RE-SCOPE flat-file-only, STAYS v11.0 + launch gate | **coder (C5a)** — MAJOR | Scope flat-file half (phase-parts lifecycle in METHODOLOGY, execution-notes ordering, STATUS SC5, v10→v11 whole-number SC8-flat, validate-pack part/ordering invariants). DELETE dead `Paused:` line; KEEP F9-glob KNOWN-GAP note. HARD CONSTRAINT TEXT: design DETERMINISTICALLY SERIALIZABLE. WIRING: `Blockers:`/`Unblocks:` → BD-185 blocks BD-215. Move tracker legs to BD-216. (TEXT only — Track-B implements.) (§9 BD-185 row). |
| BD-206 | RE-SCOPE v11.0 flat-file-only | **coder (C5a)** — MAJOR | Drop ops-contract R1-R8 mode-conditional folds; KEEP OT-v10.3 census prereq, generalized-only guard, scrubbed fixtures, detect.sh repoint, client `[mirror]` retirement, tracker-mirror client legs. ADD monolith-DELETE directive (no regenerated mirror) + `_order.md` create/reconcile directive (predesigned-but-unbuilt; reconcile to BD-203 as-built if conflict). TEXT only — Track-B implements. (§9 BD-206 row). |
| BD-215 | scope addition (status stays Deferred) | **coder (C5a)** — MAJOR | Add: cycle validator ships WITH the format validator (US-3); structured-Blockers requirement (EE-11 false-cycle evidence). (§9 fixed-by-user block, §6.4). |
| BD-204 | dated note | **Pack-Chat (C5b)** — bookkeeping | Add 2026-06-13 note re-anchoring the queued Blockers-cycle check to BD-215 (US-3); add the US-3 BD-204/BD-215 note. (§9, §6.4). |
| BD-100 | DEPRECATE + MERGE → BD-205 | **coder (C5a)** — MAJOR | Set `Status: Deprecated` + BD-205 pointer; the 3 carry-forwards (Check 23 persona-contracts gap + 2 contract-note audits) land VERBATIM in BD-205 text. (US-7). |
| BD-102 | DEPRECATE | **coder (C5a)** — MAJOR (re-scope+status) | `Status: Deprecated` + rationale (premise dead twice). (US-7). |
| BD-174 | DEPRECATE | **coder (C5a)** — MAJOR | `Status: Deprecated` + rationale. (US-7). |
| BD-198 | RESOLVE | **C5b Pack-Chat** (status flip + Resolved line) OR **C5a coder** if reconciling text is substantive | `Status: Resolved` + reconciling `Resolved:` line (cb460e6, 4 AC verified, EE-12). (US-7). |
| BD-188 | DEFER no-version | **Pack-Chat (C5b)** status flip + cluster TEXT (if substantive cluster prose, route to C5a coder) | `Status: Deferred`; "no release version; lands with the tracker-resumption release" cluster wording. (US-5). |
| BD-212 | DEFER no-version | **Pack-Chat (C5b)** status flip + cluster TEXT | `Status: Deferred` + cluster wording. (US-5). |
| BD-213 | DEFER no-version | **Pack-Chat (C5b)** status flip + cluster TEXT | `Status: Deferred` + cluster wording. (US-5). |
| BD-205 | REFRESH | **coder (C5a)** — MAJOR | Re-enumerate gate set; ABSORB BD-100 carry-forwards verbatim + BD-102/171/174 residue; drop tracker legs; keep test-hygiene note. (§9). |
| BD-039, BD-040, BD-093, BD-105, BD-109, BD-110, BD-136, BD-171, BD-172, BD-187, BD-189, BD-192, BD-197, BD-202, BD-210 | REFRESH / RE-SCOPE / RE-ANCHOR (per §9 rows) | **coder (C5a)** — MAJOR (substantive landed-content edits) | Apply each §9 row's exact edit (dead-ref fixes, monolith→`/changelog/v11.md` repoint, flat-file vocabulary, BD-205 re-anchor, drop tracker-mode clauses, validator-count refresh, fold BD-197 git-stash anchor). BD-197 is `Unblocked`; keep v11.0. (§9 rows). |
| `backlog/_toc.md` | REGEN | **mechanical (C5a end + C5b end)** | Regenerate after C5a's entry edits (toc-in-sync at C5a) AND again after C5b's edits (BD-216 changes the index), before staging each commit. |

**Cluster wording (US-5), applied to BD-188/212/213 (+ already on BD-204/207/215/216):** each
reads "no release version; lands with the tracker-resumption release." Cluster =
{BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}; BD-215 is the format-first gate.

## 10. The HELD GH deletion (POST-C5b, user-GO-gated — NOT a commit)

This is NOT scheduled into C1–C5b and touches NO repo files. After C1–C5b land and on an
EXPLICIT user GO (US-1/US-8), execute design §7 mechanics:

1. Preflight `gh auth status` + `viewerCanAdminister == true`.
2. Manifest FIRST → `/tmp/bd214-gh-issue-deletion-manifest-<date>.json` (number, node id,
   title, state, labels, `pack-id`). Recommend user archive a copy outside /tmp.
3. Candidate set = every issue with `bd-entry` label OR pack-id (all 213 carry `bd-entry`,
   EE-4). Any non-matching issue ⇒ STOP + surface.
4. Serial `deleteIssue` by node id via `gh api graphql`, ≥1s pacing, NOT_FOUND-idempotent,
   FORBIDDEN-class terminal stop. ~213 ops ≈ 4 min.
5. Verify search total → 0; spot-check `410 Gone`.
6. Delete the 49 pack-managed labels (`gh label delete`, ≥1s; 9 GH defaults stay) — US-8,
   same GO.
7. Dated note on BD-214 with counts + manifest location; then flip BD-214 `Resolved` (US-1).

**Run channel:** Pack Chat runs interactively (per-step approval) or via a throwaway `/tmp`
script — NOT committed (D-I). The PAT cannot delete repos but CAN delete issues/labels
(reference: GH PAT no-delete is repos-only); issue/label deletion is in-scope for the PAT.
**Note for Pack Chat:** confirm PAT issue-delete capability at GO (reference memory flags the
PAT as archive-only for REPOS; issue `deleteIssue` is a separate capability — verify at
preflight).

## 11. Gaps / contradictions for Pack Chat (flag, do not fill)

**GAP-1/2/3 — RESOLVED by the 2026-06-13 user resolutions** (see the Revision log at top).
GAP-1 (incremental Check 51) is applied across C1 (legs 1/2/4) → C2 (strips pack-startup ×3) →
C3 (leg 3 completes + leg 5); GAP-2 (Node-24 bump) is hoisted to C1; GAP-3 (C6 split) is
applied as C5a (coder MAJOR) + C5b (Pack-Chat bookkeeping). GAP-4/GAP-5 are FOLDED as
coder/reviewer instructions (pack-td typo C1 / prose C2; empirical Checks 22/23 re-run at
C2 and C3). They are retained below as a record, marked RESOLVED, plus ONE genuinely-new gap
the renumbering surfaced (GAP-NEW), which the planner FLAGS and does not fill.

- **GAP-NEW (Check-51 leg 3 spans TWO sweep commits — refines the user's "leg 3 in C3").**
  ⚠ The 7 leg-3 occurrences (`recommendation_should_recommend` in skill files, EE-7) are NOT
  all in one commit's scope: **pack-startup ×3** are stripped at **C2** (pack-side sweep) and
  **pm-startup ×4** at **C3** (project-side sweep). Therefore leg-3's `== 0` condition is FALSE
  until C3 lands. The user's GAP-1 resolution names "leg 3 lands in **C3**" — under the
  post-renumber map the pack-side sweep is C2 and the project-side sweep is C3, so **leg 3 is
  ADDED at C3** (where the strip COMPLETES and the condition is true), NOT at C2 (the pack-side
  sweep). This is consistent with the user's literal "C3" AND with green-per-commit; the
  planner records it explicitly because a reader could mistakenly read "leg 3 with the
  pack-side sweep" as C2. **No decision is filled — this is a notice; if Pack Chat/the user
  intended leg 3 to attach to the pack-side sweep specifically, the skill-file strip would
  need to be consolidated into one commit (re-scoping C2/C3), which the user has not directed.
  Flag for confirmation.**
- **GAP-1 (Check 51 leg-ordering) — RESOLVED (GAP-1 resolution).** Legs land with their
  fix-recipes: C1 legs 1/2/4; C2 strips 3 of 7 leg-3 occurrences (leg 3 not yet added);
  C3 adds leg 3 (strip completes) + leg 5 (install-map removed). validate-pack is GREEN at
  every boundary (§2 green-per-commit table). The dedicated test grows in lock-step.
- **GAP-2 (Node-24 deadline) — RESOLVED (GAP-2 resolution).** The Node-24 actions bump is
  hoisted to **C1** (the first commit), independent of the flip-block work, beating the
  2026-06-16 deadline. No longer pinned to the now-collapsed C2. Residual schedule note: if
  even C1 slips past 2026-06-16 the bump may need its own standalone micro-commit BEFORE C1 —
  Pack Chat should surface the C1 landing date vs the deadline at the C1 gate.
- **GAP-3 (C6 routing duality) — RESOLVED (GAP-3 resolution).** Old C6 is SPLIT: **C5a**
  (coder MAJOR entry re-scopes) + **C5b** (Pack-Chat new-entry authoring + status flips +
  `_toc.md` regen), both `pack-chat-only`, consistent with the "Batch close commit shapes"
  rule. §9 carries the per-entry C5a/C5b route assignment.
- **GAP-4 (pack-td.sh lane discipline) — FOLDED.** typo fix at **C1** (code-only); prose
  reword at **C2** (pack-side sweep). Both touch `scripts/` ⇒ manifest regens at C1 and C2.
  Coordination note retained so the split is honored.
- **GAP-5 (Check 22/23 fragment-stub freshness — empirical re-run) — FOLDED.** The **C2**
  reviewer MUST empirically re-run Checks 22/23 against the pack-side rewritten
  `HELP-FRAGMENT-TRACKER.md` stub; the **C3** reviewer MUST do the same for the project-copy
  stub. Do NOT assume the retained verb tokens keep them green — confirm by running
  validate-pack (recorded in §6 and §7 batteries).

The planner fills NONE of the above. **GAP-NEW** is surfaced for Pack-Chat/user confirmation
(it does not block — the chosen placement keeps every commit green; it only flags a wording
ambiguity in "leg 3 in C3" vs the pack-side sweep).

## 12. Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status --short`, `git branch --show-current`, plus `grep`/`sed`/`ls`/`find` reads. Zero `add/commit/push/tag/reset/stash/checkout/rm`. | COMPLIANT |
| 2. Empirical-Evidence Blocks (load-bearing re-verified) | HEAD = `0027b106789e09bad2d7cdb380c8c499d7d0f747` (matches design). `tracker_mode()` at tracker-config.sh:187 (grep). `cmd_init`:147, `cmd_enable_recommendations`:738, dispatch init):805 enable):814 (grep). tracker-migrate forward dispatch :187, reverse :189 (grep). init-project tracker.toml.example install-map :1250 AND self-doc :1405 (inside _CLIENT_INSTALLED_FILES_START 1386 / _END 1424), S11 copy :937-943, banner :908 (grep+sed). migrate-v10 example copy :299-305, pointer :678/:710 (grep). `changelog/v11.md` lines 1-6 = exact §6.6 quote (sed). Highest BD = BD-215; BD-216.md absent (ls). No check-50/check-51 test files exist (ls). CI pins checkout@v4 (88,109) setup-python@v5 (91,112) (grep). Integration test = `scripts/tests/test-v11-realistic-ot.sh` (find). Checks 39/41/46 + `_CLIENT_INSTALLED_FILES` + `_SANCTIONED_PACK_SIDE_SHIPPED` present in validate-pack.py (grep). All taken 2026-06-12 at HEAD 0027b10. | COMPLIANT |
| 3. Verify the full CI suite, not just validate-pack | Each commit's battery (§§4-9) lists validate-pack.py full + the relevant integration `test-v11-realistic-ot.sh` + per-check tests + tests pinning validator OUTPUT/prose (pack-help-test.sh, test-init-project.sh, gates test, translations test) at the commits that change pinned text. BD-203 lesson flagged for C3/C4. | COMPLIANT |
| 4. Regenerate manifest on v11-surface commits | Per-commit manifest flag (post-renumber): C1 YES (scripts/+.github/), C2 YES (scripts/+pack-ops/), C3 YES (scripts/+project-template/+supporting-docs/), C4 NO (maintenance-docs/ only), C5a NO (backlog/ only), C5b NO (backlog/ only). | COMPLIANT |
| 5. Trinity parity same-commit | C2 flags root trinity ×3 SAME commit (pack-root location). C3 flags project-template trinity ×3 SAME commit (project-template location) + cross-CLI normalization per ARCHITECTURE-BD-182. C1/C4/C5a/C5b = no trinity edit. | COMPLIANT |
| 6. Scope-keyword discipline + token trap | C1 pack-only, C2 pack-only, C3 NONE (mixed; neutral framing; no denying token in prose), C4 pack-only, C5a pack-chat-only, C5b pack-chat-only. Token-trap warning recorded for the C3 subject (§7). | COMPLIANT |
| 7. Deferral discipline | Track B carved out as user-authorized (§0, §9 TEXT-only rows); recorded out-of-plan, not implemented. No Track-A item silently deferred — all six commits (C1, C2, C3, C4, C5a, C5b) + held deletion + all 43 entry dispositions are scheduled. | COMPLIANT |
| 8. Planner never resolves design gaps | Original §11 retained; GAP-1/2/3/4/5 marked RESOLVED/FOLDED per the user resolutions; ONE genuinely-new gap (GAP-NEW: leg-3 spans C2+C3) is FLAGGED, not filled, for Pack-Chat/user confirmation. See also the revision-pass block §12a. | COMPLIANT |
| 9. Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cells. | COMPLIANT |
| 10. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: plan complete; about to Write …PLAN-BD-214-TRACKER-DEFERRAL.md` in the turn immediately before this write. No stop/halt/revert message received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete:
CLAUDE.md (full, incl. all `## Pack memory`, via system context);
ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both pages — 852 lines, every section incl.
Update log/§6.6/§7-§11/§10.5/§14a); RESEARCH-TRACKER-DEFERRAL-CENSUS.md (full, 423 lines);
pack-ops/PACK-CHAT.md (full, 389 lines); backlog/_rules.md (full, 152 lines);
changelog/_rules.md (full, 77 lines). No named document was derived rather than read.

## 12a. Rules-Applied Verification Block — 2026-06-13 revision pass

Covers ONLY the focused revision (GAP-1/2/3 applied, GAP-4/5 folded, C2 collapse +
renumber, green-per-commit re-verification, GAP-NEW flagged). The §12 block above stands
for the original plan.

| Rule (revision prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Revision-pass git verbs: `git rev-parse HEAD` → `0027b106789e09bad2d7cdb380c8c499d7d0f747`; `grep -n 'uses:' .github/workflows/validate-pack.yml`. Zero `add/commit/push/tag/reset/stash/checkout/rm`. | COMPLIANT |
| 2. Edit in place, not full rewrite | All edits applied as anchored single-occurrence string replacements (each asserted `count==1` via the edit scripts), plus two bounded section-body replacements (§2 ordering proof; old §5 C2 → collapsed note; §9 header → C5a/C5b split; §11 gaps). Section map confirmed intact below — every original section present; only the revision-relevant sections changed; ## 12a appended. NOT a full rewrite. | COMPLIANT |
| 3. Empirical-Evidence Blocks (revision state-claims) | HEAD `0027b106789e09bad2d7cdb380c8c499d7d0f747` (`git rev-parse HEAD`, 2026-06-12). Node-24 bump targets: `grep -n 'uses:'` → `actions/checkout@v4` lines 88 & 109, `actions/setup-python@v5` lines 91 & 112 (verbatim, this session) → SUPPORTED (the 4 yml lines GAP-2 hoists to C1). Leg-3 strip split: design EE-7 enumerates the 7 invokers as pack-startup ×3 (`.claude/.codex/.gemini`) + pm-startup ×4 (project-template) — the C2 sweep table strips the 3 pack-startup, the C3 sweep table strips the 4 pm-startup → SUPPORTED (leg-3 `==0` only true at C3 ⇒ GAP-NEW). Leg-5 strip: design §6.3/EE-9 install-map at init-project.sh:1250, removed in C3's atomic set → SUPPORTED (leg-5 added at C3). Check-50/51 test files do not yet exist (design EE-2) → both authored at C1. | COMPLIANT |
| 4. Green-per-commit re-verified | §2 "green-per-commit invariant" table shows Check-51 legs present per commit: C1 {1,2,4}, C2 {1,2,4}, C3 {1,2,3,4,5}, C4/C5a/C5b {all inherited} — each present leg's condition is true at its boundary (clamp/gates created by C1; entry grep-zero already true EE-8; leg3 strip completes at C3; leg5 install-map removed at C3). Each commit battery (§§4-9) lists validate-pack full + integration `test-v11-realistic-ot.sh` + per-check tests (Check 42, 50, 51) + prose-pinning tests. No commit asserts a not-yet-true condition. | COMPLIANT |
| 5. Planner never resolves design gaps silently | The renumbering surfaced a NEW contradiction (leg-3's strip spans C2+C3, so "leg 3 in C3" needs the post-renumber reading) — FLAGGED as **GAP-NEW** in §11 and NOT filled; routed to Pack-Chat/user for confirmation. | COMPLIANT |
| 6. Trinity / manifest / scope-keyword correct after renumber | Trinity: root trinity at C2 (was C3), project-template trinity at C3 (was C4) — both same-commit (§12 rule 5 updated). Manifest: C1/C2/C3 YES, C4/C5a/C5b NO (§12 rule 4 updated). Scope-keyword: C1/C2 pack-only, C3 none (mixed), C4 pack-only, C5a/C5b pack-chat-only (§12 rule 6 updated); no denying keyword token in any prose. | COMPLIANT |
| 7. Rules-Applied Verification Block | This table; one row per revision-prompt rule; every evidence cell carries a concrete measurement or anchored pointer; zero empty cells. | COMPLIANT |
| 8. PREFLIGHT + STOP-MEANS-STOP | `PREFLIGHT: revision complete; commit map confirmed; about to finalize` emitted in the message immediately before this finalization. No stop/halt/revert received. | COMPLIANT |

**Section-map confirmation (before → after the revision).**
- BEFORE: §0, §1, §2, §3, §4 (C1), §5 (C2), §6 (C3), §7 (C4), §8 (C5), §9 (C6), §10, §11, §12.
- AFTER: **Revision log (new, top)** + §0, §1, §2 (proof re-written), §3, §4 (C1 + Check-51 legs 1/2/4 + Check-50 + Node bump), **§5 (old C2 collapsed-note)**, §6 (C2, was C3), §7 (C3, was C4), §8 (C4, was C5), §9 (C5a + C5b, was C6 — SPLIT), §10 (held deletion, POST-C5b), §11 (gaps — GAP-1/2/3/4/5 RESOLVED/FOLDED + GAP-NEW added), §12, **§12a (new revision block)**.
- Every original section is PRESENT. No section dropped. Old §5 (C2 body) is intentionally converted to a collapsed-note per the user's C2-collapse decision.

**Read-in-full attestation (revision pass).** Read directly via the Read tool this pass:
CLAUDE.md (full, incl. all `## Pack memory`); PLAN-BD-214-TRACKER-DEFERRAL.md (full, every
section mapped); ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both pages — 853 lines, incl.
Update log / §6.3 / §6.5 / §6.6 / §10 / §10.5 / §11 / §14a); .github/workflows/validate-pack.yml
(full, 297 lines). No named document was derived rather than read.

**End of PLAN-BD-214-TRACKER-DEFERRAL.md**
