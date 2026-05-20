# PACK-REVIEW — BD-178

**Reviewer:** pack-reviewer (background, concurrent with BD-177 fix-pass)
**Commit reviewed:** `3dbfbdb` — fix: v11 — BD-178 align pre-existing trinity asymmetries in project-template + POQ-F4-3 Tier 0 base-loading note
**Branch:** v11-dev
**Base HEAD (pre-edit):** `3870f1c` (BD-177 commit)
**Reviewed HEAD:** `3dbfbdb`
**Date:** 2026-05-20
**Methodology:** Independent assessment first; IMPL-REPORT consulted only in §3 after independent findings formed.

---

## §1 Verdict + summary

**Verdict: APPROVE WITH SHOULDs.** The 3 known asymmetric loci converged byte-identically to the canonical wording specified in the BD-178 entry; the 2 fresh-sweep finds (Project memory intro + PLATFORM_TESTING marker) converged correctly under the General canonicalization heuristic; POQ-F4-3 Tier 0 informational note added byte-identically across all 3 trinity files; manifest regenerated per RC9 (3 v11-* SHAs drift; v10-* + existing-* unchanged); validate-pack.py exit 0 with Check 18 explicit OK; 3 persona contracts 253/253 GREEN; scope discipline clean (5 files, no pack-root trinity, no architect-doc edits, no scripts/ or pack-ops/ edits, Override 9 compliance preserved). Two SHOULDs identified:

1. **SHOULD-1 (classification accuracy):** IMPL-REPORT §5 item #4 invokes the "AGENTS-conciseness style principle" to justify NON-alignment of CLAUDE↔GEMINI body conciseness asymmetries (iOS 26, Architecture, Security, Scripts sections). The AGENTS-conciseness contract is explicitly documented in `project-template/AGENTS.md:13-17`. No analogous contract exists in `project-template/GEMINI.md` — its intro howto comment block (lines 12-13) reads "Both files should express the same project rules — only tool-specific operating notes differ" with NO conciseness carve-out. Archived maintenance-doc analysis (`maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` §D.4, lines 432-436) explicitly classifies similar GEMINI conciseness divergences as **UNRESOLVED-DRIFT**, not as authorized tool-specific exception. The IMPL-REPORT's classification is therefore inaccurate for the GEMINI side. Practical impact may be small since BD-173 (Batch 19c) will re-edit these sections, but the stated goal of BD-178 was a "fully-symmetric baseline" — partially missed.

