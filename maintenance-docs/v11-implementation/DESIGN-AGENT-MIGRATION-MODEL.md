# DESIGN — Corrected Agent Migration / Update Model (BD-221)

**Agent:** pack-architect
**Date:** 2026-06-17
**Checkout:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (MAIN, branch `v11-dev`)
**HEAD:** `c4beb8d`
**Mode:** READ-ONLY analysis. No file edits. `/tmp` scratch only for migrator runs.

---

## 0. Scope guard + what this design does

The user identified mid-BD-221 that the committed C7 migrator agent handling is
WRONG. I confirm the defect empirically, study the v9→v10 precedent the user
pointed at, fit-check it property-by-property against the v10→v11 + Gemini→
Antigravity situation, and design the corrected model. I design HOW; I do not
re-litigate the user's frozen WHAT. I run NO state-changing git verb and make NO
file edits; this doc is the only artifact.

**The frozen direction (the WHAT — constraints, not open questions):**
1. Pack agents are not client-modifiable, but a config-pack version bump CAN
   update them → on migrate/bump the new pack agents are copied in and REPLACE
   the client's old pack agents **if different**. All agents updatable.
2. Custom (`x-`) agents are KEPT — placed INTO the Antigravity bundle, not retired.
3. Gemini→Antigravity = add ALL pack agents to the Antigravity bundle + KEEP the
   custom agents from Gemini; v10.x Gemini pack agents are REPLACED by v11.0 pack agents.
4. It is a SPECIAL CASE of the general "config-pack bump updates agents" model — same treatment.

---

## 1. EXECUTIVE SUMMARY (read this first)

**The precedent FITS — anchor on it, do not reinvent.** The v9→v10 migrator's
`stage_s1_agents()` is exactly the model the user describes, and the v11 BD-119
framework already RE-IMPLEMENTS that model as `customization_preserve` + the
3-way classifier. The corrected behavior is ALREADY how the migrator handles the
**loose** `.claude/agents/` + `.codex/agents/` surfaces (replace-if-different for
pack agents; preserve for `x-`). The C7 defect is that the **Antigravity bundle**
surface was bolted on OUTSIDE that mechanism with a naive non-clobber `cp` AND the
departing `.gemini/` custom agents are swept into `gemini-retired-docs/` instead
of into the bundle.

**Two precise defects (both empirically reproduced — §4):**
- **D1 — bundle pack agents are non-clobber, not replace-if-different.** The C7
  bundle install (`migrate-v10-to-v11.sh:362-389`) copies each pack bundle agent
  IFF the destination is absent. On a re-bump where a pack agent CHANGED, the old
  client copy is NOT replaced. Violates frozen #1.
- **D2 — custom `x-` agents are retired, not kept into the bundle.** The departing
  `.gemini/agents/x-*.md` is moved whole-tree into `gemini-retired-docs/` by
  `_v10_to_v11_retire_gemini` (L500-536); the client is told to MANUALLY re-create
  it as a skill. The bundle ends up with exactly the 16 pack agents, no custom.
  Violates frozen #2 + #3.

**Root structural cause (the one thing to fix at the engine level):** the
classifier `customization_classify` does NOT recognize `.agents-plugin/...` paths
— bundle pack agents AND bundle `x-` agents both fall to class `generic` (proven
EB-7). So even routing the bundle through `customization_preserve` today would
mis-handle a bundle `x-` agent (generic 3-way, not custom-preserve). The fix has a
classifier leg + a sweep/source-merge leg + a retire-step carve-out.

**Recommended mechanism (anchor-on-precedent):** route the bundle agents through
the SAME `customization_preserve` engine the loose agents already use, by
(a) teaching `customization_classify` the `.agents-plugin/.../agents/x-*` →
`custom-agent` and `.agents-plugin/.../agents/*.md` → `pack-agent` legs, and
(b) replacing the C7 hand-rolled non-clobber bundle block with a directory-sweep
through the engine, PLUS (c) a one-time migration-only step that copies the
departing `.gemini/agents/x-*` custom agents INTO the bundle before the `.gemini/`
tree is retired. The general bump path (`init-project.sh --update`) ALREADY routes
the bundle through the engine (`_cmd_update_iter_dir ... pack-agent`, L1316-1317)
— so the bump path is 90% correct already; only the classifier leg (a) is missing
there too.

---

## 2. THE v9→v10 PRECEDENT (STEP 1) — documented empirically

### 2.1 What the v9→v10 migrator did with agents

The v9→v10 migrator (`scripts/migrate-v9-to-v10.sh`, 1226 lines, sunset by
BD-121 commit `1daa938`, recovered from `1daa938~1` to
`/tmp/handoff-bd221-agent-migration/v9-recovered/`) handled agents in a dedicated
stage `stage_s1_agents()` titled **"S1 — replace pack agents"** (recovered L486-535):

- It iterates the **pack source** roster (`$PACK/project-template/.${tool}/agents/*.${ext}`)
  for each of claude/codex/gemini.
- For each pack agent it resolves a **v9.3 baseline** blob from the `v9.3` git tag
  (`v93_baseline_to_tmp`, L158-168) and calls
  `dispatch_text_file "$cls" "$base" "$ours" "$theirs" "$ours" "$rel"` (L522-526).
