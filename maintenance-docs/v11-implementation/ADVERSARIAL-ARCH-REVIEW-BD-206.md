# ADVERSARIAL ARCHITECTURE REVIEW — BD-206 (no-monolith-mirror, form-family conversion)

**Reviewer:** `reviewer-bd206-arch-adversarial` (FRESH pack-reviewer; NOT the design author, NOT any prior reviewer).
**Review target:** `/Users/david/Developer/_tmp/pack-handoff-bd206-restart/ARCHITECTURE-BD-206.md` (861 lines, read in full).
**Reviewed at:** HEAD = `775e9cc139ef3fdde3d499198894a7bef70145e1`, branch `v11-dev`, **2026-06-26**.
**Method:** independent re-derivation (graph-first discovery + own `git grep` censuses over `git ls-files`), empirical re-verification of every EE claim against the GOLD + the live repo, full-CI-battery atomicity test. Read-only on pack + OT; sole write = this report.
**Anti-contamination:** no prior BD-206 review/reconcile/adversarial report, no RESTART/RECONCILED/FINAL architecture or plan, nothing under `/tmp/bd206-REJECTED-DO-NOT-READ/` was read. Inputs: the current ARCHITECTURE-BD-206.md + CENSUS + DECISIONS + INVESTIGATION + the GOLD + the live repo.

---

## OVERALL VERDICT: **NEEDS-REWORK**

**3 BLOCKERs + 4 MUSTs.** The design's empirical foundation (the schema EE-1/EE-2/EE-3, the 14-failure count EE-4, the call-site censuses EE-7/EE-8, the bold-pair anchor G-5) is largely SOUND and independently reproduced. But the design repeats the prior design's signature failure mode — **an under-counted blast radius** — in three specific ways that are launch-blocking:

1. **Wave-A is NOT atomic-and-sufficient for green CI** (BLOCKER-1). EE-4 measured `validate-pack.py` ONLY; the full CI battery (which §15 + the `verify-full-ci-suite` memory mandate) runs the shell tests + `build.sh --verify`, which the Wave-A deliverable set turns RED.
2. **`test-fixtures/build.sh` is under-specified** (BLOCKER-2): it sources the to-be-deleted `mirror-generate.sh`, requires the deleted monolith, is itself a manifest fixture-input, and is assigned to NO wave.
3. **`_format.md` elimination misses its test/fixture lock-step set** (BLOCKER-3): EE-6 / O1 omit ~9 `_format.md`-asserting surfaces (tests, fixtures, the validate-pack allowlist + operating-doc set).

Per-dimension verdicts: **D1 Completeness FAIL · D2 Correctness PASS-with-MUST · D3 Soundness PASS-with-MUST · D4 Risk/sequencing FAIL · D5 §16 PASS-with-SHOULD · D6 O21/O22 PASS-with-MUST.**

---

## DIMENSION 1 — COMPLETENESS (the priority; the prior design's failure mode) — **FAIL**

### BLOCKER-1 — Wave-A clears `validate-pack.py` but turns the SHELL TEST BATTERY red; it is NOT sufficient for green CI
**Severity: BLOCKER.** **Design location:** §0 fact #3 + EE-4 ("Wave-A atomicity is necessary AND sufficient for green CI") + §6 Wave A + §15 binding requirement.

The design rests its central atomicity claim on EE-4, which measured ONLY `python3 scripts/validate-pack.py`:
```
$ python3 scripts/validate-pack.py 2>&1 | grep -E 'Check (39|41)|FAILED'
Check 39 ... (7 FAILs on the 7 deleted sidecars)
Check 41 ... (7 FAILs on the same 7)
FAILED — 14 issue(s) found
```
The 14-count is correct (verified). But CI runs MORE than validate-pack. `.github/workflows/validate-pack.yml`:
```
192:  if python3 scripts/lib/ci-shard-plan.py --shard ... --needs-fixtures; then
193:      bash test-fixtures/build.sh --all --clean
195:      bash test-fixtures/build.sh --verify
202:  - name: run shard ${{ matrix.shard }}   # the {scripts/test*.sh + scripts/tests/*.sh + fixture-dependent} battery
```
Wave A = `O0+O1+O2+O3+O4(init-side)+O8` (§6). O1 deletes `_format.md` from the template; O4 stops greenfield mirror generation. The full battery has EXISTING tests that assert the OLD shape and are NOT in the Wave-A deliverable set:

