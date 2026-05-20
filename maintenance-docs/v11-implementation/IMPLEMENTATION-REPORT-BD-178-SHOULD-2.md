# IMPLEMENTATION-REPORT-BD-178-SHOULD-2

## 1. Summary

Corrected the broken POQ-F4-3 Tier 0 base-loading cross-reference across
all 3 `project-template/{CLAUDE,AGENTS,GEMINI}.md` trinity files
(byte-identically). The note previously pointed to
`docs/pack/INSTALL-PROCEDURES.md § "Stage S4"`, a section that does
not exist (INSTALL-PROCEDURES.md uses "Procedure N" naming; "Stage S4"
is script-internal banner string only). The corrected note points to
`scripts/init-project.sh` `stage_s4_skills()` — the actual function
that performs the skill-distribution behavior the note describes
(file + symbol; no line numbers per pack memory rule).

Branch: `v11-dev`
HEAD at start: `0cf6744a4be597f75cda345c5a5d9ce61b93bc4f`
HEAD at PREFLIGHT (working tree on top of this HEAD): unchanged
(no commits — coder does no state-changing git verbs).

## 2. Files changed

| Path | Change type | Line delta |
|---|---|---|
| `project-template/CLAUDE.md` | modified | 1 insertion, 1 deletion |
| `project-template/AGENTS.md` | modified | 1 insertion, 1 deletion |
| `project-template/GEMINI.md` | modified | 1 insertion, 1 deletion |
| `test-fixtures/manifest.txt` | modified | 3 insertions, 3 deletions (v11-* SHA rows drift) |

Total: 4 files modified, +6 / -6 lines.

No new files. No deleted files. No state-changing git verbs run.

## 3. Cross-reference choice (Option a / b / c) + rationale

**Chosen: Option (b)** — point to `scripts/init-project.sh`
`stage_s4_skills()` (file + symbol, no line numbers per pack memory
"file + symbol; never line numbers — line numbers drift").

### 3.1 INSTALL-PROCEDURES.md section structure (Option a feasibility)

Pack source-of-truth lives at
`supporting-docs/INSTALL-PROCEDURES.md` (it gets staged into
`docs/pack/INSTALL-PROCEDURES.md` in client projects). Its section
headings:

```
## Project file conventions in pack-controlled directories     (line 29)
## Procedure 5 — Custom agent and skill workflow               (line 84)
### Procedure 5.1 — Creating a custom agent                    (line 95)
### Procedure 5.2 — Creating a custom skill (standalone)       (line 141)
### Procedure 5.3 — Completing a partial registration          (line 157)
### Procedure 5.4 — Adopting an improperly-added file          (line 168)
### Procedure 5.5 — Detection scan as a phase-gate step        (line 185)
### Procedure 5.6 — Registration reference tables              (line 196)
## Procedure 5-C — Customization reconciliation after v9.3 → v10
### Procedure 5-C.0 .. 5-C.9                                   (lines 290-829)
## Procedure 5-S — Post-migration housekeeping                 (line 892)
## Procedure 7 — Kickoff auto-discovery and install-check      (line 933)
### 7.0 .. 7.7                                                 (lines 952-1253)
```

`grep -in "stage_s4_skills\|stage s4\|skill.*distrib\|skill.*install\|s4 "`
against `supporting-docs/INSTALL-PROCEDURES.md` returned zero hits.
There is NO section in INSTALL-PROCEDURES.md that describes the
skill-distribution / Stage-S4 install behavior the POQ-F4-3 note
discusses. The doc is focused on per-project workflows
(custom agent/skill registration, customization reconciliation,
post-migration housekeeping, kickoff auto-discovery) — not on
pack-install-time stage internals.

The only Tier-0 mention in INSTALL-PROCEDURES.md is tangential
(an agent-row column description referencing
`docs/pack/PLATFORM-SKILLS.md § "Tier 0 — Base skills"`),
not a skill-distribution procedure.

**Conclusion: Option (a) is not viable** — there is no
`docs/pack/INSTALL-PROCEDURES.md` section to point to.

### 3.2 Option (b) rationale

`scripts/init-project.sh` `stage_s4_skills()` exists at line 484:

```
484:stage_s4_skills() {
485:    say "── S4 — distribute skills (SKILL.md only) ──"
...
508:}
```

