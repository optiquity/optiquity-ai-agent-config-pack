# ARCHITECTURE — BD-206: Project-side per-entry, no-monolith-mirror, form-family conversion

**Architect (author):** `architect-bd206-nomirror` (fresh; not the prior BD-206 author, not any reviewer).
**Reconciled by:** `architect-bd206-reconcile` (fresh reconciliation instance; NOT the author, NOT the adversarial reviewer) — folds the adversarial review's 3 BLOCKERs + 4 MUSTs + 2 SHOULDs into this single doc.
**Final reconciliation by:** `architect-bd206-reconcile-2` (fresh; NOT the author, NOT the prior reconciler, NOT either reviewer) — folds the confirmation review's 1 BLOCKER + 2 MUSTs + 4 SHOULDs and CLOSES the under-counted-blast-radius class with an EXHAUSTIVE tracker-family sweep (EE-11).
**Designed at:** HEAD = `775e9cc139ef3fdde3d499198894a7bef70145e1`. **Reconciled at:** HEAD = `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7`, branch `v11-dev`, 2026-06-26 (the design's source files are UNCHANGED between the two HEADs — `git diff --name-only 775e9cc1 66c8332 -- scripts/ test-fixtures/ project-template/` = empty — so every design measurement transfers; the two new commits added the BD-248/BD-249 backlog entries only).
**Single design deliverable.** No companion/addendum docs; everything folds here.
**Read-only.** Pack repo + OptiquityTrader (OT) read-only; the only write is this doc.

> **Provenance of this design.** Authored FRESH from primary sources only:
> the OT-convert V2 GOLD (backlog 121347 B / impl-plan 344180 B) + the production
> OT changelog (179805 B) + the live pack repo + the binding ledgers
> (`DECISIONS-BD-206-RESTART.md`, `INVESTIGATION-BD-206-SIDECARS.md`) + the
> blast-radius `CENSUS-BD-206-MONOLITH-REFERENCES.md`. NO prior BD-206
> architecture / plan / review / reconcile doc was read (anti-contamination). The
> first reconciliation pass added the full-CI-battery breakage census (EE-9) and the
> complete encoding-layer enumeration (EE-10), and re-grounded EE-4/EE-6/EE-7. The
> FINAL reconciliation pass added the EXHAUSTIVE tracker-family enumeration (EE-11),
> folded 7 confirmation findings into O19/O25/EE-9/EE-10, and closed the
> under-counted-blast-radius class on the tracker test + Check-29 layer.

---

## 0. Executive summary

BD-206 converts the PROJECT side (the client-shipped `project-template/docs/project/`
template AND the machinery that operates on a populated client project) from the
legacy *monolith-with-regenerated-mirror* model to a **per-entry flat-file,
NO-monolith-mirror** model, with a **form-family schema** for backlog + implementation-plan,
a **structured (non-form-family) schema** for changelog, and **full drift enforcement**
(rules + tests + CI) in BOTH repos. It also overhauls every mechanism that assumed the
old model — installers, migrator, surface-detection, recommendation engine, validators,
governance docs, agent prompts, skill masters, the tracker library (reconciled-but-dormant),
the tracker `.toml` examples, the fixture builder, and `METHODOLOGY.md`.

**The design rests on three SSOT facts, each empirically pinned (Empirical-Evidence Blocks below):**
1. **The schema is the V2 GOLD, not v10.** Backlog = 113 `td` entries with a fixed core field
   set + a `Marker`-discriminated payload field (KNOWN GAP→Severity, TODO→Scope, VERIFY→Verify-Source).
   Impl-plan = 61 `phase-epic` + 15 `phase-part` entries. Changelog = 55 H3 date-anchored entries.
2. **`_rules.md` is the single machine-parseable schema SSOT**, parsed at runtime by BOTH the pack
   Python validator and the client bash validator — the existing `pe_supporting_files_admitted`
   parser (`scripts/lib/per-entry/_lib.sh:198-260`) is the precedent grammar (G-6).
3. **Wave A is the atomic foundational commit that takes the WHOLE CI BATTERY green** — not just
   `validate-pack.py` (the prior under-count). EE-4 pins the 14 validate-pack failures; **EE-9 pins
   the FULL-battery breakage** (the shell tests + persona contracts + `build.sh` that assert the
   old `_format.md`/mirror/support-set shape). Wave A lands ALL of them in lock-step so the first
   wave is green across the entire battery, per the binding §15 requirement + `verify-full-ci-suite`.

**Deliverable count: 27 deliverable IDs (O0–O26; O20-prose counted with O20)** across **5 waves**
(A foundational + B/C/D/E parallel). The reconciliation passes ADDED O23 (build.sh round-trip), O24
(Check-43 fixtures/test), O25 (tracker.toml + Check-29), O26 (operating-doc allowlists). **Wave F is
DROPPED** (SHOULD-1): the pack-side dead-mirror removal O22-pack is now the SEPARATE post-BD-206 BD
**BD-249** (Open, Target v11.0), not a BD-206 wave; only **O22-proj** stays in the BD-206 waves. Wave A
is large-but-green (the reconciliation EXPANDED its deliverable set per BLOCKER-1/2/3 then the final pass
folded the tracker-test inversions in lock-step with the Check-29 flip); large-but-green beats small-but-red.

**Reconciliation outcome (the 9 findings — all RESOLVED; fix-location in §9 Reconciliation log):**
- **BLOCKER-1** (Wave-A not full-battery green) → EE-9 + §6 Wave-A re-grounded against the WHOLE battery.
- **BLOCKER-2** (`test-fixtures/build.sh`) → O23 (NEW deliverable) + EE-9 + §6 Wave-A; round-trip redesigned.
- **BLOCKER-3** (`_format.md` lock-step incomplete) → EE-6 re-measured (23 operational, new membership) + O1 expanded + O9 + O24 (NEW).
- **MUST-1** (`tracker.toml` examples) → O25 (NEW) + §5 DR-4 (Check-29 `mirror_required` flip in lock-step).
- **MUST-2** (2nd force var `PE_FORCE_OVERWRITE_MIRROR`) → EE-7 re-measured + O7/DR-1 enumeration + O23.
- **MUST-3** (operating-doc allowlists) → O3 lock-step + O26 (NEW).
- **MUST-4** (`_index.md` admission) → O11 + O1 lock-step (`_lib.sh:123` add `_index.md`).
- **SHOULD-1** (Wave-F vs BD-249) → Wave F DROPPED; BD-249 is the downstream anchor; §7 SS-5 resolved.
- **SHOULD-2** (§16(5) paper-coverage) → §1 map updated; EE-9 delivers the green existing battery per wave.

**Final-reconciliation outcome (the confirmation review's 7 findings + the class-closing sweep — all RESOLVED; fix-location in §9 Reconciliation log):**
- **BLOCKER-A** (`tracker-config-schema-test.sh` Test 7 pins Check-29 `mirror_required=True` for the client → inverts under the Wave-A O25/DR-4 flip) → O25 expanded + EE-9 Wave-A inversion-set row + §6 Wave A.
- **MUST-A** (`tracker-agent-read-test.sh:71,190-192` seeds a monolith + asserts the read → flips under O19's monolith→tree repoint) → O19 expanded (test lock-step) + EE-9 (Wave-E row) + EE-11.
- **MUST-B** (the LIVE emitter `tracker-init.sh:359-376` still WRITES the client `[mirror]` table + `tracker-init-test.sh:296-302` asserts it — contradicts the no-mirror end-state) → O25 expanded (emitter + its test reconciled in lock-step with the static-example drop, Wave A) + EE-11.
- **SHOULD-A** (`.dangling-ref-allowlist.txt:101,104` stale project-mirror tokens) → O26 expanded + EE-11.
- **SHOULD-B** (`test-fixtures/README.md` round-trip prose) → O23 expanded + EE-11.
- **SHOULD-C** (`MERGE-STRATEGY.md:274-275` project-monolith prose) → CLASSIFIED IN-SCOPE (live project-side operating-doc prose BD-206 invalidates; NOT pack-side/BD-249, NOT historical) → O1 doc-ref lock-step (joins the existing `:270` `_format.md` ref) + EE-11.
- **SHOULD-D** (`tracker-config-test.sh:73` `mirror.enabled` assert) → CLASSIFIED KEEP / NO-BREAK: `:73` reads the `tracker-mode.toml` (`mode.state="tracker"`) fixture and `tracker-config.sh` is a pure TOML parser asserting the parser maps `[mirror].enabled`; in tracker mode the `[mirror]` table is the SEPARATE tracker→file read-only-mirror feature (KEEP), not the per-entry→monolith assumption → enumerated KEEP in EE-11, no edit.

**Class-closing tracker-family sweep (EE-11):** the under-counted-blast-radius class — operational layer (round 1), test/fixture layer (round 2), tracker-test + Check-29 layer (round 3) — is now CLOSED by an EXHAUSTIVE measure-then-bound sweep of the WHOLE tracker family (52 tracked lib/script/test/`.toml` files from `git ls-files`). EE-11 classifies EVERY surface that encodes the per-entry→monolith assumption / the `[mirror]` table / Check-29 `mirror_required` / the monolith fallback-read / the emitter behavior as KEEP (tracker→file read-only mirror feature — PRESERVE) vs REPOINT/REMOVE (per-entry→monolith assumption). Tracker stays gated OFF (BD-214); the sweep reconciles dormant assumptions, it does NOT activate the feature.

**New scoping-signals for the user** (do NOT defer without direction; §16):
- **SS-1** Tracker reconciliation volume (~40+ refs, 9 files) — comment/contract repointing of the
  per-entry→**monolith** assumption ONLY, preserving the separate tracker→file read-only-mirror
  feature (`tracker-mirror.sh`). PLUS the two `tracker.toml` examples + `tracker-init-test.sh` (MUST-1, O25). In-scope.
- **SS-2** `METHODOLOGY.md` wholesale plan-model rewrite (24 IMPLEMENTATION-PLAN refs) — in-scope by the newest binding decision; O14.
- **SS-3** `force-overwrite-mirror` divergence-gate removal-ripple — TWO env vars (`_MIGRATOR_FORCE_OVERWRITE_MIRROR`
  + `PE_FORCE_OVERWRITE_MIRROR`); DR-1/O7 cleans both with a two-pattern grep-zero gate.
- **SS-4** BD-246 (non-mutation checksum) + BD-247 (pack-side form-family) + the v11.1 pack-side
  backlog-compliance anchor (G-5) — OUT of scope, each with a tracked anchor.
- **SS-5** DR-2 RESOLVED to (C) — dead mirror subsystem removed on BOTH sides. O22-proj lands in
  BD-206 waves; **O22-pack is BD-249** (separate `pack-only` BD, sequenced after BD-206). The
  anchor is now RESOLVED (BD-249 exists, Open, v11.0) — no longer an open Pack-Chat question.
- **O21** the client-facing `supporting-docs/MIGRATION-v10-to-v11.md` rewritten to no-mirror (Wave D).


---

## 1. Foundational-requirements coverage map (§16 binding lens)

Every §16 foundational requirement maps to concrete deliverables; a gap here is grounds for a
follow-up architect pass. **Reconciliation update:** §16(1) + §16(5) now also point at the
EXISTING-battery lock-step (EE-9), the encoding-layer completion (EE-10), and the EXHAUSTIVE
tracker-family sweep (EE-11) — the guardrail's encoding (tests/fixtures/allowlists/constants/.toml/emitter)
moves with the surface, not after it.

| §16 requirement | Where satisfied (deliverable) |
|---|---|
| (1) Guardrail-maintenance (rules+tests+CI, both repos) | O3 (`_rules.md` schema SSOT), O9 (pack Python leg + Check-43 lock-step O24), O10 (client bash leg), O11 (`_index.md` validator + `_lib.sh:123` admission, MUST-4), O12 (changelog conformance), O13 (graceful phase/part/task naming guard); **encoding completeness: O24 (Check-43 fixtures/test), O26 (operating-doc allowlists + `.dangling-ref-allowlist.txt`), O25 (tracker.toml + Check 29 + emitter + tracker tests), EE-10 + EE-11 (the COMPLETE tracker-family sweep)** |
| (2) Freshness + accuracy | O8 (`_toc.md` regen at install), O11 (`_index.md` derive+validate sync), O7 (decompose emits tree+TOC, no mirror), O12 (changelog structure stays in sync) |
| (3) File structure (per-entry tree + 4-sidecar) | O1 (sidecar vocabulary + tree shape + `_index.md` admission), O2 (`_intro.md`), O3 (`_rules.md`), O8 (install emits the shape), O22-proj (remove the project dead-mirror constants; pack half = BD-249) |
| (4) Operational mechanics (PM Chat + agents) | O15 (trinity Document-locations), O16 (PM-CHAT plan read/write model), O17 (agent prompts), O18 (skill masters), O14 (METHODOLOGY), O21 (MIGRATION client doc) |
| (5) Testing + integrity | O9/O10/O11/O12/O13 enforcement + their tests; O6 (recommendation tests); O5 (detect/help tests); **O23 (build.sh round-trip redesign + README prose), O24 (Check-43 fixtures + test), O25/O19 (the tracker-test inversions — `tracker-config-schema-test.sh` Test 7, `tracker-init-test.sh` 3.5, `tracker-agent-read-test.sh` — land lock-step with their deliverables), EE-9 (the EXISTING battery stays GREEN at each wave — test-init-project/test-per-entry/test-v11-realistic-ot/test-migrate-decompose/persona-contracts + the tracker tests re-grounded), EE-11 (the COMPLETE tracker family swept + KEEP/REPOINT classified)**; O22-proj (remove dead project mirror test coverage); BD-246 (non-mutation checksum) + BD-249 (pack dead-mirror removal + its test coverage) referenced, OUT of scope with tracked anchors |
| (6) Ease of future tracker integration | O3 (form-family mappable schema + bold-pair carrier per G-5), O12 (structured changelog), O19 (tracker reconciliation preserves the dormant carrier + TrackerProvider abstraction; tracker→file M-track feature KEPT per EE-11), O25 (tracker.toml examples + the live `tracker-init.sh` emitter + the tracker tests adjudicated to the no-mirror model with Check 29 staying green; EE-11 classifies the COMPLETE 52-file family KEEP-vs-REPOINT) |


---

## 2. Empirical-Evidence Blocks (the state-claims this design rests on)

> EE-1..EE-8 measured at design HEAD `775e9cc1`; EE-9/EE-10 (reconciliation) measured at HEAD
> `66c8332`, 2026-06-26. The design source tree is byte-identical between the two HEADs
> (`git diff --name-only 775e9cc1 66c8332 -- scripts/ test-fixtures/ project-template/` = empty),
> so all measurements are mutually consistent.

### EE-1 — Backlog GOLD is 113 `td` entries with a Marker-discriminated payload
- **Command:** `grep -oE '^\*\*Marker\*\*: .+' <V2/BACKLOG.md> | sort | uniq -c` ; `grep -oE '^\*\*Scope\*\*: .+'` ; `'^\*\*Severity\*\*: .+'` ; `'^\*\*Verify-Source\*\*: .+'`
- **Verbatim output:** Marker = `81 KNOWN GAP`, `25 TODO`, `7 VERIFY` (sum 113). Severity = `1 critical`, `54 functional`, `26 polish` (sum 81 = KNOWN GAP count). Scope = `3 dependency`, `9 feature`, `13 phase-N` variants (sum 25 = TODO count). Verify-Source = `1 etrade-api`, `2 public-api`, `4 schwab-api` (sum 7 = VERIFY count). Entry-Type = `113 td`.
- **Interpretation:** the Marker→payload correspondence is EXACT and total: every KNOWN GAP carries Severity, every TODO carries Scope, every VERIFY carries Verify-Source. This IS the form-family discriminator.
- **Conclusion: SUPPORTED.** Independently re-verified SOUND by the adversarial review (EXACT match). The backlog form family is `Entry-Type: td` + core `{ID, Marker, Status, Blockers, Unblocks, File/Symbol, Description, Context}` + Marker-keyed payload `{Severity | Scope | Verify-Source}` + `Resolution` (Resolved only, 56).

### EE-2 — Impl-plan GOLD is 61 `phase-epic` + 15 `phase-part`; parts are lightweight
- **Command:** `grep -oE '^\*\*Entry-Type\*\*: [a-z-]+' | sort | uniq -c` ; `grep -A1 '^\*\*Entry-Type\*\*: phase-part' | grep '^\*\*' | sort | uniq -c` ; heading scan `grep -nE '^(## |### |#### )'`.
- **Verbatim output:** `61 phase-epic`, `15 phase-part`. phase-part entries carry ONLY `**Entry-Type**: phase-part`. phase-epic fields: `Entry-Type, ID, Status, Blockers, Unblocks, Goal, Prerequisite` (each 61). Heading shape: `## Phase N — Title`, `### Tasks`/`### Verification`/`### Agent`/`### Risks`, `#### N.M — Title`, `### Phase-N.Part-x — Title`, `#### Phase-N.Part-x.Task-k — Title`.
- **Interpretation:** confirms §13 Item-3 (a) LIGHTWEIGHT parts + the graceful naming convention. The OT gold ALREADY conforms → no forced refactor.
- **Conclusion: SUPPORTED.** Independently re-verified SOUND (EXACT).

### EE-3 — Changelog GOLD: 55 H3 date entries, max 130 lines / 243 Summary words
- **Command:** entry line-count distribution via awk between `^### YYYY-MM-DD` headers; `grep -oE '^\*\*[label]\*\*:' | sort | uniq -c`; max-Summary-words awk.
- **Verbatim output:** 55 entries; min/p50/p90/p95/max line-count = (small)/38/84/93/**130**; max Summary words = **243**. Field freq: `Summary 54`, `Test count 38`, `Sections updated 28`, `Files modified 27`, `Files created 25`, `Build warnings 15`, `Tasks completed 14`, … (~30 one-off labels).
- **Interpretation:** G-2b gold-safe caps `entry-max-lines: 180` (>130) + `summary-max-words: 250` (>243) yield ZERO gold violations. G-2 core set `{Summary + Test count + ≥1 Files field}` is the high-frequency intersection; doc-only entries take the Summary-only exemption.
- **Conclusion: SUPPORTED.** Independently re-verified SOUND (EXACT).

### EE-4 — validate-pack's 14 failures are EXACTLY the deleted-sidecar rows (NECESSARY, not SUFFICIENT, for green CI)
- **Command:** `python3 scripts/validate-pack.py 2>&1 | grep -E 'Check (39|41)|FAIL'` (reconfirmed at HEAD `66c8332` against the working tree's 8 uncommitted deletions).
- **Verbatim output (reconfirmed):** Check 39 FAILs (7): backlog `_intro.md`+`_rules.md`, impl-plan `_intro.md`+`_rules.md`, changelog `_intro.md`+`_rules.md`+`_format.md`. Check 41 FAILs (7): identical seven paths. `FAILED — 14 issue(s) found`.
- **Interpretation (CORRECTED in reconciliation):** the 14-count is EXACT and is the dangling install-map / `_CLIENT_INSTALLED_FILES` references to the 7 hand-deleted sidecars. Restoring 6 (rebuilt) + deleting the 2 `_format.md` rows clears all 14. **BUT clearing validate-pack is NECESSARY, NOT SUFFICIENT** — the prior conclusion ("necessary AND sufficient for green CI") was WRONG because it scoped the measurement to ONE tool. The FULL CI battery (`.github/workflows/validate-pack.yml:192-202`) ALSO runs `test-fixtures/build.sh --all/--verify` + the auto-sharded `scripts/test*.sh + scripts/tests/*.sh` battery, which assert the OLD shape (EE-9). Wave-A green requires the EE-9 set too.
- **Conclusion: SUPPORTED (count); the "sufficient" claim is REPLACED by EE-9.**

### EE-5 — `_rules.md` runtime-parse precedent exists (`pe_supporting_files_admitted`)
- **Command:** `sed -n '198,260p' scripts/lib/per-entry/_lib.sh`.
- **Verbatim output:** an `awk` parser keyed on `/^## Supporting files/` … `/^## /` reading `- \`basename\`` bullets, returning the intersection of declared-and-known basenames; falls back to a hard-coded set when `_rules.md` is absent.
- **Interpretation:** the `_rules.md`-as-runtime-schema-SSOT pattern (Item-8, G-6) is ALREADY in production. The form-family + changelog-structure schema blocks extend the SAME `## <Section>` + `- key: tokens` grammar.
- **Conclusion: SUPPORTED.** Independently re-verified SOUND.

### EE-6 — `_format.md` operational blast radius = 23 tracked files (RE-MEASURED; new membership) — BLOCKER-3
- **Command (reconciliation, HEAD `66c8332`):** `git grep -lE '_format\.md'` → 97 tracked; `git grep -lE '_format\.md' -- ':!maintenance-docs/' ':!backlog/' ':!changelog/'` → **23 operational**; plus per-line `git grep -nE '_format\.md'` on the 23.
- **Verbatim output — the 23 operational files:** `README.md`, `pack-ops/MERGE-STRATEGY.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/.operating-doc-history-allowlist.txt`, `pack-ops/.operating-doc-deferred-feature-allowlist.txt`, `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, `scripts/lib/per-entry/_lib.sh`, `scripts/lib/per-entry/mirror-generate.sh`, `scripts/lib/migrate-v10-to-v11/decompose.sh`, `scripts/validate-pack.py`, `scripts/persona-contracts/contract-greenfield.sh`, `scripts/persona-contracts/contract-migration.sh`, `scripts/tests/test-init-project.sh`, `scripts/tests/test-per-entry.sh`, `scripts/tests/test-validate-pack-check-43.sh`, `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh`, `scripts/tests/fixtures/project-side-refs/project-side-pass-same-dir-skeleton.md`, `scripts/tests/fixtures/project-side-refs/project-side-fail-per-entry-skeleton.md`, `project-template/scripts/validate-docs.sh`, `project-template/scripts/.docs-gate-allowlist.txt`, `project-template/skills/audit-methodology/SKILL.md`, `supporting-docs/MIGRATION-v10-to-v11.md`.
- **The corrected membership (the prior EE-6 "26" was an over-count of files BUT under-counted the test/fixture/allowlist surfaces — wrong membership).** The reconciliation-added surfaces (NOT in the prior EE-6 list / not in any prior deliverable):
  - `scripts/tests/test-init-project.sh:221,227,239,246-248,256-258,266-268,309-310,316,333` — the 4.2 asymmetry asserts (4.2 asserts changelog `_format.md` PRESENT) + the 4.5 byte-identity (`CHANGELOG.md == _intro.md + '---' + _format.md`).
  - `scripts/tests/test-per-entry.sh:231-232` — `1.9 project-changelog known supporting includes _format.md` (asserts the `_lib.sh:136` support-set string — FLIPS to FAIL the instant O1 drops `_format.md`).
  - `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh:143,172,183-188` — A.13 `_format.md` present + A.15 impl-plan `_format.md` absent asserts.
  - `scripts/persona-contracts/contract-greenfield.sh:212,231,239` + `contract-migration.sh:422,458,471` — `_format.md` in the expected-files arrays.
  - `scripts/tests/fixtures/project-side-refs/project-side-pass-same-dir-skeleton.md:13,21` ("Bare refs to `_intro.md`, `_rules.md`, `_format.md` MUST PASS Check 43 via the allowlist") + `…fail-per-entry-skeleton.md:14` — the DANGEROUS PASS fixture: a fixture that asserts `_format.md` MUST PASS Check 43, directly contradicting the FORBIDDEN model. Consumed by `test-validate-pack-check-43.sh`.
  - `scripts/validate-pack.py:5503` (`"_format.md": "Per-entry tree format sibling (same-dir resolution)"` — the Check-43 sibling allowlist, distinct from the mirror-rationale 5504-5507), `:8225` (the operating-doc family-glob set member `project-template/docs/project/changelog/_format.md`), and `:5094` (`"BD-NNN.md": "… (template; see /backlog/_format.md)"` — a PHANTOM pack-side ref: `backlog/_format.md` does NOT exist (`ls backlog/_format.md` = absent) → STRIP the parenthetical).
  - `scripts/tests/test-validate-pack-check-43.sh:133-138` (the `required_entries` set that asserts `_CHECK_43_ALLOWLIST` MUST contain `_format.md` + the 3 monoliths — FLIPS to FAIL when O9 removes them) + `:483,489` (the T9 PASS fixture synthesizing a `_format.md` and asserting Check 43 passes). NOTE: the mandate cited `:530,540`; the ACTUAL lines at HEAD `66c8332` are `:133-138` (allowlist-required set) + `:481-494` (T9). Coder uses the re-grep at impl time, not these literals.
- **Interpretation:** `_format.md` elimination is a multi-surface lock-step edit across operational code + DOCS + the validator allowlist/operating-doc set + the persona contracts + the TESTS + the Check-43 PASS fixtures. Several of these surfaces double as the EE-9 atomicity breaks. Its CONTENT (changelog format rules) folds into the changelog `_rules.md` formatting section (Item-4 / Q4).
- **Conclusion: SUPPORTED.** The FORBIDDEN-`_format.md` grep-zero gate must be sized against this 23-file operational set (audit-history under `maintenance-docs/`/`backlog/`/`changelog/` exempt). O1 + O9 + O24 carry the elimination; O21 carries the MIGRATION-doc share.

### EE-7 — TWO force-overwrite vars are woven through the divergence-gate (G-8 ripple; MUST-2)
- **Command:** `git grep -nE '_MIGRATOR_FORCE_OVERWRITE_MIRROR|force-overwrite-mirror'` ; `git grep -nE 'PE_FORCE_OVERWRITE_MIRROR' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'`.
- **Verbatim output:** there are TWO distinct vars. (1) `_MIGRATOR_FORCE_OVERWRITE_MIRROR` (the migrator-framework flag) in `decompose.sh`, `migrator-core.sh`, `mirror-generate.sh`, `migrate-v10-to-v11.sh`, `README.md`, `MERGE-STRATEGY.md`, `MIGRATION-v10-to-v11.md`, + Group-4 tests. (2) `PE_FORCE_OVERWRITE_MIRROR` (the per-entry-layer bypass the migrator EXPORTS to) in `mirror-generate.sh:40,251,253,288,342` (the ACTUAL bypass + warning logic), `decompose.sh:27,57,117,120,125` (the bridge `_MIGRATOR_*` → `PE_*`), `migrator-core.sh:326`, `test-fixtures/build.sh:496,552,555`, `test-v11-realistic-ot.sh:230,274`, `test-migrate-v10-to-v11-decompose.sh` Group 3/4, `test-per-entry.sh:336,373,376,488,491,497` (Group 8).
- **Interpretation:** the flag exists SOLELY to gate overwriting a hand-edited *regenerated mirror* on divergence. With no project mirror generated, the entire divergence-gate path loses its subject. The removal ripples to BOTH vars: the migrator flag + its bridge + the `PE_FORCE_OVERWRITE_MIRROR` consumers. The `mirror-generate.sh` + `test-per-entry` Group-8 consumers are removed by BD-249 (O22-pack) when the file/coverage is deleted; the `build.sh:496,552,555` consumers are handled by O23 (round-trip redesign); the `decompose.sh` bridge + `migrator-core.sh:326` + `migrate-v10-to-v11.sh` flag wiring + Group-4 tests are removed by O7/DR-1.
- **Conclusion: SUPPORTED (with ripple, TWO vars).** The grep-zero gate must use a TWO-pattern regex covering BOTH names (DR-1).

### EE-8 — The mirror subsystem is dead on BOTH sides; pack-side vestiges remain (DR-2=C call-site census)
- **Command:** `git grep -lE 'mirror-generate|per_entry_regenerate_mirror|pe_canonical_mirror_for_stream|mirror\) printf' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'` plus per-symbol `git grep -nE`.
- **Verbatim output (operational; audit-history excluded):** 12 files carry the symbols — `init-project.sh`, `migrate-v10-to-v11/decompose.sh`, `per-entry/_lib.sh`, `per-entry/decompose.sh`, `per-entry/mirror-generate.sh`, `per-entry/toc-regenerate.sh` (doc-comment only), `tests/fixture-dependent/test-v11-realistic-ot.sh`, `tests/test-init-project.sh`, `tests/test-migrate-v10-to-v11-decompose.sh`, `tests/test-per-entry.sh`, `tests/test-validate-pack-checks-32-33-34.sh`, `test-fixtures/build.sh`. The 5 `mirror) printf` constants are at `_lib.sh:85,99` (pack) + `_lib.sh:109,121,129` (project). The accessor `pe_canonical_mirror_for_stream` is `_lib.sh:150-152` (def + sole production wrapper).
- **Live-vs-dead classification:** `per_entry_regenerate_mirror` / `mirror-generate.sh` is LIVE-but-dead-in-production: its ONLY non-test callers are the project generation paths (`init-project.sh:1113`, `decompose.sh:195`) — both REMOVED by O4/O7. After O4/O7 the only callers are TESTS. The PACK-side test callers (`test-per-entry.sh` Groups 3/4/8/9; `test-validate-pack-checks-32-33-34.sh:276`; `test-init-project.sh:416,427` Group-5 idempotency) + the project test/fixture callers are dead-after-removal. `pe_canonical_mirror_for_stream`'s only callers are `test-per-entry.sh:219-221`. `toc-regenerate.sh`'s `per_entry_regenerate_toc` is a SEPARATE, surviving function (doc-comment cleaned only).
- **Interpretation:** the entire mirror subsystem is dead once O4/O7 remove the two production generation call-sites. **Reconciliation note:** the PACK-side removal (the `mirror-generate.sh` deletion + the pack constants + pack/test coverage) is now tracked as **BD-249** (separate `pack-only` BD), NOT a BD-206 wave (SHOULD-1). BD-206 keeps **O22-proj** (the project `_lib.sh:109,121,129` constants + `test-per-entry.sh:219-221` asserts). The 12-file operational set straddles both BDs; the grep-zero gate is JOINT (BD-206 O22-proj + BD-249 O22-pack ⇒ zero).
- **Conclusion: SUPPORTED.** DR-2=C sound; BD-249 is the pack-side anchor (§7 SS-5 resolved).

### EE-9 — FULL-CI-BATTERY breakage census (the BLOCKER-1 root: which EXISTING tests break, and under which deliverable) — RECONCILIATION
- **Method:** read the CI workflow to enumerate what the FULL battery runs; then, for every Wave-A/early deliverable, enumerate the EXISTING test/fixture/persona assertions that go RED under it. Candidate set from `git ls-files`; greps tracked-tree-scoped.
- **Command 1 (what CI runs):** `git grep -nE 'build\.sh|run shard|needs-fixtures' -- .github/workflows/validate-pack.yml`.
- **Verbatim:** `:192 if python3 scripts/lib/ci-shard-plan.py --shard … --needs-fixtures; then`; `:193 bash test-fixtures/build.sh --all --clean`; `:195 bash test-fixtures/build.sh --verify`; `:202 - name: run shard ${{ matrix.shard }}` (the auto-discovered `scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh` battery). **So CI = validate-pack.py + build.sh + the shell battery** — three legs, not one.
- **Command 2 (baseline):** `bash scripts/tests/test-per-entry.sh` at HEAD `66c8332` → `PASS: 57 FAIL: 0`. `python3 scripts/validate-pack.py | grep 'issue'` → `FAILED — 14 issue(s) found` (the working-tree deletions, EE-4). Interpretation: the source tree is GREEN except the 14 validate-pack rows; the shell battery is GREEN **only because the source still carries the old shape** (e.g. `test-per-entry.sh:231` passes because `_lib.sh:136` still says `_format.md`). The instant a Wave-A deliverable changes that source, the corresponding test FLIPS.
- **The breakage matrix (EXISTING tests that go RED, by deliverable):**

  | Deliverable | EXISTING test/fixture/persona that BREAKS | The assertion (verbatim file:line) | Wave-A action |
  |---|---|---|---|
  | O1 (`_lib.sh:136` drop `_format.md`) | `test-per-entry.sh:231-232` | `1.9 project-changelog known supporting includes _format.md` (asserts the support-set STRING) | invert to assert `_format.md` ABSENT from the support-set |
  | O1 (`_format.md` FORBIDDEN, template) | `test-init-project.sh:266-268` | `4.2 changelog/_format.md present` `t_fail … missing` | invert: assert changelog `_format.md` ABSENT (all 3 streams) |
  | O1 | `contract-greenfield.sh:239` + `contract-migration.sh:471` | `"docs/project/changelog/_format.md"` in expected-files array | drop the `_format.md` array entry + the 212/231/422/458 asymmetry comments |
  | O1 | `test-v11-realistic-ot.sh:172` (+143,183-188) | `A.13 changelog/_format.md present` | invert to A.13 absent; A.15 (impl-plan `_format.md` absent) STAYS but the comment updates |
  | O4 (no greenfield mirror) | `test-init-project.sh:272-280` | `4.3 docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md mirror present at parent` | invert: assert the 3 monoliths ABSENT (BD-203 pack-side inversion pattern) |
  | O4 | `test-init-project.sh:297,302,332` (4.4/4.5 byte-identity) | `cmp -s … BACKLOG.md == _intro.md`; `CHANGELOG.md == _intro.md + '---' + _format.md` | DELETE the byte-identity asserts (no mirror subject) |
  | O4 | `test-init-project.sh:386-394` (Group-5 4.6 snapshot) + `:416,427` | the 6-output snapshot set lists the 3 mirrors; Group-5 sources `mirror-generate.sh` + calls `per_entry_regenerate_mirror` | drop the 3 mirror rows from the snapshot set; Group-5 mirror-regen path removed (also a BD-249 concern, see EE-8) |
  | O4 | `contract-greenfield.sh:240-244` | `# greenfield empty mirrors` + the 3-monolith array | drop the 3 monoliths from the expected-files array |
  | O7 (decompose no regenerate) | `test-migrate-v10-to-v11-decompose.sh:300-307` (2.2a/b/c) | `regenerated mirror {BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md present` | invert: assert NO regenerated mirror (tree + `_toc.md` only) |
  | O7 | `test-v11-realistic-ot.sh:236-241,287` (Group B) | `regenerated mirrors byte-identical to fresh regen` (B.1-B.6) | DELETE Group B (no mirror to byte-compare) |
  | O7 | `contract-migration.sh:475` | comment re mirror+`_toc` generation | align to no-mirror (tree + `_toc.md`) |
  | O23 (build.sh) | `test-persona-contracts.sh` (runner) + `build.sh:537-573` | `die "monolithic mirror missing"` / round-trip byte-identity | redesigned (O23) |
  | O9 (Check-43 allowlist) | `test-validate-pack-check-43.sh:133-138` | `required_entries` MUST include `_format.md` + 3 monoliths | O24 moves the required-set in lock-step |
  | O9 | `test-validate-pack-check-43.sh:481-494` (T9) | synthesizes `_format.md`, asserts Check 43 PASSES | O24 removes/repoints the PASS fixture |
  | O25/DR-4 (Check-29 client `mirror_required` True→False) | `tracker-config-schema-test.sh` Test 7 (`:223-242`; GOOD_CLIENT `[mirror]` `:116-131`) | `7.1 missing mirror on client → exit nonzero` + `7.2 message names mirror as missing on the client example` (PINS `mirror_required=True`) | invert Test 7: a client example missing `[mirror]` must now PASS; strip the GOOD_CLIENT `[mirror]` block; rewrite the `:17-20,224-226` "required until BD-206" header (Wave A, lock-step with the `:2796` flip) |
  | O25 (live emitter no-mirror) | `tracker-init-test.sh:296-302` (3.5) | `3.5 mirror.enabled=true` + `3.5 mirror.location_backlog ("BACKLOG.md")` + `…location_status/changelog/regenerate_on_write` assert the EMITTED client `[mirror]` table | invert: assert the client init config OMITS `[mirror]` (lock-step with the `tracker-init.sh:359-376` emitter drop); rewrite the `:14-16,280-283` "until BD-206" comments (Wave A) |
- **Wave-E (O19) tracker-agent-read break (NOT Wave A — O19 is dormant, lands in Wave E):**

  | Deliverable | EXISTING test that BREAKS | The assertion (verbatim file:line) | Wave-E action |
  |---|---|---|---|
  | O19 (`tracker-agent-read.sh` TD-*/phase-* fallback monolith→tree repoint, `:251-278`) | `tracker-agent-read-test.sh:71-78,190-192` | `:71` seeds ONLY `docs/project/BACKLOG.md` (`**TD-010 — Document quux**`), NO per-entry tree; `:191-192` `2.3 TD-010 entry header` asserts the read resolves | land WITH O19 in Wave E: seed the project per-entry tree (`docs/project/backlog/TD-010.md`) instead of the monolith, OR keep a monolith-INPUT fallback for a mid-migration client and assert accordingly per O19's repoint disposition; rewrite the `:34-43` fixture comment |

  **`verify-full-ci-suite` prior-recurrence note:** this is the EXACT file the memory records as the BD-214 C1 recurrence (a dormant `tracker-*` test, CI-wired in the `tests` job, missed by a "green-on-validate-pack" verification). Folding it into O19 + EE-11 closes the recurrence. NOTE: because O19 is Wave E (dormant `tracker-*.sh`), this break is a WAVE-E full-battery break, NOT a Wave-A break — but it IS a CI-battery surface and MUST land lock-step in O19's commit.
- **Interpretation:** the Wave-A deliverable set as originally scoped (O0+O1+O2+O3+O4+O8) makes `validate-pack.py` green but turns `test-per-entry`, `test-init-project`, `test-v11-realistic-ot` (A-group), the persona contracts (+`build.sh`) RED — and the O7/O9/O23/O24-adjacent tests break in their waves. **The §15 binding requirement ("the tree goes and stays GREEN at the first wave") forces the EXISTING-test inversions for any deliverable that lands in Wave A to land WITH it.** The reconciliation EXPANDS Wave A to include the O1/O4/O8/O23/O24 EXISTING-test inversions (§6).
- **Conclusion: SUPPORTED (re-grounded by the FINAL reconciliation).** Wave-A green ⇔ the full battery (validate-pack + build.sh + the shell battery INCLUDING the tracker tests `tracker-config-schema-test.sh` + `tracker-init-test.sh`) is green; the EXISTING-test inversions — now INCLUDING the tracker Test 7 inversion + the `tracker-init-test.sh` 3.5 inversion (lock-step with the Check-29 flip + the emitter drop) — are part of the atomic Wave-A commit. The Wave-E O19 break (`tracker-agent-read-test.sh`) lands lock-step in O19's commit. Large-but-green.

### EE-10 — COMPLETE encoding-layer enumeration (Part-2 mandate: close the failure CLASS) — RECONCILIATION
- **Method (measure-then-bound, candidate set = `git ls-files` 1762 tracked; graph-first DISCOVERY then grep VERIFICATION):** for EVERY in-scope operational surface, enumerate in lock-step ALL of {its tests, its fixtures, the CI-workflow steps that run them, the validate-pack allowlists / operating-doc sets, the `tracker.toml` examples, the `_lib.sh` constants} that ENCODE the mirror / `_format.md` / sidecar-vocabulary / support-set / `_index.md` state.
- **Graph DISCOVERY:** `graphify query "Which test files, fixtures, validators, and CI workflow steps encode … the project-side monolith mirror, the changelog _format.md sidecar, or the per-entry support-set vocabulary?" --graph …/graph.json --backend claude-cli --budget 1500` → BFS depth=2, 107 nodes; surfaced validate-pack.py, init-project.sh, the trinity, METHODOLOGY, PM-CHAT, SKILL masters, README + a community of historical IMPL reports (exempt). **The graph's candidate set was fully contained within the grep ground-truth** (no graph-only operational candidate beyond the census + my greps).
- **The complete encoding layer (state → its encoding surfaces, lock-step):**

  | State encoded | Surface | Tests | Fixtures | CI step | Validator / allowlist / constant | tracker.toml | Resolved by |
  |---|---|---|---|---|---|---|---|
  | greenfield mirror generation | `init-project.sh:1084-1121` | `test-init-project.sh:266-336,386-442` | — | shard (auto) | — | — | O4/O8 + EE-9 inversions |
  | `_format.md` sidecar | template + `_lib.sh:136` | `test-per-entry.sh:231-232`, `test-init-project.sh:4.2/4.5`, `test-v11-realistic-ot.sh:143,172,183-188` | `project-side-{pass,fail}-…skeleton.md` | shard | `validate-pack.py:5503,8225,5094`; `.docs-gate-allowlist.txt`; operating-doc allowlists `419,145,150` | — | O1/O9/O24/O21/O26 |
  | Check-43 allowlist + PASS fixtures | `validate-pack.py:5503,5504-5507,5590-5593,5094` | `test-validate-pack-check-43.sh:133-138,481-494` | the 2 project-side-refs skeletons | shard | the allowlist itself | — | O9 + O24 (DR-3) |
  | support-set vocabulary | `_lib.sh:91,103,111,123,136` | `test-per-entry.sh:219-221,231-232` | — | shard | `pe_supporting_files_admitted/_known` | — | O1 (drop `_format.md`@136; ADD `_index.md`@123, MUST-4) + O22-proj (mirror constants) |
  | `_index.md` admission | `_lib.sh:123` (impl-plan support-set) | the new "no stray sidecar" legs O9/O10 | — | shard | the admission set | — | O1/O11 (MUST-4) |
  | divergence-gate / 2 force vars | `mirror-generate.sh`, `decompose.sh`, `migrator-core.sh`, `migrate-v10-to-v11.sh` | `test-per-entry.sh` Group 8, `test-migrate-decompose` Group 3/4 | — | shard | — | — | O7/DR-1 (two-pattern gate) + BD-249 (mirror-generate consumers) |
  | round-trip fixture builder | `test-fixtures/build.sh:516-578`; `test-fixtures/README.md:30,189-191` round-trip PROSE (SHOULD-B) | `test-persona-contracts.sh` (runner) | persona-contract trees | `:193,195` build/verify | manifest-inputs.sh `:56,58` (manifest fixture-input → BD-228 Check 62) | — | O23 (NEW; incl. README prose) |
  | mirror constants / generator / accessor | `_lib.sh:85,99,109,121,129,150-152`, `mirror-generate.sh` | `test-per-entry.sh` Groups 3/4/8/9, `test-validate-pack-checks-32-33-34.sh:273-278`, `test-init-project.sh:416,427` Grp5 | — | shard | — | — | O22-proj (project `109,121,129` + `test-per-entry:219-221`); BD-249 (pack `85,99` + `mirror-generate.sh` + accessor + Grp 3/4/8/9 + checks-32-33-34) |
  | tracker→monolith mirror assumption (COMPLETE family — see EE-11) | `tracker-init.sh:185-192,318-376` emitter + the `tracker-*.sh` family (`tracker-agent-read.sh:251-278`, `tracker-doctor.sh:120-200`, `tracker-migrate-forward.sh:1395,2149-2162`, `tracker-promote.sh`, `tracker-phase-task.sh`, `tracker-migrate.sh`) | `tracker-config-schema-test.sh` Test 7 (`:17-20,116-131,223-242`), `tracker-init-test.sh:14-16,256-302`, `tracker-agent-read-test.sh:34-78,190-192` | the `tracker-config/*.toml` `[mirror]` fixtures (KEEP — tracker-mode feature, EE-11) | shard | `validate-pack.py` Check-29 `mirror_required` (`:2492-2497,2571-2573,2790-2796`); `.dangling-ref-allowlist.txt:101,104` | `tracker.toml.project-example:37-44` `[mirror]`; `tracker.toml.pack-example:50,57-58` | O19 + O25 (+ DR-4 Check-29 flip) — full classification in EE-11 |
  | trinity / docs / skill / prompt / methodology prose | trinity, PM-CHAT, prompts, METHODOLOGY, SKILL masters, MIGRATION, README, PACK-AGENTS, MERGE-STRATEGY | — | — | — | — | — | O14/O15/O16/O17/O18/O21 + O1 doc-ref drops (README:149-154, PACK-AGENTS:213, MERGE-STRATEGY:270 `_format.md` AND `:274-275` project-monolith prose SHOULD-C) |
  | recommendation/detect client reads | `recommendation.sh`, `detect.sh`, `pack-help.sh` | `recommendation-test.sh`, `pack-help-test.sh` | client-tree fixtures | shard | Check 47 set-equality (UNCHANGED) | — | O5/O6 |
- **NEGATIVE controls (grep false positives confirmed OUT):** `test-validate-pack-check-40.sh:645` is a COMMENT ("conversion-input monoliths … NOT regenerated mirrors") — already correct, no edit. `test-validate-pack-check-71.sh` is **skill**-mirror byte-identity (BD-243 Check 71), a different "mirror" concept — no project-mirror surface. Both correctly excluded.
- **Additional surfaces Part-2 found beyond the 9 findings:** (1) `validate-pack.py:5094` PHANTOM pack-side `/backlog/_format.md` ref (folded into O9/O24 STRIP); (2) `test-init-project.sh` Group-5 (4.6) `per_entry_regenerate_mirror` snapshot/re-invocation at `:386-394,416,427` (folded into O4 + the BD-249/EE-8 dead-coverage set); (3) `manifest-inputs.sh:56,58` build.sh-as-manifest-input + the BD-228 Check-62 coupling (folded into O23). **No silent drops.** (FINAL reconciliation note: the complete tracker-family classification — the 4 tracker tests, the live `tracker-init.sh` emitter, and the KEEP-vs-REPOINT disposition of every `[mirror]` fixture — is now enumerated in EE-11; the surfaces folded there beyond the confirmation review's 7 are recorded in EE-11's KEEP/REPOINT table.)
- **Post-fix projected state (verification):** after Wave A (validate-pack 14 cleared + the EXISTING-test inversions + O23 build.sh redesign + O24 Check-43 lock-step) the FULL battery is green; after O7/DR-1 the two-var grep-zero gate is zero; after O22-proj + BD-249 the mirror-subsystem grep-zero gate is zero. A guard RED against the gold or a test RED in its wave is a defect.
- **Conclusion: SUPPORTED for the non-tracker encoding layer; the tracker family is COMPLETED in EE-11.** EE-10's tracker ROW listed only `tracker-init-test.sh`; the confirmation review correctly found 4 further tracker tests + the live emitter encode the same state. The FINAL reconciliation's EXHAUSTIVE tracker-family sweep (EE-11) closes that gap; a fourth reviewer can re-run EE-11's commands to check completeness.

### EE-11 — EXHAUSTIVE tracker-family enumeration (the class-closing sweep; FINAL RECONCILIATION) — measure-then-bound

- **Mandate:** close the under-counted-blast-radius class for good. The class recurred 3× (operational layer → test/fixture layer → tracker-test + Check-29 layer), each time in the tracker family — a large, gated-OFF (BD-214) dormant family that ad-hoc enumeration kept under-sweeping. This block enumerates the WHOLE tracker family and classifies EVERY mirror-encoding surface KEEP vs REPOINT/REMOVE.
- **Method (measure-then-bound):** candidate set from `git ls-files`; graph-first DISCOVERY then `git grep` VERIFICATION over the candidate set. Measured at HEAD `66c8332`, 2026-06-26.
- **Two mirror concepts (rigorously distinguished — the whole class hinges on this):**
  - **(M-mono) per-entry→monolith mirror assumption** = "a v11 client SHIPS a `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` regenerated mirror of the per-entry tree." BD-206 ABOLISHES this. → **REPOINT/REMOVE.**
  - **(M-track) tracker→file read-only mirror feature** (`tracker-mirror.sh`) = when `mode.state="tracker"`, the tracker (GH Issues) is SSOT and a read-only `BACKLOG.md`-with-header is generated FROM the tracker. A SEPARATE feature; gated OFF (BD-214). → **KEEP** (do NOT remove; do NOT activate).
- **Command 1 (candidate set):** `git ls-files 'scripts/lib/tracker-*.sh' 'scripts/tracker-*.sh' 'scripts/pack-tracker.sh' 'scripts/tests/tracker-*.sh' 'scripts/tests/test-tracker-*.sh' '*tracker*.toml*'`
- **Verbatim output:** **52 tracked files** — 18 `scripts/lib/tracker-*.sh`, 1 `scripts/tracker-migrate.sh`, 1 `scripts/pack-tracker.sh`, 16 `scripts/tests/tracker-*-test.sh`, 6 `scripts/tests/test-tracker-*.sh`, 10 `.toml` examples/fixtures (`project-template/tracker.toml.project-example`, `tracker.toml.pack-example`, 5 `scripts/tests/fixtures/tracker-config/*.toml`, 3 roundtrip/migrate fixtures).
- **Command 2 (pattern sweep):** `git grep -nE '\[mirror\]|mirror_required|location_backlog|location_changelog|regenerate_on_write|mirror\.enabled|until BD-206|monolith mirror' -- <the 52-file set>`
- **The complete classified enumeration (every surface that encodes a mirror concept):**

  | # | Surface (file:line) | Concept | Class | Resolved by | Wave |
  |---|---|---|---|---|---|
  | 1 | `validate-pack.py:2790-2796` Check-29 client `mirror_required=True` + `:2492-2497,2571-2573` rationale | M-mono (the validator REQUIRES a client `[mirror]`) | **REPOINT** (flip `mirror_required=True`→`False`; strip "until BD-206" rationale) | O25/DR-4 | **A** |
  | 2 | `project-template/tracker.toml.project-example:37-44` `[mirror]` table | M-mono (ships a client monolith-pointing `[mirror]`) | **REMOVE** (drop the table; matches the pack example's no-`[mirror]` shape) | O25/DR-4 | **A** |
  | 3 | `tracker.toml.pack-example:50,57-58` (":50 NO [mirror] on pack" comment + ":57-58 client keeps until BD-206") | M-mono (deferred-feature narration) | **REPOINT** (`:50` STAYS accurate; STRIP `:57-58` "until BD-206") | O25 | **A** |
  | 4 | `tracker-config-schema-test.sh` Test 7 (`:17-20` header, `:116-131` GOOD_CLIENT `[mirror]`, `:223-242` asserts) | M-mono (PINS `mirror_required=True` for client) | **REPOINT** (invert: client missing `[mirror]` → PASS; strip GOOD_CLIENT `[mirror]`; rewrite header) | O25/DR-4 | **A** |
  | 5 | `tracker-init.sh:359-376` live emitter writes client `[mirror]` block (`location_backlog="BACKLOG.md"` etc.) + `:185-192,318-330` "until BD-206" comments | M-mono (EMITS a client monolith `[mirror]`) | **REPOINT** (drop the client `mirror_block`; emitter writes NO `[mirror]` on the client surface; rewrite comments) | O25 (MUST-B) | **A** |
  | 6 | `tracker-init-test.sh:14-16,256-283,296-302` (3.5 asserts the EMITTED client `[mirror]`) | M-mono (asserts the emitter's client `[mirror]`) | **REPOINT** (invert 3.5: client init OMITS `[mirror]`; rewrite "until BD-206" comments) | O25 (MUST-B) | **A** |
  | 7 | `tracker-agent-read.sh:251-278` TD-*/phase-* fallback to `docs/project/{BACKLOG,IMPLEMENTATION-PLAN}.md` + `:7,255-263` comments | M-mono (reads the client monolith on fallback) | **REPOINT** (fallback reads the project per-entry tree; or keep a mid-migration monolith-INPUT fallback per O19's disposition) | O19 | **E** |
  | 8 | `tracker-agent-read-test.sh:34-78` (`:71` seeds ONLY `docs/project/BACKLOG.md`) + `:190-192` (2.3 asserts the read) | M-mono (fixture seeds the monolith) | **REPOINT** (seed the project per-entry tree; or assert the mid-migration INPUT path per O19) | O19 (MUST-A) | **E** |
  | 9 | `tracker-doctor.sh:120-200` (`:173-174` probes `docs/project/BACKLOG.md`) + `:128` comment | M-mono (doctor probes the client monolith for staleness) | **REPOINT** (the project no-mirror state; align the staleness probe + comment to no-mirror) | O19 | **E** |
  | 10 | `tracker-migrate-forward.sh:1387-1432,2142-2172` (`:1395` "clients still ship a BACKLOG.md monolith mirror"; `:2149-2150,2162` reads client `BACKLOG.md`) | M-mono in the dormant fwd path | **REPOINT** (stale-comment fix + repoint the client read to the per-entry tree where it READS for TD content) | O19 | **E** |
  | 11 | `tracker-migrate-reverse.sh:1604-1612` emits client `BACKLOG.md`/`IMPLEMENTATION-PLAN.md`/`CHANGELOG.md` | M-track (reverse EMITS the tracker→file read-only mirror when DISABLING tracker) | **KEEP** (this is the M-track reverse-emit, not the M-mono assumption — emitting on `disable` is the tracker→file feature) | n/a (KEEP) | — |
  | 12 | `tracker-mirror.sh:1-85` read-only mirror header write/strip | M-track (the feature itself) | **KEEP** (the explicit BD-206.md KEEP — tracker→file read-only mirror) | n/a (KEEP) | — |
  | 13 | `tracker-header-snapshot.sh` (BACKLOG.md preamble snapshot/apply) | M-track (preserves a user preamble across tracker reverse-emit) | **KEEP** (tracker-mode reverse-emit helper, not the M-mono assumption) | n/a (KEEP) | — |
  | 14 | `tracker-promote.sh:251-271,463-624,915-923,1306-1360` reads/appends client `BACKLOG.md`/`IMPLEMENTATION-PLAN.md` (with `docs/project/` fallback) | M-mono in the dormant promote path | **REPOINT** (where it READS/WRITES the project monolith for TD/phase content, repoint to the per-entry tree) | O19 | **E** |
  | 15 | `tracker-phase-task.sh:7,24,140,487` parses/emits `IMPLEMENTATION-PLAN.md` fragments | M-mono in the dormant phase-task path | **REPOINT** (repoint the project plan READ/EMIT to the per-entry tree) | O19 | **E** |
  | 16 | `scripts/tracker-migrate.sh`, `scripts/pack-tracker.sh:104` (verb wrappers; STATUS/IMPLEMENTATION-PLAN refs) | mixed (pack `pack-tracker.sh` writes the PACK plan stream) | `pack-tracker.sh` = PACK-side, OUT of BD-206 (per §4 verifications); `tracker-migrate.sh` repoints any project-monolith READ | O19 (project share) | **E** |
  | 17 | `scripts/tests/fixtures/tracker-config/{tracker-mode,flat-file-mode,not-yet-migrated}.toml` `[mirror]` tables | M-track (`mode.state="tracker"`/staleness-test fixtures) | **KEEP** (tracker-mode parse/staleness fixtures for Check-29′ — the M-track feature; NOT the client-example M-mono) | n/a (KEEP) | — |
  | 18 | `tracker-config-test.sh:73` `1.5 read tracker-mode mirror.enabled` (reads `tracker-mode.toml`) | M-track (parser maps `[mirror].enabled` in tracker-mode context) | **KEEP / NO-BREAK** (`tracker-config.sh` is a pure TOML parser; the assert verifies the parse, not the M-mono semantics; tracker-mode fixture) | n/a (KEEP) — SHOULD-D | — |
  | 19 | `tracker-config-schema-test.sh` Tests 15/16/17 (`:448-558`; live tracker-mode + pack `[mirror]` cases) | M-track (Check-29′ no-mirror-surface guard + pack-`[mirror]` malformed cases) | **KEEP / NO-BREAK** (these exercise the M-track staleness guard + the pack optional-`[mirror]`; unaffected by the client-example flip) | n/a (KEEP) | — |
  | 20 | `tracker-migrate-forward.sh:1992-2253`, `tracker-migrate-reverse.sh:999-1232`, the `roundtrip`/`tracker-migrate` `.toml` + `BACKLOG.md`/`IMPLEMENTATION-PLAN.md` fixtures | M-track / v10-INPUT (forward parses a v10 BACKLOG.md INPUT; reverse emits the M-track mirror) | **KEEP** (forward READS a v10-shape monolith INPUT — a legitimate migration INPUT, NOT a v11 mirror; reverse EMITS the M-track feature) | n/a (KEEP) | — |
  | 21 | `pack-ops/.dangling-ref-allowlist.txt:101,104` (`docs/project/BACKLOG.md`/`CHANGELOG.md` "regenerated ... mirror" tokens) | M-mono (validator allowlist for project-monolith prose refs) | **REMOVE** (the project-monolith prose refs go with O1/O14/O15/O16/O17/O21; size the allowlist to the post-fix legitimate set) | O26 (SHOULD-A) | **A** (with O26) |

- **KEEP/REPOINT/REMOVE tallies:** of 21 mirror-encoding surfaces — **REPOINT = 11** (rows 1,3-10,14,15 — M-mono dormant assumptions repointed), **REMOVE = 2** (rows 2,21 — the client `[mirror]` table + the dangling-ref tokens deleted), **KEEP = 7** (rows 11-13,17-20 — M-track feature / v10-INPUT / pure-parse), **MIXED = 1** (row 16 — `pack-tracker.sh` PACK-side OUT-of-BD-206 + `tracker-migrate.sh` project share REPOINT). So REPOINT/REMOVE (M-mono) = **13**; KEEP (M-track) = **7**; mixed = **1**. Tracker-family tracked files swept = **52**; mirror-encoding surfaces classified = **21**.
- **Surfaces BEYOND the confirmation review's 7 findings (folded in, NOT dropped):** the review named 7 (BLOCKER-A row 4; MUST-A rows 7-8; MUST-B rows 5-6; SHOULD-A row 21; SHOULD-B → EE-10 build.sh row; SHOULD-C → O1 doc-ref; SHOULD-D row 18). The sweep ADDED, beyond those: (a) row 9 `tracker-doctor.sh:173-174` client-monolith staleness probe; (b) row 10 `tracker-migrate-forward.sh:1395,2149-2162` "clients still ship a BACKLOG.md monolith mirror" + the client read; (c) row 14 `tracker-promote.sh` project-monolith read/append paths; (d) row 15 `tracker-phase-task.sh` project-plan parse/emit; (e) row 16 `scripts/tracker-migrate.sh` project share. All five are M-mono dormant paths → REPOINT under O19 (Wave E). **No fourth surface remains unclassified.**
- **NEGATIVE controls (confirmed KEEP, NOT a defect):** rows 11-13, 17-20 are the M-track feature or v10-INPUT migration — preserving them is the binding KEEP (BD-206.md names "tracker-mirror.sh" + "tracker→file read-only mirror" as KEEP). Removing them would DELETE the dormant tracker feature, which is OUT of scope (BD-214 keeps the feature dormant, not deleted).
- **Post-fix projected state (verification):** after Wave A, the FULL battery (incl. `tracker-config-schema-test.sh` + `tracker-init-test.sh`) is green with the Check-29 flip + the client `[mirror]` drop + the emitter drop landing together. After O19 (Wave E), the dormant `tracker-*.sh` family carries no M-mono assumption AND `tracker-agent-read-test.sh`/`tracker-doctor`/`tracker-promote`/`tracker-phase-task` tests are green lock-step. The M-track feature surfaces (KEEP rows) are UNTOUCHED. `git grep -nE 'until BD-206' -- <the 52 files> validate-pack.py` reaches grep-ZERO post-O19/O25.
- **Conclusion: SUPPORTED.** The tracker family is now EXHAUSTIVELY enumerated and KEEP/REPOINT-classified; the under-counted-blast-radius class is CLOSED for the tracker layer. A fourth reviewer re-running Command 1 + Command 2 finds the same 52-file candidate set and the same 21 classified surfaces.


---

## 3. The schema (derived from V2 GOLD + v11 standards; v10 anchoring FORBIDDEN)

The schema lives in `_rules.md` as the single machine-parseable SSOT (Item-8). It is declared in
a deterministic, minimal `key: tokens` grammar (G-6) under named H2 sections, parsed at runtime by
BOTH validators (the precedent is `pe_supporting_files_admitted`, EE-5).

### 3.1 Sanctioned sidecar vocabulary (immutable; FORBIDDEN set enforced)

`{ _rules.md, _intro.md, _toc.md, _index.md(optional) }`. `_format.md` and `_scaffolding.md` are
FORBIDDEN in EVERY tree. Stream→sidecar matrix:

| Stream | `_rules.md` | `_intro.md` | `_toc.md` | `_index.md` |
|---|---|---|---|---|
| backlog | yes | yes | yes (generated) | **no** (unordered — the tripwire) |
| implementation-plan | yes | yes | yes (generated) | **yes** (ordering, generated+validated) |
| changelog | yes | yes | yes (generated) | no (date-ordered; recoverable from filenames) |

- `_rules.md` = operational contract; pack-set; **immutable** (G-10 force-overwrite to canonical on re-run).
- `_intro.md` = human-only orientation; per-project modifiable; **agents/PM Chat never read it**; carries ZERO rules.
- `_toc.md` = generated readable index of the tree (the sole readable monolith-replacement).
- `_index.md` = generated+validated dependency-derived serial order (impl-plan only).

**Tripwire check (§3 ledger):** impl-plan gets `_index.md`; backlog gets none. A design that gives
backlog an `_index.md` or omits it from impl-plan is wrong.

### 3.2 Backlog form family (REQUIRED + enforced)

Per-entry FILE: `^TD-\d+\.md$`. **Internal anchor = bold-pair** `**TD-NNN — Title**` (G-5 (B):
tracker-safe — the dormant carrier regex `tracker-migrate-forward.sh` `ENTRY_HEADER` is bold-pair;
H4 does not match it). The splitter ACCEPTS H4 input (`#### TD-NNN —`, the gold) AND bold-pair, and
EMITS bold-pair (G-4 superset, normalize-at-emit).

Field grammar declared in `backlog/_rules.md`:

```
## Entry schema (form-family)
- entry-type: td
- core-fields: ID Marker Status Blockers Unblocks File/Symbol Description Context
- marker-enum: TODO "KNOWN GAP" VERIFY
- payload-by-marker: TODO=Scope "KNOWN GAP"=Severity VERIFY=Verify-Source
- scope-enum: phase-N dependency feature perf version
- severity-enum: critical functional polish
- verify-source: open-string
- status-enum: Open Unblocked Deferred Resolved Deprecated Cancelled
- resolved-requires: Resolution
- title-template: phase-N
```

Notes:
- `scope-enum` includes `perf` + `version` (live cross-surface vocabulary per §13 Item-1) though
  the gold uses only `{dependency, feature, phase-N}`; `phase-N` is a TEMPLATED pattern `phase-\d+`,
  not a literal token — the validator matches `^phase-\d+$` OR a literal enum member.
- `severity-enum` is bounded to the gold-observed `{critical, functional, polish}` (measure-then-bound,
  EE-1); a future severity needs a one-line `_rules.md` edit (the SSOT), not a code change.
- `verify-source` is PRESENCE-checked open-string (§13 Item-2), not enum-validated.
- The enforcement validates, per `td` entry: Entry-Type present + correct; all core-fields present;
  Marker ∈ marker-enum; the Marker-keyed payload field present + (for Scope/Severity) enum-valid;
  Status ∈ status-enum; Resolution present iff Status=Resolved.

### 3.3 Implementation-plan form family (REQUIRED + enforced)

Per-entry FILE: `^phase-\d+\.md$` (one phase-epic per file; its parts INLINE for BD-206, §3.5).
Entry discriminator = `Entry-Type ∈ {phase-epic, phase-part}`.

Field grammar declared in `implementation-plan/_rules.md`:

```
## Entry schema (form-family)
- entry-types: phase-epic phase-part
- phase-epic-fields: ID Status Blockers Unblocks Goal Prerequisite
- phase-part-fields: (none required beyond Entry-Type)   # lightweight, §13 Item-3 (a)
- phase-epic-id-template: phase-N
- status-enum: done in-progress not-started blocked deferred superseded
- body-sections: Tasks Verification Agent Risks   # presence-tolerant, not required
- extension-fields-admitted: "Execution order" Superseded-By Merged-Into "Critical distinction"
```

Notes:
- phase-epic Status enum is bounded to the gold-observed values (EE-2 showed `done`; the full set
  is the lifecycle vocabulary — the validator parses it from the SSOT, not hardcoded).
- phase-part is LIGHTWEIGHT (Entry-Type only) — no per-part field-richness enforcement in BD-206
  (that is BD-185). The validator MUST tolerate inline parts gracefully (§13 Item-3 last clause).
- `body-sections` are admitted/recognized, not mandated (the gold varies; over-mandating would
  reject valid entries — measure-then-bound).

### 3.4 Changelog structure (STRUCTURED, NOT form-family) + size caps

Per-entry FILE: `^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$` (date-slug; the existing changelog filename
convention). Internal anchor = H3 `### YYYY-MM-DD — [Phase N — | Architecture Iteration — | ]Title`
(the gold shape, EE-3). NO Entry-Type/Marker/Scope/Severity (§4 stands — changelog is the flexible stream).

Field grammar declared in `changelog/_rules.md` (the rewritten `_format.md` content + the structure):

```
## Entry structure (structured, not form-family)
- core-fields: Summary "Test count" Files          # Files = any "Files <verb>" label (modified|created|deleted|renamed)
- core-required-when: code-bearing                  # G-2 core set
- doc-only-exemption: zero-test-and-zero-files OR heading-class=doc   # Summary-only allowed
- extras: admitted                                  # ~30 one-off labels allowed (Sections updated, Build warnings, …)
- entry-max-lines: 180                              # G-2b gold-safe (gold max 130)
- summary-max-words: 250                            # G-2b gold-safe (gold max 243)
```

Notes:
- The `Files` core field is satisfied by ANY `**Files <verb>**:` label (the gold uses
  `Files modified`/`Files created`/`Files deleted`/`Files renamed`, several with a `(N)` count
  suffix) — the validator matches `^\*\*Files [a-z]+( \(\d+\))?\*\*:`.
- DOC-ONLY exemption is machine-checkable: an entry with zero `Test count` AND zero `Files` fields
  is Summary-only-valid (the gold's `## v8 Migration`-class entries).
- Size caps are cheap deterministic line/word counts; independent of the doc-only exemption.

### 3.5 Phase parts — INLINE for BD-206 (adopt-as-body) + graceful naming guard

§13 Item-3: parts stay INLINE in `phase-N.md` (the gold already does this — `### Phase-N.Part-x`
+ `#### Phase-N.Part-x.Task-k`). BD-206 adds a MINIMAL, GRACEFUL naming-conformance guard (O13):
codify the EXISTING convention as a FORMAT check — NOT a structural per-file migration (that is BD-185).

The guard (design): within a `phase-N.md`, any H3 matching `^### Phase-` MUST match
`^### Phase-\d+\.Part-[a-z] — ` and any H4 under it matching `^#### Phase-` MUST match
`^#### Phase-\d+\.Part-[a-z]\.Task-\d+ — `. The H4 task anchors directly under `### Tasks` (epic
tasks) match `^#### \d+\.\d+ — `. The guard is GRACEFUL: it only fires on a Phase-prefixed heading
that violates the template; it does NOT require parts to exist, does NOT force a refactor, and does
NOT store an execution-order marker. The OT gold conforms (EE-2) → zero violations on the gold.

### 3.6 Non-entry monolith content — classification (Item-4 + G-1)

Applying the Item-4 test to the gold's non-entry sections:
- Backlog gold preamble (`# OptiquityTrader — Backlog` + the "known issues…" blurb) → `_intro.md`.
- Impl-plan `## Codebase Snapshot`, `## Cross-Phase Notes` → `_intro.md` (human orientation).
- Impl-plan `## Phase Completion Checklist` + `## Updated Phase Completion Checklist` → **DROP** (G-1:
  manual mutating dashboards whose function already ships via per-entry `Status` + `STATUS.md` +
  `_index.md`). **PRESERVED:** the `### Execution order` lines are captured into `_index.md` (Item-5/G-3),
  not lost.
- Changelog `## Format Rules` → the rules become the `changelog/_rules.md` `## Entry structure`
  section (Item-4: process rules → `_rules.md`); the H3-grammar examples are dropped (header-only-useful).
- Any monolith section that is a RULE but project-specific → ESCALATE (none found in the gold beyond
  the above; the migrator surfaces any unclassified `## ` as a warning per O7).


---

## 4. Deliverables (O0–O26)

Each deliverable lists: the surface(s), the census record it discharges, the lock-step encoding
surfaces (`enumerate-encoding-surfaces`), and the action. Wave assignment is in §6. **Reconciliation
added O23 (build.sh round-trip), O24 (Check-43 fixtures/test lock-step), O25 (tracker.toml examples
+ Check 29), O26 (operating-doc allowlists); revised O1/O3/O4/O7/O8/O9/O11/O19/O22.** O22 splits:
**O22-proj** stays in BD-206; **O22-pack is BD-249** (separate BD).

### O0 — Sidecar generation in the migrator-feed splitter (the gap §7 of the ledger asked about)
**Census:** §1.4 decompose (sidecar production), §7 migrator-feed Q3.
**Finding:** the migrator splits entries (decompose) but the SIDECAR-content production was NOT a
designed step — it is a GAP (answering the ledger's open Q3 question). The current model copies
hand-authored sidecars from `project-template/` at install (`init-project.sh` S11); the migrator
decompose does NOT generate `_rules.md`/`_intro.md` (it installs them via `decompose.sh:137`).
**Design:** `_rules.md` is pack-canonical (immutable, identical for every project) → it is COPIED
from `project-template/`, never generated per-project (§3.1; G-10 force-overwrite on re-run).
`_intro.md` is seeded from the classified non-entry monolith content (§3.6) at migration, else the
pack-shipped stub at greenfield. `_toc.md` + `_index.md` are GENERATED (O8/O11). So "sidecar-content
production" = COPY (`_rules.md`) + SEED-or-stub (`_intro.md`) + GENERATE (`_toc.md`/`_index.md`).
This is a clarified migrator sub-operation (reusable), NOT new monolith machinery.

### O1 — Sidecar vocabulary + tree shape (the 4-sidecar model) — REVISED (MUST-4 + BLOCKER-3)
**Census:** §11 measured facts; §1 ledger; EE-6 (re-measured); EE-10.
**Action:** establish the sanctioned vocabulary `{_rules,_intro,_toc,_index(opt)}` as the shape the
template ships and the validators enforce; FORBID `_format.md`/`_scaffolding.md` everywhere.
**`_lib.sh` support-set lock-step (TWO edits):** (a) DROP `_format.md` from the `project-changelog`
`support)` branch (`_lib.sh:136`); (b) **ADD `_index.md` to the `project-implementation-plan`
`support)` branch (`_lib.sh:123`)** so `pe_supporting_files_admitted`/`_known_for_stream` admit the
new sanctioned sidecar (MUST-4) — without it, the O9/O10 "no stray sidecar" legs would flag a
generated `_index.md` as stray. (NOTE: `_index.md` is GENERATED like `_toc.md`; it is added to the
ADMISSION set so it is KNOWN-supporting, exactly as `_toc.md` is in the set.)
**Doc-ref lock-step (drop `_format.md`):** README diagram `149-154`, `PACK-AGENTS.md:213`,
`MERGE-STRATEGY.md:270` (`_format.md`).
**Doc-ref lock-step (project-monolith prose, SHOULD-C):** `MERGE-STRATEGY.md:274-275` describes the
`docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` files as "regenerated mirrors of the per-entry
trees ... the migrator overwrites them ... NOT authoritative edit targets." Under no-mirror this prose is
FALSE. **CLASSIFY:** this is LIVE project-side merge-dispatch operating-doc prose (the `generic` 3-way
dispatch + the project no-mirror SSOT) that BD-206 invalidates — it is NOT pack-side dead-mirror (that is
BD-249) and NOT historical audit text → **IN-SCOPE for BD-206**, same family as the `:270` `_format.md`
ref. **Action:** rewrite `:267-280` so the per-entry trees route through `generic` dispatch as flat-file
SSOT and the monolith-mirror paragraph is REMOVED (no regenerated project mirror exists). Lands with O1
in Wave A (doc share).
**Test lock-step (BLOCKER-3 / EE-9 — these EXISTING tests FLIP, land WITH O1 in Wave A):**
`test-per-entry.sh:231-232` (invert: `_format.md` ABSENT from support-set; ADD a `_index.md`
admitted assert for impl-plan); `test-init-project.sh:246-268` (4.2 — invert changelog `_format.md`
to ABSENT); `contract-greenfield.sh:212,231,239` + `contract-migration.sh:422,458,471` (drop the
`_format.md` array entry + asymmetry comments); `test-v11-realistic-ot.sh:143,172,183-188` (A.13 →
absent). The Check-43 allowlist + PASS-fixture share is O24.
### O2 — Rebuild `_intro.md` (3 streams) — human-only, modifiable
**Census:** Q1/Q3 INVESTIGATION (current `_intro.md` is an INVERTED do-not-edit mirror).
**Action:** author 3 NEW `_intro.md` (backlog/impl-plan/changelog) as human-only orientation,
per-project modifiable, ZERO rules, NO mirror header. Greenfield = stream-header stub.
**Derivation:** from the corrected model (§1 ledger), NOT the old files.

### O3 — Rebuild `_rules.md` (3 streams) — operational contract + machine-parseable schema SSOT — REVISED (MUST-3)
**Census:** Q1/Q3/Q5 INVESTIGATION; §1/§5 ledger; Item-8; EE-10.
**Action:** author 3 NEW `_rules.md` carrying: stream identity; filename convention; the no-mirror
SSOT clause (model on pack `backlog/_rules.md` `## Source of truth — flat-file`); the `## Supporting
files` list (the `pe_supporting_files_admitted` contract — backlog/changelog `{_rules,_intro,_toc}`,
impl-plan `{_rules,_intro,_toc,_index}`; NO `_format.md`); the `## Entry schema` block (§3.2/§3.3)
for backlog+impl-plan; the `## Entry structure` block (§3.4, incl. the folded `_format.md` content)
for changelog; lifecycle states; write authority. DECLARED immutable (G-10).
**Derivation:** corrected requirements + V2 gold schema (EE-1/EE-2) + production changelog (EE-3) —
NEVER the old files (contaminated, M1/M5 INVESTIGATION).
**Operating-docs rule:** `_rules.md` is an operating doc → ZERO history/audit text, ZERO
deferred-feature mentions, terse + structured (no "until BD-NNN" except live in-flight pointers).
**Operating-doc allowlist lock-step (MUST-3 — `validate-pack.py:8224` globs `*/_rules.md`, so the
rebuilt files ARE operating-doc-checked):** the two allowlists carry line-anchored exemptions that
reference the OLD sidecar content — `pack-ops/.operating-doc-history-allowlist.txt:157`
(`changelog/_rules.md`, snippet `2026-04-20`) + `.operating-doc-deferred-feature-allowlist.txt:423`
(`implementation-plan/_rules.md`). Because the rebuilt `_rules.md` carries ZERO history + ZERO
deferred-feature text (operating-docs rule), these exemptions become DEAD and MUST be removed in
lock-step (O26). The `_format.md`-anchored exemptions (history `145,150`; deferred `419`) are
removed by O26 with the `_format.md` elimination. **Constraint:** the rebuilt `_rules.md` MUST NOT
introduce ANY date/`until BD-NNN`/deferred-feature text, else the operating-doc check fails with no
exemption — author clean (the allowlist shrinks to zero project-`_rules.md` entries; verify the
operating-doc check passes against the rebuilt files with the trimmed allowlists). Lock-step: O26.
### O4 — DELETE the project monoliths + ship NO mirror (the core conversion) — REVISED (EE-9)
**Census:** §1.1 init greenfield generation (1084-1121), §1.3 mirror-generate, §1.4 decompose regenerate; EE-9.
**Action:** stop generating `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`. Same treatment
as BD-203 (pack side). The per-entry tree + generated `_toc.md` is the sole SSOT + readable form.
- `init-project.sh`: remove the `per_entry_regenerate_mirror` sourcing (1084-1086) + the greenfield
  empty-mirror loop (1109-1114); drop the mirror middle-field consumption from the install tuples
  (1098-1101, keep stream-dir); fix the info string (1121) + comment (1053).
- `decompose.sh`: keep reading the v10 monolith INPUT (146-148, 162 KEEP); remove the regenerate-mirror
  step (93-95 sourcing, 195-197); fix header (4) + comment (47).
**Test lock-step (EE-9 — land WITH O4 in Wave A):** `test-init-project.sh:272-280` (4.3 — invert to
the 3 monoliths ABSENT at parent); `:297,302,332` (4.4/4.5 — DELETE the mirror byte-identity asserts);
`:386-394` (Group-5 4.6 — drop the 3 mirror rows from the regen-output snapshot set) + `:416,427`
(Group-5 sources `mirror-generate.sh` + calls `per_entry_regenerate_mirror`; the regen-mirror leg is
removed here, the TOC-regen leg STAYS); `contract-greenfield.sh:240-244` (drop the 3 monoliths from
the expected-files array; keep the tree + `_toc.md` asserts).
**Lock-step:** persona contracts (§1.9); O7 carries the migration-test inversions (2.2a/b/c, Group B).
### O5 — Complete the dual-use `detect.sh`/`pack-help.sh` client-surface repoint (M3: in-scope, NOT deferrable)
**Census:** §1.6 detect.sh client branch (66-72), §1.7 pack-help.sh.
**Finding (M3):** GAP-1 is launch-coherence, NOT an audit line. With the client monolith gone, the
client-surface detection (`grep '^\*\*TD-[0-9]+ ' docs/project/BACKLOG.md`) breaks.
**Design:** add a client-surface per-entry probe PARALLEL to the existing pack-surface probe (detect.sh
56-65): probe `$target/docs/project/backlog/` for a `^TD-\d+\.md$` entry file ⇒ `td_seen=1`. Keep the
legacy-monolith probe as a pre-v11 fallback (a client mid-migration may still have the monolith INPUT)
inside the `DENY-LIST-CONTENT` markers. **`_SANCTIONED_PACK_SIDE_SHIPPED` + install map UNCHANGED**
(Check 47 set-equality preserved — this is a within-file conditional, adds no install entry).
**pack-help.sh** inherits correctness from detect.sh (no independent monolith read; verified §1.7).
**Lock-step:** Check 40 polices the `DENY-LIST-CONTENT` region — the new probe lives OUTSIDE those
markers (pack-surface style) so Check 40 is unaffected; the legacy probe stays inside.
**Tests (O5b):** `pack-help-test.sh` re-run green; add a detect.sh client-tree-probe assertion.
### O6 — Repoint `recommendation.sh` to the per-entry tree (M2: full blast radius)
**Census:** §1.8 recommendation.sh (166-188, 415).
**Finding (M2):** the census now includes `recommendation.sh:166-185` — the client-signal computation
reads the monolith for TD/phase counts + KB. After no-mirror the monolith vanishes.
**Design:** recompute signals from the tree: `td_total` = count of `docs/project/backlog/TD-*.md`;
`backlog_kb` = summed bytes of those files; `phase_count` = count of `docs/project/implementation-plan/
phase-*.md`; `plan_kb` = summed bytes. Relabel the `implementation_plan_kb` signal string (415).
**Lock-step:** `recommendation-test.sh` (§2.5) fixtures must seed a per-entry tree, not a monolith.
### O7 — Migrator overhaul: decompose emits tree+TOC (no mirror) + clean the divergence-gate (G-8/DR-1) — REVISED (MUST-2, EE-9)
**Census:** §1.3/§1.4/§1.5; EE-7 (re-measured, TWO vars).
**Action:** see O4 for the decompose regenerate removal. PLUS DR-1 (the G-8 ripple) — remove the
divergence-gate across BOTH force-overwrite vars:
- `_MIGRATOR_FORCE_OVERWRITE_MIRROR` (the migrator-framework flag): `migrator-core.sh` flag/parser/
  help/default + `:326` comment, the `decompose.sh` bridge (the `_MIGRATOR_*` → `PE_*` export at
  `:27,57,117,120,125`), the `migrate-v10-to-v11.sh` flag wiring, and the Group-4 resume/intercept
  tests (`test-migrate-v10-to-v11-decompose.sh` Group 4).
- `PE_FORCE_OVERWRITE_MIRROR` (the per-entry-layer bypass): the `mirror-generate.sh:40,251,253,288,342`
  consumers (removed with the FILE by BD-249/O22-pack — O7 need not edit them if BD-249 deletes the
  file; the planner sequences BD-249 after O7 so the deletion is terminal), and the `build.sh:496,552,555`
  consumers (handled by O23's round-trip redesign).
It is a `_MIGRATOR_*` core-internal var (NOT the frozen `MIGRATOR_*` surface) — the frozen contract is
untouched.
**Migration-test lock-step (EE-9 — land WITH O7 in its wave):** `test-migrate-v10-to-v11-decompose.sh:300-307`
(2.2a/b/c — invert to NO regenerated mirror); `test-v11-realistic-ot.sh:236-241,287` (Group B — DELETE
the mirror byte-identity asserts); `contract-migration.sh:475` (align the mirror+`_toc` comment to no-mirror).
**grep-zero gate (DR-1, TWO patterns):** after the removal, `git grep -nE '_MIGRATOR_FORCE_OVERWRITE_MIRROR|PE_FORCE_OVERWRITE_MIRROR|force-overwrite-mirror' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'`
MUST reach ZERO (jointly across O7 + O23 + BD-249).
**File-fate of `mirror-generate.sh`/`_lib.sh` mirror constants:** see DR-2 (§5) — project constants =
O22-proj (BD-206); the FILE deletion + pack constants = BD-249.
### O8 — `init-project.sh` Wave-A atomic install fix (the foundational FULL-BATTERY-green commit) — REVISED (BLOCKER-1, EE-9)
**Census:** §1.1; EE-4; EE-9; §15 binding requirement.
**Action (ATOMIC, ONE commit):** (a) ship the rebuilt 6 sidecars (O2+O3) + eliminate `_format.md`
(O1); (b) update `_CLIENT_INSTALLED_FILES` (init-project.sh 1268-1274 + self-doc 1415-1421): keep the
6 rebuilt sidecar rows, DELETE the 2 `_format.md` rows; (c) update `cmd_update` (the S11 copy block):
drop the `_format.md` copy + canonical-missing guard; (d) the S11 install no longer regenerates
mirrors (O4). This clears all 14 Check 39/41 failures (EE-4). NEVER push a bare sidecar deletion.
**ATOMICITY RE-GROUNDED (BLOCKER-1):** Wave-A green is measured against the FULL CI battery
(validate-pack.py + `test-fixtures/build.sh` + the shell shard battery), NOT validate-pack alone. The
atomic Wave-A commit therefore ALSO carries the EE-9 EXISTING-test inversions for O1/O4 + the O23
build.sh redesign + the O24 Check-43 lock-step (all the surfaces that go RED the instant the template/
support-set/mirror-generation change). The commit is large; large-but-green satisfies §15, small-but-red
does not. The Wave-A composition is enumerated in §6.
### O9 — Pack-side Python validator leg (validate-pack.py; Item-7 (c) part 1) — REVISED (BLOCKER-3)
**Census:** §2.1; validate-pack STREAMS scope note (:300-313); Item-7; EE-6/EE-10.
**Action:** add a NEW validate-pack leg that validates the SHIPPED EMPTY `project-template/docs/project/`
template: correct sidecar vocabulary present (no `_format.md`, no monolith, no stray sidecar);
`_rules.md` parses + declares a well-formed schema block. The template is EMPTY so the leg validates
the TEMPLATE SHAPE + the schema-block well-formedness, NOT entries. The leg ADMITS `_index.md` for the
impl-plan stream (MUST-4 parity with the `_lib.sh:123` admission).
**Schema-read:** the Python leg PARSES `_rules.md`'s schema block (Item-8; the parity parser to the
bash awk, G-6) — no hardcoded schema duplicate.
**Check 43 lock-step (BLOCKER-3 — three `_format.md`/mirror surfaces, DR-3):**
- `:5503` `"_format.md": "Per-entry tree format sibling …"` — STRIP (the `_format.md` sibling allowlist;
  no `_format.md` exists anywhere post-O1).
- `:5504-5507` + `:5590-5593` the 3 monolith-basename mirror-rationale allowlist + prose — STRIP the
  mirror rationale; classify the basenames KEEP-as-conversion-input vs STRIP per DR-3 (measure-then-bound).
- `:5094` `"BD-NNN.md": "… (template; see /backlog/_format.md)"` — STRIP the `(see /backlog/_format.md)`
  parenthetical (PHANTOM: pack `backlog/_format.md` does NOT exist; EE-6/EE-10).
- `:8225` `"project-template/docs/project/changelog/_format.md"` in `_CHECK_OPERATING_DOC` family-glob
  set — REMOVE (the file is gone; the `*/_rules.md` glob at `:8224` STAYS and now covers the rebuilt
  changelog `_rules.md` which carries the folded format section).
**Test lock-step:** O24 carries `test-validate-pack-check-43.sh` (the required-set `:133-138` + the T9
PASS fixture `:481-494` + the 2 project-side-refs skeleton fixtures) — they move WITH O9 in the same wave.
### O10 — Client-side bash validator leg (validate-docs.sh; Item-7 (c) part 2)
**Census:** §3.6; Item-7.
**Action:** extend `validate-docs.sh` (the client-shipped bash validator) to validate a POPULATED
client project: per-entry schema conformance (form-family for backlog+impl-plan, structured for
changelog), no reintroduced monolith mirror, correct sidecar vocabulary. PARSES the SAME `_rules.md`
schema block (the awk parser, EE-5) — the Python (O9) + bash (O10) legs cannot diverge on the schema
(only the parser is written twice, Item-8 drift mitigation).
**Lock-step:** drop `validate-docs.sh:88` `_format.md` ref + the exclude-category comments (9, 24-25,
319); drop the `.docs-gate-allowlist.txt` mirror entries (393-397) + `_format.md` lines (97-112).
### O11 — `_index.md` (impl-plan) generation + MANDATORY validation script (G-3) — REVISED (MUST-4)
**Census:** §1 ledger ADD; Item-5; G-3; EE-10.
**Action:** `_index.md` stores the dependency-derived serial sort of phase entries (derive-seed-then-
hand-maintain, G-3 (A)). Generation: derive a topological seed from each phase file's `Blockers`/
`Unblocks`/`Dependencies` SSOT (deps stay SSOT in the entry files — `_index.md` is NOT a competing
source). A MANDATORY validation script (joins the conformance enforcement, both repos) enforces TWO
hard properties: (1) hard-dependency-order consistency (the serial order is a valid topological order
of the rule-based deps); (2) per-entry↔`_index.md` membership sync (no missing/extra — analogous to
the `_toc.md`-sync Check 33). Parallelization is RUNTIME, never stored (Item-5).
**Admission lock-step (MUST-4):** `_index.md` MUST be added to the `project-implementation-plan`
support-set (`_lib.sh:123`, carried by O1) so `pe_supporting_files_admitted` treats it as
KNOWN-supporting (not stray); O9/O10's "no stray sidecar" legs read the SAME admission set. Add a
`test-per-entry.sh` assert that the impl-plan support-set includes `_index.md` (O1's test lock-step).
**Preserved from G-1:** the gold's `### Execution order` lines seed `_index.md`'s order.
### O12 — Changelog conformance check (structured; G-2/G-2b)
**Census:** §3.4; Item-6; G-2/G-2b.
**Action:** a conformance check (both repos, parses the changelog `_rules.md` `## Entry structure`
block) validating per code-bearing entry: core `{Summary + Test count + ≥1 Files field}` present;
doc-only exemption (Summary-only) when zero-test-zero-files; `entry-max-lines ≤ 180`;
`summary-max-words ≤ 250`. Cheap deterministic counts (CI-runtime-compounding aware).
**Lock-step:** its tests; the `_rules.md` SSOT (O3).

### O13 — Graceful phase/part/task naming-conformance guard (§13 Item-3)
**Census:** §13 Item-3 minimal v11.0 guard.
**Action:** the §3.5 guard (a FORMAT check, not a structural migration). Fires only on a Phase-prefixed
heading violating the template; no forced refactor; no stored execution-order marker. Tolerates inline
parts gracefully. Joins the impl-plan conformance enforcement (both repos).
**Boundary (BD-206-minimal vs BD-185-full):** BD-206 = naming/format conformance of the EXISTING inline
convention. BD-185 = per-part-file migration + part-membership/serializability drift enforcement.


### O14 — `METHODOLOGY.md` wholesale plan-model rewrite (newest binding decision)
**Census:** §4.2 (24 IMPLEMENTATION-PLAN refs, AMBIGUOUS→now in-scope by user direction); SS-2.
**Finding:** METHODOLOGY models `IMPLEMENTATION-PLAN.md` as the canonical, hand-authored, source-of-truth
plan doc — a model DEEPER than "regenerated mirror" (it predates per-entry). The newest binding decision
(2026-06-26) makes the plan-workflow rewrite WHOLESALE, not just the mirror clauses.
**Design:** rewrite METHODOLOGY's plan workflow so the plan SSOT = the `phase-N.md` per-entry tree +
`_index.md` (ordering), NOT a monolith. Every "generate/modify/read IMPLEMENTATION-PLAN.md" instruction
repoints to the per-entry plan stream (author a `phase-N.md` entry; read the relevant `phase-N.md`;
ordering via `_index.md`). The `STATUS.md` dashboard + per-entry `Status` SSOT references stay (G-1).
**Operating-docs rule:** METHODOLOGY is reference/process doc, but its plan-workflow SECTIONS are
executed-as-instruction — keep them terse, no history narration.
**Lock-step:** the SETUP/INSTALL family (§4.3) repoints in parallel (O17 covers prompts; these docs in O14).

### O15 — Trinity `## Document locations` + mirror prose (project-template CLAUDE/AGENTS/GEMINI)
**Census:** §3.1 (CLAUDE.md:226/236-237 + AGENTS/GEMINI parallels).
**Action:** rewrite the Document-locations row + the "regenerated mirrors — read-stable but never source
of truth" prose to the no-mirror model (per-entry tree + `_toc.md` is SSOT + readable). **Trinity rule:
edit all three in lock-step, same commit** (this is a `project-template/` trinity = pack-chat-only per
PACK-AGENTS.md, but the SUBSTANTIVE rewrite is MAJOR → routes to coder per `pack-chat-minor-edits-only`).
**Cross-CLI normalization:** substitute the audience-correct canonical value per
ARCHITECTURE-BD-182.md §4.1, NOT a byte-identical copy.

### O16 — `PM-CHAT.md` plan read/write/anchor model + STATUS.md header
**Census:** §3.3 (PM-CHAT.md 328-334 STATUS header; 123/321-322/784/890/933/980/1022/1068 plan reads).
**Action (HIGH-VOLUME):** (a) the STATUS.md header template (328-334) drops the "Regenerated mirror at
docs/project/BACKLOG.md" clause — keep the per-entry-tree SSOT pointer. (b) the orchestrator's plan
read/write/anchor-link instructions repoint from the monolith `IMPLEMENTATION-PLAN.md` to per-entry
`phase-N.md` + `_index.md` for ordering. The read model: read the relevant `phase-N.md` (not "the
current phase section of the monolith"); the anchor-link model: link `[Title](implementation-plan/
phase-N.md#anchor)` not `[Title](IMPLEMENTATION-PLAN.md#anchor)`; the write model: author/edit a
`phase-N.md` entry.
**Operating-docs rule:** PM-CHAT is a live operating doc — terse, no history.

### O17 — Agent prompts repoint (architect/coder/planner/reviewer/docs-researcher/pm-chat)
**Census:** §3.4 (`docs/pack/prompts/*.md`); §3.5 HELP-FRAGMENT.md:39; §4.3 SETUP/INSTALL/CLI-PM.
**Action:** repoint the required-reading + write-target + anchor refs from the monolith
`IMPLEMENTATION-PLAN.md`/`BACKLOG.md` to the per-entry streams across the prompt family. Reconcile the
mixed monolith+tree language in `coder.md` to per-entry-only. HELP-FRAGMENT.md:39 cite → the per-entry
tree (`docs/project/backlog/` + `_toc.md`); its `_CLIENT_INSTALLED_FILES` allowlist exception (validate-
pack.py:5106) STAYS. SETUP-NEW/SETUP_TEMPLATE/INSTALL-PROCEDURES/CLI-PM-SETUP narrative repoints.

### O18 — Skill masters → no-mirror; restore pack-copy↔master parity (G-4 divergence close)
**Census:** §3.2 (`project-template/skills/audit-methodology/SKILL.md:76-77`, `pm-startup/SKILL.md:78,
82,89-91`); M1.
**Finding (M1):** GAP-2's real surface is `pm-startup/SKILL.md:89-91` (NOT boundary-investigation).
**Action:** rewrite the master skill prose to no-mirror: audit-methodology drops the "regenerated mirrors
OUT OF SCOPE / skip the mirror" rule (no project mirror to skip; the pre-v11 monolith-as-INPUT branch may
survive as a conversion-input note); pm-startup repoints startup reads from the monolith mirror to the
per-entry tree + `_toc.md`. Drop the `_format.md` ref (audit-methodology:76).
**Lock-step (enumerate-encoding-surfaces):** for EACH affected master skill, verify its 3 pack copies
(`.claude/`, `.codex/`, `.gemini/`) — BD-203 (C-3) corrected the copies; O18 corrects the masters →
parity restored. The reviewer MUST diff master vs each copy to confirm parity.

### O19 — Tracker library reconciliation (per-entry→monolith mirror removed; tracker→file mirror KEPT; dormant) — REVISED (MUST-1)
**Census:** §5.1 (~40+ refs, 9 `tracker-*.sh` + tests); SS-1; the newest binding decision; EE-10.
**BOUNDARY (critical, do NOT conflate two mirror concepts):**
- The **per-entry→monolith** mirror assumption (a tracker comment/contract that says "clients still
  ship a `BACKLOG.md` monolith mirror" / "until BD-206 lands") → RECONCILE to no-mirror.
- The **tracker→file read-only mirror** in `tracker-mirror.sh` → a SEPARATE tracker feature; KEEP its
  mechanism intact (BD-206.md KEEP names "tracker-mirror.sh CLIENT legs"). Do NOT remove it.
**Action:** reconcile the per-entry→monolith assumptions across the `tracker-*.sh` family — INCLUDING
the code paths, not just comments — so the dormant code is correct-if-resumed:
- `tracker-agent-read.sh` (159,251-252,263,277-278): repoint the fallback-to-monolith read to the
  per-entry tree; fix the "clients still ship those monolith mirrors" comment.
- `tracker-init.sh` (191,323,330): rewrite the "until BD-206 lands" / "still has monolith mirrors"
  comments to the no-mirror current state.
- `tracker-doctor.sh` (`:173-174` client-monolith staleness probe + `:128` comment), `tracker-migrate-forward.sh`
  (`:1395` "clients still ship a BACKLOG.md monolith mirror" + `:2149-2162` client read), `tracker-promote.sh`
  (`:251-271,463-624,915-923,1306-1360` project-monolith read/append paths), `tracker-phase-task.sh`
  (`:7,24,140,487` project-plan parse/emit), `scripts/tracker-migrate.sh`: where they READ/EMIT a project
  monolith for TD/phase content, repoint to the per-entry tree; where they manage the tracker→file
  read-only mirror header (`tracker-mirror.sh`/`tracker-migrate-reverse.sh:1604-1612`/`tracker-header-snapshot.sh`),
  KEEP — that is the M-track feature (EE-11 KEEP rows 11-13), NOT the M-mono assumption.
**Test lock-step (MUST-A — land WITH O19 in Wave E; `verify-full-ci-suite` prior-recurrence file):**
`tracker-agent-read-test.sh:34-78,190-192` — the fixture (`:71`) seeds ONLY `docs/project/BACKLOG.md`
(no per-entry tree) and `:191-192` (2.3 TD-010) asserts the monolith read. After O19's TD-*/phase-*
fallback repoint, seed the project per-entry tree (`docs/project/backlog/TD-010.md`) instead — OR, if
O19 keeps a mid-migration monolith-INPUT fallback, assert that path — and rewrite the `:34-43` fixture
comment. ALSO any `tracker-doctor` / `tracker-promote` / `tracker-phase-task` test that asserts the
project-monolith READ inverts WITH its deliverable. This is the EXACT file the `verify-full-ci-suite`
memory records as the BD-214 C1 recurrence (a dormant CI-wired `tracker-*` test missed by a
green-on-validate-pack verification); folding it in closes the recurrence.
**Honor:** the TrackerProvider abstraction (BD-060) + tracker portability. Tracker STAYS gated OFF
(BD-214) — O19 removes the latent monolith-mirror assumption only, it does NOT activate the feature.
**Operating-docs rule:** strip the "until BD-206" / deferred-feature narration; state current behavior only.
**The `.toml` examples + the init test are a SEPARATE deliverable (O25, MUST-1)** — the census §5.1
covered `tracker-*.sh` only; the CI-load-bearing `tracker.toml` examples + `tracker-init-test.sh` are O25.
**Scoping-signal SS-1:** the volume is large; the design BOUNDS it to per-entry→monolith repointing +
the stale-comment fix + O25, explicitly EXCLUDING the tracker→file mirror feature.
### O20-prose — `validate-pack.py` scattered no-mirror prose (§5.5 per-line verify)
**Census:** §5.5 (lines 136,239,318,2495,2752,3145,5360,5625,5697,7819,8836,11491).
**Action:** per-line read each; KEEP the BD-203 pack-correct prose; UPDATE any line that wrongly implies
a surviving PROJECT mirror. This is a verification sweep (measure-then-bound), folded into O9's commit.
### O21 — `supporting-docs/MIGRATION-v10-to-v11.md` no-mirror rewrite (census §4.1, the named launch-coherence doc)
**Census:** §4.1 (the client-facing migration DOC — distinct from the migration SCRIPT O7).
**Finding (re-grepped at HEAD `775e9cc1`, 2026-06-26):** the doc's `## Per-entry decomposition` section is
built around the mirror model. In-scope (measure-then-bound) line set:
- **UPDATE-REPOINT (rewrite to no-mirror):** L319-320 ("The pre-existing monolithic files become regenerated
  mirrors … not the source of truth"); L335-337 (`_intro.md` "re-emitted at the top of the regenerated mirror");
  L340-341 (the headline **"Monolithic files become regenerated mirrors."** + the 3 `docs/project/*.md` list +
  the L342-345 "remain on disk … rewritten from the per-entry tree … hand edits not preserved" body);
  L346-347 (Check 32 **mirror-in-sync** / Check 33 TOC-in-sync — Check 32 mirror-in-sync no longer exists for
  the project side under no-mirror; correct to TOC-in-sync only, or the no-mirror invariant); L353-356 ("the
  monolithic file is a derived artifact … Per-version monolithic sources are a v10-era pattern; v11 retires it"
  — keep the "v11 retires the monolith" spirit but the per-entry tree is the SSOT, not a mirror); L363-365
  ("emits the per-entry tree plus the regenerated mirror" → "emits the per-entry tree + `_toc.md`, no mirror").
- **STRIP (remove entirely):** L338 (`_format.md` (changelog only) sidecar mention — forbidden, O1); L386 +
  the WHOLE `### \`--force-overwrite-mirror\` flag (advanced)` subsection **L384-413** (the flag is RETIRED by
  DR-1/O7 — its entire user-facing recovery narrative, the `bash … --force-overwrite-mirror` sample, and the
  L408-410 "divergence is caught at CI time via Check 32 (mirror-in-sync) … the `--force-overwrite-mirror`
  recovery flag" closing). The L406-408 "future opt-in pre-commit hook (deferred to v11.x)" is a
  deferred-feature mention → STRIP per operating-docs-no-history-no-bloat.
- **KEEP:** L468 (the S4a `IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md` root rename row — the v10 INPUT
  rename, legitimate migration step). L374 (the rollback/backup "v10 monolithic files" = the v10 INPUT, KEEP).
**Action:** rewrite the `## Per-entry decomposition` section to: monoliths are DELETED (no regenerated mirror);
the per-entry tree + generated `_toc.md` is the sole SSOT + readable form; the migrator emits the tree + TOC;
no `_format.md`; the `--force-overwrite-mirror` subsection is removed (the divergence-gate it documents is
gone, O7/DR-1). **Cross-deliverable coherence gate:** O21's removal of the `--force-overwrite-mirror`
narrative MUST be consistent with O7/DR-1's removal of the flag itself (same effort; if the flag survived in
code the doc would lie, and vice-versa) — the planner sequences O21 in the SAME wave family awareness.
**Operating-docs rule:** MIGRATION is a client-facing procedure doc; keep it terse, no history narration, no
deferred-feature mentions (the pre-commit-hook line goes).
**Lock-step (enumerate-encoding-surfaces):** the MIGRATION doc's `_format.md` + mirror prose is part of the
EE-6 `_format.md` elimination set AND the DR-1 flag-retirement set — it must move with O1 (`_format.md`
forbidden) and O7 (flag removed).
**Wave:** D (governance/docs); disjoint file (`supporting-docs/MIGRATION-v10-to-v11.md`) → parallel within D.
### O22 — Remove the dead mirror subsystem (DR-2=C) — O22-proj in BD-206; O22-pack is BD-249 — REVISED (SHOULD-1)
**Census:** EE-8 (call-site census, 12 operational files); DR-2 (RESOLVED to C); realizes
`mirror-generate.sh:12` `TODO(v11.0): retire mirror-generate project-side at BD-206`.
**User decision (binding):** there is no monolith mirror on EITHER side; remove the entire dead
subsystem from BOTH surfaces — symmetry of the CORRECT solution, never of dead vestiges.
**Commit-split (Check-36):**
- **O22-proj (PROJECT side; folds into BD-206 waves):** remove `_lib.sh:109,121,129` (the three
  `mirror) printf 'docs/project/...'` project constants) + the project mirror-filename test asserts
  `test-per-entry.sh:219-221`. SAME-FILE SERIALIZATION: `_lib.sh` is also touched by O1 (`:136` drop +
  `:123` add) — these `_lib.sh` edits SERIALIZE. `test-per-entry.sh` is touched by O22-proj (219-221),
  O1 (231-232), and BD-249 (Groups 3/4/8/9) — see the same-file note in §6.
- **O22-pack → BD-249 (PACK side; SEPARATE `pack-only` BD, sequenced AFTER BD-206; NOT a BD-206 wave):**
  delete `scripts/lib/per-entry/mirror-generate.sh`; remove `_lib.sh:85,99` pack constants + the
  `pe_canonical_mirror_for_stream` accessor (`:150-152`) + the now-empty `mirror)` branch of
  `pe__stream_attr` + the `_lib.sh:4-8,83` header/comment refs + the stale `toc-regenerate.sh:15`
  comment; remove the dead pack test coverage (`test-per-entry.sh` Groups 3/4/8/9 + `:70,600`
  sourcing/smoke; `test-validate-pack-checks-32-33-34.sh:274-278` mirror-fixture path, KEEPING the
  TOC-fixture path `:281-288`; `test-init-project.sh:416,427` Group-5 mirror-regen leg). **This is
  BD-249's deliverable (Open, v11.0); BD-206 references it as the downstream anchor — it is NOT a
  BD-206 Wave F.**
**Call-site safety (EE-8):** after O4/O7 remove the two PRODUCTION callers, the generator's only
remaining callers are tests → safe for BD-249 to delete. `toc-regenerate.sh`'s `per_entry_regenerate_toc`
is a SEPARATE, surviving function — NOT removed.
**JOINT grep-ZERO completeness gate:** after BD-206 O22-proj AND BD-249 O22-pack both land,
`git grep -nE 'mirror-generate|per_entry_regenerate_mirror|pe_canonical_mirror_for_stream|mirror\) printf' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'`
MUST reach ZERO (audit-history exempt). Within BD-206 ALONE the gate is NOT yet zero (the pack half is
BD-249) — the BD-206 reviewer asserts the PROJECT constants/asserts are gone, not the joint zero.
### O23 — `test-fixtures/build.sh` round-trip redesign (NEW — BLOCKER-2)
**Census:** EE-9; EE-10; `build.sh:476-578`; `manifest-inputs.sh:56,58`; `validate-pack.yml:193,195`.
**Finding (BLOCKER-2):** `build.sh` was assigned to NO wave. It (1) sources the to-be-deleted
`mirror-generate.sh` (`:516`), (2) `die`s if the monolith is missing (`:537-538`), (3) regenerates the
mirror via `PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror` (`:555`) and round-trip
byte-compares it (`:567-573`), AND (4) is a MANIFEST fixture-input (`manifest-inputs.sh:56`
`project-template/*` + `:58` `test-fixtures/build.sh`) that gates BD-228 Check 62 via the push-time
`manifest-sync.sh`. The no-mirror model abolishes the decompose→regenerate→diff round-trip's SUBJECT.
**Design:** rewrite the per-stream fixture step (`build.sh:510-578`) to the no-mirror model:
- REMOVE the `. mirror-generate.sh` sourcing (`:516`), the monolith-missing `die` (`:537-538`), the
  `cp …orig` snapshot (`:544`), the `per_entry_regenerate_mirror` regen (`:555`), and the round-trip
  byte-identity `cmp`/`die` (`:567-573`).
- KEEP the decompose half (`per_entry_decompose`, `:549`) IF the fixture still needs a populated
  per-entry tree from a v10 monolith INPUT; the NEW integrity property is **decompose → per-entry tree +
  `_toc.md` present + well-formed** (no mirror to diff). Equivalently, if the persona-contract fixtures
  now ship a per-entry tree directly (greenfield no longer emits a monolith), build.sh's role narrows to
  installing/validating the tree shape.
- The install-map tuple `build.sh:528` (`project-implementation-plan|…|IMPLEMENTATION-PLAN.md|…`) drops
  the mirror middle field consumption (same as O4's init-side tuple change).
**Sequencing (BLOCKER-2):** build.sh's mirror-round-trip removal lands in **Wave A** (it is part of the
full-battery-green requirement — `validate-pack.yml` runs `build.sh --all/--verify` and the persona
contracts depend on it). The `mirror-generate.sh` SOURCING removal must precede (or coincide with) the
file deletion in BD-249 — since O23 removes the source line in Wave A and BD-249 deletes the file later,
there is no edit-then-dangle window. **Manifest interplay:** because build.sh + `project-template/*` are
manifest inputs, Wave A's sidecar rebuild + build.sh edit trigger a push-time `manifest-sync.sh` regen
(BD-228 method) — the regenerated `test-fixtures/manifest.txt` is committed with Wave A (or at push per
the `regenerate-manifest-v11-surface` rule); a broken build.sh would break Check 62, so O23's redesign
must leave `build.sh --verify` green.
**Doc prose lock-step (SHOULD-B):** `test-fixtures/README.md:30` documents `v11-realistic-ot` as
"decomposes the v11 monolithic project-side mirrors ... regenerates the mirrors, and verifies byte-identity
round-trip"; `:189-191` "mirror-regen / TOC-regen + byte-identity round-trip." O23 ABOLISHES exactly this
round-trip → rewrite both spans to the no-mirror integrity property (decompose → per-entry tree + `_toc.md`
present + well-formed; NO mirror to byte-compare). `README.md` is a fixture-doc, not battery-RED, but it is
the `enumerate-encoding-surfaces` doc share of the build.sh change → lands with O23 in Wave A.
**`PE_FORCE_OVERWRITE_MIRROR` (MUST-2):** O23 removes the `build.sh:496,552,555` consumers — part of the
two-var grep-zero gate (DR-1/O7).
### O24 — Check-43 fixtures + test lock-step (NEW — BLOCKER-3)
**Census:** EE-6/EE-10; `test-validate-pack-check-43.sh:133-138,481-494`; the 2 project-side-refs skeletons.
**Finding (BLOCKER-3, the most dangerous recall miss):** a FIXTURE asserts `_format.md` MUST PASS Check
43 — directly contradicting the FORBIDDEN model — and the test's `required_entries` set asserts the
allowlist MUST contain `_format.md` + the 3 monoliths. These FLIP to FAIL the instant O9 edits the
allowlist; they are in NEITHER the prior census NOR the prior design.
**Action (lock-step with O9, SAME wave):**
- `scripts/tests/test-validate-pack-check-43.sh:133-138` — remove `_format.md` from the `required_entries`
  set; for the 3 monoliths, match O9's DR-3 KEEP/STRIP decision (if STRIP, remove from `required_entries`;
  if KEEP-as-conversion-input, keep with the conversion-input rationale).
- `:481-494` (T9) — the PASS fixture synthesizes a `docs/project/backlog/_format.md` and asserts Check 43
  passes; repoint to a SANCTIONED sibling (`_intro.md`/`_rules.md`/`_index.md`) so the test still
  exercises the same-dir allowlist resolution WITHOUT a forbidden `_format.md`.
- `scripts/tests/fixtures/project-side-refs/project-side-pass-same-dir-skeleton.md:13,21` — drop the
  `_format.md` from the "MUST PASS via the allowlist" list (keep `_intro.md`/`_rules.md`); add `_index.md`
  if the skeleton models the impl-plan stream. `…fail-per-entry-skeleton.md:14` — drop the `_format.md`
  example ref.
**Verification:** after O9+O24, `bash scripts/tests/test-validate-pack-check-43.sh` is green AND no
fixture references a forbidden `_format.md`; the FORBIDDEN-`_format.md` grep-zero gate (EE-6, operational)
passes including the test/fixture surfaces.
### O25 — `tracker.toml` examples + `tracker-init-test.sh` adjudication + Check-29 flip (NEW — MUST-1)
**Census:** `tracker.toml.project-example:37-44`; `tracker.toml.pack-example:50,57-58`;
the LIVE emitter `tracker-init.sh:185-192,318-376` (MUST-B); `tracker-init-test.sh:14-16,256-302`;
`tracker-config-schema-test.sh:17-20,116-131,223-242` Test 7 (BLOCKER-A);
`validate-pack.py:2481-2497,2571-2593,2787-2796` (Check 29); EE-10/EE-11. (The census §5.1 covered
`tracker-*.sh` only — the `.toml` examples, the live emitter, Test 7, and the 3.5 init asserts are
the missed CI-load-bearing surfaces; EE-11 classifies the COMPLETE tracker family.)
**Finding (MUST-1):** `tracker.toml.project-example:37` ships a LOAD-BEARING `[mirror]` table
(`enabled=true`, `location_backlog="BACKLOG.md"`, `location_changelog="CHANGELOG.md"`,
`regenerate_on_write=true`) that points at monoliths BD-206 deletes. It is **Check-29-ENFORCED**:
`validate-pack.py:2794-2796` calls the example-validator with `mirror_required=True` for the CLIENT
example (`:2492-2497` "the client model keeps monolith mirrors until BD-206"), so the `[mirror]` table
CANNOT simply be deleted — the validator would FAIL. `tracker.toml.pack-example:57-58` literally says the
client table survives "until BD-206 retires the project-side monolith mirrors."
**Design (DR-4 — the per-entry→monolith-vs-tracker→file boundary, applied):** the
`location_backlog/location_changelog` keys point at the per-entry→**monolith** mirror BD-206 abolishes →
the table's monolith-pointing role is RETIRED. Disposition + Check-29 lock-step (lock-step is mandatory —
the example + the validator's `mirror_required` flag move together):
- **(A) Drop the `[mirror]` table from `tracker.toml.project-example`** AND flip `validate-pack.py:2796`
  `mirror_required=True` → `False` (+ update the `:2492-2497,2571-2573` rationale to "no surface keeps a
  monolith mirror post-BD-206"). This makes the client example match the pack example (both no-`[mirror]`),
  which is the no-mirror end-state. RECOMMENDED — it is the symmetric correct solution.
- **(B)** retain the `[mirror]` table ONLY if it is re-cast as the SEPARATE tracker→file read-only-mirror
  feature (`tracker-mirror.sh`) config — but that feature's location semantics differ (a tracker-generated
  read-only file, not a per-entry→monolith mirror), and tracker is gated OFF (BD-214), so re-casting a
  dormant-feature config adds latent surface. NOT recommended.
The architect RECOMMENDS (A): drop the table + flip `mirror_required=False`, consistent with Check 29
staying green and the no-mirror model. (Pack Chat/user confirms the option at the design gate.)
- **`tracker.toml.pack-example:57-58`** — STRIP the "until BD-206 retires …" comment (operating/example
  doc; deferred-feature narration). **`:50`** ("NO [mirror] table on the pack surface") STAYS (accurate).
- **The LIVE emitter `tracker-init.sh:359-376` (MUST-B — the no-mirror end-state is NOT achieved until the EMITTER stops emitting the client `[mirror]`):** the surface-aware emitter still writes a client `mirror_block` (`[mirror]` / `enabled=true` / `location_backlog="BACKLOG.md"` / `location_status` / `location_changelog` / `regenerate_on_write=true`) pointing at monoliths BD-206 deletes; `:185-192,318-330` carry the "client surface keeps it until BD-206" comments. **Action:** drop the client `mirror_block` so the client surface emits NO `[mirror]` table (the emitter then matches the pack surface, the no-mirror end-state), and rewrite the `:185-192,318-330` comments to current behavior. WITHOUT this, the static-example drop (A) leaves a CONTRADICTION — a fresh `pack tracker init --surface client` would re-emit the very `[mirror]` table the example dropped, pointing at a deleted file.
- **`tracker-init-test.sh:14-16,256-283,296-302`** — `:296-302` (3.5) asserts the EMITTED client `[mirror]` table (`mirror.enabled=true`, `mirror.location_backlog="BACKLOG.md"`, …); invert to assert the client init config OMITS `[mirror]` (lock-step with the emitter drop). Rewrite the `:14-16,280-283` "until BD-206" / "client model still has monolith mirrors" comments to the no-mirror current state.
- **`tracker-config-schema-test.sh` Test 7 (BLOCKER-A — the Wave-A full-battery break the prior design missed):** `:17-20,224-226` header + `:116-131` GOOD_CLIENT `[mirror]` fixture + `:223-242` asserts PIN Check-29's `mirror_required=True` client behavior (`7.1 missing mirror on client → exit nonzero`; `7.2 message names mirror as missing on the client example`). The (A) `mirror_required=True→False` flip INVERTS Test 7: a client `tracker.toml` missing `[mirror]` must now PASS, not FAIL. **Action (lock-step with (A), Wave A):** invert Test 7 (missing client `[mirror]` → PASS / soft-pass), strip the `[mirror]` block from the GOOD_CLIENT fixture, and rewrite the `:17-20,224-226` "required on the client example until BD-206" header. This test is in the CI battery (`scripts/tests/*.sh`) → it MUST land in the Wave-A inversion set (EE-9).
**Verification:** Check 29 (`validate-pack.py` Check 29) green against BOTH examples post-change;
`tracker-init-test.sh` AND `tracker-config-schema-test.sh` green (Test 7 inverted, Tests 1/15/16/17
unchanged — they exercise the M-track / pack-`[mirror]` cases, KEEP per EE-11 rows 18-19); the live
`tracker-init.sh` client emitter writes NO `[mirror]`; grep-zero on `until BD-206` in the `.toml` +
tracker test + emitter surfaces.
### O26 — Operating-doc allowlist reconciliation (NEW — MUST-3)
**Census:** `pack-ops/.operating-doc-history-allowlist.txt:145,150,157`;
`pack-ops/.operating-doc-deferred-feature-allowlist.txt:419,423`; `validate-pack.py:8224` glob; EE-10.
**Finding (MUST-3):** the two operating-doc allowlists carry line-anchored exemptions for content in the
to-be-rebuilt/eliminated sidecars: history `145,150` + deferred `419` (`changelog/_format.md` — eliminated
by O1); history `157` (`changelog/_rules.md`, snippet `2026-04-20`) + deferred `423`
(`implementation-plan/_rules.md`) — both reference `_rules.md` files O3 rebuilds clean. The validator
globs `project-template/docs/project/*/_rules.md` (`:8224`) as operating docs, so the rebuilt files ARE
checked; the changelog `_format.md` glob member (`:8225`) is removed by O9.
**Action (lock-step with O1+O3+O9):**
- REMOVE the `_format.md` exemptions (history `145,150`; deferred `419`) — the file no longer exists.
- REMOVE the `changelog/_rules.md` history exemption (`157`) and the `implementation-plan/_rules.md`
  deferred exemption (`423`) — the rebuilt `_rules.md` carries ZERO history + ZERO deferred-feature text
  (O3's operating-docs constraint), so the exemptions are DEAD.
- **`.dangling-ref-allowlist.txt:101,104` (SHOULD-A — the measure-then-bound allowlist surface EE-10
  initially omitted):** the tokens `docs/project/BACKLOG.md` (`:101`) + `docs/project/CHANGELOG.md` (`:104`)
  exist to allowlist prose refs to the project monoliths AS "regenerated ... mirror" (the `reason` strings).
  After BD-206 removes that prose (O1/O14/O15/O16/O17/O21) the tokens are DEAD and their `reason` is FALSE
  under no-mirror. **Action:** REMOVE both tokens (size the allowlist to the post-fix legitimate set —
  `ci-guard-measure-then-bound`). The dangling-ref check does NOT hard-fail on unused tokens (verified) →
  SHOULD not MUST, but the allowlist MUST be sized to the legitimate set. (KEEP the `:95,98`
  `pack-ops/BACKLOG.md`/`CHANGELOG.md` tokens — those are the pack retired-monolith names cited in the
  no-recreate rule, a SEPARATE legitimate ref.) Lands with O26 in Wave A.
**Constraint (the FAIL-LOUD check):** after O3+O26, run the operating-doc check against the rebuilt
`*/_rules.md` with the trimmed allowlists — it MUST pass with ZERO project-`_rules.md` exemptions. If it
fails, the rebuilt `_rules.md` smuggled history/deferred-feature text → fix the `_rules.md` (do NOT
re-add an exemption). Measure-then-bound: the allowlist is sized to the (now empty) legitimate
project-`_rules.md` exemption set.
### Architect-level verifications (mandate item 7) — discharged
- **`customization-preserve.sh:36` cite** (§5.2): the `IMPLEMENTATION-PLAN.md §2.5 BD-088` ref is a
  maintenance/spec-doc CITATION, not a live monolith read → KEEP; verify the cited §2.5 still resolves
  (if it points at a deleted monolith spec, repoint). Low-risk; folded into O7 verification.
- **`pack-td.sh` (§5.4):** `pack td` writes the PACK's own plan stream, NOT a client mirror → PACK-side
  → CONFIRMED OUT of BD-206 scope. The "tracker deferred — BD-214" notes are accurate (keep).
- **`_lib.sh`/`mirror-generate.sh` file-fate:** DR-2 RESOLVED to C (both-sides full removal) — O22 (§5).
- **per-line `validate-pack.py` no-mirror prose:** O20-prose.


---

## 5. Design risks + open decisions (DR-1..DR-4)

### DR-1 — The divergence-gate removal-ripple — TWO force vars (G-8) — REVISED (MUST-2)
**State (EE-7, re-measured):** TWO distinct vars gate the mirror-divergence path:
`_MIGRATOR_FORCE_OVERWRITE_MIRROR` (the migrator-framework flag) and `PE_FORCE_OVERWRITE_MIRROR`
(the per-entry-layer bypass the migrator EXPORTS to; the bridge is `decompose.sh:117-125`).
**Risk:** removing only the migrator flag leaves the `PE_FORCE_OVERWRITE_MIRROR` consumers
(`mirror-generate.sh:251-253`, `build.sh:555`, Group-8 tests) orphaned referencing a dead path.
**Design:** remove the WHOLE divergence-gate across BOTH vars as ONE coherent change spanning O7
(migrator flag + bridge + Group-4 tests), O23 (`build.sh` consumers), and BD-249 (`mirror-generate.sh`
consumers + Group-8 tests, when the file/coverage is deleted). **Verification gate (TWO-pattern,
planner/coder):** `git grep -nE '_MIGRATOR_FORCE_OVERWRITE_MIRROR|PE_FORCE_OVERWRITE_MIRROR|force-overwrite-mirror' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'`
MUST reach grep-ZERO (jointly across O7+O23+BD-249). A single-pattern gate (the prior design's
`force.overwrite.mirror|_MIGRATOR_FORCE_OVERWRITE_MIRROR`) DID pattern-match `PE_FORCE_OVERWRITE_MIRROR`
via `force.overwrite.mirror` — but the ENUMERATED removal set omitted the `PE_*`/`build.sh` consumers;
this design enumerates them explicitly. **Residual:** only the v10→v11 adapter uses the flag (EE-7).
SUPPORTED.

### DR-2 — Mirror subsystem fate — RESOLVED to (C): both-sides full removal (USER DECISION) — REVISED (SHOULD-1)
**Decision (user, 2026-06-26):** no monolith mirror on EITHER side; remove the entire dead subsystem
from BOTH surfaces — symmetry of the CORRECT solution, never of dead vestiges. The call-site census
(EE-8) proves zero live production callers survive O4/O7.
**Realized by O22, SPLIT across two BDs (SHOULD-1):** **O22-proj** (the project `_lib.sh:109,121,129`
constants + `test-per-entry.sh:219-221`) folds into BD-206 waves; **O22-pack is BD-249** — a SEPARATE
`pack-only` BD (Open, Target v11.0; verified to exist) that deletes `mirror-generate.sh` + the pack
constants + the accessor + the dead pack test coverage, sequenced DIRECTLY AFTER BD-206 (the file
deletion is the terminal mirror-subsystem state). The prior "Wave F inside BD-206's rule-10 map" framing
is DROPPED — BD-249 owns the pack half with its own commit + anchor; BD-206 references it downstream.
`toc-regenerate.sh`'s `per_entry_regenerate_toc` survives (EE-8).

### DR-3 — Check 43 monolith-basename allowlist + the `_format.md` sibling: KEEP-as-conversion-input vs STRIP — REVISED (BLOCKER-3)
**State (§2.1; EE-6):** `validate-pack.py:5503` allowlists `_format.md` (sibling resolution);
`:5504-5507/5590-5593` allowlist the 3 monolith basenames as "regenerated mirrors"; `:5094` carries a
PHANTOM `(see /backlog/_format.md)`. **Measure:** no `_format.md` exists anywhere post-O1 → `:5503` is
unconditional STRIP; the `:5094` parenthetical is a STRIP (pack `backlog/_format.md` never existed). The
monolith mirror RATIONALE is false (no mirror installs). **Bound:** STRIP the mirror-rationale prose;
for the 3 basenames, classify KEEP (a v10 client mid-migration still HAS the monolith as a conversion
INPUT, so Check 43 may legitimately encounter it) vs STRIP — size the allowlist to the legitimate
(conversion-input) set ONLY. **Test lock-step (BLOCKER-3):** `test-validate-pack-check-43.sh:133-138`
(the `required_entries` set) + `:481-494` (T9 PASS fixture) + the 2 project-side-refs skeletons move WITH
the allowlist change (O24). **Planner gate:** measure whether any Check-43 code path still encounters the
3 basenames post-no-mirror; size the allowlist exactly.

### DR-4 — Check-29 `[mirror]` requirement on the client tracker.toml example — NEW (MUST-1)
**State:** `validate-pack.py:2794-2796` validates the client example with `mirror_required=True`
(`:2492-2497`), so Check 29 REQUIRES a `[mirror]` table on `tracker.toml.project-example` — the table
cannot be deleted without a validator change. `tracker.toml.pack-example` already passes
`mirror_required=False`. **Risk:** deleting the table without flipping the flag → Check 29 FAILs;
flipping the flag without deleting the table → a stale monolith-pointing example ships. **Design
(RECOMMENDED A):** drop the `[mirror]` table from the client example AND flip `:2796`
`mirror_required=True`→`False` (+ update the `:2492-2497,2571-2573` rationale) in lock-step — the client
example then matches the pack example (no `[mirror]`), the no-mirror end-state. The `location_*` keys
pointed at the per-entry→monolith mirror BD-206 abolishes; the SEPARATE tracker→file read-only-mirror
feature (`tracker-mirror.sh`) is unaffected (it is not configured via this `[mirror]` table's
monolith-location semantics). **The flip ripples to THREE further surfaces in lock-step (FINAL
reconciliation; all Wave A):** (1) `tracker-config-schema-test.sh` Test 7 PINS `mirror_required=True` →
invert (BLOCKER-A); (2) the LIVE emitter `tracker-init.sh:359-376` still WRITES the client `[mirror]` →
drop the client `mirror_block` so the emitter matches the example (MUST-B); (3) `tracker-init-test.sh:296-302`
asserts the emitted client `[mirror]` → invert. Realized by O25. **Verification:** Check 29 green against
both examples; `tracker-config-schema-test.sh` (Test 7 inverted; 1/15/16/17 KEEP) + `tracker-init-test.sh`
green; the emitter writes NO client `[mirror]`.

## 5b. CI-guard measure-then-bound contracts (the new/changed checks) — REVISED

Each new enforcement check follows the measure-then-bound contract: measured against the gold (the only
real v10→v11 target) + the empty template; candidate set from `git ls-files`; SKIP-lenient if git absent.

| Guard | Measured against | Result | Allowlist bound |
|---|---|---|---|
| Backlog form-family (O9/O10) | V2 backlog gold (113 td) | EE-1: all 113 conform to §3.2 | none — the enum IS the bound (D9) |
| Impl-plan form-family (O9/O10) | V2 impl-plan gold (61 epic + 15 part) | EE-2: all conform; parts lightweight | none |
| Changelog structure + caps (O12) | Production changelog gold (55) | EE-3: max 130 < 180; max 243 < 250; core present | gold-safe caps (0 violations) |
| `_index.md` validator (O11) | the impl-plan tree (derived) | topological + membership-sync | n/a (structural); ADMITTED in support-set (`_lib.sh:123`, MUST-4) |
| Phase/part/task naming guard (O13) | V2 impl-plan gold headings | EE-2: gold conforms → zero violations | n/a (template-match) |
| `_format.md` FORBIDDEN (O1/O9/O24/O21) | tree post-Wave-A | **EE-6: 23 OPERATIONAL refs (re-measured), incl. tests/fixtures/allowlist/operating-doc set → grep-zero** | n/a (forbidden set; audit-history exempt) |
| Empty-template shape (O9) | `project-template/docs/project/` post-Wave-A | sidecar vocabulary only, no monolith, `_index.md` admitted | n/a |
| Check 43 allowlist (O9/O24, DR-3) | the tree post-no-mirror | mirror rationale STRIP; `_format.md` sibling STRIP; phantom `:5094` STRIP; 3 basenames KEEP/STRIP per measure | sized to conversion-input set ONLY |
| Check 29 client `[mirror]` (O25, DR-4) | both `tracker.toml` examples + `tracker-config-schema-test.sh` Test 7 + the live `tracker-init.sh` emitter + `tracker-init-test.sh` 3.5 | `mirror_required` flipped to False; client table dropped; Test 7 inverted; emitter drops client `[mirror]`; 3.5 inverted → all no-`[mirror]` end-state | n/a (validator-flag change + lock-step test/emitter inversions; M-track KEEP rows untouched per EE-11) |
| Operating-doc allowlists (O26, MUST-3) | rebuilt `*/_rules.md` + the trimmed allowlists | dead exemptions removed; rebuilt files carry zero history/deferred-feature → pass with ZERO project-`_rules.md` exemptions | sized to (empty) legitimate set |
| Full CI battery green at Wave A (O8/O23/O24 + EE-9) | validate-pack + build.sh + shell shard battery | the 14 validate-pack rows cleared + EXISTING-test inversions land WITH the change | n/a (atomicity) |
| MIGRATION doc no-mirror (O21) | `supporting-docs/MIGRATION-v10-to-v11.md` re-grepped at HEAD | mirror/`_format.md`/`--force-overwrite-mirror` removed; KEEP L468 rename row | n/a (doc rewrite) |
| Dead mirror subsystem (O22-proj + BD-249) | whole tree, operational-only (EE-8: 12 files) | JOINT grep-zero on the mirror-subsystem patterns (audit-history exempt) | n/a (removal; grep-ZERO gate) |
| force-overwrite vars (DR-1/O7/O23/BD-249) | whole tree, operational-only (EE-7: TWO vars) | two-pattern grep-zero on both var names + `force-overwrite-mirror` | n/a (removal; grep-ZERO gate) |

**Post-fix verification (mandatory):** after Wave-A the FULL battery (validate-pack + `build.sh --verify`
+ the shell shard battery) runs CLEAN; the new legs run clean against the empty template; the conformance
checks run clean against the gold. A guard RED against the gold — OR an EXISTING test RED in its wave — is
a design defect. After O22-proj + BD-249, the mirror-subsystem JOINT grep-zero gate returns zero; after
O7+O23+BD-249, the two-var force-overwrite grep-zero gate returns zero (audit-history exempt).

---

## 6. Rule-10 parallelization map (parallel waves vs serial commits) — REVISED (BLOCKER-1/2, SHOULD-1)

**Scheduling principle:** independent worktree waves run in parallel; same-file edits serialize; a wave
that DEPENDS on an earlier wave's landed state runs after it. Wave A is the single atomic foundational
**FULL-BATTERY-green** commit and MUST land FIRST and ALONE. **Wave F is DROPPED** — the pack-side
dead-mirror removal is BD-249 (a separate post-BD-206 BD).

### Wave A — FOUNDATIONAL ATOMIC FULL-BATTERY-GREEN COMMIT (serial, first, alone) — EXPANDED
**Deliverables:** O0(clarified) + O1 + O2 + O3 + O4(init-side) + O8 + **O23(build.sh round-trip removal +
README prose, SHOULD-B) + O24(Check-43 fixtures/test lock-step) + the O1/O4 EXISTING-test inversions (EE-9)
+ O9's Check-43 allowlist edits + O26(operating-doc allowlist trim + `.dangling-ref-allowlist.txt:101,104`,
SHOULD-A) + O25(tracker.toml client `[mirror]` drop + Check-29 `mirror_required` flip + `tracker-config-schema-test.sh`
Test 7 inversion BLOCKER-A + the live `tracker-init.sh` emitter drop MUST-B + `tracker-init-test.sh` 3.5 inversion)
+ O1 doc-ref MERGE-STRATEGY:274-275 (SHOULD-C)**. ONE commit.
**Why this composition (BLOCKER-1, EE-9):** Wave-A green is measured against the FULL CI battery
(`validate-pack.py` + `test-fixtures/build.sh --all/--verify` + the shell shard battery), NOT
validate-pack alone. Every surface that goes RED the instant the template / support-set / mirror-
generation / `_format.md` / Check-43 allowlist changes MUST land in this commit:
- the 14 validate-pack Check 39/41 rows clear (O8) — EE-4;
- `test-per-entry.sh:231-232` inverts (O1) + a `_index.md` admitted assert adds (O11/O1);
- `test-init-project.sh` 4.2/4.3/4.4/4.5/4.6 invert/delete (O1/O4);
- `contract-greenfield.sh`/`contract-migration.sh` arrays drop the `_format.md` + 3 monoliths (O1/O4);
- `test-v11-realistic-ot.sh` A.13 inverts (O1) — NOTE this is a fixture-dependent test; it runs in the
  fixture shard which builds via `build.sh`, so O23 must land here too;
- `build.sh` mirror-round-trip removed (O23) so `build.sh --all/--verify` + the persona contracts pass;
- `test-validate-pack-check-43.sh` required-set + T9 + the 2 skeleton fixtures move with O9 (O24);
- the operating-doc allowlists trim (O26) so the rebuilt `_rules.md` passes the operating-doc check;
- the tracker.toml client `[mirror]` table drops + Check-29 `mirror_required` flips (O25/DR-4) +
  `tracker-config-schema-test.sh` Test 7 inverts (BLOCKER-A) + the live `tracker-init.sh` client emitter
  drops its `[mirror]` block (MUST-B) + `tracker-init-test.sh` 3.5 inverts + its comments rewrite — Check 29
  + `tracker-config-schema-test.sh` + `tracker-init-test.sh` are ALL in the battery, so all four move
  together in this atomic commit (the M-track KEEP surfaces per EE-11 are untouched).
**Same-file serialization within Wave A:** `init-project.sh` (O1/O4/O8), `_lib.sh` (O1 `:123` add +
`:136` drop; O22-proj `:109,121,129` — note O22-proj is Wave B but `_lib.sh` SERIALIZES across A→B→BD-249,
last writer BD-249), `validate-pack.py` (O9 Check-43 + O26-adjacent + O25 Check-29), `test-per-entry.sh`
(O1 `:231-232`; O22-proj `:219-221` is Wave B). Where a Wave-A surface and a Wave-B/BD-249 surface share a
file (`_lib.sh`, `test-per-entry.sh`), Wave A lands its edits first; the later wave edits the same file
after (no parallel write).
**Why O25 is in Wave A (not Wave E):** the client `[mirror]` drop is lock-step with the Check-29
`mirror_required` flip AND `tracker-config-schema-test.sh` Test 7 (which PINS the flag) AND the live
`tracker-init.sh` emitter + `tracker-init-test.sh` 3.5 — if any split across waves, the intermediate state
is Check-29-RED or battery-RED (Test 7) or self-contradictory (emitter re-emits the dropped table). Land
all five together. **The bulk `tracker-*.sh` reconciliation O19 stays Wave E** — those are dormant; BUT
O19 carries its OWN battery break: `tracker-agent-read-test.sh` (+ any `tracker-doctor`/`tracker-promote`/
`tracker-phase-task` test asserting a project-monolith read) inverts WITH O19 in Wave E (MUST-A, EE-9
Wave-E row). The split is by lock-step subject (Check-29 surfaces → Wave A; the dormant monolith-fallback
repoints → Wave E), each carrying its own test inversions.
**Blocks:** every later wave (they assume the rebuilt sidecars + the `_rules.md` schema SSOT exist).

### Wave B — Migrator + conversion machinery (parallel within; after A)
- **B1:** O4(decompose-side) + O7 (migrator overhaul + DR-1 two-var divergence-gate removal) +
  the O7 migration-test inversions (`test-migrate-v10-to-v11-decompose.sh` 2.2a/b/c + Group 4;
  `test-v11-realistic-ot.sh` Group B; `contract-migration.sh:475`) — `decompose.sh`, `migrator-core.sh`,
  `migrate-v10-to-v11.sh` + their tests. SERIAL within B1 (the files interlock via the flag). O7 does NOT
  edit `mirror-generate.sh` (BD-249 deletes it; the planner sequences BD-249 after B1).
- **B1b (O22-proj, PROJECT-side dead-mirror removal):** remove `_lib.sh:109,121,129` project `mirror)`
  constants + `test-per-entry.sh:219-221` project mirror-filename asserts. SAME-FILE: `_lib.sh` shared
  with Wave A (O1) → A first, B1b after; `test-per-entry.sh` shared with Wave A (O1 `:231-232`) AND
  BD-249 (Groups 3/4/8/9) → these serialize; B1b's `test-per-entry.sh` edit (project asserts 219-221) is
  PROJECT-scoped, BD-249's is pack-scoped. Since one file cannot split across two scope-keyworded commits,
  the planner uses NEUTRAL framing (no scope keyword) for whichever commit carries the shared
  `test-per-entry.sh` edits, OR lands all `test-per-entry.sh` project edits in a BD-206 commit and the
  pack-group edits in BD-249 (the file is touched by both BDs — neutral framing on the BD-206 commit that
  shares it, since BD-249 is a separate later commit). FLAG for Pack Chat (commit-framing).
- **B2:** O5 (detect.sh/pack-help.sh client repoint) + O5b tests — `detect.sh`, `pack-help.sh`,
  `pack-help-test.sh`. Independent of B1.
- **B3:** O6 (recommendation.sh repoint) + tests — `recommendation.sh`, `recommendation-test.sh`. Independent.
B1/B1b/B2/B3 mutually PARALLEL EXCEPT the `_lib.sh`/`test-per-entry.sh` serialization in B1b.

### Wave C — Enforcement legs (parallel within; after A; read A's schema)
- **C1:** O9 residual (the empty-template leg + schema parser; the Check-43 allowlist edits already landed
  in Wave A with O24) — `validate-pack.py`. NOTE: validate-pack.py's Check-43 + Check-29 edits land in
  Wave A; C1 carries the NEW empty-template-validation leg only (same file → if Wave A already touched
  validate-pack.py, C1's leg serializes after A; the planner may fold the whole validate-pack.py change
  into Wave A to avoid a second touch — RECOMMENDED, since validate-pack.py is one file).
- **C2:** O10 (client bash leg) — `validate-docs.sh`, `.docs-gate-allowlist.txt`.
- **C3:** O11 (`_index.md` generator + validator + tests). **NOTE:** the `_lib.sh:123` admission is in
  Wave A (O1); C3 carries the generator/validator/tests.
- **C4:** O12 (changelog conformance + tests).
- **C5:** O13 (naming guard + tests).
C2..C5 mutually PARALLEL (disjoint surfaces). All READ the `_rules.md` schema SSOT from Wave A.
**Same-file callout:** `validate-pack.py` is touched by Wave A (O9 Check-43/O25 Check-29/O26-adjacent) AND
C1 (the empty-template leg) — these SERIALIZE; the planner SHOULD fold all validate-pack.py edits into Wave A
(one-file, avoids a second-touch serialization) OR run C1 strictly after A on that file.

### Wave D — Governance + docs + prompts (parallel within; after A)
- **D1:** O15 (trinity Document-locations — all 3, ONE commit, trinity rule).
- **D2:** O16 (PM-CHAT plan model + STATUS header).
- **D3:** O17 (agent prompts + HELP-FRAGMENT + SETUP/INSTALL/CLI-PM).
- **D4:** O14 (METHODOLOGY wholesale plan-model rewrite).
- **D5:** O18 (skill masters + pack-copy parity verify).
- **D6:** O21 (`MIGRATION-v10-to-v11.md` no-mirror rewrite). COHERENCE: O21 removes the
  `--force-overwrite-mirror` user narrative; it must land consistent with O7/DR-1 (flag removed in code).
D1..D6 mutually PARALLEL (disjoint files); none touch B/C code.

### Wave E — Tracker library reconciliation (parallel within; after A; independent of B/C/D)
- **E1:** O19 (tracker library per-entry→monolith reconciliation; tracker→file mirror KEPT) — the dormant
  `tracker-*.sh` family (`tracker-agent-read.sh`, `tracker-doctor.sh`, `tracker-migrate-forward.sh`,
  `tracker-promote.sh`, `tracker-phase-task.sh`, `tracker-migrate.sh`; M-track KEEP files untouched) +
  their tests. **Test lock-step (MUST-A — land IN E1, the EE-9 Wave-E break):** `tracker-agent-read-test.sh`
  (`:71` seeds a monolith, `:191-192` asserts the read) inverts WITH O19; ditto any `tracker-doctor`/
  `tracker-promote`/`tracker-phase-task` test asserting a project-monolith read. `tracker-agent-read-test.sh`
  is the `verify-full-ci-suite` BD-214 C1 prior-recurrence file — missing it again is the documented
  anti-pattern. **NOTE:** O25 (the `tracker.toml` examples + Check-29 flip + Test 7 + the emitter +
  `tracker-init-test.sh`) is in WAVE A (lock-step with Check 29), NOT here — E1 is the dormant
  `tracker-*.sh` family + its monolith-fallback test inversions only. Tracker family disjoint from B/C/D.

### Downstream (NOT a BD-206 wave) — BD-249 (O22-pack, pack-side dead-mirror removal)
BD-249 (Open, v11.0) lands the pack half: DELETE `mirror-generate.sh`; remove `_lib.sh:85,99` pack
constants + the `pe_canonical_mirror_for_stream` accessor (`:150-152`) + the now-empty `mirror)` branch +
`:4-8,83` refs + `toc-regenerate.sh:15` comment; remove the dead pack test coverage. It is a SEPARATE
`pack-only` commit (Check-36), sequenced DIRECTLY AFTER BD-206 (the file deletion is terminal). BD-206
references it as the downstream anchor; the JOINT mirror-subsystem grep-zero gate goes green only after
BOTH BD-206 (O22-proj) and BD-249 land.

**Wave dependency DAG:**
```
A  →  { B1, B1b, B2, B3 }   (Wave B; B1b serializes with A on _lib.sh and with BD-249 on test-per-entry.sh)
A  →  { C1, C2, C3, C4, C5 }   (Wave C; read A's schema; C1's validate-pack.py leg serializes after A or folds into A)
A  →  { D1, D2, D3, D4, D5, D6 }   (Wave D)
A  →  { E1 }   (Wave E)
{ BD-206 fully landed }  →  BD-249   (downstream BD; NOT a BD-206 wave; terminal mirror-subsystem state)
```
**Same-file serialization callouts:** `init-project.sh` (Wave A only); `validate-pack.py` (Wave A O9
Check-43 + O25 Check-29 + C1 empty-template leg — FOLD into Wave A or serialize C1 after A); the 3 trinity
files (D1, one commit); `decompose.sh`+`migrator-core.sh`+`migrate-v10-to-v11.sh` (B1, serialize within);
**`_lib.sh`** (Wave A O1 `:123`/`:136` → B1b O22-proj `:109,121,129` → BD-249 pack constants/accessor/branch
— SERIALIZE across A→B→BD-249, last writer BD-249); **`test-per-entry.sh`** (Wave A O1 `:231-232` → B1b
O22-proj `:219-221` → BD-249 Groups 3/4/8/9 — SERIALIZE; commit-framing flag in B1b governs the shared-file
keyword); **`test-fixtures/build.sh`** (Wave A O23 round-trip removal; the `mirror-generate.sh` source line
goes in Wave A, the FILE deletes in BD-249 — no dangle); **`mirror-generate.sh`** (NOT edited by BD-206;
deleted by BD-249 — terminal).

---

## 7. Scoping-signals + out-of-scope boundaries (no silent defer) — REVISED (SHOULD-1)

**In-scope, surfaced as scoping-signals (the user has SET maximal scope — SIZE callouts, not defers):**
- **SS-1 (tracker, O19 + O25):** ~40+ refs across the COMPLETE 52-file tracker family (EE-11) — 18
  `tracker-*.sh` libs + the 2 `tracker.toml` examples + the live emitter `tracker-init.sh` + the tracker
  tests (`tracker-config-schema-test.sh` Test 7, `tracker-init-test.sh` 3.5, `tracker-agent-read-test.sh`).
  BOUNDED to per-entry→monolith (M-mono) repointing + stale-comment fix + the client `[mirror]`-table drop
  with the Check-29 `mirror_required` flip (DR-4) + the emitter drop (MUST-B) + the lock-step test
  inversions (BLOCKER-A/MUST-A). The tracker→file read-only-mirror feature (M-track: `tracker-mirror.sh`,
  `tracker-header-snapshot.sh`, the reverse-emit, the `tracker-config/*.toml` fixtures) is PRESERVED
  (EE-11 KEEP rows). Tracker stays gated OFF (BD-214) — reconciliation does NOT activate the feature.
  In v11.0 scope.
- **SS-2 (METHODOLOGY, O14):** wholesale plan-model rewrite, in v11.0 scope by the newest binding decision.
- **SS-3 (G-8 ripple, DR-1):** the divergence-gate removal spans TWO force vars + 3 deliverables
  (O7 + O23 + BD-249); a two-pattern grep-zero gate bounds it. In scope (G-8 (C)).
- **SS-5 (DR-2=C dead-mirror removal) — ANCHOR RESOLVED to BD-249:** the user decided both-sides removal.
  **O22-proj** is IN the BD-206 waves; **O22-pack is BD-249** — a SEPARATE `pack-only` BD (Open, Target
  v11.0; verified to exist), sequenced DIRECTLY AFTER BD-206. The prior open question ("BD-206 pack-side
  deliverable line OR a new pack-side BD — Pack Chat/user resolves") is now CLOSED: BD-249 is the anchor.
  BD-206 does NOT carry a Wave F. The blast radius is bounded + measured (EE-8: 12 operational files;
  JOINT grep-zero gate across BD-206 O22-proj + BD-249 O22-pack).

**Explicitly OUT of scope (referenced, NOT absorbed; each has/needs a tracked anchor):**
- **BD-185:** full per-part-file migration + part-membership/serializability drift enforcement. BD-206 does
  the INLINE adopt-as-body + the minimal naming guard (O13) ONLY.
- **BD-246 (NEW, v11.0 launch-blocking):** non-mutation integrity checksum for immutable pack-shipped
  files (recovers G-10 (A)'s loud-tampering signal). Referenced by §16(5); a separate BD.
- **BD-247 (v11.1):** pack-side form-family for the PACK backlog tree. G-5's pack/project symmetry is MOOT
  until the pack side is form-family — that is BD-247, not BD-206.
- **BD-249 (v11.0):** the PACK-side dead-mirror-subsystem removal (O22-pack). Sequenced after BD-206.
- **G-5 v11.1 anchor:** pack-side backlog compliance + no-drift workflows → a NEW/existing v11.1 BD.
- **BD-204 / tracker activation:** deferred indefinitely (BD-214). O19/O25 reconcile dormant code; they do
  NOT activate the feature.
- **G-7 (15 historical `_order.md` refs):** leave as immutable audit history. The `_order`→`_index` sweep
  (Q6/Q10) is operationally a NO-OP.

**The §14 re-derived decision set (G-9 CONFIRMED) is honored as designed:** Q5 (remove `wi-kind`) folds
into O9/O10; D9 (no allowlist — the enum is the bound); Q4 (project no-mirror enforcement = O9 pack leg +
O10 client leg).

## 8. Architect-doc-reality reconciliation chain (rule 8) — REVISED (BD-249 anchor)

This design REALIZES the `_index.md` predesign anticipated in `ARCHITECTURE-BD-185-V2.md` §5.3, its
`-ORDERING-ADDENDUM` §A-1, and `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3 (the former `_order` sidecar).
Per rule 8, the realization chain the coder/planner MUST ship:
- (a) in-code: the `_index.md` generator + validator (O11) carry a docstring naming the realized consumer
  (the impl-plan stream + the conformance check + the `_lib.sh:123` admission set) by file+symbol (never
  line numbers).
- (b) architect-doc addendum: the BD-185 predesign chain + the `_order`→`_index` census
  (`RESEARCH-ORDER-MD-RENAME-CENSUS.md`, 56 refs / 14 files) is cross-referenced as REALIZED-by-BD-206
  (historical maintenance-docs keep their content per G-7; the cross-ref is a forward pointer in the
  BD-206 IMPL report, not a rewrite of the historical doc).
- (c) IMPL-REPORT: links both. (BD-203 as-built shape WINS where the predesign conflicts — §1 ledger / BD-206.md.)

**O22 realizes an in-code TODO (the same reconciliation pattern) — discharged across BD-206 + BD-249.**
The live deferral comment `scripts/lib/per-entry/mirror-generate.sh:12`
`# TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206` is realized as a FULL both-sides
retirement (DR-2=C). Per rule 8, when the realized work lands: (a) BD-249's coder DELETES the file (the
TODO's subject) rather than leaving the comment; (b) the BD-206 IMPL-REPORT records the PROJECT half
(O22-proj) realization (project constants + asserts removed) and the BD-249 IMPL-REPORT records the PACK
half (file deletion + pack constants + dead coverage + the JOINT grep-zero); (c) no historical
maintenance-doc is rewritten (G-7). The TD-TBD marker resolves to the BD-206 (project half) + BD-249 (pack
half) anchors per `deferred-work-tracked-anchor` — the anchor is RESOLVED (BD-249 exists), no longer an
open Pack-Chat question.

## 9. Rules-Applied Verification Block — REFRESHED with reconciliation evidence (FINAL pass appended)

| Rule | Verification evidence (reconciliation-measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §2 now carries 10 EE blocks. The reconciliation ADDED EE-9 (full-battery breakage census: the CI workflow legs `validate-pack.yml:192-202`; the per-deliverable breakage matrix quoting `test-per-entry.sh:231`, `test-init-project.sh:266-280,297-332`, `test-v11-realistic-ot.sh:172`, `test-migrate-decompose:300-307`, the persona arrays) + EE-10 (complete encoding-layer enumeration table; graph-first DISCOVERY query output + grep VERIFICATION over `git ls-files` 1762 tracked) and RE-MEASURED EE-4 (count SUPPORTED, "sufficient" REPLACED), EE-6 (23 operational, new membership), EE-7 (TWO force vars), EE-8 (BD-249 split). Each state-claim has command + verbatim output + HEAD `66c8332`/`775e9cc1` + interpretation + conclusion. | COMPLIANT |
| **verify-full-ci-suite** | BLOCKER-1 root FIXED: EE-9 enumerates the FULL battery (validate-pack + `build.sh --all/--verify` + the shell shard battery, `validate-pack.yml:193,195,202`); Wave-A re-grounded (§6) to land ALL EXISTING-test inversions in the atomic commit; ran `bash scripts/tests/test-per-entry.sh` (57/0) + `python3 validate-pack.py` (14 issues = EE-4) as the baseline measurement. **FINAL pass: ran read-only `tracker-config-schema-test.sh` (40/0, Test 7.1/7.2 PASS), `tracker-init-test.sh` (3.5 PASS), `tracker-config-test.sh` (1.5 PASS), `tracker-agent-read-test.sh` (2.3 PASS) — confirmed all four are baseline-green ONLY because the source carries the old shape; folded the Wave-A inversions (Test 7 + 3.5) + the Wave-E inversion (`tracker-agent-read-test.sh`, the BD-214 C1 recurrence file) into EE-9. The Wave-A full battery NOW includes the tracker tests.** Every wave's green is asserted against the full battery, not validate-pack alone. | COMPLIANT |
| **ci-guard-measure-then-bound** | §5b re-measured EVERY guard against the actual tree: `_format.md` 23 operational (not 26) → grep-zero sized to that set; Check-43 allowlist STRIP/KEEP per measure (DR-3, incl. the phantom `:5094`); Check-29 `mirror_required` flip measured at `:2794-2796` (DR-4); operating-doc allowlists sized to (empty) legitimate set (O26); candidate set from `git ls-files`/`git grep`; SKIP-lenient noted; post-fix clean-run + grep-zero gates stated. **FINAL pass: EE-11 re-measured the tracker family at HEAD `66c8332` — Check-29 `mirror_required` flip ripples sized to 4 surfaces (validator flag + Test 7 + emitter + 3.5); `.dangling-ref-allowlist.txt:101,104` sized to the post-fix legitimate set (SHOULD-A); KEEP rows NOT widened to swallow the M-track feature.** | COMPLIANT |
| **enumerate-encoding-surfaces** | Part-2 mandate DISCHARGED in EE-10: every in-scope surface mapped to its {tests, fixtures, CI steps, validator allowlists/operating-doc sets, tracker.toml, `_lib.sh` constants} in one lock-step table. The 9 findings' asymmetric-coverage gaps closed: `_format.md`↔tests/fixtures/allowlist (O1/O9/O24/O26), `_index.md`↔support-set (O1/O11 MUST-4), rebuilt `_rules.md`↔operating-doc allowlists (O3/O26 MUST-3), tracker.toml↔Check-29 (O25/DR-4 MUST-1), build.sh↔manifest-input/CI (O23 BLOCKER-2), two force vars↔grep-gate (DR-1 MUST-2). 3 surfaces beyond the 9 folded in (phantom `:5094`; test-init Group-5 regen; manifest-inputs coupling). 2 negative controls (Check 40 comment, Check 71 skill-mirror) confirmed OUT. **FINAL pass: EE-11 EXHAUSTIVELY swept the WHOLE tracker family (52 tracked files from `git ls-files`; 21 mirror-encoding surfaces classified KEEP/REPOINT/REMOVE — M-mono REPOINT/REMOVE×13, M-track KEEP×7, mixed×1); the 4 tracker tests + the live `tracker-init.sh` emitter folded into O19/O25; 5 dormant-path surfaces beyond the review's 7 folded in; KEEP rows (tracker→file feature) preserved.** | COMPLIANT |
| **deferral-is-scope-creep / no-deferral-without-user-direction** | All 9 findings are FIX (user-approved); each RESOLVED in this doc (Reconciliation log). No deferral: the NEW surfaces (phantom ref, Group-5 regen, manifest coupling) are FOLDED into O9/O24/O4/O23, not deferred. O22-pack is BD-249 (a USER-AUTHORIZED separate v11.0 BD, not a defer — symmetry of the correct solution, scoped to its own commit by Check-36). **FINAL pass: all 7 confirmation findings FIX-now (no defer); SHOULD-C CLASSIFIED IN-SCOPE for BD-206 (live project-side prose, NOT pack-side/BD-249, NOT historical) per the explicit-classification mandate; SHOULD-D CLASSIFIED KEEP/NO-BREAK (tracker-mode parse fixture, M-track) — neither silently dropped.** | COMPLIANT |
| **tracker-portability** | The reconciliation adds NO vendor coupling: O19/O25 reconcile dormant M-mono assumptions behind the existing TrackerProvider abstraction (BD-060); the KEEP rows (EE-11 11-13,17-20) PRESERVE the tracker→file feature as-is; tracker stays gated OFF (BD-214) — the sweep does NOT activate the feature, introduce GH-specific primitives, or remove the portable abstraction. | COMPLIANT |
| **operating-docs-no-history-no-bloat** | The doc deliverables designed (O3 `_rules.md`, O14 METHODOLOGY, O15 trinity, O16 PM-CHAT, O18 skills, O19 tracker comments, O21 MIGRATION, O25 tracker.toml comments) all carry the directive: ZERO history/audit text, ZERO deferred-feature mentions (strip "until BD-206"), terse + structured. O26 + O3 ENFORCE this (the operating-doc check goes RED if the rebuilt `_rules.md` smuggles history). This DESIGN doc adds only a one-line provenance reconciliation note (no history bloat). | COMPLIANT |
| **dependency-direction-placement** | O5 preserves `_SANCTIONED_PACK_SIDE_SHIPPED` + the install map UNCHANGED (Check 47 set-equality); no new pack-side file is made a client dep; no project deliverable becomes a pack-op runtime dep. build.sh (O23) stays pack-side (a fixture builder, not shipped). | COMPLIANT |
| **architect-doc-reality-reconciliation** | §8 ships the (a) docstring / (b) addendum cross-ref / (c) IMPL-REPORT chain for `_index.md`; the O22 TODO realization is split across BD-206 (project, IMPL-REPORT) + BD-249 (pack, file deletion + IMPL-REPORT); no line numbers; BD-203 as-built wins. | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | Ran ONLY read-only git (`git rev-parse`, `git grep`, `git ls-files`, `git status --short`, `git diff --name-only`, `git branch`) + read-only `python3 validate-pack.py` + read-only `bash test-per-entry.sh` (no fixtures mutated; scratch tmpdirs) + file Reads + a read-only graphify query. The SOLE write is this design doc (Bash heredoc build + `mv` into place — the permitted single output). No state-changing git verb; no destructive op on the repo. | COMPLIANT |
| **graph-first-context** | DISCOVERY ran the graph FIRST (EE-10's `graphify query … --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500`, BFS depth=2, 107 nodes) against the INJECTED path (never recomputed from my toplevel); it surfaced the candidate set, fully contained within the grep ground-truth. VERIFICATION via grep/Read (P2 precision: exact file:line, counts). G2 not needed. | COMPLIANT |
| **spawn-unique-naming** | Operating as `architect-bd206-reconcile-2` (the FINAL reconciliation header line + this row); prior reconciler `architect-bd206-reconcile`; author `architect-bd206-nomirror`. | COMPLIANT |
| **rules-applied-verification-block / agents-read-rule-docs-in-full** | This block exists with per-rule reconciliation evidence. READ-IN-FULL: the edit-target ARCHITECTURE-BD-206.md (861 lines, two pages); ADVERSARIAL-ARCH-REVIEW-BD-206.md (257 lines, full); CENSUS (379 lines, two pages); DECISIONS-BD-206-RESTART.md (536 lines, full); INVESTIGATION-BD-206-SIDECARS.md (238 lines, full); backlog/BD-206.md + BD-249.md (full); pack-root CLAUDE.md `## Pack memory` (in-context, full). Named memory files confirmed present + read: feedback_architect_planner_empirical_evidence.md (14 ln), feedback_ci_guard_design_measure_then_bound.md (14 ln), feedback_verify_full_ci_suite.md (57 ln), feedback_agent_output_rules_applied_block.md (14 ln), feedback_agents_read_rule_docs_in_full.md (133 ln); feedback_deferral_is_scope_creep.md ABSENT as a standalone file → relied on the CLAUDE.md `deferral-is-scope-creep` rule text (in-context, full), as the prompt permitted. **FINAL pass (`architect-bd206-reconcile-2`) READ-IN-FULL: this ARCHITECTURE-BD-206.md edit-target (all pages); CONFIRM-ARCH-REVIEW-BD-206.md (331 lines, full — the 7 findings); pack-root CLAUDE.md `## Pack memory` (in-context, full); feedback_verify_full_ci_suite.md (58 ln), feedback_ci_guard_design_measure_then_bound.md (15 ln), feedback_architect_planner_empirical_evidence.md (15 ln), feedback_tracker_portability.md (21 ln); feedback_deferral_is_scope_creep.md again ABSENT → CLAUDE.md rule text. Anti-contamination: NO other prior BD-206 doc opened.** | COMPLIANT |

### Reconciliation log — each finding → RESOLVED + fix location

| Finding | Sev | RESOLVED — where in this doc |
|---|---|---|
| **BLOCKER-1** Wave-A not full-battery green | BLOCKER | EE-9 (full-battery breakage census + per-deliverable matrix); §0 fact #3; EE-4 conclusion corrected; §6 Wave-A EXPANDED + re-grounded against the full battery; §1 §16(5) map. |
| **BLOCKER-2** `test-fixtures/build.sh` | BLOCKER | O23 (NEW: round-trip redesign, mirror-source removal, manifest/Check-62 interplay, sequencing vs BD-249 file deletion); EE-9 matrix row; EE-10 row; §6 Wave A. |
| **BLOCKER-3** `_format.md` lock-step incomplete | BLOCKER | EE-6 (RE-MEASURED 23 operational, new membership incl. the Check-43 PASS fixture, `:5503`, `:8225`, `:5094`); O1 (expanded lock-step); O9 (Check-43 5503/5094/8225); O24 (NEW: Check-43 fixtures + test required-set + T9 + the 2 skeletons). |
| **MUST-1** tracker.toml examples + Check 29 | MUST | O25 (NEW: client `[mirror]` drop + pack-example comment strip + `tracker-init-test.sh`); DR-4 (Check-29 `mirror_required` True→False flip at `:2794-2796`, lock-step); §6 Wave A (lock-step placement); EE-10 row. |
| **MUST-2** 2nd force var `PE_FORCE_OVERWRITE_MIRROR` | MUST | EE-7 (RE-MEASURED, TWO vars enumerated); DR-1 (two-pattern grep-zero gate); O7 (both-var removal set); O23 (build.sh consumers); BD-249 (mirror-generate consumers). |
| **MUST-3** operating-doc allowlists | MUST | O3 (lock-step constraint + zero-history authoring); O26 (NEW: remove dead `_format.md` + `_rules.md` exemptions; fail-loud operating-doc check). |
| **MUST-4** `_index.md` admission | MUST | O1 (ADD `_index.md` to `_lib.sh:123`); O11 (admission lock-step + test); O9 (empty-template leg admits it); EE-10 row. |
| **SHOULD-1** Wave-F vs BD-249 | SHOULD | Wave F DROPPED (§6); O22 split (O22-proj in BD-206; O22-pack=BD-249); DR-2 revised; §7 SS-5 resolved to BD-249; §8 anchor resolved. |
| **SHOULD-2** §16(5) paper-coverage | SHOULD | §1 §16(5) map updated (EE-9 delivers the green EXISTING battery per wave); §5b "Full CI battery green at Wave A" row; resolved by the BLOCKER-1/2/3 fixes. |

**FINAL reconciliation — the confirmation review's 7 findings (all FIX, all RESOLVED):**

| Finding | Sev | RESOLVED — where in this doc |
|---|---|---|
| **BLOCKER-A** `tracker-config-schema-test.sh` Test 7 pins Check-29 `mirror_required=True` → inverts under the Wave-A flip | BLOCKER | O25 (Test 7 inversion bullet); DR-4 (3-surface ripple); EE-9 Wave-A inversion-set row; EE-11 row 4; §6 Wave-A composition + bullet + "Why O25 in Wave A". |
| **MUST-A** `tracker-agent-read-test.sh:71,190-192` seeds a monolith + asserts the read → flips under O19 | MUST | O19 (test lock-step bullet); EE-9 Wave-E row; EE-11 rows 7-8; §6 Wave E1 (the BD-214 C1 recurrence file). |
| **MUST-B** the live emitter `tracker-init.sh:359-376` still WRITES the client `[mirror]` table | MUST | O25 (emitter-drop bullet + `tracker-init-test.sh` 3.5 inversion); DR-4; EE-11 rows 5-6; §6 Wave A. |
| **SHOULD-A** `.dangling-ref-allowlist.txt:101,104` stale project-mirror tokens | SHOULD | O26 (SHOULD-A bullet: REMOVE both tokens, KEEP `:95,98` pack-monolith names); EE-10 tracker row; EE-11 row 21; §6 Wave A. |
| **SHOULD-B** `test-fixtures/README.md` round-trip prose | SHOULD | O23 (doc-prose lock-step bullet); EE-10 build.sh row; EE-11 (folded note); §6 Wave A. |
| **SHOULD-C** `MERGE-STRATEGY.md:274-275` project-monolith prose | SHOULD | O1 (doc-ref lock-step, SHOULD-C bullet) — **CLASSIFIED IN-SCOPE for BD-206** (live project-side merge-dispatch operating-doc prose BD-206 invalidates; NOT pack-side/BD-249, NOT historical); EE-10 trinity/docs row; §6 Wave A. |
| **SHOULD-D** `tracker-config-test.sh:73` `mirror.enabled` assert | SHOULD | EE-11 row 18 — **CLASSIFIED KEEP / NO-BREAK** (`:73` reads the `tracker-mode.toml` tracker-mode fixture; `tracker-config.sh` is a pure TOML parser; the `[mirror]` here is the M-track feature, not the M-mono assumption) — no edit; §0 final-outcome block records the classification. |

**Class-closure (the Part-2 mandate):** the under-counted-blast-radius class — operational (round 1) → test/fixture (round 2) → tracker-test+Check-29 (round 3), ALL in the tracker family — is CLOSED by EE-11's exhaustive 52-file sweep + 21-surface KEEP/REPOINT classification. Surfaces beyond the review's 7 (folded, not dropped): `tracker-doctor.sh:173-174` (EE-11 row 9), `tracker-migrate-forward.sh:1395,2149-2162` (row 10), `tracker-promote.sh` project-monolith paths (row 14), `tracker-phase-task.sh` (row 15), `scripts/tracker-migrate.sh` project share (row 16) — all M-mono dormant → REPOINT under O19 (Wave E). No fourth surface remains unclassified.

**Additional encoding surfaces Part-2 surfaced beyond the 9 (folded in, not dropped):** (1)
`validate-pack.py:5094` PHANTOM pack-side `/backlog/_format.md` ref → O9/O24 STRIP; (2)
`test-init-project.sh` Group-5 (4.6) `per_entry_regenerate_mirror` snapshot/re-invocation `:386-394,416,427`
→ O4 + EE-8/BD-249 dead-coverage set; (3) `manifest-inputs.sh:56,58` build.sh-as-manifest-input + BD-228
Check-62 coupling → O23. **Negative controls confirmed OUT:** `test-validate-pack-check-40.sh:645`
(comment, already correct), `test-validate-pack-check-71.sh` (skill-mirror, not project-mirror).

**HEAD designed at:** `775e9cc139ef3fdde3d499198894a7bef70145e1` — **Reconciled at:** `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7` (working tree: 8 uncommitted deletions — 7 sidecars + 1 maintenance RESEARCH doc, matching EE-4) — **Date:** 2026-06-26 — **Author:** `architect-bd206-nomirror` — **Reconciled by:** `architect-bd206-reconcile` — **Final reconciliation by:** `architect-bd206-reconcile-2`.

### Anti-contamination attestation
No prior BD-206 ARCHITECTURE / PLAN / REVIEW / RECONCILE / ADVERSARIAL doc beyond the permitted inputs
was read. The FIRST reconciliation pass (`architect-bd206-reconcile`) used the current ARCHITECTURE-BD-206.md
edit-target + the (now-superseded) first ADVERSARIAL-ARCH-REVIEW-BD-206.md. The FINAL reconciliation pass
(`architect-bd206-reconcile-2`) read ONLY the current ARCHITECTURE-BD-206.md edit-target + the
CONFIRM-ARCH-REVIEW-BD-206.md (the 7 confirmation findings) + the CENSUS + DECISIONS-BD-206-RESTART.md +
INVESTIGATION ledgers + backlog/BD-206.md + backlog/BD-249.md + the V2/production GOLD (read-only) + the
live repo at HEAD `66c8332`. The final pass did NOT open: the first ADVERSARIAL-ARCH-REVIEW report, the
ADVERSARIAL-PLANNER review, any prior RESTART/RECONCILED/FINAL architecture or plan, or anything under
`/tmp/bd206-REJECTED-DO-NOT-READ/` (anti-contamination + reconciliation-instance-independence).