- `scripts/tests/test-init-project.sh:266-268` — asserts changelog `_format.md` PRESENT: `t_fail "4.2 ... _format.md missing (asymmetry violated)"`. After O1 this FAILS. (verified, quoted from file.)
- `scripts/persona-contracts/contract-greenfield.sh:239` — expected-files array includes `"docs/project/changelog/_format.md"` AND (240-244) the three monoliths `"docs/project/BACKLOG.md"`, `"docs/project/IMPLEMENTATION-PLAN.md"`, `"docs/project/CHANGELOG.md"`. After O1+O4 the persona contract (run via `test-persona-contracts.sh`) FAILS. (verified, quoted.)
- `scripts/tests/test-per-entry.sh:231-232` — asserts `project-changelog known supporting includes _format.md`. After O1 FAILS.
- `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh:172` — `assert_file "A.13 changelog/_format.md present"`. After O1 FAILS.
- `scripts/tests/test-init-project.sh` 4.3/4.4/4.5 mirror-presence + byte-identity asserts — after O4 FAIL (the design notes these only under O22's lock-step / EE-8, NOT in Wave A).

**The §15 binding requirement is "the tree goes (and stays) GREEN at the first wave."** The Wave-A set as scoped cannot satisfy this: it makes `validate-pack.py` green and the shell battery red. EE-4's conclusion is provably wrong because it scoped the measurement to one tool. **The Wave-A deliverable set MUST be expanded to include the test/fixture/persona-contract `_format.md`+mirror asserts** (or those tests must move into Wave A), OR the atomicity claim re-grounded against the full battery. As written, the first commit pushes a red tree — exactly what §15 forbids.

### BLOCKER-3 — `_format.md` elimination (O1) misses ~9 lock-step surfaces; EE-6 "26 files" is an under-count of the operational set
**Severity: BLOCKER.** **Design location:** EE-6 ("26 tracked files") + O1 lock-step set + §5b row "`_format.md` FORBIDDEN (O1) … 26 refs removed → grep-zero".

My independent census:
```
$ git grep -lE '_format\.md' | wc -l            → 97   (design says EE-6 = 26)
$ git grep -lE '_format\.md' -- ':!maintenance-docs/' ':!backlog/' ':!changelog/' | wc -l → 23  (operational set)
```
The maintenance-docs/backlog/changelog history is correctly exempt. But the **23-file operational set** is larger than the files O1's lock-step enumerates, and EE-6's itemized list + O1 omit these `_format.md`-bearing OPERATIONAL surfaces (each must change or the FORBIDDEN/grep-zero gate fails, or a test asserts the forbidden file):

1. `scripts/tests/test-init-project.sh:221,227,239,246-248,256-258,266-268,309-310,316,333` — the 4.2 asymmetry asserts + the 4.5 byte-identity (`CHANGELOG.md == _intro.md + '---' + _format.md`). **Not in O1.**
2. `scripts/tests/test-per-entry.sh:231-232` — `_format.md` in the known-supporting assert. **Not in O1.**
3. `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh:143,172,183-188` — A.13/A.15 `_format.md` present/absent asserts. **Not in O1.**
4. `scripts/persona-contracts/contract-greenfield.sh:212,231,239` + `contract-migration.sh:422,458,471` — `_format.md` in the expected-files arrays. **Not in O1.**
5. `scripts/tests/fixtures/project-side-refs/project-side-pass-same-dir-skeleton.md:13,21` + `…fail-per-entry-skeleton.md:14` — fixtures that say "Bare refs to `_intro.md`, `_rules.md`, `_format.md` MUST PASS Check 43 via the allowlist." Consumed by `test-validate-pack-check-43.sh` (Group 5). **Not in EE-6 or any deliverable.**
6. `scripts/validate-pack.py:5503` — `"_format.md": "Per-entry tree format sibling (same-dir resolution)"` in the Check 43 allowlist. EE-6 cites 5504-5507/5590-5593 (mirror) but NOT 5503 (the `_format.md` sibling allowlist). **Not in O1/O9.**
7. `scripts/validate-pack.py:8225` — `"project-template/docs/project/changelog/_format.md"` in the operating-doc family-glob set (`_CHECK_OPERATING_DOC_*`, line 8224-8225). **Not in EE-6 or any deliverable.** (verified context 8195-8245.)
8. `scripts/validate-pack.py:5094` — `"BD-NNN.md": "… (template; see /backlog/_format.md)"`. (pack-side cite; verify.) **Not in EE-6.**
9. `scripts/tests/test-validate-pack-check-43.sh:530,540` — encodes the `project-side-*-skeleton.md` allowlist that includes `_format.md`. O9 names only `:136-138` (mirror basenames). **Not in O9.**

Items 1-4 are the same surfaces as BLOCKER-1 (they double as the atomicity break). Item 5 is the most dangerous recall miss: a FIXTURE that asserts `_format.md` MUST PASS Check 43 — directly contradicting the FORBIDDEN-`_format.md` model — and it is in NEITHER the census NOR the design. The `measure-then-bound` / `enumerate-encoding-surfaces` rules require the FORBIDDEN-set guard to be sized against the measured tree; the design measured 26 and the real operational set is 23 files but with a DIFFERENT membership (it dropped the test/fixture/allowlist surfaces).

### MUST-1 — `project-template/tracker.toml.project-example` `[mirror]` table + `tracker.toml.pack-example` BD-206 pointer: a self-identified BD-206 surface in NEITHER census NOR design
**Severity: MUST.** **Design location:** O19 (tracker reconciliation) + §7 OUT-of-scope; CENSUS §5.1.

Independent grep found two operational tracker config surfaces the census (§5.1 covers `tracker-*.sh` only) AND the design (O19 names only `tracker-*.sh`) both miss:
```
$ git grep -nE '\[mirror\]|BD-206' -- project-template/tracker.toml.project-example tracker.toml.pack-example
project-template/tracker.toml.project-example:37:[mirror]
tracker.toml.pack-example:57:# (project-template/tracker.toml.project-example) keeps its [mirror]
tracker.toml.pack-example:58:# table until BD-206 retires the project-side monolith mirrors.
```
`project-template/tracker.toml.project-example:37-44` is a LOAD-BEARING `[mirror]` table: `enabled = true`, `location_backlog = "BACKLOG.md"`, `location_changelog = "CHANGELOG.md"`, `regenerate_on_write = true`. `validate-pack.py:93` (Check 29) requires `[mirror]` "on the client example" — so this is CI-enforced, not just a comment. `tracker.toml.pack-example:58` literally says this table survives "until BD-206 retires the project-side monolith mirrors." Neither file appears in the census or the design (grep of both docs returned ZERO hits for `tracker.toml`/`project-example`/`pack-example`).

This is exactly the per-entry→monolith-vs-tracker→file-mirror boundary the design's O19 claims to adjudicate — but O19 never reaches these surfaces, so the adjudication is not applied. The `location_backlog = "BACKLOG.md"` points at a monolith BD-206 deletes; the disposition (KEEP as tracker→file feature vs repoint/retire per the "until BD-206" comment) is precisely the SS-1 boundary call, and it is silently un-made. Also stale: `scripts/tests/tracker-init-test.sh:281` ("the client model still has monolith mirrors until [BD-206]") and `tracker-init-test.sh:257`.

### Completeness gap the census AND design BOTH missed (the headline recall miss)
`project-template/tracker.toml.project-example` (`[mirror]` table, Check-29-enforced) + `tracker.toml.pack-example:57-58` (explicit "until BD-206" pointer) + `tracker-init-test.sh:281` stale comment. **Self-identified BD-206 surfaces, CI-load-bearing, in neither doc.**

---

## DIMENSION 2 — CORRECTNESS (re-verify the empirical claims) — **PASS with MUST-2**

I independently re-verified every EE claim. The schema/anchor/count claims are SOUND:

| Claim | Design | My measurement (HEAD 775e9cc, 2026-06-26) | Verdict |
|---|---|---|---|
| EE-1 backlog gold | 113 td; Marker 81/25/7; Sev 1/54/26; Scope 3 dep/9 feat/13 phase-N; VS 7 | EXACT match (gold 121347 B, materialized) | SUPPORTED |
| EE-1 core fields | all core present 113/113; Resolution iff Resolved (56) | ID/Marker/Status/Blockers/Unblocks/File-Symbol/Description/Context = 113 each; Resolution=56=Resolved | SUPPORTED |
| EE-2 impl-plan gold | 61 phase-epic + 15 phase-part | EXACT (gold 344180 B) | SUPPORTED |
| EE-3 changelog gold | 179805 B; 55 H3; max 130 lines | EXACT (55 entries, max entry = 130 lines) | SUPPORTED |
| EE-4 14 CI failures | Check 39×7 + Check 41×7 = the 7 deleted sidecars | EXACT (7 paths each, identical set) | SUPPORTED (count) — but see BLOCKER-1 on the "sufficient" claim |
| G-5 bold-pair anchor | tracker carrier `ENTRY_HEADER` is bold-pair; H4 does not match | `tracker-migrate-forward.sh:408` = `^\*\*((?:BD\|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$` (bold-pair). Gold backlog = 113 H4 (`#### TD-NNN`), 0 bold-pair | SUPPORTED |
| G-4 superset splitter | gold is H4; accept H4 + bold-pair, emit bold-pair | gold 113/113 H4 confirmed | SUPPORTED |
| EE-7 force-overwrite-mirror | ~40 hits, 6 files + tests | 231 total hits incl. history; operational set matches the named 6 files + 2 tests | SUPPORTED |
| EE-8 production callers | only `init:1113` + `decompose:195` (non-test) | EXACT — all other `per_entry_regenerate_mirror` callers are tests; `pe_canonical_mirror_for_stream` only `test-per-entry:219-221` | SUPPORTED |
| EE-8 toc-regenerate survives | `per_entry_regenerate_toc` is separate, survives | confirmed (independent function, separate callers) | SUPPORTED |
| O13 naming guard | gold conforms → zero violations | 61 `## Phase N`, 15 `### Phase-N.Part-x`, 27 `#### …Task-k`, ZERO non-conforming `### Phase-` | SUPPORTED |

### MUST-2 — EE-7/EE-8 cite a SECOND force-overwrite var (`PE_FORCE_OVERWRITE_MIRROR`) that the divergence-gate removal (DR-1/O7) does not enumerate
**Severity: MUST.** **Design location:** EE-7 + DR-1/O7 (removes `_MIGRATOR_FORCE_OVERWRITE_MIRROR`).

DR-1/O7 designs the removal of `_MIGRATOR_FORCE_OVERWRITE_MIRROR` with a grep-zero gate on `force.overwrite.mirror|_MIGRATOR_FORCE_OVERWRITE_MIRROR`. But there is a SECOND, distinct env var, `PE_FORCE_OVERWRITE_MIRROR`, that the divergence machinery uses at the `mirror-generate.sh` layer:
```
$ git grep -nE 'PE_FORCE_OVERWRITE_MIRROR' -- ':!maintenance-docs/'  (excerpt)
scripts/lib/per-entry/mirror-generate.sh:251,253,288,342   # the actual bypass + warning
scripts/lib/migrate-v10-to-v11/decompose.sh:27,57,117,120,125   # bridges _MIGRATOR_ → PE_
scripts/lib/migrator-core.sh:326
scripts/tests/test-per-entry.sh:336,373,376,491,497  (Group 8 force-overwrite asserts)
scripts/tests/test-migrate-v10-to-v11-decompose.sh:35-36,385,416,...  (Group 3/4)
test-fixtures/build.sh:496,552,555
```
The design's DR-1 grep-zero gate (`force.overwrite.mirror|_MIGRATOR_FORCE_OVERWRITE_MIRROR`) DOES pattern-match `PE_FORCE_OVERWRITE_MIRROR` via `force.overwrite.mirror` — but O7's enumerated removal set (the `migrator-core.sh` flag/parser/help, the `mirror-generate.sh` divergence BLOCK, the decompose bridge, the Group-4 tests) does NOT itemize the `PE_FORCE_OVERWRITE_MIRROR` consumers at `mirror-generate.sh:251-253` (the actual bypass logic) NOR `build.sh:496,552,555`. Since O22-pack deletes `mirror-generate.sh` entirely, the `PE_FORCE_OVERWRITE_MIRROR` consumers there go with it — but `build.sh`'s `PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror` (555) and the `test-per-entry` Group 8 asserts (which O22-pack DOES name) need explicit handling. The two-variable naming is a real removal-ripple the design's EE-7 mentions in passing but DR-1's gate-and-enumeration does not fully bound. Verify the grep-zero gate's regex actually catches `PE_FORCE_OVERWRITE_MIRROR` and add `build.sh` to the enumerated set.

---

## DIMENSION 3 — SOUNDNESS / BINDING-DECISION COMPLIANCE — **PASS with MUST-3**

The design honors the core binding decisions, verified:
- **Sanctioned vocabulary** `{_rules,_intro,_toc,_index(opt)}`; `_format.md`+`_scaffolding.md` FORBIDDEN (§3.1) — matches DECISIONS §1/§2. ✓
- **Tripwire** (impl-plan gets `_index.md`; backlog gets none) — §3.1 matrix + §3 ledger correct. ✓ (DECISIONS §3 tripwire passed.)
- **`_rules.md` immutable / `_intro.md` human-only** — O2/O3 honor DECISIONS §1 (G-10 force-overwrite). ✓
- **v10-anchoring-forbidden** — §3 derives from V2 gold + production changelog, EE-1/2/3; never v10. ✓ (DECISIONS §5.)
- **Form families REQUIRED for backlog+impl-plan; changelog structured-not-form-family** with G-2b caps — §3.2/3.3/3.4 match DECISIONS §4 + Item-6 + G-2b. ✓
- **Bold-pair anchor (G-5) + superset splitter (G-4)** — empirically grounded (D2 above). ✓
- **METHODOLOGY wholesale rewrite** (O14) + **tracker boundary** (O19 per-entry→monolith vs tracker→file) — both newest decisions reflected in deliverable text. ✓ (but O19 misses the `.toml` surfaces — MUST-1.)

### MUST-3 — Operating-doc allowlists (`.operating-doc-history-allowlist.txt`, `.operating-doc-deferred-feature-allowlist.txt`) carry line-anchored exemptions for the to-be-REBUILT sidecars; O3 does not reconcile them
**Severity: MUST.** **Design location:** O3 (rebuild `_rules.md`) + EE-6 (names only the `_format.md` allowlist lines).

The two operating-doc allowlists exempt SPECIFIC content snippets in the OLD sidecars via `doc:` + `pattern:` + `snippet:` triples:
```
$ grep -nE 'docs/project' pack-ops/.operating-doc-history-allowlist.txt pack-ops/.operating-doc-deferred-feature-allowlist.txt
history-allowlist:145,150: doc: …/changelog/_format.md   (snippet: 2026-04-20 / 2026-03-20)
history-allowlist:157:     doc: …/changelog/_rules.md     (snippet: 2026-04-20)
deferred-feature-allowlist:419: doc: …/changelog/_format.md
deferred-feature-allowlist:423: doc: …/implementation-plan/_rules.md
```
EE-6 names the `_format.md` lines (`history:144-150`, `deferred:419`) for the `_format.md` ELIMINATION. But it does NOT name `history:157` (`changelog/_rules.md`, snippet `2026-04-20`) or `deferred:423` (`implementation-plan/_rules.md`) — both reference `_rules.md` files O3 rebuilds FROM SCRATCH. After O3:
- If the rebuilt `_rules.md` no longer contains `2026-04-20`, the `history:157` exemption is a DEAD entry (cleanup gap, not a CI fail).
- If the rebuilt `_rules.md` introduces NEW history/deferred-feature content (a date example, a "until BD-NNN" pointer) not covered by these exemptions, the operating-doc check (the one fed by `_CHECK_OPERATING_DOC` set at validate-pack.py:8224, which globs `project-template/docs/project/*/_rules.md`) FAILS.

The design's O3 states the operating-docs-no-history rule applies but does NOT enumerate these two allowlists as lock-step surfaces requiring re-derivation against the rebuilt content. Per `enumerate-encoding-surfaces`, the rebuilt `_rules.md` (surface) + its operating-doc allowlist exemptions (the CI-side encoding) must move in lock-step. This is an asymmetric-coverage gap.

---

## DIMENSION 4 — RISK / SEQUENCING (rule-10 map) — **FAIL**

### BLOCKER-2 — `test-fixtures/build.sh` is assigned to NO wave, sources the deleted `mirror-generate.sh`, requires the deleted monolith, AND is itself a manifest fixture-input
**Severity: BLOCKER.** **Design location:** §6 rule-10 map (build.sh appears in NO wave); EE-8 ("build.sh … covered by O4/O7 … land in BD-206 waves").

`test-fixtures/build.sh:510-560` (verified, quoted) is the round-trip integrity fixture builder:
```
516:  . "$_pe_lib_dir/mirror-generate.sh"            # sources the file O22-pack/BD-249 DELETES
538:  [[ -f "$_pe_mirror" ]] || die "BD-170: monolithic mirror missing at $_pe_mirror_rel ..."  # REQUIRES the monolith
546:  cp "$_pe_mirror" "$_pe_mirror_orig"            # round-trip diff snapshot
555:  PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror "$_pe_key" "$_pe_dir" "$_pe_mirror"  # regenerates it
```
Three independent failure modes, none sequenced:
1. **After O4** (Wave A, removes init S11 mirror generation), build.sh's `die "monolithic mirror missing"` (538) STILL builds its own fixture mirror — but it asserts the input shape that O4's no-mirror model abolishes. The round-trip (decompose→regenerate→diff) has no subject under no-mirror.
2. **After O22-pack/BD-249** deletes `mirror-generate.sh`, build.sh's `. "$_pe_lib_dir/mirror-generate.sh"` (516) sources a non-existent file → hard break. §6 names `mirror-generate.sh` serialization (B1→F) but NOT build.sh's SOURCING of it.
3. **build.sh is a manifest fixture-input** — `scripts/lib/manifest-inputs.sh:67` lists `"test-fixtures/build.sh"` in `MANIFEST_INPUT_GLOBS`, AND `"project-template/*"` (line 62) covers the rebuilt sidecars. So Wave A (rebuilding sidecars) triggers `manifest-sync.sh` → runs `build.sh --all` at push (BD-228 push-time method). A broken build.sh breaks the BD-228 manifest gate (Check 62 + `build.sh --verify`).

EE-8's "covered by O4/O7 … land in BD-206 waves" is **paper coverage** — build.sh is in no deliverable's action text, no wave, and its mirror-round-trip step is not redesigned. The CI workflow runs it directly (`validate-pack.yml:193,195`). This is a launch-blocking sequencing + completeness hole.

### MUST-4 — `_index.md` is never added to the impl-plan support-set constant (`_lib.sh:123`); a new sanctioned sidecar that the admission logic does not admit
**Severity: MUST.** **Design location:** O11 (`_index.md` generation) + O1 (support-set lock-step, names `_lib.sh:136` only).

```
$ grep -nE 'support\) printf' scripts/lib/per-entry/_lib.sh
91,103,111,123:  support) printf '_rules.md _intro.md _toc.md'      # incl. project-implementation-plan (123)
136:             support) printf '_rules.md _intro.md _toc.md _format.md'   # project-changelog
$ grep -nE '_index\.md' scripts/lib/per-entry/_lib.sh   → (none)
```
O11 creates `_index.md` for the impl-plan stream and §3.1 declares it sanctioned. But the `project-implementation-plan` support-set (`_lib.sh:123`) is `_rules.md _intro.md _toc.md` — it does NOT admit `_index.md`. The admission logic (`pe_supporting_files_admitted`, EE-5) uses this set to decide which non-entry files are KNOWN-supporting vs stray. With `_index.md` not in the set, the new validators (O9/O10 "no stray sidecar") could flag `_index.md` as a stray file, and `_toc.md`/decompose could mis-handle it. O1's lock-step only DROPS `_format.md` from line 136; it never ADDS `_index.md` to line 123. Asymmetric-coverage gap (`enumerate-encoding-surfaces`).

### SHOULD-1 — Wave F (O22-pack) is in the BD-206 rule-10 map, but BD-249 makes it a SEPARATE post-BD-206 BD; the two scoping models conflict
**Severity: SHOULD.** **Design location:** §6 Wave F + DAG `{B1,B1b}→F` + §7 SS-5 + §8; vs `backlog/BD-249.md`.

BD-249 (verified to exist, Status Open, Target v11.0) says O22-pack "lands the PACK-side half … as a separate `pack-only` commit … sequenced DIRECTLY AFTER BD-206 … Exact ordering among the several post-BD-206 BDs is TBD." But the design's §6 includes "Wave F" inside the BD-206 wave plan with a hard DAG edge `{B1,B1b}→F`, implying O22-pack runs within the BD-206 effort's wave schedule. This is contradictory: the design plans Wave F as part of BD-206's parallelization map, while BD-249 scopes it as a distinct downstream BD with TBD ordering. The design should DROP Wave F from the BD-206 rule-10 map and reference BD-249 as the downstream anchor (the design pre-dates or races BD-249's opening; the §7 SS-5 "Pack Chat/user resolves the anchor" is now resolved by BD-249). Not launch-blocking, but a planner will hit ambiguity on whether to schedule Wave F.