Plus the caller at line 1299 (`stage_s4_skills` in the orchestration
sequence). The function performs exactly the behavior the note
describes — copies each `project-template/skills/*/SKILL.md` into
all three client CLI skill directories (`.claude/skills/`,
`.codex/skills/`, `.gemini/skills/`).

This is also rhetorically consistent with the prior sentence in the
note itself, which already names the function:

> `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`

Pointing the reader to where `stage_s4_skills()` actually lives
(when they want canonical reference detail) is the natural fit.

**Conclusion: Option (b) chosen.** Accurate, actionable, file +
symbol per pack memory; preserves the two-reference structure
(implementation function + Tier-0 skill exemplar
`boundary-investigation`); no line numbers (drift-safe).

### 3.3 Option (c) considered and rejected

Removing the cross-reference entirely would leave the note still
informative but lose the canonical pointer that lets a reader
audit the install-time behavior themselves. Option (b) preserves
that auditability with an accurate target — strictly better than
deletion.

## 4. Edit applied (BEFORE / AFTER across the 3 trinity files)

The edit is byte-identical across all 3 trinity files (within-trinity
lockstep per Trinity rule).

### 4.1 BEFORE (CLAUDE.md, lines 191-196 — same prose lives at AGENTS.md 175-180 and GEMINI.md 187-192)

