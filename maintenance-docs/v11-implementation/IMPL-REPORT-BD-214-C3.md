# IMPL-REPORT — BD-214 C3 (project-side + installers; Check-51 legs 3 & 5)

**Coder:** fresh pack-coder. **Date:** 2026-06-13.
**Branch:** `v11-dev`. **Base + final HEAD:** `c994d82cdab77c3ebddabe1c4db6b56d50454201`
(no commits made — agents never commit; the working tree carries all C3 edits).
**Commit:** C3 per `PLAN-BD-214-TRACKER-DEFERRAL.md` §7 (post-renumber: project-side
+ installers + Check-51 legs 3/5). **Scope keyword:** NONE (mixed-scope: `scripts/` +
`project-template/` + `supporting-docs/`); Check 36 skipped. No scope-keyword token placed
anywhere.

## 1. Summary of outcome

- **Recommendation strip COMPLETED.** pm-startup Step 8 ×4 (canonical `skills/`, `.claude`,
  `.codex` SKILL.md + `.gemini` toml) → deferred note (step number reserved). pack-startup ×3
  were stripped at C2; the 7-file strip now COMPLETES, so Check-51 leg-3 `== 0` is TRUE.
- **Check-51 legs 3 + 5 ADDED** to `scripts/validate-pack.py` and the dedicated test extended
  to assert legs 1-5. Both legs PASS (their conditions are made true by THIS commit's strips).
- **Install-map removal (atomic):** `tracker.toml.example` removed from `init-project.sh`
  (install-map array + S11 copy + self-doc block + header comment) AND Checks 39/41/46
  re-verified GREEN in the SAME working-tree state (set-equality holds). `migrate-v10-to-v11.sh`
  stops copying the example + post-report `pack tracker init` pointer reworded to a deferral
  sentence.
- **Project trinity ×3** swept tracker-mode-as-usable prose → flat-file-only + deferred, with
  PARITY (identical text in all three; the affected sections are CLI-neutral — see §5).
- **Client docs** swept: PM-CHAT.md, project OPTIONAL-FEATURES.md, project
  HELP-FRAGMENT-TRACKER.md (deferred stub) + HELP-FRAGMENT.md, prompts ×5, project `_intro`
  ×3, DEPENDENCIES.md, MIGRATION-v10-to-v11.md (Phase B → DEFERRED), METHODOLOGY.md.
- **Lock-step tests** updated to the new correct behavior (no weakened assertions): the
  `tracker.toml.example` install assertions flipped to ABSENCE assertions; the project-side
  HELP-FRAGMENT-TRACKER heading pin updated to `(deferred)`; the Check-51 test grown.
- **FULL CI wired-test job verified locally** — every run-step from `.github/workflows/validate-pack.yml`
  (both jobs) executed; all EXIT=0. **Manifest regenerated** (non-empty diff — 3 v11 fixture
  hashes).

## 2. Check-51 legs 3 + 5 — addition + now-true conditions

**`scripts/validate-pack.py` `check_tracker_deferral_flip_block()`** (header comment + docstring +
print banner updated `(legs 1/2/4)` → `(legs 1-5)`):

- **Leg 3** — `recommendation_should_recommend` grep-zero, BOUNDED to the per-CLI
  session-startup skill/command directories `_CHECK_51_RECOMMEND_SKILL_DIRS`
  (`.claude/skills`, `.codex/skills`, `.gemini/commands`, and the four project-template
  equivalents — the ONLY surfaces that wire the D-19 invocation per design EE-7). **Bounded by
  construction — NOT a whole-tree rglob** (honors `feedback-ci-check-runtime-compounding`: the
  dormant lib + its tests + maintenance-docs, the legitimate carriers, live OUTSIDE the
  scanned dirs, so no allowlist is needed inside the bounded surface). Condition made TRUE by
  THIS commit: the pm-startup ×4 Step-8 strip removes the last 4 invokers (pack-startup ×3
  stripped at C2) → measures 0.
- **Leg 5** — `tracker.toml.example` absent from the install map: asserts the token
  `tracker.toml.project-example:tracker.toml.example` is NOT present in `init-project.sh`.
  Condition made TRUE by THIS commit: the install-map array entry + self-doc line removal.

**Dedicated test `scripts/tests/test-validate-pack-check-51-flip-block.sh`** extended in
lock-step: header + Group-1 coverage doc updated to legs 1-5; `build_tree()` now writes a
clean `init-project.sh` (leg-5) + a clean skill file under a scanned dir (leg-3); new cases
**T7** (a live `recommendation_should_recommend` invoker in a skill file ⇒ leg-3 FAIL) and
**T8** (`tracker.toml.example` in the install map ⇒ leg-5 FAIL); Group-2 grep strings updated
to `(legs 1-5)` / "legs 1-5 clean". Test result quoted in §6.

**Verification (legs now TRUE):**
```
$ grep -rln recommendation_should_recommend <7 skill dirs>   → (empty)
── Check 51: BD-214 tracker-deferral flip-block guard (legs 1-5) ──
  OK: Check 51 — ... no live recommendation invoker in skill files (leg 3),
      ... tracker.toml.example absent from the install map (leg 5).
$ grep -c "tracker.toml.project-example:tracker.toml.example" scripts/init-project.sh → 0
```
(Note: a naive whole-tree `grep recommendation_should_recommend` still matches
`scripts/validate-pack.py` itself — the leg-3 constant/messages. The bounded check does NOT
scan validate-pack.py, so leg-3 correctly passes; this is the intended bounded scope.)

## 3. Atomic install-map ↔ Checks 39/41/46 change

All in the same working-tree state (one commit):

| Surface | Edit |
|---|---|
| `scripts/init-project.sh` install-map `entries=()` array | DELETED `"project-template/tracker.toml.project-example:tracker.toml.example:generic"` (replaced with a BD-214 removal comment). |
| `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES_START/_END` self-doc block | DELETED the matching `... -> tracker.toml.example [stage:S11,cmd_update]` line (kept array + self-doc in sync ⇒ Check 41 set-equality holds). |
| `scripts/init-project.sh` S11 copy (`stage_s11_v11_artifacts` step 2) | Removed the `cp` of `tracker.toml.project-example → tracker.toml.example`; replaced with a BD-214 deferred-note comment. Step numbering (1,2,3...) preserved. |
| `scripts/init-project.sh` header comment | Dropped `tracker.toml.example` from the "v11 additions (BD-080)" install list; added a BD-214 deferral note. |
| `scripts/validate-pack.py` Checks 39 / 41 / 46 | NO code change needed — they parse the install map dynamically; with the entry removed from BOTH the array and the self-doc block, set-equality + cmd_update symmetry + boundary manifests stay consistent. Verified GREEN (quoted §6). Check-51 leg 5 ADDED (the anti-reintroduction guard). |

`_SANCTIONED_PACK_SIDE_SHIPPED` is UNCHANGED (`{scripts/lib/detect.sh, scripts/pack-help.sh}`);
the removed install is a SHRINK, not a new ship — Check 47 unaffected (verified GREEN).

**`scripts/migrate-v10-to-v11.sh`:** removed the `tracker.toml.example` copy block (replaced
with a BD-214 deferred-note comment); reworded the `migrator_post_report_hook` `say "To opt
into the v11 issue-tracker integration, run: pack tracker init"` to a deferral sentence; updated
the architectural-note header comment.

## 4. Trinity parity + cross-CLI normalization

`project-template/{CLAUDE,AGENTS,GEMINI}.md` — two sections each, edited IN THE SAME commit:
(a) the `## Document locations` Source-column prose ("flat-file ... or tracker-mirrored ... In
tracker mode ... `mixed`") → flat-file-only + deferral; the `docs/project/` row Source cell
`flat (or mixed in tracker mode)` → `flat`; (b) the "Per-entry source-of-truth trees (v11.0)"
closing sentence ("In tracker mode, the tracker is source of truth ...") → flat-file-only +
deferral. **Cross-CLI normalization:** the edited sections contain NO per-CLI path/command
tokens (they reference the `pm-startup` skill name, which is identical on all three CLIs per
ARCHITECTURE-BD-182 §4.1) — so the audience-correct canonical value IS the same string on all
three. Parity is therefore byte-identical here BY CORRECTNESS, not by byte-copy reflex
(verified: `diff` of the changed CLAUDE section vs AGENTS section = identical). validate-pack
trinity-parity check PASSED.

## 5. Per-file change inventory (change type)

All MODIFIED (no new/deleted files). Pre-existing `backlog/BD-214.md` working-tree note is NOT
mine — see §8.

**Installers / validator (scripts/):**
- `scripts/init-project.sh` — install-map array + self-doc + S11 copy + header (install-map removal)
- `scripts/migrate-v10-to-v11.sh` — example-copy removal + post-report deferral wording + header
- `scripts/validate-pack.py` — Check-51 legs 3 + 5 (constants, leg bodies, docstring, banner, ok msg)

**Project trinity (parity, same commit):**
- `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`

**pm-startup skills ×4 (leg-3 strip + Step-2 read-path sweep + Step-7 reserved note):**
- `project-template/skills/pm-startup/SKILL.md`
- `project-template/.claude/skills/pm-startup/SKILL.md`
- `project-template/.codex/skills/pm-startup/SKILL.md`
- `project-template/.gemini/commands/pm-startup.toml`

**Client docs:**
- `project-template/docs/pack/PM-CHAT.md` — recommendation-routing → deferred; TD-promote step 6
  flat-file; read/write mode-conditional prose ×6 → "the per-entry tree"
- `project-template/docs/pack/OPTIONAL-FEATURES.md` — §"Tracker integration (v11)" walkthrough
  → short "(deferred)" section
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` — deferred STUB (verb tokens retained)
- `project-template/docs/pack/HELP-FRAGMENT.md` — heading → "(deferred)" + note
- `project-template/docs/pack/prompts/{reviewer,pm-chat,coder,auditor,tester}.md` — mode-conditional
  read prose → "the per-entry tree" + deferral
- `project-template/docs/project/{backlog,implementation-plan,changelog}/_intro.md` — Source-of-truth
  → flat-file-only + deferral

**supporting-docs:**
- `supporting-docs/DEPENDENCIES.md` — gh / gh-sub-issue rows + sections → "required only for the
  deferred tracker feature (dormant)"; trailing OPTIONAL-FEATURES § ref → "(deferred)"
- `supporting-docs/MIGRATION-v10-to-v11.md` — Phase B → DEFERRED (overview, What-changed,
  Step 5, Commit-sanity comment, S5 stage row, "after migration" decide-Phase-B, install bullet)
- `supporting-docs/METHODOLOGY.md` — Phase N.M blocker mode-conditional clause → flat-file-only

**Lock-step tests (real fixes to the NEW correct behavior — no weakened checks):**
- `scripts/tests/test-init-project.sh` — `tracker.toml.example` present → ABSENT assertion
- `scripts/tests/test-migrate-v10-to-v11.sh` — `tracker.toml.example` installed → ABSENT assertion
- `scripts/tests/pack-help-test.sh` — client tracker heading pin `(v11+)` → `(deferred)`
- `scripts/tests/test-validate-pack-check-51-flip-block.sh` — extended to legs 1-5 (T7/T8 added)
- `scripts/persona-contracts/contract-greenfield.sh` — drop `tracker.toml.example` from S11
  list + add explicit ABSENCE assertion
- `scripts/persona-contracts/contract-migration.sh` — drop `tracker.toml.example` from v11
  artifacts + add explicit ABSENCE assertion

**Fixtures:**
- `test-fixtures/manifest.txt` — regenerated (v11-surface commit rule)

## 6. Full wired-test results (FULL CI suite, no sampling)

Run-command list extracted from `.github/workflows/validate-pack.yml` (validate job + tests
job, both). Every step executed; all EXIT=0.

**validate job:**
```
python3 scripts/validate-pack.py                       → EXIT 0 ("PASSED — all checks clean")
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py  → EXIT 0 ("PASSED — all checks clean")
```
Within validate-pack (general): Check 39 OK (34 cmd_update entries reverse-checked, 0 drift),
Check 41 OK (36 `_CLIENT_INSTALLED_FILES` entries, 0 drift, set-equality consistent), Check 46
OK (11 boundary surfaces, 7 spawn rules), Check 51 OK (legs 1-5).

**tests job (each `bash <script>` ⇒ EXIT 0 / "PASS"):**
```
scripts/test-detect.sh ............................... PASS
scripts/tests/tracker-provider-test.sh ............... PASS
scripts/tests/tracker-config-test.sh ................. PASS
scripts/tests/tracker-init-test.sh ................... PASS
scripts/tests/tracker-agent-read-test.sh ............. PASS
scripts/tests/tracker-migrate-forward-test.sh ........ PASS
scripts/tests/tracker-migrate-reverse-test.sh ........ PASS
scripts/tests/tracker-migrate-roundtrip-test.sh ...... PASS
scripts/tests/test-tracker-phase-task.sh ............. PASS
scripts/tests/test-tracker-links.sh .................. PASS
scripts/tests/test-tracker-cycle-check.sh ............ PASS
scripts/tests/tracker-errors-test.sh ................. PASS
scripts/tests/tracker-config-schema-test.sh .......... PASS
scripts/tests/recommendation-state-schema-test.sh .... PASS
scripts/tests/test-per-entry.sh ...................... PASS
scripts/tests/test-validate-pack-checks-32-33-34.sh .. PASS
scripts/tests/test-validate-pack-checks-36-37-38.sh .. PASS
scripts/tests/test-validate-pack-check-39.sh ......... PASS
scripts/tests/test-validate-pack-check-40.sh ......... PASS
scripts/tests/test-validate-pack-check-41.sh ......... PASS
scripts/tests/test-validate-pack-check-18.sh ......... PASS
scripts/tests/test-validate-pack-check-16.sh ......... PASS
scripts/tests/test-validate-pack-check-19.sh ......... PASS
scripts/tests/test-validate-pack-check-42.sh ......... PASS
scripts/tests/test-validate-pack-check-43.sh ......... PASS
scripts/tests/test-validate-pack-check-44.sh ......... PASS
scripts/tests/test-validate-pack-check-45.sh ......... PASS
scripts/tests/test-validate-pack-check-46.sh ......... PASS
scripts/tests/test-validate-pack-check-removed-doc-advisory.sh . PASS
scripts/tests/test-validate-pack-check-49-field-faithfulness.sh . PASS
scripts/tests/test-validate-pack-check-50-codec-single-source.sh . PASS
scripts/tests/test-validate-pack-check-51-flip-block.sh . PASS (3 groups; legs 1-5; T1-T8)
scripts/tests/tracker-deferral-gate-test.sh .......... PASS
scripts/tests/tracker-bd129-gh-repo-test.sh .......... PASS
scripts/tests/tracker-bd130-doctor-wired-test.sh ..... PASS
scripts/tests/tracker-bd132-race-test.sh ............. PASS
scripts/tests/tracker-bd133-header-preservation-test.sh . PASS
scripts/tests/tracker-bd134-close-retry-test.sh ...... PASS
scripts/tests/recommendation-test.sh ................. PASS
scripts/tests/pack-help-test.sh ...................... PASS (after 2.2 heading pin fix)
scripts/tests/test-customization-preserve.sh ......... PASS
scripts/tests/test-init-project.sh ................... PASS (after absence-assertion fix)
scripts/tests/test-migrate-v10-to-v11.sh ............. PASS (after absence-assertion fix)
scripts/tests/test-migrate-v10-to-v11-dry-run.sh ..... PASS
scripts/tests/test-migrate-v10-to-v11-gates.sh ....... PASS
scripts/tests/test-migrate-v10-to-v11-decompose.sh ... PASS
scripts/test-migrator-core.sh ........................ PASS (19/0)
scripts/test-migrator-manifest.sh .................... PASS (12/0)
scripts/test-migrator-capability-translation.sh ...... PASS
bash test-fixtures/build.sh --all --clean ............ EXIT 0
bash test-fixtures/build.sh --verify ................. EXIT 0 (all fixtures OK)
scripts/tests/test-v11-realistic-ot.sh ............... PASS
scripts/test-migrator-skills.sh ...................... PASS
scripts/test-persona-contracts.sh .................... PASS (3/3 personas; after absence fixes)
scripts/tests/template-translations-test.sh .......... PASS
scripts/tests/template-version-test.sh ............... PASS
scripts/tests/test-issue-forms.sh .................... PASS
```
No sampling — the COMPLETE wired list was run. (The C1 hotfix lesson: a per-commit local CI
run that skipped a wired test went red on push; this run executes every wired step.)

## 7. Manifest diff (expected non-empty — rides this commit)

`bash test-fixtures/build.sh --all --clean` then verify: 3 v11 fixture hashes changed (the
project-template content changed), `test-fixtures/manifest.txt`:
```
-v11-realistic-ot  ae3fc6ff4956e365cba79699c724dce94559509c
-v11-flat-file  f9705c2740f8788a486b1a90bcf9448b57c04391
-v11-tracker-on  944ddee3108ce3634327b8b6ee105cb0cd825e5a
+v11-realistic-ot  1eed648f11a45cb5a0eb5b406e24bae641305254
+v11-flat-file  2b2e62535ea2b731df031335492814c7589907da
+v11-tracker-on  e9a64fb48719176062f82c0054cdbef38c4341b8
```
`build.sh --verify` EXIT 0 against the regenerated manifest. (v10 fixtures + manifest header
unchanged.)

## 8. Out-of-scope items surfaced (not touched)

1. **`backlog/BD-214.md` (` M` in `git status`)** — PRE-EXISTING working-tree dated note present
   at the C3 base HEAD `c994d82` (the session opened with ` M backlog/BD-214.md`). NOT a C3 edit;
   left untouched. It belongs to Pack-Chat bookkeeping / a later commit (C5b dated notes), not C3.
2. **C2-landed pack-side surfaces** (root trinity, pack-ops fragments, `changelog/v11.md`,
   pack-startup ×3) — already swept at C2; NOT re-touched. (The architecture §6.6 names "the C3
   coder" for `changelog/v11.md`; under the PLAN's renumber that is the pack-side sweep = C2, and
   `changelog/v11.md` already carries the deferral reword — confirmed not in my C3 §7 file set.)
3. **Check 43 allowlist `tracker.toml.example` / `tracker.toml` entries** — NOT touched (plan C3
   names only Checks 39/41/46). The basename is still a legitimate prose-reference target (existing
   clients retain an inert copy; pack-vs-project disambiguation examples in deny-list fixtures rely
   on it). No test failed for this; left as-is.
4. **Gate-3 post-Phase-B prose in MIGRATION** (lines ~415/428-430, `tracker.toml present ...
   mode.state = "tracker"`) — describes DORMANT gate auto-SKIP behavior accurately ("In flat-file
   mode the gate prints `[INFO] tracker: skipped`"); not advertisement. Left (matches design Axis-B
   "dormant code KEEPS").
5. **Persona-contract scripts + `test-migrate-v10-to-v11.sh`** were NOT in the plan's literal C3
   lock-step list (which named test-init-project / gates / translations) but DO encode the C3-changed
   install behavior. Updated them under `enumerate-encoding-surfaces` (a coder MUST update every
   surface that encodes the changed expected state). Flagged here for transparency; these are
   in-scope-by-consequence, not new scope. No band-aids — each got a real ABSENCE assertion.

## 9. Plan deviations

- **Leg-3 scan is bounded to skill dirs, not a whole-tree grep.** The architecture §6.3 describes
  leg 3 as a grep over an allowlist `{scripts/lib/recommendation.sh, scripts/tests/,
  maintenance-docs/}`. Implementing that literally as a whole-tree scan-with-exclusions would read
  every text file on EVERY validate-pack run (~151× battery) — a `feedback-ci-check-runtime-compounding`
  hazard. Per measure-then-bound + runtime-compounding, I bounded leg 3 to the 7 skill/command
  directories that are the ONLY surfaces wiring D-19 (design EE-7 enumerates exactly these). Same
  guard property (catches reintroduction of a live invoker), bounded cost. NOT a scope change — the
  legitimate carriers are simply outside the bounded surface, so the result is identical (0 hits).
  Recorded as a deliberate implementation choice consistent with both pack-memory rules.
- No other deviations. Every C3 §7 file in the plan's table was edited; verification battery is the
  plan's plus the full wired suite.

## 10. New POQs introduced

None.

## 11. Definition-of-Done checklist

| Item | Status |
|---|---|
| pm-startup Step 8 ×4 → deferred note (step number kept) | PASS |
| Check-51 leg 3 added + condition TRUE (skill grep-zero == 0) | PASS |
| Check-51 leg 5 added + condition TRUE (install-map token absent) | PASS |
| Check-51 dedicated test extended to legs 1-5 (T7/T8) + green | PASS |
| Install-map removal atomic with Checks 39/41/46 (set-equality green) | PASS |
| migrate-v10-to-v11.sh example-copy removed + post-report deferral wording | PASS |
| Project trinity ×3 swept, parity + cross-CLI normalized, same commit | PASS |
| PM-CHAT / OPTIONAL-FEATURES / HELP-FRAGMENT(-TRACKER) / prompts ×5 / _intro ×3 swept | PASS |
| DEPENDENCIES / MIGRATION (Phase B DEFERRED) / METHODOLOGY swept | PASS |
| Lock-step tests updated (no weakened checks) | PASS |
| No scope-keyword token anywhere (mixed-scope, Check 36 skipped) | PASS |
| Manifest regenerated (non-empty diff) + verify green | PASS |
| FULL CI wired-test job verified locally, all EXIT=0 (no sampling) | PASS |
| validate-pack general + PACK_VALIDATE_DEEP=1 green | PASS |
| No git state change (agents never commit) | PASS |
| `_SANCTIONED_PACK_SIDE_SHIPPED` unchanged (shrink, not new ship) | PASS |
| Boundary discipline (no pack-only refs imported into client content) | PASS |

## 12. Boundary discipline check (P-missed-7) — project-side edits

For each client-shipped surface edited, the project-side SSOT/convention was used; NO pack-only
mechanism (`pack-ops/` refs, pack-* agent names, `maintenance-docs/` refs, Pack-Chat orchestrator
role) was imported into client content:
- **project trinity / pm-startup / prompts / _intro** — used the project trinity `## Document
  locations` vocabulary + the BD-214 deferral framing (a BD-NNN reference is the project's own
  backlog-id convention, not a pack-self ref). No new pack-only target added.
- **PM-CHAT.md** — the pre-existing `pack-ops/MERGE-STRATEGY.md` "in the pack repo" reference (inside
  a DENY-LIST-CONTENT pack-vs-project disambiguation block) was REMOVED as part of collapsing the
  recommendation-routing section to a deferral note — no NEW pack-only ref introduced; the dormant
  `scripts/lib/tracker-promote.sh` / `tracker_links_create_blocked_by` references are client-side
  code pointers (the libs ship/exist client-side), not pack-ops.
- **OPTIONAL-FEATURES / HELP-FRAGMENT-TRACKER** — the "tracker.toml.pack-example in the pack repo,
  or tracker.toml.example at a client project root" phrasing is a SANCTIONED pack-vs-project
  disambiguation example (matches the Check-43 deny-list anchor phrases), retained, not a new
  pack-only dependency.
- **DEPENDENCIES / MIGRATION / METHODOLOGY** — deferral framing only; no pack-only target added.
- No SSOT augmentation was needed beyond the BD-214 deferral framing the plan supplies (no project-side
  SSOT exists for "tracker is deferred" — implementing per the plan's prompt). No Boundary-discipline
  STOP condition was hit (no edit needed to add a reference to a pack-only file).

## 13. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status`, `git status --short`, `git diff --stat`, `git diff <path>`, `git branch --show-current`, `git log --oneline`. Zero `add/commit/push/tag/reset/stash/checkout/rm`. Final HEAD unchanged at `c994d82`. | COMPLIANT |
| 2. Real fixes only — no band-aids | Test edits change assertions to the NEW correct behavior, never weaken a check: `tracker.toml.example present` → `! -f ... NOT installed` (init-project, migrate, persona ×2 — each with an explicit positive ABSENCE assertion); pack-help 2.2 heading pin `(v11+)`→`(deferred)` matches the new stub; Check-51 test GROWN (T7/T8 added) not relaxed. No check disabled. | COMPLIANT |
| 3. Trinity parity + cross-CLI normalization | `diff` of the changed CLAUDE.md `## Document locations`/per-entry sections vs AGENTS.md vs GEMINI.md = identical; sections are CLI-neutral (pm-startup skill name only) ⇒ audience-correct canonical value is the same string; validate-pack trinity-parity check (full run) EXIT 0. All three edited in the same working-tree/commit. | COMPLIANT |
| 4. Enumerate-encoding-surfaces (atomic install-map) | install-map array + self-doc block + S11 copy + header ALL edited together; Check 41 set-equality "36 entries, 0 drift" GREEN; Check 39 "34 cmd_update, 0 drift" GREEN; Check 46 GREEN; Check-51 leg 5 (anti-reintroduction) GREEN; test-init-project + migrate test + persona contracts ×2 updated in the same state. | COMPLIANT |
| 5. Verify the FULL CI suite — no sampling | Extracted the complete run list from validate-pack.yml (both jobs) and ran EACH (§6) — all EXIT 0, incl. test-init-project, gates, template-translations, Check-51 (legs 1-5), realistic-ot, persona-contracts, fixture build+verify, plus validate-pack general + `PACK_VALIDATE_DEEP=1`. | COMPLIANT |
| 6. Regenerate manifest on v11-surface commits | `project-template/` + `scripts/` + `supporting-docs/` touched ⇒ `bash test-fixtures/build.sh --all --clean` run; manifest diff NON-EMPTY (3 v11 fixture hashes, §7); `--verify` EXIT 0. | COMPLIANT |
| 7. Edit in place, not full rewrite | All edits are anchored single-occurrence Edit replacements; the only full-file Write is the project HELP-FRAGMENT-TRACKER.md deferred STUB (a deliberate stub rewrite mirroring the C2 pack-side stub, with the project verb set retained — Read-before-Write performed). No section silently dropped (each file re-grepped after editing). | COMPLIANT |
| 8. Rules-Applied Verification Block | This table — per rule, quoted evidence, conclusion; no empty cells. | COMPLIANT |
| 9. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 32/32 in-scope edits complete; Check 51 now legs 1-5 green; FULL CI wired-test job verified locally; HEAD c994d82...; about to Write IMPL-REPORT to <path>` immediately before this Write. No stop/halt/revert message received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session: CLAUDE.md (full, incl. all
`## Pack memory`, via system context); PLAN-BD-214-TRACKER-DEFERRAL.md (full, 499 lines — Revision
log, renumber map, §2 green-per-commit, §7 C3 section + atomic set, §11 GAP-NEW, §12/§12a);
ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both pages, 853 lines — §3 Layer C, §4 Axis E/F,
§5, §6.1/§6.3 legs 3/5, §6.6, §10 commit table); init-project.sh (header + S11 + install map +
self-doc), validate-pack.py (Check 51 + Checks 39/41/46 + `_CLIENT_INSTALLED_FILES` +
`_iter_client_installed_files` + `_SANCTIONED_PACK_SIDE_SHIPPED` + Check-43 allowlist),
migrate-v10-to-v11.sh; every project-side file edited (trinity ×3, pm-startup ×4, PM-CHAT,
OPTIONAL-FEATURES, HELP-FRAGMENT(-TRACKER), prompts ×5, `_intro` ×3, DEPENDENCIES, MIGRATION,
METHODOLOGY) and the lock-step tests (test-init-project, migrate, gates, translations, pack-help,
persona-contracts ×2, Check-51 test) + `.github/workflows/validate-pack.yml`. No named document
was derived rather than read.

**End of IMPL-REPORT-BD-214-C3.md**
