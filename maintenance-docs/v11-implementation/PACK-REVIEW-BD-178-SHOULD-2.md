# PACK-REVIEW-BD-178-SHOULD-2

Per-commit review of `830d628` — BD-178 SHOULD-2: correct POQ-F4-3
Tier 0 note cross-reference (`Stage S4` → `scripts/init-project.sh`
`stage_s4_skills()`).

Reviewer: `pack-reviewer` (background spawn)
Date: 2026-05-20
Branch: `v11-dev` at HEAD `18880b4` (commit-under-review: `830d628`)
Reference docs read: `pack-ops/BACKLOG.md` BD-178 entry §POQ-F4-3 absorbed
scope; `project-template/{CLAUDE,AGENTS,GEMINI}.md` at HEAD;
`project-template/docs/pack/INSTALL-PROCEDURES.md` (verified absent;
actual pack-side file at `supporting-docs/INSTALL-PROCEDURES.md`);
`scripts/init-project.sh` (function definition + call site);
`git show 830d628` (full diff). Read order respected:
IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md read AFTER independent
assessment formed. No prior `PACK-REVIEW-*.md` reports consulted for
the SHOULD-2 review (the parent `PACK-REVIEW-BD-178.md` was incidentally
surfaced by the repo-wide "Stage S4" grep but only its presence was
noted; review findings were formed without reading it).

## §1. Verdict + summary

**APPROVE — zero blocking findings.**

The commit cleanly closes BD-178 per-commit SHOULD-2 with a minimal,
correct, in-scope edit. The broken cross-reference
`docs/pack/INSTALL-PROCEDURES.md § "Stage S4"` is replaced with
`scripts/init-project.sh` `stage_s4_skills()` byte-identically across
all 3 `project-template/` trinity files, preserving within-trinity
parity. The new reference resolves (verified
`stage_s4_skills()` defined at `scripts/init-project.sh:484`, called
at L1299). Option (b) is the correct choice — Option (a) is infeasible
(no Stage S4 section exists in INSTALL-PROCEDURES.md, which uses
"Procedure N" naming), Option (c) (deletion) would lose canonical-
reference auditability. The Option (b) form (file + symbol, no line
number) matches the pack-memory file+symbol pattern exactly. Scope
discipline is tight: exactly 5 files in commit (3 trinity + manifest
+ IMPL-REPORT), with no out-of-scope edits. Manifest regen follows
RC9 with 3 v11-* SHA updates and v10-* + existing-* unchanged.
`validate-pack.py` PASSED (all 39 checks). All 3 persona contracts
PASS (191 + 25 + 37 = 253/253). The "Stage S4" broken reference
is fully eliminated from the trinity (grep returns zero hits).

## §2. Independent findings (per-scope-area)

### §2.1 Cross-reference correction applied — byte-identical across trinity

`git show 830d628 -- project-template/{CLAUDE,AGENTS,GEMINI}.md`
confirms the same single-line replacement in all 3 files:

