# V10-AUDIT-REPORT.md

*Created: 2026-04-24*
*Audit scope: v10-dev branch, tip commit `604895c` (BD-047 resolved, BD-048 filed)*
*Auditor: pack-reviewer (read-only)*
*Context: independent pre-Phase-4 audit of v10 docs. No file edits.*

---

## Part 1 — Status + scope

**What was audited**

- All 15 files in `maintenance-docs/` named in the prompt (V10-DESIGN,
  V10-IMPLEMENTATION-PLAN, V10-PHASE-3B-DESIGN / DESIGN-v2 / PLAN / PLAN-v2,
  V9-DESIGN, VERIFIED-NOTES, RECOMMENDATIONS, TOOL-COMPARISON).
- All 9 files in `supporting-docs/` (METHODOLOGY, SETUP-NEW, SETUP-EXISTING,
  MIGRATION-v9-to-v10, CLI-PM-SETUP, DEPENDENCIES, SETUP_TEMPLATE,
  AGENT_KICKOFF_TEMPLATE).
- Pack-product docs touched by Phase 3-B: `project-template/docs/pack/prompts/pm-chat.md`,
  `project-template/docs/pack/PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md`.
- Project-template trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`).
- Pack-repo trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`).
- Pack-repo meta: `README.md`, `BACKLOG.md`, `CHANGELOG.md`, `QUICKSTART.md`,
  `PACK-CHAT.md`, `PACK-AGENTS.md`.
- Supporting scripts and config for Procedure 7 targets: `project-template/scripts/*`
  (grep of `XCODE_SCHEME`), `scripts/validate-pack.py` shape (no deep logic audit).

**What was NOT audited**

- Skill SKILL.md files (30+ skills). Only their *references* from other docs were
  checked.
- Agent definition files under `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`
  (both pack-product and pack-repo). Out of scope.
- `.github/workflows/validate-pack.yml` internals (just confirmed it runs).
- Actual execution of `init-project.sh`, `add-capability.sh`, `migrate-v9-to-v10.sh`,
  or fixture-based test runs. This is Phase 4 activity.
- Pack-repo skills under `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`.
- Maintenance-docs not named in the prompt (`V10-DESIGN-PROCESS-PLAN.md`,
  `V9-AUDIT-REPORT.md`, `v10-working/`, `guides/`, `origins/`).

**Method.** Direct reads, cross-file greps for stale references (pack version
strings, script names, Procedure numbers, step numbers, BD numbers), trinity
section-by-section diffs, and plan-spec vs. landed-reality comparison for
Phase 3-B.

---

## Part 2 — Executive summary

**Findings by severity**

| Severity | Count |
|---|---:|
| Ship-blocker | **1** |
| Nice-to-fix (before Phase 4 planning benefits) | 8 |
| Note (defer / dismiss / informational) | 9 |
| **Total** | **18** |

**Readiness assessment for Phase 4: 2–3 fixes needed first.**

The v10 pack product is structurally coherent. BD-047 Phase 3-B landed cleanly;
all 12 BD-047 closure clauses have a concrete home in METHODOLOGY.md or
SETUP-NEW.md or pm-chat.md. Procedure 7 is well-integrated with the existing
Procedure 6 pattern; cross-tool parity is preserved; trinity rule is largely
intact.

One **ship-blocker** exists: SETUP-NEW.md § Manual fallback 5.A tells the
developer to edit the wrong script files — the wrapper `validate.sh` / `test.sh`
/ `format.sh`, which do not contain the `XCODE_SCHEME` variable — while
Procedure 7 §7.2.2 correctly edits the `-swift.sh` language-specific variants.
This is the exact parity failure that V10-PHASE-3B-PLAN-v2 Part 11 §11.1 was
written to prevent, and it slipped through.

Eight nice-to-fix items cluster around **version-string staleness** (several
v9 and one v8 reference in shipped templates) and **V10-IMPLEMENTATION-PLAN.md
not yet refreshed** for the Phase 3-B v2 commit shape. Neither blocks Phase 4
but both will cause confusion for the implementer who cites these docs during
Gate F.

---

## Part 3 — Findings by dimension

### 3.1 Consistency

- **AF-001 (ship-blocker)** — SETUP-NEW.md § Manual fallback 5.A edits
  `scripts/validate.sh`/`test.sh`/`format.sh`; Procedure 7 §7.2.2 edits
  `validate-swift.sh`/`test-swift.sh`/`format-swift.sh`. Only one is correct.
  See §9 AF-001.
- **AF-005** — pm-chat.md line 33 (`**Pack version:** AI Agent Config Pack v8`)
  — stale; the surrounding variant is v10 post-Phase-3B-slim.
- **AF-006** — Seven template files still say "AI Agent Config Pack v9"
  in the "Copied from:" banner. Not strictly a defect (the banner is meant to
  be removed by the developer during placeholder fill), but the *source-side*
  banner mentions the pack version the template ships as. This should be v10
  for v10.0.

### 3.2 Completeness

- **AF-007** — MIGRATION-v9-to-v10.md "What changed in v10" (§ between
  lines 25–69) names BD-044, BD-045, BD-046. It does NOT name BD-047
  (Procedure 7 / pm-chat.md kickoff auto-discovery). Migrated projects DO get
  Procedure 7 via S5's verbatim METHODOLOGY.md copy, but the guide does not
  tell them it exists.
- **AF-008** — V10-IMPLEMENTATION-PLAN.md §6.6-B "Authoritative documents"
  list (lines 1625–1631) cites `V10-PHASE-3B-DESIGN.md` and
  `V10-PHASE-3B-PLAN.md` but not `V10-PHASE-3B-DESIGN-v2.md` or
  `V10-PHASE-3B-PLAN-v2.md`. A Phase 4 implementer pointed at this list will
  read the superseded v1 docs first. See §9 AF-008.