```
**Tier 0 installation note.** Skills at `project-template/skills/` in the
pack repo are auto-distributed to all three client CLI skill directories
(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
at install time; the Tier 0 base list is then loaded by every agent for every
project per BD-142. See `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" and the
`boundary-investigation` Tier 0 skill for the canonical reference.
```

### 4.2 AFTER (CLAUDE.md, lines 191-196 — same prose lives at AGENTS.md 175-180 and GEMINI.md 187-192)

```
**Tier 0 installation note.** Skills at `project-template/skills/` in the
pack repo are auto-distributed to all three client CLI skill directories
(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
at install time; the Tier 0 base list is then loaded by every agent for every
project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
`boundary-investigation` Tier 0 skill for the canonical reference.
```

### 4.3 Diff (single-line change, identical in all 3 files)

```
-project per BD-142. See `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" and the
+project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
```

Two-line layout preserved. Dual-reference structure preserved
(function + `boundary-investigation` Tier 0 skill). Only the broken
anchor is corrected.

## 5. Within-trinity parity verification

Both diffs below are EMPTY — confirming byte-identical POQ-F4-3 note
blocks across the 3 trinity files.

```
$ diff <(sed -n '/Tier 0 installation note/,/canonical reference\./p' \
        project-template/CLAUDE.md) \
       <(sed -n '/Tier 0 installation note/,/canonical reference\./p' \
        project-template/AGENTS.md)
(no output — EMPTY)

$ diff <(sed -n '/Tier 0 installation note/,/canonical reference\./p' \
        project-template/CLAUDE.md) \
       <(sed -n '/Tier 0 installation note/,/canonical reference\./p' \
        project-template/GEMINI.md)
(no output — EMPTY)
```

## 6. Reference-resolution verification

### 6.1 New anchor resolves

```
$ grep -n "stage_s4_skills" scripts/init-project.sh | head -5
286:        # scaffold-time skill copying. stage_s4_skills copies ALL
484:stage_s4_skills() {
1299:    stage_s4_skills
```

`stage_s4_skills()` function defined at line 484; called in the
orchestration sequence at line 1299; referenced in an internal comment
at line 286. The cross-reference resolves cleanly to a real function
in a real, current pack-repo file.

### 6.2 No broken "Stage S4" hits remain in the trinity

```
$ grep -n "Stage S4" project-template/CLAUDE.md \
                     project-template/AGENTS.md \
                     project-template/GEMINI.md
(no output — zero hits)
```

The broken cross-reference is fully removed from the trinity. (Note:
"Stage S4" appears elsewhere in the repo as `scripts/init-project.sh`'s
internal banner string "── S4 — distribute skills (SKILL.md only) ──"
and as `stage_s4_skills` in the function name itself — those are
script-internal and out of scope. The trinity-file user-facing
cross-reference is the only one corrected.)

### 6.3 Post-edit grep across trinity confirms expected state

```
$ grep -n "Tier 0 installation note\|stage_s4_skills\|INSTALL-PROCEDURES.*Stage S4" \
        project-template/CLAUDE.md \
        project-template/AGENTS.md \
        project-template/GEMINI.md
project-template/CLAUDE.md:191:**Tier 0 installation note.** ...
project-template/CLAUDE.md:193:(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
project-template/CLAUDE.md:195:project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
project-template/AGENTS.md:175:**Tier 0 installation note.** ...
project-template/AGENTS.md:177:(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
project-template/AGENTS.md:179:project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
project-template/GEMINI.md:187:**Tier 0 installation note.** ...
project-template/GEMINI.md:189:(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
project-template/GEMINI.md:191:project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the
```

No `INSTALL-PROCEDURES.*Stage S4` hits returned (expected — fully
corrected). Each trinity file has 3 stage_s4_skills mentions in
the POQ-F4-3 note block (consistent with the corrected text:
first mention in the body sentence about distribution mechanism,
second mention in the cross-reference). The non-POQ-F4-3
`INSTALL-PROCEDURES.md` references elsewhere in the trinity (e.g.,
`§ "Project file conventions"`, `Procedure 7`, `Procedure 5-C`) are
untouched — they were never in scope and they reference real sections.

## 7. Manifest regen evidence

Per RC9 (commit touches `project-template/`): `bash test-fixtures/build.sh
--all --clean` regenerated all 6 fixtures. Diff:

```
$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

$ git diff test-fixtures/manifest.txt
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index f5ab6ab..a293a6c 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  01d6611e3756f4e4e79d3b3a4f4da16ea98d2a28
-v11-flat-file  7d197f5a0a5744b3bed7f5fff9bf9c3ba32df528
-v11-tracker-on  c6c8f42c04e5f39c2c53190595ca8eb30ce87bdf
+v11-realistic-ot  1b65059394305f2704660cfc8764e8b1e34fd7c5
+v11-flat-file  8299a525af78380f6bfcd1ff62aa1445d37146f4
+v11-tracker-on  281ff6f24ca4a49554b34ac7173e84bf2d9e5d38
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Drift pattern as expected:
- **v11-* rows drift (3 fixtures):** `v11-realistic-ot`,
  `v11-flat-file`, `v11-tracker-on` — all three project-template
  trinity files changed, so v11 fixtures (which install the
  project-template) get new HEAD SHAs.
- **v10-* rows unchanged (2 fixtures):** `v10-minimal`,
  `v10-realistic-ot` — tag-pinned to pre-edit v10 surface; not
  affected by v11 trinity edits.
- **existing-project-mid-dev row unchanged (1 fixture):**
  pre-pack-install input shape; no pack files installed.

Matches RC9 expectation exactly.

## 8. validate-pack.py + 3 persona contract results

### 8.1 validate-pack.py

```
$ python3 scripts/validate-pack.py 2>&1 | tail -10
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean
```

All 39 checks PASS. Check 18 (trinity parity) is in the
passing set — within-trinity parity preserved by the byte-identical
edit.

### 8.2 Greenfield persona contract

```
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -5
  PASS S6 docs/pack/PACK-FEEDBACK.md present
  PASS S6 docs/pack/prompts/ has 10 prompt files (>=10 expected)
  PASS S8 .gitignore installed

=== greenfield contract: 191 passed, 0 failed ===
```

### 8.3 Mid-dev persona contract

```
$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -5
  PASS scripts/ created
  PASS docs/pack/ created
  PASS no spurious .pack-template sidecars

=== mid-dev contract: 25 passed, 0 failed ===
```

### 8.4 Migration persona contract

```
$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -5
  PASS v11 artifact docs/project/changelog/_changelog/_format.md installed by migrator
  PASS all .github/ISSUE_TEMPLATE/*.yml installed by migrator

=== migration contract: 37 passed, 0 failed ===
```

All 3 persona contracts STILL GREEN. Combined: 191 + 25 + 37 = 253
contract assertions, 0 failed.

## 9. Verification command output

### 9.1 Pre-edit context

```
$ git rev-parse HEAD
0cf6744a4be597f75cda345c5a5d9ce61b93bc4f

$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.
nothing to commit, working tree clean
```

```
$ grep -n "Tier 0\|stage_s4_skills\|INSTALL-PROCEDURES\|Stage S4" \
    project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md | head -20
project-template/AGENTS.md:167:Skills load through three orthogonal mechanisms: Tier 0 base skills
project-template/AGENTS.md:172:the Tier 0 base list, the sparse intersection table, and the
project-template/AGENTS.md:175:**Tier 0 installation note.** Skills at `project-template/skills/` in the
project-template/AGENTS.md:177:(`.claude/skills/`, `.codex/skills/`, `.gemini/skills/`) via `stage_s4_skills()`
project-template/AGENTS.md:178:at install time; the Tier 0 base list is then loaded by every agent for every
project-template/AGENTS.md:179:project per BD-142. See `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" and the
project-template/AGENTS.md:180:`boundary-investigation` Tier 0 skill for the canonical reference.
... (analogous lines for CLAUDE.md and GEMINI.md)
```

Confirmed: all 3 trinity files have byte-identical POQ-F4-3 note
text with the broken `Stage S4` reference (pre-edit baseline matches
BD-178 commit `3dbfbdb`).

### 9.2 stage_s4_skills() exists in script

```
$ grep -n "stage_s4_skills" scripts/init-project.sh | head -5
286:        # scaffold-time skill copying. stage_s4_skills copies ALL
484:stage_s4_skills() {
1299:    stage_s4_skills
```

### 9.3 INSTALL-PROCEDURES.md section structure

See §3.1 above — full section listing with confirmation that no
"Stage S4" or "skill-distribution" procedure exists.

### 9.4 Final working-tree scope

```
$ git status --short
 M project-template/AGENTS.md
 M project-template/CLAUDE.md
 M project-template/GEMINI.md
 M test-fixtures/manifest.txt

$ git diff --stat
 project-template/AGENTS.md | 2 +-
 project-template/CLAUDE.md | 2 +-
 project-template/GEMINI.md | 2 +-
 test-fixtures/manifest.txt | 6 +++---
 4 files changed, 6 insertions(+), 6 deletions(-)
```

Exactly 3 modified trinity files + manifest, as required. No
state-changing git verbs run.

## 10. PREFLIGHT line

```
PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD 0cf6744a4be597f75cda345c5a5d9ce61b93bc4f; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md
```

(Emitted in the parent session before this Write call. Plus this
IMPL-REPORT itself is the 5th touched file — the 4/4 count in the
preflight line covers in-scope code edits per success-criteria
checklist; IMPL-REPORT is the agent's primary output and counts
separately.)

## Appendix A — Definition-of-Done checklist

- [x] All 3 trinity files have the corrected cross-reference
      byte-identically (within-trinity parity) — §4, §5
- [x] The new reference resolves correctly — Option (b): grep
      verifies `stage_s4_skills()` exists at
      `scripts/init-project.sh:484` — §6.1
- [x] Within-trinity parity preserved: both diffs EMPTY — §5
- [x] AGENTS.md / GEMINI.md / CLAUDE.md ALL three touched
      (Option b applied lockstep) — §4, §9.4
- [x] `python3 scripts/validate-pack.py` exit 0; all 39 checks PASS
      (Check 18 trinity parity OK) — §8.1
- [x] 3 persona contracts STILL GREEN (191+25+37 = 253 assertions,
      0 failed) — §8.2, §8.3, §8.4
- [x] `test-fixtures/manifest.txt` regenerated; v11-* rows drift;
      v10-* + existing-* unchanged — §7
- [x] Working tree at PREFLIGHT: exactly 3 modified trinity files +
      manifest + IMPL-REPORT — §9.4
- [x] No state-changing git verbs run — confirmed; only `rev-parse`,
      `status`, `diff` (read-only)
- [x] PREFLIGHT line emitted before IMPL-REPORT write — §10

PASS on all items.

## Appendix B — Plan deviations

Zero deviations. Prompt recommended Option (b) if INSTALL-PROCEDURES.md
had no skill-install/distribution procedure. §3.1 verified the
absence; §3.2 chose Option (b) per recommendation. Replacement text
preserved two-line layout and dual-reference structure.

## Appendix C — New POQs introduced

None. The edit is a single-line cross-reference correction; no new
architectural questions surfaced.

## Appendix D — Out-of-scope items confirmed untouched

- Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at repo
  root) — `git status` confirms zero modifications.
- Cross-CLI references (BD-182 scope) — only the
  `INSTALL-PROCEDURES.md § "Stage S4"` reference was changed; no
  other CLI-specific paths touched.
- Other content in the POQ-F4-3 note beyond the cross-reference —
  only the one-line `See ...` sentence edited; all surrounding
  prose byte-identical.
- INSTALL-PROCEDURES.md itself — unchanged (the broken anchor was
  in the trinity, not in INSTALL-PROCEDURES.md).
- `scripts/init-project.sh` — unchanged; function name was already
  correct.
- No new validate-pack checks; no architect-doc edits.