```
-project per BD-142. See `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" and the
+project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
```

Locations:
- `project-template/CLAUDE.md:195` (within block 191-196)
- `project-template/AGENTS.md:179` (within block 175-180)
- `project-template/GEMINI.md:191` (within block 187-192)

All three diff hunks are 1 insertion / 1 deletion exactly; no other
prose touched; surrounding 5 lines of the POQ-F4-3 note block remain
byte-identical pre- and post-edit. **PASS.**

### §2.2 New reference resolves

`grep -n "stage_s4_skills" scripts/init-project.sh` returns:
```
286:        # scaffold-time skill copying. stage_s4_skills copies ALL
484:stage_s4_skills() {
1299:    stage_s4_skills
```

Function defined at L484; called in stage orchestration at L1299;
referenced in a comment at L286. Function body (verified L484-494)
performs exactly the behavior the POQ-F4-3 note describes — copies
each `project-template/skills/*/SKILL.md` into all three client CLI
skill directories. The cross-reference is accurate.

`grep -n "Stage S4\|stage_s4\|^## \|^### " supporting-docs/INSTALL-PROCEDURES.md`
confirms INSTALL-PROCEDURES.md uses "Procedure N" naming and has
zero "Stage S4" references (independently corroborates Option (a)
rejection). The doc has Procedure 5, Procedure 5-C, Procedure 5-S,
Procedure 7 sub-procedures — none addresses pack-install-time
stage internals (which are scripts/init-project.sh's domain). **PASS.**

### §2.3 Within-trinity parity preserved

```
$ diff <(sed -n '191,196p' project-template/CLAUDE.md) \
       <(sed -n '175,180p' project-template/AGENTS.md)
(empty)

$ diff <(sed -n '191,196p' project-template/CLAUDE.md) \
       <(sed -n '187,192p' project-template/GEMINI.md)
(empty)
```

Both diffs EMPTY — the POQ-F4-3 note block is byte-identical across
the 3 trinity files, exactly as the Trinity rule requires for the
non-tool-specific informational text. **PASS.**

### §2.4 Scope discipline — exactly 5 files; no out-of-scope edits

`git show 830d628 --name-status`:
```
A  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md
M  project-template/AGENTS.md
M  project-template/CLAUDE.md
M  project-template/GEMINI.md
M  test-fixtures/manifest.txt
```

5 files exactly. Independently verified out-of-scope items are NOT
in the commit name-list:
- Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at repo root): NOT touched.
- `supporting-docs/INSTALL-PROCEDURES.md`: NOT touched.
- `scripts/init-project.sh`: NOT touched.
- `scripts/` (any file): NOT touched (the only `scripts/`-style reference is the trinity prose).
- `pack-ops/` (any file): NOT touched.
- `scripts/validate-pack.py`: NOT touched.
- Any architect-doc / planner-doc / archived report: NOT touched.

**PASS.**

### §2.5 Manifest regen — 3 v11-* SHA updates; v10-* + existing-* unchanged

`git show 830d628 -- test-fixtures/manifest.txt` shows the expected
RC9 drift pattern:
```
-v11-realistic-ot  01d6611e3756f4e4e79d3b3a4f4da16ea98d2a28
-v11-flat-file  7d197f5a0a5744b3bed7f5fff9bf9c3ba32df528
-v11-tracker-on  c6c8f42c04e5f39c2c53190595ca8eb30ce87bdf
+v11-realistic-ot  1b65059394305f2704660cfc8764e8b1e34fd7c5
+v11-flat-file  8299a525af78380f6bfcd1ff62aa1445d37146f4
+v11-tracker-on  281ff6f24ca4a49554b34ac7173e84bf2d9e5d38
```

- `v11-realistic-ot`: drifted (correct — project-template trinity changed)
- `v11-flat-file`: drifted (correct)
- `v11-tracker-on`: drifted (correct)
- `v10-minimal`: unchanged (correct — tag-pinned)
- `v10-realistic-ot`: unchanged (correct — tag-pinned)
- `existing-project-mid-dev`: unchanged (correct — pre-install shape)

Committed manifest matches working-tree HEAD (`git show 830d628:test-fixtures/manifest.txt | diff -` was EMPTY). **PASS.**

### §2.6 validate-pack.py + 3 persona contracts STILL GREEN

Independently re-ran both gates against HEAD `18880b4` (current HEAD
is post-`830d628`):

`python3 scripts/validate-pack.py 2>&1 | tail -3`:
```
============================================================
PASSED — all checks clean
```

All 39 checks PASS including Check 18 (trinity H2 structure parity)
and Check 11 (pack agent trinity-rule symmetry — informational).

`bash scripts/test-persona-contracts.sh 2>&1 | grep "=== "`:
```
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
Persona contract summary: 3/3 passed
```

253/253 contract assertions PASS, matching IMPL-REPORT claim. **PASS.**

### §2.7 No "Stage S4" hits remain in trinity

```
$ grep "Stage S4" project-template/CLAUDE.md \
                  project-template/AGENTS.md \
                  project-template/GEMINI.md
(no output)
```

Zero hits. Broken reference fully eliminated from the user-facing
trinity surface. **PASS.**

A repo-wide `grep` confirms remaining "Stage S4" occurrences are all
legitimate script-internal terminology in expected, out-of-scope locations:
- `supporting-docs/MIGRATION-v10-to-v11.md:387` — documenting the migrator's S4 sub-banner topology (script-internal context)
- `scripts/tests/test-migrate-v10-to-v11.sh:374` — test-code comment about fail_stage exit code
- `maintenance-docs/archive/v10-working/` and `maintenance-docs/archive/v11/` — archived historical docs (correctly untouched)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F2A.md:241` — historical IMPL-REPORT prose
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md` + `IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md` — meta-discussion of the fix itself (correct)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md:156` — pre-fix baseline citation (correct context)

None of these are user-facing client-installed prose; all are
script-internal, test, archive, or meta-discussion contexts.

### §2.8 Option (b) choice — matches pack memory file+symbol pattern

Pack memory rule (cited in commit message): "no line numbers —
line numbers drift." The Option (b) form `scripts/init-project.sh`
`stage_s4_skills()` is exactly file + symbol with no line number.
Two backticked code spans (file path + function name) preserve the
pattern. The new reference is rhetorically consistent with the
prior sentence in the SAME note block, which already names the
function (`via stage_s4_skills()` at install time) — the
correction now closes the loop by saying "for the canonical
reference, see where this function is defined."

Option (a) rejection is well-grounded: independently verified that
INSTALL-PROCEDURES.md has no "Stage S4" section (the section listing
in IMPL-REPORT §3.1 is accurate and matches my own grep). Option (c)
(deletion) would lose the canonical pointer that lets a reader audit
the install-time behavior — keeping the reference is strictly better
than dropping it. **PASS.**

## §3. Compare-to-IMPL-REPORT

After forming independent findings, I read
`IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md` in full. Findings align:

- **Files-changed count (§2):** IMPL-REPORT claims 4 modified +
  1 NEW (IMPL-REPORT itself) = 5 total. Matches my `git show
  --name-status` independently.
- **Option (b) rationale (§3.2):** IMPL-REPORT verifies
  `stage_s4_skills` at L484 and L1299 — matches my grep.
- **Edit byte-identicality (§5):** IMPL-REPORT verifies both
  CLAUDE↔AGENTS and CLAUDE↔GEMINI diffs of the POQ-F4-3 note block
  are EMPTY — matches my own diff runs.
- **Manifest drift pattern (§7):** IMPL-REPORT shows the exact SHA
  delta I verified against `git show 830d628 --`.
- **validate-pack.py (§8.1):** IMPL-REPORT claims "PASSED — all
  checks clean" — matches my re-run.
- **Persona contracts (§8.2/8.3/8.4):** IMPL-REPORT claims
  191/0 + 25/0 + 37/0 = 253/253 — matches my re-run exactly.
- **Definition-of-Done checklist (Appendix A):** all 10 items
  pass; my independent verification confirms each item.
- **Out-of-scope items (Appendix D):** IMPL-REPORT enumerates
  pack-root trinity, BD-182 cross-CLI work, INSTALL-PROCEDURES.md,
  init-project.sh, validate-pack checks, architect-docs as
  untouched — all confirmed via `git show --name-status`.

No discrepancies between IMPL-REPORT and independent assessment.

## §4. Severity-classified findings

| # | Severity | Finding | Recommendation |
|---|----------|---------|----------------|
| (no findings) | — | Zero blockers, MUSTs, SHOULDs, or NITs surfaced. | APPROVE the commit as-is. |

## §5. Verification commands run + output

### §5.1 Commit identity
```
$ git rev-parse HEAD
18880b4a584692a1d6ddea222559d0021748b49b

$ git show 830d628 --stat
... 5 files changed, 464 insertions(+), 6 deletions(-)
```

### §5.2 Cross-reference correction
```
$ grep "Stage S4" project-template/CLAUDE.md \
                  project-template/AGENTS.md \
                  project-template/GEMINI.md
(no output — zero hits — PASS)
```

### §5.3 Within-trinity parity
```
$ diff <(sed -n '191,196p' project-template/CLAUDE.md) \
       <(sed -n '175,180p' project-template/AGENTS.md)
(empty)

$ diff <(sed -n '191,196p' project-template/CLAUDE.md) \
       <(sed -n '187,192p' project-template/GEMINI.md)
(empty)
```

### §5.4 Reference resolution
```
$ grep -n "stage_s4_skills" scripts/init-project.sh
286:        # scaffold-time skill copying. stage_s4_skills copies ALL
484:stage_s4_skills() {
1299:    stage_s4_skills
```

### §5.5 INSTALL-PROCEDURES.md absence verification
```
$ grep -n "Stage S4\|stage_s4\|^## \|^### " supporting-docs/INSTALL-PROCEDURES.md | head -10
29:## Project file conventions in pack-controlled directories
84:## Procedure 5 — Custom agent and skill workflow
95:### Procedure 5.1 — Creating a custom agent
141:### Procedure 5.2 — Creating a custom skill (standalone)
... (no "Stage S4" or "stage_s4" hits — confirms Option (a) infeasible)
```

### §5.6 Manifest committed = HEAD
```
$ git show 830d628:test-fixtures/manifest.txt | diff - test-fixtures/manifest.txt
(empty — committed manifest matches HEAD)
```

### §5.7 validate-pack.py
```
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```

### §5.8 Persona contracts
```
$ bash scripts/test-persona-contracts.sh 2>&1 | grep "=== "
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
Persona contract summary: 3/3 passed
```

### §5.9 Out-of-scope verification (pack-root trinity)
```
$ grep -n "Stage S4\|INSTALL-PROCEDURES.md.*Stage S4" CLAUDE.md AGENTS.md GEMINI.md
(no output — pack-root trinity untouched + has no stale Stage S4 refs)
```

### §5.10 Duplicate-note guard
```
$ grep -c "Tier 0 installation note" project-template/{CLAUDE,AGENTS,GEMINI}.md
project-template/CLAUDE.md:1
project-template/AGENTS.md:1
project-template/GEMINI.md:1
```

Exactly 1 occurrence per file — no accidental duplication.

## §6. Out-of-scope observations

These are NOT findings against this commit. They are tangential
observations that may inform unrelated work; none should block this
approval.

1. **The pack-side INSTALL-PROCEDURES.md lives at `supporting-docs/`,
   not at `project-template/docs/pack/`.** The trinity prose uses
   client-installed path `docs/pack/INSTALL-PROCEDURES.md` (which
   appears in `test-fixtures/v11-*/docs/pack/INSTALL-PROCEDURES.md`
   after install). The new cross-reference `scripts/init-project.sh`
   `stage_s4_skills()` uses a PACK-REPO path that is also visible to
   client-installed projects (init-project.sh is staged into the
   project per S0/S5). A reader running on a client install will
   find `scripts/init-project.sh` in their project (because
   init-project.sh is one of the files staged to clients). This is
   fine for the SHOULD-2 fix — but note the asymmetry: the trinity
   prose has historically referenced *client-installed* paths
   (`docs/pack/...`) while this correction references a path that
   exists in both pack-repo and client-installed surfaces. Not an
   issue for this commit; flag here only in case future trinity
   cross-references want a consistent convention. No action needed.

2. **`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md:156`
   still contains the pre-fix prose** (cited as historical baseline:
   `project per BD-142. See \`docs/pack/INSTALL-PROCEDURES.md\` § "Stage S4"`).
   This is correct — IMPL-REPORTs document the pre-edit state and
   should not be retroactively rewritten. No action needed.

