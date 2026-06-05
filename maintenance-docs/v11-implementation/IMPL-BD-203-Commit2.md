# IMPL-BD-203 Commit 2 — ATOMIC conversion EDITS (Phase B + C + D4 A13-INVERSE)

**Agent:** pack-coder · **Date:** 2026-06-05 · **Branch:** v11-dev
**Worktree base HEAD:** `4c370dac0963dfbea9f358535811a7c86aa2cfb9`
**Final HEAD (no commits made — agents never commit):** `4c370da` (unchanged)
**Mode:** implementation. Trees built + refs corrected + D4 edits applied; monoliths NOT deleted (Pack Chat `git rm`s them).

---

## ⛔ PREFLIGHT NOT CLEAN — STOP-AND-REPORT (read this first)

Per the prompt's PREFLIGHT contract ("Check 32′ MUST be the ONLY failing
check … If ANY OTHER check failed … report what went wrong INSTEAD of a
partial IMPL-REPORT"), I am reporting a **STOP condition**, NOT emitting the
clean PREFLIGHT line.

**Why:** validate-pack on my working tree (monoliths present) has SIX FAILs;
in the simulated post-`git rm` state it has NINE genuine FAILs that DO NOT
clear on deletion. The expected-RED set was supposed to be exactly Check 32′
(+ the Check-36 HEAD transient). Two ADDITIONAL non-transient failure classes
surfaced — both are **plan gaps**, not coder errors, and both require
Pack-Chat / architect / user disposition (I did NOT silently work around them
or edit byte-faithful entry bodies):

1. **3 Check-34 dangling cross-refs** (`v12.0`×2, `BD-19b`) — pre-existing
   monolith content, byte-faithfully preserved, surfaced now that the
   per-entry tree makes Check 34 ACTIVE. The plan's FLAG-b measure-then-bound
   only covered `vN.M`-resolves-to-`vN`; it did not anticipate a future-major
   (`v12`, no entry) or an informal token (`BD-19b`, from "Batch 19b").
2. **6 Check-40 bare-refs across 4 files NOT in the plan's C1–C8**
   (`BOUNDARY-DEFINITION.md`, `DRY-RUN-MIGRATION.md`, `OPTIONAL-FEATURES.md`,
   `PACK-MEMORY-RATIONALE.md`) — once the monoliths are deleted, bare
   ``` `BACKLOG.md` ``` / ``` `CHANGELOG.md` ``` references in these files
   become "broken ref" FAILs. The plan's A11 said the Check-40 exclusion was
   "moot post-deletion"; that is wrong for OTHER pack-ops files that
   *reference* the deleted monoliths.

Everything in the plan's explicit scope (B1–B9, C1–C7-partial, D4, B8 +
every lockstep test) is DONE and verified. The two gaps above are the only
things standing between the post-delete state and full CI-green. They are
detailed in §"New POQs / plan gaps" with recommended dispositions. The trees
+ oracle are GREEN; no entry was lost (211 == 211, 11 == 11).

---

## 1. Summary of what landed (in-scope, complete + verified)

