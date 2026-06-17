# IMPL-REPORT — BD-221 CX1 (agent-migration/update CORRECTION, fix-forward)

**Agent:** pack-coder
**Commit:** CX1 (`pack-only`) — supersedes the committed C7 agent handling.
**Date:** 2026-06-17
**Regime:** ISOLATED worktree (BD-226 model). NO patch emitted; edits left
uncommitted in the worktree; awaiting post-review SendMessage.
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-adcb03ef07394ff01`
**Branch:** `worktree-agent-adcb03ef07394ff01`
**HEAD (base, unchanged — no commit made):** `c4beb8d3599027e589c212b4b7cd0fddf659b4f6`
**Governing docs:** NEW = `/tmp/handoff-bd221-agent-migration/DESIGN-AGENT-MIGRATION-MODEL.md`
(agent-migration model); plan = `/tmp/handoff-bd221-cx1-replan/PLAN-BD-221-CX1-REPLAN.md`;
reconciliation = `/tmp/handoff-bd221-cx1-replan/RECONCILIATION.md` (C-1, C-2 applied).

---

## 1. Summary

CX1 corrects the two C7 agent-migration defects (D1 non-clobber bundle
install; D2 custom `x-` agents retired-not-bundled) by bringing the
Antigravity plugin bundle surface INTO the same BD-088 customization-preserve
engine the loose `.claude/.codex/agents/` surfaces already use, plus a
migration-only step that LIFTS the departing Gemini `x-` customs into the
bundle before the `.gemini/` tree is retired to a backup holding dir. Six
`scripts/` files edited (the exact CX1 scope). validate-pack is GREEN both
modes (NEW fail-lines = ∅); the full 72-script wired CI suite is GREEN; the
fixture manifest diff is EMPTY (CX1 touches only the `--update` leg of
init-project, not fresh-init). The corrected behavior is proven empirically
by running the PATCHED migrator end-to-end against a `/tmp` clone of
`v10-realistic-ot`.

---

## 2. Pre-flight (Section 0)

- `pwd` = the isolated worktree path above (`…/.claude/worktrees/agent-…`). CONFIRMED isolated.
- `git rev-parse HEAD` = `c4beb8d` (== required base). CONFIRMED.
- `git rev-parse --abbrev-ref HEAD` = `worktree-agent-adcb03ef07394ff01`.
- `git status` clean at start; validate-pack BASE (`grep '^FAIL:' | sort`) = EMPTY (HEAD green).

## 3. Defect reproduced first (NEW §4 reversed)

Ran the COMMITTED (pre-edit) `migrate-v10-to-v11.sh` against a `/tmp`
contract sandbox of `v10-realistic-ot` (custom `x-fakeot-domain` present in
`.claude/`, `.codex/`, `.gemini/`):
- **D2 reproduced:** bundle ended with exactly the 16 pack agents; `x-fakeot-domain.md` NOT in `.agents-plugin/optiquity-agents/agents/`.
- The custom was RETIRED to `gemini-retired-docs/.gemini/agents/x-fakeot-domain.md`.
- User message said "re-create as Antigravity skills" (manual).
- **D1 (non-clobber):** the bundle block used `if [[ ! -f "$bundle_dest" ]]` (copy-iff-absent).

---

## 4. Per-file changes (6 files; `pack-only`)

### (1) `scripts/lib/customization-preserve.sh` (+23 lines)
- ADDED two classifier legs to `customization_classify`, `x-` BEFORE the general:
  `.agents-plugin/*/agents/x-*` → `custom-agent`; `.agents-plugin/*/agents/*.md` → `pack-agent`.
  Glob matches the plugin-namespace dir without hard-coding `optiquity-agents`.
- UPDATED the classifier docstring class list (note that custom-agent /
  pack-agent now cover the bundle surface too).
- ADDED the OQ-2 INVARIANT note inline: the bundle namespace is SHARED
  (pack + client) but pack agents are NEVER `x-` (the `x-` leg tests first),
  so customs are protected from replace-if-different.
- Comments name the realized model ("BD-221 corrected agent-migration
  model") with no line numbers (architect-doc-reality-reconciliation).

### (2) `scripts/migrate-v10-to-v11.sh` (+218/−… net; 4 coordinated changes)
- **(A) Engine-routed bundle install (replaces the C7 non-clobber block).**
  Per pack-source bundle file, call
  `customization_preserve "" "$bundle_ours" "$bundle_file" "$proj_rel" "$bundle_dest"`
  with NO forced class (self-classify per the new legs). `base=""` (net-new
  surface, no v10 baseline — NEW §3.1); on v10→v11 `ours` is absent →
  `new-file-in-pack` → clean add; on a re-bump with a changed pack agent →
  replace-if-different (D1 fixed). The superset-tolerant presence count
  guard is retained (asserts no pack agent missing; project x- extras allowed).
- **(B) NEW helper `_v10_to_v11_lift_gemini_customs_to_bundle`** (a SEPARATE
  function, called between install and retire in `migrator_post_dispatch_hook`).
  Lifts each departing `.gemini/agents/x-*.md` (OQ-1 fallback
  `.claude/agents/x-*.md`) INTO `.agents-plugin/optiquity-agents/agents/`.
  Non-clobber a same-named bundle custom. **DIRECT `cp` (C-2 MANDATORY) — NOT
  engine-routed** (the engine's `custom-agent` branch returns
  `removed-everywhere` with NO copy when `ours` is absent, which it always
  is for a net-new bundle custom on the first migration). Divergence handling
  (OQ-1): if both `.gemini/` and `.claude/` copies exist and differ, the
  Gemini copy WINS and a `note:` divergence line is printed.
- **(C) Retire user-message REWRITTEN:** customs are AUTO-LIFTED into the
  Antigravity bundle (live agents, nothing to re-create by hand);
  `gemini-retired-docs/` is a BACKUP. Also fixed the false "installed
  additively" descriptions: the top-of-file architectural note + the retire
  helper header now describe the engine-routed (replace-if-different) bundle
  install + the lift step. The dry-run info line mentions the lift.

  NOTE: the genuinely-still-additive non-clobber `cp` blocks (pool pack-help
  skill, per-entry templates, net-new skills) keep their "additive" comments
  — they ARE still additive (correctly). Only the BUNDLE descriptions changed.

### (3) `scripts/init-project.sh` (+22/−… net)
- The `cmd_update` bundle leg: DROPPED the forced `pack-agent` class so the
  bundle dir SELF-CLASSIFIES per file (a bundle `x-` is preserved on a bump).
- Made `_cmd_update_iter_dir`'s 3rd `cls` arg OPTIONAL (`${3:-}`): an empty
  class omits the class arg from `customization_preserve` (self-classify);
  the loose `.claude/.codex/agents/` + `scripts/` legs still pass their class.
- **OQ-6 respected:** the fresh-init `stage_s2_agents` count guard
  (`bundle_count == pack_count`, L466) is UNCHANGED.

### (4) `scripts/persona-contracts/contract-migration.sh` (+43/−… net)
- Assertion 3b: ADDED a bundle leg asserting the Gemini custom
  `x-fakeot-domain.md` LANDS in `.agents-plugin/optiquity-agents/agents/`
  (lifted). KEPT the `gemini-retired-docs/` backup assertion (still true).
  KEPT the loose `.claude`/`.codex` 3b asserts.
- KEPT the bundle pack-agent presence block (L190-216) — updated its comment
  from "installed additively (non-clobber)" to engine-routed
  (replace-if-different) + lifted-customs-allowed.
- KEPT all `GEMINI.md` trinity asserts (3 loops: presence, skill-rename, 3a).

### (5) `scripts/tests/test-migrate-v10-to-v11.sh` (+94/−… net) — **C-1 applied**
- Group 6 RESTRUCTURED. Was: call `_v10_to_v11_retire_gemini` IN ISOLATION
  (no install, no lift) → a "custom landed in bundle" assertion would FAIL.
  **Chosen fix (stated): the lift is a SEPARATE helper; Group 6 now calls
  BOTH helpers in production order (lift → retire) in the same subshell.**
  This is cleaner than folding the lift into the retire helper (which would
  conflate two single-responsibility steps and break the design's
  "before-retire" sequencing) and lighter than a whole new full-migration
  group. The isolated test now exercises the REAL lift behavior.
- KEPT the backup assertion (`gemini-retired-docs/.gemini/agents/x-ot-domain.md`).
- ADDED: (6.1) custom LIFTED into the bundle; (6.2) lift did NOT clobber a
  pre-existing pack bundle agent; (6.8/6.9) idempotent (re-run no-op, bundle
  custom intact). 9 Group-6 cases, all PASS.

### (6) `scripts/tests/test-customization-preserve.sh` (+61/−… net)
- Group 1: ADDED classify cases 1.15–1.18 — bundle `x-*`→custom-agent;
  bundle `*.md`→pack-agent; different-namespace robustness; bundle meta
  (`plugin.json`)→generic.
- Group 6: ADDED 6.3 (bundle `x-` self-classifies to custom-agent →
  `project-only-file`, preserved untouched) + 6.4 (bundle pack agent
  self-classifies to pack-agent, replace-if-different: dest gets v11 content).

---

## 5. `three-way.sh` (VERIFY-ONLY — no edit; RISK-2)

VERIFIED no edit needed. NEW §6.1 change rows do NOT list `three-way.sh`;
its `new-file-in-pack` / `project-shadows-new-pack` / `unchanged-pack`
dispositions are correct as-is for CX1's base-absent bundle path (proven
empirically — §7). No under-enumeration found; no edit made; no surfaced
finding. (If a base-absent leg HAD needed adjustment, that would have been a
STOP+surface, per the plan's MAINTAINER-CHECK gate.)

---

## 6. C-1 + C-2 application (mandatory reconciliation corrections)

- **C-1 (test restructure):** applied — Group 6 of `test-migrate-v10-to-v11.sh`
  now runs lift+retire together (the lift is a separate helper). The
  bundle-custom assertion runs against a state where the lift actually
  happened. (Method chosen: separate-helper + call-both-in-test; stated above.)
- **C-2 (direct cp lift):** applied — `_v10_to_v11_lift_gemini_customs_to_bundle`
  uses `cp "$src" "$dest"` directly, NOT `customization_preserve`. Rationale
  baked into the function header: the engine's `custom-agent` branch returns
  `removed-everywhere` with no copy when `ours` is absent (always the case
  for a net-new bundle custom).

---

## 7. Empirical migrator results (Section 4 item 3 — the keystone proof)

Ran the PATCHED migrator end-to-end on a `/tmp` clone of
`v10-realistic-ot` (via `build.sh --for-contract migration`, NEVER the real
fixture; cleaned up after). All behaviors confirmed:

- **(a) 16 pack bundle agents present + == v11 pack content.** Migration
  rc=0; `non-x agent count = 16`; ALL 16 == `project-template/.agents-plugin/optiquity-agents/agents/*.md` (cmp -s). Replace-if-different / clean add for the net-new surface.
- **(b) Gemini `x-fakeot-domain.md` LIFTED into the bundle.** Present in
  `.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md` (D2 fixed).
- **(c) `gemini-retired-docs/` backup holds `.gemini/agents/x-fakeot-domain.md`.** Move-not-delete intact.
- **(d) Idempotent.** Re-running the migrator on the already-migrated tree
  is refused by the `dispositions.tsv`-exists guard; bundle agents byte-identical before/after the attempted re-run (no mutation).
- **(e) Non-clobber on a customized bundle.** A pre-seeded extra `x-foo.md`
  survives the migration intact (preserved). For the customized-pack-agent
  variant, replace-if-different + sidecar-preserves-client-edit is proven via
  the `init-project --update` bump path (a pre-seeded STALE `architect.md`
  is replaced with v11 content; a bundle `x-bump-custom.md` is preserved).

D1 (replace-if-different) is additionally proven by unit test 6.4 and the
`--update` bump-path run (stale pack agent → v11 content; disposition
shows `class=pack-agent` for the bundle file, confirming self-classify).

NOTE on base-absent semantics (design §3.1, EB-9, confirmed empirically):
for the bundle, `base=""` always (net-new surface). So: ours-absent →
`new-file-in-pack` (clean add); ours-present-and-same → `unchanged-pack`
(idempotent no-op); ours-present-and-different → `project-shadows-new-pack`
(dest = v11 pack content AND a `.pre-update`/`.v10-customized` sidecar
preserves the client edit). All three apply the pack update when content
differs (replace-if-different holds), with the conservative sidecar when the
client had edited the file — never a silent loss.

---

## 8. Verification gate

| Gate | Result |
|---|---|
| validate-pack DEFAULT | exit 0 |
| validate-pack `PACK_VALIDATE_DEEP=1` | exit 0 |
| NEW fail lines (`comm -13 base after`) | EMPTY (0) |
| Full wired CI suite (72 scripts from `ci-shard-plan.py --print-partition`) | **72 PASS / 0 FAIL** |
| `test-migrate-v10-to-v11.sh` (restructured) | 54 PASS / 0 FAIL |
| `test-customization-preserve.sh` (new cases) | 232 PASS / 0 FAIL |
| `test-persona-contracts.sh` (3b new + bundle) | 3/3 contracts PASS (greenfield 194, mid-dev 25, migration 41) |
| manifest diff after `build.sh --all --clean` (Section 3) | EMPTY (not staged) |
| scoped files changed | 6 (exactly the CX1 set) |
| extra/untracked changes | 0 (stray test scratch dir removed) |

The full wired list was derived from `ci-shard-plan.py --print-partition`
(72 wired, 4 shards) and each script run individually (not sampled) —
`verify-full-ci-suite`.

---

## 9. grep-zero (Section 4 item 5; rename-plans-measure-then-bound)

Every remaining `gemini`/`.gemini` token in the 6 edited files is
KEEP-legitimate (mandated operational refs):
- **customization-preserve.sh** (6 hits): the legacy-READ `.gemini/agents/`
  classifier legs (the migrator must classify the departing v10 shape) + the
  `GEMINI.md` trinity filename + my docstring mention of `.gemini/agents/`.
  Zero gemini tokens introduced beyond the existing-leg docstring reference.
- **init-project.sh** (5 hits): all `GEMINI.md` trinity-filename refs
  (pre-existing; my edits introduced ZERO gemini tokens).
- **migrate-v10-to-v11.sh** (76 hits): the `.gemini/agents/` lift SOURCE,
  the `.gemini/`-retire, the `gemini-retired-docs/` holding-dir name, and the
  `GEMINI.md` trinity — all the migration's mandated operational refs.
- **contract-migration.sh / test-migrate-v10-to-v11.sh / test-customization-preserve.sh:**
  exercise those same mandated operational paths (`.gemini/agents/` source,
  `gemini-retired-docs/` backup, `GEMINI.md` trinity, legacy-READ classify).

No old-token residue requiring a STRIP. The migration's `.gemini/`
source/retire refs are the documented KEEP set for this surface.

---

## 10. Manifest (Section 3)

CX1 touches `scripts/` (v11-surface). Ran `bash test-fixtures/build.sh
--all --clean`; `git diff test-fixtures/manifest.txt` = EMPTY (CX1's
init-project edit is the `--update` leg only; fresh-init `stage_s2_agents`
— the path that builds the committed fixtures — is UNCHANGED, and the
migrator does not build committed fixtures). Manifest NOT staged. Matches
plan EB-5 prediction.

---

## 11. Boundary discipline check

CX1 edits ONLY `scripts/` source (pack-only); no `project-template/`,
`supporting-docs/`, or any client-shipped surface. No project-side SSOT
applies. No pack-only-reference-added-to-client-surface concern. The
`pack-ops/MERGE-STRATEGY.md` class-7/8 prose (the class-model SSOT doc) is
OUT OF SCOPE for CX1 (handled in C8-redo per the plan) — NOT touched.

---

## 12. Plan deviations

ZERO behavioral deviations from NEW §5/§6.1 + the plan §6. Two
implementation choices made within the design's latitude (both stated, both
sanctioned by the reconciliation):
1. **The lift is a SEPARATE helper** (`_v10_to_v11_lift_gemini_customs_to_bundle`)
   rather than inline in the install function — the design §5.3B says "a step
   that runs BEFORE the `.gemini/`-retire," and C-1 explicitly authorized
   "add a new group OR fold the lift into the retire helper — pick the
   cleanest + state which." A standalone helper is the cleanest realization
   of "a separate step before retire," and it makes the isolated Group-6 test
   able to exercise the real lift (C-1 satisfied).
2. **`_cmd_update_iter_dir` 3rd arg made optional** to express self-classify
   for the bundle leg without duplicating the iterator — a minimal,
   backward-compatible change (the other two callers still pass a class).

## 13. New POQs introduced

NONE.

## 14. OUT-OF-SCOPE surfaced (not fixed)

- The customized-pack-agent-in-bundle case on the MIGRATOR path (vs the
  `--update` path) triggers the migrator's Phase-A reconciliation gate flow
  (multi-sidecar resume) — this is the DESIGNED conservative `project-shadows-new-pack`
  behavior (§3.1) and does NOT occur on a real v10→v11 migration (the bundle
  is net-new → ours absent → clean add). It is exercised via the `--update`
  bump path (the natural home for replace-if-different). NOT a defect; noted
  for awareness only. No action taken.

---

## 15. Definition-of-Done checklist

| Item | Status |
|---|---|
| All 6 scoped files edited per NEW §5/§6.1 | PASS |
| Classifier legs added (`x-` before `*.md`) + docstring + OQ-2 invariant | PASS |
| Migrator engine-routed install (replace-if-different) | PASS |
| Migrator lift-Gemini-customs (DIRECT cp, C-2; OQ-1 source+fallback+divergence) | PASS |
| Retire user-message rewritten (auto-lift; backup) + additive comments fixed | PASS |
| init-project `--update` bundle self-classify; fresh-init guard untouched (OQ-6) | PASS |
| persona-contract bundle-custom-landed assertion + GEMINI trinity kept | PASS |
| test-migrate Group-6 restructured (C-1) + backup + lift assertions | PASS |
| test-customization-preserve bundle classify + replace + preserve cases | PASS |
| `three-way.sh` VERIFY-ONLY (no edit needed) | PASS |
| validate-pack default + DEEP exit 0; NEW = ∅ | PASS |
| Full 72-script wired CI suite green | PASS |
| Empirical migrator proof a–e | PASS |
| grep-zero: remaining gemini tokens all KEEP-legitimate | PASS |
| manifest empty (not staged) | PASS |
| boundary discipline (pack-only, scripts/ only) | PASS |
| no plain-English deferral markers introduced | PASS |
| no git state-changing verb run; no patch emitted; edits uncommitted | PASS |

---

## 16. Files changed inventory

| Path | Change type |
|---|---|
| `scripts/lib/customization-preserve.sh` | modified |
| `scripts/migrate-v10-to-v11.sh` | modified |
| `scripts/init-project.sh` | modified |
| `scripts/persona-contracts/contract-migration.sh` | modified |
| `scripts/tests/test-migrate-v10-to-v11.sh` | modified |
| `scripts/tests/test-customization-preserve.sh` | modified |

(No new files. No deletions. No manifest change.)

---

## 17. Handoff status

- Edits LEFT UNCOMMITTED in the worktree
  `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-adcb03ef07394ff01`.
- NO patch emitted (BD-226 model: patch is produced only AFTER a read-only
  reviewer confirms CLEAN, via SendMessage to this agent).
- NO git state-changing verb run. Base HEAD `c4beb8d` unchanged.
- Awaiting the post-review SendMessage.

---

## 18. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs run: `git rev-parse`, `git status`, `git diff`, `git check-ignore`. NO add/commit/push/apply/stash/checkout/restore. No patch emitted. `git status --short` shows ` M` on exactly the 6 scoped files. | COMPLIANT |
| per-action-approval-sub-agents | The one destructive op (removing the stray `.pack-migrate-v10-to-v11/` test-scratch dir) was first VERIFIED to contain only migrator-state scratch (`dry-run.fingerprint` + empty `diffs/`, no source) before `rm -rf`. The `three-way.sh` "edit only if empirically needed" gate was respected — no edit needed, no edit made. No unexpected state required a STOP. | COMPLIANT |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line `PREFLIGHT: 6/6 edits complete; validate default+DEEP green NEW=0; migrator empirically correct …; full suite green; manifest empty; C-1+C-2 applied; HEAD c4beb8d; about to Write IMPL-REPORT …` ONLY after all gates passed (validate 0/0, NEW=0, suite 72/72, manifest empty). No stop/halt message received. | COMPLIANT |
| worktree-isolation-model | pwd verified `…/.claude/worktrees/agent-adcb03ef07394ff01`; HEAD `c4beb8d`. NO upfront patch; edits uncommitted; patch deferred to post-review SendMessage. Background `build.sh`/migrator runs targeted `/tmp` clones only (never a real fixture/project). | COMPLIANT |
| edit-in-place-not-full-rewrite | Every change is a targeted `Edit` (insert/replace a specific block), never a full-file Write. Re-read the customization-preserve classifier region (L164-199) + migrator install block (L365-415) after editing to confirm the section maps are intact and ordering correct (`x-` bundle leg before `*.md` bundle leg). | COMPLIANT |
| verify-full-ci-suite | Ran EVERY script in the wired set (72, from `ci-shard-plan.py --print-partition`) individually, tallied PASS=72 FAIL=0 — not validate-pack + a sampled integration test. Plus validate default + DEEP. Saved per-script results to `/tmp/cx1-suite-results.txt`. | COMPLIANT |
| rename-plans-measure-then-bound | grep-zero gate run over the 6 edited files (`grep -icE gemini`): every remaining hit categorized as KEEP-legitimate (the migration's mandated `.gemini/` source/retire refs + `gemini-retired-docs/` + `GEMINI.md` trinity). Zero net-new gemini tokens in customization-preserve (beyond a docstring ref to the existing leg) and init-project. Evidence §9. | COMPLIANT |
| manifest-regen-on-v11-surface | Ran `bash test-fixtures/build.sh --all --clean`; `git diff --quiet test-fixtures/manifest.txt` → EMPTY. Confirmed (matches plan EB-5: fresh-init unchanged). NOT staged. | COMPLIANT |
| architect-doc-reality-reconciliation | New/changed comments name the realized model ("BD-221 corrected agent-migration model", the `_v10_to_v11_lift_gemini_customs_to_bundle` helper, the classifier-leg cross-reference in customization-preserve.sh) WITHOUT line numbers — e.g. the migrator header references "customization-preserve.sh" by file + the lift helper by name. | COMPLIANT |
| ci-check-runtime-compounding | No new validate-pack check added; no whole-tree scan or subprocess-per-entry storm introduced. The bundle install/lift iterate only the (16-file) pack bundle source + the client's x- customs — bounded, per-target. | COMPLIANT |

---

*End IMPL-REPORT-CX1 — pack-coder, isolated worktree HEAD `c4beb8d`,
2026-06-17. 6 files; validate default+DEEP green (NEW=∅); full suite 72/72;
migrator empirically correct (a–e); C-1+C-2 applied; manifest empty;
pack-only; no patch emitted; awaiting post-review SendMessage.*
