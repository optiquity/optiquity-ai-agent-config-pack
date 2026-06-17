# ADVERSARIAL REVIEW — PLAN-BD-221-CX1-REPLAN (fresh independent re-measurement)

**Reviewer:** pack-planner #2 (fresh, independent, adversarial). READ-ONLY in the
MAIN checkout. This `/tmp` doc is the only write — no repo edit, no git state change.
**Plan under review:** `/tmp/handoff-bd221-cx1-replan/PLAN-BD-221-CX1-REPLAN.md`
**Governing docs read in full:** NEW = `DESIGN-AGENT-MIGRATION-MODEL.md`;
FINAL2 = `PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md`; PACK-REVIEW-C8 / -C11 /
-C10; IMPL-REPORT-C11; OUT-OF-SCOPE-FINDINGS.md.
**Checkout (verified §0):** MAIN `v11-dev` at
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, HEAD `c4beb8d`.
NOT a worktree.
**Date:** 2026-06-17.

---

## OVERALL VERDICT: **SOUND-with-corrections**

The plan's two foundational state-corrections are CONFIRMED by independent
re-measurement (CX1 unwritten; validate-pack green default + DEEP). The commit
sequence, manifest co-ownership handling, scope keywords, green-stays-green
model, disjointness, and the C9/C10 saved-patch mechanism all hold up under
adversarial re-measurement. The CX1 6-file set is essentially complete and
correctly dispositioned (three-way.sh VERIFY-ONLY is right). The grep-zero
allowlist (POQ-C11-1) is sized measure-then-bound with the correct re-measure
caveat.

**Corrections required before coder spawn (none is a re-sequencing or a frozen-
decision conflict):**
- **C-1 (MUST):** the CX1 §3.1-row-6 Group-6 test gap — Group 6 runs
  `_v10_to_v11_retire_gemini` in ISOLATION (a subshell, hand-built `.gemini`,
  no bundle install / no custom-lift). Adding a "custom landed in the bundle"
  assertion to Group 6 AS-CONSTRUCTED would FAIL. The plan must restructure
  Group 6 (or add a new group) to exercise the lift step, OR fold the lift into
  `_v10_to_v11_retire_gemini`. Surfaced below with the exact code evidence.
- **C-2 (SHOULD):** CX1 §6.3 must state EXPLICITLY that the custom-LIFT (§6.3B)
  is a DIRECT `cp` (NOT engine-routed), because `customization_preserve`'s
  `custom-agent` branch returns `removed-everywhere` (NO copy) when `ours` is
  absent — so an engine-routed lift would silently no-op on v10→v11.
- **C-3 (SHOULD):** the C8-redo prompt must also note that C8-review NIT-#2
  (classifier doesn't match `.agents-plugin/...`) is RESOLVED by CX1's keystone
  classifier legs — so the class-7/8 header surface-vs-classifier framing
  changes. The plan §3.4 names only the SHOULD (relocate-into-bundle), not the NIT.
- **C-4 (SHOULD):** the C9 saved patch ACTIVELY WRITES `(4)` on a converted
  README line (`.agents-plugin/pack-agents/agents/ ... (4)`). POQ-C9-1 (true
  count = 5) is user-directed out-of-scope, but the plan must explicitly tell
  the C9 reviewer this `(4)` is a carried-forward out-of-scope token (NOT a
  net-new C9 defect) so the bounded cycle doesn't flag it.
- **C-5 (NIT):** the CX1 init-project §3.1-row-3 "drop forced pack-agent so the
  bundle leg self-classifies" — the plan should note the LOOSE legs (L1313-1314,
  `.claude`/`.codex/agents` forced `pack-agent`) are LEFT AS-IS, and say WHY
  (loose `x-` are already preserved-in-place by the engine elsewhere; the bundle
  is the only dir that mixes pack + custom in one swept dir). Avoids a coder
  over-reach.

None of these blocks the plan; each is a precision fix to a coder/reviewer
prompt or a one-line plan clarification. The DAG, the 6 frozen OQs, and the
fix-forward posture are all realizable and correctly held fixed.

---

## SECTION 1 — §3.1 THE TWO STATE-CORRECTIONS (re-verified independently)

### §3.1(a) Is CX1 genuinely NOT committed? — **CONFIRM**

**Empirical-Evidence Block AEB-1**
- **Command:** `git rev-parse --short HEAD`; `git log --oneline -20`;
  `git log --oneline --all | grep -i "cx1"`.
- **Output (verbatim, key):** HEAD = `c4beb8d` on `v11-dev`;
  `git log --all | grep -i cx1` → `NO CX1 IN LOG (any branch)`. Latest BD-221
  feat commit = `3ebbeaa feat: v11 — BD-221 C7 persona-contracts Antigravity
  conversion + migrator Antigravity-bundle install (pack-only)` (+ audit
  `bc7e762`). The committed cluster is **C0…C7** (subjects confirm: C0 `f68f655`
  project skills re-land … C7 `3ebbeaa` persona-contracts + migrator bundle).
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** CX1 is unwritten; C0-C7 are committed-but-unpushed.
- **Conclusion:** SUPPORTED. The plan §0.2 correction is CORRECT.

### §3.1(b) Is validate-pack GREEN at HEAD (default + DEEP)? — **CONFIRM**