| Task | Status | Verification |
|---|---|---|
| B1 mkdir `/backlog/` + `/changelog/` | DONE | dirs present |
| B4 decompose (211 backlog + 11 changelog) | DONE | count oracle 211==211, 11==11 GREEN |
| B2 `_rules.md` ×2 (no-mirror, audience+purpose, Unblocked, suffix regex, ID-extraction) | DONE | authored per amendment §F / V3 §2.6 |
| B3 `_intro.md` ×2 (human-only, audience+purpose, relocated preamble) | DONE | authored per amendment §F |
| B5 regenerate TOCs | DONE | Check 33 byte-identical PASS; suffix adjacency verified |
| B8 drop `_v8-resolved-archive.md` residue (`_lib.sh` + validate-pack.py ×2 + 3 test files) | DONE | tests GREEN |
| B9 widen `entry_sort_key` for suffix | DONE | BD-167b adjacent to BD-167 in TOC |
| C1 trinity rule rewrite ×3 (no-mirror; project mirror → BD-206) | DONE | trinity parity verified |
| C2 trinity Key-files ×3 (+ operational refs) | DONE | trinity parity |
| C3 PACK-AGENTS (Files-rows removed = D4(c); forward-note; access table; B8 archive) | DONE | post-delete sim: PACK-AGENTS bare-refs cleared |
| C4 PACK-CHAT (file-access table; separation rule; recommendation signal) | DONE | post-delete sim: PACK-CHAT bare-refs cleared |
| C5 README (layout blocks ×2; deleted-monolith rows removed) | DONE | no-mirror wording |
| C6 HELP-FRAGMENT-PACK (See-also) | DONE | tree refs |
| C7 skill/agent copies ×3 CLIs | **PARTIAL** — pack-startup (Claude) done; ~20 files remain | see §"Incomplete in-scope work" |
| D4(a) validator: re-remove monoliths from `_PACK_CHAT_ONLY_PERMITTED_PATHS` | DONE | grep confirms removal |
| D4(b) test: flip T6d/T6e True→False + add tree-path T6d2/T6e2 | DONE | Group-1 unit tests GREEN |
| FLAG-b (verification item 3): `vN.M`→`vN` bounded resolution | DONE | ~360 `vN.M` FAILs collapsed to GREEN |
| Cross-stream `TD-` tolerance (Check 34 contract conformance) | DONE | TD-010/TD-040 FAILs cleared |
| Manifest regen | DONE | empty diff (trees are not fixtures); no staging needed |

**Oracle (§7) result: GREEN.** Count (211 == measured 211; 11 == 11),
content-faithfulness (211/211 + 11/11 byte-faithful), status-preservation
({Open 28, Unblocked 1, Deferred 11, Resolved 167, Deprecated 3, Cancelled 1}
= 211, one Status/file), TOC in-sync — all GREEN.

---

## 2. Entry counts (live-measured at conversion time — NOT hard-coded)

```
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md           → 211   (live monolith header count)
$ ls backlog | grep -cE '^BD-[0-9]+[a-z]*\.md$'     → 211   (per-entry files)  → MATCH
$ grep -cE '^## v' pack-ops/CHANGELOG.md            → 11
$ ls changelog | grep -cE '^v[0-9]+\.md$'           → 11    → MATCH
```

NOTE: the count is **211**, not the plan's projected **209**. Commit 1
(pre-normalize, `a5a8ad8`) landed and promoted the 19 v8 rows + flattened
scaffolding; the BACKLOG then grew by 2 more entries since the plan's
`a630a31` measurement. The oracle measured live (per EE-P1 "never hard-code").
Suffix entries `BD-167b.md` / `BD-169b.md` present; parenthetical
`BD-195 (Code Red 3)` → `BD-195.md` (parenthetical in body, not filename).

Status distribution (monolith == tree, exact):
`{Cancelled 1, Deferred 11, Deprecated 3, Open 28, Resolved 167, Unblocked 1}` = 211.

---

## 3. validate-pack state (this is the load-bearing evidence)

### 3a. CURRENT working tree (monoliths PRESENT — my coder stage)
`python3 scripts/validate-pack.py` → EXIT 1; SIX FAILs:

| # | Check | FAIL | Class |
|---|---|---|---|
| 1 | 32′ | `pack-ops/BACKLOG.md still present while backlog/ tree exists` | EXPECTED-RED (Pack Chat `git rm` clears) |
| 2 | 32′ | `pack-ops/CHANGELOG.md still present while changelog/ tree exists` | EXPECTED-RED (Pack Chat `git rm` clears) |
| 3 | 36 | `Commit 4c370da claims pack-chat-only but touches pack-ops/BACKLOG.md` | EXPECTED-RED transient (see §4) |
| 4 | 34 | `backlog/BD-069.md:13 references v12.0` | **GENUINE — plan gap (POQ-1)** |
| 5 | 34 | `backlog/BD-114.md:48 references v12.0` | **GENUINE — plan gap (POQ-1)** |
| 6 | 34 | `backlog/BD-173.md:35 references BD-19b` | **GENUINE — plan gap (POQ-1)** |