2. **SHOULD-2 (broken cross-reference):** the POQ-F4-3 Tier 0 installation note added in all 3 trinity files reads: *"See `docs/pack/INSTALL-PROCEDURES.md` § 'Stage S4' and the `boundary-investigation` Tier 0 skill for the canonical reference."* — but no "Stage S4" section exists in any version of INSTALL-PROCEDURES.md (pack-side at `supporting-docs/INSTALL-PROCEDURES.md` or client-installed at `test-fixtures/v11-*/docs/pack/INSTALL-PROCEDURES.md`). INSTALL-PROCEDURES.md uses "Procedure N" naming, not "Stage SN" naming. The "Stage S4" terminology is script-internal (init-project.sh's `stage_s4_skills()` function at `scripts/init-project.sh:484`). Readers following the cross-reference will not find the named section.

No BLOCKERs or MUSTs. The two SHOULDs are documentation-quality issues, not scope-discipline or correctness defects.

---

## §2 Independent findings (per-scope-area assessment)

### §2.1 — Three known asymmetric loci convergence (scope item 1)

**Locus 1: "No destructive operations" bullet.** PASS — byte-identical across all 3 trinity files post-edit. Compared via `grep -nA3 "No destructive operations" project-template/*.md`:

- `project-template/CLAUDE.md:365-368`, `project-template/AGENTS.md:342-345`, `project-template/GEMINI.md:360-363` all read:
  ```
  - **No destructive operations without explicit approval.** Before
    any `git rm`, `rm -rf`, file deletion, overwrite, or
    `git reset --hard`, state exactly what will be destroyed and wait
    for explicit approval — even when the overall task is approved.
  ```
- Matches the BD-178 entry's proposed canonical wording at `pack-ops/BACKLOG.md:1499` byte-for-byte.

**Locus 2: Phase routing intro line.** PASS — byte-identical across all 3 trinity files post-edit. Compared via `grep -nA2 "## Phase routing" project-template/*.md`:

- `project-template/CLAUDE.md:396`, `project-template/AGENTS.md:373`, `project-template/GEMINI.md:391` all read:
  ```
  All three tools (Claude Code, Codex, Gemini CLI) can execute any phase.
  ```
- Matches the BD-178 entry's proposed canonical wording at `pack-ops/BACKLOG.md:1506` byte-for-byte.

**Locus 3: Trinity rule bullet.** PASS — byte-identical across all 3 trinity files post-edit. Compared via `grep -nA3 "Trinity rule" project-template/*.md`:

- `project-template/CLAUDE.md:361-364`, `project-template/AGENTS.md:338-341`, `project-template/GEMINI.md:356-359` all read:
  ```
  - **Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or
    `GEMINI.md` at the project root, the same change applies to all
    three in the same set of edits. Symmetry is the default;
    asymmetry requires justification as provably tool-specific.
  ```
- Matches the BD-178 entry's proposed canonical wording at `pack-ops/BACKLOG.md:1513` byte-for-byte.

**Conclusion: all 3 known loci converged correctly.**

### §2.2 — Within-trinity parity post-edit (scope item 2)

Ran the two diffs the prompt specified:

- `diff project-template/CLAUDE.md project-template/AGENTS.md | wc -l` → **248 lines** (matches IMPL-REPORT §8 #4)
- `diff project-template/CLAUDE.md project-template/GEMINI.md | wc -l` → **123 lines** (matches IMPL-REPORT §8 #4)

For the 3 known loci and the 2 fresh-sweep finds: ZERO drift remains — all 5 are byte-identical. This is the right outcome at the locus level.

The remaining ~248-line diff (CLAUDE↔AGENTS) and ~123-line diff (CLAUDE↔GEMINI) is composed of: (a) file identity headers and tool naming (correct intentional asymmetry), (b) AGENTS conciseness body-style (documented carve-out at `project-template/AGENTS.md:13-17`), (c) GEMINI conciseness body-style in iOS 26 / Architecture / Security / Scripts sections (UNRESOLVED — no documented carve-out — see SHOULD-1), (d) tool-specific operating notes (GEMINI Agent roster + Gemini CLI operating notes, with proper Trinity-rule-exception markers), (e) tool-specific skill paths.

### §2.3 — Fresh sweep finds verification (scope item 3)

**Fresh Sweep Find 4 (Project memory intro paragraph).** PASS — verified byte-identical across all 3 trinity files post-edit. The convergence chose the CLAUDE/AGENTS form ("regardless of agent role" + "in this project") per General canonicalization heuristic. CLAUDE-first preference applied correctly per BD-178 entry §"General canonicalization heuristic" at `pack-ops/BACKLOG.md:1516`.

**Fresh Sweep Find 5 (PLATFORM_TESTING marker).** PASS — verified byte-identical across all 3 trinity files post-edit (`[PLATFORM_TESTING — fill in from loaded skills]`). The IMPL-REPORT §5.4 reasoning is correct: CLAUDE.md was internally inconsistent with its own other `[PLATFORM_*]` markers (which all read "from loaded skills"), and AGENTS+GEMINI already had the canonical form. Aligning CLAUDE.md to AGENTS/GEMINI form rather than CLAUDE-first is correctly justified by intra-CLAUDE consistency + 2-vs-1 alignment side. Cross-checked all other PLATFORM_* / LANGUAGE_RULES markers — all are now byte-identical across trinity (`PLATFORM_DEFAULTS`, `PLATFORM_ARCHITECTURE`, `LANGUAGE_RULES`, `PLATFORM_SECURITY`, `PLATFORM_ANTIPATTERNS`, `GRPC_RULES`).

**Conclusion: both fresh-sweep finds correctly applied with sound reasoning.**

### §2.4 — POQ-F4-3 Tier 0 note (scope item 4)

**Byte-identical placement verification.** PASS — verified via `grep -nA6 "Tier 0 installation note" project-template/*.md`. All 3 trinity files have the note in the `## Skill loading` section, immediately following the existing "See `docs/pack/PLATFORM-SKILLS.md` for the authoritative D1–D5 tables..." paragraph:

- `project-template/CLAUDE.md:191-196`
- `project-template/AGENTS.md:175-180`
- `project-template/GEMINI.md:186-191`

Note text is identical 6-line block across all 3 files.

**Required content elements:**
- Auto-distribution to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` via `stage_s4_skills()` at install time — PRESENT.
- Tier 0 skills loaded by all agents by default per BD-142 — PRESENT (BD-142 cited).
- Cross-reference to `boundary-investigation` Tier 0 skill — PRESENT.

**SHOULD-2: broken cross-reference to "INSTALL-PROCEDURES.md § 'Stage S4'".** The note's cross-reference reads: *"See `docs/pack/INSTALL-PROCEDURES.md` § 'Stage S4' and the `boundary-investigation` Tier 0 skill for the canonical reference."* I verified no such section exists:

- `supporting-docs/INSTALL-PROCEDURES.md` H2 headings (via `grep -nE "^## "`): "Project file conventions...", "Procedure 5 — Custom agent and skill workflow", "Procedure 5-C — Customization reconciliation...", "Procedure 5-S — Post-migration housekeeping", "Procedure 7 — Kickoff auto-discovery..." — uses "Procedure N" naming, NOT "Stage SN" naming.
- `test-fixtures/v11-flat-file/docs/pack/INSTALL-PROCEDURES.md` (client-installed): NO "Stage S4" or `stage_s4_skills` references.
- The "Stage S4" terminology appears only in: `scripts/init-project.sh:484` (`stage_s4_skills()` function), the runtime banner string `── S4 — distribute skills (SKILL.md only) ──`, and `supporting-docs/MIGRATION-v10-to-v11.md` (in the context of "Stage S4 is split into two sub-banners — both run inside the framework's single S4 stage").

Readers following the cross-reference to find Stage S4 documentation in INSTALL-PROCEDURES.md will fail. Possible remediations: (a) point to `scripts/init-project.sh` `stage_s4_skills()` function, (b) point to MIGRATION-v10-to-v11.md (different surface), (c) add a "Stage S4" section to INSTALL-PROCEDURES.md, (d) rephrase to drop the named section reference (e.g., "See the `stage_s4_skills()` install-time function and the `boundary-investigation` Tier 0 skill for the canonical reference"). Severity: SHOULD — documentation-quality issue, not a code defect.

### §2.5 — Decline-precedence analysis check (scope item 5)

IMPL-REPORT §4 documents the decline-precedence analysis: the existing "Skill loading" paragraph covers Tier 0 *loading* semantics (the phrase "Tier 0 base skills (loaded for every project, every agent)" — present in all 3 trinity files at lines 183 / 167 / 178) but NOT *install-time auto-distribution*. The added Tier 0 installation note fills the auto-distribution gap (stage_s4_skills + physical client-CLI skill-dir distribution). The analysis is sound: PRE-EXISTING text talks about *loading* (runtime), the new note talks about *distribution* (install time). Different concerns, not duplicative.

PASS.

### §2.6 — Check 18 H2 PASS (scope item 6)

Ran `python3 scripts/validate-pack.py 2>&1`:

```
── Check 18: Trinity H2 structure parity (BD-059) ──
  OK: CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)
```

Final result: `PASSED — all checks clean` (exit 0). All 39 checks PASS.

PASS. Note: Check 18 validates H2 STRUCTURE parity only (heading names + order), NOT body content parity. This is correctly documented in the check's docstring at `scripts/validate-pack.py:1282-1294`. Body-text parity is not currently mechanically enforced — only Trinity-rule discipline + reviewer attention guard against body-text drift. This is the gap that BD-178 was opened to address manually (per BD-178 entry's rationale + per BD-181 plan to extend Check 18 H2 to pack-root trinity).

### §2.7 — Manifest regen (scope item 7)

Verified via `git show 3dbfbdb -- test-fixtures/manifest.txt`:

```
-v11-realistic-ot  e7ddf08128edc087ea827d6724965dde6ff42d20
-v11-flat-file  c7a5bc9d9815671c0ecfdaf0a8f5dbcbc7542095
-v11-tracker-on  544b8ebc24e8a701b2786b656a0d878aff1573ae
+v11-realistic-ot  ede6a325782d3c38150b72da7f804ff9ffe8dce2
+v11-flat-file  76b6baadb489f2688873b20de142da4e92752324
+v11-tracker-on  0e258e522979ff2d79c02fc58418723bb7acb75d
```

- 3 v11-* fixture SHAs updated (drift expected since project-template/ is v11-surface per RC9)
- v10-minimal, v10-realistic-ot, existing-project-mid-dev: UNCHANGED

Note on current working-tree state: BD-177's concurrent fix-pass has further drifted the v11-* manifest entries (scripts/pack-help.sh edits are also v11-surface). This is NOT a BD-178 defect — BD-178's manifest commit was correct AT THE COMMIT (`3dbfbdb`); BD-177's concurrent work has since added another v11-surface delta that will land in BD-177's commit.

PASS.

### §2.8 — Scope discipline (scope item 8)

Verified via `git show 3dbfbdb --name-only`:

```
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md
project-template/AGENTS.md
project-template/CLAUDE.md
project-template/GEMINI.md
test-fixtures/manifest.txt
```

Exactly 5 files: 3 project-template trinity + manifest + IMPL-REPORT. Confirmed:
- NO pack-root trinity edits (would be `/CLAUDE.md`, `/AGENTS.md`, `/GEMINI.md` at repo root) — none present
- NO project-template/ non-trinity edits — none present
- NO `scripts/` edits — none present
- NO `pack-ops/` edits — none present
- NO architect-doc edits — IMPL-REPORT is a new file, not an edit to existing architect docs

PASS.

### §2.9 — Override 9 compliance (scope item 9)

Override 9 (per the prompt) states that BD-178 must NOT enforce cross-trinity parity (pack-root vs project-template). BD-178 is project-template-trinity-only. Verified pack-root trinity (`/CLAUDE.md`, `/AGENTS.md`, `/GEMINI.md` at repo root) is NOT in the commit's file list. This is the correct scope per BD-181 (separate BD that addresses pack-root trinity parity enforcement via Check 18 H2 extension).

PASS.

### §2.10 — 3 persona contracts STILL GREEN (scope item 10)

Independently ran all 3 persona contracts:

```
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
```

Total: 253/253 PASS. Matches IMPL-REPORT §7 numbers.

PASS.

### §2.11 — No substantive asymmetries silently fixed (scope item 11)

IMPL-REPORT §5 claims "0 substantive asymmetries surfaced for Pack Chat escalation". I cross-checked by examining the IMPL-REPORT §5 enumeration of 10 categories classified as "tool-specific":

- Categories #1, #2, #3, #5, #6, #7, #9 are defensibly tool-specific (file identity, loading-hierarchy phrasing, skill paths, GEMINI-only Agent roster, GEMINI-only operating notes, AGENTS-specific BACKLOG write-permissions table, CLAUDE-specific `$XCODE_APP` env-block).
- Category #4 (AGENTS-conciseness style) is defensibly tool-specific FOR AGENTS — explicitly documented in AGENTS.md intro at lines 13-17. But it is invoked in §5 as a blanket carve-out covering all "Architecture, Dependencies, Antipatterns, Testing, Deferral comments" body-text divergence; this blanket coverage extends to GEMINI body text by implication (item #10 cites "bullet ordering variations" as falling within "AGENTS-conciseness principle"). For GEMINI body text, this is **inaccurate** — see SHOULD-1.
- Category #8 (intro howto comment block variations) is defensibly tool-specific (each file's howto guidance addresses its own user).
- Category #10 (bullet ordering variations) is partially defensible but incorrectly attributes GEMINI-only conciseness to AGENTS-conciseness principle.

Concrete GEMINI body-text conciseness divergences NOT addressed and incorrectly classified as "tool-specific":

| Location | CLAUDE.md form | GEMINI.md form | Status |
|---|---|---|---|
| `CLAUDE.md:10-12` intro | "Fill in the Platform and Stack Defaults section... [CONDITIONAL]... (e.g., remove iOS 26 section...)" extra guidance | dropped | Tutorial-guidance asymmetry; arguably tool-neutral (could apply to GEMINI too) |
| `CLAUDE.md:61-63` iOS 26 | "...design language for materials and visual effects. Use ... rather than custom Material or UIVisualEffectView implementations." | "...design language. Use ..." (terse) | Wording-equivalent — would align under General canonicalization heuristic if BD-178's coder treated GEMINI like AGENTS |
| `CLAUDE.md:62` Liquid Glass | "Evaluate before reaching for third-party ML inference" | "Evaluate before third-party ML inference" | Wording-equivalent — no precision delta |
| `CLAUDE.md:63` Availability | "Liquid Glass and FoundationModels require iOS 26+ / macOS 26+. Wrap in #available(iOS 26, *)... guards if the deployment target is below iOS 26 / macOS 26." | "Wrap in #available(iOS 26, *)... if deployment target is below iOS 26." | Wording-equivalent (CLAUDE.md's expanded form is more explicit but doesn't add policy) |
| `CLAUDE.md:71-79` Architecture | 9 bullets with multi-clause sentences | 8 bullets, terse compression | Wording-equivalent; archived analysis §D.4 calls this UNRESOLVED-DRIFT |
| `CLAUDE.md:95-96` Security | "Never hardcode... in source code or config files committed to git. Validate all data... before using it in domain logic" | "Never hardcode... in source or committed config. Validate all data... before use in domain logic" | Wording-equivalent |
| `CLAUDE.md:249-269` Scripts | Multi-line setup guidance + verbose post-edit-check description | Compressed wording | Wording-equivalent |

None of these change policy or behavior. They are all wording-equivalent stylistic compressions. Under the General canonicalization heuristic stated in `pack-ops/BACKLOG.md:1516` ("If two variants are equally valid (wording-only stylistic differences with no precision delta), prefer the CLAUDE.md form"), they should have been aligned to CLAUDE form in GEMINI — OR surfaced to Pack Chat for triage as "appears in scope per fresh sweep, but deferring because BD-173 will re-edit these sections anyway."

**Severity:** SHOULD. The miss is a classification/coverage issue, not a correctness defect. The practical impact may be small because BD-173 (Batch 19c) will re-edit project-template trinity extensively per its description. However, BD-178's stated goal was "fully-symmetric baseline for Batch 19c" — partially missed for GEMINI body text. Either (a) the alignment should be done now, or (b) the deferral should be explicit (new BD for GEMINI body alignment, or note in BD-173 entry that it includes GEMINI body alignment).

---

## §3 Compare-to-IMPL-REPORT (after independent assessment)

After forming independent findings in §2, I read the IMPL-REPORT in full. Comparison:

**Agreements:**
- IMPL-REPORT §3 (3 known loci): matches my independent verification. Per-locus AFTER text is byte-identical with BD-178 entry's proposed canonical wording.
- IMPL-REPORT §4 (POQ-F4-3 placement): decline-precedence analysis is sound (loading vs distribution gap). Note added correctly in lockstep across trinity. The cross-reference to "Stage S4" in INSTALL-PROCEDURES.md is the SHOULD-2 I identified — IMPL-REPORT does not flag this.
- IMPL-REPORT §5.1 (Fresh sweep finds 4 + 5): correctly applied with sound reasoning. Find 5's deviation from CLAUDE-first (CLAUDE.md aligned to AGENTS/GEMINI for PLATFORM_TESTING) is properly justified by intra-CLAUDE consistency + 2-vs-1 majority side.
- IMPL-REPORT §6 (manifest): 3 v11-* SHAs drift correctly; v10-* + existing-* unchanged. Independently verified.
- IMPL-REPORT §7 (validate-pack + persona contracts): all 39 checks + 253/253 contracts PASS. Independently verified.

**Disagreement:**
- IMPL-REPORT §5 item #4 ("AGENTS.md style principle") is invoked as a blanket carve-out for ALL body-text conciseness asymmetries including GEMINI's. The AGENTS-conciseness contract is explicitly documented in `project-template/AGENTS.md:13-17` ("bodies may be more concise here, since the loaded skills carry the full detail"). No analogous contract exists in `project-template/GEMINI.md`. Archived analysis at `maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` §D.4 (lines 432-436) explicitly classifies similar GEMINI conciseness divergences as **UNRESOLVED-DRIFT**, not as tool-specific exception. The §5 item #4 + item #10 conflation of AGENTS-vs-CLAUDE and GEMINI-vs-CLAUDE conciseness asymmetries under one "tool-specific" category is the SHOULD-1 finding.
- IMPL-REPORT §10 success criterion #2 states "PASS — 2 wording-equivalent asymmetries (Project memory intro + PLATFORM_TESTING marker) found + applied; zero substantive asymmetries surfaced". The "zero substantive asymmetries" claim is correct (the GEMINI body conciseness asymmetries don't change policy — they're wording-equivalent). But the "found + applied" framing implies the fresh sweep was complete. It was NOT complete for GEMINI body text — those asymmetries exist (verifiable via `diff CLAUDE.md GEMINI.md`) and were classified as tool-specific rather than as wording-equivalent candidates for alignment.

The classification error does not constitute a state-changing defect (no policy violation, no test failure, no scope creep). It is a documentation-quality issue regarding the completeness claim in §10 #2 + §12 + the §5 tool-specific carve-out framing.

---

## §4 Severity-classified findings table

| # | Severity | Finding | Recommendation |
|---|---|---|---|
| 1 | SHOULD | IMPL-REPORT §5 item #4 + #10 invoke AGENTS-conciseness style as blanket carve-out covering GEMINI body conciseness divergences (iOS 26, Architecture, Security, Scripts sections). AGENTS-conciseness contract is documented in AGENTS.md:13-17; no analogous contract in GEMINI.md. Archived `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` §D.4 explicitly classifies these as UNRESOLVED-DRIFT. The classification is inaccurate for GEMINI. | Either: (a) align GEMINI body text to CLAUDE form for the listed sections under General canonicalization heuristic (likely 30-60 line edits across iOS 26 + Architecture + Security + Scripts sections); (b) defer to BD-173 (Batch 19c) with explicit note in BD-173 entry that it absorbs the GEMINI body-conciseness alignment; (c) open a new follow-up BD for GEMINI body-conciseness alignment, inserted at the appropriate plan position per `feedback_deferral_is_scope_creep`. |
| 2 | SHOULD | POQ-F4-3 Tier 0 installation note cross-references `docs/pack/INSTALL-PROCEDURES.md` § "Stage S4" — no such section exists in any version of INSTALL-PROCEDURES.md (pack-side or client-installed). INSTALL-PROCEDURES.md uses "Procedure N" naming. The "Stage S4" term is script-internal (init-project.sh `stage_s4_skills()` function at `scripts/init-project.sh:484` + runtime banner string + MIGRATION-v10-to-v11.md context). | Rephrase the cross-reference. Options: (a) "See the `stage_s4_skills()` install-time function in `scripts/init-project.sh` and the `boundary-investigation` Tier 0 skill for the canonical reference" — but this is a pack-repo path that won't resolve from client install; (b) drop the named section reference: "See the install-time skill distribution mechanism (init-project.sh `stage_s4_skills()` in the pack repo) and the `boundary-investigation` Tier 0 skill for the canonical reference"; (c) add a "Stage S4" section to INSTALL-PROCEDURES.md (separate BD scope). Apply trinity lockstep to whichever option is chosen. |

No BLOCKERs. No MUSTs. No NITs.

---

## §5 Verification commands + output

```
$ git rev-parse HEAD
3dbfbdb1e0fa3d35b1349426c2c26203b0e8d9d3

$ git show 3dbfbdb --stat --name-only
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md
project-template/AGENTS.md
project-template/CLAUDE.md
project-template/GEMINI.md
test-fixtures/manifest.txt

$ diff project-template/CLAUDE.md project-template/AGENTS.md | wc -l
248

$ diff project-template/CLAUDE.md project-template/GEMINI.md | wc -l
123

$ python3 scripts/validate-pack.py 2>&1 | tail -5
── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean

$ python3 scripts/validate-pack.py 2>&1 | grep "Check 18"
── Check 18: Trinity H2 structure parity (BD-059) ──
  OK: CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)

$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -1
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -1
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -1
=== migration contract: 37 passed, 0 failed ===

$ grep -c "in the same set of edits\|state exactly what will be destroyed\|All three tools (Claude Code, Codex, Gemini CLI) can execute any phase\|Tier 0 installation note" project-template/*.md
project-template/AGENTS.md:4
project-template/CLAUDE.md:4
project-template/GEMINI.md:4

$ grep -n "Stage S4" supporting-docs/INSTALL-PROCEDURES.md
(no output)

$ grep -nE "^## " supporting-docs/INSTALL-PROCEDURES.md
29:## Project file conventions in pack-controlled directories
84:## Procedure 5 — Custom agent and skill workflow
223:## Procedure 5-C — Customization reconciliation after v9.3 → v10 migration
892:## Procedure 5-S — Post-migration housekeeping
933:## Procedure 7 — Kickoff auto-discovery and install-check

$ grep -n "stage_s4_skills\|Stage S4" scripts/init-project.sh
286:        # scaffold-time skill copying. stage_s4_skills copies ALL
484:stage_s4_skills() {
1299:    stage_s4_skills
```

All verification commands match IMPL-REPORT claims with one exception noted in §3 (the §5 item #4 framing inaccuracy regarding GEMINI body conciseness).

---

## §6 Out-of-scope observations

### O-1 — Check 18 H2 parity does not enforce body-text parity (informational)

Check 18 at `scripts/validate-pack.py:1282-1294` validates H2 STRUCTURE parity only (heading names + order). Body-text parity is NOT mechanically enforced. This is the gap that motivated BD-178 (manual alignment) and BD-181 (extending Check 18 H2 to pack-root trinity). BD-181 is already scoped per `pack-ops/BACKLOG.md:1576` — no new BD needed. The body-text parity gap is a known limitation that survives BD-178 and is acknowledged by both the BD-178 + BD-181 entries.

### O-2 — Archived `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` §D.4 UNRESOLVED-DRIFT classification (informational)

The archived doc at `maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` lines 428-436 classifies the GEMINI body-conciseness divergences as UNRESOLVED-DRIFT, with reasoning: "Gemini prefers conciseness is a style preference, not a tool-specific capability difference — so the divergence does NOT satisfy P2's qualifier as the rule is written." This is the analysis source that contradicts IMPL-REPORT §5 item #4's GEMINI classification. SHOULD-1 cites this anchor.

### O-3 — Concurrent BD-177 fix-pass impacting v11-* manifest entries (informational)

BD-177 fix-pass is running concurrently in the background and has edited `scripts/pack-help.sh` + `scripts/tests/pack-help-test.sh` + further drifted `test-fixtures/manifest.txt` v11-* entries. This is NOT a defect in BD-178's commit — BD-178's manifest write was correct at the commit (`3dbfbdb`). BD-177's concurrent v11-surface edit will land in its own commit. Documented per the prompt's "Background-spawn note".

### O-4 — Manifest verify in current working tree shows different SHAs than BD-178 commit (informational)

Running `bash test-fixtures/build.sh --verify` in the current working tree shows different v11-* SHAs than what's in the BD-178 commit's manifest. This is because of O-3 (BD-177 fix-pass has edited v11-surface files in the working tree, which would cause further v11-* drift if regenerated). The BD-178 commit's manifest was correct at the commit time. No action needed for BD-178.

---

End of PACK-REVIEW-BD-178.