### 3.3 Accuracy

- **AF-002 (nice-to-fix)** — V10-IMPLEMENTATION-PLAN.md §6.6-B Gate E3 criteria
  (lines 1647–1660) describe a two-commit, four-sweep, METHODOLOGY-untouched
  phase. The landed reality is three commits, six sweeps, and METHODOLOGY.md
  is the home of the new Procedure 7.
- **AF-009** — METHODOLOGY.md Appendix "Day 1 — Setup" (line 1610) still
  instructs `cp -r pack/[TEMPLATE]/. .` — the pre-BD-044 manual copy method.
  `init-project.sh` is now the supported entry point. This appendix content
  contradicts SETUP-NEW.md Step 3.
- **AF-010** — METHODOLOGY.md lines 3–4 and line 1644 say "Version 2.0
  (v9, April 2026)" / "AI Agent Config Pack v9". Should be v10 for the v10
  release.
- **AF-014** — DEPENDENCIES.md line 3: "AI Agent Config Pack v9 unified
  template". Stale.
- **AF-015** — SETUP_TEMPLATE.md lines 18 and 35: "AI Agent Config Pack v9".
  Stale.
- **AF-016** — AGENT_KICKOFF_TEMPLATE.md line 21: "AI Agent Config Pack v9".
  Stale.
- **AF-017** — CLI-PM-SETUP.md line 5: "Setup is in QUICKSTART.md." QUICKSTART
  has been restructured by BD-044 to a three-path router; CLI PM setup now
  lives in `SETUP-NEW.md` Step 10 Option B. Stale pointer.
- **AF-018** — CLI-PM-SETUP.md line 7: "`PM-CHAT.md` in the project root".
  BD-042 (delivered in v9.2) moved this file to `docs/pack/PM-CHAT.md`.

### 3.4 Contradictions

- **AF-001** (the ship-blocker) is also a contradiction — SETUP-NEW 5.A and
  METHODOLOGY Procedure 7 §7.2.2 name different target files for the same
  editing operation. Byte-parity check that V10-PHASE-3B-PLAN-v2 Part 11 §11.1
  specified did not catch it.
- **AF-003** — project-template trinity: CLAUDE.md and GEMINI.md have the
  "Navigation logic lives outside view and view-model types" bullet under
  "Architecture — universal layer discipline"; AGENTS.md does not.
  Same rule, different presence. See §5.
- **AF-004** — project-template trinity: CLAUDE.md line 432 and GEMINI.md line
  363 carry the italic "This table reflects quality-optimized defaults. For
  cost-optimized routing alternatives, see TOOL-COMPARISON.md" paragraph after
  the phase-routing table. AGENTS.md ends the table and goes straight to the
  `### Custom agents` sub-heading. See §5.

### 3.5 Staleness

- AF-005, AF-006, AF-009, AF-010, AF-014, AF-015, AF-016, AF-017, AF-018 are
  all staleness. See §9.
- **AF-013 (note)** — V10-DESIGN.md Part 2 alternatives-rejected (lines 750–752)
  mentions a rejected "new BACKLOG item BD-047 for v10.1" in a completely
  different context (capability-addition procedure, rejected to batch into
  BD-046). The actual current BD-047 in BACKLOG.md is kickoff auto-discovery
  — unrelated. The BD-047 number has effectively been reused. A reader who
  searches for "BD-047" in V10-DESIGN.md will hit a historical reference that
  no longer describes BD-047's actual scope. Not a defect but a latent
  documentation-archaeology hazard.

### 3.6 Trinity rule

- AF-003 (AGENTS.md missing navigation bullet).
- AF-004 (AGENTS.md missing cost-optimized routing paragraph).
- **AF-011 (note)** — GEMINI.md has an `## Agent roster` section (lines 377–391)
  enumerating the 16 pack agents. CLAUDE.md and AGENTS.md do not enumerate
  agents by name at the root level — they rely on the phase-routing table.
  Arguably tool-specific (Gemini CLI auto-discovers agents via filesystem
  scan, so enumeration helps the human reader), but the pack-repo trinity
  rule allows asymmetry only when *provably* tool-specific. This one is
  presentation-specific, not tool-specific. Flag for judgment call.

### 3.7 Confusing content

- **AF-012 (nice-to-fix)** — SETUP-NEW.md uses intentional step-number gaps
  (1, 2, 3, 4, 5, 9, 10, 11, 12) per plan §6.4. A first-time reader who
  doesn't know the gap is intentional will think they have an outdated copy.
  SETUP-EXISTING.md has the same pattern (1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12,
  missing 6) — plan §6.4 is the reason. Neither guide carries a one-line
  "step 6–8 are intentionally absent — Steps 5–8 collapsed into Step 5 by
  BD-047 Phase 3-B" note. A reader will suspect corruption.

### 3.8 Plan-reality drift

The three accepted Path-A divergences are confirmed and no others were found:

| Metric | Plan target | Landed | Accepted? |
|---|---|---|---|
| pm-chat.md Variant: kickoff section body | ≤65 lines | 74 lines | Yes (Path A) |
| METHODOLOGY.md Procedure 7 | 180–260 line corridor | 308 lines | Yes (Path A) |
| `grep 'Procedure 7'` in pm-chat.md | exactly 1 | 3 | Yes (Path A) |
| METHODOLOGY.md `^### Procedure ` count & order | 8 procedures, specific order | 8, correct order | ✓ clean |
| `^## Variant: ` in pm-chat.md | 4 matches | 4 matches | ✓ clean |
| Full pm-chat.md file | ≤220 lines | 219 lines | ✓ clean |
| Commit count in Phase 3-B | 3 | 3 (1c5116c, db416a0, 2a0c8d5) + plan-prep 6d6ab6a | ✓ clean |
| Sweeps S3B-5 and S3B-6 — pass | expected | S3B-5 has 3 hits in pm-chat.md (accepted) + 2 in SETUP guides (note) + 1 in BACKLOG.md (note); S3B-6 clean | Mostly clean; see AF-019 |

