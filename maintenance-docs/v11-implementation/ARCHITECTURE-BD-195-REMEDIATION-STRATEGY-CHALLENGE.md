# ARCHITECTURE-BD-195-REMEDIATION-STRATEGY-CHALLENGE

**Status:** Adversarial review (fresh pack-architect). READ-ONLY; no source
edits, no git state changes. Goal: REFUTE the Step-7 remediation strategy.
**Branch:** `v11-dev`. **HEAD:** `3178fa4` (`3178fa4f666326ac3eac26238b6e96ad25b60f71`).
**Target:** `ARCHITECTURE-BD-195-REMEDIATION-STRATEGY.md`.
**Trusted basis re-grounded against the repo:** `BD-195-CLEAN-FOUNDATION.md`
(K1–K7, principles, JC-1..JC-7 — binding); `AUDIT-BD-195-VERIFIED-FINDINGS.md`
(67 confirmed, 1 FP). Every load-bearing claim was re-read at `file:line` at
HEAD `3178fa4` (distrust-derived-claims); I did NOT trust the strategy's or
findings doc's summaries alone.

## Verdict summary

- **CONFIRMED:** 9 attacked elements (per-finding mapping spine; dual-consumer
  shared-validator empirics; Reading-A feasibility; the new `.mcp.json.example`
  leak; the JC-1 STRIP/KEEP categorization; B.15/B.16/B.17 line-grounding;
  the C4 `project-only` keyword; the C3 xcode split; CI-green-despite-leaks).
- **REFUTED:** 3 elements (the §2.2 KEEP allowlist line-citations 13/38/44 are
  fabricated; the NUD-1 framing omits the real decision and is mildly biased;
  the C7 manifest-regen verdict mis-states the categorical rule).
- **NEEDS-USER:** the substance of NUD-1 (whether K1.11–K1.14 are contamination
  at all) — independent of the framing flaw.

**Overall:** the strategy is structurally sound and its empirical spine holds,
BUT it requires a **bounded revision before going to the user** — specifically
the §2.2 measure-step allowlist (fabricated line citations) and the NUD-1
framing (false-dichotomy). These are correctness defects in the two places the
foundation cares about most: a measure-then-bound allowlist sized against
non-existent occurrences, and a NUD framed to steer the answer.

---

## ATTACK 1 — Per-finding fix mapping (67)

### 1a — Is any CLEAR-FIX actually ambiguous? — CONFIRMED (mapping sound) with one caveat

I spot-checked the load-bearing CLEAR-FIX classifications against the repo:

- **K3.1/K3.2 (V3.2-DELTA dangling):** CONFIRMED clear. `ARCHITECTURE-V3.2-DELTA.md`
  ABSENT, `ARCHITECTURE-V3.3-DELTA.md` EXISTS (EEB-3). Drop-the-dead-cite is
  unambiguous.
- **B.3 (`.v9-customized`→`.v10-customized`):** CONFIRMED. `migrate-v10-to-v11.sh:76`
  sets `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`. Clear factual fix.
