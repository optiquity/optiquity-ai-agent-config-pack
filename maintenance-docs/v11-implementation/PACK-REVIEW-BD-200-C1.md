# PACK-REVIEW — BD-200 commit C1 — single-source capability tables + behavior-preserving refactor

**Role:** pack-reviewer (fresh, read-only). **Branch:** `v11-dev`. **HEAD:** `356afca41733e1f6a504a1eb88a544bde1ae43e4`. **Date:** 2026-06-04.
**Scope reviewed:** the C1 working-tree changes (uncommitted) — T1 (NEW `project-template/scripts/capability-tables.sh`) + T2 (behavior-preserving edit to `scripts/add-capability.sh`) + the forced lock-step test retarget + the regenerated manifest.
**Against:** `PLAN-BD-200.md` §2 T1/T2, §3 dep #4, §5, §8; `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.5/§4.3; the re-scoped BD-200 entry. Every claim independently re-measured (I did not trust the IMPL-REPORT).

---

## VERDICT: CLEAN (no BLOCKER / no MUST). Two SHOULD/NIT cross-reference findings, both already correctly surfaced by the coder as out-of-C1-scope and disposition-pending — they do NOT block C1.

C1 is a faithful, behavior-preserving single-source extraction. No-drift re-proven byte-identical across all 21 capability args. R1 placement correct ($PACK-unset still dies at A0, exit 10). Boundary clean (zero pack-self tokens on the client-shipped file). `validate-pack.py` PASSED; 19/19 tests pass; manifest reproducible and correctly bounded to the three v11-* rows. Scope is exactly T1+T2+forced-lock-step.

---

## Findings

### F1 — `scripts/lib/detect.sh:302` carries a now-stale cross-reference to the moved symbol — SHOULD (out of C1 scope; correctly surfaced as POQ-C1-1)

`scripts/lib/detect.sh` is ACTIVE runtime source (it ships to clients; it is in `_SANCTIONED_PACK_SIDE_SHIPPED`). Its D5 reciprocal-mapping comment cites the OLD home of the moved function:

```
300:            # D5 deployment surface — reciprocal of the `deployment:apple`
301:            # and `deployment:linux-container` rows in
302:            # scripts/add-capability.sh::capability_skills(). Earlier
```

`capability_skills()` now lives in `project-template/scripts/capability-tables.sh`, so the cite names the wrong file. **Comment-only — zero runtime impact** (verified: all C1 checks green; the comment is not parsed). Per `enumerate-encoding-surfaces` this is a surface that ENCODES the old location and should be updated in lock-step with the move.

- **Severity: SHOULD.** It is a real stale cross-ref in active source, but comment-only and load-bearing nowhere.
- The coder did the right thing: `detect.sh` is NOT in T1/T2's affected-file set (PLAN §1), so editing it in C1 would be scope creep; the coder surfaced it as **POQ-C1-1** ("surfaced not silently fixed", honoring the GOALS contract) and recommended routing a one-line fix into a later BD-200 `scripts/`-touching commit per `architect-doc-reality-reconciliation`. I concur.
- **Recommended fix (later commit, not C1):** repoint the cite to `project-template/scripts/capability-tables.sh::capability_skills()`. No anchor is load-bearing today; tracking it on the open BD-200 entry / a later BD-200 commit satisfies `deferred-work-tracked-anchor`.

### F2 — `supporting-docs/METHODOLOGY.md:1455-1465` still says the three tables are "in `scripts/add-capability.sh`" — NIT (already plan-scheduled for C4)

The active client-shipped METHODOLOGY Procedure 6 tail reads:

```
1462: **Adding a new capability row.** A new pack-supported dimension /
1463: value extends three parallel surfaces in `scripts/add-capability.sh`:
1464: `capability_skills()` (skill list), `capability_files()` (conditional
1465: files to copy), and `capability_install_checks()` (tool probes + ...
```

This now names the wrong home (the three tables moved to `capability-tables.sh`). However, **this entire Procedure-6 tail is explicitly slated for redesign/strip in T5 → C4** (PLAN §2 T5 "strip ... the 'Adding a new capability row … three parallel surfaces in scripts/add-capability.sh' pack-internal tail"; EEB-PROC6-CONTAMINATED measures lines 1457/1463 as redesign targets). So this surface is already tracked for lock-step correction in a later BD-200 commit and is NOT a C1 omission.

