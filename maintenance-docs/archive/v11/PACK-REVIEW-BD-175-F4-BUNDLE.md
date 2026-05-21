# PACK-REVIEW-BD-175-F4-BUNDLE

**Reviewer:** pack-reviewer (background instance)
**HEAD reviewed:** `8f6ce51bf1e864062f00d2e3a85769f5e12732dd`
**Branch:** `v11-dev`
**Commit message:** `fix: v11 — BD-175 consolidate boundary-investigation skill to Pattern A + cascade allowlist/PLATFORM-SKILLS updates (F4 bundle)`
**Scope reviewed:** F4 mechanical (Pattern B → Pattern A consolidation of `boundary-investigation` skill) + POQ-F4-1 (validate-pack.py allowlist) + POQ-F4-2 (PLATFORM-SKILLS.md Tier 0 entry + count updates) + manifest regen + IMPL-REPORT supersession.

---

## §1 Verdict

**GO — with 2 SHOULDs + 2 NITs.**

The F4 bundle correctly executes its central CI-recovery mission. All three persona contracts PASS independently (greenfield 191/0, mid-dev 25/0, migration 37/0); `python3 scripts/validate-pack.py` exits 0 with all 36 check-sections reporting OK; `bash test-fixtures/build.sh --verify` reports all 6 fixtures match the regenerated manifest. The Pattern A relocation is byte-perfect (SHA-256 `618ebb21…` matches across the new `project-template/skills/boundary-investigation/SKILL.md` and the pre-commit Pattern B sources), the new file lives at the exact path that `stage_s4_skills()` (`scripts/init-project.sh:484-507`) iterates, the pack-side trinity at pack root is genuinely untouched, scope discipline is clean (no trinity edits, no `PACK-AGENTS.md` edits, no new validate-pack checks), and POQ-F4-3 was correctly held out per user direction. The SHOULDs concern (a) the architect-doc reconciliation chain that pack memory requires when shipped reality diverges from a prior architect-doc design, and (b) the BD-178 anchor still lacking POQ-F4-3 absorption. The NITs concern (a) the "all 38 checks PASS" wording in both commit message and IMPL-REPORT (the actual count of printed check-sections is 36; the highest numeric ID is 38), and (b) a stale prose phrase in the IMPL-REPORT §6.

---

## §2 Independent findings (per-scope-area)

### 2.1 F4 mechanical — Pattern B → Pattern A move

**PASS.** `git show 8f6ce51 --name-status` shows exactly the expected 7 lines:

```text
A   maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md
D   project-template/.codex/skills/boundary-investigation/SKILL.md
D   project-template/.gemini/skills/boundary-investigation/SKILL.md
M   project-template/docs/pack/PLATFORM-SKILLS.md
R100  project-template/.claude/skills/boundary-investigation/SKILL.md  project-template/skills/boundary-investigation/SKILL.md
M   scripts/validate-pack.py
M   test-fixtures/manifest.txt
```

Git's rename detector identifies the `.claude/skills/` Pattern B file as a 100% rename into the new Pattern A path (R100 line), confirming byte-identity through git's own similarity index. The other two Pattern B paths (`.codex/skills/` and `.gemini/skills/`) appear as pure deletions, which is correct: only one of the three byte-identical Pattern B copies can satisfy the rename heuristic, the other two collapse to deletions.

Independent SHA-256 verification (run against pre-commit and post-commit objects):

```text
project-template/.codex/skills/boundary-investigation/SKILL.md  (pre-commit):  618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686
project-template/.gemini/skills/boundary-investigation/SKILL.md (pre-commit):  618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686
project-template/skills/boundary-investigation/SKILL.md         (post-commit): 618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686
```

All three hashes match: the new Pattern A file is byte-identical to both deleted Pattern B sources. Pack-side files at pack root (`.claude/skills/boundary-investigation/SKILL.md`, etc.) share the same SHA — see §2.3.

`project-template/.gemini/skills/` grandparent was removed (confirmed via `find project-template -path '*.gemini/skills*'` returning empty). `project-template/.claude/skills/` and `project-template/.codex/skills/` parents remain (correctly — they host `pack-help` and `pm-startup`, the genuinely-per-CLI Pattern B skills).

