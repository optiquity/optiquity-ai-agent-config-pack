# IMPLEMENTATION-REPORT — BD-196 Commit C6

**Commit:** C6 of 12 — Wire the B5 boundary-pointer manifest + the spawn-rule
reference-resolution + anti-restate check (Check 46), with its per-check test and
CI wiring, against the C4/C5-cleaned tree.

**Agent:** pack-coder. **Branch:** `v11-dev`. **Base / final HEAD:**
`0cbd6d5f70a6730da2023d8f2bcf45fc06cd9800` (no commits made; working-tree edits
only — Pack Chat commits).

**Plan:** `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md`
commit C6 (+ G-A). **Design:**
`maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` (v9)
§4.3 (B5) + §9.6 (spawn-rule reference-resolution + anti-restate) + §7-area SC7.

---

## 1. Files changed (inventory)

| Path | Change type |
|---|---|
| `pack-ops/.boundary-pointer-manifest.txt` | **new** (B5 entry-point pointer manifest) |
| `scripts/validate-pack.py` | modified (add Check 46 fn + 2 helpers + `main()` callsite) |
| `scripts/tests/test-validate-pack-check-46.sh` | **new** (per-check test) |
| `.github/workflows/validate-pack.yml` | modified (wire test-46; one step) |

`git status --short`: ` M .github/workflows/validate-pack.yml`,
` M scripts/validate-pack.py`, `?? pack-ops/.boundary-pointer-manifest.txt`,
`?? scripts/tests/test-validate-pack-check-46.sh`. HEAD unchanged.

---

## 2. The B5 boundary-pointer manifest (`pack-ops/.boundary-pointer-manifest.txt`)

The §6 replacement: a machine-readable `surface → expected-pointer` record set.
Each record = `surface:` (repo-relative path) + `pointer:` (the literal substring
the surface MUST contain to resolve — the basename `BOUNDARY-DEFINITION.md`) +
`role:` (human-readable context, not parsed). Blank-line-separated; `#` comments.
Format intentionally mirrors `pack-ops/.spawn-rule-manifest.txt` (C5).

**8 surfaces manifested (measure-then-bound — see §4):**

| # | Surface | Pointer (resolves) |
|---|---|---|
| 1 | `README.md` | `BOUNDARY-DEFINITION.md` |
| 2 | `.claude/skills/boundary-investigation/SKILL.md` | `BOUNDARY-DEFINITION.md` |
| 3 | `.codex/skills/boundary-investigation/SKILL.md` | `BOUNDARY-DEFINITION.md` |
| 4 | `.gemini/skills/boundary-investigation/SKILL.md` | `BOUNDARY-DEFINITION.md` |
| 5 | `project-template/CLAUDE.md` | `BOUNDARY-DEFINITION.md` |
| 6 | `project-template/AGENTS.md` | `BOUNDARY-DEFINITION.md` |
| 7 | `project-template/GEMINI.md` | `BOUNDARY-DEFINITION.md` |
| 8 | `project-template/skills/boundary-investigation/SKILL.md` | `BOUNDARY-DEFINITION.md` |