- **Severity: NIT.** Stale, but pre-scheduled; no new finding/anchor needed.
- **Recommended fix:** none for C1 — confirm C4 (T5) removes/corrects it as planned.

### Non-findings (verified NOT stale — historical/spec records, correctly left untouched)

- `pack-ops/BACKLOG.md:2160 / 2171 / 2182` — File/Symbol specs of BD-158 / BD-189(swiftdata) / BD-189(protobuf), all **Status: Resolved** (verified at lines 2157/2168/2179). These are historical records describing the state when those BDs ran; not live cross-refs. Correctly untouched (`pack-ops/BACKLOG.md` is PM-only and not in C1 scope regardless).
- `pack-ops/BACKLOG.md:3287 / 3293` — the BD-200 entry's own problem statement, which deliberately describes the PRE-refactor state ("today inline in `scripts/add-capability.sh`"). Accurate as written.
- `pack-ops/BACKLOG.md:4522` — a Resolved record (BD-048). Historical.
- `maintenance-docs/**` (archive + planning + IMPL/PLAN/ARCH-BD-200) — pack-internal historical/design docs, not client surfaces, not lock-step encoding surfaces of the runtime contract.
- `scripts/add-capability.sh:36-38` header comment — describes the discovery table as "parallel to capability_skills() and capability_files()"; it does NOT assert a home location, and all three are still called from this script (L246/L249/L477), so it remains semantically accurate.

---

## Per-item verification (each independently measured)

### Item 1 — T1 extraction fidelity — PASS
- **Non-comment code byte-identical.** Extracted the three functions from `git show 356afca:scripts/add-capability.sh` and from the new file, stripped comment-only lines, diffed: `>>> BYTE-IDENTICAL non-comment code <<<`. All `case` arms, `echo` strings, and `:::`-delimited heredoc rows are byte-for-byte preserved.
- **Comments differ — expected and correct.** The only deltas are comment lines: pack-self tokens (`BD-141`/`BD-162`/`BD-158`/`BD-157`/`BD-156`/`BD-144`/`BD-048`, the `maintenance-docs/...PYTHON-OBSERVABILITY.md` path, `add-capability.sh`/`init-project.sh`/`pack_skill_coverage_for()` refs) were neutralized for the client-shipped surface. The plan's "verbatim" requirement is on the table OUTPUT (heredocs + `:::` rows), which is preserved; comment cleaning is mandated by the boundary requirement.
- **Sourceable-only.** `source project-template/scripts/capability-tables.sh` → `RC=0`, zero stdout/stderr. `bash -c 'source ...; declare -F'` → exactly `capability_files`, `capability_install_checks`, `capability_skills`. No top-level executable statements (the only column-0 matches are `:::` heredoc-internal content + `EOF` terminators, all inside function bodies). `bash -n` clean.
- **Docstring names consumer by file+symbol, no line numbers:** "Its consumer is the sibling `scripts/activate-capability.sh`, which sources this file (`source "$(dirname "$0")/capability-tables.sh"`)". Satisfies `architect-doc-reality-reconciliation`.

### Item 2 — Behavior-preservation (no-drift) — PASS (re-proven independently)
Sourced the PRE-refactor functions (from `git show 356afca:`) and the POST-refactor `capability-tables.sh`; dumped `capability_skills`/`capability_files`/`capability_install_checks` output **+ return code** for all 19 real args plus 2 unknown-arg defaults (`bogus:unknown`, `unknown:thing`) — exercising the `*) return 1` / `*) echo ""` / `*) :` default arms:

```
old lines: 213  new lines: 213
>>> EMPTY DIFF — NO DRIFT CONFIRMED across all 21 args <<<
```

This is my own measurement, not the coder's. Behavior-preserving acceptance MET.

