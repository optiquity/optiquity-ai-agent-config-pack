# V10-PHASE-4-PLAN.md

*Created: 2026-04-24*
*Plan type: Phase 4 implementation plan — audit-finding resolution + deferred
verification + ship sequence for v10.0.*
*Status: Draft, awaiting project-lead approval. Read-only document until
approved; no commits executed during plan authoring.*
*Authoring agent: pack-planner (read-only).*

---

## Part 0 — Status, supersession, and scope

**This plan does NOT supersede `V10-IMPLEMENTATION-PLAN.md`.** It is a
Phase-4 sibling. The implementation plan governed Phases 1, 2, 3, and
3-AC (Gates A–E2). Phase 3-B was governed by `V10-PHASE-3B-PLAN-v2.md`
(plus its v2 design `V10-PHASE-3B-DESIGN-v2.md`), which superseded the
v1 plan/design for Part 7 §7.2 and Part 10. Phase 4 — the contents of
this document — covers the period between v10-dev tip `604895c`
(BD-047 Resolved + BD-048 filed) and v10.0 tagged on main.

**Inherited specs (read-only inputs).**
- `V10-DESIGN.md` (APPROVED 2026-04-21; addendum AD-14..AD-18 merged 2026-04-22).
- `V10-IMPLEMENTATION-PLAN.md` §6.7 Gate F entry criteria, §6.8 Ship
  sequence (S-01..S-03 + merge + tag).
- `V10-PHASE-3B-PLAN-v2.md` Part 7 (Gate E3 entry criteria, including
  the three deferred items carried forward to Gate F) and Part 5
  (fixture sourcing strategy).
- `V10-PHASE-3B-DESIGN-v2.md` Part 11 (smoke-test surface matrix).
- `V10-AUDIT-REPORT.md` (AF-001..AF-020) and
  `V10-AUDIT-REPORT-2.md` (AF-021..AF-033).

**Scope of Phase 4 (three streams).**
1. **Audit-finding resolution.** All 31 findings AF-001..AF-033 with
   project-lead decisions D1–D8 baked in. AF-027 alone has "no action"
   as its only feasible resolution (historical commit message cannot
   be retrofitted).
2. **Deferred Gate E3 verification.** Three smoke-test obligations
   carried from Gate E3 because they cannot run against the pack repo
   itself: (a) fixture evidence, (b) cross-surface checks, (c) Claude
   Web manual-mode smoke. See Part 4.
3. **Ship sequence (S-01..S-03 + merge + tag).** CHANGELOG.md v10.0
   entry, README.md version table row, BACKLOG.md sweep, merge
   v10-dev → main, tag `v10.0`, move bare `v10` major tag from v9.3
   to v10.0 commit per `CLAUDE.md` "Versioning convention" /
   "Tag move sequence". See Part 6.

**Phase 4's terminal gate is Gate F** — the mandatory full structural-
validation gate before ship. Entry criteria are explicit in Part 5.

**Constraint inherited from `CLAUDE.md`.** Every commit must leave the
pack in a state where `validate-pack.py` exits 0 and the GitHub Actions
`Validate Pack` workflow passes. No exceptions.

**Branch.** All work continues on `v10-dev`. The merge to `main` is the
final S-step and only runs after the explicit "ship v10.0" approval.

---

## Part 1 — Decisions table (D1..D8 restated; commit homes assigned)

Project-lead decisions, replayed in plan-author voice for the
implementer. Not re-litigated. Each row maps to the commit that
implements it.

| # | Decision | Authoritative source | Plan-author restatement | Target commit |
|---|---|---|---|---|
| **D1** | AF-011 — `## Agent roster` asymmetry | Main audit Part 10 OQ 2 → Option (a) | Keep `## Agent roster` in `project-template/GEMINI.md` only. Add a brief justification comment inside GEMINI.md immediately above (or below) the section explaining the asymmetry as a Gemini-CLI-presentation aid. Do NOT add the section to CLAUDE.md or AGENTS.md. Trinity-rule exception is documented in-file. | **C-V10-06** |
| **D2** | V9-DESIGN.md status | Main audit Part 10 OQ 6 → Option (c) | Move `maintenance-docs/V9-DESIGN.md` to `maintenance-docs/archive/V9-DESIGN.md`. Create the `archive/` sub-directory if it does not exist. No content edit; lift-and-shift only. | **C-V10-13** |
| **D3** | V10-DESIGN-PROCESS-PLAN.md scope | Main audit Part 10 OQ 7 → Option (a) | Audit it. Already executed — `V10-AUDIT-REPORT-2.md` (13 findings AF-021..AF-033) is the result. No further plan-side action; resolutions are folded into D4–D7 below. | **(meta — already executed)** |
| **D4** | AF-025 / Audit-2 §5 archive option for V10-DESIGN-PROCESS-PLAN.md | Audit-2 Part 8 OQ 1 → Option A | Add a status/lifecycle banner at the top of `V10-DESIGN-PROCESS-PLAN.md` (in place). Do NOT move the file to `archive/`. Asymmetric treatment vs. V9-DESIGN.md is principled: V9-DESIGN.md has zero live inbound references; this plan has 11. | **C-V10-11** |
| **D5** | AF-021 phase numbering | Audit-2 Part 8 OQ 2 | Reconcile inside the AF-025 banner with a one-liner: *"This plan governed V10-PREDESIGN Phases 1+2 collapsed; the Phase 1/Phase 3 wording in Step 13 reflects that collapse — V10-PREDESIGN Phase 2 (the design pass) is implicit in this plan's Steps 9–13."* No body edit beyond the banner. | **C-V10-11** |
| **D6** | AF-024 CD-7 wording correction | Audit-2 Part 8 OQ 3 | One-sentence fix in `V10-DESIGN-PROCESS-PLAN.md` Step 5 item 5 (line 343) and §6 cross-reference matrix CD-7 row (line 785): change `(PLATFORM-SKILLS.md `## Custom skills` section)` to `(PLATFORM-SKILLS.md `## Custom agents` and `## Custom skills` sections)`. Two-line edit. | **C-V10-11** |
| **D7** | AF-033 V9-DESIGN.md path updates | Audit-2 Part 8 OQ 4 | Fold the four path-reference updates inside `V10-DESIGN-PROCESS-PLAN.md` into the SAME commit that moves V9-DESIGN.md to `archive/`. Updates touch lines 88, 524, 633, 681 (each `maintenance-docs/V9-DESIGN.md` → `maintenance-docs/archive/V9-DESIGN.md`). Same commit also re-greps the pack for any other live `maintenance-docs/V9-DESIGN.md` reference and updates if found. | **C-V10-13** |
| **D8** | V10-PREDESIGN.md part count | Audit-2 Part 8 OQ 5 (auditor bonus, not numbered AF) | One-character correction in `V10-DESIGN-PROCESS-PLAN.md` §2 line 82: `"11 parts"` → `"12 parts"` (V10-PREDESIGN.md has Part 12 "Agent Report File Convention"). No edit to V10-PREDESIGN.md itself. | **C-V10-12** |

**No re-litigation note.** D1–D8 are settled. If the implementer
believes a decision should be reopened, that is a Part 8 flag-back, not
a unilateral redirection.

---

## Part 2 — Audit-finding resolution table (AF-001..AF-033)

One row per finding. **Severity** mirrors the audit reports.
**Decision/Note** captures any project-lead decision (D-N) or
plan-author classification. **Target commit** is one of C-V10-01..17
(Part 3). **Expected diff** is the implementer's checkable signature
of a closed finding.

### 2.1 Main audit findings (AF-001..AF-020)