- **AF-019 (note)** — V10-PHASE-3B-PLAN-v2 Part 6 §6.5 S3B-5 expected exactly
  1 Procedure 7 match in pm-chat.md, zero in BACKLOG.md; landed state has
  3 in pm-chat.md (accepted as Path A) plus 1 in BACKLOG.md BD-047 Resolution
  line (1093) and descriptive mentions in SETUP-NEW.md (153) and
  SETUP-EXISTING.md (148). The BACKLOG.md mention is legitimate (Resolution
  record); the SETUP guide mentions are descriptive-not-prescriptive pointers,
  which Q5 of the plan did not explicitly forbid. No implementer flag-back is
  needed, but Phase 4 should decide whether to tighten the sweep expectation
  text to match reality, or insist on the stricter reading.

### 3.9 Procedure 6 / 7 pattern coherence

- **Good**: Both procedures live as H3 `### Procedure N — <title>` under
  METHODOLOGY.md Part 7; both use the `G<N>-<verb>` gate-label convention; both
  are paired with an external trigger (Procedure 6 ↔ `add-capability.sh`,
  Procedure 7 ↔ pm-chat.md Variant: kickoff continuation pointer); both use
  TRIO / Form approval-gate patterns; both appear in METHODOLOGY.md ordered list
  at the correct position.
- **Neutral divergence**: Procedure 6 uses two gate labels (`G6-drafts`,
  `G6-commit`) placed inline in table cells; Procedure 7 uses four (`G7-discovery`,
  `G7-install`, `G7-edit`, `G7-machine`) placed inline in H5 sub-section headings.
  V10-PHASE-3B-PLAN-v2 Part 11 §11.3 justifies the divergence (table-driven vs.
  prose-driven procedures). Acceptable.
- **Good**: Procedure 7 §7.7 "Artifacts modified / Artifacts never touched /
  Sub-flow conditions" mirrors Procedure 6 lines 1127–1134 "Artifacts modified /
  Artifacts never touched by Procedure 6." Pattern re-use is clean.
- **AF-020 (note)** — Procedure 6 sub-heading scheme uses `#### 6.1`, `#### 6.2`,
  …; Procedure 7 uses `#### 7.0`, `#### 7.1`, … with 7.2 and 7.3 exploding into
  `##### 7.2.1` etc. Procedure 5 uses `#### Procedure 5.1`, `#### Procedure 5.2`
  — the word "Procedure" is in the sub-heading. Three styles. Not a defect;
  V10-PHASE-3B-PLAN-v2 Part 11 §11.2 notes the style choice and rationale.
  Phase 4 may want a brief style note in METHODOLOGY.md Part 7 preamble to
  reduce reader confusion when moving between procedures.

### 3.10 BD-047 closure coverage

See §8 — all 12 clauses close, but clauses 4 and 7 are undermined by AF-001
(the ship-blocker).

---

## Part 4 — Cross-doc contradictions

| # | Doc A | Doc B | Contradiction |
|---|---|---|---|
| X-1 | SETUP-NEW.md § Manual fallback 5.A (lines 169, 198) | METHODOLOGY.md Procedure 7 §7.2.2 (lines 1222–1227) | A names wrappers `validate.sh / test.sh / format.sh`; B names `-swift.sh` variants. Only B is functional. Ship-blocker AF-001. |
| X-2 | V10-IMPLEMENTATION-PLAN.md §6.6-B (lines 1634–1660) | V10-PHASE-3B-PLAN-v2.md Part 7 and Part 9 | A says 2 commits / 4 sweeps / METHODOLOGY.md untouched. B says 3 commits / 6 sweeps / METHODOLOGY.md gets Procedure 7. B is the current spec. Finding AF-002, AF-008. |
| X-3 | METHODOLOGY.md Appendix (line 1610) | SETUP-NEW.md Step 3 (lines 73–105) | A instructs `cp -r pack/[TEMPLATE]/. .`; B instructs `init-project.sh`. B is the v10 entry point. AF-009. |
| X-4 | CLI-PM-SETUP.md line 5 | QUICKSTART.md (v10 three-path router) | A says "setup is in QUICKSTART.md"; B routes to SETUP-NEW.md for new projects. AF-017. |
| X-5 | CLI-PM-SETUP.md line 7 | project-template/docs/pack/PM-CHAT.md location; CLAUDE.md "Document locations" table | A says PM-CHAT.md is in project root; B says it lives under `docs/pack/`. BD-042 moved it. AF-018. |
| X-6 | MIGRATION-v9-to-v10.md "What changed in v10" | BACKLOG.md BD-047 | A lists BD-044/045/046 only; B says BD-047 was a v10.0 ship-blocker that landed on v10-dev. AF-007. |
| X-7 | pm-chat.md line 33 ("Pack version: v8") | README.md version table (latest v9.3) plus v10-dev in progress | Any PM chat pasted version check is two majors stale. AF-005. |
| X-8 | project-template/CLAUDE.md "Architecture — universal layer discipline" | project-template/AGENTS.md "Architecture — universal layer discipline" | Navigation bullet present in CLAUDE.md and GEMINI.md; absent in AGENTS.md. AF-003. |

---

## Part 5 — Trinity-pair drift report

### 5.1 Project-template trinity (`project-template/CLAUDE.md` ↔ `AGENTS.md` ↔ `GEMINI.md`)

