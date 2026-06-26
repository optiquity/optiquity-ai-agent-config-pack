# ADVERSARIAL PLAN REVIEW — BD-206

**Reviewer:** `reviewer-bd206-plan-adversarial-2` (FRESH; not the planner, not the design author, not any prior reviewer).
**Review target:** `/Users/david/Developer/_tmp/pack-handoff-bd206-restart/PLAN-BD-206.md` (383 lines, read in full).
**SSOT:** `ARCHITECTURE-BD-206.md` (APPROVED; deliverables O0–O26, §6 rule-10 map) + the SIX user-approved §1 amendments (A-1..A-6, NOT re-litigated).
**HEAD:** `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7` — **Branch:** `v11-dev` — **Date:** 2026-06-26.
**Working tree at review:** 8 uncommitted deletions (7 project sidecars + 1 RESEARCH doc) = the partial Wave-A state, verified.
**Method:** independently re-ran the full battery at the partial Wave-A state; cross-checked deliverable coverage; ran a clean-clone control to isolate the decompose-test root cause; verified every grep-zero gate baseline; verified same-file collisions against the live tree.
**Anti-contamination:** read NO prior BD-206 PLAN, NO prior review report, nothing under `/tmp/bd206-REJECTED-DO-NOT-READ/`.

---

## OVERALL VERDICT: **NEEDS-REWORK**

Two findings rise to MUST/BLOCKER and the OVERALL is NEEDS-REWORK:

- **MUST-1 (dimension 2/3):** The plan's flagship A-1 finding — the "`test-migrate-v10-to-v11-decompose.sh` dual-wave break" with 5 force-overwrite asserts "expected-RED-until-B1" at the A1 commit (EE-C / GAP-2) — is a **MISDIAGNOSIS**. Independent control proves those asserts are GREEN when sidecars + flag are present. At the A1 commit decompose is fully green; the asserts only break at B1 (when O7 removes the flag), where the plan already inverts them. The "expected-RED-until-B1" instruction to the A1 reviewer is wrong and would mask a real A1 regression while violating §15.
- **MUST-2 (dimension 4):** The plan's same-file serialization analysis (§4) is INCOMPLETE. O11/O12/O13 each add a pack-side leg to the single monolithic `scripts/validate-pack.py` (11,799 lines, 92 inline `check_*` functions; no external check modules). The plan schedules C3/C4/C5 as mutually PARALLEL worktree waves (§4 DAG) and explicitly claims (§4 line 222) "C/D/E touch none of [validate-pack.py]" — both FALSE. Parallel worktree commits all writing validate-pack.py will collide at patch-apply.

A-1's per-wave breakage SET is otherwise complete and correctly assigned **except** the EE-C dual-wave nuance is spurious (there is no dual-wave break; decompose is single-wave at B1). §15 is HONORED for the real state (A1 is fully green) but the plan's own EE-C reasoning would, if followed, VIOLATE it.

---

## DIMENSION 1 — COMPLETENESS (all 27 deliverables sequenced)

**Verdict: PASS (one NIT).**

Independent cross-check of the plan's commit set against the design's deliverable set O0–O26:

| O# | Plan commit | O# | Plan commit |
|---|---|---|---|
| O0 | A1 | O14 | D4 |
| O1 | A1 | O15 | D1 |
| O2 | A1 | O16 | D2 |
| O3 | A1 | O17 | D3 |
| O4 | A1(init)+B1(decompose) | O18 | D5 |
| O5 (+O5b) | B2 | O19 | E1 |
| O6 | B3 | O20-prose | A1 |
| O7 (+DR-1) | B1 | O21 | D6 |
| O8 | A1 | O22-proj | B1b |
| O9 | A1 | O22-pack | BD-249 |
| O10 | C2 | O23 | A1 |
| O11 | C3 | O24 | A1 |
| O12 | C4 | O25 | A1 |
| O13 | C5 | O26 | A1 |

All 27 deliverables are sequenced into a commit; none dropped; none double-counted. O4's init/decompose split matches design §6 (O4(init)→A; O4(decompose)→B1). O22's proj/pack split matches DR-2/design §4. The C1-into-A1 validate-pack fold is the design's own §6 recommendation (not drift).

