# PACK-REVIEW — BD-214 C3 (project-side + installers + Check-51 legs 3/5)

**Reviewer:** fresh pack-reviewer. **Date:** 2026-06-13.
**Base HEAD:** `c994d82cdab77c3ebddabe1c4db6b56d50454201` (C2 landed).
**Scope:** entire uncommitted C3 working-tree change set (33 tracked files + 1 untracked IMPL-REPORT).
**Read-only:** this report is the sole write.

## VERDICT — APPROVE-WITH-FIXES

The C3 mechanics (install-map atomic removal, Check-51 legs 3+5, trinity parity,
manifest, meaning preservation, full CI) are correct and the entire wired CI
battery is GREEN. Two real findings block a clean approval:

- **BLOCKER B-1** — pack-self leak: ~21 new `BD-214` references injected into the
  client-shipped `project-template/` tree (BD-free at base HEAD).
- **MUST M-1** — stale ground-truth: `migrator_target_surface_for_version v11`
  still declares `tracker.toml.example` as a v11-install surface (now false), and
  the test pins the stale value — an enumerate-encoding-surfaces gap (CI stays
  green against the wrong data).

Plus SHOULD/NIT items below. The three surfaced items are adjudicated.

---

## FINDINGS BY SEVERITY

### BLOCKER

**B-1 — `BD-214` pack-self ID leaked into client-shipped `project-template/` content.**
At the C3 base HEAD the `project-template/` tree carries ZERO `BD-NNN` references
(`git grep -l 'BD-[0-9]' c994d82 -- project-template/` → 0 files). C3 introduces
~21 new `BD-214` citations across client-shipped files:

```
3  project-template/.claude/skills/pm-startup/SKILL.md
3  project-template/.codex/skills/pm-startup/SKILL.md
3  project-template/.gemini/commands/pm-startup.toml
3  project-template/skills/pm-startup/SKILL.md
2  project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
1  project-template/docs/pack/HELP-FRAGMENT.md
1  project-template/docs/pack/OPTIONAL-FEATURES.md
2  project-template/docs/pack/PM-CHAT.md
1  project-template/docs/pack/prompts/auditor.md
1  project-template/docs/pack/prompts/coder.md
1  project-template/docs/project/backlog/_intro.md
1  project-template/docs/project/changelog/_intro.md
1  project-template/docs/project/implementation-plan/_intro.md
```

Example (`project-template/docs/project/backlog/_intro.md`):
`+Tracker mode is deferred indefinitely (no release version, BD-214);`