3. **BD-178 BACKLOG status remains "Open"** — expected, since the
   per-BD review/fix cycle for BD-178 has multiple SHOULDs in flight
   (BD-178 SHOULD-1 closed in `fa605a9`; this SHOULD-2 closes in
   `830d628`). The "implicit BD status flip on batch completion"
   rule applies after all per-BD cycles complete, not after each
   sub-fix. No action needed for this commit.

4. **`PACK-REVIEW-BD-178.md` was incidentally surfaced by my repo-wide
   `grep "Stage S4"` for §2.7 verification.** Per prompt direction, I
   did not read prior `PACK-REVIEW-*.md` files for the SHOULD-2
   review. Only the file's existence was noted; its findings did not
   inform my independent assessment. The SHOULD-2 work described in
   the commit message and IMPL-REPORT is self-contained and complete
   on its own merits.

## §7. Reviewer notes for Pack Chat

- This commit is APPROVE-AS-IS. No fix-coder spawn needed.
- The pre-existing `PACK-REVIEW-BD-178.md` SHOULD-2 finding is now
  closed by this commit.
- BD-178 BACKLOG status flip to Resolved is gated on completion of
  ALL outstanding BD-178 per-commit findings (across SHOULDs and
  any open NITs) per the per-BD review/fix pattern.
- All RC9 / Trinity / file+symbol / scope-discipline rules respected.
- Triage suggestion: zero findings → no FIX-vs-DEFER triage needed;
  surface APPROVE verdict to user with a one-line summary.