**NIT-1 — §0 commit-count is internally inconsistent (self-corrected at §6).** §0 line 20: "**13 commits** total — 1 Wave-A + 4 Wave-B + 2 Wave-C + 6 Wave-D + 1 Wave-E + 1 BD-249." This is arithmetically wrong (1+4+2+6+1 = 14 BD-206 commits, not 13) and contradicts its own clause "C carries C2..C5" (4 Wave-C commits, not 2). §6 line 307 issues an explicit "CORRECTION to §0's 13" giving the range 12–17, and §3 is declared the SSOT. The contradiction is acknowledged and §3 is authoritative, so this is a NIT — but the §0 headline should be fixed to avoid handing a wrong number to the orchestrator/user at the top of the doc.

---

## DIMENSION 2 — A-1 PER-WAVE BREAKAGE CORRECTNESS (the priority)

**Verdict: NEEDS-REWORK — the per-wave breaking-test SET is complete and the migration battery WAS empirically found (A-1 discharged on that axis), BUT the EE-C dual-wave CLASSIFICATION of `test-migrate-v10-to-v11-decompose.sh` is a MISDIAGNOSIS (MUST-1).**

### 2a. Battery re-run — the plan's empirical numbers reproduce EXACTLY (good)
Independently re-ran the full battery at the partial Wave-A state (HEAD `66c8332`, 8 deletions):

