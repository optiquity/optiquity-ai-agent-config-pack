# IMPLEMENTATION-REPORT-BD-032-FIXES

## §0 Summary

All 5 fixes from `AUDIT-BD-032.md` (F1–F5) applied to
`audit-methodology/SKILL.md` rule 21 plus parallel deduplication of the
boundary-clarification prose across the 6 auditor-ops / auditor-architecture
agent files (Claude / Codex / Gemini × 2 agents). `python3 scripts/validate-pack.py`
returns PASS for all 31 checks. No PAUSE — F4 (named-test rubric) was an
additive sentence, not a structural restructure. `deployment-python/SKILL.md`
was not touched (per scope guard — separate architect track).

## §1 Pre-flight state

- **Branch:** `v11-dev`
- **Working-tree HEAD at start:** `6350337c21f5964e7b93d89e3d6a4cf65b706a20`
- **Working-tree HEAD at finish:** `6350337c21f5964e7b93d89e3d6a4cf65b706a20` (no commits — agents never commit)
- **Untracked files at start (non-fixture, only relevant ones listed):**
  - `maintenance-docs/v11-implementation/AUDIT-BD-032.md`
  - `maintenance-docs/v11-implementation/AUDIT-BD-033.md`
  - `maintenance-docs/v11-implementation/AUDIT-BD-034.md`
  - `maintenance-docs/v11-implementation/AUDIT-BD-035.md`
  - (plus `maintenance-docs/v11-research/*` — out-of-scope, not touched)
- **Files read (read-only):**
  - `CLAUDE.md` (pack repo memory)
  - `maintenance-docs/v11-implementation/AUDIT-BD-032.md`
  - `project-template/skills/audit-methodology/SKILL.md` (full)
  - `project-template/.claude/agents/auditor-ops.md`
  - `project-template/.codex/agents/auditor-ops.toml`
  - `project-template/.gemini/agents/auditor-ops.md`
  - `project-template/.claude/agents/auditor-architecture.md`
  - `project-template/.codex/agents/auditor-architecture.toml`
  - `project-template/.gemini/agents/auditor-architecture.md`
- **Pre-flight conclusion:** all expected input files present at the paths
  named in the audit. No invent-from-thin-air situation.

## §2 Per-fix edit log

### F1 — SHOULD-FIX — Metrics + tracing boundary examples in rule 21

**File:** `project-template/skills/audit-methodology/SKILL.md` (rule 21, line 55).

**Change:** Extended the ops-side example list inside the boundary-clarification
sentence with 4 new concrete examples covering metrics, tracing sampling, alerting,
and log retention:

- "the Prometheus histogram bucket boundaries are hardcoded for sub-millisecond local development" (metrics)
- "the prod trace sampler ratio is hardcoded to 1.0" (tracing sampling)
- "no alert rule references the exported `http_request_duration_seconds` metric and no SLO is defined" (alerting / SLO)
- "the log retention policy in the deployment manifest defaults to 1 day in prod" (log retention)

These join the original three OTLP-flavoured examples ("OTLP endpoint hardcoded",
"resource `service.name` missing", "exporter not installed for prod"). Result:
7 ops-side examples spanning logging, metrics, tracing, sampling, alerting,
and retention — every named sub-domain in F3's enumeration now has at least
one concrete worked example.

**Architecture-side examples** were not extended; they already cover both
logging-shape ("`Logger` protocol is the wrong shape") and tracing-wiring
("`configure_tracing` is not wired into the app entry point") cases, and F4
adds a third architecture example inline in the named-test rubric
("registering an `OpenTelemetryClientInterceptor` on a previously-uninstrumented
gRPC channel" — which is the BD-032 audit's Scenario C).

**Verification:** `validate-pack.py` PASS; manual re-read of rule 21 confirms
the new examples appear inside the boundary-clarification sentence in
parallel grammatical structure to the originals.

### F2 — NIT — Uncertainty trigger phrases in rule 21

**File:** same as F1.

**Change:** Added a sentence after "When uncertain, file under auditor-ops"
naming three triggers for uncertainty:

> "Uncertainty typically arises when (a) the same source-file location has
> both a structural shape (the abstraction or wiring is wrong) and a
> deployment-target shape (the wrong concrete value was chosen), (b) a
> finding could be fixed by either editing source or editing config
> without source change, or (c) the same code behaves differently in dev
> vs prod due to environment alone."

Plus a follow-up clause: "Prefer ops in those cases — the deployment-shaped
fix usually subsumes the structural fix; if not, the cross-detection
annotation will surface the architecture half."

This addresses the F2 finding directly: the rule now names what triggers
uncertainty, not just what to do when uncertain. Triggers (b) and (c) are
verbatim from the BD-032 caller prompt; trigger (a) is the original
disposition wording from AUDIT-BD-032 §F2.

**Verification:** `validate-pack.py` PASS; manual re-read confirms triggers
appear inline with the "When uncertain" sentence.

### F3 — SHOULD-FIX — Add sampling, alerting / SLO, log retention as enumerated sub-domains

**File:** same as F1.

**Change:** Extended the parenthetical sub-domain enumeration in rule 21's
opening sentence from:

> "(logging output format, metrics endpoints, tracing exporter setup)"

to:

> "(logging output format, log retention, metrics endpoints, sampling rates,
> tracing exporter setup, alerting / SLO definitions)"