The manifest header explicitly documents that this is the **entry-point network
only** (the §11.3 per-actor routing pointers are C8's job — see §8) and that it
enumerates **only surfaces that actually resolve at this HEAD** (the §6 prose
named aspirational surfaces that never carried the pointer — see §4).

---

## 3. Check 46 logic (`check_boundary_and_spawn_pointer_manifests`)

Implemented as **ONE combined function** (PLAN §2 G-A: the design left the 3-vs-4
split as a coder call; one function over both manifests minimizes surface and
shares the parse + resolution helpers). Callsite added immediately after Check 45
in `main()` with a comment block citing §4.3 + §9.6 + G-A. Two new module-level
helpers: `_parse_manifest_records()` (blank-line `key: value` parser, handles
wrapped `references:` continuation lines) and
`_check_46_extract_pack_memory_imperative_bodies()` (the SC7-bounded body
extractor).

**(a) Reference-resolution (Check-34 pattern).**
- *Boundary manifest:* for each `surface`, the file must EXIST and must CONTAIN
  the `pointer` substring. Missing file → FAIL (named, with remediation); present
  but pointer-absent → FAIL.
- *Spawn manifest:* for each record, `canonical:` must name `## Pack memory`; the
  `references:` free-text must name a known reference surface
  (`PACK-AGENTS.md` / `PACK-CHAT.md`); each named surface must EXIST and must
  itself reference `## Pack memory` so the collapsed one-line pointer resolves to
  the SSOT.

**(b) Anti-restate substring scan (SC7-bounded — see §5).** No `## Pack memory`
imperative **BODY** (first clause, whitespace-normalized, `>= 60` chars) may
appear verbatim in any of the 6 spawn-relevant surfaces
(`PACK-AGENTS.md`, `PACK-CHAT.md`, + the 4 spawn-relevant skills
`commit-discipline` / `review` / `planning` / `implementation-report`). A hit →
FAIL with the offending surface + the matched body + collapse-to-one-line
remediation.

**Lenient mode:** if BOTH manifests are absent the check SKIPs (init/state, not a
violation).

---

## 4. Design-vs-reality finding (load-bearing — drove the manifest scope)

**The historical §6 prose described an aspirational pointer network, not the
real tree.** The deleted §6 (now in
`maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md`) claimed the boundary
doc was "referenced from every operating-doc entry point" and enumerated
`README`, `PACK-CHAT.md`, `PACK-AGENTS.md`, the pack-root trinity, project
`PM-CHAT.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`, the pack-* agents, and the CI
gate.

Measured at HEAD `0cbd6d5` — which of those actually carry a resolving
`BOUNDARY-DEFINITION.md` reference:

| §6-claimed surface | Carries pointer at HEAD? |
|---|---|
| `README.md` | YES |
| `pack-ops/PACK-CHAT.md` | **NO** |
| `pack-ops/PACK-AGENTS.md` | **NO** |
| pack-root trinity (`CLAUDE/AGENTS/GEMINI.md`) | **NO** |
| `project-template/docs/pack/PM-CHAT.md` | **NO** |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | **NO** |
| pack-* agents (`.claude/.codex/.gemini/agents/pack-*`) | **NO** |
| CI gate (`scripts/validate-pack.py`) | YES (code comments; not a doc pointer) |

The surfaces that DO carry a resolving pointer are the 8 in §2 (README + the 3
pack-side boundary-investigation skills + the project trinity + the project-side
boundary-investigation skill). Per **CI-guard design — measure-then-bound** and
the WORKING-STATE rule, I manifested ONLY surfaces that resolve at HEAD; naming
the aspirational §6 surfaces would have FAILed Check 46 at HEAD (a self-inflicted
working-state break). This is documented in the manifest header; adding a surface
to the manifest requires that surface to first acquire its pointer (a future
edit — and the §11.3 C8 work is one such future addition).

C4's IMPL-REPORT §6 verified the operating surfaces point at the DOC (no deleted
*section* refs) but did not measure literal-pointer presence per surface; this C6
measurement is the first time the §6 network was bound to reality. Surfaced for
reviewer awareness — it is faithful to the design's intent (a CI-asserted network
that cannot silently go stale) and to measure-then-bound.

---

## 5. SC7 anti-restate-predicate measurement (load-bearing)

The §9.6 anti-restate scan can false-positive on a legitimate one-line reference
that NAMES a rule (the §4.2 12/12-storm shape). I MEASURED two candidate
predicates against the real post-C5 surfaces before wiring.

**Candidate A — NAIVE (rule-NAME proxy; the storm-prone shape).** Predicate =
each bullet's bold-lead rule NAME, substring-scanned against the 6 surfaces.
**Result: 6 hits, ALL legitimate name-bearing references** (the C5-collapsed
one-line pointers):