- **B.14 (IMPL-REPORT vs IMPLEMENTATION-REPORT prefix):** CONFIRMED clear.
- **K4.4 (PM-CHAT.md:530 dead `docs/pack/MERGE-STRATEGY.md`):** the disposition
  text offers TWO sub-options ("point at the project-side SSOT for the behavior,
  OR drop the primary cite and keep the fenced pack-repo fallback"). That is a
  genuine choice, yet it is filed CLEAR-FIX, not NUD. **Borderline.** It does
  not rise to a user decision (both are mechanical and the fenced fallback
  already exists), so CLEAR-FIX is defensible — but the strategy should name
  ONE recipe, not leave the coder to choose. **CONFIRMED with a note:** pin the
  recipe before the coder spawns.

### 1b — Is any NUD over-escalated? — REFUTED on K1.11–K1.14 framing; see ATTACK 2

The 6 per-entry-path findings (B.5–B.10 = NUD-8) and the 5/2 README-layout
findings (NUD-4) are correctly NUD: each has two genuinely-defensible recipes
(annotate-pack-side vs drop-the-path; strip-row vs strip+annotate) and the
choice is editorial/PM. CONFIRMED not over-escalated.

K1.11–K1.14 (NUD-1) is the one place the escalate-vs-decide call is itself
contestable — see ATTACK 2. The escalation is defensible; the **framing** is
not.

### 1c — Is any ruling-backed fix inconsistent with the ruling? — CONFIRMED consistent

- **K3.12/K3.13 → JC-5 (no hand-correction; soft-advisory only):** matches JC-5
  verbatim ("leave accurate historical narrative ... the only output is a
  SOFT-advisory guard ... never hard-fail"). CONFIRMED.
- **K4.1/K5.1/B.1 → JC-3:** JC-3 says strip the `V10-DESIGN.md` ref, de-version
  v10→v11, redirect `cp -r` to init-project.sh/QUICKSTART. The mappings match
  one-to-one. CONFIRMED.
- **K5.3/K5.4 → JC-6 (version-neutral the pm-startup RAG-manifest label across
  the triad):** matches. CONFIRMED.
- **B.2 → JC-4 (malformed-path category-B, NOT a K4 leak):** matches JC-4
  verbatim. CONFIRMED.

**ATTACK 1 result: CONFIRMED** the per-finding mapping is internally consistent
with the rulings and the kinds, with one tightening note (K4.4 recipe should be
pinned).

---

## ATTACK 2 — The NUD framings (esp. NUD-1)

### 2a — Empirical shared-caller claim — CONFIRMED

The strategy's load-bearing claim is that `tracker_links_validate_id_shapes`
(via `_tlk_is_valid_pack_id`) is shared between the JC-1 phase-task path and the
own-backlog entry-Blockers path JC-1 preserves. I verified the call graph
directly at HEAD `3178fa4`:

- `tracker_links_create_blocked_by()` (tracker-links.sh:204) calls
  `tracker_links_validate_id_shapes "$src" "$tgt" || return 1` as its Step 1.
- `tracker-promote.sh:1157` calls `tracker_links_create_blocked_by` (phase-task
  path, behind the `:1155` dispatch regex that admits `BD-`).
- `tracker-migrate-forward.sh:998` calls `tracker_links_create_blocked_by` from
  the `BD-*|TD-*)` entry-Blockers arm (the path JC-1 explicitly leaves
  untouched).

So `validate_id_shapes`/`_tlk_is_valid_pack_id` IS dual-consumer. The
shared-caller claim is **SUPPORTED / CONFIRMED.**

### 2b — Is "Reading A" genuinely the only reading consistent with both halves of JC-1? — CONFIRMED feasible, but the framing is REFUTED

Reading A (strip `BD-` ONLY from the `:1155` dispatch regex; leave
`validate_id_shapes` intact) IS feasible and does not break the own-backlog
path: I verified `test-tracker-promote-path2.sh` case 4.3 exercises dep edges
with **TD-029 + phase-3.1** (not `BD-`), so stripping `BD-` from `:1155` leaves
the existing path2 dep-edge assertions green. Reading B (strip from the shared
validator) would break `migrate-forward.sh:998`'s `BD↔` links — JC-1 forbids
that. So between A and B, A is correct.

**The flaw is that A-vs-B is a false dichotomy that conceals the actual
decision.** The real question NUD-1 must put to the user is not "narrow vs
break-own-backlog" (B is a strawman no one would pick — it self-evidently
violates JC-1's own-backlog clause). The real question is:

> **Under Reading A, are K1.11–K1.14 contamination AT ALL, or did the findings
> doc mis-classify them as K1?**

Because the JC-1 error-guard belongs at the **phase-task parse boundary**
(`tracker-phase-task.sh` `DEP_ENTRY`), and K1.11–K1.14 test the **shared LINK
validator** (a different layer that legitimately accepts `TD-029 ←→ BD-108` per
V3.3 §5.1 cross-namespace links), under Reading A those four tests are testing a
**legitimate own-backlog feature** — not contamination. That means the honest
disposition is most likely "K1.11–K1.14 are NOT K1 findings; leave them green,"
which makes them a mis-classification in the findings doc rather than a
user-editorial NUD.

The strategy's own §1 note ("Why K1.11–K1.14 are NUD, not RULING-BACKED")
actually argues this correctly — it says they test the shared validator and the
LINK grammar, not the phase-task `DEP_ENTRY` grammar. But then §4 NUD-1 collapses
the decision into A-vs-B and **recommends A** while burying the "are these even
contamination?" question. A user reading NUD-1 as written will rubber-stamp
"Reading A" without being told that the substantive consequence is "we now treat
4 audit findings as false-positive-under-Reading-A." That is a smuggled answer.

**REFUTED (framing):** NUD-1 must be re-framed to surface the real decision —
*"Reading A is the only JC-1-consistent strip locus (confirmed); the consequent
question is whether K1.11–K1.14 are reclassified NOT-A-DEFECT (recommended) or
retained as contamination requiring a separate strip the foundation does not
authorize."* The A-vs-B presentation is a false dichotomy per the foundation's
"no false dichotomy" principle.

### 2c — The other 8 NUDs — CONFIRMED fair

NUD-2 (bootstrap rewrite), NUD-3 (live BD-195 entry de-citation), NUD-4 (README
layout), NUD-5 (PACK-FEEDBACK v9 label-only vs blanket), NUD-6 (METHODOLOGY
doc-version policy), NUD-7 (check-count recompute), NUD-8 (per-entry path
annotate-vs-drop), NUD-9 (skill count vs PLATFORM-SKILLS SSOT) each present two
genuinely-defensible options with repo-grounded considerations and a
non-coercive recommendation. NUD-5 and NUD-9 explicitly recommend the
*conservative* option (label-only; confirm-SSOT-first), which is the opposite of
steering. **CONFIRMED fair.**

**ATTACK 2 result: shared-caller CONFIRMED; Reading-A feasibility CONFIRMED;
NUD-1 framing REFUTED (false dichotomy that buries the real K1.11–K1.14
reclassification decision).**

---

## ATTACK 3 — Guard designs (measure-then-bound, 3 guards)

### 3.1 — JC-1 phase-task strip + error-guard — CONFIRMED (measured, not asserted)

- **Measure:** the §2.1 STRIP/KEEP table is repro-backed. I re-ran the call-graph
  and confirmed every STRIP row (the `BD-` occurrences in tracker-phase-task.sh
  grammar + docstrings, promote.sh:1151/1155 dispatch, the phase-task tests, the
  fixture `- BD-108` bullet) and every KEEP row (shared `validate_id_shapes`,
  `migrate-forward.sh:990` entry-Blockers, the link/cycle tests).
- **Categorize:** correct. The STRIP set is exactly the phase-task `DEP_ENTRY`
  layer; KEEP is the link/Blockers layer. No STRIP/KEEP swap.
- **Allowlist sized to KEEP:** the "accepted target vocabulary
  `{phase-N, phase-N.M, TD-NNN}`" is sized to the phase-task grammar's KEEP set;
  the own-backlog `BD-` lives entirely in the untouched link layer. Correct.
- **False-positive risk:** the NEW error-guard "if the raw bullet nonetheless
  carries a `BD-[0-9]+` token, emit a typed validation error." Risk: a phase-task
  Dependencies bullet whose *annotation text* legitimately contains `BD-NNN`
  (e.g. `- TD-031  see BD-108 for context`) would FALSE-POSITIVE if the guard
  greps the raw bullet rather than the captured target token. The strategy says
  "if the raw bullet ... carries a `BD-` *target* token" — but the recipe's
  implementation detail (match against raw bullet vs against capture-group-1) is
  left to the coder. **This is a real KEEP/STRIP edge the design under-specifies.**
  CONFIRMED-with-note: the error-guard must bind to the dependency-TARGET position
  only (group-1), never the free-text annotation, or it will reject legitimate
  bullets. (JC-1 says fail on "`BD-` as a project phase-task dependency *target*"
  — the design should quote that scoping into the recipe.)
- **JC-1 error-guard correctly fails on project `BD-` dep target WITHOUT breaking
  own-backlog `BD-`:** CONFIRMED — the guard lives in `tracker-phase-task.sh`
  parse, the own-backlog `BD-` lives in `tracker-links.sh`/`migrate-forward.sh`;
  disjoint surfaces.

**Result: CONFIRMED measured; one under-specification (target-position binding)
to pin in the plan.**

### 3.2 — JC-2 client-surface leak-guard broadening — REFUTED (allowlist sized against fabricated occurrences)

- **Measure (extensions/new-leak):** CONFIRMED. `.example`/`.proto` are NOT in
  `_CHECK_40_FILE_EXTS = "md|sh|py|toml|yml|yaml|json|txt"` (validate-pack.py:4880),
  so the 5 files (`.codex/config.toml.example`, `.gemini/.env.example`,
  `.mcp.json.example`, `proto/common/v1/common.proto`,
  `proto/example/v1/example_service.proto`) are currently unwalked. The new leak
  is real (ATTACK 4).
- **KEEP allowlist sizing — REFUTED.** §2.2 Step 1 (measure table) and Step 4
  (allowlist) cite **"README:13/38/44 pre-install copy instructions"** as the
  KEEP set whose `supporting-docs/...` references must stay exempt. I read
  README lines 13, 38, 44 verbatim at HEAD `3178fa4`:
  - line 13 = blank
  - line 38 = `### Contributing to the Config Pack`
  - line 44 = `Each CLI ships its own optional or experimental features ...`

  **None of lines 13/38/44 contains a `supporting-docs/` reference.** The actual
  `supporting-docs/` occurrences in README are at lines **121** (layout-map note
  `directory guidance: see supporting-docs/METHODOLOGY.md`), **143** (the
  `supporting-docs/` layout heading), and **287** (the convention prose `They
  always live in supporting-docs/`). So the strategy's KEEP allowlist is sized
  against **occurrences that do not exist at the cited lines.** This is precisely
  the measure-then-bound failure mode the foundation warns against: an allowlist
  declared without re-measuring the tree, admitting phantom lines. The KEEP
  entries the guard actually needs are README:121/287 (and the layout heading
  143) — and critically, **README is a pack-side surface that Check 43 does NOT
  walk** (Check 43 iterates `_iter_client_installed_files()`, not README), so
  those README lines are NOT in the guard's blast radius at all. The entire
  "README:13/38/44 KEEP" entry is both mis-cited AND scope-irrelevant.

  **Correction:** drop the README:13/38/44 KEEP entry entirely. README is not a
  Check-43-walked surface; its `supporting-docs/` refs (121/287/143) are
  PM-only-layout/convention prose handled under NUD-4/B.15/B.16, not by the JC-2
  guard. The genuine JC-2 allowlist is: proto self-imports (`common/v1/common.proto`,
  `example/v1/example_service.proto`) only.

- **`supporting-docs/` prefix-tightening interaction — REFUTED-as-incomplete.**
  §2.2 proposes tightening Check 43 so a `supporting-docs/<X>` cite FAILs
  regardless of installed-basename. But validate-pack.py:4236–4237 already FENCES
  `supporting-docs/METHODOLOGY.md` and `supporting-docs/INSTALL-PROCEDURES.md`
  (these two files are on the per-line-fence allowlist because they carry
  legitimate pack-internal references). The proposed tightening must be reconciled
  with that fence: the tightening targets *client-installed surfaces citing the
  `supporting-docs/` prefix*, NOT the fenced supporting-docs source files
  themselves. The design does not address this interaction. CONFIRMED-incomplete:
  the planner must verify the tightened rule does not double-flag the fenced
  files (it likely won't, since the fence files are not "client surfaces citing
  the prefix" — but the design must SAY so per measure-then-bound Step 5).

- **False-negative check:** with the broadened walk, does any STRIP slip through?
  The `.mcp.json.example` leak (ATTACK 4) is caught by the ext-add. K4.2's SHA +
  research-doc is caught by ext-add + the new SHA/bare-prose class-tests. No
  obvious STRIP escapes. CONFIRMED no false-negative in the named set.

**Result: REFUTED — the KEEP allowlist is sized against fabricated README
line-citations (13/38/44 carry no `supporting-docs/` ref; README isn't even
Check-43-walked), and the fence-interaction is unaddressed. This is the most
serious defect: a measure-then-bound guard whose allowlist failed the
measure-first contract.**

### 3.3 — JC-5 soft-advisory removed-doc guard — CONFIRMED

- Measure: K3.12 (CHANGELOG 451/481-482/562/564) + K3.13 (BACKLOG narrative
  lines) cite removed docs within accurate history. CONFIRMED those docs ABSENT
  (EEB-3).
- Categorize: ALL KEEP-as-history, zero STRIP — matches JC-5 verbatim.
- Allowlist: "every hit is a WARN, never a `fail()`" — correct; JC-5 says "never
  hard-fail." The guard must be wired non-fatal (exit 0 with WARNs). CONFIRMED.
- Risk: a soft-advisory that scans backtick-cited basenames against a
  removed-doc set could WARN on legitimate forward references; but since it is
  non-fatal by construction, a false-WARN is cosmetic, not a gate break.
  Acceptable. CONFIRMED.

**Result: CONFIRMED.**

---

## ATTACK 4 — The new leak (`.mcp.json.example:9` → `supporting-docs/CLI-PM-SETUP.md`)

CONFIRMED real and correctly placed in C3.

- `.mcp.json.example:9` verbatim: `"_readme": "Set BASE_DIR ... See
  supporting-docs/CLI-PM-SETUP.md for setup instructions."`
- `supporting-docs/CLI-PM-SETUP.md` EXISTS at pack root BUT is NOT in
  `_CLIENT_INSTALLED_FILES` — `init-project.sh` installs only
  `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md` → `docs/pack/INSTALL-PROCEDURES.md`
  (init-project.sh:1186-1187). CLI-PM-SETUP.md is never delivered.
- `.mcp.json.example` lives under `project-template/` (client-gated by location)
  and is copied to `.mcp.json` at the client; the `supporting-docs/` directory
  does not exist at a client. So the cite is a dead client path = a genuine K2/K4
  leak NOT among the 67 (the audit's `.example` files were unwalked — EEB-5).
- It is correctly folded into **C3** (the client-surface leak commit) and
  surfaced as the blast-radius of the JC-2 measure step per
  no-deferral-without-user-direction. CONFIRMED placement.

One note: the README layout (line 145) lists `CLI-PM-SETUP.md` under
supporting-docs/ as "CLI PM chat daily usage reference" — that README row is
pack-side and accurate (the file does live there). The leak is solely the
`.example` cite directing a *client* to it. The strategy scopes this correctly.

**ATTACK 4 result: CONFIRMED.**

---

## ATTACK 5 — Commit sequence (9)

### 5a — Dependency cycles — CONFIRMED none

C1 → C1b (same grammar cluster, C1b NUD-gated); C2 before C3/C4 (broadened
guard must exist to verify client-surface STRIPs land clean); C6 independent;
C7/C8/C9 NUD-gated. The DAG is acyclic. CONFIRMED.

One ordering concern: C2 (guard broadening) before C3 (client-surface fixes)
means CI would FAIL between C2 and C3 (the broadened guard fires on the
unfixed STRIP set). The strategy implicitly accepts C2+C3 as a tight pair but
does not state the inter-commit red-CI window. Per the pack's "CI must pass on
every push" rule, **C2 and C3 should land as a single commit, or C3 must
immediately follow C2 with no other push between.** The strategy's table treats
them as separate gated commits without flagging that C2-alone leaves CI red.
CONFIRMED-with-note: collapse C2+C3 (and C2+C4) or sequence them as an
atomic pair.

### 5b — Scope keywords (CI Check 36) — REFUTED-in-part / CONFIRMED-in-part

- **C1 `pack-only`:** all paths under `scripts/` — outside project-template/ +
  supporting-docs/. Correct.
- **C2 `pack-only`:** `scripts/validate-pack.py` + test. Correct.
- **C3 `project-only` EXCEPT xcode → split C3a/C3b:** CONFIRMED. `project-only`
  denies everything OUTSIDE project-template/+supporting-docs/.
  `xcode-companion-templates/` is OUTSIDE both, so an xcode file in a
  `project-only` commit FAILs Check 36. The split (C3a `project-only`, C3b
  no-keyword) is correct. CONFIRMED.
- **C4 `project-only`:** `supporting-docs/` IS a project-side prefix per
  `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`
  (validate-pack.py:3823). So `project-only` permits supporting-docs/. CONFIRMED.
- **C5 `no-keyword` (mixed scripts/ + maintenance-docs/):** correct — mixed scope
  must carry no exclusive keyword. CONFIRMED. (The alternative split is also
  valid.)
- **C7 `PM-only` (pack-ops/BACKLOG.md):** BACKLOG.md is on the PM-only list.
  Correct.
- **C8 `PM-only` (README.md):** README version table + layout are PM-only.
  Correct.
- **C9 `project-only` (project-template/ files):** correct.

The keyword assignments are sound. CONFIRMED (the only REFUTE-able item here is
the C2/C3 red-CI window in 5a, not the keywords).

### 5c — Manifest-regen verdicts — REFUTED (C7) / CONFIRMED (others)

The rule (CLAUDE.md `regenerate-manifest-v11-surface`) is categorical: any
commit whose diff includes a file under `project-template/`, `scripts/`,
`pack-ops/`, or `supporting-docs/` MUST run `build.sh --all --clean` and stage
`manifest.txt` IF the diff is non-empty.

- **C1/C2/C6 (scripts/): "YES"** — correct (scripts/ is a v11 surface).
- **C3/C9 (project-template/): "YES"** — correct.
- **C4 (supporting-docs/): "YES"** — correct.
- **C7 (pack-ops/BACKLOG.md): strategy says "NO (mirror-only edit; manifest
  unaffected ...)".** REFUTED as a mis-statement of the rule. `pack-ops/` IS one
  of the four named surfaces, so C7 MUST **run** the regen; it stages
  manifest.txt only if the diff is non-empty. The manifest captures per-fixture
  init-project.sh SHAs (verified: manifest.txt rows are `<fixture> <sha>`, e.g.
  `v11-flat-file <sha>`), and BACKLOG.md does not feed init-project.sh fixtures,
  so the diff will almost certainly be empty — but the rule still mandates
  RUNNING the regen, not skipping it. The strategy's "NO" reads as "skip the
  regen," which is wrong. **Correction:** C7 = "RUN regen; stage only if
  non-empty (expected empty)."
- **C8 (README.md): "YES if build flags README".** README is at repo root, NOT
  under the four surfaces, so the categorical rule does NOT trigger for a
  README-only commit. The strategy's conditional "YES if build flags README" is
  over-cautious but not wrong (running the regen is harmless). CONFIRMED-acceptable
  (README-only does not mandate regen; running it is harmless).

**ATTACK 5 result: CONFIRMED DAG + keywords; REFUTED the C7 manifest verdict
(mis-states the categorical rule) and flagged the C2/C3 red-CI window.**

---

## ATTACK 6 — Source-trust

CONFIRMED clean. I checked whether the strategy trusts a derived claim or a
deleted source:

- The strategy explicitly re-reads each finding at `file:line` and carries EEBs
  with verbatim output + HEAD SHA. I independently re-ran the load-bearing
  measurements (call graph, file existence, ext set, install set, README lines,
  skill/check counts) and they reproduce — EXCEPT the §2.2 README:13/38/44 KEEP
  citation, which does NOT reproduce (ATTACK 3.2). That single non-reproducing
  claim is the one place the strategy asserted an occurrence without re-measuring
  — ironically a distrust-derived-claims violation inside a measure-then-bound
  step.
- The strategy correctly treats `pack-ops/BACKLOG.md`/`CHANGELOG.md` as the
  current edit target (per-entry trees absent at HEAD — EEB-0 reproduces:
  `ls backlog/` → No such file or directory).
- It does NOT cite any deleted prison doc as authority; its trusted basis is
  CLEAN-FOUNDATION + VERIFIED-FINDINGS (both present, both `??` untracked at
  HEAD).
- The `maintenance-docs/prison/` directory is deleted (git status shows the
  prison files as `D`); the strategy does not look for it.

**ATTACK 6 result: CONFIRMED clean, with the one caught exception (the §2.2
fabricated README citation) cross-listed under ATTACK 3.2.**

---

## Consolidated refutations (what must change before the user sees this)

1. **[MUST] §2.2 KEEP allowlist — fabricated line citations.** Remove the
   "README:13/38/44 pre-install copy instructions" KEEP entry. README is not a
   Check-43-walked surface; its real `supporting-docs/` refs are at 121/287/143
   and are handled under NUD-4/B.15/B.16. The genuine JC-2 KEEP set is the two
   proto self-imports only. (measure-then-bound: the allowlist was sized against
   non-existent occurrences.)

2. **[MUST] NUD-1 framing — false dichotomy.** Re-frame to surface the real
   decision: Reading A is the confirmed strip locus; the consequent user
   question is whether K1.11–K1.14 are reclassified NOT-A-DEFECT (recommended,
   since they test the legitimate shared link layer) or retained as
   contamination. The A-vs-B presentation hides this and steers the answer.

3. **[SHOULD] C7 manifest verdict — mis-states the rule.** Change "NO" to "RUN
   regen; stage only if non-empty." pack-ops/ is a named v11 surface.

4. **[SHOULD] C2/C3 (and C2/C4) red-CI window.** State that the broadened guard
   (C2) leaves CI red until the client-surface STRIPs (C3/C4) land; collapse to
   an atomic pair or sequence with no intervening push.

5. **[SHOULD] JC-1 error-guard target-position binding.** Pin the recipe so the
   guard fires on the dependency-TARGET token (capture-group-1) only, never a
   `BD-NNN` appearing in free-text annotation, to avoid a false-positive.

6. **[NIT] §2.2 fence interaction.** State that the tightened `supporting-docs/`
   prefix rule does not double-flag the fenced supporting-docs source files
   (validate-pack.py:4236-4237).

7. **[NIT] K4.4 recipe.** Pin one of the two sub-options before the coder spawns.

None of these invalidate the strategy's spine (the 67-finding mapping, the JC-1
strip locus, the JC-5 no-correction ruling, the new-leak discovery, the commit
DAG, the keyword assignments). Items 1 and 2 are correctness defects that the
user would be deciding/approving on false premises; they must be fixed first.
Items 3–7 can be folded into the planner pass.

---

## Overall verdict

**NOT-READY as written; READY after a bounded revision.** The strategy is
fundamentally sound — its empirical spine reproduces, its per-finding mapping is
consistent with the binding rulings, the three guards follow the
measure-then-bound shape, and the new leak is a genuine catch correctly scoped
to v11.0. But TWO defects sit exactly where the foundation is least forgiving:
(1) a measure-then-bound allowlist sized against fabricated README line
citations (§2.2), and (2) a NUD framed as a false dichotomy that buries the real
K1.11–K1.14 reclassification decision (NUD-1). Fix #1 and #2, fold #3–#7 into the
planner pass, and the strategy is sound to bring to the user with the 9 NUDs.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [architect] | Every refutation/confirmation carries a command + verbatim output + HEAD `3178fa4`: call-graph greps (`tracker_links_create_blocked_by` callers → promote.sh:1157 + migrate-forward.sh:998; `validate_id_shapes` called at links.sh:204); `sed -n '13p;38p;44p' README.md` → blank / `### Contributing` / `Each CLI ships...` (no supporting-docs ref); `grep -n 'supporting-docs/' README.md` → 121/143/287; `_CHECK_40_FILE_EXTS = "md|sh|py|toml|yml|yaml|json|txt"`; init-project.sh:1186-1187 install set; `ls -d project-template/skills/*/ \| wc -l` → 36; `grep -oE 'Check 4[0-6]'` → 40-46; `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` | COMPLIANT |
| ci-guard-design-measure-then-bound [architect] | Judged all 3 guards against the 5-step contract: 3.1 measured+categorized correctly (one target-position under-spec); 3.2 REFUTED — allowlist Step-4 sized against README:13/38/44 which carry no supporting-docs ref (re-measured: blank/heading/feature-text), failing measure-first; 3.3 KEEP-only soft-advisory confirmed non-fatal per JC-5 | COMPLIANT |
| no-false-dichotomy [foundation] | NUD-1 A-vs-B identified as a false dichotomy (B is a strawman violating JC-1's own clause); the real decision (reclassify K1.11–K1.14) named explicitly | COMPLIANT |
| categorical-first / directory-based [foundation] | New leak judged by LOCATION (`.mcp.json.example` under project-template/ → client-gated) not ship-status; `supporting-docs/` dead at client by directory absence; CLI-PM-SETUP confirmed not in install set | COMPLIANT |
| distrust-derived-claims [foundation] | Did not trust the strategy's/findings doc's summaries; re-read every load-bearing claim at file:line; caught the one non-reproducing claim (§2.2 README:13/38/44) | COMPLIANT |
| rules-applied-verification-block [universal] | This table | COMPLIANT |
| agents-never-commit / STOP-MEANS-STOP [universal] | No `git add/commit/push/tag`; only Read + read-only Bash (grep/find/sed/ls + heredoc to my own report) + one Write (this report); pre-existing prison `D` entries in `git status` untouched; no parent stop issued | COMPLIANT |