### Item 3 — R1 placement (load-bearing) — PASS
- **(a) No top-level source.** The only `source "$tables"` is at `scripts/add-capability.sh:140`, inside `_load_capability_tables()` (L133). No top-level `source "$PACK/..."`.
- **Call path:** `_load_capability_tables` is invoked once, as the first statement of `stage_a1_resolve` (L241). `main()` runs `stage_a0_preflight` (L629) → `stage_a1_resolve` (L630). `$PACK` is validated in A0 at L187 (`die "PACK environment variable not set (or pass --pack <path>)" "$EXIT_PACK_INVALID"`).
- **(b) $PACK-unset regression — ran it.** `env -u PACK bash scripts/add-capability.sh --project /tmp --add language:python` dies at A0 with `error: PACK environment variable not set (or pass --pack <path>)`, **exit 10**. Compared against the PRE-refactor file (run from the `scripts/` context for correct `SCRIPT_DIR`): also exit 10, same message. No regression — the source never executes before `$PACK` validation. A missing-tables-file path additionally dies with `EXIT_PACK_INVALID`.

### Item 4 — Consumer logic preserved — PASS
`warn_if_missing_skills()` (L155) and `probe_tool_present()` (L172) remain defined in `add-capability.sh`. Neither is defined in `capability-tables.sh` (the only mention there is an incidental comment reference to `warn_if_missing_skills()` behavior, not a definition).

### Item 5 — Boundary — PASS
`grep -nE 'pack-[a-z]+|maintenance-docs/|BD-[0-9]+|pack-ops/|from the pack|\$PACK|init-project|add-capability|pack_skill_coverage|\.pack-'` on `capability-tables.sh` → **ZERO pack-self tokens**. The two retained `scripts/lib/detect.sh::<fn>()` comment refs are boundary-legitimate: `detect.sh` ∈ `_SANCTIONED_PACK_SIDE_SHIPPED` (`validate-pack.py:4158-4161`) and ships client-side (installed/sourced at `scripts/lib/detect.sh`), so naming it on a client surface references a client-resident file, not a pack-self leak (Check 43 still fully walks + enforces sanctioned files per the L4206 comment). Check 43 (157 files walked, zero bare cross-refs) and Check 37 (169 files, zero contamination) both PASS with the new file in the walk set.

### Item 6 — enumerate-encoding-surfaces / cross-ref completeness — TWO findings (F1 SHOULD, F2 NIT)
Full-repo grep (`*.sh`/`*.md`/`*.py`, excl `.git/`) for the three symbols + `add-capability.sh`-as-home. After excluding the 4 in-scope files, the historical BACKLOG records (all Resolved/spec), and pack-internal `maintenance-docs/**`, exactly two ACTIVE surfaces still encode the old location: `detect.sh:302` (F1) and `METHODOLOGY.md:1455-1465` (F2). Both are correctly handled — F1 surfaced as POQ-C1-1 (out of scope, tracked), F2 pre-scheduled for C4/T5. No silent omission.

### Item 7 — Manifest — PASS
Diff shows exactly the three `v11-*` rows moved; `v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev` unmoved. I **independently re-ran** `bash test-fixtures/build.sh --all --clean` → my regen `>>> MANIFEST REPRODUCIBLE — matches coder's regen exactly <<<` (idempotent; build rc=0). Confirmed `test-fixtures/v11-flat-file/scripts/capability-tables.sh` exists (S5-installed) and is absent from `test-fixtures/v10-minimal/scripts/`. Manifest regen satisfies `regenerate-manifest-v11-surface` (C1 touches `project-template/` + `scripts/`).

### Item 8 — Guards — PASS
`python3 scripts/validate-pack.py` → `PASSED — all checks clean` (the only non-OK lines are 14 pre-existing Check 48 advisory WARNs on `pack-ops/{BACKLOG,CHANGELOG}.md` removed-doc citations — advisory-only, exit code unaffected, unrelated to C1). Check 41 (37 entries, 0 drift) and Check 47 (set-equality `['scripts/lib/detect.sh', 'scripts/pack-help.sh']` — frozen 2-tuple, no growth) both green; the new file is `project-template/`-located and invisible to Check 47. Check 22 green.

### Item 9 — Scope — PASS
`git status --short` (excl. the IMPL report) = exactly the 4 expected files: `project-template/scripts/capability-tables.sh` (new), `scripts/add-capability.sh`, `scripts/tests/test-add-capability.sh`, `test-fixtures/manifest.txt`. No `activate-capability.sh` / `init-project.sh` / docs / pool / `pack update` logic touched. The `test-add-capability.sh` edit is a forced lock-step retarget (replaces the fragile `sed`-extract of `capability_install_checks()` from `add-capability.sh` with a direct `source "$CAP_TABLES_SH"`) — in-scope per C1-prompt item 4 + `enumerate-encoding-surfaces`; mechanical, no assertion changes; 19/19 PASS. Not scope creep.