---

## DIMENSION 5 — FOUNDATIONAL REQUIREMENTS (§16, all 6) — **PASS with SHOULD-2**

| §16 req | Design mapping (§1) | My assessment |
|---|---|---|
| (1) Guardrail-maintenance (rules+tests+CI both repos) | O3/O9/O10/O11/O12/O13 | COVERED in design intent — but BLOCKER-3 (the `_format.md` FORBIDDEN guard misses its test/fixture lock-step) + MUST-4 (`_index.md` admission) are gaps in the guardrail's encoding. Real but fixable. |
| (2) Freshness + accuracy | O8/O11/O7/O12 | COVERED. `_toc.md` regen + `_index.md` validation sound. |
| (3) File structure (per-entry + 4-sidecar) | O1/O2/O3/O8/O22 | COVERED, modulo MUST-4 (support-set) + BLOCKER-1/2 (the install+fixture machinery). |
| (4) Operational mechanics (PM Chat + agents) | O15/O16/O17/O18/O14/O21 | COVERED in scope; the repoint volume is large (O16 high-volume) but enumerated. |
| (5) Testing + integrity | O9-O13 + O5/O6 tests + BD-246 referenced | **SHOULD-2:** the testing requirement is asserted but the design's own test lock-step is incomplete (BLOCKER-1/3 — the EXISTING tests that break are not enumerated; BLOCKER-2 — build.sh round-trip not redesigned). BD-246 correctly out-of-scope with a tracked anchor (verified `backlog/BD-246.md` exists). |
| (6) Ease of future tracker integration | O3 (bold-pair carrier)/O12/O19 | COVERED — bold-pair anchor empirically aligned to the carrier (G-5 verified). But MUST-1 (the `.toml` `[mirror]` tables) is a tracker-integration surface left un-adjudicated. |