```
HIT [PACK-AGENTS.md] <- 'Agents never commit'                 (L117: "...Agents never commit — see trinity `## Pack memory`...")
HIT [PACK-CHAT.md]   <- 'One review/fix cycle per batch'       (L127: cites `### Workflow` "One review/fix cycle per batch")
HIT [PACK-CHAT.md]   <- 'Pack Chat presents triage to user before fix-coder spawns'  (L66: names the rule)
HIT [skill:review]   <- 'Deferral IS scope creep'             (L51: "...operationalizes pack memory 'Deferral IS scope creep'...")
HIT [skill:review]   <- 'Project-side concepts on pack-side surfaces — deliverable-only'  (L26: names the rule)
HIT [skill:review]   <- 'Enumerate ENCODING surfaces in pack-side audits'  (L38: names the rule)
```

The naive predicate **STORMS on legitimate references** — exactly the §4.2 shape.
**It was NOT wired.**

**Candidate B — BOUNDED (imperative BODY, length-thresholded; WIRED).** Predicate
= each bullet's imperative BODY (text AFTER the bold name), whitespace-normalized,
leading 120-char window, kept only if `>= 60` chars; substring-scanned against the
whitespace-normalized surfaces. **Result: 0 hits post-C5-collapse.** Validation it
is not vacuous: injecting a verbatim `>= 60`-char imperative body into a surface →
the predicate **catches it** (measured `caught = True`). The 60-char bound is
**body-derived, not name-derived**: the predicate scans the imperative BODY (the
text AFTER the bold rule name — the NAME group is discarded by
`_check_46_extract_pack_memory_imperative_bodies`), so rule-NAME length is
irrelevant (names are never scanned and cannot false-positive — measured: 5 rule
names are themselves ≥60 chars, the longest being 66, yet none trip the check
because the scan never sees a name). The window is chosen empirically — every real
`## Pack memory` imperative body's leading clause exceeds 60 chars (no false-
negative: a genuine verbatim restatement is caught), while a legitimate one-line
reference (which names the rule and paraphrases, not reproducing 60+ contiguous
verbatim chars of a body) cannot reach the threshold (no false-positive). The
bound thus separates one-line NAME references from verbatim BODY restatements. The
bound + measurement are recorded inline in the check's source comment.

Conclusion: **measure-then-bound applied to the anti-restate predicate.** The
storming predicate was rejected; the bounded predicate (0 hits + catches
injected restatements + no name-reference storm) was wired.

---

## 6. Check 46 PASSES at HEAD (working-state proof)

`python3 scripts/validate-pack.py` → `PASSED — all checks clean` (EXIT 0). Check 46
line:

```
── Check 46: boundary + spawn-rule pointer manifests (BD-196) ──
  OK: Check 46 — boundary manifest: 8 surface(s) resolve their BOUNDARY-DEFINITION
  pointer; spawn manifest: 6 rule(s) resolve to `## Pack memory`; anti-restate:
  0 verbatim imperative-body restatements across 6 spawn-relevant surface(s)
  (45 candidate bodies scanned, >= 60 chars).
```

**Check 42 (CI-wiring guard) stays green:** `12 per-check test file(s) on disk;
12 workflow invocation(s) found; zero unwired tests` (was 11/11 before test-46 +
its wiring landed together this commit).

---

## 7. test-46 cases (PASS + the FAILs it catches)

`scripts/tests/test-validate-pack-check-46.sh` — verification-harness pattern
(synthetic tmp REPO_ROOT, no real-file mutation, cleanup on every exit path):

- **Group 0:** module import + Check 46 symbols registered
  (`check_boundary_and_spawn_pointer_manifests`, `_parse_manifest_records`,
  `_check_46_extract_pack_memory_imperative_bodies`).
- **Group 1 (T1-T6):**
  - **T1 PASS** — both manifests resolve, no restatement.
  - **T2 FAIL** — boundary surface present but MISSING its pointer (catches the
    silent-drift case the §6 prose could not).
  - **T3 FAIL** — boundary surface named in the manifest does NOT exist on disk.
  - **T4 FAIL** — verbatim imperative BODY reintroduced into a spawn-relevant
    skill (the anti-restate teeth).
  - **T5 PASS** — a one-line NAME-bearing reference does NOT storm (the SC7 /
    §4.2 12/12 false-positive shape proven inert by the bounded predicate).
  - **T6 FAIL** — a spawn reference surface lost its `## Pack memory` canonical
    pointer (the collapsed one-line pointer no longer resolves to the SSOT).