- `dispatch_text_file` (L181-240) runs `three_way_classify base ours theirs` and
  acts on the disposition:
  - `unchanged-pack` (base==ours==theirs) → no-op (this IS "if not different").
  - `pack-update-applied` (base==ours, base!=theirs) → `cp theirs dest` (REPLACE).
  - `new-file-in-pack` (base absent, ours absent, theirs present) → `cp theirs dest` (ADD-NEW).
  - `merged-with-customization` (base!=ours, base==theirs) → keep ours.
  - `real-merge-required` (base!=ours, base!=theirs) → sidecar ours, copy theirs.
- **`x-*` files are never iterated** — the loop globs only pack-named files; the
  closing comment L530 reads: `# x-*."${src_ext}" files in dst_dir are intentionally left untouched.`

### 2.2 Answers to the STEP-1 questions

| Question | Answer (with mechanism) |
|---|---|
| How did an agent NEW in v10 get ADDED? | Same S1 loop. A v10 pack agent absent at the v9.3 baseline AND absent in the project → `three_way_classify "" "" theirs` = `new-file-in-pack` → `cp theirs dest`. **EB-8 confirms `new-file-in-pack`.** |
| How did EXISTING agents get UPDATED in place? | `three_way_classify base ours theirs` = `pack-update-applied` when the project copy still equals the v9.3 baseline but the pack changed → `cp theirs dest`. **Content-compared replace, not blind overwrite, not merge.** |
| Custom (`x-`) vs PACK distinguished + handled how? | PACK = whatever the pack roster ships (iterated). CUSTOM = `x-` prefix; never iterated → left untouched (preserved in place). |
| Additive/non-clobber/replace contract; customization interaction | The contract is **content-aware 3-way**: ADD new, REPLACE unmodified-pack, KEEP project-modified (or sidecar if pack ALSO changed). NOT additive-only, NOT blind-clobber. Customization-preserve is intrinsic: a client edit to a pack agent shows as base!=ours and is preserved/sidecared, never silently lost. |

**Empirical-Evidence Block EB-A — v9→v10 stage_s1_agents shape**
- **Command:** `git show 1daa938~1:scripts/migrate-v9-to-v10.sh` → recovered file; `grep -n -i agent` + Read L486-535.
- **Output (verbatim, key lines):**
  - L488-489 `stage_s1_agents() { say "── S1 — replace pack agents ──"`
  - L505 `for f in "$pack_src"/*."${src_ext}"; do`
  - L512 `base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")`
  - L523 `dispatch_text_file "$cls" "$base_tmp" "$ours" "$theirs" "$ours" "$rel"`
  - L530 `# x-*."${src_ext}" files in dst_dir are intentionally left untouched.`
- **HEAD/date:** recovered from `1daa938~1`, read 2026-06-17.
- **Interpretation:** the v9→v10 mechanism = iterate pack roster, 3-way-classify each against the prior-tag baseline, replace-if-different / add-if-new / preserve-if-customized; `x-` never touched.
- **Conclusion:** SUPPORTED.

**Empirical-Evidence Block EB-B — the disposition→action table**
- **Command:** Read `scripts/migrate-v9-to-v10.sh` L181-240 (`dispatch_text_file`) + `scripts/lib/three-way.sh` L57-125.
- **Output:** classifier returns `unchanged-pack | pack-update-applied | merged-with-customization | real-merge-required | new-file-in-pack | project-only-file | ...`; dispatch maps `pack-update-applied|new-file-in-pack → cp theirs dest`, `merged-with-customization → keep ours`, `real-merge-required → sidecar+copy`.
- **HEAD/date:** 2026-06-17 (three-way.sh is LIVE on HEAD `c4beb8d`).
- **Interpretation:** "replace if different" = the `pack-update-applied` leg; "keep custom" = never-iterate `x-` + the `merged-with-customization` leg.
- **Conclusion:** SUPPORTED.

### 2.3 The v11 framework ALREADY re-implements this precedent

The BD-119 framework did not throw away the v9→v10 mechanism — it generalized it:

- `scripts/lib/three-way.sh` is the SAME classifier, now LIVE on HEAD (sourced by
  the framework and by `init-project.sh --update`).
- `scripts/lib/customization-preserve.sh` `_cp_strategy_text` (L253-310) is a
  near-verbatim port of `dispatch_text_file` (its own header L250-252 says so:
  "Mirrors migrate-v9-to-v10.sh dispatch_text_file but with the v11 sidecar suffix").
- `customization_preserve` (L400-440) dispatches by class: `pack-agent` → 3-way
  text (replace-if-different); `custom-agent` (the `x-*` class) → preserve as
  `project-only-file`, never overwrite (L420-428).
- The v10→v11 migrator's framework directory-sweep `_manifest_sweep_one_dir`
  (`migrator-manifest.sh` L471-528) resolves a REAL v10 baseline
  (`migrator_baseline_to_tmp`, off `MIGRATOR_BASELINE_TAG="v10"`) and dispatches
  each swept file via `customization_preserve` — exactly the v9→v10 pattern.

**This is the property-fit anchor.** The corrected model is NOT new machinery; it
is bringing the bundle surface INTO the machinery the loose surfaces already use.

**Empirical-Evidence Block EB-C — framework port of the precedent**
- **Command:** `grep -n "Mirrors migrate-v9-to-v10" scripts/lib/customization-preserve.sh`; Read L416-440 + L253-310; Read `migrator-manifest.sh` L471-528.
- **Output (verbatim):**
  - customization-preserve.sh L251 `# pm-chat fallback, generic). Mirrors migrate-v9-to-v10.sh dispatch_text_file`
  - L417-419 `trinity|pack-agent|pack-script|pm-chat|generic) _cp_strategy_text ...`
  - L420-428 `custom-agent|custom-script) ... _cp_record "project-only-file" ... "project-owned"`
  - migrator-manifest.sh L505 `if ! migrator_baseline_to_tmp "$pack_rel" "$base"; then`
  - L516-518 `customization_preserve "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls"`
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Conclusion:** SUPPORTED — the v9→v10 precedent is the live framework.