| AF | Severity | Decision/Note | Target commit | Expected diff summary |
|---|---|---|---|---|
| **AF-001** | ship-blocker | Lands first to clear v10-dev tip of the known ship-blocker | **C-V10-01** | `supporting-docs/SETUP-NEW.md`: rewrite § Manual fallback 5.A. Replace `scripts/validate.sh`, `scripts/test.sh`, `scripts/format.sh` with `scripts/validate-swift.sh`, `scripts/test-swift.sh`, `scripts/format-swift.sh` (lines 169 and 198 plus three code-fence headings). Body wording aligned with METHODOLOGY.md Procedure 7 §7.2.2. ~6–10 lines changed. |
| **AF-002** | nice-to-fix | Fold with AF-008, AF-019 into one maintenance-doc refresh commit | **C-V10-09** | `maintenance-docs/V10-IMPLEMENTATION-PLAN.md` §6.6-B (lines 1617–1666): commit list updated to three commits (1c5116c, db416a0, 2a0c8d5); Gate E3 criteria updated to S3B-1..S3B-6; remove `METHODOLOGY.md` from "untouched" list; replace with "METHODOLOGY.md modified by Commit 3 to add Procedure 7." ~30–40 lines changed. |
| **AF-003** | nice-to-fix | TRIO trinity edit | **C-V10-02** | `project-template/AGENTS.md` § "Architecture — universal layer discipline": add the Navigation bullet ("Navigation logic lives outside view and view-model types") to match CLAUDE.md line 95 and GEMINI.md line 89. 1 line added. |
| **AF-004** | nice-to-fix | Same TRIO commit as AF-003 | **C-V10-02** | `project-template/AGENTS.md` end of phase-routing table (after line 310): add the italic cost-optimized-routing paragraph pointing at TOOL-COMPARISON.md. ~3 lines added. |
| **AF-005** | nice-to-fix | Folded into version-string refresh batch | **C-V10-03** | `project-template/docs/pack/prompts/pm-chat.md` line 33: `AI Agent Config Pack v8` → `AI Agent Config Pack v10.0`. 1 line changed. |
| **AF-006** | nice-to-fix | Same batch | **C-V10-03** | "Copied from: …v9" banners replaced with v10 in: `project-template/CLAUDE.md` line 21, `project-template/AGENTS.md` line 18, `project-template/GEMINI.md` line 17, `project-template/docs/pack/PACK-FEEDBACK.md` line 27, `project-template/docs/pack/PM-CHAT.md` line 22, `project-template/README.md` line 1. (SETUP_TEMPLATE.md and AGENT_KICKOFF_TEMPLATE.md handled by AF-015/AF-016 in same commit.) ~6 lines changed. |
| **AF-007** | nice-to-fix | Single-purpose commit (cleanest review surface) | **C-V10-04** | `supporting-docs/MIGRATION-v9-to-v10.md` § "What changed in v10": add fourth bullet for BD-047 (Procedure 7 + pm-chat.md kickoff continuation pointer + Manual fallback). ~6–10 lines added. |
| **AF-008** | nice-to-fix | Folded with AF-002 | **C-V10-09** | Same file as AF-002. §6.6-B "Authoritative documents" list (lines 1625–1631): add `V10-PHASE-3B-DESIGN-v2.md` and `V10-PHASE-3B-PLAN-v2.md`; annotate the v1 entries as superseded for Part 7 §7.2 + Part 10 (design) and full execution spec (plan). ~4–6 lines changed. |
| **AF-009** | nice-to-fix | Single-purpose commit (METHODOLOGY.md is high-impact; cleanest review surface) | **C-V10-05** | `supporting-docs/METHODOLOGY.md` Appendix "Day 1 — Setup" (line 1610 region): rewrite the "cp -r pack/[TEMPLATE]/. ." block to match SETUP-NEW.md Step 3 (`"$PACK/scripts/init-project.sh" .`). Drop `[TEMPLATE]` placeholder. ~10–15 lines changed. |
| **AF-010** | nice-to-fix | Folded into version-string refresh batch | **C-V10-03** | `supporting-docs/METHODOLOGY.md` lines 3–4 and line 1644: v9 → v10. Header `Version: 2.0 (v9, April 2026)` → `Version: 2.1 (v10.0, April 2026)` (or equivalent — bump version because Procedure 7 added). 2 lines changed. |
| **AF-011** | note (judgment call) | **D1**: keep in GEMINI.md only with justification comment | **C-V10-06** | `project-template/GEMINI.md` lines 377–391 region: add a one-line justification comment immediately above `## Agent roster`: `<!-- Trinity-rule exception: Gemini CLI auto-discovers agents via filesystem scan of .gemini/agents/. The roster below is a presentation aid for the human reader; CLAUDE.md and AGENTS.md rely on the phase-routing table and tool-side discovery. -->` 1 line added. |
| **AF-012** | nice-to-fix | Single-purpose; small commit | **C-V10-07** | Both SETUP guides: add a one-line italic note under Step 5 explaining the step-number gap. `supporting-docs/SETUP-NEW.md`: gap 6–8 (Steps 5–8 collapsed into Step 5). `supporting-docs/SETUP-EXISTING.md`: gap 6 only. ~2 lines added per file. |
| **AF-013** | note | Footnote in V10-DESIGN.md | **C-V10-08** | `maintenance-docs/V10-DESIGN.md` Part 2 rejected alternatives (lines 750–752): add a one-line parenthetical clarifying that BD-047 was later assigned to a different scope (kickoff auto-discovery) on 2026-04-24. ~2 lines added. |
| **AF-014** | nice-to-fix | Folded into version-string refresh batch | **C-V10-03** | `supporting-docs/DEPENDENCIES.md` line 3: v9 → v10. 1 line changed. |
| **AF-015** | nice-to-fix | Folded into version-string refresh batch | **C-V10-03** | `supporting-docs/SETUP_TEMPLATE.md` lines 18 and 35: v9 → v10. 2 lines changed. |
| **AF-016** | nice-to-fix | Folded into version-string refresh batch | **C-V10-03** | `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` line 21: v9 → v10. 1 line changed. |
| **AF-017** | note | Folded into version-string refresh batch | **C-V10-03** | `supporting-docs/CLI-PM-SETUP.md` line 5: rewrite "Setup is in QUICKSTART.md" pointer to `Setup is in supporting-docs/SETUP-NEW.md Step 10 Option B (Claude Code CLI) or Option D (Gemini CLI). Start there if you haven't completed setup yet.` ~2 lines changed. |
| **AF-018** | note | Same batch | **C-V10-03** | `supporting-docs/CLI-PM-SETUP.md` line 7: rewrite "PM-CHAT.md in the project root" → "docs/pack/PM-CHAT.md" (consistent with BD-042). ~2 lines changed. |
| **AF-019** | note | Folded with AF-002, AF-008 — tighten the S3B-5 sanctioned-residuals list | **C-V10-09** | `maintenance-docs/V10-PHASE-3B-PLAN-v2.md` Part 6 §6.5 (S3B-5 expected-results list): add explicit sanctioned-residuals enumeration (BACKLOG.md Resolution-line mention, SETUP-NEW.md descriptive mention, SETUP-EXISTING.md descriptive mention, three pm-chat.md mentions accepted as Path A). Audit-aligned wording: "descriptive-not-prescriptive mentions are sanctioned; redundant routing pointers are forbidden." ~8–12 lines changed. |
| **AF-020** | note | Style-preamble note in METHODOLOGY.md Part 7 | **C-V10-10** | `supporting-docs/METHODOLOGY.md` Part 7 preamble (immediately under the `## Part 7` heading): add a one-paragraph note: *"Sub-procedure heading style varies by procedure: Procedure 5 uses `#### Procedure 5.N`; Procedure 6 uses `#### 6.N`; Procedure 7 uses `#### 7.N` with `##### 7.N.M` for sub-Forms. Each procedure's local convention is intentional; do not normalize across procedures."* ~5–8 lines added. |

### 2.2 Focused-audit findings (AF-021..AF-033)