This closes the gap between the BD-032 BACKLOG description (which named
these) and the implemented rule (which did not).

The agent-file Observability bullets (auditor-ops × 3) were updated in
parallel to mirror the new sub-domain list — see §F5 below; the new
sub-domains appear in the cross-reference bullet so an auditor-ops agent
knows the cluster's scope without having to load the skill body to read
rule 21.

**Verification:** `validate-pack.py` PASS; rule 21 now explicitly enumerates
all 6 observability sub-domains.

### F4 — OBSERVATION → fix — Named-test rubric in rule 21

**File:** same as F1.

**Change:** Added a new sub-paragraph "**Named test (ownership rubric).**"
between the example list and the "When uncertain" default. Verbatim:

> "A finding is auditor-ops if the fix changes a *value* read from
> configuration at runtime (env var, manifest field, exporter parameter,
> sampler ratio, alert rule, retention setting) without changing
> source-file types or call graphs. A finding is auditor-architecture if
> the fix changes the *type* of an interface (e.g., adding `severity:`
> to a `Logger` protocol), the *call graph* between modules (e.g.,
> registering an `OpenTelemetryClientInterceptor` on a
> previously-uninstrumented gRPC channel), or the *wiring* between
> components (e.g., calling `configure_tracing()` from the app entry
> point). Apply this test before falling back to enumerated examples."

This mirrors rule 16's auditor-code systemic threshold (named test:
"≥3 independent call sites OR crosses module boundary"). The rule 21
named test is "value vs type/call-graph/wiring."

**PAUSE evaluation:** The caller asked me to PAUSE if F4 turned out to be
"materially larger" than F1–F3's content additions. F4 added one named
sub-paragraph (~110 words, three example clauses, one application
directive) — comparable in size to F1's example expansion (~80 words)
and F2's trigger-phrase expansion (~80 words). No restructure of rule
21's narrative shape was needed; the named-test paragraph slots cleanly
between the existing examples and the existing "When uncertain"
default. **No PAUSE required.** Continued through F5.

The named-test rubric also explicitly resolves AUDIT-BD-032's Scenario C
(the gRPC interceptor case): "registering an interceptor" is a *call
graph* change, so it is auditor-architecture under the named test —
exactly the outcome the audit identified the literal rule was getting
wrong.

**Verification:** `validate-pack.py` PASS; named-test paragraph reads as
a self-contained rubric distinguishable from the surrounding examples
and the uncertainty default.

### F5 — OBSERVATION → fix — Dedup boundary prose across 6 agent files

**Strategy decided:** keep the canonical full prose in
`audit-methodology/SKILL.md` rule 21 ONLY; replace each agent-file copy
with a one-line cross-reference plus the brief sub-domain enumeration
the agent needs to know its cluster owns (so the agent can answer
"is this in my scope" without forcing a skill-body re-read).

**Files modified (6):**

1. `project-template/.claude/agents/auditor-ops.md` — Observability wiring bullet replaced.
2. `project-template/.gemini/agents/auditor-ops.md` — same.
3. `project-template/.codex/agents/auditor-ops.toml` — same (single-line TOML format).
4. `project-template/.claude/agents/auditor-architecture.md` — Observability infrastructure bullet replaced.
5. `project-template/.gemini/agents/auditor-architecture.md` — same.
6. `project-template/.codex/agents/auditor-architecture.toml` — same (single-line TOML format).