### 3b. SIMULATED post-`git rm` state (non-destructive; monoliths moved aside + restored byte-identical)
`validate-pack` → EXIT 1; NINE genuine FAILs (Check 32′ now PASS):

- Check 34 (3): `v12.0`×2, `BD-19b` — **POQ-1** (persist after deletion).
- Check 40 (6 across 4 files): `BOUNDARY-DEFINITION.md`(2), `DRY-RUN-MIGRATION.md`(1),
  `OPTIONAL-FEATURES.md`(2), `PACK-MEMORY-RATIONALE.md`(1) — **POQ-2** (persist after deletion).
- Check 36 (1): `4c370da pack-chat-only` HEAD transient — clears when Commit 2
  (subject `pack-only`) becomes HEAD.

Check 32′ post-delete: **PASS** for both streams
(`backlog/ — no monolith present; _rules.md + _toc.md present; filenames conform`).
Check 33 post-delete: **PASS** (both `_toc.md` byte-identical).

**Conclusion:** the ONLY blockers to a fully-green post-conversion committed
state are POQ-1 (3 refs) + POQ-2 (6 bare-refs) + the benign Check-36 HEAD
transient. Disposition both POQs and the post-`git rm` commit is green.

---

## 4. Check-36 HEAD transient (benign — explained, not a defect)

Check 36 default-walks ONLY HEAD (`_commits_to_walk` → `git log -1 HEAD`; the
per-push CI-gate pattern). HEAD is currently `4c370da` (BD-209 Resolved,
subject `pack-chat-only`), which touched ONLY `pack-ops/BACKLOG.md`. My D4
A13-INVERSE removed `pack-ops/BACKLOG.md` from the permitted-paths set, so
4c370da retroactively fails Check 36. This is structurally identical to the
Check-32′ expected-RED: it is HEAD-relative and clears the instant Pack Chat
commits Commit 2 (subject `pack-only`, which denies only project-side paths;
the conversion touches ZERO project-side paths → Commit 2 passes Check 36).
Verified: `_is_project_side_path` returns `[]` for the full Commit-2 path set
(`backlog/**`, `changelog/**`, trinity, `pack-ops/*`, `scripts/*`). No action
needed — it is the BD-209/D4 lockstep working as designed.

---

## 5. New POQs / plan gaps (SURFACED — do not invent; require disposition)

### POQ-1 — 3 pre-existing Check-34 dangling cross-refs surfaced by the live tree

`v12.0` (BD-069.md:13, BD-114.md:48) and `BD-19b` (BD-173.md:35) are flagged
dangling. **All three are byte-faithful pre-existing monolith content** (NOT
my regression — verified verbatim in `pack-ops/BACKLOG.md`). Check 34 was SKIP
before BD-203 (no tree existed); it goes ACTIVE now that the tree is the SSOT,
so these surface for the first time.

- `v12.0` — a FUTURE major version with no `/changelog/v12.md` entry.
  BD-069: "v11.1→v12.0 fixture"; BD-114: "Required before tagging v11.0,
  v12.0, … etc." My FLAG-b bounded fix resolves `vN.M`→`vN` ONLY when `vN` is
  defined; `v12` is undefined, so `v12.0` correctly is NOT auto-resolved
  (measure-then-bound: sized exactly, never widened to swallow it).
- `BD-19b` — `CROSS_REF_RE` (`BD-\d+[a-z]*`) tokenizes "Batch 19b BD-19b
  research" → `BD-19b`. There is no BD-19b entry; the `b` belongs to
  "Batch 19b". The regex docstring already states it tolerates false positives
  in prose per §11.2.

**Why I did NOT fix:** editing the entry bodies violates the content-
faithfulness oracle + invents scope; broadening Check 34 to swallow these is
an architect decision (it would weaken the guard). The plan's §7 oracle item-7
asserted "Check 34 active+passing" but FLAG-b's measure-then-bound only
measured the `vN.M`-with-defined-major class — these 3 were not measured.