```
validate-pack.py            → FAILED — 14 issue(s) (Check 39 ×7 + Check 41 ×7), exact deleted-sidecar paths.   [matches EE-A]
test-migrate-v10-to-v11-decompose.sh → Passed: 33 Failed: 12                                                  [matches EE-B]
test-migrate-v10-to-v11.sh           → Passed: 48 Failed: 6                                                    [matches EE-B]
test-migrate-v10-to-v11-dry-run.sh   → Passed: 57 Failed: 4                                                    [matches EE-B]
test-migrate-v10-to-v11-gates.sh     → Passed: 80 Failed: 7                                                    [matches EE-B]
test-per-entry.sh                    → PASS: 57 FAIL: 0                                                         [matches EE-D]
test-init-project.sh                 → Passed: 39 Failed: 25                                                   [matches EE-D]
test-validate-pack-check-43.sh       → PASS: 9 FAIL: 0                                                          [matches EE-D]
tracker-config-schema-test.sh        → PASS: 40 FAIL: 0                                                         [matches EE-D]
tracker-init-test.sh                 → Passed: 104 Failed: 0                                                    [matches EE-D]
tracker-agent-read-test.sh           → Passed: 57 Failed: 0                                                     [matches EE-D]
```
Every number in EE-A/EE-B/EE-D reproduces verbatim. The plan DID run the migration battery EE-9 sampled past (A-1's central claim — that the migration battery is a real Wave-A surface — is TRUE). The plan correctly identifies that the migrator's internal Gate 2 runs validate-pack and cascades rc=31 across the migration battery when sidecars are deleted. **A-1's "found the breaks EE-9 missed" claim is SUPPORTED on the discovery axis.**

### 2b. The EE-C "dual-wave break" classification is WRONG — MUST-1
EE-C / GAP-2 (plan lines 247-251, 326) assert: `test-migrate-v10-to-v11-decompose.sh` is a DUAL-WAVE break — the sidecar/Gate-2 asserts (2.1a-f, 2.4) restore at A1, but the FORCE-OVERWRITE asserts (`2.0b, 4.1a/b/c, 4.2a`) "stay RED until B1" and the A1 reviewer must "treat those four as expected-RED-until-B1."

I captured the actual failing asserts at the partial state:
```
FAIL 2.0b --apply rc=0 (with --force-overwrite-mirror) — expected='0' got='31'
FAIL 2.1a..2.1f per-entry ... missing
FAIL 2.4 --apply Gate 2 PASS ...
FAIL 4.2a --resume WITHOUT --force-overwrite-mirror: rc=31; expected 25
FAIL 4.1a --resume --force-overwrite-mirror: rc=31; expected 0
FAIL 4.1b/4.1c ...
```
Every force-overwrite assert returns **rc=31 = EXIT_GATE_FAILED** (`migrator-core.sh:74 readonly EXIT_GATE_FAILED=31`) — i.e. the apply/resume aborts at the migrator's internal Gate-2 (validate-pack) BEFORE the flag logic runs. The `--force-overwrite-mirror` flag is merely how the test INVOKES apply (first-migration); the failure is the Gate-2 cascade, NOT flag behavior.

**Control experiment (decisive).** I cloned the repo at HEAD `66c8332` into a real-git `/tmp` checkout (sidecars PRESENT, `_format.md` PRESENT, flag PRESENT — i.e. the A1 state MINUS O7's flag removal) and ran decompose:
```
$ git clone -q --no-hardlinks . /tmp/bd206-clone.XXXX ; cd /tmp/bd206-clone.XXXX
$ git rev-parse --short HEAD                → 66c8332
$ test-migrate-v10-to-v11-decompose.sh     → Passed: 45 Failed: 0   ← FULLY GREEN
```
With sidecars present and the flag present, ALL 45 asserts pass — including 2.0b, 4.1a/b/c, 4.2a. This proves:
- The force-overwrite asserts pass whenever (a) Gate 2 passes (sidecars present) AND (b) the flag still exists.
- **At the A1 commit** (sidecars rebuilt → Gate 2 passes; `_format.md` eliminated; flag NOT yet removed because O7 is B1), decompose is **GREEN, all asserts including the force-overwrite ones.**
- The asserts FLIP to red only at **B1**, when O7 removes the flag + the regeneration — exactly where the plan already schedules their inversion.

So decompose is a **single-wave break at B1**, not a dual-wave break. The plan conflated "red at the pre-A1 working-tree deletion state (Gate-2 cascade)" with "red at the A1 commit HEAD." The design SSOT agrees: design EE-9 assigns ONLY the `2.2a/b/c` decompose asserts to O7/B1 and its conclusion (line 213) treats Wave-A as fully battery-green; the design never claims decompose is red at A1. **The plan introduced a NEW, incorrect claim under the A-1 banner.**

**Why this is a MUST, not a NIT:** the plan's operational instruction (EE-C, GAP-2, §3 A1 verification, §5 protocol) tells the A1 reviewer to ACCEPT a RED `test-migrate-v10-to-v11-decompose.sh` (5 force-overwrite asserts) at the A1 commit as "expected-RED-until-B1." If the coder/reviewer follows this, then (a) a GENUINE A1 regression in those asserts is silently excused, defeating the bounded review/fix cycle's purpose, and (b) the A1 commit is accepted while NOT fully battery-green — directly contrary to §15. The correct instruction is: **decompose MUST be fully green at A1; if any decompose assert is red at the A1 commit, that is a real defect, not an expected wave boundary.**

### 2c. Is the per-wave breaking SET otherwise complete?
Yes (apart from 2b). Re-checking each wave: A1's inversion set (EE-9 + the migration battery restoration via sidecar rebuild + the `:453` copy-source fix) is the complete set of tests that break at the A1 source change; B1 carries O7's decompose force-overwrite + 2.2a/b/c inversions + Group B; E1 carries the `tracker-agent-read-test.sh` dormant break; C/D carry NEW checks (no pre-existing test to break) / docs (no test break). **No test breaks at a wave whose inversion is not scheduled in/before that wave** — with the single correction that the decompose force-overwrite asserts are a B1 break (correctly scheduled in B1), NOT an A1 "tolerated red." The SET is right; the CLASSIFICATION/REVIEWER-INSTRUCTION is wrong.

---

## DIMENSION 3 — §15 GREEN-CI COMPLIANCE + the dual-wave nuance

**Verdict: NEEDS-REWORK (consequence of MUST-1).**

§15 (DECISIONS-BD-206-RESTART.md:497-510) binds: "the tree goes (and stays) GREEN **at the first wave**"; "the current 14 Check 39/41 failures clear at Wave A, **never lingering red on a push**"; "Do NOT push a bare sidecar-deletion (it would be red)."

- **14-clear-at-A1:** intact (EE-A reproduced; A1 rebuilds 6 sidecars + drops 2 `_format.md` rows → all 14 clear). ✓
- **never-lingering-red-on-a-push:** the batch pushes only at the final green HEAD (worktree-isolation model; intermediate commits land locally but the push is one unit) — so even a transiently-red intermediate commit would not be *pushed* red. On a pure push-centric reading, §15 is not violated. ✓ for the push.
- **"goes (and stays) GREEN at the first wave":** this is the stronger clause, and here the plan's OWN reasoning collides with §15. The plan documents (EE-C/GAP-2) that at the A1 COMMIT, decompose carries 5 RED asserts it labels "expected-RED-until-B1." That is a RED first-wave commit by the plan's own account → a §15 violation by the plan's reasoning. The saving grace is that the plan's reasoning is FACTUALLY WRONG (2b): decompose is actually GREEN at A1, so the real first-wave commit IS green and §15 IS honored. **But a plan that ships an incorrect "first wave is allowed to be red here" carve-out is not §15-compliant on its face** — the reviewer must remove the carve-out and assert A1 fully green.

**Resolution required:** delete the EE-C/GAP-2 "dual-wave break / expected-RED-until-B1" framing. Re-state: A1 is fully battery-green INCLUDING `test-migrate-v10-to-v11-decompose.sh` (45/0); the decompose force-overwrite + 2.2a/b/c inversions are a B1 single-wave break, inverted lock-step with O7 in B1 (already correctly scheduled). The "fallback — pull O7 into A1" option (plan line 251) is unnecessary and should be dropped; the design's O7-in-B1 boundary is sound precisely because decompose is green at A1.

---

## DIMENSION 4 — SAME-FILE SERIALIZATION CORRECTNESS

**Verdict: NEEDS-REWORK (MUST-2).**

The serialized A1-anchored files (`_lib.sh`, `test-per-entry.sh`, `migrate-v10-to-v11.sh`, `test-init-project.sh`, `build.sh`, `validate-pack.py`) and their A1→B1b→BD-249 ordering are tabled correctly (§4 lines 206-218); the `_lib.sh` line anchors (`:85,99` pack; `:109,121,129` project; `:136` support; `:123` impl-plan support for the `_index.md` add) verify against the live tree. The B1b/BD-249/A1 serialization on `_lib.sh` + `test-per-entry.sh` is correct.

**MUST-2 — the Wave-C parallel schedule collides on `validate-pack.py`.** Design O11/O12/O13 EACH "join the conformance enforcement, **both repos**" (design lines 607, 618, 628), and DECISIONS §13 Item-7 defines "both sides, different repos" as **pack repo CI = `validate-pack.py`** + client repo = `validate-docs.sh`. So:
- O11 (C3) adds an `_index.md` validation leg to validate-pack.py,
- O12 (C4) adds a changelog conformance check to validate-pack.py,
- O13 (C5) adds a naming guard to validate-pack.py.

Verified structurally: `scripts/validate-pack.py` is a SINGLE monolithic file (`wc -l` = 11,799; 92 inline `check_*` definitions; the only non-stdlib imports are `tempfile/time/tomllib` — there are NO external check modules to add a leg to). A new check = a new inline function in this one file.

The plan's §4 DAG schedules `A1 → {C2, C3, C4, C5}` as mutually PARALLEL worktree waves, the §4 same-file table lists validate-pack.py as touched by "A1 only" (post C1-fold), and §4 line 222 explicitly asserts "C/D/E touch none of [validate-pack.py]." All three are inconsistent with the plan's OWN §6 line 311 ("O10/O11/O12/O13 ship BOTH a pack leg (validate-pack.py) and a client leg"). Three parallel worktree commits all writing validate-pack.py will conflict at sequential patch-apply (the conflict protocol), and they ALSO follow A1's validate-pack.py edits.

**Resolution required:** C3/C4/C5's validate-pack.py legs must SERIALIZE (after A1, and pairwise) — they cannot be parallel worktree waves. Either (a) serialize C3→C4→C5 on validate-pack.py, or (b) fold all three new validate-pack.py legs into A1 (consistent with the C1-into-A1 fold rationale), or (c) batch the three new checks into one Wave-C validate-pack.py commit plus their disjoint client-leg/test commits in parallel. The §4 table + line 222 disjointness claim must be corrected to list validate-pack.py as a C3/C4/C5 toucher.

(Minor, same dimension: the plan's §4 entry for `migrate-v10-to-v11.sh` A1(`:453`)→B1(flag) is correct and verified disjoint-region.)

---

## DIMENSION 5 — CHECK-36 COMMIT-FRAMING

**Verdict: PASS.**

- **A1, B1, B1b, B2, B3, E1 → NEUTRAL:** correct. A1 spans `project-template/docs/project/` sidecars + `scripts/`; B1b edits `_lib.sh` (shared lib, outside project prefixes) + `test-per-entry.sh`; a `pack-only`/`project-only` keyword on any of these would trip Check 36. Neutral framing (no keyword → Check 36 skipped) is the right call. ✓
- **D1 → `pack-chat-only` valid:** project-template trinity (`CLAUDE/AGENTS/GEMINI.md`) IS pack-chat-only per CLAUDE.md line 78 + PACK-AGENTS.md. If D1's diff is the trinity only, the keyword fits. ✓ (the substantive rewrite still routes to coder per `pack-chat-minor-edits-only` — correctly noted.)
- **D2–D6 → `project-only` valid:** verified every O14/O16/O17/O18/O21 file is within the `project-only`-permitted set (`project-template/` + `supporting-docs/`): `supporting-docs/METHODOLOGY.md` (O14), `supporting-docs/{MIGRATION-v10-to-v11,CLI-PM-SETUP,INSTALL-PROCEDURES,SETUP-NEW,SETUP_TEMPLATE}.md` (O21/O17), `project-template/docs/pack/{PM-CHAT,HELP-FRAGMENT}.md` + `project-template/skills/*` (O16/O17/O18). None touches a pack-only path. ✓
- **BD-249 → `pack-only` valid:** touches only `scripts/` (no `project-template/`/`supporting-docs/`). ✓
- The plan correctly invokes `commit-subject-keyword-token-trap` (verify `git diff --name-only` before each commit; default NEUTRAL in doubt). ✓

No keyword-vs-file-set mismatch found.

---

## DIMENSION 6 — BD-249 COORDINATION + JOINT GREP-ZERO GATES

**Verdict: PASS.**

Independently reproduced the gate baselines at HEAD `66c8332`:
```
mirror-subsystem gate   git grep -nE 'mirror-generate|per_entry_regenerate_mirror|pe_canonical_mirror_for_stream|mirror\) printf' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'   → 81   [plan says 81]
two-var force-overwrite git grep -nE '_MIGRATOR_FORCE_OVERWRITE_MIRROR|PE_FORCE_OVERWRITE_MIRROR|force-overwrite-mirror' -- ':!maintenance-docs/' ':!changelog/' ':!backlog/'   → 103  [plan says 103]
_format.md (waves)      git grep -nE '_format\.md' -- ':!maintenance-docs/' ':!backlog/' ':!changelog/'   → 78
until BD-206            git grep -nE 'until BD-206' -- ':!maintenance-docs/' ':!backlog/' ':!changelog/'   → 15
```
The 81 + 103 baselines match the plan exactly. The gate-timing logic is sound and safely asserted:
- The mirror-subsystem joint gate (81→0) and two-var gate (103→0) reach zero only JOINTLY across BD-206 (O22-proj/B1b + build.sh/A1 + flag/B1) AND BD-249 (mirror-generate.sh + pack constants). The plan correctly states the BD-206 reviewer asserts only its SHARE clean, never a premature global zero (§3 BD-249 verification; §9). ✓
- `_format.md` grep-zero spans A1+C2+D6+E1 (GAP-1) — the plan correctly distributes it and asserts global zero only at batch end, not at A1. ✓
- `mirror-generate.sh` deletion is correctly sequenced TERMINAL (after A1 removes the build.sh source line + B1 removes the migrator callers → only dead tests remain) — verified against BD-249.md (`Blockers: BD-206 — sequenced DIRECTLY AFTER`). ✓
- A-3 direct-git-pathspec form is used for every gate (not the EE-11 Command-2 variable-glob that returned empty) — correct.

No premature global-zero assertion. The joint-gate model is correct.

---

## DIMENSION 7 — VERIFICATION STRATEGY + BOUNDED CYCLE + MANIFEST

**Verdict: PASS (one SHOULD).**

- **Bounded review/fix cycle:** stated per commit as "≤2 review/fix pairs + 1 final reviewer (architect escalation if dirty after final)" (4 explicit occurrences; §3 A1, §6 approval gates). Matches `review-fix-cycle`. ✓
- **Per-wave full-battery verification:** the §5 protocol runs validate-pack.py + `build.sh --all --clean && --verify` + the auto-discovered shell shard battery (incl. the migration + tracker families) per commit. Confirmed `test-migrate-v10-to-v11-decompose.sh` IS CI-wired (it is in `scripts/tests/*.sh` and is NOT in `scripts/ci-test-wiring-allowlist.txt` — only the live-GH roundtrip test is allowlisted out), so the plan correctly treats it as a battery member. ✓ Honors `verify-full-ci-suite`.
- **CI-runtime-compounding:** §5 flags the new checks O9–O13 as cheap (deterministic counts, parse-schema-once via the `pe_supporting_files_admitted` awk-grammar precedent, `git ls-files` candidate set, SKIP-lenient if git absent). Aware of the ×155 multiplier. ✓
- **SHOULD-1 — manifest-input enumeration is A1-centric and INCOMPLETE.** §5 "Manifest interplay" flags only `build.sh` + `project-template/*` as manifest inputs touched by A1. But `scripts/lib/manifest-inputs.sh:59-60` ALSO declares `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` as manifest inputs — and the D-wave edits BOTH (O14 → METHODOLOGY.md/D4; O17 → INSTALL-PROCEDURES.md/D3). So the D-wave is ALSO a manifest-input-changing wave; the plan's manifest note does not enumerate it. This is a SHOULD (not a correctness break — the push-time `manifest-sync.sh` regenerates from the WHOLE input set regardless of which wave changed an input, and Check 62 + `build.sh --verify` enforce at CI), but the plan's manifest analysis should note the D-wave inputs so the orchestrator does not assume only A1 perturbs the manifest.

---

## SUMMARY OF FINDINGS

| ID | Sev | Dimension | One-line |
|---|---|---|---|
| MUST-1 | MUST | 2/3 | EE-C/GAP-2 "decompose dual-wave break, force-overwrite asserts expected-RED-until-B1 at A1" is a misdiagnosis (Gate-2 cascade, not flag behavior); control proves decompose is GREEN at A1 (45/0) — the reviewer-instruction would mask an A1 regression and contradicts §15. |
| MUST-2 | MUST | 4 | O11/O12/O13 each add a leg to the single monolithic `validate-pack.py`; the §4 parallel Wave-C schedule + "C/D/E touch none of validate-pack.py" disjointness claim is false → patch-apply collision; C3/C4/C5 must serialize (or fold into A1). |
| SHOULD-1 | SHOULD | 7 | Manifest-input enumeration is A1-only; the D-wave also edits manifest inputs `supporting-docs/METHODOLOGY.md` (O14) + `INSTALL-PROCEDURES.md` (O17). Push-time sync still catches it; note it. |
| NIT-1 | NIT | 1 | §0 headline "13 commits" is arithmetically self-contradictory (1+4+2+6+1=14; "2 Wave-C" vs C2..C5=4); self-corrected at §6 (range 12–17, §3 SSOT). Fix the §0 number. |

**Counts:** 2 MUST, 1 SHOULD, 1 NIT. (No BLOCKER.) ≥1 MUST ⇒ **NEEDS-REWORK**.

### What is correct and should NOT be re-opened
The deliverable completeness (all 27 mapped), the A-1 discovery of the migration battery as a real Wave-A surface, every grep-zero gate baseline (81/103) and their joint-gate timing, the BD-249 terminal-deletion sequencing, all Check-36 framings, the bounded-cycle spec, the CI-runtime-compounding awareness, and the six §1 amendments (not re-litigated) are SOUND. The two MUSTs are localized: a wrong reviewer-instruction (MUST-1) and a missing serialization edge (MUST-2) — both fixable without redesign.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (measured) | Conclusion |
|---|---|---|
| **verify-full-ci-suite** | Independently re-ran validate-pack.py (14 issues), the 4 migration tests (33/12, 48/6, 57/4, 80/7), and 6 EE-D tests — all reproduce the plan's verbatim numbers; confirmed `test-migrate-v10-to-v11-decompose.sh` is CI-wired (in `scripts/tests/*.sh`, not in `ci-test-wiring-allowlist.txt`); ran a clean-clone control (45/0) to isolate the decompose root cause. Full battery exercised, not sampled. | COMPLIANT |
| **architect-planner-empirical-evidence / evidence-grounded findings** | Every finding carries the command + verbatim output + file:line + HEAD `66c8332` + 2026-06-26: EE-A grep, decompose FAIL list, `git clone ... → Passed:45 Failed:0`, `migrator-core.sh:74 EXIT_GATE_FAILED=31`, `wc -l validate-pack.py = 11799` + 92 `check_*`, `manifest-inputs.sh:59-60`, two grep-zero gate counts (81/103). | COMPLIANT |
| **review-fix-cycle (bounded)** | Verified the plan states "≤2 review/fix pairs + 1 final reviewer; architect escalation if dirty after final" per commit (4 occurrences). | COMPLIANT |
| **ci-check-runtime-compounding** | Assessed §5's new-check cost analysis (deterministic counts, parse-once, git ls-files, SKIP-lenient) — found adequate; no whole-tree scan / subprocess-per-entry storm introduced by the plan. | COMPLIANT |
| **manifest-regen-push-time** | Verified the plan's push-time manifest model (manifest-sync at push, Check 62 + build.sh --verify) and found the D-wave manifest inputs un-enumerated (SHOULD-1); push-time sync from the whole input set is still correct. | COMPLIANT |
| **commit-subject-keyword-token-trap** | Verified each commit's framing vs its actual file set (A1/B1/B1b/B2/B3/E1 NEUTRAL; D1 pack-chat-only; D2-D6 project-only; BD-249 pack-only) against `git ls-files` locations + CLAUDE.md line 78; no keyword-vs-fileset mismatch. | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | Ran only read-only git (`rev-parse`, `status`, `grep`, `ls-files`, `clone` to a /tmp scratch), read-only `validate-pack.py`, read-only shell tests in /tmp clones; HEAD unchanged at `66c8332`, working tree still exactly the 8 deletions, no worktree added to the repo. Sole write = this report. No state-changing git verb. | COMPLIANT |
| **graph-first-context** | DISCOVERY: used grep/ls-files/file-reads for a bounded, fully-named candidate set (the plan's enumerated files); verification reads confirmed exact bytes/counts. The questions were verification-of-named-surfaces (P2) + freshly-uncommitted-state (the 8 deletions) — graph not required; no broad "what relates to X" discovery left ungrounded. | COMPLIANT |
| **spawn-unique-naming** | Operating as `reviewer-bd206-plan-adversarial-2` (report header + this row). | COMPLIANT |
| **rules-applied-verification-block / agents-read-rule-docs-in-full** | This block exists with per-rule measured evidence. READ-IN-FULL: PLAN-BD-206.md (383 lines), ARCHITECTURE-BD-206.md (deliverables O0–O26 §4 + §6 map + EE-9 + DR-1/2 — read), DECISIONS-BD-206-RESTART.md (full, esp. §13/§15/§16), backlog/BD-206.md + BD-249.md (full), pack-root CLAUDE.md `## Pack memory` (in-context, full), and the named memory files: feedback_verify_full_ci_suite.md, feedback_architect_planner_empirical_evidence.md, feedback_review_fix_cycle.md, feedback_ci_check_runtime_compounding.md, feedback_manifest_regen_on_v11_surface.md, feedback_commit_subject_keyword_token_trap.md, feedback_agent_output_rules_applied_block.md, feedback_agents_read_rule_docs_in_full.md, feedback_worktree_isolation_mergeback_ops.md (each read via Read tool). Anti-contamination: NO prior BD-206 PLAN, NO prior review, nothing under /tmp/bd206-REJECTED-DO-NOT-READ/. | COMPLIANT |

**HEAD:** `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7` — **Date:** 2026-06-26 — **Reviewer:** `reviewer-bd206-plan-adversarial-2` — **Report:** `/Users/david/Developer/_tmp/pack-handoff-bd206-restart/ADVERSARIAL-PLAN-REVIEW-BD-206.md`