| AF | Severity | Decision/Note | Target commit | Expected diff summary |
|---|---|---|---|---|
| **AF-021** | note | **D5**: reconcile inside the AF-025 banner | **C-V10-11** | One-line clause appended to AF-025 status banner explaining the Phase 1/2 collapse. No body edit to Step 13. |
| **AF-022** | note | Optional Step 12 round-count annotation; deferrable, but project-lead directive is "all 31 audit findings must be resolved" — implementer adds a single annotation | **C-V10-11** | `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` §5 G9 row (line 768): append `In practice, executed as 5 iterative rounds (see V10-DESIGN.md Part 0 row 15).` ~1 line added. |
| **AF-023** | note | Resolved by AF-025 banner | **C-V10-11** | AF-025 banner includes the clause: "V10-DESIGN.md Part 2 landed with AD-1..AD-18; the final five (AD-14..AD-18) are the capability-addition addendum not anticipated by this plan." No separate body edit. |
| **AF-024** | nice-to-fix | **D6**: one-sentence fix in plan body | **C-V10-11** | Two-line edit: line 343 (Step 5 item 5) and line 785 (§6 matrix CD-7 row). |
| **AF-025** | nice-to-fix | **D4**: status banner in place; no archive move | **C-V10-11** | `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` immediately under H1: insert multi-line italic banner per Audit-2 §5 Option A wording, augmented with D5/AF-023 clauses. ~6–10 lines added. |
| **AF-026** | note | Resolved by AF-025 banner (banner signals historical status; no tense rewrite) | **C-V10-11** | No additional edit beyond AF-025 banner. |
| **AF-027** | **note — NO ACTION** | Historical commit message `4df382d` cannot be retrofitted; documented as accepted plan-reality drift | **(no commit)** | No diff. Plan documents this acceptance in Part 9 risk register and Audit-2 §3.3 reference. |
| **AF-028** | note | Resolved by AF-025 banner (banner signals plan is historical; "v9.x" wording was correct at write time) | **C-V10-11** | No additional edit. |
| **AF-029** | note | Same — banner-resolved | **C-V10-11** | No additional edit. |
| **AF-030** | note | Same — banner-resolved (PROMPT-TEMPLATES.md is already deleted in v10; plan's references are historically accurate) | **C-V10-11** | No additional edit. |
| **AF-031** | note | Add one-sentence Block-glossary line at §3 opening | **C-V10-11** | `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` immediately under `## Part 3` (line 100 region): add one sentence: *"Blocks A–F are an internal grouping device for the 13 steps; other v10 docs cite step numbers directly and do not reference Block letters."* ~1 line added. |
| **AF-032** | note | Resolved by AF-025 banner | **C-V10-11** | No additional edit. |
| **AF-033** | note | **D7**: fold path updates into the V9-DESIGN.md archive-move commit | **C-V10-13** | `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` four path references (lines 88, 524, 633, 681): `maintenance-docs/V9-DESIGN.md` → `maintenance-docs/archive/V9-DESIGN.md`. ~4 lines changed. Plus a repo-wide grep audit for any other live reference. |

**Coverage check.** Every AF-NNN appears in §2.1 or §2.2. AF-027 is the
only "no action" row. The implementer must verify the table covers
001..033 inclusive before opening any commit.


---

## Part 3 — Commit sequence (C-V10-01 .. C-V10-18)

Each commit is a **single approval gate** for the project lead. The
implementer runs the per-commit verification checklist in Part 7 before
asking for approval, shows `git status` + `git diff --stat`, then
commits only after explicit approval.

**Commit-message conventions (per `CLAUDE.md`).**
- Format: `<prefix>: vN — BD-NNN short description` or
  `<prefix>: brief description` for non-BD-scoped fixes.
- N is the current major version (10).
- No trailing period. No multi-line body required for any of these.

**Ordering rationale.**
- C-V10-01 (AF-001) lands first to clear the known ship-blocker from
  v10-dev tip.
- Trinity / version-string / migration / methodology batch (C-V10-02 →
  C-V10-10) follow — these are pack-product edits.
- Maintenance-docs banners and corrections (C-V10-11 → C-V10-13) come
  next; the V9-DESIGN.md archive move (C-V10-13) lands last among the
  doc commits because it touches the most cross-references and
  benefits from all earlier edits being settled.
- C-V10-14 (`scripts/test-detect.sh` test harness) is CI infrastructure;
  lands before the verification-evidence commit so its output can be
  captured.
- C-V10-15 (verification harness) records evidence (fixtures + cross-
  surface + manual mode + migration smoke + detect.sh test results);
  lands after all fixes and the test harness are in place so the
  verification reflects ship-ready state.
- C-V10-16..18 are the ship-prep edits (CHANGELOG, README, BACKLOG)
  immediately preceding the merge / tag in Part 6.

---

### C-V10-01 — `fix:` SETUP-NEW.md Manual fallback 5.A script-name correction

- **Message:** `fix: v10 — BD-047 SETUP-NEW.md Manual fallback names -swift.sh script variants`
- **Prefix:** `fix:` (ship-blocker correction; no new feature, no doc structure change)
- **Files touched (1):**
  - `supporting-docs/SETUP-NEW.md`
- **Expected diff scope:** ~6–10 lines changed in § Manual fallback 5.A around lines 169 and 198. Three code-fence headings updated. Body wording aligned with METHODOLOGY.md Procedure 7 §7.2.2 (byte-parity intent per V10-PHASE-3B-PLAN-v2 Part 11 §11.1).
- **Findings closed:** AF-001.
- **Verification before commit:**
  - `grep -nE 'scripts/(validate|test|format)\.sh' supporting-docs/SETUP-NEW.md` returns no matches inside § Manual fallback 5.A (matches elsewhere in the file are acceptable if they describe the wrappers in non-edit context — re-grep to confirm).
  - `diff <(awk '/§ ?Manual fallback 5\.A/,/§ ?Manual fallback 5\.B/' supporting-docs/SETUP-NEW.md) <(awk '/^#### 7\.2\.2/,/^#### 7\.2\.3/' supporting-docs/METHODOLOGY.md)` — semantic parity (not strict byte-parity; the SETUP guide narrates, the procedure prescribes).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-01** — project-lead approval before commit.

---

### C-V10-02 — `docs:` AGENTS.md trinity drift (Navigation bullet + cost-routing note)

- **Message:** `docs: v10 — AGENTS.md trinity parity (Navigation bullet, cost-routing note)`
- **Prefix:** `docs:` (no new feature; trinity-rule alignment)
- **Files touched (1):**
  - `project-template/AGENTS.md`
- **Expected diff scope:** ~4 lines added. (1) Navigation bullet under "Architecture — universal layer discipline" (matching CLAUDE.md line 95 / GEMINI.md line 89). (2) Italic cost-optimized-routing paragraph at end of phase-routing table (matching CLAUDE.md lines 432–434 / GEMINI.md lines 363–365).
- **Findings closed:** AF-003, AF-004.
- **TRIO awareness:** This commit edits AGENTS.md only because CLAUDE.md and GEMINI.md already carry both items. The trinity rule (`CLAUDE.md` pack-repo) is satisfied by parity, not by uniform edits. Implementer must verify symmetry post-edit by re-reading the three locations side-by-side.
- **Verification before commit:**
  - `diff <(awk '/Architecture — universal layer discipline/,/^## /' project-template/CLAUDE.md | grep -E '^- ') <(awk '/Architecture — universal layer discipline/,/^## /' project-template/AGENTS.md | grep -E '^- ')` — empty diff.
  - Same diff against GEMINI.md.
  - `python3 scripts/validate-pack.py` exits 0 (Check 7 trinity audit).
- **Approval gate:** **G-V10-02**.

---

### C-V10-03 — `docs:` v10 version-string refresh (8 files; one batch)

- **Message:** `docs: v10 — version string refresh (v9/v8 → v10 across template + supporting docs)`
- **Prefix:** `docs:`
- **Files touched (12):**
  - `project-template/CLAUDE.md`
  - `project-template/AGENTS.md`
  - `project-template/GEMINI.md`
  - `project-template/docs/pack/PACK-FEEDBACK.md`
  - `project-template/docs/pack/PM-CHAT.md`
  - `project-template/README.md`
  - `project-template/docs/pack/prompts/pm-chat.md`
  - `supporting-docs/METHODOLOGY.md`
  - `supporting-docs/DEPENDENCIES.md`
  - `supporting-docs/SETUP_TEMPLATE.md`
  - `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`
  - `supporting-docs/CLI-PM-SETUP.md`
- **Expected diff scope:** ~20–25 lines changed across the 12 files (most are 1–2 lines per file).
  - Banners / headers: v9 → v10.0 (or v10) consistent with file convention.
  - METHODOLOGY.md header: `Version: 2.0 (v9, April 2026)` → `Version: 2.1 (v10.0, April 2026)`; footer line 1644 mirror.
  - pm-chat.md line 33: v8 → v10.0.
  - CLI-PM-SETUP.md lines 5 + 7: stale-pointer fixes (AF-017, AF-018).
- **Findings closed:** AF-005, AF-006, AF-010, AF-014, AF-015, AF-016, AF-017, AF-018.
- **TRIO awareness:** CLAUDE.md / AGENTS.md / GEMINI.md banners must all become v10 in the same commit (uniform edit; trinity-rule symmetry preserved).
- **Verification before commit:**
  - `grep -rnE 'AI Agent Config Pack v[89]([^.]|$)' project-template/ supporting-docs/` returns ZERO matches in the ship surfaces. (Historical maintenance-docs / migration-v8-to-v9 references are acceptable; they are excluded from the grep target above.)
  - `grep -nE 'AI Agent Config Pack v8' project-template/docs/pack/prompts/pm-chat.md` returns zero.
  - `grep -nE 'PM-CHAT\.md.*project root' supporting-docs/CLI-PM-SETUP.md` returns zero.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-03**.

---

### C-V10-04 — `docs:` MIGRATION-v9-to-v10.md add BD-047 entry

- **Message:** `docs: v10 — MIGRATION-v9-to-v10.md add BD-047 entry`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `supporting-docs/MIGRATION-v9-to-v10.md`
- **Expected diff scope:** ~6–10 lines added. New bullet under § "What changed in v10" listing BD-047 (Procedure 7 + pm-chat.md kickoff continuation pointer + Manual fallback non-shell path).
- **Findings closed:** AF-007.
- **Verification before commit:**
  - `grep -nE 'BD-04[5-7]' supporting-docs/MIGRATION-v9-to-v10.md` shows BD-044, BD-045, BD-046, BD-047 all present in the "What changed" section.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-04**.

---

### C-V10-05 — `docs:` METHODOLOGY.md Appendix init-project.sh rewrite

- **Message:** `docs: v10 — METHODOLOGY.md Appendix Day 1 setup uses init-project.sh`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `supporting-docs/METHODOLOGY.md`
- **Expected diff scope:** ~10–15 lines changed in Appendix "Day 1 — Setup" (around line 1610). Replace `cp -r pack/[TEMPLATE]/. .` and the separate-METHODOLOGY-copy steps with the SETUP-NEW.md Step 3 wording: `"$PACK/scripts/init-project.sh" .`.
- **Findings closed:** AF-009.
- **Verification before commit:**
  - `grep -n 'cp -r pack' supporting-docs/METHODOLOGY.md` returns zero matches.
  - `grep -n '\[TEMPLATE\]' supporting-docs/METHODOLOGY.md` returns zero matches.
  - Appendix Day-1 wording matches SETUP-NEW.md Step 3 by inspection (not byte-parity, but command identical).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-05**.

---

### C-V10-06 — `docs:` GEMINI.md Agent roster trinity-exception comment (per D1)

- **Message:** `docs: v10 — GEMINI.md Agent roster trinity-exception comment`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `project-template/GEMINI.md`
- **Expected diff scope:** 1–2 lines added. HTML comment immediately above (or below) `## Agent roster` heading explaining the asymmetry as a Gemini-CLI-presentation aid (CLAUDE.md and AGENTS.md rely on the phase-routing table and tool-side discovery).
- **Findings closed:** AF-011 (per D1).
- **Verification before commit:**
  - `grep -n 'Agent roster' project-template/GEMINI.md` returns the original section heading.
  - `grep -nB1 'Agent roster' project-template/GEMINI.md` shows the new comment.
  - Section content unchanged (no agents added/removed).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-06**.

---

### C-V10-07 — `docs:` SETUP guides step-number gap explanatory note

- **Message:** `docs: v10 — SETUP-NEW + SETUP-EXISTING explain step-number gaps`
- **Prefix:** `docs:`
- **Files touched (2):**
  - `supporting-docs/SETUP-NEW.md`
  - `supporting-docs/SETUP-EXISTING.md`
- **Expected diff scope:** ~2 lines added per file. Italic note under Step 5 in each guide. SETUP-NEW gap = 6–8 (Steps 5–8 collapsed into Step 5 by BD-047 Phase 3-B); SETUP-EXISTING gap = 6 only.
- **Findings closed:** AF-012.
- **Verification before commit:**
  - `grep -nE '^### Step ' supporting-docs/SETUP-NEW.md` shows steps 1, 2, 3, 4, 5, 9, 10, 11, 12 (gap intentional).
  - `grep -nE '^### Step ' supporting-docs/SETUP-EXISTING.md` shows steps 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12 (gap intentional).
  - Both files contain the new italic explanation.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-07**.

---

### C-V10-08 — `docs:` V10-DESIGN.md BD-047 reused-number footnote

- **Message:** `docs: v10 — V10-DESIGN.md Part 2 footnote re BD-047 number reuse`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `maintenance-docs/V10-DESIGN.md`
- **Expected diff scope:** ~2 lines added in Part 2 rejected alternatives (lines 750–752). Parenthetical clarifying that BD-047 was later assigned to a different scope (kickoff auto-discovery) on 2026-04-24.
- **Findings closed:** AF-013.
- **Verification before commit:**
  - `grep -nC2 'BD-047' maintenance-docs/V10-DESIGN.md | head -20` shows the new footnote on lines 750–752.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-08**.

---

### C-V10-09 — `docs:` V10-IMPLEMENTATION-PLAN §6.6-B refresh + V10-PHASE-3B-PLAN-v2 S3B-5 tighten

- **Message:** `docs: v10 — V10-IMPLEMENTATION-PLAN §6.6-B v2 commit shape; V10-PHASE-3B-PLAN-v2 S3B-5 sanctioned residuals`
- **Prefix:** `docs:`
- **Files touched (2):**
  - `maintenance-docs/V10-IMPLEMENTATION-PLAN.md`
  - `maintenance-docs/V10-PHASE-3B-PLAN-v2.md`
- **Expected diff scope:**
  - V10-IMPLEMENTATION-PLAN.md §6.6-B (lines 1617–1666): ~30–40 lines changed. Authoritative-documents list (lines 1625–1631) gains v2 siblings; commit list updated to 1c5116c, db416a0, 2a0c8d5; Gate E3 criteria mention S3B-5 and S3B-6; "untouched" list no longer claims METHODOLOGY.md is untouched.
  - V10-PHASE-3B-PLAN-v2.md Part 6 §6.5 S3B-5 expected-results list: ~8–12 lines changed. Sanctioned residuals enumerated (BACKLOG.md Resolution-line, SETUP-NEW.md descriptive mention, SETUP-EXISTING.md descriptive mention, three pm-chat.md mentions accepted as Path A); forbidden category restated as "redundant routing pointers."
- **Findings closed:** AF-002, AF-008, AF-019.
- **Verification before commit:**
  - `grep -n 'V10-PHASE-3B-PLAN-v2' maintenance-docs/V10-IMPLEMENTATION-PLAN.md` returns ≥1 match.
  - `grep -n 'METHODOLOGY.md.*untouched' maintenance-docs/V10-IMPLEMENTATION-PLAN.md` returns zero matches.
  - `grep -nE 'S3B-[1-6]' maintenance-docs/V10-IMPLEMENTATION-PLAN.md` shows all six sweeps named.
  - `grep -nC3 'sanctioned residuals' maintenance-docs/V10-PHASE-3B-PLAN-v2.md` shows the new enumeration.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-09**.

---

### C-V10-10 — `docs:` METHODOLOGY.md Part 7 sub-heading style preamble note

- **Message:** `docs: v10 — METHODOLOGY.md Part 7 preamble note on per-procedure sub-heading style`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `supporting-docs/METHODOLOGY.md`
- **Expected diff scope:** ~5–8 lines added under the `## Part 7` heading (preamble paragraph). Names the three local conventions (Procedure 5 / 6 / 7) and states they are intentional.
- **Findings closed:** AF-020.
- **Verification before commit:**
  - `grep -nA8 '^## Part 7' supporting-docs/METHODOLOGY.md | head -15` shows the new preamble paragraph.
  - No procedure body change (greps for `^### Procedure ` and `^#### ` line counts unchanged from pre-commit).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-10**.

---

### C-V10-11 — `docs:` V10-DESIGN-PROCESS-PLAN.md status banner + content corrections

- **Message:** `docs: v10 — V10-DESIGN-PROCESS-PLAN.md status banner + AF-021/022/024/031 corrections`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
- **Expected diff scope:** ~14–20 lines changed total.
  - **Status banner (AF-025 + D4):** Multi-line italic block immediately under H1. Wording from Audit-2 §5 Option A, augmented with:
    - D5/AF-021 clause: phase-numbering reconciliation (Phases 1+2 collapsed).
    - AF-023 clause: AD-1..AD-18 vs. anticipated AD-1..AD-13.
    - Implicit signal that AF-026, AF-028, AF-029, AF-030, AF-032 are resolved by the banner's "historical artifact" framing.
  - **AF-022 (optional but landed per project-lead directive):** §5 G9 row (line 768) gains a one-line "5 iterative rounds" annotation.
  - **AF-024 (D6):** Step 5 item 5 (line 343) and §6 matrix CD-7 row (line 785) — `## Custom skills` → `## Custom agents` and `## Custom skills`.
  - **AF-031:** §3 opening (line 100 region) — one-sentence Block-glossary line.
- **Findings closed:** AF-021, AF-022, AF-023, AF-024, AF-025, AF-026, AF-028, AF-029, AF-030, AF-031, AF-032.
- **Path-reference updates excluded:** AF-033 (V9-DESIGN.md path) is intentionally NOT in this commit — D7 puts it in C-V10-13 alongside the archive move.
- **Verification before commit:**
  - `head -20 maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` shows the status banner immediately under H1.
  - `grep -n 'Custom agents.*Custom skills' maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` returns ≥2 matches (Step 5 + §6 matrix).
  - `grep -nA1 'Block A' maintenance-docs/V10-DESIGN-PROCESS-PLAN.md | head -5` shows the gloss sentence.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-11**.

---

### C-V10-12 — `docs:` V10-PREDESIGN.md part-count correction (D8)

- **Message:** `docs: v10 — V10-DESIGN-PROCESS-PLAN.md part-count correction (V10-PREDESIGN 11→12 parts)`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
- **Expected diff scope:** 1 line changed. §2 line 82: `"11 parts"` → `"12 parts"`.
- **Findings closed:** D8 (auditor bonus, not a numbered AF).
- **Note on file selection:** D8's correction lives in V10-DESIGN-PROCESS-PLAN.md (the document whose §2 references V10-PREDESIGN). V10-PREDESIGN.md itself does NOT need an edit — Part 12 already exists at line 822.
- **Verification before commit:**
  - `grep -n 'V10-PREDESIGN.md' maintenance-docs/V10-DESIGN-PROCESS-PLAN.md | head -5` shows the corrected `12 parts` wording around line 82.
  - `grep -c '^## Part ' maintenance-docs/V10-PREDESIGN.md` returns 12 (sanity check).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-12**.

---

### C-V10-13 — `docs:` move V9-DESIGN.md to archive/ + V10-DESIGN-PROCESS-PLAN path updates (D2 + D7)

- **Message:** `docs: v10 — archive V9-DESIGN.md; update V10-DESIGN-PROCESS-PLAN paths`
- **Prefix:** `docs:` (project-lead-resolved per OQ-V10-1; CLAUDE.md enumerates `feat:`/`fix:`/`docs:` only). The operation is structural (file move + path updates) but `docs:` is the conservative choice within the enumerated prefix set.
- **Files touched (2):**
  - `maintenance-docs/V9-DESIGN.md` → `maintenance-docs/archive/V9-DESIGN.md` (git mv)
  - `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` (path-reference updates on lines 88, 524, 633, 681, plus any others surfaced by the repo-wide grep).
- **Optional README.md Repository Layout update:** The current Repository Layout section enumerates `maintenance-docs/V9-DESIGN.md` at line 99. After the archive move, the layout should add `archive/` as a sub-directory (or note V9-DESIGN.md's new home). Land this edit in the same commit to keep README accurate. ~2 lines changed.
- **Files touched (potentially 3):**
  - As above + `README.md` Repository Layout section.
- **Expected diff scope:** 1 file rename, ~4 path edits in V10-DESIGN-PROCESS-PLAN.md, ~2 lines in README.md = ~7 lines + 1 rename total.
- **Findings closed:** D2 (V9-DESIGN.md archive), AF-033 (path updates), partial README freshness.
- **Verification before commit:**
  - `git mv` preserves history (`git log --follow maintenance-docs/archive/V9-DESIGN.md` shows v9 history).
  - `grep -rn 'maintenance-docs/V9-DESIGN\.md' . --include='*.md'` returns ZERO matches (excluding the moved file itself, which now lives at `archive/V9-DESIGN.md`).
  - `grep -rn 'maintenance-docs/archive/V9-DESIGN\.md' . --include='*.md'` returns ≥4 matches (the four updated references in V10-DESIGN-PROCESS-PLAN.md).
  - `ls maintenance-docs/archive/V9-DESIGN.md` exists.
  - `ls maintenance-docs/V9-DESIGN.md` returns "No such file or directory."
  - `python3 scripts/validate-pack.py` exits 0 (validate-pack.py does NOT enforce a maintenance-docs/V9-DESIGN.md path; verify with the actual run).
  - `validate-pack.yml` GitHub Actions check is the authoritative pre-commit signal.
- **Approval gate:** **G-V10-13**.


---

### C-V10-14 — `feat:` `scripts/test-detect.sh` unit tests for `detect.sh`

- **Message:** `feat: v10 — scripts/test-detect.sh unit tests for detect.sh library functions`
- **Prefix:** `feat:` (new test-runner script artifact).
- **Files touched (1, NEW):**
  - `scripts/test-detect.sh` (new; executable; pure bash test runner)
- **Expected diff scope:** ~150–250 lines added (new file). One test
  function per `detect.sh` function (8 total per Part 4.5 table); inline
  fixture construction; pass/fail accounting; exit-0-on-all-pass.
- **Findings closed:** Phase 4 deliverable per V10-IMPLEMENTATION-PLAN
  line 45 (B5 obligation). Closes Gate F criterion 6 (detect.sh test
  harness exists and passes).
- **Bash-vs-Python decision (locked):** Bash. See Part 4.5 rationale.
- **Verification before commit:**
  - `chmod +x scripts/test-detect.sh` and `bash scripts/test-detect.sh`
    exits 0 with all 8 functions passing.
  - `bash -n scripts/test-detect.sh` parses cleanly.
  - File header documents the runner's purpose, source dependency, and
    expected exit codes.
  - No fixture residue under `/tmp/phase-4-fixtures/detect-tests/`
    after run (each test cleans up).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-14**.

---

### C-V10-15 — `feat:` Phase 4 verification harness (deferred Gate E3 evidence + migration smoke + detect.sh test results)

- **Message:** `docs: v10 — Phase 4 verification evidence (fixtures, cross-surface, manual mode, migration script, detect.sh tests)`
- **Prefix:** `docs:` (project-lead-resolved per OQ-V10-3; the file is documentation-shaped even though it adds a new artifact).
- **Files touched (1 new):**
  - `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (NEW) — captures the three deferred Gate E3 smoke tests, the migration script smoke (Part 4.4), and the detect.sh test runner output (Part 4.5). Short structured notes file. No fixture content committed (per V10-PHASE-3B-PLAN-v2 §5 — fixtures live outside the repo on `/tmp/phase-3b-fixtures/` and `/tmp/phase-4-fixtures/`).
- **Expected diff scope:** ~150–300 lines added in the new notes file (five sections: 4.1 fixture, 4.2 cross-surface, 4.3 manual-mode, 4.4 migration smoke, 4.5 detect.sh test results).
- **Findings closed:** None numbered. Closes Gate E3 deferred items 6 (fixture evidence), 7 (cross-surface checks), 8 (Category-C Manual mode check) per V10-PHASE-3B-PLAN-v2 Part 7. Also closes Gate F criterion 7 (verification file exists with all five sections).
- **What the harness records (per Part 4 of THIS plan):**
  - Section 4.1 fixture evidence: per-fixture name, surface used, command outputs, pass/fail, deviations.
  - Section 4.2 cross-surface: Codex CLI / Gemini CLI / Desktop Commander runs (or implementer-flag-back marking surfaces unavailable).
  - Section 4.3 manual-mode: Claude Web paste evidence + reply transcript.
  - Section 4.4 migration script smoke: fixture v9.3 project, `migrate-v9-to-v10.sh` stdout, post-migration `git diff --stat`, verification checklist outcome.
  - Section 4.5 detect.sh test results: `bash scripts/test-detect.sh` output verbatim; pass/fail count.
- **Dependency:** C-V10-14 (`scripts/test-detect.sh` must exist before its output can be captured here).
- **Verification before commit:**
  - All five sections present (4.1, 4.2, 4.3, 4.4, 4.5).
  - Any unavailable-surface entry references a Part 8 flag-back row (no silent deferral).
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-15**. **This is the gate where the project lead decides whether unavailable surfaces force a v10.0 hold or are deferred to v10.1.** See Part 8 flag-back F-B.

---

### C-V10-16 — `docs:` CHANGELOG.md v10.0 entry (S-01)

- **Message:** `docs: v10 — CHANGELOG.md v10.0 entry`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `CHANGELOG.md`
- **Expected diff scope:** ~60–100 lines added at the top of the CHANGELOG (above the v9 entry). Section structure mirrors v9.0 / v9.3 entries.
- **Content (per V10-IMPLEMENTATION-PLAN.md §6.8 S-01, augmented for Phase 3-B + Phase 4):**
  - **BD-044** init-project.sh + QUICKSTART three-path router + SETUP-NEW + SETUP-EXISTING + migration-guide naming convention.
  - **BD-045** capabilities pattern in trinity + 3 skills + auditor trio.
  - **BD-046** (a) custom agent/skill support (x- prefix); (b) prompt reorg (`docs/pack/prompts/` directory; 10 per-agent files + PROMPT-AUTHORING.md); (c) migration v9.3 → v10.0 with `migrate-v9-to-v10.sh` + merge helpers + MIGRATION-v9-to-v10.md; (d) capability addition via `add-capability.sh` + Procedure 6.
  - **BD-047** PM chat kickoff auto-discovery and install-check (Procedure 7 in METHODOLOGY.md, pm-chat.md Variant: kickoff slim with continuation pointer, SETUP-NEW.md § Manual fallback for non-shell surfaces).
  - **validate-pack.py** Checks 6/7/8/9 added.
  - **Deleted:** `supporting-docs/PROMPT-TEMPLATES.md`.
  - **Phase 4 audit-finding resolution:** AF-001 ship-blocker fix; trinity drift corrections; version-string refresh; banner additions to maintenance-docs.
- **Findings closed:** S-01 of ship sequence.
- **Verification before commit:**
  - `head -5 CHANGELOG.md` shows v10 entry above v9.
  - `grep -nE 'BD-04[4-7]' CHANGELOG.md | head -10` shows all four BD items in the new section.
  - `python3 scripts/validate-pack.py` exits 0.
- **Approval gate:** **G-V10-16**.

---

### C-V10-17 — `docs:` README.md v10.0 version-table row + V10-PREDESIGN supersession (S-02)

- **Message:** `docs: v10 — README v10.0 version table row; V10-PREDESIGN supersession`
- **Prefix:** `docs:`
- **Files touched (2):**
  - `README.md`
  - `maintenance-docs/V10-PREDESIGN.md` (supersession banner if not already present; per V10-IMPLEMENTATION-PLAN §6.8 S-02 — verify on inspection)
- **Expected diff scope:** ~3–6 lines.
  - README.md version table: add `| v10.0 | <ship date> | BD-044 init-project.sh + QUICKSTART router; BD-045 capabilities pattern; BD-046 custom agent/skill support + prompt reorg + migration + capability addition; BD-047 PM chat kickoff auto-discovery |` row.
  - V10-PREDESIGN.md: confirm SUPERSEDED banner exists (Audit-2 noted lines 4–10 already carry the banner — implementer verifies). If missing, add it; if present, no edit.
- **Findings closed:** S-02 of ship sequence.
- **Verification before commit:**
  - `grep -n '^| v10.0' README.md` returns 1 match.
  - `head -12 maintenance-docs/V10-PREDESIGN.md` shows SUPERSEDED banner.
  - `python3 scripts/validate-pack.py` exits 0. Check 4 must tolerate dev-branch state (v10.0 tag not yet created at this commit).
- **Approval gate:** **G-V10-17**.

---

### C-V10-18 — `docs:` BACKLOG.md S-03 sweep (Resolve BD-044/045/046; v10-scoped item disposition)

- **Message:** `docs: v10 — BACKLOG BD-044/045/046 Resolved at v10.0; sweep v10-scoped items`
- **Prefix:** `docs:`
- **Files touched (1):**
  - `BACKLOG.md`
- **Expected diff scope:** ~10–20 lines changed.
  - BD-044: Status `Open` → `Resolved`. Resolution line: `2026-04-DD — landed at v10.0 tag (see CHANGELOG.md).`
  - BD-045: Status `Open` → `Resolved`. Same resolution date.
  - BD-046: Status `Unblocked` → `Resolved`. Add row-83 fourth bullet to description per V10-IMPLEMENTATION-PLAN §6.8 S-03: *"(d) adding pack-supported capabilities to existing projects (mechanism: `scripts/add-capability.sh` + METHODOLOGY.md Procedure 6)."* Resolution line.
  - BD-047: already Resolved (commit 604895c). Confirm Resolution line points at the right commits; no edit needed unless the line is stale.
  - BD-048: stays Open (deferred to v10.1). Confirm Blockers line accurate.
  - **Sweep:** implementer greps `BACKLOG.md` for any other v10-scoped Open item that should resolve at tag time. None expected. If any surface, **flag-back F-C** (Part 8).
- **Findings closed:** S-03 of ship sequence.
- **Verification before commit:**
  - `grep -nE '^\*\*BD-04[4-6]' BACKLOG.md` shows three items.
  - For each, `grep -A30 '^\*\*BD-044' BACKLOG.md | grep -E 'Status|Resolved'` shows `Status: Resolved` and a non-empty Resolved line.
  - `python3 scripts/validate-pack.py` exits 0 (Check 3 — no TD-TBD).
- **Approval gate:** **G-V10-18**.

---

### Commit-sequence summary table

| # | ID | Prefix | Files (count) | Findings closed | Approval gate |
|---|---|---|---|---|---|
| 1 | C-V10-01 | `fix:` | 1 | AF-001 | G-V10-01 |
| 2 | C-V10-02 | `docs:` | 1 | AF-003, AF-004 | G-V10-02 |
| 3 | C-V10-03 | `docs:` | 12 | AF-005, AF-006, AF-010, AF-014, AF-015, AF-016, AF-017, AF-018 | G-V10-03 |
| 4 | C-V10-04 | `docs:` | 1 | AF-007 | G-V10-04 |
| 5 | C-V10-05 | `docs:` | 1 | AF-009 | G-V10-05 |
| 6 | C-V10-06 | `docs:` | 1 | AF-011 (D1) | G-V10-06 |
| 7 | C-V10-07 | `docs:` | 2 | AF-012 | G-V10-07 |
| 8 | C-V10-08 | `docs:` | 1 | AF-013 | G-V10-08 |
| 9 | C-V10-09 | `docs:` | 2 | AF-002, AF-008, AF-019 | G-V10-09 |
| 10 | C-V10-10 | `docs:` | 1 | AF-020 | G-V10-10 |
| 11 | C-V10-11 | `docs:` | 1 | AF-021, AF-022, AF-023, AF-024, AF-025, AF-026, AF-028, AF-029, AF-030, AF-031, AF-032 | G-V10-11 |
| 12 | C-V10-12 | `docs:` | 1 | D8 | G-V10-12 |
| 13 | C-V10-13 | `docs:` | 2–3 | D2, AF-033 | G-V10-13 |
| 14 | C-V10-14 | `feat:` | 1 (new) | Phase 4 deliverable: detect.sh test harness (V10-IMPLEMENTATION-PLAN B5) | G-V10-14 |
| 15 | C-V10-15 | `docs:` | 1 (new) | Gate E3 deferred items 6/7/8 + migration script smoke + detect.sh test results | G-V10-15 |
| 16 | C-V10-16 | `docs:` | 1 | S-01 | G-V10-16 |
| 17 | C-V10-17 | `docs:` | 2 | S-02 | G-V10-17 |
| 18 | C-V10-18 | `docs:` | 1 | S-03 | G-V10-18 |

**AF-027:** No commit. Documented as accepted plan-reality drift in Part 9 risk register (R-V10-1) and in the AF-027 row of §2.2.

---

## Part 4 — Phase 4 verification specification

Three smoke tests deferred from Gate E3 because they cannot run against
the pack repo itself. All three are exercised before Gate F. Evidence
is captured in `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (the
artifact created in C-V10-15).

### 4.1 Fixture evidence

**Reference spec.** V10-PHASE-3B-PLAN-v2 Part 7 criterion 6 (unchanged
from v1 plan Part 5). Six fixtures, each constructed under
`/tmp/phase-3b-fixtures/<name>/` outside the pack working tree.

**Surfaces required.** At least one Bash-capable surface for every
fixture (Claude Code CLI is the canonical choice). Implementer's local
Mac with Claude Code CLI installed satisfies this.

**Fixtures (six).**

| # | Fixture name | What it exercises |
|---|---|---|
| F1 | `apple-spm-single-scheme` | Single SPM scheme; happy-path Form R + I + E + M |
| F2 | `apple-multi-scheme` | Ambiguous scheme list; Form R presents choices |
| F3 | `apple-no-simulator` | `simctl list devices available` returns empty; Form R reports no destination; G7-discovery declines |
| F4 | `apple-non-spm-layout` | Non-SPM layout; Form M skips on absence of expected SPM markers |
| F5 | `python-grpc-server` | Python + gRPC; Form I includes `grpcio-tools` |
| F6 | `python-only` | Python without gRPC; Form I skips proto deps |

**Construction method.** V10-PHASE-3B-PLAN-v2 §5.2 (manual ad-hoc; see
v1 plan Part 5 §5.2 inherited verbatim).

**What gets committed.** Nothing fixture-side. Evidence captured in the
verification notes file:
- Fixture name + construction date.
- Surface (Claude Code CLI version).
- Form R output (paste verbatim).
- Form I / E / M decisions and outputs.
- Pass/fail with notes.

**Expected output per fixture.** Form R reports correct scheme/destination
discovery (or correctly reports the absence). Form I lists the missing
brew tools without proposing already-installed ones. Form E shows the
exact diff that would land in `validate-swift.sh` / `test-swift.sh` /
`format-swift.sh` / `.claude/settings.json`. Form M companion-files
batch defaults to `skip`.

### 4.2 Cross-surface checks

**Reference spec.** V10-PHASE-3B-DESIGN-v2 Part 11 surface matrix;
V10-PHASE-3B-PLAN.md Part 9 (Deferred to Phase 4 D1/D2/D3).

**Surfaces.**

| # | Surface | Fixture used | Expected behavior |
|---|---|---|---|
| C1 | **Codex CLI** | `apple-spm-single-scheme` | Same Procedure 7 path executes; brew-install escalation per design Part 3 §3.2 |
| C2 | **Gemini CLI** | `apple-spm-single-scheme` | Same Procedure 7 path executes; native subagent context honored |
| C3 | **Desktop Commander** (Claude Desktop + filesystem MCP) | `apple-spm-single-scheme` | Procedure 7 executes via Desktop Commander tool calls; manual-mode pointer NOT emitted |

**What gets committed.** Same as 4.1 — evidence in
`V10-PHASE-4-VERIFICATION.md`. Per surface, record:
- Surface name + version.
- Fixture name.
- Form R/I/E/M outputs.
- Pass/fail.

**Unavailable-surface protocol.** If the implementer's environment lacks
a surface (e.g., no Codex CLI installed), the verification file
records `unavailable — surface not present in implementer environment`
and refers to **flag-back F-B** (Part 8). The project lead decides
whether the unavailable surface forces a v10.0 hold or is accepted as
v10.1 follow-up. **Do not silently defer.**

### 4.3 Claude Web manual-mode smoke

**Reference spec.** V10-PHASE-3B-PLAN-v2 Part 7 criterion 8
("Category-C Manual mode check"). V10-PHASE-3B-DESIGN-v2 Part 3 row
15 specifies the pointer-only shape.

**Surface.** Claude Web (no Desktop Commander, no filesystem MCP).

**Procedure.**
1. Open a new Claude Web chat.
2. Paste the kickoff variant from `project-template/docs/pack/prompts/pm-chat.md` exactly as it appears (post-Phase-3-B slim).
3. Reply `manual` to the surface-declaration prompt.
4. Verify: no tool call fires; assistant emits ONLY the 4-line pointer naming SETUP-NEW.md § Manual fallback sub-sections 5.A–5.D; no inline command summary.

**Expected output.** Exactly the pointer specified by V10-PHASE-3B-PLAN-v2
§3.3 wording. Implementer pastes the assistant's reply into the
verification file under §4.3 evidence block.

**What gets committed.** The verbatim assistant reply (or a screenshot
transcribed to text) in `V10-PHASE-4-VERIFICATION.md`.

**Failure modes.**
- Reply contains a tool call → fail; pm-chat.md kickoff variant has a defect (re-open Phase 3-B as a `fix:` retrofit).
- Reply contains an inline command summary → fail; pointer wording is wrong.
- Reply contains anything other than the 4-line pointer → fail; review against §3.3 wording.

### 4.4 Migration script smoke (`scripts/migrate-v9-to-v10.sh`)

**Reference spec.** V10-DESIGN.md Part 6 (migration design); BD-046 c
(`migrate-v9-to-v10.sh` + Procedure 5-R). The script does NOT have a
`--dry-run` mode; smoke testing means actually executing it against a
v9.3 fixture project on disk.

**Why this is a Phase 4 obligation.** v10.0 is a major version; the
v9.3 → v10.0 migration is the primary path for existing-v9 projects.
The script has not been smoke-tested in the v10 cycle (V10-AUDIT-REPORT
explicitly excluded execution of `migrate-v9-to-v10.sh` from main-audit
scope). Shipping v10.0 without a recorded successful migration run
ships an untested upgrade path.

**Surfaces required.** Bash-capable surface with the v10 pack repo
checked out (implementer's local Mac satisfies this).

**Procedure.**

1. Create a v9.3 fixture project under `/tmp/phase-4-fixtures/v9-project/`:
   - `git clone --branch v9.3 https://github.com/DShaneNYC/dhs-ai-agent-config-pack /tmp/v9-pack-source`
   - Construct a minimal v9.3 project that uses the v9 pack: copy
     `project-template/` contents, fill placeholders, add a trivial
     `Package.swift` and one Swift source file so the project is real
     enough that migration touches representative content.
   - `cd /tmp/phase-4-fixtures/v9-project && git init && git add -A && git commit -m "v9.3 baseline"`
2. Run migration:
   - `export PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev`
   - `cd /tmp/phase-4-fixtures/v9-project`
   - `"$PACK/scripts/migrate-v9-to-v10.sh" .`
3. Capture the script's stdout (paste-ready PM-chat prompt per
   V10-DESIGN.md Part 6 §6.10) and full stderr.
4. Verify post-migration state per V10-DESIGN.md Part 6 §6.10 / Procedure 5-R:
   - `git diff --stat HEAD~0` shows expected file moves and additions.
   - `python3 "$PACK/scripts/validate-pack.py"` against the migrated
     project structure where applicable (validate-pack.py is a
     pack-repo-only check, not a project-level check; if it does not
     apply at the project level, skip with note).
   - Trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) carry the
     v10 layout (`docs/pack/` paths, Active-skills line, capabilities
     pattern, etc.).
   - `docs/pack/METHODOLOGY.md` exists with Procedure 7 present.
   - `scripts/init-project.sh` and friends are present (or absent —
     migration semantics: existing-project install path; init-project.sh
     belongs to the new-project path).
   - No reference to `validate.sh` / `test.sh` / `format.sh` in the
     project's SETUP-derived files (parity with AF-001 fix).

**What gets committed.** Evidence in `V10-PHASE-4-VERIFICATION.md`
section 4.4 — fixture construction commands, migration script stdout
(paste the prompt verbatim), `git diff --stat` output, verification
checklist results.

**Expected output.** Migration script exits 0; post-migration project
matches v10 layout per V10-DESIGN.md Part 6 §6.10; Procedure 5-R
prompt is well-formed and references the correct files.

**Failure modes.**
- Script exits non-zero → defect in `migrate-v9-to-v10.sh`; **flag-back
  F-G** (Part 8). Likely a v10.0 hold (the script is the primary v9 → v10
  upgrade path).
- Post-migration trinity has v9 placeholders left → defect; flag-back F-G.
- Procedure 5-R prompt references files that do not exist → defect; flag-back F-G.
- Procedure 5-R prompt references Procedure 7 only as a placeholder /
  not at all → may be acceptable (Procedure 7 is BD-047, post-BD-046);
  evaluate per project-lead judgment.

### 4.5 detect.sh unit tests (CI infrastructure)

**Reference spec.** V10-IMPLEMENTATION-PLAN.md line 45 ("`detect.sh`
unit tests added to Phase 4 (B5). Every detection function unit-tested.").
This is a Phase 4 deliverable that was scoped in the implementation
plan but never built during Phase 3-AC or 3-B.

**Artifact produced.** `scripts/test-detect.sh` (NEW). Pure-bash test
runner. Sources `scripts/lib/detect.sh`, exercises each function with
known inputs/expected outputs, reports pass/fail.

**Functions to test** (per validate-pack.py Check 9 enumeration —
"all 7 required functions defined" plus the `detect_installed_capabilities`
extension added in C-046-ADD-01):

| # | Function | Test approach |
|---|---|---|
| 1 | `detect_pack_path` | Set up fixture with known pack location; call function; assert returned path. |
| 2 | `detect_project_root` | Fixture with marker file; call; assert root detection. |
| 3 | `detect_languages` | Fixture with `Package.swift` / `pyproject.toml` markers; assert detected languages. |
| 4 | `detect_protocols` | Fixture with `proto/` dir; assert proto detection. |
| 5 | `detect_platform_targets` | Fixture with `[PLATFORM_TARGETS]` filled; assert returned values. |
| 6 | `detect_existing_pack_install` | Fixture with `.claude/agents/` present; assert install detected. |
| 7 | `detect_pack_version` | Fixture with version marker; assert version returned. |
| 8 | `detect_installed_capabilities` | Fixture with `[PLATFORM_TARGETS]=iOS` + `proto/`; assert detected list `iOS, gRPC`. |

**Test fixtures live under** `/tmp/phase-4-fixtures/detect-tests/`
constructed inside the test runner itself (one fixture per function,
torn down after each test). No fixture content committed.

**Test runner shape (illustrative, not prescriptive — implementer
finalizes).**

```bash
#!/usr/bin/env bash
# scripts/test-detect.sh — unit tests for scripts/lib/detect.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/detect.sh"

passes=0
fails=0
fail() { echo "FAIL: $1"; fails=$((fails+1)); }
pass() { echo "PASS: $1"; passes=$((passes+1)); }

# Per-function test helpers below. Fixture construction inline per test.
# ...

echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```

**What gets committed in C-V10-14.** The new `scripts/test-detect.sh`
file (executable; ~150–250 lines).

**What gets committed in `V10-PHASE-4-VERIFICATION.md` (C-V10-15
section 4.5).** The output of running `bash scripts/test-detect.sh`
verbatim. Pass/fail count.

**Bash vs. Python decision (locked).** Bash is the right tool for
testing bash filesystem-detection functions; a Python wrapper would
add a subprocess layer with no test-quality benefit. Documented choice;
do NOT silently switch to Python at execution time. If a function
genuinely cannot be tested in bash, **flag-back F-H** (Part 8).

**Expected output.** All 8 functions pass; runner exits 0.

**Failure modes.**
- A function fails its test → defect in `scripts/lib/detect.sh`;
  **flag-back F-G** (treat as a v10.0 issue; either fix detect.sh or
  fix the test if the test was wrong).
- `scripts/lib/detect.sh` cannot be sourced → defect; flag-back F-G.

---

## Part 5 — Gate F entry criteria

Gate F is the mandatory full structural-validation gate before ship.
Reuses the Gate E / E2 / E3 pattern; criteria are inherited and
augmented from V10-IMPLEMENTATION-PLAN.md §6.7.

**All criteria are mandatory. No shortcuts.**

| # | Criterion | How verified |
|---|---|---|
| 1 | All 31 audit findings AF-001..AF-033 closed per Part 2 resolution table | Implementer walks Part 2 row-by-row; each row's "Expected diff summary" matches the landed diff in its target commit. AF-027 alone is "no action — accepted." |
| 2 | C-V10-01 .. C-V10-15 all landed | `git log --oneline v10-dev` shows exactly 15 commits between `604895c` and the Gate-F commit, in the order specified by Part 3. (Ship commits C-V10-16..18 land AFTER Gate F.) |
| 3 | All six §8.6 sweeps S1–S6 produce expected results | Reuse of V10-IMPLEMENTATION-PLAN §8 sweep schedule. Implementer runs each grep command and compares output to expected result. Sweeps S1–S6 run: B7 hard requirement. |
| 4 | All Phase-3-B sweeps S3B-1..S3B-6 produce expected results (with the AF-019 sanctioned-residuals tightening from C-V10-09) | Implementer reruns each sweep per V10-PHASE-3B-PLAN-v2 §6 against the post-Phase-4 tree. |
| 5 | Trinity integrity audit clean | Manual side-by-side read of `project-template/{CLAUDE,AGENTS,GEMINI}.md` for the six section rows in V10-AUDIT-REPORT.md §5.1 table. Plus pack-repo trinity (§5.2). Plus validate-pack.py Check 7. |
| 6 | `detect.sh` unit-test harness passes all eight function tests | `bash scripts/test-detect.sh` (built in C-V10-14) exits 0 with all 8 functions passing. Output captured in `V10-PHASE-4-VERIFICATION.md` §4.5 (C-V10-15). |
| 7 | Deferred Gate E3 smoke tests + migration smoke + detect.sh tests resolved per Part 4 | Verification file `V10-PHASE-4-VERIFICATION.md` (C-V10-15) exists and contains all five sections (4.1 fixture, 4.2 cross-surface, 4.3 manual-mode, 4.4 migration script smoke, 4.5 detect.sh test results); every entry is either `pass` or has a project-lead-acknowledged Part 8 flag-back row. |
| 8 | No open `fix:` work | `git status` clean on v10-dev; no unstaged changes; no `fix:`-pending notes in the plan or audit reports. |
| 9 | `validate-pack.py` exits 0 | `python3 scripts/validate-pack.py` from v10-dev tip. |
| 10 | GitHub Actions `Validate Pack` workflow green on v10-dev tip | `gh run list --branch v10-dev --workflow validate-pack.yml --limit 1` shows `success`. |
| 11 | README.md / CHANGELOG.md / BACKLOG.md updates landed | C-V10-16, C-V10-17, C-V10-18 all in git log. |
| 12 | No unintended file touches across Phase 4 | `git diff 604895c..HEAD --stat` lists ONLY the files enumerated in Part 3 commits. No surprise touches. |

**Gate F approval.** Project lead signs off explicitly: *"Gate F passed
— ready to ship v10.0."* Only then does Part 6 ship sequence begin.

**If a criterion fails:** open a `fix:` commit, re-run the affected
verification, and re-request Gate F approval. No partial pass; no
"will fix in v10.1" deferral allowed at this gate (per project-lead
directive).

---

## Part 6 — Ship sequence (S-01 .. S-03 + merge + tag)

Ship sequence runs only after Gate F approval. Three commits, then
merge, then tags, then push.

### 6.1 S-01 — CHANGELOG.md v10.0 entry

Already specified as **C-V10-16**. See Part 3.

### 6.2 S-02 — README.md version table v10.0 row + V10-PREDESIGN supersession

Already specified as **C-V10-17**. See Part 3.

### 6.3 S-03 — BACKLOG.md sweep (Resolve BD-044/045/046)

Already specified as **C-V10-18**. See Part 3.

### 6.4 Merge v10-dev → main

Per `CLAUDE.md` versioning convention and V10-IMPLEMENTATION-PLAN §6.8:
**no-ff merge** to preserve the v10-dev branch shape in `main`'s
history. (Squash is rejected: it would lose the per-BD commit trace
that makes Phase 3-B's three commits visible. Rebase is rejected:
v10-dev's history is signed/approved per-commit and rewriting it
breaks that audit trail.)

**Flag-back F-D** (Part 8): if the project lead prefers squash or
rebase, implementer pauses for explicit confirmation before merge.

```bash
# From the main worktree (NOT v10-dev)
cd /Users/david/Developer/dhs-ai-agent-config-pack
git fetch origin
git checkout main
git pull --ff-only

# Confirm v10-dev is ready (run from v10-dev worktree)
cd /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
python3 scripts/validate-pack.py          # must exit 0
git log --oneline -30                     # sanity

# Merge from main worktree
cd /Users/david/Developer/dhs-ai-agent-config-pack
git merge --no-ff v10-dev -m "Merge v10-dev into main — v10.0"
```

### 6.5 Tag v10.0 + move bare `v10` major tag

Per `CLAUDE.md` "Versioning convention" and "Tag move sequence":
delete local + remote, recreate at the new commit, push.

```bash
# Annotated tag for v10.0
git tag -a v10.0 -m "v10.0"

# Move bare `v10` major tag from v9.3's commit to the new v10.0 commit
git tag -d v10 2>/dev/null || true
git push origin :refs/tags/v10 2>/dev/null || true
git tag v10 v10.0
```

### 6.6 Push main + tags

```bash
git push origin main
git push origin v10.0
git push origin v10
```

After push, GitHub Actions runs `validate-pack.yml` on `main`. If it
fails, the ship is broken — open a `fix:` commit on main (NOT v10-dev,
which is already merged) and re-push. Project lead is informed
immediately.

### 6.7 Post-ship hygiene (optional, post-tag)

- Retire the v10-dev worktree if not retained for v10.x patches:
  `git worktree remove /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev`
- Update local main branch in any other worktrees: `git pull --ff-only`
- Confirm GitHub release page reflects the new tag (manual UI check or
  `gh release view v10.0`).

### 6.8 Ship-approval gate

Final approval is **explicit and verbal/typed.** The project lead
states: *"Ship v10.0."* Only then do steps 6.4 → 6.6 execute.

---

## Part 7 — Per-commit verification checklist (uniform)

Applied uniformly before every commit C-V10-01..18. The implementer
runs this list, captures the output, and presents it with the
commit-approval request.

```
[ ] git status                          — staged files match the commit's "Files touched" list
[ ] git diff --stat                     — line counts within Expected-diff-scope estimate
[ ] python3 scripts/validate-pack.py    — exits 0
[ ] Commit-specific Verification line   — every grep / diff / count from the commit's Verification block run with expected output
[ ] No unintended file touches          — git diff --name-only shows ONLY the listed files
[ ] Trinity rule (when applicable)      — TRIO commits edit all three files OR justified in commit-body comment
[ ] Finding-closure check               — grep verifies the AF-NNN concern is removed (or visual inspection where grep is impractical)
[ ] Approval gate G-V10-NN              — explicit project-lead "approved" before `git commit`
```

**Post-commit:**

```
[ ] git log --oneline -1                — commit message matches plan spec
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm post-commit)
[ ] gh run watch (when triggered)       — Validate Pack workflow green on v10-dev branch
```

**If validate-pack.py fails post-commit:** the commit is BAD and must
be rolled back BEFORE the next commit lands. Per `CLAUDE.md`, the pack
must remain in a working state at every intermediate commit. Roll-back
options:
- `git reset --soft HEAD~1` then fix and recommit (preferred — preserves staging).
- `git revert HEAD` if the commit was already pushed (not yet pushed at this stage; reset is fine).

---

## Part 8 — Implementer flag-backs

Conditions where the implementer pauses for project-lead decision.
Numbered F-A..F-E. Implementer does NOT proceed past a flag-back
without explicit resolution.

### F-A — `refactor:` vs. `docs:` for C-V10-13 [RESOLVED — `docs:` chosen]

Resolved by project lead (OQ-V10-1): C-V10-13 uses `docs:` prefix to
stay within `CLAUDE.md`'s enumerated set (`feat:` / `fix:` / `docs:`).
No flag-back required at execution time. Retained here for traceability.

### F-B — Cross-surface unavailability for Part 4 verification

If the implementer's environment lacks any of Codex CLI, Gemini CLI,
or Desktop Commander:

**Pause point:** during Part 4.2 cross-surface check.
**Decision needed:** is the unavailable surface a v10.0 hold (acquire
the surface first), or is it an accepted v10.1 follow-up (record in
verification file with explicit project-lead acknowledgment)?
**Default if unclear:** treat as v10.0 hold; surface acquisition is
typically same-day for any CLI tool.

### F-C — Unexpected v10-scoped Open BACKLOG items at S-03

If the BACKLOG.md sweep at C-V10-18 surfaces an Open item beyond
BD-044/045/046/047/048 that is plausibly v10-scoped:

**Pause point:** during C-V10-18 staging.
**Decision needed:** resolve at v10.0, defer to v10.1, or close as
out-of-scope?
**Default if unclear:** flag-back; do NOT make this call autonomously.

### F-D — Merge style at 6.4

Default is `git merge --no-ff`. If project lead prefers squash or
rebase:

**Pause point:** before 6.4 merge command.
**Decision needed:** merge style.
**Default if unclear:** `--no-ff` (preserves v10-dev branch shape and
per-BD commit trace).

### F-E — v10.1 candidate items surfacing during Phase 4 execution

If during execution the implementer identifies a defect or improvement
that is NOT in the audit reports and is NOT a Phase-4 scope item
(e.g., a typo in METHODOLOGY.md outside the AF-009 / AF-010 / AF-020
edits, or a behavioral defect in a fixture run that traces to pack
content):

**Pause point:** at discovery.
**Decision needed:** v10.0 fix-it-now, v10.1 BACKLOG file, or ignore?
**Default if unclear:** flag-back; do NOT silently expand Phase 4
scope.

### F-F — validate-pack.py disagreement with archive-move semantics

C-V10-13 moves V9-DESIGN.md to `archive/`. If `validate-pack.py`
encodes a hard expectation that V9-DESIGN.md exists at its current
path (e.g., a Check that lists expected maintenance-docs), the move
breaks CI. Implementer must read `scripts/validate-pack.py` for any
such expectation BEFORE starting C-V10-13.

**Pause point:** before staging C-V10-13.
**Decision needed:** if validate-pack.py needs an update for the new
path, does that update (a) fold into C-V10-13 (changes scope to
include `scripts/validate-pack.py`), or (b) land as a prior commit
C-V10-12.5?
**Default if unclear:** fold into C-V10-13; the commit message gains
"+ validate-pack.py path update" and Files-touched list extends.

### F-G — Migration script smoke or detect.sh test failure

If `migrate-v9-to-v10.sh` exits non-zero or produces a defective
post-migration tree (Part 4.4), OR a `detect.sh` function fails its
unit test (Part 4.5):

**Pause point:** during C-V10-15 evidence collection (immediately
after the failing run).
**Decision needed:** is this a v10.0 hold (fix `migrate-v9-to-v10.sh`
or `scripts/lib/detect.sh` before tag), or accepted with project-lead
acknowledgment?
**Default if unclear:** v10.0 hold. Both scripts are core infrastructure
and shipping with known defects breaks downstream consumers.

### F-H — `detect.sh` function genuinely cannot be tested in bash

If during C-V10-14 implementation the implementer finds a `detect.sh`
function whose behavior cannot be expressed as a bash test (e.g., it
requires complex mocking that bash can't reasonably provide):

**Pause point:** before completing the test runner.
**Decision needed:** switch the affected test (or whole runner) to
Python? Refactor `detect.sh` to be more testable? Accept reduced
coverage with documented rationale?
**Default if unclear:** flag-back. Project lead's directive ("don't
silently accept a worse outcome with bash") makes this an explicit
decision point, not an implementer choice.

---

## Part 9 — Risk register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| **R-V10-1** | AF-027 historical commit message cannot be retrofitted | Certain | Low (cosmetic) | Documented as accepted plan-reality drift in §2.2 AF-027 row and acknowledged in CHANGELOG.md (C-V10-15) if project lead chooses to mention it. No action required. |
| **R-V10-2** | Cross-surface check (Part 4.2) finds a Procedure 7 defect on Codex / Gemini / Desktop Commander | Low | High (re-opens Phase 3-B as `fix:` retrofit; potentially blocks v10.0 ship) | Run cross-surface checks early in Phase 4 — before C-V10-16 ship-prep starts — so any defect is discovered with maximum recovery time. Per Part 3 ordering, C-V10-15 runs immediately before ship-prep. |
| **R-V10-3** | Claude Web manual-mode smoke (Part 4.3) fails because pm-chat.md kickoff variant has a wording defect | Low | Medium (Phase-3-B `fix:` retrofit) | Same mitigation as R-V10-2. |
| **R-V10-4** | Field smoke test surfaces a defect during ship-prep window | Medium | High (delays ship) | Run all Part 4 verifications before C-V10-16. Treat the verification file (C-V10-15) as a hard gate in Part 5 criterion 7. |
| **R-V10-5** | validate-pack.py breaks at the V9-DESIGN.md archive move | Medium | Medium (CI red on v10-dev) | F-F flag-back: implementer reads validate-pack.py for hard path expectations BEFORE C-V10-13. If found, fold the update into C-V10-13. |
| **R-V10-6** | Trinity rule violation introduced by version-string batch C-V10-03 | Low | Medium (Check 7 fails) | Verification step in C-V10-03 explicitly diff-checks all three trinity files post-edit; `validate-pack.py` Check 7 is the safety net. |
| **R-V10-7** | Stale cross-references missed by Part 4 / Gate F sweeps | Low | Low–Medium | All six §8.6 sweeps run at Gate F per criterion 3 (mandatory; no shortcuts). Plus the Phase-3-B sweeps S3B-1..S3B-6 per criterion 4. |
| **R-V10-8** | Bare `v10` major tag fails to move | Low | Medium (downstream consumers pinned to `v10` see v9.3 instead of v10.0) | Tag-move sequence (delete local, delete remote, recreate, push) is canonical per `CLAUDE.md`; commands in §6.5 are copy-paste-safe. Verify post-push: `git ls-remote --tags origin v10` shows the v10.0 commit. |
| **R-V10-9** | Phase 4 implementer scope-creep introduces a v10.1 item silently | Medium | Medium | Flag-back F-E governs this. Implementer must pause at any out-of-Phase-4 discovery. |
| **R-V10-10** | A new BD item (BD-049+) is needed for a Phase 4 finding | Low | Low (BD-NNN numbering rule) | Per `CLAUDE.md`, BD numbers are assigned by reading BACKLOG.md and incrementing. Currently BD-048 is the highest; BD-049 is the next available. PM chat handles this if it surfaces. |
| **R-V10-11** | `migrate-v9-to-v10.sh` smoke (Part 4.4) reveals a script defect | Medium | High (v10.0 hold; the script is the primary v9 → v10 upgrade path and has not been smoke-tested in the v10 cycle) | Run smoke early in Phase 4 verification (during C-V10-15 evidence capture). F-G flag-back covers the decision. Script is small (~17 KB) and any defect is likely a focused fix. |
| **R-V10-12** | `scripts/test-detect.sh` (C-V10-14) surfaces a `detect.sh` defect | Low | Medium (v10.0 hold; `detect.sh` is sourced by init-project.sh, add-capability.sh, migrate-v9-to-v10.sh — its correctness affects all three) | Tests run before C-V10-15. Any failing function is fixed before Gate F. F-G flag-back covers the decision. |

---

## Part 10 — Open questions for the project lead

Judgment calls only the project lead can resolve. None of these block
plan approval; they will be resolved at execution time.

1. **OQ-V10-1 — `refactor:` vs. `docs:` for C-V10-13.** **Resolved:
   `docs:`** (project lead, 2026-04-24). See flag-back F-A.

2. **OQ-V10-2 — CHANGELOG.md v10.0 entry voice for Phase 4 audit-finding
   resolution.** **Resolved: released-feature style with summary line**
   (project lead, 2026-04-24). C-V10-16's CHANGELOG entry lists user-
   visible changes (BD-044/045/046/047) plus a one-line summary of the
   Phase 4 audit-finding resolutions; AF-NNN IDs are NOT enumerated.

3. **OQ-V10-3 — V10-PHASE-4-VERIFICATION.md as `feat:` or `docs:`.**
   **Resolved: `docs:`** (project lead, 2026-04-24). C-V10-15 uses
   `docs:` prefix. The file is documentation-shaped even though it adds
   a new artifact.

4. **OQ-V10-4 — Bulk-commit option.** **Resolved: 18 separate commits**
   (project lead, 2026-04-24). Plan retains 18-commit shape (one
   approval gate per fix). The project lead's "all 31 must be done"
   directive aligns with one-finding-per-commit clarity, not bulk
   commits.

5. **OQ-V10-5 — Should AF-022 round-count annotation land?** **Resolved:
   yes** (project lead, 2026-04-24). AF-022 1-line annotation lands per
   project-lead's "all 31 findings resolved" directive.

6. **OQ-V10-6 — README.md Repository Layout section update at C-V10-13.**
   **Resolved: land README edit at C-V10-13** (project lead, 2026-04-24).
   README stays accurate at every intermediate commit; the Repository
   Layout edit is folded into the V9-DESIGN.md archive-move commit
   rather than deferred to S-02 (C-V10-17).

7. **OQ-V10-7 — v10.1 BACKLOG candidates from Phase 4.** None
   anticipated. Implementer may surface candidates via flag-back F-E.

---

*End of V10-PHASE-4-PLAN.md.*