| Section | CLAUDE.md | AGENTS.md | GEMINI.md | Assessment |
|---|---|---|---|---|
| "Copied from:" banner version | v9 | v9 | v9 | All three stale (AF-006). Consistent-in-stale, but not v10. |
| Architecture — universal layer discipline — Navigation bullet | **Present** (line 95) | **Absent** | **Present** (line 89) | **Drift** (AF-003). AGENTS.md missing a universal rule. Not tool-specific. |
| Phase routing post-table cost-optimization note | Present (lines 432–434) | **Absent** | Present (lines 363–365) | **Drift** (AF-004). |
| `## Agent roster` section | Absent | Absent | **Present** (lines 377–391) | Possibly intentional asymmetry (Gemini enumerates for the reader; CLAUDE and Codex rely on agent files discovered by the tool). Judgment call (AF-011). |
| Capabilities pattern | Present | Present | Present | ✓ Clean; same content verbatim. |
| Active skills line / skill-loading block | Present | Present | Present | ✓ Clean. |
| Document locations table | Present | Present | Present | ✓ Clean. |
| Scripts table | Present (long) | Present (long) | Present (long) | ✓ Matches. |
| Deferral comments + BACKLOG hygiene | Present | Present (shorter) | Present | ✓ Content parity; AGENTS.md condensed as per its own comment. |
| Custom agents sub-section | Present | Present | Present | ✓ All three have it. |

**Summary.** Two real trinity rule violations (AF-003, AF-004) — both favor
CLAUDE.md + GEMINI.md with identical content and leave AGENTS.md short. These
predate Phase 3-B; Phase 3-B did not touch trinity files. Fix is a small TRIO
edit to AGENTS.md.

### 5.2 Pack-repo trinity (`/CLAUDE.md` ↔ `/AGENTS.md` ↔ `/GEMINI.md`)

All three are the concise pack-repo versions. Expected asymmetries (tool names,
a couple of tool-specific operating notes in GEMINI.md) are justified.
Substantive content — the trinity rule, BD-NNN numbering, commit format,
CI validation rule, "never modify without instruction" list — matches across
all three. No drift detected.

---

## Part 6 — Plan-reality drift check

The prompt names three accepted Path-A items. All three confirmed; no
additional divergences found at the metric level:

1. **pm-chat.md body ≤65 → 74 landed.** Confirmed via `awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' | wc -l` → 74.
2. **Procedure 7 260 ceiling → 308 landed.** Confirmed via `awk '/^### Procedure 7/,/^### Cancelling or deprecating/' | wc -l` → 308.
3. **Procedure 7 in pm-chat.md: 1 → 3.** Confirmed via `grep -c 'Procedure 7' pm-chat.md` → 3 (lines 26, 82, 83).

Each is within the "Path A — tolerance exceeded but semantics intact" accepted
window. No new plan-reality divergences surfaced.

**One semi-new item** — finding AF-019: S3B-5 expected "zero matches elsewhere";
landed state has 3 additional matches (BACKLOG.md resolution line +
SETUP-NEW.md descriptive mention + SETUP-EXISTING.md descriptive mention).
The plan's forbidden-location list did not include BACKLOG or the SETUP guides
explicitly; the landed mentions are legitimate. Flagged as a "tighten the plan
text" consideration for Phase 4, not a defect.

---

## Part 7 — Procedure 6 / 7 pattern coherence check

| Dimension | Procedure 6 (BD-046) | Procedure 7 (BD-047) | Match? |
|---|---|---|---|
| Heading level | H3 | H3 | ✓ |
| Location | METHODOLOGY.md Part 7 | METHODOLOGY.md Part 7 (after Procedure 6) | ✓ |
| External trigger | `scripts/add-capability.sh` stage A7 | `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff continuation pointer | ✓ symmetric |
| Gate label format | `G6-drafts`, `G6-commit` | `G7-discovery`, `G7-install`, `G7-edit`, `G7-machine` | ✓ same convention; Procedure 7 has more gates |
| Gate placement | Table cell `**Gn-…**` | H5 sub-section heading annotation | Neutral divergence (table vs prose shape) — justified |
| Sub-heading style | `#### 6.1 …` | `#### 7.0 …` | Slight style drift; Procedure 5 uses `#### Procedure 5.1` — three styles across Part 7 |
| "Artifacts modified / never touched" block | Present (lines 1127–1134) | Present (lines 1420–1441) | ✓ |
| Forward reference to external trigger | Yes (line 1106) | Yes (lines 1439–1441) | ✓ |
| PM-chat-side invocation | Pasted from stdout of `add-capability.sh` | Pasted from pm-chat.md Variant: kickoff continuation pointer | ✓ symmetric |

The pattern pair is coherent. The one area worth a Phase 4 polish pass is the
sub-heading-style mismatch across Procedures 5, 6, 7 — see AF-020.

Trinity files reference Procedure 6 (via `### Custom agents` sub-section
pointing at PLATFORM-SKILLS.md § Custom agents and via METHODOLOGY Procedure 5).
Trinity files do not reference Procedure 7 (appropriate — Procedure 7 is
invoked by the kickoff variant, not by any standing reference in CLAUDE/AGENTS/
GEMINI). No drift here.

---

## Part 8 — BD-047 12-clause closure verification

Mapping each clause against the landed artifacts:

| # | BD-047 clause (BACKLOG.md) | Closure location | Verified? |
|---|---|---|---|
| 1 | "auto-discovers Xcode scheme / simulator values (via `xcodebuild -list` and `xcrun simctl list devices available`)" | METHODOLOGY.md §7.1 Form R lines 1177–1178; §7.2.1 lines 1208–1213 | ✓ present and correct |
| 2 | "detects missing brew tools (swift-format, buf, swift-protobuf, grpc-swift)" | §7.1 Form R lines 1179, 1182–1184, 1187; §7.2.3, §7.3.1 Form I blocks | ✓ present |
| 3 | "prompts for `brew install` with developer approval" | §7.2.3 / §7.3.1 / §7.3.2 Form I, default `skip`, G7-install gate | ✓ present |
| 4 | "edits `scripts/validate.sh`, `scripts/test.sh`, `.claude/settings.json`, and `scripts/format.sh`" | §7.2.2 Form E — **actually targets `validate-swift.sh`, `test-swift.sh`, `format-swift.sh`** per flag-back #1 rationale | Partial — Procedure 7 edits the correct files; **SETUP-NEW.md § Manual fallback 5.A still edits the wrappers per BD-047's original clause wording (AF-001)**. The two halves are out of parity. |
| 5 | "handles Xcode companion files (machine-level `cp` with confirmation)" | §7.2.4 Form M, G7-machine; SETUP-NEW § 5.D | ✓ present |
| 6 | "Shell-out-capability detection" | pm-chat.md lines 40–48 (surface-declaration Q/A), lines 80–89 (continuation pointer) | ✓ present |
| 7 | "SETUP-NEW.md and SETUP-EXISTING.md Steps 5–6 change to 'PM chat handles this during kickoff' with a manual-alternative fallback section" | SETUP-NEW.md Step 5 lines 149–250; SETUP-EXISTING.md Step 5 lines 145–157 | ✓ structural; **Manual fallback content has AF-001 defect** |
| 8 | "Principle: Developer is the decision-maker" | §7.4 three common-discipline bullets (lines 1350–1357); every Form defaults to `skip` or asks for explicit reply | ✓ present |
| 9 | "Phase 3-B scope outline step 1 — planner/architect pass" | V10-PHASE-3B-DESIGN.md + DESIGN-v2.md; V10-PHASE-3B-PLAN.md + PLAN-v2.md | ✓ all four maintenance docs present |
| 10 | "Phase 3-B scope outline step 2 — enhance pm-chat.md Variant: kickoff" | Commit 1 (pm-chat.md slim + pointer) + Commit 3 (Procedure 7 body) | ✓ present; split-home but complete |
| 11 | "Phase 3-B scope outline step 3 — update SETUP-NEW + SETUP-EXISTING Steps 5–6" | Commit 2 | ✓ present (AF-001 notwithstanding) |
| 12 | "Phase 3-B scope outline step 4 — shell-out-capability detection logic with documented fallback path" | pm-chat.md surface-declaration + pointer; SETUP-NEW § Manual fallback | ✓ present (AF-001 notwithstanding) |

**Conclusion.** All 12 clauses have a closure location. Clauses 4, 7, 11, 12
are subject to AF-001: the Procedure 7 side is correct but the Manual fallback
side still names the wrapper scripts. Semantics are closed; surface is not
fully consistent. The BACKLOG.md BD-047 Resolution line should not be rolled
back, but AF-001 should be fixed before v10.0 tags.

---

## Part 9 — Findings list (AF-001 through AF-020)

Each finding is self-contained. Severity: **ship-blocker** (must fix before
v10.0 tags), **nice-to-fix** (fix during Phase 4, not a release gate),
**note** (defer, dismiss, or informational).

---

### AF-001 — SETUP-NEW.md § Manual fallback 5.A targets the wrong script files
**Severity:** ship-blocker
**Doc + location:**
- `supporting-docs/SETUP-NEW.md` § Manual fallback 5.A, lines 169, 198
- Compare with `supporting-docs/METHODOLOGY.md` Procedure 7 §7.2.2, lines 1224–1226
**Issue:** The Manual fallback tells the developer to edit
`scripts/validate.sh`, `scripts/test.sh`, and `scripts/format.sh` (the wrapper
scripts). These wrappers do not carry the `XCODE_SCHEME` / `XCODE_DESTINATION`
/ `SWIFT_SOURCE_DIRS` variables. The variables live in
`scripts/validate-swift.sh`, `scripts/test-swift.sh`, and
`scripts/format-swift.sh`. Verified by grep of `XCODE_SCHEME` in
`project-template/scripts/*.sh` — only `validate-swift.sh`, `test-swift.sh`,
and `agent-post-edit-check.sh` reference it; the wrappers do not.
**Evidence:**
- SETUP-NEW.md line 169: `Open `scripts/validate.sh` and `scripts/test.sh`. Fill these at the top:`
- SETUP-NEW.md line 198: ``also set `SWIFT_SOURCE_DIRS` in `scripts/format.sh`:``
- Procedure 7 §7.2.2 (METHODOLOGY.md line 1224): `For each of the four targets — `scripts/validate-swift.sh`, `scripts/test-swift.sh`, `.claude/settings.json`, and `scripts/format-swift.sh` …`
- V10-PHASE-3B-PLAN-v2.md Part 10 flag-back #1: "BD-047 names `scripts/validate.sh`, `scripts/test.sh`, `scripts/format.sh`; post-BD-026 the Xcode-variable anchors live in the language-specific variants. **Target the correct files per v1 Part 2.**"
- V10-PHASE-3B-PLAN-v2.md Part 11 §11.1 parity table explicitly requires the
  two command sets to agree.
**Impact:** A developer on Claude Web / ChatGPT Web (the only surfaces that
reach the Manual fallback) will edit files that do not contain the target
variables. `scripts/validate.sh` and `scripts/test.sh` are wrapper scripts
that dispatch to the `-swift.sh` variants based on marker-file detection;
adding `XCODE_SCHEME=""` at the top of a wrapper does nothing at xcodebuild
time. The build will continue to print `⚠️ XCODE_SCHEME is not set`.
**Suggested fix:** Rewrite SETUP-NEW.md § Manual fallback 5.A to name the
`-swift.sh` variants, matching Procedure 7 §7.2.2. Change two body paragraphs
and three code-fence headings. Single-commit `fix:` scope.
**Gate:** Must fix before v10.0 tag.