---

## Note on a transient test artifact (full disclosure)
To compare the PRE-refactor `$PACK`-unset exit code under correct `SCRIPT_DIR` resolution, I briefly wrote a temp copy of HEAD's `add-capability.sh` into `scripts/` and removed it immediately (`rm -f`), and I re-ran `build.sh` (which is idempotent — the working tree afterward is byte-identical to the 4 expected files; verified via `git status --short`). No source file was modified and no git state-changing verb was run. This review wrote only this one report file.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read IN FULL: `CLAUDE.md` incl. `## Pack memory` (session context, full); `PLAN-BD-200.md` (235 lines, full); `IMPL-BD-200-C1.md` (401 lines, full — claims re-verified independently, not trusted); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.5 + §4.3 (extracted + read); BD-200 + BD-202 entries in `pack-ops/BACKLOG.md` (3273-3325, full). Curated memory rules applied from `CLAUDE.md ## Pack memory` (enumerate-encoding-surfaces, boundary/no-pack-self, pack-project-separation, dependency-direction-placement, regenerate-manifest, rules-applied-block). No prior C1 review existed; none read. | COMPLIANT |
| enumerate-encoding-surfaces | Full-repo grep (`*.sh`/`*.md`/`*.py`, excl `.git/`) for `capability_skills`/`capability_files`/`capability_install_checks` + `add-capability.sh`-as-home. Classified every hit: 2 ACTIVE stale surfaces flagged (`detect.sh:302` F1 SHOULD; `METHODOLOGY.md:1455-1465` F2 NIT, plan-scheduled C4); BACKLOG hits verified Resolved/spec (lines 2157/2168/2179 `Status: Resolved`); maintenance-docs historical. Lock-step gap surfaced, severity-graded, none silently dropped. | COMPLIANT |
| empirical verification | Every verdict backed by a command I ran + quoted output: non-comment-code diff (`BYTE-IDENTICAL`), 21-arg no-drift dump (`EMPTY DIFF ... 213 lines`), `$PACK`-unset run (exit 10, both old+new), source RC=0/`declare -F`, token grep (`ZERO`), `validate-pack` (`PASSED`), manifest regen (`REPRODUCIBLE`), tests (19/0), scope `git status`. No assertion without evidence. | COMPLIANT |
| boundary / no-pack-self-in-project | `grep -nE 'pack-...|maintenance-docs/|BD-[0-9]+|pack-ops/|from the pack|$PACK|add-capability|init-project|pack_skill_coverage|.pack-'` on `capability-tables.sh` → ZERO. Retained `detect.sh` refs are sanctioned-shipped client-resident (`validate-pack.py:4158-4161`). Check 43/37 PASS with file in walk set (157/169 files). | COMPLIANT |
| pack-project separation + dependency-direction | Pack-side `add-capability.sh` sources `$PACK/project-template/scripts/capability-tables.sh` (pack→pack). New file is `project-template/`-located client deliverable, ships via S5 glob, invisible to Check 47; `_SANCTIONED_PACK_SIDE_SHIPPED` frozen 2-tuple unchanged (Check 47 set-equality green). No project-side file became a pack runtime dependency. | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly C1 (4 files); led with verdict + findings; no edge-case sprawl. Findings carry measured evidence; non-findings explicitly classified. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule name + quoted/measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL attestation row present. | COMPLIANT |
| agents-never-commit | Only read-only/idempotent verbs: `git status`/`diff`/`show`/`rev-parse`, `grep`/`sed`/`awk`/`diff`/`bash -n`, `validate-pack.py`, `build.sh` (idempotent), test run, one transient `rm -f` of a self-created temp file. NO `git add`/`commit`/`push`/`tag`/`stash`. HEAD unchanged at `356afca`. Sole file write = this report. | COMPLIANT |

**End of PACK-REVIEW — BD-200 C1. Verdict: CLEAN (2 SHOULD/NIT cross-ref findings, both out-of-C1-scope and already tracked; no BLOCKER, no MUST).**
