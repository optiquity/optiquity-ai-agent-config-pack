# PACK-REVIEW — BD-200 commit C3 (review-1)

**Reviewer:** fresh `pack-reviewer` (read-only). **Branch:** `v11-dev`. **HEAD:** `3bc96fa`.
**Date:** 2026-06-04. **Cycle position:** coder → **review-1** (this report) → triage → fix-1 → review-2. Pair 1 of max 2.
**Scope reviewed:** the uncommitted C3 working-tree change only (NEW `project-template/scripts/activate-capability.sh`, NEW `scripts/tests/test-activate-capability.sh`, MODIFIED `project-template/docs/pack/HELP-FRAGMENT.md` + `project-template/docs/pack/PM-CHAT.md` + `supporting-docs/INSTALL-PROCEDURES.md`, regenerated `test-fixtures/manifest.txt`). Prior IMPL/PACK-REVIEW reports NOT read (bias rule).

---

## Verdict (lead)

**FINDINGS-TO-FIX — 1 MUST, 1 NIT.** The boundary discipline (C3's highest-risk dimension) is **CLEAN**: zero pack-self tokens in the new client script or in any C3-added doc line; Check 43 / 37 / 22 / 41 / 47 all green; `validate-pack.py` exits 0. The fresh-clone activation walk and the `x-`-overwrite guard both independently reproduce and are load-bearing (not cosmetic). The harness is real (25/25, genuinely exercises both walks). Scope is exactly the expected six files; BD-202 update-path logic is absent; the frozen Check-47 2-tuple is unmoved; C1/C2 files are untouched.

The one MUST is a **property-fit / parity defect**: the script writes a `.pack-*`-named prompt artifact (`.pack-activate-capability-prompt.md`) into the client tree but — unlike its established sibling `add-capability.sh` — never adds it to `.gitignore`, breaking the architect-documented invariant that the `.pack-*` name pattern *means* gitignored, and polluting the client commit.

---

## Findings

### F1 — MUST — `.pack-activate-capability-prompt.md` is written but never gitignored (breaks the `.pack-*` = gitignored invariant + sibling parity)

**File:** `project-template/scripts/activate-capability.sh:53,371` (writes `.pack-activate-capability-prompt.md`); no `.gitignore`-append anywhere in the script.

**Evidence — the script names a `.pack-*` artifact and writes it to the live tree:**
```
53: readonly PROMPT_FILE=".pack-activate-capability-prompt.md"
371:    printf '%s' "$report" > "$TARGET/$PROMPT_FILE"
```

**Evidence — the established sibling DOES gitignore its prompt (`scripts/add-capability.sh:445-448`):**
```
    # Ensure the prompt file pattern is gitignored.
    if [[ -f "$TARGET/.gitignore" ]] && ! grep -Fxq "$PROMPT_FILE" "$TARGET/.gitignore"; then
        printf '%s\n' "$PROMPT_FILE" >> "$TARGET/.gitignore"
        info "+ $PROMPT_FILE to .gitignore"
    fi
```

**Evidence — the architect explicitly measured `.pack-*` ⇒ gitignored as an invariant** (`ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3 GAP-C + EEB at line 273):
> "Every `.pack-*` artifact in the tree today is gitignored (`.pack-tracker/`, `.pack-add-capability-prompt.md`) … the pool's client location must NOT use a `.pack-*` name pattern (that pattern *means* gitignored)."
> EEB: "`add-capability.sh:67 PROMPT_FILE=".pack-add-capability-prompt.md"` (and A6 adds `$PROMPT_FILE` to `.gitignore`)."

**Evidence — my own walk: after activation the prompt file is untracked and NOT ignored, and would be swept into the activation commit** (scratch `/tmp` clone, cleaned up):
```
=== git status of clone after activation ===
?? .pack-activate-capability-prompt.md      # alongside the legitimately-untracked materialized python set
=== git check-ignore .pack-activate-capability-prompt.md ===
NOT IGNORED (would be committed)
```
The developer commits the activation via `git add -A` (Procedure 6 / the script's own closing instruction "Review git diff, then … commit on a feature branch"), so this transient PM-chat-prompt artifact gets committed into the client project. The sibling `add-capability.sh` was built to prevent exactly this.

**Why MUST (not NIT):** this violates an architect-measured invariant (the `.pack-*` name pattern denotes gitignored local state — the same property-fit reasoning GAP-C used to forbid `.pack-*` for the *pool*), and it is a direct parity break with the one sibling script that does the identical job. The result is real client-project pollution (a committed ephemeral prompt file), not a style nit.

**Recommended fix:** add the same gitignore-ensure block `add-capability.sh:445-448` uses (append `$PROMPT_FILE` to `$TARGET/.gitignore` if absent) after the prompt is written — or, equivalently, the architect's alternative of not using a `.pack-*` name for a tracked artifact. The gitignore-append matches the sibling and the established convention; prefer it. Add a harness assertion (Group 1) that `git check-ignore .pack-activate-capability-prompt.md` succeeds after a run, so the encoding-surface stays symmetric (`enumerate-encoding-surfaces`).

---

### F2 — NIT — `is_x_prefixed` is referenced in P2 (line 251) before its definition (line 279)

**File:** `project-template/scripts/activate-capability.sh:251` (call in `stage_p2_delta`) vs `:279` (definition).

**Evidence:**
```
251:        if [[ -e "$TARGET/$f" ]] && ! is_x_prefixed "$TARGET/$f"; then
279: is_x_prefixed() { [[ "$(basename "$1")" == x-* ]]; }
```

**Assessment:** NOT a bug at runtime — bash resolves function names at call time, and `main()` sources the whole file before invoking `stage_p2_delta`, so `is_x_prefixed` is defined by the time P2 runs (verified: `bash -n` clean; both behavioral walks pass; the x- guard fires correctly in P2's pass-through path). It is purely a readability nit: the helper is defined under the P5 banner but first consumed in P2. **Recommend** (optional) hoisting `is_x_prefixed` into the `── Helpers ──` block near `say`/`warn`/`die` (lines 62-67) so definition precedes first use. Triage may SKIP as cosmetic; no behavioral impact.

---

## Verification results (each independently measured)

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | **Boundary — zero pack-self tokens in new client surfaces** | **PASS** | `grep -nE '\$PACK|pack-(architect\|planner\|coder\|reviewer)|maintenance-docs/|BD-[0-9]|pack-ops/|from the pack|Pack Chat'` on `activate-capability.sh` → ZERO; same grep on C3-ADDED doc lines (diff `^+`) → ZERO. Check 43 + Check 37 green. |
| 2 | **Pre-existing occurrences (assess, don't assume)** | **Pre-existing + LEGITIMATE; out-of-C3-scope** | PM-CHAT.md `Pack Chat`/`pack-ops/MERGE-STRATEGY.md` hits (lines 342/344/533) are byte-identical to `3bc96fa:` HEAD (diff = line-number shift only from C3's +2 net) AND are wrapped in `<!-- DENY-LIST-CONTENT-START/END -->` fences → Check 37 admits them (580 fenced lines exempt). INSTALL-PROCEDURES `$PACK`/`Pack Chat` hits (238/305/615/661/1014/1106-7) are in unrelated sections C3 never touched, pre-existing, CI-green. None introduced by C3; none flagged. No scope expansion warranted. |
| 3 | **`activate-capability.sh` correctness** | **PASS** | NO `$PACK` (grep ZERO); sources its OWN `$SCRIPT_DIR/capability-tables.sh` (line 79), not `$PACK`; reads `pack-capability-pool/` (line 102, P5). Stage set P0/P1/P2/P5/P8 present + invoked in `main()`. P0 = git-repo + clean-tree + AI-config + **pool-exists** (no `$PACK` check); P1 resolve; P5 copy-from-pool; P8 prompt. The extra P2 (delta) is a plan-faithful narrowing (PLAN §2 T3 "files to materialize = resolved not already present"), preventing re-clobber of existing files — acceptable, not a gap. |
| 4 | **`x-`-on-overwrite guard (independently exercised)** | **PASS — load-bearing** | My own `/tmp` walk: injected `language:python → "pyproject.toml scripts/x-keep.sh"` into the clone's installed tables, pre-placed `x-keep.sh`=`MY-PROJECT-CODE`, pool master=`POOL-WOULD-CLOBBER`. After run: `warning: preserving project-authored file (x- prefix, not overwritten): scripts/x-keep.sh`; `x-keep.sh` content = `MY-PROJECT-CODE` (preserved byte-for-byte); non-x- `pyproject.toml` WRITTEN in the same run (guard is path-faithful, not whole-run abort). |
| 5 | **Fresh-clone activation walk (re-proven myself)** | **PASS** | My own walk: Swift-only fixture via `init-project.sh`, `git clone` to `/tmp` scratch, `env -u PACK bash scripts/activate-capability.sh --add language:python`. Pool present; live `pyproject.toml` ABSENT pre-run; post-run the full python set (`pyproject.toml`, `server/`, `bootstrap/format/validate/test-python.sh`) re-materialized FROM the pool; `grep -c PACK` on the clone's installed script invocation path → 0. |
| 6 | **T6 doc rework** | **PASS** | HELP-FRAGMENT.md:15 has a valid `activate-capability.sh` verb row. PM-CHAT.md:389 names client `scripts/activate-capability.sh` + "from the pack" removed (diff confirms). INSTALL-PROCEDURES.md R3: deletions bullet (53-57) DROPS `add-capability.sh` (now lists only `init-project.sh` + `migrate-vN-to-vM.sh`); overwrites bullet (58-67) ADDS `activate-capability.sh` with the skip-and-warn explanation; both explanatory bullets + the "roster never starts with x-" bullet intact. Zero `add-capability` refs remain in the three C3 docs. |
| 7 | **Check 22 green** | **PASS** | `validate-pack.py` Check 22: "project-template: 2 prose-referenced verb(s) all present in fragment." The `activate-capability.sh` verb resolves (PM-CHAT + HELP-FRAGMENT + on-disk `project-template/scripts/activate-capability.sh`); no dangling stale `add-capability.sh` token in the C3 docs trips it. |
| 8 | **Harness green + genuine** | **PASS** | `bash scripts/tests/test-activate-capability.sh` → 25 passed / 0 failed, exit 0. Group 1 = real init-project install + real `git clone` + real `env -u PACK` activation (asserts pool population, S9 live-removal, P5 re-materialization, executability, pack-self-clean prompt). Group 2 = genuine x- guard exercise (rewrites the clone's OWN installed tables to force an x- resolution — not a stub). Self-provisions `/tmp` mktemp dirs + trap cleanup (`test-infra-self-provisioned`). |
| 9 | **Manifest** | **PASS** | Exactly the three v11-* rows moved (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`); v10-* + `existing-project-mid-dev` unchanged. `bash test-fixtures/build.sh --all --clean` reproduces the staged manifest byte-for-byte (no drift). `scripts/tests/` harness has 0 manifest rows → not installed → correctly does NOT move the manifest (C3 moves it via the S5-shipped `activate-capability.sh`). |
| 10 | **Guards + scope** | **PASS** | `validate-pack.py` exit 0 (Check 48 emits advisory WARNs on pre-existing CHANGELOG/BACKLOG removed-doc cites — JC-5 soft-advisory, exit-code-unaffected, unrelated to C3). Check 47 frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` unmoved. Scope = exactly the 4 modified + 2 new (non-report) files. BD-202 boundary intact: grep for `pack update|cmd_update|wipe.?repopulate|three_way|customization_preserve` in C3 scripts → ZERO. C1/C2 files (`add-capability.sh`, `init-project.sh`, `capability-tables.sh`) unchanged in the working tree (committed in C1/C2). |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL** (agents-read-rule-docs-in-full) | All named files Read IN FULL via Read tool: `CLAUDE.md` (541 lines, first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)` → last `testing (use /tmp clones or scratch fixtures…)`); `pack-ops/PACK-AGENTS.md` (226 lines, full); `pack-ops/PACK-CHAT.md` (310 lines, full); `project-template/CLAUDE.md` (456 lines, full); `PLAN-BD-200.md` (234 lines, full — incl. §2 T3/T6, §3, §5, §6, R3/R5); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.1/§3.7/§4.2/§4.4/§4.6 (lines 68-197) + headers map + §10 boundary lines; BD-200 entry `pack-ops/BACKLOG.md:3273-3306` + BD-202 `:3310-3327` (full); curated memory (each full): `feedback_agents_read_rule_docs_in_full.md` (71L), `feedback_agent_output_rules_applied_block.md` (14L), `feedback_manifest_regen_on_v11_surface.md` (15L), `feedback_bd_pack_only_operational_rule.md` (34L), `feedback_pack_project_separation_of_concerns.md` (32L), `feedback_client_ref_delete_or_forward_look.md` (40L), `feedback_review_cycle_position_checkpoint.md` (56L). | **COMPLIANT** |
| **boundary / no-pack-self-in-project** (CRITICAL) | `grep` on `activate-capability.sh` for `$PACK`/`pack-*`/`maintenance-docs/`/`BD-NNN`/`pack-ops/`/"from the pack"/`Pack Chat` → ZERO; same on C3-added doc lines → ZERO; Check 43 (158 files, zero bare refs) + Check 37 (170 files, zero contamination) green. | **COMPLIANT** |
| **client-ref delete-or-forward-look** | T6 reworks: HELP-FRAGMENT/PM-CHAT replace the (pack-only-shaped) `add-capability.sh from the pack` reference with the genuine client asset `scripts/activate-capability.sh` (forward-look to the landed client path — case 2). INSTALL-PROCEDURES R3 8a/8b is a correctness edit on legitimate explanatory `x-`-contract prose (op-vs-explanatory test → explanatory → preserve+correct, not strip). | **COMPLIANT** |
| **enumerate-encoding-surfaces** | The verb is encoded across script (on-disk) + HELP-FRAGMENT + PM-CHAT + Check 22 + INSTALL-PROCEDURES `x-` bullet + the harness; all verified lock-step consistent. The ONE asymmetry found: the `.pack-*` prompt artifact has no gitignore encoding partner (F1) — surfaced as MUST with a harness-assertion recommendation to close it. | **COMPLIANT** |
| **empirical verification** | Every verdict backed by a quoted command result: ran `validate-pack.py` (exit 0), the harness (25/25), my OWN fresh-clone walk + my OWN x- guard walk on `/tmp` scratch trees, manifest regen-diff, boundary greps. No claim asserted without measurement. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Checks 22/37/41/43/47 measured green at HEAD `3bc96fa` working tree; Check 47 frozen 2-tuple confirmed unmoved (measured); manifest regen measured reproducible. | **COMPLIANT** |
| **BD-202 boundary** | grep for `pack update`/`cmd_update`/`wipe.?repopulate`/`pool refresh`/`three_way`/`customization_preserve` in both C3 scripts → ZERO hits. No update-path logic present. | **COMPLIANT** |
| **review-cycle-position-checkpoint** | Stated in header: this is review-1 on C3 → findings → fix-coder (fix-1) → review-2 mandated before commit; pair 1 of max 2. Reviewer is read-only; applied no fixes. | **COMPLIANT** |
| **scope-deliverables-to-the-ask** | Reviewed exactly C3 (the 6 files); led with verdict; findings limited to 1 MUST + 1 NIT; no sprawl, no SUSPECTED/edge-case padding; pre-existing occurrences assessed and explicitly bounded out-of-scope rather than expanded. | **COMPLIANT** |
| **rules-applied-verification-block** | This block — per-rule name + measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line count + first/last anchors). | **COMPLIANT** |
| **agents-never-commit** | Only read-only verbs used (`git status/diff/show/rev-parse/clone/init/add/commit` against `/tmp` SCRATCH fixtures only — never the pack repo; `grep`/`sed`/`ls`/`python3 validate-pack.py`/`bash` test). No `git add/commit/push/tag` against the pack working tree. Single Write = this report at the caller-specified path. | **COMPLIANT** |