### SHOULD-2 — §16(5) testing-integrity is paper-covered: the design enumerates NEW tests but not the EXISTING tests its conversion breaks
The §1 map points §16(5) at "O9/O10/O11/O12/O13 enforcement + their tests." But integrity also requires the EXISTING test battery to stay green through the conversion — which BLOCKER-1/2/3 show it does not (test-init-project, test-per-entry, test-v11-realistic-ot, persona contracts, build.sh). The requirement is genuinely intended but the deliverables do not deliver a green existing-battery at each wave.

---

## DIMENSION 6 — THE TWO RE-ENGAGEMENT ADDITIONS (O21 MIGRATION doc, O22 DR-2=C) — **PASS with MUST (folded into BLOCKER-2)**

### O21 (`supporting-docs/MIGRATION-v10-to-v11.md` no-mirror rewrite)
Independently re-grepped at HEAD. The design's O21 line set is **accurate and well-bounded**: the headline "Monolithic files become regenerated mirrors" claim, the `--force-overwrite-mirror` subsection, the `_format.md` mention, the KEEP of the L468 root-rename row. The cross-deliverable coherence gate (O21's flag-narrative removal must match O7/DR-1's flag removal) is correctly stated. **No new finding** — O21 is the strongest deliverable in the doc. One NIT: O21 cites specific line numbers (L319-413) that will drift as the doc is edited; the coder should re-grep at implementation time (the design says "re-grepped at HEAD `775e9cc1`" — acceptable).