---

## 3. FIT-CHECK (STEP 2) — does the precedent fit v10→v11 + Gemini→Antigravity?

Property-by-property. Each row: does the precedent's property hold for the new situation?

| Property of the v9→v10 mechanism | Holds for v10→v11 loose (.claude/.codex)? | Holds for the Antigravity BUNDLE? |
|---|---|---|
| Iterate the pack roster as the source of truth | YES — `migrator_directory_sweeps` rows `.claude/agents`, `.codex/agents` (migrate-v10-to-v11.sh:114-115) | **PARTIAL** — C7 iterates `bundle_src/agents` but OUTSIDE the engine (L362-389) |
| Resolve a prior-version baseline (v10 tag) for clean 3-way | YES — `_manifest_sweep_one_dir` calls `migrator_baseline_to_tmp` | **MISFIT(benign)** — bundle is NET-NEW in v11; there is NO v10 baseline for `.agents-plugin/...` → base absent (this is fine; see §3.1) |
| `pack-agent` → replace-if-different | YES — class `pack-agent` → `_cp_strategy_text` | **NO (D1)** — C7 uses non-clobber `cp` |
| `x-` custom agent preserved | YES — class `custom-agent` (L167) → preserve | **NO (D2)** — bundle `x-*` falls to `generic` (EB-7); and the departing `.gemini/agents/x-*` is retired, never copied into the bundle |
| `x-` discovered by classifier path-match | YES for `.claude/`/`.codex/`/`.gemini/` legs | **NO** — classifier has no `.agents-plugin/...` leg (EB-7) |

**Verdict: the mechanism FITS; ANCHOR on it.** The three NO/PARTIAL rows are all
the SAME root gap — the bundle surface was never wired into the classifier/engine.
There is ONE genuine (benign) misfit (no v10 baseline for the net-new bundle path),
handled in §3.1. No reason to invent a new mechanism. (Pattern-matching guard:
this is an evidence-based property-fit, not reflex — 4 of 5 properties already hold
for the loose surfaces via the identical engine; the bundle just needs to join it.)

### 3.1 The one genuine misfit: net-new bundle has no v10 baseline

Because `.agents-plugin/` did not exist in v10, `migrator_baseline_to_tmp
".agents-plugin/optiquity-agents/agents/coder.md"` resolves ABSENT. With base
absent and a project copy present, `three_way_classify` returns
`project-shadows-new-pack` for BOTH identical and different content (EB-9) → the
engine writes theirs to dest AND sidecars ours. That is the conservative behavior:
it never silently clobbers, it surfaces a `.pre-update`/`.v10-customized` sidecar.

**Why this is acceptable (not a blocker) for the v10→v11 migration specifically:**
On a v10→v11 migration the client has NO pre-existing `.agents-plugin/` (it is a
fresh Antigravity surface for them) → ours is ALWAYS absent → `new-file-in-pack`
→ clean copy, no sidecar. The base-absent ambiguity only bites a v11→v11 re-bump,
where it is handled correctly by the general bump path (§5.2) IF a v11 baseline
tag is available, or conservatively (sidecar) if not. **This matches how the loose
`init-project.sh --update` path ALREADY behaves** (base="" passed deliberately,
L1161/L1302). So the misfit is pre-existing-and-accepted, not introduced here.

**Empirical-Evidence Block EB-9 — base-absent classification (the misfit)**
- **Command:** sourced `three-way.sh`; classified base="" with identical vs different ours/theirs.
- **Output (verbatim):**
  - `base='' ours==theirs (identical)` → `project-shadows-new-pack`
  - `base='' ours!=theirs (different)` → `project-shadows-new-pack`
  - `base='' ours absent (new)` → `new-file-in-pack`
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** with no baseline the classifier cannot distinguish "client edited" from "pack changed" → routes to sidecar (safe). With ours absent → clean add. On v10→v11 the bundle is always a clean add.
- **Conclusion:** SUPPORTED — base-absent is the only misfit; benign on v10→v11; conservative on re-bump.

---

## 4. THE DEFECT — empirically reproduced

I ran the COMMITTED `migrate-v10-to-v11.sh` against a `/tmp` clone of the
`test-fixtures/v10-realistic-ot` fixture (a clean git repo at HEAD's pack; bare
invocation auto-dry-runs, pauses at S3 trinity sidecars, resolved via accept-pack,
`--resume` to completion exit 0). The fixture ships a custom `x-fakeot-domain.md`
in `.claude/agents/`, `.codex/agents/`, AND `.gemini/agents/`.

### EB-1 — bundle ends with exactly the 16 PACK agents; custom NOT in bundle
- **Command:** post-`--resume`, `ls .agents-plugin/optiquity-agents/agents/`; test `-f .../x-fakeot-domain.md`.
- **Output (verbatim):**
  ```
  -- bundle agents --
  architect.md auditor-architecture.md auditor-code.md auditor-docs.md auditor-ops.md auditor-security.md auditor-tests.md auditor-ui.md auditor.md coder.md docs-researcher.md grpc-schema.md planner.md repo-ops.md reviewer.md tester.md
  -- x-fakeot-domain.md in bundle? --
  NO — NOT in bundle
  ```
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** bundle = 16 pack agents, zero custom. Frozen #2/#3 violated.
- **Conclusion:** SUPPORTED — D2 reproduced.