`BD-214` is a pack-repo backlog ID — a pack-self operational concept. Per the
categorical no-pack-self-in-project rule (`feedback_bd_pack_only_operational_rule`:
"BDs, maintenance-docs/, pack-* names, etc.; directory-based not ship-based;
surgical removal default"), `feedback_client_ref_delete_or_forward_look` (a
client-shipped pack-only ref → DELETE the ref), and P-missed-7 (never import a
pack-only mechanism into client content), a client who installs the pack receives
prose citing an un-resolvable pack BD ID. The design (§4/§5 client story) and
plan (§7) prescribed "deferral notes," NOT BD-214 citations; the coder added the
`(BD-214)` parenthetical on its own. The deferral note itself is correct and
must STAY — only the `BD-214` token must go (e.g. "tracker integration is
deferred indefinitely (no release version)"). validate-pack has NO check gating
BD-refs in `project-template/`, so this stayed green — itself the audit gap.

Note: `supporting-docs/` already carries BD refs at HEAD (MIGRATION-v10-to-v11.md
has 17), so the 13 new `BD-214` hits in `supporting-docs/` (DEPENDENCIES ×4,
MIGRATION ×8, METHODOLOGY ×1) are consistent with the existing convention on
that surface and are NOT part of B-1. B-1 is scoped to `project-template/` only.

**Fix:** strip the `BD-214` token from the ~21 `project-template/` occurrences
(keep the deferral prose). Leave `supporting-docs/` as-is.

### MUST

**M-1 — stale v11 install-surface ground-truth in `scripts/lib/migrator-core.sh`
(+ test pins the stale value).**
`migrator_target_surface_for_version v11` (scripts/lib/migrator-core.sh, the
`v11)` case) still lists `tracker.toml.example` (the line inside the v11
heredoc). Its docstring (function header) declares it the authoritative
"list of project-relative paths that **a vN install creates** ... avoids
duplicating surface knowledge across init-project.sh, migrate-vN-to-vM.sh, and
test-fixtures/build.sh." After C3, a v11 install no longer creates
`tracker.toml.example`, so this ground-truth declaration is now FALSE.
`scripts/test-migrator-core.sh` asserts the stale value:
`"$out" == *"tracker.toml.example"*` and the pass message
"adds HELP-FRAGMENT/tracker.toml.example/...". Because the test was not flipped,
CI stays GREEN against the wrong data — exactly the asymmetric-coverage audit gap
`enumerate-encoding-surfaces` warns about. Blast radius is contained today
(`test-fixtures/build.sh` does NOT consume the helper at runtime — paths are
hardcoded inline per build.sh's own header, and no v11 fixture contains
`tracker.toml.example`), which is why this is MUST not BLOCKER. But the
ground-truth surface that C3's install change should have propagated to was
missed.

**Fix:** remove `tracker.toml.example` from the `v11)` heredoc in
`migrator-core.sh` (and update the adjacent comment that says "tracker.toml,"),
then flip `test-migrator-core.sh` to assert ABSENCE (mirroring the persona-contract
pattern) + update its pass message.

### SHOULD

**S-1 — S11 stage banner still advertises "tracker".**
`scripts/init-project.sh` S11 banner reads
`"── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──"`.
The plan (§7 / design §3 Layer C, ":908 drops the tracker advertisement") called
for the banner to drop the tracker mention since S11 no longer installs any
tracker artifact. The S11 sub-stage 2 comment and copy were correctly removed,
but the stage banner word "tracker" was left. Low-impact (cosmetic stage label)
but it is a literal plan item that was not applied.

### NIT

**N-1 — HELP-FRAGMENT-TRACKER stub "at a client project root" reference.**
The project-copy stub's closing line references `tracker.toml.example` "at a
client project root" as a config record. For clients installed post-C3 that file
won't exist; existing clients keep an inert copy. The phrasing is generic and
historically accurate, so this is a NIT, not a fix-required item. (Independent of
the B-1 BD-214 issue, which also appears in this file.)

**N-2 — IMPL-REPORT is untracked.** `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C3.md`
is `??` and `maintenance-docs/` is not a v11-surface dir; harmless, but Pack Chat
should be deliberate about whether it rides C3 (it is not in the plan's C3 file list).

---

## THE THREE SURFACED ITEMS — EXPLICIT VERDICTS

### Item 1 — `backlog/BD-214.md` pre-existing dated note — VERDICT: CORRECTLY OUT OF C3 SCOPE.
`git diff c994d82 -- backlog/BD-214.md` is BYTE-IDENTICAL to the working-tree
diff: the single added line is the 2026-06-12 user-decisions note that was
already dirty at the C3 base HEAD (the planning/architecture session's
working-tree state, per the PLAN/ARCHITECTURE headers). It is NOT a C3 edit. It
is `pack-chat-only` bookkeeping that belongs to C5b, not C3. **Caution for Pack
Chat:** stage C3 by explicit pathspec — do NOT sweep `backlog/BD-214.md` into the
C3 commit.

### Item 2 — Leg-3 bounded-scan deviation — VERDICT: SOUND for the current tree; ACCEPTABLE long-term with a documented residual blind-spot (not a finding that blocks C3).
The design's leg-3 (§6.3 / EE-7 / CLAUDE.md Check-51 leg-3) was a whole-tree
`recommendation_should_recommend`-OUTSIDE-allowlist `{scripts/lib/recommendation.sh,
scripts/tests/, maintenance-docs/}` == 0. The coder implemented a BOUNDED scan of
7 hardcoded skill/command dirs (`_CHECK_51_RECOMMEND_SKILL_DIRS`), citing
`feedback-ci-check-runtime-compounding`.

Independent whole-tree measurement (`grep -rln 'recommendation_should_recommend'
. --exclude-dir=.git`) at the working tree:
```
maintenance-docs/...  (×8 — allowlisted by design)
scripts/lib/recommendation.sh        (allowlisted — the dormant lib)
scripts/tests/recommendation-test.sh (allowlisted)
scripts/tests/test-validate-pack-check-51-flip-block.sh (the test's BAD_SKILL literal)
scripts/validate-pack.py             (the check's own token literal)
```
The 7 skill files no longer contain the token (strip COMPLETE). So the bounded
scan and the whole-tree-minus-allowlist approach BOTH yield 0 today — the design
intent is met for the current tree, and the runtime-compounding rationale is
legitimate (a whole-tree `rglob` runs across the battery's ~151 validate-pack
invocations).

Residual blind-spot (honest assessment): the bounded scan only inspects the 7
hardcoded dirs. A future invocation added OUTSIDE them — e.g. a new
`scripts/init-project.sh` call, a NEW per-CLI dir (note `.gemini/skills` exists
pack-side but is NOT in the tuple; `test-fixtures/v11-*/.gemini/commands` exist),
or a renamed CLI surface — would EVADE the guard, whereas the design's
whole-tree-minus-allowlist would catch it. This is a real narrowing of the
design's guarantee. However: (a) the D-19 invocation is architecturally confined
to session-startup skill/command surfaces (EE-7 establishes the live-invoker
surface as exactly these CLI startup files), so a new invoker outside them would
be an unusual change; (b) the bound is documented in-code with the rationale.
VERDICT: SOUND enough to ship at C3 (today's condition is provably true and the
design intent met); the narrowing is a documented residual, acceptable under the
runtime rule. Recommend (SHOULD, not blocking) the bounded dir-tuple gain a
comment directing future CLI-surface additions to extend the tuple — otherwise a
new `.gemini/skills`-style startup surface would silently fall outside the guard.

### Item 3 — Extra test edits (`test-migrate-v10-to-v11.sh` + 2 persona-contracts) — VERDICT: LEGITIMATELY IN-SCOPE-BY-CONSEQUENCE; assertions are REAL, not band-aids.
All three encode the C3-changed install behavior (enumerate-encoding-surfaces) —
without them the tests would have FAILED (their old assertions expected the file
PRESENT). The new assertions are genuine ABSENCE checks:

`test-migrate-v10-to-v11.sh` — inverted from PASS-on-present to PASS-on-absent:
```
[[ ! -f "$T/tracker.toml.example" ]] \
    && t_pass "2.4 tracker.toml.example NOT installed (tracker deferred, BD-214)" \
    || t_fail "2.4 tracker.toml.example unexpectedly installed (should be deferred, BD-214)"
```

`contract-greenfield.sh` / `contract-migration.sh` — removed the file from the
must-EXIST array AND added an explicit positive absence assertion (stronger than
mere deletion):
```
if [[ ! -f "$SANDBOX/tracker.toml.example" ]]; then
    t_pass "S11 artifact tracker.toml.example NOT installed (tracker deferred, BD-214)"
else
    t_fail "S11 artifact tracker.toml.example unexpectedly installed (should be deferred, BD-214)"
fi
```
These would FAIL if the install behavior regressed — real coverage, not weakened
checks. The enumeration was complete: `test-init-project.sh` carries the matching
inversion; the remaining `tracker.toml.example` refs in `test-migrator-manifest.sh`
are a generic sample manifest entry exercising the framework's add/skip logic
(coincidental name reuse, not an encoding of install policy) and correctly left.
(The `test-migrator-core.sh` ref is the M-1 finding — that one IS an encoding of
install surface and was MISSED.)

---

## FULL CI WIRED-TEST RESULTS (every step in `.github/workflows/validate-pack.yml`, both jobs)

Command list extracted from the workflow `run:` lines (validate-pack job + tests
job). Every wired script RUN; all EXIT=0.

**validate-pack legs:**
- `python3 scripts/validate-pack.py` → EXIT 0; final line `PASSED — all checks clean`.
  Check 39 OK (34 cmd_update entries, 0 asymmetric), Check 41 OK (36
  `_CLIENT_INSTALLED_FILES` entries, 0 drift), Check 46 OK, Check 51 OK (legs 1-5,
  "tracker.toml.example absent from the install map (leg 5)"). Checks 22/23 OK
  (GAP-5 empirical re-run confirmed green).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → EXIT 0; `PASSED — all checks clean`.

**tests job — 55 wired scripts, all PASS (EXIT 0):**
detect.sh; tracker-provider; tracker-config; tracker-init; tracker-agent-read;
tracker-migrate-forward; tracker-migrate-reverse; tracker-migrate-roundtrip;
test-tracker-phase-task; test-tracker-links; test-tracker-cycle-check;
tracker-errors; tracker-config-schema; recommendation-state-schema; test-per-entry;
checks-32-33-34; checks-36-37-38; check-39; check-40; check-41; check-18; check-16;
check-19; check-42; check-43; check-44; check-45; check-46; removed-doc-advisory;
check-49-field-faithfulness; check-50-codec-single-source;
**check-51-flip-block (legs 1-5, T1-T8, EXIT 0)**; tracker-deferral-gate;
tracker-bd129; tracker-bd130; tracker-bd132; tracker-bd133; tracker-bd134;
recommendation-test; pack-help-test; test-customization-preserve;
**test-init-project**; **test-migrate-v10-to-v11**; test-migrate-v10-to-v11-dry-run;
**test-migrate-v10-to-v11-gates**; test-migrate-v10-to-v11-decompose;
test-migrator-core; test-migrator-manifest; test-migrator-capability-translation;
**test-v11-realistic-ot**; test-migrator-skills; **test-persona-contracts**;
**template-translations-test**; template-version-test; test-issue-forms.

(Batch-1 40/40 PASS, Batch-2 15/15 PASS; FAILED list empty in both runs.)

**Manifest (`regenerate-manifest-v11-surface`):**
- `bash test-fixtures/build.sh --all --clean` → EXIT 0; `diff` of freshly
  regenerated `test-fixtures/manifest.txt` vs the staged manifest → IDENTICAL.
- `bash test-fixtures/build.sh --verify` → EXIT 0 (v11-flat-file / v11-tracker-on /
  existing-project-mid-dev all OK). The staged manifest is consistent and must
  ride C3.

**Mixed-scope:** the diff legitimately spans `scripts/` + `project-template/` +
`supporting-docs/` → NO scope keyword belongs on C3 (Check 36 skipped). Confirmed.

**Trinity parity:** project-template CLAUDE/AGENTS/GEMINI carry byte-identical
hunks (same two reworded blocks). The changed sections are CLI-neutral prose
(`docs/project/`, `pm-startup Step 2`, `<stream>/_rules.md` — no per-CLI
paths/commands), so byte-identical parity is correct; no audience-correct
normalization was required and none was missed. validate-pack trinity checks pass.
pm-startup ×4 Step-8 bodies are likewise parity-consistent. (Both surfaces carry
the B-1 BD-214 leak.)

**Meaning preserved / no dropped sections:** spot-verified across the prose sweep
(_intro ×3, prompts ×5, HELP-FRAGMENT-TRACKER stub, PM-CHAT, OPTIONAL-FEATURES,
supporting-docs). Each tracker-mode arm is replaced by a deferral note; still-true
content (read-only posture, PM-chat ownership, mirror/source-of-truth statements,
`_rules.md` pointers, TD-promotion section, verb tokens for Check 22/23) is
retained. No other pack-self token leaked (no pack-ops / pack-* agents /
PACK-CHAT / maintenance-docs in any new client line — verified by grep).

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status --short`, `git log --oneline`, `git diff`, `git show`, `git grep` — all read-only. Zero `add/commit/push/tag/reset/stash/checkout/rm`. | COMPLIANT |
| 2. Read-only mandate | Sole write: this report at the prompt-specified path. `cp test-fixtures/manifest.txt /tmp/...` (scratch copy) + `build.sh --all --clean` regenerated `manifest.txt` to byte-identical (verified IDENTICAL; no net tree change). No other codebase file edited. | COMPLIANT |
| 3. Independent verification | Every PASS carries the command + quoted output: validate-pack EXIT 0 + `PASSED — all checks clean`; DEEP EXIT 0; 55/55 wired tests PASS (batch outputs quoted, FAILED empty); manifest `diff` IDENTICAL + `--verify` EXIT 0; whole-tree `recommendation_should_recommend` grep re-run for item 2. | COMPLIANT |
| 4. Real-fixes-only enforcement | Hunted band-aids: item-3 test assertions quoted verbatim and verified as genuine ABSENCE inversions (not weakened); M-1 caught a MISSED encoding surface where CI stays green against stale data; B-1 caught a pack-self leak validate-pack does not gate. | COMPLIANT |
| 5. Severity-tagged findings | B-1 (BLOCKER), M-1 (MUST), S-1 (SHOULD), N-1/N-2 (NIT) each with file + locus; 3 surfaced items each given an explicit verdict. | COMPLIANT |
| 6. Rules-Applied Verification Block | This table; per-rule quoted evidence; zero empty cells. | COMPLIANT |
| 7. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; full CI wired-test job run ...; about to Write <path>` in the message immediately before this write. No stop/halt/revert received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete:
CLAUDE.md (full, incl. all `## Pack memory` — via system context, re-read);
PLAN-BD-214-TRACKER-DEFERRAL.md (full, 499 lines incl. C3 spec §7 + green-per-commit
table §2); ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both pages, 853 lines incl.
§3 legs/Layer C, §4 Axis A-I, §5 project-side story, §6.3 leg defs, §6.6 changelog
reword, §8-§14a). Every changed file inspected via `git diff` + direct read
(scripts/validate-pack.py Check 51 + 39/41/46, init-project.sh, migrate-v10-to-v11.sh,
test-validate-pack-check-51-flip-block.sh, project-template trinity ×3, pm-startup ×4,
PM-CHAT/OPTIONAL-FEATURES/HELP-FRAGMENT-TRACKER/HELP-FRAGMENT/prompts ×5/_intro ×3,
supporting-docs ×3, test-migrate-v10-to-v11.sh, persona-contracts ×2,
migrator-core.sh, test-migrator-core.sh, test-migrator-manifest.sh, build.sh).
No named document was derived rather than read.

**End of PACK-REVIEW-BD-214-C3.md**