### O22 (DR-2=C both-sides removal)
EE-8's call-site census is **independently verified correct** (D2). The live-vs-dead classification is sound: zero production callers survive O4/O7; `toc-regenerate.sh`'s `per_entry_regenerate_toc` correctly identified as a surviving separate function. BD-249 exists as the pack-side anchor (verified). **But** O22's `enumerate-encoding-surfaces` claim ("ALL test coverage … build.sh … enumerated in lock-step") is undermined by BLOCKER-2 (build.sh has no wave/action) and MUST-2 (`PE_FORCE_OVERWRITE_MIRROR` consumers in build.sh). The O22 grep-zero gate (`mirror-generate|per_entry_regenerate_mirror|pe_canonical_mirror_for_stream|mirror) printf`, operational-only) is correctly designed and currently returns 81 hits across 12 files (verified) — the gate is sound; the gap is that build.sh, one of those 12, is unscheduled. SHOULD-1 (Wave-F-vs-BD-249 scoping conflict) also attaches here.

---

## SUMMARY OF FINDINGS

| # | Sev | Dimension | One-line |
|---|---|---|---|
| BLOCKER-1 | BLOCKER | D1/D4 | Wave-A clears validate-pack but turns the shell test battery + build.sh red; EE-4 measured one tool, not the full CI battery §15 mandates. |
| BLOCKER-2 | BLOCKER | D4 | `test-fixtures/build.sh` assigned to no wave; sources the deleted mirror-generate.sh, requires the deleted monolith, is itself a manifest fixture-input. |
| BLOCKER-3 | BLOCKER | D1 | `_format.md` elimination (O1/EE-6) misses ~9 lock-step surfaces (tests, persona contracts, a Check-43 PASS fixture asserting `_format.md`, validate-pack:5503 + 8225). |
| MUST-1 | MUST | D1/D3 | `tracker.toml.project-example` `[mirror]` table + `tracker.toml.pack-example` "until BD-206" pointer + tracker-init-test stale comment — Check-29-enforced, in NEITHER census NOR design. |
| MUST-2 | MUST | D2 | `PE_FORCE_OVERWRITE_MIRROR` (2nd var) consumers at mirror-generate.sh + build.sh not fully enumerated in DR-1/O7. |
| MUST-3 | MUST | D3 | Operating-doc allowlists exempt content in the to-be-rebuilt `_rules.md` (history:157, deferred:423); O3 does not reconcile them. |
| MUST-4 | MUST | D4 | `_index.md` never added to the impl-plan support-set constant (`_lib.sh:123`); a sanctioned sidecar the admission logic doesn't admit. |
| SHOULD-1 | SHOULD | D4 | Wave F (O22-pack) sits in the BD-206 rule-10 map but BD-249 scopes it as a separate post-BD-206 BD — conflicting models. |
| SHOULD-2 | SHOULD | D5 | §16(5) testing-integrity asserts NEW tests but does not deliver a green EXISTING battery per wave (consequence of BLOCKER-1/2/3). |