### EB-2 — custom agent RETIRED to gemini-retired-docs/, not kept
- **Command:** `find gemini-retired-docs -type f | grep x-`; `find . -name "x-fakeot-domain*"`.
- **Output (verbatim, relevant):**
  ```
  gemini-retired-docs/.gemini/agents/x-fakeot-domain.md
  ...
  ./.claude/agents/x-fakeot-domain.md        (loose — correctly preserved)
  ./.codex/agents/x-fakeot-domain.toml       (loose — correctly preserved)
  ```
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** the departing `.gemini/agents/x-fakeot-domain.md` lands in the holding dir (retired). The LOOSE `.claude`/`.codex` customs ARE correctly preserved in place (the engine works there). Only the BUNDLE representation of the custom is missing.
- **Conclusion:** SUPPORTED — D2 reproduced; loose preservation confirms the engine is correct, the bundle is the gap.

### EB-3 — loose pack agent IS replace-if-different (the engine works)
- **Command:** `shasum .claude/agents/coder.md` after migrate vs `shasum project-template/.claude/agents/coder.md`.
- **Output (verbatim):** both `29d78f5905d5a7217d0a6dedbacd106a49f723db`.
- **Interpretation:** the loose pack agent was replaced with the v11 pack content (3-way `pack-update-applied`). The engine already does frozen #1 for loose surfaces.
- **Conclusion:** SUPPORTED — the engine is correct; the bundle just isn't using it.

### EB-4 — C7 bundle install is non-clobber (D1), with a presence-only count guard
- **Command:** Read `migrate-v10-to-v11.sh` L362-389.
- **Output (verbatim, key lines):**
  - L368 `if [[ ! -f "$bundle_dest" ]]; then` (copy IFF absent — non-clobber)
  - L373-378 comment: "Superset-tolerant count guard (NOT init's strict ==) ... Assert every PACK bundle agent is PRESENT"
  - L387-388 `(( missing_bundle == 0 )) || fail_stage S5 "...missing"`
- **Interpretation:** the guard checks PRESENCE, not freshness. A changed pack agent whose old client copy is present is NOT replaced. Frozen #1 violated for the bundle.
- **Conclusion:** SUPPORTED — D1 reproduced.