### 2.2 Pattern A correctness — `stage_s4_skills()` cross-check

**PASS.** Read `scripts/init-project.sh:484-507` directly:

```bash
stage_s4_skills() {
    say "── S4 — distribute skills (SKILL.md only) ──"
    local skill_dir name tool
    for skill_dir in "$PACK/project-template/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        name=$(basename "$skill_dir")
        for tool in claude codex gemini; do
            mkdir -p "$TARGET/.${tool}/skills/$name"
            cp "$skill_dir/SKILL.md" "$TARGET/.${tool}/skills/$name/SKILL.md"
        done
    done
    ...
}
```

The loop iterates `$PACK/project-template/skills/*/`, which is exactly where the new file lives. `boundary-investigation/SKILL.md` will now auto-distribute to `<target>/.claude/skills/boundary-investigation/SKILL.md`, `<target>/.codex/...`, and `<target>/.gemini/...` during S4. This is the convention used by 30+ existing skills (`api-design`, `architecture-review`, `debugging`, `python-best-practices`, `swift-best-practices`, etc.), and the verification loop at lines 496-507 will confirm all three destination copies exist after install. No edits to `init-project.sh` were needed because Pattern A already works for any skill at `project-template/skills/<name>/`.

### 2.3 Pack-side untouched

**PASS.** The pack-root skill files are present and byte-identical to the new project-template file:

```text
/.../.claude/skills/boundary-investigation/SKILL.md           618ebb21…  (last touched 2026-05-19 15:44; commit f5b3998)
/.../.codex/skills/boundary-investigation/SKILL.md            618ebb21…  (last touched 2026-05-19 15:45; commit f5b3998)
/.../.gemini/skills/boundary-investigation/SKILL.md           618ebb21…  (last touched 2026-05-19 15:45; commit f5b3998)
/.../project-template/skills/boundary-investigation/SKILL.md  618ebb21…  (NEW in commit 8f6ce51)
```

`git log --oneline 8f6ce51 -- .claude/skills/boundary-investigation/ .codex/skills/boundary-investigation/ .gemini/skills/boundary-investigation/` shows the most recent commit touching these paths is `f5b3998` (Commit 12). Commit `8f6ce51` did not modify them. This satisfies the prompt's requirement that the pack-side skill remain unchanged — pack-repo agents continue to load these per `pack-ops/PACK-AGENTS.md:36`.

### 2.4 POQ-F4-1 — validate-pack.py allowlist

**PASS.** `git show 8f6ce51 -- scripts/validate-pack.py` shows exactly the expected substitutions:

- `_is_legitimate_deny_list_doc()` allowlist: 3 Pattern B path strings removed, 1 Pattern A string added (`"project-template/skills/boundary-investigation/SKILL.md"`).
- Allowlist comment updated from "Boundary-investigation skill files (project-side)." to a 3-line block naming the Pattern A canonical-single-source design and the `stage_s4_skills()` auto-distribution mechanism.
- `_iter_project_side_files()` walker comment updated: the old phrase "all `.claude/.codex/.gemini` files under `project-template/` are scanned" replaced with "all `project-template/` files are scanned (including `.claude/.codex/.gemini` extras)" — accurately reflects the new reality where the canonical skill source lives outside the dotted-CLI directories.
- `check_project_side_deny_list()` docstring "Specific exemptions" bullet rewritten from "The `boundary-investigation` skill files (3 CLI variants under …)" to "The `boundary-investigation` skill (Pattern A canonical single source at `project-template/skills/boundary-investigation/SKILL.md`, auto-distributed…)".

Grep verification (`grep -n "boundary-investigation" scripts/validate-pack.py`) returns 7 hits, all naming the Pattern A path; zero hits for any Pattern B path. No nearby "3 paths" or "Pattern B" comments left stale.

Functional result: independent run of `python3 scripts/validate-pack.py` reports Check 37 as `OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted).` The previously-cascading 28 FAIL lines (one per deny-list pattern occurrence in the relocated file) are all resolved.

### 2.5 POQ-F4-2 — PLATFORM-SKILLS.md Tier 0 entry + counts

**PASS.** `git show 8f6ce51 -- project-template/docs/pack/PLATFORM-SKILLS.md` shows 4 edit sites, exactly matching the IMPL-REPORT §5:

1. Step 1 "Tier 0 — Base skills" table (L195): new row inserted alphabetically between `architecture-review` and `debugging`. Description: "Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action."
2. Step 1 callout (L208): `**13 Tier 0 base skills.**` → `**14 Tier 0 base skills.**`.
3. Full skill inventory subsection header (L419): `### Tier 0 base skills (13)` → `### Tier 0 base skills (14)`.
4. Full skill inventory row (L429): new row inserted alphabetically between `architecture-review` and `debugging`. Same one-line description as Step 1; "Primary agents" column: `architect, coder, planner, reviewer, docs-researcher`.
5. Total (L498): `**Total skills: 35** (13 Tier 0 base + …)` → `**Total skills: 36** (14 Tier 0 base + …)`.

Independent grep `grep -n "35\|36" project-template/docs/pack/PLATFORM-SKILLS.md` returns only the legitimate `36` references at L498 + the unchanged `35` at L597 (pre-existing v11.0 BD reference inside a paragraph about deferral cost — not a skill-count). No stale "35" anywhere referring to skill counts.

Alphabetical placement is correct (`api-design`, `architecture-review`, **`boundary-investigation`**, `debugging`, `dependency-intake`, …).

Description style matches surrounding entries: a single concise sentence, parallel structure ("Universal X methodology; …" / "Project-side X methodology; …"), no overlong monograph. The "Primary agents" column matches the project-side analog of the pack-side 5-agent universal-loading pattern (per `pack-ops/PACK-AGENTS.md:36`).

Independent functional check via Check 31:

```text
OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 14 rows (header matches)
OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
OK: PLATFORM-SKILLS.md — total skills: 36 (header sum, inventory row count, and disk count all agree)
OK: Skill-cell consistency: 36 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

14 + 20 + 1 + 1 = 36 — header sum, inventory row count, and disk count all agree.

### 2.6 Manifest regen

**PASS.** `git show 8f6ce51 -- test-fixtures/manifest.txt` shows the expected shape: 3 v11-* SHAs updated (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`), 2 v10-* SHAs unchanged (`v10-minimal`, `v10-realistic-ot`), 1 existing-* SHA unchanged (`existing-project-mid-dev`).

Independent `bash test-fixtures/build.sh --verify` returns 6 `OK` lines, all matching the committed manifest:

```text
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot OK: 50940281c243f28c8ff755f5fd2361c5c63340b8
v11-flat-file OK: 8a6a2d05bf285f178335c9f13b0636a2c1e10b98
v11-tracker-on OK: 11bc0a3ac70b3fe8cdd64d353f3381e0ad4e953d
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

This satisfies RC9 (v11-surface = files under `project-template/` or `scripts/`; both were modified in this commit; manifest must regenerate; CI `fixture manifest verify` will pass).

### 2.7 Scope discipline

**PASS.** `git show 8f6ce51 --name-only` returns exactly 7 files (4 in-scope file ops + 1 PLATFORM-SKILLS + 1 manifest + 1 IMPL-REPORT — the F4-only intermediate IMPL-REPORT deletion brings the total file-operation count to 8 but `--name-only` reports 7 unique path entries because the rename is one line):

```text
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md  (NEW)
project-template/.codex/skills/boundary-investigation/SKILL.md                 (DELETED)
project-template/.gemini/skills/boundary-investigation/SKILL.md                (DELETED)
project-template/docs/pack/PLATFORM-SKILLS.md                                  (MODIFIED)
project-template/skills/boundary-investigation/SKILL.md                        (NEW — via R100 rename from .claude/skills/...)
scripts/validate-pack.py                                                        (MODIFIED)
test-fixtures/manifest.txt                                                      (MODIFIED)
```

Grep for trinity / PACK-AGENTS edits returns `NO trinity edits`. No edits to:

- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at pack root
- `project-template/CLAUDE.md` / `project-template/AGENTS.md` / `project-template/GEMINI.md`
- `pack-ops/PACK-AGENTS.md`
- Pack-side `.claude/skills/boundary-investigation/`, `.codex/skills/`, `.gemini/skills/` at pack root

POQ-F4-3 (editorial trinity note about Tier 0 base loading) is NOT in this commit — correct per user direction (deferred to BD-178). No new validate-pack checks added — POQ-F4-1 is an allowlist content edit + comment/docstring update only.

The `IMPLEMENTATION-REPORT-BD-175-F4.md` deletion (superseded by the bundle IMPL-REPORT) is a doc-cleanup operation, not scope creep — it removes an intermediate-state report that was never tied to a committed git state. The deletion is correctly noted in the IMPL-REPORT §2 and §14.

### 2.8 Verification claim cross-check

**PASS (with one NIT).** Independent runs confirm the coder's claims:

| Verification | Coder claim | Independent run | Match? |
|---|---|---|---|
| `python3 scripts/validate-pack.py` exit code | 0 | 0 | YES |
| `python3 scripts/validate-pack.py` "all checks PASS" | YES, "all 38 checks PASS" | YES, but the actual count of `── Check` section headers printed is 36 | YES on the PASS claim; NIT on the count of 38 |
| `bash scripts/persona-contracts/contract-greenfield.sh` | 191/0 PASS | `=== greenfield contract: 191 passed, 0 failed ===` (exit 0) | YES |
| `bash scripts/persona-contracts/contract-mid-dev.sh` | 25/0 PASS | `=== mid-dev contract: 25 passed, 0 failed ===` (exit 0) | YES |
| `bash scripts/persona-contracts/contract-migration.sh` | 37/0 PASS | `=== migration contract: 37 passed, 0 failed ===` (exit 0) | YES |

The "all 38 checks PASS" wording in the commit message and IMPL-REPORT §7 is a NIT: the printed section count is 36 (`python3 scripts/validate-pack.py 2>&1 | grep -cE "^── Check"` returns 36). The highest numeric ID is "Check 38" (Checks 12-15 do not exist; 3 unnumbered checks bring the total to 36 sections). The PASS state is fully correct; only the count phrasing is imprecise. See §4 NIT 1.

### 2.9 POQ-F4-3 NOT included

**PASS.** Independent grep across the trinity files for any new "Tier 0" / "base loading" wording in this commit returns no results (no trinity files modified). The commit message explicitly states POQ-F4-3 is deferred to BD-178. This matches user direction. No scope creep.

### 2.10 Architect-doc-vs-reality reconciliation

**SHOULD-finding.** Per pack memory rule "Architect-doc-vs-reality reconciliation" (pack-root CLAUDE.md `## Pack memory` → `### Repo conventions`):

> When a BD realizes a design anticipated in an architect doc, ship the reconciliation chain: (a) in-code docstring naming the realized consumer (file + symbol; never line numbers — line numbers drift), (b) architect-doc addendum cross-referencing the realized consumer, (c) IMPL-REPORT cross-reference linking both.

The F4 bundle is the inverse case: the prior architect doc design (`maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6 line 329 + L434) prescribed Pattern B placement, and F4 supersedes that design with Pattern A. Grep returns:

- L329: `**New skill: `boundary-investigation`** (proposed path: `.claude/skills/boundary-investigation/SKILL.md`, with parallel `.codex/skills/` and `.gemini/skills/` versions per the existing pack-skill trinity convention).`
- L434: `**Project-side skill trinity:** The skill ALSO ships to `project-template/.claude/skills/boundary-investigation/` and `.codex/` / `.gemini/` parallels — project-side coders / reviewers / architects / planners working in client repos hit the same regression mechanism in their own workflows.`

Both lines are stale post-F4 — the project-side ship-path is now `project-template/skills/boundary-investigation/SKILL.md` Pattern A canonical. The IMPL-REPORT §15 cross-references `scripts/init-project.sh:484-507` but the architect doc itself was not amended with a §6.X / §6 addendum naming F4 as the realized-superseded-design point.

The new SKILL.md (`project-template/skills/boundary-investigation/SKILL.md`) does not carry an in-frontmatter docstring naming "this file lives at Pattern A path and is auto-distributed via `stage_s4_skills()` per `scripts/init-project.sh`" — though arguably a SKILL.md is not a code file with docstrings, so this leg is weaker for prose markdown.

The IMPL-REPORT does provide the cross-reference leg (§15 names `init-project.sh:484-507` and the pre-existing Pattern B placement in Commit 12). What's missing is leg (b): the architect-doc addendum.

Severity: SHOULD, not MUST. The architect doc is in `maintenance-docs/v11-implementation/` (work-product, not active rule surface); leaving the stale Pattern B prose unaddressed creates a future-reader confusion vector but does not regress any shipped behavior. Most cleanly addressed as a 2-3 line addendum to ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §6 inserting "**§6 addendum (F4 supersession 2026-05-19):** The Pattern B project-side placement described above was superseded by F4 bundle (commit `8f6ce51`) — the project-side skill now ships as a Pattern A canonical single source at `project-template/skills/boundary-investigation/SKILL.md`, auto-distributed via `stage_s4_skills()` in `scripts/init-project.sh:484-507`. The Pattern B layout proved incompatible with the persona-contract skill-count test because Pattern B is not iterated by S4 — see PLAN-BD-175-PHASE-5.md §2.12 and IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md §3 for the supersession context." See §4 SHOULD 1.

---

## §3 Compare-to-IMPL-REPORT

After forming the findings above, I read the IMPL-REPORT (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md`). Cross-check:

**Alignments (where IMPL-REPORT matches my independent findings):**

- §2 Files-changed inventory matches my 7-file `--name-status` reading.
- §3 Pattern A vs Pattern B background table accurately describes the convention; my read of `scripts/init-project.sh:484-507` confirms it.
- §4 Before/after snippet for the allowlist edit matches my `git show 8f6ce51 -- scripts/validate-pack.py` reading.
- §5 4-site enumeration of PLATFORM-SKILLS.md edits matches my grep + reading.
- §6 persona-contract output matches my independent runs.
- §7 `python3 scripts/validate-pack.py` PASS state matches my independent run.
- §8 manifest diff matches my independent `bash test-fixtures/build.sh --verify` output (the v11-* SHAs match exactly).
- §9 verification commands (`git status`, `ls`, `grep`) match my read of the post-commit state.
- §11 Definition-of-Done table is honest — every claimed PASS is confirmed independently.
- §13 "Zero new POQs introduced" is correct — no new deferred items beyond the pre-surfaced POQ-F4-3 (deferred to BD-178 per user direction).
- §14 explicit "Files NOT modified" enumeration matches my scope-discipline finding.
- §15 cross-references include the load-bearing `scripts/init-project.sh:484-507` link.

**Divergences:**

- §7 "All 38 checks pass" — my independent count of `── Check` section headers is 36. This is identical to the commit message wording and is a NIT (the PASS state is fully correct; only the count phrasing is imprecise).
- §6 IMPL-REPORT prose says "(`scripts/tests/personas/` did not exist; actual path is `scripts/persona-contracts/`)" in §12 Plan deviations. I confirmed the actual path is `scripts/persona-contracts/` — IMPL-REPORT is correct here. No defect.
- §15 cross-references do not include the `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` doc whose §6 design was superseded. This is the same surface as my SHOULD-1 finding (architect-doc reconciliation).
- The IMPL-REPORT §5 line "User-approved Tier 0 placement (boundary-investigation is loaded by all 5 pack-* agents per `pack-ops/PACK-AGENTS.md:36`…)" — the IMPL-REPORT uses a line number (`L36`). Per the pack-template trinity rule "use the symbol name not the line number", this is a minor IMPL-REPORT-only NIT — line numbers drift. But since IMPL-REPORTs are work-product not rule surface, the line-number reference is acceptable in a frozen-in-time IMPL-REPORT. NIT severity at most; arguably "no finding" because IMPL-REPORTs are by nature point-in-time snapshots.

The IMPL-REPORT is well-organized, complete, accurate, and honest about its zero-deviation scope. My independent findings agree with it on every functional point.

---

## §4 Severity-classified findings