**Replacement text — auditor-ops bullet (Claude/Gemini wording, identical
prose with line wrapping; Codex single-line TOML carries the same prose):**

> "Observability wiring — logging output format, log retention, metrics
> endpoints, sampling rates, tracing exporter setup, alerting / SLO
> definitions. For the full ownership boundary (auditor-ops vs
> auditor-architecture vs auditor-security on observability findings,
> including the named-test rubric and the 'when uncertain, file under
> auditor-ops' default), see
> `project-template/skills/audit-methodology/SKILL.md` rule 21
> (auditor-ops scope and boundary clarification). The skill is canonical;
> this bullet does not restate it."

**Replacement text — auditor-architecture bullet (Claude/Gemini wording,
identical prose with line wrapping; Codex single-line TOML carries the
same prose):**

> "Observability infrastructure — are logs, metrics, and traces wired up
> at the right architectural layers? Does the project have a logger
> abstraction at the boundary, metric collection in the service layer,
> trace context propagated across async boundaries? This is about
> whether the wiring *exists*. For the full ownership boundary
> (auditor-architecture vs auditor-ops vs auditor-security on
> observability findings, including the named-test rubric distinguishing
> structural vs deployment-target fixes), see
> `project-template/skills/audit-methodology/SKILL.md` rule 21
> (auditor-ops scope and boundary clarification). The skill is canonical;
> this bullet does not restate it."

**Trinity discipline:**
- Claude `.md` and Gemini `.md` agent files use byte-identical prose
  (with the standard line-wrapping difference inherent in those files'
  pre-existing format conventions).
- Codex `.toml` files use the same prose collapsed to a single line
  inside `developer_instructions = """..."""` (per the existing TOML
  encoding pattern in those files — this is consistent with how the
  rest of the file's bullets are encoded).
- Substantive content (sub-domain list, cross-reference target, "skill
  is canonical" disclaimer) is byte-identical across all three CLIs
  for each of the two agent roles. No semantic drift.

**Boundary prose count before / after:**
- Before: 6 copies (1 canonical in SKILL.md + 5 derived: 3 auditor-ops
  + 2 auditor-architecture). The audit's count of 5 was off by one
  because it didn't cross-check `auditor-architecture.toml` and
  `.gemini/agents/auditor-architecture.md` — both carry the same prose.
  Verified by direct read during fix-pass.
- After: 1 canonical copy (SKILL.md rule 21) + 6 one-line cross-references.
- Maintenance tax: when rule 21 changes again, only one site needs
  editing; agent-file cross-references remain stable.

**Verification:** `validate-pack.py` PASS — all 6 agent files still pass
profile / phrase / skills-to-load checks. Trinity-rule preserved.

## §3 Validate-pack output

`python3 scripts/validate-pack.py` final line: `PASSED — all checks clean`.

All 31 checks PASS. Relevant sub-checks confirmed clean post-edit:

- Check 27 (BD-146 skills-to-load conformance): both auditor-ops (3 cited)
  and auditor-architecture (6 cited) Skills-to-load references conform —
  no skill names accidentally added or removed by the bullet rewrites.
- Permission profile checks: all 6 modified agent files still pass
  `read-only` profile validation (the Permission-profile / Output-policy
  / Hard-rules sections were not touched — only the in-Scope bullet
  was rewritten).
- All other checks (Tier 0 base, dimensional intersection, PM-startup
  parity, tracker schema) untouched and still PASS.

## §4 Files changed inventory

| File | Type | Change |
|------|------|--------|
| `project-template/skills/audit-methodology/SKILL.md` | modified | Rule 21 rewritten: F1 (4 new examples), F2 (uncertainty triggers), F3 (3 new sub-domains), F4 (named-test rubric). One sentence per fix; rule 21 grew from ~330 words to ~620 words. |
| `project-template/.claude/agents/auditor-ops.md` | modified | F5: Observability wiring bullet replaced with cross-reference + sub-domain list. |
| `project-template/.gemini/agents/auditor-ops.md` | modified | F5: same as above (byte-identical prose to Claude). |
| `project-template/.codex/agents/auditor-ops.toml` | modified | F5: same as above (single-line TOML encoding). |
| `project-template/.claude/agents/auditor-architecture.md` | modified | F5: Observability infrastructure bullet replaced with cross-reference. |
| `project-template/.gemini/agents/auditor-architecture.md` | modified | F5: same as above (byte-identical prose to Claude). |
| `project-template/.codex/agents/auditor-architecture.toml` | modified | F5: same as above (single-line TOML encoding). |

**Total files modified:** 7. **New files:** 1 (this report). **Deleted:** 0.

## §5 BD-159 §3.1 mechanical-edit sanity check

Per `CLAUDE.md` Pack memory § "Repo conventions" — "Skill and agent
maintenance is mechanical by default." This fix-pass is a maintenance
operation on existing rule 21 content, not a structural change:

- **No new skill, no new agent, no new top-level doc** introduced. ✓
- **No deleted skill, no deleted agent.** ✓
- **No `x-` skill / agent contract touched** — only pack-supplied
  files modified. ✓
- **Trinity preserved** for both auditor-ops and auditor-architecture
  across `.claude` / `.codex` / `.gemini`. ✓
- **File-count target ≤10 per BD-159 §3.1:** 7 product files modified,
  within cap. ✓
- **No edits outside the named scope:**
  - `deployment-python/SKILL.md` not touched (per scope guard;
    separate architect track). ✓
  - `maintenance-docs/v11-research/*` not touched. ✓
  - `BACKLOG.md`, `CHANGELOG.md`, `EXECUTION-PLAN-V11.0.md`,
    `README.md` not touched (PM-only files). ✓
  - Other auditor agent files (`auditor-code`, `auditor-ui`,
    `auditor-tests`, `auditor-security`, `auditor-docs`, parent
    `auditor`) not touched — they don't carry the duplicated boundary
    prose (verified by reading the audit's F5 inventory). ✓

**Workflow artifact:** This report is a workflow artifact
(`IMPLEMENTATION-REPORT-*.md`) per the same Pack-memory rule and is
therefore exempt from the "no new top-level doc" structural signal
during the BD-032 batch. It will sweep to
`maintenance-docs/archive/v11/` at v11.0 ship per Pattern B.

## §6 Plan deviations

**One:** the audit's F5 listed 5 duplicate sites for the boundary prose
(auditor-ops × 3 + auditor-architecture × 1, the Claude variant only).
The caller's prompt told me to "verify if Codex/Gemini also have copies;
if so, those count too" — and they do. I therefore deduplicated 6 sites
total, not 5. This is consistent with the caller's explicit instruction;
flagged here for traceability.

**No other deviations.** F1–F4 applied exactly as the caller directed.

## §7 New POQs introduced

**None.** All five fixes were within the audit's scope and the caller's
explicit fix list. No new policy questions surfaced during execution.

The cross-cutting `deployment-python/SKILL.md` content gap noted in the
audit (no metrics/tracing rules to enforce) was already routed to a
separate docs-researcher → architect → planner → coder cycle per the
caller's prompt and was explicitly out of scope for this fix pass — no
new POQ needed.

## §8 Definition-of-Done checklist

| Item | Status |
|------|--------|
| F1 metrics + tracing examples added to rule 21 | PASS |
| F2 uncertainty triggers added to rule 21 | PASS |
| F3 sampling / alerting / SLO / retention added to rule 21 enumeration | PASS |
| F4 named-test rubric added to rule 21 | PASS |
| F5 boundary prose deduplicated to 1 canonical + 6 cross-references | PASS |
| `python3 scripts/validate-pack.py` PASS for all 31 checks | PASS |
| Trinity rule preserved (Claude / Codex / Gemini for both auditor agents) | PASS |
| `deployment-python/SKILL.md` untouched | PASS |
| `maintenance-docs/v11-research/*` untouched | PASS |
| BD-032 BACKLOG entry untouched (PM-chat only) | PASS |
| EXECUTION-PLAN, CHANGELOG, README untouched | PASS |
| Implementation report written at the caller-specified path | PASS |
| File-count ≤10 per BD-159 §3.1 (actual: 7 product files modified) | PASS |
| No git state-changing operations | PASS |

**Verdict:** All DoD criteria PASS. Ready for Pack Chat review +
commit.

## §9 PAUSE notes

**None.** F4 stayed within additive scope (one named sub-paragraph,
similar size to F1 / F2 / F3 expansions); no restructure of rule 21's
narrative shape was needed. Continued cleanly through F5.