**Empirical-Evidence Block AEB-2**
- **Command:** `python3 scripts/validate-pack.py` (default);
  `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP). [NOTE: there is
  NO `--deep` flag — `--help` shows only `--only-check`. DEEP = the
  `PACK_VALIDATE_DEEP=1` env var, which activates Check 49's faithfulness leg.]
- **Output (verbatim):** default → `PASSED — all checks clean`, **exit 0**;
  DEEP → `PASSED — all checks clean`, **exit 0**, with `Check 49 — 227 entries
  byte-faithful (codec-lossless + parse-faithful) …`. `grep -c OK:` (DEEP) = 236.
  Check 59: `CHECK_REGISTRY has 59 entr(y/ies)`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** the cluster reached green at C4 and stayed green through
  C5/C6/C7 + the BD-189 docs commits. The DEEP run additionally exercised the
  227-entry faithfulness leg (green). The plan §0.3 "green-stays-green, NEW=∅"
  regime is CORRECT — the FINAL2 62-line march-to-green-point model is over.
- **Conclusion:** SUPPORTED. The plan §0.3 correction is CORRECT.

**Corroboration (AEB-2b):** `bash test-fixtures/build.sh --verify` →
all 6 fixtures `OK` (v10-minimal / v10-realistic-ot / v11-realistic-ot /
v11-flat-file / v11-tracker-on / existing-project-mid-dev all match manifest).
This proves the committed fixtures are consistent with the manifest at HEAD — an
independent confirmation that the green baseline is real, not a stale-manifest
mask. **NOTE:** the C11 review's M-1 reported `build.sh --verify` RED at
`bc7e762`; that RED was the C11 working-tree state, NOT committed HEAD. At
COMMITTED `c4beb8d` the manifest IS consistent (the F-1/C7-drift the C11 coder
flagged was a working-tree artifact; the committed manifest verifies clean).

**Verdict §3.1: BOTH state-corrections CONFIRMED. The plan's foundation is sound.**

---

## SECTION 2 — §3.2 CX1 FILE SET (6 files) — COMPLETE? any missing / any not needed?

Re-measured the committed code at HEAD for each of the 6 + the prompt's 7th.

### Row 1 — `scripts/lib/customization-preserve.sh` (classifier legs) — **CONFIRM (needed)**

**AEB-3:** `customization_classify` (L146-180) has legs for `.claude/.codex/
.gemini/agents/x-*` → `custom-agent` (L167-168) and `.../*.md` → `pack-agent`
(L169-170), but **NO `.agents-plugin/` leg** — bundle paths fall to the `*)
generic` catch-all (L177). Docstring (L20-22) lists exactly `custom-agent,
pack-agent, custom-script, pack-script, generic`. Adding the two legs (returning
EXISTING tokens) requires the docstring update + the test pin (rows 7). The new
legs introduce NO new disposition token (the `_cp_disposition_for` map L194-208
is unchanged). **Verified:** `customization-preserve.sh` is NOT a Check-56
verb-parity surface (`_CHECK_56_VERB_PARITY_SURFACES` = trinity ×3 / PACK-MEMORY-
RATIONALE / commit-discipline ×3 / pack-coder ×3) → the leg cannot break Check 56.
Conclusion: SUPPORTED — needed, correctly dispositioned.

### Row 2 — `scripts/migrate-v10-to-v11.sh` (bundle block + lift + retire msg) — **CONFIRM (needed)**

**AEB-4 (the D1 non-clobber, measured):** the bundle block (L362-389) is:
```
bundle_dest="$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/$rel"
if [[ ! -f "$bundle_dest" ]]; then          # ← L368 non-clobber (D1)
    mkdir -p "$(dirname "$bundle_dest")"
    cp "$bundle_file" "$bundle_dest"
fi
```
and the count guard (L379-388) is PRESENCE-only ("Assert every PACK bundle agent
is PRESENT … project extras are allowed"). It iterates `bundle_src` (= the PACK
source) only — never reads the departing `.gemini/agents/`. So D1 (non-clobber)
and D2 (no custom-lift) are both LIVE. The retire message
(`_v10_to_v11_retire_gemini`, L527-538) says: *"Review it for any customizations
you want to re-create as Antigravity skills under `.agents/skills/`"* — the exact
"manually re-create" wording §6.3(C) rewrites. Conclusion: SUPPORTED — all three
sub-changes (A bundle-via-engine; B lift; C retire-msg) are real, not no-ops.

### Row 3 — `scripts/init-project.sh` (`--update` bundle leg self-classify) — **CONFIRM (needed) + C-5**

**AEB-5:** `cmd_update` bundle leg = `_cmd_update_iter_dir
"project-template/.agents-plugin/optiquity-agents/agents"
".agents-plugin/optiquity-agents/agents" pack-agent` (L1316-1317). The forced
3rd arg `pack-agent` is passed straight to `customization_preserve "" … "$cls"`
(L1162), where `[[ -z "$class" ]] && class=$(customization_classify "$rel")`
(L403) — so dropping the forced class self-classifies per-file. **REALIZABLE.**
**C-5 (NIT):** the LOOSE legs L1313-1314 (`.claude`/`.codex/agents` forced
`pack-agent`) are LEFT AS-IS by the plan but the plan does NOT say so or say
WHY. The plan should state: leave the loose legs forced (loose `x-` agents are
NOT in the swept pack-source dir — the pack ships no `x-*` under
`project-template/.{claude,codex}/agents/`, so the loose sweep never encounters a
client `x-`; the bundle dir is the only one where the swept set could mix
pack+custom in a v11→v11 re-bump). Otherwise a coder may "consistency-fix" the
loose legs and change behavior. **fresh-init `stage_s2_agents` (L433-466)
UNCHANGED** — verified it is the path build.sh runs (L1540 call) and is NOT
touched by row 3. Conclusion: SUPPORTED with C-5.

### Row 4 — `scripts/lib/three-way.sh` (VERIFY-ONLY) — **CONFIRM (correctly NOT a change)**

**AEB-6:** `three-way.sh` dispositions (L29-56) include `new-file-in-pack` (base
absent, ours absent, theirs present → copy) and `project-shadows-new-pack` (base
absent, ours present, theirs present → classify by ours-vs-theirs). On a v10→v11
migration the bundle dest (`ours`) is ALWAYS absent (the client has no
`.agents-plugin/`) → `new-file-in-pack` → clean add. The disposition logic is
CORRECT for CX1's base-absent path with NO edit. The plan's VERIFY-ONLY call
(§3.1 row 4) is RIGHT. The RISK-2 MAINTAINER-CHECK-NEEDED hedge (if the coder
finds a real edit) is the correct posture. Conclusion: SUPPORTED — VERIFY-ONLY
is correct; the 7th prompt-file is genuinely a no-edit verify.

### Row 5 — `scripts/persona-contracts/contract-migration.sh` — **CONFIRM (needed)**

**AEB-7:** the bundle block (L183-216) asserts ADDITIVE presence: comment L183-
186 "installs the whole client plugin bundle **additively**", `t_pass "all
.agents-plugin/optiquity-agents/agents/ present post-migrate"` (L201) — PRESENCE
only, NO replace-if-different, NO custom-lift leg. The plan's row 5 (add a leg
asserting the Gemini custom `x-fakeot-domain.md` lands in the bundle) is needed.
Conclusion: SUPPORTED. (Plan cites L184-214; measured block is L183-216 — close,
non-load-bearing line drift.)

### Row 6 — `scripts/tests/test-migrate-v10-to-v11.sh` Group 6 — **CHALLENGE → C-1 (MUST)**

**AEB-8 (the gap):** Group 6 (L420-460) builds a hand-made `.gemini` tree and
runs ONLY the retire helper in a subshell:
```
mkdir -p "$G6T/.gemini/agents" …
echo "x-custom agent body" > "$G6T/.gemini/agents/x-ot-domain.md"
( … source "$MIGRATE_SH"; _MIGRATOR_TARGET="$G6T"; _v10_to_v11_retire_gemini )
```
It asserts the BACKUP at `gemini-retired-docs/.gemini/agents/x-ot-domain.md`
(L447). **It does NOT run the bundle install (§6.3A) NOR the custom-lift (§6.3B)
— those live in `_v10_to_v11_install_v11_artifacts` / a new pre-retire step, NOT
in `_v10_to_v11_retire_gemini`.** So the plan's row-6 instruction "ADD an
assertion that the custom ALSO landed in `.agents-plugin/optiquity-agents/agents/
x-ot-domain.md`" would FAIL when added to Group-6-as-constructed: that subshell
never lays down a bundle. **Correction C-1:** the CX1 plan must EITHER
(i) restructure Group 6 to invoke the lift step (e.g. call the new pre-retire
lift helper, OR a slimmed install path) before asserting the bundle-landing, OR
(ii) add a SEPARATE group that exercises the lift step, OR (iii) fold the lift
INTO `_v10_to_v11_retire_gemini` (so the existing Group-6 subshell exercises it).
Whichever the coder chooses, the plan's row-6 one-liner ("ADD an assertion to
Group 6") under-specifies the test wiring and will trip the coder's PREFLIGHT.
The HARD behavioral check (§7.2, full migrator vs a `/tmp` clone) DOES exercise
the real end-to-end path and is the right backstop — but the row-6 unit
assertion needs the wiring fix. Conclusion: NOT-SUPPORTED as written; needs C-1.

### Row 7 — `scripts/tests/test-customization-preserve.sh` (bundle classify cases) — **CONFIRM (needed)**

**AEB-9:** Group 1 (L48-72) pins positive path→class assertions (e.g. L63
`.claude/agents/x-foo.md → custom-agent`, L65 `pack-reviewer.md → pack-agent`).
It does NOT pin a TOTAL class-count, so adding `.agents-plugin/...` bundle cases
(returning existing tokens) breaks nothing. Group 5 (L287+) already covers the
legacy `.gemini/` custom-agent classification. The plan's row 7 (add bundle
classify + replace-if-different + preserve-`x-` cases) is the correct
enumerate-encoding-surfaces lock-step partner to the classifier leg. Conclusion:
SUPPORTED.

### Are there OTHER surfaces CX1 must touch that the plan MISSED?

Re-measured the candidate consumers the prompt named:
- **`migrator-manifest.sh`** — its `_manifest_sweep_one_dir` routes swept dirs
  through `customization_preserve` (L505/L516). It does NOT hard-code the bundle
  dir; the bundle is installed by the dedicated block in `migrate-v10-to-v11.sh`
  (Option A2 keeps it there). **No edit needed** IF the plan stays with A2 (it
  does). Had the plan chosen A1 (add a `migrator_directory_sweeps` row), it would
  need a sweep-row-format change — A2 correctly avoids that. CONFIRM the A2 choice.
- **`add-capability.sh`** — FINAL2 assigned its `.gemini/.env` touch + banner to
  **C3 (committed)**. Not a CX1 surface. Verified not needed for the agent fix.
- **`customization-report.sh` / dispositions** — NEW §6.1 row 4 says NONE
  expected (tokens already covered). The new legs return existing tokens → no
  report change. CONFIRM (no edit).
- **`detect.sh`** — the existing-install classify path. NEW §6.1 does not list it
  as an agent-migration change; it was converted in C3 (committed). Not a CX1
  surface. CONFIRM. (Also relevant: `detect.sh` IS copied into fixtures by init
  S11 L997 — but CX1 does not touch it, which is WHY CX1's manifest stays empty.)
- **`pack-ops/MERGE-STRATEGY.md` class 7/8 prose** — correctly EXCLUDED from CX1
  and assigned to C8-redo (scope-coherent split; the doc is `pack-only` but a
  DOC, sequenced after CX1 so it describes the landed code). CONFIRM the split.

**Verdict §3.2:** the 6-file set is COMPLETE and correctly scoped; three-way.sh
(the 7th) is correctly VERIFY-ONLY. No missing surface. The A2 mechanism choice
is correct (avoids the A1 sweep-row-format change). One MUST correction (C-1, the
Group-6 test wiring) and one NIT (C-5, the loose-leg note).

---

## SECTION 3 — §3.3 COMMIT SEQUENCE (CX1→C9→C10→C8→C11→C12→C13) — deps & ordering

### The two real ordering constraints (everything else is free) — **CONFIRM**

**AEB-10 (disjointness, measured):** every content commit touches a disjoint
file set — there is NO file in two content commits:
- CX1: `scripts/{lib/customization-preserve.sh, migrate-v10-to-v11.sh,
  init-project.sh, persona-contracts/contract-migration.sh, tests/test-migrate-
  v10-to-v11.sh, tests/test-customization-preserve.sh}`.
- C8: `pack-ops/{PACK-AGENTS,MERGE-STRATEGY,OPTIONAL-FEATURES,PACK-MEMORY-
  RATIONALE,DRY-RUN-MIGRATION,BOUNDARY-DEFINITION,CONCEPTUAL-REVIEW-METHODOLOGY}.md`.
- C9 (saved patch, 12 files): `.{agents,claude,codex}/skills/{boundary-
  investigation,commit-discipline,implementation-report}/SKILL.md`, `LICENSE.md`,
  `QUICKSTART.md`, `README.md`.
- C10 (saved patch, 7 files): `project-template/{.codex/config.toml,
  .codex/config.toml.example,README.md,scripts/activate-capability.sh,
  skills/audit-methodology/SKILL.md,skills/boundary-investigation/SKILL.md}`,
  `test-fixtures/manifest.txt`.
- C11: `supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY,SETUP-NEW,CLI-PM-SETUP,
  SETUP-EXISTING,DEPENDENCIES,MIGRATION-v10-to-v11}.md` + DELETE MIGRATION-v8-to-
  v9.md + manifest.
- **Note (no overlap trap):** C9 edits pack-root `.{agents,claude,codex}/skills/
  boundary-investigation` while C10 edits `project-template/skills/boundary-
  investigation` — DIFFERENT files (pack-root vs project-template). No collision.
- **HEAD/date:** `c4beb8d`, 2026-06-17. **Conclusion:** SUPPORTED — file-level
  disjoint; the only inter-commit coupling is the CO-OWNED manifest (C10+C11).

The TWO ordering constraints are therefore SEMANTIC, not file-overlap:
1. **CX1 before C8 and C11** — the C8 MERGE-STRATEGY class-7/8 prose and the C11
   migration narrative must describe CX1's CODE. Their reviewer step VERIFIES
   the prose against the LANDED code (§7.3). The verification TARGET must exist
   → CX1 first. **CONFIRM** (this is a real verify-dependency, not cosmetic).
2. **C10 before C11** — manifest cumulative co-ownership (§4 below). **CONFIRM.**

### Does C8/C11 truly need to be AFTER CX1? — **CONFIRM (challenged and upheld)**

I challenged this: the NEW design fully specifies the END STATE, so a coder
COULD author C8/C11 prose from the design doc without CX1 landed. BUT the
bounded review/fix cycle VERIFIES the prose against the LANDED code (the C8
reviewer reads `migrate-v10-to-v11.sh` + `customization-preserve.sh`; the C11
reviewer reads the migrator to confirm post-migration surfaces match). If CX1 is
NOT landed, the reviewer reads C7's (defective) code and would FLAG the prose as
a mismatch — re-creating the exact C8-review SHOULD finding the abandonment was
meant to escape. So CX1-first is REQUIRED for the verification to pass, not
merely tidy. SUPPORTED.

### Does C10 truly need to be BEFORE C11? — **CONFIRM**

C10 and C11 both drive the 3 v11 fixture SHAs (§4 AEB-11/12). The plan commits
C10 with its post-C10 manifest, then C11 regenerates the cumulative post-C10+C11
manifest in MAIN. If C11 landed BEFORE C10, the C11 manifest would reflect only
C11's edits, and C10 would then need its own cumulative regen — same machinery,
reversed. The C10-saved-patch already CARRIES a post-C10 manifest (hardcoded
SHAs), so committing C10 first and letting C11 regenerate cumulatively is the
path of least friction. SUPPORTED. (A cleaner micro-optimization, C-OPT below.)

### Any forward dependency / cleaner order? — **one micro-optimization (C-OPT, NIT)**

The plan interleaves C8 (pack-only, step 4) BETWEEN C10 (step 3) and C11 (step
5). C8 touches no fixture input (pack-ops not copied into fixtures — verified
`find test-fixtures/v11-realistic-ot -path '*pack-ops*'` → empty), so C8 does
NOT disturb the manifest and the interleave is HARMLESS. But the two manifest
co-owners (C10, C11) would read more cleanly ADJACENT (…C10 → C11 → C8…), so the
post-C10 manifest window is not spanned by an unrelated commit. **C-OPT (NIT,
optional):** move C8 to AFTER C11 (CX1→C9→C10→C11→C8→C12→C13). This keeps the
two project-only manifest commits adjacent and groups the two pack-only doc
commits (C8 + C9 are both pack-only). NOT required — the plan's order is correct;
this is purely a readability/least-surprise nicety. No frozen-decision conflict
(OQ-4 fixes WHICH commits redo vs apply-from-patch, not their relative order).

**Verdict §3.3: the sequence is SOUND. Both ordering constraints are real and
correctly applied. One optional micro-reorder (C-OPT).**

---

## SECTION 4 — §3.4 MANIFEST CO-OWNERSHIP (C10 AND C11 both change v11 fixtures)

### Do BOTH C10 and C11 genuinely change the v11 fixtures? — **CONFIRM**

**AEB-11 (C11 → fixtures, measured):** `init-project.sh` S6 (L677-693) copies
`$PACK/supporting-docs/METHODOLOGY.md` and `$PACK/supporting-docs/INSTALL-
PROCEDURES.md` into each fixture's `docs/pack/` (verified the two `cp`/
`existing_classifier_copy` blocks). C11 edits BOTH files → all 3 v11 fixture SHAs
drift. This is exactly the C11-review M-1 BLOCKER root-cause (independently
re-traced). SUPPORTED.

**AEB-12 (C10 → fixtures + manifest, measured):** the C10 saved patch CARRIES
`test-fixtures/manifest.txt` whose hunk changes ONLY the 3 v11 SHAs:
```
-v11-realistic-ot  83fa42ec…   +v11-realistic-ot  49a4b801…
-v11-flat-file     8176d319…   +v11-flat-file     688fbff2…
-v11-tracker-on    6f41c7eb…   +v11-tracker-on    67fa09c0…
```
v10-minimal / v10-realistic-ot / existing-project-mid-dev UNCHANGED. The patch's
manifest from-index = `2664985`, which == the CURRENT `git ls-files -s
test-fixtures/manifest.txt` blob (`2664985e…`) → the C10 patch applies CLEAN
against HEAD. SUPPORTED. (This also confirms the C10-review "manifest changes
only the 3 v11 SHAs" verdict.)

### Does CX1 genuinely NOT change fresh-init fixtures? — **CONFIRM**

**AEB-13:** build.sh builds v11 fixtures via `_run_v11_init` (L126 → fresh
`init-project.sh "$target"` → `stage_s2_agents` L1540, the path CX1 does NOT
touch). CX1's init edit is the `--update` leg (L1316) only. The fixtures contain
NEITHER `migrate-v10-to-v11.sh` NOR `customization-preserve.sh` (verified `find
… → empty`). The only pack-side files init copies INTO a fixture are
`scripts/pack-help.sh` (L993) and `scripts/lib/detect.sh` (L997) — CX1 touches
NEITHER. `grep -c agents-plugin test-fixtures/manifest.txt` → 0 (manifest tracks
no migrator/bundle line). Therefore CX1's `build.sh --all --clean` produces an
EMPTY manifest diff. SUPPORTED — RC9-verify-empty is correct; the plan's
"do-NOT-stage-unless-non-empty" + STOP-if-non-empty is the right guard.

### Is the cumulative handling correct + sufficient? — **CONFIRM, with one sharpening (C-6, SHOULD)**

**AEB-14 (cross-CX1 validity of the C10 hardcoded SHAs):** the C10 patch's
post-C10 SHAs were computed at `bc7e762`. The plan orders CX1 BEFORE C10. Since
CX1 changes no fixture input (AEB-13), `build.sh` post-CX1 produces the SAME
base v11 SHAs as `bc7e762`, so the C10 patch's hardcoded post-C10 SHAs remain
VALID after CX1 lands. ALSO: `bc7e762..c4beb8d` (the BD-189 docs landed since the
worktrees were cut) touched ONLY `backlog/*` + `maintenance-docs/*` (verified
`git diff --name-only bc7e762 c4beb8d`) — no fixture input — so the C10 SHAs are
valid at `c4beb8d` too. SUPPORTED.

**C-6 (SHOULD — sharpen the §5 step-2 procedure):** the plan §5 says "C11
regenerates the cumulative post-C10+C11 manifest in MAIN." Make the procedure
EXPLICIT and ORDER-BOUND: the C11 manifest regen MUST run in MAIN *after* C10 is
COMMITTED (so the project-template C10 edits are on disk), NOT in the C11
isolated worktree (which bases at HEAD-without-C10 and would produce a
post-C11-only manifest that DROPS C10's deltas → a silently-wrong manifest that
`build.sh --verify` would then accept as "correct" while it has lost C10's
fixture state). The plan DOES say "discard the isolated-worktree manifest;
regenerate in main" (§5 step 2) — good — but the coder prompt must state the
ORDER GATE crisply: *C10 committed → C11 prose applied in main → `build.sh
--all --clean` in main → stage the resulting manifest into C11*. This is the
single most fragile step in the whole plan; spell it out.

### Any OTHER commit that touches a fixture input? — **CONFIRM none missed**

Re-checked CX1 (no), C8 (pack-ops, no), C9 (README/QUICKSTART/LICENSE +
pack-root skills — none are fixture inputs; verified the C9 patch carries NO
manifest hunk → `grep manifest C9-final.patch` → empty), C13 (backlog +
README version row — no). **Only C10 + C11 are fixture-input commits.** The
plan's §5 enumeration is COMPLETE. SUPPORTED.

**Verdict §3.4: manifest co-ownership is CORRECTLY identified and handled. CX1
empty-manifest claim holds. Add C-6 (the order-gate sharpening) to the C11 prompt.**

---

## SECTION 5 — §3.5 DESIGN-DOC ATTRIBUTION (NEW vs FINAL2) — correct, complete, unambiguous?

### The split is well-formed — **CONFIRM**

The plan's §2 attribution table assigns each commit-part to NEW or FINAL2 and
states the reading rule: "where NEW and FINAL2 disagree about agent handling,
NEW WINS … FINAL2 governs everything that is NOT agent-migration behavior." I
re-read both docs in full and the split is CLEAN and matches reality:
- **NEW** correctly owns: the classifier legs (NEW §5.1), the migrator bundle-
  via-engine + custom-lift + retire-message (NEW §5.3 A/B/C), the init `--update`
  self-classify (NEW §5.2), the unified contract (NEW §5.0), the cross-CLI
  mapping (NEW §5.4), the base-absent benignity (NEW §3.1). All of CX1 is NEW.
- **FINAL2** correctly owns: the `.gemini`→`.agents` surface rename (C8/C9/C10/
  C11 non-agent parts), the green-point gate + grep-zero allowlist (FINAL2 §6),
  the scope keywords (FINAL2 §1), the manifest discipline, the bookkeeping
  (FINAL2 C13 / CONFIRMED-D), the MIGRATION-v8-to-v9 SPLIT (FINAL2 §3.2).
- **Hybrid parts** (correctly flagged): C8 redo (FINAL2 for the 6 other docs +
  the rename; NEW for MERGE-STRATEGY class-7/8 agent prose); C11 redo (FINAL2 for
  the 7-file rename + delete; NEW for the migration narrative custom-lift).

### ONE attribution-table imprecision — **C-7 (NIT)**

The plan §2 attribution rows cite "NEW §6.1 row 1…row 8". But the NEW design's
§6.1 is the **"Surface-by-surface change list" with 10 rows** (rows 1-10), NOT 8;
and the design ALSO has §5.1-§5.4 (the model) which is where the contract /
classifier / migrator changes are SPECIFIED. The plan's row citations conflate
"§6.1 row N" (blast-radius table) with the §5.x specification. This is a
COSMETIC cross-ref imprecision — the SUBSTANCE each row points at is correct
(e.g. "CX1 classifier legs → NEW §5.1 + §6.1 row 1" is right: §5.1 specifies the
legs, §6.1 row 1 lists the surface). **C-7 (NIT):** when the plan is handed to a
coder, ensure the coder reads NEW §5.x for the HOW (the design spec) and uses
§6.1 only as the surface checklist — the plan's prose already does this ("§5.1
'Engine-level fix' + §6.1 row 1"), so no functional fix needed; just don't let a
coder treat "§6.1 row N" as the spec. No part is left UNATTRIBUTED.

### Any part where governance is unclear? — **none found**

I checked the seams: (a) the retire-message rewrite — NEW §5.3(C) owns the
wording, FINAL2 owns nothing here (it predates the custom-lift); clean. (b) the
`gemini-retired-docs/` backup narrative in C11 — NEW §5.3(B)/(C) owns "backup,
customs auto-lifted"; FINAL2 §3 C11 owns "add the migration section + OQ-3
surface list." The plan §3.5 correctly splits these. (c) the C8 MERGE-STRATEGY
class count (12→11, the `gemini-env` removal) — this is FINAL2's rename work (C3
removed `gemini-env` from the CODE; the DOC still shows 12 at HEAD — see AEB-15),
NOT a NEW-design item; the plan §3.4 implicitly folds it into "the other … docs
conversion (FINAL2)". CONFIRM clean.

**Verdict §3.5: the attribution split is CORRECT, COMPLETE, and unambiguous for
every commit-part. One cosmetic cross-ref imprecision (C-7) — no functional gap.**

---

## SECTION 6 — §3.6 SCOPE KEYWORDS (Check 36) — each commit's diff vs its keyword

**AEB-16 (Check-36 path model, measured):** `_PROJECT_SIDE_PATH_PREFIXES =
("project-template/", "supporting-docs/")` (validate-pack.py L3992);
`_SCOPE_NEUTRAL_GENERATED_PATHS` includes `"test-fixtures/manifest.txt"`
(L4002-4003). `_subject_has_keyword` (L4088+) matches any keyword token
boundary-anchored ANYWHERE in the subject (case-insensitive). HEAD-only range by
default (`PACK_CHECK_36_RANGE=HEAD~0..HEAD` → `git log -1`).

Per-commit keyword verdict (projected diff vs keyword):

| Commit | Diff paths | Keyword | Verdict |
|---|---|---|---|
| CX1 | `scripts/…` only (+ manifest if non-empty, but empty) | `pack-only` | **CONFIRM** — no project-side prefix path |
| C8 | `pack-ops/*.md` (+ manifest, empty) | `pack-only` | **CONFIRM** — pack-ops is NOT a project-side prefix |
| C9 | `README/QUICKSTART/LICENSE` + pack-root `.{agents,claude,codex}/skills/*` | `pack-only` | **CONFIRM** — none under project-template/ or supporting-docs/ |
| C10 | `project-template/*` + `test-fixtures/manifest.txt` | `project-only` | **CONFIRM** — manifest rides scope-neutral; all else project-template/ |
| C11 | `supporting-docs/*` + DELETE + `test-fixtures/manifest.txt` | `project-only` | **CONFIRM** — supporting-docs/ is a project-side prefix; manifest scope-neutral |
| C13 | `backlog/*` + `_toc.md` + README version row | `pack-chat-only` | **CONFIRM** — bookkeeping set only |

**AEB-16b (manifest scope-neutral ride, decisive):** because `test-fixtures/
manifest.txt ∈ _SCOPE_NEUTRAL_GENERATED_PATHS`, it does NOT count as a Check-36
offender in EITHER a `pack-only` (CX1/C8/C9) or `project-only` (C10/C11) commit.
This is the key enabler that lets C10/C11 keep `project-only` while carrying the
manifest. SUPPORTED.

### Keyword-token-trap risk in any subject — **CONFIRM the plan's guard (RISK-8)**

The plan §10 RISK-8 correctly says: each subject carries AT MOST its claimed
keyword, trailing position, no keyword token in prose. The committed C0-C7
subjects already follow this (e.g. `… (pack-only)`, `… (project-only)`). The
HIGH-RISK subjects to watch:
- C8: must NOT write "convert the project-side … prose" with the bare token
  `project-only` in prose (a denying token wins → Check 36 fails the pack-only
  claim). Use neutral wording for any cross-reference.
- C11: the subject describes supporting-docs (project) work; must NOT contain
  `pack-only` anywhere (e.g. don't write "pack-only MERGE-STRATEGY untouched").
- C13 (`pack-chat-only`): per the committed pattern, fine.

**Verdict §3.6: every keyword assignment is CORRECT vs its projected diff. The
scope-neutral manifest ride is verified. The keyword-token-trap guard is sound.**

---

## SECTION 7 — §3.7 GREEN-STATE EXPECTATION (every remaining commit keeps green, NEW=∅)

### Is the green-stays-green model correct? — **CONFIRM (challenged hard)**

I challenged the claim that no remaining commit introduces a transient red.

**AEB-15 (the key insight — validate-pack does NOT gate the prose conversion):**
at HEAD `c4beb8d`, with validate-pack GREEN, the repo STILL carries:
- 14 `.gemini/` PATH hits in `pack-ops/*.md` (un-converted — C8's work);
- `pack-ops/MERGE-STRATEGY.md` STILL has **12** `### N.` class headers incl.
  class 6 `gemini-env` (L141) and `.gemini/settings.json` (L77) — the C8 redo's
  target. (The C8-REVIEW saw 11 classes because that was the ABANDONED C8
  WORKTREE draft, never committed; the COMMITTED doc at HEAD is the original 12.)
- 29 `.gemini/` PATH hits in `supporting-docs/*.md` (un-converted — C11's work).

Yet validate-pack exits 0. **This proves validate-pack does NOT gate the
`.gemini`→`.agents` prose conversion in pack-ops/supporting-docs.** Therefore:
- C8 clears NO validate fail-line and introduces NO validate fail-line → green.
- C11 clears NO validate fail-line and introduces NO validate fail-line → green.
- The COMPLETENESS of the conversion is proven ONLY by the C12 grep-zero gate,
  NOT by validate-pack. The plan §7.4 correctly relies on the grep-zero gate for
  this. The green-stays-green model is INTERNALLY CONSISTENT precisely because
  validate-pack tolerates unconverted prose — the cluster is green NOW (with
  unconverted docs) and stays green through the conversion.
- **HEAD/date:** `c4beb8d`, 2026-06-17. **Conclusion:** SUPPORTED — NEW=∅ holds
  for every remaining commit; no transient red is introduced.

### Specific transient-red challenges — all CLEAR:

- **CX1** — touches the classifier (not a Check-56 surface), the migrator, the
  `--update` leg, persona-contract, tests. None is validate-gated for content
  beyond the lockstep tests it carries (those move in-commit). The HARD risk is
  a test REGRESSION (a CX1 test edit that the migrate/customization shard then
  fails) — caught by the coder's full-suite PREFLIGHT + the reviewer's
  independent full-suite run. NEW=∅ for validate-pack; the tests are the gate.
- **C8** — verified Check 40/44/45/46/56 are the stay-green set; the class-7/8
  prose edit must NOT alter the Check-56 verb set (PACK-MEMORY-RATIONALE is a
  verb surface but MERGE-STRATEGY is NOT) and must NOT drop a bare cross-ref
  (Check 40, 10 docs). The plan §7.3 names these. No transient red.
- **C9** — edits `.{agents,claude,codex}/skills/commit-discipline/SKILL.md`
  which ARE Check-56 surfaces. **AEB-17:** the C9 patch's commit-discipline
  hunks are prose conversions (`.gemini/skills/`→`.agents/skills/`;
  `.gemini/agents/`→`.agents-plugin/pack-agents/agents/`; drop "Gemini's
  @<agent> invocation") — they do NOT touch the 28-verb denylist content. So
  Check 56 stays green. SUPPORTED (this is why the C9 patch was review-CLEAN).
- **C10** — `project-template/.codex/config.toml` is Check-2-validated (TOML
  well-formed); the cross-ref edit keeps it valid (C10-review CLEAN). No red.
- **C11** — supporting-docs prose; the DELETE of MIGRATION-v8-to-v9.md trips no
  gate (Check 48 soft-advisory, scans only backlog/changelog, basename not in
  `_REMOVED_DOC_BASENAMES`). No red. The ONLY C11 gate is M-1 (manifest) →
  handled by §5 + C-6.

### Re-verify the C7→CX1 contract/test interaction stays green — **CONFIRM**

CX1 supersedes C7's agent handling but C7 stays committed (FIX-FORWARD). The
persona-contract (C7's `contract-migration.sh`) currently asserts ADDITIVE
presence (AEB-7); CX1 row 5 CHANGES that assertion to assert custom-lift +
replace-if-different. Because CX1 lands the code AND the contract edit in the
SAME commit (lock-step), there is no window where the contract asserts the old
behavior against the new code. SUPPORTED — no C7→CX1 green gap.

**Verdict §3.7: the green-stays-green / NEW=∅ expectation is CORRECT and
adversarially upheld. validate-pack's tolerance of unconverted prose is the
reason it holds; the grep-zero gate (C12) is the real completeness backstop.**

---

## SECTION 8 — §3.8 C12 GREP-ZERO ALLOWLIST (POQ-C11-1) — measure-then-bound?

### Is the sizing right? — **CONFIRM the magnitude + the re-measure caveat**

**AEB-18 (independent magnitude, measured at HEAD pre-C11-redo):**
- `grep -rnI "\.gemini/" supporting-docs/*.md | wc -l` → **29** at HEAD (the
  FULLY un-converted state). After the C11 redo converts the install/setup
  prose, only the migration-source refs remain — the C11-review measured 13
  `.gemini/` PATH lines (POQ-C11-1a) at `bc7e762`.
- `grep -rnI "gemini-retired-docs" supporting-docs/*.md | wc -l` → **0** at HEAD
  (the holding-dir narrative is ADDED by the C11 redo; the C11-review measured 10
  occurrences in the held draft, POQ-C11-1b).
- **HEAD/date:** `c4beb8d`, 2026-06-17.

The plan §8 carries the C11-review's 13 + 10 as the EXPECTED MAGNITUDE and
explicitly states the SIZING CAVEAT: "these exact file:line counts are from
PACK-REVIEW-C11 at `bc7e762` (the ABANDONED C11 worktree) … the redo re-authors
these docs, so the line numbers WILL drift … size the C12 allowlist
measure-then-bound at C12 TIME against the ACTUAL redone C11 content — do NOT
hard-code the 13/10 counts." **This is the CORRECT application of
`ci-guard-measure-then-bound` + `rename-plans-measure-then-bound`:** the bound is
the PROPERTY ("every `.gemini/`/`gemini-retired-docs/` hit must be a
migration-source ref → KEEP; any other hit → STRIP"), not the frozen count.
SUPPORTED.

### Will the REDONE C8/C11 (custom→bundle narrative) add/remove mandated refs? — **CONFIRM (and a sharpening, C-8 NIT)**

The C11 redo's NEW narrative (customs AUTO-LIFTED into the bundle;
`gemini-retired-docs/` = BACKUP, NOT "manually re-create") will RE-WORD the
migration sections vs the held draft. This MAY shift the exact `.gemini/`-ref
count (e.g. if the new wording says "your `.gemini/agents/x-*` customs are copied
into `.agents-plugin/optiquity-agents/agents/`" it ADDS a `.gemini/agents/x-*`
migration-source ref). The C8 redo's MERGE-STRATEGY class-7 prose ("relocate
into the Antigravity bundle" — now TRUE) keeps the single `.gemini/agents/x-*.md`
KEEP token (legacy-READ carve-out class 2) the C8-review already allowlisted.
**C-8 (NIT):** the plan should add to the C12 gate's IN-SCOPE set the C8 surface
(`pack-ops/MERGE-STRATEGY.md`) as well as supporting-docs — the FINAL2 Gate A/B
already scan `pack-ops` (§7.5 lists it), so the C8 migration-source `.gemini/
agents/x-*.md` KEEP token is covered. Confirm the C12 allowlist class explicitly
includes the C8 MERGE-STRATEGY legacy-READ token (FINAL2 §6 class 2 already
does — "migrator/detect legacy-READ"). No NEW allowlist class needed for C8.

### Any over- or under-allowlisting? — **CONFIRM no allowlist growth**

The plan §8 holds: Check 47 `_SANCTIONED_PACK_SIDE_SHIPPED` stays at exactly 2;
`_CHECK_43_ALLOWLIST` stays at exactly 8; the standing FINAL2 §6 classes 1-8 are
verify-only. The ONLY new class is POQ-C11-1 (mandated migration-source refs),
which admits ONLY refs that the migration narrative MANDATES (the migrator's own
prose names `.gemini/` + `gemini-retired-docs/`). This is sized to the
legitimate-set, not widened to borderline hits. **AEB-19:** verified
`_SANCTIONED_PACK_SIDE_SHIPPED` and `_CHECK_43_ALLOWLIST` at HEAD: validate-pack
Check 47 banner = "set-equality" green; Check 43 allowlist = 8 (the plan's claim
matches the green state). SUPPORTED — measure-then-bound respected; no growth.

**Verdict §3.8: the allowlist is correctly sized measure-then-bound with the
right re-measure caveat. No over/under-allowlisting. One NIT (C-8) to confirm the
C8 token is covered by the existing legacy-READ class (it is).**

---

## SECTION 9 — §3.9 WORKTREE PLAN — sound? any hazard?

### The regime — **CONFIRM**

The plan §11 worktree table: CX1 fresh worktree off HEAD; C8/C11 fresh
worktrees post-CX1 (held C8/C11 ABANDONED per OQ-4); C9/C10 apply-from-saved-
patch in main (or a fresh worktree) with a fresh reviewer post-apply; remove
after commit. This matches the live BD-219 isolation gotchas
(`worktree-isolation-mergeback-ops` memory): baseRef:head; `/tmp` patch;
orchestrator runs `git update-index -q --refresh` before `git apply`; worktrees
do NOT auto-remove (orchestrator removes); reviewer runs IN-PLACE. SUPPORTED.

### Hazard: the saved C10 patch's manifest going stale once C11 regenerates — **CONFIRM the plan's mitigation (this is C-6)**

I challenged the exact hazard the prompt names. The C10 saved patch HARDCODES
post-C10 SHAs (`49a4b8…`). When C11 regenerates cumulatively in main, the C11
commit's manifest hunk goes from the post-C10 SHAs to the post-C10+C11 SHAs —
which is CORRECT (each commit's manifest reflects the cumulative state at that
commit). The hazard is ONLY if C11's manifest is taken from its ISOLATED
worktree (based at HEAD-without-C10) → it would reflect post-C11-only, DROPPING
C10's fixture deltas, and `build.sh --verify` post-cluster would then either
fail (if it catches the drop) or — worse — the manifest would encode a fixture
state that never existed. The plan §5 step 2 + RISK-4 correctly say "discard the
isolated-worktree manifest; regenerate in MAIN post-C10+C11." C-6 (above)
sharpens the ORDER GATE. SUPPORTED with C-6.

### Hazard: C9/C10 patch staleness if other commits land first — **CONFIRM the plan's mitigation**

**AEB-20:** `git apply --check /tmp/handoff-bd221-C9/C9-final.patch` → CLEAN;
`git apply --check /tmp/handoff-bd221-C10/C10-final.patch` → CLEAN, both at
current HEAD `c4beb8d`. C9/C10 touch paths DISJOINT from CX1's `scripts/` set
(verified: `grep "^diff --git" C9 C10 | grep scripts/(lib|migrate|init|persona|
tests)` → NO OVERLAP). So landing CX1 (and C8/C9) first does NOT break the C10
patch, and landing CX1 first does NOT break the C9 patch. The plan §10 RISK-5
correctly says RE-RUN `git apply --check` immediately before each apply. The ONE
shared file is the manifest (C10 carries it, C11 regenerates it) — handled by
§5/C-6. SUPPORTED.

### Held-worktree removal — **CONFIRM (orchestrator-only; correctly surfaced)**

The 4 held worktrees (at `bc7e762`) must be removed by the orchestrator
(`git worktree remove` is a state-changing verb = agents NEVER run it). The plan
§10 RISK-7 + §11 correctly mark this MAINTAINER CHECK NEEDED / orchestrator
action. C8/C11 worktrees are ABANDONED (OQ-4) — the redo uses FRESH worktrees;
C9/C10 are apply-from-saved-patch (the saved patches are the source of truth, so
those worktrees can also be removed). SUPPORTED — correctly an orchestrator
responsibility, not an agent action.

**Verdict §3.9: the worktree plan is SOUND. The saved-C10-manifest-staleness
hazard is real but correctly mitigated (regenerate in main, never trust the
isolated manifest) — sharpen with C-6. Patches apply clean; disjoint from CX1.**

---

## SECTION 10 — FROZEN DECISIONS (§2) — realizability check (flag ONLY if unrealizable)

Per user-prescriptive-authority, the 6 OQs + FIX-FORWARD + out-of-scope deferral
are held FIXED. I did NOT re-open them; I checked ONLY for unrealizability.

| Frozen item | Realizable? | Evidence |
|---|---|---|
| OQ-1 (bundle custom from `.gemini`→`.claude` fallback; Gemini wins on divergence) | **YES** | The custom-lift (§6.3B) is a direct `cp` from `.gemini/agents/x-*` (fallback `.claude/agents/x-*.md`) into the bundle — both source files exist in a v10 project (the fixture ships `x-fakeot-domain.md` in `.claude/.codex/.gemini/agents/`, AEB per NEW §4). Realizable as a direct copy. (See C-2 — must NOT route through the engine.) |
| OQ-2 (customs coexist in the pack bundle + invariant note) | **YES** | The `x-` classifier leg (§6.2) preserves a bundle `x-` on future bumps (`custom-agent` → preserve when `ours` exists, L420-428). Invariant note (`x-` reserved for client) is a doc addition. Realizable. |
| OQ-3 (`cmp -s` byte-identity) | **YES** | `three_way_classify` uses byte equality (existing contract, L57+); no change. Realizable as-is. |
| OQ-4 (C8+C11 redo; C9+C10 from saved patches) | **YES** | C9/C10 patches apply CLEAN (AEB-20); C8/C11 redo is fresh-worktree authoring against landed CX1. Realizable. |
| OQ-5 (`agy plugin install` = RE-VERIFY doc note) | **YES** | A `<!-- RE-VERIFY at impl -->` marker in C11 docs; the C11-review S-1 flagged the install verb lacks the hedge the session verbs carry — adding it is realizable. (Client-facing markers stay BD-ref-free — confirmed in the migrator's own prose.) |
| OQ-6 (leave fresh-init count guard) | **YES** | `stage_s2_agents` count guard `bundle_count == pack_count` (L466) is NOT touched by CX1 (CX1 edits the `--update` leg only). Leaving it is the default. Realizable. |
| FIX-FORWARD (CX1 supersedes C7; C7 stays committed; no rollback) | **YES** | CX1 lands the corrected behavior on top of committed C7; the lock-step contract/test edits avoid an old-asserts-against-new window (AEB §3.7). Realizable. |
| Out-of-scope (POQ-C9-1, F-2, F-3) addressed AFTER the cluster | **YES** | All three are genuinely out of the saved-patch / redo scope (POQ-C9-1 (4)→5 is a carried-forward token; F-2 BD-leaks pre-exist; F-3 PM-CHAT.md is not in C10/C11 diff). User-directed scheduling, not unilateral deferral. **Caveat C-4:** the C9 patch ACTIVELY writes `(4)` on a converted line — the plan must tell the C9 reviewer this is carried-forward-out-of-scope, not a net-new defect. |

**No frozen decision is UNREALIZABLE.** OQ-1 carries the one implementation
subtlety (C-2: the lift is a direct cp, not engine-routed) — realizable, just
needs the explicit note. The out-of-scope deferral is user-directed (OUT-OF-
SCOPE-FINDINGS.md §C) — surfaced-not-chased, with the C-4 reviewer caveat.

---

## SECTION 11 — CONSOLIDATED CORRECTIONS (the change-list for the plan/coder prompts)

| # | Severity | Where | Correction |
|---|---|---|---|
| **C-1** | **MUST** | CX1 §3.1 row 6 / §7.2 | Group 6 runs `_v10_to_v11_retire_gemini` in ISOLATION (no bundle install / no lift); adding a "custom landed in bundle" assertion to Group-6-as-built will FAIL. Restructure Group 6 (or add a group / fold the lift into the retire helper) so the lift step is exercised before the bundle-landing assertion. The §7.2 full-migrator `/tmp`-clone check is the right end-to-end backstop but the unit assertion needs the wiring fix. |
| **C-2** | SHOULD | CX1 §6.3(B) | State EXPLICITLY that the custom-LIFT is a DIRECT `cp` (NOT engine-routed): `customization_preserve`'s `custom-agent` branch returns `removed-everywhere` (no copy) when `ours` is absent (L420-428), so an engine-routed lift silently no-ops on v10→v11. Only the PACK-bundle install (§6.3A) is engine-routed; the custom-lift is a direct copy. |
| **C-3** | SHOULD | C8-redo prompt (§3.4/§7.3) | Note that C8-review NIT-#2 (classifier doesn't match `.agents-plugin/...`) is RESOLVED by CX1's keystone classifier legs — the class-7/8 header surface-vs-classifier framing changes (the bundle path now IS classifier-matched). Don't let the redo re-introduce the old "bundle not classifier-matched" framing. |
| **C-4** | SHOULD | C9 (§3.2) | The C9 saved patch ACTIVELY WRITES `(4)` on a converted README line (`.agents-plugin/pack-agents/agents/ … (4)`). POQ-C9-1 (true count = 5) is user-directed out-of-scope; tell the C9 reviewer the `(4)` is a carried-forward token, NOT a net-new C9 defect, so the bounded cycle doesn't flag it. |
| **C-5** | NIT | CX1 §3.1 row 3 | State that the LOOSE legs (L1313-1314, `.claude`/`.codex/agents` forced `pack-agent`) are LEFT AS-IS and WHY (the pack ships no `x-*` under loose dirs, so the loose sweep never mixes pack+custom; the bundle dir is the only mixed-content swept dir). Prevents a coder consistency-over-reach. |
| **C-6** | SHOULD | §5 step 2 / C11 prompt | Sharpen the manifest order-gate: the C11 manifest regen MUST run in MAIN AFTER C10 is COMMITTED (so C10's project-template edits are on disk), via `build.sh --all --clean` in main, staging the result into C11. NEVER take the C11 manifest from its isolated worktree (it bases at HEAD-without-C10 → drops C10's deltas → a silently-wrong manifest). This is the single most fragile step. |
| **C-7** | NIT | §2 attribution table | "§6.1 row N" citations point at the NEW design's 10-row blast-radius table, not the §5.x SPEC. Cosmetic; ensure the coder reads NEW §5.x for the HOW and uses §6.1 only as the surface checklist (the plan prose already pairs them — "§5.1 … + §6.1 row 1"). No part left unattributed. |
| **C-8** | NIT | §8 C12 gate | Confirm the C12 grep-zero in-scope set includes `pack-ops/MERGE-STRATEGY.md` (it does — FINAL2 §7.5 scans pack-ops) so the C8 class-7 `.gemini/agents/x-*.md` legacy-READ KEEP token is covered by the existing class-2 (migrator/detect legacy-READ) — NO new allowlist class needed for C8. |
| **C-OPT** | NIT (optional) | §4 sequence | Optional micro-reorder: move C8 to AFTER C11 (CX1→C9→C10→C11→C8→C12→C13) to keep the two manifest co-owners (C10/C11) adjacent and group the pack-only doc commits. Harmless either way; pure readability. |

---

## OVERALL VERDICT (restated): **SOUND-with-corrections**

The plan correctly re-establishes the world (CX1 unwritten; validate-pack green
default+DEEP), correctly identifies the green-stays-green regime, correctly
sequences CX1-first with the two real ordering constraints (CX1-before-C8/C11
verify-dependency; C10-before-C11 manifest co-ownership), correctly handles the
co-owned manifest, correctly assigns scope keywords (manifest scope-neutral
ride), correctly sizes the grep-zero allowlist measure-then-bound, and holds all
6 frozen OQs + FIX-FORWARD fixed and realizable. The CX1 6-file set is complete
and correctly dispositioned (three-way.sh VERIFY-ONLY is right; the A2 mechanism
avoids the A1 sweep-row-format change). The C9/C10 saved patches apply clean and
are disjoint from CX1.

The corrections are all precision fixes to coder/reviewer prompts (C-1 the test
wiring is the only MUST; C-2/C-3/C-4/C-6 are SHOULDs; C-5/C-7/C-8/C-OPT are
NITs). None re-sequences the DAG; none conflicts with a frozen decision. After
folding C-1 (Group-6 test wiring) and C-2/C-6 (the two implementation/manifest
sharpenings) into the CX1 and C11 coder prompts, the plan is ready for the
user planner-to-coder review gate.

---

## EMPIRICAL-EVIDENCE BLOCK INDEX (all re-run independently, 2026-06-17, HEAD c4beb8d)

| AEB | Claim re-measured | Conclusion |
|---|---|---|
| AEB-1 | CX1 not committed (any branch); C0-C7 are the committed cluster | SUPPORTED |
| AEB-2 | validate-pack green default (exit 0) + DEEP (exit 0, Check 49 = 227 entries) | SUPPORTED |
| AEB-2b | build.sh --verify all 6 fixtures OK at HEAD (committed manifest consistent) | SUPPORTED |
| AEB-3 | classifier has NO `.agents-plugin` leg (bundle → generic); not a Check-56 surface | SUPPORTED |
| AEB-4 | migrator bundle block non-clobber (L368) + retire "manually re-create" msg (L527-538) | SUPPORTED |
| AEB-5 | init `--update` bundle leg forced `pack-agent` (L1316); self-classify realizable; loose legs left as-is | SUPPORTED |
| AEB-6 | three-way.sh dispositions correct for base-absent (new-file-in-pack on v10→v11) → VERIFY-ONLY | SUPPORTED |
| AEB-7 | persona-contract asserts ADDITIVE presence (L183-216) → needs the custom-lift leg | SUPPORTED |
| AEB-8 | Group 6 runs retire-helper in ISOLATION → bundle-landing assertion would FAIL (C-1) | NOT-SUPPORTED (gap) |
| AEB-9 | test-customization-preserve pins positive cases, not a class count → bundle cases safe | SUPPORTED |
| AEB-10 | all content commits file-disjoint; only manifest co-owned (C10+C11) | SUPPORTED |
| AEB-11 | init S6 (L677-693) copies METHODOLOGY+INSTALL-PROCEDURES into v11 fixtures (C11→fixtures) | SUPPORTED |
| AEB-12 | C10 patch carries manifest changing ONLY 3 v11 SHAs; from-index == current blob (clean apply) | SUPPORTED |
| AEB-13 | CX1 touches no fixture input (not pack-help.sh/detect.sh) → empty manifest diff | SUPPORTED |
| AEB-14 | C10 hardcoded post-C10 SHAs valid post-CX1 (CX1 no fixture change) + post-BD189 | SUPPORTED |
| AEB-15 | validate-pack green WITH 14 pack-ops + 29 supporting-docs `.gemini/` + 12-class MERGE-STRATEGY → prose not validate-gated | SUPPORTED |
| AEB-16 | Check-36 path model: project-side prefixes + scope-neutral manifest; per-commit keyword verdicts | SUPPORTED |
| AEB-17 | C9 commit-discipline hunks are prose-only; do not touch 28-verb denylist → Check 56 stays green | SUPPORTED |
| AEB-18 | supporting-docs `.gemini/` magnitude 29 @HEAD (pre-redo); gemini-retired-docs 0 (added by redo) | SUPPORTED |
| AEB-19 | Check 47 set-equality green; Check 43 allowlist = 8 (no growth) | SUPPORTED |
| AEB-20 | C9 + C10 patches apply --check CLEAN at HEAD; disjoint from CX1 scripts/ | SUPPORTED |

---

## RULES-APPLIED VERIFICATION BLOCK

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [planner] | Every re-measurement carries an Empirical-Evidence Block (AEB-1..AEB-20) with the actual command + verbatim output + HEAD `c4beb8d` + date 2026-06-17 + SUPPORTED / NOT-SUPPORTED. I RE-RAN every measurement myself (did NOT trust the plan's EBs): `git log --all | grep cx1` (AEB-1), `validate-pack` default+DEEP (AEB-2), `build.sh --verify` (AEB-2b), `git apply --check` on C9/C10 (AEB-20), the classifier/migrator/init/three-way/persona/test code reads (AEB-3..AEB-9), the manifest hunk + from-index vs current blob (AEB-12), init S6 copy (AEB-11), the green-with-unconverted-prose insight (AEB-15). The one NOT-SUPPORTED (AEB-8, the Group-6 test gap) drives the only MUST correction (C-1). | COMPLIANT |
| 2 | ci-guard-measure-then-bound [planner] | Re-measured the C12 grep-zero magnitude AT HEAD before judging the allowlist: 29 `.gemini/` hits in supporting-docs (pre-redo), 0 `gemini-retired-docs` (added by redo), 14 in pack-ops, the 12-class MERGE-STRATEGY (AEB-15/AEB-18). Confirmed the plan sizes the POQ-C11-1 class to the migration-source legitimate-set ONLY, with the correct re-measure-at-C12 caveat (not a frozen count). Verified no allowlist growth: Check 47 set-equality green, Check 43 = 8 (AEB-19). Categorized the C8 legacy-READ `.gemini/agents/x-*.md` token as KEEP under the existing class-2 (C-8). | COMPLIANT |
| 3 | rename-plans-measure-then-bound | Verified the plan's completeness gate is the grep-ZERO Gate A (`.gemini/` PATH) + Gate B (bare `gemini` TOKEN, widened to prose), returning EXACTLY the KEEP allowlist; and that validate-pack green does NOT prove conversion completeness (AEB-15 — green WITH 14+29 unconverted refs) → the grep-zero gate is the real backstop. Confirmed the plan does NOT hand-enumerate a frozen anchor list but bounds by the migration-source PROPERTY. | COMPLIANT |
| 4 | user-prescriptive-authority (the frozen set) | Held all 6 OQs + FIX-FORWARD + the out-of-scope deferral FIXED; did NOT re-open any. Checked ONLY realizability (§10): all realizable; flagged the one implementation subtlety (OQ-1's lift = direct cp, C-2) and the C9 carried-forward-token reviewer caveat (C-4) WITHOUT altering the frozen decision. No frozen item flagged unrealizable. | COMPLIANT |
| 5 | agent-output-requires-rules-applied-verification-block [universal] | This block; each row backed by quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS terminal state; no empty-evidence row). | COMPLIANT |
| 6 | agents-never-commit / read-only [universal] | All git verbs read-only: `git rev-parse`, `git log`, `git diff --name-only`, `git ls-files -s`, `git apply --check` (the CHECK form — NOT the applying form), `git status --short`. Plus reads/greps + read-only `validate-pack.py` runs (default + DEEP) + `build.sh --verify` (read-only). `git status --short` confirmed EMPTY after my pass (no working-tree state introduced). The SOLE write is this review doc to `/tmp/handoff-bd221-cx1-replan/ADVERSARIAL-REVIEW-CX1-REPLAN.md`. NO source edit; NO add/commit/push/stash/checkout/merge/reset/restore/worktree-mutate/branch/tag/apply(-applying-form)/config. | COMPLIANT |
| 7 | agents-read-rule-docs-in-full [universal] | Read IN FULL via the Read tool: the plan under review (PLAN-BD-221-CX1-REPLAN.md, 368 ln); NEW (DESIGN-AGENT-MIGRATION-MODEL.md, 577 ln); FINAL2 (PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md, all pages); PACK-REVIEW-C8 (291 ln); PACK-REVIEW-C11 (345 ln); IMPL-REPORT-C11 (247 ln); OUT-OF-SCOPE-FINDINGS.md (34 ln); CLAUDE.md `## Pack memory` (via project-instructions context). The committed code surfaces (customization-preserve.sh, migrate-v10-to-v11.sh, init-project.sh, three-way.sh, contract-migration.sh, the two test files, validate-pack.py Check 36/56 + scope model, build.sh) inspected directly via Read/grep at HEAD. No derivation. | COMPLIANT |

---

## FILES READ IN FULL / INSPECTED + RUNTIME REGIME

**Read in full (Read tool):** `PLAN-BD-221-CX1-REPLAN.md`;
`DESIGN-AGENT-MIGRATION-MODEL.md`; `PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md`
(paged); `PACK-REVIEW-C8.md`; `PACK-REVIEW-C11.md`; `IMPL-REPORT-C11.md`;
`OUT-OF-SCOPE-FINDINGS.md`.

**Live committed code inspected (read-only, HEAD c4beb8d):**
`scripts/lib/customization-preserve.sh` (classifier L146-180, dispatch L400-445,
disposition map L194-208), `scripts/migrate-v10-to-v11.sh` (bundle block
L355-389, retire helper L500-538), `scripts/init-project.sh`
(`_cmd_update_iter_dir` L1149-1162, bundle leg L1310-1317, S6 docs copy L670-700,
stage_s5_scripts L550-561, S11 pack-help/detect copy L993/L997, fresh-init call
L1540), `scripts/lib/three-way.sh` (dispositions L20-56), `scripts/persona-
contracts/contract-migration.sh` (bundle block L183-216), `scripts/tests/test-
migrate-v10-to-v11.sh` (Group 6 L420-460), `scripts/tests/test-customization-
preserve.sh` (Group 1 L48-72, Group 5 L287+), `scripts/validate-pack.py` (Check
36 model L3938-4160, _SCOPE_NEUTRAL/_PROJECT_SIDE L3992-4003, Check 56 surfaces
L8960-8985), `test-fixtures/build.sh` (v11 init L110-135, --verify L964+),
`test-fixtures/manifest.txt`, `pack-ops/MERGE-STRATEGY.md` (class headers).

**Saved patches re-checked:** `/tmp/handoff-bd221-C9/C9-final.patch` (12 files,
no manifest, removes README:153 MIGRATION-v8-to-v9 row), `/tmp/handoff-bd221-C10/
C10-final.patch` (7 files incl. manifest with the 3 v11 SHAs).

**Runtime regime:** pwd `/Users/david/Developer/optiquity-ai-agent-config-pack-
v11-dev`; HEAD `c4beb8d`; branch `v11-dev` (MAIN checkout, NOT a worktree). All
writes confined to `/tmp/handoff-bd221-cx1-replan/ADVERSARIAL-REVIEW-CX1-REPLAN.md`.

*End of ADVERSARIAL-REVIEW-CX1-REPLAN.md — fresh independent pack-planner pass,
MAIN checkout HEAD `c4beb8d`, 2026-06-17. Verdict: SOUND-with-corrections (1 MUST
[C-1 Group-6 test wiring], 4 SHOULD [C-2 direct-cp lift, C-3 NIT-#2 resolution,
C-4 C9 carried-token, C-6 manifest order-gate], 3 NIT + 1 optional reorder). All
6 frozen OQs + FIX-FORWARD held fixed and realizable.*
