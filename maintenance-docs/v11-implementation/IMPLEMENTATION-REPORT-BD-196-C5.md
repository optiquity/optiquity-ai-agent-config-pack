# IMPLEMENTATION-REPORT — BD-196 C5

**Commit:** C5 — Author `pack-ops/.spawn-rule-manifest.txt`; collapse the 6
PACK-AGENTS/PACK-CHAT restatements to one-line references (incl. the PREFLIGHT
block) — NO check wired yet.

**Branch:** `v11-dev`
**Base HEAD (pre-flight `git rev-parse HEAD`):** `bf9290b924c9825a7f65a9e1b0ea6f2072259d16`
**Final HEAD (working-tree edits only; agents never commit):** `bf9290b924c9825a7f65a9e1b0ea6f2072259d16`
**Plan:** `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` C5 (L84-90)
**Design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §9.6 + EE-6 (v9)

---

## Files changed (inventory)

| Path | Change type |
|---|---|
| `pack-ops/.spawn-rule-manifest.txt` | **new** |
| `pack-ops/PACK-AGENTS.md` | modified (3 restatements collapsed) |
| `pack-ops/PACK-CHAT.md` | modified (1 verbatim restatement block collapsed; see deviation note) |

No other files touched. Manifest regen (`test-fixtures/build.sh`) is Pack Chat's at
commit time per the C5 prompt ("Manifest regen is Pack Chat's at commit — pack-ops/
touched; do NOT run build.sh or stage").

---

## Verification

- **`python3 scripts/validate-pack.py`** — **PASSED — all checks clean** (full
  suite, post-edit). Intermediate FAIL caught + fixed: Check 40 flagged a bare
  `validate-pack.py` reference at PACK-AGENTS.md:185 (introduced when I collapsed
  the PREFLIGHT block); re-qualified to `scripts/validate-pack.py`; re-ran → clean.
- **Check 40 (pack-ops/ bare-reference scanner) over edited PACK-AGENTS/PACK-CHAT**
  — PASS. The new one-line references use `[rationale: <slug>]` + `## Pack memory`
  (no `FILENAME.ext` pattern) and path-qualified `scripts/validate-pack.py` →
  none trip Check 40.
- **Check 45 (rule↔rationale bijection)** — PASS (18/18 unchanged; C5 added no new
  corpus slugs).
- **Anti-restate substring measurement** (the predicate C6 will wire) — run manually
  against the edited pack-ops files: all 7 canonical spawn-rule imperative phrases
  return ZERO hits in PACK-AGENTS.md + PACK-CHAT.md. The verbatim imperative TEXT
  is GONE → C6's anti-restate scan will PASS.

```
CLEAN: [No agent — including]                       (git-ban)
CLEAN: [may run `git add`]                           (git-ban)
CLEAN: [After all in-scope edits]                    (PREFLIGHT)
CLEAN: [STOP-MEANS-STOP on parent]                   (PREFLIGHT)
CLEAN: [Pack Chat STOPS, surfaces the findings]      (triage-stop)
CLEAN: [Source modifications are restricted by agent role]  (role-write-scope)
CLEAN: [Only Pack Chat may stage or commit]          (git-ban deliverable clause)
```

---

## The collapses (before / after — verbatim imperative TEXT confirmed GONE)

### PACK-AGENTS.md — collapse 1 of 3: git-state-change ban + deliverable contract

**Before** (L116-138): four bold paragraphs — "**Git state changes are forbidden
for ALL agents.** No agent — including `pack-coder` — may run `git add` … " +
"**Every agent produces a report file.** …" + "**Only Pack Chat may stage or
commit.** …" (the full imperative verbatim).

**After** (L116-120): one-line reference —
> **Git state changes are forbidden for ALL agents; only Pack Chat stages or
> commits.** Agents never commit — see trinity `## Pack memory`
> `[rationale: agents-never-commit]` for the canonical imperative (the forbidden
> verbs, the read-only-verb allowance, and the report-plus-working-tree-edits
> deliverable contract).

Verbatim "No agent — including" / "may run `git add`" / "Only Pack Chat may stage
or commit" → GONE (measured CLEAN).

### PACK-AGENTS.md — collapse 2 of 3: source-write / role-write scope

**Before** (L123-128): "**Source modifications are restricted by agent role:**" +
the per-agent read-only/write bullets (imperative restate of the roster Mode).

**After** (L122-128): one-line reference —
> **Source-write scope is the per-agent `Mode` in the roster above.** Read-only
> agents … Write/Edit only their caller-specified report; `pack-coder` Write/Edits
> source within its caller-defined scope plus its report — see the "Source-write
> within scope; never stages or commits" roster cell and trinity `## Pack memory`
> `### Pack Chat scope` "What Pack Chat CAN edit directly" for the canonical
> write-authority split.

Verbatim "Source modifications are restricted by agent role" → GONE (measured
CLEAN). The reference points at the roster `Mode` column (DATA, retained above)
+ the corpus "What Pack Chat CAN edit directly" rule (this rule has no
`[rationale:]` slug → rule-name + canonical pointer form per the C5 prompt).

### PACK-AGENTS.md — collapse 3 of 3: PREFLIGHT + STOP-MEANS-STOP (EE-6 PARTIAL restate)

**Before** (L190-228): the full two-sub-bullet imperative — "**PREFLIGHT line
BEFORE IMPL-REPORT.** After all in-scope edits + verification, emit … `PREFLIGHT:
N/N …`" + the Check-43/validate-pack gate paragraph + "**STOP-MEANS-STOP on parent
stop directives.** Any parent-session message containing stop / halt / revert …" +
the existing trailing "Authoritative full text … trinity `## Pack memory` …" line.

**After** (L180-187): one-line reference (the existing "Authoritative full text"
line extended to the canonical one-liner form per plan L86) —
> **Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation.** Every pack-coder (or
> coder-style fix-coder) agent emits the PREFLIGHT trust-signal line before any
> IMPL-REPORT write and halts immediately on a parent stop directive — see trinity
> `## Pack memory` `[rationale: preflight-stop-means-stop]` for the canonical
> imperative (PREFLIGHT line format, the `scripts/validate-pack.py` + Check 43
> verification gate, the report-failure-instead-of-IMPL-REPORT behavior, the
> STOP-MEANS-STOP halt rule, and the cross-CLI scope notes for Codex / Gemini).

Verbatim "After all in-scope edits" / "STOP-MEANS-STOP on parent" → GONE (measured
CLEAN). The imperative TEXT is dropped; only the resolvable reference remains.

### PACK-CHAT.md — collapse: triage-stop / per-reviewer-pass cadence block

**Before** (L63-71): "**Stop after every reviewer pass for triage discussion.**
After every pack-reviewer run, Pack Chat STOPS, surfaces the findings (severity-
grouped) to the user, and waits for triage approval — even if the reviewer verdict
is fully clean. No auto-commit on clean verdicts. … The stop point is BEFORE Pack
Chat triages …" (the imperative verbatim).

**After** (L63-70): one-line reference —
> **Stop after every reviewer pass for triage discussion.** Pack Chat STOPS after
> every pack-reviewer run, surfaces the findings to the user, and waits for triage
> approval before any fix-coder spawn — see the "Pack Chat presents triage to user
> before fix-coder spawns" rule in trinity `## Pack memory` `### Workflow` for the
> canonical imperative (the stop-before-triage gate, the clean-verdict-still-stops
> rule, and the distinction from the implicit-BD-status-flip and commit-approval
> rules).

Verbatim "Pack Chat STOPS, surfaces the findings (severity-grouped)" / "The stop
point is BEFORE Pack Chat triages" → GONE (measured CLEAN). Reference target is the
corpus "Pack Chat presents triage to user before fix-coder spawns" rule (no
`[rationale:]` slug → rule-name + canonical pointer form).

---

## Manifest contents (`pack-ops/.spawn-rule-manifest.txt`)

Six records (slug → canonical `## Pack memory` + reference surface), header
documents the format + the C6 reader contract (reference-resolution +
anti-restate). Section-name reference surfaces (NOT line numbers — line numbers
drift). Full records:

| slug | corpus home | reference surface |
|---|---|---|
| `agents-never-commit` | `### Workflow` "Agents never commit" | PACK-AGENTS.md § "Agent permission rules" (git-ban + deliverable) |
| `role-write-scope` | `### Pack Chat scope` "What Pack Chat CAN edit directly" + roster Mode | PACK-AGENTS.md § "Agent permission rules" (source-write scope) |
| `preflight-stop-means-stop` | `### Agent invocation rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" | PACK-AGENTS.md § "Agent permission rules" (PREFLIGHT obligation) |
| `presents-triage-before-fix-coder` | `### Workflow` "Pack Chat presents triage to user before fix-coder spawns" | PACK-CHAT.md § "Behavioral rules" (triage-stop block) |
| `triage-all-fix-all` | `### Workflow` "Triage all reviewer findings; default fix-all" | PACK-CHAT.md § "Behavioral rules" (triage-stop block + "Real fixes only" distinct-from cite) |
| `pack-chat-no-coder-review-bounded-cycle` | `### Pack Chat scope` "Pack Chat does NO fixes" + "Pack Chat NO coder review; bounded reviewer/fix cycle" | PACK-CHAT.md § "Behavioral rules" (per-reviewer-pass stop gate) |

The full file (so Pack Chat can re-apply without re-deriving):

```
# .spawn-rule-manifest.txt — spawn-relevant rule reference manifest (BD-196 C5)
#
# Purpose: each spawn-relevant rule is authored ONCE — its imperative lives in
# trinity `## Pack memory` (CLAUDE.md / AGENTS.md / GEMINI.md at pack root). The
# 6 former restatements in pack-ops/PACK-AGENTS.md + pack-ops/PACK-CHAT.md have
# been collapsed (BD-196 C5) to one-line REFERENCES. This manifest records, for
# each collapsed rule, its canonical home + the reference surfaces where the
# one-line pointer now lives. The C6 spawn-rule check (Check 46) reads this file
# for two assertions: (a) reference-resolution — every named reference surface
# carries a resolving pointer to the rule; (b) anti-restate — the canonical
# imperative TEXT must NOT reappear verbatim in any reference surface.
#
# Format (one record per rule, blank-line separated):
#   slug:       <rationale slug, or the rule-name token for rules without a
#               [rationale:] slug in the corpus>
#   canonical:  ## Pack memory  (trinity: CLAUDE.md / AGENTS.md / GEMINI.md @ pack root)
#   corpus:     <the corpus subsection the canonical imperative lives in>
#   references: <surface §/section where the collapsed one-line reference now lives>
#               (semicolon-separated when more than one)
#
# Lines beginning with `#` are comments. The reference surfaces use section
# names (not line numbers — line numbers drift).

slug:       agents-never-commit
canonical:  ## Pack memory
corpus:     ### Workflow — "Agents never commit"
references: PACK-AGENTS.md § "Agent permission rules" (git-state-change ban + report-deliverable contract)

slug:       role-write-scope
canonical:  ## Pack memory
corpus:     ### Pack Chat scope — "What Pack Chat CAN edit directly" (+ the per-agent Mode column in the PACK-AGENTS.md roster)
references: PACK-AGENTS.md § "Agent permission rules" (source-write scope per roster Mode)

slug:       preflight-stop-means-stop
canonical:  ## Pack memory
corpus:     ### Agent invocation rules — "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern"
references: PACK-AGENTS.md § "Agent permission rules" (Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation)

slug:       presents-triage-before-fix-coder
canonical:  ## Pack memory
corpus:     ### Workflow — "Pack Chat presents triage to user before fix-coder spawns"
references: PACK-CHAT.md § "Behavioral rules" ("Stop after every reviewer pass for triage discussion")

slug:       triage-all-fix-all
canonical:  ## Pack memory
corpus:     ### Workflow — "Triage all reviewer findings; default fix-all; nits become tech debt"
references: PACK-CHAT.md § "Behavioral rules" ("Stop after every reviewer pass for triage discussion"); PACK-CHAT.md § "Behavioral rules" ("Real fixes only — no green-the-test band-aids", distinct-from cross-reference)

slug:       pack-chat-no-coder-review-bounded-cycle
canonical:  ## Pack memory
corpus:     ### Pack Chat scope — "Pack Chat does NO fixes" + "Pack Chat NO coder review; bounded reviewer/fix cycle"
references: PACK-CHAT.md § "Behavioral rules" ("Stop after every reviewer pass for triage discussion", the per-reviewer-pass stop gate)
```

---

## Non-rule content left intact (NOT over-collapsed)

- **PACK-AGENTS.md:** the Pack-agents roster table (incl. the `Mode` column),
  "Skills loaded by pack agents", "How to invoke pack agents", "When agents are
  used vs. pack chat direct", the **PM-only Files + Directories list** (L130-158),
  per-entry decomposition notes, the Batch-19→23 forward-pointing note, the
  Skill/agent-maintenance reference (already a reference per EE-6, not one of the
  6), "Agent behavior expectations", "Key conventions". All retained verbatim.
- **PACK-CHAT.md:** Role, "When to run /pack-startup", "File access strategy",
  all other Behavioral rules (Plan-before-executing, No-commit-without-approval,
  Verify-staged, Chat-ownership-boundaries, "Real fixes only" band-aid rule,
  Direct-opinion, push-to-v11-dev, Batch-close-shapes, scope-extension,
  Tag-management, no-solution-biasing, separation-of-pack-ops-product, Delegate,
  Check-CI, no-commit-staging-threshold), "Action items", "Recommendation
  routing", "Session naming", "Cross-machine", "Keeping … current". All retained.

---

## 7b stale-reference sweep (completion criterion)

**Method:** grepped the whole repo (excl. `.git/`, `prison/`, `archive/`, and this
BD's own workflow artifacts) for cites depending on the removed restated TEXT or
removed line numbers: "as restated in PACK-AGENTS", "PACK-CHAT restates the
cadence", "Stop after every reviewer pass", PACK-AGENTS L116-138/L190-228 line
cites, PACK-CHAT L63-70/L76-77 cites, plus section-name references to "Agent
permission rules" / "Behavioral rules".

**Findings + disposition:**

1. **Live durable pack-ops surfaces — NO dangle.** The only inbound references to
   the collapsed blocks point at them by SECTION NAME, and both section headers
   survive the collapse:
   - `pack-ops/PACK-MEMORY-RATIONALE.md:42` — `per `PACK-AGENTS.md` § "Agent
     permission rules"`. The "Agent permission rules" section (L110) still exists;
     reference resolves. No edit needed.
   - Agent definition files `.claude/agents/pack-coder.md:99` +
     `.gemini/agents/pack-coder.md:96` — reference `pack-ops/PACK-AGENTS.md`
     "(agent routing + permission rules)" by role, not by removed text. Resolves.
     No edit needed.
2. **Workflow artifacts (`maintenance-docs/v11-implementation/*`,
   `maintenance-docs/v11-research/*`) — EXEMPT, no edit.** These carry line-number
   cites of the pre-collapse PACK-AGENTS PREFLIGHT block (e.g.,
   `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` "lines 190-211", `PLAN-CLEANUP-
   BATCH-19C.md` "L190-211"). Per the "Skill and agent maintenance" pack-memory
   rule, workflow artifacts (`ARCHITECTURE-*`, `PLAN-*`, `IMPLEMENTATION-REPORT-*`,
   `RESEARCH-*`) are historical records describing state at their own batch's HEAD;
   they are NOT live forward-pointing surfaces and are NOT rewritten on a later
   reshape. They sweep to `maintenance-docs/archive/vN/` at version ship (Pattern
   B). Editing them retroactively would falsify the historical record.
3. **`maintenance-docs/v11-research/*` "Audit cadence" matches** — unrelated
   (BD-110 pack-auditor "Audit cadence" section, not the collapsed cadence rule).
   No action.

**Conclusion:** 7b sweep clean. No live durable surface dangles. The `.spawn-rule-
manifest.txt` records the reference surfaces so C6 can assert resolution.

---

## Plan deviations

**D1 (surfaced per "never resolve plan contradictions yourself" — documented, not
silently resolved).** The plan + EE-6 state "6 restatements (3 PACK-AGENTS + 3
PACK-CHAT)". On the actual tree at HEAD `bf9290b` (byte-identical to EE-6's measured
HEAD `3bef42b` for PACK-CHAT.md — confirmed via `git diff 3bef42b HEAD --
pack-ops/PACK-CHAT.md` = empty):