**Recommended dispositions (for user/architect):**
- `v12.0` (×2): treat future-major version mentions as out-of-scope for
  cross-ref validation (a `vN.M` whose major `vN` is NOT yet a release is a
  forward-reference, not a dangling entry-ref) — a small architect-sanctioned
  extension to `_resolves_to_defined_id` (tolerate `vN.M` where `vN` > the
  highest defined major). OR add a Check-34 allowlist entry per
  `ci-guard-measure-then-bound`.
- `BD-19b`: the cleanest fix is a one-word edit in BD-173.md ("Batch 19b
  research" — drop the redundant "BD-19b"), but that touches a byte-faithful
  entry body → needs explicit user approval (it is content, not scaffolding).
  Alternative: Check-34 allowlist. Surfaced, not done.

### POQ-2 — Check-40 bare-refs to the deleted monoliths in 4 files NOT in C1–C8

Post-`git rm`, bare ``` `BACKLOG.md` ``` / ``` `CHANGELOG.md` ``` references in
these pack-ops files become "broken ref" FAILs (Check 40):

| File:line | Reference | Nature |
|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md:43` | `BACKLOG.md`, `CHANGELOG.md` | C2 category list of pack-only ops files |
| `pack-ops/DRY-RUN-MIGRATION.md:199` | `BACKLOG.md` | harness-doc prose |
| `pack-ops/OPTIONAL-FEATURES.md:133,203` | `BACKLOG.md` | tracker-behavior prose ("sidecar `BACKLOG.md`") |
| `pack-ops/PACK-MEMORY-RATIONALE.md:361` | `BACKLOG.md` | prose example ("pack-ops uses BDs in `BACKLOG.md`") |

The plan's **A11 claim that the Check-40 exclusion is "moot post-deletion (the
files won't exist)" is incorrect**: it conflated the deleted *referencing
file* (correctly inert) with *references TO* the deleted monoliths in OTHER
pack-ops docs. The plan's C1–C8 enumeration covered trinity/README/PACK-AGENTS/
PACK-CHAT/HELP-FRAGMENT but missed these 4 files.

**Why I did NOT fix:** these 4 files are NOT in my scoped C1–C8 edit set;
fixing them is scope expansion. PACK-MEMORY-RATIONALE.md is additionally a
pack-chat-only / rule↔rationale-bijection surface (BD-198) — editing it has
its own propagation discipline.

**Recommended dispositions (for user/architect):** repoint each bare ref to
the tree (`/backlog/`, `/changelog/`) or qualify/allowlist per Check-40's
documented remediation (`_CHECK_40_ALLOWLIST` + one-line rationale). Most are
straightforward repoints (same pattern as C3–C6). Recommend Pack Chat scope a
follow-up coder edit covering exactly these 4 files (and re-confirm no others
via the post-delete sim). DRY-RUN-MIGRATION / OPTIONAL-FEATURES prose may be
historical — confirm per fail-loud principle 2.

---

## 6. Incomplete in-scope work (C7 — partial)

**C7 (pack-copied skill/agent prompts ×3 CLIs) is PARTIAL.** I completed
`.claude/skills/pack-startup/SKILL.md` (the clearest "regenerated mirror" model
statement + read-instructions). **~20 files remain** with monolith/mirror refs:

```
.claude|.codex|.gemini /agents/{pack-architect,pack-coder,pack-planner}
.claude|.codex|.gemini /skills/{boundary-investigation,commit-discipline,
                                 implementation-report,pack-startup}/SKILL.md
.gemini/commands/pack-startup.toml   (+ .codex/.gemini pack-startup copies)
```

Reference types in the remaining set: read-instructions
(`Read pack-ops/BACKLOG.md`), permission lists, "regenerated mirror" model
statements, example greps. **I stopped C7 mid-sweep** because the two POQs make
a clean PREFLIGHT unreachable regardless, and continuing a 20-file mechanical
sweep before the POQs are dispositioned risks re-work (the boundary-
investigation deny-list edit interacts with G-4 — see below). Pack Chat should
either (a) scope a fresh coder to finish C7 + POQ-2 together, or (b) re-prompt
me to complete C7 after POQ disposition.

**G-4 reminder (plan §9, SURFACED):** the C7 boundary-investigation pack copies
CAN be corrected pack-only, but the `project-template/skills/boundary-
investigation/SKILL.md` MASTER is PROJECT-side (denied by `pack-only` → BD-206).
Correcting the pack copies now creates the KNOWN, scheduled pack-vs-project
skill-master divergence the plan flagged. Surface to user.

---

## 7. Boundary discipline check

All my edits are pack-side (`pack-only` permits everything outside
`project-template/` + `supporting-docs/`). I touched ZERO project-side files.
Per-edit SSOT investigation:

- **Trinity rule (C1) / Key-files (C2):** pack-root trinity (CLAUDE/AGENTS/
  GEMINI.md at repo root) — pack-side SSOT. The PROJECT-side trinity copy
  (`project-template/`) is a SEPARATE artifact (`pack-project-separation`),
  corrected at BD-206 — NOT touched here. The project-side mirror model is
  LEFT INTACT in my pack-trinity rewrite (I explicitly say project mirrors
  remain until BD-206).
- **PACK-AGENTS / PACK-CHAT / README / HELP-FRAGMENT (C3–C6):** pack-only
  governance/structure surfaces — pack-side SSOT, correct home.
- **`_rules.md` / `_intro.md` (B2/B3):** authored fresh for the pack `/backlog/`
  + `/changelog/` trees. FORMAT followed the client template at
  `project-template/docs/project/backlog/_rules.md` (READ for shape, NEVER
  copied) — the pack versions carry the NO-MIRROR statement (the client
  versions carry the regenerated-mirror model; they are SEPARATE artifacts per
  `pack-project-separation-of-concerns`). No project-side SSOT was imported.
- **No pack-only→project leak and no project→pack leak introduced.** No
  pack-* agent name, `pack-ops/`, `maintenance-docs/`, or `Pack Chat`
  orchestrator reference was added to any project-side surface (I edited none).

**Boundary discipline stop:** none. No edit added a pack-only reference to a
project-side surface.

---

## 8. Plan deviations

| Deviation | Reason |
|---|---|
| Count is **211**, not the plan's projected 209 | Live-measured at conversion (per EE-P1 "never hard-code"); Commit 1 pre-normalize + 2 later entries grew it. NOT a deviation in spirit — the oracle is dynamic. |
| FLAG-b fix = `vN.M`→`vN` major-resolution + cross-stream `TD-` tolerance | The plan said "apply the measure-then-bound exclusion the plan specifies" but the plan specifies NO concrete mechanism (only R3 notes coarser granularity). I implemented the only measure-then-bound-correct mapping consistent with per-release granularity (architecture §2.3). The `TD-` tolerance makes Check 34 honor its OWN documented contract (§10.6) which the impl did not enforce. |
| C7 PARTIAL; 2 POQs unresolved | STOP-and-report per PREFLIGHT contract (see top). |
| Did NOT delete monoliths; ran NO git verbs | Per scope — Pack Chat `git rm`s + commits. |

---

## 9. Files changed inventory

### New files (untracked — full content of meta-docs below; entries are decompose output)
- `backlog/` — **214 files**: 211 `BD-NNN[b].md` entries (decompose output, byte-faithful to monolith) + `_rules.md` + `_intro.md` + `_toc.md`.
- `changelog/` — **14 files**: 11 `vN.md` entries (decompose output) + `_rules.md` + `_intro.md` + `_toc.md`.
- `maintenance-docs/v11-implementation/IMPL-BD-203-Commit2.md` — this report.

### Modified files (16)
| Path | Tasks |
|---|---|
| `scripts/validate-pack.py` | D4(a) permitted-paths; B8 known_supporting + v8_archive SKIP removal; FLAG-b `_resolves_to_defined_id` + cross-stream tolerance |
| `scripts/lib/per-entry/_lib.sh` | B8 (drop `_v8-resolved-archive.md` from support set + doc-comment) |
| `scripts/lib/per-entry/toc-regenerate.sh` | B9 (widen `entry_sort_key` for suffix) |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | B8 lockstep (fixture + C3 retire) |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | D4(b) T6d/T6e flip + tree-path cases |
| `scripts/tests/test-per-entry.sh` | B8 lockstep (1.8 flip, Group 7 rework, Group 3/8 v8-archive removal, fixture builder retire) |
| `scripts/tests/test-v11-realistic-ot.sh` | Group C rewrite (pre-conversion SKIP → post-conversion PASS) — ENCODING surface per `verify-full-ci-suite` |
| `CLAUDE.md` | C1 rule + C2 Key-files + 5 operational refs |
| `AGENTS.md` | C1 + C2 + operational refs (trinity parity) |
| `GEMINI.md` | C1 + C2 + operational refs (trinity parity, prose form) |
| `pack-ops/PACK-AGENTS.md` | C3 + D4(c) Files-rows removal |
| `pack-ops/PACK-CHAT.md` | C4 |
| `README.md` | C5 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | C6 |
| `.claude/skills/pack-startup/SKILL.md` | C7 (partial — 1 of ~21) |

NOT modified by me (pre-existing working-tree change at session start):
`maintenance-docs/v11-implementation/PLAN-BD-203.md` (present in `git status`
before my session — confirmed I made no edit to it).

### Manifest
`bash test-fixtures/build.sh --all --clean` → **empty diff** (the new trees
are not test-fixtures; my `scripts/` edits did not change tracked fixture
SHAs). No manifest staging required.

---

## 10. Verification commands + results (verbatim)

```
$ git rev-parse HEAD                                  → 4c370dac0963dfbea9f358535811a7c86aa2cfb9
$ ls backlog | grep -cE '^BD-[0-9]+[a-z]*\.md$'       → 211
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md             → 211        (count oracle MATCH)
$ ls changelog | grep -cE '^v[0-9]+\.md$'             → 11
$ grep -cE '^## v' pack-ops/CHANGELOG.md              → 11         (count oracle MATCH)

ORACLE (§7):
  content-faithfulness backlog  → checked=211 mismatches=0  GREEN
  content-faithfulness changelog→ checked=11  mismatches=0  GREEN
  status-preservation           → monolith dist == tree dist; 1 Status/file  GREEN
  TOC in-sync (Check 33)         → both _toc.md byte-identical  GREEN
  suffix adjacency               → BD-167b after BD-167; BD-169b after BD-169  GREEN

CI test battery (current working tree, monoliths present):
  test-validate-pack-checks-32-33-34.sh → EXIT 0  PASS 68 / FAIL 0   GREEN
  test-per-entry.sh                     → EXIT 0  PASS 57 / FAIL 0   GREEN
  test-validate-pack-checks-36-37-38.sh → EXIT 1  PASS 6  / FAIL 2   (both = "validate-pack exits 0 on HEAD" end-to-end; EXPECTED-RED transient — Group-1 unit incl. D4 flip PASS)
  test-v11-realistic-ot.sh (post-del sim)→ PASS 31 / FAIL 2  (C.1 + C.9 only — blocked by POQ-1; C.2–C.8,C.10 incl. Check-32′-PASS rewrite GREEN)

syntax: validate-pack.py (ast.parse) OK; all 6 edited .sh files `bash -n` OK.

validate-pack (current, monoliths present): EXIT 1; 6 FAIL
  = 2× Check 32′ (expected) + 1× Check 36 (expected transient) + 3× Check 34 (POQ-1)
validate-pack (post-git-rm sim):            EXIT 1; 9 genuine FAIL
  = 3× Check 34 (POQ-1) + 6× Check 40 (POQ-2) + 1× Check 36 transient; Check 32′ PASS
```

---

## 11. Definition-of-Done checklist

| Item | PASS/FAIL | Note |
|---|---|---|
| Trees built; every entry preserved (211==211, 11==11) | **PASS** | red line honored |
| §7 oracle GREEN (count/content/status/toc/cross-ref) | **PASS** (cross-ref: pack-internal GREEN; 3 genuine dangling = POQ-1) | content/status/count/toc all GREEN |
| `_rules.md`/`_intro.md` authored (no-mirror, audience+purpose, Unblocked, suffix, ID-rule) | **PASS** | |
| B8 + B9 carry-forwards + lockstep tests | **PASS** | |
| D4 A13-INVERSE (validator + test + PACK-AGENTS folded into C3) | **PASS** | |
| C1–C6 doc-model corrections | **PASS** | |
| C7 skill/agent copies ×3 CLIs | **FAIL (partial)** | 1 of ~21; stopped per STOP-condition |
| validate-pack GREEN except ONLY Check 32′ | **FAIL** | also Check 36 transient + 3 Check-34 (POQ-1); see top |
| No monolith deleted; no git verb run | **PASS** | Pack Chat does the `git rm` |
| Manifest regenerated | **PASS** | empty diff |
| Trinity parity (CLAUDE/AGENTS/GEMINI) | **PASS** | C1/C2 + operational refs symmetric |

---

## 12. Recommended next steps for Pack Chat

1. **Disposition POQ-1** (3 Check-34 dangling refs) with user/architect:
   `v12.0`→future-major tolerance or allowlist; `BD-19b`→entry-body one-word
   edit (needs user approval) or allowlist.
2. **Disposition POQ-2** (6 Check-40 bare-refs in 4 files): scope a coder to
   repoint/allowlist `BOUNDARY-DEFINITION.md`, `DRY-RUN-MIGRATION.md`,
   `OPTIONAL-FEATURES.md`, `PACK-MEMORY-RATIONALE.md`.
3. **Finish C7** (~20 pack-copied skill/agent files ×3 CLIs) + surface G-4
   (pack-vs-project boundary-investigation master divergence → BD-206).
4. **THEN** Pack Chat: `git rm pack-ops/BACKLOG.md pack-ops/CHANGELOG.md`
   (user-approved) → run FULL validate-pack (now GREEN incl. Check 32′ + 33 +
   34 once POQ-1/POQ-2 fixed) → commit the atomic Commit 2.
5. Sequence the **BD-203 status flip** into `/backlog/BD-203.md` (G-7) — the
   monolith it normally flips in is being deleted.

---

## 13. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (QUOTED) | Conclusion |
|---|---|---|
| **read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION** | READ-IN-FULL row below: PLAN-BD-203.md (799 lines, §2/§6/§7 read directly), ARCHITECTURE-BD-203-V3.md (413), -V3-AMENDMENT.md (244), the two named memory files, + every file I edited read before editing. CLAUDE.md `## Pack memory` read in full (system-reminder full text + Read of the rule region). No named doc derived. | COMPLIANT |
| **preflight-stop-means-stop** | I did NOT emit the clean PREFLIGHT line — POQ-1/POQ-2 made it unreachable; I reported what went wrong INSTEAD (this report, §"STOP-AND-REPORT" at top). No parent stop/halt was issued during the run. | COMPLIANT |
| **agents-never-commit (NO git verbs, esp. NO `git rm`)** | Ran only read-only git (`rev-parse`, `status`, `diff --stat`, `log`, `show`). Monoliths NOT deleted (the simulation used `mv` aside + `mv` back — verified byte-identical restore via `diff -q`; never `git rm`). No `git add`/`commit`. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Every edit was a targeted `Edit` (old_string→new_string) or a Write of a genuinely NEW file (`_rules.md`/`_intro.md`/the report). No existing file rewritten wholesale. | COMPLIANT |
| **enumerate-encoding-surfaces** | D4 moved validator (`validate-pack.py:_PACK_CHAT_ONLY_PERMITTED_PATHS`) + its test (`test-…-36-37-38.sh` T6d/T6e) TOGETHER. B8 moved `_lib.sh` + `validate-pack.py` ×2 + 3 test files (32-33-34, per-entry, +realistic-ot Group C) in lockstep. Check-32′ banner ENCODING surface (`test-v11-realistic-ot.sh` Group C) updated per `verify-full-ci-suite`. | COMPLIANT |
| **regenerate-manifest-on-v11-surface** | `bash test-fixtures/build.sh --all --clean` ran (touched `scripts/`+`pack-ops/`); diff EMPTY → nothing to stage. Evidence: `diff /tmp/manifest-before.txt test-fixtures/manifest.txt` → 0 lines. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered the trees + refs + D4. SURFACED POQ-1/POQ-2 + the C7-partial + G-4 rather than inventing fixes or silently editing byte-faithful entry bodies / out-of-scope files. | COMPLIANT |
| **fail-loud-delete-old-source (preserve-every-entry + archive-history-out)** | preserve-every-entry: 211==211 / 11==11, content-faithfulness GREEN (zero mismatches). archive-history-out: NO `_v8-resolved-archive.md` emitted (B8); the 19 v8 rows are live `BD-00N.md` entries. delete-old-source: I built the no-mirror trees + corrected refs; Pack Chat performs the gated `git rm` (I do not). | COMPLIANT |
| **verify-full-ci-suite** | Ran the FULL battery (32-33-34, per-entry, 36-37-38, realistic-ot incl. INTEGRATION) + validate-pack — not just validate-pack. Caught the realistic-ot Group-C banner ENCODING surface (the exact failure mode this rule was learned from). | COMPLIANT |
| **rules-applied-verification-block** | This table; every row QUOTED evidence (none empty); per-file READ-IN-FULL proof below. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `PLAN-BD-203.md` | YES | 799 lines; L1 "# PLAN-BD-203 …" → L799 "**End of PLAN-BD-203.md**"; §2 Phase B/C/D + §6 actor + §7 oracle read directly (2 pages). |
| `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines; L1 "# ARCHITECTURE-BD-203-V3 …" → L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 244 lines; L1 "# ARCHITECTURE-BD-203-V3-AMENDMENT …" → L244 "**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**". |
| `feedback_fail_loud_delete_old_source.md` | YES | 55 lines; L1 frontmatter "name: fail-loud-delete-old-source-on-migration" → L55 "do not invent scope." |
| `feedback_verify_full_ci_suite.md` | YES | 43 lines; L1 frontmatter "name: verify-full-ci-suite-not-just-validate-pack" → L42 cross-refs (`feedback_review_fix_cycle`, manifest-regen). |
| `CLAUDE.md ## Pack memory` | YES | Full text via system-reminder (project instructions) + Read of the rule region L465-490 before editing. |
| `scripts/validate-pack.py` (edit regions) | YES | Read L3168-3278 (Check 32′), 3409-3442 (CROSS_REF_RE/_collect), 3445-3604 (Check 34), 3735-3774 (permitted-paths), 3826-3942 (Check 36), 5040-5210 (Check 40) before editing. |
| `scripts/lib/per-entry/_lib.sh` | YES | 459 lines read in full (stream tuples + support set). |
| `scripts/lib/per-entry/decompose.sh` | YES | 311 lines read in full (anchors + walk). |
| `scripts/lib/per-entry/toc-regenerate.sh` | YES | order_groups L195-232 + entry_sort_key L237-260 read before B9. |
| `project-template/docs/project/backlog/_rules.md` + `changelog/_rules.md` + `backlog/_intro.md` | YES | read for FORMAT (never copied — separate artifacts). |
| each edited test file + trinity + PACK-AGENTS/PACK-CHAT/README/HELP-FRAGMENT | YES | each Read at the edit region before its Edit (Edit tool requires prior Read). |

**No named document was derived rather than read.** Entry counts (211 backlog
/ 11 changelog), status distribution, the 3 dangling refs, and the 6 Check-40
bare-refs were all independently measured this session at HEAD `4c370da` via
Bash/Read — not carried from the plan's stale `a630a31`/`c22d71c` numbers
(the plan's projected 209 was re-measured live to 211).

**End of IMPL-BD-203-Commit2.md**