**Empirical foundation that is SOUND (independently reproduced):** EE-1/EE-2/EE-3 schema vs gold (exact), EE-4 14-count (exact, but "sufficient" claim wrong), EE-7/EE-8 call-site censuses (exact), G-4/G-5 anchor (exact), O13 naming guard (gold conforms), the binding-decision compliance (vocabulary/tripwire/v10-forbidden/G-2b caps/DR-2=C/BD-249).

**Recommendation:** NEEDS-REWORK. Fix the three BLOCKERs (re-scope Wave A to the full CI battery; assign + redesign build.sh; complete the `_format.md` lock-step set including the Check-43 PASS fixture) and the four MUSTs before the design advances to the planner gate. The conversion logic is correct; the blast radius is — again — under-counted at the test/fixture/CI-encoding layer.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (measured, quoted) | Conclusion |
|---|---|---|
| **measure-then-bound / blast-radius completeness** | Re-derived the blast radius INDEPENDENTLY: graph-first discovery (`graphify query … --graph …graph.json --backend claude-cli --budget 1500` → surfaced mirror-generate community + a STALE `project-template/docs/project/CHANGELOG.md` node, which I disproved via `git ls-files` showing no tracked monolith) + own `git grep` over `git ls-files` (1762 tracked): `_format.md` = 97 files (23 operational, vs design's "26"); force-overwrite = 231 hits; mirror-subsystem grep = 81 hits/12 files. Found 3 surfaces in NEITHER census NOR design (`tracker.toml.project-example` `[mirror]`, `tracker.toml.pack-example` BD-206 pointer, the Check-43 `_format.md` PASS fixture). | COMPLIANT |
| **ground every finding in evidence** | Every finding cites the command run + verbatim file:line output + HEAD `775e9cc` + severity + the exact design location it contradicts (EE-4/§6/§15 for BLOCKER-1; EE-8/§6 for BLOCKER-2; EE-6/O1 for BLOCKER-3; O19/§5.1 for MUST-1; etc.). | COMPLIANT |
| **enumerate-encoding-surfaces** | For each flagged surface I checked its lock-step set: `_format.md` surface ↔ its tests (test-init-project 4.2/4.5, test-per-entry 1.9, test-v11-realistic-ot A.13) ↔ fixtures (project-side-refs) ↔ validator (validate-pack:5503/8225) ↔ test-check-43:530-540 — flagged where the design updates one but not its pair; same for `_index.md` (sidecar ↔ support-set constant) and the rebuilt `_rules.md` (↔ operating-doc allowlists). | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | Ran ONLY read-only verbs: `git rev-parse`, `git grep`, `git ls-files`, `git status --short`, `git branch` (via snapshot), `python3 validate-pack.py` (read-only), file Reads, graphify query (read-only). No state-changing git verb. Sole write = this report at the prompted path. No destructive op. | COMPLIANT |
| **graph-first-context** | DISCOVERY ran graph FIRST (the monolith-mirror traversal) against the INJECTED `--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` (never recomputed from my own toplevel); it surfaced the mirror-generate community + a stale CHANGELOG node; I then VERIFIED via grep/Read (the stale node disproved by `git ls-files`). G2 not needed (query returned nodes). | COMPLIANT |
| **spawn-unique-naming** | Operating as `reviewer-bd206-arch-adversarial` (report header + this row). | COMPLIANT |
| **rules-applied-verification-block / agents-read-rule-docs-in-full** | This block exists with per-rule measured evidence. Read IN FULL: pack-root CLAUDE.md `## Pack memory` (in-context, full); the review target ARCHITECTURE-BD-206.md (861 lines, two-page Read); CENSUS (379 lines, two pages); DECISIONS-BD-206-RESTART.md (536 lines); INVESTIGATION-BD-206-SIDECARS.md (238 lines); backlog/BD-206.md (23 lines) + BD-249.md. Memory files read via the CLAUDE.md `## Pack memory` rule text + the named files referenced in-context (feedback_ci_guard_design_measure_then_bound, feedback_researcher_maps_blast_radius_before_architect, feedback_agent_output_rules_applied_block, feedback_architect_planner_empirical_evidence, feedback_agents_read_rule_docs_in_full) — all reachable via MEMORY.md index in-context. | COMPLIANT |

**HEAD reviewed at:** `775e9cc139ef3fdde3d499198894a7bef70145e1` — **Date:** 2026-06-26 — **Reviewer:** `reviewer-bd206-arch-adversarial`.

### Anti-contamination attestation
No prior BD-206 ARCHITECTURE/PLAN/REVIEW/RECONCILE/ADVERSARIAL doc was read (the handoff dir's ADVERSARIAL-ARCHITECT-REVIEW, ADVERSARIAL-PLANNER-REVIEW, RESTART/RECONCILED/FINAL architectures, and PLAN were deliberately NOT opened); nothing under `/tmp/bd206-REJECTED-DO-NOT-READ/` was read; §16's referenced FINAL doc was NOT opened. All findings derive from my own measurement of the current ARCHITECTURE-BD-206.md against the GOLD + the live repo + the allowed ledgers (CENSUS/DECISIONS/INVESTIGATION).