- **Group 2:** end-to-end `validate-pack.py` exits 0 + Check 46 clean-output
  present at HEAD.

Result: PASS 3 / FAIL 0. Neighbors confirmed green: test-45 (3/0),
test-checks-32-33-34 (65/0), test-42 (4/0). All 12 `test-validate-pack-check*.sh`
files PASS.

---

## 8. C6-vs-C8 §11.3 routing-pointer note (plan-internal inconsistency, SURFACED)

The plan's C6 prose (PLAN §3 C6 "Changes" + §3 C6 line 94 + the §8-step map row
"4e") says C6's manifest "includes the §11.3 routing pointers (PACK-CHAT 'File
access strategy' 4 pointers; ... review skill)". **The C6 spawn prompt's SCOPE
CLARIFICATION re-resolves this:** the §11.3 per-actor routing pointers are
authored in **C8** and folded into the manifest THEN — NOT in C6. C6 creates the
**entry-point pointer network only** (the surfaces that point AT
`BOUNDARY-DEFINITION.md`).

I implemented per the spawn prompt's clarification: the manifest contains the
8 entry-point surfaces, NOT the §11.3 routing pointers. The manifest header
explicitly states the routing pointers are C8's and will be folded in then.

**SURFACED inconsistency (per the prompt's instruction):** PLAN §3 C6 prose and
the §8-step map row "4e (C6 manifest fold)" attribute the §11.3 routing-pointer
fold to C6; the C6 spawn prompt attributes authoring to C8. These conflict on
WHERE the routing pointers are authored. I followed the spawn prompt (C8). The
PLAN row "4e" reads `C6 (manifest fold) + C8 (pointers)` — reconcilable as "C8
authors the pointers AND folds them into the manifest"; the C6-prose "includes
the §11.3 routing pointers" is the inconsistent clause. Recommend Pack Chat note
this so C8's prompt makes the manifest-fold explicitly C8's.

---

## 9. Manifest regen note

Manifest regen is **Pack Chat's at commit**. C6 touches `pack-ops/` + `scripts/`
(v11-surface), so the `test-fixtures/manifest.txt` regen trigger fires — but per
the prompt I did NOT run `test-fixtures/build.sh` and did NOT stage the manifest.
Pack Chat runs `bash test-fixtures/build.sh --all --clean` and stages any
`manifest.txt` diff alongside the C6 scope edits in the same commit. (The new
`pack-ops/.boundary-pointer-manifest.txt` is a pack-only file not installed by
`scripts/init-project.sh`, so the manifest diff is expected-empty — but the
rebuild+check is Pack Chat's mandated step.)

---

## 10. Plan deviations

**One scope reconciliation (per the spawn prompt, not a deviation from the
approved scope):** the §11.3 routing pointers were NOT authored here (deferred to
C8 per the prompt's SCOPE CLARIFICATION) — see §8. **G-A resolution:** Check 46
implemented as ONE combined function (the plan's stated default; the coder-split
option not taken). No other deviations. No new POQs.

---

## 11. New POQs introduced

None. (§4 design-vs-reality and §8 C6-vs-C8 are SURFACED observations with a
followed disposition, not open questions blocking C6.)

---

## 12. Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| `pack-ops/.boundary-pointer-manifest.txt` authored (B5; §6 replacement) | PASS |
| Manifest = entry-point surfaces only (NOT §11.3 routing pointers — C8's) | PASS |
| Manifest scoped to surfaces that resolve at HEAD (measure-then-bound) | PASS |
| Check 46 added: reference-resolution over BOTH manifests | PASS |
| Check 46 added: SC7-bounded anti-restate substring scan | PASS |
| `main()` callsite after Check 45 | PASS |
| SC7 predicate MEASURED before wiring; storming predicate rejected | PASS |
| Bounded predicate = 0 hits at HEAD + catches injected restatement | PASS |
| Check 46 PASSES at HEAD (`validate-pack.py` EXIT 0) | PASS |
| `scripts/tests/test-validate-pack-check-46.sh` authored (PASS + injected FAILs) | PASS |
| test-46 wired in `.github/workflows/validate-pack.yml`; Check 42 green (12/12) | PASS |
| test-46 + neighbors (45 / 32-33-34 / 42) PASS; all 12 per-check tests PASS | PASS |
| No git state changes; no manifest build/stage (Pack Chat's) | PASS |
| C6-vs-C8 §11.3 inconsistency surfaced | PASS |
| Trinity: not triggered (no trinity file edited) | PASS (N/A) |

---

## 13. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No state-changing git verb run; `git status --short` = 2 ` M` + 2 `??`; `git rev-parse HEAD` = `0cbd6d5` unchanged. Deliverable = working-tree edits + this IMPL-REPORT. | COMPLIANT |
| EDIT IN PLACE — targeted Edits to validate-pack.py | Two `Edit` calls: appended Check 46 fn/helpers before `# ── Main`, inserted callsite after `check_pack_memory_rationale_bijection()`. No rewrite of the file. | COMPLIANT |
| NEW-CHECK WIRING DISCIPLINE (Check 42) | Check 46 has fn + `main()` callsite + per-check test (`test-validate-pack-check-46.sh`) + CI-workflow wiring line — ALL in this commit. Check 42 = `12 on disk; 12 invocations; zero unwired`. | COMPLIANT |
| WORKING-STATE (Check 46 PASS at HEAD) | `validate-pack.py` EXIT 0; Check 46 `OK: ... 8 surface(s) resolve; 6 rule(s) resolve; anti-restate: 0 restatements`. Manifest scoped to resolving surfaces (measure-then-bound) precisely so HEAD is clean. | COMPLIANT |
| SC7 MITIGATION (anti-restate predicate measured before wiring) | §5: naive rule-NAME predicate measured = 6 storm hits (all legit name refs) → REJECTED; bounded BODY predicate (>=60 chars) = 0 hits + catches injected restatement → WIRED. Bound recorded in source comment. | COMPLIANT |
| PREFLIGHT before IMPL-REPORT | PREFLIGHT line emitted before this Write; `validate-pack.py` full suite (incl. Check 46 + 42 wiring + 43 + 45) PASS; test-46 + neighbors 32/34/45/42 PASS; all 12 per-check tests PASS (§6/§7). Manifest build NOT run (Pack Chat's). | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |
| Trinity rule | C6 edited 0 trinity files (`CLAUDE/AGENTS/GEMINI.md` at pack-root or project-template). The boundary manifest NAMES project trinity as check targets (reference-resolution data, like Check 37/43 walking project-side trees), but does not EDIT them. | N/A: trinity not triggered |
| Prison rule | No file under `maintenance-docs/prison/` read, cited, or trusted. `archive/v11/BOUNDARY-DEFINITION-HISTORY.md` (readable history, NOT prison) consulted for the deleted §6 entry-point list. | COMPLIANT |
| Boundary discipline (P-missed-7) | The new manifest is a PACK-ONLY file (`pack-ops/`); it does not import a pack mechanism into a project-side file. It NAMES project-side surfaces (`project-template/` trinity + skill) as reference-resolution targets — the same allowed pattern as the pack-side Check 37/43 walking project-side trees (a pack validator verifying project-side structure). No project-side file was edited; no project-side SSOT augmentation needed. | COMPLIANT |
| CI guard design — measure-then-bound | §4: the boundary manifest was scoped by MEASURING which surfaces actually resolve at HEAD (8 KEEP) and EXCLUDING the aspirational §6 surfaces that do not carry the pointer (would FAIL); §5: the anti-restate allowlist/predicate was sized to the BODY (not NAME) by measurement, never widened to admit the storm. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-196-C6.md.**