---

### AF-002 — V10-IMPLEMENTATION-PLAN.md §6.6-B describes the pre-v2 commit shape
**Severity:** nice-to-fix
**Doc + location:** `maintenance-docs/V10-IMPLEMENTATION-PLAN.md` §6.6-B,
lines 1617–1666.
**Issue:** The section describes Phase 3-B as a two-commit phase (C-047-01 +
C-047-02) with Gate E3 criteria 2 "Cross-reference sweeps S3B-1..S3B-4 clean"
and criterion 10 "No unintended touches (trinity, scripts, METHODOLOGY.md,
`validate-pack.py`, `README.md`, `BACKLOG.md` all untouched)." The landed v2
reality is three commits, six sweeps (S3B-1..S3B-6), and METHODOLOGY.md is
*deliberately* modified to host Procedure 7.
**Evidence:**
- §6.6-B line 1634: "Commits (see V10-PHASE-3B-PLAN.md Part 7 for full detail)" — points at v1 plan, not v2.
- §6.6-B line 1648: "Cross-reference sweeps S3B-1..S3B-4 clean" — v2 added S3B-5 and S3B-6.
- §6.6-B line 1659: "No unintended touches (trinity, scripts, **METHODOLOGY.md**, validate-pack.py, README.md, BACKLOG.md all untouched)" — Commit 3 touches METHODOLOGY.md by design.
**Suggested fix:** Refresh §6.6-B to cite V10-PHASE-3B-DESIGN-v2.md and
V10-PHASE-3B-PLAN-v2.md as authoritative, replace commit list with the
three v2 commits, update Gate E3 criteria with S3B-5/S3B-6 and remove the
METHODOLOGY.md-untouched clause (replace with "METHODOLOGY.md modified by
Commit 3 to add Procedure 7; no other changes").

---

### AF-003 — AGENTS.md missing Navigation bullet (trinity drift)
**Severity:** nice-to-fix
**Doc + location:** `project-template/AGENTS.md` "Architecture — universal
layer discipline" (lines 66–76).
**Issue:** CLAUDE.md line 95 and GEMINI.md line 89 each carry the bullet
"Navigation logic lives outside view and view-model types." AGENTS.md does
not. This is a universal-layer-discipline rule; it is not tool-specific.
**Evidence:** See grep results in §5.1.
**Suggested fix:** Add the Navigation bullet to AGENTS.md § Architecture —
universal layer discipline. TRIO trinity rule applies; no other edit needed
as the rule is already in the other two. Single `fix:` commit.

---

### AF-004 — AGENTS.md missing cost-optimized-routing note (trinity drift)
**Severity:** nice-to-fix
**Doc + location:** `project-template/AGENTS.md` end of Phase routing table
(after line 310).
**Issue:** CLAUDE.md lines 432–434 and GEMINI.md lines 363–365 end the phase-
routing table with an italic note pointing at TOOL-COMPARISON.md for
cost-optimized routing alternatives. AGENTS.md does not.
**Suggested fix:** Add the same italic paragraph to AGENTS.md immediately
after the phase-routing table, before `### Custom agents`. Fold with AF-003
fix into one TRIO commit.

---

### AF-005 — pm-chat.md Variant: kickoff Pack-version placeholder is v8
**Severity:** nice-to-fix
**Doc + location:** `project-template/docs/pack/prompts/pm-chat.md` line 33.
**Issue:** The kickoff variant tells the developer to fill in the placeholders
then paste. The pre-filled `**Pack version:**` line reads `AI Agent Config
Pack v8`. The developer usually does not edit this because it looks like
boilerplate context; a new v10 project's PM chat will read "Pack version: v8"
and react accordingly.
**Suggested fix:** Change the template value to `AI Agent Config Pack v10.0`
(or leave as `[PLACEHOLDER]` if intentional, but then flag that in the pre-
paste instructions). Single `fix:` commit.

---

### AF-006 — Seven template / supporting-docs files carry "Copied from: …v9" banners
**Severity:** nice-to-fix
**Docs + locations:**
- `project-template/CLAUDE.md` line 21
- `project-template/AGENTS.md` line 18
- `project-template/GEMINI.md` line 17
- `project-template/docs/pack/PACK-FEEDBACK.md` line 27
- `project-template/docs/pack/PM-CHAT.md` line 22
- `project-template/README.md` line 1
- `supporting-docs/SETUP_TEMPLATE.md` lines 18 and 35
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` line 21
**Issue:** All say "AI Agent Config Pack v9." The banner is intended to be
removed by the developer during placeholder fill, but the source-side banner
itself must reflect the pack version that ships the file.
**Suggested fix:** Bulk `sed` / manual replace v9 → v10 across these files.
One `docs:` commit. No trinity-rule exemptions needed (all three template
trinity files are uniformly stale, so the TRIO fix preserves symmetry).

---

### AF-007 — MIGRATION-v9-to-v10.md omits BD-047
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/MIGRATION-v9-to-v10.md` § "What changed
in v10" (lines 27–69).
**Issue:** Three BD items listed (BD-044, BD-045, BD-046). BD-047 is not
named. Migrated projects get Procedure 7 automatically via S5's
METHODOLOGY.md copy, but the migration guide does not tell them.
**Suggested fix:** Add a fourth bullet: `BD-047 — PM chat kickoff auto-
discovery and install-check. A new Procedure 7 in METHODOLOGY.md paired
with the pm-chat.md Variant: kickoff continuation pointer. On shell-capable
surfaces, the PM chat runs read-only discovery (xcodebuild -list, simctl,
brew detection) and offers approval-gated Forms for every install and edit.`

---

### AF-008 — V10-IMPLEMENTATION-PLAN.md §6.6-B cites v1 design/plan, not v2
**Severity:** nice-to-fix
**Doc + location:** `maintenance-docs/V10-IMPLEMENTATION-PLAN.md` §6.6-B
"Authoritative documents" lines 1625–1631.
**Issue:** Lists `V10-PHASE-3B-DESIGN.md` and `V10-PHASE-3B-PLAN.md` as the
authoritative reads. The v2 docs supersede both for Part 7 §7.2 and Part 10
(design) and for full execution spec (plan). A Phase 4 implementer cited to
§6.6-B will read the superseded docs first.
**Suggested fix:** Update the list to include the v2 siblings with the
supersession note already present in the v2 header comments.

---

### AF-009 — METHODOLOGY.md Appendix `cp -r pack/[TEMPLATE]/. .` is stale (pre-BD-044)
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/METHODOLOGY.md` Appendix "Day 1 — Setup"
line 1610.
**Issue:** The appendix still reads `Copy template files from pack: cp -r
pack/[TEMPLATE]/. . — then separately copy METHODOLOGY.md, PM-CHAT.md, and
PACK-FEEDBACK.md from project-template/ and supporting-docs/`. This is the
v8-era manual copy procedure. BD-044 introduced `init-project.sh` which
replaces the entire block. The appendix also references `[TEMPLATE]` — a
relic of the pre-v9 three-template era.
**Suggested fix:** Rewrite the Appendix Day-1 bullet list to match SETUP-NEW.md
Step 3 (`"$PACK/scripts/init-project.sh" .`).

---

### AF-010 — METHODOLOGY.md version string is v9
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/METHODOLOGY.md` lines 3–4 and line 1644.
**Issue:** Header declares `Version: 2.0 (v9, April 2026)` / `Applies to:
AI Agent Config Pack v9`. Footer reads `Version 2.0 — AI Agent Config Pack
v9, April 2026`. METHODOLOGY.md gained Procedure 7 as a BD-047 v10.0 change;
the version header should move.
**Suggested fix:** Bump to v10 at Phase 4 / ship.

---

### AF-011 — GEMINI.md has `## Agent roster` section absent from CLAUDE.md + AGENTS.md
**Severity:** note (judgment call)
**Doc + location:** `project-template/GEMINI.md` lines 377–391.
**Issue:** The roster enumerates all 16 pack agents by name. Arguably tool-
specific (Gemini CLI auto-discovers via filesystem scan; listing in GEMINI.md
aids human readability). But the pack trinity rule allows asymmetry only when
*provably* tool-specific, and enumerating agent names is presentation, not
tool behavior.
**Suggested fix:** Needs-decision. Either drop the section from GEMINI.md
(rely on discovery + phase-routing table as CLAUDE / AGENTS do), OR add
matching sections to CLAUDE.md and AGENTS.md, OR keep the current asymmetry
and add a brief justification comment inside GEMINI.md explaining why this
is Gemini-only.

---

### AF-012 — SETUP guides have step-number gaps with no explanatory note
**Severity:** nice-to-fix
**Docs + locations:**
- `supporting-docs/SETUP-NEW.md` — Steps 1–5, 9–12 (gap at 6–8)
- `supporting-docs/SETUP-EXISTING.md` — Steps 1–5, 7–12 (gap at 6)
**Issue:** Intentional per V10-PHASE-3B-PLAN-v2.md §6.4 ("step-number
preservation"), but a first-time reader will suspect the file is corrupted.
**Suggested fix:** Add a one-line italic note under Step 5 in each guide:
`*Steps 6–8 were collapsed into Step 5 by BD-047 Phase 3-B — the step numbers
are preserved for cross-doc reference stability.*` (For SETUP-EXISTING, the
gap is at 6 only.) Single `docs:` commit.

---

### AF-013 — V10-DESIGN.md Part 2 rejected-alternative mentions "BD-047" (now reused number)
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN.md` Part 2 rejected
alternatives, lines 750–752.
**Issue:** The text rejects a hypothetical "BD-047 for v10.1" in the context
of capability-addition batching. The BD-047 number was subsequently assigned
to a different scope (PM chat kickoff auto-discovery). A reader who searches
V10-DESIGN.md for BD-047 hits a historical reference that describes a very
different concept.
**Suggested fix:** Add a one-line footnote or parenthetical clarification
in V10-DESIGN.md lines 750–752: `(Note: BD-047 was later filed on 2026-04-24
for a different scope — PM chat kickoff auto-discovery. This rejected
alternative predates that filing.)`. Low priority — defer to v10.1 cleanup
unless the Phase 4 audit flags reader confusion.

---

### AF-014 — DEPENDENCIES.md version string is v9
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/DEPENDENCIES.md` line 3.
**Issue:** `This document lists all tools required or optionally used by the
AI Agent Config Pack v9 unified template.` Should be v10.
**Suggested fix:** Rename v9 → v10 at Phase 4 / ship.

---

### AF-015 — SETUP_TEMPLATE.md version strings are v9
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/SETUP_TEMPLATE.md` lines 18 and 35.
**Issue:** `"Generated from: supporting-docs/SETUP_TEMPLATE.md — AI Agent
Config Pack v9"` and `"AI Agent Config Pack v9 available locally"`. Both
stale.
**Suggested fix:** Rename v9 → v10.

---

### AF-016 — AGENT_KICKOFF_TEMPLATE.md version string is v9
**Severity:** nice-to-fix
**Doc + location:** `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` line 21.
**Issue:** `"Generated from: supporting-docs/AGENT_KICKOFF_TEMPLATE.md —
AI Agent Config Pack v9"`. Stale.
**Suggested fix:** Rename v9 → v10.

---

### AF-017 — CLI-PM-SETUP.md "Setup is in QUICKSTART.md" is stale pointer
**Severity:** note (fix can fold into AF-010 / AF-014 pass)
**Doc + location:** `supporting-docs/CLI-PM-SETUP.md` line 5.
**Issue:** QUICKSTART.md is now a three-path router; CLI PM chat setup lives
in SETUP-NEW.md Step 10 Option B.
**Suggested fix:** Change to `Setup is in supporting-docs/SETUP-NEW.md Step 10
Option B (Claude Code CLI) or Option D (Gemini CLI). Start there if you haven't
completed setup yet.`

---

### AF-018 — CLI-PM-SETUP.md "`PM-CHAT.md` in the project root" is stale
**Severity:** note
**Doc + location:** `supporting-docs/CLI-PM-SETUP.md` line 7.
**Issue:** BD-042 (v9.2) moved PM-CHAT.md from project root to
`docs/pack/PM-CHAT.md`. CLAUDE.md "Document locations" table confirms this.
**Suggested fix:** Change to `For startup procedures, file access strategy,
and behavioral rules, see docs/pack/PM-CHAT.md (the authoritative PM chat
instructions).`

---

### AF-019 — S3B-5 Procedure 7 sweep finds legitimate extra matches not enumerated in plan
**Severity:** note
**Doc + location:** V10-PHASE-3B-PLAN-v2.md Part 6 §6.5 expected-results list.
**Issue:** The sweep expected "zero matches elsewhere in project-template/,
QUICKSTART.md, README.md, PACK-*.md, BACKLOG.md, root trinity." Landed state
has:
- 3 matches in pm-chat.md (accepted as Path A)
- 1 match in `BACKLOG.md` line 1093 (BD-047 Resolution record — legitimate,
  written *after* the sweep was defined)
- 1 descriptive mention in `supporting-docs/SETUP-NEW.md` line 153 ("METHODOLOGY.md
  Procedure 7) after you paste the kickoff prompt")
- 1 descriptive mention in `supporting-docs/SETUP-EXISTING.md` line 148
All legitimate; none violate Q5's intent (which prohibited *redundant routing
pointers*, not descriptive mentions).
**Suggested fix:** No action required. Phase 4 gate sweep should apply the
same legitimacy judgment. Optional: tighten the S3B-5 "sanctioned residuals"
list during Phase 4's Gate F sweep definition pass.

---

### AF-020 — Procedures 5 / 6 / 7 have three different sub-heading styles
**Severity:** note
**Doc + location:** `supporting-docs/METHODOLOGY.md` Procedures 5, 6, 7.
**Issue:**
- Procedure 5 uses `#### Procedure 5.1`, `#### Procedure 5.2`, …
- Procedure 6 uses `#### 6.1`, `#### 6.2`, …
- Procedure 7 uses `#### 7.0`, `#### 7.1`, `#### 7.2` with `##### 7.2.1`, …
Not a defect; V10-PHASE-3B-PLAN-v2.md Part 11 §11.2 rationalizes the
Procedure 7 numeric style. But three styles across three adjacent procedures
is a reader-experience nit.
**Suggested fix:** Defer to v10.1 cosmetic pass. Optionally add a Part 7
preamble note: "Sub-procedure heading style varies by procedure; see each
procedure for its own convention."

---

## Part 10 — Open questions for the project lead

These are judgment calls only the project lead can resolve.

1. **AF-001 fix timing.** Fix inside Phase 3-B as a `fix:` retrofit commit (4th
   commit on v10-dev), or fix during Phase 4 before v10.0 tag? Retrofitting
   preserves the 3-commit Phase 3-B shape in git log but risks implementer
   confusion; Phase 4 fix is cleaner but means v10-dev tip carries a known
   ship-blocker until then. Recommend retrofit.

2. **AF-011 GEMINI.md Agent roster section.** Keep asymmetric (tool-specific
   presentation aid), drop from GEMINI, or add to CLAUDE + AGENTS? No
   correctness consequence; purely a trinity-discipline judgment call.

3. **AF-006 + AF-010 + AF-014–AF-016 version string update scope.** Fold all
   seven v9 → v10 changes into one `docs: v10 — version string refresh`
   commit during Phase 4, or distribute per-file? A single commit is
   cheaper to review and easier to revert.

4. **AF-002 + AF-008 V10-IMPLEMENTATION-PLAN.md refresh.** The plan is a
   maintenance-doc, not a shipped artifact. It is already accurate for
   Phases 1, 2, 3, 3-AC, and 3-B if the reader knows to consult the v2
   docs. Refresh inside Phase 4, or accept as-is with a one-line
   "§6.6-B superseded by V10-PHASE-3B-{DESIGN,PLAN}-v2.md" note at the
   top of §6.6-B?

5. **AF-013 BD-047 number reuse.** V10-DESIGN.md's rejected "BD-047" refers
   to a different concept than the filed BD-047. Acceptable (the number
   was never assigned to the rejected alternative) or worth a footnote?

6. **V9-DESIGN.md "Status: Planning" header (not a numbered finding).** The
   file header still says "Status: Planning — no implementation has begun,"
   though v9 shipped and is annotated with v9.3 and v10 postscripts. Treat
   as historical artifact or update to "Status: Superseded — see V10-DESIGN.md"?

7. **Scope question.** The prompt scope did not include
   `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` (910 lines). Given the v2
   plan explicitly references it, should Phase 4 audit also verify its
   currency? Out-of-scope per prompt instruction; flagging here.

---

*End of V10-AUDIT-REPORT.md.*