- **PACK-AGENTS = 3 verbatim restatement blocks** → collapsed cleanly (git-ban,
  role-write-scope, PREFLIGHT). Matches EE-6 exactly.
- **PACK-CHAT = 1 verbatim restatement BLOCK** carrying THREE rule-concepts. EE-6's
  three PACK-CHAT rows (cadence "L76-77", triage-stop "L63", fix-all/no-fixes
  "L63-70") all point INTO or AROUND the single "Stop after every reviewer pass for
  triage discussion" block (L63-71). EE-6's "L76-77" lands inside the unrelated
  "Chat-ownership boundaries" block (concurrent-session ownership), not a cadence
  restatement. The fix-all/no-fixes rule exists in PACK-CHAT ONLY as slug
  REFERENCES inside the "Real fixes only" band-aid block ("Distinct from
  `feedback-fix-all-review-findings` … and `feedback-pack-chat-does-no-fixes` …")
  — already reference-form, no verbatim imperative to remove.

**Disposition (no self-resolution):** I collapsed the one verbatim PACK-CHAT
restatement block (the triage-stop / per-reviewer-pass block) — that is the only
surface in PACK-CHAT carrying verbatim spawn-rule imperative TEXT. The manifest maps
all THREE PACK-CHAT rule-concepts (presents-triage, triage-all/fix-all,
no-coder-review/bounded-cycle) to that collapsed reference surface so C6's
reference-resolution covers them. The C5 OUTCOME the plan requires — "the C6
anti-restate scan passes; no canonical imperative TEXT appears verbatim in
PACK-AGENTS/PACK-CHAT" — is achieved and MEASURED (all 7 phrases CLEAN). I did NOT
invent extra collapses to force a literal "3 separate PACK-CHAT block edits" count,
because no additional verbatim restatement exists to collapse and inventing one
would be a fabricated edit. **Surfaced for Pack Chat / planner review:** if the
planner intended three physically-distinct PACK-CHAT block edits, the EE-6 line map
does not match the current file and the plan/EE-6 should be reconciled — but the C5
GOAL (anti-restate-clean tree + resolvable manifest) is met as-is.

No other deviations.

---

## New POQs

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `pack-ops/.spawn-rule-manifest.txt` authored (6 records: slug → canonical + references) | PASS |
| 3 PACK-AGENTS restatements collapsed to one-line references (git-ban, role-write-scope, PREFLIGHT) | PASS |
| PACK-CHAT verbatim restatement block collapsed to one-line reference (see D1) | PASS |
| Verbatim canonical imperative TEXT removed (C6 anti-restate will pass) — measured | PASS |
| New references are resolvable cites (path-qualified / anchor-allowlisted) — do not trip Check 40 | PASS |
| Non-rule content (roster, how-to-invoke, PM-only list, role/startup/framing) left intact | PASS |
| EDIT IN PLACE (targeted Edits, not rewrite); re-read confirms nothing else changed | PASS |
| 7b stale-reference sweep run repo-wide; live surfaces fixed-or-confirmed-clean | PASS |
| `python3 scripts/validate-pack.py` full suite PASS incl. Check 40 + Check 45 | PASS |
| Manifest regen NOT run/staged (Pack Chat's at commit) | PASS |
| No git state changes | PASS |
| PREFLIGHT emitted before IMPL-REPORT | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No state-changing git verb run; only Read/Edit/Write + read-only `git rev-parse`/`status`/`diff`/`show`/`log`. `git status --short` shows ` M`/`??` (working-tree only), HEAD unchanged at `bf9290b`. Deliverable = working-tree edits + this IMPL-REPORT. | COMPLIANT |
| EDIT IN PLACE — targeted Edits, not a rewrite | Used `Edit` (exact-string) on PACK-AGENTS.md (3) + PACK-CHAT.md (1) + 1 Check-40 fix; `Write` only for the NEW manifest + this report. Re-read PACK-AGENTS.md L108-194: roster/PM-only list/forward-note/skill-ref all unchanged. PACK-CHAT.md: only the L63-71 block changed (confirmed by the targeted grep showing all other behavioral rules intact). | COMPLIANT |
| Collapse must remove the VERBATIM imperative TEXT (C6 anti-restate) | 7-phrase substring measurement against edited pack-ops files → all CLEAN (zero hits). Output quoted in Verification §. | COMPLIANT |
| PREFLIGHT before IMPL-REPORT; verification before PREFLIGHT (validate-pack incl. Check 40) | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" (Check 40 + Check 45 OK lines quoted). Intermediate Check-40 FAIL on bare `validate-pack.py` caught + fixed before PREFLIGHT. PREFLIGHT line emitted with HEAD `bf9290b` before this Write. | COMPLIANT |
| Manifest regen is Pack Chat's at commit (do NOT run build.sh / stage) | Did NOT run `test-fixtures/build.sh`; did NOT `git add` anything. `git status --short` shows manifest.txt NOT modified by me. | COMPLIANT |
| Output ends with Rules-Applied Verification Block (concise) | This block. | COMPLIANT |
| PRISON RULE — never read/cite/trust `maintenance-docs/prison/` | All greps excluded `prison/`; no read of any prison path. | COMPLIANT |
| Never resolve plan contradictions / fill plan gaps yourself | D1 (PACK-CHAT 1-block-vs-3-rows EE-6 mismatch) documented in Plan deviations + surfaced to Pack Chat/planner; NOT silently resolved by inventing extra collapses. | COMPLIANT |
| Filename uniqueness heuristic | New file `pack-ops/.spawn-rule-manifest.txt` — `find . -name ".spawn-rule-manifest.txt" -not -path "./.git/*"` returns only the new file (unique). | COMPLIANT |
| Trinity rule | C5 touches pack-ops docs + a `.txt` manifest only — no trinity file (CLAUDE/AGENTS/GEMINI) edited. Plan C5: "Trinity: no". | N/A: no trinity file in C5 scope |
| Boundary discipline (P-missed-7) | All edits are pack-ops/ (pack-only) surfaces; no `project-template/` / `supporting-docs/` edit. References point at pack-side SSOTs (trinity `## Pack memory`, PACK-AGENTS roster). No pack-only reference injected into a project-side file. | N/A: no project-side edit |