| # | Severity | File / Surface | Finding | Suggested fix |
|---|---|---|---|---|
| S1 | SHOULD | `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6 (L329 + L434) | Pack-memory rule "Architect-doc-vs-reality reconciliation" requires an architect-doc addendum when shipped reality (F4 Pattern A) supersedes a prior architect-doc design (Architect C §6 Pattern B). Stale prose at L329/L434 still names Pattern B as the project-side ship-path. | Add a 2-3 line addendum to §6 (or insert §6.X) naming the F4 supersession, the new Pattern A path, the `stage_s4_skills()` realized consumer, and a back-pointer to commit `8f6ce51` + the bundle IMPL-REPORT. Same pattern as the BD-119 §9.2 / BD-160 reconciliation worked example cited in the pack memory rule. |
| S2 | SHOULD | `pack-ops/BACKLOG.md` BD-178 entry (L1479-1530) | The F4 bundle commit message + IMPL-REPORT name BD-178 as the anchor for POQ-F4-3 (editorial trinity note about Tier 0 base loading). BD-178 currently scopes "project-template trinity asymmetry alignment" but does not explicitly absorb POQ-F4-3 into its File/Symbol or Description. Pack memory `feedback_deferred_work_tracking.md` requires deferred work to land on a live forward-pointing surface AND be scheduled to a specific anchor — the anchor exists (BD-178) but does not yet describe the deferred work. | Add a bullet to BD-178's Description (or a sub-locus row in File/Symbol) explicitly naming POQ-F4-3: "Per F4 bundle commit `8f6ce51` deferral: add a one-line note to `project-template/{CLAUDE,AGENTS,GEMINI}.md` clarifying that Tier 0 base skills (including the new `boundary-investigation` skill) load for every project regardless of D1-D5, with per-agent filtering per PLATFORM-SKILLS.md Step 2." Pack-Chat-direct edit (BACKLOG is PM-only). |
| N1 | NIT | Commit message body (line "all 38 checks PASS") + IMPL-REPORT §7 ("All 38 checks pass") + §11 row "`python3 scripts/validate-pack.py` exit 0 — PASS — §7" | The validate-pack.py script prints 36 `── Check` section headers (numeric IDs 1-10 + 16-38 + 3 unnumbered = 36). The highest numeric ID is 38, but the printed-section count is 36. The "38" wording conflates "highest check ID" with "number of checks". Functional PASS state is fully correct. | Future commit messages and reports state "all 36 checks PASS (highest check ID is Check 38; numeric IDs 11-15 not in use)" or simply "all checks PASS". This is a cosmetic / audit-precision NIT; the commit message and IMPL-REPORT are frozen and need no edit. |
| N2 | NIT | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` §5 line 159 | "the pack-side equivalent at `pack-ops/PACK-AGENTS.md:36`" — uses a line number reference. The pack-template trinity says "use the symbol name not the line number; line numbers drift with every edit". Since IMPL-REPORT is a point-in-time work-product and the file at `pack-ops/PACK-AGENTS.md:36` is correct at the time of writing, this is borderline acceptable. | Prefer "the pack-side `boundary-investigation` skill-loading row in `pack-ops/PACK-AGENTS.md` Pack skill load table" in future IMPL-REPORTs. The current file is frozen — no edit needed. |

No BLOCKER or MUST findings. The bundle satisfies its central CI-recovery mission and is correct on every functional dimension.

---

## §5 Verification commands run + output

### 5.1 validate-pack.py (independent)

```text
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
$ echo $?
0

$ python3 scripts/validate-pack.py 2>&1 | grep -cE "^── Check"
36
```

### 5.2 Persona contracts (independent)

```text
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -2
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -2
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -2
=== migration contract: 37 passed, 0 failed ===
```

All three persona contracts PASS; all three exit 0.

### 5.3 Manifest verify

```text
$ bash test-fixtures/build.sh --verify 2>&1 | tail -6
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 50940281c243f28c8ff755f5fd2361c5c63340b8
  v11-flat-file OK: 8a6a2d05bf285f178335c9f13b0636a2c1e10b98
  v11-tracker-on OK: 11bc0a3ac70b3fe8cdd64d353f3381e0ad4e953d
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 fixtures match the committed manifest.

### 5.4 Byte-identity SHA-256

```text
$ shasum -a 256 .claude/skills/boundary-investigation/SKILL.md \
                .codex/skills/boundary-investigation/SKILL.md \
                .gemini/skills/boundary-investigation/SKILL.md \
                project-template/skills/boundary-investigation/SKILL.md