### EB-7 — classifier does NOT recognize bundle paths (root structural cause)
- **Command:** sourced `customization-preserve.sh`; `customization_classify` on bundle vs loose paths.
- **Output (verbatim):**
  ```
  .agents-plugin/optiquity-agents/agents/coder.md            -> generic
  .agents-plugin/optiquity-agents/agents/x-fakeot-domain.md  -> generic
  .claude/agents/coder.md                                    -> pack-agent
  .claude/agents/x-fakeot-domain.md                          -> custom-agent
  ```
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** bundle pack AND bundle custom both classify `generic`. `generic` routes through `_cp_strategy_text` (3-way replace-if-different) — OK for a bundle PACK agent, but WRONG for a bundle `x-` agent (it would be 3-way'd, not unconditionally preserved). This is why simply adding a directory-sweep row is NOT sufficient — the classifier leg must be added first.
- **Conclusion:** SUPPORTED — the missing classifier legs are the engine-level root cause.

### EB-10 — independent corroboration: the C8 + C11 reviews already flagged it
- **Command:** Read `/tmp/handoff-bd221-C8/PACK-REVIEW-C8.md` L105-146, L153-162.
- **Output (verbatim, key):**
  - C8 SHOULD: "The code does NOT relocate the custom agents into the Antigravity bundle ... moves the entire departing `.gemini/` tree ... into `gemini-retired-docs/`."
  - C8 NIT: "the *classifier* does not match `.agents-plugin/...` to those classes (it would fall to `generic`, code L177)."
- **Interpretation:** the C8 reviewer independently identified BOTH the retirement-not-bundle behavior (D2) AND the classifier gap (root cause). The reviewer framed it as doc-vs-code/NIT under the OLD (additive, manual-recreate) intent; under the CORRECTED intent these become the design's primary targets.
- **Conclusion:** SUPPORTED.

---

## 5. THE CORRECTED MODEL (the design)

### 5.0 The unified contract (one model, two surface shapes, three call sites)

**Contract (identical to the v9→v10 precedent):** "On any pack version event
(fresh init / `--update` bump / vN→vM migrate), for each agent surface: ADD pack
agents the client lacks; REPLACE pack agents the client has but that DIFFER from
the new pack version; KEEP (never overwrite) `x-` custom agents; surface a sidecar
when a pack agent was BOTH client-edited AND pack-changed."

This contract is realized by ONE engine (`customization_preserve` + 3-way) at
THREE call sites:
1. `init-project.sh stage_s2_agents` — fresh install (always clean ADD).
2. `init-project.sh cmd_update` (`_cmd_update_iter_dir ... pack-agent`) — general bump.
3. `migrate-v10-to-v11.sh` directory sweeps + post-dispatch hook — migration.

The two surface SHAPES are: loose per-CLI (`.claude/agents/`, `.codex/agents/`)
and the Antigravity plugin bundle (`.agents-plugin/optiquity-agents/agents/`).

### 5.1 Engine-level fix (shared by all three call sites) — add the classifier legs

`customization_classify` (customization-preserve.sh ~L164-170) gains two legs,
ordered `x-` BEFORE the general so the prefix wins:

```
.agents-plugin/*/agents/x-*           -> custom-agent
.agents-plugin/*/agents/*.md          -> pack-agent
```

(Use a glob that matches the plugin-namespace dir, e.g.
`.agents-plugin/*/agents/x-*.md`, so the design does not hard-code
`optiquity-agents` — keeps the leg robust if the plugin namespace changes.)

This single change makes EVERY call site that routes the bundle through the engine
do the right thing automatically: bundle pack agents → replace-if-different;
bundle `x-` → preserve. **This is the keystone fix.**

ENCODING-SURFACE note (enumerate-encoding-surfaces rule): adding classifier legs
means updating in lock-step (a) the classifier branch, (b) the classifier
docstring class list (L20-22 area), (c) `test-customization-preserve.sh` (it pins
the 12-token classifier — see C8 review §3(c)(ii) which enumerates the classes),
and (d) `pack-ops/MERGE-STRATEGY.md` class 7/8 prose (the class-model SSOT doc).

### 5.2 General bump path (init-project.sh) — already 90% correct

`cmd_update` already routes the bundle through the engine:
`_cmd_update_iter_dir "project-template/.agents-plugin/optiquity-agents/agents"
".agents-plugin/optiquity-agents/agents" pack-agent` (L1316-1317). It passes an
EXPLICIT class `pack-agent` for the whole dir — which means even an `x-` agent in
that dir is forced to `pack-agent` (because the explicit `cls` arg bypasses
`customization_classify`, L403). **Defect-in-waiting:** with the §5.1 classifier
legs in place, the cleaner fix is to call `_cmd_update_iter_dir` WITHOUT forcing
the class so each file self-classifies (pack vs `x-`). Recommended change: drop
the forced `pack-agent` for the bundle leg and let `customization_preserve`
classify per-file (it already does this for the explicit-entries loop? — no; that
loop also passes class. The per-file self-classify is the bundle's specific need
because a bundle dir mixes pack + custom).

`stage_s2_agents` (fresh install, L433-468) is fine as-is — a fresh install has no
custom agents and no pre-existing target, so `cp -R` whole-bundle is correct
(the count guard `bundle_count == pack_count` holds because the source has only
pack agents).

### 5.3 Migration path (migrate-v10-to-v11.sh) — the C7 revision

Replace the C7 hand-rolled bundle block (L362-389) and adjust the retire step
(L500-536). Two coordinated changes:

**(A) Install/update the bundle through the engine (replaces L362-389).**
Add the bundle dir to the framework's directory sweeps so it goes through
`_manifest_sweep_one_dir` → `customization_preserve` (replace-if-different for
pack agents; preserve for `x-` once §5.1 lands). Either:
- **Option A1 (preferred — anchor):** add a `migrator_directory_sweeps` row
  `project-template/.agents-plugin/optiquity-agents/agents pack-agent`? NO — a
  forced class would mis-handle `x-` again. Instead add the row WITHOUT a forced
  class is not possible (the sweep row format is `<dir> <class>`). So either
  extend the sweep-row format to allow a "self-classify" sentinel, OR
- **Option A2 (simpler):** keep a dedicated bundle block in the post-dispatch
  hook, but have it call `customization_preserve "" "$ours" "$theirs" "$rel"
  "$dest"` per pack-source file (NO forced class → self-classify via §5.1). Base
  is "" (net-new surface; §3.1). On v10→v11 ours is absent → clean add.

  Recommendation: **A2** — it keeps the migration-specific ordering (install
  before retire) explicit and avoids changing the sweep-row grammar. The block
  iterates `bundle_src` (pack source) for the PACK agents (add/replace-if-diff),
  and is paired with (B) for the custom agents.

**(B) Copy the departing `.gemini/agents/x-*` INTO the bundle BEFORE retiring (new step).**
Before `_v10_to_v11_retire_gemini` runs, add a step that, for each
`$_MIGRATOR_TARGET/.gemini/agents/x-*` (and the loose `.claude`/`.codex` x- agents
already preserved in place — see note below), copies it to
`$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/agents/<name>` IFF not already
present (never clobber a same-named bundle custom). This realizes frozen #2/#3:
the Gemini custom agent becomes an Antigravity bundle agent.

  Source-of-truth question (OPEN — §7 Q1): the custom agent exists in THREE
  places in a v10 project (`.claude/agents/x-*.md`, `.codex/agents/x-*.toml`,
  `.gemini/agents/x-*.md`). Which is the source for the bundle copy? The
  `.claude`/`.gemini` `.md` form is the natural source (bundle agents are `.md`);
  the `.codex` `.toml` is a different format. Recommend: source the bundle custom
  from the `.gemini/agents/x-*.md` (the departing tree, since the conversion is
  literally "Gemini→Antigravity") falling back to `.claude/agents/x-*.md` if the
  Gemini copy is absent. The loose `.claude`/`.codex` x- copies remain preserved
  in place (Claude/Codex still read loose dirs — they are NOT retired).

**(C) Adjust the retire step.** After (B) has lifted the customs into the bundle,
`_v10_to_v11_retire_gemini` still moves the departing `.gemini/` to
`gemini-retired-docs/` as a recovery copy (move-not-delete is correct and stays).
The user-facing message (L530-535) must change: it should say the Gemini custom
agents were COPIED INTO the Antigravity bundle (`.agents-plugin/.../agents/`) and
the `.gemini/` tree was retired to `gemini-retired-docs/` as a backup — NOT "review
it and manually re-create your customizations as skills." Frozen #2 means the
re-creation is automatic, not manual.

  Note: the `.gemini/` STANDARD (non-x) skill mirrors stay retired-only (the v11
  loose `.agents/skills/` install already shipped them); only AGENTS are lifted.

### 5.4 Cross-CLI mapping summary (the corrected end state)

| Surface | Pack agents on bump/migrate | Custom (`x-`) agents on bump/migrate |
|---|---|---|
| `.claude/agents/*.md` (loose) | replace-if-different (engine `pack-agent`) — ALREADY correct | preserved in place (engine `custom-agent`) — ALREADY correct |
| `.codex/agents/*.toml` (loose) | replace-if-different — ALREADY correct | preserved in place — ALREADY correct |
| `.agents-plugin/optiquity-agents/agents/*.md` (bundle) | replace-if-different — FIX via §5.1 + §5.3(A) | preserved in bundle (§5.1) + Gemini custom lifted in (§5.3(B)) |
| `.gemini/agents/*` (departing) | n/a (Gemini retired) | `x-` lifted INTO bundle (§5.3(B)); whole tree then moved to `gemini-retired-docs/` as backup |

---

## 6. BLAST RADIUS + SEQUENCING (STEP 3)

This is mid-cluster: C0–C7 are COMMITTED on HEAD `c4beb8d`; four C8–C11 worktrees
are live (held). The correction is a NEW migrator change SUPERSEDING C7's agent
handling, plus doc/test reconciliation that overlaps the held C8/C11.

### 6.1 Surface-by-surface change list (measure-then-bound)

| # | Surface | Change | Evidence |
|---|---|---|---|
| 1 | `scripts/lib/customization-preserve.sh` | ADD two classifier legs (`.agents-plugin/*/agents/x-*`→custom-agent; `*.md`→pack-agent); update docstring class list | EB-7 (legs missing) |
| 2 | `scripts/migrate-v10-to-v11.sh` | REPLACE C7 bundle block L362-389 with engine-routed install (§5.3A); ADD lift-Gemini-customs-into-bundle step before retire (§5.3B); REWRITE retire user-message L530-535 (§5.3C); fix the L429-430/L470-475 "installed additively" comments | EB-1/2/4 |
| 3 | `scripts/init-project.sh` | bundle `--update` leg L1316-1317: drop forced `pack-agent` class so bundle files self-classify (so a bundle `x-` is preserved on bump) | §5.2; L1316-1317 |
| 4 | `scripts/lib/customization-report.sh` / dispositions | NONE expected — `pack-update-applied`/`project-only-file` tokens already covered | L196-208 token map |
| 5 | `pack-ops/MERGE-STRATEGY.md` (HEAD: v10 class names) | class 7/8 prose: add the `.agents-plugin/.../agents/x-*` + `*.md` legs; change the "relocate into bundle" line to match the NOW-TRUE behavior (the C8 SHOULD becomes a real fix, not a doc-only patch). **This OVERLAPS the held C8 conversion** — coordinate (§6.4) | EB-10; C8 review L105-146 |
| 6 | `scripts/persona-contracts/contract-migration.sh` | assertion 3b: ADD a bundle leg asserting the Gemini custom `x-fakeot-domain.md` lands in `.agents-plugin/.../agents/`; the bundle pack-agent block L190-209 already asserts presence (KEEP, optionally strengthen to freshness) | L305-315, L190-216 |
| 7 | `scripts/tests/test-migrate-v10-to-v11.sh` | Group 6 (L421-456): the assertion `gemini-retired-docs/.gemini/agents/x-ot-domain.md` (L447) stays (backup copy still there) BUT ADD an assertion that the custom ALSO landed in `.agents-plugin/.../agents/x-ot-domain.md`; the bundle block L156-161 KEEP | L447, L156-161 |
| 8 | `scripts/tests/test-customization-preserve.sh` | ADD bundle-path classify cases (`.agents-plugin/.../x-*`→custom-agent; `*.md`→pack-agent) + a replace-if-different + a preserve-x case for the bundle | C8 review §3(c)(ii) enumerates the pinned classifier set |
| 9 | `supporting-docs/SETUP-EXISTING.md` + `MIGRATION-v10-to-v11.md` (held in C11) | post-migration narrative: custom agents are AUTO-LIFTED into the bundle (not "manually re-create as skills"); `gemini-retired-docs/` is a BACKUP. **OVERLAPS held C11** — coordinate | C11 review §post-migration list |
| 10 | `test-fixtures/manifest.txt` | NO CHANGE from the migrator fix itself — v11 fixtures are init-built, not migrator-built (EB-5/EB-6 below); BUT any commit touching `scripts/` MUST regen the manifest per RC9 and stage if non-empty | §6.2 |

### 6.2 Manifest / fixture impact

**Empirical-Evidence Block EB-5 — v11 fixtures are init-built, not migrator-built**
- **Command:** `grep -n "init-project\|migrate" test-fixtures/build.sh`; `grep agents-plugin test-fixtures/manifest.txt`.
- **Output (verbatim):**
  - build.sh L119 `PACK="$v10_src" bash "$v10_src/scripts/init-project.sh" "$target"` (v10 fixtures)
  - build.sh L126 `PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" "$target"` (v11 fixtures)
  - No `migrate-v10-to-v11` invocation in build.sh (only an unrelated comment at L508).
  - `grep agents-plugin manifest.txt` → 0 lines (manifest tracks per-fixture SHAs: 6 fixtures, 10 lines incl. header).
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** committed fixtures (`v11-realistic-ot` etc.) are produced by `init-project.sh`, never the migrator. Migrator OUTPUT is built per-test in `/tmp`. So the corrected migrator does NOT change any committed fixture content → no per-fixture-SHA change.
- **Conclusion:** SUPPORTED — manifest content unchanged by the migrator fix. (RC9 still requires running `build.sh --all --clean` on any `scripts/`-touching commit and staging IF the diff is non-empty; expect empty here, but VERIFY at impl.)

**Empirical-Evidence Block EB-6 — v11 fixture has bundle, no custom, no gemini-retired-docs**
- **Command:** `find test-fixtures/v11-realistic-ot -path "*agents-plugin*"`; test `-d .gemini` / `-d gemini-retired-docs`.
- **Output (verbatim):** bundle present (`.agents-plugin/optiquity-agents/agents/*.md` + plugin.json + RUNTIME-SUBAGENT-PATTERN.md); `.gemini` → NO; `gemini-retired-docs` → NO.
- **Interpretation:** a fresh v11 install (the fixture) has no custom agents and no retirement artifacts — consistent with init being clean-add. The corrected migration behavior is only exercised by the per-test `/tmp` migrator runs + the persona-contract, not the committed fixtures.
- **Conclusion:** SUPPORTED.

### 6.3 Install-map / Check 39/41/47 impact

NO change. The bundle is recursive-walk-covered by the `project-template/`
inventory and keyed off `init-project.sh` (C7 design EB §4 established this and it
remains true — the corrected migrator adds NO new install-map row; it routes
existing pack-source files through the engine). The Gemini-custom-lift (§5.3B)
copies CLIENT-existing files (the departing `.gemini/agents/x-*`), not pack-source
files — so it is not an install-map entry either. **VERIFY at impl** by running
`scripts/validate-pack.py` (Checks 39/41/47) against the projected tree.

### 6.4 Recommended commit sequence (how it slots vs held C8–C11)

The correction touches BOTH pack-engine/migrator/test surfaces AND the held
C8 (MERGE-STRATEGY) + C11 (setup/migration docs) surfaces. Two viable orderings;
I recommend Option-1.

**Option-1 (preferred) — land the correction as a NEW pack-only commit FIRST, then
re-derive the held C8/C11 against the corrected code.**

1. **CX1 (pack-only) — engine + migrator + tests correction.** §6.1 rows 1,2,3,6,7,8
   (classifier legs, migrator bundle-via-engine + custom-lift + retire-message,
   init `--update` self-classify, persona-contract bundle-custom assertion, the two
   test files). One coder, one review/fix cycle. Manifest regen per RC9 (expect
   no-op; stage if non-empty). This SUPERSEDES C7's agent handling.
2. **C8 (re-derive)** — the held C8 worktree authored MERGE-STRATEGY against the
   WRONG behavior (its own SHOULD finding documents the mismatch). Re-do C8's
   MERGE-STRATEGY class-7/8 prose against the CORRECTED code from CX1 (row 5). The
   held C8 worktree is now stale for the agent classes — discard/redo that portion.
3. **C11 (re-derive)** — the held C11 setup/migration docs describe the
   retire-and-manually-recreate narrative; re-do the post-migration agent
   narrative against CX1 (row 9). C11 also has the open MUST manifest-regen
   (C11 review M-1) — fold that in.
4. C9/C10 (held, non-agent) proceed unchanged relative to this correction
   (verify no incidental overlap).

Rationale: the doc surfaces (C8/C11) must describe the CORRECTED code, so the code
correction must land first. Re-deriving the two held doc worktrees is cheaper than
trying to patch them to match code that itself is being rewritten.

**Option-2 (NOT recommended)** — fold the code correction INTO the held C8/C11
worktrees. Rejected: mixes pack-engine code (pack-only, needs its own review cycle)
into doc worktrees; muddies Check-36 scope keywords; and the agent-migration fix is
a coherent unit that deserves its own commit + review for auditability.

**Sequencing concern (§7 Q4):** the held C8/C11 worktrees are based at an older
HEAD (`bc7e762` per `git worktree list`); CX1 lands on `v11-dev` HEAD. Re-deriving
C8/C11 after CX1 means the held worktrees should be re-based on the post-CX1 HEAD
(orchestrator action — agents never run git state-changers). Surface to the user.

---

## 7. OPEN QUESTIONS / CONCERNS FOR THE USER

1. **Bundle-custom source of truth (which copy seeds the bundle `x-`?).** A v10
   project has the custom agent in `.claude/agents/x-*.md`, `.codex/agents/x-*.toml`,
   AND `.gemini/agents/x-*.md`. The bundle is `.md`. Recommend sourcing the bundle
   custom from `.gemini/agents/x-*.md` (the literal Gemini→Antigravity lift),
   falling back to `.claude/agents/x-*.md`. Confirm. (If a client's three copies
   DIVERGED, which wins? Recommend: Gemini copy, since "convert Gemini" — but flag
   any divergence in the report.)

2. **Future-bump safety of customs coexisting in the pack bundle.** Once a custom
   `x-foo.md` lives in `.agents-plugin/optiquity-agents/agents/` alongside the 16
   pack agents, a FUTURE pack bump must (a) replace-if-different the 16 pack agents
   and (b) NEVER touch `x-foo.md`. The §5.1 classifier legs guarantee (b) IFF every
   future bump routes the bundle through the engine (self-classify). RISK: the
   plugin namespace dir is SHARED between pack-owned and client-owned files — if a
   future pack agent were ever named `x-*` (it won't be, by the `x-` convention)
   the leg would mis-handle it. Acceptable given the `x-`-reserved-for-client rule,
   but worth an explicit invariant note. Confirm comfort.

3. **How is "different" determined?** Content equality via `cmp -s` (byte-identical)
   inside `three_way_classify`. NOT semantic. A whitespace-only pack edit counts as
   "different" → replace. This matches the v9→v10 precedent exactly. Confirm this is
   the intended granularity (it is the existing contract; no change proposed).

4. **Held-worktree re-base.** §6.4 — the held C8/C11 worktrees predate CX1 and
   should be re-derived/re-based after the code correction lands. Orchestrator
   action; surfacing for the sequencing decision.

5. **`agy plugin install` runtime semantics (forward-looking).** Whether Antigravity
   re-reads the bundle after the migrator updates `.agents-plugin/.../agents/*.md`
   in place, or requires a re-`agy plugin install`, is undocumented (gemini-cli
   #27305 open; C11 review S-1 flagged the install-verb as RE-VERIFY). The migrator
   correctly updates the FILES; whether the client must re-run an install verb is a
   doc note carrying `<!-- RE-VERIFY at impl -->`. Not a blocker for the file-level
   correctness this design specifies. Confirm the doc-note posture.

6. **`stage_s2_agents` count guard on a future bundle with customs.** The fresh-init
   guard is `bundle_count == pack_count` (init-project.sh L466). Fresh init has no
   customs so this holds. It does NOT run on `--update`/migrate (those use the
   superset-tolerant presence guard). No change needed, but noting the asymmetry so
   it is not "fixed" by mistake into a strict `==` that a custom-bearing bundle
   would fail.

---

## 8. WHY THIS IS NOT DEFERRABLE (no-deferral-without-user-direction)

BD-221 is the v11.0 LAUNCH GATE. The agent-migration model is the core of the
Gemini→Antigravity conversion for EXISTING projects (frozen decision d). Shipping
v11.0 with a migrator that silently fails to update pack agents on re-bump (D1) and
loses custom agents into a holding dir requiring manual re-creation (D2) is a
launch-blocking defect against the user's frozen model. No part of this defers to
v11.1+ — it is in-scope v11.0 correction work. (The `agy plugin install` runtime
re-read semantics, Q5, is the only forward-looking item, and it is a doc-marker
hedge, not deferred work.)

---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | Every state-claim carries an Empirical-Evidence Block with the actual command + verbatim output + HEAD `c4beb8d` + date 2026-06-17 + SUPPORTED conclusion: EB-A/B/C (precedent), EB-1/2/3/4/7/10 (defect, from a live `/tmp` migrator run), EB-5/6 (fixture/manifest), EB-9 (misfit). The defect EBs are from running the COMMITTED `migrate-v10-to-v11.sh` against a `/tmp` clone of `v10-realistic-ot`, not asserted. | COMPLIANT |
| ci-guard-measure-then-bound | I measured the tree before bounding: ran `customization_classify` against actual bundle + loose paths (EB-7); grepped the manifest + build.sh to bound the fixture/manifest impact (EB-5/6); confirmed install-map/Check 39/41/47 require NO widening (§6.3, KEEP). No allowlist widened; the classifier legs are sized to the exact `.agents-plugin/.../agents/` surface, `x-` before `*.md`. | COMPLIANT |
| dependency-direction-placement | The fix routes CLIENT-shipped bundle agents through the SHARED `customization-preserve.sh`/`three-way.sh` libs (pack-side libs are a dependency of the client deliverable — the allowed direction). No client deliverable becomes a runtime dependency of a pack operation. No new file placement proposed; no `_SANCTIONED_PACK_SIDE_SHIPPED` change. | COMPLIANT |
| pattern-matching-out-of-context | The precedent-anchor is justified by an explicit property-by-property fit-check (§3 table): 4 of 5 properties already hold for the loose surfaces via the identical engine; the 1 genuine misfit (net-new bundle has no v10 baseline, §3.1) is documented as benign on v10→v11 and pre-existing-accepted on re-bump. Adoption is evidence-based, not reflex. | COMPLIANT |
| no-deferral-without-user-direction | §8 — every part lands in v11.0; no defer-recommendation; the single forward-looking item (Q5, `agy plugin install` runtime re-read) is a doc-marker hedge per the BD-221 RE-VERIFY convention, not deferred work. | COMPLIANT |
| user-prescriptive-authority | The frozen WHAT (4 directions) is treated as binding constraints (§0); I designed only the HOW. Where the HOW has genuine open choices (bundle-custom source, held-worktree re-base) they are surfaced as questions (§7), not decided unilaterally. | COMPLIANT |

---

## 10. ARTIFACTS

- Recovered v9→v10 migrator: `/tmp/handoff-bd221-agent-migration/v9-recovered/migrate-v9-to-v10.sh` (from `git show 1daa938~1`).
- This design: `/tmp/handoff-bd221-agent-migration/DESIGN-AGENT-MIGRATION-MODEL.md`.
- Live defect-reproduction `/tmp` scratch dirs were created, exercised, and (mostly) cleaned; the reproduction is fully captured in EB-1/2/3/4 above.