618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686  .claude/skills/boundary-investigation/SKILL.md
618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686  .codex/skills/boundary-investigation/SKILL.md
618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686  .gemini/skills/boundary-investigation/SKILL.md
618ebb21c0f0565c087bf9e08418ba2dc17248da355db692f9e9cca4eaf4e686  project-template/skills/boundary-investigation/SKILL.md
```

All 4 files share the same SHA-256 — the pack-side trinity and the new project-template canonical Pattern A source are byte-identical to each other and to the deleted Pattern B sources (per pre-commit SHA check in §2.1).

### 5.5 PLATFORM-SKILLS.md counts (independent)

```text
$ python3 scripts/validate-pack.py 2>&1 | grep -E "PLATFORM-SKILLS|skill-cell"
[extension] Skills-to-load conformance vs PLATFORM-SKILLS (BD-146)
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 14 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 36 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 36 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

14 + 20 + 1 + 1 = 36 — totals agree across the header callout, the inventory row count, and the disk count.

---

## §6 Out-of-scope observations

These are not actionable for F4 bundle (won't block GO) but are worth logging as feed-in candidates for BD-176 / BD-177 / BD-178 or post-batch:

1. **Architect-doc reconciliation pattern repeats.** The SHOULD-1 finding (architect-doc still names superseded Pattern B) is the second occurrence of this pattern in BD-175 alone (the first was the BD-119 §9.2 / BD-160 reconciliation worked example cited in pack memory). The pack memory rule already captures the pattern; no new structural work needed. But the recurrence suggests that pack-coder prompts for any BD that supersedes a prior architect-doc design could carry an explicit "If your work supersedes a prior architect-doc design, add the reconciliation addendum to the architect doc as part of this commit" reminder. Not in scope for F4 review. Feed-in candidate for whatever post-batch BD addresses pack-coder prompt boilerplate.

2. **`pack-ops/PACK-AGENTS.md:36` line-number coupling.** The IMPL-REPORT §5 names "the pack-side skill at `pack-ops/PACK-AGENTS.md:36`". If PACK-AGENTS.md is edited (e.g., the skill rows are re-ordered or a new skill is added at the top of the load table), this line number drifts. The current line at L36 happens to be the `boundary-investigation` row, but coupling to L36 is fragile. Same pattern surfaces in scripts/validate-pack.py line numbers cited throughout the prompt itself (e.g., "lines 3918-3920" — which the actual file has at L3922 after the diff). NIT-level; the pack-memory rule already exists ("use symbol name not line number"); the recurrence suggests a future post-batch BD could sweep IMPL-REPORTs for line-number references and convert them to symbol references where the surface is still mutable.

3. **F4 bundle pattern is itself worth codifying.** The "F4 mechanical → POQ-F4-1 allowlist-cascade fix → POQ-F4-2 inventory-cascade fix" structure is a clean pattern: a single mechanical change can cascade into N independent validate-pack failures via deny-list allowlists and inventory orphan-checks. The pack memory `feedback_review_fix_one_cycle.md` rule covers the within-batch review cadence but does not call out this specific "cascade-fix bundle" pattern as a recommended commit shape. The F4 bundle IMPL-REPORT (§7 "Cascade-failure resolution" prose) is a candidate exemplar. Not in scope for F4 review. Feed-in candidate for whatever post-batch BD addresses the broader release-gate "what cascades count as the same commit" question.

4. **Greenfield contract was previously RED with "36/36/35 vs expected 37/37/36".** The commit message claims this state; persona-contract test code at `scripts/persona-contracts/contract-greenfield.sh:81-130` (per IMPL-REPORT §15) holds the skill-count assertion. Independent verification post-F4 shows the contract now passes 191/0 — the count assertion is one of the 191 PASS lines. No defect; this is the central success criterion. Worth noting that the BD-175 prevention-mechanisms commit (Commit 12, `f5b3998`) shipped Pattern B without exercising the persona-contract test before tagging "implementation complete" — this is an L3 systemic gap (per BD-175's own §8 prevention framework) where a prevention mechanism (CI persona-contract pass) was bypassed by the very BD that introduced the regression. The fix (always run all 3 persona contracts before claiming PASS on any v11-surface skill-related commit) may already be captured by RC9 or another pack memory rule; if not, it is a candidate for codification.

---

**Verdict reaffirmed: GO. Recommended fixes: S1 + S2 (both SHOULD). NITs N1 + N2 are cosmetic and the commit need not be amended.**
